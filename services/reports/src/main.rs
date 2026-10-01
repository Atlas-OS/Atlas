use atlas_reports::{Config, StartupError, create};
use std::{env, net::SocketAddr, path::PathBuf, time::Duration};

#[tokio::main]
async fn main() {
    let required = |name: &str| env::var(name).unwrap_or_else(|_| panic!("Set {name}"));
    let list = |name: &str| {
        required(name)
            .split(',')
            .map(|v| v.trim().to_owned())
            .collect::<Vec<_>>()
    };
    let config = Config {
        data: PathBuf::from(env::var("ATLAS_REPORTS_DATA").unwrap_or_else(|_| "/data".into())),
        web: PathBuf::from(env::var("ATLAS_REPORTS_WEB").unwrap_or_else(|_| "/web".into())),
        origin: required("ATLAS_REPORTS_ORIGIN"),
        gateway_secret: required("ATLAS_REPORTS_GATEWAY_SECRET"),
        admins: list("ATLAS_REPORTS_ADMINS"),
        proxy_ips: list("ATLAS_REPORTS_PROXY_IPS")
            .iter()
            .map(|v| v.parse().expect("Invalid ATLAS_REPORTS_PROXY_IPS entry"))
            .collect(),
        quota_bytes: env::var("ATLAS_REPORTS_QUOTA_BYTES")
            .ok()
            .map(|v| v.parse().expect("Invalid ATLAS_REPORTS_QUOTA_BYTES"))
            .unwrap_or(2 * 1024 * 1024 * 1024),
    };
    let (app, state) = create(config).unwrap_or_else(|error| match error {
        StartupError::Config(reason) => panic!("Cannot initialize report service: {reason}"),
        StartupError::Storage => {
            panic!("Cannot initialize report service; see the storage or database error above.")
        }
    });
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
