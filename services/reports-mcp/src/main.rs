use atlas_reports_mcp::{
    ReportsServer,
    api::{Client, Config, DEFAULT_ORIGIN, Error},
};
use rmcp::{ServiceExt, service::ServerInitializeError, transport::stdio};
use std::{env, path::PathBuf, process::ExitCode};

async fn run() -> Result<(), &'static str> {
    let client = Client::new(Config {
        origin: env::var("ATLAS_REPORTS_ORIGIN").unwrap_or_else(|_| DEFAULT_ORIGIN.into()),
        token: env::var("ATLAS_REPORTS_AGENT_TOKEN").map_err(
            |_| "Set ATLAS_REPORTS_AGENT_TOKEN to an access key from Agent access in the report dashboard.",
        )?,
        workspace: PathBuf::from(
            env::var_os("ATLAS_REPORTS_WORKSPACE")
                .ok_or("Set ATLAS_REPORTS_WORKSPACE to an absolute path for a private folder.")?,
        ),
    })
    .map_err(|error| match error {
        // At startup this can only be the workspace folder itself.
        Error::Workspace => {
            "ATLAS_REPORTS_WORKSPACE must be a folder this account can create and own, not a file, symbolic link or junction."
        }
        other => other.message(),
    })?;
    ReportsServer::new(client)
        .serve(stdio())
        .await
        .map_err(|error| match error {
            ServerInitializeError::ConnectionClosed(_) => {
                "The MCP client closed the connection before completing the initialize handshake."
            }
            _ => "The MCP client did not complete the initialize handshake.",
        })?
        .waiting()
        .await
        .map_err(|_| "The MCP connection ended unexpectedly.")?;
    Ok(())
}

#[tokio::main]
async fn main() -> ExitCode {
    match run().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(reason) => {
            // Fixed text only: underlying errors can include credentials,
            // response text or the client's JSON. Stdout carries MCP.
            eprintln!("Atlas reports MCP stopped. {reason}");
            ExitCode::FAILURE
        }
    }
}
