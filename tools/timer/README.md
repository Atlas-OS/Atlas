# Timer tool builds

This folder holds the recipe that builds the two timer utilities in the Atlas package, `SetTimerResolution.exe` and `MeasureSleep.exe`, from pinned source.
It's for maintainers who rebuild those utilities or check where they come from.

Both utilities come from [valleyofdoom/TimerResolution](https://github.com/valleyofdoom/TimerResolution), under the GNU General Public License v3.0.
They use the header-only [args](https://github.com/Taywee/args) library, under the MIT License.

| File | Purpose |
| --- | --- |
| `Build-TimerTools.ps1` | Downloads the pinned inputs, applies the patches and compiles both utilities. |
| `inputs.json` | Pins each source file and licence text by URL and SHA-256. |
| `MeasureSleep.patch`, `SetTimerResolution.patch` | The Atlas changes to the upstream source. |
| `accepted-build.json` | The build manifest of the utilities in the Atlas package. |
| `.gitattributes` | Turns off line-ending conversion for `.json` and `.patch` files, so their bytes match the manifest. |

## Build

You need PowerShell 7, Git, the MSVC 14.44.35207 toolset and the Windows SDK 10.0.26100.0.

```powershell
./tools/timer/Build-TimerTools.ps1 -OutputDirectory <new-folder>
```

| Parameter | Meaning |
| --- | --- |
| `-OutputDirectory` | Required: a folder that doesn't exist yet, so an earlier build is never overwritten. |
| `-VisualStudio` | The Visual Studio installation with the MSVC toolset, by default Visual Studio 2022 Build Tools under `%ProgramFiles(x86)%`. |
| `-WindowsKits` | The Windows Kits folder with the SDK, by default `%ProgramFiles(x86)%\Windows Kits\10`. |

The script:

1. Downloads each file in `inputs.json` into `<new-folder>/source`, and stops if a SHA-256 doesn't match.
2. Copies `inputs.json`, both patches and itself into `source`.
3. Checks that each patch applies, then applies it with `git apply`.
4. Clears the `CL`, `_CL_`, `LINK` and `_LINK_` environment variables for the build, so local compiler options can't change the output.
5. Compiles both utilities for x64 with the static C runtime (`/MT`) and `/Brepro` for reproducible output.
6. Writes `build-manifest.json`, and `corresponding-source.zip` with the contents of `source`.

The manifest records the compiler version and SHA-256, the toolset, the SDK, the compiler flags, the inputs, and the SHA-256 of every source file and executable.
The script doesn't change files under `playbook/`.

> [!WARNING]
> The script doesn't run the utilities, and you shouldn't run them on your development PC to check a build.
> `SetTimerResolution.exe` changes the system timer resolution, and `MeasureSleep.exe` raises itself to real-time priority.

## Patches

`MeasureSleep.patch` makes three changes:

- It requires at least three samples (`--samples`), because the first sample is discarded and the standard deviation needs at least two of the rest.
- It rejects a negative sleep duration (`--sleep_n`) before the value reaches the unsigned argument of Windows' `Sleep`.
- It measures the delta against the requested sleep duration instead of a fixed 1 ms.

`SetTimerResolution.patch` rejects a resolution of zero or less before the native call.
Valid arguments work as they do upstream, so the scheduled task in `playbook/Executables/AtlasModules/Other/Force Timer Resolution.xml` keeps running `SetTimerResolution --resolution 5060 --no-console`.

## Accept a build

1. Build into two new folders, and check that the `outputs` hashes in both `build-manifest.json` files match.
2. Check timer behaviour on a disposable VM or test PC.
3. Copy the build into the Atlas package:

   | Build output | Destination |
   | --- | --- |
   | `SetTimerResolution.exe` | `playbook/Executables/AtlasModules/Tools/SetTimerResolution.exe` |
   | `MeasureSleep.exe` | `playbook/Executables/AtlasDesktop/3. General Configuration/Timer Resolution/! MeasureSleep.exe` |
   | `corresponding-source.zip` | `playbook/Executables/AtlasModules/Sources/TimerResolution-source.zip` |

4. Replace `accepted-build.json` with the new `build-manifest.json`.
5. Update the SHA-256 values in the [binary inventory](../../playbook/Executables/AtlasModules/README.md).
6. Run `tests/Atlas.TimerProvenance.Tests.ps1` in Windows PowerShell 5.1, as [Testing](../../docs/testing.md) describes.

The test checks three things:

- Both executables match the `outputs` in `accepted-build.json`.
- `TimerResolution-source.zip` holds exactly the `sourceFiles`, with matching SHA-256 values, including both licence texts.
- `Build-TimerTools.ps1`, `inputs.json` and both patches in this folder match their `sourceFiles` entries.

Any change to the script, `inputs.json` or a patch therefore needs a new accepted build.

Keep `TimerResolution-source.zip` in the Atlas package whenever it includes the executables, because it's their corresponding source.
