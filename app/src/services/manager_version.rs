//! This Atlas Manager's own version: whether it meets what an Atlas package
//! asks for (`minimumManagerVersion` in `atlas.json`), and whether a release
//! is newer than it. Atlas Manager is released with the Atlas version of the
//! same number and can't update itself, so a newer one is downloaded from
//! the latest release.

use super::releases::AtlasVersion;

/// A version as `minimumManagerVersion` writes it: `major.minor.patch`,
/// digits only.
pub type PlainVersion = (u64, u64, u64);

/// Reads a `major.minor.patch` version, refusing anything else: a leading
/// "v", a suffix, a missing or extra part.
pub fn parse_plain(text: &str) -> Option<PlainVersion> {
    let mut parts = text.split('.').map(|part| {
        (!part.is_empty() && part.bytes().all(|b| b.is_ascii_digit()))
            .then(|| part.parse::<u64>().ok())
            .flatten()
    });
    let version = (parts.next()??, parts.next()??, parts.next()??);
    parts.next().is_none().then_some(version)
}

/// The patch release after this app's version, which review previews show
/// as a newer Atlas Manager.
pub fn next_patch() -> String {
    let (major, minor, patch) = ManagerVersion::current().version.core;
    format!("{major}.{minor}.{}", patch + 1)
}

/// How this app compares with packages and releases.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ManagerVersion {
    /// The Atlas version this app is released with. A tester build carries
    /// its base version: a candidate for 0.6.0 is 0.6.0.
    version: AtlasVersion,
    /// A tester build: a candidate that comes before the release of its
    /// base version.
    tester: bool,
}

impl ManagerVersion {
    /// This app: Cargo's version, which a tester build's RC id starts with.
    pub fn current() -> Self {
        Self::new(env!("CARGO_PKG_VERSION"), super::embedded::rc_id().is_some())
    }

    /// `version` is an Atlas version such as `0.6.0`.
    pub fn new(version: &str, tester: bool) -> Self {
        let version = AtlasVersion::parse(version).expect("Atlas Manager's version is an Atlas version");
        Self { version, tester }
    }

    /// Whether this app is at least `minimum`, judged by its base version,
    /// so a tester build meets what the release of that version meets.
    pub fn meets(&self, minimum: PlainVersion) -> bool {
        self.version.core >= minimum
    }

    /// Whether the release tagged `release` (with or without a leading "v")
    /// is newer than this app. A tester build counts any release of its base
    /// version, the final one included, as newer. A tag that isn't a version
    /// is never newer.
    pub fn older_than(&self, release: &str) -> bool {
        let Some(release) = AtlasVersion::parse(release) else { return false };
        if self.tester { release.core >= self.version.core } else { release > self.version }
    }
}

impl std::fmt::Display for ManagerVersion {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let (major, minor, patch) = self.version.core;
        write!(f, "{major}.{minor}.{patch}")?;
        if let Some(suffix) = &self.version.suffix {
            write!(f, "-{suffix}")?;
        }
        if self.tester {
            write!(f, " (test build)")?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_plain_versions_are_read() {
        assert_eq!(parse_plain("0.6.0"), Some((0, 6, 0)));
        assert_eq!(parse_plain("10.20.30"), Some((10, 20, 30)));
        for text in ["", "0.6", "0.6.0.1", "v0.6.0", "0.6.0-rc.1", "0.6.x", " 0.6.0", "0..0", "0.6.-1"] {
            assert_eq!(parse_plain(text), None, "{text:?}");
        }
    }

    #[test]
    fn a_package_is_met_by_its_version_or_a_later_one() {
        let manager = ManagerVersion::new("0.6.0", false);
        assert!(manager.meets((0, 6, 0)));
        assert!(manager.meets((0, 5, 9)));
        assert!(!manager.meets((0, 6, 1)));
        assert!(!manager.meets((1, 0, 0)));
        // A tester build compares its base version.
        let tester = ManagerVersion::new("0.6.0", true);
        assert!(tester.meets((0, 6, 0)));
        assert!(!tester.meets((0, 7, 0)));
    }

    #[test]
    fn a_release_is_newer_only_when_its_version_is() {
        let manager = ManagerVersion::new("0.6.0", false);
        assert!(manager.older_than("0.6.1"), "newer");
        assert!(manager.older_than("v0.7.0"), "newer, tagged with a v");
        assert!(manager.older_than("0.6.0-hotfix"), "a hotfix of this version comes after it");
        assert!(!manager.older_than("0.6.0"), "equal");
        assert!(!manager.older_than("v0.6.0"), "equal, tagged with a v");
        assert!(!manager.older_than("0.5.1"), "older");
        assert!(!manager.older_than("next"), "not a version");
        let hotfix = ManagerVersion::new("0.6.0-hotfix", false);
        assert!(!hotfix.older_than("0.6.0-hotfix") && !hotfix.older_than("0.6.0"));
    }

    #[test]
    fn a_tester_build_is_older_than_the_final_release_of_its_base_version() {
        let tester = ManagerVersion::new("0.6.0", true);
        assert!(tester.older_than("0.6.0"), "the final release");
        assert!(tester.older_than("v0.6.0-hotfix"));
        assert!(tester.older_than("0.7.0"));
        assert!(!tester.older_than("0.5.1"), "an earlier release");
        assert_eq!(tester.to_string(), "0.6.0 (test build)");
    }
}
