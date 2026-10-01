# Atlas heading-level patch

This directory vendors the published `accesskit_windows` 0.34.0 crate from
crates.io (upstream AccessKit commit `c88605b96d04431f9c3c792464a0f2f253480e94`,
`platforms/windows`). Its MIT and Apache-2.0 licence texts are retained.
`app/Cargo.toml` pins it through `[patch.crates-io]`.

Upstream maps AccessKit's `level` only to UIA `Level`, which is meant for tree
items, and adds 1 to it. Narrator's heading navigation (H and Shift+H in scan
mode, the number keys and the headings list) reads UIA `HeadingLevel`, so every
Atlas heading reported `HeadingLevel_None`. `src/node.rs` adds a
`heading_level` getter that maps a `Role::Heading` node's level 1 to 9 to
`HeadingLevel1` to `HeadingLevel9` (80051 to 80059), registers it for
`UIA_HeadingLevelPropertyId`, and makes `level()` return nothing for headings,
so they no longer also report an off-by-one `Level`. Nothing else changes.

Offer the same change to AccessKit. When upgrading, check whether upstream
maps `HeadingLevel` now and drop this vendor copy if so; otherwise reapply the
two changes in `node.rs`. Check with a UIA probe that the page title reports
80051, step headings 80052 and card headers 80053, then with Narrator scan
mode that H, Shift+H and the headings list move between them.
