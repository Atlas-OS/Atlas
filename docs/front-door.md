# The front door

This page is a reference for contributors who work on the install or test it by hand.
It describes `Entry/Install-Atlas.ps1`, the script Atlas Manager runs to install Atlas, which the rest of the documentation calls the front door.

> [!IMPORTANT]
> Atlas Manager is the only way to install Atlas.
> Run the front door yourself only on a test PC or a virtual machine, and don't point users to it.

For how the front door fits with the TrustedInstaller broker and the install plan, see [Atlas architecture](architecture.md).

## How Atlas Manager runs it

Atlas Manager extracts the Atlas package, then starts Windows PowerShell 5.1 elevated with `-Command`.
It uses `-Command` because `-File` passes every argument as one string, and the option list must arrive as an array.

```powershell
& '<package folder>\Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1' -Option @('defender-enable','mitigations-default', ...) -Unattended
```

It adds `-WindowsSecurityConfirmed` when you confirmed the reading of its last Windows Security check, and `-ChooseAgain` when you chose **Choose again**.
Atlas Manager restarts Windows itself, so it never passes `-Restart`.

## Run it when testing

The quickest repeatable test is the lab run, which restores a Hyper-V checkpoint, installs through the front door and runs the health check.
See [Lab VM verification](testing.md#lab-vm-verification).

To run it by hand:

1. Build the Atlas package, for example with `-NoPassword` so you can extract it with any archive tool (see [Build options](building.md#build-options)).
   A `-LocalTest` build leaves out `SupportedBuilds`, so the front door refuses it.
2. Bring Windows and Microsoft Store apps up to date, or let Atlas Manager's **Get ready** page do it.
   The front door checks this and exits with code 5 when anything is outstanding.
3. Open Windows PowerShell 5.1 as administrator, signed in as the account Atlas is for.
4. Go to the `Executables` folder of the extracted package and run the front door:

   ```powershell
   .\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable, mitigations-default, auto-updates-disable, keyboard-shortcuts -Restart
   ```

The front door makes the same changes as an install from Atlas Manager, so use a PC you can reset.

## Parameters

| Parameter | Effect |
| --- | --- |
| `-Option` | Required. The option names from `FeaturePages` in `playbook.conf`, lower case, letters, digits and hyphens only. |
| `-Unattended` | Doesn't ask before continuing after warnings. Blocking requirements still apply. |
| `-WindowsSecurityConfirmed` | You checked in Windows Security that all four protection switches are off. A switch that can't be read then doesn't block, but one that reads on still does. |
| `-ChooseAgain` | On an update or a reinstall, applies the `-Option` choices wherever the PC differs from them. Without it, the install keeps the choices the PC has. |
| `-Restart` | Restarts Windows 10 seconds after a successful install. |
| `-RestartComment` | The text of Windows's restart notice with `-Restart`, at most 512 characters, control characters removed. The default is `Atlas installation complete.` |
| `-KeepStaging` | Keeps this run's staging copy whole, whatever the outcome. |
| `-WindowsSetup` | Refused. Microsoft Store preparation belongs to a signed-in user, so the front door must run in that user's session. |

`-Option` needs exactly one option from each radio group: Microsoft Defender, processor protections, automatic updates and keyboard languages.
It needs exactly one browser when it includes `install-another-browser`, and refuses a browser without it.
Options that `playbook.conf` doesn't declare are refused.
Capture checks the options, so a wrong one fails the run with exit code 1 after the preparation check.

To list each group's options, read `FeaturePages` in `playbook/playbook.conf`, or call `Get-AtlasPlaybookOption` from the `Atlas.InstallState` module.

`-ChooseAgain` has no effect on a first installation, and the front door says so.
A Rebase refuses it before anything is copied, because a Rebase first puts back the choices the PC had before Windows rebuilt itself.
Run the Rebase without it, then reinstall Atlas with it.
An unfinished install goes on the way it began, whether or not you pass it.
See [Keep my choices or Choose again](upgrading.md#keep-my-choices-or-choose-again) for what each way does.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Atlas is installed. Restart Windows to finish, unless you passed `-Restart`. |
| 1 | The install failed. Run the same command again to resume. |
| 2 | A requirement isn't met, or you didn't confirm the warnings. |
| 3 | The prompt isn't elevated. |
| 4 | Reserved for Atlas Manager's launcher, which reports it when the front door never started. |
| 5 | Windows or Microsoft Store preparation isn't finished, so the install didn't start. |

## Requirement checks

The front door prints each check as `OK`, `FAIL` or `WARN`, followed by its name and detail.
A `FAIL` stops the install with exit code 2.
After a `WARN`, the front door asks `Continue despite the warnings above? [Y/N]` unless you passed `-Unattended`.
A check that can't run counts as failed.

| Check | Fails when |
| --- | --- |
| `Windows edition` | Windows isn't a client installation, or it's Home, LTSC, IoT LTSC or Server. |
| `Windows build` | The build isn't in `SupportedBuilds`. The detail says when Atlas Manager can move Windows to a supported release first. |
| `Windows release` | The release catalog doesn't list the build and revision as released (see [Windows release eligibility](windows-release-policy.md)). |
| `User account` | User Account Control is off, the account has no normal non-elevated token, or it's a work or school (Microsoft Entra ID) account. |
| `No pending reboot` | The servicing stack or Windows Update has set its restart flag. |
| `No pending file replacements` | Never. It only notes files Windows replaces at the next restart. |
| `Plugged in` | The PC runs on battery, or Windows can't tell. |
| `No third-party antivirus` | Windows Security Center lists another antivirus app. |
| `Windows Security` | A protection switch is on, or can't be read and `-WindowsSecurityConfirmed` wasn't given. |
| `No Windows update in progress` | Atlas Manager is moving Windows to a newer release and hasn't finished, or its record of that can't be read. |

Some details of these checks:

- A missing `EnableLUA` value counts as User Account Control on, as Windows treats it.
  The token check then decides.
  The built-in Administrator account fails this check.
- Pending file replacements without either restart flag don't block.
  An update can queue some, such as printer drivers, without asking for a restart, and apps such as Xbox Gaming Services queue one at every restart.
- An antivirus registration whose signed program is gone is the leftover of an uninstall, so the check ignores it.
- `Plugged in` and `No third-party antivirus` block only when `playbook.conf` declares `PluggedIn` and `NoAntivirus`.
  Otherwise their failure is a warning.
- `Windows Security` runs only when `playbook.conf` declares `DefenderToggled`.
  The front door refuses a package that declares a requirement it can't check.
- The last check also fails while Atlas Manager hasn't yet checked how Windows moved, and when Atlas packages are gone after a feature update without Windows having reinstalled itself.
  See [Moving Windows to a newer release](windows-transition.md).

The front door checks the Windows build before it resolves the install mode, so it reports an unsupported Windows build as such, not as an Atlas version it can't update.

### Windows Security on a PC without Defender

The protection switches belong to the Defender service, so a PC without it has none to turn off and `Windows Security` doesn't block.
The detail says what this install does about the missing Defender.
It decides from the mode, the update path and whether Atlas's NoDefender package is installed.

| Situation | Detail |
| --- | --- |
| Atlas's NoDefender package removed Defender, and the options keep it, on a Fresh install, a Rebase or with `-ChooseAgain` | The install takes the package off, so Defender is back after the restart. |
| The same, on an update or reinstall that keeps the choices | A warning: the install leaves Defender removed and records it as removed. |
| Nothing Atlas installed removed Defender, and the options keep it | A warning: this install can't bring Defender back. |
| Any other case, or the packages or the mode can't be read | There's nothing to turn off. |

## What the front door does

1. It checks that it's elevated, reads the target version from `playbook.conf` and runs the requirement checks.
2. It resolves the install mode and the update path and prints them, for example `Install mode: Upgrade, keeping your choices.`
   It refuses an installed Atlas version that `UpgradableFrom` doesn't list, and Atlas files whose version it can't establish.
3. It copies `playbook.conf` and the `Executables` folder into a new folder under `%windir%\AtlasOS\Staging`.
   The folder gets an access list at creation that lets only SYSTEM and Administrators write.
   The copy refuses symbolic links and junctions in the extracted package.
4. It runs the preparation check from the staging copy (see [The check before the install](preparation.md#the-check-before-the-install)).
   If preparation isn't finished, it exits with code 5.
5. It writes `request.json` into the copy, with the sorted options and `choices` set to `Keep` or `ChooseAgain`.
6. It asks the TrustedInstaller broker to run Capture from the copy, with a five-minute limit.
   When Capture takes a choice from the PC instead of the request, the front door names it: `Choices taken from this PC instead of the request: ...`
7. It publishes the installing user's marker from its own session.
8. It asks the broker to run Run from the copy, with a two-hour limit.
9. After a successful install it removes its staging copy, prints `Atlas installed successfully.` and restarts Windows when asked.

Capture and Run are described in [Atlas architecture](architecture.md#what-runs-where).
The records they write are in [Install state and records](install-state.md).

### Choices Capture takes from the PC

On an update or reinstall that keeps the choices, Capture replaces each requested choice the PC shows with what the PC has.
It runs before the installing user is bound and within the broker's time limit, so it reads only the machine.
That covers Atlas's packages, the Defender service, the toggle records, the VBS settings, Edge, the Toolbox and the browsers.
Snipping Tool and eclean keep the request, and so does the keyboard choice unless a KeyboardShortcuts record shows it.

Capture logs a line for each choice it takes, such as `Kept 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': Atlas's NoDefender package is installed. Run again with -ChooseAgain to change it.`
A resume must then give the options Capture recorded.
A Rebase isn't read from the PC, because a rebuilt Windows no longer shows its choices, so Atlas Manager's record of the feature update keeps them.

### The user marker

The marker is `HKCU\Software\AtlasOS\InstallSession`, written by `Entry/Publish-AtlasInstallUser.ps1`.
It holds only the user's SID, the Windows session ID and the capture nonce.
Run accepts exactly one marker that carries the nonce, checks that its SID matches the user hive holding it, binds that user to the install and removes the marker.
All install work runs later as TrustedInstaller.

### The broker's Install operation

The broker accepts `Install` only for a copy under the protected staging root whose owner and writers are trusted.
It runs `Install/Invoke-AtlasInstallSession.ps1` from that copy as TrustedInstaller, once with `-Phase Capture` and once with `-Phase Run`.
The TrustedInstaller process has no console, so each phase writes its own log, and the broker passes the end of it back when the phase fails.

Each phase logs to `Executables\AtlasModules\Logs\install-capture.log` or `install-run.log` in the staging copy.
It also leaves a copy in `%windir%\AtlasModules\Logs\install`, because a successful install removes the staging copy.
A failed phase's message names the copy.
See [How diagnostics work](diagnostics.md#how-it-works).

## Staging copies

A successful install removes its own copy.
It also strips the package files from older copies, keeping what diagnostics export: `request.json`, `AtlasModules\Logs` and the `Preparation` folder.
Copies made after this run's are left alone, in case another run is using one.

A run that stops before Capture, because the preparation check refused it or the copy failed, keeps only what diagnostics export.
Once Capture has started, a failed run keeps its whole copy until a later successful install tidies it.
A broker that timed out can leave its TrustedInstaller process in the copy, which is why the front door doesn't delete it then.
`-KeepStaging` keeps the copy whole in every case.

## Resuming

Run the same command again to resume a failed install.
Each attempt makes a new staging copy, and the install resumes from its install state.

- A failed Capture that hadn't started the plan replaces its choices and update path with the new request's.
- Once the plan has started, a retry keeps the original choices, update path and completed steps.
  The front door says so: `Continuing the unfinished installation as it began, ...`
- A retry with other options is refused, and the message names the options the run started with.
  When Capture took choices from the PC, the failure message gives the `-Option` list to rerun with.

See [Install state and records](install-state.md#the-active-install-state) for how a resume decides what to run again.
