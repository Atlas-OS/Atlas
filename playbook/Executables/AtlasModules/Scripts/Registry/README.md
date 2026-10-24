# Scripts\Registry — paired Toolbox copies

Some `.reg` files in this tree are duplicated into `..\..\Toolbox\` for the standalone
Atlas Toolbox flows. **Edit both copies together** — the pairs below must stay byte-identical,
and `tests/Atlas.PayloadLayout.Tests.ps1` ("Paired registry assets stay in lockstep") fails CI
if they diverge.

| Scripts\Registry copy | Toolbox copy |
| --- | --- |
| `SecurityHealthTray\disable.reg` | `Toolbox\Scripts\SecurityHealthTray\RemoveTray.reg` |
| `SecurityHealthTray\enable.reg` | `Toolbox\Scripts\SecurityHealthTray\AddTray.reg` |
