# Moving Windows to a newer release

This page explains why and how Atlas Manager moves Windows to a newer release before it installs Atlas, and how Atlas is put back if Windows rebuilds itself on the way.
It's for contributors and testers.

Here, moving Windows to a newer release means installing a feature update.
A feature update takes Windows from one release to the next, such as from one yearly Windows 11 release to the following one.
The rest of the work Atlas Manager does before an install is described in [Preparing Windows](preparation.md).

## Why Atlas Manager moves Windows

Atlas installs only on the Windows releases in the [supported releases](windows-release-policy.md#supported-releases) table.
When a PC runs a release Atlas Manager knows how to move from, Atlas Manager offers a feature update on the **Get ready** page:

- On a release the Atlas package doesn't support, the feature update is required before the install.
- On a supported release with a newer supported one available, Atlas Manager recommends it, and you can keep your release.

The feature updates Atlas Manager can make are listed in `TRANSITIONS` in [`app/src/services/windows_release.rs`](../app/src/services/windows_release.rs).
Each entry gives the source builds, the target build and release, the KB numbers Windows Update is known to offer it under, and the prerequisite update (see [Monthly updates and the prerequisite](#monthly-updates-and-the-prerequisite)).

Each of these feature updates is an enablement package.
The new release's files are already on the PC, and one restart switches it on.
So Atlas's servicing packages, removed apps, services, policies and recorded choices stay.
If Windows rebuilds itself instead, the Atlas install puts Atlas back (see [Rebase](#rebase)).

A feature update needs a supported edition, which excludes Home, LTSC and Server, and a released Windows build, which excludes Insider builds.
It also needs nothing else that would stop the Atlas install.
Atlas Manager's **Home** page says when an edition or a release has no path to a supported one, and when the current release stops getting security updates on Home and Pro editions.

## How it works

The preparation worker, `Preparation/Update-Windows.ps1`, does the work, with the functions in `Preparation/WindowsTransition.ps1`.
A run decides from the PC each time, so a run interrupted by a restart or by closing Atlas Manager starts again where the PC is.

1. It runs the [preflight checks](#preflight-checks) and records the Windows Update settings it may change, and what the Atlas install was.
2. It turns on Windows Update where something held it back.
3. It installs the monthly updates, including the prerequisite update.
4. It retargets the update pin to the new release.
5. It waits for Windows Update to offer the feature update, then installs it.
6. It commits the update and Atlas Manager restarts Windows.
7. After the restart it decides how Windows moved, then finishes the monthly and Microsoft Store updates.
8. The Atlas install that follows puts the Windows Update settings back as its last step.

You accept Microsoft's licence terms for the new release in Atlas Manager, and the worker accepts them on Windows Update's side only after that.

## Preflight checks

Before the first change, the worker checks that the feature update can work.
The checks also run when an earlier run of ordinary updates left its record open (see [Turning Windows Update on](#turning-windows-update-on)).
The first problem stops the run before anything changes.

| Check | Stops with |
| --- | --- |
| Windows doesn't need a restart | A restart first |
| The connection has confirmed internet access and isn't metered or roaming | The connection's reason |
| The PC doesn't get updates from its organisation's server (`AU\UseWUServer` isn't 1) | `feature-managed` |
| BITS, Cryptographic Services and Windows Modules Installer exist and aren't disabled | `feature-blocked` |
| The system drive has at least 6 GiB free | `feature-disk-space` |
| Windows doesn't read its component store as `NonRepairable` | `feature-servicing` |
| The current pin values are ones Atlas can record and put back | `feature-pin` |
| An existing record is readable and owned by SYSTEM or Administrators | `feature-journal` |
| Windows is on a source build of the feature update, or on its target | `feature-build` |

An Atlas PC can read its component store as repairable because of the Atlas packages alone (see [The component store and the Atlas packages](preparation.md#the-component-store-and-the-atlas-packages)).
So a repairable store doesn't stop the feature update.
The worker logs the corrupt items that the newest check in `CBS.log` names, labelled as the known Atlas package pattern or not, and goes on.
A health check that can't run is logged with its error, and the worker goes on too.

## What Atlas records first

The record is `HKLM\SOFTWARE\AtlasOS\WindowsTransition`, which only administrators and SYSTEM can write.
For each Windows Update setting the worker may change, it keeps the original value, or its absence, and whether the worker turns it on.
It also keeps the source and target releases and the installed Atlas packages.

The first record also notes what the Atlas install was, in case Windows rebuilds itself:

- the Atlas version;
- the install choices, from `state.json` with what the PC shows taking precedence, or from the PC alone for an Atlas older than 0.6;
- the toggle records, with the file names of Atlas 0.5.0's launchers;
- the browser Atlas recorded;
- the app families installed for any account, and whether Edge, OneDrive, Microsoft Defender and the Atlas folder were there.

A copy goes to `%ProgramFiles%\Atlas Setup Recovery\WindowsTransition`, which a rebuilt Windows keeps even when it loses `HKLM\SOFTWARE\AtlasOS`.
Only the first record reads the Atlas install, because on a resume the PC may already be rebuilt.
The toggle records are read as [Records from before Atlas 0.6](install-state.md#records-from-before-atlas-06) describes, because no update has repaired them yet.

## Turning Windows Update on

The worker turns on only the settings that hold Windows Update back, from a fixed table in `Get-AtlasWindowsTransitionItem`.

| Group | Settings |
| --- | --- |
| Turned off | The `DisableWindowsUpdateAccess`, `DoNotConnectToWindowsUpdateInternetLocations` and `AU\NoAutoUpdate` policies, the `wuauserv` and `UsoSvc` services, and the `sih` and `sihboot` tasks |
| Delayed | The `DeferQualityUpdates` and `DeferQualityUpdatesPeriodInDays` policies |
| Paused | The pause values under `WindowsUpdate\UpdatePolicy\Settings` and `WindowsUpdate\UX\Settings` |
| Pin | `TargetReleaseVersion`, `ProductVersion` and `TargetReleaseVersionInfo`, which are retargeted instead of removed |

These are what Atlas 0.5.0's launchers, Atlas's own toggles or other tools set.
A task the PC doesn't have is recorded as absent and left alone.
Windows Update searches and installs without the tasks, so a task that can't be turned on doesn't stop the run.

The worker reads each value back after changing it.
A value that goes back, for example because an organisation's policy sets it, stops the run with `feature-policy`.
When something turns Windows Update off again during the run, such as a launcher from an earlier Atlas, the worker turns it on once more.
The second time, the run stops with `feature-blocked`.

While a record is open, the Atlas folder's toggles for Windows Update and for pausing updates refuse to change them.
A change then would mix a new choice into what Atlas puts back.

The **Get ready** page uses the same record and the same restore for ordinary updates on a PC whose Windows Update is turned off, paused or delayed.
That record doesn't touch the pin.

## Monthly updates and the prerequisite

The worker installs the monthly updates first, with the pin's target still unchanged, so Windows isn't told to move while they install.

A feature update can need the newest cumulative update for the installed build.
Windows Update can offer that update only as optional at first, and the ordinary pass doesn't install optional updates.
So before the feature update, the worker also asks Windows Update for optional updates (`DeploymentAction='OptionalInstallation'`).
Windows Update clients that can't answer that are asked for browse-only updates instead.

From what it finds, the worker installs only Windows's own cumulative update for the installed build:

- an update whose KB number the transition's prerequisite list names;
- or one whose title names a later revision of the installed build.

It installs no other optional update.
When two cumulative updates for the build are offered together, it installs only the newer one.
Once Microsoft's regular monthly updates include the prerequisite, the ordinary pass installs it.

The transition also gives the minimum revision that includes the prerequisite.
That value only explains a missing offer, and doesn't stop a run (see [Waiting for the offer](#waiting-for-the-offer)).

## Retargeting the update pin

Every Atlas install pins Windows Update to the installed release, with the `qol/windows-update/disable-feature-updates` tweak.
To move Windows, the worker retargets the pin to the new release instead of removing it.

| Value | Data |
| --- | --- |
| `TargetReleaseVersion` | 1 |
| `ProductVersion` | `Windows 11` |
| `TargetReleaseVersionInfo` | The target release, such as `<yy>H2` |

Microsoft documents these values as the [TargetReleaseVersion policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-update#targetreleaseversion).
`Set-AtlasFeatureUpdateTarget` is their only writer, and the Atlas pin tweak uses it too.
It creates the policy key only when it's missing, so the other policy values beside it stay, and it doesn't set `DisableWUfBSafeguards`.

Stopping before Windows moves puts back the original values, or their absence.
The Atlas install writes the same pin afterwards, so Windows stays on the new release.

## Waiting for the offer

Windows Update reads the pin only when it starts or scans.
So the worker restarts Windows Update, unless it's installing something, and waits up to two minutes for its policy state to show the new release before the first search.

Windows Update then offers the release some minutes later.
After a first search that finds nothing, the worker restarts Windows Update once more, at most twice in a run.
It then searches online again after 30, 60 and 90 seconds, then every two minutes, for up to 10 minutes.
**Stop updating** still works meanwhile.

Of the feature updates Windows Update offers, the worker installs the one whose KB number the transition lists.
Failing that, it installs the one whose title names the target release.
When several titles name it and none has a known KB number, it installs none and stops with `feature-failed`.
It logs any other feature update and leaves it alone.

Windows Update can give the offer the KB number of a monthly update.
So update history counts as the new release only by the ID of the update Atlas installed, or by a title that names the release.

When nothing is offered, the worker works out why, from the most specific cause to the least:

1. Windows installed the feature update by itself since the record was made, so the worker asks for the restart.
2. Windows Update has the update hidden: `feature-hidden`.
3. The installed revision is below the minimum the transition gives: `feature-prerequisite`.
4. The PC lacks TPM 2.0 or UEFI firmware, which Windows 11 requires: `feature-hardware`.
5. Otherwise: `feature-not-offered`.

`feature-not-offered` and `feature-prerequisite` are outcomes, so the logs record them as waiting, not as failures.

### Waiting in Atlas Manager

Windows Update can take from under a minute to about two hours to offer the release once the pin targets it.
**Home** and the release's card on the **Get ready** page say so before you start.

While nothing is offered, the **Get ready** page says it's waiting, without calling it a failure.
While Atlas Manager stays open, it looks again by itself every 10 minutes for up to two hours, with Windows Update left on.
Each look is the worker's `-OfferOnly` run, which installs nothing else.
When the wait is for the prerequisite (`feature-prerequisite`), each look is a full run, because only a full run installs it.

- An indeterminate progress bar on the card shows how long Atlas has waited and when it looks next.
  Its accessible name stays the same across looks, so a screen reader announces only a change.
- When the offer comes while the window is in the background, its taskbar button flashes.
- A look that loses the connection doesn't end the wait.
- **Check again** looks at once.
- Opened again on a wait, **Home** offers **Check again**, and the **Get ready** page looks once by itself.

When the offer comes, the feature update goes on.
After two hours without one, Atlas Manager puts the settings back once nothing else is running, and says to check again later or to reinstall from an Atlas ISO after a backup.
While an Atlas install is still to finish, it only stops looking, because that install puts the settings back as its last step.

## Installing the update and restarting

The worker downloads and installs the feature update on its own.
Any result that leaves work for a restart counts as installed, because the build Windows starts after the restart decides whether it moved.
When Windows wants a restart before the install, Atlas Manager restarts first.
A failed install gets one more try, and the second failure stops the run with `feature-failed`.

Atlas commits the installed update once, immediately before it restarts Windows.
The worker finds the update again by the ID the record keeps, and commits it.
Committing twice before one restart can fail the update, so the record notes the start of Windows in which it committed.
A commit that fails is logged, and the restart goes ahead.

After the restart:

- On the target build, the worker decides how Windows moved (see [Rebase](#rebase)), then finishes the monthly and Microsoft Store updates.
- Still on the old build after a restart from Start without Atlas's commit, it asks for one more restart through Atlas Manager.
- Still on the old build after that, Windows rolled the update back: `feature-rolled-back`.

## Putting Windows Update settings back

The Atlas install puts the settings back in its `WindowsTransition` step, near the end of the plan.
That step comes after the Defaults step has replayed your recorded choices and the `qol` tweaks have written the pin.

- Settings that a recorded toggle choice owns are left to that choice's replay.
- A setting changed since Atlas turned it on is left as it is.
- A setting that can't be put back stays in the record with the reason in the log, and **Home** offers **Put back settings**.
  The others go back regardless.
- A problem in this step is a warning, so it doesn't fail the install.

When the record closes, the worker keeps a summary of it as `LastResult` under the record's key.

The install waits until Atlas Manager has checked how Windows moved, because that decides the install mode.
It stops when Atlas packages are gone without Windows having reinstalled itself.
The front door's `No Windows update in progress` check enforces both (see [Requirement checks](front-door.md#requirement-checks)).

## Cancelling and undoing

These put the settings back exactly, original pin included:

- cancelling from any step before the install starts, which asks first;
- **Stop updating** on the card between looks;
- closing Atlas Manager before the new release is installed, or after Atlas Manager reopened from a restart.

If the settings can't be put back, Atlas Manager says why, and closes only if you still want it to.
After Windows has moved, putting the settings back keeps the new release's pin.

**Home** offers **Put back settings** whenever a record is open, no Atlas install is unfinished and Windows didn't rebuild itself.
In the other two cases, putting back is refused with `feature-install-active`.
After a rebuild, the record is what the Atlas install puts Atlas back from, and the install puts the settings back itself.

To undo the feature update, uninstall it from **Update history** in Windows Update.
If Windows reinstalled itself, choose **Go back** in Recovery settings within 10 days.
A PC that started on a release Atlas doesn't support shouldn't go back after the Atlas install.

## Rebase

If Windows Update rebuilds Windows instead of switching the new release on, Setup brings back Defender, telemetry and Edge, and resets services and tasks.
It also moves `%windir%\AtlasModules` and `AtlasDesktop` to `Windows.old`.

After the restart, the worker decides once which happened and keeps the answer in the record.
No single sign decides, because a cumulative update can leave an empty `Windows.old`.
Windows was rebuilt only when all of these hold:

- `Windows.old\Windows` holds files;
- Setup's `$WINDOWS.~BT` folder exists, or `Panther\setupact.log` was written since the record was made;
- Atlas's servicing packages or the Atlas folder are gone.

Atlas's components gone with no sign of Setup stops the run with `feature-components-lost`.

From the record or its copy, Atlas Manager recognises the Atlas install even when the version markers are gone.
The install then runs in Rebase mode: the Upgrade plan, plus the fresh-install Services, Components and AppX support phases.
It also runs the fresh-install tweaks that declare `OnRebase = 'Run'`, such as the service backup, devices, version-specific files and default account pictures.

The choices are the ones recorded before Windows moved.
**Your choices** shows them and asks only for a required choice nothing recorded.
A Rebase always keeps them, so to change them, reinstall Atlas once it has finished and select **Choose again**.

A Rebase:

- copies `winServices.reg` and `atlasServices.reg` back from `Windows.old`;
- brings back the toggle records from the record when Windows lost them all, with Atlas 0.5.0's launcher paths;
- brings back the browser choice when it's missing, then repairs records from before Atlas 0.6;
- keeps every recorded toggle choice for the Defaults step to replay, instead of applying the fresh-install defaults over it;
- removes Defender again when the recorded choice was to remove it, which needs the protection switches off first, as for any install;
- leaves out the fresh-install steps that would overwrite your own settings: the Start and taskbar layouts, file associations, Send To, the Atlas theme, hidden Settings pages and the power plan.

### What a Rebase does for each account

- **Apps.** The record lists the app families installed for any account in Windows's profile list before the feature update, work or school accounts included.
  A package that's only staged, registered only to SYSTEM or a deleted account, or waiting for Windows to finish removing it doesn't count.
  A Rebase leaves every listed family for every account, and removes, for all accounts, only families nobody had, which are the ones Windows put back.
  When the apps couldn't be listed beforehand, the record has no list, and a Rebase removes none.
- **OneDrive.** The record notes OneDrive when it's installed for the whole PC or in any account's profile.
  A Rebase then leaves it.
  Otherwise it uninstalls the copy Windows put back and its machine-wide parts, as a fresh install does.
- **Edge.** Edge is installed for the whole PC.
  A Rebase removes it only when it wasn't installed before the feature update and the recorded choice was to remove it.
  **Your choices** shows **Remove Microsoft Edge** cleared when Edge was installed before.
- **Leftover files and settings** of Edge, OneDrive and the removed apps, in `HKCU` and profile folders, are cleared only for the installing user.
  That runs under their own token, as in a fresh install.
  Other accounts' profiles don't change.

## Failure reasons

Every step of a run goes to `windows-transition.log` beside the preparation job folders, with each outcome's reason ID.
[Reporting problems](diagnostics.md#triage) explains where to find it in an exported ZIP.

| Reason | Meaning |
| --- | --- |
| `feature-managed` | The PC gets updates from its organisation's update server. |
| `feature-blocked` | A service Windows Update needs is turned off or missing, or Windows Update was turned off again during the run. |
| `feature-disk-space` | The system drive has too little free space. |
| `feature-servicing` | Windows reads its component store as damaged beyond repair. |
| `feature-pin` | A pin value is one Atlas couldn't put back later. |
| `feature-journal` | The record can't be read or can't be trusted. |
| `feature-policy` | A setting went back after Atlas turned it on. |
| `feature-build` | The Windows build is neither a source nor the target. |
| `feature-terms` | The licence terms weren't accepted. |
| `feature-hidden` | Windows Update has the feature update hidden. |
| `feature-prerequisite` | Windows needs a newer monthly update first, and Windows Update offers nothing newer. |
| `feature-hardware` | Windows Update offers nothing, and the PC lacks TPM 2.0 or UEFI firmware. |
| `feature-not-offered` | Windows Update doesn't offer the release to this PC yet. |
| `feature-failed` | Windows couldn't install the update, or several offers named the release. |
| `feature-rolled-back` | Windows went back to its earlier release after the restart. |
| `feature-components-lost` | Atlas components were gone after the restart without a sign of Setup. |
| `feature-restore` | Some settings couldn't be put back. |
| `feature-install-active` | Putting back is left to an unfinished Atlas install, or to the install after a rebuild. |
