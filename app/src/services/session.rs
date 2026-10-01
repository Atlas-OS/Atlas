//! The on-disk record of an install that has been started: which process is
//! running it, where its output goes, and where its exit code is written.
//! The record outlives the window, so a reopened app can find the install
//! again instead of assuming nothing is running.

use std::fs::{File, OpenOptions};
use std::os::windows::fs::OpenOptionsExt;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use windows::Win32::Foundation::ERROR_SHARING_VIOLATION;

use super::installer::InstallRequest;
use super::{files, registry, system};

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

    /// Created once the record is written; the wrapper runs the front door
    /// only after it appears.
    pub fn go_path(&self) -> PathBuf {
        self.exit_path.with_extension("go")
    }

    /// Where the machine log ended when this install started.
    pub fn machine_offset_path(&self) -> PathBuf {
        self.log_path.with_extension("machine-offset")
    }
}

pub fn load(paths: &SessionPaths) -> Result<Option<SessionRecord>> {
    files::read_json(&paths.record)
}

pub fn save(paths: &SessionPaths, record: &SessionRecord) -> Result<()> {
    files::write_json_atomically(&paths.record, record)
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
    /// How long [`acquire`](Self::acquire) waits for another window's launch
    /// to finish committing.
    pub const WAIT: Duration = Duration::from_secs(5);

    pub fn acquire(paths: &SessionPaths) -> Result<Self> {
        Self::acquire_within(paths, Self::WAIT)
    }

    /// Waits at most `wait` for the lock; [`Busy`] if it is still held.
    pub fn acquire_within(paths: &SessionPaths, wait: Duration) -> Result<Self> {
        const RETRY: Duration = Duration::from_millis(50);
        let deadline = Instant::now() + wait;
        loop {
            match Self::try_acquire(paths) {
                Ok(lock) => return Ok(lock),
                Err(error) if error.is::<Busy>() && Instant::now() < deadline => std::thread::sleep(RETRY),
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
        options.read(true).write(true).create(true).truncate(false).share_mode(0);
        match options.open(&path) {
            Ok(file) => Ok(Self { _file: file }),
            Err(error) if error.raw_os_error() == Some(ERROR_SHARING_VIOLATION.0 as i32) => Err(Busy.into()),
            Err(error) => Err(error).with_context(|| format!("open {}", path.display())),
        }
    }

    /// The current record, classified.
    pub fn inspect(&self, paths: &SessionPaths) -> Inspection {
        match load(paths) {
            Ok(None) => Inspection::None,
            Ok(Some(record)) if record.is_pending() => Inspection::Abandoned,
            Ok(Some(record)) => {
                let liveness = record.liveness();
                classify(record, liveness)
            }
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

/// A committed record, by what Windows says about its process.
fn classify(record: SessionRecord, liveness: system::Liveness) -> Inspection {
    match liveness {
        system::Liveness::Alive => Inspection::Live(record),
        system::Liveness::Ended => Inspection::Ended(record),
        // The wrapper writes the exit file only after the front door has
        // returned, so whatever holds that process id now (after a restart,
        // a process this user may not query) is not the installer.
        system::Liveness::Unknown(_) if record.exit_code().is_some() => Inspection::Ended(record),
        // Windows would not say whether the process runs: the record's
        // owner is unknown, exactly as when it cannot be read.
        system::Liveness::Unknown(problem) => {
            log::warn!("the install session's process cannot be queried: {problem}");
            Inspection::Unreadable(problem)
        }
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

/// Which copy of the app shows the result of the install started at
/// `written_at`. Read by the completion Run entry after the restart and, for
/// `exe`, by Atlas's new-user script. Lives beside the session record.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LauncherRecord {
    pub exe: PathBuf,
    /// The app version that wrote it, for people reading the file.
    pub version: String,
    pub written_at: String,
}

pub fn launcher_path(paths: &SessionPaths) -> PathBuf {
    paths.record.with_file_name("launcher.json")
}

/// Arms the completion window for an install that has just started: the
/// recovery copy of this app is staged once, recorded in `launcher.json`,
/// and registered to open after the restart. Staging runs Windows
/// PowerShell, so this belongs on a worker.
pub fn arm_completion(paths: &SessionPaths) -> Result<()> {
    let exe = super::recovery_app::stage().context("stage the installation recovery executable")?;
    write_launcher(paths, &exe)?;
    register_completion(&exe)
}

/// Writes `launcher.json` for an install starting now, naming `exe`.
pub fn write_launcher(paths: &SessionPaths, exe: &Path) -> Result<LauncherRecord> {
    let record = LauncherRecord {
        exe: exe.to_path_buf(),
        version: env!("CARGO_PKG_VERSION").to_owned(),
        written_at: chrono::Local::now().to_rfc3339(),
    };
    files::write_json_atomically(&launcher_path(paths), &record)?;
    Ok(record)
}

pub fn load_launcher(paths: &SessionPaths) -> Result<Option<LauncherRecord>> {
    files::read_json(&launcher_path(paths))
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

/// The Run entry that reopens this app after the install's restart. It stays
/// through launches in the same boot and is removed after the restart,
/// whatever the result.
const COMPLETION_RUN_VALUE: &str = "AtlasInstallCompletion";

#[cfg(not(test))]
fn register_completion(exe: &Path) -> Result<()> {
    // On a PC installed from Atlas media, the before-desktop app owns this
    // sign-in and shows the result itself; a Run entry would open a second
    // window once Explorer starts.
    if super::desktop_setup::active() {
        return Ok(());
    }
    windows_registry::CURRENT_USER
        .create(registry::RUN_KEY)?
        .set_string(COMPLETION_RUN_VALUE, format!("\"{}\" --after-install-restart", exe.display()))?;
    Ok(())
}

/// Tests never register anything that runs at sign-in.
#[cfg(test)]
fn register_completion(_exe: &Path) -> Result<()> {
    Ok(())
}

/// Removes the Run entry that reopens this app after the restart. An install
/// that failed or was abandoned owes no completion window, and one that has
/// been shown must not come back at every sign-in. An entry that is already
/// gone is fine.
#[cfg(not(test))]
pub fn unregister_completion() -> Result<()> {
    let key = windows_registry::CURRENT_USER.create(registry::RUN_KEY)?;
    registry::remove_value(&key, COMPLETION_RUN_VALUE)
}

#[cfg(test)]
pub fn unregister_completion() -> Result<()> {
    Ok(())
}

/// What a launch from the completion Run entry does. Deciding only reads;
/// the entry is removed by [`clear_completion`], once sign-in has had time to
/// start the other programs the key lists.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Completion {
    /// Windows hasn't restarted since the install started (a sign-out, an
    /// Explorer restart): nothing opens, and the entry stays.
    Wait,
    /// Windows has restarted since, and the install finished: the
    /// completion window opens, and the entry goes.
    Show,
    /// The entry has had its chance, or nothing usable says when the
    /// install started: nothing opens, and the entry goes.
    Clear,
}

/// Decides what the launch from the completion Run entry does: the
/// completion window shows only after Windows has restarted since the
/// install started, and only for an install recorded as newer than that
/// start.
pub fn completion_after_restart(paths: &SessionPaths) -> Completion {
    let launcher = load_launcher(paths).unwrap_or_else(|error| {
        log::warn!("could not read {}: {error:#}", launcher_path(paths).display());
        None
    });
    completion_for(launcher.as_ref(), || Ok(super::atlas_state::read()?.and_then(|state| state.installed_at)))
}

fn completion_for(
    launcher: Option<&LauncherRecord>,
    installed_at: impl FnOnce() -> Result<Option<String>>,
) -> Completion {
    let Some(launcher) = launcher else { return Completion::Clear };
    if chrono::DateTime::parse_from_rfc3339(&launcher.written_at).is_ok()
        && !system::booted_since(&launcher.written_at)
    {
        return Completion::Wait;
    }
    match installed_at() {
        Ok(installed) if completion_matches(&launcher.written_at, installed.as_deref()) => Completion::Show,
        Ok(_) => Completion::Clear,
        Err(error) => {
            log::warn!("could not check for an installation to confirm: {error:#}");
            Completion::Clear
        }
    }
}

/// Whether this PC still owes the restart that finishes an install: the
/// install `launcher.json` was written for has finished (the state document
/// records an install since it started), and Windows hasn't restarted since.
/// It is the completion Run entry's [`Completion::Wait`], limited to an
/// install that succeeded, so it holds from the success until the restart
/// and survives relaunching the app without any state of its own.
/// `installed_at` is the state document's `installedAt`.
pub fn restart_owed(paths: &SessionPaths, installed_at: Option<&str>) -> bool {
    let launcher = load_launcher(paths).unwrap_or_else(|error| {
        log::warn!("could not read {}: {error:#}", launcher_path(paths).display());
        None
    });
    restart_owed_for(launcher.as_ref(), installed_at, system::booted_since)
}

fn restart_owed_for(
    launcher: Option<&LauncherRecord>,
    installed_at: Option<&str>,
    booted_since: impl FnOnce(&str) -> bool,
) -> bool {
    let Some(launcher) = launcher else { return false };
    chrono::DateTime::parse_from_rfc3339(&launcher.written_at).is_ok()
        && completion_matches(&launcher.written_at, installed_at)
        && !booted_since(&launcher.written_at)
}

/// Removes the completion Run entry once a launch from it has decided. A
/// failure is logged: the entry then fires at the next sign-in, which
/// decides again.
pub fn clear_completion() {
    if let Err(error) = unregister_completion() {
        log::error!("could not remove the completion Run entry: {error:#}");
    }
}

/// Where "Restart later" for install `record` is recorded, beside its log,
/// so every window following that install stops its own countdown. It is
/// never removed with the record: a Done in the window that declined must
/// not bring the restart back in another.
pub fn restart_declined_path(record: &SessionRecord) -> PathBuf {
    record.log_path.with_extension("restart-declined")
}

pub fn decline_restart(record: &SessionRecord) -> Result<()> {
    let path = restart_declined_path(record);
    std::fs::write(&path, "").with_context(|| format!("write {}", path.display()))
}

pub fn restart_declined(record: &SessionRecord) -> bool {
    restart_declined_path(record).exists()
}

fn completion_matches(requested: &str, installed: Option<&str>) -> bool {
    let requested = super::atlas_state::parse_timestamp(requested);
    let installed = installed.and_then(super::atlas_state::parse_timestamp);
    matches!((requested, installed), (Some(requested), Some(installed)) if installed >= requested)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::{TempDir, TestKey};

    /// Only another window holding the lock means "wait": a lock file that
    /// cannot be opened at all fails at once with its own cause.
    #[test]
    fn a_lock_that_cannot_be_opened_is_not_reported_as_another_window() {
        let temp = TempDir::new("session-lock-denied");
        let paths = SessionPaths::under(temp.path());
        // Windows refuses to open a directory as a file: access denied.
        std::fs::create_dir_all(paths.record.with_extension("lock")).unwrap();
        let error = LaunchLock::acquire_within(&paths, Duration::from_millis(200)).err().unwrap();
        assert!(!error.is::<Busy>(), "{error:#}");
    }

    #[test]
    fn completion_requires_a_success_newer_than_the_launch_request() {
        let request = "2026-09-06T18:00:00Z";
        assert!(!completion_matches(request, None));
        assert!(!completion_matches(request, Some("2026-09-05T18:00:00Z")));
        assert!(!completion_matches("invalid", Some(request)));
        assert!(completion_matches(request, Some("2026-09-06T19:05:00+01:00")));
    }

    #[test]
    fn the_completion_entry_waits_out_its_own_boot_and_shows_only_a_newer_install() {
        let launcher = |written_at: &str| LauncherRecord {
            exe: PathBuf::from(r"C:\Atlas\AtlasManager.exe"),
            version: "0.6.0".into(),
            written_at: written_at.into(),
        };
        let installed = |at: Option<&str>| {
            let at = at.map(str::to_owned);
            move || Ok(at)
        };
        let later = Some("2001-01-01T01:00:00Z");

        // A sign-out or Explorer restart in the install's own boot: nothing
        // opens, nothing else is read, and the entry stays.
        let now = launcher(&chrono::Local::now().to_rfc3339());
        assert_eq!(completion_for(Some(&now), || panic!("read in the install's own boot")), Completion::Wait);
        // The first launch after the restart, for the install that finished.
        let before_boot = launcher("2001-01-01T00:00:00Z");
        assert_eq!(completion_for(Some(&before_boot), installed(later)), Completion::Show);
        // No newer install recorded, or none readable: the entry has had its chance.
        assert_eq!(completion_for(Some(&before_boot), installed(None)), Completion::Clear);
        assert_eq!(
            completion_for(Some(&before_boot), installed(Some("2000-12-31T00:00:00Z"))),
            Completion::Clear
        );
        assert_eq!(completion_for(Some(&before_boot), || anyhow::bail!("unreadable")), Completion::Clear);
        // Nothing says when the install started.
        assert_eq!(completion_for(None, installed(later)), Completion::Clear);
        assert_eq!(completion_for(Some(&launcher("invalid")), installed(later)), Completion::Clear);
    }

    #[test]
    fn a_restart_is_owed_only_after_a_success_in_the_boot_it_started_in() {
        let launcher = LauncherRecord {
            exe: PathBuf::from(r"C:\Atlas\AtlasManager.exe"),
            version: "0.6.0".into(),
            written_at: "2026-10-01T09:00:00Z".into(),
        };
        let same_boot = |_: &str| false;
        let after_restart = |_: &str| true;
        let finished = Some("2026-10-01T09:20:00+00:00");
        // Succeeded, and Windows hasn't restarted since the install started.
        assert!(restart_owed_for(Some(&launcher), finished, same_boot));
        // Windows has restarted since: nothing is owed.
        assert!(!restart_owed_for(Some(&launcher), finished, after_restart));
        // The install failed or was abandoned: the state document records
        // nothing newer than its start, or nothing at all.
        assert!(!restart_owed_for(Some(&launcher), Some("2026-09-30T10:00:00Z"), same_boot));
        assert!(!restart_owed_for(Some(&launcher), None, same_boot));
        // No record of an install, or one that says nothing usable.
        assert!(!restart_owed_for(None, finished, same_boot));
        let unreadable = LauncherRecord { written_at: "invalid".into(), ..launcher.clone() };
        assert!(!restart_owed_for(Some(&unreadable), finished, same_boot));
    }

    #[test]
    fn the_restart_owed_reading_follows_the_launcher_record_on_disk() {
        let temp = TempDir::new("session-restart-owed");
        let paths = SessionPaths::under(temp.path());
        let later = (chrono::Local::now() + chrono::Duration::minutes(20)).to_rfc3339();
        assert!(!restart_owed(&paths, Some(&later)), "no install has started");
        // An install armed in this boot that has since finished.
        write_launcher(&paths, Path::new(r"C:\Atlas\AtlasManager.exe")).unwrap();
        assert!(restart_owed(&paths, Some(&later)));
        assert!(!restart_owed(&paths, None));
        // An install armed before this boot.
        let old = LauncherRecord {
            exe: PathBuf::from(r"C:\Atlas\AtlasManager.exe"),
            version: "0.6.0".into(),
            written_at: "2001-01-01T00:00:00Z".into(),
        };
        files::write_json_atomically(&launcher_path(&paths), &old).unwrap();
        assert!(!restart_owed(&paths, Some(&later)));
    }

    #[test]
    fn removing_the_completion_entry_tolerates_one_already_gone() {
        let test = TestKey::new("completion");
        test.key.set_string(COMPLETION_RUN_VALUE, "armed").unwrap();
        registry::remove_value(&test.key, COMPLETION_RUN_VALUE).unwrap();
        assert!(test.key.get_string(COMPLETION_RUN_VALUE).is_err());
        registry::remove_value(&test.key, COMPLETION_RUN_VALUE).unwrap();
    }

    #[test]
    fn a_process_windows_will_not_describe_has_ended_once_its_exit_code_is_written() {
        let temp = TempDir::new("session-unknown-liveness");
        let record = SessionRecord {
            id: "s".into(),
            pid: 4,
            process_start: 1,
            started_at: String::new(),
            log_path: temp.path().join("install-s.log"),
            exit_path: temp.path().join("install-s.exit"),
            request: InstallRequest { playbook_dir: temp.path().into(), options: vec![], restart: false },
        };
        let unknown = || system::Liveness::Unknown("open process 4: access denied".into());
        // Without a result the owner is unknown, and nothing may start.
        assert!(matches!(classify(record.clone(), unknown()), Inspection::Unreadable(_)));
        std::fs::write(&record.exit_path, "0").unwrap();
        assert!(matches!(classify(record.clone(), unknown()), Inspection::Ended(_)));
        assert!(matches!(classify(record.clone(), system::Liveness::Alive), Inspection::Live(_)));
    }

    #[test]
    fn the_launcher_record_names_the_given_executable() {
        let temp = TempDir::new("session-launcher");
        let paths = SessionPaths::under(temp.path());
        assert_eq!(load_launcher(&paths).unwrap(), None);
        let exe = Path::new(r"C:\Program Files\Atlas Setup Recovery\AtlasManager.exe");
        let written = write_launcher(&paths, exe).unwrap();
        assert_eq!(written.exe, exe);
        assert_eq!(written.version, env!("CARGO_PKG_VERSION"));
        assert_eq!(load_launcher(&paths).unwrap(), Some(written));
        // Atlas's new-user script reads `exe` from the JSON itself.
        let json: serde_json::Value =
            serde_json::from_str(&std::fs::read_to_string(launcher_path(&paths)).unwrap()).unwrap();
        assert_eq!(json["exe"], exe.to_str().unwrap());
        assert!(
            json["writtenAt"].as_str().is_some_and(|at| chrono::DateTime::parse_from_rfc3339(at).is_ok())
        );
    }
}
