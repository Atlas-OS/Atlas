# Scripts\Registry — paired Toolbox copies

Some `.reg` payloads in this tree are duplicated into `..\..\Toolbox\` for the standalone
Atlas Toolbox flows. **Edit both copies together** — the pairs below must stay byte-identical,
and `tests/Atlas.PayloadLayout.Tests.ps1` ("Paired registry assets stay in lockstep") fails CI
if they diverge.

| Scripts\Registry copy | Toolbox copy |
| --- | --- |
| `SecurityHealthTray\disable.reg` | `Toolbox\Scripts\SecurityHealthTray\RemoveTray.reg` |
| `SecurityHealthTray\enable.reg` | `Toolbox\Scripts\SecurityHealthTray\AddTray.reg` |

Note: `Terminals\{disabled,enabled,minimal}.reg` share their content with
`Toolbox\ConfigurationServices\ContextMenuTerminals\ContextMenuTerminals_{0,1,2}.reg` but are
*not* byte-identical — each `Terminals` copy appends an `HKLM\SOFTWARE\AtlasOS` state-tracking
section that the Toolbox copies lack, so they are not covered by the lockstep test.
