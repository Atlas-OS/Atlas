use crate::{
    ApiError, ApiResult, AppState, DAY, HOUR, MAX_JSON, MAX_REPORTS, MAX_ZIP, PRIVACY_VERSION,
    RETENTION_DAYS, STATUSES, UPLOAD_HEADROOM, archive, bump, claim, hex, is_hex64, now,
    purge_rates, remove_if_present, scrub_wal, sha,
};
use axum::{
    Json, Router,
    body::Body,
    extract::{ConnectInfo, DefaultBodyLimit, Path, Query, Request, State},
    http::{HeaderMap, Method, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{get, post, put},
};
use futures_util::StreamExt;
use ring::digest;
use rusqlite::{Connection, OptionalExtension, TransactionBehavior, params};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::{
    net::{IpAddr, Ipv6Addr, SocketAddr},
    time::Duration,
};
use tokio::io::AsyncWriteExt;
use tower::ServiceExt;
use tower_http::services::{ServeDir, ServeFile};
use uuid::Uuid;

pub(crate) fn header<'a>(headers: &'a HeaderMap, name: &str) -> &'a str {
    headers
        .get(name)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
}
pub(crate) fn trusted(state: &AppState, request: &Request) -> bool {
    let peer = request.extensions().get::<ConnectInfo<SocketAddr>>();
    let supplied = header(request.headers(), "x-atlas-gateway");
    peer.is_some_and(|peer| state.config.proxy_ips.contains(&peer.0.ip()))
        && state.verify_gateway(supplied)
}
/// A host usually controls a whole IPv6 /64, so it shares one rate identity.
/// IPv4-mapped addresses are canonicalised first so they stay per address.
fn client_key(ip: IpAddr) -> String {
    match ip.to_canonical() {
        IpAddr::V4(v4) => v4.to_string(),
        IpAddr::V6(v6) => format!("{}/64", Ipv6Addr::from(u128::from(v6) & (!0u128 << 64))),
    }
}
pub(crate) fn rate(state: &AppState, request: &Request, action: &str, limit: i64) -> ApiResult<()> {
    let peer = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|p| p.0.ip());
    // Behind Cloudflare, CF-Connecting-IP is the client. Other proxies must strip
    // it and append the client to X-Forwarded-For. Both are ignored unless the
    // peer is a pinned proxy with the gateway secret.
    let address = if trusted(state, request) {
        header(request.headers(), "cf-connecting-ip")
            .parse::<IpAddr>()
            .ok()
            .or_else(|| {
                header(request.headers(), "x-forwarded-for")
                    .rsplit(',')
                    .next()
                    .and_then(|v| v.trim().parse::<IpAddr>().ok())
            })
            .or(peer)
    } else {
        peer
    };
    let client = address.map_or_else(|| "unknown".into(), client_key);
    let hour = now() / HOUR;
    let bucket = format!("{hour}:{}:{action}", state.signature(&client));
    let global = format!("{hour}:global:{action}");
    let db = state.db.lock().unwrap();
    purge_rates(&db, hour)?;
    // Only accepted requests spend the shared budget, so one client cannot use
    // it up. Once it is spent, no new per-client buckets are stored.
    let spent: Option<i64> = db
        .query_row("SELECT n FROM rates WHERE bucket=?1", [&global], |r| {
            r.get(0)
        })
        .optional()?;
    if spent.unwrap_or(0) >= 1000 {
        return Err(ApiError(
            StatusCode::TOO_MANY_REQUESTS,
            "Reports are busy. Please try again later.",
        ));
    }
    if bump(&db, &bucket)? > limit {
        return Err(ApiError(
            StatusCode::TOO_MANY_REQUESTS,
            "Please try again later.",
        ));
    }
    bump(&db, &global)?;
    Ok(())
}
async fn admin_guard(State(state): State<AppState>, request: Request, next: Next) -> Response {
    let user = header(request.headers(), "remote-user");
    if !trusted(&state, &request) || !state.config.admins.iter().any(|u| u == user) {
        return ApiError(StatusCode::UNAUTHORIZED, "Administrator sign-in required.")
            .into_response();
    }
    if !matches!(*request.method(), Method::GET | Method::HEAD) {
        // CSRF tokens are per UTC day. Yesterday's is still accepted, so a page
        // left open past midnight can save.
        let token = header(request.headers(), "x-atlas-csrf");
        let day = now() / DAY;
        if header(request.headers(), "origin") != state.config.origin
            || ![day, day - 1]
                .iter()
                .any(|&d| state.verify(&claim::csrf(user, d), token))
        {
            return ApiError(StatusCode::FORBIDDEN, "Refresh the page before saving.")
                .into_response();
        }
    }
    next.run(request).await
}

pub fn router(state: AppState) -> Router {
    let admin = Router::new()
        .route("/session", get(session))
        .route("/reports", get(listing))
        .route("/reports/{id}", axum::routing::patch(review).delete(delete))
        .route("/reports/{id}/diagnostics", get(download))
        .route(
            "/agent-tokens",
            get(crate::agent::tokens).post(crate::agent::create_token),
        )
        .route(
            "/agent-tokens/{id}",
            axum::routing::delete(crate::agent::revoke_token),
        )
        .layer(middleware::from_fn_with_state(state.clone(), admin_guard))
        .layer(DefaultBodyLimit::max(MAX_JSON));
    // upload() streams the body and enforces MAX_ZIP itself.
    let uploads = Router::new()
        .route("/api/v1/reports/{id}/diagnostics", put(upload))
        .layer(DefaultBodyLimit::disable());
    let static_files = ServeDir::new(&state.config.web).append_index_html_on_directories(true);
    let admin_file = ServeFile::new(state.config.web.join("index.html"));
    Router::new()
        .route("/api/v1/info", get(info))
        .route(
            "/api/v1/reports",
            post(submit).layer(DefaultBodyLimit::max(MAX_JSON)),
        )
        .route("/health", get(health))
        .route_service("/admin", admin_file)
        .nest("/api/admin", admin)
        .nest("/api/agent", crate::agent::router(state.clone()))
        .merge(uploads)
        .fallback_service(static_files)
        .with_state(state)
}

#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
struct ReportInput {
    submission_key: Uuid,
    category: String,
    message: String,
    #[serde(default)]
    contact: String,
    #[serde(default)]
    version: String,
    #[serde(default)]
    has_diagnostics: bool,
    consent: bool,
    privacy_version: String,
}
async fn info(State(state): State<AppState>) -> Json<Value> {
    Json(json!({
        "privacy_version": PRIVACY_VERSION,
        "retention_days": RETENTION_DAYS,
        "max_zip_bytes": MAX_ZIP,
        "operator": "Atlas team",
        "destination": state.config.origin,
    }))
}
async fn health(State(state): State<AppState>) -> ApiResult<Json<Value>> {
    state
        .db
        .lock()
        .unwrap()
        .query_row("SELECT 1", [], |_| Ok(()))?;
    Ok(Json(json!({"status":"ok"})))
}
pub(crate) async fn read_json<T: serde::de::DeserializeOwned>(request: Request) -> ApiResult<T> {
    if header(request.headers(), "content-type")
        .split(';')
        .next()
        .unwrap_or("")
        != "application/json"
    {
        return Err(ApiError(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "Use JSON report details.",
        ));
    }
    let bytes = tokio::time::timeout(
        Duration::from_secs(15),
        axum::body::to_bytes(request.into_body(), MAX_JSON),
    )
    .await
    .map_err(|_| {
        ApiError(
            StatusCode::REQUEST_TIMEOUT,
            "Request timed out. Please retry.",
        )
    })?
    .map_err(|_| ApiError(StatusCode::PAYLOAD_TOO_LARGE, "Message is too large."))?;
    serde_json::from_slice(&bytes)
        .map_err(|_| ApiError(StatusCode::UNPROCESSABLE_ENTITY, "Invalid report details."))
}
async fn submit(
    State(state): State<AppState>,
    request: Request,
) -> ApiResult<(StatusCode, Json<Value>)> {
    let origin = header(request.headers(), "origin");
    if !origin.is_empty() && origin != state.config.origin {
        return Err(ApiError(StatusCode::FORBIDDEN, "Invalid request origin."));
    }
    rate(&state, &request, "report", 12)?;
    let mut details: ReportInput = read_json(request).await?;
    details.message = details.message.trim().to_owned();
    details.contact = details.contact.trim().to_owned();
    details.version = details.version.trim().to_owned();
    // Consent covers one notice version. Senders with an older one get their
    // own reason, so they know to reload the page or update Atlas Manager.
    if details.privacy_version != PRIVACY_VERSION {
        return Err(ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "The privacy notice has changed. Copy your message, reload this page or update Atlas Manager, then review the notice before sending.",
        ));
    }
    if !(10..=4000).contains(&details.message.chars().count())
        || details.contact.chars().count() > 254
        || details.version.chars().count() > 80
        || !["issue", "suggestion"].contains(&details.category.as_str())
        || !details.consent
        || details.submission_key.get_version_num() != 4
    {
        return Err(ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Enter a short message and confirm sharing.",
        ));
    }
    let key_hash = state.signature(&details.submission_key.to_string());
    let fingerprint = sha(&serde_json::to_vec(&details).unwrap());
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction_with_behavior(TransactionBehavior::Immediate)?;
    let old: Option<(String, String, bool)> = transaction
        .query_row(
            "SELECT id,fingerprint,ready FROM reports WHERE key_hash=?1",
            [&key_hash],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .optional()?;
    let (id, ready) = if let Some((id, old_fingerprint, ready)) = old {
        if fingerprint != old_fingerprint {
            return Err(ApiError(
                StatusCode::CONFLICT,
                "This report has changed. Start a new submission.",
            ));
        }
        (id, ready)
    } else {
        let recent: i64 = transaction.query_row(
            "SELECT count(*) FROM reports WHERE created > ?1",
            [now() - DAY],
            |r| r.get(0),
        )?;
        let all: i64 = transaction.query_row("SELECT count(*) FROM reports", [], |r| r.get(0))?;
        if recent >= 500
            || all >= MAX_REPORTS
            || fs2::available_space(&state.config.data)? < UPLOAD_HEADROOM
        {
            return Err(ApiError(
                StatusCode::SERVICE_UNAVAILABLE,
                "Reports are temporarily unavailable. Save your diagnostics and retry later.",
            ));
        }
        let id = Uuid::new_v4().to_string();
        transaction.execute(
            "INSERT INTO reports(id,key_hash,fingerprint,created,category,message,contact,version,expects_zip,ready,privacy_version)
            VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11)",
            params![
                id,
                key_hash,
                fingerprint,
                now(),
                details.category,
                details.message,
                details.contact,
                details.version,
                details.has_diagnostics,
                !details.has_diagnostics,
                PRIVACY_VERSION
            ],
        )?;
        (id, !details.has_diagnostics)
    };
    transaction.commit()?;
    let upload_token = details
        .has_diagnostics
        .then(|| state.signature(&claim::upload(&id, &key_hash)));
    Ok((
        StatusCode::CREATED,
        Json(json!({"id": id, "received": ready, "upload_token": upload_token})),
    ))
}

struct Temporary(std::path::PathBuf);
impl Drop for Temporary {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.0);
    }
}
async fn upload(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    request: Request,
) -> ApiResult<Json<Value>> {
    rate(&state, &request, "upload", 12)?;
    let row: Option<(String, i64, bool, bool)> = state
        .db
        .lock()
        .unwrap()
        .query_row(
            "SELECT key_hash,created,expects_zip,ready FROM reports WHERE id=?1",
            [id.to_string()],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
        )
        .optional()?;
    let Some((key_hash, created, expects, ready)) = row else {
        return Err(ApiError(StatusCode::NOT_FOUND, "Upload not found."));
    };
    let supplied = header(request.headers(), "authorization")
        .strip_prefix("Bearer ")
        .unwrap_or("");
    if !expects
        || created < now() - DAY
        || !state.verify(&claim::upload(&id.to_string(), &key_hash), supplied)
    {
        return Err(ApiError(StatusCode::NOT_FOUND, "Upload not found."));
    }
    if ready {
        return Ok(Json(json!({"id":id,"received":true})));
    }
    if header(request.headers(), "content-type") != "application/zip" {
        return Err(ApiError(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "Choose an Atlas diagnostic ZIP.",
        ));
    }
    if let Some(size) = request.headers().get("content-length") {
        let size = size
            .to_str()
            .ok()
            .and_then(|s| s.parse::<u64>().ok())
            .ok_or(ApiError(StatusCode::BAD_REQUEST, "Invalid upload length."))?;
        if size > MAX_ZIP {
            return Err(ApiError(
                StatusCode::PAYLOAD_TOO_LARGE,
                "Diagnostics exceed the 64 MB upload limit.",
            ));
        }
    }
    let permit = state.uploads.clone().try_acquire_owned().map_err(|_| {
        ApiError(
            StatusCode::SERVICE_UNAVAILABLE,
            "Uploads are busy. Please retry shortly.",
        )
    })?;
    let used = state.stored_bytes()?;
    if used.saturating_add(UPLOAD_HEADROOM) > state.config.quota_bytes
        || fs2::available_space(&state.config.data)? < UPLOAD_HEADROOM
    {
        return Err(ApiError(
            StatusCode::SERVICE_UNAVAILABLE,
            "Report storage is temporarily full. Save your diagnostics and retry later.",
        ));
    }
    let (temporary, bytes, digest) = receive(&state, request.into_body()).await?;
    let path = temporary.0.clone();
    // The validator keeps the upload permit even if the client disconnects.
    let (summary, _permit) =
        tokio::task::spawn_blocking(move || (archive::validate(&path), permit))
            .await
            .map_err(|_| {
                ApiError(
                    StatusCode::SERVICE_UNAVAILABLE,
                    "Couldn’t validate diagnostics. Please retry.",
                )
            })?;
    let summary = summary?;
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction_with_behavior(TransactionBehavior::Immediate)?;
    let current: Option<bool> = transaction
        .query_row(
            "SELECT ready FROM reports WHERE id=?1",
            [id.to_string()],
            |r| r.get(0),
        )
        .optional()?;
    match current {
        None => {
            return Err(ApiError(
                StatusCode::NOT_FOUND,
                "Report no longer available.",
            ));
        }
        // A retry of this upload finished first; keep its file.
        Some(true) => {}
        Some(false) => {
            std::fs::rename(&temporary.0, state.file(id))?;
            // Persist the rename before the report is marked ready.
            #[cfg(unix)]
            std::fs::File::open(state.config.data.join("uploads"))?.sync_all()?;
            transaction.execute(
                "UPDATE reports SET ready=1,bytes=?1,digest=?2,summary=?3 WHERE id=?4",
                params![bytes as i64, digest, summary.to_string(), id.to_string()],
            )?;
        }
    }
    transaction.commit()?;
    Ok(Json(json!({"id":id,"received":true})))
}
/// Streams an upload into a temporary file, within MAX_ZIP and two minutes.
/// Returns the file, its size and its SHA-256.
async fn receive(state: &AppState, body: Body) -> ApiResult<(Temporary, u64, String)> {
    let temporary = Temporary(
        state
            .config
            .data
            .join("uploads")
            .join(format!("{}.part", Uuid::new_v4())),
    );
    let mut options = tokio::fs::OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    options.mode(0o600);
    let mut file = options.open(&temporary.0).await?;
    let mut stream = body.into_data_stream();
    let mut total = 0;
    let mut digest = digest::Context::new(&digest::SHA256);
    tokio::time::timeout(Duration::from_secs(120), async {
        while let Some(chunk) = stream.next().await {
            let chunk = chunk.map_err(|_| {
                ApiError(StatusCode::BAD_REQUEST, "Upload interrupted. Please retry.")
            })?;
            total += chunk.len() as u64;
            if total > MAX_ZIP {
                return Err(ApiError(
                    StatusCode::PAYLOAD_TOO_LARGE,
                    "Diagnostics exceed the 64 MB upload limit.",
                ));
            }
            file.write_all(&chunk).await?;
            digest.update(&chunk);
        }
        file.sync_all().await?;
        Ok::<_, ApiError>(())
    })
    .await
    .map_err(|_| {
        ApiError(
            StatusCode::REQUEST_TIMEOUT,
            "Upload timed out. Please retry.",
        )
    })??;
    Ok((temporary, total, hex(digest.finish().as_ref())))
}

async fn session(State(state): State<AppState>, headers: HeaderMap) -> Json<Value> {
    let user = header(&headers, "remote-user");
    let csrf = state.signature(&claim::csrf(user, now() / DAY));
    Json(json!({"user": user, "csrf": csrf}))
}
/// Whether a listing offset and status filter are in range.
pub(crate) fn valid_filter(offset: i64, status: &str) -> bool {
    (0..=100_000).contains(&offset) && (status.is_empty() || STATUSES.contains(&status))
}
/// Counts the reports a listing can show, of one status or all when empty.
pub(crate) fn ready_count(db: &Connection, status: &str) -> rusqlite::Result<i64> {
    db.query_row(
        "SELECT count(*) FROM reports WHERE ready=1 AND (?1='' OR status=?1)",
        [status],
        |r| r.get(0),
    )
}
/// Reads a stored archive summary, or `{}` if it cannot be parsed.
pub(crate) fn summary(row: &rusqlite::Row, index: usize) -> rusqlite::Result<Value> {
    Ok(serde_json::from_str(&row.get::<_, String>(index)?).unwrap_or(json!({})))
}
#[derive(Deserialize)]
struct Filter {
    #[serde(default)]
    offset: i64,
    #[serde(default)]
    status: String,
}
async fn listing(
    State(state): State<AppState>,
    Query(filter): Query<Filter>,
) -> ApiResult<Json<Value>> {
    if !valid_filter(filter.offset, &filter.status) {
        return Err(ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Invalid filter.",
        ));
    }
    let db = state.db.lock().unwrap();
    let mut statement = db.prepare("SELECT id,created,category,message,contact,version,bytes,summary,status,notes FROM reports WHERE ready=1 AND (?1='' OR status=?1) ORDER BY created DESC,id LIMIT 50 OFFSET ?2")?;
    let reports = statement
        .query_map(params![filter.status, filter.offset], |r| {
            Ok(json!({
                "id": r.get::<_, String>(0)?,
                "created": r.get::<_, i64>(1)?,
                "category": r.get::<_, String>(2)?,
                "message": r.get::<_, String>(3)?,
                "contact": r.get::<_, String>(4)?,
                "version": r.get::<_, String>(5)?,
                "bytes": r.get::<_, i64>(6)?,
                "summary": summary(r, 7)?,
                "status": r.get::<_, String>(8)?,
                "notes": r.get::<_, String>(9)?,
            }))
        })?
        .collect::<Result<Vec<_>, _>>()?;
    let total = ready_count(&db, &filter.status)?;
    Ok(Json(json!({"reports": reports, "total": total})))
}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Review {
    status: String,
    #[serde(default)]
    notes: String,
}
async fn review(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    request: Request,
) -> ApiResult<Json<Value>> {
    let user = header(request.headers(), "remote-user").to_owned();
    let details: Review = read_json(request).await?;
    if !STATUSES.contains(&details.status.as_str()) || details.notes.chars().count() > 8000 {
        return Err(ApiError(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Invalid review details.",
        ));
    }
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction()?;
    if transaction.execute(
        "UPDATE reports SET status=?1,notes=?2 WHERE id=?3 AND ready=1",
        params![details.status, details.notes, id.to_string()],
    )? == 0
    {
        return Err(ApiError(StatusCode::NOT_FOUND, "Report not found."));
    }
    transaction.execute(
        "INSERT INTO audit VALUES(?1,?2,'review',?3)",
        params![now(), user, id.to_string()],
    )?;
    transaction.commit()?;
    Ok(Json(json!({"saved":true})))
}
async fn download(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    request: Request,
) -> ApiResult<Response> {
    let actor = header(request.headers(), "remote-user").to_owned();
    serve_audited(&state, id, &actor, "download", request).await
}
/// Records who fetched a report's diagnostics, then serves the stored ZIP as
/// an attachment, never as page content, with its SHA-256 for checking and
/// when the report was made (Unix seconds), so a downloaded copy can be
/// deleted when the report's retention ends.
pub(crate) async fn serve_audited(
    state: &AppState,
    id: Uuid,
    actor: &str,
    action: &str,
    request: Request,
) -> ApiResult<Response> {
    let (digest, created) = {
        let db = state.db.lock().unwrap();
        let row: Option<(String, i64)> = db
            .query_row(
                "SELECT digest,created FROM reports WHERE id=?1 AND ready=1 AND bytes>0",
                [id.to_string()],
                |r| Ok((r.get(0)?, r.get(1)?)),
            )
            .optional()?;
        let row = row.ok_or(ApiError(StatusCode::NOT_FOUND, "Diagnostics not found."))?;
        db.execute(
            "INSERT INTO audit VALUES(?1,?2,?3,?4)",
            params![now(), actor, action, id.to_string()],
        )?;
        row
    };
    let mut response = ServeFile::new(state.file(id))
        .oneshot(request)
        .await
        .unwrap()
        .map(Body::new);
    let headers = response.headers_mut();
    headers.insert("content-type", "application/zip".parse().unwrap());
    headers.insert(
        "content-disposition",
        format!("attachment; filename=\"Atlas-report-{id}.zip\"")
            .parse()
            .unwrap(),
    );
    if is_hex64(&digest) {
        headers.insert("x-atlas-diagnostics-sha256", digest.parse().unwrap());
    }
    headers.insert(
        "x-atlas-report-created",
        created.to_string().parse().unwrap(),
    );
    Ok(response)
}
async fn delete(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    headers: HeaderMap,
) -> ApiResult<StatusCode> {
    delete_report(&state, id, header(&headers, "remote-user"), "delete")
}
/// Deletes a report and its attachment, records who did it and clears the
/// deleted text from the WAL.
pub(crate) fn delete_report(
    state: &AppState,
    id: Uuid,
    actor: &str,
    action: &str,
) -> ApiResult<StatusCode> {
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction_with_behavior(TransactionBehavior::Immediate)?;
    if transaction.execute(
        "DELETE FROM reports WHERE id=?1 AND ready=1",
        [id.to_string()],
    )? == 0
    {
        return Err(ApiError(StatusCode::NOT_FOUND, "Report not found."));
    }
    // Inside the transaction, so the report stays if its file cannot be removed.
    remove_if_present(&state.file(id))?;
    transaction.execute(
        "INSERT INTO audit VALUES(?1,?2,?3,?4)",
        params![now(), actor, action, id.to_string()],
    )?;
    transaction.commit()?;
    scrub_wal(&db);
    Ok(StatusCode::NO_CONTENT)
}

#[cfg(test)]
mod tests {
    use super::client_key;

    #[test]
    fn ipv6_clients_share_a_64_and_mapped_ipv4_stays_per_address() {
        let key = |ip: &str| client_key(ip.parse().unwrap());
        assert_eq!(key("2001:db8::1"), "2001:db8::/64");
        assert_eq!(key("2001:db8::ffff:1"), "2001:db8::/64");
        assert_eq!(key("2001:db8:0:1::1"), "2001:db8:0:1::/64");
        assert_eq!(key("::ffff:192.0.2.30"), "192.0.2.30");
        assert_eq!(key("::ffff:192.0.2.31"), "192.0.2.31");
        assert_eq!(key("192.0.2.30"), "192.0.2.30");
    }
}
