# Release verification matrix

This page lists the evidence every Atlas release needs before it's published, for the maintainers who verify and approve releases.
Passing the [automated checks](testing.md) is necessary, but it doesn't show that installs, updates or devices behave as intended.
[Releasing Atlas](releasing.md) says where these checks fit in the release.

## Where the evidence goes

Record the evidence in the release pull request, the one that bumps the version.
For each check, record:

- the commit and the SHA-256 of the `AtlasManager.exe`, the Atlas package and any media it used;
- the Windows release, build, edition and architecture, and whether it was a VM or a physical PC;
- the result, and anything left untested;
- sanitised logs or reports, attached or linked.

> [!IMPORTANT]
> Evidence counts only for the files it names.
> A result from another candidate, or from a build of a different commit, doesn't cover the release.

Keep VM disks, checkpoints, transcripts, screenshots and machine paths out of Git, as [publication contents](publication.md) describes.

## Required evidence

The supported Windows releases are those in `SupportedBuilds` in `playbook/playbook.conf`, listed in the [supported releases](windows-release-policy.md#supported-releases) table.
The Atlas versions a release updates are those in `UpgradableFrom` in the same file.

| Area | What must hold | Evidence |
| --- | --- | --- |
| Fresh install | Get ready, the install, the restart and the health check complete on each supported release. | A VM run from a clean checkpoint on each supported release, then at least one physical PC. |
| Customised baseline | Atlas installs over a Windows installation that already has user changes. | A VM run from a checkpoint with common user changes in place. |
| Updates | Choices and backups are kept when updating from each version in `UpgradableFrom`. | A VM run for each source version with **Keep my choices**, one with **Choose again**, and a reinstall of the same version. |
| Windows transition | Atlas Manager moves Windows to a supported release, then installs or updates Atlas. | A VM run from each Windows release Atlas Manager offers to move ([Moving Windows to a newer release](windows-transition.md)). |
| User lifecycle | The installing user, another existing profile and a new profile get the intended settings. | First sign-in of each profile, a retry after a failed migration, and the settings protected policies keep. |
| Preparation | Windows, the Microsoft Store and installed Store apps are up to date before Atlas changes anything. | A provider failure, going offline and reconnecting, a pending restart, and a retry with each driver choice. |
| Recovery | Fixed choices and progress survive an interruption without starting a second install. | Closing and reopening the app, a process failure, a restart, declined elevation and Explorer recovery; the SYSTEM cleanup task's permissions and self-deletion. |
| Windows services | Servicing, the Microsoft Store and BITS work after the install. | A Store app install, a BITS transfer and a Windows Update scan after the restart. |
| ISO creation | Media passes verification, sets the local account and password, and boots. | The interactive, saved-choice and before-desktop flows; edition filtering with firmware Home and Pro keys and on PCs without one. |
| USB writing | Atlas Manager writes the chosen physical drive, protects source and system disks, verifies the output and ejects safely. | Cancelling at each stage, unplugging or replacing the drive, drive-letter reuse, a refused eject and a UEFI boot. |
| Network drivers | The optional staged driver package works on the target hardware. | Physical Wi-Fi and Ethernet, and a driver Windows Update offers after the install. |
| Interface and languages | Atlas Manager is usable at supported sizes and themes, with complete catalogs. | Keyboard use, text scaling, contrast themes and Narrator; native-speaker review of changed strings. |
| Distribution | Build inputs are reproducible and licence and provenance records are complete. | Runtime checks of the timer utilities built from source; a review of the dependency notices and corresponding sources. |
| Release files | The draft release's files are the ones the workflow built and attested. | Each file checked against `SHA256SUMS.txt` and its attestation. |

VM runs don't show performance or driver compatibility on physical hardware.

## Regression checks

Include these scenarios in every release:

- Disabling a boot or system driver can leave Windows unable to start.
  Keep the guard against those changes, and test driver changes on disposable systems.
- A successful install on one account doesn't show that another user's sign-in migration, Store deployment, BITS transfers or physical devices work.
- Test servicing and connectivity after the restart.
  Compare unexplained event-log failures with a baseline taken before Atlas was installed, before you attribute a cause.

The [testing guide's release checks](testing.md#release-checks) list the detailed checks for areas a release changed.
[ISO creation](../app/docs/iso-creation.md) covers media checks.
