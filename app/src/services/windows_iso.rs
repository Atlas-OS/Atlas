//! Resolve Windows installation media through the Atlas website and stream the ISO from Microsoft.
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::Path;
use std::time::{Duration, Instant};

use anyhow::{Context, Result, ensure};
use serde_json::Value;

const API: &str = "https://atlasos.net/api/ms-iso";
const MAX_ISO_BYTES: u64 = 32 * 1024 * 1024 * 1024;

#[derive(Clone)]
pub struct Language {
    pub id: String,
    pub label: String,
}

fn agent() -> ureq::Agent {
    ureq::Agent::new_with_config(
        ureq::Agent::config_builder()
            .https_only(true)
            .max_redirects(0)
            .timeout_connect(Some(Duration::from_secs(20)))
            .timeout_recv_response(Some(Duration::from_secs(240)))
            .timeout_recv_body(Some(Duration::from_secs(24 * 60 * 60)))
            .build(),
    )
}

fn api(path: &str) -> Result<Value> {
    let mut response = agent().get(format!("{API}/{path}")).call()?;
    ensure!(response.status().as_u16() == 200, "Unexpected Worker response");
    Ok(response.body_mut().with_config().limit(1024 * 1024).read_json()?)
}

fn valid_id(id: &str) -> bool {
    (1..=10).contains(&id.len()) && id.bytes().all(|b| b.is_ascii_digit())
}

fn parse_languages(value: &Value) -> Result<Vec<Language>> {
    let skus = value["Skus"].as_array().context("Missing ISO languages")?;
    let mut result = Vec::new();
    for sku in skus {
        let id = match &sku["Id"] {
            Value::String(id) => id.clone(),
            Value::Number(id) => id.to_string(),
            _ => continue,
        };
        if let Some(label) = sku["LocalizedLanguage"].as_str()
            && !label.trim().is_empty()
            && valid_id(&id)
        {
            result.push(Language { id, label: label.to_owned() });
        }
    }
    result.sort_by(|a, b| a.label.cmp(&b.label));
    ensure!(!result.is_empty(), "No ISO languages available");
    Ok(result)
}

pub fn languages(arch: &str) -> Result<Vec<Language>> {
    parse_languages(&api(&format!("skus?arch={arch}"))?)
}

fn microsoft_link(value: &Value) -> Result<&str> {
    let link = value["ProductDownloadOptions"][0]["Uri"].as_str().context("No ISO download available")?;
    let uri: ureq::http::Uri = link.parse()?;
    ensure!(
        uri.scheme_str() == Some("https")
            && matches!(
                uri.authority().map(|a| a.as_str()),
                Some(
                    "software.download.prss.microsoft.com"
                        | "software-static.download.prss.microsoft.com"
                        | "software-download.microsoft.com"
                )
            )
            && uri.path().to_ascii_lowercase().ends_with(".iso"),
        "Invalid Microsoft ISO link"
    );
    Ok(link)
}

pub fn download(
    arch: &str,
    id: &str,
    path: &Path,
    cancelled: impl Fn() -> bool,
    progress: impl FnMut(u64, u64),
) -> Result<()> {
    ensure!(valid_id(id) && !path.exists(), "Choose a new file");
    let response = api(&format!("links?arch={arch}&skuId={id}"))?;
    ensure!(!cancelled(), "Cancelled");
    let mut response = agent()
        .get(microsoft_link(&response)?)
        .call()
        .map_err(|_| anyhow::anyhow!("Could not start the Microsoft ISO transfer"))?;
    ensure!(response.status().as_u16() == 200, "Unexpected ISO response");
    let size: u64 = response.headers().get("content-length").context("No ISO size")?.to_str()?.parse()?;
    ensure!((32774..=MAX_ISO_BYTES).contains(&size), "Invalid ISO size");
    save_iso(response.body_mut().as_reader(), path, size, cancelled, progress)
}

fn save_iso(
    mut reader: impl Read,
    path: &Path,
    size: u64,
    cancelled: impl Fn() -> bool,
    mut progress: impl FnMut(u64, u64),
) -> Result<()> {
    let mut temp = tempfile::NamedTempFile::new_in(path.parent().context("Missing download directory")?)?;
    let mut buffer = vec![0; 256 * 1024];
    let mut received = 0;
    let mut stamp = Instant::now();
    progress(0, size);
    loop {
        ensure!(!cancelled(), "Cancelled");
        let count = reader.read(&mut buffer)?;
        if count == 0 {
            break;
        }
        received += count as u64;
        ensure!(received <= size, "ISO exceeds its declared size");
        temp.write_all(&buffer[..count])?;
        if stamp.elapsed() >= Duration::from_millis(250) {
            progress(received, size);
            stamp = Instant::now();
        }
    }
    ensure!(received == size && !cancelled(), "ISO transfer incomplete");
    // Windows media can carry ISO 9660, UDF, or both. A Microsoft error
    // page can also arrive with HTTP 200 and a Content-Length.
    temp.seek(SeekFrom::Start(16 * 2048 + 1))?;
    let mut descriptor = [0; 5];
    temp.read_exact(&mut descriptor)?;
    ensure!(matches!(&descriptor, b"CD001" | b"BEA01"), "Response is not an ISO image");
    temp.as_file_mut().sync_all()?;
    temp.persist_noclobber(path)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn worker_language_ids_can_be_strings_or_numbers() {
        let langs = parse_languages(&json!({"Skus":[{"Id":2,"LocalizedLanguage":"German"},{"Id":"1","LocalizedLanguage":"English"},{"Id":"1&extra","LocalizedLanguage":"Invalid"}]})).unwrap();
        assert_eq!(langs.iter().map(|l| l.id.as_str()).collect::<Vec<_>>(), ["1", "2"]);
    }

    #[test]
    fn transfers_publish_only_the_complete_file_and_keep_existing_files() {
        let dir = tempfile::tempdir().unwrap();
        let dest = dir.path().join("Windows.iso");
        let mut source = [7u8; 33_000];
        source[32769..32774].copy_from_slice(b"CD001");
        let size = source.len() as u64;
        for (length, cancel) in [(size + 1, false), (size - 1, false), (size, true)] {
            assert!(save_iso(&source[..], &dest, length, || cancel, |_, _| {}).is_err());
            assert_eq!(dir.path().read_dir().unwrap().count(), 0);
        }
        let mut different = source;
        different[0] = 9;
        assert!(save_iso(&[0u8; 33_000][..], &dest, size, || false, |_, _| {}).is_err());
        save_iso(&source[..], &dest, size, || false, |_, _| {}).unwrap();
        assert!(save_iso(&different[..], &dest, size, || false, |_, _| {}).is_err());
        assert_eq!(std::fs::read(dest).unwrap(), source);
    }

    #[test]
    fn accepts_only_direct_microsoft_iso_links() {
        for (link, ok) in [
            ("https://software.download.prss.microsoft.com/dbazure/test.iso?t=x", true),
            ("https://software.download.prss.microsoft.com.evil.test/test.iso", false),
            ("https://evil@software.download.prss.microsoft.com/test.iso", false),
            ("https://software.download.prss.microsoft.com/a.exe", false),
        ] {
            assert_eq!(microsoft_link(&json!({"ProductDownloadOptions":[{"Uri":link}]})).is_ok(), ok);
        }
    }
}
