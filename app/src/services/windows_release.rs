//! Whether a Windows build is a public release, not whether an ISO is genuine.
//! Cumulative updates can share a build number with earlier Insider flights,
//! so only builds Microsoft lists under the General Availability Channel
//! qualify.

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
    include_str!("../../../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json");
/// How long a reading of Microsoft's page is reused.
const CACHE_FOR: Duration = Duration::from_secs(15 * 60);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Released,
    Preview,
    Unknown,
}

#[derive(Deserialize)]
struct Catalog {
    releases: Vec<Release>,
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

/// Whether an unlisted revision may be checked on Microsoft's release page.
/// Tester builds never depend on a live page, here or for an ISO; stable
/// builds keep an unlisted revision Unknown until the page lists it.
pub(crate) const REFRESH_ONLINE: bool = !cfg!(feature = "embedded-playbook");

/// With no `refresh` (tester builds), an unlisted revision of a supported
/// build on a release branch counts as released: the bundled list only ages,
/// so it is most likely a newer cumulative update.
fn classify_with(
    version: &str,
    build_lab: &str,
    known: &HashSet<String>,
    refresh: Option<impl FnOnce() -> Result<HashSet<String>>>,
) -> Status {
    if preview_branch(build_lab) {
        return Status::Preview;
    }
    if known.contains(version) {
        return Status::Released;
    }
    match refresh {
        Some(refresh) => {
            if refresh().is_ok_and(|versions| versions.contains(version)) {
                Status::Released
            } else {
                Status::Unknown
            }
        }
        None => Status::Released,
    }
}

pub fn classify(build: u32, revision: u32, build_lab: &str) -> Status {
    if !BUILD_FAMILIES.iter().any(|family| family.0 == build) || revision == 0 {
        return Status::Unknown;
    }
    classify_with(
        &format!("10.0.{build}.{revision}"),
        build_lab,
        snapshot(),
        REFRESH_ONLINE.then_some(latest),
    )
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
    Ok(versions)
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
        // The KB cell is not used, but checking its shape makes a reworked
        // page fail closed instead of being misread.
        if !cells[5].is_empty() {
            let (kb, url) = cells[5]
                .strip_prefix('[')
                .and_then(|text| text.strip_suffix(')'))
                .and_then(|text| text.split_once("]("))
                .context("Malformed release KB reference")?;
            let digits = kb.strip_prefix("KB").context("Unexpected release KB reference")?;
            ensure!(
                !digits.is_empty() && digits.bytes().all(|byte| byte.is_ascii_digit()),
                "Malformed release KB number"
            );
            let path =
                url.strip_prefix("https://support.microsoft.com/").context("Unexpected release KB origin")?;
            ensure!(
                !path.is_empty() && !path.chars().any(|c| c.is_whitespace() || c == ')'),
                "Malformed release KB URL"
            );
        }
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
    /// Home, LTSC or Server: the edition, not the version, rules it out.
    Edition,
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
        return Some(WindowsBlock::Edition);
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
        assert_eq!(block(&system(26100, "EnterpriseS")), Some(WindowsBlock::Edition));
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
    fn released_26h2_versions_are_known_offline_and_prerelease_branches_are_refused() {
        for revision in [9457, 9550] {
            assert_eq!(classify(26300, revision, "ge_release"), Status::Released);
            assert_eq!(classify(26300, revision, "26300.1.amd64fre.rs_prerelease"), Status::Preview);
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

    #[test]
    fn public_releases_include_promoted_insider_builds_and_public_optional_updates() {
        let no_network: Refresh = || panic!("known releases need no network");
        for version in ["10.0.26200.6584", "10.0.26200.7309", "10.0.26200.9278"] {
            assert_eq!(classify_with(version, "ge_release", snapshot(), Some(no_network)), Status::Released);
        }
        assert_eq!(classify(26200, 6584, "26200.1.amd64fre.rs_prerelease.250101"), Status::Preview);
        assert_eq!(classify(26200, 0, ""), Status::Unknown);
        assert_eq!(classify(26100, 6584, ""), Status::Unknown);
    }

    #[test]
    fn unknown_builds_refresh_without_treating_failed_verification_as_insider() {
        let version = "10.0.26200.9999";
        assert_eq!(
            classify_with(version, "ge_release", snapshot(), Some(|| Ok(HashSet::from([version.into()])))),
            Status::Released
        );
        for version in ["10.0.26200.5074", "10.0.26200.5551", version] {
            assert_eq!(
                classify_with(version, "ge_release", snapshot(), Some(|| anyhow::bail!("offline"))),
                Status::Unknown
            );
        }
    }

    #[test]
    fn without_a_live_lookup_unlisted_ga_revisions_pass_but_insider_branches_still_fail() {
        let offline = None::<Refresh>;
        assert_eq!(classify_with("10.0.26200.9999", "ge_release", snapshot(), offline), Status::Released);
        assert_eq!(classify_with("10.0.26200.6584", "ge_release", snapshot(), offline), Status::Released);
        assert_eq!(
            classify_with("10.0.26200.9999", "26200.1.amd64fre.rs_prerelease.250101", snapshot(), offline),
            Status::Preview
        );
        // A tester build never reaches Microsoft's page; the build gate alone still applies.
        if !REFRESH_ONLINE {
            assert_eq!(classify(26200, 65535, "ge_release"), Status::Released);
            assert_eq!(classify(26100, 65535, "ge_release"), Status::Unknown);
        }
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
