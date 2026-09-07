//! The status light: a small filled circle whose colour is the state, with a
//! word beside it so colour is never the only signal.

use gpui::{
    App, ElementId, IntoElement, ParentElement, RenderOnce, Role, SharedString, Styled, Window, div,
    prelude::*, px,
};

use super::{ProgressRing, Typography};
use crate::theme::ActiveTheme;

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
}

impl StatusLight {
    pub fn new(state: LightState, label: impl Into<SharedString>) -> Self {
        Self { id: None, state, label: label.into() }
    }

    /// With an id the light is reported to assistive technology as a status
    /// node; without one, the surrounding row is expected to carry the text.
    pub fn id(mut self, id: impl Into<ElementId>) -> Self {
        self.id = Some(id.into());
        self
    }
}

impl RenderOnce for StatusLight {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let (colour, text) = match self.state {
            LightState::Good => (theme.success, theme.success),
            LightState::Bad => (theme.critical, theme.critical),
            LightState::Caution => (theme.caution, theme.caution),
            LightState::Unknown => (theme.text_tertiary, theme.text_secondary),
            LightState::Pending => (theme.accent, theme.text_secondary),
        };
        let fill = if theme.high_contrast {
            theme.transparent()
        } else {
            colour.opacity(if theme.is_dark() { 0.14 } else { 0.10 })
        };
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
                .aria_label(self.label)
                .flex_shrink_0()
                .child(body)
                .into_any_element(),
            None => body.into_any_element(),
        }
    }
}
