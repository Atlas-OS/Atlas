//! Whether a Windows build is a public release, not whether an ISO is genuine.
//! Cumulative updates can share a build number with earlier Insider flights,
//! so only builds Microsoft lists under the General Availability Channel, or
//! as a hotpatch in its hotpatch calendar, qualify.

use std::collections::HashSet;
use std::sync::{Mutex, OnceLock, PoisonError};
use std::time::{Duration, Instant};

use anyhow::{Context, Result, ensure};
use chrono::NaiveDate;
use serde::Deserialize;

use super::system::SystemInfo;

const SOURCE_URL: &str =
    "https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information";
/// The bundled list of public releases, shared with the PowerShell side.
pub(super) const CATALOG: &str =
    include_str!("../../../package/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json");
/// How long a reading of Microsoft's page is reused.
const CACHE_FOR: Duration = Duration::from_secs(15 * 60);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Released,
    Preview,
    /// Microsoft's page was read and leaves this version out: most often a
    /// Release Preview build, or an update the page doesn't list yet.
    Unlisted,
    Unknown,
}

#[derive(Deserialize)]
struct Catalog {
    releases: Vec<Release>,
    /// The hotpatches Microsoft's hotpatch calendar lists, which Windows
    /// Update also offers outside hotpatch enrolment. Kept apart from the
    /// General Availability releases, which alone decide anything else.
    #[serde(default)]
    hotpatches: Vec<Release>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Release {
    version: String,
    available_date: String,
}

/// Supported builds and their release names; must match the catalog's
/// supportedReleases.
const BUILD_FAMILIES: &[(u32, &str)] = &[(26200, "25H2"), (26300, "26H2")];

fn snapshot() -> &'static HashSet<String> {
    static SNAPSHOT: OnceLock<HashSet<String>> = OnceLock::new();
    SNAPSHOT.get_or_init(|| {
        let catalog: Catalog = serde_json::from_str(CATALOG).expect("validated Windows release catalog");
        catalog
            .releases
            .into_iter()
            .chain(catalog.hotpatches)
            .filter(|release| {
                NaiveDate::parse_from_str(&release.available_date, "%Y-%m-%d")
                    .expect("validated release date")
                    <= chrono::Utc::now().date_naive()
            })
            .map(|release| release.version)
            .collect()
    })
}

/// Insider builds come from an rs_prerelease branch, whatever their number.
fn preview_branch(build_lab: &str) -> bool {
    build_lab.to_ascii_lowercase().split(['.', '_', '-']).any(|part| part == "prerelease")
}

/// Whether an ISO's unlisted revision may be checked on Microsoft's release
/// page. Tester builds don't depend on a live page for an ISO. This PC is
/// always checked on it, as the installer checks it, so Get ready and the
/// installer can't disagree about it.
pub(crate) const REFRESH_ONLINE: bool = !cfg!(feature = "embedded-package");

/// A revision the bundled list doesn't have is looked up on Microsoft's page:
/// it is Unlisted when the page leaves it out, and Unknown when the page
/// can't be read.
fn classify_with(
    version: &str,
    build_lab: &str,
    known: &HashSet<String>,
    refresh: impl FnOnce() -> Result<HashSet<String>>,
) -> Status {
    if preview_branch(build_lab) {
        return Status::Preview;
    }
    if known.contains(version) {
        return Status::Released;
    }
    match refresh() {
        Ok(versions) if versions.contains(version) => Status::Released,
        Ok(_) => Status::Unlisted,
        Err(_) => Status::Unknown,
    }
}

pub fn classify(build: u32, revision: u32, build_lab: &str) -> Status {
    if !BUILD_FAMILIES.iter().any(|family| family.0 == build) || revision == 0 {
        return Status::Unknown;
    }
    classify_with(&format!("10.0.{build}.{revision}"), build_lab, snapshot(), latest)
}

struct CachedReleases {
    checked_at: Instant,
    versions: HashSet<String>,
}

fn latest() -> Result<HashSet<String>> {
    static CACHE: Mutex<Option<CachedReleases>> = Mutex::new(None);
    // Held across the fetch, so concurrent checks share one request.
    let mut cache = CACHE.lock().unwrap_or_else(PoisonError::into_inner);
    if let Some(cached) = &*cache
        && cached.checked_at.elapsed() < CACHE_FOR
    {
        return Ok(cached.versions.clone());
    }
    let config = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(15)))
        .max_redirects(0)
        .http_status_as_error(true)
        .build();
    let mut response = ureq::Agent::new_with_config(config)
        .get(SOURCE_URL)
        .header("User-Agent", super::releases::USER_AGENT)
        .header("Accept", "text/markdown")
        .call()
        .context("check Microsoft's published Windows releases")?;
    ensure!(response.status() == 200, "Unexpected release information response");
    ensure!(
        response.headers().get("content-type").and_then(|value| value.to_str().ok()).is_some_and(|value| {
            value.split(';').next().is_some_and(|mime| mime.eq_ignore_ascii_case("text/markdown"))
        }),
        "Release information was not Markdown"
    );
    let text = response.body_mut().with_config().limit(1024 * 1024).read_to_string()?;
    let versions = parse_markdown(&text, chrono::Utc::now().date_naive())?;
    *cache = Some(CachedReleases { checked_at: Instant::now(), versions: versions.clone() });
    Ok(versions)
}

/// A Markdown heading line without its `#` or `**` decoration.
fn heading(line: &str) -> &str {
    line.trim().trim_start_matches('#').trim().trim_matches('*')
}

fn parse_markdown(text: &str, today: NaiveDate) -> Result<HashSet<String>> {
    let mut versions = HashSet::new();
    for &(build, release) in BUILD_FAMILIES {
        let section = format!("Version {release} (OS build {build})");
        if text.lines().any(|line| heading(line) == section) {
            versions.extend(parse_release_section(text, today, build, &section)?);
        }
    }
    ensure!(!versions.is_empty(), "No supported public Windows release table found in Microsoft's response");
    // Only adds to the General Availability releases: a calendar that can't
    // be read leaves them as they are.
    match parse_hotpatches(text, today) {
        Ok(hotpatches) => versions.extend(hotpatches),
        Err(error) => log::warn!(
            "Microsoft's hotpatch calendar couldn't be read, so only General Availability releases count: {error:#}"
        ),
    }
    Ok(versions)
}

/// The heading Microsoft puts over its hotpatch calendar.
const HOTPATCH_CALENDAR: &str = "Windows 11 hotpatch calendar";

/// The `Version <release> (OS build <build>)` a line names, bold or as a
/// heading, without what follows it, such as the calendar year the hotpatch
/// calendar puts on the same line.
fn version_heading(line: &str) -> Option<&str> {
    let text = line.trim().trim_start_matches('#').trim();
    let text = match text.strip_prefix("**") {
        Some(bold) => bold.split("**").next().unwrap_or(bold),
        None => text,
    };
    Some(text.trim()).filter(|text| text.starts_with("Version "))
}

/// The released hotpatches of the supported releases in Microsoft's hotpatch
/// calendar. Its baseline rows are monthly updates the General Availability
/// tables list already, and any other kind of row is left out. A calendar
/// that's missing gives none; a row of a supported release that can't be
/// read is an error, so a reworked calendar is never misread.
fn parse_hotpatches(text: &str, today: NaiveDate) -> Result<HashSet<String>> {
    let mut versions = HashSet::new();
    let mut seen = HashSet::new();
    let mut inside = false;
    let mut prefix: Option<String> = None;
    let mut header = false;
    for line in text.lines() {
        let trimmed = line.trim_start();
        if trimmed.starts_with("# ") || trimmed.starts_with("## ") {
            if inside {
                break;
            }
            inside = heading(line) == HOTPATCH_CALENDAR;
            continue;
        }
        if !inside {
            continue;
        }
        if let Some(version) = version_heading(line) {
            prefix = BUILD_FAMILIES
                .iter()
                .find(|(build, release)| version == format!("Version {release} (OS build {build})"))
                .map(|(build, _)| format!("{build}."));
            header = false;
            continue;
        }
        if !trimmed.starts_with('|') {
            continue;
        }
        let cells: Vec<_> = line.trim().split('|').map(str::trim).collect();
        if cells == ["", "Month", "Update type", "Type", "Availability date", "Build", "KB article", ""] {
            header = true;
            continue;
        }
        if cells.iter().all(|cell| cell.chars().all(|c| matches!(c, '-' | ':'))) {
            continue;
        }
        let Some(prefix) = &prefix else { continue };
        ensure!(header, "A hotpatch row has no table header");
        ensure!(cells.len() == 8 && cells[0].is_empty() && cells[7].is_empty(), "Malformed hotpatch row");
        if cells[3] != "Hotpatch" {
            continue;
        }
        // A month the calendar announces before its hotpatch is released.
        if cells[4].is_empty() && cells[5].is_empty() {
            continue;
        }
        let date = NaiveDate::parse_from_str(cells[4], "%Y-%m-%d")?;
        let revision = cells[5].strip_prefix(prefix.as_str()).context("Unexpected hotpatch build")?;
        ensure!(
            !revision.is_empty() && revision.bytes().all(|byte| byte.is_ascii_digit()),
            "Malformed hotpatch revision"
        );
        let version = format!("10.0.{prefix}{}", revision.parse::<u32>()?);
        ensure!(seen.insert(version.clone()), "Duplicate hotpatch version");
        if date > today {
            continue;
        }
        check_kb_reference(cells[6])?;
        versions.insert(version);
    }
    Ok(versions)
}

/// Checks a release's KB cell. It isn't used, but checking its shape makes a
/// reworked page fail closed instead of being misread.
fn check_kb_reference(cell: &str) -> Result<()> {
    if cell.is_empty() {
        return Ok(());
    }
    let (kb, url) = cell
        .strip_prefix('[')
        .and_then(|text| text.strip_suffix(')'))
        .and_then(|text| text.split_once("]("))
        .context("Malformed release KB reference")?;
    let digits = kb.strip_prefix("KB").context("Unexpected release KB reference")?;
    ensure!(
        !digits.is_empty() && digits.bytes().all(|byte| byte.is_ascii_digit()),
        "Malformed release KB number"
    );
    let path = url.strip_prefix("https://support.microsoft.com/").context("Unexpected release KB origin")?;
    ensure!(
        !path.is_empty() && !path.chars().any(|c| c.is_whitespace() || c == ')'),
        "Malformed release KB URL"
    );
    Ok(())
}

/// The released versions in the table under the heading `section`.
fn parse_release_section(text: &str, today: NaiveDate, build: u32, section: &str) -> Result<HashSet<String>> {
    let prefix = format!("{build}.");
    let mut inside = false;
    let mut versions = HashSet::new();
    let mut seen = HashSet::new();
    let mut header = false;
    for line in text.lines() {
        let heading = heading(line);
        if heading == section {
            inside = true;
            continue;
        }
        if inside && heading.starts_with("Version ") {
            break;
        }
        if !inside {
            continue;
        }
        let cells: Vec<_> = line.split('|').map(str::trim).collect();
        if cells == ["", "Servicing option", "Update type", "Availability date", "Build", "KB article", ""] {
            header = true;
            continue;
        }
        if cells.get(1) != Some(&"General Availability Channel") {
            continue;
        }
        ensure!(cells.len() == 7 && cells[0].is_empty() && cells[6].is_empty(), "Malformed GA release row");
        let date = NaiveDate::parse_from_str(cells[3], "%Y-%m-%d")?;
        let revision = cells[4].strip_prefix(&prefix).context("Unexpected GA release build")?;
        ensure!(
            !revision.is_empty() && revision.bytes().all(|byte| byte.is_ascii_digit()),
            "Malformed GA release revision"
        );
        let revision: u32 = revision.parse()?;
        let version = format!("10.0.{build}.{revision}");
        ensure!(seen.insert(version.clone()), "Duplicate GA release version");
        if date > today {
            continue;
        }
        check_kb_reference(cells[5])?;
        versions.insert(version);
    }
    ensure!(
        header && !versions.is_empty(),
        "No public release table under {section} in Microsoft's response"
    );
    Ok(versions)
}

/// The release name of a build Atlas supports, such as "26H2".
pub fn release_name(build: u32) -> Option<&'static str> {
    BUILD_FAMILIES.iter().find(|family| family.0 == build).map(|family| family.1)
}

/// A move between Windows releases through Windows Update. Microsoft
/// delivers it as an enablement package: the files are already there, and
/// one restart switches the new release on. Kept apart from
/// [`BUILD_FAMILIES`], which lists the builds Atlas supports, not the ones it
/// can move from.
#[derive(Debug, PartialEq, Eq)]
pub struct Transition {
    pub sources: &'static [u32],
    pub target_build: u32,
    pub target_release: &'static str,
    /// KB numbers Windows Update is known to offer the move under. They name
    /// the update in logs; the worker picks the offer by the release its
    /// title names, so a new KB doesn't stop the move.
    pub kbs: &'static [u32],
    /// KB numbers of the optional cumulative update the move needs first. The
    /// worker installs that update, or a newer one for the same build, and no
    /// other optional update.
    pub prerequisites: &'static [u32],
    /// The revision that includes the prerequisites. It tells "needs a newer
    /// monthly update" apart from "not offered yet" and never gates anything.
    pub minimum_revision: u32,
    /// When the target release stops getting security updates on Home and Pro.
    pub target_end_of_updates: &'static str,
}

pub const TRANSITIONS: &[Transition] = &[Transition {
    sources: &[26100, 26200],
    target_build: 26300,
    target_release: "26H2",
    // The enablement package, and the offer that delivers it on 25H2.
    kbs: &[5_121_794, 5_129_195],
    // The September 2026 preview cumulative update; regular updates from
    // October 2026 include it.
    prerequisites: &[5_124_010],
    minimum_revision: 9546,
    target_end_of_updates: "2028-10-10",
}];

/// When a build stops getting security updates on the Home and Pro editions.
/// Enterprise and Education get a longer window.
const HOME_PRO_END_OF_UPDATES: &[(u32, &str)] = &[(26100, "2026-10-13")];

/// Whether this PC gets updates on the Home and Pro schedule.
fn home_pro_family(system: &SystemInfo) -> bool {
    let edition = system.edition_id.to_ascii_lowercase();
    edition.starts_with("core") || edition.starts_with("professional")
}

/// When this PC's Windows release stops getting security updates, for an
/// edition on the Home and Pro schedule.
pub fn end_of_updates(system: &SystemInfo) -> Option<NaiveDate> {
    if !home_pro_family(system) {
        return None;
    }
    HOME_PRO_END_OF_UPDATES
        .iter()
        .find(|(build, _)| *build == system.build)
        .and_then(|(_, date)| NaiveDate::parse_from_str(date, "%Y-%m-%d").ok())
}

impl Transition {
    pub fn end_of_updates(&self) -> NaiveDate {
        NaiveDate::parse_from_str(self.target_end_of_updates, "%Y-%m-%d").expect("valid transition date")
    }
}

/// Whether the release a PC is on must move for Atlas, or only may.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TransitionNeed {
    /// The package does not support this build: the move comes first.
    Required,
    /// The package supports this build; moving is recommended.
    Optional,
}

/// The move this PC can make before installing a package that supports
/// `supported`: on a source build, with a supported edition and a released
/// Windows, toward a target the package supports. Never during Windows
/// setup, where Windows Update is not Atlas's to drive.
pub fn transition_for(
    system: &SystemInfo,
    supported: &[u32],
    desktop_setup: bool,
) -> Option<(&'static Transition, TransitionNeed)> {
    if desktop_setup || !system.supported_edition() || preview_branch(&system.build_lab) {
        return None;
    }
    let transition = TRANSITIONS
        .iter()
        .find(|t| t.sources.contains(&system.build) && supported.contains(&t.target_build))?;
    let need =
        if supported.contains(&system.build) { TransitionNeed::Optional } else { TransitionNeed::Required };
    Some((transition, need))
}

/// The transition that moves Windows to `release`, for a move under way.
pub fn transition_to(release: &str) -> Option<&'static Transition> {
    TRANSITIONS.iter().find(|t| t.target_release.eq_ignore_ascii_case(release))
}

/// Why a package that supports `supported` can't be installed on this PC
/// whatever Atlas does, so Home can say so before anything starts.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WindowsBlock {
    /// Home or Server: the edition, not the version, rules it out.
    Edition,
    /// An LTSC edition. Windows' name for it carries the LTSC release's
    /// year, which reads like a version, so it's named by its kind instead.
    Ltsc,
    /// No update Atlas can make reaches a supported version from this one.
    NoPath { build: u32 },
    /// An Insider or preview build.
    Preview,
}

pub fn windows_block(system: &SystemInfo, supported: &[u32], desktop_setup: bool) -> Option<WindowsBlock> {
    if desktop_setup || system.build == 0 {
        return None;
    }
    if !system.supported_edition() {
        return Some(if system.ltsc_edition() { WindowsBlock::Ltsc } else { WindowsBlock::Edition });
    }
    if preview_branch(&system.build_lab) {
        return Some(WindowsBlock::Preview);
    }
    if supported.contains(&system.build) || transition_for(system, supported, desktop_setup).is_some() {
        return None;
    }
    Some(WindowsBlock::NoPath { build: system.build })
}

#[cfg(test)]
mod tests {
    use super::*;

    type Refresh = fn() -> Result<HashSet<String>>;

    fn system(build: u32, edition: &str) -> SystemInfo {
        SystemInfo {
            build,
            revision: 9550,
            edition_id: edition.into(),
            installation_type: "Client".into(),
            build_lab: format!("{build}.9550.amd64fre.ge_release.260918-1415"),
            ..SystemInfo::default()
        }
    }

    #[test]
    fn only_a_supported_edition_on_a_source_build_can_move_toward_a_supported_target() {
        let supported = [26200, 26300];
        let need = |system: &SystemInfo| {
            transition_for(system, &supported, false)
                .map(|(transition, need)| (transition.target_build, need))
        };
        assert_eq!(need(&system(26100, "Professional")), Some((26300, TransitionNeed::Required)));
        assert_eq!(need(&system(26200, "Enterprise")), Some((26300, TransitionNeed::Optional)));
        for build in [26300, 22631, 28000, 19045] {
            assert_eq!(need(&system(build, "Professional")), None, "{build}");
        }
        for edition in ["Core", "CoreSingleLanguage", "EnterpriseS", "IoTEnterpriseS"] {
            assert_eq!(need(&system(26100, edition)), None, "{edition}");
        }
        let mut server = system(26100, "ServerStandard");
        server.installation_type = "Server".into();
        assert_eq!(need(&server), None);
        let mut insider = system(26100, "Professional");
        insider.build_lab = "26100.1.amd64fre.rs_prerelease.240101".into();
        assert_eq!(need(&insider), None);
        assert_eq!(transition_for(&system(26100, "Professional"), &supported, true), None, "Windows setup");
        assert_eq!(
            transition_for(&system(26100, "Professional"), &[26200], false),
            None,
            "a target the package lacks"
        );
    }

    #[test]
    fn home_names_what_rules_a_pc_out_before_anything_starts() {
        let supported = [26200, 26300];
        let block = |system: &SystemInfo| windows_block(system, &supported, false);
        assert_eq!(block(&system(26100, "Core")), Some(WindowsBlock::Edition));
        for edition in ["EnterpriseS", "IoTEnterpriseS", "IoTEnterpriseSK"] {
            assert_eq!(block(&system(26300, edition)), Some(WindowsBlock::Ltsc), "{edition}");
        }
        let mut server = system(26300, "ServerStandard");
        server.installation_type = "Server".into();
        assert_eq!(block(&server), Some(WindowsBlock::Edition));
        assert_eq!(block(&system(22631, "Professional")), Some(WindowsBlock::NoPath { build: 22631 }));
        assert_eq!(block(&system(28000, "Professional")), Some(WindowsBlock::NoPath { build: 28000 }));
        let mut insider = system(26300, "Professional");
        insider.build_lab = "26300.1.amd64fre.rs_prerelease.260101".into();
        assert_eq!(block(&insider), Some(WindowsBlock::Preview));
        for build in [26100, 26200, 26300] {
            assert_eq!(block(&system(build, "Professional")), None, "{build}");
        }
        assert_eq!(windows_block(&system(22631, "Core"), &supported, true), None, "Windows setup");
    }

    #[test]
    fn only_home_and_pro_on_24h2_get_the_end_of_updates_warning() {
        let date = NaiveDate::from_ymd_opt(2026, 10, 13);
        for edition in ["Core", "Professional", "ProfessionalWorkstation", "ProfessionalEducation"] {
            assert_eq!(end_of_updates(&system(26100, edition)), date, "{edition}");
        }
        for edition in ["Enterprise", "Education", "IoTEnterprise"] {
            assert_eq!(end_of_updates(&system(26100, edition)), None, "{edition}");
        }
        assert_eq!(end_of_updates(&system(26200, "Professional")), None);
        assert_eq!(TRANSITIONS[0].end_of_updates(), NaiveDate::from_ymd_opt(2028, 10, 10).unwrap());
        assert_eq!(transition_to("26h2").map(|t| t.target_build), Some(26300));
        assert_eq!(transition_to("25H2"), None);
    }

    #[test]
    fn the_catalog_lists_the_supported_build_families() {
        let catalog: serde_json::Value = serde_json::from_str(CATALOG).unwrap();
        assert_eq!(catalog["schemaVersion"], 2);
        let families: Vec<(u64, &str)> = catalog["supportedReleases"]
            .as_array()
            .unwrap()
            .iter()
            .map(|family| (family["build"].as_u64().unwrap(), family["release"].as_str().unwrap()))
            .collect();
        let expected: Vec<(u64, &str)> =
            BUILD_FAMILIES.iter().map(|&(build, release)| (u64::from(build), release)).collect();
        assert_eq!(families, expected);
    }

    #[test]
    fn catalogued_versions_are_released_and_prerelease_branches_are_refused() {
        for (build, revision) in [(26200, 6584), (26300, 9457), (26300, 9550)] {
            assert_eq!(classify(build, revision, "ge_release"), Status::Released, "{build}.{revision}");
            // A promoted Insider build number only counts on a release branch.
            let insider = format!("{build}.1.amd64fre.rs_prerelease");
            assert_eq!(classify(build, revision, &insider), Status::Preview, "{build}.{revision}");
        }
        assert_eq!(classify(28000, 9457, "ge_release"), Status::Unknown);
        assert_eq!(classify(26300, 0, "ge_release"), Status::Unknown);
    }

    #[test]
    fn parser_combines_matching_released_sections_without_accepting_other_channels() {
        let text = "**Version 26H2 (OS build 26300)**\n\
            | Servicing option | Update type | Availability date | Build | KB article |\n\
            | General Availability Channel | | 2026-09-29 | 26300.9457 | |\n\
            | Release Preview Channel | | 2026-09-29 | 26300.9990 | |\n\
            **Version 25H2 (OS build 26200)**\n\
            | Servicing option | Update type | Availability date | Build | KB article |\n\
            | General Availability Channel | | 2026-09-01 | 26200.9278 | |";
        let today = NaiveDate::from_ymd_opt(2026, 9, 30).unwrap();
        assert_eq!(
            parse_markdown(text, today).unwrap(),
            HashSet::from(["10.0.26300.9457".into(), "10.0.26200.9278".into()])
        );
        assert!(parse_markdown(&text.replace("26300.9457", "26200.9457"), today).is_err());
        assert!(parse_markdown(text, NaiveDate::from_ymd_opt(2026, 9, 28).unwrap()).is_err());
    }

    /// Microsoft's page as it lists hotpatches: the General Availability
    /// tables, then a calendar whose 26H2 heading carries the year on the
    /// same line, with baseline rows, an announced month and 24H2 rows.
    const HOTPATCH_PAGE: &str = "## Windows 11 release history\n\
        **Version 26H2 (OS build 26300)**\n\
        | Servicing option | Update type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- |\n\
        | General Availability Channel | 2026-11 B | 2026-11-10 | 26300.9974 | [KB5132061](https://support.microsoft.com/help/5132061) |\n\
        **Version 25H2 (OS build 26200)**\n\
        | Servicing option | Update type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- |\n\
        | General Availability Channel | 2026-11 B | 2026-11-10 | 26200.9974 | [KB5132061](https://support.microsoft.com/help/5132061) |\n\
        \n\
        ## Windows 11 hotpatch calendar\n\
        \n\
        Note\n\
        \n\
        Hotpatching is not available on Windows 11, version 26H1.\n\
        **Version 26H2 (OS build 26300)** **Calendar year 2026**\n\
        \n\
        | Month | Update type | Type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- | --- |\n\
        | October | 2026.10 B | Baseline (Restart) | 2026-10-13 | 26300.9711 | [KB5127648](https://support.microsoft.com/help/5127648) |\n\
        | November | 2026.11 B | Hotpatch | 2026-11-10 | 26300.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |\n\
        | December | 2026.12 B | Hotpatch |  |  |  |\n\
        \n\
        **Version 25H2 (OS build 26200)**\n\
        **Calendar year 2026**\n\
        \n\
        | Month | Update type | Type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- | --- |\n\
        | August | 2026.08 B | Hotpatch | 2026-08-11 | 26200.9106 | [KB5120994](https://support.microsoft.com/help/5120994) |\n\
        | November | 2026.11 B | Hotpatch | 2026-11-10 | 26200.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |\n\
        \n\
        **Calendar year 2025**\n\
        \n\
        | Month | Update type | Type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- | --- |\n\
        | November | 2025.11 B | Hotpatch | 2025-11-11 | 26200.7092 | [KB5068966](https://support.microsoft.com/topic/november-11-2025-hotpatch-kb5068966-os-builds-26200-7092-and-26100-7092-d702b84c) |\n\
        \n\
        **Version 24H2 (OS build 26100)**\n\
        **Calendar year 2026**\n\
        \n\
        | Month | Update type | Type | Availability date | Build | KB article |\n\
        | --- | --- | --- | --- | --- | --- |\n\
        | November | 2026.11 B | Hotpatch | 2026-11-10 | 26100.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |\n";

    fn versions(list: &[&str]) -> HashSet<String> {
        list.iter().map(|version| format!("10.0.{version}")).collect()
    }

    #[test]
    fn released_hotpatches_of_the_supported_releases_count_beside_general_availability() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 20).unwrap();
        let general = ["26300.9974", "26200.9974"];
        assert_eq!(
            parse_markdown(HOTPATCH_PAGE, today).unwrap(),
            versions(&[&general[..], &["26300.9911", "26200.9106", "26200.9911", "26200.7092"]].concat()),
            "baseline rows, the announced month and 24H2 add nothing"
        );
        // Not released yet.
        let later = HOTPATCH_PAGE
            .replace("2026-11-10 | 26300.9911", "2026-11-25 | 26300.9911")
            .replace("2026-11-10 | 26200.9911", "2026-11-25 | 26200.9911");
        assert_eq!(
            parse_markdown(&later, today).unwrap(),
            versions(&["26300.9974", "26200.9974", "26200.9106", "26200.7092"])
        );
        // A row of another kind, such as a preview, is left out.
        let preview =
            HOTPATCH_PAGE.replace("| Hotpatch | 2026-08-11", "| Hotpatch (Release Preview) | 2026-08-11");
        assert!(!parse_markdown(&preview, today).unwrap().contains("10.0.26200.9106"));
        // Without a calendar, the General Availability releases are all there is.
        let (without, _) = HOTPATCH_PAGE.split_once("## Windows 11 hotpatch calendar").unwrap();
        assert_eq!(parse_markdown(without, today).unwrap(), versions(&general));
    }

    /// A calendar that can't be read adds nothing and takes nothing away:
    /// the General Availability releases still count, and are still required.
    #[test]
    fn a_calendar_that_cannot_be_read_leaves_general_availability_as_it_is() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 20).unwrap();
        let general = versions(&["26300.9974", "26200.9974"]);
        for broken in [
            HOTPATCH_PAGE.replace("26200.9106", "26100.9106"),
            HOTPATCH_PAGE.replace("26200.9106", "26200.bad"),
            HOTPATCH_PAGE.replace("2026-08-11", "August 11"),
            HOTPATCH_PAGE.replace("| 2026-08-11 | 26200.9106 |", "| 2026-08-11 |  |"),
            HOTPATCH_PAGE.replace("26200.7092", "26200.9911"),
            HOTPATCH_PAGE
                .replace("https://support.microsoft.com/help/5120994", "https://example.com/5120994"),
            HOTPATCH_PAGE.replace("| Month | Update type | Type |", "| Month | Update type | Kind |"),
            HOTPATCH_PAGE.replace(
                "| November | 2026.11 B | Hotpatch | 2026-11-10 | 26200",
                "| November | Hotpatch | 2026-11-10 | 26200",
            ),
        ] {
            assert_eq!(parse_markdown(&broken, today).unwrap(), general, "{broken}");
        }
        let without_general =
            HOTPATCH_PAGE.replace("General Availability Channel", "Release Preview Channel");
        assert!(parse_markdown(&without_general, today).is_err(), "hotpatches alone are no release table");
    }

    /// The bundled catalog lists hotpatches apart from the General
    /// Availability releases, never the same version twice, and only for the
    /// supported builds; they count offline.
    #[test]
    fn the_bundled_hotpatches_count_offline() {
        let catalog: Catalog = serde_json::from_str(CATALOG).unwrap();
        let general: HashSet<_> = catalog.releases.iter().map(|release| release.version.clone()).collect();
        assert!(!catalog.hotpatches.is_empty());
        for hotpatch in &catalog.hotpatches {
            assert!(!general.contains(&hotpatch.version), "{}", hotpatch.version);
            assert!(
                BUILD_FAMILIES
                    .iter()
                    .any(|(build, _)| hotpatch.version.starts_with(&format!("10.0.{build}."))),
                "{}",
                hotpatch.version
            );
        }
        let no_network: Refresh = || panic!("listed hotpatches need no network");
        for version in ["10.0.26200.9911", "10.0.26300.9911", "10.0.26200.7092"] {
            assert_eq!(
                classify_with(version, "ge_release", snapshot(), no_network),
                Status::Released,
                "{version}"
            );
        }
    }

    #[test]
    fn public_releases_include_promoted_insider_builds_and_public_optional_updates() {
        let no_network: Refresh = || panic!("known releases need no network");
        for version in ["10.0.26200.6584", "10.0.26200.7309", "10.0.26200.9278"] {
            assert_eq!(classify_with(version, "ge_release", snapshot(), no_network), Status::Released);
        }
    }

    #[test]
    fn unknown_builds_refresh_without_treating_failed_verification_as_insider() {
        // Its own list, not the bundled one, so a catalog update that lists
        // these builds can't change the answers.
        let known = HashSet::from(["10.0.26300.9711".to_owned()]);
        let version = "10.0.26200.9999";
        assert_eq!(
            classify_with(version, "ge_release", &known, || Ok(HashSet::from([version.into()]))),
            Status::Released
        );
        for version in ["10.0.26200.5074", "10.0.26200.5551", version] {
            assert_eq!(
                classify_with(version, "ge_release", &known, || anyhow::bail!("offline")),
                Status::Unknown
            );
        }
        // Read, but left out: a Release Preview build or one not listed yet.
        // Every build checks this, a tester build too, as the installer does.
        for version in ["10.0.26200.5551", "10.0.26300.9807", "10.0.26300.10066"] {
            assert_eq!(
                classify_with(version, "ge_release", &known, || Ok(HashSet::from(
                    ["10.0.26300.9711".into()]
                ))),
                Status::Unlisted
            );
        }
        // An Insider branch is refused before any lookup.
        let no_network: Refresh = || panic!("an Insider branch needs no network");
        assert_eq!(
            classify_with("10.0.26200.9999", "26200.1.amd64fre.rs_prerelease.250101", &known, no_network),
            Status::Preview
        );
    }

    #[test]
    fn parser_requires_the_right_section_channel_build_and_released_date() {
        let text = "| General Availability Channel | B | 2026-01-01 | 26200.1 | KB |\n\
            **Version 25H2 (OS build 26200)**\n\
            | Servicing option | Update type | Availability date | Build | KB article |\n\
            | General Availability Channel | D | 2026-01-01 | 26200.7705 | [KB123](https://support.microsoft.com/help/123) |\n\
            | Release Preview | B | 2026-01-01 | 26200.9990 | KB |\n\
            | General Availability Channel | B | 2099-01-01 | 26200.9991 | KB |\n\
            **Version 24H2 (OS build 26100)**\n\
            | General Availability Channel | B | 2026-01-01 | 26200.9993 | KB |";
        let today = NaiveDate::from_ymd_opt(2026, 9, 7).unwrap();
        assert_eq!(parse_markdown(text, today).unwrap(), HashSet::from(["10.0.26200.7705".into()]));
        assert!(parse_markdown("<html>unexpected response</html>", today).is_err());
        assert!(parse_markdown(&text.replace("Servicing option", "Unexpected column"), today).is_err());
        assert!(parse_markdown(&text.replace("support.microsoft.com", "example.com"), today).is_err());
        assert!(parse_markdown(&text.replace("26200.7705", "26100.7705"), today).is_err());
        assert!(parse_markdown(&text.replace("26200.7705", "26200.bad"), today).is_err());
        assert!(parse_markdown(&text.replace("26200.9991", "26200.7705"), today).is_err());
    }
}
