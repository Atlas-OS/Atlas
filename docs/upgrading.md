# Updating Atlas

This page explains how Atlas Manager updates the Atlas on your PC to a newer release, or reinstalls the same release, and what happens to your settings and choices.
For the records Atlas keeps behind this, see [Install state and records](install-state.md).

## Supported update paths

Atlas Manager updates Atlas from the versions listed in `UpgradableFrom` in [`playbook/playbook.conf`](../playbook/playbook.conf).
Atlas 0.5.0-hotfix records itself as 0.5.0, so it updates as 0.5.0.
Any other installed version needs a fresh installation of Windows, and so does an Atlas whose version Atlas can't read.

`UpgradableFrom` says which versions Atlas Manager accepts, and the [release verification matrix](release-verification-matrix.md) says what a release verifies.

Your Windows release is a separate requirement.
The PC must run one of the [supported releases](windows-release-policy.md#supported-releases).
When it doesn't, Atlas Manager can often move Windows to a newer release first, on the **Get ready** page.
See [Moving Windows to a newer release](windows-transition.md).

## What an update changes

Every update replaces the Atlas folder and modules in `%windir%\AtlasModules`, keeping Atlas's logs.
It runs the current tweaks, apart from those marked as fresh-install only (`OnUpgrade = 'Skip'`).
It then applies your recorded toggle choices again with the new release's definitions, and they win over any tweak default they overlap.

For a toggle with no recorded choice, the update adopts one only when your registry values point to exactly one of its states, and that state only sets registry values.
A state that also changes services or runs actions isn't adopted, because its values can match Windows's own defaults.
So Atlas can't recover every customisation it doesn't recognise.

When the Atlas power plan is active, the update counts your power-saving choice as **Disable**, even if an earlier install recorded Enable.
Other power plans don't count as a choice, and the update leaves them alone.

## What an update keeps

An update keeps your Start and taskbar layouts, your file associations and the service backups from your first install.
It doesn't repeat the fresh-install service, component and app removal steps, so an established PC isn't treated as a clean Windows installation.

What happens to your install choices depends on the way you update, described next.

## Keep my choices or Choose again

When Atlas Manager updates or reinstalls Atlas, the **Your choices** page first asks how to update, or how to reinstall when the version is the same.

- **Keep my choices**, the default, keeps every choice as your PC has it now.
- **Choose again** asks every choice again, starting from how your PC is set up now, and applies each one as a new installation would.

The same screen lists **Your choices on this PC now**.
Atlas Manager reads each choice from what your PC shows:

| Choice | What Atlas reads on the PC |
| --- | --- |
| Microsoft Defender | Atlas's NoDefender package, or the Defender service |
| Processor protections | The Mitigations toggle record |
| Windows Update | The AutomaticUpdates toggle record |
| Turn off hibernation | The Hibernation toggle record |
| Turn off power saving | The PowerSaving toggle record |
| Turn off virtualisation-based security (VBS) | Whether VBS is off |
| Remove Microsoft Edge | Whether Edge is installed |
| Remove Snipping Tool | Whether Snipping Tool is installed |
| Install Atlas Toolbox | The Toolbox installer's record under `HKLM\SOFTWARE\AtlasOS\Toolbox`, and the Toolbox program |
| Browser | The browsers Atlas offers that are installed, and the browser recorded under `HKLM\SOFTWARE\AtlasOS\SetupOptions` while it's installed |
| Keyboard languages | Your Alt+Shift setting and keyboard layouts |

The Toolbox counts as installed only when both its record and its program are there, because Toolbox 0.1.x leaves the record behind when you uninstall it.

What your PC shows wins over Atlas's record of the last install, because an earlier update may have recorded a choice it never applied.
The screen names any choice where the record is wrong.
A choice the PC doesn't show comes from Atlas's record, or from the record Atlas Manager keeps while it moves Windows to a newer release.
Atlas 0.5.0 and 0.4.1 keep no record of their own, so only the PC, or that record, shows their choices.

Atlas Manager doesn't ask how to update:

- on a first installation, which applies every choice;
- for an [unfinished install](#unfinished-installs), which goes on the way it began;
- after Windows rebuilt itself during a feature update, because a [Rebase](windows-transition.md#rebase) puts back the choices recorded before it.

### Keep my choices

**Your choices** locks every choice to what your PC has.
It asks only for a required choice that neither the PC nor Atlas's record shows.
When it knows them all, **Continue** goes from the first screen straight to **Windows Security**.

The install changes none of your choices, so what earlier choices did stays.
For example, Microsoft Defender that Atlas's NoDefender package removed stays removed, and the install records it as removed.

The install itself also takes each choice your PC shows from the PC, and its log names each one with a `Kept ...` line.

### Choose again

**Your choices** shows every screen again, starting from what your PC has.
**On this PC now** marks the answer your PC has, and an answer that changes your PC says what it changes.

Some answers are fixed, because an update can't undo them:

- **Remove Microsoft Edge** stays ticked once Edge is gone.
  **Install or Remove Edge** in the Atlas folder puts it back.
- **Install Atlas Toolbox** stays ticked while the Toolbox is installed, and **Install a browser** while a browser Atlas installed is there.
  Atlas doesn't uninstall apps, but you can still choose another browser, and Atlas installs it beside the first.

**Keep Microsoft Defender (recommended)** stays available when Defender is missing and no Atlas package removed it.
The **Windows Security** step then warns that Atlas can't bring Defender back, without stopping the install.

The install applies each choice that differs from your PC, after it installs any newly chosen browser or Toolbox:

- **Microsoft Defender.**
  Keeping it puts Defender's core service back and takes Atlas's NoDefender package off, so Defender is back after the restart.
  Removing it installs that package and turns the core service off at the next start of Windows.
  Either change also installs Atlas's NoTelemetry package when it's missing.
  With the NoDefender package already installed, the install only turns off a core service an earlier Atlas left on.
  Atlas can take off only its own package, so a Defender missing for another reason stays missing, with a warning.
- **Microsoft Edge and Snipping Tool.**
  A ticked box removes Edge, or Snipping Tool from every account that has it, as a first installation does.
  While Windows still provisions them, they're also removed for new accounts, even when no account has them, so a feature update doesn't bring them back.
  A cleared box puts nothing back.
- **Power saving, hibernation, processor protections, Windows Update, VBS and keyboard languages.**
  A ticked box or a disabling answer applies Atlas's Disable.
  A cleared box or a default answer undoes Atlas's own Disable, and only where Atlas recorded it, so a power plan or update setting you made yourself isn't touched.

A few of these have exceptions:

- When every processor protection is on (a Mitigations record of 2), keeping protections leaves them all on.
- Clearing **Turn off virtualisation-based security (VBS)** while VBS is off turns it back on after the restart, unless a policy controls it.
  VBS then stays as it is, with the warning `Left VBS as it is: <reason>.`
- A UEFI lock stops only turning VBS off.
- The keyboard answer is always applied.
- When an install that removes Defender finds Atlas's NoDefender package still waiting for a restart, it only warns.
  One that keeps Defender fails with `Microsoft Defender couldn't be restored: ...` until you restart.

Neither way repeats Atlas's other app removals, or its Phone Link, OneDrive or Smart App Control changes.
Neither changes the layouts and settings an update keeps.

## Reinstalling the same version

A reinstall of the installed version runs the tweaks and the installing user's setup, so a new build's fixes reach a PC that already has that version.
Your recorded choices still win over the tweaks' defaults.
Other accounts get the changes once, at their next sign-in.
**Choose again** applies changed choices, as on an update.

## Unfinished installs

An install that stopped goes on the way it began, because the steps it finished won't run again.
**Home** offers **Finish installing Atlas**, and **Your choices** skips its first screen.
Atlas Manager chooses again when the install began that way.

Until the install's main steps have started, a new attempt can still change your choices.
An update that began keeping your choices takes every choice your PC shows again, so **Your choices** asks only what the PC can't show.
The **Windows Security** step also goes by the way the install began.
For example, an update that keeps your choices leaves Defender as your PC has it, whatever options the install holds.

## What Atlas records

When an install finishes, it reads your PC again and records each choice as the PC shows it, which can differ from what you asked for.
Changing a choice later in the Atlas folder or Atlas Toolbox keeps the record in step.
When a choice the install tried to apply didn't take effect, the completion window says **Some choices didn't take effect**, names it and offers **Open log file**.

When Atlas's record keeps Microsoft Defender but Atlas's NoDefender package still removes it, **Home** and the completion window warn that **Microsoft Defender is still removed**.
The warning points to **Choose again** and to **Toggle Defender**, and you can dismiss it for that install.

See [What Atlas records](install-state.md#what-atlas-records) for the details.

## PCs with several accounts

When several people use the PC, each with their own account, the install reaches each account differently:

- **Windows and the whole PC.**
  A feature update, Windows Update's settings, services, machine policies and app removals apply to every account.
- **You, the person installing.**
  Your ordinary settings change under your own non-elevated account during the install, and the install's privileged part handles your protected user policies.
- **Other existing accounts.**
  Each is registered for a one-time migration of ordinary user settings, which runs when that person next signs in.
  A reinstall of the same version registers them again.
  A failed migration runs again at the next sign-in.
  The sign-in migration doesn't change protected policies, so those accounts can keep older protected user policies.
- **New accounts** created after the install get Atlas's new-user setup at their first sign-in.

Before any restart, Atlas Manager checks whether anyone else is signed in, and asks before closing their apps (see [Restarts](preparation.md#restarts)).

Each account's migration log is in that account's `%LOCALAPPDATA%\AtlasOS\Logs`.
To check an account after the restart, sign in as that person and run **Check Atlas Health** from `9. Troubleshooting` in the Atlas folder.
A successful install doesn't prove that every account's settings, or Microsoft Store apps, updated.

The **Get ready** page updates Microsoft Store apps only for you.
See [Microsoft Store apps of other accounts](preparation.md#microsoft-store-apps-of-other-accounts).
