# Release candidate tools

This folder holds the scripts that build release candidates for testers.
It's for maintainers; the procedure, what a tester build disables and how to verify one are in [Tester builds (release candidates)](../../app/docs/rc-testers-build.md).

| File | Purpose |
| --- | --- |
| `build-rc.sh` | Builds one release-candidate ZIP on Linux: the production Atlas package, Atlas Manager with that package embedded, notices and the tester notice. |
| `setup-linux.sh` | Installs the user-scoped Rust cross-build tools: the pinned Rust toolchain, the `x86_64-pc-windows-msvc` target and the pinned cargo-xwin. |
| `Add-BundledToolbox.ps1` | Copies a Toolbox installer into a staged copy of the Atlas package source. |
| `README-RC.txt` | The tester notice template that `build-rc.sh` fills in. |

## Build a candidate

The system prerequisites, such as PowerShell 7, 7-Zip and the LLVM tools, are in the Linux desktop cross-build section of [Building the Atlas package](../../docs/building.md).
Run `setup-linux.sh` once, then build candidate `<n>`:

```sh
tools/release/setup-linux.sh
tools/release/build-rc.sh --rc <n>
```

The output goes to `artifacts/rc/<version>-rc.<n>/`, with the ZIP, the `.apbx` and `SHA256SUMS.txt`.
`<version>` comes from `<Version>` in `playbook/playbook.conf`, which must match the `[package]` version in `app/Cargo.toml`.
Nothing is tagged or published; you post the ZIP and its checksum lines by hand.

`build-rc.sh` builds a committed tree from an export of the commit's `playbook/`, so untracked and ignored files stay out.
It refuses uncommitted changes unless you pass `--allow-dirty`.
It then builds from the working tree, and the recorded commit ends in `-dirty`, so the candidate isn't publishable.

## Bundle a Toolbox

When a candidate needs a Toolbox release that isn't published yet, pass the installer and its version:

```sh
tools/release/build-rc.sh --rc <n> --toolbox <path>/AtlasToolbox-Setup.exe --toolbox-version <x.y.z>
```

`build-rc.sh` then runs `Add-BundledToolbox.ps1` on its staged copy of `playbook/`.
The script writes the installer to `Executables/AtlasModules/Bundled/Toolbox/AtlasToolbox-Setup.exe`, with `AtlasToolbox-Setup.json` beside it recording the version, SHA-256 and size.
Atlas installs that copy instead of the latest Toolbox release on GitHub, and checks the version afterwards.
The script refuses to write into the checkout's own `playbook/` folder, and releases carry no bundled Toolbox.

## Tester notice placeholders

`build-rc.sh` fills in these placeholders when it copies `README-RC.txt` into the ZIP.

| Placeholder | Filled with |
| --- | --- |
| `@RC_ID@` | The candidate id, `<version>-rc.<n>`. |
| `@COMMIT@` | The short source commit, ending in `-dirty` for a build with uncommitted changes. |
| `@SUPPORTED_BUILDS@` | The `<SupportedBuilds>` entries in `playbook/playbook.conf`, as "a, b and c". |
| `@UPGRADABLE_FROM@` | The `<UpgradableFrom>` entries in `playbook/playbook.conf`, as "a, b and c". |
| `@TOOLBOX_NOTE@` | A line naming the bundled Toolbox version, or nothing when there's no `--toolbox`. |

The build stops if the finished notice still holds a placeholder, so add a substitution to `build-rc.sh` with any new one.
Keep the notice true for every candidate: put facts that change between releases in a placeholder, not in the template.
