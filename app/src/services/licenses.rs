//! Notices travel with the standalone executable, including copies staged on media.
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, PoisonError};

pub const TEXT: &str = concat!(
    "ATLAS PROJECT LICENSE\n\n",
    include_str!("../../../LICENSE"),
    "\n\nGPUI INPUT ADAPTATION\nCopyright Zed Industries. Atlas adds themed, labelled username input.\n\n",
    include_str!("../../licenses/GPUI-input-APACHE-2.0.txt"),
    "\n\n",
    include_str!("../../licenses/THIRD-PARTY-NOTICES.txt"),
);

/// Export only to a new file, so command-line extraction cannot overwrite user work.
pub fn write_to(path: &Path) -> std::io::Result<()> {
    let mut file = std::fs::OpenOptions::new().write(true).create_new(true).open(path)?;
    file.write_all(TEXT.as_bytes())?;
    file.sync_all()
}

/// The temporary text copy `open` shows: written once per process and
/// reused while it is intact, so opening the notices again adds no files.
fn temp_copy() -> anyhow::Result<PathBuf> {
    static COPY: Mutex<Option<PathBuf>> = Mutex::new(None);
    let mut copy = COPY.lock().unwrap_or_else(PoisonError::into_inner);
    if let Some(path) = copy.as_ref()
        && std::fs::metadata(path).is_ok_and(|file| file.len() == TEXT.len() as u64)
    {
        return Ok(path.clone());
    }
    let unique = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_nanos();
    let path = std::env::temp_dir().join(format!("Atlas-licenses-{}-{unique}.txt", std::process::id()));
    write_to(&path)?;
    *copy = Some(path.clone());
    Ok(path)
}

/// Opens a text copy of the notices in the default editor. Blocks while
/// the copy is written and the shell starts the editor; call it off the
/// UI thread.
pub fn open() -> anyhow::Result<()> {
    super::system::shell_execute("open", &temp_copy()?.to_string_lossy())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extraction_preserves_existing_files() {
        let temp = crate::services::test_support::TempDir::new("notices");
        let path = temp.path().join("THIRD-PARTY-NOTICES.txt");
        write_to(&path).unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), TEXT);
        assert_eq!(write_to(&path).unwrap_err().kind(), std::io::ErrorKind::AlreadyExists);
    }

    #[test]
    fn the_notices_are_written_once_and_rewritten_only_when_the_copy_is_gone() {
        let first = temp_copy().unwrap();
        assert_eq!(std::fs::read_to_string(&first).unwrap(), TEXT);
        assert_eq!(temp_copy().unwrap(), first, "a second opening reuses the copy");
        std::fs::remove_file(&first).unwrap();
        let second = temp_copy().unwrap();
        assert_eq!(std::fs::read_to_string(&second).unwrap(), TEXT);
        std::fs::remove_file(second).unwrap();
    }
}
