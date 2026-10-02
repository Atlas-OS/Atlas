# Reporting problems with Atlas Manager or Atlas

How to report a problem with Atlas Manager or with Atlas itself, and what the diagnostic
export contains. [Triage](#triage) and [How it works](#how-it-works) are for
contributors.

## Report a problem

Both routes are in Atlas Manager's Settings, under **Help and feedback**:
**Send a report**, then **Export diagnostics**. The install, ISO and USB pages offer the
same buttons under a problem. The installing view keeps them with the install log, adding
**Send a report** once the install ends. **Report a problem** on Home opens
**Send a report**.

| Route | How | Who sees it |
| --- | --- | --- |
| Bug report | **Export diagnostics**, then **Show in folder**. Attach the redacted ZIP to a bug report. | Anyone: community and development channels are public. |
| Private report | **Send a report**: pick an issue or a suggestion, describe it and confirm. Atlas Manager sends your message, optional contact details, its version and any diagnostics you include to reports.atlasos.net. | The Atlas team. It may use AI services from other companies to help investigate; these get your message and diagnostics, never your contact details. Deleted after 90 days; see [Atlas reports](../services/reports/README.md) for what is kept. |

Nothing is uploaded automatically. Say what you were doing, the expected and actual
result, roughly when (with timezone) and whether it repeats; the archive includes a
template.

**Send a report** collects diagnostics as soon as they are included, which is the default
for an issue, so there is no separate step. It reuses a ZIP only if you exported it on the
page you came from; otherwise each report collects its own. **Review ZIP** shows the ZIP
in its folder before you send, and choosing **Send report** while collection runs sends
once it finishes. If sending fails, your text stays on the page and a retry reuses the same
submission. You can also use [the report website](https://reports.atlasos.net), which
shows the same privacy notice, or share the ZIP yourself.

- Export after a failure, before deleting app data or reinstalling Windows. Retrying
  and reopening the app keep earlier app logs.
- If the window cannot open, run `AtlasManager.exe --export-diagnostics`.
- Archives go to `%LOCALAPPDATA%\AtlasOS\App\Diagnostics` (`ATLAS_APP_DATA` overrides
  the root for isolated testing), including those **Send a report** collects. Atlas
  never deletes them; remove them when the investigation is over.
- Run as the affected account; other users' profiles are not collected
  automatically. Elevation reaches more machine evidence but is not required to
  export readable files.

## What the ZIP contains

| Included | Excluded |
| --- | --- |
| App and Atlas logs, preparation and media-worker diagnostics, saved settings and session state, the installing account's user logs, ISO setup and desktop recovery logs, the read-only install report, and the preparation evidence, install request and runtime logs from staging copies of the Atlas package | Executable files, scripts, application code and assets, ISO/WIM media, memory dumps, symbolic links and junctions |

Exports keep whole files up to 32 MiB each and 256 MiB in total (including the
archive's READ-ME, bug report template and manifest), and visit at most 2,048
entries.

### Redaction

Exported text is redacted; the original local logs are unchanged.

| Treatment | Data |
| --- | --- |
| Replaced with consistent anonymous labels | Account profile names; the collecting user's account, computer and domain names; the local account name entered for an ISO's setup; email addresses; account SID prefixes; Microsoft Entra ID account SIDs |
| Removed | Password fields, API credentials, HTTP authorization and cookies, signed URL credentials, common access-token formats, product keys, private keys |
| Kept | Account RIDs and well-known Windows SIDs (for diagnosing permissions); error messages, stack traces, timestamps, build and version numbers, selected options, operation IDs, hardware models, device identifiers, network (IP and MAC) addresses, installed applications, the useful remainder of file paths |

Redaction is targeted: it cannot reliably detect arbitrary personal text or an
unrecognised secret format in third-party output. The app therefore names what it
removes (the user name, PC name, email addresses and known passwords or keys) and never
calls the ZIP anonymous. UTF-8 and BOM-marked UTF-16 logs are supported; unknown or binary
encodings are explicitly omitted.

## Triage

- Start with `manifest.json`: the running executable's SHA-256, app version, selected
  package identity when available, Windows build and edition, elevation, each
  redacted file's hash, the redaction policy version, and any unavailable, unreadable
  or size-limited evidence, which you can request separately. Missing files are normal
  before installation.
- Correlate app log timestamps with the installation, preparation or media job, and
  check `report/machine-report.txt` for health, state and Windows events.
- For Get ready's updates, and above all a move to a newer Windows release, read
  `preparation/windows-transition.log` first: every step of the move, with each outcome's
  reason id (`feature-*`). Each job folder's `updates.log` has that run's updates and the
  Microsoft Store items it waited for. A run that found no offer yet ends with an
  `Outcome (feature-not-offered)` line, not an error record. `report/machine-report.txt`
  adds the record under `HKLM\SOFTWARE\AtlasOS\WindowsTransition`, the Windows Update
  policies, services and tasks, the Atlas servicing packages, update history, the ends of
  `CBS.log` and `DISM.log`, the Setup and Windows Update event channels and pending file
  renames.
- A completed ZIP does not mean the operation succeeded; check collection errors and
  the operation's own result.
- Files captured during a running operation are snapshots, not a consistent
  transaction.
- Keep the executable matching the recorded hash for crash investigation.

### RC3 exports that hit the entry limit

1. In elevated Windows PowerShell, as the account that attempted the installation,
   run `tools/dev/Get-AtlasInstallEvidence.ps1`. It reads the state document and the
   ten newest staging requests without running Atlas's scripts or changing
   installation state, and saves one log in the app's Logs directory.
2. Export diagnostics again; the exporter redacts and includes that log.
3. Send the resulting ZIP, not the raw log.

## How it works

The exporter is `app/src/services/diagnostics.rs`; redaction rules are in
`diagnostics_redaction.rs`.

- **App logs:** per-process/session files under the app's `Logs` directory, four
  4 MiB segments per process. Startup prunes older app logs to 36 previous segments
  plus active processes; installation logs are not pruned. If `Logs` cannot be
  created, logging falls back to `%TEMP%\AtlasDiagnostics`, and exports include the
  current fallback log.
- **Crashes:** Rust panic messages and backtraces are flushed before exit. Native
  crashes, forced termination and disk-write failures may leave no final message.
  There is no automatic crash upload or full dump collection.
- **Machine report:** collected before the bulk of the files, with a 60-second
  deadline. Each finished section is written to `report/machine-report.partial.txt`,
  so a timed-out collector keeps them and `collectorError` names the section it was
  in. A failed collector does not discard other logs.
- **Media jobs:** each ISO check, ISO build and USB operation keeps its worker logs,
  request and error in a job folder under `%ProgramFiles%\Atlas Setup Recovery\Media`,
  which only administrators can change. Starting a job removes other jobs older than
  a day, always keeping the newest 20. Jobs that earlier versions left in the app's
  `ISO` directory are pruned the same way (`prune_legacy_jobs` in
  `app/src/services/iso.rs`). They are exported last, without their licence notices,
  so they cannot use up the size budget.
- **Installation:** TrustedInstaller install phases write startup, completion and
  exception details (including stack/position) to the staging copy's
  `Executables\AtlasModules\Logs\install-capture.log` and `install-run.log`; the
  broker relays the end of the phase's log, up to a size limit, on failure. These cover
  bootstrap and module-loading exceptions, but process termination or script parse
  failures may leave none.
