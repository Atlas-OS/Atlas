//! Progress indicators: the 3px bar (determinate and indeterminate) and a
//! small spinning ring for rows that are still checking. When Windows
//! animations are off, both hold still.

use std::time::Duration;

use gpui::{
    Animation, AnimationExt, App, ElementId, IntoElement, ParentElement, RenderOnce, Role, SharedString,
    Styled, Transformation, Window, div, ease_in_out, percentage, prelude::*, px, relative, svg,
};

use crate::theme::ActiveTheme;

#[derive(IntoElement)]
pub struct ProgressBar {
    id: ElementId,
    label: SharedString,
    /// `None` animates an indeterminate sweep.
    value: Option<f32>,
}

impl ProgressBar {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, value: Option<f32>) -> Self {
        Self { id: id.into(), label: label.into(), value: value.map(|v| v.clamp(0., 1.)) }
    }
}

impl RenderOnce for ProgressBar {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let track = div()
            .id(self.id)
            .role(Role::ProgressIndicator)
            .aria_label(self.label)
            .when_some(self.value, |this, value| {
                this.aria_numeric_value((value * 100.).round() as f64)
                    .aria_min_numeric_value(0.)
                    .aria_max_numeric_value(100.)
            })
            .relative()
            .w_full()
            .h(px(3.))
            .rounded(px(1.5))
            .bg(theme.control_strong_stroke.opacity(0.35))
            .overflow_hidden();
        let accent = theme.accent;

        match self.value {
            Some(value) => track.child(
                div().absolute().left_0().top_0().h_full().rounded(px(1.5)).bg(accent).w(relative(value)),
            ),
            None if theme.reduce_motion => track.child(
                div().absolute().left_0().top_0().h_full().rounded(px(1.5)).bg(accent).w(relative(0.5)),
            ),
            None => track.child(
                div()
                    .absolute()
                    .top_0()
                    .h_full()
                    .w(relative(0.33))
                    .rounded(px(1.5))
                    .bg(accent)
                    .with_animation(
                        "progress-sweep",
                        Animation::new(Duration::from_millis(1600)).repeat().with_easing(ease_in_out),
                        |this, delta| this.left(relative(-0.33 + delta * 1.33)),
                    ),
            ),
        }
    }
}

/// A 16px spinning ring in the accent colour. Decorative: the row it sits in
/// says "Checking" in words.
#[derive(IntoElement)]
pub struct ProgressRing {
    size: f32,
}

impl ProgressRing {
    pub fn new() -> Self {
        Self { size: 16. }
    }

    pub fn size(mut self, size: f32) -> Self {
        self.size = size;
        self
    }
}

impl Default for ProgressRing {
    fn default() -> Self {
        Self::new()
    }
}

impl RenderOnce for ProgressRing {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let accent = theme.accent;
        let ring = svg().path("icons/ring.svg").size(px(self.size)).text_color(accent);
        div().flex().items_center().justify_center().size(px(self.size)).child(if theme.reduce_motion {
            ring.into_any_element()
        } else {
            ring.with_animation(
                "progress-ring",
                Animation::new(Duration::from_millis(1100)).repeat(),
                |this, delta| this.with_transformation(Transformation::rotate(percentage(delta))),
            )
            .into_any_element()
        })
    }
}
