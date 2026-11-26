//! Installation media: an Atlas ISO made in three steps. Windows asks which
//! PC the ISO is for and where Windows comes from, and checks the files by
//! itself; Setup holds the edition, the account, the drivers and the Atlas
//! choices; Create reviews them, builds the ISO and shows how it ended. The
//! USB panel can then write the ISO to a drive. It runs apart from the
//! install flow and its checks of this PC.

mod create;
mod download;
mod menu;
mod setup;

use std::cell::Cell;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::atomic::Ordering;

use futures::StreamExt;
use gpui::{
    AnyElement, App, Bounds, Context, Div, Entity, FocusHandle, Hsla, IntoElement, ParentElement,
    PathPromptOptions, Pixels, Point, Render, Role, ScrollHandle, Stateful, Task, Window, div, prelude::*,
    px,
};

use super::usb::UsbPage;
use super::{
    CommandBar, Diagnostics, PageTitle, StepStatus, Stepper, card_body, card_title, detail_text,
    manager_download_button, page_frame,
};
use crate::i18n::{describe, fmt};
use crate::model::{AcquireProblem, Acquisition, AppModel, Page, ReleaseCheck};
use crate::services::iso::{self, Architecture, FailureReason, ImageInfo, Mode, Stage, UsernameProblem};
use crate::services::package::{self, Manifest};
use crate::services::preparation::Drivers;
use crate::services::{settings, system};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::text_input::TextInput;
use crate::ui::{
    Button, CapCenteredText, FocusHandles, Icon, InfoBar, LightState, ProgressBar, ProgressRing, RadioGroup,
    RadioItem, ScrollbarState, Severity, StatusLight, TextMark, Typography, a11y_text, card, icon, link_row,
};

/// The new ISO's name, unless the user chooses another.
const OUTPUT_STEM: &str = "Atlas-Windows";
/// How often the Create step reads a volume short of space again.
const SPACE_RECHECK: std::time::Duration = std::time::Duration::from_secs(5);
/// Windows Settings' Storage page, where space can be freed.
const STORAGE_SETTINGS: &str = "ms-settings:storagesense";

/// The steps of making an ISO, in order.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
enum IsoStep {
    /// Which PC the ISO is for, the Windows ISO and the Atlas package.
    Windows,
    /// The Windows the ISO installs and how Atlas is set up from it.
    Setup,
    /// A review of everything, then the build.
    Create,
}

impl IsoStep {
    const ALL: [IsoStep; 3] = [IsoStep::Windows, IsoStep::Setup, IsoStep::Create];

    fn index(self) -> usize {
        self as usize
    }

    fn title(self) -> String {
        match self {
            IsoStep::Windows => t!("iso-step-source"),
            IsoStep::Setup => t!("iso-step-setup"),
            IsoStep::Create => t!("iso-step-create"),
        }
    }

    fn previous(self) -> Option<Self> {
        self.index().checked_sub(1).map(|index| Self::ALL[index])
    }

    fn next(self) -> Option<Self> {
        Self::ALL.get(self.index() + 1).copied()
    }
}

/// What each step asks for before the flow moves past it.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct Gates {
    /// Windows: the files passed the check, and none was chosen again since.
    checked: bool,
    /// Setup: a local account name Windows accepts.
    account: bool,
}

impl Gates {
    fn passes(self, step: IsoStep) -> bool {
        match step {
            IsoStep::Windows => self.checked,
            IsoStep::Setup => self.account,
            IsoStep::Create => true,
        }
    }

    /// Whether the stepper can go from `current` to `target`: back to any
    /// earlier step, or forward to one visited before (up to `furthest`)
    /// while every step on the way is still done.
    fn reachable(self, current: IsoStep, target: IsoStep, furthest: IsoStep) -> bool {
        if target <= current {
            return target < current;
        }
        target <= furthest
            && IsoStep::ALL[current.index()..target.index()].iter().all(|step| self.passes(*step))
    }
}

/// Where a step stands in the stepper. A step the user went past, and that
/// still holds, is done, even while an earlier step is showing again.
fn step_status(step: IsoStep, current: IsoStep, furthest: IsoStep, gates: Gates) -> StepStatus {
    match StepStatus::by_position(step.index(), current.index()) {
        StepStatus::Done if !gates.passes(step) => StepStatus::Attention,
        StepStatus::Upcoming if step < furthest && gates.passes(step) => StepStatus::Done,
        status => status,
    }
}

/// A file the Windows step asks for.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Field {
    Source,
    Package,
}

/// How the last check or build ended.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum JobResult {
    None,
    Complete,
    Cancelled,
    /// With the worker's reason, when it gave one.
    Failed(Option<FailureReason>),
}

/// Where a stage of a build stands, against the stage reported last.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StageState {
    Done,
    Current,
    Failed,
    NotStarted,
}

fn stage_state(stage: Stage, reported: Stage, failed: bool) -> StageState {
    match stage.cmp(&reported) {
        std::cmp::Ordering::Less => StageState::Done,
        std::cmp::Ordering::Equal if failed => StageState::Failed,
        std::cmp::Ordering::Equal => StageState::Current,
        std::cmp::Ordering::Greater => StageState::NotStarted,
    }
}

fn stage_text(stage: Stage) -> String {
    match stage {
        Stage::Inspect => t!("iso-stage-read"),
        Stage::Copy => t!("iso-stage-copy"),
        Stage::AddAtlas => t!("iso-stage-add-atlas"),
        Stage::NetworkDrivers => t!("iso-stage-network-drivers"),
        Stage::Master => t!("iso-stage-master"),
        Stage::Verify => t!("iso-stage-verify"),
        Stage::Cleanup => t!("iso-stage-cleanup"),
    }
}

/// How long a stage usually takes, against the others: copying Windows and
/// writing the ISO take most of a build.
fn stage_weight(stage: Stage) -> f32 {
    match stage {
        Stage::Inspect => 3.,
        Stage::Copy => 30.,
        Stage::AddAtlas => 5.,
        Stage::NetworkDrivers => 10.,
        Stage::Master => 30.,
        Stage::Verify => 17.,
        Stage::Cleanup => 5.,
    }
}

/// How far a build has come: the share of its stages, by weight, finished
/// before `reported`, and of `reported` itself the `fraction` its bytes say.
/// It only grows, as the worker reports stages in order.
fn build_progress(reported: Stage, network_drivers: bool, fraction: Option<f32>) -> f32 {
    let stages = Stage::build(network_drivers);
    let total: f32 = stages.iter().copied().map(stage_weight).sum();
    let done: f32 = stages.iter().copied().filter(|stage| *stage < reported).map(stage_weight).sum();
    let within = stages.contains(&reported).then(|| stage_weight(reported) * fraction.unwrap_or(0.));
    ((done + within.unwrap_or(0.)) / total).clamp(0., 1.)
}

/// A stage's accessible name: its title and where it stands. The list it's
/// in gives its position ("4 of 6").
fn stage_name(title: &str, state: StageState) -> String {
    let status = match state {
        StageState::Done => t!("stepper-status-completed"),
        StageState::Current => t!("iso-stage-status-current"),
        StageState::Failed => t!("iso-stage-status-failed"),
        StageState::NotStarted => t!("iso-stage-status-not-started"),
    };
    t!("iso-stage-a11y", title = title, status = status)
}

/// What to change about a local account name. An empty name only waits for
/// input, and the footer says what's needed.
fn account_error(name: &str) -> Option<String> {
    if name.is_empty() {
        return None;
    }
    iso::username_problem(name).map(|problem| match problem {
        UsernameProblem::Invalid => t!("iso-account-invalid"),
        UsernameProblem::TrailingDot => t!("iso-account-trailing-dot"),
        UsernameProblem::Reserved => t!("iso-account-reserved"),
    })
}

/// A file in `folder` named `stem` that overwrites nothing: `stem.iso`, then
/// `stem (2).iso` and so on.
fn free_name(folder: &Path, stem: &str, exists: impl Fn(&Path) -> bool) -> PathBuf {
    let candidate = |number: u32| {
        folder.join(if number == 1 { format!("{stem}.iso") } else { format!("{stem} ({number}).iso") })
    };
    (1..100).map(candidate).find(|path| !exists(path)).unwrap_or_else(|| candidate(1))
}

/// A new ISO in `folder` that overwrites nothing: Atlas-Windows.iso, then
/// Atlas-Windows (2).iso and so on.
fn free_output(folder: &Path, exists: impl Fn(&Path) -> bool) -> PathBuf {
    free_name(folder, OUTPUT_STEM, exists)
}

/// `path`, or, when a file already has its name, the first free name like it:
/// Mine.iso becomes Mine (2).iso, and Mine (2).iso becomes Mine (3).iso.
fn unused_path(path: &Path, exists: impl Fn(&Path) -> bool) -> PathBuf {
    if !exists(path) {
        return path.to_path_buf();
    }
    let folder = path.parent().unwrap_or(Path::new(""));
    let stem = path.file_stem().map(|stem| stem.to_string_lossy().into_owned()).unwrap_or_default();
    // "Name (2)" counts on from its number, not to "Name (2) (2)".
    let base = stem
        .strip_suffix(')')
        .and_then(|rest| rest.rsplit_once(" ("))
        .filter(|(_, number)| !number.is_empty() && number.bytes().all(|b| b.is_ascii_digit()))
        .map_or(stem.as_str(), |(base, _)| base);
    free_name(folder, base, exists)
}

/// The edition among `editions` that is this PC's, named as Windows images
/// name them, from the PC's EditionID. Home and the editions Atlas doesn't
/// support have none.
fn this_pc_edition(edition_id: &str, editions: &[String]) -> Option<String> {
    let name = match edition_id.to_ascii_lowercase().as_str() {
        "professional" => "Windows 11 Pro",
        "professionaln" => "Windows 11 Pro N",
        "professionaleducation" => "Windows 11 Pro Education",
        "professionaleducationn" => "Windows 11 Pro Education N",
        "professionalworkstation" => "Windows 11 Pro for Workstations",
        "professionalworkstationn" => "Windows 11 Pro N for Workstations",
        "education" => "Windows 11 Education",
        "educationn" => "Windows 11 Education N",
        "enterprise" => "Windows 11 Enterprise",
        "enterprisen" => "Windows 11 Enterprise N",
        _ => return None,
    };
    editions.iter().find(|edition| edition.eq_ignore_ascii_case(name)).cloned()
}

/// The name of the account Atlas runs as, when Windows would accept it for
/// the ISO's local account.
fn this_pc_account() -> Option<String> {
    std::env::var("USERNAME").ok().filter(|name| iso::valid_username(name))
}

/// Whether this process was started on ISO creation, as relaunching as
/// administrator starts it: it doesn't ask again by itself, so a relaunch
/// that comes back without the permission can't repeat.
fn launched_on_this_page() -> bool {
    let args: Vec<String> = std::env::args().collect();
    args.windows(2).any(|pair| pair[0] == "--page" && pair[1] == "iso")
}

fn architecture_text(architecture: Architecture) -> String {
    match architecture {
        Architecture::X64 => t!("iso-architecture-x64"),
        Architecture::Arm64 => t!("iso-architecture-arm64"),
    }
}

/// A source the person can fix themselves by using other Windows media, or a
/// copy of the ISO that Windows can mount.
fn other_media_fixes(reason: Option<FailureReason>) -> bool {
    matches!(
        reason,
        Some(
            FailureReason::EditionUnsupported
                | FailureReason::IsoCustomised
                | FailureReason::IsoMountFile
                | FailureReason::WindowsReleaseUnlisted
                | FailureReason::WindowsUnsupported
        )
    )
}

pub struct IsoPage {
    download: download::IsoDownload,
    /// The Windows ISO's Change menu is open.
    source_menu: bool,
    /// Where the Change link was last drawn, for the menu to open under.
    source_menu_anchor: Rc<Cell<Bounds<Pixels>>>,
    terms_folder: Option<PathBuf>,
    /// The edition's Change menu is open, under the link it was drawn at.
    edition_menu: bool,
    edition_menu_anchor: Rc<Cell<Bounds<Pixels>>>,
    edition: Option<String>,
    /// The user chose the edition, so the target PC's no longer sets it.
    edition_chosen: bool,
    accept_terms: bool,
    usb: Option<Entity<UsbPage>>,
    username: Entity<TextInput>,
    model: Entity<AppModel>,
    source: Option<PathBuf>,
    archive: Option<PathBuf>,
    output: Option<PathBuf>,
    /// The output is Atlas's suggestion beside the source, not the user's
    /// choice, so it follows the source.
    output_suggested: bool,
    package: Option<PathBuf>,
    /// The unpacked package's size, which the free space it needs counts.
    package_bytes: u64,
    setup_available: bool,
    manifest: Option<Rc<Manifest>>,
    options: Vec<String>,
    /// The optional extras are unfolded under the questions, as they start;
    /// Hide folds them.
    extras_shown: bool,
    image: Option<ImageInfo>,
    mode: Mode,
    drivers: Option<Drivers>,
    reinstall_this_pc: bool,
    /// The user chose which PC the ISO is for, so arriving from a message
    /// about reinstalling this PC doesn't change it.
    target_chosen: bool,
    /// The last build was asked for this PC's network drivers and found
    /// that Windows includes them, so it added none.
    network_inbox: bool,
    copy_network_drivers: bool,
    step: IsoStep,
    /// The furthest step reached since the files were last checked.
    furthest: IsoStep,
    /// The stage the worker reported last.
    stage: Stage,
    /// The furthest the build's bar has been, so it never goes back.
    peak: f32,
    /// Whether the build running, or last run, adds this PC's network drivers.
    network_build: bool,
    result: JobResult,
    /// The Atlas Manager version the package asked for, when the last job
    /// failed with [`FailureReason::ManagerOutdated`] and the package named one.
    manager_required: Option<String>,
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    /// The files the last check ran on, so a check that failed isn't
    /// repeated by itself until a file changes.
    checked_files: Option<(PathBuf, Option<PathBuf>)>,
    /// A build found the package changed since the check: the check runs
    /// again, then the build.
    rebuild: bool,
    /// The new ISO's volume and whether the build fits there.
    destination: Option<iso::Destination>,
    /// The volume is read again every few seconds while it lacks the space,
    /// so space freed elsewhere is noticed without asking.
    destination_watched: bool,
    /// The page visit on which Atlas last asked for administrator
    /// permission by itself, and on which it last fetched the package.
    elevation_asked: Option<u64>,
    package_requested: Option<u64>,
    /// Windows refused the last relaunch as administrator.
    elevation_declined: bool,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    /// The `ATLAS_ISO_PREVIEW` state (debug builds only). A preview page never
    /// reads or writes files and never starts a check or build.
    preview: Option<String>,
    /// A preview of the page as it is before Atlas has administrator permission.
    preview_unelevated: bool,
    /// Step, result and page visit as last drawn, and whether a build was
    /// showing, so each change is announced once.
    shown: Option<Shown>,
    diagnostics: Diagnostics,
}

/// What the page drew last, to tell what's new.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Shown {
    step: IsoStep,
    result: JobResult,
    visit: u64,
    building: bool,
    declined: bool,
}

impl IsoPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        let username = cx.new(|cx| {
            crate::ui::text_input::TextInput::new(
                cx,
                "iso-username-input",
                || t!("iso-username"),
                || t!("iso-username-placeholder"),
            )
        });
        cx.observe(&username, |_, _, cx| cx.notify()).detach();
        cx.observe(&model, |this, model, cx| {
            this.follow_model(&model, cx);
            cx.notify();
        })
        .detach();
        let page = Self {
            download: download::IsoDownload::new(),
            source_menu: false,
            source_menu_anchor: Rc::default(),
            terms_folder: None,
            edition_menu: false,
            edition_menu_anchor: Rc::default(),
            edition: None,
            edition_chosen: false,
            accept_terms: false,
            usb: None,
            username,
            model,
            source: None,
            archive: None,
            output: None,
            output_suggested: false,
            package: None,
            package_bytes: 0,
            setup_available: false,
            manifest: None,
            options: vec![],
            extras_shown: true,
            image: None,
            mode: Mode::Interactive,
            drivers: Default::default(),
            reinstall_this_pc: true,
            target_chosen: false,
            network_inbox: false,
            copy_network_drivers: true,
            step: IsoStep::Windows,
            furthest: IsoStep::Windows,
            stage: Stage::Inspect,
            peak: 0.,
            network_build: false,
            result: JobResult::None,
            manager_required: None,
            job: None,
            task: None,
            checked_files: None,
            rebuild: false,
            destination: None,
            destination_watched: false,
            elevation_asked: None,
            package_requested: None,
            elevation_declined: false,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            preview: None,
            preview_unelevated: false,
            shown: None,
            diagnostics: Diagnostics::new(cx),
        };
        #[cfg(debug_assertions)]
        let page = page.with_preview(cx);
        page
    }

    /// The page in the state `ATLAS_ISO_PREVIEW` names, with made-up files.
    #[cfg(debug_assertions)]
    fn with_preview(mut self, cx: &mut Context<Self>) -> Self {
        let Ok(state) = std::env::var("ATLAS_ISO_PREVIEW") else { return self };
        let state = state.as_str();
        self.preview = Some(state.to_owned());
        self.preview_unelevated = matches!(state, "not-elevated" | "elevation-declined");
        self.elevation_declined = state == "elevation-declined";
        let downloads = PathBuf::from(r"C:\Users\Atlas\Downloads");
        // No Windows ISO chosen yet: the download is on offer.
        if !matches!(state, "windows-empty" | "download-change" | "download-progress" | "download-failed") {
            self.source = Some(downloads.join("Win11_25H2_EnglishInternational_x64.iso"));
        }
        // Offline: the latest package couldn't be found, so one on this PC is offered.
        if state == "package-offline" {
            self.model.update(cx, |model, _| model.release = ReleaseCheck::Failed);
        } else if state == "package-windows-iso" {
            // A Windows ISO chosen as the Atlas package, as the bar above it says.
            self.archive = Some(downloads.join("Win11_25H2_EnglishInternational_x64.iso"));
        } else {
            self.archive = Some(downloads.join("Atlas.atlaspkg"));
        }
        self.output = Some(downloads.join("Atlas-Windows.iso"));
        let name = match state {
            "account-empty" => "",
            "account-invalid" => "Atlas/PC",
            _ => "Atlas",
        };
        self.username.update(cx, |input, cx| input.set_value(name, cx));
        // Every state past a successful check has the image's details.
        let before_check = matches!(
            state,
            "windows-empty"
                | "download-change"
                | "download-progress"
                | "download-failed"
                | "source-menu"
                | "package-offline"
                | "checking"
                | "not-elevated"
                | "elevation-declined"
                | "failed"
                | "release-unknown"
                | "release-unlisted"
                | "edition-unsupported"
                | "iso-customised"
                | "windows-unsupported"
                | "package-unsupported"
                | "package-windows-iso"
                | "manager-outdated"
        );
        if !before_check {
            self.image = Some(ImageInfo {
                edition_terms: vec!["0".repeat(64), "0".repeat(64)],
                editions: vec!["Windows 11 Pro".into(), "Windows 11 Education".into()],
                bytes: 7_100_000_000,
                architecture: Architecture::X64,
            });
            self.package_bytes = 400_000_000;
        }
        if state == "this-pc-arm64" {
            let image = self.image.as_mut().unwrap();
            image.architecture = Architecture::Arm64;
            self.source = Some(downloads.join("Win11_25H2_EnglishInternational_Arm64.iso"));
        }
        let mut manifest = crate::services::package::parse(include_str!("../../../package/atlas.json"))
            .ok()
            .filter(|_| state != "package-windows-iso");
        // A package too old to make an ISO, as the bar above it says.
        if state == "package-unsupported"
            && let Some(manifest) = &mut manifest
        {
            manifest.version = "0.5.0".into();
        }
        let manifest = manifest.map(Rc::new);
        self.options = manifest.as_deref().map(iso::default_options).unwrap_or_default();
        // A review that carries a choice that reduces protection, to show its caution.
        if state == "review-before" {
            for option in &mut self.options {
                if option == "defender-enable" {
                    *option = "defender-disable".into();
                }
            }
        }
        self.manifest = manifest;
        self.step = match state {
            "setup"
            | "setup-another-pc"
            | "account-empty"
            | "account-invalid"
            | "setup-now"
            | "setup-extras-folded"
            | "before-desktop"
            | "choices-unsupported" => IsoStep::Setup,
            "review"
            | "review-before"
            | "review-space"
            | "progress"
            | "progress-network"
            | "cancelling"
            | "build-failed"
            | "network-failed"
            | "cancelled"
            | "complete"
            | "complete-network-inbox" => IsoStep::Create,
            _ => IsoStep::Windows,
        };
        // The checked files can go on to the steps visited before.
        self.furthest = if state == "files-checked" { IsoStep::Create } else { self.step };
        self.mode = match state {
            "setup-now" | "setup-extras-folded" | "review-before" => Mode::Configured,
            "before-desktop" => Mode::BeforeDesktop,
            _ => Mode::Interactive,
        };
        self.extras_shown = state != "setup-extras-folded";
        self.setup_available = state != "choices-unsupported";
        self.reinstall_this_pc = !matches!(state, "setup-another-pc" | "this-pc-arm64");
        self.network_build = matches!(state, "progress-network" | "network-failed");
        self.network_inbox = state == "complete-network-inbox";
        if !self.reinstall_this_pc || self.image.is_none() {
            self.edition = None;
        } else if state != "setup" {
            self.edition = Some("Windows 11 Pro".into());
        }
        self.accept_terms = matches!(state, "review" | "review-before");
        self.result = match state {
            "complete" | "complete-network-inbox" => JobResult::Complete,
            "failed" | "build-failed" => JobResult::Failed(Some(if state == "failed" {
                FailureReason::Check
            } else {
                FailureReason::Build
            })),
            "network-failed" => JobResult::Failed(Some(FailureReason::Build)),
            "release-unknown" => JobResult::Failed(Some(FailureReason::WindowsReleaseUnknown)),
            "release-unlisted" => JobResult::Failed(Some(FailureReason::WindowsReleaseUnlisted)),
            "edition-unsupported" => JobResult::Failed(Some(FailureReason::EditionUnsupported)),
            "iso-customised" => JobResult::Failed(Some(FailureReason::IsoCustomised)),
            "windows-unsupported" => JobResult::Failed(Some(FailureReason::WindowsUnsupported)),
            "package-unsupported" => JobResult::Failed(Some(FailureReason::PackageUnsupported)),
            "package-windows-iso" => JobResult::Failed(Some(FailureReason::PackageIsWindowsIso)),
            "manager-outdated" => JobResult::Failed(Some(FailureReason::ManagerOutdated)),
            "cancelled" => JobResult::Cancelled,
            _ => JobResult::None,
        };
        if state == "manager-outdated" {
            self.manager_required = Some(crate::services::manager_version::next_patch());
        }
        if matches!(self.result, JobResult::Failed(_)) {
            self.job = Some(settings::app_data_dir());
        }
        self.stage = match state {
            "checking" => Stage::Inspect,
            "progress-network" | "network-failed" => Stage::NetworkDrivers,
            _ => Stage::Master,
        };
        // Part of the way through writing the ISO, by its bytes.
        self.peak =
            build_progress(self.stage, self.network_build, (self.stage == Stage::Master).then_some(0.4));
        const GIB: u64 = 1 << 30;
        let needed = iso::space_needed(7_100_000_000, self.package_bytes);
        let free = if state == "review-space" { 21 * GIB } else { 118 * GIB };
        self.destination = Some(iso::Destination {
            drive: "C:".into(),
            free,
            needed,
            problem: (free < needed).then_some(iso::DestinationProblem::Space),
        });
        // A check or build in progress holds the window on this page, as a real one does.
        if matches!(state, "progress" | "progress-network" | "checking" | "cancelling") {
            self.model.update(cx, |model, _| {
                model.iso_busy = true;
                model.iso_cancel.store(state == "cancelling", Ordering::Relaxed);
            });
        }
        self.source_menu = state == "source-menu";
        self.download.preview(state);
        if state.starts_with("usb-") {
            let (model, output) = (self.model.clone(), self.output.clone());
            let panel = cx.new(|cx| UsbPage::new(model, output, vec![], Some(state), cx));
            cx.observe(&panel, |_, _, cx| cx.notify()).detach();
            self.usb = Some(panel);
        }
        self
    }

    /// Takes in what the model learned: the Atlas package Get ready
    /// downloaded or opened fills an empty package field (never one the user
    /// chose), and arriving to reinstall this PC preselects This PC once.
    fn follow_model(&mut self, model: &Entity<AppModel>, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        let (archive, for_this_pc, on_page, busy, bundled) = {
            let state = model.read(cx);
            (
                state.package.as_ref().and_then(|package| package.archive.clone()),
                state.iso_for_this_pc,
                state.page == Page::Iso,
                state.iso_busy,
                state.bundled(),
            )
        };
        if self.archive.is_none()
            && !bundled
            && let Some(archive) = archive
        {
            self.archive = Some(archive);
        }
        if for_this_pc && on_page {
            if !busy && !self.target_chosen && self.suits_this_pc() {
                self.set_target(true, false, cx);
            }
            model.update(cx, |m, _| m.iso_for_this_pc = false);
        }
        if on_page {
            self.settle(cx);
        }
    }

    /// What the page does by itself while it shows: it asks for
    /// administrator permission on arrival, fetches the latest Atlas package
    /// and Microsoft's Windows languages, and checks the files once it has
    /// both a Windows ISO and a package.
    fn settle(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        let (on_page, elevated, visit, bundled, fetch) = {
            let state = self.model.read(cx);
            let fetch = !state.latest_predates_app()
                && !state.acquisition.is_busy()
                && !matches!(state.acquisition, Acquisition::Failed(_));
            (state.page == Page::Iso, state.elevated, state.page_visit, state.bundled(), fetch)
        };
        if !on_page {
            return;
        }
        if !elevated && self.elevation_asked != Some(visit) && !launched_on_this_page() {
            self.elevation_asked = Some(visit);
            self.relaunch_elevated(cx);
        }
        if self.step == IsoStep::Windows && self.source.is_none() {
            self.prefetch_languages(cx);
        }
        if !elevated {
            return;
        }
        if self.archive.is_none() && !bundled && fetch && self.package_requested != Some(visit) {
            self.package_requested = Some(visit);
            self.model.update(cx, |m, cx| m.download_latest(cx));
        }
        self.check_when_ready(cx);
    }

    /// Checks the files once a Windows ISO and a package are both known, on
    /// the Windows step. A check that failed waits for a file to change, or
    /// for Try again.
    fn check_when_ready(&mut self, cx: &mut Context<Self>) {
        if self.image.is_some() || self.step != IsoStep::Windows || self.result != JobResult::None {
            return;
        }
        let state = self.model.read(cx);
        if state.iso_busy || state.locked() || state.recovering || !state.elevated || self.download.busy() {
            return;
        }
        let Some(source) = self.source.clone() else { return };
        if self.archive.is_none() && !state.bundled() {
            return;
        }
        let files = (source, self.archive.clone());
        if self.checked_files.as_ref() == Some(&files) {
            return;
        }
        self.checked_files = Some(files);
        self.start(true, cx);
    }

    /// Whether the checked image, if any, can be reinstalled on this PC.
    fn suits_this_pc(&self) -> bool {
        self.image.as_ref().is_none_or(|image| image.architecture == iso::host_architecture())
    }

    /// Sets which PC the ISO is for, and with it the defaults that follow
    /// it: the Windows download's architecture, the edition and the account
    /// name, unless the user chose them.
    fn set_target(&mut self, this_pc: bool, chosen: bool, cx: &mut Context<Self>) {
        self.reinstall_this_pc = this_pc && self.suits_this_pc();
        self.target_chosen |= chosen;
        if self.reinstall_this_pc {
            self.set_download_arch(iso::host_architecture(), false, cx);
        }
        self.apply_target_defaults(cx);
        cx.notify();
    }

    /// The edition and account name the target suggests: this PC's edition
    /// and its user's name for This PC. Anything the user set stays.
    fn apply_target_defaults(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        if !self.edition_chosen
            && let Some(image) = &self.image
        {
            let edition = if self.reinstall_this_pc {
                this_pc_edition(&self.model.read(cx).system.edition_id, &image.editions)
            } else {
                None
            };
            if edition != self.edition {
                self.edition = edition;
                self.accept_terms = false;
            }
        }
        if self.reinstall_this_pc
            && self.username.read(cx).value().is_empty()
            && let Some(name) = this_pc_account()
        {
            self.username.update(cx, |input, cx| input.set_value(name, cx));
        }
    }

    /// Goes back in an open USB panel the way its Back button does: from
    /// Review to the drive list, otherwise out of the panel. Returns false
    /// when no panel is showing or a write is running, so the caller can fall
    /// back to leaving the page.
    pub fn usb_back(&mut self, cx: &mut Context<Self>) -> bool {
        let Some(panel) = &self.usb else { return false };
        if panel.read(cx).closed || self.model.read(cx).usb_busy {
            return false;
        }
        panel.update(cx, |usb, cx| usb.back(cx));
        cx.notify();
        true
    }

    /// Opens the USB panel for `source`. Its Windows builds are those of the
    /// Atlas package just added to the ISO, or of the app's own package for an
    /// existing ISO.
    fn open_usb(&mut self, source: Option<PathBuf>, cx: &mut Context<Self>) {
        let model = self.model.clone();
        let builds = match (&source, &self.manifest) {
            (Some(_), Some(manifest)) => manifest.supported_builds.clone(),
            _ => model.read(cx).manifest().supported_builds.clone(),
        };
        let panel = cx.new(|cx| UsbPage::new(model, source, builds, None, cx));
        cx.observe(&panel, |_, _, cx| cx.notify()).detach();
        self.usb = Some(panel);
        cx.notify();
    }

    fn pick(&mut self, field: Field, cx: &mut Context<Self>) {
        if self.preview.is_some() || self.model.read(cx).locked() {
            return;
        }
        // The dialog shows this on its Open button, so it names the action,
        // as the USB page and Get ready word their pickers of these files.
        let prompt = match field {
            Field::Source => t!("iso-use-local"),
            Field::Package => t!("file-dialog-open-package"),
        };
        let receiver = cx.prompt_for_paths(PathPromptOptions {
            files: true,
            directories: false,
            multiple: false,
            prompt: Some(prompt.into()),
        });
        cx.spawn(async move |this, cx| {
            if let Ok(Ok(Some(paths))) = receiver.await
                && let Some(path) = paths.into_iter().next()
            {
                this.update(cx, |this, cx| match field {
                    Field::Source => this.accept_source(path, cx),
                    Field::Package => {
                        this.archive = Some(path);
                        this.manifest = None;
                        this.invalidate(cx);
                        this.settle(cx);
                    }
                })
                .ok();
            }
        })
        .detach();
    }

    /// The Save dialog for the new ISO, from the Create step.
    fn pick_output(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() || self.model.read(cx).locked() {
            return;
        }
        let directory = self
            .output
            .as_ref()
            .or(self.source.as_ref())
            .and_then(|p| p.parent())
            .map(PathBuf::from)
            .unwrap_or_else(std::env::temp_dir);
        let name = self
            .output
            .as_ref()
            .and_then(|p| p.file_name())
            .map(|name| name.to_string_lossy().into_owned())
            .unwrap_or_else(|| format!("{OUTPUT_STEM}.iso"));
        let response = cx.prompt_for_new_path(&directory, Some(&name));
        cx.spawn(async move |this, cx| {
            if let Ok(Ok(Some(path))) = response.await {
                this.update(cx, |this, cx| {
                    this.output = Some(with_iso_extension(path));
                    this.output_suggested = false;
                    this.result = JobResult::None;
                    this.check_destination();
                    cx.notify();
                })
                .ok();
            }
        })
        .detach();
    }

    fn accept_source(&mut self, path: PathBuf, cx: &mut Context<Self>) {
        self.source = Some(path);
        self.source_menu = false;
        self.suggest_output();
        self.invalidate(cx);
        self.settle(cx);
    }

    /// Puts the new ISO beside the source, under a name no file has yet,
    /// until the user chooses where to save it.
    fn suggest_output(&mut self) {
        if (self.output.is_none() || self.output_suggested)
            && let Some(folder) = self.source.as_deref().and_then(Path::parent)
        {
            self.output = Some(free_output(folder, Path::exists));
            self.output_suggested = true;
        }
    }

    /// Starts the files over: a file chosen again, even the same one, is
    /// checked again.
    fn invalidate(&mut self, cx: &mut Context<Self>) {
        self.checked_files = None;
        self.edition = None;
        self.edition_chosen = false;
        self.edition_menu = false;
        self.accept_terms = false;
        self.image = None;
        self.result = JobResult::None;
        self.destination = None;
        self.rebuild = false;
        self.step = IsoStep::Windows;
        self.furthest = IsoStep::Windows;
        cx.notify();
    }

    fn go_to_step(&mut self, step: IsoStep, cx: &mut Context<Self>) {
        if step != self.step {
            // A result belongs to the step its job ran from: a check's to
            // Windows, a build's to Create.
            self.result = JobResult::None;
            self.source_menu = false;
        }
        self.step = step;
        self.furthest = self.furthest.max(step);
        if step == IsoStep::Create {
            self.check_destination();
        }
        self.scroll.set_offset(Point::default());
        cx.notify();
    }

    /// Reads the new ISO's volume again, for the Create step to show.
    fn check_destination(&mut self) {
        if self.preview.is_some() {
            return;
        }
        self.destination = match (&self.output, &self.image) {
            (Some(output), Some(image)) => {
                Some(iso::destination(output, iso::space_needed(image.bytes, self.package_bytes)))
            }
            _ => None,
        };
    }

    /// Whether the Create step shows a destination without the space the build needs.
    fn short_of_space(&self) -> bool {
        self.step == IsoStep::Create
            && self.destination.as_ref().is_some_and(|d| d.problem == Some(iso::DestinationProblem::Space))
    }

    /// Reads the volume again every few seconds while it's short of space,
    /// so Create ISO becomes available once space is freed, as Open Storage
    /// settings invites. It stops once the space is there or the step changes.
    fn watch_destination(&mut self, cx: &mut Context<Self>) {
        if self.destination_watched || self.preview.is_some() || !self.short_of_space() {
            return;
        }
        self.destination_watched = true;
        cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(SPACE_RECHECK).await;
                let watching = this.update(cx, |this, cx| {
                    if this.short_of_space() && !this.model.read(cx).iso_busy {
                        this.check_destination();
                        cx.notify();
                    }
                    this.destination_watched = this.short_of_space();
                    this.destination_watched
                });
                if !matches!(watching, Ok(true)) {
                    break;
                }
            }
        })
        .detach();
    }

    pub fn analytics_path(&self) -> &'static str {
        if self.usb.is_some() {
            return "iso/usb";
        }
        match self.step {
            IsoStep::Windows => "iso/windows",
            IsoStep::Setup => "iso/setup",
            IsoStep::Create => "iso/create",
        }
    }

    fn gates(&self, cx: &App) -> Gates {
        Gates { checked: self.image.is_some(), account: iso::valid_username(self.username.read(cx).value()) }
    }

    /// The package needs a newer Atlas Manager, as the last check found or
    /// as fetching the latest package did: the version it asks for, if it
    /// names one.
    fn manager_outdated(&self, cx: &App) -> Option<Option<String>> {
        if self.result == JobResult::Failed(Some(FailureReason::ManagerOutdated)) {
            return Some(self.manager_required.clone());
        }
        let state = self.model.read(cx);
        let own_package = self.archive.is_none()
            || state.package.as_ref().and_then(|package| package.archive.as_ref()) == self.archive.as_ref();
        match &state.acquisition {
            Acquisition::Failed(AcquireProblem::ManagerOutdated { required }) if own_package => {
                Some(required.clone())
            }
            _ => None,
        }
    }

    fn start(&mut self, inspect: bool, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        if self.download.busy() || self.model.read(cx).locked() || self.model.read(cx).recovering {
            return;
        }
        let bundled = self.model.read(cx).bundled();
        let Some(source) = self.source.clone() else { return };
        if self.output.is_none() {
            self.suggest_output();
        }
        let Some(mut output) = self.output.clone() else { return };
        let archive = match self.archive.clone() {
            Some(archive) => archive,
            // A tester build adds its bundled package, which the worker writes out.
            None if bundled => PathBuf::new(),
            None => return,
        };
        if !inspect {
            // A file that took the name since it was chosen moves the new ISO
            // to the next free name, and the volume is read again just before.
            output = unused_path(&output, Path::exists);
            self.output = Some(output.clone());
            self.check_destination();
            if self.destination.as_ref().is_some_and(|destination| destination.problem.is_some()) {
                cx.notify();
                return;
            }
        }
        let Ok(job) = iso::new_job() else {
            // Nothing ran, so there are no diagnostics to open.
            self.job = None;
            self.result = JobResult::Failed(None);
            cx.notify();
            return;
        };
        self.job = Some(job.clone());
        self.result = JobResult::None;
        self.source_menu = false;
        if inspect {
            // Checking again replaces the last result, so a failed check
            // cannot leave an earlier one to continue with.
            self.edition_menu = false;
            self.accept_terms = false;
            self.image = None;
        }
        self.stage = Stage::Inspect;
        self.peak = 0.;
        self.network_inbox = false;
        let (reinstall_this_pc, copy_network_drivers) =
            network_choices(inspect, self.reinstall_this_pc, self.copy_network_drivers);
        self.network_build = copy_network_drivers;
        let input = iso::CreateInput {
            inspect,
            bundled,
            archive,
            inspected_package: self.package.clone(),
            source,
            output,
            edition: self.edition.clone(),
            accepted_terms: self
                .image
                .as_ref()
                .filter(|_| self.accept_terms)
                .and_then(|img| img.terms(self.edition.as_deref()).map(str::to_owned)),
            mode: self.effective_mode(),
            options: self.options.clone(),
            drivers: self.drivers,
            username: if inspect { "Atlas".to_string() } else { self.username.read(cx).value().to_string() },
            reinstall_this_pc,
            copy_network_drivers,
            // Windows Update first, with the installed drivers to fall back on.
            update_network_drivers: copy_network_drivers,
        };
        self.model.update(cx, |m, cx| {
            if !inspect {
                crate::services::analytics::send(
                    m.settings.usage_analytics,
                    "ISO build started",
                    "iso/create",
                );
            }
            m.iso_busy = true;
            m.iso_cancel.store(false, Ordering::Relaxed);
            cx.notify();
        });
        let cancel = self.model.read(cx).iso_cancel.clone();
        self.task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded();
            let work = cx.background_executor().spawn(async move {
                iso::prune_jobs(&job);
                iso::prune_legacy_jobs(&settings::AppPaths::from_process().root);
                let result = iso::create(input, &job, cancel, |report| {
                    let _ = tx.unbounded_send(report);
                });
                // The package's size, for the free space the build will need.
                let package_bytes = result
                    .as_ref()
                    .ok()
                    .filter(|_| inspect)
                    .map(|created| iso::package_bytes(&created.package));
                (result, job.is_dir(), package_bytes)
            });
            while let Some(report) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.stage = report.stage;
                    let value = build_progress(report.stage, this.network_build, report.fraction);
                    this.peak = this.peak.max(value);
                    cx.notify();
                })
                .ok();
            }
            let (result, staged, package_bytes) = work.await;
            this.update(cx, |this, cx| {
                let cancelled = this.model.read(cx).iso_cancel.load(Ordering::Relaxed);
                this.model.update(cx, |m, cx| {
                    m.iso_busy = false;
                    cx.notify();
                });
                if !staged {
                    // The job could not be created, so there are no diagnostics to show.
                    this.job = None;
                }
                if let Some(bytes) = package_bytes {
                    this.package_bytes = bytes;
                }
                this.finish(inspect, cancelled, result, cx);
                // A changed package is checked again before the build runs again.
                if !inspect && !this.rebuild {
                    let event = match this.result {
                        JobResult::Complete => "ISO build completed",
                        JobResult::Cancelled => "ISO build cancelled",
                        _ => "ISO build failed",
                    };
                    crate::services::analytics::send(
                        this.model.read(cx).settings.usage_analytics,
                        event,
                        "iso/create",
                    );
                }
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    /// The mode the ISO is built with: one the package can't carry falls
    /// back to choices after sign-in, which every package supports.
    fn effective_mode(&self) -> Mode {
        if self.setup_available { self.mode } else { Mode::Interactive }
    }

    /// Takes in how a check or build ended. A check that passed stays on the
    /// Windows step, which then offers Continue, unless it was the check a
    /// changed package called for at Create, which builds again; anything
    /// else leaves its result on the step it ran from.
    fn finish(
        &mut self,
        inspect: bool,
        cancelled: bool,
        result: anyhow::Result<iso::Created>,
        cx: &mut Context<Self>,
    ) {
        match result {
            Ok(created) if inspect => {
                self.terms_folder = self.job.clone();
                let image_suits = created.image.as_ref().is_none_or(|image| {
                    image.architecture == iso::host_architecture() || self.preview.is_some()
                });
                self.image = created.image;
                // A package replaced just before Create keeps the choices made
                // with it while they still fit the new one.
                let same_package = self.package.as_ref() == Some(&created.package)
                    || (self.rebuild && iso::validate_options(&created.manifest, &self.options).is_ok());
                let kept = iso::options_after_inspection(&created.manifest, &self.options, same_package);
                let choices_kept = kept == self.options;
                self.options = kept;
                self.manifest = Some(Rc::new(created.manifest));
                self.setup_available = iso::supports_setup(&created.package);
                self.package = Some(created.package);
                // An ISO for another kind of processor is for another PC.
                if !image_suits {
                    self.reinstall_this_pc = false;
                }
                self.apply_target_defaults(cx);
                if std::mem::take(&mut self.rebuild) {
                    self.step = IsoStep::Create;
                    if choices_kept {
                        self.start(false, cx);
                    }
                }
            }
            Ok(created) => {
                // Windows includes this PC's network drivers: none were added,
                // and the result says so rather than claiming a copy.
                self.network_inbox = created.network_drivers_inbox;
                if created.network_drivers_inbox {
                    self.network_build = false;
                }
                self.result = JobResult::Complete;
            }
            Err(_) if cancelled => {
                self.rebuild = false;
                // A cancelled check leaves nothing to say; a build says the
                // original ISO is as it was.
                self.result = if inspect { JobResult::None } else { JobResult::Cancelled };
            }
            Err(error) => {
                // A package for a newer Atlas Manager says which version it needs.
                let outdated = error.downcast_ref::<package::ManagerOutdated>();
                self.manager_required = outdated.and_then(|outdated| outdated.required.clone());
                let reason = match outdated {
                    Some(_) => Some(FailureReason::ManagerOutdated),
                    None => error.downcast_ref::<iso::Failure>().map(|failure| failure.reason),
                };
                if reason == Some(FailureReason::PackageChanged) && !inspect && !self.rebuild {
                    // The package file was replaced since the check: check it
                    // again, then build with the same choices if they still fit.
                    self.rebuild = true;
                    self.image = None;
                    self.start(true, cx);
                    return;
                }
                self.rebuild = false;
                if inspect && self.step == IsoStep::Create {
                    // The check a changed package called for failed: its
                    // result belongs to the Windows step.
                    self.step = IsoStep::Windows;
                }
                self.result = JobResult::Failed(reason);
            }
        }
        self.scroll.set_offset(Point::default());
    }

    /// Checks the files again after a failed check, or builds again after a
    /// failed build.
    fn try_again(&mut self, cx: &mut Context<Self>) {
        let inspect = self.step == IsoStep::Windows;
        self.result = JobResult::None;
        if inspect {
            self.checked_files = None;
            self.check_when_ready(cx);
        } else {
            self.start(false, cx);
        }
        cx.notify();
    }

    fn relaunch_elevated(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        // The UAC prompt pumps a nested message loop inside ShellExecute;
        // keep it off the UI thread.
        cx.spawn(async move |this, cx| {
            let launched = cx.background_executor().spawn(async { system::relaunch_iso_elevated() }).await;
            this.update(cx, |this, cx| match launched {
                Ok(()) => cx.quit(),
                Err(error) => {
                    log::warn!("ISO elevation was not completed: {error:#}");
                    this.elevation_declined = true;
                    cx.notify();
                }
            })
            .ok();
        })
        .detach();
    }

    /// The steps, with each one the user can go to now as a button. The
    /// current step takes focus when the step changes, so it's announced.
    fn stepper(
        &self,
        gates: Gates,
        may_move: bool,
        focus: FocusHandle,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let entity = cx.entity();
        let mut stepper = Stepper::new("iso-stepper", t!("iso-title")).current_focus(focus, None).on_select(
            move |index, _, cx| entity.update(cx, |this, cx| this.go_to_step(IsoStep::ALL[index], cx)),
        );
        for step in IsoStep::ALL {
            stepper = stepper.step(
                step.title(),
                step_status(step, self.step, self.furthest, gates),
                may_move && gates.reachable(self.step, step, self.furthest),
            );
        }
        stepper.into_any_element()
    }

    /// The one bar at the top of the page, if any: the first that applies of
    /// a missing administrator permission, a package for a newer Atlas
    /// Manager, how the last check or build failed and a cancelled build.
    /// Each names the problem and holds the fix; `accent` says whether its
    /// fix is the page's next action.
    fn top_bar(
        &self,
        elevated: bool,
        focus: &FocusHandle,
        cx: &mut Context<Self>,
    ) -> Option<(AnyElement, bool)> {
        if !elevated {
            let message =
                if self.elevation_declined { t!("iso-elevation-declined") } else { t!("iso-admin-reason") };
            let bar = InfoBar::new(Severity::Warning, t!("iso-elevation-title"), message)
                .id("iso-elevation")
                .focus_handle(focus.clone())
                .action(
                    Button::new("iso-elevate", t!("common-restart-as-administrator"))
                        .accent()
                        .icon(Icon::Admin)
                        .on_click(cx.listener(|this, _, _, cx| this.relaunch_elevated(cx))),
                );
            return Some((bar.into_any_element(), true));
        }
        if let Some(required) = self.manager_outdated(cx) {
            let bar = InfoBar::new(
                Severity::Warning,
                t!("iso-manager-outdated-title"),
                describe::manager_outdated(required.as_deref()),
            )
            .id("iso-manager-outdated")
            .focus_handle(focus.clone())
            .action(manager_download_button("iso-manager-download").accent());
            return Some((bar.into_any_element(), true));
        }
        match self.result {
            JobResult::Failed(reason) => Some(self.failure_bar(reason, focus, cx)),
            JobResult::Cancelled => Some((
                InfoBar::new(Severity::Informational, t!("iso-cancelled"), t!("iso-cancelled-unchanged"))
                    .id("iso-cancelled")
                    .focus_handle(focus.clone())
                    .into_any_element(),
                false,
            )),
            _ => None,
        }
    }

    /// The bar a failed check or build leaves: what went wrong, the fix, and
    /// the help row when nothing the person can do is known to fix it.
    fn failure_bar(
        &self,
        reason: Option<FailureReason>,
        focus: &FocusHandle,
        cx: &mut Context<Self>,
    ) -> (AnyElement, bool) {
        let (title, message) = self.failure_text();
        let mut bar =
            InfoBar::new(Severity::Error, title, message).id("iso-error").focus_handle(focus.clone());
        let checking = self.step == IsoStep::Windows;
        let mut accent = false;
        if checking && other_media_fixes(reason) {
            accent = true;
            bar = bar.action(
                div()
                    .flex()
                    .flex_wrap()
                    .gap(px(8.))
                    .child(
                        Button::new("iso-fix-download", t!("iso-download-windows"))
                            .accent()
                            .icon(Icon::Download)
                            .on_click(cx.listener(|this, _, _, cx| this.download_windows_now(cx))),
                    )
                    .child(
                        Button::new("iso-fix-choose", t!("iso-use-local"))
                            .on_click(cx.listener(|this, _, _, cx| this.pick(Field::Source, cx))),
                    ),
            );
        } else if checking
            && matches!(reason, Some(FailureReason::PackageUnsupported | FailureReason::PackageIsWindowsIso))
        {
            accent = true;
            bar = bar.action(
                Button::new("iso-fix-package", t!("iso-fix-package"))
                    .accent()
                    .on_click(cx.listener(|this, _, _, cx| this.pick(Field::Package, cx))),
            );
        } else if checking {
            // Try again checks the same files; the footer's Continue waits.
            accent = true;
            bar = bar.action(
                Button::new("iso-check-again", t!("common-try-again"))
                    .accent()
                    .on_click(cx.listener(|this, _, _, cx| this.try_again(cx))),
            );
        } else if self.network_build && self.stage == Stage::NetworkDrivers {
            // Leaving them out is the way on; the footer's Try again repeats
            // the export that just failed.
            accent = true;
            bar = bar.action(Button::new("iso-network-skip", t!("iso-network-skip")).accent().on_click(
                cx.listener(|this, _, _, cx| {
                    this.copy_network_drivers = false;
                    this.try_again(cx);
                }),
            ));
        }
        if failure_needs_help(reason, checking, self.job.is_some()) {
            let log = self.job.clone().filter(|_| reason != Some(FailureReason::ManagerOutdated));
            bar = bar.content(self.diagnostics.content_with_log(&self.model, log, cx));
        }
        (bar.into_any_element(), accent)
    }

    /// The stage a build failed at, when the worker got that far. Atlas
    /// refuses a changed or unusable package before the worker starts.
    fn failed_stage(&self) -> Option<Stage> {
        match self.result {
            JobResult::Failed(reason)
                if self.step == IsoStep::Create
                    && self.job.is_some()
                    && !matches!(
                        reason,
                        Some(
                            FailureReason::PackageChanged
                                | FailureReason::PackageUnsupported
                                | FailureReason::PackageIsWindowsIso
                                | FailureReason::ManagerOutdated
                        )
                    ) =>
            {
                Some(self.stage)
            }
            _ => None,
        }
    }

    /// A build's stages as a checklist: done, current and not started, or the
    /// stage it failed at.
    fn stage_list(&self, failed: bool, cx: &App) -> Stateful<Div> {
        let theme = cx.theme();
        let stages = Stage::build(self.network_build);
        let total = stages.len();
        div()
            .id("iso-stages")
            .role(Role::List)
            .aria_label(t!("iso-progress-title"))
            .aria_size_of_set(total)
            .flex()
            .flex_col()
            .gap(px(8.))
            .children(stages.into_iter().enumerate().map(|(index, stage)| {
                let state = stage_state(stage, self.stage, failed);
                let title = stage_text(stage);
                let (glyph, colour): (AnyElement, Hsla) = match state {
                    StageState::Done => (icon(Icon::Completed).into_any_element(), theme.success),
                    StageState::Current => (ProgressRing::new().into_any_element(), theme.accent),
                    StageState::Failed => (icon(Icon::ErrorBadge).into_any_element(), theme.critical),
                    // An empty circle: the Completed glyph without its check.
                    StageState::NotStarted => (
                        div()
                            .size(px(14.))
                            .rounded_full()
                            .border_1()
                            .border_color(theme.control_strong_stroke)
                            .into_any_element(),
                        theme.text_secondary,
                    ),
                };
                let strong = matches!(state, StageState::Current | StageState::Failed);
                div()
                    .id(("iso-stage", index))
                    .role(Role::ListItem)
                    // No "Step N of M": that's the stepper's; the list gives "4 of 6".
                    .aria_label(stage_name(&title, state))
                    // AccessKit counts from 0 and takes the size from the list.
                    .aria_position_in_set(index)
                    .flex()
                    // The 16px glyphs start on the card's text edge, and the
                    // names line up with a radio button's label, as on the USB page.
                    .gap(px(16.))
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
                            .when(strong, |this| this.type_body_strong())
                            .text_color(if state == StageState::NotStarted {
                                theme.text_secondary
                            } else {
                                theme.text_primary
                            })
                            .child(CapCenteredText(title.into())),
                    )
            }))
    }

    /// Step 1: which PC the ISO is for, the Windows ISO and the Atlas package.
    fn windows_cards(
        &mut self,
        accent_free: bool,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Vec<AnyElement> {
        let target = self.target_card(cx);
        let source = self.source_card(accent_free, window, cx);
        let package = self.package_card(accent_free, cx);
        let usb = link_row()
            .child(
                Button::new("iso-existing-usb", t!("usb-existing"))
                    .hyperlink()
                    .compact()
                    .on_click(cx.listener(|this, _, _, cx| this.open_usb(None, cx))),
            )
            .into_any_element();
        vec![target, source, package, usb]
    }

    /// Which PC the ISO is for. An ISO for another kind of processor can only
    /// be for another PC, so This PC is unavailable then and says why, and
    /// Another PC stays chosen.
    fn target_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let entity = cx.entity();
        // The answer applies to the build, so it can change while the files are checked.
        let locked = self.model.read(cx).locked() && !self.model.read(cx).iso_busy;
        let mut this_pc =
            RadioItem::new("iso-this-pc", t!("iso-target-this"), self.focus.get("iso-this-pc", cx))
                .icon(Icon::PC);
        if let Some(image) = self.image.as_ref().filter(|_| !self.suits_this_pc()) {
            this_pc = this_pc
                .disabled(true)
                .description(t!("iso-target-arch", architecture = architecture_text(image.architecture)))
                .readable_description();
        }
        let items = [
            this_pc,
            RadioItem::new("iso-other-pc", t!("iso-target-another"), self.focus.get("iso-other-pc", cx))
                .icon(Icon::Devices),
        ];
        let body = card_body().child(card_title(cx, "iso-target", t!("iso-target-title"), 3)).child(
            RadioGroup::new("iso-target", t!("iso-target-title"))
                .items(items)
                .selected(Some(usize::from(!self.reinstall_this_pc)))
                .disabled(locked)
                .on_select(move |index, _, cx| {
                    entity.update(cx, |this, cx| this.set_target(index == 0, true, cx))
                }),
        );
        card(cx).child(body).into_any_element()
    }

    /// The Windows ISO: the download on offer, its progress, or the file
    /// chosen with its Change menu and how its check is going.
    fn source_card(&mut self, accent_free: bool, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let mut body = card_body().child(card_title(cx, "iso-source", t!("iso-source"), 3));
        let Some(path) = self.source.clone() else {
            body = body.child(self.windows_download(accent_free, cx));
            return card(cx).child(body).into_any_element();
        };
        let theme = cx.theme().clone();
        let (checking, locked) = {
            let state = self.model.read(cx);
            let checking = state.iso_busy && self.step == IsoStep::Windows;
            (checking, state.locked() || checking || self.download.busy())
        };
        let name = path.file_name().unwrap_or_default().to_string_lossy().into_owned();
        let anchor = self.source_menu_anchor.clone();
        let change_focus = self.focus.get("iso-change-source", cx);
        let open = self.source_menu;
        // Hidden while it can't work: during a download or the check, or while
        // another job holds the app.
        let change = (!locked).then(|| {
            div().relative().child(
                Button::new("iso-change-source", t!("common-change"))
                    .compact()
                    .hyperlink()
                    // Invokable rather than expandable: the menu it opens takes
                    // focus, which is what announces it.
                    .focus_handle(change_focus.clone())
                    .aria_label(t!("iso-pick-a11y", action = t!("common-change"), field = t!("iso-source")))
                    .on_click(cx.listener(|this, _, window, cx| {
                        this.source_menu = !this.source_menu;
                        if this.source_menu {
                            let first = this.focus.get("iso-menu-download", cx);
                            window.focus(&first, cx);
                        }
                        cx.notify();
                    })),
            )
        });
        body = body.child(
            div()
                .flex()
                .flex_wrap()
                .items_center()
                .gap_x(px(8.))
                .child(div().min_w_0().type_body().child(detail_text("iso-source-file", name)))
                .children(change.map(|change| change.child(menu::anchor(anchor)))),
        );
        if open && !locked {
            body = body.child(self.source_menu_flyout(change_focus, window, cx));
        }
        // How the check of the files stands, announced as it changes: the
        // image's architecture and size once it passed.
        let facts = self.image.as_ref().filter(|_| !checking).map(|image| {
            [architecture_text(image.architecture), describe::file_size(image.bytes)]
                .join(&t!("usb-detail-separator"))
        });
        let status = if checking {
            Some(StatusLight::new(LightState::Pending, t!("iso-checking")))
        } else {
            facts.as_ref().map(|facts| {
                StatusLight::new(LightState::Good, t!("package-status-ready"))
                    .check_mark()
                    .aria_label(t!("iso-checked-a11y", facts = facts.as_str()))
            })
        };
        if let Some(status) = status {
            body = body.child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap(px(8.))
                    .child(status.id("iso-check-status").live())
                    // The pill's name carries the facts, so they're read once.
                    .when_some(facts, |row, facts| {
                        row.child(div().type_caption().text_color(theme.text_secondary).child(facts))
                    }),
            );
        }
        card(cx).child(body).into_any_element()
    }

    /// The source's Change menu: download Windows from Microsoft instead,
    /// or choose another ISO file.
    fn source_menu_flyout(
        &mut self,
        change: FocusHandle,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let entity = cx.entity();
        let close: menu::Command = {
            let (entity, change) = (entity.clone(), change.clone());
            Rc::new(move |window, cx| {
                entity.update(cx, |this, cx| {
                    this.source_menu = false;
                    cx.notify();
                });
                window.focus(&change, cx);
            })
        };
        let download: menu::Command = {
            let entity = entity.clone();
            Rc::new(move |_, cx| entity.update(cx, |this, cx| this.download_windows_now(cx)))
        };
        let choose: menu::Command =
            Rc::new(move |_, cx| entity.update(cx, |this, cx| this.pick(Field::Source, cx)));
        let commands = vec![
            menu::MenuCommand {
                id: "iso-menu-download".into(),
                label: t!("iso-download-windows"),
                focus: self.focus.get("iso-menu-download", cx),
                checked: None,
                run: download,
            },
            menu::MenuCommand {
                id: "iso-menu-choose".into(),
                label: t!("iso-use-local"),
                focus: self.focus.get("iso-menu-choose", cx),
                checked: None,
                run: choose,
            },
        ];
        menu::flyout(t!("iso-source").into(), commands, self.source_menu_anchor.get(), close, window, cx)
    }

    /// The Atlas package: its version, the download of the latest under way,
    /// or why it couldn't be prepared, as Get ready shows it. `accent_free`
    /// says whether nothing above it leads.
    fn package_card(&mut self, accent_free: bool, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        let (bundled, latest_predates_app, locked, is_latest, version) = {
            let state = self.model.read(cx);
            let bundled = state.bundled();
            let latest_predates_app = state.latest_predates_app();
            let selected_package =
                state.package.as_ref().filter(|p| bundled || p.archive.as_ref() == self.archive.as_ref());
            let latest =
                state.release.release().filter(|r| !latest_predates_app && r.package_asset().is_some());
            let is_latest = !bundled
                && latest.is_some_and(|release| {
                    selected_package.is_some_and(|package| {
                        matches!(&package.origin, crate::model::Origin::Release(_))
                            && crate::services::releases::compare_versions(
                                &package.manifest.version,
                                release.version(),
                            )
                            .is_eq()
                    })
                });
            let version = selected_package
                .map(|package| package.manifest.version.clone())
                .or_else(|| self.manifest.as_ref().map(|manifest| manifest.version.clone()));
            let locked = state.locked() || state.iso_busy || self.download.busy();
            (bundled, latest_predates_app, locked, is_latest, version)
        };
        // The review fixture shows the verified-release state without making a network
        // request, except for the old package or the Windows ISO a refused package stands for.
        #[cfg(debug_assertions)]
        let is_latest = is_latest
            || self
                .preview
                .as_deref()
                .is_some_and(|state| !matches!(state, "package-unsupported" | "package-windows-iso"));
        let mut body = card_body().child(card_title(cx, "iso-package", t!("iso-review-package"), 3));
        let known = self.archive.is_some() || bundled;
        if known {
            let name = match (&version, &self.archive) {
                _ if bundled => t!("iso-package-bundled"),
                (Some(version), _) => format!("Atlas {version}"),
                (None, Some(path)) => path.file_name().unwrap_or_default().to_string_lossy().into_owned(),
                (None, None) => String::new(),
            };
            body = body.child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(8.))
                    .child(div().type_body().child(detail_text("iso-package-name", name)))
                    .when(is_latest, |row| {
                        row.child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("iso-package-latest-label", t!("iso-package-latest-label"))),
                        )
                    })
                    // Hidden while it can't work, as the Windows ISO's is.
                    .when(!bundled && !locked, |row| {
                        row.child(
                            Button::new("iso-change-package", t!("common-change"))
                                .compact()
                                .hyperlink()
                                .aria_label(t!(
                                    "iso-pick-a11y",
                                    action = t!("common-change"),
                                    field = t!("iso-review-package")
                                ))
                                .on_click(cx.listener(|this, _, _, cx| this.pick(Field::Package, cx))),
                        )
                    }),
            );
        } else {
            let (content, stalled) = if latest_predates_app {
                (
                    div()
                        .type_body()
                        .text_color(theme.text_secondary)
                        .child(detail_text("iso-package-release-old", t!("iso-package-release-old")))
                        .into_any_element(),
                    true,
                )
            } else {
                // Its retry is the page's next action once the Windows ISO is
                // known, when nothing above leads.
                self.package_download(accent_free && self.source.is_some(), cx)
            };
            body = body.child(content);
            // Without the latest package, one saved on this PC does as well.
            if stalled && !locked {
                body = body.child(
                    link_row().child(
                        Button::new("iso-open-package", t!("package-open-file"))
                            .compact()
                            .hyperlink()
                            .on_click(cx.listener(|this, _, _, cx| this.pick(Field::Package, cx))),
                    ),
                );
            }
        }
        card(cx).child(body).into_any_element()
    }

    /// Under an empty package field: the latest Atlas package downloading or
    /// unpacking, or why it couldn't be prepared with the way to try again.
    /// Atlas fetches it by itself once per visit; a download the user
    /// cancelled waits for Download. Also whether it stalled, so a package
    /// saved on this PC is offered instead. A failure reads in the error
    /// colour, and its retry is the accent when `accent` says it leads.
    fn package_download(&self, accent: bool, cx: &App) -> (AnyElement, bool) {
        let theme = cx.theme().clone();
        let state = self.model.read(cx);
        let release = state.release.release().cloned();
        let model = self.model.clone();
        // Download waits while a release check it asked for runs.
        let waiting = state.locked() || state.download_pending();
        let download_label = match &release {
            Some(r) => t!("package-download-version", version = r.version()),
            None => t!("package-download-newest"),
        };
        // The offline preview keeps its failed release check even when the
        // app's own check, which no preview stops, succeeds meanwhile.
        let release_failed = matches!(state.release, ReleaseCheck::Failed)
            || self.preview.as_deref() == Some("package-offline");
        let fetching = matches!(state.release, ReleaseCheck::Checking | ReleaseCheck::NotChecked)
            || state.download_pending()
            || (self.package_requested != Some(state.page_visit) && self.preview.is_none());
        let stalled = match &state.acquisition {
            Acquisition::Downloading { .. } | Acquisition::Extracting { .. } => false,
            // The bar's own download is the way on.
            Acquisition::Failed(AcquireProblem::ManagerOutdated { .. }) => false,
            Acquisition::Failed(_) => true,
            _ => !fetching || release_failed,
        };
        let content = match &state.acquisition {
            Acquisition::Downloading { received, total } => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(div().type_body().child(a11y_text(
                    "iso-package-downloading",
                    t!(
                        "package-downloading",
                        version = release.as_ref().map(|r| r.version()).unwrap_or(""),
                        received = fmt::megabytes_value(*received),
                        total = fmt::megabytes_value(*total)
                    ),
                )))
                .child(
                    ProgressBar::new(
                        "iso-package-progress",
                        t!("package-progress"),
                        Some(*received as f32 / (*total).max(1) as f32),
                    )
                    .live(),
                )
                .child({
                    let model = model.clone();
                    div().flex().child(
                        Button::new("iso-package-cancel", t!("package-cancel-download"))
                            .on_click(move |_, _, cx| model.update(cx, |m, cx| m.cancel_download(cx))),
                    )
                }),
            Acquisition::Extracting { .. } => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(div().type_body().child(a11y_text("iso-package-unpacking", t!("package-unpacking"))))
                .child(ProgressBar::new("iso-package-progress", t!("package-progress"), None).live()),
            // The bar says it needs a newer Atlas Manager and offers it.
            Acquisition::Failed(AcquireProblem::ManagerOutdated { .. }) => {
                div().type_body().child(detail_text(
                    "iso-package-name",
                    release.as_ref().map(|r| format!("Atlas {}", r.version())).unwrap_or_default(),
                ))
            }
            Acquisition::Failed(problem) => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(
                    div()
                        .id("iso-package-problem")
                        .role(Role::Status)
                        .aria_label(problem.text(false))
                        .aria_live(gpui::Live::Polite)
                        .type_body()
                        .text_color(theme.critical)
                        .child(problem.text(false)),
                )
                .child(
                    div().flex().child(
                        Button::new("iso-package-download", download_label)
                            .icon(Icon::Download)
                            .when(accent && !waiting, Button::accent)
                            .disabled(waiting)
                            .on_click(move |_, _, cx| model.update(cx, |m, cx| m.download_latest(cx))),
                    ),
                ),
            _ if release_failed && !state.download_pending() => {
                let message = t!("iso-package-release-failed");
                div()
                    .flex()
                    .flex_col()
                    .gap(px(8.))
                    .child(
                        div()
                            .id("iso-package-problem")
                            .role(Role::Status)
                            .aria_label(message.clone())
                            .aria_live(gpui::Live::Polite)
                            .type_body()
                            .text_color(theme.critical)
                            .child(message),
                    )
                    .child(
                        div().flex().child(
                            Button::new("iso-package-download", t!("common-try-again"))
                                .when(accent && !waiting, Button::accent)
                                .disabled(waiting)
                                .on_click(move |_, _, cx| model.update(cx, |m, cx| m.download_latest(cx))),
                        ),
                    )
            }
            // Fetching starts by itself once the release is known.
            _ if fetching => div().flex().items_center().gap(px(8.)).child(
                StatusLight::new(LightState::Pending, t!("iso-package-fetching")).id("iso-package-fetching"),
            ),
            // A download the user cancelled.
            _ => div().flex().child(
                Button::new("iso-package-download", download_label)
                    .icon(Icon::Download)
                    .when(accent && !waiting, Button::accent)
                    .disabled(waiting)
                    .on_click(move |_, _, cx| model.update(cx, |m, cx| m.download_latest(cx))),
            ),
        };
        (content.into_any_element(), stalled)
    }

    /// Why the step's primary button is unavailable, when nothing on the
    /// page says it already: the status lives in one place.
    fn hint(&self, elevated: bool, cx: &App) -> String {
        let state = self.model.read(cx);
        match self.step {
            // Another job, such as Windows preparation, holding the app; this
            // page's own check says so where it shows.
            _ if state.locked() && !state.iso_busy => t!("iso-locked"),
            // The bar says what's missing, or a row says what's happening.
            _ if !elevated || self.result != JobResult::None => String::new(),
            IsoStep::Windows if state.iso_busy || self.download.busy() => String::new(),
            IsoStep::Windows if self.source.is_none() => t!("iso-need-windows"),
            IsoStep::Windows if self.archive.is_none() && !state.bundled() => String::new(),
            IsoStep::Setup if self.username.read(cx).value().is_empty() => t!("iso-account-empty"),
            _ => String::new(),
        }
    }

    /// Back and the step's primary button, or the controls of a running or
    /// finished job.
    fn footer(&self, gates: Gates, elevated: bool, bar_leads: bool, cx: &mut Context<Self>) -> AnyElement {
        let (busy, cancelling, locked) = {
            let state = self.model.read(cx);
            (state.iso_busy, state.iso_busy && state.iso_cancel.load(Ordering::Relaxed), state.locked())
        };
        if busy && self.step == IsoStep::Create {
            // Cancelling keeps the button, unavailable; the heading says so,
            // as on the USB page.
            return CommandBar::new()
                .cancel(
                    "iso-cancel",
                    t!("iso-cancel"),
                    cancelling,
                    cx.listener(|this, _, _, cx| {
                        this.model.update(cx, |m, cx| {
                            m.iso_cancel.store(true, Ordering::Relaxed);
                            cx.notify();
                        });
                    }),
                )
                .into_any_element();
        }
        if self.result == JobResult::Complete {
            let done = Button::new("iso-done", t!("common-done")).on_click(cx.listener(|this, _, _, cx| {
                // Done leaves the page ready for another ISO: the file just
                // written cannot be the next output, so another name is suggested.
                this.output = None;
                this.suggest_output();
                this.checked_files = None;
                this.invalidate(cx);
                this.model.update(cx, |m, cx| m.navigate(Page::Home, cx));
            }));
            let usb = Button::new("iso-write-usb", t!("iso-create-usb"))
                .accent()
                .on_click(cx.listener(|this, _, _, cx| this.open_usb(this.output.clone(), cx)));
            return CommandBar::new().back(done).primary(usb).into_any_element();
        }
        let locked = locked || busy || self.download.busy();
        let back = Button::new("iso-back", t!("common-back"))
            .disabled(self.step.previous().is_none() || locked)
            .on_click(cx.listener(|this, _, _, cx| {
                if let Some(previous) = this.step.previous() {
                    this.go_to_step(previous, cx);
                }
            }));
        let hint = self.hint(elevated, cx);
        let mut bar = CommandBar::new().hint(hint.clone()).back(back);
        // A package for a newer Atlas Manager can't make an ISO here at all:
        // the bar's download is the only way on.
        if self.manager_outdated(cx).is_some() {
            return bar.into_any_element();
        }
        let primary =
            match self.step {
                IsoStep::Create => {
                    let blocked = self.destination.as_ref().is_some_and(|d| d.problem.is_some()) || !elevated;
                    let failed = matches!(self.result, JobResult::Failed(_));
                    let label = if failed { t!("common-try-again") } else { t!("iso-create") };
                    Button::new("iso-create", label)
                        .when(!blocked && !bar_leads, Button::accent)
                        .disabled(blocked || locked)
                        .on_click(cx.listener(move |this, _, _, cx| {
                            if failed { this.try_again(cx) } else { this.start(false, cx) }
                        }))
                }
                step => {
                    let enabled = gates.passes(step) && elevated && !locked;
                    Button::new("iso-next", t!("common-next"))
                        .when(enabled && !bar_leads, Button::accent)
                        .trailing_icon(Icon::ChevronRight)
                        .disabled(!enabled)
                        .when(!enabled && !hint.is_empty(), |button| button.aria_description(hint.clone()))
                        .on_click(cx.listener(|this, _, _, cx| {
                            if let Some(next) = this.step.next() {
                                this.go_to_step(next, cx);
                            }
                        }))
                }
            };
        bar = bar.primary(primary);
        bar.into_any_element()
    }
}

impl Render for IsoPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if let Some(usb) = &self.usb {
            if !usb.read(cx).closed {
                return div().size_full().child(usb.clone()).into_any_element();
            }
            self.usb = None;
            // The control that opened the panel is gone; announce this page again.
            self.shown = None;
        }
        let (busy, elevated, visit) = {
            let state = self.model.read(cx);
            let elevated = (state.elevated || self.preview.is_some()) && !self.preview_unelevated;
            (state.iso_busy, elevated, state.page_visit)
        };
        let complete = self.result == JobResult::Complete;
        // A build runs from Create and takes over the page; a check runs within the Windows step.
        let building = busy && self.step == IsoStep::Create;
        let step_focus = self.focus.get("iso-step-current", cx);
        let result_focus = self.focus.get("iso-result", cx);

        // A new step, or arriving on the page, puts focus on the current
        // step in the stepper, which names it. A result, the elevation
        // question's answer or a build that starts puts it on what says so.
        // A check that starts by itself moves nothing.
        let now = Shown {
            step: self.step,
            result: self.result,
            visit,
            building,
            declined: self.elevation_declined,
        };
        if self.shown != Some(now) {
            let before = self.shown.replace(now);
            let news = before.is_some_and(|before| {
                (before.result != now.result && now.result != JobResult::None)
                    || (now.building && !before.building)
                    || (now.declined && !before.declined)
            });
            let moved = before.is_none_or(|before| before.step != now.step || before.visit != now.visit);
            if news || (moved && (complete || building)) {
                window.focus(&result_focus, cx);
            } else if moved {
                window.focus(&step_focus, cx);
            }
        }
        let gates = self.gates(cx);
        self.watch_destination(cx);

        let mut body: Vec<AnyElement> = Vec::new();
        if !building && !complete {
            let may_move = elevated && !busy && !self.model.read(cx).locked() && !self.download.busy();
            body.push(self.stepper(gates, may_move, step_focus, cx));
        }
        let bar = if building || complete { None } else { self.top_bar(elevated, &result_focus, cx) };
        let bar_leads = bar.as_ref().is_some_and(|(_, accent)| *accent);
        if let Some((bar, _)) = bar {
            body.push(bar);
        }
        if building {
            body.push(self.progress_card(&result_focus, cx));
        } else if complete {
            body.push(self.complete_card(&result_focus, cx));
        } else {
            match self.step {
                IsoStep::Windows => body.extend(self.windows_cards(!bar_leads, window, cx)),
                IsoStep::Setup => body.extend(self.setup_cards(window, cx)),
                IsoStep::Create => body.extend(self.create_cards(cx)),
            }
        }
        let footer = self.footer(gates, elevated, bar_leads, cx);
        self.diagnostics.settle(&self.model, window, cx);
        page_frame(
            "iso-page",
            Some(PageTitle { text: t!("iso-title").into(), badge: None, back: None }),
            None,
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            body,
            Some(footer),
            cx,
        )
        .into_any_element()
    }
}

impl IsoPage {
    /// Title and message of the error bar: the problem, then what to do, as
    /// far as the worker said.
    fn failure_text(&self) -> (String, String) {
        let checking = self.step == IsoStep::Windows;
        let failure = match self.result {
            JobResult::Failed(reason) => reason,
            _ => None,
        };
        let generic_title = if checking { t!("iso-check-failed") } else { t!("iso-failed") };
        if self.job.is_none() && failure != Some(FailureReason::ManagerOutdated) {
            // Nothing ran: there are no diagnostics to point at.
            return (generic_title, t!("iso-unstaged"));
        }
        match failure {
            Some(FailureReason::WindowsReleaseUnknown) => {
                (t!("iso-release-unknown-title"), t!("iso-release-unconfirmed"))
            }
            Some(FailureReason::WindowsReleaseUnlisted) => (t!("iso-preview-title"), t!("iso-preview")),
            Some(FailureReason::EditionUnsupported) => {
                (t!("iso-edition-unsupported-title"), t!("iso-edition-unsupported"))
            }
            Some(FailureReason::IsoCustomised) => (t!("iso-customised-title"), t!("iso-customised")),
            Some(FailureReason::WindowsUnsupported) => {
                (t!("iso-windows-unsupported-title"), t!("iso-windows-unsupported"))
            }
            Some(FailureReason::PackageUnsupported) => {
                (t!("iso-package-old-title"), t!("iso-package-old", minimum = iso::MINIMUM_VERSION))
            }
            // Not a version to change: the file goes under Windows ISO instead.
            Some(FailureReason::PackageIsWindowsIso) => {
                (t!("iso-package-windows-iso-title"), t!("iso-package-windows-iso"))
            }
            Some(FailureReason::ManagerMissing) => {
                (t!("iso-manager-missing-title"), t!("iso-manager-missing"))
            }
            Some(FailureReason::DiskSpace) => (generic_title, t!("iso-failed-space")),
            Some(FailureReason::DestinationPath) => (generic_title, t!("iso-path-too-long")),
            Some(FailureReason::IsoMount) => (generic_title, t!("iso-mount-failed")),
            Some(FailureReason::IsoMountDrivers) => (generic_title, t!("iso-mount-drivers")),
            Some(FailureReason::IsoMountFile) => (generic_title, t!("iso-mount-file")),
            Some(FailureReason::IsoMountTimeout) => (generic_title, t!("iso-mount-timeout")),
            Some(FailureReason::Build) if self.network_build && self.stage == Stage::NetworkDrivers => {
                (generic_title, t!("iso-network-not-added"))
            }
            // Checked before Create, so only a change while it ran gets here,
            // and trying again checks them before it builds.
            Some(
                FailureReason::OutputExists
                | FailureReason::DestinationFilesystem
                | FailureReason::NetworkArchitecture
                | FailureReason::PackageChanged
                | FailureReason::ManagerOutdated
                | FailureReason::Check
                | FailureReason::Build,
            )
            | None => {
                (generic_title, if checking { t!("iso-check-failed-retry") } else { t!("iso-failed-retry") })
            }
        }
    }
}

/// Whether a failure gets the help row: only one that nothing on the page
/// fixes, not media to replace, a package to change, a connection to check or
/// drivers to turn back on.
fn failure_needs_help(reason: Option<FailureReason>, checking: bool, ran: bool) -> bool {
    !ran || match reason {
        Some(
            FailureReason::WindowsReleaseUnknown
            | FailureReason::PackageUnsupported
            | FailureReason::PackageIsWindowsIso
            | FailureReason::ManagerOutdated
            | FailureReason::DiskSpace
            | FailureReason::DestinationPath
            | FailureReason::IsoMountDrivers,
        ) => false,
        reason if checking && other_media_fixes(reason) => false,
        _ => true,
    }
}

/// A summary row's value, with a caption under it when there is one, such
/// as a file's folder or a drive's size.
pub(super) fn captioned(key: &str, value: String, caption: Option<String>, cx: &App) -> Div {
    div().flex().flex_col().gap(px(2.)).min_w_0().child(detail_text(key, value)).when_some(
        caption,
        |this, caption| {
            this.child(
                div()
                    .type_caption()
                    .text_color(cx.theme().text_secondary)
                    .child(detail_text(&format!("{key}-caption"), caption)),
            )
        },
    )
}

/// A file as a summary row shows it: its name, with its folder as a caption.
pub(super) fn file_value(key: &str, path: &Path, cx: &App) -> Div {
    let name = path
        .file_name()
        .map(|name| name.to_string_lossy().into_owned())
        .unwrap_or_else(|| path.display().to_string());
    let folder = path
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .map(|parent| parent.display().to_string());
    captioned(key, name, folder, cx)
}

/// The network choices a request carries: reinstall this PC, and include
/// its network drivers. A check carries none: they apply to the build.
fn network_choices(inspect: bool, reinstall: bool, copy: bool) -> (bool, bool) {
    let reinstall = !inspect && reinstall;
    (reinstall, reinstall && copy)
}

/// The output must end in `.iso`: the worker refuses anything else, so a
/// name typed without an extension gets one rather than a failure later.
fn with_iso_extension(path: PathBuf) -> PathBuf {
    if path.extension().is_some_and(|e| e.eq_ignore_ascii_case("iso")) {
        path
    } else {
        let mut name = path.into_os_string();
        name.push(".iso");
        PathBuf::from(name)
    }
}

#[cfg(test)]
mod tests;
