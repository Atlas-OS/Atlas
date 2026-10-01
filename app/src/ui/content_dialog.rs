//! The Fluent ContentDialog, as the window's prompt: every `window.prompt`
//! the app makes opens one over the page, centred on the window and in the
//! app's own theme, instead of a legacy task dialog that sits away from the
//! window under an English "Warning" caption.
//!
//! The first answer is the safe one ("Keep open"). It takes WinUI's Close
//! slot: rightmost, accent and focused, and Escape chooses it. The others
//! keep their order to its left. The answer chosen is reported by its index
//! in the list the prompt was given, so callers don't change.
//!
//! When the window is too short for the whole dialog, as at a large text
//! size, the title and message scroll and the buttons stay in view.
//!
//! The smoke layer stops the page under it, and the title bar's caption
//! buttons stay usable: Minimize and Maximize work, and Close asks the shell,
//! which keeps the window while a dialog is open. The rest of the title bar
//! still moves the window.

use gpui::{
    App, AppContext, Context, EventEmitter, FocusHandle, Focusable, IntoElement, ParentElement, PromptButton,
    PromptHandle, PromptLevel, PromptResponse, Render, RenderablePromptHandle, Role, ScrollHandle,
    SharedString, Styled, Window, WindowControlArea, div, prelude::*, px,
};

use super::actions::{FocusNext, FocusPrevious, NavigateBack};
use super::titlebar::{CAPTION_BUTTONS_WIDTH, TITLE_BAR_HEIGHT};
use super::{Button, ScrollbarState, Typography, a11y_text, elevation_shadow, nested_scrollbar};
use crate::theme::ActiveTheme;

/// WinUI's ContentDialog width limits.
const MIN_WIDTH: f32 = 320.;
const MAX_WIDTH: f32 = 548.;
/// The dialog's padding, and the space kept from the window's edges.
const PADDING: f32 = 24.;
/// Between buttons.
const GAP: f32 = 8.;
/// A standard button's padding and border either side of its label.
const BUTTON_CHROME: f32 = 26.;

/// The prompt builder `main` registers with `set_prompt_builder`.
pub fn build(
    _level: PromptLevel,
    message: &str,
    detail: Option<&str>,
    actions: &[PromptButton],
    handle: PromptHandle,
    window: &mut Window,
    cx: &mut App,
) -> RenderablePromptHandle {
    let dialog = cx.new(|cx| ContentDialog::new(message, detail, actions, cx));
    handle.with_view(dialog, window, cx)
}

pub struct ContentDialog {
    title: SharedString,
    message: Option<SharedString>,
    answers: Vec<SharedString>,
    /// One per answer, in the answers' order.
    focus: Vec<FocusHandle>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
}

impl EventEmitter<PromptResponse> for ContentDialog {}

impl Focusable for ContentDialog {
    /// The safe answer has focus, so Enter keeps the window.
    fn focus_handle(&self, _: &App) -> FocusHandle {
        self.focus[0].clone()
    }
}

impl ContentDialog {
    fn new(title: &str, message: Option<&str>, actions: &[PromptButton], cx: &mut Context<Self>) -> Self {
        let answers: Vec<SharedString> = actions.iter().map(|action| action.label().clone()).collect();
        let focus = answers.iter().map(|_| cx.focus_handle()).collect();
        Self {
            title: title.to_owned().into(),
            message: message.filter(|message| !message.is_empty()).map(|message| message.to_owned().into()),
            answers,
            focus,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
        }
    }

    /// The answers' indexes as the buttons stand, left to right: the safe
    /// answer last, in the Close slot.
    fn visual_order(&self) -> Vec<usize> {
        visual_order(self.answers.len())
    }

    /// Tab and Shift+Tab stay among the dialog's buttons.
    fn cycle(&self, forward: bool, window: &mut Window, cx: &mut Context<Self>) {
        let order = self.visual_order();
        let current = order.iter().position(|&index| self.focus[index].is_focused(window));
        let next = match current {
            Some(at) if forward => (at + 1) % order.len(),
            Some(at) => (at + order.len() - 1) % order.len(),
            None => order.len() - 1,
        };
        window.focus(&self.focus[order[next]], cx);
    }

    /// Whether the buttons fit side by side in equal columns, and the width
    /// the dialog needs for them when they do.
    fn button_layout(&self, window: &Window) -> (bool, f32) {
        let size = super::typography::BODY_SIZE.to_pixels(window.rem_size());
        let widest = self
            .answers
            .iter()
            .map(|label| {
                let run = [gpui::TextRun {
                    len: label.len(),
                    font: gpui::font(crate::theme::FONT_TEXT),
                    color: gpui::black(),
                    background_color: None,
                    underline: None,
                    strikethrough: None,
                }];
                f32::from(window.text_system().shape_line(label.clone(), size, &run, None).width)
            })
            .fold(0., f32::max);
        let count = self.answers.len() as f32;
        let row = count * (widest + BUTTON_CHROME) + (count - 1.) * GAP;
        let available =
            (f32::from(window.viewport_size().width) - 2. * PADDING).min(MAX_WIDTH) - 2. * PADDING;
        (row <= available, (row + 2. * PADDING).max(MIN_WIDTH))
    }
}

/// See [`ContentDialog::visual_order`].
fn visual_order(count: usize) -> Vec<usize> {
    (1..count).chain((count > 0).then_some(0)).collect()
}

impl Render for ContentDialog {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let smoke = gpui::black().opacity(0.3);
        let (side_by_side, row_width) = self.button_layout(window);
        let buttons = self.visual_order().into_iter().map(|index| {
            let label = self.answers[index].clone();
            Button::new(("dialog-answer", index), label)
                .when(index == 0, Button::accent)
                .focus_handle(self.focus[index].clone())
                .on_click(cx.listener(move |_, _, _, cx| cx.emit(PromptResponse(index))))
                .into_any_element()
        });
        let footer = div()
            .flex()
            .flex_none()
            .gap(px(GAP))
            .p(px(PADDING))
            .bg(theme.solid_background)
            .border_t_1()
            .border_color(theme.card_stroke)
            .map(|this| if side_by_side { this.flex_row() } else { this.flex_col() })
            // Equal columns side by side; full width stacked, the safe answer last.
            .children(buttons.map(|button| div().flex_1().min_w_0().flex().flex_col().child(button)));
        let dialog = div()
            .id("content-dialog")
            .role(Role::AlertDialog)
            .aria_label(self.title.clone())
            .when_some(self.message.clone(), |this, message| this.aria_description(message))
            .flex()
            .flex_col()
            .min_w(px(row_width.min(MAX_WIDTH)))
            .max_w(px(MAX_WIDTH))
            .max_h_full()
            .rounded(px(8.))
            .overflow_hidden()
            .bg(theme.solid_background)
            .border_1()
            .border_color(theme.flyout_stroke)
            .shadow(elevation_shadow(&theme, 32.))
            .child(
                div()
                    .relative()
                    .flex()
                    .flex_col()
                    .min_h_0()
                    .bg(theme.layer_fill)
                    .child(
                        div()
                            .id("content-dialog-body")
                            .flex()
                            .flex_col()
                            .min_h_0()
                            .overflow_y_scroll()
                            .track_scroll(&self.scroll)
                            .gap(px(12.))
                            .p(px(PADDING))
                            .text_color(theme.text_primary)
                            .child(
                                div()
                                    .type_subtitle()
                                    .child(a11y_text("content-dialog-title", self.title.clone())),
                            )
                            .when_some(self.message.clone(), |this, message| {
                                this.child(
                                    div().type_body().child(a11y_text("content-dialog-message", message)),
                                )
                            }),
                    )
                    .child(nested_scrollbar(&self.scroll, &self.scrollbar)),
            )
            .child(footer);
        div()
            .id("content-dialog-layer")
            .key_context("ContentDialog")
            .size_full()
            .relative()
            .font_family(crate::theme::FONT_TEXT)
            .on_action(cx.listener(|this, _: &FocusNext, window, cx| this.cycle(true, window, cx)))
            .on_action(cx.listener(|this, _: &FocusPrevious, window, cx| this.cycle(false, window, cx)))
            // Escape answers Keep open, and never reaches the page's Back.
            .on_action(cx.listener(|_, _: &NavigateBack, _, cx| cx.emit(PromptResponse(0))))
            // The title bar left of the caption buttons still moves the window.
            .child(
                div()
                    .id("content-dialog-title-bar")
                    .absolute()
                    .top_0()
                    .left_0()
                    .right(px(CAPTION_BUTTONS_WIDTH))
                    .h(px(TITLE_BAR_HEIGHT))
                    .bg(smoke)
                    .occlude()
                    .window_control_area(WindowControlArea::Drag),
            )
            .child(
                div()
                    .id("content-dialog-smoke")
                    .absolute()
                    .top(px(TITLE_BAR_HEIGHT))
                    .left_0()
                    .right_0()
                    .bottom_0()
                    .bg(smoke)
                    .occlude(),
            )
            .child(
                div()
                    .absolute()
                    .top(px(TITLE_BAR_HEIGHT))
                    .left_0()
                    .right_0()
                    .bottom_0()
                    .p(px(PADDING))
                    .flex()
                    .items_center()
                    .justify_center()
                    .child(dialog),
            )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_safe_answer_takes_the_close_slot_and_the_rest_keep_their_order() {
        assert_eq!(visual_order(2), [1, 0]);
        assert_eq!(visual_order(3), [1, 2, 0]);
        assert_eq!(visual_order(1), [0]);
        assert!(visual_order(0).is_empty());
    }
}
