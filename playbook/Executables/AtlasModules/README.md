# Sources

Some of the Playbook contains binary executables. This file lists their SHA256 hashes and sources so the shipped files can be verified reproducibly. Hashes are uppercase SHA256, as produced by `Get-FileHash` in PowerShell or `sha256sum` (uppercased) on Linux.

**Completeness contract**: every binary file shipped under `playbook\Executables` (`.exe`, `.dll`, `.cab`, `.zip`) is listed here. Compare the inventory with the shipped files when replacing a binary.

The root of the file paths listed here starts in `playbook\Executables`.

The installed `AtlasModules\LICENSE` contains the Atlas project license.
Third-party components retain their separately documented terms.

## Multi-Choice

- Path: `\AtlasModules\Tools\multichoice.exe`
- SHA256 Hash: `6AB2FF0163AFE0FAC4E7506F9A63293421A1880076944339700A59A06578927D`
- Source: https://github.com/Atlas-OS/utilities/releases/download/multichoice-v0.4/multichoice-compressed.exe
- Repository: https://github.com/Atlas-OS/utilities
- Version: v0.4
- Renamed to `multichoice.exe`
- License: [GNU General Public License v3.0](https://github.com/Atlas-OS/utilities/blob/main/LICENSE)

## SetTimerResolution & MeasureSleep

- Path: `\AtlasModules\Tools\SetTimerResolution.exe`
    - SHA256 Hash: `67592C7DA1728E2084A5F1E17AA4312E49F3D48DF21ADB0844E66259D4489EBD`
    - Base source: [v1.0.0 commit edf6102](https://github.com/valleyofdoom/TimerResolution/tree/edf6102dbe9cd84fd973f00b0add44d3e9d62801), with the reviewed Atlas input-validation patch.
- Path: `\AtlasDesktop\3. General Configuration\Timer Resolution\! MeasureSleep.exe`
    - SHA256 Hash: `952C19EA42CC8733BCCC07624E952266054FFB6AB50A80090B60A76C3A71E7E4`
    - Base source: [v1.0.0 commit 79b5c6a](https://github.com/valleyofdoom/TimerResolution/tree/79b5c6a8b2015cd1376b60753cd2c9bd5fe1326f), with reviewed Atlas sample-count, duration-validation and delta-calculation patches.
- Path: `\AtlasModules\Sources\TimerResolution-source.zip`
    - SHA256 Hash: `0C546BC247E6D66AA94048DFB161F45837E0DDB9CD591BC1C28F0536234B2306`
    - Corresponding source for both shipped executables: exact patched C++, args header, original licenses, patches, pinned inputs and build recipe. This is an intentional payload source archive, not temporary build output.
- Rebuild using `tools/timer/Build-TimerTools.ps1`; `tools/timer/accepted-build.json` records the accepted source/compiler/output hashes. MSVC 14.44.35207, Windows SDK 10.0.26100.0, x64 static CRT. Two output directories produced byte-identical executables. The utilities were not executed during provenance review; runtime validation remains required before release.
- Timer source license: GNU GPL v3; header-only [args 6.4.6](https://github.com/Taywee/args/tree/e3e6e46699f1ce487a42fd64838f53daeb5aa89b) uses MIT. Both full license texts accompany the exact source in the payload archive.
- These source-built files replace legacy assets from the defunct `deaglebullet/TimerResolution` repository. Their old hashes could not be tied to corresponding source; no equivalence to those old binaries is claimed.

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

## StoreFixer

- Path: `\AtlasModules\Tools\StoreFixer.exe`
- SHA256 Hash: `A87F5E85FA2BF1461FBB0DEB1070C184C46F0924EE805F3D0F0D42D3504F67FA`
- Source: https://github.com/TheyCreeper/StoreFixer/releases/download/0.0.4/StoreFixer.exe (release asset is bit-identical to the shipped file)
- Repository: https://github.com/TheyCreeper/StoreFixer
- Version: 0.0.4
- License: [CC0 1.0 Universal](https://github.com/TheyCreeper/StoreFixer/blob/main/LICENSE)
- Used by the "Fix Microsoft Store Issues" troubleshooting toggle.

## CBS component packages

- Path: `\AtlasModules\Packages\Z-Atlas-NoDefender-Package31bf3856ad364e35amd645.0.0.0.cab`
    - SHA256 Hash: `6A8D1F8788277B425766FAD069A8192EDC33EEA2D6F7F9B061A42C941A21D2EC`
- Path: `\AtlasModules\Packages\Z-Atlas-NoDefender-Package31bf3856ad364e35arm645.0.0.0.cab`
    - SHA256 Hash: `39500FA6DF403F162C02A9C36D37D2C787BF459C05376872B9962FA649F4E081`
- Path: `\AtlasModules\Packages\Z-Atlas-NoTelemetry-Package31bf3856ad364e35amd645.0.0.0.cab`
    - SHA256 Hash: `11C5E3502DCB962F2FAE456712C7982DC1864D686B76194628CBFF8D1CD77ECA`
- Path: `\AtlasModules\Packages\Z-Atlas-NoTelemetry-Package31bf3856ad364e35arm645.0.0.0.cab`
    - SHA256 Hash: `C6526330F660E654B249B63A974793BAE0E39F6714A0B79E03942145195E29A3`
- Provenance: Built from the configs in `tools/sxsc` with the external builder pinned by full commit SHA (`SXSC_REF` in `.github/workflows/build.yml`). CI uploads short-lived CAB candidates for review; accepted candidates are committed separately. Verify a replacement against the candidate artifact before updating this inventory.
- Repository (builder): https://github.com/Atlas-OS/sxsc
