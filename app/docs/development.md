# Developing Atlas Manager

This page covers building, testing and releasing Atlas Manager, and what CI checks on every change.
It's for contributors; the [Atlas Manager README](../README.md) lists the requirements.

## Build and run

Run Cargo from `app/`.

```powershell
cargo run
```

`cargo run` makes a development build, which optimises dependencies but keeps Atlas's own debugging information.
Use the release executable for distribution and for [performance measurements](performance.md).

`rust-toolchain.toml` pins the compiler and `Cargo.lock` pins the dependencies, so local and CI builds agree.
The first build compiles GPUI and takes a few minutes.

## Test

```powershell
cargo test --locked
```

- Unit tests cover the services, pages, the install flow and the language catalogs.
- The model tests in `src/model/tests/` run the real model in headless GPUI with controlled adapters ([architecture](architecture.md#tests)).
- The installer tests start Windows PowerShell 5.1 against harmless stub scripts in a temporary folder; nothing is installed.
- The catalog gate checks every catalog and every `t!` call; run it alone with `cargo test --bin AtlasManager catalog_checks` ([languages](i18n.md)).

The Pester tests for the scripts in `tools/` run under PowerShell 7 with Pester 5.7.1:

```powershell
Invoke-Pester tools/tests
```

### Before a pull request

Run the checks CI runs first:

```powershell
cargo fmt --all -- --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
```

### Tester-build checks

CI also runs Clippy and the tests with the `embedded-playbook` feature, which compiles an Atlas package into the executable.
To run them locally, build a LocalTest package and point the build at it.
A LocalTest package is an Atlas package built with `-LocalTest`, which leaves out the supported-build and product-code checks so tests can unpack it anywhere.

```powershell
pwsh -NoProfile -File ..\tools\build\Build-Playbook.ps1 -LocalTest
$env:ATLAS_EMBED_APBX = (Resolve-Path '..\playbook\Atlas Test.apbx').Path
$env:ATLAS_RC_ID = '<version>-rc.1'
cargo clippy --locked --all-targets --features embedded-playbook -- -D warnings
cargo test --locked --features embedded-playbook
```

`ATLAS_RC_ID` must start with the `[package]` version in `app/Cargo.toml`.
The tests never install the package; they only unpack it into a temporary folder.

## Release build

```powershell
pwsh -NoProfile -File tools/Build-Release.ps1
```

`tools/Build-Release.ps1` first checks that the third-party notices are current (`tools/Export-DependencyNotices.ps1 -Check`, see [licence notices](../licenses/README.md)).
It then builds `target/x86_64-pc-windows-msvc/release/AtlasManager.exe` with a static C runtime, so a clean Windows installation needs no Visual C++ runtime.

- The explicit Cargo target keeps the static runtime setting out of host build scripts and procedural macros.
- The script sets `CARGO_INCREMENTAL=0`, because stale incremental state can break the release link step.

| Parameters | Builds |
| --- | --- |
| None | The stable executable. |
| `-RcId <id> -EmbedApbx <path>` | A tester build, with `ATLAS_RC_ID` and `ATLAS_EMBED_APBX` set and `--features embedded-playbook` added. |
| `-Json` | The stable executable, with Cargo's JSON diagnostics. |

### Tester builds

A tester build carries one Atlas package inside the executable and installs nothing else.
Its RC id (release-candidate id), such as `<version>-rc.<n>`, labels the build for testers, and `build.rs` fails unless both variables are set.

```powershell
pwsh -NoProfile -File tools/Build-Release.ps1 -RcId <version>-rc.<n> -EmbedApbx "..\playbook\Atlas v<version>-rc.<n>.apbx"
```

This builds the executable only, for local checks.
[Tester builds](rc-testers-build.md) covers producing the tester ZIP, what the build disables and where the RC id appears.

### Linux cross-builds

On Linux, `../tools/release/build-rc.sh` produces the tester ZIP.
`../tools/release/setup-linux.sh` and the [Linux desktop cross-build](../../docs/building.md#linux-desktop-cross-build) replace the Visual Studio tools.
`llvm-rc` compiles the icon and manifest, and the shaders come from the committed Windows export ([precompiled shaders](../vendor/gpui-pre-windows/ATLAS-PATCH.md#precompiled-shaders-for-linux-builds)).

## CI

`.github/workflows/app.yml` runs on changes under `app/`, and on changes to the files outside it that the app or its tests compile in or read.
Those include `playbook.conf`, the front door, the diagnostics collector and the shared test fixtures, and the workflow's path filter lists them all.

The workflow:

1. checks formatting;
2. runs Clippy, with warnings as errors, and the tests;
3. builds a LocalTest Atlas package, and runs Clippy and the tests again with `--features embedded-playbook`;
4. builds the release executable and saves it, with the licence notices, as `atlas-manager-windows-x64`;
5. exports the production shader bytecode and saves it as `atlas-gpui-shaders`.

The Pester tests in `tools/tests` run in the repository's test workflow.

## Performance

[App performance](performance.md) covers `tools\Measure-AppPerformance.ps1`, which takes repeatable, read-only startup, idle and resize measurements with isolated app data.
It also explains the build settings: the GPUI backend, ZIP features, release profile and dependency debug symbols.
