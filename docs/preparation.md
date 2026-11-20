# Preparing Windows

This page explains what Atlas Manager's **Get ready** page does before it installs Atlas, and how the preparation worker behind it works.
It's for contributors, and for anyone working out why an update or a Microsoft Store repair stopped.

Moving Windows to a newer release also starts on the **Get ready** page, and has its own page: [Moving Windows to a newer release](windows-transition.md).

## What the Get ready page does

Atlas Manager brings Windows and Microsoft Store apps up to date before it installs Atlas, so that servicing doesn't run alongside the install.
The **Get ready** page shows the installation files, the PC checks, the drivers choice and the **Update Windows and Store apps** card.

When you start updating, Atlas Manager runs the preparation worker, which:

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
- **Stop updating** asks the worker to stop after the current step.
  Windows Update's and Microsoft Store's own work isn't interrupted, so a stop waits for it.

Atlas Manager's side of the job, including recovery after a restart, is in [Atlas Manager's install flow](../app/docs/install-flow.md#preparation-and-restart-recovery).

## Windows updates

The worker searches Windows Update online, downloads and installs what it finds, and searches again until nothing is left.

- Each search asks the Windows Update service itself (`ServerSelection` set to `ssWindowsUpdate`).
  The default service can be another catalogue on some PCs, and that catalogue may not offer the update Atlas needs.
- A PC that gets updates from its organisation's server (`AU\UseWUServer` set to 1) keeps that server.
- A search that ends with errors runs again, up to three times, 30 seconds apart.
- The worker leaves out optional previews (browse-only updates) and feature updates.
  It also leaves out drivers when you chose **Install drivers myself**.
- When one pass offers several cumulative updates for the installed build, it installs only the newest.
  Installing an older one first can leave the newer one to install again after a restart.
- Updates that can ask for input are installed last, silently.
  One that still needs you stops the run with `manual-updates`, naming the updates to finish in Windows Settings.
- A run gives up with `windows-passes` when Windows still offers updates after eight passes.

The worker stops waiting for two kinds of update:

- An update that installs successfully and is offered again at once, such as the Windows Security platform update.
  The log calls it `reoffered-after-success`.
- A driver that Windows Update fails with `0x80070103`, because the device already has one at least as good.
  The log calls it `driver not needed`.

The worker keeps both under `HKLM\SOFTWARE\AtlasOS\Preparation` for 30 days, up to 100 entries.
The check before the install reads the same record, so it doesn't wait for them either.

When Windows Update is turned off, paused or set to delay monthly updates, the **Get ready** page turns it on for the run.
It records the original settings first, and the Atlas install puts them back at its end (see [Putting Windows Update settings back](windows-transition.md#putting-windows-update-settings-back)).

## Windows component store

Windows installs updates into its component store (WinSxS).
When the store is damaged, updates fail, often with `0x80073712` (`ERROR_SXS_COMPONENT_STORE_CORRUPT`).
The worker repairs the store at most once per run with `DISM /Online /Cleanup-Image /RestoreHealth`, which takes replacement files from Windows Update.
Microsoft describes the repair in [Repair a Windows image](https://learn.microsoft.com/windows-hardware/manufacture/desktop/repair-a-windows-image).

The repair runs in two cases:

- Before the run's first search, when Windows already records damage (`/CheckHealth` reads `Repairable`).
  PCs with Atlas packages installed are skipped, as the next section explains.
- When an update fails with `0x80073712`.
  The updates that failed then get another try.

While DISM runs, the update card says Windows is being repaired first, which can take half an hour or more.
DISM reports no progress the worker can read, and like Windows Update's own work it isn't stopped.
If the repair leaves a restart, the **Get ready** page restarts before it searches.

When Windows reads the store as `NonRepairable`, the run stops before any update with `component-store-unrepairable`.
When an update still fails with `0x80073712` after the repair, the run stops with that error.
Both offer **Create an Atlas ISO** for reinstalling Windows.
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
- Before moving Windows to a newer release, the worker records the store's health and goes on with a repairable store (see [Preflight checks](windows-transition.md#preflight-checks)).

Windows's own scheduled store cleanup can have the same effect on any PC with the packages.

## Microsoft Store

PCs that ran Atlas over Windows installed from older media often have a Microsoft Store too old to update apps.
The worker deals with the Store before the Store apps:

1. A Store that's staged or provisioned on the PC but not registered and working for you is registered for you.
   The worker uses the newest package's manifest under `WindowsApps`, or the package family name.
2. The worker asks the Store to update itself, then App Installer, by package family, through [`AppInstallManager.UpdateAppByPackageFamilyNameAsync`](https://learn.microsoft.com/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.updateappbypackagefamilynameasync).
   The update card says so while it does.

Nothing Atlas 0.5.0 sets by default stops this.
It leaves the Store's services alone, and turning off automatic Store app updates (`AutoDownload` set to 2) doesn't stop an update Atlas asks for.

### Microsoft Store repair

If the Store still can't update, the worker tries these repairs once per run, in order, and tries the Store again after each one that changed something:

1. **`wsreset.exe -i`**, run in your session.
   The switch isn't documented.
   It runs without a window, registers the Store's frameworks (UI.Xaml, VCLibs) again and updates the Store's purchase app in the background, and the worker follows what it queued.
   It doesn't change the Store's or App Installer's version, or register a Store you hadn't registered.
   Plain `wsreset.exe`, which opens the Store, isn't used.
2. **App Installer, then the Store through winget.**
   When the PC has a newer App Installer staged, or installed for another account, the worker registers that copy for you without a download.
   Otherwise, or when registering it changes nothing, it installs App Installer and its frameworks from the latest stable [winget-cli release](https://github.com/microsoft/winget-cli/releases).
   Then it installs the Store with `winget install --id 9WZDNCRFJBMP --source msstore`.
3. **StoreFixer**, started through Atlas's own **Fix MS Store Issues**, which runs it as TrustedInstaller.
   A PC with an Atlas older than 0.6 has no safe way to start it, so the worker leaves this step out there.

App Installer versions are compared by the package's own version.
The list of provisioned packages gives the bundle's version, such as 2026.115.2221.0, which is always above the package's, such as 1.27.459.0, so the worker doesn't use it.
The winget-cli repository is checked by its GitHub IDs, and each file by the SHA-256 that GitHub records and by Microsoft's signature.

The first repair after which the Store works ends the repairs, and the card says what was done.
If none helps, the run stops with `store-repair-failed` and offers **Repair Microsoft Store**, which runs the repairs again.
It also offers **Create an Atlas ISO**, for reinstalling Windows when the Store still can't be repaired, and **Send a report**.

### Store app updates

An app update that ends in `Error` or `Canceled` is cleared from the Store's queue, and the worker searches the Store again.
If the Store offers the app again, the worker waits for it again and stops if it fails again.
If the Store no longer offers it, the app is up to date, because a busy Store can report `Error` for an update it has already installed.
The log says which.

A Store you removed on purpose stays removed.
Atlas 0.5.0's **Disable Microsoft Store** and Atlas's Microsoft Store toggle record `HKLM\SOFTWARE\AtlasOS\Services\MicrosoftStore` with `state` set to 0.
With that record and no Store registered for you, the worker skips Store app updates and says so, and the check before the install skips the Store too.
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

Before Atlas Manager restarts Windows for preparation:

- It saves the draft with the restart time, copies itself to `%ProgramFiles%\Atlas Setup Recovery` and adds the HKCU Run entry `AtlasWindowsPreparation`, which starts that copy with `--after-preparation-restart`.
- The entry opens Atlas Manager only after a new start of Windows, so sign-ins in the same session leave it in place.
  It's removed after the restart, or silently at its next launch if the draft was abandoned.
- On a PC installed from an Atlas ISO, the before-desktop shell starts Atlas Manager again instead.

After the restart, Atlas Manager restores the package and your choices and offers **Continue updates**, without marking preparation complete.
Failures to save, to register the Run entry and to restart have their own messages.
A failed restart keeps recovery in place for a restart through Windows.
When `shutdown.exe` answers that a shutdown is already in progress or scheduled (errors 1115 and 1190), the restart counts as accepted.

Before any restart Atlas Manager makes, it checks for other people with an open or disconnected session.
If anyone else is signed in, it names them, says that restarting closes their apps and loses their unsaved work, and restarts only when you choose **Restart anyway**.
Nothing counts down while someone else is signed in.
When Windows won't list the sessions, the restart goes ahead and the reason is logged.

Microsoft documents the parts this relies on in [Run and RunOnce registry keys](https://learn.microsoft.com/windows/win32/setupapi/run-and-runonce-registry-keys) and [`IInstallationResult::RebootRequired`](https://learn.microsoft.com/windows/win32/api/wuapi/nf-wuapi-iinstallationresult-get_rebootrequired).

## The check before the install

Before Capture, the front door runs the worker again with `-VerifyOnly`, from the protected staging copy of the Atlas package.
It passes only when:

- an online Windows Update search finds no required updates, apart from those recorded under `HKLM\SOFTWARE\AtlasOS\Preparation`;
- Microsoft Store is registered for you, with no outstanding updates or active queue items;
- the connection has confirmed internet access and isn't metered, over its data limit or roaming;
- Windows needs no restart;
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
For each Store item the worker waited for, it gives the package family, the product ID, the versions before and after and how it ended.
A failed item also gets the Store's error code.

The Store reports most failed installs only as `0x80073CF9`.
So when an item ends with an AppX deployment error, `updates.log` also gets the events 401 and 404 that the `Microsoft-Windows-AppXDeploymentServer/Operational` log recorded since the run started, under the package each names.
They give the cause, such as `0x80070490`.
A log that can't be read is noted, and the run goes on.
See [Log limits](diagnostics.md#log-limits) for how much of each log Atlas keeps.

While Windows moves to a newer release, the worker also writes `windows-transition.log` beside the job folders, and notes there how many AppX events it found.
These logs belong to the **Get ready** page, so they aren't under `%windir%\AtlasModules\Logs`.
**Export diagnostics** includes them, and `tools/dev/Get-AtlasInstallReport.ps1` lists the Store lines from the latest runs.

| Reason | Meaning |
| --- | --- |
| `session-owner` | The worker isn't running as the signed-in owner of the session. |
| `manual-updates` | Some updates need you to finish them in Windows Settings. |
| `windows-passes` | Windows still offers updates after eight passes. |
| `component-store-unrepairable` | Windows reads its component store as damaged beyond repair. |
| `store-missing` | Microsoft Store isn't registered for you. |
| `store-paused-battery`, `store-paused-network` | The Store paused an update until the PC is plugged in or on Wi-Fi. |
| `store-timeout` | Store apps didn't finish updating in time. |
| `store-passes` | The Store still offers updates after eight passes. |
| `store-repair-failed` | None of the Store repairs made the Store work. |

The `feature-*` reasons belong to moving Windows to a newer release, and are listed in [Moving Windows to a newer release](windows-transition.md#failure-reasons).
