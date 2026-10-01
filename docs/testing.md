# Testing

Automated checks for the Windows PowerShell scripts that run on users' PCs, the Atlas
package and the desktop app, and VM checks for release candidates. Run commands from the
repository root.

The Windows PowerShell tests need Windows PowerShell 5.1; the build tools and build tests
need PowerShell 7. On each, install the CI versions of Pester (5.7.1) and PSScriptAnalyzer
(1.25.0); see `.github/workflows/test.yml` and `lint.yml`. The inbox Pester 3 is too old.

Run unit tests unelevated; they use mocks, temporary files and scratch HKCU keys. Run
install and configuration checks only in a disposable Windows VM, never on a development
host.

Release candidates need the evidence listed in the
[release verification matrix](reliability-verification-matrix.md); rerun the relevant VM and
device checks on the exact package. For upgrades, see [upgrading Atlas](upgrading.md).

## 1. PSScriptAnalyzer

| Profile | Settings (`.github/linters/`) | Scope |
| --- | --- | --- |
| Windows PowerShell | `PSScriptAnalyzerSettings.Payload.psd1` | `playbook/**`, `app/resources/**` (runs on users' PCs under Windows PowerShell 5.1). Adds `PSUseCompatibleSyntax` for 5.1 and 7.4. |
| Strict | `PSScriptAnalyzerSettings.psd1` | `tools/**`, `tests/**`, the app's release and notice tooling and its tests |

```powershell
Get-ChildItem playbook,app/resources -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1

Get-ChildItem tools,tests,app/tools/Build-Release.ps1,app/tools/Export-DependencyNotices.ps1,app/tools/tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

CI fails on any Error or Warning.

## 2. Windows PowerShell 5.1 parse gate

Target machines run Windows PowerShell 5.1. CI parses every `.ps1`, `.psm1` and `.psd1`
under `playbook` and `app/resources` with `[System.Management.Automation.Language.Parser]`
in `powershell.exe` to catch PowerShell 7-only syntax.

## 3. Pester unit tests

Windows PowerShell tests, in Windows PowerShell 5.1 (`powershell.exe -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @(Get-ChildItem tests -Filter '*.Tests.ps1' |
    Where-Object Name -ne 'AtlasBuild.Tests.ps1' |
    Select-Object -ExpandProperty FullName)
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

Build tests, in PowerShell 7 (`pwsh -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @('tests/AtlasBuild.Tests.ps1', 'app/tools/tests')
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

CI uses the same split, so each suite runs once, on its supported host. Both exit nonzero
on failure. For a focused run, narrow `Run.Path` and keep the matching host. Keep
`ErrorActionPreference` at its default: a global `Stop` can intercept native errors that
tests assert on.

The suites cover shared logic and key behavior such as install-state retry, registry
targeting, tweak and toggle execution, process arguments, package selection and
build/archive parity. They make no persistent changes; registry tests create and remove
`HKCU:\Software\AtlasRewriteTest`. When writing tests:

- Prefer focused behavioral tests of shared logic, and of the real points where code starts
  a process, crosses a privilege boundary, saves state or recovers.
- Assert on behavior or data (definitions, plans, manifests), never script text, except
  for exact cross-artifact contracts such as a path a `.reg` file embeds.
- Begin each Windows PowerShell test file's `BeforeAll` with
  `. (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')`, which enforces the host and module
  paths (see its header). Keep shared host setup there.
- Call tooling such as `tools\dev\New-ToggleLaunchers.ps1` through
  `$script:AtlasTestToolsHost` (PowerShell 7).
- Validate toggle definitions as data with `Test-AtlasToggleDefinition`; run companion
  functions through `Invoke-AtlasToggleFunction` with mocked module commands
  (`tests\Atlas.Toggles.Tests.ps1`).
- Test console output by capturing printed lines and scripting answers, as
  `tests\Atlas.ConsolePresentation.Tests.ps1` does for the heading, warning gate, closing
  line and single exit pause against small fixture toggles.

To review console wording before a VM run, `tools\dev\Show-AtlasConsoleDemo.ps1` renders
the vocabulary and four sample flows under Windows PowerShell 5.1 without changing the
machine.

## 4. Apbx smoke verification

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` verifies a built package, including exact
file-path parity with the source ([details](building.md#verifying-a-build)). It is the
strongest end-to-end check short of installing Atlas.

## 5. Generated artifacts

Two PowerShell 7 generators maintain the committed launcher stubs, JSON catalog and
Markdown references. `tests\Atlas.Toggles.Tests.ps1` and `tests\Atlas.Catalog.Tests.ps1`
run them with `-Validate`, so CI fails when a definition changes without regenerating.

```powershell
pwsh tools/dev/New-ToggleLaunchers.ps1 -Validate   # AtlasDesktop and Toolbox .cmd stubs
pwsh tools/dev/Export-AtlasCatalog.ps1 -Validate   # Toggles\catalog.json and docs\catalog
```

Run them without `-Validate` to regenerate.

## 6. Desktop app (Rust)

```
cd app
cargo test
```

`.github/workflows/app.yml` builds `app/` against its lockfile on `windows-latest`, checks
formatting, and runs Clippy (warnings as errors) and `cargo test`, both without features
and with `--features embedded-playbook` (the tester build).

The tests install nothing and change no settings. They cover:

- package version containment and transactional extraction (synthetic `.apbx` files);
- the Windows PowerShell launch, using real `powershell.exe` and stub scripts (option
  arrays, exit codes, non-UTF-8 output, session reattach);
- release ordering and download verification;
- install-flow transitions and locking, and settings persistence and recovery;
- registry and COM adapters (scratch keys under `HKCU:\Software\AtlasOS\AppTests`);
- theme contrast;
- Windows-language negotiation, regional number and date formatting, every catalog under
  `app/i18n`, and every `t!` call against the source catalog (see `app/docs/i18n.md`).

## Lab VM verification

The checks above never apply Atlas configuration. A Hyper-V lab VM covers what only a real
install can: the front door, the TrustedInstaller broker, plan phases, sign-in replay and
the health check. Take the checkpoint after Windows setup, before installing Atlas.

```powershell
pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
    -Credential (Get-Credential) -PlaybookPath "playbook\Atlas Test.apbx"
```

Each run restores the checkpoint, copies the Atlas package in over PowerShell Direct,
installs Atlas unattended through `Scripts\Entry\Install-Atlas.ps1`, reboots and runs
`Scripts\Entry\Test-AtlasHealth.ps1 -Json`. The install log, health report,
`Compare-SystemState` before/after diff and Atlas logs go to `lab-output\`. The script
header lists steps and host requirements.

The run fails if the install exits non-zero, a fresh install reports drift, or the guest
does not come back. Exit codes: 0 verified, 1 install or verification failed, 2 lab setup
failed.

`.github/workflows/integration.yml` runs it on manual dispatch. It needs a prepared
checkpoint and a self-hosted runner labelled `self-hosted`, `windows` and `hyperv`; the
repository provides neither.

| Setting | Kind | Value |
| --- | --- | --- |
| `ATLAS_LAB_VM` | Variable | VM name; the job is skipped when unset |
| `ATLAS_LAB_CHECKPOINT` | Variable | Checkpoint name |
| `ATLAS_LAB_USER` | Variable, optional | Guest administrator (default `Administrator`) |
| `ATLAS_LAB_PASSWORD` | Secret | Guest administrator password |

The lab run does not cover launcher interactions or upgrades from earlier releases; use the
checklist below and the verification matrix.

### Collecting a report from a VM by hand

`tools/dev/Get-AtlasInstallReport.ps1` writes a read-only text report of an installed
machine for bug reports. Copy it to the machine and run it from an elevated Windows
PowerShell prompt as the account that installed Atlas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1
```

The report goes to that user's Desktop as `atlas-install-report-<timestamp>.txt`. Its
drift check runs the installed health check and is the result to rely on; the other
sections add machine context, listed in the script header. A section that fails records
why, and the report still completes.

### Release candidate regression checklist

On a clean Windows checkpoint, install the rebuilt Atlas package with Atlas Manager, and
repeat from the same checkpoint with AME Wizard. Do not reinstall over a build that seeded
every default from `DEFAULT.reg`: those records replay as choices, hiding whether state
records only applied choices. Compare the registry state store with
`C:\Windows\AtlasOS\state.json`, verify PhoneLink, RecentItems and WebSearch are applied
and recorded as disabled, and run the installed health launcher after reboot.

When changing the relevant code, also check:

- **Health:** Open Explorer first. Transient Bags, High Contrast initialization and taskbar
  pin bookkeeping are excluded from verification; persistent declarations and refused
  policy writes are not.
- **Indexing:** Run Disable, Enable and Minimal from the desktop launchers and check
  Indexing Options, also after reboot. Minimal covers AtlasDesktop and Start Menu, not user
  data; Enable covers user documents, not AppData.
- **PCA:** Check PcaSvc and PcaPatchDbTask after the delayed-start interval. The tweak
  disables and stops the service before disabling the task, because starting PcaSvc
  re-enables the task even under the DisablePCA policy.
- **Edge:** Remove Edge but keep WebView2 registration, runtime files and shared updater
  infrastructure. Runtime binaries alone do not prove WebView2 is present.
- **OneDrive:** Cleanup unregisters OneDrive at install and removes files in one attempt
  after the reboot, through a temporary HKCU Run entry (see
  `Scripts\Operations\Remove-OneDriveCurrentUserData.ps1`). Keep the installing user's
  transcripts from before and after reboot. Verify leftovers are gone, nonempty sync folders
  remain, and cleanup does not recur at later sign-ins. Check the user transcript even when
  the aggregate warning log is clean.
- **New user:** Sign in as a new standard user. Expect the setup toast, an Explorer
  refresh, correct taskbar pins, a second refresh from the delayed Search finalizer, then
  the completion toast, with no forced sign-out. Expect one successful setup transcript, and
  none at a later ordinary sign-in. `Scripts\Entry\Initialize-NewUser.ps1` explains the
  refresh ordering.
- **Launchers from a standard account:** Enter administrator credentials when asked;
  user changes must target the initiating account. Test both directions, restore the
  intended defaults, reboot when recommended and check health.
- **Upgrade and reapply:** Recorded choices replay, and `PowerSaving\PreviousPowerSchemeGuid`
  metadata survives without a bogus toggle warning.

For these checks, run the latest [report collector](#collecting-a-report-from-a-vm-by-hand)
with `-RcDiagnostics`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1 -RcDiagnostics
```

This adds Windows Search, PCA task, OneDrive shell-extension, WebView2, local policy and
BITS diagnostics with related events (see the parameter help). It stays read-only: it
reports missing task history and enables neither history nor auditing.

`tools/dev/Start-AtlasPcaTrace.ps1` changes state: it records the starting state, enables
task history, disables only PcaPatchDbTask and prints how to restore the history setting.
Preserve evidence before reinstalling.
