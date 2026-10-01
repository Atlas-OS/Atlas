//! UI state and background task coordination. Pages render this model; actions
//! use [`crate::flow`] to enforce install transitions and prevent changes while
//! an install is running.
//!
//! The model owns the check, download, security and restart tasks. Replacing a
//! task drops its handle; generation checks discard results from older tasks.

mod checks;
mod drafts;
mod elevation;
mod eligibility;
mod install;
mod navigation;
mod options;
mod package;
mod preferences;
mod preparation;
mod preview;
mod recovery;
mod restart;
#[cfg(test)]
pub(crate) mod test_harness;
#[cfg(test)]
mod tests;

pub use checks::{ReadyHelp, ReadyStatus};
pub use elevation::ElevationProblem;
pub use eligibility::InstallBlock;
pub use install::{InstallAttempt, Preflight};
pub use options::ScreenKind;
pub use package::{AcquireProblem, Acquisition, Origin, PlaybookSource, ReleaseCheck};
pub use preferences::{ProtectionReminder, ReminderReason};
pub use restart::{OwedRestart, RestartCountdown, RestartProblem};

// The Install page's tests check the Windows Security rule directly.
#[cfg(test)]
pub use checks::security_verified;

use std::collections::BTreeSet;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::time::Instant;

use gpui::{Context, EventEmitter, Task};

pub use crate::environment::Environment;
pub use crate::flow::{Flow, RunState, Step};
use crate::i18n::{self, Localization};
use crate::services::atlas_state::{self, AtlasState};
use crate::services::playbook::{self, Manifest};
use crate::services::requirements::{CheckId, CheckResult};
use crate::services::security::SecurityStatus;
use crate::services::session::{SessionPaths, SessionRecord};
use crate::services::settings::{self, AppSettings, SettingsProblem};
use crate::services::system::{AccessibilityPreferences, SystemInfo};
use crate::services::{self, desktop_setup, diagnostics, iso};

use navigation::PendingStart;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Page {
    Home,
    Iso,
    Install,
    Settings,
    Report,
    /// The completion window, opened by the completion Run entry after the
    /// install's restart (see `session::completion_after_restart`).
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
            "report" => Some(Page::Report),
            "installed" => Some(Page::Installed),
            _ => None,
        }
    }
}

/// Something the user should know about the app's own state (a damaged
/// settings file, a save that failed), shown on Home until dismissed, or,
/// for a failed save, until a later write has saved what was lost. Held as
/// its cause so it can be worded in whatever language is current.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Notice {
    SettingsReset(SettingsProblem),
    SettingsNotSaved { error: String },
    SessionUnreadable { error: String, record: PathBuf },
}

pub enum ModelEvent {
    ThemeChanged,
    LanguageChanged,
}

/// Counts restarts of one kind of background task. A task keeps the
/// generation it started in; once a newer one has begun, its late result is
/// stale and dropped.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct Generation(u64);

impl Generation {
    /// Begins a new generation, making every earlier one stale, and returns it.
    fn next(&mut self) -> Generation {
        self.0 += 1;
        *self
    }
}

/// What closing the window now would interrupt, so the shell knows whether
/// and how to ask first.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CloseGuard {
    /// Nothing is under way; the window just closes.
    None,
    /// A preparation restart is being saved; closing waits for that moment.
    Wait,
    /// Windows preparation is running.
    Preparation,
    /// An ISO or USB job is running.
    Media,
    /// The final checks run and nothing has launched: closing starts nothing.
    PreparingInstall,
    /// The installer has launched; it carries on without the window.
    Install,
    /// The restart countdown is running, and only this window keeps it.
    Restart,
    /// A setup is under way with Windows Security switches read off:
    /// closing leaves them off unless the user finishes or turns them back on.
    ProtectionOff,
}

pub struct AppModel {
    pub diagnostics_busy: bool,
    pub diagnostics_result: Option<Result<PathBuf, String>>,
    /// Launched as the setup shell of an Atlas ISO install, before the
    /// user's desktop exists.
    pub before_desktop: bool,
    /// Options chosen when the ISO was built; the first package that loads
    /// uses them if it accepts them.
    iso_initial_options: Option<Vec<String>>,
    pub preparation: services::preparation::State,
    pub preparation_progress: Option<services::preparation::Progress>,
    pub preparation_error: Option<String>,
    pub preparation_job: Option<PathBuf>,
    /// When preparation asked for a restart (RFC 3339); saved in the draft
    /// so the next start resumes after it.
    preparation_restart_at: Option<String>,
    pub preparation_problem: Option<services::preparation::RestartProblem>,
    pub preparation_cancel: Arc<AtomicBool>,
    preparation_task: Option<Task<()>>,
    /// The driver policy preparation uses when the user has not chosen one,
    /// read from the machine once, at startup, rather than on every render.
    driver_default: services::preparation::Drivers,
    /// An ISO or USB job is running (the USB page sets this as well as
    /// `usb_busy`).
    pub iso_busy: bool,
    pub usb_busy: bool,
    pub iso_cancel: Arc<AtomicBool>,
    env: Environment,
    pub page: Page,
    /// Counts changes of page, so a page can tell being shown again from
    /// being redrawn and move focus to its heading.
    pub page_visit: u64,
    /// The page the report page was opened from, for its back arrow.
    report_return: Page,
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
    /// The shared install record couldn't be read (the raw error). The flow
    /// waits at Get ready until a new reading succeeds.
    pub record_problem: Option<String>,
    record_generation: Generation,
    /// The elevated copy is being started; nothing may begin or restart
    /// the flow until Windows has answered.
    pub elevating: bool,
    /// Where the launch asked to open, applied once recovery has decided.
    pending_start: Option<PendingStart>,

    pub release: ReleaseCheck,
    pub acquisition: Acquisition,
    acquisition_task: Option<Task<()>>,
    acquisition_generation: Generation,
    /// Set when the running download is given up, so its transfer stops at
    /// its next chunk rather than running on unseen.
    acquisition_cancel: Arc<AtomicBool>,
    /// When the running download last received data.
    download_heard: Instant,
    pub playbook: Option<PlaybookSource>,
    /// Download was chosen while the release check ran or had failed: the
    /// check, when it ends, starts the download wherever it was chosen.
    download_requested: bool,
    builtin_manifest: Manifest,

    pub security: SecurityStatus,
    security_read_at: Option<Instant>,
    security_watch: Option<Task<()>>,
    security_generation: Generation,
    /// The user confirmed, in Windows Security, that the switches that could
    /// not be read are off. The confirmation names the reading it was given
    /// for: a different reading, later, is not covered by it.
    security_confirmation: Option<SecurityStatus>,

    pub flow: Flow,
    /// Which screen of the Options step is showing (see [`AppModel::option_screens`]).
    pub option_screen: usize,
    /// Options was opened from a Change link on the Install step: Continue
    /// goes back there. Never saved in the draft.
    pub returning_to_install: bool,
    pub options: BTreeSet<String>,
    pub checks: Vec<(CheckId, Option<CheckResult>)>,
    check_tasks: Vec<Task<()>>,
    /// Blocking checks that could not run and that the user confirmed by hand.
    pub acknowledged: BTreeSet<CheckId>,
    checks_generation: Generation,
    /// Why the final checks refused to start the install.
    pub preflight_problem: Option<Preflight>,
    /// Counts refusals, so a refusal like the one before it is still news.
    pub preflight_epoch: u64,
    /// The launch was handed to a worker; the installer may be starting.
    launching: bool,

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
    /// What belongs to the current install attempt alone.
    pub attempt: InstallAttempt,
    restart_timer: Option<Task<()>>,
    restart_generation: Generation,
    /// Why the last "Restart as administrator" did not happen, if it did not.
    pub elevation_error: Option<ElevationProblem>,
    /// The user left the flow with Windows Security switched off.
    pub security_reminder: bool,
    /// The reminder above was restored from an earlier run, so it waits
    /// for a live reading rather than naming switches never read.
    awaiting_reminder_reading: bool,
    /// The reminder was dismissed on the "Atlas is installed" window, which
    /// shows one dismissed before it opened.
    reminder_dismissed_here: bool,
    /// Whether the window is in front, as the shell last reported. A restart
    /// countdown that starts unseen runs longer.
    window_active: bool,
    /// ISO creation was opened to reinstall this PC: it preselects This PC
    /// once, on arrival.
    pub iso_for_this_pc: bool,
    /// The latest Windows Security reading for Home's and the "Atlas is
    /// installed" window's reminders, taken as they open.
    protection: Option<SecurityStatus>,
    protection_generation: Generation,
    /// A finished install still owes its restart (see
    /// [`AppModel::owed_restart`]).
    owed_restart: Option<OwedRestart>,
    session_paths: SessionPaths,
}

impl EventEmitter<ModelEvent> for AppModel {}

impl AppModel {
    pub fn export_diagnostics(&mut self, cx: &mut Context<Self>) {
        if self.diagnostics_busy {
            return;
        }
        self.diagnostics_busy = true;
        self.diagnostics_result = None;
        let root = self.env.paths.root.clone();
        let package = self
            .playbook
            .as_ref()
            .and_then(|book| playbook::identity(&book.dir))
            .and_then(|identity| serde_json::to_value(identity).ok());
        log::info!("Diagnostic export requested");
        cx.spawn(async move |this, cx| {
            let result = cx
                .background_executor()
                .spawn(
                    async move { diagnostics::export(&root, package).map_err(|error| format!("{error:#}")) },
                )
                .await;
            this.update(cx, |this, cx| {
                match &result {
                    Ok(path) => log::info!("Diagnostic export saved: {}", path.display()),
                    Err(error) => log::error!("Diagnostic export failed: {error}"),
                }
                this.diagnostics_busy = false;
                this.diagnostics_result = Some(result);
                cx.notify();
            })
            .ok();
        })
        .detach();
        cx.notify();
    }

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
        let store = settings::Store::new(env.paths.settings(), env.settings_lock_wait);
        let elevated = (env.adapters.is_elevated)();
        let mut model = Self {
            diagnostics_busy: false,
            diagnostics_result: None,
            before_desktop: desktop_setup::active()
                || (cfg!(debug_assertions) && std::env::var_os("ATLAS_DESKTOP_PREVIEW").is_some()),
            iso_initial_options: if loaded.settings.draft.is_none() { iso::staged_options() } else { None },
            preparation: Default::default(),
            preparation_progress: None,
            preparation_error: None,
            preparation_job: None,
            preparation_restart_at: None,
            preparation_problem: None,
            preparation_cancel: Arc::new(AtomicBool::new(false)),
            preparation_task: None,
            driver_default: (env.adapters.read_driver_default)(),
            install_identity: (env.adapters.read_install_identity)().map_err(|e| format!("{e:#}")),
            atlas: (env.adapters.read_atlas_state)().map_err(|e| format!("{e:#}")),
            env,
            page: Page::Home,
            page_visit: 0,
            report_return: Page::Home,
            iso_busy: false,
            usb_busy: false,
            iso_cancel: Arc::new(AtomicBool::new(false)),
            system: SystemInfo::read(),
            elevated,
            settings: loaded.settings,
            notice: loaded.problem.map(Notice::SettingsReset),
            accessibility: AccessibilityPreferences::read(),
            localization,
            recovering: false,
            record_problem: None,
            record_generation: Generation::default(),
            elevating: false,
            pending_start: None,
            release: ReleaseCheck::NotChecked,
            acquisition: Acquisition::Idle,
            acquisition_task: None,
            acquisition_generation: Generation::default(),
            acquisition_cancel: Arc::new(AtomicBool::new(false)),
            download_heard: Instant::now(),
            playbook: None,
            download_requested: false,
            builtin_manifest,
            security: SecurityStatus::default(),
            security_read_at: None,
            security_watch: None,
            security_generation: Generation::default(),
            security_confirmation: None,
            flow: Flow::default(),
            option_screen: 0,
            returning_to_install: false,
            options,
            checks: Vec::new(),
            check_tasks: Vec::new(),
            acknowledged: BTreeSet::new(),
            checks_generation: Generation::default(),
            preflight_problem: None,
            preflight_epoch: 0,
            launching: false,
            session: None,
            own_session: None,
            flow_id: None,
            store,
            attempt: InstallAttempt::default(),
            restart_timer: None,
            restart_generation: Generation::default(),
            elevation_error: None,
            security_reminder: false,
            awaiting_reminder_reading: false,
            reminder_dismissed_here: false,
            window_active: true,
            iso_for_this_pc: false,
            protection: None,
            protection_generation: Generation::default(),
            owed_restart: None,
            session_paths,
        };
        if let Some(preview) = preview::requested() {
            preview::apply(&mut model, &preview);
            return model;
        }
        if model.env.check_updates {
            model.check_for_updates(cx);
        }
        model.begin_recovery(cx);
        model.refresh_page_notices(cx);
        model
    }

    /// An install, an ISO or USB job, or Windows preparation is running;
    /// nothing that feeds the install may change.
    pub fn locked(&self) -> bool {
        self.flow.locked() || self.iso_busy || self.preparation.busy()
    }

    /// Whether the shell's window is in front, as it reports on activation.
    pub fn set_window_active(&mut self, active: bool) {
        self.window_active = active;
    }

    /// Whether a Download chosen before the release was known is waiting.
    pub fn download_pending(&self) -> bool {
        self.download_requested
    }
}
