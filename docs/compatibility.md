# Files kept for compatibility

Atlas keeps a small set of files only because something outside this repository, or an
older Atlas install, still addresses them by path. Each entry below names the consumer
that pins it and the condition under which removal can be considered. Check consumers,
packaging and migration coverage again before removing any of them.

| Path | Pinned by | Remove when |
| --- | --- | --- |
| `Scripts\RunAsTI.cmd` (deny-only stub) | Shortcuts and context-menu commands written by Atlas 0.5.x and earlier | `playbook.conf` `UpgradableFrom` no longer admits any 0.5.x version |
| `Scripts\Install\Compat\Remove-AtlasLegacyElevationArtifacts.ps1` (PreInstall phase) | Registry commands, tasks and shortcuts left by Atlas 0.5.x elevation helpers | Same as above |
| `AtlasModules\Toolbox\Scripts\` launchers: `toggleDefender.cmd`, `vbsCurrentConfig.cmd`, `viewBootValues.cmd`, `NVidia\{Disable,Enable}NVIDIADisplayContainerLS.cmd`, `SuperFetch\DisableSuperFetch.cmd`, `Troubleshooting\{Fix Errors 2502 and 2503,Repair Windows Components,Telemetry Components}.cmd` and `Troubleshooting\TroubleshootingNetwork\{AtlasDefault,WindowsDefault}.cmd` | Atlas Toolbox releases before 0.2.0, which run these by hard-coded path (the NVIDIA pair also from the context menu those releases add). Toolbox 0.2.0 and later read `Toggles\catalog.json` and run toggles by name; `tests\Atlas.ToolboxLaunchers.Tests.ps1` pins each path and the toggle and state it runs | No supported Atlas install keeps a Toolbox release before 0.2.0 |
| `Scripts\Registry\SecurityHealthTray\*.reg` byte-identical pairs with `Toolbox\Scripts\SecurityHealthTray\*.reg` | Same Toolbox path contract; `tests\Atlas.PayloadLayout.Tests.ps1` enforces the pairing | Same as above |
| `Scripts\Entry\Set-IndexConfiguration.cmd`, `Test-EdgeState.cmd`, `Test-Winget.cmd`, `Set-SettingsPageVisibilityLauncher.cmd` | Command-line entry points documented for support and used by the software picker and CBS update helper | Their PowerShell targets grow a documented, environment-sanitizing entry of their own |
| `AtlasModules\Flags\*.flag` after install completion | Machines installed before the state document existed; every Atlas reader uses `C:\Windows\AtlasOS\state.json` and falls back to the flags only when it is absent | The oldest version `UpgradableFrom` admits wrote the state document |
| `HKLM\SOFTWARE\AtlasOS\Services` as the toggle write store, mirrored into `state.json` | Atlas Toolbox releases before 0.2.0 read the registry tree; 0.2.0 and later read the `toggles` section of `state.json` | No supported Atlas install keeps a Toolbox release before 0.2.0 |

Rules for these files:

- Toggle records represent applied choices, with user work replayed at first sign-in.
  Default launcher labels do not seed the registry or state document. Existing records
  are always replayed: the store cannot tell a default seeded by an earlier build from a
  user's choice.
- A file kept for compatibility is never the implementation. It forwards to, or is
  generated from, the one implementation under `Scripts\` or `Toggles\`. Each Toolbox
  launcher is a stub that `tools\dev\New-ToggleLaunchers.ps1` generates from its toggle's
  `ToolboxLauncher` declaration. Declare one only for a path that a Toolbox release before
  0.2.0 opens.
- Each entry names its consumer and its removal condition here. Adding a compatibility
  file without both is a review blocker.
- When `UpgradableFrom` changes, revisit every row that references the dropped version.
