# Compatibility code and files

Atlas keeps a few files, and some code, only because something outside this repository, an older Atlas install or an earlier Atlas Manager still depends on them.
This page is for contributors.
Each entry names what depends on it and the condition under which it can go.
Check the consumers, the packaging and the update path again before you remove any of them.

## Files

File paths are relative to `%windir%\AtlasModules`, where the Atlas package installs them.

| Path | Pinned by | Remove when |
| --- | --- | --- |
| `Scripts\RunAsTI.cmd`, a stub that refuses to run | Shortcuts and context-menu commands that Atlas 0.5.x and earlier wrote | `updatableFrom` in `package/atlas.json` contains no 0.5.x version |
| `Scripts\Install\Compat\Remove-AtlasLegacyElevationArtifacts.ps1`, run by the PreInstall phase | Registry commands, tasks and shortcuts that Atlas 0.5.x elevation helpers left, and the records Atlas Toolbox 0.1.x wrote outside the toggle store | Same as above |
| The `Toolbox\Scripts\` launchers: `toggleDefender.cmd`, `vbsCurrentConfig.cmd`, `viewBootValues.cmd`, `NVidia\{Disable,Enable}NVIDIADisplayContainerLS.cmd`, `SuperFetch\DisableSuperFetch.cmd`, `Troubleshooting\{Fix Errors 2502 and 2503,Repair Windows Components,Telemetry Components}.cmd` and `Troubleshooting\TroubleshootingNetwork\{AtlasDefault,WindowsDefault}.cmd` | Atlas Toolbox releases before 0.2.0, which run these by fixed path, and the NVIDIA pair also from the context menu those releases add. Toolbox 0.2.0 and later read `Toggles\catalog.json` and run toggles by name. | No supported Atlas install keeps a Toolbox release before 0.2.0 |
| `Scripts\Registry\SecurityHealthTray\*.reg`, byte-identical to `Toolbox\Scripts\SecurityHealthTray\*.reg` | The same Toolbox path contract | Same as above |
| `Scripts\Entry\Set-IndexConfiguration.cmd`, `Test-EdgeState.cmd`, `Test-Winget.cmd` and `Set-SettingsPageVisibilityLauncher.cmd` | Command-line entry points documented for support, used by the software picker and the CBS update helper | Their PowerShell targets get a documented entry of their own that cleans the environment |
| `Flags\*.flag` after an install completes | PCs installed before the state document existed. Every Atlas reader uses `%windir%\AtlasOS\state.json`, and falls back to the flags only when it's missing. | The oldest version `updatableFrom` lists wrote the state document |
| `HKLM\SOFTWARE\AtlasOS\Services` as the toggle store, mirrored into `state.json` | Atlas Toolbox releases before 0.2.0, which read the registry. Toolbox 0.2.0 and later read the `toggles` section of `state.json`. | No supported Atlas install keeps a Toolbox release before 0.2.0 |

Tests hold these contracts in place:

- `tests/Atlas.ToolboxLaunchers.Tests.ps1` pins each Toolbox launcher path, with the toggle and state it runs.
- `tests/Atlas.PackageLayout.Tests.ps1` checks that each `SecurityHealthTray` pair stays identical.

How Atlas replays the toggle records in that store, and why it replays every record, is described in [Toggle records](install-state.md#toggle-records).

## Code

This code reads or cleans up what earlier releases left on a PC.
Paths are relative to the repository root.

| Code | What it handles | Remove when |
| --- | --- | --- |
| The `playbookDir` alias of `package_dir` in `InstallDraft` (`app/src/services/settings.rs`) and `InstallRequest` (`app/src/services/installer/mod.rs`) | Saved drafts and install session records that 0.6.0 test builds wrote, which name the unpacked package `playbookDir` | Support for the 0.6.0 test builds ends |
| `prune_legacy_jobs` in `app/src/services/iso.rs`, run when ISO or USB creation starts | ISO jobs that 0.6.0 test builds kept in the `ISO` folder of Atlas Manager's app data, which it prunes and then removes | Same as above |
| `remove_old_cache` in `app/src/services/package.rs`, which Atlas Manager runs at start-up when no install or preparation is running | Packages that 0.6.0 test builds unpacked in the `Playbooks` folder of its app data, which nothing reads | Same as above |
| The `ISO` and `Preparation` folders that diagnostics collect from Atlas Manager's app data, in `app/src/services/diagnostics.rs` | ISO and preparation jobs that 0.6.0 test builds kept there | Same as above |
| `Remove-AtlasStagedPackage` deleting `playbook.conf`, in `package/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1` | Staging copies that 0.6.0 test builds made, which hold `playbook.conf` where `atlas.json` sits | Same as above |
| The `abandoned.json` recovery in `Start-AtlasInstallState`, in `package/Executables/AtlasModules/Scripts/Modules/Atlas.InstallState/` | A failed Fresh run that a 0.6.0 test build archived as `%windir%\AtlasOS\Install\abandoned.json`, which a Reapply of the same version resumes | Same as above |
| The `Atlas Playbook v<version>` form that `ConvertFrom-AtlasVersionMarker` (`package/Executables/AtlasModules/Scripts/Preparation/WindowsTransition.ps1`) and `marker_version` (`app/src/services/atlas_state.rs`) accept | The version marker that releases before Atlas 0.6 wrote, as [the package format](package-format.md#the-version-recorded-in-windows) describes | `updatableFrom` in `package/atlas.json` contains only versions 0.6 and later |
| `earlier_marker_version` in `app/src/services/atlas_state.rs`, which reads `AtlasOS v<version>` | The OEM model name that releases before Atlas 0.4.1 wrote, so **Home** names such an install as one no package updates | Naming those releases no longer matters: without it, they get the message for Atlas's files without a record, which offers the same Atlas ISO |

## Rules

- A file kept for compatibility isn't the implementation.
  It forwards to, or is generated from, the one implementation under `Scripts\` or `Toggles\`.
- Each Toolbox launcher is a stub that `tools/dev/New-ToggleLaunchers.ps1` generates from its toggle's `ToolboxLauncher` declaration.
  Declare one only for a path that a Toolbox release before 0.2.0 opens.
- Every entry names its consumer and its removal condition on this page.
  Adding compatibility code or a compatibility file without both blocks the review.
- When `updatableFrom` changes, revisit every entry that mentions a removed version.
