use atlas_reports::{Config, create};
use std::{env, net::SocketAddr, path::PathBuf, time::Duration};

#[tokio::main]
async fn main() {
    let required = |name| env::var(name).unwrap_or_else(|_| panic!("Set {name}"));
    let config = Config {
        data: PathBuf::from(env::var("ATLAS_REPORTS_DATA").unwrap_or_else(|_| "/data".into())),
        web: PathBuf::from(env::var("ATLAS_REPORTS_WEB").unwrap_or_else(|_| "/web".into())),
        origin: required("ATLAS_REPORTS_ORIGIN"),
        gateway_secret: required("ATLAS_REPORTS_GATEWAY_SECRET"),
        admins: required("ATLAS_REPORTS_ADMINS")
            .split(',')
            .map(str::to_owned)
            .collect(),
        proxy_ips: required("ATLAS_REPORTS_PROXY_IPS")
            .split(',')
            .map(|v| v.parse().expect("Invalid trusted proxy IP"))
            .collect(),
        quota_bytes: env::var("ATLAS_REPORTS_QUOTA_BYTES")
            .ok()
            .map(|v| v.parse().expect("Invalid quota"))
            .unwrap_or(2 * 1024 * 1024 * 1024),
        retention_days: 90,
    };
    let (app, state) =
        create(config).unwrap_or_else(|_| panic!("Cannot initialize report service"));
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(Duration::from_secs(3600)).await;
            let copy = state.clone();
            let _ = tokio::task::spawn_blocking(move || copy.prune()).await;
        }
    });
    let address = env::var("ATLAS_REPORTS_LISTEN").unwrap_or_else(|_| "0.0.0.0:8080".into());
    let listener = tokio::net::TcpListener::bind(&address)
        .await
        .expect("Cannot listen");
    println!("Atlas reports listening on {address}");
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await
    .expect("Server stopped");
}
