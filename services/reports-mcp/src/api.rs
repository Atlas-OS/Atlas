use ring::digest;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{
    fs::{self, File, OpenOptions},
    io::{Read, Write},
    path::{Path, PathBuf},
    sync::Mutex,
    time::Duration,
};
use uuid::Uuid;

pub const DEFAULT_ORIGIN: &str = "https://reports.atlasos.net";
pub const MAX_ZIP: u64 = 64 * 1024 * 1024;
const MAX_JSON: u64 = 2 * 1024 * 1024;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Configuration,
    InvalidInput,
    Unauthorized,
    NotFound,
    Busy,
    Network,
    InvalidResponse,
    TooLarge,
    Integrity,
    Workspace,
    DeleteForbidden,
    Confirmation,
}
impl Error {
    pub fn message(self) -> &'static str {
        match self {
            Self::Configuration => {
                "Set a valid origin, private absolute workspace and scoped report token."
            }
            Self::InvalidInput => {
                "Use a report UUID, supported status, offset 0–100000 and limit 1–50."
            }
            Self::Unauthorized => "The report token is expired, revoked or not authorized.",
            Self::NotFound => "The report or diagnostics no longer exists.",
            Self::Busy => "Report access is busy. Retry shortly.",
            Self::Network => {
                "Cannot reach the configured report service. Check the connection and retry."
            }
            Self::InvalidResponse => "The report service returned an invalid response.",
            Self::TooLarge => "The response exceeds the local size limit.",
            Self::Integrity => "Diagnostics failed the size or SHA-256 integrity check.",
            Self::Workspace => {
                "Cannot safely write diagnostics in the configured private workspace."
            }
            Self::DeleteForbidden => "This credential cannot delete reports.",
            Self::Confirmation => {
                "Explicitly approve deletion of this report before setting confirm:true."
            }
        }
    }
}
impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.message())
    }
}
impl std::error::Error for Error {}
type Result<T> = std::result::Result<T, Error>;

pub struct Config {
    pub origin: String,
    pub token: String,
    pub workspace: PathBuf,
}

pub struct Client {
    agent: ureq::Agent,
    origin: String,
    token: String,
    workspace: PathBuf,
    download_lock: Mutex<()>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Preview {
    pub id: String,
    pub created: i64,
    pub category: String,
    pub version: String,
    pub bytes: u64,
    pub status: String,
    pub summary: Value,
    pub message_preview: String,
}
#[derive(Debug, Serialize, Deserialize)]
pub struct Listing {
    pub reports: Vec<Preview>,
    pub total: u64,
    pub offset: u32,
    pub limit: u32,
}
#[derive(Debug, Serialize, Deserialize)]
pub struct Report {
    pub id: String,
    pub created: i64,
    pub category: String,
    pub version: String,
    pub bytes: u64,
    pub status: String,
    pub summary: Value,
    pub message: String,
    pub notes: String,
    pub digest: String,
}
#[derive(Deserialize)]
struct Detail {
    report: Report,
}

#[derive(Debug, Serialize)]
pub struct Download {
    pub report_id: String,
    pub local_path: PathBuf,
    pub bytes: u64,
    pub sha256: String,
    pub cached: bool,
    pub extracted: bool,
}

pub fn report_id(value: &str) -> Result<String> {
    if value.len() != 36 {
        return Err(Error::InvalidInput);
    }
    Uuid::parse_str(value)
        .map(|id| id.to_string())
        .map_err(|_| Error::InvalidInput)
}
pub fn pagination(status: Option<&str>, offset: u32, limit: u32) -> Result<()> {
    if offset > 100000
        || !(1..=50).contains(&limit)
        || status.is_some_and(|s| !["new", "investigating", "resolved", "closed"].contains(&s))
    {
        return Err(Error::InvalidInput);
    }
    Ok(())
}
fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}
fn status(error: ureq::Error) -> Error {
    match error {
        ureq::Error::StatusCode(401 | 403) => Error::Unauthorized,
        ureq::Error::StatusCode(404) => Error::NotFound,
        ureq::Error::StatusCode(429 | 503) => Error::Busy,
        ureq::Error::StatusCode(_)
        | ureq::Error::TooManyRedirects
        | ureq::Error::RedirectFailed => Error::InvalidResponse,
        _ => Error::Network,
    }
}
fn origin_valid(value: &str) -> bool {
    let Ok(uri) = value.parse::<ureq::http::Uri>() else {
        return false;
    };
    let host = uri.host().unwrap_or("").trim_matches(['[', ']']);
    let loopback = host == "localhost"
        || host
            .parse::<std::net::IpAddr>()
            .is_ok_and(|ip| ip.is_loopback());
    uri.authority().is_some_and(|a| !a.as_str().contains('@'))
        && uri.path() == "/"
        && uri.query().is_none()
        && !value.ends_with('/')
        && (uri.scheme_str() == Some("https") || (loopback && uri.scheme_str() == Some("http")))
}
fn regular_file(path: &Path) -> Result<bool> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_file() && !metadata.file_type().is_symlink() => Ok(true),
        Ok(_) => Err(Error::Workspace),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(false),
        Err(_) => Err(Error::Workspace),
    }
}
fn hash_file(path: &Path) -> Result<(u64, String)> {
    let mut file = File::open(path).map_err(|_| Error::Workspace)?;
    let mut total = 0;
    let mut hash = digest::Context::new(&digest::SHA256);
    let mut buffer = [0; 65536];
    loop {
        let count = file.read(&mut buffer).map_err(|_| Error::Workspace)?;
        if count == 0 {
            break;
        }
        total += count as u64;
        if total > MAX_ZIP {
            return Err(Error::TooLarge);
        }
        hash.update(&buffer[..count]);
    }
    Ok((total, hex(hash.finish().as_ref())))
}
struct Temporary(PathBuf);
impl Drop for Temporary {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

impl Client {
    pub fn new(config: Config) -> Result<Self> {
        if !origin_valid(&config.origin)
            || !config.workspace.is_absolute()
            || config.token.len() < 32
            || config.token.len() > 512
            || !config
                .token
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"-_.".contains(&b))
        {
            return Err(Error::Configuration);
        }
        if fs::symlink_metadata(&config.workspace).is_ok_and(|m| m.file_type().is_symlink()) {
            return Err(Error::Workspace);
        }
        fs::create_dir_all(&config.workspace).map_err(|_| Error::Workspace)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            fs::set_permissions(&config.workspace, fs::Permissions::from_mode(0o700))
                .map_err(|_| Error::Workspace)?;
        }
        let workspace = config
            .workspace
            .canonicalize()
            .map_err(|_| Error::Workspace)?;
        let agent = ureq::Agent::new_with_config(
            ureq::Agent::config_builder()
                .user_agent("AtlasReportsMCP/0.1.0")
                .max_redirects(0)
                .https_only(config.origin.starts_with("https://"))
                .timeout_connect(Some(Duration::from_secs(10)))
                .timeout_global(Some(Duration::from_secs(120)))
                .build(),
        );
        Ok(Self {
            agent,
            origin: config.origin,
            token: config.token,
            workspace,
            download_lock: Mutex::new(()),
        })
    }
    fn request(&self, path: &str) -> Result<ureq::http::Response<ureq::Body>> {
        self.agent
            .get(&format!("{}{path}", self.origin))
            .header("Authorization", &format!("Bearer {}", self.token))
            .header("Accept-Encoding", "identity")
            .call()
            .map_err(status)
    }
    fn json<T: serde::de::DeserializeOwned>(&self, path: &str) -> Result<T> {
        let mut response = self.request(path)?;
        if response.status().as_u16() != 200
            || response
                .headers()
                .get("content-type")
                .and_then(|v| v.to_str().ok())
                .is_none_or(|v| v.split(';').next() != Some("application/json"))
        {
            return Err(Error::InvalidResponse);
        }
        let mut bytes = Vec::new();
        response
            .body_mut()
            .as_reader()
            .take(MAX_JSON + 1)
            .read_to_end(&mut bytes)
            .map_err(|_| Error::Network)?;
        if bytes.len() as u64 > MAX_JSON {
            return Err(Error::TooLarge);
        }
        serde_json::from_slice(&bytes).map_err(|_| Error::InvalidResponse)
    }
    pub fn list(&self, status_filter: Option<&str>, offset: u32, limit: u32) -> Result<Listing> {
        pagination(status_filter, offset, limit)?;
        let mut path = format!("/api/agent/reports?offset={offset}&limit={limit}");
        if let Some(status) = status_filter {
            path += &format!("&status={status}");
        }
        let listing: Listing = self.json(&path)?;
        if listing.offset != offset
            || listing.limit != limit
            || listing.total > 100000
            || listing.reports.len() > limit as usize
        {
            return Err(Error::InvalidResponse);
        }
        for report in &listing.reports {
            report_id(&report.id).map_err(|_| Error::InvalidResponse)?;
            if report.message_preview.chars().count() > 240 || report.bytes > MAX_ZIP {
                return Err(Error::InvalidResponse);
            }
        }
        Ok(listing)
    }
    pub fn get(&self, id: &str) -> Result<Report> {
        let id = report_id(id)?;
        let detail: Detail = self.json(&format!("/api/agent/reports/{id}"))?;
        if detail.report.id != id
            || detail.report.bytes > MAX_ZIP
            || detail.report.message.chars().count() > 4000
            || detail.report.notes.chars().count() > 8000
        {
            return Err(Error::InvalidResponse);
        }
        Ok(detail.report)
    }
    pub fn delete(&self, id: &str, confirm: bool) -> Result<()> {
        if !confirm {
            return Err(Error::Confirmation);
        }
        let id = report_id(id)?;
        let response = self
            .agent
            .delete(&format!("{}/api/agent/reports/{id}", self.origin))
            .header("Authorization", &format!("Bearer {}", self.token))
            .force_send_body()
            .send_json(serde_json::json!({"confirm_id":id}))
            .map_err(|error| match error {
                ureq::Error::StatusCode(403) => Error::DeleteForbidden,
                other => status(other),
            })?;
        if response.status().as_u16() != 204 {
            return Err(Error::InvalidResponse);
        }
        Ok(())
    }
    pub fn download(&self, id: &str) -> Result<Download> {
        let id = report_id(id)?;
        let _lock = self.download_lock.try_lock().map_err(|_| Error::Busy)?;
        let mut response = self.request(&format!("/api/agent/reports/{id}/diagnostics"))?;
        if response.status().as_u16() != 200
            || response
                .headers()
                .get("content-type")
                .and_then(|v| v.to_str().ok())
                .is_none_or(|v| v.split(';').next() != Some("application/zip"))
        {
            return Err(Error::InvalidResponse);
        }
        let checksum = response
            .headers()
            .get("x-atlas-diagnostics-sha256")
            .and_then(|v| v.to_str().ok())
            .ok_or(Error::InvalidResponse)?
            .to_ascii_lowercase();
        if checksum.len() != 64 || !checksum.bytes().all(|b| b.is_ascii_hexdigit()) {
            return Err(Error::InvalidResponse);
        }
        let length = response
            .headers()
            .get("content-length")
            .map(|v| {
                v.to_str()
                    .ok()
                    .and_then(|s| s.parse::<u64>().ok())
                    .ok_or(Error::InvalidResponse)
            })
            .transpose()?;
        if length.is_some_and(|size| size > MAX_ZIP) {
            return Err(Error::TooLarge);
        }
        let destination = self.workspace.join(format!("{id}-{checksum}.zip"));
        if regular_file(&destination)? {
            let (bytes, current) = hash_file(&destination)?;
            if current != checksum || length.is_some_and(|l| l != bytes) {
                return Err(Error::Integrity);
            }
            return Ok(Download {
                report_id: id,
                local_path: destination,
                bytes,
                sha256: checksum,
                cached: true,
                extracted: false,
            });
        }
        let temporary = Temporary(self.workspace.join(format!("{}.part", Uuid::new_v4())));
        let mut options = OpenOptions::new();
        options.write(true).create_new(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            options.mode(0o600);
        }
        let mut file = options.open(&temporary.0).map_err(|_| Error::Workspace)?;
        let mut reader = response.body_mut().as_reader();
        let mut buffer = [0; 65536];
        let mut total = 0;
        let mut hash = digest::Context::new(&digest::SHA256);
        loop {
            let count = reader.read(&mut buffer).map_err(|_| Error::Network)?;
            if count == 0 {
                break;
            }
            total += count as u64;
            if total > MAX_ZIP {
                return Err(Error::TooLarge);
            }
            hash.update(&buffer[..count]);
            file.write_all(&buffer[..count])
                .map_err(|_| Error::Workspace)?;
        }
        if total == 0
            || hex(hash.finish().as_ref()) != checksum
            || length.is_some_and(|l| l != total)
        {
            return Err(Error::Integrity);
        }
        file.sync_all().map_err(|_| Error::Workspace)?;
        drop(file);
        // Hard linking commits without replacing an existing file or following a
        // symbolic link. The private temporary name is removed by its guard.
        fs::hard_link(&temporary.0, &destination).map_err(|_| Error::Workspace)?;
        Ok(Download {
            report_id: id,
            local_path: destination,
            bytes: total,
            sha256: checksum,
            cached: false,
            extracted: false,
        })
    }
}
