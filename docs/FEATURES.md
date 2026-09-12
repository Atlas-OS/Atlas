# EBOS Features

EBOS is a **unified** Windows optimization platform. It merges two
legacy projects — a performance/usability playbook and a
privacy/usability playbook — into one coherent system with a single
Core, single service list, single design language and single recovery
model. Neither legacy project exists as a separate product or mode.

## EBOS Core (`Configuration\core`, `EBOSModules\Core`)

- Hardware & OS detection: Windows build/edition/arch, CPU, GPU (with
  performance class), RAM, storage media, chassis (laptop/desktop),
  UEFI/BIOS, virtualization, battery, network adapters
- Compatibility verdict per supported build — unsupported tweaks are
  skipped with a logged notice, never forced
- Change log (text + JSONL) for every Core action
- Registry change-sets with prior-value capture → undo
- Backup/rollback engine (registry exports + scheduled-task states +
  system restore points)
- System validation suite (17 checks)

## Domains

| Domain | Highlights |
|---|---|
| **Windows** | Win32/AppX/WinSxS package removal, component removal (signed CABs), unified service list, Windows Update policy, debloat, scheduled tasks, Storage Sense, OS identity |
| **Privacy** | Telemetry policies, diagnostics, advertising ID, activity feed, Recall snapshots, speech/inking personalization, app telemetry (NVIDIA/Office), cloud sync, hosts-based telemetry filtering |
| **Security** | BitLocker policy, VBS/HVCI (opt-out), SAM enumeration hardening, remote assistance off, UAC secure desktop (documented, reversible) |
| **Optimization** | Boot config, crash control, kernel, MMCSS, multimedia, power, NTFS (last-access, 8.3), memory compression, background apps, service-host split, Win32 priority separation, startup/shutdown |
| **Gaming** | Game Mode (on, recommended), Game Bar background recording (off), mouse acceleration (off), hardware-accelerated GPU scheduling (opt-in) |
| **Network** | TCP/EBOS network settings, SMB throttling off, anonymous access/enum restricted |
| **UI** | Explorer, Start, shell, context menus, Windows 11 taskbar, accessibility, **Liquid Glass** |
| **Recovery** | Post-change service backup, Windows RE verification, legacy reverts |

## Windows 11 taskbar experience

- Alignment: centered (default) / left — global + per-monitor
- Size: small / default / large (DPI-aware 100–200%)
- Multi-monitor: all monitors / primary only, survives reconnect/rearrange
- Materials: Clear / Tinted / Dark / Light / Automatic glass + opaque fallback
- Pins, tray, Wi-Fi, volume, battery, Bluetooth, notifications, clock
- Explorer-recovery loop: restart → validate → rollback last taskbar
  change → restart → validate
- Reset (taskbar or appearance) without touching other optimizations

See [TASKBAR.md](TASKBAR.md).

## Liquid Glass design system

- 7 centralized materials, token-driven (`docs/design-system`)
- Quality tiers: Ultra / High / Balanced / Performance / Compatibility
- GPU-aware, battery-aware, accessibility-aware automatic selection
- Reduced transparency / reduced motion → simplified material, never forced

See [LIQUID-GLASS.md](LIQUID-GLASS.md).

## Profiles

`balanced · performance · gaming · competitive · productivity · privacy ·
minimal · custom` — each profile configures optimization **and**
appearance together, and can be undone
(`EBOS-Profiles.ps1 -Undo`).

## Safe debloat

Detect → explain → categorize → selectively remove → back up → validate.
Windows Update, Microsoft Store, sign-in and core features keep working
unless you explicitly choose otherwise.

## What was consolidated during the merge

- **One services implementation** (union of both legacy lists, safest
  shared values, single authoritative file)
- **One component-removal system** (EBOS signed CAB packages; the legacy
  external-tool-based system-package removal was removed)
- **One browser-installation path** (option-gated installer script;
  duplicate direct-download path removed)
- **All external companion-tool invocations replaced with native
  implementations** (powercfg, fsutil, registry, DISM, PowerShell)
- **One wallpaper/theme system** (EBOS paths, EBOS branding)
- Duplicated top-level copy of the second legacy playbook deleted
