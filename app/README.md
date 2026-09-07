# Atlas Manager

The graphical front door for AtlasOS: a Windows 11 desktop app that shows the
installed Atlas version, checks GitHub for newer releases, and runs a four-step
install: get ready (elevate once, run the system checks, fetch the package),
choose options, turn off Windows Security while the app watches the switches
live, then hand the install to `Entry\Install-Atlas.ps1` (the same script the
command-line front door uses). Checks come first so you can resolve setup problems
before turning protection off.
Windows Security comes last to reduce the time protection is off.

It is written in Rust on [GPUI](https://github.com/zed-industries/zed/tree/main/crates/gpui),
Zed's GPU-accelerated UI framework, pinned to the `gpui-pre` crates.io snapshot.
Nothing else sits between the app and GPUI: the controls in `src/ui` are drawn
to the Windows 11 Fluent spec (Mica backdrop, Segoe UI Variable, Segoe Fluent
Icons, WinUI colour tokens) so the window reads as part of the OS, and they
carry the accessible roles, names and keyboard behaviour Windows controls have.

## ISO creation (Beta)

Home also offers **Create an Atlas ISO**. Choose an unmodified supported Windows
11 x64 ISO, an Atlas `.apbx` package and a new output filename. Windows' built-in
Storage, DISM and IMAPI services create and verify the media; the ADK is not required.
Administrator access and sufficient space on a local NTFS or ReFS volume are required.

ISO creation requires Atlas 0.6.0 or newer. Choose Atlas settings now or after
sign-in, and provide a local-account name. Windows creates the account and
requests a new password at the user's first sign-in. Both modes open the app
on the destination, where Windows, Microsoft Store and installed Store apps
must finish updating before Atlas can be applied. Updates require internet
access. This Beta does not apply Atlas before the first desktop.
Use the portable release executable when creating media for a clean PC.
See [ISO creation and release validation](docs/iso-injection.md).

## Build, test and run

Requirements: rustup (the compiler is pinned by `rust-toolchain.toml` to a
stable release, currently 1.98.1, so builds here and in CI agree), the Visual
Studio build tools (for `rc.exe`, which embeds the icon), and Windows 11 build
22621 or later for Mica. The first build compiles GPUI and takes a few minutes.

```
cd app
cargo run
cargo test --locked # unit and model tests; Windows PowerShell runs harmless stubs
cargo clippy --locked --all-targets -- -D warnings
powershell -NoProfile -File tools/Build-Release.ps1
```

The same checks run in CI (`.github/workflows/app.yml`) on every change under `app/`.
CI also builds and saves the release executable as `atlas-manager-windows-x64`.
The release script writes `target/x86_64-pc-windows-msvc/release/AtlasManager.exe`
with the C runtime linked statically, so a clean Windows installation does not
need a separately installed Visual C++ runtime. The explicit Cargo target keeps
this setting separate from host build scripts and procedural macros.
Use the release executable for performance measurements and distribution;
`cargo run` without `--release` is a development build.

The app selects `gpui-pre-windows` directly through `src/platform.rs`, so
the lockfile does not need GPUI's unrelated OS backends. The Windows
manifest remains enabled. ZIP support includes AES and Deflate, without
the unused Zopfli encoder. Development dependencies retain optimisation
but omit debug symbols; Atlas itself retains full debugging. For debugging
inside a dependency, override this with
`cargo build --config 'profile.dev.package."*".debug=true'`.

For repeatable, read-only startup, idle and resize smoke measurements:

```powershell
.\tools\Measure-AppPerformance.ps1 -Executable .\target\release\AtlasManager.exe -Runs 3 -OutFile measurements.json
```

This uses isolated app data and never installs Atlas or changes Windows
settings. Window-creation time is not time to first rendered frame; CPU
percentages represent one logical core. See `docs/performance.md` for measurement instructions and build settings.

Startup flags and environment variables exist for review and testing:

```
AtlasManager.exe --page install --step security      # open on a page or step (ready|options|security|install)
AtlasManager.exe --just-installed                    # the completion window the payload opens after the restart
AtlasManager.exe --playbook "..\playbook\Atlas Test.apbx"   # unpack a local package on launch
AtlasManager.exe "C:\Downloads\Atlas 0.6.0.apbx"     # same, as "Open with"
AtlasManager.exe --language de                       # a shipped language tag, or qps-ploc for the pseudo-locale
```

- `ATLAS_APP_DATA=<dir>` keeps settings, downloads, unpacked playbooks, install
  logs and the install session under a directory of your choice, so a review run
  never touches the real `%LOCALAPPDATA%\AtlasOS\App`.
- `ATLAS_STATE_FILE=<state.json>` renders the installed and update-available
  states on a PC without Atlas.
- `ATLAS_LANGUAGE=<tag>` is `--language` from the environment;
  `ATLAS_FORMAT_LOCALE=<tag>` (for example `de-DE`) overrides the Windows
  regional format used for numbers, dates and times;
  `ATLAS_WINDOWS_LANGUAGES=de-DE,en-US` stands in for the Windows
  display-language list (`error` simulates a failed query).
- `tools\Capture-Window.ps1 -OutFile shot.png` screenshots the running window.
- `tools\Get-AccessibilityTree.ps1 [-Invoke <name>]` prints what UI Automation
  (and so Narrator) sees, with focus and toggle states, and can press a control
  through its accessible action.

[Language documentation](docs/i18n.md) covers language selection, catalog readiness
and adding translations. [Writing guidance](docs/writing.md) describes the app's voice.

For app or installation problems, use **Export diagnostics** in Settings or the
installation/media pages. It creates a local ZIP of app and playbook evidence;
review it before sharing privately. If the window cannot open, run
`AtlasManager.exe --export-diagnostics`. See [support diagnostics](../docs/diagnostics.md)
for log locations, collection limits and the reporting process.

## Languages

The app follows the Windows display language by default and offers a manual
choice in Settings. It ships English (UK and US), German, Spanish, French,
Brazilian Portuguese, Polish, Russian, Turkish, Simplified Chinese,
Traditional Chinese, Japanese, Indonesian, Thai and Hindi; the non-English catalogs are AI-assisted and remain previews pending native-speaker review; a preview is used when Windows speaks that language, with a
dismissible notice that offers the English source language. Numbers, dates and times follow the Windows
regional format independently of the app language. Text is looked up when a
page renders, from semantic state rather than stored strings, so switching
language re-words everything on screen, including earlier errors and
results, without disturbing the flow or a running install. Catalogs are
Fluent files under `i18n/<tag>/atlas.ftl`, compiled into the executable;
tests check every catalog and every message the code uses. Right-to-left
languages are not shipped because the pinned GPUI does not shape or order
right-to-left text (see `docs/i18n.md`).

## What the app does and does not do

- Reads `%windir%\AtlasOS\state.json` for the installed version, mode, options
  and history. It never writes it; the PowerShell modules own that document.
- Asks the GitHub releases API for the latest release and compares versions the
  way Atlas tags them: `0.5.0-hotfix` is newer than `0.5.0`. Downloads go to
  `%LOCALAPPDATA%\AtlasOS\App\Downloads` and are verified against the asset's
  size and published digest before they are trusted; packages are unpacked into
  a private staging directory and only then published as
  `...\App\Playbooks\<version>_<digest>`, an immutable directory named by
  the package's content, so a bad package never replaces a good one and two
  packages that both call themselves 0.6.0 never share a directory.
- Only playbooks that ship the front door script (Atlas 0.6.0 and newer) can
  be installed from here. Older packages are refused with a message that points
  to the AME Wizard.
- "Install Atlas" relaunches the app elevated through the UAC prompt before
  anything else. The flow's step, options and unpacked package are saved as a
  draft in `settings.json` (written atomically; a failed save stops the
  relaunch), so the elevated copy resumes where the user was; the draft is
  cleared when the install succeeds or the flow is cancelled.
- Windows Security is watched once a second through the same registry values
  the AME Wizard reads (Tamper Protection, real-time protection, cloud-delivered
  protection, sample submission). A switch that cannot be read is shown as
  unreadable, never as on or off; an elevated user can confirm unreadable
  switches by hand after checking Windows Security.
- System checks mirror playbook.conf's requirements: administrator, supported
  build, no pending Windows updates (Windows Update Agent, offline search), no
  pending restart, no third-party antivirus (Security Center), internet, mains
  power, plus an advisory Windows activation row (Atlas never changes
  activation; the row just says so and points at the activation settings). A blocking check that fails, or that could not run, disables Next;
  a check that could not run can be confirmed by hand. The mandatory checks and
  the security switches are read again just before the installer starts.
- The install runs `Install-Atlas.ps1 -Option @(...) -Unattended [-Restart]`
  through `powershell.exe -Command` (so the option list arrives as a real
  array) with UTF-8 output. The child writes to a log file under
  `...\App\Logs`, and a session record (`...\App\session.json`) names the
  process and log. Launching is one protocol under a cross-process lock: the
  record is written before the child starts and the child only runs the front
  door once it has the go-ahead, so no installer can run unrecorded and two
  windows cannot start overlapping installs. While it runs, the package, options and settings are locked
  and the window can only be closed knowingly; the install keeps going in the
  background, and reopening the app picks the session up again and shows its
  result. While it runs (and after it succeeds) the window shows one
  dedicated installing view: phase, progress, when it started, and the log
  behind "Show details". After a successful install the front door restarts
  Windows in ten seconds; the view counts down with a "Don't restart now"
  button (and "Restart now" once stopped). After the restart, the payload's
  first-logon setup opens this app again with `--just-installed` (it finds the
  app through `launcher.json`, written when the install started) to show an
  "Atlas is installed" window; if the app can't be found it shows a persistent
  toast instead. A failed install goes back to the Install step, which has the
  log and Try again.
- The Options step asks one decision per screen (Defender, mitigations,
  updates), each as a question with the consequence of the chosen answer, then
  one screen of optional extras; the Install summary lists the choices with
  Change links.

## Accessibility and keyboard

Every control has an accessible role and name (buttons, links, radio groups,
check boxes, headings, lists, status and alert regions, the install log). Tab
and Shift+Tab move between controls; a radio group is a single tab stop and
the arrow keys change the selection; Enter and Space activate. Changing step
moves focus to the step heading, and an install result is focused so it is
announced. A Windows contrast theme switches the palette to the system
colours, the Ease of Access text size scales the type ramp, and turning off
Windows animations stops the progress indicators moving.

## Layout

```
src/
  main.rs         window options (Mica, custom title bar, icon), startup flags, key bindings
  shell.rs        title bar (with the settings gear) + one content layer, theme, focus traversal, close guard
  model.rs        AppModel: all state, owned background tasks; model/tests.rs drives it headless
  environment.rs  what the model needs from the process: paths, machine adapters, restart timing
  flow.rs         the install flow's state machine (steps, run state, allowed transitions)
  theme.rs        Fluent tokens for light, dark and contrast themes, Atlas blue accent
  assets.rs       SVGs and the window icon compiled into the binary
  i18n/           language choice, message lookup (t!), words for semantic state,
                  regional formatting, catalog checks
  ui/             Button, InfoBar, RadioGroup, CheckBox, ProgressBar,
                  ProgressRing, StatusLight, TitleBar, Scrollbar
  pages/          Home (status, what's new, the one button), Install (4 steps), Installing, Installed, Settings
  services/       Windows-facing code with no UI dependency:
                  system, atlas_state, security, requirements, releases,
                  playbook, installer, session, settings, locale
i18n/<tag>/atlas.ftl   one Fluent message catalog per shipped language (en-GB is the source)
```

Slow work (HTTP, Windows Update, WMI, extraction, the installer launch) runs
on GPUI's background executor and reports back through the model, which
notifies observers; pages are thin views over the model. The tasks are owned
by the model and carry a generation, so cancelling or repeating an operation
drops the old work and a late result never lands in newer state. Provider
probes use bounded waits. Preparation retains its servicing worker until the
provider returns; cancellation does not kill an active Windows Update operation.

### Preparation and restart recovery

Before preparation starts, the app copies its exact executable into an immutable
SHA-256 directory under the Windows Program Files folder's `Atlas Setup Recovery`
directory. Restart registrations use this protected local copy, so removing the
original download or unplugging its source does not remove the recovery app.
Before-desktop ISO setup already uses its protected local copy.

Preparation jobs also live beneath this protected directory, scoped to the app's
settings path. Workers, driver policies and journals allow only administrators and
SYSTEM to write. A separate precreated cancellation file lets the installing user
request a stop without replacing executable content or completion records. The
worker and staging helper restrict PowerShell module lookup to the inbox module root.

Reopening the app attaches to the recorded PID and creation time and reads its
durable journal. Unknown process liveness keeps ownership; a reused PID does not.
Older user-writable journals can make Atlas wait for an existing worker, but cannot
prove preparation succeeded or supply a cancellation target. Once that worker exits,
the user retries preparation through the protected path. The app never starts a
second servicing worker to replace one that is still running.

Preparation and direct installation share the payload's
`Scripts/Preparation/Update-Windows.ps1`. Direct installation verifies live Windows
and Store readiness before starting the install plan. Store's verification API can
queue paused updates; it does not install them during verification. See
[the release policy](../docs/windows-release-policy.md) for the installed-OS and
ISO eligibility checks. Actual servicing, UAC and restart recovery still require
candidate-specific Windows testing.

The model tests (`src/model/tests.rs`) run the real model inside a headless
GPUI application with controlled adapters for elevation, the Windows Security
reading, the checks and the restart commands, and a real Windows PowerShell
child running a stub front door; they cover the final security decision,
recovery of finished installs after the app was closed, retrying a recovered
failure and the restart countdown's timer ownership.
