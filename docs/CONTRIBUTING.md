# Contributing to EBOS

Thanks for considering a contribution!

## Ways to help

- Reports bugs via the issue templates (attach the EBOS validation +
  system reports)
- Suggest features / tweaks (must have measurable benefit, documented
  risk and a rollback path)
- Improve documentation
- Submit pull requests

## Ground rules

1. **No placebo tweaks.** Every change needs a justified, ideally
   measurable benefit.
2. **Classify risk** (SAFE/LOW/MEDIUM/HIGH/EXPERIMENTAL) in a comment
   on every modification that has trade-offs.
3. **Rollback first.** Changes should be reversible whenever
   technically possible.
4. **Security is not a bargaining chip.** Changes that weaken security
   must be opt-in, documented in `docs/SECURITY.md`.
5. **Hardware-aware.** Build-gated changes must skip gracefully on
   unsupported systems.
6. **One authoritative implementation.** Don't add a second way to do
   something that exists — extend the existing domain file.
7. **Keep EBOS lightweight** — no background processes, services,
   scheduled tasks, polling loops or telemetry from EBOS itself.

## Repository layout

```
src/playbook/            the EBOS playbook (AME Wizard)
  Configuration/         task pipeline (core, windows, privacy, ...)
  Executables/           scripts + the EBOS folder copied to Windows
  playbook.conf          playbook manifest (options, supported builds)
src/sxsc/                signed component-removal package configs
docs/                   documentation + design system
tools/validate/         repository validator (run before every PR)
```

## Before opening a PR

```bash
python3 tools/validate/validate-ebos.py   # must exit 0
```

## Building the playbook locally

- **Windows (official):** `src\playbook\build-playbook.cmd` (uses
  `src\dependencies\local-build.ps1`, requires PowerShell + 7-Zip)
- **Linux/macOS (official):** `src/playbook/build-playbook.sh`
- **Any platform, no PowerShell needed:**
  `python3 tools/build/build-apbx.py --file-name "EBOS Playbook" --output-dir src/release-zip`
  — a faithful port of `local-build.ps1` (same transformations, same
  `malte` password zip). Requires Info-ZIP `zip` or 7-Zip.

All builders produce a renamed password-protected ZIP (`malte`) with the
playbook contents at the archive root, with the OEM version placeholder
substituted from `playbook.conf`.

- YAML: 2-space indent, single quotes for task paths
- PowerShell: 5.1-compatible, `Set-StrictMode -Version 2.0` in Core
  scripts, comment blocks for dangerous operations
- Update `docs/CHANGELOG.md` and relevant docs

## Testing checklist for playbook changes

- [ ] Local build (`src/playbook/build-playbook.cmd|sh`)
- [ ] Fresh VM install (supported build)
- [ ] Upgrade from previous EBOS version
- [ ] Rollback paths exercised (`EBOS-Rollback.ps1 -List`)
- [ ] `EBOS-Validate.ps1` all-PASS (or explained WARN)
