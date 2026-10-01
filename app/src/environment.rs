//! What the model needs from its process: file locations, machine readers and
//! restart timing. The app wires the Windows adapters; model tests wire
//! controlled ones, so they run without elevation, a restart or a particular
//! Windows Security state.

use std::sync::Arc;
use std::time::Duration;

use crate::services::atlas_state::{self, AtlasState, InstallIdentity};
use crate::services::preparation::{self, Drivers};
use crate::services::releases::{self, Release};
use crate::services::requirements::{self, CheckContext, CheckId, CheckResult};
use crate::services::security::SecurityStatus;
use crate::services::session::{self, SessionPaths};
use crate::services::settings::{self, AppPaths};
use crate::services::{iso, system};

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
