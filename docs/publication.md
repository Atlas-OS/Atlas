# Publication contents

This page is for contributors and maintainers who commit to the repository or prepare a release.
It says what belongs in Git, what stays local, and what to review before a release.

Review staged and unstaged changes separately before committing.
A passing build doesn't approve install behaviour or redistribution rights.
Record release evidence against the exact file hashes, as the [release verification matrix](release-verification-matrix.md) describes.

## Files that belong in Git

- Atlas Manager's source, every catalog under `app/i18n`, source graphics, Cargo manifests and lockfile, the toolchain pin, required resources, and reproducible build and review tools.
- The patched crates under `app/vendor/`: GPUI, and AccessKit's Windows adapter `accesskit_windows`.
  Each keeps its licence texts and an `ATLAS-PATCH.md` that names the upstream version and explains the local changes, so reviewers can check them against upstream.
  Never replace them with build output.
- The Atlas package source, the declared third-party files the package includes with their licence and provenance inventory, and the generated launchers and catalogs the product uses.
- Source, lockfiles and deployment examples for the reports service and its MCP server under `services/`.
- Behavioural tests, CI definitions, portable editor configuration, and lasting architecture, build, testing, compatibility and translation guidance.

Generated catalogs and launcher stubs are committed on purpose; regenerate them when their definitions change.
The binary inventory is a review requirement: a listed hash doesn't establish the corresponding source or permission to redistribute.

## Files that must stay local

- `app/target/`, `target/` under `services/`, `artifacts/`, `lab-output/`, `tests/results/` and `testResults.xml`.
- A local reports service's `data/` (database and received reports) and `web/`.
- Built `.apbx` packages, replacement and temporary archives, release ZIPs, executables, PDBs, and native DLL output that isn't in the package's declared binary inventory.
- Windows ISOs, extracted media, WIM, ESD and SWM files, and mounted image contents.
- VM disks, differencing disks, checkpoints, saved state and exported VMs.
- Credentials, `.env` files with secrets, signing private keys, certificates that contain private keys, access tokens and user-specific application state.
- Installer transcripts, diagnostic logs, screenshots, interface capture JSON, benchmark samples and crash dumps.
- Temporary experiments that no build, test or document uses.
- Local copies of upstream documentation, and copies of an earlier tree kept to compare against during review.

Keep captures in `screenshots/`, `app/screenshots/` or an ignored output folder; source icons and images stay tracked.
Screenshots that a document shows are documentation, not captures: they live in `docs/images/`.
Don't ignore every `.json`, `.xml`, `.png`, `.zip`, `.dll` or `.exe`: some are source files or part of the Atlas package.
Ignore rules don't untrack committed files, so inspect the proposed commit and every new binary.
Never delete a file only because it's untracked.

## Before a release

[Releasing Atlas](releasing.md) lists the release steps in order.
Before the release pull request is merged:

1. Group the changes by install behaviour, media safety, Atlas Manager behaviour, packaging and documentation, and review each group against the previous release.
2. Check that the [automated checks](testing.md) pass and the package passes `Test-Apbx.ps1`, built with every eligibility gate.
3. Include the project licence and the required dependency notices with Atlas Manager.
   Before publishing executables, resolve any missing binary provenance and audit dependency licence obligations.
4. Inspect the rendered interface and complete the [verification matrix](release-verification-matrix.md).
   Record untested behaviour in the release pull request.
5. Check that every feature Atlas Manager labels **Beta** has the same label in its documentation and the release notes.
6. Check the full proposed Git contents for secrets, machine paths and generated files committed by mistake.
7. Ask a maintainer listed in `.github/CODEOWNERS` to approve the release pull request.

## Dependency provenance

**Windows releases.**
Install eligibility uses a shared, reviewed release catalog.
The [Windows release policy](windows-release-policy.md) covers how to update it, the online lookup, and why eligibility isn't an authenticity check.

**Atlas Manager dependencies.**
Atlas Manager embeds its generated dependency notices, also shown in Settings and by `AtlasManager.exe --licenses`.
The production build checks the locked inventory and notice text before compiling.
[The notice workflow](../app/licenses/README.md) covers its conservative scope, pinned supplementary texts and the review that stays manual.
Generated notices are committed source: don't replace them with SPDX labels alone, and don't treat successful generation as meeting every redistribution obligation.

**Timer utilities.**
They're built from pinned source with reviewed narrow patches.
[Their build recipe](../tools/timer/README.md) and accepted manifest map the binaries in the Atlas package to their source.
`AtlasModules/Sources/TimerResolution-source.zip` belongs in the package and its binary inventory; keep it whenever those executables are included.
Reproducible builds and source review don't replace runtime checks of timer behaviour on the release files.
