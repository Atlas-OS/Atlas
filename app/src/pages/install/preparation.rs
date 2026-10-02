//! Step 1's update card: the Windows and Microsoft Store updates an install
//! needs first, and the restart they may ask for. Trouble and the restart
//! show as a bar in the card, with what to do about them beside it.

use std::sync::atomic::Ordering;

use gpui::{AnyElement, Context, FocusHandle, IntoElement, ParentElement, Styled, div, prelude::*, px};

use super::{InstallPage, details_toggle};
use crate::i18n::{describe, fmt};
use crate::model::{Page, RestoreStatus};
use crate::pages::{card_body, detail_text, on_model, step_card_header};
use crate::services::preparation::{self, Activity, Progress, RestartProblem, Stage, State};
use crate::services::requirements::{CheckId, Verdict};
use crate::services::system::links;
use crate::services::update_access::BlockerKind;
use crate::services::windows_release::TransitionNeed;
use crate::t;
use crate::theme::{ActiveTheme, Theme};
use crate::ui::{Button, InfoBar, ProgressBar, Severity, Typography, a11y_text, card};

/// The longest worker message shown inline; the job folder keeps its full log.
const FAILURE_DETAIL_MAX_CHARS: usize = 2000;
/// A progress report this old (seconds) is said to be delayed.
const REPORT_DELAYED_SECONDS: u64 = 15;
/// Progress unchanged this long (seconds) is said to be unchanged.
const UNCHANGED_SECONDS: u64 = 60;
/// The elapsed time shows from this many seconds on; before that it's noise.
const ELAPSED_SHOWN_SECONDS: u64 = 60;

/// What the card's main button does in the current state. The label and the
/// click both come from it, so the button never says one thing and does another.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum PrepareAction {
    /// A stop was asked for; it happens at the next safe point.
    Stopping,
    /// The restart is being saved or made.
    Restarting,
    Stop,
    Restart,
    Continue,
    /// Run again after updating failed or couldn't connect.
    Retry,
    Start,
}

impl PrepareAction {
    fn of(preparation: &State, stop_requested: bool) -> Self {
        match preparation {
            _ if preparation.busy() && stop_requested => Self::Stopping,
            State::SavingRestart | State::Restarting => Self::Restarting,
            _ if preparation.busy() => Self::Stop,
            State::Reboot => Self::Restart,
            State::Resumed => Self::Continue,
            State::Failed | State::Network | State::RestartPersists { .. } => Self::Retry,
            _ => Self::Start,
        }
    }

    fn label(self) -> String {
        match self {
            Self::Stopping => t!("iso-cancelling"),
            Self::Restarting | Self::Restart => t!("prepare-restart"),
            Self::Stop => t!("prepare-stop"),
            Self::Continue => t!("prepare-continue"),
            Self::Retry => t!("common-try-again"),
            Self::Start => t!("prepare-start"),
        }
    }

    /// Whether the button starts the next thing to do rather than stopping
    /// or waiting, so it can be the page's accent button.
    fn moves_on(self) -> bool {
        matches!(self, Self::Restart | Self::Continue | Self::Retry | Self::Start)
    }
}

impl InstallPage {
    /// The update card. `with_help` puts the diagnostics under a failure;
    /// `focus` is for the bar it shows when updating needs the user.
    pub(super) fn preparation_card(
        &self,
        with_help: bool,
        focus: FocusHandle,
        action_focus: FocusHandle,
        cx: &Context<Self>,
    ) -> AnyElement {
        let theme = cx.theme();
        let state = self.model.read(cx);
        let failure = state.preparation_progress.as_ref().and_then(|p| p.failure());
        let stop_requested = state.preparation_cancel.load(Ordering::Relaxed);
        // A move between Windows releases under way or chosen, and the words
        // its outcomes need.
        let request = state.transition_request();
        let release = request.as_ref().map(|request| request.target_release.clone()).unwrap_or_default();
        let moving = request.as_ref().is_some_and(|request| state.system.build != request.target_build);
        let version = state.manifest().version.clone();
        let current = state.system.display_version.clone();
        let words = describe::TransitionWords { release: &release, current: &current, version: &version };
        // Not offered is a wait: while Atlas looks again by itself it says so,
        // and once the wait ends, that the settings went back, or why not.
        let wait_ended = state.offer_wait.is_some_and(|wait| wait.expired);
        let put_back_failed = match &state.restore_status {
            RestoreStatus::Failed(error) if wait_ended => Some(error.clone()),
            _ => None,
        };
        let outcome =
            failure.and_then(|failure| describe::transition_failure(failure, &words)).map(|outcome| {
                if wait_ended && failure.is_some_and(Activity::not_offered) {
                    match &put_back_failed {
                        Some(error) => t!(
                            "prepare-offer-wait-put-back-failed",
                            release = release.as_str(),
                            error = error.as_str()
                        ),
                        None => t!("prepare-offer-wait-ended", release = release.as_str()),
                    }
                } else if state.offer_rechecks_active() {
                    format!("{outcome} {}", t!("prepare-offer-rechecking"))
                } else if failure.is_some_and(Activity::not_offered) {
                    format!("{outcome} {}", t!("prepare-offer-check-again"))
                } else {
                    outcome
                }
            });
        let reason = failure.and_then(|failure| failure.reason.as_deref()).filter(|_| outcome.is_some());
        let not_offered = failure.is_some_and(Activity::not_offered);
        let store_repair_failed = state.store_repair_failed();
        let restart_reasons = state
            .preparation_progress
            .as_ref()
            .map(|progress| progress.activity.restart_reasons.as_slice())
            .unwrap_or(&[]);
        let finishing = |id: &str| restart_reasons.iter().any(|reason| reason == id);
        // While Atlas waits for the offer, the live progress node keeps one
        // name between looks and during them, so only a change is announced;
        // the clock beside it moves on unannounced.
        let waiting_name = t!("prepare-not-offered-title", release = release.as_str());
        // Two sentences side by side, spaced by the layout rather than a typed
        // space, which some scripts don't put between sentences.
        let clock = state.offer_wait_clock().map(|clock| {
            let next = match clock.next_check_minutes {
                Some(minutes) => t!("prepare-offer-next-check", minutes = minutes),
                None => t!("prepare-offer-checking-now"),
            };
            div()
                .id("preparation-wait-clock")
                .flex()
                .flex_wrap()
                .gap_x(px(4.))
                .type_caption()
                .text_color(theme.text_secondary)
                .child(detail_text(
                    "preparation-wait-waited",
                    t!("prepare-offer-waited", minutes = clock.waited_minutes),
                ))
                .child(detail_text("preparation-wait-next", next))
        });
        let message = match &state.preparation {
            State::Idle if moving => t!("prepare-description-transition", release = release.as_str()),
            State::Idle => t!("prepare-description"),
            // After the restart that installs the new version, or after one for
            // the updates that come before it.
            State::Resumed if request.is_some() && state.transition_installed() => {
                t!("prepare-resumed-transition", release = release.as_str())
            }
            State::Resumed if request.is_some() => {
                t!("prepare-resumed-before-move", release = release.as_str())
            }
            State::Resumed => t!("prepare-resumed"),
            State::SavingRestart => t!("prepare-saving-restart"),
            State::Ready => t!("prepare-complete"),
            State::Reboot | State::Restarting if finishing(preparation::FEATURE_COMMIT) => {
                t!("prepare-reboot-commit", release = release.as_str())
            }
            State::Reboot | State::Restarting if finishing(preparation::FEATURE_UPDATE) => {
                t!("prepare-reboot-transition", release = release.as_str())
            }
            State::Reboot | State::Restarting => {
                let reasons = restart_reasons;
                if reasons.is_empty() {
                    t!("prepare-reboot")
                } else {
                    t!("prepare-reboot-reasons", reasons = describe::restart_reasons(reasons))
                }
            }
            State::RestartPersists { reasons } => {
                t!("prepare-restart-persists", reasons = describe::restart_reasons(reasons))
            }
            State::Failed => outcome
                .clone()
                .unwrap_or_else(|| describe::preparation_failure(failure, state.preparation_error.is_some())),
            State::Cancelled => t!("prepare-cancelled"),
            State::Network => describe::preparation_network(
                state.preparation_progress.as_ref().and_then(|p| p.activity.network_reason.as_deref()),
            ),
            State::WaitingExternal => t!("prepare-previous-worker"),
            State::Running { stage, .. } => match stage {
                Stage::WindowsSearch | Stage::Verify if state.offer_wait_running() => waiting_name.clone(),
                Stage::WindowsSearch | Stage::Verify => t!("prepare-windows-search"),
                Stage::WindowsDownload => t!("prepare-windows-download"),
                Stage::WindowsInstall => t!("prepare-windows-install"),
                Stage::StoreSearch => t!("prepare-store-search"),
                Stage::StoreSelfUpdate => t!("prepare-store-self-update"),
                Stage::StoreInstall => t!("prepare-store-install"),
                Stage::StoreRepair => t!("prepare-store-repair"),
            },
        };
        let busy = state.preparation.busy();
        let action = PrepareAction::of(&state.preparation, stop_requested);
        let page_hidden = state.update_access.as_ref().is_some_and(|access| access.page_hidden);
        // Where Windows lets the user resolve what stopped preparation.
        let shortcut = match &state.preparation {
            State::Network => {
                Some(("prepare-network", t!("prepare-network-settings"), "ms-settings:network"))
            }
            State::RestartPersists { .. } => {
                Some(("prepare-open-windows-update", t!("check-fix-windows-update"), links::WINDOWS_UPDATE))
            }
            // Windows Update settings Atlas didn't change: their page, unless
            // a setting hides it.
            State::Failed if reason == Some("feature-blocked") => (!page_hidden).then(|| {
                ("prepare-open-windows-update", t!("check-fix-windows-update"), links::WINDOWS_UPDATE)
            }),
            State::Failed if reason.is_some() || store_repair_failed => None,
            State::Failed => match state.preparation_progress.as_ref().map(|p| p.stage) {
                Some(
                    Stage::StoreSearch | Stage::StoreSelfUpdate | Stage::StoreInstall | Stage::StoreRepair,
                ) => Some((
                    "prepare-open-store",
                    t!("prepare-open-store"),
                    "ms-windows-store://downloadsandupdates",
                )),
                Some(Stage::WindowsSearch | Stage::WindowsDownload | Stage::WindowsInstall) => Some((
                    "prepare-open-windows-update",
                    t!("check-fix-windows-update"),
                    links::WINDOWS_UPDATE,
                )),
                Some(Stage::Verify) | None => None,
            },
            _ => None,
        };
        // Why the action is unavailable, beside it rather than only at the
        // top of the page. Relaunching lives with Permission to install.
        let failed_check = |id: CheckId| {
            state.checks.iter().any(|(check, result)| {
                *check == id && result.as_ref().is_some_and(|result| result.verdict != Verdict::Pass)
            })
        };
        let handled_build = state.checks.iter().any(|(check, result)| {
            *check == CheckId::SupportedBuild
                && result.as_ref().is_some_and(|result| state.handled_by_preparation(result))
        });
        let unavailable = if busy {
            None
        } else if state.install_block().is_some() {
            Some(t!("prepare-blocked-source"))
        } else if failed_check(CheckId::SupportedBuild) && !handled_build {
            Some(t!("prepare-needs-build-check", check = CheckId::SupportedBuild.title()))
        } else if moving && state.transition_chosen() && !state.windows_terms_accepted {
            Some(t!("prepare-needs-terms", release = release.as_str()))
        } else if !state.elevated {
            Some(t!("prepare-needs-build-check", check = CheckId::Administrator.title()))
        } else {
            None
        };
        let blocked = unavailable.is_some() || !state.preparation_may_start() || !state.elevated;
        let enabled = match action {
            PrepareAction::Stopping | PrepareAction::Restarting => false,
            PrepareAction::Stop => true,
            PrepareAction::Restart
            | PrepareAction::Continue
            | PrepareAction::Retry
            | PrepareAction::Start => !blocked,
        };
        // The current task's button is the accent one: once there is a
        // package, and while updating is what's left, or something to retry.
        let accent = enabled
            && action.moves_on()
            && (action != PrepareAction::Start || state.playbook.is_some())
            && state.preparation != State::Ready;
        let label = match action {
            PrepareAction::Start if moving => t!("prepare-start-transition", release = release.as_str()),
            PrepareAction::Retry if not_offered => t!("prepare-check-again"),
            // Trying again runs the repairs again.
            PrepareAction::Retry if store_repair_failed => t!("prepare-repair-store"),
            _ => action.label(),
        };
        // Trying again can't help when Windows was rebuilt, the record can't
        // be read or an organisation manages updates; a report or putting the
        // settings back can.
        let retry_useless = matches!(
            reason,
            Some(
                "feature-components-lost"
                    | "feature-journal"
                    | "feature-managed"
                    | "feature-build"
                    | "feature-hardware"
            )
        );
        let main_button = Button::new("prepare-action", label)
            .focus_handle(action_focus)
            .when(accent, Button::accent)
            .disabled(!enabled)
            .on_click(on_model(&self.model, |m, cx| {
                let stop_requested = m.preparation_cancel.load(Ordering::Relaxed);
                match PrepareAction::of(&m.preparation, stop_requested) {
                    PrepareAction::Stopping | PrepareAction::Restarting | PrepareAction::Stop => {
                        m.preparation_cancel.store(true, Ordering::Relaxed)
                    }
                    PrepareAction::Restart => m.restart_preparation(cx),
                    PrepareAction::Continue | PrepareAction::Retry | PrepareAction::Start => {
                        m.prepare_windows(cx)
                    }
                }
                cx.notify();
            }));
        let now = chrono::Utc::now().timestamp().max(0) as u64;
        let stalled = matches!(state.preparation, State::Running { .. })
            && state.preparation_progress.as_ref().is_some_and(|progress| stall(progress, now).is_some());
        // The job folder helps only where something may be wrong.
        let log_folder = state
            .preparation_job
            .clone()
            .filter(|_| stalled || matches!(state.preparation, State::Failed | State::WaitingExternal))
            .map(|job| {
                Button::new("prepare-log", t!("iso-diagnostics"))
                    .on_click(move |_, _, cx| cx.reveal_path(&job))
            });
        // What else an outcome of the move offers: keeping a version that may
        // stay, a fresh install from an Atlas ISO, or putting the settings back.
        let optional = state.windows_transition().is_some_and(|(_, need)| need == TransitionNeed::Optional);
        let keep = (not_offered && optional && !state.transition_open()).then(|| {
            Button::new("prepare-keep-version", t!("prepare-keep-version", current = current.as_str()))
                .on_click(on_model(&self.model, |m, cx| m.set_windows_transition(true, cx)))
        });
        let iso = (matches!(reason, Some("feature-hardware")) || not_offered)
            .then(|| state.can_navigate(Page::Iso))
            .filter(|offered| *offered)
            .map(|_| {
                Button::new("prepare-iso", t!("iso-open"))
                    .on_click(on_model(&self.model, |m, cx| m.navigate_iso_for_this_pc(cx)))
            });
        let put_back = (matches!(reason, Some("feature-build")) || put_back_failed.is_some()).then(|| {
            Button::new("prepare-put-back", t!("home-put-back"))
                .disabled(!state.may_restore_update_access())
                .on_click(on_model(&self.model, |m, cx| m.restore_update_access(cx)))
        });
        // Between looks, stopping is a choice beside Check again, as Cancel offers it.
        let stop = (not_offered && state.offer_rechecks_active()).then(|| {
            let model = self.model.clone();
            Button::new("prepare-stop-waiting", t!("prepare-stop")).on_click(move |_, window, cx| {
                let (question, version) = {
                    let state = model.read(cx);
                    (state.stop_question(), state.manifest().version.clone())
                };
                if let Some(question) = question {
                    super::ask_to_stop_updating(&model, question, &version, window, cx);
                }
            })
        });
        let actions = div()
            .flex()
            .flex_wrap()
            .gap(px(8.))
            .when(state.preparation != State::WaitingExternal && !retry_useless, |row| row.child(main_button))
            .children(stop)
            .children(put_back)
            .children(keep)
            .children(iso)
            .when_some(shortcut, |row, (id, label, target)| row.child(Button::new(id, label).opens(target)))
            .children(log_folder);
        let caption = |id: &str, text: String| {
            div().type_caption().text_color(theme.text_secondary).child(detail_text(id, text))
        };

        let mut body = card_body().gap(px(12.));
        match &state.preparation {
            State::Failed | State::Network | State::RestartPersists { .. } => {
                // The raw worker message and its code are for troubleshooting.
                let detail = failure
                    .and_then(|f| f.failure_message.as_ref())
                    .or(state.preparation_error.as_ref())
                    .map(|detail| detail.chars().take(FAILURE_DETAIL_MAX_CHARS).collect::<String>())
                    .filter(|_| state.preparation == State::Failed);
                let code = failure
                    .and_then(|f| f.error_code.as_ref())
                    .map(|code| t!("prepare-error-code", code = code.clone()));
                let has_details = detail.is_some() || code.is_some();
                let shown = self.show_preparation_details;
                let details = has_details.then(|| {
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(4.))
                        .child(div().flex().child(details_toggle(
                            "preparation-details",
                            t!("prepare-title"),
                            shown,
                            |page| &mut page.show_preparation_details,
                            cx,
                        )))
                        .when(shown, |this| {
                            this.child(
                                div()
                                    .flex()
                                    .flex_col()
                                    .gap(px(2.))
                                    .type_caption()
                                    .when_some(detail, |this, detail| {
                                        this.child(detail_text("preparation-failure-detail", detail))
                                    })
                                    .when_some(code, |this, code| {
                                        this.child(detail_text("preparation-error-code", code))
                                    }),
                            )
                        })
                });
                // A run that ended without a report isn't called a failure.
                let unconfirmed = state.preparation == State::Failed
                    && failure.is_none()
                    && state.preparation_error.is_none();
                let (severity, title) = if unconfirmed {
                    (Severity::Warning, t!("prepare-unconfirmed-title"))
                } else if not_offered && wait_ended {
                    (
                        Severity::Informational,
                        t!("prepare-offer-wait-ended-title", release = release.as_str()),
                    )
                } else if not_offered {
                    (Severity::Informational, t!("prepare-not-offered-title", release = release.as_str()))
                } else if outcome.is_some() && state.preparation == State::Failed {
                    (Severity::Error, t!("prepare-transition-failed-title", release = release.as_str()))
                } else {
                    (Severity::Error, t!("prepare-failed-title"))
                };
                // Waiting between looks: the progress node and the clock, so the
                // wait never looks frozen.
                let waiting = (not_offered && state.offer_rechecks_active()).then(|| {
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(4.))
                        .child(ProgressBar::new("preparation-progress", waiting_name.clone(), None).live())
                        .children(clock)
                });
                let details = match (waiting, details) {
                    (Some(waiting), Some(details)) => {
                        Some(div().flex().flex_col().gap(px(8.)).child(waiting).child(details))
                    }
                    (Some(waiting), None) => Some(waiting),
                    (None, details) => details,
                };
                let bar = InfoBar::new(severity, title, message)
                    .id("preparation-status")
                    .focus_handle(focus)
                    .action(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(8.))
                            .w_full()
                            .child(actions)
                            .when_some(unavailable, |this, reason| {
                                this.child(caption("preparation-unavailable", reason))
                            }),
                    );
                body = body.child(match details {
                    Some(details) => bar.content(details),
                    None => bar,
                });
                if with_help {
                    body = body.child(self.diagnostics.content(&self.model, cx));
                }
            }
            State::Reboot => {
                let problem = state.preparation_problem.map(|problem| match problem {
                    RestartProblem::Save => t!("prepare-restart-save-failed"),
                    RestartProblem::Registration => t!("prepare-restart-registration-failed"),
                    RestartProblem::Commit => t!("prepare-restart-commit-failed", release = release.as_str()),
                    RestartProblem::Restart => t!("prepare-restart-failed"),
                });
                // The restart starts as soon as the button is chosen, so the
                // warning to save work comes first, as plainly as the rest.
                let severity = if problem.is_some() { Severity::Error } else { Severity::Warning };
                let bar =
                    InfoBar::new(severity, t!("prepare-reboot-title"), message)
                        .id("preparation-status")
                        .focus_handle(focus)
                        .action(
                            div()
                                .flex()
                                .flex_col()
                                .gap(px(8.))
                                .w_full()
                                .child(div().type_body().child(a11y_text(
                                    "preparation-save-work",
                                    t!("prepare-reboot-save-work"),
                                )))
                                .child(actions)
                                .when_some(unavailable, |this, reason| {
                                    this.child(caption("preparation-unavailable", reason))
                                }),
                        );
                body = body.child(match problem {
                    Some(problem) => bar
                        .content(div().type_body().child(a11y_text("preparation-restart-problem", problem))),
                    None => bar,
                });
            }
            _ => {
                body = body.child(div().child(a11y_text("preparation-status", message.clone())));
                // What the finished run did about Microsoft Store itself.
                if let Some(outcome) = state.store_outcome() {
                    body = body.child(caption("preparation-store-outcome", describe::store_outcome(outcome)));
                }
                // Before anything runs: each Windows Update setting Atlas
                // turns on for the update, and that it comes back.
                if let Some(notice) =
                    access_notice(state, &version).filter(|_| !busy && !state.preparation.ready())
                {
                    body = body.child(notice);
                }
                if busy {
                    let value = state.preparation_progress.as_ref().and_then(|p| p.fraction()).or_else(
                        || match state.preparation {
                            State::Running { stage: Stage::StoreInstall, completed, total } if total > 0 => {
                                Some(completed as f32 / total as f32)
                            }
                            _ => None,
                        },
                    );
                    body = body
                        // The one live node while updating: its name is the stage.
                        .child(ProgressBar::new("preparation-progress", message, value).live())
                        .when_some(
                            state
                                .preparation_progress
                                .as_ref()
                                .filter(|_| matches!(state.preparation, State::Running { .. })),
                            |this, progress| {
                                this.children(running_details(
                                    progress,
                                    value.is_none(),
                                    now,
                                    release.as_str(),
                                    theme,
                                ))
                            },
                        )
                        .children(clock)
                        // Only once Stop was chosen: what stopping means.
                        .when(stop_requested && matches!(state.preparation, State::Running { .. }), |this| {
                            this.child(caption("preparation-stop-detail", t!("prepare-stop-description")))
                        });
                }
                body = body.child(actions).when_some(unavailable, |this, reason| {
                    this.child(caption("preparation-unavailable", reason))
                });
            }
        }
        card(cx)
            .child(step_card_header(cx, "preparation", t!("prepare-title"), None))
            .child(body)
            .into_any_element()
    }
}

/// The Windows Update settings Atlas will turn on for this run, one line
/// per kind, with when they come back. Nothing when none hold updates back.
fn access_notice(state: &crate::model::AppModel, version: &str) -> Option<InfoBar> {
    let access = state.update_access.as_ref()?;
    if access.blockers.is_empty() || access.journal.is_some() {
        return None;
    }
    let mut lines: Vec<String> = access
        .blockers
        .iter()
        .map(|blocker| match blocker.kind {
            BlockerKind::Off => t!("access-off"),
            BlockerKind::Paused => t!("access-paused"),
            BlockerKind::Delayed => t!("access-delayed"),
        })
        .collect();
    lines.push(if access.blockers.iter().any(|blocker| blocker.owned) {
        t!("access-back-chosen", version = version)
    } else {
        t!("access-back", version = version)
    });
    lines.push(t!("access-back-stop"));
    Some(
        InfoBar::new(Severity::Informational, t!("access-notice-title"), "")
            .id("preparation-access")
            .content(
                div().flex().flex_col().gap(px(4.)).children(
                    lines
                        .into_iter()
                        .enumerate()
                        .map(|(index, line)| detail_text(&format!("preparation-access-{index}"), line)),
                ),
            ),
    )
}

/// Whether the card shows `state` as a bar with its next button in it:
/// trouble to retry, or a restart to make.
pub(super) fn in_bar(state: &State) -> bool {
    matches!(state, State::Failed | State::Network | State::RestartPersists { .. } | State::Reboot)
}

/// Why a running update looks stuck, if it does.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Stall {
    /// No report has arrived for this many seconds.
    Silent(u64),
    /// Reports arrive, but progress hasn't moved for this many seconds.
    Unchanged(u64),
}

/// The worker is waiting for Windows Update to offer the new release, which
/// can take minutes and is not a stall while its reports keep coming.
fn waiting_for_offer(progress: &Progress) -> bool {
    progress.activity.waiting.as_deref() == Some("feature-offer")
}

fn stall(progress: &Progress, now: u64) -> Option<Stall> {
    let age = progress.report_age(now);
    if age >= REPORT_DELAYED_SECONDS {
        Some(Stall::Silent(age))
    } else if progress.activity.unchanged_seconds >= UNCHANGED_SECONDS && !waiting_for_offer(progress) {
        Some(Stall::Unchanged(progress.activity.unchanged_seconds))
    } else {
        None
    }
}

/// What a running update reports under its progress bar: the update in
/// hand, its figures, and a note when reports are late or progress stands
/// still. The percentage shows only when the bar can't, and the elapsed time
/// only after a minute.
fn running_details(
    progress: &Progress,
    indeterminate: bool,
    now: u64,
    release: &str,
    theme: &Theme,
) -> Vec<AnyElement> {
    let activity = &progress.activity;
    let mut details = Vec::new();
    if let Some(title) = &activity.current_update {
        details.push(detail_text("preparation-update", title.clone()).into_any_element());
    }
    // The figures are secondary to the stage and the update above them.
    let mut figures = Vec::new();
    if let Some(percent) = activity.percent.filter(|_| indeterminate) {
        figures.push(detail_text("preparation-percent", t!("prepare-percent", percent = percent)));
    }
    if progress.total > 0 && (activity.percent.is_some() || progress.stage == Stage::StoreInstall) {
        figures.push(detail_text(
            "preparation-count",
            t!("prepare-count", completed = progress.completed, total = progress.total),
        ));
    }
    if let (Some(done), Some(total)) = (activity.bytes_downloaded, activity.bytes_total.filter(|n| *n > 0)) {
        figures.push(detail_text(
            "preparation-bytes",
            t!("prepare-bytes", downloaded = fmt::megabytes_value(done), total = fmt::megabytes_value(total)),
        ));
    }
    let age = progress.report_age(now);
    let elapsed = activity.elapsed_seconds.map(|elapsed| elapsed.saturating_add(age));
    if let Some(elapsed) = elapsed.filter(|elapsed| *elapsed >= ELAPSED_SHOWN_SECONDS) {
        figures.push(detail_text(
            "preparation-elapsed",
            t!("prepare-elapsed", minutes = elapsed / 60, seconds = elapsed % 60),
        ));
    }
    if !figures.is_empty() {
        details.push(
            div()
                .flex()
                .flex_col()
                .gap(px(2.))
                .type_caption()
                .text_color(theme.text_secondary)
                .children(figures)
                .into_any_element(),
        );
    }
    let note = match stall(progress, now) {
        Some(Stall::Silent(seconds)) => Some(t!("prepare-report-delayed", seconds = seconds)),
        Some(Stall::Unchanged(seconds)) => Some(t!("prepare-progress-unchanged", minutes = seconds / 60)),
        None if waiting_for_offer(progress) => Some(t!("prepare-waiting-offer", release = release)),
        None if activity.percent.is_none() => Some(t!("prepare-progress-waiting")),
        None => None,
    };
    details.extend(note.map(|note| detail_text("preparation-activity", note).into_any_element()));
    details
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_preparation_button_is_labelled_with_what_a_click_does() {
        // A restart that's due is offered as one, with or without permission yet.
        assert_eq!(PrepareAction::of(&State::Reboot, false), PrepareAction::Restart);
        let running = State::Running { stage: Stage::WindowsDownload, completed: 0, total: 1 };
        assert_eq!(PrepareAction::of(&running, false), PrepareAction::Stop);
        assert_eq!(PrepareAction::of(&running, true), PrepareAction::Stopping);
        assert_eq!(PrepareAction::of(&State::SavingRestart, false), PrepareAction::Restarting);
        // Trouble is retried; the first run starts.
        for trouble in [State::Failed, State::Network, State::RestartPersists { reasons: vec![] }] {
            assert_eq!(PrepareAction::of(&trouble, false), PrepareAction::Retry, "{trouble:?}");
        }
        assert_eq!(PrepareAction::of(&State::Idle, false), PrepareAction::Start);
        assert_eq!(PrepareAction::of(&State::Resumed, false), PrepareAction::Continue);
        assert!(!PrepareAction::Stop.moves_on() && !PrepareAction::Stopping.moves_on());
    }

    #[test]
    fn a_running_update_is_called_stuck_only_after_a_while() {
        let mut progress: Progress = serde_json::from_value(serde_json::json!({
            "schema": 1, "status": "running", "stage": "windows-download", "completed": 0, "total": 1,
            "updatedAt": 1000
        }))
        .unwrap();
        assert_eq!(stall(&progress, 1000 + REPORT_DELAYED_SECONDS - 1), None);
        assert_eq!(
            stall(&progress, 1000 + REPORT_DELAYED_SECONDS),
            Some(Stall::Silent(REPORT_DELAYED_SECONDS))
        );
        progress.activity.unchanged_seconds = UNCHANGED_SECONDS;
        assert_eq!(stall(&progress, 1001), Some(Stall::Unchanged(UNCHANGED_SECONDS)));
        // A report that never said when it was written is not called late.
        progress.updated_at = 0;
        progress.activity.unchanged_seconds = 0;
        assert_eq!(stall(&progress, 1_000_000), None);
    }

    #[test]
    fn waiting_minutes_for_the_new_version_to_be_offered_is_not_a_stall() {
        let mut progress: Progress = serde_json::from_value(serde_json::json!({
            "schema": 1, "status": "running", "stage": "windows-search", "completed": 0, "total": 0,
            "updatedAt": 1000, "activity": { "waiting": "feature-offer", "unchangedSeconds": 300 }
        }))
        .unwrap();
        assert_eq!(stall(&progress, 1001), None, "reports keep coming while it waits");
        assert_eq!(
            stall(&progress, 1000 + REPORT_DELAYED_SECONDS),
            Some(Stall::Silent(REPORT_DELAYED_SECONDS))
        );
        progress.activity.waiting = None;
        assert_eq!(stall(&progress, 1001), Some(Stall::Unchanged(300)));
    }
}
