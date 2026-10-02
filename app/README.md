# Atlas Manager

Atlas Manager is the Windows 11 desktop app that installs and updates AtlasOS.
This guide is for contributors who build, test or review it.

The app shows the installed Atlas version, checks GitHub for newer releases and
runs a four-step install:

1. **Get ready**: elevate once, run the system checks, update Windows and
   Microsoft Store apps, and fetch the Atlas package.
2. **Your choices**: choose the Atlas options.
3. **Windows Security**: turn it off while the app watches the switches live.
4. **Install**: run `Entry\Install-Atlas.ps1`, the "front door" script that
   command-line installs also use.

Checks and updates come first so problems are fixed before protection goes off.
Windows Security comes last so protection is off as briefly as possible.

The app is Rust on [GPUI](https://github.com/zed-industries/zed/tree/main/crates/gpui)
(Zed's GPU-accelerated UI framework), pinned to the `gpui-pre` crates.io
snapshot, with no component library. `src/ui` draws Windows 11 Fluent controls
(Mica, Segoe UI Variable, Segoe Fluent Icons, WinUI colour tokens) so the window
looks native, with Windows' accessible roles, names and keyboard behaviour. The
text box adapts Zed's Apache-2.0 GPUI input example
(`licenses/GPUI-input-APACHE-2.0.txt`).

## ISO creation (Beta)

**Create an Atlas ISO** on Home stages Atlas in Windows install media, which
Windows' Storage, DISM and IMAPI services create and verify (no ADK needed). It
needs administrator access, enough free space on a local NTFS or ReFS volume, an
unmodified supported Windows 11 x64 or ARM64 ISO, an Atlas package (`.apbx`),
version 0.6.0 or newer, a new output filename and a local-account name.
Windows creates the account and asks for its password at the first sign-in;
the ISO skips Windows setup's licence, Microsoft account and privacy screens.
The flow has four steps, Files, Windows setup, Your choices and Review, and
carries a Beta badge in its title.

| Mode | On the new PC |
| --- | --- |
| **Make Atlas choices after sign-in** | Atlas Manager opens on the desktop for updates, choices and the install. |
| **Make Atlas choices now** | Choices saved in the ISO are preselected. |
| **Finish setup before the desktop** | Saved choices skip the Your choices step. After the intended user signs in, Atlas Manager runs full-screen, with Explorer behind it, until updates and the install finish. **Continue in Windows** works whenever no update, install, media job or restart countdown is running. |

Saving choices needs a package that declares ISO setup support; otherwise only
the first mode is available. Every mode applies Atlas after Windows setup and
sign-in, never inside `install.wim`, once Windows, Microsoft Store and Store apps
are updated, so the new PC needs internet access.

Create media from the portable release executable, not a development build. The
ISO carries a copy of the running executable, and the release build's static C
runtime means the new PC needs no Visual C++ runtime. See
[ISO creation and release validation](docs/iso-creation.md).

## Diagnostics and reports

**Export diagnostics** creates a ZIP of app and Atlas installation evidence for
a bug report, with the user name, PC name, email addresses and known passwords
or keys removed; `AtlasManager.exe --export-diagnostics` does the same if the
window cannot open. **Send a report** sends a message privately to the Atlas
team ([Atlas reports](../services/reports/README.md)), with diagnostics it
collects as the page opens unless the user turns **Include diagnostics** off.
Both are in Settings > Help and feedback, and Home's **Report a problem** opens
Send a report. Elsewhere they appear only under a problem, such as a failed
check, install or ISO build, and with the log of a running install.
[Diagnostics](../docs/diagnostics.md) covers log locations, collection limits
and the reporting process.

## Build, test and run

You need rustup (`rust-toolchain.toml` pins a stable compiler, currently 1.98.1,
so local and CI builds agree), PowerShell 7.2 or later (`pwsh`) for the release
script, the Visual Studio build tools (`rc.exe` embeds the icon) and Windows 11
build 22621 or later for Mica. The first build compiles GPUI and takes a few
minutes.

```
cd app
cargo run
cargo test --locked # unit and model tests; Windows PowerShell runs harmless stubs
cargo fmt --all -- --check
cargo clippy --locked --all-targets -- -D warnings
pwsh -NoProfile -File tools/Build-Release.ps1
pwsh -NoProfile -File tools/Build-Release.ps1 -RcId 0.6.0-rc.1 -EmbedApbx "..\playbook\Atlas v0.6.0-rc.1.apbx"
```

`cargo run` without `--release` is a development build; distribute and measure
performance with the release executable.

### Release and tester builds

`tools/Build-Release.ps1` checks the third-party notices
(`tools/Export-DependencyNotices.ps1 -Check`), then builds
`target/x86_64-pc-windows-msvc/release/AtlasManager.exe` with a static C
runtime, so a clean Windows installation needs no Visual C++ runtime. The
explicit Cargo target keeps that setting out of host build scripts and
procedural macros. The script sets `CARGO_INCREMENTAL=0` because stale
incremental state has caused release link failures.

| Parameters | Builds |
| --- | --- |
| none | The stable executable. |
| `-RcId <id> -EmbedApbx <path>` | The tester build: sets `ATLAS_RC_ID` and `ATLAS_EMBED_APBX` and adds `--features embedded-playbook`, as `build-rc.sh` does. |
| `-Json` | With Cargo JSON diagnostics. |

A tester build carries one Atlas package and installs nothing else; `build.rs` fails
unless both variables are set. [Tester builds](docs/rc-testers-build.md) lists
what it disables and where the RC id appears.
On Linux, `../tools/release/build-rc.sh` produces the tester ZIP, and
`../tools/release/setup-linux.sh` with the
[Linux desktop cross-build](../docs/building.md#linux-desktop-cross-build)
replaces the Visual Studio tools: `llvm-rc` compiles the icon and manifest, and
the shaders come from the committed Windows export.

### CI

`.github/workflows/app.yml` runs on changes under `app/` and to the `playbook/`
files compiled into the app (`playbook.conf`, the front door, the preparation
and compatibility scripts, the driver-policy files). It runs the format check,
then Clippy and the tests twice (without features, and with
`--features embedded-playbook` against a LocalTest package), and saves the
release executable as `atlas-manager-windows-x64`.

### Performance

[App performance](docs/performance.md) covers
`tools\Measure-AppPerformance.ps1` (repeatable, read-only startup, idle and
resize measurements with isolated app data that never install Atlas or change
Windows)
and the [build settings](docs/performance.md#build-settings): GPUI backend, ZIP
features, release profile and dependency debug symbols.

### Review flags and variables

| Flag | Effect |
| --- | --- |
| `--page <page>` | Opens `home`, `iso`, `install`, `settings`, `report` or `installed`. |
| `--step <step>` | Opens an install step: `ready`, `options`, `security` or `install`. |
| `--just-installed` | Opens the completion window shown after the install's restart. |
| `--playbook <file.apbx>` | Unpacks a local package on launch; a bare `.apbx` path ("Open with") does the same. |
| `--language <tag>`, `ATLAS_LANGUAGE=<tag>` | Uses one of the available languages, or `qps-ploc` for the pseudo-locale. |

| Variable | Effect |
| --- | --- |
| `ATLAS_APP_DATA=<dir>` | Keeps settings, downloads, unpacked packages, install logs and the session in `<dir>`, never the real `%LOCALAPPDATA%\AtlasOS\App`. |
| `ATLAS_STATE_FILE=<state.json>` | Debug builds: shows the installed or update-available state on a PC without Atlas. Release builds always read `%windir%\AtlasOS\state.json` (`src/services/atlas_state.rs`). |
| `ATLAS_FORMAT_LOCALE=<tag>` | Overrides the regional format for numbers, dates and times, for example `de-DE`. |
| `ATLAS_WINDOWS_LANGUAGES=de-DE,en-US` | Replaces the Windows display-language list; `error` simulates a failed query. |
| `ATLAS_TEXT_SCALE=1.5`, `ATLAS_HIGH_CONTRAST=1` | Debug builds: preview a text size (1.0 to 2.25) or a contrast theme without changing Windows. |

Debug builds also have review previews. The preparation, report and ISO
previews never update Windows, restart the PC, install Atlas, build media or
send a report. `ATLAS_SECURITY_PREVIEW` only replaces the switch readings, and
`ATLAS_DESKTOP_PREVIEW` only makes the app behave as in before-desktop setup;
neither holds anything back.

| Variable | Shows |
| --- | --- |
| `ATLAS_PREPARATION_PREVIEW=<state>` | The install flow with a stand-in package. Get ready: `idle`, `busy`, `stopping`, `download`, `complete`, `resume`, `resumed`, `cancelled`, `failed`, `failed-battery`, `unconfirmed`, `reboot`, `reboot-others` (Restart now asking first because other people are signed in), `restart-persists`, `network`, `network-limited`, `previous-worker`, `ineligible`, `pending-updates`, `checks-blocked`, `checks-warnings`. Microsoft Store itself: `store-updating`, `store-repairing`, `store-updated`, `store-bootstrapped`, `store-repaired`, `store-skipped-removed`, `store-repair-failed`. Moving Windows to 26H2: `windows-required`, `windows-ready`, `windows-choice`, `windows-keep`, `windows-blockers`, `windows-running`, `windows-waiting`, `windows-restart`, `windows-commit-failed`, `windows-resumed`, `windows-not-offered`, `windows-not-offered-25h2`, `windows-not-offered-ended`, `windows-hardware`, `windows-rolled-back`, `windows-disk-space`, `windows-blocked`, `windows-components-lost`, `windows-managed`, `windows-failed`; after Windows reinstalled itself during the move, `windows-rebuilt`, and Your choices with every choice kept (`options-rebase`) or one missing (`options-rebase-partial`); an update from Atlas 0.5.0 starting from the extras the PC shows (`options-upgrade`). Home: `home-24h2-pro`, `home-25h2`, `home-24h2-home`, `home-23h2`, `home-update-access`, `home-update-access-after`, `home-not-offered`, `home-update-access-unreadable`, `home-put-back-failed`, and Restart now asking first because someone else is signed in (`home-restart-others`). The completion window: `installed-update-off`. Windows Security: `security-on`, `security-off`, `security-readable-off`, `security-unreadable`, `security-absent`. Install: `install-ready`, `install-refused`, `install-busy`. |
| `ATLAS_SECURITY_PREVIEW=<reading>` | Every Windows Security reading as `on`, `off`, `some-off` (Tamper Protection and Cloud-delivered protection off), `unreadable` or `absent` (Defender removed), for the reminders on Home and the completion window. |
| `ATLAS_REPORT_PREVIEW=<state>` | Send a report as `invalid`, `collecting`, `ready`, `prepare-failed`, `waiting`, `sending`, `sent`, `failed`, `busy`, `outdated` or `diagnostics`. Nothing is collected, and Send fails without connecting. |
| `ATLAS_REVIEW_OTHER_SESSIONS=<names>` | Debug builds: the account names, separated by commas, that Atlas reads as signed in besides you, so the question before a restart can be reviewed on a PC nobody else uses. |
| `ATLAS_REVIEW_NO_RESTART=1` | A restart Atlas asks for is logged and reported as accepted, and Windows keeps running, so capturing a countdown or **Restart now** is safe. |
| `ATLAS_ISO_PREVIEW=<state>`, `ATLAS_DESKTOP_PREVIEW=1` | ISO, USB and before-desktop states; `tools\Review-Iso.ps1` sets them ([ISO creation](docs/iso-creation.md#review-and-localization)). |

`tools\Capture-Window.ps1 -OutFile shot.png` screenshots the running window.
`tools\Get-AccessibilityTree.ps1 [-Invoke <name>]` prints what UI Automation
(and so Narrator) sees, with focus and toggle states; `-Invoke` presses a
control through its accessible action.

## Languages

The app follows the Windows display language (Settings > Language offers a
manual choice).
Numbers, dates and times follow the Windows regional format, whatever the app
language. It is available in English
(UK and US), German, Spanish, French, Brazilian Portuguese, Polish, Russian,
Turkish, Simplified Chinese, Traditional Chinese, Japanese, Indonesian, Thai and
Hindi. Non-English catalogs are AI-assisted previews until a native speaker
reviews them; a preview loads when Windows uses that language, with a
dismissible notice that offers English.

Catalogs are Fluent files at `i18n/<tag>/atlas.ftl`, compiled into the
executable; tests check every catalog and every message the code uses. Text is
worded at render time from semantic state, so a language switch re-words
everything on screen, earlier errors and results included, without disturbing
the flow or a running install. Right-to-left languages are not included: the
pinned GPUI cannot shape or order them.

[Language documentation](docs/i18n.md) covers language selection, catalog
readiness and adding translations; [writing guidance](docs/writing.md) covers
the app's voice.

## Accessibility and keyboard

Every control has an accessible role and name: buttons, links, radio groups,
check boxes, combo boxes, toggle switches, headings, lists, status and alert
regions, and the install log.

- Tab and Shift+Tab move between controls. A radio group is one tab stop whose
  selection the arrow keys change. Enter and Space activate. The focus ring is
  Windows' 2 px outer and 1 px inner ring.
- Page Up/Down and Ctrl+Home/End scroll the page. The install log is a tab stop
  that also scrolls with the arrow keys, Home and End.
- In a text box, Ctrl+Home/End jump to the start or end; in the report message,
  Page Up/Down move the caret a page.
- A closed combo box ignores the arrow keys, so a value such as the app's
  language never changes as focus passes over it. Enter, Space, Alt+Down,
  Alt+Up or F4 opens the list; the arrow keys, Home, End and Page Up/Down move
  the highlight; Enter or Space commits it. Escape or Tab closes the list
  without changing anything.
- A tooltip appears after 500 ms of hover, or at once when its control takes
  keyboard focus, and stays until the pointer or focus leaves. Escape or a
  press dismisses it.
- A close confirmation is a Fluent ContentDialog over the window, in the app's
  theme and language. Its safe answer, **Keep open**, is rightmost, accent and
  focused, and Escape chooses it.
- Changing page or step focuses its heading. Install results take focus so they
  are announced, as do export results if focus has not moved since the export
  started. Message bars that don't take focus are polite live regions, as are
  progress bars and the status of the installation files and the Windows
  Security switches, so Narrator reads them as they appear or change.
- Headings report their level, so Narrator's heading navigation follows the
  outline: 1 for the page title, 2 for a step heading or a page's cards, 3 for
  the cards under a step. Every node reports the app's language, and each
  language in Settings > Language reports its own.
- Contrast themes switch to the system colours, selected text included. The
  Ease of Access text size scales the type ramp. Turning off Windows animations
  stops the progress indicators moving.

## Layout

```
src/
  main.rs         window options (Mica, custom title bar, icon), key bindings
  cli.rs          command-line flags
  platform.rs     builds the GPUI application on the Windows backend
  shell.rs        title bar (with the settings gear) + one content layer, theme, focus traversal, close guard
  model.rs        AppModel: all state, owned background tasks; model/ holds it by concern,
                  and model/tests/ drives it headless on model/test_harness.rs
  environment.rs  what the model needs from the process: paths, machine adapters, restart timing
  flow.rs         the install flow's state machine (steps, run state, allowed transitions)
  theme.rs        Fluent tokens for light, dark and contrast themes, Atlas blue accent
  assets.rs       SVGs and the window icon compiled into the binary
  i18n/           language choice, message lookup (t!), words for semantic state,
                  regional formatting, catalog checks
  ui/             Fluent controls: Button, card, InfoBar, RadioGroup, CheckBox,
                  ComboBox, ToggleSwitch, TextInput, ProgressBar, ProgressRing,
                  StatusLight, tooltips, ContentDialog (the window's prompts),
                  TitleBar, Scrollbar, release-note markdown
  pages/          Home (status, what's new, the install button), Install (install/,
                  4 steps), Installing, Installed, ISO, USB, Send a report, Settings,
                  and the shared stepper and footer
  services/       Windows-facing code with no UI dependency: system, atlas_state,
                  security, requirements, windows_release, windows_installation,
                  releases, playbook, embedded, preparation, recovery_app,
                  installer, session, settings, registry, locale, iso, usb, desktop_setup,
                  diagnostics (and its redaction), reports, licenses
resources/        icon and version resource; iso/ (ISO, USB and destination
                  setup scripts) and prepare/ (protected staging helper)
i18n/<tag>/atlas.ftl   one Fluent message catalog per available language (en-GB is the source)
examples/         i18n_spike, the GPUI rendering probe for RTL, CJK and mixed scripts
licenses/         third-party notices and the dependency inventory
vendor/           the patched GPUI crates and AccessKit's Windows adapter, which
                  reports heading levels (see each ATLAS-PATCH.md)
tools/            release build, notices, measurement and review scripts
```

## How it works

### Releases and packages

- The app reads `%windir%\AtlasOS\state.json` (installed version, mode, options,
  history) but never writes it; the PowerShell modules own it.
- The GitHub releases API supplies the latest release. Versions compare as Atlas
  tags them: `0.5.0-hotfix` is newer than `0.5.0`.
- Downloads go to `%LOCALAPPDATA%\AtlasOS\App\Downloads` and are trusted only
  once they match the asset's size and published digest.
- Packages unpack through a private staging directory into an immutable
  `...\App\Playbooks\<version>_<digest>`, so a bad package never replaces a good
  one and two packages that both call themselves 0.6.0 never share a directory
  (`src/services/playbook.rs`).
- Only packages with the front door script (Atlas 0.6.0 and newer) install
  here; older ones are refused with a pointer to AME Wizard.

### Install flow

- **Install Atlas** first relaunches the app elevated through UAC. A draft in
  `settings.json` (step, options, unpacked package) lets the elevated copy
  resume; it is written atomically, a failed save stops the relaunch, and
  success or cancelling clears it.
- Home lists the four steps. While a setup is unfinished, it marks the steps
  done and the current one, as the stepper does.
- Get ready shows Installation files, PC checks, the drivers choice, and Update
  Windows and Store apps, under one status bar that names the next action. Where
  the package needs a newer Windows (24H2 to 26H2), or recommends one (25H2), a
  Windows 11, version 26H2 card says what changes and asks for Microsoft's licence
  terms; Update Windows to version 26H2 then moves Windows first
  ([upgrading](../docs/upgrading.md#windows-version-transition)). Home shows the
  two parts of such an update, warns when 24H2 stops getting security updates,
  and says when an edition or version can't take the package at all. If Windows
  reinstalls itself instead of switching the new version on, Get ready says so and
  Your choices uses the choices recorded before the move, asking only for one
  nothing recorded ([Rebase](../docs/upgrading.md#rebase)). The checks keep
  their order while they run; then the ones that need attention come first and
  the passed ones fold into "N checks passed" behind **Show details**. A failed
  check offers the Windows Settings page that fixes it, such as **Open installed
  apps** for other antivirus software.
- Your choices asks one decision per screen (Defender, processor protections,
  updates), each as a question showing the consequence of the answer, then one
  screen of optional extras, where a page that depends on an option follows the
  page offering it (the browser picker comes after the apps). The Install
  summary lists the choices, with a caution mark on risky ones and Change
  links; the installation files, Windows, activation and the installation
  command (with Copy) are behind **Show details**.
- Windows Security is read once a second from the registry values AME Wizard
  reads: Tamper Protection, real-time protection, cloud-delivered
  protection and sample submission. One message bar says what is left to do.
  An unreadable switch shows as unreadable, never on or off; an elevated user
  can confirm it by hand, with the bar's check box, after checking Windows
  Security.
- Protection is never left off silently. Closing the window during a setup
  while a switch reads off asks first and offers Windows Security. Cancelling
  the setup leaves a reminder on Home, naming the switches still off, that
  survives a relaunch until a reading shows them back on. After an install that
  kept Defender, once its restart is done, Home and the completion window read
  the switches when they open and when the window is activated again, and show
  a dismissible reminder while any is off, or a warning if Defender is missing;
  "You're all set" appears only when every switch reads on. After an install
  that removed Defender, the completion window says the PC has no antivirus
  until another is installed.

System checks cover `playbook.conf`'s requirements and the front door's own
(`src/services/requirements/`):

| Check | Detail |
| --- | --- |
| Administrator, internet, mains power | |
| User Account Control on | The built-in Administrator account does not qualify. |
| Supported Windows edition and build | A public release, not Insider. |
| No pending Windows updates | Windows Update Agent, offline search. |
| No pending restart | |
| No third-party antivirus | Security Center. |
| Windows activation | Advisory. Atlas never changes activation; the row says so and links to the activation settings. |

A blocking check that fails or cannot run disables Continue; only an update
scan that could not run can be confirmed by hand. Until Update Windows and
Store apps has run, pending updates and a pending restart are notes for it to
handle, not blockers. The mandatory checks and security switches, pending
updates and restarts included, are read again just before the installer
starts.

### Running the install

- The app runs `Install-Atlas.ps1 -Option @(...) -Unattended` through
  `powershell.exe -Command` (so the option list arrives as a real array) with
  UTF-8 output. The child logs to `...\App\Logs`; `...\App\session.json`
  records the process and log.
- Launching holds a cross-process lock. The record is written before the child
  starts, and the child runs the front door only after a go-ahead, so no
  installer runs unrecorded and two windows cannot start overlapping installs
  (`src/services/installer/`, `session.rs`). Closing the window during the
  final checks starts nothing.
- While the install runs, the package, options and settings are locked, and
  closing the window needs confirmation. The install continues in the
  background; reopening the app picks the session up and shows its result.
- During and after a successful install, one view shows the phase, progress
  and start time, with the log and diagnostic export behind **Show details**. A
  failed install returns to the Install step with **Try again**. One bar says
  what happened, quoting the installer's last error line, with the next action
  beside it (**Relaunch as administrator** when Atlas lacks permission) and
  diagnostics under it; the log is behind **Show details**.

### Restart and completion

- **Restart my PC automatically after installation** (Settings and the Install
  summary; on by default) asks Windows to restart when the countdown after a
  successful install ends. The installing view says so while the install runs.
  The countdown lasts 10 seconds, or 60 seconds when it starts with the window
  in the background, whose taskbar button then flashes until the user returns.
  **Restart later**, which has keyboard focus during the countdown, stops it in
  every window following that install; the view then offers **Restart now**.
  Closing the window during the countdown asks first, offering **Keep
  open**, **Restart now** or **Close without restarting**; the countdown is
  held while the dialog is open and starts again on Keep open.
- Until Windows restarts after a successful install, Home shows a restart bar
  with **Restart now** in place of Reinstall or Update. It needs no state of its
  own: `launcher.json` was written for that install, the recorded install is
  newer, and Windows hasn't restarted since.
- When the install starts, the app writes `launcher.json` and the HKCU Run entry
  `AtlasInstallCompletion`, which opens a staged copy of the app with
  `--after-install-restart` (`src/services/session.rs`). Before-desktop setup
  skips the entry; its supervisor shows the page.
- The entry survives same-boot sign-ins. The first launch after a restart shows
  "Atlas is installed" if the recorded install is newer than `launcher.json`,
  and removes the entry about 20 seconds after sign-in, once Windows has started
  the Run key's other programs. A failed install removes the entry.
- Atlas's first-logon setup opens `--just-installed` only for accounts set up
  later, and shows a toast if it cannot find the app.

### Preparation and restart recovery

- Before preparation or an install, the app copies itself to the immutable,
  hash-named `%ProgramFiles%\Atlas Setup Recovery\<SHA-256>\AtlasManager.exe`.
  Restart registrations use this copy, so deleting the download or unplugging
  its drive does not break recovery. Before-desktop ISO setup already runs from
  the protected `%windir%\AtlasISO` and skips the copy.
- Jobs live in `Atlas Setup Recovery\Preparation` (scoped to the app's settings
  path) and `Atlas Setup Recovery\Media` (ISO and USB)
  (`src/services/recovery_app.rs`, `resources/prepare/Stage-App.ps1`). Only
  administrators and SYSTEM can write their workers, driver policies and
  journals. A precreated cancellation file lets the installing user request a
  stop without being able to replace executables or completion records.
- The worker and staging helper load PowerShell modules only from the inbox
  module root.
- An elevated start removes finished jobs beyond the newest five, never one
  whose worker may still be running.
- Reopening the app reattaches to the worker by PID and process creation time
  and reads its journal. If Windows cannot tell whether it is running, Atlas
  assumes it is; a process that reused the PID does not count.
- Journals in the older user-writable `%LOCALAPPDATA%\AtlasOS\App\Preparation`
  can only make Atlas wait for their worker, never prove success or provide a
  cancellation target. Once that worker exits, the user retries through the
  protected path.
- The app never starts a second servicing worker while one is running.
  Cancelling never kills an active Windows Update operation; preparation keeps
  its worker until Windows Update or the Store returns.
- Moving Windows to another release, and turning Windows Update on where an
  earlier Atlas, the user or a tool turned it off, paused or delayed it, go through the same worker
  and its functions-only `WindowsTransition.ps1`, staged beside it. Its record in
  `HKLM\SOFTWARE\AtlasOS\WindowsTransition` survives a lost draft; Home offers
  to continue or put the settings back while one is open, and closing the window
  before Windows has moved puts them back first. **Restart and continue** runs
  the worker's one-shot commit after recovery is registered and before the
  restart. Each move appends what it read, changed, searched for, found and
  installed to `windows-transition.log` in the protected preparation folder, which
  diagnostics include with the record, Windows Update history and the servicing
  logs.
- Preparation and direct installation share the Atlas package's
  `Scripts/Preparation/Update-Windows.ps1`. Direct installation checks live
  Windows and Store readiness first. Store's verification API can queue paused
  updates but does not install them.

[The release policy](../docs/windows-release-policy.md) covers installed-OS and
ISO eligibility. Servicing, UAC and restart recovery still need testing on
Windows for each candidate.

### Settings

Settings lists one card per setting, as Windows Settings does: **App theme**
and **Language** are combo boxes, and **Restart my PC automatically after
installation** is a toggle switch, locked while updates, an install or a media
job runs. A combo box choice applies only when committed. **Help and feedback**
holds Send a report and Export diagnostics, and **About** the version, licence
and links. The note about the translucent background shows only while it is
opaque and no contrast theme is on.

### Background work and tests

- Slow work (HTTP, Windows Update, WMI, extraction, the installer launch) runs
  on GPUI's background executor and reports through the model, which notifies
  its observers; pages are thin views over it. Each model-owned task carries a
  generation, so cancelling or repeating an operation drops the old task and a
  late result never lands in newer state (`src/model.rs`).
- The Windows Update, Security Center and licensing queries behind the checks
  time out rather than hang, with at most one worker each (`Bounded` in
  `src/services/requirements/`).
- The model tests (`src/model/tests/`) run the real model in headless GPUI
  with controlled adapters (elevation, Windows Security, checks, restart
  commands) and a real Windows PowerShell child running a stub front door.
  Coverage includes the final security decision, recovering installs that
  finished while the app was closed, retrying a recovered failure and the
  restart countdown's timer ownership.
