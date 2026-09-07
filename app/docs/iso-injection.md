# Atlas ISO creation (Beta)

## Scope and sequence

Atlas 0.6 requires Windows 11 25H2 (build 26200). Fresh installs and ISO
creation no longer support 24H2. The app's PC checks and ISO edition filter
both read this requirement from `playbook.conf`. The declared Atlas upgrade
sources (0.4.1, 0.5.0 and 0.5.1) are unchanged; upgrading Atlas also requires
a supported Windows build.

ISO creation requires Atlas 0.6.0 or newer. There is no compatibility path
for 0.5 or 0.4.1. The normal app also prepares the destination PC before
applying Atlas: install recommended Windows updates, update Microsoft Store,
and finish updates for all installed Store apps. Third-party WinGet apps are
outside this scope.

Store updates depend on the destination user's registered apps. Consequently
this Beta stages Atlas in the ISO and applies it after Windows setup and
sign-in. It does **not** claim that Atlas is fully applied in install.wim.
The choices are:

- Choose Atlas settings after sign-in.
- Save Atlas settings in the ISO and use them in the destination app.
- Finish setup before the desktop, using the saved Atlas settings.

All use the normal preparation, Windows Security and install flow. Before-desktop
setup runs after the intended user's native password change and sign-in, with
Atlas presented full-screen before the normal desktop. Explorer's shell services
run behind it so native Settings, Windows Security and Store apps work on Pro.
It still requires elevation, connectivity and security prerequisites; it is not
a fully unattended installation or a kiosk restriction. Windows shortcuts remain
available, and other monitors may show the desktop.

### Before-desktop handoff

The legacy `Install-Atlas.ps1 -WindowsSetup` SYSTEM entry is rejected: it cannot
verify the intended user's Store updates. The supported before-desktop flow
uses the app after that user's sign-in.

Atlas uses Windows' per-user CustomShell policy instead of replacing Windows
binaries. FirstLogonCommands registers it only for the installing account, after
OOBE. The default profile and future users retain the Windows shell. The installing
user's shell supervisor verifies the account SID and starts the elevated app,
then starts Explorer unelevated once the Atlas window appears (or after a bounded
startup timeout). Only the app window is full-screen; native controls can open
above it.
Windows and Store operations therefore run in the intended user's context.
Saved choices skip the repeated options step, while update and security gates
remain enforced. The existing preparation and installer records survive reboots.

The supervisor ensures Explorer is running when Atlas closes, elevation is declined,
or startup fails. First logon registers a SYSTEM cleanup task with a fixed action in
the protected Windows/AtlasISO directory. Only administrators/SYSTEM can change it;
the setup account receives read/execute permission to request that one action.
Cleanup validates the protected account SID, removes only Atlas's exact shell command
from that loaded user's hive, and deletes the task. It never changes the policy key's
ACL. If cleanup fails, Explorer still opens and a diagnostic records the retry needed;
the shell remains available for recovery at the next sign-in.
A recent restart marker preserves the shell across an
app-requested restart. A session-local mutex prevents shell recovery from starting
another supervisor. This mode skips the ordinary completion Run entry, since
the supervisor opens the completion page after restart. Payload shell refresh
operations retain normal Explorer recovery.
The app offers Continue in Windows whenever no operation is running.

Microsoft documents first-logon timing in [FirstLogonCommands](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands), the [CustomShell policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-winlogon#customshell), and [task read/execute permissions](https://learn.microsoft.com/en-us/windows/win32/taskschd/security-contexts-for-running-tasks). Validate registration, permissions, self-deletion, restart and failure recovery on each supported Windows edition; fixture tests do not prove the actual Task Scheduler handoff.

## Media creation

1. Keep ISO state separate from the live installer. Reuse GPUI controls,
   theme tokens, accessible navigation, native file dialogs and Fluent.
2. Inspect every edition with DISM. Require supported Windows 11 x64 builds
   and a full version published in Microsoft's General Availability release table.
   App, direct installation and ISO checks share a reviewed release catalog.
   Unknown versions trigger a bounded official-source refresh; unavailable or
   unrecognized release information blocks the operation with a retry explanation.
   This verifies release eligibility, not the authenticity of modified media.
   Reject existing answer files and OEM payloads instead of merging unknown
   setup instructions. Mount source media read-only. Exclude Home and known LTSC
   editions using the destination edition gate; reject media with no supported
   editions. Mixed Microsoft media remains usable: export every supported index
   with DISM integrity checking into a new WIM, then verify the resulting identities.
   Show the included editions before building. Do not insert a product key or select
   an image index. Request the product-key and image-installation UI in Windows Setup,
   so users can select a licensed edition. Firmware Home keys and volume-license media
   require separate boot validation; these UI settings are not evidence of activation.
3. Copy media to a private unique staging directory. Add the portable app and its notices,
   selected archive, destination bootstrap and typed settings. Use IMAPI2FS
   for UDF mastering with BIOS and UEFI boot entries. Validate boot catalogs,
   remount and hash important files, calculate the full output digest, and
   publish to a new filename only after verification.
4. Create the chosen local administrator through supported unattended setup
   settings. Hide online-account screens. One bootstrap automatic logon
   disables further automatic logons, expires the initial empty password,
   registers the app for the next sign-in and signs out. The user's next
   sign-in goes through Windows' native password-change experience.
5. The destination app restores preselected Atlas options. The shared
   preparation worker uses Windows Update Agent and AppInstallManager.
   It verifies provider completion, handles pending restarts, rescans after
   updating Store itself and refuses to proceed on partial or unknown results.
6. Save the install draft before requesting a restart. Register RunOnce to
   reopen the Get ready step. Recheck updates after sign-in; a previous
   preparation scan never becomes a permanently cached permission to install.
7. Keep Atlas blocked until preparation succeeds. Existing security and
   installation checks still apply. Cooperatively stop between servicing
   operations; never kill a Windows servicing provider.

## Update behaviour

Choose Windows Update drivers or manual drivers before preparation. The default
respects an existing Atlas driver-blocking policy; otherwise Windows Update is
recommended. Both paths use the registry policies shipped in AtlasDesktop.
Manual mode also filters driver updates from the worker and readiness scan.
The ISO carries this choice and applies its policy during specialize, before
OOBE; normal installation applies it before the app starts an update scan.
This does not remove drivers Windows already installed before opening Atlas.

The worker checks the active Windows network profile before each provider pass.
Wi-Fi and Ethernet are supported. Offline, captive-portal, metered, roaming and
restricted connections stop preparation with a network-settings action. Missing
Wi-Fi hardware support still requires the user to install a network driver.

Optional previews and feature upgrades are excluded:
a feature upgrade may leave the builds supported by the selected playbook.
The existing pending-update check uses the same inclusion rules.

Windows Update runs search, download, installation and rescan passes. Store
updates use SearchForAllUpdatesAsync with automatic installation and application
restarts enabled. The preparation screen explains that Store apps will close and update.
Already active Store work is included. Ready-to-download items are restarted;
failed queue entries are cleared before retrying, following WinGet's recovery.
An empty initial scan alone does not prove updates finished. Missing Store
registration, errors, paused work, timeouts and repeated remaining updates
produce an actionable failed state with diagnostics.

The app never automatically restarts the PC for preparation. Restart and
continue is an explicit action. Closing during preparation offers to stop
after the current operation while keeping the window open.

## UI and localization

The flow is Files → Windows and Atlas preferences → Review → Create.
Preferences ask whether the ISO is for this PC or another PC. Only the first
choice exposes an optional network-driver backup. Users can copy installed
drivers or first check Windows Update for matching driver offers. Installed
packages remain as a fallback. This check downloads only; it never creates
a Windows Update installer or changes the host driver policy.

Manual mode also sets the machine `DriverSearching\SearchOrderConfig` policy
to 0, matching the Windows `DeviceSetup.admx` definition of never searching
Windows Update. Automatic mode removes that policy and restores the ordinary
search preference. Both the app and ISO use the shared registry pair. See Microsoft's
[device-driver source policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-devicesetup#driversearchplaces-searchorderconfiguration).
Inbox drivers bundled with Windows servicing remain outside the
[quality-update driver exclusion](https://learn.microsoft.com/en-us/windows/deployment/update/waas-configure-wufb#exclude-drivers-from-quality-updates).

Get-NetAdapter selects physical Ethernet/Wi-Fi adapters, and WMI matches their
device IDs to signed OEM INF packages. PnPUtil exports each package once.
Built-in Windows drivers and unrelated VPN/virtual-adapter packages are not
backed up. The update option matches the adapters' hardware/compatible IDs to
Windows Update's network-driver metadata. It uses an unmetered connection,
downloads at most 2 GB, copies the payload out of the cache, extracts cabinets
and requires INF/catalog files. It is not a manufacturer-wide latest-version
finder, and an offered driver may not support an older target Windows build.

Packages and their source report travel under Windows/AtlasISO/NetworkDrivers
and network-drivers.json. Every file is hashed against the mounted output ISO.
Specialize stages/installs matching packages with PnPUtil before OOBE, even in
manual-driver mode. A destination driver rejection is logged without aborting
Windows installation, and the packages remain available for manual recovery.
Wi-Fi credentials are not backed up. If no packages are exportable, the build
reports the problem and lets the user change this option; it never silently
claims a backup succeeded.
The local-account field supports Unicode, IME composition, selection,
clipboard operations and keyboard navigation. Reject invalid Windows account
names, reserved names, control characters and names over 20 UTF-16 units.
Write account names through the XML DOM and JSON, never through interpolated
PowerShell commands.

The Beta notice stays visible. Progress names actual stages; Store progress
reflects completed app updates. Errors retain selected inputs and provide
diagnostics. Check default and minimum window sizes, light/dark themes,
long translations and pseudo-localization.

All 15 shipped catalogs contain the ISO and preparation copy: en-GB, en-US,
de, es, fr, pt-BR, pl, ru, tr, id, ja, zh-Hans, zh-Hant, th and hi.
Catalog completeness and formatting are automated checks. Native-speaker
review remains the quality bar for marking translated languages verified.

## Create a Windows installation USB (Beta)

The completed-ISO screen offers **Create installation USB**. The first ISO screen
also offers an existing-ISO entry point. USB selection is explicit; refreshing
clears the selection. The review identifies the model, capacity, volumes and serial
and requires an acknowledgement before **Erase and create USB** becomes available.

`Write-Usb.ps1` uses Windows Storage cmdlets to create an active MBR/FAT32 partition
of up to 32 decimal GB. Extra capacity remains unallocated, disclosed before erasure.
The target is UEFI x64 Windows 11 25H2; legacy BIOS and other operating systems are
not supported by this Beta. The worker copies the ISO's signed UEFI boot files
without an additional bootloader. It prepares large WIMs using DISM's integrity-
checked split into `sources/install*.swm`. Large ESDs are exported with all editions
preserved before splitting. Other files exceeding FAT32's limit fail before erasure.
The source is locked against replacement and working space/capacity are checked first.

The writer refuses boot/system, internal, offline and read-only disks, missing
identifiers, and targets containing its ISO, app or working files. It checks number,
hardware path, serial, model, capacity and unique ID immediately before destructive
operations. Copying and verification recheck disk identity and volume identity to
reject unplugged/replaced devices or reused drive letters. File writes and verification
use the selected volume's GUID path, so drive-letter reassignment cannot redirect
the destination. See Microsoft's [volume naming contract](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-volume).
A global mutex prevents
concurrent Atlas writers. Cancellation waits through indivisible Storage/DISM calls
and interrupts file copying between chunks; partial media is never reported ready.
Every written file is compared with its prepared source using SHA-256. Completion
offers safe ejection via `CM_Request_Device_EjectW`, with a recoverable error if vetoed.

This follows Microsoft's [Windows USB installation guidance](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/install-windows-from-a-usb-flash-drive)
and [split-image guidance](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/split-a-windows-image--wim--file-to-span-across-multiple-dvds).
Rufus `2368e49`, `src/vhd.c:WimSplitFile` and `src/format.c` informed media
handling; no Rufus code was copied. MicrosoftDocs/sdk-api `5f2625b6`,
`sdk-api-src/content/cfgmgr32/nf-cfgmgr32-cm_request_device_ejectw.md` documents ejection
results, vetoes and privileges. The app includes all 15 translations and read-only
fixtures for selection, empty, confirmation, progress, failure and completion states.

## Reference sources

- pbatard/rufus, commit 2368e49, `src/wue.c`: OOBE privacy defaults
  (`ProtectYourPC=3`) and native local-account password-change sequencing.
  Rufus is GPL-3.0 licensed. The implementation uses the documented Windows
  settings, without copying Rufus's registry script or global password policy.
- [ProtectYourPC](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc):
  disable Express settings and hide the corresponding OOBE page. Atlas media
  applies this default automatically; existing Atlas options retain meaningful
  security and update choices in the app.
- AME Wizard Core: Ameliorated-LLC/trusted-uninstaller-cli, commit
  f325e9d. AmeliorationUtil.cs RunPlaybook and InjectOOBE plus WimWrapper
  provide source references. This implementation does not reuse its offline
  registry virtualization or replace OOBE executables.
- MicrosoftDocs/win32/Wua_Sdk: Windows Update Agent COM contracts.
- [PnPUtil export/add-driver commands](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax).
- [WUA CopyFromCache](https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdate-copyfromcache):
  the driver workflow exports package files, not a cache to restore using CopyToCache.
- [Atlas installation requirements](https://docs.atlasos.net/docs/getting-started/install/install-playbook/),
  Driver Updates, and the paired AtlasDesktop driver-policy registry files.
- [Windows connection profiles](https://learn.microsoft.com/en-us/uwp/api/windows.networking.connectivity.connectionprofile):
  connectivity and connection-cost checks independent of Wi-Fi or Ethernet.
- microsoft/winget-cli/src/AppInstallerCommonCore/MSStore.cpp:
  AppInstallManager updates and provider completion.
- [Windows Setup answer-file discovery](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview).
- [FirstLogonCommands](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands).
- [AutoLogon count workaround](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount).
- [Store update search](https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager.searchforallupdatesasync).
- Text-input mechanics adapted from the Apache-2.0 GPUI input example in the
  zed-industries/zed source. License: licenses/GPUI-input-APACHE-2.0.txt.

## Validation and release criteria

Repository tests cover parts of media construction, update filtering, protocol parsing,
cancellation and recovery using temporary files and controlled providers. They do not
prove that generated media boots, that a physical disk cannot be replaced between
identity checks, or that Windows and Store servicing complete on a destination PC.

Before distributing a candidate, record its app, playbook and ISO SHA-256 hashes and
validate the exact artifacts:

- Fresh Windows 11 25H2 setup in each supported edition, including native local-account
  password change and removal of bootstrap automatic logon.
- Interactive choices, saved choices and before-desktop setup; restart/resume,
  declined elevation, normal exit and recovery to Explorer.
- Windows, Microsoft Store and installed Store app preparation; offline failure,
  pending restart, provider error and retry. Check both driver choices.
- Physical network-driver staging, including an offered driver download and operation
  on the destination hardware.
- Physical USB confirmation, system/source-disk protection, cancellation during each
  stage, unplug/replacement, written-file verification, safe-eject veto and UEFI boot.
- Minimum/default window sizes, light/dark/contrast themes, long translations,
  keyboard navigation, text scaling and Narrator.

Keep raw logs, screenshots and disk images outside Git;
attach sanitized evidence and exact artifact hashes to a release review. See the
[release verification matrix](../../docs/reliability-verification-matrix.md).
