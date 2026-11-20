# Windows release policy

This page explains which Windows releases Atlas installs on and builds ISOs from, and how Atlas checks a Windows version.
It's for testers and maintainers, and for anyone who wants to know why Atlas Manager refused a version of Windows.

Atlas installs on, and builds ISOs from, Windows 11 releases in Microsoft's public General Availability release history.
Only public releases qualify because they're fixed builds that every PC gets the same way through Windows Update, so a check on one PC holds for another.
Insider, Canary, Dev, Beta and Release Preview builds can change the components, services and settings Atlas relies on without notice, and a later public release can differ from them.

## Supported releases

| Release | Build | Status |
| --- | --- | --- |
| Windows 11 25H2 | `26200` | Supported |
| Windows 11 26H2 | `26300` | Supported |

**Supported** means the build is in `SupportedBuilds` in `playbook/playbook.conf` and in the release catalog's `supportedReleases`, so Atlas installs on that build's public revisions and builds ISOs from them.
Atlas Manager can move a PC on an earlier release to a supported one first ([Moving Windows to a newer release](windows-transition.md)).

The build number alone isn't enough: Insider flights have used these numbers too.
Atlas Manager reads the running system's build and update revision (UBR).
ISO inspection reads DISM's four-part image version, including its service-pack build and revision (`SPBuild`).
Edition and architecture are checked separately.

| Result | Meaning |
| --- | --- |
| `Released` | The complete version is in the public General Availability table, with an availability date no later than today. |
| `Preview` | A supplied BuildLabEx contains a delimited `prerelease` branch marker. |
| `Unlisted` | Microsoft's release information was read, and the complete version isn't in its General Availability tables. |
| `Unknown` | Eligibility couldn't be established. |

- `Unlisted` is most often a Release Preview build, or an update the page doesn't list yet.
  Atlas says so and suggests checking again once Microsoft lists it.
- `Unknown` follows unavailable release information, an unexpected response format, or an unlisted version checked offline.
  It isn't evidence of an Insider installation.
- Public optional non-security updates qualify, even when Microsoft calls them "Preview".
- A build once offered to Insiders can later become public, so historical Insider lists never override published General Availability entries.
- Enrolment and flight-signing settings don't prove the installed image's channel.

## Architectures

ISO creation and USB writing accept x64 and ARM64 client images; all editions in one image must share an architecture.
The builder writes the matching `processorArchitecture` into the answer file and verifies the UEFI loader:

- `bootx64.efi` for x64, which keeps BIOS and UEFI boot catalog entries;
- `bootaa64.efi` for ARM64, which is UEFI only.

Network drivers copied from the host must match the image's architecture.
Microsoft documents [servicing ARM64 images from an AMD64 technician PC](https://learn.microsoft.com/windows-hardware/manufacture/desktop/arm64-device-manufacturing), but media built on x64 may still need device-specific boot and storage drivers to boot an ARM device.

## Online lookup

The bundled [release catalog](#updating-the-catalog) decides most versions offline.
When it doesn't list a revision, Atlas asks for the Markdown form of [Microsoft's Windows 11 release information](https://learn.microsoft.com/windows/release-health/windows11-release-information):

- Only the General Availability tables of the supported releases are accepted.
- The request has a 15-second deadline and a 1 MiB body limit.
  Unexpected content or malformed tables give `Unknown`.
- PowerShell follows at most three redirects within the same official HTTPS origin; Atlas Manager rejects redirects.
- Successful lookups are cached in memory only, never in a persistent trust file.
  Atlas Manager keeps them for 15 minutes.

Who looks a revision up depends on what is being checked:

| Check | Looks up an unlisted revision online |
| --- | --- |
| The running system, in Atlas Manager and in `Install-Atlas.ps1` | Always, in every build of Atlas Manager. |
| An ISO's image, in a release build of Atlas Manager | Yes. |
| An ISO's image, in a tester build | No. |

A tester build is an Atlas Manager build that carries one Atlas package and installs nothing else, made so testers can check a release candidate ([Tester builds](../app/docs/rc-testers-build.md)).
It checks the running system online because `Install-Atlas.ps1` always does, so Get ready and the install agree on an unlisted revision, such as a Release Preview build.

For an ISO, a tester build calls `Get-AtlasWindowsReleaseStatus -NoRefresh`.
An image has no BuildLabEx to show its branch, so that check accepts an unlisted revision only if it's newer than every listed revision of that build.
Older unlisted revisions, such as pre-release flights, stay `Unknown`.

## What the check doesn't prove

> [!IMPORTANT]
> Eligibility isn't an authenticity check.
> Don't describe it as cryptographic verification or complete Insider detection.

Metadata can be copied or altered, identical public and Release Preview builds share a version, and offline image metadata doesn't establish where every component came from.
Keep requiring official Windows media.

## Updating the catalog

Atlas Manager, the ISO worker and the front door, `Install-Atlas.ps1`, share the reviewed [`windows-releases.json`](../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json) catalog.
Atlas Manager checks it in [`windows_release.rs`](../app/src/services/windows_release.rs); PowerShell callers use [`Windows-Release.ps1`](../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1).
Keep their parsers and classification fixtures consistent when changing the policy.

From the repository root in PowerShell 7:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -Refresh
```

For a repeatable update from a saved official Markdown response:

```powershell
./tools/dev/Update-WindowsReleaseCatalog.ps1 -MarkdownPath '<saved response>' -AsOfDate '<yyyy-MM-dd>'
```

Review the JSON diff:

- The catalog records the source URL, document commit, SHA-256 of the response, update timestamp and cutoff date.
  It also records each release's version, date, update type and KB reference.
  Schema 2 declares the supported release and build pairs separately from the full-version rows.
- Check new rows against the official page.
  Keep public optional releases; leave out Insider-channel rows and future availability dates.
- Never add a version only because an ISO or a local PC reports it.

After any policy or fixture change, run `tests/Atlas.WindowsRelease.Tests.ps1` through the repository's Pester runner and the Rust `services::windows_release` tests.
The PowerShell fixtures cover malformed tables, network failures, response limits, redirect restrictions, catalog fallback and deterministic generation.
They don't replace install, servicing or ISO boot checks.
