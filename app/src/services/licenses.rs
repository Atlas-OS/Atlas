//! Notices travel with the standalone executable, including copies staged on media.
use std::io::Write;
use std::path::Path;

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

pub fn open() -> anyhow::Result<()> {
    use windows::Win32::UI::Shell::ShellExecuteW;
    use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;
    use windows::core::{HSTRING, PCWSTR};
    let unique = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_nanos();
    let path = std::env::temp_dir().join(format!("Atlas-licenses-{}-{unique}.txt", std::process::id()));
    write_to(&path)?;
    let target = HSTRING::from(path.as_os_str());
    let verb = HSTRING::from("open");
    let result = unsafe {
        ShellExecuteW(None, PCWSTR(verb.as_ptr()), PCWSTR(target.as_ptr()), None, None, SW_SHOWNORMAL)
    };
    anyhow::ensure!(result.0 as usize > 32, "Windows could not open the license notices");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extraction_preserves_existing_files() {
        let path = std::env::temp_dir().join(format!("atlas-notices-test-{}.txt", std::process::id()));
        write_to(&path).unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), TEXT);
        assert_eq!(write_to(&path).unwrap_err().kind(), std::io::ErrorKind::AlreadyExists);
        std::fs::remove_file(path).unwrap();
    }
}
