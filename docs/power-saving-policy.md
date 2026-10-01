# Power-saving policy

The Power Saving toggle uses documented Windows power-plan operations to switch to an
Atlas copy of the Balanced plan with four plugged-in (AC) settings changed; undoing it
restores the previous plan. This page explains what it changes, what it leaves alone
and why. It is not a switch for every device or platform power-saving mechanism, and
battery (DC) values stay as Balanced has them. Power behavior depends on hardware,
firmware and drivers, so a blanket change can raise energy use and heat without a
performance or latency benefit that holds on every machine.

## Using the toggle

The toggle needs administrator rights. Its launchers are in
`3. General Configuration\Power-saving`:

| Launcher | Toggle state | Effect |
| --- | --- | --- |
| `Disable Power-saving.cmd` | `Disable` | Applies the Atlas plan. |
| `Default Power-saving (default).cmd` | `Enable` | Restores the previous plan and deletes the Atlas plan. |

A fresh install with **Maximum Performance (Disable Power Saving)**
(`disable-power-saving`) applies `Disable`. Without that option, the installer
activates Balanced.

Default Power-saving undoes only Atlas's change. It never runs
`powercfg /restoredefaultschemes`, which would delete the machine's current plans and
their settings.

## AC settings

The Atlas plan ("Atlas Power Scheme", `11111111-1111-1111-1111-111111111111`) changes
only these AC values:

| Setting (subgroup) | Setting GUID | AC value | Meaning and limits |
| --- | --- | ---: | --- |
| NVMe NOPPME (Hard disk, `0012ee47-9041-4b5d-9b77-535fba8b1442`) | `fc7372b6-ab2d-43ee-8797-15e9841f2cca` | `0` | Off. A plan setting, not a promise that every storage device avoids low-power states. |
| Allow Throttle States (Processor power management, `54533251-82be-4824-96c1-47b60b740d00`) | `3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb` | `0` | Disabled on AC. Firmware thermal controls still apply. |
| Turn off display after (Display, `7516b95f-f776-4464-8c53-06167f40cc99`) | `3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e` | `0` | Never. Can increase display energy use. |
| Processor performance time check interval (Processor power management, `54533251-82be-4824-96c1-47b60b740d00`) | `4d2b0152-7d5c-498b-88e2-34345392a2c5` | `200` | 200 ms, within the documented Windows range. An Atlas product choice, not a performance or DPC-latency guarantee. |

## What the toggle does not change

| Not changed | Why |
| --- | --- |
| Values under `HKLM\SYSTEM\CurrentControlSet\Enum`, including per-device idle, wake, selective-suspend and D-state values (no writes, deletes or renames) | The right value depends on the device; see [Machines upgraded from older Atlas versions](#machines-upgraded-from-older-atlas-versions). |
| The ACPI Processor Aggregator (`ACPI000C`) | Windows can use it to idle logical processors during thermal mitigation. |
| Devices matched by localized WMI ACPI friendly name; bulk `MSPower_DeviceEnable` changes | No exactly reversible way across hardware. |
| Network-adapter advanced properties, even the standardized `*EEE` and `*SelectiveSuspend` keywords | Left to the adapter, driver, OEM and user; Atlas has no exact per-adapter rollback. |
| `StorageD3InModernStandby` | An OEM/SoC platform policy. |
| StorNVMe `IdlePowerMode` and NDIS `DefaultPnPCapabilities` | Microsoft does not document them for this use. |
| `PowerThrottlingOff` | It has a public Windows policy, but older Atlas versions changed it without recording whether it was absent, `0` or `1`. Leaving it alone keeps rollback exact. |
| Zero values for the NVMe idle timeouts (`d3d55efd-c1ff-424e-9dc3-441be7833010`, `d639518a-e56d-4345-8af2-b9f32fb26109`), USB hub suspend timeout (`0853a681-27c8-4100-a2fd-82013e970683`), USB selective suspend (`48e6b7a6-50f5-4782-a5d4-53bb8f07e226`), USB 3 link power management (`d4e98f31-5ffe-4ce1-be31-1b38b384c009`) and display dim timeout (`17aaa29b-8b43-4b94-aafe-35f64daaf1ee`) | Blanket zeros can defeat low-power behavior that Windows or the platform manages, and older Atlas versions did not restore the exact prior values. |

Some of these are documented for driver, OEM or managed-device use. Atlas omits them
because it has no safe, exactly reversible way to apply them on all hardware, not
because Windows lacks support.

Network adapter power properties belong to a separate setting. The
`atlas-network-settings` install step and
`9. Troubleshooting\Network\Reset Network to Atlas Default.cmd` set
`AutoDisableGigabit`, `ApCompatMode`, `SipsEnabled`, `ReduceSpeedOnPowerDown` and
`DMACoalescing` (plain or `*`-prefixed) to `0` on PCI network adapters that expose
them.

### Machines upgraded from older Atlas versions

Older Atlas versions changed or renamed per-device values under `Enum`. Atlas leaves
them as they are, even in Default Power-saving, because guessing a Windows default is
unsafe: the right value depends on the device, driver package, firmware and OEM
configuration, and an absent value can be meaningful. To fix an affected machine, use
evidence from its OEM or driver package, or validate the fix in a disposable VM that
represents that installation. No compatibility switch restores the old per-device
changes.

## How it works

`Set-AtlasPowerSavingState` in
`playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Hardware\Domain\Power.ps1`
implements both states.

- **Both states** require the Windows Balanced plan
  (`381b4222-f694-41f0-9685-ff5bb260df2e`) and hold the machine-wide
  `Global\AtlasOS.PowerSaving.Transaction.v1` mutex for the whole transaction, so
  concurrent launches cannot interleave rollback state with plan changes. Waiting more
  than 30 seconds fails without changing anything.
- **Rollback value:** before changing any plan, Disable saves the active plan's GUID
  (lowercase, no braces) as a `REG_SZ` at
  `HKLM\SOFTWARE\AtlasOS\Services\PowerSaving\PreviousPowerSchemeGuid`, or Balanced if
  the Atlas plan is already active. An existing value is kept, so a rerun never
  replaces the original target. A value that is not a `REG_SZ` GUID stops the run.
- **Disable** replaces any existing Atlas plan (activating Balanced first if needed)
  with a fresh duplicate of Balanced, sets the four AC values and activates it.
- **Default** activates the saved plan if it is installed and is not the Atlas plan,
  otherwise Balanced, then deletes the Atlas plan.
- **Checks:** every `%SystemRoot%\System32\powercfg.exe` call stops the run on a
  nonzero exit code, and every plan GUID from `powercfg` or the registry is validated.
  The active plan is read back before success is reported. Default removes the saved
  value only after that check.

## Reference sources

These pinned sources document the Windows API and device behavior the policy relies
on.

| Official repository | Reference role |
| --- | --- |
| [MicrosoftDocs/win32](https://github.com/MicrosoftDocs/win32/tree/8e75e578b68b316f488d3a6961dcbecfa5fbee61) | Win32 power-policy concepts and identifiers |
| [MicrosoftDocs/sdk-api](https://github.com/MicrosoftDocs/sdk-api/tree/8dfcd02a4ac3225474f3180609eacb0f349e6770) | Native API contracts for power and device states |
| [MicrosoftDocs/windows-driver-docs](https://github.com/MicrosoftDocs/windows-driver-docs/tree/fd4411dc8b020d92d2da58f2371f20415f0911cb) | PnP registry access rules, WDF idle-value ownership, ACPI000C thermal behavior, and platform power guidance |
| [MicrosoftDocs/windowsserverdocs](https://github.com/MicrosoftDocs/windowsserverdocs/tree/2fb17db01783a5266bde9aeeb7741cb6411fbdf6) | Windows power-configuration and Modern Standby product guidance |
| [microsoft/windows-docs-rs](https://github.com/microsoft/windows-docs-rs/tree/c882d801b7cefbb3e02d8b3c265341441a2207c0) | Generated Windows metadata documentation used to cross-check symbols |
| [microsoft/windows-rs](https://github.com/microsoft/windows-rs/tree/07f344c019b8fdae4d398d4c2591596044cb416a) | Generated Windows bindings used as a source-level cross-check |

Setting names, enumerations and ranges were also checked against the Windows SDK
10.0.26100 policy definitions, the inbox Power ADMX/ADML files and read-only
`powercfg.exe /qh` output. Generated bindings and command output only confirm names
and values; they do not justify undocumented registry or device changes.
