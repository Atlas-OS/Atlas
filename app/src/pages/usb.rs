//! Writes an ISO to a USB drive, as a panel over the ISO page: the ISO and
//! the drive on one screen, a dialog that names the drive before erasing
//! it, then the write, which reads every file back and ejects the drive.
//!
//! The page checks what it can before anything is erased: the ISO when it
//! arrives or changes, and each drive as the list shows it. The list follows
//! drives as they're connected and removed.

use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use futures::StreamExt;
use gpui::{
    AnyElement, App, Context, Div, Entity, FocusHandle, IntoElement, ParentElement, PathPromptOptions,
    PromptLevel, Render, Role, ScrollHandle, Stateful, Task, Window, div, prelude::*, px,
};

use super::{
    CommandBar, Diagnostics, PageTitle, PanelBack, card_body, card_title, detail_text, focusable_heading,
    page_frame,
};
use crate::i18n::fmt;
use crate::model::{AppModel, Page};
use crate::services::usb::{self, Drive, FailureReason, Progress, SoldSize, Stage};
use crate::services::{iso, settings, system};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    BODY_LINE_HEIGHT, Button, CapCenteredText, FocusHandles, Icon, InfoBar, ProgressBar, ProgressRing,
    RadioGroup, RadioItem, ScrollbarState, Severity, TextMark, Typography, a11y_text, card, icon, icon_sized,
};

/// How often the page looks for drives being connected or removed.
const POLL: Duration = Duration::from_secs(2);
/// Looks between checks of an ISO that lacked working space, about 30 s.
const SPACE_RECHECK_POLLS: u32 = 15;
/// Looks between checks while another window writes or ejects a drive, about 6 s.
const BUSY_RECHECK_POLLS: u32 = 3;
/// Windows Settings' Storage page, where space can be freed.
const STORAGE_SETTINGS: &str = "ms-settings:storagesense";

/// Where the page is: choosing, writing, or done.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Phase {
    /// The ISO and the drive, with the button that asks to erase it.
    Choose,
    /// Writing, or ejecting again after Windows refused.
    Writing,
    /// Written and verified; `ejected` once Windows let the drive go.
    Done { ejected: bool },
}

/// What the check of the ISO found.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum IsoCheck {
    /// No ISO yet, or one whose check waits for another job.
    None,
    Checking,
    /// Usable: a write copies `bytes` to the drive.
    Passed {
        bytes: u64,
    },
    Failed(IsoProblem),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum IsoProblem {
    /// Not Windows 11 installation media for a build the package supports.
    Unsupported,
    /// The ISO or Atlas Manager is on a network location or in a linked folder.
    Location,
    /// Too little space on the Windows drive to split its large image.
    WorkingSpace,
    /// The check failed some other way, such as a damaged ISO.
    Unreadable,
    /// Windows didn't open the ISO as a drive Atlas can read.
    Mount,
    /// The drivers Windows mounts an ISO with are turned off.
    MountDrivers,
    /// The ISO's file is stored in a way Windows doesn't mount; a copy is.
    MountFile,
    /// Windows stopped answering while it opened the ISO.
    MountTimeout,
}

impl IsoProblem {
    fn text(self) -> String {
        match self {
            Self::Unsupported => t!("usb-iso-not-usable"),
            Self::Location => t!("usb-iso-location"),
            Self::WorkingSpace => t!("usb-working-space"),
            Self::Unreadable => t!("usb-iso-unreadable"),
            Self::Mount => t!("iso-mount-failed"),
            Self::MountDrivers => t!("iso-mount-drivers"),
            Self::MountFile => t!("iso-mount-file"),
            Self::MountTimeout => t!("iso-mount-timeout"),
        }
    }

    /// Whether nothing the person can do is known to fix it, so the card
    /// offers help and the check's logs.
    fn needs_help(self) -> bool {
        matches!(self, Self::Unreadable | Self::Mount | Self::MountTimeout)
    }
}

/// Why a listed drive can't be written to. It's shown, unavailable, with this.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Unusable {
    HoldsIso,
    HoldsApp,
    /// Below the smallest size the writer takes.
    TooSmall,
    /// Too small for this ISO's files.
    TooSmallForIso,
}

impl Unusable {
    fn text(self) -> String {
        match self {
            Self::HoldsIso => t!("usb-drive-has-iso"),
            Self::HoldsApp => t!("usb-drive-has-app"),
            Self::TooSmall => t!("usb-drive-too-small-needs", size = usb::MIN_SOLD_GB),
            Self::TooSmallForIso => t!("usb-drive-too-small-iso"),
        }
    }
}

/// Whether `drive` can be written to, and if not, why: it holds the ISO
/// (`source`) or Atlas Manager (`app`), or it's too small for the writer or
/// for the ISO's `bytes`, or a write found it too small (`rejected`).
fn unusable(
    drive: &Drive,
    source: Option<&Path>,
    app: Option<&Path>,
    bytes: Option<u64>,
    rejected: &[Drive],
) -> Option<Unusable> {
    if source.is_some_and(|source| drive.holds(source)) {
        Some(Unusable::HoldsIso)
    } else if app.is_some_and(|app| drive.holds(app)) {
        Some(Unusable::HoldsApp)
    } else if drive.too_small {
        Some(Unusable::TooSmall)
    } else if bytes.is_some_and(|bytes| !drive.fits(bytes)) || rejected.iter().any(|r| r.same_device(drive)) {
        Some(Unusable::TooSmallForIso)
    } else {
        None
    }
}

/// The drive chosen, as the latest list reports it, and whether the user
/// chose it rather than Atlas.
#[derive(Clone, Debug, PartialEq, Eq)]
struct Pick {
    drive: Drive,
    by_user: bool,
}

/// The pick after a new list, given which drives in it can be used. The
/// pick follows its drive to its new record. A drive the user chose that is
/// gone stays chosen, unseen, so it's chosen again when it's back; one Atlas
/// chose is let go. With nothing chosen, Atlas chooses the only usable drive.
fn repick(pick: Option<Pick>, drives: &[Drive], usable: &[bool]) -> Option<Pick> {
    let usable_drives: Vec<&Drive> =
        drives.iter().zip(usable).filter(|(_, usable)| **usable).map(|(d, _)| d).collect();
    if let Some(pick) = pick {
        if let Some(drive) = usable_drives.iter().find(|drive| pick.drive.same_device(drive)) {
            return Some(Pick { drive: (*drive).clone(), by_user: pick.by_user });
        }
        if pick.by_user {
            return Some(pick);
        }
    }
    match usable_drives[..] {
        [only] => Some(Pick { drive: only.clone(), by_user: false }),
        _ => None,
    }
}

/// What the bar at the top reports.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum UsbError {
    /// The drive list could not be read.
    Scan,
    /// A finished drive could not be ejected; it is still ready.
    Eject,
    /// The user stopped a write; `changed` when the drive may be partly written.
    Cancelled { changed: bool },
    /// The drive was removed, reconnected or replaced before anything was erased.
    DriveChanged,
    /// A write failed; `changed` when the drive may be partly written.
    Write { changed: bool },
}

impl UsbError {
    /// Severity, title and message of the bar. Cancelling is the user's own
    /// choice, a changed drive lost nothing, and a failed eject leaves a
    /// finished drive, so none of these is an error. A cancelled write that
    /// left the drive incomplete is a warning: the drive can't be used as it is.
    fn bar(self) -> (Severity, String, String) {
        match self {
            Self::Scan => (Severity::Error, t!("usb-scan-failed-title"), t!("usb-scan-failed-retry")),
            Self::Eject => (Severity::Warning, t!("usb-eject-failed-title"), t!("usb-eject-failed-ready")),
            Self::Cancelled { changed: true } => {
                (Severity::Warning, t!("usb-drive-cancelled-title"), t!("usb-cancelled-partial"))
            }
            Self::Cancelled { changed: false } => {
                (Severity::Informational, t!("usb-drive-cancelled-title"), t!("usb-cancelled-unchanged"))
            }
            Self::DriveChanged => {
                (Severity::Informational, t!("usb-drive-changed-title"), t!("usb-drive-changed"))
            }
            Self::Write { changed } => (
                Severity::Error,
                t!("usb-failed-title"),
                if changed { t!("usb-failed-partial") } else { t!("usb-failed-before-erase") },
            ),
        }
    }

    /// Whether Get help belongs under the bar: for failures nobody expects,
    /// and not for what the user did or can put right themselves.
    fn offers_help(self) -> bool {
        matches!(self, Self::Scan | Self::Write { .. })
    }
}

/// Where a failed job leaves the page.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Failed {
    /// A bar says what happened.
    Bar(UsbError),
    /// The ISO can't be used; its card says why.
    Iso(IsoProblem),
    /// The ISO's files don't fit the drive; the list marks it.
    TooSmall,
}

impl Failed {
    /// Where a failed `operation` leaves the page, from what the worker
    /// reported. Before a write erases anything, its typed reasons are the
    /// check's, and say the drive is unchanged.
    fn of(operation: &str, cancelled: bool, failure: Option<&usb::Failure>) -> Self {
        // Without the worker's account of it, the drive may have been changed.
        let changed = failure.is_none_or(|failure| failure.drive_changed);
        let reason = failure.and_then(|failure| failure.reason);
        let iso = |reason| match reason {
            Some(FailureReason::IsoUnsupported) => Some(IsoProblem::Unsupported),
            Some(FailureReason::SourceLocation) => Some(IsoProblem::Location),
            Some(FailureReason::WorkingSpace) => Some(IsoProblem::WorkingSpace),
            Some(FailureReason::IsoMount) => Some(IsoProblem::Mount),
            Some(FailureReason::IsoMountDrivers) => Some(IsoProblem::MountDrivers),
            Some(FailureReason::IsoMountFile) => Some(IsoProblem::MountFile),
            Some(FailureReason::IsoMountTimeout) => Some(IsoProblem::MountTimeout),
            _ => None,
        };
        match operation {
            "List" => Self::Bar(UsbError::Scan),
            "Check" => Self::Iso(iso(reason).unwrap_or(IsoProblem::Unreadable)),
            "Eject" => Self::Bar(UsbError::Eject),
            _ if cancelled => Self::Bar(UsbError::Cancelled { changed }),
            _ if changed => Self::Bar(UsbError::Write { changed: true }),
            _ => match reason {
                Some(FailureReason::DoesNotFit) => Self::TooSmall,
                Some(FailureReason::DriveChanged) => Self::Bar(UsbError::DriveChanged),
                reason => iso(reason).map_or(Self::Bar(UsbError::Write { changed: false }), Self::Iso),
            },
        }
    }
}

/// Lists and checks that waited for another job holding the app.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct Pending {
    list: bool,
    check: bool,
}

pub struct UsbPage {
    pub closed: bool,
    model: Entity<AppModel>,
    source: Option<PathBuf>,
    /// Looking in Downloads for an ISO, when none was given.
    finding_source: bool,
    /// Atlas Manager's own file, which no drive it writes may hold.
    app: Option<PathBuf>,
    /// The Windows builds the Atlas package supports; the worker refuses others.
    supported_builds: Vec<u32>,
    check: IsoCheck,
    /// The job of a check that failed unexpectedly, for its log.
    check_job: Option<PathBuf>,
    /// Stops the check under way, when another ISO replaces it.
    check_cancel: Option<Arc<AtomicBool>>,
    check_task: Option<Task<()>>,
    /// A newer check is due once the one under way has stopped.
    check_again: bool,
    /// The last check found another window's write or eject under way, so
    /// it runs again shortly.
    check_busy: bool,
    drives: Vec<Drive>,
    /// Whether a list has been read since the page opened.
    listed: bool,
    list_task: Option<Task<()>>,
    /// Drives changed while a list was being read, so another is due.
    list_again: bool,
    pick: Option<Pick>,
    /// Drives a write found too small for this ISO.
    rejected: Vec<Drive>,
    /// The drive the user agreed to erase, which Try again writes again.
    confirmed: Option<Drive>,
    phase: Phase,
    error: Option<UsbError>,
    progress: Progress,
    /// The furthest the bar has been, so it never goes back.
    peak: f32,
    /// The failed job the bar's help row opens.
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    /// Disks and drive letters at the last look, and looks since the last
    /// check for working space.
    devices: Option<usb::Devices>,
    polls: u32,
    watch: Option<Task<()>>,
    pending: Pending,
    /// The relaunch as administrator was declined.
    elevation_declined: bool,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    preview: bool,
    /// A review preview of the panel before Atlas has administrator permission.
    preview_unelevated: bool,
    /// A review preview opens with the erase question.
    ask_on_open: bool,
    diagnostics: Diagnostics,
    shown: Option<Shown>,
    /// The drive card's focus target last drawn, so focus can follow it.
    shown_target: Option<String>,
}

/// What was last announced by moving focus: the phase, the bar, the ISO's
/// problem, whether another job held the app, whether Windows refused the
/// relaunch as administrator, and the page visit, so returning to the open
/// panel is announced too. Lists and progress are left out so they never
/// move focus.
type Shown = (Phase, Option<UsbError>, Option<IsoProblem>, bool, bool, u64);

impl UsbPage {
    pub fn new(
        model: Entity<AppModel>,
        source: Option<PathBuf>,
        supported_builds: Vec<u32>,
        preview: Option<&str>,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&model, |this, model, cx| {
            // Work that waited for another job starts once it ends; deferred,
            // as at opening, so the model isn't updated from its own notification.
            let due = this.take_due(model.read(cx));
            if due != Pending::default() {
                let entity = cx.entity();
                cx.defer(move |cx| {
                    entity.update(cx, |this, cx| {
                        if due.list {
                            this.start_list(cx);
                        }
                        if due.check {
                            this.start_check(false, cx);
                        }
                    })
                });
            }
            cx.notify();
        })
        .detach();
        let mut page = Self {
            closed: false,
            model,
            finding_source: source.is_none() && preview.is_none(),
            source,
            app: std::env::current_exe().ok(),
            supported_builds,
            check: IsoCheck::None,
            check_job: None,
            check_cancel: None,
            check_task: None,
            check_again: false,
            check_busy: false,
            drives: vec![],
            listed: false,
            list_task: None,
            list_again: false,
            pick: None,
            rejected: vec![],
            confirmed: None,
            phase: Phase::Choose,
            error: None,
            progress: Progress::default(),
            peak: 0.,
            job: None,
            task: None,
            devices: None,
            polls: 0,
            watch: None,
            pending: Pending::default(),
            elevation_declined: preview == Some("usb-elevation-declined"),
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            preview: preview.is_some(),
            preview_unelevated: matches!(preview, Some("usb-not-elevated" | "usb-elevation-declined")),
            ask_on_open: false,
            diagnostics: Diagnostics::new(cx),
            shown: None,
            shown_target: None,
        };
        if let Some(state) = preview {
            page.load_preview(state);
            // A write holds the app, as a real one does.
            if page.phase == Phase::Writing {
                page.model.update(cx, |m, _| {
                    m.iso_busy = true;
                    m.usb_busy = true;
                    m.iso_cancel.store(state == "usb-cancelling", Ordering::Relaxed);
                });
            }
        } else if page.elevated(cx) {
            let entity = cx.entity();
            cx.defer(move |cx| {
                entity.update(cx, |this, cx| {
                    this.start_list(cx);
                    if this.finding_source {
                        this.find_source(cx);
                    } else {
                        this.start_check(false, cx);
                    }
                    this.watch = Some(this.watch_drives(cx));
                })
            });
        } else if page.finding_source {
            // Finding the ISO needs no permission, so the page shows it while
            // it asks; checking it and listing drives wait for the relaunch.
            let entity = cx.entity();
            cx.defer(move |cx| entity.update(cx, |this, cx| this.find_source(cx)));
        }
        page
    }

    /// Shows the panel in the review preview `state`, with made-up drives.
    fn load_preview(&mut self, state: &str) {
        let [drive, other, small] = usb::preview_drives();
        self.source = (state != "usb-iso-missing")
            .then(|| PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso"));
        self.check = match state {
            // Checking the ISO waits for the permission, as a real one does.
            "usb-iso-missing" | "usb-not-elevated" | "usb-elevation-declined" => IsoCheck::None,
            "usb-iso-checking" => IsoCheck::Checking,
            "usb-iso-unsupported" => IsoCheck::Failed(IsoProblem::Unsupported),
            "usb-iso-unreadable" => IsoCheck::Failed(IsoProblem::Unreadable),
            "usb-working-space" => IsoCheck::Failed(IsoProblem::WorkingSpace),
            _ => IsoCheck::Passed { bytes: 6_500_000_000 },
        };
        self.listed = !matches!(state, "usb-looking" | "usb-scan-failed");
        self.drives = match state {
            "usb-empty" | "usb-looking" | "usb-scan-failed" => vec![],
            "usb-drives" => vec![drive.clone(), other, small],
            "usb-too-small" => vec![small],
            _ => vec![drive.clone()],
        };
        self.repick();
        self.phase = match state {
            "usb-progress" | "usb-cancelling" => Phase::Writing,
            "usb-complete" => Phase::Done { ejected: true },
            "usb-eject-failed" => Phase::Done { ejected: false },
            _ => Phase::Choose,
        };
        self.progress = Progress { stage: "copy".into(), done: 3, total: 8 };
        self.peak = self.progress.overall();
        self.error = match state {
            "usb-failed" => Some(UsbError::Write { changed: true }),
            "usb-failed-unchanged" => Some(UsbError::Write { changed: false }),
            "usb-drive-changed" => Some(UsbError::DriveChanged),
            "usb-cancelled" => Some(UsbError::Cancelled { changed: true }),
            "usb-cancelled-unchanged" => Some(UsbError::Cancelled { changed: false }),
            "usb-scan-failed" => Some(UsbError::Scan),
            "usb-eject-failed" => Some(UsbError::Eject),
            _ => None,
        };
        // A real failure leaves its job, and the log folder with it, and a
        // drive the user agreed to erase.
        if self.error.is_some_and(UsbError::offers_help) {
            self.job = Some(settings::app_data_dir());
        }
        if self.check == IsoCheck::Failed(IsoProblem::Unreadable) {
            self.check_job = Some(settings::app_data_dir());
        }
        if self.error.is_some() {
            self.confirmed = Some(drive);
        }
        self.ask_on_open = state == "usb-confirm";
    }

    fn elevated(&self, cx: &App) -> bool {
        !self.preview_unelevated && (self.preview || self.model.read(cx).elevated)
    }

    /// Another job, such as Windows preparation, holds the app, and nothing
    /// here can start until it ends. This page's own write isn't another job.
    fn held(&self, cx: &App) -> bool {
        self.model.read(cx).locked() && self.phase != Phase::Writing
    }

    /// Work that waited for another job, once it has ended and the panel is
    /// on screen. The wait is used up, so one job's end starts the work once.
    fn take_due(&mut self, state: &AppModel) -> Pending {
        let due = !self.closed && state.page == Page::Iso && !state.locked();
        if due { std::mem::take(&mut self.pending) } else { Pending::default() }
    }

    /// The bytes a write copies, once the ISO passed its check.
    fn bytes(&self) -> Option<u64> {
        match self.check {
            IsoCheck::Passed { bytes } => Some(bytes),
            _ => None,
        }
    }

    fn unusable(&self, drive: &Drive) -> Option<Unusable> {
        unusable(drive, self.source.as_deref(), self.app.as_deref(), self.bytes(), &self.rejected)
    }

    /// Chooses again after the drives, the ISO or its check changed; never
    /// while a write runs, whatever a list that ends meanwhile says.
    fn repick(&mut self) {
        if self.phase == Phase::Writing {
            return;
        }
        let usable: Vec<bool> = self.drives.iter().map(|drive| self.unusable(drive).is_none()).collect();
        self.pick = repick(self.pick.take(), &self.drives, &usable);
    }

    /// The picked drive's place in the list, while it's there and usable.
    fn selected(&self) -> Option<usize> {
        let pick = self.pick.as_ref()?;
        self.drives.iter().position(|drive| pick.drive.same_device(drive) && self.unusable(drive).is_none())
    }

    /// The drive Create USB drive would erase: picked, usable, with an ISO
    /// that passed its check, and nothing else under way.
    fn ready_drive(&self, cx: &App) -> Option<Drive> {
        if self.phase != Phase::Choose || self.held(cx) || self.bytes().is_none() || self.source.is_none() {
            return None;
        }
        self.selected().map(|index| self.drives[index].clone())
    }

    /// Looks in Downloads for the newest Atlas ISO, when none was given.
    fn find_source(&mut self, cx: &mut Context<Self>) {
        let found = cx
            .background_executor()
            .spawn(async { usb::downloads_folder().and_then(|folder| usb::newest_atlas_iso(&folder)) });
        cx.spawn(async move |this, cx| {
            let found = found.await;
            this.update(cx, |this, cx| {
                this.finding_source = false;
                // One chosen meanwhile stays.
                if this.source.is_none() && found.is_some() {
                    this.source = found;
                    this.start_check(false, cx);
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    fn choose_iso(&mut self, cx: &mut Context<Self>) {
        if self.preview || self.phase == Phase::Writing {
            return;
        }
        let response = cx.prompt_for_paths(PathPromptOptions {
            files: true,
            directories: false,
            multiple: false,
            prompt: Some(t!("iso-use-local").into()),
        });
        cx.spawn(async move |this, cx| {
            if let Ok(Ok(Some(paths))) = response.await
                && let Some(path) = paths.into_iter().next()
            {
                this.update(cx, |this, cx| {
                    this.finding_source = false;
                    this.source = Some(path);
                    this.rejected.clear();
                    this.check = IsoCheck::None;
                    this.check_job = None;
                    this.error = None;
                    this.repick();
                    this.start_check(false, cx);
                    cx.notify();
                })
                .ok();
            }
        })
        .detach();
    }

    /// Looks for drives coming and going every [`POLL`], while the panel is
    /// on screen, and reads the list again when they have. The look itself
    /// is cheap; reading the list takes a worker.
    fn watch_drives(&mut self, cx: &mut Context<Self>) -> Task<()> {
        self.devices = Some(usb::devices());
        cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(POLL).await;
                let devices = cx.background_executor().spawn(async { usb::devices() }).await;
                if this.update(cx, |this, cx| this.poll(devices, cx)).is_err() {
                    break;
                }
            }
        })
    }

    fn poll(&mut self, devices: usb::Devices, cx: &mut Context<Self>) {
        // While a write runs, or the panel is out of sight, the last look
        // stays, so a change meanwhile is noticed after.
        if self.closed || self.phase != Phase::Choose || self.model.read(cx).page != Page::Iso {
            return;
        }
        if self.devices.as_ref() != Some(&devices) {
            self.devices = Some(devices);
            self.start_list(cx);
        }
        // Space freed on the Windows drive is noticed without asking.
        self.polls += 1;
        if self.check == IsoCheck::Failed(IsoProblem::WorkingSpace)
            && self.polls.is_multiple_of(SPACE_RECHECK_POLLS)
        {
            self.start_check(true, cx);
        }
        if self.check_busy && self.polls.is_multiple_of(BUSY_RECHECK_POLLS) {
            self.start_check(true, cx);
        }
    }

    /// Reads the drive list. One already being read is read again after.
    fn start_list(&mut self, cx: &mut Context<Self>) {
        if self.preview || !self.elevated(cx) || self.phase == Phase::Writing {
            return;
        }
        if self.held(cx) {
            self.pending.list = true;
            cx.notify();
            return;
        }
        if self.list_task.is_some() {
            self.list_again = true;
            return;
        }
        self.devices = Some(usb::devices());
        let cancel = Arc::new(AtomicBool::new(false));
        self.list_task = Some(self.spawn_job("List", None, cancel, cx, |this, result, job, cx| {
            this.list_task = None;
            match result {
                Ok(outcome) => {
                    this.drives = outcome.drives;
                    this.listed = true;
                    if this.error == Some(UsbError::Scan) {
                        this.error = None;
                    }
                }
                Err(error) => {
                    log::error!("USB drive list failed: {error:#}");
                    // A failed write's bar stays; it says more.
                    if this.error.is_none_or(|error| error == UsbError::Scan) {
                        this.error = Some(UsbError::Scan);
                        this.job = job;
                    }
                }
            }
            this.repick();
            if std::mem::take(&mut this.list_again) {
                this.start_list(cx);
            }
        }));
        cx.notify();
    }

    /// Checks the ISO. A check under way for an earlier ISO is stopped, and
    /// this one starts once it has. A `quiet` check keeps what the last one
    /// found on screen until it has an answer.
    fn start_check(&mut self, quiet: bool, cx: &mut Context<Self>) {
        if self.preview || !self.elevated(cx) || self.source.is_none() || self.phase == Phase::Writing {
            return;
        }
        self.check_busy = false;
        if self.held(cx) {
            self.pending.check = true;
            self.check = IsoCheck::None;
            cx.notify();
            return;
        }
        if !quiet {
            self.check = IsoCheck::Checking;
        }
        if let Some(cancel) = &self.check_cancel {
            cancel.store(true, Ordering::Relaxed);
            self.check_again = true;
            return;
        }
        let cancel = Arc::new(AtomicBool::new(false));
        self.check_cancel = Some(cancel.clone());
        self.check_task = Some(self.spawn_job("Check", None, cancel, cx, |this, result, job, cx| {
            this.check_task = None;
            this.check_cancel = None;
            // The answer is for an ISO since replaced.
            if std::mem::take(&mut this.check_again) {
                this.start_check(false, cx);
                return;
            }
            this.finish_check(result, job);
        }));
        cx.notify();
    }

    /// Takes in what a check found, and the job folder of one that failed.
    fn finish_check(&mut self, result: anyhow::Result<usb::Outcome>, job: Option<PathBuf>) {
        match result {
            // Another window's write or eject holds the worker, and may read
            // the ISO: nothing was checked, and nothing went wrong, so what
            // the page shows stays while it checks again shortly (see `poll`).
            Ok(outcome) if outcome.busy => {
                log::info!("USB ISO check waits for another Atlas USB operation");
                self.check_busy = true;
            }
            Ok(outcome) => {
                self.check = IsoCheck::Passed { bytes: outcome.bytes };
                self.check_job = None;
            }
            Err(error) => {
                log::error!("USB ISO check failed: {error:#}");
                let problem = match Failed::of("Check", false, error.downcast_ref()) {
                    Failed::Iso(problem) => problem,
                    _ => IsoProblem::Unreadable,
                };
                self.check = IsoCheck::Failed(problem);
                self.check_job = job.filter(|_| problem.needs_help());
            }
        }
        self.repick();
    }

    /// Asks before erasing the drive, naming it, its size and its letters.
    /// Cancel is the safe answer: it's the dialog's default, and Escape
    /// chooses it.
    fn confirm_erase(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(drive) = self.ready_drive(cx) else { return };
        if window.has_active_prompt() {
            return;
        }
        let title = erase_question(&drive);
        let message = t!("usb-confirm-message");
        let (cancel, erase) = (t!("common-cancel"), t!("usb-confirm-erase"));
        let answer = window.prompt(
            PromptLevel::Warning,
            &title,
            Some(&message),
            &[cancel.as_str(), erase.as_str()],
            cx,
        );
        cx.spawn(async move |this, cx| {
            if answer.await == Ok(1) {
                this.update(cx, |this, cx| this.write_confirmed(&drive, cx)).ok();
            }
        })
        .detach();
    }

    /// Writes the drive the user agreed to erase, as the list has it now:
    /// only if it's still the drive picked, still usable, and the very drive
    /// asked about, by the identity the worker checks. A drive the list only
    /// found again by its serial number, model and size is asked about again.
    fn write_confirmed(&mut self, confirmed: &Drive, cx: &mut Context<Self>) {
        let Some(drive) = self.ready_drive(cx).filter(|drive| drive.same_identity(confirmed)) else {
            cx.notify();
            return;
        };
        self.pick = Some(Pick { drive: drive.clone(), by_user: true });
        self.confirmed = Some(drive.clone());
        self.start_write(drive, cx);
    }

    /// Try again after a failed write: the same drive, which the user has
    /// already agreed to erase, while it's connected and picked, and its
    /// identity hasn't changed (see [`Self::write_confirmed`]).
    fn retry_drive(&self, cx: &App) -> Option<Drive> {
        let confirmed = self.confirmed.as_ref()?;
        self.ready_drive(cx).filter(|drive| drive.same_identity(confirmed))
    }

    fn start_write(&mut self, drive: Drive, cx: &mut Context<Self>) {
        if self.preview || self.held(cx) || self.phase != Phase::Choose {
            return;
        }
        self.error = None;
        self.phase = Phase::Writing;
        self.progress = Progress { stage: "prepare".into(), ..Default::default() };
        self.peak = 0.;
        let cancel = self.hold_app(cx);
        self.task = Some(self.spawn_job("Write", Some(drive), cancel, cx, |this, result, job, cx| {
            let cancelled = this.release_app(cx);
            match result {
                Ok(outcome) => this.finish_written(outcome.ejected),
                Err(error) => {
                    log::error!("USB write failed: {error:#}");
                    this.phase = Phase::Choose;
                    match Failed::of("Write", cancelled, error.downcast_ref()) {
                        Failed::Bar(failure) => {
                            this.error = Some(failure);
                            this.job = job;
                        }
                        Failed::Iso(problem) => this.check = IsoCheck::Failed(problem),
                        Failed::TooSmall => this.rejected.extend(this.confirmed.clone()),
                    }
                    this.repick();
                    // Picked again by its serial number, if it's still there;
                    // erasing it asks again.
                    if this.error == Some(UsbError::DriveChanged) {
                        this.start_list(cx);
                    }
                }
            }
        }));
        cx.notify();
    }

    /// Ejects the written drive again, after Windows refused.
    fn start_eject(&mut self, cx: &mut Context<Self>) {
        let Some(drive) = self.confirmed.clone() else { return };
        if self.preview || self.held(cx) {
            return;
        }
        self.error = None;
        self.phase = Phase::Writing;
        self.progress = Progress { stage: "eject".into(), ..Default::default() };
        self.peak = self.progress.overall();
        let cancel = self.hold_app(cx);
        self.task = Some(self.spawn_job("Eject", Some(drive), cancel, cx, |this, result, job, cx| {
            this.release_app(cx);
            let ejected = result.is_ok();
            if let Err(error) = result {
                log::error!("USB eject failed: {error:#}");
                this.job = job;
            }
            this.finish_written(ejected);
        }));
        cx.notify();
    }

    fn finish_written(&mut self, ejected: bool) {
        self.phase = Phase::Done { ejected };
        self.error = (!ejected).then_some(UsbError::Eject);
    }

    /// Holds the app while the drive changes: no navigation or close without
    /// asking, and no other job. Returns the flag that cancels the job.
    fn hold_app(&mut self, cx: &mut Context<Self>) -> Arc<AtomicBool> {
        let cancel = self.model.read(cx).iso_cancel.clone();
        cancel.store(false, Ordering::Relaxed);
        self.model.update(cx, |m, cx| {
            m.iso_busy = true;
            m.usb_busy = true;
            cx.notify();
        });
        cancel
    }

    /// Lets the app go after a write or eject. Returns whether it was cancelled.
    fn release_app(&mut self, cx: &mut Context<Self>) -> bool {
        let cancelled = self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
        self.model.update(cx, |m, cx| {
            m.iso_busy = false;
            m.usb_busy = false;
            cx.notify();
        });
        cancelled
    }

    /// Runs `operation` in a new job folder on a background thread, follows
    /// its progress, then hands `finish` its result and the job folder, when
    /// one was made.
    fn spawn_job(
        &mut self,
        operation: &'static str,
        drive: Option<Drive>,
        cancel: Arc<AtomicBool>,
        cx: &mut Context<Self>,
        finish: impl FnOnce(&mut Self, anyhow::Result<usb::Outcome>, Option<PathBuf>, &mut Context<Self>)
        + 'static,
    ) -> Task<()> {
        let source = self.source.clone();
        let builds = self.supported_builds.clone();
        let (tx, mut rx) = futures::channel::mpsc::unbounded();
        cx.spawn(async move |this, cx| {
            let work = cx.background_executor().spawn(async move {
                let Ok(job) = iso::new_job() else {
                    // Nothing ran, so nothing changed and there's no log.
                    return (Err(usb::Failure::new(None, false, "no job directory").into()), None);
                };
                iso::prune_jobs(&job);
                iso::prune_legacy_jobs(&settings::AppPaths::from_process().root);
                let result =
                    usb::run(operation, source.as_deref(), drive.as_ref(), &builds, &job, cancel, |p| {
                        let _ = tx.unbounded_send(p);
                    });
                let staged = job.is_dir();
                (result, staged.then_some(job))
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.progress = progress;
                    this.peak = this.peak.max(this.progress.overall());
                    cx.notify();
                })
                .ok();
            }
            let (result, job) = work.await;
            this.update(cx, |this, cx| {
                finish(this, result, job, cx);
                cx.notify();
            })
            .ok();
        })
    }

    fn relaunch_elevated(&mut self, cx: &mut Context<Self>) {
        if self.preview {
            return;
        }
        // The UAC prompt pumps a nested message loop inside ShellExecute;
        // keep it off the UI thread.
        cx.spawn(async move |this, cx| {
            let launched = cx.background_executor().spawn(async { system::relaunch_iso_elevated() }).await;
            this.update(cx, |this, cx| match launched {
                Ok(()) => cx.quit(),
                Err(error) => {
                    log::warn!("USB elevation was not completed: {error:#}");
                    this.elevation_declined = true;
                    cx.notify();
                }
            })
            .ok();
        })
        .detach();
    }

    fn close(&mut self, cx: &mut Context<Self>) {
        self.closed = true;
        if let Some(cancel) = &self.check_cancel {
            cancel.store(true, Ordering::Relaxed);
        }
        cx.notify();
    }

    /// Back, from the footer, the title's arrow or Escape alike: out of the
    /// panel, unless the drive is being written.
    pub fn back(&mut self, cx: &mut Context<Self>) {
        if self.phase != Phase::Writing {
            self.close(cx);
        }
    }
}

/// A drive's name as Windows reports it, or "USB drive" without one.
fn drive_name(drive: &Drive) -> String {
    let name = drive.name.trim();
    if name.is_empty() { t!("usb-drive") } else { name.to_owned() }
}

/// A size as drives are sold, as their packaging says: "256 GB".
fn sold_size_text(bytes: u64) -> String {
    match usb::sold_size(bytes) {
        SoldSize::Gigabytes(gb) => t!("usb-drive-size", size = gb),
        SoldSize::Terabytes(tb) => {
            t!("usb-drive-size-tb", size = fmt::decimal(tb, if tb.fract() == 0. { 0 } else { 1 }))
        }
    }
}

/// A drive's letters as Windows shows them, "F:" or "F:, G:", or `None`
/// when it has none.
fn drive_letters(drive: &Drive) -> Option<String> {
    let letters: Vec<String> = drive
        .letters
        .iter()
        .map(|letter| letter.trim())
        .filter(|letter| !letter.is_empty())
        .map(|letter| format!("{letter}:"))
        .collect();
    (!letters.is_empty()).then(|| letters.join(", "))
}

/// "256 GB · F:", leaving out the letters when it has none.
fn drive_detail(drive: &Drive) -> String {
    let size = sold_size_text(drive.size);
    match drive_letters(drive) {
        Some(letters) => [size, letters].join(&t!("usb-detail-separator")),
        None => size,
    }
}

/// The question before erasing, which names the drive as the list and
/// File Explorer do: "Erase Kingston DataTraveler Max (256 GB, F:)?". A
/// drive that reports no name has a question of its own, because the list's
/// "USB drive" doesn't read as a name inside it.
fn erase_question(drive: &Drive) -> String {
    let (name, size) = (drive.name.trim(), sold_size_text(drive.size));
    match (name.is_empty(), drive_letters(drive)) {
        (false, Some(letters)) => {
            t!("usb-confirm-title-letters", drive = name, size = size, letters = letters)
        }
        (false, None) => t!("usb-confirm-title", drive = name, size = size),
        (true, Some(letters)) => t!("usb-confirm-title-unnamed-letters", size = size, letters = letters),
        (true, None) => t!("usb-confirm-title-unnamed", size = size),
    }
}

/// The size of a row's mark: a radio button's, so marks and radio buttons
/// share the card's text edge and their text lines up.
const MARK: f32 = 20.;

/// A row that starts with a mark on the card's text edge, as a radio
/// button does, so its text lines up with the drives' names. With a
/// `detail` line, the mark sits on the first line.
fn mark_row(mark: impl IntoElement, detail: bool, text: impl IntoElement) -> Div {
    div()
        .flex()
        .items_start()
        .gap(px(12.))
        .child(
            TextMark::new(
                div().flex_shrink_0().size(px(MARK)).flex().items_center().justify_center().child(mark),
                detail,
            )
            .natural_text(),
        )
        .child(div().flex_1().min_w_0().child(text))
}

/// A stage's name in the checklist, which shows it done, under way or not
/// started.
fn stage_name(stage: Stage) -> String {
    match stage {
        Stage::Prepare => t!("usb-stage-prepare-files"),
        Stage::Format => t!("usb-stage-formatting"),
        Stage::Copy => t!("usb-stage-copying"),
        Stage::Verify => t!("usb-stage-checking"),
        Stage::Eject => t!("usb-stage-ejecting"),
    }
}

/// The stage under way, as the progress bar names it: "Formatting…". A
/// language whose stage names don't say they're under way says it here.
fn stage_label(stage: Stage) -> String {
    t!("iso-progress-stage", stage = stage_name(stage))
}

/// The write's stages as a checklist: done, the one `reported` last, and
/// not started.
fn stage_list(reported: Stage, cx: &App) -> Stateful<Div> {
    let theme = cx.theme();
    div()
        .id("usb-stages")
        .role(Role::List)
        .aria_label(t!("usb-progress-title"))
        .aria_size_of_set(Stage::ALL.len())
        .flex()
        .flex_col()
        .gap(px(8.))
        .children(Stage::ALL.into_iter().enumerate().map(|(index, stage)| {
            let title = stage_name(stage);
            let state = stage.cmp(&reported);
            let (glyph, colour, status): (AnyElement, _, _) = match state {
                std::cmp::Ordering::Less => {
                    (icon(Icon::Completed).into_any_element(), theme.success, t!("stepper-status-completed"))
                }
                std::cmp::Ordering::Equal => {
                    (ProgressRing::new().into_any_element(), theme.accent, t!("iso-stage-status-current"))
                }
                // An empty circle: the Completed glyph without its check.
                std::cmp::Ordering::Greater => (
                    div()
                        .size(px(14.))
                        .rounded_full()
                        .border_1()
                        .border_color(theme.control_strong_stroke)
                        .into_any_element(),
                    theme.text_secondary,
                    t!("iso-stage-status-not-started"),
                ),
            };
            div()
                .id(("usb-stage", index))
                .role(Role::ListItem)
                // No "Step N of M": the list gives "2 of 5".
                .aria_label(t!("iso-stage-a11y", title = title.clone(), status = status))
                // AccessKit counts from 0 and takes the size from the list.
                .aria_position_in_set(index)
                .flex()
                // The 16px glyphs start on the card's text edge, and the
                // names line up with a radio button's label.
                .gap(px(MARK - 16. + 12.))
                .child(
                    TextMark::new(
                        div()
                            .flex_shrink_0()
                            .size(px(16.))
                            .flex()
                            .items_center()
                            .justify_center()
                            .text_color(colour)
                            .child(glyph),
                        false,
                    )
                    .strong(),
                )
                .child(
                    div()
                        .flex_1()
                        .min_w_0()
                        .type_body()
                        .when(state == std::cmp::Ordering::Equal, |this| this.type_body_strong())
                        .text_color(if state == std::cmp::Ordering::Greater {
                            theme.text_secondary
                        } else {
                            theme.text_primary
                        })
                        .child(CapCenteredText(title.into())),
                )
        }))
}

impl Render for UsbPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let secondary = theme.text_secondary;
        let elevated = self.elevated(cx);
        let held = self.held(cx);
        let visit = self.model.read(cx).page_visit;
        let status = self.focus.get("usb-status", cx);
        let problem = match self.check {
            IsoCheck::Failed(problem) => Some(problem),
            _ => None,
        };
        // Results are announced by moving focus to them: a bar, the progress
        // heading, the ISO's problem, or the drive list.
        let shown = (self.phase, self.error, problem, held, self.elevation_declined, visit);
        let announce = self.shown != Some(shown);
        self.shown = Some(shown);
        if std::mem::take(&mut self.ask_on_open) {
            cx.defer_in(window, |this, window, cx| this.confirm_erase(window, cx));
        }
        let mut body: Vec<AnyElement> = Vec::new();
        let mut focus: Option<FocusHandle> = None;
        let mut help_drawn = false;

        // One bar at most, the first of: the permission Atlas needs, another
        // job holding the app, then what the last job came to.
        let bar_leads;
        if !elevated {
            // As the ISO page asks: a warning that says why, and the same after
            // Windows refused, with the relaunch as the way on.
            let message =
                if self.elevation_declined { t!("usb-elevation-declined") } else { t!("usb-admin-reason") };
            body.push(
                InfoBar::new(Severity::Warning, t!("usb-elevation-title"), message)
                    .id("usb-elevation")
                    .focus_handle(status.clone())
                    .action(
                        Button::new("usb-elevate", t!("common-restart-as-administrator"))
                            .accent()
                            .icon(Icon::Admin)
                            .on_click(cx.listener(|this, _, _, cx| this.relaunch_elevated(cx))),
                    )
                    .into_any_element(),
            );
            focus = Some(status.clone());
            bar_leads = true;
        } else if held {
            body.push(
                InfoBar::new(Severity::Informational, "", t!("iso-locked"))
                    .id("usb-locked")
                    .focus_handle(status.clone())
                    .into_any_element(),
            );
            focus = Some(status.clone());
            bar_leads = false;
        } else if let Some(error) = self.error {
            let (severity, title, message) = error.bar();
            let mut bar = InfoBar::new(severity, title, message).id("usb-error").focus_handle(status.clone());
            let try_again = |id: &'static str| Button::new(id, t!("common-try-again")).accent();
            let action = match error {
                UsbError::Scan => Some(
                    try_again("usb-retry-list").on_click(cx.listener(|this, _, _, cx| this.start_list(cx))),
                ),
                UsbError::Eject => Some(
                    try_again("usb-retry-eject").on_click(cx.listener(|this, _, _, cx| this.start_eject(cx))),
                ),
                UsbError::Write { .. } if self.retry_drive(cx).is_some() => {
                    Some(try_again("usb-retry-write").on_click(cx.listener(|this, _, _, cx| {
                        if let Some(drive) = this.retry_drive(cx) {
                            this.start_write(drive, cx);
                        }
                    })))
                }
                _ => None,
            };
            bar_leads = action.is_some();
            if let Some(action) = action {
                bar = bar.action(action);
            }
            if error.offers_help() {
                bar = bar.content(self.diagnostics.content_with_log(&self.model, self.job.clone(), cx));
                help_drawn = true;
            }
            body.push(bar.into_any_element());
            focus = Some(status.clone());
        } else {
            bar_leads = false;
        }

        let footer = match self.phase {
            Phase::Writing => {
                let stage = self.progress.stage();
                let cancelling = self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
                let heading = if cancelling { t!("iso-cancelling-short") } else { t!("usb-progress-title") };
                let percent = (self.peak * 100.).floor() as u64;
                body.push(
                    card(cx)
                        .child(
                            card_body()
                                .gap(px(12.))
                                .child(
                                    div()
                                        .flex()
                                        .flex_col()
                                        .gap(px(8.))
                                        .child(
                                            div()
                                                .flex()
                                                .items_center()
                                                .justify_between()
                                                .gap(px(16.))
                                                .child(
                                                    focusable_heading(
                                                        "usb-progress-title",
                                                        2,
                                                        heading,
                                                        &status,
                                                        cx,
                                                    )
                                                    .m(px(-1.))
                                                    .min_w_0(),
                                                )
                                                .child(
                                                    div()
                                                        .flex_shrink_0()
                                                        .type_body()
                                                        .text_color(secondary)
                                                        .child(a11y_text(
                                                            "usb-percent",
                                                            t!("usb-percent", percent = percent),
                                                        )),
                                                ),
                                        )
                                        // The one live node while writing: its name is the
                                        // stage under way, worded as the ISO's progress label,
                                        // since the stage names also label the checklist.
                                        .child(
                                            ProgressBar::new(
                                                "usb-progress",
                                                stage_label(stage),
                                                Some(self.peak),
                                            )
                                            .live(),
                                        ),
                                )
                                .child(stage_list(stage, cx))
                                .child(
                                    div()
                                        .type_body()
                                        .text_color(secondary)
                                        .child(detail_text("usb-keep-open", t!("usb-keep-open"))),
                                ),
                        )
                        .into_any_element(),
                );
                if focus.is_none() {
                    focus = Some(status.clone());
                }
                // An eject can't be stopped part way, and is soon over.
                let stoppable = !cancelling && stage != Stage::Eject;
                Some(CommandBar::new().cancel(
                    "usb-cancel",
                    t!("common-cancel"),
                    !stoppable,
                    cx.listener(|this, _, _, cx| {
                        this.model.update(cx, |m, cx| {
                            m.iso_cancel.store(true, Ordering::Relaxed);
                            cx.notify();
                        });
                    }),
                ))
            }
            Phase::Done { ejected } => {
                // A finished job's result is the page, as the finished ISO's is:
                // a tick, the heading and what to do next. A refused eject has
                // its bar instead, which says the drive is ready.
                if ejected {
                    body.push(self.complete_card(&status, cx));
                    if focus.is_none() {
                        focus = Some(status.clone());
                    }
                }
                let done = Button::new("usb-done", t!("common-done"))
                    .when(!bar_leads, Button::accent)
                    .on_click(cx.listener(|this, _, _, cx| this.close(cx)));
                Some(CommandBar::new().primary(done))
            }
            Phase::Choose => {
                let iso_leads = !bar_leads
                    && (matches!(self.check, IsoCheck::Failed(_))
                        || (self.source.is_none() && !self.finding_source));
                body.push(self.iso_card(iso_leads, !help_drawn, &mut focus, cx));
                // Drives are listed once Atlas has the permission to read them.
                let target = if elevated { self.drive_card(&mut body, held, cx) } else { None };
                // Focus follows the drive card's target when what it was on goes,
                // such as "Looking for USB drives…" when the list arrives.
                if let Some((key, handle)) = target {
                    if focus.is_none() {
                        focus = Some(handle.clone());
                    }
                    if let Some(previous) =
                        self.shown_target.replace(key.clone()).filter(|previous| *previous != key)
                        && self.focus.get(&previous, cx).is_focused(window)
                        && !announce
                    {
                        window.focus(&handle, cx);
                    }
                }
                // The bar's Try again writes the drive again; Create USB drive
                // would ask about the same drive, so it's hidden meanwhile.
                let retry_shown = matches!(self.error, Some(UsbError::Write { .. }))
                    && elevated
                    && !held
                    && self.retry_drive(cx).is_some();
                Some(self.choose_footer(bar_leads || iso_leads, elevated, held, !retry_shown, cx))
            }
        };
        if announce && let Some(focus) = focus {
            window.focus(&focus, cx);
        }
        self.diagnostics.settle(&self.model, window, cx);
        // The title's arrow, like Escape, goes where the footer's Back goes, so
        // every Back on a screen does the same thing.
        let entity = cx.entity();
        let back = PanelBack {
            enabled: self.phase != Phase::Writing,
            on_back: Rc::new(move |_, cx| entity.update(cx, |this, cx| this.back(cx))),
        };
        page_frame(
            "usb-page",
            Some(PageTitle { text: t!("usb-title").into(), badge: None, back: Some(back) }),
            None,
            None,
            (&self.scroll, &self.scrollbar),
            body,
            footer.map(IntoElement::into_any_element),
            cx,
        )
    }
}

impl UsbPage {
    /// The ISO card: the file, with Change, and what its check found. With a
    /// problem, the fix is its accent button when `leads`; Get help goes
    /// under an unexpected one when `help` is free to draw.
    fn iso_card(
        &mut self,
        leads: bool,
        help: bool,
        focus: &mut Option<FocusHandle>,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let theme = cx.theme().clone();
        let status = self.focus.get("usb-iso-problem", cx);
        let problem = match self.check {
            IsoCheck::Failed(problem) => Some(problem),
            _ => None,
        };
        let choose = |id: &'static str, cx: &mut Context<Self>| {
            Button::new(id, t!("iso-use-local"))
                .icon(Icon::Folder)
                .when(leads, Button::accent)
                .on_click(cx.listener(|this, _, _, cx| this.choose_iso(cx)))
        };
        let mut content = card_body().child(card_title(cx, "usb-iso", t!("usb-iso-title"), 2));
        let Some(path) = &self.source else {
            if !self.finding_source {
                content = content.child(
                    div()
                        .flex()
                        .flex_wrap()
                        .items_center()
                        .gap_x(px(16.))
                        .gap_y(px(8.))
                        .child(
                            div()
                                .flex_1()
                                .min_w(px(200.))
                                .type_body()
                                .text_color(theme.text_secondary)
                                .child(detail_text("usb-iso-missing", t!("usb-iso-missing"))),
                        )
                        .child(choose("usb-choose-iso", cx)),
                );
            }
            return card(cx).child(content).into_any_element();
        };
        let name = path
            .file_name()
            .map(|name| name.to_string_lossy().into_owned())
            .unwrap_or_else(|| path.display().to_string());
        let folder = path.parent().map(|parent| parent.display().to_string()).unwrap_or_default();
        // The fix for an ISO that can't be used is another one, under the problem.
        let change =
            !matches!(problem, Some(IsoProblem::Unsupported | IsoProblem::Location | IsoProblem::MountFile));
        content = content.child(
            div()
                .flex()
                .items_start()
                .gap(px(16.))
                .child(
                    div()
                        .flex_1()
                        .min_w_0()
                        .flex()
                        .flex_col()
                        .child(
                            div()
                                .type_body()
                                .text_color(theme.text_primary)
                                .child(detail_text("usb-iso-name", name)),
                        )
                        .when(!folder.is_empty(), |this| {
                            this.child(
                                div()
                                    .type_caption()
                                    .text_color(theme.text_secondary)
                                    .child(detail_text("usb-iso-folder", folder)),
                            )
                        }),
                )
                .when(change, |this| {
                    this.child(
                        // The 24px compact link's text lines up with the 20px body line.
                        div().flex_shrink_0().mt(px(-2.)).child(
                            Button::new("usb-change-iso", t!("common-change"))
                                .hyperlink()
                                .compact()
                                // The card's title as shown, after a colon, as the
                                // ISO page names what its Change links change.
                                .aria_label(t!(
                                    "iso-pick-a11y",
                                    action = t!("common-change"),
                                    field = t!("usb-iso-title")
                                ))
                                .on_click(cx.listener(|this, _, _, cx| this.choose_iso(cx))),
                        ),
                    )
                }),
        );
        // What the check says goes on a line of its own, its mark in the line.
        let status_line = |mark: AnyElement, text: AnyElement| {
            div()
                .flex()
                .items_start()
                .gap(px(8.))
                .child(div().flex().flex_shrink_0().items_center().h(BODY_LINE_HEIGHT).child(mark))
                .child(div().flex_1().min_w_0().type_body().child(text))
        };
        match self.check {
            IsoCheck::Checking => {
                content = content.child(status_line(
                    ProgressRing::new().into_any_element(),
                    div()
                        .text_color(theme.text_secondary)
                        .child(detail_text("usb-iso-checking", t!("usb-iso-checking")))
                        .into_any_element(),
                ));
            }
            IsoCheck::Failed(problem) => {
                let message = problem.text();
                let fix = match problem {
                    IsoProblem::Unsupported | IsoProblem::Location | IsoProblem::MountFile => {
                        choose("usb-iso-fix", cx)
                    }
                    IsoProblem::WorkingSpace => Button::new("usb-iso-fix", t!("usb-open-storage"))
                        .when(leads, Button::accent)
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(STORAGE_SETTINGS),
                    IsoProblem::Unreadable
                    | IsoProblem::Mount
                    | IsoProblem::MountDrivers
                    | IsoProblem::MountTimeout => Button::new("usb-iso-fix", t!("common-try-again"))
                        .when(leads, Button::accent)
                        .on_click(cx.listener(|this, _, _, cx| this.start_check(false, cx))),
                };
                let help = help && problem.needs_help();
                content = content.child(
                    div()
                        .id("usb-iso-problem")
                        .role(Role::Group)
                        .aria_label(message.clone())
                        .track_focus(&status.clone().tab_stop(false))
                        .flex()
                        .flex_col()
                        .gap(px(8.))
                        .child(status_line(
                            icon(Icon::ErrorBadge).text_color(theme.critical).into_any_element(),
                            div()
                                .text_color(theme.text_primary)
                                .child(detail_text("usb-iso-problem", message))
                                .into_any_element(),
                        ))
                        .child(div().flex().child(fix))
                        .when(help, |this| {
                            this.child(self.diagnostics.content_with_log(
                                &self.model,
                                self.check_job.clone(),
                                cx,
                            ))
                        }),
                );
                if focus.is_none() {
                    *focus = Some(status);
                }
            }
            IsoCheck::None | IsoCheck::Passed { .. } => {}
        }
        card(cx).child(content).into_any_element()
    }

    /// The drive card, pushed onto `body`: the drives, with those that can't
    /// be used shown unavailable and why, or what to connect. Returns where
    /// focus goes to announce it, with a stable key: the drive picked, or the
    /// first usable one, or the text that says what's missing.
    fn drive_card(
        &mut self,
        body: &mut Vec<AnyElement>,
        held: bool,
        cx: &mut Context<Self>,
    ) -> Option<(String, FocusHandle)> {
        // Before the first list, a bar says what it waits for.
        if !self.listed && (held || self.error == Some(UsbError::Scan)) {
            return None;
        }
        let theme = cx.theme().clone();
        let selected = self.selected();
        let reasons: Vec<Option<Unusable>> = self.drives.iter().map(|drive| self.unusable(drive)).collect();
        let status_key = "usb-drive-status".to_owned();
        let status = self.focus.get(&status_key, cx);
        let status_text = |id: &'static str, text: String, looking: bool| {
            let mark = if looking {
                ProgressRing::new().size(MARK).into_any_element()
            } else {
                icon_sized(Icon::Usb, MARK).text_color(theme.text_secondary).into_any_element()
            };
            // The group's name carries the text, so it is read once.
            div()
                .id(id)
                .role(Role::Group)
                .aria_label(text.clone())
                .track_focus(&status.clone().tab_stop(false))
                .child(mark_row(mark, false, div().type_body().text_color(theme.text_secondary).child(text)))
        };
        let connect = t!("usb-connect", size = usb::MIN_SOLD_GB);
        let mut content = card_body().child(card_title(cx, "usb-drives", t!("usb-drive"), 2));
        let target;
        if !self.listed {
            content = content.child(status_text("usb-looking", t!("usb-looking"), true));
            target = (status_key, status.clone());
        } else if self.drives.is_empty() {
            content = content.child(status_text("usb-connect", connect, false));
            target = (status_key, status.clone());
        } else {
            let first_usable = reasons.iter().position(Option::is_none);
            let target_index = selected.or(first_usable);
            let items: Vec<RadioItem> = self
                .drives
                .iter()
                .zip(&reasons)
                .enumerate()
                .map(|(i, (drive, reason))| {
                    let handle = self.focus.get(&format!("usb-drive-{i}"), cx);
                    let mut detail = drive_detail(drive);
                    if let Some(reason) = reason {
                        detail = format!("{detail}\n{}", reason.text());
                    }
                    // The reason a drive can't be used stays readable on it.
                    RadioItem::new(("usb-drive", i), drive_name(drive), handle)
                        .description(detail)
                        .disabled(reason.is_some())
                        .readable_description()
                })
                .collect();
            let entity = cx.entity();
            content = content.child(
                RadioGroup::new("usb-drive-list", t!("usb-drive")).items(items).selected(selected).on_select(
                    move |index, _, cx| {
                        entity.update(cx, |this, cx| {
                            if let Some(drive) = this.drives.get(index).filter(|d| this.unusable(d).is_none())
                            {
                                this.pick = Some(Pick { drive: drive.clone(), by_user: true });
                                cx.notify();
                            }
                        })
                    },
                ),
            );
            target = match target_index {
                Some(index) => {
                    let key = format!("usb-drive-{index}");
                    let handle = self.focus.get(&key, cx);
                    (key, handle)
                }
                None => {
                    // Every drive listed is unavailable: what would do instead.
                    content = content.child(status_text("usb-connect", connect, false));
                    (status_key, status.clone())
                }
            };
        }
        body.push(card(cx).child(content).into_any_element());
        Some(target)
    }

    /// Back, and Create USB drive when `create` says it's offered: the accent
    /// unless something above leads. While it can't be chosen, the reason is
    /// read with it, and shown only when nothing on the page says it already.
    fn choose_footer(
        &self,
        other_leads: bool,
        elevated: bool,
        held: bool,
        create: bool,
        cx: &mut Context<Self>,
    ) -> CommandBar {
        let ready = self.ready_drive(cx).is_some();
        let (hint, shown) = if ready || !elevated {
            // Without the permission, the bar says what's needed.
            (String::new(), false)
        } else if held {
            (t!("iso-locked"), false)
        } else if self.source.is_none() {
            (if self.finding_source { String::new() } else { t!("usb-iso-missing") }, false)
        } else if let IsoCheck::Failed(problem) = self.check {
            (problem.text(), false)
        } else if self.bytes().is_none() {
            (t!("usb-iso-checking"), false)
        } else if !self.listed {
            (t!("usb-looking"), false)
        } else if !self.drives.iter().any(|drive| self.unusable(drive).is_none()) {
            (t!("usb-connect", size = usb::MIN_SOLD_GB), false)
        } else {
            (t!("usb-hint-pick"), true)
        };
        let back =
            Button::new("usb-close", t!("common-back")).on_click(cx.listener(|this, _, _, cx| this.back(cx)));
        let bar = CommandBar::new().back(back);
        if !create {
            return bar;
        }
        let create = Button::new("usb-create", t!("usb-create"))
            .when(!other_leads, Button::accent)
            .disabled(!ready)
            .when(!ready && !hint.is_empty(), |button| button.aria_description(hint.clone()))
            .on_click(cx.listener(|this, _, window, cx| this.confirm_erase(window, cx)));
        bar.hint(if shown { hint } else { String::new() }).primary(create)
    }

    /// The finished drive, as the finished ISO shows itself: a tick, the
    /// heading that takes focus, and what to do with the drive.
    fn complete_card(&self, focus: &FocusHandle, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        card(cx)
            .child(
                card_body()
                    .gap(px(8.))
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(12.))
                            .child(
                                TextMark::new(
                                    div().text_color(theme.success).child(icon(Icon::Completed)),
                                    false,
                                )
                                .natural_text(),
                            )
                            .child(
                                focusable_heading("usb-complete", 2, t!("usb-complete-title"), focus, cx)
                                    .type_subtitle(),
                            ),
                    )
                    .child(div().type_body().child(detail_text("usb-ready", t!("usb-ready")))),
            )
            .into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn failure(reason: Option<FailureReason>, drive_changed: bool) -> anyhow::Error {
        usb::Failure::new(reason, drive_changed, "test").into()
    }

    #[test]
    fn a_write_that_stopped_before_erasing_says_what_to_change_where_it_applies() {
        let of = |reason, changed| Failed::of("Write", false, failure(reason, changed).downcast_ref());
        // What the check would have found is shown on the ISO, or the drive.
        assert_eq!(of(Some(FailureReason::IsoUnsupported), false), Failed::Iso(IsoProblem::Unsupported));
        assert_eq!(of(Some(FailureReason::SourceLocation), false), Failed::Iso(IsoProblem::Location));
        assert_eq!(of(Some(FailureReason::WorkingSpace), false), Failed::Iso(IsoProblem::WorkingSpace));
        assert_eq!(of(Some(FailureReason::DoesNotFit), false), Failed::TooSmall);
        assert_eq!(of(Some(FailureReason::DriveChanged), false), Failed::Bar(UsbError::DriveChanged));
        assert_eq!(of(None, false), Failed::Bar(UsbError::Write { changed: false }));
        // Past preparing, or with no account from the worker, the drive may be partly written.
        assert_eq!(
            of(Some(FailureReason::DriveChanged), true),
            Failed::Bar(UsbError::Write { changed: true })
        );
        assert_eq!(
            of(Some(FailureReason::DriveUnavailable), true),
            Failed::Bar(UsbError::Write { changed: true })
        );
        assert_eq!(Failed::of("Write", false, None), Failed::Bar(UsbError::Write { changed: true }));
        let cancelled = |changed| Failed::of("Write", true, failure(None, changed).downcast_ref());
        assert_eq!(cancelled(false), Failed::Bar(UsbError::Cancelled { changed: false }));
        assert_eq!(cancelled(true), Failed::Bar(UsbError::Cancelled { changed: true }));
    }

    #[test]
    fn a_check_says_what_is_wrong_with_the_iso() {
        let of = |reason| Failed::of("Check", false, failure(reason, false).downcast_ref());
        assert_eq!(of(Some(FailureReason::IsoUnsupported)), Failed::Iso(IsoProblem::Unsupported));
        assert_eq!(of(Some(FailureReason::WorkingSpace)), Failed::Iso(IsoProblem::WorkingSpace));
        assert_eq!(of(None), Failed::Iso(IsoProblem::Unreadable));
        // Windows couldn't open it as a drive: the card says so, with help.
        assert_eq!(of(Some(FailureReason::IsoMount)), Failed::Iso(IsoProblem::Mount));
        assert_eq!(of(Some(FailureReason::IsoMountDrivers)), Failed::Iso(IsoProblem::MountDrivers));
        assert_eq!(of(Some(FailureReason::IsoMountFile)), Failed::Iso(IsoProblem::MountFile));
        assert_eq!(of(Some(FailureReason::IsoMountTimeout)), Failed::Iso(IsoProblem::MountTimeout));
        for problem in [IsoProblem::Unreadable, IsoProblem::Mount, IsoProblem::MountTimeout] {
            assert!(problem.needs_help(), "{problem:?}");
        }
        // The card's message has the fix: other media, space, drivers or a copy.
        for problem in [
            IsoProblem::Unsupported,
            IsoProblem::Location,
            IsoProblem::WorkingSpace,
            IsoProblem::MountDrivers,
            IsoProblem::MountFile,
        ] {
            assert!(!problem.needs_help(), "{problem:?}");
        }
        assert_eq!(Failed::of("List", true, None), Failed::Bar(UsbError::Scan));
        assert_eq!(Failed::of("Eject", false, None), Failed::Bar(UsbError::Eject));
    }

    #[test]
    fn only_unexpected_failures_offer_help() {
        for error in [UsbError::Scan, UsbError::Write { changed: true }, UsbError::Write { changed: false }] {
            assert!(error.offers_help(), "{error:?}");
        }
        for error in [
            UsbError::Eject,
            UsbError::DriveChanged,
            UsbError::Cancelled { changed: true },
            UsbError::Cancelled { changed: false },
        ] {
            assert!(!error.offers_help(), "{error:?}");
        }
        crate::i18n::testing::english(|| {
            assert_eq!(UsbError::Write { changed: true }.bar().0, Severity::Error);
            assert_eq!(UsbError::Eject.bar().0, Severity::Warning, "the drive is still ready");
            assert_eq!(UsbError::DriveChanged.bar().0, Severity::Informational, "nothing was erased");
            assert_eq!(UsbError::Cancelled { changed: false }.bar().0, Severity::Informational);
            assert_eq!(
                UsbError::Cancelled { changed: true }.bar().0,
                Severity::Warning,
                "the drive can't be used as it is"
            );
        });
    }

    #[test]
    fn the_erase_question_names_the_drive_its_size_and_its_letters() {
        crate::i18n::testing::english(|| {
            let [drive, ..] = usb::preview_drives();
            assert_eq!(erase_question(&drive), "Erase Kingston DataTraveler Max (256 GB, F:)?");
            let two = Drive { letters: vec!["F".into(), " G ".into()], ..drive.clone() };
            assert_eq!(erase_question(&two), "Erase Kingston DataTraveler Max (256 GB, F:, G:)?");
            // A drive an unfinished write left has no letter to name.
            let bare = Drive { letters: vec![" ".into()], ..drive.clone() };
            assert_eq!(erase_question(&bare), "Erase Kingston DataTraveler Max (256 GB)?");
            // A drive that reports no name isn't asked about by its fallback name.
            let unnamed = Drive { name: " ".into(), ..drive };
            assert_eq!(erase_question(&unnamed), "Erase the USB drive (256 GB, F:)?");
            assert_eq!(
                erase_question(&Drive { letters: vec![], ..unnamed }),
                "Erase the USB drive (256 GB)?"
            );
        });
    }

    /// The checklist shows a stage's bare name; only the progress bar says
    /// it's under way, as the ISO's does.
    #[test]
    fn the_progress_bar_words_the_stage_as_under_way() {
        crate::i18n::testing::english(|| {
            assert_eq!(stage_name(Stage::Format), "Formatting");
            assert_eq!(stage_label(Stage::Format), "Formatting…");
        });
    }

    #[test]
    fn a_drive_too_small_says_what_size_would_do() {
        crate::i18n::testing::english(|| {
            assert_eq!(Unusable::TooSmall.text(), "Too small. Needs 16 GB or more.");
        });
    }

    #[test]
    fn no_message_tells_people_which_button_to_press() {
        crate::i18n::testing::english(|| {
            let mut texts: Vec<String> = [
                UsbError::Scan,
                UsbError::Eject,
                UsbError::DriveChanged,
                UsbError::Cancelled { changed: true },
                UsbError::Cancelled { changed: false },
                UsbError::Write { changed: true },
                UsbError::Write { changed: false },
            ]
            .into_iter()
            .map(|error| error.bar().2)
            .collect();
            texts.extend(
                [
                    IsoProblem::Unsupported,
                    IsoProblem::Location,
                    IsoProblem::WorkingSpace,
                    IsoProblem::Unreadable,
                    IsoProblem::Mount,
                    IsoProblem::MountDrivers,
                    IsoProblem::MountFile,
                    IsoProblem::MountTimeout,
                ]
                .map(IsoProblem::text),
            );
            texts.extend([
                t!("usb-connect", size = usb::MIN_SOLD_GB),
                t!("usb-iso-missing"),
                t!("usb-ready"),
            ]);
            for text in texts {
                for word in ["Choose", "choose", "Select", "select", "Refresh", "Review"] {
                    assert!(!text.contains(word), "{text}");
                }
            }
        });
    }

    #[test]
    fn a_drive_shows_its_size_as_sold_and_its_letters() {
        crate::i18n::testing::english(|| {
            let [drive, ..] = usb::preview_drives();
            assert_eq!(drive_detail(&drive), "256 GB · F:");
            let two = Drive { letters: vec!["F".into(), "G".into()], ..drive.clone() };
            assert_eq!(drive_detail(&two), "256 GB · F:, G:");
            let bare = Drive { letters: vec![], name: " ".into(), ..drive };
            assert_eq!(drive_detail(&bare), "256 GB");
            assert_eq!(drive_name(&bare), t!("usb-drive"));
            assert_eq!(sold_size_text(1_000_204_886_016), "1 TB");
        });
    }

    #[test]
    fn drives_that_cant_be_written_say_why() {
        let [drive, _, small] = usb::preview_drives();
        let iso = Path::new(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso");
        let app = Path::new(r"C:\Users\Atlas\Downloads\AtlasManager.exe");
        assert_eq!(unusable(&drive, Some(iso), Some(app), Some(6_500_000_000), &[]), None);
        assert_eq!(unusable(&small, Some(iso), Some(app), None, &[]), Some(Unusable::TooSmall));
        assert_eq!(
            unusable(&drive, Some(Path::new(r"F:\Atlas.iso")), None, None, &[]),
            Some(Unusable::HoldsIso)
        );
        assert_eq!(
            unusable(&drive, None, Some(Path::new(r"f:\AtlasManager.exe")), None, &[]),
            Some(Unusable::HoldsApp)
        );
        // The ISO's files must fit the partition, at most 32 GB.
        assert_eq!(
            unusable(&drive, Some(iso), None, Some(40_000_000_000), &[]),
            Some(Unusable::TooSmallForIso)
        );
        // A write that found it too small is believed.
        let rejected = [Drive { number: 9, ..drive.clone() }];
        assert_eq!(unusable(&drive, Some(iso), None, Some(1), &rejected), Some(Unusable::TooSmallForIso));
    }

    #[test]
    fn atlas_picks_the_only_usable_drive_and_keeps_the_users_choice() {
        let [a, b, small] = usb::preview_drives();
        let all = vec![a.clone(), b.clone(), small.clone()];
        let usable = [true, true, false];
        // One usable drive is picked by itself; two wait for the user.
        let only = repick(None, &[a.clone(), small.clone()], &[true, false]);
        assert_eq!(only, Some(Pick { drive: a.clone(), by_user: false }));
        assert_eq!(repick(None, &all, &usable), None);
        // A pick follows its drive to the new record, renumbered.
        let renumbered = Drive { number: 8, unique_id: "new".into(), ..a.clone() };
        let user = Some(Pick { drive: a.clone(), by_user: true });
        assert_eq!(
            repick(user.clone(), &[renumbered.clone(), b.clone()], &[true, true]),
            Some(Pick { drive: renumbered, by_user: true })
        );
        // The user's drive, gone, stays picked for when it comes back, and
        // another isn't picked in its place.
        assert_eq!(repick(user.clone(), std::slice::from_ref(&b), &[true]), user);
        // Atlas's own pick, gone, gives way to the only drive left.
        let auto = Some(Pick { drive: a.clone(), by_user: false });
        assert_eq!(repick(auto, std::slice::from_ref(&b), &[true]), Some(Pick { drive: b, by_user: false }));
        // A drive that can't be used is never picked.
        assert_eq!(repick(None, std::slice::from_ref(&small), &[false]), None);
    }

    #[test]
    fn work_asked_for_while_atlas_is_busy_waits_for_it() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::preparation::State;
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-locked");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            // A look for the Windows Update offer, started while the ISO page is open.
            model.update(&mut cx, |m, _| {
                m.page = Page::Iso;
                m.preparation = State::Running { stage: Default::default(), completed: 0, total: 0 };
            });
            let iso = PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso");
            let panel = cx.update(|cx| cx.new(|cx| UsbPage::new(model.clone(), Some(iso), vec![], None, cx)));
            // The list and the check asked for on opening wait, instead of
            // reading as no drives at all.
            cx.background_executor().timer(Duration::from_millis(50)).await;
            panel.update(&mut cx, |panel, cx| {
                assert_eq!(panel.pending, Pending { list: true, check: true });
                assert!(panel.list_task.is_none() && panel.check_task.is_none() && panel.error.is_none());
                assert!(panel.take_due(model.read(cx)) == Pending::default());
                assert!(panel.pending.list, "still waiting while the look runs");
                model.update(cx, |m, _| m.preparation = State::Ready);
                assert_eq!(panel.take_due(model.read(cx)), Pending { list: true, check: true });
                assert_eq!(
                    panel.take_due(model.read(cx)),
                    Pending::default(),
                    "one job's end starts it once"
                );
                panel.pending.list = true;
                model.update(cx, |m, _| m.page = Page::Install);
                assert_eq!(panel.take_due(model.read(cx)), Pending::default(), "not while out of sight");
                assert!(panel.pending.list);
            });
        });
    }

    #[test]
    fn create_waits_for_a_checked_iso_and_a_usable_drive() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-ready");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let panel =
                cx.update(|cx| cx.new(|cx| UsbPage::new(model, None, vec![], Some("usb-select"), cx)));
            panel.update(&mut cx, |panel, cx| {
                let [drive, other, _] = usb::preview_drives();
                assert_eq!(panel.ready_drive(cx), Some(drive.clone()), "the only drive is picked");
                panel.check = IsoCheck::Checking;
                assert_eq!(panel.ready_drive(cx), None);
                panel.check = IsoCheck::Passed { bytes: 6_500_000_000 };
                // Another drive arrives: the pick stays.
                panel.drives.push(other.clone());
                panel.repick();
                assert_eq!(panel.ready_drive(cx), Some(drive.clone()));
                // The picked drive goes, leaving one.
                panel.drives = vec![other.clone()];
                panel.repick();
                assert_eq!(
                    panel.ready_drive(cx),
                    Some(other),
                    "Atlas's own pick gives way to the only drive"
                );
                // Back leaves the panel.
                panel.back(cx);
                assert!(panel.closed);
            });
        });
    }

    /// A drive found again only by its serial number, model and size, as a
    /// generic flash drive's twin would be, is picked, but erasing it asks
    /// again, and so does Try again; the drive the user agreed to is written.
    #[test]
    fn only_the_drive_the_user_agreed_to_erase_is_written() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-confirmed");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let panel =
                cx.update(|cx| cx.new(|cx| UsbPage::new(model, None, vec![], Some("usb-select"), cx)));
            panel.update(&mut cx, |panel, cx| {
                let [drive, ..] = usb::preview_drives();
                let twin = Drive { number: 5, unique_id: "twin".into(), ..drive.clone() };
                panel.drives = vec![twin.clone()];
                panel.repick();
                assert_eq!(panel.ready_drive(cx), Some(twin.clone()), "the twin is picked");
                panel.write_confirmed(&drive, cx);
                assert_eq!(panel.confirmed, None, "nothing is written without asking again");
                panel.confirmed = Some(drive.clone());
                assert_eq!(panel.retry_drive(cx), None, "Try again asks again too");
                panel.confirmed = None;
                panel.write_confirmed(&twin, cx);
                assert_eq!(panel.confirmed, Some(twin), "the drive agreed to is written");
            });
        });
    }

    /// A check that finds another window's write or eject under way reads
    /// nothing; the page keeps checking, with no failure, and checks again.
    #[test]
    fn a_check_another_write_holds_up_runs_again_without_a_failure() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-check-busy");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let panel =
                cx.update(|cx| cx.new(|cx| UsbPage::new(model, None, vec![], Some("usb-select"), cx)));
            panel.update(&mut cx, |panel, _| {
                panel.check = IsoCheck::Checking;
                let busy: usb::Outcome = serde_json::from_str(r#"{"busy":true}"#).unwrap();
                panel.finish_check(Ok(busy), Some(PathBuf::from("job")));
                assert_eq!(panel.check, IsoCheck::Checking, "no failure, and no pass either");
                assert!(panel.check_busy, "it checks again");
                assert_eq!(panel.check_job, None);
                let passed: usb::Outcome = serde_json::from_str(r#"{"checked":true,"bytes":5}"#).unwrap();
                panel.finish_check(Ok(passed), None);
                assert_eq!(panel.check, IsoCheck::Passed { bytes: 5 });
            });
        });
    }

    #[test]
    fn a_write_in_progress_keeps_the_panel_and_its_drive() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-writing");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let panel =
                cx.update(|cx| cx.new(|cx| UsbPage::new(model, None, vec![], Some("usb-progress"), cx)));
            panel.update(&mut cx, |panel, cx| {
                let before = panel.pick.clone();
                assert!(before.is_some());
                panel.back(cx);
                assert!(!panel.closed, "Back waits for the write");
                // A list that ends meanwhile, without the drive, changes nothing picked.
                let [_, other, _] = usb::preview_drives();
                panel.drives = vec![other];
                panel.repick();
                assert_eq!(panel.pick, before);
            });
        });
    }
}
