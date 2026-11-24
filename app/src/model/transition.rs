//! Moving Windows to the release a package needs, before installing it, and
//! the Windows Update settings Atlas turns on for an update and puts back.
//! The update worker does the work; this decides when it may, and what the
//! user is asked first.

use std::sync::atomic::Ordering;

use gpui::{Context, Task};

use super::{AppModel, RunState, Step};
use crate::services::preparation::{self, Operation, State, TransitionRequest};
use crate::services::requirements::{CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::update_access::{JournalKind, Phase, UpdateAccess};
use crate::services::windows_release::{self, Transition, TransitionNeed, WindowsBlock};

/// What happens once a run stops that the user stopped while the move
/// waited for Windows Update's offer: a run stops only at its next safe
/// point, so the rest waits for it to end.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(super) enum AfterStop {
    /// Keep this Windows version: the settings go back, and updating
    /// carries on without the move.
    Keep,
    /// Stop updating: the settings go back and the flow ends, as Cancel does.
    Leave,
}

/// Free space read again while a move waits for room on the system drive.
#[derive(Default)]
pub(super) struct SpaceWatch {
    task: Option<Task<()>>,
    /// The task is still reading; it ends by itself once there's room or
    /// nothing waits for it.
    running: bool,
}

/// Where putting back the Windows Update settings stands.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum RestoreStatus {
    #[default]
    Idle,
    Running,
    /// The worker refused or failed; the record stays open.
    Failed(String),
}

/// What stopping the flow now would leave, for the question asked first.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StopQuestion {
    /// Windows Update was turned on for plain updates.
    Access,
    /// Windows hasn't moved; it keeps `current`.
    BeforeMove { current: String },
    /// Windows has moved to `release`, or will at the next restart.
    AfterMove { release: String },
}

impl AppModel {
    /// The move this PC can make for the package at hand, if any.
    pub fn windows_transition(&self) -> Option<(&'static Transition, TransitionNeed)> {
        windows_release::transition_for(&self.system, &self.manifest().supported_builds, self.before_desktop)
    }

    /// Whether Get ready will move Windows: always where the package needs
    /// it, and where it's optional unless the user chose to keep their
    /// version or this PC can't move (see [`AppModel::move_ruled_out`]).
    pub fn transition_chosen(&self) -> bool {
        match self.windows_transition() {
            Some((_, TransitionNeed::Required)) => true,
            Some((_, TransitionNeed::Optional)) => {
                !self.windows_transition_declined && !self.move_ruled_out()
            }
            None => false,
        }
    }

    /// A move this PC can't make, as Get ready's checks read it: hardware
    /// below what Windows 11 requires, or updates from an organisation's
    /// server. Windows Update would refuse it only after the move had begun.
    /// Where moving is optional, Atlas keeps this version without asking;
    /// where it's required, the check says what to do.
    pub fn move_ruled_out(&self) -> bool {
        self.checks.iter().any(|(id, result)| {
            matches!(id, CheckId::MoveHardware | CheckId::MoveUpdateSource)
                && result.as_ref().is_some_and(|result| result.verdict == Verdict::Fail)
        })
    }

    /// Whether Get ready shows the move's own card, first under the
    /// stepper: a move to choose or accept that this PC can make, one under
    /// way, how one ended, or a Windows that reinstalled itself on the way.
    pub fn windows_card_shown(&self) -> bool {
        let offered =
            self.windows_transition().is_some() && (!self.move_ruled_out() || self.transition_open());
        offered || self.move_shows_preparation() || self.rebase_choices().is_some()
    }

    /// Whether the move's card says how updating stands, in place of the
    /// update row: Windows hasn't reached the release the move is for, the
    /// last run ended in one of the move's own outcomes, or the restart owed
    /// finishes the move. The rest of updating comes after the move.
    pub fn move_shows_preparation(&self) -> bool {
        let Some(request) = self.transition_request() else {
            return false;
        };
        let before_target =
            self.system.build != request.target_build && (self.transition_open() || !self.move_ruled_out());
        let outcome = self.preparation == State::Failed
            && self
                .preparation_progress
                .as_ref()
                .and_then(|progress| progress.failure())
                .and_then(|failure| failure.reason.as_deref())
                .is_some_and(|reason| reason.starts_with("feature-"));
        let restart = matches!(self.preparation, State::Reboot | State::SavingRestart | State::Restarting)
            && self.restart_needs_commit();
        before_target || outcome || restart
    }

    /// Whether the last run's move ended for a cause one of Get ready's
    /// checks now reports as well: hardware below what Windows 11 requires,
    /// an organisation's update server, or too little free space. The check
    /// says it, with its fix, so how the move stands doesn't say it again.
    pub fn move_outcome_held_by_check(&self) -> bool {
        if self.preparation != State::Failed {
            return false;
        }
        let check = match self
            .preparation_progress
            .as_ref()
            .and_then(|progress| progress.failure())
            .and_then(|failure| failure.reason.as_deref())
        {
            Some("feature-hardware") => CheckId::MoveHardware,
            Some("feature-managed") => CheckId::MoveUpdateSource,
            Some("feature-disk-space") => CheckId::MoveSpace,
            _ => return false,
        };
        self.check_counts(check)
            && self.checks.iter().any(|(id, result)| {
                *id == check && result.as_ref().is_some_and(|result| result.verdict == Verdict::Fail)
            })
    }

    /// The move under way by Atlas's record, if its target is one Atlas knows.
    pub fn recorded_transition(&self) -> Option<&'static Transition> {
        self.update_access
            .as_ref()
            .and_then(UpdateAccess::transition)
            .and_then(|journal| journal.target.as_ref())
            .and_then(|target| windows_release::transition_to(&target.release))
    }

    /// What the next preparation run asks the worker to do about the
    /// Windows version: continue a move under way, or start the one chosen.
    pub fn transition_request(&self) -> Option<TransitionRequest> {
        if self.transition_open() {
            return self
                .recorded_transition()
                .map(|transition| TransitionRequest::new(transition, self.windows_terms_accepted));
        }
        let (transition, _) = self.windows_transition()?;
        self.transition_chosen().then(|| TransitionRequest::new(transition, self.windows_terms_accepted))
    }

    /// Whether a run must turn Windows Update on: it is off, paused or
    /// delayed, or a plain update's record is open.
    pub fn update_access_needed(&self) -> bool {
        self.update_access.as_ref().is_some_and(|access| {
            !access.blockers.is_empty()
                || access.journal.as_ref().is_some_and(|j| j.kind == JournalKind::Access)
        })
    }

    /// A move between releases is under way, by Atlas's record.
    pub fn transition_open(&self) -> bool {
        self.update_access.as_ref().and_then(UpdateAccess::transition).is_some()
    }

    /// Whether the choices that start updating over are fixed: while a move is
    /// under way, whose record decides what runs next, and while a restart is
    /// owed or has just happened, which starting over would forget.
    pub fn preparation_choices_fixed(&self) -> bool {
        use crate::services::preparation::State;
        self.transition_open()
            || matches!(
                self.preparation,
                State::Reboot
                    | State::SavingRestart
                    | State::Restarting
                    | State::Resumed
                    | State::RestartPersists { .. }
            )
    }

    /// Forgets the last preparation run, made for choices that changed, and
    /// what it reported: Get ready offers to start updating again, not a
    /// failure that no longer applies.
    pub(super) fn reset_preparation(&mut self) {
        self.preparation = preparation::State::Idle;
        self.preparation_progress = None;
        self.preparation_error = None;
        self.preparation_source_linked = false;
    }

    /// Keeps the Windows version (`keep`) or moves an optional one. Refused
    /// while anything runs, and while a move is under way: stopping it
    /// decides that. Updating starts over for the new choice, except that a
    /// restart owed or just made is kept, since starting over would forget it.
    pub fn keep_windows_version(&mut self, keep: bool, cx: &mut Context<Self>) {
        if self.locked() || self.transition_open() {
            return;
        }
        if self.windows_transition_declined == keep {
            return;
        }
        self.windows_transition_declined = keep;
        if !self.preparation_choices_fixed() {
            self.reset_preparation();
        }
        self.save_draft(cx);
        // Keeping this version needs no licence terms: updating can start.
        self.advance_ready(cx);
        cx.notify();
    }

    /// Accepts or withdraws the licence terms. While the choices are fixed
    /// they can still be accepted, as a new flow continuing a move must, but
    /// not withdrawn, and updating doesn't start over.
    pub fn accept_windows_terms(&mut self, accepted: bool, cx: &mut Context<Self>) {
        let fixed = self.preparation_choices_fixed();
        if self.locked() || (fixed && !accepted) {
            return;
        }
        self.windows_terms_accepted = accepted;
        if !fixed {
            self.reset_preparation();
        }
        self.save_draft(cx);
        // Accepting the terms is the go-ahead for the move: it starts now.
        self.advance_ready(cx);
        cx.notify();
    }

    /// Accept and update: accepts the licence terms, the go-ahead for the
    /// move, and starts it, also after the user stopped updating or a run
    /// stopped for the terms. Something still to finish, such as the checks,
    /// holds the start until then (see [`AppModel::preparation_may_start`]).
    pub fn accept_and_update(&mut self, cx: &mut Context<Self>) {
        if self.locked() {
            return;
        }
        self.updates_held = false;
        self.accept_windows_terms(true, cx);
        if matches!(self.preparation, State::Idle | State::Cancelled | State::Failed | State::Network) {
            self.start_preparation(false, cx);
        }
    }

    /// Whether keeping this Windows version can be chosen now, where moving
    /// is optional: before the new release is installed, while nothing runs
    /// but the wait for its offer, and while the settings Atlas turned on for
    /// it can be put back, which an unfinished Atlas install leaves to itself
    /// (see [`AppModel::keep_waits_for_install`]). A run under way counts as
    /// having turned them on, as it records them before Atlas reads them.
    pub fn may_keep_windows_version(&self) -> bool {
        let journal = self.update_access.as_ref().and_then(UpdateAccess::transition);
        let quiet = !self.preparation.busy() || self.offer_wait_shown();
        !self.flow.locked()
            && !self.iso_busy
            && !self.elevating
            && self.restore_status != RestoreStatus::Running
            && quiet
            && !matches!(
                self.preparation,
                State::Reboot
                    | State::SavingRestart
                    | State::Restarting
                    | State::Resumed
                    | State::RestartPersists { .. }
            )
            && !self.keep_waits_for_install()
            && journal.is_none_or(|journal| !journal.installed() && self.elevated)
    }

    /// Whether choosing to keep this version needs the user's go-ahead
    /// first: the move has begun, so stopping it puts back what Atlas turned
    /// on, as the stop question says.
    pub fn keeping_stops_the_move(&self) -> bool {
        self.transition_open() || (self.preparation.busy() && self.transition_chosen())
    }

    /// Whether keeping this version waits for an unfinished Atlas install,
    /// or one owed to a Windows that rebuilt itself: the move has begun, and
    /// that install's own last step puts back what Atlas turned on for it,
    /// so nothing else may until then.
    pub fn keep_waits_for_install(&self) -> bool {
        self.keeping_stops_the_move()
            && (self.resume_target().is_some() || self.rebuilt_windows_awaits_install())
    }

    /// Keeps this Windows version once the move has begun, as the user
    /// confirmed (see [`AppModel::keeping_stops_the_move`]): a run waiting
    /// for the offer stops first, then the settings Atlas turned on go back,
    /// and updating carries on without the move.
    pub fn keep_windows_version_now(&mut self, cx: &mut Context<Self>) {
        if !self.may_keep_windows_version() {
            return;
        }
        if self.preparation.busy() {
            log::info!("Keeping this Windows version once the run waiting for the offer stops");
            self.after_stop = Some(AfterStop::Keep);
            self.preparation_cancel.store(true, Ordering::Relaxed);
            cx.notify();
            return;
        }
        self.keep_after_move_stops(false, cx);
    }

    /// Puts the settings back, then keeps this version; `stopped` when a run
    /// stopped for this alone.
    fn keep_after_move_stops(&mut self, stopped: bool, cx: &mut Context<Self>) {
        if self.update_access.as_ref().is_none_or(|access| access.journal.is_none()) {
            self.keep_without_move(cx);
            return;
        }
        if !self.may_restore_update_access() {
            // What changed while the run stopped, such as an Atlas install
            // left unfinished, holds the settings, so the move stays. A run
            // stopped only to keep this version leaves updating free to carry
            // on, and Get ready says why the version wasn't kept.
            log::info!("not keeping this Windows version: the settings can't be put back now");
            if stopped && self.preparation == State::Cancelled {
                self.updates_held = false;
                self.reset_preparation();
                self.advance_ready(cx);
            }
            cx.notify();
            return;
        }
        self.restore_update_access_then(
            |this, done, cx| {
                if done {
                    this.keep_without_move(cx);
                }
            },
            cx,
        );
    }

    fn keep_without_move(&mut self, cx: &mut Context<Self>) {
        log::info!("Keeping this Windows version; updating carries on without the move");
        self.windows_transition_declined = true;
        self.updates_held = false;
        self.stop_offer_wait();
        self.reset_preparation();
        self.save_draft(cx);
        self.advance_ready(cx);
        cx.notify();
    }

    /// Stop updating while the move waits for the offer, as the user
    /// confirmed: a look under way stops first; then the settings go back
    /// and the flow ends, as Cancel does.
    pub fn stop_waiting_for_offer(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            log::info!("Stopping the move once the run waiting for the offer stops");
            self.after_stop = Some(AfterStop::Leave);
            self.preparation_cancel.store(true, Ordering::Relaxed);
            cx.notify();
        } else {
            self.stop_updating(cx);
        }
    }

    /// The question asked before stopping a move that waits for the offer,
    /// or before keeping this version: nothing has moved yet.
    pub fn move_stop_question(&self) -> StopQuestion {
        StopQuestion::BeforeMove { current: self.system.display_version.clone() }
    }

    /// Once a run ends: what the user asked for while it waited for the
    /// offer (see [`AfterStop`]). A run that found the offer meanwhile has
    /// gone on with the move, which nothing then undoes.
    pub(super) fn finish_after_stop(&mut self, cx: &mut Context<Self>) {
        let Some(after) = self.after_stop.take() else {
            return;
        };
        if !matches!(self.preparation, State::Cancelled | State::Failed | State::Network) {
            log::info!(
                "the run ended as {:?} before it stopped; {after:?} isn't carried out",
                self.preparation
            );
            return;
        }
        match after {
            AfterStop::Keep => self.keep_after_move_stops(true, cx),
            AfterStop::Leave => self.stop_updating(cx),
        }
    }

    /// A move waits for room on the system drive: the free-space check
    /// failed while the move counts.
    fn free_space_short(&self) -> bool {
        self.check_counts(CheckId::MoveSpace)
            && self.checks.iter().any(|(id, result)| {
                *id == CheckId::MoveSpace
                    && result.as_ref().is_some_and(|result| result.verdict == Verdict::Fail)
            })
    }

    /// While a move waits for room, reads the free space again every so
    /// often, and once there's enough, carries on by itself: a run that
    /// stopped for the space starts over, and one not started yet starts.
    pub(super) fn follow_free_space(&mut self, cx: &mut Context<Self>) {
        if self.space_watch.running || !self.free_space_short() || super::preview::active() {
            return;
        }
        let interval = self.env.offer_recheck.space;
        let run = self.env.adapters.run_check.clone();
        let context = self.check_context();
        self.space_watch.running = true;
        self.space_watch.task = Some(cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(interval).await;
                let (run, context) = (run.clone(), context.clone());
                let result =
                    cx.background_executor().spawn(async move { run(CheckId::MoveSpace, &context) }).await;
                let reading =
                    this.update(cx, |this, cx| this.observe_free_space(result, cx)).unwrap_or(false);
                if !reading {
                    break;
                }
            }
        }));
    }

    /// Records a reading of the free space; returns whether to read again.
    fn observe_free_space(&mut self, result: CheckResult, cx: &mut Context<Self>) -> bool {
        if !self.free_space_short() || !self.flow.active || self.flow.step != Step::Ready {
            self.space_watch.running = false;
            return false;
        }
        let enough = result.verdict == Verdict::Pass;
        if let Some(slot) = self.checks.iter_mut().find(|(id, _)| *id == CheckId::MoveSpace) {
            slot.1 = Some(result);
        }
        if enough {
            log::info!("There's room for the move now; carrying on");
            self.space_watch.running = false;
            let stopped_for_space = self.preparation == State::Failed
                && self
                    .preparation_progress
                    .as_ref()
                    .and_then(|progress| progress.failure())
                    .is_some_and(|failure| failure.reason.as_deref() == Some("feature-disk-space"));
            if stopped_for_space && !self.locked() {
                self.reset_preparation();
            }
            self.advance_ready(cx);
        }
        cx.notify();
        !enough
    }

    /// Whether Update Windows and Store apps may run now. The Windows
    /// compatibility check must pass, or fail only because Atlas moves
    /// Windows here. Before a move, the licence terms must be accepted and
    /// nothing else may stand in the way of the Atlas install: nothing
    /// changes Windows while something would still stop Atlas.
    pub fn preparation_may_start(&self) -> bool {
        if self.driver_choice_required() {
            return false;
        }
        let build =
            self.checks.iter().find(|(id, _)| *id == CheckId::SupportedBuild).and_then(|(_, r)| r.as_ref());
        let chosen = self.transition_chosen();
        let build_ok = build.is_some_and(|result| {
            result.verdict == Verdict::Pass
                || (chosen && matches!(result.detail, CheckDetail::BuildTransition { .. }))
        });
        if !build_ok {
            return false;
        }
        !chosen || (self.windows_terms_accepted && self.blocking_checks_complete() && !self.checks_blocking())
    }

    /// Reads Windows Update's blockers and Atlas's record again.
    pub fn refresh_update_access(&mut self) {
        match (self.env.adapters.read_update_access)() {
            Ok(access) => {
                if let Some(error) = &access.journal_error {
                    log::warn!("the Windows Update record can't be read: {error}");
                }
                self.update_access = Some(access);
            }
            Err(error) => {
                log::warn!("could not read Windows Update settings: {error:#}");
                self.update_access = None;
            }
        }
    }

    /// Why Home can't start the flow on this Windows, for the package Home
    /// would offer. Once a package is loaded, Get ready's checks decide.
    pub fn windows_block(&self) -> Option<WindowsBlock> {
        if self.package.is_some() {
            return None;
        }
        windows_release::windows_block(&self.system, &self.manifest().supported_builds, self.before_desktop)
    }

    /// Whether Put back settings may run: a record is open, nothing runs, no
    /// elevation prompt is up, and no Atlas install is unfinished, nor owed
    /// to a Windows that rebuilt itself: that install's own last step puts
    /// them back, and needs the record until then.
    pub fn may_restore_update_access(&self) -> bool {
        self.update_access.as_ref().is_some_and(|access| access.journal.is_some())
            && !self.rebuilt_windows_awaits_install()
            && !self.locked()
            && !self.elevating
            && self.resume_target().is_none()
    }

    /// Windows rebuilt itself during the move, and the record keeps what the
    /// Atlas install needs to put Atlas back.
    pub fn rebuilt_windows_awaits_install(&self) -> bool {
        self.update_access
            .as_ref()
            .and_then(|access| access.journal.as_ref())
            .is_some_and(|journal| journal.rebase().is_some())
    }

    /// Puts back the Windows Update settings Atlas changed. Without
    /// administrator rights it starts the elevated copy, which offers it again.
    pub fn restore_update_access(&mut self, cx: &mut Context<Self>) {
        self.restore_update_access_then(|_, _, _| {}, cx);
    }

    fn restore_update_access_then(
        &mut self,
        then: impl FnOnce(&mut Self, bool, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        if super::preview::active() {
            return;
        }
        if !self.may_restore_update_access() {
            // Offered before something changed: `then` is dropped
            // unanswered, so the log says why.
            log::info!(
                "not putting back Windows Update settings: record open {}, busy {}, install unfinished {}",
                self.update_access.as_ref().is_some_and(|access| access.journal.is_some()),
                self.locked() || self.elevating,
                self.resume_target().is_some() || self.rebuilt_windows_awaits_install(),
            );
            return;
        }
        if !self.elevated {
            // Nothing may start while the prompt is up, a second Put back
            // included (see `relaunch_as_administrator`).
            self.elevating = true;
            cx.notify();
            cx.spawn(async move |this, cx| {
                Self::relaunch_as_administrator(this, cx, |_, _| {
                    log::info!("putting back declined at the prompt")
                })
                .await;
            })
            .detach();
            return;
        }
        log::info!("Putting back the Windows Update settings changed for an update");
        self.restore_status = RestoreStatus::Running;
        let run = self.env.adapters.run_operation.clone();
        let settings = self.env.paths.settings();
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result =
                cx.background_executor().spawn(async move { run(&settings, Operation::Restore) }).await;
            this.update(cx, |this, cx| {
                this.refresh_update_access();
                let done = match result {
                    Ok(()) => {
                        log::info!("Windows Update settings put back");
                        this.restore_status = RestoreStatus::Idle;
                        true
                    }
                    Err(error) => {
                        log::error!("could not put back Windows Update settings: {error:#}");
                        this.restore_status = RestoreStatus::Failed(format!("{error:#}"));
                        false
                    }
                };
                then(this, done, cx);
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// What Cancel would leave changed, from any step, when the user should
    /// be asked first: Atlas's record is open and no install has started.
    /// After Windows rebuilt itself the record waits for the Atlas install,
    /// so stopping puts nothing back and there is nothing to ask.
    pub fn stop_question(&self) -> Option<StopQuestion> {
        let journal = self.update_access.as_ref()?.journal.as_ref()?;
        if !self.flow.active
            || self.flow.run != RunState::Idle
            || self.locked()
            || self.rebuilt_windows_awaits_install()
        {
            return None;
        }
        Some(match journal.kind {
            JournalKind::Access => StopQuestion::Access,
            JournalKind::Transition
                if journal.installed() || self.system.build == journal.target.as_ref()?.build =>
            {
                StopQuestion::AfterMove { release: journal.target.as_ref()?.release.clone() }
            }
            JournalKind::Transition => {
                StopQuestion::BeforeMove { current: journal.source.display_version.clone() }
            }
        })
    }

    /// Stop updating: puts the settings back, then leaves the flow. If they
    /// can't be put back, the flow is left anyway and Home offers it again.
    pub fn stop_updating(&mut self, cx: &mut Context<Self>) {
        if !self.may_restore_update_access() || !self.elevated {
            self.cancel_flow(cx);
            return;
        }
        self.restore_update_access_then(|this, _, cx| this.cancel_flow(cx), cx);
    }

    /// Whether closing the window would leave Windows Update turned on with
    /// nothing to come back for: before the version change is installed, with
    /// no worker running and no restart owed. Once Atlas has reopened after
    /// a restart, nothing brings the user back any more.
    pub fn update_access_close_guard(&self) -> bool {
        use crate::services::preparation::State;
        let Some(journal) = self.update_access.as_ref().and_then(|access| access.journal.as_ref()) else {
            return false;
        };
        // A preview puts nothing back, so offering to before closing would
        // only ask again.
        self.elevated
            && !super::preview::active()
            && !journal.installed()
            && !matches!(self.preparation, State::Reboot | State::SavingRestart | State::Restarting)
            && self.may_restore_update_access()
    }

    /// Puts the settings back before closing, then tells `then` whether
    /// that worked. If the put-back can't start, as when something started
    /// since closing asked, `then` is dropped uncalled.
    pub fn restore_before_closing(
        &mut self,
        then: impl FnOnce(&mut Self, bool, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        self.restore_update_access_then(then, cx);
    }

    /// Which Windows Update blockers the install that just finished turned
    /// back on as the user had chosen. Only a put-back made by that install's
    /// own last step counts, not one from an earlier update.
    pub fn update_choice_after_install(&self) -> Option<Vec<crate::services::update_access::BlockerKind>> {
        let access = self.update_access.as_ref()?;
        let last = access.last_result.as_ref()?;
        let installed_at = self.installed()?.installed_at_local()?;
        let closed_at = crate::i18n::fmt::parse_local(&last.closed_at)?;
        let gap = installed_at.signed_duration_since(closed_at);
        (last.outcome == "Installed" && gap >= chrono::Duration::zero() && gap < chrono::Duration::hours(6))
            .then(|| {
                // What the install replayed over a setting Atlas had lifted, and
                // what a recorded choice holds now: a setting something else had
                // already turned on before the record was made isn't in the first.
                let mut kinds = last.replayed();
                kinds.extend(
                    access.blockers.iter().filter(|blocker| blocker.owned).map(|blocker| blocker.kind),
                );
                kinds.sort();
                kinds.dedup();
                kinds
            })
    }

    /// Atlas's commit comes before restarting: the last run's restart
    /// reasons ask for it, or the record says a version change is installed
    /// and waits for its restart, which is all a reopened window knows. The
    /// worker commits once per boot whatever it is asked.
    pub(super) fn restart_needs_commit(&self) -> bool {
        let reported = self
            .preparation_progress
            .as_ref()
            .is_some_and(|progress| preparation::finishes_version_change(&progress.activity.restart_reasons));
        let recorded = self
            .update_access
            .as_ref()
            .and_then(UpdateAccess::transition)
            .is_some_and(|journal| journal.phase == Phase::Installed);
        reported || recorded
    }

    /// What a report about a failed or refused Windows update starts with:
    /// the cause and the state of the move, for the team to follow up.
    pub fn report_context(&self) -> Option<String> {
        let failure = self.preparation_progress.as_ref().and_then(|progress| progress.failure());
        let reason =
            failure.and_then(|f| f.reason.as_deref()).filter(|reason| reason.starts_with("feature-"));
        let restore = match &self.restore_status {
            RestoreStatus::Failed(error) => Some(error.as_str()),
            _ => None,
        };
        let journal_error = self.update_access.as_ref().and_then(|access| access.journal_error.as_deref());
        if reason.is_none() && restore.is_none() && journal_error.is_none() {
            return None;
        }
        let mut lines = vec![crate::t!("report-transition-intro"), String::new()];
        if let Some(reason) = reason {
            lines.push(format!("Reason: {reason}"));
        }
        if let Some(code) = failure.and_then(|f| f.error_code.as_deref()) {
            lines.push(format!("Error code: {code}"));
        }
        if let Some(error) = restore {
            lines.push(format!("Put back: {error}"));
        }
        if let Some(error) = journal_error {
            lines.push(format!("Record unreadable: {error}"));
        }
        lines.push(format!(
            "Windows: {} {} {}",
            self.system.build_label(),
            self.system.display_version,
            self.system.edition_id
        ));
        if let Some(request) = self.transition_request() {
            let kbs: Vec<String> = request.kbs.iter().map(|kb| format!("KB{kb}")).collect();
            lines.push(format!(
                "Target: {} ({}, {})",
                request.target_release,
                request.target_build,
                kbs.join(", ")
            ));
        }
        if let Some(journal) = self.update_access.as_ref().and_then(|access| access.journal.as_ref()) {
            lines.push(format!(
                "Record: {:?}, {:?}, since {}",
                journal.kind, journal.phase, journal.created_at
            ));
            lines.push(format!("Turned on: {}", journal.lifted().join(", ")));
            if let Some(last) = journal.history.last() {
                lines.push(format!("Last step: {} {}", last.event, last.detail));
            }
        }
        Some(lines.join("\n"))
    }
}

#[cfg(test)]
impl super::InstallBlock {
    /// The Windows version or edition rules this PC out.
    pub fn windows(&self) -> Option<WindowsBlock> {
        match self {
            super::InstallBlock::Windows { block, .. } => Some(*block),
            _ => None,
        }
    }
}
