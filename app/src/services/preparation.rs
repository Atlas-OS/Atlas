//! Windows and Store preparation. The worker reports provider completion,
//! never treats starting an update scan as a successful update.
use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    },
    time::{SystemTime, UNIX_EPOCH},
};

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Stage {
    #[default]
    WindowsSearch,
    WindowsDownload,
    WindowsInstall,
    StoreSearch,
    StoreInstall,
    Verify,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Running,
    Complete,
    Reboot,
    Failed,
    Cancelled,
    Network,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Eq)]
pub struct Progress {
    pub schema: u32,
    pub status: Status,
    pub stage: Stage,
    pub completed: u32,
    pub total: u32,
    #[serde(default)]
    pub pid: u32,
    #[serde(default, rename = "processStart")]
    pub process_start: u64,
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum State {
    #[default]
    Idle,
    Running {
        stage: Stage,
        completed: u32,
        total: u32,
    },
    WaitingExternal,
    Ready,
    Reboot,
    Restarting,
    Failed,
    Cancelled,
    Network,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Drivers {
    #[default]
    Automatic,
    Manual,
}
impl Drivers {
    pub fn argument(self) -> &'static str {
        match self {
            Self::Automatic => "automatic",
            Self::Manual => "manual",
        }
    }
    pub fn policy(self) -> &'static [u8] {
        match self {
            Self::Automatic => include_bytes!(
                "../../../playbook/Executables/AtlasDesktop/2. Drivers/Drivers from Windows Update/Enable Drivers from Windows Update.reg"
            ),
            Self::Manual => include_bytes!(
                "../../../playbook/Executables/AtlasDesktop/2. Drivers/Drivers from Windows Update/Disable Drivers from Windows Update.reg"
            ),
        }
    }
}

pub fn existing_driver_policy() -> Drivers {
    let blocked = [
        (r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate", "ExcludeWUDriversInQualityUpdate"),
        (r"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", "ExcludeWUDriversInQualityUpdate"),
        (r"SOFTWARE\Microsoft\PolicyManager\current\device\Update", "ExcludeWUDriversInQualityUpdate"),
        (r"SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState", "ExcludeWUDrivers"),
        (r"SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching", "DontSearchWindowsUpdate"),
    ]
    .iter()
    .any(|(path, value)| {
        windows_registry::LOCAL_MACHINE.open(path).ok().and_then(|key| key.get_u32(value).ok()) == Some(1)
    });
    if blocked { Drivers::Manual } else { Drivers::Automatic }
}
impl State {
    pub fn busy(&self) -> bool {
        matches!(self, Self::Running { .. } | Self::WaitingExternal | Self::Restarting)
    }
    pub fn ready(&self) -> bool {
        matches!(self, Self::Ready)
    }
}

pub fn new_job(settings: &Path) -> Result<PathBuf> {
    let root = super::recovery_app::preparation_root(settings)?;
    let id = SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos();
    let job = root.join(format!("{}-{id}", std::process::id()));
    Ok(job)
}

fn parse_event(line: &str) -> Option<Progress> {
    let event: Progress = serde_json::from_str(line.strip_prefix("ATLAS_PREP:")?).ok()?;
    (event.schema == 1 && event.completed <= event.total).then_some(event)
}

#[derive(Clone, Debug)]
pub struct RunningJob {
    pub directory: PathBuf,
    pub pid: u32,
    pub process_start: u64,
    pub trusted: bool,
}

fn read_progress(job: &Path) -> Option<Progress> {
    let text = fs::read_to_string(job.join("state.json")).ok()?;
    parse_event(&format!("ATLAS_PREP:{}", text.trim_start_matches('\u{feff}')))
}

/// Discover only journals from this user's app directory and still-identical processes.
pub fn recover_running(settings: &Path) -> Result<Option<RunningJob>> {
    let root = super::recovery_app::preparation_root(settings)?;
    if let Some(job) = scan_running(&root, true)? {
        return Ok(Some(job));
    }
    let legacy = settings.parent().context("settings directory")?.join("Preparation");
    if legacy != root {
        return scan_running(&legacy, false);
    }
    Ok(None)
}

fn scan_running(root: &Path, trusted: bool) -> Result<Option<RunningJob>> {
    let entries = match fs::read_dir(root) {
        Ok(entries) => entries,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).context("read preparation recovery journals"),
    };
    for entry in entries {
        let entry = entry?;
        let name = entry.file_name();
        let name = name.to_string_lossy();
        if !name.split_once('-').is_some_and(|(pid, stamp)| {
            !pid.is_empty()
                && !stamp.is_empty()
                && pid.bytes().chain(stamp.bytes()).all(|b| b.is_ascii_digit())
        }) {
            continue;
        }
        if !entry.file_type()?.is_dir() {
            continue;
        }
        #[cfg(windows)]
        {
            use std::os::windows::fs::MetadataExt;
            if entry.metadata()?.file_attributes() & 0x400 != 0 {
                continue;
            }
        }
        let Some(progress) = read_progress(&entry.path()) else { continue };
        if progress.pid == 0 || (trusted && progress.process_start == 0) {
            continue;
        }
        if super::system::process_liveness(progress.pid, progress.process_start)
            != super::system::Liveness::Ended
        {
            let trusted = trusted && super::recovery_app::validate_preparation(&entry.path()).is_ok();
            return Ok(Some(RunningJob {
                directory: entry.path(),
                pid: progress.pid,
                process_start: progress.process_start,
                trusted,
            }));
        }
    }
    Ok(None)
}

pub fn monitor(job: RunningJob, cancel: Arc<AtomicBool>, report: impl FnMut(Progress)) -> Result<State> {
    if !job.trusted {
        while super::system::process_liveness(job.pid, job.process_start) != super::system::Liveness::Ended {
            std::thread::sleep(std::time::Duration::from_millis(250));
        }
        return Ok(State::Failed);
    }
    let stop = Arc::new(AtomicBool::new(false));
    let watcher = watch_cancel(cancel, stop.clone(), job.directory.join("cancel"));
    let state = monitor_with(&job, report, || super::system::process_liveness(job.pid, job.process_start));
    stop.store(true, Ordering::Relaxed);
    let _ = watcher.join();
    state
}

fn watch_cancel(
    cancel: Arc<AtomicBool>,
    stop: Arc<AtomicBool>,
    path: PathBuf,
) -> std::thread::JoinHandle<()> {
    std::thread::spawn(move || {
        let mut reported = false;
        while !stop.load(Ordering::Relaxed) {
            if cancel.load(Ordering::Relaxed) {
                // Open only the precreated marker; its protected parent forbids replacement.
                match write_cancel(&path) {
                    Ok(()) => break,
                    Err(error) if !reported => {
                        log::error!("could not request preparation cancellation: {error}; retrying");
                        reported = true;
                    }
                    Err(_) => {}
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
    })
}

fn write_cancel(path: &Path) -> std::io::Result<()> {
    use std::io::Write;
    let mut options = fs::OpenOptions::new();
    options.write(true);
    #[cfg(windows)]
    {
        use std::os::windows::fs::OpenOptionsExt;
        options.custom_flags(0x00200000); // FILE_FLAG_OPEN_REPARSE_POINT
    }
    let mut file = options.open(path)?;
    #[cfg(windows)]
    {
        use std::os::windows::fs::MetadataExt;
        if file.metadata()?.file_attributes() & 0x400 != 0 {
            return Err(std::io::Error::new(
                std::io::ErrorKind::PermissionDenied,
                "Linked cancellation files are not supported",
            ));
        }
    }
    file.set_len(0)?;
    file.write_all(b"cancel")
}

fn monitor_with(
    job: &RunningJob,
    mut report: impl FnMut(Progress),
    mut liveness: impl FnMut() -> super::system::Liveness,
) -> Result<State> {
    let mut last: Option<Progress> = None;
    loop {
        let ended = liveness() == super::system::Liveness::Ended;
        if let Some(progress) = read_progress(&job.directory)
            && progress.pid == job.pid
            && progress.process_start == job.process_start
            && last.as_ref() != Some(&progress)
        {
            report(progress.clone());
            last = Some(progress);
        }
        if ended {
            break;
        }
        std::thread::sleep(std::time::Duration::from_millis(250));
    }
    Ok(match last.map(|p| p.status) {
        Some(Status::Complete) => State::Ready,
        Some(Status::Reboot) => State::Reboot,
        Some(Status::Cancelled) => State::Cancelled,
        Some(Status::Network) => State::Network,
        _ => State::Failed,
    })
}

pub fn run(
    job: &Path,
    drivers: Drivers,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Progress),
) -> Result<State> {
    if cfg!(test) {
        bail!("Real Windows servicing is disabled in unit tests");
    }
    if !super::desktop_setup::active() {
        super::recovery_app::stage().context("prepare a local app copy before Windows updates")?;
    }
    let script = job.join("Update-Windows.ps1");
    super::recovery_app::stage_preparation(
        job,
        include_str!("../../../playbook/Executables/AtlasModules/Scripts/Preparation/Update-Windows.ps1"),
        drivers.policy(),
    )?;
    let log = fs::File::create(job.join("worker.log"))?;
    let mut command = Command::new(super::system::powershell_path());
    command
        .args(["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"])
        .arg(&script)
        .arg("-JobPath")
        .arg(job)
        .arg("-PersistentCancellation")
        .args(["-DriverMode", drivers.argument()])
        .stdout(Stdio::from(log.try_clone()?))
        .stderr(Stdio::from(log.try_clone()?));
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    let mut child = command.spawn().context("start Windows preparation")?;
    let pid = child.id();
    let Some(process_start) = super::system::process_start_time(pid) else {
        let stop = Arc::new(AtomicBool::new(false));
        let watcher = watch_cancel(cancel, stop.clone(), job.join("cancel"));
        let waited = child.wait();
        stop.store(true, Ordering::Relaxed);
        let _ = watcher.join();
        waited?;
        bail!("Could not verify the preparation process identity; check diagnostics before retrying");
    };
    let result =
        monitor(RunningJob { directory: job.to_owned(), pid, process_start, trusted: true }, cancel, report);
    let exit = child.wait()?;
    if !exit.success() {
        bail!("Windows preparation failed; see {}", job.join("updates.log").display());
    }
    result
}

/// Register immediately before the user-requested restart. The existing
/// install draft retains the selected package and choices across elevation.
pub struct ResumeRegistration {
    command: String,
    previous: Option<String>,
}

const RESUME_KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\RunOnce";
const RESUME_VALUE: &str = "!AtlasWindowsPreparation";

pub fn register_resume() -> Result<Option<ResumeRegistration>> {
    if super::desktop_setup::active() {
        return Ok(None);
    }
    let exe = super::recovery_app::stage()?;
    register_at(&windows_registry::CURRENT_USER.create(RESUME_KEY)?, &exe).map(Some)
}

fn register_at(key: &windows_registry::Key, exe: &Path) -> Result<ResumeRegistration> {
    // Normal startup restores the saved draft. A forced step can start a new
    // flow before asynchronous recovery finishes and replace its saved package.
    let command = format!("\"{}\"", exe.display());
    anyhow::ensure!(
        command.encode_utf16().count() < 260,
        "Recovery command exceeds the Windows RunOnce limit"
    );
    let previous = match key.get_string(RESUME_VALUE) {
        Ok(previous) => Some(previous),
        Err(error) if error.code().0 == 0x8007_0002_u32 as i32 => None,
        Err(error) => return Err(error.into()),
    };
    key.set_string(RESUME_VALUE, &command)?;
    Ok(ResumeRegistration { command, previous })
}

pub fn undo_resume(registration: &ResumeRegistration) -> Result<()> {
    undo_at(&windows_registry::CURRENT_USER.create(RESUME_KEY)?, registration)
}

fn undo_at(key: &windows_registry::Key, registration: &ResumeRegistration) -> Result<()> {
    if key.get_string(RESUME_VALUE).ok().as_deref() == Some(&registration.command) {
        match &registration.previous {
            Some(previous) => key.set_string(RESUME_VALUE, previous)?,
            None => key.remove_value(RESUME_VALUE)?,
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cancellation_only_writes_an_existing_marker() {
        let temp = super::super::test_support::TempDir::new("persistent-cancel");
        let marker = temp.path().join("cancel");
        assert_eq!(write_cancel(&marker).unwrap_err().kind(), std::io::ErrorKind::NotFound);
        assert!(!marker.exists());
        fs::write(&marker, "").unwrap();
        write_cancel(&marker).unwrap();
        assert_eq!(fs::read_to_string(&marker).unwrap(), "cancel");
    }

    fn journal(job: &Path, pid: u32, start: u64, status: &str) {
        fs::create_dir_all(job).unwrap();
        fs::write(
            job.join("state.json"),
            serde_json::to_vec(&serde_json::json!({
                "schema":1, "status":status, "stage":"verify", "completed":0,"total":0,
                "pid":pid,"processStart":start
            }))
            .unwrap(),
        )
        .unwrap();
    }

    #[test]
    fn recovery_matches_creation_time_and_does_not_adopt_stale_success() {
        let temp = super::super::test_support::TempDir::new("preparation-recovery");
        let settings = temp.path().join("settings.json");
        let job = temp.path().join("Preparation/123-456");
        let pid = std::process::id();
        let start = super::super::system::process_start_time(pid).unwrap();
        journal(&job, pid, start, "running");
        let recovered = recover_running(&settings).unwrap().unwrap();
        assert_eq!(recovered.directory, job);
        journal(&job, pid, start + 1, "complete");
        assert!(recover_running(&settings).unwrap().is_none());
        assert_eq!(
            monitor_with(&recovered, |_| {}, || super::super::system::Liveness::Ended).unwrap(),
            State::Failed
        );
        journal(&job, pid, start, "complete");
        let mut reads = 0;
        let result = monitor_with(
            &recovered,
            |_| {},
            || {
                reads += 1;
                if reads == 1 {
                    super::super::system::Liveness::Unknown("access denied".into())
                } else {
                    super::super::system::Liveness::Ended
                }
            },
        )
        .unwrap();
        assert_eq!(reads, 2, "unknown ownership must not release the operation");
        assert_eq!(result, State::Ready);
    }

    #[test]
    fn a_reopened_monitor_can_stop_a_real_harmless_worker_without_owning_its_stdout() {
        let temp = super::super::test_support::TempDir::new("preparation-orphan");
        let job = temp.path().join("Preparation/123-456");
        fs::create_dir_all(&job).unwrap();
        fs::write(job.join("cancel"), "").unwrap();
        let script = job.join("fixture.ps1");
        fs::write(&script, r#"
$record = @{schema=1;status='running';stage='verify';completed=0;total=0;pid=$PID;processStart=[Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().ToFileTimeUtc()}
$record | ConvertTo-Json -Compress | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'state.json')
[Console]::WriteLine('started')
$deadline = [DateTime]::UtcNow.AddSeconds(10)
while ((Get-Content -LiteralPath (Join-Path $PSScriptRoot 'cancel') -Raw) -cne 'cancel' -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 25 }
$record.status = 'cancelled'
$record | ConvertTo-Json -Compress | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'state.json')
[Console]::WriteLine('stopped')
"#).unwrap();
        let output = fs::File::create(job.join("worker.log")).unwrap();
        let mut command = Command::new(super::super::system::powershell_path());
        command
            .args(["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"])
            .arg(script)
            .stdout(Stdio::from(output));
        #[cfg(windows)]
        {
            use std::os::windows::process::CommandExt;
            command.creation_flags(0x08000000);
        }
        let mut child = command.spawn().unwrap();
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        let recovered = loop {
            if let Some(job) = recover_running(&temp.path().join("settings.json")).unwrap() {
                break job;
            }
            assert!(std::time::Instant::now() < deadline, "worker did not publish its identity");
            std::thread::sleep(std::time::Duration::from_millis(25));
        };
        let state = monitor(recovered, Arc::new(AtomicBool::new(true)), |_| {}).unwrap();
        assert_eq!(state, State::Cancelled);
        assert!(child.wait().unwrap().success());
        let log = fs::read_to_string(job.join("worker.log")).unwrap();
        assert!(log.contains("started") && log.contains("stopped"));
    }

    #[test]
    fn restart_rollback_restores_only_the_registration_it_created() {
        let path = format!(
            r"Software\AtlasOS\AppTests\Resume-{}-{}",
            std::process::id(),
            SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos()
        );
        let key = windows_registry::CURRENT_USER.create(&path).unwrap();
        let registration =
            register_at(&key, Path::new(r"C:\Program Files\Atlas Setup Recovery\hash\AtlasManager.exe"))
                .unwrap();
        assert!(key.get_string(RESUME_VALUE).unwrap().starts_with('"'));
        assert_eq!(
            key.get_string(RESUME_VALUE).unwrap(),
            r#""C:\Program Files\Atlas Setup Recovery\hash\AtlasManager.exe""#
        );
        undo_at(&key, &registration).unwrap();
        assert!(key.get_string(RESUME_VALUE).is_err());
        key.set_string(RESUME_VALUE, "previous registration").unwrap();
        let registration = register_at(&key, Path::new(r"C:\recovery\AtlasManager.exe")).unwrap();
        undo_at(&key, &registration).unwrap();
        assert_eq!(key.get_string(RESUME_VALUE).unwrap(), "previous registration");
        key.set_string(RESUME_VALUE, "newer registration").unwrap();
        undo_at(&key, &registration).unwrap();
        assert_eq!(key.get_string(RESUME_VALUE).unwrap(), "newer registration");
        drop(key);
        windows_registry::CURRENT_USER.remove_tree(path).unwrap();
    }
    #[test]
    fn protocol_requires_a_known_state_and_valid_counts() {
        assert!(
            parse_event(
                r#"ATLAS_PREP:{"schema":1,"status":"complete","stage":"verify","completed":0,"total":0}"#
            )
            .is_some()
        );
        for line in [
            r#"ATLAS_PREP:{"schema":1,"status":"started","stage":"verify","completed":0,"total":0}"#,
            r#"ATLAS_PREP:{"schema":1,"status":"complete","stage":"verify","completed":2,"total":1}"#,
        ] {
            assert!(parse_event(line).is_none());
        }
    }
    #[test]
    fn only_provider_completion_satisfies_preparation() {
        for state in [
            State::Idle,
            State::Failed,
            State::Reboot,
            State::Cancelled,
            State::Network,
            State::Running { stage: Stage::StoreSearch, completed: 0, total: 0 },
        ] {
            assert!(!state.ready());
        }
        assert!(State::Ready.ready());
    }
}
