//! Fluent buttons: accent, standard, subtle and hyperlink.

use std::rc::Rc;

use gpui::{
    App, BoxShadow, ClickEvent, ElementId, FocusHandle, Hsla, IntoElement, ParentElement, RenderOnce, Role,
    SharedString, Styled, Window, div, point, prelude::*, px,
};

use super::icons::icon_in_line_sized;
use super::tooltip::{self, TooltipState};
use super::{
    BODY_LINE_HEIGHT, ClickHandler, Icon, Revealed, Typography, focus_ring, icon, icon_in_line, on_activate,
    pointer_hover,
};
use crate::theme::{ActiveTheme, Theme};

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
    tooltip: Option<SharedString>,
    /// Read after the name, such as why a disabled button can't be used yet.
    description: Option<SharedString>,
    /// A disclosure's state: whether what it shows is open.
    expanded: Option<bool>,
    /// The page's programmatic default, which shows its focus ring whenever
    /// it has focus.
    keyboard_default: bool,
    variant: ButtonVariant,
    icon: Option<Icon>,
    trailing_icon: Option<Icon>,
    disabled: bool,
    compact: bool,
    centre_label: bool,
    opens_externally: bool,
    on_click: Option<ClickHandler>,
    focus: Option<FocusHandle>,
}

impl Button {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            aria_label: None,
            tooltip: None,
            description: None,
            expanded: None,
            keyboard_default: false,
            variant: ButtonVariant::Standard,
            icon: None,
            trailing_icon: None,
            disabled: false,
            compact: false,
            centre_label: false,
            opens_externally: false,
            on_click: None,
            focus: None,
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

    /// A Fluent tooltip, shown on hover and on keyboard focus. Give every
    /// icon-only button one, usually its accessible name. Text that adds to
    /// the name is also the button's accessible description.
    pub fn tooltip(mut self, text: impl Into<SharedString>) -> Self {
        self.tooltip = Some(text.into());
        self
    }

    /// What assistive technology reads after the name: for a disabled
    /// button, what it waits for. A tooltip that adds to the name comes first.
    pub fn aria_description(mut self, text: impl Into<SharedString>) -> Self {
        self.description = Some(text.into());
        self
    }

    /// A Show details or Hide details toggle: whether what it opens is shown.
    /// Narrator reads "collapsed" or "expanded", and the change when pressed.
    pub fn expanded(mut self, expanded: bool) -> Self {
        self.expanded = Some(expanded);
        self
    }

    /// The page's programmatic default. Shows the focus ring whenever
    /// focused, like a Windows default button, not only after a key press.
    pub fn keyboard_default(mut self) -> Self {
        self.keyboard_default = true;
        self
    }

    pub fn on_click(mut self, handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static) -> Self {
        self.on_click = Some(Rc::new(handler));
        self
    }

    /// Lets the page move keyboard focus to the button, to make it the
    /// keyboard's default. A button with a tooltip takes focus through the
    /// tooltip's own handle, so the two don't combine.
    pub fn focus_handle(mut self, handle: FocusHandle) -> Self {
        self.focus = Some(handle);
        self
    }

    /// Opens a URL or shell URI when clicked. Reported as a link.
    pub fn opens(mut self, target: impl Into<String>) -> Self {
        let target = target.into();
        self.opens_externally = true;
        self.on_click(move |_, _, cx| cx.open_url(&target))
    }
}

/// A button's colours at rest, hovered and pressed, and its outline.
struct Colours {
    fill: Hsla,
    fill_hover: Hsla,
    fill_pressed: Hsla,
    text: Hsla,
    text_hover: Hsla,
    text_pressed: Hsla,
    stroke: Hsla,
}

fn colours(theme: &Theme, variant: ButtonVariant, disabled: bool) -> Colours {
    let mut colours = match variant {
        ButtonVariant::Accent => Colours {
            fill: theme.accent,
            fill_hover: theme.accent_hover,
            fill_pressed: theme.accent_pressed,
            text: theme.text_on_accent,
            text_hover: theme.text_on_accent,
            text_pressed: theme.text_on_accent,
            stroke: theme.control_stroke,
        },
        ButtonVariant::Standard => Colours {
            fill: theme.control_fill,
            fill_hover: theme.control_fill_hover,
            fill_pressed: theme.control_fill_pressed,
            text: theme.text_primary,
            text_hover: theme.text_on_hover(theme.text_primary),
            text_pressed: theme.text_on_hover(theme.text_secondary),
            stroke: theme.control_stroke,
        },
        ButtonVariant::Subtle => Colours {
            fill: theme.transparent(),
            fill_hover: theme.subtle_hover,
            fill_pressed: theme.subtle_pressed,
            text: theme.text_primary,
            text_hover: theme.text_on_hover(theme.text_primary),
            text_pressed: theme.text_on_hover(theme.text_secondary),
            stroke: theme.transparent(),
        },
        ButtonVariant::Hyperlink => Colours {
            fill: theme.transparent(),
            fill_hover: theme.subtle_hover,
            fill_pressed: theme.subtle_pressed,
            text: theme.accent_text,
            text_hover: theme.text_on_hover(theme.accent_text_hover),
            text_pressed: theme.text_on_hover(theme.accent_text_hover),
            stroke: theme.transparent(),
        },
    };
    if disabled {
        (colours.fill, colours.text) = match variant {
            ButtonVariant::Accent => (theme.accent_disabled, theme.text_on_accent_disabled),
            ButtonVariant::Standard => (theme.control_fill_disabled, theme.text_disabled),
            ButtonVariant::Subtle | ButtonVariant::Hyperlink => (theme.transparent(), theme.text_disabled),
        };
    }
    colours
}

impl RenderOnce for Button {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        // A disabled button can't take focus or hover, so it shows no tooltip.
        let tooltip = self.tooltip.clone().filter(|_| !self.disabled).map(|text| {
            let state = window.use_keyed_state(self.id.clone(), cx, |_, cx| TooltipState::new(cx));
            (text, state)
        });
        let theme = cx.theme();
        let disabled = self.disabled;
        let variant = self.variant;
        let is_link = variant == ButtonVariant::Hyperlink;
        let Colours { fill, fill_hover, fill_pressed, text, text_hover, text_pressed, stroke } =
            colours(theme, variant, disabled);

        // Win11 draws a slightly darker stroke on the bottom edge of raised
        // buttons; a 1px offset shadow reproduces it without a gradient border.
        let bottom_edge = match (variant, disabled, theme.high_contrast) {
            (ButtonVariant::Accent, false, false) => Some(theme.control_stroke_on_accent_secondary),
            (ButtonVariant::Standard, false, false) => Some(theme.control_stroke_secondary),
            _ => None,
        };
        let focus_outer = theme.focus_outer;
        let focus_inner = theme.focus_inner;

        let height = if self.compact { 24. } else { 32. };
        let icon_only = self.label.is_empty();
        let on_click = self.on_click.clone();
        debug_assert!(self.focus.is_none() || self.tooltip.is_none(), "a button takes one focus handle");
        let focus = self.focus.clone();
        let name = self.aria_label.clone().unwrap_or_else(|| self.label.clone());
        let description = super::compose_description(&[
            tooltip::description(self.tooltip.as_ref(), &name).filter(|_| !disabled),
            self.description.clone(),
        ]);
        let keyboard_default = self.keyboard_default;

        let button = div()
            .id(self.id)
            .role(if self.opens_externally { Role::Link } else { Role::Button })
            .aria_label(name)
            .when_some(description, |this, text| this.aria_description(text))
            .when_some(self.expanded, |this, expanded| this.aria_expanded(expanded))
            .aria_disabled(disabled)
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
            .border_color(stroke)
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
                let this = match focus {
                    Some(handle) => this.track_focus(&handle.tab_index(0).tab_stop(true)),
                    None => this.tab_index(0),
                };
                let this =
                    pointer_hover(this, window, move |style| style.bg(fill_hover).text_color(text_hover))
                        .active(move |style| style.bg(fill_pressed).text_color(text_pressed));
                let this = if keyboard_default {
                    this.focus(move |style| focus_ring(style, focus_outer, focus_inner))
                } else {
                    this.focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                };
                this.when_some(on_click, on_activate)
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
            });
        let button = match tooltip {
            Some((text, state)) => tooltip::attach(button, text, &state, window, cx),
            None => button,
        };
        Revealed::new(button)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disabling_a_button_never_changes_its_outline() {
        for theme in [Theme::light(), Theme::dark()] {
            for variant in [
                ButtonVariant::Accent,
                ButtonVariant::Standard,
                ButtonVariant::Subtle,
                ButtonVariant::Hyperlink,
            ] {
                let (enabled, disabled) = (colours(&theme, variant, false), colours(&theme, variant, true));
                assert_eq!(enabled.stroke, disabled.stroke, "{:?} {variant:?}", theme.appearance);
            }
        }
    }
}
