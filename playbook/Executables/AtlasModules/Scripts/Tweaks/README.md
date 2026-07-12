# Atlas tweak definitions

This folder holds Atlas' declarative tweaks: one data-only `.psd1` file per tweak,
organized as `<category>\...\<name>.psd1`, plus `tweaks.manifest.psd1` which defines the
category order and the tweak list per category (disabling a tweak = commenting out its
manifest line). Files are parsed with `Import-PowerShellDataFile` (no code execution)
and applied by the `Atlas.Tweaks` module (`Invoke-AtlasTweak` / `Invoke-AtlasTweakCategory`),
which centralizes the hard semantics once: exact-user HKCU and fixed-default-hive scope
separation, architecture gating and per-entry error handling.

Validate any file or folder with `Test-AtlasTweakSchema -Path <path>`. Validate the
manifest and complete execution graph with `Test-AtlasTweakManifest -Path
<tweaks.manifest.psd1>` (both are run by CI).

**Naming:** tweak files are kebab-case (`set-hidden-settings-pages.psd1`), deliberately
unlike the `Verb-Noun` scripts elsewhere: these are data definitions addressed by manifest
slug, not invokable commands, and each name maps 1:1 to the legacy YAML tweak it was
converted from (so `git log --follow` and system-state triage reach the original). A
companion `Script` shares its definition's basename. Do not rename them to PascalCase.

## Manifest schema (`tweaks.manifest.psd1`)

```powershell
@{
    Categories = @(
        @{
            Name        = 'networking'
            # Modes allowed by the parent AME/YAML route which invokes this PowerShell
            # category. The validator composes these with each tweak's OnUpgrade gate.
            ParentModes = @('Fresh')
            # Paths are relative to the category folder, without the .psd1 extension.
            Tweaks      = @(
                'atlas-network-settings'
                'shares/restrict-anonymous-access'
            )
        }
    )
    # Full slugs for definitions invoked directly from another PowerShell phase or a
    # deliberately small YAML shim rather than as part of a category.
    Standalone = @(
        @{ Slug = 'qol/appearance/atlas-theme-upgrade'; ParentModes = @('Upgrade') }
    )
    # Every definition not enabled above must be classified with a recorded reason.
    Disabled = @(
        @{ Slug = 'networking/disable-llmnr'; Reason = 'Preserve home-LAN name resolution.' }
    )
}
```

`ParentModes` describes outer-route reachability: `Fresh`, `Upgrade`, or both. It does
not replace `OnUpgrade`. For example, an `OnUpgrade = 'Only'` definition under a
fresh-only category is unreachable and fails validation. A definition file must appear
exactly once across `Categories`, `Standalone`, and `Disabled`; missing files, duplicate
categories/slugs, unsafe paths, unknown keys and unclassified files also fail.

## Tweak schema

All keys are optional except `Name`. Action keys run in the documented machine-pass order;
`PostUserRegistryRefresh` is phase orchestration metadata and runs only at its explicit
post-live-HKCU boundary.

| Key | Type | Meaning |
| --- | --- | --- |
| `Name` | string (required) | Display name, used in logs. |
| `Description` | string | What the tweak does and why. |
| `Option` | string | Only apply when the user selected this FeaturePage option. Known values: `auto-updates-default`, `auto-updates-disable`, `browser-brave`, `browser-chrome`, `browser-firefox`, `browser-librewolf`, `defender-disable`, `defender-enable`, `disable-core-isolation`, `disable-hibernation`, `disable-power-saving`, `install-another-browser`, `install-toolbox`, `mitigations-default`, `mitigations-disable`, `remove-snipping-tool`, `uninstall-edge`. |
| `Arch` | `'X64'` or `'ARM64'` | Only apply on this architecture. |
| `MinBuild` / `MaxBuild` | integer | Only apply on this Windows build range (inclusive). Maps the old YAML `builds: ['>=22000']` (`MinBuild = 22000`) and `builds: ['<22000']` (`MaxBuild = 21999`). Not enforced when the build number can't be read. |
| `OnUpgrade` | `'Both'` (default), `'Skip'` or `'Only'` | `Skip` = fresh installs only, `Only` = upgrade installs only, `Both` = always. The default matches the legacy YAML semantics (actions without an `onUpgrade` gate ran on fresh installs and upgrades). |
| `Oobe` | bool | When `$false`, the tweak is skipped during OOBE installs. |
| `RunAs` | `'User'` | Runs the companion `Script` as the exact install-state-bound, non-elevated user via `Invoke-AtlasAsUser`; other keys keep their own execution context. Requires `Oobe = $false`, a first-login path for the eventual user, and a successful `-ExpectedUserSid` token check. Elevated user companions are unsupported; shell work must use the session-filtered refresh helper. |
| `Registry` | array of hashtables | Registry operations, see below. |
| `PostUserRegistryRefresh` | `'ShellRefresh'`, `'ExplorerRefresh'`, `'SearchShellRefresh'`, `'StartMenuRefresh'`, or `'ExplorerAndSettingsRefresh'` | After the exact install-state-bound user's live-HKCU pass succeeds, runs the selected session-filtered refresh and requires exit code 0. Requires `Oobe = $false` and an ambient HKCU entry; duplicate operations are collapsed in manifest order. Do not duplicate the refresh in `Run` or `Script`. |
| `Services` | array of hashtables | `@{ Name; StartupType (int 0-4); Operation; IgnoreErrors }`. `Operation` is `'Change'` (default; writes the service key's `Start` value directly so protected services work), `'Stop'` or `'Start'`. `StartupType` is required for `Change`: 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled. Missing services and failed mutations are errors unless the entry explicitly declares `IgnoreErrors = $true`. |
| `ScheduledTasks` | array of hashtables | `@{ Path; Operation; IgnoreErrors }` with `Operation` = `'Disable'` (default) or `'Enable'`, applied through one waited, checked call to the exact System32 `schtasks.exe`. Any nonzero result fails by default; edition/build-optional tasks must explicitly declare `IgnoreErrors = $true`. |
| `Run` | array of hashtables | `@{ Exe; Args; Arch; IgnoreErrors; Wait; RunAs; AllowedExitCodes }`. `Exe` must be absolute or start with `{windir}`; `Args` is an array of exact strings. Runs are always waited and checked, accepting only 0 unless exact System32 DISM declares `@(0, 3010)`. `IgnoreErrors = $true` turns a machine-run failure into a warning. `RunAs = 'User'` runs as the exact install-state-bound user, requires `Wait = $true`, passes `-ExpectedUserSid`, and cannot ignore failure. |
| `RemovePaths` | array of hashtables | `@{ Path; Arch; IgnoreErrors }`; paths must resolve beneath `{windir}`, are removed recursively, and an already-missing path is success. A failed removal is fatal by default unless the entry explicitly declares `IgnoreErrors = $true`. |
| `Script` | string | Relative path to a companion `.ps1` next to the tweak file, invoked after all other keys for genuinely imperative work. |

### Registry entries

```powershell
@{
    Path         = 'HKLM:\...' # or 'HKCU\...', the fixed HKU\Atlas_DefaultUser, Registry::HKEY_...
    Name         = 'ValueName' # required for Set/Delete
    Type         = 'DWord'     # String | ExpandString | Binary | DWord | MultiString | QWord | None
    Data         = 0           # required for Set unless Type is None/String/ExpandString
    Operation    = 'Set'       # Set (default) | Delete | DeleteKey | AddKey
    Arch         = 'X64'       # optional per-entry architecture gate
    IgnoreErrors = $true       # optional: warn and continue
}
```

HKCU entries run in separate scopes. Outside OOBE, the exact install-state-bound user applies
the live-user pass through ambient `HKCU`; TrustedInstaller applies the same entries to the fixed
default-user mount (`HKU\Atlas_DefaultUser`). Other explicit user hives are rejected. Write
`HKCU\...` and let the ordered install plan select the scope.

## Full example

```powershell
@{
    Name           = 'Disable Fault Tolerant Heap'
    Description    = 'Stops Windows silently shimming applications after crashes.'
    Option         = 'defender-disable'   # only when the user picked this option
    Arch           = 'X64'
    OnUpgrade      = 'Skip'               # fresh installs only ('Both' is the default)
    Oobe           = $true
    Registry       = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Example'; Name = 'Legacy'; Operation = 'Delete' }
        @{ Path = 'HKLM:\SOFTWARE\AtlasOS\Example'; Operation = 'AddKey' }
    )
    Services       = @(
        @{ Name = 'ExampleSvc'; StartupType = 4 }                  # Operation defaults to 'Change'
        @{ Name = 'ExampleSvc'; Operation = 'Stop' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Example\ExampleTask' }       # Operation defaults to 'Disable'
    )
    Run            = @(
        @{ Exe = '{windir}\System32\rundll32.exe'; Args = @('fthsvc.dll,FthSysprepSpecialize'); Arch = 'X64' }
    )
    RemovePaths    = @(
        @{ Path = '{windir}\ExampleLeftover' }
    )
    Script         = 'disable-fth.ps1'    # companion script next to this .psd1
}
```
