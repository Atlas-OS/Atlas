# Deploy the reports service

This guide is for operators who run the reports service in production behind Traefik and Authelia, optionally with Cloudflare in front.
Reports, diagnostics and the SQLite database stay private, and only the website directory is served as static files.
The [service reference](../API.md) lists the settings, limits and proxy requirements.

## Prerequisites

- A Linux host with Docker Engine and the Docker Compose plugin.
- Traefik on the Docker network `atlas_reports_proxy`.
  `compose.yaml` declares that network as external, so create it before the first start, with a subnet that holds both fixed addresses:

  ```sh
  docker network create --subnet 172.30.80.0/24 atlas_reports_proxy
  ```

  Attach Traefik to it at `172.30.80.2`; the reports container takes `172.30.80.3`.
  To use other addresses, set the reports address in `compose.yaml` and Traefik's address as `ATLAS_REPORTS_PROXY_IPS` in `store.env`.
- Authelia, set up as Traefik's ForwardAuth middleware with two-factor authentication.
- The built reports website: the static files its build produces.
  Its source is kept outside this repository.
- OpenSSL, to generate the gateway secret.

## Install

1. From `services/reports`, build the image and give it a tag that identifies the build, such as the commit:

   ```sh
   docker build --tag localhost/atlas-reports:<tag> .
   ```

2. Create the deployment directories:

   ```sh
   install -d -m 750 /srv/atlas-reports
   install -d -m 700 -o 10001 -g 10001 /srv/atlas-reports/data
   install -d -m 755 /srv/atlas-reports/web
   ```

3. Copy `deploy/compose.yaml` into `/srv/atlas-reports`.
4. Create `/srv/atlas-reports/.env` with one line that names the image from step 1:

   ```text
   ATLAS_REPORTS_IMAGE=localhost/atlas-reports:<tag>
   ```

5. Copy `deploy/store.env.example` to `/srv/atlas-reports/store.env` and fill it in.
   Set `ATLAS_REPORTS_ADMINS` to the reviewers' Authelia usernames, and generate the gateway secret with `openssl rand -hex 32`.
6. Make `store.env` readable only by root:

   ```sh
   chown root:root /srv/atlas-reports/store.env
   chmod 600 /srv/atlas-reports/store.env
   ```

7. Copy the website's built files into `/srv/atlas-reports/web`.
   Use the website build that matches this service: the service accepts only reports that confirm its current privacy notice.
8. Configure Traefik and Authelia as described in [Authentication and proxy](#authentication-and-proxy).
9. Start the service from `/srv/atlas-reports`:

   ```sh
   docker compose up -d
   ```

10. Run the checks in [Check a deployment](#check-a-deployment).

Keep secrets out of Git.
`deploy/.gitignore` ignores `store.env` and `.env` in case you fill them in inside the repository.

### Image and container

`compose.yaml` runs the image named by `ATLAS_REPORTS_IMAGE`, or `localhost/atlas-reports:latest` when it's unset.
Compose reads the variable from the shell or from the `.env` file beside `compose.yaml`; the container itself doesn't receive it.

The container runs as UID 10001 with a read-only root filesystem, dropped capabilities, resource limits and rotating logs.
It publishes no host port, so only Traefik reaches it, over `atlas_reports_proxy`.

`atlas-reports.container` is an optional Podman Quadlet for hosts that run Podman instead of Docker.
It names its image on the `Image=` line and doesn't read `ATLAS_REPORTS_IMAGE`.
It needs a proxy on the same Podman network, because Docker networks are separate.
Never run both runtimes against the same data directory.

## Update

1. Back up the data directory, as described in [Operations](#operations).
2. From `services/reports`, build the new image with a new tag:

   ```sh
   docker build --tag localhost/atlas-reports:<tag> .
   ```

3. Replace the contents of `/srv/atlas-reports/web` with the website build that matches the new image.
4. Set `ATLAS_REPORTS_IMAGE` in `/srv/atlas-reports/.env` to the new tag.
5. From `/srv/atlas-reports`, run `docker compose up -d`.
   Compose replaces the container and keeps the data directory.
6. Run the checks in [Check a deployment](#check-a-deployment).

Keep the previous image and website build until you're sure you won't roll back.

## Roll back

1. Set `ATLAS_REPORTS_IMAGE` in `/srv/atlas-reports/.env` back to the previous tag.
2. Put back the website build that matches the previous image.
3. From `/srv/atlas-reports`, run `docker compose up -d`.
4. Run the checks in [Check a deployment](#check-a-deployment).

Leave the data directory in place: a rollback never deletes data.
If the previous image doesn't start, read the reason with `docker compose logs reports`.
Restore the backup from the update only as a last resort, because it loses reports received since.

## Authentication and proxy

- Protect `/admin` and `/api/admin`, and every path under them, with Authelia ForwardAuth.
  Require two-factor authentication for the reviewers in `ATLAS_REPORTS_ADMINS`, and deny everyone else.
- If Authelia already protects other sites, add the reports host to its session cookie domains and access control rules alongside the existing entries.
  Replacing those entries breaks sign-in for the other sites.
- On every reports route, strip incoming `Remote-User`, `Remote-Groups`, `Remote-Name`, `Remote-Email` and `X-Atlas-Gateway`.
  Copy `Remote-User` only from successful ForwardAuth on admin routes.
- Then add `X-Atlas-Gateway` on every route, including `/api/v1/` and `/api/agent/`.
  Public rate limits need it to trust the forwarded client address, and agent access requires it.
- Leave `/api/v1/` and `/api/agent/` without sign-in, because submissions are public and agents use access keys.
  Pass `Authorization` through, but don't log it or put access keys in URLs.
- Give an access key the delete permission only for a specific deletion task, with a short expiry.
  Keep access keys in private MCP client configuration.
- After rotating the gateway secret, revoke the old access keys and issue new ones.
  The old ones stop working but still count toward the 20 active.

Security keys are bound to the domain they were enrolled on.
If the Authelia portal for the reports host is on a hostname where reviewers have no key yet, each reviewer enrols one at `/settings/two-factor-authentication` on that portal.
Keys enrolled on other portals still work there, so leave them in place.

Configure an Authelia notifier that delivers enrolment codes to reviewers, such as email.
Authelia's filesystem notifier writes codes to a file on the server; if you use it, keep that file private and out of logs.

If Traefik issues certificates through the HTTP-01 challenge and HTTP requests are redirected to HTTPS, route only `/.well-known/acme-challenge/` on these hosts to `acme-http@internal`.
Keep the routers' source-IP allowlist on that route.

At the proxy, use HTTPS, limit uploads to 64 MiB, and set timeouts and concurrency limits.
The service still enforces archive checks, rate limits, the storage quota and expiry.

### Cloudflare

If Cloudflare is in front of Traefik:

- Set SSL/TLS to Full (strict), so Cloudflare verifies the origin certificate.
- On the reports and authentication routers, allow only Cloudflare's published IPv4 and IPv6 ranges, checked against the connecting address rather than a forwarded header.
  Update the ranges when Cloudflare changes them.
- For these hosts, turn off script and HTML rewriting and automatic Web Analytics injection (`disable_rum: true`), so the service's Content Security Policy keeps working.
- Atlas Manager (`AtlasApp/<version>`) and the MCP server (`AtlasReportsMCP/<version>`) can't solve browser challenges.
  Exclude these hosts from custom user-agent or HTTP/1.1 rules that would block them, and test with both user agents.
- Limit any legacy `securityLevel` or `bic` (Browser Integrity Check) exemption to `/api/v1/`, `/api/agent/` and certificate challenges.
- Exempt only `PUT /api/v1/reports/{id}/diagnostics` requests carrying a Bearer upload token and `Content-Type: application/zip` from managed WAF and bot challenges.
  Binary archives can trigger the WAF's body-size anomaly rule, and the service verifies upload tokens, archive contents and size limits itself.
- Keep managed WAF rules on other routes, rate limiting and DDoS protection.
- Rate-limit `POST /api/v1/reports` at Cloudflare as well.
  The service limits each client address, but only the proxy can stop many addresses from filling the daily report cap.

## Operations

- The example `store.env` sets the attachment quota to 2 GiB.
  Monitor free disk space: new reports and uploads get 503 when less than 128 MiB is free.
- Back up the data and the proxy and authentication configuration with restricted permissions.
  For a manual backup, stop the reports container briefly with `docker compose stop reports`, copy `/srv/atlas-reports/data`, then start it again with `docker compose start reports`.
- Backups keep reports that were deleted after the backup was taken.
  The privacy notice covers every copy, so delete each backup before it's older than the [retention period](../API.md#data-and-privacy).
- Validate configuration before restarting, and restart only the affected services.
- Run `cargo audit` before deploying, and keep the proxy, Authelia, operating system and container runtime patched.

## Check a deployment

After each install, update or rollback, check these in order:

1. Reports can be sent, with and without diagnostics.
2. Reviewers can sign in to `/admin` with two-factor authentication.
3. Access keys get only their scopes: a key without the delete permission gets 403 when it deletes.
4. Requests with spoofed `Remote-User` and `X-Atlas-Gateway` headers are rejected.
