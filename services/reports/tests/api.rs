use atlas_reports::{AppState, Config, create};
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
};
use tower::ServiceExt;
use uuid::Uuid;

struct Fixture {
    app: Router,
    state: AppState,
    _dir: tempfile::TempDir,
}
impl Fixture {
    fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let (app, state) = create(Config {
            data: dir.path().into(),
            web: dir.path().join("web"),
            origin: "https://reports.test".into(),
            gateway_secret: "test-gateway-secret-xxxxxxxxxxxxxxxx".into(),
            admins: vec!["jack".into()],
            proxy_ips: vec!["127.0.0.1".parse().unwrap()],
            quota_bytes: 2 * 1024 * 1024 * 1024,
            retention_days: 90,
        })
        .unwrap_or_else(|_| panic!("fixture"));
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
    json!({"submission_key":Uuid::new_v4(),"category":"issue","message":"Night Light never changes the screen.","contact":"","version":"rc.8","has_diagnostics":true,"consent":true,"privacy_version":"2026-09-30"})
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
    let (receipt, code) = f
        .send(archive(
            Some(("user/app.log", "<script>malicious</script>")),
            true,
        ))
        .await;
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
    assert!(
        headers["content-disposition"]
            .to_str()
            .unwrap()
            .contains("attachment")
    );
    assert!(zip::ZipArchive::new(Cursor::new(bytes)).is_ok());
    assert_eq!(
        f.json("DELETE", &path, Value::Null, true).await.0,
        StatusCode::NO_CONTENT
    );
    assert_eq!(
        f.json("GET", &(path + "/diagnostics"), Value::Null, true)
            .await
            .0,
        StatusCode::NOT_FOUND
    );
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
async fn retries_and_suggestions() {
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
async fn csrf_origin_and_consent() {
    let f = Fixture::new();
    let mut data = metadata();
    data["consent"] = false.into();
    assert_eq!(
        f.json("POST", "/api/v1/reports", data, false).await.0,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    let path = format!("/api/admin/reports/{}", Uuid::new_v4());
    assert_eq!(
        f.request(
            "DELETE",
            &path,
            vec![],
            false,
            &[
                ("remote-user", "jack"),
                ("x-atlas-gateway", "test-gateway-secret-xxxxxxxxxxxxxxxx"),
                ("origin", "https://evil.test")
            ]
        )
        .await
        .0,
        StatusCode::FORBIDDEN
    );
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
}
#[tokio::test]
async fn rejects_malformed_archives_and_zip_traversal() {
    for name in [
        "../outside.txt",
        "/absolute.txt",
        "C:/test.log",
        "folder\\bad.log",
    ] {
        let f = Fixture::new();
        let (_, code) = f.send(archive(Some((name, "bad")), true)).await;
        assert_eq!(code, StatusCode::UNPROCESSABLE_ENTITY, "{name}");
    }
    for bytes in [b"not a zip".to_vec(), archive(None, false)] {
        let f = Fixture::new();
        assert_eq!(f.send(bytes).await.1, StatusCode::UNPROCESSABLE_ENTITY);
    }
}
#[tokio::test]
async fn expansion_and_metadata_limits() {
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
async fn rates_ignore_untrusted_forwarded_headers() {
    let f = Fixture::new();
    for _ in 0..12 {
        assert_eq!(
            f.json("POST", "/api/v1/reports", metadata(), false).await.0,
            StatusCode::CREATED
        );
    }
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
}
#[tokio::test]
async fn expiry_deletes_attachment_and_record() {
    let f = Fixture::new();
    let (_, code) = f.send(archive(None, true)).await;
    assert_eq!(code, StatusCode::OK);
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
    let (_, list) = f.json("GET", "/api/admin/reports", Value::Null, true).await;
    assert_eq!(list["total"], 0);
}
#[test]
fn hostile_signature_does_not_panic() {
    let f = Fixture::new();
    assert!(!f.state.verify("value", &"é".repeat(32)));
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
    let f = Fixture::new();
    let orphan = f.state.file(Uuid::new_v4());
    std::fs::write(&orphan, b"orphaned diagnostics").unwrap();
    let part = f.state.config.data.join("uploads").join("interrupted.part");
    let sparse = std::fs::File::create(&part).unwrap();
    sparse.set_len(f.state.config.quota_bytes).unwrap();
    assert_eq!(
        f.send(archive(None, true)).await.1,
        StatusCode::SERVICE_UNAVAILABLE
    );
    f.state.prune().unwrap_or_else(|_| panic!("prune"));
    assert!(!orphan.exists());
    assert!(part.exists()); // A current upload may still own this file.
    std::fs::remove_file(part).unwrap();
    assert_eq!(f.send(archive(None, true)).await.1, StatusCode::OK);
}

#[tokio::test]
async fn metadata_only_reports_cannot_grow_without_bound() {
    let f = Fixture::new();
    f.state.db.lock().unwrap().execute_batch(&format!("WITH RECURSIVE numbers(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM numbers WHERE n < {})
        INSERT INTO reports(id,key_hash,fingerprint,created,category,message,contact,version,expects_zip,ready,privacy_version)
        SELECT 'seed-'||n,'key-'||n,'fingerprint',{},'suggestion','A message','','',0,1,'2026-09-30' FROM numbers",atlas_reports::MAX_REPORTS,atlas_reports::now()-86401)).unwrap();
    assert_eq!(
        f.json("POST", "/api/v1/reports", metadata(), false).await.0,
        StatusCode::SERVICE_UNAVAILABLE
    );
}

#[tokio::test]
async fn archive_crc_duplicate_and_symlink_validation() {
    let mut bytes = archive(Some(("user/app.log", "hello")), true);
    // Change the central-directory CRC without touching compressed content.
    let central = bytes.windows(4).position(|b| b == b"PK\x01\x02").unwrap();
    bytes[central + 16] ^= 1;
    let f = Fixture::new();
    assert_eq!(f.send(bytes).await.1, StatusCode::UNPROCESSABLE_ENTITY);
    let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
    zip.start_file("manifest.json", zip::write::SimpleFileOptions::default())
        .unwrap();
    zip.write_all(br#"{"schema":2,"redaction":"public-v1"}"#)
        .unwrap();
    zip.add_symlink(
        "link",
        "/etc/passwd",
        zip::write::SimpleFileOptions::default(),
    )
    .unwrap();
    assert_eq!(
        f.send(zip.finish().unwrap().into_inner()).await.1,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert_eq!(
        f.send(archive(Some(("MANIFEST.JSON", "duplicate")), true))
            .await
            .1,
        StatusCode::UNPROCESSABLE_ENTITY
    );
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
fn configuration_requires_https_or_loopback_and_explicit_proxy() {
    for origin in [
        "http://reports.test",
        "https://reports.test/path",
        "https://user@reports.test",
        "https://reports.test?x=y",
        "https://reports.test/",
    ] {
        let dir = tempfile::tempdir().unwrap();
        let config = Config {
            data: dir.path().into(),
            web: dir.path().join("web"),
            origin: origin.into(),
            gateway_secret: "test-gateway-secret-xxxxxxxxxxxxxxxx".into(),
            admins: vec!["jack".into()],
            proxy_ips: vec!["127.0.0.1".parse().unwrap()],
            quota_bytes: 2 * 1024 * 1024 * 1024,
            retention_days: 90,
        };
        assert!(create(config).is_err(), "{origin}");
    }
}

#[tokio::test]
async fn verified_cloudflare_clients_have_separate_buckets() {
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
