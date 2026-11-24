//! Shows the install from its final checks to the restart countdown, as one
//! screen whose bar never goes backwards: what Atlas is doing, and one line
//! on keeping the PC on and whether it restarts by itself. Failures return to
//! the Install step, which provides the log and retry action.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, Role, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::install::details_toggle;
use super::{LogIds, LogView, card_header, detail_text, focusable_heading, log_actions, on_model};
use crate::model::{AppModel, RestartProblem, RunState};
use crate::services::installer::Phase;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, FocusHandles, Icon, InfoBar, ProgressBar, ScrollbarState, Severity, Typography, a11y_text, card,
    focus_reveal, icon_sized, scrollbar,
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

/// The most progress shown, as a fraction, while the installer runs. The
/// plan can finish before the installer exits, and the end waits for its
/// result.
const RUNNING_PROGRESS_CAP: f32 = 0.99;

/// What the view shows. The final checks and the installer's run are one
/// screen, so moving from one to the other moves nothing.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Screen {
    Installing,
    Installed,
    Other,
}

impl Screen {
    fn of(run: RunState) -> Self {
        match run {
            RunState::Preparing | RunState::Running => Screen::Installing,
            RunState::Finished(_) if run.succeeded() => Screen::Installed,
            _ => Screen::Other,
        }
    }
}

pub struct InstallingPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    log: LogView,
    /// The log, and the raw error of anything that went wrong, folded away
    /// by default.
    show_details: bool,
    shown_screen: Option<Screen>,
    /// Whether the last frame showed the automatic restart as cancelled.
    shown_restart_cancelled: bool,
    /// Whether Windows had been asked to restart last frame.
    shown_restarting: bool,
    /// The restarts that didn't happen, as last announced.
    shown_restart_epoch: u64,
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
            shown_screen: None,
            shown_restart_cancelled: false,
            shown_restarting: false,
            shown_restart_epoch: 0,
            focus: FocusHandles::default(),
        }
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        self.log.render(LOG_IDS, 220., LOG_LINES_SHOWN, &state.attempt, cx)
    }
}

/// What the view says Atlas is doing while it installs, as a short verb
/// phrase: the final checks and the installer's own first checks read the
/// same, so the two read as one step.
fn installing_label(run: RunState, phase: Phase) -> String {
    match (run, phase) {
        (RunState::Preparing, _) | (_, Phase::Preflight) => t!("installing-checking-label"),
        (_, Phase::Staging) => t!("installing-staging-label"),
        (_, Phase::Applying) => t!("installing-applying-label"),
        (_, Phase::Done) => t!("installing-finishing-label"),
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
            cancelled,
            restarting,
            cancellable,
            output_problem,
            restart_problem,
            restarts_after,
            plan_progress,
        ) = {
            let state = self.model.read(cx);
            (
                state.attempt.restart_epoch,
                state.flow.run,
                state.attempt.phase,
                state.restart_countdown(),
                state.attempt.restart_cancelled,
                state.attempt.restart_requested,
                state.restart_cancellable(),
                state.attempt.output_problem.clone(),
                state.attempt.restart_problem.clone(),
                // The final checks run before there's a record, so they say
                // what the request will ask for.
                state.install_request().is_some_and(|request| request.restart),
                state.attempt.plan_progress,
            )
        };
        let screen = Screen::of(run);
        // Announce each change of screen by focusing the heading. A countdown
        // focuses Restart later instead, so a key press keeps the PC from
        // restarting before work is saved. "Restart later" removes the focused
        // button, so focus returns to the heading.
        if self.shown_screen != Some(screen) || (cancelled && !self.shown_restart_cancelled) {
            self.shown_screen = Some(screen);
            self.scroll.set_offset(gpui::Point::default());
            let focus =
                if screen == Screen::Installed && cancellable { &later_focus } else { &heading_focus };
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
        // Try again or Restart now is back right under it.
        if std::mem::replace(&mut self.shown_restart_epoch, restart_epoch) != restart_epoch {
            let target = if restart_problem.is_some() { &problem_focus } else { &heading_focus };
            window.focus(target, cx);
            focus_reveal::request(window, cx);
        }

        let (title, line): (String, String) = match screen {
            Screen::Installing => (t!("installing-title"), installing_label(run, phase)),
            Screen::Installed => (
                t!("installing-installed-title"),
                match (restarting, countdown, cancelled) {
                    (true, _, _) | (_, Some(0), _) => t!("restart-now-message"),
                    (_, Some(seconds), _) => t!("installing-restart-countdown", seconds = seconds),
                    // The bar under the heading says what to do.
                    _ if restart_problem.is_some() => String::new(),
                    (_, None, true) => t!("restart-stopped"),
                    (_, None, false) => t!("restart-needed"),
                },
            ),
            Screen::Other => (t!("install-title"), String::new()),
        };
        // While it counts down, there's still time to save work elsewhere.
        let counting = screen == Screen::Installed && !restarting && countdown.is_some_and(|left| left > 0);
        let save = counting.then(|| t!("installing-restart-save"));
        // What the heading and the restart buttons read with them.
        let said = match &save {
            Some(save) => format!("{line} {save}"),
            None => line.clone(),
        };

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
            .child(if screen == Screen::Installed {
                icon_sized(Icon::Completed, 48.).text_color(theme.success).into_any_element()
            } else {
                svg().path("brand/atlas-mark.svg").size(px(48.)).text_color(theme.brand).into_any_element()
            })
            .child(
                focusable_heading("installing-heading", 1, title, &heading_focus, cx)
                    .m(px(-1.))
                    // Focused, it reads the lines under it too: what happens next.
                    .when(!said.is_empty(), |this| this.aria_description(said.clone()))
                    .text_center(),
            )
            .when(!line.is_empty(), |this| {
                this.child(
                    div()
                        .flex()
                        .flex_col()
                        .items_center()
                        .type_body()
                        .text_color(theme.text_secondary)
                        .text_center()
                        .child(a11y_text("installing-line", line.clone()))
                        .when_some(save, |this, save| this.child(a11y_text("installing-save", save))),
                )
            });

        match screen {
            Screen::Installing => {
                // Only the plan's own count moves the bar, so it never goes
                // backwards; until the plan runs, it sweeps. The bar is named
                // after what Atlas is doing and announces it as that changes.
                let fraction = plan_progress
                    .filter(|_| run == RunState::Running)
                    .map(|progress| progress.fraction().min(RUNNING_PROGRESS_CAP));
                let keep_on =
                    if restarts_after { t!("installing-keep-on-restart") } else { t!("installing-keep-on") };
                column = column.child(
                    div()
                        .w_full()
                        .flex()
                        .flex_col()
                        .gap(px(8.))
                        .pt(px(12.))
                        .child(ProgressBar::new("installing-progress", line.clone(), fraction).live())
                        // Said while there is still time to save work elsewhere.
                        .child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .text_center()
                                .child(a11y_text("installing-keep-on", keep_on)),
                        ),
                );
            }
            Screen::Installed => {
                // A restart that didn't happen: what to do, with the retry,
                // in the words Home uses for the restart still owed. Windows'
                // own words are behind Show details.
                if restart_problem.is_some() {
                    column = column.child(
                        InfoBar::new(Severity::Warning, t!("home-restart-title"), t!("home-restart-failed"))
                            .id("restart-problem")
                            .focus_handle(problem_focus.clone())
                            .action(
                                Button::new("restart-retry", t!("common-try-again"))
                                    .accent()
                                    .icon(Icon::Power)
                                    .on_click(on_model(&model, |m, cx| m.restart_now(cx))),
                            ),
                    );
                }
                let mut buttons =
                    div().id("restart-actions").flex().flex_wrap().justify_center().gap(px(8.)).pt(px(8.));
                if restarting {
                    // Windows has the request; nothing here can take it back.
                } else if cancellable {
                    // Restart now is the countdown's own end, so it's the
                    // accent; Restart later has the keyboard. Entering the
                    // group reads the countdown.
                    buttons = buttons
                        .role(Role::Group)
                        .aria_label(said.clone())
                        .child(
                            Button::new("restart-now", t!("restart-now"))
                                .accent()
                                .icon(Icon::Power)
                                .on_click(on_model(&model, |m, cx| m.restart_now(cx))),
                        )
                        .child(
                            Button::new("stop-restart", t!("restart-dont-now"))
                                .focus_handle(later_focus.clone())
                                // Focus starts here, so Enter doesn't restart; Restart now is the
                                // accent, and the ring shows only after a key press, as elsewhere.
                                .on_click(on_model(&model, |m, cx| m.cancel_restart(cx))),
                        );
                } else {
                    // After a refusal, Try again in its bar is the restart.
                    buttons = buttons
                        .when(restart_problem.is_none(), |this| {
                            this.child(
                                Button::new("restart-now", t!("restart-now"))
                                    .accent()
                                    .icon(Icon::Power)
                                    .on_click(on_model(&model, |m, cx| m.restart_now(cx))),
                            )
                        })
                        .child(
                            Button::new("installing-done", t!("common-done"))
                                .on_click(on_model(&model, |m, cx| m.cancel_flow(cx))),
                        );
                }
                column = column.child(buttons);
            }
            Screen::Other => {}
        }

        // The installer carries on whether or not Atlas can follow its log.
        if output_problem.is_some() {
            column = column.child(
                InfoBar::new(Severity::Warning, t!("output-problem-title"), t!("installing-output-problem"))
                    .id("installing-output")
                    .action(
                        Button::new("installing-output-log", t!("common-open-log-folder"))
                            .icon(Icon::Folder)
                            .on_click(on_model(&model, |m, cx| m.reveal_log(cx))),
                    ),
            );
        }

        // The log stays a click away, never in the way, with Windows' or the
        // log reader's own words for what went wrong above it, untranslated.
        let show_details = self.show_details;
        column = column.child(div().pt(px(8.)).child(details_toggle(
            "installing-details",
            t!("common-install-log"),
            show_details,
            |page| &mut page.show_details,
            cx,
        )));
        if show_details {
            let errors: Vec<(&str, String)> = restart_problem
                .map(|RestartProblem::Start { error }| ("restart-error", error))
                .into_iter()
                .chain(output_problem.map(|error| ("output-error", error)))
                .collect();
            let actions = log_actions(&model, LOG_IDS, cx);
            column = column.child(
                card(cx)
                    .w_full()
                    .child(card_header(cx, "log", t!("common-install-log"), actions.into_any_element()))
                    .when(!errors.is_empty(), |card| {
                        card.child(
                            div()
                                .flex()
                                .flex_col()
                                .gap(px(2.))
                                .px(px(16.))
                                .pt(px(8.))
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .children(errors.into_iter().map(|(key, error)| detail_text(key, error))),
                        )
                    })
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::installer::InstallOutcome;

    /// The final checks and the installer's run are one screen, so moving
    /// from one to the other neither moves focus nor changes the heading,
    /// and both start by checking the PC.
    #[test]
    fn the_final_checks_and_the_install_read_as_one_screen() {
        assert_eq!(Screen::of(RunState::Preparing), Screen::of(RunState::Running));
        assert_eq!(Screen::of(RunState::Finished(InstallOutcome::Succeeded)), Screen::Installed);
        assert_eq!(Screen::of(RunState::Finished(InstallOutcome::Failed(1))), Screen::Other);
        crate::i18n::testing::english(|| {
            let checking = installing_label(RunState::Preparing, Phase::Preflight);
            assert_eq!(installing_label(RunState::Running, Phase::Preflight), checking);
            let labels = [Phase::Staging, Phase::Applying, Phase::Done]
                .map(|phase| installing_label(RunState::Running, phase));
            for label in std::iter::once(&checking).chain(&labels) {
                assert!(label.ends_with('…'), "a progress label ends in an ellipsis: {label}");
            }
            assert!(labels.iter().all(|label| *label != checking), "each phase says what it does");
        });
    }
}
