# Contributing

Full contribution guidelines live in our
[documentation](https://docs.atlasos.net/docs/contributing/). This file is the in-repo
quick start.

## Quick start

Prerequisites: **PowerShell 7** and **7-Zip or NanaZip** for builds; **Windows
PowerShell 5.1** and **Pester 5.7.1** for payload tests.

```
./build.cmd                                   # build a test playbook (.apbx)
pwsh tools/build/Test-Apbx.ps1 -Path "playbook/Atlas Test.apbx"   # verify it
```

Run the [payload and build tests in their separate hosts](../docs/testing.md#3-pester-unit-tests).
Use unelevated test shells; configuration actions and installation checks belong in a
disposable VM.

Lint in PowerShell 7 with PSScriptAnalyzer 1.25.0 (CI runs both profiles):

```powershell
Get-ChildItem playbook -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1

Get-ChildItem tools,tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

## Where things live

- **Architecture:** [docs/architecture.md](../docs/architecture.md) — how an install runs
  and where the code lives. Scripts are organized by who invokes them: `Entry` (processes
  started from outside), `Install` (install-only plan, phases, tasks), `Operations`
  (child-process and user-context entry bodies), and `Modules` (shared implementations).
- **Compatibility surfaces:** [docs/compatibility.md](../docs/compatibility.md) — every file
  kept for an external consumer, with its removal condition.
- **Building:** [docs/building.md](../docs/building.md).
- **Testing:** [docs/testing.md](../docs/testing.md).

## Common tasks

- **Add or change a tweak:** edit the relevant `.psd1` under
  `playbook/Executables/AtlasModules/Scripts/Tweaks` (schema in that folder's `README.md`)
  and its entry in `tweaks.manifest.psd1`. To disable a tweak, remove it from `Categories`
  or `Standalone` and add its full slug and a reason to `Disabled`. Every shipped
  definition must be classified exactly once.
- **Add or change an AtlasDesktop toggle:** edit the data-only definition
  `playbook/Executables/AtlasModules/Toggles/<Group>/<Name>.psd1` (schema in that folder's
  `README.md`); imperative work goes in the function-only companion `<Name>.ps1` beside it.
  Validate with `Test-AtlasToggleDefinition -Path playbook/Executables/AtlasModules/Toggles`
  (from the `Atlas.Toggles` module) and regenerate launchers with
  `pwsh tools/dev/New-ToggleLaunchers.ps1`.
- **Regenerate the catalog after definition changes:** run
  `pwsh tools/dev/Export-AtlasCatalog.ps1` for the JSON and Markdown references. Both
  generators support `-Validate` to check for drift without writing files.
- **Share one implementation between the install and a toggle:** give the install tweak a
  `Toggle = @(@{ Name; State })` entry instead of duplicating the toggle's machine work.
- **Work on the desktop app:** see [app/README.md](../app/README.md) for Rust builds,
  isolated tests and review tools.
- **Bump the version:** `pwsh tools/build/Set-AtlasVersion.ps1 -Version X.Y.Z`.

The payload runs under **Windows PowerShell 5.1** — avoid PowerShell 7-only syntax in
anything under `playbook/`. The CI parse gate enforces this.
