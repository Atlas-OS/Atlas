//! Reports leave the PC only after explicit review and consent in the report
//! page. The destination is fixed, HTTPS-only, and redirects are never followed.
use anyhow::{Context, Result, bail};
use serde::Deserialize;
use serde_json::json;
use std::{fs::File, path::Path, time::Duration};

pub const ORIGIN: &str = "https://reports.atlasos.net";
pub const PRIVACY_VERSION: &str = "2026-09-30";
pub const MAX_ZIP: u64 = 64 * 1024 * 1024;

pub fn new_key() -> Result<String> {
    let mut bytes = [0u8; 16];
    ring::rand::SecureRandom::fill(&ring::rand::SystemRandom::new(), &mut bytes)
        .map_err(|_| anyhow::anyhow!("Cannot create report identity"))?;
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    let hex: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
    Ok(format!("{}-{}-{}-{}-{}", &hex[..8], &hex[8..12], &hex[12..16], &hex[16..20], &hex[20..]))
}

#[derive(Deserialize)]
struct Receipt {
    id: String,
    upload_token: Option<String>,
    received: bool,
}

#[derive(Deserialize)]
struct UploadReceipt {
    id: Option<String>,
    received: bool,
}
impl UploadReceipt {
    fn validate(self, expected_id: &str) -> Result<()> {
        if !self.received || self.id.as_deref().is_some_and(|id| id != expected_id) {
            bail!("Invalid upload acknowledgement");
        }
        Ok(())
    }
}

fn retryable(error: &anyhow::Error) -> bool {
    error.chain().filter_map(|cause| cause.downcast_ref::<ureq::Error>()).any(|error| {
        matches!(
            error,
            ureq::Error::Io(_)
                | ureq::Error::Timeout(_)
                | ureq::Error::HostNotFound
                | ureq::Error::ConnectionFailed
                | ureq::Error::StatusCode(408 | 429 | 500 | 502 | 503 | 504)
        )
    })
}

pub fn valid_id(value: &str) -> bool {
    value.len() == 36
        && value
            .bytes()
            .enumerate()
            .all(|(i, b)| if [8, 13, 18, 23].contains(&i) { b == b'-' } else { b.is_ascii_hexdigit() })
}

pub fn send(key: &str, message: &str, contact: &str, diagnostics: Option<&Path>) -> Result<String> {
    let message = message.trim();
    let contact = contact.trim();
    if !(10..=4000).contains(&message.chars().count()) || contact.chars().count() > 254 || !valid_id(key) {
        bail!("Invalid report details");
    }
    let attachment = diagnostics.map(File::open).transpose().context("open prepared diagnostics")?;
    if attachment.as_ref().is_some_and(|f| f.metadata().map(|m| m.len() > MAX_ZIP).unwrap_or(true)) {
        bail!("Diagnostics exceed the upload limit");
    }
    let agent = ureq::Agent::new_with_config(
        ureq::Agent::config_builder()
            .user_agent(super::releases::USER_AGENT)
            .https_only(true)
            .max_redirects(0)
            .timeout_connect(Some(Duration::from_secs(10)))
            .timeout_global(Some(Duration::from_secs(120)))
            .build(),
    );
    let details = json!({"submission_key":key,"category":"issue","message":message,"contact":contact,
        "version":super::embedded::rc_id().unwrap_or(env!("CARGO_PKG_VERSION")),
        "has_diagnostics":attachment.is_some(),"consent":true,"privacy_version":PRIVACY_VERSION});
    // Retry a transient connection failure with the same key. A lost response
    // never creates a second report or reuploads an already completed ZIP.
    let mut last_error = None;
    for attempt in 0..2 {
        let result = (|| -> Result<String> {
            let mut response = agent.post(&format!("{ORIGIN}/api/v1/reports")).send_json(&details)?;
            if response.status().as_u16() != 201 {
                bail!("Unexpected report response");
            }
            let receipt: Receipt = response.body_mut().with_config().limit(8192).read_json()?;
            if !valid_id(&receipt.id) {
                bail!("Invalid report receipt");
            }
            if let Some(file) = attachment.as_ref().filter(|_| !receipt.received) {
                let token = receipt.upload_token.context("missing upload receipt")?;
                if token.len() != 64 || !token.bytes().all(|b| b.is_ascii_hexdigit()) {
                    bail!("Invalid upload receipt");
                }
                let mut file = file.try_clone()?;
                use std::io::Seek;
                file.rewind()?;
                let mut response = agent
                    .put(&format!("{ORIGIN}/api/v1/reports/{}/diagnostics", receipt.id))
                    .header("Authorization", &format!("Bearer {token}"))
                    .header("Content-Type", "application/zip")
                    .header("Content-Length", &file.metadata()?.len().to_string())
                    .send(&file)?;
                if response.status().as_u16() != 200 {
                    bail!("Unexpected upload response");
                }
                let uploaded: UploadReceipt = response.body_mut().with_config().limit(8192).read_json()?;
                uploaded.validate(&receipt.id)?;
            } else if !receipt.received {
                bail!("Report was not acknowledged");
            }
            Ok(receipt.id)
        })();
        match result {
            Ok(receipt) => return Ok(receipt),
            Err(error) => {
                let retry = attempt == 0 && retryable(&error);
                last_error = Some(error);
                if retry {
                    std::thread::sleep(Duration::from_secs(1));
                } else {
                    break;
                }
            }
        }
    }
    Err(last_error.unwrap())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn receipt_paths_cannot_escape() {
        assert!(valid_id(&new_key().unwrap()));
        for value in ["../../secret", "https://evil.test", "00000000-0000-0000-0000-00000000000/"] {
            assert!(!valid_id(value));
        }
    }
    #[test]
    fn sharing_rejects_invalid_details_before_network() {
        assert!(send(&new_key().unwrap(), " ", "", None).is_err());
        assert!(send(&new_key().unwrap(), "Valid test message", &"x".repeat(255), None).is_err());
    }

    #[test]
    fn upload_acknowledgement_requires_received_and_matching_identity() {
        let id = new_key().unwrap();
        for value in [json!({"received":true,"id":id}), json!({"received":true})] {
            assert!(serde_json::from_value::<UploadReceipt>(value).unwrap().validate(&id).is_ok());
        }
        for value in [json!({"received":false,"id":id}), json!({"received":true,"id":new_key().unwrap()})] {
            assert!(serde_json::from_value::<UploadReceipt>(value).unwrap().validate(&id).is_err());
        }
        assert!(serde_json::from_value::<UploadReceipt>(json!({"id":id})).is_err());
    }

    #[test]
    fn only_transient_delivery_errors_are_retried() {
        for status in [408, 429, 500, 502, 503, 504] {
            assert!(retryable(&ureq::Error::StatusCode(status).into()));
        }
        for status in [400, 401, 403, 409, 413, 422] {
            assert!(!retryable(&ureq::Error::StatusCode(status).into()));
        }
        assert!(!retryable(&anyhow::anyhow!("Invalid upload acknowledgement")));
        assert!(!retryable(&ureq::Error::TooManyRedirects.into()));
    }
}
