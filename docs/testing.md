# Testing

This page is for contributors and maintainers.
It covers the automated checks for the Windows PowerShell scripts that run on users' PCs, the Atlas package and Atlas Manager, the lab VM run, and the checks to repeat for a release.
Run the commands from the repository root.

The Windows PowerShell tests need Windows PowerShell 5.1, and the build tools and build tests need PowerShell 7.
Install Pester 5.7.1 in both hosts and PSScriptAnalyzer 1.25.0 in PowerShell 7, the versions `.github/workflows/test.yml` and `lint.yml` pin.
The inbox Pester 3 is too old.

Run unit tests unelevated; they use mocks, temporary files and scratch HKCU keys.
CI runs them elevated, so a test must give the same result under either token.
Mock the privilege check or set up the state it reads, rather than branching on the real token.

> [!WARNING]
> Run install and configuration checks only in a disposable Windows VM, never on a development PC.

Each release also needs the evidence in the [release verification matrix](release-verification-matrix.md); see [Release checks](#release-checks).

## PSScriptAnalyzer

| Profile | Settings (`.github/linters/`) | Scope |
| --- | --- | --- |
| Windows PowerShell | `PSScriptAnalyzerSettings.Payload.psd1` | `playbook/**` and `app/resources/**`, which run on users' PCs under Windows PowerShell 5.1. Adds `PSUseCompatibleSyntax` for 5.1 and 7.4. |
| Strict | `PSScriptAnalyzerSettings.psd1` | `tools/**`, `tests/**`, and Atlas Manager's release and notice tooling and its tests |

```powershell
Get-ChildItem playbook,app/resources -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1

Get-ChildItem tools,tests,app/tools/Build-Release.ps1,app/tools/Export-DependencyNotices.ps1,app/tools/tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

CI fails on any Error or Warning.

## Windows PowerShell 5.1 parse gate

Users' PCs run Windows PowerShell 5.1.
CI parses every `.ps1`, `.psm1` and `.psd1` under `playbook` and `app/resources` with `[System.Management.Automation.Language.Parser]` in `powershell.exe`, to catch syntax that only PowerShell 7 accepts.

## Pester unit tests

Run the Windows PowerShell tests in Windows PowerShell 5.1 (`powershell.exe -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @(Get-ChildItem tests -Filter '*.Tests.ps1' |
    Where-Object Name -ne 'AtlasBuild.Tests.ps1' |
    Select-Object -ExpandProperty FullName)
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

Run the build tests in PowerShell 7 (`pwsh -NoProfile`):

```powershell
Import-Module Pester -RequiredVersion 5.7.1
$config = New-PesterConfiguration
$config.Run.Path = @('tests/AtlasBuild.Tests.ps1', 'app/tools/tests')
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
```

CI uses the same split, so each suite runs once, on its supported host.
Both exit nonzero on failure.
For a focused run, narrow `Run.Path` and keep the matching host.
Keep `ErrorActionPreference` at its default: a global `Stop` can intercept native errors that tests assert on.

The suites cover shared logic and key behaviour, such as install-state retry, registry targeting, tweak and toggle execution, process arguments, package selection and build and archive parity.
They make no lasting changes.
Registry tests create and remove `HKCU:\Software\AtlasRewriteTest`.

To review console wording before a VM run, `tools\dev\Show-AtlasConsoleDemo.ps1` renders the vocabulary and five sample flows under Windows PowerShell 5.1 without changing the PC.

## Package verification

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` verifies a built package, including exact file-path parity with the source.
[Verifying a build](building.md#verifying-a-build) lists its checks.
It's the strongest end-to-end check short of installing Atlas.

## Generated files

Two PowerShell 7 generators maintain the committed launcher stubs, the JSON catalog and the Markdown references.
`tests\Atlas.Toggles.Tests.ps1` and `tests\Atlas.Catalog.Tests.ps1` run them with `-Validate`, so CI fails when a definition changes without regenerating.

```powershell
pwsh tools/dev/New-ToggleLaunchers.ps1 -Validate   # AtlasDesktop and Toolbox .cmd stubs
pwsh tools/dev/Export-AtlasCatalog.ps1 -Validate   # Toggles\catalog.json and docs\catalog
```

Run them without `-Validate` to regenerate.

## Desktop app (Rust)

```powershell
cd app
cargo test
```

`.github/workflows/app.yml` builds `app/` against its lockfile on `windows-latest`.
It checks formatting, and runs Clippy (warnings as errors) and `cargo test`, both without features and with `--features embedded-playbook`, the [tester build](building.md#tester-builds).

The tests install nothing and change no settings.
They cover:

- package version containment and transactional extraction, with synthetic `.apbx` files;
- the Windows PowerShell launch, using the real `powershell.exe` and stub scripts: option arrays, exit codes, non-UTF-8 output and session reattach;
- release ordering and download verification;
- install-flow transitions and locking, and settings persistence and recovery;
- registry and COM adapters, with scratch keys under `HKCU:\Software\AtlasOS\AppTests`;
- theme contrast;
- Windows-language negotiation, regional number and date formatting, every catalog under `app/i18n`, and every `t!` call against the source catalog ([internationalisation](../app/docs/i18n.md)).

## Writing tests

- Prefer focused behavioural tests of shared logic, and of the real points where code starts a process, crosses a privilege boundary, saves state or recovers.
- Assert on behaviour or data (definitions, plans, manifests), never on script text.
  The exception is an exact contract between two files, such as a path a `.reg` file embeds.
- Don't add tests that only check that a file, function, definition entry or string exists or is gone, or that repeat a definition's values.
  Definition validation and the generators' `-Validate` runs catch drift.
  Keep such a check only when it's the sole guard of a real rule, such as a privacy default or a privilege split.
- Begin each Windows PowerShell test file's `BeforeAll` with `. (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')`, which enforces the host and module paths (see its header).
  Keep shared host setup there.
- Call tooling such as `tools\dev\New-ToggleLaunchers.ps1` through `$script:AtlasTestToolsHost` (PowerShell 7).
- Validate toggle definitions as data with `Test-AtlasToggleDefinition`.
  Run companion functions through `Invoke-AtlasToggleFunction` with mocked module commands, as `tests\Atlas.Toggles.Tests.ps1` does.
- Test console output by capturing printed lines and scripting answers.
  `tests\Atlas.ConsolePresentation.Tests.ps1` does this for the heading, warning gate, closing line and single exit pause against small fixture toggles.

## Lab VM verification

The checks above never apply Atlas configuration.
A Hyper-V lab VM covers what only a real install can: the front door, the TrustedInstaller broker, the plan phases, sign-in replay and the health check.

Prepare the VM before the first run:

1. Install a supported Windows release and finish Windows setup.
2. Sign in with an ordinary administrator account.
   Don't use the built-in Administrator: the front door refuses it, because it needs a standard user token alongside the administrator one.
3. Install updates until Windows Update and the Microsoft Store report nothing pending.
   Restart if Windows asks, and sign in again with the same account.
4. Take the checkpoint while that account is signed in.

Then build a full package and run the lab:

```powershell
pwsh tools/build/Build-Playbook.ps1 -FileName 'Atlas Lab' -ReplaceOldPlaybook -DontOpenPbLocation
pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
    -Credential (Get-Credential) -PlaybookPath "playbook\Atlas Lab.apbx"
```

Give `-Credential` the account the checkpoint is signed in as.
The lab needs a full build: a `-LocalTest` build leaves out `<SupportedBuilds>`, so the front door refuses it.

Each run restores the checkpoint and copies the Atlas package in over PowerShell Direct.
It then installs Atlas unattended through `Scripts\Entry\Install-Atlas.ps1`, restarts the VM and runs `Scripts\Entry\Test-AtlasHealth.ps1 -Json`.
The install log, the health report, the `Compare-SystemState` before-and-after diff and the Atlas logs go to `lab-output\`.
The script header lists the steps and the host requirements.

The run fails if the install exits nonzero, a fresh install reports drift, or the VM doesn't come back.

| Exit code | Meaning |
| --- | --- |
| 0 | Verified. |
| 1 | The install or the verification failed. |
| 2 | Lab setup failed. |

`.github/workflows/integration.yml` runs the lab on manual dispatch.
It needs a prepared checkpoint and a self-hosted runner labelled `self-hosted`, `windows` and `hyperv`; the repository provides neither.

| Setting | Kind | Value |
| --- | --- | --- |
| `ATLAS_LAB_VM` | Variable | VM name; the job is skipped when it's unset. |
| `ATLAS_LAB_CHECKPOINT` | Variable | Checkpoint name. |
| `ATLAS_LAB_USER` | Variable | The administrator account the checkpoint is signed in as. Set it: the built-in Administrator doesn't work. |
| `ATLAS_LAB_PASSWORD` | Secret | That account's password. |

The lab run doesn't cover launcher interactions or updates from earlier releases; use the [release checks](#release-checks) and the [verification matrix](release-verification-matrix.md).

### Collecting a report by hand

`tools/dev/Get-AtlasInstallReport.ps1` writes a read-only text report of a PC with Atlas installed, for bug reports.
Copy it to the PC and run it from an elevated Windows PowerShell prompt as the account that installed Atlas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1
```

The report goes to that user's desktop as `atlas-install-report-<timestamp>.txt`.
Its drift check runs the installed health check and is the result to rely on.
The other sections add context about the PC, listed in the script header.
A section that fails records why, and the report still completes.

## Release checks

Repeat these checks for each release, with the files you'll publish or a tester build of the same commit.
Start each pass from the clean checkpoint.
Reinstalling over a build that recorded every launcher default hides whether Atlas records only applied choices.

After installing with Atlas Manager:

- Compare the toggle records under `HKLM\SOFTWARE\AtlasOS\Services` with `%windir%\AtlasOS\state.json`.
- Check that PhoneLink, RecentItems and WebSearch are applied and recorded as disabled.
- Restart, then run the installed health launcher.

When a release changes the code behind one of these areas, also check it:

- **Health:** Open File Explorer first.
  Transient Bags, High Contrast initialisation and taskbar pin bookkeeping are left out of verification; persistent declarations and refused policy writes aren't.
- **Indexing:** Run Disable, Enable and Minimal from the desktop launchers and check Indexing Options, also after a restart.
  Minimal covers AtlasDesktop and the Start menu, not user data; Enable covers user documents, not AppData.
- **PCA:** Check PcaSvc and PcaPatchDbTask after the delayed-start interval.
  The tweak disables and stops the service before disabling the task, because starting PcaSvc re-enables the task even under the DisablePCA policy.
- **Edge:** Remove Edge, but keep WebView2 registration, runtime files and the shared updater infrastructure.
  Runtime binaries alone don't prove WebView2 is present.
- **OneDrive:** Cleanup unregisters OneDrive during the install, then removes its files in one attempt after the restart, through a temporary HKCU Run entry (see `Scripts\Operations\Remove-OneDriveCurrentUserData.ps1`).
  Keep the installing user's transcripts from before and after the restart.
  Check that leftovers are gone, sync folders with files in them remain, and cleanup doesn't run again at later sign-ins.
  Check the user transcript even when the combined warning log is clean.
- **New user:** Sign in as a new standard user.
  Expect the setup notification, a File Explorer refresh, the right taskbar pins, a second refresh from the delayed Search step, then the completion notification, without a forced sign-out.
  Expect one successful setup transcript, and none at a later ordinary sign-in.
  `Scripts\Entry\Initialize-NewUser.ps1` explains the refresh order.
- **Launchers from a standard account:** Enter administrator credentials when asked; user changes must reach the account that started the launcher.
  Test both directions, restore the intended defaults, restart when recommended and check health.
- **Updates and reapply:** Recorded choices replay, and the `PowerSaving\PreviousPowerSchemeGuid` value survives with no toggle warning.

For these checks, run the [report collector](#collecting-a-report-by-hand) from the release commit with `-RcDiagnostics`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-AtlasInstallReport.ps1 -RcDiagnostics
```

This adds Windows Search, PCA task, OneDrive shell-extension, WebView2, local policy and BITS diagnostics with related events (see the parameter help).
It stays read-only: it reports missing task history and turns on neither history nor auditing.

`tools/dev/Start-AtlasPcaTrace.ps1` changes the PC.
It records the starting state, turns on task history, disables only PcaPatchDbTask and prints how to restore the history setting.
Keep the evidence before reinstalling.
