//! The element that shapes, scrolls and paints a text box's text, caret and
//! selection, and registers it for IME input.

// Adapted from Zed's GPUI examples/input.rs. Copyright Zed Industries, Apache-2.0.

use std::ops::Range;

use crate::theme::ActiveTheme;
use gpui::{
    App, AvailableSpace, Bounds, ContentMask, ElementId, ElementInputHandler, Entity, GlobalElementId, Hsla,
    LayoutId, PaintQuad, Pixels, ShapedLine, SharedString, Style, TextAlign, TextRun, UnderlineStyle, Window,
    fill, point, prelude::*, px, relative, size,
};

use super::TextInput;
use super::layout::{Rows, caret_row, visible_row_offset};

/// A multi-line input shows at least this many rows, grows with its text up
/// to the maximum, and then scrolls.
const MIN_ROWS: usize = 5;
const MAX_ROWS: usize = 10;

pub(super) struct TextElement {
    pub(super) input: Entity<TextInput>,
}

pub(super) struct PrepaintState {
    line: Option<ShapedLine>,
    rows: Option<Rows>,
    cursor: Option<PaintQuad>,
    selections: Vec<PaintQuad>,
    offset: Pixels,
    vertical_offset: Pixels,
    /// The caret offset and text length this layout shows.
    shown: (usize, usize),
}

fn visible_caret_offset(current: Pixels, cursor: Pixels, width: Pixels, line_width: Pixels) -> Pixels {
    let available = (width - px(4.)).max(px(0.));
    current.max(cursor - available).min(cursor).max(px(0.)).min((line_width - available).max(px(0.)))
}

/// The text to draw (the placeholder when there is none) and its runs, with
/// an IME composition underlined and, in a contrast theme, the selection in
/// the highlight text colour.
fn display_runs(input: &TextInput, window: &Window, cx: &App) -> (SharedString, Vec<TextRun>) {
    let style = window.text_style();
    let (display_text, text_color) = if input.content.is_empty() {
        ((input.placeholder)().into(), cx.theme().text_secondary)
    } else {
        (input.content.clone(), style.color)
    };

    let run = TextRun {
        len: display_text.len(),
        font: style.font(),
        color: text_color,
        background_color: None,
        underline: None,
        strikethrough: None,
    };
    if input.content.is_empty() {
        return (display_text, vec![run]);
    }
    let selected = cx.theme().selection_text().map(|colour| (input.selected_range.clone(), colour));
    (display_text, split_runs(run, input.marked_range.clone(), selected))
}

/// `run` split where the IME composition (`marked`, underlined) and the
/// selection (drawn in the colour given with it) start and end.
fn split_runs(
    run: TextRun,
    marked: Option<Range<usize>>,
    selected: Option<(Range<usize>, Hsla)>,
) -> Vec<TextRun> {
    let len = run.len;
    let selected = selected.filter(|(range, _)| !range.is_empty());
    let mut edges = vec![0, len];
    edges.extend(marked.iter().flat_map(|range| [range.start, range.end]));
    edges.extend(selected.iter().flat_map(|(range, _)| [range.start, range.end]));
    edges.retain(|&edge| edge <= len);
    edges.sort_unstable();
    edges.dedup();
    let runs: Vec<TextRun> = edges
        .windows(2)
        .map(|pair| {
            let within = |range: &Range<usize>| range.start <= pair[0] && pair[1] <= range.end;
            let color = match &selected {
                Some((range, colour)) if within(range) => *colour,
                _ => run.color,
            };
            let underline = marked.as_ref().filter(|range| within(range)).map(|_| UnderlineStyle {
                color: Some(color),
                thickness: px(1.0),
                wavy: false,
            });
            TextRun { len: pair[1] - pair[0], color, underline, ..run.clone() }
        })
        .collect();
    if runs.is_empty() { vec![run] } else { runs }
}

impl IntoElement for TextElement {
    type Element = Self;

    fn into_element(self) -> Self::Element {
        self
    }
}

impl Element for TextElement {
    type RequestLayoutState = ();
    type PrepaintState = PrepaintState;

    fn id(&self) -> Option<ElementId> {
        None
    }

    fn source_location(&self) -> Option<&'static core::panic::Location<'static>> {
        None
    }

    fn request_layout(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&gpui::InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (LayoutId, Self::RequestLayoutState) {
        let mut style = Style::default();
        style.size.width = relative(1.).into();
        let input = self.input.read(cx);
        if !input.multiline {
            style.size.height = window.line_height().into();
            return (window.request_layout(style, [], cx), ());
        }
        // As tall as the wrapped text, within the row limits.
        let (text, runs) = display_runs(input, window, cx);
        let font_size = window.text_style().font_size.to_pixels(window.rem_size());
        let line_height = window.line_height();
        let layout = window.request_measured_layout(style, move |known, available, window, _| {
            let width = known.width.or(match available.width {
                AvailableSpace::Definite(width) => Some(width),
                _ => None,
            });
            let rows: usize = window
                .text_system()
                .shape_text(text.clone(), font_size, &runs, width, None)
                .map(|lines| lines.iter().map(|line| line.wrap_boundaries().len() + 1).sum())
                .unwrap_or(1);
            size(width.unwrap_or_default(), line_height * rows.clamp(MIN_ROWS, MAX_ROWS) as f32)
        });
        (layout, ())
    }

    fn prepaint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&gpui::InspectorElementId>,
        bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        window: &mut Window,
        cx: &mut App,
    ) -> Self::PrepaintState {
        let input = self.input.read(cx);
        let selected_range = input.selected_range.clone();
        let cursor = input.cursor_offset();
        let shown = (cursor, input.content.len());
        let (display_text, runs) = display_runs(input, window, cx);
        let font_size = window.text_style().font_size.to_pixels(window.rem_size());

        if input.multiline {
            let line_height = window.line_height();
            let lines = window
                .text_system()
                .shape_text(display_text.clone(), font_size, &runs, Some(bounds.size.width), None)
                .unwrap_or_default();
            let rows = Rows::new(display_text, lines, line_height);
            let caret_row = caret_row(&rows.rows, cursor, input.at_row_end);
            let caret = rows.position(cursor, caret_row);
            // Follow the caret when it moves or the text changes; otherwise
            // keep where the wheel left the text.
            let offset = if input.revealed == Some(shown) {
                input.vertical_offset.min((rows.height() - bounds.size.height).max(px(0.)))
            } else {
                visible_row_offset(
                    input.vertical_offset,
                    caret.y,
                    line_height,
                    bounds.size.height,
                    rows.height(),
                )
            };
            let origin = bounds.origin - point(px(0.), offset);
            let cursor = selected_range
                .is_empty()
                .then(|| fill(Bounds::new(origin + caret, size(px(2.), line_height)), cx.theme().accent));
            let mut selections = Vec::new();
            if !selected_range.is_empty() {
                for (index, row) in rows.rows.iter().enumerate() {
                    let start = selected_range.start.max(row.start);
                    let end = selected_range.end.min(row.end);
                    // A selected line break shows as a sliver past the row.
                    let newline =
                        !row.wraps && selected_range.end > row.end && selected_range.start <= row.end;
                    if start > end || (start == end && !newline) {
                        continue;
                    }
                    let left = origin + rows.position(start, index);
                    let right = rows.position(end, index).x + if newline { px(4.) } else { px(0.) };
                    selections.push(fill(
                        Bounds::from_corners(left, point(origin.x + right, left.y + line_height)),
                        cx.theme().selection_fill(),
                    ));
                }
            }
            return PrepaintState {
                line: None,
                rows: Some(rows),
                cursor,
                selections,
                offset: px(0.),
                vertical_offset: offset,
                shown,
            };
        }

        let line = window.text_system().shape_line(display_text, font_size, &runs, None);

        let raw_cursor = line.x_for_index(cursor);
        let offset =
            visible_caret_offset(input.horizontal_offset, raw_cursor, bounds.size.width, line.width());
        let cursor_pos = raw_cursor - offset;
        let (selection, cursor) = if selected_range.is_empty() {
            (
                None,
                Some(fill(
                    Bounds::new(
                        point(bounds.left() + cursor_pos, bounds.top()),
                        size(px(2.), bounds.bottom() - bounds.top()),
                    ),
                    cx.theme().accent,
                )),
            )
        } else {
            (
                Some(fill(
                    Bounds::from_corners(
                        point(bounds.left() + line.x_for_index(selected_range.start) - offset, bounds.top()),
                        point(bounds.left() + line.x_for_index(selected_range.end) - offset, bounds.bottom()),
                    ),
                    cx.theme().selection_fill(),
                )),
                None,
            )
        };
        PrepaintState {
            line: Some(line),
            rows: None,
            cursor,
            selections: selection.into_iter().collect(),
            offset,
            vertical_offset: px(0.),
            shown,
        }
    }

    fn paint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&gpui::InspectorElementId>,
        bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        prepaint: &mut Self::PrepaintState,
        window: &mut Window,
        cx: &mut App,
    ) {
        let focus_handle = self.input.read(cx).focus_handle.clone();
        window.handle_input(&focus_handle, ElementInputHandler::new(bounds, self.input.clone()), cx);
        if let Some(rows) = prepaint.rows.take() {
            let offset = prepaint.vertical_offset;
            // Rows scrolled out of view must not show in the padding.
            window.with_content_mask(Some(ContentMask { bounds }), |window| {
                for selection in prepaint.selections.drain(..) {
                    window.paint_quad(selection)
                }
                let mut origin = bounds.origin - point(px(0.), offset);
                for line in &rows.lines {
                    if let Err(error) =
                        line.paint(origin, rows.line_height, TextAlign::Left, None, window, cx)
                    {
                        log::error!("could not paint a text box line: {error}");
                    }
                    origin.y += line.size(rows.line_height).height;
                }
                if focus_handle.is_focused(window)
                    && let Some(cursor) = prepaint.cursor.take()
                {
                    window.paint_quad(cursor);
                }
            });
            // A thin thumb in the right padding says there is more to scroll.
            let content = rows.height();
            if content > bounds.size.height {
                let track = bounds.size.height;
                let thumb = (track * (track / content)).max(px(16.));
                let top = bounds.top() + (track - thumb) * (offset / (content - track));
                window.paint_quad(
                    fill(
                        Bounds::new(point(bounds.right() + px(4.), top), size(px(2.), thumb)),
                        cx.theme().text_tertiary,
                    )
                    .corner_radii(px(1.)),
                );
            }
            let shown = prepaint.shown;
            self.input.update(cx, |input, _cx| {
                input.last_rows = Some(rows);
                input.last_bounds = Some(bounds);
                input.vertical_offset = offset;
                input.revealed = Some(shown);
            });
            return;
        }
        for selection in prepaint.selections.drain(..) {
            window.paint_quad(selection)
        }
        let Some(line) = prepaint.line.take() else { return };
        let origin = bounds.origin - point(prepaint.offset, px(0.));
        if let Err(error) = line.paint(origin, window.line_height(), TextAlign::Left, None, window, cx) {
            log::error!("could not paint a text box line: {error}");
        }

        if focus_handle.is_focused(window)
            && let Some(cursor) = prepaint.cursor.take()
        {
            window.paint_quad(cursor);
        }

        self.input.update(cx, |input, _cx| {
            input.last_layout = Some(line);
            input.last_bounds = Some(bounds);
            input.horizontal_offset = prepaint.offset;
        });
    }
}

#[cfg(test)]
mod tests {
    use super::{split_runs, visible_caret_offset};
    use gpui::{TextRun, font, hsla, px};

    #[test]
    fn long_input_keeps_the_caret_visible_and_resets_after_deleting_or_resizing() {
        assert_eq!(visible_caret_offset(px(0.), px(500.), px(200.), px(500.)), px(304.));
        assert_eq!(visible_caret_offset(px(304.), px(50.), px(200.), px(500.)), px(50.));
        assert_eq!(visible_caret_offset(px(304.), px(80.), px(200.), px(80.)), px(0.));
        assert_eq!(visible_caret_offset(px(304.), px(500.), px(700.), px(500.)), px(0.));
    }

    #[test]
    fn contrast_selections_and_compositions_split_the_text_runs() {
        let text = hsla(0., 0., 0., 1.);
        let highlight_text = hsla(0., 0., 1., 1.);
        let run = TextRun {
            len: 10,
            font: font("Segoe UI"),
            color: text,
            background_color: None,
            underline: None,
            strikethrough: None,
        };
        let parts = |runs: Vec<TextRun>| -> Vec<(usize, bool, bool)> {
            runs.iter().map(|run| (run.len, run.color == highlight_text, run.underline.is_some())).collect()
        };
        // Nothing to split: one run in the text colour.
        assert_eq!(parts(split_runs(run.clone(), None, None)), [(10, false, false)]);
        // A selection outside a contrast theme is not passed in.
        assert_eq!(
            parts(split_runs(run.clone(), Some(2..5), None)),
            [(2, false, false), (3, false, true), (5, false, false)]
        );
        // A contrast selection takes the highlight text colour.
        assert_eq!(
            parts(split_runs(run.clone(), None, Some((3..7, highlight_text)))),
            [(3, false, false), (4, true, false), (3, false, false)]
        );
        // Overlapping, and an empty selection (a caret) changes nothing.
        assert_eq!(
            parts(split_runs(run.clone(), Some(2..5), Some((4..10, highlight_text)))),
            [(2, false, false), (2, false, true), (1, true, true), (5, true, false)]
        );
        assert_eq!(parts(split_runs(run, Some(0..10), Some((4..4, highlight_text)))), [(10, false, true)]);
    }
}
