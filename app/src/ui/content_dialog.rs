//! The Fluent ContentDialog, as the window's prompt: every `window.prompt`
//! the app makes opens one over the page, centred on the window and in the
//! app's own theme, instead of a legacy task dialog that sits away from the
//! window under an English "Warning" caption.
//!
//! Each answer has a role, given by building it with [`safe_answer`],
//! [`default_answer`] or [`answer`]:
//! - The safe answer takes WinUI's Close slot, rightmost, and Escape
//!   chooses it. It's the answer that changes least, such as Keep open.
//! - The default answer is the accent and has focus, so Enter chooses it.
//!   With none given, the safe answer is the default too, as it must be when
//!   the other answer is destructive, such as restarting while other apps
//!   may hold unsaved work. A default of its own suits an answer that loses
//!   nothing, such as opening Windows Security to turn protection back on.
//! - The others keep their order, left of the safe answer.
//!
//! The answer chosen is reported by its index in the list the prompt was
//! given. A plain label carries no role, except that GPUI reads the words
//! "OK" and "Cancel" as roles; with no safe answer, the first answer is safe
//! and the default.
//!
//! When the window is too short for the whole dialog, as at a large text
//! size, the title and message scroll and the buttons stay in view.
//!
//! The smoke layer dims the whole window and stops the page under it, while
//! the title bar's caption buttons stay usable: Minimize and Maximize work,
//! and Close asks the shell, which keeps the window while a dialog is open.
//! The rest of the title bar still moves the window.

use gpui::{
    App, AppContext, Context, EventEmitter, FocusHandle, Focusable, IntoElement, ParentElement, PromptButton,
    PromptHandle, PromptLevel, PromptResponse, Render, RenderablePromptHandle, Role, ScrollHandle,
    SharedString, Styled, Window, WindowControlArea, div, prelude::*, px,
};

use super::actions::{FocusNext, FocusPrevious, NavigateBack};
use super::titlebar::{CAPTION_BUTTONS_WIDTH, TITLE_BAR_HEIGHT};
use super::{Button, ScrollbarState, Typography, a11y_text, elevation_shadow, nested_scrollbar};
use crate::theme::{ActiveTheme, text_font};

/// WinUI's ContentDialog width limits.
const MIN_WIDTH: f32 = 320.;
const MAX_WIDTH: f32 = 548.;
/// The dialog's padding, and the space kept from the window's edges.
const PADDING: f32 = 24.;
/// Between buttons.
const GAP: f32 = 8.;
/// A standard button's padding and border either side of its label.
const BUTTON_CHROME: f32 = 26.;

/// The answer Escape chooses, in the Close slot. GPUI's own conversion from a
/// label gives a role by the label's text, so answers are built here instead.
pub fn safe_answer(label: impl Into<SharedString>) -> PromptButton {
    PromptButton::Cancel(label.into())
}

/// The answer Enter chooses: the accent, focused as the dialog opens.
pub fn default_answer(label: impl Into<SharedString>) -> PromptButton {
    PromptButton::Ok(label.into())
}

/// An answer with no role of its own.
pub fn answer(label: impl Into<SharedString>) -> PromptButton {
    PromptButton::Other(label.into())
}

/// Which answer Escape chooses and which is the default, by index.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Roles {
    safe: usize,
    default: usize,
}

impl Roles {
    fn of(actions: &[PromptButton]) -> Self {
        debug_assert!(
            actions.iter().filter(|action| action.is_cancel()).count() <= 1
                && actions.iter().filter(|action| matches!(action, PromptButton::Ok(_))).count() <= 1,
            "a dialog has at most one safe answer and one default"
        );
        let safe = actions.iter().position(PromptButton::is_cancel).unwrap_or(0);
        let default = actions.iter().position(|action| matches!(action, PromptButton::Ok(_))).unwrap_or(safe);
        Self { safe, default }
    }
}

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
    roles: Roles,
    /// One per answer, in the answers' order.
    focus: Vec<FocusHandle>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
}

impl EventEmitter<PromptResponse> for ContentDialog {}

impl Focusable for ContentDialog {
    /// The default answer has focus, so Enter chooses it.
    fn focus_handle(&self, _: &App) -> FocusHandle {
        self.focus[self.roles.default].clone()
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
            roles: Roles::of(actions),
            focus,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
        }
    }

    /// The answers' indexes as the buttons stand, left to right: the safe
    /// answer last, in the Close slot.
    fn visual_order(&self) -> Vec<usize> {
        visual_order(self.answers.len(), self.roles.safe)
    }

    /// Tab and Shift+Tab stay among the dialog's buttons.
    fn cycle(&self, forward: bool, window: &mut Window, cx: &mut Context<Self>) {
        let order = self.visual_order();
        let current = order.iter().position(|&index| self.focus[index].is_focused(window));
        let next = match current {
            Some(at) if forward => (at + 1) % order.len(),
            Some(at) => (at + order.len() - 1) % order.len(),
            None => order.iter().position(|&index| index == self.roles.default).unwrap_or(0),
        };
        window.focus(&self.focus[order[next]], cx);
    }

    /// Whether the buttons fit side by side in equal columns, and the width
    /// the dialog needs for them when they do, with labels set in `font`.
    fn button_layout(&self, font: &gpui::Font, window: &Window) -> (bool, f32) {
        let size = super::typography::BODY_SIZE.to_pixels(window.rem_size());
        let widest = self
            .answers
            .iter()
            .map(|label| {
                let run = [gpui::TextRun {
                    len: label.len(),
                    font: font.clone(),
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
fn visual_order(count: usize, safe: usize) -> Vec<usize> {
    (0..count).filter(|&index| index != safe).chain((safe < count).then_some(safe)).collect()
}

impl Render for ContentDialog {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let smoke = gpui::black().opacity(0.3);
        // The prompt is drawn as a root of its own, so it inherits nothing
        // from the window's root, the language's font fallbacks included.
        let font = text_font(cx);
        let (side_by_side, row_width) = self.button_layout(&font, window);
        let Roles { safe, default } = self.roles;
        let buttons = self.visual_order().into_iter().map(|index| {
            let label = self.answers[index].clone();
            Button::new(("dialog-answer", index), label)
                .when(index == default, Button::accent)
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
            .font(font)
            .on_action(cx.listener(|this, _: &FocusNext, window, cx| this.cycle(true, window, cx)))
            .on_action(cx.listener(|this, _: &FocusPrevious, window, cx| this.cycle(false, window, cx)))
            // Escape gives the safe answer, and never reaches the page's Back.
            .on_action(cx.listener(move |_, _: &NavigateBack, _, cx| cx.emit(PromptResponse(safe))))
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
            // The caption buttons dim with the rest. Without a hitbox, the
            // smoke leaves them their clicks and hover.
            .child(
                div()
                    .absolute()
                    .top_0()
                    .right_0()
                    .w(px(CAPTION_BUTTONS_WIDTH))
                    .h(px(TITLE_BAR_HEIGHT))
                    .bg(smoke),
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
        assert_eq!(visual_order(2, 0), [1, 0]);
        assert_eq!(visual_order(3, 0), [1, 2, 0]);
        assert_eq!(visual_order(2, 1), [0, 1]);
        assert_eq!(visual_order(3, 1), [0, 2, 1]);
        assert_eq!(visual_order(1, 0), [0]);
        assert!(visual_order(0, 0).is_empty());
    }

    #[test]
    fn the_safe_answer_is_the_default_unless_another_answer_is() {
        // A destructive question: the safe answer is the default too.
        let stop = [safe_answer("Keep creating"), answer("Stop")];
        assert_eq!(Roles::of(&stop), Roles { safe: 0, default: 0 });
        // Restarting on close can lose work in other apps: Restart later is
        // the default, rightmost, and Enter and Escape both choose it.
        let restart = [answer("Restart now"), safe_answer("Restart later")];
        assert_eq!(Roles::of(&restart), Roles { safe: 1, default: 1 });
        assert_eq!(visual_order(2, Roles::of(&restart).safe), [0, 1]);
        // An answer that loses nothing can be the default of its own.
        let protection = [default_answer("Open Windows Security"), safe_answer("Close window")];
        assert_eq!(Roles::of(&protection), Roles { safe: 1, default: 0 });
        // Labels alone, as GPUI passes them, keep the first answer safe.
        let labels = [answer("Keep open"), answer("Close window")];
        assert_eq!(Roles::of(&labels), Roles { safe: 0, default: 0 });
    }

    #[test]
    fn built_answers_keep_their_labels_whatever_they_say() {
        // GPUI's conversion from text would give "Cancel" a role and rename "ok".
        assert_eq!(answer("Cancel"), PromptButton::Other("Cancel".into()));
        assert_eq!(answer("ok").label().as_ref(), "ok");
        assert!(safe_answer("Don't restart").is_cancel());
    }
}
