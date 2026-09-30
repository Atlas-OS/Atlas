# Deploy the reports service

The Rust API serves a separately built frontend. Reports, diagnostics and SQLite
stay private; only the frontend directory is served as static files.

## Runtime

From `services/reports`:

```sh
docker build --tag localhost/atlas-reports:latest .
install -d -m 750 /srv/atlas-reports
install -d -m 700 -o 10001 -g 10001 /srv/atlas-reports/data
install -d -m 755 /srv/atlas-reports/web
```

Copy `compose.yaml`, a completed `store.env`, and the frontend's `dist/` contents
into `/srv/atlas-reports` and `web/`. Keep `store.env` root-owned with mode `600`;
generate its gateway secret with `openssl rand -hex 32`. Never commit secrets.
Start with `docker compose up -d` from `/srv/atlas-reports`.
Compose uses the existing proxy on an internal `atlas_reports_proxy` network:
Traefik `172.30.80.2`, reports `172.30.80.3`. Adjust both addresses if necessary.
Publish no host port. UID 10001, read-only root, dropped capabilities, resource
limits and rotating logs are configured in the service definition.

`atlas-reports.container` is an optional Podman Quadlet. It requires a proxy on
the same Podman network; Docker networks are separate. Never run both runtimes
against the same SQLite directory.

## Authentication and proxy

- Protect `/admin` and `/api/admin`, including descendants, with Authelia
  ForwardAuth. Require two-factor authentication for the configured administrator
  allowlist and deny everyone else. Preserve existing authentication domains.
- Strip incoming `Remote-User`, `Remote-Groups`, `Remote-Name`, `Remote-Email` and
  `X-Atlas-Gateway` on every reports route. For admin routes, copy `Remote-User`
  only from successful ForwardAuth. Inject the gateway secret afterward.
- Configure the API with the exact proxy socket IP, gateway secret and administrator
  allowlist. A forwarded username alone must never authorize access.
- Public submissions require no login. `/api/agent/reports` uses independent
  Bearer credentials; browser cookies and forwarded usernames cannot authorize it.
  Preserve `Authorization`, but never log it or put credentials in URLs.
- Agent credentials expire, are revocable and are stored as signatures. Read-only
  is the default. Deletion requires an explicitly issued delete scope and matching
  report confirmation. Keep the client credential in private MCP configuration.

Security keys are domain-specific. On a new authentication hostname, enroll a key
at `/settings/two-factor-authentication` and retain the original portal's key.
Configure notification delivery; never log private filesystem enrollment codes.

Use HTTPS and Full (strict) origin verification. With Cloudflare, allow only its
published IPv4/IPv6 ranges on the reports/authentication routers, checking the
immediate connection address rather than trusting client-supplied forwarded IPs.
Refresh these ranges when they change.

Use a separate HTTP-01 certificate resolver. If validation redirects to HTTPS,
route only `/.well-known/acme-challenge/` on these hosts to `acme-http@internal`,
retaining the source-IP allowlist.

Keep the self-only CSP: disable script/HTML rewriting and automatic Web Analytics
injection for these hosts (`disable_rum: true`). Native clients cannot solve
browser challenges. Exclude these hosts from incompatible custom user-agent or
HTTP/1.1 rules; limit any legacy `securityLevel`/`bic` exemption to `/api/v1/`,
`/api/agent/` and certificate challenges. Retain managed WAF, rate limits and DDoS
protection. Verify with the actual Manager and MCP user agents.

Bound uploads to 64 MiB, timeouts and concurrency at the proxy. The API enforces
archive checks, rate limits, storage quota and expiry.

## Operations

Quota: 2 GiB. Retention: 90 days. Deletion removes live reports and archives,
but older backups may retain them. Monitor host free space.

Back up private data and proxy/authentication configuration with restricted
permissions. For a manual SQLite backup, stop reports briefly, copy its data,
then restart. Keep previous images for rollback; never delete data during rollback.
Validate configuration before restarting only the affected services.

Verify intake, admin sign-in, agent scopes and rejection of spoofed identities.
