//! Fluent buttons: accent, standard, subtle and hyperlink.

use std::rc::Rc;

use gpui::{
    App, BoxShadow, ClickEvent, ElementId, IntoElement, ParentElement, RenderOnce, Role, SharedString,
    Styled, Window, div, point, prelude::*, px,
};

use super::icons::icon_in_line_sized;
use super::{BODY_LINE_HEIGHT, Icon, Typography, focus_ring, icon, icon_in_line};
use crate::t;
use crate::theme::ActiveTheme;

type ClickHandler = Rc<dyn Fn(&ClickEvent, &mut Window, &mut App)>;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum ButtonVariant {
    /// Filled with the accent colour. One per view, for the primary action.
    Accent,
    /// The everyday button.
    #[default]
    Standard,
    /// No fill until hovered. Toolbars and secondary actions.
    Subtle,
    /// Reads as a link. Opens something elsewhere.
    Hyperlink,
}

#[derive(IntoElement)]
pub struct Button {
    id: ElementId,
    label: SharedString,
    /// The accessible name when the label is empty (icon-only buttons) or
    /// needs more context than the visible text gives.
    aria_label: Option<SharedString>,
    variant: ButtonVariant,
    icon: Option<Icon>,
    trailing_icon: Option<Icon>,
    disabled: bool,
    compact: bool,
    centre_label: bool,
    opens_externally: bool,
    on_click: Option<ClickHandler>,
}

impl Button {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            aria_label: None,
            variant: ButtonVariant::Standard,
            icon: None,
            trailing_icon: None,
            disabled: false,
            compact: false,
            centre_label: false,
            opens_externally: false,
            on_click: None,
        }
    }

    pub fn accent(mut self) -> Self {
        self.variant = ButtonVariant::Accent;
        self
    }

    pub fn subtle(mut self) -> Self {
        self.variant = ButtonVariant::Subtle;
        self
    }

    pub fn hyperlink(mut self) -> Self {
        self.variant = ButtonVariant::Hyperlink;
        self
    }

    pub fn icon(mut self, icon: Icon) -> Self {
        self.icon = Some(icon);
        self
    }

    pub fn trailing_icon(mut self, icon: Icon) -> Self {
        self.trailing_icon = Some(icon);
        self
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    /// 24px tall, for use inside dense rows.
    pub fn compact(mut self) -> Self {
        self.compact = true;
        self
    }

    /// Centre visible capitals, matching adjacent badges and controls.
    pub fn centre_label(mut self) -> Self {
        self.centre_label = true;
        self
    }

    /// The name assistive technology announces. Required for icon-only buttons.
    pub fn aria_label(mut self, label: impl Into<SharedString>) -> Self {
        self.aria_label = Some(label.into());
        self
    }

    pub fn on_click(mut self, handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static) -> Self {
        self.on_click = Some(Rc::new(handler));
        self
    }

    /// Opens a URL or shell URI when clicked. Reported as a link.
    pub fn opens(mut self, target: impl Into<String>) -> Self {
        let target = target.into();
        self.opens_externally = true;
        self.on_click(move |_, _, cx| cx.open_url(&target))
    }
}

impl RenderOnce for Button {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let disabled = self.disabled;
        let variant = self.variant;
        let is_link = variant == ButtonVariant::Hyperlink;

        let (fill, fill_hover, fill_pressed, text, text_hover, text_pressed, stroke) = match variant {
            ButtonVariant::Accent => (
                theme.accent,
                theme.accent_hover,
                theme.accent_pressed,
                theme.text_on_accent,
                theme.text_on_accent,
                theme.text_on_accent,
                theme.control_stroke,
            ),
            ButtonVariant::Standard => (
                theme.control_fill,
                theme.control_fill_hover,
                theme.control_fill_pressed,
                theme.text_primary,
                theme.text_on_hover(theme.text_primary),
                theme.text_on_hover(theme.text_secondary),
                theme.control_stroke,
            ),
            ButtonVariant::Subtle => (
                theme.transparent(),
                theme.subtle_hover,
                theme.subtle_pressed,
                theme.text_primary,
                theme.text_on_hover(theme.text_primary),
                theme.text_on_hover(theme.text_secondary),
                theme.transparent(),
            ),
            ButtonVariant::Hyperlink => (
                theme.transparent(),
                theme.subtle_hover,
                theme.subtle_pressed,
                theme.accent_text,
                theme.text_on_hover(theme.accent_text_hover),
                theme.text_on_hover(theme.accent_text_hover),
                theme.transparent(),
            ),
        };

        let (fill, text) = if disabled {
            match variant {
                ButtonVariant::Accent => (theme.accent_disabled, theme.text_on_accent_disabled),
                ButtonVariant::Standard => (theme.control_fill_disabled, theme.text_disabled),
                _ => (theme.transparent(), theme.text_disabled),
            }
        } else {
            (fill, text)
        };

        // Win11 draws a slightly darker stroke on the bottom edge of raised
        // buttons; a 1px offset shadow reproduces it without a gradient border.
        let bottom_edge = match (variant, disabled, theme.high_contrast) {
            (ButtonVariant::Accent, false, false) => Some(gpui::black().opacity(0.14)),
            (ButtonVariant::Standard, false, false) => Some(theme.control_stroke_strong),
            _ => None,
        };
        let focus_outer = theme.focus_outer;
        let focus_inner = theme.focus_inner;

        let height = if self.compact { 24. } else { 32. };
        let icon_only = self.label.is_empty();
        let on_click = self.on_click.clone();
        let name = self.aria_label.clone().unwrap_or_else(|| self.label.clone());
        let description = disabled.then(|| t!("common-not-available"));

        div()
            .id(self.id)
            .role(if self.opens_externally { Role::Link } else { Role::Button })
            .aria_label(name)
            .when_some(description, |this, text| this.aria_description(text))
            .flex()
            .flex_shrink_0()
            .items_center()
            .justify_center()
            .gap(px(8.))
            .min_h(px(height))
            .px(px(if icon_only || self.compact { 8. } else { 12. }))
            .rounded(px(4.))
            .bg(fill)
            .border_1()
            .border_color(if disabled { theme.control_stroke } else { stroke })
            .text_color(text)
            .type_body()
            .when(is_link, |this| this.cursor_pointer())
            .when_some(bottom_edge, |this, colour| {
                this.shadow(vec![BoxShadow {
                    color: colour,
                    offset: point(px(0.), px(1.)),
                    blur_radius: px(0.),
                    spread_radius: px(0.),
                    inset: false,
                }])
            })
            .when(!disabled, |this| {
                this.tab_index(0)
                    .hover(move |style| style.bg(fill_hover).text_color(text_hover))
                    .active(move |style| style.bg(fill_pressed).text_color(text_pressed))
                    .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                    .when_some(on_click, |this, handler| {
                        // See selection.rs: the accessible Click must reach
                        // the handler even when the button is out of view.
                        let by_action = handler.clone();
                        this.on_click(move |event, window, cx| handler(event, window, cx))
                            .on_a11y_action(gpui::AccessibleAction::Click, move |_, window, cx| {
                                by_action(&ClickEvent::default(), window, cx)
                            })
                    })
            })
            .when_some(self.icon, |this, glyph| {
                this.child(if icon_only || self.centre_label {
                    icon(glyph)
                } else {
                    icon_in_line(glyph, BODY_LINE_HEIGHT)
                })
            })
            .when(!icon_only, |this| {
                this.child(div().whitespace_nowrap().child(if self.centre_label {
                    super::CapCenteredText(self.label).into_any_element()
                } else {
                    self.label.into_any_element()
                }))
            })
            .when_some(self.trailing_icon, |this, glyph| {
                this.child(if self.centre_label {
                    super::icon_sized(glyph, 12.).into_any_element()
                } else {
                    icon_in_line_sized(glyph, 12., BODY_LINE_HEIGHT).into_any_element()
                })
            })
    }
}
