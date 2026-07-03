# Atlas tweak definitions

This folder holds Atlas' declarative tweaks: one data-only `.psd1` file per tweak,
organized as `<category>\...\<name>.psd1`, plus `tweaks.manifest.psd1` which defines the
category order and the tweak list per category (disabling a tweak = commenting out its
manifest line). Files are parsed with `Import-PowerShellDataFile` (no code execution)
and applied by the `Atlas.Tweaks` module (`Invoke-AtlasTweak` / `Invoke-AtlasTweakCategory`),
which centralizes the hard semantics once: HKCU resolution under TrustedInstaller,
default-user-hive mirroring, architecture gating and per-entry error handling.

Validate any file or folder with `Test-AtlasTweakSchema -Path <path>` (also run by CI).

## Manifest schema (`tweaks.manifest.psd1`)

```powershell
@{
    Categories = @(
        @{
            Name   = 'networking'
            # Paths are relative to the category folder, without the .psd1 extension.
            Tweaks = @(
                'disable-network-throttling'
                'subfolder/some-other-tweak'
            )
        }
    )
}
```

## Tweak schema

All keys are optional except `Name`. Keys are applied in the order listed below.

| Key | Type | Meaning |
| --- | --- | --- |
| `Name` | string (required) | Display name, used in logs. |
| `Description` | string | What the tweak does and why. |
| `Option` | string | Only apply when the user selected this FeaturePage option. Known values: `auto-updates-default`, `auto-updates-disable`, `browser-brave`, `browser-chrome`, `browser-firefox`, `browser-librewolf`, `defender-disable`, `defender-enable`, `disable-core-isolation`, `disable-hibernation`, `disable-power-saving`, `install-another-browser`, `install-toolbox`, `mitigations-default`, `mitigations-disable`, `remove-snipping-tool`, `uninstall-edge`. |
| `Arch` | `'X64'` or `'ARM64'` | Only apply on this architecture. |
| `OnUpgrade` | `'Skip'` (default), `'Only'` or `'Both'` | `Skip` = fresh installs only, `Only` = upgrade installs only, `Both` = always. |
| `Oobe` | bool | When `$false`, the tweak is skipped during OOBE installs. |
| `Registry` | array of hashtables | Registry operations, see below. |
| `Services` | array of hashtables | `@{ Name; StartupType (int 0-4); Operation }`. `Operation` is `'Change'` (default; writes the service key's `Start` value directly so protected services work), `'Stop'` or `'Start'`. `StartupType` is required for `Change`: 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled. |
| `ScheduledTasks` | array of hashtables | `@{ Path; Operation }` with `Operation` = `'Disable'` (default) or `'Enable'`, applied via `schtasks.exe /Change`. A missing task only logs a warning. |
| `StopProcesses` | array of strings | Process names (wildcards allowed, no `.exe`) stopped with `-Force`; missing processes are ignored. |
| `Run` | array of hashtables | `@{ Exe; Args; Arch; IgnoreErrors; Wait }`. `Wait` defaults to `$true`; when waiting, a non-zero exit code other than 3010 (reboot required, e.g. DISM) is a failure. |
| `RemovePaths` | array of hashtables | `@{ Path; Arch }`; paths are removed recursively, `{windir}` expands to the Windows directory, missing paths are ignored. |
| `Script` | string | Relative path to a companion `.ps1` next to the tweak file, invoked after all other keys for genuinely imperative work. |

### Registry entries

```powershell
@{
    Path         = 'HKLM:\...' # or 'HKCU\...', 'HKU\...', 'Registry::HKEY_...'
    Name         = 'ValueName' # required for Set/Delete
    Type         = 'DWord'     # String | ExpandString | Binary | DWord | MultiString | QWord | None
    Data         = 0           # required for Set unless Type is None/String/ExpandString
    Operation    = 'Set'       # Set (default) | Delete | DeleteKey | AddKey
    Arch         = 'X64'       # optional per-entry architecture gate
    IgnoreErrors = $true       # optional: swallow failures silently
}
```

HKCU semantics: when the install runs as SYSTEM/TrustedInstaller, `HKCU` paths are
resolved to the interactive user's hive under `HKEY_USERS\<SID>` and mirrored into the
loaded default-user hive (`HKU\AME_UserHive_Default`) so new accounts inherit the tweak.
Never hardcode `HKEY_USERS\<SID>` paths yourself - write `HKCU\...` and let the engine
resolve it.

## Full example

```powershell
@{
    Name           = 'Disable Fault Tolerant Heap'
    Description    = 'Stops Windows silently shimming applications after crashes.'
    Option         = 'defender-disable'   # only when the user picked this option
    Arch           = 'X64'
    OnUpgrade      = 'Skip'
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
    StopProcesses  = @('example*')
    Run            = @(
        @{ Exe = 'rundll32.exe'; Args = 'fthsvc.dll,FthSysprepSpecialize'; Arch = 'X64' }
    )
    RemovePaths    = @(
        @{ Path = '{windir}\ExampleLeftover' }
    )
    Script         = 'disable-fth.ps1'    # companion script next to this .psd1
}
```
