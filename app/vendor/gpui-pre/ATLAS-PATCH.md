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

## Atlas completion shader

`src/color.rs` adds the Windows-only `FlowingGradient` background tag (4),
constructor, transparency handling and debug formatting. `src/style.rs` handles
that tag in the existing background paint path. The Background memory layout
is unchanged. Pair with the vendored Windows renderer; see
`../gpui-pre-windows/ATLAS-PATCH.md` for its shader and maintenance checks.
