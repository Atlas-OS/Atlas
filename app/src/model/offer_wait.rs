//! Waiting for Windows Update to offer the Windows release Get ready moves
//! to. Windows Update can take from a minute to many more to offer it once
//! the target is set, so "not offered" is a wait, not a failure: while the
//! window stays open, Get ready looks again every so often, for a while, and
//! continues the move when the offer comes. Windows Update stays turned on
//! meanwhile; the user agreed to the move and its record is open. When the
//! wait ends without an offer, the settings are put back, unless an Atlas
//! install still to finish does that itself.

use std::time::{Duration, Instant};

use gpui::Context;

use super::{AppModel, Step};
use crate::environment::OfferRecheckTiming;
use crate::services::preparation::{Activity, MISSING_PREREQUISITE, State, waits_for_offer};
use crate::services::update_access::UpdateAccess;

/// What a run reports while it waits for Windows Update's offer.
const FEATURE_OFFER: &str = "feature-offer";

/// The wait for an offer in this flow.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct OfferWait {
    /// When the first search found no offer; the wait lasts a window from here.
    pub since: Instant,
    /// The wait ended without an offer, and the settings were put back.
    pub expired: bool,
    /// The looks are full runs: the move waits for a newer monthly update,
    /// which only a full run installs.
    pub full_runs: bool,
}

impl OfferWait {
    pub fn started(since: Instant) -> Self {
        Self { since, expired: false, full_runs: false }
    }
}

/// Whole minutes waited since `since`, as of `now`; `None` under a minute,
/// which says nothing worth reading.
pub fn waited_minutes(since: Instant, now: Instant) -> Option<u64> {
    let minutes = now.saturating_duration_since(since).as_secs() / 60;
    (minutes > 0).then_some(minutes)
}

/// What the wait does next, after a search at `last` found nothing.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RecheckStep {
    /// Look again after this long.
    Wait(Duration),
    /// The wait is over.
    Expire,
}

/// The next step of a wait that began at `since`, as of `now`: the next look
/// one interval after the last, unless the window would be over by then.
pub fn recheck_step(since: Instant, now: Instant, timing: OfferRecheckTiming) -> RecheckStep {
    let elapsed = now.saturating_duration_since(since);
    if elapsed + timing.interval > timing.window {
        RecheckStep::Expire
    } else {
        RecheckStep::Wait(timing.interval)
    }
}

impl AppModel {
    /// The last run found no offer for the move under way.
    pub fn waiting_for_offer(&self) -> bool {
        self.preparation == State::Failed
            && self.transition_open()
            && self.last_failure().is_some_and(Activity::not_offered)
    }

    fn last_failure(&self) -> Option<&Activity> {
        self.preparation_progress.as_ref().and_then(|progress| progress.failure())
    }

    /// The record of a move says its last run found no offer, as Home and
    /// Get ready see it when the app opens again: it names a cause a live
    /// run waits on too.
    pub fn transition_waiting_for_offer(&self) -> bool {
        self.last_recorded_reason().is_some_and(waits_for_offer)
    }

    /// The cause the record's last entry names when it is an outcome, before
    /// the move is installed. The worker writes `reason=<id> code=<code> <message>`.
    fn last_recorded_reason(&self) -> Option<&str> {
        let journal = self.update_access.as_ref().and_then(UpdateAccess::transition)?;
        let entry =
            journal.history.last().filter(|entry| entry.event == "outcome" && !journal.installed())?;
        entry.detail.strip_prefix("reason=")?.split(' ').next()
    }

    /// The wait goes on after the last run: it found no offer, or it lost
    /// the connection while the wait was running.
    fn offer_wait_goes_on(&self) -> bool {
        self.waiting_for_offer()
            || (self.preparation == State::Network
                && self.transition_open()
                && self.offer_wait.is_some_and(|wait| !wait.expired))
    }

    /// The automatic looks are running: Get ready says so.
    pub fn offer_rechecks_active(&self) -> bool {
        self.offer_wait.is_some_and(|wait| !wait.expired) && self.offer_wait_goes_on()
    }

    /// The wait is under way, between looks or during one.
    pub fn offer_wait_running(&self) -> bool {
        self.offer_wait.is_some_and(|wait| !wait.expired)
            && (self.offer_wait_goes_on() || self.preparation.busy())
    }

    /// Atlas is waiting for Windows Update to offer the release, as Get
    /// ready shows it: a run waits for it, a look is under way, or the looks
    /// between runs go on. A look that lost the connection says so instead.
    pub fn offer_wait_shown(&self) -> bool {
        let run_waits = matches!(self.preparation, State::Running { .. })
            && self
                .preparation_progress
                .as_ref()
                .is_some_and(|progress| progress.activity.waiting.as_deref() == Some(FEATURE_OFFER));
        self.preparation != State::Network && (run_waits || self.offer_wait_running())
    }

    /// How many whole minutes Atlas has waited for the offer, counted from
    /// the first run that waited for it; `None` under a minute, and when it
    /// isn't waiting.
    pub fn offer_waited_minutes(&self) -> Option<u64> {
        if !self.offer_wait_shown() {
            return None;
        }
        let since = self.offer_waiting_since.or(self.offer_wait.map(|wait| wait.since))?;
        waited_minutes(since, Instant::now())
    }

    /// After every run: starts or continues the wait when no offer came, or
    /// when a look lost the connection; ends it when anything else happened.
    pub(super) fn follow_offer_wait(&mut self, cx: &mut Context<Self>) {
        if !self.offer_wait_goes_on() || !self.flow.active {
            if !matches!(self.offer_wait, Some(OfferWait { expired: true, .. })) {
                self.stop_offer_wait();
            }
            return;
        }
        let now = Instant::now();
        let mut wait = self.offer_wait.unwrap_or_else(|| OfferWait::started(now));
        wait.expired = false;
        // A look that lost the connection says nothing about the cause.
        if self.waiting_for_offer() {
            wait.full_runs = self.last_failure().and_then(|failure| failure.reason.as_deref())
                == Some(MISSING_PREREQUISITE);
        }
        self.offer_wait = Some(wait);
        match recheck_step(wait.since, now, self.env.offer_recheck) {
            RecheckStep::Wait(delay) => self.schedule_offer_recheck(delay, cx),
            RecheckStep::Expire => self.expire_offer_wait(cx),
        }
    }

    fn schedule_offer_recheck(&mut self, delay: Duration, cx: &mut Context<Self>) {
        let generation = self.offer_wait_generation.next();
        // Get ready's minutes waited move on between looks.
        let tick = self.env.offer_recheck.tick;
        self.offer_wait_tick = Some(cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(tick).await;
                let ticking = this
                    .update(cx, |this, cx| {
                        cx.notify();
                        this.offer_wait_generation == generation && this.offer_rechecks_active()
                    })
                    .unwrap_or(false);
                if !ticking {
                    break;
                }
            }
        }));
        self.offer_wait_task = Some(cx.spawn(async move |this, cx| {
            cx.background_executor().timer(delay).await;
            this.update(cx, |this, cx| {
                if this.offer_wait_generation != generation || !this.offer_rechecks_active() {
                    return;
                }
                // A look put off past the end of the wait ends it instead.
                let since = this.offer_wait.map_or_else(Instant::now, |wait| wait.since);
                if since.elapsed() > this.env.offer_recheck.window {
                    this.expire_offer_wait(cx);
                    return;
                }
                if this.preparation.busy()
                    || !this.flow.active
                    || this.flow.step != Step::Ready
                    || this.locked()
                {
                    // Get ready isn't where a run can start; look again later.
                    this.schedule_offer_recheck(this.env.offer_recheck.interval, cx);
                    return;
                }
                log::info!("Looking again for the Windows release Windows Update hasn't offered yet");
                let offer_only = !this.offer_wait.is_some_and(|wait| wait.full_runs);
                // A check that now fails, such as the connection, refuses the
                // look; the wait goes on, and still ends on time.
                if !this.start_preparation(offer_only, cx) {
                    this.schedule_offer_recheck(this.env.offer_recheck.interval, cx);
                }
            })
            .ok();
        }));
    }

    /// The wait is over: the settings go back, as when stopping, and Get
    /// ready says to check again later. While something else runs, the
    /// settings go back once it's done. An Atlas install still to finish
    /// puts them back as its last step and needs the record until then, so
    /// there the looks just stop, and Get ready offers Check again.
    fn expire_offer_wait(&mut self, cx: &mut Context<Self>) {
        self.offer_wait_task = None;
        self.offer_wait_tick = None;
        if self.resume_target().is_some() || self.rebuilt_windows_awaits_install() {
            log::info!(
                "Windows Update offered nothing while Atlas waited; the Atlas install puts the settings back"
            );
            self.stop_offer_wait();
            // The ticks that redrew Get ready have stopped with the looks.
            cx.notify();
            return;
        }
        if !self.may_restore_update_access()
            && self.update_access.as_ref().is_some_and(|access| access.journal.is_some())
        {
            self.schedule_offer_recheck(self.env.offer_recheck.interval, cx);
            return;
        }
        log::info!("Windows Update offered nothing while Atlas waited; putting the settings back");
        if let Some(wait) = self.offer_wait.as_mut() {
            wait.expired = true;
        }
        self.restore_update_access(cx);
    }

    pub(super) fn stop_offer_wait(&mut self) {
        self.offer_wait = None;
        self.offer_wait_task = None;
        self.offer_wait_tick = None;
        self.offer_waiting_since = None;
        self.offer_wait_generation.next();
    }

    /// Opened again on a move whose last run found no offer: once checks are
    /// done, Get ready looks once more by itself.
    pub(super) fn check_offer_on_reopen(&mut self, cx: &mut Context<Self>) {
        if self.offer_reopen_checked
            || !self.transition_waiting_for_offer()
            || !self.flow.active
            || self.flow.step != Step::Ready
            || self.preparation != State::Idle
            || !self.preparation_may_start()
        {
            return;
        }
        self.offer_reopen_checked = true;
        log::info!("Looking again for the Windows release Windows Update hadn't offered");
        let offer_only = self.last_recorded_reason() != Some(MISSING_PREREQUISITE);
        self.start_preparation(offer_only, cx);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn timing() -> OfferRecheckTiming {
        OfferRecheckTiming::default()
    }

    /// The time waited is said in whole minutes, rounded down, and not at
    /// all under a minute: never zero, and never a ticking clock.
    #[test]
    fn the_wait_is_counted_in_whole_minutes() {
        let start = Instant::now();
        let at = |seconds: u64| start + Duration::from_secs(seconds);
        assert_eq!(waited_minutes(start, at(59)), None);
        assert_eq!(waited_minutes(start, at(60)), Some(1));
        assert_eq!(waited_minutes(start, at(34 * 60 + 59)), Some(34));
        assert_eq!(waited_minutes(at(10), start), None, "a clock that went backwards");
    }

    #[test]
    fn it_looks_every_ten_minutes_for_two_hours_then_stops() {
        let since = Instant::now();
        let at = |minutes: u64| since + Duration::from_secs(minutes * 60);
        assert_eq!(recheck_step(since, at(0), timing()), RecheckStep::Wait(Duration::from_secs(600)));
        assert_eq!(recheck_step(since, at(100), timing()), RecheckStep::Wait(Duration::from_secs(600)));
        assert_eq!(recheck_step(since, at(110), timing()), RecheckStep::Wait(Duration::from_secs(600)));
        assert_eq!(
            recheck_step(since, at(111), timing()),
            RecheckStep::Expire,
            "the next look would be past 2 hours"
        );
        assert_eq!(recheck_step(since, at(120), timing()), RecheckStep::Expire);
        let looks = (0..=120)
            .step_by(10)
            .take_while(|m| recheck_step(since, at(*m), timing()) != RecheckStep::Expire);
        assert_eq!(looks.count(), 12, "a look at 10, 20 … 120 minutes after the first");
    }
}
