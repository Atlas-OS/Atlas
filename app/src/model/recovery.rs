//! Startup recovery: what an earlier window left in the shared install
//! record and the draft, and following or closing out that install.

use std::time::Duration;

use gpui::Context;

use super::drafts::draft_launched;
use super::package::bundled_holds;
use super::{AppModel, Generation, Notice, Origin, Page, PlaybookSource, Step};
use crate::services::session::{self, Inspection, LaunchLock, SessionPaths, SessionRecord};
use crate::services::settings::{self, InstallDraft};
use crate::services::{installer, playbook, preparation, system};

/// How long startup waits for the install record before finishing recovery
/// in the background; a stuck lock holder must not delay the first frame.
const STARTUP_WAIT: Duration = Duration::from_millis(250);

/// How many times a reading asks for a busy launch lock before it calls the
/// record unreadable.
const LOCK_ATTEMPTS: u32 = 3;

/// What startup found in the shared install record, read on a worker so a
/// held launch lock never blocks the window.
#[derive(Debug)]
pub(super) enum StartupInspection {
    None,
    Unreadable(String),
    Live(SessionRecord),
    Ended(SessionRecord),
}

impl AppModel {
    /// Drops this window's view of its session and releases the shared
    /// record (see [`AppModel::release_record`]).
    pub(super) fn clear_session(&mut self, cx: &mut Context<Self>) {
        if let Some(record) = self.forget_session() {
            self.release_record(record.id, cx);
        }
    }

    /// Drops this window's view of its session without touching the shared
    /// record, and hands the record back for whoever finalises it.
    pub(super) fn forget_session(&mut self) -> Option<SessionRecord> {
        let record = self.session.take();
        self.own_session = None;
        self.restart_timer = None;
        self.attempt.reset();
        record
    }

    /// Removes the shared record if it still belongs to session `id`; a newer
    /// install started from another window keeps its record. The removal
    /// takes the launch lock, so it runs on a worker rather than the
    /// window's thread.
    fn release_record(&self, id: String, cx: &mut Context<Self>) {
        let paths = self.session_paths.clone();
        cx.background_executor()
            .spawn(async move {
                if let Err(error) = session::release(&paths, &id) {
                    log::warn!("could not release the install session: {error:#}");
                }
            })
            .detach();
    }

    /// Clears the draft that launched `record`, then releases the record,
    /// never the reverse, so disk never holds a launching draft without its
    /// record. If the draft write fails, the record stays for the next
    /// window or Done. `then` gets the draft that remains.
    pub(super) fn finalize_completed(
        &mut self,
        record: SessionRecord,
        then: impl FnOnce(&mut Self, Option<InstallDraft>, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        let id = record.id.clone();
        self.clear_draft_of(
            &record,
            move |this, remaining, cx| {
                this.release_record(id, cx);
                then(this, remaining, cx);
            },
            cx,
        );
    }

    pub(super) fn resume_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.settings.draft.clone() else { return };
        self.restore_preparation(&draft);
        let Some(step) = Step::parse(&draft.step) else {
            self.flow_id = draft.flow.clone();
            self.clear_draft(cx);
            self.flow_id = None;
            return;
        };
        // While the install record can't be read, the flow waits at Get
        // ready, which says why, before anyone switches protection off.
        let step = if self.record_problem.is_some() { Step::Ready } else { step };
        // An ownerless draft is adopted by this window.
        self.flow_id = Some(draft.flow.clone().unwrap_or_else(settings::new_flow_id));
        self.own_session = draft.session.clone();
        if let Some(dir) = draft.playbook_dir.filter(|dir| playbook::is_extracted(dir)) {
            if self.bundled() && !bundled_holds(&dir) {
                // A draft from another package (or an unverifiable one) is
                // not this tester build's to resume; the bundled package is
                // loaded in its place once the flow reaches Ready.
                log::info!("The draft's package {} is not the bundled package; ignoring it", dir.display());
            } else {
                match playbook::read_manifest(&dir) {
                    Ok(manifest) => {
                        // The file it came from, for ISO creation, while it's still there.
                        let archive = draft.package_archive.filter(|archive| archive.is_file());
                        self.playbook =
                            Some(PlaybookSource { dir, manifest, origin: Origin::Unpacked, archive });
                    }
                    Err(error) => log::warn!("could not resume the unpacked package: {error:#}"),
                }
            }
        }
        if !draft.options.is_empty() {
            self.options = draft.options.into_iter().collect();
        }
        self.option_screen = draft.option_screen;
        if self.flow.resume(step).is_ok() {
            self.enter_ready(cx);
            self.navigate(Page::Install, cx);
        }
    }

    /// Finds out whether an earlier instance of the app left an install
    /// running or finished. The shared record is read under the launch lock
    /// on a worker; the window waits a moment for the answer so the first
    /// frame is usually right, and otherwise finishes recovering in the
    /// background while offering nothing that could start a second install.
    pub(super) fn begin_recovery(&mut self, cx: &mut Context<Self>) {
        let paths = self.session_paths.clone();
        let settings = self.env.paths.settings();
        let task = cx
            .background_executor()
            .spawn(async move { (inspect_startup(&paths), preparation::recover_running(&settings)) });
        match cx.foreground_executor().block_with_timeout(STARTUP_WAIT, task) {
            Ok((found, running)) => self.finish_recovery(found, running, cx),
            Err(task) => {
                self.recovering = true;
                cx.spawn(async move |this, cx| {
                    let (found, running) = task.await;
                    this.update(cx, |this, cx| this.finish_recovery(found, running, cx)).ok();
                })
                .detach();
            }
        }
    }

    fn finish_recovery(
        &mut self,
        found: StartupInspection,
        running_preparation: anyhow::Result<Option<preparation::RunningJob>>,
        cx: &mut Context<Self>,
    ) {
        self.recovering = false;
        self.drop_left_start_page();
        if self.elevated {
            // Finished preparation jobs beyond the newest few are only
            // history; the protected folder can only be changed elevated.
            let settings = self.env.paths.settings();
            let keep =
                running_preparation.as_ref().ok().and_then(Option::as_ref).map(|job| job.directory.clone());
            cx.background_executor()
                .spawn(async move {
                    if let Err(error) = preparation::prune_jobs(&settings, keep.as_deref()) {
                        log::warn!("could not remove finished preparation jobs: {error:#}");
                    }
                })
                .detach();
        }
        match found {
            StartupInspection::None => {}
            StartupInspection::Unreadable(problem) => {
                // Ownership is unknown; the record stays and installs are
                // refused until it can be read. The user is told where it is.
                self.notice = Some(Notice::SessionUnreadable {
                    error: problem.clone(),
                    record: self.session_paths.record.clone(),
                });
                self.set_record_problem(Some(problem));
            }
            StartupInspection::Live(record) => {
                self.attach_session(record, false, cx);
                self.apply_pending_start(cx);
                return;
            }
            StartupInspection::Ended(record)
                if record.exit_code() == Some(0) && system::booted_since(&record.started_at) =>
            {
                // Succeeded and Windows has restarted since: the completion
                // window covers it, so close it out, then resume any other draft.
                self.refresh_atlas_state();
                self.finalize_completed(
                    record,
                    |this, remaining, cx| {
                        this.drop_left_start_page();
                        this.settings.draft = remaining;
                        if !this.flow.active {
                            this.resume_draft(cx);
                        }
                        this.apply_pending_start(cx);
                        cx.notify();
                    },
                    cx,
                );
                cx.notify();
                return;
            }
            StartupInspection::Ended(record) => {
                // Finished while no window was open: show the result (with
                // its log) until the user leaves it, and let the usual
                // completion handling arbitrate the draft.
                self.attach_session(record, true, cx);
                self.apply_pending_start(cx);
                return;
            }
        }
        if !self.flow.active {
            self.resume_draft(cx);
        }
        match running_preparation {
            Ok(Some(job)) => {
                // A running preparation is followed at Get ready, in the
                // resumed flow or in one of its own.
                self.flow.resume(Step::Ready).ok();
                self.flow_id.get_or_insert_with(settings::new_flow_id);
                self.navigate(Page::Install, cx);
                self.follow_preparation(job.directory.clone(), Some(job), cx);
            }
            Err(error) => log::warn!("could not inspect preparation recovery: {error:#}"),
            Ok(None) => {}
        }
        // The start request waited for the draft; a command-line step still
        // takes precedence over it.
        self.apply_pending_start(cx);
        // A flow left with protection off on an earlier run, and none resumed now.
        self.restore_pending_reminder(cx);
        // A flow that reached Ready while recovery was still running waited
        // for this answer before loading anything.
        if self.bundled() && self.flow.active && self.flow.step == Step::Ready && self.playbook.is_none() {
            self.load_bundled_package(cx);
        }
        cx.notify();
    }

    /// Follows a recorded install: its package, choices and output. `ended`
    /// says the process was already gone when the record was read.
    fn attach_session(&mut self, record: SessionRecord, ended: bool, cx: &mut Context<Self>) {
        if self.flow.attach_running().is_err() {
            return;
        }
        // A package still unpacking belongs to no install; the recorded one wins.
        self.cancel_acquisition();
        // The launching flow keeps its identity (and its finished
        // preparation), so a failed install can save edits and reserve its
        // retry. Any other flow gets an identity of its own: it never takes
        // over a newer draft, and its own draft is never taken for an
        // ownerless one.
        match self.settings.draft.clone().filter(|draft| draft_launched(draft, &record)) {
            Some(draft) => {
                self.flow_id = Some(draft.flow.clone().unwrap_or_else(settings::new_flow_id));
                self.own_session = Some(record.id.clone());
                if self.preparation == preparation::State::Idle {
                    self.restore_preparation(&draft);
                }
            }
            None => {
                self.flow_id.get_or_insert_with(settings::new_flow_id);
            }
        }
        if playbook::is_extracted(&record.request.playbook_dir)
            && let Ok(manifest) = playbook::read_manifest(&record.request.playbook_dir)
        {
            self.playbook = Some(PlaybookSource {
                dir: record.request.playbook_dir.clone(),
                manifest,
                origin: Origin::Unpacked,
                archive: None,
            });
        }
        self.options = record.request.options.iter().cloned().collect();
        let events = installer::reattach(&record);
        self.follow_session(record, events, cx);
        self.attempt.recovered = ended;
        self.navigate(Page::Install, cx);
    }

    /// Reads the shared install record again after it could not be read, on
    /// a worker and under the launch lock like the startup reading. A record
    /// that reads cleanly no longer holds the flow back; a live install is
    /// left for the launch to follow.
    pub(super) fn recheck_record(&mut self, cx: &mut Context<Self>) {
        if self.record_problem.is_none() {
            return;
        }
        let generation = self.record_generation.next();
        let paths = self.session_paths.clone();
        cx.spawn(async move |this, cx| {
            let found = cx.background_executor().spawn(async move { inspect_startup(&paths) }).await;
            this.update(cx, |this, cx| this.finish_record_check(generation, found, cx)).ok();
        })
        .detach();
    }

    /// Applies a reading from [`AppModel::recheck_record`], unless a launch
    /// or a newer reading has answered since.
    pub(super) fn finish_record_check(
        &mut self,
        generation: Generation,
        found: StartupInspection,
        cx: &mut Context<Self>,
    ) {
        if generation != self.record_generation || self.flow.locked() {
            return;
        }
        match found {
            StartupInspection::Unreadable(problem) => self.record_problem = Some(problem),
            StartupInspection::None | StartupInspection::Live(_) | StartupInspection::Ended(_) => {
                self.record_problem = None;
                if matches!(self.notice, Some(Notice::SessionUnreadable { .. })) {
                    self.notice = None;
                }
            }
        }
        cx.notify();
    }

    /// Records what the launch protocol last found in the shared record. A
    /// reading still under way elsewhere is older, so it no longer counts.
    pub(super) fn set_record_problem(&mut self, problem: Option<String>) {
        self.record_generation.next();
        self.record_problem = problem;
    }
}

/// Reads the shared install record under the launch lock. A record that a
/// launch abandoned before committing is removed here; everything else is
/// handed to the model to reconcile with its draft.
fn inspect_startup(paths: &SessionPaths) -> StartupInspection {
    // Under the launch lock, a launch elsewhere has either committed its
    // process or is not there at all. The lock is held for moments, so a
    // busy one is asked for again before the record is called unreadable.
    let mut attempts = 0;
    let lock = loop {
        attempts += 1;
        match LaunchLock::acquire(paths) {
            Ok(lock) => break lock,
            Err(error) if error.is::<session::Busy>() && attempts < LOCK_ATTEMPTS => {}
            Err(error) => {
                log::warn!("could not inspect the install session: {error:#}");
                return StartupInspection::Unreadable(format!("{error:#}"));
            }
        }
    };
    match lock.inspect(paths) {
        Inspection::None => StartupInspection::None,
        Inspection::Abandoned => {
            lock.discard(paths);
            StartupInspection::None
        }
        Inspection::Unreadable(problem) => StartupInspection::Unreadable(problem),
        Inspection::Live(record) => StartupInspection::Live(record),
        Inspection::Ended(record) => StartupInspection::Ended(record),
    }
}
