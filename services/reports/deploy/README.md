# Deploy the reports service

How the Atlas team deploys the reports service behind Traefik, Authelia and
Cloudflare. Reports, diagnostics and the SQLite database stay private; only the
website directory is served as static files. Settings, limits and the proxy
requirements are in [the service reference](../API.md).

## Runtime

From `services/reports`:

```sh
docker build --tag localhost/atlas-reports:latest .
install -d -m 750 /srv/atlas-reports
install -d -m 700 -o 10001 -g 10001 /srv/atlas-reports/data
install -d -m 755 /srv/atlas-reports/web
```

1. Copy `compose.yaml` and a completed `store.env` (from `store.env.example`) into
   `/srv/atlas-reports`. Keep `store.env` root-owned with mode `600`, generate its
   gateway secret with `openssl rand -hex 32`, and never commit secrets.
2. Copy the website's `dist/` contents into `/srv/atlas-reports/web`. Deploy
   matching website and service versions together: the service accepts only
   reports that confirm its current privacy notice.
3. Run `docker compose up -d` from `/srv/atlas-reports`.

Compose joins the existing proxy's internal `atlas_reports_proxy` network, with
Traefik at `172.30.80.2` and reports at `172.30.80.3`. For other addresses, set
the reports address in `compose.yaml` and Traefik's as `ATLAS_REPORTS_PROXY_IPS`
in `store.env`. Publish no host port. The container runs as UID 10001 with a
read-only root filesystem, dropped capabilities, resource limits and rotating
logs.

`atlas-reports.container` is an optional Podman Quadlet. It needs a proxy on the
same Podman network, because Docker networks are separate. Never run both runtimes
against the same data directory.

## Authentication and proxy

- Protect `/admin` and `/api/admin`, and every path under them, with Authelia
  ForwardAuth. Require two-factor authentication for the administrator allowlist
  and deny everyone else. Preserve existing authentication domains.
- On every reports route, strip incoming `Remote-User`, `Remote-Groups`,
  `Remote-Name`, `Remote-Email` and `X-Atlas-Gateway`. Copy `Remote-User` only
  from successful ForwardAuth on admin routes.
- Then add `X-Atlas-Gateway` on every route, including `/api/v1/` and
  `/api/agent/`. Public rate limits need it to trust the forwarded client address,
  and agent access requires it.
- Leave `/api/v1/` and `/api/agent/` without sign-in: submissions are public, and
  agents use Bearer credentials. Pass `Authorization` through, but never log it or
  put credentials in URLs.
- Issue agent delete scope only for a specific deletion task, with a short expiry.
  Keep client credentials in private MCP configuration.
- After rotating the gateway secret, revoke the old agent credentials and issue new
  ones. The old ones stop working but still count toward the 20 active.

Security keys are bound to their domain. On a new authentication hostname, enroll
a key at `/settings/two-factor-authentication` and keep the original portal's key.
Configure notification delivery; never log private filesystem enrollment codes.

Use a separate HTTP-01 certificate resolver. If validation redirects to HTTPS,
route only `/.well-known/acme-challenge/` on these hosts to `acme-http@internal`,
keeping the routers' source-IP allowlist.

At the proxy, use HTTPS, limit uploads to 64 MiB, and set timeouts and
concurrency limits. The service still enforces archive checks, rate limits, the
storage quota and expiry.

### Cloudflare

- Set SSL/TLS to Full (strict), so Cloudflare verifies the origin certificate.
- On the reports and authentication routers, allow only Cloudflare's published
  IPv4 and IPv6 ranges, checked against the connecting address rather than a
  forwarded header. Update the ranges when Cloudflare changes them.
- For these hosts, disable script and HTML rewriting and automatic Web Analytics
  injection (`disable_rum: true`), so the service's Content Security Policy keeps
  working.
- Atlas Manager (`AtlasApp/<version>`) and the MCP server
  (`AtlasReportsMCP/<version>`) cannot solve browser challenges. Exclude these
  hosts from custom user-agent or HTTP/1.1 rules that would block them, limit any
  legacy `securityLevel` or `bic` (Browser Integrity Check) exemption to
  `/api/v1/`, `/api/agent/` and certificate challenges, and test with both user
  agents.
- Keep managed WAF rules, rate limiting and DDoS protection. Rate-limit
  `POST /api/v1/reports` here too: the service limits each client address, but
  only the proxy can stop many addresses from filling the daily report cap.

## Operations

- The attachment quota is 2 GiB and retention is 90 days. Monitor free disk space:
  new reports and uploads get 503 when less than 128 MiB is free.
- Back up the data and the proxy and authentication configuration with restricted
  permissions. For a manual backup, stop the reports container briefly, copy
  `/srv/atlas-reports/data`, then start it again.
- Backups keep reports deleted after they were taken. The privacy notice says
  reports are deleted after 90 days, so keep backups for at most 90 days and
  delete older ones.
- Keep previous images for rollback, and never delete data during a rollback.
- Validate configuration before restarting, and restart only the affected services.
- Run `cargo audit` before deploying, and keep the proxy, Authelia, operating
  system and container runtime patched.

After each deployment, check that:

- reports can be sent;
- administrators can sign in;
- agent credentials get only their scopes;
- spoofed `Remote-User` and `X-Atlas-Gateway` headers are rejected.
