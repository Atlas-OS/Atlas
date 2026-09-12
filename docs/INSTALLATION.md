# EBOS Installation

EBOS is applied through [AME Wizard](https://amelabs.net) using the EBOS
Playbook (an `.apbx` file). It does **not** redistribute a modified
Windows ISO and does not alter Windows activation.

## Requirements

- Windows 11 24H2 (build **26100**) or 25H2 (build **26200**)
  - Unsupported builds are detected by EBOS Core and unsupported tweaks
    are **skipped**, never forced
- Administrator account
- Working internet connection (browsers/utilities are downloaded)
- No pending Windows updates, no other antivirus, Defender enabled
  before starting (EBOS can disable it afterwards)
- Plugged in (laptops)

> [!WARNING]
> Component removal (Windows features/packages) is intended for a
> **fresh Windows installation only**. Applying it to an in-use system
> can cause irreversible damage.

## Steps

1. Download the latest EBOS Playbook from
   [releases](https://github.com/EBOS/EBOS/releases/latest).
2. Launch `AME Wizard.exe`.
3. Drag the `.apbx` file onto AME Wizard (the archive password is
   handled automatically).
4. Follow the installer pages:
   - **Security choices** — Defender, CPU mitigations, automatic updates
     (all reversible from the EBOS folder later)
   - **Optional removals** — Edge, OneDrive, Teams, Xbox, Photos, …
   - **Appearance** — EBOS wallpaper, dark mode, classic context menu,
     transparency (Liquid Glass opaque fallback)
   - **Performance** — hibernation, automatic maintenance,
     hardware-accelerated GPU scheduling
5. Wait for the playbook to finish and reboot when prompted.

## After installation

Open the `EBOS` folder on the Desktop:

- **0. EBOS Core** — dashboard, system report, validation, backups,
  rollback, taskbar & Liquid Glass configuration, profiles
- **1–9** — software, drivers, general configuration, interface tweaks,
  settings, advanced configuration, security, tools, troubleshooting

## ISO mode

The playbook also supports injection into Windows installation media
(`SupportsISO`). See the AME Wizard documentation for ISO creation.
