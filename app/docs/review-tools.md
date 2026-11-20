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
| `--playbook <file.apbx>` | Unpacks a local Atlas package on launch; a bare `.apbx` path, as "Open with" passes, does the same. |
| `--language <tag>` | Uses one of the available languages, or `qps-ploc` for the pseudo-locale, whatever the setting says. |
| `--export-diagnostics` | Saves a diagnostics ZIP without opening the window. |
| `--licenses [<new-file>]` | Opens a text copy of the licence notices, or saves one to a new file. |

[Tester builds](rc-testers-build.md) ignore `--playbook` and `.apbx` arguments.

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

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `idle` | Get ready before anything has run, without a package. |
| `busy`, `stopping` | Updates running, and stopping after the current operation. |
| `download` | A Windows update downloading. |
| `complete` | Updates finished. |
| `resume` | An unfinished install that goes on with its held choices. |
| `resumed` | Atlas reopened after its own restart. |
| `cancelled` | Updating stopped by the user. |
| `failed` | A Store app update that failed, with its error. |
| `failed-battery` | Store updates paused for low battery. |
| `unconfirmed` | Updating that couldn't confirm it finished. |
| `reboot` | A restart that updating needs. |
| `reboot-others` | **Restart now** asking first because other people are signed in. |
| `restart-persists` | A restart Windows still asks for after restarting. |
| `network`, `network-limited` | No usable connection, and a limited one. |
| `previous-worker` | Waiting for an update worker that's still running from earlier. |
| `ineligible` | An installed Atlas that the package can't update. |
| `pending-updates` | Pending updates and a pending restart, which the update step handles. |
| `checks-blocked` | Blocking checks, a check that couldn't run and advice, with updates waiting. |
| `checks-warnings` | Checks that pass with notes. |

### Microsoft Store and the component store

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `store-updating`, `store-repairing` | Microsoft Store updating or repairing itself before the apps. |
| `store-updated`, `store-bootstrapped`, `store-repaired`, `store-skipped-removed` | Each outcome for Microsoft Store itself once updating has finished. |
| `store-repair-failed` | A Store repair that failed. |
| `components-repairing` | Windows repairing its component store before updates. |
| `components-damaged` | An update that still failed on the component store. |
| `components-unrepairable` | Component store damage that Windows can't repair. |

### Moving Windows to a newer release

These states show Get ready on a PC that Atlas Manager [moves to a supported Windows release](../../docs/windows-transition.md).

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `windows-required` | A required move, before the licence terms are accepted. |
| `windows-ready` | A required move with the terms accepted. |
| `windows-choice`, `windows-keep` | An optional move, before the user chooses and after they choose to keep this version. |
| `windows-blockers` | Windows Update settings that Atlas turns on for the move. |
| `windows-running` | The new release downloading. |
| `windows-waiting` | Waiting for Windows Update to offer the new release. |
| `windows-restart` | The restart that finishes the move. |
| `windows-commit-failed` | A failed commit before that restart. |
| `windows-resumed` | Atlas reopened on the new release. |
| `windows-not-offered`, `windows-not-offered-25h2` | Windows Update not offering the release yet, while Atlas keeps looking. |
| `windows-not-offered-ended` | The wait ended and the settings were put back. |
| `windows-hardware`, `windows-disk-space`, `windows-managed` | A move stopped by hardware below the Windows 11 requirements, too little disk space or an organisation's update server. |
| `windows-blocked` | A setting Atlas didn't change that keeps Windows Update from running. |
| `windows-rolled-back`, `windows-failed` | A move that Windows rolled back, or that failed. |
| `windows-components-lost` | Atlas's changes gone after the update, with no sign that Windows reinstalled itself. |
| `windows-rebuilt` | Windows reinstalled itself during the move, and Atlas puts its changes back. |

### Your choices

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `options-rebase` | After Windows reinstalled itself, with every recorded choice kept. |
| `options-rebase-partial` | The same, with one choice missing from the record. |
| `options-update-path` | The first screen of an update from an older Atlas release. |
| `options-keep-partial` | **Keep my choices** asking the one choice the PC can't show. |
| `options-choose-again` | **Choose again** on a reinstall over a record the PC contradicts, with the first screen saying so. |
| `options-choose-again-defender`, `options-choose-again-mitigations` | What each answer changes on the Defender and processor protections screens. |
| `options-choose-again-fixed` | The extras an update can't undo: a second browser, and cleared boxes that turn features back on. |

### Windows Security and Install

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `security-on` | Tamper Protection off and the other switches still on. |
| `security-off` | Every switch off. |
| `security-readable-off` | Every readable switch off, and one that can't be read. |
| `security-unreadable` | No switch readable. |
| `security-absent` | Microsoft Defender gone because the user chose to remove it. |
| `security-defender-removed` | Defender removed by Atlas, and staying removed. |
| `security-defender-restore` | Defender removed by Atlas, and **Choose again** bringing it back. |
| `security-defender-missing` | Defender kept by the record but missing, though Atlas didn't remove it. |
| `install-ready` | The Install step, ready to start. |
| `install-refused` | The final checks refusing to start the installer. |
| `install-busy` | Another Atlas window starting an installation. |
| `install-choose-again` | The Install summary of a reinstall that chooses again. |

### Home and the completion window

| `ATLAS_PREPARATION_PREVIEW` | Shows |
| --- | --- |
| `home-24h2-pro` | An older Atlas on Windows 11, version 24H2 Pro, with a newer Atlas on offer; any `home-` state not listed here shows the same. |
| `home-25h2` | The same on version 25H2, where moving Windows is optional. |
| `home-24h2-home` | The same on Windows 11 Home, which the package doesn't support. |
| `home-23h2` | A Windows version with no update path. |
| `home-update-access`, `home-update-access-after` | Atlas's record of the Windows Update settings it turned on, before and after Windows moved. |
| `home-not-offered` | That record after Windows Update didn't offer the release. |
| `home-update-access-unreadable` | A record Atlas can't read. |
| `home-put-back-failed` | Putting the settings back failed. |
| `home-restart-others` | **Restart now** asking first because someone else is signed in. |
| `home-defender-not-restored` | Microsoft Defender still removed though Atlas's record kept it. |
| `home-defender-missing` | Defender missing with no Atlas package to blame. |
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

| `ATLAS_REPORT_PREVIEW` | Shows |
| --- | --- |
| `invalid` | Every field marked invalid. |
| `collecting` | Diagnostics being collected. |
| `ready` | An empty report with diagnostics ready. |
| `prepare-failed` | Diagnostics that couldn't be prepared. |
| `waiting`, `sending` | A filled-in report waiting for diagnostics, and sending. |
| `sent` | The receipt of a sent report. |
| `failed` | A send that failed and can be retried. |
| `busy` | The report service busy. |
| `outdated` | An app version the report service doesn't accept. |
| `diagnostics` | Diagnostics the service refused. |

### ISO and USB

`tools\Review-Iso.ps1 -State <state>` opens one of these states in `target\debug\AtlasManager.exe` with isolated settings, and never builds media.
It saves a screenshot and the accessibility tree under `%TEMP%`.
Its parameters set the language, theme, window size and a scroll offset, and `-Desktop` adds the before-desktop bar.
It sets `ATLAS_ISO_PREVIEW`, and for `prepare-` states also `ATLAS_PREPARATION_PREVIEW`.

| Screen | States |
| --- | --- |
| Home | `home` |
| Files | `files`, `files-empty`, `files-checked`, `checking`, `not-elevated`, `failed`, `release-unknown`, `release-unlisted`, `package-unsupported` |
| Windows setup | `windows`, `account-empty`, `account-invalid`, `network-drivers` |
| Your choices | `choices`, `choices-unsupported`, `before`, `before-desktop` |
| Review and Create | `review`, `review-before`, `progress`, `progress-network`, `build-failed`, `package-changed`, `cancelled`, `complete` |
| Preparation | `prepare-idle`, `prepare-busy`, `prepare-stopping`, `prepare-download`, `prepare-complete`, `prepare-resume`, `prepare-failed`, `prepare-failed-battery`, `prepare-unconfirmed`, `prepare-reboot`, `prepare-restart-persists`, `prepare-network`, `prepare-network-limited`, `prepare-previous-worker` |
| USB | `usb-select`, `usb-empty`, `usb-review`, `usb-progress`, `usb-failed`, `usb-failed-iso`, `usb-failed-unchanged`, `usb-scan-failed`, `usb-cancelled-unchanged`, `usb-complete`, `usb-eject-failed`, `usb-ejected` |

## Scripts

Run these from `app/` while the app is open.

| Script | Does |
| --- | --- |
| `tools\Capture-Window.ps1 -OutFile shot.png` | Saves a screenshot of the running window. |
| `tools\Get-AccessibilityTree.ps1` | Prints what UI Automation, and so Narrator, sees, with focus and toggle states. |
| `tools\Get-AccessibilityTree.ps1 -Invoke <name>` | Presses a control through its accessible action, as voice control would, even when it's scrolled out of view. |
| `tools\Review-Iso.ps1 -State <state>` | Captures an ISO, USB or preparation state ([ISO and USB](#iso-and-usb)). |

For example, `tools\Get-AccessibilityTree.ps1 -Invoke 日本語` switches the language through the accessible action.

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
