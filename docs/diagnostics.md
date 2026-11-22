# Reporting problems with Atlas Manager or Atlas

This page explains how to report a problem with Atlas Manager or with Atlas itself, and what the diagnostic export contains.
It's for anyone using Atlas; [Triage](#triage), [Log limits](#log-limits) and [How it works](#how-it-works) are for contributors.

## Report a problem

In Atlas Manager, open **Settings** > **Help and feedback**.
It has both routes: **Send a report** and **Export diagnostics**.
The install, ISO and USB pages offer the same buttons under a problem.
The installing view keeps them with the install log, and adds **Send a report** once the install ends.
**Report a problem** on Home opens **Send a report**.

| Route | Who sees it |
| --- | --- |
| Private report, with **Send a report** | The Atlas team. |
| Public bug report, with **Export diagnostics** | Anyone: community and development channels are public. |

Nothing is uploaded automatically.
Say what you were doing, the result you expected and the one you got, roughly when it happened (with the time zone), and whether it happens again.
The archive includes a template for this.

### Send a private report

Choose **Send a report**, pick an issue or a suggestion, describe it and confirm.
Atlas Manager sends your message, any contact details you give, its version and any diagnostics you include to reports.atlasos.net.
The Atlas team may use AI services from other companies to help investigate; these get your message and diagnostics, never your contact details.
Reports are deleted after 90 days; [Atlas reports](../services/reports/README.md) says what's kept.

**Send a report** collects diagnostics as soon as they're included, which is the default for an issue, so there's no separate step.
It reuses a ZIP only if you exported it on the page you came from; otherwise each report collects its own.
**Review ZIP** shows the ZIP in its folder before you send.
If you choose **Send report** while collection runs, the report goes once collection finishes.

If sending fails, your text stays on the page, and a retry reuses the same submission.
The service closes a submission whose ZIP hasn't arrived after a day; a retry then sends a new one.
You can also use [the report website](https://reports.atlasos.net), which shows the same privacy notice, or share the ZIP yourself.

### Attach diagnostics to a bug report

Choose **Export diagnostics**, then **Show in folder**, and attach the redacted ZIP to a bug report.

- Export after a failure, before deleting app data or reinstalling Windows.
  Retrying and reopening the app keep earlier app logs.
- If the window can't open, run `AtlasManager.exe --export-diagnostics`.
- Archives go to `%LOCALAPPDATA%\AtlasOS\App\Diagnostics`, including those **Send a report** collects.
  `ATLAS_APP_DATA` overrides the root for isolated testing.
  Atlas never deletes them; remove them when the investigation is over.
- Run Atlas Manager as the affected account; other users' profiles aren't collected automatically.
  Elevation reaches more evidence from the PC, but you don't need it to export readable files.

## What the ZIP contains

The ZIP includes:

- app and Atlas logs;
- preparation and media-worker diagnostics;
- saved settings and session state;
- the installing account's user logs;
- ISO setup and desktop recovery logs;
- the read-only install report;
- the preparation evidence, install request and runtime logs from staging copies of the Atlas package.

The ZIP leaves out:

- executable files, scripts, application code and assets;
- ISO and WIM media;
- memory dumps;
- symbolic links and junctions.

Exports have size and entry limits; see [Log limits](#log-limits).

### Redaction

Exported text is redacted; the original local logs are unchanged.

Atlas Manager replaces these with consistent anonymous labels:

- account profile names;
- the collecting user's account, computer and domain names;
- the local account name entered for an ISO's setup;
- email addresses;
- account SID prefixes and Microsoft Entra ID account SIDs;
- the per-profile job folder names under `Atlas Setup Recovery`, which are derived from the profile path.

It removes:

- password fields, API credentials, HTTP authorisation and cookies;
- signed URL credentials and common access-token formats;
- product keys and private keys.

It keeps:

- account RIDs and well-known Windows SIDs, for diagnosing permissions;
- error messages, stack traces, timestamps, build and version numbers, selected options and operation IDs;
- hardware models, device identifiers, network (IP and MAC) addresses and installed applications;
- the useful remainder of file paths.

> [!NOTE]
> Redaction is targeted: it can't reliably detect arbitrary personal text, or a secret format it doesn't know, in other programs' output.
> Atlas Manager therefore names what it removes (the user name, PC name, email addresses and known passwords or keys) and never calls the ZIP anonymous.

UTF-8 and BOM-marked UTF-16 logs are supported; files in unknown or binary encodings are left out and listed as such.
A crash or hard reset can leave runs of NUL bytes in a log.
The export takes them out, marks the place with `[NUL bytes removed]` where more text follows, and lists the file in the manifest as `included: NUL bytes removed`.

## Triage

Start with `manifest.json`.
It records the running executable's SHA-256, the app version, the selected package when available, the Windows build and edition, and elevation.
It also records each redacted file's hash, the redaction policy version, and any evidence that was unavailable, unreadable or over a size limit, which you can ask for separately.
Missing files are normal before an install.

Correlate app log timestamps with the install, preparation or media job.
`report/machine-report.txt` has the health check, the install state and Windows events.

| Question | Read first | Look for |
| --- | --- | --- |
| Why did a move to a newer Windows release stop? | `preparation/windows-transition.log` | Each step of the move, with each outcome's reason ID (`feature-*`). |
| Where are the move's earlier steps? | `preparation/windows-transition.old.log` | The steps before the log passed 1 MiB. |
| Did Windows offer the feature update? | `preparation/windows-transition.log` | An `Outcome (feature-not-offered)` line, which isn't an error record. |
| Which updates did Get ready install? | `updates.log` in each job folder | That run's updates and the Microsoft Store items it waited for. |
| Why did a preparation worker stop without reporting? | `worker.log` in the same job folder | The error it wrote, for example when PowerShell refused to run it. |
| Why did a Store item end in `Error`? | The event section of `report/machine-report.txt` | The AppX deployment errors behind 0x80073CF9, which only says the install failed. |
| What state is Windows servicing in? | `report/machine-report.txt` | The `HKLM\SOFTWARE\AtlasOS\WindowsTransition` record, update policies, services, tasks and update history. |
| Did servicing log errors? | `report/machine-report.txt` | The ends of `CBS.log` and `DISM.log`, the Setup and Windows Update event channels, and pending file renames. |
| Which way did an update or reinstall go? | `install-capture.log` | The `Install mode:` line, such as `Install mode: Upgrade, keeping your choices.` |
| Which choices did Capture take from the PC? | `install-capture.log` | A `Kept ...` line for each, after the repairs to toggle records an Atlas before 0.6 left. |
| Which records did a Rebase put back? | `atlas-install.log` | The same record repair lines. |
| Did Atlas keep an old Toolbox record? | `install-run.log` | `Customized old Atlas Toolbox record ... was retained.`, for a record that holds more than the Toolbox wrote. |
| How was each choice applied? | `atlas-install.log` | `Applied choice ...`, `Choice ... already matches this PC.` or `Choice ... is already recorded as ...`. |
| Did the app removal list provisioned apps? | `atlas-install.log` | `Couldn't list the apps Windows provisions for new accounts, so the app removal looks for the chosen ones itself: ...` |
| Which choices were recorded differently from the request? | `atlas-install.log` | A `Recorded ...` line from Completion for each one ([Updating Atlas](upgrading.md)). |
| Why did an install stop while removing apps? | The applications section of `report/machine-report.txt` | Each package Atlas removes that's still registered or provisioned. |
| Which accounts still have that package? | The applications section of `report/machine-report.txt` | Each account's install state when collected elevated; otherwise, the accounts the AppX store's registry lists. |
| Why did that removal fail? | The event section of `report/machine-report.txt` | AppX deployment events during the install that name those packages. |

Keep these in mind:

- A completed ZIP doesn't mean the operation succeeded; check collection errors and the operation's own result.
- Files captured during a running operation are snapshots, not a consistent transaction.
- Keep the executable that matches the recorded hash for crash investigation.

## Log limits

Each log Atlas and Atlas Manager keep has a limit, so repeated runs can't fill the disk.

| Log | Limit |
| --- | --- |
| Atlas Manager logs | Four 4 MiB segments for each process. Startup keeps the 36 newest earlier segments, plus those of running processes. |
| `atlas-install.log` and `warnings-summary.log` | Past 16 MiB, moved aside before the next run as `*.previous.log`, replacing the one before. |
| Timestamped install logs | Deleted after 90 days, apart from the newest 200. |
| `windows-transition.log` | Past 1 MiB, copied to `windows-transition.old.log`, replacing the one before, and started again. |
| AppX deployment events in `updates.log` | Each text once a run, cut at 1,500 characters. |
| AppX deployment events in `updates.log`, by count | At most four for each package each time a Store item fails, and 24 a run. |
| Media job folders | Starting a job removes other jobs older than a day, always keeping the newest 20. |
| Diagnostic export | Whole files up to 32 MiB each, 256 MiB in total, and at most 2,048 entries visited. |

The install logs are in `%windir%\AtlasModules\Logs\install`.
`updates.log` and `windows-transition.log` belong to Get ready, not to the Atlas install, so they're in its job folders rather than under `%windir%\AtlasModules\Logs`.
Get ready notes a deployment log it can't read and carries on.
The export's total includes its READ-ME, bug report template and manifest.

## How it works

The exporter is `app/src/services/diagnostics.rs`; the redaction rules are in `diagnostics_redaction.rs`.

- **App logs:** per-process and per-session files under the app's `Logs` folder.
  Startup prunes older app logs; install logs aren't pruned.
  If `Logs` can't be created, logging falls back to `%TEMP%\AtlasDiagnostics`, and exports include the current fallback log.
- **Crashes:** Rust panic messages and backtraces are flushed before exit.
  Native crashes, forced termination and disk-write failures may leave no final message.
  There's no automatic crash upload or full dump collection.
- **Machine report:** collected before most of the files, with a 60-second deadline.
  The health check inside it is stopped after 25 seconds, so a slow check can't use up the deadline.
  Each finished section is written to `report/machine-report.partial.txt`, so a timed-out collector keeps them, and `collectorError` names the section it was in.
  A failed collector doesn't discard other logs.
- **Machine report events:** event log sections start when an unfinished install began, or half an hour before the last install finished.
  AppX deployment warnings and information are read only for the install and the hour after it finished.
  Atlas servicing packages are read from the registry, so they're listed without elevation.
- **Media jobs:** each ISO check, ISO build and USB operation keeps its worker logs, request and error in a job folder under `%ProgramFiles%\Atlas Setup Recovery\Media`, which only administrators can change.
  Jobs that earlier versions left in the app's `ISO` folder are pruned the same way (`prune_legacy_jobs` in `app/src/services/iso.rs`).
  They're exported last, without their licence notices, so they can't use up the size budget.
- **Install phases:** TrustedInstaller install phases write startup, completion and exception details, including the stack and position, to the staging copy's `Executables\AtlasModules\Logs\install-capture.log` and `install-run.log`.
  On failure, the broker relays the end of the phase's log, up to a size limit.
  A successful install removes its staging copy, so each phase also leaves a copy of its log, whether it succeeds or fails, in `%windir%\AtlasModules\Logs\install` as `<UTC yyyyMMdd-HHmmss>-install-capture.log` or `-install-run.log`.
  A failed phase's message names that copy.
  These cover bootstrap and module-loading exceptions, but process termination or script parse failures may leave none.
- **Machine install logs:** `%windir%\AtlasModules\Logs` survives updates and resumes.
  An update keeps the folder when it replaces the rest of `AtlasModules`, and doesn't copy the staging copy's logs over it.
  Before each run, Atlas applies the [log limits](#log-limits); a failure there is only a warning in the run's log.
