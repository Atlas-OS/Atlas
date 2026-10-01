//! The window's own title bar: 32px tall, transparent over Mica, with the
//! Atlas mark, the window title, an optional settings button and native-sized
//! caption buttons (46x32) that hit-test as real caption controls so snap
//! layouts and double-click work.

use std::rc::Rc;

use gpui::{
    App, ClickEvent, IntoElement, ParentElement, RenderOnce, Role, SharedString, Styled, Window,
    WindowControlArea, div, prelude::*, px, svg,
};

use super::tooltip::{self, TooltipState};
use super::typography::{CAPTION_SIZE, cap_center_offset};
use super::{ClickHandler, Icon, Typography, focus_ring, icon_sized, on_activate, pointer_hover};
use crate::t;
use crate::theme::{ActiveTheme, FONT_ICONS, FONT_TEXT};

/// The title bar's height, which popups keep clear of.
pub const TITLE_BAR_HEIGHT: f32 = 32.;
/// The caption buttons' width: Minimize, Maximize and Close, 46px each.
pub const CAPTION_BUTTONS_WIDTH: f32 = 3. * 46.;

#[derive(IntoElement)]
pub struct TitleBar {
    title: SharedString,
    settings: Option<(bool, ClickHandler)>,
}

impl TitleBar {
    pub fn new(title: impl Into<SharedString>) -> Self {
        Self { title: title.into(), settings: None }
    }

    /// Adds a gear button beside the caption buttons. `active` marks it while
    /// the settings page is open.
    pub fn settings(
        mut self,
        active: bool,
        handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
    ) -> Self {
        self.settings = Some((active, Rc::new(handler)));
        self
    }
}

impl RenderOnce for TitleBar {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let tooltip = self
            .settings
            .is_some()
            .then(|| window.use_keyed_state("title-settings", cx, |_, cx| TooltipState::new(cx)));
        let theme = cx.theme().clone();
        let active = window.is_window_active();
        let text = if active { theme.text_primary } else { theme.text_disabled };
        let hover = theme.subtle_hover;
        let hover_text = theme.text_on_hover(text);
        let pressed = theme.subtle_pressed;
        let focus_outer = theme.focus_outer;
        let focus_inner = theme.focus_inner;
        div()
            .flex()
            .flex_shrink_0()
            .items_center()
            .w_full()
            .h(px(TITLE_BAR_HEIGHT))
            // Only the title region drags the window; the buttons stay clickable.
            .child(
                div()
                    .id("title-drag")
                    .flex()
                    .flex_1()
                    .h_full()
                    .items_center()
                    .gap(px(16.))
                    .pl(px(16.))
                    .window_control_area(WindowControlArea::Drag)
                    .child(
                        svg()
                            .path("brand/atlas-mark.svg")
                            .size(px(16.))
                            .text_color(theme.brand)
                            .with_transformation(gpui::Transformation::translate(gpui::point(
                                px(0.),
                                cap_center_offset(
                                    gpui::font(FONT_TEXT),
                                    CAPTION_SIZE.to_pixels(window.rem_size()),
                                    window,
                                    cx,
                                ),
                            ))),
                    )
                    .child(div().type_caption().text_color(text).child(self.title)),
            )
            .when_some(self.settings.zip(tooltip), |this, ((selected, handler), tooltip)| {
                let name: SharedString =
                    if selected { t!("common-close-settings") } else { t!("common-settings") }.into();
                let button = on_activate(
                    div()
                        .id("title-settings")
                        .role(Role::Button)
                        .aria_label(name.clone())
                        .flex()
                        .items_center()
                        .justify_center()
                        .w(px(40.))
                        .h(px(24.))
                        .mr(px(6.))
                        .rounded(px(4.))
                        .border_1()
                        .border_color(theme.transparent())
                        // Selected, it sits on the hover fill, so it takes that fill's text colour.
                        .text_color(if selected { theme.text_on_hover(theme.accent_text) } else { text })
                        .when(selected, |this| this.bg(hover))
                        .map(|this| {
                            pointer_hover(this, window, move |style| style.bg(hover).text_color(hover_text))
                        })
                        .active(move |style| style.bg(pressed))
                        .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                        .tab_index(0)
                        .child(icon_sized(Icon::Settings, 14.)),
                    handler,
                );
                this.child(tooltip::attach(button, name, &tooltip, window, cx))
            })
            .child(
                div()
                    .flex()
                    .h_full()
                    .font_family(FONT_ICONS)
                    .child(CaptionButton::Minimize)
                    .child(if window.is_maximized() {
                        CaptionButton::Restore
                    } else {
                        CaptionButton::Maximize
                    })
                    .child(CaptionButton::Close),
            )
    }
}

#[derive(IntoElement)]
enum CaptionButton {
    Minimize,
    Maximize,
    Restore,
    Close,
}

impl CaptionButton {
    fn area(&self) -> WindowControlArea {
        match self {
            CaptionButton::Minimize => WindowControlArea::Min,
            CaptionButton::Maximize | CaptionButton::Restore => WindowControlArea::Max,
            CaptionButton::Close => WindowControlArea::Close,
        }
    }

    fn icon(&self) -> Icon {
        match self {
            CaptionButton::Minimize => Icon::Minimize,
            CaptionButton::Maximize => Icon::Maximize,
            CaptionButton::Restore => Icon::Restore,
            CaptionButton::Close => Icon::Close,
        }
    }

    fn id(&self) -> &'static str {
        match self {
            CaptionButton::Minimize => "caption-minimize",
            CaptionButton::Maximize => "caption-maximize",
            CaptionButton::Restore => "caption-restore",
            CaptionButton::Close => "caption-close",
        }
    }
}

impl RenderOnce for CaptionButton {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let is_close = matches!(self, CaptionButton::Close);
        let enabled = match self {
            CaptionButton::Minimize => window.is_minimizable(),
            CaptionButton::Maximize | CaptionButton::Restore => window.is_resizable(),
            CaptionButton::Close => true,
        };
        let active = window.is_window_active();
        let (hover_bg, hover_fg, pressed_bg, pressed_fg) = if is_close {
            let (red, on_red) = (theme.caption_close_hover(), theme.caption_close_text());
            (red, on_red, red.opacity(0.9), on_red.opacity(0.7))
        } else {
            (
                theme.subtle_hover,
                theme.text_on_hover(theme.text_primary),
                theme.subtle_pressed,
                theme.text_on_hover(theme.text_secondary),
            )
        };
        let idle = if enabled && active { theme.text_primary } else { theme.text_disabled };
        // The caption buttons are native hit-test areas; Windows itself exposes
        // them through UI Automation as the window's title bar controls.
        div()
            .id(self.id())
            .flex()
            .items_center()
            .justify_center()
            .w(px(46.))
            .h_full()
            .text_color(idle)
            .window_control_area(self.area())
            .when(enabled, |this| {
                pointer_hover(this, window, move |style| style.bg(hover_bg).text_color(hover_fg))
                    .active(move |style| style.bg(pressed_bg).text_color(pressed_fg))
            })
            .child(icon_sized(self.icon(), 10.))
    }
}
