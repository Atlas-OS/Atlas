# Publication contents

What belongs in Git, what stays local, and what to check before a release. Review staged
and unstaged changes separately before committing. A passing build does not approve
installation behavior or redistribution rights; record evidence against the exact candidate
hashes in the [release verification matrix](reliability-verification-matrix.md).

## Files that belong in Git

- App source, all 15 language catalogs, source graphics, Cargo manifests and lockfile,
  toolchain pin, required resources, and reproducible build and review tools.
- The patched crates under `app/vendor/` (GPUI, and AccessKit's Windows adapter
  `accesskit_windows`), each with its license texts and an `ATLAS-PATCH.md` that names the
  upstream version and explains the local changes, keeping them reviewable. Never replace
  them with build output.
- Atlas package source, the declared third-party files the package includes and their
  license and provenance inventory, and the generated launchers and catalogs the product
  uses.
- Source, lockfiles and deployment examples for the reports service and its MCP server
  under `services/`.
- Behavioral tests, CI definitions, portable editor configuration, and long-term
  architecture, build, testing, compatibility and translation guidance.

Generated catalogs and launcher stubs are intentional source artifacts; regenerate them
when their definitions change. The binary inventory is a review requirement: a listed hash
does not establish corresponding source or redistribution permission.

## Files that must stay local

- `app/target/`, `target/` under `services/`, `artifacts/`, `lab-output/`, `tests/results/`
  and `testResults.xml`.
- A local reports service's `data/` (database and received reports) and `web/`.
- Built APBX packages, replacement and temporary archives, release ZIPs, executables, PDBs,
  and native DLL output not listed in the package's declared binary inventory.
- Windows ISOs, extracted media, WIM/ESD/SWM files and mounted image contents.
- VM disks, differencing disks, checkpoints, saved state and exported VMs.
- Credentials, `.env` files with secrets, signing private keys, certificates containing
  private keys, access tokens and user-specific application state.
- Installer transcripts, diagnostic logs, screenshots, UI capture JSON, benchmark samples,
  crash dumps and temporary experiments without a documented source role.
- Local upstream documentation caches and review-baseline snapshots.

Keep captures in `screenshots/`, `app/screenshots/` or an ignored output directory; source
icons and images stay tracked. Do not blanket-ignore `.json`, `.xml`, `.png`, `.zip`, `.dll`
or `.exe`: some are source files or part of the Atlas package. Ignore rules do not untrack
committed files, so inspect the proposed commit and every new binary explicitly. Never
delete a file merely because it is untracked.

## Before a release

1. Group changes by installation contracts, media safety, app behavior, packaging and
   documentation; review each group against the previous release.
2. Run the supported-host tests, generators, analyzers, app checks and APBX verifier.
   Build with production eligibility gates intact.
3. Include the project license and required dependency notices with app distributions.
   Before publishing executables, resolve missing binary provenance and audit dependency
   license obligations.
4. Inspect the rendered UI and complete the candidate's VM and device checks. Keep ISO
   creation and USB writing labelled Beta. Record untested behavior explicitly.
5. Check the full proposed Git contents for secrets, local paths and accidental generated
   files, then get the project's normal release approval.

## Dependency provenance

**Windows releases.** Installation eligibility uses a shared, reviewed release catalog. The
[Windows release policy](windows-release-policy.md) covers its update procedure, network
fallback, and why eligibility is not an authenticity check.

**App dependencies.** The app embeds its generated dependency notices, also shown in
Settings and by `AtlasManager.exe --licenses`. The production build checks the locked
inventory and notice text before compiling. [The notice workflow](../app/licenses/README.md)
covers its conservative scope, pinned supplementary texts and remaining manual review.
Generated notices are source artifacts: do not replace them with SPDX labels alone, and do
not treat successful generation as meeting every redistribution obligation.

**Timer utilities.** Built from pinned source with reviewed narrow patches;
[their build recipe](../tools/timer/README.md) and accepted manifest map the binaries the
Atlas package includes to their source. `AtlasModules/Sources/TimerResolution-source.zip`
belongs in the package and its binary inventory; keep it whenever those executables are
included. Reproducible builds and source review do not replace runtime validation of timer
behavior on the release candidate.
