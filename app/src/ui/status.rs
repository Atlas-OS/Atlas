//! The status light: a small filled circle whose colour is the state, with a
//! word beside it so colour is never the only signal.

use gpui::{
    App, ElementId, Hsla, IntoElement, Live, ParentElement, RenderOnce, Role, SharedString, Styled, Window,
    div, prelude::*, px,
};

use super::{Icon, ProgressRing, Typography, icon_sized};
use crate::theme::{ActiveTheme, Theme};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LightState {
    /// The desired state: green.
    Good,
    /// Needs the user's attention: red.
    Bad,
    /// Not ideal, but the flow can continue: amber.
    Caution,
    /// Could not be determined: grey.
    Unknown,
    /// Still being read.
    Pending,
}

#[derive(IntoElement)]
pub struct StatusLight {
    id: Option<ElementId>,
    state: LightState,
    label: SharedString,
    /// The accessible name, when the label alone lacks its context.
    name: Option<SharedString>,
    live: bool,
    check_mark: bool,
}

impl StatusLight {
    pub fn new(state: LightState, label: impl Into<SharedString>) -> Self {
        Self { id: None, state, label: label.into(), name: None, live: false, check_mark: false }
    }

    /// The name assistive technology reads instead of the label, such as
    /// "Installation files: Ready" for a pill that shows only "Ready". It
    /// should start with what the label says.
    pub fn aria_label(mut self, name: impl Into<SharedString>) -> Self {
        self.name = Some(name.into());
        self
    }

    /// Announces the status when it changes. Needs an [`id`](Self::id).
    pub fn live(mut self) -> Self {
        self.live = true;
        self
    }

    /// A check mark instead of the dot: a task done rather than a state that
    /// is good, such as a protection switch turned off for installing.
    pub fn check_mark(mut self) -> Self {
        self.check_mark = true;
        self
    }

    /// With an id the light is reported to assistive technology as a status
    /// node; without one, the surrounding row is expected to carry the text.
    pub fn id(mut self, id: impl Into<ElementId>) -> Self {
        self.id = Some(id.into());
        self
    }
}

/// The dot, label and pill colours for a state. Light pills for a verdict use
/// the opaque WinUI status fills, which keep the coloured label readable
/// wherever the pill sits; a tint of the state colour would not.
fn pill_colours(theme: &Theme, state: LightState) -> (Hsla, Hsla, Hsla) {
    let (colour, text) = match state {
        LightState::Good => (theme.success, theme.success),
        LightState::Bad => (theme.critical, theme.critical),
        LightState::Caution => (theme.caution, theme.caution),
        LightState::Unknown => (theme.text_tertiary, theme.text_secondary),
        LightState::Pending => (theme.accent, theme.text_secondary),
    };
    let fill = if theme.high_contrast {
        theme.transparent()
    } else if theme.is_dark() {
        colour.opacity(0.14)
    } else {
        match state {
            LightState::Good => theme.success_fill,
            LightState::Bad => theme.critical_fill,
            LightState::Caution => theme.caution_fill,
            LightState::Unknown | LightState::Pending => colour.opacity(0.10),
        }
    };
    (colour, text, fill)
}

impl RenderOnce for StatusLight {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let (colour, text, fill) = pill_colours(theme, self.state);
        let body = div()
            .flex()
            .flex_shrink_0()
            .items_center()
            .gap(px(8.))
            .min_h(px(20.))
            .py(px(2.))
            .px(px(10.))
            .rounded_full()
            .bg(fill)
            .when(theme.high_contrast, |this| this.border_1().border_color(theme.text_primary))
            .child(match self.state {
                LightState::Pending => ProgressRing::new().size(12.).into_any_element(),
                _ if self.check_mark => {
                    icon_sized(Icon::CheckMark, 12.).text_color(colour).into_any_element()
                }
                _ => gpui::svg()
                    .path("icons/status-dot.svg")
                    .size(px(8.))
                    .text_color(colour)
                    .into_any_element(),
            })
            .child(
                div()
                    .type_caption()
                    .font_weight(gpui::FontWeight::SEMIBOLD)
                    .text_color(text)
                    .child(super::typography::CapCenteredText(self.label.clone())),
            );
        match self.id {
            Some(id) => div()
                .id(id)
                .role(Role::Status)
                .aria_label(self.name.unwrap_or(self.label))
                .when(self.live, |this| this.aria_live(Live::Polite))
                .flex_shrink_0()
                .child(body)
                .into_any_element(),
            None => body.into_any_element(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::theme::{composite, contrast_ratio};

    #[test]
    fn every_status_label_is_readable_on_its_pill() {
        let states = [
            LightState::Good,
            LightState::Bad,
            LightState::Caution,
            LightState::Unknown,
            LightState::Pending,
        ];
        for theme in [Theme::light(), Theme::dark()] {
            // The pill sits on the page layer or inside a card.
            let layer = composite(theme.layer_fill, theme.solid_background);
            let card = composite(theme.card_fill, layer);
            for state in states {
                let (_, text, fill) = pill_colours(&theme, state);
                for (surface, backdrop) in [("layer", layer), ("card", card)] {
                    let ratio = contrast_ratio(text, fill, backdrop);
                    assert!(
                        ratio >= 4.5,
                        "{:?} {state:?} on a {surface}: {ratio:.2}:1 is below 4.5:1",
                        theme.appearance
                    );
                }
            }
        }
    }
}
