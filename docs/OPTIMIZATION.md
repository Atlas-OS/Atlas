# EBOS Optimization Guide

Every optimization in EBOS carries a risk classification and, wherever
technically possible, a rollback path.

## Risk classification

| Level | Meaning |
|---|---|
| **SAFE** | No known functional downside |
| **LOW** | Minor trade-off, rarely noticed |
| **MEDIUM** | Notable trade-off (security, features); documented + reversible |
| **HIGH** | Intended for fresh installs / advanced users (component removal) |
| **EXPERIMENTAL** | Possible gains, possible instability (e.g. TSX re-enable) |

## Hardware-aware application

EBOS Core detects the system **before** applying anything
(`core\detect.yml` → `EBOS-Detect.ps1`):

```
CPU · GPU (+perf class) · RAM · SSD/HDD · Windows build · laptop/desktop
network adapters · DPI/monitors · battery · virtualization · UEFI
```

Domains consult this report. The Liquid Glass controller uses the GPU
class and battery state directly. Unsupported builds → `SKIPPED`, no
modification performed.

## CPU & scheduling

- Win32 priority separation tuned for responsiveness (reversible)
- Service-host splitting disabled conservatively
  (legacy threshold reverted — it broke `XboxGipSvc`)
- Power plans: balanced by default; performance/ultimate via profiles

## Memory

- Memory compression disabled (legacy default, documented)
- Background apps disabled (reversible; Xbox Game Bar KGL known issue
  documented and reverted on upgrade)
- **No** placebo working-set hacks

## Storage

- NTFS last-access updates and 8.3 short names disabled (`fsutil`)
- Reserved storage disabled; Storage Sense configured

## Network

- EBOS network settings (TCP stack defaults tuned by Microsoft guidance)
- SMB bandwidth throttling disabled
- Anonymous share access/enumeration restricted (security-positive)

## Input & gaming

- Mouse acceleration off (raw input), Game Mode on, Game Bar
  background recording off, HAGS opt-in
- Timer-resolution tools available in the EBOS folder (not forced)

## Audio & multimedia

- MMCMS configured; "communications ducking" set to *do nothing*

## Boot

- Fast startup/hibernation option-gated (`powercfg /h off|on`)
- Startup delay disabled; shutdown wait decreased

## What EBOS deliberately does NOT do

- No permanent background processes, services, scheduled tasks or
  polling loops created by EBOS itself
- No security-broken defaults (see [SECURITY.md](SECURITY.md))
- No tweaks with only placebo effect
- No forcing of obsolete tweaks on unsupported builds
