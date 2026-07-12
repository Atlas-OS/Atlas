# Power-saving policy

The Power Saving toggle applies a bounded Atlas **AC power-plan policy**. It does
not claim to disable every device or platform power-saving mechanism. The policy
uses documented Windows power-plan operations, records the user's prior plan, and
changes only four reviewed AC settings. Battery/DC values are not changed.

This narrower contract is intentional. Power policy is hardware-, firmware-, and
driver-dependent; a blanket change can increase energy use and heat without a
universal performance or latency benefit.

## Plan lifecycle and rollback

When Power Saving is disabled, Atlas:

1. enumerates the installed schemes and requires the Windows Balanced scheme
   (`381b4222-f694-41f0-9685-ff5bb260df2e`);
2. reads the active scheme and stores its canonical GUID as a `REG_SZ` at
   `HKLM\SOFTWARE\AtlasOS\Services\PowerSaving\PreviousPowerSchemeGuid` before
   changing any scheme;
3. preserves an existing valid saved value so that rerunning the toggle does not
   replace the original rollback target with the Atlas plan;
4. duplicates Balanced into the Atlas scheme
   (`11111111-1111-1111-1111-111111111111`), applies the reviewed settings, and
   verifies that the Atlas scheme is active.

If Atlas is already active but no prior value exists, Balanced is recorded as the
safe fallback. All `powercfg.exe` calls use checked arguments and exit status, and
the plan list and active-plan postconditions are read back before success is
reported. Disable and Default hold the same machine-wide
`Global\AtlasOS.PowerSaving.Transaction.v1` mutex across the complete saved-state
and power-plan transaction so concurrent launches cannot interleave rollback
state with plan creation or deletion.

The Default action is deliberately not a system-wide reset. It activates the
saved prior scheme when that scheme is still installed and is not the Atlas
scheme; otherwise it activates Balanced. After verifying activation, it deletes
only the Atlas-owned scheme and verifies the final plan state before removing the
saved value. It never invokes `/restoredefaultschemes`, because that operation
deletes the machine's current schemes and their settings rather than undoing only
Atlas's change.

## Retained AC settings

| Setting GUID | AC value | Atlas policy and claim boundary |
| --- | ---: | --- |
| `fc7372b6-ab2d-43ee-8797-15e9841f2cca` | `0` | Sets the documented NVMe NOPPME option to its off value. This is a plan setting, not a promise that every storage device will avoid low-power states. |
| `3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb` | `0` | Sets Allow Throttle States to disabled for AC operation. Firmware thermal controls still apply. |
| `3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e` | `0` | Sets the AC display-idle timeout to Never. This can increase display energy use. |
| `4d2b0152-7d5c-498b-88e2-34345392a2c5` | `200` | Selects a 200 ms processor performance time-check interval within the documented Windows range. This is an Atlas product-policy choice, not a universal performance or DPC-latency guarantee. |

The policy does not reinterpret `0` generically: each retained value is tied to
its specific setting contract.

## Intentionally removed legacy behavior

The hardened policy no longer performs the following broad or non-reversible
operations:

- recursive writes, deletes, or value renames under
  `HKLM\SYSTEM\CurrentControlSet\Enum`, including legacy per-device idle, wake,
  selective-suspend, and D-state values;
- disabling the ACPI Processor Aggregator (`ACPI000C`), which Windows can use for
  logical-processor idling during thermal mitigation;
- disabling devices by the localized WMI ACPI friendly name, or bulk-changing
  `MSPower_DeviceEnable` instances;
- changing vendor-specific network-adapter advanced-property keywords. Even the
  standardized `*EEE` and `*SelectiveSuspend` controls are left to the adapter,
  driver, OEM, and user because Atlas does not have an exact per-adapter rollback
  transaction;
- overriding `StorageD3InModernStandby`, an OEM/SoC platform policy, or writing
  the uncontracted StorNVMe `IdlePowerMode` and NDIS
  `DefaultPnPCapabilities` values;
- writing `PowerThrottlingOff`. The value has a public Windows policy contract,
  but its absent/zero/one state was not captured by the old toggle, so excluding
  it keeps rollback exact and bounded;
- forcing the former NVMe idle-timeout settings
  (`d3d55efd-c1ff-424e-9dc3-441be7833010` and
  `d639518a-e56d-4345-8af2-b9f32fb26109`), USB hub suspend timeout
  (`0853a681-27c8-4100-a2fd-82013e970683`), USB selective suspend
  (`48e6b7a6-50f5-4782-a5d4-53bb8f07e226`), USB 3 link power management
  (`d4e98f31-5ffe-4ce1-be31-1b38b384c009`), or display dim timeout
  (`17aaa29b-8b43-4b94-aafe-35f64daaf1ee`) to zero. Those blanket values can
  defeat Windows or platform-managed low-power behavior and were not restored to
  their exact prior state.

Some of these controls are documented for a driver, OEM, or targeted management
scenario. Their removal from Atlas is not a claim that Windows does not support
them; it means the legacy cross-hardware implementation did not have a safe,
exactly reversible contract.

### Legacy installation state

Values or value-name changes made by an older recursive `Enum` implementation
cannot be safely auto-restored by guessing a Windows default. The correct value
can depend on the exact device, driver package, firmware, and OEM configuration,
and an absent value may itself be meaningful. Atlas therefore neither deletes nor
rewrites those legacy entries during Default. Remediation requires evidence for
the affected hardware from its OEM/driver package or validation in a disposable
VM representative of that installation. There is no compatibility switch that
reenables the unsafe legacy mutation path.

## Reviewed primary-source snapshots

The policy was reviewed against clean, official repositories in the managed local
source workspace. Each local `HEAD` matched the commit below on 2026-07-11.

| Official repository | Local snapshot under `D:\git\docs` | Reviewed commit | Review role |
| --- | --- | --- | --- |
| [MicrosoftDocs/win32](https://github.com/MicrosoftDocs/win32/tree/8e75e578b68b316f488d3a6961dcbecfa5fbee61) | `sources\github\MicrosoftDocs\win32` | `8e75e578b68b316f488d3a6961dcbecfa5fbee61` | Win32 power-policy concepts and identifiers |
| [MicrosoftDocs/sdk-api](https://github.com/MicrosoftDocs/sdk-api/tree/8dfcd02a4ac3225474f3180609eacb0f349e6770) | `sources\github\MicrosoftDocs\sdk-api` | `8dfcd02a4ac3225474f3180609eacb0f349e6770` | Native API contracts for power and device-state boundaries |
| [MicrosoftDocs/windows-driver-docs](https://github.com/MicrosoftDocs/windows-driver-docs/tree/fd4411dc8b020d92d2da58f2371f20415f0911cb) | `sources\github\MicrosoftDocs\windows-driver-docs` | `fd4411dc8b020d92d2da58f2371f20415f0911cb` | PnP registry access rules, WDF idle-value ownership, ACPI000C thermal behavior, and platform power guidance |
| [MicrosoftDocs/windowsserverdocs](https://github.com/MicrosoftDocs/windowsserverdocs/tree/2fb17db01783a5266bde9aeeb7741cb6411fbdf6) | `sources\github\MicrosoftDocs\windowsserverdocs` | `2fb17db01783a5266bde9aeeb7741cb6411fbdf6` | Windows power-configuration and Modern Standby product guidance |
| [microsoft/windows-docs-rs](https://github.com/microsoft/windows-docs-rs/tree/c882d801b7cefbb3e02d8b3c265341441a2207c0) | `sources\github\microsoft\windows-docs-rs` | `c882d801b7cefbb3e02d8b3c265341441a2207c0` | Generated Windows metadata documentation used to cross-check symbols |
| [microsoft/windows-rs](https://github.com/microsoft/windows-rs/tree/07f344c019b8fdae4d398d4c2591596044cb416a) | `sources\github\microsoft\windows-rs` | `07f344c019b8fdae4d398d4c2591596044cb416a` | Generated Windows bindings used as a source-level cross-check |

Setting names, enumerations, and ranges were additionally cross-checked against
the Windows SDK 10.0.26100 policy definitions, the inbox Power ADMX/ADML files,
and read-only `powercfg.exe /qh` output. Generated bindings and local host output
were corroborating evidence; they were not treated as permission for undocumented
registry or device mutations.
