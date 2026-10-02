//! What holds Windows Update back on this PC, and the record of what Atlas
//! changed to turn it on for an update. Read only: the update worker
//! (Preparation\WindowsTransition.ps1) makes and undoes every change.

use anyhow::{Context, Result, bail};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use windows_registry::{Key, LOCAL_MACHINE, Type};

use super::registry::NOT_FOUND;

/// Where the worker keeps its record. Users can read it; only administrators
/// and SYSTEM can write it.
const RECORD: &str = r"SOFTWARE\AtlasOS\WindowsTransition";

/// How one setting holds Windows Update back.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum BlockerKind {
    /// Windows Update, its service or its access is turned off.
    Off,
    /// Updates are paused.
    Paused,
    /// Monthly updates are delayed.
    Delayed,
}

/// One kind of blocker this PC has. `owned` says a recorded Atlas choice
/// (a toggle) set it, so the Atlas install turns it back on as chosen.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Blocker {
    pub kind: BlockerKind,
    pub owned: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Rule {
    /// A DWORD other than 0 blocks.
    Nonzero,
    /// A service start type of 4 (disabled) blocks.
    Disabled,
    /// A pause end date still ahead blocks.
    Future,
    /// Counts only while updates are paused.
    Paused,
}

/// The settings the worker may lift, as in its fixed table (the shared
/// fixture keeps the two in step). The pin is not listed: it is retargeted,
/// never lifted. Nor are the update tasks: the worker turns them on with the
/// service, and on their own they hold nothing back.
struct Item {
    id: &'static str,
    kind: BlockerKind,
    path: &'static str,
    name: &'static str,
    rule: Rule,
    owner: Option<&'static str>,
}

const POLICY: &str = r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate";
const PAUSE: &str = r"SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings";
const UX: &str = r"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings";
const WINDOWS_UPDATE: Option<&str> = Some("ToggleWindowsUpdates");
const PAUSE_UPDATES: Option<&str> = Some("PauseUpdates");

const ITEMS: &[Item] = &[
    Item {
        id: "policy.DisableWindowsUpdateAccess",
        kind: BlockerKind::Off,
        path: POLICY,
        name: "DisableWindowsUpdateAccess",
        rule: Rule::Nonzero,
        owner: WINDOWS_UPDATE,
    },
    Item {
        id: "policy.DoNotConnectToWindowsUpdateInternetLocations",
        kind: BlockerKind::Off,
        path: POLICY,
        name: "DoNotConnectToWindowsUpdateInternetLocations",
        rule: Rule::Nonzero,
        owner: WINDOWS_UPDATE,
    },
    Item {
        id: "policy.AU.NoAutoUpdate",
        kind: BlockerKind::Off,
        path: r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
        name: "NoAutoUpdate",
        rule: Rule::Nonzero,
        owner: WINDOWS_UPDATE,
    },
    Item {
        id: "service.wuauserv",
        kind: BlockerKind::Off,
        path: r"SYSTEM\CurrentControlSet\Services\wuauserv",
        name: "Start",
        rule: Rule::Disabled,
        owner: WINDOWS_UPDATE,
    },
    Item {
        id: "service.UsoSvc",
        kind: BlockerKind::Off,
        path: r"SYSTEM\CurrentControlSet\Services\UsoSvc",
        name: "Start",
        rule: Rule::Disabled,
        owner: WINDOWS_UPDATE,
    },
    Item {
        id: "policy.DeferQualityUpdates",
        kind: BlockerKind::Delayed,
        path: POLICY,
        name: "DeferQualityUpdates",
        rule: Rule::Nonzero,
        owner: None,
    },
    Item {
        id: "policy.DeferQualityUpdatesPeriodInDays",
        kind: BlockerKind::Delayed,
        path: POLICY,
        name: "DeferQualityUpdatesPeriodInDays",
        rule: Rule::Nonzero,
        owner: None,
    },
    Item {
        id: "pause.PausedFeatureStatus",
        kind: BlockerKind::Paused,
        path: PAUSE,
        name: "PausedFeatureStatus",
        rule: Rule::Nonzero,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PausedQualityStatus",
        kind: BlockerKind::Paused,
        path: PAUSE,
        name: "PausedQualityStatus",
        rule: Rule::Nonzero,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseFeatureUpdatesStartTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseFeatureUpdatesStartTime",
        rule: Rule::Paused,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseFeatureUpdatesEndTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseFeatureUpdatesEndTime",
        rule: Rule::Future,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseQualityUpdatesStartTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseQualityUpdatesStartTime",
        rule: Rule::Paused,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseQualityUpdatesEndTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseQualityUpdatesEndTime",
        rule: Rule::Future,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseUpdatesStartTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseUpdatesStartTime",
        rule: Rule::Paused,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.PauseUpdatesExpiryTime",
        kind: BlockerKind::Paused,
        path: UX,
        name: "PauseUpdatesExpiryTime",
        rule: Rule::Future,
        owner: PAUSE_UPDATES,
    },
    Item {
        id: "pause.FlightSettingsMaxPauseDays",
        kind: BlockerKind::Paused,
        path: UX,
        name: "FlightSettingsMaxPauseDays",
        rule: Rule::Paused,
        owner: PAUSE_UPDATES,
    },
];

/// A registry value as the blocker rules need it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) enum Value {
    Number(u32),
    Text(String),
    Other,
}

/// Which blockers the values hold, by kind, from the same rules the worker
/// uses. `read` gives each item's value; `owned` says whether a toggle has a
/// recorded choice.
fn blockers_from(
    mut read: impl FnMut(&Item) -> Option<Value>,
    owned: impl Fn(&str) -> bool,
    now: DateTime<Utc>,
) -> Vec<Blocker> {
    let values: Vec<(&Item, Option<Value>)> = ITEMS.iter().map(|item| (item, read(item))).collect();
    let blocks = |item: &Item, value: &Option<Value>| match (item.rule, value) {
        (Rule::Nonzero, Some(Value::Number(number))) => *number != 0,
        (Rule::Disabled, Some(Value::Number(start))) => *start == 4,
        (Rule::Future, Some(Value::Text(text))) => future(text, now),
        _ => false,
    };
    let paused = values.iter().any(|(item, value)| item.kind == BlockerKind::Paused && blocks(item, value));
    let mut found: Vec<Blocker> = Vec::new();
    for (item, value) in &values {
        let blocking = match item.rule {
            Rule::Paused | Rule::Future => paused && value.is_some(),
            _ => blocks(item, value),
        };
        if !blocking {
            continue;
        }
        let owned = item.owner.is_some_and(&owned);
        match found.iter_mut().find(|blocker| blocker.kind == item.kind) {
            Some(blocker) => blocker.owned |= owned,
            None => found.push(Blocker { kind: item.kind, owned }),
        }
    }
    found.sort_by_key(|blocker| blocker.kind);
    found
}

fn future(text: &str, now: DateTime<Utc>) -> bool {
    DateTime::parse_from_rfc3339(text).is_ok_and(|when| when.with_timezone(&Utc) > now)
}

/// Whether a record is a move between Windows releases or only turned
/// Windows Update on for plain updates.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum JournalKind {
    Transition,
    Access,
}

/// How far a move has got, as the worker last recorded it. A diagnostic: the
/// worker always decides from the machine.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Phase {
    Lifted,
    Targeted,
    Installed,
    OnTarget,
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct Source {
    pub build: u32,
    pub ubr: u32,
    pub display_version: String,
    pub edition_id: String,
}

#[derive(Clone, Debug, PartialEq, Eq, Deserialize)]
pub struct Target {
    pub release: String,
    pub build: u32,
    pub kb: String,
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(default)]
pub struct HistoryEntry {
    pub at: String,
    pub event: String,
    pub detail: String,
}

#[derive(Clone, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JournalItem {
    id: String,
    lifted: bool,
}

/// How Windows moved, as the worker decided once on the target build: switched
/// on in place, or rebuilt by Setup.
#[derive(Clone, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(default)]
pub struct Rebuild {
    pub rebuilt: bool,
    pub signals: Vec<String>,
}

/// What the record kept of the Atlas install before Windows moved: its
/// version and the install options its choices give.
#[derive(Clone, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct Carry {
    pub atlas_version: Option<String>,
    pub options: Vec<String>,
    /// `recorded` (a state document's options) or `observed` (read from what
    /// an Atlas without one left).
    pub option_source: String,
    /// Microsoft Edge was installed before Windows moved. A Rebase then
    /// leaves it, whatever the choices say.
    pub edge: bool,
}

/// The open record: what kind of change it is, where it stands, and its
/// recent history for a report.
#[derive(Clone, Debug, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Journal {
    schema: u32,
    pub kind: JournalKind,
    pub phase: Phase,
    pub source: Source,
    #[serde(default)]
    pub target: Option<Target>,
    pub created_at: String,
    #[serde(default)]
    items: Vec<JournalItem>,
    #[serde(default)]
    pub history: Vec<HistoryEntry>,
    #[serde(default)]
    pub rebuild: Option<Rebuild>,
    #[serde(default)]
    pub carry: Option<Carry>,
}

impl Journal {
    /// Windows rebuilt itself during the move, and the record kept the Atlas
    /// install it had: the Atlas install puts Atlas back with those choices.
    pub fn rebase(&self) -> Option<&Carry> {
        if self.kind != JournalKind::Transition
            || !self.rebuild.as_ref().is_some_and(|rebuild| rebuild.rebuilt)
        {
            return None;
        }
        self.carry.as_ref().filter(|carry| carry.atlas_version.is_some())
    }

    /// Whether Windows has moved, or is only waiting for the restart that
    /// finishes it.
    pub fn installed(&self) -> bool {
        matches!(self.phase, Phase::Installed | Phase::OnTarget)
    }

    /// The ids of the settings the record turned on.
    pub fn lifted(&self) -> Vec<&str> {
        self.items.iter().filter(|item| item.lifted).map(|item| item.id.as_str()).collect()
    }
}

/// What the last put-back did, kept after the record closes.
#[derive(Clone, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct LastResult {
    pub closed_at: String,
    pub outcome: String,
    pub kind: String,
    pub restored: Vec<String>,
    pub changed: Vec<String>,
    /// Left to the recorded choices the install replayed.
    pub owned: Vec<String>,
    pub build: u32,
    pub ubr: u32,
}

impl LastResult {
    /// Which kinds of blocker the install turned back on as the user chose.
    pub fn replayed(&self) -> Vec<BlockerKind> {
        let mut kinds: Vec<BlockerKind> = self
            .owned
            .iter()
            .filter_map(|id| ITEMS.iter().find(|item| item.id == id).map(|item| item.kind))
            .collect();
        kinds.sort();
        kinds.dedup();
        kinds
    }
}

/// Parses the worker's record. Only schema 1 is understood; anything else is
/// an error, never a guess.
pub(crate) fn parse_journal(text: &str) -> Result<Journal> {
    let journal: Journal = serde_json::from_str(text.trim_start_matches('\u{feff}'))
        .context("parse the Windows Update record")?;
    if journal.schema != 1 {
        bail!("the Windows Update record has schema {}, which this version doesn't read", journal.schema);
    }
    if journal.kind == JournalKind::Transition && journal.target.is_none() {
        bail!("the Windows Update record has no target");
    }
    Ok(journal)
}

pub(crate) fn parse_last_result(text: &str) -> Result<LastResult> {
    serde_json::from_str(text.trim_start_matches('\u{feff}')).context("parse the last Windows Update result")
}

/// This PC's Windows Update blockers and Atlas's record, as read now.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct UpdateAccess {
    pub blockers: Vec<Blocker>,
    pub journal: Option<Journal>,
    /// The record exists but can't be trusted; nothing acts on it.
    pub journal_error: Option<String>,
    pub last_result: Option<LastResult>,
    /// Settings hides its Windows Update page, so a link to it leads nowhere.
    pub page_hidden: bool,
}

impl UpdateAccess {
    /// A move between releases is under way.
    pub fn transition(&self) -> Option<&Journal> {
        self.journal.as_ref().filter(|journal| journal.kind == JournalKind::Transition)
    }

    /// Something Atlas changed is still to be put back, or can't be read.
    pub fn open(&self) -> bool {
        self.journal.is_some() || self.journal_error.is_some()
    }
}

fn read_value(key: &Key, name: &str) -> Result<Option<Value>> {
    match key.get_value(name) {
        Ok(value) => Ok(Some(match value.ty() {
            Type::U32 => Value::Number(u32::try_from(value).unwrap_or_default()),
            Type::String => Value::Text(String::try_from(value).unwrap_or_default()),
            _ => Value::Other,
        })),
        Err(error) if error.code().0 == NOT_FOUND => Ok(None),
        Err(error) => Err(anyhow::anyhow!("read {name}: {error}")),
    }
}

fn read_machine(path: &str, name: &str) -> Result<Option<Value>> {
    match LOCAL_MACHINE.open(path) {
        Ok(key) => read_value(&key, name),
        Err(error) if error.code().0 == NOT_FOUND => Ok(None),
        Err(error) => Err(anyhow::anyhow!("open {path}: {error}")),
    }
}

fn read_text(name: &str) -> Result<Option<String>> {
    Ok(match read_machine(RECORD, name)? {
        Some(Value::Text(text)) => Some(text),
        Some(_) => bail!("{name} has an unexpected registry type"),
        None => None,
    })
}

/// Reads this PC's blockers and Atlas's record. Works without elevation.
pub fn read() -> Result<UpdateAccess> {
    let mut problem = None;
    let blockers = blockers_from(
        |item| {
            read_machine(item.path, item.name).unwrap_or_else(|error| {
                problem.get_or_insert_with(|| format!("{error:#}"));
                None
            })
        },
        // A recorded choice is a DWORD state, as the worker reads it: a key
        // whose state an older record left cleared holds none.
        |toggle| {
            LOCAL_MACHINE
                .open(format!(r"SOFTWARE\AtlasOS\Services\{toggle}"))
                .and_then(|key| key.get_u32("state"))
                .is_ok()
        },
        Utc::now(),
    );
    if let Some(problem) = problem {
        log::warn!("some Windows Update settings could not be read: {problem}");
    }
    let text = match read_text("Journal") {
        // Without the registry record, its copy under Program Files stands in:
        // a Windows that rebuilt itself keeps Program Files.
        Ok(None) => read_copy(),
        other => other,
    };
    let (journal, journal_error) = match text {
        Ok(Some(text)) => match parse_journal(&text) {
            Ok(journal) => (Some(journal), None),
            Err(error) => (None, Some(format!("{error:#}"))),
        },
        Ok(None) => (None, None),
        Err(error) => (None, Some(format!("{error:#}"))),
    };
    let last_result = read_text("LastResult").ok().flatten().and_then(|text| parse_last_result(&text).ok());
    let page_hidden = matches!(
        read_machine(r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer", "SettingsPageVisibility"),
        Ok(Some(Value::Text(pages))) if hides_windows_update(&pages)
    );
    Ok(UpdateAccess { blockers, journal, journal_error, last_result, page_hidden })
}

/// The Atlas version the record of a move kept, when Windows rebuilt itself
/// during it. Nothing when there is no such record or it can't be read.
pub fn rebase_version() -> Option<String> {
    let text = match read_text("Journal") {
        Ok(None) => read_copy(),
        other => other,
    };
    let journal = parse_journal(&text.ok()??).ok()?;
    journal.rebase()?.atlas_version.clone()
}

/// The worker's copy of its record, beside Atlas Manager's recovery files.
fn read_copy() -> Result<Option<String>> {
    use windows::Win32::{
        System::Com::CoTaskMemFree,
        UI::Shell::{FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, SHGetKnownFolderPath},
    };
    let folder = unsafe { SHGetKnownFolderPath(&FOLDERID_ProgramFiles, KF_FLAG_DEFAULT, None) }?;
    let text = unsafe { folder.to_string() };
    unsafe { CoTaskMemFree(Some(folder.0.cast())) };
    let path = std::path::PathBuf::from(text?).join(r"Atlas Setup Recovery\WindowsTransition\journal.json");
    read_copy_at(&path)
}

/// The copy at `path`, refused as the worker refuses it when it is a link or
/// larger than any record.
fn read_copy_at(path: &std::path::Path) -> Result<Option<String>> {
    const LIMIT: u64 = 512 * 1024;
    let metadata = match std::fs::symlink_metadata(path) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).with_context(|| format!("read {}", path.display())),
    };
    if super::files::is_reparse_point(&metadata) || metadata.len() > LIMIT {
        bail!("the copy of the Windows Update record at {} can't be trusted", path.display());
    }
    std::fs::read_to_string(path).map(Some).with_context(|| format!("read {}", path.display()))
}

/// `SettingsPageVisibility` hides the pages it lists after `hide:`.
fn hides_windows_update(pages: &str) -> bool {
    pages
        .trim()
        .strip_prefix("hide:")
        .is_some_and(|list| list.split(';').any(|page| page.trim().eq_ignore_ascii_case("windowsupdate")))
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURES: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/windows-transition");

    fn fixture(name: &str) -> String {
        std::fs::read_to_string(format!("{FIXTURES}/{name}")).unwrap()
    }

    #[test]
    fn a_record_copy_larger_than_any_record_is_not_read() {
        let temp = crate::services::test_support::TempDir::new("record-copy");
        let path = temp.path().join("journal.json");
        assert_eq!(read_copy_at(&path).unwrap(), None);
        std::fs::write(&path, fixture("journal-transition.json")).unwrap();
        assert!(read_copy_at(&path).unwrap().is_some());
        std::fs::write(&path, vec![b' '; 512 * 1024 + 1]).unwrap();
        assert!(read_copy_at(&path).is_err());
    }

    /// The table here and the worker's (asserted by Pester against the same
    /// fixture) must list the same settings with the same rules.
    #[test]
    fn the_items_match_the_worker_s_table() {
        let items: Vec<serde_json::Value> = serde_json::from_str(&fixture("items.json")).unwrap();
        // Scheduled tasks come back with the service; they never block on their own.
        let lifted: Vec<&serde_json::Value> =
            items.iter().filter(|item| item["group"] != "pin" && item["rule"] != "task").collect();
        assert_eq!(lifted.len(), ITEMS.len());
        for (expected, item) in lifted.iter().zip(ITEMS) {
            assert_eq!(expected["id"], item.id);
            assert_eq!(expected["path"], item.path, "{}", item.id);
            assert_eq!(expected["name"], item.name, "{}", item.id);
            assert_eq!(expected["owner"].as_str(), item.owner, "{}", item.id);
            let kind = match item.kind {
                BlockerKind::Off => "off",
                BlockerKind::Paused => "paused",
                BlockerKind::Delayed => "delayed",
            };
            assert_eq!(expected["group"], kind, "{}", item.id);
            let rule = match item.rule {
                Rule::Nonzero => "nonzero",
                Rule::Disabled => "disabled",
                Rule::Future => "future",
                Rule::Paused => "paused",
            };
            assert_eq!(expected["rule"], rule, "{}", item.id);
        }
    }

    fn values(entries: &[(&str, Value)]) -> impl Fn(&Item) -> Option<Value> + use<> {
        let entries: Vec<(String, Value)> =
            entries.iter().map(|(id, value)| ((*id).to_owned(), value.clone())).collect();
        move |item: &Item| entries.iter().find(|(id, _)| id == item.id).map(|(_, value)| value.clone())
    }

    fn now() -> DateTime<Utc> {
        DateTime::parse_from_rfc3339("2026-10-01T12:00:00Z").unwrap().with_timezone(&Utc)
    }

    #[test]
    fn a_0_5_1_pc_with_updates_off_and_paused_has_both_owned_blockers() {
        let read = values(&[
            ("policy.DisableWindowsUpdateAccess", Value::Number(1)),
            ("service.wuauserv", Value::Number(4)),
            ("pause.PausedFeatureStatus", Value::Number(1)),
            ("pause.PauseUpdatesExpiryTime", Value::Text("3000-12-31T14:03:37Z".into())),
        ]);
        assert_eq!(
            blockers_from(&read, |_| true, now()),
            vec![
                Blocker { kind: BlockerKind::Off, owned: true },
                Blocker { kind: BlockerKind::Paused, owned: true }
            ]
        );
        let unowned = blockers_from(&read, |_| false, now());
        assert!(unowned.iter().all(|blocker| !blocker.owned));
    }

    /// An Atlas 0.5.0 install with Windows Update turned off by its toggle,
    /// paused in Settings and delayed: all three show, the first as the
    /// user's recorded choice.
    #[test]
    fn atlas_0_5_0_with_updates_off_paused_and_delayed_shows_all_three() {
        let state: serde_json::Value =
            serde_json::from_str(&fixture("atlas050-updates-off-paused-delayed.json")).unwrap();
        let entries: Vec<(String, Value)> = state["values"]
            .as_object()
            .unwrap()
            .iter()
            .map(|(id, value)| {
                let value = match value {
                    serde_json::Value::Number(number) => Value::Number(number.as_u64().unwrap() as u32),
                    serde_json::Value::String(text) => Value::Text(text.clone()),
                    _ => Value::Other,
                };
                (id.clone(), value)
            })
            .collect();
        let read =
            move |item: &Item| entries.iter().find(|(id, _)| id == item.id).map(|(_, value)| value.clone());
        let records = state["toggleRecords"].as_object().unwrap().clone();
        let owned = move |toggle: &str| records.contains_key(toggle);
        let read_at =
            DateTime::parse_from_rfc3339(state["readAt"].as_str().unwrap()).unwrap().with_timezone(&Utc);
        let expected: Vec<Blocker> = state["blockers"]
            .as_array()
            .unwrap()
            .iter()
            .map(|blocker| Blocker {
                kind: match blocker["kind"].as_str().unwrap() {
                    "off" => BlockerKind::Off,
                    "paused" => BlockerKind::Paused,
                    _ => BlockerKind::Delayed,
                },
                owned: blocker["owned"].as_bool().unwrap(),
            })
            .collect();
        assert_eq!(blockers_from(read, owned, read_at), expected);
    }

    #[test]
    fn settings_at_their_open_values_and_an_ended_pause_block_nothing() {
        let read = values(&[
            ("policy.DisableWindowsUpdateAccess", Value::Number(0)),
            ("service.wuauserv", Value::Number(3)),
            ("pause.PausedFeatureStatus", Value::Number(0)),
            ("pause.PauseUpdatesExpiryTime", Value::Text("2020-01-01T00:00:00Z".into())),
            ("pause.PauseUpdatesStartTime", Value::Text("2019-12-01T00:00:00Z".into())),
        ]);
        assert_eq!(blockers_from(read, |_| true, now()), vec![]);
        // A 0.5.0 delay has no toggle that owns it.
        let delayed = values(&[("policy.DeferQualityUpdates", Value::Number(1))]);
        assert_eq!(
            blockers_from(delayed, |_| true, now()),
            vec![Blocker { kind: BlockerKind::Delayed, owned: false }]
        );
    }

    #[test]
    fn only_a_schema_1_record_is_read() {
        let transition = parse_journal(&fixture("journal-transition.json")).unwrap();
        assert_eq!(transition.kind, JournalKind::Transition);
        assert_eq!(transition.phase, Phase::Targeted);
        assert_eq!(transition.target.as_ref().map(|t| t.build), Some(26300));
        assert_eq!(transition.source.display_version, "24H2");
        assert!(transition.lifted().contains(&"service.wuauserv"));
        assert!(!transition.installed());
        assert_eq!(transition.history.last().map(|entry| entry.event.as_str()), Some("targeted"));
        let access = parse_journal(&fixture("journal-access.json")).unwrap();
        assert_eq!(access.kind, JournalKind::Access);
        assert!(access.target.is_none());
        let newer = fixture("journal-transition.json").replacen("\"schema\":1", "\"schema\":2", 1);
        assert!(parse_journal(&newer).is_err());
        assert!(parse_journal("{not json").is_err());
        let extra = fixture("journal-transition.json").replacen(
            "\"kind\":\"transition\"",
            "\"kind\":\"transition\",\"x\":0",
            1,
        );
        assert!(parse_journal(&extra).is_ok(), "unknown fields are ignored");
        let untargeted = fixture("journal-transition.json").replacen("\"target\"", "\"aim\"", 1);
        assert!(parse_journal(&untargeted).is_err(), "a move without a target");
        let last = parse_last_result(&fixture("last-result.json")).unwrap();
        assert_eq!(last.outcome, "Installed");
        assert_eq!(last.replayed(), vec![BlockerKind::Off]);
    }

    /// The worker writes the same shape (Pester checks it against this
    /// fixture with the worker's own validation).
    #[test]
    fn a_rebuilt_windows_record_gives_the_kept_atlas_version_and_choices() {
        let rebuilt = parse_journal(&fixture("journal-rebuilt.json")).unwrap();
        let carry = rebuilt.rebase().expect("Windows rebuilt itself and the record kept Atlas 0.5.0");
        assert_eq!(carry.atlas_version.as_deref(), Some("0.5.0"));
        assert_eq!(carry.option_source, "observed");
        assert!(carry.options.iter().any(|option| option == "defender-disable"));
        assert_eq!(rebuilt.rebuild.as_ref().map(|r| r.signals.len()), Some(4));

        let in_place = fixture("journal-rebuilt.json").replacen("\"rebuilt\":true", "\"rebuilt\":false", 1);
        assert!(parse_journal(&in_place).unwrap().rebase().is_none(), "switched on in place");
        let undecided = parse_journal(&fixture("journal-transition.json")).unwrap();
        assert!(undecided.rebase().is_none(), "not decided before the move");
        let no_atlas = fixture("journal-rebuilt.json").replacen(
            "\"atlasVersion\":\"0.5.0\"",
            "\"atlasVersion\":null",
            1,
        );
        assert!(parse_journal(&no_atlas).unwrap().rebase().is_none(), "a PC without Atlas installs fresh");
    }

    #[test]
    fn only_a_listed_windows_update_page_counts_as_hidden() {
        assert!(hides_windows_update("hide:recovery;windowsupdate;home"));
        assert!(!hides_windows_update("hide:recovery;home"));
        assert!(!hides_windows_update("showonly:windowsupdate"));
    }
}
