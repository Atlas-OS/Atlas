//! A tester build carries one playbook inside the executable and installs
//! nothing else. The bytes are written to the downloads folder once and then
//! go through the same extraction and caching as a downloaded package, so
//! everything downstream sees an ordinary `.apbx` with an exact digest.
//!
//! Without the `embedded-playbook` feature this module only answers "no".
#![cfg_attr(not(any(test, feature = "embedded-playbook")), allow(dead_code, unused_imports))]

use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};

use super::playbook;
use super::releases::sha256_file;

#[cfg(feature = "embedded-playbook")]
mod built {
    include!(concat!(env!("OUT_DIR"), "/embedded.rs"));
    pub const SOURCE_COMMIT: &str = env!("ATLAS_SOURCE_COMMIT");
}

/// The release candidate id this build carries, such as `0.6.0-rc.1`.
pub fn rc_id() -> Option<&'static str> {
    #[cfg(feature = "embedded-playbook")]
    {
        Some(built::RC_ID)
    }
    #[cfg(not(feature = "embedded-playbook"))]
    {
        None
    }
}

/// The Git commit the tester build was made from, for About and diagnostics.
pub fn source_commit() -> Option<&'static str> {
    #[cfg(feature = "embedded-playbook")]
    {
        Some(built::SOURCE_COMMIT)
    }
    #[cfg(not(feature = "embedded-playbook"))]
    {
        None
    }
}

/// SHA-256 of the embedded archive, hashed once.
#[cfg(feature = "embedded-playbook")]
pub fn sha256() -> &'static str {
    static HASH: std::sync::OnceLock<String> = std::sync::OnceLock::new();
    HASH.get_or_init(|| sha256_bytes(built::APBX))
}

/// Writes the embedded archive under the app's downloads and returns its path.
#[cfg(feature = "embedded-playbook")]
pub fn materialize(paths: &super::settings::AppPaths) -> Result<PathBuf> {
    materialize_into(&paths.downloads().join(format!("Atlas-{}.apbx", built::RC_ID)), built::APBX, sha256())
}

/// Whether an unpacked package directory holds exactly the embedded archive.
#[cfg(feature = "embedded-playbook")]
pub fn holds(dir: &Path) -> bool {
    package_matches(dir, sha256())
}

pub(crate) fn sha256_bytes(bytes: &[u8]) -> String {
    ring::digest::digest(&ring::digest::SHA256, bytes).as_ref().iter().map(|b| format!("{b:02x}")).collect()
}

/// An unpacked directory was extracted from an archive with this digest.
pub(crate) fn package_matches(dir: &Path, sha256: &str) -> bool {
    playbook::identity(dir).is_some_and(|identity| identity.sha256.eq_ignore_ascii_case(sha256))
}

/// Puts `bytes` at `destination` unless an identical file is already there.
/// Each caller writes its own temporary file and renames it into place, so
/// two instances (or startup and the ISO page) racing here both end with one
/// valid file; whoever loses the rename verifies and reuses the winner's.
pub(crate) fn materialize_into(destination: &Path, bytes: &[u8], sha256: &str) -> Result<PathBuf> {
    let intact = |path: &Path| {
        std::fs::metadata(path).is_ok_and(|meta| meta.len() == bytes.len() as u64)
            && sha256_file(path).is_ok_and(|actual| actual.eq_ignore_ascii_case(sha256))
    };
    if intact(destination) {
        return Ok(destination.to_path_buf());
    }
    let dir = destination.parent().context("the embedded package needs a parent directory")?;
    std::fs::create_dir_all(dir).with_context(|| format!("create {}", dir.display()))?;
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    let name = destination.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
    let partial = dir.join(format!("{name}.{}-{nanos:x}.partial", std::process::id()));
    let result = std::fs::write(&partial, bytes)
        .with_context(|| format!("write {}", partial.display()))
        .and_then(|()| {
            std::fs::rename(&partial, destination)
                .with_context(|| format!("move {} into place", destination.display()))
        });
    if result.is_err() {
        let _ = std::fs::remove_file(&partial);
        // Another writer may have won; its file is as good as ours.
        if intact(destination) {
            return Ok(destination.to_path_buf());
        }
    }
    result.map(|()| destination.to_path_buf())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::{TempDir, apbx};

    const BYTES: &[u8] = b"not really an archive, but bytes are bytes";

    #[test]
    fn a_valid_cached_file_is_kept_and_a_corrupt_one_is_replaced() {
        let temp = TempDir::new("embedded-cache");
        let destination = temp.path().join("Downloads/Atlas-test.apbx");
        let digest = sha256_bytes(BYTES);
        assert_eq!(materialize_into(&destination, BYTES, &digest).unwrap(), destination);
        let written = std::fs::metadata(&destination).unwrap().modified().unwrap();
        std::thread::sleep(std::time::Duration::from_millis(20));
        materialize_into(&destination, BYTES, &digest).unwrap();
        assert_eq!(std::fs::metadata(&destination).unwrap().modified().unwrap(), written, "not rewritten");

        std::fs::write(&destination, b"same length but not the same bytes,corrupt").unwrap();
        materialize_into(&destination, BYTES, &digest).unwrap();
        assert_eq!(std::fs::read(&destination).unwrap(), BYTES);
        std::fs::write(&destination, b"short").unwrap();
        materialize_into(&destination, BYTES, &digest).unwrap();
        assert_eq!(std::fs::read(&destination).unwrap(), BYTES);
        assert!(
            std::fs::read_dir(destination.parent().unwrap()).unwrap().count() == 1,
            "no partial files remain"
        );
    }

    #[test]
    fn concurrent_callers_end_with_one_valid_file() {
        let temp = TempDir::new("embedded-race");
        let destination = temp.path().join("Atlas-race.apbx");
        let digest = sha256_bytes(BYTES);
        let workers: Vec<_> = (0..8)
            .map(|_| {
                let destination = destination.clone();
                let digest = digest.clone();
                std::thread::spawn(move || materialize_into(&destination, BYTES, &digest).unwrap())
            })
            .collect();
        for worker in workers {
            assert_eq!(worker.join().unwrap(), destination);
        }
        assert_eq!(std::fs::read(&destination).unwrap(), BYTES);
        assert_eq!(std::fs::read_dir(temp.path()).unwrap().count(), 1, "no partial files remain");
    }

    #[test]
    fn a_package_matches_only_the_archive_it_was_unpacked_from() {
        let temp = TempDir::new("embedded-identity");
        let package = apbx::write(&temp.path().join("package.apbx"), &apbx::valid("0.6.0"));
        let digest = sha256_file(&package).unwrap();
        let (dir, _) = playbook::extract_into(&package, &temp.path().join("Playbooks"), |_, _| {}).unwrap();
        assert!(package_matches(&dir, &digest));
        assert!(package_matches(&dir, &digest.to_uppercase()));
        assert!(!package_matches(&dir, &sha256_bytes(BYTES)));
        assert!(!package_matches(temp.path(), &digest), "a directory without an identity never matches");
    }
}
