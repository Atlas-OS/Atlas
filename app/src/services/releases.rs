//! GitHub releases of Atlas-OS/Atlas: what is newest, and downloading the
//! playbook asset with progress and verification.

use std::cmp::Ordering;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

const LATEST_URL: &str = "https://api.github.com/repos/Atlas-OS/Atlas/releases/latest";
const USER_AGENT: &str = concat!("AtlasApp/", env!("CARGO_PKG_VERSION"));

#[derive(Clone, Debug, Deserialize)]
pub struct Release {
    pub tag_name: String,
    #[serde(default)]
    pub body: String,
    #[serde(default)]
    pub html_url: String,
    #[serde(default)]
    pub published_at: String,
    #[serde(default)]
    pub assets: Vec<Asset>,
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Asset {
    #[serde(default)]
    pub id: u64,
    pub name: String,
    pub size: u64,
    pub browser_download_url: String,
    /// `sha256:<hex>` when GitHub reports one for the asset.
    #[serde(default)]
    pub digest: Option<String>,
    #[serde(default)]
    pub updated_at: String,
}

impl Release {
    /// Version without a leading "v", as it appears in playbook.conf.
    pub fn version(&self) -> &str {
        self.tag_name.trim_start_matches(['v', 'V'])
    }

    /// The playbook file to install, if the release ships one.
    pub fn playbook_asset(&self) -> Option<&Asset> {
        self.assets.iter().find(|asset| asset.name.to_ascii_lowercase().ends_with(".apbx"))
    }
}

impl Asset {
    /// The SHA-256 hex digest GitHub advertises, if any.
    pub fn sha256(&self) -> Option<&str> {
        let digest = self.digest.as_deref()?;
        let hex = digest.strip_prefix("sha256:")?;
        (hex.len() == 64 && hex.bytes().all(|b| b.is_ascii_hexdigit())).then_some(hex)
    }
}

/// How long a release-metadata request may take in total. It is a few
/// kilobytes of JSON; anything longer is a stalled connection.
const METADATA_TIMEOUT: Duration = Duration::from_secs(20);
/// How long a package download may take in total, and how long the server
/// may take to start answering. The body is tens of megabytes.
const DOWNLOAD_TIMEOUT: Duration = Duration::from_secs(60 * 30);
const RESPONSE_TIMEOUT: Duration = Duration::from_secs(30);

fn agent(total: Duration) -> ureq::Agent {
    let config = ureq::Agent::config_builder()
        .user_agent(USER_AGENT)
        .timeout_connect(Some(Duration::from_secs(10)))
        .timeout_recv_response(Some(RESPONSE_TIMEOUT))
        .timeout_global(Some(total))
        .http_status_as_error(true)
        .build();
    ureq::Agent::new_with_config(config)
}

pub fn fetch_latest() -> Result<Release> {
    log::info!("Checking Atlas releases");
    let mut response = agent(METADATA_TIMEOUT)
        .get(LATEST_URL)
        .header("Accept", "application/vnd.github+json")
        .call()
        .context("ask GitHub for the latest Atlas release")?;
    response.body_mut().read_json::<Release>().context("read the release description")
}

/// An Atlas release version as the project tags it: `major.minor.patch`
/// with an optional suffix such as `-hotfix`.
///
/// Atlas publishes hotfixes for a base version as `<base>-hotfix` releases,
/// so unlike semver a suffix sorts *after* the bare version. Pre-release
/// builds are marked as GitHub pre-releases and never appear as the latest
/// release, so nothing this app compares uses a suffix to mean "earlier".
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AtlasVersion {
    pub core: (u64, u64, u64),
    pub suffix: Option<String>,
}

impl AtlasVersion {
    pub fn parse(text: &str) -> Option<AtlasVersion> {
        let text = text.trim().trim_start_matches(['v', 'V']);
        let (core, suffix) = match text.split_once('-') {
            Some((core, suffix)) if !suffix.is_empty() => (core, Some(suffix.to_owned())),
            Some(_) => return None,
            None => (text, None),
        };
        let mut parts = core.split('.').map(|p| p.parse::<u64>().ok());
        let major = parts.next().flatten()?;
        let minor = parts.next().flatten()?;
        // "0.4" style tags.
        let patch = match parts.next() {
            Some(patch) => patch?,
            None => 0,
        };
        if parts.next().is_some() {
            return None;
        }
        Some(AtlasVersion { core: (major, minor, patch), suffix })
    }
}

impl Ord for AtlasVersion {
    fn cmp(&self, other: &Self) -> Ordering {
        self.core.cmp(&other.core).then_with(|| match (&self.suffix, &other.suffix) {
            (None, None) => Ordering::Equal,
            (None, Some(_)) => Ordering::Less,
            (Some(_), None) => Ordering::Greater,
            (Some(a), Some(b)) => a.to_ascii_lowercase().cmp(&b.to_ascii_lowercase()),
        })
    }
}

impl PartialOrd for AtlasVersion {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

/// Compares two Atlas versions. Unparseable versions compare as strings.
pub fn compare_versions(a: &str, b: &str) -> Ordering {
    match (AtlasVersion::parse(a), AtlasVersion::parse(b)) {
        (Some(a), Some(b)) => a.cmp(&b),
        _ => a.trim().cmp(b.trim()),
    }
}

/// What was verified about a cached download; stored beside the file so a
/// same-named file of the same size is not mistaken for this asset.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct CacheRecord {
    asset: Asset,
    sha256: String,
}

fn record_path(destination: &Path) -> PathBuf {
    let mut name = destination.file_name().map(|n| n.to_os_string()).unwrap_or_default();
    name.push(".verified.json");
    destination.with_file_name(name)
}

/// Streams an asset to disk, reporting (received, total) as it goes. Total is
/// the asset size GitHub reports, so the bar is accurate even without a
/// Content-Length header. The file is verified before it replaces any
/// earlier copy.
pub fn download_into(dir: &Path, asset: &Asset, mut progress: impl FnMut(u64, u64)) -> Result<PathBuf> {
    log::info!("Downloading playbook asset {}; bytes={}; digest={:?}", asset.name, asset.size, asset.digest);
    std::fs::create_dir_all(dir).with_context(|| format!("create {}", dir.display()))?;
    let destination = dir.join(&asset.name);
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    let partial = dir.join(format!("{}.{}-{nanos:x}.partial", asset.name, std::process::id()));

    let result = (|| -> Result<()> {
        let response = agent(DOWNLOAD_TIMEOUT)
            .get(&asset.browser_download_url)
            .call()
            .with_context(|| format!("download {}", asset.name))?;
        let mut reader = response.into_body().into_reader();
        let mut file =
            std::fs::File::create(&partial).with_context(|| format!("create {}", partial.display()))?;

        let mut received = 0u64;
        let mut buffer = [0u8; 64 * 1024];
        progress(0, asset.size);
        loop {
            let read = reader.read(&mut buffer).context("read from GitHub")?;
            if read == 0 {
                break;
            }
            file.write_all(&buffer[..read]).context("write the playbook")?;
            received += read as u64;
            progress(received, asset.size.max(received));
        }
        file.flush()?;
        drop(file);
        promote(&partial, &destination, asset)
    })();
    if result.is_err() {
        let _ = std::fs::remove_file(&partial);
    }
    result.map(|()| destination)
}

/// Verifies a fully downloaded file against the asset and moves it into
/// place with its cache record.
fn promote(partial: &Path, destination: &Path, asset: &Asset) -> Result<()> {
    let length = std::fs::metadata(partial)?.len();
    anyhow::ensure!(
        asset.size == 0 || length == asset.size,
        "the download of {} is incomplete ({length} of {} bytes)",
        asset.name,
        asset.size
    );
    let sha256 = sha256_file(partial)?;
    if let Some(expected) = asset.sha256() {
        anyhow::ensure!(
            sha256.eq_ignore_ascii_case(expected),
            "the download of {} does not match the digest GitHub published",
            asset.name
        );
    }
    let record = CacheRecord { asset: asset.clone(), sha256 };
    let record_path = record_path(destination);
    let _ = std::fs::remove_file(&record_path);
    std::fs::rename(partial, destination)
        .with_context(|| format!("move {} into place", destination.display()))?;
    std::fs::write(&record_path, serde_json::to_string_pretty(&record)?)
        .with_context(|| format!("write {}", record_path.display()))?;
    Ok(())
}

/// A previously downloaded copy of this asset under `dir`, if it was
/// verified as this asset and still matches its recorded digest.
pub fn cached_in(dir: &Path, asset: &Asset) -> Option<PathBuf> {
    let path = dir.join(&asset.name);
    let record: CacheRecord =
        serde_json::from_str(&std::fs::read_to_string(record_path(&path)).ok()?).ok()?;
    if record.asset != *asset {
        return None;
    }
    if let Some(expected) = asset.sha256()
        && !record.sha256.eq_ignore_ascii_case(expected)
    {
        return None;
    }
    let metadata = std::fs::metadata(&path).ok()?;
    if asset.size != 0 && metadata.len() != asset.size {
        return None;
    }
    let actual = sha256_file(&path).ok()?;
    actual.eq_ignore_ascii_case(&record.sha256).then_some(path)
}

pub fn sha256_file(path: &Path) -> Result<String> {
    let mut file = std::fs::File::open(path).with_context(|| format!("open {}", path.display()))?;
    let mut context = ring::digest::Context::new(&ring::digest::SHA256);
    let mut buffer = [0u8; 64 * 1024];
    loop {
        let read = file.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        context.update(&buffer[..read]);
    }
    Ok(context.finish().as_ref().iter().map(|b| format!("{b:02x}")).collect())
}

pub fn file_name(path: &Path) -> String {
    path.file_name().map(|name| name.to_string_lossy().into_owned()).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::TempDir;

    #[test]
    fn hotfix_tags_sort_after_their_base_release() {
        assert_eq!(compare_versions("0.5.0-hotfix", "0.5.0"), Ordering::Greater);
        assert_eq!(compare_versions("0.5.0", "0.5.0-hotfix"), Ordering::Less);
        assert_eq!(compare_versions("0.5.1", "0.5.0-hotfix"), Ordering::Greater);
        assert_eq!(compare_versions("0.5.0-hotfix", "0.5.0-hotfix"), Ordering::Equal);
        assert_eq!(compare_versions("0.5.0-Hotfix", "0.5.0-hotfix"), Ordering::Equal);
    }

    #[test]
    fn every_published_tag_shape_parses() {
        // Shapes Atlas has used: "v0.3.2", "0.4", "0.4.0", "0.5.0-hotfix", "0.5.1".
        assert_eq!(compare_versions("v0.3.2", "0.4"), Ordering::Less);
        assert_eq!(compare_versions("0.4", "0.4.0"), Ordering::Equal);
        assert_eq!(compare_versions("0.6.0", "0.5.1"), Ordering::Greater);
        assert_eq!(compare_versions("0.10.0", "0.9.9"), Ordering::Greater);
        assert!(AtlasVersion::parse("0.6.0-").is_none());
        assert!(AtlasVersion::parse("0.6.0.1").is_none());
        assert!(AtlasVersion::parse("next").is_none());
        // Unparseable tags fall back to string order rather than panicking.
        assert_eq!(compare_versions("next", "0.6.0"), "next".cmp("0.6.0"));
    }

    #[test]
    fn digests_are_only_accepted_in_the_github_shape() {
        let mut asset = Asset { digest: Some(format!("sha256:{}", "ab".repeat(32))), ..Asset::default() };
        assert_eq!(asset.sha256(), Some("ab".repeat(32)).as_deref());
        asset.digest = Some("md5:abc".into());
        assert_eq!(asset.sha256(), None);
        asset.digest = Some("sha256:short".into());
        assert_eq!(asset.sha256(), None);
    }

    fn asset(dir: &Path, name: &str, data: &[u8]) -> (Asset, PathBuf) {
        let path = dir.join(name);
        std::fs::write(&path, data).unwrap();
        let sha = sha256_file(&path).unwrap();
        let asset = Asset {
            id: 42,
            name: name.to_owned(),
            size: data.len() as u64,
            browser_download_url: "https://example.invalid/asset".into(),
            digest: Some(format!("sha256:{sha}")),
            updated_at: "2026-09-01T00:00:00Z".into(),
        };
        (asset, path)
    }

    #[test]
    fn a_same_name_same_size_file_is_not_treated_as_the_asset() {
        let temp = TempDir::new("releases-cache");
        let (asset, _) = asset(temp.path(), "Atlas.apbx", b"payload-bytes");
        // Present with the right size but never verified: not cached.
        assert_eq!(cached_in(temp.path(), &asset), None);
    }

    #[test]
    fn promotion_verifies_length_and_digest_and_records_identity() {
        let temp = TempDir::new("releases-promote");
        let (asset, path) = asset(temp.path(), "Atlas.apbx", b"payload-bytes");
        let partial = temp.path().join("Atlas.apbx.partial");
        std::fs::rename(&path, &partial).unwrap();
        promote(&partial, &path, &asset).unwrap();
        assert_eq!(cached_in(temp.path(), &asset), Some(path.clone()));

        // A different asset with the same name and size is not the cached one.
        let mut other = asset.clone();
        other.id = 43;
        assert_eq!(cached_in(temp.path(), &other), None);
        let mut other = asset.clone();
        other.digest = Some(format!("sha256:{}", "00".repeat(32)));
        assert_eq!(cached_in(temp.path(), &other), None);

        // Local modification invalidates the cache.
        std::fs::write(&path, b"payload-BYTES").unwrap();
        assert_eq!(cached_in(temp.path(), &asset), None);
    }

    #[test]
    fn a_short_or_mismatching_download_is_refused() {
        let temp = TempDir::new("releases-refuse");
        let (mut asset, path) = asset(temp.path(), "Atlas.apbx", b"payload-bytes");
        let partial = temp.path().join("Atlas.apbx.partial");
        std::fs::rename(&path, &partial).unwrap();
        asset.size += 1;
        assert!(promote(&partial, &path, &asset).unwrap_err().to_string().contains("incomplete"));
        asset.size -= 1;
        asset.digest = Some(format!("sha256:{}", "11".repeat(32)));
        assert!(promote(&partial, &path, &asset).unwrap_err().to_string().contains("digest"));
        assert!(!path.exists());
    }
}
