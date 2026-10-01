//! The command bar pinned under a multi-step page: an optional command on the
//! leading side, then a hint, Back and the primary button on the trailing side.
//!
//! The hint sits right before the buttons it explains. It wraps to at most two
//! lines there; when even that doesn't fit, it moves above the buttons as a
//! caption, where it wraps as far as it needs. It is never cut short.

use gpui::{
    AnyElement, App, ClickEvent, ElementId, IntoElement, ParentElement, Pixels, Refineable, RenderOnce,
    SharedString, Styled, Window, div, px,
};

use crate::theme::ActiveTheme;
use crate::ui::{Button, Typography, a11y_text};

#[derive(IntoElement, Default)]
pub struct CommandBar {
    leading: Option<AnyElement>,
    hint: SharedString,
    back: Option<AnyElement>,
    primary: Option<AnyElement>,
}

impl CommandBar {
    pub fn new() -> Self {
        Self::default()
    }

    /// The flow's Cancel on the leading side: always a standard button, so
    /// it looks the same on every page that has one.
    pub fn cancel(
        mut self,
        id: impl Into<ElementId>,
        label: impl Into<SharedString>,
        disabled: bool,
        on_click: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
    ) -> Self {
        self.leading = Some(Button::new(id, label).disabled(disabled).on_click(on_click).into_any_element());
        self
    }

    /// Why the primary button is unavailable, or what to know before choosing
    /// it. Nothing is drawn for an empty hint.
    pub fn hint(mut self, hint: impl Into<SharedString>) -> Self {
        self.hint = hint.into();
        self
    }

    pub fn back(mut self, button: impl IntoElement) -> Self {
        self.back = Some(button.into_any_element());
        self
    }

    pub fn primary(mut self, button: impl IntoElement) -> Self {
        self.primary = Some(button.into_any_element());
        self
    }
}

impl RenderOnce for CommandBar {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        // Back and the primary button sit at the bottom of their line, level
        // with the leading command, beside a hint of any height.
        let buttons = div()
            .flex()
            .flex_shrink_0()
            .self_end()
            .items_center()
            .gap(px(8.))
            .children(self.back)
            .children(self.primary);
        let hint = (!self.hint.is_empty()).then(|| {
            let (one_line, two_lines) = hint_widths(&self.hint, window);
            // Laid out at its two-line width, so it stays beside the buttons
            // only while two lines are enough, and grows to one line when there
            // is room.
            div()
                .flex_grow_1()
                .flex_basis(two_lines)
                .max_w(one_line)
                .min_w_0()
                .type_caption()
                .text_color(cx.theme().text_secondary)
                .child(a11y_text("footer-hint", self.hint))
        });
        div().flex().items_end().gap(px(12.)).children(self.leading).child(
            // A hint that doesn't fit beside the buttons keeps the first line
            // to itself, so it sits above them, and is still read before them.
            div()
                .flex_1()
                .min_w_0()
                .flex()
                .flex_wrap()
                .justify_end()
                .items_center()
                .gap_x(px(12.))
                .gap_y(px(8.))
                .children(hint)
                .child(buttons),
        )
    }
}

/// The hint's width on one line, and the narrowest width that keeps it to two
/// lines, both measured the way the caption wraps. Each has a pixel to spare,
/// as layout snaps edges to whole device pixels.
fn hint_widths(text: &SharedString, window: &Window) -> (Pixels, Pixels) {
    let mut caption = div().type_caption();
    let mut style = window.text_style();
    style.refine(caption.text_style());
    let size = style.font_size.to_pixels(window.rem_size());
    let runs = [style.to_run(text.len())];
    let shape =
        |width: Option<Pixels>| window.text_system().shape_text(text.clone(), size, &runs, width, None);
    let one_line = shape(None)
        .map(|lines| lines.iter().map(|line| line.width()).fold(px(0.), Pixels::max).ceil())
        .unwrap_or_default();
    let lines = |width: Pixels| {
        shape(Some(width))
            .map(|lines| lines.iter().map(|line| line.wrap_boundaries().len() + 1).sum::<usize>())
            .unwrap_or(usize::MAX)
    };
    (one_line + px(1.), narrowest(one_line, |width| lines(width) <= 2) + px(1.))
}

/// The narrowest whole-pixel width up to `widest` at which `fits` holds, given
/// that it holds at `widest` and keeps holding as the width grows.
fn narrowest(widest: Pixels, fits: impl Fn(Pixels) -> bool) -> Pixels {
    let (mut low, mut high) = (px(0.), widest);
    while high - low > px(1.) {
        let middle = ((low + high) / 2.).floor();
        if fits(middle) {
            high = middle;
        } else {
            low = middle;
        }
    }
    high
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_narrowest_width_is_the_first_that_fits() {
        // Words of 30px, two to a line from 60px: three words need two lines
        // from 60px up and fit on one from 90px.
        let lines = |width: Pixels| {
            if width >= px(90.) {
                1
            } else if width >= px(60.) {
                2
            } else {
                3
            }
        };
        assert_eq!(narrowest(px(90.), |width| lines(width) <= 2), px(60.));
        assert_eq!(narrowest(px(90.), |width| lines(width) <= 1), px(90.));
        // A hint already on one line at its full width stays there.
        assert_eq!(narrowest(px(1.), |_| true), px(1.));
    }
}
