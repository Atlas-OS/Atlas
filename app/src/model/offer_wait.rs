//! Waiting for Windows Update to offer the Windows release Get ready moves
//! to. Windows Update can take from a minute to many more to offer it once
//! the target is set, so "not offered" is a wait, not a failure: while the
//! window stays open, Get ready looks again every so often, for a while, and
//! continues the move when the offer comes. Windows Update stays turned on
//! meanwhile; the user agreed to the move and its record is open. When the
//! wait ends without an offer, the settings are put back.

use std::time::{Duration, Instant};

use gpui::Context;

use super::{AppModel, Step};
use crate::environment::OfferRecheckTiming;
use crate::services::preparation::{Activity, State};
use crate::services::update_access::UpdateAccess;

/// The wait for an offer in this flow.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct OfferWait {
    /// When the first search found no offer; the wait lasts a window from here.
    pub since: Instant,
    /// The wait ended without an offer, and the settings were put back.
    pub expired: bool,
    /// When the next look is due, while one is scheduled.
    pub next_check: Option<Instant>,
    /// The looks are full runs: the move waits for a newer monthly update,
    /// which only a full run installs.
    pub full_runs: bool,
}

impl OfferWait {
    pub fn started(since: Instant) -> Self {
        Self { since, expired: false, next_check: None, full_runs: false }
    }
}

/// What Get ready shows of a wait under way: how long Atlas has waited, and
/// when it looks again, in whole minutes; no next look while it looks.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct OfferWaitClock {
    pub waited_minutes: u64,
    pub next_check_minutes: Option<u64>,
}

/// The clock of a wait that began at `waiting_since`, as of `now`. The time
/// waited counts down to whole minutes, at least one; the next look counts
/// up, so it never says zero before it starts.
pub fn wait_clock(waiting_since: Instant, next_check: Option<Instant>, now: Instant) -> OfferWaitClock {
    let waited = now.saturating_duration_since(waiting_since).as_secs() / 60;
    let next = next_check.map(|at| at.saturating_duration_since(now).as_secs().div_ceil(60).max(1));
    OfferWaitClock { waited_minutes: waited.max(1), next_check_minutes: next }
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
    /// Get ready see it when the app opens again.
    pub fn transition_waiting_for_offer(&self) -> bool {
        self.last_recorded_outcome().is_some_and(|detail| {
            detail.contains("reason=feature-not-offered") || detail.contains("reason=feature-prerequisite")
        })
    }

    /// The detail of the record's last entry when it is an outcome, before
    /// the move is installed.
    fn last_recorded_outcome(&self) -> Option<&str> {
        let journal = self.update_access.as_ref().and_then(UpdateAccess::transition)?;
        let entry = journal.history.last().filter(|_| !journal.installed())?;
        (entry.event == "outcome").then_some(entry.detail.as_str())
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

    /// How long Atlas has waited for the offer, counted from the first search
    /// that waited for it, and when it looks again.
    pub fn offer_wait_clock(&self) -> Option<OfferWaitClock> {
        let wait = self.offer_wait.filter(|_| self.offer_wait_running())?;
        let next_check = wait.next_check.filter(|_| !self.preparation.busy());
        Some(wait_clock(self.offer_waiting_since.unwrap_or(wait.since), next_check, Instant::now()))
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
        if let Some(wait) = self.offer_wait.as_mut() {
            wait.next_check = Some(Instant::now() + delay);
        }
        // Get ready's clock moves on between looks, so the wait never looks frozen.
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
                if let Some(wait) = this.offer_wait.as_mut() {
                    wait.next_check = None;
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
                this.start_preparation(offer_only, cx);
            })
            .ok();
        }));
    }

    /// The wait is over: the settings go back, as when stopping, and Get
    /// ready says to check again later. While something else runs, the
    /// settings go back once it's done.
    fn expire_offer_wait(&mut self, cx: &mut Context<Self>) {
        self.offer_wait_task = None;
        self.offer_wait_tick = None;
        if !self.may_restore_update_access()
            && self.update_access.as_ref().is_some_and(|access| access.journal.is_some())
        {
            self.schedule_offer_recheck(self.env.offer_recheck.interval, cx);
            return;
        }
        log::info!("Windows Update offered nothing while Atlas waited; putting the settings back");
        if let Some(wait) = self.offer_wait.as_mut() {
            wait.expired = true;
            wait.next_check = None;
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
        let offer_only = !self
            .last_recorded_outcome()
            .is_some_and(|detail| detail.contains(&format!("reason={MISSING_PREREQUISITE}")));
        self.start_preparation(offer_only, cx);
    }
}

/// The cause a move names when the monthly update it needs isn't installed
/// yet. Only a full run installs one, so a look for it isn't offer-only.
const MISSING_PREREQUISITE: &str = "feature-prerequisite";

#[cfg(test)]
mod tests {
    use super::*;

    fn timing() -> OfferRecheckTiming {
        OfferRecheckTiming::default()
    }

    /// The clock says how long Atlas has waited and when it looks again, in
    /// whole minutes, and never says zero minutes.
    #[test]
    fn the_wait_clock_counts_whole_minutes() {
        let start = Instant::now();
        let at = |seconds: u64| start + Duration::from_secs(seconds);
        assert_eq!(
            wait_clock(start, Some(at(34 * 60 + 360)), at(34 * 60)),
            OfferWaitClock { waited_minutes: 34, next_check_minutes: Some(6) }
        );
        assert_eq!(
            wait_clock(start, Some(at(34 * 60 + 301)), at(34 * 60 + 59)),
            OfferWaitClock { waited_minutes: 34, next_check_minutes: Some(5) },
            "4 min 2 s to go is shown as 5 minutes"
        );
        assert_eq!(
            wait_clock(start, Some(at(10)), at(20)),
            OfferWaitClock { waited_minutes: 1, next_check_minutes: Some(1) },
            "a look already due, a wait just begun"
        );
        assert_eq!(wait_clock(start, None, at(111 * 60)).next_check_minutes, None, "looking now");
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
