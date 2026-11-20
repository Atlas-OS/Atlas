# Atlas Manager

Atlas Manager is the Windows 11 desktop app that installs and updates Atlas, creates Atlas ISOs and USB drives, and sends diagnostics and reports to the Atlas team.
This guide is for contributors who build, test or review it; user documentation lives on the [Atlas documentation site](https://atlasos.net/docs/).

## Requirements

- Windows 11, build 22621 or later, which the window's Mica backdrop needs.
- [rustup](https://rustup.rs/); `rust-toolchain.toml` pins the compiler, so local and CI builds use the same one.
- The Visual Studio build tools, whose `rc.exe` embeds the icon and version resource.
- PowerShell 7.2 or later (`pwsh`) for the release build and the review scripts.

## Quick start

Run these commands from `app/`.
The first build compiles GPUI and takes a few minutes.

### Run

```powershell
cargo run
```

This makes a development build; distribute and measure only the release executable.

### Test

```powershell
cargo test --locked
```

The tests drive the real model headless, and start Windows PowerShell only against harmless stub scripts, so nothing is installed.

### Before a pull request

```powershell
cargo fmt --all -- --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
```

### Release build

```powershell
pwsh -NoProfile -File tools/Build-Release.ps1
```

The script writes `target/x86_64-pc-windows-msvc/release/AtlasManager.exe`.
[Development](docs/development.md) covers tester builds, the embedded-package tests and CI.

## What the app does

- **Installs and updates Atlas.**
  Home shows the installed version and checks GitHub for newer releases.
  The install has four steps, **Get ready**, **Your choices**, **Windows Security** and **Install**, and ends by running the front door, `Entry\Install-Atlas.ps1`, the script in the Atlas package that installs Atlas.
- **Creates media.**
  **Create an Atlas ISO** builds Windows 11 installation media that applies Atlas after Windows setup, and can write it to a USB drive.
- **Helps with problems.**
  **Export diagnostics** saves a ZIP for a bug report, and **Send a report** sends a message privately to the Atlas team.

The app follows the Windows display language, with English as the source and preview translations in other languages.
It's written in Rust on [GPUI](https://github.com/zed-industries/zed/tree/main/crates/gpui), Zed's GPU-accelerated UI framework, and draws its own Windows 11 Fluent controls.

## Documentation

| Page | Covers |
| --- | --- |
| [Development](docs/development.md) | Building, testing, release and tester builds, and CI. |
| [Architecture](docs/architecture.md) | The source layout, the model and its background tasks, packages and tests. |
| [The install flow](docs/install-flow.md) | The four steps, the system checks, running the install, the restart, settings and recovery. |
| [Creating an Atlas ISO](docs/iso-creation.md) | Creating an ISO and a USB drive, and what happens on the new PC. |
| [ISO internals](docs/iso-internals.md) | How the ISO and USB workers build, verify and hand over media. |
| [Review tools](docs/review-tools.md) | Flags, environment variables and preview states for reviewing every screen. |
| [Accessibility](docs/accessibility.md) | Accessible roles, keyboard behaviour, Narrator, themes and text size. |
| [Languages](docs/i18n.md) | Language selection, catalogs, adding a language, translation review and package text. |
| [Translation guidance](docs/translating.md) | Each language's conventions and open terminology questions. |
| [Writing for Atlas](docs/writing.md) | The interface copy guide. |
| [App performance](docs/performance.md) | Measuring startup, idle and resize, and the build settings. |
| [Tester builds](docs/rc-testers-build.md) | Building and checking a release candidate with a bundled Atlas package. |
| [Licence notices](licenses/README.md) | The third-party notices and how to update them. |
| [Diagnostics](../docs/diagnostics.md) | Log locations, collection limits and the reporting process. |

Documentation and code comments follow the [writing style](../docs/style.md).
The vendored GPUI crates and AccessKit's Windows adapter each describe their Atlas changes in an `ATLAS-PATCH.md` under `vendor/`.
