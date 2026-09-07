# Atlas toggle definitions

A toggle is a post-install setting a user changes from the AtlasDesktop folder (or the
Atlas Toolbox). Each toggle is one data-only definition, `Toggles\<Group>\<Name>.psd1`,
plus an optional companion script `Toggles\<Group>\<Name>.ps1` beside it that contains
only functions. Definitions are parsed with the restricted data-file parser, so no
toggle code runs until the engine (`Atlas.Toggles`) invokes a named companion function.

The definition declares a toggle's states with the same declarative vocabulary as the
install tweaks (`Registry`, `Services`, `ScheduledTasks`) plus named functions for work
that is genuinely imperative. The engine derives where each part runs from the
declarations, so a definition never states its own privilege split:

| Work | Declared by | Runs as | Replayed |
| --- | --- | --- | --- |
| Machine | `HKLM` registry entries, `Services`, `ScheduledTasks`, `MachineAction` | the declared `Elevation` (Administrator or TrustedInstaller) | on upgrade, from the recorded state |
| User | `HKCU` registry entries, `UserAction` | the launching user's own non-elevated process, after the machine part succeeds | at each account's first sign-in |
| Local | any registry entry and `Action` of an `Elevation = 'None'` toggle | the launcher process, unchanged | never (such toggles record no state) |

A state that has user work must be launched from a non-elevated process: the engine
runs the machine part in a UAC child (or through the TrustedInstaller broker), records
the state there, then finishes the user part in the launching process so it can never
inherit an elevated token. A state with only machine work is elevated as a whole.

Validate every definition without running any toggle code with
`Test-AtlasToggleDefinition -Path <Toggles folder>` (CI runs it). Regenerate launchers with
`pwsh tools\dev\New-ToggleLaunchers.ps1`; each launcher is a two-line stub that calls the
shared `Scripts\Entry\Invoke-AtlasToggleLauncher.cmd`.

## Definition schema

```powershell
@{
    Name            = 'Bluetooth'            # required; must equal the file name
    Description     = 'What it changes.'     # optional
    Elevation       = 'Admin'                # 'None' | 'Admin' | 'TrustedInstaller' (default None)
    Warning         = 'Shown and confirmed before an interactive run.'   # optional
    Menu            = $true                  # optional: one launcher with a numbered state picker
    Launcher        = '6. Advanced Configuration\...\Toggle X.cmd'      # Menu toggles only
    ToolboxLauncher = 'Scripts\X\toggleX.cmd'                            # optional Toolbox copy
    SilentDefault   = 'Enable'               # Menu toggles: state used silently with no record
    NoStateRecord   = $true                  # optional: never record this toggle
    Script          = 'Bluetooth.ps1'        # companion; required when a state names a function
    States          = @(                     # ordered; menu numbering follows this order
        @{
            Name             = 'Disable'     # required identifier
            StateValue       = 0             # REG_DWORD recorded under HKLM\SOFTWARE\AtlasOS\Services\<Name>
            Launcher         = '6. Advanced Configuration\Services\Bluetooth\Disable Bluetooth.cmd'
            ToolboxLauncher  = 'ConfigurationServices\X\X_0.cmd'   # optional
            MenuLabel        = 'Disable Bluetooth'                  # Menu toggles
            Reboot           = 'Recommend'   # 'None' | 'Recommend' | 'Prompt' | 'RestartExplorer'
            ShellRefreshOperation = 'SearchShellRefresh'   # with RestartExplorer; default ExplorerRefresh
            NoStateRecord    = $true         # optional per-state variant
            Registry         = @( @{ Path = 'HKLM:\...'; Name = 'Value'; Type = 'DWord'; Data = 0 } )
            Services         = @( @{ Name = 'bthserv'; StartupType = 4; AllowMissing = $true } )
            ScheduledTasks   = @( @{ Path = '\Microsoft\Windows\X\Task'; Operation = 'Disable' } )
            MachineAction    = 'Disable-AtlasBluetoothMachine'   # companion function
            UserAction       = 'Disable-AtlasBluetoothUser'      # companion function
            Action           = 'Invoke-AtlasX'                   # Elevation None only
            ContextAction    = 'Set-AtlasXContextMenu'           # runs first; /justcontext stops after it
            ReplayApplicable = 'Test-AtlasXReplayApplicable'     # $false removes a stale record on upgrade
        }
    )
}
```

Rules the validator enforces:

- `Name` equals the file name; state names are identifiers; a `StateValue` is an integer
  unique within the toggle unless the toggle or state declares `NoStateRecord`.
- Public non-menu states declare a `Launcher`; menu toggles declare one top-level
  `Launcher` and optionally `SilentDefault`. Non-menu implementation states may instead
  declare `Internal = $true` and `NoStateRecord = $true`, with no launcher. Internal
  states are omitted from the public catalog.
- `Registry`, `Services` and `ScheduledTasks` entries use the tweak entry keys
  (`Registry` also accepts `SkipVerification`, a non-empty reason string for transient
  entries that still apply but are excluded from drift checks; `Services` also accepts
  `AllowMissing`; `Registry` also accepts `AllowOsProtected` for
  values Windows refuses to write directly, and `UseGroupPolicy` for HKLM
  `Software\Policies` DWORD Set entries that must persist in the local GPO).
  `HKCU` entries are user work; protected
  policy paths under `HKCU` are rejected because a medium-integrity process must not set
  policy. Explicit `HKEY_USERS` hives are rejected.
- Elevated toggles declare `MachineAction` and/or `UserAction`, never `Action`.
  `Elevation = 'None'` toggles declare `Action` and/or `HKCU` registry entries, never
  `Services`, `ScheduledTasks`, `MachineAction`, `UserAction`, `ReplayApplicable` or
  machine registry paths, and must declare `NoStateRecord` because they cannot write the
  protected state store.
- Every function a state names must be defined in the companion script, and every
  function the companion defines (including private helpers) is named `Verb-AtlasNoun`.

Order within one scope is fixed: `Registry`, `Services`, `ScheduledTasks`, then the
function. Put work in the companion only when that order, a prompt, a native command or a
computed value makes the declarative form insufficient.

## Companion scripts

A companion contains nothing but function definitions. Each function takes one
parameter, `$Toggle`, and runs under strict mode with terminating errors. `Atlas.Core`,
`Atlas.Registry`, `Atlas.Services` and `Atlas.TasksProcs` are already imported; use
`Import-AtlasModule -Name Atlas.Appx` (or `Atlas.Software`, `Atlas.Download`) for others.

```powershell
function Disable-AtlasBluetoothMachine {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Disabling Bluetooth devices. This can take a minute...'
    }
    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -AllowNoMatch -Silent
}
```

`$Toggle` carries: `Name`, `State`, `StateValue`, `Silent`, `JustContext`,
`NoExplorerRestart`, `ResetServices`, `StateRoot`, `LauncherPath`, `WinDir`,
`AtlasModulesPath`, `ScriptsPath`, `ModulesPath`, `OperationsPath` and `WindowsBuild`.
Only prompt when `-not $Toggle.Silent`; silent runs include upgrade replay, first
sign-in replay and the closed service-defaults reset. Use `Invoke-AtlasToggleNativeCommand`
for native executables so exit codes are checked. A function may apply another toggle's
machine part with `Invoke-AtlasToggleMachineState -Name X -State Y -StateRoot $Toggle.StateRoot`.

Everything a companion prints goes through the Atlas.Core console vocabulary
([docs/console-presentation.md](../../../../docs/console-presentation.md)): `Write-AtlasStep`
for slow work, `Read-AtlasYesNo` and `Read-AtlasChoice` for the questions a state already
asks, `Write-AtlasNote`, `Write-AtlasWarning` and `Write-AtlasSuccess` for facts, and
`Write-AtlasNextStep` or `Write-AtlasManualStep` when the user must continue elsewhere
(the latter turns the closing line into `Not finished yet:`). The engine owns the
heading, the definition's warning gate, the `Done:` line, the restart follow-up and the
single exit pause, so a companion never prints "Finished" or pauses. A companion that
runs a script or helper checks its exit code and throws, so a helper that stopped early
is reported as not applied.

A public machine-only TrustedInstaller state may name an `InteractiveState` companion
function. The administrator process invokes it before crossing the silent broker
boundary. It must return exactly one existing machine-only state name; it must not
return user or local work. Use fixed internal states to carry a prompted choice into
the broker, as Indexing does. Record the public choice only after that work succeeds.
Silent replay skips the selector and applies the original recorded state, so its
machine action must preserve any separately saved option without prompting.

## State record and replay

Only the machine part records state, and only after it completes. Upgrades replay every
recorded state's machine part from the installed definition; records whose definition
or state no longer exists are removed. First sign-in replays every recorded state's
user part for the new account. Toggles that must never replay (safe mode, one-shot
repairs, information views) declare `NoStateRecord`.

Recorded states can be verified: `Test-AtlasToggleState` reads one state's `Registry`,
`Services` and `ScheduledTasks` declarations back for a scope, and `Test-AtlasToggleDrift`
does that for every recorded state, flagging records whose definition or value no longer
exists. Companion functions are not verified. The health check launcher
(`9. Troubleshooting\Check Atlas Health.cmd`) and the Defaults phase after an upgrade
replay both use it.

`catalog.json` beside this file is generated from the definitions by
`tools\dev\Export-AtlasCatalog.ps1` and validated by CI; regenerate it after changing a
definition. It is the machine-readable index consumers such as AtlasToolbox use.

## Install-time use

Install tweaks apply a toggle's machine part and record it with the tweak `Toggle` key
(`Toggle = @( @{ Name = 'AutomaticUpdates'; State = 'Disable' } )`), so the install and
the AtlasDesktop launcher share one implementation.
