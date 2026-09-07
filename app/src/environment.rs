//! What the model needs from the process it runs in: where its files live,
//! how it reads the machine, and how fast the restart countdown runs. The
//! app wires the real Windows adapters; the model tests wire controlled ones,
//! so orchestration can be exercised without an elevated PC, a restart or a
//! particular Windows Security state.

use std::sync::Arc;
use std::time::Duration;

use crate::services::requirements::{self, CheckContext, CheckId, CheckResult};
use crate::services::security::SecurityStatus;
use crate::services::settings::AppPaths;
use crate::services::system;

pub type CheckRunner = Arc<dyn Fn(CheckId, &CheckContext) -> CheckResult + Send + Sync>;
pub type RestartScheduler = Arc<dyn Fn(&str) -> anyhow::Result<()> + Send + Sync>;
pub type IdentityReader =
    Arc<dyn Fn() -> anyhow::Result<crate::services::atlas_state::InstallIdentity> + Send + Sync>;

/// The machine as the model sees it. Every reader is a plain function, so a
/// test can substitute one without a trait for each service.
#[derive(Clone)]
pub struct Adapters {
    pub is_elevated: Arc<dyn Fn() -> bool + Send + Sync>,
    pub read_security: Arc<dyn Fn() -> SecurityStatus + Send + Sync>,
    pub read_install_identity: IdentityReader,
    pub run_check: CheckRunner,
    pub schedule_restart: RestartScheduler,
    pub register_preparation_resume: Arc<dyn Fn() -> anyhow::Result<()> + Send + Sync>,
}

impl Adapters {
    /// The real Windows readers and commands.
    pub fn windows() -> Self {
        Self {
            is_elevated: Arc::new(system::is_elevated),
            read_security: Arc::new(SecurityStatus::read),
            read_install_identity: Arc::new(crate::services::atlas_state::read_install_identity),
            run_check: Arc::new(requirements::run),
            schedule_restart: Arc::new(system::schedule_restart),
            register_preparation_resume: Arc::new(crate::services::preparation::register_resume),
        }
    }
}

/// The app-owned countdown before an immediate Windows restart.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct RestartTiming {
    /// How long the countdown lasts.
    pub countdown: Duration,
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
    /// `--language`, which outranks the language setting (review and testing).
    pub language_override: Option<String>,
    pub restart: RestartTiming,
    pub adapters: Adapters,
}

impl Environment {
    /// The running process: its app data directory and the real adapters.
    pub fn from_process(language_override: Option<String>) -> Self {
        Self {
            paths: AppPaths::from_process(),
            check_updates: true,
            language_override,
            restart: RestartTiming::default(),
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
            language_override: None,
            restart: RestartTiming::default(),
            adapters: Adapters::windows(),
        }
    }
}

impl std::fmt::Debug for Environment {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Environment")
            .field("paths", &self.paths)
            .field("check_updates", &self.check_updates)
            .field("language_override", &self.language_override)
            .field("restart", &self.restart)
            .finish_non_exhaustive()
    }
}
