# Testing

The checks below cover the PowerShell payload, packaging and desktop app. Run local
checks from the repository root unless a command says otherwise. Payload tests require
Windows PowerShell 5.1; build tooling and generators require PowerShell 7.

Use unelevated shells for unit tests. They use mocks, temporary files and scratch
HKCU keys; never run configuration actions on a development host. Installation and
interactive configuration checks belong in a disposable Windows VM.

The [release verification matrix](reliability-verification-matrix.md) separates
historical reports from the evidence required for a release candidate. Rerun the
relevant VM and device checks against the exact package being released.

For upgrade behavior, preservation rules and migration limits, see [upgrading Atlas](upgrading.md).

## 1. PSScriptAnalyzer

Two profiles under `.github/linters`:

- **Payload** (`PSScriptAnalyzerSettings.Payload.psd1`) for `playbook/**` and `app/resources/**` — the code that
  ships and runs under Windows PowerShell 5.1. Adds `PSUseCompatibleSyntax` targeting 5.1
  and 7.4.
- **Strict** (`PSScriptAnalyzerSettings.psd1`) for `tools/**`, `tests/**`, and the
  app's release/notice tooling and its fixtures.

```powershell
Get-ChildItem playbook,app/resources -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1

Get-ChildItem tools,tests,app/tools/Build-Release.ps1,app/tools/Export-DependencyNotices.ps1,app/tools/tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

CI fails on any Error or Warning.

## 2. Windows PowerShell 5.1 parse gate

The payload must parse under Windows PowerShell 5.1 (what target machines run), so CI
parses every payload `.ps1`, `.psm1` and `.psd1` with `[System.Management.Automation.Language.Parser]` under
`powershell.exe`. This catches pwsh-7-only syntax before it ships.

## 3. Pester unit tests

Pester 5 tests under `tests/` cover shared pure logic and important behavior boundaries:
install-state retry, registry targeting, tweak/toggle execution, process argument handling,
package selection, and build/archive parity. They run unelevated and never make persistent
machine changes; registry tests use and remove a scratch key under
`HKCU:\Software\AtlasRewriteTest`.

Prefer focused behavioral tests for shared logic and real process, privilege, persistence,
or recovery boundaries. Tests assert on behavior or on data (definitions, plans,
manifests), never on the text of a script; the one exception is an exact cross-artifact
contract, such as a path that a `.reg` file must embed. Toggle definitions are validated
as data by `Test-AtlasToggleDefinition`, and companion functions are exercised through the
engine's `Invoke-AtlasToggleFunction` with mocked module commands (see
`tests\Atlas.Toggles.Tests.ps1`).

The console vocabulary is tested the same way: `tests\Atlas.ConsolePresentation.Tests.ps1`
captures the lines the helpers print and scripts the answers they read, and checks the
engine's heading, warning gate, closing line and single exit pause against small
fixture toggles. `tools\dev\Show-AtlasConsoleDemo.ps1` renders the vocabulary and four
representative flows (a simple toggle, a multi-question flow, a failure, a manual
Settings hand-over) under Windows PowerShell 5.1 without touching the machine; use it to
review wording changes before a VM run.

CI runs the runtime and payload suites under Windows PowerShell 5.1 (`powershell`),
the host they actually ship to. `AtlasBuild.Tests.ps1` and `app/tools/tests` run separately under PowerShell 7
(`pwsh`), which the build tooling requires. This covers each surface on its supported host
without running every payload test twice.

Payload test files should start their `BeforeAll` with
`. (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')`. That shared file refuses to run on
anything but Windows PowerShell 5.1 and pins module resolution to the inbox module root,
the payload module tree and Pester, mirroring `Scripts\Initialize-AtlasPowerShell.ps1`.
Keep common host setup there. Repository tooling such as
`tools\dev\New-ToggleLaunchers.ps1` is invoked through `$script:AtlasTestToolsHost`
(PowerShell 7) when a test needs it.

Run the payload suite in **Windows PowerShell 5.1** (`powershell.exe -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @(Get-ChildItem tests -Filter '*.Tests.ps1' |
    Where-Object Name -ne 'AtlasBuild.Tests.ps1' |
    Select-Object -ExpandProperty FullName)
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

Run build tests separately in **PowerShell 7** (`pwsh -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @('tests/AtlasBuild.Tests.ps1', 'app/tools/tests')
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

These commands exit their test shell with a nonzero code on failure. For a focused run,
set `Run.Path` to the relevant test files in the appropriate host. Keep the outer
`ErrorActionPreference` at its normal value; native-error tests exercise failures that
a global `Stop` preference can intercept before their assertions.

CI uses Pester 5.7.1 and PSScriptAnalyzer 1.25.0. Install those versions for each host
that needs them (see `.github/workflows/test.yml` and `lint.yml`); the inbox Pester 3
is insufficient.

## 4. Apbx smoke verification

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` structurally verifies a built package and
requires exact source/archive file-path parity (see [building.md](building.md)). It is the
strongest end-to-end signal available without applying the playbook to a live Windows
install.

## 5. Generated artifacts

Two generators maintain the committed launcher stubs, JSON catalog and Markdown
references. These artifacts must stay in sync with the definitions. Both generators
run under PowerShell 7 and are invoked by the Pester
suites (`tests\Atlas.Toggles.Tests.ps1`, `tests\Atlas.Catalog.Tests.ps1`), so CI fails
when a definition changes without regenerating:

```powershell
pwsh tools/dev/New-ToggleLaunchers.ps1 -Validate   # AtlasDesktop and Toolbox .cmd stubs
pwsh tools/dev/Export-AtlasCatalog.ps1 -Validate   # Toggles\catalog.json and docs\catalog
```

Run them without `-Validate` to regenerate.

## 6. Desktop app (Rust)

`.github/workflows/app.yml` builds the GPUI app under `app/` against its lockfile, checks
formatting, runs Clippy with warnings as errors, and runs `cargo test` on `windows-latest`.
The unit tests cover the boundaries the app owns: package version containment and
transactional extraction (synthetic `.apbx` packages in a temporary directory), the
Rust-to-Windows-PowerShell launch (real `powershell.exe` against harmless stub scripts:
option arrays, exit codes, non-UTF-8 output, session reattach), release-version ordering
and download verification, install-flow transitions and locking, settings persistence and
recovery, registry and COM adapters (a scratch key under `HKCU:\Software\AtlasOS\AppTests`),
theme contrast, and the language layer: Windows-language negotiation (including the
Chinese-script and regional-overlay cases), regional number and date formatting through
Windows, and every message catalog under `app/i18n` (syntax, completeness, variables,
plural categories, and a scan of every `t!` call in the code against the source catalog;
see `app/docs/i18n.md`). Nothing is installed and no machine setting changes.

```
cd app
cargo test
```

## Lab VM verification

The checks above do not apply Atlas configuration. The behaviour that only a real install
can prove (the front door, the TrustedInstaller broker, the plan phases, sign-in replay
and the health check) runs on a Hyper-V lab VM:

```powershell
pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
    -Credential (Get-Credential) -PlaybookPath "playbook\Atlas Test.apbx"
```

One run restores the checkpoint, copies the extracted playbook into the guest over
PowerShell Direct, takes a `Compare-SystemState` baseline, installs Atlas unattended
through `Scripts\Entry\Install-Atlas.ps1`, reboots, runs
`Scripts\Entry\Test-AtlasHealth.ps1 -Json`, takes a second state dump and collects the
install log, the health report, the state diff and the Atlas logs into `lab-output\`. The
run fails when the install exits non-zero or the health check reports drift immediately
after a fresh install.

### Collecting a report from a VM by hand

`tools/dev/Get-AtlasInstallReport.ps1` collects one text file describing an installed
machine, for attaching to a bug report. Copy it to the machine and run it from an
elevated Windows PowerShell prompt as the account that installed Atlas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1
```

It writes `atlas-install-report-<timestamp>.txt` to that user's Desktop and changes
nothing. The authoritative section is the drift check, which runs the shipped health
check. The rest is context the drift check cannot cover: the install state document and
transaction, Edge, Defender, the Atlas CBS packages, services and their startup types,
installed applications and AppX packages, scheduled tasks, startup entries, event log
errors since the install, and the tail of the Atlas logs. Each section is independent, so
a section that cannot be collected records why and the report still completes.

`.github/workflows/integration.yml` runs the same script from a self-hosted runner with
the labels `self-hosted`, `windows` and `hyperv`, configured through the repository
variables `ATLAS_LAB_VM`, `ATLAS_LAB_CHECKPOINT`, optional `ATLAS_LAB_USER` and the
secret `ATLAS_LAB_PASSWORD`. The job is skipped when `ATLAS_LAB_VM` is unset; the checkpoint, credential and runner
must also be configured before it can succeed. No runner machine is provided by the
repository. The lab runner does not automate launcher interactions or upgrades from
previous releases; use the checklist below and the verification matrix for that coverage.

### RC regression checklist

Use a clean Windows checkpoint and import the rebuilt APBX into AME for fresh-install
coverage. Reapplying over a build that seeded every default in `DEFAULT.reg` cannot
establish the new applied-choice state contract. Compare the registry state store with
`C:\Windows\AtlasOS\state.json`, verify PhoneLink, RecentItems and WebSearch are applied
and recorded as disabled, and run the installed health launcher after reboot.

Exercise these boundaries when changing the relevant code:

- Open Explorer before checking health. Transient Bags, High Contrast initialization
  and taskbar pin bookkeeping have explicit verification exclusions; persistent
  declarations and refused policy writes must still be checked.
- Run indexing Disable, Enable and Minimal through the desktop launchers. In Indexing
  Options, verify Minimal includes AtlasDesktop and Start Menu, excluding user data;
  Enable includes user documents but excludes AppData. Check again after reboot.
- Check both PcaSvc and PcaPatchDbTask beyond the delayed-start interval. The PCA tweak
  disables and stops the service before disabling the task. Starting PcaSvc reproduced
  task re-enablement in the RC investigation; DisablePCA policy alone did not prevent it.
- Remove Edge while retaining WebView2 registration, runtime files and shared updater
  infrastructure. Runtime binary presence alone is not sufficient detection.
- For installer OneDrive cleanup, retain the exact-user transcripts before and after
  reboot. Early cleanup unregisters OneDrive and schedules file removal through a
  temporary HKCU Run entry. The boot-time guard ignores same-boot Explorer restarts;
  the first later-boot attempt consumes the entry before cleanup. Verify leftover
  removal, preservation of nonempty sync folders, and no recurring cleanup at later
  sign-ins. Do not hide a user transcript failure behind a clean aggregate warning log.
- Create a standard user with no existing profile. Observe the setup toast, Explorer
  refresh, correct taskbar pins and completion toast without a forced sign-out. Confirm
  one successful setup transcript and no new transcript on an ordinary later sign-in.
  The initializer removes its RunOnce retry before refreshing Explorer; nested desktop
  commands use `/silent /noaction`. The delayed Search finalizer performs a second
  controlled refresh before the completion toast.
- Exercise desktop launchers from a standard account using administrator credentials
  when requested. Confirm user changes target the initiating account. Test both toggle
  directions, restore the intended defaults, reboot when recommended, and check health.
- For upgrade/reapply coverage, confirm recorded choices are replayed and that
  `PowerSaving\PreviousPowerSchemeGuid` metadata survives without a bogus toggle warning.

For a read-only diagnostic report, run the latest collector as the installing account
from an elevated Windows PowerShell prompt:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1 -RcDiagnostics
```

The extended report includes Search scope, PCA task XML and available task history,
OneDrive file/owner diagnostics, WebView2 detection, local policy processing and relevant
Windows events. Missing history is reported; collection does not enable auditing.
`tools/dev/Start-AtlasPcaTrace.ps1` is a separate, state-changing focused diagnostic:
it records the starting state, enables task history, disables only PcaPatchDbTask and
prints how to restore the previous history setting. Preserve evidence before reinstalling.
