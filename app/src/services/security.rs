//! Live view of the four Windows Security switches that must be off before
//! Atlas installs, read from the registry values behind the "Virus & threat
//! protection settings" page. AME Wizard reads the same values, so the app
//! and AME Wizard agree on whether a PC is ready.

use windows_registry::{Key, LOCAL_MACHINE};

const DEFENDER: &str = r"SOFTWARE\Microsoft\Windows Defender";
/// Atlas removes the Defender service together with Defender; a PC where an
/// earlier install did so has no switches to turn off.
const WINDEFEND_SERVICE: &str = r"SYSTEM\CurrentControlSet\Services\WinDefend";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Switch {
    Off,
    On,
    /// The registry could not be read; the app must not claim either state.
    Unknown,
}

impl Switch {
    pub fn is_off(self) -> bool {
        matches!(self, Switch::Off)
    }
}

/// Named exactly as Windows Security names them, so the two lists read the same.
#[allow(clippy::enum_variant_names)]
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Protection {
    TamperProtection,
    RealTimeProtection,
    CloudDelivered,
    SampleSubmission,
}

impl Protection {
    /// Order matches the Windows Security page, so the two lists line up visually.
    pub const ALL: [Protection; 4] = [
        Protection::RealTimeProtection,
        Protection::CloudDelivered,
        Protection::SampleSubmission,
        Protection::TamperProtection,
    ];
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SecurityStatus {
    pub tamper_protection: Switch,
    pub real_time_protection: Switch,
    pub cloud_delivered: Switch,
    pub sample_submission: Switch,
    /// False only when the Defender service is known to be gone (an earlier
    /// Atlas install removed it); an unreadable service key counts as present.
    pub defender_present: bool,
}

impl Default for SecurityStatus {
    fn default() -> Self {
        Self {
            tamper_protection: Switch::Unknown,
            real_time_protection: Switch::Unknown,
            cloud_delivered: Switch::Unknown,
            sample_submission: Switch::Unknown,
            defender_present: true,
        }
    }
}

/// How many switches are in each state; on and unreadable are never conflated.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct SwitchCounts {
    pub off: usize,
    pub on: usize,
    pub unknown: usize,
}

impl SecurityStatus {
    pub fn get(&self, protection: Protection) -> Switch {
        match protection {
            Protection::TamperProtection => self.tamper_protection,
            Protection::RealTimeProtection => self.real_time_protection,
            Protection::CloudDelivered => self.cloud_delivered,
            Protection::SampleSubmission => self.sample_submission,
        }
    }

    pub fn all_off(&self) -> bool {
        Protection::ALL.iter().all(|p| self.get(*p).is_off())
    }

    /// Every switch that could be read is off, and at least one could not be.
    pub fn off_where_readable(&self) -> bool {
        let counts = self.counts();
        counts.on == 0 && counts.unknown > 0
    }

    /// Whether any switch is known to be off (protection was reduced).
    pub fn any_off(&self) -> bool {
        Protection::ALL.iter().any(|p| self.get(*p).is_off())
    }

    /// The switches in `state`, in Windows Security's order.
    pub fn switches(&self, state: Switch) -> Vec<Protection> {
        Protection::ALL.into_iter().filter(|p| self.get(*p) == state).collect()
    }

    pub fn counts(&self) -> SwitchCounts {
        let mut counts = SwitchCounts::default();
        for protection in Protection::ALL {
            match self.get(protection) {
                Switch::Off => counts.off += 1,
                Switch::On => counts.on += 1,
                Switch::Unknown => counts.unknown += 1,
            }
        }
        counts
    }

    /// Reads every switch. Cheap enough to poll once a second.
    pub fn read() -> Self {
        if let Some(status) = review_status() {
            return status;
        }
        let defender_present =
            !matches!(super::registry::key_present(LOCAL_MACHINE, WINDEFEND_SERVICE), Ok(false));
        let root = LOCAL_MACHINE.open(DEFENDER).ok();
        let open = |name: &str| root.as_ref().and_then(|root| root.open(name).ok());
        let features = open("Features");
        let real_time = open("Real-Time Protection");
        let spynet = open("SpyNet");
        let value = |key: &Option<Key>, name: &str| key.as_ref().map(|key| dword(key, name));
        Self::from_values(
            value(&features, "TamperProtection"),
            value(&real_time, "DisableRealtimeMonitoring"),
            value(&spynet, "SpyNetReporting"),
            value(&spynet, "SubmitSamplesConsent"),
            defender_present,
        )
    }

    /// The switches from their registry values, each `None` when its key
    /// can't be opened and `Some(None)` when the value isn't a DWORD, or a
    /// QWORD that fits in 32 bits. The front door's check uses the same rule,
    /// and a shared fixture keeps the two in step.
    fn from_values(
        tamper: Option<Option<u32>>,
        real_time: Option<Option<u32>>,
        cloud: Option<Option<u32>>,
        samples: Option<Option<u32>>,
        defender_present: bool,
    ) -> Self {
        Self {
            tamper_protection: tamper.flatten().map_or(Switch::Unknown, tamper_protection_switch),
            // 1 = switched off. Absent or unreadable counts as on, which keeps
            // the step blocked.
            real_time_protection: match real_time {
                Some(Some(1)) => Switch::Off,
                Some(_) => Switch::On,
                None => Switch::Unknown,
            },
            // 0 = off, 1 basic, 2 advanced.
            cloud_delivered: cloud
                .flatten()
                .map_or(Switch::Unknown, |value| if value == 0 { Switch::Off } else { Switch::On }),
            sample_submission: samples.flatten().map_or(Switch::Unknown, sample_submission_switch),
            defender_present,
        }
    }
}

/// Debug builds accept `ATLAS_SECURITY_PREVIEW` for design review, so the
/// Windows Security reminders can be checked without changing Windows
/// Security: `on`, `off`, `some-off` (Tamper Protection and Cloud-delivered
/// protection off), `unreadable` or `absent` (Defender removed).
fn review_status() -> Option<SecurityStatus> {
    if !cfg!(debug_assertions) {
        return None;
    }
    let all = |switch| SecurityStatus {
        tamper_protection: switch,
        real_time_protection: switch,
        cloud_delivered: switch,
        sample_submission: switch,
        defender_present: true,
    };
    match std::env::var("ATLAS_SECURITY_PREVIEW").ok()?.as_str() {
        "on" => Some(all(Switch::On)),
        "off" => Some(all(Switch::Off)),
        "some-off" => Some(SecurityStatus {
            tamper_protection: Switch::Off,
            cloud_delivered: Switch::Off,
            ..all(Switch::On)
        }),
        "unreadable" => Some(SecurityStatus { tamper_protection: Switch::Unknown, ..all(Switch::On) }),
        "absent" => Some(SecurityStatus { defender_present: false, ..all(Switch::Unknown) }),
        _ => None,
    }
}

/// A REG_DWORD, or a REG_QWORD that fits in 32 bits, which the front door
/// reads the same way.
fn dword(key: &Key, name: &str) -> Option<u32> {
    key.get_u32(name).ok()
}

/// 0 (always prompt) and 2 (never send) stop automatic submission; 1 and 3
/// send automatically and keep the step blocked.
fn sample_submission_switch(consent: u32) -> Switch {
    match consent {
        0 | 2 => Switch::Off,
        1 | 3 => Switch::On,
        _ => Switch::Unknown,
    }
}

/// 0 and 4 are off, 1 and 5 on; any other value is not claimed either way.
fn tamper_protection_switch(value: u32) -> Switch {
    match value {
        0 | 4 => Switch::Off,
        1 | 5 => Switch::On,
        _ => Switch::Unknown,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tamper_protection_accepts_only_known_off_values() {
        for value in [0, 4] {
            assert_eq!(tamper_protection_switch(value), Switch::Off);
        }
        // Windows 11 25H2 can report 1 while Get-MpComputerStatus confirms On.
        for value in [1, 5] {
            assert_eq!(tamper_protection_switch(value), Switch::On);
        }
        for value in [2, 3, 6, u32::MAX] {
            assert_eq!(tamper_protection_switch(value), Switch::Unknown);
            assert!(!tamper_protection_switch(value).is_off());
        }
    }

    #[test]
    fn sample_submission_distinguishes_automatic_from_prompted_and_never_send() {
        assert_eq!(sample_submission_switch(0), Switch::Off);
        assert_eq!(sample_submission_switch(2), Switch::Off);
        assert_eq!(sample_submission_switch(1), Switch::On);
        assert_eq!(sample_submission_switch(3), Switch::On);
        assert_eq!(sample_submission_switch(4), Switch::Unknown);
        assert_eq!(sample_submission_switch(u32::MAX), Switch::Unknown);
    }

    /// The registry values Windows and privacy tools leave, shared with the
    /// front door's Pester cases. A key the case leaves out is missing, a
    /// value that isn't a number isn't a DWORD, and {"qword": n} is a
    /// REG_QWORD.
    #[test]
    fn the_switches_match_the_front_door_s_for_every_shared_case() {
        let path = concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/front-door/windows-security.json");
        let cases: Vec<serde_json::Value> =
            serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
        assert!(!cases.is_empty());
        for case in cases {
            let value = |key: &str, name: &str| {
                case["registry"].get(key).map(|values| {
                    let raw = &values[name];
                    raw.get("qword").unwrap_or(raw).as_u64().and_then(|number| u32::try_from(number).ok())
                })
            };
            let status = SecurityStatus::from_values(
                value("Features", "TamperProtection"),
                value("Real-Time Protection", "DisableRealtimeMonitoring"),
                value("SpyNet", "SpyNetReporting"),
                value("SpyNet", "SubmitSamplesConsent"),
                true,
            );
            let expected = |name: &str| match case["switches"][name].as_str() {
                Some("off") => Switch::Off,
                Some("on") => Switch::On,
                Some("unreadable") => Switch::Unknown,
                other => panic!("{name}: {other:?}"),
            };
            assert_eq!(
                [
                    status.tamper_protection,
                    status.real_time_protection,
                    status.cloud_delivered,
                    status.sample_submission
                ],
                ["tamperProtection", "realTimeProtection", "cloudDelivered", "sampleSubmission"]
                    .map(expected),
                "{}",
                case["name"]
            );
        }
    }

    /// A REG_DWORD, or a REG_QWORD that fits in 32 bits, is a value, as it is
    /// to the front door.
    #[test]
    fn a_dword_or_a_qword_that_fits_is_read_as_a_switch_value() {
        let test = crate::services::test_support::TestKey::new("security-dword");
        test.key.set_u32("Dword", 1).unwrap();
        test.key.set_u64("Qword", 1).unwrap();
        test.key.set_u64("Large", u64::from(u32::MAX) + 1).unwrap();
        test.key.set_string("Text", "1").unwrap();
        assert_eq!(dword(&test.key, "Dword"), Some(1));
        assert_eq!(dword(&test.key, "Qword"), Some(1));
        assert_eq!(dword(&test.key, "Large"), None);
        assert_eq!(dword(&test.key, "Text"), None);
        assert_eq!(dword(&test.key, "Missing"), None);
    }

    #[test]
    fn unknown_switches_are_never_counted_as_on() {
        let status = SecurityStatus {
            tamper_protection: Switch::Off,
            real_time_protection: Switch::Off,
            cloud_delivered: Switch::Unknown,
            sample_submission: Switch::Unknown,
            defender_present: true,
        };
        assert_eq!(status.counts(), SwitchCounts { off: 2, on: 0, unknown: 2 });
        assert!(!status.all_off());
        assert!(status.off_where_readable());
        assert!(status.any_off());

        let mixed = SecurityStatus { cloud_delivered: Switch::On, ..status };
        assert_eq!(mixed.counts(), SwitchCounts { off: 2, on: 1, unknown: 1 });
        assert!(!mixed.off_where_readable());

        let all_off = SecurityStatus {
            tamper_protection: Switch::Off,
            real_time_protection: Switch::Off,
            cloud_delivered: Switch::Off,
            sample_submission: Switch::Off,
            defender_present: true,
        };
        assert!(all_off.all_off());
        assert!(!SecurityStatus::default().any_off());

        // Listed in Windows Security's order, whatever the state.
        assert_eq!(
            status.switches(Switch::Off),
            [Protection::RealTimeProtection, Protection::TamperProtection]
        );
        assert_eq!(mixed.switches(Switch::Unknown), [Protection::SampleSubmission]);
        assert_eq!(mixed.switches(Switch::On), [Protection::CloudDelivered]);
        assert!(all_off.switches(Switch::On).is_empty());
    }
}
