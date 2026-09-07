//! UI state and background task coordination. Pages render this model; actions
//! use [`crate::flow`] to enforce install transitions and prevent changes while
//! an install is running.
//!
//! The model owns the check, download, security and restart tasks. Replacing a
//! task drops its handle; generation checks discard results from older tasks.

use std::collections::BTreeSet;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, Instant};

use futures::StreamExt;
use gpui::{ClipboardItem, Context, EventEmitter, PathPromptOptions, SharedString, Task};

pub use crate::environment::Environment;
pub use crate::flow::{Flow, RunState, Step};
use crate::i18n::{self, Localization, describe};
use crate::services::atlas_state::{self, AtlasState};
use crate::services::installer::{self, InstallEvent, InstallOutcome, InstallRequest, Phase};
use crate::services::playbook::{self, FeaturePage, Manifest, PageKind};
use crate::services::releases::{self, Release};
use crate::services::requirements::{CheckContext, CheckDetail, CheckId, CheckResult};
use crate::services::security::{SecurityStatus, SwitchCounts};
use crate::services::session::{self, Inspection, LaunchLock, SessionPaths, SessionRecord};
use crate::services::settings::{
    self, AppSettings, InstallDraft, LanguagePreference, SettingsProblem, ThemePreference,
};
use crate::services::system::{self, AccessibilityPreferences, SystemInfo};
use crate::t;

/// Lines kept in memory; the full log is on disk.
const LOG_KEEP: usize = 2000;
/// Bytes of log kept in memory, whatever the line count.
const LOG_KEEP_BYTES: usize = 1024 * 1024;
/// A Windows Security reading older than this is not trusted for the gate.
const SECURITY_FRESH: Duration = Duration::from_secs(5);
/// How long startup waits for the shared install record before carrying on
/// without it and finishing the recovery in the background. The lock is
/// uncontended in practice; another window mid-launch holds it for
/// milliseconds, and a stuck holder must not freeze this window's first frame.
const STARTUP_WAIT: Duration = Duration::from_millis(250);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Page {
    Home,
    Iso,
    Install,
    Settings,
    /// The completion window the payload opens after the restart.
    Installed,
}

impl Page {
    /// Command-line spelling, for `--page`.
    pub fn parse(name: &str) -> Option<Page> {
        match name.to_ascii_lowercase().as_str() {
            "home" | "updates" => Some(Page::Home),
            "iso" => Some(Page::Iso),
            "install" => Some(Page::Install),
            "settings" => Some(Page::Settings),
            "installed" => Some(Page::Installed),
            _ => None,
        }
    }
}

#[derive(Clone, Debug)]
pub enum ReleaseCheck {
    NotChecked,
    Checking,
    Ready { release: Release },
    Failed,
}

impl ReleaseCheck {
    pub fn release(&self) -> Option<&Release> {
        match self {
            ReleaseCheck::Ready { release } => Some(release),
            _ => None,
        }
    }
}

#[derive(Clone, Debug)]
pub enum Acquisition {
    Idle,
    Downloading { received: u64, total: u64 },
    Extracting { done: usize, total: usize },
    Failed(AcquireProblem),
}

/// Why the package could not be made ready. Worded when rendered.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AcquireProblem {
    /// The release has no .apbx asset.
    NoPlaybookAsset { version: String },
    /// The package predates the front door script.
    Unsupported { version: String },
    /// Anything else, with the raw error chain as a diagnostic.
    Other { error: String },
}

impl Acquisition {
    pub fn is_busy(&self) -> bool {
        matches!(self, Acquisition::Downloading { .. } | Acquisition::Extracting { .. })
    }
}

#[derive(Clone, Debug)]
pub enum Origin {
    Release(String),
    LocalFile(PathBuf),
    /// Unpacked earlier and picked up again after a relaunch.
    Unpacked,
}

/// A prepared package: an immutable directory whose name carries the
/// package's version and content digest (see [`playbook::extract_into`]),
/// so the manifest read from it describes the files that will run.
#[derive(Clone, Debug)]
pub struct PlaybookSource {
    pub dir: PathBuf,
    pub manifest: Manifest,
    pub origin: Origin,
}

impl PlaybookSource {
    /// Where the package came from, in the current language.
    pub fn describe(&self) -> String {
        match &self.origin {
            Origin::Release(version) => t!("package-from-release", version = version),
            Origin::LocalFile(path) => {
                t!("package-from-file", version = &self.manifest.version, file = releases::file_name(path))
            }
            Origin::Unpacked => t!("package-unpacked", version = &self.manifest.version),
        }
    }
}

/// Something the user should know about the app's own state (a damaged
/// settings file, a save that failed), shown on Home until dismissed. Held
/// as its cause so it can be worded in whatever language is current.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Notice {
    SettingsReset(SettingsProblem),
    SettingsNotSaved { error: String },
    SessionUnreadable { error: String, record: PathBuf },
}

/// Why the final checks refused to start the install.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Preflight {
    InvalidOptions {
        error: String,
    },
    /// Checks or Windows Security changed since the user last saw them.
    Changed {
        checks: Vec<(CheckId, CheckDetail)>,
        security: Option<SwitchCounts>,
    },
    /// Another window holds the launch lock.
    Busy,
    /// The shared install record cannot be read, so nothing may start.
    RecordUnreadable {
        error: String,
    },
    /// The launch protocol refused; nothing ran.
    Refused {
        error: String,
    },
}

/// Why the last "Restart as administrator" did not happen.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ElevationProblem {
    Declined,
    DeclinedContinue,
    DraftNotSaved { error: String },
}

/// A restart command that did not take.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum RestartProblem {
    Start { error: String },
}

/// A restart countdown in progress: when it ends, and how long it was, so
/// the remaining time is read from the clock rather than counted in ticks.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct RestartCountdown {
    pub deadline: Instant,
    pub total: Duration,
}

impl RestartCountdown {
    /// Whole seconds left, rounded up; `0` once the deadline has passed.
    pub fn seconds_left(&self) -> u32 {
        self.deadline.saturating_duration_since(Instant::now()).as_secs_f32().ceil() as u32
    }

    /// How far along the countdown is, 0 to 1.
    pub fn progress(&self) -> f32 {
        let left = self.deadline.saturating_duration_since(Instant::now()).as_secs_f32();
        (1.0 - left / self.total.as_secs_f32().max(f32::EPSILON)).clamp(0.0, 1.0)
    }
}

/// State that belongs to one install attempt: the log tail and the phase
/// read from it, an output problem, and the restart that follows a success.
/// It is reset as a whole whenever the attempt's session is dropped or a new
/// attempt starts, so nothing from an earlier attempt can show under a
/// later result.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct InstallAttempt {
    /// The tail of the install log; the whole log is in the session's `log_path`.
    pub log: Vec<SharedString>,
    pub log_total: usize,
    /// Bytes held in `log`.
    log_bytes: usize,
    pub phase: Phase,
    pub plan_progress: Option<installer::PlanProgress>,
    /// The raw error from reading the install log, if reading failed.
    pub output_problem: Option<String>,
    /// The result was found after reopening the app: the install had already
    /// ended, so whether Windows is about to restart is unknown and no
    /// countdown is shown for it.
    pub recovered: bool,
    /// The front door asked Windows to restart, and this is the countdown.
    pub restart: Option<RestartCountdown>,
    /// The user stopped the automatic restart.
    pub restart_cancelled: bool,
    /// A restart command that did not take.
    pub restart_problem: Option<RestartProblem>,
}

impl InstallAttempt {
    pub fn reset(&mut self) {
        *self = Self::default();
    }

    /// Appends output to the tail kept in memory, reads the phase from it,
    /// and trims the tail to [`LOG_KEEP`] lines and [`LOG_KEEP_BYTES`]
    /// bytes. The decoder has already capped each line.
    pub fn push_lines(&mut self, lines: Vec<String>) {
        for line in &lines {
            if let Some(progress) = installer::PlanProgress::from_line(line) {
                // Replayed/duplicated log batches must not move the bar backwards.
                if self.plan_progress.is_none_or(|old| progress.fraction() >= old.fraction()) {
                    self.plan_progress = Some(progress);
                }
            }
            if let Some(phase) = Phase::from_line(line) {
                self.phase = self.phase.max(phase);
            }
        }
        self.log_total += lines.len();
        for line in lines {
            self.log_bytes += line.len();
            self.log.push(SharedString::from(line));
        }
        let mut drop = 0;
        let mut bytes = self.log_bytes;
        let mut count = self.log.len();
        while drop < self.log.len() && (count > LOG_KEEP || bytes > LOG_KEEP_BYTES) {
            bytes -= self.log[drop].len();
            count -= 1;
            drop += 1;
        }
        if drop > 0 {
            self.log.drain(..drop);
            self.log_bytes = bytes;
        }
    }

    /// Seconds left on the restart countdown, or `None` when none is running.
    pub fn restart_countdown(&self) -> Option<u32> {
        self.restart.map(|countdown| countdown.seconds_left())
    }
}

enum Progress {
    Download(u64, u64),
    Extract(usize, usize),
}

/// What the restart timer found when it woke.
enum Tick {
    Continue,
    Expired,
    Stop,
}

/// What startup found in the shared install record, read on a worker so a
/// held launch lock never blocks the window.
#[derive(Debug)]
enum StartupInspection {
    None,
    Unreadable(String),
    Live(SessionRecord),
    Ended(SessionRecord),
}

pub enum ModelEvent {
    ThemeChanged,
    LanguageChanged,
}

pub struct AppModel {
    pub before_desktop: bool,
    iso_initial_options: Option<Vec<String>>,
    pub preparation: crate::services::preparation::State,
    pub preparation_job: Option<PathBuf>,
    pub preparation_cancel: Arc<std::sync::atomic::AtomicBool>,
    preparation_task: Option<Task<()>>,
    pub iso_busy: bool,
    pub usb_busy: bool,
    pub iso_cancel: Arc<std::sync::atomic::AtomicBool>,
    env: Environment,
    pub page: Page,
    pub system: SystemInfo,
    pub elevated: bool,
    pub atlas: Result<Option<AtlasState>, String>,
    pub install_identity: Result<atlas_state::InstallIdentity, String>,
    pub settings: AppSettings,
    pub notice: Option<Notice>,
    pub accessibility: AccessibilityPreferences,
    /// Which language is showing and how that was decided.
    pub localization: Localization,
    /// Startup is still finding out whether an install is running; nothing
    /// that could start one is offered until it knows.
    pub recovering: bool,

    pub release: ReleaseCheck,
    pub acquisition: Acquisition,
    acquisition_task: Option<Task<()>>,
    acquisition_epoch: u64,
    pub playbook: Option<PlaybookSource>,
    builtin_manifest: Manifest,

    pub security: SecurityStatus,
    security_read_at: Option<Instant>,
    security_watch: Option<Task<()>>,
    security_epoch: u64,
    /// The user confirmed, in Windows Security, that the switches that could
    /// not be read are off. The confirmation names the reading it was given
    /// for: a different reading, later, is not covered by it.
    security_confirmation: Option<SecurityStatus>,

    pub flow: Flow,
    /// Which screen of the Options step is showing (see [`AppModel::option_screens`]).
    pub option_screen: usize,
    pub options: BTreeSet<String>,
    pub checks: Vec<(CheckId, Option<CheckResult>)>,
    check_tasks: Vec<Task<()>>,
    /// Blocking checks that could not run and that the user confirmed by hand.
    pub acknowledged: BTreeSet<CheckId>,
    checks_epoch: u64,
    /// Why the final checks refused to start the install.
    pub preflight_problem: Option<Preflight>,

    /// The running or most recently finished install.
    pub session: Option<SessionRecord>,
    /// The session this window itself started, if any; its draft is cleared
    /// when that install succeeds and no other.
    own_session: Option<String>,
    /// The identity of the flow this window is running, written into its
    /// draft so only this window saves or abandons it.
    flow_id: Option<String>,
    /// The one writer of settings.json: ordered transactions on a thread of
    /// their own, each against the document as it is on disk.
    store: settings::Store,
    /// Everything that belongs to that install attempt alone.
    pub attempt: InstallAttempt,
    restart_timer: Option<Task<()>>,
    restart_epoch: u64,
    /// Why the last "Restart as administrator" did not happen, if it did not.
    pub elevation_error: Option<ElevationProblem>,
    /// The user left the flow with Windows Security switched off.
    pub security_reminder: bool,
    session_paths: SessionPaths,
}

impl EventEmitter<ModelEvent> for AppModel {}

/// The shipped English variant that best matches a Windows display-language
/// list; British English, the source, when none matches.
pub fn english_for(windows_languages: &[String]) -> String {
    let english: Vec<&'static i18n::Locale> = i18n::catalog::LOCALES
        .iter()
        .filter(|locale| locale.listed() && locale.id().language.as_str() == "en")
        .collect();
    let requested = i18n::negotiate::parse_tags(windows_languages.iter().map(String::as_str));
    i18n::negotiate::negotiate(&requested, &english)
        .first()
        .filter(|_| requested.iter().any(|tag| tag.language.as_str() == "en"))
        .map(|locale| locale.tag.to_owned())
        .unwrap_or_else(|| i18n::catalog::SOURCE_TAG.to_owned())
}

impl AppModel {
    /// `language_override` comes from `--language` and outranks the setting
    /// (review and testing only).
    pub fn new(language_override: Option<String>, cx: &mut Context<Self>) -> Self {
        Self::with_environment(Environment::from_process(language_override), cx)
    }

    pub fn with_environment(env: Environment, cx: &mut Context<Self>) -> Self {
        let builtin_manifest = Manifest::builtin();
        let options = builtin_manifest.default_options().into_iter().collect();
        let loaded = settings::load_from(&env.paths.settings());
        // Before anything renders, so the first frame is already translated.
        let localization = i18n::activate(&loaded.settings.language, env.language_override.as_deref());
        let session_paths = env.paths.session();
        let store = settings::Store::new(env.paths.settings());
        let elevated = (env.adapters.is_elevated)();
        let mut model = Self {
            before_desktop: crate::services::desktop_setup::active()
                || (cfg!(debug_assertions) && std::env::var_os("ATLAS_DESKTOP_PREVIEW").is_some()),
            iso_initial_options: if loaded.settings.draft.is_none() {
                crate::services::iso::staged_options()
            } else {
                None
            },
            preparation: Default::default(),
            preparation_job: None,
            preparation_cancel: Arc::new(std::sync::atomic::AtomicBool::new(false)),
            preparation_task: None,
            install_identity: (env.adapters.read_install_identity)().map_err(|e| format!("{e:#}")),
            env,
            page: Page::Home,
            iso_busy: false,
            usb_busy: false,
            iso_cancel: Arc::new(std::sync::atomic::AtomicBool::new(false)),
            system: SystemInfo::read(),
            elevated,
            atlas: atlas_state::read().map_err(|e| format!("{e:#}")),
            settings: loaded.settings,
            notice: loaded.problem.map(Notice::SettingsReset),
            accessibility: AccessibilityPreferences::read(),
            localization,
            recovering: false,
            release: ReleaseCheck::NotChecked,
            acquisition: Acquisition::Idle,
            acquisition_task: None,
            acquisition_epoch: 0,
            playbook: None,
            builtin_manifest,
            security: SecurityStatus::default(),
            security_read_at: None,
            security_watch: None,
            security_epoch: 0,
            security_confirmation: None,
            flow: Flow::default(),
            option_screen: 0,
            options,
            checks: Vec::new(),
            check_tasks: Vec::new(),
            acknowledged: BTreeSet::new(),
            checks_epoch: 0,
            preflight_problem: None,
            session: None,
            own_session: None,
            flow_id: None,
            store,
            attempt: InstallAttempt::default(),
            restart_timer: None,
            restart_epoch: 0,
            elevation_error: None,
            security_reminder: false,
            session_paths,
        };
        if cfg!(debug_assertions)
            && let Ok(preview) = std::env::var("ATLAS_PREPARATION_PREVIEW")
        {
            use crate::services::preparation::{Stage, State};
            model.preparation = match preview.as_str() {
                "busy" => State::Running { stage: Stage::StoreInstall, completed: 4, total: 12 },
                "complete" => State::Ready,
                "failed" => State::Failed,
                "reboot" => State::Reboot,
                "network" => State::Network,
                "previous-worker" => State::WaitingExternal,
                _ => State::Idle,
            };
            if matches!(preview.as_str(), "busy" | "complete" | "failed" | "reboot" | "previous-worker") {
                model.preparation_job = Some(std::env::temp_dir());
            }
            model.elevated = true;
            model.flow.resume(Step::Ready).ok();
            model.page = Page::Install;
            return model;
        }
        if model.env.check_updates {
            model.check_for_updates(cx);
        }
        model.begin_recovery(cx);
        model
    }

    pub fn driver_preference(&self) -> crate::services::preparation::Drivers {
        self.settings
            .drivers
            .or_else(crate::services::iso::staged_drivers)
            .unwrap_or_else(crate::services::preparation::existing_driver_policy)
    }

    pub fn set_drivers(&mut self, drivers: crate::services::preparation::Drivers, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.settings.drivers = Some(drivers);
        self.preparation = Default::default();
        self.persist(move |doc| doc.drivers = Some(drivers), |_, (), _| {}, cx);
        cx.notify();
    }

    pub fn prepare_windows(&mut self, cx: &mut Context<Self>) {
        if cfg!(debug_assertions) && std::env::var_os("ATLAS_PREPARATION_PREVIEW").is_some() {
            return;
        }
        use crate::services::preparation::{self, State};
        self.refresh_atlas_state();
        if self.install_eligibility_problem().is_some() {
            cx.notify();
            return;
        }
        if self.locked() || !self.elevated || !self.flow.active || self.flow.step != Step::Ready {
            return;
        }
        match preparation::recover_running(&self.env.paths.settings()) {
            Ok(Some(job)) => {
                self.follow_preparation(job.directory.clone(), Some(job), cx);
                return;
            }
            Err(error) => {
                log::error!("preparation recovery: {error:#}");
                self.preparation = State::Failed;
                cx.notify();
                return;
            }
            Ok(None) => {}
        }
        if !self.preparation_build_supported() {
            cx.notify();
            return;
        }
        let job = match preparation::new_job(&self.env.paths.settings()) {
            Ok(job) => job,
            Err(error) => {
                log::error!("preparation directory: {error:#}");
                self.preparation = State::Failed;
                cx.notify();
                return;
            }
        };
        self.follow_preparation(job, None, cx);
    }

    fn follow_preparation(
        &mut self,
        job: PathBuf,
        recovered: Option<crate::services::preparation::RunningJob>,
        cx: &mut Context<Self>,
    ) {
        use crate::services::preparation::{self, State};
        let drivers = self.driver_preference();
        self.preparation_job = Some(job.clone());
        self.preparation_cancel = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let cancel = self.preparation_cancel.clone();
        self.save_draft(cx);
        self.preparation = if recovered.as_ref().is_some_and(|job| !job.trusted) {
            State::WaitingExternal
        } else {
            State::Running { stage: Default::default(), completed: 0, total: 0 }
        };
        self.preparation_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded();
            let task = cx.background_executor().spawn(async move {
                let report = |event| {
                    let _ = tx.unbounded_send(event);
                };
                match recovered {
                    Some(recovered) => preparation::monitor(recovered, cancel, report),
                    None => preparation::run(&job, drivers, cancel, report),
                }
            });
            while let Some(event) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.preparation =
                        State::Running { stage: event.stage, completed: event.completed, total: event.total };
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                this.preparation = result.unwrap_or_else(|error| {
                    log::error!("Windows preparation: {error:#}");
                    State::Failed
                });
                this.run_checks(cx);
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    pub fn preparation_build_supported(&self) -> bool {
        self.checks.iter().any(|(id, result)| {
            *id == CheckId::SupportedBuild
                && result
                    .as_ref()
                    .is_some_and(|result| result.verdict == crate::services::requirements::Verdict::Pass)
        })
    }

    pub fn restart_preparation(&mut self, cx: &mut Context<Self>) {
        if cfg!(debug_assertions) && std::env::var_os("ATLAS_PREPARATION_PREVIEW").is_some() {
            return;
        }
        use crate::services::preparation::{self, State};
        if self.preparation != State::Reboot {
            return;
        }
        let Some(draft) = self.current_draft() else { return };
        let saved = self.store.transact(move |doc| doc.draft = Some(draft));
        self.preparation = State::Restarting;
        cx.spawn(async move |this, cx| {
            let saved = saved.await;
            let registration = if matches!(saved, Ok(Ok(()))) {
                cx.background_executor().spawn(async { preparation::register_resume() }).await
            } else {
                Err(anyhow::anyhow!("could not save preparation before restarting"))
            };
            this.update(cx, |this, cx| {
                let result = registration.and_then(|registration| {
                    let result = (this.env.adapters.schedule_restart)(&t!("shutdown-comment"));
                    if result.is_err()
                        && let Some(registration) = registration
                        && let Err(error) = preparation::undo_resume(&registration)
                    {
                        log::warn!("could not roll back preparation restart registration: {error:#}");
                    }
                    result
                });
                if let Err(error) = result {
                    log::error!("preparation restart: {error:#}");
                    this.preparation = State::Reboot;
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
        cx.notify();
    }

    // ----- Facts -----------------------------------------------------------

    pub fn installed(&self) -> Option<&AtlasState> {
        self.atlas.as_ref().ok().and_then(|state| state.as_ref())
    }

    pub fn installed_version(&self) -> Option<&str> {
        self.installed()
            .and_then(|state| state.installed_version.as_deref())
            .filter(|v| !v.trim().is_empty())
            .or({
                match &self.install_identity {
                    Ok(atlas_state::InstallIdentity::Installed(version)) => Some(version.as_str()),
                    _ => None,
                }
            })
    }

    pub fn install_eligibility_problem(&self) -> Option<String> {
        match &self.install_identity {
            Ok(identity) if identity.allows(self.manifest()) => None,
            Ok(atlas_state::InstallIdentity::Installed(version)) => {
                Some(t!("install-source-unsupported", source = version, target = &self.manifest().version))
            }
            _ => Some(t!("install-source-unknown")),
        }
    }

    /// An install is preparing or running; nothing that feeds it may change.
    pub fn locked(&self) -> bool {
        self.flow.locked() || self.iso_busy || self.preparation.busy()
    }

    /// The window shows the dedicated installing view: while an install is
    /// preparing or running, and after it succeeded until the user leaves.
    pub fn install_in_progress(&self) -> bool {
        self.flow.active
            && (self.flow.locked()
                || matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success()))
    }

    /// The manifest that describes the install: the downloaded playbook's, or
    /// the one built into this app until a package is available.
    pub fn manifest(&self) -> &Manifest {
        self.playbook.as_ref().map(|p| &p.manifest).unwrap_or(&self.builtin_manifest)
    }

    /// The label the user sees for an option: the package's text, translated
    /// when this app knows the option, falling back to its name.
    pub fn option_label(&self, name: &str) -> String {
        let text = self
            .manifest()
            .option_label(name)
            .or_else(|| self.builtin_manifest.option_label(name))
            .unwrap_or(name);
        describe::option_label(name, text)
    }

    /// A release newer than what is installed, if the check has run.
    pub fn update_available(&self) -> Option<&Release> {
        let release = self.release.release()?;
        match self.installed_version() {
            Some(installed) => {
                (releases::compare_versions(release.version(), installed).is_gt()).then_some(release)
            }
            None => None,
        }
    }

    /// Avoid replacing a loaded preview package with an older public release.
    pub fn can_download_latest(&self) -> bool {
        self.release.release().is_some_and(|release| {
            self.playbook.as_ref().is_none_or(|package| {
                !releases::compare_versions(release.version(), &package.manifest.version).is_lt()
            })
        })
    }

    /// Every check has reported, advisory ones included.
    pub fn checks_complete(&self) -> bool {
        !self.checks.is_empty() && self.checks.iter().all(|(_, result)| result.is_some())
    }

    /// Every required check has reported. Activation remains advisory.
    pub fn blocking_checks_complete(&self) -> bool {
        !self.checks.is_empty()
            && self.checks.iter().filter(|(id, _)| id.blocking()).all(|(_, result)| result.is_some())
    }

    /// Whether a check still stands in the way, honouring the user's
    /// acknowledgement of checks that could not run.
    pub fn check_blocks(&self, result: &CheckResult) -> bool {
        result.blocks_install() && !(result.needs_acknowledgement() && self.acknowledged.contains(&result.id))
    }

    pub fn checks_blocking(&self) -> bool {
        self.checks.iter().filter_map(|(_, result)| result.as_ref()).any(|result| self.check_blocks(result))
    }

    /// Whether the "Get ready" step is satisfied.
    pub fn ready_to_continue(&self) -> bool {
        self.install_eligibility_problem().is_none()
            && self.preparation.ready()
            && self.playbook.is_some()
            && !self.acquisition.is_busy()
            && self.blocking_checks_complete()
            && !self.checks_blocking()
    }

    /// Whether the Windows Security reading is recent enough to trust.
    pub fn security_fresh(&self) -> bool {
        self.security_read_at.is_some_and(|read| read.elapsed() < SECURITY_FRESH)
    }

    /// Whether the user's manual confirmation covers the current reading.
    pub fn security_acknowledged(&self) -> bool {
        self.security_confirmation == Some(self.security)
    }

    /// Whether Windows Security is verified off: every switch reads off, or
    /// every readable switch does and the user confirmed the rest by hand.
    pub fn security_ok(&self) -> bool {
        self.security_fresh() && security_verified(&self.security, self.security_confirmation, self.elevated)
    }

    pub fn can_install(&self) -> bool {
        self.flow.active
            && self.flow.step == Step::Install
            && !self.locked()
            && !matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success())
            && self.ready_to_continue()
            && self.elevated
            && self.security_ok()
    }

    /// Whether the Install step describes the recorded install (running, or
    /// succeeded) rather than what the current choices would run.
    pub fn showing_recorded_install(&self) -> bool {
        self.session.is_some()
            && (self.flow.locked()
                || matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success()))
    }

    /// The request the running (or completed) install was started with, or
    /// the one the current choices would produce. After a failed attempt the
    /// current choices win, so a retry reflects every edit made since.
    pub fn install_request(&self) -> Option<InstallRequest> {
        if let Some(session) = &self.session
            && self.showing_recorded_install()
        {
            return Some(session.request.clone());
        }
        let source = self.playbook.as_ref()?;
        Some(InstallRequest {
            playbook_dir: source.dir.clone(),
            options: self.effective_options(),
            restart: self.settings.restart_after_install,
            // Captured in the language showing when the install starts.
            restart_comment: self.settings.restart_after_install.then(|| t!("shutdown-comment")),
        })
    }

    /// The restart countdown, if one is running.
    pub fn restart_countdown(&self) -> Option<u32> {
        self.attempt.restart_countdown()
    }

    pub fn restart_progress(&self) -> Option<f32> {
        self.attempt.restart.map(|countdown| countdown.progress())
    }

    // ----- Navigation ------------------------------------------------------

    pub fn navigate(&mut self, page: Page, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        if self.iso_busy && page != Page::Iso {
            return;
        }
        self.page = page;
        self.sync_security_watch(cx);
        cx.notify();
    }

    fn after_step_change(&mut self, cx: &mut Context<Self>) {
        self.preflight_problem = None;
        // Leaving an unsuccessful result starts a new attempt; its record and
        // in-memory log go, the log file stays under Logs.
        if self.flow.run == RunState::Idle && self.session.is_some() {
            self.clear_session(cx);
        }
        if self.flow.step == Step::Ready {
            self.enter_ready(cx);
        }
        self.save_draft(cx);
        self.sync_security_watch(cx);
        cx.notify();
    }

    /// Revisits an earlier step (from the stepper or a "go to" button).
    pub fn set_step(&mut self, step: Step, cx: &mut Context<Self>) {
        if self.flow.go_to(step).is_ok() {
            self.option_screen = 0;
            self.after_step_change(cx);
        }
    }

    /// Jumps back to one screen of the Options step (from "Change" links).
    pub fn edit_options(&mut self, screen: usize, cx: &mut Context<Self>) {
        if self.flow.go_to(Step::Options).is_ok() {
            self.option_screen = screen.min(self.option_screens().len().saturating_sub(1));
            self.after_step_change(cx);
        }
    }

    /// Next screen of the Options step, or the next step.
    pub fn next_step(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        if self.flow.step == Step::Options && self.flow.may_edit() && self.flow.active {
            let screens = self.option_screens().len();
            if self.option_screen + 1 < screens {
                self.option_screen += 1;
                self.after_step_change(cx);
                return;
            }
        }
        let skip_saved_options = self.before_desktop
            && self.flow.step == Step::Ready
            && self.ready_to_continue()
            && crate::services::iso::validate_options(
                self.manifest(),
                &self.options.iter().cloned().collect::<Vec<_>>(),
            )
            .is_ok();
        if self.flow.advance().is_ok() {
            if skip_saved_options {
                let _ = self.flow.advance();
            }
            self.option_screen = 0;
            self.after_step_change(cx);
        }
    }

    /// Previous screen of the Options step, or the previous step. Coming
    /// back into Options from later lands on its last screen.
    pub fn previous_step(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        if self.flow.step == Step::Options
            && self.flow.may_edit()
            && self.flow.active
            && self.option_screen > 0
        {
            self.option_screen -= 1;
            self.after_step_change(cx);
            return;
        }
        if let Ok(step) = self.flow.back() {
            self.option_screen =
                if step == Step::Options { self.option_screens().len().saturating_sub(1) } else { 0 };
            self.after_step_change(cx);
        }
    }

    /// Opens the flow at a step given on the command line (review tooling).
    pub fn start_flow_at(&mut self, step: Step, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        if self.flow.resume(step).is_ok() {
            self.flow_id = Some(settings::new_flow_id());
            self.own_session = None;
            self.take_over_draft(cx);
            self.after_step_change(cx);
            self.navigate(Page::Install, cx);
        }
    }

    /// Starts the install flow. Everything in it needs administrator rights,
    /// so the elevation prompt comes first; the draft lets the elevated copy
    /// resume here instead of starting over.
    pub fn begin_install(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if self.install_eligibility_problem().is_some() {
            cx.notify();
            return;
        }
        if self.iso_busy || self.preparation.busy() {
            return;
        }
        if self.recovering || self.flow.begin().is_err() {
            return;
        }
        self.checks.clear();
        self.check_tasks.clear();
        self.acknowledged.clear();
        self.preflight_problem = None;
        self.elevation_error = None;
        self.security_reminder = false;
        // A new flow, begun on purpose, takes the draft over from whatever
        // flow held it; from here on only this window may change it.
        self.flow_id = Some(settings::new_flow_id());
        self.own_session = None;
        if self.elevated {
            self.take_over_draft(cx);
            self.enter_ready(cx);
            self.navigate(Page::Install, cx);
            return;
        }
        // The draft must be on disk before the elevated copy starts, so it
        // resumes here instead of starting over; the write is awaited, off
        // the window's thread.
        let Some(draft) = self.current_draft() else { return };
        let saved = self.store.transact(move |doc| doc.draft = Some(draft));
        cx.notify();
        cx.spawn(async move |this, cx| {
            let saved = saved.await;
            this.update(cx, |this, cx| {
                if !this.flow.active || this.locked() {
                    return;
                }
                match saved {
                    Ok(Ok(())) => match system::relaunch_elevated() {
                        Ok(()) => cx.defer(|cx| cx.quit()),
                        Err(error) => {
                            log::warn!("elevation declined: {error:#}");
                            this.flow.cancel().ok();
                            this.clear_draft(cx);
                            this.flow_id = None;
                            this.elevation_error = Some(ElevationProblem::Declined);
                        }
                    },
                    Ok(Err(error)) => {
                        this.flow.cancel().ok();
                        this.flow_id = None;
                        this.elevation_error = Some(ElevationProblem::DraftNotSaved { error });
                    }
                    Err(_) => {
                        this.flow.cancel().ok();
                        this.flow_id = None;
                        this.elevation_error = Some(ElevationProblem::DraftNotSaved {
                            error: "the settings writer stopped".into(),
                        });
                    }
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// Leaves the flow. Refused while an install is in progress. Whatever the
    /// flow was doing in the background (acquiring a package, running
    /// checks) is cancelled with it; a new flow starts from nothing.
    pub fn cancel_flow(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        let finished_ok = matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success());
        if self.flow.cancel().is_err() {
            return;
        }
        // Protection was switched off for an install that is not happening
        // (or that stopped early); remind the user to put it back.
        self.security_reminder = !finished_ok && self.security.any_off();
        self.security_confirmation = None;
        self.cancel_acquisition();
        self.check_tasks.clear();
        if finished_ok {
            // Done acknowledges a result; it abandons nothing. The draft that
            // launched this install is cleared (again, if completion already
            // did it) before the record goes, and a draft some other flow
            // saved meanwhile is picked up, as it would be at the next start.
            self.flow_id = None;
            self.navigate(Page::Home, cx);
            let picked_up = |this: &mut Self, remaining: Option<InstallDraft>, cx: &mut Context<Self>| {
                this.settings.draft = remaining;
                if !this.flow.active {
                    this.resume_draft(cx);
                }
            };
            match self.forget_session() {
                Some(record) => self.finalize_completed(record, picked_up, cx),
                None => self.persist(|doc| doc.draft.clone(), picked_up, cx),
            }
        } else {
            self.clear_session(cx);
            self.clear_draft(cx);
            self.flow_id = None;
            self.navigate(Page::Home, cx);
        }
    }

    pub fn dismiss_notice(&mut self, cx: &mut Context<Self>) {
        self.notice = None;
        cx.notify();
    }

    pub fn dismiss_security_reminder(&mut self, cx: &mut Context<Self>) {
        self.security_reminder = false;
        cx.notify();
    }

    fn enter_ready(&mut self, cx: &mut Context<Self>) {
        if self.checks.is_empty() {
            self.run_checks(cx);
        }
        if self.playbook.is_none()
            && !self.acquisition.is_busy()
            && !matches!(self.acquisition, Acquisition::Failed(_))
        {
            self.acquire_latest(cx);
        }
    }

    // ----- Draft and session ----------------------------------------------

    /// This flow's draft as it stands, or `None` outside a flow.
    fn current_draft(&self) -> Option<InstallDraft> {
        if !self.flow.active {
            return None;
        }
        Some(InstallDraft {
            step: self.flow.step.name().to_owned(),
            options: self.options.iter().cloned().collect(),
            playbook_dir: self.playbook.as_ref().map(|p| p.dir.clone()),
            option_screen: self.option_screen,
            session: self.own_session.clone(),
            flow: self.flow_id.clone(),
        })
    }

    /// Runs a settings transaction on the store and, once it has been
    /// written, hands its answer to `then` on the window's thread. A
    /// transaction that fails is reported on Home; nothing waits here.
    fn persist<R: Send + 'static>(
        &mut self,
        change: impl FnOnce(&mut AppSettings) -> R + Send + 'static,
        then: impl FnOnce(&mut Self, R, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        let answer = self.store.transact(change);
        cx.spawn(async move |this, cx| {
            let answer = answer.await;
            this.update(cx, |this, cx| match answer {
                Ok(Ok(answer)) => then(this, answer, cx),
                Ok(Err(error)) => this.settings_failed(error, cx),
                Err(_) => this.settings_failed("the settings writer stopped".into(), cx),
            })
            .ok();
        })
        .detach();
    }

    fn settings_failed(&mut self, error: String, cx: &mut Context<Self>) {
        log::warn!("could not save settings: {error}");
        if self.notice.is_none() {
            self.notice = Some(Notice::SettingsNotSaved { error });
        }
        cx.notify();
    }

    /// Saves this flow's draft if the draft on disk is still this flow's (or
    /// nobody's). A newer draft another window began is left alone, and this
    /// window's progress is simply no longer persisted.
    fn save_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.current_draft() else { return };
        self.settings.draft = Some(draft.clone());
        let flow = draft.flow.clone();
        self.persist(
            move |doc| {
                if draft_owned_by(&doc.draft, flow.as_deref()) {
                    doc.draft = Some(draft);
                    true
                } else {
                    false
                }
            },
            |_, written, _| {
                if !written {
                    log::warn!(
                        "another window has taken over the install flow; this flow is no longer saved"
                    );
                }
            },
            cx,
        );
    }

    /// Writes this flow's draft whatever is on disk: a flow the user has just
    /// begun replaces any earlier one.
    fn take_over_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.current_draft() else { return };
        self.settings.draft = Some(draft.clone());
        self.persist(move |doc| doc.draft = Some(draft), |_, (), _| {}, cx);
    }

    /// Abandons this flow's draft: the one on disk goes only if it is still
    /// this flow's (a newer draft another window saved is not this window's
    /// to remove).
    fn clear_draft(&mut self, cx: &mut Context<Self>) {
        self.settings.draft = None;
        let flow = self.flow_id.clone();
        self.persist(
            move |doc| {
                if doc.draft.is_some() && draft_owned_by(&doc.draft, flow.as_deref()) {
                    doc.draft = None;
                }
            },
            |_, (), _| {},
            cx,
        );
    }

    /// Clears the draft that launched install `record`, wherever it is now
    /// on disk, and no other; `then` receives whatever draft remains.
    fn clear_draft_of(
        &mut self,
        record: &SessionRecord,
        then: impl FnOnce(&mut Self, Option<InstallDraft>, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        if self.settings.draft.as_ref().is_some_and(|draft| draft_launched(draft, record)) {
            self.settings.draft = None;
        }
        let record = record.clone();
        self.persist(
            move |doc| {
                if doc.draft.as_ref().is_some_and(|draft| draft_launched(draft, &record)) {
                    doc.draft = None;
                }
                doc.draft.clone()
            },
            then,
            cx,
        );
    }

    /// Drops this window's view of its session and releases the shared
    /// record (see [`AppModel::release_record`]).
    fn clear_session(&mut self, cx: &mut Context<Self>) {
        if let Some(record) = self.forget_session() {
            self.release_record(record.id, cx);
        }
    }

    /// Drops this window's view of its session without touching the shared
    /// record, and hands the record back for whoever finalises it.
    fn forget_session(&mut self) -> Option<SessionRecord> {
        let record = self.session.take();
        self.own_session = None;
        self.restart_timer = None;
        self.attempt.reset();
        record
    }

    /// Removes the shared record if it still belongs to session `id`; a newer
    /// install started from another window keeps its record. The removal
    /// takes the launch lock, so it runs on a worker rather than the
    /// window's thread.
    fn release_record(&self, id: String, cx: &mut Context<Self>) {
        let paths = self.session_paths.clone();
        cx.background_executor()
            .spawn(async move {
                if let Err(error) = session::release(&paths, &id) {
                    log::warn!("could not release the install session: {error:#}");
                }
            })
            .detach();
    }

    /// Closes out a completed install in order: first the draft that
    /// launched it is cleared (a transaction on the store), and only once
    /// that has been written is the record released. If the transaction
    /// fails the record stays, the failure is reported, and the next window
    /// (or the next Done) finishes the job; the durable state is never left
    /// with a launching draft and no record to explain it. `then` runs after
    /// the release with whatever draft remains.
    fn finalize_completed(
        &mut self,
        record: SessionRecord,
        then: impl FnOnce(&mut Self, Option<InstallDraft>, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        let id = record.id.clone();
        self.clear_draft_of(
            &record,
            move |this, remaining, cx| {
                this.release_record(id, cx);
                then(this, remaining, cx);
            },
            cx,
        );
    }

    fn resume_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.settings.draft.clone() else { return };
        let Some(step) = Step::parse(&draft.step) else {
            self.flow_id = draft.flow.clone();
            self.clear_draft(cx);
            self.flow_id = None;
            return;
        };
        // A draft from before flows had identities is adopted by this window.
        self.flow_id = Some(draft.flow.clone().unwrap_or_else(settings::new_flow_id));
        self.own_session = draft.session.clone();
        if let Some(dir) = draft.playbook_dir.filter(|dir| playbook::is_extracted(dir)) {
            match playbook::read_manifest(&dir) {
                Ok(manifest) => {
                    self.playbook = Some(PlaybookSource { dir, manifest, origin: Origin::Unpacked });
                }
                Err(error) => log::warn!("could not resume the unpacked playbook: {error:#}"),
            }
        }
        if !draft.options.is_empty() {
            self.options = draft.options.into_iter().collect();
        }
        self.option_screen = draft.option_screen;
        if self.flow.resume(step).is_ok() {
            self.enter_ready(cx);
            self.navigate(Page::Install, cx);
        }
    }

    /// Finds out whether an earlier instance of the app left an install
    /// running or finished. The shared record is read under the launch lock
    /// on a worker; the window waits a moment for the answer so the first
    /// frame is usually right, and otherwise finishes recovering in the
    /// background while offering nothing that could start a second install.
    fn begin_recovery(&mut self, cx: &mut Context<Self>) {
        let paths = self.session_paths.clone();
        let settings = self.env.paths.settings();
        let task = cx.background_executor().spawn(async move {
            (inspect_startup(&paths), crate::services::preparation::recover_running(&settings))
        });
        match cx.foreground_executor().block_with_timeout(STARTUP_WAIT, task) {
            Ok((found, preparation)) => self.finish_recovery(found, preparation, cx),
            Err(task) => {
                self.recovering = true;
                cx.spawn(async move |this, cx| {
                    let (found, preparation) = task.await;
                    this.update(cx, |this, cx| this.finish_recovery(found, preparation, cx)).ok();
                })
                .detach();
            }
        }
    }

    fn finish_recovery(
        &mut self,
        found: StartupInspection,
        preparation: anyhow::Result<Option<crate::services::preparation::RunningJob>>,
        cx: &mut Context<Self>,
    ) {
        self.recovering = false;
        match found {
            StartupInspection::None => {}
            StartupInspection::Unreadable(problem) => {
                // Ownership is unknown; the record stays and installs are
                // refused until it can be read. The user is told where it is.
                self.notice = Some(Notice::SessionUnreadable {
                    error: problem,
                    record: self.session_paths.record.clone(),
                });
            }
            StartupInspection::Live(record) => {
                self.attach_session(record, false, cx);
                return;
            }
            StartupInspection::Ended(record) => {
                if record.exit_code() == Some(0) && system::booted_since(&record.started_at) {
                    // The install finished and Windows has restarted since:
                    // the payload's own completion window covers it, and
                    // this record and its draft describe nothing current.
                    // The draft goes first and the record only after it;
                    // whatever other draft remains resumes once that is done.
                    self.refresh_atlas_state();
                    self.finalize_completed(
                        record,
                        |this, remaining, cx| {
                            this.settings.draft = remaining;
                            if !this.flow.active {
                                this.resume_draft(cx);
                            }
                            cx.notify();
                        },
                        cx,
                    );
                    cx.notify();
                    return;
                } else {
                    // Finished while no window was open: show the result
                    // (with its log) until the user leaves it, and let the
                    // usual completion handling arbitrate the draft.
                    self.attach_session(record, true, cx);
                    return;
                }
            }
        }
        // A flow started meanwhile (a command-line step) keeps precedence
        // over the draft; otherwise the draft resumes where the user was.
        if !self.flow.active {
            self.resume_draft(cx);
        }
        match preparation {
            Ok(Some(job)) => {
                if !self.flow.active {
                    self.flow.resume(Step::Ready).ok();
                }
                self.flow.step = Step::Ready;
                self.page = Page::Install;
                self.follow_preparation(job.directory.clone(), Some(job), cx);
            }
            Err(error) => log::warn!("could not inspect preparation recovery: {error:#}"),
            Ok(None) => {}
        }
        cx.notify();
    }

    /// Follows a recorded install: its package, choices and output. `ended`
    /// says the process was already gone when the record was read.
    fn attach_session(&mut self, record: SessionRecord, ended: bool, cx: &mut Context<Self>) {
        if self.flow.attach_running().is_err() {
            return;
        }
        // Recovery bypasses resume_draft. Keep the launching flow's identity
        // so a failed install can save edits and reserve its retry. A newer,
        // unrelated draft must still be protected from this window.
        if let Some(draft) = self.settings.draft.as_ref().filter(|draft| draft_launched(draft, &record)) {
            self.flow_id = Some(draft.flow.clone().unwrap_or_else(settings::new_flow_id));
            self.own_session = Some(record.id.clone());
        }
        if playbook::is_extracted(&record.request.playbook_dir)
            && let Ok(manifest) = playbook::read_manifest(&record.request.playbook_dir)
        {
            self.playbook = Some(PlaybookSource {
                dir: record.request.playbook_dir.clone(),
                manifest,
                origin: Origin::Unpacked,
            });
        }
        self.options = record.request.options.iter().cloned().collect();
        let events = installer::reattach(&record);
        self.restart_timer = None;
        self.attempt.reset();
        self.attempt.recovered = ended;
        self.session = Some(record);
        self.pump_install_events(events, cx);
        self.navigate(Page::Install, cx);
    }

    // ----- Options ---------------------------------------------------------

    /// The Options step, one decision per screen: every required choice
    /// (radio page) gets its own screen, phrased as a question, and the
    /// optional extras share the last one.
    pub fn option_screens(&self) -> Vec<OptionScreen> {
        let manifest = self.manifest();
        let mut screens = Vec::new();
        let mut extras = Vec::new();
        for (index, page) in manifest.pages.iter().enumerate() {
            if page.kind == PageKind::Radio && page.depends_on.is_none() {
                screens.push(OptionScreen {
                    kind: ScreenKind::of_page(page),
                    pages: vec![index],
                    required: true,
                });
            } else {
                extras.push(index);
            }
        }
        if !extras.is_empty() {
            screens.push(OptionScreen { kind: ScreenKind::Extras, pages: extras, required: false });
        }
        screens
    }

    /// The screen that is showing, clamped to what the manifest offers.
    pub fn current_option_screen(&self) -> usize {
        self.option_screen.min(self.option_screens().len().saturating_sub(1))
    }

    pub fn choose_option(&mut self, page_index: usize, name: &str, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        let Some(page) = self.manifest().pages.get(page_index) else { return };
        match page.kind {
            PageKind::Radio => {
                let siblings: Vec<String> = page.options.iter().map(|o| o.name.clone()).collect();
                for sibling in siblings {
                    self.options.remove(&sibling);
                }
                self.options.insert(name.to_owned());
            }
            PageKind::Checkbox => {
                if !self.options.remove(name) {
                    self.options.insert(name.to_owned());
                }
            }
        }
        self.save_draft(cx);
        cx.notify();
    }

    /// Option names to pass to the installer, honouring `DependsOn` pages.
    pub fn effective_options(&self) -> Vec<String> {
        let manifest = self.manifest();
        let mut names = Vec::new();
        for page in &manifest.pages {
            if page.depends_on.as_ref().is_some_and(|dependency| !self.options.contains(dependency)) {
                continue;
            }
            for option in &page.options {
                if self.options.contains(&option.name) {
                    names.push(option.name.clone());
                }
            }
        }
        names
    }

    // ----- Releases --------------------------------------------------------

    pub fn check_for_updates(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if matches!(self.release, ReleaseCheck::Checking) {
            return;
        }
        self.release = ReleaseCheck::Checking;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result = cx.background_executor().spawn(async { releases::fetch_latest() }).await;
            this.update(cx, |this, cx| {
                this.release = match result {
                    Ok(release) => ReleaseCheck::Ready { release },
                    Err(error) => {
                        log::warn!("release check failed: {error:#}");
                        ReleaseCheck::Failed
                    }
                };
                // The flow may have started before the release was known.
                if this.flow.active && this.flow.step == Step::Ready && this.playbook.is_none() {
                    this.acquire_latest(cx);
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// Downloads the latest playbook (or reuses a verified cached copy) and
    /// unpacks it so it can be installed.
    pub fn acquire_latest(&mut self, cx: &mut Context<Self>) {
        if self.locked() || self.acquisition.is_busy() || !self.flow.may_edit() || !self.can_download_latest()
        {
            return;
        }
        let Some(release) = self.release.release().cloned() else {
            // Not an error yet: the release check is still running or failed,
            // and the Ready step shows that state on its own.
            return;
        };
        let Some(asset) = release.playbook_asset().cloned() else {
            self.acquisition = Acquisition::Failed(AcquireProblem::NoPlaybookAsset {
                version: release.version().to_owned(),
            });
            cx.notify();
            return;
        };
        let version = release.version().to_owned();
        let downloads = self.env.paths.downloads();
        let playbooks = self.env.paths.playbooks();
        self.acquisition = Acquisition::Downloading { received: 0, total: asset.size };
        self.acquisition_epoch += 1;
        let epoch = self.acquisition_epoch;
        cx.notify();

        self.acquisition_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded::<Progress>();
            let task = cx.background_executor().spawn(async move {
                let path = match releases::cached_in(&downloads, &asset) {
                    Some(path) => path,
                    None => {
                        let mut last_percent = u64::MAX;
                        releases::download_into(&downloads, &asset, |received, total| {
                            let percent = received * 100 / total.max(1);
                            if percent != last_percent {
                                last_percent = percent;
                                let _ = tx.unbounded_send(Progress::Download(received, total));
                            }
                        })?
                    }
                };
                let mut last_percent = usize::MAX;
                playbook::extract_into(&path, &playbooks, |done, total| {
                    let percent = done * 100 / total.max(1);
                    if percent != last_percent {
                        last_percent = percent;
                        let _ = tx.unbounded_send(Progress::Extract(done, total));
                    }
                })
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    if this.acquisition_epoch != epoch {
                        return;
                    }
                    this.acquisition = match progress {
                        Progress::Download(received, total) => Acquisition::Downloading { received, total },
                        Progress::Extract(done, total) => Acquisition::Extracting { done, total },
                    };
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                this.finish_acquisition(
                    epoch,
                    result.map(|(dir, manifest)| (dir, manifest, Origin::Release(version))),
                    cx,
                );
            })
            .ok();
        }));
    }

    /// Lets the user pick an .apbx they already have.
    pub fn choose_local_playbook(&mut self, cx: &mut Context<Self>) {
        if self.locked() || self.acquisition.is_busy() || !self.flow.may_edit() {
            return;
        }
        let receiver = cx.prompt_for_paths(PathPromptOptions {
            files: true,
            directories: false,
            multiple: false,
            prompt: Some(t!("file-dialog-open-playbook").into()),
        });
        cx.spawn(async move |this, cx| {
            let Ok(Ok(Some(paths))) = receiver.await else { return };
            let Some(path) = paths.into_iter().next() else { return };
            this.update(cx, |this, cx| this.load_playbook_file(path, cx)).ok();
        })
        .detach();
    }

    /// Unpacks an .apbx the user already has (file dialog, `--playbook`, or
    /// "Open with" on the package).
    pub fn load_playbook_file(&mut self, path: PathBuf, cx: &mut Context<Self>) {
        if self.locked() || self.acquisition.is_busy() || !self.flow.may_edit() {
            return;
        }
        let playbooks = self.env.paths.playbooks();
        self.acquisition = Acquisition::Extracting { done: 0, total: 0 };
        self.acquisition_epoch += 1;
        let epoch = self.acquisition_epoch;
        cx.notify();
        self.acquisition_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded::<Progress>();
            let source = path.clone();
            let task = cx.background_executor().spawn(async move {
                let mut last_percent = usize::MAX;
                playbook::extract_into(&source, &playbooks, |done, total| {
                    let percent = done * 100 / total.max(1);
                    if percent != last_percent {
                        last_percent = percent;
                        let _ = tx.unbounded_send(Progress::Extract(done, total));
                    }
                })
            });
            while let Some(Progress::Extract(done, total)) = rx.next().await {
                this.update(cx, |this, cx| {
                    if this.acquisition_epoch != epoch {
                        return;
                    }
                    this.acquisition = Acquisition::Extracting { done, total };
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                this.finish_acquisition(
                    epoch,
                    result.map(|(dir, manifest)| (dir, manifest, Origin::LocalFile(path))),
                    cx,
                );
            })
            .ok();
        }));
    }

    /// Stops an acquisition and forgets it. The blocking transfer or
    /// extraction already under way on a worker runs to its end on its own;
    /// its result is never applied.
    fn cancel_acquisition(&mut self) {
        self.acquisition_task = None;
        self.acquisition_epoch += 1;
        if self.acquisition.is_busy() {
            self.acquisition = Acquisition::Idle;
        }
    }

    fn finish_acquisition(
        &mut self,
        epoch: u64,
        result: anyhow::Result<(PathBuf, Manifest, Origin)>,
        cx: &mut Context<Self>,
    ) {
        if epoch != self.acquisition_epoch {
            return;
        }
        self.acquisition_task = None;
        match result {
            Ok((dir, manifest, origin)) => {
                // Keep the user's choices that still exist; fill the rest with defaults.
                let valid: BTreeSet<String> =
                    manifest.pages.iter().flat_map(|p| p.options.iter().map(|o| o.name.clone())).collect();
                let mut options: BTreeSet<String> =
                    self.options.iter().filter(|o| valid.contains(*o)).cloned().collect();
                for page in &manifest.pages {
                    let has_choice = page.options.iter().any(|o| options.contains(&o.name));
                    if page.kind == PageKind::Radio
                        && !has_choice
                        && let Some(default) = page.options.iter().find(|o| o.default)
                    {
                        options.insert(default.name.clone());
                    }
                }
                self.options = options;
                if let Some(saved) = self.iso_initial_options.take() {
                    if crate::services::iso::validate_options(&manifest, &saved).is_ok() {
                        self.options = saved.into_iter().collect();
                    } else {
                        log::warn!(
                            "The staged Atlas options do not match the selected package; using the normal options flow."
                        );
                    }
                }
                self.playbook = Some(PlaybookSource { dir, manifest, origin });
                self.acquisition = Acquisition::Idle;
                // Supported builds may differ between playbooks.
                if self.flow.active {
                    self.run_checks(cx);
                } else {
                    self.checks.clear();
                    self.check_tasks.clear();
                }
                self.save_draft(cx);
            }
            Err(error) => {
                let problem = match error.downcast_ref::<playbook::Unsupported>() {
                    Some(unsupported) => AcquireProblem::Unsupported { version: unsupported.version.clone() },
                    None => AcquireProblem::Other { error: format!("{error:#}") },
                };
                self.acquisition = Acquisition::Failed(problem);
            }
        }
        cx.notify();
    }

    // ----- Windows Security ------------------------------------------------

    /// The watcher runs only while a reading can matter: on the Security and
    /// Install steps of an idle flow. A running or finished install reads
    /// nothing from it (the final preflight takes its own reading), so it
    /// stops rather than polling and redrawing for no one.
    fn sync_security_watch(&mut self, cx: &mut Context<Self>) {
        let finished_ok = matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success());
        let wanted = self.page == Page::Install
            && matches!(self.flow.step, Step::Security | Step::Install)
            && !self.flow.locked()
            && !finished_ok;
        if wanted == self.security_watch.is_some() {
            return;
        }
        self.security_epoch += 1;
        // Whatever was read before the watcher paused is stale now.
        self.security_read_at = None;
        if !wanted {
            self.security_watch = None;
            return;
        }
        let epoch = self.security_epoch;
        let read = self.env.adapters.read_security.clone();
        self.security_watch = Some(cx.spawn(async move |this, cx| {
            let mut first = true;
            loop {
                let read = read.clone();
                let status = cx.background_executor().spawn(async move { read() }).await;
                let keep_going = this
                    .update(cx, |this, cx| {
                        if this.security_epoch != epoch {
                            return false;
                        }
                        let changed = this.observe_security(status);
                        // The first reading turns "Reading" into a verdict;
                        // after that only a different reading is news.
                        if changed || first {
                            cx.notify();
                        }
                        first = false;
                        true
                    })
                    .unwrap_or(false);
                if !keep_going {
                    break;
                }
                cx.background_executor().timer(Duration::from_millis(1000)).await;
            }
        }));
    }

    /// Records a reading. Returns whether it differs from the last one. A
    /// confirmation given for the previous reading no longer matches, so a
    /// change in what can be read invalidates it by construction.
    fn observe_security(&mut self, status: SecurityStatus) -> bool {
        let changed = self.security != status;
        self.security = status;
        self.security_read_at = Some(Instant::now());
        changed
    }

    pub fn acknowledge_security(&mut self, confirmed: bool, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.security_confirmation = confirmed.then_some(self.security);
        cx.notify();
    }

    // ----- System checks ---------------------------------------------------

    /// Runs every check again. The previous batch's tasks are dropped and
    /// their late results ignored; a provider still busy on a worker is
    /// joined by the new batch rather than duplicated (see
    /// `requirements::bounded`).
    pub fn run_checks(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.checks_epoch += 1;
        let epoch = self.checks_epoch;
        self.checks = CheckId::ALL.iter().map(|id| (*id, None)).collect();
        self.acknowledged.clear();
        self.preflight_problem = None;
        let context = Arc::new(CheckContext {
            system: self.system.clone(),
            supported_builds: self.manifest().supported_builds.clone(),
        });
        let run = self.env.adapters.run_check.clone();
        let elevated = self.env.adapters.is_elevated.clone();
        self.check_tasks = CheckId::ALL
            .iter()
            .map(|&id| {
                let context = context.clone();
                let run = run.clone();
                let elevated = elevated.clone();
                cx.spawn(async move |this, cx| {
                    let result = cx.background_executor().spawn(async move { run(id, &context) }).await;
                    this.update(cx, |this, cx| {
                        if this.checks_epoch != epoch {
                            return;
                        }
                        if let Some(slot) = this.checks.iter_mut().find(|(check, _)| *check == id) {
                            slot.1 = Some(result);
                        }
                        if id == CheckId::Administrator {
                            this.elevated = elevated();
                        }
                        cx.notify();
                    })
                    .ok();
                })
            })
            .collect();
        cx.notify();
    }

    pub fn acknowledge_check(&mut self, id: CheckId, confirmed: bool, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        if confirmed {
            self.acknowledged.insert(id);
        } else {
            self.acknowledged.remove(&id);
        }
        cx.notify();
    }

    // ----- Install ---------------------------------------------------------

    /// Starts the install: the mandatory checks and the Windows Security
    /// switches are read again first, and the child only starts if they still
    /// pass. The request is captured now and cannot change afterwards.
    ///
    /// The decision is made on the window's thread from the fresh readings;
    /// the launch itself (which takes the cross-process lock and spawns the
    /// child) runs on a worker while the flow stays locked in `Preparing`.
    pub fn start_install(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if !self.can_install() {
            cx.notify();
            return;
        }
        let Some(request) = self.install_request() else { return };
        if let Err(error) = installer::validate_options(&request.options) {
            self.preflight_problem = Some(Preflight::InvalidOptions { error: format!("{error:#}") });
            cx.notify();
            return;
        }
        if self.flow.start_preparing().is_err() {
            return;
        }
        self.preflight_problem = None;
        self.clear_session(cx);
        self.sync_security_watch(cx);
        cx.notify();

        let context = Arc::new(CheckContext {
            system: self.system.clone(),
            supported_builds: self.manifest().supported_builds.clone(),
        });
        let run = self.env.adapters.run_check.clone();
        let read_security = self.env.adapters.read_security.clone();
        let is_elevated = self.env.adapters.is_elevated.clone();
        let paths = self.session_paths.clone();
        let store = self.store.clone();
        cx.spawn(async move |this, cx| {
            let (results, security, elevated) = cx
                .background_executor()
                .spawn(async move {
                    let results: Vec<CheckResult> =
                        CheckId::ALL.iter().filter(|id| id.blocking()).map(|id| run(*id, &context)).collect();
                    (results, read_security(), is_elevated())
                })
                .await;
            let go = this
                .update(cx, |this, cx| {
                    if this.flow.run != RunState::Preparing {
                        return false;
                    }
                    this.observe_security(security);
                    this.elevated = this.elevated && elevated;
                    for result in &results {
                        if let Some(slot) = this.checks.iter_mut().find(|(id, _)| *id == result.id) {
                            slot.1 = Some(result.clone());
                        }
                    }
                    match preflight_decision(
                        &results,
                        &this.acknowledged,
                        &this.security,
                        this.security_confirmation,
                        this.elevated,
                    ) {
                        Ok(()) => true,
                        Err(problem) => {
                            this.flow.stop_preparing().ok();
                            this.preflight_problem = Some(problem);
                            this.sync_security_watch(cx);
                            cx.notify();
                            false
                        }
                    }
                })
                .unwrap_or(false);
            if !go {
                return;
            }
            // The draft names the install it is about to launch before the
            // child can run, so a window that closes (or crashes) during the
            // handoff leaves a durable record and a draft that agree.
            let id = session::new_id();
            let Some(draft) = this
                .update(cx, |this, _| {
                    this.own_session = Some(id.clone());
                    this.current_draft()
                })
                .ok()
                .flatten()
            else {
                return;
            };
            let flow = draft.flow.clone();
            let reserved = store
                .transact(move |doc| {
                    if draft_owned_by(&doc.draft, flow.as_deref()) {
                        doc.draft = Some(draft);
                        true
                    } else {
                        false
                    }
                })
                .await;
            let associated = this
                .update(cx, |this, cx| {
                    let refusal = match reserved {
                        Ok(Ok(true)) => None,
                        Ok(Ok(false)) => {
                            Some("another Atlas window has taken over this install flow".to_owned())
                        }
                        Ok(Err(error)) => Some(error),
                        Err(_) => Some("the settings writer stopped".to_owned()),
                    };
                    match refusal {
                        None => this.flow.run == RunState::Preparing,
                        Some(error) => {
                            this.own_session = None;
                            this.flow.stop_preparing().ok();
                            this.preflight_problem = Some(Preflight::Refused {
                                error: format!("the install could not be recorded in the draft: {error}"),
                            });
                            this.sync_security_watch(cx);
                            cx.notify();
                            false
                        }
                    }
                })
                .unwrap_or(false);
            if !associated {
                return;
            }
            let launch =
                cx.background_executor().spawn(async move { installer::start_as(id, request, &paths) }).await;
            let started = launch.as_ref().ok().map(|(record, _)| record.id.clone());
            if this.update(cx, |this, cx| this.finish_launch(launch, cx)).is_err()
                && let Some(id) = started
            {
                // The window went away between the decision and the launch.
                // The child runs under its durable record; the next window
                // finds it there. Nothing is lost, only unwatched.
                log::warn!(
                    "the window closed while install {id} was starting; it continues under its record"
                );
            }
        })
        .detach();
    }

    fn finish_launch(
        &mut self,
        launch: anyhow::Result<(SessionRecord, futures::channel::mpsc::Receiver<InstallEvent>)>,
        cx: &mut Context<Self>,
    ) {
        if self.flow.run != RunState::Preparing {
            return;
        }
        match launch {
            Ok((record, events)) => {
                // So the payload can open this app again after the restart.
                if let Err(error) = session::record_launcher(&self.session_paths) {
                    log::warn!("could not record the app path for the completion window: {error:#}");
                }
                #[cfg(not(test))]
                if let Err(error) = session::register_completion() {
                    log::warn!("could not schedule the completion window: {error:#}");
                }
                self.flow.start_running().ok();
                self.restart_timer = None;
                self.attempt.reset();
                self.session = Some(record);
                self.pump_install_events(events, cx);
            }
            Err(error) => match error.downcast::<installer::AlreadyRunning>() {
                // Another instance's install is running (the launch lock saw
                // it first); follow that one instead. The id this window
                // reserved launched nothing.
                Ok(installer::AlreadyRunning(existing)) => {
                    self.own_session = None;
                    self.save_draft(cx);
                    self.flow.start_running().ok();
                    self.restart_timer = None;
                    self.attempt.reset();
                    let events = installer::reattach(&existing);
                    self.session = Some(existing);
                    self.pump_install_events(events, cx);
                }
                // The protocol guarantees nothing ran: back to idle with the
                // reason, not a fake "aborted" result.
                Err(error) => {
                    self.own_session = None;
                    self.save_draft(cx);
                    self.flow.stop_preparing().ok();
                    self.preflight_problem = Some(if error.downcast_ref::<session::Busy>().is_some() {
                        Preflight::Busy
                    } else if let Some(unreadable) = error.downcast_ref::<installer::RecordUnreadable>() {
                        Preflight::RecordUnreadable { error: unreadable.0.clone() }
                    } else {
                        Preflight::Refused { error: format!("{error:#}") }
                    });
                    self.sync_security_watch(cx);
                }
            },
        }
        cx.notify();
    }

    fn pump_install_events(
        &mut self,
        mut events: futures::channel::mpsc::Receiver<InstallEvent>,
        cx: &mut Context<Self>,
    ) {
        cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(Duration::from_secs(1)).await;
                let running = this
                    .update(cx, |this, cx| {
                        cx.notify();
                        matches!(this.flow.run, RunState::Running)
                    })
                    .unwrap_or(false);
                if !running {
                    break;
                }
            }
        })
        .detach();
        cx.spawn(async move |this, cx| {
            while let Some(event) = events.next().await {
                let alive = this
                    .update(cx, |this, cx| {
                        match event {
                            InstallEvent::Lines(lines) => this.push_log(lines),
                            InstallEvent::OutputProblem(problem) => {
                                this.attempt.output_problem = Some(problem)
                            }
                            InstallEvent::Finished(outcome) => this.finish_install(outcome, cx),
                        }
                        cx.notify();
                    })
                    .is_ok();
                if !alive {
                    break;
                }
            }
        })
        .detach();
    }

    /// The child ended. A success ends the flow and, when this window saw it
    /// end, mirrors the front door's restart countdown. Anything else keeps
    /// the user on the Install step with the result, the log and a retry
    /// that is ready to use: the readiness checks the retry depends on are
    /// started here if this window never ran them (an install found after
    /// reopening the app).
    fn finish_install(&mut self, outcome: InstallOutcome, cx: &mut Context<Self>) {
        if self.flow.finish(outcome).is_err() {
            return;
        }
        self.refresh_atlas_state();
        if outcome.is_success() {
            if let Some(record) = self.session.clone() {
                self.clear_draft_of(&record, |_, _, _| {}, cx);
            }
            let restart = self.session.as_ref().is_some_and(|s| s.request.restart);
            if restart && !self.attempt.recovered {
                self.begin_restart_countdown(cx);
            }
        } else if self.checks.is_empty() {
            self.run_checks(cx);
        }
        self.sync_security_watch(cx);
    }

    /// Atlas owns the countdown; Windows receives an immediate restart only at expiry. The timer belongs to
    /// this attempt: replacing or cancelling the countdown drops it, and a
    /// generation check keeps a timer that already woke from touching a
    /// newer countdown.
    fn begin_restart_countdown(&mut self, cx: &mut Context<Self>) {
        let timing = self.env.restart;
        self.restart_epoch += 1;
        let epoch = self.restart_epoch;
        self.attempt.restart =
            Some(RestartCountdown { deadline: Instant::now() + timing.countdown, total: timing.countdown });
        self.attempt.restart_cancelled = false;
        self.restart_timer = Some(cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(timing.tick).await;
                let tick = this
                    .update(cx, |this, cx| {
                        if this.restart_epoch != epoch {
                            return Tick::Stop;
                        }
                        cx.notify();
                        match this.attempt.restart {
                            Some(countdown) if Instant::now() >= countdown.deadline => Tick::Expired,
                            Some(_) => Tick::Continue,
                            None => Tick::Stop,
                        }
                    })
                    .unwrap_or(Tick::Stop);
                match tick {
                    Tick::Continue => continue,
                    Tick::Stop => return,
                    Tick::Expired => break,
                }
            }
            let requested = this
                .update(cx, |this, cx| {
                    if this.restart_epoch != epoch || this.attempt.restart.is_none() {
                        return false;
                    }
                    if let Err(error) = (this.env.adapters.schedule_restart)(&t!("shutdown-comment")) {
                        this.attempt.restart = None;
                        this.attempt.restart_problem =
                            Some(RestartProblem::Start { error: format!("{error:#}") });
                        cx.notify();
                        return false;
                    }
                    true
                })
                .unwrap_or(false);
            if !requested {
                return;
            }
            // If Windows is still running well after the countdown, it did
            // not restart; offer the restart again instead of claiming it is
            // happening.
            cx.background_executor().timer(timing.grace).await;
            this.update(cx, |this, cx| {
                if this.restart_epoch == epoch && this.attempt.restart.is_some() {
                    this.attempt.restart = None;
                    this.attempt.restart_cancelled = false;
                    cx.notify();
                }
            })
            .ok();
        }));
    }

    fn stop_restart_timer(&mut self) {
        self.restart_timer = None;
        self.restart_epoch += 1;
        self.attempt.restart = None;
    }

    /// Cancels the local countdown, so the user can finish
    /// something first. Atlas still needs the restart to complete setup.
    pub fn cancel_restart(&mut self, cx: &mut Context<Self>) {
        if self.attempt.restart.is_none() {
            return;
        }
        self.stop_restart_timer();
        self.attempt.restart_cancelled = true;
        self.attempt.restart_problem = None;
        cx.notify();
    }

    /// Starts the app countdown
    /// when the automatic restart was declined or turned off.
    pub fn restart_now(&mut self, cx: &mut Context<Self>) {
        if !matches!(self.flow.run, RunState::Finished(outcome) if outcome.is_success()) {
            return;
        }
        self.attempt.restart_problem = None;
        self.begin_restart_countdown(cx);
        cx.notify();
    }

    fn push_log(&mut self, lines: Vec<String>) {
        self.attempt.push_lines(lines);
    }

    /// The full log text for the clipboard (what is in memory; the file has everything).
    pub fn copy_log(&self, cx: &mut Context<Self>) {
        let mut text = self.attempt.log.iter().map(|line| line.as_ref()).collect::<Vec<_>>().join("\r\n");
        if let Some(session) = &self.session {
            text.push_str("\r\n");
            text.push_str(&t!("log-full-log-note", path = session.log_path.display().to_string()));
        }
        cx.write_to_clipboard(ClipboardItem::new_string(text));
    }

    pub fn reveal_log(&self, cx: &mut Context<Self>) {
        if let Some(session) = &self.session {
            let detailed = installer::machine_log_path();
            cx.reveal_path(if detailed.exists() { &detailed } else { &session.log_path });
        }
    }

    pub fn refresh_atlas_state(&mut self) {
        self.atlas = atlas_state::read().map_err(|e| format!("{e:#}"));
        self.install_identity = (self.env.adapters.read_install_identity)().map_err(|e| format!("{e:#}"));
        if let Err(error) = &self.install_identity {
            log::warn!("could not establish Atlas installation eligibility: {error}");
        }
    }

    // ----- Settings --------------------------------------------------------

    pub fn set_theme(&mut self, theme: ThemePreference, cx: &mut Context<Self>) {
        if self.settings.theme == theme {
            return;
        }
        self.settings.theme = theme;
        self.persist(move |doc| doc.theme = theme, |_, (), _| {}, cx);
        cx.emit(ModelEvent::ThemeChanged);
        cx.notify();
    }

    /// The preview translation currently in use, unless the user has
    /// dismissed the notice for it. The shell shows a bar naming it and
    /// offering English, the language Atlas is verified in.
    pub fn preview_notice(&self) -> Option<&'static i18n::Locale> {
        let locale = self.localization.primary();
        let dismissed =
            self.settings.dismissed_preview_notices.iter().any(|tag| tag.eq_ignore_ascii_case(locale.tag));
        (locale.readiness < i18n::Readiness::Source && !dismissed).then_some(locale)
    }

    /// Hides the preview notice for the current language, for good.
    pub fn dismiss_preview_notice(&mut self, cx: &mut Context<Self>) {
        let Some(locale) = self.preview_notice() else { return };
        let tag = locale.tag.to_owned();
        self.settings.dismissed_preview_notices.push(tag.clone());
        self.persist(
            move |doc| {
                if !doc.dismissed_preview_notices.iter().any(|t| t.eq_ignore_ascii_case(&tag)) {
                    doc.dismissed_preview_notices.push(tag);
                }
            },
            |_, (), _| {},
            cx,
        );
        cx.notify();
    }

    /// Switches to English from the preview notice: the English variant
    /// closest to the Windows display languages, so a US-English Windows
    /// gets US spelling. The choice is saved like one made in Settings.
    pub fn switch_to_english(&mut self, cx: &mut Context<Self>) {
        let tag = english_for(&self.localization.windows_languages);
        self.set_language(LanguagePreference::Explicit(tag), cx);
    }

    /// Changes the app language. Nothing but the words changes: the page,
    /// step, choices, focus and any running install stay as they are, and
    /// the next render draws every notice and status in the new language.
    pub fn set_language(&mut self, language: LanguagePreference, cx: &mut Context<Self>) {
        if self.settings.language == language {
            // Choosing "Match Windows" again is a request to look at Windows
            // again, for example after a query that failed at startup.
            if language == LanguagePreference::System {
                self.apply_language(cx);
            }
            return;
        }
        self.settings.language = language.clone();
        self.persist(move |doc| doc.language = language, |_, (), _| {}, cx);
        self.apply_language(cx);
    }

    fn apply_language(&mut self, cx: &mut Context<Self>) {
        self.apply_language_with(i18n::current_windows_languages(), cx);
    }

    /// Applies the language setting against an already-read Windows list, so
    /// a refresh negotiates against the list it just compared and never
    /// downgrades a working choice because a second query failed.
    fn apply_language_with(&mut self, windows: Result<Vec<String>, String>, cx: &mut Context<Self>) {
        self.localization = i18n::activate_with(&self.settings.language, None, windows);
        cx.emit(ModelEvent::LanguageChanged);
        cx.notify();
    }

    /// While "Match Windows" is on, follows a change to the Windows display
    /// language made while the app was in the background. Windows may need a
    /// sign-out for some changes, so this only reflects what it reports.
    pub fn refresh_language(&mut self, cx: &mut Context<Self>) {
        // The regional format is read live by the formatters; a change only
        // needs a redraw.
        let format_locale = i18n::fmt::format_locale_tag();
        if format_locale != self.localization.format_locale {
            self.localization.format_locale = format_locale;
            cx.notify();
        }
        if self.settings.language != LanguagePreference::System || !self.localization.follows_windows() {
            return;
        }
        match i18n::current_windows_languages() {
            Ok(languages) => {
                let was_unavailable =
                    matches!(self.localization.decision, i18n::Decision::WindowsUnavailable(_));
                if languages == self.localization.windows_languages && !was_unavailable {
                    return;
                }
                self.apply_language_with(Ok(languages), cx);
            }
            // A transient failure keeps the last working choice; the next
            // activation tries again.
            Err(error) => log::warn!("could not re-read the Windows display languages: {error:#}"),
        }
    }

    pub fn set_restart_after_install(&mut self, restart: bool, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.settings.restart_after_install = restart;
        self.persist(move |doc| doc.restart_after_install = restart, |_, (), _| {}, cx);
        cx.notify();
    }

    /// Re-reads the Ease of Access preferences; the theme follows them.
    pub fn refresh_accessibility(&mut self, cx: &mut Context<Self>) {
        let preferences = AccessibilityPreferences::read();
        if preferences != self.accessibility {
            self.accessibility = preferences;
            cx.emit(ModelEvent::ThemeChanged);
            cx.notify();
        }
    }

    /// Relaunches elevated from inside the flow (only reachable when the app
    /// was started on the Install page without elevation). The draft is
    /// written first (awaited, off the window's thread) so the elevated copy
    /// resumes here.
    pub fn relaunch_elevated(&mut self, cx: &mut Context<Self>) {
        if self.locked() {
            return;
        }
        let Some(draft) = self.current_draft() else { return };
        self.settings.draft = Some(draft.clone());
        let flow = draft.flow.clone();
        let saved = self.store.transact(move |doc| {
            if draft_owned_by(&doc.draft, flow.as_deref()) {
                doc.draft = Some(draft);
                true
            } else {
                false
            }
        });
        cx.spawn(async move |this, cx| {
            let saved = saved.await;
            this.update(cx, |this, cx| {
                if this.locked() {
                    return;
                }
                let problem = match saved {
                    Ok(Ok(true)) => None,
                    Ok(Ok(false)) => Some("another Atlas window has taken over this install flow".to_owned()),
                    Ok(Err(error)) => Some(error),
                    Err(_) => Some("the settings writer stopped".to_owned()),
                };
                if let Some(error) = problem {
                    this.elevation_error = Some(ElevationProblem::DraftNotSaved { error });
                    cx.notify();
                    return;
                }
                match system::relaunch_elevated() {
                    // The elevated copy is starting; quit once this handler has
                    // returned, since quitting mid-update would re-enter the app state.
                    Ok(()) => cx.defer(|cx| cx.quit()),
                    Err(error) => {
                        log::warn!("elevation declined: {error:#}");
                        this.elevation_error = Some(ElevationProblem::DeclinedContinue);
                        cx.notify();
                    }
                }
            })
            .ok();
        })
        .detach();
    }
}

/// Whether Windows Security counts as off for the gate: every switch reads
/// off, or every readable switch does and the user confirmed the unreadable
/// rest by hand for this very reading. One rule for the step's Next button,
/// the Install button and the final preflight.
pub fn security_verified(
    status: &SecurityStatus,
    confirmation: Option<SecurityStatus>,
    elevated: bool,
) -> bool {
    status.all_off() || (elevated && confirmation == Some(*status) && status.off_where_readable())
}

/// The last decision before the child starts, from the readings taken a
/// moment ago: which blocking checks still stand in the way (an unknown
/// result the user acknowledged does not), and whether Windows Security is
/// verified off under the current confirmation.
pub fn preflight_decision(
    results: &[CheckResult],
    acknowledged: &BTreeSet<CheckId>,
    security: &SecurityStatus,
    confirmation: Option<SecurityStatus>,
    elevated: bool,
) -> Result<(), Preflight> {
    let problems: Vec<(CheckId, CheckDetail)> = results
        .iter()
        .filter(|result| {
            result.blocks_install() && !(result.needs_acknowledgement() && acknowledged.contains(&result.id))
        })
        .map(|result| (result.id, result.detail.clone()))
        .collect();
    let security_problem = (!security_verified(security, confirmation, elevated)).then(|| security.counts());
    if problems.is_empty() && security_problem.is_none() {
        Ok(())
    } else {
        Err(Preflight::Changed { checks: problems, security: security_problem })
    }
}

/// Whether the draft on disk may be written or removed by flow `flow`:
/// there is none, it is this flow's, or it predates flow identities and so
/// belongs to no window in particular.
pub fn draft_owned_by(on_disk: &Option<InstallDraft>, flow: Option<&str>) -> bool {
    match on_disk {
        None => true,
        Some(draft) => draft.flow.is_none() || draft.flow.as_deref() == flow,
    }
}

/// Whether `draft` is the flow that launched the install `record`. Only
/// positive ownership counts: the draft names the session. A current flow
/// that has not launched (it has an identity but no session) is never it,
/// whatever package or step it is at. The one exception is a draft from
/// before flows had identities: it is taken to be the launcher only if it
/// stood at the Install step for the very package the record ran, with
/// every option the record ran among its choices.
pub fn draft_launched(draft: &InstallDraft, record: &SessionRecord) -> bool {
    if draft.session.is_some() {
        return draft.session.as_deref() == Some(record.id.as_str());
    }
    draft.flow.is_none()
        && draft.step == Step::Install.name()
        && draft.playbook_dir.as_deref() == Some(record.request.playbook_dir.as_path())
        && record.request.options.iter().all(|option| draft.options.contains(option))
}

/// Reads the shared install record under the launch lock. A record that a
/// launch abandoned before committing is removed here; everything else is
/// handed to the model to reconcile with its draft.
fn inspect_startup(paths: &SessionPaths) -> StartupInspection {
    // Under the launch lock, so a launch in progress elsewhere has either
    // committed its process or is not there at all.
    let lock = match LaunchLock::acquire(paths) {
        Ok(lock) => lock,
        Err(error) => {
            log::warn!("could not inspect the install session: {error:#}");
            return StartupInspection::Unreadable(format!("{error:#}"));
        }
    };
    match lock.inspect(paths) {
        Inspection::None => StartupInspection::None,
        Inspection::Abandoned => {
            lock.discard(paths);
            StartupInspection::None
        }
        Inspection::Unreadable(problem) => StartupInspection::Unreadable(problem),
        Inspection::Live(record) => StartupInspection::Live(record),
        Inspection::Ended(record) => StartupInspection::Ended(record),
    }
}

/// One screen of the Options step.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OptionScreen {
    /// What the screen decides; its title and question are worded at render.
    pub kind: ScreenKind,
    /// Indexes into the manifest's pages shown on this screen.
    pub pages: Vec<usize>,
    /// Exactly one choice is required.
    pub required: bool,
}

/// What a page of options controls, derived from its first option's stable
/// name. The words for each kind live in the message catalog.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ScreenKind {
    Defender,
    Mitigations,
    Updates,
    Browser,
    Power,
    Apps,
    Toolbox,
    ChooseOne,
    Extras,
}

impl ScreenKind {
    pub fn of_page(page: &FeaturePage) -> ScreenKind {
        let first = page.options.first().map(|o| o.name.as_str()).unwrap_or_default();
        match first {
            n if n.starts_with("defender") => ScreenKind::Defender,
            n if n.starts_with("mitigations") => ScreenKind::Mitigations,
            n if n.starts_with("auto-updates") => ScreenKind::Updates,
            n if n.starts_with("browser") => ScreenKind::Browser,
            n if n.starts_with("disable-hibernation") || n.starts_with("disable-power") => ScreenKind::Power,
            n if n.starts_with("remove-")
                || n.starts_with("uninstall-")
                || n.starts_with("install-another") =>
            {
                ScreenKind::Apps
            }
            n if n.starts_with("install-toolbox") => ScreenKind::Toolbox,
            _ => match page.kind {
                PageKind::Radio => ScreenKind::ChooseOne,
                PageKind::Checkbox => ScreenKind::Extras,
            },
        }
    }
}

#[cfg(test)]
mod tests;
