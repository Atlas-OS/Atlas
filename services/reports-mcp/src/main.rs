use atlas_reports_mcp::{
    ReportsServer,
    api::{Client, Config, DEFAULT_ORIGIN},
};
use rmcp::{ServiceExt, transport::stdio};
use std::{env, path::PathBuf, process::ExitCode};

async fn run() -> Result<(), ()> {
    let client = Client::new(Config {
        origin: env::var("ATLAS_REPORTS_ORIGIN").unwrap_or_else(|_| DEFAULT_ORIGIN.into()),
        token: env::var("ATLAS_REPORTS_AGENT_TOKEN").map_err(|_| ())?,
        workspace: PathBuf::from(env::var_os("ATLAS_REPORTS_WORKSPACE").ok_or(())?),
    })
    .map_err(|_| ())?;
    ReportsServer::new(client)
        .serve(stdio())
        .await
        .map_err(|_| ())?
        .waiting()
        .await
        .map_err(|_| ())?;
    Ok(())
}

#[tokio::main]
async fn main() -> ExitCode {
    if run().await.is_err() {
        // Deliberately omit underlying HTTP/configuration errors, which may
        // contain credentials or untrusted response text. Stdout is MCP only.
        eprintln!(
            "Atlas reports MCP stopped. Check the private workspace, scoped token and report service connection."
        );
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}
