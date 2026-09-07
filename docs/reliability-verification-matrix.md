# Release verification matrix

Passing repository checks is necessary but does not establish installation, upgrade
or device reliability. Record the exact app, playbook and media hashes with each
release review. Results from a different candidate do not certify the current tree.

## Required evidence

| Surface | Required outcome | Evidence still needed for the publication candidate |
| --- | --- | --- |
| Fresh installation | Fresh Windows 11 25H2; preparation, payload, restart and health checks complete | Exact-candidate VM runs on supported editions, then representative physical hardware |
| Atlas upgrades | Declared 0.4.1, 0.5.0 and 0.5.1 sources; choices and backups preserved | Each official source on a supported Windows build; document the Windows transition required for older installs |
| User lifecycle | Installing user, another existing profile and a new profile receive the intended settings | First sign-in, failed migration retry and protected-policy limitations |
| ISO creation (Beta) | Media verification, native local account/password change and successful boot | Exact-candidate interactive, saved-choice and before-desktop flows; supported-edition filtering with firmware Home/Pro keys and keyless devices |
| Preparation | Windows, Microsoft Store and installed Store apps updated before applying Atlas | Provider failure, offline/reconnect, pending reboot and retry with both driver policies |
| Recovery | Fixed choices and progress survive interruption without duplicate installers | Close/reopen, process failure, restart, declined elevation and Explorer recovery; actual SYSTEM cleanup-task permissions and self-deletion |
| USB writing (Beta) | Correct physical target, protected source/system disks, verified output, safe eject | Cancellation at each stage, unplug/replacement, drive-letter reuse, eject veto and UEFI boot |
| Network drivers | Optional staged package works on target hardware | Physical Wi-Fi/Ethernet and a newly offered Windows Update driver download |
| UI and languages | Usable at supported sizes/themes with complete catalogs | Keyboard, text scaling, contrast and Narrator; native-speaker translation review |
| Distribution | Reproducible build inputs and complete license/provenance records | Runtime checks for the source-built timer replacements; final redistribution review of the collected dependency notices and corresponding sources |

## Regression checks

Do not commit VM disks, checkpoints,
transcripts, screenshots or personal host paths. Attach sanitized, hash-bound test
reports to a release review when they are independently checked.

Include these regression scenarios:

- Disabling a boot/system driver can make Windows unbootable; preserve the guard
  against those mutations and validate driver changes on disposable systems.
- A successful machine install does not prove another user's logon migration,
  Store deployment, BITS operation or physical device behavior.
- Test post-reboot servicing and connectivity, and compare unexplained event-log
  failures against a pre-Atlas baseline before attributing a cause.

See [testing](testing.md) for automated checks, [upgrading](upgrading.md) for the
Windows-build conflict, and [ISO creation](../app/docs/iso-injection.md) for media
validation. Record current review results separately from historical reports.
