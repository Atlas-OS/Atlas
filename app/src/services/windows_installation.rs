//! Read-only hints that Windows has already been used. These are advisory:
//! feature upgrades can reset InstallDate, and uninstall registrations do not
//! cover portable apps. Never treat a lack of evidence as proof of a clean PC.

use std::collections::BTreeSet;
use std::time::{SystemTime, UNIX_EPOCH};

use windows_registry::{CURRENT_USER, Key, LOCAL_MACHINE};

const DAY: u64 = 86_400;
/// A week allows time to finish Windows updates and driver setup after a wipe.
const AGE_WARNING_DAYS: u64 = 7;
/// A handful of visible desktop apps is a second, independent hint of prior use.
const APP_WARNING_COUNT: usize = 3;

#[derive(Clone, Debug, Default)]
pub struct Evidence {
    pub age_days: Option<u64>,
    pub desktop_apps: usize,
}

impl Evidence {
    pub fn suggests_prior_use(&self) -> bool {
        self.age_days.is_some_and(|days| days >= AGE_WARNING_DAYS) || self.desktop_apps >= APP_WARNING_COUNT
    }

    pub fn read() -> Self {
        let installed = LOCAL_MACHINE
            .open(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion")
            .and_then(|key| key.get_u64("InstallDate"))
            .ok();
        let now = SystemTime::now().duration_since(UNIX_EPOCH).ok().map(|time| time.as_secs());
        let mut apps = BTreeSet::new();
        for root in [&LOCAL_MACHINE, &CURRENT_USER] {
            for path in [
                r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            ] {
                if let Ok(key) = root.open(path) {
                    collect_apps(&key, &mut apps);
                }
            }
        }
        Self { age_days: age_days(installed, now), desktop_apps: apps.len() }
    }
}

fn age_days(installed: Option<u64>, now: Option<u64>) -> Option<u64> {
    // Missing, zero and future dates are unknown, not "fresh".
    let installed = installed.filter(|date| *date > 0)?;
    now?.checked_sub(installed).map(|seconds| seconds / DAY)
}

fn collect_apps(key: &Key, apps: &mut BTreeSet<String>) {
    let Ok(names) = key.keys() else { return };
    for name in names {
        let Ok(app) = key.open(name) else { continue };
        let Ok(name) = app.get_string("DisplayName") else { continue };
        let name = name.trim().to_lowercase();
        if app.get_u32("SystemComponent").unwrap_or_default() == 1
            || app.get_string("ParentKeyName").is_ok_and(|value| !value.is_empty())
            || app.get_string("ReleaseType").is_ok_and(|value| !value.is_empty())
            || !counts_as_desktop_app(&name)
        {
            continue;
        }
        // Only count visible, uninstallable products. Keep Microsoft desktop
        // products such as Office; excluding the entire publisher hides prior use.
        if app.get_string("UninstallString").is_ok_and(|value| !value.trim().is_empty()) {
            apps.insert(name);
        }
    }
}

fn counts_as_desktop_app(name: &str) -> bool {
    !name.is_empty()
        && ![
            "microsoft edge",
            "microsoft onedrive",
            "microsoft visual c++",
            "microsoft .net",
            "microsoft windows desktop runtime",
            "microsoft asp.net",
            "windows driver package",
            "windows software development kit",
            "nvidia graphics driver",
            "nvidia physx",
            "nvidia hd audio",
            "nvidia frameview",
            "amd chipset",
            "amd software",
            "intel(r) chipset",
            "intel(r) graphics",
            "intel(r) management engine",
            "realtek audio",
            "realtek high definition audio",
        ]
        .iter()
        .any(|prefix| name.starts_with(prefix))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn age_and_apps_are_independent_hints_not_a_clean_install_verdict() {
        for (age_days, desktop_apps, expected) in [
            (Some(6), 2, false),
            (Some(7), 0, true),
            (Some(365), 0, true),
            (Some(0), 3, true),
            (None, 3, true),
            (None, 0, false),
        ] {
            assert_eq!(Evidence { age_days, desktop_apps }.suggests_prior_use(), expected);
        }
        assert_eq!(age_days(Some(DAY), Some(8 * DAY)), Some(7));
        assert_eq!(age_days(Some(0), Some(8 * DAY)), None);
        assert_eq!(age_days(Some(9 * DAY), Some(8 * DAY)), None);
        assert_eq!(age_days(None, Some(8 * DAY)), None);
        assert_eq!(age_days(Some(DAY), None), None);
    }

    #[test]
    fn setup_components_do_not_count_as_desktop_apps_but_office_and_browsers_do() {
        for name in [
            "Microsoft Edge",
            "Microsoft Visual C++ 2022 Redistributable (x64)",
            "NVIDIA Graphics Driver 580.00",
            "Realtek Audio Driver",
            "",
        ] {
            assert!(!counts_as_desktop_app(&name.to_lowercase()), "{name}");
        }
        for name in ["Microsoft 365 Apps for enterprise", "Google Chrome", "Steam", "Discord"] {
            assert!(counts_as_desktop_app(&name.to_lowercase()), "{name}");
        }
    }
}
