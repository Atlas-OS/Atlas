use crate::{
    ApiError, ApiResult, AppState, MAX_REPORTS, MAX_ZIP, PRIVACY_VERSION, archive, hex, now, sha,
};
use axum::{
    Json, Router,
    body::Body,
    extract::{ConnectInfo, DefaultBodyLimit, Path, Query, Request, State},
    http::{HeaderMap, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{get, post, put},
};
use futures_util::StreamExt;
use ring::digest;
use rusqlite::{OptionalExtension, params};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::{net::SocketAddr, time::Duration};
use tokio::io::AsyncWriteExt;
use tower::ServiceExt;
use tower_http::services::{ServeDir, ServeFile};
use uuid::Uuid;

fn error(code: StatusCode, message: &'static str) -> ApiError {
    ApiError(code, message)
}
fn header<'a>(headers: &'a HeaderMap, name: &str) -> &'a str {
    headers
        .get(name)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
}
fn trusted(state: &AppState, request: &Request) -> bool {
    let peer = request.extensions().get::<ConnectInfo<SocketAddr>>();
    let supplied = header(request.headers(), "x-atlas-gateway");
    peer.is_some_and(|peer| state.config.proxy_ips.contains(&peer.0.ip()))
        && state.verify_gateway(supplied)
}
fn rate(state: &AppState, request: &Request, action: &str, limit: i64) -> ApiResult<()> {
    let peer = request
        .extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|p| p.0.ip().to_string())
        .unwrap_or_else(|| "unknown".into());
    // Cloudflare's verified ingress supplies the original client. Portable
    // proxies must strip that header and append their own forwarded address.
    // Neither header is trusted without both a pinned peer and gateway secret.
    let address = if trusted(state, request) {
        header(request.headers(), "cf-connecting-ip")
            .parse::<std::net::IpAddr>()
            .ok()
            .or_else(|| {
                header(request.headers(), "x-forwarded-for")
                    .rsplit(',')
                    .next()
                    .and_then(|v| v.trim().parse::<std::net::IpAddr>().ok())
            })
            .map(|v| v.to_string())
            .unwrap_or(peer)
    } else {
        peer
    };
    let hour = now() / 3600;
    let bucket = format!("{hour}:{}:{action}", state.signature(&address));
    let db = state.db.lock().unwrap();
    db.execute(
        "DELETE FROM rates WHERE CAST(substr(bucket,1,instr(bucket,':')-1) AS INTEGER) < ?1",
        [hour - 24],
    )?;
    let global = format!("{hour}:global:{action}");
    db.execute(
        "INSERT INTO rates VALUES(?1,1) ON CONFLICT(bucket) DO UPDATE SET n=n+1",
        [&global],
    )?;
    let global_count: i64 =
        db.query_row("SELECT n FROM rates WHERE bucket=?1", [&global], |r| {
            r.get(0)
        })?;
    if global_count > 1000 {
        return Err(error(
            StatusCode::TOO_MANY_REQUESTS,
            "Reports are busy. Please try again later.",
        ));
    }
    db.execute(
        "INSERT INTO rates VALUES(?1,1) ON CONFLICT(bucket) DO UPDATE SET n=n+1",
        [&bucket],
    )?;
    let count: i64 = db.query_row("SELECT n FROM rates WHERE bucket=?1", [&bucket], |r| {
        r.get(0)
    })?;
    if count > limit {
        return Err(error(
            StatusCode::TOO_MANY_REQUESTS,
            "Please try again later.",
        ));
    }
    Ok(())
}
async fn admin_guard(State(state): State<AppState>, request: Request, next: Next) -> Response {
    let user = header(request.headers(), "remote-user");
    if !trusted(&state, &request) || !state.config.admins.iter().any(|u| u == user) {
        return error(StatusCode::UNAUTHORIZED, "Administrator sign-in required.").into_response();
    }
    if !matches!(
        *request.method(),
        axum::http::Method::GET | axum::http::Method::HEAD
    ) {
        let token = header(request.headers(), "x-atlas-csrf");
        let day = now() / 86400;
        if header(request.headers(), "origin") != state.config.origin
            || ![day, day - 1]
                .iter()
                .any(|d| state.verify(&format!("csrf:{user}:{d}"), token))
        {
            return error(StatusCode::FORBIDDEN, "Refresh the page before saving.").into_response();
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
        .layer(middleware::from_fn_with_state(state.clone(), admin_guard))
        .layer(DefaultBodyLimit::max(32768));
    let uploads = Router::new()
        .route("/api/v1/reports/{id}/diagnostics", put(upload))
        .layer(DefaultBodyLimit::disable());
    let static_files = ServeDir::new(&state.config.web).append_index_html_on_directories(true);
    let admin_file = ServeFile::new(state.config.web.join("index.html"));
    Router::new()
        .route("/api/v1/info", get(info))
        .route(
            "/api/v1/reports",
            post(submit).layer(DefaultBodyLimit::max(32768)),
        )
        .route("/health", get(health))
        .route_service("/admin", admin_file)
        .nest("/api/admin", admin)
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
    Json(
        json!({"privacy_version":PRIVACY_VERSION,"retention_days":state.config.retention_days,"max_zip_bytes":MAX_ZIP,"operator":"Atlas team","destination":state.config.origin}),
    )
}
async fn health(State(state): State<AppState>) -> ApiResult<Json<Value>> {
    state
        .db
        .lock()
        .unwrap()
        .query_row("SELECT 1", [], |_| Ok(()))?;
    Ok(Json(json!({"status":"ok"})))
}
async fn read_json<T: serde::de::DeserializeOwned>(request: Request) -> ApiResult<T> {
    if header(request.headers(), "content-type")
        .split(';')
        .next()
        .unwrap_or("")
        != "application/json"
    {
        return Err(error(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "Use JSON report details.",
        ));
    }
    let bytes = tokio::time::timeout(
        Duration::from_secs(15),
        axum::body::to_bytes(request.into_body(), 32768),
    )
    .await
    .map_err(|_| {
        error(
            StatusCode::REQUEST_TIMEOUT,
            "Request timed out. Please retry.",
        )
    })?
    .map_err(|_| error(StatusCode::PAYLOAD_TOO_LARGE, "Message is too large."))?;
    serde_json::from_slice(&bytes)
        .map_err(|_| error(StatusCode::UNPROCESSABLE_ENTITY, "Invalid report details."))
}
async fn submit(
    State(state): State<AppState>,
    request: Request,
) -> ApiResult<(StatusCode, Json<Value>)> {
    let origin = header(request.headers(), "origin");
    if !origin.is_empty() && origin != state.config.origin {
        return Err(error(StatusCode::FORBIDDEN, "Invalid request origin."));
    }
    rate(&state, &request, "report", 12)?;
    let mut details: ReportInput = read_json(request).await?;
    details.message = details.message.trim().to_owned();
    details.contact = details.contact.trim().to_owned();
    details.version = details.version.trim().to_owned();
    if !(10..=4000).contains(&details.message.chars().count())
        || details.contact.chars().count() > 254
        || details.version.chars().count() > 80
        || !["issue", "suggestion"].contains(&details.category.as_str())
        || !details.consent
        || details.privacy_version != PRIVACY_VERSION
        || details.submission_key.get_version_num() != 4
    {
        return Err(error(
            StatusCode::UNPROCESSABLE_ENTITY,
            "Enter a short message and confirm sharing.",
        ));
    }
    let key_hash = state.signature(&details.submission_key.to_string());
    let fingerprint = sha(&serde_json::to_vec(&details).unwrap());
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction_with_behavior(rusqlite::TransactionBehavior::Immediate)?;
    let old: Option<(String, String, bool)> = transaction
        .query_row(
            "SELECT id,fingerprint,ready FROM reports WHERE key_hash=?1",
            [&key_hash],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .optional()?;
    let (id, ready) = if let Some((id, old_fingerprint, ready)) = old {
        if fingerprint != old_fingerprint {
            return Err(error(
                StatusCode::CONFLICT,
                "This report has changed. Start a new submission.",
            ));
        }
        (id, ready)
    } else {
        let count: i64 = transaction.query_row(
            "SELECT count(*) FROM reports WHERE created > ?1",
            [now() - 86400],
            |r| r.get(0),
        )?;
        let all: i64 = transaction.query_row("SELECT count(*) FROM reports", [], |r| r.get(0))?;
        if count >= 500
            || all >= MAX_REPORTS
            || fs2::available_space(&state.config.data)? < MAX_ZIP * 2
        {
            return Err(error(
                StatusCode::SERVICE_UNAVAILABLE,
                "Reports are temporarily unavailable. Save your diagnostics and retry later.",
            ));
        }
        let id = Uuid::new_v4().to_string();
        transaction.execute("INSERT INTO reports(id,key_hash,fingerprint,created,category,message,contact,version,expects_zip,ready,privacy_version) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11)", params![id,key_hash,fingerprint,now(),details.category,details.message,details.contact,details.version,details.has_diagnostics,!details.has_diagnostics,PRIVACY_VERSION])?;
        (id, !details.has_diagnostics)
    };
    transaction.commit()?;
    Ok((
        StatusCode::CREATED,
        Json(
            json!({"id":id,"received":ready,"upload_token":details.has_diagnostics.then(|| state.signature(&format!("upload:{id}:{key_hash}")))}),
        ),
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
        return Err(error(StatusCode::NOT_FOUND, "Upload not found."));
    };
    let supplied = header(request.headers(), "authorization")
        .strip_prefix("Bearer ")
        .unwrap_or("");
    if !expects
        || created < now() - 86400
        || !state.verify(&format!("upload:{id}:{key_hash}"), supplied)
    {
        return Err(error(StatusCode::NOT_FOUND, "Upload not found."));
    }
    if ready {
        return Ok(Json(json!({"id":id,"received":true})));
    }
    if header(request.headers(), "content-type") != "application/zip" {
        return Err(error(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "Choose an Atlas diagnostic ZIP.",
        ));
    }
    if let Some(size) = request.headers().get("content-length") {
        let size = size
            .to_str()
            .ok()
            .and_then(|s| s.parse::<u64>().ok())
            .ok_or(error(StatusCode::BAD_REQUEST, "Invalid upload length."))?;
        if size > MAX_ZIP {
            return Err(error(
                StatusCode::PAYLOAD_TOO_LARGE,
                "Diagnostics exceed the 64 MB upload limit.",
            ));
        }
    }
    let permit = state.uploads.clone().try_acquire_owned().map_err(|_| {
        error(
            StatusCode::SERVICE_UNAVAILABLE,
            "Uploads are busy. Please retry shortly.",
        )
    })?;
    let used = state.stored_bytes()?;
    if used.saturating_add(MAX_ZIP * 2) > state.config.quota_bytes
        || fs2::available_space(&state.config.data)? < MAX_ZIP * 2
    {
        return Err(error(
            StatusCode::SERVICE_UNAVAILABLE,
            "Report storage is temporarily full. Save your diagnostics and retry later.",
        ));
    }
    let temporary = Temporary(
        state
            .config
            .data
            .join("uploads")
            .join(format!("{}.part", Uuid::new_v4())),
    );
    let mut file = tokio::fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&temporary.0)
        .await?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        file.set_permissions(std::fs::Permissions::from_mode(0o600))
            .await?;
    }
    let mut stream = request.into_body().into_data_stream();
    let mut total = 0;
    let mut digest = digest::Context::new(&digest::SHA256);
    tokio::time::timeout(Duration::from_secs(120), async {
        while let Some(chunk) = stream.next().await {
            let chunk = chunk
                .map_err(|_| error(StatusCode::BAD_REQUEST, "Upload interrupted. Please retry."))?;
            total += chunk.len() as u64;
            if total > MAX_ZIP {
                return Err(error(
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
        error(
            StatusCode::REQUEST_TIMEOUT,
            "Upload timed out. Please retry.",
        )
    })??;
    drop(file);
    let path = temporary.0.clone();
    // The blocking validator retains its permit even if the HTTP client leaves.
    let (summary, _permit) =
        tokio::task::spawn_blocking(move || (archive::validate(&path), permit))
            .await
            .map_err(|_| {
                error(
                    StatusCode::SERVICE_UNAVAILABLE,
                    "Couldn’t validate diagnostics. Please retry.",
                )
            })?;
    let summary = summary?;
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction_with_behavior(rusqlite::TransactionBehavior::Immediate)?;
    let current: Option<bool> = transaction
        .query_row(
            "SELECT ready FROM reports WHERE id=?1",
            [id.to_string()],
            |r| r.get(0),
        )
        .optional()?;
    if current == Some(false) {
        std::fs::rename(&temporary.0, state.file(id))?;
        #[cfg(unix)]
        std::fs::File::open(state.config.data.join("uploads"))?.sync_all()?;
        transaction.execute(
            "UPDATE reports SET ready=1,bytes=?1,digest=?2,summary=?3 WHERE id=?4",
            params![
                total as i64,
                hex(digest.finish().as_ref()),
                summary.to_string(),
                id.to_string()
            ],
        )?;
    } else if current.is_none() {
        return Err(error(StatusCode::NOT_FOUND, "Report no longer available."));
    }
    transaction.commit()?;
    Ok(Json(json!({"id":id,"received":true})))
}

async fn session(State(state): State<AppState>, headers: HeaderMap) -> Json<Value> {
    let user = header(&headers, "remote-user");
    Json(json!({"user":user,"csrf":state.signature(&format!("csrf:{user}:{}",now()/86400))}))
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
    if !(0..=100000).contains(&filter.offset)
        || !["", "new", "investigating", "resolved", "closed"].contains(&filter.status.as_str())
    {
        return Err(error(StatusCode::UNPROCESSABLE_ENTITY, "Invalid filter."));
    }
    let db = state.db.lock().unwrap();
    let mut statement = db.prepare("SELECT id,created,category,message,contact,version,bytes,summary,status,notes FROM reports WHERE ready=1 AND (?1='' OR status=?1) ORDER BY created DESC,id LIMIT 50 OFFSET ?2")?;
    let rows = statement.query_map(params![filter.status,filter.offset], |r| Ok(json!({"id":r.get::<_,String>(0)?,"created":r.get::<_,i64>(1)?,"category":r.get::<_,String>(2)?,"message":r.get::<_,String>(3)?,"contact":r.get::<_,String>(4)?,"version":r.get::<_,String>(5)?,"bytes":r.get::<_,i64>(6)?,"summary":serde_json::from_str::<Value>(&r.get::<_,String>(7)?).unwrap_or(json!({})),"status":r.get::<_,String>(8)?,"notes":r.get::<_,String>(9)?})))?.collect::<Result<Vec<_>,_>>()?;
    let total: i64 = db.query_row(
        "SELECT count(*) FROM reports WHERE ready=1 AND (?1='' OR status=?1)",
        [&filter.status],
        |r| r.get(0),
    )?;
    Ok(Json(json!({"reports":rows,"total":total})))
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
    if !["new", "investigating", "resolved", "closed"].contains(&details.status.as_str())
        || details.notes.chars().count() > 8000
    {
        return Err(error(
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
        return Err(error(StatusCode::NOT_FOUND, "Report not found."));
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
    {
        let db = state.db.lock().unwrap();
        let bytes: Option<i64> = db
            .query_row(
                "SELECT bytes FROM reports WHERE id=?1 AND ready=1",
                [id.to_string()],
                |r| r.get(0),
            )
            .optional()?;
        if bytes.unwrap_or(0) == 0 {
            return Err(error(StatusCode::NOT_FOUND, "Diagnostics not found."));
        }
        db.execute(
            "INSERT INTO audit VALUES(?1,?2,'download',?3)",
            params![
                now(),
                header(request.headers(), "remote-user"),
                id.to_string()
            ],
        )?;
    }
    let response = ServeFile::new(state.file(id))
        .oneshot(request)
        .await
        .unwrap();
    let mut response = response.map(Body::new);
    response
        .headers_mut()
        .insert("content-type", "application/zip".parse().unwrap());
    response.headers_mut().insert(
        "content-disposition",
        format!("attachment; filename=\"Atlas-report-{id}.zip\"")
            .parse()
            .unwrap(),
    );
    Ok(response)
}
async fn delete(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    headers: HeaderMap,
) -> ApiResult<StatusCode> {
    let mut db = state.db.lock().unwrap();
    let transaction = db.transaction()?;
    let path = state.file(id);
    if path.exists() {
        std::fs::remove_file(path)?;
    }
    transaction.execute("DELETE FROM reports WHERE id=?1", [id.to_string()])?;
    transaction.execute(
        "INSERT INTO audit VALUES(?1,?2,'delete',?3)",
        params![now(), header(&headers, "remote-user"), id.to_string()],
    )?;
    transaction.commit()?;
    Ok(StatusCode::NO_CONTENT)
}
