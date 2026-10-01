use atlas_reports::{AppState, Config, MAX_ZIP, StartupError, create};
use axum::{
    Router,
    body::{Body, to_bytes},
    extract::ConnectInfo,
    http::{Request, StatusCode},
};
use serde_json::{Value, json};
use std::{
    io::{Cursor, Write},
    net::SocketAddr,
    path::Path,
};
use tower::ServiceExt;
use uuid::Uuid;

struct Fixture {
    app: Router,
    state: AppState,
    _dir: tempfile::TempDir,
}
fn config(data: &Path) -> Config {
    Config {
        data: data.into(),
        web: data.join("web"),
        origin: "https://reports.test".into(),
        gateway_secret: "test-gateway-secret-xxxxxxxxxxxxxxxx".into(),
        admins: vec!["jack".into()],
        proxy_ips: vec!["127.0.0.1".parse().unwrap()],
        quota_bytes: 2 * 1024 * 1024 * 1024,
    }
}
impl Fixture {
    fn new() -> Self {
        Self::with(|config| config)
    }
    fn with(adjust: impl FnOnce(Config) -> Config) -> Self {
        let dir = tempfile::tempdir().unwrap();
        let (app, state) = create(adjust(config(dir.path()))).unwrap();
        Self {
            app,
            state,
            _dir: dir,
        }
    }
    async fn request(
        &self,
        method: &str,
        path: &str,
        body: Vec<u8>,
        auth: bool,
        extra: &[(&str, &str)],
    ) -> (StatusCode, Value, axum::http::HeaderMap, Vec<u8>) {
        let mut builder = Request::builder()
            .method(method)
            .uri(path)
            .header("host", "reports.test");
        if !extra.iter().any(|(key, _)| *key == "content-type") {
            builder = builder.header("content-type", "application/json");
        }
        if auth {
            builder = builder
                .header("remote-user", "jack")
                .header("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx")
                .header("origin", "https://reports.test")
                .header(
                    "x-atlas-csrf",
                    self.state
                        .signature(&format!("csrf:jack:{}", atlas_reports::now() / 86400)),
                );
        }
        for (k, v) in extra {
            builder = builder.header(*k, *v);
        }
        let mut req = builder.body(Body::from(body)).unwrap();
        req.extensions_mut().insert(ConnectInfo(
            "127.0.0.1:12345".parse::<SocketAddr>().unwrap(),
        ));
        let res = self.app.clone().oneshot(req).await.unwrap();
        let status = res.status();
        let headers = res.headers().clone();
        let bytes = to_bytes(res.into_body(), 1024 * 1024)
            .await
            .unwrap()
            .to_vec();
        (
            status,
            serde_json::from_slice(&bytes).unwrap_or(Value::Null),
            headers,
            bytes,
        )
    }
    async fn json(
        &self,
        method: &str,
        path: &str,
        value: Value,
        auth: bool,
    ) -> (StatusCode, Value) {
        let (code, body, _, _) = self
            .request(method, path, serde_json::to_vec(&value).unwrap(), auth, &[])
            .await;
        (code, body)
    }
    async fn send(&self, zip: Vec<u8>) -> (Value, StatusCode) {
        let (code, receipt) = self
            .json("POST", "/api/v1/reports", metadata(), false)
            .await;
        assert_eq!(code, StatusCode::CREATED);
        let token = format!("Bearer {}", receipt["upload_token"].as_str().unwrap());
        let path = format!(
            "/api/v1/reports/{}/diagnostics",
            receipt["id"].as_str().unwrap()
        );
        let (code, _, _, _) = self
            .request(
                "PUT",
                &path,
                zip,
                false,
                &[
                    ("authorization", &token),
                    ("content-type", "application/zip"),
                ],
            )
            .await;
        (receipt, code)
    }
}
fn metadata() -> Value {
    json!({"submission_key":Uuid::new_v4(),"category":"issue","message":"Night Light never changes the screen.","contact":"","version":"rc.8","has_diagnostics":true,"consent":true,"privacy_version":atlas_reports::PRIVACY_VERSION})
}
/// Submits a report through the trusted proxy on behalf of `client`.
async fn submit_from(fixture: &Fixture, client: &str) -> StatusCode {
    fixture
        .request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ("cf-connecting-ip", client),
            ],
        )
        .await
        .0
}
fn count(fixture: &Fixture, sql: &str) -> i64 {
    fixture
        .state
        .db
        .lock()
        .unwrap()
        .query_row(sql, [], |r| r.get(0))
        .unwrap()
}

async fn issue_agent(fixture: &Fixture, can_delete: bool) -> Value {
    let (code, value) = fixture
        .json(
            "POST",
            "/api/admin/agent-tokens",
            json!({"name":"Test agent","days":30,"can_delete":can_delete}),
            true,
        )
        .await;
    assert_eq!(code, StatusCode::CREATED);
    value
}
async fn agent_request(
    fixture: &Fixture,
    token: &Value,
    method: &str,
    path: &str,
    body: Value,
) -> (StatusCode, Value, axum::http::HeaderMap, Vec<u8>) {
    let auth = format!("Bearer {}", token["token"].as_str().unwrap());
    fixture
        .request(
            method,
            path,
            serde_json::to_vec(&body).unwrap(),
            false,
            &[
                ("authorization", &auth),
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
            ],
        )
        .await
}

#[tokio::test]
async fn agent_credentials_require_admin_and_never_list_secrets() {
    let f = Fixture::new();
    let input = json!({"name":"Test agent","days":30});
    assert_eq!(
        f.json("POST", "/api/admin/agent-tokens", input.clone(), false)
            .await
            .0,
        StatusCode::UNAUTHORIZED
    );
    let issued = issue_agent(&f, false).await;
    assert_eq!(issued["scope"], "reports:read diagnostics:read");
    let stored: String = {
        let db = f.state.db.lock().unwrap();
        db.query_row(
            "SELECT signature FROM agent_tokens WHERE id=?1",
            [issued["id"].as_str().unwrap()],
            |r| r.get(0),
        )
        .unwrap()
    };
    assert_ne!(stored, issued["token"].as_str().unwrap());
    assert!(f.state.verify(
        &format!("agent:{}", issued["token"].as_str().unwrap()),
        &stored
    ));
    let (_, listed) = f
        .json("GET", "/api/admin/agent-tokens", Value::Null, true)
        .await;
    assert_eq!(listed["tokens"][0]["can_delete"], false);
    assert!(
        !listed
            .to_string()
            .contains(issued["token"].as_str().unwrap())
    );
    assert!(!listed.to_string().contains(&stored));
    for input in [
        json!({"name":"","days":30}),
        json!({"name":"Test","days":0}),
        json!({"name":"Test","days":91}),
        json!({"name":"line\nbreak","days":30}),
    ] {
        assert_eq!(
            f.json("POST", "/api/admin/agent-tokens", input, true)
                .await
                .0,
            StatusCode::UNPROCESSABLE_ENTITY
        );
    }
}

#[tokio::test]
async fn agent_bearer_requires_trusted_gateway_and_cannot_replace_browser_auth() {
    let f = Fixture::new();
    let issued = issue_agent(&f, false).await;
    let authorization = format!("Bearer {}", issued["token"].as_str().unwrap());
    assert_eq!(
        f.request(
            "GET",
            "/api/agent/reports",
            vec![],
            false,
            &[("authorization", &authorization)]
        )
        .await
        .0,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        f.request(
            "GET",
            "/api/agent/reports",
            vec![],
            false,
            &[
                ("authorization", &authorization),
                ("x-atlas-gateway", "wrong-gateway")
            ]
        )
        .await
        .0,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        f.request(
            "GET",
            "/api/agent/reports",
            vec![],
            false,
            &[
                ("authorization", &authorization),
                ("origin", "https://reports.test"),
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx")
            ]
        )
        .await
        .0,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        f.json("GET", "/api/agent/reports", Value::Null, true)
            .await
            .0,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        agent_request(&f, &issued, "GET", "/api/admin/reports", Value::Null)
            .await
            .0,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        agent_request(&f, &issued, "POST", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::METHOD_NOT_ALLOWED
    );
    let (code, _, _, _) = f
        .request(
            "GET",
            "/api/agent/reports",
            vec![],
            false,
            &[
                ("authorization", "Bearer atlas_reports_invalid_123"),
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
            ],
        )
        .await;
    assert_eq!(code, StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn unauthenticated_agent_requests_spend_no_shared_budget() {
    let f = Fixture::new();
    let issued = issue_agent(&f, false).await;
    let unknown = format!("Bearer atlas_reports_{}_{}", Uuid::new_v4(), "0".repeat(64));
    let forged = format!(
        "Bearer atlas_reports_{}_{}",
        issued["id"].as_str().unwrap(),
        "0".repeat(64)
    );
    let written = || {
        let db = f.state.db.lock().unwrap();
        let rates: (i64, i64) = db
            .query_row("SELECT count(*), coalesce(sum(n),0) FROM rates", [], |r| {
                Ok((r.get(0)?, r.get(1)?))
            })
            .unwrap();
        let last_used: Option<i64> = db
            .query_row(
                "SELECT last_used FROM agent_tokens WHERE id=?1",
                [issued["id"].as_str().unwrap()],
                |r| r.get(0),
            )
            .unwrap();
        (rates, last_used)
    };
    let before = written();
    for authorization in ["Bearer garbage", &unknown, &forged] {
        let (code, _, _, _) = f
            .request(
                "GET",
                "/api/agent/reports",
                vec![],
                false,
                &[
                    ("authorization", authorization),
                    ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ],
            )
            .await;
        assert_eq!(code, StatusCode::UNAUTHORIZED, "{authorization}");
    }
    assert_eq!(written(), before);
    assert_eq!(
        agent_request(&f, &issued, "GET", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::OK
    );
}

#[tokio::test]
async fn agent_listing_detail_and_download_preserve_privacy_and_digest() {
    let f = Fixture::new();
    let issued = issue_agent(&f, false).await;
    let zip = archive(None, true);
    let (receipt, code) = f.send(zip.clone()).await;
    assert_eq!(code, StatusCode::OK);
    let id = receipt["id"].as_str().unwrap();
    f.state.db.lock().unwrap().execute("UPDATE reports SET message=?1,contact='private contact',notes='Investigation notes' WHERE id=?2",rusqlite::params!["x".repeat(300),id]).unwrap();
    let (code, list, _, _) = agent_request(
        &f,
        &issued,
        "GET",
        "/api/agent/reports?offset=0&limit=1",
        Value::Null,
    )
    .await;
    assert_eq!(code, StatusCode::OK);
    assert_eq!(list["limit"], 1);
    assert_eq!(list["total"], 1);
    assert_eq!(
        list["reports"][0]["message_preview"]
            .as_str()
            .unwrap()
            .chars()
            .count(),
        240
    );
    assert!(list["reports"][0].get("contact").is_none());
    assert!(list["reports"][0].get("notes").is_none());
    assert_eq!(list["untrusted_content"], true);
    let (code, detail, _, _) = agent_request(
        &f,
        &issued,
        "GET",
        &format!("/api/agent/reports/{id}"),
        Value::Null,
    )
    .await;
    assert_eq!(code, StatusCode::OK);
    assert_eq!(detail["report"]["message"].as_str().unwrap().len(), 300);
    assert_eq!(detail["report"]["notes"], "Investigation notes");
    assert!(detail["report"].get("contact").is_none());
    let (code, _, headers, downloaded) = agent_request(
        &f,
        &issued,
        "GET",
        &format!("/api/agent/reports/{id}/diagnostics"),
        Value::Null,
    )
    .await;
    assert_eq!(code, StatusCode::OK);
    assert_eq!(downloaded, zip);
    assert_eq!(
        headers["x-atlas-diagnostics-sha256"],
        atlas_reports::sha(&zip)
    );
    // When the report was made, so a downloaded copy can expire with it.
    let created: i64 = headers["x-atlas-report-created"]
        .to_str()
        .unwrap()
        .parse()
        .unwrap();
    assert_eq!(created, detail["report"]["created"].as_i64().unwrap());
    assert_eq!(headers["cache-control"], "no-store");
    assert!(f.state.file(id.parse().unwrap()).exists());
    for path in [
        "/api/agent/reports?limit=51",
        "/api/agent/reports?offset=-1",
        "/api/agent/reports?status=invalid",
    ] {
        assert_eq!(
            agent_request(&f, &issued, "GET", path, Value::Null).await.0,
            StatusCode::UNPROCESSABLE_ENTITY
        );
    }
    assert_eq!(
        agent_request(
            &f,
            &issued,
            "GET",
            &format!("/api/agent/reports/{}", Uuid::new_v4()),
            Value::Null
        )
        .await
        .0,
        StatusCode::NOT_FOUND
    );
    let last_used: Option<i64> = f
        .state
        .db
        .lock()
        .unwrap()
        .query_row(
            "SELECT last_used FROM agent_tokens WHERE id=?1",
            [issued["id"].as_str().unwrap()],
            |r| r.get(0),
        )
        .unwrap();
    assert!(last_used.is_some());
}

#[tokio::test]
async fn agent_revocation_and_expiry_apply_to_every_request() {
    let f = Fixture::new();
    let issued = issue_agent(&f, false).await;
    assert_eq!(
        agent_request(&f, &issued, "GET", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::OK
    );
    assert_eq!(
        f.json(
            "DELETE",
            &format!("/api/admin/agent-tokens/{}", issued["id"].as_str().unwrap()),
            Value::Null,
            true
        )
        .await
        .0,
        StatusCode::NO_CONTENT
    );
    assert_eq!(
        agent_request(&f, &issued, "GET", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::UNAUTHORIZED
    );
    let expiring = issue_agent(&f, false).await;
    f.state
        .db
        .lock()
        .unwrap()
        .execute(
            "UPDATE agent_tokens SET expires=0 WHERE id=?1",
            [expiring["id"].as_str().unwrap()],
        )
        .unwrap();
    assert_eq!(
        agent_request(&f, &expiring, "GET", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::UNAUTHORIZED
    );
}

#[tokio::test]
async fn agent_delete_requires_permission_and_exact_confirmation_and_is_audited() {
    let f = Fixture::new();
    let reader = issue_agent(&f, false).await;
    let deleter = issue_agent(&f, true).await;
    assert_eq!(
        deleter["scope"],
        "reports:read diagnostics:read reports:delete"
    );
    let (receipt, _) = f.send(archive(None, true)).await;
    let id = receipt["id"].as_str().unwrap();
    let path = format!("/api/agent/reports/{id}");
    assert_eq!(
        agent_request(&f, &reader, "DELETE", &path, json!({"confirm_id":id}))
            .await
            .0,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        agent_request(
            &f,
            &deleter,
            "DELETE",
            &path,
            json!({"confirm_id":Uuid::new_v4()})
        )
        .await
        .0,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert!(f.state.file(id.parse().unwrap()).exists());
    assert_eq!(
        agent_request(&f, &deleter, "DELETE", &path, json!({"confirm_id":id}))
            .await
            .0,
        StatusCode::NO_CONTENT
    );
    assert!(!f.state.file(id.parse().unwrap()).exists());
    assert_eq!(
        agent_request(&f, &reader, "GET", &path, Value::Null)
            .await
            .0,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        agent_request(&f, &deleter, "DELETE", &path, json!({"confirm_id":id}))
            .await
            .0,
        StatusCode::NOT_FOUND
    );
    let actor: String = f
        .state
        .db
        .lock()
        .unwrap()
        .query_row(
            "SELECT actor FROM audit WHERE action='agent-delete' AND report_id=?1",
            [id],
            |r| r.get(0),
        )
        .unwrap();
    assert!(actor.starts_with(&format!("agent:{}:", deleter["id"].as_str().unwrap())));
    assert!(!actor.contains(deleter["token"].as_str().unwrap()));
}

#[tokio::test]
async fn agent_access_cannot_evict_protected_audit_records() {
    let f = Fixture::new();
    let reader = issue_agent(&f, false).await;
    let hour = atlas_reports::now() / 3600;
    {
        let db = f.state.db.lock().unwrap();
        db.execute(
            "INSERT INTO audit VALUES(?1,'jack','delete',''),(?1,'jack','download','')",
            [atlas_reports::now()],
        )
        .unwrap();
        db.execute_batch(&format!("WITH RECURSIVE numbers(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM numbers WHERE n < 10001)
            INSERT INTO audit SELECT {},'agent:seed','agent-read','' FROM numbers", atlas_reports::now())).unwrap();
    }
    for _ in 0..2 {
        assert_eq!(
            agent_request(&f, &reader, "GET", "/api/agent/reports", Value::Null)
                .await
                .0,
            StatusCode::OK
        );
    }
    // The hourly cleanup must keep both kinds of record too.
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert_eq!(
        count(
            &f,
            "SELECT count(*) FROM audit WHERE action IN ('delete','download','agent-token-create')"
        ),
        3
    );
    assert_eq!(
        count(
            &f,
            "SELECT count(*) FROM audit WHERE action IN ('agent-list','agent-read','agent-download')"
        ),
        10_000
    );
    // Listing is recorded once per credential per hour.
    if atlas_reports::now() / 3600 == hour {
        assert_eq!(
            count(&f, "SELECT count(*) FROM audit WHERE action='agent-list'"),
            1
        );
    }
}

#[tokio::test]
async fn agent_history_pruning_does_not_leave_credentials_unusable() {
    let f = Fixture::new();
    let issued = issue_agent(&f, false).await;
    // Newer revoked history pushes the working key out of the newest 128.
    f.state
        .db
        .lock()
        .unwrap()
        .execute_batch(&format!(
            "WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM n WHERE i < 260)
            INSERT INTO agent_tokens(id,name,signature,created,expires,revoked)
            SELECT 'old-'||i,'Old','unused',{now}+i,{now}+86400,1 FROM n",
            now = atlas_reports::now()
        ))
        .unwrap();
    issue_agent(&f, false).await;
    assert_eq!(
        agent_request(&f, &issued, "GET", "/api/agent/reports", Value::Null)
            .await
            .0,
        StatusCode::OK
    );
    assert!(count(&f, "SELECT count(*) FROM agent_tokens") <= 130);
}
fn archive(extra: Option<(&str, &str)>, valid: bool) -> Vec<u8> {
    let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
    let options = zip::write::SimpleFileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated);
    zip.start_file("manifest.json", options).unwrap();
    zip.write_all(if valid {
        br#"{"schema":2,"redaction":"public-v1","windows":{"build":"26300.9457"}}"#
    } else {
        b"{}"
    })
    .unwrap();
    if let Some((name, contents)) = extra {
        zip.start_file(name, options).unwrap();
        zip.write_all(contents.as_bytes()).unwrap();
    }
    zip.finish().unwrap().into_inner()
}
#[tokio::test]
async fn report_review_download_delete() {
    let f = Fixture::new();
    let zip = archive(Some(("user/app.log", "<script>malicious</script>")), true);
    let (receipt, code) = f.send(zip.clone()).await;
    assert_eq!(code, StatusCode::OK);
    let (_, list) = f.json("GET", "/api/admin/reports", Value::Null, true).await;
    assert_eq!(list["total"], 1);
    assert_eq!(list["reports"][0]["summary"]["windows"], "26300.9457");
    let path = format!("/api/admin/reports/{}", receipt["id"].as_str().unwrap());
    assert_eq!(
        f.json(
            "PATCH",
            &path,
            json!({"status":"investigating","notes":"Reproduced"}),
            true
        )
        .await
        .0,
        StatusCode::OK
    );
    let (code, _, headers, bytes) = f
        .request("GET", &(path.clone() + "/diagnostics"), vec![], true, &[])
        .await;
    assert_eq!(code, StatusCode::OK);
    assert_eq!(headers["content-type"], "application/zip");
    assert!(
        headers["content-disposition"]
            .to_str()
            .unwrap()
            .contains("attachment")
    );
    assert_eq!(
        headers["x-atlas-diagnostics-sha256"],
        atlas_reports::sha(&zip)
    );
    assert_eq!(bytes, zip);
    assert_eq!(
        f.json("DELETE", &path, Value::Null, true).await.0,
        StatusCode::NO_CONTENT
    );
    assert_eq!(
        f.json("GET", &(path.clone() + "/diagnostics"), Value::Null, true)
            .await
            .0,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        f.json("DELETE", &path, Value::Null, true).await.0,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        count(&f, "SELECT count(*) FROM audit WHERE action='delete'"),
        1
    );
}

#[tokio::test]
async fn deleted_and_expired_report_text_leaves_no_residue() {
    let f = Fixture::new();
    let deleter = issue_agent(&f, true).await;
    let marker = format!("PRIVATE-{}", Uuid::new_v4());
    let stored = |suffix: &str| {
        let marker = format!("{marker}-{suffix}");
        ["reports.sqlite3", "reports.sqlite3-wal"]
            .iter()
            .any(|name| {
                std::fs::read(f.state.config.data.join(name))
                    .is_ok_and(|bytes| bytes.windows(marker.len()).any(|w| w == marker.as_bytes()))
            })
    };
    let mut ids = Vec::new();
    for suffix in ["admin", "agent", "expired"] {
        let mut data = metadata();
        data["has_diagnostics"] = false.into();
        data["message"] = format!("Private message {marker}-{suffix}").into();
        data["contact"] = format!("{marker}-{suffix}").into();
        let (code, receipt) = f.json("POST", "/api/v1/reports", data, false).await;
        assert_eq!(code, StatusCode::CREATED);
        ids.push(receipt["id"].as_str().unwrap().to_owned());
        assert!(stored(suffix));
    }
    assert_eq!(
        f.json(
            "DELETE",
            &format!("/api/admin/reports/{}", ids[0]),
            Value::Null,
            true
        )
        .await
        .0,
        StatusCode::NO_CONTENT
    );
    assert!(!stored("admin"));
    assert_eq!(
        agent_request(
            &f,
            &deleter,
            "DELETE",
            &format!("/api/agent/reports/{}", ids[1]),
            json!({"confirm_id":ids[1]})
        )
        .await
        .0,
        StatusCode::NO_CONTENT
    );
    assert!(!stored("agent"));
    f.state
        .db
        .lock()
        .unwrap()
        .execute(
            "UPDATE reports SET created=?1 WHERE id=?2",
            rusqlite::params![atlas_reports::now() - 91 * 86400, ids[2]],
        )
        .unwrap();
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert!(!stored("expired"));
}
#[tokio::test]
async fn no_public_access_or_header_spoof() {
    let f = Fixture::new();
    for path in ["/api/admin/session", "/api/admin/reports"] {
        assert_eq!(
            f.json("GET", path, Value::Null, false).await.0,
            StatusCode::UNAUTHORIZED
        );
        assert_eq!(
            f.request("GET", path, vec![], false, &[("remote-user", "jack")])
                .await
                .0,
            StatusCode::UNAUTHORIZED
        );
        assert_eq!(
            f.request(
                "GET",
                path,
                vec![],
                false,
                &[
                    ("remote-user", "other"),
                    ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx")
                ]
            )
            .await
            .0,
            StatusCode::UNAUTHORIZED
        );
    }
}
#[tokio::test]
async fn unchanged_retry_returns_same_report_and_edit_conflicts() {
    let f = Fixture::new();
    let mut data = metadata();
    data["has_diagnostics"] = false.into();
    data["category"] = "suggestion".into();
    let (_, first) = f.json("POST", "/api/v1/reports", data.clone(), false).await;
    let (_, second) = f.json("POST", "/api/v1/reports", data.clone(), false).await;
    assert_eq!(first["id"], second["id"]);
    assert_eq!(first["received"], true);
    assert!(first["upload_token"].is_null());
    data["message"] = "Changed the message after submission.".into();
    assert_eq!(
        f.json("POST", "/api/v1/reports", data, false).await.0,
        StatusCode::CONFLICT
    );
}
#[tokio::test]
async fn foreign_origins_and_stale_csrf_tokens_are_refused() {
    let f = Fixture::new();
    assert_eq!(
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[("origin", "https://evil.test")]
        )
        .await
        .0,
        StatusCode::FORBIDDEN
    );
    let mut data = metadata();
    data["has_diagnostics"] = false.into();
    let (_, receipt) = f.json("POST", "/api/v1/reports", data, false).await;
    let path = format!("/api/admin/reports/{}", receipt["id"].as_str().unwrap());
    let day = atlas_reports::now() / 86400;
    let token = |day: i64| f.state.signature(&format!("csrf:jack:{day}"));
    let review = async |origin: &str, csrf: String| {
        f.request(
            "PATCH",
            &path,
            serde_json::to_vec(&json!({"status":"investigating"})).unwrap(),
            false,
            &[
                ("remote-user", "jack"),
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ("origin", origin),
                ("x-atlas-csrf", &csrf),
            ],
        )
        .await
        .0
    };
    assert_eq!(
        review("https://reports.test", "0".repeat(64)).await,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        review("https://reports.test", token(day - 2)).await,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        review("https://evil.test", token(day)).await,
        StatusCode::FORBIDDEN
    );
    // A page left open past midnight can still save.
    assert_eq!(
        review("https://reports.test", token(day - 1)).await,
        StatusCode::OK
    );
}
#[tokio::test]
async fn stale_privacy_notice_has_its_own_reason() {
    let f = Fixture::new();
    let mut data = metadata();
    data["privacy_version"] = "2026-01-01".into();
    data["consent"] = false.into();
    let (code, stale) = f.json("POST", "/api/v1/reports", data, false).await;
    assert_eq!(code, StatusCode::UNPROCESSABLE_ENTITY);
    let mut data = metadata();
    data["consent"] = false.into();
    let (code, current) = f.json("POST", "/api/v1/reports", data, false).await;
    assert_eq!(code, StatusCode::UNPROCESSABLE_ENTITY);
    assert_ne!(stale["detail"], current["detail"]);
    assert!(stale["detail"].as_str().unwrap().contains("privacy notice"));
}
#[tokio::test]
async fn rejects_unsafe_archives() {
    let mut crc = archive(Some(("user/app.log", "hello")), true);
    // Change the central-directory CRC without touching compressed content.
    let central = crc.windows(4).position(|b| b == b"PK\x01\x02").unwrap();
    crc[central + 16] ^= 1;
    let mut symlink = zip::ZipWriter::new(Cursor::new(Vec::new()));
    symlink
        .start_file("manifest.json", zip::write::SimpleFileOptions::default())
        .unwrap();
    symlink
        .write_all(br#"{"schema":2,"redaction":"public-v1"}"#)
        .unwrap();
    symlink
        .add_symlink(
            "link",
            "/etc/passwd",
            zip::write::SimpleFileOptions::default(),
        )
        .unwrap();
    let mut cases = [
        "../outside.txt",
        "/absolute.txt",
        "C:/test.log",
        r"folder\bad.log",
    ]
    .map(|name| (name, archive(Some((name, "bad")), true)))
    .to_vec();
    cases.extend([
        ("not a zip", b"not a zip".to_vec()),
        ("unredacted manifest", archive(None, false)),
        ("central CRC", crc),
        ("symbolic link", symlink.finish().unwrap().into_inner()),
        (
            "duplicate manifest",
            archive(Some(("MANIFEST.JSON", "duplicate")), true),
        ),
    ]);
    // One client may send 12 reports an hour, so keep the cases below that.
    let f = Fixture::new();
    for (label, bytes) in cases {
        assert_eq!(
            f.send(bytes).await.1,
            StatusCode::UNPROCESSABLE_ENTITY,
            "{label}"
        );
    }
    assert_eq!(
        std::fs::read_dir(f.state.config.data.join("uploads"))
            .unwrap()
            .count(),
        0
    );
}
#[tokio::test]
async fn expanded_member_and_json_body_limits() {
    let f = Fixture::new();
    assert_eq!(
        f.send(archive(
            Some(("huge.log", &"0".repeat(32 * 1024 * 1024 + 1))),
            true
        ))
        .await
        .1,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert_eq!(
        f.request("POST", "/api/v1/reports", vec![b'x'; 32769], false, &[])
            .await
            .0,
        StatusCode::PAYLOAD_TOO_LARGE
    );
}
#[tokio::test]
async fn one_cleanup_pass_removes_every_expired_report() {
    let f = Fixture::new();
    let mut expired = Vec::new();
    for _ in 0..3 {
        let (receipt, code) = f.send(archive(None, true)).await;
        assert_eq!(code, StatusCode::OK);
        expired.push(receipt["id"].as_str().unwrap().parse::<Uuid>().unwrap());
    }
    let (_, incomplete) = f.json("POST", "/api/v1/reports", metadata(), false).await;
    expired.push(incomplete["id"].as_str().unwrap().parse().unwrap());
    {
        let db = f.state.db.lock().unwrap();
        for (index, id) in expired.iter().enumerate() {
            let age = if index < 3 { 91 * 86400 } else { 86401 };
            db.execute(
                "UPDATE reports SET created=?1 WHERE id=?2",
                rusqlite::params![atlas_reports::now() - age, id.to_string()],
            )
            .unwrap();
        }
        db.execute(
            "INSERT INTO rates VALUES(?1,1)",
            [format!("{}:stale:report", atlas_reports::now() / 3600 - 25)],
        )
        .unwrap();
    }
    let (fresh, code) = f.send(archive(None, true)).await;
    assert_eq!(code, StatusCode::OK);
    let fresh: Uuid = fresh["id"].as_str().unwrap().parse().unwrap();
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    for id in expired {
        assert!(!f.state.file(id).exists());
    }
    assert!(f.state.file(fresh).exists());
    assert_eq!(count(&f, "SELECT count(*) FROM reports"), 1);
    assert_eq!(
        count(
            &f,
            "SELECT count(*) FROM rates WHERE bucket LIKE '%:stale:%'"
        ),
        0
    );
}

#[tokio::test]
async fn cleanup_and_startup_continue_past_undeletable_files() {
    let f = Fixture::new();
    let mut ids = Vec::new();
    for _ in 0..2 {
        let mut data = metadata();
        data["has_diagnostics"] = false.into();
        let (_, receipt) = f.json("POST", "/api/v1/reports", data, false).await;
        ids.push(receipt["id"].as_str().unwrap().parse::<Uuid>().unwrap());
    }
    std::fs::create_dir(f.state.file(ids[0])).unwrap();
    std::fs::write(f.state.file(ids[1]), b"expired diagnostics").unwrap();
    f.state
        .db
        .lock()
        .unwrap()
        .execute(
            "UPDATE reports SET created=?1",
            [atlas_reports::now() - 91 * 86400],
        )
        .unwrap();
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert_eq!(count(&f, "SELECT count(*) FROM reports"), 0);
    assert!(!f.state.file(ids[1]).exists());
    assert!(f.state.file(ids[0]).is_dir());
    assert!(create(config(&f.state.config.data)).is_ok());
}

#[test]
fn startup_failures_name_the_setting_or_point_to_the_logged_cause() {
    let dir = tempfile::tempdir().unwrap();
    std::fs::write(dir.path().join("reports.sqlite3"), [7; 4096]).unwrap();
    let start = |origin: &str| {
        let mut child = std::process::Command::new(env!("CARGO_BIN_EXE_atlas-reports"))
            .env("ATLAS_REPORTS_DATA", dir.path())
            .env("ATLAS_REPORTS_WEB", dir.path().join("web"))
            .env("ATLAS_REPORTS_ORIGIN", origin)
            .env(
                "ATLAS_REPORTS_GATEWAY_SECRET",
                "test-gateway-secret-xxxxxxxxxxxxxxxx",
            )
            .env("ATLAS_REPORTS_ADMINS", "jack")
            .env("ATLAS_REPORTS_PROXY_IPS", "127.0.0.1")
            .env("ATLAS_REPORTS_LISTEN", "127.0.0.1:0")
            .env_remove("ATLAS_REPORTS_QUOTA_BYTES")
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .unwrap();
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(30);
        while child.try_wait().unwrap().is_none() {
            if std::time::Instant::now() > deadline {
                child.kill().unwrap();
                panic!("The service started despite the invalid setup");
            }
            std::thread::sleep(std::time::Duration::from_millis(50));
        }
        let output = child.wait_with_output().unwrap();
        assert!(!output.status.success());
        String::from_utf8_lossy(&output.stderr).into_owned()
    };
    let stderr = start("http://reports.test");
    assert!(
        stderr.contains("Cannot initialize report service: ATLAS_REPORTS_ORIGIN must be"),
        "{stderr}"
    );
    // A corrupt database is an operator problem, not advice for a sender.
    let stderr = start("https://reports.test");
    assert!(
        stderr.contains("Report database operation failed"),
        "{stderr}"
    );
    assert!(
        stderr
            .contains("Cannot initialize report service; see the storage or database error above."),
        "{stderr}"
    );
    assert!(
        !stderr.contains("Please retry") && !stderr.contains("Save your diagnostics"),
        "{stderr}"
    );
    assert!(!stderr.contains("test-gateway-secret"), "{stderr}");
}

#[test]
fn failing_startup_cleanup_does_not_stop_create() {
    let dir = tempfile::tempdir().unwrap();
    // Without the `ready` column every cleanup pass fails.
    rusqlite::Connection::open(dir.path().join("reports.sqlite3"))
        .unwrap()
        .execute_batch("CREATE TABLE reports(id TEXT PRIMARY KEY,created INTEGER NOT NULL)")
        .unwrap();
    let (_, state) = create(config(dir.path())).unwrap_or_else(|_| panic!("startup"));
    assert!(state.prune().is_err());
}

#[test]
fn upgrade_replaces_unscoped_audit_bound_and_scrubs_deleted_text() {
    let dir = tempfile::tempdir().unwrap();
    let file = dir.path().join("reports.sqlite3");
    let marker = format!("deleted-before-upgrade-{}", Uuid::new_v4());
    {
        // The pre-upgrade schema: one audit limit for every action, and text
        // deleted before secure_delete was enabled.
        let db = rusqlite::Connection::open(&file).unwrap();
        db.execute_batch(
            "PRAGMA journal_mode=WAL;
            CREATE TABLE audit(at INTEGER NOT NULL,actor TEXT NOT NULL,action TEXT NOT NULL,report_id TEXT NOT NULL);
            CREATE TRIGGER audit_bound AFTER INSERT ON audit BEGIN
                DELETE FROM audit WHERE rowid <= NEW.rowid - 10000;
            END;
            CREATE TABLE scratch(t TEXT);",
        )
        .unwrap();
        db.execute("INSERT INTO scratch VALUES(?1)", [&marker])
            .unwrap();
        db.execute_batch("DELETE FROM scratch; PRAGMA wal_checkpoint(TRUNCATE);")
            .unwrap();
    }
    let contains = |path: &Path| {
        std::fs::read(path).is_ok_and(|bytes| {
            bytes
                .windows(marker.len())
                .any(|window| window == marker.as_bytes())
        })
    };
    assert!(contains(&file));
    let (_, state) = create(config(dir.path())).unwrap_or_else(|_| panic!("upgrade"));
    assert!(!contains(&file));
    assert!(!contains(&dir.path().join("reports.sqlite3-wal")));
    let db = state.db.lock().unwrap();
    let version: i64 = db
        .query_row("PRAGMA user_version", [], |r| r.get(0))
        .unwrap();
    assert_eq!(version, 1);
    db.execute_batch(
        "INSERT INTO audit VALUES(1,'jack','delete','');
        WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM n WHERE i < 10001)
        INSERT INTO audit SELECT 1,'Test agent','agent-read','' FROM n;",
    )
    .unwrap();
    let deletions: i64 = db
        .query_row(
            "SELECT count(*) FROM audit WHERE action='delete'",
            [],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(deletions, 1);
}
#[test]
fn hostile_signature_does_not_panic() {
    let f = Fixture::new();
    assert!(!f.state.verify("value", &format!("a{}b", "é".repeat(31))));
}

#[tokio::test]
async fn trusted_gateway_still_requires_allowed_peer() {
    let f = Fixture::new();
    let mut request = Request::builder()
        .uri("/api/admin/session")
        .header("host", "reports.test")
        .header("remote-user", "jack")
        .header("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx")
        .body(Body::empty())
        .unwrap();
    request.extensions_mut().insert(ConnectInfo(
        "192.0.2.1:12345".parse::<SocketAddr>().unwrap(),
    ));
    assert_eq!(
        f.app.oneshot(request).await.unwrap().status(),
        StatusCode::UNAUTHORIZED
    );
}

#[tokio::test]
async fn invalid_upload_token_and_declared_size_do_not_create_files() {
    let f = Fixture::new();
    let (_, receipt) = f.json("POST", "/api/v1/reports", metadata(), false).await;
    let path = format!(
        "/api/v1/reports/{}/diagnostics",
        receipt["id"].as_str().unwrap()
    );
    assert_eq!(
        f.request(
            "PUT",
            &path,
            archive(None, true),
            false,
            &[
                ("authorization", "Bearer bad"),
                ("content-type", "application/zip")
            ]
        )
        .await
        .0,
        StatusCode::NOT_FOUND
    );
    let token = format!("Bearer {}", receipt["upload_token"].as_str().unwrap());
    assert_eq!(
        f.request(
            "PUT",
            &path,
            vec![],
            false,
            &[
                ("authorization", &token),
                ("content-type", "application/zip"),
                ("content-length", "67108865")
            ]
        )
        .await
        .0,
        StatusCode::PAYLOAD_TOO_LARGE
    );
    assert_eq!(
        std::fs::read_dir(f.state.config.data.join("uploads"))
            .unwrap()
            .count(),
        0
    );
}

#[tokio::test]
async fn orphaned_and_interrupted_files_count_toward_quota_and_are_recovered() {
    // The smallest quota allowed, where any stored byte blocks another upload.
    let f = Fixture::with(|config| Config {
        quota_bytes: 2 * MAX_ZIP,
        ..config
    });
    let orphan = f.state.file(Uuid::new_v4());
    std::fs::write(&orphan, b"orphaned diagnostics").unwrap();
    assert_eq!(
        f.send(archive(None, true)).await.1,
        StatusCode::SERVICE_UNAVAILABLE
    );
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert!(!orphan.exists());
    let part = f.state.config.data.join("uploads").join("interrupted.part");
    std::fs::write(&part, b"x").unwrap();
    assert_eq!(
        f.send(archive(None, true)).await.1,
        StatusCode::SERVICE_UNAVAILABLE
    );
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert!(part.exists()); // A current upload may still own this file.
    std::fs::remove_file(part).unwrap();
    assert_eq!(f.send(archive(None, true)).await.1, StatusCode::OK);
}

#[tokio::test]
async fn metadata_only_reports_cannot_grow_without_limit() {
    let f = Fixture::new();
    f.state.db.lock().unwrap().execute_batch(&format!("WITH RECURSIVE numbers(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM numbers WHERE n < {})
        INSERT INTO reports(id,key_hash,fingerprint,created,category,message,contact,version,expects_zip,ready,privacy_version)
        SELECT 'seed-'||n,'key-'||n,'fingerprint',{},'suggestion','A message','','',0,1,'2026-09-30' FROM numbers",atlas_reports::MAX_REPORTS,atlas_reports::now()-86401)).unwrap();
    assert_eq!(
        f.json("POST", "/api/v1/reports", metadata(), false).await.0,
        StatusCode::SERVICE_UNAVAILABLE
    );
}

fn crc32(bytes: &[u8]) -> u32 {
    !bytes.iter().fold(!0, |crc, &byte| {
        (0..8).fold(crc ^ u32::from(byte), |crc, _| {
            (crc >> 1) ^ (0xEDB8_8320 & (crc & 1).wrapping_neg())
        })
    })
}
enum Hidden {
    /// Before the archive, with the directory unchanged.
    Prepended,
    /// Before the archive, with every directory offset moved past it.
    Shifted,
    /// Between the last member and the central directory.
    BeforeDirectory,
}
/// Adds a stored `../../evil.cmd` local header that the central directory does
/// not list, so only tools that scan local headers see it.
fn hide_entry(zip: &[u8], place: Hidden) -> Vec<u8> {
    let (name, data) = (b"../../evil.cmd", b"echo pwned");
    let mut entry = b"PK\x03\x04\x14\0\0\0\0\0\0\0\0\0".to_vec();
    entry.extend(crc32(data).to_le_bytes());
    entry.extend((data.len() as u32).to_le_bytes());
    entry.extend((data.len() as u32).to_le_bytes());
    entry.extend((name.len() as u16).to_le_bytes());
    entry.extend([0, 0]);
    entry.extend(name);
    entry.extend(data);
    let shift = entry.len() as u32;
    let mut bytes = zip.to_vec();
    let end = bytes.len() - 22;
    assert!(bytes[end..].starts_with(b"PK\x05\x06"));
    let read = |bytes: &[u8], at: usize| u32::from_le_bytes(bytes[at..at + 4].try_into().unwrap());
    let directory = read(&bytes, end + 16);
    if !matches!(place, Hidden::Prepended) {
        bytes[end + 16..end + 20].copy_from_slice(&(directory + shift).to_le_bytes());
    }
    if matches!(place, Hidden::Shifted) {
        let mut header = directory as usize;
        while bytes[header..].starts_with(b"PK\x01\x02") {
            let offset = read(&bytes, header + 42) + shift;
            bytes[header + 42..header + 46].copy_from_slice(&offset.to_le_bytes());
            header += 46
                + [28, 30, 32]
                    .map(|at| {
                        usize::from(u16::from_le_bytes([
                            bytes[header + at],
                            bytes[header + at + 1],
                        ]))
                    })
                    .iter()
                    .sum::<usize>();
        }
    }
    let at = match place {
        Hidden::BeforeDirectory => directory as usize,
        _ => 0,
    };
    bytes.splice(at..at, entry);
    bytes
}
#[tokio::test]
async fn archive_names_must_match_local_headers_without_unicode_overrides() {
    let f = Fixture::new();
    // Tools that scan local headers, such as 7-Zip, extract an entry hidden
    // outside the listed members.
    for place in [Hidden::Prepended, Hidden::Shifted, Hidden::BeforeDirectory] {
        let bytes = hide_entry(&archive(Some(("logs/notes.txt", "x")), true), place);
        assert_eq!(
            zip::ZipArchive::new(Cursor::new(bytes.clone()))
                .unwrap()
                .len(),
            2
        );
        assert_eq!(f.send(bytes).await.1, StatusCode::UNPROCESSABLE_ENTITY);
    }
    // Other tools read a traversal name from the local header.
    let mut bytes = archive(Some(("logs/notes.txt", "x")), true);
    let local = bytes
        .windows(14)
        .position(|w| w == b"logs/notes.txt")
        .unwrap();
    bytes[local..local + 14].copy_from_slice(b"../../evil.cmd");
    assert_eq!(f.send(bytes).await.1, StatusCode::UNPROCESSABLE_ENTITY);
    // Both headers agree, but an Info-ZIP Unicode Path field in the local
    // header gives tools that honour it a traversal name.
    let mut field = vec![1];
    field.extend(crc32(b"logs/notes.txt").to_le_bytes());
    field.extend(b"../../evil.cmd");
    let mut options = zip::write::FileOptions::<zip::write::ExtendedFileOptions>::default();
    options.add_extra_data(0x4242, &field, false).unwrap();
    let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
    zip.start_file("manifest.json", zip::write::SimpleFileOptions::default())
        .unwrap();
    zip.write_all(br#"{"schema":2,"redaction":"public-v1"}"#)
        .unwrap();
    zip.start_file("logs/notes.txt", options).unwrap();
    zip.write_all(b"x").unwrap();
    let mut bytes = zip.finish().unwrap().into_inner();
    // The writer refuses 0x7075 itself, so relabel the local copy only.
    let central = bytes.windows(4).position(|b| b == b"PK\x01\x02").unwrap();
    let id = bytes[..central]
        .windows(4)
        .position(|b| b == [0x42, 0x42, field.len() as u8, 0])
        .unwrap();
    bytes[id..id + 2].copy_from_slice(&0x7075u16.to_le_bytes());
    assert_eq!(f.send(bytes).await.1, StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn upload_retries_preserve_one_attachment_and_delete_prevents_reuse() {
    let f = Fixture::new();
    let (receipt, code) = f.send(archive(None, true)).await;
    assert_eq!(code, StatusCode::OK);
    let token = format!("Bearer {}", receipt["upload_token"].as_str().unwrap());
    let path = format!(
        "/api/v1/reports/{}/diagnostics",
        receipt["id"].as_str().unwrap()
    );
    assert_eq!(
        f.request(
            "PUT",
            &path,
            archive(None, true),
            false,
            &[("authorization", &token)]
        )
        .await
        .0,
        StatusCode::OK
    );
    assert_eq!(
        std::fs::read_dir(f.state.config.data.join("uploads"))
            .unwrap()
            .count(),
        1
    );
    let admin = format!("/api/admin/reports/{}", receipt["id"].as_str().unwrap());
    assert_eq!(
        f.json("DELETE", &admin, Value::Null, true).await.0,
        StatusCode::NO_CONTENT
    );
    assert_eq!(
        f.request(
            "PUT",
            &path,
            archive(None, true),
            false,
            &[("authorization", &token)]
        )
        .await
        .0,
        StatusCode::NOT_FOUND
    );
}

#[test]
fn configuration_errors_name_the_setting_and_loopback_may_use_http() {
    let dir = tempfile::tempdir().unwrap();
    let base = || config(dir.path());
    let origin = |origin: &str| Config {
        origin: origin.into(),
        ..base()
    };
    for (setting, config) in [
        ("ATLAS_REPORTS_ORIGIN", origin("http://reports.test")),
        ("ATLAS_REPORTS_ORIGIN", origin("https://reports.test/")),
        ("ATLAS_REPORTS_ORIGIN", origin("https://reports.test/path")),
        ("ATLAS_REPORTS_ORIGIN", origin("https://user@reports.test")),
        ("ATLAS_REPORTS_ORIGIN", origin("https://reports.test?x=y")),
        (
            "ATLAS_REPORTS_GATEWAY_SECRET",
            Config {
                gateway_secret: "x".repeat(20),
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_ADMINS",
            Config {
                admins: vec!["".into()],
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_ADMINS",
            Config {
                admins: vec!["jack".into(), " alice".into()],
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_ADMINS",
            Config {
                admins: vec!["alice ".into()],
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_PROXY_IPS",
            Config {
                proxy_ips: vec![],
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_PROXY_IPS",
            Config {
                proxy_ips: vec!["0.0.0.0".parse().unwrap()],
                ..base()
            },
        ),
        (
            "ATLAS_REPORTS_QUOTA_BYTES",
            Config {
                quota_bytes: 64 * 1024 * 1024,
                ..base()
            },
        ),
    ] {
        let Err(StartupError::Config(reason)) = create(config) else {
            panic!("{setting} accepted");
        };
        assert!(reason.starts_with(setting), "{reason}");
    }
    let config = Config {
        admins: vec!["jack".into(), "alice".into()],
        ..base()
    };
    assert!(create(config).is_ok());
    for local in [
        "http://localhost:8087",
        "http://127.0.0.1:8087",
        "http://[::1]:8087",
    ] {
        assert!(create(origin(local)).is_ok(), "{local}");
    }
}

#[tokio::test]
async fn rate_identity_trusts_forwarded_client_only_via_gateway() {
    let f = Fixture::new();
    let proxy = [
        ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
        ("cf-connecting-ip", "192.0.2.10"),
    ];
    for _ in 0..12 {
        assert_eq!(
            f.request(
                "POST",
                "/api/v1/reports",
                serde_json::to_vec(&metadata()).unwrap(),
                false,
                &proxy
            )
            .await
            .0,
            StatusCode::CREATED
        );
    }
    assert_eq!(
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &proxy
        )
        .await
        .0,
        StatusCode::TOO_MANY_REQUESTS
    );
    assert_eq!(
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ("cf-connecting-ip", "192.0.2.11")
            ]
        )
        .await
        .0,
        StatusCode::CREATED
    );
    // A client cannot select its rate identity by sending the header alone.
    for _ in 0..12 {
        assert_eq!(
            f.request(
                "POST",
                "/api/v1/reports",
                serde_json::to_vec(&metadata()).unwrap(),
                false,
                &[("cf-connecting-ip", "192.0.2.12")]
            )
            .await
            .0,
            StatusCode::CREATED
        );
    }
    assert_eq!(
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[("cf-connecting-ip", "192.0.2.13")]
        )
        .await
        .0,
        StatusCode::TOO_MANY_REQUESTS
    );
    assert_eq!(
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[("x-forwarded-for", "1.2.3.4")]
        )
        .await
        .0,
        StatusCode::TOO_MANY_REQUESTS
    );
    // The proxy appends the client it saw, so only the last entry is trusted.
    let forwarded = async |chain: &str| {
        f.request(
            "POST",
            "/api/v1/reports",
            serde_json::to_vec(&metadata()).unwrap(),
            false,
            &[
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ("x-forwarded-for", chain),
            ],
        )
        .await
        .0
    };
    for _ in 0..12 {
        assert_eq!(
            forwarded("198.51.100.9, 192.0.2.20").await,
            StatusCode::CREATED
        );
    }
    assert_eq!(
        forwarded("198.51.100.10, 192.0.2.20").await,
        StatusCode::TOO_MANY_REQUESTS
    );
}

#[tokio::test]
async fn one_client_cannot_spend_the_shared_hourly_budget() {
    // Seeded buckets belong to one hour, so start again if the hour changes.
    loop {
        let f = Fixture::new();
        let hour = atlas_reports::now() / 3600;
        let global = format!("{hour}:global:report");
        f.state
            .db
            .lock()
            .unwrap()
            .execute("INSERT INTO rates VALUES(?1,980)", [&global])
            .unwrap();
        let mut codes = Vec::new();
        for _ in 0..32 {
            codes.push(submit_from(&f, "192.0.2.40").await);
        }
        let spent = count(&f, &format!("SELECT n FROM rates WHERE bucket='{global}'"));
        let other = submit_from(&f, "192.0.2.41").await;
        if atlas_reports::now() / 3600 != hour {
            continue;
        }
        assert!(codes[..12].iter().all(|c| *c == StatusCode::CREATED));
        assert!(
            codes[12..]
                .iter()
                .all(|c| *c == StatusCode::TOO_MANY_REQUESTS)
        );
        assert_eq!(spent, 992);
        assert_eq!(other, StatusCode::CREATED);
        break;
    }
}

#[tokio::test]
async fn spent_shared_budget_stores_no_client_buckets() {
    loop {
        let f = Fixture::new();
        let hour = atlas_reports::now() / 3600;
        f.state
            .db
            .lock()
            .unwrap()
            .execute(
                "INSERT INTO rates VALUES(?1,1000)",
                [format!("{hour}:global:report")],
            )
            .unwrap();
        let before = count(&f, "SELECT count(*) FROM rates");
        let code = submit_from(&f, "192.0.2.42").await;
        if atlas_reports::now() / 3600 != hour {
            continue;
        }
        assert_eq!(code, StatusCode::TOO_MANY_REQUESTS);
        assert_eq!(count(&f, "SELECT count(*) FROM rates"), before);
        break;
    }
}

#[tokio::test]
async fn ipv6_rate_identity_is_the_64() {
    let f = Fixture::new();
    for host in 1..=12 {
        assert_eq!(
            submit_from(&f, &format!("2001:db8::{host:x}")).await,
            StatusCode::CREATED
        );
    }
    assert_eq!(
        submit_from(&f, "2001:db8::ff").await,
        StatusCode::TOO_MANY_REQUESTS
    );
    assert_eq!(
        submit_from(&f, "2001:db8:0:1::1").await,
        StatusCode::CREATED
    );
}

#[tokio::test]
async fn streamed_upload_limit_removes_partial_files() {
    let f = Fixture::new();
    let (_, receipt) = f.json("POST", "/api/v1/reports", metadata(), false).await;
    let path = format!(
        "/api/v1/reports/{}/diagnostics",
        receipt["id"].as_str().unwrap()
    );
    let token = format!("Bearer {}", receipt["upload_token"].as_str().unwrap());
    assert_eq!(
        f.request(
            "PUT",
            &path,
            vec![0; atlas_reports::MAX_ZIP as usize + 1],
            false,
            &[
                ("authorization", &token),
                ("content-type", "application/zip")
            ]
        )
        .await
        .0,
        StatusCode::PAYLOAD_TOO_LARGE
    );
    assert_eq!(
        std::fs::read_dir(f.state.config.data.join("uploads"))
            .unwrap()
            .count(),
        0
    );
}

#[tokio::test]
async fn interrupted_body_removes_partial_upload() {
    let f = Fixture::new();
    let (_, receipt) = f.json("POST", "/api/v1/reports", metadata(), false).await;
    let path = format!(
        "/api/v1/reports/{}/diagnostics",
        receipt["id"].as_str().unwrap()
    );
    let body = Body::from_stream(futures_util::stream::iter(vec![
        Ok(axum::body::Bytes::from_static(b"partial zip")),
        Err(std::io::Error::new(
            std::io::ErrorKind::ConnectionReset,
            "disconnected",
        )),
    ]));
    let mut request = Request::builder()
        .method("PUT")
        .uri(path)
        .header("host", "reports.test")
        .header("content-type", "application/zip")
        .header(
            "authorization",
            format!("Bearer {}", receipt["upload_token"].as_str().unwrap()),
        )
        .body(body)
        .unwrap();
    request.extensions_mut().insert(ConnectInfo(
        "127.0.0.1:12345".parse::<SocketAddr>().unwrap(),
    ));
    assert_eq!(
        f.app.clone().oneshot(request).await.unwrap().status(),
        StatusCode::BAD_REQUEST
    );
    assert_eq!(
        std::fs::read_dir(f.state.config.data.join("uploads"))
            .unwrap()
            .count(),
        0
    );
    assert_eq!(f.state.uploads.available_permits(), 2);
}

#[cfg(unix)]
#[test]
fn data_permissions_are_private() {
    use std::os::unix::fs::PermissionsExt;
    let f = Fixture::new();
    for (path, mode) in [
        (&f.state.config.data, 0o700),
        (&f.state.config.data.join("uploads"), 0o700),
        (&f.state.config.data.join("reports.sqlite3"), 0o600),
    ] {
        assert_eq!(
            std::fs::metadata(path).unwrap().permissions().mode() & 0o777,
            mode
        );
    }
}
