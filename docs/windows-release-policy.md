# Windows release eligibility

Atlas 0.6 installs on, and builds ISOs from, Windows 11 releases in Microsoft's General
Availability release history. This page is for testers and maintainers.

## Supported releases

| Release | Build | Status |
| --- | --- | --- |
| Windows 11 25H2 | `26200` | Supported |
| Windows 11 26H2 | `26300` | Release-candidate testing. Passed on `26300.9457`: fresh x64 Hyper-V installation, post-reboot settings readback, app-removal inventory, runtime checks, component-store health scan. Not established: physical devices, ARM64, GPU-dependent features, upgrade paths. |

The build number alone is not enough: Insider flights have used these numbers too.
The app reads the running system's build and update revision (UBR); ISO inspection
reads DISM's four-part image version, including its service-pack build/revision
(`SPBuild`). Edition and architecture are checked separately.

| Result | Meaning |
| --- | --- |
| `Released` | The complete version is in the public General Availability table with an availability date no later than today. |
| `Preview` | A supplied BuildLabEx contains a delimited `prerelease` branch marker. |
| `Unknown` | Eligibility could not be established: an unlisted version, unavailable release information or an unexpected response format. Not evidence of an Insider installation. |

- Public optional non-security updates qualify, even when Microsoft calls them
  "Preview".
- A build once offered to Insiders can later become public, so historical Insider
  lists never override published General Availability entries.
- Enrollment and flight-signing settings do not prove the installed image's channel.

## Architectures

ISO creation and USB writing accept x64 and ARM64 client images; all editions in one
image must share an architecture. The builder writes the matching
`processorArchitecture` into the answer file and verifies the UEFI loader:
`bootx64.efi` for x64, which keeps BIOS and UEFI boot catalog entries, or
`bootaa64.efi` for ARM64, which is UEFI only.

Network drivers copied from the host must match the image's architecture. Microsoft
documents [servicing ARM64 images from an AMD64 technician PC](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/arm64-device-manufacturing),
but media built on x64 may still need device-specific boot and storage drivers to
boot an ARM device.

## Online lookup

Snapshot versions are checked offline. In stable builds, an unknown version triggers
a size- and time-limited HTTPS request for the Markdown form of
[Microsoft's Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information):

- Only the matching 25H2 and 26H2 General Availability tables are accepted.
- 15-second deadline and 1 MiB body limit. Unexpected content or malformed tables
  give `Unknown`.
- PowerShell follows at most three redirects within the same official HTTPS origin;
  the Rust client rejects redirects.
- Successful lookups are cached in memory only (the app keeps them 15 minutes), never
  in a persistent trust file.

Tester builds never make this request:

- **Running system:** an unlisted revision of a supported build on a release branch is
  accepted.
- **ISO:** an image has no BuildLabEx to show its branch, so ISO inspection calls
  `Get-AtlasWindowsReleaseStatus -NoRefresh`. It accepts an unlisted revision only if
  it is newer than every listed revision of that build. Older unlisted revisions,
  such as pre-release flights, stay `Unknown`.

## What the check does not prove

Eligibility is not an authenticity check. Metadata can be copied or altered,
identical public and Release Preview builds share a version, and offline image
metadata does not establish where every component came from. Keep requiring official
Windows media. Do not describe this check as cryptographic verification or complete
Insider detection.

## Updating the snapshot

The app, the ISO worker and the direct installer, `Install-Atlas.ps1`, share the reviewed
[`windows-releases.json`](../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json)
snapshot. The app checks it in
[`windows_release.rs`](../app/src/services/windows_release.rs); PowerShell callers use
[`Windows-Release.ps1`](../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1).
Keep their parsers and classification fixtures consistent when changing the policy.

From the repository root in PowerShell 7:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -Refresh
```

For a repeatable update from a saved official Markdown response:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -MarkdownPath '<saved response>' -AsOfDate '2026-09-07'
```

Review the JSON diff:

- The snapshot records the source URL, document commit, SHA-256 of the response,
  update timestamp and cutoff date, plus each release's version, date, update type
  and KB reference. Schema 2 declares the supported release/build pairs separately
  from the full-version rows.
- Check new rows against the official page. Keep public optional releases; exclude
  Insider-channel rows and future availability dates.
- Never add a version just because an ISO or a local machine reports it.

After any policy or fixture change, run `tests/Atlas.WindowsRelease.Tests.ps1` through
the repository's Pester runner and the Rust `services::windows_release` tests. The
PowerShell fixtures cover malformed tables, network failures, response limits,
redirect restrictions, snapshot fallback and deterministic generation. They do not
replace installation, servicing or ISO boot validation.
