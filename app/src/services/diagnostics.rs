//! Local support evidence. No upload, media copies, registry changes or servicing.
use std::{
    fs::{self, File, OpenOptions},
    io::{self, Read, Write},
    path::{Path, PathBuf},
    sync::{Arc, Mutex, OnceLock},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result};
use serde_json::{Value, json};
use std::os::windows::fs::OpenOptionsExt;
use zip::{ZipWriter, write::SimpleFileOptions};

const CHUNK: u64 = 4 * 1024 * 1024;
const FILE_LIMIT: u64 = 32 * 1024 * 1024;
const TOTAL_LIMIT: u64 = 256 * 1024 * 1024;
static LOG_LOCATION: OnceLock<PathBuf> = OnceLock::new();

fn unique_id() -> String {
    format!(
        "{}-{}",
        SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_nanos(),
        std::process::id()
    )
}

struct RollingLog {
    path: PathBuf,
    file: Option<File>,
    bytes: u64,
    limit: u64,
}

impl RollingLog {
    fn new(path: PathBuf, limit: u64) -> io::Result<Self> {
        let file = OpenOptions::new().create_new(true).write(true).share_mode(1).open(&path)?;
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
            let _ = fs::remove_file(self.rotated(3));
            for index in (1..3).rev() {
                let source = self.rotated(index);
                if source.exists() {
                    fs::rename(source, self.rotated(index + 1))?;
                }
            }
            fs::rename(&self.path, self.rotated(1))?;
            self.file = Some(OpenOptions::new().create_new(true).write(true).share_mode(1).open(&self.path)?);
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
        // Never remove installation logs. Open files from other app processes are
        // retained by Windows even if they fall outside the retained history.
        let mut old: Vec<_> = fs::read_dir(&root)?
            .flatten()
            .filter(|entry| {
                let name = entry.file_name().to_string_lossy().into_owned();
                name.starts_with("app-") && name.ends_with(".log")
            })
            .collect();
        old.sort_by_key(|entry| std::cmp::Reverse(entry.file_name()));
        for entry in old.into_iter().skip(36) {
            let _ = fs::remove_file(entry.path());
        }
        RollingLog::new(root.join(format!("app-{}.log", unique_id())), CHUNK)
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
        let _ = LOG_LOCATION.set(writer.path.clone());
        let shared = SharedLog(Arc::new(Mutex::new(writer)));
        builder.target(env_logger::Target::Pipe(Box::new(shared.clone())));
        std::panic::set_hook(Box::new(move |panic| {
            // Direct write ignores log-level overrides; try_lock avoids deadlock
            // if a panic originated in the logger. Flush before release aborts.
            if let Ok(mut log) = shared.0.try_lock() {
                let _ = writeln!(
                    log,
                    "{} PANIC {panic}\n{}",
                    chrono::Utc::now(),
                    std::backtrace::Backtrace::force_capture()
                );
                let _ = log.flush();
            }
        }));
    }
    builder.init();
    log::info!(
        "Atlas Manager {} started; pid={}; Windows={:?}; elevated={}",
        env!("CARGO_PKG_VERSION"),
        std::process::id(),
        super::system::SystemInfo::read(),
        super::system::is_elevated()
    );
}

pub const PRIVACY: &str = "Atlas diagnostics\n\nPrepared for sharing in public community or development channels when reporting a bug. Known credential formats and personal account details are automatically redacted; consistent anonymous labels keep related evidence connected.\n\nError details, timestamps, versions, hardware models, application names and operation IDs are kept to help investigate. Nothing is uploaded automatically. See BUG-REPORT.txt for what to include with your report and manifest.json for collection details.\n";

struct Bundle {
    zip: ZipWriter<File>,
    entries: Vec<Value>,
    bytes: u64,
    files: usize,
    redactor: super::diagnostics_redaction::Redactor,
}

fn reparse(metadata: &fs::Metadata) -> bool {
    use std::os::windows::fs::MetadataExt;
    metadata.file_attributes() & 0x400 != 0
}

impl Bundle {
    fn note(&mut self, name: &str, status: impl ToString) {
        self.entries.push(
            json!({"path": self.redactor.text(name), "status": self.redactor.text(&status.to_string())}),
        );
    }

    fn text(&mut self, name: &str, bytes: &[u8]) -> Result<()> {
        let name = self.redactor.text(name);
        let bytes = self.redactor.file(bytes).context("diagnostic text encoding is unsupported")?;
        self.zip.start_file(
            &name,
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
        )?;
        self.zip.write_all(&bytes)?;
        Ok(())
    }

    fn collect(&mut self, path: &Path, name: &str, depth: usize) -> Result<()> {
        if self.files >= 2048 || depth > 12 {
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
        if reparse(&metadata) {
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
                    for entry in entries {
                        if self.files >= 2048 {
                            self.note(name, "remaining entries omitted: file limit");
                            break;
                        }
                        self.collect(
                            &entry.path(),
                            &format!("{name}/{}", entry.file_name().to_string_lossy()),
                            depth + 1,
                        )?;
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
        if metadata.len() > FILE_LIMIT || self.bytes + metadata.len() > TOTAL_LIMIT {
            self.note(name, format!("omitted: size limit ({} bytes)", metadata.len()));
            return Ok(());
        }
        let mut bytes = Vec::new();
        match File::open(path).and_then(|file| file.take(FILE_LIMIT + 1).read_to_end(&mut bytes)) {
            Ok(_) if bytes.len() as u64 <= FILE_LIMIT && self.bytes + bytes.len() as u64 <= TOTAL_LIMIT => {}
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
        if bytes.len() as u64 > FILE_LIMIT || self.bytes + bytes.len() as u64 > TOTAL_LIMIT {
            self.note(name, "omitted: redacted text exceeds size limit");
            return Ok(());
        }
        let name = self.redactor.text(name);
        // Write the already-redacted bytes once; their digest must describe
        // exactly the contents reviewers receive.
        self.zip.start_file(
            &name,
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
        )?;
        self.zip.write_all(&bytes)?;
        self.bytes += bytes.len() as u64;
        let hash = ring::digest::digest(&ring::digest::SHA256, &bytes);
        let hash: String = hash.as_ref().iter().map(|byte| format!("{byte:02x}")).collect();
        self.entries.push(json!({"path":name,"status":"included","bytes":bytes.len(),"sha256":hash}));
        Ok(())
    }
}

fn collect_report(directory: &Path) -> Result<()> {
    use std::{
        os::windows::process::CommandExt,
        process::{Command, Stdio},
    };
    let output = File::create(directory.join("collector.log"))?;
    // Feed the embedded collector directly: never execute a script from an
    // app-data directory that a different process could replace before launch.
    let destination = directory.join("machine-report.txt").to_string_lossy().replace('\'', "''");
    let command = format!(
        "$source = [Console]::In.ReadToEnd(); & ([scriptblock]::Create($source)) -OutputPath '{destination}'"
    );
    let mut child = Command::new(super::system::powershell_path())
        .args(["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"])
        .arg(command)
        .stdin(Stdio::piped())
        .stdout(output.try_clone()?)
        .stderr(output)
        .creation_flags(0x0800_0000)
        .spawn()?;
    if let Err(error) = child
        .stdin
        .take()
        .context("collector input")?
        .write_all(include_bytes!("../../../tools/dev/Get-AtlasInstallReport.ps1"))
    {
        let _ = child.kill();
        let _ = child.wait();
        return Err(error.into());
    }
    let start = Instant::now();
    loop {
        if let Some(status) = child.try_wait()? {
            anyhow::ensure!(status.success(), "machine collector exited {status}");
            return Ok(());
        }
        if start.elapsed() > Duration::from_secs(60) {
            child.kill()?;
            child.wait()?;
            anyhow::bail!("machine collector timed out after 60 seconds; other logs remain available");
        }
        std::thread::sleep(Duration::from_millis(100));
    }
}

/// Works before Atlas installation and without elevation. Missing protected files
/// are reported instead of aborting the rest of the export.
pub fn export(root: &Path, package: Option<Value>) -> Result<PathBuf> {
    let saved = super::settings::load_from(&root.join("settings.json"));
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
    let result = (|| -> Result<PathBuf> {
        let collector = collect_report(&working).err().map(|error| format!("{error:#}"));
        let temporary = exports.join(format!("Atlas-diagnostics-{id}.partial"));
        let destination = temporary.with_extension("zip");
        let output = OpenOptions::new().create_new(true).write(true).open(&temporary)?;
        let mut bundle = Bundle {
            zip: ZipWriter::new(output),
            entries: Vec::new(),
            bytes: 0,
            files: 0,
            redactor: super::diagnostics_redaction::Redactor::new(),
        };
        let packed = (|| -> Result<()> {
            bundle.text("READ-ME.txt", PRIVACY.as_bytes())?;
            if let Some(path) = &package_directory {
                bundle.collect(&path.join("Executables/AtlasModules/Logs"), "playbook/staged-logs", 0)?;
            }
            bundle.text("BUG-REPORT.txt", b"What were you doing?\nWhat did you expect?\nWhat happened (include exact message)?\nApproximate time and timezone:\nDoes it happen again?\nAttach this ZIP when reporting the issue in a public community or development channel.\n")?;
            for name in
                ["Logs", "ISO", "Preparation", "settings.json", "settings.json.invalid", "session.json"]
            {
                bundle.collect(&root.join(name), &format!("app/{name}"), 0)?;
            }
            if let Some(path) = LOG_LOCATION.get() {
                bundle.collect(path, "app/current-process.log", 0)?;
            }
            match super::recovery_app::preparation_root(&root.join("settings.json")) {
                Ok(path) => bundle.collect(&path, "preparation", 0)?,
                Err(error) => bundle.note("preparation", error),
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
                bundle.collect(
                    &windows.join("AtlasISO/network-drivers.json"),
                    "iso/network-drivers.json",
                    0,
                )?;
            }
            bundle.collect(&working, "report", 0)?;
            let executable = std::env::current_exe().ok();
            let hash = executable.as_ref().and_then(|path| super::releases::sha256_file(path).ok());
            let info = super::system::SystemInfo::read();
            let manifest = json!({"schema":2,"redaction":"public-v1","createdAt":chrono::Utc::now().to_rfc3339(),"appVersion":env!("CARGO_PKG_VERSION"),"executable":executable,"appSha256":hash,"package":package,"windows":{"build":info.build_label(),"edition":info.edition_id,"release":info.display_version},"elevated":super::system::is_elevated(),"collectorError":collector,"loggingPath":LOG_LOCATION.get(),"limits":{"fileBytes":FILE_LIMIT,"totalBytes":TOTAL_LIMIT,"entries":2048},"files":bundle.entries});
            bundle.text("manifest.json", &serde_json::to_vec_pretty(&manifest)?)?;
            Ok(())
        })();
        match packed.and_then(|()| Ok(bundle.zip.finish()?)) {
            Ok(file) => {
                file.sync_all()?;
                drop(file);
                fs::rename(&temporary, &destination)?;
                Ok(destination)
            }
            Err(error) => {
                let _ = fs::remove_file(&temporary);
                Err(error)
            }
        }
    })();
    let _ = fs::remove_dir_all(&working);
    result.context("export Atlas diagnostics")
}

#[cfg(test)]
mod tests {
    use super::*;
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
        let mut bundle = Bundle {
            zip: ZipWriter::new(File::create(temp.path().join("out.zip")).unwrap()),
            entries: vec![],
            bytes: 0,
            files: 0,
            redactor: super::super::diagnostics_redaction::Redactor::new(),
        };
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
        let mut bundle = Bundle {
            zip: ZipWriter::new(File::create(&target).unwrap()),
            entries: Vec::new(),
            bytes: 0,
            files: 0,
            redactor: super::super::diagnostics_redaction::Redactor::new(),
        };
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
        let digest = ring::digest::digest(&ring::digest::SHA256, log.as_bytes());
        let digest: String = digest.as_ref().iter().map(|byte| format!("{byte:02x}")).collect();
        assert_eq!(manifest["files"][0]["sha256"], digest);
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
        let mut bundle = Bundle {
            zip: ZipWriter::new(File::create(&target).unwrap()),
            entries: Vec::new(),
            bytes: 0,
            files: 0,
            redactor: super::super::diagnostics_redaction::Redactor::new(),
        };
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
}
