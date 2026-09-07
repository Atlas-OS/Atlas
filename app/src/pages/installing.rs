//! Shows preparation, installation progress and the restart countdown.
//! Failures return to the Install step, which provides the log and retry action.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, Role, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::{LogIds, LogView};
use crate::i18n::fmt;
use crate::model::{AppModel, RunState};
use crate::services::installer::Phase;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, FocusHandles, Icon, ProgressBar, ProgressRing, ScrollbarState, Typography, a11y_text, card,
    icon_sized, scrollbar,
};

/// Log lines drawn; the whole log is in the file.
const LOG_LINES_SHOWN: usize = 300;
const LOG_IDS: LogIds =
    LogIds { log: "installing-log", hidden: "installing-log-hidden", line: "installing-log-line" };

pub struct InstallingPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    log: LogView,
    show_details: bool,
    shown_run: Option<RunState>,
    focus: FocusHandles,
}

impl InstallingPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            log: LogView::default(),
            show_details: false,
            shown_run: None,
            focus: FocusHandles::default(),
        }
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        self.log.render(LOG_IDS, 220., LOG_LINES_SHOWN, &state.attempt, cx)
    }
}

impl Render for InstallingPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let heading_focus = self.focus.get("installing-heading", cx);
        let (run, phase, countdown, progress, cancelled, started_at, output_problem, restart_problem) = {
            let state = self.model.read(cx);
            (
                state.flow.run,
                state.attempt.phase,
                state.restart_countdown(),
                state.restart_progress(),
                state.attempt.restart_cancelled,
                state.session.as_ref().map(|s| s.started_at.clone()),
                state.attempt.output_problem.clone(),
                state.attempt.restart_problem.clone(),
            )
        };
        let plan_progress = self.model.read(cx).attempt.plan_progress;
        // Announce each change of state by focusing the heading.
        if self.shown_run != Some(run) {
            self.shown_run = Some(run);
            self.scroll.set_offset(gpui::Point::default());
            window.focus(&heading_focus, cx);
        }

        let succeeded = matches!(run, RunState::Finished(outcome) if outcome.is_success());
        let (title, line): (String, String) = match run {
            RunState::Preparing => (t!("installing-checking-title"), t!("installing-checking-line")),
            RunState::Running => (
                t!("installing-title"),
                match phase {
                    Phase::Preflight => t!("installing-phase-preflight"),
                    Phase::Staging => t!("installing-phase-staging"),
                    Phase::Applying => t!("installing-phase-applying"),
                    Phase::Done => t!("installing-phase-done"),
                },
            ),
            RunState::Finished(_) if succeeded => (
                t!("installing-installed-title"),
                match (countdown, cancelled) {
                    (Some(0), _) => t!("restart-now-message"),
                    (Some(seconds), _) => t!("restart-countdown", seconds = seconds),
                    (None, true) => t!("restart-stopped"),
                    (None, false) => t!("restart-needed"),
                },
            ),
            _ => (t!("install-title"), String::new()),
        };
        let started = started_at.as_deref().and_then(fmt::parse_local).map(|when| {
            let minutes = (chrono::Local::now().signed_duration_since(when).num_minutes()).max(0);
            let time = fmt::time(&when);
            match minutes {
                0 => t!("installing-started-just-now", time = time),
                n => t!("installing-started-minutes", time = time, minutes = n),
            }
        });

        // The mark, the state, the one line that matters, then progress.
        let mut column = div()
            .flex()
            .flex_col()
            .items_center()
            .w_full()
            .max_w(px(600.))
            .gap(px(16.))
            .flex_shrink_0()
            .my_auto()
            .child(if succeeded {
                icon_sized(Icon::Completed, 56.).text_color(theme.success).into_any_element()
            } else {
                svg().path("brand/atlas-mark.svg").size(px(56.)).text_color(theme.brand).into_any_element()
            })
            .child(
                div()
                    .id("installing-heading")
                    .role(Role::Heading)
                    .aria_level(1)
                    .aria_label(title.clone())
                    .track_focus(&heading_focus.clone().tab_stop(false))
                    .type_title()
                    .text_color(theme.text_primary)
                    .text_center()
                    .child(title),
            )
            .child(
                div()
                    .type_body_large()
                    .text_color(theme.text_secondary)
                    .text_center()
                    .child(a11y_text("installing-line", line)),
            );

        match run {
            RunState::Preparing => {
                column = column.child(div().pt(px(8.)).child(ProgressRing::new().size(28.)));
            }
            RunState::Running => {
                column = column
                    .child(div().w_full().pt(px(8.)).child(ProgressBar::new(
                        "installing-progress",
                        t!("install-progress"),
                        Some(plan_progress.map_or(0., |p| p.fraction()).min(0.99)),
                    )))
                    .when_some(plan_progress, |this, p| {
                        this.child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(format!("{}%", (p.fraction() * 100.).floor().min(99.) as u32)),
                        )
                    })
                    .when_some(started, |this, text| {
                        this.child(
                            div()
                                .type_caption()
                                .text_color(theme.text_tertiary)
                                .child(a11y_text("installing-started", text)),
                        )
                    });
            }
            RunState::Finished(_) if succeeded => {
                if let Some(progress) = progress {
                    column = column.child(div().w_full().pt(px(8.)).child(ProgressBar::new(
                        "restart-progress",
                        t!("restart-progress"),
                        Some(progress),
                    )));
                }
                let mut buttons = div().flex().gap(px(8.)).pt(px(8.));
                if countdown.is_some() {
                    buttons = buttons.child(Button::new("stop-restart", t!("restart-dont-now")).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.cancel_restart(cx))
                    }));
                } else {
                    buttons = buttons
                        .child(
                            Button::new("restart-now", t!("restart-now"))
                                .accent()
                                .icon(Icon::Power)
                                .on_click({
                                    let model = model.clone();
                                    move |_, _, cx| model.update(cx, |m, cx| m.restart_now(cx))
                                }),
                        )
                        .child(Button::new("installing-done", t!("common-done")).subtle().on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.cancel_flow(cx))
                        }));
                }
                column = column.child(buttons);
            }
            _ => {}
        }

        if let Some(problem) = restart_problem {
            column = column.child(
                div()
                    .type_caption()
                    .text_color(theme.caution)
                    .text_center()
                    .child(a11y_text("installing-restart-problem", problem.text())),
            );
        }
        if let Some(problem) = output_problem {
            column = column.child(
                div()
                    .type_caption()
                    .text_color(theme.caution)
                    .text_center()
                    .child(a11y_text("installing-output", t!("output-problem-message", error = problem))),
            );
        }

        // The log stays a click away, never in the way.
        let show_details = self.show_details;
        column = column.child(
            div().pt(px(16.)).child(
                Button::new(
                    "installing-details",
                    if show_details { t!("common-hide-details") } else { t!("common-show-details") },
                )
                .hyperlink()
                .compact()
                .trailing_icon(if show_details { Icon::ChevronUp } else { Icon::ChevronDown })
                .on_click(cx.listener(|this, _, _, cx| {
                    this.show_details = !this.show_details;
                    cx.notify();
                })),
            ),
        );
        if show_details {
            let has_log = self.model.read(cx).session.is_some();
            let actions = div()
                .flex()
                .gap(px(8.))
                .child(
                    Button::new("installing-copy", t!("common-copy"))
                        .compact()
                        .icon(Icon::Copy)
                        .aria_label(t!("common-copy-install-log"))
                        .on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.copy_log(cx))
                        }),
                )
                .child(
                    Button::new("installing-open", t!("common-open-log-file"))
                        .compact()
                        .icon(Icon::Folder)
                        .disabled(!has_log)
                        .on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.reveal_log(cx))
                        }),
                );
            column = column.child(
                card(cx)
                    .w_full()
                    .child(super::card_header(
                        cx,
                        "log",
                        t!("common-install-log"),
                        Some(actions.into_any_element()),
                    ))
                    .child(self.log_view(cx)),
            );
        }

        div()
            .relative()
            .size_full()
            .child(
                div()
                    .id("installing-scroll")
                    .size_full()
                    .overflow_y_scroll()
                    .track_scroll(&self.scroll)
                    .flex()
                    .flex_col()
                    .items_center()
                    .px(px(40.))
                    .py(px(40.))
                    .child(column),
            )
            .child(scrollbar(&self.scroll, &self.scrollbar))
    }
}
