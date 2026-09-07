//! Build installation media without running a payload on the host.
//! Requests are JSON data, never interpolated into PowerShell source.
use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

const SETUP_CAPABILITY: &str = "Executables/AtlasModules/Scripts/Install/iso-setup.json";
use std::fs;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::{
    Arc,
    atomic::{AtomicBool, Ordering},
};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Mode {
    #[default]
    Interactive,
    Configured,
    BeforeDesktop,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Request {
    #[serde(default)]
    pub reinstall_this_pc: bool,
    #[serde(default)]
    pub copy_network_drivers: bool,
    #[serde(default)]
    pub update_network_drivers: bool,
    #[serde(default)]
    pub drivers: super::preparation::Drivers,
    pub username: String,
    pub source: PathBuf,
    pub output: PathBuf,
    pub archive: PathBuf,
    pub package: PathBuf,
    pub app: PathBuf,
    pub mode: Mode,
    pub options: Vec<String>,
    pub supported_builds: Vec<u32>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImageInfo {
    pub editions: Vec<String>,
    pub bytes: u64,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum Stage {
    #[default]
    Inspect,
    Copy,
    Inject,
    NetworkDrivers,
    Master,
    Verify,
    Cleanup,
}
impl Stage {
    pub fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "inspect" => Self::Inspect,
            "copy" => Self::Copy,
            "inject" => Self::Inject,
            "network-drivers" => Self::NetworkDrivers,
            "master" => Self::Master,
            "verify" => Self::Verify,
            "cleanup" => Self::Cleanup,
            _ => return None,
        })
    }
}

pub fn supports_setup(package: &Path) -> bool {
    // Explicit capability; a version string or an AME SupportsISO flag is not enough.
    fs::read_to_string(package.join(SETUP_CAPABILITY))
        .ok()
        .and_then(|s| serde_json::from_str::<serde_json::Value>(&s).ok())
        .is_some_and(|v| {
            v.get("schema").and_then(|v| v.as_u64()) == Some(1)
                && v.get("firstSignIn").and_then(|v| v.as_bool()) == Some(true)
        })
}

pub fn supports_version(version: &str) -> bool {
    let mut parts = version.trim_start_matches('v').split(['.', '-']);
    matches!((parts.next().and_then(|v| v.parse::<u32>().ok()), parts.next().and_then(|v| v.parse::<u32>().ok())), (Some(major), Some(minor)) if major > 0 || minor >= 6)
}

pub fn validate_options(manifest: &super::playbook::Manifest, options: &[String]) -> Result<()> {
    use std::collections::HashSet;
    let unique: HashSet<_> = options.iter().collect();
    if unique.len() != options.len() || options.iter().any(|o| manifest.option_label(o).is_none()) {
        bail!("Unknown or repeated Atlas option");
    }
    for page in &manifest.pages {
        let selected = page.options.iter().filter(|o| options.contains(&o.name)).count();
        let active = page.depends_on.as_ref().is_none_or(|n| options.contains(n));
        if (!active && selected != 0)
            || (active && page.kind == super::playbook::PageKind::Radio && selected != 1)
        {
            bail!("The Atlas choices are incomplete or inconsistent");
        }
    }
    Ok(())
}

pub fn default_options(manifest: &super::playbook::Manifest) -> Vec<String> {
    let mut options = manifest.default_options();
    for page in &manifest.pages {
        if page.depends_on.as_ref().is_some_and(|n| !options.contains(n)) {
            options.retain(|n| !page.options.iter().any(|o| &o.name == n));
        }
    }
    options
}

pub fn validate(request: &Request) -> Result<()> {
    anyhow::ensure!(
        !request.update_network_drivers || request.copy_network_drivers,
        "Network driver updates require network driver copying."
    );
    anyhow::ensure!(
        !request.copy_network_drivers || request.reinstall_this_pc,
        "Network drivers can only be copied for reinstalling this PC."
    );
    if !valid_username(&request.username) {
        bail!("Invalid Windows local account name");
    }
    if !request.source.extension().is_some_and(|e| e.eq_ignore_ascii_case("iso")) {
        bail!("Choose a Windows ISO file");
    }
    if !request.output.extension().is_some_and(|e| e.eq_ignore_ascii_case("iso")) {
        bail!("The output filename must end in .iso");
    }
    if request.output.exists() {
        bail!("The output already exists; choose a new filename");
    }
    let parent = request.output.parent().context("output has no parent")?.canonicalize()?;
    let source = request.source.canonicalize()?;
    if source == parent.join(request.output.file_name().context("missing filename")?) {
        bail!("The source and output must be different files");
    }
    if request.mode != Mode::Interactive && !supports_setup(&request.package) {
        bail!("This package does not support ISO setup");
    }
    if request.options.iter().any(|o| {
        o.is_empty() || !o.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
    }) {
        bail!("Invalid Atlas option identifier");
    }
    Ok(())
}

pub fn valid_username(name: &str) -> bool {
    !name.is_empty()
        && name.encode_utf16().count() <= 20
        && name.trim() == name
        && !name.ends_with('.')
        && !name.chars().any(|c| c.is_control() || "\"/\\[]:;|=,+*?<>@".contains(c))
        && ![
            "administrator",
            "guest",
            "defaultaccount",
            "defaultuser0",
            "wdagutilityaccount",
            "system",
            "anonymous logon",
        ]
        .iter()
        .any(|reserved| name.eq_ignore_ascii_case(reserved))
}

/// Read choices only for the app and package staged together by Windows Setup.
pub(super) fn staged_settings() -> Option<serde_json::Value> {
    let root = PathBuf::from(std::env::var_os("WINDIR")?).join("AtlasISO");
    if std::env::current_exe().ok()?.canonicalize().ok()?
        != root.join("AtlasManager.exe").canonicalize().ok()?
    {
        return None;
    }
    let value: serde_json::Value =
        serde_json::from_str(&fs::read_to_string(root.join("setup.json")).ok()?).ok()?;
    if value["schema"] != 2 {
        return None;
    }
    Some(value)
}

pub fn staged_drivers() -> Option<super::preparation::Drivers> {
    serde_json::from_value(staged_settings()?["drivers"].clone()).ok()
}

pub fn staged_options() -> Option<Vec<String>> {
    let value = staged_settings()?;
    if value["mode"] != "configured" && value["mode"] != "before-desktop" {
        return None;
    }
    serde_json::from_value(value["options"].clone()).ok()
}

/// A unique diagnostic directory remains available even after failure.
pub fn job_dir() -> Result<PathBuf> {
    let id = SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos();
    let dir = super::settings::app_data_dir().join("ISO").join(format!("{}-{id}", std::process::id()));
    fs::create_dir_all(&dir)?;
    Ok(dir)
}

#[derive(Debug)]
pub struct UnverifiedWindowsRelease;

impl std::fmt::Display for UnverifiedWindowsRelease {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("The ISO's Windows build could not be verified as a public release")
    }
}

impl std::error::Error for UnverifiedWindowsRelease {}

pub fn run(
    request: &Request,
    dir: &Path,
    inspect: bool,
    cancel: Arc<AtomicBool>,
    mut report: impl FnMut(Stage),
) -> Result<Option<ImageInfo>> {
    validate(request)?;
    let script = dir.join("Build-Iso.ps1");
    let input = dir.join("request.json");
    fs::write(&script, include_str!("../../resources/iso/Build-Iso.ps1"))?;
    fs::write(
        dir.join("Windows-Release.ps1"),
        include_str!("../../../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1"),
    )?;
    fs::write(
        dir.join("windows-releases.json"),
        include_str!(
            "../../../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json"
        ),
    )?;
    fs::write(dir.join("Master-Iso.ps1"), include_str!("../../resources/iso/Master-Iso.ps1"))?;
    fs::write(dir.join("Setup.ps1"), include_str!("../../resources/iso/Setup.ps1"))?;
    fs::write(dir.join("Desktop.ps1"), include_str!("../../resources/iso/Desktop.ps1"))?;
    fs::write(dir.join("Desktop-Policy.ps1"), include_str!("../../resources/iso/Desktop-Policy.ps1"))?;
    fs::write(dir.join("THIRD-PARTY-NOTICES.txt"), super::licenses::TEXT)?;
    fs::write(dir.join("Network-Drivers.ps1"), include_str!("../../resources/iso/Network-Drivers.ps1"))?;
    fs::write(dir.join("DriverPolicy.reg"), request.drivers.policy())?;
    fs::write(&input, serde_json::to_vec(request)?)?;
    let log = fs::File::create(dir.join("build.log"))?;
    let mut command = Command::new(super::system::powershell_path());
    command
        .args(["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"])
        .arg(&script)
        .arg("-RequestFile")
        .arg(&input)
        .arg("-Operation")
        .arg(if inspect { "Inspect" } else { "Build" })
        .stdout(Stdio::piped())
        .stderr(Stdio::from(log.try_clone()?));
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x08000000);
    }
    let mut child = command.spawn().context("start Windows image worker")?;
    let flag = dir.join("cancel");
    let stop = Arc::new(AtomicBool::new(false));
    let watcher = super::system::watch_cancellation(cancel, stop.clone(), flag);
    let mut image = None;
    let mut release_unverified = false;
    use std::io::Write;
    let mut log = log;
    let stream = child.stdout.take().context("worker stdout")?;
    for line in BufReader::new(stream).lines() {
        let Ok(line) = line else { break };
        let _ = writeln!(log, "{line}");
        release_unverified |= line == "ATLAS_ERROR:windows-release-unknown";
        if let Some(stage) = line.strip_prefix("ATLAS_STAGE:").and_then(Stage::parse) {
            report(stage);
        }
        if let Some(json) = line.strip_prefix("ATLAS_RESULT:") {
            image = serde_json::from_str(json).ok();
        }
    }
    let result = child.wait();
    stop.store(true, Ordering::Relaxed);
    let _ = watcher.join();
    if !result?.success() {
        if release_unverified {
            return Err(UnverifiedWindowsRelease.into());
        }
        bail!("Windows image worker failed. See {}", dir.join("build.log").display());
    }
    if inspect && image.is_none() {
        bail!("Windows did not return image information");
    }
    Ok(image)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn local_account_names_follow_windows_limits() {
        for name in [
            "",
            " admin",
            "admin ",
            "name.",
            "Administrator",
            "user/name",
            "user\nname",
            "name@example",
            "123456789012345678901",
        ] {
            assert!(!valid_username(name), "{name:?}");
        }
        for name in ["Atlas", "小明", "Мария", "José", "माया", "ผู้ใช้", "12345678901234567890"]
        {
            assert!(valid_username(name), "{name:?}");
        }
    }
    #[test]
    fn iso_support_begins_with_atlas_06() {
        for version in ["0.4.1", "0.5.0", "invalid"] {
            assert!(!supports_version(version));
        }
        for version in ["0.6.0", "0.6.0-beta.1", "0.7.0", "1.0.0"] {
            assert!(supports_version(version));
        }
    }
    #[test]
    fn request_rejects_unknown_fields() {
        let mut value = serde_json::json!({
            "username": "Atlas",
            "source": "Windows.iso",
            "output": "Atlas.iso",
            "archive": "Atlas.apbx",
            "package": "package",
            "app": "AtlasManager.exe",
            "mode": "interactive",
            "options": [],
            "supportedBuilds": [26200]
        });
        assert!(serde_json::from_value::<Request>(value.clone()).is_ok());
        value["command"] = serde_json::json!("Remove-Item");
        let error = serde_json::from_value::<Request>(value).unwrap_err();
        assert!(error.to_string().contains("unknown field `command`"));
    }
    #[test]
    fn stage_protocol_is_closed() {
        assert_eq!(Stage::parse("master"), Some(Stage::Master));
        assert_eq!(Stage::parse("done"), None);
    }

    #[test]
    fn iso_options_respect_required_groups_and_dependencies() {
        let manifest = super::super::playbook::Manifest::builtin();
        let defaults = default_options(&manifest);
        assert!(validate_options(&manifest, &defaults).is_ok());
        assert!(validate_options(&manifest, &[]).is_err());
        let mut unknown = defaults.clone();
        unknown.push("shell-command".into());
        assert!(validate_options(&manifest, &unknown).is_err());
        let mut duplicate = defaults.clone();
        duplicate.push(defaults[0].clone());
        assert!(validate_options(&manifest, &duplicate).is_err());
    }

    #[test]
    fn existing_outputs_and_unsupported_setup_packages_are_refused() {
        let temp = super::super::test_support::TempDir::new("iso-validation");
        let dir = temp.path().to_path_buf();
        let source = dir.join("Windows.iso");
        let output = dir.join("Atlas.iso");
        fs::write(&source, b"source").unwrap();
        let mut request = Request {
            reinstall_this_pc: false,
            copy_network_drivers: false,
            update_network_drivers: false,
            drivers: Default::default(),
            username: "Atlas".into(),
            source: source.clone(),
            output: output.clone(),
            archive: dir.join("Atlas.apbx"),
            package: dir.clone(),
            app: dir.join("AtlasManager.exe"),
            mode: Mode::Interactive,
            options: vec![],
            supported_builds: vec![26100],
        };
        assert!(validate(&request).is_ok());
        request.copy_network_drivers = true;
        assert!(validate(&request).is_err());
        request.reinstall_this_pc = true;
        assert!(validate(&request).is_ok());
        request.update_network_drivers = true;
        request.copy_network_drivers = false;
        assert!(validate(&request).is_err());
        request.update_network_drivers = false;
        fs::write(&output, b"keep").unwrap();
        assert!(validate(&request).is_err());
        assert_eq!(fs::read(&output).unwrap(), b"keep");
        request.output = source.clone();
        assert!(validate(&request).is_err());
        request.output = dir.join("new.iso");
        request.mode = Mode::Configured;
        assert!(validate(&request).is_err());
        fs::create_dir_all(dir.join(SETUP_CAPABILITY).parent().unwrap()).unwrap();
        fs::write(dir.join(SETUP_CAPABILITY), r#"{"schema":1,"firstSignIn":true}"#).unwrap();
        assert!(validate(&request).is_ok());
        fs::write(dir.join(SETUP_CAPABILITY), r#"{"schema":2,"firstSignIn":true}"#).unwrap();
        assert!(validate(&request).is_err());
    }
}
