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

use std::sync::atomic::Ordering;

use gpui::{
    AnyElement, App, Context, Entity, FocusHandle, IntoElement, Point, Render, ScrollHandle, SharedString,
    Styled, Window, prelude::*, px,
};

use super::{CommandBar, LogIds, LogView, StepStatus, Stepper, focusable_heading, on_model, page_frame};
use crate::model::{AppModel, ElevationProblem, RunState, Step};
use crate::services::iso;
use crate::services::preparation::State as Preparation;
use crate::services::windows_installation::Evidence;
use crate::t;
use crate::ui::{Button, FocusHandles, Icon, InfoBar, ScrollbarState, Severity, Typography, focus_reveal};

const LOG_IDS: LogIds =
    LogIds { log: "install-log", hidden: "log-hidden", line: "log-line", copy: "log-copy", open: "log-open" };

/// Log lines drawn; older lines are in the file.
const LOG_LINES_SHOWN: usize = 500;

pub struct InstallPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    log: LogView,
    scrollbar: ScrollbarState,
    show_command: bool,
    /// The Install summary's details: installation files, Windows, activation
    /// and the installation command.
    show_summary_details: bool,
    /// A finished attempt's log, folded away by default.
    show_log: bool,
    /// The passed checks on Get ready, folded into one line by default.
    show_passed_checks: bool,
    /// The raw details of an update failure.
    show_preparation_details: bool,
    /// Whether updating was under way last frame, to follow how it ended.
    preparation_was_busy: bool,
    windows_installation: Evidence,
    used_windows_warning_dismissed: bool,
    /// This copy was staged by Atlas installation media in the Windows it has
    /// just installed, so the fresh-install note is left out.
    staged_iso_setup: bool,
    /// The step and option screen drawn last frame, to reset scrolling and focus on a change.
    shown_step: Option<(Step, usize)>,
    shown_run: Option<RunState>,
    /// The last refusal of the final checks that was brought into view.
    shown_preflight_epoch: u64,
    /// Updating was last seen waiting to continue after Atlas's own restart,
    /// so its Continue updates took focus once.
    shown_resumed: bool,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    focus: FocusHandles,
    diagnostics: super::Diagnostics,
}

impl InstallPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        cx.spawn(async move |this, cx| {
            let evidence = cx.background_executor().spawn(async { Evidence::read() }).await;
            this.update(cx, |this, cx| {
                this.windows_installation = evidence;
                cx.notify();
            })
            .ok();
        })
        .detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            log: LogView::default(),
            scrollbar: ScrollbarState::new(),
            show_command: false,
            show_summary_details: false,
            show_log: false,
            show_passed_checks: false,
            show_preparation_details: false,
            preparation_was_busy: false,
            windows_installation: Default::default(),
            used_windows_warning_dismissed: false,
            staged_iso_setup: iso::is_staged_setup(),
            shown_step: None,
            shown_run: None,
            shown_preflight_epoch: 0,
            shown_resumed: false,
            seen_visit: 0,
            focus: FocusHandles::default(),
            diagnostics: super::Diagnostics::new(cx),
        }
    }

    fn stepper(&self, current: Step, may_edit: bool, cx: &App) -> AnyElement {
        let state = self.model.read(cx);
        let model = self.model.clone();
        let mut stepper = Stepper::new("stepper", t!("stepper-label"))
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

        let (hint, next_enabled): (String, bool) = match step {
            Step::Ready => {
                if stopping {
                    (t!("footer-prepare-stopping"), false)
                } else if state.install_block().is_some() {
                    (t!("install-source-title"), false)
                } else if !state.preparation.ready()
                    && state.preparation != Preparation::Idle
                    // A build that fails its check cannot be prepared; that check is what to fix.
                    && state.preparation_build_supported()
                {
                    (t!("footer-prepare-required"), false)
                } else if !state.checks_complete() || state.acquisition.is_busy() {
                    (t!("footer-still-checking"), false)
                } else if state.checks_blocking() {
                    (t!("footer-fix-items"), false)
                } else if state.playbook.is_none() && state.bundled() {
                    (t!("footer-need-package-bundled"), false)
                } else if state.playbook.is_none() {
                    (t!("footer-need-package"), false)
                } else if !state.preparation.ready() {
                    (t!("footer-prepare-required"), false)
                } else {
                    (String::new(), true)
                }
            }
            Step::Options => (String::new(), true),
            Step::Security => {
                // What is left to do, not how many switches: the card says that.
                if state.security_ok() {
                    (String::new(), true)
                } else if !state.security_fresh() {
                    (t!("footer-reading-security"), false)
                } else if state.security.counts().on > 0 {
                    (t!("footer-security-pending"), false)
                } else if !state.elevated {
                    (t!("security-unknown-unelevated-title"), false)
                } else {
                    (t!("footer-security-confirm"), false)
                }
            }
            Step::Install => {
                // Why Install (or Try again) is unavailable, beside it, or
                // what to do before choosing it when it restarts the PC.
                let restart = state.install_request().is_some_and(|request| request.restart);
                let hint = if !run.may_start() {
                    String::new()
                } else if !state.elevated {
                    t!("install-elevate-title")
                } else if state.playbook.is_some() && !state.ready_to_continue() {
                    t!("install-not-ready-title")
                } else if state.can_install() && restart {
                    t!("footer-install-ready")
                } else {
                    String::new()
                };
                (hint, false)
            }
        };

        let cancel_disabled =
            stopping || (locked && !matches!(state.preparation, Preparation::Running { .. }));
        let on_cancel = {
            let model = model.clone();
            move |_: &gpui::ClickEvent, window: &mut Window, cx: &mut App| {
                // Desktop setup has no Home to return to, so Cancel closes the window.
                if model.read(cx).before_desktop && !model.read(cx).preparation.busy() {
                    window.remove_window();
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
            .accent()
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

        CommandBar::new()
            .cancel("flow-cancel", t!("common-cancel"), cancel_disabled, on_cancel)
            .hint(hint)
            .back(back)
            .primary(forward)
            .into_any_element()
    }
}

/// Why the last relaunch as administrator failed, for the steps before
/// Install, which has its own bar. Relaunching can't help while another
/// window owns the setup; starting over here can.
fn elevation_problem(state: &AppModel, model: &Entity<AppModel>) -> Option<AnyElement> {
    let problem = state.elevation_error.as_ref().filter(|_| !state.elevated)?;
    let bar =
        InfoBar::new(Severity::Error, t!("install-elevate-title"), problem.text()).id("step-elevate-problem");
    let bar = if *problem == ElevationProblem::TakenOver {
        bar.action(start_over_button("step-start-over", model))
    } else {
        bar
    };
    Some(bar.into_any_element())
}

/// Starts the setup again from Get ready.
fn start_over_button(id: &'static str, model: &Entity<AppModel>) -> Button {
    Button::new(id, t!("home-start-over")).on_click(on_model(model, |m, cx| m.begin_install(cx)))
}

/// Leads back to Get ready, where what stands in the way is fixed.
fn go_to_ready_button(id: &'static str, model: &Entity<AppModel>) -> Button {
    Button::new(id, t!("go-to-ready")).on_click(on_model(model, |m, cx| m.set_step(Step::Ready, cx)))
}

/// The Show details link with its chevron, which opens or folds the part of
/// the page that `flag` says is shown. Its accessible name adds `section`,
/// the title of the card it opens, so every toggle on a page has its own
/// name, and it reports whether that part is shown.
fn details_toggle(
    id: &'static str,
    section: impl Into<SharedString>,
    shown: bool,
    flag: fn(&mut InstallPage) -> &mut bool,
    cx: &Context<InstallPage>,
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
        let step_heading = self.focus.get("step-heading", cx);
        let result_focus = self.focus.get("install-result", cx);
        let preflight_focus = self.focus.get("install-preflight", cx);

        // A new step, or arriving from another page, puts focus on the step
        // heading; a new step also starts at the top. A result is brought
        // into view and announced.
        let visit = self.model.read(cx).page_visit;
        let arrived = std::mem::replace(&mut self.seen_visit, visit) != visit;
        if self.shown_step != Some((step, screen)) {
            let first = self.shown_step.is_none();
            self.shown_step = Some((step, screen));
            self.scroll.set_offset(Point::default());
            if !first {
                window.focus(&step_heading, cx);
            }
        }
        if arrived {
            window.focus(&step_heading, cx);
        }
        if self.shown_run != Some(run) {
            let was_finished = matches!(self.shown_run, Some(RunState::Finished(_)));
            self.shown_run = Some(run);
            if matches!(run, RunState::Finished(_)) && !was_finished {
                self.scroll.set_offset(Point::default());
                reveal_focus(&result_focus, window, cx);
            }
        }
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

        // Updates that end in trouble or a restart put the next button in the
        // bar that explains it, so focus follows to that bar: the outcome is
        // announced, and the keyboard isn't left on a button that went away.
        let preparation_focus = self.focus.get("preparation-status", cx);
        let (busy, in_bar) = {
            let state = &self.model.read(cx).preparation;
            (state.busy(), preparation::in_bar(state))
        };
        if std::mem::replace(&mut self.preparation_was_busy, busy) && in_bar && step == Step::Ready {
            reveal_focus(&preparation_focus, window, cx);
        }
        // Back after Atlas's own restart, Continue updates is what's next:
        // it takes focus once and is brought into view.
        let resumed = self.model.read(cx).preparation == Preparation::Resumed && step == Step::Ready;
        if resumed && !std::mem::replace(&mut self.shown_resumed, true) {
            let action = self.focus.get("prepare-action", cx);
            reveal_focus(&action, window, cx);
        }
        self.shown_resumed &= resumed;

        let heading =
            t!("step-heading", number = step.index() + 1, total = Step::ALL.len(), title = step.title());
        // Each screen of Your choices names its question when the heading
        // takes focus, so moving on is announced as a new screen.
        let heading_name = (step == Step::Options).then(|| self.choice_heading_name(&heading, cx)).flatten();
        let mut body = vec![
            self.stepper(step, may_edit, cx),
            focusable_heading("step-heading", 2, heading, &step_heading, cx)
                .when_some(heading_name, |this, name| this.aria_label(name))
                .type_subtitle()
                .pb(px(4.))
                .into_any_element(),
        ];
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

/// Moves focus to `handle` and brings it into view on the next frame, as a
/// result or the next button it puts focus on can be off screen.
fn reveal_focus(handle: &FocusHandle, window: &mut Window, cx: &mut App) {
    window.focus(handle, cx);
    focus_reveal::request(window, cx);
}

impl InstallPage {
    /// The step heading's accessible name on a screen of Your choices: the
    /// step, then which choice and its question, or the optional extras.
    fn choice_heading_name(&self, heading: &str, cx: &App) -> Option<String> {
        let state = self.model.read(cx);
        let screens = state.option_screens();
        let current = state.current_option_screen();
        let screen = screens.get(current)?;
        let (number, total) = (current + 1, screens.len());
        Some(if screen.required {
            t!(
                "step-heading-choice-a11y",
                heading = heading,
                progress = t!("options-progress", number = number, total = total),
                question = screen.kind.question()
            )
        } else {
            t!(
                "step-heading-extras-a11y",
                heading = heading,
                progress = t!("options-progress-extras", number = number, total = total)
            )
        })
    }
}
