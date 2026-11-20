# Creating an Atlas ISO (Beta)

Atlas Manager builds a Windows 11 installation ISO that applies Atlas after Windows setup, and writes that ISO, or an existing one, to a USB drive.
This page is for people who create Atlas media; [ISO internals](iso-internals.md) explains how the workers build and check it.

> [!IMPORTANT]
> Create media with the release executable, not a development build.
> The ISO carries a copy of the running executable, and the release build's static C runtime means the new PC needs no Visual C++ runtime.

## Requirements

| Item | Requirement |
| --- | --- |
| Windows release | A [supported Windows 11 release](../../docs/windows-release-policy.md#supported-releases), for the source ISO and for every PC Atlas installs on. |
| Source ISO | Unmodified Windows 11 client media, all x64 or all ARM64, whose full version Microsoft lists as generally available. |
| Editions | At least one edition besides Home and the known LTSC editions. |
| Atlas package | Atlas 0.6.0 or later, as an `.apbx` file. |
| Administrator access | Without it, the page offers only **Relaunch as administrator**. |
| Free space | A new file on a local NTFS or ReFS volume with about 5 × the source ISO, plus 2 × the unpacked package, plus 4 GiB free. |
| Account name | A name for the local account that Windows setup creates. |
| USB drive | A USB disk from 8 GiB to 2 TiB. |

- Atlas refuses media that has its own answer file or a `$OEM$` folder, rather than merge it with unknown setup instructions.
- Saving Atlas choices in the ISO needs a package that declares ISO setup support in `Executables\AtlasModules\Scripts\Install\iso-setup.json`.
- The PC checks, the ISO edition filter and the USB writer all read the supported builds from `SupportedBuilds` in `playbook.conf`.

Updating an installed Atlas also needs a supported Windows release, and Atlas Manager moves Windows to one first where it can ([Moving Windows to a newer release](../../docs/windows-transition.md)).
Where it can't, it points to this page, with a reminder to back up first.
That happens on a Windows version with no update path, on hardware below the Windows 11 requirements, and on a PC that Windows Update isn't offering the new release to yet.

## Create an ISO

Choose **Create an Atlas ISO** on Home.
The flow has four steps, **Files**, **Windows setup**, **Your choices** and **Review**, followed by **Create**.
Its title carries a **Beta** badge, and **Files** shows the full Beta notice.
The flow is independent of the install flow and its PC checks.

1. **Files.** Choose the Windows ISO, the Atlas package and where to save the new ISO, then choose **Check files**.
   **Download Windows 11 from Microsoft** opens Microsoft's download page.
   Until you choose a name, Atlas suggests one beside the source ISO that no file has yet: `Atlas-Windows.iso`, then `Atlas-Windows (2).iso` and so on.
   After a successful check, the files card reads **Ready** and **Continue** replaces **Check files**.
   Choosing another file clears the check, and checking the same package again keeps the saved choices.
2. **Windows setup.** Set the local account, driver updates, the target PC and network drivers.
   An empty account name holds **Continue** with a hint, and an invalid one is marked on the field.
3. **Your choices.** Choose the mode and, when choices are saved in the ISO, the Atlas options.
4. **Review.** Check one card per earlier step, each with a **Change** link, and the editions the ISO includes.
   Atlas sets no product key or image index, so Windows setup asks, and you choose an edition you're licensed for.
5. **Create.** A checklist shows the build's stages: checking the source, copying Windows files, adding Atlas, preparing network drivers (only when the ISO includes them), writing the ISO, checking it and finishing up.

- **Back** and **Continue** keep every value, and the stepper jumps to any step already reached once every step before it is complete.
- A failure or cancellation shows a bar with **Open log folder**, then the diagnostics, and a failed build marks the stage it stopped at.
  Your inputs stay.
- A result belongs to its step, and clears when you leave it.
- If the Atlas package changed after the check, **Files** asks you to choose **Check files** again.

### Modes

Atlas is applied after Windows setup and sign-in, not inside `install.wim`, because Store updates depend on the new user's registered apps.
The ISO keeps its Windows editions unchanged, and Atlas adds its own files and an answer file beside them.
Every mode then runs the normal preparation, Windows Security and install steps, checks included, so the new PC needs internet access.

| Mode | Atlas choices | When Atlas Manager opens |
| --- | --- | --- |
| **Make Atlas choices after sign-in** | Made on the new PC | On the desktop, after sign-in |
| **Make Atlas choices now** | Saved in the ISO and preselected | On the desktop, after sign-in |
| **Finish setup before the desktop** | Saved in the ISO; the **Your choices** step is skipped | Full-screen after sign-in, before the desktop |

Without `iso-setup.json` in the package, only the first mode is available.

**Finish setup before the desktop** is neither unattended nor a kiosk lock.

- It needs elevation, a network connection and the security prerequisites.
- After the intended user signs in, Atlas Manager runs full-screen until updates and the install finish.
- Explorer runs behind the app, so Settings, Windows Security and Store apps work on Pro.
  Windows shortcuts work, and other monitors may show the desktop.
- **Continue in Windows** works whenever no update, install, media job or restart countdown is running.

### Local account

The answer file creates this local administrator account.
Windows asks for its password at the first sign-in, and the ISO skips Windows setup's licence, Microsoft account and privacy screens.

A name can't:

- be a built-in name, such as Administrator or Guest;
- contain control characters or any of `" / \ [ ] : ; | = , + * ? < > @`;
- start or end with a space, or end with a full stop;
- be longer than 20 UTF-16 units.

The field supports Unicode, IME composition, selection, the clipboard and keyboard navigation.

### Network drivers

**Windows setup** asks which PC the ISO is for.
With **This PC** as the target, **Include this PC's network drivers** adds the signed OEM driver packages of the physical Ethernet and Wi-Fi adapters, so Windows can go online right after it's reinstalled.
Built-in Windows drivers, VPN and virtual adapters, and Wi-Fi credentials aren't copied.

- **Use installed drivers** exports the installed packages.
- **Check Windows Update first** also downloads the drivers Windows Update offers for the adapters, and keeps the installed packages as a fallback.
  It needs an unmetered connection, and never installs updates or changes this PC's driver policy.
  It isn't a search for the latest driver, and an offered driver may not support an older target build.

When the adapters use only drivers that come with Windows, and Windows Update offers none, there's nothing to back up, and the finished ISO's message says so.
A package that fails to export stops the build, so you can change the option.
Atlas never claims a backup that didn't happen.

### Driver updates

The driver-update choice in **Windows setup** works as it does in Get ready ([driver updates](install-flow.md#driver-updates)).
The new PC applies it during Windows setup, before its first update scan.

## Create a Windows installation USB (Beta)

**Create installation USB** is on the completed-ISO screen, and on the first ISO screen for an existing ISO.

> [!CAUTION]
> Atlas erases the USB drive you choose.

1. Choose the drive yourself; refreshing the list clears the choice.
   The list shows each drive's model, capacity and volumes.
2. Check the review, which adds the drive's serial number.
   **Erase and create USB** stays unavailable until you acknowledge the erase.
3. When writing finishes, eject the drive from the app, which leaves **Done**.
   If Windows refuses the eject, the app says so and you can try again.

- **Back**, the title's back arrow and Escape go from the review to the drive list, then out of the panel.
  The arrow is unavailable while a job runs.
- A failure offers **Open log folder** and the diagnostics.

The result is UEFI media for Windows 11 x64 or ARM64 on a supported build.
This Beta doesn't support legacy BIOS boot or other operating systems.

- The drive gets one active MBR FAT32 partition of up to 32 GB (decimal), and the rest stays unallocated, as the app says before erasing.
- The media uses the ISO's signed UEFI boot files, and Atlas adds no bootloader.
- A large `install.wim` is split into `sources\install*.swm` parts, and a large `install.esd` is first exported to a WIM with every edition.
  Any other file over FAT32's 4 GiB limit fails before anything is erased.

Atlas refuses boot, system, offline and read-only disks, disks without identifiers, and any disk that holds the ISO, the app or their working files.
It checks the drive's identity again before erasing and while writing, and reads every file back to verify it ([USB writing](iso-internals.md#usb-writing)).

## On the new PC

1. **Windows setup** copies the Atlas files to `%windir%\AtlasISO`.
2. In the `specialize` pass, which runs before the out-of-box experience (OOBE), setup applies the driver-update choice and installs the backed-up network drivers.
3. During OOBE, Windows' first-run setup screens, the answer file creates the account through supported unattended settings and hides the licence and online-account screens.
   It also sets `ProtectYourPC=3`, which turns Express settings off and hides them, because Atlas's options hold the real security and update choices.
   The ISO's **Windows setup** step says so under the account name.
4. One automatic sign-in turns off further automatic sign-ins, expires the empty password, registers Atlas Manager for the next sign-in and signs out.
5. At your sign-in, Windows asks for a new password, then Atlas Manager opens and runs [the install flow](install-flow.md).

## Troubleshooting

| Problem | What to do |
| --- | --- |
| Release information is unavailable or unrecognised | Check the files again; the check stops and explains why. |
| The ISO's Windows build isn't in Microsoft's list of public releases | Use an ISO from Microsoft, or check the files again once Microsoft lists the build; Release Preview and other preview builds aren't supported. |
| A network driver was rejected | Install it from `%windir%\AtlasISO\NetworkDrivers` once Windows is running ([details](#a-network-driver-was-rejected)). |
| Before-desktop cleanup failed | Run `%windir%\AtlasISO\Desktop.ps1 -RestoreDesktop` ([details](#before-desktop-cleanup-failed)). |
| An ISO or USB job failed | Choose **Open log folder** to see its logs, request and errors. |
| The ISO has no network drivers | Nothing to do: this PC's adapters use drivers that come with Windows, and the finished ISO's message says so. |

### A network driver was rejected

Windows installation continues without it.
`%windir%\AtlasISO\setup.log` records what happened, and `network-drivers-result.json` holds PnPUtil's exit code.

### Before-desktop cleanup failed

Explorer still opens, and `%LOCALAPPDATA%\Atlas-desktop-recovery.log` has the error.
After you run `Desktop.ps1 -RestoreDesktop`, the shell stays available for recovery at the next sign-in.

### Where job logs are

Each ISO or USB job keeps its logs, request and errors in its own folder under `%ProgramFiles%\Atlas Setup Recovery\Media`, which **Open log folder** shows.
