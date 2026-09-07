# Atlas architecture

Atlas is a Windows optimization playbook packaged as an APBX and applied by AME
Wizard. AME supplies the package runtime, FeaturePage selections, OOBE/ISO
applicability, and the initial execution identities. Atlas owns the installation
workflow in PowerShell. AME tasks are not an Atlas execution framework: the YAML
handoff invokes fixed PowerShell entry points and does not contain the feature
workflow.

The installation is organized around these responsibilities:

- custom.yml captures AME facts and starts one installer.
- Atlas.InstallState stores only the facts and progress needed to resume.
- Install-Plan.ps1 is the single ordered applicability table.
- Invoke-AtlasInstall.ps1 is the single install orchestrator.
- Machine, installing-user, and default-user work have explicit identity scopes.
- A setting has one implementation. Install tweaks and AtlasDesktop toggles are both
  declarative callers of it, and a toggle's machine part is what the install applies.
- Native interop is one C# source loaded once per process through one
  protected loader.

## Repository layout

Every file below `playbook` ships in the APBX except generated APBX files and their
recognized build/publication artifacts. There is no separate payload manifest.
The APBX verifier compares source and archive paths and rejects missing, extra, or
changed payload files. The script tree is organized by who invokes a file:

~~~
playbook/
├─ playbook.conf
├─ Configuration/custom.yml           AME handoff (thin; see below)
└─ Executables/
   ├─ AtlasDesktop/                   user-facing folder; every .cmd is a two-line launcher stub
   ├─ AtlasModules/
   │  ├─ Toggles/<Group>/<Name>.psd1   data-only toggle definitions (+ optional <Name>.ps1 companion)
   │  ├─ Toolbox/                     launcher stubs and assets the standalone Toolbox app addresses by path
   │  └─ Scripts/
   │     ├─ Initialize-AtlasPowerShell.ps1   the one PowerShell bootstrap every entry point dot-sources
   │     ├─ Entry/                    processes started from outside: AME, launchers, the broker,
   │     │                            RunOnce, shell verbs, user-facing tools
   │     ├─ Install/                  reachable only during an install
   │     │  ├─ Install-Plan.ps1       the ordered plan table
   │     │  ├─ Phases/               one script per plan phase
   │     │  ├─ Tasks/                lifecycle checkpoints and installing-user passes
   │     │  └─ Compat/               upgrade-only cleanup of retired Atlas versions
   │     ├─ Operations/              process-boundary scripts only: package transactions, elevated
   │     │                            child bodies and user-context bodies invoked by path
   │     │                            (Safe Mode, CBS retry, Edge removal, drivers, OpenShell, ...)
   │     ├─ Modules/Atlas.*/          libraries (see the module table)
   │     ├─ Tweaks/<category>/        data-only install tweaks (+ companion scripts)
   │     └─ Registry/                 .reg assets imported by toggles
   └─ Themes/
app/                                   Atlas desktop app (Rust, GPUI): version, updates, guided install (see app/README.md)
tools/
├─ build/                              AtlasBuild module, Build-Playbook, Test-Apbx, Set-AtlasVersion (PowerShell 7)
├─ dev/                                New-ToggleLaunchers, Export-AtlasCatalog, Compare-SystemState, Install-DevProfile
├─ lab/                                Invoke-AtlasLabRun: install and verify on a Hyper-V VM (PowerShell 7)
├─ native/                             Build-AtlasNative: deterministic, signable build of Atlas.Native.cs
└─ sxsc/                               CBS package sources
tests/                                 Pester 5 suites (payload suites run under Windows PowerShell 5.1)
docs/
~~~

Path conventions inside the payload are fixed. An entry, operation or install script
reaches the Scripts root with `Split-Path -Parent $PSScriptRoot` (two levels for
`Install\Tasks`, `Install\Phases` and `Install\Compat`), dot-sources
`Initialize-AtlasPowerShell.ps1` before it imports anything, and imports modules by
their exact manifest path. Installed absolute paths are
`%windir%\AtlasModules\Scripts\Entry\...`, `...\Operations\...` and
`...\Install\Tasks\...`.

## The PowerShell bootstrap

[Initialize-AtlasPowerShell.ps1](../playbook/Executables/AtlasModules/Scripts/Initialize-AtlasPowerShell.ps1)
is dot-sourced by every process entry point before any autoloadable command runs. It
replaces `PSModulePath` with the Atlas module tree followed by the inbox Windows
PowerShell module root, and imports the four inbox modules Atlas relies on from their
exact protected manifests, verifying that each loaded from that path. Nothing inherited
from a per-user module path can shadow an Atlas or Microsoft module afterwards.

## The AME handoff

[custom.yml](../playbook/Configuration/custom.yml) is a thin compatibility layer,
not the Atlas workflow engine. It uses the exact inbox Windows PowerShell 5.1 host
with -File and contains no AME task includes.

Its handoff is fixed:

| Handoff | Identity | Purpose |
| --- | --- | --- |
| Six gated Begin calls | TrustedInstaller | Capture Fresh, Upgrade, or Reapply crossed with normal or OOBE execution |
| One non-OOBE user marker | currentUser | Publish a nonce-bound SID and session ID in that user's HKCU |
| Seventeen option calls | TrustedInstaller | Record only FeaturePage options selected by AME |
| Commit | TrustedInstaller | Validate the marker, bind the user when applicable, and freeze the captured state |
| WdBoot delete | AME offline registry action | Apply the one ISO-only mounted-image exception |
| Entry\Invoke-AtlasInstall.ps1 -Run | TrustedInstaller | Execute the complete live install plan |

The same three scripts serve the front door below; only the caller differs.

The current-user action publishes identity only. It does not run install work,
elevate the account, or select a different session. OOBE has no installing-user
marker.

The WdBoot action is intentionally outside the PowerShell plan because it targets
an offline mounted image. It is unreachable during a live installation. All other
live work is owned by the one TrustedInstaller PowerShell process. Each option is
its own AME action because AME gates actions per option; Atlas deliberately keeps
option capture in PowerShell rather than in AME registry actions so that every
install fact is written and validated by Atlas code.

## The Atlas front door

AME is one host for the install, not the only one.
[Entry\Install-Atlas.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1)
installs the same playbook from an elevated Windows PowerShell prompt in the
extracted APBX's `Executables` folder:

~~~
.\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable, mitigations-default, auto-updates-disable -Restart
~~~

It runs the same plan, state and identity model AME drives. The script requires a
supported build and edition and no pending reboot, including pending file renames.
It blocks battery power and registered third-party antivirus when the playbook declares
`PluggedIn` and `NoAntivirus`; an unavailable provider does not count as a pass.
`-Unattended` suppresses prompts without bypassing these requirements. It copies the extracted payload into a fresh
directory beneath `C:\Windows\AtlasOS\Staging` created with a from-birth DACL that only
SYSTEM and Administrators can write, records the requested options in `request.json`
beside it, and calls the TrustedInstaller broker twice with the closed `Install`
operation. The native launcher accepts that operation only for a payload root beneath
the protected staging root whose owner and writers are trusted, exactly as it protects
the installed tree for toggles.

Direct entry verifies preparation before capture using the same Windows/Store provider
worker embedded in the app. Online Windows scans must find no required updates;
Microsoft Store must be registered for the installing user and return no outstanding
updates or active queue items. Connectivity must be unrestricted, and neither Windows
nor deferred file operations may require a restart. Required Windows Security switches
are checked independently. An unavailable provider blocks installation.

The verifier does not download or install updates. The Store API queues newly found
updates paused even with automatic downloads disabled; finish those updates in Atlas
or Microsoft Store before retrying. The ordinary preparation pass resumes that queue.
Verification runs anew in a protected staging directory and does not accept a saved
completion receipt. SYSTEM/session-zero execution and elevation as a different user
are rejected: the Store check must belong to the signed-in Windows session owner.
The legacy `-WindowsSetup` direct route is unsupported; ISO setup must reach that
user's sign-in and use the normal preparation flow.

`Install\Invoke-AtlasInstallSession.ps1` runs as TrustedInstaller from the staging copy.
Its Capture phase validates the request against the option groups playbook.conf
declares, decides Fresh, Upgrade or Reapply from the machine state document, begins the
install state and records the options. A legacy installation must have a version
declared in `UpgradableFrom`; a payload directory alone cannot establish eligibility.
An interrupted capture replaces its complete choice set. Once a run starts, retries
retain the original choices and completed steps. The app/standalone entry rejects
changed choices; AME's incremental capture rejects added choices but retains prior
choices if they are omitted on retry. The front door then publishes the installing
user's marker from its own session, and the Run phase commits the state and executes
`Entry\Invoke-AtlasInstall.ps1 -Run`. A failed run keeps the staging copy so the same
command resumes the plan; a successful one removes it.

## The machine state document

After an install completes, everything Atlas knows about the machine lives in one
document, `C:\Windows\AtlasOS\state.json`, owned by
[Atlas.State](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.State/Atlas.State.psm1):
the installed version, the mode that produced it, an install history, the selected
options, and the recorded AtlasDesktop toggle states. Install completion writes the
install facts; the toggle engine mirrors every recorded toggle state into it and rebuilds
that view whenever the Defaults phase initializes or replays the toggle store. Writes take
one global mutex and replace the file atomically; reads are schema-checked, so a
malformed document is an error rather than trusted input.

Recorded toggle states mean Atlas applied that choice's machine work and queued its user
work for first sign-in. Fresh installs do not seed states from launcher defaults. The
`(default)` launcher labels live in toggle definitions; they are not evidence of applied
work. Existing records from older releases remain replayable because seeded defaults
cannot be distinguished from user choices. An RC installed with the former `DEFAULT.reg`
seed needs a clean VM install to validate fresh/upgrade parity under this contract.

`Get-AtlasContext` reads the document for post-install mode, options and version, and the
health check, support bundles and the Toolbox app read the same file. The
`AtlasModules\Flags` files and the registry toggle tree are still written for consumers
listed in [compatibility.md](compatibility.md); no Atlas code prefers them.

## Verification and the health check

Apply and verify share one vocabulary. Every `Registry`, `Services` and `ScheduledTasks`
declaration that a tweak or toggle state applies can be read back:
`Test-AtlasRegistryEntries` (Atlas.Registry), `Test-AtlasServiceEntries` (Atlas.Services)
and `Test-AtlasScheduledTaskEntries` (Atlas.TasksProcs) return one drift record per
declaration that no longer holds, with the reason. `Test-AtlasToggleState` and
`Test-AtlasToggleDrift` (Atlas.Toggles) verify one state or every recorded state against
the installed definitions; `Test-AtlasTweak` and `Test-AtlasTweakCategory` (Atlas.Tweaks)
do the same for install tweaks, honouring each tweak's applicability gates. Companion
functions and `Run` entries are imperative and are not verified.

Registry entries may declare `SkipVerification` with a non-empty reason when they only
initialize transient Windows state. They still apply normally, but are excluded from
drift checks; verbose registry verification explains each exclusion. Durable settings
beside them remain verified. `AllowOsProtected` only tolerates refused writes and does
not exclude verification.

Machine registry defaults may declare `VerifyWithToggle` with a toggle `Name`, integer
`State`, and a `Set` (`Type`/`Data`) or `Delete` expectation. The health check supplies
recorded toggle states to tweak verification. A matching recorded choice changes only
the read-back expectation; no record or another state retains the install default.
The check is still performed, so an incorrect override remains drift. This metadata
does not change registry application and cannot infer current-user preferences from
machine records. Location and Copilot use it for their explicit enable choices.

Scheduled-task changes check the scheduler's `Enabled` property before and after
`schtasks.exe`, logging the verified result. Only missing-task HRESULTs are tolerated;
access failures, nonzero change exits and mismatched results fail the operation unless
the declaration explicitly allows errors. Verification uses the same language-neutral
property rather than interpreting localized command output.

`UseGroupPolicy = $true` routes HKLM `Software\Policies` DWORD Set entries through
`IGroupPolicyObject`, preserving unrelated local policy settings and saving the local
GPO through Windows. Atlas checks `gpupdate` and verifies the effective registry value
before reporting success. Widgets uses this route for `AllowNewsAndInterests`; the
device policy covers its taskbar entry as well as the board.

Search indexing stages URLs under `HKLM\SOFTWARE\AtlasOS\Search` while WSearch is
stopped, then applies them through `ISearchCrawlScopeManager` after starting the service.
Applying Minimal or Full replaces previous user scope overrides with Windows defaults
and the selected preset; administrator Group Policy remains authoritative. Includes
end in a directory separator and exclusions in `\*`, as described in Microsoft's
[scope rule format](https://learn.microsoft.com/en-us/windows/win32/search/-search-3x-wds-extidx-csm-scoperules).
After `SaveAll`, Atlas reopens the scope manager and verifies effective inclusion and
exclusion. Windows owns the Gather scope records and CurrentPolicies cache; Atlas does
not edit them or reset Search setup. `Get-AtlasIndexScopeState` reads effective scope
for report probes without creating files or changing configuration.

[Entry\Test-AtlasHealth.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Test-AtlasHealth.ps1)
is the user-facing check, shipped as the AtlasDesktop launcher
`9. Troubleshooting\Check Atlas Health.cmd`. It reads the state document, verifies every
recorded toggle state and every applicable tweak in machine scope and in the calling
user's own HKCU scope, and prints or (`-Json`) emits the report. It changes nothing; exit
code 1 means drift was found, 2 means Atlas is not installed or the check could not run.
The Defaults phase runs the same toggle verification after an upgrade replays the recorded
states and logs anything that still drifts, which is how a declaration the new Windows
build no longer honours becomes visible.

## Install state

[Atlas.InstallState](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.InstallState/Atlas.InstallState.psm1)
uses one bounded JSON document and one mutex. Its default paths are:

| Path | Meaning |
| --- | --- |
| C:\Windows\AtlasOS\Install\active.json | Active Capturing or Running install |
| C:\Windows\AtlasOS\Install\active.json.bak | Last valid state used for simple recovery |
| C:\Windows\AtlasOS\Install\work | Small temporary data owned by the active install |
| C:\Windows\AtlasOS\Install\last.json | Completed diagnostic record |

The active document contains schema version, target version, transaction ID,
status, mode, OOBE state, selected options, installing-user SID and session,
capture nonce, completed step names, and the last error. It does not contain a
second workflow model.

The lifecycle is:

1. Begin creates Capturing state. A retry reuses an active state only when the
   target version, install mode, and OOBE scope match; a conflicting Begin is rejected.
2. Option and user capture add facts while Capturing. On a retry, a matching user
   may refresh only the session ID; a different SID is rejected.
3. Commit changes the state to Running. Captured mode, OOBE state, options, and
   user identity are no longer reclassified by later AME calls.
4. Successful steps add their key to completedSteps. A failing action records its
   error without completing the key.
5. Completion requires every applicable plan key, publishes the installed
   compatibility flags, writes last.json, and removes active.json, its backup,
   and the work directory.

State writes use a temporary file, replacement, and a global named mutex.
If the primary document is malformed and its backup is valid, the module restores
the valid backup. The active document is the complete resume model; there are
no parallel phase records or operator reconciliation states.

### Retry semantics

Each plan entry has one replay mode:

- Once runs until it succeeds, then skips on later attempts.
- Always runs whenever control reaches it on every attempt, even if it completed
  before. These steps are small and idempotent lifecycle operations.

An Always entry is still ordered within the plan; it is not a hidden finally
handler. A retry resumes the same plan, reruns the lifecycle entries it reaches,
skips completed Once entries, and retries the first incomplete work.

## One plan and one orchestrator

[Install-Plan.ps1](../playbook/Executables/AtlasModules/Scripts/Install/Install-Plan.ps1)
contains the only ordered install table. It filters records by Fresh, Upgrade, or
Reapply and by normal or OOBE execution.

| Ordered work | Modes | OOBE | Replay |
| --- | --- | --- | --- |
| DefaultHiveLoad | All | Included | Always |
| PayloadReplacement | All | Included | Always |
| NotificationDisable | All | Included | Always |
| PreInstall | All | Included | Once |
| ShellRefresh | All | Excluded | Once |
| Environment | All | Included | Once |
| Tweak: qol/set-hidden-settings-pages | Fresh | Included | Once |
| InitializePath | All | Included | Once |
| Features | All | Included | Once |
| Software | All | Included | Once |
| Services | Fresh | Included | Once |
| Components | Fresh | Included | Once |
| AppxSupport | Fresh | Included | Once |
| Defaults | All | Included | Once |
| Revert | Upgrade | Included | Once |
| Tweak: qol/appearance/atlas-theme-upgrade | Upgrade | Included | Once |
| Tweaks: networking, performance, privacy, qol, security, debloat, scripts, misc | Fresh | Included | Once |
| Tweak: scripts/set-power-settings | Fresh | Included | Once |
| InstallingUserSetup | Fresh | Excluded | Once |
| OemBranding | Upgrade | Included | Once |
| NotificationRestore | All | Included | Always |
| DefaultHiveUnload | All | Included | Always |

All means Fresh, Upgrade, and Reapply. Reapply receives only the common work; it
does not inherit fresh-only or upgrade-only actions.

Fresh OOBE applies the machine and default-user parts of every tweak category.
It intentionally has no installing-user identity, so live-user registry work,
ShellRefresh, and InstallingUserSetup remain excluded. The default profile is
seeded with the Atlas first-logon RunOnce entry; Initialize-NewUser later performs
the session-bound work under the exact user at that user's first sign-in. This
keeps OOBE useful without pretending that an interactive user token exists.

[Entry\Invoke-AtlasInstall.ps1](../playbook/Executables/AtlasModules/Scripts/Entry/Invoke-AtlasInstall.ps1)
reads the committed state, obtains this plan, and dispatches only four closed
record kinds:

- Phase maps a known phase name to Install\Phases\Invoke-NamePhase.ps1.
- TweakCategory (`Tweaks/<category>`) maps a known category to Invoke-TweaksPhase.ps1.
- Tweak (`Tweak/<slug>`) maps one Standalone manifest tweak to Invoke-TweaksPhase.ps1
  with `-Slug`; these are tweaks whose position in the plan lies outside the category
  order. A standalone tweak runs its machine and default-user passes only.
- Checkpoint maps a known lifecycle name to a fixed Install\Tasks script.

The orchestrator starts from the extracted source payload. After
PayloadReplacement succeeds or is already complete, subsequent actions use the
installed C:\Windows\AtlasModules\Scripts tree. When all applicable keys have
completed, the orchestrator calls Complete-AtlasInstallState directly. There is
separate finalization phase; the active state and completed plan keys are the resume
record.

Install actions return to the orchestrator rather than terminating its process.
The outer exit code remains 0 for success, 1 for an install failure, and 2 for
the wrong privilege. custom.yml halts on any nonzero result.

### Phase responsibilities

| Phase | Main responsibility |
| --- | --- |
| PreInstall | Remove obsolete Atlas elevation artifacts (Install\Compat) and perform bounded machine/user cleanup |
| ShellRefresh | Refresh the exact installing user's shell outside OOBE |
| Environment | Apply environment and runtime configuration |
| Features | Apply Windows capabilities and optional features |
| Software | Install selected utilities and browsers; Toolbox resolves the latest stable release at install time and is not pinned to the playbook version |
| Services | Back up Windows services, then apply the File Sharing, Location and Indexing defaults as the machine part of those toggles, recording each |
| Components | Apply machine component and browser cleanup |
| AppxSupport | Apply installed/provisioned AppX changes and exact-user cache work |
| Defaults | Initialize the toggle state store on fresh installs; replay recorded toggles on upgrades |
| Revert | Run upgrade-only repair work |
| Tweaks | Apply one declarative category, or one standalone tweak, in explicit machine, current-user, and default-user scopes |

## Identity and registry scopes

### Installing-user identity

Entry\Publish-AtlasInstallUser.ps1 writes a nonce, the current token SID, and the
current process session ID beneath HKCU\Software\AtlasOS\InstallSession.
TrustedInstaller accepts exactly one marker matching the active capture nonce,
checks that the marker SID equals its HKEY_USERS hive, binds the SID/session to
the state, and removes the marker.

Invoke-AtlasAsUser later consumes only that install-state binding. It:

- runs only from SYSTEM or TrustedInstaller context;
- asks WTS for the recorded session instead of enumerating sessions;
- verifies the returned primary token's SID and session;
- requires that user's profile hive to be loaded;
- launches only the exact inbox Windows PowerShell host with
  CreateProcessAsUser;
- waits for a bounded result and does not support detached children.

This is the user boundary for shell refresh, live HKCU work, AppX cache work, and
other install-time operations that must observe the installing user's session.

### The HKCU rule

Ambient HKCU belongs to the current process token. Atlas therefore uses three
explicit passes:

1. TrustedInstaller applies machine entries and machine companion work without
   redirecting HKCU.
2. Outside OOBE, the exact install-state-bound user process verifies its own SID
   and applies live-user entries through its ambient HKCU.
3. TrustedInstaller binds Atlas.Registry to the active transaction ID and writes
   the same applicable HKCU declarations directly to the fixed loaded
   HKU\Atlas_DefaultUser hive.

The default-user pass accepts only strict TrustedInstaller identity, an active
install-state transaction, and the fixed hive mount. Other live-user HKEY_USERS
targets are rejected. The writes occur during the owning tweak category instead
of being queued for a later registry pass.

DefaultHiveLoad and DefaultHiveUnload bracket every plan. The orchestrator records
mount ownership only after Atlas successfully loads the hive. A best-effort
finally cleanup unloads an Atlas-owned mount after a later failure; it never
unloads a mount this invocation did not create. At successful completion Atlas
replaces the installed flag set with the applicable
Upgrade.flag, Interactive.flag, and option-*.flag files. These flags preserve the
post-install compatibility contract after active state is archived; they do not
drive the current install plan, which requires install state.

## Notification lifecycle

Notification suppression is one small machine-policy transaction. Before setting
NoToastApplicationNotification to DWORD 1, Install\Tasks\Set-NotificationState.ps1
stores exactly two values in work\notification.json: whether the policy existed and
its previous DWORD value.

On a retry, Disable validates and reuses the existing snapshot instead of
overwriting the original state. Restore writes back the prior value or removes
the value when it was originally absent, verifies the result, and deletes the
snapshot only after success. The install-state work directory is removed after
the plan completes. There is no per-user notification path.

## Privileged post-install operations

The install orchestrator already runs as TrustedInstaller through the AME
handoff. User-facing post-install tools use Atlas's native TrustedInstaller
broker (Entry\Invoke-AtlasTrustedInstallerBroker.ps1) instead of an arbitrary
RunAsTI launcher.

The public broker accepts typed Toggle, ResetServices and Install operations. Toggle
and ResetServices map to fixed installed entry points: Entry\Invoke-Toggle.ps1 and
Entry\Restore-AtlasServiceDefaults.ps1. Install maps to the protected staging copy of
Install\Invoke-AtlasInstallSession.ps1 described in the front-door flow above.
Its process contract is deliberately small:
the target's exit code is returned to the caller, and validation or execution
diagnostics are written to standard error. Internal native launch evidence is not
part of the public protocol. Feature implementation remains in the shared
PowerShell modules and toggle definitions. Scripts\RunAsTI.cmd remains only as a
deny-only compatibility stub for obsolete shortcuts (see
[compatibility.md](compatibility.md)).

## Safe Mode and CBS retry

[Operations\SafeMode.ps1](../playbook/Executables/AtlasModules/Scripts/Operations/SafeMode.ps1)
implements four explicit operations: Minimal, Networking, CommandPrompt, and
Exit. It uses the fixed System32 bcdedit.exe and stores only the prior Winlogon
shell needed to undo CommandPrompt mode in
C:\Windows\AtlasOS\Recovery\SafeMode.json.

[Operations\CbsRetry.ps1](../playbook/Executables/AtlasModules/Scripts/Operations/CbsRetry.ps1)
owns failed CBS package recovery:

1. Atlas records absolute package paths in
   C:\Windows\AtlasOS\Recovery\CbsRetry.json.
2. The state moves from Pending to Armed after CommandPrompt Safe Mode is set.
3. CbsRetry.ps1 -Recover exits Safe Mode and invokes the existing
   Atlas.Software CBS installer with those literal paths.
4. The state file is removed only after the retry succeeds.

One mutex serializes the retry. Payload replacement refuses to run while CBS
retry state is present, so it cannot replace the installer needed for recovery.
There is no hidden scheduled task or AME task runner in this flow; recovery is
an explicit -Recover operation.

## PowerShell modules

| Module | Responsibility |
| --- | --- |
| Atlas.Core | Data-file loading, sibling module import, active install-state context, post-install flag compatibility, logging, privilege checks, exact-user launch, the native TrustedInstaller broker, and the native type loader |
| Atlas.State | The machine state document: installed version, history, options and the toggle view |
| Atlas.InstallState | Compact capture, persistence, step replay, and completion into the state document |
| Atlas.Registry | Typed registry operations, explicit current-token/default-user identity scopes, declarative registry entries and their verification, Windows PowerShell execution policy |
| Atlas.Services | Service startup changes, declarative service entries and their verification, service backup/restore |
| Atlas.TasksProcs | Scheduled task and process helpers, declarative scheduled-task entries and their verification |
| Atlas.Tweaks | Declarative tweak loading, validation, applicability, scoped execution, and verification |
| Atlas.Toggles | Toggle definition loading and validation, the toggle engine, the state store, upgrade/first sign-in replay, and drift verification |
| Atlas.Download | Bounded HTTPS downloads, protected staging, contained native execution, GitHub release resolution, trusted WinGet resolution |
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

Settings implementations live in these modules; a toggle companion, a tweak companion
script or an entry script imports the module (`Import-AtlasModule` inside companions)
and calls the function. A companion function never shares a name with the module
function it calls, so it cannot shadow it. `Scripts\Operations` keeps only scripts that
are process boundaries by nature: bodies run as a contained or elevated child, package
transactions, and user-context bodies that Windows or a launcher invokes by path.

## Native code

Every P/Invoke and COM interop declaration Atlas needs lives in one file,
[Atlas.Core\Native\Atlas.Native.cs](../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.Core/Native/Atlas.Native.cs),
under the `Atlas.Native` namespace. `Initialize-AtlasNativeType` (Atlas.Core) loads it
once per process. When a prebuilt `Atlas.Native.dll` with a valid Authenticode signature
ships beside the source it is loaded as is; otherwise the source is compiled in place. In
a high-integrity process the compile runs through a random, from-birth-ACL'd directory
under the system profile with TEMP redirected for its duration, so a requester-writable
temp directory never participates in code that will run as SYSTEM or TrustedInstaller.
Low-integrity processes compile directly. Callers never call Add-Type themselves.

`tools\native\Build-AtlasNative.ps1` builds that DLL deterministically with the Roslyn
compiler (same source and compiler, byte-identical output), records its SHA-256, and
signs it when given a code-signing certificate. No DLL ships today: the project has no
signing certificate, and an unsigned DLL is deliberately ignored by the loader, so the
payload keeps compiling from source until one exists.

## Tweaks and AtlasDesktop toggles

A setting has one implementation. The two declarative surfaces that call it are:

- Install tweaks: data-only PSD1 definitions under Scripts\Tweaks\category, ordered by
  tweaks.manifest.psd1. The [tweak schema](../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md)
  describes registry entries, services, scheduled tasks, applicability, companion
  scripts, post-user-registry refresh declarations, and the `Toggle` key, which applies
  and records the machine part of an AtlasDesktop toggle state during the install.
- AtlasDesktop toggles: data-only PSD1 definitions under AtlasModules\Toggles\Group,
  each with an optional companion script that contains only functions. The
  [toggle schema](../playbook/Executables/AtlasModules/Toggles/README.md) uses the same
  Registry, Services and ScheduledTasks vocabulary plus named companion functions.

Windows refuses a small number of policy value writes outright: the key opens for
writing and the kernel then denies the value, for every caller including
TrustedInstaller. A registry entry that expects this declares `AllowOsProtected`, which
turns that one condition into a logged warning instead of a failed install, and only that
condition. The health check still reports the value as drift, so a refusal is visible
rather than silent. Every other registry failure remains fatal and now names the exact
entry that failed.

The toggle engine derives where each part of a state runs from the declarations. HKLM
registry entries, services, scheduled tasks and `MachineAction` are machine work,
which runs under the declared elevation and is recorded under
HKLM\SOFTWARE\AtlasOS\Services after it completes. HKCU entries and `UserAction` are
user work, which runs in the launching user's own non-elevated process after the
machine part succeeds. A state with user work must therefore be launched
unelevated: the engine runs the machine part in a UAC child (or through the
TrustedInstaller broker) and finishes the user part locally, so user work can never
inherit an elevated token. An `Elevation = 'None'` toggle runs everything locally and
records nothing. Upgrades replay every recorded state's machine part from the installed
definition, and each account's first sign-in replays the user parts. The state store
never persists executable paths.

Every AtlasDesktop and Toolbox `.cmd` is a generated two-line stub that calls
Scripts\Entry\Invoke-AtlasToggleLauncher.cmd with the toggle name, the state and its
own path. The shared body anchors to the protected command host, sanitizes the
environment, validates the flag grammar (`/silent`, `/quiet`, `/justcontext`,
`/noaction`) before Windows PowerShell starts, and runs Entry\Invoke-Toggle.ps1.
`tools\dev\New-ToggleLaunchers.ps1` regenerates and validates the stubs from the
definitions without executing any toggle code.

What an interactive run prints is owned by the engine and the console vocabulary in
Atlas.Core (`Domain\Ui.ps1`): the Atlas heading, the warning gate a definition
declares, the numbered menu, one closing line derived from the run outcome (`Done:`,
`Not finished yet:` or `Partly done:`), the restart follow-up and the single exit
pause. Companions and nested helpers only add steps, questions and facts through the
same helpers, and the interactive entry points switch `Write-AtlasLog` to its
`Interactive` console style so diagnostics stay in the log file while warnings and
errors still reach the user. Silent, replay and broker runs keep the diagnostic echo.
[console-presentation.md](console-presentation.md) specifies the vocabulary, the
ownership rules and the rendered examples.

### Generated catalog

The definitions are the only hand-written description of what Atlas can do.
`tools\dev\Export-AtlasCatalog.ps1` derives everything that lists them:
`Toggles\catalog.json` in the payload (every toggle, its states, launchers, elevation and
state values; the machine-readable contract for AtlasToolbox and other consumers) and the
generated references under [docs/catalog](catalog/toggles.md). Output is deterministic
and CI validates that the committed files match the definitions.

### Start and taskbar pins

Atlas deliberately configures Start and taskbar pins as part of its user setup.
The exact-user setup also creates the user's `Atlas.lnk` desktop shortcut with
the Atlas folder icon, then refreshes that user's Explorer session after the
taskbar pin database is committed so the running File Explorer window groups
under its canonical pin. The generated File Explorer shortcut carries the
`Microsoft.Windows.Explorer` AppUserModelID in its Shell property store; the
taskbar uses that identity to associate Explorer windows with the pin.
For later accounts, the two-stage RunOnce setup removes its retry before the
stage-two Explorer refresh, preventing the restarted shell from launching a
concurrent initializer. Its delayed search finalizer runs without a redundant
transcript and shows the ready notification only after the final shell refresh.
The same exact-user path also performs safe OneDrive registration and leftover
cleanup for each new account without deleting a sync root that contains files.
Start uses the Windows policy surface. Atlas checks the servicing level that
introduced the local policy and emits a clear warning when the current system is
too old; the validated layout and default-profile cleanup still run so a later
cumulative update can consume the configuration.

Windows exposes no equivalent stable API for Atlas's taskbar layout, so the
taskbar binary values are an intentional compatibility payload rather than a
general data model. Atlas keeps the payload within the playbook's supported-build
boundary, checks every native registry write, and fails the user-setup checkpoint
rather than recording false success when a value cannot be applied. An unavailable
selected browser falls back to Edge and then to an Explorer-only layout. Temporary
shortcut staging is always removed. Captured values are reviewed and
compatibility-tested when supported Windows builds change; they are not silently
assumed portable across every shell version or user profile.

## Packaging

The APBX is a password-protected ZIP assembled by tools\build\AtlasBuild.
Building uses a unique temporary output, verifies the archive before
publication, and replaces the destination only after verification succeeds.
tools\build\Test-Apbx.ps1 checks archive integrity, root layout, configuration,
and exact payload parity.

SxS CABs under tools\sxsc are built as review-only CI candidates and committed
to the playbook payload separately after review. Their package versions are
independent of the Atlas playbook version.

See [building.md](building.md), [testing.md](testing.md) and
[compatibility.md](compatibility.md) for developer workflows and the compatibility
boundary.
