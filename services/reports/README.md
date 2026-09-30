# Atlas reports

This Rust service receives voluntary issue reports and suggestions from Atlas
Manager or the report website. The intake, validation, storage and administrator
API live in the public Atlas repository. The Svelte website is built separately
and mounted as static files; it does not determine who can access reports.

## Data and privacy

The production destination is **https://reports.atlasos.net**, operated by the
Atlas team on its configured VPS. Sending a report is optional. There are no
reporter accounts and no background uploads. A report contains its category,
message, optional contact information, application version and, if selected, the
redacted diagnostic ZIP reviewed by the sender. Suggestions can omit diagnostics.

Atlas Manager uses a fixed HTTPS destination, does not follow redirects when
submitting, and can export diagnostics locally when delivery fails. The server
requires explicit consent and the current privacy notice version. Report IDs and
upload tokens are generated capabilities, not publicly searchable identifiers.

Reports and attachments expire after 90 days by default. Incomplete submissions
expire after 24 hours. An authorized administrator can delete a report immediately;
this removes its message, contact details, notes and attachment. The audit trail
keeps only the administrator name, action, timestamp and report ID, with a maximum
of 10,000 entries and the same retention window. File deletion does not promise
forensic erasure from a VPS disk or an operator's separately downloaded copy.

The application stores an HMAC-derived client-address bucket for rate limiting,
not the raw address, and removes old buckets after 24 hours. Cloudflare and the
reverse proxy can still process or log addresses and request metadata under their
own configuration. Do not enable request-body or Authorization-header logging.
The operator must keep any backup retention consistent with the privacy notice;
deleting live data does not automatically delete an independently made backup.

ZIP validation requires the Atlas `schema: 2`, `redaction: "public-v1"` manifest.
This checks format and the sender's redaction declaration; it cannot guarantee
that arbitrary files contain no personal information. The ZIP is never extracted
or executed. All members are read to EOF to check CRCs, expansion limits, unsafe
paths, duplicate names, encryption and symbolic or special file entries. Logs and
messages remain untrusted content, even after validation.

## Run on a VPS

Build with `cargo build --release --locked` or the supplied Dockerfile. The image
runs as UID/GID 10001. Mount a private writable data directory at `/data` and the
compiled Svelte site, read-only, at `/web`. The data directory, uploads and SQLite
database are restricted to their Unix owner. Keep `/data` outside the website
directory. The service supports one process per data directory; do not run
multiple replicas against the same SQLite database.

| Environment variable | Purpose |
| --- | --- |
| `ATLAS_REPORTS_ORIGIN` | Exact public origin, e.g. `https://reports.atlasos.net`, without trailing slash |
| `ATLAS_REPORTS_GATEWAY_SECRET` | Random secret of at least 32 characters, injected by the trusted reverse proxy |
| `ATLAS_REPORTS_ADMINS` | Comma-separated allowed Authelia usernames, currently `jack` |
| `ATLAS_REPORTS_PROXY_IPS` | Explicit comma-separated proxy peer IP addresses; never a wildcard |
| `ATLAS_REPORTS_DATA` | Private data directory, default `/data` |
| `ATLAS_REPORTS_WEB` | Compiled website directory, default `/web` |
| `ATLAS_REPORTS_LISTEN` | Private listening address, default `0.0.0.0:8080` inside the container |
| `ATLAS_REPORTS_QUOTA_BYTES` | Attachment-directory limit including partial and orphan files, default 2 GiB |

Use HTTPS at the reverse proxy. Plain HTTP origins are accepted only for literal
loopback addresses or `localhost` during local development. The backend port must
not be published to the Internet. Keep the gateway secret in root-readable
deployment configuration, never in this repository, the website bundle or a
browser cookie. Keep it stable across upgrades so existing upload tokens and
idempotency keys continue to work.

With Traefik and Authelia, protect `/admin` and `/api/admin` with Authelia forward
authentication and an access policy limited to the administrator. Strip incoming
identity and gateway headers before authentication, copy only Authelia's verified
`Remote-User`, then inject `X-Atlas-Gateway` on the backend connection. The API also
requires **all three** of the pinned socket peer, gateway secret and allowed user.
Admin changes require the exact origin and the CSRF token from `/api/admin/session`.
The API must never trust a client's supplied `Remote-User` by itself.

For the production Cloudflare deployment, restrict the report and authentication
routers to Cloudflare source networks using the **origin socket address**, not a
client-supplied forwarding header. Only then forward `CF-Connecting-IP`; the
backend uses it after authenticating the proxy. A portable deployment without
Cloudflare must strip this header and append a verified client address to
`X-Forwarded-For`. Neither forwarding header is used from an untrusted peer.
Configure reverse-proxy header/read/idle timeouts, upload limits and resource
limits as well: the application is an additional boundary, not an Internet-facing
TLS or slow-connection server.

The server caps messages at 32 KiB of JSON, 4,000 message characters, 254 contact
characters and 80 version characters. It allows at most 500 new reports daily,
10,000 retained reports, 12 submissions and uploads per client per hour, and
1,000 attempts per action globally per hour. Uploads are streamed with a 64 MiB
limit and a 120-second deadline; JSON bodies have a 15-second deadline. Only two
uploads/ZIP validations and 32 requests run concurrently. Full storage returns a
retryable error rather than dropping an existing report. ZIPs are limited to
2,048 members, 32 MiB per member and 256 MiB expanded overall.

Cleanup runs at startup and hourly. It removes expired rows, attachments,
incomplete submissions and stale temporary files, and recovers orphaned files
from a crash between rename and SQLite commit. SQLite metadata and the bounded
audit trail consume space in addition to the attachment quota; allow disk headroom.

## Public API

`GET /api/v1/info` returns the privacy version, destination, retention and upload
limit. `POST /api/v1/reports` accepts JSON:

```json
{
  "submission_key": "a UUID v4 generated once for this submission",
  "category": "issue",
  "message": "What happened and what was expected?",
  "contact": "",
  "version": "0.6.0-rc.8",
  "has_diagnostics": true,
  "consent": true,
  "privacy_version": "2026-09-30"
}
```

The response contains `id`, `received` and an `upload_token` when diagnostics were
requested. Upload the ZIP with `PUT /api/v1/reports/{id}/diagnostics`, content type
`application/zip` and `Authorization: Bearer <upload_token>`. A successful upload
returns `received: true`. Tokens expire after 24 hours. No public report listing,
attachment download or status lookup is available.

Retry unchanged metadata with the same submission key after a connection failure;
the server returns the same report instead of creating a duplicate. Changing
metadata under the same key returns 409. Retrying an already completed upload is
also safe. Generate a new submission key if the sender edits or starts a new report.

## Administrator API

Authenticated routes are `/api/admin/session`, `/api/admin/reports` and
`/api/admin/reports/{id}`. Listing supports `status` and `offset`, returning up to
50 reports with a total count. Statuses are `new`, `investigating`, `resolved` and
`closed`. `PATCH` saves status and notes; `DELETE` removes the report and attachment.
`GET /api/admin/reports/{id}/diagnostics` returns a ZIP attachment with a generated
filename, never executable page content. Downloads, edits and deletes are audited.
The dashboard must render message/contact/note text as text, not raw HTML.

## Verification and references

Run `cargo test --locked`, `cargo clippy --locked --all-targets -- -D warnings`,
`cargo fmt --check` and `cargo audit`. Tests exercise the API's trust boundary,
CSRF, retries, deletion/retention, malicious archives, upload/metadata limits,
interrupted transfers, quota recovery and client rate identities.

Implementation was checked against the official local sources for
[Axum 0.8.9 body limits](https://github.com/tokio-rs/axum/blob/main/axum-core/src/extract/default_body_limit.rs),
[Authelia v4.39.20 Traefik integration](https://www.authelia.com/integration/proxies/traefik/),
and [zip 8.6.0 EOF/CRC verification](https://github.com/zip-rs/zip2/blob/v8.6.0/src/crc32.rs).
`Cargo.lock` pins the service dependencies. An advisory check does not substitute
for keeping the proxy, identity provider, operating system and container runtime
patched.
