# EBOS Recovery & Rollback

Every meaningful EBOS modification is reversible whenever technically
possible.

## Layers of safety

1. **Pre-change backup** (`core\backup.yml` → `EBOS-Backup.ps1 -PreInstall`)
   - restore point "EBOS pre-install" (best effort — Windows limits
     checkpoints to once per 24 h)
   - registry exports: services hive, policies, Explorer keys
   - scheduled-task state snapshot
   - location: `%WINDIR%\EBOSModules\Backups\<timestamp>-pre-install\`
2. **Per-action change-sets** — Core scripts capture prior values of
   every registry write (`changeset-*.json`) → one-command undo
3. **Post-change service backup** (`recovery\backup-services.yml`) —
   the post-EBOS service state for reference/restore
4. **Windows RE verification** — validation checks recovery is available

## Commands

```powershell
$core = "$env:WINDIR\EBOSModules\Core"

# view everything recoverable
& "$core\EBOS-Rollback.ps1" -List

# restore the newest full backup
& "$core\EBOS-Rollback.ps1" -Latest

# restore a specific backup
& "$core\EBOS-Rollback.ps1" -Name 20260826-120000-pre-install

# undo the last taskbar / glass / profile change-set
& "$core\EBOS-Rollback.ps1" -UndoChangeSet taskbar
& "$core\EBOS-Profiles.ps1" -Undo

# fresh backup at any time
& "$core\EBOS-Backup.ps1"
```

All actions are appended to the EBOS change log:

```
%WINDIR%\EBOSModules\Other\ebos-change-log.txt    (human)
%WINDIR%\EBOSModules\Other\ebos-change-log.jsonl  (machine)
```

Example entries:

```
[2026-08-26 12:00:31] [UI] [SUCCESS] Registry: TaskbarAl in ...Advanced -> 0 (rollback: AVAILABLE)
[2026-08-26 12:00:34] [UI] [SUCCESS] Explorer restarted successfully; taskbar validated.
```

## System restore points

`Get-ComputerRestorePoint` lists EBOS restore points; restore via
`rstrui.exe` (Safe Mode works too).

## Validation

`EBOS-Validate.ps1` checks boot, Explorer, taskbar, Liquid Glass,
network, DNS, audio, GPU, storage, Windows Update, Store, Defender,
Bluetooth, USB, sleep, recovery and EBOS Core — writing
`validation-report.txt`. Failures identify the responsible module and
are logged; run rollback if needed, then revalidate.

## Known non-reversible changes

- **Component/WinSxS removal** (`components.yml`, signed CABs) —
  intended for fresh installs only; reinstall Windows to undo
- **AppX removals** — most apps reinstall from the Microsoft Store
- **Microsoft Edge removal** — opt-in; reinstall via official installer

## Troubleshooting recovery

- Explorer not starting: `EBOS-Taskbar.ps1 -Reset`, then reboot
- Playbook interrupted: re-run the playbook (upgrade path handles
  cleanup); Windows Update/service state restored from backups
- "Safe Mode" entry in `9. Troubleshooting` for offline repairs
