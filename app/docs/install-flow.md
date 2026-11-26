# The install flow

This page describes how Atlas Manager installs and updates Atlas, from Home through the four steps to the restart, and how it recovers when something interrupts it.
It's for contributors who change the flow and reviewers who check its behaviour.

## Steps

| Step | What happens |
| --- | --- |
| **Get ready** | The app elevates once, runs the system checks, fetches the Atlas package, and updates Windows and Microsoft Store apps by itself. |
| **Your choices** | You choose the Atlas options. |
| **Windows Security** | The app opens Windows Security, you turn off the protection switches while it watches them live, and it moves on once they're off. |
| **Install** | The app runs the front door, `Entry\Install-Atlas.ps1`, the script in the Atlas package that installs Atlas. |

Checks and updates come first, so problems are fixed before protection goes off.
Windows Security comes last, so protection is off for as short a time as possible.
`src/flow.rs` enforces the order: the flow moves forward one step at a time, and nothing moves while an install runs ([architecture](architecture.md#the-model-and-background-tasks)).

## Starting the flow

- On a PC without Atlas, Home's one button is **Install Atlas**, beside this PC's Windows, the latest Atlas version and one sentence on what Atlas does.
- Under it, the **What happens** card lists the four steps by the stepper's names, each with one sentence, then reminds you to save your work.
  Get ready's sentence names the Windows version it moves to when the package needs a newer one, and Install's gives the package's usual time and whether the PC then restarts by itself.
- Under that, a card offers to [reinstall Windows with Atlas](iso-creation.md).
- Where Windows shows signs of earlier use (`AppModel::windows_looks_used`), that card comes first, recommended, with the accent, and **What happens** follows it.
  **Install Atlas** then asks first, naming what can break and that Atlas removes OneDrive; **Install anyway** starts the flow with the risk accepted (`AppModel::begin_install_on_used_windows`).
- **Install Atlas** first relaunches the app elevated through User Account Control (UAC).
- A draft in `settings.json` holds the step, the options and the unpacked package, so the elevated copy can resume.
  The app writes it atomically, a failed save stops the relaunch, and success or cancelling clears it.
- While a setup is unfinished, Home offers **Continue setup** and **Start over**.
  The same card, titled **Setting up Atlas**, marks each step as the stepper does: done, current, needing attention again, or still to come.

### Home

- The hero names what's installed and whether something newer is, with one button for the next step: install, continue, update, **Continue update** for an update under way, **Download Atlas Manager** when the package needs a newer one, or reinstall.
  It's the page's one accent, except where reinstalling Windows is the way on and where a bar carries the way on, such as **Restart now** while a restart is owed.
  **Reinstall Atlas** on an Atlas that's up to date isn't the accent, as nothing calls for it, and while the installation record can't be read, the status shows no "Up to date".
- On a PC without Atlas, the latest version joins the Windows line once the release check finds it.
  While the check runs, or after it fails, the status says so instead, with **Try again** after a failure.
- At most one bar shows under it, the most urgent that applies: a restart owed, then Windows Security protection or a missing Microsoft Defender, then Windows Update settings Atlas changed, then the end of security updates for this Windows, then the rest.
  A bar's raw error is behind **Show details**, and the help row shows only under an unexpected failure.
  Windows that no update path reaches gets a warning, and the ISO card first; a record Atlas can't read gets **Try again** as the accent.
  An installed Atlas that no package updates, and Atlas's files without a record of a finished install, also put the ISO card first, and Get ready's bar offers **Create an Atlas ISO** for them.
- **Your Atlas setup** lists each choice under its question, as the Install step's summary does, with Windows and the installation history.
  It records what was chosen, so it shows none of the cautions that go with a choice where it's made.

## Get ready

Get ready is one checklist with three rows: **Check your PC**, the Atlas package (**Atlas** *version*), and **Windows and Microsoft Store updates**, with the driver choice under it.
Each row has a status mark, a title and one status line, and an action only when there's something to do.
What needs attention unfolds under its row.

- While the checks run, their row says so.
  Then the ones that need attention unfold under it, most urgent first, and the rest fold behind **Show details**.
  The status line counts them one way: "9 checks passed", "5 of 9 checks passed", or "7 of 9 checks passed · 2 handled by updating".
  Updates waiting and a pending restart are folded too, as updating's own.
- A failed check says what it found and what to do under its title, as text that Narrator reads with the check, and offers the Windows Settings page that fixes it, such as **Open installed apps** for other antivirus software.
  Where one check alone stands in the way, its fix is the page's accent; where reinstalling Windows is the only way on, **Create an Atlas ISO** is.
- The package row downloads the latest release by itself.
  It offers **Open package file** as a link, and **Download again** only after a failure.
- Atlas Manager refuses a package that needs a newer Atlas Manager before unpacking anything.
  Such a package names a later `minimumManagerVersion` than this app, or uses a newer manifest format.
  The package row names the version it needs, when the package gives one, and offers **Download Atlas Manager**, which opens the latest release.
  No help row shows, because the remedy is known ([Atlas Manager's own version](architecture.md#atlas-managers-own-version)).
- At most one bar shows above the checklist, the first that applies: why no installation can start here, or a relaunch as administrator that didn't happen.
  A row's own state never gets a bar as well.
- Every line a row shows by default is Body text; only raw details behind **Show details**, such as an error as Windows wrote it, are captions.
- Under an unexpected failure, a row of links offers **Send a report**, **Export diagnostics** and, where a log exists, **Open log folder**.
  A problem the row says how to fix, such as a battery, a connection, an app left open or a check with its Settings page, gets none.
- While Continue waits, it reads why as its description.
  The footer shows that in a few words only when the checklist doesn't already say it: fixing what the checks found, getting the Atlas package, or finishing updates that stopped or failed.
  While Atlas checks, downloads or updates, or a row's caption or the bar says what's next, the footer stays quiet; so does it on **Windows Security**, where the bar and the list say what's left.

### What Get ready does by itself

Get ready asks nothing it can find out, and does the known next step itself (`AppModel::advance_ready`).

- **It starts updating** once the app is elevated, every check has reported, nothing stands in the way except what updating itself resolves (updates waiting and a pending restart), there's no install block, the package is ready and the driver choice is known.
  A move to a newer Windows release also waits for the user's choice and Microsoft's licence terms, and **Accept and update** starts it at once.
  While a check stands in the way, which would keep the move from starting, the card doesn't offer **Accept and update**: the check's fix comes first.
- A move short of free space reads it again every 30 seconds; once there's enough, a move already accepted carries on by itself.
- It starts from a preparation not yet run, or the one Atlas's own restart left to continue.
  A run that fails offers **Try again** rather than trying again by itself.
  After **Stop updating**, nothing starts again until the user chooses **Resume updates**.
  A choice that starts updating over, such as the driver choice, starts it again.
- **It moves on to Your choices** once everything has passed with nothing to read, the package is ready and Windows is up to date.
  It does so once per visit, and not when the user came back to Get ready on purpose.
  A check that passed with a note, or that waits for the user's confirmation, keeps the page.
- Starting moves no focus.
  Moving on announces the new step, as **Continue** does.

Atlas also reads at startup whether Windows shows signs of earlier use: installed a week or more ago, or with several apps (`AppModel::windows_looks_used`).
It doesn't count for a PC with Atlas, or for the Windows that an Atlas ISO has just installed.
The draft keeps whether the user accepted the risk for the flow (`used_windows_accepted`).

### Moving Windows to a newer release

Where the package needs a newer Windows release, or recommends one, a card of its own comes first, above the checklist ([On the Get ready page](../../docs/windows-transition.md#on-the-get-ready-page)).
It names the release, says what the move keeps and how long it usually takes, and offers **Accept and update**, the go-ahead under Microsoft's licence terms, which starts updating and moves Windows before anything else.
Where moving is optional, it asks which release to use, and keeping this one starts updating without the move.

- From the go-ahead to its outcome, the card shows how updating stands: the run, the wait for Windows Update's offer, the restart that finishes the move and how it ended, each with its buttons (`AppModel::move_shows_preparation`).
  Its progress bar or outcome comes straight under the status line, then the choice where moving is optional, and **Stop updating** sits at the card's trailing edge, also while Atlas waits for the offer.
  The update row waits for the move meanwhile, and carries on after it.
- Keeping this version stays a choice while Atlas waits for the offer; it asks first, as stopping the move puts back the Windows Update settings Atlas turned on.
  While an Atlas install is unfinished, its own last step puts them back, so keeping this version waits for it, and a line under the choice says so (`AppModel::keep_waits_for_install`).
  Should that become true while a run stops for the keep, the move stays and updating carries on.
- A move this PC can't make, because of its hardware or an organisation's update server, shows as a PC check with **Create an Atlas ISO**, before anything starts.
  Where moving is optional, Atlas keeps this version without asking, and the card doesn't show (`AppModel::move_ruled_out`).
- A move that stopped for what a check then finds too (hardware, an update server or free space) is said once, by the check with its fix; the card only says the move starts once the checks pass (`AppModel::move_outcome_held_by_check`).

- Home shows the two parts of such an update, warns when the installed Windows version stops getting security updates, and says when an edition or version can't take the package at all.
- If Windows reinstalls itself instead of switching the new version on, the move's card says so.
  Atlas then puts itself back on the rebuilt Windows, an install mode called [Rebase](../../docs/windows-transition.md#rebase).
- A Rebase uses the choices recorded before the move, and **Your choices** asks only for a choice that nothing recorded.
  It always keeps those choices; to change them afterwards, choose **Reinstall Atlas**, then **Choose again**.

### System checks

The checks cover the requirements the package's manifest, `atlas.json`, lists and the front door's own (`src/services/requirements/`).

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

Where Get ready moves Windows to a newer release, three more checks say what the move needs, by the preparation worker's rules ([Preflight checks](../../docs/windows-transition.md#preflight-checks)).
They count only while the move is chosen, and the install never runs them.

| Check | Detail |
| --- | --- |
| Windows 11 hardware | A TPM 2.0 and UEFI firmware, where Windows lets Atlas read them; otherwise **Create an Atlas ISO**. |
| Free space | 6 GiB free on the system drive; otherwise **Open Storage settings**. |
| Where updates come from | Not an organisation's update server (`AU\UseWUServer`); otherwise **Create an Atlas ISO**. |

- A blocking check that fails or can't run disables **Continue**.
  Only an update scan that couldn't run can be confirmed by hand.
- Until updating has run, pending updates and a pending restart are notes for it to handle, not blockers.
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
  Once reconnected, **Try again** runs again with nothing to reload.
  Atlas doesn't retry by itself: Windows' connection check and the worker's can disagree on a metered or roaming connection, and a retry that loops would be worse than one click.
- **Scope.** Optional previews and feature updates are left out, because a feature update can leave the supported builds.
  The pending-update check uses the same rules.
- **Providers.** Windows Update Agent runs search, download, install and rescan passes.
  AppInstallManager's `SearchForAllUpdatesAsync` installs Store app updates automatically and restarts the apps, and the update row warns that they'll close before updating starts.
  The progress bar sweeps, as most stages report progress one update or package at a time, which would make it start over; Store apps report one share for all the apps a search found, so their bar fills as the package download's does.
  The stage names what's happening, and **Show details** gives the figures.
- **Microsoft Store.** Updating, reinstalling or repairing Microsoft Store on the way changes nothing the user does, so only the log keeps it.
  Where Microsoft Store is turned off, the row says Windows is up to date, and under it that Store apps weren't updated.
  Microsoft Store's verification API can queue paused updates, but doesn't install them.
- **Completion.** Each provider must report completion.
  Partial or unknown results never continue, and an empty first scan alone proves nothing.
  Errors, missing Store registration, paused work, timeouts and reappearing updates fail with diagnostics and a suggested action.
- **Restarts.** As soon as preparation needs a restart, the app saves the install draft and arms a per-user Run entry, `AtlasWindowsPreparation`, that waits for a new boot.
  Restarting from Windows therefore resumes Atlas too, and signing out first doesn't use the entry up.
  The entry removes itself after the restart, or at its next launch once the draft is abandoned.
  Before-desktop setup relaunches through its own shell.
- **The countdown.** Once the draft and the Run entry are in place, Get ready says "Your PC restarts in 60 seconds." and "Save your work first.", with **Restart now** as the accent and **Restart later** holding focus, then restarts; the taskbar button flashes if the window is behind others.
  The countdown follows **Restart automatically after installing and updating**: with it off, Get ready offers **Restart now** and nothing counts down.
  While someone else is signed in nothing counts down either, and **Restart now** asks first; someone who signs in during the countdown makes it ask at the end.
  **Restart later** and **Cancel** stop the countdown and leave **Restart now**, and so does leaving Get ready for another page.
  Atlas doesn't restart for updating while an ISO or USB job runs.
  Closing the window during the countdown asks **Restart to finish updating?**, holding the countdown meanwhile: **Restart later**, the default that Enter and Escape choose, closes Atlas; the Run entry still resumes Atlas after a restart from Windows.
- **Resuming.** After Atlas's own restart, updating carries on by itself.
  A restart Windows asks for again straight after, with no update work in between, isn't made again: the row says restarting again probably won't help, with **Try again** and **Open Windows Update**, and what Windows still reports a restart for is behind **Show details**.
  An earlier scan never counts as lasting permission to install.
- **Stopping.** **Stop updating** and **Cancel** stop after the current operation; closing the window offers to, and keeps the window open.
  The worker never stops a Windows servicing provider by force.
  Get ready then waits for **Resume updates**.

### Driver updates

A line under the updates says how Windows gets drivers, such as "Drivers: Through Windows Update", and **Change** unfolds the two answers.
The default keeps an existing Atlas policy that blocks driver updates; otherwise the app recommends Windows Update, whose answer says "(recommended)" where the choice is made.
Changing the answer once updating has run starts updating again under it, which a line under the answers says.
An ISO that left the choice until after sign-in asks it unfolded, and updating waits for the answer.

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

- **Your choices** asks every question on one screen (Defender, processor protections, updates and the keyboard), a card each with the question as its title (`src/model/options.rs`).
  The package's default answers stay chosen; only the other answers say, in one line, what they cost.
- While the screen asks about Defender, processor protections or updates, one line at the top says the Atlas folder can change them later.
- The optional extras go at the bottom, folded into one card that says how many are ticked, with **Show** to unfold them.
  A page that depends on an option comes after the page that offers it, so the browser picker comes after the apps.
- Atlas answers the keyboard question itself when Windows has one keyboard layout (`src/services/keyboard_layouts.rs`), with **No, I use one keyboard layout**, and doesn't ask it.
  It reads the layouts again as Your choices opens, and asks when Windows can't list them, before the desktop exists, and in Windows that an Atlas ISO has just installed, whose choices were made with the ISO.
  An update that keeps the choices keeps a recorded answer, and takes Atlas's only where nothing recorded or shows one.
- Where the choices showing can't change, one bar above them says why: an unfinished install holds them, or Atlas puts back the ones it recorded before Windows rebuilt itself.
  Where only a choice the PC can't show is asked, with **Keep my choices** or after a rebuild, a plain line says the rest stay instead.
  **Choose again** has neither, as each answer says what it changes.

### Ready to install

The Install step's card lists the choices, with a caution under risky ones and **Change** beside each that Your choices asks.
**Change** opens Your choices with focus on that question's answer, or on the folded extras, unfolded; Continue then leads straight back.
Under the choices, one line says how long installing usually takes and whether the PC then restarts, beside the **Restart automatically when installation finishes** box.
The box starts from **Restart automatically after installing and updating** in Settings and changes this install only (`AppModel::install_restarts`): Settings keeps the default for every install and for the restarts updating needs.
The box is kept for the flow it was set in, and a relaunch starts it from Settings again.
The Atlas package, Windows, activation, what Atlas turns off whichever Defender answer is chosen (Smart App Control, Enhanced Phishing Protection and Find my device) and the installation command, with **Copy**, are behind **Show details**.
The card is **Ready to install** while the footer offers the install, and **Your Atlas setup** while the bar's fix comes first.

At most one bar sits above the card, the first that applies: how the last attempt ended, a refusal of the final checks, missing administrator permission, a package that isn't ready, Get ready no longer passing, or a protection switch back on.
Its button is the fix, such as **Go to Get ready** or **Go to Your choices** at the question left unanswered, and is then the step's accent button instead of **Install Atlas**.
Raw errors are behind its **Show details**, and the footer says only "Save your work and close your apps first", while the PC restarts after installing.

### Updating or reinstalling

When you update or reinstall the installed Atlas, **Your choices** first asks **Keep my choices** or **Choose again**.
It lists the choices this PC has now, and what the PC shows wins over Atlas's record (`src/model/rebase.rs`, `src/services/legacy_choices.rs`).

- **Keep my choices** locks every choice, and asks only for a required one the PC can't show.
- **Choose again** asks every question from what the PC has, marks the answer it has now, and says under each answer what it changes.
  It also fixes what an update can't undo: Edge already removed, and a Toolbox or browser that Atlas installed.
- The summary's first row, **How Atlas updates**, gives the answer.
- An unfinished install skips that first screen and continues as it began.
  The Windows Security bar follows its recorded mode and update path.
- If an unfinished update began with **Keep my choices** and its plan hasn't started, its choices stay held to what the PC shows.

[Keep my choices or Choose again](../../docs/upgrading.md#keep-my-choices-or-choose-again) covers what each answer does.

## Windows Security

Atlas reads the four Windows Security protection switches once a second: Tamper Protection, Real-time protection, Cloud-delivered protection and Automatic sample submission.
It reads the registry values behind Windows Security's **Virus & threat protection settings** page, by the same rules as the front door's check (`src/services/security.rs`).

- At most one message bar says what's left to do, with **Open Windows Security** as the accent until the step passes.
  While the first reading is on its way, the switches' own marks are the only status, and once every switch reads off there's no bar.
- A switch Atlas can't read shows as unreadable, never on or off.
  An elevated user can confirm it by hand with the bar's check box, after checking Windows Security; the bar and the box name only the switches Atlas couldn't read.
- Without Microsoft Defender there's nothing to turn off, and the bar says what happens to Defender.
  It stays removed, this install brings it back, or it's missing and Atlas can't bring it back.
  A missing Defender is a warning that doesn't stop the install.

### What Windows Security does by itself

Atlas never changes a protection switch: they're always the user's to turn off.
The step does the rest itself (`AppModel::advance_security`).

- **It opens Windows Security** at **Virus & threat protection settings** when a switch reads on or can't be read, once per visit to the step, with the same call as **Open Windows Security**, which stays for opening it again.
  It doesn't without administrator rights, when the bar offers the relaunch instead.
- **It moves on to Install** once every switch reads off: the window comes back to the front, or its taskbar button flashes where Windows won't allow that, shows the switches off for about 1.5 seconds, then goes on.
  A switch turned back on meanwhile keeps the step.
- **It's passed over** when its first reading already passes, with every switch off or Microsoft Defender gone, and the stepper marks it done.
  Continue on Your choices goes straight to Install: arriving, the step takes that first reading at once, so it doesn't show before Atlas knows there's nothing to do.
  A Defender the user chose to keep that's missing keeps the step, as its warning is for reading.
- None of this happens when the user comes back to Windows Security on purpose, from the stepper or with **Back**, except opening Windows Security for a switch that's on.

### Protection reminders

Protection is never left off silently.

- Closing the window during a setup while a switch reads off asks first, and offers Windows Security.
- Cancelling the setup leaves a reminder on Home that names the switches still off.
  It survives a relaunch until a reading shows them back on.
- After an install that kept Defender, once its restart is done, Home and the completion window read the switches when they open and whenever the window is activated again.
  They show a dismissible reminder while any switch is off, or a warning if Defender is missing.
  "You're all set" appears only when every switch reads on.
- After an install that removed Defender, the completion window says the PC has no antivirus until another is installed.
- When Atlas's record kept Defender but Atlas's package still removes it, Home and the completion window say it's still removed and how to bring it back, with **Reinstall Atlas**, whose first screen offers **Choose again**.
  On Home it's the accent and takes the hero's **Reinstall Atlas**; where the hero offers an update instead, the update is the way back.

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

- From the final checks until the restart after a successful install, one view shows what Atlas is doing, such as "Setting up Windows…", over a progress bar that never goes backwards, with the log behind **Show details**.
  The final checks and the installer's own first checks both read "Checking your PC…", as one step.
  One line under the bar says to keep the PC on and plugged in, and whether it restarts by itself when installation finishes.
- When Atlas can't follow the installer's log, a bar says so, with **Open log folder** and the error behind **Show details**; the install carries on.
- A failed install returns to the Install step, where one bar says what happened and what to do, in two sentences at most, with the one button that matches the cause:
  **Relaunch as administrator** without permission, **Go to Get ready** for requirements the PC didn't meet or updates that weren't finished, and otherwise the footer's **Try again**.
  Where the bar's button is the fix, the footer leaves **Try again** out, and where the attempt stopped before changing anything, the bar's title is "Installation hasn't started".
  The installer's last error line and the log are behind the bar's **Show details**.
- **Open Windows Security** sits beside a failure that may have changed things while Defender is still there, for turning the protection switches back on.
- The row of help links goes inside the bar, under its **Show details**, only when the cause is unexpected, not under one the bar's button fixes.
- A retry that stops on the same error as the attempt before it says another try is unlikely to help, and points to **Send a report**.
  It names the apps when Windows still wouldn't remove them.
- Once Defender is gone, the bar doesn't tell you to turn protection back on.

## Restart and completion

- After the install plan exits successfully, Atlas waits up to two minutes for its installer process tree. It then closes leftover processes in that tree and confirms it has emptied before continuing.
- **Restart automatically after installing and updating** in Settings is on by default.
  Each install starts from it, and the Install step's **Restart automatically when installation finishes** box changes that install alone ([Ready to install](#ready-to-install)).
  An install that restarts asks Windows to when the countdown after its success ends, and the installing view says so while the install runs.
- The countdown lasts 10 seconds, or 60 seconds when it starts with the window in the background, whose taskbar button then flashes until you return.
  It's a sentence, "Your PC restarts in 8 seconds.", with "Save your work first." under it, then **Restart now** and **Restart later**.
- **Restart later** has keyboard focus during the countdown.
  It stops the countdown in every window following that install, and the view then offers **Restart now**.
- When Windows refuses the restart, a bar says to restart from the Start menu, with **Try again** and Windows' error behind **Show details**.
- Closing the window during the countdown asks **Restart to finish setting up Atlas?**, with **Restart now**, and **Restart later**, the default that Enter and Escape choose, which closes Atlas without restarting, so a key pressed after **Close** never loses unsaved work in other apps.
  The countdown is held while the dialog is open.
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
- At most one bar shows under the completion window's heading, the most urgent that applies: Windows Security protection or Microsoft Defender, then choices that didn't apply, then Windows Update turned off or paused again as the user chose.
- The choices bar names each choice the install tried to apply that the PC doesn't have as asked, with the row of help links, **Open log folder** among them.
  It reads them from the `notApplied` list that the install's completion wrote to its history entry in `state.json` ([what Atlas records](../../docs/install-state.md#what-atlas-records)).
- It lists the choices this PC has in the order Your choices asks them.
  Where the user installs drivers themselves, a line under that list says where to get them, with **Open the drivers guide**.
- Its one accent button is the bar's own where it leads back to protection: **Reinstall Atlas** while Atlas's package still removes a Defender the record kept, and **Open Windows Security** while a reminder says switches are off.
  Otherwise it's **Done**.

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
- The restart that finishes a move runs the worker's one-shot commit after recovery is registered and before Windows restarts.
- Each move appends what it read, changed, searched for, found and installed to `windows-transition.log` in the protected preparation folder.
  Diagnostics include that log with the record, Windows Update history and the servicing logs.

[Preparation](../../docs/preparation.md) covers the package side of preparation, and [Windows release eligibility](../../docs/windows-release-policy.md) covers which Windows installations and ISOs qualify.

## Settings

**Settings** has sections as Windows Settings does, each a heading over one card per setting: **Appearance**, **Language**, **Installation**, **Privacy**, **Help** and **About**.

- **App theme** and **App language** are combo boxes of the same width, and a choice applies only when you commit it.
  A note goes under the row, never beside the header, only when it changes something.
  Under the theme box, it says a Windows contrast theme sets the colours.
  The language box always shows the language in use, and its one note says why it shows English, that the language is a preview translation once its notice is dismissed, or that dates and numbers follow another region.
- **Restart automatically after installing and updating** is a toggle switch, locked while updates, an install or a media job runs.
  It's the only place that sets this default: the Install step's box changes one install, not the setting.
  It governs the restart after installing and the one Windows and Store updates need on Get ready.
- **Share usage data with Atlas** says what it shares and links to the privacy policy.
- **Help** holds **Send a report**, **Export diagnostics** and **Open app folder**.
- **About** shows the version, licence and links.
  When the release check finds a newer Atlas Manager, it also shows a note with **Download Atlas Manager**, as Home does.

### Help

- **Export diagnostics** creates a ZIP of app and Atlas installation evidence for a bug report.
  It removes the user name, PC name, email addresses and known passwords or keys.
  Its label stays while it runs, with a spinner where the result goes.
  The ZIP is named by when it was saved, such as `Atlas-diagnostics-2026-11-24-0612.zip`, and the result names it and its folder, or offers **Try again** with the error behind **Show details**.
  `AtlasManager.exe --export-diagnostics` does the same if the window can't open.
- **Send a report** sends a message privately to the Atlas team ([Atlas reports](../../services/reports/README.md)).
  It collects diagnostics as the page opens, unless you turn **Include diagnostics** off.
  Its footer holds one status line, and after a failure its button becomes **Try again**, or **Open the report website** where this version can't send.
- Both are in **Settings** > **Help**, and **Report a problem** on Home opens **Send a report**.
  Elsewhere they appear as one row of links under an unexpected failure, such as a check that couldn't run or a failed install or ISO build, with **Open log folder** where a log exists.
  The row carries no privacy text: **Send a report** says what it sends, and the export's result says what the ZIP leaves out.

[Diagnostics](../../docs/diagnostics.md) covers log locations, collection limits and the reporting process.
