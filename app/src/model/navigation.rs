//! Moving between pages and through the install flow's steps, and starting
//! or leaving the flow.

use std::path::PathBuf;

use gpui::Context;

use super::install::disarm_completion;
use super::{Acquisition, AppModel, ElevationProblem, Page, RunState, Step};
use crate::services::iso;
use crate::services::settings::{self, InstallDraft};

/// Where the launch asked to open, kept while startup recovery is still
/// finding out what to resume.
#[derive(Clone, Debug)]
pub(super) struct PendingStart {
    page: Option<Page>,
    step: Option<Step>,
    playbook: Option<PathBuf>,
    /// `page_visit` once the page had opened; any later visit is the user's.
    visit: u64,
}

impl AppModel {
    /// Whether [`navigate`](Self::navigate) would go to `page` now. Nothing
    /// leaves a running preparation, an ISO or USB job, or the installing
    /// view, which covers every page; controls that navigate are hidden or
    /// disabled when this says no, and `navigate` refuses as a backstop.
    pub fn can_navigate(&self, page: Page) -> bool {
        !self.preparation.busy()
            && !(self.iso_busy && page != Page::Iso)
            && !(self.install_in_progress() && page != Page::Install)
    }

    /// Where the page's back arrow and Escape go: the report page returns to
    /// the page it was opened from, while that page still has something to
    /// show; everything else returns home.
    pub fn back_target(&self) -> Page {
        match (self.page, self.report_return) {
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
            if page == Page::Report {
                self.report_return = self.page;
            }
            self.page = page;
            self.page_visit += 1;
            self.refresh_page_notices(cx);
        }
        self.sync_security_watch(cx);
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
        self.save_draft(cx);
        self.sync_security_watch(cx);
        cx.notify();
    }

    /// Revisits an earlier step (from the stepper or a "go to" button).
    pub fn set_step(&mut self, step: Step, cx: &mut Context<Self>) {
        if self.flow.go_to(step).is_ok() {
            self.option_screen = 0;
            self.returning_to_install = false;
            self.after_step_change(cx);
        }
    }

    /// Jumps back to one screen of the Options step (from "Change" links).
    /// From the Install step, Continue then leads straight back to it.
    pub fn edit_options(&mut self, screen: usize, cx: &mut Context<Self>) {
        let from_install = self.flow.step == Step::Install;
        if self.flow.go_to(Step::Options).is_ok() {
            self.option_screen = screen.min(self.option_screens().len().saturating_sub(1));
            self.returning_to_install = from_install;
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
            let screens = self.option_screens().len();
            if self.option_screen + 1 < screens {
                self.option_screen += 1;
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
        if self.flow.step == Step::Options
            && self.flow.may_edit()
            && self.flow.active
            && self.option_screen > 0
        {
            self.option_screen -= 1;
            self.after_step_change(cx);
            return;
        }
        if let Ok(step) = self.flow.back() {
            self.option_screen =
                if step == Step::Options { self.option_screens().len().saturating_sub(1) } else { 0 };
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
        playbook: Option<PathBuf>,
        cx: &mut Context<Self>,
    ) {
        if self.recovering {
            if let Some(page) = page.filter(|page| *page != Page::Install) {
                self.navigate(page, cx);
            }
            self.pending_start = Some(PendingStart { page, step, playbook, visit: self.page_visit });
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
        if let Some(path) = playbook {
            self.load_playbook_file(path, cx);
        }
    }

    /// Applies the start request that waited for recovery, into whatever
    /// flow recovery resumed or attached.
    pub(super) fn apply_pending_start(&mut self, cx: &mut Context<Self>) {
        if let Some(PendingStart { page, step, playbook, .. }) = self.pending_start.take() {
            self.apply_start(page, step, playbook, cx);
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
            self.take_over_draft(cx);
            self.after_step_change(cx);
            self.navigate(Page::Install, cx);
        }
    }

    /// Starts the install flow. Everything in it needs administrator rights,
    /// so the elevation prompt comes first; the draft lets the elevated copy
    /// resume here instead of starting over.
    pub fn begin_install(&mut self, cx: &mut Context<Self>) {
        if self.elevating {
            return;
        }
        self.refresh_atlas_state();
        if self.start_block().is_some() {
            cx.notify();
            return;
        }
        if self.iso_busy || self.preparation.busy() {
            return;
        }
        if self.recovering || self.flow.begin().is_err() {
            return;
        }
        self.checks.clear();
        self.check_tasks.clear();
        self.acknowledged.clear();
        self.preflight_problem = None;
        self.elevation_error = None;
        self.security_reminder = false;
        self.forget_pending_reminder(cx);
        self.returning_to_install = false;
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
                    let Err(error) = saved else { return true };
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
        // Protection was switched off for an install that is not happening
        // (or that stopped early); remind the user to put it back.
        self.security_reminder = !finished_ok && self.security.any_off();
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
        if self.playbook.is_none()
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
