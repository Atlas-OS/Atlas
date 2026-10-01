//! Public, opt-in report intake. Attachments are validated in place and never
//! extracted, executed or made publicly readable. See README.md for the boundary
//! between the public API and the authenticated reverse proxy.
mod agent;
mod archive;
mod routes;

use axum::{
    Json, Router,
    body::Body,
    extract::State,
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
};
use ring::{digest, hmac};
use rusqlite::Connection;
use serde_json::json;
use std::{
    fs,
    net::IpAddr,
    path::{Path, PathBuf},
    sync::{Arc, Mutex},
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::Semaphore;

pub const MAX_ZIP: u64 = 64 * 1024 * 1024;
/// Version of the privacy notice that consent covers. The web form
/// (atlas-reports-ui `api.ts`) and Atlas Manager (`app/src/services/reports.rs`)
/// send the same value, so change all three with the notice text.
pub const PRIVACY_VERSION: &str = "2026-10-01";
pub const MAX_REPORTS: i64 = 10_000;
/// Days a report and its audit history are kept, as the privacy notice promises.
pub const RETENTION_DAYS: i64 = 90;
pub(crate) const STATUSES: [&str; 4] = ["new", "investigating", "resolved", "closed"];
pub(crate) const HOUR: i64 = 3_600;
pub(crate) const DAY: i64 = 86_400;
/// Largest JSON body on any route. reports-mcp relies on it to limit report text.
pub(crate) const MAX_JSON: usize = 32 * 1024;
/// Uploads that can be received and validated at once.
const UPLOAD_SLOTS: usize = 2;
/// Disk space kept free for every upload slot at full size.
pub(crate) const UPLOAD_HEADROOM: u64 = MAX_ZIP * UPLOAD_SLOTS as u64;
/// Requests served at once; the rest are asked to retry.
const MAX_REQUESTS: usize = 32;
/// Agent read actions, as an SQL list. They have their own audit limit, so they
/// cannot evict administrator entries.
const AGENT_ACCESS: &str = "'agent-list','agent-read','agent-download'";
/// Most agent read entries the audit log keeps.
const AGENT_AUDIT_ROWS: i64 = 10_000;
/// Most entries of every other kind the audit log keeps.
const AUDIT_ROWS: i64 = 50_000;

pub type ApiResult<T> = Result<T, ApiError>;

pub struct ApiError(pub StatusCode, pub &'static str);
impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (self.0, Json(json!({"detail": self.1}))).into_response()
    }
}
impl From<rusqlite::Error> for ApiError {
    fn from(error: rusqlite::Error) -> Self {
        log_failure("database", &error);
        Self(
            StatusCode::SERVICE_UNAVAILABLE,
            "Reports are temporarily unavailable. Please retry.",
        )
    }
}
impl From<std::io::Error> for ApiError {
    fn from(error: std::io::Error) -> Self {
        log_failure("storage", &error);
        Self(
            StatusCode::SERVICE_UNAVAILABLE,
            "Report storage is temporarily unavailable. Save your diagnostics and retry.",
        )
    }
}

/// Why the service could not start.
#[derive(Debug)]
pub enum StartupError {
    /// An invalid setting. The text names it without echoing its value.
    Config(&'static str),
    /// A storage or database failure, already logged with its cause.
    Storage,
}
impl From<rusqlite::Error> for StartupError {
    fn from(error: rusqlite::Error) -> Self {
        log_failure("database", &error);
        Self::Storage
    }
}
impl From<std::io::Error> for StartupError {
    fn from(error: std::io::Error) -> Self {
        log_failure("storage", &error);
        Self::Storage
    }
}
/// Logs the cause for the operator. Senders only ever see fixed text.
fn log_failure(kind: &str, error: &dyn std::fmt::Display) {
    eprintln!("Report {kind} operation failed: {error}");
}

pub fn now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}
pub fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}
pub fn sha(bytes: &[u8]) -> String {
    hex(digest::digest(&digest::SHA256, bytes).as_ref())
}
/// Whether `value` is 64 hex digits, the form of a SHA-256 or HMAC tag.
pub(crate) fn is_hex64(value: &str) -> bool {
    value.len() == 64 && value.bytes().all(|b| b.is_ascii_hexdigit())
}

/// Messages signed with the gateway secret. Each kind has its own prefix, so a
/// signature issued for one purpose is never accepted for another. Agent key
/// signatures are stored, so changing their format revokes every key.
pub(crate) mod claim {
    pub fn upload(id: &str, key_hash: &str) -> String {
        format!("upload:{id}:{key_hash}")
    }
    pub fn csrf(user: &str, day: i64) -> String {
        format!("csrf:{user}:{day}")
    }
    pub fn agent(token: &str) -> String {
        format!("agent:{token}")
    }
}

/// Moves committed changes into the database file and empties the WAL, so
/// deleted text does not remain in older WAL frames.
pub(crate) fn scrub_wal(db: &Connection) {
    let _ = db.query_row("PRAGMA wal_checkpoint(TRUNCATE)", [], |_| Ok(()));
}
/// Adds one to a rate bucket and returns its new count.
pub(crate) fn bump(db: &Connection, bucket: &str) -> rusqlite::Result<i64> {
    db.query_row(
        "INSERT INTO rates VALUES(?1,1) ON CONFLICT(bucket) DO UPDATE SET n=n+1 RETURNING n",
        [bucket],
        |r| r.get(0),
    )
}
/// Rate buckets are named `{hour}:…` and kept for 24 hours.
pub(crate) fn purge_rates(db: &Connection, hour: i64) -> rusqlite::Result<usize> {
    db.execute(
        "DELETE FROM rates WHERE CAST(substr(bucket,1,instr(bucket,':')-1) AS INTEGER) < ?1",
        [hour - 24],
    )
}
/// Removes a file, treating one that is already gone as removed.
pub(crate) fn remove_if_present(path: &Path) -> std::io::Result<()> {
    match fs::remove_file(path) {
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        result => result,
    }
}

pub struct Config {
    pub data: PathBuf,
    pub web: PathBuf,
    pub origin: String,
    pub gateway_secret: String,
    pub admins: Vec<String>,
    pub proxy_ips: Vec<IpAddr>,
    pub quota_bytes: u64,
}

pub struct Store {
    pub config: Config,
    pub db: Mutex<Connection>,
    pub uploads: Arc<Semaphore>,
    requests: Semaphore,
    key: hmac::Key,
}
pub type AppState = Arc<Store>;
impl Store {
    pub fn signature(&self, value: &str) -> String {
        hex(hmac::sign(&self.key, value.as_bytes()).as_ref())
    }
    pub fn verify(&self, value: &str, signature: &str) -> bool {
        // Hex digits are ASCII, so the two-byte slices below never split a character.
        if !is_hex64(signature) {
            return false;
        }
        let tag = (0..64)
            .step_by(2)
            .map(|i| u8::from_str_radix(&signature[i..i + 2], 16))
            .collect::<Result<Vec<_>, _>>();
        let Ok(tag) = tag else {
            return false;
        };
        hmac::verify(&self.key, value.as_bytes(), &tag).is_ok()
    }
    /// Compares a supplied gateway secret with the configured one in constant
    /// time, by using each as an HMAC key over the same message.
    pub fn verify_gateway(&self, supplied: &str) -> bool {
        let supplied = hmac::Key::new(hmac::HMAC_SHA256, supplied.as_bytes());
        let tag = hmac::sign(&supplied, b"atlas-gateway");
        hmac::verify(&self.key, b"atlas-gateway", tag.as_ref()).is_ok()
    }
    pub fn file(&self, id: uuid::Uuid) -> PathBuf {
        self.config.data.join("uploads").join(format!("{id}.zip"))
    }
    /// Counts every file in the upload folder, including interrupted and
    /// orphaned uploads, not just committed reports.
    pub fn stored_bytes(&self) -> ApiResult<u64> {
        let mut bytes = 0;
        for entry in fs::read_dir(self.config.data.join("uploads"))? {
            // A failed upload may remove its temporary file during the walk.
            let metadata = match entry.and_then(|entry| entry.metadata()) {
                Ok(metadata) => metadata,
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => continue,
                Err(error) => return Err(error.into()),
            };
            if metadata.is_file() {
                bytes += metadata.len();
            }
        }
        Ok(bytes)
    }
    pub fn prune(&self) -> ApiResult<()> {
        let mut db = self.db.lock().unwrap();
        let result = self.prune_locked(&mut db);
        scrub_wal(&db);
        result
    }
    // Holding the lock for the whole pass stops an upload from committing a
    // file between the ready check and its removal.
    fn prune_locked(&self, db: &mut Connection) -> ApiResult<()> {
        let cutoff = now() - RETENTION_DAYS * DAY;
        let transaction = db.transaction()?;
        // Removing the rows first leaves their attachments to the orphan sweep
        // below, so one undeletable file cannot keep other reports.
        transaction.execute(
            "DELETE FROM reports WHERE created < ?1 OR (ready=0 AND created < ?2)",
            [cutoff, now() - DAY],
        )?;
        purge_rates(&transaction, now() / HOUR)?;
        transaction.execute("DELETE FROM audit WHERE at < ?1", [cutoff])?;
        // The audit_bound trigger already limits agent reads as they are written.
        transaction.execute(
            &format!(
                "DELETE FROM audit WHERE action NOT IN ({AGENT_ACCESS}) AND rowid NOT IN
                (SELECT rowid FROM audit WHERE action NOT IN ({AGENT_ACCESS}) ORDER BY rowid DESC LIMIT {AUDIT_ROWS})"
            ),
            [],
        )?;
        transaction.commit()?;
        for entry in fs::read_dir(self.config.data.join("uploads"))?.flatten() {
            let path = entry.path();
            let remove = match path.extension().and_then(|e| e.to_str()) {
                // A recent .part file may belong to an upload in progress.
                Some("part") => entry
                    .metadata()
                    .and_then(|m| m.modified())
                    .is_ok_and(|t| t.elapsed().unwrap_or_default().as_secs() > DAY as u64),
                // Also recovers a crash between the rename and the SQLite commit.
                Some("zip") => {
                    let id = path.file_stem().and_then(|n| n.to_str()).unwrap_or("");
                    !db.query_row(
                        "SELECT EXISTS(SELECT 1 FROM reports WHERE id=?1 AND ready=1)",
                        [id],
                        |r| r.get::<_, bool>(0),
                    )?
                }
                _ => false,
            };
            if remove && let Err(error) = remove_if_present(&path) {
                eprintln!("Report storage cleanup failed: {error}");
            }
        }
        Ok(())
    }
}

/// Names the first invalid setting without echoing any configured value.
fn invalid_setting(config: &Config) -> Option<&'static str> {
    let origin = config.origin.parse::<axum::http::Uri>().ok();
    let valid_origin = origin.as_ref().is_some_and(|uri| {
        let authority = uri.authority().map(|a| a.as_str()).unwrap_or("");
        let host = uri.host().unwrap_or("").trim_matches(['[', ']']);
        let local = host == "localhost" || host.parse::<IpAddr>().is_ok_and(|ip| ip.is_loopback());
        !authority.is_empty()
            && !authority.contains('@')
            && uri.query().is_none()
            && uri.path() == "/"
            && !config.origin.ends_with('/')
            && (uri.scheme_str() == Some("https") || (local && uri.scheme_str() == Some("http")))
    });
    if !valid_origin {
        Some(
            "ATLAS_REPORTS_ORIGIN must be an https:// origin (http:// only on loopback) with no path, trailing slash, query or user info",
        )
    } else if config.gateway_secret.len() < 32
        || config.gateway_secret.chars().any(char::is_control)
    {
        Some(
            "ATLAS_REPORTS_GATEWAY_SECRET must be at least 32 characters with no control characters",
        )
    } else if config.admins.is_empty()
        || config
            .admins
            .iter()
            .any(|a| a.is_empty() || a.trim() != a || a.chars().any(char::is_control))
    {
        Some(
            "ATLAS_REPORTS_ADMINS must list at least one username, with no empty entries, surrounding spaces or control characters",
        )
    } else if config.proxy_ips.is_empty()
        || config
            .proxy_ips
            .iter()
            .any(|ip| ip.is_unspecified() || ip.is_multicast())
    {
        Some(
            "ATLAS_REPORTS_PROXY_IPS must list at least one specific proxy IP address, not an unspecified or multicast one",
        )
    } else if config.quota_bytes < UPLOAD_HEADROOM {
        Some("ATLAS_REPORTS_QUOTA_BYTES must be at least 134217728, twice the upload limit")
    } else {
        None
    }
}

/// Creates `path` if needed and, on Unix, limits access to the service account.
/// A symbolic link is refused with `symlink_error`.
fn private_dir(path: &Path, symlink_error: &'static str) -> Result<(), StartupError> {
    if fs::symlink_metadata(path).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err(StartupError::Config(symlink_error));
    }
    fs::create_dir_all(path)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(path, fs::Permissions::from_mode(0o700))?;
    }
    Ok(())
}

fn open_database(path: &Path) -> Result<Connection, StartupError> {
    let db = Connection::open(path)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(path, fs::Permissions::from_mode(0o600))?;
    }
    db.busy_timeout(Duration::from_secs(10))?;
    db.execute_batch("PRAGMA journal_mode=WAL;
        PRAGMA secure_delete=ON;
        CREATE TABLE IF NOT EXISTS reports(id TEXT PRIMARY KEY,key_hash TEXT UNIQUE NOT NULL,fingerprint TEXT NOT NULL,created INTEGER NOT NULL,category TEXT NOT NULL,message TEXT NOT NULL,contact TEXT NOT NULL,version TEXT NOT NULL,expects_zip INTEGER NOT NULL,ready INTEGER NOT NULL,bytes INTEGER NOT NULL DEFAULT 0,digest TEXT NOT NULL DEFAULT '',summary TEXT NOT NULL DEFAULT '{}',status TEXT NOT NULL DEFAULT 'new',notes TEXT NOT NULL DEFAULT '',privacy_version TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS rates(bucket TEXT PRIMARY KEY,n INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS audit(at INTEGER NOT NULL,actor TEXT NOT NULL,action TEXT NOT NULL,report_id TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS agent_tokens(id TEXT PRIMARY KEY,name TEXT NOT NULL,signature TEXT NOT NULL,created INTEGER NOT NULL,expires INTEGER NOT NULL,last_used INTEGER,revoked INTEGER NOT NULL DEFAULT 0,can_delete INTEGER NOT NULL DEFAULT 0);
        CREATE INDEX IF NOT EXISTS audit_action ON audit(action);")?;
    // Recreated on every start so the limit always matches AGENT_ACCESS.
    db.execute_batch(&format!(
        "DROP TRIGGER IF EXISTS audit_bound;
        CREATE TRIGGER audit_bound AFTER INSERT ON audit WHEN NEW.action IN ({AGENT_ACCESS}) BEGIN
            DELETE FROM audit WHERE action IN ({AGENT_ACCESS}) AND rowid <= NEW.rowid - {AGENT_AUDIT_ROWS};
        END;"
    ))?;
    // user_version 1 means the file was rebuilt once with secure_delete on, so
    // no text deleted before then remains.
    let version: i64 = db.query_row("PRAGMA user_version", [], |r| r.get(0))?;
    if version == 0 {
        match db.execute_batch("VACUUM; PRAGMA user_version=1;") {
            Ok(()) => scrub_wal(&db),
            Err(error) => {
                eprintln!("Report database compaction failed; it will retry at next start: {error}")
            }
        }
    }
    Ok(db)
}

pub fn create(config: Config) -> Result<(Router, AppState), StartupError> {
    if let Some(reason) = invalid_setting(&config) {
        return Err(StartupError::Config(reason));
    }
    private_dir(&config.data, "Data directory must not be a symbolic link")?;
    private_dir(
        &config.data.join("uploads"),
        "Upload directory must not be a symbolic link",
    )?;
    let db = open_database(&config.data.join("reports.sqlite3"))?;
    let key = hmac::Key::new(hmac::HMAC_SHA256, config.gateway_secret.as_bytes());
    let state = Arc::new(Store {
        config,
        db: Mutex::new(db),
        uploads: Arc::new(Semaphore::new(UPLOAD_SLOTS)),
        requests: Semaphore::new(MAX_REQUESTS),
        key,
    });
    if state.prune().is_err() {
        eprintln!("Startup cleanup failed; it will retry hourly.");
    }
    let app =
        routes::router(state.clone()).layer(middleware::from_fn_with_state(state.clone(), guard));
    Ok((app, state))
}

async fn guard(State(state): State<AppState>, request: Request<Body>, next: Next) -> Response {
    // Serve only the configured host, so a DNS name rebound to this server
    // cannot reach the API.
    let host = request
        .headers()
        .get("host")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    let expected = state.config.origin.split("://").nth(1).unwrap_or("");
    let permit = state.requests.try_acquire();
    let mut response = if host != expected {
        ApiError(StatusCode::BAD_REQUEST, "Invalid request host.").into_response()
    } else if let Ok(_permit) = permit {
        next.run(request).await
    } else {
        ApiError(
            StatusCode::SERVICE_UNAVAILABLE,
            "Reports are busy. Please retry shortly.",
        )
        .into_response()
    };
    for (key, value) in [
        ("x-content-type-options", "nosniff"),
        ("referrer-policy", "no-referrer"),
        ("x-frame-options", "DENY"),
        ("cache-control", "no-store"),
        (
            "content-security-policy",
            "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'",
        ),
    ] {
        response.headers_mut().insert(
            axum::http::HeaderName::from_static(key),
            axum::http::HeaderValue::from_static(value),
        );
    }
    response
}
