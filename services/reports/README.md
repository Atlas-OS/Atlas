# Atlas reports

This folder holds the Rust service behind Atlas reports, which validates, stores and manages the issue reports and suggestions people send.
This page explains what happens to a report for anyone sending one, and how contributors build and test the service.

## Sending a report

Send an issue or suggestion from Atlas Manager or the [report website](https://reports.atlasos.net).
Describe what happened, and include diagnostics if they help.
Contact details are optional.

Reports go privately to the Atlas team.
Nothing is uploaded automatically: you choose what to include and confirm before sending.
When Atlas Manager exports diagnostics, it removes your user name, PC name, email addresses and known passwords or keys.
It keeps the technical details needed to investigate, such as error details, hardware models and app names.
You're welcome to check the ZIP first.
Messages and contact details are sent as written.

Reports are deleted after 90 days, and copies the team downloads are deleted within the same 90 days.
The team can delete reports sooner through the private dashboard.
Reports and attachments are never publicly listed.
Access requires an authorised account with two-factor sign-in, or a scoped access key the team issues to an investigation tool.
The team may use AI services from other companies to help investigate.
These get a report's message and diagnostics, but not its contact details.
Hosting security services may record connection details, including IP addresses.
[Data and privacy](API.md#data-and-privacy) lists everything the service keeps and for how long.

You can also export diagnostics and share them on Discord.

## Build and test

Run these from `services/reports`:

```sh
cargo build --release --locked
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
cargo audit
```

- `cargo audit` needs the `cargo-audit` tool; run it before deploying, because `Cargo.lock` pins every dependency.
- `tests/api.rs` covers proxy trust, CSRF, retries, deletion and retention, malicious archives, size limits, interrupted uploads, quota recovery and rate-limit identities.
- CI (`.github/workflows/reports.yml`) runs `fmt`, `clippy` and `test` on Ubuntu and Windows, for this service and the [MCP server](../reports-mcp/README.md).
- The `Dockerfile` builds an image that runs as UID and GID 10001.

The [service reference](API.md) covers settings, routes and limits, and the [deployment guide](deploy/README.md) covers running the service in production.
