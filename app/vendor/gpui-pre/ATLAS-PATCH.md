# Atlas GPUI line-breaking patch

This directory vendors the published gpui-pre 0.3.3 crate from crates.io.
The original license files are retained. Atlas pins it through the
[patch.crates-io] entry in app/Cargo.toml.

Upstream's word-character list excludes Thai and Devanagari. Normal text
can wrap inside words and detach combining marks in the Windows renderer.
The change in src/text_system/line_layout.rs uses the ICU4X line segmenter
for text containing either script. complex_script_breaks.rs supplies
dictionary line breaks and grapheme boundaries; emergency wrapping respects
grapheme boundaries. Only the first glyph at a source byte index may create
a boundary: DirectWrite can emit several glyphs for the same text cluster.
Other text follows the existing upstream algorithm. This patches shaped-line
wrapping, not every separate editor or truncation algorithm in GPUI.

Cargo.toml adds icu_segmenter with compiled_data and without default
features. Cargo.lock resolves the dependency; no runtime data download is
needed. The helper is included in Atlas's test build so its Thai, Hindi and
unaffected-script regressions run with cargo test. Native 700x520 previews
exercise the actual DirectWrite glyph path.

Reference: https://docs.rs/icu_segmenter/latest/icu_segmenter/struct.LineSegmenter.html

When upgrading GPUI, check whether upstream now supports these scripts,
repeat the native wrapping checks, and remove this patch if it is redundant.
Keep the line-breaking changes limited to the files described above.

### No break after a no-break space

Upstream treats U+00A0, U+202F and U+2011 as word characters, which keeps
`:`, `;` and `!` attached after them. `?` is deliberately not a word
character, so URLs such as `foo?b=2` can wrap, and the non-word branch of
both wrappers offered a break before it whatever came first. French writes
a no-break space before `?`, so a question could end with `?` alone on the
next line. src/text_system/glue_breaks.rs holds the rule (UAX #14 LB12: no
break after glue), declared in src/text_system.rs; the non-word branches of
`LineLayout::compute_wrap_boundaries` (line_layout.rs) and
`LineWrapper::wrap_line` (line_wrapper.rs) consult it. Nothing else
changes: `?` after any other character is still a break opportunity.
The published crate's own tests don't build outside the Zed workspace, so
Atlas's test build includes glue_breaks.rs and runs its tests (as it does
for complex_script_breaks.rs), and app/src/i18n/line_breaks.rs wraps text
through both wrappers with GPUI's headless `NoopTextSystem`: if either
wrapper stops consulting the rule, `cargo test` fails. line_layout.rs keeps
its own `compute_wrap_boundaries` case for the day the crate's tests build.
On a GPUI upgrade, check whether upstream now follows LB12 and drop this if
so, then check a French question heading at 700x520 with real fonts.

## Atlas completion shader

`src/color.rs` adds the Windows-only `FlowingGradient` background tag (4),
constructor, transparency handling and debug formatting. `src/style.rs` handles
that tag in the existing background paint path. The Background memory layout
is unchanged. Pair with the vendored Windows renderer; see
`../gpui-pre-windows/ATLAS-PATCH.md` for its shader and maintenance checks.

## Linux resource compilation

`build.rs` writes an RC with an absolute manifest path into Cargo's output
directory so `llvm-rc` can resolve `resources/windows/gpui.manifest.xml` during
an MSVC cross-build.

## Accessibility states, live regions and language

`src/elements/div.rs` adds four fields to `AriaProperties` and their builders
on `StatefulInteractiveElement`: `aria_disabled` and `aria_read_only` (AccessKit's
`Disabled` and `ReadOnly` flags, so UIA `IsEnabled` is false for a disabled
control and `ValuePattern.IsReadOnly` true for a read-only text box),
`aria_live` and `aria_lang`. `write_a11y_info` writes the flags, the language,
and a live setting on every node: the one asked for, or `Live::Off`.
`src/elements/text.rs` writes `Live::Off` on text nodes too. AccessKit inherits
the live setting, so an explicit Off keeps a live region's buttons, links and
text from announcing themselves; the region announces itself when it appears
or its name changes. `Live` is re-exported from `src/gpui.rs`.

`Window::set_accessibility_language` (src/window.rs) stores a BCP 47 tag in
`A11y` (src/window/a11y.rs), and `begin_frame` sets it on the root Window node
each frame, so every node inherits it as its UIA Culture unless an element
sets its own with `aria_lang`. The window's first, empty tree has no language:
the app sets it on its first render.

`test_write_a11y_info_states_live_and_language` in div.rs covers the writer.
As with the crate's other tests it doesn't build outside the Zed workspace;
check a UIA tree (Atlas's `tools/Get-AccessibilityTree.ps1`) after an upgrade:
disabled buttons show `IsEnabled=False`, live nodes `LiveSetting=Polite` and
their descendants `Off`, and every node the app's language.

### No closing punctuation at the start of a row

Upstream already keeps `!`, `)`, `”`, `»` and similar marks with the word
before them by treating them as word characters in
`LineWrapper::is_word_char`, which both wrappers use. The patch adds the
German closing quote `“` (English only opens with it after a space, which
stays a break opportunity) and the CJK closing and stop punctuation, so
`。`, `、`, `）` or `」` never start a row (kinsoku; UAX #14 classes CL and
EX). `src/i18n/line_breaks.rs` in the app checks both wrappers.
