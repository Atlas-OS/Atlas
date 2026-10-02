//! Moving Windows to the release a package needs, before installing it, and
//! the Windows Update settings Atlas turns on for an update and puts back.
//! The update worker does the work; this decides when it may, and what the
//! user is asked first.

use gpui::Context;

use super::{AppModel, RunState};
use crate::services::preparation::{self, Operation, TransitionRequest};
use crate::services::requirements::{CheckDetail, CheckId, Verdict};
use crate::services::update_access::{JournalKind, Phase, UpdateAccess};
use crate::services::windows_release::{self, Transition, TransitionNeed, WindowsBlock};

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
    /// version.
    pub fn transition_chosen(&self) -> bool {
        match self.windows_transition() {
            Some((_, TransitionNeed::Required)) => true,
            Some((_, TransitionNeed::Optional)) => !self.windows_transition_declined,
            None => false,
        }
    }

    /// Windows has the new version, or only waits for the restart that
    /// switches it on.
    pub fn transition_installed(&self) -> bool {
        self.update_access
            .as_ref()
            .and_then(UpdateAccess::transition)
            .is_some_and(|journal| journal.installed())
    }

    /// What the next preparation run asks the worker to do about the
    /// Windows version: continue a move under way, or start the one chosen.
    pub fn transition_request(&self) -> Option<TransitionRequest> {
        if let Some(journal) = self.update_access.as_ref().and_then(UpdateAccess::transition) {
            let transition =
                journal.target.as_ref().and_then(|target| windows_release::transition_to(&target.release))?;
            return Some(TransitionRequest::new(transition, self.windows_terms_accepted));
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

    /// Keeps or moves an optional Windows version. Refused while anything
    /// runs, and while a move is under way: stopping it decides that.
    pub fn set_windows_transition(&mut self, keep: bool, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() || self.transition_open() {
            return;
        }
        if self.windows_transition_declined == keep {
            return;
        }
        self.windows_transition_declined = keep;
        // Preparation starts over for the new choice, on disk too.
        self.preparation = Default::default();
        self.save_draft(cx);
        cx.notify();
    }

    /// Accepts or withdraws the licence terms. While the choices are fixed
    /// they can still be accepted, as a new flow continuing a move must, but
    /// not withdrawn, and updating doesn't start over.
    pub fn accept_windows_terms(&mut self, accepted: bool, cx: &mut Context<Self>) {
        let fixed = self.preparation_choices_fixed();
        if self.locked() || !self.flow.may_edit() || (fixed && !accepted) {
            return;
        }
        self.windows_terms_accepted = accepted;
        if !fixed {
            self.preparation = Default::default();
        }
        self.save_draft(cx);
        cx.notify();
    }

    /// Whether Update Windows and Store apps may run now. The Windows
    /// compatibility check must pass, or fail only because Atlas moves
    /// Windows here. Before a move, the licence terms must be accepted and
    /// nothing else may stand in the way of the Atlas install: nothing
    /// changes Windows while something would still stop Atlas.
    pub fn preparation_may_start(&self) -> bool {
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
        if self.playbook.is_some() {
            return None;
        }
        windows_release::windows_block(&self.system, &self.manifest().supported_builds, self.before_desktop)
    }

    /// Whether Put back settings may run: a record is open, nothing runs,
    /// and no Atlas install is unfinished, nor owed to a Windows that rebuilt
    /// itself: that install's own last step puts them back, and needs the
    /// record until then.
    pub fn may_restore_update_access(&self) -> bool {
        self.update_access.as_ref().is_some_and(|access| access.journal.is_some())
            && !self.rebuilt_windows_awaits_install()
            && !self.locked()
            && !self.flow.locked()
            && self.resume_target().is_none()
            && self.restore_status != RestoreStatus::Running
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
        if super::preview::active() || !self.may_restore_update_access() {
            return;
        }
        if !self.elevated {
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
        self.elevated
            && !journal.installed()
            && !matches!(self.preparation, State::Reboot | State::SavingRestart | State::Restarting)
            && self.may_restore_update_access()
    }

    /// Puts the settings back before closing, then tells `then` whether
    /// that worked.
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
