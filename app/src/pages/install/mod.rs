//! Install: a four-step flow. Get ready (checks and the package), choose
//! options, turn off Windows Security, install.
//!
//! Every action goes through the model's flow rules; the page only decides
//! what to show and which controls look enabled. All words come from the
//! message catalog at render time, from the model's semantic state.

mod options;
mod preparation;
mod ready;
mod security;
mod summary;

use std::rc::Rc;
use std::sync::atomic::Ordering;

use gpui::{
    AnyElement, App, Context, Entity, FocusHandle, IntoElement, Point, PromptLevel, Render, ScrollHandle,
    SharedString, Window, prelude::*,
};

use super::{CommandBar, LogIds, LogView, StepStatus, Stepper, on_model, page_frame};
use crate::model::{
    Acquisition, AppModel, ElevationProblem, ReadyStatus, ReleaseCheck, RunState, ScreenKind, Step,
    StopQuestion,
};
use crate::services::preparation::State as Preparation;
use crate::t;
use crate::ui::{Button, FocusHandles, Icon, InfoBar, ScrollbarState, Severity, focus_reveal};

const LOG_IDS: LogIds =
    LogIds { log: "install-log", hidden: "log-hidden", line: "log-line", copy: "log-copy", open: "log-open" };

/// Log lines drawn; older lines are in the file.
const LOG_LINES_SHOWN: usize = 500;

/// Closes the window as the caption Close button does, asking first.
pub type CloseHandler = Rc<dyn Fn(&mut Window, &mut App)>;

pub struct InstallPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    log: LogView,
    scrollbar: ScrollbarState,
    show_command: bool,
    /// The Install summary's details: the Atlas package, Windows, activation,
    /// what every Defender answer turns off, and the installation command.
    show_summary_details: bool,
    /// The raw words behind the Install step's bar: a refusal's error, or a
    /// finished attempt's error and log.
    show_result_details: bool,
    /// What the Change link just chosen on the Install step lists, so focus
    /// goes there once Your choices shows (see `InstallPage::change_focus`).
    change_target: Option<ScreenKind>,
    /// The passed checks on Get ready, folded into one line by default.
    show_passed_checks: bool,
    /// The raw details of an update failure, or a running update's figures.
    show_preparation_details: bool,
    /// The raw error of installation files that couldn't be prepared.
    show_package_details: bool,
    /// What a move to a newer Windows release removes, before its go-ahead.
    show_windows_details: bool,
    /// The driver choice's two answers, folded under its line by default.
    show_driver_choice: bool,
    /// Whether updating was under way last frame, to follow how it ended.
    preparation_was_busy: bool,
    /// The user chose the update row's button since updating was last
    /// seen idle, so the run it starts is theirs, not one of Atlas's looks.
    preparation_asked: bool,
    /// Updating was last seen idle waiting for the offer, with looks to come.
    offer_wait_shown: bool,
    /// The step and option screen drawn last frame, to reset scrolling and focus on a change.
    shown_step: Option<(Step, usize)>,
    /// The run drawn last frame, with the install it belongs to, so each
    /// result is brought into view once, a retry's too.
    shown_run: Option<(RunState, Option<String>)>,
    /// The last refusal of the final checks that was brought into view.
    shown_preflight_epoch: u64,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    focus: FocusHandles,
    diagnostics: super::Diagnostics,
    /// The shell's own close, so Cancel doesn't depend on where focus is.
    close: CloseHandler,
}

impl InstallPage {
    pub fn new(model: Entity<AppModel>, close: CloseHandler, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            log: LogView::default(),
            scrollbar: ScrollbarState::new(),
            show_command: false,
            show_summary_details: false,
            show_result_details: false,
            change_target: None,
            show_passed_checks: false,
            show_preparation_details: false,
            show_package_details: false,
            show_windows_details: false,
            show_driver_choice: false,
            preparation_was_busy: false,
            preparation_asked: false,
            offer_wait_shown: false,
            shown_step: None,
            shown_run: None,
            shown_preflight_epoch: 0,
            seen_visit: 0,
            focus: FocusHandles::default(),
            diagnostics: super::Diagnostics::new(cx),
            close,
        }
    }

    /// The stepper, which marks where the flow is. The current step takes
    /// focus when the step changes, so it's announced: on Your choices its
    /// name goes on with the questions showing (`current_name`).
    fn stepper(
        &self,
        current: Step,
        may_edit: bool,
        focus: FocusHandle,
        current_name: Option<String>,
        cx: &App,
    ) -> AnyElement {
        let state = self.model.read(cx);
        let model = self.model.clone();
        let mut stepper = Stepper::new("stepper", t!("stepper-label"))
            .current_focus(focus, current_name.map(Into::into))
            .on_select(move |index, _, cx| model.update(cx, |m, cx| m.set_step(Step::ALL[index], cx)));
        for step in Step::ALL {
            // Earlier steps can be gone back to; later ones can't be skipped to.
            let status = StepStatus::visited(step.index(), current.index(), state.step_satisfied(step));
            stepper = stepper.step(step.title(), status, step < current && may_edit);
        }
        stepper.into_any_element()
    }

    fn footer(&self, cx: &App) -> AnyElement {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let step = state.flow.step;
        let run = state.flow.run;
        let locked = state.locked();
        // Cancel asked preparation to stop; it does at the next safe point.
        let stopping = state.preparation.busy() && state.preparation_cancel.load(Ordering::Relaxed);

        let (wait, next_enabled): (Wait, bool) = match step {
            Step::Ready => match ready_hint(state, stopping) {
                Some(wait) => (wait, false),
                None => (Wait::none(), true),
            },
            Step::Options => (Wait::none(), true),
            // The bar or the list above says what is left to do, so the
            // footer only reads it with Continue.
            Step::Security => {
                if state.security_ok() {
                    (Wait::none(), true)
                } else if !state.security_fresh() {
                    (Wait::quiet(t!("footer-reading-security")), false)
                } else if state.security.counts().on > 0 {
                    (Wait::quiet(t!("footer-security-pending")), false)
                } else if !state.elevated {
                    (Wait::quiet(t!("security-unknown-unelevated-title")), false)
                } else {
                    (Wait::quiet(t!("footer-security-confirm")), false)
                }
            }
            Step::Install => {
                // What to do before choosing Install when it restarts the PC.
                // Why it's unavailable is the bar's to say, not the footer's.
                let restart = state.install_request().is_some_and(|request| request.restart);
                let hint = if state.can_install() && restart && !summary::retry_hidden(state) {
                    Wait::shown(t!("footer-install-ready"))
                } else {
                    Wait::none()
                };
                (hint, false)
            }
        };
        let Wait { reason: hint, shown } = wait;

        let cancel_disabled =
            stopping || (locked && !matches!(state.preparation, Preparation::Running { .. }));
        let on_cancel = {
            let model = model.clone();
            let close = self.close.clone();
            move |_: &gpui::ClickEvent, window: &mut Window, cx: &mut App| {
                // Cancel stops the countdown to a restart for updates first,
                // as Not now does, so no restart comes while a question is open.
                model.update(cx, |m, cx| m.decline_preparation_restart(cx));
                // Desktop setup has no Home to return to, so Cancel closes the
                // window, asking first as the caption Close button does.
                if model.read(cx).before_desktop && !model.read(cx).preparation.busy() {
                    close(window, cx);
                    return;
                }
                // Windows Update settings changed for the update are put back
                // on the way out; the user is told first.
                if let Some(question) = model.read(cx).stop_question() {
                    let title = stop_title(model.read(cx));
                    ask_to_stop_updating(&model, question, &title, window, cx);
                    return;
                }
                model.update(cx, |m, cx| {
                    if m.preparation.busy() {
                        m.preparation_cancel.store(true, Ordering::Relaxed);
                        cx.notify();
                    } else {
                        m.cancel_flow(cx);
                    }
                })
            }
        };
        let back = Button::new("flow-back", t!("common-back"))
            .disabled(step.previous().is_none() || locked)
            .on_click(on_model(&model, |m, cx| m.previous_step(cx)));
        let forward = match step {
            // The installing view covers this page while an install runs
            // and after it succeeds, so only a failed attempt is retried here.
            Step::Install => Button::new(
                "flow-install",
                if matches!(run, RunState::Finished(_)) {
                    t!("common-try-again")
                } else {
                    t!("button-install")
                },
            )
            // The one accent, unless the bar's own button is the next step.
            .when(!summary::bar_leads(state), Button::accent)
            .disabled(!state.can_install())
            // Read with the button, while it waits: why it can't be chosen yet.
            .when(!state.can_install() && !hint.is_empty(), |button| button.aria_description(hint.clone()))
            .on_click(on_model(&model, |m, cx| m.start_install(cx))),
            _ => Button::new(
                "flow-next",
                // Straight back to Install only while Windows Security still
                // passes; otherwise Continue stops there first.
                if step == Step::Options && state.returning_to_install && state.security_ok() {
                    t!("go-to-install")
                } else {
                    t!("common-next")
                },
            )
            .accent()
            .trailing_icon(Icon::ChevronRight)
            .disabled(!next_enabled || locked)
            .when((!next_enabled || locked) && !hint.is_empty(), |button| {
                button.aria_description(hint.clone())
            })
            .on_click(on_model(&model, |m, cx| m.next_step(cx))),
        };

        // Try again is left out while the result's own button is the fix.
        let forward = (step != Step::Install || !summary::retry_hidden(state)).then_some(forward);
        CommandBar::new()
            .cancel("flow-cancel", t!("common-cancel"), cancel_disabled, on_cancel)
            .hint(if shown { hint } else { String::new() })
            .back(back)
            .when_some(forward, CommandBar::primary)
            .into_any_element()
    }
}

/// Why a step's Continue waits, which it reads as its description while it
/// can't be chosen, and whether the footer shows it too. It shows only what
/// the page doesn't already say: status lives in one place, so a row, a
/// caption or a bar that says it keeps it.
#[derive(Clone, Debug, PartialEq, Eq)]
struct Wait {
    reason: String,
    shown: bool,
}

impl Wait {
    fn none() -> Self {
        Self { reason: String::new(), shown: false }
    }

    /// Read with Continue only: the page says it already.
    fn quiet(reason: String) -> Self {
        Self { reason, shown: false }
    }

    /// Read with Continue and shown beside it.
    fn shown(reason: String) -> Self {
        Self { reason, shown: true }
    }
}

/// Why Continue waits on Get ready, or `None` once it can go. The footer
/// shows it only when the checklist doesn't say it: what Continue needs the
/// user to finish, after a problem they can fix. While Atlas is at work, or
/// a row, its caption or the bar at the top says what's next, it's only
/// read with Continue.
fn ready_hint(state: &AppModel, stopping: bool) -> Option<Wait> {
    if stopping {
        return Some(Wait::quiet(t!("footer-prepare-stopping-stage")));
    }
    if state.install_block().is_some() {
        return Some(Wait::none());
    }
    if state.ready_to_continue() {
        return None;
    }
    Some(match state.ready_status() {
        Some(ReadyStatus::Busy) => Wait::quiet(t!("footer-still-checking")),
        Some(ReadyStatus::Blocked) => Wait::shown(t!("footer-checks-blocked")),
        Some(ReadyStatus::ManagerOutdated) => Wait::quiet(t!("footer-manager-outdated")),
        Some(ReadyStatus::NoPackage) if state.bundled() => Wait::quiet(t!("footer-need-package-bundled")),
        // The download starts once Atlas knows the latest release.
        Some(ReadyStatus::NoPackage)
            if matches!(state.release, ReleaseCheck::Checking | ReleaseCheck::NotChecked)
                && !matches!(state.acquisition, Acquisition::Failed(_)) =>
        {
            Wait::quiet(t!("footer-still-checking"))
        }
        // The row says it couldn't get them, and what to do.
        Some(ReadyStatus::NoPackage) if matches!(state.acquisition, Acquisition::Failed(_)) => {
            Wait::quiet(t!("footer-need-files"))
        }
        Some(ReadyStatus::NoPackage) => Wait::shown(t!("footer-need-files")),
        // The caption under the update row says what updating waits for.
        Some(ReadyStatus::Drivers) => Wait::quiet(t!("footer-drivers")),
        Some(ReadyStatus::WindowsTerms) => Wait::quiet(t!("footer-windows-terms")),
        // Atlas is at work, or the row asks for its restart.
        Some(ReadyStatus::Updating) => Wait::quiet(t!("footer-updating")),
        Some(ReadyStatus::UpdatesRestart) => Wait::quiet(t!("footer-restart")),
        Some(ReadyStatus::Updates | ReadyStatus::UpdatesResumed) => {
            Wait::quiet(t!("footer-prepare-required"))
        }
        Some(ReadyStatus::UpdatesStopped | ReadyStatus::UpdatesFailed | ReadyStatus::UpdatesUnconfirmed) => {
            Wait::shown(t!("footer-prepare-required"))
        }
        Some(ReadyStatus::Warnings | ReadyStatus::Ready) | None => Wait::none(),
    })
}

/// The stop question's title: an update names the Atlas it updates to; a
/// first install or reinstall is only updating Windows so far.
fn stop_title(state: &AppModel) -> String {
    if state.updates_atlas() {
        t!("stop-update-title", version = &state.manifest().version)
    } else {
        t!("stop-update-title-windows")
    }
}

/// Asks before leaving the flow with Windows Update settings changed: Stop
/// updating puts them back, then leaves; Keep updating stays.
fn ask_to_stop_updating(
    model: &Entity<AppModel>,
    question: StopQuestion,
    title: &str,
    window: &mut Window,
    cx: &mut App,
) {
    let message = match question {
        StopQuestion::Access => t!("stop-update-access"),
        StopQuestion::BeforeMove { current } => t!("stop-update-before", current = current),
        StopQuestion::AfterMove { release } => t!("stop-update-after", release = release),
    };
    let answers = [
        crate::ui::content_dialog::safe_answer(t!("stop-update-keep")),
        crate::ui::content_dialog::answer(t!("prepare-stop")),
    ];
    let answer = window.prompt(PromptLevel::Warning, title, Some(&message), &answers, cx);
    let model = model.clone();
    cx.spawn(async move |cx| {
        if answer.await == Ok(1) {
            model.update(cx, |model, cx| model.stop_updating(cx));
        }
    })
    .detach();
}

/// Why the last relaunch as administrator failed, for the steps before
/// Install, which has its own bar. Relaunching can't help while another
/// window owns the setup; starting over here can, and it's the accent while
/// the step's Continue can't be chosen (`step_done`).
fn elevation_problem(state: &AppModel, model: &Entity<AppModel>, step_done: bool) -> Option<AnyElement> {
    let problem = state.elevation_error.as_ref().filter(|_| !state.elevated)?;
    let bar =
        InfoBar::new(Severity::Error, t!("install-elevate-title"), problem.text()).id("step-elevate-problem");
    let bar = if *problem == ElevationProblem::TakenOver {
        bar.action(start_over_button("step-start-over", state, model).when(!step_done, Button::accent))
    } else {
        bar
    };
    Some(bar.into_any_element())
}

/// Starts the setup again from Get ready, unavailable while
/// [`AppModel::begin_install`] would refuse.
fn start_over_button(id: &'static str, state: &AppModel, model: &Entity<AppModel>) -> Button {
    Button::new(id, t!("home-start-over"))
        .disabled(state.recovering || state.elevating || state.locked())
        .on_click(on_model(model, |m, cx| m.begin_install(cx)))
}

/// The Show details link with its chevron, which opens or folds the part of
/// the page that `flag` says is shown. Its accessible name adds `section`,
/// the title of the card it opens, so every toggle on a page has its own
/// name, and it reports whether that part is shown. The installing view
/// shares it, so the same control reads the same on both.
pub(super) fn details_toggle<T: 'static>(
    id: &'static str,
    section: impl Into<SharedString>,
    shown: bool,
    flag: fn(&mut T) -> &mut bool,
    cx: &Context<T>,
) -> Button {
    let label = if shown { t!("common-hide-details") } else { t!("common-show-details") };
    let section: SharedString = section.into();
    Button::new(id, label.clone())
        .aria_label(t!("common-details-a11y", action = label, section = section.as_ref()))
        .expanded(shown)
        .hyperlink()
        .compact()
        .trailing_icon(if shown { Icon::ChevronUp } else { Icon::ChevronDown })
        .on_click(cx.listener(move |this, _, _, cx| {
            let shown = flag(this);
            *shown = !*shown;
            cx.notify();
        }))
}

impl Render for InstallPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let (step, run, may_edit, screen) = {
            let state = self.model.read(cx);
            (state.flow.step, state.flow.run, state.flow.may_edit(), state.current_option_screen())
        };
        let step_focus = self.focus.get("step-current", cx);
        let result_focus = self.focus.get("install-result", cx);
        let preflight_focus = self.focus.get("install-preflight", cx);

        // A new step, or arriving from another page, puts focus on the
        // current step in the stepper, which names it; a new step also
        // starts at the top. A Change link puts it on what it changes
        // instead, which is read with its question, and brings that into
        // view. A result is brought into view and announced.
        let visit = self.model.read(cx).page_visit;
        let arrived = std::mem::replace(&mut self.seen_visit, visit) != visit;
        if self.shown_step != Some((step, screen)) {
            let first = self.shown_step.is_none();
            self.shown_step = Some((step, screen));
            self.scroll.set_offset(Point::default());
            let changed = self.change_target.take().filter(|_| step == Step::Options);
            match changed.and_then(|kind| self.change_focus(kind, cx)) {
                Some(target) => reveal_focus(&target, window, cx),
                None if !first => window.focus(&step_focus, cx),
                None => {}
            }
        }
        if arrived {
            window.focus(&step_focus, cx);
        }
        // The installing view covers this page while an install runs, so a
        // retry goes from one result straight to the next; the install each
        // belongs to tells them apart.
        let shown_run = (run, self.model.read(cx).session.as_ref().map(|session| session.id.clone()));
        if result_is_new(self.shown_run.as_ref(), &shown_run) {
            self.scroll.set_offset(Point::default());
            reveal_focus(&result_focus, window, cx);
        }
        self.shown_run = Some(shown_run);
        // The final checks refused while the installing view was showing;
        // each refusal is brought into view and announced, even one like the last.
        let (preflight_epoch, refused) = {
            let state = self.model.read(cx);
            (state.preflight_epoch, state.preflight_problem.is_some())
        };
        if self.shown_preflight_epoch != preflight_epoch {
            self.shown_preflight_epoch = preflight_epoch;
            if refused && step == Step::Install {
                self.scroll.set_offset(Point::default());
                reveal_focus(&preflight_focus, window, cx);
            }
        }

        // Updates that end in trouble or a restart put what to do next under
        // the update row, so focus follows to the row: the outcome is
        // announced, and the keyboard isn't left on a button that went away.
        // A countdown puts it on Not now instead, so a key press keeps the PC
        // from restarting before work is saved. Starting needs nobody, so it
        // moves nothing.
        let row_focus = self.focus.get("preparation-status", cx);
        let later_focus = self.focus.get("prepare-not-now", cx);
        let (busy, needs_user, waiting, counting) = {
            let state = self.model.read(cx);
            (
                state.preparation.busy(),
                preparation::needs_user(&state.preparation),
                state.waiting_for_offer() && state.offer_rechecks_active(),
                state.preparation_countdown().is_some(),
            )
        };
        let was_busy = std::mem::replace(&mut self.preparation_was_busy, busy);
        if !busy {
            if was_busy
                && needs_user
                && step == Step::Ready
                && preparation_end_is_news(
                    self.preparation_asked,
                    self.offer_wait_shown,
                    waiting,
                    window.focused(cx).is_some(),
                )
            {
                reveal_focus(if counting { &later_focus } else { &row_focus }, window, cx);
            }
            self.preparation_asked = false;
            self.offer_wait_shown = waiting;
        }

        // Each screen of Your choices says what it asks when the current
        // step takes focus, so moving on is announced as a new screen.
        let current_name = (step == Step::Options).then(|| self.choice_heading_name(cx)).flatten();
        let mut body = vec![self.stepper(step, may_edit, step_focus, current_name, cx)];
        body.extend(match step {
            Step::Ready => self.ready_cards(cx),
            Step::Options => self.options_cards(cx),
            Step::Security => self.security_cards(cx),
            Step::Install => self.install_cards(cx),
        });
        let footer = self.footer(cx);
        // Each step places the diagnostics under what went wrong, if anything did.
        self.diagnostics.settle(&self.model, window, cx);
        page_frame(
            "install-scroll",
            Some(t!("install-title").into()),
            None,
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            body,
            Some(footer),
            cx,
        )
    }
}

/// Whether the run drawn now is a result to bring into view: a finished run
/// not drawn last frame. A retry's result belongs to another install, so it
/// counts even when it ends the same way.
fn result_is_new(shown: Option<&(RunState, Option<String>)>, now: &(RunState, Option<String>)) -> bool {
    shown != Some(now) && matches!(now.0, RunState::Finished(_))
}

/// Whether updating that just ended on Get ready takes focus. A look Atlas
/// made by itself that found the wait as it was is no news: focus stays
/// where the user left it, unless it went with a control the look took away.
fn preparation_end_is_news(asked: bool, was_waiting: bool, waiting: bool, focus_kept: bool) -> bool {
    asked || !was_waiting || !waiting || !focus_kept
}

/// Moves focus to `handle` and brings it into view on the next frame, as a
/// result or the next button it puts focus on can be off screen.
fn reveal_focus(handle: &FocusHandle, window: &mut Window, cx: &mut App) {
    window.focus(handle, cx);
    focus_reveal::request(window, cx);
}

impl InstallPage {
    /// What the current step reads after its name on a screen of Your
    /// choices (see [`options::choice_heading_name`]).
    fn choice_heading_name(&self, cx: &App) -> Option<String> {
        options::choice_heading_name(self.model.read(cx))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::installer::InstallOutcome;

    #[test]
    fn only_news_from_updating_takes_focus() {
        // (asked, was waiting, still waiting, focus kept)
        let table = [
            ((false, true, true, true), false, "an automatic look that found the wait as it was"),
            ((true, true, true, true), true, "the user's own Check again"),
            ((false, true, false, true), true, "a look that ended the wait, as Network or its expiry does"),
            ((false, true, true, false), true, "focus went with a control the look took away"),
            ((false, false, true, true), true, "the first look that found the wait"),
        ];
        for ((asked, was_waiting, waiting, focus_kept), news, case) in table {
            assert_eq!(preparation_end_is_news(asked, was_waiting, waiting, focus_kept), news, "{case}");
        }
    }

    #[test]
    fn each_install_result_is_brought_into_view_once() {
        let failed =
            |session: &str| (RunState::Finished(InstallOutcome::Failed(1)), Some(session.to_owned()));
        let first = failed("first");
        assert!(result_is_new(None, &first));
        assert!(result_is_new(Some(&(RunState::Running, Some("first".into()))), &first));
        assert!(!result_is_new(Some(&first), &first), "the same result again");
        // A retry from the result goes straight to the next one, the same failure in another install.
        assert!(result_is_new(Some(&first), &failed("retry")));
        assert!(!result_is_new(None, &(RunState::Idle, None)), "no result to show");
    }
}
