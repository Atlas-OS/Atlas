//! Reads the machine state document that an Atlas install leaves behind at
//! `%windir%\AtlasOS\state.json` (owned by the Atlas.State PowerShell module).

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use chrono::{DateTime, Local};
use serde::Deserialize;

use super::{files, registry};

/// How an install was done, from the state document's `mode`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum InstallMode {
    Fresh,
    Upgrade,
    Reapply,
    Unknown,
}

impl InstallMode {
    pub fn parse(mode: Option<&str>) -> InstallMode {
        match mode.map(str::to_ascii_lowercase).as_deref() {
            Some("fresh") => InstallMode::Fresh,
            Some("upgrade") => InstallMode::Upgrade,
            Some("reapply") => InstallMode::Reapply,
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
    /// An unfinished install of this version, with the options it was
    /// started with once its plan is running.
    Resume(String, Option<Vec<String>>),
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
            read_legacy_versions()
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
    let active = root.join("Install/active.json");
    match std::fs::read_to_string(&active) {
        Ok(text) => {
            let doc: serde_json::Value = serde_json::from_str(text.trim_start_matches('\u{feff}'))?;
            let target = doc["targetVersion"].as_str().filter(|s| !s.trim().is_empty());
            anyhow::ensure!(
                doc["schemaVersion"] == 1
                    && target.is_some()
                    && doc["mode"].as_str().is_some_and(
                        |m| ["fresh", "upgrade", "reapply"].contains(&m.to_ascii_lowercase().as_str())
                    ),
                "the active Atlas installation record is invalid"
            );
            let options = if doc["status"] == "Running" {
                Some(
                    serde_json::from_value::<Vec<String>>(doc["options"].clone())
                        .context("read original Atlas installation choices")?,
                )
            } else {
                anyhow::ensure!(doc["status"] == "Capturing", "invalid active installation status");
                None
            };
            return Ok(InstallIdentity::Resume(target.unwrap().to_owned(), options));
        }
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => return Err(error).context("read active Atlas installation"),
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
            "<Playbook><Version>0.6.0</Version><UpgradableFrom><string>0.4.1</string><string>0.5.0</string><string>0.5.1</string></UpgradableFrom></Playbook>",
        )
        .unwrap();
        for version in ["0.4.1", "0.5.0", "0.5.1", "0.6.0"] {
            assert!(InstallIdentity::Installed(version.into()).allows(&manifest));
        }
        for version in ["0.3.2", "0.5.0-hotfix", "0.7.0", "unknown"] {
            assert!(!InstallIdentity::Installed(version.into()).allows(&manifest));
        }
        assert!(InstallIdentity::Fresh.allows(&manifest));
        assert!(InstallIdentity::Resume("0.6.0".into(), None).allows(&manifest));
        assert!(!InstallIdentity::Resume("0.5.1".into(), None).allows(&manifest));
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
            InstallIdentity::Resume("0.6.0".into(), None)
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

    #[test]
    fn running_install_recovers_exact_choices_and_rejects_missing_or_invalid_choices() {
        let temp = super::super::test_support::TempDir::new("resume-choices");
        let state = temp.path().join("state.json");
        let active = temp.path().join("Install/active.json");
        std::fs::create_dir_all(active.parent().unwrap()).unwrap();
        for options in [
            serde_json::json!(["auto-updates-disable", "disable-power-saving"]),
            serde_json::Value::Null,
            serde_json::json!([42]),
        ] {
            std::fs::write(&active, serde_json::json!({"schemaVersion":1,"targetVersion":"0.6.0","mode":"Fresh","status":"Running","options":options}).to_string()).unwrap();
            let result = read_identity_at(
                &state,
                || panic!("must use active state"),
                || panic!("must use active state"),
            );
            if options[0].is_string() {
                assert_eq!(
                    result.unwrap(),
                    InstallIdentity::Resume(
                        "0.6.0".into(),
                        Some(vec!["auto-updates-disable".into(), "disable-power-saving".into()])
                    )
                );
            } else {
                assert!(result.is_err());
            }
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
