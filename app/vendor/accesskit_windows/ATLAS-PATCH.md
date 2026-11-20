# Atlas changes to accesskit_windows 0.34.0

This directory vendors the published `accesskit_windows` 0.34.0 crate from crates.io (upstream AccessKit commit `c88605b96d04431f9c3c792464a0f2f253480e94`, `platforms/windows`), with one change that reports heading levels.
Its MIT and Apache-2.0 licence texts are kept.
The `[patch.crates-io]` entry in `app/Cargo.toml` pins this copy.

## Heading levels

Upstream maps AccessKit's `level` only to UI Automation's `Level`, which is meant for tree items, and adds 1 to it.
Narrator's heading navigation (H and Shift+H in scan mode, the number keys and the headings list) reads `HeadingLevel` instead, so without this change every Atlas heading reports `HeadingLevel_None`.

`src/node.rs` makes two changes:

- A `heading_level` getter maps a `Role::Heading` node's level 1 to 9 to `HeadingLevel1` to `HeadingLevel9` (80051 to 80059), registered for `UIA_HeadingLevelPropertyId`.
- `level()` returns nothing for headings, so they don't also report an off-by-one `Level`.

Nothing else changes.

Upstream status: not yet proposed to AccessKit.

When you upgrade, check whether upstream maps `HeadingLevel` itself, and drop this vendored copy if it does.
Otherwise reapply the two changes in `node.rs`.
Then check with a UI Automation probe that the page title reports 80051, step headings 80052 and card headers 80053.
Finally, check in Narrator's scan mode that H, Shift+H and the headings list move between them.
