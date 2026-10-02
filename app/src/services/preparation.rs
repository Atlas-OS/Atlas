//! Runs and follows the Windows Update and Microsoft Store worker. Only the
//! provider's own completion counts as ready; starting a scan never does.

use std::fs;
use std::io::{self, Write};
use std::os::windows::fs::OpenOptionsExt;
use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use windows::Win32::Storage::FileSystem::FILE_FLAG_OPEN_REPARSE_POINT;

use super::powershell::{self, CancelWatch};
use super::system::{self, Liveness};
use super::{files, recovery_app, registry};

/// The worker script, embedded so the app and the worker it drives always
/// agree on the journal and the failure causes it names.
pub(crate) const WORKER: &str =
    include_str!("../../../playbook/Executables/AtlasModules/Scripts/Preparation/Update-Windows.ps1");
/// The functions-only library the worker dot-sources for moving Windows to
/// another release and putting back the Windows Update settings it changed.
pub(crate) const LIBRARY: &str =
    include_str!("../../../playbook/Executables/AtlasModules/Scripts/Preparation/WindowsTransition.ps1");
/// The functions-only library that applies the drivers choice, shared by the
/// worker and ISO setup.
pub(crate) const REGISTRY_LIBRARY: &str =
    include_str!("../../../playbook/Executables/AtlasModules/Scripts/Preparation/RegistryFile.ps1");

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Stage {
    #[default]
    WindowsSearch,
    WindowsDownload,
    WindowsInstall,
    StoreSearch,
    /// Microsoft Store or App Installer updating itself, before the apps.
    StoreSelfUpdate,
    StoreInstall,
    /// Repairing a Microsoft Store that couldn't update.
    StoreRepair,
    Verify,
}

/// What a finished run did about Microsoft Store itself.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StoreOutcome {
    /// It was out of date and updated itself first.
    Updated,
    /// It couldn't update itself, so App Installer and the Store came from Microsoft.
    Bootstrapped,
    /// It wasn't working and a repair fixed it.
    Repaired,
    /// The user removed it, so Store app updates were skipped.
    SkippedRemoved,
}

impl StoreOutcome {
    pub fn id(self) -> &'static str {
        match self {
            Self::Updated => "store-updated",
            Self::Bootstrapped => "store-bootstrapped",
            Self::Repaired => "store-repaired",
            Self::SkippedRemoved => "store-skipped-removed",
        }
    }

    /// The outcome to keep when a later run reports `later`: a repair says
    /// more than the update it led to, as the worker keeps it within a run.
    pub fn then(self, later: Self) -> Self {
        if matches!(self, Self::Bootstrapped | Self::Repaired) && later == Self::Updated {
            self
        } else {
            later
        }
    }

    /// The worker's id for an outcome; `None` for one this build doesn't know.
    pub fn from_id(id: &str) -> Option<Self> {
        Some(match id {
            "store-updated" => Self::Updated,
            "store-bootstrapped" => Self::Bootstrapped,
            "store-repaired" => Self::Repaired,
            "store-skipped-removed" => Self::SkippedRemoved,
            _ => return None,
        })
    }
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
    #[serde(default, rename = "updatedAt")]
    pub updated_at: u64,
    #[serde(default)]
    pub activity: Activity,
    /// `commit` or `restore` for a short operation's worker (see
    /// [`Operation`]); none for a preparation run.
    #[serde(default)]
    pub operation: Option<String>,
}

/// Details the worker may add to its journal; all optional, so a journal
/// without them still parses.
#[derive(Clone, Debug, Default, Deserialize, PartialEq, Eq)]
#[serde(default, rename_all = "camelCase")]
pub struct Activity {
    pub failure_message: Option<String>,
    pub error_code: Option<String>,
    pub package_name: Option<String>,
    pub percent: Option<u32>,
    pub current_update: Option<String>,
    pub bytes_downloaded: Option<u64>,
    pub bytes_total: Option<u64>,
    pub elapsed_seconds: Option<u64>,
    /// Seconds since the provider's progress last changed. The journal is
    /// rewritten while it stays the same, so a fresh journal is not progress.
    pub unchanged_seconds: u64,
    /// What the worker is waiting for while progress can't move:
    /// `feature-offer` while Windows Update has yet to offer the new release.
    pub waiting: Option<String>,
    /// Which restart markers the worker saw when it asked for a restart
    /// (`servicing`, `windows-update`, `file-renames`, `update-agent`).
    pub restart_reasons: Vec<String>,
    /// A failure cause the app words itself, such as `store-missing`
    /// (see [`crate::i18n::describe::preparation_failure_reason`]).
    pub reason: Option<String>,
    /// Why the connection was refused: `offline`, `limited`, `metered` or
    /// `roaming`.
    pub network_reason: Option<String>,
    /// The setting or service that keeps Windows Update off (`feature-blocked`,
    /// `feature-managed`).
    pub setting: Option<String>,
    /// The drive and the space a Windows update needs (`feature-disk-space`),
    /// in whole gigabytes.
    pub drive: Option<String>,
    pub free_gb: Option<String>,
    pub needed_gb: Option<String>,
    /// Windows 11 hardware this PC lacks, comma-separated: `tpm`, `uefi`
    /// (`feature-hardware`).
    pub hardware: Option<String>,
    /// What a finished run did about Microsoft Store itself (see [`StoreOutcome`]).
    pub store_outcome: Option<String>,
}

impl Activity {
    /// Whether a move ended waiting for Windows Update rather than failing:
    /// Microsoft hasn't offered the release to this PC yet.
    pub fn not_offered(&self) -> bool {
        matches!(self.reason.as_deref(), Some("feature-not-offered" | "feature-prerequisite"))
    }
}

impl Progress {
    /// Only terminal failures may display error data from a journal.
    pub fn failure(&self) -> Option<&Activity> {
        (self.status == Status::Failed && self.activity.failure_message.is_some()).then_some(&self.activity)
    }

    pub fn fraction(&self) -> Option<f32> {
        self.activity.percent.map(|p| p as f32 / 100.).or_else(|| {
            (self.stage == Stage::StoreInstall && self.total > 0)
                .then(|| self.completed as f32 / self.total as f32)
        })
    }

    pub fn report_age(&self, now: u64) -> u64 {
        if self.updated_at == 0 { 0 } else { now.saturating_sub(self.updated_at) }
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum State {
    #[default]
    Idle,
    /// Windows restarted after preparation asked; it must run again.
    Resumed,
    Running {
        stage: Stage,
        completed: u32,
        total: u32,
    },
    /// A worker started by an earlier window is still running.
    WaitingExternal,
    Ready,
    Reboot,
    SavingRestart,
    Restarting,
    /// Windows asked for a restart again right after one, without any update
    /// work in between: a marker survives restarts, so another one is not
    /// offered. `reasons` names the markers the worker saw.
    RestartPersists {
        reasons: Vec<String>,
    },
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

/// Updates the worker installed successfully that Windows Update offered
/// again at once, by `"<update id>/<revision>"`: installing them again changes
/// nothing, so they no longer count as pending. The worker keeps the list
/// under HKLM, where only administrators write; entries older than 30 days
/// lapse.
pub fn reoffered_updates() -> std::collections::HashSet<String> {
    let text = windows_registry::LOCAL_MACHINE
        .open(r"SOFTWARE\AtlasOS\Preparation")
        .and_then(|key| key.get_string("Reoffered"))
        .unwrap_or_default();
    parse_reoffered(&text, chrono::Utc::now())
}

fn parse_reoffered(text: &str, now: chrono::DateTime<chrono::Utc>) -> std::collections::HashSet<String> {
    let entries: Vec<serde_json::Value> = match serde_json::from_str(text.trim_start_matches('\u{feff}')) {
        Ok(serde_json::Value::Array(entries)) => entries,
        Ok(entry @ serde_json::Value::Object(_)) => vec![entry],
        _ => return Default::default(),
    };
    entries
        .iter()
        .filter(|entry| {
            entry["at"].as_str().and_then(|at| chrono::DateTime::parse_from_rfc3339(at).ok()).is_some_and(
                |at| now.signed_duration_since(at.with_timezone(&chrono::Utc)) < chrono::Duration::days(30),
            )
        })
        .filter_map(|entry| entry["key"].as_str())
        .filter(|key| !key.is_empty() && key.len() <= 80 && !key.chars().any(char::is_control))
        .map(str::to_owned)
        .collect()
}

/// Manual when any Windows Update driver-exclusion policy is already set.
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
        matches!(self, Self::Running { .. } | Self::WaitingExternal | Self::SavingRestart | Self::Restarting)
    }

    /// The state a finished run settles into. A restart request that follows
    /// a restart Atlas already made, with no update work in between, means a
    /// marker survives restarts; it is named instead of restarting again.
    /// A restart that finishes a Windows version change is the exception:
    /// the worker bounds those itself.
    pub fn settle(self, after_restart: bool, did_work: bool, reasons: Vec<String>) -> Self {
        if self == Self::Reboot && after_restart && !did_work && !finishes_version_change(&reasons) {
            return Self::RestartPersists { reasons };
        }
        self
    }
    pub fn ready(&self) -> bool {
        matches!(self, Self::Ready)
    }
}

/// The restart reasons the worker names around a Windows version change:
/// the package is installed and needs a restart, or Windows needs one more
/// restart with Atlas's commit before it.
pub const FEATURE_UPDATE: &str = "feature-update";
pub const FEATURE_COMMIT: &str = "feature-commit";

/// Whether a restart request finishes a Windows version change, which
/// Atlas commits just before restarting.
pub fn finishes_version_change(reasons: &[String]) -> bool {
    reasons.iter().any(|reason| reason == FEATURE_UPDATE || reason == FEATURE_COMMIT)
}

/// A move to another Windows release for the worker to make, from
/// [`crate::services::windows_release::TRANSITIONS`].
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TransitionRequest {
    pub target_release: String,
    pub target_build: u32,
    pub sources: Vec<u32>,
    pub kbs: Vec<u32>,
    pub prerequisites: Vec<u32>,
    pub minimum_revision: u32,
    /// The user accepted Microsoft's licence terms for the target release.
    /// Without it the worker refuses before downloading anything.
    pub accept_license: bool,
    /// Only look for the offer again, while waiting for Windows Update.
    pub offer_only: bool,
}

impl TransitionRequest {
    pub fn new(transition: &super::windows_release::Transition, accept_license: bool) -> Self {
        Self {
            target_release: transition.target_release.to_owned(),
            target_build: transition.target_build,
            sources: transition.sources.to_vec(),
            kbs: transition.kbs.to_vec(),
            prerequisites: transition.prerequisites.to_vec(),
            minimum_revision: transition.minimum_revision,
            accept_license,
            offer_only: false,
        }
    }
}

/// What one preparation run does.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PreparationRequest {
    pub drivers: Drivers,
    pub transition: Option<TransitionRequest>,
    /// Turn Windows Update on for this run when it is off, paused or delayed.
    pub open_update_access: bool,
}

fn join_numbers(numbers: &[u32]) -> String {
    numbers.iter().map(u32::to_string).collect::<Vec<_>>().join(",")
}

/// The worker's arguments for `request`, after `-JobPath`.
pub fn worker_args(request: &PreparationRequest) -> Vec<String> {
    let mut args = vec![
        "-PersistentCancellation".to_owned(),
        "-DriverMode".to_owned(),
        request.drivers.argument().to_owned(),
    ];
    if let Some(transition) = &request.transition {
        args.extend([
            "-WindowsTarget".to_owned(),
            transition.target_release.clone(),
            "-TargetBuild".to_owned(),
            transition.target_build.to_string(),
            "-SourceBuilds".to_owned(),
            join_numbers(&transition.sources),
            "-FeatureKb".to_owned(),
            join_numbers(&transition.kbs),
            "-MinimumRevision".to_owned(),
            transition.minimum_revision.to_string(),
        ]);
        if !transition.prerequisites.is_empty() {
            args.extend(["-PrerequisiteKb".to_owned(), join_numbers(&transition.prerequisites)]);
        }
        if transition.accept_license {
            args.push("-AcceptLicense".to_owned());
        }
        if transition.offer_only {
            args.push("-OfferOnly".to_owned());
        }
    } else if request.open_update_access {
        args.push("-OpenWindowsUpdate".to_owned());
    }
    args
}

/// A short worker operation outside a preparation run.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Operation {
    /// Atlas's commit of a pending Windows version change, just before Atlas
    /// restarts Windows.
    Commit,
    /// Puts back the Windows Update settings an unfinished update changed.
    Restore,
}

impl Operation {
    fn switch(self) -> &'static str {
        match self {
            Self::Commit => "-CommitFeatureUpdate",
            Self::Restore => "-RestoreWindowsUpdate",
        }
    }
}

/// Runs `operation` in a protected job of its own and waits for it. An
/// error carries the worker's reason and message.
pub fn run_operation(settings: &Path, operation: Operation) -> Result<()> {
    if cfg!(test) {
        bail!("real Windows servicing is disabled in unit tests");
    }
    let job = new_job(settings)?;
    recovery_app::stage_preparation(&job, WORKER, LIBRARY, REGISTRY_LIBRARY, Drivers::Automatic.policy())?;
    let log = fs::File::create(job.join("worker.log"))?;
    let status = powershell::command()
        .arg("-File")
        .arg(job.join("Update-Windows.ps1"))
        .arg("-JobPath")
        .arg(&job)
        .arg("-PersistentCancellation")
        .arg(operation.switch())
        .stdout(Stdio::from(log.try_clone()?))
        .stderr(Stdio::from(log))
        .status()
        .with_context(|| format!("start {operation:?}"))?;
    let progress = read_progress(&job);
    match progress.as_ref().map(|progress| progress.status) {
        Some(Status::Complete) if status.success() => Ok(()),
        _ => {
            let activity = progress.map(|progress| progress.activity).unwrap_or_default();
            bail!(
                "{}{}",
                activity.reason.map(|reason| format!("{reason}: ")).unwrap_or_default(),
                activity.failure_message.unwrap_or_else(|| format!("the worker ended with {status}"))
            )
        }
    }
}

/// The reason id in an error from [`run_operation`], if the worker named one.
pub fn operation_reason(error: &str) -> Option<&str> {
    error.split_once(": ").map(|(reason, _)| reason).filter(|reason| reason.starts_with("feature-"))
}

pub fn new_job(settings: &Path) -> Result<PathBuf> {
    let root = recovery_app::preparation_root(settings)?;
    let id = SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos();
    let job = root.join(format!("{}-{id}", std::process::id()));
    Ok(job)
}

/// The start stamp of a job directory: one named `<pid>-<nanos>` that is a
/// real directory, never a link out of the protected root.
fn job_stamp(entry: &fs::DirEntry) -> std::io::Result<Option<u128>> {
    let name = entry.file_name();
    let name = name.to_string_lossy();
    let digits = |text: &str| !text.is_empty() && text.bytes().all(|b| b.is_ascii_digit());
    let Some((_, stamp)) = name.split_once('-').filter(|(pid, stamp)| digits(pid) && digits(stamp)) else {
        return Ok(None);
    };
    if !entry.file_type()?.is_dir() || files::is_reparse_point(&entry.metadata()?) {
        return Ok(None);
    }
    Ok(stamp.parse().ok())
}

/// Finished jobs kept for diagnostics.
const FINISHED_JOBS_KEPT: usize = 5;

/// Removes the directories of finished preparation jobs beyond the newest
/// few. A job counts as finished only when its journal reports a result and
/// its worker has ended; anything else, and `keep`, stays.
pub fn prune_jobs(settings: &Path, keep: Option<&Path>) -> Result<()> {
    prune_finished(&recovery_app::preparation_root(settings)?, keep, FINISHED_JOBS_KEPT)
}

fn prune_finished(root: &Path, keep: Option<&Path>, kept: usize) -> Result<()> {
    let entries = match fs::read_dir(root) {
        Ok(entries) => entries,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(()),
        Err(error) => return Err(error).context("read preparation jobs"),
    };
    let mut finished = Vec::new();
    for entry in entries.flatten() {
        let path = entry.path();
        let Ok(Some(stamp)) = job_stamp(&entry) else { continue };
        if keep == Some(path.as_path()) {
            continue;
        }
        let Some(progress) = read_progress(&path) else { continue };
        if progress.status == Status::Running
            || progress.pid == 0
            || progress.process_start == 0
            || system::process_liveness(progress.pid, progress.process_start) != Liveness::Ended
        {
            continue;
        }
        finished.push((stamp, path));
    }
    finished.sort_by_key(|(stamp, _)| std::cmp::Reverse(*stamp));
    for (_, path) in finished.into_iter().skip(kept) {
        if let Err(error) = fs::remove_dir_all(&path) {
            log::warn!("could not remove finished preparation job {}: {error}", path.display());
        }
    }
    Ok(())
}

fn parse_event(line: &str) -> Option<Progress> {
    let event: Progress = serde_json::from_str(line.strip_prefix("ATLAS_PREP:")?).ok()?;
    (event.schema == 1 && event.completed <= event.total && event.activity.percent.is_none_or(|p| p <= 100))
        .then_some(event)
}

#[derive(Clone, Debug)]
pub struct RunningJob {
    pub directory: PathBuf,
    pub pid: u32,
    pub process_start: u64,
    /// Windows confirmed the job directory is the protected one staging
    /// created; only then is its journal believed.
    pub trusted: bool,
}

fn read_progress(job: &Path) -> Option<Progress> {
    let text = fs::read_to_string(job.join("state.json")).ok()?;
    parse_event(&format!("ATLAS_PREP:{}", text.trim_start_matches('\u{feff}')))
}

/// A preparation worker still running from this user's job root, matched by
/// PID and start time.
pub fn recover_running(settings: &Path) -> Result<Option<RunningJob>> {
    let root = recovery_app::preparation_root(settings)?;
    let entries = match fs::read_dir(&root) {
        Ok(entries) => entries,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).context("read preparation recovery journals"),
    };
    for entry in entries {
        let entry = entry?;
        if job_stamp(&entry)?.is_none() {
            continue;
        }
        let Some(progress) = read_progress(&entry.path()) else { continue };
        // A commit or put-back still running is not a run to follow.
        if progress.pid == 0 || progress.process_start == 0 || progress.operation.is_some() {
            continue;
        }
        if system::process_liveness(progress.pid, progress.process_start) != Liveness::Ended {
            let trusted = recovery_app::validate_preparation(&entry.path()).is_ok();
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

/// How often a worker's liveness and journal are read.
const POLL: Duration = Duration::from_millis(250);
/// How often the last known report is sent again, so its age stays visible
/// while a worker writes nothing new.
const HEARTBEAT: Duration = Duration::from_secs(2);

pub fn monitor(job: RunningJob, cancel: Arc<AtomicBool>, report: impl FnMut(Progress)) -> Result<State> {
    if !job.trusted {
        while system::process_liveness(job.pid, job.process_start) != Liveness::Ended {
            std::thread::sleep(POLL);
        }
        return Ok(State::Failed);
    }
    let _watch = CancelWatch::start(cancel, job.directory.join("cancel"), write_cancel);
    monitor_with(&job, report, || system::process_liveness(job.pid, job.process_start), HEARTBEAT)
}

/// Writes the cancellation marker staging created in the protected job
/// directory. The file is only ever opened, never created, and a link in its
/// place is refused, so nothing else can stand in for it.
fn write_cancel(path: &Path) -> io::Result<()> {
    // Open a link itself, never its target.
    let mut file =
        fs::OpenOptions::new().write(true).custom_flags(FILE_FLAG_OPEN_REPARSE_POINT.0).open(path)?;
    if files::is_reparse_point(&file.metadata()?) {
        return Err(io::Error::new(
            io::ErrorKind::PermissionDenied,
            "linked cancellation files are not supported",
        ));
    }
    file.set_len(0)?;
    file.write_all(b"cancel")
}

fn monitor_with(
    job: &RunningJob,
    mut report: impl FnMut(Progress),
    mut liveness: impl FnMut() -> Liveness,
    heartbeat: Duration,
) -> Result<State> {
    let mut last: Option<Progress> = None;
    let mut reported = Instant::now();
    loop {
        let ended = liveness() == Liveness::Ended;
        if let Some(progress) = read_progress(&job.directory)
            && progress.pid == job.pid
            && progress.process_start == job.process_start
            && last.as_ref() != Some(&progress)
        {
            report(progress.clone());
            last = Some(progress);
            reported = Instant::now();
        }
        // Keep the age of the last known report visible even if a worker
        // stops writing or its newest journal cannot be read.
        if reported.elapsed() >= heartbeat {
            if let Some(progress) = &last {
                report(progress.clone());
            }
            reported = Instant::now();
        }
        if ended {
            break;
        }
        std::thread::sleep(POLL);
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
    request: &PreparationRequest,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Progress),
) -> Result<State> {
    if cfg!(test) {
        bail!("real Windows servicing is disabled in unit tests");
    }
    if !super::desktop_setup::active() {
        recovery_app::stage().context("prepare a local app copy before Windows updates")?;
    }
    recovery_app::stage_preparation(job, WORKER, LIBRARY, REGISTRY_LIBRARY, request.drivers.policy())?;
    let log = fs::File::create(job.join("worker.log"))?;
    log::info!("Windows preparation: {}", worker_args(request).join(" "));
    let mut child = powershell::command()
        .arg("-File")
        .arg(job.join("Update-Windows.ps1"))
        .arg("-JobPath")
        .arg(job)
        .args(worker_args(request))
        .stdout(Stdio::from(log.try_clone()?))
        .stderr(Stdio::from(log))
        .spawn()
        .context("start Windows preparation")?;
    let pid = child.id();
    let Some(process_start) = system::process_start_time(pid) else {
        let watch = CancelWatch::start(cancel, job.join("cancel"), write_cancel);
        let waited = child.wait();
        drop(watch);
        waited?;
        bail!("could not verify the preparation process identity; check diagnostics before retrying");
    };
    let result =
        monitor(RunningJob { directory: job.to_owned(), pid, process_start, trusted: true }, cancel, report);
    let exit = child.wait()?;
    if !exit.success() {
        return reported_failure(job, pid, process_start, result);
    }
    result
}

/// What a worker that exited with an error ended in: the failure its journal
/// reports, which Get ready words, or an error when it reported none. No
/// offer yet is logged as the outcome it is.
fn reported_failure(job: &Path, pid: u32, process_start: u64, result: Result<State>) -> Result<State> {
    let log = job.join("updates.log");
    if let Ok(State::Failed) = result
        && let Some(progress) = read_progress(job)
        && progress.pid == pid
        && progress.process_start == process_start
        && let Some(failure) = progress.failure()
    {
        let reason = failure.reason.as_deref().unwrap_or("none");
        let message = failure.failure_message.as_deref().unwrap_or_default();
        if failure.not_offered() {
            log::info!("Windows preparation ended without an offer ({reason}): {message}");
        } else {
            log::error!("Windows preparation failed ({reason}): {message}; see {}", log.display());
        }
        return Ok(State::Failed);
    }
    bail!("Windows preparation failed; see {}", log.display())
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RestartProblem {
    Save,
    Registration,
    /// Windows couldn't get the version change ready for the restart, so
    /// Atlas didn't restart.
    Commit,
    Restart,
}

/// The Run entry that reopens Atlas after preparation's restart. Like the
/// install completion entry, it waits out launches in the same boot (checked
/// against the saved restart time) and is removed after the restart or when
/// the draft is abandoned.
const RESUME_VALUE: &str = "AtlasWindowsPreparation";
/// A Run entry's command must stay under this many UTF-16 units.
const RUN_COMMAND_LIMIT: usize = 260;

pub fn register_resume() -> Result<()> {
    if super::desktop_setup::active() {
        return Ok(());
    }
    let exe = recovery_app::stage()?;
    register_at(&windows_registry::CURRENT_USER.create(registry::RUN_KEY)?, &exe)
}

fn register_at(key: &windows_registry::Key, exe: &Path) -> Result<()> {
    // No --page: normal startup restores the saved draft, while forcing a
    // page would start a new flow and lose the saved package.
    let command = format!("\"{}\" --after-preparation-restart", exe.display());
    anyhow::ensure!(
        command.encode_utf16().count() < RUN_COMMAND_LIMIT,
        "the recovery command exceeds the Windows Run limit"
    );
    key.set_string(RESUME_VALUE, &command)?;
    log::info!("Preparation recovery registered: {command}");
    Ok(())
}

pub fn state_after_restart(timestamp: Option<&str>) -> State {
    match timestamp {
        Some(timestamp) if system::booted_since(timestamp) => State::Resumed,
        Some(_) => State::Reboot,
        None => State::Idle,
    }
}

/// What a launch from the recovery Run entry does.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Resume {
    /// Windows has not restarted yet: stay silent and keep the entry.
    Wait,
    /// The draft no longer owes a restart: remove the entry and stay silent.
    Abandoned,
    /// Windows has restarted: open Atlas, then remove the entry.
    Open,
    /// The settings cannot be read: open Atlas so the problem is visible,
    /// and keep recovery armed.
    Unreadable,
}

/// How long a launch from the Run entry waits before removing it when
/// nothing else has taken that long already. Explorer may still be starting
/// the other programs under the key at sign-in, and a program it starts
/// should not write to the key meanwhile.
pub const RESUME_SETTLE: Duration = Duration::from_secs(20);

/// Decides what a launch from the recovery Run entry does. It only reads
/// the draft; the entry is removed by [`clear_resume`].
pub fn resume_after_restart(settings: &Path) -> Resume {
    let loaded = super::settings::read_from(settings);
    if loaded.problem.is_some() {
        return Resume::Unreadable;
    }
    let state = state_after_restart(
        loaded.settings.draft.as_ref().and_then(|draft| draft.preparation_restart_at.as_deref()),
    );
    log::info!("Preparation startup recovery: {state:?}");
    resume_for(state)
}

fn resume_for(state: State) -> Resume {
    match state {
        State::Reboot => Resume::Wait,
        State::Resumed => Resume::Open,
        _ => Resume::Abandoned,
    }
}

/// Removes the recovery Run entry. A failure is logged: the entry then fires
/// at the next sign-in, which decides again.
pub fn clear_resume() {
    let cleared = windows_registry::CURRENT_USER
        .create(registry::RUN_KEY)
        .map_err(anyhow::Error::from)
        .and_then(|key| registry::remove_value(&key, RESUME_VALUE));
    if let Err(error) = cleared {
        log::error!("could not remove the preparation recovery entry: {error:#}");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::{TempDir, TestKey};

    #[test]
    fn progress_recovers_legacy_journals_and_uses_only_provider_percentages() {
        let old =
            r#"ATLAS_PREP:{"schema":1,"status":"running","stage":"windows-install","completed":0,"total":5}"#;
        let old = parse_event(old).unwrap();
        assert_eq!(old.fraction(), None);
        assert_eq!(old.report_age(100), 0);
        let new = r#"ATLAS_PREP:{"schema":1,"status":"running","stage":"windows-download","completed":1,"total":5,"updatedAt":100,"activity":{"percent":37,"currentUpdate":"Cumulative update","bytesDownloaded":370,"bytesTotal":1000,"elapsedSeconds":65,"unchangedSeconds":60}}"#;
        let progress = parse_event(new).unwrap();
        assert_eq!(progress.fraction(), Some(0.37));
        assert_eq!(progress.activity.current_update.as_deref(), Some("Cumulative update"));
        assert_eq!(progress.activity.unchanged_seconds, 60);
        assert_eq!(progress.report_age(120), 20);
        assert_eq!(progress.report_age(90), 0);
        assert!(parse_event(&new.replace("\"percent\":37", "\"percent\":101")).is_none());
        assert!(parse_event(&new.replace("\"completed\":1", "\"completed\":6")).is_none());
        assert!(
            parse_event(
                r#"ATLAS_PREP:{"schema":1,"status":"started","stage":"verify","completed":0,"total":0}"#
            )
            .is_none(),
            "an unknown status"
        );
    }

    #[test]
    fn a_missing_journal_keeps_last_known_progress_aging_without_claiming_success() {
        let temp = TempDir::new("preparation-heartbeat");
        let job =
            RunningJob { directory: temp.path().to_owned(), pid: 123, process_start: 456, trusted: true };
        journal(&job.directory, job.pid, job.process_start, "running");
        let started = Instant::now();
        let mut reports = Vec::new();
        let result = monitor_with(
            &job,
            |event| {
                reports.push(event);
                let _ = fs::remove_file(job.directory.join("state.json"));
            },
            || if started.elapsed() >= Duration::from_millis(60) { Liveness::Ended } else { Liveness::Alive },
            Duration::from_millis(20),
        )
        .unwrap();
        assert!(reports.len() >= 2);
        assert_eq!(reports[0], reports[1], "a UI refresh must not fabricate provider activity");
        assert_eq!(result, State::Failed);
    }

    /// A worker exits with an error when a run stops, also when Windows
    /// Update only hasn't offered the new release yet. What it reported is
    /// the result Get ready words; only a worker that reported nothing is an
    /// error here.
    #[test]
    fn a_worker_that_reported_why_it_stopped_ends_failed_with_that_report() {
        let temp = TempDir::new("preparation-reported-failure");
        let job = temp.path();
        let write = |pid: u32, reason: Option<&str>| {
            let mut activity = serde_json::json!({ "reason": reason });
            if reason.is_some() {
                activity["failureMessage"] = "Windows Update does not offer 26H2 to this PC yet.".into();
            }
            fs::write(
                job.join("state.json"),
                serde_json::json!({
                    "schema":1,"status":"failed","stage":"windows-search","completed":0,"total":0,
                    "pid":pid,"processStart":7,"activity":activity
                })
                .to_string(),
            )
            .unwrap();
        };
        let failed = || Ok(State::Failed);
        for reason in ["feature-not-offered", "feature-failed"] {
            write(42, Some(reason));
            assert_eq!(reported_failure(job, 42, 7, failed()).unwrap(), State::Failed, "{reason}");
        }
        write(42, None);
        assert!(reported_failure(job, 42, 7, failed()).is_err(), "no reason, no message: unexplained");
        write(43, Some("feature-not-offered"));
        assert!(reported_failure(job, 42, 7, failed()).is_err(), "another worker's journal");
        write(42, Some("feature-not-offered"));
        assert!(reported_failure(job, 42, 7, Ok(State::Ready)).is_err(), "an error exit after success");
    }

    #[test]
    fn cancellation_only_writes_an_existing_marker() {
        let temp = TempDir::new("persistent-cancel");
        let marker = temp.path().join("cancel");
        assert_eq!(write_cancel(&marker).unwrap_err().kind(), std::io::ErrorKind::NotFound);
        assert!(!marker.exists());
        fs::write(&marker, "").unwrap();
        write_cancel(&marker).unwrap();
        assert_eq!(fs::read_to_string(&marker).unwrap(), "cancel");
    }

    #[test]
    fn terminal_failure_details_reach_the_monitor_and_are_not_shown_for_running_work() {
        let temp = TempDir::new("preparation-error-detail");
        let value = serde_json::json!({
            "schema":1,"status":"failed","stage":"store-install","completed":0,"total":1,
            "pid":42,"processStart":123,
            "activity":{"failureMessage":"Resources are in use","errorCode":"0x80073D02","packageName":"NanaZip"}
        });
        fs::write(temp.path().join("state.json"), value.to_string()).unwrap();
        let job =
            RunningJob { directory: temp.path().to_owned(), pid: 42, process_start: 123, trusted: true };
        let mut reports = Vec::new();
        let state = monitor_with(&job, |p| reports.push(p), || Liveness::Ended, HEARTBEAT).unwrap();
        assert_eq!(state, State::Failed);
        let failure = reports[0].failure().unwrap();
        assert_eq!(failure.package_name.as_deref(), Some("NanaZip"));
        assert_eq!(failure.error_code.as_deref(), Some("0x80073D02"));
        reports[0].status = Status::Running;
        assert!(reports[0].failure().is_none());
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
        let temp = TempDir::new("preparation-recovery");
        let settings = temp.path().join("settings.json");
        let job = temp.path().join("Preparation/123-456");
        let pid = std::process::id();
        let start = system::process_start_time(pid).unwrap();
        journal(&job, pid, start, "running");
        let recovered = recover_running(&settings).unwrap().unwrap();
        assert_eq!(recovered.directory, job);
        journal(&job, pid, start + 1, "complete");
        assert!(recover_running(&settings).unwrap().is_none());
        assert_eq!(monitor_with(&recovered, |_| {}, || Liveness::Ended, HEARTBEAT).unwrap(), State::Failed);
        journal(&job, pid, start, "complete");
        let mut operation: serde_json::Value =
            serde_json::from_str(&fs::read_to_string(job.join("state.json")).unwrap()).unwrap();
        operation["operation"] = "restore".into();
        fs::write(job.join("state.json"), operation.to_string()).unwrap();
        assert!(recover_running(&settings).unwrap().is_none(), "a put-back is not a run to follow");
        journal(&job, pid, start, "complete");
        let mut reads = 0;
        let result = monitor_with(
            &recovered,
            |_| {},
            || {
                reads += 1;
                if reads == 1 { Liveness::Unknown("access denied".into()) } else { Liveness::Ended }
            },
            HEARTBEAT,
        )
        .unwrap();
        assert_eq!(reads, 2, "unknown ownership must not release the operation");
        assert_eq!(result, State::Ready);
    }

    #[test]
    fn a_reopened_monitor_can_stop_a_real_harmless_worker_without_owning_its_stdout() {
        // Stop and reap the fixture before TempDir is dropped, including on panic.
        struct Worker(std::process::Child);
        impl Drop for Worker {
            fn drop(&mut self) {
                let _ = self.0.kill();
                let _ = self.0.wait();
            }
        }

        let temp = TempDir::new("preparation-orphan");
        let job = temp.path().join("Preparation/123-456");
        fs::create_dir_all(&job).unwrap();
        fs::write(job.join("cancel"), "").unwrap();
        let script = job.join("fixture.ps1");
        fs::write(&script, r#"
$ErrorActionPreference = 'Stop'
$record = @{schema=1;status='running';stage='verify';completed=0;total=0;pid=$PID;processStart=[Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().ToFileTimeUtc()}
$record | ConvertTo-Json -Compress | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'state.json')
[Console]::WriteLine('started')
$deadline = [DateTime]::UtcNow.AddSeconds(60)
while ((Get-Content -LiteralPath (Join-Path $PSScriptRoot 'cancel') -Raw) -cne 'cancel' -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 25 }
$record.status = 'cancelled'
$record | ConvertTo-Json -Compress | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'state.json')
[Console]::WriteLine('stopped')
"#).unwrap();
        let output = fs::File::create(job.join("worker.log")).unwrap();
        let errors = fs::File::create(job.join("worker-errors.log")).unwrap();
        let mut child = Worker(
            powershell::command()
                .arg("-File")
                .arg(script)
                .stdout(Stdio::from(output))
                .stderr(Stdio::from(errors))
                .spawn()
                .unwrap(),
        );
        // Shared Windows runners can take several seconds to start PowerShell.
        let deadline = Instant::now() + Duration::from_secs(30);
        let recovered = loop {
            if let Some(job) = recover_running(&temp.path().join("settings.json")).unwrap() {
                break job;
            }
            let exited = child.0.try_wait().unwrap();
            assert!(
                exited.is_none() && Instant::now() < deadline,
                "worker did not publish its identity (exit: {exited:?}): {}",
                fs::read_to_string(job.join("worker-errors.log")).unwrap_or_default()
            );
            std::thread::sleep(Duration::from_millis(25));
        };
        let state = monitor(recovered, Arc::new(AtomicBool::new(true)), |_| {}).unwrap();
        assert_eq!(state, State::Cancelled);
        assert!(child.0.wait().unwrap().success());
        let log = fs::read_to_string(job.join("worker.log")).unwrap();
        assert!(log.contains("started") && log.contains("stopped"));
    }

    #[test]
    fn restart_registration_survives_same_boot_and_is_removed_after_recovery() {
        let test = TestKey::new("resume");
        let exe = Path::new(r"C:\Program Files\Atlas Setup Recovery\hash\AtlasManager.exe");
        register_at(&test.key, exe).unwrap();
        let command = test.key.get_string(RESUME_VALUE).unwrap();
        assert_eq!(command, format!("\"{}\" --after-preparation-restart", exe.display()));
        assert_eq!(resume_for(State::Reboot), Resume::Wait);
        assert_eq!(resume_for(State::Resumed), Resume::Open);
        assert_eq!(resume_for(State::Idle), Resume::Abandoned, "abandoned drafts do not reopen");
        // Deciding never writes the key; the entry goes only when cleared.
        assert_eq!(test.key.get_string(RESUME_VALUE).unwrap(), command);
        registry::remove_value(&test.key, RESUME_VALUE).unwrap();
        assert!(test.key.get_string(RESUME_VALUE).is_err());
        registry::remove_value(&test.key, RESUME_VALUE).unwrap();
    }

    #[test]
    fn recovery_requires_a_real_boot_and_never_marks_updates_complete() {
        assert_eq!(state_after_restart(None), State::Idle);
        assert_eq!(state_after_restart(Some("invalid")), State::Reboot);
        assert_eq!(state_after_restart(Some(&chrono::Utc::now().to_rfc3339())), State::Reboot);
        assert_eq!(state_after_restart(Some("2001-01-01T00:00:00Z")), State::Resumed);
        assert!(!State::Resumed.ready());
        assert!(State::SavingRestart.busy());
    }

    #[test]
    fn a_damaged_draft_opens_the_app_and_is_left_for_it_to_report() {
        let temp = TempDir::new("preparation-damaged-settings");
        let settings = temp.path().join("settings.json");
        fs::write(&settings, "{").unwrap();
        assert_eq!(resume_after_restart(&settings), Resume::Unreadable);
        assert!(settings.is_file(), "the window's own load sets it aside and says so");
    }

    #[test]
    fn a_second_restart_request_without_work_names_the_marker_instead() {
        let reasons = vec!["file-renames".to_owned()];
        assert_eq!(
            State::Reboot.settle(true, false, reasons.clone()),
            State::RestartPersists { reasons: reasons.clone() }
        );
        // A first request, or one after updates were installed, still restarts.
        assert_eq!(State::Reboot.settle(false, false, reasons.clone()), State::Reboot);
        assert_eq!(State::Reboot.settle(true, true, reasons.clone()), State::Reboot);
        // Other verdicts are untouched.
        assert_eq!(State::Ready.settle(true, false, reasons.clone()), State::Ready);
        assert_eq!(State::Failed.settle(true, false, reasons), State::Failed);
        // Finishing a Windows version change needs its own restarts, which
        // the worker bounds; a marker that survives restarts is still named.
        for reason in [FEATURE_UPDATE, FEATURE_COMMIT] {
            assert_eq!(State::Reboot.settle(true, false, vec![reason.to_owned()]), State::Reboot, "{reason}");
        }
        assert_eq!(
            State::Reboot.settle(true, false, vec!["windows-update".to_owned()]),
            State::RestartPersists { reasons: vec!["windows-update".to_owned()] }
        );
    }

    fn transition(accept_license: bool) -> TransitionRequest {
        TransitionRequest::new(&crate::services::windows_release::TRANSITIONS[0], accept_license)
    }

    #[test]
    fn the_worker_is_asked_to_move_windows_only_with_a_request_and_to_accept_terms_only_when_the_user_did() {
        let plain =
            PreparationRequest { drivers: Drivers::Manual, transition: None, open_update_access: false };
        assert_eq!(worker_args(&plain), ["-PersistentCancellation", "-DriverMode", "manual"]);
        let open = PreparationRequest { open_update_access: true, ..plain.clone() };
        assert!(worker_args(&open).contains(&"-OpenWindowsUpdate".to_owned()));
        assert!(!worker_args(&open).contains(&"-WindowsTarget".to_owned()));

        let moving = PreparationRequest {
            transition: Some(transition(false)),
            open_update_access: true,
            ..plain.clone()
        };
        let args = worker_args(&moving);
        let value = |flag: &str| args.iter().position(|arg| arg == flag).map(|index| args[index + 1].clone());
        assert_eq!(value("-WindowsTarget").as_deref(), Some("26H2"));
        assert_eq!(value("-TargetBuild").as_deref(), Some("26300"));
        assert_eq!(value("-SourceBuilds").as_deref(), Some("26100,26200"));
        assert_eq!(value("-FeatureKb").as_deref(), Some("5121794,5129195"));
        assert_eq!(value("-PrerequisiteKb").as_deref(), Some("5124010"));
        assert_eq!(value("-MinimumRevision").as_deref(), Some("9546"));
        assert!(!args.contains(&"-AcceptLicense".to_owned()), "terms not accepted");
        assert!(!args.contains(&"-OpenWindowsUpdate".to_owned()), "a move turns Windows Update on itself");
        let accepted = PreparationRequest { transition: Some(transition(true)), ..plain.clone() };
        assert!(worker_args(&accepted).contains(&"-AcceptLicense".to_owned()));
        assert!(!worker_args(&accepted).contains(&"-OfferOnly".to_owned()));
        let recheck = PreparationRequest {
            transition: Some(TransitionRequest { offer_only: true, ..transition(true) }),
            ..plain
        };
        assert!(worker_args(&recheck).contains(&"-OfferOnly".to_owned()));
    }

    #[test]
    fn an_update_offered_again_after_it_installed_stops_counting_for_30_days() {
        let now =
            chrono::DateTime::parse_from_rfc3339("2026-10-01T12:00:00Z").unwrap().with_timezone(&chrono::Utc);
        let text = r#"[{"key":"0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f/200","kb":"5007651","at":"2026-09-30T08:00:00Z"},
            {"key":"old/1","at":"2026-08-01T08:00:00Z"},{"key":"","at":"2026-09-30T08:00:00Z"},{"at":"2026-09-30T08:00:00Z"}]"#;
        let handled = parse_reoffered(text, now);
        assert_eq!(handled.len(), 1);
        assert!(handled.contains("0d5c1a3b-3a2b-4c6d-9e1f-2a3b4c5d6e7f/200"));
        let one = r#"{"key":"a/1","at":"2026-09-30T08:00:00Z"}"#;
        assert!(parse_reoffered(one, now).contains("a/1"), "one entry written on its own");
        assert!(parse_reoffered("{not json", now).is_empty());
        assert!(parse_reoffered("", now).is_empty());
    }

    #[test]
    fn a_version_change_report_carries_what_the_app_words() {
        let line = r#"ATLAS_PREP:{"schema":1,"status":"reboot","stage":"windows-install","completed":0,"total":0,"activity":{"restartReasons":["feature-update"],"unchangedSeconds":0}}"#;
        assert!(finishes_version_change(&parse_event(line).unwrap().activity.restart_reasons));
        let line = r#"ATLAS_PREP:{"schema":1,"status":"failed","stage":"windows-search","completed":0,"total":0,"activity":{"failureMessage":"Drive C: has 2 GB free","reason":"feature-disk-space","drive":"C:","freeGb":"2","neededGb":"6","hardware":"tpm,uefi","setting":"BITS"}}"#;
        let failure = parse_event(line).unwrap().failure().cloned().unwrap();
        assert_eq!(failure.reason.as_deref(), Some("feature-disk-space"));
        assert_eq!(
            (failure.drive.as_deref(), failure.free_gb.as_deref(), failure.needed_gb.as_deref()),
            (Some("C:"), Some("2"), Some("6"))
        );
        assert_eq!(failure.hardware.as_deref(), Some("tpm,uefi"));
        assert_eq!(failure.setting.as_deref(), Some("BITS"));
        assert_eq!(
            operation_reason("feature-install-active: An Atlas install is unfinished"),
            Some("feature-install-active")
        );
        assert_eq!(operation_reason("the worker ended with exit code: 1"), None);
    }

    /// The field names Update-Windows.ps1 writes for the causes and restart
    /// reasons the app words itself.
    #[test]
    fn a_report_names_the_cause_and_reasons_the_app_words() {
        let line = r#"ATLAS_PREP:{"schema":1,"status":"failed","stage":"store-install","completed":0,"total":1,"activity":{"failureMessage":"Microsoft Store needs attention","reason":"store-paused-battery"}}"#;
        let event = parse_event(line).unwrap();
        assert_eq!(event.failure().and_then(|f| f.reason.as_deref()), Some("store-paused-battery"));
        let line = r#"ATLAS_PREP:{"schema":1,"status":"network","stage":"verify","completed":0,"total":0,"activity":{"networkReason":"metered"}}"#;
        assert_eq!(parse_event(line).unwrap().activity.network_reason.as_deref(), Some("metered"));
        let line = r#"ATLAS_PREP:{"schema":1,"status":"reboot","stage":"windows-install","completed":0,"total":0,"activity":{"restartReasons":["servicing","file-renames"],"elapsedSeconds":1,"unchangedSeconds":0}}"#;
        let event = parse_event(line).unwrap();
        assert_eq!(event.status, Status::Reboot);
        assert_eq!(event.activity.restart_reasons, vec!["servicing".to_owned(), "file-renames".to_owned()]);
    }

    #[test]
    fn only_finished_jobs_beyond_the_newest_few_are_removed() {
        let temp = TempDir::new("preparation-prune");
        let root = temp.path().join("Preparation");
        let pid = std::process::id();
        let start = system::process_start_time(pid).unwrap();
        let job = |stamp: u32| root.join(format!("{pid}-{stamp}"));
        // This process's id with another start time is a worker that has ended.
        for stamp in 1..=4 {
            journal(&job(stamp), pid, start + 1, "complete");
        }
        journal(&job(5), pid, start, "running");
        journal(&job(6), pid, start, "failed");
        journal(&job(0), pid, start + 1, "failed");
        fs::create_dir_all(root.join("not-a-job")).unwrap();
        prune_finished(&root, Some(&job(0)), 2).unwrap();
        assert!(!job(1).exists() && !job(2).exists(), "older finished jobs go");
        assert!(job(3).exists() && job(4).exists(), "the newest finished jobs stay");
        assert!(job(5).exists() && job(6).exists(), "a job whose worker still runs stays");
        assert!(job(0).exists(), "the job on screen stays");
        assert!(root.join("not-a-job").exists());
    }
}
