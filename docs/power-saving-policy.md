# Power-saving policy

This page explains what Atlas's Power Saving toggle changes, what it leaves alone and why, for contributors, reviewers and users who want the detail.
The toggle uses documented Windows power-plan operations to switch to an Atlas copy of the Balanced plan with four plugged-in (AC) settings changed; undoing it restores the previous plan.

The toggle isn't a switch for every device or platform power-saving mechanism, and battery (DC) values stay as Balanced has them.
Power behaviour depends on hardware, firmware and drivers.
A blanket change can raise energy use and heat without a performance or latency benefit that holds on every PC.

## Using the toggle

The toggle needs administrator rights.
Its launchers are in `3. General Configuration\Power-saving`:

| Launcher | Toggle state | Effect |
| --- | --- | --- |
| `Disable Power-saving.cmd` | `Disable` | Applies the Atlas plan. |
| `Default Power-saving (default).cmd` | `Enable` | Restores the previous plan and deletes the Atlas plan. |

A fresh install with **Turn off power saving** (`disable-power-saving`) ticked on Atlas Manager's **Your choices** page applies `Disable`.
Without it, the install makes Balanced the active plan.

Default Power-saving undoes only Atlas's change, apart from applying any recorded CPU Idle and Sleep choices to the restored plan (see [How it works](#how-it-works)).
It never runs `powercfg /restoredefaultschemes`, which would delete the PC's current plans and their settings.

Check Atlas Health reads the active plan for both states.
For Disable it also checks the four AC settings below, and reports missing or unreadable settings as drift rather than trusting the toggle record alone.

### Updates and reinstalls

Before an update or a reinstall of the same version starts, an active Atlas plan counts as the choice **Disable**, even if an earlier install left an Enable record.
Replaying a stale Enable record would remove the active Atlas plan, so the install repairs the record before it keeps choices or replays toggles.
It logs `Set the 'PowerSaving' record to 0: the Atlas power plan is active.` when it does.

Atlas Manager and the record Atlas keeps when it moves Windows to a newer release read the same evidence.
Other power plans don't establish this choice, and a plan isn't replaced only because its name differs.
An install whose steps have already begun keeps the choices it captured when it started.

## AC settings

The Atlas plan ("Atlas Power Scheme", `11111111-1111-1111-1111-111111111111`) changes only these AC values:

| Setting (subgroup) | Setting GUID | AC value | Meaning and limits |
| --- | --- | ---: | --- |
| NVMe NOPPME (Hard disk, `0012ee47-9041-4b5d-9b77-535fba8b1442`) | `fc7372b6-ab2d-43ee-8797-15e9841f2cca` | `0` | Off. A plan setting, not a promise that every storage device avoids low-power states. |
| Allow Throttle States (Processor power management, `54533251-82be-4824-96c1-47b60b740d00`) | `3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb` | `0` | Disabled on AC. Firmware thermal controls still apply. |
| Turn off display after (Display, `7516b95f-f776-4464-8c53-06167f40cc99`) | `3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e` | `0` | Never. Can increase display energy use. |
| Processor performance time check interval (Processor power management, `54533251-82be-4824-96c1-47b60b740d00`) | `4d2b0152-7d5c-498b-88e2-34345392a2c5` | `200` | 200 ms, within the range Windows accepts. An Atlas product choice, not a performance or DPC-latency guarantee. |

Recorded CPU Idle and Sleep choices are applied to this plan too.

## What the toggle doesn't change

| Not changed | Why |
| --- | --- |
| Values under `HKLM\SYSTEM\CurrentControlSet\Enum`, including per-device idle, wake, selective-suspend and D-state values | The right value depends on the device, and the driver framework owns the idle and wake values ([user control of device idle and wake behaviour](https://learn.microsoft.com/windows-hardware/drivers/wdf/user-control-of-device-idle-and-wake-behavior)). |
| The ACPI Processor Aggregator (`ACPI000C`) | Windows uses it to idle logical processors as a thermal mitigation ([ACPI-defined devices](https://learn.microsoft.com/windows-hardware/drivers/bringup/acpi-defined-devices)). |
| Devices matched by localised WMI ACPI friendly name, and bulk `MSPower_DeviceEnable` changes | No exactly reversible way exists across hardware. |
| Network-adapter advanced properties, including the standardised `*EEE` ([power management keywords](https://learn.microsoft.com/windows-hardware/drivers/network/standardized-inf-keywords-for-power-management)) and `*SelectiveSuspend` keywords | The toggle has no exact per-adapter rollback; a separate install step sets five vendor properties ([network adapter properties](#network-adapter-properties)). |
| `StorageD3InModernStandby` | It's a platform policy that OEMs set through ACPI first ([storage power management](https://learn.microsoft.com/windows-hardware/design/component-guidelines/power-management-for-storage-hardware-devices-intro)). |
| StorNVMe `IdlePowerMode` and NDIS `DefaultPnPCapabilities` | Microsoft doesn't document them for this use. |
| `PowerThrottlingOff` | It has a public policy ([Turn off Power Throttling](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-admx-power)), but older Atlas versions changed it without recording its earlier value, so leaving it alone keeps rollback exact. |
| Zero values for the NVMe idle timeouts, USB hub suspend timeout, USB selective suspend, USB 3 link power management and display dim timeout | Blanket zeros can defeat low-power behaviour that Windows or the platform manages, and older Atlas versions didn't restore the exact earlier values. |

The settings in the last row are the NVMe idle timeouts (`d3d55efd-c1ff-424e-9dc3-441be7833010`, `d639518a-e56d-4345-8af2-b9f32fb26109`), USB hub suspend timeout (`0853a681-27c8-4100-a2fd-82013e970683`), USB selective suspend (`48e6b7a6-50f5-4782-a5d4-53bb8f07e226`), USB 3 link power management (`d4e98f31-5ffe-4ce1-be31-1b38b384c009`) and display dim timeout (`17aaa29b-8b43-4b94-aafe-35f64daaf1ee`).

Some of these are documented for driver, OEM or managed-device use.
Atlas leaves them out because it has no safe, exactly reversible way to apply them on all hardware, not because Windows lacks support.

### Network adapter properties

The Power Saving toggle doesn't touch network adapters.
A separate install step, `atlas-network-settings`, and the `9. Troubleshooting\Network\Reset Network to Atlas Default.cmd` launcher set these properties to `0`, with or without a `*` prefix, on PCI network adapters whose driver exposes them:

- `AutoDisableGigabit`
- `ApCompatMode`
- `SipsEnabled`
- `ReduceSpeedOnPowerDown`
- `DMACoalescing`

These writes keep no record of the earlier values.
To go back to the driver's settings, run `9. Troubleshooting\Network\Reset Network to Windows Default.cmd`, which resets the network stack and reinstalls every present network adapter.

### PCs updated from older Atlas versions

Older Atlas versions changed or renamed per-device values under `Enum`.
Atlas leaves them as they are, even in Default Power-saving, because guessing a Windows default is unsafe.
The right value depends on the device, driver package, firmware and OEM configuration, and an absent value can be meaningful.

To fix an affected PC, use evidence from its OEM or driver package, or check the fix in a disposable VM that represents that installation.
No compatibility switch restores the old per-device changes.

## How it works

`Set-AtlasPowerSavingState` in `playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Hardware\Domain\Power.ps1` implements both states.

- **Both states** require the Windows Balanced plan (`381b4222-f694-41f0-9685-ff5bb260df2e`).
  They hold the machine-wide `Global\AtlasOS.PowerSaving.Transaction.v1` mutex for the whole transaction, so concurrent launches can't interleave rollback state with plan changes.
  Waiting more than 30 seconds fails without changing anything.
- **Rollback value:** before changing any plan, Disable saves the active plan's GUID (lowercase, no braces) as a `REG_SZ` at `HKLM\SOFTWARE\AtlasOS\Services\PowerSaving\PreviousPowerSchemeGuid`, or Balanced if the Atlas plan is already active.
  An existing value is kept, so a rerun never replaces the original target.
  A value that isn't a `REG_SZ` GUID stops the run.
- **Disable** replaces any existing Atlas plan with a fresh duplicate of Balanced, activating Balanced first if needed, then sets the four AC values and activates it.
- **Default** activates the saved plan if it's installed and isn't the Atlas plan, otherwise Balanced, then deletes the Atlas plan.
- **Per-plan choices:** CPU idle and sleep settings belong to each plan, so after either state the toggle applies the recorded CpuIdle and Sleep choices to the plan it left active.
  A recorded choice that doesn't apply on this PC, such as disabling CPU idle with SMT on, is skipped.
  One that can't be applied is logged as a warning, and an interactive run says to run that choice's launcher again; neither fails the toggle.
  Upgrade replay restores PowerSaving before them.
- **Unlisted plans:** on Modern Standby PCs, `powercfg /list` shows only Balanced and its copies.
  The Ultimate Performance copy older Atlas versions made is left out of that list but still holds the Atlas GUID.
  Both states therefore also look for its key under `HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes` and delete it.
- **Checks:** every `%windir%\System32\powercfg.exe` call that `Set-AtlasPowerSavingState` makes stops the run on a nonzero exit code, and every plan GUID from `powercfg` or the registry is validated.
  The active plan is read back before success is reported.
  Default removes the saved value only after that check.
