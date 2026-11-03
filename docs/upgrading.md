# Upgrading Atlas

The Atlas 0.6 package accepts installed versions 0.4.1 and 0.5.0 (the 0.5.0-hotfix release records itself as 0.5.0). The source-version list is an eligibility check, not evidence that every version and Windows build combination has been tested. The current package accepts Windows 11 25H2 (build 26200) and 26H2 (build 26300); the upgrade on 26H2 has been checked only in VMs so far (see [the Windows release policy](windows-release-policy.md) and [Windows version transition](#windows-version-transition)). Source Atlas version and Windows build are separate requirements: on 24H2, Atlas Manager moves Windows to 26H2 before the Atlas upgrade (see [Windows version transition](#windows-version-transition)).

## What an upgrade applies

Before an update or same-version reinstall starts, an active Atlas Power Scheme is
treated as the power-saving choice **Disable**, even if an earlier installer left
an Enable record. Atlas Manager and the Windows transition snapshot read that same
evidence, and the installer repairs the record before keeping choices or replaying
toggles. Other power plans do not establish this choice and are not replaced merely
because their name differs. An installation whose steps have already begun keeps
its original captured choices.

Every update replaces the Atlas folder and modules, keeping Atlas's logs, and runs the current networking, performance, privacy, quality-of-life, security, debloat, scripts and miscellaneous tweak categories. A reinstall of the installed version runs them too (see [Reinstalling the same version](#reinstalling-the-same-version)). Tweaks declared with `OnUpgrade = 'Skip'` remain fresh-install only. What happens to the install choices depends on how the update treats them: see [Keep my choices or Choose again](#keep-my-choices-or-choose-again).

Recorded toggle choices take precedence over overlapping registry defaults. Their selected states are reapplied using the new definitions. New defaults are recorded only when applied. For a toggle with no recorded choice, migration adopts one only when existing registry values uniquely identify it and that choice does nothing but set registry values. A choice that also changes services or runs actions isn't adopted, because its values can match Windows' own defaults. Unrecognized customizations can't all be recovered automatically.

Upgrades preserve existing Start and taskbar layouts, file associations, and the original service backup files. They do not repeat the fresh-install service, component and AppX removal phases, so an established installation is not treated as a clean Windows image. Choose again changes only what its own choices cover.

## Keep my choices or Choose again

When Atlas Manager updates or reinstalls the installed Atlas, Your choices first asks how to update, or how to reinstall when the version is the same. It has two answers:

- **Keep my choices**, the default. Every choice stays as the PC has it now.
- **Choose again**. Every choice is asked again, starting from how the PC is set up now, and the installation applies each one as a new installation would.

The same screen lists **Your choices on this PC now**. Each choice comes from what the PC shows: Atlas's NoDefender package or the Defender service; the Mitigations, AutomaticUpdates, Hibernation, PowerSaving and KeyboardShortcuts toggle records; VBS turned off; Edge and Snipping Tool removed; the Toolbox, which counts as installed only while both its installer's record under `HKLM\SOFTWARE\AtlasOS\Toolbox` and its program are there, because Toolbox 0.1.x leaves the record behind when it is uninstalled; the browsers Atlas offers that are installed, and the browser recorded under `HKLM\SOFTWARE\AtlasOS\SetupOptions` while it's installed; and the installing user's Alt+Shift setting and keyboard layouts. What the PC shows wins over Atlas's record of the last installation, because an earlier update may have recorded a choice it never applied, and the screen names the choices where the record is wrong. A choice the PC doesn't show comes from that record, or from the record of a Windows move. Atlas 0.5.0 and 0.4.1 keep no record of their own, so only the PC, or a move's record, shows their choices.

Atlas Manager doesn't ask:

- on a first installation, which applies every choice;
- for an unfinished installation, which goes on as it began (see [Unfinished installations](#unfinished-installations));
- after Windows rebuilt itself during a move to a newer release, because a [Rebase](#rebase) puts back the choices recorded before the move;
- before the desktop exists, in an Atlas ISO's setup.

The front door's `-ChooseAgain` switch is the second answer, and without it an update keeps the choices. A Rebase refuses `-ChooseAgain` before anything changes, and a first installation ignores it with a note. AME Wizard never chooses again.

### Keep my choices

Your choices locks every choice to what the PC has, and asks only a required choice that neither the PC nor Atlas's record shows. When it knows them all, Continue goes from the first screen straight to Windows Security. The installation changes no choice, so what earlier choices did stays: Microsoft Defender that Atlas's NoDefender package removed stays removed, and the installation records it as removed.

The installation's Capture holds the request to the PC as well. It runs before the installing user is bound, within the broker's time limit, so it reads only the machine: Atlas's packages, the Defender service, the toggle records, the VBS settings, Edge, the Toolbox and the browsers. It takes each choice those show from the PC and logs a line for each, such as `Kept 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': Atlas's NoDefender package is installed. Run again with -ChooseAgain to change it.` Snipping Tool and eclean keep the request, and so does the keyboard choice unless a KeyboardShortcuts record shows it. The front door then names the choices it took (`Choices taken from this PC instead of the request: ...`), and a resume must give those options.

### Choose again

Your choices shows every screen again, starting from what the PC has, with **On this PC now** under the answer the PC has and, under an answer that changes the PC, what it changes. Some answers are fixed, because an update can't undo them:

- **Remove Microsoft Edge** stays ticked once Edge is gone. **Install or Remove Edge** in the Atlas folder puts it back.
- **Install Atlas Toolbox** stays ticked while the Toolbox program is installed, and **Install another browser** while a browser Atlas installed is there: Atlas doesn't uninstall apps. Another browser can still be chosen, and Atlas installs it beside the first.

**Keep Microsoft Defender** stays available when Defender is missing and no Atlas package removed it. The Windows Security step then warns that Atlas can't bring it back, without stopping the installation.

The installation adds the Choices step. It comes after Software, which installs a newly chosen browser or Toolbox, and before Defaults and the tweak categories. It reads the PC once and applies each choice that differs from it, as a first installation would:

- **Microsoft Defender.** Keeping it puts Defender's core service back and takes Atlas's NoDefender package off, so Defender is back after the restart. Removing it installs that package and turns the core service off at the next startup. Either change also installs Atlas's NoTelemetry package when it is missing. With the NoDefender package already installed, it only turns off a core service an earlier Atlas left on. Only Atlas's own package can be taken off, so a Defender missing without it stays missing, with a warning. A package still waiting for a restart fails an installation that keeps Defender (`Microsoft Defender couldn't be restored: ...`), and only warns one that removes it.
- **Microsoft Edge and Snipping Tool.** A ticked box removes Edge, or Snipping Tool from every account that has it, as a first installation does. Snipping Tool and Edge's apps are also removed for new accounts and deprovisioned while Windows still provisions them, even when no account has them installed, so a feature update doesn't bring them back. A cleared box puts nothing back.
- **The choice toggles**: PowerSaving, Hibernation, Mitigations, AutomaticUpdates, VbsState and KeyboardShortcuts, applied through Atlas's own toggles. A ticked box or a disable answer applies Disable. A cleared box or a default answer undoes Atlas's own Disable, only where Atlas recorded the toggle, so a power plan or update setting the user made isn't touched. With every processor protection on (a Mitigations record of 2), keeping protections leaves them all on. Clearing **Turn off VBS** while VBS is off turns it back on after the restart, unless a policy controls it: VBS then stays as it is, with the warning `Left VBS as it is: <reason>.` A UEFI lock stops only turning VBS off. The keyboard answer is always applied.

The step records the toggles it set in `%windir%\AtlasOS\Install\work\choices.json`, and Defaults leaves only those out of its replay. Every other record is replayed as when keeping the choices. An Edge or app removal that an interrupted attempt began is finished by the next attempt, even though the apps no longer show. A servicing or Edge failure fails the step at once; toggle and app failures fail it together, once every other choice is applied.

Neither way repeats Atlas's other app removals, Phone Link, OneDrive or Smart App Control, or changes the layouts and settings an update preserves.

### Reinstalling the same version

A reinstall of the installed version (Reapply) runs the eight tweak categories and the installing user's setup, whichever way it takes, so a new build's fixes reach a PC that already has that version. Recorded choices still win over the tweaks' defaults. Other accounts get the changes once, at their next sign-in: the installing user's setup stamps them under `HKLM\SOFTWARE\AtlasOS\UpgradeUsers` with the version and the installation's transaction ID, and the sign-in migration runs once for each stamp. Choose again adds the Choices step, as on an update.

### Unfinished installations

An installation that stopped goes on the way it began, as it keeps its options. Home offers **Finish installing Atlas**, Your choices has no first screen, and Atlas Manager passes `-ChooseAgain` again when the installation began with it. From the command line, the front door says so (`Continuing the unfinished installation as it began, choosing again; its choices can't change now.`), and a Capture given other options names the ones it started with. Until its plan has started, a new request can still change both. An update that began keeping the choices then takes every choice the PC shows again, so Your choices holds those as **Keep my choices** does and asks only what the PC can't show. The Windows Security step goes by the way it began too: an update keeping the choices leaves Defender as the PC has it, whatever options it holds.

## What Atlas records

The options in `%windir%\AtlasOS\state.json` describe what the PC has, not what was asked for:

- **At completion.** Once the plan has run, completion reads the PC again, now with the apps installed for every account in Windows's profile list (local, Microsoft and work or school accounts) and the installing user's keyboard settings. An app left only staged, waiting for Windows to finish removing it, or registered only to SYSTEM or an account that no longer exists doesn't count, as nobody can open it. It takes each choice the PC shows from the PC, and records the result in `state.json` and the `option-*.flag` files. A Toolbox or browser that isn't installed afterwards is left out. A Defender package that Windows installs or removes at the restart this installation asks for already counts. Each choice recorded otherwise than requested gets a log line, such as `Recorded 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': ...`, and `Install\last.json` keeps the request as `options` beside `recordedOptions`. A reading that fails leaves the request for the choices it covers, with a warning. Completion also records, as `notApplied` in this installation's `history` entry in `state.json`, the choices the plan tried to apply that the PC doesn't have as asked. When it couldn't read the PC at all, the entry has no `notApplied`, and no notice follows. When the list names any, Atlas Manager's completion window says **Some choices didn't take effect**, naming those choices, with **Open log file**. A choice recorded otherwise only because nothing in the plan changes it isn't named: VBS already off when a first installation leaves its box clear, or Snipping Tool on another account when an update keeps the choices.
- **Between installations.** The choice toggles keep their install choice in step in the same write, whether they run from the Atlas folder or Atlas Toolbox: Mitigations, AutomaticUpdates, KeyboardShortcuts, Hibernation, PowerSaving and VbsState. So do **Toggle Defender**, for the restart it asks for, and **Install or Remove Edge**, by whether Edge is installed afterwards, along with `option-uninstall-edge.flag`, which decides whether a new account's setup cleans its Edge data. A record that can't be written is only a warning, and the next installation records what the PC has. While an installation runs, only its completion writes them.

When Atlas's record kept Microsoft Defender but Atlas's NoDefender package still removes it, as an earlier update could leave it, Home and the completion window warn that **Microsoft Defender is still removed**. The bar points to **Choose again** and to **Toggle Defender**, and can be dismissed for that installation.

### Records from before Atlas 0.6

Atlas Toolbox 0.1.x and the Atlas 0.5.0 launchers wrote toggle records under `HKLM\SOFTWARE\AtlasOS\Services`, not always as Atlas 0.6 reads them. A launcher always wrote its file name as `path` beside the state. The Toolbox's pages for Mitigations, the shortcut icon and the terminal menu never did, and never changed the PC: they merged their files from a folder no Atlas install has. On an update from before 0.6, the installation repairs these records once, before anything reads them, and logs each change: the front door's Capture does it for an Upgrade or Rebase, and AME Wizard's Begin for an Upgrade. A run whose plan has started doesn't do it again.

- **Mitigations and ShortcutIcon.** A record whose path names one of their launchers is set from that launcher's file name, whatever the Toolbox wrote over it since. A record without a path is removed, and nothing is replayed for it: only the Toolbox wrote it, often just by opening, in its own numbering. Your choices reads the Mitigations record the same way, and so reads the one a Windows move's record kept for a Rebase: a record an earlier release wrote may hold the Toolbox's own, so its Mitigations choice stands only beside a launcher's record, and is asked otherwise.
- **ContextMenuTerminals** without a path takes the terminal menu the PC has, because the Toolbox numbered it differently. It is removed when the menu can't be read.
- **FileSharing** 0 written for **Enable File Sharing** is removed. So is **Printing** 0 from **Disable Printing** while the Print Spooler is on: every Atlas 0.5.0 install recorded it when it only took printing off the context menu.
- The Toolbox's own records move to Atlas's: `SearchIndexing` goes, recording `Indexing` 0 only when it turned search indexing off; `AppIconsThumbnail` and `HightestMode` become `AppIconThumbnail` and `HighestMode`, with the PC deciding when both exist; a `Recall` record in other letter case is renamed; and its CPU Idle desktop menu goes, and without an Atlas record of that menu the update adds Atlas's instead.

The record of a Windows move reads Mitigations and ShortcutIcon by the same rule, because no update has repaired the records when it is written: it keeps neither a record only the Toolbox wrote nor a choice that came from one. A Rebase also repairs the toggle records as Capture does, before anything reads them, including those it brings back from the move's record, so one that an earlier release's move record kept is repaired too.

Every installation's PreInstall step also deletes the old Toolbox's records outside the toggle store: those directly under `HKLM\SOFTWARE\AtlasOS` (Toolbox 0.1.1 to 0.1.9), the ones there named `Services<Name>`, without the backslash, and its settings in `ServicesToolbox` (0.1.10), and its `FeatureUpdateDeferrals` and `QualityUpdateDeferrals` records. A key goes only when it holds nothing but the values the Toolbox wrote there; any other is left, with a warning. `HKLM\SOFTWARE\AtlasOS\Toolbox`, the Toolbox installer's own record, stays.

## User settings

On a PC that several people use, each with their own account:

- **Windows and the machine.** The move to a newer Windows release, Windows Update's settings,
  services, policies under `HKLM` and the AppX removals apply to the whole PC, so to every
  account.
- **The person installing.** Their ordinary settings run under their own non-elevated token
  during the install, and the privileged installation pass handles their protected user
  policies. Both apply during the install.
- **Other existing accounts.** Each is registered for a versioned migration of ordinary user
  settings that runs when that person next signs in, and a reinstall of the same version
  registers them again ([Reinstalling the same version](#reinstalling-the-same-version)). A
  successful migration records `HKCU\SOFTWARE\AtlasOS\UserSetup\UpgradeVersion`. A failed one
  doesn't write the marker, so it runs again at the next sign-in. The sign-in pass doesn't
  migrate protected policy roots, so those accounts may keep older protected user policies.
- **New accounts** created after the install get the new-user setup at their first sign-in.
- **Restarts.** Before any restart Atlas Manager makes (for Windows updates, for the move to a
  newer release, and after the install), it checks for other people with an open or
  disconnected session. If anyone else is signed in, it names them, says that restarting closes
  their apps and loses their unsaved work, and restarts only when the user chooses **Restart
  anyway**. No countdown runs while someone else is signed in. When Windows won't list the
  sessions, the restart goes ahead without asking and the reason is logged. The installer's own
  restart through `Install-Atlas.ps1 -Restart`, which Atlas Manager doesn't use, doesn't check.

User migration transcripts are stored in `%LOCALAPPDATA%\AtlasOS\Logs`. Check the completed install transaction and run Atlas health checks after reboot, under the affected user as well as the installing account. A successful installer alone does not prove that application updates or every user's settings work.

### Microsoft Store apps of other accounts

Get ready updates Microsoft Store apps through the Store for the signed-in user only. A Store
app is installed once for the PC and registered for each account that has it
([how packaged apps are installed](https://learn.microsoft.com/windows/msix/desktop/desktop-to-uwp-behind-the-scenes)).
An app the installing user has too gets its newer version registered for another account when
that person next signs in
([apps after an update](https://learn.microsoft.com/troubleshoot/windows-client/application-management/modern-apps-application-packages-reported-vulnerable)).
An app only another account has isn't updated. Atlas 0.5.0 and Atlas 0.6 both turn off
automatic Store app updates for the whole PC
(`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload`=2,
the tweak `qol/disable-store-auto-updates`), so those apps stay at their version until that
person updates them in Microsoft Store (**Library** > **Get updates**). The Atlas install itself
doesn't need them.

## Windows' component store

Windows installs updates into its component store (WinSxS). When the store is damaged, updates
fail, often with `0x80073712` (`ERROR_SXS_COMPONENT_STORE_CORRUPT`). Get ready repairs it at
most once per run with `DISM /Online /Cleanup-Image /RestoreHealth`, which takes replacement
files from Windows Update
([repairing a Windows image](https://learn.microsoft.com/windows-hardware/manufacture/desktop/repair-a-windows-image)):

- Before the run's first search, when Windows already records damage (`/CheckHealth` reads
  `Repairable`). PCs with Atlas packages installed are skipped: the packages by themselves make
  the store read as repairable, and a repair doesn't change that (see
  [the component store](architecture.md#the-component-store-and-the-atlas-packages)).
- When an update fails with `0x80073712`. The updates that failed get another try afterwards.

While DISM runs, the update card says Windows is being repaired first, which can take half an
hour or more. DISM reports no progress Get ready can read, and like Windows Update's own work it
isn't stopped: **Stop updating** waits for it to finish. If the repair leaves a restart, Get
ready restarts before it searches.

When Windows reads the store as `NonRepairable`, Get ready stops before any update with
`component-store-unrepairable`. When an update still fails with `0x80073712` after the repair,
Get ready stops with that code. Both offer **Create an Atlas ISO** for reinstalling Windows.
The health Windows reads, the repair's exit code and the health afterwards go to `updates.log`.

## Microsoft Store

PCs that ran Atlas straight over Windows from older media often have a Microsoft Store too old
to update apps. Get ready deals with the Store before the Store apps:

1. A Store that's staged or provisioned on the PC but not registered and working for the user
   is registered for them, from the newest package's manifest under `WindowsApps` or by its
   family name. That brings the Store back at once.
2. Get ready asks the Store to update itself, then App Installer, by package family
   ([`AppInstallManager.UpdateAppByPackageFamilyNameAsync`](https://learn.microsoft.com/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.updateappbypackagefamilynameasync)),
   and says so on the update card while it does.

Nothing Atlas 0.5.0 sets by default stops this: it leaves the Store's services alone, and
turning off automatic Store app updates (`AutoDownload`=2) doesn't stop an update Atlas asks
for.

If the Store still can't update, Get ready repairs it once per run, and tries the Store again
after each step that changed something:

1. `wsreset.exe -i`, run in the user's session. The switch isn't documented: it runs without a
   window, registers the Store's frameworks (UI.Xaml, VCLibs) again and updates the Store's
   purchase app in the background, and Get ready follows what it queued. It doesn't change the
   Store's or App Installer's version or register a Store the user hadn't registered. Plain
   `wsreset.exe`, which opens the Store, isn't used.
2. App Installer, then the Store through winget. When the PC has App Installer staged, or
   installed for another account, in a newer version than the user's, Get ready registers that
   copy for the user, with no download. It compares App Installer's own package versions: the
   list of provisioned packages gives the bundle's version (such as 2026.115.2221.0), which is
   always above the package's (such as 1.27.459.0), so it isn't used. When the PC has nothing
   newer, or registering it leaves the user's version as it was, Get ready installs App Installer
   and the frameworks it needs from the latest stable
   [winget-cli release](https://github.com/microsoft/winget-cli/releases) (the repository
   checked by its GitHub ids, each file by the SHA-256 GitHub records and Microsoft's
   signature). Then it installs the Store itself with
   `winget install --id 9WZDNCRFJBMP --source msstore`.
3. StoreFixer, through Atlas 0.6's own **Fix MS Store Issues**, which runs it as
   TrustedInstaller. A PC with an older Atlas has no safe way to start it, so this step is left
   out there.

The first step after which the Store works ends the repairs, and the card says what was done.
If none helps, Get ready stops with `store-repair-failed` and offers **Repair Microsoft Store**,
which runs the repairs again, **Create an Atlas ISO**, for reinstalling Windows when the Store
still can't be repaired, and **Send a report**.

An app update that ends in `Error` or `Canceled` is cleared from the Store's queue, and the
Store is searched again. If it offers the app again, Get ready waits for it again and stops if
it fails again. If it no longer offers it, the app is up to date: a busy Store can report
`Error` for an update it has already installed. The log says which.

Every step and its result go to `updates.log` in the job folder (and `windows-transition.log`
during a move): the Store's packages and frameworks by version before and after, and each Store
item Get ready waited for, with its package family, its product ID, the version before and
after, and how it ended, with the Store's error code when it failed. The Store reports most
failed installs only as `0x80073CF9`, so when an item ends with an AppX deployment error,
`updates.log` also gets the events 401 and 404 the
`Microsoft-Windows-AppXDeploymentServer/Operational` log recorded since the run started, under
the package each names, and `windows-transition.log` notes how many. They give the cause, such
as `0x80070490`. Each event is written once a run, with its text cut at 1,500 characters, and
`updates.log` takes at most four for each package each time an item fails, and 24 a run. A log
that can't be read is noted without stopping Get ready. These logs belong to Get ready, not to
the Atlas install, so they aren't under `%windir%\AtlasModules\Logs`; **Export diagnostics**
includes them, and `tools/dev/Get-AtlasInstallReport.ps1` lists the Store lines from the latest
runs.

A Store the user removed on purpose stays removed. Atlas 0.5.0's **Disable Microsoft Store**
and Atlas 0.6's Microsoft Store toggle record `HKLM\SOFTWARE\AtlasOS\Services\MicrosoftStore`
with `state`=0. With that record and no Store registered for the user, Get ready skips Store
app updates and says so, and the check before the install doesn't look for Store updates
either. Atlas 0.5.0's script removed the Store only for the account that ran it, so other
accounts may still have it. The install doesn't need the Store: NanaZip, for one, falls back
to its verified download.

## Verification

See [testing](testing.md) for repository checks. Release validation should include an actual official-release install, a customized baseline, upgrade through Atlas Manager (with Keep my choices and with Choose again) and through AME Wizard, a reinstall of the same version, reboot, health checks, preservation of selected choices and backups, Microsoft Store deployment, and a BITS transfer. Test additional existing profiles and a new profile separately. VM checks do not establish performance or driver compatibility on physical hardware.

## Windows version transition

Windows 11 24H2 (build 26100) is not in `SupportedBuilds`. Atlas Manager moves a 24H2 PC
to 26H2 (build 26300) in Get ready, before the Atlas upgrade, and recommends the same move
on 25H2, where the user can keep 25H2 instead. Windows Update offers 26H2 to both as
"Windows 11, version 26H2", which installs Microsoft's enablement package KB5121794: a small
update that switches on files Windows already has, so Atlas's servicing packages, removed
apps, services, policies and recorded choices stay. If Windows rebuilds itself instead, the
Atlas install puts Atlas back (see [Rebase](#rebase)). The move needs a supported edition
(not Home, LTSC or Server) and nothing else that would stop the Atlas install; Atlas
Manager's Home page says so for other editions and for versions with no path, such as 23H2.

How the move works:

- Windows Update stays pinned to the installed version. Atlas never lifts the pin to let
  Windows move: it retargets it to 26H2 (`TargetReleaseVersion`=1,
  `ProductVersion`=`Windows 11`, `TargetReleaseVersionInfo`=`26H2`; see the
  [TargetReleaseVersion policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-update#targetreleaseversion))
  and never sets `DisableWUfBSafeguards`. Stopping before the move puts back the original
  values, or their absence. The Atlas install writes the same pin afterwards, so Windows stays
  on 26H2.
- Before the first change, the update worker records the Windows Update settings it may
  change in `HKLM\SOFTWARE\AtlasOS\WindowsTransition` and checks that it can work: no
  update server (WSUS), BITS, Cryptographic Services and Windows Modules Installer not
  disabled, at least 6 GB free on the system drive, a component store Windows can
  repair (Atlas PCs can read as repairable from the Atlas packages alone; see
  [the component store](architecture.md#the-component-store-and-the-atlas-packages)), a
  working connection, no pending restart, and pin values it can record (a value it couldn't
  put back stops the move with `feature-pin`). These checks also run when plain updates left
  their record open. It also records what the Atlas install was: its
  version, the install choices its records show, its toggle records, and which apps, Edge
  and OneDrive were installed. Then it turns Windows Update on where Atlas 0.5.0's toggles,
  the user or another tool turned it off, paused it or delayed monthly updates, installs the
  monthly updates, retargets the pin, and installs the 26H2 upgrade. Every search asks the
  Windows Update service itself
  ([`ServerSelection`](https://learn.microsoft.com/windows/win32/api/wuapicommon/ne-wuapicommon-serverselection)
  = `ssWindowsUpdate`), not the first service registered with Automatic Updates, which on
  some PCs is a catalogue that doesn't offer the release; a PC that gets
  updates from its organisation's server keeps that server for plain updates and is refused
  a move. Windows Update reads the pin only when it starts or scans, so the
  worker restarts it and waits up to two minutes for its policy state to show 26H2 before the
  first search. Windows Update then offers the release some minutes later, so after a first
  search that finds nothing the worker restarts it once more (never more than twice in a
  run) and keeps searching online, 30, 60 and 90 seconds apart and then every two minutes,
  for up to 10 minutes. Atlas Manager says it is waiting for the offer meanwhile, and **Stop
  updating** still works. If Windows Update still offers nothing, Get ready says it is
  waiting and offers **Check again**. Of the upgrades offered, the worker installs the one
  whose KB number Atlas knows or, failing that, the one whose title names 26H2; if several
  titles do, it installs none. Any other upgrade is logged and left alone. Windows Update can
  give the offer the KB number of a monthly update (KB5129195 is also the September 2026
  security update), so update history counts as 26H2 only by the id of the update Atlas
  installed or by a title that names the release. The licence terms are accepted only after
  the user accepts them in Atlas Manager.
- Until 13 October 2026, the update needs the optional preview update KB5124010. Before the
  move, the worker asks Windows Update for optional updates
  (`DeploymentAction='OptionalInstallation'`) and installs only Windows's own cumulative
  update for the installed build: KB5124010, or a newer one whose title names a later
  revision of the build. It installs no other optional update, and when two cumulative
  updates for the build are offered together it installs only the newer.
- An update that installs successfully and is offered again at once, such as the Windows
  Security platform update, is installed once and then left for 30 days: it's logged as
  `reoffered-after-success` and recorded under `HKLM\SOFTWARE\AtlasOS\Preparation`, so the
  install's own check doesn't wait for it either.
- A driver that Windows Update fails with 0x80070103, because the device already has one
  at least as good, is logged as `driver not needed` and kept in the same record for 30
  days, so the install's own check doesn't wait for it either.
- Atlas commits the change once, just before it restarts Windows: it finds the installed
  update again by the id the record keeps and commits it. A commit that fails is logged, and
  the restart goes ahead: only the build Windows starts decides whether it moved.
  After the restart the worker records how Windows moved, then finishes the monthly and
  Store updates.
- Near its end, after it has replayed the recorded choices and written the pin, the Atlas
  install puts back the Windows Update settings the record lists, except those a recorded
  toggle choice set: the install has already replayed those. A setting changed after Atlas
  turned it on is left as it is. A setting that can't be put back stays in the record, with
  the reason in the log, and Home offers to put it back; the others go back regardless.
- The install waits until Atlas Manager has checked how Windows moved, because that decides
  the install mode, and stops when Atlas packages are gone without Windows having reinstalled
  itself.

Windows Update can take from under a minute to about 2 hours to offer 26H2 once the pin
targets it; Home's plan and the 26H2 card say so before the move starts. If it offers
nothing yet, Get ready says it is waiting, not that something failed, and while Atlas
Manager stays open it looks again by itself every 10 minutes for up to 2 hours (the
worker's `-OfferOnly` run, which installs nothing else), with Windows Update left on for the
move the user chose. Meanwhile an indeterminate progress bar stays on the card with how long
Atlas has waited and when it looks next; the bar's accessible name stays the same across the
looks, so a screen reader hears only a change. When the offer comes after the window lost
focus, its taskbar button flashes. A look that loses the connection doesn't end the wait.
When the move waits for a newer monthly update first (`feature-prerequisite`), the looks are
full runs, since only those install it. **Check again** looks at once. When the offer comes,
the move goes on; after 2 hours without one, Atlas Manager puts the settings back (once
nothing else runs) and says to check again later, or to reinstall from an Atlas ISO after a
backup. While an Atlas install is still to finish, it only stops looking, because that install
puts the settings back as its last step. Opened again on a move still waiting, Home offers
**Check again** and Get ready looks once by itself. Hardware below the Windows 11
requirements is named as such (reinstall from an Atlas ISO).

Cancelling from any step before the install starts (Cancel asks first, and **Stop updating**
on the card between looks does the same), or closing Atlas Manager before 26H2 is installed,
puts the settings back exactly, the original pin included; so does closing after Atlas Manager
has reopened from a restart. If they can't be put back, Atlas Manager says why and closes only
if the user still wants to. After the move, putting them back keeps the 26H2 pin. Home offers
**Put back settings** whenever a record is open, no Atlas install is unfinished and Windows
didn't rebuild itself. After a rebuild nothing is put back before the Atlas install: the record
is what the install puts Atlas back from, and the install puts the settings back itself.

To undo the move, uninstall it from Update history in Windows Update or, if Windows
reinstalled itself, choose **Go back** in Recovery settings within 10 days. Atlas 0.6 doesn't
support 24H2, so a PC that started there shouldn't undo it after the Atlas install.

### Rebase

If Windows Update replaces Windows instead of switching 26H2 on, Setup brings back
Defender, telemetry and Edge, resets services and tasks, and moves `%windir%\AtlasModules`
and `AtlasDesktop` to `Windows.old`. After the restart, the worker decides once which
happened and keeps the answer in the record. No single sign decides, because a cumulative
update can leave an empty `Windows.old`: Windows was rebuilt only when `Windows.old\Windows`
holds files, Setup's `$WINDOWS.~BT` folder or a `Panther\setupact.log` written during the
move shows that Setup ran, and Atlas's servicing packages or its folder are gone. Atlas's
components gone with no sign of Setup stops the update with `feature-components-lost`.

The record also has a copy at `%ProgramFiles%\Atlas Setup Recovery\WindowsTransition`,
which a rebuilt Windows keeps even if it loses `HKLM\SOFTWARE\AtlasOS`. From either, Atlas
Manager recognises the Atlas install when the version markers are gone, and the install runs
in **Rebase** mode: the Upgrade plan, plus the fresh-install Services, Components and AppX
phases and the fresh-install tweaks that declare `OnRebase = 'Run'` (the service backup,
devices, version-specific files and default account pictures). The choices are the ones
recorded before the move: Your choices shows them and asks only for a required choice
nothing recorded. A Rebase always keeps them, so to change them, reinstall Atlas once it has
finished and choose again ([Keep my choices or Choose again](#keep-my-choices-or-choose-again)).
A Rebase:

- copies `winServices.reg` and `atlasServices.reg` back from `Windows.old`, and brings back
  the toggle records from the record when Windows lost them all, with their Atlas 0.5.0
  launcher paths, and the browser choice when it's missing; records from before 0.6 are then
  repaired ([Records from before Atlas 0.6](#records-from-before-atlas-06));
- keeps every recorded toggle choice for the Defaults phase to replay instead of applying the
  fresh-install defaults over it;
- removes Edge, OneDrive and AppX families only where they weren't installed before the move,
  so nothing the user kept or put back loses its data (see below for other accounts); Your
  choices shows **Remove Microsoft Edge** cleared when Edge was installed before the move;
- removes Defender again when the recorded choice was to remove it (Windows Security's
  switches must be off first, as for any install);
- leaves out the fresh-install steps that would overwrite the user's own settings: the Start
  and taskbar layouts, file associations, Send To, the Atlas theme, hidden Settings pages and
  the power plan.

What a Rebase does for each account:

- **AppX.** The record lists the app families installed for any account in Windows's profile
  list before the move (`Get-AppxPackage -AllUsers`), work or school accounts included. A
  package only staged, registered only
  to SYSTEM or an account that no longer exists, or waiting for Windows to finish removing it
  doesn't count. A Rebase leaves every family listed for every account, and
  removes, for all accounts, only families nobody had: those Windows put back, as a fresh
  install removes them. Nobody's data for an app they had is touched. When the apps couldn't
  be listed before the move, the record has no list, and a Rebase removes none.
- **OneDrive.** The record notes OneDrive when it's installed for the whole PC or in any
  account's profile, not only the installing user's. A Rebase then leaves it. Otherwise it
  uninstalls the copy Windows put back and its machine-wide pieces, as a fresh install does.
- **Edge.** Edge is installed for the whole PC. A Rebase removes it only when it wasn't installed
  before the move and the recorded choice was to remove it.
- **Leftover files and settings** of Edge, OneDrive and the removed apps (`HKCU` and profile
  folders) are cleared only for the installing user, in their own token, as in a fresh install.
  Other accounts' profiles aren't changed.

The move has been checked in VMs from Atlas 0.5.0 on 24H2 and on 25H2 (also with Windows
Update turned off, paused and delayed, a second account signed in, and Microsoft Store removed,
unregistered or out of date) and on a PC already on 26H2. It still needs validation from 0.4.1,
on ARM64, on hardware below the Windows 11 requirements and on the refused editions.

Other existing profiles, new-profile first sign-in, different feature
choices and physical hardware still require candidate-specific validation. See the
[release verification matrix](reliability-verification-matrix.md).
