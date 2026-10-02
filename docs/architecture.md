# Atlas architecture

Atlas is a Windows optimization project distributed as the Atlas package, an `.apbx` file.
This document is for contributors and operators: how an install runs, where each part
lives, and the rules the code relies on.

Atlas Manager, the recommended installer, applies the package through the
[front door](#the-atlas-front-door), which also runs on its own from PowerShell. AME
Wizard, the alternative installer, calls the package a playbook and applies it through its
own host. Either way, the workflow itself is Atlas PowerShell.

## Repository layout

The script tree is organized by who invokes a file:

~~~
playbook/
├─ playbook.conf
├─ Configuration/custom.yml           AME handoff
└─ Executables/
   ├─ AtlasDesktop/                   user-facing launchers (two-line .cmd stubs)
   ├─ AtlasModules/
   │  ├─ Toggles/<Group>/<Name>.psd1   data-only toggle definitions (+ optional <Name>.ps1 companion)
   │  ├─ Toolbox/                     launcher stubs and assets the Toolbox app opens by path
   │  └─ Scripts/
   │     ├─ Initialize-AtlasPowerShell.ps1   PowerShell bootstrap every entry point dot-sources
   │     ├─ Compatibility/            Windows release catalog and its check (windows-release-policy.md)
   │     ├─ Entry/                    processes started from outside: AME, launchers, the broker,
   │     │                            RunOnce, shell verbs, user-facing tools
   │     ├─ Install/                  reachable only during an install
   │     │  ├─ Install-Plan.ps1       the ordered plan table
   │     │  ├─ Phases/               one script per plan phase
   │     │  ├─ Tasks/                lifecycle checkpoints and installing-user passes
   │     │  └─ Compat/               upgrade-only cleanup of retired Atlas versions
   │     ├─ Operations/              scripts that run in their own process, invoked by path
   │     │                            (Safe Mode, CBS retry, Edge removal, drivers, OpenShell, ...)
   │     ├─ Modules/Atlas.*/          libraries (see the module table)
   │     ├─ Preparation/              Windows and Microsoft Store update worker, also embedded in the app
   │     ├─ Tweaks/<category>/        data-only install tweaks (+ companion scripts)
   │     └─ Registry/                 .reg assets imported by toggles
   └─ Themes/
app/                                   Atlas Manager, the desktop app (Rust, GPUI): installed version, updates,
                                       guided install, ISO and USB creation, diagnostics (see app/README.md)
services/                              Atlas reports service and its MCP server
tools/
├─ build/                              AtlasBuild module, Build-Playbook, Test-Apbx, Set-AtlasVersion (PowerShell 7)
├─ dev/                                New-ToggleLaunchers, Export-AtlasCatalog, Compare-SystemState, Install-DevProfile
├─ lab/                                Invoke-AtlasLabRun: install and verify on a Hyper-V VM (PowerShell 7)
├─ native/                             Build-AtlasNative: deterministic, signable build of Atlas.Native.cs
├─ release/                            Linux cross-build setup and tester bundles (see building.md)
├─ release-zip/                        extra files packed beside the APBX in the release ZIP
├─ sxsc/                               CBS package sources
└─ timer/                              source build of the timer utilities the Atlas package includes
tests/                                 Pester 5 suites (the Windows PowerShell tests run under Windows PowerShell 5.1)
docs/
~~~

Everything under `playbook` is included in the APBX, except generated APBX files and
recognized build and publication artifacts. There is no manifest of the package's files:
the APBX verifier compares source and archive paths and rejects missing, extra or changed
files.

Entry, operation and install scripts find the Scripts root with
`Split-Path -Parent $PSScriptRoot` (two levels for `Install\Tasks`, `Install\Phases` and
`Install\Compat`). They dot-source `Initialize-AtlasPowerShell.ps1` before importing
anything, then import modules by exact manifest path. Installed paths are
`%windir%\AtlasModules\Scripts\Entry\...`, `...\Operations\...` and `...\Install\Tasks\...`.

## The Atlas front door

[Entry\Install-Atlas.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1)
installs Atlas without AME, with the same plan, state and identity model. Atlas
Manager runs it too. Run it from an elevated Windows PowerShell prompt in the extracted
package's `Executables` folder:

~~~
.\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable, mitigations-default, auto-updates-disable -Restart
~~~

| Parameter | Effect |
| --- | --- |
| `-Option` | FeaturePage options from `playbook.conf`, one per required group (Defender, mitigations, automatic updates). `Get-AtlasInstallOption` (Atlas.InstallState) lists them. |
| `-Unattended` | No prompts, including the confirmation after warnings. Requirements still apply. |
| `-Restart` | Restarts Windows ten seconds after a successful install. `-RestartComment` sets the notice text. |
| `-KeepStaging` | Keeps the staging copy after a successful install. |

| Exit code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Install failed; rerun the same command to resume |
| 2 | Requirements not met |
| 3 | Not elevated |
| 4 | The script never started (reported by Atlas Manager's launcher) |
| 5 | Windows or Microsoft Store preparation is not finished; the install did not start |

### Requirements

| Check | Blocks when |
| --- | --- |
| Windows build and edition | Unsupported |
| Windows release | Not confirmed generally available ([Windows release policy](windows-release-policy.md)) |
| User Account Control | Off, or the account lacks a normal non-elevated token (this rules out the built-in Administrator) |
| Pending restart | Servicing or Windows Update needs one, by their own restart flags. Pending file replacements without either flag are only a note: an update can queue some, such as printer drivers, without asking for a restart, and apps such as Xbox Gaming Services queue one at every boot. |
| `PluggedIn` | On battery |
| `NoAntivirus` | Third-party antivirus is registered |
| `DefenderToggled` | Windows Security switches are on |

The last three apply only when `playbook.conf` declares them. A check that cannot run
counts as a failure. The front door also blocks while Atlas Manager is moving Windows to
another release and Windows hasn't reached it, or while its record of the Windows Update
settings it changed (`HKLM\SOFTWARE\AtlasOS\WindowsTransition`) can't be read. It checks
the Windows build before it resolves the install mode, so a Windows version Atlas doesn't
support is reported as such.

### Preparation check

Before capture, the front door runs `Preparation\Update-Windows.ps1 -VerifyOnly`, the
worker Atlas Manager embeds. It passes only when:

- an online Windows scan finds no required updates;
- Microsoft Store is registered for the installing user, with no outstanding updates or
  active queue items;
- the connection has confirmed internet access and is not metered, data-limited or
  roaming;
- Windows needs no restart (pending file replacements are noted but neither warn nor block);
- the update service is available.

The check never downloads or installs updates. Newly found Store updates are queued paused, even with
automatic downloads off; finish them in Atlas (whose preparation pass resumes the queue)
or Microsoft Store, then retry. Every check runs anew in a protected staging directory and
ignores saved completion receipts.

The Store check must run as the signed-in session owner, so SYSTEM, session 0, elevation
as another account and `-WindowsSetup` (installing from Windows setup as SYSTEM) are
refused. ISO setup must reach that user's sign-in and use normal preparation.

### Preparation restarts in Atlas Manager

Code: `app/src/services/preparation.rs` and `app/src/main.rs`.

- A required restart outranks a partial Windows installation failure, and is checked even
  when an update provider throws. Per-update results and provider errors go to the
  diagnostic log.
- Before offering a restart, the app saves the draft with a restart timestamp, stages its
  recovery executable and adds a temporary HKCU Run entry, `--after-preparation-restart`.
  The entry opens the app only after a new boot; same-boot sign-ins leave it armed. It is
  removed after reboot, or silently at its next launch if the draft was abandoned. Install
  completion works the same way; the ISO custom shell relaunches itself.
- After reboot, the app restores the package and choices and offers **Continue updates**,
  without marking preparation complete.
- Save, startup registration and shutdown failures have separate translated messages. A
  failed shutdown keeps recovery armed for a restart through Windows. When `shutdown.exe`
  answers that a shutdown is already in progress or scheduled (errors 1115 and 1190), the
  restart counts as accepted.

Based on Microsoft's
[`Run and RunOnce Registry Keys`](https://github.com/MicrosoftDocs/win32/blob/79eaaa46b30bd0efef0d0f5a65fd7d11fdd8e2de/desktop-src/setupapi/run-and-runonce-registry-keys.md)
and [`IInstallationResult::RebootRequired`](https://github.com/MicrosoftDocs/sdk-api/blob/f38eb1cccc6080c44fac242e8f6995abf983644d/sdk-api-src/content/wuapi/nf-wuapi-iinstallationresult-get_rebootrequired.md).

### How the front door works

1. It copies the package's files to a new directory under `C:\Windows\AtlasOS\Staging`
   that only SYSTEM and Administrators can write (the access list is set at creation),
   with the options in `request.json`.
2. **Capture.** The TrustedInstaller broker's `Install` operation runs
   `Install\Invoke-AtlasInstallSession.ps1`, which validates the request against the
   option groups in `playbook.conf`, picks Fresh, Upgrade, Reapply or Rebase from the
   machine state document and Atlas Manager's record of a Windows move, begins the install
   state and records the options.
3. The front door publishes the installing user's marker from its own session.
4. **Run.** A second `Install` call commits the state and runs
   `Entry\Invoke-AtlasInstall.ps1 -Run`. Failure keeps the staging copy for resuming;
   success removes it.

The native launcher accepts `Install` only for a copy of the package under the protected
staging root with trusted owner and writers, the same protection it gives the installed
tree for toggles.

- An installed version other than the target must be in `UpgradableFrom`. Installations
  that predate the state document are identified by their OEM version marker
  (`Atlas Playbook vX.Y.Z`). An Atlas installation with no recognisable version is
  refused, not treated as an upgrade source.
- An interrupted capture replaces its whole choice set. Once a run starts, retries keep the
  original choices and completed steps.
- The front door rejects changed choices. AME's incremental capture rejects added choices
  but keeps earlier ones a retry omits.

## The health check

[Entry\Test-AtlasHealth.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Test-AtlasHealth.ps1)
is available as the AtlasDesktop launcher `9. Troubleshooting\Check Atlas Health.cmd`. It
verifies every recorded toggle state and applicable tweak, in machine scope and the
calling user's own HKCU, using the checks in [Verification](#verification). It changes
nothing and prints a report, or JSON with `-Json`.

| Exit code | Meaning |
| --- | --- |
| 0 | No drift |
| 1 | Drift found |
| 2 | Atlas is not installed, or the check could not run |

## The AME handoff

When AME runs the install, it supplies the package runtime, FeaturePage selections,
OOBE/ISO applicability and the starting identities (TrustedInstaller and the signed-in
user). [custom.yml](../playbook/Configuration/custom.yml)
only hands off: it runs the exact inbox Windows PowerShell 5.1 host with `-File`, uses no
AME task includes, and contains no feature workflow.

| Handoff | Identity | Purpose |
| --- | --- | --- |
| Six gated Begin calls | TrustedInstaller | Capture Fresh, Upgrade, or Reapply crossed with normal or OOBE execution |
| One non-OOBE user marker | currentUser | Publish that user's SID and session ID, with the capture nonce, in their HKCU |
| Eighteen option calls | TrustedInstaller | Record only FeaturePage options selected by AME |
| Commit | TrustedInstaller | Validate the marker, bind the user when applicable, and freeze the captured state |
| WdBoot delete | AME offline registry action | Apply the one ISO-only mounted-image exception |
| Entry\Invoke-AtlasInstall.ps1 -Run | TrustedInstaller | Execute the complete live install plan |

- The user marker only publishes identity: no install work, elevation or session change.
  OOBE has no marker.
- Options are separate actions because AME gates actions per option. Capture stays in
  PowerShell, not AME registry actions, so Atlas code writes and validates every install
  fact.
- WdBoot targets an offline mounted image, so it sits outside the plan and cannot run
  during a live install. All other live work runs in the one TrustedInstaller process.
- The front door reuses the marker, Commit and `-Run`, but captures mode and options from
  one validated request.

## One plan and one orchestrator

[Install-Plan.ps1](../playbook/Executables/AtlasModules/Scripts/Install/Install-Plan.ps1)
is the only ordered install table.

| Ordered work | Modes | OOBE | Replay |
| --- | --- | --- | --- |
| DefaultHiveLoad | All | Included | Always |
| PayloadReplacement | All | Included | Always |
| NotificationDisable | All | Included | Always |
| RebaseRecovery | Rebase | Included | Once |
| LegacyChoices | Upgrade, Rebase | Included | Once |
| PreInstall | All | Included | Once |
| ShellRefresh | All | Excluded | Once |
| Environment | All | Included | Once |
| Tweak: qol/set-hidden-settings-pages | Fresh | Included | Once |
| InitializePath | All | Included | Once |
| Features | All | Included | Once |
| Software | All | Included | Once |
| Services | Fresh, Rebase | Included | Once |
| Components | Fresh, Rebase | Included | Once |
| AppxSupport | Fresh, Rebase | Included | Once |
| Defaults | All | Included | Once |
| Tweak: qol/appearance/atlas-theme-upgrade | Upgrade, Rebase | Included | Once |
| Tweaks: networking, performance, privacy, qol, security, debloat, scripts, misc | Fresh, Upgrade, Rebase | Included | Once |
| Tweak: scripts/set-power-settings | Fresh | Included | Once |
| WindowsTransition | All | Included | Once |
| InstallingUserSetup | Fresh, Upgrade, Rebase | Excluded | Once |
| OemBranding | Upgrade, Rebase | Included | Once |
| NotificationRestore | All | Included | Always |
| DefaultHiveUnload | All | Included | Always |

All means Fresh, Upgrade, Reapply and Rebase. Reapply gets only the common work. Rebase
puts Atlas back on a Windows that rebuilt itself while Atlas Manager moved it to a newer
release: the Upgrade plan, plus the fresh-install phases the rebuild undid, with the choices
recorded before the move ([upgrading](upgrading.md#rebase)).

- LegacyChoices registers existing user profiles for logon migration. If no toggle states
  are recorded, it adopts the choices existing settings uniquely identify
  ([upgrading.md](upgrading.md)).
- On an upgrade, InstallingUserSetup migrates the installing user's settings without
  resetting their desktop layout.
- WindowsTransition puts back the Windows Update settings Atlas Manager turned on to
  update Windows, after Defaults has replayed recorded choices and Tweaks/qol has written
  the feature-update pin. Settings a recorded toggle owns are left to the replay. A
  failure here is a warning; the record stays open and Atlas Manager offers to put the
  settings back from Home ([upgrading.md](upgrading.md#windows-version-transition)).
- Fresh OOBE has no installing user, so live-user registry work, ShellRefresh and
  InstallingUserSetup are excluded; machine and default-user tweak parts still apply.
  Instead, the default profile gets the first-logon RunOnce entry, and Initialize-NewUser
  does the session-bound work as each user at first sign-in.

[Entry\Invoke-AtlasInstall.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Invoke-AtlasInstall.ps1)
reads the committed state and dispatches four fixed record kinds:

| Kind | Key | Runs |
| --- | --- | --- |
| Phase | `<Name>` | `Install\Phases\Invoke-<Name>Phase.ps1` |
| TweakCategory | `Tweaks/<category>` | `Invoke-TweaksPhase.ps1` for that category |
| Tweak | `Tweak/<slug>` | `Invoke-TweaksPhase.ps1 -Slug` for one Standalone manifest tweak placed outside the category order; machine and default-user passes only |
| Checkpoint | `Checkpoint/<Name>` | A fixed `Install\Tasks` script |

Each key must name a known phase, category, tweak slug or checkpoint; anything else is
rejected.

- The orchestrator starts from the extracted package, then uses the installed
  `C:\Windows\AtlasModules\Scripts` tree once PayloadReplacement is complete.
- When every applicable key is complete, it calls `Complete-AtlasInstallState`. There is no
  finalization phase; the active state and completed keys are the resume record.
- Steps return to the orchestrator instead of ending its process. It exits 0 on success,
  1 on an install failure and 2 on the wrong privilege; custom.yml halts on any nonzero
  code.

### Phase responsibilities

| Phase | Main responsibility |
| --- | --- |
| PreInstall | Remove obsolete Atlas elevation artifacts (Install\Compat) and run limited machine and user cleanup |
| ShellRefresh | Refresh the exact installing user's shell outside OOBE |
| Environment | Apply environment and runtime configuration |
| Features | Apply Windows capabilities and optional features; clean the component store on fresh installs only, before the Components phase installs the Atlas packages (see below); keep the Atlas packages' repair source |
| Software | Install selected utilities and browsers. Toolbox resolves the latest stable release at install time, not a version pinned in the Atlas package. |
| Services | Back up Windows services, then apply and record the File Sharing, Location and Indexing defaults as the machine part of those toggles |
| Components | Apply machine component and browser cleanup, and the Defender choice. Keeping Defender uninstalls the `Z-Atlas-NoDefender-Package` CBS package if it is present; a failed removal fails the install rather than report success on a PC with no antivirus. |
| AppxSupport | Apply installed/provisioned AppX changes and exact-user cache work |
| Defaults | Initialize the toggle state store on fresh installs; replay recorded toggles on upgrades and reapplies |
| Tweaks | Apply one declarative category, or one standalone tweak, in explicit machine, current-user and default-user scopes |

### The component store and the Atlas packages

The Atlas CBS packages replace inbox components with a higher version
(`38655.38527.65535.65535`). Once a cumulative update adds a newer version of a replaced
component, `DISM /StartComponentCleanup` rebuilds the oldest version from its baseline and
can't rebuild all of its files. With `Z-Atlas-NoTelemetry-Package` installed, it rebuilds
Application Experience (AppInv) 10.0.26100.1591 without `aeinvext.dll` and
`Microsoft.Management.Deployment.winmd`, and the next store check reports the store as
repairable. So:

- The Features phase cleans the store only when no Atlas package is installed and the
  install isn't an update: on a fresh install, before the Components phase. Otherwise it
  logs why it skipped.
- Every install keeps the packages' repair source: an update replaces
  `%windir%\AtlasModules`, so the Features phase recreates
  `AtlasModules\Packages\WinSxS` while the packages are installed, or removes the
  `Servicing\LocalSourcePath` policy when it names that folder and the folder is gone.
- An online `DISM /RestoreHealth` doesn't bring such a store back to clean: it repairs
  those two files and the next check reports other 10.0.26100.1591-baseline files
  instead (Device Inventory's `devinv.dll`, and `resources.pri` of the File Explorer and
  OOBE user experiences). Offline, it fails with 0x800F0915: the Atlas repair source
  holds only the Atlas manifests.
- So Atlas PCs can read as repairable from the packages alone. Before moving Windows to a
  newer release, the update worker records the store check's result and the corrupt items
  the newest check in `CBS.log` names, labelled as the known Atlas package pattern or not,
  and goes on with a repairable store. Whether Windows moved is decided after the restart,
  as for any move. A check that can't run is logged with its error and the move goes on too;
  only a store Windows can't repair stops the move with `feature-servicing`.

Windows's own scheduled store cleanup can do the same on any PC with the packages.

## Install state

[Atlas.InstallState](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.InstallState/Atlas.InstallState.psm1)
keeps one size-limited JSON document under a global named mutex.

| Path | Meaning |
| --- | --- |
| C:\Windows\AtlasOS\Install\active.json | Active Capturing or Running install |
| C:\Windows\AtlasOS\Install\active.json.bak | Last valid state, used for simple recovery |
| C:\Windows\AtlasOS\Install\work | Small temporary data owned by the active install |
| C:\Windows\AtlasOS\Install\last.json | Completed diagnostic record |

The active document is the complete resume model; there are no parallel phase records or
operator reconciliation states. It holds the schema and target versions, transaction ID,
status, mode, OOBE state, options, installing-user SID and session, capture nonce,
completed steps and last error.

1. **Begin** creates Capturing state. A retry reuses it only if the target version, mode
   and OOBE scope match; a conflicting Begin is rejected.
2. **Capture** adds options and the user. A retry may refresh only the same user's
   session ID; a different SID is rejected.
3. **Commit** sets Running. Later AME calls cannot reclassify the mode, OOBE state,
   options or user.
4. **Steps.** Success adds the key to completedSteps; failure records the error and leaves
   the key incomplete.
5. **Completion** requires every applicable key. It replaces the installed flags with the
   applicable `Upgrade.flag`, `Interactive.flag` and `option-*.flag`, writes last.json,
   and removes active.json, its backup and the work directory.

The flags keep the post-install compatibility contract; they never drive the plan. Writes
go to a temporary file that replaces the document. A malformed document with a valid
backup is restored from the backup.

### Retry semantics

| Replay | Behaviour |
| --- | --- |
| Once | Runs until it succeeds, then is skipped |
| Always | Runs on every attempt that reaches it, even if it completed before. Reserved for small, idempotent lifecycle steps. |

A retry resumes the same plan and retries the first incomplete step. Always entries keep
their place in the order; they are not hidden finally handlers.

## Identity and registry scopes

### Installing-user identity

`Entry\Publish-AtlasInstallUser.ps1` writes a nonce, the token SID and the session ID to
`HKCU\Software\AtlasOS\InstallSession`. TrustedInstaller accepts exactly one marker
matching the capture nonce, checks its SID against the HKEY_USERS hive holding it, binds
the SID and session to the state, and removes the marker.

`Invoke-AtlasAsUser` relies only on that binding. It:

- runs only from SYSTEM or TrustedInstaller;
- asks WTS for the recorded session, never enumerating sessions;
- verifies the returned token's SID and session;
- requires the user's profile hive to be loaded;
- launches only the exact inbox Windows PowerShell host, with CreateProcessAsUser;
- waits for the result with a timeout and supports no detached children.

Shell refresh, live HKCU work, AppX cache work and other installing-user steps go through
it.

### The HKCU rule

Ambient HKCU belongs to the current process token, so each tweak category runs three
explicit passes during its own step, never a later queued pass:

1. **Machine.** TrustedInstaller applies machine entries and companion work without
   redirecting HKCU.
2. **Live user** (outside OOBE). The bound user process verifies its own SID and writes
   its own HKCU.
3. **Default user.** With Atlas.Registry bound to the active transaction ID,
   TrustedInstaller writes the same declarations to the fixed loaded
   `HKU\Atlas_DefaultUser` hive. Only strict TrustedInstaller identity with an active
   transaction may do this; other HKEY_USERS targets are rejected.

DefaultHiveLoad and DefaultHiveUnload bracket every plan. Atlas records mount ownership
only after loading the hive. After a later failure, best-effort cleanup unloads an
Atlas-owned mount, but never one this run did not create.

## Notification lifecycle

`Install\Tasks\Set-NotificationState.ps1` silences notifications during the install by
setting the machine policy `NoToastApplicationNotification` to DWORD 1. Disable first
saves whether the value existed and its previous DWORD in `work\notification.json`; a
retry validates and reuses that snapshot rather than overwriting it. Restore writes back the prior value,
or removes it if absent, verifies, and only then deletes the snapshot. There is no
per-user path.

## The machine state document

`C:\Windows\AtlasOS\state.json`
([Atlas.State](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.State/Atlas.State.psm1))
holds everything Atlas knows about an installed machine: version, the mode that produced
it, install history, options and recorded AtlasDesktop toggle states.

- Install completion writes the install facts. The toggle engine mirrors each recorded
  toggle state, and rebuilds that view when the Defaults phase initializes or replays the
  store.
- Writes take a global mutex and replace the file atomically. Reads are schema-checked,
  so a malformed document is an error, not trusted input.
- A recorded state means Atlas applied that choice's machine work and queued its user work
  for first sign-in. Fresh installs seed nothing from launcher defaults; `(default)`
  labels are not evidence of applied work.
- Existing records are always replayed, because the store cannot tell a default seeded by
  an earlier build from a user's choice.
- `Get-AtlasContext` (post-install mode, options and version), the health check, support
  bundles and the Toolbox app read this file. `AtlasModules\Flags` and the registry toggle tree are still written for the
  consumers in [compatibility.md](compatibility.md); no Atlas code prefers them.

## Verification

Apply and verify share one vocabulary. Besides the health check, the Defaults phase uses
it: after an upgrade replays the recorded states, Defaults verifies them and logs any
remaining drift. This exposes declarations a new Windows build no longer honours.

### Verification functions

Every `Registry`, `Services` and `ScheduledTasks` declaration a tweak or toggle state
applies can be read back. Each function returns one drift record, with the reason, per
declaration that no longer holds.

| Function | Module | Verifies |
| --- | --- | --- |
| `Test-AtlasRegistryEntries` | Atlas.Registry | Registry declarations |
| `Test-AtlasServiceEntries` | Atlas.Services | Service declarations |
| `Test-AtlasScheduledTaskEntries` | Atlas.TasksProcs | Scheduled-task declarations |
| `Test-AtlasToggleState`, `Test-AtlasToggleDrift` | Atlas.Toggles | One state, or every recorded state, against the installed definitions |
| `Test-AtlasTweak`, `Test-AtlasTweakCategory` | Atlas.Tweaks | Install tweaks, honouring each tweak's applicability gates |

Companion functions and `Run` entries are imperative and are not verified.

### Registry entry options

These keys are defined in the
[tweak schema](../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md).

| Key | Effect |
| --- | --- |
| `SkipVerification` | A non-empty reason. The entry applies but skips drift checks; for values that only initialize transient Windows state. Verbose verification explains each exclusion. |
| `AllowOsProtected` | Logs a warning instead of failing, only when the key opens but Windows refuses the value for every caller, including TrustedInstaller. The health check still reports it as drift. Other registry failures stay fatal and name the exact entry. |
| `UseGroupPolicy = $true` | Writes HKLM `Software\Policies` DWORD Set entries through `IGroupPolicyObject`, keeping unrelated local policy. Atlas checks `gpupdate` and verifies the effective value before reporting success. Widgets uses it for `AllowNewsAndInterests`, which covers the taskbar entry as well as the board. |
| `VerifyWithToggle` | On a machine or current-user default: a toggle `Name`, integer `State`, and a `Set` (`Type`/`Data`) or `Delete` override. |

`VerifyWithToggle` (`Atlas.Tweaks\Domain\Verify.ps1`) expects the override when that
toggle's recorded state matches, and the install default otherwise. Either way the value
is checked, so an incorrect override is still drift. Fresh installs apply the default; an
upgrade applies the override when the state matches, so it does not restore a restriction
the user lifted. Current-user values are read from the account being checked, never
another profile. Location and Copilot use it for their explicit enable choices.

### Scheduled tasks and search indexing

Scheduled-task changes (`Atlas.TasksProcs\Domain\ScheduledTasks.ps1`) read the
scheduler's language-neutral `Enabled` state before and after `schtasks.exe` and log the
verified result; verification never parses localized output.
Only missing-task HRESULTs are tolerated. Access failures, nonzero exit codes and
mismatched results fail unless the declaration allows errors.

Search indexing (`Atlas.Search\Domain\Index.ps1`) stages URLs under
`HKLM\SOFTWARE\AtlasOS\Search` while WSearch is stopped. Once the service starts, it
commits them through `ISearchCrawlScopeManager`, then reopens the scope manager to verify
the saved effective scope (`SearchScope` in `Atlas.Native.cs`). Includes end in a directory
separator and exclusions in `\*`, per Microsoft's
[scope rule format](https://learn.microsoft.com/en-us/windows/win32/search/-search-3x-wds-extidx-csm-scoperules).

- Minimal or Full replaces earlier user scope overrides with Windows defaults and the
  preset. Administrator Group Policy still takes precedence.
- Windows owns the Gather scope records and CurrentPolicies cache; Atlas does not edit
  them or reset Search setup.
- `Get-AtlasIndexScopeState` reads effective scope for report probes without creating
  files or changing configuration.

## Tweaks and AtlasDesktop toggles

A setting has one implementation, in a [PowerShell module](#powershell-modules). Two kinds
of declarative definition call it:

| Kind | Definitions | Schema |
| --- | --- | --- |
| Install tweaks | Data-only PSD1 files under `Scripts\Tweaks\<category>`, ordered by `tweaks.manifest.psd1` | [Tweak schema](../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md). Its `Toggle` key applies and records the machine part of a toggle state during the install. |
| AtlasDesktop toggles | Data-only PSD1 files under `AtlasModules\Toggles\<Group>`, each with an optional functions-only companion script | [Toggle schema](../playbook/Executables/AtlasModules/Toggles/README.md): the same `Registry`, `Services` and `ScheduledTasks` vocabulary plus named companion functions |

### The toggle engine

Atlas.Toggles decides where each part of a state runs from its declarations; the toggle
schema has the full rules.

- Machine work runs under the declared elevation and is recorded under
  `HKLM\SOFTWARE\AtlasOS\Services` once it completes.
- User work runs after the machine part succeeds, in the launching user's own
  non-elevated process, so it never inherits an elevated token.
- Upgrades replay each recorded state's machine part from the installed definition. Each
  account's first sign-in replays the user parts.
- The state store never persists executable paths.

### Launchers and console output

- Every AtlasDesktop and Toolbox `.cmd` is a generated two-line stub. It calls
  `Scripts\Entry\Invoke-AtlasToggleLauncher.cmd` with the toggle name, the state and its
  own path.
- That shared body anchors to the protected command host and sanitizes the environment. It
  validates `/silent`, `/quiet`, `/justcontext` and `/noaction` before Windows PowerShell
  starts, then runs `Entry\Invoke-Toggle.ps1`.
- `tools\dev\New-ToggleLaunchers.ps1` regenerates and validates the stubs without running
  toggle code.
- The engine and the Atlas.Core console vocabulary (`Domain\Ui.ps1`) own what an
  interactive run prints; companions only add steps, questions and facts through the same
  helpers. [console-presentation.md](console-presentation.md) has the details.

### Generated catalog

The definitions are the only hand-written description of what Atlas can do.
`tools\dev\Export-AtlasCatalog.ps1` derives everything that lists them:

- `Toggles\catalog.json` in the Atlas package: every toggle with its states, launchers,
  elevation and state values. It is the machine-readable contract for AtlasToolbox and
  other consumers.
- The references under [docs/catalog](catalog/toggles.md).

Output is deterministic, and CI checks that the committed files match the definitions.

### Start and taskbar pins

Atlas sets Start and taskbar pins during user setup. The code is in
`Atlas.Shell\Domain\Start.ps1` and `Taskbar.ps1`, and in `Entry\Initialize-NewUser.ps1`
for later accounts.

- Start uses the Windows Configure Start Pins policy. On systems older than the servicing
  level that introduced the local policy, Atlas warns but still applies the validated
  layout and default-profile cleanup, so a later cumulative update can use them.
- Windows has no stable taskbar layout API, so the taskbar's binary values are a
  deliberate compatibility workaround, kept within supported builds. They are not assumed
  portable across shell versions or profiles, and are retested when supported builds
  change.
- Every native registry write is checked; a value that cannot be applied fails the
  user-setup checkpoint instead of recording false success.
- A missing selected browser falls back to Edge, then to File Explorer alone. Temporary
  shortcut staging is always removed.
- The generated File Explorer shortcut carries the `Microsoft.Windows.Explorer`
  AppUserModelID, and Explorer refreshes after the pin database is committed, so open
  Explorer windows group under the pin. Setup also creates the user's `Atlas.lnk` desktop
  shortcut with the Atlas folder icon.
- For later accounts, the two-stage RunOnce setup removes its retry before refreshing
  Explorer, so the new shell cannot start a second initializer. The ready notification
  follows the final shell refresh.
- Setup registers OneDrive and cleans up leftovers per account, never deleting a sync
  root that contains files.

## Privileged post-install operations

The orchestrator already runs as TrustedInstaller, started by AME or by the front door
through the broker. Post-install tools use the native TrustedInstaller broker
(`Entry\Invoke-AtlasTrustedInstallerBroker.ps1`), not an arbitrary RunAsTI launcher. It
accepts three typed operations:

| Operation | Runs |
| --- | --- |
| Toggle | Installed `Entry\Invoke-Toggle.ps1` |
| ResetServices | Installed `Entry\Restore-AtlasServiceDefaults.ps1` |
| Install | The protected staging copy of `Install\Invoke-AtlasInstallSession.ps1` (see [the front door](#the-atlas-front-door)) |

The process contract is deliberately small: the caller gets the target's exit code, and
diagnostics go to standard error. Native launch evidence is internal, not part of the
protocol. Feature logic stays in the shared modules and toggle definitions.
`Scripts\RunAsTI.cmd` is only a deny-only stub for obsolete shortcuts (see
[compatibility.md](compatibility.md)).

## Safe Mode and CBS retry

[Operations\SafeMode.ps1](../playbook/Executables/AtlasModules/Scripts/Operations/SafeMode.ps1)
has four operations: Minimal, Networking, CommandPrompt and Exit. It uses the fixed
System32 `bcdedit.exe`. Its only state is the prior Winlogon shell, needed to undo
CommandPrompt mode, in `C:\Windows\AtlasOS\Recovery\SafeMode.json`.

[Operations\CbsRetry.ps1](../playbook/Executables/AtlasModules/Scripts/Operations/CbsRetry.ps1)
recovers failed CBS packages:

1. Atlas records absolute package paths in `C:\Windows\AtlasOS\Recovery\CbsRetry.json`.
2. The state moves from Pending to Armed once CommandPrompt Safe Mode is set.
3. `CbsRetry.ps1 -Recover` exits Safe Mode and runs the Atlas.Software CBS installer with
   those literal paths.
4. The state file is removed only after the retry succeeds.

One mutex serializes the retry. The PayloadReplacement phase refuses to run while CBS
retry state exists, so it cannot replace the installer recovery needs. Recovery is always
an explicit `-Recover` operation, never a hidden scheduled task or AME task runner.

## PowerShell modules

| Module | Responsibility |
| --- | --- |
| Atlas.Core | Data-file loading, sibling module import, active install-state context, post-install flag compatibility, logging, the console vocabulary, privilege checks, exact-user launch, the native TrustedInstaller broker, and the native type loader |
| Atlas.State | The machine state document: installed version, history, options and the toggle view |
| Atlas.InstallState | Compact capture, persistence, step replay, and completion into the state document |
| Atlas.Registry | Typed registry operations, explicit current-token/default-user identity scopes, declarative registry entries and their verification, Windows PowerShell execution policy |
| Atlas.Services | Service startup changes, declarative service entries and their verification, service backup/restore |
| Atlas.TasksProcs | Scheduled task and process helpers, declarative scheduled-task entries and their verification |
| Atlas.Tweaks | Declarative tweak loading, validation, applicability, scoped execution, and verification |
| Atlas.Toggles | Toggle definition loading and validation, the toggle engine, the state store, upgrade/first sign-in replay, and drift verification |
| Atlas.Download | Size- and time-limited HTTPS downloads, protected staging, contained native execution, GitHub release resolution, trusted WinGet resolution |
| Atlas.Appx | Installed/provisioned AppX operations, exact-user cache work, Game Bar installation |
| Atlas.Software | Software/browser installers and CBS package operations |
| Atlas.Shortcuts | Shortcut creation |
| Atlas.Themes | Theme application |
| Atlas.Security | Defender package state, VBS/HVCI configuration, Windows Temp permission repair |
| Atlas.Hardware | Atlas power scheme, PnP device enable/disable |
| Atlas.Network | Atlas/Windows network defaults, file sharing on/off |
| Atlas.Search | Search index configuration and machine state, Store search recommendations |
| Atlas.Privacy | Location services machine state, telemetry log cleanup, telemetry component removal |
| Atlas.Shell | Settings page visibility, file associations, Send To menu, shell context-menu helpers, Start layout, taskbar pins, Explorer Home pins |

- Toggle companions, tweak companions and entry scripts import the module
  (`Import-AtlasModule` inside companions) and call its function.
- A companion function never shares a name with the module function it calls, so it
  cannot shadow it.
- `Scripts\Operations` keeps only scripts that must run in their own process: contained
  or elevated child bodies, package transactions, and user-context bodies that Windows or
  a launcher invokes by path.

### The PowerShell bootstrap

Every process entry point dot-sources
[Initialize-AtlasPowerShell.ps1](../playbook/Executables/AtlasModules/Scripts/Initialize-AtlasPowerShell.ps1)
before any autoloadable command runs. It sets `PSModulePath` to the Atlas module tree
followed by the inbox Windows PowerShell module root. It then imports the four inbox
modules Atlas uses from their exact protected manifests, checking each loaded from that
path. Nothing on a per-user module path can then shadow an Atlas or Microsoft module.

### Native code

Every P/Invoke and COM interop declaration lives in
[Atlas.Core\Native\Atlas.Native.cs](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.Core/Native/Atlas.Native.cs),
namespace `Atlas.Native`. `Initialize-AtlasNativeType` (Atlas.Core) loads it once per
process; callers never call `Add-Type` themselves.

- A prebuilt `Atlas.Native.dll` beside the source is used only if its Authenticode
  signature is valid. Otherwise the source is compiled in place.
- Elevated and SYSTEM processes compile in a new, randomly named directory under the
  system profile, created with an access list admitting only SYSTEM and Administrators.
  TEMP and TMP point at it meanwhile, so a temp directory the requesting user can write
  never feeds code that runs as SYSTEM or TrustedInstaller.
- Unelevated processes compile directly.
- `tools\native\Build-AtlasNative.ps1` builds a deterministic, signable DLL (see
  [building.md](building.md)). No release includes one yet: the project has no
  code-signing certificate, and the loader ignores unsigned DLLs.

## Packaging

- tools\build\AtlasBuild assembles the APBX, a password-protected ZIP. A build writes to a
  unique temporary output and replaces the destination only after the archive verifies.
- `tools\build\Test-Apbx.ps1` checks archive integrity, root layout, configuration and
  exact parity with the files under `playbook`.
- SxS CABs under `tools\sxsc` are built as review-only CI candidates and committed under
  `playbook` separately after review. Their CBS package versions are independent of the
  Atlas version.

See [building.md](building.md), [testing.md](testing.md) and
[compatibility.md](compatibility.md) for developer workflows and the files kept for
compatibility.
