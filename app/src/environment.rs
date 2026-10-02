//! What the model needs from its process: file locations, machine readers and
//! restart timing. The app wires the Windows adapters; model tests wire
//! controlled ones, so they run without elevation, a restart or a particular
//! Windows Security state.

use std::path::Path;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::time::Duration;

use crate::services::atlas_state::{self, AtlasState, InstallIdentity};
use crate::services::preparation::{self, Drivers, Operation, PreparationRequest, Progress, State};
use crate::services::releases::{self, Release};
use crate::services::requirements::{self, CheckContext, CheckId, CheckResult};
use crate::services::security::SecurityStatus;
use crate::services::session::{self, SessionPaths};
use crate::services::settings::{self, AppPaths};
use crate::services::system::SystemInfo;
use crate::services::update_access::{self, UpdateAccess};
use crate::services::{iso, system};

/// Runs one preparation in a job folder, reporting the worker's progress.
pub type RunPreparation = dyn Fn(&Path, &PreparationRequest, Arc<AtomicBool>, Box<dyn FnMut(Progress) + Send>) -> anyhow::Result<State>
    + Send
    + Sync;

/// The machine as the model sees it. Every reader is a plain function, so a
/// test can substitute one without a trait for each service.
#[derive(Clone)]
#[allow(clippy::type_complexity)]
pub struct Adapters {
    pub is_elevated: Arc<dyn Fn() -> bool + Send + Sync>,
    pub read_security: Arc<dyn Fn() -> SecurityStatus + Send + Sync>,
    pub read_install_identity: Arc<dyn Fn() -> anyhow::Result<InstallIdentity> + Send + Sync>,
    pub read_atlas_state: Arc<dyn Fn() -> anyhow::Result<Option<AtlasState>> + Send + Sync>,
    pub run_check: Arc<dyn Fn(CheckId, &CheckContext) -> CheckResult + Send + Sync>,
    pub schedule_restart: Arc<dyn Fn(&str) -> anyhow::Result<()> + Send + Sync>,
    pub register_preparation_resume: Arc<dyn Fn() -> anyhow::Result<()> + Send + Sync>,
    pub relaunch_elevated: Arc<dyn Fn() -> anyhow::Result<()> + Send + Sync>,
    /// Arms the completion window for an install that has just started (see
    /// [`session::arm_completion`]); run on a worker.
    pub arm_completion: Arc<dyn Fn(&SessionPaths) -> anyhow::Result<()> + Send + Sync>,
    /// Asks GitHub for the latest Atlas release.
    pub fetch_release: Arc<dyn Fn() -> anyhow::Result<Release> + Send + Sync>,
    /// The driver policy this PC has when the user has not chosen one.
    pub read_driver_default: Arc<dyn Fn() -> Drivers + Send + Sync>,
    /// This PC's Windows version and edition.
    pub read_system: Arc<dyn Fn() -> SystemInfo + Send + Sync>,
    /// The Windows and Store update worker; run on a worker thread.
    pub run_preparation: Arc<RunPreparation>,
    /// What holds Windows Update back, and Atlas's record of what it turned on.
    pub read_update_access: Arc<dyn Fn() -> anyhow::Result<UpdateAccess> + Send + Sync>,
    /// A short worker operation (commit, put back) for the settings at the
    /// given path; run on a worker thread.
    pub run_operation: Arc<dyn Fn(&Path, Operation) -> anyhow::Result<()> + Send + Sync>,
    /// The install options an Atlas without a state document shows on the PC.
    pub read_legacy_choices: Arc<dyn Fn() -> Vec<String> + Send + Sync>,
    /// The other people signed in to this PC, whose apps a restart closes.
    pub read_other_sessions: Arc<dyn Fn() -> anyhow::Result<Vec<String>> + Send + Sync>,
}

impl Adapters {
    /// The real Windows readers and commands.
    pub fn windows() -> Self {
        Self {
            is_elevated: Arc::new(system::is_elevated),
            read_security: Arc::new(SecurityStatus::read),
            read_install_identity: Arc::new(atlas_state::read_install_identity),
            read_atlas_state: Arc::new(atlas_state::read),
            run_check: Arc::new(requirements::run),
            schedule_restart: Arc::new(system::schedule_restart),
            register_preparation_resume: Arc::new(preparation::register_resume),
            relaunch_elevated: Arc::new(system::relaunch_elevated),
            arm_completion: Arc::new(session::arm_completion),
            fetch_release: Arc::new(releases::fetch_latest),
            read_driver_default: Arc::new(|| {
                iso::staged_drivers().unwrap_or_else(preparation::existing_driver_policy)
            }),
            read_system: Arc::new(SystemInfo::read),
            run_preparation: Arc::new(|job, request, cancel, report| {
                preparation::run(job, request, cancel, report)
            }),
            read_update_access: Arc::new(update_access::read),
            run_operation: Arc::new(preparation::run_operation),
            read_legacy_choices: Arc::new(crate::services::legacy_choices::read),
            read_other_sessions: Arc::new(crate::services::signed_in::others),
        }
    }
}

/// The app-owned countdown before an immediate Windows restart.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct RestartTiming {
    /// How long the countdown lasts while the window is in front.
    pub countdown: Duration,
    /// How long it lasts when it starts with the window behind other
    /// windows or minimised: long enough to notice the flashing taskbar
    /// button, come back and choose Restart later.
    pub background_countdown: Duration,
    /// How often the view is refreshed while it runs.
    pub tick: Duration,
    /// How long after the countdown the view keeps saying Windows is
    /// restarting before concluding that it is not.
    pub grace: Duration,
}

impl Default for RestartTiming {
    fn default() -> Self {
        Self {
            countdown: Duration::from_secs(10),
            background_countdown: Duration::from_secs(60),
            tick: Duration::from_secs(1),
            grace: Duration::from_secs(20),
        }
    }
}

/// How Get ready waits for Windows Update to offer a new Windows release:
/// how often it looks again, and for how long in all.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct OfferRecheckTiming {
    pub interval: Duration,
    pub window: Duration,
    /// How often Get ready's clock of the wait is refreshed between looks.
    pub tick: Duration,
}

impl Default for OfferRecheckTiming {
    fn default() -> Self {
        Self {
            interval: Duration::from_secs(10 * 60),
            window: Duration::from_secs(2 * 60 * 60),
            tick: Duration::from_secs(15),
        }
    }
}

#[derive(Clone)]
pub struct Environment {
    pub paths: AppPaths,
    /// Ask GitHub for the latest release at startup.
    pub check_updates: bool,
    /// A tester build: the bundled Atlas package is the only one, loaded
    /// when a flow needs it, and GitHub is never asked. Tests keep this off
    /// and choose their own packages.
    pub embedded_startup: bool,
    /// `--language`, which outranks the language setting (review and testing).
    pub language_override: Option<String>,
    pub restart: RestartTiming,
    pub offer_recheck: OfferRecheckTiming,
    /// How long a settings write waits for another window's lock before it fails.
    pub settings_lock_wait: Duration,
    pub adapters: Adapters,
}

impl Environment {
    /// The running process: its app data directory and the real adapters.
    pub fn from_process(language_override: Option<String>) -> Self {
        Self {
            paths: AppPaths::from_process(),
            // A tester build installs only its bundled package, so it never checks for releases.
            check_updates: !cfg!(feature = "embedded-playbook"),
            embedded_startup: cfg!(feature = "embedded-playbook"),
            language_override,
            restart: RestartTiming::default(),
            offer_recheck: OfferRecheckTiming::default(),
            settings_lock_wait: settings::LOCK_WAIT,
            adapters: Adapters::windows(),
        }
    }

    /// An isolated environment under `root` with no network and the real
    /// adapters; tests replace the adapters they control.
    #[cfg(test)]
    pub fn isolated(root: impl Into<std::path::PathBuf>) -> Self {
        Self {
            paths: AppPaths::under(root),
            check_updates: false,
            embedded_startup: false,
            language_override: None,
            restart: RestartTiming::default(),
            offer_recheck: OfferRecheckTiming::default(),
            settings_lock_wait: settings::LOCK_WAIT,
            adapters: Adapters::windows(),
        }
    }
}

impl std::fmt::Debug for Environment {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Environment")
            .field("paths", &self.paths)
            .field("check_updates", &self.check_updates)
            .field("embedded_startup", &self.embedded_startup)
            .field("language_override", &self.language_override)
            .field("restart", &self.restart)
            .field("settings_lock_wait", &self.settings_lock_wait)
            .finish_non_exhaustive()
    }
}
