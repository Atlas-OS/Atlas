//! Step 4, Install: the last attempt's result, what stands in the way of
//! starting, and a summary of what will be installed. The installing view
//! covers this page while an install runs and once one has succeeded, so
//! only an idle step or a failed attempt shows here.

use gpui::{
    AnyElement, App, ClipboardItem, Context, IntoElement, ParentElement, Styled, div, prelude::*, px,
};

use super::{InstallPage, LOG_IDS, LOG_LINES_SHOWN, details_toggle, go_to_ready_button, start_over_button};
use crate::i18n::describe;
use crate::model::{ElevationProblem, Preflight, RunState, Step};
use crate::pages::{
    ListEntry, card_body, caution_caption, detail_row, detail_row_with_action, detail_text, log_actions,
    on_model, plain_list, step_card_header,
};
use crate::services::installer::{self, InstallOutcome, Phase};
use crate::services::requirements::{CheckId, Verdict};
use crate::services::system::links;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{Button, CheckBox, Icon, InfoBar, Severity, Typography, a11y_text, card};

impl InstallPage {
    pub(super) fn install_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let model = self.model.clone();
        let result_focus = self.focus.get("install-result", cx);
        let preflight_focus = self.focus.get("install-preflight", cx);
        let state = self.model.read(cx);
        let run = state.flow.run;
        let mut cards = Vec::new();

        // The current result comes first, so it is never hidden below the
        // summary at small window sizes, with what helps right under it.
        if let RunState::Finished(outcome) = run {
            // A retry of an install an earlier attempt began applying.
            let resumed = state.original_options().is_some();
            let severity = if outcome == InstallOutcome::Lost { Severity::Warning } else { Severity::Error };
            let advice = outcome.advice(state.attempt.phase, resumed);
            // The installer's own words for what went wrong, untranslated.
            let message = match state.attempt.last_error() {
                Some(error) => t!("install-source-details", problem = advice, error = error),
                None => advice,
            };
            // One next action: without permission, relaunching comes before
            // anything else, here rather than in a bar of its own.
            let relaunch = (!state.elevated).then(|| {
                if state.elevation_error == Some(ElevationProblem::TakenOver) {
                    start_over_button("result-start-over", &model)
                } else {
                    Button::new("result-elevate", t!("common-restart-as-administrator"))
                        .accent()
                        .icon(Icon::Admin)
                        .disabled(!state.may_relaunch_elevated())
                        .on_click(on_model(&model, |m, cx| m.relaunch_elevated(cx)))
                }
            });
            let back_to_ready = outcome.needs_preparation() || outcome == InstallOutcome::Failed(2);
            // An installer that stopped without a result may have changed
            // things, so its message says how to turn protection back on.
            let protections =
                state.attempt.phase >= Phase::Applying || resumed || outcome == InstallOutcome::Lost;
            let actions = div()
                .flex()
                .flex_wrap()
                .gap(px(8.))
                .children(relaunch)
                .when(back_to_ready, |this| this.child(go_to_ready_button("result-back-ready", &model)))
                .when(protections, |this| {
                    this.child(
                        Button::new("result-open-security", t!("common-open-windows-security"))
                            .icon(Icon::Shield)
                            .opens(links::WINDOWS_SECURITY_PROTECTION),
                    )
                });
            let elevation = state.elevation_error.as_ref().filter(|_| !state.elevated).map(|e| e.text());
            let bar = InfoBar::new(severity, outcome.heading(resumed), message)
                .id("install-result")
                .focus_handle(result_focus)
                .action(actions);
            cards.push(
                match elevation {
                    Some(text) => {
                        bar.content(div().type_body().child(a11y_text("install-result-elevation", text)))
                    }
                    None => bar,
                }
                .into_any_element(),
            );
            cards.push(self.diagnostics.panel(&self.model, cx).into_any_element());
        }

        if let Some(problem) = &state.preflight_problem {
            cards.push(
                InfoBar::new(
                    Severity::Error,
                    t!("preflight-title"),
                    problem.text(&state.system, state.original_options().is_some()),
                )
                .id("install-preflight")
                .focus_handle(preflight_focus)
                .when_some(preflight_action(problem, &model), |bar, action| bar.action(action))
                .into_any_element(),
            );
            // A refusal follows an attempt that never started, so no result shows above.
            if !matches!(run, RunState::Finished(_)) {
                cards.push(self.diagnostics.panel(&self.model, cx).into_any_element());
            }
        }
        if let Some(problem) = &state.attempt.output_problem {
            cards.push(
                InfoBar::new(
                    Severity::Warning,
                    t!("output-problem-title"),
                    t!("output-problem-message", error = problem),
                )
                .id("install-output-problem")
                .into_any_element(),
            );
        }

        // What stands between this step and Install (or Try again).
        if run.may_start() {
            if !state.elevated {
                // After an attempt, the result above offers the relaunch.
                if !matches!(run, RunState::Finished(_)) {
                    // Relaunching cannot help while another window owns the
                    // setup; starting over here can.
                    let action = if state.elevation_error == Some(ElevationProblem::TakenOver) {
                        start_over_button("install-start-over", &model)
                    } else {
                        Button::new("install-elevate", t!("common-restart-as-administrator"))
                            .accent()
                            .icon(Icon::Admin)
                            .on_click(on_model(&model, |m, cx| m.relaunch_elevated(cx)))
                    };
                    let why = state
                        .elevation_error
                        .as_ref()
                        .map(|e| e.text())
                        .unwrap_or_else(|| t!("detail-admin-missing"));
                    cards.push(
                        InfoBar::new(Severity::Warning, t!("install-elevate-title"), why)
                            .id("install-elevate-bar")
                            .action(action)
                            .into_any_element(),
                    );
                }
            } else if state.playbook.is_none() {
                cards.push(
                    InfoBar::new(
                        Severity::Warning,
                        t!("install-no-package-title"),
                        if state.bundled() {
                            t!("install-no-package-bundled-message")
                        } else {
                            t!("install-no-package-message")
                        },
                    )
                    .id("install-no-package")
                    .action(go_to_ready_button("install-back-ready", &model))
                    .into_any_element(),
                );
            } else if !state.ready_to_continue() {
                // Step 1 is not satisfied for this session (checks or Windows
                // updates), so Install stays disabled: say so and lead back.
                cards.push(
                    InfoBar::new(
                        Severity::Warning,
                        t!("install-not-ready-title"),
                        t!("install-not-ready-message"),
                    )
                    .id("install-not-ready")
                    .action(go_to_ready_button("install-back-ready", &model))
                    .into_any_element(),
                );
            } else if !state.security_ok() {
                let message = if !state.security_fresh() {
                    t!("install-security-reading")
                } else {
                    t!(
                        "install-security-message",
                        summary = describe::security_summary(&state.security.counts())
                    )
                };
                cards.push(
                    InfoBar::new(Severity::Warning, t!("install-security-title"), message)
                        .id("install-security")
                        .action(
                            Button::new("install-open-security", t!("common-open-windows-security"))
                                .icon(Icon::Shield)
                                .opens(links::WINDOWS_SECURITY_PROTECTION),
                        )
                        .into_any_element(),
                );
            }
        }
        if matches!(run, RunState::Finished(_)) {
            cards.push(self.finished_log(cx));
        }
        cards.push(self.summary_card(cx));
        cards
    }

    /// A finished attempt's log, folded away under its Copy and Open log
    /// file buttons until asked for.
    fn finished_log(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let shown = self.show_log;
        let toggle =
            details_toggle("log-toggle", t!("common-install-log"), shown, |page| &mut page.show_log, cx);
        let log = shown.then(|| self.log_view(cx));
        card(cx)
            .child(step_card_header(
                cx,
                "log",
                t!("common-install-log"),
                Some(log_actions(&self.model, LOG_IDS, cx).into_any_element()),
            ))
            .child(div().flex().px(px(16.)).py(px(8.)).child(toggle))
            .children(log)
            .into_any_element()
    }

    /// What will be installed: the choices first, then what to know before
    /// starting, then the details behind a toggle.
    fn summary_card(&self, cx: &Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let request = state.install_request();
        let restart = request.as_ref().map(|r| r.restart).unwrap_or(state.settings.restart_after_install);
        let title = if matches!(state.flow.run, RunState::Finished(_)) {
            t!("summary-try-again")
        } else {
            t!("summary-ready")
        };
        let shown = self.show_summary_details;
        let toggle = details_toggle(
            "summary-details",
            title.clone(),
            shown,
            |page| &mut page.show_summary_details,
            cx,
        );
        card(cx)
            .child(step_card_header(cx, "summary", title, None))
            .child(
                card_body()
                    .children(self.choice_rows(cx))
                    .child(detail_row(
                        cx,
                        "duration",
                        t!("summary-duration"),
                        detail_text(
                            "duration",
                            t!("summary-duration-value", minutes = state.manifest().estimated_minutes),
                        ),
                    ))
                    .child(
                        CheckBox::new("install-restart", t!("summary-restart-checkbox"), restart)
                            .description(t!("settings-restart-description"))
                            .on_toggle(on_model(&model, |m, cx| {
                                let next = !m.settings.restart_after_install;
                                m.set_restart_after_install(next, cx);
                            })),
                    )
                    .child(div().flex().pt(px(4.)).child(toggle))
                    .when(shown, |this| this.children(self.summary_details(cx)))
                    .map(|this| this.text_color(theme.text_primary)),
            )
            .into_any_element()
    }

    /// The facts already seen on Get ready, and the installation command.
    fn summary_details(&self, cx: &Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme();
        let state = self.model.read(cx);
        let request = state.install_request();
        let activation = state
            .checks
            .iter()
            .find(|(id, _)| *id == CheckId::Activation)
            .and_then(|(_, result)| result.as_ref())
            .map(|result| match result.verdict {
                Verdict::Pass => t!("summary-activation-ok"),
                Verdict::Warn => t!("summary-activation-missing"),
                _ => t!("summary-activation-unknown"),
            })
            .unwrap_or_else(|| t!("summary-activation-unknown"));
        let package =
            state.playbook.as_ref().map(|source| source.describe()).unwrap_or_else(|| t!("package-none-yet"));
        let show_command = self.show_command;
        // Built only while shown, not on every frame.
        let command = request.as_ref().filter(|_| show_command).map(|request| {
            installer::command_line(request)
                .unwrap_or_else(|error| t!("summary-command-unavailable", error = format!("{error:#}")))
        });
        let mut details = vec![
            detail_row(cx, "package", t!("common-package"), detail_text("package", package))
                .into_any_element(),
            detail_row(
                cx,
                "windows",
                t!("common-windows"),
                detail_text("windows", describe::system_description(&state.system)),
            )
            .into_any_element(),
            detail_row(cx, "activation", t!("summary-activation"), detail_text("activation", activation))
                .into_any_element(),
        ];
        if request.is_some() {
            details.push(
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .pt(px(4.))
                    .child(
                        div().flex().child(
                            Button::new(
                                "toggle-command",
                                if show_command {
                                    t!("summary-hide-command")
                                } else {
                                    t!("summary-show-command")
                                },
                            )
                            .hyperlink()
                            .compact()
                            .expanded(show_command)
                            .trailing_icon(if show_command { Icon::ChevronUp } else { Icon::ChevronDown })
                            .on_click(cx.listener(|this, _, _, cx| {
                                this.show_command = !this.show_command;
                                cx.notify();
                            })),
                        ),
                    )
                    .when_some(command, |this, command| {
                        // The exact command, as the installer receives it.
                        let copied = command.clone();
                        this.child(
                            div()
                                .px(px(12.))
                                .py(px(8.))
                                .rounded(px(4.))
                                .bg(theme.subtle_hover)
                                .type_mono()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("install-command", command)),
                        )
                        .child(
                            div().flex().child(
                                Button::new("copy-command", t!("common-copy"))
                                    .compact()
                                    .icon(Icon::Copy)
                                    .aria_label(t!("summary-copy-command-a11y"))
                                    .on_click(move |_, _, cx| {
                                        cx.write_to_clipboard(ClipboardItem::new_string(copied.clone()))
                                    }),
                            ),
                        )
                    })
                    .into_any_element(),
            );
        }
        details
    }

    /// One row per Options screen with a Change link at its trailing edge;
    /// Continue from there returns here. A resumed install's choices are
    /// fixed, so its rows have no link. Choices that reduce protection, or
    /// delete the user's data, carry a caution.
    fn choice_rows(&self, cx: &App) -> Vec<AnyElement> {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let manifest = state.manifest();
        let options = state.effective_options();
        let mut rows = Vec::new();
        for (index, screen) in state.option_screens().into_iter().enumerate() {
            let chosen: Vec<ListEntry> = screen
                .pages
                .iter()
                .filter_map(|&page_index| manifest.pages.get(page_index))
                .filter(|page| page.depends_on.as_ref().is_none_or(|dependency| options.contains(dependency)))
                .flat_map(|page| page.options.iter())
                .filter(|option| options.contains(&option.name))
                .map(|option| ListEntry::install_option(&option.name, &option.text, state.before_desktop))
                .collect();
            let title = screen.kind.title();
            let key = format!("choice-{index}");
            let change = state.locked_options().is_none().then(|| {
                Button::new(("change-choice", index), t!("common-change"))
                    .hyperlink()
                    .compact()
                    .aria_label(t!("summary-change-a11y", title = title.as_str()))
                    .disabled(!state.flow.may_edit())
                    .on_click(on_model(&model, move |m, cx| m.edit_options(index, cx)))
            });
            let value: AnyElement = if screen.required {
                let (text, caution) = match chosen.into_iter().next() {
                    Some(ListEntry { text, caution }) => (text, caution),
                    None => (t!("summary-not-chosen"), None),
                };
                div()
                    .flex()
                    .flex_col()
                    .gap(px(2.))
                    .min_w_0()
                    .child(detail_text(&key, text))
                    .when_some(caution, |this, caution| {
                        this.child(caution_caption(cx, detail_text(&format!("{key}-caution"), caution)))
                    })
                    .into_any_element()
            } else if chosen.is_empty() {
                div()
                    .text_color(theme.text_secondary)
                    .child(detail_text(&key, t!("common-none")))
                    .into_any_element()
            } else {
                plain_list(cx, ("choices", index), &title, chosen).w_full().into_any_element()
            };
            rows.push(
                detail_row_with_action(cx, &key, title, value, change.map(IntoElement::into_any_element))
                    .into_any_element(),
            );
        }
        rows
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        self.log.render(LOG_IDS, 280., LOG_LINES_SHOWN, &state.attempt, cx)
    }
}

/// What fixes a refusal of the final checks: unusable choices are
/// corrected on Your choices, a setup another window took over is started
/// again here, and changed checks and an unreadable record are dealt with on
/// Get ready. A launch that failed or was busy is retried with Install Atlas
/// below, so it has none, and so has a change to Windows Security alone,
/// which has its own bar below with Open Windows Security.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum PreflightFix {
    Options,
    StartOver,
    Ready,
}

fn preflight_fix(problem: &Preflight) -> Option<PreflightFix> {
    match problem {
        Preflight::InvalidOptions { .. } => Some(PreflightFix::Options),
        Preflight::TakenOver => Some(PreflightFix::StartOver),
        Preflight::Changed { checks, .. } if checks.is_empty() => None,
        Preflight::Changed { .. } | Preflight::RecordUnreadable { .. } => Some(PreflightFix::Ready),
        Preflight::Refused { .. } | Preflight::Busy => None,
    }
}

/// The refusal bar's button, if it has one (see [`PreflightFix`]).
fn preflight_action(problem: &Preflight, model: &gpui::Entity<crate::model::AppModel>) -> Option<Button> {
    Some(match preflight_fix(problem)? {
        PreflightFix::Options => Button::new("install-back-options", t!("go-to-options"))
            .on_click(on_model(model, |m, cx| m.set_step(Step::Options, cx))),
        PreflightFix::StartOver => start_over_button("install-start-over", model),
        PreflightFix::Ready => go_to_ready_button("install-back-ready", model),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::requirements::CheckDetail;

    /// Install Atlas is the retry for a launch that failed or was busy, so
    /// the bar doesn't send the user back to Get ready, which can't help.
    #[test]
    fn only_problems_get_ready_fixes_lead_back_there() {
        assert_eq!(preflight_fix(&Preflight::Refused { error: "denied".into() }), None);
        assert_eq!(preflight_fix(&Preflight::Busy), None);
        assert_eq!(
            preflight_fix(&Preflight::RecordUnreadable { error: "x".into() }),
            Some(PreflightFix::Ready)
        );
        let changed =
            Preflight::Changed { checks: vec![(CheckId::Power, CheckDetail::PowerUnknown)], security: None };
        assert_eq!(preflight_fix(&changed), Some(PreflightFix::Ready));
        let security_only = Preflight::Changed { checks: vec![], security: Some(Default::default()) };
        assert_eq!(preflight_fix(&security_only), None);
        assert_eq!(preflight_fix(&Preflight::TakenOver), Some(PreflightFix::StartOver));
        assert_eq!(
            preflight_fix(&Preflight::InvalidOptions { error: "x".into() }),
            Some(PreflightFix::Options)
        );
    }
}
