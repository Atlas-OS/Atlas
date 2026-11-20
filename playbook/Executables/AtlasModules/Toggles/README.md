# Atlas toggle definitions

This folder holds the toggles: settings a user changes after the install from the AtlasDesktop folder or Atlas Toolbox.
It's for contributors who add or change a toggle.
The generated [toggle reference](../../../../docs/catalog/toggles.md) lists every toggle with its states and work.

Each toggle is one data-only definition, `Toggles/<Group>/<Name>.psd1`, with an optional companion script beside it, `Toggles/<Group>/<Name>.ps1`, that holds only functions.
Atlas loads definitions with `Import-AtlasDataFile`, which wraps the inbox `Import-PowerShellDataFile` and runs no code.
No toggle code runs until the engine, `Atlas.Toggles`, calls a named companion function.

## Where the work runs

A definition declares its states with the same vocabulary as the install tweaks (`Registry`, `Services`, `ScheduledTasks`), plus named functions for work that has to be code.
The engine works out where each part runs from those declarations, so a definition never states its own privilege split.

| Work | Declared by | Runs as | Replayed |
| --- | --- | --- | --- |
| Machine | `HKLM` registry entries, `Services`, `ScheduledTasks`, `MachineAction` | The declared `Elevation`. | On update, from the recorded state. |
| User | `HKCU` registry entries, `UserAction` | The launching user, without elevation. | At each new account's first sign-in. |
| Local | Any registry entry and `Action` of an `Elevation = 'None'` toggle | The launcher process. | Never, because these toggles record no state. |

### Order of the machine and user parts

A state with user work must start from an unelevated process, so that work never inherits an elevated token.
When the state also has machine work or a `ContextAction`, the engine runs the machine part in a UAC child process, or through the TrustedInstaller broker, and records the state there.
It then finishes the user part in the launching process.
A state whose only work is per-user runs that work first, in the launching process.
The elevated child then only records the choice, and the closing line waits for that record, so a failed user step never replaces an earlier recorded choice.
A state with only machine work is elevated as a whole.
A `/justcontext` run applies only the `ContextAction` and records nothing.

## Validate and generate

Validate every definition without running toggle code with `Test-AtlasToggleDefinition -Path <Toggles folder>`; CI runs it.
Regenerate the launchers with `pwsh tools/dev/New-ToggleLaunchers.ps1`.
Each launcher is a two-line stub that calls the shared `Scripts/Entry/Invoke-AtlasToggleLauncher.cmd`.

## Definition schema

Two-state public toggles use `Disable` and `Enable` as their state names, recorded as `0` and `1`; a UI shows them as Disabled and Enabled.
Multi-choice toggles use descriptive state names.
Write the description so the controlled feature is clear: enabling PauseUpdates pauses updates, while enabling RecentItems removes restrictions without overwriting the user's tracking preferences.

Consumers read state names from `catalog.json`, not from launcher file names, which can be more descriptive.
State records store the numeric `StateValue`, so a recorded choice doesn't depend on the state name.

```powershell
@{
    Name            = 'Bluetooth'            # required; must equal the file name
    Description     = 'What it changes.'     # optional; full sentences
    Elevation       = 'Admin'                # 'None' | 'Admin' | 'TrustedInstaller' (default None)
    Warning         = 'Shown and confirmed before an interactive run.'   # optional
    Menu            = $true                  # optional: one launcher with a numbered state picker
    Launcher        = '6. Advanced Configuration\...\Toggle X.cmd'      # Menu toggles only
    ToolboxLauncher = 'Scripts\X\toggleX.cmd'                            # only for a path a Toolbox release before 0.2.0 opens (docs/compatibility.md)
    SilentDefault   = 'Enable'               # Menu toggles: state used silently with no record
    NoStateRecord   = $true                  # optional: never record this toggle
    Script          = 'Bluetooth.ps1'        # companion; required when a state names a function
    States          = @(                     # ordered; menu numbering follows this order
        @{
            Name             = 'Disable'     # required identifier
            StateValue       = 0             # REG_DWORD recorded under HKLM\SOFTWARE\AtlasOS\Services\<Name>
            Launcher         = '6. Advanced Configuration\Services\Bluetooth\Disable Bluetooth.cmd'
            ToolboxLauncher  = 'Scripts\X\disableX.cmd'             # only for a path a Toolbox release before 0.2.0 opens (docs/compatibility.md)
            MenuLabel        = 'Disable Bluetooth'                  # Menu toggles
            Reboot           = 'Recommend'   # 'None' | 'Recommend' | 'Prompt' | 'RestartExplorer' | 'SignOut'
            ShellRefreshOperation = 'SearchShellRefresh'   # with RestartExplorer; default ExplorerRefresh
            NoStateRecord    = $true         # optional per-state variant
            Internal         = $true         # optional: an implementation state with no launcher, left out of the catalog
            Registry         = @( @{ Path = 'HKLM:\...'; Name = 'Value'; Type = 'DWord'; Data = 0 } )
            Services         = @( @{ Name = 'bthserv'; StartupType = 4 } )
            ScheduledTasks   = @( @{ Path = '\Microsoft\Windows\X\Task'; Operation = 'Disable' } )
            MachineAction    = 'Disable-AtlasBluetoothMachine'   # companion function
            UserAction       = 'Disable-AtlasBluetoothUser'      # companion function
            Action           = 'Invoke-AtlasX'                   # Elevation None only
            ContextAction    = 'Set-AtlasXContextMenu'           # runs first; /justcontext stops after it
            ReplayApplicable = 'Test-AtlasXReplayApplicable'     # $false removes a stale record on update
            InteractiveState = 'Select-AtlasXState'              # TrustedInstaller only; see below
        }
    )
}
```

### Rules the validator enforces

- `Name` equals the file name, and state names are identifiers.
- A `StateValue` is an integer, unique within the toggle, unless the toggle or state declares `NoStateRecord`.
- Public non-menu states declare a `Launcher`.
  Menu toggles declare one top-level `Launcher`, and optionally `SilentDefault`.
- A non-menu implementation state can declare `Internal = $true` and `NoStateRecord = $true` instead of a launcher.
  The catalog leaves internal states out.
- `InteractiveState` belongs only on a public machine-only state of a TrustedInstaller toggle.
- `Registry` entries take the [tweak registry keys](../Scripts/Tweaks/README.md#registry-entries) except `MigrateDwordToString` and `VerifyWithToggle`.
  `Services` and `ScheduledTasks` entries take the same keys as in tweaks.
- `HKCU` entries are user work.
  Policy paths under `HKCU` are rejected, because a medium-integrity process must not set policy, and so are explicit `HKEY_USERS` hives.
- Elevated toggles declare `MachineAction`, `UserAction` or both, never `Action`.
- `Elevation = 'None'` toggles declare `Action`, `HKCU` registry entries or both, and must declare `NoStateRecord`, because they can't write the protected state store.
  They can't declare `Services`, `ScheduledTasks`, `MachineAction`, `UserAction`, `ReplayApplicable` or machine registry paths.
- Every function a state names is defined in the companion script, and every function the companion defines, private helpers included, is named `Verb-AtlasNoun`.

Within one scope the order is fixed: `Registry`, `Services`, `ScheduledTasks`, then the function.
Put work in the companion only when that order, a prompt, a native command or a computed value makes the declarative form insufficient.

## Companion scripts

A companion contains one header comment, which says what it does, which identity runs it and when, followed by function definitions only.
Each function takes one parameter, `$Toggle`, and runs under strict mode with terminating errors.
`Atlas.Core`, `Atlas.Registry`, `Atlas.Services` and `Atlas.TasksProcs` are already imported; use `Import-AtlasModule -Name Atlas.Appx` (or `Atlas.Software`, `Atlas.Download`) for others.

```powershell
# Companion for the Bluetooth toggle: disables or enables every Bluetooth device. Its machine
# functions run as Administrator when you run a launcher and when an update replays the
# recorded state.

function Disable-AtlasBluetoothMachine {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Disabling Bluetooth devices. This can take a minute...'
    }
    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -AllowNoMatch -Silent
}
```

`$Toggle` carries `Name`, `State`, `StateValue`, `Silent`, `JustContext`, `NoExplorerRestart`, `ResetServices`, `StateRoot`, `LauncherPath`, `WinDir`, `AtlasModulesPath`, `ScriptsPath`, `ModulesPath`, `OperationsPath` and `WindowsBuild`.
Only prompt when `-not $Toggle.Silent`.
Silent runs include update replay, first sign-in replay and the service defaults reset.
Use `Invoke-AtlasToggleNativeCommand` for native executables, so exit codes are checked.
A function can apply another toggle's machine part with `Invoke-AtlasToggleMachineState -Name X -State Y -StateRoot $Toggle.StateRoot`.

### Console output

Everything a companion prints goes through the Atlas.Core console vocabulary described in [console presentation](../../../../docs/console-presentation.md):

- `Write-AtlasStep` for slow work.
- `Read-AtlasYesNo` and `Read-AtlasChoice` for the questions a state already asks.
- `Write-AtlasNote`, `Write-AtlasWarning` and `Write-AtlasSuccess` for facts.
- `Write-AtlasNextStep` or `Write-AtlasManualStep` when the user must continue elsewhere.
  `Write-AtlasManualStep` turns the closing line into `Not finished yet:`.

The engine owns the heading, the definition's warning gate, the `Done:` line, the restart follow-up and the single pause before the window closes.
A companion never prints "Finished", pauses or signs out.
`Reboot = 'SignOut'` shows the sign-out notice after the closing line and asks "Sign out now?" in interactive runs, by which time the choice is recorded.

A companion that runs a script or helper checks its exit code and throws, so a helper that stopped early is reported as not applied.
A companion that asks before restarting File Explorer calls `Invoke-AtlasToggleCurrentSessionShellRefresh -Operation ExplorerRefresh`.
It reports a failed refresh with `Write-AtlasPartial`, because its own change is already in place.

### TrustedInstaller toggles and interactive choices

A TrustedInstaller toggle's machine work always runs in the silent broker, so a prompt, warning or step in its `MachineAction` never reaches the user.
A public machine-only state of a TrustedInstaller toggle can name an `InteractiveState` companion function instead.
The administrator process calls it before it hands the work to the broker.
It must return exactly one existing machine-only state name, never one with user or local work.
Returning the state's own name confirms it, as Mitigations does after its warning.
Use fixed internal states to carry a prompted choice into the broker, as Indexing does, and record the public choice only after that work succeeds.
Silent replay skips the selector and applies the original recorded state, so its machine action must keep any separately saved option without prompting.

## State record and replay

Only the elevated machine process records state, and only after the machine part completes.
A user-only state is recorded after its user part succeeds.
Updates replay every recorded state's machine part from the installed definition, and remove records whose definition or state no longer exists.
Each new account's first sign-in replays every recorded state's user part.
Toggles that must never replay, such as safe mode, one-shot repairs and information views, declare `NoStateRecord`.

Recorded states can be verified.
`Test-AtlasToggleState` reads one state's `Registry`, `Services` and `ScheduledTasks` declarations back for a scope.
`Test-AtlasToggleDrift` does that for every recorded state, and flags records whose definition or value no longer exists.
Companion functions aren't verified.
The health check launcher (`9. Troubleshooting\Check Atlas Health.cmd`) and the Defaults phase after an update replay both use it.

`catalog.json` beside this file is generated from the definitions by `tools/dev/Export-AtlasCatalog.ps1`, and CI checks it.
Regenerate it after you change a definition.
It's the machine-readable index that consumers such as Atlas Toolbox read.

## Install-time use

Install tweaks apply a toggle's machine part and record it with the tweak `Toggle` key, such as `Toggle = @( @{ Name = 'AutomaticUpdates'; State = 'Disable' } )`.
The install and the AtlasDesktop launcher then share one implementation.
On an update, a toggle that already has a recorded state gets that state instead.
