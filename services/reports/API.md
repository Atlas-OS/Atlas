# Atlas reports service reference

The reports service receives issue reports and suggestions from Atlas Manager and
the [report website](https://reports.atlasos.net). It stores them in SQLite and
serves the review API, the agent API and the separately built website. This
reference is for operators and contributors; production setup is in
[deploy/README.md](deploy/README.md). The service and the reverse proxy enforce
access control, never the website.

## Build and test

```sh
cargo build --release --locked
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
cargo audit
```

The `Dockerfile` image runs as UID/GID 10001. CI (`.github/workflows/reports.yml`)
runs `fmt`, `clippy` and `test` on Ubuntu and Windows for this service and the MCP
server. `tests/api.rs` covers proxy trust, CSRF, retries, deletion and retention,
malicious archives, size limits, interrupted uploads, quota recovery and rate-limit
identities. `Cargo.lock` pins dependencies; run `cargo audit` before deploying.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `ATLAS_REPORTS_ORIGIN` | Required | Public origin, such as `https://reports.atlasos.net`, with no path, query, user name or trailing slash. `http://` only for `localhost` or a loopback IP. Other `Host` values get 400. |
| `ATLAS_REPORTS_GATEWAY_SECRET` | Required | At least 32 characters, no control characters. Sent by the proxy as `X-Atlas-Gateway`; also signs upload tokens, CSRF tokens and agent credentials, and identifies retried submissions. |
| `ATLAS_REPORTS_ADMINS` | Required | Reviewer usernames, comma-separated, matched against `Remote-User`. No empty entries or control characters. |
| `ATLAS_REPORTS_PROXY_IPS` | Required | IP addresses the proxy connects from, comma-separated. No unspecified or multicast addresses. |
| `ATLAS_REPORTS_DATA` | `/data` | Data directory. Keep it outside the web directory. |
| `ATLAS_REPORTS_WEB` | `/web` | Built website. Mount it read-only. |
| `ATLAS_REPORTS_LISTEN` | `0.0.0.0:8080` | Listen address. Only the proxy should reach it. |
| `ATLAS_REPORTS_QUOTA_BYTES` | 2 GiB | Attachment space, including partial and orphaned files. Minimum 134217728 (128 MiB). |

- A missing or invalid setting stops startup with a message naming the setting,
  not its value.
- Retention is fixed at 90 days.
- Run one process per data directory; cleanup and concurrency limits use locks
  inside the process.
- Keep the gateway secret in root-readable deployment configuration, never in this
  repository, the website bundle or a cookie. Keep it stable: rotating it
  invalidates upload tokens, CSRF tokens and agent credentials, and a submission
  retried across the rotation becomes a new report.
- On Unix the data and `uploads` directories get mode `700`, the database and
  attachments `600`. Either directory is refused if it is a symbolic link.

## Proxy trust

A request comes from the proxy only if its socket peer is in
`ATLAS_REPORTS_PROXY_IPS` and its `X-Atlas-Gateway` header matches the gateway
secret.

- **Administrator routes** return 401 unless the request comes from the proxy with
  `Remote-User` in `ATLAS_REPORTS_ADMINS`; a forwarded username alone never grants
  access. Methods other than `GET` and `HEAD` also need `Origin` equal to
  `ATLAS_REPORTS_ORIGIN` and the `X-Atlas-CSRF` token from `/api/admin/session`,
  or return 403. A token lasts until the end of the next UTC day.
- **Agent routes** require a Bearer credential; see [Agent access](#agent-access).
- **Rate limits** identify the client by `CF-Connecting-IP`, then the last
  `X-Forwarded-For` entry, then the socket peer. The headers count only on
  requests from the proxy.

The proxy must strip incoming `Remote-User` and `X-Atlas-Gateway`, set
`Remote-User` only after its own sign-in check succeeds, and add `X-Atlas-Gateway`
to every forwarded request, including `/api/v1/` and `/api/agent/`. Behind
Cloudflare, it must accept only Cloudflare's addresses, checked at the socket,
before forwarding `CF-Connecting-IP`. Otherwise it must strip `CF-Connecting-IP`
and append the verified client address to `X-Forwarded-For`.
[Authentication and proxy](deploy/README.md#authentication-and-proxy) covers
Traefik and Authelia.

Never publish the service's port; it is not built to face the Internet. TLS,
upload size limits, slow-connection timeouts and resource limits belong at the
proxy and container. Every response sets `Cache-Control: no-store`,
`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
`Referrer-Policy: no-referrer` and a Content Security Policy that allows only the
site's own scripts, styles and connections.

## Public API

| Route | Purpose |
| --- | --- |
| `GET /api/v1/info` | `privacy_version`, `retention_days`, `max_zip_bytes`, `operator` and `destination` |
| `GET /health` | `{"status": "ok"}` when the database responds |
| `POST /api/v1/reports` | Create a report |
| `PUT /api/v1/reports/{id}/diagnostics` | Upload its diagnostic ZIP |

Errors are JSON with a `detail` message; a malformed ID or query string gets a
plain-text 400.

Create a report with `Content-Type: application/json`:

```json
{
  "submission_key": "a UUID v4 generated once for this submission",
  "category": "issue",
  "message": "What happened and what was expected?",
  "contact": "",
  "version": "0.6.0",
  "has_diagnostics": true,
  "consent": true,
  "privacy_version": "2026-10-01"
}
```

`category` is `issue` or `suggestion`, and `consent` must be `true`. `contact`,
`version` and `has_diagnostics` are optional. Unknown fields are refused.

| Status | When |
| --- | --- |
| 201 | Returns `id`, `received`, and `upload_token` if `has_diagnostics` is true. Resending the same fields with the same `submission_key` returns the same report, so retries are safe; they still count toward the hourly limit. |
| 403 | An `Origin` header other than `ATLAS_REPORTS_ORIGIN` |
| 409 | Different fields under a used `submission_key` |
| 422 | An outdated `privacy_version`, with a `detail` asking the sender to reload the page or update Atlas Manager; or another invalid field, with a general `detail` |

Use a new `submission_key` when the sender edits the report or starts another.

Upload the ZIP within 24 hours of creating the report, with
`Content-Type: application/zip` and `Authorization: Bearer <upload_token>`.
Success, including a repeated upload, returns `received: true`. A wrong or expired
token, or a report sent without diagnostics, returns 404.

## Administrator API

These routes follow [Proxy trust](#proxy-trust).

| Route | Purpose |
| --- | --- |
| `GET /api/admin/session` | Signed-in username and CSRF token |
| `GET /api/admin/reports` | Completed reports, newest first, 50 per page, with `total`; optional `status` and `offset` |
| `PATCH /api/admin/reports/{id}` | Set `status` (`new`, `investigating`, `resolved` or `closed`) and `notes` |
| `DELETE /api/admin/reports/{id}` | Delete the report and its attachment; 404 if the report does not exist |
| `GET /api/admin/reports/{id}/diagnostics` | The ZIP as a download named `Atlas-report-{id}.zip`, with its SHA-256 in `X-Atlas-Diagnostics-Sha256` and when the report was made, in Unix seconds, in `X-Atlas-Report-Created`; 404 if there is none |
| `GET /api/admin/agent-tokens` | Metadata for the newest 256 agent credentials |
| `POST /api/admin/agent-tokens` | Create a credential from `name` (1–80 characters), `days` (1–90) and optional `can_delete` (default `false`). The secret is shown once. 409 when 20 are active. |
| `DELETE /api/admin/agent-tokens/{id}` | Revoke a credential |

Reviews, downloads, deletions and credential changes are audited under the
reviewer's username. The dashboard must render messages, contact details and notes
as text, never HTML.

## Agent access

Agent requests must come through the proxy with
`Authorization: Bearer <credential>`. Credentials, called access keys in the
dashboard, look like `atlas_reports_<id>_<64 hex characters>` and are stored only
as HMAC signatures. Expiry and revocation are checked on every request.

- Cookies and `Remote-User` cannot replace the credential.
- Any request with an `Origin` header gets 403, so web pages cannot call these
  routes.
- A missing, malformed, expired or revoked credential gets 401, and nothing is
  written. Nothing is rate-limited before authentication, so failed attempts spend
  no shared budget; a 256-bit secret cannot be guessed in practice.
- Agents cannot edit reports, manage credentials or use administrator routes.

| Route | Returns |
| --- | --- |
| `GET /api/agent/reports` | Metadata and a 240-character message preview, newest first; optional `status`, `offset` and `limit` (1–50, default 20). No contact details or notes. |
| `GET /api/agent/reports/{id}` | Message, notes and diagnostic metadata. No contact details. |
| `GET /api/agent/reports/{id}/diagnostics` | The ZIP, with its SHA-256 in `X-Atlas-Diagnostics-Sha256` and when the report was made, in Unix seconds, in `X-Atlas-Report-Created`; 404 if there is none |
| `DELETE /api/agent/reports/{id}` | 204 if the credential has `can_delete` and the JSON body is `{"confirm_id": "<id>"}`; 403 without `can_delete`, 422 if `confirm_id` differs, 404 if the report does not exist |

`confirm_id` catches malformed requests; it is not a human approval. JSON
responses include `"untrusted_content": true` because report text is data, never
instructions. Reads, downloads and deletions are audited per credential, and
listings once per credential per hour. The [MCP server](../reports-mcp/README.md)
connects MCP clients to these routes.

## Limits

| Limit | Value |
| --- | --- |
| JSON request body | 32 KiB, received within 15 seconds |
| Message | 10–4,000 characters after trimming |
| Contact, version | 254 and 80 characters |
| Review notes | 8,000 characters |
| New reports | 500 in any 24 hours; 10,000 stored |
| Per client (IPv4 address or IPv6 /64) | 12 submission and 12 upload requests an hour |
| All clients | 1,000 submission and 1,000 upload requests an hour. Only requests within their client's limit count, so one client cannot use it up. |
| Agent credentials | 600 requests an hour each, counted after verification; 20 active at once |
| Agent deletions, credential creation | 60 and 20 an hour per client |
| Upload | 64 MiB, streamed to disk within 120 seconds |
| Concurrency | 32 requests, including at most 2 uploads being received or validated |
| Free space | New reports need 128 MiB free on disk; uploads also need 128 MiB left under the quota |

Hourly limits reset at the start of each UTC hour. Rate limits return 429 and
capacity limits 503; both are retryable, and nothing stored is dropped. The
database and audit trail use disk space outside the quota, so leave room.

## Data and privacy

The Atlas team runs the production service. Sending a report is optional; there
are no reporter accounts or background uploads. Atlas Manager sends only to
`https://reports.atlasos.net` and does not follow redirects. If sending fails, it
keeps the message and the diagnostics ZIP, so the sender can try again or use the
report website.

A report holds its category, message, optional contact details, Atlas version, the
privacy notice version the sender accepted and, optionally, a redacted diagnostic
ZIP the sender can check first. Reviewers can add a status and notes. Report IDs
are random, and there is no public listing, download or status lookup.

Reports reach the team's reviewers through the dashboard, and the agents the team
issues access keys to. An agent usually runs in an MCP client that sends what it
reads to an AI provider, so the privacy notice says the team may use AI services
from other companies. Agents get a report's message, notes and diagnostics, never
its contact details (see [Agent access](#agent-access)).

| Data | Kept for |
| --- | --- |
| Reports and attachments | 90 days, or until deleted |
| Submissions whose diagnostics never arrived | 24 hours |
| Audit entries: actor, action, time and report or credential ID | 90 days; at most the latest 10,000 agent listings, reads and downloads, and the latest 50,000 other entries, so heavy agent use cannot push out reviews, reviewer downloads, deletions or credential changes |
| Rate-limit counters, keyed by an HMAC of the client address, never the address itself | 24 hours |

Deleting a report, by a reviewer, an agent or expiry, removes its message, contact
details, notes and attachment. SQLite's `secure_delete` overwrites the text in the
database file, and the write-ahead log is emptied afterwards. Attachment files are
removed, not securely erased.

The privacy notice says reports are deleted after 90 days, and that covers every
copy:

- **Backups** are kept for at most 90 days; see
  [Operations](deploy/README.md#operations).
- **The MCP server** deletes each ZIP it downloaded once its report is 90 days
  old, using the download's `X-Atlas-Report-Created` header; see
  [Downloaded copies](../reports-mcp/README.md#downloaded-copies).
- **Reviewers** delete ZIPs they download from the dashboard when they finish
  with them, and within 90 days of the report.

Deleting a report sooner doesn't reach copies already downloaded or backed up.

Cloudflare and the reverse proxy can log client addresses and request metadata.
Never enable request-body or `Authorization` logging.

`PRIVACY_VERSION` is compiled into the service (`src/lib.rs`), the website (its
`src/api.ts`) and Atlas Manager (`app/src/services/reports.rs`); change all three
with the notice text. An Atlas Manager test checks that the service declares the
same version. The service accepts only the current version, so changing it stops
older Manager builds and cached pages from sending until they update. Deploy the
website and service together.

## Diagnostic archives

An upload must be a ZIP whose `manifest.json` declares `"schema": 2` and
`"redaction": "public-v1"`. That confirms the format and the sender's redaction
claim, not that the files hold no personal information, so treat every archive,
log and message as untrusted. Archives are never extracted or executed.

Validation (`src/archive.rs`) reads every member to check its CRC, and refuses:

| Check | Refused |
| --- | --- |
| Size | An empty archive, more than 2,048 members, a member over 32 MiB, more than 256 MiB expanded, or a `manifest.json` over 2 MiB |
| Entry type | Encrypted entries, symbolic links, special files, and compression other than stored or deflate |
| Names | Absolute paths; `.`, `..` or empty segments; backslashes, colons or control characters; over 512 bytes; duplicates, including names that differ only by case |
| Headers | Local headers that disagree with the central directory, Info-ZIP Unicode path or comment fields (which can replace the stored name), and data descriptors |
| Layout | Data before the first member, and gaps between members or before the central directory |

A refused archive returns 422 and is not kept. The sender can retry with the same
token until it expires.

## How it works

- **Cleanup** (`Store::prune` in `src/lib.rs`) runs at startup and hourly. It
  applies the retention above and removes partial uploads older than 24 hours and
  attachments with no completed report.
- **Older databases**, created before `secure_delete`, are rebuilt once with
  `VACUUM` at startup to clear text left by earlier deletions, retrying at each
  start until it succeeds (`create` in `src/lib.rs`).
