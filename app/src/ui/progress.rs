//! Progress indicators: the 3px bar (determinate and indeterminate) and a
//! small spinning ring for rows that are still checking. When Windows
//! animations are off, both hold still.

use std::time::Duration;

use gpui::{
    Animation, AnimationExt, App, ElementId, IntoElement, Live, ParentElement, RenderOnce, Role,
    SharedString, Styled, Transformation, Window, div, ease_in_out, percentage, prelude::*, px, relative,
    svg,
};

use crate::theme::ActiveTheme;

const BAR_HEIGHT: f32 = 3.;
/// The indeterminate segment's share of the track.
const SEGMENT: f32 = 0.33;

#[derive(IntoElement)]
pub struct ProgressBar {
    id: ElementId,
    label: SharedString,
    /// `None` animates an indeterminate sweep.
    value: Option<f32>,
    decorative: bool,
    live: bool,
}

impl ProgressBar {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, value: Option<f32>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            value: value.map(|v| v.clamp(0., 1.)),
            decorative: false,
            live: false,
        }
    }

    /// Drawn only, with no progress node of its own, for a bar whose words
    /// beside it say everything: the restart countdown's sentence and its
    /// buttons' group name give the seconds, so the bar's elapsed fraction
    /// would only contradict them.
    pub fn decorative(mut self) -> Self {
        self.decorative = true;
        self
    }

    /// Announces its name when it changes, as the one live node of a task
    /// in progress: name it after the stage or step, not the percentage.
    pub fn live(mut self) -> Self {
        self.live = true;
        self
    }
}

impl RenderOnce for ProgressBar {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let exposed = !self.decorative;
        let track = div()
            .id(self.id)
            .when(exposed, |this| {
                this.role(Role::ProgressIndicator)
                    .aria_label(self.label)
                    .when(self.live, |this| this.aria_live(Live::Polite))
                    .when_some(self.value, |this, value| {
                        this.aria_numeric_value((value * 100.).round() as f64)
                            .aria_min_numeric_value(0.)
                            .aria_max_numeric_value(100.)
                    })
            })
            .relative()
            .w_full()
            .h(px(BAR_HEIGHT))
            .rounded(px(BAR_HEIGHT / 2.))
            .bg(theme.control_strong_stroke.opacity(0.35))
            .overflow_hidden();
        let accent = theme.accent;
        let bar = || div().absolute().top_0().h_full().rounded(px(BAR_HEIGHT / 2.)).bg(accent);

        match self.value {
            Some(value) => track.child(bar().left_0().w(relative(value))),
            // A paused frame of the sweep: a segment clear of the left edge
            // never reads as a fraction done.
            None if theme.reduce_motion => track.child(bar().left(relative(SEGMENT)).w(relative(SEGMENT))),
            // The segment enters from the left and leaves at the right.
            None => track.child(
                bar().w(relative(SEGMENT)).with_animation(
                    "progress-sweep",
                    Animation::new(Duration::from_millis(1600))
                        .repeat()
                        .with_easing(ease_in_out)
                        .with_max_fps(60.),
                    |this, delta| this.left(relative(-SEGMENT + delta * (1. + SEGMENT))),
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
                Animation::new(Duration::from_millis(1100)).repeat().with_max_fps(60.),
                |this, delta| this.with_transformation(Transformation::rotate(percentage(delta))),
            )
            .into_any_element()
        })
    }
}
