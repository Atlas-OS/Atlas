//! Fluent buttons: accent, standard, subtle and hyperlink.
//!
//! A hyperlink button inside [`OnTint`], as every InfoBar but an
//! informational one lays out its content, takes a darker link colour in the
//! light theme, so it keeps 4.5:1 on the tint.

use std::cell::Cell;
use std::rc::Rc;

use gpui::{
    AnyElement, App, Bounds, BoxShadow, ClickEvent, Div, Element, ElementId, FocusHandle, GlobalElementId,
    Hsla, InspectorElementId, IntoElement, LayoutId, ParentElement, Pixels, RenderOnce, Role, SharedString,
    Styled, Window, div, point, prelude::*, px,
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

/// The padding either side of a compact or icon-only button's content.
const COMPACT_PADDING: f32 = 8.;
/// The padding either side of a standard button's label.
const PADDING: f32 = 12.;

/// How far a compact or icon-only button's content sits inside its box: its
/// padding and its 1px border. A [`link_row`] moves it into the margin.
pub const COMPACT_INSET: Pixels = px(COMPACT_PADDING + 1.);

/// A row of compact hyperlink buttons that starts a line of a text column,
/// such as Show details under a message or a row of help links. As a radio
/// group's glyphs do, each line's first link has its text on the column's
/// edge, while its hover fill and focus ring reach into the gutter. The row
/// wraps, and a wrapped line starts on the edge too. A link after text on the
/// same line, such as "9 checks passed · Show details", isn't in one, and
/// keeps its padding before its text.
pub fn link_row() -> Div {
    div().flex().flex_wrap().items_center().gap(px(4.)).ml(-COMPACT_INSET)
}

thread_local! {
    /// Set while an [`OnTint`] lays out its content, when buttons render.
    static ON_TINT: Cell<bool> = const { Cell::new(false) };
}

/// Lays out its content as sitting on a tinted surface, such as a success,
/// warning or error InfoBar's fill, so the hyperlink buttons in it take
/// [`link_on_tint`]. Transparent to layout: it takes its content's own
/// layout node.
pub(super) struct OnTint {
    child: AnyElement,
}

impl OnTint {
    pub(super) fn new(child: impl IntoElement) -> Self {
        Self { child: child.into_any_element() }
    }
}

impl Element for OnTint {
    type RequestLayoutState = ();
    type PrepaintState = ();

    fn id(&self) -> Option<ElementId> {
        None
    }

    fn source_location(&self) -> Option<&'static core::panic::Location<'static>> {
        None
    }

    fn request_layout(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (LayoutId, Self::RequestLayoutState) {
        // Components render as they lay out, and a button picks its colours then.
        let outer = ON_TINT.replace(true);
        let layout = self.child.request_layout(window, cx);
        ON_TINT.set(outer);
        (layout, ())
    }

    fn prepaint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        _bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        window: &mut Window,
        cx: &mut App,
    ) -> Self::PrepaintState {
        self.child.prepaint(window, cx);
    }

    fn paint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        _bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        _prepaint: &mut Self::PrepaintState,
        window: &mut Window,
        cx: &mut App,
    ) {
        self.child.paint(window, cx);
    }
}

/// A link's colour on a tinted surface. The light tints are darker than a
/// card, where the usual light link colour has barely 4.5:1, so links on
/// them take the shade WinUI gives accent text (AccentDark2), which keeps
/// more than 5:1 on each. Dark tints and contrast themes keep the usual link
/// colour, which already clears 4.5:1 there.
fn link_on_tint(theme: &Theme) -> Hsla {
    if theme.high_contrast || theme.is_dark() {
        theme.accent_text
    } else {
        gpui::rgb(crate::theme::ATLAS_BLUE_DARK2).into()
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

fn colours(theme: &Theme, variant: ButtonVariant, disabled: bool, on_tint: bool) -> Colours {
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
            text: if on_tint { link_on_tint(theme) } else { theme.accent_text },
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
            colours(theme, variant, disabled, ON_TINT.get());

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
            .px(px(if icon_only || self.compact { COMPACT_PADDING } else { PADDING }))
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
                // As in Windows, the ring shows only once the keyboard is in use;
                // a page's emphasis is its accent button.
                this.focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                    .when_some(on_click, on_activate)
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
    use crate::theme::{composite, contrast_ratio, windows_contrast_themes};

    const VARIANTS: [ButtonVariant; 4] =
        [ButtonVariant::Accent, ButtonVariant::Standard, ButtonVariant::Subtle, ButtonVariant::Hyperlink];

    #[test]
    fn disabling_a_button_never_changes_its_outline() {
        for theme in [Theme::light(), Theme::dark()] {
            for variant in VARIANTS {
                let (enabled, disabled) =
                    (colours(&theme, variant, false, false), colours(&theme, variant, true, false));
                assert_eq!(enabled.stroke, disabled.stroke, "{:?} {variant:?}", theme.appearance);
            }
        }
    }

    /// Links in a success, warning or error InfoBar, at rest, hovered and
    /// pressed, on the bar's tint.
    #[test]
    fn links_keep_readable_text_on_every_infobar_tint() {
        for theme in [Theme::light(), Theme::dark()] {
            let link = colours(&theme, ButtonVariant::Hyperlink, false, true);
            for (tint, fill) in [
                ("success", theme.success_fill),
                ("warning", theme.caution_fill),
                ("error", theme.critical_fill),
            ] {
                let bar = composite(fill, theme.solid_background);
                for (state, text, over) in [
                    ("at rest", link.text, link.fill),
                    ("hovered", link.text_hover, link.fill_hover),
                    ("pressed", link.text_pressed, link.fill_pressed),
                ] {
                    let ratio = contrast_ratio(text, over, bar);
                    assert!(ratio >= 4.5, "{:?} {tint} {state}: {ratio:.2}:1", theme.appearance);
                }
            }
        }
    }

    /// The colours a button actually draws with. Contrast themes keep gray
    /// text readable, so a disabled label must stay readable there too.
    #[test]
    fn contrast_themes_keep_every_button_label_readable() {
        for (name, colors) in windows_contrast_themes() {
            let theme = Theme::high_contrast(colors);
            // What a transparent fill shows.
            let window = theme.solid_background;
            for (variant, on_tint) in
                VARIANTS.into_iter().flat_map(|variant| [(variant, false), (variant, true)])
            {
                let (enabled, disabled) =
                    (colours(&theme, variant, false, on_tint), colours(&theme, variant, true, on_tint));
                for (state, text, fill) in [
                    ("at rest", enabled.text, enabled.fill),
                    ("hovered", enabled.text_hover, enabled.fill_hover),
                    ("pressed", enabled.text_pressed, enabled.fill_pressed),
                    ("disabled", disabled.text, disabled.fill),
                ] {
                    let ratio = contrast_ratio(text, fill, window);
                    assert!(ratio >= 4.5, "{name} {variant:?} {state}: {ratio:.2}:1 is below 4.5:1");
                }
            }
        }
    }
}
