# Atlas ISO creation (Beta)

The Atlas app builds a Windows 11 installation ISO that applies Atlas after
Windows setup, and writes that ISO, or an existing one, to a USB drive. This page
is for people creating media, contributors to the media workers, and release
testers.

## Requirements

| Item | Requirement |
| --- | --- |
| Windows build | 11 25H2 (build 26200) or 26H2 (build 26300), for the source ISO and any PC Atlas installs on. Not 24H2 (build 26100). |
| Source ISO | Windows 11 client media, all x64 or all ARM64, with its full version in Microsoft's General Availability release table. Media with an answer file or a `$OEM$` folder is refused rather than merged with unknown setup instructions. |
| Editions | At least one besides Home and the known LTSC editions. |
| Atlas package | 0.6.0 or newer. Saving choices in the ISO also needs `Executables\AtlasModules\Scripts\Install\iso-setup.json`. |
| Output | A new file on a local NTFS or ReFS volume with about 5 × the source ISO + 2 × the unpacked package + 4 GB free. |
| USB drive | A USB disk from 8 GB to 2 TB. It is erased. |

Supported builds come from `playbook.conf`, read by the PC checks, the ISO
edition filter and the USB writer. Upgrades from 0.4.1 and 0.5.0
(`UpgradableFrom`) also need a supported build; Atlas Manager moves 24H2 to 26H2
first, and offers the same move on 25H2
([upgrading](../../docs/upgrading.md#windows-version-transition)).
Where it can't, it points to this page instead, with a reminder to back up first:
a version with no update path (such as 23H2), hardware below the Windows 11
requirements, or a PC Windows Update isn't offering 26H2 to yet.

## Create an ISO

The flow is **Files → Windows setup → Your choices → Review → Create**. The
title carries a Beta badge, and the full Beta notice shows on Files. The flow is
independent of the live-install flow and its PC checks. Without administrator
access, the page offers only **Relaunch as administrator**.

1. **Files.** Choose the Windows ISO (**Download Windows 11 from Microsoft**
   opens Microsoft's download page), the Atlas package and where to save the
   new ISO, then **Check files**. Atlas suggests a name beside the source ISO
   that no file has yet (`Atlas-Windows.iso`, then `Atlas-Windows (2).iso` and
   so on) until you choose one. After a successful check the files card reads
   Ready and **Continue** replaces Check files; choosing another file clears the
   check. Rechecking the same package keeps the saved choices.
2. **Windows setup.** The local account, driver updates, the target PC and
   network drivers. An empty account name holds Continue with a hint; an
   invalid one is marked on the field.
3. **Your choices.** The mode and, when choices are saved in the ISO, the Atlas
   option pages.
4. **Review.** One card per earlier step, each with a Change link. It lists the
   included editions. Atlas sets no product key or image index, so Windows
   Setup asks and users choose a licensed edition. Firmware Home keys and
   volume-licence media need separate boot validation; these settings aren't
   evidence of activation.
5. **Create.** A checklist shows the build's stages: checking the source,
   copying Windows files, adding Atlas, preparing network drivers (only when
   the ISO includes them), writing the ISO, checking it and finishing up.

Back and forward keep every value, and the stepper jumps to any step already
reached while the steps between it are complete. A failure or cancellation
shows a bar with **Open log folder**, then the diagnostics, and a failed build
marks the stage it stopped at; the inputs stay. A result belongs to its step
and clears when you leave it. If the Atlas package changed after the check,
Files asks for **Check files** again.

### Modes

Atlas is applied after Windows setup and sign-in, not inside `install.wim`,
because Store updates depend on the destination user's registered apps. The
Windows editions in the ISO are copied unchanged; Atlas adds its own files and an
answer file beside them.

| Mode | Atlas choices | When Atlas opens |
| --- | --- | --- |
| **Make Atlas choices after sign-in** | Made on the destination PC | After sign-in |
| **Make Atlas choices now** | Saved in the ISO and preselected | After sign-in |
| **Finish setup before the desktop** | Saved in the ISO; the Your choices step is skipped | Full-screen after sign-in, before the desktop |

Without `iso-setup.json`, only the first mode is available. All modes run the
normal preparation, Windows Security and install steps, gates included.

**Finish setup before the desktop** is neither unattended nor a kiosk lock. It
needs elevation, a network connection and the security prerequisites. Explorer
runs behind the app, so Settings, Windows Security and Store apps work on Pro.
Windows shortcuts work, and other monitors may show the desktop. **Continue in
Windows** is offered unless an update, install, media job or restart countdown
is running.

### Local account

The answer file creates this local administrator. Names can't be built-in (such
as Administrator or Guest), contain control characters or
`" / \ [ ] : ; | = , + * ? < > @`, start or end with a space, end with a full
stop, or exceed 20 UTF-16 units. They're written through the XML DOM and JSON,
never into PowerShell commands. The field supports Unicode, IME composition,
selection, clipboard and keyboard navigation.

### Network-driver backup

Windows setup asks which PC the ISO is for. With **This PC** as the target,
**Include this PC's network drivers** adds the signed OEM packages of the
physical Ethernet and Wi-Fi adapters. Built-in Windows drivers, VPN and virtual
adapters, and Wi-Fi credentials aren't copied. In specialize, PnPUtil stages the
packages and installs those that match, even with **Install drivers myself**.

- **Use installed drivers** exports the installed packages.
- **Check Windows Update first** also downloads Windows Update's offers for the
  adapters' hardware and compatible IDs, keeping installed packages as a
  fallback. It needs an unmetered connection and never installs updates or
  changes the host's driver policy. It isn't a latest-driver search, and an
  offered driver may not support an older target build.

Downloads and the packaged total are each capped at 2 GB, and every package needs
INF and catalog files. The build exports the drivers last, after the answer
file. When the adapters use only drivers that come with Windows (and Windows
Update offers none), there is nothing to back up: the build adds no
`NetworkDrivers` folder, prints `ATLAS_NOTE:network-drivers-inbox`, and the
finished ISO's message says so. A package that fails to export stops the build,
which lets the user change the option. Atlas never claims a backup that didn't
happen. Code: `resources/iso/Network-Drivers.ps1`.

## Create a Windows installation USB (Beta)

**Create installation USB** is on the completed-ISO screen, and on the first ISO
screen for an existing ISO. Choose the drive explicitly; refreshing the list
clears the choice. The list shows each drive's model, capacity and volumes;
the review adds its serial number, and **Erase and create USB** stays
unavailable until you acknowledge the erase. Back, the title's back arrow and
Escape go from the review to the drive list, then out of the panel; the arrow
is unavailable while a job runs. Afterwards, eject from the app
(`CM_Request_Device_EjectW`), which leaves **Done**; a Windows veto gives a
recoverable error. A failure offers **Open log folder** and the diagnostics.

The result is UEFI media for Windows 11 x64 or ARM64 on a supported build; this
Beta doesn't support legacy BIOS boot or other operating systems. It has one
active MBR/FAT32 partition of up to 32 decimal GB, with the rest of the drive
left unused (unallocated), as disclosed before erasing. It uses the ISO's signed
UEFI boot files; Atlas adds no bootloader. A large `install.wim` is split with
DISM's integrity-checked split into `sources\install*.swm` parts of up to
3,800 MB; a large `install.esd` is first exported, with every edition, to a WIM.
Any other file over FAT32's 4 GB limit fails before anything is erased.

Safety rules (`resources/iso/Write-Usb.ps1`):

- **Refused disks.** Boot, system, offline and read-only disks, disks without
  identifiers, and disks holding the worker's ISO, app or working files.
- **Before erasing.** The source is locked against replacement, and space and
  capacity are checked. These failures are typed, so the app says what to change
  and that the drive wasn't touched.
- **Identity.** Disk number, hardware path, serial, model, capacity and unique ID
  are checked just before destructive operations. Copying and verification
  recheck disk and volume identity, rejecting unplugged or replaced devices and
  reused drive letters. Writes and verification use the volume GUID path, which
  a reassigned letter can't redirect.
- **One writer.** A global mutex blocks concurrent Atlas USB writes.
- **Cancellation.** Waits for uninterruptible Storage and DISM calls and stops
  copying between chunks. Partial media is never reported ready. A RAW drive,
  such as one left by a cancelled write, is initialized without being cleared.
- **Verification.** Every file is read back unbuffered, bypassing the Windows
  file cache, and compared by SHA-256. File-system metadata still goes through
  the cache.

## On the destination PC

1. **Windows Setup** copies the Atlas files to `%windir%\AtlasISO`.
2. **Specialize**, before OOBE, applies the driver-update choice and installs
   backed-up network drivers.
3. **OOBE.** The answer file creates the account through supported unattended
   settings, hides the licence and online-account screens and sets
   `ProtectYourPC=3` (Express settings off and hidden; Atlas's options hold the
   real security and update choices). The ISO's Windows setup step says so
   under the account name.
4. **Bootstrap logon.** One automatic logon disables further automatic logons,
   expires the empty password, registers the app for the next sign-in and signs
   out.
5. **Sign-in.** Windows asks for a new password, then Atlas opens.

## Preparing the PC

As in a normal install, the app installs recommended Windows updates, updates
Microsoft Store and finishes updates for all installed Store apps. Third-party
WinGet apps are out of scope. Atlas stays blocked until preparation succeeds.
Code: the Atlas package's
`Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1`, run by
`src/services/preparation.rs`; comments there explain each provider rule.

- **Network.** Checked before each provider pass. Wi-Fi and Ethernet work;
  offline, captive-portal, metered, roaming and restricted connections stop with
  a network-settings action. Users must install a missing Wi-Fi driver.
- **Scope.** Optional previews and feature upgrades are excluded, since a feature
  upgrade may leave the supported builds. The pending-update check uses the same
  rules.
- **Providers.** Windows Update Agent runs search, download, install and rescan
  passes. AppInstallManager `SearchForAllUpdatesAsync` installs Store app updates
  automatically and restarts the apps; the screen warns that they will close.
  Progress counts completed app updates.
- **Completion.** Each provider must report completion; partial or unknown
  results never continue, and an empty first scan alone proves nothing. Errors,
  missing Store registration, paused work, timeouts and reappearing updates fail
  with diagnostics and a suggested action.
- **Restarts.** The app never restarts the PC on its own; the user chooses
  **Restart and continue**. As soon as preparation needs a restart, the app
  saves the install draft and arms a per-user Run entry,
  `AtlasWindowsPreparation`, that waits for a new boot. Restarting from Windows
  therefore also resumes Atlas, and signing out first doesn't use it up. The
  entry removes itself after the restart, or at its next launch once the draft
  is abandoned. Before-desktop setup relaunches through its own shell.
- **Resuming.** **Continue updates** reruns preparation; an earlier scan never
  counts as lasting permission to install.
- **Stopping.** Closing the window offers to stop after the current operation
  and keeps the window open. The worker never kills a Windows servicing provider.

### Driver updates

Chosen before preparation. The default keeps an existing Atlas driver-blocking
policy; otherwise Windows Update is recommended.

| Choice | Effect |
| --- | --- |
| **Get drivers through Windows Update** | Removes the `DriverSearching\SearchOrderConfig` policy, restoring the ordinary search preference. |
| **Install drivers myself** | Filters driver updates out of preparation, the front door's pre-install readiness check and the pending-update check. Sets machine `DriverSearching\SearchOrderConfig` to 0, never searching Windows Update ([`DeviceSetup.admx`](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-devicesetup#driversearchplaces-searchorderconfiguration)). |

Both apply the paired AtlasDesktop policies in
`2. Drivers\Drivers from Windows Update`, shared by the app and the ISO. A normal
install applies the choice before the first update scan. Neither choice removes
drivers installed before Atlas opened. Inbox drivers bundled with Windows
servicing are outside the
[quality-update driver exclusion](https://learn.microsoft.com/en-us/windows/deployment/update/waas-configure-wufb#exclude-drivers-from-quality-updates).

## Troubleshooting

| Problem | What to do |
| --- | --- |
| Release information unavailable or unrecognised | The check stops with an explanation. Retry. |
| A network driver was rejected | Windows installation continues. See `%windir%\AtlasISO\setup.log` and PnPUtil's exit code in `network-drivers-result.json`. Install manually from `%windir%\AtlasISO\NetworkDrivers`. |
| Before-desktop cleanup failed | Explorer still opens, and `%LOCALAPPDATA%\Atlas-desktop-recovery.log` has the error. Run `%windir%\AtlasISO\Desktop.ps1 -RestoreDesktop`. The shell remains available for recovery at the next sign-in. |
| An ISO or USB job failed | Its logs, request and errors stay in its job directory under `%ProgramFiles%\Atlas Setup Recovery\Media`, which **Open log folder** shows. |
| The ISO has no network drivers | This PC's adapters use drivers that come with Windows, so there was nothing to add; the finished ISO's message says so. |

## How it works

### ISO build

Code: `src/services/iso.rs`, `resources/iso/Build-Iso.ps1` and
`Master-Iso.ps1`.

- **Inspection.** DISM reads every edition from the source, mounted read-only.
  Versions are checked against `windows-releases.json` in Atlas's
  compatibility scripts, shared with the app and direct installation. Unknown
  versions trigger a size- and time-limited refresh from Microsoft's release
  page. This checks eligibility, not the authenticity of modified media
  ([release policy](../../docs/windows-release-policy.md)).
- **Editions.** Exclusions match the destination edition check. Supported
  editions are exported, with DISM integrity checking, to a new WIM whose edition
  identities are verified.
- **Staging.** In a private, uniquely named directory beside the output. The app
  and notices, package, destination scripts and typed settings go in
  `sources\$OEM$\$$\AtlasISO`; network drivers, if any, go in its
  `NetworkDrivers` folder, with `network-drivers.json` as their source report.
  Atlas sits beside the Windows image, never inside it. The worker reports its
  stages in order (`ATLAS_STAGE:inspect`, `copy`, `add-atlas`,
  `network-drivers`, `master`, `verify`, `cleanup`), and the app's checklist
  follows them.
- **Mastering.** IMAPI2FS writes a UDF image with BIOS and UEFI boot entries for
  x64, or UEFI only for ARM64.
- **Verification.** The boot catalog is validated, and the remounted image's key
  files and network-driver files are hashed against the staged copies. The
  output's SHA-256 is recorded before it takes the new filename.
- **One build.** A global mutex allows one Atlas ISO operation at a time.

### Worker jobs

ISO and USB workers, requests and media scripts are staged under
`%ProgramFiles%\Atlas Setup Recovery\Media`. Only administrators and SYSTEM can
change it, so a program running as the user can't swap them before use. Workers
load PowerShell modules only from the inbox module root. Starting a job removes
jobs older than a day and beyond the newest 20, including earlier versions' jobs
(`prune_jobs` and `prune_legacy_jobs` in `src/services/iso.rs`).

### Before-desktop handoff

Code: `resources/iso/Setup.ps1`, `Desktop.ps1` and `Desktop-Policy.ps1`.

- **User context.** The app runs as the intended user after sign-in, so Windows
  and Store work does too. `Install-Atlas.ps1 -WindowsSetup`, a SYSTEM entry
  point, is refused: it can't verify that user's Store updates.
- **Shell.** A per-user [CustomShell](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-winlogon#customshell)
  policy, set by FirstLogonCommands after OOBE for the installing account only.
  No Windows binaries are replaced; the default profile and future users keep
  the Windows shell.
- **Supervisor.** `Desktop.ps1` verifies the account SID, starts the app
  elevated, then starts Explorer unelevated when the Atlas window appears or
  after 30 seconds. It also restores Explorer if Atlas closes, elevation is
  declined or startup fails. Only the app window is full-screen; native controls
  open above it.
- **Cleanup.** First logon registers a SYSTEM task,
  `AtlasOS ISO desktop cleanup <SID>`, that runs a fixed action from the
  protected `%windir%\AtlasISO`. Only administrators and SYSTEM
  can change it; the setup account can only read and run it
  ([task permissions](https://learn.microsoft.com/en-us/windows/win32/taskschd/security-contexts-for-running-tasks)).
  It validates the SID, removes only Atlas's exact shell command from that
  user's loaded hive and deletes itself, without changing the policy key's
  permissions.
- **Restarts.** The shell survives app-requested restarts, and the supervisor,
  not the usual Run entry, then opens the completion page. Preparation and
  installer records survive too. Normal Explorer recovery applies when the
  install restarts Explorer. The restart marker and the per-session mutex that
  prevents a second supervisor are commented in `Desktop.ps1`.

## Review and localization

Debug builds have read-only preview states of the ISO, USB and preparation
screens. `tools\Review-Iso.ps1 -State <state>` opens one in `target\debug` with
isolated settings, never builds media, and saves a screenshot and the
accessibility tree under `%TEMP%`. Parameters select the state, language, theme,
window size and a scroll offset; `-Desktop` adds the before-desktop bar.

| Screen | States |
| --- | --- |
| Home | `home` |
| Files | `files`, `files-checked`, `checking`, `not-elevated`, `failed`, `release-unknown`, `package-unsupported` |
| Windows setup | `windows`, `account-empty`, `account-invalid`, `network-drivers` |
| Your choices | `choices`, `choices-unsupported`, `before`, `before-desktop` |
| Review and Create | `review`, `review-before`, `progress`, `progress-network`, `build-failed`, `package-changed`, `cancelled`, `complete` |
| Preparation | `prepare-idle`, `prepare-busy`, `prepare-stopping`, `prepare-download`, `prepare-complete`, `prepare-resume`, `prepare-failed`, `prepare-failed-battery`, `prepare-unconfirmed`, `prepare-reboot`, `prepare-restart-persists`, `prepare-network`, `prepare-network-limited`, `prepare-previous-worker` |
| USB | `usb-select`, `usb-empty`, `usb-review`, `usb-progress`, `usb-failed`, `usb-failed-iso`, `usb-failed-unchanged`, `usb-scan-failed`, `usb-cancelled-unchanged`, `usb-complete`, `usb-eject-failed`, `usb-ejected` |

The catalog for every available language includes the ISO, USB and preparation
text. Completeness and formatting are checked automatically; native-speaker
review marks a translation verified ([Languages](i18n.md)).

## Validation and release criteria

Repository tests cover parts of media construction, update filtering, protocol
parsing, cancellation and recovery with temporary files and controlled providers.
They don't prove that media boots, that a physical disk can't be swapped between
identity checks, that Windows and Store servicing complete on a destination PC,
or that the Task Scheduler handoff works.

Before distributing a candidate, record the SHA-256 hashes of its app, Atlas
package and ISO, and validate those exact artifacts:

- Fresh 25H2 setup in each supported edition, including the native password
  change and removal of the bootstrap automatic logon.
- Each mode: restart and resume, declined elevation, normal exit and recovery to
  Explorer.
- Before-desktop cleanup on each edition: task registration and permissions,
  self-deletion, restart and failure recovery.
- Windows, Store and Store app preparation: offline failure, pending restart,
  provider error and retry, with both driver choices.
- Physical network-driver staging, including an offered driver download, and
  operation on the destination hardware.
- Physical USB: confirmation, system and source-disk protection, cancellation at
  each stage, unplug and replacement, file verification, eject veto and UEFI
  boot.
- Minimum and default window sizes, light, dark and contrast themes, long
  translations, pseudo-localization, keyboard navigation, text scaling and
  Narrator.

Keep raw logs, screenshots and disk images out of Git. Attach sanitized evidence
and artifact hashes to the release review
([release verification matrix](../../docs/reliability-verification-matrix.md)).

## Microsoft documentation

- [USB installation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/install-windows-from-a-usb-flash-drive),
  [split images](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/split-a-windows-image--wim--file-to-span-across-multiple-dvds)
  and [volume naming](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-volume)
- Answer files: [discovery](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview),
  [ProtectYourPC](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc),
  [FirstLogonCommands](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands)
  and the [AutoLogon count workaround](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount)
- Drivers: [PnPUtil](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax)
  and [ejecting a device](https://learn.microsoft.com/en-us/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_request_device_ejectw)
  (results, vetoes and privileges)
- Updates: the [Windows Update Agent API](https://learn.microsoft.com/en-us/windows/win32/wua_sdk/portal-client),
  [CopyFromCache](https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-copyfromcache)
  (packages are exported, not restored with CopyToCache) and
  [Store update search](https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.searchforallupdatesasync)
- [Connection profiles](https://learn.microsoft.com/en-us/uwp/api/windows.networking.connectivity.connectionprofile)
  (connectivity and cost, whatever the adapter type)

Driver choices follow the [Atlas installation guide](https://docs.atlasos.net/docs/install/playbook/),
the Driver Updates documentation and the AtlasDesktop driver-policy registry
files.
