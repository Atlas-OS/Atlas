# EBOS Changelog

## 1.0.0 — Unified release

The first **EBOS** release: Revision OS and Atlas OS functionality
merged, refactored and re-branded into one coherent platform.

### Unification

- **One playbook, one product.** The two co-existing legacy playbooks
  (and the duplicated top-level copy of the second one) are gone;
  everything lives in the single EBOS playbook
- **Domain architecture** under `Configuration\`:
  `core · windows · privacy · security · optimization · gaming ·
  network · ui · recovery · misc · scripts` — no legacy silos
- **One authoritative services configuration** merging both legacy
  lists (identical values where overlapping; conflicts resolved toward
  the safest option)
- **One component-removal system** (EBOS signed CAB packages)
- **One browser-installation path** (duplicate download path removed)
- **All `revitool.exe` invocations replaced with native
  implementations**: `powercfg` (hibernate/fast-startup), `fsutil`
  (NTFS), registry (VBS/HVCI, driver updates, update pause, inking,
  background apps, Settings page visibility, TSX), DISM/PowerShell
  (VCLibs restore), service actions (SysMain)
- Third-party companion-tool download removed from the installer
- **Conflict resolved:** the legacy "disable System Restore
  pre-defined config" tweak was **dropped** — it disabled periodic
  restore points, which contradicts EBOS's recovery-first model
  (EBOS Core creates pre-install restore points)

### EBOS Core (new)

- Hardware/OS detection + compatibility gating
  (`EBOS-Detect.ps1`, `core\detect.yml`)
- Pre-change backup with restore point (`EBOS-Backup.ps1`,
  `core\backup.yml`)
- Rollback engine (`EBOS-Rollback.ps1`) — backups, change-sets,
  restore points
- Validation suite — 17 checks (`EBOS-Validate.ps1`, `core\validate.yml`)
- Change log (text + JSONL) for every Core action
- Registry change-sets with prior-value capture → undo
- Dashboard hub (`EBOS-Dashboard.ps1`, `EBOS → 0. EBOS Core`)

### Gaming domain (new)

- Game Mode on (recommended), Game Bar recording off, mouse
  acceleration off, hardware-accelerated GPU scheduling (opt-in)

### Liquid Glass design system (new)

- Token-driven material system (`docs/design-system`)
- 7 materials, 5 quality tiers, GPU/battery/accessibility-aware
  auto-selection (`EBOS-Glass.ps1`)
- Windows implementation tasks (`ui\liquid-glass\`)

### Windows 11 taskbar controller (new)

- Alignment/size/multi-monitor/reset with Explorer-recovery loop
  (`EBOS-Taskbar.ps1`)

### Profiles (new)

- `balanced · performance · gaming · competitive · productivity ·
  privacy · minimal · custom`, each undoable (`EBOS-Profiles.ps1`)

### Branding & cleanup

- Full migration to the EBOS brand; legacy names remain only in the
  license attribution (`docs/ATTRIBUTION.md`)
- Legacy wallpapers/themes paths rebranded; OS/OEM identity = EBOS
- Duplicate/dead files removed (second playbook tree, update tooling
  for the removed companion app, duplicate orchestration indexes)
- Installer feature pages extended with the integrated options
  (removals, appearance, hibernation, maintenance, HAGS, taskbar
  animations)

### CI & validation

- `tools/validate/validate-ebos.py` — YAML syntax, task-reference
  resolution, executable references, option/manifest sync, branding
  scan, secret scan, build-support sync (runs in CI)
- CI workflow fixed (EBOS paths/branding) and gated on validation

### Notes

- Supported builds: 26100 (24H2), 26200 (25H2)
- Component removal still targets fresh installations only
