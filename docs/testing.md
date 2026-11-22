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
| Windows PowerShell | `PSScriptAnalyzerSettings.Package.psd1` | `package/**` and `app/resources/**`, which run on users' PCs under Windows PowerShell 5.1. Adds `PSUseCompatibleSyntax` for 5.1 and 7.4, and `PSProvideCommentHelp` for exported functions. |
| Strict | `PSScriptAnalyzerSettings.psd1` | `tools/**`, `tests/**`, and Atlas Manager's release, notice and screenshot tooling and its tests |

```powershell
Get-ChildItem package,app/resources -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Package.psd1

Get-ChildItem tools,tests,app/tools/Build-Release.ps1,app/tools/Export-DependencyNotices.ps1,app/tools/Update-ReadmeScreenshots.ps1,app/tools/tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

CI fails on any Error or Warning.

## Windows PowerShell 5.1 parse gate

Users' PCs run Windows PowerShell 5.1.
CI parses every `.ps1`, `.psm1` and `.psd1` under `package` and `app/resources` with `[System.Management.Automation.Language.Parser]` in `powershell.exe`, to catch syntax that only PowerShell 7 accepts.

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

`tools/build/Test-Package.ps1 -Path "<file>.atlaspkg"` verifies a built package, including exact file-path parity with the source.
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
It checks formatting, and runs Clippy (warnings as errors) and `cargo test`, both without features and with `--features embedded-package`, the [tester build](building.md#tester-builds).

The tests install nothing and change no settings.
They cover:

- package version containment and transactional extraction, with synthetic `.atlaspkg` files;
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
`tools/lab/Invoke-AtlasLabRun.ps1` runs one install on a Hyper-V VM on your own PC, and `.github/workflows/integration.yml` runs the same script on a self-hosted runner.
The script's help (`Get-Help tools/lab/Invoke-AtlasLabRun.ps1 -Full`) gives every detail.
The lab doesn't cover launcher interactions or updates from earlier releases; use the [release checks](#release-checks) and the [verification matrix](release-verification-matrix.md) for those.

### Preparing the VM

The host needs Hyper-V with its PowerShell module, PowerShell 7, and 7-Zip or NanaZip to extract the package.
Run the script from an elevated prompt, or as a member of the Hyper-V Administrators group.

Prepare the VM once, then take the checkpoint that every run starts from:

1. Install a Windows release that `supportedBuilds` in `package/atlas.json` lists, finish Windows setup, and give the VM internet access.
2. Sign in with a local administrator account other than the built-in Administrator.
   The front door refuses the built-in Administrator, because it needs a standard user token alongside the administrator one.
3. Install updates until Windows Update and the Microsoft Store report nothing pending.
   Restart if Windows asks, and sign in again with the same account.
4. Turn off the four Windows Security protection switches, and leave out any other antivirus app, as the package's requirements demand.
5. Take a standard checkpoint while that account is signed in.
   A production checkpoint starts the VM at the sign-in screen, so the run stops unless the account signs in automatically.

When Windows Update or the Microsoft Store offers something new, the front door exits 5 and the run stops.
Install the updates in the VM, then take the checkpoint again.

### Running the lab

Build a full package, then run the lab against the VM:

```powershell
pwsh tools/build/Build-Package.ps1 -FileName 'Atlas Lab' -ReplaceExisting -NoExplorer
pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
    -Credential (Get-Credential AtlasLab) -PackagePath 'package\Atlas Lab.atlaspkg'
```

The lab needs a full build: a `-LocalTest` build has an empty `supportedBuilds`, so the front door refuses it.

| Parameter | Meaning |
| --- | --- |
| `-VMName` | The Hyper-V VM. |
| `-CheckpointName` | The checkpoint each run restores. |
| `-Credential` | The administrator account that's signed in at the checkpoint, which PowerShell Direct and the front door use. |
| `-PackagePath` | A full `.atlaspkg` build. |
| `-ArchiveKey` | The package's ZIP password: `atlasos` by default, or an empty string for a `-NoPassword` build. |
| `-ExtractedRoot` | An extracted package to install instead of `-PackagePath`. |
| `-Option` | The option ids to install with; the recommended set by default. |
| `-OutputPath` | Where the results go; `lab-output\<timestamp>` by default. |
| `-BootTimeoutSeconds` | How long to wait for the VM, and for the account's session, after each start; 600 by default. |
| `-InstallTimeoutSeconds` | How long the front door may run before the lab stops it; 7200 by default. |
| `-Keep` | Leave the VM running after the run instead of turning it off. |

Each run:

1. restores the checkpoint, starts the VM and waits for the account's interactive session;
2. copies the package into the VM over PowerShell Direct, and records the registry, services and scheduled tasks with `Compare-SystemState`;
3. runs `Scripts\Entry\Install-Atlas.ps1` unattended in the account's interactive session;
4. restarts the VM, runs `Scripts\Entry\Test-AtlasHealth.ps1 -Json`, and compares a second record with the first;
5. collects the results and turns the VM off.

Step 4 is skipped when the front door stops before it installs anything.

PowerShell Direct runs commands in session 0, which the front door refuses, because preparing Windows and the Microsoft Store and installing Atlas belong to the signed-in account's session.
So the run registers a one-time scheduled task for the account, which Windows runs elevated in that account's interactive session, as Atlas Manager runs the front door.
The run removes the task once it has the result.

### What the lab reports

The run writes these files to the output folder:

| File | Contents |
| --- | --- |
| `lab-run.log` | The lab run's own log. |
| `install.log` | The front door's output. |
| `install-session.json` | The account and session the front door ran in, and whether it ran elevated. |
| `install-result.json` | The front door's exit code. |
| `health.json` | The health check's report. |
| `baseline.json`, `candidate.json` and `state-diff.txt` | The records from before and after the install, and their differences. |
| `Logs\` and `state.json` | The Atlas logs and the state document from the VM. |

The script prints each step as it goes, and ends with its exit code and the output folder:

| Exit code | Meaning |
| --- | --- |
| 0 | Atlas installed and the health check found no drift. |
| 1 | The front door failed or didn't finish in time, or the health check reported drift or couldn't run. |
| 2 | Lab setup failed, including a VM that doesn't meet the prerequisites, so the front door exited 3 (not elevated) or 5 (updates pending). |

### Running the lab in CI

`.github/workflows/integration.yml` runs the lab on manual dispatch.
It needs a prepared checkpoint and a self-hosted runner labelled `self-hosted`, `windows` and `hyperv`; the repository provides neither.

| Setting | Kind | Value |
| --- | --- | --- |
| `ATLAS_LAB_VM` | Variable | VM name; the job is skipped when it's unset. |
| `ATLAS_LAB_CHECKPOINT` | Variable | Checkpoint name. |
| `ATLAS_LAB_USER` | Variable | The local administrator account the checkpoint is signed in as, other than the built-in Administrator. |
| `ATLAS_LAB_PASSWORD` | Secret | That account's password. |

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
