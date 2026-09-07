//! App preferences, stored beside the downloaded playbooks under
//! `%LOCALAPPDATA%\AtlasOS\App`.

use std::path::{Path, PathBuf};
use std::sync::mpsc;

use anyhow::{Context, Result};
use futures::channel::oneshot;
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ThemePreference {
    #[default]
    System,
    Light,
    Dark,
}

/// Which language the app speaks: the Windows display language (the
/// default) or one the user chose. Stored as `"system"` or a BCP 47 tag, so
/// a settings file written before the setting existed reads as System, and
/// a tag this build does not ship is kept rather than rewritten.
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(from = "String", into = "String")]
pub enum LanguagePreference {
    #[default]
    System,
    Explicit(String),
}

impl From<String> for LanguagePreference {
    fn from(value: String) -> Self {
        let trimmed = value.trim();
        if trimmed.is_empty() || trimmed.eq_ignore_ascii_case("system") {
            LanguagePreference::System
        } else {
            LanguagePreference::Explicit(trimmed.to_owned())
        }
    }
}

impl From<LanguagePreference> for String {
    fn from(value: LanguagePreference) -> Self {
        match value {
            LanguagePreference::System => "system".to_owned(),
            LanguagePreference::Explicit(tag) => tag,
        }
    }
}

/// An install flow in progress. Saved before the app relaunches elevated so
/// the new process can pick up exactly where the user was.
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct InstallDraft {
    /// Restart requirement recorded before registering preparation recovery.
    pub preparation_restart_at: Option<String>,
    /// Step name as `Step::parse` understands it.
    pub step: String,
    pub options: Vec<String>,
    /// An already unpacked playbook, if one was ready.
    pub playbook_dir: Option<PathBuf>,
    /// Which options screen was showing (see `AppModel::option_screens`).
    pub option_screen: usize,
    /// The id of the install this flow started, once it has. A completed
    /// install clears the draft that launched it and no other.
    pub session: Option<String>,
    /// Which flow owns this draft: a random id the window that began the
    /// flow chose. A window saves or abandons the draft only while it is the
    /// owner; a draft without one was written before flows had identities.
    pub flow: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct AppSettings {
    pub drivers: Option<super::preparation::Drivers>,
    pub theme: ThemePreference,
    pub language: LanguagePreference,
    /// Restart automatically when the install completes.
    pub restart_after_install: bool,
    pub draft: Option<InstallDraft>,
    /// Language tags whose "preview translation" notice the user dismissed.
    pub dismissed_preview_notices: Vec<String>,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            drivers: None,
            theme: ThemePreference::System,
            language: LanguagePreference::System,
            restart_after_install: true,
            draft: None,
            dismissed_preview_notices: Vec::new(),
        }
    }
}

/// Why the stored settings were not used. The raw error is kept as a
/// diagnostic; the UI puts a translated explanation around it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SettingsProblem {
    /// The file exists but could not be read.
    Unreadable { error: String },
    /// The file did not parse and was renamed aside.
    DamagedKept { error: String, kept_as: String },
    /// The file did not parse and could not be renamed aside.
    Damaged { error: String },
}

/// What `load` found: the settings to use and, if the stored file could not
/// be read, why.
#[derive(Clone, Debug, Default)]
pub struct Loaded {
    pub settings: AppSettings,
    pub problem: Option<SettingsProblem>,
}

/// `%LOCALAPPDATA%\AtlasOS\App`. `ATLAS_APP_DATA` overrides it for design
/// review and testing, so a review run never touches the real app data.
pub fn app_data_dir() -> PathBuf {
    if let Some(path) = std::env::var_os("ATLAS_APP_DATA") {
        return PathBuf::from(path);
    }
    std::env::var_os("LOCALAPPDATA")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir)
        .join("AtlasOS")
        .join("App")
}

/// Where this app keeps its own files: settings, downloads, unpacked
/// playbooks and the install session. One value names them all, so the model
/// (and its tests) can point everything at one directory.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AppPaths {
    pub root: PathBuf,
}

impl AppPaths {
    /// The process's app data directory (see [`app_data_dir`]).
    pub fn from_process() -> Self {
        Self::under(app_data_dir())
    }

    pub fn under(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn settings(&self) -> PathBuf {
        self.root.join("settings.json")
    }

    /// Extracted playbooks, one directory per package.
    pub fn playbooks(&self) -> PathBuf {
        self.root.join("Playbooks")
    }

    /// Downloaded packages with their verification records.
    pub fn downloads(&self) -> PathBuf {
        self.root.join("Downloads")
    }

    pub fn session(&self) -> super::session::SessionPaths {
        super::session::SessionPaths::under(&self.root)
    }
}

/// Missing settings are the defaults. An unreadable file is set aside as
/// `settings.json.invalid` rather than silently replaced, and reported.
pub fn load_from(path: &Path) -> Loaded {
    let text = match std::fs::read_to_string(path) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Loaded::default(),
        Err(error) => {
            return Loaded {
                settings: AppSettings::default(),
                problem: Some(SettingsProblem::Unreadable { error: error.to_string() }),
            };
        }
    };
    match serde_json::from_str(text.trim_start_matches('\u{feff}')) {
        Ok(settings) => Loaded { settings, problem: None },
        Err(error) => {
            let aside = invalid_path(path);
            let kept = std::fs::rename(path, &aside).is_ok();
            let problem = if kept {
                SettingsProblem::DamagedKept {
                    error: error.to_string(),
                    kept_as: aside.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default(),
                }
            } else {
                SettingsProblem::Damaged { error: error.to_string() }
            };
            Loaded { settings: AppSettings::default(), problem: Some(problem) }
        }
    }
}

fn invalid_path(path: &Path) -> PathBuf {
    let mut name = path.file_name().map(|n| n.to_os_string()).unwrap_or_default();
    name.push(".invalid");
    path.with_file_name(name)
}

/// Reads the current document, lets `change` edit it (and answer something
/// about it), and writes it back, all under a lock other instances of the
/// app take for the same file. Every decision about the document (set this
/// field, clear this draft and no other) is made against what is on disk at
/// that moment, never a cached copy. A missing file starts from the
/// defaults; a damaged one is set aside as `load_from` does; a file that
/// exists but cannot be read fails the transaction and is left untouched.
pub fn modify<R>(path: &Path, change: impl FnOnce(&mut AppSettings) -> R) -> Result<R> {
    let _lock = SettingsLock::acquire(path)?;
    let loaded = load_from(path);
    if let Some(SettingsProblem::Unreadable { error }) = &loaded.problem {
        anyhow::bail!("{} cannot be read at the moment ({error}); nothing was changed", path.display());
    }
    let mut settings = loaded.settings;
    let answer = change(&mut settings);
    save_to(path, &settings)?;
    Ok(answer)
}

/// A short-lived, cross-process lock on the settings file (a lock file
/// opened with no sharing, as the launch lock is). Only contention is
/// waited out; any other failure to open the lock file is an error at once.
struct SettingsLock {
    _file: std::fs::File,
}

impl SettingsLock {
    fn acquire(path: &Path) -> Result<Self> {
        const WAIT: std::time::Duration = std::time::Duration::from_secs(2);
        const RETRY: std::time::Duration = std::time::Duration::from_millis(20);
        const ERROR_SHARING_VIOLATION: i32 = 32;
        let lock_path = path.with_extension("json.lock");
        if let Some(parent) = lock_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let deadline = std::time::Instant::now() + WAIT;
        loop {
            let mut options = std::fs::OpenOptions::new();
            options.read(true).write(true).create(true).truncate(false);
            #[cfg(windows)]
            {
                use std::os::windows::fs::OpenOptionsExt;
                options.share_mode(0);
            }
            match options.open(&lock_path) {
                Ok(file) => return Ok(Self { _file: file }),
                Err(error)
                    if error.raw_os_error() == Some(ERROR_SHARING_VIOLATION)
                        && std::time::Instant::now() < deadline =>
                {
                    std::thread::sleep(RETRY);
                }
                Err(error) => {
                    return Err(error).with_context(|| format!("lock {}", lock_path.display()));
                }
            }
        }
    }
}

/// A fresh flow identity: time, process and a nanosecond stamp.
pub fn new_flow_id() -> String {
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or_default();
    format!("{}-{nanos:x}", std::process::id())
}

/// The one way the app writes its settings: transactions run in order on a
/// thread of their own, each a locked read-modify-write of the current
/// document (see [`modify`]), so the window's thread never waits for the
/// lock and no writer ever replaces the document with a stale copy. The
/// caller receives the transaction's answer when it has been written.
#[derive(Clone)]
pub struct Store {
    jobs: mpsc::Sender<Job>,
}

type Job = Box<dyn FnOnce(&Path) + Send>;

impl Store {
    pub fn new(path: PathBuf) -> Self {
        let (jobs, queue) = mpsc::channel::<Job>();
        std::thread::Builder::new()
            .name("atlas-settings".into())
            .spawn(move || {
                for job in queue {
                    job(&path);
                }
            })
            .expect("start the settings thread");
        Self { jobs }
    }

    /// Queues `change`; the receiver resolves with its answer once the
    /// document has been written, or with the reason it was not.
    pub fn transact<R: Send + 'static>(
        &self,
        change: impl FnOnce(&mut AppSettings) -> R + Send + 'static,
    ) -> oneshot::Receiver<Result<R, String>> {
        let (done, answer) = oneshot::channel();
        let job: Job = Box::new(move |path| {
            let result = modify(path, change).map_err(|error| format!("{error:#}"));
            let _ = done.send(result);
        });
        if self.jobs.send(job).is_err() {
            log::error!("the settings thread is gone");
        }
        answer
    }
}

/// Writes the whole document to a temporary file and renames it into place,
/// so an interruption never leaves a half-written settings file.
pub fn save_to(path: &Path, settings: &AppSettings) -> Result<()> {
    let parent = path.parent().context("the settings path has no parent")?;
    std::fs::create_dir_all(parent).with_context(|| format!("create {}", parent.display()))?;
    let json = serde_json::to_string_pretty(settings)?;
    let mut temp_name = path.file_name().map(|n| n.to_os_string()).unwrap_or_default();
    temp_name.push(format!(".{}.tmp", std::process::id()));
    let temp = path.with_file_name(temp_name);
    let result = (|| -> Result<()> {
        std::fs::write(&temp, json).with_context(|| format!("write {}", temp.display()))?;
        std::fs::rename(&temp, path).with_context(|| format!("replace {}", path.display()))
    })();
    if result.is_err() {
        let _ = std::fs::remove_file(&temp);
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::TempDir;

    #[test]
    fn settings_round_trip_atomically() {
        let temp = TempDir::new("settings-roundtrip");
        let path = temp.path().join("nested").join("settings.json");
        let settings = AppSettings {
            dismissed_preview_notices: vec![],
            drivers: Some(super::super::preparation::Drivers::Manual),
            theme: ThemePreference::Dark,
            language: LanguagePreference::Explicit("de".into()),
            restart_after_install: false,
            draft: Some(InstallDraft {
                step: "options".into(),
                options: vec!["defender-enable".into()],
                playbook_dir: Some(PathBuf::from(r"C:\Playbooks\0.6.0")),
                option_screen: 2,
                session: Some("20260905-120000-1234-abc".into()),
                flow: Some("flow-1".into()),
                preparation_restart_at: None,
            }),
        };
        save_to(&path, &settings).unwrap();
        let loaded = load_from(&path);
        assert_eq!(loaded.settings, settings);
        assert!(loaded.problem.is_none());
        let names: Vec<String> = std::fs::read_dir(path.parent().unwrap())
            .unwrap()
            .flatten()
            .map(|e| e.file_name().to_string_lossy().into_owned())
            .collect();
        assert_eq!(names, vec!["settings.json"], "no temporary file may remain");
    }

    #[test]
    fn missing_settings_are_defaults_without_a_problem() {
        let temp = TempDir::new("settings-missing");
        let loaded = load_from(&temp.path().join("settings.json"));
        assert_eq!(loaded.settings, AppSettings::default());
        assert!(loaded.problem.is_none());
    }

    #[test]
    fn a_damaged_file_is_kept_aside_and_reported() {
        let temp = TempDir::new("settings-damaged");
        let path = temp.path().join("settings.json");
        std::fs::write(&path, "{ \"theme\": \"dark\", ").unwrap();
        let loaded = load_from(&path);
        assert_eq!(loaded.settings, AppSettings::default());
        assert!(matches!(
            &loaded.problem,
            Some(SettingsProblem::DamagedKept { kept_as, .. }) if kept_as == "settings.json.invalid"
        ));
        assert!(!path.exists());
        assert!(temp.path().join("settings.json.invalid").is_file());
        // The next load is clean again.
        assert!(load_from(&path).problem.is_none());
    }

    #[test]
    fn older_settings_files_read_as_match_windows_and_unknown_tags_are_kept() {
        let temp = TempDir::new("settings-language");
        let path = temp.path().join("settings.json");
        std::fs::write(&path, "{ \"theme\": \"dark\", \"restartAfterInstall\": true }").unwrap();
        let loaded = load_from(&path);
        assert_eq!(loaded.settings.language, LanguagePreference::System);
        std::fs::write(&path, "{ \"language\": \"tlh\" }").unwrap();
        assert_eq!(load_from(&path).settings.language, LanguagePreference::Explicit("tlh".into()));
        std::fs::write(&path, "{ \"language\": \"System\" }").unwrap();
        assert_eq!(load_from(&path).settings.language, LanguagePreference::System);
        // Written back as a plain string.
        save_to(
            &path,
            &AppSettings { language: LanguagePreference::Explicit("pl".into()), ..Default::default() },
        )
        .unwrap();
        assert!(std::fs::read_to_string(&path).unwrap().contains("\"language\": \"pl\""));
    }

    #[test]
    fn modify_edits_what_is_on_disk_not_a_stale_copy() {
        let temp = TempDir::new("settings-modify");
        let path = temp.path().join("settings.json");
        let newer = InstallDraft { step: "options".into(), ..InstallDraft::default() };
        save_to(
            &path,
            &AppSettings { draft: Some(newer.clone()), theme: ThemePreference::Dark, ..Default::default() },
        )
        .unwrap();
        // A caller holding an older idea of the file clears the draft only if
        // the one on disk is the one it means.
        let cleared = modify(&path, |settings| {
            if settings.draft.as_ref().is_some_and(|draft| draft.step == "install") {
                settings.draft = None;
                true
            } else {
                false
            }
        })
        .unwrap();
        assert!(!cleared, "the newer draft on disk is not this caller's to clear");
        let on_disk = load_from(&path).settings;
        assert_eq!(on_disk.draft, Some(newer.clone()));
        assert_eq!(on_disk.theme, ThemePreference::Dark, "other settings on disk are kept");
        modify(&path, |settings| settings.draft = None).unwrap();
        assert!(load_from(&path).settings.draft.is_none());
    }

    /// The follow-up verification's two failures: a writer overlapping a
    /// locked transaction, and a stale whole-document preference save. With
    /// every writer a transaction, both changes survive.
    #[test]
    fn concurrent_and_stale_writers_both_keep_the_other_ones_change() {
        let temp = TempDir::new("settings-writers");
        let path = temp.path().join("settings.json");
        save_to(&path, &AppSettings::default()).unwrap();
        let draft =
            InstallDraft { step: "security".into(), flow: Some("b".into()), ..InstallDraft::default() };
        // A slow transaction holds the lock while another store writes.
        let a = Store::new(path.clone());
        let b = Store::new(path.clone());
        let slow = a.transact(|settings| {
            std::thread::sleep(std::time::Duration::from_millis(300));
            settings.theme = ThemePreference::Dark;
        });
        std::thread::sleep(std::time::Duration::from_millis(50));
        let started = std::time::Instant::now();
        let other = {
            let draft = draft.clone();
            b.transact(move |settings| settings.draft = Some(draft))
        };
        futures::executor::block_on(slow).unwrap().unwrap();
        futures::executor::block_on(other).unwrap().unwrap();
        assert!(
            started.elapsed() >= std::time::Duration::from_millis(200),
            "the second writer waited for the lock"
        );
        let on_disk = load_from(&path).settings;
        assert_eq!(on_disk.theme, ThemePreference::Dark);
        assert_eq!(on_disk.draft, Some(draft.clone()));
        // A preference change from a store that never saw the draft.
        futures::executor::block_on(a.transact(|settings| settings.restart_after_install = false))
            .unwrap()
            .unwrap();
        let on_disk = load_from(&path).settings;
        assert!(!on_disk.restart_after_install);
        assert_eq!(on_disk.draft, Some(draft), "a field update never erases another window's draft");
        // Transactions from one store apply in order.
        drop(a.transact(|settings| settings.theme = ThemePreference::Light));
        drop(a.transact(|settings| settings.theme = ThemePreference::Dark));
        let last = a.transact(|settings| settings.theme = ThemePreference::System);
        futures::executor::block_on(last).unwrap().unwrap();
        assert_eq!(load_from(&path).settings.theme, ThemePreference::System);
    }

    #[test]
    #[cfg(windows)]
    fn a_document_that_cannot_be_read_is_not_replaced_with_defaults() {
        use std::os::windows::fs::OpenOptionsExt;
        const FILE_SHARE_WRITE: u32 = 0x2;
        const FILE_SHARE_DELETE: u32 = 0x4;
        let temp = TempDir::new("settings-unreadable");
        let path = temp.path().join("settings.json");
        let draft =
            InstallDraft { step: "options".into(), flow: Some("x".into()), ..InstallDraft::default() };
        save_to(
            &path,
            &AppSettings { draft: Some(draft.clone()), theme: ThemePreference::Dark, ..Default::default() },
        )
        .unwrap();
        let before = std::fs::read(&path).unwrap();
        // Readable by nobody else, yet replaceable: the atomic rename would succeed.
        let holder = std::fs::OpenOptions::new()
            .read(true)
            .share_mode(FILE_SHARE_WRITE | FILE_SHARE_DELETE)
            .open(&path)
            .unwrap();
        assert!(matches!(load_from(&path).problem, Some(SettingsProblem::Unreadable { .. })));
        let error = modify(&path, |settings| settings.draft = None).unwrap_err();
        assert!(error.to_string().contains("nothing was changed"), "{error:#}");
        drop(holder);
        assert_eq!(std::fs::read(&path).unwrap(), before, "the document is untouched");
        assert_eq!(load_from(&path).settings.draft, Some(draft));
    }

    #[test]
    fn a_save_that_cannot_complete_reports_an_error() {
        let temp = TempDir::new("settings-fail");
        // A directory where the file should be makes the rename fail.
        let path = temp.path().join("settings.json");
        std::fs::create_dir_all(&path).unwrap();
        assert!(save_to(&path, &AppSettings::default()).is_err());
    }
}
