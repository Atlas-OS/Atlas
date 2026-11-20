# Files kept for compatibility

Atlas keeps a few files only because something outside this repository, or an older Atlas install, still opens them by path.
This page is for contributors.
Each entry names the consumer that pins the file and the condition under which it can go.
Check the consumers, the packaging and the update path again before you remove any of them.

File paths are relative to `%windir%\AtlasModules`, where the Atlas package installs them.

| Path | Pinned by | Remove when |
| --- | --- | --- |
| `Scripts\RunAsTI.cmd`, a stub that refuses to run | Shortcuts and context-menu commands that Atlas 0.5.x and earlier wrote | `UpgradableFrom` in `playbook.conf` no longer lists any 0.5.x version |
| `Scripts\Install\Compat\Remove-AtlasLegacyElevationArtifacts.ps1`, run by the PreInstall phase | Registry commands, tasks and shortcuts that Atlas 0.5.x elevation helpers left, and the records Atlas Toolbox 0.1.x wrote outside the toggle store | Same as above |
| The `Toolbox\Scripts\` launchers: `toggleDefender.cmd`, `vbsCurrentConfig.cmd`, `viewBootValues.cmd`, `NVidia\{Disable,Enable}NVIDIADisplayContainerLS.cmd`, `SuperFetch\DisableSuperFetch.cmd`, `Troubleshooting\{Fix Errors 2502 and 2503,Repair Windows Components,Telemetry Components}.cmd` and `Troubleshooting\TroubleshootingNetwork\{AtlasDefault,WindowsDefault}.cmd` | Atlas Toolbox releases before 0.2.0, which run these by fixed path, and the NVIDIA pair also from the context menu those releases add. Toolbox 0.2.0 and later read `Toggles\catalog.json` and run toggles by name. | No supported Atlas install keeps a Toolbox release before 0.2.0 |
| `Scripts\Registry\SecurityHealthTray\*.reg`, byte-identical to `Toolbox\Scripts\SecurityHealthTray\*.reg` | The same Toolbox path contract | Same as above |
| `Scripts\Entry\Set-IndexConfiguration.cmd`, `Test-EdgeState.cmd`, `Test-Winget.cmd` and `Set-SettingsPageVisibilityLauncher.cmd` | Command-line entry points documented for support, used by the software picker and the CBS update helper | Their PowerShell targets get a documented entry of their own that cleans the environment |
| `Flags\*.flag` after an install completes | PCs installed before the state document existed. Every Atlas reader uses `%windir%\AtlasOS\state.json`, and falls back to the flags only when it's missing. | The oldest version `UpgradableFrom` lists wrote the state document |
| `HKLM\SOFTWARE\AtlasOS\Services` as the toggle store, mirrored into `state.json` | Atlas Toolbox releases before 0.2.0, which read the registry. Toolbox 0.2.0 and later read the `toggles` section of `state.json`. | No supported Atlas install keeps a Toolbox release before 0.2.0 |

Tests hold these contracts in place:

- `tests/Atlas.ToolboxLaunchers.Tests.ps1` pins each Toolbox launcher path, with the toggle and state it runs.
- `tests/Atlas.PayloadLayout.Tests.ps1` checks that each `SecurityHealthTray` pair stays identical.

## Rules for these files

- A file kept for compatibility isn't the implementation.
  It forwards to, or is generated from, the one implementation under `Scripts\` or `Toggles\`.
- Each Toolbox launcher is a stub that `tools/dev/New-ToggleLaunchers.ps1` generates from its toggle's `ToolboxLauncher` declaration.
  Declare one only for a path that a Toolbox release before 0.2.0 opens.
- Every entry names its consumer and its removal condition on this page.
  Adding a compatibility file without both blocks the review.
- When `UpgradableFrom` changes, revisit every row that mentions a version it no longer lists.

How Atlas replays the toggle records in that store, and why it replays every record, is described in [Toggle records](install-state.md#toggle-records).
