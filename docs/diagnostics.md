# Reporting app and playbook problems

In Atlas Manager, choose **Export diagnostics** in Settings or on the install,
ISO or USB page. Wait for **Show diagnostic ZIP**, then review the archive and
send it privately to Atlas support. Nothing is uploaded automatically. Include
what you were doing, the expected and actual result, approximate time/timezone,
and whether the problem repeats. A template is included in the archive.

Export after a failure before deleting app data or reinstalling Windows. Retrying
and reopening the app retain earlier app logs. If the window cannot open, run
`AtlasManager.exe --export-diagnostics`; archives are saved under
`%LOCALAPPDATA%\AtlasOS\App\Diagnostics`. `ATLAS_APP_DATA` overrides that root for
isolated testing. Run as the affected account; another user's profile is not
collected automatically. Elevation can improve access to machine evidence but is
not required to export the files that are readable.

The ZIP contains app and playbook logs, preparation and media-worker diagnostics,
saved settings/session state, the installing account's user logs, ISO setup and
desktop recovery logs, and the read-only install report. It excludes executable
payloads, scripts, ISO/WIM media and memory dumps. Logs and reports can contain
account names, SIDs, file paths, installed applications and device identifiers.
They are not automatically anonymized: review before sharing.

`manifest.json` records the running executable's SHA-256, app version, selected
package identity when available, Windows build/edition, elevation, and the hash
of each included file. Unavailable, unreadable and size-limited evidence is listed
explicitly. Missing files are normal before installation. The machine collector
has a 60-second deadline; a failed collector does not discard other logs. Files
captured during a running operation are snapshots, not a consistent transaction.

App logs use separate process/session files under the app's `Logs` directory,
with four 4 MiB segments per process and pruning of older app logs at startup
(36 previous segments retained, plus active processes). Installation logs are
not pruned by this policy. If the normal app log location cannot be created,
logging falls back to `%TEMP%\AtlasDiagnostics`; the current fallback log is also
included in an export. Rust panic messages/backtraces are flushed before exit;
native crashes, forced termination and disk-write failures may leave no final
message. No automatic crash upload or full dump collection is installed.

Exports retain complete eligible files up to 32 MiB each, 256 MiB total and 2,048
visited entries. The manifest identifies omitted evidence so support can request
specific files separately. Symbolic links/junctions are skipped. Existing exports
are not automatically deleted; users may remove ZIPs after support no longer
needs them.

For triage, read `manifest.json`, correlate timestamps in app logs with the
installation/preparation/media job, and check `report/machine-report.txt` for
health, state and Windows events. Do not infer success merely from a completed
ZIP: inspect collection errors and the underlying operation's result. Preserve
the executable corresponding to the recorded hash for crash investigation.
