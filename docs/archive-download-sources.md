# Archive-app download sources

NanaZip installation tries the pinned GitHub release asset first,
then the project's official SourceForge file through
`https://downloads.sourceforge.net/project/`. SourceForge selects a
mirror; Atlas does not select by language, country, or a fixed regional host.
Each source has a 60-second download deadline and must match the same pinned
size and SHA-256. Installation starts only after successful verification; an
installation failure never triggers another installation from the mirror.
No GitHub API request is needed on the user's PC.
It does not guarantee availability from every country or ISP. Validate from the
affected user's network before claiming the connectivity problem is resolved.

NanaZip is pinned to **7.0.1843.0**. Its stable MSIX bundle and offline license
have sizes and SHA-256 hashes embedded in `Atlas.Software/Domain/Installers.ps1`.
On 2026-09-19, both SourceForge downloads matched the hashes published by the
upstream GitHub release API. Installation also checks package identity and
version before DISM provisioning. Updating NanaZip now requires updating the
version, sizes, and hashes together in the playbook; it no longer discovers the
latest release during setup.

Atlas no longer installs 7-Zip as a fallback or offers it in the software picker.
Exhausted NanaZip downloads or provisioning errors propagate to setup instead of
silently installing a different archive app. Existing 7-Zip replacement remains
opt-in, with removal only after successful NanaZip provisioning. Build/lab tools
can still use an existing 7-Zip-compatible command. The legacy `SevenZip`
component identifier still dispatches to NanaZip for compatibility.

Store-first installation is a separate developer experiment, documented in
[nanazip-store-probe.md](nanazip-store-probe.md). It is not enabled in the playbook.

Official source references:

- https://github.com/M2Team/NanaZip (identifies SourceForge as an official project site)
- https://sourceforge.net/projects/nanazip/files/7.0.1843.0/
- https://github.com/M2Team/NanaZip/releases/tag/7.0.1843.0

## Background-app registry failure in diagnostic bundle 7776

The installing-user log records a denied value operation for
`HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\BackgroundAppGlobalToggle`.
The key opened for writing, but this does not establish which mechanism denied
the subsequent operation or prove all tokens would be denied.

Local MicrosoftDocs/win32 at `79eaaa46`,
`desktop-src/SysInfo/registry-key-security-and-access-rights.md`, documents
`KEY_SET_VALUE` and registry access checks. No documentation for this exact
preference was found in the local Microsoft documentation or the online search.
Microsoft's documented `LetAppsRunInBackground` policy is device-scoped and
Force Deny prevents users from overriding it; it is not a like-for-like replacement
for Atlas's per-user preference:
https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy#letappsruninbackground

The specific Search preference is now best effort in installation and both toggle
directions. Value-level access denial is logged; other failures still propagate.
Health verification still reports an unapplied value as drift. The primary
`GlobalUserDisabled` preference remains required. This prevents the observed
setup abort without claiming the denied preference was applied or changing to
a device-wide policy.
