<h1 align="center">
  <a href="https://ebos.net" target="_blank"><img src="images/github-banner.png" alt="EBOS" width="800"></a>
</h1>
  <p align="center">
    <a href="https://github.com/EBOS/EBOS/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/ebos-os/ebos?style=for-the-badge&logo=github&color=1A91FF"/></a>
    <a href="https://github.com/EBOS/EBOS/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/ebos-os/ebos?style=for-the-badge&color=1A91FF" /></a>
    <a href="https://github.com/EBOS/EBOS/releases/latest"><img alt="Release" src="https://img.shields.io/github/release/ebos-os/ebos?style=for-the-badge&color=1A91FF" /></a>
  </p>

<p align="center"><b>EBOS — Unified Windows Performance, Gaming, Privacy, Security & Liquid Glass Desktop Experience</b></p>

<p align="center">
  <a href="https://ebos.net" target="_blank">🌐 Website</a>
  •
  <a href="docs/DOCUMENTATION.md">📚 Documentation</a>
  •
  <a href="docs/INSTALLATION.md">🚀 Installation</a>
  •
  <a href="docs/TASKBAR.md">🎛️ Taskbar</a>
  •
  <a href="docs/LIQUID-GLASS.md">💎 Liquid Glass</a>
</p>

## What is EBOS?

EBOS is an open-source platform that enhances Windows through a single
[AME Wizard](https://amelabs.net) playbook: performance and gaming
optimizations, privacy controls, security-aware configuration, a
Windows 11 taskbar experience and the **Liquid Glass** design system —
all hardware-aware, validated and reversible wherever technically
possible.

EBOS **unifies two legacy projects** (their functionality, not their
identities — see [attribution](docs/ATTRIBUTION.md)) into one coherent
system with a single Core, a single service list and a single design
language.

```
                     ┌─────────────────────────────┐
                     │        EBOS Core            │
                     │ detect · backup · validate  │
                     └──────────────┬──────────────┘
        ┌────────┬────────┬────────┼────────┬────────┬────────┐
        ▼        ▼        ▼        ▼        ▼        ▼        ▼
     Windows  Privacy  Security  Optimize  Gaming  Network     UI
        └────────┴────────┴────────┴────────┴────────┴───┬────┘
                                                          ▼
                                          Windows 11 Taskbar + Liquid Glass
```

## Highlights

- **🔒 Privacy** — telemetry, diagnostics, advertising and tracking
  disabled while sign-in, Store and updates keep working
- **📈 Performance** — meaningful optimizations only; no placebo
- **🎮 Gaming** — Game Mode, input tuning, opt-in HAGS, gaming profiles
- **🛡️ Security-aware** — security trade-offs are explicit, documented
  and reversible
- **💎 Liquid Glass** — token-driven translucent material system with
  GPU/battery/accessibility-aware quality tiers
- **🎛️ Windows 11 taskbar** — alignment, size, multi-monitor, glass
  materials, Explorer recovery loop
- **↩️ Recovery** — pre-change backups, restore points, per-action
  undo, 17-check validation
- **✅ Transparent** — plain-text playbook, hashed open-source binaries,
  CI validation of every change

## Documentation

| Doc | Contents |
|---|---|
| [INSTALLATION](docs/INSTALLATION.md) | Requirements, steps, ISO mode |
| [FEATURES](docs/FEATURES.md) | Complete feature map + what the merge consolidated |
| [OPTIMIZATION](docs/OPTIMIZATION.md) | Risk classes, hardware-aware engine, per-area details |
| [SECURITY](docs/SECURITY.md) | Preserved vs opt-in security options |
| [PRIVACY](docs/PRIVACY.md) | What is disabled and what keeps working |
| [TASKBAR](docs/TASKBAR.md) | The EBOS taskbar experience |
| [LIQUID-GLASS](docs/LIQUID-GLASS.md) | Materials, tiers, fallbacks |
| [RECOVERY](docs/RECOVERY.md) | Backups, rollback, validation |
| [TROUBLESHOOTING](docs/TROUBLESHOOTING.md) | Common issues & fixes |
| [Design system](docs/design-system/README.md) | Tokens, materials, components |
| [ATTRIBUTION](docs/ATTRIBUTION.md) | Licenses & third-party components |
| [CHANGELOG](docs/CHANGELOG.md) | Release history |

## Quick start (after install)

Open the **EBOS** folder on the Desktop → **0. EBOS Core**:

```text
EBOS Dashboard        interactive control center
System Report         hardware + compatibility report
Validate System Health   17-check [PASS]/[FAIL] report
Create EBOS Backup    timestamped backup + restore point
EBOS Rollback         backups / undo change-sets / restore points
Configure Taskbar     alignment · size · multi-monitor · reset
Liquid Glass Quality  auto or manual material tier
Apply Profile         balanced · performance · gaming · competitive ·
                      productivity · privacy · minimal · custom
```

Or from PowerShell:

```powershell
$env:Path += ";$env:WINDIR\EBOSModules\Core"
EBOS-Dashboard.ps1
```

## Repository structure

```
src/playbook/
├── Configuration/
│   ├── custom.yml      # entry point — the unified pipeline
│   ├── core/           # detection · backup · validation
│   ├── windows/        # packages · components · services · updates · debloat
│   ├── privacy/  security/  optimization/  gaming/  network/
│   ├── ui/             # explorer · taskbar · start · shell · liquid-glass
│   ├── recovery/       # backups · winre · legacy reverts
│   └── misc/  scripts/
├── Executables/
│   ├── EBOSModules/Core/   # EBOS Core engine (PS)
│   ├── EBOSDesktop/        # the user-facing EBOS folder
│   └── ...
└── playbook.conf
docs/                    documentation + design system
tools/validate/          repository validator (CI-enforced)
```

## Development

```bash
python3 tools/validate/validate-ebos.py   # must pass before every PR
src/playbook/build-playbook.cmd           # local playbook build (Windows)
```

See [CONTRIBUTING](.github/CONTRIBUTING.md).

> [!WARNING]
> Component removal (Windows features/packages) is intended for a
> **fresh Windows installation only**. Applying it to an existing,
> in-use system can cause irreversible damage.

## License

[CC BY-SA 4.0](LICENSE). EBOS does not redistribute a modified Windows
ISO and does not alter activation — see [attribution](docs/ATTRIBUTION.md)
for the integrated third-party components and their licenses.
