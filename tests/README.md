# Tests

This folder holds the Pester tests for the Atlas package scripts and the build tools.
It's for contributors who add or run tests.
The [testing guide](../docs/testing.md) covers the full suites, the required Pester and PSScriptAnalyzer versions, the analyzers and the VM checks.

## Test files

Name each test file `Atlas.<Area>.Tests.ps1`, after the module, script or behaviour it covers, such as `Atlas.Registry.Tests.ps1` or `Atlas.DefenderChoice.Tests.ps1`.

| File | Host | Covers |
| --- | --- | --- |
| `Atlas.<Area>.Tests.ps1` | Windows PowerShell 5.1 | Scripts and modules under `playbook/`, which run on users' PCs |
| `AtlasBuild.Tests.ps1` | PowerShell 7 | The build tools under `tools/build` |

## The test host

`AtlasTestHost.ps1` sets up each Windows PowerShell test file to run the way Atlas scripts run on users' PCs.
Every `Atlas.<Area>.Tests.ps1` file dot-sources it at the start of its `BeforeAll` block.

```powershell
BeforeAll { . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1') }
```

It does the following:

- Stops the run unless the host is Windows PowerShell 5.1.
- Sets `PSModulePath` to the inbox modules, the Atlas modules under `playbook/Executables/AtlasModules/Scripts/Modules` and the module folder that holds Pester, so a module on a per-user path can't shadow them.
- Imports the inbox Management, Utility and Security modules from their exact manifests.
- Defines paths that tests use: `$script:AtlasTestRepoRoot`, `$script:AtlasTestScriptsRoot` and `$script:AtlasTestModulesRoot`.
- Finds PowerShell 7 as `$script:AtlasTestToolsHost`, for tests that run the generators under `tools/dev`.

Keep shared host setup in this file, not in individual test files.

## Run one test file

Run a test file on its own host, from the repository root.
Install Pester 5 for that host first: Windows PowerShell 5.1 includes only Pester 3, which can't run these tests.
Use Windows PowerShell 5.1 for an `Atlas.<Area>.Tests.ps1` file.

```powershell
powershell -NoProfile -Command "Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop; Invoke-Pester -Path tests/Atlas.Registry.Tests.ps1 -Output Detailed"
```

Use PowerShell 7 for the build tests.

```powershell
pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop; Invoke-Pester -Path tests/AtlasBuild.Tests.ps1 -Output Detailed"
```

Run tests unelevated; the testing guide explains how they keep a development PC unchanged.

## Fixtures

`fixtures` holds data files for the PowerShell tests.
The Atlas Manager tests under `app/` read most of them too, so the scripts and the app agree on the same records.
Changing a fixture runs both suites in CI.

| Folder | Contents |
| --- | --- |
| `front-door` | `windows-security.json`: Windows Security registry values and the protection switch states each should produce |
| `windows-transition` | Records Atlas writes while it moves Windows to a newer release, records older Atlas releases left, and the options Atlas reads from them |

Most fixtures are written by hand in the format of the records they stand for.
`cbs-appinv-baseline.txt` is an excerpt of a Windows CBS log, kept to component names and corruption counts.
The files hold no personal data: account SIDs are placeholders such as `S-1-5-21-1-2-3-1001`.
Before you add a file taken from a real PC, replace every SID, user name, computer name and user profile path with a placeholder like these.
