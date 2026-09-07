# App performance

Use a release build for measurements. Debug builds optimise dependencies but retain
Atlas's debugging information, and do not represent the distributed executable.

## Measuring changes

Run from `app/`:

```powershell
powershell -NoProfile -File tools/Build-Release.ps1
.\tools\Measure-AppPerformance.ps1 -Executable .\target\x86_64-pc-windows-msvc\release\AtlasManager.exe -Runs 3 -OutFile measurements.json
```

The harness uses isolated app data and does not start an installation. It measures
window creation, idle CPU, memory and a resize workload. Compare repeated runs on
the same machine with the same window size, scale, theme and power settings. Keep
raw samples and executable hashes with the pull request that uses them.

Window creation is not the first rendered frame. CPU percentages represent one
logical core. Startup update checks use the network and can outlast the settling
period. A few smoke runs cannot establish a sustained memory trend or a performance
gain; profile the relevant workload before drawing those conclusions.

## Build settings

The compiler is pinned in `rust-toolchain.toml`; dependencies are locked in
`Cargo.lock`. The app selects GPUI's Windows backend directly. ZIP support retains
AES and Deflate for playbook extraction.

Release builds use thin LTO, four codegen units and abort on panic. The production
build script links the C runtime statically. Development dependencies omit debug
symbols; enable them when investigating dependency code:

```powershell
cargo build --config 'profile.dev.package."*".debug=true'
```

CI disables incremental compilation and caches build output. To inspect compilation
time locally, use `cargo build --release --locked --timings`.

## Runtime considerations

Slow work runs on background tasks. Provider calls that cannot be cancelled have
bounded workers; install logs use a bounded display tail and retain the full log on
disk. Preserve these limits when changing progress or polling behaviour.

GPUI's Windows backend has a VSync loop that wakes even when the frame handler has
nothing to draw. Profile that loop when investigating idle power use. Atlas does
not add a continuous Home-page polling timer.
