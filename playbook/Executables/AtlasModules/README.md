# Binary inventory

This file lists every executable, archive and Windows component package in the Atlas package, with its SHA-256 hash, source and licence.
It's for reviewers who verify those binaries and for maintainers who replace one.

Every `.exe`, `.dll`, `.cab` and `.zip` file under `playbook/Executables` has an entry here.
No test checks this, so compare the list with the files whenever you add, replace or remove a binary.

Paths start at `playbook/Executables`.
Hashes are upper-case SHA-256, as `Get-FileHash` prints them; on Linux, upper-case the output of `sha256sum`.

On an installed PC, `%windir%\AtlasModules\LICENSE` holds the Atlas project licence.
Third-party components keep their own licences, listed with each entry.

## Multi-Choice

| Path | SHA-256 |
| --- | --- |
| `AtlasModules/Tools/multichoice.exe` | `6AB2FF0163AFE0FAC4E7506F9A63293421A1880076944339700A59A06578927D` |

- Version: v0.4
- Source: the [multichoice-v0.4 release](https://github.com/Atlas-OS/utilities/releases/download/multichoice-v0.4/multichoice-compressed.exe) of [Atlas-OS/utilities](https://github.com/Atlas-OS/utilities), renamed from `multichoice-compressed.exe`
- Licence: [GNU General Public License v3.0](https://github.com/Atlas-OS/utilities/blob/main/LICENSE)
- Used by: the `SendToContextMenu` toggle, which shows its Send To choice dialog with this tool (`Atlas.Shell/Domain/SendTo.ps1`)

## SetTimerResolution and MeasureSleep

| Path | SHA-256 |
| --- | --- |
| `AtlasModules/Tools/SetTimerResolution.exe` | `67592C7DA1728E2084A5F1E17AA4312E49F3D48DF21ADB0844E66259D4489EBD` |
| `AtlasDesktop/3. General Configuration/Timer Resolution/! MeasureSleep.exe` | `952C19EA42CC8733BCCC07624E952266054FFB6AB50A80090B60A76C3A71E7E4` |
| `AtlasModules/Sources/TimerResolution-source.zip` | `0C546BC247E6D66AA94048DFB161F45837E0DDB9CD591BC1C28F0536234B2306` |

- Version: TimerResolution v1.0.0 with Atlas patches.
  SetTimerResolution comes from [commit edf6102](https://github.com/valleyofdoom/TimerResolution/tree/edf6102dbe9cd84fd973f00b0add44d3e9d62801) and MeasureSleep from [commit 79b5c6a](https://github.com/valleyofdoom/TimerResolution/tree/79b5c6a8b2015cd1376b60753cd2c9bd5fe1326f).
- Source: Atlas builds both executables with the [timer build recipe](../../../tools/timer/README.md).
  `tools/timer/accepted-build.json` records the accepted source, compiler and output hashes.
  `TimerResolution-source.zip` is the corresponding source for both: the patched C++, the args header, the patches, the pinned inputs, the build recipe and both licence texts.
- Licence: GNU General Public License v3.0.
  The header-only [args 6.4.6](https://github.com/Taywee/args/tree/e3e6e46699f1ce487a42fd64838f53daeb5aa89b) library uses the MIT License.
- Used by: the `TimerResolution` toggle, whose Enable state registers the `Force Timer Resolution` scheduled task that runs SetTimerResolution.
  MeasureSleep sits in the Atlas desktop folder for people to run themselves.

## ViVeTool

| Path | SHA-256 |
| --- | --- |
| `AtlasModules/Tools/ViVeTool-v0.3.3.zip` | `59D1E792EDCC001A319C16435A03D203975BF50EB38BD55CA34370900606F9F0` |
| `AtlasModules/Tools/ViVeTool-v0.3.3-ARM64CLR.zip` | `37708C95C5053539CD068460E28E565D6B25A33C87F09B6B91A4F82A18E30132` |

- Version: v0.3.3
- Source: the [x64 archive](https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3.zip) and the [Arm64 archive](https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3-ARM64CLR.zip) from the v0.3.3 release of [thebookisclosed/ViVe](https://github.com/thebookisclosed/ViVe)
- Licence: [GNU General Public License v3.0](https://github.com/thebookisclosed/ViVe/blob/master/LICENSE)
- Used by: `Scripts/Operations/Update-ClientCbs.ps1`, which the "Modify Client.CBS" install tweak runs to turn off Windows feature IDs

## StoreFixer

| Path | SHA-256 |
| --- | --- |
| `AtlasModules/Tools/StoreFixer.exe` | `A87F5E85FA2BF1461FBB0DEB1070C184C46F0924EE805F3D0F0D42D3504F67FA` |

- Version: 0.0.4
- Source: the [StoreFixer 0.0.4 release asset](https://github.com/TheyCreeper/StoreFixer/releases/download/0.0.4/StoreFixer.exe) from [TheyCreeper/StoreFixer](https://github.com/TheyCreeper/StoreFixer), byte-identical to the file in the Atlas package
- Licence: [CC0 1.0 Universal](https://github.com/TheyCreeper/StoreFixer/blob/main/LICENSE)
- Used by: the `FixMSStoreIssues` troubleshooting toggle

## CBS component packages

| Path | SHA-256 |
| --- | --- |
| `AtlasModules/Packages/Z-Atlas-NoDefender-Package31bf3856ad364e35amd645.0.0.0.cab` | `6A8D1F8788277B425766FAD069A8192EDC33EEA2D6F7F9B061A42C941A21D2EC` |
| `AtlasModules/Packages/Z-Atlas-NoDefender-Package31bf3856ad364e35arm645.0.0.0.cab` | `39500FA6DF403F162C02A9C36D37D2C787BF459C05376872B9962FA649F4E081` |
| `AtlasModules/Packages/Z-Atlas-NoTelemetry-Package31bf3856ad364e35amd645.0.0.0.cab` | `11C5E3502DCB962F2FAE456712C7982DC1864D686B76194628CBFF8D1CD77ECA` |
| `AtlasModules/Packages/Z-Atlas-NoTelemetry-Package31bf3856ad364e35arm645.0.0.0.cab` | `C6526330F660E654B249B63A974793BAE0E39F6714A0B79E03942145195E29A3` |

- Version: 5.0.0.0, the package version in each file name
- Source: built from the configs in `tools/sxsc` by the [Atlas-OS/sxsc](https://github.com/Atlas-OS/sxsc) builder, pinned by full commit SHA in `SXSC_REF` in `.github/workflows/build.yml`.
  The [CAB build guide](../../../tools/sxsc/README.md) covers how CI builds candidate CABs.
- Licence: built from configs in this repository, which the [project licence](../../../LICENSE) covers
- Used by: `Install-AtlasCbsPackage` (Atlas.Software), when the install or the Defender and telemetry toggles remove those components.
  It checks each CAB against `AtlasModules/Packages/Atlas-CbsHashes.psd1` first.

## Replace a binary

1. Replace the file under `playbook/Executables`.
   For a CAB, verify it against the CI candidate artifact it came from.
2. Hash it and update its entry here: path, SHA-256, version and source.

   ```powershell
   Get-FileHash -Algorithm SHA256 -LiteralPath <path>
   ```

3. For a CAB, regenerate `AtlasModules/Packages/Atlas-CbsHashes.psd1` with the command in its header.
   The install refuses any CAB whose name or hash isn't in that file, and `tests/Atlas.PayloadLayout.Tests.ps1` fails when the file and the CABs differ.
4. For the timer tools, rebuild and accept the build as the [timer build recipe](../../../tools/timer/README.md) describes.
   `tests/Atlas.TimerProvenance.Tests.ps1` fails when the executables or the source archive differ from `tools/timer/accepted-build.json`.
5. Compare this inventory with the binaries in the package, since no test does.

   ```powershell
   Get-ChildItem -LiteralPath playbook/Executables -Recurse -File -Include *.exe, *.dll, *.cab, *.zip |
       Get-FileHash -Algorithm SHA256
   ```
