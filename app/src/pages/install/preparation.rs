//! How Windows and Microsoft Store updating stands on Get ready: the run,
//! the restart it may ask for and how it ended, as one [`RunView`]. The
//! update row in the checklist shows it, with the driver choice under it,
//! except while Windows moves to a newer release: then the move's own card
//! shows it, and the row waits for the move. Updating starts by itself, so
//! the view says how it stands, and what to do only when something needs
//! the user: trouble, a restart, or a stop to resume.

use std::sync::atomic::Ordering;

use gpui::{
    AnyElement, App, Context, Entity, FocusHandle, IntoElement, ParentElement, PromptLevel, Role, Styled,
    Window, div, prelude::*, px,
};

use super::ready::{ChecklistRow, Mark, row_note, row_text, status_line};
use super::{InstallPage, details_toggle};
use crate::i18n::describe::{self, Outcome};
use crate::i18n::fmt;
use crate::model::{AppModel, Page, RestoreStatus, StopQuestion};
use crate::pages::{detail_text, on_model};
use crate::services::preparation::{self, Activity, Progress, RestartProblem, Stage, State};
use crate::services::requirements::{CheckId, Verdict};
use crate::services::system::links;
use crate::services::update_access::BlockerKind;
use crate::t;
use crate::theme::{ActiveTheme, Theme};
use crate::ui::{Button, Icon, ProgressBar, Typography, link_row};

/// The longest worker message shown inline; the job folder keeps its full log.
const FAILURE_DETAIL_MAX_CHARS: usize = 2000;
/// A progress report this old (seconds) is said to be late.
const REPORT_DELAYED_SECONDS: u64 = 15;
/// Progress unchanged this long (seconds) is said to be unchanged.
const UNCHANGED_SECONDS: u64 = 60;
/// Storage in Windows Settings, where space is freed up.
const STORAGE_SETTINGS: &str = "ms-settings:storagesense";
/// Services, where a service Windows Update needs is turned back on.
const SERVICES: &str = "services.msc";
/// A Store app can't update while it's open.
const ERROR_PACKAGES_IN_USE: &str = "0x80073D02";

/// What the main button does in the current state. The label and the click
/// both come from it, so the button never says one thing and does another.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum PrepareAction {
    /// A stop was asked for; it happens at the next safe point.
    Stopping,
    /// The restart is being saved or made.
    Restarting,
    Stop,
    Restart,
    /// Carry on after Atlas's own restart, which happens by itself unless
    /// something holds Get ready back.
    Continue,
    /// Run again after updating failed or couldn't connect.
    Retry,
    /// The user stopped updating; it waits for them to resume it.
    Resume,
    /// Not started; Get ready starts it by itself.
    Start,
}

impl PrepareAction {
    fn of(preparation: &State, stop_requested: bool, held: bool) -> Self {
        match preparation {
            _ if preparation.busy() && stop_requested => Self::Stopping,
            State::SavingRestart | State::Restarting => Self::Restarting,
            _ if preparation.busy() => Self::Stop,
            State::Reboot => Self::Restart,
            State::Resumed => Self::Continue,
            State::Failed | State::Network | State::RestartPersists { .. } => Self::Retry,
            State::Cancelled => Self::Resume,
            State::Idle if held => Self::Resume,
            _ => Self::Start,
        }
    }

    fn label(self) -> String {
        match self {
            Self::Stopping => t!("iso-cancelling"),
            Self::Restarting | Self::Restart => t!("restart-now"),
            Self::Stop => t!("prepare-stop"),
            Self::Continue => t!("prepare-continue"),
            Self::Retry => t!("common-try-again"),
            Self::Resume => t!("ready-updates-resume"),
            Self::Start => t!("ready-updates-start"),
        }
    }

    /// Whether the button starts the next thing to do rather than stopping
    /// or waiting, so it can be the page's accent button.
    fn moves_on(self) -> bool {
        matches!(self, Self::Restart | Self::Continue | Self::Retry | Self::Resume | Self::Start)
    }
}

/// How a run that ended in trouble is put right, which decides its one
/// main button: trying again, or something else that trying again can't
/// replace.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Remedy {
    /// Try again, or the state's own main button.
    Retry,
    /// Reinstall Windows from an Atlas ISO: nothing on this Windows helps.
    Reinstall,
    /// The Atlas team needs to look: Send a report.
    Report,
    /// Put back the Windows Update settings Atlas changed.
    PutBack,
    /// Free up space; Atlas reads it again by itself and carries on.
    Space,
    /// Restart, then try again by itself after sign-in.
    RestartFirst,
    /// Run Microsoft Store's repairs again.
    RepairStore,
    /// Nothing in this window helps, as when Atlas Manager runs from a
    /// linked folder: the message says what to do.
    None,
}

impl Remedy {
    fn of(state: &AppModel, failure: Option<&Activity>, put_back_failed: bool) -> Self {
        let reason = failure.and_then(|failure| failure.reason.as_deref());
        if state.preparation == State::Failed && state.preparation_source_linked {
            return Self::None;
        }
        if put_back_failed {
            return Self::PutBack;
        }
        match reason {
            Some("feature-hardware" | "feature-managed" | "feature-servicing") => Self::Reinstall,
            Some("feature-components-lost" | "feature-journal" | "feature-pin") => Self::Report,
            Some("feature-build") => Self::PutBack,
            Some("feature-disk-space") => Self::Space,
            _ if state.store_repair_failed() => Self::RepairStore,
            _ if failure.is_some_and(describe::component_store_unrepairable) => Self::Reinstall,
            _ if failure.is_some_and(describe::component_store_still_damaged) => Self::RestartFirst,
            _ => Self::Retry,
        }
    }
}

/// How updating stands, as the update row or the move's card shows it: a
/// leading mark, one status line, and what unfolds under it.
pub(super) struct RunView {
    pub mark: Mark,
    /// How it stands, or what happened.
    pub status: String,
    /// Read after the name: what the line under the status says.
    pub description: Option<String>,
    pub below: Vec<AnyElement>,
    /// The action at the row's trailing edge, while one runs.
    pub trailing: Option<AnyElement>,
}

impl InstallPage {
    /// How updating stands. `with_help` puts the help row under a failure;
    /// `accent` lets the view's main button be the page's accent;
    /// `action_focus` is that button's, and `later_focus` is Not now's,
    /// which takes focus during the countdown.
    pub(super) fn run_view(
        &self,
        with_help: bool,
        accent: bool,
        action_focus: FocusHandle,
        later_focus: FocusHandle,
        cx: &Context<Self>,
    ) -> RunView {
        let theme = cx.theme();
        let state = self.model.read(cx);
        // A move that stopped for what a check now reports as well: the
        // check says it, with its fix, so this says only that the move waits.
        if state.move_outcome_held_by_check() {
            return RunView {
                mark: Mark::Pending,
                status: t!("windows-starts-after-checks"),
                description: None,
                below: Vec::new(),
                trailing: None,
            };
        }
        let failure = state.preparation_progress.as_ref().and_then(|p| p.failure());
        let stop_requested = state.preparation_cancel.load(Ordering::Relaxed);
        // A move between Windows releases under way or chosen, and the words
        // its outcomes need.
        let request = state.transition_request();
        let release = request.as_ref().map(|request| request.target_release.clone()).unwrap_or_default();
        let version = state.manifest().version.clone();
        let current = state.system.display_version.clone();
        let words = describe::TransitionWords { release: &release, current: &current, version: &version };
        // Not offered is a wait: while Atlas looks again by itself it says
        // so, and once the wait ends, that the settings went back, or not.
        let waiting = state.offer_wait_shown();
        let wait_ended = state.offer_wait.is_some_and(|wait| wait.expired);
        let not_offered = failure.is_some_and(Activity::not_offered);
        let put_back_error = match &state.restore_status {
            RestoreStatus::Failed(error) if state.transition_open() => Some(error.clone()),
            _ => None,
        };
        let outcome: Option<Outcome> = failure
            .and_then(|failure| describe::transition_outcome(failure, &words))
            .map(|outcome| match () {
                _ if wait_ended && not_offered => Outcome {
                    title: t!("windows-wait-ended-title", release = release.as_str()),
                    body: if put_back_error.is_some() {
                        t!("windows-wait-put-back-failed")
                    } else {
                        t!("windows-wait-ended")
                    },
                },
                _ => outcome,
            });
        let unconfirmed =
            state.preparation == State::Failed && failure.is_none() && state.preparation_error.is_none();
        let restart_reasons = state
            .preparation_progress
            .as_ref()
            .map(|progress| progress.activity.restart_reasons.as_slice())
            .unwrap_or(&[]);
        let finishing = |id: &str| restart_reasons.iter().any(|reason| reason == id);
        let held = state.updates_held();
        let countdown = state.preparation_countdown();
        let commit_failed =
            state.preparation == State::Reboot && state.preparation_problem == Some(RestartProblem::Commit);
        // What the status line says: how updating stands, in a line.
        let status = match &state.preparation {
            State::Running { .. } if stop_requested => t!("footer-prepare-stopping-stage"),
            _ if waiting => t!("windows-waiting", release = release.as_str()),
            State::Idle if held => t!("ready-updates-stopped"),
            State::Idle => t!("ready-updates-pending"),
            State::Resumed => t!("ready-updates-resumed"),
            State::SavingRestart => t!("prepare-saving-restart"),
            State::Restarting => t!("ready-updates-restarting"),
            // Microsoft Store turned off: only Windows was updated.
            State::Ready if state.store_outcome() == Some(preparation::StoreOutcome::SkippedRemoved) => {
                t!("ready-updates-done-windows")
            }
            State::Ready => t!("ready-updates-done"),
            // Windows couldn't get ready for the restart: the restart is
            // still what's next, so it's no failure.
            State::Reboot if commit_failed => t!("windows-commit-failed-title"),
            State::Reboot if state.preparation_problem.is_some() => t!("ready-updates-restart-failed"),
            State::Reboot => match countdown {
                Some(seconds) => t!("ready-updates-restart-countdown", seconds = seconds),
                // The card's title names the release a move installed; only a
                // second restart to finish it says so again.
                None if finishing(preparation::FEATURE_COMMIT) => {
                    t!("ready-updates-restart-finish", release = release.as_str())
                }
                None => t!("ready-updates-restart"),
            },
            State::RestartPersists { .. } => t!("ready-updates-restart-persists"),
            State::Network => t!("ready-updates-network"),
            // A run that ended without a report isn't called a failure.
            State::Failed if unconfirmed => t!("prepare-unconfirmed-title"),
            State::Failed => outcome
                .as_ref()
                .map(|outcome| outcome.title.clone())
                .or_else(|| failure.and_then(describe::preparation_failure_title))
                .unwrap_or_else(|| t!("prepare-failed-title")),
            State::Cancelled => t!("ready-updates-stopped"),
            State::WaitingExternal => t!("ready-updates-previous"),
            State::Running { stage, .. } => stage_status(*stage),
        };
        // What happened, said under the status: then what to do.
        let message = match &state.preparation {
            _ if waiting => None,
            State::Reboot => state.preparation_problem.map(|problem| match problem {
                RestartProblem::Save => t!("prepare-restart-save-failed"),
                RestartProblem::Registration => t!("prepare-restart-registration-failed"),
                RestartProblem::SourceLinked => t!("prepare-restart-source-linked"),
                RestartProblem::Commit => t!("windows-commit-failed"),
                RestartProblem::Restart => t!("prepare-restart-failed"),
            }),
            State::RestartPersists { .. } => Some(t!("ready-updates-restart-persists-advice")),
            State::Failed if state.preparation_source_linked => Some(t!("prepare-failed-source-linked")),
            State::Failed => {
                Some(outcome.as_ref().map(|outcome| outcome.body.clone()).unwrap_or_else(|| {
                    describe::preparation_failure(failure, state.preparation_error.is_some())
                }))
            }
            State::Network => Some(describe::preparation_network(
                state.preparation_progress.as_ref().and_then(|p| p.activity.network_reason.as_deref()),
            )),
            _ => None,
        };
        let busy = state.preparation.busy();
        let action = PrepareAction::of(&state.preparation, stop_requested, held);
        let remedy = Remedy::of(state, failure, put_back_error.is_some());
        let reason = failure.and_then(|failure| failure.reason.as_deref());
        let unavailable = (!busy).then(|| unavailable_reason(state)).flatten();
        let blocked = unavailable.is_some() || !state.preparation_may_start() || !state.elevated;
        let enabled = match action {
            PrepareAction::Stopping | PrepareAction::Restarting => false,
            PrepareAction::Stop => true,
            PrepareAction::Restart
            | PrepareAction::Continue
            | PrepareAction::Retry
            | PrepareAction::Resume
            | PrepareAction::Start => !blocked,
        };
        let label = match action {
            PrepareAction::Restart if commit_failed => t!("common-try-again"),
            PrepareAction::Retry if remedy == Remedy::RepairStore => t!("prepare-repair-store-again"),
            _ => action.label(),
        };
        // Hidden where it can't work: Get ready starts updating by itself,
        // and continues after a restart by itself, unless something holds it
        // back, which the caption under the status names. While Atlas waits
        // for the offer, the looks carry on by themselves, and stopping asks
        // first; a remedy other than trying again replaces it.
        let main_button = (enabled
            && !matches!(action, PrepareAction::Start | PrepareAction::Continue)
            && !waiting
            && (action != PrepareAction::Retry || matches!(remedy, Remedy::Retry | Remedy::RepairStore))
            && state.preparation != State::WaitingExternal)
            .then(|| {
                Button::new("prepare-action", label)
                    .focus_handle(action_focus.clone())
                    .when(action.moves_on() && accent, Button::accent)
                    .when(action == PrepareAction::Restart && !commit_failed, |button| {
                        button.icon(Icon::Power)
                    })
                    .on_click(cx.listener(|this, _, _, cx| {
                        // The run this starts is the user's: how it ends is
                        // announced, even when it ends as the last one did.
                        this.preparation_asked = true;
                        this.model.update(cx, |m, cx| {
                            let stop_requested = m.preparation_cancel.load(Ordering::Relaxed);
                            match PrepareAction::of(&m.preparation, stop_requested, m.updates_held()) {
                                PrepareAction::Stopping | PrepareAction::Restarting | PrepareAction::Stop => {
                                    m.preparation_cancel.store(true, Ordering::Relaxed)
                                }
                                PrepareAction::Restart => m.restart_preparation(cx),
                                PrepareAction::Continue
                                | PrepareAction::Retry
                                | PrepareAction::Resume
                                | PrepareAction::Start => m.prepare_windows(cx),
                            }
                            cx.notify();
                        });
                    }))
            });
        // The remedy's own button, when trying again isn't it.
        let can_iso = state.can_navigate(Page::Iso);
        let remedy_button = match remedy {
            Remedy::Reinstall => can_iso.then(|| iso_button("prepare-iso", &self.model, accent)),
            Remedy::Report => state.can_navigate(Page::Report).then(|| {
                Button::new("prepare-report", t!("report-title"))
                    .when(accent, Button::accent)
                    .on_click(on_model(&self.model, |m, cx| m.navigate(Page::Report, cx)))
            }),
            Remedy::PutBack => Some(
                Button::new("prepare-put-back", t!("home-put-back"))
                    .when(accent, Button::accent)
                    .disabled(!state.may_restore_update_access())
                    .on_click(on_model(&self.model, |m, cx| m.restore_update_access(cx))),
            ),
            Remedy::Space => Some(
                Button::new("prepare-storage", t!("check-fix-storage"))
                    .when(accent, Button::accent)
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(STORAGE_SETTINGS),
            ),
            Remedy::RestartFirst => Some(
                Button::new("prepare-restart-retry", t!("prepare-restart-and-retry"))
                    .when(accent, Button::accent)
                    .icon(Icon::Power)
                    .disabled(blocked)
                    .on_click(on_model(&self.model, |m, cx| m.restart_to_retry(cx))),
            ),
            Remedy::Retry | Remedy::RepairStore | Remedy::None => None,
        }
        .filter(|_| state.preparation == State::Failed);
        // Where Windows lets the user resolve what stopped updating.
        let page_hidden = state.update_access.as_ref().is_some_and(|access| access.page_hidden);
        let shortcut = match &state.preparation {
            State::Network => Some(("prepare-network", t!("prepare-network-settings"), links::NETWORK)),
            State::RestartPersists { .. } => {
                Some(("prepare-open-windows-update", t!("check-fix-windows-update"), links::WINDOWS_UPDATE))
            }
            // A service Windows Update needs: Services; another setting
            // Atlas didn't change: Windows Update's page, unless it's hidden.
            State::Failed if reason == Some("feature-blocked") => {
                match failure.and_then(|failure| failure.setting.as_deref()).and_then(describe::service_name)
                {
                    Some(_) => Some(("prepare-open-services", t!("prepare-open-services"), SERVICES)),
                    None => (!page_hidden).then(|| {
                        ("prepare-open-windows-update", t!("check-fix-windows-update"), links::WINDOWS_UPDATE)
                    }),
                }
            }
            State::Failed if reason.is_some() || remedy != Remedy::Retry => None,
            // An app left open is closed, not looked for in Microsoft Store.
            State::Failed
                if failure
                    .and_then(|failure| failure.error_code.as_deref())
                    .is_some_and(|code| code.eq_ignore_ascii_case(ERROR_PACKAGES_IN_USE)) =>
            {
                None
            }
            State::Failed => match state.preparation_progress.as_ref().map(|p| p.stage) {
                Some(
                    Stage::StoreSearch | Stage::StoreSelfUpdate | Stage::StoreInstall | Stage::StoreRepair,
                ) => Some((
                    "prepare-open-store",
                    t!("prepare-open-store"),
                    "ms-windows-store://downloadsandupdates",
                )),
                Some(
                    Stage::WindowsSearch
                    | Stage::WindowsDownload
                    | Stage::WindowsInstall
                    | Stage::WindowsRepair,
                ) => Some((
                    "prepare-open-windows-update",
                    t!("check-fix-windows-update"),
                    links::WINDOWS_UPDATE,
                )),
                Some(Stage::Verify) | None => None,
            },
            _ => None,
        };
        // After a wait that ended: reinstalling Windows is the other way on.
        let wait_iso = (wait_ended && not_offered && put_back_error.is_none() && can_iso)
            .then(|| iso_button("prepare-iso", &self.model, false));
        let now = chrono::Utc::now().timestamp().max(0) as u64;
        let stalled = matches!(state.preparation, State::Running { .. })
            && state.preparation_progress.as_ref().is_some_and(|progress| stall(progress, now).is_some());
        let job = state.preparation_job.clone();
        let log_link = |id: &'static str| {
            job.clone().map(|job| {
                Button::new(id, t!("iso-diagnostics"))
                    .hyperlink()
                    .compact()
                    .on_click(move |_, _, cx| cx.reveal_path(&job))
            })
        };
        // While Atlas waits for the offer, stopping is the one choice; it
        // asks first, as Cancel does, as it puts the settings back.
        let stop_waiting = waiting.then(|| {
            let model = self.model.clone();
            Button::new("prepare-stop-waiting", t!("prepare-stop"))
                .disabled(stop_requested)
                .on_click(move |_, window, cx| ask_to_stop_waiting(&model, window, cx))
        });

        let mut below: Vec<AnyElement> = Vec::new();
        let mut trailing: Option<AnyElement> = None;
        let mark;
        match &state.preparation {
            // Waiting for Windows Update to offer the release, in a run or
            // between looks: one bar, what to expect, and how long so far,
            // with Stop updating at the trailing edge as while it runs.
            _ if waiting => {
                mark = Mark::Busy;
                below.push(
                    ProgressBar::new("preparation-progress", status.clone(), None).live().into_any_element(),
                );
                below.push(
                    div()
                        .id("preparation-wait")
                        .flex()
                        .flex_wrap()
                        .gap_x(px(4.))
                        .type_body()
                        .text_color(theme.text_secondary)
                        .child(detail_text("preparation-wait-detail", t!("windows-waiting-detail")))
                        .when_some(state.offer_waited_minutes(), |this, minutes| {
                            this.child(detail_text(
                                "preparation-wait-waited",
                                t!("windows-waited", minutes = minutes),
                            ))
                        })
                        .into_any_element(),
                );
                trailing = stop_waiting.map(IntoElement::into_any_element);
            }
            State::Failed | State::Network | State::RestartPersists { .. } => {
                mark = if wait_ended && not_offered {
                    Mark::Note
                } else if unconfirmed
                    || state.preparation == State::Network
                    || matches!(remedy, Remedy::Space)
                    || reason == Some("feature-blocked")
                {
                    Mark::Warning
                } else {
                    Mark::Error
                };
                below.extend(message.clone().map(|message| row_text("preparation-message", message, cx)));
                let actions = div()
                    .flex()
                    .flex_wrap()
                    .gap(px(8.))
                    .children(remedy_button)
                    .children(main_button)
                    .children(wait_iso)
                    .when_some(shortcut, |row, (id, label, target)| {
                        row.child(Button::new(id, label).trailing_icon(Icon::OpenInNewWindow).opens(target))
                    });
                below.push(actions.into_any_element());
                below.extend(unavailable.map(|reason| row_note("preparation-unavailable", reason, cx)));
                // The raw worker message, its code, the error putting the
                // settings back and what Windows still reports a restart for
                // are for troubleshooting.
                let detail = match &state.preparation {
                    State::Failed => failure
                        .and_then(|f| f.failure_message.as_ref())
                        .or(state.preparation_error.as_ref())
                        .map(|detail| detail.chars().take(FAILURE_DETAIL_MAX_CHARS).collect::<String>()),
                    State::RestartPersists { reasons } => Some(t!(
                        "ready-updates-restart-persists-reasons",
                        reasons = describe::restart_reasons(reasons)
                    )),
                    _ => None,
                };
                let code = failure
                    .and_then(|f| f.error_code.as_ref())
                    .map(|code| t!("prepare-error-code", code = code.clone()));
                // A Store the repairs can't mend leaves reinstalling Windows.
                let reinstall = (remedy == Remedy::RepairStore).then(|| {
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(8.))
                        .child(row_text("preparation-store-iso", t!("prepare-store-broken-iso"), cx))
                        .when(can_iso, |this| {
                            this.child(div().flex().child(iso_button("prepare-iso", &self.model, false)))
                        })
                        .into_any_element()
                });
                if detail.is_some() || code.is_some() || put_back_error.is_some() || reinstall.is_some() {
                    below.push(self.failure_details(detail, code, put_back_error.clone(), reinstall, cx));
                }
                if with_help {
                    let log = job.clone().filter(|_| state.preparation == State::Failed);
                    below.push(self.diagnostics.content_with_log(&self.model, log, cx).into_any_element());
                }
            }
            State::Reboot => {
                // A restart updating asks for is the plan, not a problem; nor
                // is one Windows couldn't get ready for, which Try again makes.
                mark = if state.preparation_problem.is_some() && !commit_failed {
                    Mark::Error
                } else {
                    Mark::Note
                };
                below.extend(
                    message.clone().map(|message| row_text("preparation-restart-problem", message, cx)),
                );
                // The restart starts as soon as the button is chosen, or the
                // countdown ends, so the warning to save work comes first.
                below.push(row_note("preparation-save-work", t!("ready-updates-restart-save"), cx));
                let not_now = countdown.is_some().then(|| {
                    Button::new("prepare-not-now", t!("restart-dont-now"))
                        .focus_handle(later_focus)
                        // Focus starts here, so Enter doesn't restart; Restart now is the
                        // accent, and the ring shows only after a key press, as elsewhere.
                        .on_click(on_model(&self.model, |m, cx| m.decline_preparation_restart(cx)))
                });
                below.push(
                    div()
                        .id("preparation-restart-actions")
                        .role(Role::Group)
                        // Entering the group reads how long is left.
                        .aria_label(status.clone())
                        .flex()
                        .flex_wrap()
                        .gap(px(8.))
                        .children(main_button)
                        .children(not_now)
                        .into_any_element(),
                );
                below.extend(unavailable.map(|reason| row_note("preparation-unavailable", reason, cx)));
            }
            State::Running { stage, .. } => {
                mark = Mark::Busy;
                // One bar that never goes backwards. Most stages report their
                // progress one update or package at a time, so a bar that
                // followed them would start over; it sweeps instead. Store
                // apps report one share for all the apps a search found, which
                // only grows until the next search, so their bar shows it, as
                // the package download does.
                let share = match (stage, state.preparation_progress.as_ref()) {
                    (Stage::StoreInstall, Some(progress)) => {
                        progress.activity.percent.map(|percent| percent.min(100) as f32 / 100.)
                    }
                    _ => None,
                };
                below.push(
                    ProgressBar::new("preparation-progress", status.clone(), share).live().into_any_element(),
                );
                below.extend(
                    stage_detail(*stage).map(|detail| row_note("preparation-stage-detail", detail, cx)),
                );
                if let Some(progress) = state.preparation_progress.as_ref() {
                    below.extend(
                        stall_note(progress, now).map(|note| row_note("preparation-activity", note, cx)),
                    );
                    if stalled {
                        below.extend(
                            log_link("prepare-log").map(|link| link_row().child(link).into_any_element()),
                        );
                    }
                    let figures = running_figures(progress, theme);
                    if !figures.is_empty() {
                        below.push(self.running_details(figures, cx));
                    }
                }
                trailing = main_button.map(IntoElement::into_any_element);
            }
            State::WaitingExternal => {
                mark = Mark::Busy;
                below.push(
                    ProgressBar::new("preparation-progress", status.clone(), None).live().into_any_element(),
                );
                below.extend(log_link("prepare-log").map(|link| link_row().child(link).into_any_element()));
            }
            State::SavingRestart | State::Restarting => {
                mark = Mark::Busy;
            }
            State::Ready => {
                mark = Mark::Done;
                // What the finished run did about Microsoft Store itself,
                // where that changes what to expect.
                if let Some(note) = state.store_outcome().and_then(describe::store_outcome) {
                    below.push(row_note("preparation-store-outcome", note, cx));
                }
            }
            State::Idle | State::Cancelled | State::Resumed => {
                mark = if state.preparation == State::Resumed { Mark::Busy } else { Mark::Pending };
                // Before anything runs: each Windows Update setting Atlas
                // turns on for the update, and that it comes back.
                below.extend(access_notice(state, &version, cx));
                below.extend(unavailable.map(|reason| row_note("preparation-unavailable", reason, cx)));
                trailing = main_button.map(IntoElement::into_any_element);
            }
        }
        RunView { mark, status, description: message, below, trailing }
    }

    /// The update row. `run` is how updating stands, or `None` while the
    /// move's card shows it and the row waits for the move. `focus` is the
    /// row's, for when how updating ended is news.
    pub(super) fn preparation_row(
        &self,
        run: Option<RunView>,
        drivers: AnyElement,
        focus: Option<FocusHandle>,
        cx: &Context<Self>,
    ) -> AnyElement {
        let view = run.unwrap_or_else(|| {
            let state = self.model.read(cx);
            let release =
                state.transition_request().map(|request| request.target_release).unwrap_or_default();
            RunView {
                mark: Mark::Pending,
                status: t!("ready-updates-after-move", release = release.as_str()),
                description: None,
                below: Vec::new(),
                trailing: None,
            }
        });
        let mut below = view.below;
        below.push(drivers);
        let title = t!("ready-updates-title");
        ChecklistRow {
            id: "preparation-status",
            mark: view.mark,
            name: t!("check-a11y", title = title.as_str(), state = view.status.as_str()),
            title,
            status: status_line("preparation", view.status, None, cx),
            description: view.description,
            action: view.trailing,
            below,
            divided: true,
            focus,
            heading: None,
        }
        .render(cx)
    }

    /// What else may help with a failure, then its raw details, behind Show
    /// details.
    fn failure_details(
        &self,
        detail: Option<String>,
        code: Option<String>,
        put_back_error: Option<String>,
        more: Option<AnyElement>,
        cx: &Context<Self>,
    ) -> AnyElement {
        let shown = self.show_preparation_details;
        div()
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(link_row().child(details_toggle(
                "preparation-details",
                t!("ready-updates-title"),
                shown,
                |page| &mut page.show_preparation_details,
                cx,
            )))
            .when(shown, |this| {
                this.children(more.map(|more| div().pt(px(4.)).pb(px(8.)).child(more))).child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .type_caption()
                        .text_color(cx.theme().text_secondary)
                        .when_some(detail, |this, detail| {
                            this.child(detail_text("preparation-failure-detail", detail))
                        })
                        .when_some(code, |this, code| this.child(detail_text("preparation-error-code", code)))
                        .when_some(put_back_error, |this, error| {
                            this.child(detail_text("preparation-put-back-error", error))
                        }),
                )
            })
            .into_any_element()
    }

    /// What a running update reports beyond its stage, behind Show details:
    /// the update in hand and its figures.
    fn running_details(&self, figures: Vec<AnyElement>, cx: &Context<Self>) -> AnyElement {
        let shown = self.show_preparation_details;
        div()
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(link_row().child(details_toggle(
                "preparation-details",
                t!("ready-updates-title"),
                shown,
                |page| &mut page.show_preparation_details,
                cx,
            )))
            .when(shown, |this| this.children(figures))
            .into_any_element()
    }
}

/// Create an Atlas ISO, for reinstalling this PC's Windows.
fn iso_button(id: &'static str, model: &Entity<AppModel>, accent: bool) -> Button {
    Button::new(id, t!("iso-open"))
        .when(accent, Button::accent)
        .on_click(on_model(model, |m, cx| m.navigate_iso_for_this_pc(cx)))
}

/// Asks before stopping a move that waits for the offer: stopping puts the
/// settings back and ends the setup, as Cancel does.
fn ask_to_stop_waiting(model: &Entity<AppModel>, window: &mut Window, cx: &mut App) {
    let (question, title) = {
        let state = model.read(cx);
        (state.move_stop_question(), super::stop_title(state))
    };
    let StopQuestion::BeforeMove { current } = question else {
        return;
    };
    let message = t!("stop-update-before", current = current);
    let (keep, stop) = (t!("stop-update-keep"), t!("prepare-stop"));
    let answer =
        window.prompt(PromptLevel::Warning, &title, Some(&message), &[keep.as_str(), stop.as_str()], cx);
    let model = model.clone();
    cx.spawn(async move |cx| {
        if answer.await == Ok(1) {
            model.update(cx, |model, cx| model.stop_waiting_for_offer(cx));
        }
    })
    .detach();
}

/// A running stage, as a verb phrase that ends in an ellipsis.
fn stage_status(stage: Stage) -> String {
    match stage {
        Stage::WindowsSearch | Stage::Verify => t!("prepare-windows-search"),
        Stage::WindowsDownload => t!("prepare-windows-download"),
        Stage::WindowsInstall => t!("prepare-windows-install"),
        Stage::WindowsRepair => t!("prepare-windows-repairing"),
        Stage::StoreSearch => t!("prepare-store-search"),
        Stage::StoreSelfUpdate => t!("prepare-store-updating"),
        Stage::StoreInstall => t!("prepare-store-install"),
        Stage::StoreRepair => t!("prepare-store-repairing"),
    }
}

/// What a stage that reports no progress of its own says under its bar:
/// why it runs, and how long it can take.
fn stage_detail(stage: Stage) -> Option<String> {
    match stage {
        Stage::WindowsRepair => Some(t!("prepare-windows-repair-detail")),
        Stage::StoreRepair => Some(t!("prepare-store-repair-detail")),
        _ => None,
    }
}

/// Why updating can't start, or carry on, by itself now, if something holds
/// it back that the page doesn't show already.
fn unavailable_reason(state: &AppModel) -> Option<String> {
    // Every check that can stop updating has reported when the build check has.
    let failed_check = |id: CheckId| {
        state.checks.iter().any(|(check, result)| {
            *check == id && result.as_ref().is_some_and(|result| result.verdict != Verdict::Pass)
        })
    };
    let handled_build = state.checks.iter().any(|(check, result)| {
        *check == CheckId::SupportedBuild
            && result.as_ref().is_some_and(|result| state.handled_by_preparation(result))
    });
    if state.install_block().is_some() {
        Some(t!("ready-updates-blocked"))
    } else if failed_check(CheckId::SupportedBuild) && !handled_build {
        Some(t!("ready-updates-needs-windows"))
    } else if state.driver_choice_required() {
        Some(t!("ready-updates-needs-drivers"))
    } else if !state.elevated {
        Some(t!("ready-updates-needs-admin"))
    } else {
        None
    }
}

/// The Windows Update settings Atlas will turn on for this run, one line
/// per kind, with when they come back: as they were, whoever set them.
/// Nothing when none hold updates back.
pub(super) fn access_notice(state: &AppModel, version: &str, cx: &App) -> Option<AnyElement> {
    let access = state.update_access.as_ref()?;
    if access.blockers.is_empty() || access.journal.is_some() || state.preparation.ready() {
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
    lines.push(t!("access-back", version = version));
    lines.push(t!("access-back-stop"));
    let theme = cx.theme();
    Some(
        div()
            .id("preparation-access")
            .role(Role::Group)
            .aria_label(t!("access-notice-title"))
            .flex()
            .flex_col()
            .gap(px(2.))
            .child(div().type_body_strong().text_color(theme.text_primary).child(t!("access-notice-title")))
            .children(lines.into_iter().enumerate().map(|(index, line)| {
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(detail_text(&format!("preparation-access-{index}"), line))
            }))
            .into_any_element(),
    )
}

/// Whether updating that ended needs the user: trouble to retry, or a
/// restart to make. Focus goes to it when that's news.
pub(super) fn needs_user(state: &State) -> bool {
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

/// A repair of Windows' component store reports no progress at all, which
/// its stage says, so it never looks stuck while its reports keep coming.
fn repairing(progress: &Progress) -> bool {
    progress.stage == Stage::WindowsRepair
}

fn stall(progress: &Progress, now: u64) -> Option<Stall> {
    let age = progress.report_age(now);
    if age >= REPORT_DELAYED_SECONDS {
        Some(Stall::Silent(age))
    } else if progress.activity.unchanged_seconds >= UNCHANGED_SECONDS
        && !waiting_for_offer(progress)
        && !repairing(progress)
    {
        Some(Stall::Unchanged(progress.activity.unchanged_seconds))
    } else {
        None
    }
}

/// What a running update says under its bar when reports are late or
/// progress stands still, in whole minutes at most: never a ticking clock.
fn stall_note(progress: &Progress, now: u64) -> Option<String> {
    match stall(progress, now)? {
        Stall::Silent(_) => Some(t!("prepare-report-late")),
        Stall::Unchanged(seconds) => Some(t!("prepare-progress-still", minutes = seconds / 60)),
    }
}

/// The figures a running update reports: the update in hand, its share of
/// the stage, the count of updates and the bytes downloaded. No clock: how
/// long it has taken says nothing about how long is left.
fn running_figures(progress: &Progress, theme: &Theme) -> Vec<AnyElement> {
    let activity = &progress.activity;
    let mut figures = Vec::new();
    if let Some(title) = &activity.current_update {
        figures.push(detail_text("preparation-update", title.clone()));
    }
    if let Some(percent) = activity.percent {
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
    figures
        .into_iter()
        .map(|figure| div().type_caption().text_color(theme.text_secondary).child(figure).into_any_element())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_preparation_button_is_labelled_with_what_a_click_does() {
        // A restart that's due is offered as one, with or without permission yet.
        assert_eq!(PrepareAction::of(&State::Reboot, false, false), PrepareAction::Restart);
        let running = State::Running { stage: Stage::WindowsDownload, completed: 0, total: 1 };
        assert_eq!(PrepareAction::of(&running, false, false), PrepareAction::Stop);
        assert_eq!(PrepareAction::of(&running, true, false), PrepareAction::Stopping);
        assert_eq!(PrepareAction::of(&State::SavingRestart, false, false), PrepareAction::Restarting);
        // Trouble is retried; the first run starts by itself.
        for trouble in [State::Failed, State::Network, State::RestartPersists { reasons: vec![] }] {
            assert_eq!(PrepareAction::of(&trouble, false, false), PrepareAction::Retry, "{trouble:?}");
        }
        assert_eq!(PrepareAction::of(&State::Idle, false, false), PrepareAction::Start);
        assert_eq!(PrepareAction::of(&State::Resumed, false, false), PrepareAction::Continue);
        // A stop the user made waits for them, also once a choice started updating over.
        assert_eq!(PrepareAction::of(&State::Cancelled, false, true), PrepareAction::Resume);
        assert_eq!(PrepareAction::of(&State::Idle, false, true), PrepareAction::Resume);
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

    /// A late report is said without a count of seconds, which would tick.
    #[test]
    fn a_late_report_is_said_without_a_ticking_clock() {
        crate::i18n::testing::english(|| {
            let progress: Progress = serde_json::from_value(serde_json::json!({
                "schema": 1, "status": "running", "stage": "windows-download", "completed": 0, "total": 1,
                "updatedAt": 1000
            }))
            .unwrap();
            let early = stall_note(&progress, 1000 + REPORT_DELAYED_SECONDS);
            let later = stall_note(&progress, 1000 + REPORT_DELAYED_SECONDS + 7);
            assert!(early.is_some());
            assert_eq!(early, later, "the words don't change as the seconds pass");
        });
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

    #[test]
    fn a_component_store_repair_without_progress_is_not_a_stall() {
        let progress: Progress = serde_json::from_value(serde_json::json!({
            "schema": 1, "status": "running", "stage": "windows-repair", "completed": 0, "total": 0,
            "updatedAt": 1000, "activity": { "unchangedSeconds": 1200 }
        }))
        .unwrap();
        assert_eq!(stall(&progress, 1001), None, "reports keep coming while DISM works");
        assert_eq!(
            stall(&progress, 1000 + REPORT_DELAYED_SECONDS),
            Some(Stall::Silent(REPORT_DELAYED_SECONDS))
        );
    }

    /// Every running stage is said as a verb phrase ending in an ellipsis,
    /// as a progress bar's label is.
    #[test]
    fn every_stage_is_a_progress_label() {
        crate::i18n::testing::english(|| {
            for stage in [
                Stage::WindowsSearch,
                Stage::WindowsDownload,
                Stage::WindowsInstall,
                Stage::WindowsRepair,
                Stage::StoreSearch,
                Stage::StoreSelfUpdate,
                Stage::StoreInstall,
                Stage::StoreRepair,
                Stage::Verify,
            ] {
                assert!(stage_status(stage).ends_with('…'), "{stage:?}: {}", stage_status(stage));
            }
        });
    }
}
