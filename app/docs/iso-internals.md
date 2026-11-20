# ISO internals

This page explains how Atlas Manager's ISO and USB workers build, verify and hand over Atlas media, and how before-desktop setup works on the new PC.
It's for contributors who change the media workers; [Creating an Atlas ISO](iso-creation.md) covers what users do.

## ISO build

The code is in `src/services/iso.rs`, `resources/iso/Build-Iso.ps1` and `resources/iso/Master-Iso.ps1`.

- **Inspection.** DISM reads every edition from the source, mounted read-only.
  The worker checks each version against `windows-releases.json` in the Atlas package's compatibility scripts, which the app and the front door share.
  An unknown version triggers a refresh from Microsoft's release page, limited in size and time.
  This checks eligibility, not the authenticity of modified media ([Windows release eligibility](../../docs/windows-release-policy.md)).
- **Editions.** The exclusions match the destination edition check.
  The worker exports the supported editions, with DISM integrity checking, to a new WIM, and verifies their edition identities.
  Atlas sets no product key or image index, so firmware Home keys and volume licence media need their own boot checks; these settings say nothing about activation.
- **Staging.** The worker stages in a private, uniquely named folder beside the output.
  The app and its notices, the package, the destination scripts and the typed settings go in `sources\$OEM$\$$\AtlasISO`.
  Network drivers, if any, go in its `NetworkDrivers` folder, with `network-drivers.json` as their source report.
  Atlas sits beside the Windows image, never inside it.
- **Stages.** The worker reports its stages in order (`ATLAS_STAGE:inspect`, `copy`, `add-atlas`, `network-drivers`, `master`, `verify`, `cleanup`), and the app's checklist follows them.
- **Mastering.** IMAPI2FS writes a UDF image with BIOS and UEFI boot entries for x64, or UEFI only for ARM64.
- **Verification.** The worker validates the boot catalog, then hashes the remounted image's key files and network-driver files against the staged copies.
  It records the output's SHA-256 before the output takes its new file name.
- **One build.** A global mutex allows one Atlas ISO operation at a time.
- **Free space.** The output volume needs about 5 × the source ISO, plus 2 × the unpacked package, plus 4 GiB.

The local account name reaches the answer file through the XML DOM and JSON, never through PowerShell commands.

### Network drivers

The code is in `resources/iso/Network-Drivers.ps1`.

- Downloads and the packaged total are each capped at 2 GiB, and every package needs INF and catalog files.
- **Check Windows Update first** downloads Windows Update's offers for the adapters' hardware and compatible IDs.
- The build exports the drivers last, after the answer file.
- When the adapters use only drivers that come with Windows, the build adds no `NetworkDrivers` folder and prints `ATLAS_NOTE:network-drivers-inbox`, which the app turns into the finished ISO's message.
- In Windows setup's `specialize` pass, which runs before the out-of-box experience (OOBE), PnPUtil stages the packages and installs those that match, even when the user chose **Install drivers myself**.

## Worker jobs

The ISO and USB workers, their requests and the media scripts are staged under `%ProgramFiles%\Atlas Setup Recovery\Media`.
Only administrators and SYSTEM can change that folder, so a program running as the user can't swap them before use.
Workers load PowerShell modules only from the inbox module root.

Starting a job removes jobs older than a day and beyond the newest 20, including jobs that earlier versions left (`prune_jobs` and `prune_legacy_jobs` in `src/services/iso.rs`).

## USB writing

The code is in `resources/iso/Write-Usb.ps1`.

| Rule | What the worker does |
| --- | --- |
| Refused disks | Refuses boot, system, offline and read-only disks, disks without identifiers, and disks that hold the worker's ISO, app or working files. |
| Before erasing | Locks the source against replacement and checks space and capacity, with typed failures so the app can say what to change and that the drive wasn't touched. |
| Identity | Checks disk number, hardware path, serial, model, capacity and unique ID just before each destructive operation. |
| Copying | Rechecks disk and volume identity, rejecting unplugged or replaced devices and reused drive letters. |
| Volume paths | Writes and verifies through the volume GUID path, which a reassigned drive letter can't redirect. |
| One writer | Blocks concurrent Atlas USB writes with a global mutex. |
| Cancellation | Waits for Storage and DISM calls that can't be interrupted, and stops copying between chunks. |
| Partial media | Never reports partial media as ready, and initialises a RAW drive, such as one a cancelled write left, without clearing it. |
| Verification | Reads every file back unbuffered, bypassing the Windows file cache, and compares it by SHA-256; file-system metadata still goes through the cache. |

- The worker splits a large `install.wim` with DISM's integrity-checked split into `sources\install*.swm` parts of up to 3,800 MiB, which stay under FAT32's 4 GiB file limit.
- A large `install.esd` is first exported, with every edition, to a WIM.
- The partition is at most 32 GB (decimal), because Windows formats FAT32 only up to that size.
- Ejecting uses `CM_Request_Device_EjectW`, and a veto from Windows gives a recoverable error.

## Before-desktop handoff

The code is in `resources/iso/Setup.ps1`, `resources/iso/Desktop.ps1` and `resources/iso/Desktop-Policy.ps1`.

- **User context.** The app runs as the intended user after sign-in, so Windows and Store work does too.
  The front door refuses `Install-Atlas.ps1 -WindowsSetup`, an entry point that runs as SYSTEM, because it can't verify that user's Store updates.
- **Shell.** A per-user [`CustomShell` policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-admx-winlogon#customshell), set by `FirstLogonCommands` after OOBE, applies to the installing account only.
  No Windows binaries are replaced, and the default profile and future users keep the Windows shell.
- **Supervisor.** `Desktop.ps1` verifies the account SID and starts the app elevated.
  It then starts Explorer unelevated when the Atlas window appears, or after 30 seconds.
  It also restores Explorer if Atlas closes, elevation is declined or startup fails.
  Only the app window is full-screen, and native controls open above it.
- **Cleanup.** First sign-in registers a SYSTEM task, `AtlasOS ISO desktop cleanup <SID>`, that runs a fixed action from the protected `%windir%\AtlasISO`.
  Only administrators and SYSTEM can change the task, and the setup account can only read and run it ([task security contexts](https://learn.microsoft.com/windows/win32/taskschd/security-contexts-for-running-tasks)).
  The task validates the SID, removes only Atlas's exact shell command from that user's loaded hive and deletes itself, without changing the policy key's permissions.
- **Restarts.** The shell survives restarts the app asks for, and the supervisor, not the usual Run entry, then opens the completion page.
  Preparation and installer records survive too, and normal Explorer recovery applies when the install restarts Explorer.
  Comments in `Desktop.ps1` explain the restart marker and the per-session mutex that prevents a second supervisor.

## Tests and release checks

Repository tests cover parts of media construction, update filtering, protocol parsing, cancellation and recovery, with temporary files and controlled providers.
They don't show that media boots, that a physical disk can't be swapped between identity checks, that Windows and Store servicing complete on a new PC, or that the Task Scheduler handoff works.

The [release verification matrix](../../docs/release-verification-matrix.md) lists the ISO, USB and network-driver evidence each release needs, on each supported Windows release.

## Microsoft documentation

- [Installing Windows from a USB flash drive](https://learn.microsoft.com/windows-hardware/manufacture/desktop/install-windows-from-a-usb-flash-drive), [splitting a Windows image](https://learn.microsoft.com/windows-hardware/manufacture/desktop/split-a-windows-image--wim--file-to-span-across-multiple-dvds) and [naming a volume](https://learn.microsoft.com/windows/win32/fileio/naming-a-volume).
- Answer files: [how Windows setup finds them](https://learn.microsoft.com/windows-hardware/manufacture/desktop/windows-setup-automation-overview), [`ProtectYourPC`](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc), [`FirstLogonCommands`](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands) and the [`AutoLogon` `LogonCount` workaround](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount).
- Drivers: [PnPUtil command syntax](https://learn.microsoft.com/windows-hardware/drivers/devtest/pnputil-command-syntax) and [`CM_Request_Device_EjectW`](https://learn.microsoft.com/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_request_device_ejectw), for its results, vetoes and privileges.
- Updates: the [Windows Update Agent API](https://learn.microsoft.com/windows/win32/wua_sdk/portal-client), [`IUpdate::CopyFromCache`](https://learn.microsoft.com/windows/win32/api/wuapi/nf-wuapi-iupdate-copyfromcache) (the worker exports packages, and doesn't restore them with `CopyToCache`) and [`AppInstallManager.SearchForAllUpdatesAsync`](https://learn.microsoft.com/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.searchforallupdatesasync).
- [`ConnectionProfile`](https://learn.microsoft.com/uwp/api/windows.networking.connectivity.connectionprofile), for connectivity and cost whatever the adapter type.
