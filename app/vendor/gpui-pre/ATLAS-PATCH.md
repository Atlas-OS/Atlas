# Atlas changes to gpui-pre 0.3.13

This directory vendors the published `gpui-pre` 0.3.13 crate from crates.io, with the changes below.
CI saves this file with each Atlas Manager build as the notice of those changes, and maintainers use it as the checklist when they upgrade GPUI.
The original licence files are kept, and the `[patch.crates-io]` entry in `app/Cargo.toml` pins this copy.

| Change | Files | Check after a GPUI upgrade |
| --- | --- | --- |
| [Thai and Devanagari line breaking](#thai-and-devanagari-line-breaking) | `Cargo.toml`, `src/text_system/line_layout.rs`, `src/text_system/complex_script_breaks.rs` | Whether upstream breaks these scripts itself; Thai and Hindi wrapping at 700 × 520 with real fonts. |
| [Completion page background](#completion-page-background) | `src/color.rs`, `src/style.rs` | The tag and layout still agree with the Windows renderer's shader. |
| [Accessibility states, live regions and language](#accessibility-states-live-regions-and-language) | `src/elements/div.rs`, `src/elements/text.rs`, `src/gpui.rs`, `src/window.rs`, `src/window/a11y.rs` | The UI Automation tree of the running app. |

## Thai and Devanagari line breaking

Upstream uses ICU4X with non-complex-script data. Atlas adds dictionary segmentation for Thai and grapheme-safe wrapping for Thai and Devanagari.

- `src/text_system/line_layout.rs` uses the ICU4X line segmenter for text that contains either script.
  Other text follows the upstream algorithm.
- `src/text_system/complex_script_breaks.rs` supplies dictionary line breaks and grapheme boundaries, and emergency wrapping respects grapheme boundaries.
- Only the first glyph at a source byte index can create a boundary, because DirectWrite can emit several glyphs for one text cluster.
- The segmenter uses the compiled ICU data from the upstream dependency.

GPUI's upstream line breaker handles no-break spaces and closing punctuation. Atlas exercises both text wrappers in `app/src/i18n/line_breaks.rs`.
Atlas Manager's test build compiles `complex_script_breaks.rs`, so its Thai, Hindi and unaffected-script cases run with `cargo test`.
Native previews at 700 × 520 exercise the DirectWrite glyph path itself.
The [ICU4X `LineSegmenter` documentation](https://docs.rs/icu_segmenter/latest/icu_segmenter/struct.LineSegmenter.html) describes the segmenter.

After a GPUI upgrade, check whether upstream supports these scripts, and remove this change if it does.
Otherwise repeat the native wrapping checks, and keep the change within the files listed.

## Completion page background

`src/color.rs` adds the Windows-only `FlowingGradient` background tag (4), with its constructor, transparency handling and debug formatting.
`src/style.rs` handles that tag in the existing background paint path.
The `Background` memory layout is unchanged.

The vendored Windows renderer draws the tag.
The [`gpui-pre-windows` changes](../gpui-pre-windows/ATLAS-PATCH.md) describe its shader and the checks it needs.

## Accessibility states, live regions and language

`src/elements/div.rs` adds four fields to `AriaProperties`, with builders on `StatefulInteractiveElement`.

| Field | Effect |
| --- | --- |
| `aria_disabled` | Sets AccessKit's `Disabled` flag, so UI Automation's `IsEnabled` is false for a disabled control. |
| `aria_read_only` | Sets AccessKit's `ReadOnly` flag, so `ValuePattern.IsReadOnly` is true for a read-only text box. |
| `aria_live` | Sets the node's live setting. |
| `aria_lang` | Sets the node's language. |

`write_a11y_info` writes the flags, the language and a live setting on every node: the one asked for, or `Live::Off`.
`src/elements/text.rs` writes `Live::Off` on text nodes too.
AccessKit inherits the live setting, so an explicit `Off` stops a live region's buttons, links and text announcing themselves.
The region announces itself when it appears or its name changes.
`src/gpui.rs` re-exports `Live`.

`Window::set_accessibility_language` (`src/window.rs`) stores a BCP 47 tag in `A11y` (`src/window/a11y.rs`).
`begin_frame` sets it on the root window node each frame, so every node inherits it as its UI Automation culture unless an element sets its own with `aria_lang`.
The window's first, empty tree has no language; Atlas Manager sets it on its first render.

`test_write_a11y_info_states_live_and_language` in `div.rs` covers the writer, but like the crate's other tests it doesn't build outside the Zed workspace.
After a GPUI upgrade, read the UI Automation tree with `app/tools/Get-AccessibilityTree.ps1` and check that:

- disabled buttons show `IsEnabled=False`;
- live nodes show `LiveSetting=Polite`, and their descendants `Off`;
- every node reports the app's language.
