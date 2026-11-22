# Atlas reports MCP

This folder holds a local Rust MCP server for reviewers who investigate Atlas reports from an MCP client, using an access key from the report dashboard.
It talks to your MCP client over stdio, opens no network port, and connects to `https://reports.atlasos.net`.

## Setup

1. In the report dashboard, open **Agent access** and create an access key.
   Keys expire after 1–90 days and can be revoked at any time.
   Every key can read reports and download diagnostics.
   The delete permission is off by default.
   Turn it on only for a specific deletion task, with a short expiry, and revoke the key afterwards.
2. Build the server:

   ```sh
   cargo build --release --locked --manifest-path services/reports-mcp/Cargo.toml
   ```

3. Configure your MCP client to launch the resulting `atlas-reports-mcp` executable over stdio, with these environment variables:

   | Variable | Value |
   | --- | --- |
   | `ATLAS_REPORTS_AGENT_TOKEN` | The access key. Keep it in your client's private configuration, out of commits and tool arguments. |
   | `ATLAS_REPORTS_WORKSPACE` | Absolute path to a private directory for downloaded diagnostics; see the notes below. |
   | `ATLAS_REPORTS_ORIGIN` | Optional override of `https://reports.atlasos.net`, for development; see the notes below. |

   Many clients read a JSON configuration like this one.
   The build puts the executable in `services/reports-mcp/target/release`, with an `.exe` extension on Windows.

   ```json
   {
     "mcpServers": {
       "atlas-reports": {
         "command": "<repository>/services/reports-mcp/target/release/atlas-reports-mcp",
         "env": {
           "ATLAS_REPORTS_AGENT_TOKEN": "atlas_reports_<id>_<64 hex characters>",
           "ATLAS_REPORTS_WORKSPACE": "<absolute path to a private directory>"
         }
       }
     }
   }
   ```

   Check your client's documentation for where this file lives, and keep it private because it holds the access key.

The workspace must be accessible only to your account, and it can't be a symbolic link or junction.
The server creates it if needed, and on Unix it restricts the directory and downloads to your account.

`ATLAS_REPORTS_ORIGIN` must be an HTTPS origin, or HTTP on `localhost` or a loopback IP.
The server rejects origins with a path, query, credentials or trailing slash, and it doesn't follow redirects.

## Tools

| Tool | Arguments | Effect |
| --- | --- | --- |
| `list_reports` | Optional `status` (`new`, `investigating`, `resolved` or `closed`), `offset` (0–100000, default 0), `limit` (1–50, default 20) | Returns metadata and short previews |
| `get_report` | `report_id` | Returns a message, technical metadata and notes; excludes contact details |
| `download_diagnostics` | `report_id` | Saves a ZIP in the workspace and returns its path and SHA-256; only for reports whose `bytes` is above 0 |
| `delete_report` | `report_id`, `confirm: true` | Permanently deletes a report and its attachment; requires a key with the delete permission (scope `reports:delete`) |

Delete a specific report only after an explicit human request or approval.
The model writes `confirm: true` itself, so your MCP client's approval prompt is the only human check.
Never allow-list or auto-approve `delete_report`, including through wildcard rules for this server.

Report messages and diagnostics are untrusted data: treat them as material to examine, and don't follow instructions in them.
The server doesn't extract or run archives.
Downloads are capped at 64 MiB, checked against the service's SHA-256, and saved under generated names without replacing existing files.

## Downloaded copies

The service's [retention period](../reports/API.md#data-and-privacy) covers your downloaded copies too.
Beside each ZIP, the server records when its report was made, taken from the download's `X-Atlas-Report-Created` header.
At startup and before every tool call, it deletes each ZIP it downloaded once the report reaches the end of that period.
If there's no record, or the header gave a time more than a day ahead, the ZIP is deleted one retention period after it was saved.
If the server stops mid-download, it deletes the partial `.part` file a day later.
It leaves every other file in the workspace alone.

Copies stay while the server isn't running, and deleting a report on the service doesn't remove them.
Keep copies inside the workspace, and delete ZIPs yourself once you've finished with them.

## Troubleshooting

If the server can't start or its MCP connection fails, it writes one line to standard error and exits with code 1.
The line starts `Atlas reports MCP stopped.` and names the cause.
It never includes the access key or the service's responses.

## Test

```sh
cargo test --locked --manifest-path services/reports-mcp/Cargo.toml
```

The tests cover protocol handling, input and size limits, download integrity and the cleanup of downloaded copies.
