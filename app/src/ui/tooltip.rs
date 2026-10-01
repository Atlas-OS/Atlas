//! The Fluent tooltip: a short caption beside a control. It appears after
//! the Windows hover delay, or at once when the control takes keyboard
//! focus, and goes when the pointer leaves, focus moves on, the control is
//! pressed or Escape is pressed. It stays while its trigger lasts, so it can
//! be read at any pace.

use std::cell::Cell;
use std::rc::Rc;
use std::time::Duration;

use gpui::{
    Anchor, App, Bounds, Context, Div, Entity, FocusHandle, IntoElement, MouseButton, ParentElement, Pixels,
    SharedString, Stateful, Styled, Subscription, Task, Window, anchored, deferred, div, point, prelude::*,
    px,
};

use super::typography::CAPTION_LINE_HEIGHT;
use super::{Typography, drawn_bounds, elevation_shadow};
use crate::theme::ActiveTheme;

/// Windows shows a tooltip after the double-click time, 500 ms by default.
const SHOW_DELAY: Duration = Duration::from_millis(500);
/// Between the control and its tooltip.
const GAP: Pixels = px(4.);
/// Keeps a tooltip clear of the window's edges.
const MARGIN: Pixels = px(4.);
/// Drawn over everything else, flyouts included.
const PRIORITY: usize = 2;

/// A control's tooltip between frames. Keep one per control, keyed by its id.
pub(super) struct TooltipState {
    /// The control's focus handle, so keyboard focus can show the tooltip.
    pub(super) focus: FocusHandle,
    /// The pointer has rested on the control for the hover delay.
    hovered: bool,
    /// Escape or a press hid the tooltip; it stays hidden until both the
    /// pointer and focus have left.
    dismissed: bool,
    show: Option<Task<()>>,
    /// Takes Escape while the tooltip shows, before the page's own Escape.
    escape: Option<Subscription>,
    /// Where the control was drawn last, to place the tooltip beside it.
    bounds: Rc<Cell<Bounds<Pixels>>>,
}

impl TooltipState {
    pub(super) fn new(cx: &mut Context<Self>) -> Self {
        Self {
            focus: cx.focus_handle(),
            hovered: false,
            dismissed: false,
            show: None,
            escape: None,
            bounds: Rc::default(),
        }
    }

    fn hover(&mut self, hovered: bool, cx: &mut Context<Self>) {
        if hovered {
            self.show = Some(cx.spawn(async move |this, cx| {
                cx.background_executor().timer(SHOW_DELAY).await;
                this.update(cx, |this, cx| {
                    this.hovered = true;
                    cx.notify();
                })
                .ok();
            }));
        } else {
            self.show = None;
            self.hovered = false;
            cx.notify();
        }
    }

    fn dismiss(&mut self, cx: &mut Context<Self>) {
        self.dismissed = true;
        self.show = None;
        cx.notify();
    }

    /// Whether the tooltip shows this frame, with Escape held for it while it does.
    fn visible(&mut self, keyboard_focus: bool, cx: &mut Context<Self>) -> bool {
        if !self.hovered && !keyboard_focus {
            self.dismissed = false;
        }
        let visible = !self.dismissed && (self.hovered || keyboard_focus);
        if !visible {
            self.escape = None;
        } else if self.escape.is_none() {
            let state = cx.weak_entity();
            self.escape = Some(cx.intercept_keystrokes(move |event, _, cx| {
                if event.keystroke.key == "escape"
                    && !event.keystroke.modifiers.modified()
                    && state.update(cx, |state, cx| state.dismiss(cx)).is_ok()
                {
                    cx.stop_propagation();
                }
            }));
        }
        visible
    }
}

/// Gives `control` the tooltip `text`, and `state`'s focus handle as its tab stop.
pub(super) fn attach(
    control: Stateful<Div>,
    text: SharedString,
    state: &Entity<TooltipState>,
    window: &mut Window,
    cx: &mut App,
) -> Stateful<Div> {
    let keyboard_focus = state.read(cx).focus.is_focused(window) && window.last_input_was_keyboard();
    let visible = state.update(cx, |state, cx| state.visible(keyboard_focus, cx));
    let bounds = state.read(cx).bounds.clone();
    let drawn = bounds.get();
    let focus = state.read(cx).focus.clone().tab_index(0).tab_stop(true);
    let (hover, press) = (state.clone(), state.clone());
    control
        .track_focus(&focus)
        .on_hover(move |hovered, _, cx| hover.update(cx, |state, cx| state.hover(*hovered, cx)))
        .on_mouse_down(MouseButton::Left, move |_, _, cx| press.update(cx, |state, cx| state.dismiss(cx)))
        .child(drawn_bounds(bounds))
        // Placed by the last frame's bounds, which the first frame lacks.
        .when(visible && !drawn.is_empty(), |this| this.child(bubble(text, drawn, window, cx)))
}

/// The tooltip itself: above the control, or below it when the window has no
/// room above, centred and kept inside the window.
fn bubble(text: SharedString, control: Bounds<Pixels>, window: &Window, cx: &App) -> impl IntoElement {
    let theme = cx.theme();
    let rem = window.rem_size();
    // Padding and stroke around one line of caption text.
    let line = CAPTION_LINE_HEIGHT.to_pixels(rem) + px(16.);
    let (anchor, at) = if fits_above(control, line) {
        (Anchor::BottomCenter, point(control.center().x, control.top() - GAP))
    } else {
        (Anchor::TopCenter, point(control.center().x, control.bottom() + GAP))
    };
    // WinUI's 320px limit, scaled with the text and kept inside the window.
    let width = (rem * 20.).min(window.viewport_size().width - MARGIN * 2.);
    deferred(
        anchored().anchor(anchor).position(at).snap_to_window_with_margin(MARGIN).child(
            div()
                .max_w(width)
                .px(px(9.))
                .pt(px(6.))
                .pb(px(8.))
                .rounded(px(4.))
                .bg(theme.flyout_fill)
                .border_1()
                .border_color(theme.flyout_stroke)
                .shadow(elevation_shadow(theme, 16.))
                .type_caption()
                .text_color(theme.text_primary)
                .child(text),
        ),
    )
    .with_priority(PRIORITY)
}

/// Whether a tooltip of `height` fits between the window's top edge and `control`.
fn fits_above(control: Bounds<Pixels>, height: Pixels) -> bool {
    control.top() - GAP - height >= MARGIN
}

/// The accessible description a tooltip gives a control named `name`: none
/// when it only repeats the name.
pub(super) fn description(tooltip: Option<&SharedString>, name: &str) -> Option<SharedString> {
    tooltip.filter(|text| text.trim() != name.trim()).cloned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::size;

    #[test]
    fn a_tooltip_goes_below_a_control_at_the_top_of_the_window() {
        let line = px(32.);
        let title_bar_button = Bounds::new(point(px(800.), px(4.)), size(px(40.), px(24.)));
        assert!(!fits_above(title_bar_button, line));
        let page_button = Bounds::new(point(px(40.), px(200.)), size(px(120.), px(32.)));
        assert!(fits_above(page_button, line));
    }

    #[test]
    fn a_tooltip_that_repeats_the_name_adds_no_description() {
        let settings = SharedString::from("Settings");
        assert_eq!(description(Some(&settings), "Settings"), None);
        assert_eq!(description(None, "Settings"), None);
        let more = SharedString::from("Open Atlas settings (Ctrl+,)");
        assert_eq!(description(Some(&more), "Settings"), Some(more.clone()));
    }
}
