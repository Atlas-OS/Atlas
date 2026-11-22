# App performance

This page explains how to measure Atlas Manager's startup, idle and resize performance, and which build settings affect it.
It's for contributors who change the app's rendering, background work or build profile.

Use a release build for measurements.
Debug builds optimise dependencies but keep Atlas's own debugging information, and don't represent the distributed executable.

## Measuring changes

Run these from `app/`:

```powershell
pwsh -NoProfile -File tools/Build-Release.ps1
.\tools\Measure-AppPerformance.ps1 -Executable .\target\x86_64-pc-windows-msvc\release\AtlasManager.exe -Runs 3 -OutFile measurements.json
```

The harness uses isolated app data, runs the app in English, and never starts an installation or changes Windows settings.
For each run it:

1. opens the app on Home, or on Settings with `-Page settings`;
2. measures window creation;
3. waits 5 seconds for startup to settle;
4. records idle CPU over `-IdleSeconds` (5 by default, up to 60) and memory;
5. records CPU and wall time during a fixed resize workload.

`-Runs` takes 1 to 10.
The harness prints the JSON report, and saves it with `-OutFile`; the report includes the executable's SHA-256 and size and the number of logical processors.

Compare repeated runs on the same PC with the same window size, scale, theme and power settings.
Keep raw samples and executable hashes with the pull request that uses them.

- Window creation isn't the first rendered frame.
- CPU percentages represent one logical core.
- Startup update checks use the network, and can outlast the settling period.
- A few smoke runs can't establish a sustained memory trend or a performance gain; profile the relevant workload before drawing those conclusions.

## Build settings

`rust-toolchain.toml` pins the compiler, and `Cargo.lock` pins the dependencies.

- The app selects GPUI's Windows backend (`gpui-pre-windows`) directly through `src/platform.rs`, so the lockfile doesn't need GPUI's backends for other operating systems.
  The Windows manifest stays enabled.
- ZIP support keeps AES and Deflate for unpacking Atlas packages, without the unused Zopfli encoder.
- Release builds use thin LTO, four codegen units, stripped symbols and abort on panic.
  The production build script links the C runtime statically.
- Development builds leave out debug symbols for dependencies, and Atlas itself keeps full debugging information.

To investigate dependency code, turn dependency symbols on:

```powershell
cargo build --config 'profile.dev.package."*".debug=true'
```

CI turns off incremental compilation and caches build output.
To inspect compilation time locally, use `cargo build --release --locked --timings`.

## Runtime considerations

Slow work runs on background tasks.
Provider calls that can't be cancelled run on a limited number of workers.
Install logs keep a limited tail on screen and the full log on disk.
Keep these limits when you change progress or polling behaviour.

GPUI's Windows backend has a VSync loop that wakes even when the frame handler has nothing to draw.
Profile that loop when you investigate idle power use.
Atlas doesn't add a continuous polling timer to Home.
