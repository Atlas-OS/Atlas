//! The row of steps above a multi-step flow: which step is showing, which are
//! done, which need attention and which come next. Visited steps can be chosen
//! to go back to them.

use std::cmp::Ordering;
use std::rc::Rc;

use gpui::{
    AnyElement, App, Div, ElementId, IntoElement, ParentElement, RenderOnce, Role, SharedString, Styled,
    Window, div, prelude::*, px,
};

use crate::i18n::fmt;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    BODY_LINE_HEIGHT, Icon, Revealed, Typography, body_cap_center_offset, centred_step_number,
    icon_in_line_sized, icon_sized,
};

/// Where a step stands.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StepStatus {
    Done,
    Current,
    /// Visited, but what it asks for isn't satisfied yet.
    Attention,
    Upcoming,
}

impl StepStatus {
    /// The usual status of the step at `index` while `current` is showing.
    pub fn by_position(index: usize, current: usize) -> Self {
        match index.cmp(&current) {
            Ordering::Less => StepStatus::Done,
            Ordering::Equal => StepStatus::Current,
            Ordering::Greater => StepStatus::Upcoming,
        }
    }

    /// Where a step stands once the user has been through it: done only
    /// while what it asks for still holds (see `AppModel::step_satisfied`),
    /// otherwise it needs attention, even while a later step is showing.
    pub fn visited(index: usize, current: usize, satisfied: bool) -> Self {
        match Self::by_position(index, current) {
            StepStatus::Done if !satisfied => StepStatus::Attention,
            status => status,
        }
    }

    /// The words that end a step's accessible name.
    fn text(self) -> String {
        match self {
            StepStatus::Done => t!("stepper-status-completed"),
            StepStatus::Current => t!("stepper-status-current"),
            StepStatus::Attention => t!("stepper-status-attention"),
            StepStatus::Upcoming => t!("stepper-status-upcoming"),
        }
    }
}

/// A step's accessible name: "Step 2 of 4, Your choices, current step".
pub(super) fn step_name(index: usize, total: usize, title: &str, status: StepStatus) -> String {
    t!("stepper-step-a11y", number = index + 1, total = total, title = title, status = status.text())
}

/// A step's round marker, as the stepper and Home's step list both draw it:
/// a check when done, the number on the accent when current, "!" on the
/// caution colour when it needs attention, and an outlined number to come.
/// `None` is Home's plain list. Size and place it where it goes.
pub fn step_marker(number: usize, status: Option<StepStatus>, cx: &App) -> Div {
    let theme = cx.theme();
    div()
        .flex()
        .items_center()
        .justify_center()
        .size(px(22.))
        .rounded_full()
        .map(|this| match status {
            Some(StepStatus::Done | StepStatus::Current) => {
                this.bg(theme.accent).text_color(theme.text_on_accent)
            }
            // The caution colour, with its pale fill as the glyph, reads
            // in light, dark and high contrast alike.
            Some(StepStatus::Attention) => this.bg(theme.caution).text_color(theme.caution_fill),
            Some(StepStatus::Upcoming) | None => {
                this.border_1().border_color(theme.control_strong_stroke).text_color(theme.text_secondary)
            }
        })
        .child(step_glyph(number, status))
}

fn step_glyph(number: usize, status: Option<StepStatus>) -> AnyElement {
    match status {
        Some(StepStatus::Done) => icon_sized(Icon::CheckMark, 10.).into_any_element(),
        Some(StepStatus::Attention) => centred_step_number("!").into_any_element(),
        _ => centred_step_number(fmt::integer(number as u64)).into_any_element(),
    }
}

struct StepperStep {
    title: SharedString,
    status: StepStatus,
    clickable: bool,
}

type SelectHandler = Rc<dyn Fn(usize, &mut Window, &mut App)>;

/// The steps, reported as a list. A step that can be chosen is a button.
#[derive(IntoElement)]
pub struct Stepper {
    id: ElementId,
    label: SharedString,
    steps: Vec<StepperStep>,
    on_select: Option<SelectHandler>,
}

impl Stepper {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>) -> Self {
        Self { id: id.into(), label: label.into(), steps: Vec::new(), on_select: None }
    }

    /// Adds the next step: its title, where it stands, and whether it can be
    /// chosen to go back to it.
    pub fn step(mut self, title: impl Into<SharedString>, status: StepStatus, clickable: bool) -> Self {
        self.steps.push(StepperStep { title: title.into(), status, clickable });
        self
    }

    /// Runs with a step's index when that step is chosen.
    pub fn on_select(mut self, handler: impl Fn(usize, &mut Window, &mut App) + 'static) -> Self {
        self.on_select = Some(Rc::new(handler));
        self
    }
}

impl RenderOnce for Stepper {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let marker_top = body_cap_center_offset(window, cx);
        let total = self.steps.len();
        let mut row = div()
            .id(self.id)
            .role(Role::List)
            .aria_label(self.label)
            .aria_size_of_set(total)
            .flex()
            .items_center()
            .flex_wrap()
            .gap_y(px(8.))
            .pb(px(4.));
        for (index, step) in self.steps.into_iter().enumerate() {
            let status = step.status;
            let current = status == StepStatus::Current;
            let marker = step_marker(index + 1, Some(status), cx).relative().top(marker_top);
            let label = div()
                .type_body()
                .when(current, |this| this.type_body_strong())
                .text_color(if current { theme.text_primary } else { theme.text_secondary })
                .child(step.title.clone());
            let select = self.on_select.clone().filter(|_| step.clickable);
            let item = div()
                .id(("step", index))
                .role(if select.is_some() { Role::Button } else { Role::ListItem })
                .aria_label(step_name(index, total, &step.title, status))
                // AccessKit counts from 0 and takes the size from the list.
                .aria_position_in_set(index)
                .flex()
                .items_center()
                .gap(px(8.))
                .px(px(8.))
                .py(px(4.))
                .rounded(px(4.))
                .border_1()
                .border_color(theme.transparent())
                .when_some(select, |this, select| {
                    let hover = theme.subtle_hover;
                    let focus_outer = theme.focus_outer;
                    let by_action = select.clone();
                    this.tab_index(0)
                        .hover(move |style| style.bg(hover))
                        .focus_visible(move |style| style.border_color(focus_outer))
                        .on_a11y_action(gpui::AccessibleAction::Click, move |_, window, cx| {
                            by_action(index, window, cx)
                        })
                        .on_click(move |_, window, cx| select(index, window, cx))
                })
                .child(marker)
                .child(label);
            // The chevron stays with the step before it, so a wrapped row
            // never starts with one.
            row = row.child(div().flex().items_center().child(Revealed::new(item)).when(
                index + 1 < total,
                |this| {
                    this.child(
                        icon_in_line_sized(Icon::ChevronRight, 10., BODY_LINE_HEIGHT)
                            .text_color(theme.text_tertiary)
                            .mx(px(4.)),
                    )
                },
            ));
        }
        row
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_visited_step_that_is_not_satisfied_needs_attention() {
        use StepStatus::*;
        let statuses = |unsatisfied: Option<usize>, current| {
            [0, 1, 2, 3].map(|step| StepStatus::visited(step, current, Some(step) != unsatisfied))
        };
        assert_eq!(statuses(None, 2), [Done, Done, Current, Upcoming]);
        assert_eq!(statuses(Some(0), 2), [Attention, Done, Current, Upcoming]);
        assert_eq!(statuses(Some(2), 3), [Done, Done, Attention, Current]);
        // The step showing is current, and a step ahead is upcoming, either way.
        assert_eq!(StepStatus::visited(0, 0, false), Current);
        assert_eq!(StepStatus::visited(2, 1, false), Upcoming);
    }

    #[test]
    fn steps_default_to_their_place_in_the_flow() {
        assert_eq!(StepStatus::by_position(0, 1), StepStatus::Done);
        assert_eq!(StepStatus::by_position(1, 1), StepStatus::Current);
        assert_eq!(StepStatus::by_position(2, 1), StepStatus::Upcoming);
    }

    #[test]
    fn the_attention_mark_is_readable_in_light_and_dark() {
        use crate::theme::{Theme, contrast_ratio};
        for theme in [Theme::light(), Theme::dark()] {
            let ratio = contrast_ratio(theme.caution_fill, theme.caution, theme.solid_background);
            assert!(ratio >= 3., "{:?}: {ratio:.2}:1 is below 3:1", theme.appearance);
        }
    }

    #[test]
    fn a_step_name_says_where_the_step_stands() {
        crate::i18n::testing::english(|| {
            assert_eq!(
                step_name(1, 4, "Your choices", StepStatus::Current),
                "Step 2 of 4, Your choices, current step"
            );
            assert_eq!(
                step_name(0, 4, "Get ready", StepStatus::Attention),
                "Step 1 of 4, Get ready, needs attention"
            );
        });
    }
}
