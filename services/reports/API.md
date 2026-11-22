# Atlas reports service reference

This reference describes the reports service for operators and contributors: its settings, routes, limits and data handling.
The service receives issue reports and suggestions from Atlas Manager and the [report website](https://reports.atlasos.net), stores them in SQLite, and serves the review API, the agent API and the separately built website.
The [deployment guide](deploy/README.md) covers production setup, and the [Atlas reports overview](README.md) covers building and testing.

The service and the reverse proxy enforce access control; the website has no part in it.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `ATLAS_REPORTS_ORIGIN` | Required | Public origin, such as `https://reports.atlasos.net`, with no path, query, user name or trailing slash. `http://` only for `localhost` or a loopback IP. Other `Host` values get 400. |
| `ATLAS_REPORTS_GATEWAY_SECRET` | Required | At least 32 characters, no control characters. The proxy sends it as `X-Atlas-Gateway`, and it signs upload tokens, CSRF tokens and access keys. |
| `ATLAS_REPORTS_ADMINS` | Required | Reviewer usernames, comma-separated, matched against `Remote-User`. No empty entries or control characters. |
| `ATLAS_REPORTS_PROXY_IPS` | Required | IP addresses the proxy connects from, comma-separated. No unspecified or multicast addresses. |
| `ATLAS_REPORTS_DATA` | `/data` | Data directory. Keep it outside the web directory. |
| `ATLAS_REPORTS_WEB` | `/web` | Built website. Mount it read-only. |
| `ATLAS_REPORTS_LISTEN` | `0.0.0.0:8080` | Listen address. Only the proxy should reach it. |
| `ATLAS_REPORTS_QUOTA_BYTES` | 2 GiB | Attachment space, including partial and orphaned files. Minimum 134217728 (128 MiB). |

- A missing or invalid setting stops startup with a message that names the setting and leaves out its value.
- Retention is fixed; see [Data and privacy](#data-and-privacy).
- Run one process per data directory.
  Cleanup and concurrency limits use locks inside the process.
- Keep the gateway secret in root-readable deployment configuration, and out of this repository, the website bundle and cookies.
- Keep the gateway secret stable.
  The service also uses it to recognise retried submissions.
  Rotating it invalidates upload tokens, CSRF tokens and access keys, and a submission retried across the rotation becomes a new report.
- On Unix the data and `uploads` directories get mode `700`, and the database and attachments `600`.
  The service refuses either directory if it's a symbolic link.

## Proxy trust

A request comes from the proxy only if its socket peer is in `ATLAS_REPORTS_PROXY_IPS` and its `X-Atlas-Gateway` header matches the gateway secret.

- **Administrator routes** return 401 unless the request comes from the proxy with `Remote-User` in `ATLAS_REPORTS_ADMINS`.
  A forwarded username alone doesn't grant access.
  Methods other than `GET` and `HEAD` also need `Origin` equal to `ATLAS_REPORTS_ORIGIN` and the `X-Atlas-CSRF` token from `/api/admin/session`, or they return 403.
  A token lasts until the end of the next UTC day.
- **Agent routes** require an access key as a Bearer token; see [Agent access](#agent-access).
- **Rate limits** identify the client by `CF-Connecting-IP`, then the last `X-Forwarded-For` entry, then the socket peer.
  The headers count only on requests from the proxy.

The proxy must strip incoming `Remote-User` and `X-Atlas-Gateway`, and set `Remote-User` only after its own sign-in check succeeds.
It must add `X-Atlas-Gateway` to every forwarded request, including `/api/v1/` and `/api/agent/`.
Behind Cloudflare, the proxy must accept connections only from Cloudflare's addresses, checked at the socket, before it forwards `CF-Connecting-IP`.
Without Cloudflare, it must strip `CF-Connecting-IP` and append the verified client address to `X-Forwarded-For`.
[Authentication and proxy](deploy/README.md#authentication-and-proxy) covers Traefik and Authelia.

Don't publish the service's port, because it isn't built to face the internet.
TLS, upload size limits, slow-connection timeouts and resource limits belong at the proxy and container.
Every response sets `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` and a Content Security Policy that allows only the site's own scripts, styles and connections.

## Public API

| Route | Purpose |
| --- | --- |
| `GET /api/v1/info` | The privacy notice version, retention and upload limit |
| `GET /health` | `{"status": "ok"}` when the database responds |
| `POST /api/v1/reports` | Create a report |
| `PUT /api/v1/reports/{id}/diagnostics` | Upload its diagnostic ZIP |

Errors are JSON with a `detail` message.
A malformed ID or query string gets a plain-text 400.

### Service information

`GET /api/v1/info` returns:

```json
{
  "privacy_version": "<yyyy-MM-dd>",
  "retention_days": 90,
  "max_zip_bytes": 67108864,
  "operator": "Atlas team",
  "destination": "https://reports.atlasos.net"
}
```

`privacy_version` is the notice version a report must confirm, and `destination` is `ATLAS_REPORTS_ORIGIN`.

### Create a report

Send the report with `Content-Type: application/json`:

```json
{
  "submission_key": "3f2b8c1e-7a4d-4e9b-b6c5-1d8e2f0a9c47",
  "category": "issue",
  "message": "What happened and what was expected?",
  "contact": "",
  "version": "<version>",
  "has_diagnostics": true,
  "consent": true,
  "privacy_version": "<yyyy-MM-dd>"
}
```

- `submission_key` is a UUID v4 that the sender generates once for this submission.
- `category` is `issue` or `suggestion`.
- `consent` must be `true`, and `privacy_version` must match the one from `GET /api/v1/info`.
- `contact`, `version` and `has_diagnostics` are optional.
- Unknown fields are refused.

A created report returns 201:

```json
{
  "id": "9c41e7d2-5b8a-4f13-a6e0-2d7c3b9f8e15",
  "received": false,
  "upload_token": "<64 hex characters>"
}
```

`received` is `true` once the report is complete: straight away without diagnostics, or after the upload.
`upload_token` is `null` when `has_diagnostics` is `false`.

| Status | When |
| --- | --- |
| 201 | The report was created, or the same fields arrived again under the same `submission_key`. |
| 403 | An `Origin` header other than `ATLAS_REPORTS_ORIGIN`. |
| 409 | Different fields under the `submission_key` of a report that hasn't expired. |
| 422 | An outdated `privacy_version`, with a `detail` asking the sender to reload the page or update Atlas Manager, or another invalid field, with a general `detail`. |

Resending the same fields with the same `submission_key` returns the same report, so retries are safe.
They still count toward the hourly limit.
A report whose diagnostics didn't arrive within 24 hours has expired.
Resending it, changed or not, replaces it with a new report that has a new `id` and `upload_token`.
Use a new `submission_key` when the sender edits the report or starts another.

### Upload diagnostics

Upload the ZIP within 24 hours of creating the report, with `Content-Type: application/zip` and `Authorization: Bearer <upload_token>`.
Success, including a repeated upload, returns the report's `id` with `"received": true`.
A wrong or expired token, or a report sent without diagnostics, returns 404.

## Administrator API

These routes follow [Proxy trust](#proxy-trust).

| Route | Purpose |
| --- | --- |
| `GET /api/admin/session` | Signed-in username and CSRF token |
| `GET /api/admin/reports` | Completed reports, newest first, 50 per page, with `total`; optional `status` and `offset` |
| `PATCH /api/admin/reports/{id}` | Set `status` (`new`, `investigating`, `resolved` or `closed`) and `notes` |
| `DELETE /api/admin/reports/{id}` | Delete the report and its attachment; 404 if the report doesn't exist |
| `GET /api/admin/reports/{id}/diagnostics` | The ZIP as a download named `Atlas-report-{id}.zip`, with the headers listed under [Agent access](#agent-access); 404 if there's none |
| `GET /api/admin/agent-tokens` | Metadata for the newest 256 access keys |
| `POST /api/admin/agent-tokens` | Create an access key from `name` (1–80 characters), `days` (1–90) and optional `can_delete` (default `false`). The key is shown once. 409 when 20 are active. |
| `DELETE /api/admin/agent-tokens/{id}` | Revoke an access key |

Reviews, downloads, deletions and access key changes are audited under the reviewer's username.
The dashboard must render messages, contact details and notes as text, so none of them can inject HTML.

## Agent access

Agent requests must come through the proxy with `Authorization: Bearer <access key>`.
Access keys look like `atlas_reports_<id>_<64 hex characters>`, and the service stores only their HMAC signatures.
Expiry and revocation are checked on every request.

Every access key can read reports and download diagnostics.
Only a key with the delete permission (`can_delete`, reported as scope `reports:delete`) can delete reports.

- Cookies and `Remote-User` can't replace the access key.
- Any request with an `Origin` header gets 403, so web pages can't call these routes.
- A missing, malformed, expired or revoked access key gets 401, and nothing is written.
- Nothing is rate-limited before authentication, so failed attempts spend no shared budget.
  A 256-bit secret can't be guessed in practice.
- Agents can't edit reports, manage access keys or use administrator routes.

| Route | Returns |
| --- | --- |
| `GET /api/agent/reports` | Metadata and a 240-character message preview, newest first; optional `status`, `offset` and `limit` (1–50, default 20). Contact details and notes are left out. |
| `GET /api/agent/reports/{id}` | Message, notes and diagnostic metadata. Contact details are left out. |
| `GET /api/agent/reports/{id}/diagnostics` | The ZIP; 404 if there's none |
| `DELETE /api/agent/reports/{id}` | 204 if the key has the delete permission and the JSON body is `{"confirm_id": "<id>"}`; 403 without the delete permission, 422 if `confirm_id` differs, 404 if the report doesn't exist |

Diagnostic downloads, here and on the administrator route, carry two headers:

- `X-Atlas-Diagnostics-Sha256`: the ZIP's SHA-256.
- `X-Atlas-Report-Created`: when the report was made, in Unix seconds.

`confirm_id` catches malformed requests; it isn't a human approval.
JSON responses include `"untrusted_content": true`, so agents treat report text as data to examine.
Reads, downloads and deletions are audited per access key, and listings once per access key per hour.
The [MCP server](../reports-mcp/README.md) connects MCP clients to these routes.

## Limits

| Limit | Value |
| --- | --- |
| JSON request body | 32 KiB, received within 15 seconds |
| Message | 10–4,000 characters after trimming |
| Contact, version | 254 and 80 characters |
| Review notes | 8,000 characters |
| New reports | 500 in any 24 hours; 10,000 stored |
| Per client (IPv4 address or IPv6 /64) | 12 submission and 12 upload requests an hour |
| All clients | 1,000 submission and 1,000 upload requests an hour. Only requests within their client's limit count, so one client can't use it up. |
| Access keys | 600 requests an hour each, counted after verification; 20 active at once |
| Agent deletions, access key creation | 60 and 20 an hour per client |
| Upload | 64 MiB, streamed to disk within 120 seconds |
| Concurrency | 32 requests, including at most 2 uploads being received or validated |
| Free space | New reports need 128 MiB free on disk; uploads also need 128 MiB left under the quota |

Hourly limits reset at the start of each UTC hour.
Rate limits return 429 and capacity limits 503.
Both are retryable, and nothing stored is dropped.
The database and audit trail use disk space outside the quota, so leave room for them.

## Data and privacy

The Atlas team runs the production service.
Sending a report is optional, and there are no reporter accounts or background uploads.
Atlas Manager sends only to `https://reports.atlasos.net` and doesn't follow redirects.
If sending fails, it keeps the message and the diagnostics ZIP, so the sender can try again or use the report website.

A report holds its category, message, optional contact details, Atlas version and the privacy notice version the sender accepted.
It can also hold a redacted diagnostic ZIP that the sender can check first.
Reviewers can add a status and notes.
Report IDs are random, and there's no public listing, download or status lookup.

Reports reach the team's reviewers through the dashboard, and the agents the team issues access keys to.
An agent usually runs in an MCP client that sends what it reads to an AI provider, so the privacy notice says the team may use AI services from other companies.
Agents get a report's message, notes and diagnostics, without its contact details (see [Agent access](#agent-access)).

| Data | Kept for |
| --- | --- |
| Reports and attachments | 90 days, or until deleted |
| Submissions whose diagnostics never arrived | 24 hours |
| Audit entries: actor, action, time and report or access key ID | 90 days; at most the latest 10,000 agent listings, reads and downloads, and the latest 50,000 other entries, so heavy agent use can't push out reviews, reviewer downloads, deletions or access key changes |
| Rate-limit counters, keyed by an HMAC of the client address instead of the address itself | 24 hours |

Deleting a report, whether a reviewer, an agent or expiry does it, removes its message, contact details, notes and attachment.
SQLite's `secure_delete` overwrites the text in the database file, and the write-ahead log is emptied afterwards.
Attachment files are removed but not securely erased.

The privacy notice says reports are deleted after 90 days, and that covers every copy:

- **Backups** are kept for at most 90 days; see [Operations](deploy/README.md#operations).
- **The MCP server** deletes each ZIP it downloaded once its report is 90 days old, using the download's `X-Atlas-Report-Created` header; see [Downloaded copies](../reports-mcp/README.md#downloaded-copies).
- **Reviewers** delete ZIPs they download from the dashboard when they finish with them, and within 90 days of the report.

Deleting a report sooner doesn't reach copies already downloaded or backed up.

Cloudflare and the reverse proxy can log client addresses and request metadata.
Keep request-body and `Authorization` logging turned off.

`PRIVACY_VERSION` is compiled into the service (`src/lib.rs`), the reports website and Atlas Manager (`app/src/services/reports.rs`).
The website's source is kept outside this repository.
Change all three together with the notice text.
An Atlas Manager test checks that the service declares the same version.
The service accepts only the current version, so changing it stops older Atlas Manager builds and cached pages from sending until they update.
Deploy the website and service together.

## Diagnostic archives

An upload must be a ZIP whose `manifest.json` declares `"schema": 2` and `"redaction": "public-v1"`.
That confirms the format and the sender's redaction claim, but not that the files hold no personal information, so treat every archive, log and message as untrusted.
The service doesn't extract or run archives.

Validation (`src/archive.rs`) reads every member to check its CRC, and refuses:

| Check | Refused |
| --- | --- |
| Size | An empty archive, more than 2,048 members, a member over 32 MiB, more than 256 MiB expanded, or a `manifest.json` over 2 MiB |
| Entry type | Encrypted entries, symbolic links, special files, and compression other than stored or deflate |
| Names | Absolute paths; `.`, `..` or empty segments; backslashes, colons or control characters; over 512 bytes; duplicates, including names that differ only by case |
| Headers | Local headers that disagree with the central directory, Info-ZIP Unicode path or comment fields (which can replace the stored name), and data descriptors |
| Layout | Data before the first member, and gaps between members or before the central directory |

A refused archive returns 422 and isn't kept.
The service log names the check that refused it and the report ID; the response leaves both out.
The sender can retry with the same token until it expires.

## Background tasks

- **Cleanup** (`Store::prune` in `src/lib.rs`) runs at startup and then hourly.
  It applies the retention in [Data and privacy](#data-and-privacy), and removes partial uploads older than 24 hours and attachments with no completed report.
- **Compaction** (`open_database` in `src/lib.rs`) runs at startup on a database that hasn't yet been rebuilt with `secure_delete` on.
  It rebuilds the file once with `VACUUM`, so no text from earlier deletions remains, and retries at each start until it succeeds.
