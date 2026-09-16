# Tester builds (release candidates)

A tester build is `AtlasManager.exe` compiled with the `embedded-playbook`
feature. It carries exactly one Atlas playbook inside the executable and
installs nothing else, so every tester of candidate N runs the same bytes
and no candidate can quietly turn into a different package. It is what the
stable build becomes once the candidate is accepted: the code is identical
except for the gates listed below, which are compiled out rather than
switched off at run time.

## How it is produced

`../../tools/release/build-rc.sh --rc N [--allow-dirty]`, run on Linux from any
directory, builds one candidate end to end:

1. `tools/build/Build-Playbook.ps1` builds the production APBX
   (`Atlas v<version>-rc.N.apbx`, every eligibility gate intact) into a
   working directory, and `tools/build/Test-Apbx.ps1` verifies it against the
   tracked `playbook/` tree. `<version>` is read from `playbook/playbook.conf`.
2. `cargo xwin build --release --locked --target x86_64-pc-windows-msvc
   --features embedded-playbook` compiles the app with the C runtime linked
   statically, after `tools/Export-DependencyNotices.ps1 -Check` confirms the
   third-party notices are current.
3. The ZIP `AtlasManager-<rc id>-windows-x64.zip` is assembled from the
   executable, the same APBX as a standalone file (for AME Wizard users),
   `LICENSE.txt`, `THIRD-PARTY-NOTICES.txt`, `GPUI-LICENSE-APACHE.txt` and
   `README-RC.txt` (from `tools/release/README-RC.txt` with the RC id and
   commit filled in).
4. `SHA256SUMS.txt` lists the ZIP, the APBX and the executable in the release
   workflow's format.
5. The finished directory is moved into place as
   `artifacts/rc/<version>-rc.N/` in one step; a failed run leaves an earlier
   candidate untouched.

The script refuses a tree with uncommitted changes unless `--allow-dirty` is
passed, in which case the recorded commit ends in `-dirty` and the candidate
is not publishable. Nothing is tagged or uploaded; the maintainer posts the
ZIP and the checksum lines by hand.

On Windows, `tools/Build-Release.ps1 -RcId <id> -EmbedApbx <path>` builds the
same executable (without the ZIP) for local checks.

### Environment variables

`build.rs` reads these when the feature is on and fails the build when either
is missing or invalid, so a tester build can never be produced by accident:

| Variable | Meaning |
| --- | --- |
| `ATLAS_EMBED_APBX` | Path of the `.apbx` to bake into the executable. Must name a readable file. |
| `ATLAS_RC_ID` | The candidate id shown to testers, for example `0.6.0-rc.1`: letters, digits, dots and dashes only, and ending in `-rc.N` with N from 1 to 65535. |

`build-rc.sh` also sets `XWIN_CACHE_DIR`, `XWIN_ACCEPT_LICENSE`,
`XWIN_SDK_VERSION` and `XWIN_CRT_VERSION` for cargo-xwin (see
`../../docs/building.md`), and `build.rs` records the short Git commit of the
tree (`-dirty` when it has changes) as `ATLAS_SOURCE_COMMIT`.

## What the build disables

Compared with the stable build, a tester build:

- never asks GitHub for releases and never downloads a package
  (`Environment.check_updates` is false);
- has no file picker for a package; `--playbook` and `.apbx` command-line
  arguments are ignored;
- installs only its bundled archive, which is written once to the app's
  Downloads folder as `Atlas-<rc id>.apbx` and then unpacked through the
  ordinary content-addressed package cache; a draft or recovered session that
  names another package is not resumed;
- creates ISOs and USBs from the bundled archive only;
- never consults Microsoft's Windows release page. The stable build looks a
  Windows update revision up there when the bundled release catalog does not
  list it; a tester build must not depend on a live page, so an unlisted
  revision of the supported build 26200 on a release branch is accepted as a
  public release (Insider branches and other builds still fail the check;
  see `src/services/windows_release.rs`).

## Where the RC id appears

- Under the title bar of every page.
- Settings > About, together with the source commit and the SHA-256 of the
  bundled package.
- The executable's version resource: `FileVersion` and `ProductVersion`
  carry the id as text, and the numeric `FILEVERSION`/`PRODUCTVERSION` use
  the candidate number as their fourth component (`0.6.0-rc.2` is
  `0.6.0.2`), so candidates differ in Explorer's Details tab.
- `rcId` in the manifest of every diagnostic export.
- The Downloads file name, the ZIP name and `README-RC.txt`.

## Verification

Automatic, during the build:

- `Test-Apbx.ps1` passes for the APBX before it is embedded.
- `Export-DependencyNotices.ps1 -Check` passes.
- `cargo build --locked` with the feature; the CI workflow
  (`.github/workflows/app.yml`) runs the tests and Clippy with the feature
  against a LocalTest package on every change under `app/`.
- `SHA256SUMS.txt` is produced from the files testers receive.

By hand, after the build:

- `7z l AtlasManager.exe` (or Explorer > Properties > Details) shows the
  icon, `AtlasOS` as the company, and the RC id in the version fields.
- The checksum lines match what was posted.

Still owed on Windows for each candidate, in a disposable Windows 11 25H2
installation:

- The app opens without a Visual C++ runtime installed, shows the RC id under
  the title bar and in About, and offers no download or file picker.
- A complete install through the four steps, including the UAC relaunch, the
  Windows Security switches, the restart countdown and the completion window
  after the restart.
- Reopening the app while the installer runs picks the session up again.
- ISO creation from the bundled archive in each of the three modes, and the
  before-desktop handoff (`docs/iso-injection.md`).
- **Export diagnostics** from Settings and `AtlasManager.exe --export-diagnostics`
  both produce a ZIP under `%LOCALAPPDATA%\AtlasOS\App\Diagnostics` with the
  right `rcId`.
