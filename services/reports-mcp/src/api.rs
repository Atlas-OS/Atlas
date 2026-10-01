use ring::digest;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{
    fs::{self, File, OpenOptions},
    io::{self, Read, Write},
    path::{Path, PathBuf},
    sync::Mutex,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use uuid::Uuid;

pub const DEFAULT_ORIGIN: &str = "https://reports.atlasos.net";
/// The service's upload limit.
pub const MAX_ZIP: u64 = 64 * 1024 * 1024;
const MAX_JSON: u64 = 2 * 1024 * 1024;
/// The service accepts at most 32 KiB of JSON per report or review, so no
/// stored message or note can be longer.
const MAX_TEXT: usize = 32 * 1024;
/// How long the service keeps a report, and so how long a downloaded copy
/// may stay in the workspace: the privacy notice says reports are deleted
/// after 90 days.
pub const RETENTION: Duration = Duration::from_secs(90 * 24 * 60 * 60);
/// Beside each downloaded ZIP: when its report was made, in Unix seconds.
const CREATED_SUFFIX: &str = ".created";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Origin,
    Token,
    WorkspacePath,
    InvalidInput,
    Unauthorized,
    NotFound,
    NoDiagnostics,
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
            Self::Origin => {
                "ATLAS_REPORTS_ORIGIN must be an https:// origin (http:// only on loopback) with no path, query, credentials or trailing slash."
            }
            Self::Token => {
                "ATLAS_REPORTS_AGENT_TOKEN is not a valid access key. Copy it again without spaces or quotes."
            }
            Self::WorkspacePath => "ATLAS_REPORTS_WORKSPACE must be an absolute path.",
            Self::InvalidInput => {
                "Use a report UUID, supported status, offset 0–100000 and limit 1–50."
            }
            Self::Unauthorized => "The access key is expired, revoked or not authorized.",
            Self::NotFound => "The report was not found. It may have expired or been deleted.",
            Self::NoDiagnostics => {
                "No diagnostics are available for this report. Reports sent without a ZIP show bytes 0; expired or deleted reports have none."
            }
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
            Self::DeleteForbidden => "This access key cannot delete reports.",
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
    // Hyphenated form only; Uuid::parse_str also accepts braced, URN and simple forms.
    if value.len() != 36 {
        return Err(Error::InvalidInput);
    }
    Uuid::parse_str(value)
        .map(|id| id.to_string())
        .map_err(|_| Error::InvalidInput)
}
/// Checks a listing request against the limits and statuses the service accepts.
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
fn http_error(error: ureq::Error) -> Error {
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
/// Copies at most MAX_ZIP bytes from `reader` to `sink`, returning the count
/// and SHA-256. Read failures become `read_error`; write failures mean the
/// workspace cannot be used.
fn copy_hashed(
    mut reader: impl Read,
    mut sink: impl Write,
    read_error: Error,
) -> Result<(u64, String)> {
    let mut buffer = [0; 65536];
    let mut total = 0;
    let mut hash = digest::Context::new(&digest::SHA256);
    loop {
        let count = reader.read(&mut buffer).map_err(|_| read_error)?;
        if count == 0 {
            break;
        }
        total += count as u64;
        if total > MAX_ZIP {
            return Err(Error::TooLarge);
        }
        hash.update(&buffer[..count]);
        sink.write_all(&buffer[..count])
            .map_err(|_| Error::Workspace)?;
    }
    Ok((total, hex(hash.finish().as_ref())))
}
/// Accepts only a 200 response of the given content type.
fn expect_type(response: &ureq::http::Response<ureq::Body>, mime: &str) -> Result<()> {
    let actual = response
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok());
    if response.status().as_u16() != 200 || actual.is_none_or(|v| v.split(';').next() != Some(mime))
    {
        return Err(Error::InvalidResponse);
    }
    Ok(())
}
/// Returns the familiar `C:\…` form of a canonical `\\?\C:\…` path, which
/// some tools cannot open, when both forms name the same file.
#[cfg(windows)]
fn display_path(path: PathBuf) -> PathBuf {
    use std::path::{Component, Prefix};
    let plain = |component: Component| match component {
        Component::Prefix(prefix) => matches!(prefix.kind(), Prefix::VerbatimDisk(_)),
        Component::RootDir => true,
        // Win32 parsing trims trailing dots and spaces and maps device names.
        Component::Normal(name) => name.to_str().is_some_and(|name| {
            let stem = name.split('.').next().unwrap_or("").trim_end();
            let stem = stem.to_ascii_uppercase();
            let device = matches!(stem.as_str(), "CON" | "PRN" | "AUX" | "NUL")
                || (stem.chars().count() == 4
                    && (stem.starts_with("COM") || stem.starts_with("LPT")));
            !device
                && !name.ends_with(['.', ' '])
                && !name.contains(|c: char| c.is_control() || "<>:\"/|?*".contains(c))
        }),
        _ => false,
    };
    match path.to_str().and_then(|p| p.strip_prefix(r"\\?\")) {
        Some(simple) if simple.len() < 260 && path.components().all(plain) => simple.into(),
        _ => path,
    }
}
#[cfg(not(windows))]
fn display_path(path: PathBuf) -> PathBuf {
    path
}
struct Temporary(PathBuf);
impl Drop for Temporary {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

impl Client {
    pub fn new(config: Config) -> Result<Self> {
        if !origin_valid(&config.origin) {
            return Err(Error::Origin);
        }
        if !config.workspace.is_absolute() {
            return Err(Error::WorkspacePath);
        }
        if config.token.len() < 32
            || config.token.len() > 512
            || !config
                .token
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"-_.".contains(&b))
        {
            return Err(Error::Token);
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
        // Copies whose reports have passed their retention go before anything else.
        prune(&workspace, SystemTime::now());
        let agent = ureq::Agent::new_with_config(
            ureq::Agent::config_builder()
                .user_agent(concat!("AtlasReportsMCP/", env!("CARGO_PKG_VERSION")))
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
    /// Deletes downloaded ZIPs whose reports are past their 90 days (see
    /// [`prune`]). Runs at startup and before every tool call.
    pub fn prune(&self) -> usize {
        prune(&self.workspace, SystemTime::now())
    }
    fn request(&self, path: &str) -> Result<ureq::http::Response<ureq::Body>> {
        self.agent
            .get(&format!("{}{path}", self.origin))
            .header("Authorization", &format!("Bearer {}", self.token))
            // Uncompressed, so Content-Length and the SHA-256 header describe
            // the bytes read.
            .header("Accept-Encoding", "identity")
            .call()
            .map_err(http_error)
    }
    fn json<T: serde::de::DeserializeOwned>(&self, path: &str) -> Result<T> {
        let mut response = self.request(path)?;
        expect_type(&response, "application/json")?;
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
            // The service truncates previews to 240 characters.
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
            || detail.report.message.len() > MAX_TEXT
            || detail.report.notes.len() > MAX_TEXT
        {
            return Err(Error::InvalidResponse);
        }
        Ok(detail.report)
    }
    /// Deletes one report and returns its normalized id.
    pub fn delete(&self, id: &str, confirm: bool) -> Result<String> {
        if !confirm {
            return Err(Error::Confirmation);
        }
        let id = report_id(id)?;
        let response = self
            .agent
            .delete(&format!("{}/api/agent/reports/{id}", self.origin))
            .header("Authorization", &format!("Bearer {}", self.token))
            // ureq sends no DELETE body unless forced, and the service requires
            // confirm_id.
            .force_send_body()
            .send_json(serde_json::json!({"confirm_id":id}))
            .map_err(|error| match error {
                ureq::Error::StatusCode(403) => Error::DeleteForbidden,
                other => http_error(other),
            })?;
        if response.status().as_u16() != 204 {
            return Err(Error::InvalidResponse);
        }
        Ok(id)
    }
    pub fn download(&self, id: &str) -> Result<Download> {
        let id = report_id(id)?;
        // One download at a time: this limits disk use and stops two calls
        // racing on the same destination.
        let _lock = self.download_lock.try_lock().map_err(|_| Error::Busy)?;
        let mut response = self
            .request(&format!("/api/agent/reports/{id}/diagnostics"))
            .map_err(|error| match error {
                Error::NotFound => Error::NoDiagnostics,
                other => other,
            })?;
        expect_type(&response, "application/zip")?;
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
        // When the report was made, so the copy can be deleted with it.
        let created = response
            .headers()
            .get("x-atlas-report-created")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.parse::<i64>().ok());
        let destination = self.workspace.join(format!("{id}-{checksum}.zip"));
        let cached = regular_file(&destination)?;
        let bytes = if cached {
            let file = File::open(&destination).map_err(|_| Error::Workspace)?;
            let (bytes, current) = copy_hashed(file, io::sink(), Error::Workspace)?;
            if current != checksum || length.is_some_and(|l| l != bytes) {
                return Err(Error::Integrity);
            }
            bytes
        } else {
            let body = response.body_mut().as_reader();
            self.save(body, &destination, &checksum, length)?
        };
        if let Some(created) = created {
            record_created(&destination, created)?;
        }
        Ok(Download {
            report_id: id,
            local_path: display_path(destination),
            bytes,
            sha256: checksum,
            cached,
            extracted: false,
        })
    }
    /// Writes a download to `destination` through a private temporary file,
    /// keeping it only when its size and SHA-256 match.
    fn save(
        &self,
        body: impl Read,
        destination: &Path,
        checksum: &str,
        length: Option<u64>,
    ) -> Result<u64> {
        let temporary = Temporary(self.workspace.join(format!("{}.part", Uuid::new_v4())));
        let mut options = OpenOptions::new();
        options.write(true).create_new(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            options.mode(0o600);
        }
        let mut file = options.open(&temporary.0).map_err(|_| Error::Workspace)?;
        let (total, hash) = copy_hashed(body, &mut file, Error::Network)?;
        if total == 0 || hash != checksum || length.is_some_and(|l| l != total) {
            return Err(Error::Integrity);
        }
        file.sync_all().map_err(|_| Error::Workspace)?;
        drop(file);
        // Hard linking commits without replacing an existing file or following a
        // symbolic link. The temporary name is removed by its guard.
        fs::hard_link(&temporary.0, destination).map_err(|_| Error::Workspace)?;
        Ok(total)
    }
}

/// Records when a downloaded ZIP's report was made, beside it, unless that
/// is already recorded.
fn record_created(zip: &Path, created: i64) -> Result<()> {
    let path = sidecar(zip);
    if regular_file(&path)? {
        return Ok(());
    }
    let mut options = OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options.open(&path).map_err(|_| Error::Workspace)?;
    file.write_all(created.to_string().as_bytes())
        .map_err(|_| Error::Workspace)
}

fn sidecar(zip: &Path) -> PathBuf {
    let mut name = zip.as_os_str().to_owned();
    name.push(CREATED_SUFFIX);
    PathBuf::from(name)
}

/// Whether `name` is a ZIP this server saved: `{report id}-{sha256}.zip`.
fn downloaded_zip(name: &str) -> bool {
    name.strip_suffix(".zip")
        .and_then(|stem| stem.get(..36).zip(stem.get(36..)))
        .is_some_and(|(id, rest)| {
            report_id(id).is_ok()
                && rest.strip_prefix('-').is_some_and(|hash| {
                    hash.len() == 64 && hash.bytes().all(|b| b.is_ascii_hexdigit())
                })
        })
}

/// Deletes each ZIP this server downloaded into `workspace` once its
/// report's retention has ended at `now`, with the record of when that
/// report was made. A ZIP downloaded before that was recorded goes 90 days
/// after it was saved. Other files are left alone; nothing that can't be
/// read or removed stops the rest. Returns how many ZIPs were deleted.
pub fn prune(workspace: &Path, now: SystemTime) -> usize {
    let Ok(entries) = fs::read_dir(workspace) else {
        return 0;
    };
    let mut deleted = 0;
    for entry in entries.flatten() {
        let name = entry.file_name();
        let Some(name) = name.to_str() else { continue };
        if !downloaded_zip(name) {
            continue;
        }
        let zip = entry.path();
        if !matches!(regular_file(&zip), Ok(true)) {
            continue;
        }
        let started = fs::read_to_string(sidecar(&zip))
            .ok()
            .and_then(|text| text.trim().parse::<u64>().ok())
            .map(|seconds| UNIX_EPOCH + Duration::from_secs(seconds))
            .or_else(|| fs::metadata(&zip).and_then(|m| m.modified()).ok());
        let Some(started) = started else { continue };
        if now
            .duration_since(started)
            .is_ok_and(|age| age >= RETENTION)
            && fs::remove_file(&zip).is_ok()
        {
            let _ = fs::remove_file(sidecar(&zip));
            deleted += 1;
        }
    }
    deleted
}

#[cfg(all(test, windows))]
mod tests {
    use super::display_path;

    #[test]
    fn verbatim_paths_are_simplified_only_when_equivalent() {
        let show = |path: &str| display_path(path.into()).to_str().unwrap().to_owned();
        assert_eq!(
            show(r"\\?\C:\Users\me\work\a.zip"),
            r"C:\Users\me\work\a.zip"
        );
        let long = format!(r"\\?\C:\{}\a.zip", "x".repeat(260));
        for kept in [
            r"\\?\UNC\server\share\a.zip",
            r"\\?\C:\work\con\a.zip",
            r"\\?\C:\work\LPT1.log\a.zip",
            r"\\?\C:\work.\a.zip",
            r"\\?\C:\work \a.zip",
            &long,
        ] {
            assert_eq!(show(kept), kept);
        }
    }
}
