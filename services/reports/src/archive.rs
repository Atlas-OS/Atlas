use crate::{ApiError, ApiResult};
use axum::http::StatusCode;
use serde_json::{Value, json};
use std::{
    collections::HashSet,
    fs::File,
    io::{Read, Seek, SeekFrom},
    path::Path,
};
use uuid::Uuid;

const MAX_ENTRIES: usize = 2048;
const MAX_NAME: usize = 512;
/// Expanded size of one member.
const MAX_ENTRY_BYTES: u64 = 32 * 1024 * 1024;
/// Expanded size of the whole archive.
const MAX_EXPANDED_BYTES: u64 = 256 * 1024 * 1024;
const MAX_MANIFEST_BYTES: u64 = 2 * 1024 * 1024;

/// Why an archive was refused: a fixed reason, or the reading library's error.
type Refusal = Box<dyn std::error::Error>;

/// Checks a report's uploaded ZIP in place and returns its summary. Why an
/// archive was refused is logged for the operator; senders only ever see fixed
/// text.
pub fn validate(path: &Path, report: Uuid) -> ApiResult<Value> {
    validate_inner(path).map_err(|reason| {
        eprintln!("Report {report} diagnostics refused: {reason}");
        ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Choose a valid redacted Atlas diagnostic ZIP.",
        )
    })
}
/// Whether `extra` holds an Info-ZIP Unicode Path or Comment field, which some
/// tools show instead of the stored name or comment.
fn has_name_override(mut extra: &[u8]) -> bool {
    while let [a, b, c, d, rest @ ..] = extra {
        if matches!(u16::from_le_bytes([*a, *b]), 0x7075 | 0x6375) {
            return true;
        }
        extra = rest
            .get(usize::from(u16::from_le_bytes([*c, *d]))..)
            .unwrap_or_default();
    }
    false
}
/// Other tools may read the name from the local header rather than the
/// central directory, so both must name the same file. Returns where the
/// entry's data ends. Refuses a local header that disagrees, carries a name
/// override, or leaves the sizes to a descriptor after the data, which Atlas
/// never writes.
fn local_entry_end(file: &mut File, entry: &zip::read::ZipFile<File>) -> Result<u64, Refusal> {
    let mut header = [0; 30];
    file.seek(SeekFrom::Start(entry.header_start()))?;
    file.read_exact(&mut header)?;
    let descriptor = u16::from_le_bytes([header[6], header[7]]) & 8 != 0;
    let name = usize::from(u16::from_le_bytes([header[26], header[27]]));
    let extra = usize::from(u16::from_le_bytes([header[28], header[29]]));
    let mut fields = vec![0; name + extra];
    file.read_exact(&mut fields)?;
    if !header.starts_with(b"PK\x03\x04") || fields[..name] != *entry.name_raw() {
        return Err("Local header differs from central directory".into());
    }
    if descriptor {
        return Err("Data descriptor".into());
    }
    if has_name_override(&fields[name..]) {
        return Err("Unicode path or comment field".into());
    }
    let data = entry.header_start() + (30 + name + extra) as u64;
    data.checked_add(entry.compressed_size())
        .ok_or_else(|| "Invalid member size".into())
}
fn validate_inner(path: &Path) -> Result<Value, Refusal> {
    let mut archive = zip::ZipArchive::new(File::open(path)?)?;
    let mut local = File::open(path)?;
    if archive.is_empty() || archive.len() > MAX_ENTRIES {
        return Err("Archive entry limit".into());
    }
    if archive.offset() != 0 {
        return Err("Data before first member".into());
    }
    let mut names = HashSet::new();
    let mut size = 0u64;
    let mut manifest = None;
    let mut actual = 0;
    let mut spans = Vec::with_capacity(archive.len());
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index)?;
        let before = actual;
        if has_name_override(entry.extra_data().unwrap_or_default()) {
            return Err("Unicode path or comment field".into());
        }
        spans.push((entry.header_start(), local_entry_end(&mut local, &entry)?));
        let name = entry.name().to_owned();
        let kind = entry.unix_mode().unwrap_or(0) & 0o170000;
        if name.is_empty()
            || name.starts_with('/')
            || name.contains(['\\', ':'])
            || name.chars().any(char::is_control)
            || name.split('/').any(|p| p == ".." || p == ".")
            || name.contains("//")
            || name.len() > MAX_NAME
        {
            return Err("Unsafe member name".into());
        }
        if !names.insert(name.to_lowercase()) {
            return Err("Duplicate member name".into());
        }
        if entry.encrypted() {
            return Err("Encrypted member".into());
        }
        if entry.is_symlink() {
            return Err("Symbolic link member".into());
        }
        if !matches!(
            entry.compression(),
            zip::CompressionMethod::Stored | zip::CompressionMethod::Deflated
        ) {
            return Err("Unsupported compression".into());
        }
        if !matches!(kind, 0 | 0o100000 | 0o040000) {
            return Err("Special archive entry".into());
        }
        size = size.checked_add(entry.size()).ok_or("Expansion limit")?;
        if entry.size() > MAX_ENTRY_BYTES || size > MAX_EXPANDED_BYTES {
            return Err("Expansion limit".into());
        }
        if name == "manifest.json" {
            if entry.size() > MAX_MANIFEST_BYTES {
                return Err("Manifest limit".into());
            }
            let mut bytes = Vec::new();
            entry
                .by_ref()
                .take(MAX_MANIFEST_BYTES + 1)
                .read_to_end(&mut bytes)?;
            if bytes.len() as u64 > MAX_MANIFEST_BYTES {
                return Err("Manifest limit".into());
            }
            actual += bytes.len() as u64;
            manifest = Some(serde_json::from_slice::<Value>(&bytes)?);
        } else {
            let mut bytes = [0; 65536];
            let mut member = 0;
            loop {
                let count = entry.read(&mut bytes)?;
                if count == 0 {
                    break;
                }
                member += count as u64;
                actual += count as u64;
                // Stop as soon as the inflated data passes a limit, whatever
                // the header claims.
                if member > MAX_ENTRY_BYTES || actual > MAX_EXPANDED_BYTES {
                    return Err("Expansion limit".into());
                }
            }
        }
        if actual > MAX_EXPANDED_BYTES || actual - before != entry.size() {
            return Err("Invalid expanded size".into());
        }
    }
    // Members must fill the file up to the central directory, so tools that
    // scan local headers cannot find an entry that was not checked here.
    spans.sort_unstable();
    let mut next = 0;
    for (start, end) in spans {
        if start != next {
            return Err("Gap or overlap between members".into());
        }
        next = end;
    }
    if next != archive.central_directory_start() {
        return Err("Gap or overlap at central directory".into());
    }
    let manifest = manifest.ok_or("Missing manifest")?;
    if manifest["schema"] != 2 || manifest["redaction"] != "public-v1" {
        return Err("Unredacted manifest".into());
    }
    let clipped = |value: &Value| {
        value
            .as_str()
            .unwrap_or("")
            .chars()
            .take(120)
            .collect::<String>()
    };
    let rc = manifest
        .get("rcId")
        .filter(|v| v.is_string())
        .unwrap_or(&manifest["appVersion"]);
    Ok(json!({
        "rc": clipped(rc),
        "windows": clipped(&manifest["windows"]["build"]),
        "edition": clipped(&manifest["windows"]["edition"]),
    }))
}

#[cfg(test)]
mod tests {
    use super::validate_inner;
    use std::io::{Cursor, Write};
    use zip::write::{FullFileOptions, SimpleFileOptions};

    const MANIFEST: &[u8] = br#"{"schema":2,"redaction":"public-v1"}"#;

    fn archive(members: &[(&str, &[u8])]) -> Vec<u8> {
        let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
        for (name, data) in members {
            zip.start_file(*name, SimpleFileOptions::default()).unwrap();
            zip.write_all(data).unwrap();
        }
        zip.finish().unwrap().into_inner()
    }
    fn check(bytes: &[u8]) -> Result<serde_json::Value, String> {
        let file = tempfile::NamedTempFile::new().unwrap();
        std::fs::write(file.path(), bytes).unwrap();
        validate_inner(file.path()).map_err(|reason| reason.to_string())
    }

    // The operator log shows the reason, so each check must give its own.
    #[test]
    fn each_refusal_names_its_check() {
        let valid = archive(&[("manifest.json", MANIFEST), ("logs/notes.txt", b"x")]);
        assert!(check(&valid).is_ok());
        let mut prefixed = b"junk".to_vec();
        prefixed.extend(&valid);
        // The first copy of the name is the local header's.
        let mut renamed = valid.clone();
        let local = renamed
            .windows(14)
            .position(|w| w == b"logs/notes.txt")
            .unwrap();
        renamed[local..local + 14].copy_from_slice(b"logs/other.txt");
        let mut symlink = zip::ZipWriter::new(Cursor::new(Vec::new()));
        symlink
            .start_file("manifest.json", SimpleFileOptions::default())
            .unwrap();
        symlink.write_all(MANIFEST).unwrap();
        symlink
            .add_symlink("link", "/etc/passwd", SimpleFileOptions::default())
            .unwrap();
        // A writer that can't seek puts the sizes in a descriptor after the data.
        let mut streamed = zip::ZipWriter::new_stream(Vec::new());
        streamed
            .start_file("manifest.json", SimpleFileOptions::default())
            .unwrap();
        streamed.write_all(MANIFEST).unwrap();
        // A Unicode Comment field: version 1, the CRC-32 of the empty stored
        // comment, then the replacement text.
        let mut commented = zip::ZipWriter::new(Cursor::new(Vec::new()));
        let mut options = FullFileOptions::default();
        options
            .add_extra_data(0x6375, [1, 0, 0, 0, 0, b'x'], true)
            .unwrap();
        commented.start_file("manifest.json", options).unwrap();
        commented.write_all(MANIFEST).unwrap();
        for (bytes, reason) in [
            (
                archive(&[("manifest.json", MANIFEST), ("../notes.txt", b"x")]),
                "Unsafe member name",
            ),
            (
                archive(&[("manifest.json", MANIFEST), ("MANIFEST.JSON", b"x")]),
                "Duplicate member name",
            ),
            (
                symlink.finish().unwrap().into_inner(),
                "Symbolic link member",
            ),
            (prefixed, "Data before first member"),
            (renamed, "Local header differs from central directory"),
            (streamed.finish().unwrap().into_inner(), "Data descriptor"),
            (
                commented.finish().unwrap().into_inner(),
                "Unicode path or comment field",
            ),
            (archive(&[("logs/notes.txt", b"x")]), "Missing manifest"),
            (archive(&[("manifest.json", b"{}")]), "Unredacted manifest"),
        ] {
            assert_eq!(check(&bytes).unwrap_err(), reason);
        }
    }
}
