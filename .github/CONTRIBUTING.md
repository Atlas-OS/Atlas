# Contributing

Full contribution guidelines live in our
[documentation](https://docs.atlasos.net/docs/contributing/). This file is the in-repo
quick start.

## Quick start

Prerequisites: **PowerShell 7** and **7-Zip or NanaZip**.

```
./build.cmd                                   # build a test playbook (.apbx)
pwsh tools/build/Test-Apbx.ps1 -Path "playbook/Atlas Test.apbx"   # verify it
Invoke-Pester -Path tests                     # run the unit tests
```

Lint before opening a PR (CI runs the same two profiles):

```powershell
Get-ChildItem playbook -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1
```

## Where things live

- **Architecture:** [docs/architecture.md](../docs/architecture.md) — how an install runs
  and where the code lives.
- **Building:** [docs/building.md](../docs/building.md).
- **Testing:** [docs/testing.md](../docs/testing.md).

## Common tasks

- **Add or change a tweak:** edit the relevant `.psd1` under
  `playbook/Executables/AtlasModules/Scripts/Tweaks` (schema in that folder's `README.md`)
  and its line in `tweaks.manifest.psd1`. Disable a tweak by commenting out its manifest
  line.
- **Add or change an AtlasDesktop toggle:** edit the definition under
  `playbook/Executables/AtlasModules/Toggles`, then regenerate launchers with
  `pwsh tools/dev/New-ToggleLaunchers.ps1`.
- **Bump the version:** `pwsh tools/build/Set-AtlasVersion.ps1 -Version X.Y.Z`.

The payload runs under **Windows PowerShell 5.1** — avoid PowerShell 7-only syntax in
anything under `playbook/`. The CI parse gate enforces this.
