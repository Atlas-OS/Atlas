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
pwsh -NoProfile -File tools/build/Build-Playbook.ps1 -LocalTest
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
| `-Removals <list>` | Strip selected metadata gates for dev builds. Pass arrays from a PowerShell session; native `pwsh -File` arguments do not construct an array from commas. |

For a custom combination, invoke the script from a PowerShell 7 session:

```powershell
& ./tools/build/Build-Playbook.ps1 -Removals @(
    'Requirements', 'WinverRequirement', 'Verification'
) -DontOpenPbLocation
```

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

## Linux desktop cross-build

The desktop app targets Windows MSVC from Linux using cargo-xwin 0.23.1 and
the Rust version in `app/rust-toolchain.toml`. Install PowerShell 7 (`pwsh`),
7-Zip, Rust/rustup and LLVM (including `clang-cl`, `lld-link`, `llvm-lib`,
`llvm-rc` and `llvm-readobj`) using your distribution's supported package
instructions. `sha256sum` is also required. On Arch-based systems, PowerShell
may require an AUR package such as `powershell-bin`; review and install it with
your normal package manager. The setup script does not install system packages.

From any directory, run `tools/release/setup-linux.sh` using its repository path.
It resolves the checkout root and selects the app's pinned toolchain before
installing the Windows target and cargo-xwin. The checkout/cache path must not
contain spaces. Unset `RUSTFLAGS` and `CARGO_ENCODED_RUSTFLAGS`: target-scoped
static CRT flags must reach the Windows build without affecting host tools.

The first successful Linux link used cargo-xwin 0.23.1, SDK `10.0.26100` and
CRT `14.44.17.14` (xwin package identifiers). Use these pins with the absolute
cache path when building from `app/`:

```bash
export XWIN_CACHE_DIR="$(cd .. && pwd -P)/artifacts/xwin"
export XWIN_ACCEPT_LICENSE=1
export XWIN_SDK_VERSION=10.0.26100
export XWIN_CRT_VERSION=14.44.17.14
pwsh -NoProfile -File tools/Export-DependencyNotices.ps1 -Check
CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS='-C target-feature=+crt-static' \
  cargo xwin build --release --locked --target x86_64-pc-windows-msvc
```

The result is `app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe`.
`7z l` shows its icon, version information and manifest. This link is a build
check; run installation and recovery checks on Windows.

### Production shader export

Linux uses the Windows-generated shader bytecode committed under
`app/vendor/gpui-pre-windows/prebuilt/`. It checks SHA-256 hashes of
`shaders.hlsl`, `color_text_raster.hlsl` and their shared `alpha_correction.hlsl`
include before copying the bytecode into the build output. It never runs FXC or
Wine. A missing or stale export fails the build.

On Windows with the SDK installed, regenerate with:

```powershell
pwsh -NoProfile -File app/tools/Export-ShaderBytes.ps1
```

This uses Cargo's reported build-script output for the exact release build,
and exports bytecode, input hashes and FXC provenance together. Desktop app CI
also uploads these files as `atlas-gpui-shaders`. Commit the complete export
after changing any HLSL input, compiler, compiler flag, profile or entrypoint.
The Windows build continues to compile its own shaders and warns on differences
from the committed export.

## Native assembly

The payload compiles `Scripts\Modules\Atlas.Core\Native\Atlas.Native.cs` at runtime.
`tools/native/Build-AtlasNative.ps1` builds the same source ahead of time into
`artifacts\native\Atlas.Native.dll` with the Roslyn `csc.exe` from a Visual Studio or Build
Tools installation (found through `vswhere`, or given with `-CompilerPath`), using
`/deterministic` so the same source and compiler produce byte-identical output, and writes
the SHA-256 beside it. `-SignCertificateThumbprint` signs the DLL with SHA-256 and a
timestamp. The loader only accepts a DLL with a valid Authenticode signature, so an
unsigned build is a local check, not something to ship; the project does not have a
code-signing certificate yet. `-AllowLegacyCompiler` falls back to the .NET Framework
`csc.exe`, whose output is not reproducible.

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
`playbook/Configuration/custom.yml` to the new version. Review the diff before committing.
Tagging `v0.7.0` then triggers the release workflow described above.

## Optional developer setup

`tools/dev/Install-DevProfile.ps1` adds a one-time snippet to your PowerShell `$PROFILE`
that puts the Atlas payload modules on `PSModulePath` when you open the repo in VS Code, so
`Import-Module` and IntelliSense resolve. Run `-Remove` to undo it.
