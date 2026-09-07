# Upgrading Atlas

The 0.6 playbook accepts installed versions 0.4.1, 0.5.0 and 0.5.1. The source-version list is an eligibility check, not evidence that every version and Windows build combination has been tested. The current playbook accepts Windows 11 25H2 (build 26200). Source Atlas version and Windows build are separate requirements; a declared source version does not permit a 24H2 upgrade.

## What an upgrade applies

Upgrades replace the Atlas folder and modules, apply the selected installation features, and run the current networking, performance, privacy, quality-of-life, security, debloat, scripts and miscellaneous tweak categories. Definitions marked `OnUpgradeSkip` retain their fresh-install-only behavior.

Recorded toggle choices take precedence over overlapping registry defaults. Their selected states are reapplied using the new definitions. New defaults are recorded only when applied. On releases without recorded choices, migration adopts a choice only when existing settings uniquely identify it; unrecognized customizations cannot all be recovered automatically.

Upgrades preserve existing Start and taskbar layouts, file associations, and the original service backup files. They do not repeat the fresh-install service/component removal phases or run the old blanket Microsoft Store repair. This deliberately avoids treating an established installation as a clean Windows image.

## User settings

The installing user's ordinary settings run under that user's non-elevated token. Protected user policy settings are handled by the privileged installation pass. Existing profiles are registered for a versioned logon migration of ordinary user settings; successful migration records `HKCU\SOFTWARE\AtlasOS\UserSetup\UpgradeVersion`. A failed migration does not write the completion marker and can retry at the next logon.

The logon pass does not migrate protected policy roots for other existing profiles. Those profiles may retain older protected user policies. Newly created profiles follow the separate new-user setup path.

User migration transcripts are stored in `%LOCALAPPDATA%\AtlasOS\Logs`. Check the completed install transaction and run Atlas health checks after reboot, under the affected user as well as the installing account. A successful installer alone does not prove that application updates or every user's settings work.

## Verification

See [testing](testing.md) for repository checks. Release validation should include an actual official-release install, a customized baseline, upgrade through AME, reboot, health checks, preservation of selected choices and backups, Microsoft Store deployment, and a BITS transfer. Test additional existing profiles and a new profile separately. VM checks do not establish performance or driver compatibility on physical hardware.

### Windows version transition

Windows 24H2 is outside the current `SupportedBuilds` list. Before releasing 0.6, establish and
validate a supported Windows transition for an existing 0.4.1 installation, then
exercise its Atlas upgrade on 25H2. The source-version declaration remains intact.

Atlas 0.5.1, other existing profiles, new-profile first sign-in, different feature
choices and physical hardware still require candidate-specific validation. See the
[release verification matrix](reliability-verification-matrix.md).
