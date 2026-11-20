# Building the Atlas package

This page is for contributors and maintainers who build the Atlas package (`.apbx`), verify it, or cross-build Atlas Manager from Linux.
[Releasing Atlas](releasing.md) puts these builds in order for a release.

## Prerequisites

- **PowerShell 7** (`pwsh`) for the build tools under `tools/build`.
  The scripts that run on users' PCs target Windows PowerShell 5.1.
- **7-Zip or NanaZip** on `PATH` (`7z`, `7zz`, or the installed 7-Zip) to create the `.apbx` archive.

## Quick start

From the repository root, run one of these:

```powershell
.\build.cmd
pwsh -NoProfile -File tools/build/Build-Playbook.ps1 -LocalTest
```

```sh
./build.sh
```

Each writes `playbook/Atlas Test.apbx`.
You can also double-click `build.cmd`.
The wrappers need `pwsh` and return the build's exit code, so scripts and CI can call them.
They pause when a build fails.
Pass any argument, for example `build.cmd ci`, to skip the pause on failure.

VS Code (`.vscode/launch.json`) and Zed (`.zed/tasks.json`) include `Build Atlas package` configurations.

## Build options

| Parameter | Meaning |
| --- | --- |
| `-LocalTest` | The wrappers' profile: `-ReplaceOldPlaybook`, `-DontOpenPbLocation` and the `WinverRequirement` removal. |
| `-FileName <name>` | Output name (default `Atlas Test`). |
| `-ReplaceOldPlaybook` | Replace an existing archive, only after the new one passes verification. |
| `-DontOpenPbLocation` | Don't open File Explorer at the built file (CI uses this). |
| `-NoPassword` | Build without the `malte` ZIP password. |
| `-PlaybookPath` / `-OutputPath` | Override the package source or output folder (defaults follow the repository layout). |
| `-Removals <list>` | Strip eligibility gates for development builds (values below). |

`pwsh -File` doesn't turn commas into an array, so pass `-Removals` from a PowerShell 7 session:

```powershell
& ./tools/build/Build-Playbook.ps1 -Removals @('Requirements', 'WinverRequirement') -DontOpenPbLocation
```

| `-Removals` value | Strips from `playbook.conf` |
| --- | --- |
| `Requirements` | `<Requirement>` pre-flight gates |
| `WinverRequirement` | `<SupportedBuilds>` |

> [!WARNING]
> The front door refuses a package without `<SupportedBuilds>`, so `-LocalTest` builds and builds with the `WinverRequirement` removal can't install Atlas.
> Use them for archive checks only, and build releases with every gate.

## Verifying a build

`tools/build/Test-Apbx.ps1 -Path "<file>.apbx"` exits 0 when every check passes, and 1 otherwise.
It checks:

- archive integrity and the password;
- that no entry has a rooted or traversal path, and no entry appears twice;
- exact file-path parity with the source `playbook/` tree, the root layout and the tooling exclusions;
- that `playbook.conf` parses and its title carries its version;
- that the build stamped the Atlas version into the OEM information script.

Use `-PlaybookPath` for a source tree other than `playbook/`.
The builder verifies its temporary archive before publishing it, so a failed build leaves an existing archive unchanged.
CI also runs the verifier on its own.

## Build Atlas Manager on Windows

Atlas Manager builds with Cargo and `app/tools/Build-Release.ps1`.
The [Atlas Manager README](../app/README.md) lists the prerequisites, the build and test commands, and the stable and tester variants.

## Linux desktop cross-build

You can build the Windows MSVC Atlas Manager, `AtlasManager.exe`, on Linux with cargo-xwin.

1. Install these with your distribution's package manager: PowerShell 7 (`pwsh`), 7-Zip, `sha256sum`, Rust and rustup, and LLVM with `clang-cl`, `lld-link`, `llvm-lib`, `llvm-rc` and `llvm-readobj`.
   The setup script installs no system packages.
   Arch-based systems may need an AUR package such as `powershell-bin`; review it before installing.
2. Run `tools/release/setup-linux.sh` by its repository path, from any folder.
   It finds the checkout root and installs the toolchain pinned in `app/rust-toolchain.toml`, the Windows target and cargo-xwin.
3. Build from `app/`:

   ```sh
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

- `XWIN_CACHE_DIR` must be absolute.
  Checkout and cache paths mustn't contain spaces.
- Unset `RUSTFLAGS` and `CARGO_ENCODED_RUSTFLAGS`.
  They would override the target-scoped static CRT flag, which must reach the Windows build without affecting host tools.

The result is `app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe`.
`7z l` shows its icon, version information and manifest.
A Linux link is only a build check: run install and recovery checks on Windows.

### Production shader export

Linux builds never run FXC or Wine.
They copy the Windows-generated bytecode committed under `app/vendor/gpui-pre-windows/prebuilt/`.
That crate's `build.rs` first checks the SHA-256 of `shaders.hlsl`, `color_text_raster.hlsl` and their shared `alpha_correction.hlsl`, and fails on a missing or stale export.
Windows builds compile their own shaders and warn when they differ from the export.

Regenerate the export on Windows with the SDK installed.
Commit the complete export after changing any HLSL input, compiler, compiler flag, profile or entry point:

```powershell
pwsh -NoProfile -File app/tools/Export-ShaderBytes.ps1
```

It exports bytecode, input hashes and FXC provenance from Cargo's build-script output for the exact release build.
Atlas Manager CI also uploads them as `atlas-gpui-shaders`.

## Tester builds

A tester build is an `AtlasManager.exe` that carries one Atlas package and installs nothing else.
Maintainers give tester builds to testers as release candidates.
`tools/release/build-rc.sh` builds one tester bundle on Linux, with the toolchain from the [Linux desktop cross-build](#linux-desktop-cross-build):

```sh
tools/release/build-rc.sh --rc <n> [--allow-dirty] [--toolbox <installer> --toolbox-version <x.y.z>]
```

| Option | Meaning |
| --- | --- |
| `--rc <n>` | The candidate number, a positive integer. The candidate ID is `<version>-rc.<n>`, with the version from `playbook.conf`. |
| `--allow-dirty` | Build even with uncommitted changes to tracked files. The candidate then can't be published. |
| `--toolbox <installer>` | Put that AtlasOS Toolbox installer in the package, so installing the Toolbox uses it instead of the latest Toolbox release on GitHub. Use it when the candidate needs a Toolbox that isn't published. |
| `--toolbox-version <x.y.z>` | The version of the installer `--toolbox` names. Required with `--toolbox`. |

The script stops before building anything if the `[package]` version in `app/Cargo.toml` differs from `playbook.conf`'s.
Otherwise it builds:

1. the production Atlas package, with every eligibility gate, built from the commit's `playbook/` rather than the working tree, and verified with `Test-Apbx.ps1`;
2. `AtlasManager.exe` built with the `embedded-playbook` feature, carrying exactly that package;
3. a ZIP of both, the licence notices and a tester note, `README-RC.txt`, which names any bundled Toolbox version.

Output goes to `artifacts/rc/<version>-rc.<n>/`, with `SHA256SUMS.txt` beside the ZIP.
A failed run leaves an earlier candidate untouched.
With `--allow-dirty` and uncommitted changes to tracked files, it builds from the working tree, untracked files included.
About, diagnostics and `README-RC.txt` then show a `-dirty` commit.
Without such changes it still builds from the commit, so untracked files stay out.

Nothing is tagged or published: post the ZIP and the checksum lines by hand.
[Tester builds](../app/docs/rc-testers-build.md) covers the design, what the build disables, and the Windows checks it requires.

A tester build never checks GitHub, downloads, or opens another Atlas package.
On first use it writes its bundled package to the app's Downloads folder and unpacks it through the ordinary package cache.
Every candidate of a release has the same version, so moving to the next one is a reinstall.
On Home, choose **Reinstall Atlas**, then **Keep my choices** or **Choose again**, as [Updating Atlas](upgrading.md) describes.

## Native assembly

`tools/native/Build-AtlasNative.ps1` precompiles `Scripts\Modules\Atlas.Core\Native\Atlas.Native.cs` into `artifacts\native\Atlas.Native.dll` with its SHA-256.
Without the DLL, the Windows PowerShell scripts compile that source at runtime.
The script uses the Roslyn `csc.exe` from Visual Studio or Build Tools, found through `vswhere` or given with `-CompilerPath`.
It compiles with `/deterministic`, so the same source and compiler give byte-identical output.
`-AllowLegacyCompiler` falls back to the .NET Framework `csc.exe`, whose output isn't reproducible.

The loader accepts only a DLL with a valid Authenticode signature, so unsigned builds are for local checks, not for release.
`-SignCertificateThumbprint` signs with SHA-256 and a timestamp.
The script header lists the options and exit codes.

## CI and release builds

The ordinary build workflow, `.github/workflows/build.yml`, produces short-lived review artifacts and publishes nothing.
It builds a CI package without `<SupportedBuilds>` (the `WinverRequirement` removal), so that package can't install Atlas.
SxS CAB candidates are separate artifacts; review them before committing them under `playbook/`.

A `v<version>` tag starts the release workflow, `.github/workflows/release.yml`.
It builds and verifies the Atlas package, the release ZIP and the stable `AtlasManager.exe`, records their hashes, attests them and creates a draft release.
The release files are `Atlas-v<version>.apbx`, `Atlas-v<version>.zip` and `AtlasManager.exe`.
Their names have no spaces, because GitHub renames asset files that do, and `SHA256SUMS.txt` would then name files the release doesn't have.
[Releasing Atlas](releasing.md) covers the version bump, the tag and publishing.

## Optional developer setup

`tools/dev/Install-DevProfile.ps1` adds a one-time `$PROFILE` snippet.
It puts Atlas's PowerShell modules on `PSModulePath` when you open the repository in VS Code, so `Import-Module` and IntelliSense resolve.
`-Remove` undoes it.
