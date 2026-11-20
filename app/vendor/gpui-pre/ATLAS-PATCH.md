# Atlas changes to gpui-pre 0.3.3

This directory vendors the published `gpui-pre` 0.3.3 crate from crates.io, with the changes below.
CI saves this file with each Atlas Manager build as the notice of those changes, and maintainers use it as the checklist when they upgrade GPUI.
The original licence files are kept, and the `[patch.crates-io]` entry in `app/Cargo.toml` pins this copy.

| Change | Files | Check after a GPUI upgrade |
| --- | --- | --- |
| [Thai and Devanagari line breaking](#thai-and-devanagari-line-breaking) | `Cargo.toml`, `src/text_system/line_layout.rs`, `src/text_system/complex_script_breaks.rs` | Whether upstream breaks these scripts itself; Thai and Hindi wrapping at 700 × 520 with real fonts. |
| [No break after a no-break space](#no-break-after-a-no-break-space) | `src/text_system.rs`, `src/text_system/glue_breaks.rs`, `src/text_system/line_layout.rs`, `src/text_system/line_wrapper.rs` | Whether upstream follows UAX #14 LB12; a French question heading at 700 × 520. |
| [No closing punctuation at the start of a row](#no-closing-punctuation-at-the-start-of-a-row) | `src/text_system/line_wrapper.rs` | `cargo test` in `app/`. |
| [Completion page background](#completion-page-background) | `src/color.rs`, `src/style.rs` | The tag and layout still agree with the Windows renderer's shader. |
| [Linux resource compilation](#linux-resource-compilation) | `build.rs` | A Linux cross-build of Atlas Manager. |
| [Accessibility states, live regions and language](#accessibility-states-live-regions-and-language) | `src/elements/div.rs`, `src/elements/text.rs`, `src/gpui.rs`, `src/window.rs`, `src/window/a11y.rs` | The UI Automation tree of the running app. |

## Thai and Devanagari line breaking

Upstream's word-character list leaves out Thai and Devanagari.
In the Windows renderer, ordinary text in those scripts can then wrap inside words and detach combining marks.

- `src/text_system/line_layout.rs` uses the ICU4X line segmenter for text that contains either script.
  Other text follows the upstream algorithm.
- `src/text_system/complex_script_breaks.rs` supplies dictionary line breaks and grapheme boundaries, and emergency wrapping respects grapheme boundaries.
- Only the first glyph at a source byte index can create a boundary, because DirectWrite can emit several glyphs for one text cluster.
- `Cargo.toml` adds `icu_segmenter` with `compiled_data` and without default features.
  `Cargo.lock` resolves it, and nothing is downloaded at run time.

The change covers shaped-line wrapping, not GPUI's separate editor and truncation algorithms.
Atlas Manager's test build compiles `complex_script_breaks.rs`, so its Thai, Hindi and unaffected-script cases run with `cargo test`.
Native previews at 700 × 520 exercise the DirectWrite glyph path itself.
The [ICU4X `LineSegmenter` documentation](https://docs.rs/icu_segmenter/latest/icu_segmenter/struct.LineSegmenter.html) describes the segmenter.

After a GPUI upgrade, check whether upstream supports these scripts, and remove this change if it does.
Otherwise repeat the native wrapping checks, and keep the change within the files listed.

## No break after a no-break space

Upstream treats U+00A0, U+202F and U+2011 as word characters, which keeps `:`, `;` and `!` attached after them.
`?` isn't a word character, so that URLs such as `foo?b=2` can wrap, and the non-word branch of both wrappers offers a break before it whatever precedes it.
French writes a no-break space before `?`, so upstream can leave a question's `?` alone on the next line.

- `src/text_system/glue_breaks.rs` holds the rule (UAX #14 LB12: no break after glue), and `src/text_system.rs` declares it.
- The non-word branches of `LineLayout::compute_wrap_boundaries` (`line_layout.rs`) and `LineWrapper::wrap_line` (`line_wrapper.rs`) consult it.
- `?` after any other character stays a break opportunity.

The published crate's tests don't build outside the Zed workspace.
Instead, `app/src/i18n/line_breaks.rs` wraps text through both wrappers with GPUI's headless `NoopTextSystem`, so `cargo test` fails if either wrapper stops consulting the rule.
`line_layout.rs` also has its own `compute_wrap_boundaries` case for when the crate's tests build.

After a GPUI upgrade, check whether upstream follows LB12, and drop this change if it does.
Then check a French question heading at 700 × 520 with real fonts.

## No closing punctuation at the start of a row

Upstream keeps `!`, `)`, `”`, `»` and similar marks with the word before them by treating them as word characters in `LineWrapper::is_word_char`, which both wrappers use.
This change adds two groups to that list:

- the German closing quote `“`, which English uses only as an opening quote after a space, and that space stays a break opportunity;
- CJK closing and stop punctuation, so `。`, `、`, `）` and `」` never start a row (kinsoku; UAX #14 classes CL and EX).

`app/src/i18n/line_breaks.rs` checks both wrappers.

## Completion page background

`src/color.rs` adds the Windows-only `FlowingGradient` background tag (4), with its constructor, transparency handling and debug formatting.
`src/style.rs` handles that tag in the existing background paint path.
The `Background` memory layout is unchanged.

The vendored Windows renderer draws the tag.
The [`gpui-pre-windows` changes](../gpui-pre-windows/ATLAS-PATCH.md) describe its shader and the checks it needs.

## Linux resource compilation

`build.rs` writes a resource script with an absolute manifest path into Cargo's output directory.
`llvm-rc` can then find `resources/windows/gpui.manifest.xml` during an MSVC cross-build.

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
