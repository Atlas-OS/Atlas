# Atlas tweak definitions

This folder holds Atlas' declarative tweaks: one data-only `.psd1` file per tweak,
organized as `<category>\...\<name>.psd1`, plus `tweaks.manifest.psd1` which defines the
category order, standalone steps and deliberately disabled definitions. Files are parsed with `Import-PowerShellDataFile` (no code execution)
and applied by the `Atlas.Tweaks` module (`Invoke-AtlasTweak` / `Invoke-AtlasTweakCategory`),
which handles exact-user HKCU and fixed-default-hive scope
separation, architecture gating and per-entry error handling.

Validate any file or folder with `Test-AtlasTweakSchema -Path <path>`. Validate the
manifest and complete execution graph with `Test-AtlasTweakManifest -Path
<tweaks.manifest.psd1>` (both are run by CI).

Verify an applied tweak with `Test-AtlasTweak -Path <tweak.psd1>` or a whole category with
`Test-AtlasTweakCategory -Name <category>`: both read the `Registry`, `Services` and
`ScheduledTasks` declarations back from the machine and return one record per entry that
no longer holds. `Run`, `RemovePaths` and companion scripts are not verified. The health
check (`Scripts\Entry\Test-AtlasHealth.ps1`) runs this for every category.

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
            # Install-plan modes under which this category's `Tweaks/<name>` step runs
            # (`Install-Plan.ps1`, executed by `Invoke-TweaksPhase.ps1`). The validator
            # composes these with each tweak's OnUpgrade gate.
            ParentModes = @('Fresh')
            # Paths are relative to the category folder, without the .psd1 extension.
            Tweaks      = @(
                'atlas-network-settings'
                'shares/restrict-anonymous-access'
            )
        }
    )
    # Full slugs for definitions the install plan places outside the category order as
    # their own 'Tweak/<slug>' steps (Install\Install-Plan.ps1). A standalone tweak runs
    # only the machine and default-user passes, so it may not declare live HKCU entries.
    Standalone = @(
        @{ Slug = 'qol/appearance/atlas-theme-upgrade'; ParentModes = @('Upgrade') }
    )
    # Every definition not enabled above must be classified with a recorded reason.
    Disabled = @(
        @{ Slug = 'networking/disable-llmnr'; Reason = 'Preserve home-LAN name resolution.' }
    )
}
```

`ParentModes` describes install-plan reachability: `Fresh`, `Upgrade`, or both. It does
not replace `OnUpgrade`. For example, an `OnUpgrade = 'Only'` definition under a
fresh-only category is unreachable and fails validation. A definition file must appear
exactly once across `Categories`, `Standalone`, and `Disabled`. To disable one, remove
its enabled entry and add its full slug and a reason to `Disabled`. Missing files, duplicate
categories/slugs, unsafe paths, unknown keys and unclassified files also fail.

## Tweak schema

All keys are optional except `Name`. Action keys run in the machine pass in the order Registry, Services, ScheduledTasks, Toggle, Run, RemovePaths, Script;
`PostUserRegistryRefresh` is phase orchestration metadata and runs only at its explicit
post-live-HKCU boundary.

| Key | Type | Meaning |
| --- | --- | --- |
| `Name` | string (required) | Display name, used in logs. |
| `Description` | string | What the tweak does and why. |
| `Option` | string | Only apply when the user selected this FeaturePage option. Known values: `auto-updates-default`, `auto-updates-disable`, `browser-brave`, `browser-chrome`, `browser-firefox`, `browser-librewolf`, `defender-disable`, `defender-enable`, `disable-core-isolation`, `disable-hibernation`, `disable-power-saving`, `install-another-browser`, `install-toolbox`, `mitigations-default`, `mitigations-disable`, `remove-snipping-tool`, `uninstall-edge`. |
| `Arch` | `'X64'` or `'ARM64'` | Only apply on this architecture. |
| `MinBuild` / `MaxBuild` | integer | Only apply on this Windows build range (inclusive). Maps the old YAML `builds: ['>=22000']` (`MinBuild = 22000`) and `builds: ['<22000']` (`MaxBuild = 21999`). Not enforced when the build number can't be read. |
| `OnUpgrade` | `'Both'` (default), `'Skip'` or `'Only'` | `Skip` = fresh installs only, `Only` = upgrade installs only, `Both` = either mode when the install plan reaches this tweak. `ParentModes` still limits the category or standalone route; this key does not add work to Reapply. |
| `Oobe` | bool | When `$false`, the tweak is skipped during OOBE installs. |
| `RunAs` | `'User'` | Runs the companion `Script` as the exact install-state-bound, non-elevated user via `Invoke-AtlasAsUser`; other keys keep their own execution context. Requires `Oobe = $false`, a first-login path for the eventual user, and a successful `-ExpectedUserSid` token check. Elevated user companions are unsupported; shell work must use the session-filtered refresh helper. |
| `Registry` | array of hashtables | Registry operations, see below. |
| `PostUserRegistryRefresh` | `'ShellRefresh'`, `'ExplorerRefresh'`, `'SearchShellRefresh'`, `'StartMenuRefresh'`, or `'ExplorerAndSettingsRefresh'` | After the exact install-state-bound user's live-HKCU pass succeeds, runs the selected session-filtered refresh and requires exit code 0. Requires an ambient HKCU entry; duplicate operations are collapsed in manifest order. During OOBE, default-profile registry data is still applied but the live-session refresh is deferred to first logon. Do not duplicate the refresh in `Run` or `Script`. |
| `Services` | array of hashtables | `@{ Name; StartupType (int 0-4); Operation; AllowMissing; IgnoreErrors }`. `Operation` is `'Change'` (default; writes the service key's `Start` value directly so protected services work), `'Stop'` or `'Start'`. `StartupType` is required for `Change`: 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled. A missing service is an error unless the entry declares `AllowMissing = $true` (for edition-, build- or hardware-optional services); any other failure is an error unless the entry declares `IgnoreErrors = $true`. Applied by `Invoke-AtlasServiceEntries` in Atlas.Services, which toggles share. |
| `ScheduledTasks` | array of hashtables | `@{ Path; Operation; IgnoreErrors }` with `Operation` = `'Disable'` (default) or `'Enable'`, applied through the Atlas.TasksProcs helpers and the exact System32 `schtasks.exe`. A missing task is logged as a warning. Access failures, nonzero exits and failed readback are errors unless `IgnoreErrors = $true`, which also tolerates malformed entries. |
| `Toggle` | array of hashtables | `@{ Name; State }`. Applies and records the machine part of an installed AtlasDesktop toggle state through `Invoke-AtlasToggleMachineState`, so the install and the launcher share one implementation (see `AtlasModules\Toggles\README.md`). Runs in the machine pass after `ScheduledTasks`. |
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
    IgnoreErrors = $true       # optional: warn and continue on any failure
    AllowOsProtected = $true   # optional: warn and continue only when Windows refuses this value
    UseGroupPolicy = $true     # optional: HKLM Software\Policies DWORD Set only; save local GPO, refresh and verify
    SkipVerification = 'Windows rewrites this initial value.' # optional: reason to exclude a transient entry from drift checks
}
```

`IgnoreErrors` and `AllowOsProtected` are not the same thing. `IgnoreErrors` tolerates every
failure, including a mistyped path that would otherwise never be noticed. `AllowOsProtected`
tolerates exactly one condition: the key opened for writing and Windows then refused this value,
which happens for a small number of values even with TrustedInstaller rights. A supported
policy API may still be required instead of a direct write. Everything else still fails.
It applies to `Set` and `Delete` only, and the Atlas health
check still reports a refused value as drift, so a protected value is never lost silently.

`UseGroupPolicy` persists a machine DWORD policy through Windows' local Group Policy
editor API, checks policy refresh, and verifies the applied value. It does not use
`AllowOsProtected` to tolerate a failed policy application.

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
