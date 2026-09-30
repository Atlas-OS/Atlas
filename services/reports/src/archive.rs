use crate::{ApiError, ApiResult};
use axum::http::StatusCode;
use serde_json::{Value, json};
use std::{collections::HashSet, fs::File, io::Read, path::Path};

pub fn validate(path: &Path) -> ApiResult<Value> {
    validate_inner(path).map_err(|_| {
        ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Choose a valid redacted Atlas diagnostic ZIP.",
        )
    })
}
fn validate_inner(path: &Path) -> Result<Value, Box<dyn std::error::Error>> {
    let mut archive = zip::ZipArchive::new(File::open(path)?)?;
    if archive.is_empty() || archive.len() > 2048 {
        return Err("Archive entry limit".into());
    }
    let mut names = HashSet::new();
    let mut size = 0u64;
    let mut manifest = None;
    let mut actual = 0;
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index)?;
        let before = actual;
        let name = entry.name().to_owned();
        let kind = entry.unix_mode().unwrap_or(0) & 0o170000;
        if name.is_empty()
            || name.starts_with('/')
            || name.contains(['\\', ':'])
            || name.chars().any(char::is_control)
            || name.split('/').any(|p| p == ".." || p == ".")
            || name.contains("//")
            || name.len() > 512
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
        if entry.size() > 32 * 1024 * 1024 || size > 256 * 1024 * 1024 {
            return Err("Expansion limit".into());
        }
        if name == "manifest.json" {
            if entry.size() > 2 * 1024 * 1024 {
                return Err("Manifest limit".into());
            }
            let mut bytes = Vec::new();
            entry
                .by_ref()
                .take(2 * 1024 * 1024 + 1)
                .read_to_end(&mut bytes)?;
            if bytes.len() > 2 * 1024 * 1024 {
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
                if member > 32 * 1024 * 1024 || actual > 256 * 1024 * 1024 {
                    return Err("Expansion limit".into());
                }
            }
        }
        if actual > 256 * 1024 * 1024 || actual - before != entry.size() {
            return Err("Invalid expanded size".into());
        }
    }
    let manifest = manifest.ok_or("Missing manifest")?;
    if manifest["schema"] != 2 || manifest["redaction"] != "public-v1" {
        return Err("Unredacted manifest".into());
    }
    let bounded = |value: &Value| {
        value
            .as_str()
            .unwrap_or("")
            .chars()
            .take(120)
            .collect::<String>()
    };
    Ok(
        json!({"rc": bounded(manifest.get("rcId").filter(|v| v.is_string()).unwrap_or(&manifest["appVersion"])), "windows":bounded(&manifest["windows"]["build"]), "edition":bounded(&manifest["windows"]["edition"])}),
    )
}
