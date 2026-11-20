# Releasing Atlas

This guide takes a maintainer from a version bump to a published Atlas release.
It assumes you can build on Windows as [Building the Atlas package](building.md) describes, and that you can push tags to the repository.

A release is a GitHub release with four files: `Atlas-v<version>.apbx`, `Atlas-v<version>.zip`, `AtlasManager.exe` and `SHA256SUMS.txt`.
Atlas Manager offers the newest published release to every user, so publishing is the last step, after the evidence is in.

## Steps

1. **Bump the version.**
   On a branch, run the version script with all three numbers:

   ```powershell
   pwsh tools/build/Set-AtlasVersion.ps1 -Version <version>
   ```

   It sets `<Version>` in `playbook/playbook.conf`, adds the previous version to `<UpgradableFrom>`, and sets the same version in `app/Cargo.toml` and `app/Cargo.lock`.
   If `playbook.conf` already has the version, the script only brings the other files in line with it.
   Tester builds and the release workflow both stop when Atlas Manager's version and `playbook.conf` disagree.
   Review `SupportedBuilds` and `UpgradableFrom` in the diff.
   If the [release catalog](windows-release-policy.md#updating-the-catalog) is behind Microsoft's page, refresh it in the same branch.
   Open the release pull request with these changes; it's where you record the evidence.

2. **Build the release files.**
   Build the Atlas package with every eligibility gate, then the stable Atlas Manager:

   ```powershell
   pwsh -NoProfile -File tools/build/Build-Playbook.ps1 -FileName 'Atlas v<version>' -DontOpenPbLocation
   pwsh -NoProfile -File app/tools/Build-Release.ps1
   ```

   The package goes to `playbook/` and Atlas Manager to `app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe`.
   Don't use `-LocalTest` or `-Removals` for a release: both strip the checks that refuse unsupported PCs.
   To give testers a candidate, build a [tester build](building.md#tester-builds) from the same commit instead.

3. **Verify the package.**
   `Test-Apbx.ps1` checks the archive against the source tree and exits 1 if any check fails:

   ```powershell
   pwsh -NoProfile -File tools/build/Test-Apbx.ps1 -Path 'playbook/Atlas v<version>.apbx'
   ```

   [Verifying a build](building.md#verifying-a-build) lists what it checks.

4. **Run the checks.**
   Every check in the [testing guide](testing.md) must pass on the release commit: PSScriptAnalyzer, the Windows PowerShell 5.1 parse gate, both Pester suites, the generators with `-Validate`, and the Atlas Manager tests, formatting and Clippy.
   CI runs them on every push, so a green run on the commit you'll tag covers this step.

5. **Run the VM and device checks.**
   Work through the [release verification matrix](release-verification-matrix.md) and the [release checks](testing.md#release-checks) for the areas the release changed.
   Use the files from steps 2 and 3, or a tester build of the same commit, and start each run from a clean checkpoint.

6. **Record the evidence.**
   Add the results to the release pull request with the hashes of the files you tested, as the [matrix](release-verification-matrix.md#where-the-evidence-goes) describes.
   Before merging, check the proposed contents as [publication contents](publication.md#before-a-release) describes.
   A maintainer listed in `.github/CODEOWNERS` approves and merges the pull request.

7. **Tag the release.**
   Tag the merged commit with `v` and the version, and push the tag:

   ```powershell
   git tag v<version>
   git push origin v<version>
   ```

   The tag starts `.github/workflows/release.yml`.
   It stops unless the tag is `v<major>.<minor>.<patch>` and matches `<Version>` in `playbook.conf`, and unless `AtlasManager.exe` reports the same version.
   It builds the stable Atlas Manager and the Atlas package, verifies the package with `Test-Apbx.ps1`, and writes `SHA256SUMS.txt`.
   It then attests the three files and creates a draft release through the `release` environment, which must set the variable `ATLAS_RELEASE_ENABLED` to `true`.

8. **Publish.**
   Download the draft's files and check each one against `SHA256SUMS.txt` and its attestation:

   ```powershell
   gh attestation verify AtlasManager.exe --repo Atlas-OS/Atlas
   ```

   The release workflow builds the files again from the tag, so they aren't byte for byte the files your VM runs used.
   Repeat the fresh install from the matrix with the draft's `AtlasManager.exe`, using **Open package file** on the **Get ready** page to open the draft's `.apbx`.
   Add the hashes to the release pull request.
   Write the release notes, then publish the draft.

> [!WARNING]
> Publishing makes the release GitHub's latest release, and Atlas Manager offers it to every user straight away.
> Don't publish a draft whose evidence is incomplete.

## Related pages

- [Building the Atlas package](building.md) covers build options, tester builds and the Linux cross-build.
- [Testing](testing.md) covers each automated check and the lab VM run.
- [Publication contents](publication.md) covers what belongs in Git and the review before a release.
- [Release verification matrix](release-verification-matrix.md) lists the evidence each release needs.
