# Building the Atlas package

How to build and verify the Atlas package (`.apbx`), cross-build the desktop app
from Linux, and prepare releases.

## Prerequisites

- **PowerShell 7** (`pwsh`) for the build tools under `tools/build`. The scripts that
  run on users' PCs target Windows PowerShell 5.1.
- **7-Zip or NanaZip** on `PATH` (`7z`, `7zz`, or the installed 7-Zip) to create the
  `.apbx` archive.

## Quick start

From the repository root:

```
./build.cmd        # Windows (double-clickable)
./build.sh         # Unix shell (pwsh)
pwsh -NoProfile -File tools/build/Build-Playbook.ps1 -LocalTest   # direct
```

Each writes `playbook/Atlas Test.apbx`. The wrappers require `pwsh` and return the build's
exit code, so scripts and CI can call them. Any argument suppresses the pause on failure.

VS Code (`.vscode/launch.json`) and Zed (`.zed/tasks.json`) include `Build Atlas package`
configurations.

## Build options

| Parameter | Meaning |
| --- | --- |
| `-LocalTest` | The wrappers' profile: `-ReplaceOldPlaybook`, `-DontOpenPbLocation`, and removal of `WinverRequirement` and `Verification`. |
| `-FileName <name>` | Output name (default `Atlas Test`). |
| `-ReplaceOldPlaybook` | Replace an existing archive, only after the new one passes verification. |
| `-DontOpenPbLocation` | Do not open Explorer at the built file (CI uses this). |
| `-NoPassword` | Build without the `malte` ZIP password. |
| `-PlaybookPath` / `-OutputPath` | Override the package source or output directory (defaults follow the repository layout). |
| `-Removals <list>` | Strip metadata gates for dev builds (values below). |

`pwsh -File` does not turn commas into an array, so pass `-Removals` from a PowerShell 7
session:

```powershell
& ./tools/build/Build-Playbook.ps1 -Removals @(
    'Requirements', 'WinverRequirement', 'Verification'
) -DontOpenPbLocation
```

| `-Removals` value | Strips from `playbook.conf` |
| --- | --- |
| `Requirements` | `<Requirement>` pre-flight gates |
| `WinverRequirement` | `<SupportedBuilds>` |
| `Verification` | `<ProductCode>` |

## Verifying a build

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` exits 0 when every check passes, 1
otherwise. It checks:

- archive integrity and password;
- no rooted or traversal paths and no duplicate entries;
- exact file-path parity with the source `playbook/` tree, the root layout and tooling
  exclusions;
- configuration matching the source, and valid `playbook.conf`, AME handoff and stamped OEM
  version.

Use `-PlaybookPath` for a non-default source tree. The builder verifies its temporary
archive before publishing it, so a failed build leaves an existing archive unchanged. CI
also runs the verifier independently.

## Linux desktop cross-build

Builds the Windows MSVC desktop app, `AtlasManager.exe`, on Linux with cargo-xwin.

1. Install with your distribution's package manager (the setup script installs no system
   packages): PowerShell 7 (`pwsh`), 7-Zip, `sha256sum`, Rust/rustup, and LLVM with
   `clang-cl`, `lld-link`, `llvm-lib`, `llvm-rc` and `llvm-readobj`. Arch-based systems may
   need an AUR package such as `powershell-bin`; review it before installing.
2. Run `tools/release/setup-linux.sh` by its repository path, from any directory. It finds
   the checkout root and installs the toolchain pinned in `app/rust-toolchain.toml`, the
   Windows target and cargo-xwin.
3. Build from `app/`:

   ```bash
   export XWIN_CACHE_DIR="$(cd .. && pwd -P)/artifacts/xwin"
   export XWIN_ACCEPT_LICENSE=1
   export XWIN_SDK_VERSION=10.0.26100
   export XWIN_CRT_VERSION=14.44.17.14
   pwsh -NoProfile -File tools/Export-DependencyNotices.ps1 -Check
   CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS='-C target-feature=+crt-static' \
     cargo xwin build --release --locked --target x86_64-pc-windows-msvc
   ```

| Pin | Version |
| --- | --- |
| cargo-xwin | 0.23.1 (installed by `setup-linux.sh`) |
| Windows SDK (xwin) | `10.0.26100` (also the `build-rc.sh` default) |
| CRT (xwin) | `14.44.17.14` (also the `build-rc.sh` default) |

- `XWIN_CACHE_DIR` must be absolute. Checkout and cache paths must not contain spaces.
- Unset `RUSTFLAGS` and `CARGO_ENCODED_RUSTFLAGS`; they would override the target-scoped
  static CRT flag, which must reach the Windows build without affecting host tools.

The result is `app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe`; `7z l` shows
its icon, version information and manifest. A Linux link is only a build check: run
installation and recovery checks on Windows.

### Release candidates for testers

`tools/release/build-rc.sh --rc N` builds one tester bundle on Linux:

1. the production Atlas package, with every eligibility gate, verified with
   `Test-Apbx.ps1`;
2. `AtlasManager.exe` built with the `embedded-playbook` feature, carrying exactly that
   package;
3. a ZIP of both, the license notices and a tester note.

Output goes to `artifacts/rc/<version>-rc.N/`, with `SHA256SUMS.txt` beside the ZIP. A
failed run leaves an earlier candidate untouched. The tree must be committed unless you pass
`--allow-dirty`; About and diagnostics then show a `-dirty` commit. Nothing is tagged or
published: post the ZIP and checksum lines by hand. See
[`app/docs/rc-testers-build.md`](../app/docs/rc-testers-build.md) for the design and the
checks still owed on Windows.

A tester build never checks GitHub, downloads, or opens another Atlas package. On first
use it writes its bundled package to the app's Downloads folder and unpacks it through the
ordinary package cache. Testers reinstall Windows between candidates; installed candidates
are not upgraded.

### Production shader export

Linux builds never run FXC or Wine. They copy the Windows-generated bytecode committed
under `app/vendor/gpui-pre-windows/prebuilt/`. That crate's `build.rs` first checks the
SHA-256 of `shaders.hlsl`, `color_text_raster.hlsl` and their shared `alpha_correction.hlsl`,
and fails on a missing or stale export. Windows builds compile their own shaders and warn
when they differ from the export.

Regenerate on Windows with the SDK installed, and commit the complete export after changing
any HLSL input, compiler, compiler flag, profile or entrypoint:

```powershell
pwsh -NoProfile -File app/tools/Export-ShaderBytes.ps1
```

It exports bytecode, input hashes and FXC provenance from Cargo's build-script output for
the exact release build. Desktop app CI also uploads them as `atlas-gpui-shaders`.

## Native assembly

`tools/native/Build-AtlasNative.ps1` precompiles
`Scripts\Modules\Atlas.Core\Native\Atlas.Native.cs`, which the Windows PowerShell scripts
otherwise compile at runtime, into `artifacts\native\Atlas.Native.dll` plus its SHA-256.
It uses the Roslyn `csc.exe` from Visual Studio or Build Tools (found through `vswhere`,
or `-CompilerPath`) with `/deterministic`, so the same source and compiler give
byte-identical output.
`-AllowLegacyCompiler` falls back to the .NET Framework `csc.exe`, whose output is not
reproducible.

The loader only accepts a DLL with a valid Authenticode signature, so unsigned builds are
for local checks, not for release. `-SignCertificateThumbprint` signs with SHA-256 and a
timestamp; the project has no code-signing certificate yet. Options and exit codes are in
the script header.

## CI and releases

The ordinary build workflow produces short-lived review artifacts and publishes nothing.
SxS CAB candidates are separate artifacts; review them before committing them under
`playbook/`.

A canonical `vX.Y.Z` tag matching `playbook.conf` builds and verifies the APBX and release
ZIP, records their hashes and attestations, and creates a draft GitHub release through the
`release` environment. That environment must set the variable `ATLAS_RELEASE_ENABLED` to
`true`.

## Version bumps

`<Version>` in `playbook.conf` is the single source of truth. Bump it with:

```
pwsh tools/build/Set-AtlasVersion.ps1 -Version 0.7.0
```

This sets `<Version>`, rewrites `<Title>` to `Atlas v0.7.0`, moves the previous version
into `<UpgradableFrom>`, and points every `onUpgradeVersions` entry in
`playbook/Configuration/custom.yml` at the new version. Review and commit the diff, then tag
`v0.7.0` to start the release workflow.

## Optional developer setup

`tools/dev/Install-DevProfile.ps1` adds a one-time `$PROFILE` snippet that puts Atlas's
PowerShell modules on `PSModulePath` when you open the repository in VS Code, so
`Import-Module` and IntelliSense resolve. `-Remove` undoes it.
