# Review tools

This page lists the command-line flags, environment variables, preview states and scripts for reviewing Atlas Manager's screens.
It's for contributors who check layout, copy, translations and accessibility without installing Atlas or changing Windows.

> [!NOTE]
> Variables marked **Debug** work only in debug builds, such as the one `cargo run` makes.
> Release builds ignore them.

## Command-line flags

| Flag | Effect |
| --- | --- |
| `--page <page>` | Opens `home`, `iso`, `install`, `settings`, `report` or `installed`. |
| `--step <step>` | Opens an install step: `ready`, `options`, `security` or `install`. |
| `--just-installed` | Opens the completion window that follows the install's restart. |
| `--package <file.atlaspkg>` | Unpacks a local Atlas package on launch; a bare `.atlaspkg` path, as "Open with" passes, does the same, and a bare `.apbx` path opens the Install page to explain that it isn't an Atlas package. |
| `--language <tag>` | Uses one of the available languages, or `qps-ploc` for the pseudo-locale, whatever the setting says. |
| `--export-diagnostics` | Saves a diagnostics ZIP without opening the window. |
| `--licenses [<new-file>]` | Opens a text copy of the licence notices, or saves one to a new file. |

[Tester builds](rc-testers-build.md) ignore `--package` and package path arguments.

## Environment variables

Variables last for the PowerShell session.
Clear one with `Remove-Item Env:<name>`, for example `Remove-Item Env:ATLAS_LANGUAGE`.

| Variable | Builds | Effect |
| --- | --- | --- |
| `ATLAS_APP_DATA=<dir>` | All | Keeps settings, downloads, unpacked packages, install logs and the session in `<dir>` instead of `%LOCALAPPDATA%\AtlasOS\App`. |
| `ATLAS_LANGUAGE=<tag>` | All | Works like `--language`; the flag wins when both are set. |
| `ATLAS_FORMAT_LOCALE=<tag>` | All | Formats numbers, dates and times with that locale's standard formats, for example `de-DE`. |
| `ATLAS_WINDOWS_LANGUAGES=<tag>,<tag>` | All | Replaces the Windows display-language list; `error` simulates a failed query. |
| `ATLAS_STATE_FILE=<state.json>` | Debug | Reads this file instead of `%windir%\AtlasOS\state.json`, to show the installed and update-available states on a PC without Atlas. |
| `ATLAS_TEXT_SCALE=<scale>` | Debug | Previews a text size from 1.0 to 2.25 without changing Windows. |
| `ATLAS_HIGH_CONTRAST=1` | Debug | Previews a dark contrast theme without changing Windows. |
| `ATLAS_REVIEW_OTHER_SESSIONS=<names>` | Debug | Treats these comma-separated account names as signed in besides you, so the question before a restart can be reviewed. |
| `ATLAS_REVIEW_NO_RESTART=1` | Debug | Logs a restart Atlas asks for and reports it as accepted while Windows keeps running, so a countdown or **Restart now** is safe to capture. |
| `ATLAS_SECURITY_PREVIEW=<reading>` | Debug | Replaces the Windows Security reading ([readings](#windows-security-readings)). |
| `ATLAS_PREPARATION_PREVIEW=<state>` | Debug | Opens the install flow, Home or the completion window in a preview state ([preview states](#preview-states)). |
| `ATLAS_REPORT_PREVIEW=<state>` | Debug | Opens **Send a report** in a preview state ([Send a report](#send-a-report)). |
| `ATLAS_DIAGNOSTICS_PREVIEW=<state>` | Debug | Opens **Settings** with a diagnostics export in a preview state ([Diagnostics export](#diagnostics-export)). |
| `ATLAS_ISO_PREVIEW=<state>` | Debug | Opens ISO creation or the USB panel in a preview state ([ISO and USB](#iso-and-usb)). |
| `ATLAS_DESKTOP_PREVIEW=1` | Debug | Makes the app behave as it does in before-desktop setup. |

`ATLAS_FORMAT_LOCALE` ignores customisations made in Windows.
The one exception is a date when `<tag>` is the PC's own regional format, which can still follow a customised long date.

## Preview states

Preview states never update Windows, restart the PC, install Atlas, build media or send a report.
`ATLAS_PREPARATION_PREVIEW` opens the install flow with a stand-in Atlas package and passing checks, unless the state says otherwise.

> [!WARNING]
> `ATLAS_SECURITY_PREVIEW` only replaces the switch readings, and `ATLAS_DESKTOP_PREVIEW` only changes how the app behaves.
> With either set on its own, the app can still update Windows and install Atlas.

### Get ready

Previews never start updating or move on by themselves, so each state stays as it opens.

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `idle` | Get ready before anything has run, without a package. |
| `package-downloading`, `package-failed` | The Atlas package downloading, and a download that failed, with its error behind **Show details**. |
| `busy`, `stopping` | Store apps updating, with their share on the bar, and stopping after the current operation. |
| `download` | A Windows update downloading. |
| `complete` | Updates finished. |
| `resume` | An unfinished install that goes on with its held choices. |
| `resumed` | Atlas reopened after its own restart, about to carry on updating. |
| `cancelled` | Updating stopped by the user, with **Resume updates**. |
| `failed` | A Store app update that failed because the app was open. |
| `failed-battery` | Store updates paused for low battery. |
| `unconfirmed` | Updating that couldn't confirm it finished. |
| `reboot` | A restart that updating needs, with no countdown, as with automatic restart off. |
| `reboot-countdown` | The countdown to that restart, with **Restart now** and **Restart later**. |
| `reboot-others` | **Restart now** asking first because other people are signed in. |
| `restart-persists` | A restart Windows still asks for after restarting. |
| `network`, `network-limited` | No usable connection, and a limited one. |
| `previous-worker` | Waiting for an update worker that's still running from earlier. |
| `ineligible` | An installed Atlas that the package can't update. |
| `manager-outdated` | The package row refusing a package that needs a newer Atlas Manager, with **Download Atlas Manager**. |
| `drivers-required` | An ISO that left the driver choice until after sign-in, asking it. |
| `pending-updates` | Pending updates and a pending restart, which updating takes care of. |
| `checks-blocked` | Blocking checks, a check that couldn't run and advice, with updates waiting. |
| `checks-warnings` | Checks that pass with notes. |

### Microsoft Store and the component store

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `store-updating`, `store-repairing` | Microsoft Store updating or repairing itself before the apps. |
| `store-updated`, `store-bootstrapped`, `store-repaired` | Updating finished after Microsoft Store was updated, reinstalled or repaired, which only the log says. |
| `store-skipped-removed` | Updating finished on a PC where Microsoft Store is turned off, so Store apps weren't updated. |
| `store-repair-failed` | A Store repair that failed, with **Try repair again** and reinstalling behind **Show details**. |
| `components-repairing` | Windows repairing its component store before updates. |
| `components-damaged` | An update that still failed on the component store, with **Restart and try again**. |
| `components-unrepairable` | Component store damage that Windows can't repair, with **Create an Atlas ISO**. |

### Moving Windows to a newer release

These states show Get ready on a PC that Atlas Manager [moves to a supported Windows release](../../docs/windows-transition.md), with the move's card first.

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `windows-required` | A required move, before **Accept and update**. |
| `windows-ready` | A required move with the terms accepted, about to start. |
| `windows-choice`, `windows-keep` | An optional move, before the user chooses and after they choose to keep this version. |
| `windows-blockers` | Windows Update settings that Atlas turns on for the move. |
| `windows-checks-space`, `windows-checks-hardware`, `windows-checks-managed` | A PC check finding too little free space, hardware below the Windows 11 requirements or an organisation's update server, before the move starts. |
| `windows-running` | The new release downloading. |
| `windows-waiting` | The first run waiting for Windows Update to offer the new release, 25 minutes in. |
| `windows-stopped` | The move stopped by the user, with **Resume updates**. |
| `windows-restart` | The restart that finishes the move, with no countdown, as with automatic restart off. |
| `windows-restart-countdown` | The countdown to that restart, with **Restart now** and **Restart later**. |
| `windows-commit-failed` | Windows unable to get ready for that restart, with **Try again**. |
| `windows-resumed` | Atlas reopened on the new release. |
| `windows-not-offered`, `windows-not-offered-25h2` | Windows Update not offering the release yet, while Atlas keeps looking, 34 minutes in. |
| `windows-not-offered-ended` | The wait ended and the settings were put back. |
| `windows-not-offered-put-back-failed` | The wait ended and putting the settings back failed. |
| `windows-hardware` | A move stopped by hardware below the Windows 11 requirements, which the PC check then finds too, so the check says it. |
| `windows-disk-space`, `windows-managed` | A move stopped by too little disk space or an organisation's update server, which the PC checks didn't find. |
| `windows-blocked` | A service Windows Update needs, turned off. |
| `windows-rolled-back`, `windows-failed` | A move that Windows rolled back, or that failed. |
| `windows-components-lost` | Atlas's changes gone after the update, with no sign that Windows reinstalled itself. |
| `windows-rebuilt` | Windows reinstalled itself during the move, and Atlas puts its changes back. |

Keeping this version during a move asks first, in a dialog no preview opens.

### Your choices

Every preview asks the keyboard question as on a PC with two keyboard layouts, except `options-one-layout`.

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `options-first-install` | A first install's questions, with the optional extras unfolded. |
| `options-extras-folded` | The same with the extras folded by Hide. |
| `options-one-layout` | The same on a PC with one keyboard layout, which Atlas answers the keyboard question for. |
| `options-rebase` | After Windows reinstalled itself, with every recorded choice kept. |
| `options-rebase-partial` | The same, asking the one choice missing from the record. |
| `options-update-path` | The first screen of an update from an older Atlas release. |
| `options-keep-partial` | **Keep my choices** asking the one choice the PC can't show. |
| `options-choose-again` | **Choose again** on a reinstall over a record the PC contradicts, with the first screen saying so. |
| `options-choose-again-defender`, `options-choose-again-mitigations` | What each answer changes on the Defender and processor protections questions. |
| `options-choose-again-fixed` | The extras, unfolded, an update can't undo: a second browser, and cleared boxes that turn features back on. |

### Windows Security and Install

Windows Security previews never open Windows Security, move on or pass the step over by themselves.

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `security-checking` | The step before its first reading. |
| `security-on` | Tamper Protection off and the other switches still on. |
| `security-off` | Every switch off. |
| `security-readable-off` | Every readable switch off, and one that couldn't be read. |
| `security-unreadable` | No switch readable. |
| `security-absent` | Microsoft Defender gone because the user chose to remove it. |
| `security-defender-removed` | Defender removed by Atlas, and staying removed. |
| `security-defender-restore` | Defender removed by Atlas, and **Choose again** bringing it back. |
| `security-defender-missing` | Defender kept by the record but missing, though Atlas didn't remove it. |
| `install-ready` | The Install step, ready to start. |
| `install-choose-again` | The Install step of a reinstall that chooses again. |
| `install-refused` | The final checks unable to start the installer. |
| `install-busy` | Another Atlas window starting an installation. |
| `install-invalid-options` | The final checks refusing choices that leave the browser picker without an answer. |
| `install-changed` | The final checks finding a check and a protection switch changed. |
| `install-taken-over` | Another Atlas window using this setup. |
| `install-record-unreadable` | An install record Atlas can't read. |
| `install-failed` | An attempt that failed while it changed Windows, with Defender still there. |
| `install-not-elevated` | An attempt without administrator permission, in a window that has none. |
| `install-requirements` | An attempt the installer stopped for a requirement the PC didn't meet. |
| `install-preparation` | An attempt the installer stopped because Windows or Store updates weren't finished. |
| `install-lost` | An attempt that ended without reporting a result. |

### Installing

These states show the installing view, which covers every page from the final checks until the restart.
**Restart now** and **Try again** restart nothing while they show.

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `installing-checking` | The final checks before the installer starts. |
| `installing-preflight`, `installing-staging`, `installing-applying`, `installing-finishing` | The installer checking the PC, getting its files ready, setting up Windows and finishing. |
| `installing-manual` | Setting up Windows with automatic restart off. |
| `installing-output-error` | A log Atlas can't follow while the installer carries on. |
| `installing-countdown` | The restart counting down, from 60 seconds. |
| `installing-restart-error` | A restart Windows refused, with **Try again**. |
| `installing-restart-later` | The countdown stopped with **Restart later**. |
| `installing-restart-off` | Installed, with automatic restart off. |
| `installing-restart-others` | **Restart now** asking first because someone else is signed in. |
| `installing-restarting` | Windows restarting. |

### Home and the completion window

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `home-fresh` | A PC without Atlas, on Windows that has just been installed, with **What happens** under the hero. |
| `home-fresh-checking`, `home-fresh-check-failed` | The same while the release check runs, and after it failed. |
| `home-used` | A PC without Atlas, on Windows that has been in use, where Home recommends reinstalling it. |
| `home-used-question` | The same, with the question **Install Atlas** asks there. |
| `home-flow` | A PC without Atlas, with a setup under way at **Your choices** after Get ready finished, which **Setting up Atlas** marks done. |
| `home-24h2-pro` | An older Atlas on Windows 11, version 24H2 Pro, with a newer Atlas on offer; any `home-` state not listed here shows the same. |
| `home-25h2` | The same on version 25H2, where moving Windows is optional. |
| `home-24h2-home` | The same on Windows 11 Home, which the package doesn't support. |
| `home-23h2` | A Windows version with no update path. |
| `home-up-to-date` | The latest Atlas, with its choices and installation history. |
| `home-checking`, `home-check-failed` | The same while the release check runs, and after it failed. |
| `home-state-error` | An installation record Atlas can't read. |
| `home-settings-not-saved`, `home-session-unreadable` | The latest Atlas with a notice about the app's own settings, and about an install record it can't read. |
| `home-manager-update` | A release newer than this Atlas Manager, with the note that offers **Download Atlas Manager**; `--page settings` shows the same note in **About**. |
| `home-manager-outdated` | The same release, after Get ready found its package needs the newer Atlas Manager. |
| `home-restart`, `home-restart-failed` | An install's restart still owed, and Windows refusing it. |
| `home-update-access`, `home-update-access-after` | Atlas's record of the Windows Update settings it turned on, before and after Windows moved. |
| `home-not-offered` | That record after Windows Update didn't offer the release. |
| `home-update-access-unreadable` | A record Atlas can't read. |
| `home-put-back-failed` | Putting the settings back failed. |
| `home-restart-others` | **Restart now** asking first because someone else is signed in. |
| `home-defender-not-restored` | Microsoft Defender still removed though Atlas's record kept it. |
| `home-defender-missing` | Defender missing with no Atlas package to blame. |
| `installed` | The completion window after a first install that kept Microsoft Defender; `ATLAS_SECURITY_PREVIEW` sets what its switches read. |
| `installed-defender-removed` | The same after a first install that removed Defender. |
| `installed-defender-not-restored` | The same with Atlas's record keeping Defender while Atlas's package still removes it, with **Reinstall Atlas**. |
| `installed-manual-drivers` | The same where the user installs drivers themselves, with the line under the setup card. |
| `installed-update-off` | The completion window after an update whose last step turned Windows Update off again, as the user chose. |
| `installed-choices-not-applied` | The completion window naming a choice the installation couldn't apply. |

### Windows Security readings

`ATLAS_SECURITY_PREVIEW` sets the reading behind the protection reminders on Home and in the completion window.

| `ATLAS_SECURITY_PREVIEW` | Reading |
| --- | --- |
| `on` | Every switch on. |
| `off` | Every switch off. |
| `some-off` | Tamper Protection and Cloud-delivered protection off. |
| `unreadable` | Tamper Protection unreadable, and the rest on. |
| `absent` | Microsoft Defender removed. |

### Send a report

`ATLAS_REPORT_PREVIEW` collects nothing, and **Send report** fails without connecting.
The footer's status line says what's happening, and after a failure its button is **Try again**.

| `ATLAS_REPORT_PREVIEW` | Shows |
| --- | --- |
| `invalid` | Every field marked invalid, with the contact details over their limit and counted. |
| `collecting` | Diagnostics being collected. |
| `ready` | An empty report with diagnostics ready. |
| `suggestion` | An empty suggestion, without diagnostics. |
| `limit` | A message near the longest the service accepts, with its character count. |
| `prepare-failed` | Diagnostics that couldn't be prepared, with the error behind **Show details**. |
| `waiting`, `sending` | A filled-in report waiting for diagnostics, and sending. |
| `sent` | The receipt of a sent report. |
| `failed` | A send that failed and can be retried, with the report website as the fallback. |
| `busy` | The report service busy. |
| `outdated` | An app version the report service doesn't accept, with **Download Atlas Manager** in the bar and the report website as the footer's button. |
| `diagnostics` | Diagnostics the service refused. |

### Diagnostics export

`ATLAS_DIAGNOSTICS_PREVIEW` collects nothing.
It shows the export in **Settings** > **Help**, as every page's help row shows it.

| `ATLAS_DIAGNOSTICS_PREVIEW` | Shows |
| --- | --- |
| `exporting` | An export running, with **Export diagnostics** as it was and a spinner where the result goes. |
| `saved` | The saved ZIP, named by the date and time it was saved, with the name of its folder. |
| `failed` | An export that failed, with **Try again** and the error behind **Show details**. |

### Dialogs

Closing the window, with the title bar's **Close** button, asks first in these states.
**Restart now** restarts nothing while `ATLAS_REVIEW_NO_RESTART=1` is set.

| State | Asks |
| --- | --- |
| `ATLAS_PREPARATION_PREVIEW=installing-countdown` | Whether to restart before closing. |
| `ATLAS_PREPARATION_PREVIEW=security-off` | Whether to close with the protection switches off. |
| `ATLAS_PREPARATION_PREVIEW=installing-applying`, `installing-manual` | Whether to close while installing, with and without the restart afterwards. |
| `ATLAS_PREPARATION_PREVIEW=installing-checking` | Whether to stop before installing. |
| `ATLAS_PREPARATION_PREVIEW=busy` | Whether to stop updating. |
| `ATLAS_ISO_PREVIEW=progress` | Whether to stop creating the ISO. |

`home-used-question` opens Home's question before installing on Windows that has been in use, and `installing-restart-others` with `ATLAS_REVIEW_OTHER_SESSIONS` opens the question before restarting while other people are signed in.

### ISO and USB

`tools\Review-Iso.ps1 -State <state>` opens one of these states in `target\debug\AtlasManager.exe` with isolated settings, and never builds media.
It saves a screenshot and the accessibility tree under `%TEMP%`.
Its parameters set the language, theme, window size and a scroll offset, and `-Desktop` adds the before-desktop bar.
It sets `ATLAS_ISO_PREVIEW`, and for `prepare-` states also `ATLAS_PREPARATION_PREVIEW`.

ISO previews never ask for administrator permission, fetch a package or check the files by themselves.
USB previews show made-up drives, and never list drives, check the ISO or write a drive.

| Screen | States |
| --- | --- |
| Home | `home` |
| Windows | `windows-empty` (the download on offer), `download-change` (its language and architecture open), `download-progress`, `download-failed`, `source-menu` (the Windows ISO's Change menu), `package-offline` (no latest package, with **Open package file**), `checking`, `files-checked`, `this-pc-arm64` (an ISO for another kind of processor) |
| Windows, bars | `not-elevated`, `elevation-declined`, `failed`, `release-unknown`, `release-unlisted`, `edition-unsupported`, `iso-customised`, `windows-unsupported`, `package-unsupported` (an Atlas 0.5.0 package), `manager-outdated` |
| Setup | `setup` (two editions, Windows Setup choosing), `setup-another-pc`, `account-empty`, `account-invalid`, `setup-now` (the questions inline), `setup-extras-folded` (the extras folded by Hide), `before-desktop`, `choices-unsupported` |
| Create | `review`, `review-before` (a choice that reduces protection), `review-space` (too little free space, with **Open Storage settings**), `progress` (part of the way through writing the ISO), `progress-network`, `cancelling`, `build-failed`, `network-failed`, `cancelled`, `complete`, `complete-network-inbox` |
| Preparation | `prepare-idle`, `prepare-busy`, `prepare-stopping`, `prepare-download`, `prepare-complete`, `prepare-resume`, `prepare-failed`, `prepare-failed-battery`, `prepare-unconfirmed`, `prepare-reboot`, `prepare-restart-persists`, `prepare-network`, `prepare-network-limited`, `prepare-previous-worker` |
| USB | `usb-select` (one drive, picked by itself), `usb-drives` (two drives and one too small), `usb-too-small`, `usb-empty`, `usb-looking`, `usb-confirm` (the erase question), `usb-not-elevated`, `usb-elevation-declined` |
| USB, ISO | `usb-iso-missing`, `usb-iso-checking`, `usb-iso-unsupported`, `usb-iso-unreadable`, `usb-working-space` |
| USB, writing | `usb-progress`, `usb-cancelling`, `usb-complete`, `usb-eject-failed`, `usb-failed`, `usb-failed-unchanged`, `usb-drive-changed`, `usb-cancelled`, `usb-cancelled-unchanged`, `usb-scan-failed` |

## Scripts

Run these from `app/` while the app is open.

| Script | Does |
| --- | --- |
| `tools\Capture-Window.ps1 -OutFile shot.png` | Saves a screenshot of the running window. |
| `tools\Get-AccessibilityTree.ps1` | Prints what UI Automation, and so Narrator, sees, with focus and toggle states. |
| `tools\Get-AccessibilityTree.ps1 -Invoke <name>` | Presses a control through its accessible action, as voice control would, even when it's scrolled out of view. |
| `tools\Review-Iso.ps1 -State <state>` | Captures an ISO, USB or preparation state ([ISO and USB](#iso-and-usb)). |

For example, `tools\Get-AccessibilityTree.ps1 -Invoke 日本語` switches the language through the accessible action.

## README screenshots

`tools\Update-ReadmeScreenshots.ps1` saves the README's pictures of the **Get ready** page as `docs/images/atlas-manager-get-ready-light.png` and `atlas-manager-get-ready-dark.png`.
It builds nothing and uses the existing debug build, `target\debug\AtlasManager.exe`, so run `cargo build --locked` first; without that build it stops with an error.

For each theme, the script opens the debug build on the **Get ready** page in the `complete` preview state, in British English, with its own settings under `%TEMP%` and `ATLAS_REVIEW_NO_RESTART=1`.
Those settings answer the driver question with Windows Update, so the picture doesn't depend on the PC's own driver policy.
It sizes the window to 960 × 680, waits for it to draw, captures it with `tools\Capture-Window.ps1` and closes it, so a window appears for a few seconds each time.
It clears every `ATLAS_` variable for the run and restores them afterwards.
`-Theme light` or `-Theme dark` captures one theme.

```powershell
cargo build --locked
.\tools\Update-ReadmeScreenshots.ps1
```

## Language checks

```powershell
.\AtlasManager.exe --language de
$env:ATLAS_LANGUAGE = 'zh-TW'; .\AtlasManager.exe
cargo test --bin AtlasManager i18n
cargo run --example i18n_spike
```

`cargo test --bin AtlasManager i18n` runs the negotiation, catalog, plural, formatting and wording tests, including the tests that prove the catalog gate rejects broken catalogs.
`cargo run --example i18n_spike` opens the GPUI rendering probe for right-to-left, CJK and mixed scripts.
[Languages](i18n.md) covers what these check.
