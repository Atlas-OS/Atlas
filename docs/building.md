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
enables the live log, replaces the prior test archive, removes the version/product
verification gates, and does not open Explorer. The resulting `Atlas Test.apbx` is written
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
| `-LocalTest` | Standard local profile used by `build.cmd`/`build.sh`: live log, replace existing test APBX, remove `WinverRequirement` and `Verification`, and do not open Explorer. |
| `-FileName <name>` | Output name (default `Atlas Test`). |
| `-ReplaceOldPlaybook` | Overwrite an existing archive of the same name. |
| `-AddLiveLog` | Inject a console action that tails AME Wizard's `OutputBuffer.txt` during install. |
| `-DontOpenPbLocation` | Do not open Explorer at the built file (used by CI and the local wrappers). |
| `-NoPassword` | Build without the `malte` ZIP password. |
| `-PlaybookPath` / `-OutputPath` | Override the playbook dir / output dir (defaults to the repo layout). |
| `-Removals <list>` | Strip content for dev builds so they install on unsupported machines. |

`-Removals` values:

| Value | Effect |
| --- | --- |
| `Dependencies` | Strip the `NO LOCAL BUILD` block from `atlas/start.yml` (DISM/download steps that only work in a real install). |
| `Requirements` | Strip `<Requirement>` pre-flight gates from `playbook.conf`. |
| `WinverRequirement` | Strip `<SupportedBuilds>` from `playbook.conf`. |
| `Verification` | Strip `<ProductCode>` from `playbook.conf`. |

## Verifying a build

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` checks archive integrity and password,
rejects rooted/traversal paths and duplicate file entries, requires exact file-path parity
with the source `playbook/` tree, checks the archive root layout and tooling exclusions,
and validates `playbook.conf` plus the stamped OEM version. Use `-PlaybookPath` when
verifying against a non-default source tree. CI runs it on every build.

## Version bumps

`playbook.conf` `<Version>` is the single source of truth. Bump it with:

```
pwsh tools/build/Set-AtlasVersion.ps1 -Version 0.7.0
```

This updates `<Version>`, rewrites `<Title>` to `Atlas v0.7.0`, and moves the previous
version into `<UpgradableFrom>` — one edit, one commit. Tagging `v0.7.0` then triggers the
release workflow, which asserts the tag matches `<Version>` before building.

## Optional developer setup

`tools/dev/Install-DevProfile.ps1` adds a one-time snippet to your PowerShell `$PROFILE`
that puts the Atlas payload modules on `PSModulePath` when you open the repo in VS Code, so
`Import-Module` and IntelliSense resolve. Run `-Remove` to undo it.
