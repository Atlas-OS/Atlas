# Sources

Some of the Playbook contains binary executables. This file provides verification for those files, by listing the SHA256 hashes, sources, and when each was last verified/checked. Hashes are uppercase SHA256, as produced by `Get-FileHash` in PowerShell or `sha256sum` (uppercased) on Linux.

**Completeness contract**: every binary file shipped under `playbook\Executables` (`.exe`, `.dll`, `.cab`, `.zip`) is listed here. Completeness and all hashes last cross-checked against disk on 7/5/2026.

The root of the file paths listed here starts in `playbook\Executables`.

## Multi-Choice

- Path: `\AtlasModules\Tools\multichoice.exe`
- SHA256 Hash: `6AB2FF0163AFE0FAC4E7506F9A63293421A1880076944339700A59A06578927D`
- Source: https://github.com/Atlas-OS/utilities/releases/download/multichoice-v0.4/multichoice-compressed.exe
- Repository: https://github.com/Atlas-OS/utilities
- Version: v0.4
- Renamed to `multichoice.exe`
- License: [GNU General Public License v3.0](https://github.com/Atlas-OS/utilities/blob/main/LICENSE)
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk)

## SetTimerResolution & MeasureSleep

- Path: `\AtlasModules\Tools\SetTimerResolution.exe`
    - SHA256 Hash: `0515C2428E8960C751AD697ACA1C8D03BD43E2F0F1A0C0D2B4D998361C35EB57`
    - Original source: `https://github.com/deaglebullet/TimerResolution/releases/download/SetTimerResolution-v1.0.0/SetTimerResolution.exe` (defunct — see note)
    - Version: v1.0.0
- Path: `\AtlasDesktop\3. General Configuration\Timer Resolution\! MeasureSleep.exe`
    - SHA256 Hash: `377AC4DAF2590AE6AC4703E8B9B532CB1D2041EB0AFE7AD4F62546AF32BE1B11`
    - Original source: `https://github.com/deaglebullet/TimerResolution/releases/download/MeasureSleep-v1.0.0/MeasureSleep.exe` (defunct — see note)
    - Version: v1.0.0
- Repository: https://github.com/valleyofdoom/TimerResolution (current upstream project)
- License: [GNU General Public License v3.0](https://github.com/valleyofdoom/TimerResolution/blob/main/LICENSE)
- Note: as of 7/5/2026 the `deaglebullet/TimerResolution` repository these exact assets were downloaded from no longer exists on GitHub. The upstream project (also credited as "amitxv" in `\AtlasModules\Acknowledgements`) publishes releases with the same tags at `valleyofdoom/TimerResolution`, but its current `SetTimerResolution-v1.0.0`/`MeasureSleep-v1.0.0` assets do not hash-match the shipped files (likely rebuilt binaries of the same source). The shipped files therefore currently have no retrievable public download; source code is available in the upstream repository.
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk)

## ViVeTool

- Path: `\AtlasModules\Tools\ViVeTool-v0.3.3.zip`
    - SHA256 hash: `59D1E792EDCC001A319C16435A03D203975BF50EB38BD55CA34370900606F9F0`
    - Source: https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3.zip
    - Version: v0.3.3
- Path: `\AtlasModules\Tools\ViVeTool-v0.3.3-ARM64CLR.zip`
    - SHA256 hash: `37708C95C5053539CD068460E28E565D6B25A33C87F09B6B91A4F82A18E30132`
    - Source: https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3-ARM64CLR.zip
    - Version: v0.3.3
- Repository: https://github.com/thebookisclosed/ViVe
- License: [GNU General Public License v3.0](https://github.com/thebookisclosed/ViVe/blob/master/LICENSE)
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk)

## StoreFixer

- Path: `\AtlasModules\Tools\StoreFixer.exe`
- SHA256 Hash: `A87F5E85FA2BF1461FBB0DEB1070C184C46F0924EE805F3D0F0D42D3504F67FA`
- Source: https://github.com/TheyCreeper/StoreFixer/releases/download/0.0.4/StoreFixer.exe (release asset is bit-identical to the shipped file)
- Repository: https://github.com/TheyCreeper/StoreFixer
- Version: 0.0.4
- License: [CC0 1.0 Universal](https://github.com/TheyCreeper/StoreFixer/blob/main/LICENSE)
- Used by the Revert phase (`\AtlasModules\Scripts\Phases\Invoke-RevertPhase.ps1`) and the "Fix Microsoft Store Issues" troubleshooting toggle.
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk and against the upstream release asset)

## YamlDotNet

- Path: `\YamlDotNet.dll`
- SHA256 Hash: `9172F0758ED76963E0EDE3B5CA9A1FB5B82F64C7E7A92CB3A6DE39EFA933A668`
- Source: https://www.nuget.org/packages/YamlDotNet/16.3.0 (the shipped file is bit-identical to `lib/net47/YamlDotNet.dll` inside the NuGet package)
- Repository: https://github.com/aaubry/YamlDotNet
- Version: 16.3.0
- License: [MIT](https://github.com/aaubry/YamlDotNet/blob/master/LICENSE.txt)
- Note: YAML parsing library formerly loaded by the default-user-hive script (`APPLYDUHIVE.ps1`). That script has since been replaced by the PowerShell framework's hive sync, and no current script references this DLL.
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk and against the NuGet package contents)

## CBS component packages

- Path: `\AtlasModules\Packages\Z-Atlas-NoDefender-Package31bf3856ad364e35amd645.0.0.0.cab`
    - SHA256 Hash: `6A8D1F8788277B425766FAD069A8192EDC33EEA2D6F7F9B061A42C941A21D2EC`
- Path: `\AtlasModules\Packages\Z-Atlas-NoDefender-Package31bf3856ad364e35arm645.0.0.0.cab`
    - SHA256 Hash: `39500FA6DF403F162C02A9C36D37D2C787BF459C05376872B9962FA649F4E081`
- Path: `\AtlasModules\Packages\Z-Atlas-NoTelemetry-Package31bf3856ad364e35amd645.0.0.0.cab`
    - SHA256 Hash: `11C5E3502DCB962F2FAE456712C7982DC1864D686B76194628CBFF8D1CD77ECA`
- Path: `\AtlasModules\Packages\Z-Atlas-NoTelemetry-Package31bf3856ad364e35arm645.0.0.0.cab`
    - SHA256 Hash: `C6526330F660E654B249B63A974793BAE0E39F6714A0B79E03942145195E29A3`
- Provenance: Built by CI from the configs in `tools/sxsc` using the external builder pinned by full commit SHA (`SXSC_REF` in `.github/workflows/build.yml`) and committed back by the build workflow. Hashes change whenever CI rebuilds them; verify by comparing against the most recent build-workflow run.
- Repository (builder): https://github.com/Atlas-OS/sxsc
- Last Verified: 7/5/2026 by advisor audit (`sha256sum`, cross-checked against disk)
