# Creating an Atlas ISO

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
| Atlas package | Atlas 0.6.0 or later, as an `.atlaspkg` file. |
| Administrator access | Windows asks for it when the page opens. Until it's given, the page shows **Relaunch as administrator** above the first step. |
| Free space | A new file on a local NTFS or ReFS volume with about 5 × the source ISO, plus 2 × the unpacked package, plus 4 GiB free. The **Create** step shows both figures. |
| Account name | A name for the local account that Windows setup creates. |
| USB drive | A USB disk from 8 GiB to 2 TiB: one sold as 16 GB or more. |

- Atlas refuses media that has its own answer file or a `$OEM$` folder, rather than merge it with unknown setup instructions.
- Saving Atlas choices in the ISO needs a package that declares ISO setup support in `Executables\AtlasModules\Scripts\Install\iso-setup.json`.
- The PC checks, the ISO edition filter and the USB writer all read the supported builds from `supportedBuilds` in the package's `atlas.json`.

Updating an installed Atlas also needs a supported Windows release, and Atlas Manager moves Windows to one first where it can ([Moving Windows to a newer release](../../docs/windows-transition.md)).
Where it can't, it points to this page, with a reminder to back up first.
That happens on a Windows version with no update path, on hardware below the Windows 11 requirements, and on a PC that Windows Update isn't offering the new release to yet.

## Create an ISO

Choose **Create an Atlas ISO** on Home's **Reinstall Windows with Atlas** card to start.
Home recommends it where Windows on the PC has been in use, and where only reinstalling Windows gets the PC to the Atlas package.
The flow has three steps, **Windows**, **Setup** and **Create**, and is independent of the install flow and its PC checks.
Without administrator permission, Windows asks for it as the page opens, and Atlas relaunches on the page.

1. **Windows.** Answer which PC the ISO is for, **This PC** (the default) or **Another PC**, then get Windows and the Atlas package.
   - **Download from Microsoft** starts at once and saves to your Downloads folder, under a name no file has yet. The caption under it names what you get, for example "Windows 11 · English International · x64": the language Windows shows on this PC, as Microsoft names it, and this PC's architecture. **Change** opens both choices.
   - **Choose an ISO file** uses one you have. Once a file is chosen, its **Change** opens a menu with both ways.
   - Atlas fetches the latest Atlas package by itself. **Change** beside it opens another package.
   - Once both are known, Atlas checks them by itself, and **Continue** becomes available when the check passes. An ISO for another kind of processor than this PC's can only be for another PC: **This PC** is unavailable, with the reason under it, and **Another PC** stays chosen.
   - While a download or the check runs, **Change** is hidden rather than unavailable.
   - A check that fails names the problem, and its bar offers the fix: **Download from Microsoft** or **Choose an ISO file** for media Atlas can't use, **Choose another package**, or **Try again**.
     A Windows ISO chosen as the Atlas package is named as one, with **Choose another package**, and the bar says to choose it as the Windows ISO instead.
   - Without the latest Atlas package, the package card says why in the error colour, with **Try again** and **Open package file**.
   - A package that needs a newer Atlas Manager shows one bar with **Download Atlas Manager**, and no **Continue**.
2. **Setup.** The Windows the ISO installs, and how Atlas is set up from it.
   - **Windows edition**: for This PC, this PC's edition when the ISO has it; otherwise Windows Setup asks. With several editions, **Change** opens the list of them, with **Windows Setup asks** first. You can read the licence terms from the ISO and accept them here, so Windows Setup doesn't ask.
   - **Local account name**: for This PC, your user name. An empty name holds **Continue** with a hint, and an invalid one is marked on the field.
   - **Drivers**: for This PC, **Include this PC's Wi-Fi and Ethernet drivers** ([network drivers](#network-drivers)), then **How should drivers be installed?**, as **Get ready** asks it, with **Choose after sign-in** as a third answer ([driver updates](#driver-updates)).
   - **When do you want to make your Atlas choices?**: [the mode](#modes). **Now** shows the Atlas package's questions under it, as **Your choices** asks them, with the line that says which choices the Atlas folder can change later, and the optional extras folded.
3. **Create.** Where the new ISO goes, with **Change**, and the space the build needs against the space free, such as "Needs 37.8 GB · 118.0 GB free on C:". Then one card per earlier step, each with **Change**.
   A drive without the space offers **Open Storage settings**, and Atlas reads it again every few seconds, so **Create ISO** becomes available once space is freed.
   Atlas suggests a name beside the Windows ISO that no file has yet: `Atlas-Windows.iso`, then `Atlas-Windows (2).iso` and so on.
   Atlas sets no product key or image index. If Windows Setup asks, choose an edition you're licensed for. Microsoft's single-edition Enterprise Evaluation ISO uses its own evaluation channel.
   **Create ISO** shows one progress bar, with its percentage, and the build's stages: reading the Windows ISO, copying Windows files, adding Atlas, preparing network drivers (only when the ISO includes them), writing the ISO, checking it and finishing up. While the ISO is written, the bar follows the bytes written. **Cancel creation** turns the heading to "Cancelling…" until the build stops at a safe point.

Before the build starts, Atlas reads the destination again: a folder that isn't on a local NTFS or ReFS volume, or that lacks the space, holds **Create ISO** with the reason under the new ISO. A file that took the chosen name in the meantime moves the new ISO to the next free name, such as `Atlas-Windows (2).iso`. An Atlas package that changed since the check is checked again by itself, and the build carries on while the choices still fit it.

- **Back** and **Continue** keep every value, and the stepper jumps to any step already reached once every step before it is complete.
  A step change moves focus to the current step in the stepper, which names it.
- A failed build names the problem, offers **Try again**, marks the stage it stopped at and, when nothing on the page fixes it, shows **Send a report**, **Export diagnostics** and **Open log folder**.
  Your inputs stay.
- A cancelled build says your original ISO wasn't changed. The worker removes its temporary files.
- A result belongs to its step, and clears when you leave it.
- The finished page says the ISO is ready, with **Show in folder**, **Done** and **Create a USB drive**. A finished USB drive shows itself the same way.

### Modes

Atlas is applied after Windows setup and sign-in, not inside `install.wim`, because Store updates depend on the new user's registered apps.
The ISO includes the supported Windows editions, or only the one picked on the **Setup** step. Atlas places its own files and an answer file beside the Windows image.
Every mode then runs the normal preparation, Windows Security and install steps, checks included, so the new PC needs internet access.

| Mode on the Setup step | Atlas choices | When Atlas Manager opens |
| --- | --- | --- |
| **After sign-in** (the default) | Made on the new PC | On the desktop, after sign-in |
| **Now** | Saved in the ISO and preselected | On the desktop, after sign-in |
| **Now**, with **Finish before the desktop opens** ticked | Saved in the ISO; the **Your choices** step is skipped | Full-screen after sign-in, before the desktop |

Without `iso-setup.json` in the package, the step says the choices are made after sign-in, and offers no other mode.

**Finish before the desktop opens** is neither unattended nor a kiosk lock.

- It needs elevation, a network connection and the security prerequisites.
- After the intended user signs in, Atlas Manager runs full-screen until updates and the install finish.
- Explorer runs behind the app, so Settings, Windows Security and Store apps work on Pro.
  Windows shortcuts work, and other monitors may show the desktop.
- **Continue in Windows** works whenever no update, install, media job or restart countdown is running.

### Local account

The answer file creates this local administrator account.
For This PC, Atlas suggests your user name on this PC.
Windows asks for its password at the first sign-in. The ISO skips the Microsoft account and privacy screens, as the **Create** step's review says. Windows Setup shows the licence terms unless you accept them in Manager. Manager offers that choice when it can read the same terms for every edition you include. Enterprise Evaluation handles its own licence during Setup.

A name can't:

- be a built-in name, such as Administrator or Guest;
- contain control characters or any of `" / \ [ ] : ; | = , + * ? < > @`;
- start or end with a space, or end with a full stop;
- be longer than 20 UTF-16 units.

The field supports Unicode, IME composition, selection, the clipboard and keyboard navigation.

### Network drivers

The **Windows** step asks which PC the ISO is for.
With **This PC** as the target, **Include this PC's Wi-Fi and Ethernet drivers** on the **Setup** step, ticked by default, adds the signed OEM driver packages of the physical Ethernet and Wi-Fi adapters, so Windows can go online right after it's reinstalled.
Built-in Windows drivers, VPN and virtual adapters, and Wi-Fi credentials aren't copied.

- The build exports the installed packages, then, on an unmetered connection, also downloads the drivers Windows Update offers for the adapters.
- When Windows Update can't be used (a metered, limited or missing connection, or a search or download that fails), the installed packages are what the ISO carries, and the network driver log says why.
- It never installs updates or changes this PC's driver policy. It isn't a search for the latest driver, and an offered driver may not support an older target build.

When the adapters use only drivers that come with Windows, and Windows Update offers none, there's nothing to back up, and the finished ISO's message says so.
An installed package that fails to export stops the build, whose bar offers **Create without them**.
Atlas never claims a backup that didn't happen.

### Driver updates

Windows Setup uses the drivers that come with Windows and any network drivers included on the ISO. Driver downloads from Windows Update are blocked until Atlas Manager starts preparing Windows after sign-in.

Leave **Choose after sign-in** selected to decide in **Get ready**, or choose **Get drivers through Windows Update** or **Install drivers myself** when you build the ISO. Atlas Manager uses a choice saved on the ISO without asking again.

After a manual-driver installation, Atlas Manager links to the [drivers guide](https://atlasos.net/docs/essential-setup/drivers/) for chipset, network and graphics drivers.

## Create a Windows installation USB

**Create a USB drive** is on the finished ISO's page, and **Create a USB drive from an existing ISO** is on the **Windows** step.

> [!CAUTION]
> Atlas erases the USB drive you choose.

The ISO and the drive are on one screen, and Atlas checks both before anything is erased.
Without administrator permission, the page shows the ISO under a bar that asks for it with **Relaunch as administrator**, as ISO creation does, and lists drives once Atlas has it.

- **The ISO** is the one just created, or else the newest ISO in Downloads whose name starts with "Atlas". **Change** opens another.
  Atlas checks it straight away: that it's Windows 11 installation media for a build the Atlas package supports, that it and Atlas Manager are on a drive of this PC rather than a network location or a linked folder, and that the Windows drive has room to split a large image.
  A problem shows under the ISO with its fix: **Choose an ISO file**, **Open Storage settings** or **Try again**. After freeing space, Atlas checks again by itself within 30 seconds.
- **The drive list** follows drives as they're connected and removed. Each drive shows its model, its size as drives are sold (256 GB, not the 238 GB Windows shows) and its drive letters.
  A drive Atlas can't write is shown unavailable, with the reason: too small (under 8 GiB, which rules out drives sold as 8 GB, so it says 16 GB or more is needed), too small for this ISO, or holding the ISO or Atlas Manager.
- **Picking the drive.** When only one drive can be used, Atlas picks it. A drive you pick stays picked while others come and go, and is picked again if it's reconnected.
- **Create USB drive** asks once, naming the drive, its size and its letters, such as "Erase Kingston DataTraveler Max (256 GB, F:)?". **Cancel** is the default answer, and Escape chooses it; **Erase and create** starts.
- **Progress** is one bar for the whole job, with its percentage, over five stages: Preparing files, Formatting, Copying files, Checking the drive and Ejecting. **Cancel** turns the heading to "Cancelling…".
  Atlas ejects the drive once every file is checked, and the page says the drive is ready. If Windows won't let it go, a bar says the drive is ready anyway and offers **Try again**.

After a failure, the screen comes back with what happened above it:

- A write that may have changed the drive offers **Try again**, which writes the same drive again without asking, and **Send a report**, **Export diagnostics** and **Open log folder**. **Create USB drive** is hidden meanwhile, unless you pick another drive.
- A drive removed, reconnected or replaced before erasing is looked for again by its serial number. Nothing on it changed.
- Cancelling says whether the drive is now incomplete, as a warning when it is.

**Back**, the title's back arrow and Escape leave the panel, except while the drive is being written.

The result is UEFI media for Windows 11 x64 or ARM64 on a supported build.
The USB writer doesn't support legacy BIOS boot or other operating systems.

- The drive gets one active MBR FAT32 partition of up to 32 GB (decimal), and the rest stays unallocated.
- The media uses the ISO's signed UEFI boot files, and Atlas adds no bootloader.
- A large `install.wim` is split into `sources\install*.swm` parts, and a large `install.esd` is first exported to a WIM with every edition.
  Any other file over FAT32's 4 GiB limit fails before anything is erased.

Atlas refuses boot, system, offline and read-only disks, disks without identifiers, and any disk that holds the ISO, the app or their working files.
It checks the drive's identity again before erasing and while writing, and reads every file back to verify it ([USB writing](iso-internals.md#usb-writing)).

## On the new PC

1. **Windows setup** copies the Atlas files to `%windir%\AtlasISO`.
2. In the `specialize` pass, which runs before the out-of-box experience (OOBE), setup blocks Windows Update driver downloads and installs the backed-up network drivers.
3. During OOBE, Windows' first-run setup screens, the answer file creates the local account and hides the network and online-account screens.
   You'll need internet access when Atlas Manager runs preparation after sign-in.
   It also sets `ProtectYourPC=3`, which turns Express settings off and hides them, because Atlas's options hold the real security and update choices.
   The **Create** step's review says so in its **Windows Setup** row.
4. One automatic sign-in turns off further automatic sign-ins, expires the empty password, registers Atlas Manager for the next sign-in and signs out.
5. At your sign-in, Windows asks for a new password, then Atlas Manager opens and runs [the install flow](install-flow.md).

## Troubleshooting

| Problem | What to do |
| --- | --- |
| Release information is unavailable or unrecognised | Check your internet connection, then choose **Try again** on the bar. |
| The ISO's Windows build isn't in Microsoft's list of public releases | Use an ISO from Microsoft: the bar offers **Download from Microsoft**. Release Preview and other preview builds aren't supported. |
| A network driver couldn't be exported | Choose **Create without them** on the bar, or update the driver in Device Manager first. |
| A network driver was rejected | Install it from `%windir%\AtlasISO\NetworkDrivers` once Windows is running ([details](#a-network-driver-was-rejected)). |
| Before-desktop cleanup failed | Run `%windir%\AtlasISO\Desktop.ps1 -RestoreDesktop` ([details](#before-desktop-cleanup-failed)). |
| Windows couldn't open the ISO | Restart your PC, then try again. Atlas waits for Windows to give the ISO a drive letter, and gives one itself to an ISO it opened ([mounting](iso-internals.md#iso-build)). |
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
