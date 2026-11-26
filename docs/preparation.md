# Preparing Windows

This page explains what Atlas Manager's **Get ready** page does before it installs Atlas, and how the preparation worker behind it works.
It's for contributors, and for anyone working out why an update or a Microsoft Store repair stopped.

Moving Windows to a newer release also starts on the **Get ready** page, and has its own page: [Moving Windows to a newer release](windows-transition.md).

## What the Get ready page does

Atlas Manager brings Windows and Microsoft Store apps up to date before it installs Atlas, so that servicing doesn't run alongside the install.
The **Get ready** page is a checklist: the PC checks, the Atlas package, and **Windows and Microsoft Store updates**, with the drivers choice under it.

Updating starts by itself once the checks pass and the package is ready, as [the install flow](../app/docs/install-flow.md#what-get-ready-does-by-itself) describes.
Atlas Manager then runs the preparation worker, which:

1. installs the Windows updates Windows Update offers;
2. registers, updates or repairs Microsoft Store for you when it can't update apps;
3. updates your Microsoft Store apps;
4. repairs Windows's component store when updates fail on it;
5. asks for a restart whenever Windows needs one, then carries on after it.

The install itself starts only when a fresh check confirms that nothing is left (see [The check before the install](#the-check-before-the-install)).

## The preparation worker

The worker is `Preparation/Update-Windows.ps1`, a Windows PowerShell 5.1 script that Atlas Manager embeds and runs elevated.
Its process loads PowerShell modules only from the inbox module root, so a module on a user path can't replace one it uses.

- It runs as the signed-in owner of the Windows session, because Microsoft Store state belongs to that user.
  It refuses SYSTEM, session 0 and elevation as another account with the reason `session-owner`.
- One run holds the mutex `Global\AtlasOS.WindowsPreparation` at a time.
  A check before an install waits up to two minutes for another run to finish, and any other run stops at once.
- Each run has a job folder under `%ProgramFiles%\Atlas Setup Recovery\Preparation`, which only administrators and SYSTEM can change.
  It holds the worker's `state.json`, its `updates.log` and `worker.log`.
- The worker replaces `state.json` whole with each report, and tries again while something such as a scanner holds it.
  A progress report that still can't go in waits for the next one.
  The report of how the run ended is tried for up to a minute, then written over the held file in place, because Atlas Manager reads only `state.json`.
  The run fails only when that doesn't work either.
- **Stop updating** asks the worker to stop after the current step.
  Windows Update's and Microsoft Store's own work isn't interrupted, so a stop waits for it.

Atlas Manager's side of the job, including recovery after a restart, is in [Atlas Manager's install flow](../app/docs/install-flow.md#preparation-and-restart-recovery).

## Windows updates

The worker searches Windows Update online, downloads and installs what it finds, and searches again until nothing is left.

- Each search asks the Windows Update service itself (`ServerSelection` set to `ssWindowsUpdate`).
  The default service can be another catalogue on some PCs, and that catalogue may not offer the update Atlas needs.
- A PC that gets updates from its organisation's server (`AU\UseWUServer` set to 1) keeps that server.
  A redirect to a server that can't be one, on a PC no organisation manages, is lifted for the run instead (see [Turning Windows Update on](windows-transition.md#turning-windows-update-on)).
- A search that fails or ends with errors runs up to three times, after 30 seconds and then 60.
  When Windows Update still can't be reached, or keeps stopping, the run stops with `windows-update-unreachable`.
  The errors that count are `0x8024001E`, `0x80240069`, `0x80240438` and `0x80244010` to `0x8024401F`; any other error stops the run at once.
- Before a failed search runs again, the worker waits up to two minutes for the Windows Update service to report that it's running, and starts it once if it stopped.
  Windows Update can drop a search while it restarts, as it can straight after a component store repair.
- The worker leaves out optional previews (browse-only updates) and feature updates.
  It also leaves out drivers when you chose **Install drivers myself**.
- When one pass offers several cumulative updates for the installed build, it installs only the newest.
  Installing an older one first can leave the newer one to install again after a restart.
- Updates that can ask for input are installed last, silently.
  An update that requires your input stops the run with `manual-updates`, naming the updates to finish in Windows Settings.
- A run gives up with `windows-passes` when Windows still offers updates after eight passes.

A failed update gets one more try after a fresh search.
Some failures are handled first:

- When another installation holds Windows Update (`0x80240016`), the worker waits for it, for at least 30 seconds and at most 10 minutes, then tries again.
  These waits don't use up the update's try, and a run makes up to three of them.
- When an install result gives no code of its own, `updates.log` adds the code Windows Update's history records for that attempt, and the run reports that one.

Before a restart for updates, the worker records the updates it's for under `HKLM\SOFTWARE\AtlasOS\Preparation`.
When one of them fails again after the restart, or asks for yet another restart, the run stops with `manual-updates` instead of restarting again.
A record from more than a day before doesn't count.

The worker stops waiting for three kinds of update:

- An update that installs successfully and is offered again at once, such as the Windows Security platform update.
  The log calls it `reoffered-after-success`.
- A driver that Windows Update fails with `0x80070103`, because the device already has one at least as good.
  The log calls it `driver not needed`.
- Microsoft Defender's own updates (KB2267602 and KB4052623) on a PC Atlas removed Defender from: Atlas's NoDefender package is installed, and the WinDefend service or the Defender engine (`MsMpEng.exe`) is gone.
  Windows Update can keep offering them there, and they fail with `0x80070643`.
  The log calls them `defender update not needed`.
  While Defender could still run, they stay required.

The worker keeps all three under `HKLM\SOFTWARE\AtlasOS\Preparation` for 30 days, up to 100 entries.
The check before the install reads the same record, so it doesn't wait for them either.
Defender's updates are the exception: each new one has a new ID, so the worker and the check decide them from the PC every time, and the record only shows them.

When Windows Update is turned off, paused, set to delay monthly updates or sent to an update server that isn't there, the **Get ready** page turns it on for the run.
It records the original settings first, and the Atlas install puts them back at its end (see [Putting Windows Update settings back](windows-transition.md#putting-windows-update-settings-back)).

## Windows component store

Windows installs updates into its component store (WinSxS).
When the store is damaged, updates fail, often with `0x80073712` (`ERROR_SXS_COMPONENT_STORE_CORRUPT`).
The worker repairs the store at most once per run with `DISM /Online /Cleanup-Image /RestoreHealth`, which takes replacement files from Windows Update.
Microsoft describes the repair in [Repair a Windows image](https://learn.microsoft.com/windows-hardware/manufacture/desktop/repair-a-windows-image).

The repair runs in three cases:

- Before the run's first search, when Windows already records damage (`/CheckHealth` reads `Repairable`).
  PCs with Atlas packages installed are skipped, as the next section explains.
- Before moving Windows to a newer release, when the store reads `Repairable` for a reason other than the Atlas packages (see [Preflight checks](windows-transition.md#preflight-checks)).
- When an update fails with `0x80073712`, or with `0x800F0831` (`CBS_E_STORE_CORRUPTION`), which servicing reports when the store is missing a manifest the update needs.
  The updates that failed then get another try.

While DISM runs, the update row says Windows is being repaired, and under its progress bar that this can take half an hour or more.
DISM reports no progress the worker can read, and like Windows Update's own work it isn't stopped.
If the repair leaves a restart, the **Get ready** page restarts before it searches.

When Windows reads the store as `NonRepairable`, the run stops before any update with `component-store-unrepairable`.
The update row says Windows is too damaged to update, with **Create an Atlas ISO** as its one button, after a backup; trying again can't help.

A repair can also fail on manifests the store has lost, such as those of Features on Demand.
DISM then ends with an error such as `0x800F0915`, the store still reads `Repairable`, and `CBS.log` reports `Store corruption, manifest missing for package` since the repair started.
The Atlas install would fail on such a store with `0x800F0831`, so the run stops with `component-store-unrepairable` there, before any update.

- The worker records the failed repair under `HKLM\SOFTWARE\AtlasOS\Preparation`.
- The next run, such as trying again, repairs once more.
- After a second such failure, runs stop at once without repairing, as each repair can take several minutes.
- A store that reads healthy clears the record, and a record lapses after 30 days.

When an update still fails with `0x80073712` after the repair, the run stops with that error.
A restart can clear what's left, so the row offers **Restart and try again**.
It restarts as any restart updating asks for does, and updating carries on by itself after you sign in.

When an update still fails with `0x800F0831` after its retry and the run's repair, the run stops with `component-store-unrepairable` and that code, and its message names the update.
The repair can report the store healthy while it's still missing what the update needs, so trying again can't help either.

The health Windows reads, the repair's exit code and the health afterwards go to `updates.log`.

### The component store and the Atlas packages

The Atlas CBS packages replace inbox components with a higher version (`38655.38527.65535.65535`).
Once a cumulative update adds a newer version of a replaced component, `DISM /StartComponentCleanup` can't fully rebuild the components the packages replaced.
The next store check then reports the store as repairable.
An online repair doesn't bring such a store back to clean, and an offline repair fails with `0x800F0915`, because the Atlas repair source holds only the Atlas manifests.
So an Atlas PC can read as repairable because of the packages alone.

Atlas handles this in four places:

- The install's Features phase cleans the store only on a fresh install with no Atlas package installed, before the Components phase installs the packages.
  Otherwise it logs why it skipped the cleanup.
- Every install keeps the packages' repair source.
  An update replaces `%windir%\AtlasModules`, so the Features phase recreates `AtlasModules\Packages\WinSxS` while the packages are installed.
  When the `Servicing\LocalSourcePath` policy names that folder and the folder is gone, it removes the policy.
- The **Get ready** page leaves a repairable store alone on a PC with Atlas packages before its first search.
  It still repairs the store when an update fails with `0x80073712`.
- Before moving Windows to a newer release, the worker records the store's health and goes on with a repairable store.
  It repairs the store first only when a store check finds damage other than the packages' own (see [Preflight checks](windows-transition.md#preflight-checks)).

Windows's own scheduled store cleanup can have the same effect on any PC with the packages.

## Microsoft Store

PCs that ran Atlas over Windows installed from older media often have a Microsoft Store too old to update apps.
The worker deals with the Store before the Store apps:

1. A Store that's staged or provisioned on the PC but not registered and working for you is registered for you.
   The worker uses the newest package's manifest under `WindowsApps`, or the package family name.
2. The worker asks the Store to update itself, then App Installer, by package family, through [`AppInstallManager.UpdateAppByPackageFamilyNameAsync`](https://learn.microsoft.com/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.updateappbypackagefamilynameasync).
   The update row says so while it does.

Nothing Atlas 0.5.0 sets by default stops this.
It leaves the Store's services alone, and turning off automatic Store app updates (`AutoDownload` set to 2) doesn't stop an update Atlas asks for.

### Orphaned AppX deployment rows

Before any update work, the worker looks for **orphaned AppX deployment rows** on a PC that shows their symptom, and removes them when it finds some.
`StateRepository-Deployment.srd`, under `%ProgramData%\Microsoft\Windows\AppRepository`, keeps each package's files, manifest and source URIs under the package's id in `StateRepository-Machine.srd`.
Removing packages with AME's `!appx` action, as Atlas 0.4 and 0.5 did, could drop a package from the Machine database and leave those rows behind.
They are the likely cause of `0x80070490` (`0x80073CF9` in the Store) on PCs that ran those versions: Microsoft doesn't document either database, so this is inferred from affected PCs, where installs fail in the deployment's Evaluated state.

The databases can't be changed while StateRepository runs, and on a running desktop it can't be held stopped: the services that depend on it start it again, and several of them, such as Gaming Services and AppXSvc, start on triggers within seconds of being stopped.
So the repair runs at the next startup, and asks for that restart only when there is something to remove.
It comes before the update work so that its restarts never land in the middle of it.

- The symptom is an install that failed in the Evaluated state with `0x80070490` in the last 30 days: event 605 in the `Microsoft-Windows-AppXDeploymentServer/Operational` log, matched by its data, not its localized text. Without one, the worker leaves the databases alone, even when they hold orphaned rows. `0x80073CF9` alone isn't the symptom, since it stands for any failed install, such as one of a paused package. The log keeps only its newest events, so a PC whose failures have aged out of it isn't repaired.
- The worker counts the orphaned rows in a copy of both databases. With none, or when the checks below refuse, it asks for no restart and goes on with the updates.
- When Windows already owes a restart, the worker leaves the rows for a later run instead of adding its own restart to it.
- Only SYSTEM can write the databases, and only TrustedInstaller can change StateRepository's start type. The worker registers three scheduled tasks that run as SYSTEM; started with `RunEx` as `NT SERVICE\TrustedInstaller`, a task also gets the TrustedInstaller group, so no installed Atlas is needed and the repair reaches PCs still on Atlas 0.4 or 0.5. The repair task runs the worker's own protected copy, in the job folder Atlas Manager staged; a worker run from anywhere else leaves the repair out.
- It sets a notice Windows shows before sign-in, saying that Atlas is repairing Windows and restarts once more by itself. Without StateRepository, the lock screen, Start and the taskbar don't open, packaged apps that start at sign-in, such as PowerToys Command Palette, fail with "Class not registered", and signing in can come before the startup task. A notice the PC already shows is kept, and none is added.
- Then it disables StateRepository, which keeps running until the restart, and asks Atlas Manager to restart Windows.
- At startup, StateRepository and every service that depends on it stay stopped. A startup task runs the repair as TrustedInstaller, then always runs the restore, which puts StateRepository's start type back, starts it and the dependents that start automatically, clears the notice and removes all three tasks. The restore needs neither the job folder nor the worker.
- The restore then restarts Windows once, because a session signed in while StateRepository was off keeps a broken shell. If Atlas Manager is already open again, it restarts only the shell processes that started before the restore, so Atlas Manager's run isn't cut short. While the start type is still disabled, the restore keeps the tasks and the notice, so it runs again at the next startup, where the repair keeps its earlier outcome and changes nothing. When a task or the disabled start type is left, it doesn't restart, so a failed restore can't restart Windows at every startup.
- The repair removes nothing unless StateRepository is disabled and stopped, when the Machine database lists no packages, or when more files are orphaned than kept, since then that database doesn't describe the packages the Deployment database belongs to.
- Only once those checks pass, it copies the Deployment database and its write-ahead log beside it, as `StateRepository-Deployment.srd.atlas-backup-<time>`.
- The rows go in one transaction, which is rolled back when StateRepository has started (checked right before the delete and the commit), when `PRAGMA foreign_key_check` finds a new broken reference in a table pointing at the removed rows, such as `ContentGroupFile`, or when `PRAGMA quick_check` fails.
- The outcome goes to `apprepository.json` in that job folder. The next run logs it and doesn't repair again.
- A repair that fails before StateRepository is disabled is logged, and the run goes on with the updates.

### Microsoft Store repair

If the Store still can't update, the worker tries these repairs once per run, in order, and tries the Store again after each one that changed something.
A Store that fails for a moment is tried again first, and one that's slow but still moving gets no repairs (see [Store app updates](#store-app-updates)).

A Store that didn't answer in any of its tries first has its install service restarted, and is tried again.
The Microsoft Store Install Service (`InstallService`) carries out the Store's downloads and installs, and a stuck one stops the Store answering.
The worker waits at most a minute for it to stop and a minute for it to start, and leaves a service that's turned off alone, as it couldn't start again.

1. **`wsreset.exe -i`**, run in your session.
   The switch isn't documented.
   It runs without a window, registers the Store's frameworks (UI.Xaml, VCLibs) again and updates the Store's purchase app in the background, and the worker follows what it queued.
   It doesn't change the Store's or App Installer's version, or register a Store you hadn't registered.
   Plain `wsreset.exe`, which opens the Store, isn't used.
2. **App Installer, then the Store through winget.**
   When the PC has a newer App Installer staged, or installed for another account, the worker registers that copy for you without a download.
   Otherwise, or when registering it changes nothing, it installs App Installer and its frameworks from the latest stable [winget-cli release](https://github.com/microsoft/winget-cli/releases).
   When your App Installer is already that release or newer, it downloads nothing.
   If Windows refuses that release because a newer App Installer is on the PC, the worker uses the signed winget available to you.
   Then it installs the Store with `winget install --id 9WZDNCRFJBMP --source msstore`.
3. **StoreFixer**, started through Atlas's own **Fix MS Store Issues**, which runs it as TrustedInstaller.
   A PC with an Atlas older than 0.6 has no safe way to start it, so the worker leaves this step out there, and says it skipped it.

App Installer versions are compared by the package's own version.
The release's tag gives that version, and the version your winget reports must also be at least the tag before the worker skips the download.
The list of provisioned packages gives the bundle's version, such as 2026.115.2221.0, which is always above the package's, such as 1.27.459.0, so the worker doesn't use it.
The winget-cli repository is checked by its GitHub IDs, and each file by the SHA-256 that GitHub records and by Microsoft's signature.
A download that the connection cuts short, or that a proxy or GitHub refuses, is logged as a network problem.
GitHub answers HTTP 403 or 429 when one address sends it too many requests, as a shared connection can, and a proxy that wants credentials answers 407.

The first repair after which the Store works ends the repairs, and `updates.log` says what was done.
The update row doesn't, as it changes nothing you do.
If none helps, the run stops with `store-repair-failed`, and its message says how each repair ended.
The update row says Microsoft Store isn't working and that installing Atlas now could break Store apps, with **Try repair again**, which runs the repairs again.
Behind **Show details** are the worker's own message and **Create an Atlas ISO**, for reinstalling Windows after a backup if the repair keeps failing.
The row of help links under it offers **Send a report**, **Export diagnostics** and **Open log folder**.

### Updates Windows can't stage

Windows can fail to stage an app update with `0x80070490` (`ERROR_NOT_FOUND`, element not found), which the Store reports only as `0x80073CF9`.
Updates whose files are already on the PC still install.
The apps that fail are built-in ones, such as Calculator, Photos, App Installer and the Store itself, and the repairs don't change it.

After the repairs, the run stops with `store-appx-staging` instead of `store-repair-failed` when either of these holds:

- Since the run started, the AppX deployment log has event 401 for a Stage or an Add that failed with `0x80070490` for two or more apps, and the Store still fails to deploy an update.
- The bootstrap's own App Installer bundle failed with `0x80070490`.

The worker reads the operation and the error from the event's own values, which don't depend on the language Windows uses.
An item the Store cancels with `0x80004004` (`E_ABORT`) after such a failure counts as that failure (see [Store app updates](#store-app-updates)).

The update row says Windows can't update its built-in apps and names them by their package names, such as ZuneMusic.
It offers **Create an Atlas ISO**, for reinstalling Windows after a backup, and **Try again**.

The worker records each run that ends this way as `StoreStaging` under `HKLM\SOFTWARE\AtlasOS\Preparation`, with the apps.
The repairs run in at most two such runs: the first, and one more after you try again.
After that, a run whose Store fails to stage updates for any of the recorded apps again stops before the repairs.
The Store is still asked to update first, so a Store that works again finishes as usual and clears the record.
A record more than 30 days old counts for nothing.

When a run stops this way, `updates.log` also gets read-only evidence, once a run, on lines that start with `Microsoft Store: staging evidence:`:

- the events of each failing deployment, as `Get-AppPackageLog -ActivityID` gives them, read through a query that each AppX log filters itself;
- the `Microsoft-Windows-AppXDeploymentServer/Operational` log's errors and warnings since the run started that `updates.log` doesn't have already;
- for each app, its packages for every account (by SID only), its provisioned packages, its entries under `Applications`, `InboxApplications` and `Deprovisioned` in `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore`, and whether `%ProgramData%\Microsoft\Windows\AppRepository` holds each installed package's manifest.

See [Log limits](diagnostics.md#log-limits) for how much of it the worker writes.
A part that can't be read is noted, and nothing in it changes how the run ends.

### Store app updates

An app update that ends in `Error` or `Canceled` is cleared from the Store's queue, and the worker searches the Store again.
If the Store offers the app again, the worker waits for it again and stops if it fails again.
If the update disappears from the Store, the app is up to date, because a busy Store can report `Error` for an update it has already installed.
If a newly failed update is for an installed app, the worker gives the queue up to a minute to settle and searches again before it starts repairs. It does this once per run.
The log says which.

Some Store failures pass on their own:

- an update the Store cancels with `0x80004004` (`E_ABORT`);
- a Store that doesn't answer within three minutes;
- a Store that refuses to resume a queued download.

The worker tries the Store again, up to four times in all, 15 seconds apart.
The Store's own update gets the same tries before the repairs, and one try after each repair, which says whether it helped.
When the Store still fails that way, it goes on to the repairs, as a Store that fails every time can be broken.

An item the Store cancels with `0x80004004` in a run whose AppX deployment log already shows Windows unable to stage an update with `0x80070490` counts as that failure instead, as trying again doesn't get past a staging failure.
The run reports `0x80070490` with the apps Windows couldn't stage, and goes on to the repairs at once (see [Updates Windows can't stage](#updates-windows-cant-stage)).

The worker waits for Store apps while their updates move, until 30 minutes after anything last moved, and for 90 minutes at most.
A Store that stops moving for 30 minutes gets the repairs, as a stuck Store can need them.
One still moving after 90 minutes stops the run with `store-timeout`, without the repairs.

An update that fails because its app is open (`0x80073D02`) is tried again too, up to four times in all, 15 seconds apart, as the Store closes an app it updates and the app can be closed meanwhile.
When the app is still open after that, the run stops without the repairs, which can't close it.
The update row names the app: close it, then try again, in Task Manager if it has no window.
The row offers only **Try again**, as Microsoft Store has nothing to add.

A Store you removed on purpose stays removed.
Atlas 0.5.0's **Disable Microsoft Store** and Atlas's Microsoft Store toggle record `HKLM\SOFTWARE\AtlasOS\Services\MicrosoftStore` with `state` set to 0.
With that record and no Store registered for you, the worker skips Store app updates, and the check before the install skips the Store too.
The update row then says Windows is up to date, and under it that Store apps weren't updated because Microsoft Store is turned off.
Atlas 0.5.0's script removed the Store only for the account that ran it, so other accounts may still have it.
The install doesn't need the Store.
NanaZip, for example, falls back to its verified download.

### Microsoft Store apps of other accounts

The worker updates Microsoft Store apps through the Store for the signed-in user only.
A Store app is installed once for the PC and registered for each account that has it, as [how packaged apps are installed](https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-behind-the-scenes) describes.
An app you have too gets its newer version registered for another account when that person next signs in, as [apps after an update](https://learn.microsoft.com/troubleshoot/windows-client/application-management/modern-apps-application-packages-reported-vulnerable) explains.

An app only another account has isn't updated.
Atlas 0.5.0 and Atlas both turn off automatic Store app updates for the whole PC, with the tweak `qol/disable-store-auto-updates` (`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload` set to 2).
Those apps stay at their version until that person updates them in Microsoft Store (**Library** > **Get updates**).
The Atlas install doesn't need them.

## Restarts

A restart Windows needs outranks a partial failure.
The worker checks for one even when an update provider throws, because a failed provider can still have installed updates, and asks for the restart first.
Atlas Manager writes the results of each update and any provider errors to its diagnostic log.
The worker checks the servicing stack's and Windows Update's restart flags, then asks Windows Update itself.
Files waiting to be replaced at the next restart are noted but don't ask for one, because apps such as Xbox Gaming Services queue one at every restart.

Windows can keep the servicing stack's flag (`Component Based Servicing\RebootPending`) over restarts while servicing has nothing pending, and `CBS.log` then says `Nothing is pending` at each shutdown.
So when that flag is the only one left after a restart a run asked for while the flag was there, the worker asks servicing and Windows Update what still waits:

- `%windir%\WinSxS\pending.xml`;
- an exclusive session under `SessionsPending`;
- the `PackagesPending` and `RebootInProgress` markers;
- packages waiting to install or uninstall;
- Windows Update's own need for a restart.

With none of these, the flag holds nothing back: `updates.log` notes a stale restart marker, and the run goes on.
A flag that no restart has met yet still gets its restart.
The worker keeps the restart it last asked for, and the start of Windows in which it found the flag stale, under `HKLM\SOFTWARE\AtlasOS\Preparation`.
For the rest of that start, the **Get ready** restart check and the install's requirement check don't count the flag either, while servicing still has nothing waiting.
If Windows Update then asks for a restart before it installs an update, the run stops with `manual-updates` instead of restarting again.

Before Atlas Manager restarts Windows for preparation:

- It saves the draft with the restart time, copies itself to `%ProgramFiles%\Atlas Setup Recovery` and adds the HKCU Run entry `AtlasWindowsPreparation`, which starts that copy with `--after-preparation-restart`.
- The entry opens Atlas Manager only after a new start of Windows, so sign-ins in the same session leave it in place.
  It's removed after the restart, or silently at its next launch if the draft was abandoned.
- On a PC installed from an Atlas ISO, the before-desktop shell starts Atlas Manager again instead.

Once the draft and the Run entry are in place, Atlas Manager counts down 60 seconds, with **Restart now** and **Restart later**, then restarts.
With **Restart automatically after installing and updating** off in **Settings**, it offers **Restart now** and nothing counts down.

After the restart, Atlas Manager restores the package and your choices and carries on updating by itself, without marking preparation complete.
Failures to save, to register the Run entry and to restart have their own messages.
A failed restart keeps recovery in place for a restart through Windows.
When `shutdown.exe` answers that a shutdown is already in progress or scheduled (errors 1115 and 1190), the restart counts as accepted.

Before any restart Atlas Manager makes, it checks for other people with an open or disconnected session.
If anyone else is signed in, it names them, says that restarting closes their apps and loses their unsaved work, and restarts only when you choose **Restart anyway**.
Nothing counts down while someone else is signed in: **Restart now** asks first.
When Windows won't list the sessions, the restart goes ahead and the reason is logged.

Microsoft documents the parts this relies on in [Run and RunOnce registry keys](https://learn.microsoft.com/windows/win32/setupapi/run-and-runonce-registry-keys) and [`IInstallationResult::RebootRequired`](https://learn.microsoft.com/windows/win32/api/wuapi/nf-wuapi-iinstallationresult-get_rebootrequired).

## The check before the install

Before Capture, the front door runs the worker again with `-VerifyOnly`, from the protected staging copy of the Atlas package.
It passes only when:

- an online Windows Update search finds no required updates, apart from those recorded under `HKLM\SOFTWARE\AtlasOS\Preparation` and Defender's own updates on a PC Atlas removed Defender from (see [Windows updates](#windows-updates));
- Microsoft Store is registered for you, with no outstanding updates or active queue items;
- the connection has confirmed internet access and isn't metered, over its data limit or roaming;
- Windows needs no restart, apart from a servicing flag found stale as [Restarts](#restarts) describes;
- the Windows Update service is available.

The check never downloads or installs updates.
Store updates it finds are queued paused, even with automatic downloads off.
Finish them on the **Get ready** page, whose next run resumes the queue, or in Microsoft Store, then try again.

Each check runs in a new job folder inside the staging copy and ignores earlier results.
When the `ExcludeWUDriversInQualityUpdate` policy is set, as the **Install drivers myself** choice sets it, the check doesn't wait for drivers.
A refused check ends the front door with exit code 5 (see [The front door](front-door.md#exit-codes)).

## Logs and failure reasons

Every step and its result go to `updates.log` in the job folder.
The log lists the Store's packages and frameworks by version before and after.
For each Store item the worker waited for, it gives the package family, the product ID, the installed versions before and after the attempt and how it ended.
A failed item also gets the Store's error code.

The Store reports most failed installs only as `0x80073CF9`.
So when an item ends with an AppX deployment error, `updates.log` also gets the events 401 and 404 that the `Microsoft-Windows-AppXDeploymentServer/Operational` log recorded since the run started, under the package each names.
They give the cause, such as `0x80070490`.
For `0x80070490`, the worker also looks for nearby related StateRepository errors once per run and logs up to five.
A log that can't be read is noted, and the run goes on.
See [Log limits](diagnostics.md#log-limits) for how much of each log Atlas keeps.

While Windows moves to a newer release, the worker also writes `windows-transition.log` beside the job folders, and notes there how many AppX events it found.
These logs belong to the **Get ready** page, so they aren't under `%windir%\AtlasModules\Logs`.
**Export diagnostics** includes them, and `tools/dev/Get-AtlasInstallReport.ps1` lists the Store lines from the latest runs, with any [staging evidence](#updates-windows-cant-stage) in full.

| Reason | Meaning |
| --- | --- |
| `session-owner` | The worker isn't running as the signed-in owner of the session. |
| `manual-updates` | Some updates need you to finish them in Windows Settings, including updates that didn't finish after a restart for them. |
| `windows-passes` | Windows still offers updates after eight passes. |
| `windows-update-unreachable` | Windows Update couldn't be reached, or kept stopping, on every try. |
| `component-store-unrepairable` | Windows reads its component store as damaged beyond repair, or an update stays missing its files after the repair (`0x800F0831`). |
| `store-missing` | Microsoft Store isn't registered for you. |
| `store-paused-battery`, `store-paused-network` | The Store paused an update until the PC is plugged in or on Wi-Fi. |
| `store-timeout` | Store apps didn't finish updating in time. |
| `store-passes` | The Store still offers updates after eight passes. |
| `store-repair-failed` | None of the Store repairs made the Store work. |
| `store-appx-staging` | Windows couldn't stage updates for built-in apps (`0x80070490`), and the Store repairs didn't help. |

The `feature-*` reasons belong to moving Windows to a newer release, and are listed in [Moving Windows to a newer release](windows-transition.md#failure-reasons).
