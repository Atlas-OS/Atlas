//! Text that arrives from an IME or the clipboard: UTF-16 offsets, IME
//! composition and pasted line breaks.

// Adapted from Zed's GPUI examples/input.rs. Copyright Zed Industries, Apache-2.0.

use std::ops::Range;

use gpui::{Bounds, Context, EntityInputHandler, Pixels, UTF16Selection, Window, point, px};

use super::TextInput;
use super::layout::composition_bounds;

/// The clipboard as one line: each line break (CRLF from Windows counts
/// once) and tab becomes a space, and surrounding whitespace goes.
pub(super) fn single_line(text: &str) -> String {
    text.replace("\r\n", " ").replace(['\r', '\n', '\t'], " ").trim().to_owned()
}

/// The clipboard for a multi-line input: every line break becomes `\n`
/// (CRLF from Windows counts once) and each tab a space.
pub(super) fn multi_line(text: &str) -> String {
    text.replace("\r\n", "\n").replace('\r', "\n").replace('\t', " ")
}

/// The byte offset in `text` for a UTF-16 offset, clamped to the text.
fn offset_from_utf16(text: &str, offset: usize) -> usize {
    let mut utf8_offset = 0;
    let mut utf16_count = 0;

    for ch in text.chars() {
        if utf16_count >= offset {
            break;
        }
        utf16_count += ch.len_utf16();
        utf8_offset += ch.len_utf8();
    }

    utf8_offset
}

/// The UTF-16 offset in `text` for a byte offset, clamped to the text.
fn offset_to_utf16(text: &str, offset: usize) -> usize {
    let mut utf16_offset = 0;
    let mut utf8_count = 0;

    for ch in text.chars() {
        if utf8_count >= offset {
            break;
        }
        utf8_count += ch.len_utf8();
        utf16_offset += ch.len_utf16();
    }

    utf16_offset
}

/// `new_text` replacing `range` of `content`. Returns the new content, the
/// range an IME composition marks and the selection, all in bytes. The caret
/// (`caret_utf16`, in UTF-16 units relative to `new_text`, as the Windows IME
/// reports it) lands inside the new text; without one it goes after it.
fn compose(
    content: &str,
    range: Range<usize>,
    new_text: &str,
    caret_utf16: Option<Range<usize>>,
) -> (String, Option<Range<usize>>, Range<usize>) {
    let composed = content[..range.start].to_owned() + new_text + &content[range.end..];
    let marked = (!new_text.is_empty()).then(|| range.start..range.start + new_text.len());
    let selected = match caret_utf16 {
        Some(caret) => {
            range.start + offset_from_utf16(new_text, caret.start)
                ..range.start + offset_from_utf16(new_text, caret.end)
        }
        None => range.start + new_text.len()..range.start + new_text.len(),
    };
    (composed, marked, selected)
}

impl TextInput {
    fn offset_from_utf16(&self, offset: usize) -> usize {
        offset_from_utf16(&self.content, offset)
    }

    fn offset_to_utf16(&self, offset: usize) -> usize {
        offset_to_utf16(&self.content, offset)
    }

    fn range_to_utf16(&self, range: &Range<usize>) -> Range<usize> {
        self.offset_to_utf16(range.start)..self.offset_to_utf16(range.end)
    }

    fn range_from_utf16(&self, range_utf16: &Range<usize>) -> Range<usize> {
        self.offset_from_utf16(range_utf16.start)..self.offset_from_utf16(range_utf16.end)
    }

    /// The bytes an edit replaces: the range the IME names, else the
    /// composition, else the selection.
    fn edit_range(&self, range_utf16: Option<&Range<usize>>) -> Range<usize> {
        range_utf16
            .map(|range| self.range_from_utf16(range))
            .or_else(|| self.marked_range.clone())
            .unwrap_or_else(|| self.selected_range.clone())
    }
}

impl EntityInputHandler for TextInput {
    fn text_for_range(
        &mut self,
        range_utf16: Range<usize>,
        actual_range: &mut Option<Range<usize>>,
        _window: &mut Window,
        _cx: &mut Context<Self>,
    ) -> Option<String> {
        let range = self.range_from_utf16(&range_utf16);
        actual_range.replace(self.range_to_utf16(&range));
        Some(self.content[range].to_string())
    }

    fn selected_text_range(
        &mut self,
        _ignore_disabled_input: bool,
        _window: &mut Window,
        _cx: &mut Context<Self>,
    ) -> Option<UTF16Selection> {
        Some(UTF16Selection {
            range: self.range_to_utf16(&self.selected_range),
            reversed: self.selection_reversed,
        })
    }

    fn marked_text_range(&self, _window: &mut Window, _cx: &mut Context<Self>) -> Option<Range<usize>> {
        self.marked_range.as_ref().map(|range| self.range_to_utf16(range))
    }

    fn unmark_text(&mut self, _window: &mut Window, _cx: &mut Context<Self>) {
        self.marked_range = None;
    }

    fn replace_text_in_range(
        &mut self,
        range_utf16: Option<Range<usize>>,
        new_text: &str,
        _: &mut Window,
        cx: &mut Context<Self>,
    ) {
        if self.read_only {
            return;
        }
        let range = self.edit_range(range_utf16.as_ref());
        let (content, _, selected) = compose(&self.content, range, new_text, None);
        self.content = content.into();
        self.selected_range = selected;
        self.marked_range = None;
        self.at_row_end = false;
        cx.notify();
    }

    fn replace_and_mark_text_in_range(
        &mut self,
        range_utf16: Option<Range<usize>>,
        new_text: &str,
        new_selected_range_utf16: Option<Range<usize>>,
        _window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        if self.read_only {
            return;
        }
        let range = self.edit_range(range_utf16.as_ref());
        let (content, marked, selected) = compose(&self.content, range, new_text, new_selected_range_utf16);
        self.content = content.into();
        self.marked_range = marked;
        self.selected_range = selected;
        self.at_row_end = false;
        cx.notify();
    }

    fn bounds_for_range(
        &mut self,
        range_utf16: Range<usize>,
        bounds: Bounds<Pixels>,
        _window: &mut Window,
        _cx: &mut Context<Self>,
    ) -> Option<Bounds<Pixels>> {
        let range = self.range_from_utf16(&range_utf16);
        if self.multiline {
            let at_row_end = self.at_row_end && range.start == self.cursor_offset();
            let local = composition_bounds(&self.content, self.last_rows.as_ref()?, range, at_row_end)?;
            let origin = bounds.origin + local.origin - point(px(0.), self.vertical_offset);
            return Some(Bounds::new(origin, local.size));
        }
        let last_layout = self.last_layout.as_ref()?;
        Some(Bounds::from_corners(
            point(
                bounds.left() + last_layout.x_for_index(range.start) - self.horizontal_offset,
                bounds.top(),
            ),
            point(
                bounds.left() + last_layout.x_for_index(range.end) - self.horizontal_offset,
                bounds.bottom(),
            ),
        ))
    }

    fn character_index_for_point(
        &mut self,
        point: gpui::Point<Pixels>,
        _window: &mut Window,
        _cx: &mut Context<Self>,
    ) -> Option<usize> {
        let line_point = self.last_bounds?.localize(&point)?;
        if self.multiline {
            let rows = self.rows()?;
            let index = rows.index_at(rows.row_at(line_point.y + self.vertical_offset), line_point.x);
            return Some(self.offset_to_utf16(index));
        }
        // A layout made for other text, such as an empty input's placeholder, can't place a character.
        let last_layout = self.last_layout.as_ref().filter(|layout| layout.text == self.content)?;
        let utf8_index = last_layout.index_for_x(line_point.x + self.horizontal_offset)?;
        Some(self.offset_to_utf16(utf8_index))
    }
}

#[cfg(test)]
mod tests {
    use super::{compose, multi_line, offset_from_utf16, offset_to_utf16, single_line};

    #[test]
    fn composing_after_ascii_marks_the_new_text_and_places_the_caret_inside_it() {
        // "ab" with the caret at the end; the IME composes two 3-byte
        // characters and reports the caret after both (2 UTF-16 units).
        let (content, marked, selected) = compose("ab", 2..2, "日本", Some(2..2));
        assert_eq!(content, "ab日本");
        assert_eq!(marked, Some(2..8));
        assert_eq!(selected, 8..8);

        // Caret between the two composed characters: a UTF-16 unit into the
        // new text, not into the whole content.
        let (_, _, selected) = compose("ab", 2..2, "日本", Some(1..1));
        assert_eq!(selected, 5..5);
    }

    #[test]
    fn a_composition_that_replaces_text_offsets_both_caret_ends_by_the_range_start() {
        // Replace "b" (bytes 1..2) with the composition and select all of it.
        let (content, marked, selected) = compose("ab", 1..2, "日本", Some(0..2));
        assert_eq!(content, "a日本");
        assert_eq!(marked, Some(1..7));
        assert_eq!(selected, 1..7);
    }

    #[test]
    fn an_empty_composition_clears_the_mark() {
        let (content, marked, selected) = compose("ab日本", 2..8, "", None);
        assert_eq!(content, "ab");
        assert_eq!(marked, None);
        assert_eq!(selected, 2..2);
    }

    #[test]
    fn utf16_offsets_round_trip_and_clamp() {
        assert_eq!(offset_from_utf16("a😀b", 3), 5);
        assert_eq!(offset_to_utf16("a😀b", 5), 3);
        assert_eq!(offset_from_utf16("ab", 10), 2);
        assert_eq!(offset_to_utf16("ab", 10), 2);
    }

    #[test]
    fn pasted_text_becomes_one_trimmed_line() {
        assert_eq!(single_line("  user\r\nname\t\r\n"), "user name");
        assert_eq!(single_line("plain"), "plain");
    }

    #[test]
    fn text_pasted_into_a_multi_line_input_keeps_its_lines() {
        assert_eq!(multi_line("a\r\nb\rc\td\n"), "a\nb\nc d\n");
        assert_eq!(multi_line("  indented\r\n"), "  indented\n");
    }
}
