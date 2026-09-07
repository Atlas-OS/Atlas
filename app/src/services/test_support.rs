//! Helpers for service tests: disposable directories under the system temp
//! folder and small synthetic .apbx packages. Nothing here touches the real
//! app data, the registry hives the app reads, or the machine's Atlas state.

use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

/// A fresh directory that is removed when dropped.
pub struct TempDir(PathBuf);

impl TempDir {
    pub fn new(name: &str) -> Self {
        let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
        let path = std::env::temp_dir()
            .join("atlas-app-tests")
            .join(format!("{name}-{}-{nanos:x}", std::process::id()));
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

/// Synthetic playbook packages.
pub mod apbx {
    use std::io::Write;
    use std::path::{Path, PathBuf};

    use zip::write::{FileOptions, SimpleFileOptions};
    use zip::{AesMode, ZipWriter};

    pub const FRONT_DOOR: &str = "Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1";

    pub struct Entry {
        pub name: String,
        pub data: Vec<u8>,
        pub encrypted: bool,
    }

    pub struct Package {
        pub entries: Vec<Entry>,
        /// Bytes to flip after writing, to simulate a damaged archive.
        pub corrupt_marker: Option<Vec<u8>>,
    }

    pub fn conf(version: &str) -> String {
        conf_with_builds(version, &[26100])
    }

    pub fn conf_with_builds(version: &str, builds: &[u32]) -> String {
        let builds: String = builds.iter().map(|b| format!("<string>{b}</string>")).collect();
        format!(
            "<Playbook><Version>{version}</Version><SupportedBuilds>{builds}</SupportedBuilds><FeaturePages><RadioPage DefaultOption=\"defender-enable\"><Options><RadioOption><Name>defender-enable</Name><Text>Keep Defender</Text></RadioOption><RadioOption><Name>defender-disable</Name><Text>Remove Defender</Text></RadioOption></Options></RadioPage></FeaturePages></Playbook>"
        )
    }

    fn entry(name: &str, data: impl Into<Vec<u8>>) -> Entry {
        Entry { name: name.to_owned(), data: data.into(), encrypted: true }
    }

    pub fn valid(version: &str) -> Package {
        Package {
            entries: vec![
                entry("playbook.conf", conf(version)),
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
        package.entries[0] = entry("playbook.conf", conf_with_builds(version, builds));
        package
    }

    /// A valid package whose front door runs `body` (Windows PowerShell 5.1)
    /// with the real parameter block, so a model test can install it.
    pub fn with_front_door(version: &str, body: &str) -> Package {
        let mut package = valid(version);
        let script = format!(
            "\u{feff}[CmdletBinding()]\r\nparam(\r\n    [Parameter(Mandatory = $true)]\r\n    [ValidatePattern('^[a-z0-9-]+$')]\r\n    [string[]]$Option,\r\n    [switch]$Unattended,\r\n    [switch]$Restart,\r\n    [string]$RestartComment,\r\n    [switch]$KeepStaging\r\n)\r\n{body}\r\n"
        );
        package.entries[1] = entry(FRONT_DOOR, script);
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
    pub fn truncated(version: &str) -> Package {
        let mut package = valid(version);
        let marker = b"ATLAS-CORRUPTION-MARKER-".repeat(64);
        package.entries.push(Entry {
            name: "Executables/big.bin".to_owned(),
            data: marker.clone(),
            encrypted: false,
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
                options = options.with_aes_encryption(AesMode::Aes256, "malte");
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

    /// Staging or retired directories still present under a cache root.
    pub fn leftovers(root: &Path) -> Vec<PathBuf> {
        let Ok(entries) = std::fs::read_dir(root) else { return Vec::new() };
        entries
            .flatten()
            .map(|e| e.path())
            .filter(|p| p.file_name().is_some_and(|n| n.to_string_lossy().starts_with('.')))
            .collect()
    }
}
