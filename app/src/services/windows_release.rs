//! Release eligibility, not ISO authenticity. Public cumulative updates can share
//! a build number with earlier Insider flights; only published GA rows qualify.
use std::collections::HashSet;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use anyhow::{Context, Result, ensure};
use chrono::NaiveDate;
use serde::Deserialize;

pub const SOURCE_URL: &str =
    "https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information";
pub const CATALOG: &str =
    include_str!("../../../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json");

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Released,
    Preview,
    Unknown,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Catalog {
    schema_version: u32,
    build: u32,
    release: String,
    releases: Vec<Release>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Release {
    version: String,
    available_date: String,
}

fn snapshot() -> &'static HashSet<String> {
    static SNAPSHOT: OnceLock<HashSet<String>> = OnceLock::new();
    SNAPSHOT.get_or_init(|| {
        let catalog: Catalog = serde_json::from_str(CATALOG).expect("validated Windows release catalog");
        assert_eq!(catalog.schema_version, 1);
        assert_eq!(catalog.build, 26200);
        assert_eq!(catalog.release, "25H2");
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

fn preview_branch(build_lab: &str) -> bool {
    build_lab.to_ascii_lowercase().split(['.', '_', '-']).any(|part| part == "prerelease")
}

fn classify_with(
    version: &str,
    build_lab: &str,
    known: &HashSet<String>,
    refresh: impl FnOnce() -> Result<HashSet<String>>,
) -> Status {
    if preview_branch(build_lab) {
        return Status::Preview;
    }
    if known.contains(version) || refresh().is_ok_and(|versions| versions.contains(version)) {
        Status::Released
    } else {
        Status::Unknown
    }
}

pub fn classify(build: u32, revision: u32, build_lab: &str) -> Status {
    if build != 26200 || revision == 0 {
        return Status::Unknown;
    }
    classify_with(&format!("10.0.{build}.{revision}"), build_lab, snapshot(), latest)
}

struct CachedReleases {
    checked_at: Instant,
    versions: HashSet<String>,
}

fn latest() -> Result<HashSet<String>> {
    static CACHE: OnceLock<Mutex<Option<CachedReleases>>> = OnceLock::new();
    let mut cache = CACHE.get_or_init(|| Mutex::new(None)).lock().map_err(|e| anyhow::anyhow!("{e}"))?;
    if let Some(cached) = &*cache
        && cached.checked_at.elapsed() < Duration::from_secs(15 * 60)
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

fn parse_markdown(text: &str, today: NaiveDate) -> Result<HashSet<String>> {
    let mut inside = false;
    let mut versions = HashSet::new();
    let mut seen = HashSet::new();
    let mut header = false;
    for line in text.lines() {
        let heading = line.trim().trim_start_matches('#').trim().trim_matches('*');
        if heading == "Version 25H2 (OS build 26200)" {
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
        let revision = cells[4].strip_prefix("26200.").context("Unexpected GA release build")?;
        ensure!(
            !revision.is_empty() && revision.bytes().all(|byte| byte.is_ascii_digit()),
            "Malformed GA release revision"
        );
        let revision: i32 = revision.parse()?;
        let version = format!("10.0.26200.{revision}");
        ensure!(seen.insert(version.clone()), "Duplicate GA release version");
        if date > today {
            continue;
        }
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
    ensure!(header && !versions.is_empty(), "No public 25H2 release table found in Microsoft's response");
    Ok(versions)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn public_releases_include_promoted_insider_builds_and_public_optional_updates() {
        let no_network = || -> Result<HashSet<String>> { panic!("known releases need no network") };
        for version in ["10.0.26200.6584", "10.0.26200.7309", "10.0.26200.9278"] {
            assert_eq!(classify_with(version, "ge_release", snapshot(), no_network), Status::Released);
        }
        assert_eq!(classify(26200, 6584, "26200.1.amd64fre.rs_prerelease.250101"), Status::Preview);
        assert_eq!(classify(26200, 0, ""), Status::Unknown);
        assert_eq!(classify(26100, 6584, ""), Status::Unknown);
    }

    #[test]
    fn unknown_builds_refresh_without_treating_failed_verification_as_insider() {
        let version = "10.0.26200.9999";
        assert_eq!(
            classify_with(version, "ge_release", snapshot(), || Ok(HashSet::from([version.into()]))),
            Status::Released
        );
        for version in ["10.0.26200.5074", "10.0.26200.5551", version] {
            assert_eq!(
                classify_with(version, "ge_release", snapshot(), || anyhow::bail!("offline")),
                Status::Unknown
            );
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
