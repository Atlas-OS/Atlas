//! The durable record of an install that has been started: which process is
//! running it, where its output goes, and where its exit code is written.
//! The record outlives the window, so a reopened app can find the install
//! again instead of assuming nothing is running.

use std::fs::{File, OpenOptions};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use super::installer::InstallRequest;
use super::system;

/// Where session files live. Injected so tests never touch the real app data.
#[derive(Clone, Debug)]
pub struct SessionPaths {
    pub record: PathBuf,
    pub logs: PathBuf,
}

impl SessionPaths {
    pub fn under(root: &Path) -> Self {
        Self { record: root.join("session.json"), logs: root.join("Logs") }
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionRecord {
    pub id: String,
    pub pid: u32,
    /// Process creation time (FILETIME), so a reused PID is not mistaken for
    /// the installer.
    pub process_start: u64,
    pub started_at: String,
    pub log_path: PathBuf,
    pub exit_path: PathBuf,
    pub request: InstallRequest,
}

impl SessionRecord {
    /// Written before the child was spawned; no process identity yet.
    pub fn is_pending(&self) -> bool {
        self.pid == 0
    }

    /// Whether the installer process is still running.
    pub fn is_alive(&self) -> bool {
        self.liveness() == system::Liveness::Alive
    }

    /// Whether the installer process is still running, or whether Windows
    /// would not say.
    pub fn liveness(&self) -> system::Liveness {
        if self.is_pending() {
            return system::Liveness::Ended;
        }
        system::process_liveness(self.pid, self.process_start)
    }

    /// The exit code the installer wrote when it finished, if it did.
    pub fn exit_code(&self) -> Option<i32> {
        std::fs::read_to_string(&self.exit_path).ok()?.trim().parse().ok()
    }
}

pub fn load(paths: &SessionPaths) -> Result<Option<SessionRecord>> {
    let text = match std::fs::read_to_string(&paths.record) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).with_context(|| format!("read {}", paths.record.display())),
    };
    serde_json::from_str(text.trim_start_matches('\u{feff}'))
        .map(Some)
        .with_context(|| format!("parse {}", paths.record.display()))
}

pub fn save(paths: &SessionPaths, record: &SessionRecord) -> Result<()> {
    if let Some(parent) = paths.record.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let temp = paths.record.with_extension(format!("json.{}.tmp", std::process::id()));
    std::fs::write(&temp, serde_json::to_string_pretty(record)?)?;
    std::fs::rename(&temp, &paths.record).with_context(|| format!("write {}", paths.record.display()))
}

/// A collision-resistant session id: time, process and a nanosecond stamp.
pub fn new_id() -> String {
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    format!("{}-{}-{nanos:x}", chrono::Local::now().format("%Y%m%d-%H%M%S"), std::process::id())
}

/// What the shared record says, read while the launch lock is held so no
/// launch can be half-committed at the same time.
#[derive(Debug)]
pub enum Inspection {
    /// No record.
    None,
    /// The recorded process is running.
    Live(SessionRecord),
    /// The recorded process has ended; its exit file may hold the result.
    Ended(SessionRecord),
    /// A record written by a launch that never committed a process. The lock
    /// is held, so no launch is under way: nothing owns this record.
    Abandoned,
    /// The record exists but cannot be read or parsed right now. Its owner is
    /// unknown, which is not the same as absent: nothing may replace or
    /// remove it, and no new install may start, until it can be read.
    Unreadable(String),
}

/// Serialises everything that reads and replaces the shared session record
/// across app instances: whoever holds the lock file (opened with no sharing)
/// may inspect the record, start a new install, or remove the record.
/// Released when dropped.
pub struct LaunchLock {
    _file: File,
}

impl LaunchLock {
    /// Waits briefly for another instance's launch to finish committing.
    pub fn acquire(paths: &SessionPaths) -> Result<Self> {
        const WAIT: std::time::Duration = std::time::Duration::from_secs(5);
        const RETRY: std::time::Duration = std::time::Duration::from_millis(50);
        let deadline = std::time::Instant::now() + WAIT;
        loop {
            match Self::try_acquire(paths) {
                Ok(lock) => return Ok(lock),
                Err(error) if error.is::<Busy>() && std::time::Instant::now() < deadline => {
                    std::thread::sleep(RETRY);
                }
                Err(error) => return Err(error),
            }
        }
    }

    fn try_acquire(paths: &SessionPaths) -> Result<Self> {
        let path = paths.record.with_extension("lock");
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut options = OpenOptions::new();
        options.read(true).write(true).create(true).truncate(false);
        #[cfg(windows)]
        {
            use std::os::windows::fs::OpenOptionsExt;
            options.share_mode(0);
        }
        #[cfg(not(windows))]
        {
            options.create_new(true);
        }
        match options.open(&path) {
            Ok(file) => Ok(Self { _file: file }),
            Err(error) if is_sharing_violation(&error) => Err(Busy.into()),
            Err(error) => Err(error).with_context(|| format!("open {}", path.display())),
        }
    }

    /// The current record, classified.
    pub fn inspect(&self, paths: &SessionPaths) -> Inspection {
        match load(paths) {
            Ok(None) => Inspection::None,
            Ok(Some(record)) if record.is_pending() => Inspection::Abandoned,
            Ok(Some(record)) => match record.liveness() {
                system::Liveness::Alive => Inspection::Live(record),
                system::Liveness::Ended => Inspection::Ended(record),
                // Windows would not say whether the process runs: the
                // record's owner is unknown, exactly as when it cannot be read.
                system::Liveness::Unknown(problem) => {
                    log::warn!("the install session's process cannot be queried: {problem}");
                    Inspection::Unreadable(problem)
                }
            },
            Err(error) => {
                log::warn!("the install session record is unreadable: {error:#}");
                Inspection::Unreadable(format!("{error:#}"))
            }
        }
    }

    /// Removes the record. Only for callers that already hold this lock.
    pub fn discard(&self, paths: &SessionPaths) {
        let _ = std::fs::remove_file(&paths.record);
    }
}

/// Another instance holds the launch lock.
#[derive(Debug)]
pub struct Busy;

impl std::fmt::Display for Busy {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "another Atlas window is starting an install; wait a moment and try again")
    }
}

impl std::error::Error for Busy {}

fn is_sharing_violation(error: &std::io::Error) -> bool {
    const ERROR_SHARING_VIOLATION: i32 = 32;
    error.raw_os_error() == Some(ERROR_SHARING_VIOLATION)
        || error.kind() == std::io::ErrorKind::AlreadyExists
        || error.kind() == std::io::ErrorKind::PermissionDenied
}

/// Where this app's executable is, written when an install starts so the
/// payload's first-logon setup can open the completion window after the
/// restart. Lives beside the session record.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LauncherRecord {
    pub exe: PathBuf,
    pub version: String,
    pub written_at: String,
}

pub fn launcher_path(paths: &SessionPaths) -> PathBuf {
    paths.record.with_file_name("launcher.json")
}

pub fn record_launcher(paths: &SessionPaths) -> Result<LauncherRecord> {
    let exe = super::recovery_app::stage().context("stage the installation recovery executable")?;
    let record = LauncherRecord {
        exe,
        version: env!("CARGO_PKG_VERSION").to_owned(),
        written_at: chrono::Local::now().to_rfc3339(),
    };
    let path = launcher_path(paths);
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    std::fs::write(&path, serde_json::to_string_pretty(&record)?)
        .with_context(|| format!("write {}", path.display()))?;
    Ok(record)
}

pub fn load_launcher(paths: &SessionPaths) -> Result<Option<LauncherRecord>> {
    let text = match std::fs::read_to_string(launcher_path(paths)) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error.into()),
    };
    Ok(Some(serde_json::from_str(text.trim_start_matches('\u{feff}'))?))
}

/// Removes the record only if it still describes session `id`. A newer
/// session's record (another window's live install) is left alone. Returns
/// whether a record was removed.
pub fn release(paths: &SessionPaths, id: &str) -> Result<bool> {
    let lock = LaunchLock::acquire(paths)?;
    let matches = match lock.inspect(paths) {
        Inspection::Live(record) | Inspection::Ended(record) => record.id == id,
        Inspection::None | Inspection::Abandoned => false,
        Inspection::Unreadable(problem) => anyhow::bail!("the install record cannot be read: {problem}"),
    };
    if matches {
        lock.discard(paths);
    }
    Ok(matches)
}

// RunOnce is consumed when Explorer restarts during installation. Keep this entry
// through same-boot launches, then remove it on the next boot even after failure.
const COMPLETION_RUN_KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Run";

#[cfg(not(test))]
pub fn register_completion() -> Result<()> {
    // The ISO shell supervisor owns this sign-in and its completion page.
    // A Run entry would create a second window when Explorer starts behind it.
    if super::desktop_setup::active() {
        return Ok(());
    }
    let exe = super::recovery_app::stage()?;
    windows_registry::CURRENT_USER
        .create(COMPLETION_RUN_KEY)?
        .set_string("AtlasInstallCompletion", format!("\"{}\" --after-install-restart", exe.display()))?;
    Ok(())
}

pub fn completion_after_restart(paths: &SessionPaths) -> Result<bool> {
    let Some(launcher) = load_launcher(paths)? else {
        return Ok(false);
    };
    if !system::booted_since(&launcher.written_at) {
        return Ok(false);
    }
    let key = windows_registry::CURRENT_USER.create(COMPLETION_RUN_KEY)?;
    let _ = key.remove_value("AtlasInstallCompletion");
    let installed = super::atlas_state::read()?.and_then(|s| s.installed_at);
    Ok(completion_matches(&launcher.written_at, installed.as_deref()))
}

fn completion_matches(requested: &str, installed: Option<&str>) -> bool {
    let requested = super::atlas_state::parse_timestamp(requested);
    let installed = installed.and_then(super::atlas_state::parse_timestamp);
    matches!((requested, installed), (Some(requested), Some(installed)) if installed >= requested)
}

#[cfg(test)]
mod completion_tests {
    use super::completion_matches;
    #[test]
    fn completion_requires_a_success_newer_than_the_launch_request() {
        let request = "2026-09-06T18:00:00Z";
        assert!(!completion_matches(request, None));
        assert!(!completion_matches(request, Some("2026-09-05T18:00:00Z")));
        assert!(!completion_matches("invalid", Some(request)));
        assert!(completion_matches(request, Some("2026-09-06T19:05:00+01:00")));
    }
}
