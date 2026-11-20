# CBS package configs

This folder holds the configs for the four CBS packages (CABs) in the Atlas package.
It's for maintainers who change which Windows components the packages replace, or who rebuild the CABs.

| Config | Package | Architecture |
| --- | --- | --- |
| `Atlas-Defender-Remover.yaml` | `Z-Atlas-NoDefender-Package` | amd64 |
| `Atlas-Defender-Remover-Arm.yaml` | `Z-Atlas-NoDefender-Package` | arm64 |
| `Atlas-NoTelemetry.yaml` | `Z-Atlas-NoTelemetry-Package` | amd64 |
| `Atlas-NoTelemetry-Arm.yaml` | `Z-Atlas-NoTelemetry-Package` | arm64 |

The NoDefender package covers Microsoft Defender, SmartScreen and their related components.
The NoTelemetry package covers telemetry, compatibility appraisal and feedback components.
Each config names its package and lists the Windows components it updates, with the architecture and version of each, and any registry values an update sets.
The built CABs live in `playbook/Executables/AtlasModules/Packages`.

## How CI builds candidate CABs

The Build Atlas package workflow, `.github/workflows/build.yml`, builds CABs when a push changes a config in this folder.
It rebuilds all four in these cases:

- a manual run (`workflow_dispatch`);
- a push that deletes a config;
- a file named `regenAllConfigs` in this folder;
- a push with no usable previous commit to compare with, such as the first push of a branch or a force push.

For the selected configs, the workflow:

1. Fetches the builder, [Atlas-OS/sxsc](https://github.com/Atlas-OS/sxsc), at the full commit SHA in `SXSC_REF`, and stops if the checked-out commit differs.
2. Creates a signing certificate, then runs the builder's `sxsc.py` and `start-build.ps1` for each config.
3. Regenerates `Atlas-CbsHashes.psd1` in its workspace, so the CI Atlas package from the same run carries the new CABs.
4. Uploads the CABs with a `SHA256SUMS.txt` as the artifact `Atlas-CAB-candidates-<commit>`, which GitHub keeps for seven days.

The workflow has read-only access to the repository, so it never commits CABs.
To change the builder, set `SXSC_REF` to the full SHA of the new commit.

The signing certificate changes with every build, so Atlas can't pin its thumbprint.
Atlas pins each CAB's SHA-256 in `Atlas-CbsHashes.psd1` instead, and refuses to install a CAB that's missing from that file or doesn't match its hash.

## Accept candidate CABs

1. Download the `Atlas-CAB-candidates-<commit>` artifact, and check each CAB against its `SHA256SUMS.txt`.
2. Test the `Atlas-CI-<commit>` artifact from the same run, which is built with those CABs, on a disposable VM of each architecture you changed.
3. Replace the CABs in `playbook/Executables/AtlasModules/Packages`.
4. Regenerate `playbook/Executables/AtlasModules/Packages/Atlas-CbsHashes.psd1` with the command in its header comment.
5. Update the SHA-256 values in the CBS component packages section of the [binary inventory](../../playbook/Executables/AtlasModules/README.md).
6. Run `tests/Atlas.PayloadLayout.Tests.ps1`, which fails if `Atlas-CbsHashes.psd1` and the CABs in the folder differ.

Commit the CABs, `Atlas-CbsHashes.psd1` and the binary inventory together, so the tests pass at every commit.
