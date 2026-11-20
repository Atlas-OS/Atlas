# Registry files

This folder holds the `.reg` files that some toggles import to apply a state.
It's for contributors who change those toggles.

Each subfolder belongs to one toggle and holds one file for each of its states.
The toggle's companion script picks the file for the state and imports it with `Import-AtlasRegFile`.

| Folder | Toggle | Files |
| --- | --- | --- |
| `SecurityHealthTray` | `SecurityHealthTray` | `enable.reg`, `disable.reg` |
| `TakeOwnership` | `TakeOwnership` | `add.reg`, `remove.reg` |
| `Terminals` | `ContextMenuTerminals` | `enabled.reg`, `disabled.reg`, `minimal.reg` |

## Toolbox copies

Some files here also have a copy under `AtlasModules/Toolbox` for the standalone Atlas Toolbox flows.
Edit both copies together, because each pair must stay byte-identical.
`tests/Atlas.PayloadLayout.Tests.ps1` fails when a pair differs.

| Registry copy | Toolbox copy |
| --- | --- |
| `SecurityHealthTray/disable.reg` | `Toolbox/Scripts/SecurityHealthTray/RemoveTray.reg` |
| `SecurityHealthTray/enable.reg` | `Toolbox/Scripts/SecurityHealthTray/AddTray.reg` |
