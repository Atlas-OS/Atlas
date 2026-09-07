# Windows release eligibility

Atlas 0.6 installation and ISO creation support Windows 11 25H2 releases listed in
Microsoft's General Availability release history. The build family `26200` alone
does not establish eligibility: Insider flights have also used it. The app reads
the running system's build and UBR; ISO inspection uses DISM's four-part image
version, including its service-pack build/revision (`SPBuild`). Edition and
architecture checks remain separate requirements.

The app, ISO worker and direct playbook entry share the reviewed
[`windows-releases.json`](../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json)
snapshot. The app implements the check in
[`windows_release.rs`](../app/src/services/windows_release.rs); PowerShell callers
use [`Windows-Release.ps1`](../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1).
Keep their parser and classification fixtures consistent when changing the policy.

- `Released`: the complete version appears in the public General Availability
  table with an availability date no later than today.
- `Preview`: a supplied BuildLabEx contains a delimited `prerelease` branch marker.
- `Unknown`: eligibility could not be established. This includes an unlisted
  version, unavailable release information or an unexpected response format.
  Unknown is not evidence that Windows is an Insider installation.

Public optional nonsecurity updates qualify even when Microsoft calls the update
a "Preview". A build previously offered to Insiders can later become a public
release, so historical Insider build lists must not override published General
Availability entries. Enrollment and flight-signing settings are not used as proof
of the installed image's channel.

Known snapshot versions work offline. An unknown version triggers a bounded HTTPS
request to [Microsoft's Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information),
requesting its Markdown representation. Only the 25H2 General Availability table
is accepted. Responses have a 15-second deadline and a 1 MiB body limit;
unexpected content or malformed tables fail closed. Successful lookups are cached
in the process, never in a persistent trust file. PowerShell permits at most three
redirects within the same official HTTPS origin; the Rust client rejects redirects.

Eligibility is not an authenticity check. Metadata can be copied or altered, and
identical public and Release Preview builds cannot be distinguished by their
version alone. Offline image metadata also does not establish the provenance of
every image component. Continue to require official Windows media; do not describe
this check as cryptographic verification or complete Insider detection.

## Updating the snapshot

Use PowerShell 7 from the repository root:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -Refresh
```

For a repeatable update from a saved official Markdown response:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -MarkdownPath '<saved response>' -AsOfDate '2026-09-07'
```

Review the resulting JSON diff. The snapshot records the source URL, document
commit, SHA-256 of the response, update timestamp and cutoff date alongside each
release's version, date, update type and KB reference. Check new rows against the
official page, preserving public optional releases while excluding Insider-channel
rows and future availability dates. Do not add a version solely because an ISO or
a local machine reports it.

Run `tests/Atlas.WindowsRelease.Tests.ps1` through the repository's Pester runner
and the Rust `services::windows_release` tests after updating policy or fixtures.
The PowerShell fixtures cover malformed tables, network failures, response bounds,
redirect restrictions, snapshot fallback and deterministic generation. These checks
do not replace installation, servicing or ISO boot validation.
