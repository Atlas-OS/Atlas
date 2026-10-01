//! The Fluent ToggleSwitch, for a setting that is simply on or off: its
//! state in words, then a 40x20 track whose knob slides to the end that's on.

use std::rc::Rc;

use gpui::{
    App, ClickEvent, ElementId, IntoElement, ParentElement, RenderOnce, Role, SharedString, Styled, Toggled,
    Window, div, prelude::*, px,
};

use super::typography::CapCenteredText;
use super::{ClickHandler, Revealed, Typography, focus_ring, on_activate};
use crate::t;
use crate::theme::ActiveTheme;

const TRACK_WIDTH: f32 = 40.;
const TRACK_HEIGHT: f32 = 20.;
const KNOB: f32 = 12.;
/// The knob grows under the pointer, as WinUI's does.
const KNOB_HOVER: f32 = 14.;

#[derive(IntoElement)]
pub struct ToggleSwitch {
    id: ElementId,
    /// The accessible name: the setting's header.
    label: SharedString,
    /// Read after the name: the setting's description beside it.
    description: Option<SharedString>,
    on: bool,
    disabled: bool,
    on_toggle: Option<ClickHandler>,
}

impl ToggleSwitch {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, on: bool) -> Self {
        Self { id: id.into(), label: label.into(), description: None, on, disabled: false, on_toggle: None }
    }

    /// What the setting does, as its card says under the header, so a
    /// screen reader on the switch hears it too.
    pub fn description(mut self, text: impl Into<SharedString>) -> Self {
        self.description = Some(text.into());
        self
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    pub fn on_toggle(mut self, handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static) -> Self {
        self.on_toggle = Some(Rc::new(handler));
        self
    }
}

/// Where the knob's left edge goes, for a knob of `size` in a track that is
/// `on` or off: 4px in from its end at rest, 3px when it has grown.
fn knob_left(on: bool, size: f32) -> f32 {
    let inset = (TRACK_HEIGHT - size) / 2.;
    if on { TRACK_WIDTH - inset - size } else { inset }
}

impl RenderOnce for ToggleSwitch {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let (on, disabled) = (self.on, self.disabled);
        let (focus_outer, focus_inner) = (theme.focus_outer, theme.focus_inner);
        let (track_fill, track_stroke, knob_fill) = match (on, disabled) {
            (true, false) => (theme.accent, theme.accent, theme.text_on_accent),
            (true, true) => (theme.accent_disabled, theme.accent_disabled, theme.text_on_accent_disabled),
            (false, false) => (theme.control_fill, theme.text_secondary, theme.text_secondary),
            (false, true) => (theme.control_fill_disabled, theme.text_disabled, theme.text_disabled),
        };
        let state = if on { t!("security-switch-on") } else { t!("security-switch-off") };
        let group: SharedString = format!("toggle-{:?}", self.id).into();
        let rest = (knob_left(on, KNOB), (TRACK_HEIGHT - KNOB) / 2.);
        let grown = (knob_left(on, KNOB_HOVER), (TRACK_HEIGHT - KNOB_HOVER) / 2.);
        let track = div()
            .relative()
            .flex_shrink_0()
            .w(px(TRACK_WIDTH))
            .h(px(TRACK_HEIGHT))
            .rounded_full()
            .bg(track_fill)
            .border_1()
            .border_color(track_stroke)
            .child(
                div()
                    .absolute()
                    // Inside the 1px border.
                    .left(px(rest.0 - 1.))
                    .top(px(rest.1 - 1.))
                    .size(px(KNOB))
                    .rounded_full()
                    .bg(knob_fill)
                    .when(!disabled, |this| {
                        this.group_hover(group.clone(), move |style| {
                            style.left(px(grown.0 - 1.)).top(px(grown.1 - 1.)).size(px(KNOB_HOVER))
                        })
                    }),
            );
        let row = div()
            .id(self.id)
            .group(group)
            .role(Role::Switch)
            .aria_label(self.label)
            .when_some(self.description, |this, text| this.aria_description(text))
            .aria_toggled(if on { Toggled::True } else { Toggled::False })
            .aria_disabled(disabled)
            .flex()
            .flex_shrink_0()
            .items_center()
            .gap(px(12.))
            .px(px(4.))
            .py(px(4.))
            .rounded(px(4.))
            .border_1()
            .border_color(theme.transparent())
            .type_body()
            .text_color(if disabled { theme.text_disabled } else { theme.text_primary })
            .child(div().min_w(px(24.)).child(CapCenteredText(state.into())))
            .child(track)
            .when(!disabled, |this| {
                this.tab_index(0)
                    .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                    .when_some(self.on_toggle, on_activate)
            });
        Revealed::new(row)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_knob_sits_four_pixels_in_from_the_end_that_is_on() {
        assert_eq!(knob_left(false, KNOB), 4.);
        assert_eq!(knob_left(true, KNOB), 24.);
        // Grown under the pointer, it keeps its end.
        assert_eq!(knob_left(false, KNOB_HOVER), 3.);
        assert_eq!(knob_left(true, KNOB_HOVER), 23.);
    }
}
