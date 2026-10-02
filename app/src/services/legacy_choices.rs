//! The install choices an Atlas without a state document (0.5.x and 0.4.1)
//! shows on the PC: the Defender package, the toggle records its choices
//! left, what it removed or installed. The same rules as the update worker's
//! `Get-AtlasTransitionObservedOption` (Preparation\WindowsTransition.ps1);
//! a shared fixture keeps the two in step. Read only. A choice nothing shows
//! is left out, never guessed.

use std::collections::HashMap;
use std::path::Path;

use windows_registry::{CURRENT_USER, LOCAL_MACHINE};

/// What the PC shows, as the worker reads it.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Facts {
    /// Installed Atlas servicing packages (`Z-Atlas-...`).
    pub packages: Vec<String>,
    /// Toggle records under `HKLM\SOFTWARE\AtlasOS\Services`, by name.
    pub toggles: HashMap<String, u32>,
    /// `HKLM\SOFTWARE\AtlasOS\SetupOptions\browser`, when the value exists.
    pub browser: Option<String>,
    pub edge: bool,
    /// Installed app families (`Name_PublisherId`).
    pub appx: Vec<String>,
    pub toolbox: bool,
    pub core_isolation_off: bool,
    /// Browsers Atlas offers that are installed, by option name.
    pub browsers: Vec<String>,
}

/// The install options `facts` show.
pub fn observed_options(facts: &Facts) -> Vec<String> {
    let mut options = Vec::new();
    let mut add = |option: &str| options.push(option.to_owned());
    if facts.packages.iter().any(|package| package.starts_with("Z-Atlas-NoDefender-Package")) {
        add("defender-disable");
    } else if !facts.packages.is_empty() {
        add("defender-enable");
    }
    if let Some(state) = facts.toggles.get("Mitigations") {
        add(if *state == 0 { "mitigations-disable" } else { "mitigations-default" });
    }
    if let Some(state) = facts.toggles.get("AutomaticUpdates") {
        add(if *state == 0 { "auto-updates-disable" } else { "auto-updates-default" });
    }
    if facts.toggles.get("Hibernation") == Some(&0) {
        add("disable-hibernation");
    }
    if facts.toggles.get("PowerSaving") == Some(&0) {
        add("disable-power-saving");
    }
    if !facts.edge {
        add("uninstall-edge");
    }
    let snipping = |family: &String| family.to_ascii_lowercase().starts_with("microsoft.screensketch_");
    if !facts.appx.is_empty() && !facts.appx.iter().any(snipping) {
        add("remove-snipping-tool");
    }
    if facts.core_isolation_off {
        add("disable-core-isolation");
    }
    if facts.toolbox {
        add("install-toolbox");
    }
    // Atlas 0.5.0 records LibreWolf as an empty name, so then the one browser
    // installed decides.
    let browser = match facts.browser.as_deref() {
        Some("Brave") => Some("browser-brave"),
        Some("Firefox") => Some("browser-firefox"),
        Some("Google Chrome") => Some("browser-chrome"),
        Some("LibreWolf") => Some("browser-librewolf"),
        Some(_) if facts.browsers.len() == 1 => Some(facts.browsers[0].as_str()),
        _ => None,
    };
    if let Some(browser) = browser {
        let browser = browser.to_owned();
        add("install-another-browser");
        add(&browser);
    }
    options
}

/// The options this PC shows, or none when it has no Atlas packages,
/// toggle records or Atlas files to read them from.
pub fn read() -> Vec<String> {
    let facts = read_facts();
    if facts.packages.is_empty() && facts.toggles.is_empty() {
        return Vec::new();
    }
    observed_options(&facts)
}

fn read_facts() -> Facts {
    let dword = |path: &str, name: &str| LOCAL_MACHINE.open(path).and_then(|key| key.get_u32(name)).ok();
    let subkeys = |root: &windows_registry::Key, path: &str| -> Vec<String> {
        root.open(path).and_then(|key| key.keys().map(Iterator::collect)).unwrap_or_default()
    };
    let packages_root = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages";
    let packages = subkeys(LOCAL_MACHINE, packages_root)
        .into_iter()
        .filter(|name| name.starts_with("Z-Atlas-"))
        .filter(|name| dword(&format!(r"{packages_root}\{name}"), "CurrentState") == Some(112))
        .collect();
    let toggles = subkeys(LOCAL_MACHINE, r"SOFTWARE\AtlasOS\Services")
        .into_iter()
        .filter_map(|name| {
            dword(&format!(r"SOFTWARE\AtlasOS\Services\{name}"), "state").map(|state| (name, state))
        })
        .collect();
    // The installing user's apps: an unelevated read can't list every user's.
    let appx = subkeys(
        CURRENT_USER,
        r"Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages",
    )
    .into_iter()
    .filter_map(|full| {
        let parts: Vec<&str> = full.split('_').collect();
        (parts.len() >= 2).then(|| format!("{}_{}", parts[0], parts[parts.len() - 1]))
    })
    .collect();
    let program_files = std::env::var_os("ProgramW6432")
        .or_else(|| std::env::var_os("ProgramFiles"))
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| r"C:\Program Files".into());
    let x86 = std::env::var_os("ProgramFiles(x86)")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| r"C:\Program Files (x86)".into());
    let exists = |path: &Path| path.exists();
    let browsers = [
        ("browser-brave", r"BraveSoftware\Brave-Browser\Application\brave.exe"),
        ("browser-firefox", r"Mozilla Firefox\firefox.exe"),
        ("browser-chrome", r"Google\Chrome\Application\chrome.exe"),
        ("browser-librewolf", r"LibreWolf\librewolf.exe"),
    ]
    .into_iter()
    .filter(|(_, path)| exists(&program_files.join(path)))
    .map(|(option, _)| option.to_owned())
    .collect();
    Facts {
        packages,
        toggles,
        browser: LOCAL_MACHINE
            .open(r"SOFTWARE\AtlasOS\SetupOptions")
            .and_then(|key| key.get_string("browser"))
            .ok(),
        edge: exists(&x86.join(r"Microsoft\Edge\Application\msedge.exe")),
        appx,
        toolbox: LOCAL_MACHINE.open(r"SOFTWARE\AtlasOS\Toolbox").is_ok(),
        core_isolation_off: core_isolation_off(
            dword(r"SYSTEM\CurrentControlSet\Control\DeviceGuard", "EnableVirtualizationBasedSecurity"),
            dword(
                r"SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity",
                "Enabled",
            ),
        ),
        browsers,
    }
}

/// What Atlas 0.5.0's "Disable Core Isolation" (`ConfigVBS.ps1 -DisableAllVBS`)
/// leaves under `Control\DeviceGuard`: virtualization-based security off, and
/// memory integrity off where Windows had its key. Without that key the
/// script's write of it failed and only the first value was set, so memory
/// integrity may be absent, but not on. The worker reads the same rule
/// (`Test-AtlasTransitionCoreIsolationOff`).
fn core_isolation_off(vbs: Option<u32>, memory_integrity: Option<u32>) -> bool {
    vbs == Some(0) && memory_integrity.is_none_or(|value| value == 0)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The registry values Atlas 0.5.0 and Windows leave, shared with the
    /// worker's Pester cases.
    #[test]
    fn core_isolation_is_read_from_the_values_atlas_0_5_0_leaves() {
        let path =
            concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/windows-transition/core-isolation.json");
        let cases: Vec<serde_json::Value> =
            serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
        assert!(!cases.is_empty());
        for case in cases {
            let value = |name: &str| case["values"][name].as_u64().map(|value| value as u32);
            assert_eq!(
                core_isolation_off(
                    value("enableVirtualizationBasedSecurity"),
                    value("hypervisorEnforcedCodeIntegrity")
                ),
                case["off"].as_bool().unwrap(),
                "{}",
                case["name"]
            );
        }
    }

    /// The worker reads the same cases (Pester), so the app and the record of
    /// a move agree on what an Atlas install chose.
    #[test]
    fn the_options_match_the_worker_s_for_every_shared_case() {
        let path = concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../tests/fixtures/windows-transition/observed-options.json"
        );
        let cases: Vec<serde_json::Value> =
            serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
        assert!(!cases.is_empty());
        for case in cases {
            let facts = &case["facts"];
            let strings = |value: &serde_json::Value| -> Vec<String> {
                value
                    .as_array()
                    .map(|items| items.iter().filter_map(|item| item.as_str().map(str::to_owned)).collect())
                    .unwrap_or_default()
            };
            let facts = Facts {
                packages: strings(&case["packages"]),
                toggles: facts["toggles"]
                    .as_array()
                    .unwrap()
                    .iter()
                    .map(|record| {
                        (
                            record["name"].as_str().unwrap().to_owned(),
                            record["state"].as_u64().unwrap() as u32,
                        )
                    })
                    .collect(),
                browser: facts["browser"].as_str().map(str::to_owned),
                edge: facts["edge"].as_bool().unwrap(),
                appx: strings(&facts["appx"]),
                toolbox: facts["toolbox"].as_bool().unwrap(),
                core_isolation_off: facts["coreIsolationOff"].as_bool().unwrap(),
                browsers: strings(&facts["browsers"]),
            };
            assert_eq!(observed_options(&facts), strings(&case["options"]), "{}", case["name"]);
        }
    }
}
