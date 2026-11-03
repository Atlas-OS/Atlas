//! Reads the machine state document that an Atlas install leaves behind at
//! `%windir%\AtlasOS\state.json` (owned by the Atlas.State PowerShell module).

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use chrono::{DateTime, Local};
use serde::Deserialize;

use super::{files, registry};

/// How an install was done, from the state document's `mode`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum InstallMode {
    Fresh,
    Upgrade,
    Reapply,
    /// Atlas put back on a Windows that rebuilt itself while Atlas Manager
    /// moved it to a newer release.
    Rebase,
    #[default]
    Unknown,
}

impl InstallMode {
    pub fn parse(mode: Option<&str>) -> InstallMode {
        match mode.map(str::to_ascii_lowercase).as_deref() {
            Some("fresh") => InstallMode::Fresh,
            Some("upgrade") => InstallMode::Upgrade,
            Some("reapply") => InstallMode::Reapply,
            Some("rebase") => InstallMode::Rebase,
            _ => InstallMode::Unknown,
        }
    }
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AtlasState {
    pub schema_version: u32,
    pub installed_version: Option<String>,
    pub installed_at: Option<String>,
    pub mode: Option<String>,
    #[serde(default)]
    pub is_oobe: bool,
    #[serde(default)]
    pub options: Vec<String>,
    #[serde(default)]
    pub history: Vec<HistoryEntry>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HistoryEntry {
    pub version: Option<String>,
    pub mode: Option<String>,
    pub completed_at: Option<String>,
    /// The options of each choice this install tried to apply that the PC
    /// didn't have as asked once it had run, as its completion read them: the
    /// ones it asked for and the ones it recorded instead. `None` when the
    /// completion couldn't read the PC, or came before it said.
    #[serde(default)]
    pub not_applied: Option<Vec<String>>,
}

impl AtlasState {
    /// Whether the document records a finished install: capture writes one
    /// before the install finishes.
    pub fn has_completed_install(&self) -> bool {
        self.installed_version.as_ref().is_some_and(|version| !version.trim().is_empty())
            && self.installed_at_local().is_some()
    }

    pub fn install_mode(&self) -> InstallMode {
        InstallMode::parse(self.mode.as_deref())
    }

    /// When the install finished, in the user's local zone.
    pub fn installed_at_local(&self) -> Option<DateTime<Local>> {
        parse_timestamp(self.installed_at.as_deref()?)
    }
}

impl HistoryEntry {
    pub fn install_mode(&self) -> InstallMode {
        InstallMode::parse(self.mode.as_deref())
    }

    pub fn completed_at_local(&self) -> Option<DateTime<Local>> {
        parse_timestamp(self.completed_at.as_deref()?)
    }
}

/// An RFC 3339 timestamp from the state document, in the user's local zone.
pub fn parse_timestamp(iso: &str) -> Option<DateTime<Local>> {
    Some(DateTime::parse_from_rfc3339(iso).ok()?.with_timezone(&Local))
}

/// The machine state document. Debug builds accept `ATLAS_STATE_FILE` for design
/// review, so the installed and update-available states can be rendered on a
/// PC without Atlas.
pub fn state_path() -> PathBuf {
    if cfg!(debug_assertions)
        && let Some(path) = std::env::var_os("ATLAS_STATE_FILE")
    {
        return PathBuf::from(path);
    }
    super::system::windows_dir().join(r"AtlasOS\state.json")
}

/// `Ok(None)` when Atlas has never been installed here.
pub fn read() -> Result<Option<AtlasState>> {
    read_at(&state_path())
}

fn read_at(path: &Path) -> Result<Option<AtlasState>> {
    let state: Option<AtlasState> = files::read_json(path)?;
    if let Some(state) = &state
        && state.schema_version != 1
    {
        anyhow::bail!(
            "the Atlas state document uses schema {}, which this app does not understand",
            state.schema_version
        );
    }
    Ok(state)
}

/// What is installed, for deciding whether a package may install here. An
/// install in progress is `Resume`, never `Installed`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum InstallIdentity {
    Fresh,
    Installed(String),
    /// An unfinished install of this version, and what it began with.
    Resume(String, Unfinished),
}

/// What an unfinished install began with.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Unfinished {
    /// The options it was started with, once its plan is running or any of
    /// its steps has completed: from then on the install keeps them.
    pub held: Option<Vec<String>>,
    /// It goes through every choice again (`-ChooseAgain`) rather than
    /// keeping them as the PC had them. Held with the options; until then a
    /// capture that starts again takes the request's.
    pub choose_again: bool,
    /// How it installs, which a capture that starts again keeps too, as the
    /// front door reads it from the same record.
    pub mode: InstallMode,
}

/// How active.json records `-ChooseAgain`, as the install state checks it. A
/// record from before it has none, which keeps the choices.
fn choose_again(choices: Option<&serde_json::Value>) -> Option<bool> {
    match choices {
        None => Some(false),
        Some(choices) if choices == "Keep" => Some(false),
        Some(choices) if choices == "ChooseAgain" => Some(true),
        Some(_) => None,
    }
}

impl InstallIdentity {
    pub fn allows(&self, manifest: &super::playbook::Manifest) -> bool {
        match self {
            Self::Fresh => true,
            Self::Resume(target, _) => target == &manifest.version,
            Self::Installed(version) => {
                version == &manifest.version || manifest.upgradable_from.contains(version)
            }
        }
    }
}

/// Reads the install identity in the front door's order: an install in
/// progress, then state.json, then the registry markers of Atlas before 0.6.
/// The front door checks again before changing anything.
pub fn read_install_identity() -> Result<InstallIdentity> {
    let path = state_path();
    let fixture = cfg!(debug_assertions) && std::env::var_os("ATLAS_STATE_FILE").is_some();
    read_identity_at(
        &path,
        || {
            if fixture {
                return Ok(Vec::new());
            }
            let mut versions = read_legacy_versions()?;
            if versions.is_empty() {
                // A Windows that rebuilt itself during Atlas Manager's move can
                // lose the markers; the record of the move kept the version.
                versions.extend(super::update_access::rebase_version());
            }
            Ok(versions)
        },
        || {
            if fixture {
                return Ok(false);
            }
            let windows = path.parent().and_then(|root| root.parent()).context("Windows directory")?;
            Ok(windows.join("AtlasModules/Scripts").try_exists()?)
        },
    )
}

fn read_identity_at(
    path: &Path,
    legacy: impl FnOnce() -> Result<Vec<String>>,
    atlas_files_exist: impl FnOnce() -> Result<bool>,
) -> Result<InstallIdentity> {
    let root = path.parent().context("Atlas state directory")?;
    if let Some(doc) = files::read_json::<serde_json::Value>(&root.join("Install/active.json"))? {
        let invalid = |field: &str| format!("the active Atlas installation record has an invalid {field}");
        anyhow::ensure!(doc["schemaVersion"] == 1, invalid("schemaVersion"));
        let target = doc["targetVersion"]
            .as_str()
            .filter(|s| !s.trim().is_empty())
            .with_context(|| invalid("targetVersion"))?;
        let mode = InstallMode::parse(doc["mode"].as_str());
        anyhow::ensure!(mode != InstallMode::Unknown, invalid("mode"));
        let status = doc["status"]
            .as_str()
            .filter(|status| ["Capturing", "Running"].contains(status))
            .with_context(|| invalid("status"))?;
        let choose_again = choose_again(doc.get("choices")).with_context(|| invalid("choices"))?;
        // The same test Set-AtlasInstallOptions uses to hold a resume to its
        // original options.
        let held =
            status == "Running" || doc["completedSteps"].as_array().is_some_and(|steps| !steps.is_empty());
        let held = held
            .then(|| serde_json::from_value::<Vec<String>>(doc["options"].clone()))
            .transpose()
            .context("read original Atlas installation choices")?;
        return Ok(InstallIdentity::Resume(target.to_owned(), Unfinished { held, choose_again, mode }));
    }
    let state = read_at(path)?;
    let version =
        state.as_ref().and_then(|s| s.installed_version.as_deref()).filter(|s| !s.trim().is_empty());
    if let Some(version) = version {
        return Ok(InstallIdentity::Installed(version.to_owned()));
    }
    let mut versions = legacy()?;
    versions.sort();
    versions.dedup();
    anyhow::ensure!(versions.len() <= 1, "installed Atlas version markers disagree");
    if let Some(version) = versions.pop() {
        return Ok(InstallIdentity::Installed(version));
    }
    anyhow::ensure!(!atlas_files_exist()?, "Atlas's files exist without an identifiable installed version");
    Ok(InstallIdentity::Fresh)
}

fn read_legacy_versions() -> Result<Vec<String>> {
    let markers = [
        (r"SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation", "Model"),
        (r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "RegisteredOrganization"),
    ]
    .map(|(key, name)| -> Result<Option<String>> {
        let value = windows_registry::LOCAL_MACHINE.open(key).and_then(|key| key.get_string(name));
        match value {
            Ok(value) => Ok(legacy_version(&value)),
            Err(error) if error.code().0 == registry::NOT_FOUND => Ok(None),
            Err(error) => Err(error).context("read legacy Atlas identity"),
        }
    });
    let mut versions = Vec::new();
    for marker in markers {
        if let Some(version) = marker? {
            versions.push(version);
        }
    }
    Ok(versions)
}

fn legacy_version(value: &str) -> Option<String> {
    const PREFIX: &str = "Atlas Playbook ";
    let version = value
        .get(..PREFIX.len())
        .filter(|prefix| prefix.eq_ignore_ascii_case(PREFIX))
        .and_then(|_| value.get(PREFIX.len()..))?;
    let version = version.strip_prefix(['v', 'V']).unwrap_or(version);
    let parts: Vec<_> = version.split('.').collect();
    (parts.len() == 3 && parts.iter().all(|p| !p.is_empty() && p.bytes().all(|b| b.is_ascii_digit())))
        .then(|| version.to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn declared_upgrade_sources_and_same_version_reapply_are_distinct_from_other_installs() {
        let manifest = super::super::playbook::parse(
            "<Playbook><Version>0.6.0</Version><UpgradableFrom><string>0.4.1</string><string>0.5.0</string></UpgradableFrom></Playbook>",
        )
        .unwrap();
        for version in ["0.4.1", "0.5.0", "0.6.0"] {
            assert!(InstallIdentity::Installed(version.into()).allows(&manifest));
        }
        for version in ["0.3.2", "0.5.0-hotfix", "0.5.1", "0.7.0", "unknown"] {
            assert!(!InstallIdentity::Installed(version.into()).allows(&manifest));
        }
        assert!(InstallIdentity::Fresh.allows(&manifest));
        assert!(InstallIdentity::Resume("0.6.0".into(), Unfinished::default()).allows(&manifest));
        assert!(!InstallIdentity::Resume("0.5.0".into(), Unfinished::default()).allows(&manifest));
    }

    /// Start-AtlasInstallState writes active.json, so every mode it accepts
    /// must be one the app reads as itself, and nothing else may be read.
    #[test]
    fn every_mode_the_install_state_writes_is_one_the_app_reads() {
        let module = include_str!(
            "../../../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.InstallState/Atlas.InstallState.psm1"
        );
        let start =
            &module[module.find("function Start-AtlasInstallState").expect("Start-AtlasInstallState")..];
        let list = &start[start.find("[ValidateSet(").expect("its mode list") + "[ValidateSet(".len()..];
        let modes: Vec<&str> =
            list[..list.find(')').unwrap()].split(',').map(|mode| mode.trim().trim_matches('\'')).collect();
        assert!(modes.len() >= 4, "{modes:?}");
        let temp = super::super::test_support::TempDir::new("install-modes");
        let state = temp.path().join("state.json");
        let active = temp.path().join("Install/active.json");
        std::fs::create_dir_all(active.parent().unwrap()).unwrap();
        let identity = |mode: &str| {
            let doc = serde_json::json!({
                "schemaVersion": 1, "targetVersion": "0.6.0", "mode": mode, "status": "Capturing",
            });
            std::fs::write(&active, doc.to_string()).unwrap();
            read_identity_at(&state, || panic!("must use active state"), || panic!("must use active state"))
        };
        for mode in modes.iter().flat_map(|mode| [mode.to_string(), mode.to_ascii_lowercase()]) {
            let parsed = InstallMode::parse(Some(&mode));
            assert!(format!("{parsed:?}").eq_ignore_ascii_case(&mode), "{mode} reads as {parsed:?}");
            assert_eq!(
                identity(&mode).unwrap(),
                InstallIdentity::Resume("0.6.0".into(), Unfinished { mode: parsed, ..Unfinished::default() }),
                "{mode}"
            );
        }
        assert_eq!(InstallMode::parse(Some("Repair")), InstallMode::Unknown);
        assert!(identity("Repair").is_err());
    }

    /// Start-AtlasInstallState records its `-Choices` in active.json, so each
    /// value it accepts must be one the app reads, and nothing else may be.
    #[test]
    fn every_choice_the_install_state_records_is_one_the_app_reads() {
        let module = include_str!(
            "../../../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.InstallState/Atlas.InstallState.psm1"
        );
        let start =
            &module[module.find("function Start-AtlasInstallState").expect("Start-AtlasInstallState")..];
        let before = &start[..start.find("[string]$Choices").expect("its -Choices parameter")];
        let list =
            &before[before.rfind("[ValidateSet(").expect("its choices list") + "[ValidateSet(".len()..];
        let values: Vec<&str> =
            list[..list.find(')').unwrap()].split(',').map(|value| value.trim().trim_matches('\'')).collect();
        assert_eq!(values, ["Keep", "ChooseAgain"]);
        for value in &values {
            assert_eq!(
                choose_again(Some(&serde_json::json!(value))),
                Some(*value == "ChooseAgain"),
                "{value}"
            );
        }
        assert_eq!(
            choose_again(Some(&serde_json::json!("keep"))),
            None,
            "the install state compares exactly"
        );
    }

    #[test]
    fn legacy_marker_parser_matches_the_front_door_contract() {
        for value in ["Atlas Playbook v0.4.1", "Atlas Playbook 0.4.1", "atlas playbook V0.4.1"] {
            assert_eq!(legacy_version(value).as_deref(), Some("0.4.1"));
        }
        for value in [
            "Atlas 0.4.1",
            "Atlas Playbook 0.5.0-hotfix",
            "Atlas Playbook 0.5",
            "Atlas Playbook 0.5.1 ",
            "Other",
        ] {
            assert_eq!(legacy_version(value), None);
        }
    }

    #[test]
    fn identity_files_preserve_active_then_state_then_legacy_precedence() {
        let temp = super::super::test_support::TempDir::new("eligibility");
        let state = temp.path().join("state.json");
        let active = temp.path().join("Install/active.json");
        std::fs::create_dir_all(active.parent().unwrap()).unwrap();
        std::fs::write(&state, r#"{"schemaVersion":1,"installedVersion":"0.3.2"}"#).unwrap();
        std::fs::write(
            &active,
            r#"{"schemaVersion":1,"targetVersion":"0.6.0","mode":"Fresh","status":"Capturing"}"#,
        )
        .unwrap();
        let no_legacy = || -> Result<Vec<String>> { panic!("must not read legacy evidence") };
        let no_files = || -> Result<bool> { panic!("must not look for Atlas's files") };
        assert_eq!(
            read_identity_at(&state, no_legacy, no_files).unwrap(),
            InstallIdentity::Resume(
                "0.6.0".into(),
                Unfinished { mode: InstallMode::Fresh, ..Unfinished::default() }
            )
        );
        std::fs::remove_file(&active).unwrap();
        assert_eq!(
            read_identity_at(&state, no_legacy, no_files).unwrap(),
            InstallIdentity::Installed("0.3.2".into())
        );
        std::fs::write(&state, r#"{"schemaVersion":1,"options":["choice"]}"#).unwrap();
        assert_eq!(
            read_identity_at(&state, || Ok(vec!["0.5.0".into(), "0.5.0".into()]), no_files).unwrap(),
            InstallIdentity::Installed("0.5.0".into())
        );
        assert!(read_identity_at(&state, || Ok(vec!["0.5.0".into(), "0.4.1".into()]), no_files).is_err());
        assert!(read_identity_at(&state, || Ok(vec![]), || Ok(true)).is_err());
        assert_eq!(read_identity_at(&state, || Ok(vec![]), || Ok(false)).unwrap(), InstallIdentity::Fresh);
        assert!(read_identity_at(&state, || anyhow::bail!("registry access denied"), no_files).is_err());
        std::fs::write(&active, "broken").unwrap();
        assert!(read_identity_at(&state, no_legacy, no_files).is_err());
        std::fs::remove_file(&active).unwrap();
        std::fs::write(&state, "broken").unwrap();
        assert!(read_identity_at(&state, no_legacy, no_files).is_err());
    }

    /// A plan that runs, or one recovered to Capturing with steps already
    /// done, keeps its original options; so does the app.
    #[test]
    fn a_started_install_recovers_exact_choices_and_rejects_missing_or_invalid_choices() {
        let temp = super::super::test_support::TempDir::new("resume-choices");
        let state = temp.path().join("state.json");
        let active = temp.path().join("Install/active.json");
        std::fs::create_dir_all(active.parent().unwrap()).unwrap();
        let read = |status: &str, steps: serde_json::Value, options: &serde_json::Value| {
            let doc = serde_json::json!({
                "schemaVersion": 1, "targetVersion": "0.6.0", "mode": "Fresh", "status": status,
                "completedSteps": steps, "options": options,
            });
            std::fs::write(&active, doc.to_string()).unwrap();
            read_identity_at(&state, || panic!("must use active state"), || panic!("must use active state"))
        };
        for (status, steps) in
            [("Running", serde_json::json!([])), ("Capturing", serde_json::json!(["Features"]))]
        {
            for options in [
                serde_json::json!(["auto-updates-disable", "disable-power-saving"]),
                serde_json::Value::Null,
                serde_json::json!([42]),
            ] {
                let result = read(status, steps.clone(), &options);
                if options[0].is_string() {
                    assert_eq!(
                        result.unwrap(),
                        InstallIdentity::Resume(
                            "0.6.0".into(),
                            Unfinished {
                                held: Some(vec![
                                    "auto-updates-disable".into(),
                                    "disable-power-saving".into()
                                ]),
                                choose_again: false,
                                mode: InstallMode::Fresh,
                            }
                        ),
                        "{status}"
                    );
                } else {
                    assert!(result.is_err(), "{status} {options}");
                }
            }
        }
        // Until then the choices can still change, whatever they were.
        assert_eq!(
            read("Capturing", serde_json::json!([]), &serde_json::Value::Null).unwrap(),
            InstallIdentity::Resume(
                "0.6.0".into(),
                Unfinished { mode: InstallMode::Fresh, ..Unfinished::default() }
            )
        );
        assert!(read("Completed", serde_json::json!(["Features"]), &serde_json::json!([])).is_err());
    }

    /// An unfinished install says whether it chose again, held or not. A
    /// record from before the choice existed keeps the choices, and one the
    /// install state would refuse is refused here too.
    #[test]
    fn an_unfinished_install_says_whether_it_chose_again() {
        let temp = super::super::test_support::TempDir::new("resume-choose-again");
        let state = temp.path().join("state.json");
        let active = temp.path().join("Install/active.json");
        std::fs::create_dir_all(active.parent().unwrap()).unwrap();
        let read = |status: &str, choices: Option<serde_json::Value>| {
            let mut doc = serde_json::json!({
                "schemaVersion": 1, "targetVersion": "0.6.0", "mode": "Reapply", "status": status,
                "completedSteps": [], "options": ["defender-enable"],
            });
            if let Some(choices) = choices {
                doc["choices"] = choices;
            }
            std::fs::write(&active, doc.to_string()).unwrap();
            read_identity_at(&state, || panic!("must use active state"), || panic!("must use active state"))
        };
        let held = |choose_again| {
            InstallIdentity::Resume(
                "0.6.0".into(),
                Unfinished {
                    held: Some(vec!["defender-enable".into()]),
                    choose_again,
                    mode: InstallMode::Reapply,
                },
            )
        };
        assert_eq!(read("Running", None).unwrap(), held(false), "a record from before -ChooseAgain");
        assert_eq!(read("Running", Some("Keep".into())).unwrap(), held(false));
        assert_eq!(read("Running", Some("ChooseAgain".into())).unwrap(), held(true));
        // Until a step has run, nothing is held, but the way it began is still read.
        let unheld = |choose_again| {
            InstallIdentity::Resume(
                "0.6.0".into(),
                Unfinished { held: None, choose_again, mode: InstallMode::Reapply },
            )
        };
        assert_eq!(read("Capturing", Some("ChooseAgain".into())).unwrap(), unheld(true));
        assert_eq!(read("Capturing", Some("Keep".into())).unwrap(), unheld(false));
        assert_eq!(read("Capturing", None).unwrap(), unheld(false));
        for invalid in [
            serde_json::Value::Null,
            serde_json::json!("chooseagain"),
            serde_json::json!(true),
            serde_json::json!(["Keep"]),
        ] {
            assert!(read("Running", Some(invalid.clone())).is_err(), "{invalid}");
            assert!(read("Capturing", Some(invalid.clone())).is_err(), "{invalid}");
        }
    }

    /// Capture writes state.json before the install has finished; only a
    /// version and a valid time of completion make it an installed PC.
    #[test]
    fn only_a_versioned_timestamped_state_is_an_installed_pc() {
        for (version, timestamp, installed) in [
            (None, None, false),
            (Some("0.6.0"), None, false),
            (Some("0.6.0"), Some("invalid"), false),
            (Some(""), Some("2026-09-07T14:00:00Z"), false),
            (Some("0.6.0"), Some("2026-09-07T14:00:00Z"), true),
        ] {
            let state: AtlasState = serde_json::from_value(serde_json::json!({
                "schemaVersion": 1, "installedVersion": version, "installedAt": timestamp,
            }))
            .unwrap();
            assert_eq!(state.has_completed_install(), installed, "{version:?} {timestamp:?}");
        }
    }
}
