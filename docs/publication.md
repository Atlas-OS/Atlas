# Publication contents

Review staged and unstaged changes separately before preparing commits. A passing
build does not approve the package's installation behavior or redistribution rights.
Use the [release verification matrix](reliability-verification-matrix.md) to record
evidence against the exact candidate hashes.

## Files that belong in Git

- App source, all 15 language catalogs, source graphics, Cargo manifests and lockfile,
  toolchain pin, required resources and reproducible build/review tools.
- The patched GPUI source, its license and patch-maintenance notes. Keep its upstream
  version and local changes reviewable; do not replace it with build output.
- Playbook source, declared third-party payload assets, their license/provenance
  inventory, and the generated launchers and catalogs consumed by the product.
- Behavioral tests, CI definitions, portable editor configuration and durable
  architecture, build, testing, compatibility and translation guidance.

Generated catalogs and launcher stubs are intentional source artifacts. Regenerate
them when their definitions change. The binary inventory is a review requirement;
listing a hash does not establish corresponding source or redistribution permission.

## Files that must stay local

- `app/target/`, `artifacts/`, `lab-output/`, `tests/results/` and `testResults.xml`.
- Built APBX packages and replacement/temporary archives; release ZIPs, executables,
  PDBs and native DLL build output outside the declared payload inventory.
- Windows ISOs, extracted Windows media, WIM/ESD/SWM files and mounted image contents.
- VM disks, differencing disks, checkpoints, saved state and exported VMs.
- Credentials, `.env` files containing secrets, signing private keys, certificates
  containing private keys, access tokens and user-specific application state.
- Installer transcripts, diagnostic logs, screenshots, UI capture JSON, benchmark
  samples, crash dumps and temporary experiments without a documented source role.
- Local upstream documentation caches and review-baseline snapshots.

Keep captures in `screenshots/`, `app/screenshots/` or an ignored output directory.
Source icons and images remain visible to Git. Do not blanket-ignore `.json`, `.xml`,
`.png`, `.zip`, `.dll` or `.exe`: some are intentional source or payload assets.
Ignore rules do not remove files already tracked; inspect the proposed commit contents
and every new binary explicitly. Never delete a file merely because it is untracked.

## Before a release

1. Group changes by installation contracts, media safety, app behavior, packaging and
   documentation. Review each group against the previous release.
2. Run the supported-host tests, generators, analyzers, app checks and APBX verifier.
   Build a package with production eligibility gates intact.
3. Include the project license and required dependency notices in app distributions.
   Resolve missing binary provenance and audit dependency license obligations before
   publishing executable artifacts.
4. Inspect rendered UI and complete the candidate-specific VM/device checks. Keep ISO
   creation and USB writing labelled Beta. Record untested behavior explicitly.
5. Review the complete proposed Git contents for secrets, local paths and accidental
   generated files, then obtain the project's normal release approval.

## Dependency provenance

Windows installation eligibility uses a shared reviewed release catalog. See the
[Windows release policy](windows-release-policy.md) for its update procedure,
network fallback and the distinction between eligibility and media authenticity.

The app embeds its generated dependency notices, also available through Settings and
`AtlasManager.exe --licenses`. The production build checks the locked inventory and notice
text before compilation. See [the notice workflow](../app/licenses/README.md) for its
conservative dependency scope, pinned supplementary texts and remaining manual review
requirements. Generated notices are source artifacts; do not replace them with SPDX
labels alone or treat successful generation as proof of all redistribution obligations.

The timer utilities are built from pinned source and reviewed narrow patches.
[Their build recipe](../tools/timer/README.md) and accepted manifest map the shipped
binaries to corresponding source. `AtlasModules/Sources/TimerResolution-source.zip`
is intentionally included in the payload and its binary inventory. Preserve it when
publishing those executables. Reproducible builds and source inspection do not replace
runtime validation of timer behavior on the release candidate.
