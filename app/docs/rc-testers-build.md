# Tester builds

This page explains how release candidates of Atlas Manager are built and checked.
It's for maintainers who build candidates and testers who verify them.

A tester build is `AtlasManager.exe` compiled with the `embedded-playbook` feature.
It carries exactly one Atlas package inside the executable and installs nothing else, so every tester of a candidate runs the same bytes, and no candidate can turn into a different package.
The feature fixes [what the build disables](#what-the-build-disables) at compile time; everything else is the same code as the stable build released once the candidate is accepted.

Each candidate has an RC id (release-candidate id) of the form `<version>-rc.<n>`, which testers see in the app and in file names.

## How it's produced

On Linux, with the toolchain from the [Linux desktop cross-build](../../docs/building.md#linux-desktop-cross-build), run this from any folder:

```sh
tools/release/build-rc.sh --rc <n> [--allow-dirty] [--toolbox AtlasToolbox-Setup.exe --toolbox-version <x.y.z>]
```

`build-rc.sh` stops before building anything if the `[package]` version in `app/Cargo.toml` differs from the version in `playbook.conf`.
Otherwise it:

1. Builds the production Atlas package, `Atlas v<version>-rc.<n>.apbx`, with `tools/build/Build-Playbook.ps1` and every eligibility check intact.
   `<version>` comes from `playbook/playbook.conf`.
   - With no uncommitted changes, it builds from an export of the commit's `playbook/`, so untracked and ignored files in the checkout stay out, and `tools/build/Test-Apbx.ps1` verifies the package against that export.
   - With `--allow-dirty` and uncommitted changes, both use the working tree.
   - With `--toolbox`, `tools/release/Add-BundledToolbox.ps1` first puts that Toolbox installer, and a manifest of its version, SHA-256 and size, in `Executables\AtlasModules\Bundled\Toolbox` of the export (a copy of the working tree when it has changes).
     Installing the Toolbox, from **Your choices** or the Atlas folder, then uses that copy instead of the latest release on GitHub.
     Use it when the candidate needs a Toolbox that isn't published yet; releases never carry one.
     `README-RC.txt` names the bundled version.
2. Confirms that the third-party notices are current with `tools/Export-DependencyNotices.ps1 -Check`, then compiles the app with a static C runtime: `cargo xwin build --release --locked --target x86_64-pc-windows-msvc --features embedded-playbook`.
3. Puts these files in `AtlasManager-<rc id>-windows-x64.zip`:
   - the executable;
   - the same Atlas package as a separate file, byte for byte, which testers don't need to install;
   - `LICENSE.txt`, `THIRD-PARTY-NOTICES.txt` and `GPUI-LICENSE-APACHE.txt`;
   - `README-RC.txt`, which is `tools/release/README-RC.txt` with the RC id, the commit and any bundled Toolbox filled in.
4. Lists the ZIP, the package and the executable in `SHA256SUMS.txt`, in the release workflow's format.
5. Moves the finished working folder to `artifacts/rc/<version>-rc.<n>/` in one step, so a failed run leaves an earlier candidate untouched.

The script refuses uncommitted changes unless you pass `--allow-dirty`.
With it, the recorded commit (in **About**, diagnostics and `README-RC.txt`) ends in `-dirty`, and the candidate isn't publishable.
Nothing is tagged or uploaded: the maintainer posts the ZIP and the checksum lines by hand.

On Windows, `tools/Build-Release.ps1 -RcId <id> -EmbedApbx <path>` builds the same executable, without the ZIP, for local checks ([development](development.md#tester-builds)).

### Environment variables

With the feature on, `build.rs` fails if either variable is missing or invalid, so a tester build is never produced by accident.

| Variable | Meaning |
| --- | --- |
| `ATLAS_EMBED_APBX` | The path of a readable Atlas package (`.apbx`) to embed. |
| `ATLAS_RC_ID` | The RC id, such as `<version>-rc.<n>`: the version in `app/Cargo.toml`, then `-rc.` and a number from 1 to 65535 with no leading zero, in letters, digits, dots and dashes only. |

`build.rs` also records the tree's short Git commit as `ATLAS_SOURCE_COMMIT`, ending in `-dirty` when there are changes, or `unknown` without Git.
`build-rc.sh` sets `XWIN_CACHE_DIR`, `XWIN_ACCEPT_LICENSE`, `XWIN_SDK_VERSION` and `XWIN_CRT_VERSION` for cargo-xwin ([building Atlas](../../docs/building.md)).

## What the build disables

Compared with the stable build, a tester build:

- never asks GitHub for releases or downloads a package (`Environment.check_updates` is false);
- has no package file picker, and ignores `--playbook` and `.apbx` arguments;
- installs only its bundled package, which it writes once to the app's Downloads folder as `Atlas-<rc id>.apbx` and unpacks through the normal package cache, keyed by the package's digest;
- doesn't resume a draft or recovered session that names another package;
- creates ISOs and USB drives from the bundled package only;
- doesn't consult Microsoft's Windows release page for an ISO.

For this PC, a tester build checks a revision that its bundled release catalog doesn't list on Microsoft's page, as the front door does (`src/services/windows_release.rs`).
Get ready then refuses a Release Preview build that the front door would refuse, instead of passing it.
An ISO carries no branch name, so an unlisted image revision passes only if it's newer than every catalogued revision of its build.

## Where the RC id appears

| Place | Detail |
| --- | --- |
| Under the title bar | On every page. |
| **Settings** > **About** | With the source commit and the bundled package's SHA-256. |
| Version resource | As text in `FileVersion` and `ProductVersion`; the numeric `FILEVERSION` and `PRODUCTVERSION` use the candidate number as their fourth part, so candidates differ in Explorer's **Details** tab. |
| Diagnostic exports | As `rcId` in the manifest. |
| Files | In the Downloads file name, the ZIP name and `README-RC.txt`. |

For example, `<major>.<minor>.<patch>-rc.<n>` becomes the numeric version `<major>.<minor>.<patch>.<n>`.

## Verification

During the build, these checks run automatically:

- `Test-Apbx.ps1` passes for the package before it's embedded;
- `Export-DependencyNotices.ps1 -Check` passes;
- `cargo build --locked` succeeds with the feature;
- `SHA256SUMS.txt` is produced from the files testers receive.

CI (`.github/workflows/app.yml`) also runs the tests and Clippy with the feature against a LocalTest package, on every change under `app/` or to the `playbook/` files compiled into the app ([development](development.md#ci)).

After the build, check by hand that:

- `7z l AtlasManager.exe`, or Explorer's **Properties** > **Details**, shows the icon, `AtlasOS` as the company and the RC id in the version fields;
- the checksum lines match what was posted.

### Checks for each candidate

Run these by hand for each candidate, on a disposable installation of a [supported Windows release](../../docs/windows-release-policy.md#supported-releases).

- **Launch.** Without a Visual C++ runtime installed, the app opens, shows the RC id under the title bar and in **About**, and offers no download or file picker.
- **Install.** Complete all four steps, including the UAC relaunch, the protection switches, the restart countdown and the completion window after the restart.
- **Servicing.** Run **Get ready** with pending Windows and Store updates, and check that updating finishes, including a restart that preparation asks for and the app's resumption after sign-in.
- **Completion entry.** After an install, choose **Restart later**, then sign out and in.
  No window opens, `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\AtlasInstallCompletion` remains, and Home, opened by hand, shows "Your PC needs to restart" with **Restart now**.
  After a restart, the completion window opens, and the value is gone about 20 seconds after sign-in.
- **Recovery.** Reopening the app while the installer runs picks the session up.
  Declining the UAC prompt that begins the flow abandons it, and declining a relaunch from inside the flow keeps the flow and its draft.
- **ISO.** Create an ISO from the bundled package in each of the three modes, and check the before-desktop handoff ([Creating an Atlas ISO](iso-creation.md)).
- **Diagnostics.** **Export diagnostics** in **Settings** > **Help and feedback** and `AtlasManager.exe --export-diagnostics` both produce a ZIP under `%LOCALAPPDATA%\AtlasOS\App\Diagnostics` with the right `rcId`.
  **Send a report** collects its diagnostics as the page opens, without a separate step.
- **Reports.** The report service and website run the privacy notice version the candidate sends (`PRIVACY_VERSION` in `src/services/reports.rs`).
  The service refuses any other version, so the app, the service and the website deploy together.
  The app's privacy text and the website's say the same, the use of AI services included.

The [release verification matrix](../../docs/release-verification-matrix.md) lists the evidence the final release needs.
