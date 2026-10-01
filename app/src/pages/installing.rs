//! Shows preparation, installation progress and the restart countdown.
//! Failures return to the Install step, which provides the log and retry action.
//! While the install runs, it says whether the PC restarts by itself after.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, Role, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::{LogIds, LogView, card_header, log_actions, on_model};
use crate::i18n::fmt;
use crate::model::{AppModel, RunState};
use crate::services::installer::Phase;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, FocusHandles, Icon, InfoBar, ProgressBar, ProgressRing, ScrollbarState, Severity, Typography,
    a11y_text, card, focus_reveal, icon_sized, scrollbar,
};

/// Log lines drawn; the whole log is in the file.
const LOG_LINES_SHOWN: usize = 300;
const LOG_IDS: LogIds = LogIds {
    log: "installing-log",
    hidden: "installing-log-hidden",
    line: "installing-log-line",
    copy: "installing-copy",
    open: "installing-open",
};

/// The most progress shown, in percent, while the installer runs. The plan can
/// finish before the installer exits, and 100% waits for its result.
const RUNNING_PERCENT_CAP: f32 = 99.;

pub struct InstallingPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    log: LogView,
    show_details: bool,
    shown_run: Option<RunState>,
    /// Whether the last frame showed the automatic restart as cancelled.
    shown_restart_cancelled: bool,
    /// Whether Windows had been asked to restart last frame.
    shown_restarting: bool,
    /// The restarts that didn't happen, as last announced.
    shown_restart_epoch: u64,
    focus: FocusHandles,
    diagnostics: super::Diagnostics,
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
            shown_restart_cancelled: false,
            shown_restarting: false,
            shown_restart_epoch: 0,
            focus: FocusHandles::default(),
            diagnostics: super::Diagnostics::new(cx),
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
        let later_focus = self.focus.get("stop-restart", cx);
        let problem_focus = self.focus.get("restart-problem", cx);
        let (
            restart_epoch,
            run,
            phase,
            countdown,
            progress,
            cancelled,
            restarting,
            cancellable,
            started_at,
            output_problem,
            restart_problem,
            restarts_after,
        ) = {
            let state = self.model.read(cx);
            (
                state.attempt.restart_epoch,
                state.flow.run,
                state.attempt.phase,
                state.restart_countdown(),
                state.restart_progress(),
                state.attempt.restart_cancelled,
                state.attempt.restart_requested,
                state.restart_cancellable(),
                state.session.as_ref().map(|s| s.started_at.clone()),
                state.attempt.output_problem.clone(),
                state.attempt.restart_problem.clone(),
                state.session.as_ref().is_some_and(|s| s.request.restart),
            )
        };
        let plan_progress = self.model.read(cx).attempt.plan_progress;
        // Announce each change of state by focusing the heading. A countdown
        // focuses Restart later instead, so a key press keeps the PC from
        // restarting before work is saved. "Restart later" removes the focused
        // button, so focus returns to the heading.
        if self.shown_run != Some(run) || (cancelled && !self.shown_restart_cancelled) {
            self.shown_run = Some(run);
            self.scroll.set_offset(gpui::Point::default());
            let focus = if run.succeeded() && cancellable { &later_focus } else { &heading_focus };
            window.focus(focus, cx);
        }
        self.shown_restart_cancelled = cancelled;
        // The countdown ran out or Restart now was chosen: the focused button
        // goes, so the heading, which says Windows is restarting, takes focus.
        if restarting && !std::mem::replace(&mut self.shown_restarting, true) {
            window.focus(&heading_focus, cx);
        }
        self.shown_restarting = restarting;
        // A restart Windows refused, or didn't act on, is announced, and
        // Restart now is back right under it.
        if std::mem::replace(&mut self.shown_restart_epoch, restart_epoch) != restart_epoch {
            let target = if restart_problem.is_some() { &problem_focus } else { &heading_focus };
            window.focus(target, cx);
            focus_reveal::request(window, cx);
        }

        let succeeded = run.succeeded();
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
                match (restarting, countdown, cancelled) {
                    (true, _, _) | (_, Some(0), _) => t!("restart-now-message"),
                    (_, Some(seconds), _) => t!("restart-countdown", seconds = seconds),
                    (_, None, true) => t!("restart-stopped"),
                    (_, None, false) => t!("restart-needed"),
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
            .max_w(px(560.))
            .gap(px(12.))
            .flex_shrink_0()
            .my_auto()
            .child(if succeeded {
                icon_sized(Icon::Completed, 48.).text_color(theme.success).into_any_element()
            } else {
                svg().path("brand/atlas-mark.svg").size(px(48.)).text_color(theme.brand).into_any_element()
            })
            .child(
                div()
                    .id("installing-heading")
                    .role(Role::Heading)
                    .aria_level(1)
                    .aria_label(title.clone())
                    // Focused, it reads the line under it too: what happens next.
                    .when(!line.is_empty(), |this| this.aria_description(line.clone()))
                    .track_focus(&heading_focus.clone().tab_stop(false))
                    .type_title()
                    .text_color(theme.text_primary)
                    .text_center()
                    .child(title),
            )
            .child(
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .text_center()
                    .child(a11y_text("installing-line", line.clone())),
            );

        match run {
            RunState::Preparing => {
                column = column.child(div().pt(px(8.)).child(ProgressRing::new().size(28.)));
            }
            RunState::Running => {
                // The bar reports the whole percent the label shows.
                let percent = plan_progress.map(|p| (p.fraction() * 100.).floor().min(RUNNING_PERCENT_CAP));
                let mut progress_group =
                    div().w_full().flex().flex_col().gap(px(8.)).pt(px(12.)).child(ProgressBar::new(
                        "installing-progress",
                        t!("install-progress"),
                        percent.map(|percent| percent / 100.),
                    ));
                let metadata = div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .justify_between()
                    .gap(px(8.))
                    .when_some(started, |this, text| {
                        this.child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("installing-started", text)),
                        )
                    })
                    .when_some(percent, |this, percent| {
                        let percent = t!("install-percent", percent = percent as u32);
                        this.child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("installing-percent", percent)),
                        )
                    });
                progress_group = progress_group.child(metadata).when(restarts_after, |this| {
                    // Said while there is still time to save work elsewhere.
                    this.child(
                        div()
                            .type_caption()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("installing-restart-auto", t!("installing-restart-auto"))),
                    )
                });
                column = column.child(progress_group);
            }
            RunState::Finished(_) if succeeded => {
                if let Some(progress) = progress {
                    // Decorative: the sentence above and the buttons' group
                    // name give the seconds in words.
                    column = column.child(
                        div()
                            .w_full()
                            .pt(px(8.))
                            .child(ProgressBar::new("restart-progress", "", Some(progress)).decorative()),
                    );
                }
                // A restart that didn't happen, before the buttons that retry it.
                if let Some(problem) = &restart_problem {
                    column = column.child(
                        InfoBar::new(Severity::Warning, t!("home-restart-title"), problem.text())
                            .id("restart-problem")
                            .focus_handle(problem_focus.clone()),
                    );
                }
                let mut buttons =
                    div().id("restart-actions").flex().flex_wrap().justify_center().gap(px(8.)).pt(px(8.));
                if restarting {
                    // Windows has the request; nothing here can take it back.
                } else if cancellable {
                    // Both standard: the countdown is the default, and Restart
                    // later has the keyboard. Entering the group reads the countdown.
                    buttons = buttons
                        .role(Role::Group)
                        .aria_label(line.clone())
                        .child(
                            Button::new("restart-now", t!("restart-now"))
                                .icon(Icon::Power)
                                .on_click(on_model(&model, |m, cx| m.restart_now(cx))),
                        )
                        .child(
                            Button::new("stop-restart", t!("restart-dont-now"))
                                .focus_handle(later_focus.clone())
                                // The keyboard's default: its focus ring shows from the start.
                                .keyboard_default()
                                .on_click(on_model(&model, |m, cx| m.cancel_restart(cx))),
                        );
                } else {
                    buttons = buttons
                        .child(
                            Button::new("restart-now", t!("restart-now"))
                                .accent()
                                .icon(Icon::Power)
                                .on_click(on_model(&model, |m, cx| m.restart_now(cx))),
                        )
                        .child(
                            Button::new("installing-done", t!("common-done"))
                                .on_click(on_model(&model, |m, cx| m.cancel_flow(cx))),
                        );
                }
                column = column.child(buttons);
            }
            _ => {}
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
        let details_label = if show_details { t!("common-hide-details") } else { t!("common-show-details") };
        column = column.child(
            div().pt(px(8.)).child(
                Button::new("installing-details", details_label.clone())
                    .aria_label(t!(
                        "common-details-a11y",
                        action = details_label,
                        section = t!("common-install-log")
                    ))
                    .expanded(show_details)
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
            let actions = log_actions(&model, LOG_IDS, cx);
            column = column.child(
                card(cx)
                    .w_full()
                    .child(card_header(cx, "log", t!("common-install-log"), Some(actions.into_any_element())))
                    .child(self.log_view(cx))
                    .child(div().p(px(16.)).child(self.diagnostics.content(&self.model, cx))),
            );
        }
        self.diagnostics.settle(&self.model, window, cx);

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
