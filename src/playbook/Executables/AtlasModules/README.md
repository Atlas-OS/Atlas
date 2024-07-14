# Sources
Some of the Playbook contains binary executables. This file provides some verification for those files, by listing the SHA256 hashes, sources, and when each was last verified/checked. Hashes were collected using `Get-FileHash` in PowerShell.

The root of the file paths listed here starts in `src\playbook\Executables`.

### Multi-Choice

- Path: `\AtlasModules\Tools\multichoice.exe`
- SHA256 Hash: `6AB2FF0163AFE0FAC4E7506F9A63293421A1880076944339700A59A06578927D`
- Source: https://github.com/Atlas-OS/Atlas-Utilities/releases/download/multichoice-v0.4/multichoice-compressed.exe
- Repository: https://github.com/Atlas-OS/Atlas-Utilities
- Version: v0.4
- Renamed to `multichoice.exe`
- License: [GNU General Public License v3.0](https://github.com/Atlas-OS/utilities/blob/main/LICENSE)
- Last Verified: 5/24/2024 by Xyueta

## SetTimerResolution & MeasureSleep

- Path: `\AtlasModules\Tools\SetTimerResolution.exe`
    - SHA256 Hash: `0515C2428E8960C751AD697ACA1C8D03BD43E2F0F1A0C0D2B4D998361C35EB57`
    - Source: https://github.com/deaglebullet/TimerResolution/releases/download/SetTimerResolution-v1.0.0/SetTimerResolution.exe
    - Version: v1.0.0
- Path: `\AtlasDesktop\3. General Configuration\Power\Timer Resolution\! MeasureSleep.exe`
    - SHA256 Hash: `377AC4DAF2590AE6AC4703E8B9B532CB1D2041EB0AFE7AD4F62546AF32BE1B11`
    - Source: https://github.com/deaglebullet/TimerResolution/releases/download/MeasureSleep-v1.0.0/MeasureSleep.exe
    - Version: v1.0.0
- Repository: https://github.com/deaglebullet/TimerResolution
- License: [GNU General Public License v3.0](https://github.com/adeaglebullet/TimerResolution/blob/main/LICENSE)
- Last Verified: 5/24/2024 by Xyueta

## ViVeTool

> [!NOTE]  
> This is included in the Playbook and isn't in the AtlasModules.

- Path: `Executables\ViVeTool-v0.3.3.zip`
    - SHA256 hash: `59D1E792EDCC001A319C16435A03D203975BF50EB38BD55CA34370900606F9F0`
    - Source: https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3.zip
    - Version: v0.3.3
- Path: `Executables\ViVeTool-v0.3.3-ARM64CLR.zip`
    - SHA256 hash: `37708C95C5053539CD068460E28E565D6B25A33C87F09B6B91A4F82A18E30132`
    - Source: https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3-ARM64CLR.zip
    - Version: v0.3.3
- Repository: https://github.com/thebookisclosed/ViVe
- License: [GNU General Public License v3.0](https://github.com/thebookisclosed/ViVe/blob/master/LICENSE)
- Last Verified: 7/14/2024 by he3als