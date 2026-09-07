//! Surfaces: the Fluent card.

use crate::theme::ActiveTheme;
use gpui::{App, Div, Styled, div, px};

/// A Fluent card: 8px corners, 1px stroke, translucent fill over Mica.
pub fn card(cx: &App) -> Div {
    let theme = cx.theme();
    div()
        .flex()
        .flex_col()
        .rounded(px(8.))
        .bg(theme.card_fill)
        .border_1()
        .border_color(theme.card_stroke)
        .overflow_hidden()
}
