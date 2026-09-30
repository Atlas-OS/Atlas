//! Public, opt-in report intake. Attachments are validated in place and never
//! extracted, executed or made publicly readable. See README.md for the boundary
//! between the public API and the authenticated reverse proxy.
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
    net::IpAddr,
    path::PathBuf,
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::sync::Semaphore;

pub const MAX_ZIP: u64 = 64 * 1024 * 1024;
pub const PRIVACY_VERSION: &str = "2026-09-30";
pub const MAX_REPORTS: i64 = 10_000;
pub type ApiResult<T> = Result<T, ApiError>;

pub struct ApiError(pub StatusCode, pub &'static str);
impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (self.0, Json(json!({"detail": self.1}))).into_response()
    }
}
impl From<rusqlite::Error> for ApiError {
    fn from(error: rusqlite::Error) -> Self {
        eprintln!("Report database operation failed: {error}");
        Self(
            StatusCode::SERVICE_UNAVAILABLE,
            "Reports are temporarily unavailable. Please retry.",
        )
    }
}
impl From<std::io::Error> for ApiError {
    fn from(error: std::io::Error) -> Self {
        eprintln!("Report storage operation failed: {error}");
        Self(
            StatusCode::SERVICE_UNAVAILABLE,
            "Report storage is temporarily unavailable. Save your diagnostics and retry.",
        )
    }
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

pub struct Config {
    pub data: PathBuf,
    pub web: PathBuf,
    pub origin: String,
    pub gateway_secret: String,
    pub admins: Vec<String>,
    pub proxy_ips: Vec<IpAddr>,
    pub quota_bytes: u64,
    pub retention_days: i64,
}

pub struct Store {
    pub config: Config,
    pub db: Mutex<Connection>,
    pub uploads: Arc<Semaphore>,
    requests: Semaphore,
}
pub type AppState = Arc<Store>;
impl Store {
    pub fn signature(&self, value: &str) -> String {
        let key = hmac::Key::new(hmac::HMAC_SHA256, self.config.gateway_secret.as_bytes());
        hex(hmac::sign(&key, value.as_bytes()).as_ref())
    }
    pub fn verify(&self, value: &str, signature: &str) -> bool {
        if signature.len() != 64 || !signature.bytes().all(|b| b.is_ascii_hexdigit()) {
            return false;
        }
        let tag = (0..64)
            .step_by(2)
            .map(|i| u8::from_str_radix(&signature[i..i + 2], 16))
            .collect::<Result<Vec<_>, _>>();
        let Ok(tag) = tag else {
            return false;
        };
        let key = hmac::Key::new(hmac::HMAC_SHA256, self.config.gateway_secret.as_bytes());
        hmac::verify(&key, value.as_bytes(), &tag).is_ok()
    }
    pub fn verify_gateway(&self, supplied: &str) -> bool {
        let expected_key = hmac::Key::new(hmac::HMAC_SHA256, self.config.gateway_secret.as_bytes());
        let supplied_key = hmac::Key::new(hmac::HMAC_SHA256, supplied.as_bytes());
        hmac::verify(
            &expected_key,
            b"atlas-gateway",
            hmac::sign(&supplied_key, b"atlas-gateway").as_ref(),
        )
        .is_ok()
    }
    pub fn file(&self, id: uuid::Uuid) -> PathBuf {
        self.config.data.join("uploads").join(format!("{id}.zip"))
    }
    pub fn stored_bytes(&self) -> ApiResult<u64> {
        // Include interrupted and orphaned uploads, not just committed rows.
        let mut bytes = 0u64;
        for entry in std::fs::read_dir(self.config.data.join("uploads"))? {
            let entry = entry?;
            let metadata = entry.metadata()?;
            if metadata.is_file() {
                bytes = bytes.checked_add(metadata.len()).ok_or(ApiError(
                    StatusCode::SERVICE_UNAVAILABLE,
                    "Report storage is full.",
                ))?;
            }
        }
        Ok(bytes)
    }
    pub fn prune(&self) -> ApiResult<()> {
        let db = self.db.lock().unwrap();
        let cutoff = now() - self.config.retention_days * 86400;
        let mut statement =
            db.prepare("SELECT id FROM reports WHERE created < ?1 OR (ready=0 AND created < ?2)")?;
        let ids = statement
            .query_map([cutoff, now() - 86400], |row| row.get::<_, String>(0))?
            .collect::<Result<Vec<_>, _>>()?;
        for id in ids {
            if let Ok(id) = id.parse() {
                let path = self.file(id);
                if path.exists() {
                    std::fs::remove_file(path)?;
                }
            }
            db.execute("DELETE FROM reports WHERE id=?1", [&id])?;
        }
        db.execute("DELETE FROM audit WHERE at < ?1", [cutoff])?;
        db.execute("DELETE FROM audit WHERE rowid NOT IN (SELECT rowid FROM audit ORDER BY rowid DESC LIMIT 10000)", [])?;
        for entry in std::fs::read_dir(self.config.data.join("uploads"))? {
            let entry = entry?;
            if entry.path().extension().is_some_and(|e| e == "part")
                && entry
                    .metadata()?
                    .modified()?
                    .elapsed()
                    .unwrap_or_default()
                    .as_secs()
                    > 86400
            {
                std::fs::remove_file(entry.path())?;
            }
            if entry.path().extension().is_some_and(|e| e == "zip") {
                let id = entry
                    .path()
                    .file_stem()
                    .and_then(|n| n.to_str())
                    .unwrap_or("")
                    .to_owned();
                let ready: bool = db.query_row(
                    "SELECT EXISTS(SELECT 1 FROM reports WHERE id=?1 AND ready=1)",
                    [&id],
                    |r| r.get(0),
                )?;
                // Recover crashes between the atomic rename and SQLite commit.
                if !ready {
                    std::fs::remove_file(entry.path())?;
                }
            }
        }
        Ok(())
    }
}

pub fn create(config: Config) -> ApiResult<(Router, AppState)> {
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
    if !valid_origin
        || config.gateway_secret.len() < 32
        || config.gateway_secret.chars().any(char::is_control)
        || config.admins.is_empty()
        || config
            .admins
            .iter()
            .any(|a| a.is_empty() || a.chars().any(char::is_control))
        || config.proxy_ips.is_empty()
        || config
            .proxy_ips
            .iter()
            .any(|ip| ip.is_unspecified() || ip.is_multicast())
        || !(1..=365).contains(&config.retention_days)
        || config.quota_bytes < MAX_ZIP * 2
    {
        return Err(ApiError(
            StatusCode::INTERNAL_SERVER_ERROR,
            "Invalid service configuration",
        ));
    }
    if std::fs::symlink_metadata(&config.data).is_ok_and(|m| m.file_type().is_symlink()) {
        return Err(ApiError(
            StatusCode::INTERNAL_SERVER_ERROR,
            "Data directory must not be a symbolic link",
        ));
    }
    std::fs::create_dir_all(config.data.join("uploads"))?;
    if std::fs::symlink_metadata(config.data.join("uploads"))?
        .file_type()
        .is_symlink()
    {
        return Err(ApiError(
            StatusCode::INTERNAL_SERVER_ERROR,
            "Upload directory must not be a symbolic link",
        ));
    }
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        for path in [&config.data, &config.data.join("uploads")] {
            std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o700))?;
        }
    }
    let db = Connection::open(config.data.join("reports.sqlite3"))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(
            config.data.join("reports.sqlite3"),
            std::fs::Permissions::from_mode(0o600),
        )?;
    }
    db.busy_timeout(std::time::Duration::from_secs(10))?;
    db.execute_batch("PRAGMA journal_mode=WAL;
        CREATE TABLE IF NOT EXISTS reports(id TEXT PRIMARY KEY,key_hash TEXT UNIQUE NOT NULL,fingerprint TEXT NOT NULL,created INTEGER NOT NULL,category TEXT NOT NULL,message TEXT NOT NULL,contact TEXT NOT NULL,version TEXT NOT NULL,expects_zip INTEGER NOT NULL,ready INTEGER NOT NULL,bytes INTEGER NOT NULL DEFAULT 0,digest TEXT NOT NULL DEFAULT '',summary TEXT NOT NULL DEFAULT '{}',status TEXT NOT NULL DEFAULT 'new',notes TEXT NOT NULL DEFAULT '',privacy_version TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS rates(bucket TEXT PRIMARY KEY,n INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS audit(at INTEGER NOT NULL,actor TEXT NOT NULL,action TEXT NOT NULL,report_id TEXT NOT NULL);
        CREATE TRIGGER IF NOT EXISTS audit_bound AFTER INSERT ON audit BEGIN
            DELETE FROM audit WHERE rowid <= NEW.rowid - 10000;
        END;")?;
    let state = Arc::new(Store {
        config,
        db: Mutex::new(db),
        uploads: Arc::new(Semaphore::new(2)),
        requests: Semaphore::new(32),
    });
    state.prune()?;
    let app =
        routes::router(state.clone()).layer(middleware::from_fn_with_state(state.clone(), guard));
    Ok((app, state))
}

async fn guard(State(state): State<AppState>, request: Request<Body>, next: Next) -> Response {
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
