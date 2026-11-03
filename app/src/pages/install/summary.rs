//! Step 4, Install: the last attempt's result, what stands in the way of
//! starting, and a summary of what will be installed. The installing view
//! covers this page while an install runs and once one has succeeded, so
//! only an idle step or a failed attempt shows here.

use gpui::{
    AnyElement, App, ClipboardItem, Context, IntoElement, ParentElement, Styled, div, prelude::*, px,
};

use super::{InstallPage, LOG_IDS, LOG_LINES_SHOWN, details_toggle, go_to_ready_button, start_over_button};
use crate::i18n::describe;
use crate::model::{AppModel, ElevationProblem, Preflight, RunState, ScreenKind, Step, UpdatePath};
use crate::pages::{
    ListEntry, card_body, caution_caption, detail_row, detail_row_with_action, detail_text, log_actions,
    on_model, plain_list, step_card_header,
};
use crate::services::installer::{self, InstallOutcome};
use crate::services::playbook::{FeatureOption, Manifest};
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
            let facts = state.attempt_facts();
            let severity = if outcome == InstallOutcome::Lost { Severity::Warning } else { Severity::Error };
            let advice = outcome.advice(&facts);
            // The installer's own words for what went wrong, untranslated.
            let message = match state.attempt.last_error() {
                Some(error) => t!("install-source-details", problem = advice, error = error),
                None => advice,
            };
            // One next action: without permission, relaunching comes before
            // anything else, here rather than in a bar of its own.
            let relaunch = (!state.elevated).then(|| {
                if state.elevation_error == Some(ElevationProblem::TakenOver) {
                    start_over_button("result-start-over", state, &model)
                } else {
                    Button::new("result-elevate", t!("common-restart-as-administrator"))
                        .accent()
                        .icon(Icon::Admin)
                        .disabled(!state.may_relaunch_elevated())
                        .on_click(on_model(&model, |m, cx| m.relaunch_elevated(cx)))
                }
            });
            let back_to_ready = outcome.needs_preparation() || outcome == InstallOutcome::Failed(2);
            let actions = div()
                .flex()
                .flex_wrap()
                .gap(px(8.))
                .children(relaunch)
                .when(back_to_ready, |this| this.child(go_to_ready_button("result-back-ready", &model)))
                .when(state.result_offers_windows_security(), |this| {
                    this.child(
                        Button::new("result-open-security", t!("common-open-windows-security"))
                            .icon(Icon::Shield)
                            .opens(links::WINDOWS_SECURITY_PROTECTION),
                    )
                });
            let elevation = state.elevation_error.as_ref().filter(|_| !state.elevated).map(|e| e.text());
            let bar = InfoBar::new(severity, outcome.heading(facts.resumed), message)
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
                .when_some(preflight_action(problem, state, &model), |bar, action| bar.action(action))
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
                        start_over_button("install-start-over", state, &model)
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
                            .disabled(state.locked())
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

    /// One row per choice with a Change link at its trailing edge (see
    /// [`open_change`]). An update or reinstall first says how it treats the
    /// choices. Keeping them, only that row has a link: every other choice is
    /// as this PC has it, and its link leads through any the PC can't show.
    /// A resumed install's choices are fixed, so its rows have no link.
    /// Choices that reduce protection, or delete the user's data, carry a
    /// caution.
    fn choice_rows(&self, cx: &App) -> Vec<AnyElement> {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let manifest = state.manifest();
        let options = state.effective_options();
        let editable = state.flow.may_edit();
        let mut rows = Vec::new();
        for (index, row) in choice_row_plan(state).into_iter().enumerate() {
            let (key, title) = if row.kind == ScreenKind::UpdatePath {
                ("choice-path".to_owned(), t!("summary-update-path"))
            } else {
                (format!("choice-{index}"), row.kind.title())
            };
            let kind = row.kind;
            let action = row.change.map(|screen| {
                Button::new(("change-choice", screen), t!("common-change"))
                    .hyperlink()
                    .compact()
                    .aria_label(t!("summary-change-a11y", title = title.as_str()))
                    .disabled(!editable)
                    .on_click(on_model(&model, move |m, cx| open_change(m, kind, screen, cx)))
                    .into_any_element()
            });
            let value = if row.kind == ScreenKind::UpdatePath {
                let path = match path_taken(state) {
                    UpdatePath::Keep => t!("update-path-keep"),
                    UpdatePath::ChooseAgain => t!("update-path-choose"),
                };
                detail_text(&key, path).into_any_element()
            } else {
                let chosen = chosen_on(manifest, &row.pages, &options, |option| {
                    ListEntry::install_option(&option.name, &option.text, state.before_desktop)
                });
                choice_value(
                    cx,
                    &key,
                    ("choices", index),
                    &title,
                    row.required,
                    chosen,
                    t!("summary-not-chosen"),
                )
            };
            rows.push(detail_row_with_action(cx, &key, title, value, action).into_any_element());
        }
        rows
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        self.log.render(LOG_IDS, 280., LOG_LINES_SHOWN, &state.attempt, cx)
    }
}

/// A row of the summary's choices: the screen whose choices it lists, or
/// how an update or reinstall treats them ([`ScreenKind::UpdatePath`]), and
/// the screen of Your choices its Change link opens, if it has one.
#[derive(Clone, Debug, PartialEq, Eq)]
struct ChoiceRow {
    kind: ScreenKind,
    pages: Vec<usize>,
    required: bool,
    change: Option<usize>,
}

/// The summary's rows of choices. An update or reinstall says first how it
/// treats them, with a link to its first screen; an unfinished install that
/// chose again says so too, without one, as it can't change. Then one row
/// per choice: keeping the choices, each is as this PC has it, so it has no
/// link; choosing again, each links to its screen after the first one. A
/// first install links each to its screen, unless its choices are fixed. An
/// unfinished update that will keep them links only the ones it asks.
fn choice_row_plan(state: &AppModel) -> Vec<ChoiceRow> {
    let update = state.update_choices().is_some();
    let choosing_again = state.choosing_again();
    let mut rows = Vec::new();
    if state.unfinished_choices().is_some_and(|choices| !choices.complete()) {
        let asked = state.option_screens();
        rows.extend(state.choice_screens().into_iter().map(|screen| ChoiceRow {
            change: asked.iter().position(|shown| shown.pages == screen.pages),
            kind: screen.kind,
            pages: screen.pages,
            required: screen.required,
        }));
        return rows;
    }
    if update || choosing_again {
        rows.push(ChoiceRow {
            kind: ScreenKind::UpdatePath,
            pages: Vec::new(),
            required: false,
            change: update.then_some(0),
        });
    }
    let (screens, first, links) = if update {
        (state.choice_screens(), 1, choosing_again)
    } else {
        (state.option_screens(), 0, state.locked_options().is_none())
    };
    rows.extend(screens.into_iter().enumerate().map(|(index, screen)| ChoiceRow {
        kind: screen.kind,
        pages: screen.pages,
        required: screen.required,
        change: links.then_some(first + index),
    }));
    rows
}

/// Follows the Change link of the summary's row of `kind`, which opens
/// `screen` of Your choices. How Atlas updates goes through Your choices
/// again from its first screen, as its answer decides which screens follow:
/// every one when choosing again, and those this PC can't show when keeping
/// the choices. Continue from any other row's screen comes back here.
fn open_change(m: &mut AppModel, kind: ScreenKind, screen: usize, cx: &mut gpui::Context<AppModel>) {
    if kind == ScreenKind::UpdatePath {
        m.set_step(Step::Options, cx);
    } else {
        m.edit_options(screen, cx);
    }
}

/// How the summary says the install treats the choices: as this flow chose,
/// or, for an unfinished install, as it began.
fn path_taken(state: &AppModel) -> UpdatePath {
    if state.choosing_again() { UpdatePath::ChooseAgain } else { UpdatePath::Keep }
}

/// The options among `options` that the screen showing `pages` has chosen,
/// each as `entry` lists it. A page shown only once another option is
/// chosen counts only then.
pub(super) fn chosen_on<T>(
    manifest: &Manifest,
    pages: &[usize],
    options: &[String],
    entry: impl Fn(&FeatureOption) -> T,
) -> Vec<T> {
    pages
        .iter()
        .filter_map(|&page_index| manifest.pages.get(page_index))
        .filter(|page| page.depends_on.as_ref().is_none_or(|dependency| options.contains(dependency)))
        .flat_map(|page| page.options.iter())
        .filter(|option| options.contains(&option.name))
        .map(entry)
        .collect()
}

/// A row's value in a list of choices, keyed like its row: a required
/// choice's answer, with its caution, or `unmade` when there is none; or the
/// extras chosen, in list `list`, or None.
pub(super) fn choice_value(
    cx: &App,
    key: &str,
    list: (&'static str, usize),
    title: &str,
    required: bool,
    chosen: Vec<ListEntry>,
    unmade: String,
) -> AnyElement {
    if required {
        let (text, caution) = match chosen.into_iter().next() {
            Some(ListEntry { text, caution }) => (text, caution),
            None => (unmade, None),
        };
        div()
            .flex()
            .flex_col()
            .gap(px(2.))
            .min_w_0()
            .child(detail_text(key, text))
            .when_some(caution, |this, caution| {
                this.child(caution_caption(cx, detail_text(&format!("{key}-caution"), caution)))
            })
            .into_any_element()
    } else if chosen.is_empty() {
        div()
            .text_color(cx.theme().text_secondary)
            .child(detail_text(key, t!("common-none")))
            .into_any_element()
    } else {
        plain_list(cx, list, title, chosen).w_full().into_any_element()
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
fn preflight_action(problem: &Preflight, state: &AppModel, model: &gpui::Entity<AppModel>) -> Option<Button> {
    Some(match preflight_fix(problem)? {
        PreflightFix::Options => Button::new("install-back-options", t!("go-to-options"))
            .on_click(on_model(model, |m, cx| m.set_step(Step::Options, cx))),
        PreflightFix::StartOver => start_over_button("install-start-over", state, model),
        PreflightFix::Ready => go_to_ready_button("install-back-ready", model),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::test_harness::run_model_test;
    use crate::pages::testing::{NO_TELEMETRY, installed_model, records};
    use crate::services::atlas_state::{InstallIdentity, InstallMode, Unfinished};
    use crate::services::legacy_choices::Facts;
    use crate::services::requirements::CheckDetail;
    use crate::services::test_support::TempDir;

    /// The rows' kinds and the screen each Change link opens.
    fn plan(m: &AppModel) -> Vec<(ScreenKind, Option<usize>)> {
        choice_row_plan(m).into_iter().map(|row| (row.kind, row.change)).collect()
    }

    /// An update or reinstall says first how it treats the choices. Keeping
    /// them, only that row can be changed, as every other choice is the
    /// PC's; choosing again, each row opens its own screen after the first.
    #[test]
    fn the_summary_says_how_atlas_updates_and_links_only_what_can_change() {
        use ScreenKind::{Defender, Extras, Keyboard, Mitigations, Updates};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-rows");
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("Mitigations", 1), ("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, _| {
                let choices = [Defender, Mitigations, Updates, Keyboard, Extras];
                assert!(m.update_choices().unwrap().complete());
                let keeping: Vec<_> = std::iter::once((ScreenKind::UpdatePath, Some(0)))
                    .chain(choices.iter().map(|kind| (*kind, None)))
                    .collect();
                assert_eq!(plan(m), keeping);
                m.update_path = UpdatePath::ChooseAgain;
                let choosing: Vec<_> = std::iter::once((ScreenKind::UpdatePath, Some(0)))
                    .chain(choices.iter().enumerate().map(|(index, kind)| (*kind, Some(index + 1))))
                    .collect();
                assert_eq!(plan(m), choosing);
                // An option screen per row, Change opening the one its row lists.
                let screens = m.option_screens();
                for (kind, change) in plan(m) {
                    assert_eq!(screens[change.unwrap()].kind, kind);
                }

                // A first install has no such row, and links every choice.
                m.install_identity = Ok(InstallIdentity::Fresh);
                let first: Vec<_> =
                    choices.iter().enumerate().map(|(index, kind)| (*kind, Some(index))).collect();
                assert_eq!(plan(m), first);
                // An unfinished install that chose again says so, and nothing can change.
                let unfinished = Unfinished {
                    held: Some(vec!["defender-enable".into()]),
                    choose_again: true,
                    mode: InstallMode::Reapply,
                };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
                m.update_path = UpdatePath::Keep;
                let resumed: Vec<_> = std::iter::once((ScreenKind::UpdatePath, None))
                    .chain(choices.iter().map(|kind| (*kind, None)))
                    .collect();
                assert_eq!(plan(m), resumed);
                assert_eq!(path_taken(m), UpdatePath::ChooseAgain, "as it began, whatever this flow has");
                m.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
                assert_eq!(path_taken(m), UpdatePath::Keep);
            });
        });
    }

    /// An unfinished update that will keep the choices, with nothing held
    /// yet, lists every one as keeping them does and links only the one this
    /// PC can't show; with every one shown, none.
    #[test]
    fn an_unfinished_update_that_keeps_the_choices_links_only_what_it_asks() {
        use ScreenKind::{Defender, Extras, Keyboard, Mitigations, Updates};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-unfinished-keep");
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, _| {
                let unfinished = Unfinished { held: None, choose_again: false, mode: InstallMode::Upgrade };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
                assert_eq!(
                    plan(m),
                    [
                        (Defender, None),
                        (Mitigations, Some(0)),
                        (Updates, None),
                        (Keyboard, None),
                        (Extras, None)
                    ]
                );
                m.pc_facts.toggles.insert("Mitigations".into(), 1);
                let none: Vec<_> = [Defender, Mitigations, Updates, Keyboard, Extras]
                    .iter()
                    .map(|kind| (*kind, None))
                    .collect();
                assert_eq!(plan(m), none, "nothing to ask");
            });
        });
    }

    /// How Atlas updates leads through Your choices again from its first
    /// screen, so neither the screens choosing again opens nor the one
    /// keeping the choices still asks is skipped on the way back to the
    /// summary. Any other row's screen returns straight there.
    #[test]
    fn changing_how_atlas_updates_goes_through_the_screens_its_answer_leads_to() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-path-change");
            // No record of processor protections, so keeping the choices asks it.
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, cx| {
                let at = |m: &AppModel| (m.flow.step, m.option_screens()[m.current_option_screen()].kind);
                assert_eq!(m.update_choices().unwrap().missing, [ScreenKind::Mitigations]);
                m.flow.resume(Step::Install).unwrap();
                open_change(m, ScreenKind::UpdatePath, 0, cx);
                assert_eq!(at(m), (Step::Options, ScreenKind::UpdatePath));
                m.next_step(cx);
                assert_eq!(at(m), (Step::Options, ScreenKind::Mitigations), "what keeping still asks");

                m.flow.resume(Step::Install).unwrap();
                open_change(m, ScreenKind::UpdatePath, 0, cx);
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                m.next_step(cx);
                assert_eq!(at(m), (Step::Options, ScreenKind::Defender), "every screen, choosing again");

                m.flow.resume(Step::Install).unwrap();
                open_change(m, ScreenKind::Mitigations, 2, cx);
                assert_eq!(at(m), (Step::Options, ScreenKind::Mitigations));
                m.next_step(cx);
                assert!(m.flow.step > Step::Options, "back towards the summary: {:?}", m.flow.step);
            });
        });
    }

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
