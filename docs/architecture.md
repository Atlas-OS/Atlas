# Atlas architecture

Atlas is a Windows optimization playbook applied by [AME Wizard](https://amelabs.net).
This document describes how the repository is laid out and how an install runs.

## Repository layout

```
/
├─ playbook/                 Everything under here — and nothing else — ships in the .apbx
│  ├─ playbook.conf          AME Wizard manifest (metadata, requirements, FeaturePages)
│  ├─ Configuration/         The YAML shim (thin; orchestration only)
│  │  ├─ custom.yml          Entry point: hive lifecycle + phase calls
│  │  ├─ tweaks.yml          Per-category Tweaks phase calls (every tweak is PowerShell)
│  │  └─ atlas/              start / components / appx / default (AME-only actions)
│  └─ Executables/           Payload deployed to C:\Windows (AtlasModules, AtlasDesktop, Themes)
│     └─ AtlasModules/Scripts/
│        ├─ Invoke-AtlasInstall.ps1   Install orchestrator (one call per phase)
│        ├─ Invoke-Toggle.ps1          Toggle CLI (every AtlasDesktop launcher calls it)
│        ├─ Modules/          Atlas.* PowerShell framework (see below)
│        ├─ Phases/           One Invoke-<Phase>Phase.ps1 per install phase
│        ├─ Tweaks/           Declarative tweak data (.psd1) + tweaks.manifest.psd1
│        ├─ Internal/         Shared implementation scripts
│        └─ Tasks/            Pre-payload-copy scripts (run from the extracted playbook)
│     └─ AtlasModules/Toggles/   Per-toggle definitions for the AtlasDesktop user tools
├─ tools/
│  ├─ build/                 AtlasBuild module, Build-Playbook.ps1, Test-Apbx.ps1, Set-AtlasVersion.ps1
│  ├─ dev/                   Install-DevProfile.ps1, New-ToggleLaunchers.ps1, Convert-TweakYaml.ps1, Compare-SystemState.ps1
│  ├─ sxsc/                  SxS component package configs (CABs built by CI)
│  └─ release-zip/           Extra files shipped alongside the .apbx
├─ tests/                    Pester 5 unit tests
└─ docs/                     This documentation
```

**The one rule that keeps the build simple:** everything under `playbook/` ships in the
`.apbx`, and nothing outside it does. The repository tree *is* the shipped payload — there
is no build-time repo-to-archive mapping. `tools/build/Test-Apbx.ps1` enforces exact
source/archive file-path parity as well as the archive root layout.

## The AME Wizard boundary

AME Wizard remains the runtime that installs the playbook: it handles TrustedInstaller
execution, the install UI, the OOBE/ISO integration, and the `.apbx` package format. What
changed in the rewrite is that the YAML layer is now a **thin shim** — almost all logic
lives in PowerShell.

The YAML keeps only what is genuinely AME-specific:

- the default-user-hive `reg load`/`reg unload` bracketing,
- `!writeStatus` progress text,
- `option:` / `onUpgrade:` / `oobe:` / `iso:` gating,
- `weight:` progress hints and `handleExitCodes` halting,
- `!appx` package removals (AME's provisioned/system-package removal is more robust than
  `Remove-AppxPackage`),
- the ISO-only offline-hive Defender key delete.

Everything else is a `!powerShell` call into the framework.

### Option handoff

AME evaluates FeaturePage options in YAML only. Right after the payload is copied,
`custom.yml` writes one flag file per selected option (and `Upgrade.flag` /
`Interactive.flag`) under `C:\Windows\AtlasModules\Flags`. The framework reads them through
`Test-AtlasOption` and `Get-AtlasContext` — so all option/upgrade/OOBE gating collapses
into PowerShell while AME stays the single source of truth for the user's choices.

## Install pipeline

`custom.yml` loads the default-user hive, copies the payload, captures the option flags,
then calls `Invoke-AtlasInstall.ps1 -Phase <Name>` once per phase. Each phase asserts the
privilege it needs and delegates to the framework modules.

| Phase | Privilege | Work |
| --- | --- | --- |
| PreInstall | Administrator | disable notifications, disk cleanup |
| Environment | Administrator | NGEN, PowerShell telemetry opt-out |
| Features | Administrator | DISM features/capabilities (needs online sources) |
| Software | Administrator | utilities, browser, toolbox (option-gated) |
| Services | TrustedInstaller | service backup + hardening |
| Components | TrustedInstaller | Edge/OneDrive removal, CBS packages |
| AppxSupport | Administrator | AppX snapshot / deprovision / cache clear |
| Defaults | Administrator | DEFAULT.reg (fresh) / toggle re-apply (upgrade) |
| Revert | TrustedInstaller | StoreFixer (upgrade-only) |
| Tweaks | TrustedInstaller | one call per category (see below) |
| Finalize | Administrator | default-user-hive sync, registry path fixup |

**Exit code contract** (consumed by AME `handleExitCodes`): `0` success, `1` fatal, `2`
wrong privilege, `3` unsupported environment. Each phase writes a transcript plus a shared
log under `C:\Windows\AtlasModules\Logs\install`.

[AME 0.8.4 launches playbook PowerShell actions](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/blob/f325e9d950e6b37003a46c786fd1b6c20f3180dd/TrustedUninstaller.Shared/Actions/PowershellAction.cs#L91-L96)
with a process-scoped execution-policy bypass, and AtlasDesktop launchers specify their own
process policy. Microsoft documents that
[`powershell.exe -ExecutionPolicy` affects only the current session](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1#-executionpolicy-executionpolicy)
and does not change the registry policy. Atlas therefore preserves the machine's existing
Windows PowerShell execution policy instead of replacing an administrator's configuration
during installation.

## PowerShell framework (`Modules/Atlas.*`)

| Module | Responsibility |
| --- | --- |
| **Atlas.Core** | install context, option flags, logging, privilege checks, TrustedInstaller relaunch, shared UI helpers |
| **Atlas.Registry** | registry value/key/hive operations; HKCU redirection + default-hive mirroring |
| **Atlas.Tweaks** | loads and applies declarative `.psd1` tweaks; schema validation |
| **Atlas.Services** | service startup changes, service backup |
| **Atlas.Appx** | AppX snapshot/deprovision/cache-clear |
| **Atlas.TasksProcs** | scheduled task and process helpers |
| **Atlas.Software** | software/browser installs, CBS packages, OneDrive removal |
| **Atlas.Toggles** | the AtlasDesktop toggle engine and upgrade re-apply |
| **Atlas.Shortcuts / Atlas.Themes** | shortcut creation and theme application |

`Atlas.Core` also provides `Invoke-AtlasAsUser`, the inverse of the vendored `RunAsTI.cmd`:
from a SYSTEM/TrustedInstaller phase it grabs the active console session's token
(`WTSQueryUserToken`) and runs a process as the interactive user on the interactive desktop
(`CreateProcessAsUser`) — the same technique AME Wizard's backend uses for
`runas: currentUser`. Tweaks that must touch the running shell (theme apply, pin-to-Home)
set `RunAs = 'User'` / `'UserElevated'` and the engine bounces their companion script
through it.

### The HKCU redirection rule

When the install runs as SYSTEM/TrustedInstaller, ambient `HKCU:` points at the SYSTEM
profile, not the user. `Atlas.Registry` resolves `HKCU\...` paths to the interactive user's
hive (`HKU\<SID>`) and mirrors each write into the loaded default-user hive
(`HKU\AME_UserHive_Default`) so new accounts inherit the tweak. Mirrored paths are recorded
and replayed by `Sync-AtlasDefaultUserHive` in the Finalize phase. Tweak authors always
write plain `HKCU\...` and let the engine resolve it — this replaces the old
`APPLYDUHIVE.ps1`, which scraped the YAML for HKCU paths.

## Tweaks

Each tweak is a data-only `.psd1` under `Scripts/Tweaks/<category>` (see
[`Scripts/Tweaks/README.md`](../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md)
for the schema). `tweaks.manifest.psd1` defines category order and per-tweak enable/disable
— commenting out a manifest line disables a tweak, mirroring the old "comment out the
`!task` include" workflow. The Tweaks phase applies one category per call.

Every tweak is now a `.psd1` — `tweaks.yml` contains no `!task` includes. Tweaks that need
the interactive user (theme/lock-screen and pin-to-Home COM) use the `RunAs` key described
above rather than an AME `runas` YAML action.

## AtlasDesktop toggles

The numbered AtlasDesktop folders are the user-facing post-install toggles. Each toggle is
a definition under `AtlasModules/Toggles/<Group>/<Name>.ps1`; a tiny generated `.cmd`
launcher (one per action, with the original display filename) calls `Invoke-Toggle.ps1`,
which dispatches to `Atlas.Toggles`. `tools/dev/New-ToggleLaunchers.ps1` generates the
launchers and validates that none have drifted from their definition.

Toggle state is recorded in `HKLM\SOFTWARE\AtlasOS\Services\<Name>` (`state` DWORD + `path`
REG_SZ) — the schema is frozen so upgrades re-apply the user's previous choices via
`Invoke-AtlasToggleReapply`.

## Packaging

The `.apbx` is a renamed, password-protected ZIP (password `malte`, so antivirus engines
do not scan-flag the payload). `tools/build/AtlasBuild` builds it with 7-Zip/NanaZip and
applies dev-build staging overrides (`-Removals`, `-AddLiveLog`). The SxS component CAB
packages in `tools/sxsc` are built by CI from an external pinned builder and committed back
to `playbook/Executables/AtlasModules/Packages`; their versions are independent of the
playbook version.

See [building.md](building.md) and [testing.md](testing.md) for the workflows.
