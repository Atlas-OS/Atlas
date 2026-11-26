# ISO internals

This page explains how Atlas Manager's ISO and USB workers build, verify and hand over Atlas media, and how before-desktop setup works on the new PC.
It's for contributors who change the media workers; [Creating an Atlas ISO](iso-creation.md) covers what users do.

## ISO build

The code is in `src/services/iso.rs`, `resources/iso/Build-Iso.ps1` and `resources/iso/Master-Iso.ps1`.

- **Windows download.** On the Windows step, users can browse for an existing ISO or download one. Manager requests the language list and a signed ISO link from the website's `/api/ms-iso` endpoints and downloads the file directly from Microsoft into the Downloads known folder, under a name no file has yet. It picks the language that matches the first Windows display language (`language_for` in `src/pages/iso/download.rs`), and the target PC's architecture. A cancelled or incomplete transfer leaves the destination untouched.
- **Checks before Create.** The app reads the output's volume as the worker does (`destination` in `src/services/iso.rs`, which a test keeps in step with `Assert-Output`): a local NTFS or ReFS volume with the free space below. The worker asserts the output only for a build, so checking the files never fails on where the ISO will go.
- **Mounting.** The ISO and USB workers share `resources/iso/Iso-Mount.ps1`, and read a mounted ISO only as exactly one volume with a drive letter.
  Windows can give the letter late, or none where automatic mounting is off, so the worker reads the image's volume again every half second for about 30 seconds.
  After about 10 seconds, an image the worker mounted itself gets the highest free drive letter, which the worker takes back before it ejects the image. An image that was already mounted is used as it is.
  Without such a volume, the worker stops with `iso-mount`, and the log lists each volume's filesystem, drive letter and status.
- **Mount failures.** Before it mounts an image, the worker stops with `iso-mount-drivers` if the `vdrvroot` or `cdrom` driver is disabled (`Start` 4), because Windows then mounts no ISO, or waits minutes for a drive that never starts.
  When Windows refuses to read or mount the source, a file stored compressed, encrypted or sparse stops it with `iso-mount-file`, which asks for a copy in an ordinary folder; the worker changes nothing about the user's file. Any other refusal is `iso-mount`.
  The storage cmdlets run as jobs on one local CIM session with a 120-second operation timeout, and the worker waits no longer than that for each, because Windows doesn't apply the timeout to every call over a local session. A call that doesn't finish stops the worker with `iso-mount-timeout`.
- **Inspection.** DISM reads every edition from the source, mounted read-only.
  The worker checks each version against `windows-releases.json` in the Atlas package's compatibility scripts, which the app and the front door share.
  An unknown version triggers a refresh from Microsoft's release page, limited in size and time.
  This checks eligibility, not the authenticity of modified media ([Windows release eligibility](../../docs/windows-release-policy.md)).
- **Editions.** The exclusions match the destination edition check.
  The worker exports the supported editions, with DISM integrity checking, to a new WIM, and verifies their edition identities.
  On Arm64 Windows, where Atlas Manager and its workers run as x64, the DISM PowerShell module can lack native code for the process (0x8007000B). The worker then deletes the partial WIM and exports the same editions with Windows' own `dism.exe`, with maximum compression and the integrity check, before the same verification.
  Atlas sets no product key or image index, so firmware Home keys and volume licence media need their own boot checks; these settings say nothing about activation.
  For single-edition Enterprise Evaluation media, Setup reads Microsoft's edition configuration in WinPE. Atlas delivers its answer file to the installed Windows Panther folder for the later setup passes.
- **Staging.** The worker stages in a private, uniquely named folder beside the output.
  The app and its notices, the package, the destination scripts and the typed settings go in `sources\$OEM$\$$\AtlasISO`.
  Network drivers, if any, go in its `NetworkDrivers` folder, with `network-drivers.json` as their source report.
  Atlas sits beside the Windows image, never inside it.
- **Stages.** The worker reports its stages in order (`ATLAS_STAGE:inspect`, `copy`, `add-atlas`, `network-drivers`, `master`, `verify`, `cleanup`), and the app's checklist follows them.
  While `Master-Iso.ps1` writes the image, it also reports the bytes written (`ATLAS_PROGRESS:{"done":…,"total":…}`), every 64 MiB and at the end. The page weights the stages by their usual share of a build, and moves the bar within the writing stage by those bytes, so the bar never goes back.
- **Mastering.** IMAPI2FS writes a UDF image with BIOS and UEFI boot entries for x64, or UEFI only for ARM64.
- **Verification.** The worker validates the boot catalog, then hashes the remounted image's key files and network-driver files against the staged copies.
  It records the output's SHA-256 before the output takes its new file name.
- **One build.** A global mutex allows one Atlas ISO operation at a time.
- **Free space.** The output volume needs about 5 × the source ISO, plus 2 × the unpacked package, plus 4 GiB.

The local account name reaches the answer file through the XML DOM and JSON, never through PowerShell commands.

### Driver policy

The `windowsPE` answer disables Setup Dynamic Update on media that loads it. Enterprise Evaluation uses Microsoft's default with Dynamic Update disabled so Setup can read its edition configuration. During `specialize`, Setup imports the manual driver policy for every ISO. The `drivers` setting in `setup.json` holds the choice Atlas Manager applies when preparing Windows, or `null` to ask after sign-in.

### Network drivers

The code is in `resources/iso/Network-Drivers.ps1`.

- Downloads and the packaged total are each capped at 2 GiB, and every package needs INF and catalog files.
- The app always asks for Windows Update's offers (`updateNetworkDrivers`) with the installed drivers. The worker downloads the offers for the adapters' hardware and compatible IDs on an unmetered connection; a metered, limited or missing connection, or a search or download that fails, leaves the installed packages alone on the ISO and is written to `network-drivers.log`. Cancellation still stops the build.
- The build exports the drivers last, after the answer file.
- When the adapters use only drivers that come with Windows, the build adds no `NetworkDrivers` folder and prints `ATLAS_NOTE:network-drivers-inbox`, which the app turns into the finished ISO's message.
- In Windows setup's `specialize` pass, which runs before the out-of-box experience (OOBE), PnPUtil stages the packages and installs those that match, even when the user chose **Install drivers myself**.

## Worker jobs

The ISO and USB workers, their requests and the media scripts are staged under `%ProgramFiles%\Atlas Setup Recovery\Media`.
Only administrators and SYSTEM can change that folder, so a program running as the user can't swap them before use.
Workers load PowerShell modules only from the inbox module root.

Starting a job removes jobs older than a day and beyond the newest 20, including jobs that earlier versions left (`prune_jobs` and `prune_legacy_jobs` in `src/services/iso.rs`).

## USB writing

The code is in `resources/iso/Write-Usb.ps1`, with the app's side in `src/services/usb.rs` and `src/pages/usb.rs`.
The worker has four operations: **List**, **Check**, **Write** and **Eject**.

| Rule | What the worker does |
| --- | --- |
| Listing | Lists every USB disk that passes the rules below except the smallest size, and marks those under 8 GiB as too small, so the page can show why they can't be used. |
| Refused disks | Refuses boot, system, offline and read-only disks, disks without identifiers, and disks that hold the worker's ISO, app or working files. |
| Checking | Reads the source ISO before a drive is chosen: the same media, path and working-space rules a write applies, and the bytes a write copies. It changes nothing. |
| Before erasing | Locks the source against replacement and checks the source, space and capacity again, with typed failures so the app can say what to change and that the drive wasn't touched. |
| Identity | Checks disk number, hardware path, serial, model, capacity and unique ID just before each destructive operation. |
| Copying | Rechecks disk and volume identity, rejecting unplugged or replaced devices and reused drive letters. |
| Volume paths | Writes and verifies through the volume GUID path, which a reassigned drive letter can't redirect. |
| One at a time | Runs writes, ejects and checks one at a time with a global mutex, as a check mounts the ISO a write reads. |
| Cancellation | Waits for Storage and DISM calls that can't be interrupted, and stops copying between chunks. |
| Partial media | Never reports partial media as ready, and initialises a RAW drive, such as one a cancelled write left, without clearing it. |
| Verification | Reads every file back unbuffered, bypassing the Windows file cache, and compares it by SHA-256; file-system metadata still goes through the cache. |
| Ejecting | A write ejects the drive once it's verified. A drive Windows won't let go is still ready, so the result reports it rather than the write failing. |

- A check that finds the mutex taken reports `busy` without reading the ISO, and the page checks again a few seconds later; a write or eject that finds it taken stops before changing anything.
  Lists change nothing, so they run alongside any of them.
- The worker splits a large `install.wim` with DISM's integrity-checked split into `sources\install*.swm` parts of up to 3,800 MiB, which stay under FAT32's 4 GiB file limit.
- A large `install.esd` is first exported, with every edition, to a WIM. That WIM comes out larger than the ESD, so a check's byte count is a lower bound for such an ISO, and the write's own capacity check before erasing decides.
- The partition is at most 32 GB (decimal), because Windows formats FAT32 only up to that size. The page applies the worker's partition rule to the check's byte count to mark drives too small for the ISO; a test keeps the two in step.
- Ejecting uses `CM_Request_Device_EjectW`. Windows refuses while a file on the drive is open, often briefly, such as a scan of the files just written, so the worker tries five times, two seconds apart.
- Progress is reported per stage, in bytes where there are any: hashing the source while preparing, copying, and verifying. The page weights the stages by their usual share of the time, so one bar runs once from start to finish and never goes back.

The page follows drives coming and going without a worker: every two seconds while it's on screen, it compares the disks Plug and Play lists for the disk driver (`HKLM\SYSTEM\CurrentControlSet\Services\disk\Enum`) and the drive letters in use, and runs **List** when they change.
It doesn't list while a write runs, so the drive picked can't change under it. After a `drive-changed` failure, it lists again and picks the drive with the same serial number, model and size.
Generic flash drives can share all three, so that match only picks a drive: the user's go-ahead to erase it carries over only while every part of the identity the worker checks is unchanged (`Drive::same_identity`), and otherwise **Create USB drive** asks again.

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
