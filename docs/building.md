# Building the playbook

## Prerequisites

- **PowerShell 7** (`pwsh`) for the build tooling. The shipped payload targets Windows
  PowerShell 5.1, but the build scripts under `tools/build` use pwsh 7.
- **7-Zip or NanaZip** on `PATH` (`7z`, `7zz`, or the installed 7-Zip). Required to create
  the `.apbx` archive.

## Quick start

From the repository root:

```
./build.cmd        # Windows (double-clickable)
./build.sh         # Unix shell (pwsh)
```

Both wrap `tools/build/Build-Playbook.ps1` with the standard `-LocalTest` profile, which
replaces the prior test archive, removes the version/product verification gates, and does
not open Explorer. The resulting `Atlas Test.apbx` is written
inside `playbook/` (i.e. `playbook/Atlas Test.apbx`).

The wrappers require `pwsh` and return the underlying build exit code, so they are safe to
use from other scripts and CI. Passing any argument suppresses the Windows/shell pause on
failure for non-interactive callers.

You can also run the build directly:

```
pwsh tools/build/Build-Playbook.ps1 -ReplaceOldPlaybook -Removals Verification,WinverRequirement
```

Editor integrations are provided for VS Code (`.vscode/launch.json`) and Zed
(`.zed/tasks.json`) — pick a "Build Playbook" configuration.

## Build options

`Build-Playbook.ps1` parameters:

| Parameter | Meaning |
| --- | --- |
| `-LocalTest` | Standard local profile used by `build.cmd`/`build.sh`: replace existing test APBX, remove `WinverRequirement` and `Verification`, and do not open Explorer. |
| `-FileName <name>` | Output name (default `Atlas Test`). |
| `-ReplaceOldPlaybook` | Replace an existing archive only after the new archive passes verification. |
| `-DontOpenPbLocation` | Do not open Explorer at the built file (used by CI and the local wrappers). |
| `-NoPassword` | Build without the `malte` ZIP password. |
| `-PlaybookPath` / `-OutputPath` | Override the playbook dir / output dir (defaults to the repo layout). |
| `-Removals <list>` | Strip selected metadata gates for dev builds. |

`-Removals` values:

| Value | Effect |
| --- | --- |
| `Requirements` | Strip `<Requirement>` pre-flight gates from `playbook.conf`. |
| `WinverRequirement` | Strip `<SupportedBuilds>` from `playbook.conf`. |
| `Verification` | Strip `<ProductCode>` from `playbook.conf`. |

## Verifying a build

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` checks archive integrity and password,
rejects rooted/traversal paths and duplicate file entries, requires exact file-path parity
with the source `playbook/` tree, checks the archive root layout and tooling exclusions,
compares the configuration with the source, and validates `playbook.conf`, the AME handoff,
and the stamped OEM version. Use `-PlaybookPath` when verifying against a non-default source
tree. The builder verifies its temporary archive before publishing it, and CI runs the same
verifier independently. A failed build leaves an existing destination archive unchanged.

## CI and releases

The ordinary build workflow produces short-lived review artifacts and does not publish a
release. SxS CAB candidates are separate artifacts and must be reviewed before they are
committed to the playbook payload.

A canonical `vX.Y.Z` tag matching `playbook.conf` builds and verifies the APBX and release
ZIP, records their hashes and attestations, then creates a draft GitHub release through the
`release` environment. That environment must define `ATLAS_RELEASE_ENABLED=true`.

## Version bumps

`playbook.conf` `<Version>` is the single source of truth. Bump it with:

```
pwsh tools/build/Set-AtlasVersion.ps1 -Version 0.7.0
```

This updates `<Version>`, rewrites `<Title>` to `Atlas v0.7.0`, moves the previous
version into `<UpgradableFrom>`, and rewrites every `onUpgradeVersions` entry in
`playbook/Configuration/custom.yml` to the new version — one command, one commit.
Tagging `v0.7.0` then triggers the release workflow described above.

## Optional developer setup

`tools/dev/Install-DevProfile.ps1` adds a one-time snippet to your PowerShell `$PROFILE`
that puts the Atlas payload modules on `PSModulePath` when you open the repo in VS Code, so
`Import-Module` and IntelliSense resolve. Run `-Remove` to undo it.
