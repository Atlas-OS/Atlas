# Reports service deployment

The Rust API lives in this repository. The Svelte frontend is built separately and
mounted as read-only static files. Diagnostics and SQLite stay in a private data
directory; neither directory is published by the reverse proxy.

## Container

Build the service from `services/reports` with Docker or Podman:

```sh
docker build --tag localhost/atlas-reports:latest .
install -d -m 750 /srv/atlas-reports
install -d -m 700 -o 10001 -g 10001 /srv/atlas-reports/data
install -d -m 755 /srv/atlas-reports/web
```

Copy `compose.yaml` and a completed `store.env` into `/srv/atlas-reports`; make the
environment file root-owned with mode `600`. Generate a gateway secret using
`openssl rand -hex 32`. Never commit it or expose it through the public API.
Copy the frontend's built `dist/` contents into `web/`.

The Compose example assumes an existing internal network named
`atlas_reports_proxy`, with Traefik at `172.30.80.2` and reports at `172.30.80.3`.
Change those addresses together if the subnet is occupied. Expose no reports host
port. Start the service with `docker compose up -d` in `/srv/atlas-reports`.

`atlas-reports.container` is an alternative Quadlet for a Podman-managed host.
Install it under `/etc/containers/systemd` after creating the same network and
configuring that host's proxy. Docker and Podman networks are independent;
switching the existing proxy is a separate migration, not a prerequisite for
deploying reports. Do not run both service definitions against the same SQLite
directory.

## Proxy and authentication

Use HTTPS. Proxy `/admin`, its descendants, and `/api/admin` through Authelia's
`/api/authz/forward-auth` endpoint. Put a `two_factor` rule for the explicit
administrator username before a `deny` rule for everyone else. Extend
`session.cookies` for the reports domain while retaining existing cookie domains.
Public report creation and upload endpoints do not require an account.

Before forwarding any reports request, remove incoming `Remote-User`,
`Remote-Groups`, `Remote-Name`, `Remote-Email`, and `X-Atlas-Gateway`. For protected
routes, copy `Remote-User` only from Authelia's successful authentication response.
Inject the gateway secret after authentication. Public routes inject the same
secret after removing identity headers, allowing the API to trust client address
metadata without trusting a public identity header. The API additionally checks
the exact connecting proxy IP and configured administrator allowlist.

When using Cloudflare, restrict reports and authentication routers to Cloudflare's
published IP ranges using the immediate source address, not an `X-Forwarded-For`
strategy. Then `CF-Connecting-IP` is usable by the authenticated proxy path for
rate limits. Refresh the allowlist when Cloudflare changes its published ranges.
Use a dedicated HTTP-01 ACME resolver for proxied domains; TLS-ALPN challenges
cannot pass through Cloudflare's TLS termination. Keep unrelated certificates and
routers unchanged.

Set the proxy request body limit to 64 MiB, a bounded upload timeout, a small JSON
body limit on other endpoints, and a global concurrency bound. The API separately
enforces attachment limits, per-reporter and global rate limits, archive checks,
storage quota, and expiry. Container logs rotate at 10 MiB, with three files.

## Storage and operations

The default storage quota is 2 GiB and report retention is 90 days. Administrators
can permanently delete a report, its contact details, and its diagnostic archive
from the dashboard. Completed deletion is recorded in the audit table without
keeping the report body. Quotas do not replace monitoring the host's free space.

Before changing proxy or Authelia configuration, save root-only backups. Validate
Compose and Authelia configuration before restarting only those services. Check
the existing application routes after restarting. Keep image tags for rollback;
do not delete the data directory when rolling back the application.

Backups contain private reports: keep them access restricted and apply a retention
policy. A report deleted from live storage can still exist in an older backup.
For a consistent manual backup, briefly stop the reports container, copy the data
directory, and start it again. Avoid copying an active SQLite database without
also coordinating its WAL state.

Validate `/health`, `/api/v1/info`, anonymous suggestion creation, diagnostics
upload, and unauthorized admin access after deployment. Requests with spoofed
identity headers must still go to Authelia or receive a denial. Never relax the
production authentication policy to test the dashboard.

Implementation references: Authelia `v4.39.20` documentation under
`docs/content/integration/proxies/traefik.md`,
`docs/content/configuration/session/introduction.md`, and
`docs/content/configuration/security/access-control.md`; Traefik `v3.7.10`
IPAllowList, ForwardAuth, Headers, Buffering, and ACME configuration; Podman's
`docs/source/markdown/podman-systemd.unit.5.md` Quadlet reference.
