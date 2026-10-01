//! How a multi-line input's text wraps into visual rows, and where the caret,
//! the IME window and the scroll position go on them.

use std::ops::Range;

use gpui::{Bounds, Pixels, Point, SharedString, WrappedLine, point, px, size};

/// A multi-line input's text as shaped and wrapped: its lines, and the
/// visual rows they wrap into, top to bottom.
pub(super) struct Rows {
    /// What was shaped: the input's text, or its placeholder.
    pub(super) text: SharedString,
    pub(super) lines: Vec<WrappedLine>,
    pub(super) rows: Vec<Row>,
    pub(super) line_height: Pixels,
}

/// One visual row: bytes `start..end` of the text, part of line `line`,
/// which starts at byte `line_start`. The row begins `x` into the line's
/// unwrapped layout; `wraps` when the line continues on the next row.
#[derive(Clone, Copy, Debug, PartialEq)]
pub(super) struct Row {
    line: usize,
    line_start: usize,
    pub(super) start: usize,
    pub(super) end: usize,
    x: Pixels,
    pub(super) wraps: bool,
}

impl Rows {
    pub(super) fn new(
        text: SharedString,
        lines: impl IntoIterator<Item = WrappedLine>,
        line_height: Pixels,
    ) -> Self {
        let mut lines: Vec<WrappedLine> = lines.into_iter().collect();
        if lines.is_empty() {
            // Shaping yields a line even for no text; keep one if it did not.
            lines.push(WrappedLine::default());
        }
        let mut rows = Vec::new();
        let mut line_start = 0;
        for (index, line) in lines.iter().enumerate() {
            let (mut start, mut x) = (line_start, px(0.));
            for boundary in line.wrap_boundaries() {
                let glyph = &line.runs()[boundary.run_ix].glyphs[boundary.glyph_ix];
                let end = line_start + glyph.index;
                rows.push(Row { line: index, line_start, start, end, x, wraps: true });
                (start, x) = (end, glyph.position.x);
            }
            let end = line_start + line.len();
            rows.push(Row { line: index, line_start, start, end, x, wraps: false });
            line_start = end + 1;
        }
        Self { text, lines, rows, line_height }
    }

    pub(super) fn height(&self) -> Pixels {
        self.line_height * self.rows.len() as f32
    }

    /// Where the caret at `index` is drawn on `row`, from the text's top left.
    pub(super) fn position(&self, index: usize, row: usize) -> Point<Pixels> {
        let Row { line, line_start, x, .. } = self.rows[row];
        let layout = &self.lines[line].unwrapped_layout;
        point(layout.x_for_index(index.saturating_sub(line_start)) - x, self.line_height * row as f32)
    }

    pub(super) fn row_at(&self, y: Pixels) -> usize {
        ((y / self.line_height).max(0.) as usize).min(self.rows.len() - 1)
    }

    /// The caret offset on `row` closest to `x`.
    pub(super) fn index_at(&self, row: usize, x: Pixels) -> usize {
        let row = self.rows[row];
        let layout = &self.lines[row.line].unwrapped_layout;
        (row.line_start + layout.closest_index_for_x(x + row.x)).clamp(row.start, row_end(&row, &self.text))
    }

    /// Whether `index` is where `row` wraps, so a caret put there from the
    /// row stays at its end.
    pub(super) fn wraps_at(&self, row: usize, index: usize) -> bool {
        let row = self.rows[row];
        row.wraps && index == row.end
    }
}

/// The row a caret at `index` is drawn on. A caret where a line wraps starts
/// the next row, as in Windows edit controls, unless it was put at the end
/// of the row above (`at_row_end`).
pub(super) fn caret_row(rows: &[Row], index: usize, at_row_end: bool) -> usize {
    rows.iter()
        .position(|row| index < row.end || (index == row.end && (at_row_end || !row.wraps)))
        .unwrap_or(rows.len().saturating_sub(1))
}

/// The last caret offset on `row`. A row that wraps at a space ends before
/// it, so the caret is drawn on the row. A row that wraps elsewhere (CJK or
/// Thai text, a long word) ends after its last character, where the caret
/// stays on the row only when put there from it (see [`caret_row`]).
pub(super) fn row_end(row: &Row, text: &str) -> usize {
    match text[row.start..row.end].char_indices().next_back() {
        Some((index, c)) if row.wraps && c.is_whitespace() => row.start + index,
        _ => row.end,
    }
}

/// Where an IME puts its window for `range` of a multi-line input's
/// `content`, from the text's top left: the part of the range on its first
/// row. An empty input shows its placeholder, with the caret at the start.
pub(super) fn composition_bounds(
    content: &str,
    rows: &Rows,
    range: Range<usize>,
    at_row_end: bool,
) -> Option<Bounds<Pixels>> {
    if content.is_empty() {
        return Some(Bounds::new(Point::default(), size(px(2.), rows.line_height)));
    }
    if rows.text.as_ref() != content {
        return None;
    }
    let row = caret_row(&rows.rows, range.start, at_row_end);
    let start = rows.position(range.start, row);
    let end = rows.position(range.end.min(rows.rows[row].end), row);
    Some(Bounds::from_corners(start, point(end.x, start.y + rows.line_height)))
}

/// The vertical scroll that keeps a caret row (`caret` from the text's top)
/// in view, moving no further than it must, within the text's height.
pub(super) fn visible_row_offset(
    current: Pixels,
    caret: Pixels,
    line_height: Pixels,
    height: Pixels,
    content: Pixels,
) -> Pixels {
    current.max(caret + line_height - height).min(caret).min((content - height).max(px(0.))).max(px(0.))
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use super::{Row, Rows, caret_row, composition_bounds, row_end, visible_row_offset};
    use gpui::{Bounds, Hsla, NoopTextSystem, TextRun, TextSystem, WindowTextSystem, font, point, px, size};

    /// "one two three\n\nfour", its first line wrapped after "one " and "two ".
    fn rows() -> (String, Vec<Row>) {
        let row =
            |line, line_start, start, end, wraps| Row { line, line_start, start, end, x: px(0.), wraps };
        let rows = vec![
            row(0, 0, 0, 4, true),
            row(0, 0, 4, 8, true),
            row(0, 0, 8, 13, false),
            row(1, 14, 14, 14, false),
            row(2, 15, 15, 19, false),
        ];
        ("one two three\n\nfour".to_owned(), rows)
    }

    #[test]
    fn a_caret_at_a_wrap_starts_the_next_row_and_one_at_a_line_end_stays() {
        let (_, rows) = rows();
        let found = [0, 3, 4, 8, 13, 14, 15, 19, 40].map(|index| caret_row(&rows, index, false));
        assert_eq!(found, [0, 0, 1, 2, 2, 3, 4, 4, 4]);
        // Put at the end of a row that wraps, the caret stays there.
        assert_eq!(caret_row(&rows, 4, true), 0);
        assert_eq!(caret_row(&rows, 13, true), 2);
    }

    /// `text` shaped and wrapped `width` wide as a multi-line input lays it
    /// out, by GPUI's headless text system: 6px a character, 20px rows.
    fn shaped(text: &'static str, width: f32) -> Rows {
        let system = WindowTextSystem::new(Arc::new(TextSystem::new(Arc::new(NoopTextSystem::new()))));
        let run = TextRun {
            len: text.len(),
            font: font("Segoe UI"),
            color: Hsla::default(),
            background_color: None,
            underline: None,
            strikethrough: None,
        };
        let lines = system.shape_text(text.into(), px(10.), &[run], Some(px(width)), None).unwrap();
        Rows::new(text.into(), lines, px(20.))
    }

    #[test]
    fn a_row_that_wraps_without_a_space_ends_after_its_last_character() {
        // Five characters a row, with no spaces to wrap at.
        let rows = shaped("你好世界你好世界", 30.);
        assert_eq!(rows.rows[0].start..rows.rows[0].end, 0..15);
        assert_eq!(row_end(&rows.rows[0], &rows.text), 15, "End reaches the fifth character");
        assert_eq!(rows.index_at(0, px(1000.)), 15, "so does a click past the row");
        assert!(rows.wraps_at(0, 15));
        assert_eq!(caret_row(&rows.rows, 15, true), 0, "and the caret is drawn there");
        assert_eq!(rows.position(15, 0), point(px(30.), px(0.)));
        assert_eq!(caret_row(&rows.rows, 15, false), 1, "arriving from elsewhere starts the next row");
        assert_eq!(rows.index_at(1, px(1000.)), 24, "the last row ends with the text");
        assert!(!rows.wraps_at(1, 24));

        let rows = shaped("abcdefghijklmnopqrstuvwxyz", 30.);
        assert_eq!(rows.index_at(0, px(1000.)), rows.rows[0].end);
    }

    #[test]
    fn a_row_that_wraps_at_a_space_still_ends_before_it() {
        let rows = shaped("one two three\n\nfour", 30.);
        let ends: Vec<usize> = rows.rows.iter().map(|row| row_end(row, &rows.text)).collect();
        assert_eq!(ends, [3, 7, 13, 14, 19]);
        assert_eq!(rows.index_at(0, px(1000.)), 3);
        assert!(!rows.wraps_at(0, 3));
        assert_eq!(caret_row(&rows.rows, ends[0], false), 0, "the caret stays on the row");
    }

    #[test]
    fn an_empty_multi_line_input_puts_the_ime_at_the_start_of_its_text() {
        // The placeholder is what was shaped; the caret is before it.
        let placeholder = shaped("I was trying to…", 300.);
        let caret = Bounds::new(point(px(0.), px(0.)), size(px(2.), px(20.)));
        assert_eq!(composition_bounds("", &placeholder, 0..0, false), Some(caret));
        // A layout made for other text is not used.
        assert_eq!(composition_bounds("x", &placeholder, 0..0, false), None);
        // Otherwise the composition's first row: "two" on the second.
        let rows = shaped("one two three", 30.);
        let second = Bounds::new(point(px(0.), px(20.)), size(px(18.), px(20.)));
        assert_eq!(composition_bounds("one two three", &rows, 4..7, false), Some(second));
    }

    #[test]
    fn a_tall_input_scrolls_only_as_far_as_the_caret_needs() {
        // 22px rows, five (110px) visible, 440px of text.
        let at = |current: f32, caret: f32| {
            visible_row_offset(px(current), px(caret), px(22.), px(110.), px(440.))
        };
        assert_eq!(at(0., 44.), px(0.));
        assert_eq!(at(0., 110.), px(22.));
        assert_eq!(at(200., 44.), px(44.));
        assert_eq!(at(400., 418.), px(330.));
        // Text shorter than the input never scrolls.
        assert_eq!(visible_row_offset(px(66.), px(0.), px(22.), px(110.), px(88.)), px(0.));
    }
}
