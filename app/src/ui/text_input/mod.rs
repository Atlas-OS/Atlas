//! A themed, labelled text box, single- or multi-line. This module holds its
//! actions, state and editing; the submodules lay it out, draw it and take IME input.

// Adapted from Zed's GPUI examples/input.rs. Copyright Zed Industries, Apache-2.0.

mod element;
mod ime;
mod layout;

use std::ops::Range;

use super::typography::CAPTION_LINE_HEIGHT;
use super::{Icon, Typography, icon_in_line_sized};
use crate::theme::{ActiveTheme, Theme};
use gpui::{
    App, Bounds, ClipboardItem, Context, CursorStyle, EntityInputHandler, FocusHandle, Focusable,
    MouseButton, MouseDownEvent, MouseMoveEvent, MouseUpEvent, Pixels, Point, Rems, ScrollWheelEvent,
    ShapedLine, SharedString, Window, actions, div, prelude::*, px,
};
use unicode_segmentation::*;

use element::TextElement;
use ime::{multi_line, single_line};
use layout::{Rows, caret_row, row_end};

actions!(
    text_input,
    [
        Backspace,
        Delete,
        Left,
        Right,
        Up,
        Down,
        SelectLeft,
        SelectRight,
        SelectUp,
        SelectDown,
        SelectAll,
        Home,
        End,
        SelectHome,
        SelectEnd,
        TextStart,
        TextEnd,
        SelectTextStart,
        SelectTextEnd,
        PageUp,
        PageDown,
        SelectPageUp,
        SelectPageDown,
        Newline,
        Paste,
        Cut,
        Copy,
    ]
);

const LINE_HEIGHT: Rems = Rems(22. / 16.);
const PADDING_Y: Pixels = px(6.);

pub struct TextInput {
    focus_handle: FocusHandle,
    content: SharedString,
    id: &'static str,
    /// The accessible name.
    label: fn() -> String,
    /// The hint shown while the input is empty.
    placeholder: fn() -> String,
    read_only: bool,
    multiline: bool,
    error: Option<SharedString>,
    description: Option<SharedString>,
    horizontal_offset: Pixels,
    /// How far a multi-line input's text is scrolled up.
    vertical_offset: Pixels,
    /// The caret offset and text length last scrolled into view, so a wheel
    /// scroll stays put until the caret moves or the text changes.
    revealed: Option<(usize, usize)>,
    /// The caret offset Up or Down last moved to, and the x it aims for.
    goal: Option<(usize, Pixels)>,
    /// The caret is at the end of a row that wraps without a space, and is
    /// drawn there, not at the start of the next row (see [`caret_row`]).
    at_row_end: bool,
    selected_range: Range<usize>,
    selection_reversed: bool,
    marked_range: Option<Range<usize>>,
    last_layout: Option<ShapedLine>,
    last_rows: Option<Rows>,
    last_bounds: Option<Bounds<Pixels>>,
    is_selecting: bool,
}

impl TextInput {
    /// `label` and `placeholder` are called when the input draws, so they
    /// follow a language change: pass `|| t!("...")`.
    pub fn new(
        cx: &mut Context<Self>,
        id: &'static str,
        label: fn() -> String,
        placeholder: fn() -> String,
    ) -> Self {
        Self {
            focus_handle: cx.focus_handle(),
            content: "".into(),
            id,
            label,
            placeholder,
            read_only: false,
            multiline: false,
            error: None,
            description: None,
            horizontal_offset: px(0.),
            vertical_offset: px(0.),
            revealed: None,
            goal: None,
            at_row_end: false,
            selected_range: 0..0,
            selection_reversed: false,
            marked_range: None,
            last_layout: None,
            last_rows: None,
            last_bounds: None,
            is_selecting: false,
        }
    }
    pub fn value(&self) -> &str {
        self.content.as_ref()
    }
    pub fn set_read_only(&mut self, read_only: bool) {
        self.read_only = read_only;
    }

    /// Makes the input multi-line: the text wraps, Enter starts a new line
    /// and pasted line breaks are kept.
    pub fn multiline(&mut self) {
        self.multiline = true;
    }

    /// What is wrong with the value, or `None` once it is fixed. The field
    /// takes a critical outline with the message under it (and, focused, a
    /// critical underline), and the message leads its accessible
    /// description. Write it as the fix: "Enter at least 10 characters".
    pub fn set_error(&mut self, error: Option<SharedString>) {
        self.error = error;
    }

    /// Help the page shows beside the field, such as what to write. The
    /// field reads it out as its description, after any error. Set it on
    /// each render, so it follows a language change.
    pub fn set_description(&mut self, description: Option<SharedString>) {
        self.description = description;
    }

    /// Replaces the text, with the caret at the end and nothing selected.
    pub fn set_value(&mut self, value: impl Into<SharedString>, cx: &mut Context<Self>) {
        self.content = value.into();
        let end = self.content.len();
        self.selected_range = end..end;
        self.selection_reversed = false;
        self.marked_range = None;
        self.at_row_end = false;
        cx.notify();
    }
    fn left(&mut self, _: &Left, _: &mut Window, cx: &mut Context<Self>) {
        if self.selected_range.is_empty() {
            self.move_to(self.previous_boundary(self.cursor_offset()), cx);
        } else {
            self.move_to(self.selected_range.start, cx)
        }
    }

    fn right(&mut self, _: &Right, _: &mut Window, cx: &mut Context<Self>) {
        if self.selected_range.is_empty() {
            self.move_to(self.next_boundary(self.selected_range.end), cx);
        } else {
            self.move_to(self.selected_range.end, cx)
        }
    }

    fn select_left(&mut self, _: &SelectLeft, _: &mut Window, cx: &mut Context<Self>) {
        self.select_to(self.previous_boundary(self.cursor_offset()), cx);
    }

    fn select_right(&mut self, _: &SelectRight, _: &mut Window, cx: &mut Context<Self>) {
        self.select_to(self.next_boundary(self.cursor_offset()), cx);
    }

    fn up(&mut self, _: &Up, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(false, 1, false, cx);
    }

    fn down(&mut self, _: &Down, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(true, 1, false, cx);
    }

    fn select_up(&mut self, _: &SelectUp, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(false, 1, true, cx);
    }

    fn select_down(&mut self, _: &SelectDown, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(true, 1, true, cx);
    }

    fn page_up(&mut self, _: &PageUp, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(false, self.page_rows(), false, cx);
    }

    fn page_down(&mut self, _: &PageDown, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(true, self.page_rows(), false, cx);
    }

    fn select_page_up(&mut self, _: &SelectPageUp, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(false, self.page_rows(), true, cx);
    }

    fn select_page_down(&mut self, _: &SelectPageDown, _: &mut Window, cx: &mut Context<Self>) {
        self.move_vertically(true, self.page_rows(), true, cx);
    }

    /// How many rows a multi-line input shows at once: a page for Page Up
    /// and Page Down.
    fn page_rows(&self) -> usize {
        match (self.last_bounds, self.rows()) {
            (Some(bounds), Some(rows)) => ((bounds.size.height / rows.line_height) as usize).max(1),
            _ => 1,
        }
    }

    /// Moves the caret `count` visual rows, keeping to the column a run of
    /// these moves started from. From the first or last row it goes to the
    /// start or end of the text.
    fn move_vertically(&mut self, down: bool, count: usize, select: bool, cx: &mut Context<Self>) {
        let cursor = self.cursor_offset();
        let Some(rows) = self.rows() else { return };
        let row = caret_row(&rows.rows, cursor, self.at_row_end);
        let last = rows.rows.len() - 1;
        let x = match self.goal {
            Some((at, x)) if at == cursor => x,
            _ => rows.position(cursor, row).x,
        };
        let (target, at_row_end) = if !down && row == 0 {
            (0, false)
        } else if down && row == last {
            (self.content.len(), false)
        } else {
            let to = if down { (row + count).min(last) } else { row.saturating_sub(count) };
            let index = rows.index_at(to, x);
            (index, rows.wraps_at(to, index))
        };
        if select {
            self.select_to(target, cx)
        } else {
            self.move_to(target, cx)
        }
        self.at_row_end = at_row_end;
        self.goal = Some((target, x));
    }

    fn select_all(&mut self, _: &SelectAll, _: &mut Window, cx: &mut Context<Self>) {
        self.move_to(0, cx);
        self.select_to(self.content.len(), cx)
    }

    /// The start of the text, or of the caret's row in a multi-line input.
    fn line_start(&self) -> usize {
        let cursor = self.cursor_offset();
        self.rows().map_or(0, |rows| rows.rows[caret_row(&rows.rows, cursor, self.at_row_end)].start)
    }

    /// The end of the text, or of the caret's row in a multi-line input, and
    /// whether the caret stays at the end of that row where it wraps.
    fn line_end(&self) -> (usize, bool) {
        let cursor = self.cursor_offset();
        self.rows().map_or((self.content.len(), false), |rows| {
            let row = caret_row(&rows.rows, cursor, self.at_row_end);
            let end = row_end(&rows.rows[row], &self.content);
            (end, rows.wraps_at(row, end))
        })
    }

    fn home(&mut self, _: &Home, _: &mut Window, cx: &mut Context<Self>) {
        self.move_to(self.line_start(), cx);
    }

    fn end(&mut self, _: &End, _: &mut Window, cx: &mut Context<Self>) {
        let (end, at_row_end) = self.line_end();
        self.move_to(end, cx);
        self.at_row_end = at_row_end;
    }

    fn select_home(&mut self, _: &SelectHome, _: &mut Window, cx: &mut Context<Self>) {
        self.select_to(self.line_start(), cx);
    }

    fn select_end(&mut self, _: &SelectEnd, _: &mut Window, cx: &mut Context<Self>) {
        let (end, at_row_end) = self.line_end();
        self.select_to(end, cx);
        self.at_row_end = at_row_end;
    }

    fn text_start(&mut self, _: &TextStart, _: &mut Window, cx: &mut Context<Self>) {
        self.move_to(0, cx);
    }

    fn text_end(&mut self, _: &TextEnd, _: &mut Window, cx: &mut Context<Self>) {
        self.move_to(self.content.len(), cx);
    }

    fn select_text_start(&mut self, _: &SelectTextStart, _: &mut Window, cx: &mut Context<Self>) {
        self.select_to(0, cx);
    }

    fn select_text_end(&mut self, _: &SelectTextEnd, _: &mut Window, cx: &mut Context<Self>) {
        self.select_to(self.content.len(), cx);
    }

    fn newline(&mut self, _: &Newline, window: &mut Window, cx: &mut Context<Self>) {
        self.replace_text_in_range(None, "\n", window, cx)
    }

    fn backspace(&mut self, _: &Backspace, window: &mut Window, cx: &mut Context<Self>) {
        if self.selected_range.is_empty() {
            let prev = self.previous_boundary(self.cursor_offset());
            if self.cursor_offset() == prev {
                window.play_system_bell();
                return;
            }
            self.select_to(prev, cx)
        }
        self.replace_text_in_range(None, "", window, cx)
    }

    fn delete(&mut self, _: &Delete, window: &mut Window, cx: &mut Context<Self>) {
        if self.selected_range.is_empty() {
            let next = self.next_boundary(self.cursor_offset());
            if self.cursor_offset() == next {
                window.play_system_bell();
                return;
            }
            self.select_to(next, cx)
        }
        self.replace_text_in_range(None, "", window, cx)
    }

    fn on_mouse_down(&mut self, event: &MouseDownEvent, window: &mut Window, cx: &mut Context<Self>) {
        self.is_selecting = true;
        window.focus(&self.focus_handle, cx);

        let (index, at_row_end) = self.index_for_mouse_position(event.position);
        if event.modifiers.shift {
            self.select_to(index, cx);
        } else {
            self.move_to(index, cx)
        }
        self.at_row_end = at_row_end;
    }

    fn on_mouse_up(&mut self, _: &MouseUpEvent, _window: &mut Window, _: &mut Context<Self>) {
        self.is_selecting = false;
    }

    fn on_mouse_move(&mut self, event: &MouseMoveEvent, _: &mut Window, cx: &mut Context<Self>) {
        if self.is_selecting {
            let (index, at_row_end) = self.index_for_mouse_position(event.position);
            self.select_to(index, cx);
            self.at_row_end = at_row_end;
        }
    }

    fn paste(&mut self, _: &Paste, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(text) = cx.read_from_clipboard().and_then(|item| item.text()) {
            let text = if self.multiline { multi_line(&text) } else { single_line(&text) };
            self.replace_text_in_range(None, &text, window, cx);
        }
    }

    /// Scrolls a multi-line input whose text is taller than it. At either
    /// end the wheel goes on to scroll the page.
    fn on_scroll_wheel(&mut self, event: &ScrollWheelEvent, _: &mut Window, cx: &mut Context<Self>) {
        let (Some(bounds), Some(rows)) = (self.last_bounds, self.last_rows.as_ref()) else { return };
        let limit = (rows.height() - bounds.size.height).max(px(0.));
        let offset =
            (self.vertical_offset - event.delta.pixel_delta(rows.line_height).y).clamp(px(0.), limit);
        if offset != self.vertical_offset {
            self.vertical_offset = offset;
            cx.stop_propagation();
            cx.notify();
        }
    }

    fn copy(&mut self, _: &Copy, _: &mut Window, cx: &mut Context<Self>) {
        if !self.selected_range.is_empty() {
            cx.write_to_clipboard(ClipboardItem::new_string(
                self.content[self.selected_range.clone()].to_string(),
            ));
        }
    }
    fn cut(&mut self, _: &Cut, window: &mut Window, cx: &mut Context<Self>) {
        if !self.selected_range.is_empty() {
            self.copy(&Copy, window, cx);
            self.replace_text_in_range(None, "", window, cx)
        }
    }

    fn move_to(&mut self, offset: usize, cx: &mut Context<Self>) {
        self.selected_range = offset..offset;
        self.at_row_end = false;
        cx.notify()
    }

    fn cursor_offset(&self) -> usize {
        if self.selection_reversed { self.selected_range.start } else { self.selected_range.end }
    }

    /// The multi-line layout, when it was made for the current text.
    fn rows(&self) -> Option<&Rows> {
        self.last_rows.as_ref().filter(|rows| rows.text == self.content)
    }

    /// The caret offset for a click at `position`, and whether it is at the
    /// end of the row clicked, where that row wraps.
    fn index_for_mouse_position(&self, position: Point<Pixels>) -> (usize, bool) {
        if self.content.is_empty() {
            return (0, false);
        }
        if self.multiline {
            let (Some(bounds), Some(rows)) = (self.last_bounds.as_ref(), self.rows()) else {
                return (0, false);
            };
            let local = position - bounds.origin;
            let row = rows.row_at(local.y + self.vertical_offset);
            let index = rows.index_at(row, local.x);
            return (index, rows.wraps_at(row, index));
        }

        let (Some(bounds), Some(line)) = (self.last_bounds.as_ref(), self.last_layout.as_ref()) else {
            return (0, false);
        };
        if position.y < bounds.top() {
            return (0, false);
        }
        if position.y > bounds.bottom() {
            return (self.content.len(), false);
        }
        (line.closest_index_for_x(position.x - bounds.left() + self.horizontal_offset), false)
    }

    fn select_to(&mut self, offset: usize, cx: &mut Context<Self>) {
        self.at_row_end = false;
        if self.selection_reversed {
            self.selected_range.start = offset
        } else {
            self.selected_range.end = offset
        };
        if self.selected_range.end < self.selected_range.start {
            self.selection_reversed = !self.selection_reversed;
            self.selected_range = self.selected_range.end..self.selected_range.start;
        }
        cx.notify()
    }

    fn previous_boundary(&self, offset: usize) -> usize {
        self.content
            .grapheme_indices(true)
            .rev()
            .find_map(|(idx, _)| (idx < offset).then_some(idx))
            .unwrap_or(0)
    }

    fn next_boundary(&self, offset: usize) -> usize {
        self.content
            .grapheme_indices(true)
            .find_map(|(idx, _)| (idx > offset).then_some(idx))
            .unwrap_or(self.content.len())
    }
}

/// The field's outline, as WinUI's TextBox draws it: a hairline border with
/// a stronger line along the bottom at rest, and a 2px underline when
/// focused, in the accent colour, or the critical colour for a wrong value,
/// whose whole border is critical too. A contrast theme keeps a full outline,
/// in the accent colour when focused.
fn outline(theme: &Theme, error: bool, focused: bool) -> (gpui::Hsla, Option<gpui::BoxShadow>) {
    if theme.high_contrast {
        let colour = match (error, focused) {
            (true, _) => theme.critical,
            (false, true) => theme.accent,
            (false, false) => theme.control_stroke,
        };
        return (colour, None);
    }
    let border = if error { theme.critical } else { theme.control_stroke };
    let (colour, height) = match (error, focused) {
        (true, true) => (theme.critical, 2.),
        (false, true) => (theme.accent, 2.),
        (_, false) => (theme.control_strong_stroke, 1.),
    };
    // An inset shadow moved up by its height paints a band along the bottom
    // that follows the rounded corners, under the 1px border and without
    // moving anything.
    let underline = gpui::BoxShadow {
        color: colour,
        offset: gpui::point(px(0.), px(-height)),
        blur_radius: px(0.),
        spread_radius: px(0.),
        inset: true,
    };
    (border, Some(underline))
}

/// The error under a field: an error glyph and the message, wrapping.
pub(crate) fn error_caption(error: SharedString, theme: &Theme) -> impl IntoElement {
    div()
        .flex()
        .items_start()
        .gap(px(6.))
        .type_caption()
        .text_color(theme.critical)
        .child(icon_in_line_sized(Icon::ErrorBadge, 12., CAPTION_LINE_HEIGHT).type_caption())
        .child(div().flex_1().min_w_0().child(error))
}

impl Render for TextInput {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let line_height = LINE_HEIGHT.to_pixels(window.rem_size());
        let theme = cx.theme().clone();
        let focused = self.focus_handle.is_focused(window);
        let (border, underline) = outline(&theme, self.error.is_some(), focused);
        let fill = if focused { theme.control_fill_input_active } else { theme.control_fill };
        // The error first, then the help: neither replaces the other.
        let description = super::compose_description(&[self.error.clone(), self.description.clone()]);
        let input = div()
            .id(self.id)
            .role(if self.multiline { gpui::Role::MultilineTextInput } else { gpui::Role::TextInput })
            .aria_label((self.label)())
            .aria_value(self.content.clone())
            .when_some(description, |this, description| this.aria_description(description))
            // Still focusable and readable, as a WinUI TextBox with IsReadOnly is.
            .aria_read_only(self.read_only)
            .flex()
            .key_context(if self.multiline { "TextInput multiline" } else { "TextInput" })
            .track_focus(&self.focus_handle(cx).tab_index(0).tab_stop(true))
            .cursor(CursorStyle::IBeam)
            .on_action(cx.listener(Self::backspace))
            .on_action(cx.listener(Self::delete))
            .on_action(cx.listener(Self::left))
            .on_action(cx.listener(Self::right))
            .on_action(cx.listener(Self::up))
            .on_action(cx.listener(Self::down))
            .on_action(cx.listener(Self::select_left))
            .on_action(cx.listener(Self::select_right))
            .on_action(cx.listener(Self::select_up))
            .on_action(cx.listener(Self::select_down))
            .on_action(cx.listener(Self::select_all))
            .on_action(cx.listener(Self::home))
            .on_action(cx.listener(Self::end))
            .on_action(cx.listener(Self::select_home))
            .on_action(cx.listener(Self::select_end))
            .on_action(cx.listener(Self::text_start))
            .on_action(cx.listener(Self::text_end))
            .on_action(cx.listener(Self::select_text_start))
            .on_action(cx.listener(Self::select_text_end))
            .on_action(cx.listener(Self::page_up))
            .on_action(cx.listener(Self::page_down))
            .on_action(cx.listener(Self::select_page_up))
            .on_action(cx.listener(Self::select_page_down))
            .on_action(cx.listener(Self::newline))
            .on_action(cx.listener(Self::paste))
            .on_action(cx.listener(Self::cut))
            .on_action(cx.listener(Self::copy))
            .on_mouse_down(MouseButton::Left, cx.listener(Self::on_mouse_down))
            .on_mouse_up(MouseButton::Left, cx.listener(Self::on_mouse_up))
            .on_mouse_up_out(MouseButton::Left, cx.listener(Self::on_mouse_up))
            .on_mouse_move(cx.listener(Self::on_mouse_move))
            .on_scroll_wheel(cx.listener(Self::on_scroll_wheel))
            .bg(fill)
            .border_1()
            .border_color(border)
            .when_some(underline, |this, line| this.shadow(vec![line]))
            .rounded(px(4.))
            .overflow_hidden()
            .type_body()
            .line_height(LINE_HEIGHT)
            .text_color(theme.text_primary)
            .child(
                div()
                    .when(!self.multiline, |this| this.h(line_height + PADDING_Y * 2.))
                    .w_full()
                    .px(px(10.))
                    .py(PADDING_Y)
                    .child(TextElement { input: cx.entity() }),
            );
        // Screen readers hear the error as the field's description, so the
        // caption stays out of the accessibility tree.
        let field = div()
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(input)
            .when_some(self.error.clone(), |this, error| this.child(error_caption(error, &theme)));
        super::Revealed::new(field)
    }
}

impl Focusable for TextInput {
    fn focus_handle(&self, _: &App) -> FocusHandle {
        self.focus_handle.clone()
    }
}
