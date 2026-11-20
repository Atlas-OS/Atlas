# Install state and records

This page is a reference for contributors.
It describes the files and registry records Atlas keeps about an install.
These are the active install state, the machine state document, the option flags and toggle records, and the records that older Atlas releases and the old Atlas Toolbox left.

For the install itself, see [Atlas architecture](architecture.md).
For what you see in Atlas Manager when you update, see [Updating Atlas](upgrading.md).

## Where Atlas keeps its records

| Location | Holds |
| --- | --- |
| `%windir%\AtlasOS\Install\active.json` | The install in progress, while it's Capturing or Running |
| `%windir%\AtlasOS\Install\active.json.bak` | The last valid copy of `active.json` |
| `%windir%\AtlasOS\Install\work` | Small temporary files the active install owns: the AppX snapshot, `notification.json` and `choices.json` |
| `%windir%\AtlasOS\Install\last.json` | The last completed install, for diagnostics |
| `%windir%\AtlasOS\state.json` | The machine state document |
| `%windir%\AtlasModules\Flags\*.flag` | Option flags kept for readers older than the state document |
| `HKLM\SOFTWARE\AtlasOS\Services\<Name>` | Toggle records |
| `HKLM\SOFTWARE\AtlasOS\SetupOptions` | The browser Atlas installed, as `browser` |
| `HKLM\SOFTWARE\AtlasOS\UpgradeUsers` | Accounts stamped for the sign-in migration |
| `HKCU\SOFTWARE\AtlasOS\UserSetup` | An account's last completed migration, as `UpgradeVersion` |
| `HKCU\Software\AtlasOS\InstallSession` | The installing user's marker, between Capture and Run |
| `HKLM\SOFTWARE\AtlasOS\WindowsTransition` | Atlas Manager's record of the Windows Update settings it changed (see [Moving Windows to a newer release](windows-transition.md)) |
| `HKLM\SOFTWARE\AtlasOS\Preparation` | Updates the **Get ready** page no longer waits for (see [Preparing Windows](preparation.md)) |
| `HKLM\SOFTWARE\AtlasOS\Toolbox` | The Atlas Toolbox installer's own record |

## The active install state

`Atlas.InstallState` keeps the install in progress in `active.json`.
The document is all a resume needs, so Atlas keeps no other record of an install's progress.

| Field | Meaning |
| --- | --- |
| `schemaVersion` | The document's schema version |
| `targetVersion` | The Atlas version being installed |
| `transactionId` | A GUID for this install |
| `status` | `Capturing`, `Running`, or `Completed` in `last.json` |
| `mode` | `Fresh`, `Upgrade`, `Reapply` or `Rebase` |
| `options` | The options the install applies |
| `choices` | The update path: `Keep` or `ChooseAgain` |
| `userSid`, `userSessionId` | The installing user, once Run has bound them |
| `captureNonce` | The value the installing user's marker must carry |
| `completedSteps` | The plan keys that have finished |
| `lastError` | The last step's failure, cut at 4,096 characters |

A document without `choices` comes from a release older than the update path, and keeps the choices.
A document an older Atlas release wrote can carry `isOobe`, which nothing reads, so Atlas drops it when it reads the document.

Every read and write takes the global mutex `Global\AtlasOS.InstallState.v1`, waiting up to 30 seconds.
A write goes to a temporary file that then replaces the document, keeping the old one as `active.json.bak`.
Reads are schema-checked.
When `active.json` is malformed and the backup is valid, Atlas restores the document from the backup.

### How an install moves through it

1. **Capture starts the state.**
   `Start-AtlasInstallState` creates a `Capturing` document with a new transaction ID and capture nonce, or returns the active one for the same target version.
   An active install of another version is refused, and so is another mode, with a message that names the unfinished install and how to finish it.
   `Resolve-AtlasInstallMode` returns the active document's mode, so a retry resumes the install it began.
2. **Capture records the options.**
   While no step has completed, a new capture replaces the options and the update path with the new request's.
   Once a step has completed, the options can't change, and a different set is refused with the options the run started with.
3. **Run binds the installing user.**
   It finds the one marker that carries the capture nonce and records that user's SID and session.
   A resume from the same account updates the session ID, and one from another account is refused.
4. **Run commits the state.**
   The status becomes `Running`.
5. **The plan runs its steps.**
   A step that succeeds adds its key to `completedSteps`, and one that fails records `lastError` and leaves its key out.
   The lock isn't held while a step runs, so a step can start a user process that reads the state.
6. **Completion closes the install.**
   It requires every key the plan applies, records what the PC has (see [What Atlas records](#what-atlas-records)) and writes `last.json`.
   It then removes `active.json`, its backup and the `work` folder.

### Replay

Each step in the plan has a replay rule.

| Replay | Behaviour |
| --- | --- |
| `Once` | Runs until it succeeds, then a resume skips it. |
| `Always` | Runs on every attempt that reaches it, even if it completed before. Only small lifecycle steps that are safe to repeat use it. |

A resume runs the same plan and starts again at the first incomplete step.
`Always` steps keep their place in the order.
After a failure, the orchestrator still puts back the notification policy and unloads the default-user hive when this attempt loaded it.

## What Atlas records

The options in `state.json` describe what the PC has, which can differ from what was asked for.

### At completion

Once the plan has run, completion reads the PC with `Get-AtlasRecordedOption` and takes each choice the PC shows from the PC.
It reads the apps installed for every account in Windows's profile list, including Microsoft and work or school accounts, and the installing user's keyboard settings.

- An app that's only staged, waiting for Windows to finish removing it, or registered only to SYSTEM or a deleted account doesn't count, because nobody can open it.
- A Toolbox or browser that isn't installed afterwards is left out.
- A Defender package that Windows installs or removes at the restart this install asks for already counts.
- A reading that fails leaves the request for the choices it covers, with a warning.

Each choice recorded differently from the request gets a log line, such as `Recorded 'defender-disable' for Microsoft Defender instead of the requested 'defender-enable': ...`.
`last.json` keeps the request as `options` and what was recorded as `recordedOptions`.

Completion also writes `notApplied` into this install's `history` entry in `state.json`.
It lists the options of each choice the plan tried to apply that the PC doesn't have as asked.
Atlas Manager's completion window names those choices.
A choice recorded differently only because nothing in the plan changes it isn't listed.
Examples are VBS that was already off when a first installation leaves its box clear, or Snipping Tool on another account when an update keeps the choices.
When completion couldn't read the PC at all, the entry has no `notApplied`.

### Between installs

The six choice toggles keep their install choice in step in the same write, whether they run from the Atlas folder or Atlas Toolbox.
They are Mitigations, AutomaticUpdates, KeyboardShortcuts, Hibernation, PowerSaving and VbsState.

**Toggle Defender** sets the Defender choice for the restart it asks for.
**Install or Remove Edge** sets the Edge choice by whether Edge is installed afterwards, and keeps `option-uninstall-edge.flag` in step.
A new account's setup reads that flag to decide whether to clean its Edge data.

None of them sets a choice while `active.json` exists, because completion records what the PC has, or before any install has completed.
A choice that can't be written is a warning, and the next install records what the PC has.

When Atlas's record keeps Microsoft Defender but Atlas's NoDefender package still removes it, Atlas Manager warns that **Microsoft Defender is still removed**.
An earlier update can leave a PC this way.

## The machine state document

`%windir%\AtlasOS\state.json`, written by `Atlas.State`, holds what Atlas knows about an installed PC.

| Field | Holds |
| --- | --- |
| `installedVersion`, `installedAt`, `mode` | The installed Atlas version, when it completed and the mode that installed it |
| `options` | What the PC has for each install choice |
| `history` | One entry per completed install: `version`, `mode`, `completedAt`, `transactionId` and, when completion read the PC, `notApplied` |
| `toggles` | Each recorded toggle state, as `state` and `updatedAt` |
| `isOobe`, `isInteractive` | Kept for readers of schema 1. Completion writes `false` and `true`, because Atlas installs only from a signed-in session. |

- Install completion writes the install facts.
- The toggle engine mirrors each recorded toggle state, and rebuilds the whole view when the Defaults phase sets up or replays the store.
  A toggle's `updatedAt` says when it was set to that state, so a replay that keeps the state doesn't change it.
- Writes take the global mutex `Global\AtlasOS.State.v1` and replace the file atomically.
- Reads are schema-checked, and a document with unknown fields is refused, so a malformed file is reported as an error.

`Get-AtlasContext`, the health check, support bundles and Atlas Toolbox read this document.

## Option flags

Completion replaces every file in `%windir%\AtlasModules\Flags` with:

- `Upgrade.flag`, on an Upgrade or a Rebase;
- `Interactive.flag`;
- `option-<name>.flag` for each recorded option.

The flags keep a contract for readers older than the state document, listed in [Files kept for compatibility](compatibility.md).
They don't decide what the plan does, and every Atlas reader uses `state.json` first.

## Toggle records

The toggle engine records each applied state under `HKLM\SOFTWARE\AtlasOS\Services\<Name>`, as the DWORD `state`, once the state's machine work has completed.
The [toggle schema](../playbook/Executables/AtlasModules/Toggles/README.md#state-record-and-replay) has the full recording and replay rules.

- A recorded state means Atlas applied that choice's machine work and queued its user work for each account's first sign-in.
- A fresh install seeds nothing from launcher defaults, so a `(default)` label isn't evidence of applied work.
- An update or reinstall replays every existing record, because the store can't tell a default an earlier build seeded from a choice you made.
- The one exception is a choice toggle that the Choices step set in the same install, which the Defaults step leaves out of its replay (see [choices.json](#choicesjson)).
- After an update replays the records, the Defaults step checks them and logs any drift, which shows declarations a newer Windows build no longer honours.
- The store never keeps executable paths.

## choices.json

When an update or reinstall chooses again, the Choices step applies each choice that differs from the PC.
It records the toggles it set in `%windir%\AtlasOS\Install\work\choices.json`.
The Defaults step leaves only those toggles out of its replay, and replays every other record as when keeping the choices.

## Records from before Atlas 0.6

Atlas Toolbox 0.1.x and the Atlas 0.5.0 launchers wrote toggle records under `HKLM\SOFTWARE\AtlasOS\Services`, not always as Atlas 0.6 reads them.
A launcher always wrote its file name as `path` beside the state.
The Toolbox's pages for Mitigations, the shortcut icon and the terminal menu never did.
They also never changed the PC, because they merged their files from a folder no Atlas install has.

On an update from a version before 0.6, Capture repairs these records once, before anything reads them, and logs each change.
A run whose plan has started doesn't repair them again.

| Record | Repair |
| --- | --- |
| `Mitigations`, `ShortcutIcon` | A record whose `path` names one of their launchers is set from that launcher's file name. A record without a `path` is removed, and nothing is replayed for it, because only the Toolbox wrote it, in its own numbering. |
| `ContextMenuTerminals` without a `path` | Takes the terminal menu the PC has, because the Toolbox numbered it differently. It's removed when the menu can't be read. |
| `FileSharing` 0 from **Enable File Sharing** | Removed. |
| `Printing` 0 from **Disable Printing** | Removed while the Print Spooler is on, because every Atlas 0.5.0 install recorded it when it only took printing off the context menu. |
| `SearchIndexing` | Removed. It records `Indexing` 0 only when the Toolbox turned search indexing off. |
| `AppIconsThumbnail`, `HightestMode` | Become `AppIconThumbnail` and `HighestMode`. When both names exist, the PC decides. |
| `Recall` in other letter case | Renamed to `Recall`. |
| The Toolbox's CPU Idle desktop menu | Removed. Without an Atlas record of that menu, the update adds Atlas's menu instead. |

**Your choices** reads the Mitigations record by the same rule.
A Mitigations record that an Atlas before 0.6 wrote counts only beside a launcher's record, and Atlas Manager asks for the choice otherwise.

The record Atlas Manager keeps while it [moves Windows to a newer release](windows-transition.md#what-atlas-records-first) reads Mitigations and ShortcutIcon by the same rule, because no update has repaired the records when it's written.
It keeps neither a record only the Toolbox wrote nor a choice that came from one.
A Rebase repairs the toggle records as Capture does, before anything reads them, including those it brings back from that record.

On every update and reinstall whose plan hasn't started, Capture also sets the `PowerSaving` record to 0 while the Atlas power plan is active.
An earlier install can leave an Enable record beside an active Atlas power plan, and replaying it would remove the plan.
Atlas Manager, and its record before a feature update, read the active plan the same way.
Other power plans don't establish this choice, and Atlas doesn't replace one because of its name.

## Sign-in migration stamps

An update or reinstall changes other accounts' ordinary settings when each person next signs in.

- On an update or a Rebase, the LegacyChoices step stamps every existing account under `HKLM\SOFTWARE\AtlasOS\UpgradeUsers` with the target version.
- On a reinstall, the installing user's setup stamps every account with the version and the install's transaction ID, so a second reinstall of the same version reaches them again.
- At sign-in, `Entry/Update-AtlasUser.ps1` runs once for each stamp and records it as `UpgradeVersion` under `HKCU\SOFTWARE\AtlasOS\UserSetup`.
  A failed migration doesn't record the stamp, so it runs again at the next sign-in.
- The installing user's own pass records the stamp too, so their next sign-in doesn't run it again.

Each migration writes a transcript to that account's `%LOCALAPPDATA%\AtlasOS\Logs`.
It applies ordinary user settings and replays the user part of each recorded toggle, but not protected policy roots.

## Old Atlas Toolbox records

Every install's PreInstall step deletes the records the old Atlas Toolbox kept outside the toggle store:

- the records directly under `HKLM\SOFTWARE\AtlasOS`, written by Toolbox 0.1.1 to 0.1.9;
- the keys there named `Services<Name>`, without the backslash, and its settings in `ServicesToolbox`, written by Toolbox 0.1.10;
- its `FeatureUpdateDeferrals` and `QualityUpdateDeferrals` records.

A key goes only when it holds nothing but the values the Toolbox wrote.
Any other key stays, with the warning `Customized old Atlas Toolbox record ... was retained.`
`HKLM\SOFTWARE\AtlasOS\Toolbox`, the Toolbox installer's own record, stays.
