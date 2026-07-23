# Atlas architecture

Atlas is a Windows optimization playbook packaged as an APBX and applied by AME
Wizard. AME supplies the package runtime, FeaturePage selections, OOBE/ISO
applicability, and the initial execution identities. Atlas owns the installation
workflow in PowerShell. AME tasks are not an Atlas execution framework: the YAML
handoff invokes fixed PowerShell entry points and does not contain the feature
workflow.

The current design is intentionally small:

- custom.yml captures AME facts and starts one installer.
- Atlas.InstallState stores only the facts and progress needed to resume.
- Install-Plan.ps1 is the single ordered applicability table.
- Invoke-AtlasInstall.ps1 is the single install orchestrator.
- Machine, installing-user, and default-user work have explicit identity scopes.
- Native helper boundaries are retained where Windows privileges or sessions
  genuinely require them; ordinary feature logic stays in ordinary PowerShell.

## Repository layout

~~~
/
├─ playbook/
│  ├─ playbook.conf
│  ├─ Configuration/
│  │  └─ custom.yml
│  └─ Executables/
│     └─ AtlasModules/
│        ├─ Scripts/
│        │  ├─ Invoke-AtlasInstall.ps1
│        │  ├─ Invoke-Toggle.ps1
│        │  ├─ Internal/
│        │  ├─ Modules/Atlas.*/
│        │  ├─ Phases/
│        │  ├─ Tasks/
│        │  └─ Tweaks/
│        └─ Toggles/
├─ tools/
│  ├─ build/
│  ├─ dev/
│  ├─ release-zip/
│  └─ sxsc/
├─ tests/
└─ docs/
~~~

Every non-generated file below playbook ships in the APBX. There is no separate
payload manifest or build-time source mapping. The APBX verifier compares source
and archive paths and rejects missing, extra, or changed payload files.

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
| Invoke-AtlasInstall.ps1 -Run | TrustedInstaller | Execute the complete live install plan |

The current-user action publishes identity only. It does not run install work,
elevate the account, or select a different session. OOBE has no installing-user
marker.

The WdBoot action is intentionally outside the PowerShell plan because it targets
an offline mounted image. It is unreachable during a live installation. All other
live work is owned by the one TrustedInstaller PowerShell process.

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

[Install-Plan.ps1](../playbook/Executables/AtlasModules/Scripts/Internal/Install-Plan.ps1)
contains the only ordered install table. It filters records by Fresh, Upgrade, or
Reapply and by normal or OOBE execution.

| Ordered work | Modes | OOBE | Replay |
| --- | --- | --- | --- |
| DefaultHiveLoad | All | Included | Always |
| PayloadReplacement | All | Included | Once |
| NotificationDisable | All | Included | Always |
| PreInstall | All | Included | Once |
| ShellRefresh | All | Excluded | Once |
| Environment | All | Included | Once |
| HiddenSettingsPages | Fresh | Included | Once |
| InitializePath | All | Included | Once |
| Features | All | Included | Once |
| Software | All | Included | Once |
| Services | Fresh | Included | Once |
| Components | Fresh | Included | Once |
| AppxSupport | Fresh | Included | Once |
| Defaults | All | Included | Once |
| DefaultRegistrySeed | Fresh | Included | Once |
| Revert | Upgrade | Included | Once |
| Tweaks: networking, performance, privacy, qol, security, debloat, scripts, misc | Fresh | Included | Once |
| PowerSettings | Fresh | Included | Once |
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

[Invoke-AtlasInstall.ps1](../playbook/Executables/AtlasModules/Scripts/Invoke-AtlasInstall.ps1)
reads the committed state, obtains this plan, and dispatches only three closed
record kinds:

- Phase maps a known phase name to Phases\Invoke-NamePhase.ps1.
- TweakCategory maps a known category to Invoke-TweaksPhase.ps1.
- Checkpoint maps a known lifecycle name to a fixed internal or task script.

The Checkpoint record kind describes a fixed lifecycle action in the table; it
does not introduce another persistence model. The orchestrator starts from the
extracted source payload.
After PayloadReplacement succeeds or is already complete, subsequent actions use
the installed C:\Windows\AtlasModules\Scripts tree. When all applicable keys have
completed, the orchestrator calls Complete-AtlasInstallState directly. There is
no InstallJournal, separate finalization phase, or proof framework; the active
state and completed plan keys are the resume record.

Install actions return to the orchestrator rather than terminating its process.
The outer exit code remains 0 for success, 1 for an install failure, and 2 for
the wrong privilege. custom.yml halts on any nonzero result.

### Phase responsibilities

| Phase | Main responsibility |
| --- | --- |
| PreInstall | Remove obsolete Atlas elevation artifacts and perform bounded machine/user cleanup |
| ShellRefresh | Refresh the exact installing user's shell outside OOBE |
| Environment | Apply environment and runtime configuration |
| Features | Apply Windows capabilities and optional features |
| Software | Install selected utilities and browsers; Toolbox resolves the latest stable release at install time and is not pinned to the playbook version |
| Services | Back up and apply Atlas service startup choices |
| Components | Apply machine component and browser cleanup |
| AppxSupport | Apply installed/provisioned AppX changes and exact-user cache work |
| Defaults | Apply default configuration or supported toggle replay |
| Revert | Run upgrade-only repair work |
| Tweaks | Apply one declarative category in explicit machine, current-user, and default-user scopes |

## Identity and registry scopes

### Installing-user identity

Publish-AtlasInstallUser.ps1 writes a nonce, the current token SID, and the
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
NoToastApplicationNotification to DWORD 1, Set-NotificationState.ps1 stores
exactly two values in work\notification.json: whether the policy existed and its
previous DWORD value.

On a retry, Disable validates and reuses the existing snapshot instead of
overwriting the original state. Restore writes back the prior value or removes
the value when it was originally absent, verifies the result, and deletes the
snapshot only after success. The install-state work directory is removed after
the plan completes. There is no per-user notification path or generic recovery
abstraction.

## Privileged post-install operations

The install orchestrator already runs as TrustedInstaller through the AME
handoff. User-facing post-install tools use Atlas's native TrustedInstaller
broker instead of an arbitrary RunAsTI launcher.

The public broker accepts only typed Toggle and ResetServices operations and maps
them to fixed installed entry points. Its process contract is deliberately small:
the target's exit code is returned to the caller, and validation or execution
diagnostics are written to standard error. Internal native launch evidence is not
part of the public protocol. Feature implementation remains in the shared
PowerShell modules and toggle definitions. RunAsTI.cmd remains only as a deny-only
compatibility stub for obsolete shortcuts.

## Safe Mode and CBS retry

[SafeMode.ps1](../playbook/Executables/AtlasModules/Scripts/Internal/SafeMode.ps1)
implements four explicit operations: Minimal, Networking, CommandPrompt, and
Exit. It uses the fixed System32 bcdedit.exe and stores only the prior Winlogon
shell needed to undo CommandPrompt mode in
C:\Windows\AtlasOS\Recovery\SafeMode.json.

[CbsRetry.ps1](../playbook/Executables/AtlasModules/Scripts/Internal/CbsRetry.ps1)
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
| Atlas.Core | Active install-state context, post-install flag compatibility, logging, privilege checks, exact-user launch, and the native TrustedInstaller broker |
| Atlas.InstallState | Compact capture, persistence, step replay, and completion |
| Atlas.Registry | Typed registry operations and explicit current-token/default-user identity scopes |
| Atlas.Tweaks | Declarative tweak loading, validation, applicability, and scoped execution |
| Atlas.Services | Service startup changes and service backup/restore |
| Atlas.Appx | Installed/provisioned AppX operations and exact-user cache work |
| Atlas.TasksProcs | Scheduled task and process helpers |
| Atlas.Software | Software/browser installers and CBS package operations |
| Atlas.Toggles | AtlasDesktop toggle execution and supported upgrade replay |
| Atlas.Shortcuts | Shortcut creation |
| Atlas.Themes | Theme application |

## Tweaks and AtlasDesktop

Install tweaks are data-only PSD1 definitions under
Scripts\Tweaks\category. The
[tweak schema](../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md)
describes registry entries, applicability, optional companion scripts, and
post-user-registry refresh declarations. tweaks.manifest.psd1 owns category
ordering and enablement. The install plan calls each enabled category directly;
there are no YAML task includes.

AtlasDesktop's numbered folders are post-install tools. Each action has a
definition under AtlasModules\Toggles and a small generated CMD launcher that
calls Invoke-Toggle.ps1. The Atlas.Toggles module validates the definition,
dispatches the requested state, and records declarative state in
HKLM\SOFTWARE\AtlasOS\Services. It does not persist executable paths as replay
instructions.

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

See [building.md](building.md) and [testing.md](testing.md) for developer
workflows.
