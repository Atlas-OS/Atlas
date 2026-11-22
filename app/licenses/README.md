# Atlas Manager licence notices

This folder holds the third-party notices that Atlas Manager carries, and the inventory they're generated from.
It's for contributors who change Cargo dependencies or prepare a release.

## What the app carries

`AtlasManager.exe` embeds three texts: the project's GNU General Public License, the Apache License 2.0 for the adapted GPUI input example (`GPUI-input-APACHE-2.0.txt`), and `THIRD-PARTY-NOTICES.txt`.

- Open them from **Settings** > **About** > **Licence**.
- Run `AtlasManager.exe --licenses` to open a text copy.
- Run `AtlasManager.exe --licenses <new-file>` to save a copy; the app won't overwrite an existing file.

ISO staging copies the notices into the ISO as well.

## Updating the notices

Run `../tools/Export-DependencyNotices.ps1` after changing Cargo dependencies, and commit what it writes.
With `-Check`, it compares freshly generated text and inventory with the committed files and fails on any notice it can't resolve.
The production build runs that check before it compiles.

The generator never downloads licence text.
When a crate lacks a notice, find the upstream text, pin its source URL and SHA-256 in `supplements.json`, and commit the file under `supplemental/`.
Keep the original author notices; an SPDX identifier or a generic licence template doesn't replace them.
The generator includes licence files from nested folders too.

## What the inventory covers

`dependency-inventory.json` lists every package in the locked Windows dependency graph, build and development packages included, so no package is left out because of how Cargo classifies its dependency.
`normalWindowsDependency` marks the normal dependencies, without procedural macros.
Before publishing a release, review the bundled code, each licence's conditions, any source the licences require you to provide, and changes to the dependency graph.

## Supplemental files

A supplemental file normally comes from the commit in the crate's `.cargo_vcs_info.json`.
Two crates take their licence from a later upstream commit that only adds the missing `LICENSE` file and changes no source code:

| Crate | Commit |
| --- | --- |
| seahash 4.1.0 | `3088c5c912b70b586d27bf553fbe964e025a2c89` |
| simd_helpers 0.1.0 | `82040194cd05affb060bf94d6f19f82a771d07fb` |

`supplements.json` records both exceptions.
The published sval_nested crate stores its licence files as flattened symlinks, so `supplemental/` holds the real texts from the crate's exact VCS commit.

## Hashes and line endings

The generated text and inventory belong in Git and in every distribution, and they contain no machine paths.
Supplemental hashes cover the downloaded bytes.
Inventory hashes of Cargo package texts normalise line endings to LF, so they match on every platform.
