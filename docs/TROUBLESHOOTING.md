# EBOS Troubleshooting

First stop: `EBOS → 9. Troubleshooting` (on the Desktop folder) and the
`EBOS → 0. EBOS Core` dashboard (`Validate System Health`,
`EBOS Rollback`).

## Quick triage

```powershell
$core = "$env:WINDIR\EBOSModules\Core"
& "$core\EBOS-Validate.ps1"        # 17-check health report
& "$core\EBOS-Rollback.ps1" -List  # what can be rolled back
& "$core\EBOS-Detect.ps1" -WriteReport  # hardware/compatibility facts
```

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| Taskbar missing/white after tweak | Explorer didn't restart cleanly | `EBOS-Taskbar.ps1 -Reset`; the recovery loop already attempted rollback automatically |
| Xbox sign-in broken | Legacy service grouping threshold | removed in EBOS; upgrade path restores defaults (`Set services to defaults.cmd`) |
| Game Bar recording grayed out | Background apps disabled | `EBOS-Validate` reports it; re-enable via `EBOS → 3. General Configuration` |
| Store apps fail to launch | VCLibs removed | playbook re-registers VCLibs automatically; else `Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.VCLibs.140.00` |
| MSI install errors 2502/2503 | Permissions | `9. Troubleshooting → Fix Errors 2502 and 2503.cmd` |
| Network shares invisible | NetBT disabled for file sharing | `6. Advanced Configuration → Services` file-sharing toggle |
| Build not supported message | Non-24H2/25H2 build | EBOS skips incompatible tweaks automatically; update Windows or stay on your legacy setup |
| Defender state unexpected | Installer choice | `7. Security → Defender` toggle |

## Network issues

`9. Troubleshooting → Network` contains the EBOS defaults and Windows
defaults scripts for the network stack.

## Repair install

`9. Troubleshooting → Repair Windows Components.cmd` runs DISM
restore-health + SFC. `Reset this PC` link included for last resort.

## Getting help

- Documentation: <https://docs.ebos.net>
- Discussions: <https://github.com/EBOS/EBOS/discussions>
- Bug reports: use the issue templates (include the EBOS validation
  report + system report)
