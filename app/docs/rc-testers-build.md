# Tester builds (release candidates)

For maintainers who build release candidates and testers who verify them.

A tester build is `AtlasManager.exe` compiled with the `embedded-playbook`
feature. It carries exactly one Atlas package inside the executable and
installs nothing else, so every tester of candidate N runs the same bytes and no
candidate can turn into a different package. Apart from
[What the build disables](#what-the-build-disables), which the feature fixes at
compile time rather than switching at run time, it is the same code as the
stable build released once the candidate is accepted.

## How it is produced

On Linux, with the toolchain from
[Linux desktop cross-build](../../docs/building.md#linux-desktop-cross-build),
run from any directory:

```
tools/release/build-rc.sh --rc N [--allow-dirty]
```

1. `tools/build/Build-Playbook.ps1` builds the production Atlas package,
   `Atlas v<version>-rc.N.apbx`, with every eligibility gate intact (`<version>`
   comes from `playbook/playbook.conf`). `tools/build/Test-Apbx.ps1` verifies
   it against the tracked `playbook/` tree.
2. After `tools/Export-DependencyNotices.ps1 -Check` confirms the third-party
   notices are current, `cargo xwin build --release --locked --target x86_64-pc-windows-msvc
   --features embedded-playbook` compiles the app with a static C runtime.
3. `AtlasManager-<rc id>-windows-x64.zip` gets the executable, the same package as
   a standalone file (for AME Wizard users), `LICENSE.txt`,
   `THIRD-PARTY-NOTICES.txt`, `GPUI-LICENSE-APACHE.txt` and `README-RC.txt`
   (`tools/release/README-RC.txt` with the RC id and commit filled in).
4. `SHA256SUMS.txt` lists the ZIP, the package and the executable in the release
   workflow's format.
5. The finished working directory moves to `artifacts/rc/<version>-rc.N/` in one
   step, so a failed run leaves an earlier candidate untouched.

The script refuses uncommitted changes unless `--allow-dirty` is passed; the
recorded commit then ends in `-dirty` and the candidate is not publishable.
Nothing is tagged or uploaded: the maintainer posts the ZIP and checksum lines
by hand.

On Windows, `tools/Build-Release.ps1 -RcId <id> -EmbedApbx <path>` builds the
same executable, without the ZIP, for local checks.

### Environment variables

With the feature on, `build.rs` fails if either variable is missing or invalid,
so a tester build is never produced by accident.

| Variable | Meaning |
| --- | --- |
| `ATLAS_EMBED_APBX` | Path of a readable Atlas package (`.apbx`) to embed. |
| `ATLAS_RC_ID` | The candidate id shown to testers, for example `0.6.0-rc.1`: letters, digits, dots and dashes only, ending in `-rc.N` (N from 1 to 65535, no leading zero). |

`build.rs` also records the tree's short Git commit as `ATLAS_SOURCE_COMMIT`
(`-dirty` with changes, `unknown` without Git). `build-rc.sh` sets
`XWIN_CACHE_DIR`, `XWIN_ACCEPT_LICENSE`, `XWIN_SDK_VERSION` and
`XWIN_CRT_VERSION` for cargo-xwin ([`docs/building.md`](../../docs/building.md)).

## What the build disables

Compared with the stable build, a tester build:

- never asks GitHub for releases or downloads a package
  (`Environment.check_updates` is false);
- has no package file picker and ignores `--playbook` and `.apbx` arguments;
- installs only its bundled package, written once to the app's Downloads folder
  as `Atlas-<rc id>.apbx` and unpacked through the normal package cache (keyed
  by the package's digest), and does not resume a draft or recovered session
  that names another package;
- creates ISOs and USBs from the bundled package only;
- never consults Microsoft's Windows release page, which the stable build uses
  for update revisions the bundled release catalog does not list.

A tester build must not depend on a live page, so an unlisted revision of a
supported build (26200 or 26300) on a release branch counts as a public release
(`src/services/windows_release.rs`); Insider branches and other builds still
fail. An ISO carries no branch name, so an unlisted image revision passes only
if it is newer than every catalogued revision of its build.

## Where the RC id appears

| Place | Detail |
| --- | --- |
| Under the title bar | Every page. |
| Settings > About | With the source commit and the bundled package's SHA-256. |
| Version resource | As text in `FileVersion` and `ProductVersion`. The numeric `FILEVERSION` and `PRODUCTVERSION` use the candidate number as the fourth part (`0.6.0-rc.2` is `0.6.0.2`), so candidates differ in Explorer's Details tab. |
| Diagnostic exports | `rcId` in the manifest. |
| Files | The Downloads file name, the ZIP name and `README-RC.txt`. |

## Verification

Automatic, during the build: `Test-Apbx.ps1` passes for the package before it is
embedded, `Export-DependencyNotices.ps1 -Check` passes, `cargo build --locked`
succeeds with the feature, and `SHA256SUMS.txt` is produced from the files
testers receive. CI (`.github/workflows/app.yml`) also runs the tests and Clippy
with the feature against a LocalTest package on every change under `app/` or to
the `playbook/` files compiled into the app.

By hand, after the build:

- `7z l AtlasManager.exe` (or Explorer > Properties > Details) shows the icon,
  `AtlasOS` as the company and the RC id in the version fields.
- The checksum lines match what was posted.

By hand for each candidate, on a disposable Windows 11 25H2 installation:

- **Launch**: without a Visual C++ runtime installed, the app opens, shows the
  RC id under the title bar and in About, and offers no download or file picker.
- **Install**: complete all four steps, including the UAC relaunch, the Windows
  Security switches, the restart countdown and the completion window after the
  restart.
- **Completion entry**: after an install, choose Restart later, then sign out
  and in. No window opens,
  `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\AtlasInstallCompletion`
  remains, and Home, opened by hand, shows "Your PC needs to restart" with
  Restart now. Restart: the completion window opens, and the value is gone
  about 20 seconds after sign-in.
- **Recovery**: reopening the app while the installer runs picks the session up.
- **ISO**: create an ISO from the bundled package in each of the three modes,
  and check the before-desktop handoff ([ISO creation](iso-creation.md)).
- **Diagnostics**: **Export diagnostics** in Settings > Help and feedback and
  `AtlasManager.exe --export-diagnostics` both produce a ZIP under
  `%LOCALAPPDATA%\AtlasOS\App\Diagnostics` with the right `rcId`. **Send a
  report** collects its diagnostics as the page opens, with no separate step.
- **Reports**: the report service and website run the privacy notice version
  the candidate sends (`PRIVACY_VERSION` in `src/services/reports.rs`); the
  service refuses any other, so the app, the service and the website deploy
  together. The app's privacy text and the website's say the same, the use of
  AI services included.
