# EBOS Privacy Guide

EBOS removes the majority of Windows telemetry while keeping normal
functionality (login, Store, updates) working.

## What is disabled

- **Diagnostic data** — set to required minimum via policy
  (`AllowTelemetry` = security level on supported editions)
- **CEIP / SQM** — off
- **Activity history & timeline** — off, no upload
- **Advertising ID** — off
- **Tailored experiences / suggestions** — off
- **Speech** — online speech recognition off; local recognition intact
- **Inking & typing personalization** — off (native implementation:
  `RestrictImplicitInkCollection`, `RestrictImplicitTextCollection`)
- **Location** — off by default (toggle in EBOS folder)
- **Recall snapshots** — disabled
- **Input/dotNET/PowerShell CLI telemetry** — opted out
- **App telemetry** — NVIDIA telemetry disabled; Office telemetry disabled
- **Cloud sync of settings/messages** — disabled
- **Windows Media Player telemetry / usage tracking** — off
- **Hosts filter** — well-known Microsoft telemetry endpoints filtered;
  login/Store/update endpoints are **not** touched

## What keeps working

Microsoft account sign-in · Microsoft Store · Windows Update (manual or
automatic, your choice) · Windows Search (web search configurable) ·
Xbox sign-in (if Xbox apps kept)

## Scope limits

EBOS controls Windows only. Browsers and third-party apps have their
own telemetry — consider privacy-respecting browsers (Brave/LibreWolf
installers are offered).

## Verification

Run `EBOS-Validate.ps1` — the report includes the state of
telemetry-related services (`DiagTrack` disabled, etc.).
