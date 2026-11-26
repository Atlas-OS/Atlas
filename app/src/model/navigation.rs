//! Moving between pages and through the install flow's steps, and starting
//! or leaving the flow.

use std::path::PathBuf;

use gpui::Context;

use super::install::disarm_completion;
use super::{
    Acquisition, AppModel, ElevationProblem, Page, ReadyStatus, RestoreStatus, RunState, ScreenKind, Step,
    UpdatePath,
};
use crate::services::iso;
use crate::services::settings::{self, InstallDraft};

/// Where the launch asked to open, kept while startup recovery is still
/// finding out what to resume.
#[derive(Clone, Debug)]
pub(super) struct PendingStart {
    page: Option<Page>,
    step: Option<Step>,
    package: Option<PathBuf>,
    /// `page_visit` once the page had opened; any later visit is the user's.
    visit: u64,
}

impl AppModel {
    /// Whether [`navigate`](Self::navigate) would go to `page` now. Nothing
    /// leaves a running preparation, an ISO or USB job, or the installing
    /// view, which covers every page; controls that navigate are hidden or
    /// disabled when this says no, and `navigate` refuses as a backstop. A
    /// preparation can start while the window shows another page (a look for
    /// the Windows Update offer while Atlas waits for it), so the Install
    /// page, which shows its progress and Stop, can always be reached.
    pub fn can_navigate(&self, page: Page) -> bool {
        !(self.preparation.busy() && page != Page::Install)
            && !(self.iso_busy && page != Page::Iso)
            && !(self.install_in_progress() && page != Page::Install)
    }

    /// Where the page's back arrow and Escape go: the report page returns to
    /// the page it was opened from, while that page still has something to
    /// show; everything else returns home. While a preparation runs, only
    /// the Install page can be reached, so every other page leads there.
    pub fn back_target(&self) -> Page {
        match (self.page, self.report_return) {
            (page, _) if page != Page::Install && self.preparation.busy() => Page::Install,
            (Page::Report, Page::Install) if !self.flow.active => Page::Home,
            (Page::Report, origin) => origin,
            _ => Page::Home,
        }
    }

    /// Opens ISO creation to reinstall this PC, from a message that
    /// recommends it: the ISO page preselects This PC once, on arrival.
    pub fn navigate_iso_for_this_pc(&mut self, cx: &mut Context<Self>) {
        if self.can_navigate(Page::Iso) {
            self.iso_for_this_pc = true;
            self.navigate(Page::Iso, cx);
        }
    }

    pub fn navigate(&mut self, page: Page, cx: &mut Context<Self>) {
        if !self.can_navigate(page) {
            return;
        }
        if page != self.page {
            // Only Get ready shows the countdown to the restart updating
            // needs, and Not now with it: leaving puts the restart off.
            if page != Page::Install {
                self.decline_preparation_restart(cx);
            }
            if page == Page::Report {
                self.report_return = self.page;
            }
            self.page = page;
            self.page_visit += 1;
            self.refresh_page_notices(cx);
        }
        self.sync_security_watch(cx);
        // Get ready waits for the user to be on it before it acts by itself.
        if page == Page::Install {
            self.advance_ready(cx);
        }
        cx.notify();
    }

    fn after_step_change(&mut self, cx: &mut Context<Self>) {
        self.preflight_problem = None;
        // Leaving an unsuccessful result starts a new attempt; its record and
        // in-memory log go, the log file stays under Logs.
        if self.flow.run == RunState::Idle && self.session.is_some() {
            self.clear_session(cx);
        }
        if self.flow.step == Step::Ready {
            self.enter_ready(cx);
        }
        if self.flow.step == Step::Options && self.flow.may_edit() {
            // First, as whether the keyboard question is asked follows it.
            self.refresh_keyboard_layouts();
            self.apply_recorded_choices();
        }
        self.save_draft(cx);
        self.sync_security_watch(cx);
        cx.notify();
        // Last, as moving on runs this again for the next step.
        if self.flow.step == Step::Ready {
            self.advance_ready(cx);
        }
    }

    /// Revisits an earlier step (from the stepper or a "go to" button).
    /// Back on Get ready or Windows Security on purpose, it stays there
    /// until the user moves on.
    pub fn set_step(&mut self, step: Step, cx: &mut Context<Self>) {
        if self.flow.go_to(step).is_ok() {
            self.option_screen = 0;
            self.returning_to_install = false;
            if step == Step::Ready {
                self.ready_moves_on = false;
            }
            self.security_on_purpose = step == Step::Security;
            self.after_step_change(cx);
        }
    }

    /// What Get ready does by itself once nothing waits for the user: it
    /// starts updating (see [`AppModel::updates_start_by_themselves`]), and
    /// once it's done, moves on to Your choices (see
    /// [`AppModel::ready_moves_on_by_itself`]). Called wherever what they
    /// wait for can change: a check reporting, a choice on Get ready, the
    /// step or page showing, the install record read again.
    pub(super) fn advance_ready(&mut self, cx: &mut Context<Self>) {
        self.update_by_itself(cx);
        if self.ready_moves_on_by_itself() {
            log::info!("Get ready is done; moving on to Your choices");
            self.ready_moves_on = false;
            self.next_step(cx);
        }
    }

    /// Whether Get ready moves on to Your choices by itself now: once per
    /// visit, when everything has passed with nothing to read, the package
    /// is ready and Windows is up to date. Not when the user came back to it
    /// on purpose, and not when a check passed with a note or needs the
    /// user's confirmation (see [`ReadyStatus::Ready`]): they may want to
    /// read it first.
    pub fn ready_moves_on_by_itself(&self) -> bool {
        self.env.automatic_get_ready
            && self.ready_moves_on
            && !super::preview::active()
            && self.page == Page::Install
            && self.flow.active
            && self.flow.step == Step::Ready
            && self.flow.may_edit()
            && !self.locked()
            && self.ready_status() == Some(ReadyStatus::Ready)
            && self.ready_to_continue()
    }

    /// Opens Your choices at what a Change link's row lists. How Atlas
    /// updates goes back through the first screen of an update or
    /// reinstall, as its answer decides which questions follow. Any other
    /// row opens the screen of questions, with the extras unfolded for
    /// theirs, and from the Install step, Continue then leads straight back.
    pub fn edit_options(&mut self, kind: ScreenKind, cx: &mut Context<Self>) {
        if kind == ScreenKind::UpdatePath {
            self.set_step(Step::Options, cx);
            return;
        }
        let from_install = self.flow.step == Step::Install;
        if self.flow.go_to(Step::Options).is_ok() {
            self.option_screen = self.choices_screen().unwrap_or(0);
            self.returning_to_install = from_install;
            self.extras_shown |= kind == ScreenKind::Extras;
            self.after_step_change(cx);
        }
    }

    /// Next screen of the Options step, or the next step.
    pub fn next_step(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() || (self.flow.step == Step::Ready && self.install_block().is_some()) {
            return;
        }
        if self.flow.step == Step::Options && self.flow.may_edit() && self.flow.active {
            if std::mem::take(&mut self.returning_to_install) {
                // Back to the summary the Change link came from. Windows
                // Security was watched meanwhile; it is shown again only
                // when its reading no longer passes.
                if self.flow.advance().is_ok() {
                    if self.security_ok() {
                        self.flow.advance().ok();
                    }
                    self.option_screen = 0;
                    self.after_step_change(cx);
                }
                return;
            }
            let screen = self.current_option_screen();
            if screen + 1 < self.option_screens().len() {
                self.option_screen = screen + 1;
                self.after_step_change(cx);
                return;
            }
        }
        // Before the desktop exists, options staged with the ISO stand in
        // for the Options step when the package accepts them.
        let skip_staged_options = self.before_desktop
            && self.flow.step == Step::Ready
            && self.ready_to_continue()
            && iso::validate_options(self.manifest(), &self.effective_options()).is_ok();
        if self.flow.advance().is_ok() {
            if skip_staged_options {
                self.flow.advance().ok();
            }
            self.option_screen = 0;
            self.after_step_change(cx);
        }
    }

    /// Previous screen of the Options step, or the previous step. Coming
    /// back into Options from later lands on its last screen.
    pub fn previous_step(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        self.returning_to_install = false;
        // From the screen showing: a draft's index can be past the last
        // screen of a package that has fewer.
        let screen = self.current_option_screen();
        if self.flow.step == Step::Options && self.flow.may_edit() && self.flow.active && screen > 0 {
            self.option_screen = screen - 1;
            self.after_step_change(cx);
            return;
        }
        if let Ok(step) = self.flow.back() {
            self.option_screen =
                if step == Step::Options { self.option_screens().len().saturating_sub(1) } else { 0 };
            if step == Step::Ready {
                self.ready_moves_on = false;
            }
            self.security_on_purpose = step == Step::Security;
            self.after_step_change(cx);
        }
    }

    /// Opens where the launch asked: a page, a step (review tooling) or a
    /// package ("Open with"). While startup recovery is still finding out
    /// what to resume, the rest waits for its answer, so a saved draft or a
    /// recorded install is never replaced by a flow begun before either was
    /// seen. Only a page outside the install flow opens at once.
    pub fn apply_start(
        &mut self,
        page: Option<Page>,
        step: Option<Step>,
        package: Option<PathBuf>,
        cx: &mut Context<Self>,
    ) {
        if self.recovering {
            if let Some(page) = page.filter(|page| *page != Page::Install) {
                self.navigate(page, cx);
            }
            self.pending_start = Some(PendingStart { page, step, package, visit: self.page_visit });
            return;
        }
        if let Some(page) = page {
            if page == Page::Install && !self.flow.active {
                self.start_flow_at(Step::Ready, cx);
            }
            self.navigate(page, cx);
        }
        if let Some(step) = step {
            self.start_flow_at(step, cx);
        }
        if let Some(path) = package {
            self.load_package_file(path, cx);
        }
    }

    /// Applies the start request that waited for recovery, into whatever
    /// flow recovery resumed or attached.
    pub(super) fn apply_pending_start(&mut self, cx: &mut Context<Self>) {
        if let Some(PendingStart { page, step, package, .. }) = self.pending_start.take() {
            self.apply_start(page, step, package, cx);
        }
    }

    /// Forgets the start page once the user has gone elsewhere while
    /// recovery ran, so recovery never pulls them back to it. An Install
    /// request stays: it also starts the flow.
    pub(super) fn drop_left_start_page(&mut self) {
        if let Some(pending) = &mut self.pending_start
            && pending.page != Some(Page::Install)
            && pending.visit != self.page_visit
        {
            pending.page = None;
        }
    }

    /// Opens the flow at a step given on the command line (review tooling).
    pub fn start_flow_at(&mut self, step: Step, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        if self.flow.resume(step).is_ok() {
            self.flow_id = Some(settings::new_flow_id());
            self.own_session = None;
            self.returning_to_install = false;
            self.extras_shown = true;
            self.begin_get_ready();
            self.take_over_draft(cx);
            self.after_step_change(cx);
            self.navigate(Page::Install, cx);
        }
    }

    /// A flow arrives at Get ready, not on purpose: Get ready may start
    /// updating, and move on, by itself.
    pub(super) fn begin_get_ready(&mut self) {
        self.updates_held = false;
        self.ready_moves_on = true;
    }

    /// Starts the install flow. Everything in it needs administrator rights,
    /// so the elevation prompt comes first; the draft lets the elevated copy
    /// resume here instead of starting over.
    pub fn begin_install(&mut self, cx: &mut Context<Self>) {
        self.begin_flow(false, cx);
    }

    /// Starts the install flow on Windows that looks used (see
    /// [`AppModel::windows_looks_used`]), the user having accepted the risk:
    /// the acceptance holds for this flow, Atlas's own restarts included,
    /// and is in the draft the elevated copy resumes.
    pub fn begin_install_on_used_windows(&mut self, cx: &mut Context<Self>) {
        self.begin_flow(true, cx);
    }

    fn begin_flow(&mut self, used_windows_accepted: bool, cx: &mut Context<Self>) {
        if self.elevating {
            return;
        }
        self.refresh_atlas_state();
        if self.start_block().is_some() {
            cx.notify();
            return;
        }
        // A put-back of Windows Update settings counts too: under it the new
        // flow's checks and package are refused, and nothing starts them after.
        if self.locked() {
            return;
        }
        if self.recovering || self.flow.begin().is_err() {
            return;
        }
        self.checks.clear();
        self.check_tasks.clear();
        self.acknowledged.clear();
        self.security_confirmation = None;
        self.preflight_problem = None;
        self.elevation_error = None;
        // Licence terms, the version choice and going on past the used-Windows
        // warning belong to one flow.
        self.windows_terms_accepted = false;
        self.windows_transition_declined = false;
        self.used_windows_accepted = used_windows_accepted;
        self.begin_get_ready();
        self.recorded_choices_applied = false;
        self.update_path = UpdatePath::Keep;
        self.store_outcome_seen = None;
        // So does a preparation that finished, failed or stopped; a restart it
        // asked for, or made, is kept.
        self.forget_preparation();
        self.stop_offer_wait();
        // An earlier put-back that failed is offered again from what the
        // record says now, not from that failure.
        if matches!(self.restore_status, RestoreStatus::Failed(_)) {
            self.restore_status = RestoreStatus::Idle;
        }
        // So is a package attempt that failed for an earlier flow or on the
        // ISO page: this flow tries again rather than showing that failure.
        if matches!(self.acquisition, Acquisition::Failed(_)) {
            self.acquisition = Acquisition::Idle;
        }
        self.security_reminder = false;
        self.forget_pending_reminder(cx);
        self.returning_to_install = false;
        self.extras_shown = true;
        // A new flow, begun on purpose, takes the draft over from whatever
        // flow held it; from here on only this window may change it.
        self.flow_id = Some(settings::new_flow_id());
        self.own_session = None;
        if self.elevated {
            self.take_over_draft(cx);
            self.enter_ready(cx);
            self.navigate(Page::Install, cx);
            return;
        }
        // The draft must be on disk before the elevated copy starts, so it
        // resumes here instead of starting over; the write is awaited, off
        // the window's thread.
        let Some(draft) = self.current_draft() else { return };
        let saved = self.store.transact(move |doc| doc.draft = Some(draft));
        self.elevating = true;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let saved = saved.await;
            let ready = this
                .update(cx, |this, cx| {
                    if !this.flow.active || this.locked() {
                        this.elevating = false;
                        cx.notify();
                        return false;
                    }
                    let Err(error) = saved else {
                        // This flow's draft replaced whatever an earlier
                        // failed write left to replay.
                        this.unsaved_draft = None;
                        return true;
                    };
                    this.elevating = false;
                    this.flow.cancel().ok();
                    this.flow_id = None;
                    this.elevation_error = Some(ElevationProblem::DraftNotSaved { error });
                    cx.notify();
                    false
                })
                .unwrap_or(false);
            if ready {
                Self::relaunch_as_administrator(this, cx, |this, cx| {
                    this.flow.cancel().ok();
                    this.clear_draft(cx);
                    this.flow_id = None;
                    this.elevation_error = Some(ElevationProblem::Declined);
                })
                .await;
            }
        })
        .detach();
    }

    /// Leaves the flow. Refused while an install is in progress. Whatever the
    /// flow was doing in the background (acquiring a package, running
    /// checks) is cancelled with it; a new flow starts from nothing.
    pub fn cancel_flow(&mut self, cx: &mut Context<Self>) {
        if self.preparation.busy() {
            return;
        }
        let finished_ok = self.flow.run.succeeded();
        if self.flow.cancel().is_err() {
            return;
        }
        self.returning_to_install = false;
        self.stop_offer_wait();
        self.stop_preparation_countdown();
        // Protection was switched off for an install that is not happening
        // (or that stopped early); remind the user to put it back. Without
        // Defender there is nothing to put back.
        self.security_reminder = !finished_ok && self.security.defender_present && self.security.any_off();
        if self.security_reminder {
            // The flow's reading is newer than any Home took before it began.
            self.protection = None;
            self.awaiting_reminder_reading = false;
            // Kept in settings, so the reminder survives a relaunch.
            self.remember_pending_reminder(cx);
        }
        self.security_confirmation = None;
        // A relaunch that failed inside the flow has nothing left to retry.
        self.elevation_error = None;
        self.cancel_acquisition();
        self.check_tasks.clear();
        if finished_ok {
            // Done acknowledges a success and abandons nothing: it closes out
            // the install, then resumes any draft another flow saved meanwhile.
            self.flow_id = None;
            self.navigate(Page::Home, cx);
            let picked_up = |this: &mut Self, remaining: Option<InstallDraft>, cx: &mut Context<Self>| {
                this.settings.draft = remaining;
                if !this.flow.active {
                    this.resume_draft(cx);
                }
            };
            match self.forget_session() {
                Some(record) => self.finalize_completed(record, picked_up, cx),
                None => self.persist(|doc| doc.draft.clone(), picked_up, cx),
            }
        } else {
            if self.session.is_some() {
                disarm_completion();
            }
            self.clear_session(cx);
            self.clear_draft(cx);
            self.flow_id = None;
            self.navigate(Page::Home, cx);
        }
    }

    pub(super) fn enter_ready(&mut self, cx: &mut Context<Self>) {
        if self.checks.is_empty() {
            self.run_checks(cx);
        }
        if self.package.is_none()
            && !self.acquisition.is_busy()
            && !matches!(self.acquisition, Acquisition::Failed(_))
        {
            if self.bundled() {
                self.load_bundled_package(cx);
            } else {
                self.acquire_latest(cx);
            }
        }
    }
}
