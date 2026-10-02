//! Windows preparation before the install, and the restart it may need,
//! saved so the flow resumes after it.

use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use futures::StreamExt;
use gpui::Context;

use super::drafts::DraftWrite;
use super::{AppModel, RestartKind, Step, preview};
use crate::services::preparation::{
    self, Drivers, Operation, PreparationRequest, RestartProblem, Stage, State, Status, StoreOutcome,
};
use crate::services::settings::InstallDraft;
use crate::t;

impl AppModel {
    pub fn driver_preference(&self) -> Drivers {
        self.settings.drivers.unwrap_or(self.driver_default)
    }

    pub fn set_drivers(&mut self, drivers: Drivers, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() || self.preparation_choices_fixed() {
            return;
        }
        self.settings.drivers = Some(drivers);
        // Preparation starts over under the new policy, on disk too: a draft
        // resumed later must not skip it.
        self.preparation = Default::default();
        self.persist_preference(move |doc| doc.drivers = Some(drivers), cx);
        self.save_draft(cx);
        cx.notify();
    }

    pub fn prepare_windows(&mut self, cx: &mut Context<Self>) {
        self.start_preparation(false, cx);
    }

    /// Starts a preparation run; `offer_only` only looks for the offer of a
    /// move already targeted, as the looks while waiting for it do.
    pub(super) fn start_preparation(&mut self, offer_only: bool, cx: &mut Context<Self>) {
        log::info!("Windows preparation requested");
        if preview::active() {
            return;
        }
        self.refresh_atlas_state();
        if self.install_block().is_some() {
            cx.notify();
            return;
        }
        if self.locked() || !self.elevated || !self.flow.active || self.flow.step != Step::Ready {
            return;
        }
        // Checking again after the wait ended starts a new wait.
        if self.offer_wait.as_ref().is_some_and(|wait| wait.expired) {
            self.offer_wait = None;
        }
        match preparation::recover_running(&self.env.paths.settings()) {
            Ok(Some(job)) => {
                log::info!(
                    "following a preparation worker still running: pid {} in {}",
                    job.pid,
                    job.directory.display()
                );
                self.follow_preparation(job.directory.clone(), Some(job), false, cx);
                return;
            }
            Err(error) => {
                log::error!("preparation recovery: {error:#}");
                self.fail_preparation(error, cx);
                return;
            }
            Ok(None) => {}
        }
        if !self.preparation_may_start() {
            cx.notify();
            return;
        }
        match preparation::new_job(&self.env.paths.settings()) {
            Ok(job) => self.follow_preparation(job, None, offer_only, cx),
            Err(error) => {
                log::error!("preparation directory: {error:#}");
                self.fail_preparation(error, cx);
            }
        }
    }

    /// Ends a preparation that could not start, with `error` as its reason.
    fn fail_preparation(&mut self, error: anyhow::Error, cx: &mut Context<Self>) {
        self.preparation_progress = None;
        self.preparation_error = Some(format!("{error:#}"));
        self.preparation = State::Failed;
        cx.notify();
    }

    pub(super) fn follow_preparation(
        &mut self,
        job: PathBuf,
        recovered: Option<preparation::RunningJob>,
        offer_only: bool,
        cx: &mut Context<Self>,
    ) {
        let request = PreparationRequest {
            drivers: self.driver_preference(),
            transition: self
                .transition_request()
                .map(|transition| preparation::TransitionRequest { offer_only, ..transition }),
            open_update_access: self.update_access_needed(),
        };
        let run_preparation = self.env.adapters.run_preparation.clone();
        // A run started from the resumed state follows a restart Atlas asked
        // for; if Windows immediately asks for another one, the marker
        // survives restarts and restarting again would loop.
        let after_restart = self.preparation == State::Resumed;
        // Only a run that follows a restart carries on what the one before it
        // did about Microsoft Store.
        if !after_restart {
            self.store_outcome_seen = None;
        }
        self.preparation_restart_at = None;
        self.preparation_problem = None;
        self.preparation_job = Some(job.clone());
        self.preparation_progress = None;
        self.preparation_error = None;
        self.preparation_cancel = Arc::new(AtomicBool::new(false));
        let cancel = self.preparation_cancel.clone();
        self.preparation = if recovered.as_ref().is_some_and(|job| !job.trusted) {
            State::WaitingExternal
        } else {
            State::Running { stage: Default::default(), completed: 0, total: 0 }
        };
        // A check started from Ready no longer vouches for it: a draft resumed
        // after this run must not skip preparation, however the run ends.
        self.save_draft(cx);
        self.preparation_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded();
            let task = cx.background_executor().spawn(async move {
                let report = move |event| {
                    let _ = tx.unbounded_send(event);
                };
                match recovered {
                    Some(recovered) => preparation::monitor(recovered, cancel, report),
                    None => run_preparation(&job, &request, cancel, Box::new(report)),
                }
            });
            let mut did_work = false;
            while let Some(event) = rx.next().await {
                if event.status == Status::Running
                    && matches!(
                        event.stage,
                        Stage::WindowsDownload
                            | Stage::WindowsInstall
                            | Stage::StoreSelfUpdate
                            | Stage::StoreInstall
                            | Stage::StoreRepair
                    )
                {
                    did_work = true;
                }
                this.update(cx, |this, cx| {
                    if event.activity.waiting.as_deref() == Some("feature-offer") {
                        this.offer_waiting_since.get_or_insert_with(std::time::Instant::now);
                    }
                    this.preparation =
                        State::Running { stage: event.stage, completed: event.completed, total: event.total };
                    this.preparation_progress = Some(event);
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                if let Some(outcome) = this
                    .preparation_progress
                    .as_ref()
                    .and_then(|progress| progress.activity.store_outcome.as_deref())
                    .and_then(StoreOutcome::from_id)
                {
                    this.store_outcome_seen =
                        Some(this.store_outcome_seen.map_or(outcome, |earlier| earlier.then(outcome)));
                }
                let reasons = this
                    .preparation_progress
                    .as_ref()
                    .map(|progress| progress.activity.restart_reasons.clone())
                    .unwrap_or_default();
                let state = result
                    .unwrap_or_else(|error| {
                        log::error!("Windows preparation: {error:#}");
                        this.preparation_error = Some(format!("{error:#}"));
                        State::Failed
                    })
                    .settle(after_restart, did_work, reasons);
                if let State::RestartPersists { reasons } = &state {
                    log::warn!(
                        "Windows still reports a pending restart after restarting ({reasons:?}); not restarting again"
                    );
                }
                this.preparation = state;
                // Whatever the run did, Atlas's record may have changed.
                this.refresh_update_access();
                let waited = this.offer_wait.is_some_and(|wait| !wait.expired);
                this.follow_offer_wait(cx);
                // After a wait the user may have stopped watching: the offer
                // came, or the move needs them again.
                if waited
                    && !this.waiting_for_offer()
                    && !matches!(this.preparation, State::Cancelled | State::Network)
                {
                    cx.emit(super::ModelEvent::NeedsAttention);
                }
                if this.preparation == State::Reboot {
                    this.save_preparation_restart(false, cx);
                } else if this.preparation.ready() {
                    // So a draft resumed later does not ask for a
                    // preparation that is already done.
                    this.save_draft(cx);
                }
                this.run_checks(cx);
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    /// What updating did about Microsoft Store itself, once it's done: in
    /// the run that finished, or in one before a restart.
    pub fn store_outcome(&self) -> Option<StoreOutcome> {
        (self.preparation == State::Ready).then_some(self.store_outcome_seen).flatten()
    }

    /// Microsoft Store couldn't be repaired: Get ready offers the repairs
    /// again, and a report.
    pub fn store_repair_failed(&self) -> bool {
        self.preparation == State::Failed
            && self
                .preparation_progress
                .as_ref()
                .and_then(|progress| progress.failure())
                .is_some_and(|failure| failure.reason.as_deref() == Some("store-repair-failed"))
    }

    pub fn restart_preparation(&mut self, cx: &mut Context<Self>) {
        if preview::active() {
            return;
        }
        if self.preparation != State::Reboot || self.hold_for_other_sessions(RestartKind::Preparation, cx) {
            return;
        }
        self.save_preparation_restart(true, cx);
    }

    /// Restarts for Get ready once the user has confirmed it over other
    /// people's sessions.
    pub(super) fn restart_preparation_now(&mut self, cx: &mut Context<Self>) {
        if self.preparation == State::Reboot {
            self.save_preparation_restart(true, cx);
        }
    }

    /// Saves the draft and arms recovery as soon as a worker requires a
    /// restart, also when the user will restart from Windows instead of this
    /// app. The draft is saved before recovery is registered.
    pub(super) fn save_preparation_restart(&mut self, restart: bool, cx: &mut Context<Self>) {
        self.preparation_cancel.store(false, Ordering::Relaxed);
        self.preparation_restart_at.get_or_insert_with(|| chrono::Utc::now().to_rfc3339());
        self.preparation_problem = None;
        let Some(draft) = self.current_draft() else {
            self.preparation_problem = Some(RestartProblem::Save);
            cx.notify();
            return;
        };
        let saved = self.write_owned_draft(draft);
        let register = self.env.adapters.register_preparation_resume.clone();
        // A Windows version change is committed once, right before Atlas
        // restarts, and only once the draft and recovery are in place.
        let commit = (restart && self.restart_needs_commit())
            .then(|| (self.env.adapters.run_operation.clone(), self.env.paths.settings()));
        self.preparation = State::SavingRestart;
        cx.spawn(async move |this, cx| {
            let result = match saved.await {
                DraftWrite::Written => {
                    cx.background_executor().spawn(async move { register() }).await.map_err(|error| {
                        log::error!("preparation recovery registration: {error:#}");
                        RestartProblem::Registration
                    })
                }
                not_saved => {
                    log::error!("could not save preparation before restarting: {not_saved:?}");
                    Err(RestartProblem::Save)
                }
            };
            let result = match (result, commit) {
                (Ok(()), Some((run, settings))) => cx
                    .background_executor()
                    .spawn(async move { run(&settings, Operation::Commit) })
                    .await
                    .map_err(|error| {
                        log::error!("could not commit the Windows version change: {error:#}");
                        RestartProblem::Commit
                    }),
                (result, _) => result,
            };
            this.update(cx, |this, cx| {
                this.preparation = State::Reboot;
                if let Err(problem) = result {
                    this.preparation_problem = Some(problem);
                } else if restart {
                    // Keep recovery armed if shutdown fails: restarting through
                    // Windows should still bring the user back to their draft.
                    match (this.env.adapters.schedule_restart)(&t!("prepare-shutdown-comment")) {
                        Ok(()) => {
                            this.preparation = State::Restarting;
                            let grace = this.env.restart.grace;
                            cx.spawn(async move |this, cx| {
                                cx.background_executor().timer(grace).await;
                                this.update(cx, |this, cx| {
                                    if this.preparation == State::Restarting {
                                        this.preparation = State::Reboot;
                                        this.preparation_problem = Some(RestartProblem::Restart);
                                        cx.notify();
                                    }
                                })
                                .ok();
                            })
                            .detach();
                        }
                        Err(error) => {
                            log::error!("preparation restart: {error:#}");
                            this.preparation_problem = Some(RestartProblem::Restart);
                        }
                    }
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
        cx.notify();
    }

    /// Takes over what a draft says about Windows preparation: a restart
    /// still owed, or a preparation already finished.
    pub(super) fn restore_preparation(&mut self, draft: &InstallDraft) {
        self.windows_transition_declined = draft.windows_transition_declined;
        self.windows_terms_accepted = draft.windows_terms_accepted;
        self.recorded_choices_applied = draft.recorded_choices_applied;
        self.store_outcome_seen = draft.store_outcome.as_deref().and_then(StoreOutcome::from_id);
        self.preparation_restart_at = draft.preparation_restart_at.clone();
        if self.preparation_restart_at.is_some() {
            self.preparation = preparation::state_after_restart(self.preparation_restart_at.as_deref());
        } else if draft.preparation_ready {
            // Windows was prepared before the draft was saved, and no
            // restart is owed: the Install step need not wait for it again.
            self.preparation = State::Ready;
        }
    }
}
