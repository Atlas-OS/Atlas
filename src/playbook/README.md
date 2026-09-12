# EBOS Release (AtlasOS Playbook)

EBOS is an enhanced AtlasOS playbook for Windows 11 (24H2/25H2).
Apply it with [AME Wizard](https://docs.atlasos.net/getting-started/installation)
by dropping `EBOS Release.apbx` into the wizard window.

## Build

Self-contained, no external dependencies:

```cmd
build-playbook.cmd
```

This regenerates `Executables\playbook.ico` from `playbook.png`,
injects `<Version>` from `playbook.conf` into all `%%EBOS_VERSION%%`
tokens, and packages everything into `EBOS Release.apbx`
(a ZIP renamed to `.apbx`).

## Layout

| Path | Ships where | Purpose |
|---|---|---|
| `playbook.conf` | apbx root | Playbook metadata, version (single source of truth), supported builds, wizard pages |
| `Configuration/` | apbx only | AME Wizard tasks (`custom.yml`, `tweaks.yml`, `atlas/`, `tweaks/`) |
| `Executables/` | `C:\Windows\` | `AtlasModules/`, `AtlasDesktop/` (post-install folder), setup scripts |
| `Images/` | apbx only | Browser icons for the wizard pages |
| `Build-Playbook.ps1` | apbx root | Builder (called by `build-playbook.cmd`) |

## Image staging (optional, for ISO baking)

```powershell
# Without Windhawk (default, matches the wizard default of unchecked)
.\Executables\Stage-ImageFiles.ps1 -Destination "C:\EBOS"
# With transparent taskbar pre-installed at first boot
.\Executables\Stage-ImageFiles.ps1 -Destination "C:\EBOS" -IncludeWindhawk
```

Then place `SetupComplete.cmd` in `C:\Windows\Setup\Scripts\` of the image.
`SetupComplete.cmd` only auto-installs Windhawk when the staging marker
`include-windhawk.txt` exists; the playbook option installs on demand anyway.

## Versioning

Bump `<Version>` in `playbook.conf` only. Never hardcode the version in
scripts — use the `%%EBOS_VERSION%%` token, which the builder replaces at
package time (it fails the build if a token survives).

## Verify on a deployed machine

Atlas folder → `9. Troubleshooting` → `Verify EBOS Configuration.cmd`
(checks services, policies, power plan, theme, OEM; `-FixIssues` repairs).
