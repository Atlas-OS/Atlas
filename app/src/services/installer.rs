//! Runs the Atlas front door (`Install-Atlas.ps1`) as a child process.
//!
//! The child writes to a log file rather than a pipe, so it never blocks on
//! this app and keeps running if the window is closed. A session record
//! (see [`super::session`]) names the process and the log, and a wrapper
//! command writes the script's exit code beside the log, so a reopened app
//! can pick the install up again and learn how it ended.

use std::fs;
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use futures::SinkExt;
use futures::channel::mpsc::{Receiver, Sender, channel};
use serde::{Deserialize, Serialize};

use super::playbook;
use super::session::{self, Inspection, LaunchLock, SessionPaths, SessionRecord};
use super::system;

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InstallRequest {
    pub playbook_dir: PathBuf,
    pub options: Vec<String>,
    pub restart: bool,
    /// The message Windows shows in its restart notice after a successful
    /// install with `restart`, in the app's language at the time. Older
    /// session records have none; the front door then uses its English text.
    #[serde(default)]
    pub restart_comment: Option<String>,
}

#[derive(Clone, Debug)]
pub enum InstallEvent {
    /// A batch of output lines, oldest first.
    Lines(Vec<String>),
    /// Output could not be read; the install itself may still be running.
    /// Carries the raw I/O error as a diagnostic.
    OutputProblem(String),
    Finished(InstallOutcome),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum InstallOutcome {
    Succeeded,
    /// Exit code from the script: 1 failure, 2 requirements not met, 3 not elevated.
    Failed(i32),
    /// The wrapper never received the go-ahead (the install record could not
    /// be established), so the front door was not run.
    NotStarted,
    /// The process ended without reporting a result (found after reopening).
    Lost,
}

/// How far the front door got, read from its own progress lines.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord)]
pub enum Phase {
    /// Checks and staging preparation; nothing on the PC has changed.
    #[default]
    Preflight,
    /// The payload is being copied to the protected staging directory and
    /// the install state captured; Windows itself is unchanged.
    Staging,
    /// The install plan is running as TrustedInstaller; changes are being applied.
    Applying,
    Done,
}

impl Phase {
    /// The phase a front door output line announces, if it announces one.
    pub fn from_line(line: &str) -> Option<Phase> {
        let line = line.trim_start();
        let text = line.strip_prefix("[Atlas]")?.trim_start();
        if text.starts_with("Staging the payload") || text.starts_with("Capturing the install state") {
            Some(Phase::Staging)
        } else if text.starts_with("Running the install plan") {
            Some(Phase::Applying)
        } else if text.starts_with("Atlas installed successfully") {
            Some(Phase::Done)
        } else {
            None
        }
    }
}

/// Completed plan actions plus the final state commit, reported by the payload.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct PlanProgress {
    pub completed: u32,
    pub total: u32,
}

impl PlanProgress {
    pub fn from_line(line: &str) -> Option<Self> {
        let marker = "[AtlasProgress] ";
        let text = line
            .strip_prefix(marker)
            .or_else(|| line.split_once("] [INFO] [AtlasProgress] ").map(|(_, text)| text))?;
        let (completed, total) = text.trim().split_once('/')?;
        let completed = completed.parse().ok()?;
        let total = total.parse().ok()?;
        (total > 0 && completed <= total).then_some(Self { completed, total })
    }

    pub fn fraction(self) -> f32 {
        self.completed as f32 / self.total as f32
    }
}

#[cfg(test)]
mod plan_progress_tests {
    use super::PlanProgress;

    #[test]
    fn parses_payload_progress_and_rejects_invalid_or_unrelated_output() {
        let progress =
            PlanProgress::from_line("[2026-09-06 20:32:19] [-] [INFO] [AtlasProgress] 8/40").unwrap();
        assert_eq!(progress.fraction(), 0.2);
        assert_eq!(PlanProgress::from_line("[AtlasProgress] 40/40").unwrap().fraction(), 1.0);
        for line in [
            "8/40",
            "[AtlasProgress] 1/0",
            "[AtlasProgress] 41/40",
            "[AtlasProgress] -1/40",
            "[AtlasProgress] 3/no",
            "[AtlasProgress] 3/40 extra",
        ] {
            assert!(PlanProgress::from_line(line).is_none(), "{line}");
        }
    }
}

impl InstallOutcome {
    pub fn is_success(self) -> bool {
        matches!(self, InstallOutcome::Succeeded)
    }
}

/// Option names are passed inside a PowerShell array literal, so they are
/// held to the same shape the script validates (`^[a-z0-9-]+$`).
pub fn validate_options(options: &[String]) -> Result<()> {
    anyhow::ensure!(!options.is_empty(), "no install options were chosen");
    for option in options {
        let ok = !option.is_empty()
            && option.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-');
        anyhow::ensure!(ok, "{option:?} is not a valid option name");
    }
    Ok(())
}

/// Single-quoted PowerShell string literal; the only escape is a doubled quote.
fn ps_quote(text: &str) -> String {
    format!("'{}'", text.replace('\'', "''"))
}

/// A path as PowerShell 5.1 accepts it (no `\\?\` prefix).
pub fn plain_path(path: &Path) -> String {
    let text = path.to_string_lossy();
    if let Some(rest) = text.strip_prefix(r"\\?\UNC\") {
        format!(r"\\{rest}")
    } else if let Some(rest) = text.strip_prefix(r"\\?\") {
        rest.to_owned()
    } else {
        text.into_owned()
    }
}

/// The call to the front door, as a PowerShell statement.
pub fn script_call(request: &InstallRequest) -> Result<String> {
    validate_options(&request.options)?;
    let script = playbook::front_door(&request.playbook_dir);
    let options = request.options.iter().map(|o| ps_quote(o)).collect::<Vec<_>>().join(",");
    let mut call = format!("& {} -Option @({options}) -Unattended", ps_quote(&plain_path(&script)));
    if request.restart {
        call.push_str(" -Restart");
        // Only a front door that declares the parameter gets it; an older
        // package would otherwise refuse the unknown parameter.
        if let Some(comment) =
            request.restart_comment.as_deref().map(restart_comment_text).filter(|c| !c.is_empty())
            && front_door_accepts_restart_comment(&script)
        {
            call.push_str(&format!(" -RestartComment {}", ps_quote(&comment)));
        }
    }
    Ok(call)
}

/// `shutdown.exe /c` takes at most 512 characters and no control characters.
/// The front door applies the same rule; this keeps the command line honest.
pub fn restart_comment_text(comment: &str) -> String {
    comment.chars().filter(|c| !c.is_control()).collect::<String>().trim().chars().take(512).collect()
}

/// Whether the front door at `script` declares `-RestartComment` (Atlas
/// 0.6.0 packages built before the parameter existed do not). Read from the
/// script's own `param(...)` block, so a mention in a comment or a default
/// value does not count and PowerShell's case-insensitive names do.
pub fn front_door_accepts_restart_comment(script: &Path) -> bool {
    use std::collections::HashMap;
    use std::sync::Mutex;
    use std::time::SystemTime;
    /// Modification time and length of a script, and whether it declares the parameter.
    type Stamp = (Option<SystemTime>, u64);
    static KNOWN: Mutex<Option<HashMap<PathBuf, (Stamp, bool)>>> = Mutex::new(None);
    let Ok(metadata) = fs::metadata(script) else { return false };
    let stamp = (metadata.modified().ok(), metadata.len());
    if let Ok(mut known) = KNOWN.lock()
        && let Some((seen, accepts)) = known.get_or_insert_with(HashMap::new).get(script)
        && *seen == stamp
    {
        return *accepts;
    }
    let accepts = fs::read_to_string(script)
        .map(|text| declared_parameters(&text).iter().any(|name| name == "restartcomment"))
        .unwrap_or(false);
    if let Ok(mut known) = KNOWN.lock() {
        known.get_or_insert_with(HashMap::new).insert(script.to_path_buf(), (stamp, accepts));
    }
    accepts
}

/// The parameter names a PowerShell script's own `param(...)` block
/// declares, lower-cased: the `$name`s at the block's top level that end a
/// declaration (followed by `,`, `)` or `=`), skipping comments, strings,
/// attributes and default values. Only the root block counts: a `param`
/// inside braces belongs to a function, and comments may sit between
/// `param` and its `(`. A test compares this against PowerShell's own
/// parser for the front door and a set of awkward layouts, so the app never
/// passes an argument a legacy front door would refuse.
pub fn declared_parameters(script: &str) -> Vec<String> {
    let chars: Vec<char> = script.chars().collect();
    let len = chars.len();
    // Skips a comment or string starting at `i`, returning the index after it.
    let skip_inert = |i: usize| -> Option<usize> {
        match chars[i] {
            '#' => Some(chars[i..].iter().position(|c| *c == '\n').map(|n| i + n).unwrap_or(len)),
            '<' if chars.get(i + 1) == Some(&'#') => {
                let mut j = i + 2;
                while j + 1 < len && !(chars[j] == '#' && chars[j + 1] == '>') {
                    j += 1;
                }
                Some((j + 2).min(len))
            }
            quote @ ('\'' | '"') => {
                let mut j = i + 1;
                while j < len {
                    if chars[j] == '`' && quote == '"' {
                        j += 2;
                        continue;
                    }
                    if chars[j] == quote {
                        if chars.get(j + 1) == Some(&quote) {
                            j += 2;
                            continue;
                        }
                        return Some(j + 1);
                    }
                    j += 1;
                }
                Some(len)
            }
            _ => None,
        }
    };
    let is_ident = |c: char| c.is_ascii_alphanumeric() || c == '_';

    // The script's own param block: the first `param` at brace depth zero
    // (outside comments and strings) whose next token, comments aside, is `(`.
    let mut i = 0;
    let mut start = None;
    let mut braces = 0usize;
    while i < len {
        if let Some(next) = skip_inert(i) {
            i = next;
            continue;
        }
        match chars[i] {
            '{' => braces += 1,
            '}' => braces = braces.saturating_sub(1),
            _ => {}
        }
        let word: String = chars[i..(i + 5).min(len)].iter().collect();
        if braces == 0
            && word.eq_ignore_ascii_case("param")
            && (i == 0 || !is_ident(chars[i - 1]))
            && !is_ident(*chars.get(i + 5).unwrap_or(&' '))
        {
            let mut j = i + 5;
            loop {
                while j < len && chars[j].is_whitespace() {
                    j += 1;
                }
                match (chars.get(j), chars.get(j + 1)) {
                    (Some('#'), _) | (Some('<'), Some('#')) => j = skip_inert(j).unwrap_or(len),
                    _ => break,
                }
            }
            if chars.get(j) == Some(&'(') {
                start = Some(j + 1);
            }
            // Whether or not it was a block, a root `param` is the only one
            // that can be the script's; nothing later counts.
            break;
        }
        i += 1;
    }
    let Some(mut i) = start else { return Vec::new() };

    let mut names = Vec::new();
    let mut depth = 1usize;
    let mut in_default = false;
    while i < len && depth > 0 {
        if let Some(next) = skip_inert(i) {
            i = next;
            continue;
        }
        match chars[i] {
            '(' | '[' | '{' => depth += 1,
            ')' | ']' | '}' => depth -= 1,
            ',' if depth == 1 => in_default = false,
            '=' if depth == 1 => in_default = true,
            '$' if depth == 1 && !in_default => {
                let mut j = i + 1;
                while j < len && is_ident(chars[j]) {
                    j += 1;
                }
                let name: String = chars[i + 1..j].iter().collect();
                // Whitespace and comments may sit between the name and its terminator.
                let mut k = j;
                loop {
                    while k < len && chars[k].is_whitespace() {
                        k += 1;
                    }
                    match (chars.get(k), chars.get(k + 1)) {
                        (Some('#'), _) | (Some('<'), Some('#')) => k = skip_inert(k).unwrap_or(len),
                        _ => break,
                    }
                }
                let ends_declaration = matches!(chars.get(k), Some(',') | Some(')') | Some('='));
                if !name.is_empty() && chars.get(j) != Some(&':') && ends_declaration {
                    names.push(name.to_lowercase());
                }
                i = j;
                continue;
            }
            _ => {}
        }
        i += 1;
    }
    names
}

/// What the child runs. It first waits for the go-ahead file, which the app
/// creates only once the session record is durable, so the front door never
/// runs without a record that a reopened app can find. Then: UTF-8 output,
/// the front door, and the exit code written where the session can find it.
/// `-Command` is used instead of `-File` because `-File` passes every
/// argument as one string, which cannot express the script's `[string[]]`
/// option list.
fn wrapper_command(request: &InstallRequest, exit_path: &Path, go_path: &Path) -> Result<String> {
    Ok(format!(
        "$atlasGo = {go}; $atlasDeadline = (Get-Date).AddSeconds({timeout}); while (-not (Test-Path -LiteralPath $atlasGo)) {{ if ((Get-Date) -gt $atlasDeadline) {{ exit {not_started} }}; Start-Sleep -Milliseconds 50 }}; [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false); {call}; $atlasExit = $LASTEXITCODE; if ($null -eq $atlasExit) {{ $atlasExit = 1 }}; [IO.File]::WriteAllText({exit}, [string]$atlasExit); exit $atlasExit",
        go = ps_quote(&plain_path(go_path)),
        timeout = HANDOVER_TIMEOUT_SECONDS,
        not_started = NOT_STARTED_EXIT_CODE,
        call = script_call(request)?,
        exit = ps_quote(&plain_path(exit_path)),
    ))
}

const POWERSHELL_FLAGS: [&str; 6] =
    ["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"];

/// The command line, for showing the user what will run.
pub fn command_line(request: &InstallRequest) -> Result<String> {
    let call = script_call(request)?;
    Ok(format!("powershell.exe {} \"{call}\"", POWERSHELL_FLAGS.join(" ")))
}

/// The shared install record cannot be read, so no install may start.
#[derive(Debug)]
pub struct RecordUnreadable(pub String);

impl std::fmt::Display for RecordUnreadable {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "the record of the last install cannot be read ({}), so Atlas cannot tell whether it is still running; nothing was started",
            self.0
        )
    }
}

impl std::error::Error for RecordUnreadable {}

/// Another install is already running; the caller should follow it.
#[derive(Debug)]
pub struct AlreadyRunning(pub SessionRecord);

impl std::fmt::Display for AlreadyRunning {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "an install started at {} is still running (process {})", self.0.started_at, self.0.pid)
    }
}

impl std::error::Error for AlreadyRunning {}

/// Starts the installer and records the session. Output events arrive on the
/// returned receiver from a reader thread; the final event is `Finished`.
///
/// Launching and recording are one protocol, serialised across app instances
/// by the launch lock: an install that is still running is refused with
/// [`AlreadyRunning`]; the log and exit files are created exclusively under a
/// collision-resistant id; the session record is written before the child
/// starts and rewritten with its process identity; only then does the child
/// receive the go-ahead that lets it run the front door. Any failure before
/// the go-ahead leaves no running installer and returns an error.
#[cfg(test)]
pub fn start(
    request: InstallRequest,
    paths: &SessionPaths,
) -> Result<(SessionRecord, Receiver<InstallEvent>)> {
    start_as(session::new_id(), request, paths)
}

/// [`start`] under a session id the caller chose in advance, so the caller
/// can record which install it is about to launch (in its draft, say)
/// before the child receives permission to run.
pub fn start_as(
    id: String,
    request: InstallRequest,
    paths: &SessionPaths,
) -> Result<(SessionRecord, Receiver<InstallEvent>)> {
    let script = playbook::front_door(&request.playbook_dir);
    log::info!(
        "Installation session {id} requested; package={:?}; options={:?}",
        playbook::identity(&request.playbook_dir),
        request.options
    );
    anyhow::ensure!(script.is_file(), "{} is missing", script.display());
    validate_options(&request.options)?;

    let launch = LaunchLock::acquire(paths).context("nothing was started")?;
    match launch.inspect(paths) {
        Inspection::Live(existing) => return Err(AlreadyRunning(existing).into()),
        Inspection::Unreadable(problem) => return Err(RecordUnreadable(problem).into()),
        Inspection::None | Inspection::Ended(_) | Inspection::Abandoned => {}
    }

    fs::create_dir_all(&paths.logs).with_context(|| format!("create {}", paths.logs.display()))?;
    let log_path = paths.logs.join(format!("install-{id}.log"));
    let exit_path = paths.logs.join(format!("install-{id}.exit"));
    let go_path = paths.logs.join(format!("install-{id}.go"));
    // Atlas owns restart timing; even older payloads must never schedule a Windows overlay.
    let mut child_request = request.clone();
    child_request.restart = false;
    child_request.restart_comment = None;
    let command_text = wrapper_command(&child_request, &exit_path, &go_path)?;
    let machine_offset = fs::metadata(machine_log_path()).map(|m| m.len()).unwrap_or(0);
    fs::write(log_path.with_extension("machine-offset"), machine_offset.to_string())?;

    let log = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&log_path)
        .with_context(|| format!("create {}", log_path.display()))?;
    let log_err = log.try_clone().context("share the log file")?;

    let mut record = SessionRecord {
        id,
        pid: 0,
        process_start: 0,
        started_at: chrono::Local::now().to_rfc3339(),
        log_path: log_path.clone(),
        exit_path,
        request: request.clone(),
    };
    // The record must be durable before anything runs.
    if let Err(error) = fail_point(FailPoint::InitialRecord).and_then(|()| session::save(paths, &record)) {
        let _ = fs::remove_file(&log_path);
        let _ = fs::remove_file(log_path.with_extension("machine-offset"));
        return Err(error.context("record the install before starting it; nothing was started"));
    }

    let mut command = Command::new("powershell.exe");
    command
        .args(POWERSHELL_FLAGS)
        .arg(&command_text)
        .current_dir(&request.playbook_dir)
        .stdin(Stdio::null())
        .stdout(Stdio::from(log))
        .stderr(Stdio::from(log_err));
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x0800_0000;
        command.creation_flags(CREATE_NO_WINDOW);
    }
    let mut child = match command.spawn() {
        Ok(child) => child,
        Err(error) => {
            launch.discard(paths);
            let _ = fs::remove_file(&log_path);
            let _ = fs::remove_file(log_path.with_extension("machine-offset"));
            return Err(anyhow::Error::from(error).context("start Windows PowerShell; nothing was started"));
        }
    };
    #[cfg(test)]
    LAST_SPAWNED.with(|last| last.set(child.id()));

    // The child is waiting for the go-ahead; establish ownership first.
    record.pid = child.id();
    record.process_start = system::process_start_time(child.id()).unwrap_or_default();
    let established = fail_point(FailPoint::RecordRewrite)
        .and_then(|()| session::save(paths, &record))
        .and_then(|()| fail_point(FailPoint::GoAhead))
        .and_then(|()| fs::write(&go_path, "go").with_context(|| format!("write {}", go_path.display())));
    if let Err(error) = established {
        let _ = child.kill();
        let _ = child.wait();
        launch.discard(paths);
        let _ = fs::remove_file(&log_path);
        let _ = fs::remove_file(log_path.with_extension("machine-offset"));
        return Err(error.context("record the install before starting it; nothing was started"));
    }

    let (sender, receiver) = channel(EVENT_BACKLOG);
    let watch = Watch::Owned(child);
    thread::spawn(move || follow(log_path, watch, sender));
    Ok((record, receiver))
}

/// Points in the launch protocol where a test can inject a failure.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FailPoint {
    InitialRecord,
    RecordRewrite,
    GoAhead,
}

#[cfg(test)]
thread_local! {
    static FAIL_AT: std::cell::Cell<Option<FailPoint>> = const { std::cell::Cell::new(None) };
    static LAST_SPAWNED: std::cell::Cell<u32> = const { std::cell::Cell::new(0) };
}

#[cfg(test)]
fn fail_point(point: FailPoint) -> Result<()> {
    if FAIL_AT.with(|fail| fail.get()) == Some(point) {
        anyhow::bail!("injected failure at {point:?}");
    }
    Ok(())
}

#[cfg(not(test))]
fn fail_point(_point: FailPoint) -> Result<()> {
    Ok(())
}

/// Follows an install that an earlier app instance started. Output starts
/// from the beginning of the log, so the whole history is available.
pub fn reattach(record: &SessionRecord) -> Receiver<InstallEvent> {
    let (sender, receiver) = channel(EVENT_BACKLOG);
    let watch = Watch::Detached(record.clone());
    let log_path = record.log_path.clone();
    thread::spawn(move || follow(log_path, watch, sender));
    receiver
}

enum Watch {
    Owned(Child),
    Detached(SessionRecord),
}

impl Watch {
    /// `Some(outcome)` once the installer has ended.
    fn poll(&mut self) -> Option<InstallOutcome> {
        match self {
            Watch::Owned(child) => match child.try_wait() {
                Ok(Some(status)) => Some(outcome_from_code(status.code())),
                Ok(None) => None,
                Err(_) => Some(InstallOutcome::Lost),
            },
            Watch::Detached(record) => {
                if let Some(code) = record.exit_code() {
                    return Some(outcome_from_code(Some(code)));
                }
                if record.is_alive() {
                    return None;
                }
                // The process is gone; give a just-written exit file a moment.
                let deadline = Instant::now() + Duration::from_secs(2);
                while Instant::now() < deadline {
                    if let Some(code) = record.exit_code() {
                        return Some(outcome_from_code(Some(code)));
                    }
                    thread::sleep(Duration::from_millis(100));
                }
                Some(InstallOutcome::Lost)
            }
        }
    }
}

/// Exit code the wrapper uses when the go-ahead never arrived. The front
/// door's own codes are 0 to 3.
const NOT_STARTED_EXIT_CODE: i32 = 4;
/// How long the wrapper waits for the go-ahead before giving up.
const HANDOVER_TIMEOUT_SECONDS: u32 = 60;

fn outcome_from_code(code: Option<i32>) -> InstallOutcome {
    match code {
        Some(0) => InstallOutcome::Succeeded,
        Some(NOT_STARTED_EXIT_CODE) => InstallOutcome::NotStarted,
        Some(code) => InstallOutcome::Failed(code),
        None => InstallOutcome::Lost,
    }
}

/// Events waiting for the UI at any moment. The child writes to disk, so the
/// follower can simply pause when the window is behind; it never buffers a
/// large replay in memory and never drops a line.
const EVENT_BACKLOG: usize = 8;
/// Lines per event, so a big replay reaches the model in pieces it can trim.
const LINES_PER_EVENT: usize = 2000;

pub fn machine_log_path() -> PathBuf {
    std::env::var_os("SystemRoot")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(r"C:\Windows"))
        .join(r"AtlasModules\Logs\install\atlas-install.log")
}

/// Tails the log until the installer ends, then drains everything that is
/// left before reporting the outcome.
fn follow(log_path: PathBuf, mut watch: Watch, mut sender: Sender<InstallEvent>) {
    const POLL: Duration = Duration::from_millis(120);
    let mut decoder = LineDecoder::default();
    let mut position = 0u64;
    let mut buffer = vec![0u8; 64 * 1024];
    let mut reported_problem = false;
    let machine_path = machine_log_path();
    let mut machine_position = fs::read_to_string(log_path.with_extension("machine-offset"))
        .ok()
        .and_then(|s| s.parse::<u64>().ok());
    let mut machine_decoder = LineDecoder::default();
    let mut machine_problem = false;

    // Reads what has been appended, sends it, and reports whether anything
    // arrived. Returns `Err` only when the receiver is gone.
    let mut pump = |path: &Path,
                    position: &mut u64,
                    buffer: &mut Vec<u8>,
                    decoder: &mut LineDecoder,
                    reported_problem: &mut bool|
     -> Result<bool, ()> {
        match read_new_bytes(path, position, buffer) {
            Ok([]) => Ok(false),
            Ok(bytes) => {
                let mut lines = decoder.push(bytes).into_iter().peekable();
                while lines.peek().is_some() {
                    let batch: Vec<String> = lines.by_ref().take(LINES_PER_EVENT).collect();
                    deliver(&mut sender, InstallEvent::Lines(batch))?;
                }
                Ok(true)
            }
            Err(error) => {
                if !*reported_problem {
                    *reported_problem = true;
                    deliver(&mut sender, InstallEvent::OutputProblem(error.to_string()))?;
                }
                Ok(false)
            }
        }
    };

    let outcome = loop {
        let ended = watch.poll();
        if pump(&log_path, &mut position, &mut buffer, &mut decoder, &mut reported_problem).is_err() {
            return;
        }
        if let Some(position) = machine_position.as_mut()
            && machine_path.exists()
            && pump(&machine_path, position, &mut buffer, &mut machine_decoder, &mut machine_problem).is_err()
        {
            return;
        }
        if let Some(outcome) = ended {
            // Drain detailed child output before publishing success or failure.
            if let Some(position) = machine_position.as_mut() {
                while machine_path.exists() {
                    match pump(
                        &machine_path,
                        position,
                        &mut buffer,
                        &mut machine_decoder,
                        &mut machine_problem,
                    ) {
                        Ok(true) => continue,
                        Ok(false) => break,
                        Err(()) => return,
                    }
                }
            }
            break outcome;
        }
        thread::sleep(POLL);
    };
    // Drain to the end of the file: a backlog can be many chunks long.
    loop {
        match pump(&log_path, &mut position, &mut buffer, &mut decoder, &mut reported_problem) {
            Ok(true) => continue,
            Ok(false) => break,
            Err(()) => return,
        }
    }
    if let Some(line) = decoder.finish()
        && deliver(&mut sender, InstallEvent::Lines(vec![line])).is_err()
    {
        return;
    }
    let _ = deliver(&mut sender, InstallEvent::Finished(outcome));
}

/// Hands an event to the UI, waiting while its backlog is full. `Err` means
/// the receiver is gone and the follower can stop.
fn deliver(sender: &mut Sender<InstallEvent>, event: InstallEvent) -> Result<(), ()> {
    futures::executor::block_on(sender.send(event)).map_err(|_| ())
}

/// Reads everything appended to the file since `position`.
fn read_new_bytes<'a>(path: &Path, position: &mut u64, buffer: &'a mut Vec<u8>) -> std::io::Result<&'a [u8]> {
    let mut file = fs::File::open(path)?;
    let len = file.metadata()?.len();
    if len < *position {
        // Truncated or replaced: start over rather than reading garbage.
        *position = 0;
    }
    if len == *position {
        return Ok(&buffer[..0]);
    }
    file.seek(SeekFrom::Start(*position))?;
    let wanted = usize::try_from(len - *position).unwrap_or(usize::MAX).min(4 * 1024 * 1024);
    if buffer.len() < wanted {
        buffer.resize(wanted, 0);
    }
    let mut filled = 0;
    while filled < wanted {
        let read = file.read(&mut buffer[filled..wanted])?;
        if read == 0 {
            break;
        }
        filled += read;
    }
    *position += filled as u64;
    Ok(&buffer[..filled])
}

/// The most of one line that is kept. Longer lines are cut there and marked;
/// the rest of the line is skipped, not stored. The full text is on disk.
pub const MAX_LINE_BYTES: usize = 8 * 1024;
/// Appended to a line that was cut at [`MAX_LINE_BYTES`].
pub const TRUNCATION_MARKER: &str = " [truncated]";

/// Splits a byte stream into lines and decodes each one leniently: a byte
/// that is not UTF-8 becomes U+FFFD instead of ending the stream. Each push
/// scans only the bytes it adds, so a long unterminated line costs its
/// length once, and every line it emits, complete or not, is cut at
/// [`MAX_LINE_BYTES`]; an unterminated line is cut as soon as it passes the
/// cap and the rest of it skipped, so no more than the cap is ever held.
#[derive(Default)]
pub struct LineDecoder {
    pending: Vec<u8>,
    /// How much of `pending` has already been searched for a line break.
    scanned: usize,
    /// The rest of an overlong line is being skipped until its line break.
    skipping: bool,
}

impl LineDecoder {
    pub fn push(&mut self, mut bytes: &[u8]) -> Vec<String> {
        let mut lines = Vec::new();
        if self.skipping {
            let Some(end) = bytes.iter().position(|b| *b == b'\n' || *b == b'\r') else {
                return lines;
            };
            self.skipping = false;
            bytes = &bytes[end..];
        }
        self.pending.extend_from_slice(bytes);
        let mut start = 0;
        let mut index = self.scanned;
        while index < self.pending.len() {
            let byte = self.pending[index];
            if byte == b'\n' || byte == b'\r' {
                lines.extend(emit_line(&self.pending[start..index]));
                if byte == b'\r' && self.pending.get(index + 1) == Some(&b'\n') {
                    index += 1;
                }
                start = index + 1;
            }
            index += 1;
        }
        self.pending.drain(..start.min(self.pending.len()));
        self.scanned = self.pending.len();
        if self.pending.len() > MAX_LINE_BYTES {
            lines.extend(truncated_line(&self.pending));
            self.pending.clear();
            self.scanned = 0;
            self.skipping = true;
        }
        lines
    }

    /// The unterminated last line, if any.
    pub fn finish(&mut self) -> Option<String> {
        let rest = std::mem::take(&mut self.pending);
        self.scanned = 0;
        if std::mem::take(&mut self.skipping) {
            // The line was already delivered, cut and marked.
            return None;
        }
        emit_line(&rest)
    }
}

/// One logical line as the UI receives it: decoded leniently, trimmed, and
/// cut at [`MAX_LINE_BYTES`] whatever its origin.
fn emit_line(bytes: &[u8]) -> Option<String> {
    if bytes.len() > MAX_LINE_BYTES { truncated_line(bytes) } else { decode_line(bytes) }
}

fn decode_line(bytes: &[u8]) -> Option<String> {
    let line = String::from_utf8_lossy(bytes);
    let line = line.trim_end();
    (!line.is_empty()).then(|| line.to_owned())
}

/// The first [`MAX_LINE_BYTES`] of a line, cut at a character boundary and marked.
fn truncated_line(bytes: &[u8]) -> Option<String> {
    let text = String::from_utf8_lossy(&bytes[..MAX_LINE_BYTES]);
    let mut text = text.into_owned();
    // A character split by the cut decoded as U+FFFD; drop it.
    if text.ends_with('\u{FFFD}') && bytes.get(MAX_LINE_BYTES).is_some_and(|b| b & 0xC0 == 0x80) {
        text.pop();
    }
    text.push_str(TRUNCATION_MARKER);
    Some(text)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::TempDir;
    use futures::StreamExt;
    use futures::executor::block_on;

    #[test]
    fn options_are_held_to_the_scripts_pattern() {
        assert!(validate_options(&["defender-enable".into(), "auto-updates-disable".into()]).is_ok());
        assert!(validate_options(&[]).is_err());
        assert!(validate_options(&["".into()]).is_err());
        assert!(validate_options(&["a,b".into()]).is_err());
        assert!(validate_options(&["Defender".into()]).is_err());
        assert!(validate_options(&["a'b".into()]).is_err());
        assert!(validate_options(&["a b".into()]).is_err());
    }

    #[test]
    fn the_command_passes_a_real_array_and_quotes_paths() {
        let request = InstallRequest {
            playbook_dir: PathBuf::from(r"C:\Users\O'Brien\AtlasOS\App\Playbooks\0.6.0"),
            options: vec!["defender-enable".into(), "mitigations-default".into()],
            restart: true,
            restart_comment: None,
        };
        let call = script_call(&request).unwrap();
        assert_eq!(
            call,
            r"& 'C:\Users\O''Brien\AtlasOS\App\Playbooks\0.6.0\Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1' -Option @('defender-enable','mitigations-default') -Unattended -Restart"
        );
        assert!(command_line(&request).unwrap().starts_with(
            "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"& '"
        ));
        assert_eq!(plain_path(Path::new(r"\\?\C:\x\y")), r"C:\x\y");
        assert_eq!(plain_path(Path::new(r"\\?\UNC\server\share\y")), r"\\server\share\y");
    }

    #[test]
    #[cfg(windows)]
    fn the_restart_comment_reaches_a_front_door_that_declares_it_and_is_withheld_otherwise() {
        let temp = TempDir::new("installer-restart-comment");
        let dir = stub_playbook(
            temp.path(),
            "Write-Host \"COMMENT=$RestartComment\"\r\nWrite-Host \"RESTART=$Restart\"\r\nexit 0",
        );
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir.clone(),
            options: vec!["defender-enable".into()],
            restart: true,
            restart_comment: Some("  Neustart: „Atlas“ ist fertig ✓ \u{7}O'Brien  ".into()),
        };
        let call = script_call(&request).unwrap();
        assert!(
            call.ends_with("-Restart -RestartComment 'Neustart: „Atlas“ ist fertig ✓ O''Brien'"),
            "{call}"
        );
        let (_, lines, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Succeeded, "{lines:?}");
        assert!(lines.contains(&"COMMENT=".to_owned()), "{lines:?}");
        assert!(lines.contains(&"RESTART=False".to_owned()), "{lines:?}");

        // An older front door without the parameter is called as before.
        let script = playbook::front_door(&dir);
        fs::write(
            &script,
            "[CmdletBinding()]\r\nparam([string[]]$Option, [switch]$Unattended, [switch]$Restart, [switch]$KeepStaging)\r\nWrite-Host \"OLD=$Restart\"\r\nexit 0",
        )
        .unwrap();
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: true,
            restart_comment: Some("Atlas".into()),
        };
        let call = script_call(&request).unwrap();
        assert!(call.ends_with("-Unattended -Restart"), "{call}");
        let (_, lines, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Succeeded, "{lines:?}");
        assert!(lines.contains(&"OLD=False".to_owned()), "{lines:?}");
        assert_eq!(restart_comment_text(&"x".repeat(600)).chars().count(), 512);
        assert_eq!(restart_comment_text(" \t\r\n "), "");
    }

    #[test]
    fn the_capability_check_reads_the_param_block_not_the_file_text() {
        // The repository's own front door declares it.
        let real = include_str!("../../../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
        assert_eq!(
            declared_parameters(real),
            ["option", "unattended", "windowssetup", "restart", "restartcomment", "keepstaging"]
        );
        // The recheck's legacy stub: a comment mentions the name, the block does not declare it.
        let legacy = "\u{feff}# Documentation mentions an unsupported parameter: $RestartComment\r\n[CmdletBinding()]\r\nparam([string[]]$Option,[switch]$Restart)\r\n'STUB ENTERED'\r\n";
        assert_eq!(declared_parameters(legacy), ["option", "restart"]);
        // Case-insensitive, attributes, a block comment, a default value and a
        // string that all mention the name without declaring it.
        let tricky = "<# $RestartComment in a header #>\nparam(\n  [Parameter(Mandatory = $true)][ValidatePattern('^[a-z$RestartComment]+$')] [string[]] $Option,\n  [string]$Other = \"$RestartComment\",\n  [string]$Third = $RestartComment,\n  [switch]$restartcomment # trailing $RestartComment\n)\nfunction f { param($RestartCommentInner) }";
        assert_eq!(declared_parameters(tricky), ["option", "other", "third", "restartcomment"]);
        let no_block = "Write-Host 'no params here $RestartComment'";
        assert!(declared_parameters(no_block).is_empty());
        let scoped = "param($env:Thing, $RestartComment)";
        assert_eq!(declared_parameters(scoped), ["restartcomment"]);
        // The final recheck's case: a comment between `param` and `(`, and a
        // helper function that declares the name for itself.
        let commented = "[CmdletBinding()]\nparam <# Script parameters. #> ([string[]]$Option,[switch]$Restart)\nfunction Format-RestartNotice { param([string]$RestartComment) $RestartComment }\n'STUB ENTERED'\n";
        assert_eq!(declared_parameters(commented), ["option", "restart"]);
        // No root block at all, only a function's: nothing is declared.
        let function_only = "function f { param([string]$RestartComment) }\n'x'";
        assert!(declared_parameters(function_only).is_empty());

        // Through the file-level check, with the cache keyed on the file's stamp.
        let temp = TempDir::new("installer-capability");
        let script = temp.path().join("Install-Atlas.ps1");
        fs::write(&script, legacy).unwrap();
        assert!(!front_door_accepts_restart_comment(&script));
        std::thread::sleep(Duration::from_millis(30));
        fs::write(&script, "param([string[]]$Option, [switch]$Restart, [string]$RestartComment)\n").unwrap();
        assert!(front_door_accepts_restart_comment(&script));
    }

    /// The Rust parser must agree with PowerShell's own parser about the root
    /// parameter block, for the repository's front door and for layouts that
    /// have tripped simpler checks. Windows PowerShell 5.1 parses each file
    /// without running it.
    #[test]
    #[cfg(windows)]
    fn the_capability_parser_agrees_with_powershells_parser() {
        let real = include_str!("../../../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
        let fixtures: [(&str, &str); 12] = [
            ("real", real),
            (
                "legacy-comment",
                "# Documentation mentions an unsupported parameter: $RestartComment\r\n[CmdletBinding()]\r\nparam([string[]]$Option,[switch]$Restart)\r\n'STUB ENTERED'\r\n",
            ),
            (
                "commented-param",
                "[CmdletBinding()]\nparam <# Script parameters. #> ([string[]]$Option,[switch]$Restart)\nfunction Format-RestartNotice { param([string]$RestartComment) $RestartComment }\n'STUB ENTERED'\n",
            ),
            (
                "line-comment-after-param",
                "[CmdletBinding()]\nparam # the block follows\n(\n  [string[]]$Option, # options\n  [switch]$Restart <# inline #>,\n  [string]$RestartComment\n)\n'x'\n",
            ),
            (
                "lowercase-typed",
                "param([string[]]$Option, [switch]$Restart, [string]$restartcomment = 'Atlas', [switch]$KeepStaging)\n'x'\n",
            ),
            (
                "defaults-and-strings",
                "param(\n  [Parameter(Mandatory = $true)][ValidatePattern('^[a-z$RestartComment]+$')] [string[]] $Option,\n  [string]$Other = \"$RestartComment\",\n  [string]$Third = $RestartComment,\n  [switch]$Restart\n)\n'x'\n",
            ),
            ("function-only", "function f { param([string]$RestartComment) }\n'x'\n"),
            ("no-params", "Write-Host 'no params here $RestartComment'\n"),
            (
                "requires-and-using",
                "#requires -Version 5.1\nusing namespace System.IO\n<# header mentions $RestartComment #>\n[CmdletBinding()]\nParam([string[]]$Option, [switch]$Restart, [string]$RestartComment)\n'x'\n",
            ),
            (
                "scoped-variable-default",
                "param([string]$Where = $env:TEMP, [string[]]$Option, [switch]$Restart)\n'x'\n",
            ),
            (
                "nested-attribute-parens",
                "param([Parameter(Mandatory = $true, HelpMessage = 'x (y), z')][string[]]$Option, [ValidateSet('a', 'b')][string]$RestartComment)\n'x'\n",
            ),
            (
                "multiline-attributes",
                "[CmdletBinding(SupportsShouldProcess = $true)]\nparam(\n    [Parameter(Mandatory = $true)]\n    [ValidatePattern('^[a-z0-9-]+$')]\n    [string[]]$Option,\n\n    [switch]$Unattended,\n\n    [switch]$Restart,\n\n    [string]$RestartComment,\n\n    [switch]$KeepStaging\n)\n'x'\n",
            ),
        ];
        let temp = TempDir::new("installer-parser-parity");
        let mut list = String::new();
        for (name, text) in &fixtures {
            let path = temp.path().join(format!("{name}.ps1"));
            fs::write(&path, text).unwrap();
            list.push_str(&format!("{}\n", path.display()));
        }
        let list_path = temp.path().join("fixtures.txt");
        fs::write(&list_path, &list).unwrap();
        // PowerShell prints "<name>=<param,param>" per file from its own AST.
        let script = format!(
            "foreach ($file in Get-Content -LiteralPath '{}') {{ $tokens = $null; $errors = $null; $ast = [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors); if ($errors.Count -gt 0) {{ throw \"$file does not parse: $($errors[0].Message)\" }}; $names = @(); if ($ast.ParamBlock) {{ $names = @($ast.ParamBlock.Parameters | ForEach-Object {{ $_.Name.VariablePath.UserPath.ToLowerInvariant() }}) }}; [IO.Path]::GetFileNameWithoutExtension($file) + '=' + ($names -join ',') }}",
            plain_path(&list_path)
        );
        let output = Command::new("powershell.exe")
            .args([
                "-NoLogo",
                "-NoProfile",
                "-NonInteractive",
                "-ExecutionPolicy",
                "Bypass",
                "-Command",
                &script,
            ])
            .output()
            .expect("run Windows PowerShell");
        assert!(output.status.success(), "{}", String::from_utf8_lossy(&output.stderr));
        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut compared = 0;
        for line in stdout.lines() {
            let Some((name, params)) = line.trim().split_once('=') else { continue };
            let expected: Vec<&str> = params.split(',').filter(|p| !p.is_empty()).collect();
            let (_, text) =
                fixtures.iter().find(|(n, _)| *n == name).unwrap_or_else(|| panic!("unknown fixture {name}"));
            assert_eq!(
                declared_parameters(text),
                expected,
                "{name}: the Rust parser disagrees with PowerShell"
            );
            compared += 1;
        }
        assert_eq!(compared, fixtures.len(), "every fixture must be compared: {stdout}");
    }

    #[test]
    fn phases_are_read_from_the_front_doors_own_lines() {
        assert_eq!(Phase::from_line("[Atlas] Atlas 0.6.0 from 'C:\\x'."), None);
        assert_eq!(
            Phase::from_line("[Atlas] Staging the payload in a protected directory..."),
            Some(Phase::Staging)
        );
        assert_eq!(
            Phase::from_line("[Atlas] Capturing the install state as TrustedInstaller..."),
            Some(Phase::Staging)
        );
        assert_eq!(
            Phase::from_line(
                "[Atlas] Running the install plan as TrustedInstaller. This takes several minutes..."
            ),
            Some(Phase::Applying)
        );
        assert_eq!(Phase::from_line("[Atlas] Atlas installed successfully."), Some(Phase::Done));
    }

    #[test]
    fn the_decoder_survives_invalid_bytes_and_split_reads() {
        let mut decoder = LineDecoder::default();
        let mut lines = decoder.push(&[0xE9, b'\n', b'A', b'F', b'T']);
        assert_eq!(lines, vec!["\u{FFFD}".to_owned()]);
        lines = decoder.push(b"ER\r\nnext\rlast");
        assert_eq!(lines, vec!["AFTER".to_owned(), "next".to_owned()]);
        // A multi-byte character split across reads decodes intact.
        let euro = "€".as_bytes();
        assert!(decoder.push(&euro[..1]).is_empty());
        assert_eq!(decoder.push(&euro[1..]), Vec::<String>::new());
        assert_eq!(decoder.finish(), Some("last€".to_owned()));
        assert_eq!(decoder.finish(), None);
    }

    #[test]
    fn a_long_unterminated_line_costs_its_length_once_and_is_cut_and_marked() {
        let mut decoder = LineDecoder::default();
        let chunk = vec![b'x'; 64 * 1024];
        let total = 16 * 1024 * 1024 / chunk.len();
        let started = Instant::now();
        let mut lines = Vec::new();
        for _ in 0..total {
            lines.extend(decoder.push(&chunk));
        }
        let elapsed = started.elapsed();
        // 16 MiB with no newline: one cut line, nothing retained past the cap,
        // and linear work (the quadratic rescan took seconds here).
        assert_eq!(lines.len(), 1, "{} lines", lines.len());
        assert_eq!(lines[0].len(), MAX_LINE_BYTES + TRUNCATION_MARKER.len());
        assert!(lines[0].ends_with(TRUNCATION_MARKER));
        assert!(decoder.pending.len() <= MAX_LINE_BYTES);
        assert!(elapsed < Duration::from_secs(2), "took {elapsed:?}");
        // The rest of that line is skipped; the next line arrives whole.
        assert_eq!(decoder.push(b"tail of the long line\nnext line\n"), vec!["next line".to_owned()]);
        assert_eq!(decoder.finish(), None);

        // A cut never splits a character: the line ends on a boundary.
        let mut decoder = LineDecoder::default();
        let mut bytes = vec![b'a'; MAX_LINE_BYTES - 1];
        bytes.extend_from_slice("\u{20ac}\u{20ac}".as_bytes());
        let lines = decoder.push(&bytes);
        assert_eq!(lines.len(), 1);
        let text = lines[0].strip_suffix(TRUNCATION_MARKER).unwrap();
        assert!(text.ends_with('a'), "the split euro sign is dropped, not shown as U+FFFD");
        assert!(!text.contains('\u{FFFD}'));
        // An overlong line delivered before its break is not delivered again at the end.
        assert_eq!(decoder.push(b"more"), Vec::<String>::new());
        assert_eq!(decoder.finish(), None);

        // A break split across pushes (\r then \n) is one break, not an empty line.
        let mut decoder = LineDecoder::default();
        assert_eq!(decoder.push(b"one\r"), vec!["one".to_owned()]);
        assert_eq!(decoder.push(b"\ntwo\n"), vec!["two".to_owned()]);
    }

    /// The verification's cases: the cap applies to complete lines too, in
    /// one push, with CRLF, several at once, at the boundary, across the
    /// chunk that brings the newline, and at `finish()`.
    #[test]
    fn complete_lines_are_cut_at_the_same_cap_as_unfinished_ones() {
        let marked = MAX_LINE_BYTES + TRUNCATION_MARKER.len();
        let mut decoder = LineDecoder::default();
        let mut input = vec![b'a'; 32 * 1024];
        input.push(b'\n');
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].len(), marked);
        assert!(lines[0].ends_with(TRUNCATION_MARKER));

        // A megabyte line with CRLF, then a short line, in one push.
        let mut input = vec![b'b'; 1024 * 1024 + 1];
        input.extend_from_slice(b"\r\nshort\r\n");
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].len(), marked);
        assert_eq!(lines[1], "short");

        // Two long lines in one read are two marked lines.
        let mut input = vec![b'c'; MAX_LINE_BYTES + 1];
        input.push(b'\n');
        input.extend(vec![b'd'; MAX_LINE_BYTES + 1]);
        input.push(b'\n');
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 2);
        assert!(lines.iter().all(|line| line.len() == marked));

        // Exactly the cap is kept whole; one more byte is cut.
        let mut input = vec![b'e'; MAX_LINE_BYTES];
        input.push(b'\n');
        assert_eq!(decoder.push(&input)[0].len(), MAX_LINE_BYTES);

        // The newline arrives in the chunk that crosses the cap: still one
        // marked line, nothing of it repeated, and the next line intact.
        assert!(decoder.push(&vec![b'f'; MAX_LINE_BYTES - 10]).is_empty());
        let lines = decoder.push(b"ffffffffffffffffffff\nnext\n");
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].len(), marked);
        assert_eq!(lines[1], "next");

        // Multibyte text is cut on a character boundary, complete or not.
        let text = "\u{20ac}".repeat(MAX_LINE_BYTES / 3 + 5);
        let mut input = text.clone().into_bytes();
        input.push(b'\n');
        let cut = decoder.push(&input).remove(0);
        let kept = cut.strip_suffix(TRUNCATION_MARKER).unwrap();
        assert!(kept.chars().all(|c| c == '\u{20ac}'), "no replacement character at the cut");
        assert!(kept.len() <= MAX_LINE_BYTES);

        // The final unterminated remainder is cut too.
        assert!(decoder.push(&vec![b'g'; MAX_LINE_BYTES - 1]).is_empty());
        assert!(decoder.push(b"g").is_empty(), "exactly the cap is still pending");
        assert_eq!(decoder.finish().unwrap().len(), MAX_LINE_BYTES);
        let mut decoder = LineDecoder::default();
        // Under the overflow trigger but over it once trimmed at finish: the
        // cap applies to what finish() emits as well.
        assert!(decoder.push(&vec![b'h'; MAX_LINE_BYTES]).is_empty());
        assert_eq!(decoder.finish().unwrap().len(), MAX_LINE_BYTES);
    }

    /// A harmless stand-in for the front door with the real parameter block.
    fn stub_playbook(root: &Path, body: &str) -> PathBuf {
        let dir = root.join("Play book 'quoted'").join("0.6.0");
        let script = playbook::front_door(&dir);
        fs::create_dir_all(script.parent().unwrap()).unwrap();
        fs::write(dir.join("playbook.conf"), "<Playbook><Version>0.6.0</Version></Playbook>").unwrap();
        fs::write(
            &script,
            format!(
                "\u{feff}[CmdletBinding()]\r\nparam(\r\n    [Parameter(Mandatory = $true)]\r\n    [ValidatePattern('^[a-z0-9-]+$')]\r\n    [string[]]$Option,\r\n    [switch]$Unattended,\r\n    [switch]$Restart,\r\n    [string]$RestartComment,\r\n    [switch]$KeepStaging\r\n)\r\n{body}\r\n"
            ),
        )
        .unwrap();
        dir
    }

    fn run(request: InstallRequest, paths: &SessionPaths) -> (SessionRecord, Vec<String>, InstallOutcome) {
        let (record, mut events) = start(request, paths).expect("start the stub installer");
        let mut lines = Vec::new();
        let outcome = block_on(async {
            loop {
                match events.next().await.expect("the reader ends with Finished") {
                    InstallEvent::Lines(batch) => lines.extend(batch),
                    InstallEvent::OutputProblem(problem) => panic!("output problem: {problem}"),
                    InstallEvent::Finished(outcome) => break outcome,
                }
            }
        });
        (record, lines, outcome)
    }

    #[test]
    #[cfg(windows)]
    fn multiple_options_reach_windows_powershell_as_an_array() {
        let temp = TempDir::new("installer-options");
        let dir = stub_playbook(
            temp.path(),
            "foreach ($o in $Option) { Write-Host \"OPTION=$o\" }\r\nWrite-Host \"COUNT=$($Option.Count)\"\r\nWrite-Host \"UNATTENDED=$Unattended RESTART=$Restart\"\r\nWrite-Host \"CWD=$((Get-Location).Path)\"\r\nexit 0",
        );
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir.clone(),
            options: vec![
                "defender-enable".into(),
                "mitigations-default".into(),
                "auto-updates-disable".into(),
            ],
            restart: false,
            restart_comment: None,
        };
        let (record, lines, outcome) = run(request.clone(), &paths);
        assert_eq!(outcome, InstallOutcome::Succeeded, "{lines:?}");
        assert!(lines.contains(&"OPTION=defender-enable".to_owned()), "{lines:?}");
        assert!(lines.contains(&"OPTION=mitigations-default".to_owned()), "{lines:?}");
        assert!(lines.contains(&"OPTION=auto-updates-disable".to_owned()), "{lines:?}");
        assert!(lines.contains(&"COUNT=3".to_owned()), "{lines:?}");
        assert!(lines.contains(&"UNATTENDED=True RESTART=False".to_owned()), "{lines:?}");
        assert!(lines.iter().any(|l| l.starts_with("CWD=") && l.ends_with("0.6.0")), "{lines:?}");
        // The session record points at the log and the exit code was written.
        assert_eq!(record.request, request);
        assert_eq!(record.exit_code(), Some(0));
        assert!(fs::read_to_string(&record.log_path).unwrap().contains("OPTION=defender-enable"));
        assert_eq!(session::load(&paths).unwrap(), Some(record));
    }

    #[test]
    #[cfg(windows)]
    fn exit_codes_and_stderr_come_back_and_output_survives_bad_bytes() {
        let temp = TempDir::new("installer-exit");
        let dir = stub_playbook(
            temp.path(),
            "Write-Host \"[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...\"\r\nWrite-Host \"Grüße ✓\"\r\n$s = [Console]::OpenStandardOutput(); $s.Write([byte[]](0xE9, 0x0A), 0, 2); $s.Flush()\r\nWrite-Host \"AFTER_NON_UTF8\"\r\n[Console]::Error.WriteLine(\"[Atlas] something failed\")\r\nexit 1",
        );
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: true,
            restart_comment: None,
        };
        let (record, lines, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Failed(1), "{lines:?}");
        assert!(lines.contains(&"Grüße ✓".to_owned()), "{lines:?}");
        assert!(lines.contains(&"\u{FFFD}".to_owned()), "{lines:?}");
        assert!(lines.contains(&"AFTER_NON_UTF8".to_owned()), "{lines:?}");
        assert!(lines.contains(&"[Atlas] something failed".to_owned()), "{lines:?}");
        assert_eq!(record.exit_code(), Some(1));
        assert!(lines.iter().any(|l| Phase::from_line(l) == Some(Phase::Applying)));
    }

    #[test]
    #[cfg(windows)]
    fn a_finished_session_can_be_reattached_from_its_record() {
        let temp = TempDir::new("installer-reattach");
        let dir = stub_playbook(temp.path(), "Write-Host \"first line\"\r\nexit 2");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let (record, _, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Failed(2));
        assert!(!record.is_alive());

        let mut events = reattach(&record);
        let (lines, outcome) = block_on(async {
            let mut lines = Vec::new();
            loop {
                match events.next().await.unwrap() {
                    InstallEvent::Lines(batch) => lines.extend(batch),
                    InstallEvent::OutputProblem(_) => {}
                    InstallEvent::Finished(outcome) => break (lines, outcome),
                }
            }
        });
        assert_eq!(lines, vec!["first line".to_owned()]);
        assert_eq!(outcome, InstallOutcome::Failed(2));

        // Without an exit file the ended process is reported as lost, not as a success.
        fs::remove_file(&record.exit_path).unwrap();
        let mut events = reattach(&record);
        let outcome = block_on(async {
            loop {
                if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                    break outcome;
                }
            }
        });
        assert_eq!(outcome, InstallOutcome::Lost);
    }

    #[test]
    fn a_missing_front_door_is_refused_before_anything_starts() {
        let temp = TempDir::new("installer-missing");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: temp.path().join("nowhere"),
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        assert!(start(request, &paths).is_err());
        assert!(session::load(&paths).unwrap().is_none());
    }
    #[test]
    #[cfg(windows)]
    fn a_record_that_cannot_be_written_starts_nothing() {
        let temp = TempDir::new("installer-record-failure");
        let dir = stub_playbook(temp.path(), "Write-Host \"STUB_RAN\"\r\nexit 0");
        let paths = SessionPaths::under(&temp.path().join("App"));
        // A directory where the record file should be makes the record write fail.
        fs::create_dir_all(&paths.record).unwrap();
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let error = start(request, &paths).unwrap_err();
        assert!(error.to_string().contains("nothing was started"), "{error:#}");
        std::thread::sleep(Duration::from_millis(1500));
        let artifacts: Vec<String> = fs::read_dir(&paths.logs)
            .map(|d| d.flatten().map(|e| e.file_name().to_string_lossy().into_owned()).collect())
            .unwrap_or_default();
        assert!(artifacts.is_empty(), "no log, exit or go file may remain: {artifacts:?}");
    }

    #[test]
    #[cfg(windows)]
    fn a_running_install_refuses_a_second_start_and_hands_back_its_record() {
        let temp = TempDir::new("installer-second-start");
        let dir = stub_playbook(temp.path(), "Start-Sleep -Seconds 3\r\nWrite-Host \"first done\"\r\nexit 0");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let (first, events) = start(request.clone(), &paths).unwrap();
        assert!(first.is_alive());
        let error = start(request.clone(), &paths).unwrap_err();
        let running = error.downcast::<AlreadyRunning>().expect("a second start reports the running install");
        assert_eq!(running.0.pid, first.pid);
        assert_eq!(
            session::load(&paths).unwrap().unwrap().pid,
            first.pid,
            "the record still names the first install"
        );
        let outcome = block_on(async {
            let mut events = events;
            loop {
                if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                    break outcome;
                }
            }
        });
        assert_eq!(outcome, InstallOutcome::Succeeded);
        // Once it has ended, a new install may start and gets its own artifacts.
        let (second, _, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Succeeded);
        assert_ne!(second.log_path, first.log_path);
        assert_ne!(second.id, first.id);
    }

    #[test]
    fn a_held_launch_lock_refuses_a_start() {
        let temp = TempDir::new("installer-launch-lock");
        let dir = stub_playbook(temp.path(), "exit 0");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let held = session::LaunchLock::acquire(&paths).unwrap();
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let error = start(request, &paths).unwrap_err();
        assert!(format!("{error:#}").contains("another Atlas window"), "{error:#}");
        assert!(session::load(&paths).unwrap().is_none());
        drop(held);
        assert!(session::LaunchLock::acquire(&paths).is_ok());
    }

    #[test]
    fn a_completed_session_replays_the_whole_log() {
        let temp = TempDir::new("installer-large-replay");
        let logs = temp.path().join("Logs");
        fs::create_dir_all(&logs).unwrap();
        let log_path = logs.join("install-large.log");
        let exit_path = logs.join("install-large.exit");
        let mut text = String::new();
        let padding = "x".repeat(110);
        for index in 0..80_000 {
            text.push_str(&format!("line {index} {padding}\n"));
        }
        text.push_str("FINAL_SENTINEL\n");
        text.push_str("tail without newline \u{20ac}");
        fs::write(&log_path, text.as_bytes()).unwrap();
        assert!(text.len() > 9 * 1024 * 1024, "the log must span several read chunks");
        fs::write(&exit_path, "1").unwrap();
        let record = SessionRecord {
            id: "large".into(),
            pid: 0,
            process_start: 0,
            started_at: String::new(),
            log_path,
            exit_path,
            request: InstallRequest {
                playbook_dir: temp.path().into(),
                options: vec![],
                restart: false,
                restart_comment: None,
            },
        };
        let mut events = reattach(&record);
        let (lines, outcome) = block_on(async {
            let mut lines = Vec::new();
            loop {
                match events.next().await.unwrap() {
                    InstallEvent::Lines(batch) => lines.extend(batch),
                    InstallEvent::OutputProblem(problem) => panic!("{problem}"),
                    InstallEvent::Finished(outcome) => break (lines, outcome),
                }
            }
        });
        assert_eq!(outcome, InstallOutcome::Failed(1));
        assert_eq!(lines.len(), 80_002, "every line reaches the UI");
        assert_eq!(lines[80_000], "FINAL_SENTINEL");
        assert_eq!(lines[80_001], "tail without newline \u{20ac}");
    }

    #[test]
    #[cfg(windows)]
    fn a_backlog_written_just_before_exit_is_not_lost() {
        let temp = TempDir::new("installer-backlog");
        let dir = stub_playbook(
            temp.path(),
            "$out = [Console]::Out\r\n$pad = 'y' * 120\r\nfor ($i = 0; $i -lt 60000; $i++) { $out.WriteLine(\"L$i $pad\") }\r\n$out.WriteLine('FINAL_SENTINEL')\r\n$out.Flush()\r\nexit 0",
        );
        let paths = SessionPaths::under(&temp.path().join("App"));
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let (_, lines, outcome) = run(request, &paths);
        assert_eq!(outcome, InstallOutcome::Succeeded);
        assert_eq!(lines.last().map(String::as_str), Some("FINAL_SENTINEL"), "{} lines", lines.len());
        assert!(lines.len() >= 60_001, "{} lines", lines.len());
    }
    /// A stub whose front door records that it ran in a side file, so a test
    /// can tell whether the script body was ever entered.
    fn marking_stub(root: &Path, body: &str) -> (InstallRequest, PathBuf) {
        let marker = root.join("front-door-ran.txt");
        let dir = stub_playbook(
            root,
            &format!("Set-Content -LiteralPath '{}' -Value 'ran'\r\n{body}", marker.display()),
        );
        (
            InstallRequest {
                playbook_dir: dir,
                options: vec!["defender-enable".into()],
                restart: false,
                restart_comment: None,
            },
            marker,
        )
    }

    #[test]
    #[cfg(windows)]
    fn a_stale_windows_cleanup_leaves_a_newer_live_session_alone() {
        let temp = TempDir::new("installer-stale-clear");
        let paths = SessionPaths::under(&temp.path().join("App"));
        // Window A: an attempt that fails; A keeps this record in memory.
        let (previous, _) = marking_stub(temp.path(), "exit 1");
        let (failed, _, outcome) = run(previous, &paths);
        assert_eq!(outcome, InstallOutcome::Failed(1));
        // Window B: a newer, live install.
        let (request, _) = marking_stub(temp.path(), "Start-Sleep -Seconds 3\r\nexit 0");
        let (live, events) = start(request.clone(), &paths).unwrap();
        assert_ne!(live.id, failed.id);
        // Window A leaves its failed result: only its own record may go.
        assert!(!session::release(&paths, &failed.id).unwrap(), "a stale id removes nothing");
        assert_eq!(session::load(&paths).unwrap().map(|r| r.id), Some(live.id.clone()));
        let error = start(request, &paths).unwrap_err();
        let running = error.downcast::<AlreadyRunning>().expect("the live install is still found");
        assert_eq!(running.0.id, live.id);
        let outcome = block_on(async {
            let mut events = events;
            loop {
                if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                    break outcome;
                }
            }
        });
        assert_eq!(outcome, InstallOutcome::Succeeded);
        assert!(session::release(&paths, &live.id).unwrap());
        assert!(session::load(&paths).unwrap().is_none());
    }

    #[test]
    fn abandoned_and_unreadable_records_do_not_own_anything() {
        let temp = TempDir::new("installer-abandoned");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let pending = SessionRecord {
            id: "pending".into(),
            pid: 0,
            process_start: 0,
            started_at: String::new(),
            log_path: paths.logs.join("x.log"),
            exit_path: paths.logs.join("x.exit"),
            request: InstallRequest {
                playbook_dir: temp.path().into(),
                options: vec![],
                restart: false,
                restart_comment: None,
            },
        };
        session::save(&paths, &pending).unwrap();
        assert!(!pending.is_alive());
        {
            let lock = LaunchLock::acquire(&paths).unwrap();
            assert!(matches!(lock.inspect(&paths), Inspection::Abandoned));
        }
        assert!(!session::release(&paths, "pending").unwrap(), "an abandoned record is nobody's to release");
        // Unparseable is unknown ownership, not abandonment: nothing may touch it.
        fs::write(&paths.record, "{ not json").unwrap();
        let lock = LaunchLock::acquire(&paths).unwrap();
        assert!(matches!(lock.inspect(&paths), Inspection::Unreadable(_)));
        assert!(matches!(lock.inspect(&SessionPaths::under(&temp.path().join("empty"))), Inspection::None));
        drop(lock);
        assert!(session::release(&paths, "pending").is_err(), "an unreadable record cannot be released");
        assert!(paths.record.is_file(), "the record is preserved");
        let dir = stub_playbook(temp.path(), "exit 0");
        let request = InstallRequest {
            playbook_dir: dir,
            options: vec!["defender-enable".into()],
            restart: false,
            restart_comment: None,
        };
        let error = start(request, &paths).unwrap_err();
        assert!(format!("{error:#}").contains("cannot be read"), "{error:#}");
        assert_eq!(fs::read_to_string(&paths.record).unwrap(), "{ not json", "the record is not replaced");
    }

    #[test]
    #[cfg(windows)]
    fn a_transiently_unreadable_record_keeps_its_live_owner() {
        use std::os::windows::fs::OpenOptionsExt;
        const FILE_SHARE_DELETE: u32 = 0x4;
        let temp = TempDir::new("installer-unreadable-live");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let (request, _) = marking_stub(
            temp.path(),
            "Start-Sleep -Seconds 4
exit 0",
        );
        let (live, events) = start(request.clone(), &paths).unwrap();
        assert!(live.is_alive());

        // Another process holds the record open without read sharing.
        let holder =
            fs::OpenOptions::new().read(true).share_mode(FILE_SHARE_DELETE).open(&paths.record).unwrap();
        assert!(fs::read_to_string(&paths.record).is_err(), "the record must be unreadable for this test");
        {
            let lock = LaunchLock::acquire(&paths).unwrap();
            match lock.inspect(&paths) {
                Inspection::Unreadable(_) => {}
                other => panic!("unreadable must not be classified as {other:?}"),
            }
        }
        assert!(session::release(&paths, &live.id).is_err());
        LAST_SPAWNED.with(|last| last.set(0));
        let error = start(request.clone(), &paths).unwrap_err();
        assert!(format!("{error:#}").contains("cannot be read"), "{error:#}");
        assert_eq!(LAST_SPAWNED.with(|last| last.get()), 0, "no second child may be launched");
        drop(holder);

        // Once readable again, the original live session is recovered.
        assert_eq!(session::load(&paths).unwrap().map(|r| r.id), Some(live.id.clone()));
        {
            let lock = LaunchLock::acquire(&paths).unwrap();
            assert!(matches!(lock.inspect(&paths), Inspection::Live(ref r) if r.id == live.id));
        }
        let error = start(request, &paths).unwrap_err();
        let running = error.downcast::<AlreadyRunning>().expect("the live install is found again");
        assert_eq!(running.0.id, live.id);
        let outcome = block_on(async {
            let mut events = events;
            loop {
                if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                    break outcome;
                }
            }
        });
        assert_eq!(outcome, InstallOutcome::Succeeded);
    }

    #[test]
    #[cfg(windows)]
    fn record_publication_failures_never_reach_the_front_door() {
        for point in [FailPoint::InitialRecord, FailPoint::RecordRewrite, FailPoint::GoAhead] {
            let temp = TempDir::new("installer-fail-point");
            let paths = SessionPaths::under(&temp.path().join("App"));
            let (request, marker) = marking_stub(temp.path(), "exit 0");
            FAIL_AT.with(|fail| fail.set(Some(point)));
            LAST_SPAWNED.with(|last| last.set(0));
            let result = start(request, &paths);
            FAIL_AT.with(|fail| fail.set(None));
            let error = result.err().unwrap_or_else(|| panic!("{point:?} must fail the start"));
            assert!(error.to_string().contains("nothing was started"), "{point:?}: {error:#}");
            let spawned = LAST_SPAWNED.with(|last| last.get());
            if point == FailPoint::InitialRecord {
                assert_eq!(spawned, 0, "nothing is spawned before the record is durable");
            } else {
                assert_ne!(spawned, 0);
                assert!(
                    !crate::services::system::process_alive(spawned, 0),
                    "{point:?}: the waiting child is gone"
                );
            }
            std::thread::sleep(Duration::from_millis(500));
            assert!(!marker.exists(), "{point:?}: the front door must not run");
            assert!(session::load(&paths).unwrap().is_none(), "{point:?}: no record remains");
            let artifacts: Vec<String> = fs::read_dir(&paths.logs)
                .map(|d| d.flatten().map(|e| e.file_name().to_string_lossy().into_owned()).collect())
                .unwrap_or_default();
            assert!(artifacts.is_empty(), "{point:?}: no artifacts remain: {artifacts:?}");
        }
    }
    #[test]
    fn the_launcher_record_names_this_executable_for_the_payload() {
        let temp = TempDir::new("installer-launcher");
        let paths = SessionPaths::under(&temp.path().join("App"));
        assert!(session::load_launcher(&paths).unwrap().is_none());
        let written = session::record_launcher(&paths).unwrap();
        assert_eq!(written.exe, std::env::current_exe().unwrap());
        assert_eq!(session::load_launcher(&paths).unwrap(), Some(written));
        // The payload reads it as JSON with an "exe" property.
        let text = fs::read_to_string(session::launcher_path(&paths)).unwrap();
        let json: serde_json::Value = serde_json::from_str(&text).unwrap();
        assert!(json["exe"].as_str().is_some_and(|exe| exe.ends_with(".exe")));
    }
}
