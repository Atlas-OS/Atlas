//! The restart that completes a successful install: the countdown Atlas
//! keeps, "Restart later" shared with every window, "Restart now", and the
//! restart Home asks for while one is still owed. And the countdown to the
//! restart Windows and Store updates need on Get ready.

use std::time::{Duration, Instant};

use gpui::Context;

use super::{AppModel, ModelEvent, Page, Step};
use crate::services::preparation::State as Preparation;
use crate::services::session;
use crate::t;

/// A restart command that did not take.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum RestartProblem {
    Start { error: String },
}

/// A restart countdown in progress: when it ends, and how long it was, so
/// the remaining time is read from the clock rather than counted in ticks.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct RestartCountdown {
    pub deadline: Instant,
    pub total: Duration,
}

impl RestartCountdown {
    /// Whole seconds left, rounded up; `0` once the deadline has passed.
    pub fn seconds_left(&self) -> u32 {
        self.deadline.saturating_duration_since(Instant::now()).as_secs_f32().ceil() as u32
    }
}

/// A finished install whose restart hasn't happened yet, as Home offers it
/// (see [`session::restart_owed`]).
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct OwedRestart {
    /// Windows has been asked to restart from Home and hasn't yet.
    pub requested: bool,
    /// The last request Windows refused.
    pub problem: Option<RestartProblem>,
    /// Counts the requests that didn't take, refused or not acted on, so
    /// Home can announce each one, even one like the last.
    pub epoch: u64,
}

/// A restart Atlas holds until the user confirms it, because other people
/// are signed in and restarting closes their apps too.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RestartConfirmation {
    pub kind: RestartKind,
    /// Their account names, each once.
    pub people: Vec<String>,
}

/// Which restart is waiting to be confirmed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RestartKind {
    /// The restart that completes an install, from its countdown or Restart now.
    Install,
    /// Home's Restart now, for an install that still owes its restart.
    Owed,
    /// The restart Get ready asks for while preparing Windows.
    Preparation,
    /// The restart Get ready offers to try updates that failed on Windows'
    /// component store again.
    Retry,
}

/// What the restart timer found when it woke.
enum Tick {
    Continue,
    Expired,
    Stop,
}

impl AppModel {
    /// Seconds left on the restart countdown, if one is running.
    pub fn restart_countdown(&self) -> Option<u32> {
        self.attempt.restart.map(|countdown| countdown.seconds_left())
    }

    /// Atlas owns the countdown; Windows receives an immediate restart only
    /// at expiry. The timer belongs to this attempt: replacing or cancelling
    /// the countdown drops it, and a generation check keeps a timer that
    /// already woke from touching a newer countdown. "Restart later" in any
    /// window following the same install stops it too.
    /// The countdown is chosen once, as it starts: the usual one while the
    /// window is in front, a longer one when nobody may be looking at it. It
    /// doesn't shorten if the user comes back.
    /// Nothing counts down while other people are signed in: Atlas asks
    /// first, and restarts only once the user agrees.
    pub(super) fn begin_restart_countdown(&mut self, cx: &mut Context<Self>) {
        if self.hold_for_other_sessions(RestartKind::Install, cx) {
            // A held countdown resumed into other people's sessions ends
            // here, as at expiry. This never runs inside the timer it drops.
            self.stop_restart_timer();
            return;
        }
        let timing = self.env.restart;
        let total = if self.window_active { timing.countdown } else { timing.background_countdown };
        let generation = self.restart_generation.next();
        self.attempt.restart = Some(RestartCountdown { deadline: Instant::now() + total, total });
        self.attempt.restart_cancelled = false;
        self.restart_timer = Some(cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(timing.tick).await;
                let tick = this
                    .update(cx, |this, cx| {
                        if this.restart_generation != generation {
                            return Tick::Stop;
                        }
                        cx.notify();
                        if this.restart_declined() {
                            this.follow_declined_restart();
                            return Tick::Stop;
                        }
                        match this.attempt.restart {
                            Some(countdown) if Instant::now() >= countdown.deadline => Tick::Expired,
                            Some(_) => Tick::Continue,
                            None => Tick::Stop,
                        }
                    })
                    .unwrap_or(Tick::Stop);
                match tick {
                    Tick::Continue => continue,
                    Tick::Stop => return,
                    Tick::Expired => break,
                }
            }
            this.update(cx, |this, cx| {
                if this.restart_generation != generation || this.attempt.restart.is_none() {
                    return;
                }
                if this.restart_declined() {
                    this.follow_declined_restart();
                    cx.notify();
                } else if this.hold_for_other_sessions(RestartKind::Install, cx) {
                    // Someone signed in during the countdown. This timer is
                    // ending, so only the countdown goes.
                    this.restart_generation.next();
                    this.attempt.restart = None;
                } else {
                    this.request_restart(cx);
                }
            })
            .ok();
        }));
    }

    /// Whether "Restart later" was chosen for this install, in this window
    /// or in another one following it.
    pub(super) fn restart_declined(&self) -> bool {
        self.session.as_ref().is_some_and(session::restart_declined)
    }

    /// Ends this window's countdown after another window declined the
    /// restart, as if the choice had been made here.
    fn follow_declined_restart(&mut self) {
        self.restart_generation.next();
        self.attempt.restart = None;
        self.attempt.restart_cancelled = true;
    }

    /// Asks Windows to restart now, at the end of the countdown or on
    /// "Restart now". A refusal is shown with the restart offered again. A
    /// request Windows accepted but has not acted on by the end of the grace
    /// period is offered again too, rather than claiming a restart that is
    /// not happening. A countdown left showing stays at zero meanwhile.
    fn request_restart(&mut self, cx: &mut Context<Self>) {
        self.attempt.restart_problem = None;
        if let Err(error) = (self.env.adapters.schedule_restart)(&t!("shutdown-comment")) {
            self.attempt.restart = None;
            self.attempt.restart_requested = false;
            self.attempt.restart_problem = Some(RestartProblem::Start { error: format!("{error:#}") });
            // Each refusal is news, even one like the last.
            self.attempt.restart_epoch += 1;
            cx.notify();
            return;
        }
        self.attempt.restart_requested = true;
        let generation = self.restart_generation;
        let grace = self.env.restart.grace;
        cx.spawn(async move |this, cx| {
            cx.background_executor().timer(grace).await;
            this.update(cx, |this, cx| {
                if this.restart_generation == generation && this.attempt.restart_requested {
                    this.attempt.restart = None;
                    this.attempt.restart_requested = false;
                    this.attempt.restart_cancelled = false;
                    this.attempt.restart_epoch += 1;
                    cx.notify();
                }
            })
            .ok();
        })
        .detach();
        cx.notify();
    }

    fn stop_restart_timer(&mut self) {
        self.restart_timer = None;
        self.restart_generation.next();
        self.attempt.restart = None;
    }

    /// Holds the restart countdown while the close prompt is open. The
    /// prompt blocks the window's thread, so a tick queued behind it would
    /// otherwise restart the PC the moment it closes, whatever the answer.
    /// The countdown stays cancellable meanwhile.
    pub fn hold_restart(&mut self) {
        self.restart_timer = None;
        self.restart_generation.next();
    }

    /// Starts a held countdown again, from the beginning, once the close
    /// prompt was answered with Keep open or dismissed.
    pub fn resume_restart(&mut self, cx: &mut Context<Self>) {
        if self.restart_cancellable() {
            self.begin_restart_countdown(cx);
            cx.notify();
        }
    }

    /// Whether "Restart later" can still do anything: a countdown is running
    /// and Windows has not been asked yet.
    pub fn restart_cancellable(&self) -> bool {
        self.attempt.restart.is_some() && !self.attempt.restart_requested
    }

    /// Cancels the local countdown, so the user can finish something first.
    /// Atlas still needs the restart to complete setup. Once Windows has the
    /// request there is nothing here to cancel.
    pub fn cancel_restart(&mut self, cx: &mut Context<Self>) {
        if !self.restart_cancellable() {
            return;
        }
        self.stop_restart_timer();
        self.attempt.restart_cancelled = true;
        self.attempt.restart_problem = None;
        // Other windows following this install count down on their own.
        if let Some(record) = &self.session
            && let Err(error) = session::decline_restart(record)
        {
            log::warn!("could not tell other windows the restart was declined: {error:#}");
        }
        cx.notify();
    }

    /// Reads again whether a finished install still owes its restart, for
    /// Home. A request already made from Home is kept while it stands.
    pub(super) fn refresh_owed_restart(&mut self) {
        let installed_at = self.installed().and_then(|state| state.installed_at.clone());
        if session::restart_owed(&self.session_paths, installed_at.as_deref()) {
            self.owed_restart.get_or_insert_with(OwedRestart::default);
        } else {
            self.owed_restart = None;
        }
    }

    /// The restart Home offers: owed, and not covered by the install view,
    /// which has a Restart now of its own.
    pub fn owed_restart(&self) -> Option<&OwedRestart> {
        self.owed_restart.as_ref().filter(|_| self.page == Page::Home && !self.install_in_progress())
    }

    /// Home's Restart now: the same immediate restart the install view asks
    /// for. A refusal is shown with the restart offered again, and so is a
    /// request Windows accepted but hasn't acted on by the end of the grace
    /// period.
    pub fn restart_owed_now(&mut self, cx: &mut Context<Self>) {
        if self.owed_restart().is_none_or(|owed| owed.requested)
            || self.hold_for_other_sessions(RestartKind::Owed, cx)
        {
            return;
        }
        self.request_owed_restart(cx);
    }

    fn request_owed_restart(&mut self, cx: &mut Context<Self>) {
        if self.owed_restart().is_none_or(|owed| owed.requested) {
            return;
        }
        let result = (self.env.adapters.schedule_restart)(&t!("shutdown-comment"));
        let Some(owed) = self.owed_restart.as_mut() else { return };
        match result {
            Err(error) => {
                owed.problem = Some(RestartProblem::Start { error: format!("{error:#}") });
                owed.epoch += 1;
            }
            Ok(()) => {
                owed.problem = None;
                owed.requested = true;
                let grace = self.env.restart.grace;
                cx.spawn(async move |this, cx| {
                    cx.background_executor().timer(grace).await;
                    this.update(cx, |this, cx| {
                        if let Some(owed) = this.owed_restart.as_mut()
                            && owed.requested
                        {
                            owed.requested = false;
                            owed.epoch += 1;
                            cx.notify();
                        }
                    })
                    .ok();
                })
                .detach();
            }
        }
        cx.notify();
    }

    /// Asks Windows to restart straight away, when the automatic restart
    /// was declined, turned off, or did not take.
    pub fn restart_now(&mut self, cx: &mut Context<Self>) {
        if !self.flow.run.succeeded() || self.attempt.restart_requested {
            return;
        }
        self.stop_restart_timer();
        self.attempt.restart_cancelled = false;
        if self.hold_for_other_sessions(RestartKind::Install, cx) {
            return;
        }
        self.request_restart(cx);
    }

    /// The restart waiting for the user to confirm it over other people's
    /// sessions, if any.
    pub fn restart_confirmation(&self) -> Option<&RestartConfirmation> {
        self.restart_confirmation.as_ref()
    }

    /// Reads who else is signed in right before a restart. With nobody,
    /// the restart goes ahead; otherwise it is held and the shell asks.
    /// A list Windows won't give is logged, and the restart goes ahead as
    /// it did before Atlas looked.
    pub(super) fn hold_for_other_sessions(&mut self, kind: RestartKind, cx: &mut Context<Self>) -> bool {
        let people = self.other_people();
        if people.is_empty() {
            return false;
        }
        log::info!("{} other people signed in; asking before the {kind:?} restart", people.len());
        self.restart_confirmation = Some(RestartConfirmation { kind, people });
        cx.notify();
        true
    }

    /// The user chose to restart although other people are signed in.
    pub fn confirm_restart(&mut self, cx: &mut Context<Self>) {
        let Some(confirmation) = self.restart_confirmation.take() else { return };
        log::info!("restart confirmed over other people's sessions");
        match confirmation.kind {
            RestartKind::Install => {
                if self.flow.run.succeeded() && !self.attempt.restart_requested {
                    self.stop_restart_timer();
                    self.attempt.restart_cancelled = false;
                    self.request_restart(cx);
                }
            }
            RestartKind::Owed => self.request_owed_restart(cx),
            RestartKind::Preparation => self.restart_preparation_now(cx),
            RestartKind::Retry => self.restart_to_retry_now(cx),
        }
        cx.notify();
    }

    /// The user kept the PC running for the others. The restart is still
    /// owed, and Restart now asks again.
    pub fn decline_restart_confirmation(&mut self, cx: &mut Context<Self>) {
        if self.restart_confirmation.take().is_some() {
            log::info!("restart not confirmed; other people are signed in");
            cx.notify();
        }
    }

    /// The other people signed in, whose apps a restart would close. A list
    /// Windows won't give is logged and read as nobody.
    fn other_people(&self) -> Vec<String> {
        (self.env.adapters.read_other_sessions)().unwrap_or_else(|error| {
            log::warn!("could not read who else is signed in: {error:#}");
            Vec::new()
        })
    }

    /// Seconds left before Atlas restarts for updating, while it counts down.
    pub fn preparation_countdown(&self) -> Option<u32> {
        self.preparation_countdown.map(|countdown| countdown.seconds_left())
    }

    /// Counts down to the restart updating needs, once the draft and
    /// recovery are in place, then restarts as Restart now does. Updating
    /// runs unattended, so the countdown is long enough to come back to,
    /// and the taskbar button flashes when the window is behind others.
    /// It follows the Restart automatically setting: with it off, Get ready
    /// offers Restart now and nothing counts down. Nothing counts down while
    /// other people are signed in either: Restart now asks first, as it
    /// does at the end if someone signs in meanwhile. Only Get ready keeps
    /// it (see [`AppModel::preparation_countdown_allowed`]); anything that
    /// ends what it needs ends it, as Not now does.
    pub(super) fn begin_preparation_countdown(&mut self, cx: &mut Context<Self>) {
        if !self.preparation_countdown_allowed() || !self.other_people().is_empty() {
            self.stop_preparation_countdown();
            return;
        }
        let timing = self.env.restart;
        let generation = self.preparation_countdown_generation.next();
        self.preparation_countdown = Some(RestartCountdown {
            deadline: Instant::now() + timing.preparation,
            total: timing.preparation,
        });
        cx.emit(ModelEvent::NeedsAttention);
        self.preparation_countdown_timer = Some(cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(timing.tick).await;
                let tick = this
                    .update(cx, |this, cx| {
                        if this.preparation_countdown_generation != generation {
                            return Tick::Stop;
                        }
                        cx.notify();
                        if !this.preparation_countdown_allowed() {
                            log::info!("restart for updates put off: Get ready no longer counts down to it");
                            this.preparation_countdown = None;
                            return Tick::Stop;
                        }
                        match this.preparation_countdown {
                            Some(countdown) if Instant::now() >= countdown.deadline => Tick::Expired,
                            Some(_) => Tick::Continue,
                            None => Tick::Stop,
                        }
                    })
                    .unwrap_or(Tick::Stop);
                match tick {
                    Tick::Continue => continue,
                    Tick::Stop => return,
                    Tick::Expired => break,
                }
            }
            this.update(cx, |this, cx| {
                if this.preparation_countdown_generation == generation {
                    log::info!("Restarting for Windows and Store updates at the end of the countdown");
                    // This timer is ending, so only the countdown goes.
                    this.preparation_countdown = None;
                    this.preparation_countdown_generation.next();
                    this.restart_for_updates(cx);
                    cx.notify();
                }
            })
            .ok();
        }));
        cx.notify();
    }

    /// Whether Get ready may count down to the restart updating needs: the
    /// restart is owed and saved for, Restart automatically is on, Get ready
    /// is the page showing, where the countdown and Not now are, and no ISO
    /// or USB job runs, which the restart would break off.
    fn preparation_countdown_allowed(&self) -> bool {
        self.settings.restart_after_install
            && self.preparation == Preparation::Reboot
            && self.preparation_problem.is_none()
            && self.flow.active
            && self.flow.step == Step::Ready
            && self.page == Page::Install
            && !self.media_job_running()
    }

    /// An ISO or USB job runs (the USB page sets both flags).
    pub(super) fn media_job_running(&self) -> bool {
        self.iso_busy || self.usb_busy
    }

    /// Holds the countdown while closing asks about it, so the PC doesn't
    /// restart under the question.
    pub fn hold_preparation_countdown(&mut self) {
        self.stop_preparation_countdown();
    }

    /// Counts down again after closing's question went away unanswered.
    pub fn resume_preparation_countdown(&mut self, cx: &mut Context<Self>) {
        self.begin_preparation_countdown(cx);
    }

    /// Not now: the countdown stops, and Get ready offers Restart now.
    pub fn decline_preparation_restart(&mut self, cx: &mut Context<Self>) {
        if self.preparation_countdown.is_some() {
            log::info!("restart for updates put off");
            self.stop_preparation_countdown();
            cx.notify();
        }
    }

    pub(super) fn stop_preparation_countdown(&mut self) {
        self.preparation_countdown = None;
        self.preparation_countdown_timer = None;
        self.preparation_countdown_generation.next();
    }
}
