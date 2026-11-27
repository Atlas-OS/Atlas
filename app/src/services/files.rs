//! File helpers the services share: JSON documents read and replaced whole,
//! telling a link from the file or directory it stands in for, and stamps
//! that keep the names of files and folders made at the same moment apart.

use std::fs;
use std::io::ErrorKind;
use std::os::windows::fs::MetadataExt;
use std::path::Path;
use std::sync::{Mutex, PoisonError};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde::Serialize;
use serde::de::DeserializeOwned;
use windows::Win32::Storage::FileSystem::FILE_ATTRIBUTE_REPARSE_POINT;

/// A JSON document, or `None` when there is no file. A leading byte order
/// mark is accepted, as Windows PowerShell writes one.
pub fn read_json<T: DeserializeOwned>(path: &Path) -> Result<Option<T>> {
    let text = match fs::read_to_string(path) {
        Ok(text) => text,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(error).with_context(|| format!("read {}", path.display())),
    };
    serde_json::from_str(text.trim_start_matches('\u{feff}'))
        .map(Some)
        .with_context(|| format!("parse {}", path.display()))
}

/// Writes `value` beside `path` and renames it into place, so a reader (this
/// app in another window, or Atlas's scripts) never finds half a document. The
/// temporary file is removed if anything fails.
pub fn write_json_atomically(path: &Path, value: &impl Serialize) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).with_context(|| format!("create {}", parent.display()))?;
    }
    let mut name = path.file_name().context("a file name")?.to_os_string();
    name.push(format!(".{}.tmp", std::process::id()));
    let temp = path.with_file_name(name);
    let written = serde_json::to_vec_pretty(value)
        .map_err(anyhow::Error::from)
        .and_then(|bytes| fs::write(&temp, bytes).with_context(|| format!("write {}", temp.display())))
        .and_then(|()| fs::rename(&temp, path).with_context(|| format!("write {}", path.display())));
    if written.is_err() {
        let _ = fs::remove_file(&temp);
    }
    written
}

/// A junction, symbolic link or other reparse point, from metadata read
/// without following it.
pub fn is_reparse_point(metadata: &fs::Metadata) -> bool {
    metadata.file_attributes() & FILE_ATTRIBUTE_REPARSE_POINT.0 != 0
}

/// Nanoseconds since 1970 for naming a file or folder with this process's
/// id, always later than the last stamp handed out here. Two names asked
/// for in the same tick of the clock, such as the USB drive list and the
/// ISO check starting together, would otherwise be the same.
pub fn unique_stamp() -> u128 {
    static LAST: Mutex<u128> = Mutex::new(0);
    let now = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or_default();
    let mut last = LAST.lock().unwrap_or_else(PoisonError::into_inner);
    *last = now.max(*last + 1);
    *last
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::TempDir;

    #[test]
    fn a_write_that_cannot_be_renamed_into_place_leaves_no_temporary_file() {
        let temp = TempDir::new("files-atomic");
        let path = temp.path().join("session.json");
        // A directory in the way makes the final rename fail.
        fs::create_dir(&path).unwrap();
        assert!(write_json_atomically(&path, &serde_json::json!({"id": "s"})).is_err());
        let names: Vec<_> =
            fs::read_dir(temp.path()).unwrap().flatten().map(|entry| entry.file_name()).collect();
        assert_eq!(names, ["session.json"], "only the directory remains");
    }

    #[test]
    fn stamps_asked_for_together_are_all_different() {
        // Many threads asking at once land in the same clock tick.
        let threads: Vec<_> = (0..8)
            .map(|_| std::thread::spawn(|| (0..1000).map(|_| unique_stamp()).collect::<Vec<_>>()))
            .collect();
        let mut stamps: Vec<u128> = threads.into_iter().flat_map(|thread| thread.join().unwrap()).collect();
        let count = stamps.len();
        stamps.sort_unstable();
        stamps.dedup();
        assert_eq!(stamps.len(), count, "no stamp is handed out twice");
    }

    #[test]
    fn each_stamp_is_later_than_the_one_before() {
        let first = unique_stamp();
        let second = unique_stamp();
        assert!(second > first);
    }
}
