//! What a PC shows of the install choices Atlas made on it: the Defender
//! package and service, the toggle records its choices left, what it removed
//! or installed. Read for every Atlas PC: an Atlas without a state document
//! (0.5.x and 0.4.1) has nothing else to show its choices, and an earlier
//! update may have recorded a choice it never applied. The same rules as the
//! update worker's `Get-AtlasTransitionObservedOption` and
//! `Merge-AtlasObservedOption` (Preparation\WindowsTransition.ps1); shared
//! fixtures keep the two in step. Read only. A choice nothing shows is left
//! out, never guessed.

use std::collections::HashMap;
use std::path::Path;

use windows_registry::{CURRENT_USER, LOCAL_MACHINE, Type};

use super::registry::{self, NOT_FOUND};

/// What the PC shows, as the worker reads it. A fact that is `None`, or an
/// app list that is empty, wasn't read: the choice it shows then stays as
/// recorded.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Facts {
    /// Installed Atlas servicing packages (`Z-Atlas-...`).
    pub packages: Vec<String>,
    /// Toggle records under `HKLM\SOFTWARE\AtlasOS\Services`, by name.
    pub toggles: HashMap<String, u32>,
    /// The file name in the `path` beside a record, by the record's name:
    /// the Atlas 0.5 launcher that wrote it, or empty when the path names no
    /// file. The old Toolbox and Atlas 0.6 leave no path.
    pub launchers: HashMap<String, String>,
    /// `HKLM\SOFTWARE\AtlasOS\SetupOptions\browser`, when the value exists.
    pub browser: Option<String>,
    pub edge: Option<bool>,
    /// App families installed for an account (`Name_PublisherId`): for the
    /// worker, every account in the PC's profile list, not a package left
    /// only staged or registered to SYSTEM; here, this account's own.
    pub appx: Vec<String>,
    /// Whether the Atlas Toolbox is installed, as the worker reads it: its
    /// installer's record, which Toolbox 0.1.x leaves behind when it is
    /// uninstalled, and its program.
    pub toolbox: Option<bool>,
    /// The Toolbox's program is in Program Files, as Atlas's Toolbox install
    /// checks for it.
    pub toolbox_program: Option<bool>,
    pub core_isolation_off: Option<bool>,
    /// Browsers Atlas offers that are installed, by option name.
    pub browsers: Option<Vec<String>>,
    /// The installing user's Alt+Shift setting (`HKCU\Keyboard Layout\Toggle`,
    /// `Language Hotkey`) as text, whether stored as text or a number.
    pub language_hotkey: Option<String>,
    /// How many keyboard layouts the installing user has (`Keyboard Layout\Preload`).
    pub keyboard_layouts: Option<usize>,
    /// Whether the Microsoft Defender service (`WinDefend`) is registered.
    pub defender: Option<bool>,
}

impl Facts {
    /// Whether Atlas's NoDefender servicing package is installed. Windows
    /// counts it only once the restart that installs it is done.
    pub fn defender_package_installed(&self) -> bool {
        self.packages.iter().any(|package| package.starts_with("Z-Atlas-NoDefender-Package"))
    }

    /// Whether Snipping Tool is gone from the apps read. Windows always has
    /// apps, so an empty list means they couldn't be listed.
    pub fn snipping_tool_removed(&self) -> Option<bool> {
        let snipping = |family: &String| family.to_ascii_lowercase().starts_with("microsoft.screensketch_");
        (!self.appx.is_empty()).then(|| !self.appx.iter().any(snipping))
    }

    /// The facts of an Atlas before 0.6, with each record its old Toolbox
    /// (0.1.x) may have written read for what it means. That Toolbox numbered
    /// Mitigations 0 off, 1 all on and 2 Windows' default, unlike Atlas, wrote
    /// 2 by itself when it opened without a record, and never changed the
    /// PC's mitigations. Atlas 0.5's launchers, which did, leave their file
    /// name beside the record, so that name decides, and a record without one
    /// shows nothing. Only an Atlas before 0.6 is read this way: a record a
    /// later one wrote has no file name to go by. The update's
    /// `Repair-AtlasToolboxRecord` applies the same rule before it reads the
    /// records; toolbox-records.json keeps the two in step.
    pub fn before_0_6(mut self) -> Facts {
        if self.toggles.contains_key(MITIGATIONS) {
            match self.launchers.get(MITIGATIONS).map(|file| mitigations_launcher_state(file)) {
                Some(Some(state)) => {
                    self.toggles.insert(MITIGATIONS.to_owned(), state);
                }
                // A launcher this rule doesn't know, or a path that names no
                // file, leaves the record as it is.
                Some(None) => {}
                None => {
                    self.toggles.remove(MITIGATIONS);
                }
            }
        }
        self
    }
}

const MITIGATIONS: &str = "Mitigations";

/// Atlas 0.5's Mitigations launchers, each with the state it applied and
/// recorded.
const MITIGATIONS_LAUNCHERS: [(&str, u32); 3] = [
    ("Disable All Mitigations.cmd", 0),
    ("Set Windows Default Mitigations.cmd", 1),
    ("Enable All Mitigations.cmd", 2),
];

/// The Mitigations state Atlas 0.5's launcher `file` applied and recorded.
fn mitigations_launcher_state(file: &str) -> Option<u32> {
    MITIGATIONS_LAUNCHERS
        .into_iter()
        .find(|(launcher, _)| file.eq_ignore_ascii_case(launcher))
        .map(|(_, state)| state)
}

/// The install choices the PC can show, each with the options it covers.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Group {
    Defender,
    Mitigations,
    AutoUpdates,
    Hibernation,
    PowerSaving,
    Edge,
    SnippingTool,
    CoreIsolation,
    Toolbox,
    Browser,
    Keyboard,
}

impl Group {
    /// Whether `option` belongs to this choice, so the PC showing the choice
    /// replaces it.
    fn covers(self, option: &str) -> bool {
        match self {
            Group::Defender => matches!(option, "defender-enable" | "defender-disable"),
            Group::Mitigations => matches!(option, "mitigations-disable" | "mitigations-default"),
            Group::AutoUpdates => matches!(option, "auto-updates-disable" | "auto-updates-default"),
            Group::Hibernation => option == "disable-hibernation",
            Group::PowerSaving => option == "disable-power-saving",
            Group::Edge => option == "uninstall-edge",
            Group::SnippingTool => option == "remove-snipping-tool",
            Group::CoreIsolation => option == "disable-core-isolation",
            Group::Toolbox => option == "install-toolbox",
            Group::Browser => option == "install-another-browser" || option.starts_with("browser-"),
            Group::Keyboard => {
                matches!(option, "keyboard-shortcuts" | "keyboard-selector" | "keyboard-single")
            }
        }
    }
}

/// What the PC shows, choice by choice, in the worker's order: the options
/// its evidence gives, or none when it shows the choice cleared. A choice
/// nothing shows is left out. `base`, the options recorded, names the browser
/// to look for and gives the keyboard choice the detail its evidence lacks.
/// `legacy` reads an Atlas without a state document, whose browser record
/// means what Atlas 0.5.0 meant by it.
fn evidence(facts: &Facts, base: &[String], legacy: bool) -> Vec<(Group, Vec<&'static str>)> {
    let mut shown: Vec<(Group, Vec<&'static str>)> = Vec::new();
    let mut shows = |group: Group, options: &[&'static str]| shown.push((group, options.to_vec()));
    let record = |name: &str| facts.toggles.get(name).copied();

    // Only Atlas's NoDefender package removes Defender, and any other Atlas
    // package or the Defender service shows it kept. Defender missing without
    // that package shows nothing: Atlas didn't remove it, so it isn't taken
    // for a choice to remove it.
    if facts.defender_package_installed() {
        shows(Group::Defender, &["defender-disable"]);
    } else if !facts.packages.is_empty() || facts.defender == Some(true) {
        shows(Group::Defender, &["defender-enable"]);
    }
    if let Some(state) = record(MITIGATIONS) {
        shows(Group::Mitigations, &[if state == 0 { "mitigations-disable" } else { "mitigations-default" }]);
    }
    if let Some(state) = record("AutomaticUpdates") {
        shows(
            Group::AutoUpdates,
            &[if state == 0 { "auto-updates-disable" } else { "auto-updates-default" }],
        );
    }
    let ticked = |on: bool, option: &'static str| if on { vec![option] } else { Vec::new() };
    if let Some(state) = record("Hibernation") {
        shows(Group::Hibernation, &ticked(state == 0, "disable-hibernation"));
    }
    if let Some(state) = record("PowerSaving") {
        shows(Group::PowerSaving, &ticked(state == 0, "disable-power-saving"));
    }
    if let Some(edge) = facts.edge {
        shows(Group::Edge, &ticked(!edge, "uninstall-edge"));
    }
    if let Some(removed) = facts.snipping_tool_removed() {
        shows(Group::SnippingTool, &ticked(removed, "remove-snipping-tool"));
    }
    if let Some(off) = facts.core_isolation_off {
        shows(Group::CoreIsolation, &ticked(off, "disable-core-isolation"));
    }
    // A Toolbox chosen but not there yet is one the install puts on.
    if facts.toolbox == Some(true) {
        shows(Group::Toolbox, &["install-toolbox"]);
    }

    // The taskbar pin record names the browser a new installation chose, and
    // updates leave it as it is, so an installed browser chosen since comes
    // first. Atlas 0.5.0 recorded LibreWolf as an empty name, so on its
    // installs the one browser installed then decides. Atlas 0.6 records no
    // browser that way, and one someone installed themselves isn't a choice.
    // The record outlives a browser someone uninstalled, so the one it names
    // counts only while it is there, once the browsers have been read.
    let installed = facts.browsers.as_deref().unwrap_or_default();
    let chosen = base.iter().find(|option| option.starts_with("browser-")).and_then(|chosen| {
        BROWSERS
            .iter()
            .copied()
            .find(|browser| browser == chosen && installed.iter().any(|name| name == browser))
    });
    let named = match facts.browser.as_deref() {
        Some("Brave") => Some("browser-brave"),
        Some("Firefox") => Some("browser-firefox"),
        Some("Google Chrome") => Some("browser-chrome"),
        Some("LibreWolf") => Some("browser-librewolf"),
        Some(_) if legacy && installed.len() == 1 => {
            BROWSERS.iter().copied().find(|browser| *browser == installed[0])
        }
        _ => None,
    };
    let browser = chosen.or_else(|| {
        named.filter(|named| facts.browsers.is_none() || installed.iter().any(|name| name == named))
    });
    if let Some(browser) = browser {
        shows(Group::Browser, &["install-another-browser", browser]);
    }

    // A KeyboardShortcuts record says whether the shortcuts are on. Without
    // one, Alt+Shift does: Atlas 0.5.0 turned it and Ctrl+Shift off for every
    // user (3), and someone who turned them back on in Settings has 1 or 2
    // again. Off is all either shows, so a recorded language selector or
    // single layout stays; without a layout count it is the language
    // selector, as for a KeyboardShortcuts record of 0 set between installs.
    let off = match record("KeyboardShortcuts") {
        Some(state @ (0 | 1)) => Some(state == 0),
        _ => match facts.language_hotkey.as_deref() {
            Some("3") => Some(true),
            Some(hotkey) if !hotkey.is_empty() => Some(false),
            _ => None,
        },
    };
    match off {
        Some(false) => shows(Group::Keyboard, &["keyboard-shortcuts"]),
        Some(true) => {
            let kept = base.iter().find_map(|option| match option.as_str() {
                "keyboard-selector" => Some("keyboard-selector"),
                "keyboard-single" => Some("keyboard-single"),
                _ => None,
            });
            let several = facts.keyboard_layouts.is_none_or(|layouts| layouts > 1);
            let keyboard = kept.unwrap_or(if several { "keyboard-selector" } else { "keyboard-single" });
            shows(Group::Keyboard, &[keyboard]);
        }
        None => {}
    }
    shown
}

/// The browsers Atlas offers, by option name.
const BROWSERS: [&str; 4] = ["browser-brave", "browser-firefox", "browser-chrome", "browser-librewolf"];

/// The install options `facts` show on their own, which for an Atlas without
/// a state document are its choices.
pub fn observed_options(facts: &Facts) -> Vec<String> {
    evidence(facts, &[], true).into_iter().flat_map(|(_, options)| options).map(str::to_owned).collect()
}

/// The install choices this PC has: choice by choice, what it shows replaces
/// the options `base` recorded, and `base` keeps every choice the PC doesn't
/// show, install-eclean and any added later among them. The options `base`
/// keeps come first, in its order. The worker's `Merge-AtlasObservedOption`
/// applies the same rules before an install, and after it to record what it
/// did; merged-options.json keeps the two in step.
pub fn kept_options(base: &[String], facts: &Facts) -> Vec<String> {
    let evidence = evidence(facts, base, false);
    let mut kept: Vec<String> = Vec::new();
    for option in base.iter().filter(|option| !option.is_empty()) {
        if !evidence.iter().any(|(group, _)| group.covers(option)) && !kept.contains(option) {
            kept.push(option.clone());
        }
    }
    for option in evidence.into_iter().flat_map(|(_, options)| options) {
        if !kept.iter().any(|kept| kept == option) {
            kept.push(option.to_owned());
        }
    }
    kept
}

/// The options a Windows move's record kept for an Atlas before 0.6, as a
/// base for facts [`Facts::before_0_6`] reads. The record read the toggle
/// records as they were, so its Mitigations choice may come from one only the
/// old Toolbox wrote, which an update's Capture also removes: only what the
/// PC shows now decides it, and without that it is asked.
pub fn carried_before_0_6(options: &[String]) -> Vec<String> {
    options.iter().filter(|option| !Group::Mitigations.covers(option)).cloned().collect()
}

/// The options a Windows move's record kept for an Atlas before 0.6, for the
/// Rebase that puts them back on a Windows that lost its records: a
/// Mitigations choice among them comes from the `mitigations` record it
/// kept, by state and launcher file, read as [`Facts::before_0_6`] reads one,
/// in its place. A record an update wrote before that rule took the choice
/// from the old Toolbox's own record, which never changed the PC; without a
/// launcher's record it is asked.
pub fn rebase_options_before_0_6(
    options: &[String],
    mitigations: Option<(u32, Option<&str>)>,
) -> Vec<String> {
    let mut facts = Facts::default();
    if let Some((state, launcher)) = mitigations {
        facts.toggles.insert(MITIGATIONS.to_owned(), state);
        if let Some(launcher) = launcher {
            facts.launchers.insert(MITIGATIONS.to_owned(), launcher_file(launcher));
        }
    }
    let mut shown = observed_options(&facts.before_0_6()).into_iter();
    let mut kept = Vec::new();
    for option in options {
        if !Group::Mitigations.covers(option) {
            kept.push(option.clone());
        } else if let Some(record) = shown.next() {
            kept.push(record);
        }
    }
    kept
}

/// What this PC shows. Each fact is read on its own, and one that can't be
/// read is left unread.
pub fn read() -> Facts {
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
    let mut launchers = HashMap::new();
    let mut toggles: HashMap<String, u32> = subkeys(LOCAL_MACHINE, r"SOFTWARE\AtlasOS\Services")
        .into_iter()
        .filter_map(|name| {
            let path = format!(r"SOFTWARE\AtlasOS\Services\{name}");
            let state = dword(&path, "state")?;
            // The launcher's file name, as data: it is never opened or run.
            let launcher = LOCAL_MACHINE
                .open(&path)
                .and_then(|key| key.get_string("path"))
                .ok()
                .map(|path| launcher_file(&path));
            let state = if name == "AutomaticUpdates" {
                automatic_updates_record(state, launcher.as_deref(), read_automatic_updates_policy)?
            } else {
                state
            };
            if let Some(launcher) = launcher {
                launchers.insert(name.clone(), launcher);
            }
            Some((name, state))
        })
        .collect();
    let active_scheme = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes")
        .and_then(|key| key.get_string("ActivePowerScheme"))
        .ok();
    preserve_active_atlas_plan(&mut toggles, active_scheme.as_deref());
    // The installing user's apps: an unelevated read can't list every user's.
    // Windows lists a package here while it is registered to this account, so
    // one left only staged or registered to another account isn't counted.
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
    let toolbox_program = exists(&program_files.join(r"Atlas Toolbox\AtlasToolbox.exe"));
    // Atlas 0.5.0 stored the hotkeys as numbers; Windows and Settings store text.
    let language_hotkey = CURRENT_USER.open(r"Keyboard Layout\Toggle").ok().and_then(|key| {
        let value = key.get_value("Language Hotkey").ok()?;
        match value.ty() {
            Type::U32 => u32::try_from(value).ok().map(|number| number.to_string()),
            Type::String => String::try_from(value).ok().map(|text| text.trim().to_owned()),
            _ => None,
        }
    });
    // Without the key there are no layouts to count, as the worker reads it.
    let keyboard_layouts = CURRENT_USER
        .open(r"Keyboard Layout\Preload")
        .and_then(|key| key.values().map(Iterator::count))
        .unwrap_or_default();
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
        launchers,
        browser: LOCAL_MACHINE
            .open(r"SOFTWARE\AtlasOS\SetupOptions")
            .and_then(|key| key.get_string("browser"))
            .ok(),
        edge: Some(exists(&x86.join(r"Microsoft\Edge\Application\msedge.exe"))),
        appx,
        toolbox: toolbox_installed(
            registry::key_present(LOCAL_MACHINE, r"SOFTWARE\AtlasOS\Toolbox").ok(),
            toolbox_program,
        ),
        toolbox_program: Some(toolbox_program),
        core_isolation_off: Some(core_isolation_off(
            dword(r"SYSTEM\CurrentControlSet\Control\DeviceGuard", "EnableVirtualizationBasedSecurity"),
            dword(
                r"SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity",
                "Enabled",
            ),
        )),
        browsers: Some(browsers),
        language_hotkey,
        keyboard_layouts: Some(keyboard_layouts),
        defender: registry::key_present(LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\WinDefend").ok(),
    }
}

/// A running Atlas plan proves the power-saving choice even when an earlier
/// installer left a conflicting record. Other plans and unreadable values do
/// not establish a choice, so retain their records as they are.
fn preserve_active_atlas_plan(toggles: &mut HashMap<String, u32>, active: Option<&str>) {
    if active.is_some_and(|guid| guid.eq_ignore_ascii_case("11111111-1111-1111-1111-111111111111")) {
        toggles.insert("PowerSaving".to_owned(), 0);
    }
}

/// Whether the Atlas Toolbox is installed, from its installer's record and
/// whether its program is there. Toolbox 0.1.x leaves the record behind when
/// it is uninstalled, so it counts only beside the program, as the worker's
/// `Get-AtlasTransitionMachineFact` reads it.
fn toolbox_installed(record: Option<bool>, program: bool) -> Option<bool> {
    record.map(|record| record && program)
}

/// The file name a record's `path` ends with, split as the update's
/// `Repair-AtlasToolboxRecord` splits it: empty when the path names no file,
/// which is still a path, so no Toolbox write.
fn launcher_file(path: &str) -> String {
    path.rsplit(['\\', '/']).next().unwrap_or_default().to_owned()
}

fn is_legacy_cpu_menu_launcher(path: &str) -> bool {
    let file = path.rsplit(['\\', '/']).next().unwrap_or_default();
    [
        "Add Idle Toggle in Desktop Context Menu.cmd",
        "Remove Idle Toggle in Desktop Context Menu (default).cmd",
    ]
    .iter()
    .any(|name| file.eq_ignore_ascii_case(name))
}

// Two old CPU menu launchers overwrote AutomaticUpdates. Only a recognized
// record is repaired, using the live update policy rather than its wrong value;
// a policy that can't be read leaves the choice out. The policy is read only
// for such a record.
fn automatic_updates_record(
    state: u32,
    launcher: Option<&str>,
    policy: impl FnOnce() -> anyhow::Result<Option<u32>>,
) -> Option<u32> {
    if state == 1 && launcher.is_some_and(is_legacy_cpu_menu_launcher) {
        automatic_updates_from_policy(policy().ok()?)
    } else {
        Some(state)
    }
}

fn automatic_updates_from_policy(value: Option<u32>) -> Option<u32> {
    match value {
        Some(2) => Some(0),
        None | Some(3..=5) => Some(1),
        _ => None,
    }
}

fn read_automatic_updates_policy() -> anyhow::Result<Option<u32>> {
    let key = match LOCAL_MACHINE.open(r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU") {
        Ok(key) => key,
        Err(error) if error.code().0 == NOT_FOUND => return Ok(None),
        Err(error) => return Err(error.into()),
    };
    match key.get_value("AUOptions") {
        Ok(value) if value.ty() == Type::U32 => u32::try_from(value).map(Some).map_err(Into::into),
        Ok(_) => anyhow::bail!("AUOptions is not REG_DWORD"),
        Err(error) if error.code().0 == NOT_FOUND => Ok(None),
        Err(error) => Err(error.into()),
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

    #[test]
    fn an_active_atlas_plan_survives_a_stale_power_saving_record() {
        for case in shared_cases("power-saving-records.json") {
            let mut toggles = HashMap::new();
            if let Some(state) = case["record"].as_u64() {
                toggles.insert("PowerSaving".to_owned(), state as u32);
            }
            preserve_active_atlas_plan(&mut toggles, case["active"].as_str());
            assert_eq!(
                toggles.get("PowerSaving").copied(),
                case["expected"].as_u64().map(|state| state as u32),
                "{}",
                case["name"]
            );
            let options = observed_options(&Facts { toggles, ..Facts::default() });
            assert_eq!(options.iter().any(|option| option == "disable-power-saving"), case["expected"] == 0);
        }
    }

    /// The AutomaticUpdates records and update policies Atlas 0.5.0 and
    /// Windows leave, shared with the worker's Pester cases. `record` is the
    /// state read, or null when the choice is left out.
    #[test]
    fn a_cpu_menu_record_cannot_enable_automatic_updates() {
        let path = concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../tests/fixtures/windows-transition/legacy-automatic-updates.json"
        );
        let cases: Vec<serde_json::Value> =
            serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
        assert!(!cases.is_empty());
        for case in cases {
            let policy = || -> anyhow::Result<Option<u32>> {
                match &case["policy"] {
                    serde_json::Value::Null => Ok(None),
                    policy if policy["kind"] == "DWord" => Ok(Some(policy["data"].as_u64().unwrap() as u32)),
                    // What read_automatic_updates_policy answers for any other kind.
                    _ => anyhow::bail!("AUOptions is not REG_DWORD"),
                }
            };
            assert_eq!(
                automatic_updates_record(
                    case["state"].as_u64().unwrap() as u32,
                    case["launcher"].as_str(),
                    policy
                ),
                case["record"].as_u64().map(|state| state as u32),
                "{}",
                case["name"]
            );
        }
        let unread = || -> anyhow::Result<Option<u32>> { panic!("only a CPU menu record reads the policy") };
        assert_eq!(
            automatic_updates_record(0, Some("Add Idle Toggle in Desktop Context Menu.cmd"), unread),
            Some(0)
        );
        assert_eq!(automatic_updates_record(1, None, unread), Some(1));
    }

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

    fn shared_cases(file: &str) -> Vec<serde_json::Value> {
        let path = format!("{}/../tests/fixtures/windows-transition/{file}", env!("CARGO_MANIFEST_DIR"));
        let cases: Vec<serde_json::Value> =
            serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
        assert!(!cases.is_empty(), "{file}");
        cases
    }

    fn strings(value: &serde_json::Value) -> Vec<String> {
        value
            .as_array()
            .map(|items| items.iter().filter_map(|item| item.as_str().map(str::to_owned)).collect())
            .unwrap_or_default()
    }

    /// A shared case's facts, where a fact left out or null wasn't read. The
    /// app reads servicing packages at CurrentState 112 only, so the NoDefender
    /// package installed is one of them, and one waiting for a restart
    /// doesn't count before an install.
    fn fixture_facts(case: &serde_json::Value) -> Facts {
        let facts = &case["facts"];
        let mut packages = strings(&case["packages"]);
        if facts["defenderPackage"] == "Installed" {
            packages.push("Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0".into());
        }
        Facts {
            packages,
            toggles: facts["toggles"]
                .as_array()
                .map(|records| {
                    records
                        .iter()
                        .map(|record| {
                            (
                                record["name"].as_str().unwrap().to_owned(),
                                record["state"].as_u64().unwrap() as u32,
                            )
                        })
                        .collect()
                })
                .unwrap_or_default(),
            launchers: HashMap::new(),
            browser: facts["browser"].as_str().map(str::to_owned),
            edge: facts["edge"].as_bool(),
            appx: strings(&facts["appx"]),
            // A case may give the Toolbox installer's record and its program instead.
            toolbox: match facts["toolboxRecord"].as_bool() {
                Some(record) => toolbox_installed(Some(record), facts["toolboxProgram"] == true),
                None => facts["toolbox"].as_bool(),
            },
            toolbox_program: facts["toolboxProgram"].as_bool(),
            core_isolation_off: facts["coreIsolationOff"].as_bool(),
            browsers: facts["browsers"].as_array().map(|_| strings(&facts["browsers"])),
            language_hotkey: facts["languageHotkey"].as_str().map(str::to_owned),
            keyboard_layouts: facts["keyboardLayouts"].as_u64().map(|layouts| layouts as usize),
            defender: facts["defender"].as_bool(),
        }
    }

    /// The worker reads the same cases (Pester), so the app and the record of
    /// a move agree on what an Atlas install chose. Merged over nothing, as
    /// for an install with a record that names none, the options are the
    /// same, except that an empty browser name, Atlas 0.5.0's LibreWolf,
    /// names no browser there.
    #[test]
    fn the_options_match_the_worker_s_for_every_shared_case() {
        for case in shared_cases("observed-options.json") {
            let mut facts = fixture_facts(&case);
            // The worker's case reads a missing layout count as none.
            facts.keyboard_layouts = Some(facts.keyboard_layouts.unwrap_or_default());
            let expected = strings(&case["options"]);
            assert_eq!(observed_options(&facts), expected, "{}", case["name"]);
            let mut over_nothing = expected.clone();
            if case["facts"]["browser"] == "" {
                over_nothing
                    .retain(|option| option != "install-another-browser" && !option.starts_with("browser-"));
            }
            assert_eq!(kept_options(&[], &facts), over_nothing, "{}, merged over nothing", case["name"]);
        }
    }

    /// The worker merges the same cases (Pester) before and after an
    /// install; Atlas Manager, which reads the PC only before one, shares the
    /// first. The options are compared as sets, and none comes twice.
    #[test]
    fn what_the_pc_shows_wins_over_the_record_as_the_worker_merges_it() {
        let cases: Vec<_> = shared_cases("merged-options.json")
            .into_iter()
            .filter(|case| case["afterInstall"] == false)
            .collect();
        assert!(cases.len() >= 10, "{} cases before an install", cases.len());
        for case in cases {
            // Every account's app registrations are the worker's reading after
            // an install; Atlas Manager lists only the apps of its own account.
            assert!(case["facts"].get("appxPackages").is_none(), "{}", case["name"]);
            let merged = kept_options(&strings(&case["base"]), &fixture_facts(&case));
            let mut sorted = merged.clone();
            sorted.sort();
            sorted.dedup();
            assert_eq!(sorted.len(), merged.len(), "{}: {merged:?}", case["name"]);
            let mut expected = strings(&case["options"]);
            expected.sort();
            assert_eq!(sorted, expected, "{}", case["name"]);
        }
    }

    /// What `base` keeps comes first, in its order, then what the PC shows.
    #[test]
    fn the_choices_the_pc_does_not_show_keep_their_place() {
        let base: Vec<String> = ["defender-enable", "a-later-choice", "install-eclean", "a-later-choice"]
            .map(str::to_owned)
            .to_vec();
        let facts = Facts {
            packages: vec!["Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0".into()],
            ..Facts::default()
        };
        assert_eq!(kept_options(&base, &facts), ["a-later-choice", "install-eclean", "defender-disable"]);
        assert_eq!(
            kept_options(&base, &Facts::default()),
            ["defender-enable", "a-later-choice", "install-eclean"]
        );
    }

    /// On a PC from before 0.6, a Mitigations record means what the launcher
    /// named beside it applied, whatever the old Toolbox left in it since; one
    /// the Toolbox wrote on its own, with no name, shows nothing.
    #[test]
    fn a_mitigations_record_from_before_0_6_is_read_by_the_launcher_that_wrote_it() {
        let facts = |state: u32, launcher: Option<&str>| Facts {
            toggles: [(MITIGATIONS.to_owned(), state), ("AutomaticUpdates".to_owned(), 0)].into(),
            launchers: launcher
                .map(|file| [(MITIGATIONS.to_owned(), file.to_owned())].into())
                .unwrap_or_default(),
            ..Facts::default()
        };
        let mitigations = |facts: Facts| -> Vec<String> {
            observed_options(&facts.before_0_6())
                .into_iter()
                .filter(|o| o.starts_with("mitigations-"))
                .collect()
        };
        for state in 0..=2 {
            // The Toolbox's 2, which it writes by itself, is Windows' default there.
            assert!(mitigations(facts(state, None)).is_empty(), "{state} without a launcher");
            assert_eq!(
                mitigations(facts(state, Some("Disable All Mitigations.cmd"))),
                ["mitigations-disable"]
            );
            assert_eq!(
                mitigations(facts(state, Some("set windows default mitigations.cmd"))),
                ["mitigations-default"]
            );
            let all_on = facts(state, Some("Enable All Mitigations.cmd")).before_0_6();
            assert_eq!(all_on.toggles.get(MITIGATIONS), Some(&2), "{state}");
        }
        // A launcher the rule doesn't know leaves the record as it is, and so
        // does a path that names no file: it is still a path, so no Toolbox write.
        assert_eq!(facts(0, Some("Mitigations.cmd")).before_0_6().toggles.get(MITIGATIONS), Some(&0));
        for path in ["", r"C:\Windows\AtlasDesktop\7. Security\Mitigations\"] {
            assert_eq!(launcher_file(path), "", "{path:?}");
            let record = facts(2, Some(&launcher_file(path))).before_0_6();
            assert_eq!(record.toggles.get(MITIGATIONS), Some(&2), "{path:?}");
        }
        assert_eq!(
            launcher_file(r"C:\Windows\AtlasDesktop\7. Security\Mitigations\Disable All Mitigations.cmd"),
            "Disable All Mitigations.cmd"
        );
        // The rule reads Mitigations alone, and only before 0.6.
        assert_eq!(facts(2, None).before_0_6().toggles.get("AutomaticUpdates"), Some(&0));
        assert_eq!(observed_options(&facts(2, None)), ["mitigations-default", "auto-updates-disable"]);
    }

    /// The update reads the same records the same way before it reads the
    /// choices (`Repair-AtlasToolboxRecord`, whose Pester cases read
    /// toolbox-records.json too): each case is one record, by its key, state
    /// and launcher path, on an update from its version, and the record left,
    /// or none. The app reads only the records that show a choice.
    #[test]
    fn the_toolbox_records_read_as_the_update_reads_them() {
        const CHOICE_RECORDS: [&str; 5] =
            [MITIGATIONS, "AutomaticUpdates", "Hibernation", "PowerSaving", "KeyboardShortcuts"];
        let before_0_6 = |version: &str| {
            let mut parts = version.split('.').map(|part| part.parse::<u32>().expect(version));
            (parts.next().unwrap(), parts.next().unwrap()) < (0, 6)
        };
        let cases = shared_cases("toolbox-records.json");
        let mut read = 0;
        for case in cases.iter().filter(|case| CHOICE_RECORDS.contains(&case["key"].as_str().unwrap())) {
            let key = case["key"].as_str().unwrap().to_owned();
            let facts = Facts {
                toggles: [(key.clone(), case["state"].as_u64().unwrap() as u32)].into(),
                launchers: case["path"]
                    .as_str()
                    .map(|path| [(key.clone(), launcher_file(path))].into())
                    .unwrap_or_default(),
                ..Facts::default()
            };
            let facts =
                if before_0_6(case["version"].as_str().unwrap()) { facts.before_0_6() } else { facts };
            let left: HashMap<String, u32> = match &case["result"] {
                serde_json::Value::Null => HashMap::new(),
                result => {
                    [(result["key"].as_str().unwrap().to_owned(), result["state"].as_u64().unwrap() as u32)]
                        .into()
                }
            };
            assert_eq!(facts.toggles, left, "{}", case["name"]);
            read += 1;
        }
        assert!(read >= 10, "{read} cases read");
        // Every launcher the rule knows has a case, so the cases pin the table.
        for (launcher, _) in MITIGATIONS_LAUNCHERS {
            assert!(
                cases.iter().any(|case| case["key"] == MITIGATIONS
                    && case["path"].as_str().is_some_and(|path| launcher_file(path) == launcher)),
                "{launcher}"
            );
        }
    }

    /// The installer's record an uninstalled Toolbox 0.1.x leaves doesn't show
    /// a Toolbox on its own, so keeping the choices doesn't put it back.
    #[test]
    fn the_toolbox_counts_only_with_its_program() {
        assert_eq!(toolbox_installed(Some(true), true), Some(true));
        assert_eq!(toolbox_installed(Some(true), false), Some(false));
        assert_eq!(toolbox_installed(Some(false), true), Some(false));
        assert_eq!(toolbox_installed(None, true), None, "a record that couldn't be read");
        let uninstalled = Facts { toolbox: toolbox_installed(Some(true), false), ..Facts::default() };
        assert!(!observed_options(&uninstalled).iter().any(|option| option == "install-toolbox"));
    }

    /// The Mitigations choice a Windows move's record carried from an Atlas
    /// before 0.6 never stands on its own; the rest of it does.
    #[test]
    fn a_carried_mitigations_choice_from_before_0_6_is_left_to_the_pc() {
        let carried: Vec<String> =
            ["defender-disable", "mitigations-disable", "auto-updates-disable"].map(str::to_owned).to_vec();
        assert_eq!(carried_before_0_6(&carried), ["defender-disable", "auto-updates-disable"]);
        let launcher = Facts {
            toggles: [(MITIGATIONS.to_owned(), 2)].into(),
            launchers: [(MITIGATIONS.to_owned(), "Enable All Mitigations.cmd".to_owned())].into(),
            ..Facts::default()
        };
        assert_eq!(
            kept_options(&carried_before_0_6(&carried), &launcher.before_0_6()),
            ["defender-disable", "auto-updates-disable", "mitigations-default"],
            "what the PC shows"
        );
    }

    /// A Rebase from before 0.6 takes the Mitigations choice its move's
    /// record carried only from the record a launcher left, in its place,
    /// and never adds one the record didn't carry.
    #[test]
    fn a_rebase_takes_a_carried_mitigations_choice_only_from_a_launcher_s_record() {
        let owned = |options: &[&str]| -> Vec<String> { options.iter().map(|o| (*o).to_owned()).collect() };
        let carried = owned(&["defender-disable", "mitigations-disable", "auto-updates-disable"]);
        let asked = owned(&["defender-disable", "auto-updates-disable"]);
        let rebase = |record| rebase_options_before_0_6(&carried, record);
        assert_eq!(rebase(None), asked, "no record kept");
        assert_eq!(rebase(Some((0, None))), asked, "the old Toolbox's own record");
        assert_eq!(rebase(Some((0, Some("Disable All Mitigations.cmd")))), carried);
        assert_eq!(
            rebase(Some((0, Some("Set Windows Default Mitigations.cmd")))),
            owned(&["defender-disable", "mitigations-default", "auto-updates-disable"]),
            "what the launcher applied"
        );
        let none = owned(&["defender-disable"]);
        assert_eq!(rebase_options_before_0_6(&none, Some((0, Some("Disable All Mitigations.cmd")))), none);
    }

    /// An Alt+Shift value that is there but empty says nothing about the
    /// shortcuts, as the worker reads it as text.
    #[test]
    fn an_empty_language_hotkey_shows_no_keyboard_choice() {
        let facts =
            Facts { language_hotkey: Some(String::new()), keyboard_layouts: Some(2), ..Facts::default() };
        assert!(observed_options(&facts).is_empty());
        let single = vec!["keyboard-single".to_owned()];
        assert_eq!(kept_options(&single, &facts), single);
        let on = Facts { language_hotkey: Some("1".into()), ..facts };
        assert_eq!(observed_options(&on), ["keyboard-shortcuts"]);
    }
}
