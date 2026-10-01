//! Reports leave the PC only after explicit review and consent in the report
//! page. The destination is fixed, HTTPS-only, and redirects are never followed.
use std::io::Seek;
use std::{fmt, fs::File, ops::RangeInclusive, path::Path, time::Duration};

use anyhow::{Context, Result, bail};
use serde::Deserialize;
use serde_json::{Value, json};

pub const ORIGIN: &str = "https://reports.atlasos.net";
// The report service (services/reports in this repository) enforces these
// limits and refuses any other privacy notice version; the app mirrors them
// to say what fits before sending.
const PRIVACY_VERSION: &str = "2026-10-01";
const MAX_ZIP: u64 = 64 * 1024 * 1024;
/// Characters allowed after trimming.
pub const MESSAGE_CHARS: RangeInclusive<usize> = 10..=4000;
pub const CONTACT_MAX_CHARS: usize = 254;
/// The most of a receipt read from the service.
const RECEIPT_LIMIT: u64 = 8192;
/// How long a transient failure waits before its one retry.
const RETRY_PAUSE: Duration = Duration::from_secs(1);

pub fn message_fits(message: &str) -> bool {
    MESSAGE_CHARS.contains(&message.trim().chars().count())
}

pub fn contact_fits(contact: &str) -> bool {
    contact.trim().chars().count() <= CONTACT_MAX_CHARS
}

/// What a report is about. The service files the two kinds separately.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum Category {
    #[default]
    Issue,
    Suggestion,
}

/// Why a report was not sent, in terms of what the sender can do about it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SendProblem {
    /// The connection, the service or this PC failed; trying again may work.
    Retry,
    /// The service is limiting reports or has no room for now.
    Busy,
    /// This version of the app can no longer send reports.
    Outdated,
    /// The prepared diagnostics can't be read or were refused.
    Diagnostics,
}

/// The service refused the report itself. The app checks everything the
/// service checks before sending, so this means the two no longer agree (a
/// changed privacy notice, say), and retrying cannot help.
#[derive(Debug)]
struct ServiceIncompatible(u16);
impl fmt::Display for ServiceIncompatible {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "the report service refused this version's report (HTTP {})", self.0)
    }
}
impl std::error::Error for ServiceIncompatible {}

/// The prepared diagnostics can't be read, or the service refused them.
#[derive(Debug)]
struct DiagnosticsUnusable(&'static str);
impl fmt::Display for DiagnosticsUnusable {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.0)
    }
}
impl std::error::Error for DiagnosticsUnusable {}

/// Classifies an error from [`send`].
pub fn problem(error: &anyhow::Error) -> SendProblem {
    if error.downcast_ref::<ServiceIncompatible>().is_some() {
        SendProblem::Outdated
    } else if error.downcast_ref::<DiagnosticsUnusable>().is_some() {
        SendProblem::Diagnostics
    } else if error
        .chain()
        .filter_map(|cause| cause.downcast_ref::<ureq::Error>())
        .any(|error| matches!(error, ureq::Error::StatusCode(429 | 503)))
    {
        SendProblem::Busy
    } else {
        SendProblem::Retry
    }
}

/// A random version-4 UUID naming one report: sending again with the same
/// key never creates a second report.
pub fn new_key() -> Result<String> {
    let mut bytes = [0u8; 16];
    ring::rand::SecureRandom::fill(&ring::rand::SystemRandom::new(), &mut bytes)
        .map_err(|_| anyhow::anyhow!("cannot create report identity"))?;
    // Version 4 and the RFC 4122 variant; the service accepts only v4 keys.
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    let hex = super::releases::hex(&bytes);
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

/// A hyphenated UUID. Receipt ids go into URL paths, so nothing else is
/// accepted.
fn valid_id(value: &str) -> bool {
    value.len() == 36
        && value
            .bytes()
            .enumerate()
            .all(|(i, b)| if [8, 13, 18, 23].contains(&i) { b == b'-' } else { b.is_ascii_hexdigit() })
}

fn details(key: &str, category: Category, message: &str, contact: &str, diagnostics: bool) -> Value {
    let category = match category {
        Category::Issue => "issue",
        Category::Suggestion => "suggestion",
    };
    json!({"submission_key":key,"category":category,"message":message,"contact":contact,
        "version":super::embedded::rc_id().unwrap_or(env!("CARGO_PKG_VERSION")),
        "has_diagnostics":diagnostics,"consent":true,"privacy_version":PRIVACY_VERSION})
}

/// The details the service would refuse, caught before anything is sent.
fn validate_details(key: &str, message: &str, contact: &str) -> Result<()> {
    anyhow::ensure!(
        message_fits(message) && contact_fits(contact) && valid_id(key),
        "Invalid report details"
    );
    Ok(())
}

pub fn send(
    key: &str,
    category: Category,
    message: &str,
    contact: &str,
    diagnostics: Option<&Path>,
) -> Result<String> {
    validate_details(key, message, contact)?;
    let attachment = diagnostics
        .map(File::open)
        .transpose()
        .context(DiagnosticsUnusable("Cannot open the prepared diagnostics"))?;
    if attachment.as_ref().is_some_and(|f| f.metadata().map(|m| m.len() > MAX_ZIP).unwrap_or(true)) {
        return Err(DiagnosticsUnusable("Diagnostics exceed the upload limit").into());
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
    let details = details(key, category, message.trim(), contact.trim(), attachment.is_some());
    // A transient failure is retried once with the same key: a lost response
    // never creates a second report or uploads a finished ZIP again.
    match submit(&agent, &details, attachment.as_ref()) {
        Err(error) if retryable(&error) => {
            std::thread::sleep(RETRY_PAUSE);
            submit(&agent, &details, attachment.as_ref())
        }
        result => result,
    }
}

/// Files the report and, unless the service already has them, uploads the
/// diagnostics. Returns the receipt id.
fn submit(agent: &ureq::Agent, details: &Value, attachment: Option<&File>) -> Result<String> {
    let mut response =
        agent.post(&format!("{ORIGIN}/api/v1/reports")).send_json(details).map_err(|error| match error {
            ureq::Error::StatusCode(status @ (400 | 415 | 422)) => ServiceIncompatible(status).into(),
            error => anyhow::Error::from(error),
        })?;
    if response.status().as_u16() != 201 {
        bail!("Unexpected report response");
    }
    let receipt: Receipt = response.body_mut().with_config().limit(RECEIPT_LIMIT).read_json()?;
    if !valid_id(&receipt.id) {
        bail!("Invalid report receipt");
    }
    match attachment {
        Some(file) if !receipt.received => {
            let token = receipt.upload_token.context("missing upload receipt")?;
            upload(agent, &receipt.id, &token, file)?;
        }
        _ if !receipt.received => bail!("Report was not acknowledged"),
        _ => {}
    }
    Ok(receipt.id)
}

/// Uploads the diagnostics for report `id` with the token its receipt gave.
fn upload(agent: &ureq::Agent, id: &str, token: &str, file: &File) -> Result<()> {
    if token.len() != 64 || !token.bytes().all(|b| b.is_ascii_hexdigit()) {
        bail!("Invalid upload receipt");
    }
    let mut file = file.try_clone()?;
    file.rewind()?;
    let mut response = agent
        .put(&format!("{ORIGIN}/api/v1/reports/{id}/diagnostics"))
        .header("Authorization", &format!("Bearer {token}"))
        .header("Content-Type", "application/zip")
        .header("Content-Length", &file.metadata()?.len().to_string())
        .send(&file)
        .map_err(|error| match error {
            ureq::Error::StatusCode(413 | 422) => {
                anyhow::Error::from(error).context(DiagnosticsUnusable("The service refused the diagnostics"))
            }
            error => error.into(),
        })?;
    if response.status().as_u16() != 200 {
        bail!("Unexpected upload response");
    }
    let uploaded: UploadReceipt = response.body_mut().with_config().limit(RECEIPT_LIMIT).read_json()?;
    uploaded.validate(id)
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

    /// `send` checks these before it connects to anything.
    #[test]
    fn invalid_details_are_refused_before_sending() {
        let key = new_key().unwrap();
        assert!(validate_details(&key, "Valid test message", "").is_ok());
        assert!(validate_details(&key, " ", "").is_err());
        assert!(validate_details(&key, "Valid test message", &"x".repeat(255)).is_err());
        assert!(validate_details("not-a-key", "Valid test message", "").is_err());
    }

    #[test]
    fn limits_count_characters_after_trimming() {
        assert!(!message_fits(&"x".repeat(9)) && message_fits(&"x".repeat(10)));
        assert!(message_fits(&format!("  {}  ", "é".repeat(4000))) && !message_fits(&"x".repeat(4001)));
        assert!(message_fits("line one\nline two"));
        assert!(contact_fits(&"x".repeat(254)) && !contact_fits(&"x".repeat(255)));
    }

    /// The service refuses any other notice version, so a bump that misses
    /// it would stop every report. The website's copy is in its own repository.
    #[test]
    fn the_privacy_version_is_the_one_the_service_accepts() {
        let service = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../services/reports/src/lib.rs");
        let source = std::fs::read_to_string(&service).expect("the report service's source");
        let declared = format!("pub const PRIVACY_VERSION: &str = \"{PRIVACY_VERSION}\";");
        assert!(source.contains(&declared), "{} must declare {declared}", service.display());
        assert_eq!(
            details(&new_key().unwrap(), Category::Issue, "message", "", false)["privacy_version"],
            PRIVACY_VERSION
        );
    }

    #[test]
    fn the_category_is_sent_as_the_service_names_it() {
        let key = new_key().unwrap();
        assert_eq!(details(&key, Category::Issue, "message", "", false)["category"], "issue");
        assert_eq!(details(&key, Category::Suggestion, "message", "", true)["category"], "suggestion");
    }

    #[test]
    fn failures_are_classified_by_what_the_sender_can_do() {
        let refused: anyhow::Error = ServiceIncompatible(422).into();
        assert_eq!(problem(&refused), SendProblem::Outdated);
        assert!(!retryable(&refused));
        let upload =
            anyhow::Error::from(ureq::Error::StatusCode(422)).context(DiagnosticsUnusable("refused"));
        assert_eq!(problem(&upload), SendProblem::Diagnostics);
        assert!(!retryable(&upload));
        for status in [429, 503] {
            assert_eq!(problem(&ureq::Error::StatusCode(status).into()), SendProblem::Busy);
        }
        assert!(retryable(&anyhow::Error::from(ureq::Error::StatusCode(503)).context("upload")));
        assert_eq!(problem(&ureq::Error::ConnectionFailed.into()), SendProblem::Retry);
        assert_eq!(problem(&anyhow::anyhow!("Invalid report receipt")), SendProblem::Retry);

        // A prepared ZIP that has gone missing fails before any network use.
        let missing = std::env::temp_dir().join(format!("atlas-missing-{}.zip", new_key().unwrap()));
        let error =
            send(&new_key().unwrap(), Category::Issue, "Valid test message", "", Some(&missing)).unwrap_err();
        assert_eq!(problem(&error), SendProblem::Diagnostics);
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
