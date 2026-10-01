use crate::{ApiError, ApiResult};
use axum::http::StatusCode;
use serde_json::{Value, json};
use std::{
    collections::HashSet,
    fs::File,
    io::{Read, Seek, SeekFrom},
    path::Path,
};

const MAX_ENTRIES: usize = 2048;
const MAX_NAME: usize = 512;
/// Expanded size of one member.
const MAX_ENTRY_BYTES: u64 = 32 * 1024 * 1024;
/// Expanded size of the whole archive.
const MAX_EXPANDED_BYTES: u64 = 256 * 1024 * 1024;
const MAX_MANIFEST_BYTES: u64 = 2 * 1024 * 1024;

pub fn validate(path: &Path) -> ApiResult<Value> {
    validate_inner(path).map_err(|_| {
        ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Choose a valid redacted Atlas diagnostic ZIP.",
        )
    })
}
/// Whether `extra` holds an Info-ZIP Unicode Path or Comment field, which some
/// tools show instead of the stored name.
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
/// entry's data ends, or `None` when the headers disagree or the sizes follow
/// the data in a descriptor, which Atlas never writes.
fn local_entry_end(
    file: &mut File,
    entry: &zip::read::ZipFile<File>,
) -> std::io::Result<Option<u64>> {
    let mut header = [0; 30];
    file.seek(SeekFrom::Start(entry.header_start()))?;
    file.read_exact(&mut header)?;
    let descriptor = u16::from_le_bytes([header[6], header[7]]) & 8 != 0;
    let name = usize::from(u16::from_le_bytes([header[26], header[27]]));
    let extra = usize::from(u16::from_le_bytes([header[28], header[29]]));
    let mut fields = vec![0; name + extra];
    file.read_exact(&mut fields)?;
    let matches = header.starts_with(b"PK\x03\x04")
        && !descriptor
        && fields[..name] == *entry.name_raw()
        && !has_name_override(&fields[name..]);
    let data = entry.header_start() + (30 + name + extra) as u64;
    Ok(matches
        .then(|| data.checked_add(entry.compressed_size()))
        .flatten())
}
fn validate_inner(path: &Path) -> Result<Value, Box<dyn std::error::Error>> {
    let mut archive = zip::ZipArchive::new(File::open(path)?)?;
    let mut local = File::open(path)?;
    if archive.is_empty() || archive.len() > MAX_ENTRIES {
        return Err("Archive entry limit".into());
    }
    if archive.offset() != 0 {
        return Err("Unsafe archive entry".into());
    }
    let mut names = HashSet::new();
    let mut size = 0u64;
    let mut manifest = None;
    let mut actual = 0;
    let mut spans = Vec::with_capacity(archive.len());
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index)?;
        let before = actual;
        let end = if has_name_override(entry.extra_data().unwrap_or_default()) {
            None
        } else {
            local_entry_end(&mut local, &entry)?
        };
        let Some(end) = end else {
            return Err("Unsafe archive entry".into());
        };
        spans.push((entry.header_start(), end));
        let name = entry.name().to_owned();
        let kind = entry.unix_mode().unwrap_or(0) & 0o170000;
        if name.is_empty()
            || name.starts_with('/')
            || name.contains(['\\', ':'])
            || name.chars().any(char::is_control)
            || name.split('/').any(|p| p == ".." || p == ".")
            || name.contains("//")
            || name.len() > MAX_NAME
            || !names.insert(name.to_lowercase())
            || entry.encrypted()
            || entry.is_symlink()
            || !matches!(
                entry.compression(),
                zip::CompressionMethod::Stored | zip::CompressionMethod::Deflated
            )
        {
            return Err("Unsafe archive entry".into());
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
            return Err("Unsafe archive entry".into());
        }
        next = end;
    }
    if next != archive.central_directory_start() {
        return Err("Unsafe archive entry".into());
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
