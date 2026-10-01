//! Registry access that tells a key or value that is absent from one that
//! cannot be read, and the Run entries that reopen the app after a restart.

use anyhow::{Context, Result};
use windows::Win32::Foundation::ERROR_FILE_NOT_FOUND;
use windows_registry::Key;

/// The per-user key whose entries Windows starts at sign-in. Atlas uses Run,
/// not RunOnce: RunOnce entries are consumed the next time Explorer starts,
/// which a sign-out or an Explorer restart brings before the Windows restart
/// they wait for.
pub(super) const RUN_KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Run";

/// The error code a registry call returns for a key or value that does not
/// exist.
pub(super) const NOT_FOUND: i32 = ERROR_FILE_NOT_FOUND.to_hresult().0;

/// Whether a registry key exists. Absence is only concluded from "not
/// found"; any other refusal to open it is reported.
pub(super) fn key_present(root: &Key, path: &str) -> Result<bool> {
    match root.open(path) {
        Ok(_) => Ok(true),
        Err(error) if error.code().0 == NOT_FOUND => Ok(false),
        Err(error) => Err(anyhow::anyhow!("open {path}: {error}")),
    }
}

/// Removes the value `name`. One that is already gone is fine.
pub(super) fn remove_value(key: &Key, name: &str) -> Result<()> {
    match key.remove_value(name) {
        Ok(()) => Ok(()),
        Err(error) if error.code().0 == NOT_FOUND => Ok(()),
        Err(error) => Err(error).with_context(|| format!("remove {name}")),
    }
}

/// The files `PendingFileRenameOperations` (a REG_MULTI_SZ of source/target
/// pairs) will replace or remove at the next restart, as readable paths. A
/// missing value means no renames; any other read failure is reported.
pub(super) fn pending_file_renames(key: &Key) -> Result<Vec<String>> {
    let value = match key.get_value("PendingFileRenameOperations") {
        Ok(value) => value,
        Err(error) if error.code().0 == NOT_FOUND => return Ok(vec![]),
        Err(error) => return Err(anyhow::anyhow!("read PendingFileRenameOperations: {error}")),
    };
    if value.ty() != windows_registry::Type::MultiString {
        return Err(anyhow::anyhow!("PendingFileRenameOperations is not a multi-string"));
    }
    // Decoded by hand: a removal is stored as a source followed by an empty
    // target, and the crate's decoder treats the first empty string as the
    // end of the list, which would hide every entry after a removal.
    let mut entries: Vec<String> = value.as_wide().split(|c| *c == 0).map(String::from_utf16_lossy).collect();
    while entries.last().is_some_and(String::is_empty) {
        entries.pop();
    }
    Ok(entries
        .chunks(2)
        .map(|pair| pair[0].trim())
        .filter(|source| !source.is_empty())
        .map(pending_path_display)
        .collect())
}

/// Strips the kernel-path decorations a rename entry carries (`!` for
/// replace-existing, a `*N` flag group, the `\??\` prefix).
fn pending_path_display(entry: &str) -> String {
    let mut rest = entry.strip_prefix('!').unwrap_or(entry);
    if let Some(after_star) = rest.strip_prefix('*') {
        rest = after_star.trim_start_matches(|c: char| c.is_ascii_digit());
    }
    rest.strip_prefix(r"\??\").unwrap_or(rest).to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::test_support::TestKey;
    use windows_registry::{CURRENT_USER, LOCAL_MACHINE};

    #[test]
    fn reboot_markers_distinguish_absent_from_unreadable() {
        assert!(!key_present(CURRENT_USER, r"SOFTWARE\AtlasOS\AppTests\NoSuchKey").unwrap());
        assert!(key_present(CURRENT_USER, "SOFTWARE").unwrap());
        // A key that exists but may not be opened is an error, not "absent"
        // (SECURITY is readable by the system account alone).
        assert!(key_present(LOCAL_MACHINE, "SECURITY").is_err());
    }

    #[test]
    fn pending_file_renames_are_read_as_a_multi_string() {
        let test = TestKey::new("renames");
        assert!(pending_file_renames(&test.key).unwrap().is_empty(), "missing value means no renames");

        test.key.set_multi_string("PendingFileRenameOperations", &[r"\??\C:\old.dll", ""]).unwrap();
        assert_eq!(pending_file_renames(&test.key).unwrap(), vec![r"C:\old.dll".to_owned()]);

        // Only the sources are named; the decorations Windows adds are dropped.
        test.key
            .set_multi_string(
                "PendingFileRenameOperations",
                &[
                    r"*1\??\C:\Windows\System32\gamingservicesproxy_13.dll.0",
                    "",
                    r"!\??\C:\a.tmp",
                    r"\??\C:\a.dll",
                ],
            )
            .unwrap();
        assert_eq!(
            pending_file_renames(&test.key).unwrap(),
            vec![r"C:\Windows\System32\gamingservicesproxy_13.dll.0".to_owned(), r"C:\a.tmp".to_owned()]
        );

        test.key.set_multi_string("PendingFileRenameOperations", &[""]).unwrap();
        assert!(
            pending_file_renames(&test.key).unwrap().is_empty(),
            "only empty entries is not a pending rename"
        );

        // A value of the wrong type is a read error, not silently "no renames".
        test.key.set_u32("PendingFileRenameOperations", 1).unwrap();
        assert!(pending_file_renames(&test.key).is_err());
    }
}
