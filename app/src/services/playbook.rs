//! The Atlas package: reading playbook.conf (what the install offers and
//! requires) and unpacking an .apbx so the front door script can run it.
//!
//! Unpacking is transactional and the result immutable. The archive is
//! written to a private staging directory under the package cache,
//! validated there, and only then moved into its final place, which is named
//! after the package's version *and* the archive's content digest
//! (`<cache>/<version>_<digest>`). Two packages that both call themselves
//! 0.6.0 therefore never share a directory: a manifest read from a prepared
//! package always describes the files at that path, whatever another window
//! unpacks later. Identical content is recognised and reused.

use std::fs;
use std::io::Read;
use std::path::{Component, Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use super::files::is_reparse_point;
use super::releases::sha256_file;

/// The archive password is public by design; it only stops antivirus engines
/// from scanning the scripts inside the package before they are staged.
pub(crate) const APBX_PASSWORD: &str = "malte";

/// The install time playbook.conf claims when it gives none.
const DEFAULT_ESTIMATED_MINUTES: u32 = 15;

/// The playbook.conf in this repository, used to describe options
/// before any release has been downloaded.
const BUILTIN_CONF: &str = include_str!("../../../playbook/playbook.conf");

/// The first Atlas release that includes the front door script this app drives.
pub const FIRST_FRONT_DOOR_VERSION: &str = "0.6.0";

/// Whether an Atlas version is known to predate the front door script. A
/// version that cannot be read is not: the package's own files decide.
pub fn predates_front_door(version: &str) -> bool {
    super::releases::AtlasVersion::parse(version).is_some()
        && super::releases::compare_versions(version, FIRST_FRONT_DOOR_VERSION).is_lt()
}

/// The package predates the front door script this app drives. Typed so the
/// UI can explain it in the user's language.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Unsupported {
    pub version: String,
}

impl std::fmt::Display for Unsupported {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Atlas {} predates this app and has no front door script; install it with AME Wizard, or use Atlas {FIRST_FRONT_DOOR_VERSION} or newer here",
            self.version
        )
    }
}

impl std::error::Error for Unsupported {}

/// The package is recent enough to have the front door script but does not
/// contain it: damaged, incomplete, or not an Atlas release.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Incomplete {
    pub version: String,
}

impl std::fmt::Display for Incomplete {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Atlas {} has no front door script at Executables\\AtlasModules\\Scripts\\Entry\\Install-Atlas.ps1",
            self.version
        )
    }
}

impl std::error::Error for Incomplete {}

const STAGING_PREFIX: &str = ".staging-";
/// Written into every published directory: which archive it came from.
const IDENTITY_FILE: &str = ".atlas-package.json";
/// Hex digits of the archive digest in the directory name.
const DIGEST_IN_NAME: usize = 16;

/// What a published directory holds: the version its manifest declares and
/// the SHA-256 of the archive it was unpacked from.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PackageIdentity {
    pub version: String,
    pub sha256: String,
}

impl PackageIdentity {
    /// The directory name for this content: version, then enough of the
    /// digest to tell packages apart, separated so neither is mistaken for
    /// part of the other (a version never contains `_`).
    pub fn directory_name(&self) -> String {
        format!("{}_{}", self.version, &self.sha256[..DIGEST_IN_NAME.min(self.sha256.len())])
    }
}

/// The identity a published directory records, if it has one.
pub fn identity(dir: &Path) -> Option<PackageIdentity> {
    let text = fs::read_to_string(dir.join(IDENTITY_FILE)).ok()?;
    serde_json::from_str(&text).ok()
}

#[derive(Clone, Debug)]
pub struct Manifest {
    pub version: String,
    pub upgradable_from: Vec<String>,
    pub supported_builds: Vec<u32>,
    pub estimated_minutes: u32,
    pub pages: Vec<FeaturePage>,
}

#[derive(Clone, Debug)]
pub struct FeaturePage {
    pub kind: PageKind,
    pub description: String,
    pub learn_more: Option<Link>,
    /// Only shown when this option name is selected elsewhere.
    pub depends_on: Option<String>,
    pub options: Vec<FeatureOption>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PageKind {
    /// Exactly one option; `default` names the preselected one.
    Radio,
    /// Any number of options.
    Checkbox,
}

#[derive(Clone, Debug)]
pub struct FeatureOption {
    pub name: String,
    pub text: String,
    pub image: Option<String>,
    pub default: bool,
}

impl FeatureOption {
    /// Optional artwork belongs to the unpacked package, never the executable.
    pub fn image_path(&self, package: &Path) -> Option<PathBuf> {
        let name = self.image.as_deref()?;
        // FileName is a stem in Images, not an arbitrary path or URL.
        if name.is_empty() || !name.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_') {
            return None;
        }
        let path = package.join("Images").join(format!("{name}.png"));
        path.is_file().then_some(path)
    }
}

#[derive(Clone, Debug)]
pub struct Link {
    pub url: String,
}

impl Manifest {
    pub fn builtin() -> Manifest {
        parse(BUILTIN_CONF).expect("the repository playbook.conf parses")
    }

    /// Option names selected by default, in page order.
    pub fn default_options(&self) -> Vec<String> {
        self.pages
            .iter()
            .flat_map(|page| page.options.iter().filter(|o| o.default).map(|o| o.name.clone()))
            .collect()
    }

    /// The label the user saw for an option name, if this manifest knows it.
    pub fn option_label(&self, name: &str) -> Option<&str> {
        self.pages
            .iter()
            .flat_map(|page| page.options.iter())
            .find(|option| option.name == name)
            .map(|option| option.text.as_str())
    }
}

/// The manifest of an already unpacked package directory.
pub fn read_manifest(dir: &Path) -> Result<Manifest> {
    let text = fs::read_to_string(dir.join("playbook.conf"))
        .with_context(|| format!("read {}", dir.join("playbook.conf").display()))?;
    parse(&text)
}

pub fn parse(xml: &str) -> Result<Manifest> {
    let xml = xml.trim_start_matches('\u{feff}');
    let doc = roxmltree::Document::parse(xml).context("parse playbook.conf")?;
    let root = doc.root_element();
    let text_of = |name: &str| -> String {
        root.children()
            .find(|n| n.has_tag_name(name))
            .and_then(|n| n.text())
            .unwrap_or_default()
            .trim()
            .to_owned()
    };

    // The `<string>` items of a list element such as `<SupportedBuilds>`.
    let strings = |tag: &str| {
        root.children()
            .find(|n| n.has_tag_name(tag))
            .into_iter()
            .flat_map(|list| list.children().filter(|n| n.has_tag_name("string")))
            .filter_map(|n| n.text())
            .map(str::trim)
    };
    let pages = root
        .children()
        .find(|n| n.has_tag_name("FeaturePages"))
        .map(|node| node.children().filter(|n| n.is_element()).filter_map(parse_page).collect())
        .unwrap_or_default();

    Ok(Manifest {
        version: text_of("Version"),
        upgradable_from: strings("UpgradableFrom").map(str::to_owned).collect(),
        supported_builds: strings("SupportedBuilds").filter_map(|build| build.parse().ok()).collect(),
        estimated_minutes: text_of("EstimatedMinutes").parse().unwrap_or(DEFAULT_ESTIMATED_MINUTES),
        pages,
    })
}

fn parse_page(node: roxmltree::Node) -> Option<FeaturePage> {
    let kind = match node.tag_name().name() {
        "RadioPage" | "RadioImagePage" => PageKind::Radio,
        "CheckboxPage" => PageKind::Checkbox,
        _ => return None,
    };
    let default = node.attribute("DefaultOption").unwrap_or_default();
    let options = node
        .children()
        .find(|n| n.has_tag_name("Options"))
        .map(|options| {
            options
                .children()
                .filter(|n| n.is_element())
                .filter_map(|option| {
                    let child_text = |name: &str| {
                        option
                            .children()
                            .find(|n| n.has_tag_name(name))
                            .and_then(|n| n.text())
                            .map(|t| t.trim().to_owned())
                    };
                    let name = child_text("Name")?;
                    Some(FeatureOption {
                        default: name == default,
                        text: child_text("Text").unwrap_or_else(|| name.clone()),
                        image: child_text("FileName"),
                        name,
                    })
                })
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    if options.is_empty() {
        return None;
    }
    let learn_more = node
        .children()
        .find(|n| n.has_tag_name("BottomLine"))
        .and_then(|n| Some(Link { url: n.attribute("Link")?.to_owned() }));
    Some(FeaturePage {
        kind,
        description: node.attribute("Description").unwrap_or_default().to_owned(),
        learn_more,
        depends_on: node.attribute("DependsOn").map(str::to_owned),
        options,
    })
}

/// Checks that a package version can name a cache directory: the same shape
/// `Get-AtlasPlaybookVersion` accepts (`major.minor.patch` with an optional
/// `-suffix` of letters, digits, dots and dashes), which rules out empty,
/// relative, rooted and separator-bearing values.
pub fn validate_version(version: &str) -> Result<&str> {
    const MAX_LEN: usize = 64;
    let text = version.trim();
    anyhow::ensure!(!text.is_empty(), "the package has no version");
    anyhow::ensure!(text.len() <= MAX_LEN, "the package version {text:?} is too long");
    let (core, suffix) = match text.split_once('-') {
        Some((core, suffix)) => (core, Some(suffix)),
        None => (text, None),
    };
    let parts: Vec<&str> = core.split('.').collect();
    let core_ok =
        parts.len() == 3 && parts.iter().all(|p| !p.is_empty() && p.bytes().all(|b| b.is_ascii_digit()));
    anyhow::ensure!(core_ok, "the package version {text:?} is not major.minor.patch");
    if let Some(suffix) = suffix {
        let suffix_ok =
            !suffix.is_empty() && suffix.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-');
        anyhow::ensure!(suffix_ok, "the package version {text:?} has an invalid suffix");
    }
    // Windows drops trailing dots from directory names, which would make the
    // published path differ from the version.
    anyhow::ensure!(!text.ends_with('.'), "the package version {text:?} ends with a dot");
    Ok(text)
}

/// The front door script inside an extracted package. The package keeps
/// `playbook.conf` at its root and Atlas's files under `Executables`; the
/// script finds the root from its own location.
pub fn front_door(dir: &Path) -> PathBuf {
    dir.join("Executables").join("AtlasModules").join("Scripts").join("Entry").join("Install-Atlas.ps1")
}

/// Drops the `\\?\` prefix `canonicalize` adds: PowerShell's path cmdlets
/// cannot parse it, and these paths are handed to PowerShell.
pub fn plain_path(path: PathBuf) -> PathBuf {
    let Some(text) = path.to_str() else { return path };
    let Some(rest) = text.strip_prefix(r"\\?\") else { return path };
    if let Some(unc) = rest.strip_prefix(r"UNC\") {
        return PathBuf::from(format!(r"\\{unc}"));
    }
    PathBuf::from(rest)
}

pub fn is_extracted(dir: &Path) -> bool {
    dir.join("playbook.conf").is_file() && front_door(dir).is_file()
}

/// Unpacks an .apbx beneath `root`, a directory this app owns. The package is
/// written and validated in a private staging directory first, then
/// published as `<root>/<version>_<digest>`. That directory is never written
/// again: an archive with the same content is recognised by its digest and
/// the existing directory returned as it is; different content of the same
/// version gets a directory of its own, leaving the first untouched.
///
/// Published directories are never removed: another window, a draft or an
/// install record may still point at one, and removing it would defeat the
/// identity scheme.
pub fn extract_into(
    apbx: &Path,
    root: &Path,
    mut progress: impl FnMut(usize, usize),
) -> Result<(PathBuf, Manifest)> {
    let file = fs::File::open(apbx).with_context(|| format!("open {}", apbx.display()))?;
    let mut archive = zip::ZipArchive::new(file).context("read the package archive")?;

    // Read the manifest first so the target directory carries the real version.
    let manifest = {
        let mut entry = archive
            .by_name_decrypt("playbook.conf", APBX_PASSWORD.as_bytes())
            .context("the package has no playbook.conf")?;
        let mut text = String::new();
        entry.read_to_string(&mut text).context("read playbook.conf")?;
        parse(&text)?
    };
    let version = validate_version(&manifest.version)?.to_owned();
    let identity = PackageIdentity { version: version.clone(), sha256: sha256_file(apbx)? };

    fs::create_dir_all(root).with_context(|| format!("create {}", root.display()))?;
    let root = plain_path(root.canonicalize().with_context(|| format!("resolve {}", root.display()))?);
    sweep_leftovers(&root);

    let target = root.join(identity.directory_name());
    anyhow::ensure!(
        target.parent() == Some(root.as_path()) && is_plain_component(&target),
        "the package version {version:?} does not name a cache directory"
    );
    // The same bytes were unpacked before: the directory is immutable, so
    // it still holds exactly this package.
    if let Some(published) = find_published(&root, &identity) {
        let total = archive.len();
        progress(total, total);
        return Ok((published, manifest));
    }

    let staging = create_unique_dir(&root, &format!("{STAGING_PREFIX}{version}-"))?;
    let result = (|| -> Result<PathBuf> {
        extract_entries(&mut archive, &staging, &mut progress)?;
        if !is_extracted(&staging) {
            let version = version.clone();
            return Err(if predates_front_door(&version) {
                Unsupported { version }.into()
            } else {
                Incomplete { version }.into()
            });
        }
        reject_reparse_points(&staging)?;
        fs::write(staging.join(IDENTITY_FILE), serde_json::to_string_pretty(&identity)?)
            .context("record the package identity")?;
        publish(&staging, &root, &identity)
    })();
    if result.is_err() {
        let _ = fs::remove_dir_all(&staging);
    }
    result.map(|published| (published, manifest))
}

/// The directories one identity may be published under: its name, and a
/// few numbered alternatives for when that name is occupied by something
/// that is not this package (a damaged remnant, say).
fn candidates(root: &Path, identity: &PackageIdentity) -> Vec<PathBuf> {
    let name = identity.directory_name();
    std::iter::once(root.join(&name)).chain((2..=9).map(|n| root.join(format!("{name}-{n}")))).collect()
}

/// A complete published copy of exactly this package, if there is one.
fn find_published(root: &Path, identity: &PackageIdentity) -> Option<PathBuf> {
    candidates(root, identity).into_iter().find(|dir| holds(dir, identity))
}

fn holds(dir: &Path, identity: &PackageIdentity) -> bool {
    is_extracted(dir) && self::identity(dir).as_ref() == Some(identity)
}

/// Whether the path ends in an ordinary name, not `..`, a root or a drive.
fn is_plain_component(path: &Path) -> bool {
    matches!(path.components().next_back(), Some(Component::Normal(_)))
}

fn extract_entries<R: Read + std::io::Seek>(
    archive: &mut zip::ZipArchive<R>,
    staging: &Path,
    progress: &mut impl FnMut(usize, usize),
) -> Result<()> {
    let total = archive.len();
    for index in 0..total {
        let mut entry = archive
            .by_index_decrypt(index, APBX_PASSWORD.as_bytes())
            .with_context(|| format!("read entry {index}"))?;
        let Some(relative) = entry.enclosed_name() else {
            anyhow::bail!("the package contains an unsafe path: {}", entry.name());
        };
        check_entry_components(&relative).with_context(|| format!("unsafe entry {}", entry.name()))?;
        let path = staging.join(&relative);
        anyhow::ensure!(path.starts_with(staging), "the package contains an unsafe path: {}", entry.name());
        if entry.is_dir() {
            fs::create_dir_all(&path)?;
        } else {
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent)?;
            }
            let mut output = fs::File::create(&path).with_context(|| format!("create {}", path.display()))?;
            std::io::copy(&mut entry, &mut output).with_context(|| format!("write {}", path.display()))?;
        }
        progress(index + 1, total);
    }
    Ok(())
}

/// Beyond `enclosed_name()`: every component must be an ordinary name with no
/// drive, stream or device syntax, because the files are later run elevated.
fn check_entry_components(relative: &Path) -> Result<()> {
    const DEVICES: [&str; 22] = [
        "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
        "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
    ];
    for component in relative.components() {
        let Component::Normal(name) = component else {
            anyhow::bail!("path component {component:?} is not a plain name");
        };
        let name = name.to_string_lossy();
        anyhow::ensure!(!name.is_empty(), "empty path component");
        anyhow::ensure!(!name.contains(':'), "path component {name:?} contains a colon");
        anyhow::ensure!(
            !name.ends_with('.') && !name.ends_with(' '),
            "path component {name:?} has a trailing dot or space"
        );
        let stem = name.split('.').next().unwrap_or_default().to_ascii_uppercase();
        anyhow::ensure!(!DEVICES.contains(&stem.as_str()), "path component {name:?} is a device name");
    }
    Ok(())
}

/// A junction or symbolic link inside the package could redirect the
/// elevated installer; the front door refuses them too.
fn reject_reparse_points(dir: &Path) -> Result<()> {
    for entry in fs::read_dir(dir).with_context(|| format!("list {}", dir.display()))? {
        let entry = entry?;
        let path = entry.path();
        let metadata = fs::symlink_metadata(&path)?;
        if is_reparse_point(&metadata) {
            anyhow::bail!("the package contains a link at {}", path.display());
        }
        if metadata.is_dir() {
            reject_reparse_points(&path)?;
        }
    }
    Ok(())
}

/// Publishes the validated staging directory under the package's name, or
/// the first free numbered alternative. A published directory is never
/// replaced, moved or removed here: if another extractor of the same bytes
/// published first (between this extractor's reuse check and its rename),
/// that copy is the package and this staging directory is simply dropped; a
/// path occupied by anything else is left alone and the next name tried.
fn publish(staging: &Path, root: &Path, identity: &PackageIdentity) -> Result<PathBuf> {
    // A move refused while nothing sits at the destination is a lock on the
    // staging tree (a scanner reading the freshly unpacked files), not an
    // occupied name; it is retried for a while before being reported as such.
    const LOCK_ATTEMPTS: u32 = 40;
    const LOCK_PAUSE: Duration = Duration::from_millis(500);
    let mut locked_attempts = 0;
    for candidate in candidates(root, identity) {
        if holds(&candidate, identity) {
            let _ = fs::remove_dir_all(staging);
            return Ok(candidate);
        }
        loop {
            match move_without_replacing(staging, &candidate) {
                Ok(()) => return Ok(candidate),
                // Taken (at the check, or since): by a concurrent extractor of
                // the same bytes (reuse it) or by something else (next name).
                Err(Occupied) if candidate.exists() => {
                    if holds(&candidate, identity) {
                        let _ = fs::remove_dir_all(staging);
                        return Ok(candidate);
                    }
                    break;
                }
                Err(Occupied) => {
                    locked_attempts += 1;
                    if locked_attempts >= LOCK_ATTEMPTS {
                        anyhow::bail!(
                            "the unpacked package under {} could not be moved into place: Windows refused the move for {} seconds, so another program is probably still reading it",
                            staging.display(),
                            (LOCK_PAUSE * LOCK_ATTEMPTS).as_secs()
                        );
                    }
                    std::thread::sleep(LOCK_PAUSE);
                }
                Err(Failed(error)) => {
                    return Err(error).with_context(|| format!("publish {}", candidate.display()));
                }
            }
        }
    }
    anyhow::bail!(
        "every directory name for {} under {} is occupied",
        identity.directory_name(),
        root.display()
    )
}

use MoveOutcome::{Failed, Occupied};

enum MoveOutcome {
    /// Something already sits at the destination; it was left as it was.
    Occupied,
    Failed(std::io::Error),
}

/// Moves a directory to a path that must not exist yet. `std::fs::rename`
/// replaces an existing file or empty directory on Windows, so publication
/// uses the move without the replace flag: whatever occupies the
/// destination, however briefly it has been there, is never overwritten.
fn move_without_replacing(from: &Path, to: &Path) -> std::result::Result<(), MoveOutcome> {
    use windows::Win32::Foundation::{
        ERROR_ACCESS_DENIED, ERROR_ALREADY_EXISTS, ERROR_FILE_EXISTS, WIN32_ERROR,
    };
    use windows::Win32::Storage::FileSystem::{MOVE_FILE_FLAGS, MoveFileExW};
    use windows::core::HSTRING;
    let (from, to) = (HSTRING::from(from.as_os_str()), HSTRING::from(to.as_os_str()));
    match unsafe { MoveFileExW(&from, &to, MOVE_FILE_FLAGS(0)) } {
        Ok(()) => Ok(()),
        Err(error) => match WIN32_ERROR((error.code().0 & 0xFFFF) as u32) {
            ERROR_ALREADY_EXISTS | ERROR_FILE_EXISTS | ERROR_ACCESS_DENIED => Err(Occupied),
            code => Err(Failed(std::io::Error::from_raw_os_error(code.0 as i32))),
        },
    }
}

fn unique_path(root: &Path, prefix: &str) -> PathBuf {
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    root.join(format!("{prefix}{}-{nanos:x}", std::process::id()))
}

fn create_unique_dir(root: &Path, prefix: &str) -> Result<PathBuf> {
    for _ in 0..16 {
        let path = unique_path(root, prefix);
        match fs::create_dir(&path) {
            Ok(()) => return Ok(path),
            Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(error) => return Err(error).with_context(|| format!("create {}", path.display())),
        }
    }
    anyhow::bail!("could not create a staging directory under {}", root.display())
}

/// Removes staging directories left by an interrupted run. Recent ones may
/// belong to another running instance.
fn sweep_leftovers(root: &Path) {
    const MIN_AGE: Duration = Duration::from_secs(60 * 60);
    let Ok(entries) = fs::read_dir(root) else { return };
    for entry in entries.flatten() {
        let name = entry.file_name();
        let name = name.to_string_lossy();
        if !name.starts_with(STAGING_PREFIX) {
            continue;
        }
        let old = entry
            .metadata()
            .and_then(|m| m.modified())
            .ok()
            .and_then(|modified| SystemTime::now().duration_since(modified).ok())
            .is_some_and(|age| age > MIN_AGE);
        if old {
            let _ = fs::remove_dir_all(entry.path());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::{TempDir, apbx};

    #[test]
    fn browser_artwork_is_optional_and_resolved_from_the_package() {
        let temp = TempDir::new("browser-artwork");
        let manifest = Manifest::builtin();
        let brave =
            manifest.pages.iter().flat_map(|p| &p.options).find(|o| o.name == "browser-brave").unwrap();
        assert_eq!(brave.image.as_deref(), Some("brave"));
        assert_eq!(brave.image_path(temp.path()), None);
        fs::create_dir(temp.path().join("Images")).unwrap();
        let path = temp.path().join("Images/brave.png");
        fs::write(&path, b"artwork").unwrap();
        assert_eq!(brave.image_path(temp.path()), Some(path));
        for name in [None, Some("../brave"), Some(r"C:\brave"), Some("https://example.com/logo"), Some("")] {
            let mut option = brave.clone();
            option.image = name.map(str::to_owned);
            assert_eq!(option.image_path(temp.path()), None);
        }
    }

    #[test]
    fn versions_that_name_a_cache_directory_are_accepted() {
        for version in ["0.6.0", " 0.6.0 ", "0.5.0-hotfix", "10.20.30-rc.1", "0.6.0-a-b.c"] {
            assert!(validate_version(version).is_ok(), "{version:?}");
        }
        assert_eq!(validate_version(" 0.6.0 ").unwrap(), "0.6.0");
    }

    #[test]
    fn versions_that_could_escape_the_cache_are_rejected() {
        for version in [
            "",
            " ",
            ".",
            "..",
            "../x",
            "..\\..\\unrelated",
            "C:\\audit-example\\unrelated",
            "/0.6.0",
            "\\0.6.0",
            "0.6.0/x",
            "0.6.0\\x",
            "0.6",
            "0.6.0.1",
            "v0.6.0",
            "0.6.0-",
            "0.6.0-.",
            "0.6.0-x/y",
            "0.6.0-x\\y",
            "0.6.0-a b",
        ] {
            assert!(validate_version(version).is_err(), "{version:?} must be rejected");
        }
    }

    #[test]
    fn entry_components_with_windows_special_syntax_are_rejected() {
        assert!(check_entry_components(Path::new("Executables/a.ps1")).is_ok());
        for bad in ["Executables/file:stream", "CON", "Executables/nul.txt", "Executables/trailing.", "x/aux"]
        {
            assert!(check_entry_components(Path::new(bad)).is_err(), "{bad:?}");
        }
    }

    #[test]
    fn a_valid_package_is_published_under_its_version_and_digest() {
        let temp = TempDir::new("playbook-valid");
        let package = apbx::write(&temp.path().join("valid.apbx"), &apbx::valid("0.6.0"));
        let root = temp.path().join("Playbooks");
        let mut seen = Vec::new();
        let (dir, manifest) = extract_into(&package, &root, |done, total| seen.push((done, total))).unwrap();
        // Progress once per entry, ending at the total.
        let total = seen.last().unwrap().1;
        assert_eq!(seen.len(), total);
        assert_eq!(seen.last(), Some(&(total, total)));
        assert_eq!(manifest.version, "0.6.0");
        let digest = sha256_file(&package).unwrap();
        assert_eq!(dir, plain_path(root.canonicalize().unwrap()).join(format!("0.6.0_{}", &digest[..16])));
        assert!(is_extracted(&dir));
        assert_eq!(identity(&dir), Some(PackageIdentity { version: "0.6.0".into(), sha256: digest }));
        assert!(apbx::leftovers(&root).is_empty());
    }

    #[test]
    fn an_escaping_version_never_touches_anything_outside_the_cache() {
        let temp = TempDir::new("playbook-escape");
        let root = temp.path().join("Playbooks");
        let outside = temp.path().join("unrelated");
        fs::create_dir_all(&outside).unwrap();
        fs::write(outside.join("keep.txt"), "keep").unwrap();
        for version in ["", "..", "..\\..\\unrelated", &outside.display().to_string()] {
            let package = apbx::write(&temp.path().join("escape.apbx"), &apbx::valid(version));
            let error = extract_into(&package, &root, |_, _| {}).unwrap_err();
            assert!(error.to_string().contains("version"), "{version:?}: {error:#}");
        }
        assert!(outside.join("keep.txt").is_file());
        assert!(apbx::leftovers(&root).is_empty());
    }

    #[test]
    fn only_versions_before_the_front_door_predate_it() {
        for version in ["0.5.0", "0.5.0-hotfix", "v0.4", "0.3.2"] {
            assert!(predates_front_door(version), "{version}");
        }
        // Suffixes sort after their base release (Atlas tags hotfixes that way).
        for version in ["0.6.0", "0.6.0-rc.1", "v0.7.0", "1.0.0", "next"] {
            assert!(!predates_front_door(version), "{version}");
        }
    }

    #[test]
    fn failed_extractions_keep_the_previous_package_and_leave_nothing_behind() {
        let temp = TempDir::new("playbook-replace");
        let root = temp.path().join("Playbooks");
        let good = apbx::write(&temp.path().join("good.apbx"), &apbx::valid("0.6.0"));
        let (dir, _) = extract_into(&good, &root, |_, _| {}).unwrap();
        let marker = front_door(&dir);
        let before = fs::read(&marker).unwrap();

        // No front door: fails validation after extraction. An older package
        // predates it; a current one is incomplete.
        let old = apbx::write(&temp.path().join("old.apbx"), &apbx::without_front_door("0.5.0"));
        let error = extract_into(&old, &root, |_, _| {}).unwrap_err();
        assert_eq!(error.downcast_ref::<Unsupported>(), Some(&Unsupported { version: "0.5.0".into() }));
        for version in ["0.6.0", "0.6.1"] {
            let damaged = apbx::write(&temp.path().join("damaged.apbx"), &apbx::without_front_door(version));
            let error = extract_into(&damaged, &root, |_, _| {}).unwrap_err();
            assert_eq!(error.downcast_ref::<Incomplete>(), Some(&Incomplete { version: version.into() }));
        }
        // Traversal entry: fails during extraction.
        let unsafe_entry =
            apbx::write(&temp.path().join("unsafe.apbx"), &apbx::with_entry("0.6.0", "../escape.txt"));
        assert!(extract_into(&unsafe_entry, &root, |_, _| {}).is_err());
        // Corrupt data: fails mid-copy.
        let corrupt = apbx::write(&temp.path().join("corrupt.apbx"), &apbx::corrupted("0.6.0"));
        assert!(extract_into(&corrupt, &root, |_, _| {}).is_err());

        assert_eq!(fs::read(&marker).unwrap(), before, "the previous package must survive");
        assert!(!temp.path().join("escape.txt").exists());
        assert!(apbx::leftovers(&root).is_empty());
    }

    /// Two windows can each prepare "0.6.0"; neither may change what the
    /// other has read and is about to run.
    #[test]
    fn different_content_of_the_same_version_never_shares_a_directory() {
        let temp = TempDir::new("playbook-same");
        let root = temp.path().join("Playbooks");
        let first = apbx::write(&temp.path().join("a.apbx"), &apbx::valid_with_builds("0.6.0", &[26200]));
        let (dir_a, manifest_a) = extract_into(&first, &root, |_, _| {}).unwrap();
        let door_a = fs::read(front_door(&dir_a)).unwrap();
        let second = apbx::write(&temp.path().join("b.apbx"), &apbx::valid_with_builds("0.6.0", &[99999]));
        let (dir_b, manifest_b) = extract_into(&second, &root, |_, _| {}).unwrap();
        assert_ne!(dir_a, dir_b, "same version, different bytes: different directories");
        assert_eq!(manifest_a.supported_builds, vec![26200]);
        assert_eq!(manifest_b.supported_builds, vec![99999]);
        // What A read still describes what is at A's path.
        assert_eq!(read_manifest(&dir_a).unwrap().supported_builds, vec![26200]);
        assert_eq!(fs::read(front_door(&dir_a)).unwrap(), door_a);
        assert!(apbx::leftovers(&root).is_empty());

        // The same bytes again are recognised and reused, not re-unpacked.
        fs::write(dir_a.join("marker.txt"), "still here").unwrap();
        let mut reported = Vec::new();
        let (dir_again, _) = extract_into(&first, &root, |done, total| reported.push((done, total))).unwrap();
        assert_eq!(dir_again, dir_a);
        assert!(dir_a.join("marker.txt").is_file(), "a reused directory is not touched");
        assert_eq!(reported.len(), 1, "reuse reports completion once");

        // A damaged copy under the right name is neither reused nor touched:
        // the package is published under the next name.
        fs::remove_file(front_door(&dir_b)).unwrap();
        fs::write(dir_b.join("remnant.txt"), "left behind").unwrap();
        let (dir_b2, _) = extract_into(&second, &root, |_, _| {}).unwrap();
        assert_ne!(dir_b2, dir_b);
        assert_eq!(
            dir_b2,
            plain_path(root.canonicalize().unwrap())
                .join(format!("{}-2", dir_b.file_name().unwrap().to_string_lossy()))
        );
        assert!(is_extracted(&dir_b2));
        assert!(dir_b.join("remnant.txt").is_file(), "the occupied path is left as it was");
        assert_eq!(extract_into(&second, &root, |_, _| {}).unwrap().0, dir_b2);
        assert!(apbx::leftovers(&root).is_empty());
    }

    /// A path occupied by something that is not the package (a stray file, an
    /// empty directory) is never replaced, whatever `rename` would do.
    #[test]
    fn an_occupied_publication_name_is_left_untouched_and_the_next_used() {
        let temp = TempDir::new("playbook-occupied");
        let root = temp.path().join("Playbooks");
        let package = apbx::write(&temp.path().join("a.apbx"), &apbx::valid("0.6.0"));
        let digest = sha256_file(&package).unwrap();
        let name = format!("0.6.0_{}", &digest[..16]);
        fs::create_dir_all(&root).unwrap();
        // A regular file with content sits where the package would go.
        fs::write(root.join(&name), b"preserve me").unwrap();
        let (published, _) = extract_into(&package, &root, |_, _| {}).unwrap();
        assert_eq!(published, plain_path(root.canonicalize().unwrap()).join(format!("{name}-2")));
        assert_eq!(fs::read(root.join(&name)).unwrap(), b"preserve me");
        assert!(is_extracted(&published));

        // An empty directory is not a package either, and stays empty.
        let temp = TempDir::new("playbook-occupied-dir");
        let root = temp.path().join("Playbooks");
        let package = apbx::write(&temp.path().join("a.apbx"), &apbx::valid("0.6.0"));
        // A fresh archive carries fresh timestamps, so its digest and name differ.
        let name = format!("0.6.0_{}", &sha256_file(&package).unwrap()[..16]);
        fs::create_dir_all(root.join(&name)).unwrap();
        let (published, _) = extract_into(&package, &root, |_, _| {}).unwrap();
        assert_eq!(published, plain_path(root.canonicalize().unwrap()).join(format!("{name}-2")));
        assert_eq!(fs::read_dir(root.join(&name)).unwrap().count(), 0, "the empty directory is untouched");
        // The move itself refuses an occupied destination of either kind.
        let staging = temp.path().join("staging");
        fs::create_dir_all(&staging).unwrap();
        assert!(matches!(move_without_replacing(&staging, &root.join(&name)), Err(Occupied)));
        assert!(matches!(move_without_replacing(&staging, &published), Err(Occupied)));
        let file = temp.path().join("file.txt");
        fs::write(&file, "x").unwrap();
        assert!(matches!(move_without_replacing(&staging, &file), Err(Occupied)));
        assert!(staging.is_dir(), "a refused move leaves the source in place");
        assert!(apbx::leftovers(&root).is_empty());
    }

    /// Two extractors of the same archive both pass the reuse check before
    /// either has published. The second must adopt the first's directory,
    /// not replace it.
    #[test]
    fn a_concurrent_extractor_of_the_same_bytes_reuses_the_winner_and_replaces_nothing() {
        let temp = TempDir::new("playbook-concurrent");
        let root = temp.path().join("Playbooks");
        let package = apbx::write(&temp.path().join("a.apbx"), &apbx::valid("0.6.0"));
        // The second extractor's staging, prepared before the first publishes.
        let scratch = temp.path().join("Scratch");
        let (staged, _) = extract_into(&package, &scratch, |_, _| {}).unwrap();
        fs::create_dir_all(&root).unwrap();
        let root = plain_path(root.canonicalize().unwrap());
        let staging = root.join(format!("{STAGING_PREFIX}0.6.0-test"));
        fs::rename(&staged, &staging).unwrap();
        // The first extractor publishes and its caller starts using the path.
        let (winner, _) = extract_into(&package, &root, |_, _| {}).unwrap();
        fs::write(winner.join("in-use.txt"), "held by the first caller").unwrap();
        let door_before = fs::metadata(front_door(&winner)).unwrap().modified().unwrap();
        // The second extractor now publishes its finished staging.
        let identity = identity(&winner).unwrap();
        let published = publish(&staging, &root, &identity).unwrap();
        assert_eq!(published, winner, "the loser adopts the winner's directory");
        assert!(winner.join("in-use.txt").is_file(), "nothing in the winner's directory was replaced");
        assert_eq!(fs::metadata(front_door(&winner)).unwrap().modified().unwrap(), door_before);
        assert!(!staging.exists(), "only the loser's private staging goes");
        assert!(apbx::leftovers(&root).is_empty());
    }

    #[test]
    fn a_move_refused_by_an_open_handle_is_retried_rather_than_called_occupied() {
        let temp = TempDir::new("playbook-locked");
        let package = apbx::write(&temp.path().join("valid.apbx"), &apbx::valid("0.6.0"));
        let root = temp.path().join("Playbooks");
        fs::create_dir_all(&root).unwrap();
        let staging = create_unique_dir(&root, &format!("{STAGING_PREFIX}0.6.0-")).unwrap();
        // A tree that would publish, with one of its files held open the way a
        // scanner holds a freshly written file.
        fs::write(staging.join("scanned.txt"), "contents").unwrap();
        let held = fs::File::open(staging.join("scanned.txt")).unwrap();
        let identity = PackageIdentity { version: "0.6.0".into(), sha256: sha256_file(&package).unwrap() };
        let expected = root.join(identity.directory_name());
        assert!(
            matches!(move_without_replacing(&staging, &expected), Err(Occupied)),
            "a held file refuses the move"
        );
        let publisher = {
            let (staging, root, identity) = (staging.clone(), root.clone(), identity.clone());
            std::thread::spawn(move || publish(&staging, &root, &identity))
        };
        std::thread::sleep(Duration::from_millis(1200));
        drop(held);
        let published = publisher.join().unwrap().unwrap();
        assert_eq!(published, expected);
        assert!(published.join("scanned.txt").is_file());
    }

    #[test]
    fn plain_path_drops_only_the_verbatim_prefix() {
        assert_eq!(plain_path(PathBuf::from(r"\\?\C:\Users\x")), PathBuf::from(r"C:\Users\x"));
        assert_eq!(plain_path(PathBuf::from(r"\\?\UNC\server\share\x")), PathBuf::from(r"\\server\share\x"));
        assert_eq!(plain_path(PathBuf::from(r"C:\Users\x")), PathBuf::from(r"C:\Users\x"));
        assert_eq!(plain_path(PathBuf::from(r"\\server\share")), PathBuf::from(r"\\server\share"));
        // What PowerShell receives must not start with the prefix.
        let temp = TempDir::new("playbook-plain");
        let package = apbx::write(&temp.path().join("valid.apbx"), &apbx::valid("0.6.0"));
        let (dir, _) = extract_into(&package, &temp.path().join("Playbooks"), |_, _| {}).unwrap();
        assert!(!dir.to_string_lossy().starts_with(r"\\?\"), "{}", dir.display());
    }
}
