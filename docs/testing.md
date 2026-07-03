# Testing

The project is verified by four automated gates. All four run in CI; you can run each
locally.

## 1. PSScriptAnalyzer

Two profiles under `.github/linters`:

- **Payload** (`PSScriptAnalyzerSettings.Payload.psd1`) for `playbook/**` — the code that
  ships and runs under Windows PowerShell 5.1. Adds `PSUseCompatibleSyntax` targeting 5.1
  and 7.4.
- **Strict** (`PSScriptAnalyzerSettings.psd1`) for `tools/**` and `tests/**`.

```powershell
Get-ChildItem playbook -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.Payload.psd1

Get-ChildItem tools,tests -Recurse -Include *.ps1,*.psm1 |
    Invoke-ScriptAnalyzer -Settings .github/linters/PSScriptAnalyzerSettings.psd1
```

CI fails on any Error or Warning.

## 2. Windows PowerShell 5.1 parse gate

The payload must parse under Windows PowerShell 5.1 (what target machines run), so CI
parses every payload script with `[System.Management.Automation.Language.Parser]` under
`powershell.exe`. This catches pwsh-7-only syntax before it ships.

## 3. Pester unit tests

Pester 5 tests under `tests/` cover the pure logic of the framework (the registry engine's
HKCU resolution and default-hive mirroring, tweak schema and gating, toggle state, the
build module, etc.). They run unelevated and never mutate the machine — registry tests use
a scratch key under `HKCU:\Software\AtlasRewriteTest`.

```powershell
$config = New-PesterConfiguration
$config.Run.Path = 'tests'
Invoke-Pester -Configuration $config
```

> If a PowerShell 7 install has polluted your `PSModulePath`, the tweak engine's data-file
> loader falls back to an AST parse, so tests still pass under 5.1.

## 4. Apbx smoke verification

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` structurally verifies a built package (see
[building.md](building.md)). It is the strongest end-to-end signal available without
applying the playbook to a live Windows install.

## Manual / VM verification

Behavioural verification that touches Windows itself is done on a VM, not in CI:

- `tools/dev/Compare-SystemState.ps1 -Mode Dump` before/after an install produces registry,
  service, and scheduled-task snapshots; `-Mode Compare` diffs two dumps. Use it to compare
  an old-playbook install against a new-playbook install and triage every difference.
- For toggles: double-click a launcher unelevated and elevated, run it with `/silent`,
  and confirm the recorded state under `HKLM\SOFTWARE\AtlasOS\Services`.
- For upgrades: install a previous release, then apply the new one, and confirm toggle
  choices are re-applied.
