# The install flow

This page describes how Atlas Manager installs and updates Atlas, from Home through the four steps to the restart, and how it recovers when something interrupts it.
It's for contributors who change the flow and reviewers who check its behaviour.

## Steps

| Step | What happens |
| --- | --- |
| **Get ready** | The app elevates once, runs the system checks, updates Windows and Microsoft Store apps, and fetches the Atlas package. |
| **Your choices** | You choose the Atlas options. |
| **Windows Security** | You turn off the protection switches while the app watches them live. |
| **Install** | The app runs the front door, `Entry\Install-Atlas.ps1`, the script in the Atlas package that installs Atlas. |

Checks and updates come first, so problems are fixed before protection goes off.
Windows Security comes last, so protection is off for as short a time as possible.
`src/flow.rs` enforces the order: the flow moves forward one step at a time, and nothing moves while an install runs ([architecture](architecture.md#the-model-and-background-tasks)).

## Starting the flow

- **Install Atlas** first relaunches the app elevated through User Account Control (UAC).
- A draft in `settings.json` holds the step, the options and the unpacked package, so the elevated copy can resume.
  The app writes it atomically, a failed save stops the relaunch, and success or cancelling clears it.
- Home lists the four steps.
  While a setup is unfinished, it marks the steps already done and the current one, as the stepper does.

## Get ready

Get ready shows four cards under one status bar that names the next action: **Installation files**, **PC checks**, the drivers choice, and **Update Windows and Store apps**.

- The checks keep their order while they run.
  Then the ones that need attention come first, and the passed ones fold into "N checks passed" behind **Show details**.
- A failed check offers the Windows Settings page that fixes it, such as **Open installed apps** for other antivirus software.

### Moving Windows to a newer release

Where the package needs a newer Windows release, or recommends one, a card names that release, says what changes and asks you to accept Microsoft's licence terms.
The **Update Windows to version …** button then moves Windows before anything else ([Moving Windows to a newer release](../../docs/windows-transition.md)).

- Home shows the two parts of such an update, warns when the installed Windows version stops getting security updates, and says when an edition or version can't take the package at all.
- If Windows reinstalls itself instead of switching the new version on, Get ready says so.
  Atlas then puts itself back on the rebuilt Windows, an install mode called [Rebase](../../docs/windows-transition.md#rebase).
- A Rebase uses the choices recorded before the move, and **Your choices** asks only for a choice that nothing recorded.
  It always keeps those choices; to change them afterwards, choose **Reinstall Atlas**, then **Choose again**.

### System checks

The checks cover the requirements in `playbook.conf` and the front door's own (`src/services/requirements/`).

| Check | Detail |
| --- | --- |
| Administrator | The app runs elevated. |
| Internet | A working connection. |
| Mains power | The PC isn't running on battery. |
| User Account Control on | The built-in Administrator account doesn't qualify. |
| Supported Windows edition and build | A public release, not an Insider build. |
| No pending Windows updates | Windows Update Agent, searched offline. |
| No pending restart | Windows hasn't asked for a restart. |
| No third-party antivirus | Read from Security Center. |
| Windows activation | Advisory: the row says Atlas never changes activation, and links to the activation settings. |

- A blocking check that fails or can't run disables **Continue**.
  Only an update scan that couldn't run can be confirmed by hand.
- Until **Update Windows and Store apps** has run, pending updates and a pending restart are notes for it to handle, not blockers.
- Just before the installer starts, the app reads the mandatory checks and the protection switches again, pending updates and restarts included.

### Updates

Get ready installs recommended Windows updates, updates Microsoft Store and finishes updates for all installed Store apps.
Third-party WinGet apps are out of scope.
Atlas stays blocked until this preparation succeeds.

The Atlas package's `Scripts/Preparation/Update-Windows.ps1` does the work, run by `src/services/preparation.rs`, whose comments explain each provider rule.
The front door runs the same script to check Windows and Store readiness before it installs.

- **Network.** The app checks the connection before each provider pass.
  Wi-Fi and Ethernet work, while offline, captive-portal, metered, roaming and restricted connections stop with a network-settings action.
  You must install a missing Wi-Fi driver yourself.
- **Scope.** Optional previews and feature updates are left out, because a feature update can leave the supported builds.
  The pending-update check uses the same rules.
- **Providers.** Windows Update Agent runs search, download, install and rescan passes.
  AppInstallManager's `SearchForAllUpdatesAsync` installs Store app updates automatically and restarts the apps, and the screen warns that they'll close.
  Progress counts completed app updates.
  Microsoft Store's verification API can queue paused updates, but doesn't install them.
- **Completion.** Each provider must report completion.
  Partial or unknown results never continue, and an empty first scan alone proves nothing.
  Errors, missing Store registration, paused work, timeouts and reappearing updates fail with diagnostics and a suggested action.
- **Restarts.** The app never restarts the PC on its own; you choose **Restart and continue**.
  As soon as preparation needs a restart, the app saves the install draft and arms a per-user Run entry, `AtlasWindowsPreparation`, that waits for a new boot.
  Restarting from Windows therefore resumes Atlas too, and signing out first doesn't use the entry up.
  The entry removes itself after the restart, or at its next launch once the draft is abandoned.
  Before-desktop setup relaunches through its own shell.
- **Resuming.** **Continue updates** runs preparation again.
  An earlier scan never counts as lasting permission to install.
- **Stopping.** Closing the window offers to stop after the current operation, and keeps the window open.
  The worker never stops a Windows servicing provider by force.

### Driver updates

You choose how Windows gets drivers before preparation runs.
The default keeps an existing Atlas policy that blocks driver updates; otherwise the app recommends Windows Update.

| Choice | Effect |
| --- | --- |
| **Get drivers through Windows Update** | Removes the `DriverSearching\SearchOrderConfig` policy, restoring Windows' usual search preference. |
| **Install drivers myself** | Leaves driver updates out of preparation and out of the update checks, and sets the machine's `DriverSearching\SearchOrderConfig` to 0 so Windows never searches Windows Update for drivers. |

- Both choices apply the paired policies in the Atlas folder's `2. Drivers\Drivers from Windows Update`, which the app and the ISO share.
- An install applies the choice before the first update scan.
- Neither choice removes drivers installed before Atlas Manager opened.
- The [Atlas installation guide](https://atlasos.net/docs/install/manager/) describes the same choices for users.
- Microsoft documents the value as the [`DriverSearchPlaces` search order policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-admx-devicesetup#driversearchplaces-searchorderconfiguration).
  Inbox drivers that come with Windows servicing are outside the [driver exclusion for quality updates](https://learn.microsoft.com/windows/deployment/update/waas-configure-wufb#exclude-drivers-from-quality-updates).

## Your choices

- **Your choices** asks one decision per screen (Defender, processor protections and updates), each as a question that shows the consequence of each answer.
- One screen of optional extras follows.
  A page that depends on an option comes after the page that offers it, so the browser picker comes after the apps.
- The Install summary lists the choices, with a caution mark on risky ones and **Change** links.
  The installation files, Windows, activation and the installation command (with **Copy**) are behind **Show details**.

### Updating or reinstalling

When you update or reinstall the installed Atlas, **Your choices** first asks **Keep my choices** or **Choose again**.
It lists the choices this PC has now, and what the PC shows wins over Atlas's record (`src/model/rebase.rs`, `src/services/legacy_choices.rs`).

- **Keep my choices** locks every choice, and asks only for a required one the PC can't show.
- **Choose again** opens every screen from what the PC has, marks the answer it has now, and says under each answer what it changes.
  It also fixes what an update can't undo: Edge already removed, and a Toolbox or browser that Atlas installed.
- The summary's first row, **How Atlas updates**, gives the answer.
- An unfinished install skips that first screen and continues as it began.
  The Windows Security bar follows its recorded mode and update path.
- If an unfinished update began with **Keep my choices** and its plan hasn't started, its choices stay held to what the PC shows.

[Keep my choices or Choose again](../../docs/upgrading.md#keep-my-choices-or-choose-again) covers what each answer does.

## Windows Security

Atlas reads the four Windows Security protection switches once a second: Tamper Protection, Real-time protection, Cloud-delivered protection and Automatic sample submission.
It reads the registry values behind Windows Security's **Virus & threat protection settings** page, by the same rules as the front door's check (`src/services/security.rs`).

- One message bar says what's left to do.
- A switch Atlas can't read shows as unreadable, never on or off.
  An elevated user can confirm it by hand with the bar's check box, after checking Windows Security.
- Without Microsoft Defender there's nothing to turn off, and the bar says what happens to Defender.
  It stays removed, this install brings it back, or it's missing and Atlas can't bring it back.
  A missing Defender is a warning that doesn't stop the install.

### Protection reminders

Protection is never left off silently.

- Closing the window during a setup while a switch reads off asks first, and offers Windows Security.
- Cancelling the setup leaves a reminder on Home that names the switches still off.
  It survives a relaunch until a reading shows them back on.
- After an install that kept Defender, once its restart is done, Home and the completion window read the switches when they open and whenever the window is activated again.
  They show a dismissible reminder while any switch is off, or a warning if Defender is missing.
  "You're all set" appears only when every switch reads on.
- After an install that removed Defender, the completion window says the PC has no antivirus until another is installed.
- When Atlas's record kept Defender but Atlas's package still removes it, Home and the completion window say it's still removed and how to bring it back.

## Running the install

- The app runs `Install-Atlas.ps1 -Option @(...) -Unattended` through `powershell.exe -Command`, so the option list arrives as a real array, with UTF-8 output.
  It adds `-WindowsSecurityConfirmed` when you confirmed by hand the switches Atlas couldn't read, and `-ChooseAgain` when the install chooses again.
  The front door then accepts those unreadable switches, but still blocks any switch that reads on.
- The child process logs to `...\App\Logs`, and `...\App\session.json` records the process and its log.
- Launching holds a cross-process lock.
  The app writes the record before the child starts, and the child runs the front door only after a go-ahead, so no installer runs unrecorded and two windows can't start overlapping installs (`src/services/installer/`, `src/services/session.rs`).
  Closing the window during the final checks starts nothing.
- While the install runs, the package, options and settings are locked, and closing the window needs confirmation.
  The install continues in the background, and reopening the app picks the session up and shows its result.

[The front door](../../docs/front-door.md) covers its parameters, exit codes and requirement checks.

### Results

- During and after a successful install, one view shows the phase, progress and start time, with the log and diagnostic export behind **Show details**.
- A failed install returns to the Install step with **Try again**.
  One bar says what happened, quoting the installer's last error line, with the next action beside it and diagnostics under it.
  The next action is **Relaunch as administrator** when Atlas lacks permission, and the log is behind **Show details**.
- A retry that stops on the same error as the attempt before it says another try is unlikely to help, and points to **Send a report**.
  It names the apps when Windows still wouldn't remove them.
- Once Defender is gone, the bar doesn't tell you to turn protection back on.

## Restart and completion

- **Restart my PC automatically after installation**, in Settings and the Install summary, is on by default.
  It asks Windows to restart when the countdown after a successful install ends, and the installing view says so while the install runs.
- The countdown lasts 10 seconds, or 60 seconds when it starts with the window in the background, whose taskbar button then flashes until you return.
- **Restart later** has keyboard focus during the countdown.
  It stops the countdown in every window following that install, and the view then offers **Restart now**.
- Closing the window during the countdown asks first, offering **Keep open**, **Restart now** or **Close without restarting**.
  The countdown is held while the dialog is open, and starts again on **Keep open**.
- Until Windows restarts after a successful install, Home shows a restart bar with **Restart now** in place of **Reinstall Atlas** or **Update to Atlas** *version*.
  The bar needs no state of its own: `launcher.json` was written for that install, the recorded install is newer, and Windows hasn't restarted since.

### The completion window

- When the install starts, the app writes `launcher.json` and the HKCU Run entry `AtlasInstallCompletion`, which opens a staged copy of the app with `--after-install-restart` (`src/services/session.rs`).
  Before-desktop setup skips the entry, because its supervisor shows the page.
- The entry survives sign-ins within the same boot.
  The first launch after a restart shows **Atlas is installed** if the recorded install is newer than `launcher.json`.
- That launch removes the entry about 20 seconds after sign-in, once Windows has started the Run key's other programs.
  A failed install removes the entry too.
- Atlas's first sign-in setup opens `--just-installed` only for accounts set up later, and shows a notification if it can't find the app.
- The completion window names each choice the install tried to apply that the PC doesn't have as asked, with **Open log file**.
  It reads them from the `notApplied` list that the install's completion wrote to its history entry in `state.json` ([what Atlas records](../../docs/install-state.md#what-atlas-records)).

## Preparation and restart recovery

- Before preparation or an install, the app copies itself to the immutable, hash-named `%ProgramFiles%\Atlas Setup Recovery\<SHA-256>\AtlasManager.exe`.
  Restart registrations use this copy, so deleting the download or unplugging its drive doesn't break recovery.
  Before-desktop ISO setup already runs from the protected `%windir%\AtlasISO`, and skips the copy.
- Jobs live in `Atlas Setup Recovery\Preparation`, scoped to the app's settings path, and in `Atlas Setup Recovery\Media` for ISO and USB jobs (`src/services/recovery_app.rs`, `resources/prepare/Stage-App.ps1`).
  Only administrators and SYSTEM can write their workers, driver policies and journals.
  A cancellation file created in advance lets the installing user ask for a stop, without being able to replace executables or completion records.
- The worker and the staging helper load PowerShell modules only from the inbox module root.
- An elevated start removes finished jobs beyond the newest five, never one whose worker may still be running.
- Reopening the app reattaches to the worker by process ID and creation time, and reads its journal.
  If Windows can't tell whether the worker is running, Atlas assumes it is, and a process that reused the ID doesn't count.
- If Windows can't confirm that a running job's folder is the protected one staging created, Atlas only waits for that job's worker.
  Such a job can't prove success or take a cancellation, and once its worker exits, you retry through the protected path.
- Diagnostics also collect preparation jobs in the user-writable `%LOCALAPPDATA%\AtlasOS\App\Preparation` folder, which Atlas doesn't follow.
- The app never starts a second servicing worker while one it can follow is running, and a machine-wide lock stops any worker running beside another.
- Cancelling never stops an active Windows Update operation; preparation keeps its worker until Windows Update or the Store returns.

### Windows Update settings and moving Windows

Two kinds of job go through the same worker and its functions-only `WindowsTransition.ps1`, staged beside it:

- moving Windows to another release;
- turning Windows Update back on where an earlier Atlas, the user or a tool turned it off, paused or delayed it.

The job's record in `HKLM\SOFTWARE\AtlasOS\WindowsTransition` survives a lost draft.

- While a record is open, Home offers to continue or to put the settings back.
- Closing the window before Windows has moved puts the settings back first.
- **Restart and continue** runs the worker's one-shot commit after recovery is registered and before the restart.
- Each move appends what it read, changed, searched for, found and installed to `windows-transition.log` in the protected preparation folder.
  Diagnostics include that log with the record, Windows Update history and the servicing logs.

[Preparation](../../docs/preparation.md) covers the package side of preparation, and [Windows release eligibility](../../docs/windows-release-policy.md) covers which Windows installations and ISOs qualify.

## Settings

**Settings** lists one card per setting, as Windows Settings does.

- **App theme** and **Language** are combo boxes, and a choice applies only when you commit it.
- **Restart my PC automatically after installation** is a toggle switch, locked while updates, an install or a media job runs.
- **Help and feedback** holds **Send a report** and **Export diagnostics**.
- **About** shows the version, licence and links.
- The note about the translucent background shows only while the background is opaque and no contrast theme is on.

### Help and feedback

- **Export diagnostics** creates a ZIP of app and Atlas installation evidence for a bug report.
  It removes the user name, PC name, email addresses and known passwords or keys.
  `AtlasManager.exe --export-diagnostics` does the same if the window can't open.
- **Send a report** sends a message privately to the Atlas team ([Atlas reports](../../services/reports/README.md)).
  It collects diagnostics as the page opens, unless you turn **Include diagnostics** off.
- Both are in **Settings** > **Help and feedback**, and **Report a problem** on Home opens **Send a report**.
  Elsewhere they appear only under a problem, such as a failed check, install or ISO build, and beside the log of a running install.

[Diagnostics](../../docs/diagnostics.md) covers log locations, collection limits and the reporting process.
