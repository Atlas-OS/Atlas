//! Installation media: an Atlas ISO built in four steps (files, Windows setup,
//! choices, review), which the USB panel can then write to a drive. It runs
//! apart from the install flow and its checks of this PC.

use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::atomic::Ordering;

use futures::StreamExt;
use gpui::{
    AnyElement, App, Context, Div, Entity, FocusHandle, Hsla, IntoElement, ParentElement, PathPromptOptions,
    Point, Render, Role, ScrollHandle, Stateful, Task, Window, div, prelude::*, px,
};

use super::usb::UsbPage;
use super::{
    CommandBar, Diagnostics, ListEntry, PageTitle, StepStatus, Stepper, card_body, card_header_with_icon,
    caution_caption, detail_row, detail_text, drivers_radio, focusable_heading, option_page_card, page_frame,
    plain_list, step_card_header,
};
use crate::i18n::{describe, fmt};
use crate::model::{Acquisition, AppModel, Page, ReleaseCheck, ScreenKind};
use crate::services::iso::{self, Architecture, FailureReason, ImageInfo, Mode, Stage, UsernameProblem};
use crate::services::playbook::{Manifest, PageKind};
use crate::services::preparation::Drivers;
use crate::services::{settings, system};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::text_input::TextInput;
use crate::ui::{
    Button, CapCenteredText, CheckBox, FocusHandles, Icon, InfoBar, LightState, ProgressBar, ProgressRing,
    RadioGroup, RadioItem, ScrollbarState, Severity, StatusLight, TextMark, Typography, a11y_text, card,
    icon,
};

/// Where Microsoft offers Windows 11 ISOs.
const WINDOWS_DOWNLOAD: &str = "https://www.microsoft.com/software-download/windows11";

/// The new ISO's name, unless the user chooses another.
const OUTPUT_STEM: &str = "Atlas-Windows";

/// The steps of making an ISO, in order.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
enum IsoStep {
    Files,
    /// The Windows the ISO installs: its account, drivers and target PC.
    Windows,
    /// How Atlas is set up from it, and the choices it carries.
    Choices,
    Review,
}

impl IsoStep {
    const ALL: [IsoStep; 4] = [IsoStep::Files, IsoStep::Windows, IsoStep::Choices, IsoStep::Review];

    fn index(self) -> usize {
        self as usize
    }

    fn title(self) -> String {
        match self {
            IsoStep::Files => t!("iso-review-files"),
            IsoStep::Windows => t!("iso-step-windows"),
            IsoStep::Choices => t!("step-options"),
            IsoStep::Review => t!("iso-step-review"),
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
    /// Files: they passed the check, and none was chosen again since.
    checked: bool,
    /// Windows setup: a local account name Windows accepts.
    account: bool,
    /// Your choices: the Atlas package supports the setup mode chosen.
    mode: bool,
}

impl Gates {
    fn passes(self, step: IsoStep) -> bool {
        match step {
            IsoStep::Files => self.checked,
            IsoStep::Windows => self.account,
            IsoStep::Choices => self.mode,
            IsoStep::Review => true,
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

/// A file the first step asks for.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Field {
    Source,
    Package,
    Output,
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
        Stage::Inspect => t!("iso-stage-inspect"),
        Stage::Copy => t!("iso-stage-copy"),
        Stage::AddAtlas => t!("iso-stage-add-atlas"),
        Stage::NetworkDrivers => t!("iso-stage-network-drivers"),
        Stage::Master => t!("iso-stage-master"),
        Stage::Verify => t!("iso-stage-verify"),
        Stage::Cleanup => t!("iso-stage-cleanup"),
    }
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

/// A new ISO in `folder` that overwrites nothing: Atlas-Windows.iso, then
/// Atlas-Windows (2).iso and so on.
fn free_output(folder: &Path, exists: impl Fn(&Path) -> bool) -> PathBuf {
    let candidate = |number: u32| {
        folder.join(if number == 1 {
            format!("{OUTPUT_STEM}.iso")
        } else {
            format!("{OUTPUT_STEM} ({number}).iso")
        })
    };
    (1..100).map(candidate).find(|path| !exists(path)).unwrap_or_else(|| candidate(1))
}

pub struct IsoPage {
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
    setup_available: bool,
    manifest: Option<Rc<Manifest>>,
    options: Vec<String>,
    image: Option<ImageInfo>,
    mode: Mode,
    drivers: Drivers,
    reinstall_this_pc: bool,
    /// The user chose which PC the ISO is for, so arriving from a message
    /// about reinstalling this PC doesn't change it.
    target_chosen: bool,
    /// The last build was asked for this PC's network drivers and found
    /// that Windows includes them, so it added none.
    network_inbox: bool,
    copy_network_drivers: bool,
    update_network_drivers: bool,
    step: IsoStep,
    /// The furthest step reached since the files were last checked.
    furthest: IsoStep,
    /// The stage the worker reported last.
    stage: Stage,
    /// Whether the build running, or last run, adds this PC's network drivers.
    network_build: bool,
    result: JobResult,
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    /// The `ATLAS_ISO_PREVIEW` state (debug builds only). A preview page never
    /// reads or writes files and never starts a build.
    preview: Option<String>,
    /// A preview of the page as it is before Atlas has administrator permission.
    preview_unelevated: bool,
    /// Step, busy and result as last drawn, and the model's page visit, so
    /// each change and each arrival is announced.
    shown: Option<(IsoStep, bool, JobResult, u64)>,
    diagnostics: Diagnostics,
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
            usb: None,
            username,
            model,
            source: None,
            archive: None,
            output: None,
            output_suggested: false,
            package: None,
            setup_available: false,
            manifest: None,
            options: vec![],
            image: None,
            mode: Mode::Interactive,
            drivers: Default::default(),
            reinstall_this_pc: false,
            target_chosen: false,
            network_inbox: false,
            copy_network_drivers: true,
            update_network_drivers: false,
            step: IsoStep::Files,
            furthest: IsoStep::Files,
            stage: Stage::Inspect,
            network_build: false,
            result: JobResult::None,
            job: None,
            task: None,
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
        self.preview_unelevated = state == "not-elevated";
        self.source = Some(PathBuf::from(r"C:\Downloads\Windows11_25H2_English_x64.iso"));
        // A first-time user who never handled the Atlas package: the field is empty.
        if state != "files-empty" {
            self.archive = Some(PathBuf::from(r"C:\Downloads\Atlas.apbx"));
        }
        self.output = Some(PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso"));
        let name = match state {
            "account-empty" => "",
            "account-invalid" => "Atlas/PC",
            _ => "Atlas",
        };
        self.username.update(cx, |input, cx| input.set_value(name, cx));
        // Every state past a successful check has the image's details.
        if !matches!(
            state,
            "files"
                | "files-empty"
                | "failed"
                | "release-unknown"
                | "package-unsupported"
                | "checking"
                | "not-elevated"
                | "package-changed"
        ) {
            self.image = Some(ImageInfo {
                editions: vec!["Windows 11 Pro".into()],
                bytes: 6_500_000_000,
                architecture: Architecture::X64,
            });
        }
        let manifest = crate::services::playbook::parse(include_str!("../../../playbook/playbook.conf"))
            .ok()
            .map(Rc::new);
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
            "windows" | "network-drivers" | "account-empty" | "account-invalid" => IsoStep::Windows,
            "choices" | "choices-unsupported" | "before" | "before-desktop" => IsoStep::Choices,
            "review" | "review-before" | "progress" | "progress-network" | "build-failed"
            | "package-changed" | "cancelled" | "complete" => IsoStep::Review,
            _ => IsoStep::Files,
        };
        // The checked files can go on to the steps visited before.
        self.furthest = if state == "files-checked" { IsoStep::Review } else { self.step };
        self.mode = match state {
            "before" | "review-before" | "choices-unsupported" => Mode::Configured,
            "before-desktop" => Mode::BeforeDesktop,
            _ => Mode::Interactive,
        };
        self.setup_available = matches!(state, "before" | "before-desktop" | "review-before");
        self.reinstall_this_pc = matches!(state, "network-drivers" | "progress-network");
        self.update_network_drivers = state == "network-drivers";
        self.network_build = state == "progress-network";
        self.result = match state {
            "complete" => JobResult::Complete,
            "failed" => JobResult::Failed(None),
            "build-failed" => JobResult::Failed(Some(FailureReason::Build)),
            "release-unknown" => JobResult::Failed(Some(FailureReason::WindowsReleaseUnknown)),
            "package-unsupported" => JobResult::Failed(Some(FailureReason::PackageUnsupported)),
            "package-changed" => JobResult::Failed(Some(FailureReason::PackageChanged)),
            "cancelled" => JobResult::Cancelled,
            _ => JobResult::None,
        };
        if matches!(self.result, JobResult::Failed(_) | JobResult::Cancelled) {
            self.job = Some(settings::app_data_dir());
        }
        self.stage = match state {
            "checking" => Stage::Inspect,
            "progress-network" => Stage::NetworkDrivers,
            _ => Stage::Master,
        };
        // A check or build in progress holds the window on this page, as a real one does.
        if matches!(state, "progress" | "progress-network" | "checking") {
            self.model.update(cx, |model, _| model.iso_busy = true);
        }
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
                state.playbook.as_ref().and_then(|package| package.archive.clone()),
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
            // An image already checked must suit this PC for it to be the target.
            let suits =
                self.image.as_ref().is_none_or(|image| image.architecture == iso::host_architecture());
            if !busy && !self.target_chosen && suits {
                self.reinstall_this_pc = true;
            }
            model.update(cx, |m, _| m.iso_for_this_pc = false);
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
        if field == Field::Output {
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
                        this.invalidate(cx);
                    })
                    .ok();
                }
            })
            .detach();
            return;
        }
        let prompt = match field {
            Field::Source => t!("iso-source"),
            _ => t!("iso-package", minimum = iso::MINIMUM_VERSION),
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
                this.update(cx, |this, cx| {
                    if field == Field::Source {
                        this.source = Some(path);
                        this.suggest_output();
                    } else {
                        this.archive = Some(path);
                    }
                    this.invalidate(cx);
                })
                .ok();
            }
        })
        .detach();
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

    fn invalidate(&mut self, cx: &mut Context<Self>) {
        self.image = None;
        self.result = JobResult::None;
        self.step = IsoStep::Files;
        self.furthest = IsoStep::Files;
        cx.notify();
    }

    fn go_to_step(&mut self, step: IsoStep, cx: &mut Context<Self>) {
        if step != self.step {
            // A result belongs to the step its job ran from: a check's to
            // Files, a build's to Review.
            self.result = JobResult::None;
        }
        self.step = step;
        self.furthest = self.furthest.max(step);
        self.scroll.set_offset(Point::default());
        cx.notify();
    }

    fn gates(&self, cx: &App) -> Gates {
        Gates {
            checked: self.image.is_some(),
            account: iso::valid_username(self.username.read(cx).value()),
            mode: self.mode == Mode::Interactive || self.setup_available,
        }
    }

    fn start(&mut self, inspect: bool, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        if self.model.read(cx).locked() || self.model.read(cx).recovering {
            return;
        }
        let bundled = self.model.read(cx).bundled();
        let (Some(source), Some(output)) = (self.source.clone(), self.output.clone()) else { return };
        let archive = match self.archive.clone() {
            Some(archive) => archive,
            // A tester build adds its bundled package, which the worker writes out.
            None if bundled => PathBuf::new(),
            None => return,
        };
        let Ok(job) = iso::new_job() else {
            // Nothing ran, so there are no diagnostics to open.
            self.job = None;
            self.result = JobResult::Failed(None);
            cx.notify();
            return;
        };
        self.job = Some(job.clone());
        self.result = JobResult::None;
        if inspect {
            // Checking again replaces the last result, so a failed check
            // cannot leave an earlier one to continue with.
            self.image = None;
        }
        self.stage = Stage::Inspect;
        self.network_inbox = false;
        let (reinstall_this_pc, copy_network_drivers, update_network_drivers) = network_choices(
            inspect,
            self.reinstall_this_pc,
            self.copy_network_drivers,
            self.update_network_drivers,
        );
        self.network_build = copy_network_drivers;
        let input = iso::CreateInput {
            inspect,
            bundled,
            archive,
            inspected_package: self.package.clone(),
            source,
            output,
            mode: self.mode,
            options: self.options.clone(),
            drivers: self.drivers,
            username: if inspect { "Atlas".to_string() } else { self.username.read(cx).value().to_string() },
            reinstall_this_pc,
            copy_network_drivers,
            update_network_drivers,
        };
        self.model.update(cx, |m, cx| {
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
                let result = iso::create(input, &job, cancel, |stage| {
                    let _ = tx.unbounded_send(stage);
                });
                (result, job.is_dir())
            });
            while let Some(stage) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.stage = stage;
                    cx.notify();
                })
                .ok();
            }
            let (result, staged) = work.await;
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
                this.finish(inspect, cancelled, result);
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    /// Takes in how a check or build ended: a check that passed moves on to
    /// Windows setup, and anything else leaves its result on the step it ran from.
    fn finish(&mut self, inspect: bool, cancelled: bool, result: anyhow::Result<iso::Created>) {
        match result {
            Ok(created) if inspect => {
                self.image = created.image;
                let same_package = self.package.as_ref() == Some(&created.package);
                self.options = iso::options_after_inspection(&created.manifest, &self.options, same_package);
                self.manifest = Some(Rc::new(created.manifest));
                self.setup_available = iso::supports_setup(&created.package);
                self.package = Some(created.package);
                self.step = IsoStep::Windows;
                self.furthest = self.furthest.max(IsoStep::Windows);
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
            Err(_) if cancelled => self.result = JobResult::Cancelled,
            Err(error) => {
                let reason = error.downcast_ref::<iso::Failure>().map(|failure| failure.reason);
                if reason == Some(FailureReason::PackageChanged) {
                    // The check was of another package, so the files need
                    // checking again: Files offers Check files, not Continue.
                    self.image = None;
                }
                self.result = JobResult::Failed(reason);
            }
        }
        self.scroll.set_offset(Point::default());
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
                    this.result = JobResult::Failed(None);
                    cx.notify();
                }
            })
            .ok();
        })
        .detach();
    }

    /// The steps, with each one the user can go to now as a button.
    fn stepper(&self, gates: Gates, may_move: bool, cx: &mut Context<Self>) -> AnyElement {
        let entity = cx.entity();
        let mut stepper = Stepper::new("iso-stepper", t!("iso-title")).on_select(move |index, _, cx| {
            entity.update(cx, |this, cx| this.go_to_step(IsoStep::ALL[index], cx))
        });
        for step in IsoStep::ALL {
            stepper = stepper.step(
                step.title(),
                step_status(step, self.step, self.furthest, gates),
                may_move && gates.reachable(self.step, step, self.furthest),
            );
        }
        stepper.into_any_element()
    }

    /// The bar that asks for administrator permission, with the way to give it.
    fn elevation_bar(&self, declined: bool, focus: &FocusHandle, cx: &mut Context<Self>) -> AnyElement {
        let (severity, message) = if declined {
            (Severity::Error, t!("elevation-declined"))
        } else {
            (Severity::Warning, t!("iso-admin-description"))
        };
        InfoBar::new(severity, t!("iso-elevation-title"), message)
            .id("iso-elevation")
            .focus_handle(focus.clone())
            .action(
                Button::new("iso-elevate", t!("common-restart-as-administrator"))
                    .accent()
                    .icon(Icon::Admin)
                    .on_click(cx.listener(|this, _, _, cx| this.relaunch_elevated(cx))),
            )
            .into_any_element()
    }

    /// The bar a failed check or build leaves, with its log folder.
    fn error_bar(&self, focus: &FocusHandle) -> AnyElement {
        let (title, message) = self.failure_text();
        let mut bar =
            InfoBar::new(Severity::Error, title, message).id("iso-error").focus_handle(focus.clone());
        if let Some(job) = self.job.clone() {
            bar = bar.action(
                Button::new("iso-error-log", t!("iso-diagnostics"))
                    .icon(Icon::Folder)
                    .on_click(move |_, _, cx| cx.reveal_path(&job)),
            );
        }
        bar.into_any_element()
    }

    /// The bar a cancelled check or build leaves. Its message points at the
    /// log folder, so it is left out when there is none.
    fn cancelled_bar(&self, focus: &FocusHandle) -> AnyElement {
        let message = if self.job.is_some() { t!("iso-cancelled-description") } else { String::new() };
        let mut bar = InfoBar::new(Severity::Informational, t!("iso-cancelled"), message)
            .id("iso-cancelled")
            .focus_handle(focus.clone());
        if let Some(job) = self.job.clone() {
            bar = bar.action(
                Button::new("iso-cancelled-log", t!("iso-diagnostics"))
                    .icon(Icon::Folder)
                    .on_click(move |_, _, cx| cx.reveal_path(&job)),
            );
        }
        bar.into_any_element()
    }

    /// The stage a build failed at, when the worker got that far. Atlas
    /// refuses a changed or unusable package before the worker starts.
    fn failed_stage(&self) -> Option<Stage> {
        match self.result {
            JobResult::Failed(reason)
                if self.step == IsoStep::Review
                    && self.job.is_some()
                    && !matches!(
                        reason,
                        Some(FailureReason::PackageChanged | FailureReason::PackageUnsupported)
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
                    .gap(px(12.))
                    .child(
                        TextMark::new(
                            div()
                                .flex_shrink_0()
                                .size(px(20.))
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

    /// Step 1: the Windows ISO, the Atlas package and where to save the new ISO.
    fn files(&self, checked: bool, cx: &mut Context<Self>) -> AnyElement {
        let mut content = card_body().gap(px(14.));
        let bundled = self.model.read(cx).bundled();
        let fields = [
            (Field::Source, t!("iso-source"), &self.source),
            (Field::Package, t!("iso-package", minimum = iso::MINIMUM_VERSION), &self.archive),
            (Field::Output, t!("iso-output"), &self.output),
        ];
        for (index, (field, label, path)) in fields.into_iter().enumerate() {
            let heading =
                div().type_body_strong().child(a11y_text(("iso-field-label", index), label.clone()));
            if field == Field::Package && bundled {
                content = content.child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(6.))
                        .child(heading)
                        .child(detail_text("iso-path-1", t!("iso-package-bundled"))),
                );
                continue;
            }
            let action = if field == Field::Output { t!("iso-save-as") } else { t!("iso-browse") };
            content = content.child(
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .child(heading)
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(12.))
                            .when(field == Field::Source && path.is_some(), |this| {
                                this.child(TextMark::new(icon(Icon::Disc), false).natural_text())
                            })
                            .child(
                                div().flex_1().min_w_0().child(detail_text(
                                    &format!("iso-path-{index}"),
                                    path.as_ref()
                                        .map(|p| p.display().to_string())
                                        .unwrap_or_else(|| t!("iso-no-file")),
                                )),
                            )
                            .child(
                                // Named with its field: three pickers would otherwise
                                // all be "Browse" or "Save as".
                                Button::new(("iso-pick", index), action.clone())
                                    .aria_label(t!(
                                        "iso-pick-a11y",
                                        action = action.as_str(),
                                        field = label.as_str()
                                    ))
                                    .icon(Icon::Folder)
                                    .on_click(cx.listener(move |this, _, _, cx| this.pick(field, cx))),
                            ),
                    )
                    // Where to get the ISO the field asks for.
                    .when(field == Field::Source, |this| {
                        this.child(
                            div().flex().child(
                                Button::new("iso-source-download", t!("iso-source-download"))
                                    .hyperlink()
                                    .compact()
                                    .trailing_icon(Icon::OpenInNewWindow)
                                    .opens(WINDOWS_DOWNLOAD),
                            ),
                        )
                    })
                    // A first-time user never handled the file: Atlas downloads it here.
                    .when(field == Field::Package && path.is_none(), |this| {
                        this.children(self.package_download(cx))
                    }),
            );
        }
        // Checked files leave Continue as the only way on; this says why.
        if checked {
            content =
                content.child(div().flex().pt(px(12.)).border_t_1().border_color(cx.theme().divider).child(
                    StatusLight::new(LightState::Good, t!("package-status-ready")).id("iso-files-ready"),
                ));
        }
        card(cx).child(content).into_any_element()
    }

    /// Under an empty package field: the latest Atlas package to download,
    /// its progress, or why it couldn't be prepared, as Get ready offers it.
    fn package_download(&self, cx: &mut Context<Self>) -> Option<AnyElement> {
        let theme = cx.theme().clone();
        let state = self.model.read(cx);
        let release = state.release.release().cloned();
        let model = self.model.clone();
        let content = match &state.acquisition {
            Acquisition::Downloading { received, total } => div()
                .flex()
                .flex_col()
                .gap(px(6.))
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
                .child(
                    div().flex().child(
                        Button::new("iso-package-cancel", t!("package-cancel-download"))
                            .on_click(move |_, _, cx| model.update(cx, |m, cx| m.cancel_download(cx))),
                    ),
                ),
            Acquisition::Extracting { .. } => div()
                .flex()
                .flex_col()
                .gap(px(6.))
                .child(div().type_body().child(a11y_text("iso-package-unpacking", t!("package-unpacking"))))
                .child(ProgressBar::new("iso-package-progress", t!("package-progress"), None).live()),
            _ if state.latest_predates_app() || !state.offers_download() => return None,
            acquisition => {
                let checking = matches!(state.release, ReleaseCheck::Checking) || state.download_pending();
                let label = match &release {
                    Some(r) => t!("package-download-version", version = r.version()),
                    None => t!("package-download-newest"),
                };
                // A download that failed, or a release check that did: as
                // Get ready says it, so Download never fails without a word.
                let problem = match acquisition {
                    Acquisition::Failed(problem) => Some((problem.text(false), theme.critical)),
                    _ if !checking && matches!(state.release, ReleaseCheck::Failed) => {
                        Some((t!("package-release-failed"), theme.text_secondary))
                    }
                    _ => None,
                };
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .when_some(problem, |this, (problem, colour)| {
                        // Announced as it appears: Download has just gone back to idle.
                        this.child(
                            div()
                                .id("iso-package-problem")
                                .role(Role::Status)
                                .aria_label(problem.clone())
                                .aria_live(gpui::Live::Polite)
                                .type_caption()
                                .text_color(colour)
                                .child(problem),
                        )
                    })
                    .child(
                        div().flex().child(
                            Button::new("iso-package-download", label)
                                .icon(Icon::Download)
                                .disabled(checking || state.locked())
                                .on_click(move |_, _, cx| model.update(cx, |m, cx| m.download_latest(cx))),
                        ),
                    )
            }
        };
        Some(content.into_any_element())
    }

    /// Step 2: the Windows the ISO installs. The account, then the drivers,
    /// then the PC it's for and that PC's network drivers.
    fn windows_setup(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let secondary = cx.theme().text_secondary;
        let error = account_error(self.username.read(cx).value());
        self.username.update(cx, |input, _| input.set_error(error.map(Into::into)));
        let account = card(cx)
            .child(step_card_header(cx, "iso-account", t!("iso-username"), None))
            .child(
                card_body()
                    .gap(px(8.))
                    .child(detail_text("iso-account-description", t!("iso-account-description")))
                    .child(self.username.clone())
                    .child(
                        div()
                            .text_color(secondary)
                            .child(detail_text("iso-privacy-defaults", t!("iso-privacy-defaults"))),
                    ),
            )
            .into_any_element();

        let driver_entity = cx.entity();
        let drivers = drivers_radio("iso-drivers", self.drivers, &mut self.focus, cx, move |drivers, cx| {
            driver_entity.update(cx, |this, cx| {
                this.drivers = drivers;
                cx.notify();
            })
        });
        let drivers = card(cx)
            .child(step_card_header(cx, "iso-drivers", t!("prepare-drivers"), None))
            .child(card_body().child(drivers))
            .into_any_element();

        let target_entity = cx.entity();
        let target_items = [
            RadioItem::new("iso-this-pc", t!("iso-target-this"), self.focus.get("iso-this-pc", cx))
                .icon(Icon::PC)
                // What choosing it gives, before it's chosen.
                .description(t!("iso-target-this-description")),
            RadioItem::new("iso-other-pc", t!("iso-target-other"), self.focus.get("iso-other-pc", cx))
                .icon(Icon::Devices),
        ];
        let mut target = card_body().gap(px(12.)).child(
            RadioGroup::new("iso-target", t!("iso-target-title"))
                .items(target_items)
                .selected(Some(usize::from(!self.reinstall_this_pc)))
                .on_select(move |index, _, cx| {
                    target_entity.update(cx, |this, cx| {
                        this.reinstall_this_pc = index == 0;
                        this.target_chosen = true;
                        cx.notify();
                    })
                }),
        );
        if self.reinstall_this_pc {
            target = target.child(
                CheckBox::new("iso-copy-network", t!("iso-copy-network"), self.copy_network_drivers)
                    .description(t!("iso-network-detail"))
                    .on_toggle(cx.listener(|this, _, _, cx| {
                        this.copy_network_drivers = !this.copy_network_drivers;
                        cx.notify();
                    })),
            );
            if self.copy_network_drivers {
                let network_entity = cx.entity();
                // Indented under the check box, whose text starts 32px in from its own control.
                target = target.child(
                    div().pl(px(32.)).child(
                        RadioGroup::new("iso-network-source", t!("iso-network-source"))
                            .items([
                                RadioItem::new(
                                    "iso-network-installed",
                                    t!("iso-network-installed"),
                                    self.focus.get("iso-network-installed", cx),
                                ),
                                RadioItem::new(
                                    "iso-network-updated",
                                    t!("iso-network-updated"),
                                    self.focus.get("iso-network-updated", cx),
                                )
                                .description(t!("iso-network-updated-detail")),
                            ])
                            .selected(Some(usize::from(self.update_network_drivers)))
                            .on_select(move |index, _, cx| {
                                network_entity.update(cx, |this, cx| {
                                    this.update_network_drivers = index == 1;
                                    cx.notify();
                                })
                            }),
                    ),
                );
            }
        }
        vec![
            account,
            drivers,
            card(cx)
                .child(step_card_header(cx, "iso-target", t!("iso-target-title"), None))
                .child(target)
                .into_any_element(),
        ]
    }

    /// Step 3: how Atlas is set up from the ISO and, when the ISO carries
    /// them, the choices it's set up with.
    fn choices(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let mut body = vec![];
        if self.mode != Mode::Interactive && !self.setup_available {
            // A tester build cannot swap its package, so the advice is to
            // choose the after-sign-in mode instead of a newer package.
            let bundled = self.model.read(cx).bundled();
            body.push(
                if bundled {
                    InfoBar::new(
                        Severity::Warning,
                        t!("iso-package-unsupported-bundled-title"),
                        t!("iso-package-unsupported-bundled"),
                    )
                } else {
                    InfoBar::new(
                        Severity::Warning,
                        t!("iso-package-unsupported-title"),
                        t!("iso-package-unsupported"),
                    )
                }
                .id("iso-package-unsupported")
                .into_any_element(),
            );
        }
        let entity = cx.entity();
        let modes = RadioGroup::new("iso-mode", t!("iso-mode-title"))
            .items([
                RadioItem::new(
                    "iso-interactive",
                    t!("iso-mode-interactive"),
                    self.focus.get("iso-interactive", cx),
                )
                .description(t!("iso-mode-interactive-description")),
                RadioItem::new("iso-before", t!("iso-mode-before"), self.focus.get("iso-before", cx))
                    .description(t!("iso-mode-before-description")),
                RadioItem::new("iso-desktop", t!("iso-mode-desktop"), self.focus.get("iso-desktop", cx))
                    .description(t!("iso-mode-desktop-description")),
            ])
            .selected(Some(match self.mode {
                Mode::Interactive => 0,
                Mode::Configured => 1,
                Mode::BeforeDesktop => 2,
            }))
            .on_select(move |index, _, cx| {
                entity.update(cx, |this, cx| {
                    this.mode = match index {
                        0 => Mode::Interactive,
                        1 => Mode::Configured,
                        _ => Mode::BeforeDesktop,
                    };
                    cx.notify();
                })
            });
        body.push(
            card(cx)
                .child(step_card_header(cx, "iso-mode", t!("iso-mode-title"), None))
                .child(card_body().child(modes))
                .into_any_element(),
        );
        if self.mode != Mode::Interactive
            && let Some(manifest) = self.manifest.clone()
        {
            for (page_index, page) in manifest.pages.iter().enumerate() {
                if page.depends_on.as_ref().is_some_and(|name| !self.options.contains(name)) {
                    continue;
                }
                // Titled as in the install flow: a top-level choice as a question.
                let kind = ScreenKind::of_page(page);
                let header = if page.kind == PageKind::Radio && page.depends_on.is_none() {
                    kind.question()
                } else {
                    kind.title()
                };
                let chosen = self.options.clone();
                let entity = cx.entity();
                let radio = page.kind == PageKind::Radio;
                let names: Vec<String> = page.options.iter().map(|o| o.name.clone()).collect();
                body.push(option_page_card(
                    cx,
                    "iso-option",
                    page_index,
                    page,
                    header,
                    move |name| chosen.iter().any(|option| option == name),
                    false,
                    &mut self.focus,
                    |option| describe::known_option_consequence(&option.name, &option.text),
                    Rc::new(move |name: &str, cx: &mut App| {
                        let name = name.to_owned();
                        let names = names.clone();
                        entity.update(cx, |this, cx| {
                            if radio {
                                this.options.retain(|n| !names.contains(n));
                                this.options.push(name);
                            } else if this.options.contains(&name) {
                                this.options.retain(|n| n != &name);
                            } else {
                                this.options.push(name);
                            }
                            this.clean_options();
                            cx.notify();
                        })
                    }),
                    // The ISO's own package isn't unpacked here, so no browser logos.
                    None,
                ));
            }
        }
        body
    }

    fn clean_options(&mut self) {
        if let Some(manifest) = &self.manifest {
            for page in &manifest.pages {
                if page.depends_on.as_ref().is_some_and(|n| !self.options.contains(n)) {
                    self.options.retain(|n| !page.options.iter().any(|o| &o.name == n));
                } else if page.kind == PageKind::Radio
                    && !page.options.iter().any(|o| self.options.contains(&o.name))
                    && let Some(default) = page.options.iter().find(|o| o.default)
                {
                    self.options.push(default.name.clone());
                }
            }
        }
    }

    /// One row per choice page the ISO carries: the page's name, and what was
    /// chosen on it. A choice that reduces protection says what it means.
    fn choice_rows(&self, cx: &App) -> Vec<AnyElement> {
        let Some(manifest) = self.manifest.as_ref().filter(|_| self.mode != Mode::Interactive) else {
            return vec![];
        };
        let secondary = cx.theme().text_secondary;
        manifest
            .pages
            .iter()
            .enumerate()
            .filter(|(_, page)| page.depends_on.as_ref().is_none_or(|name| self.options.contains(name)))
            .map(|(index, page)| {
                let title = ScreenKind::of_page(page).title();
                let key = format!("iso-choice-{index}");
                let chosen: Vec<ListEntry> = page
                    .options
                    .iter()
                    .filter(|option| self.options.contains(&option.name))
                    .map(|option| ListEntry::option(&option.name, &option.text))
                    .collect();
                let value = if page.kind == PageKind::Radio {
                    let (text, caution) = match chosen.into_iter().next() {
                        Some(ListEntry { text, caution }) => (text, caution),
                        None => (t!("summary-not-chosen"), None),
                    };
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .min_w_0()
                        .child(detail_text(&key, text))
                        .when_some(caution, |this, caution| {
                            this.child(caution_caption(cx, detail_text(&format!("{key}-caution"), caution)))
                        })
                        .into_any_element()
                } else if chosen.is_empty() {
                    div().text_color(secondary).child(detail_text(&key, t!("common-none"))).into_any_element()
                } else {
                    plain_list(cx, ("iso-choice-list", index), &title, chosen).into_any_element()
                };
                detail_row(cx, &key, title, value).into_any_element()
            })
            .collect()
    }

    /// Step 4: everything the ISO will be built from, as labelled rows in a
    /// card per step, each with a Change link back to that step.
    fn review(&self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let secondary = cx.theme().text_secondary;
        let caption = move |text: gpui::Text| div().type_caption().text_color(secondary).child(text);
        let file_value = |key: &str, path: &PathBuf| file_value(key, path, cx);
        let change = |id: &'static str, step: IsoStep| {
            Button::new(id, t!("common-change"))
                .hyperlink()
                .compact()
                .aria_label(t!("summary-change-a11y", title = step.title()))
                .on_click(cx.listener(move |this, _, _, cx| this.go_to_step(step, cx)))
                .into_any_element()
        };

        let mut files = card_body().gap(px(4.));
        if let Some(path) = &self.source {
            // The image's architecture and size, under its name and folder.
            let image = self.image.as_ref().map(|image| {
                let architecture = match image.architecture {
                    Architecture::X64 => t!("iso-architecture-x64"),
                    Architecture::Arm64 => t!("iso-architecture-arm64"),
                };
                [architecture, describe::file_size(image.bytes)].join(&t!("usb-detail-separator"))
            });
            files = files.child(detail_row(
                cx,
                "iso-source",
                t!("iso-source"),
                file_value("iso-review-source", path).when_some(image, |this, image| {
                    this.child(caption(detail_text("iso-review-image", image)))
                }),
            ));
        }
        if let Some(image) = &self.image {
            files = files.child(detail_row(
                cx,
                "iso-editions",
                t!("iso-review-editions"),
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .min_w_0()
                    .child(plain_list(
                        cx,
                        "iso-editions",
                        &t!("iso-review-editions"),
                        image.editions.iter().cloned().map(ListEntry::new).collect(),
                    ))
                    .child(caption(detail_text("iso-edition-selection", t!("iso-edition-selection")))),
            ));
        }
        if let Some(path) = &self.archive {
            files = files.child(detail_row(
                cx,
                "iso-package",
                t!("iso-review-package"),
                file_value("iso-review-package", path),
            ));
        } else if self.model.read(cx).bundled() {
            // A tester build adds its bundled package; say so rather than
            // leaving the row out.
            files = files.child(detail_row(
                cx,
                "iso-package",
                t!("iso-review-package"),
                detail_text("iso-review-package", t!("iso-package-bundled")),
            ));
        }
        if let Some(path) = &self.output {
            files = files.child(detail_row(
                cx,
                "iso-output",
                t!("iso-review-output"),
                file_value("iso-review-output", path),
            ));
        }

        let network = (self.reinstall_this_pc && self.copy_network_drivers).then(|| {
            if self.update_network_drivers {
                t!("iso-network-updated-detail")
            } else {
                t!("iso-network-detail")
            }
        });
        let windows = card_body()
            .gap(px(4.))
            .child(detail_row(
                cx,
                "iso-account",
                t!("iso-review-account"),
                detail_text("iso-review-account", self.username.read(cx).value().to_string()),
            ))
            .child(detail_row(
                cx,
                "iso-drivers",
                t!("iso-review-drivers"),
                detail_text(
                    "iso-review-drivers",
                    if self.drivers == Drivers::Manual {
                        t!("prepare-drivers-manual")
                    } else {
                        t!("prepare-drivers-auto")
                    },
                ),
            ))
            .child(detail_row(
                cx,
                "iso-target",
                t!("iso-review-target"),
                captioned(
                    "iso-review-target",
                    if self.reinstall_this_pc { t!("iso-target-this") } else { t!("iso-target-other") },
                    network,
                    cx,
                ),
            ));

        let (mode_title, mode_detail) = match self.mode {
            Mode::Interactive => (t!("iso-mode-interactive"), t!("iso-mode-interactive-description")),
            Mode::BeforeDesktop => (t!("iso-mode-desktop"), t!("iso-mode-desktop-description")),
            Mode::Configured => (t!("iso-mode-before"), t!("iso-mode-before-description")),
        };
        let choices = card_body()
            .gap(px(4.))
            .child(detail_row(
                cx,
                "iso-mode",
                t!("iso-atlas-options"),
                captioned("iso-review-mode", mode_title, Some(mode_detail), cx),
            ))
            .children(self.choice_rows(cx));

        let section = |key: &str, step: IsoStep, icon: Option<Icon>, id: &'static str, rows: Div| {
            card(cx)
                .child(card_header_with_icon(cx, key, step.title(), icon, Some(change(id, step)), 3))
                .child(rows)
                .into_any_element()
        };
        vec![
            div()
                .type_body()
                .text_color(secondary)
                .child(detail_text("iso-review-description", t!("iso-review-description")))
                .into_any_element(),
            section("iso-review-files", IsoStep::Files, Some(Icon::Disc), "iso-change-files", files),
            section("iso-review-windows", IsoStep::Windows, None, "iso-change-windows", windows),
            section("iso-review-choices", IsoStep::Choices, None, "iso-change-choices", choices),
        ]
    }

    /// Why the step's primary button is unavailable, when the step itself
    /// doesn't say it beside the problem.
    fn hint(&self, gates: Gates, cx: &App) -> String {
        match self.step {
            IsoStep::Windows if self.username.read(cx).value().is_empty() => t!("iso-account-empty"),
            // Why Review ISO is unavailable; the bar above offers the fixes.
            IsoStep::Choices if !gates.mode => t!("iso-package-unsupported-bundled-title"),
            _ => String::new(),
        }
    }

    /// Back and the step's primary button, or the controls of a running or
    /// finished job.
    fn footer(&self, gates: Gates, busy: bool, cancelling: bool, cx: &mut Context<Self>) -> AnyElement {
        if busy {
            return CommandBar::new()
                .cancel(
                    "iso-cancel",
                    if cancelling { t!("iso-cancelling") } else { t!("iso-cancel") },
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
                this.invalidate(cx);
                this.model.update(cx, |m, cx| m.navigate(Page::Home, cx));
            }));
            let usb = Button::new("iso-write-usb", t!("usb-title"))
                .accent()
                .on_click(cx.listener(|this, _, _, cx| this.open_usb(this.output.clone(), cx)));
            return CommandBar::new().back(done).primary(usb).into_any_element();
        }
        let locked = self.model.read(cx).locked();
        let back = Button::new("iso-back", t!("common-back"))
            .disabled(self.step.previous().is_none() || locked)
            .on_click(cx.listener(|this, _, _, cx| {
                if let Some(previous) = this.step.previous() {
                    this.go_to_step(previous, cx);
                }
            }));
        let next = |label: String, enabled: bool, cx: &mut Context<Self>| {
            Button::new("iso-next", label)
                .accent()
                .trailing_icon(Icon::ChevronRight)
                .disabled(!enabled || locked)
                .on_click(cx.listener(|this, _, _, cx| {
                    if let Some(next) = this.step.next() {
                        this.go_to_step(next, cx);
                    }
                }))
        };
        let primary = match self.step {
            // Choosing another file clears the check; until then the files
            // stay checked and Continue is the way on.
            IsoStep::Files if gates.checked => next(t!("common-next"), true, cx),
            IsoStep::Files => {
                let bundled = self.model.read(cx).bundled();
                Button::new("iso-inspect", t!("iso-inspect"))
                    .accent()
                    .disabled(
                        self.source.is_none()
                            || (self.archive.is_none() && !bundled)
                            || self.output.is_none()
                            || locked,
                    )
                    .on_click(cx.listener(|this, _, _, cx| this.start(true, cx)))
            }
            IsoStep::Windows => next(t!("common-next"), gates.account, cx),
            IsoStep::Choices => next(t!("iso-review"), gates.mode, cx),
            IsoStep::Review => Button::new("iso-create", t!("iso-create"))
                .accent()
                .disabled(locked)
                .on_click(cx.listener(|this, _, _, cx| this.start(false, cx))),
        };
        CommandBar::new().hint(self.hint(gates, cx)).back(back).primary(primary).into_any_element()
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
        let (busy, cancelling, elevated, visit) = {
            let state = self.model.read(cx);
            let elevated = (state.elevated || self.preview.is_some()) && !self.preview_unelevated;
            (
                state.iso_busy,
                state.iso_busy && state.iso_cancel.load(Ordering::Relaxed),
                elevated,
                state.page_visit,
            )
        };
        let failed = matches!(self.result, JobResult::Failed(_));
        let complete = self.result == JobResult::Complete;
        let cancelled = self.result == JobResult::Cancelled;
        // A build runs from Review and takes over the page; a check runs within step 1.
        let building = busy && self.step == IsoStep::Review;
        let status = self.focus.get("iso-status", cx);
        let shown = (self.step, busy, self.result, visit);
        if self.shown != Some(shown) {
            self.shown = Some(shown);
            window.focus(&status, cx);
        }
        let gates = self.gates(cx);

        let mut body: Vec<AnyElement> = Vec::new();
        if !building && !complete {
            body.push(self.stepper(gates, elevated && !busy && !self.model.read(cx).locked(), cx));
            // A new step is announced by its heading, unless a result or a
            // check in progress is announced instead.
            let heading_focus = if elevated && !busy && !failed && !cancelled {
                status.clone()
            } else {
                self.focus.get("iso-step-heading", cx)
            };
            let title = t!(
                "step-heading",
                number = self.step.index() + 1,
                total = IsoStep::ALL.len(),
                title = self.step.title()
            );
            body.push(
                focusable_heading("iso-step-heading", 2, title, &heading_focus, cx)
                    .type_subtitle()
                    .pb(px(4.))
                    .into_any_element(),
            );
        }
        let mut footer = None;
        if !elevated {
            // Nothing on this page works without the permission, so the bar
            // and its button are all there is.
            body.push(self.elevation_bar(failed, &status, cx));
        } else {
            // What the last check or build came to, under the steps, with
            // the ways to get help right beside it.
            if failed || cancelled {
                body.push(if failed { self.error_bar(&status) } else { self.cancelled_bar(&status) });
                body.push(self.diagnostics.panel(&self.model, cx).into_any_element());
            }
            // Where a build stopped, as the checklist it showed while running.
            if self.failed_stage().is_some() {
                body.push(card(cx).child(card_body().child(self.stage_list(true, cx))).into_any_element());
            }
            if building {
                let current = if cancelling { t!("iso-cancelling") } else { stage_text(self.stage) };
                body.push(
                    card(cx)
                        .child(
                            card_body()
                                .gap(px(16.))
                                .child(focusable_heading(
                                    "iso-progress-title",
                                    2,
                                    t!("iso-progress-title"),
                                    &status,
                                    cx,
                                ))
                                // The one live node while creating: it names the stage.
                                .child(ProgressBar::new("iso-progress", current, None).live())
                                .child(self.stage_list(false, cx))
                                .child(detail_text(
                                    "iso-progress-description",
                                    t!("iso-progress-description"),
                                )),
                        )
                        .into_any_element(),
                );
            } else if busy {
                let stage = if cancelling { t!("iso-cancelling") } else { stage_text(self.stage) };
                body.push(
                    card(cx)
                        .child(
                            card_body()
                                .gap(px(18.))
                                .child(focusable_heading("iso-progress-title", 2, stage.clone(), &status, cx))
                                .child(ProgressBar::new("iso-progress", stage, None).live())
                                .child(detail_text(
                                    "iso-progress-description",
                                    t!("iso-progress-description"),
                                )),
                        )
                        .into_any_element(),
                );
            } else if complete {
                body.push(
                    InfoBar::new(Severity::Success, t!("iso-complete"), t!("iso-complete-description"))
                        .id("iso-complete")
                        .focus_handle(status.clone())
                        // Network drivers were asked for, and Windows has them already.
                        .when(self.network_inbox, |bar| {
                            bar.content(
                                div()
                                    .type_body()
                                    .child(a11y_text("iso-network-inbox", t!("iso-network-inbox"))),
                            )
                        })
                        .into_any_element(),
                );
                if let Some(path) = &self.output {
                    body.push(
                        card(cx)
                            .child(
                                card_body().child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .gap(px(12.))
                                        .child(TextMark::new(icon(Icon::Disc), false).natural_text())
                                        .child(div().flex_1().min_w_0().child(detail_text(
                                            "iso-created-file",
                                            path.display().to_string(),
                                        )))
                                        .child(
                                            Button::new("iso-reveal", t!("iso-open-folder"))
                                                .icon(Icon::Folder)
                                                .on_click(cx.listener(|this, _, _, cx| {
                                                    if let Some(path) = &this.output {
                                                        cx.reveal_path(path);
                                                    }
                                                })),
                                        ),
                                ),
                            )
                            .into_any_element(),
                    );
                }
            } else {
                match self.step {
                    IsoStep::Files => {
                        // The title's Beta badge says why. This bar gives the
                        // safety advice once, where the flow starts, unless a
                        // result already holds the top of the page.
                        if !failed && !cancelled {
                            body.push(
                                InfoBar::new(Severity::Informational, "", t!("iso-beta-description"))
                                    .id("iso-beta")
                                    .into_any_element(),
                            );
                        }
                        let bundled = self.model.read(cx).bundled();
                        body.push(
                            detail_text(
                                "iso-files-description",
                                if bundled {
                                    t!("iso-files-description-bundled")
                                } else {
                                    t!("iso-files-description")
                                },
                            )
                            .into_any_element(),
                        );
                        body.push(self.files(gates.checked, cx));
                        body.push(
                            div()
                                .flex()
                                .child(
                                    Button::new("iso-existing-usb", t!("usb-existing"))
                                        .hyperlink()
                                        .on_click(cx.listener(|this, _, _, cx| this.open_usb(None, cx))),
                                )
                                .into_any_element(),
                        );
                    }
                    IsoStep::Windows => body.extend(self.windows_setup(cx)),
                    IsoStep::Choices => body.extend(self.choices(cx)),
                    IsoStep::Review => body.extend(self.review(cx)),
                }
            }
            footer = Some(self.footer(gates, busy, cancelling, cx));
        }
        self.diagnostics.settle(&self.model, window, cx);
        page_frame(
            "iso-page",
            Some(PageTitle { text: t!("iso-title").into(), badge: Some(t!("iso-beta").into()), back: None }),
            None,
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            body,
            footer,
            cx,
        )
        .into_any_element()
    }
}

impl IsoPage {
    /// Title and message of the error bar: what failed and what to do next,
    /// as far as the worker said. Only an existing output file calls for a
    /// new filename; a failed build leaves the chosen name free.
    fn failure_text(&self) -> (String, String) {
        let checking = self.step == IsoStep::Files;
        let failure = match self.result {
            JobResult::Failed(reason) => reason,
            _ => None,
        };
        let title = match failure {
            Some(FailureReason::PackageUnsupported) => t!("iso-package-unsupported-title"),
            _ if checking => t!("iso-check-failed"),
            _ => t!("iso-failed"),
        };
        if self.job.is_none() {
            // Nothing ran: there are no diagnostics to point at.
            return (title, t!("iso-failed-unstaged"));
        }
        let message = match failure {
            Some(FailureReason::WindowsReleaseUnknown) => t!("iso-release-unknown"),
            Some(FailureReason::OutputExists) => t!("iso-failed-output-exists"),
            Some(FailureReason::DestinationFilesystem) => t!("iso-failed-destination"),
            Some(FailureReason::DiskSpace) => t!("iso-failed-space"),
            Some(FailureReason::WindowsUnsupported) => t!("iso-failed-windows-unsupported"),
            Some(FailureReason::EditionUnsupported) => t!("iso-failed-edition"),
            Some(FailureReason::IsoCustomised) => t!("iso-failed-customised"),
            Some(FailureReason::NetworkArchitecture) => t!("iso-failed-network-architecture"),
            Some(FailureReason::PackageUnsupported) => {
                t!("iso-failed-package-unsupported", minimum = iso::MINIMUM_VERSION)
            }
            Some(FailureReason::PackageChanged) => t!("iso-failed-package-changed"),
            Some(FailureReason::Build) if self.stage == Stage::NetworkDrivers => t!("iso-network-failed"),
            Some(FailureReason::Check) | None if checking => t!("iso-check-failed-description"),
            Some(FailureReason::Check | FailureReason::Build) | None => t!("iso-failed-description"),
        };
        (title, message)
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

/// The network choices a request carries: reinstall this PC, copy its network
/// drivers, update them. A check carries none: they are made in step 2, which a
/// failed check cannot reach.
fn network_choices(inspect: bool, reinstall: bool, copy: bool, update: bool) -> (bool, bool, bool) {
    let reinstall = !inspect && reinstall;
    let copy = reinstall && copy;
    (reinstall, copy, copy && update)
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
mod tests {
    use super::*;
    use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
    use crate::services::test_support::TempDir;

    #[test]
    fn a_check_sends_no_network_driver_choices() {
        // Chosen on an earlier visit to step 2, which a failed check could not lead back to.
        assert_eq!(network_choices(true, true, true, true), (false, false, false));
        assert_eq!(network_choices(false, true, true, true), (true, true, true));
        assert_eq!(network_choices(false, true, false, true), (true, false, false));
        assert_eq!(network_choices(false, false, true, true), (false, false, false));
    }

    const ALL_DONE: Gates = Gates { checked: true, account: true, mode: true };

    #[test]
    fn the_stepper_goes_back_freely_and_forward_only_to_visited_steps_that_still_hold() {
        use IsoStep::*;
        // Back to any earlier step; never to the step showing.
        assert!(ALL_DONE.reachable(Review, Files, Review));
        assert!(Gates::default().reachable(Choices, Windows, Choices));
        assert!(!ALL_DONE.reachable(Windows, Windows, Review));
        // Forward only as far as the furthest step reached.
        assert!(ALL_DONE.reachable(Files, Review, Review));
        assert!(!ALL_DONE.reachable(Files, Choices, Windows));
        // Never past a step that no longer holds: an account name cleared on
        // Windows setup keeps Review out of reach from there and from Files.
        let no_account = Gates { account: false, ..ALL_DONE };
        assert!(!no_account.reachable(Windows, Review, Review));
        assert!(!no_account.reachable(Files, Choices, Review));
        assert!(no_account.reachable(Files, Windows, Review));
        // A package that can't carry the mode keeps Review out of reach.
        let no_mode = Gates { mode: false, ..ALL_DONE };
        assert!(!no_mode.reachable(Windows, Review, Review));
        assert!(no_mode.reachable(Windows, Choices, Review));
    }

    #[test]
    fn steps_the_user_went_past_stay_done_while_an_earlier_one_shows() {
        use IsoStep::*;
        let statuses =
            |current, furthest, gates| IsoStep::ALL.map(|step| step_status(step, current, furthest, gates));
        use StepStatus::{Attention, Current, Done, Upcoming};
        assert_eq!(statuses(Windows, Windows, ALL_DONE), [Done, Current, Upcoming, Upcoming]);
        // Back on Files from Review: the steps in between are still done, and
        // Review, never finished, is still to come.
        assert_eq!(statuses(Files, Review, ALL_DONE), [Current, Done, Done, Upcoming]);
        // Visited but not gone past.
        assert_eq!(statuses(Files, Choices, ALL_DONE), [Current, Done, Upcoming, Upcoming]);
        let no_account = Gates { account: false, ..ALL_DONE };
        assert_eq!(statuses(Files, Review, no_account), [Current, Upcoming, Done, Upcoming]);
        assert_eq!(statuses(Review, Review, no_account), [Done, Attention, Done, Current]);
    }

    #[test]
    fn a_build_ticks_off_its_stages_and_marks_the_one_that_failed() {
        let states = |reported, failed| {
            Stage::build(false)
                .into_iter()
                .map(|stage| stage_state(stage, reported, failed))
                .collect::<Vec<_>>()
        };
        use StageState::*;
        assert_eq!(
            states(Stage::Inspect, false),
            [Current, NotStarted, NotStarted, NotStarted, NotStarted, NotStarted]
        );
        assert_eq!(states(Stage::Master, false), [Done, Done, Done, Current, NotStarted, NotStarted]);
        assert_eq!(states(Stage::Master, true), [Done, Done, Done, Failed, NotStarted, NotStarted]);
        assert_eq!(states(Stage::Cleanup, false), [Done, Done, Done, Done, Done, Current]);
    }

    #[test]
    fn a_stage_says_plainly_where_it_stands() {
        crate::i18n::testing::english(|| {
            assert_eq!(
                stage_name(&stage_text(Stage::Master), StageState::Failed),
                "Writing the ISO file, failed"
            );
            assert_eq!(
                stage_name(&stage_text(Stage::Copy), StageState::Done),
                "Copying Windows files, completed"
            );
            assert!(!stage_name("x", StageState::Current).contains("Step"));
        });
    }

    #[test]
    fn an_empty_account_name_waits_and_a_refused_one_says_what_to_change() {
        crate::i18n::testing::english(|| {
            assert_eq!(account_error(""), None);
            assert_eq!(account_error("Atlas"), None);
            assert_eq!(account_error("Atlas/PC"), Some(t!("iso-account-invalid")));
            assert_eq!(account_error("Atlas."), Some(t!("iso-account-trailing-dot")));
            assert_eq!(account_error("Guest"), Some(t!("iso-account-reserved")));
            // The message lists every symbol Windows refuses.
            for symbol in "\"/\\[]:;|=,+*?<>@".chars() {
                assert!(t!("iso-account-invalid").contains(symbol), "{symbol}");
            }
        });
    }

    #[test]
    fn the_suggested_iso_never_overwrites_a_file() {
        let folder = Path::new(r"C:\Downloads");
        assert_eq!(free_output(folder, |_| false), folder.join("Atlas-Windows.iso"));
        let taken = [folder.join("Atlas-Windows.iso"), folder.join("Atlas-Windows (2).iso")];
        assert_eq!(
            free_output(folder, |path| taken.iter().any(|t| t == path)),
            folder.join("Atlas-Windows (3).iso")
        );
    }

    fn page(cx: &mut gpui::AsyncApp, temp: &TempDir) -> Entity<IsoPage> {
        let model = new_model(cx, Machine::new(all_off()).environment(temp.path()));
        cx.update(|cx| cx.new(|cx| IsoPage::new(model.clone(), cx)))
    }

    #[test]
    fn only_a_failure_with_a_job_points_at_its_diagnostics() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-failure-text");
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, _| {
                page.result = JobResult::Failed(None);
                page.job = None;
                assert_eq!(page.failure_text(), (t!("iso-check-failed"), t!("iso-failed-unstaged")));
                page.step = IsoStep::Review;
                assert_eq!(page.failure_text(), (t!("iso-failed"), t!("iso-failed-unstaged")));

                page.job = Some(temp.path().to_path_buf());
                assert_eq!(page.failure_text().1, t!("iso-failed-description"));
                page.step = IsoStep::Files;
                assert_eq!(page.failure_text().1, t!("iso-check-failed-description"));
                // An Atlas package replaced after the check is named, whatever the step.
                page.step = IsoStep::Review;
                page.result = JobResult::Failed(Some(FailureReason::PackageChanged));
                assert_eq!(page.failure_text(), (t!("iso-failed"), t!("iso-failed-package-changed")));
            });
        });
    }

    #[test]
    fn only_a_build_the_worker_ran_shows_the_stage_it_failed_at() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-failed-stage");
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, _| {
                page.step = IsoStep::Review;
                page.stage = Stage::Master;
                page.job = Some(temp.path().to_path_buf());
                page.result = JobResult::Failed(Some(FailureReason::Build));
                assert_eq!(page.failed_stage(), Some(Stage::Master));
                // Refused by Atlas before the worker started.
                page.result = JobResult::Failed(Some(FailureReason::PackageChanged));
                assert_eq!(page.failed_stage(), None);
                // No job: nothing ran.
                page.result = JobResult::Failed(None);
                page.job = None;
                assert_eq!(page.failed_stage(), None);
                // A failed check has no stages to show.
                page.job = Some(temp.path().to_path_buf());
                page.step = IsoStep::Files;
                assert_eq!(page.failed_stage(), None);
                page.step = IsoStep::Review;
                page.result = JobResult::Cancelled;
                assert_eq!(page.failed_stage(), None);
            });
        });
    }

    #[test]
    fn the_new_iso_follows_the_source_until_the_user_chooses_where_to_save_it() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-output");
            let (first, second) = (temp.path().join("first"), temp.path().join("second"));
            std::fs::create_dir_all(&first).unwrap();
            std::fs::create_dir_all(&second).unwrap();
            // An ISO made earlier keeps its name.
            std::fs::write(first.join("Atlas-Windows.iso"), b"earlier").unwrap();
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, _| {
                page.source = Some(first.join("Windows.iso"));
                page.suggest_output();
                assert_eq!(page.output, Some(first.join("Atlas-Windows (2).iso")));
                page.source = Some(second.join("Windows.iso"));
                page.suggest_output();
                assert_eq!(page.output, Some(second.join("Atlas-Windows.iso")));
                // Chosen with Save as: it stays where the user put it.
                let chosen = temp.path().join("Mine.iso");
                page.output = Some(chosen.clone());
                page.output_suggested = false;
                page.source = Some(first.join("Windows.iso"));
                page.suggest_output();
                assert_eq!(page.output, Some(chosen));
            });
        });
    }

    #[test]
    fn going_back_and_forward_keeps_every_choice_and_a_new_file_starts_again() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-steps");
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, cx| {
                page.image = Some(ImageInfo {
                    editions: vec!["Windows 11 Pro".into()],
                    bytes: 1,
                    architecture: Architecture::X64,
                });
                page.username.update(cx, |input, cx| input.set_value("Ada", cx));
                page.go_to_step(IsoStep::Windows, cx);
                page.reinstall_this_pc = true;
                page.drivers = Drivers::Manual;
                page.go_to_step(IsoStep::Choices, cx);
                page.mode = Mode::Interactive;
                page.go_to_step(IsoStep::Review, cx);
                page.go_to_step(IsoStep::Files, cx);
                assert_eq!(page.furthest, IsoStep::Review);
                assert!(page.gates(cx).reachable(page.step, IsoStep::Review, page.furthest));
                assert_eq!(page.username.read(cx).value(), "Ada");
                assert!(page.reinstall_this_pc && page.drivers == Drivers::Manual);
                // Choosing another file means checking again from the start.
                page.invalidate(cx);
                assert_eq!((page.step, page.furthest), (IsoStep::Files, IsoStep::Files));
                assert!(!page.gates(cx).reachable(IsoStep::Files, IsoStep::Windows, page.furthest));
                assert_eq!(page.username.read(cx).value(), "Ada");
            });
        });
    }

    #[test]
    fn a_result_stays_with_its_step_and_a_changed_package_is_checked_again() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-result-step");
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, cx| {
                page.image = Some(ImageInfo {
                    editions: vec!["Windows 11 Pro".into()],
                    bytes: 1,
                    architecture: Architecture::X64,
                });
                page.step = IsoStep::Review;
                page.furthest = IsoStep::Review;
                page.finish(false, false, Err(anyhow::anyhow!("worker failed")));
                // The step showing keeps its result.
                page.go_to_step(IsoStep::Review, cx);
                assert_eq!(page.result, JobResult::Failed(None));
                assert!(page.gates(cx).checked, "a failed build leaves the check standing");

                page.finish(
                    false,
                    false,
                    Err(iso::Failure::new(FailureReason::PackageChanged, "test").into()),
                );
                assert_eq!(page.result, JobResult::Failed(Some(FailureReason::PackageChanged)));
                // Change next to Files, as the bar says: no build failure on
                // the Files step, and Check files rather than Continue.
                page.go_to_step(IsoStep::Files, cx);
                assert_eq!(page.result, JobResult::None);
                assert!(!page.gates(cx).checked);
                assert!(!page.gates(cx).reachable(IsoStep::Files, IsoStep::Windows, page.furthest));
            });
        });
    }

    #[test]
    fn the_footer_says_what_an_unavailable_step_still_needs() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("iso-hint");
            let page = page(&mut cx, &temp);
            page.update(&mut cx, |page, cx| {
                page.step = IsoStep::Windows;
                assert_eq!(page.hint(page.gates(cx), cx), t!("iso-account-empty"));
                // A name with a problem says so in the field, not here.
                page.username.update(cx, |input, cx| input.set_value("Atlas/PC", cx));
                assert!(!page.gates(cx).account);
                assert_eq!(page.hint(page.gates(cx), cx), "");
                page.step = IsoStep::Choices;
                page.mode = Mode::Configured;
                page.setup_available = false;
                // Why Review ISO is unavailable, not the harder of the two fixes.
                assert_eq!(page.hint(page.gates(cx), cx), t!("iso-package-unsupported-bundled-title"));
                page.setup_available = true;
                assert_eq!(page.hint(page.gates(cx), cx), "");
            });
        });
    }
}
