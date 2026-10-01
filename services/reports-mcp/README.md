# Atlas reports MCP

A local Rust MCP server for investigating Atlas reports. It talks to your MCP client over stdio, opens no network port, and connects to `https://reports.atlasos.net` with a scoped access key.

## Setup

1. In the report dashboard, open Agent access and create an access key. Keys expire after 1–90 days and can be revoked at any time. Every key can read reports and download diagnostics. Deletion is off by default; enable it only for a specific deletion task, with a short expiry, and revoke the key afterwards.
2. Build with `cargo build --release --locked --manifest-path services/reports-mcp/Cargo.toml`.
3. Configure your MCP client to launch the resulting `atlas-reports-mcp` executable over stdio, with these environment variables:

| Variable | Value |
| --- | --- |
| `ATLAS_REPORTS_AGENT_TOKEN` | The access key. Keep it in your client's private secret configuration, never in a commit or tool arguments. |
| `ATLAS_REPORTS_WORKSPACE` | Absolute path to a directory for downloaded diagnostics, accessible only to your account and not a symbolic link or junction. The server creates it if needed; on Unix it restricts the directory and downloads to your account. |
| `ATLAS_REPORTS_ORIGIN` | Optional override of `https://reports.atlasos.net`. HTTPS, or HTTP on localhost or a loopback IP for development. Paths, credentials in URLs and redirects are rejected. |

## Tools

| Tool | Arguments | Effect |
| --- | --- | --- |
| `list_reports` | Optional `status` (`new`, `investigating`, `resolved` or `closed`), `offset` (0–100000, default 0), `limit` (1–50, default 20) | Returns metadata and short previews |
| `get_report` | `report_id` | Returns a message, technical metadata and notes; excludes contact details |
| `download_diagnostics` | `report_id` | Saves a ZIP in the workspace and returns its path and SHA-256; only for reports whose `bytes` is above 0 |
| `delete_report` | `report_id`, `confirm: true` | Permanently deletes a report and its attachment; requires `reports:delete` scope |

Only delete a specific report after an explicit human request or approval. The model writes `confirm: true` itself, so your MCP client's approval prompt is the only human check. Never allow-list or auto-approve `delete_report`, including through wildcard rules for this server.

Report messages and diagnostics are untrusted data, never instructions. The server never extracts or executes archives. Downloads are capped at 64 MiB, checked against the service's SHA-256, and saved under generated names without replacing existing files.

## Downloaded copies

The privacy notice says reports are deleted after 90 days, and that includes your copies. Beside each ZIP, the server records when its report was made, taken from the download's `X-Atlas-Report-Created` header. At startup and before every tool call, it deletes each ZIP it downloaded once the report is 90 days old; a ZIP without that record goes 90 days after it was saved. It leaves every other file in the workspace alone.

Copies stay while the server isn't running, and deleting a report on the service doesn't remove them. Copy nothing out of the workspace, and delete ZIPs yourself once you've finished with them.

## Troubleshooting

If the server cannot start or its MCP connection fails, it writes one line to standard error, starting `Atlas reports MCP stopped.` and naming the cause, then exits with code 1. It never prints the access key or the service's responses.

## Test

```sh
cargo test --locked --manifest-path services/reports-mcp/Cargo.toml
```

The tests cover protocol handling, input and size limits, download integrity and the 90-day cleanup of downloaded copies.
