//! Helpers for service tests: disposable directories and registry keys, stub
//! front doors and small synthetic Atlas packages. Nothing here touches the
//! real app data, the registry keys the app reads, or the machine's Atlas
//! state.

use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use windows_registry::{CURRENT_USER, Key};

fn unique_suffix() -> String {
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    format!("{}-{nanos:x}", std::process::id())
}

/// A fresh directory under the system temp folder, removed when dropped.
pub struct TempDir(PathBuf);

impl TempDir {
    pub fn new(name: &str) -> Self {
        let path = std::env::temp_dir().join("atlas-app-tests").join(format!("{name}-{}", unique_suffix()));
        fs::create_dir_all(&path).expect("create a temporary test directory");
        Self(path)
    }

    pub fn path(&self) -> &Path {
        &self.0
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

/// A fresh key under `HKCU\Software\AtlasOS\AppTests`, removed with
/// everything in it when dropped, so a failing test leaves nothing behind.
pub struct TestKey {
    path: String,
    pub key: Key,
}

impl TestKey {
    pub fn new(name: &str) -> Self {
        let path = format!(r"Software\AtlasOS\AppTests\{name}-{}", unique_suffix());
        let key = CURRENT_USER.create(&path).expect("create a test key under HKCU");
        Self { path, key }
    }

    /// Its path under HKCU, for code that opens keys by path.
    pub fn path(&self) -> &str {
        &self.path
    }
}

impl Drop for TestKey {
    fn drop(&mut self) {
        let _ = CURRENT_USER.remove_tree(&self.path);
    }
}

/// The real front door's text before its parameter block, and the inside of
/// that block.
pub fn front_door_parts() -> (&'static str, &'static str) {
    let script = include_str!("../../../package/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
    let (head, rest) = script.split_once("\nparam(").expect("the front door's parameter block");
    let (block, _) = rest.split_once("\n)").expect("the end of the front door's parameter block");
    (head, block)
}

/// A front door that runs `body` behind the real script's help and parameter
/// block, so a stub binds a launch's arguments exactly as the front door does.
pub fn front_door_script(body: &str) -> String {
    let (head, block) = front_door_parts();
    // The byte order mark makes Windows PowerShell 5.1 read a body's non-ASCII text as UTF-8.
    format!("\u{feff}{}\nparam({block}\n)\r\n{body}\r\n", head.trim_start_matches('\u{feff}'))
}

/// Synthetic Atlas packages, encrypted as releases are.
pub mod package {
    use std::io::Write;
    use std::path::{Path, PathBuf};

    use zip::write::{FileOptions, SimpleFileOptions};
    use zip::{AesMode, ZipWriter};

    use crate::services::package::PACKAGE_PASSWORD;

    pub const FRONT_DOOR: &str = "Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1";
    pub const MANIFEST: &str = "atlas.json";

    pub struct Entry {
        pub name: String,
        pub data: Vec<u8>,
        pub encrypted: bool,
        /// The password it's encrypted under, when it isn't Atlas's.
        pub password: Option<&'static str>,
    }

    pub struct Package {
        pub entries: Vec<Entry>,
        /// Bytes that locate the damage: the 8 bytes after them are flipped
        /// once the archive is written.
        pub corrupt_marker: Option<Vec<u8>>,
    }

    /// A manifest with one Defender choice, supporting `builds`.
    pub fn manifest(version: &str, builds: &[u32]) -> String {
        let builds: Vec<_> = builds.iter().map(|build| serde_json::json!({ "build": build })).collect();
        manifest_with_choices(
            version,
            &builds,
            serde_json::json!([{
                "id": "defender",
                "kind": "single",
                "default": "defender-enable",
                "options": [
                    { "id": "defender-enable", "label": "Keep Defender" },
                    { "id": "defender-disable", "label": "Remove Defender" },
                ],
            }]),
        )
    }

    /// A manifest declaring `choices`, as `atlas.json` lists them.
    pub fn manifest_with_choices(
        version: &str,
        builds: &[serde_json::Value],
        choices: serde_json::Value,
    ) -> String {
        serde_json::json!({
            "schemaVersion": 1,
            "version": version,
            "minimumManagerVersion": "0.6.0",
            "supportedBuilds": builds,
            "updatableFrom": [],
            "requirements": [],
            "choices": choices,
        })
        .to_string()
    }

    fn entry(name: &str, data: impl Into<Vec<u8>>) -> Entry {
        Entry { name: name.to_owned(), data: data.into(), encrypted: true, password: None }
    }

    pub fn valid(version: &str) -> Package {
        Package {
            entries: vec![
                entry(MANIFEST, manifest(version, &[26100])),
                entry(FRONT_DOOR, "param([string[]]$Option) exit 0\r\n"),
                entry("Executables/AtlasModules/Scripts/Initialize-AtlasPowerShell.ps1", "# bootstrap\r\n"),
            ],
            corrupt_marker: None,
        }
    }

    /// A valid package whose manifest supports `builds`; the content (and so
    /// the digest) differs per build list.
    pub fn valid_with_builds(version: &str, builds: &[u32]) -> Package {
        let mut package = valid(version);
        package.entries[0] = entry(MANIFEST, manifest(version, builds));
        package
    }

    /// An AME Wizard package as Atlas releases before 0.6 came: its manifest
    /// is playbook.conf, under another password.
    pub fn ame_wizard(version: &str) -> Package {
        let conf = format!("<Playbook><Version>{version}</Version></Playbook>");
        Package {
            entries: vec![Entry {
                name: "playbook.conf".to_owned(),
                data: conf.into_bytes(),
                encrypted: true,
                password: Some("another password"),
            }],
            corrupt_marker: None,
        }
    }

    /// A valid package whose front door runs `body` (Windows PowerShell 5.1)
    /// behind the real front door's parameter block, so a model test can
    /// install it.
    pub fn with_front_door(version: &str, body: &str) -> Package {
        let mut package = valid(version);
        package.entries[1] = entry(FRONT_DOOR, super::front_door_script(body));
        package
    }

    pub fn without_front_door(version: &str) -> Package {
        let mut package = valid(version);
        package.entries.retain(|e| e.name != FRONT_DOOR);
        package
    }

    pub fn with_entry(version: &str, name: &str) -> Package {
        let mut package = valid(version);
        package.entries.push(entry(name, "extra"));
        package
    }

    /// A package whose last (stored, unencrypted) entry fails its CRC check
    /// while it is being copied out.
    pub fn corrupted(version: &str) -> Package {
        let mut package = valid(version);
        let marker = b"ATLAS-CORRUPTION-MARKER-".repeat(64);
        package.entries.push(Entry {
            name: "Executables/big.bin".to_owned(),
            data: marker.clone(),
            encrypted: false,
            password: None,
        });
        package.corrupt_marker = Some(marker[..24].to_vec());
        package
    }

    pub fn write(path: &Path, package: &Package) -> PathBuf {
        let file = std::fs::File::create(path).expect("create the test package");
        let mut writer = ZipWriter::new(file);
        for entry in &package.entries {
            let mut options: SimpleFileOptions =
                FileOptions::default().compression_method(zip::CompressionMethod::Stored);
            if entry.encrypted {
                options =
                    options.with_aes_encryption(AesMode::Aes256, entry.password.unwrap_or(PACKAGE_PASSWORD));
            }
            writer.start_file(&entry.name, options).expect("start an entry");
            writer.write_all(&entry.data).expect("write an entry");
        }
        writer.finish().expect("finish the test package");
        if let Some(marker) = &package.corrupt_marker {
            let mut bytes = std::fs::read(path).unwrap();
            let start = bytes.windows(marker.len()).position(|w| w == marker.as_slice()).expect("marker");
            for byte in &mut bytes[start + marker.len()..start + marker.len() + 8] {
                *byte ^= 0xFF;
            }
            std::fs::write(path, bytes).unwrap();
        }
        path.to_path_buf()
    }

    /// Staging directories still present under a cache root.
    pub fn leftovers(root: &Path) -> Vec<PathBuf> {
        let Ok(entries) = std::fs::read_dir(root) else { return Vec::new() };
        entries
            .flatten()
            .map(|e| e.path())
            .filter(|p| p.file_name().is_some_and(|n| n.to_string_lossy().starts_with('.')))
            .collect()
    }
}
