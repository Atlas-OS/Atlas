//! Local support evidence. No upload, media copies, registry changes or servicing.

use std::{
    fs::{self, File, OpenOptions},
    io::{self, Read, Write},
    os::windows::fs::OpenOptionsExt,
    path::{Path, PathBuf},
    sync::{
        Arc, Mutex, OnceLock,
        atomic::{AtomicBool, Ordering},
    },
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result};
use serde_json::{Value, json};
use windows::Win32::Storage::FileSystem::FILE_SHARE_READ;
use windows::Win32::UI::WindowsAndMessaging::{
    MB_ICONERROR, MB_ICONINFORMATION, MB_OK, MB_SETFOREGROUND, MESSAGEBOX_STYLE, MessageBoxW,
};
use windows::core::{HSTRING, PCWSTR};
use zip::{ZipWriter, write::SimpleFileOptions};

use super::diagnostics_redaction::Redactor;
use super::files::is_reparse_point;

/// Size at which the app log rolls over to a new file.
const LOG_ROLL_BYTES: u64 = 4 * 1024 * 1024;
/// Rolled-over copies kept of the current process's log.
const LOG_ROTATIONS: usize = 3;
/// App logs of earlier runs kept in the logs folder.
const APP_LOGS_KEPT: usize = 36;
// Per-file, total and entry limits of an archive: the report service refuses
// anything beyond them.
const FILE_LIMIT: u64 = 32 * 1024 * 1024;
const TOTAL_LIMIT: u64 = 256 * 1024 * 1024;
const MAX_ENTRIES: usize = 2048;
/// How deep the collector walks into a folder.
const MAX_DEPTH: usize = 12;
/// Kept free within TOTAL_LIMIT for manifest.json, which is written last. The
/// report service counts every member against the total and caps the
/// manifest at this size.
const MANIFEST_RESERVE: u64 = 2 * 1024 * 1024;
static LOG_LOCATION: OnceLock<PathBuf> = OnceLock::new();
/// The panic dialog has been shown (or is showing): a second panic on another
/// thread, or one raised while the dialog is up, must not stack another.
static PANIC_SHOWN: AtomicBool = AtomicBool::new(false);
/// Not translated: it is shown when the app has no window (or no working
/// one) to speak through, and must never depend on anything that can fail.
const DIALOG_TITLE: &str = "Atlas Manager";

/// A message box owned by no window, for the moments the app has none: a
/// panic, or a headless command-line run. Blocks until dismissed.
fn message_box(text: &str, style: MESSAGEBOX_STYLE) {
    let title = HSTRING::from(DIALOG_TITLE);
    let text = HSTRING::from(text);
    unsafe {
        MessageBoxW(None, PCWSTR(text.as_ptr()), PCWSTR(title.as_ptr()), MB_OK | MB_SETFOREGROUND | style);
    }
}

/// Tells the user how `--export-diagnostics` ended. That run has no window,
/// so a message box is the only place the answer can go.
pub fn report_headless_export(result: &Result<PathBuf>) {
    match result {
        Ok(path) => {
            message_box(&format!("Diagnostics were saved to {}.", path.display()), MB_ICONINFORMATION)
        }
        Err(error) => message_box(&format!("Couldn't export diagnostics. {error:#}"), MB_ICONERROR),
    }
}

fn unique_id() -> String {
    format!(
        "{}-{}",
        SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_nanos(),
        std::process::id()
    )
}

/// A log file that others may read while it is written.
fn create_log(path: &Path) -> io::Result<File> {
    OpenOptions::new().create_new(true).write(true).share_mode(FILE_SHARE_READ.0).open(path)
}

struct RollingLog {
    path: PathBuf,
    file: Option<File>,
    bytes: u64,
    limit: u64,
}

impl RollingLog {
    fn new(path: PathBuf, limit: u64) -> io::Result<Self> {
        let file = create_log(&path)?;
        Ok(Self { path, file: Some(file), bytes: 0, limit })
    }

    fn rotated(&self, index: usize) -> PathBuf {
        self.path.with_extension(format!("{index}.log"))
    }
}

impl Write for RollingLog {
    fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
        if self.bytes >= self.limit {
            self.file.take();
            let _ = fs::remove_file(self.rotated(LOG_ROTATIONS));
            for index in (1..LOG_ROTATIONS).rev() {
                let source = self.rotated(index);
                if source.exists() {
                    fs::rename(source, self.rotated(index + 1))?;
                }
            }
            fs::rename(&self.path, self.rotated(1))?;
            self.file = Some(create_log(&self.path)?);
            self.bytes = 0;
        }
        let count = bytes.len().min((self.limit - self.bytes) as usize);
        let file = self.file.as_mut().ok_or_else(|| io::Error::other("app log unavailable"))?;
        file.write_all(&bytes[..count])?;
        file.flush()?;
        self.bytes += count as u64;
        Ok(count)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.file.as_mut().ok_or_else(|| io::Error::other("app log unavailable"))?.flush()
    }
}

#[derive(Clone)]
struct SharedLog(Arc<Mutex<RollingLog>>);
impl Write for SharedLog {
    fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
        self.0.lock().map_err(|_| io::Error::other("app log lock poisoned"))?.write(bytes)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.0.lock().map_err(|_| io::Error::other("app log lock poisoned"))?.flush()
    }
}

pub fn init_logging() {
    let open = |root: PathBuf| -> io::Result<RollingLog> {
        fs::create_dir_all(&root)?;
        // Prune app logs only; installation logs share this folder. A log
        // another instance holds open cannot be deleted, so it survives.
        let mut old: Vec<_> = fs::read_dir(&root)?
            .flatten()
            .filter(|entry| {
                let name = entry.file_name().to_string_lossy().into_owned();
                name.starts_with("app-") && name.ends_with(".log")
            })
            .collect();
        old.sort_by_key(|entry| std::cmp::Reverse(entry.file_name()));
        for entry in old.into_iter().skip(APP_LOGS_KEPT) {
            let _ = fs::remove_file(entry.path());
        }
        RollingLog::new(root.join(format!("app-{}.log", unique_id())), LOG_ROLL_BYTES)
    };
    let primary = super::settings::app_data_dir().join("Logs");
    let opened = open(primary.clone()).or_else(|error| {
        eprintln!("Cannot create Atlas app log in {}: {error}", primary.display());
        open(std::env::temp_dir().join("AtlasDiagnostics"))
    });
    let mut builder =
        env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("warn,AtlasManager=info"));
    builder.format_timestamp_millis();
    // Keep Atlas's support history even when the launching shell sets a broad
    // RUST_LOG=warn/off filter. Dependency verbosity remains configurable.
    builder.filter_module(module_path!().split("::").next().unwrap(), log::LevelFilter::Info);
    if let Ok(writer) = opened {
        let log_path = writer.path.clone();
        let _ = LOG_LOCATION.set(log_path.clone());
        let shared = SharedLog(Arc::new(Mutex::new(writer)));
        builder.target(env_logger::Target::Pipe(Box::new(shared.clone())));
        std::panic::set_hook(Box::new(move |panic| {
            // Written directly so log filters cannot drop it; try_lock because
            // the panic may come from inside the logger; flushed because
            // release builds abort on panic.
            if let Ok(mut log) = shared.0.try_lock() {
                let _ = writeln!(
                    log,
                    "{} PANIC {panic}\n{}",
                    chrono::Utc::now(),
                    std::backtrace::Backtrace::force_capture()
                );
                let _ = log.flush();
            }
            // The window is about to vanish; say so, and where the details
            // are, once. Test binaries panic on purpose and must not block.
            if !cfg!(test) && !PANIC_SHOWN.swap(true, Ordering::SeqCst) {
                message_box(
                    &format!(
                        "Atlas Manager stopped unexpectedly. Details were written to {}.",
                        log_path.display()
                    ),
                    MB_ICONERROR,
                );
            }
        }));
    }
    builder.init();
    // A tester's log excerpt names the candidate it came from.
    let candidate = match (super::embedded::rc_id(), super::embedded::source_commit()) {
        (Some(rc), Some(commit)) => format!(" (candidate {rc}, source {commit})"),
        (Some(rc), None) => format!(" (candidate {rc})"),
        (None, Some(commit)) => format!(" (source {commit})"),
        (None, None) => String::new(),
    };
    log::info!(
        "Atlas Manager {}{candidate} started; pid={}; Windows={:?}; elevated={}",
        env!("CARGO_PKG_VERSION"),
        std::process::id(),
        super::system::SystemInfo::read(),
        super::system::is_elevated()
    );
}

/// The archive's READ-ME.txt.
const README_TEXT: &str = "Atlas diagnostics\n\nPrepared for a bug report. \"Send a report\" in Atlas Manager shares it privately with the Atlas team; posts in community or development channels are public. Known credential formats and personal account details are automatically redacted; consistent anonymous labels keep related evidence connected.\n\nError details, timestamps, versions, hardware models, application names and operation IDs are kept to help investigate. Nothing is uploaded automatically. See BUG-REPORT.txt for what to include with your report and manifest.json for collection details.\n";

/// The archive's BUG-REPORT.txt.
const BUG_REPORT_TEXT: &str = "What were you doing?\nWhat did you expect?\nWhat happened (include exact message)?\nApproximate time and timezone:\nDoes it happen again?\nAttach this ZIP to your report. \"Send a report\" in Atlas Manager shares it privately with the Atlas team; posts in community or development channels are public.\n";

struct Bundle {
    zip: ZipWriter<File>,
    entries: Vec<Value>,
    bytes: u64,
    files: usize,
    redactor: Redactor,
}

/// A media job directory, or a 0.6.0 release candidate's ISO job. An ISO
/// build may leave its 4 MB copy of the licence notices there, which is not
/// evidence.
fn is_iso_job(name: &str) -> bool {
    ["media/", "app/ISO/"].iter().any(|root| name.strip_prefix(root).is_some_and(|job| !job.contains('/')))
}

/// A staging folder holds thousands of Atlas's files; inside one, only its
/// request.json and AtlasModules/Logs are visited, so it cannot use up the
/// entry limit. `parent` is the archive name of the folder holding `child`.
fn skips_staged_files(parent: &str, child: &str) -> bool {
    let Some(relative) = parent.strip_prefix("playbook/state/Staging/") else { return false };
    let parts: Vec<_> = relative.split('/').collect();
    let child = child.to_ascii_lowercase();
    match parts[..] {
        [_, executables] if executables.eq_ignore_ascii_case("Executables") => {
            child != "request.json" && child != "atlasmodules"
        }
        [_, executables, modules]
            if executables.eq_ignore_ascii_case("Executables")
                && modules.eq_ignore_ascii_case("AtlasModules") =>
        {
            child != "logs"
        }
        _ => false,
    }
}

impl Bundle {
    fn new(file: File) -> Self {
        Self { zip: ZipWriter::new(file), entries: Vec::new(), bytes: 0, files: 0, redactor: Redactor::new() }
    }

    fn note(&mut self, name: &str, status: impl ToString) {
        self.entries.push(
            json!({"path": self.redactor.text(name), "status": self.redactor.text(&status.to_string())}),
        );
    }

    /// Whether `len` more bytes of evidence fit, leaving room for the manifest.
    fn fits(&self, len: u64) -> bool {
        len <= FILE_LIMIT && self.bytes + len + MANIFEST_RESERVE <= TOTAL_LIMIT
    }

    /// Adds a member of already-redacted bytes and counts them.
    fn write_member(&mut self, name: &str, bytes: &[u8]) -> Result<()> {
        self.zip.start_file(
            name,
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
        )?;
        self.zip.write_all(bytes)?;
        self.bytes += bytes.len() as u64;
        Ok(())
    }

    /// Writes one of the archive's own texts and returns its redacted size.
    fn text(&mut self, name: &str, bytes: &[u8]) -> Result<u64> {
        let name = self.redactor.text(name);
        let bytes = self.redactor.file(bytes).context("diagnostic text encoding is unsupported")?;
        self.write_member(&name, &bytes)?;
        Ok(bytes.len() as u64)
    }

    fn collect(&mut self, path: &Path, name: &str, depth: usize) -> Result<()> {
        if self.files >= MAX_ENTRIES || depth > MAX_DEPTH {
            self.note(name, "omitted: file/depth limit");
            return Ok(());
        }
        self.files += 1;
        let metadata = match fs::symlink_metadata(path) {
            Ok(metadata) => metadata,
            Err(error) => {
                self.note(name, format!("unavailable: {error}"));
                return Ok(());
            }
        };
        if is_reparse_point(&metadata) {
            self.note(name, "omitted: reparse point");
            return Ok(());
        }
        if metadata.is_dir() {
            match fs::read_dir(path) {
                Ok(entries) => {
                    let mut entries: Vec<_> = entries
                        .filter_map(|entry| match entry {
                            Ok(entry) => Some(entry),
                            Err(error) => {
                                self.note(name, format!("directory entry unavailable: {error}"));
                                None
                            }
                        })
                        .collect();
                    entries.sort_by_key(|entry| std::cmp::Reverse(entry.file_name()));
                    let iso_job = is_iso_job(name);
                    for entry in entries {
                        let child = entry.file_name().to_string_lossy().into_owned();
                        if (iso_job && child.eq_ignore_ascii_case(super::iso::NOTICES))
                            || skips_staged_files(name, &child)
                        {
                            continue;
                        }
                        if self.files >= MAX_ENTRIES {
                            self.note(name, "remaining entries omitted: file limit");
                            break;
                        }
                        self.collect(&entry.path(), &format!("{name}/{child}"), depth + 1)?;
                    }
                }
                Err(error) => self.note(name, format!("unreadable directory: {error}")),
            }
            return Ok(());
        }
        // An allowlist prevents collecting media, executables, scripts or dumps.
        let allowed = path.extension().is_some_and(|extension| {
            matches!(extension.to_str(), Some("log" | "json" | "exit" | "txt" | "invalid"))
        });
        if !metadata.is_file() || !allowed {
            return Ok(());
        }
        if !self.fits(metadata.len()) {
            self.note(name, format!("omitted: size limit ({} bytes)", metadata.len()));
            return Ok(());
        }
        let mut bytes = Vec::new();
        match File::open(path).and_then(|file| file.take(FILE_LIMIT + 1).read_to_end(&mut bytes)) {
            Ok(_) if self.fits(bytes.len() as u64) => {}
            Ok(_) => {
                self.note(name, "omitted: file grew beyond size limit");
                return Ok(());
            }
            Err(error) => {
                self.note(name, format!("unreadable: {error}"));
                return Ok(());
            }
        }
        let Some(bytes) = self.redactor.file(&bytes) else {
            self.note(name, "omitted: unsupported text encoding");
            return Ok(());
        };
        if !self.fits(bytes.len() as u64) {
            self.note(name, "omitted: redacted text exceeds size limit");
            return Ok(());
        }
        let name = self.redactor.text(name);
        // Write the already-redacted bytes once; their digest must describe
        // exactly the contents reviewers receive.
        self.write_member(&name, &bytes)?;
        let hash = super::releases::sha256_bytes(&bytes);
        self.entries.push(json!({"path":name,"status":"included","bytes":bytes.len(),"sha256":hash}));
        Ok(())
    }
}

/// The section the collector was working on: it announces each as it starts.
fn stuck_section(log: &str) -> Option<&str> {
    log.lines().rev().find_map(|line| line.trim_end().strip_prefix("Collecting: "))
}

fn collect_report(directory: &Path) -> Result<()> {
    run_collector(
        directory,
        include_bytes!("../../../tools/dev/Get-AtlasInstallReport.ps1"),
        Duration::from_secs(60),
    )
}

fn run_collector(directory: &Path, script: &[u8], deadline: Duration) -> Result<()> {
    let child = spawn_collector(directory, script)?;
    wait_collector(child, &directory.join("collector.log"), deadline)
}

/// Starts the collector on `script`, logging to `collector.log`.
fn spawn_collector(directory: &Path, script: &[u8]) -> Result<std::process::Child> {
    use std::process::Stdio;
    let output = File::create(directory.join("collector.log"))?;
    // Feed the collector directly: never execute a script from an app-data
    // directory that a different process could replace before launch.
    // The paths travel in the environment, so no character in a profile name
    // can end a quoted string early. The collector appends each finished
    // section to the partial report, which survives a timeout.
    let mut child = super::powershell::command()
        .arg("-Command")
        .arg(
            "$source = [Console]::In.ReadToEnd(); & ([scriptblock]::Create($source)) \
             -OutputPath $env:ATLAS_REPORT_OUTPUT -PartialPath $env:ATLAS_REPORT_PARTIAL",
        )
        .env("ATLAS_REPORT_OUTPUT", directory.join("machine-report.txt"))
        .env("ATLAS_REPORT_PARTIAL", directory.join("machine-report.partial.txt"))
        .stdin(Stdio::piped())
        .stdout(output.try_clone()?)
        .stderr(output)
        .spawn()?;
    if let Err(error) = child.stdin.take().context("collector input")?.write_all(script) {
        let _ = child.kill();
        let _ = child.wait();
        return Err(error.into());
    }
    Ok(child)
}

/// Waits up to `deadline` for the collector to finish. On a timeout, names
/// the section it was working on, from its `log`.
fn wait_collector(mut child: std::process::Child, log: &Path, deadline: Duration) -> Result<()> {
    let start = Instant::now();
    loop {
        if let Some(status) = child.try_wait()? {
            anyhow::ensure!(status.success(), "machine collector exited {status}");
            return Ok(());
        }
        if start.elapsed() > deadline {
            child.kill()?;
            child.wait()?;
            let section = stuck_section(&String::from_utf8_lossy(&fs::read(log).unwrap_or_default()))
                .map(|title| format!(" in section '{title}'"))
                .unwrap_or_default();
            anyhow::bail!(
                "machine collector timed out after {} seconds{section}; finished sections and other logs remain available",
                deadline.as_secs()
            );
        }
        std::thread::sleep(Duration::from_millis(100));
    }
}

/// Works before Atlas installation and without elevation. Missing protected files
/// are reported instead of aborting the rest of the export.
pub fn export(root: &Path, package: Option<Value>) -> Result<PathBuf> {
    let saved = super::settings::read_from(&root.join("settings.json"));
    let package_directory = saved.settings.draft.and_then(|draft| draft.playbook_dir).or_else(|| {
        super::session::load(&super::session::SessionPaths::under(root))
            .ok()
            .flatten()
            .map(|session| session.request.playbook_dir)
    });
    let package = package.or_else(|| {
        package_directory
            .as_ref()
            .and_then(|path| super::playbook::identity(path))
            .and_then(|identity| serde_json::to_value(identity).ok())
    });
    let exports = root.join("Diagnostics");
    fs::create_dir_all(&exports)?;
    let id = unique_id();
    let working = exports.join(format!("collect-{id}"));
    fs::create_dir(&working)?;
    let collector = collect_report(&working).err().map(|error| format!("{error:#}"));
    let archive = Archive { root, working: &working, package_directory: package_directory.as_deref() };
    let result = archive.write_to(&exports.join(format!("Atlas-diagnostics-{id}.zip")), package, collector);
    let _ = fs::remove_dir_all(&working);
    result.context("export Atlas diagnostics")
}

/// Where the evidence for one archive comes from.
struct Archive<'a> {
    root: &'a Path,
    /// The collector's folder for this export.
    working: &'a Path,
    package_directory: Option<&'a Path>,
}

impl Archive<'_> {
    /// Writes the archive beside `destination` as a `.partial` file first,
    /// renamed into place only once it is complete.
    fn write_to(
        &self,
        destination: &Path,
        package: Option<Value>,
        collector: Option<String>,
    ) -> Result<PathBuf> {
        let temporary = destination.with_extension("partial");
        let output = OpenOptions::new().create_new(true).write(true).open(&temporary)?;
        let written = self
            .write(Bundle::new(output), package, collector)
            .and_then(|()| Ok(fs::rename(&temporary, destination)?));
        if written.is_err() {
            let _ = fs::remove_file(&temporary);
        }
        written.map(|()| destination.to_path_buf())
    }

    /// Collects everything into `bundle`, adds the manifest last, and writes
    /// the archive to disk.
    fn write(&self, mut bundle: Bundle, package: Option<Value>, collector: Option<String>) -> Result<()> {
        bundle.text("READ-ME.txt", README_TEXT.as_bytes())?;
        bundle.collect(self.working, "report", 0)?;
        if let Some(path) = self.package_directory {
            bundle.collect(&path.join("Executables/AtlasModules/Logs"), "playbook/staged-logs", 0)?;
        }
        bundle.text("BUG-REPORT.txt", BUG_REPORT_TEXT.as_bytes())?;
        // app/Preparation is where the 0.6.0 release candidates kept preparation
        // jobs; current ones are in the protected root collected below.
        for name in ["Logs", "Preparation", "settings.json", "settings.json.invalid", "session.json"] {
            bundle.collect(&self.root.join(name), &format!("app/{name}"), 0)?;
        }
        if let Some(path) = LOG_LOCATION.get() {
            bundle.collect(path, "app/current-process.log", 0)?;
        }
        let settings = self.root.join("settings.json");
        match super::recovery_app::preparation_root(&settings) {
            Ok(path) => bundle.collect(&path, "preparation", 0)?,
            Err(error) => bundle.note("preparation", error),
        }
        match super::recovery_app::media_root(&settings) {
            Ok(path) => bundle.collect(&path, "media", 0)?,
            Err(error) => bundle.note("media", error),
        }
        if let Some(local) = std::env::var_os("LOCALAPPDATA") {
            let local = PathBuf::from(local);
            bundle.collect(&local.join("AtlasOS/Logs"), "user/logs", 0)?;
            bundle.collect(&local.join("Atlas-desktop-recovery.log"), "user/desktop-recovery.log", 0)?;
        }
        if let Some(windows) = std::env::var_os("WINDIR") {
            let windows = PathBuf::from(windows);
            bundle.collect(&windows.join("AtlasModules/Logs"), "playbook/logs", 0)?;
            bundle.collect(&windows.join("AtlasOS"), "playbook/state", 0)?;
            bundle.collect(&windows.join("AtlasISO/setup.log"), "iso/setup.log", 0)?;
            bundle.collect(&windows.join("AtlasISO/network-drivers.json"), "iso/network-drivers.json", 0)?;
        }
        // Release-candidate ISO jobs go last, so they cannot use up the
        // budget current evidence needs.
        bundle.collect(&self.root.join("ISO"), "app/ISO", 0)?;

        let executable = std::env::current_exe().ok();
        let info = super::system::SystemInfo::read();
        // The report service refuses an archive unless its manifest says
        // schema 2 and redaction public-v1.
        let manifest = json!({
            "schema": 2,
            "redaction": "public-v1",
            "createdAt": chrono::Utc::now().to_rfc3339(),
            "appVersion": env!("CARGO_PKG_VERSION"),
            "rcId": super::embedded::rc_id(),
            "sourceCommit": super::embedded::source_commit(),
            "appSha256": executable.as_ref().and_then(|path| super::releases::sha256_file(path).ok()),
            "executable": executable,
            "package": package,
            "windows": {"build": info.build_label(), "edition": info.edition_id, "release": info.display_version},
            "elevated": super::system::is_elevated(),
            "collectorError": collector,
            "loggingPath": LOG_LOCATION.get(),
            "limits": {"fileBytes": FILE_LIMIT, "totalBytes": TOTAL_LIMIT, "entries": MAX_ENTRIES},
            "files": bundle.entries,
        });
        let written = bundle.text("manifest.json", &serde_json::to_vec_pretty(&manifest)?)?;
        anyhow::ensure!(written <= MANIFEST_RESERVE, "diagnostic manifest exceeds its limit");
        bundle.zip.finish()?.sync_all()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::iso::NOTICES;
    use crate::services::test_support::TempDir;

    #[test]
    fn panic_details_survive_process_exit() {
        if std::env::var_os("ATLAS_DIAGNOSTIC_PANIC_CHILD").is_some() {
            init_logging();
            panic!("diagnostic panic fixture");
        }
        let temp = TempDir::new("diagnostic-panic");
        let status = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "services::diagnostics::tests::panic_details_survive_process_exit"])
            .env("ATLAS_DIAGNOSTIC_PANIC_CHILD", "1")
            .env("ATLAS_APP_DATA", temp.path())
            .env("RUST_LOG", "off")
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status()
            .unwrap();
        assert!(!status.success());
        let file = fs::read_dir(temp.path().join("Logs")).unwrap().next().unwrap().unwrap();
        let text = fs::read_to_string(file.path()).unwrap();
        assert!(text.contains("PANIC") && text.contains("diagnostic panic fixture"));
        assert!(text.contains("stack backtrace") || text.contains("0:"));
    }

    #[test]
    fn locked_file_does_not_prevent_collecting_other_logs() {
        let temp = TempDir::new("diagnostic-locked");
        let locked = temp.path().join("locked.log");
        let _handle = OpenOptions::new().create_new(true).write(true).share_mode(0).open(&locked).unwrap();
        let readable = temp.path().join("readable.log");
        fs::write(&readable, "useful evidence").unwrap();
        let mut bundle = Bundle::new(File::create(temp.path().join("out.zip")).unwrap());
        bundle.collect(&locked, "locked.log", 0).unwrap();
        bundle.collect(&readable, "readable.log", 0).unwrap();
        assert!(bundle.entries[0]["status"].as_str().unwrap().contains("unreadable"));
        assert_eq!(bundle.entries[1]["status"], "included");
    }

    #[test]
    fn rotating_log_keeps_recent_history_and_flushes() {
        let temp = TempDir::new("diagnostic-rotation");
        let path = temp.path().join("app-test.log");
        let mut log = RollingLog::new(path.clone(), 4).unwrap();
        log.write_all(b"11112222333344445555").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"5555");
        assert_eq!(fs::read(log.rotated(3)).unwrap(), b"2222");
    }

    #[test]
    fn archive_redacts_copies_and_metadata_and_hashes_the_exported_bytes() {
        let temp = TempDir::new("diagnostic-redacted-archive");
        let source = temp.path().join("install.log");
        let original = "ERROR 0x80070005 C:\\Users\\Test Person\\AppData\\Local\\AtlasOS\\install.log\npassword='test credential'\ntransaction=job-42\n";
        fs::write(&source, original).unwrap();
        let target = temp.path().join("test.zip");
        let mut bundle = Bundle::new(File::create(&target).unwrap());
        bundle.collect(&source, "logs/install.log", 0).unwrap();
        bundle.note("missing.log", "unreadable C:\\Users\\Test Person\\missing.log");
        bundle.text("manifest.json", &serde_json::to_vec(&json!({"files":bundle.entries})).unwrap()).unwrap();
        bundle.zip.finish().unwrap();
        assert_eq!(fs::read_to_string(source).unwrap(), original, "local evidence must stay unchanged");
        let mut zip = zip::ZipArchive::new(File::open(target).unwrap()).unwrap();
        let mut log = String::new();
        zip.by_name("logs/install.log").unwrap().read_to_string(&mut log).unwrap();
        let mut manifest = String::new();
        zip.by_name("manifest.json").unwrap().read_to_string(&mut manifest).unwrap();
        for text in [&log, &manifest] {
            assert!(!text.contains("Test Person") && !text.contains("test credential"));
        }
        assert!(log.contains("0x80070005") && log.contains("transaction=job-42"));
        let manifest: Value = serde_json::from_str(&manifest).unwrap();
        assert_eq!(manifest["files"][0]["sha256"], super::super::releases::sha256_bytes(log.as_bytes()));
    }

    #[test]
    fn staged_package_files_cannot_exhaust_the_evidence_budget() {
        let temp = TempDir::new("diagnostic-staging-budget");
        let state = temp.path().join("state");
        let executables = state.join("Staging/one/Executables");
        let assets = executables.join("AtlasDesktop/assets");
        let modules = executables.join("AtlasModules");
        fs::create_dir_all(&assets).unwrap();
        fs::create_dir_all(modules.join("Logs")).unwrap();
        fs::create_dir_all(modules.join("Scripts")).unwrap();
        fs::create_dir_all(state.join("Install")).unwrap();
        for index in 0..30 {
            fs::write(assets.join(format!("asset-{index}.json")), "{}").unwrap();
        }
        fs::write(modules.join("Scripts/catalog.json"), "package metadata").unwrap();
        fs::write(modules.join("Logs/install-capture.log"), "actual exception").unwrap();
        fs::write(executables.join("request.json"), "{\"options\":[]}").unwrap();
        fs::write(state.join("Install/active.json"), "install state").unwrap();
        let target = temp.path().join("test.zip");
        let mut bundle = Bundle::new(File::create(&target).unwrap());
        bundle.collect(&state, "playbook/state", 0).unwrap();
        assert!(bundle.files < 20);
        bundle.zip.finish().unwrap();
        let mut zip = zip::ZipArchive::new(File::open(target).unwrap()).unwrap();
        for name in [
            "Install/active.json",
            "Staging/one/Executables/request.json",
            "Staging/one/Executables/AtlasModules/Logs/install-capture.log",
        ] {
            assert!(zip.by_name(&format!("playbook/state/{name}")).is_ok());
        }
        assert!(
            zip.by_name("playbook/state/Staging/one/Executables/AtlasModules/Scripts/catalog.json").is_err()
        );
    }

    #[test]
    fn bundle_keeps_full_logs_and_records_missing_and_oversized_files() {
        let temp = TempDir::new("diagnostic-export");
        let source = temp.path().join("source");
        fs::create_dir(&source).unwrap();
        let text = "original failure\n".repeat(100);
        fs::write(source.join("install.log"), &text).unwrap();
        fs::write(source.join("private.exe"), "excluded").unwrap();
        File::create(source.join("large.log")).unwrap().set_len(FILE_LIMIT + 1).unwrap();
        let target = temp.path().join("test.zip");
        let mut bundle = Bundle::new(File::create(&target).unwrap());
        bundle.collect(&source, "logs", 0).unwrap();
        bundle.collect(&source.join("absent.log"), "absent.log", 0).unwrap();
        assert!(bundle.entries.iter().any(|entry| entry["status"].as_str().unwrap().contains("size limit")));
        assert!(bundle.entries.iter().any(|entry| entry["status"].as_str().unwrap().contains("unavailable")));
        bundle.zip.finish().unwrap();
        let mut zip = zip::ZipArchive::new(File::open(&target).unwrap()).unwrap();
        let mut restored = String::new();
        zip.by_name("logs/install.log").unwrap().read_to_string(&mut restored).unwrap();
        assert_eq!(restored, text);
        assert!(zip.by_name("logs/private.exe").is_err());
    }

    #[test]
    fn the_budget_counts_the_archive_texts_and_keeps_room_for_the_manifest() {
        let temp = TempDir::new("diagnostic-budget");
        let log = temp.path().join("late.log");
        fs::write(&log, "x".repeat(100)).unwrap();
        let mut bundle = Bundle::new(File::create(temp.path().join("test.zip")).unwrap());
        assert_eq!(bundle.text("READ-ME.txt", README_TEXT.as_bytes()).unwrap(), README_TEXT.len() as u64);
        assert_eq!(bundle.bytes, README_TEXT.len() as u64);
        bundle.bytes = TOTAL_LIMIT - MANIFEST_RESERVE - 10;
        bundle.collect(&log, "late.log", 0).unwrap();
        assert!(bundle.entries[0]["status"].as_str().unwrap().contains("size limit"));
    }

    #[test]
    fn a_collector_that_stopped_early_leaves_its_finished_sections_and_names_the_last() {
        let temp = TempDir::new("diagnostic-partial");
        let working = temp.path().join("collect");
        fs::create_dir(&working).unwrap();
        fs::write(working.join("machine-report.partial.txt"), "1. Machine\nfinished section").unwrap();
        let target = temp.path().join("test.zip");
        let mut bundle = Bundle::new(File::create(&target).unwrap());
        bundle.collect(&working, "report", 0).unwrap();
        bundle.zip.finish().unwrap();
        let mut zip = zip::ZipArchive::new(File::open(&target).unwrap()).unwrap();
        assert!(zip.by_name("report/machine-report.partial.txt").is_ok());

        let log =
            "Collecting: 1. Machine\r\nCollecting: 10. Event log errors and warnings since the install\r\n";
        assert_eq!(stuck_section(log), Some("10. Event log errors and warnings since the install"));
        assert_eq!(stuck_section(""), None);
    }

    #[test]
    fn the_collector_gets_its_paths_whatever_the_profile_name_and_a_timeout_names_the_section() {
        let temp = TempDir::new("diagnostic-collector");
        // Every single quote PowerShell recognises, as a profile name may hold.
        let working = temp.path().join("O\u{2019}Brien's \u{2018}x\u{201A}\u{201B}");
        fs::create_dir(&working).unwrap();
        let stub = |sleep: u32| {
            format!(
                "param([string]$OutputPath, [string]$PartialPath)\r\n\
                 [IO.File]::WriteAllText($PartialPath, 'finished')\r\n\
                 Write-Host 'Collecting: 2. Slow'\r\n\
                 Start-Sleep -Seconds {sleep}\r\n\
                 [IO.File]::WriteAllText($OutputPath, 'complete')\r\n"
            )
        };
        run_collector(&working, stub(0).as_bytes(), Duration::from_secs(60)).unwrap();
        assert_eq!(fs::read_to_string(working.join("machine-report.txt")).unwrap(), "complete");

        fs::remove_file(working.join("machine-report.partial.txt")).unwrap();
        // The short deadline starts once the section is under way, so a slow
        // PowerShell start cannot use it up.
        let log = working.join("collector.log");
        let child = spawn_collector(&working, stub(30).as_bytes()).unwrap();
        let started = Instant::now();
        while !fs::read_to_string(&log).unwrap_or_default().contains("Collecting:") {
            assert!(started.elapsed() < Duration::from_secs(60), "the collector did not start");
            std::thread::sleep(Duration::from_millis(50));
        }
        let error = wait_collector(child, &log, Duration::from_secs(1)).unwrap_err();
        assert!(format!("{error:#}").contains("in section '2. Slow'"), "{error:#}");
        assert_eq!(fs::read_to_string(working.join("machine-report.partial.txt")).unwrap(), "finished");
    }

    /// A job's copy of the notices is left out, in current media jobs (which
    /// keep it when a build is killed) and in release-candidate ISO jobs.
    #[test]
    fn iso_jobs_are_exported_without_their_licence_notices() {
        let temp = TempDir::new("diagnostic-iso-notices");
        let target = temp.path().join("test.zip");
        let mut bundle = Bundle::new(File::create(&target).unwrap());
        for (root, name) in [("Media", "media"), ("ISO", "app/ISO")] {
            let job = temp.path().join(root).join("123-456");
            fs::create_dir_all(&job).unwrap();
            fs::write(job.join(NOTICES), "notices").unwrap();
            fs::write(job.join("build.log"), "worker failure").unwrap();
            let visited = bundle.files;
            bundle.collect(&temp.path().join(root), name, 0).unwrap();
            assert_eq!(bundle.files - visited, 3, "{name}: the notices cost no visit");
        }
        // Only a job's own copy is left out.
        let notices = temp.path().join("Media/123-456").join(NOTICES);
        bundle.collect(&notices, "notes/THIRD-PARTY-NOTICES.txt", 0).unwrap();
        bundle.zip.finish().unwrap();
        let mut zip = zip::ZipArchive::new(File::open(&target).unwrap()).unwrap();
        for name in ["media", "app/ISO"] {
            assert!(zip.by_name(&format!("{name}/123-456/build.log")).is_ok());
            assert!(zip.by_name(&format!("{name}/123-456/THIRD-PARTY-NOTICES.txt")).is_err());
        }
        assert!(zip.by_name("notes/THIRD-PARTY-NOTICES.txt").is_ok());
    }
}
