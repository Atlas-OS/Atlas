# Developer scripts

This folder holds PowerShell scripts for people who work on Atlas: two generators for committed files, and helpers for testing and diagnosing installs.
Each script's comment-based help gives its parameters; the documentation linked below explains when to use it.

## Generators

Run a generator after you change what it reads, and commit its output.
Both take `-Validate`, which compares the expected output with the files on disk without writing anything, and the Pester tests run both that way.

| Script | Purpose | Documentation |
| --- | --- | --- |
| `New-ToggleLaunchers.ps1` | Generates the AtlasDesktop and Toolbox `.cmd` launcher stubs from the toggle definitions. | [Atlas toggle definitions](../../playbook/Executables/AtlasModules/Toggles/README.md) |
| `Export-AtlasCatalog.ps1` | Generates `playbook/Executables/AtlasModules/Toggles/catalog.json` and `docs/catalog/` from the toggle definitions and the tweak manifest. | [Atlas architecture](../../docs/architecture.md) |

```powershell
pwsh tools/dev/New-ToggleLaunchers.ps1
pwsh tools/dev/Export-AtlasCatalog.ps1
```

## Testing and diagnostics

| Script | Purpose | Documentation |
| --- | --- | --- |
| `Compare-SystemState.ps1` | Dumps registry, service and scheduled task state to JSON, and compares two dumps. | [Testing](../../docs/testing.md) |
| `Get-AtlasInstallReport.ps1` | Writes a read-only text report of an installed PC; Atlas Manager runs it for diagnostics exports. | [Testing](../../docs/testing.md) |
| `Get-AtlasInstallEvidence.ps1` | Collects Atlas state and the newest staging requests into a log that diagnostics exports include, without rerunning the install. | [Reporting problems](../../docs/diagnostics.md) |
| `Start-AtlasPcaTrace.ps1` | Disables `PcaPatchDbTask` on an installed Atlas VM and turns on task history, to trace whether the task is turned back on after a restart. | [Testing](../../docs/testing.md) |
| `Show-AtlasConsoleDemo.ps1` | Renders the Atlas console vocabulary and four sample launcher flows without changing the PC. | [Console presentation](../../docs/console-presentation.md) |
| `Update-WindowsReleaseCatalog.ps1` | Regenerates the Windows release catalog, `Scripts/Compatibility/windows-releases.json`, from Microsoft's release information. | [Windows release eligibility](../../docs/windows-release-policy.md) |
| `Install-DevProfile.ps1` | Adds a `$PROFILE` snippet that puts the Atlas modules on `PSModulePath` in VS Code; `-Remove` takes it out. | [Building the Atlas package](../../docs/building.md) |
