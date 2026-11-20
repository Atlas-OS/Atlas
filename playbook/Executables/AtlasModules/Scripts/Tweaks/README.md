# Atlas tweak definitions

This folder holds the tweaks the Atlas install applies: one data-only definition for each tweak, and the manifest that orders them.
It's for contributors who add or change a tweak.
The generated [install tweak reference](../../../../../docs/catalog/tweaks.md) lists every tweak with its conditions and work.

## How tweaks are loaded

Each tweak is a `.psd1` file at `<category>/.../<name>.psd1`.
`tweaks.manifest.psd1` sets the category order, the standalone steps and the disabled definitions.
Atlas loads every definition with `Import-AtlasDataFile`, which wraps the inbox `Import-PowerShellDataFile` and runs no code.
The `Atlas.Tweaks` module applies them with `Invoke-AtlasTweak` and `Invoke-AtlasTweakCategory`.
It handles the option, architecture and install mode gates, the separate current-user scopes and the error handling for each entry.

### The install user

The install user is the account that ran Atlas Manager.
The install state records its SID, and Atlas checks a process token against that SID before it runs anything as that user.
Tweaks reach the install user in two ways: current-user (`HKCU`) registry entries, and companion scripts with `RunAs = 'User'`.

## Validate and verify

Validate a file or folder with `Test-AtlasTweakSchema -Path <path>`.
Validate the manifest and every route through it with `Test-AtlasTweakManifest -Path <tweaks.manifest.psd1>`.
CI runs both.

Verify an applied tweak with `Test-AtlasTweak -Path <tweak.psd1>`, or a whole category with `Test-AtlasTweakCategory -Name <category>`.
Both return one record for each entry that no longer holds, and nothing for a tweak whose conditions don't apply to the PC.
`-RegistryScope` picks `Machine` (the default), `ProtectedCurrentUser` (`HKCU` policy keys) or `CurrentUser` entries.

Verification reads back:

- `Registry` entries, except those with `SkipVerification`.
  An entry with `VerifyWithToggle` expects the value of the recorded toggle state, and values a recorded toggle owns are left to toggle verification.
- `Services` and `ScheduledTasks`, in the `Machine` scope only.

It doesn't check `Toggle` entries, which the toggle engine verifies, or `Run`, `RemovePaths`, `Script` and `PostUserRegistryRefresh`.
The health check (`Scripts/Entry/Test-AtlasHealth.ps1`) runs it for every category and for the standalone tweaks the install plan ran on that PC.

## Naming

Tweak files are kebab-case, such as `set-hidden-settings-pages.psd1`, unlike the `Verb-Noun` scripts elsewhere.
They're data definitions that the manifest and the install plan address by slug, not commands you run.
A companion `Script` shares its definition's base name.
Don't rename them to PascalCase.

## Manifest schema (`tweaks.manifest.psd1`)

```powershell
@{
    Categories = @(
        @{
            Name        = 'networking'
            # The install plan routes that reach this category's Tweaks/<name> step.
            ParentModes = @('Fresh', 'Upgrade')
            # Paths relative to the category folder, without the .psd1 extension.
            Tweaks      = @(
                'atlas-network-settings'
                'shares/restrict-anonymous-access'
            )
        }
    )
    # Definitions the install plan runs as their own Tweak/<slug> steps, outside the category order.
    Standalone = @(
        @{ Slug = 'qol/appearance/atlas-theme-upgrade'; ParentModes = @('Upgrade') }
    )
    # Every definition not enabled above, with the reason it's disabled.
    Disabled = @(
        @{ Slug = 'networking/disable-llmnr'; Reason = 'Preserves home network name resolution.' }
    )
}
```

`ParentModes` names the install plan routes that reach a category or standalone step: `Fresh`, `Upgrade` or both.
`Install-Plan.ps1` holds the routes themselves, and the catalog generator checks that the two agree.
A Rebase install takes the `Upgrade` route.
A Reapply, a reinstall of the same version, takes the categories' `Upgrade` route but not standalone `Upgrade` steps.
`ParentModes` doesn't replace a tweak's own `OnUpgrade`: the validator combines them, so an `OnUpgrade = 'Only'` tweak in a fresh-only category is unreachable and fails validation.

A standalone tweak runs only the machine and default-user passes, so it can't declare live `HKCU` entries.
Each definition file appears exactly once across `Categories`, `Standalone` and `Disabled`.
To disable a tweak, remove its enabled entry and add its full slug and a reason to `Disabled`.
Missing files, duplicate categories or slugs, unsafe paths, unknown keys and unclassified files also fail validation.

## Tweak schema

All keys are optional except `Name`.
The machine pass applies the action keys in this order: `Registry`, `Services`, `ScheduledTasks`, `Toggle`, `Run`, `RemovePaths`, `Script`.
`PostUserRegistryRefresh` runs at its own point, after the live `HKCU` pass.

| Key | Type | Meaning |
| --- | --- | --- |
| `Name` | string (required) | Display name in logs and the catalog. |
| `Description` | string | What the tweak does, in full sentences. |
| `Option` | string | Apply only when the user chose this option; see [Options](#options). |
| `Arch` | `'X64'` or `'ARM64'` | Apply only on this architecture. |
| `MinBuild` / `MaxBuild` | integer | Apply only within this Windows build range, inclusive. |
| `OnUpgrade` | `'Both'` (default), `'Skip'` or `'Only'` | The install modes that run the tweak; see [Install modes](#install-modes). |
| `OnRebase` | `'Run'` | With `OnUpgrade = 'Skip'`, also run on Rebase installs. |
| `RunAs` | `'User'` | Run the companion `Script` as the install user; see [Companion scripts](#companion-scripts). |
| `Registry` | array of hashtables | Registry operations; see [Registry entries](#registry-entries). |
| `PostUserRegistryRefresh` | string | A shell refresh after the live `HKCU` pass; see [Shell refresh](#shell-refresh). |
| `Services` | array of hashtables | Service changes; see [Services](#services). |
| `ScheduledTasks` | array of hashtables | Tasks to disable or enable; see [Scheduled tasks](#scheduled-tasks). |
| `Toggle` | array of hashtables | Toggle states to apply and record; see [Toggle entries](#toggle-entries). |
| `Run` | array of hashtables | Programs to run and check; see [Run entries](#run-entries). |
| `RemovePaths` | array of hashtables | Paths under `{windir}` to delete; see [RemovePaths entries](#removepaths-entries). |
| `Script` | string | A companion `.ps1` next to the definition; see [Companion scripts](#companion-scripts). |

### Options

`Option` takes one of these values: `auto-updates-default`, `auto-updates-disable`, `browser-brave`, `browser-chrome`, `browser-firefox`, `browser-librewolf`, `defender-disable`, `defender-enable`, `disable-core-isolation`, `disable-hibernation`, `disable-power-saving`, `install-another-browser`, `install-toolbox`, `install-eclean`, `keyboard-shortcuts`, `keyboard-selector`, `keyboard-single`, `mitigations-default`, `mitigations-disable`, `remove-snipping-tool` or `uninstall-edge`.
A cleared check box or a default answer has no tweak of its own.
When an update chooses again, the Choices step applies it and undoes Atlas's earlier Disable where Atlas recorded one; see [Choose again](../../../../../docs/upgrading.md#choose-again).

### Install modes

`OnUpgrade` decides which install modes run a tweak, within the modes its category or standalone route reaches:

- `Both`, the default, runs it in every mode the route reaches.
- `Skip` runs it on fresh installs only.
  Upgrade, Reapply and Rebase installs skip it, unless `OnRebase = 'Run'` adds Rebase.
- `Only` runs it on Upgrade, Reapply and Rebase installs, and never on fresh installs.

A Rebase install puts Atlas back on a Windows that rebuilt itself while Atlas Manager moved it to a newer release.
Leave `OnRebase` out of tweaks that would overwrite the user's own layout, theme, file associations or settings.

`MinBuild` and `MaxBuild` aren't enforced when Atlas can't read the Windows build number.

### Registry entries

```powershell
@{
    Path         = 'HKLM:\...' # or 'HKCU\...', the default-user hive HKU\Atlas_DefaultUser, Registry::HKEY_...
    Name         = 'ValueName' # required for Set and Delete; '' is the key's default value
    Type         = 'DWord'     # String | ExpandString | Binary | DWord | MultiString | QWord | None
    Data         = 0           # required for Set unless Type is None, String or ExpandString
    Operation    = 'Set'       # Set (default) | Delete | DeleteKey | AddKey
    Arch         = 'X64'       # optional architecture gate for this entry
    IgnoreErrors = $true       # optional: warn and continue on any failure
    AllowOsProtected = $true   # optional: warn and continue only when Windows refuses this value
    UseGroupPolicy = $true     # optional, HKLM Software\Policies DWord Set only: save to the local GPO and verify
    SkipVerification = 'Windows rewrites this initial value.' # optional: why drift checks skip this entry
    Mask         = '4'         # optional, Binary or String Set only: change only these bits
    MigrateDwordToString = $true # optional, masked String only: read an existing DWORD value as the flags
    VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String'; Data = 'Allow' } # optional
}
```

`Mask` keeps a user's other flags.
For `Binary`, `Mask` and `Data` are byte arrays of the same length; for `String`, both are unsigned decimal flag strings such as `'4'`.
A missing value is written as `Data`, and a value of an unexpected kind or length fails the entry.
A masked entry must be a `Set`, and can't use `UseGroupPolicy` or `VerifyWithToggle`.
`MigrateDwordToString = $true` lets a masked `String` entry take over a value that older Atlas releases wrote as a DWORD, and rewrites it as a decimal string.

`VerifyWithToggle` names a toggle, an integer `State`, and a `Set` (`Type` and `Data`) or `Delete` override.
Once that state is recorded, an update applies the override instead of the install default, and verification expects it.
It needs a fully verified `Set` or `Delete` of a machine or current-user value, so it can't be combined with `Mask` or `SkipVerification`.
See [Registry entry options](../../../../../docs/architecture.md#registry-entry-options).

`IgnoreErrors` and `AllowOsProtected` tolerate different things:

- `IgnoreErrors` tolerates every failure, including a mistyped path that would otherwise never be noticed.
- `AllowOsProtected` tolerates one condition: the key opened for writing and Windows then refused this value.
  This happens for a few values even with TrustedInstaller rights, and a supported policy API may be needed instead.
  It applies to `Set` and `Delete` only, and the Atlas health check still reports a refused value as drift.

`UseGroupPolicy` saves a machine DWORD policy through the Windows local Group Policy API, checks that policy refreshed, and verifies the applied value.
It doesn't use `AllowOsProtected` to tolerate a failed policy application.

### Current-user entries

`HKCU` entries run in two scopes.
The install user applies them to their own profile through ambient `HKCU`.
TrustedInstaller applies the same entries to the default-user hive (`HKU\Atlas_DefaultUser`), which accounts created later start from.
Other explicit user hives are rejected.
Write `HKCU\...` and let the install plan pick the scope.

### Shell refresh

`PostUserRegistryRefresh` takes one of `ShellRefresh`, `ExplorerRefresh`, `SearchShellRefresh`, `StartMenuRefresh` or `ExplorerAndSettingsRefresh`.
After the install user's live `HKCU` pass succeeds, Atlas runs that refresh in the install user's session and requires exit code 0.
The tweak needs at least one ambient `HKCU` entry.
A refresh several tweaks ask for runs once, in manifest order.
Don't repeat the refresh in `Run` or `Script`.

### Services

`Services` entries take `@{ Name; StartupType; Operation; AllowMissing; IgnoreErrors }`:

- `Operation` is `Change` (the default), `Stop` or `Start`.
  `Change` writes the service key's `Start` value directly, so protected services work too.
- `StartupType` is required for `Change`: 0 Boot, 1 System, 2 Automatic, 3 Manual or 4 Disabled.
- A missing service is skipped when `StartupType` is 4, since it can't run.
  For 0 to 3 it's an error unless the entry declares `AllowMissing = $true`, for services that depend on the edition, build or hardware.
- Any other failure is an error unless the entry declares `IgnoreErrors = $true`.

`Invoke-AtlasServiceEntries` in Atlas.Services applies these entries for tweaks and toggles alike.

### Scheduled tasks

`ScheduledTasks` entries take `@{ Path; Operation; IgnoreErrors }`, where `Operation` is `Disable` (the default) or `Enable`.
Atlas applies them through the Atlas.TasksProcs helpers and `%windir%\System32\schtasks.exe`.
A missing task is logged as a warning.
Access failures, nonzero exit codes and failed readback are errors unless the entry declares `IgnoreErrors = $true`, which also tolerates malformed entries.

### Toggle entries

`Toggle` entries take `@{ Name; State }`.
Each applies and records the machine part of an installed toggle state through `Invoke-AtlasToggleMachineState`, so the install and the AtlasDesktop launcher share one implementation.
On an update, a toggle that already has a recorded state gets that state instead.
See the [toggle definitions README](../../Toggles/README.md).

### Run entries

`Run` entries take `@{ Exe; Args; Arch; IgnoreErrors; Wait; AllowedExitCodes }`:

- `Exe` is an absolute path or starts with `{windir}`, and `Args` is an array of strings passed exactly as written.
- Atlas always waits for a Run entry and checks its exit code, so `Wait` can only be `$true`.
- A Run entry succeeds only with exit code 0.
  The one exception is `{windir}\System32\dism.exe`, which can declare `AllowedExitCodes = @(0, 3010)` so that 3010, DISM's "restart required" code, also counts as success.
- `IgnoreErrors = $true` turns a failure into a warning.

Work that must run as the install user belongs in a companion `Script` with `RunAs = 'User'`.

### RemovePaths entries

`RemovePaths` entries take `@{ Path; Arch; IgnoreErrors }`.
Each path must resolve beneath `{windir}` and is removed recursively; a path that's already gone counts as success.
A failed removal stops the tweak unless the entry declares `IgnoreErrors = $true`.

### Companion scripts

`Script` names a `.ps1` file next to the definition for work that has to be code.
It runs after every other key in the machine pass.

With `RunAs = 'User'`, Atlas starts the companion through `Invoke-AtlasAsUser` as the install user, without elevation, and passes `-ExpectedUserSid` for the script's token check.
The companion runs once, for the install user, so accounts created later need their own first sign-in path, such as Initialize-NewUser.
There are no elevated user companions, and shell work uses the session-filtered refresh helper.

## Example

This is `privacy/disable-pca.psd1`, which uses registry entries, services and a scheduled task:

```powershell
@{
    Name        = 'Disable Program Compatibility Assistant (PCA)'
    Description = 'Turns off the Program Compatibility Assistant and the application compatibility engine, with their service, app inventory and compatibility database task.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AITEnable'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableEngine'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableInventory'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisablePCA'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableUAR'; Type = 'DWord'; Data = 1 }
    )
    Services = @(
        @{ Name = 'PcaSvc'; StartupType = 4 }
        @{ Name = 'PcaSvc'; Operation = 'Stop' }
    )
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Application Experience\PcaPatchDbTask' }
    )
}
```

For other keys, see `qol/disable-screen-capture-hotkey.psd1` (an `Option` gate), `performance/disable-fth.psd1` (`Run` and `RemovePaths` with architecture gates) and `qol/taskbar/config-pins.psd1` (`OnUpgrade` and a companion script).
