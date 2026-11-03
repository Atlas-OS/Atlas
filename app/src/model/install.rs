//! Starting the install and following it: the final checks, the launch, the
//! installer's output and its result.

use std::path::Path;
use std::time::Duration;

use futures::StreamExt;
use futures::channel::mpsc::Receiver;
use gpui::{ClipboardItem, Context, SharedString};

use super::checks::preflight_decision;
use super::drafts::DraftWrite;
use super::package::bundled_holds;
use super::{AppModel, CloseGuard, RestartCountdown, RestartProblem, RunState, preview};
use crate::i18n::describe;
use crate::services::installer::{self, InstallEvent, InstallOutcome, InstallRequest, Phase};
use crate::services::iso;
use crate::services::preparation::State as PreparationState;
use crate::services::requirements::{CheckDetail, CheckId, CheckResult};
use crate::services::security::{SecurityStatus, SwitchCounts};
use crate::services::session::{self, SessionRecord};
use crate::t;

/// Lines kept in memory; the full log is on disk.
const LOG_KEEP: usize = 2000;
/// Bytes of log kept in memory, whatever the line count.
const LOG_KEEP_BYTES: usize = 1024 * 1024;
/// How often the installing view is redrawn while the install runs, so its
/// "started N minutes ago" stays current. Output redraws it as it arrives.
const ELAPSED_REDRAW: Duration = Duration::from_secs(15);

/// Why the final checks refused to start the install.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Preflight {
    InvalidOptions {
        error: String,
    },
    /// Checks or Windows Security changed since the user last saw them.
    Changed {
        checks: Vec<(CheckId, CheckDetail)>,
        security: Option<SwitchCounts>,
    },
    /// Another window holds the launch lock.
    Busy,
    /// Another window began a flow of its own and now owns the draft, so
    /// this one may not record an install in it.
    TakenOver,
    /// The shared install record cannot be read, so nothing may start.
    RecordUnreadable {
        error: String,
    },
    /// The launch protocol refused; nothing ran.
    Refused {
        error: String,
    },
}

/// State of one install attempt, reset as a whole so nothing from an earlier
/// attempt shows under a later result. Only the error it stopped on, which is
/// never shown, carries over (see `earlier_error`).
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct InstallAttempt {
    /// The tail of the install log; the whole log is in the session's `log_path`.
    pub log: Vec<SharedString>,
    pub log_total: usize,
    /// Bytes held in `log`.
    log_bytes: usize,
    pub phase: Phase,
    pub plan_progress: Option<installer::PlanProgress>,
    /// The raw error from reading the install log, if reading failed.
    pub output_problem: Option<String>,
    /// The result was found after reopening the app: the install had already
    /// ended, so whether Windows is about to restart is unknown and no
    /// countdown is shown for it.
    pub recovered: bool,
    /// The countdown to the restart Atlas asks Windows for after a success.
    pub restart: Option<RestartCountdown>,
    /// Windows has been asked to restart (the countdown ended, or the user
    /// chose "Restart now"); nothing here can take that back.
    pub restart_requested: bool,
    /// The user stopped the automatic restart.
    pub restart_cancelled: bool,
    /// A restart command that did not take.
    pub restart_problem: Option<RestartProblem>,
    /// Counts the restarts that didn't happen, refused or not acted on, so
    /// the view can announce each one, even one like the last.
    pub restart_epoch: u64,
    /// The error the attempt before this one stopped on, when this one
    /// retries an install already part-way through. It tells a failure that
    /// repeats from a new one, so it outlives a refused start, leaving the
    /// result for another step and leaving the flow; not a restart of the app.
    pub earlier_error: Option<String>,
}

impl InstallAttempt {
    /// Starts a new attempt, holding on to the error this one stopped on, or
    /// to the one it held if it never ran, such as a start the final checks
    /// refused.
    pub fn reset(&mut self) {
        let earlier =
            if self.log_total > 0 { self.last_error().map(str::to_owned) } else { self.earlier_error.take() };
        *self = Self { earlier_error: earlier, ..Self::default() };
    }

    /// Appends output to the tail kept in memory, reads the phase from it,
    /// and trims the tail to [`LOG_KEEP`] lines and [`LOG_KEEP_BYTES`]
    /// bytes. The decoder has already capped each line.
    pub fn push_lines(&mut self, lines: Vec<String>) {
        for line in &lines {
            if let Some(progress) = installer::PlanProgress::from_line(line) {
                // Replayed/duplicated log batches must not move the bar backwards.
                if self.plan_progress.is_none_or(|old| progress.fraction() >= old.fraction()) {
                    self.plan_progress = Some(progress);
                }
            }
            if let Some(phase) = Phase::from_line(line) {
                self.phase = self.phase.max(phase);
            }
        }
        self.log_total += lines.len();
        for line in lines {
            self.log_bytes += line.len();
            self.log.push(SharedString::from(line));
        }
        let mut drop = 0;
        let mut bytes = self.log_bytes;
        let mut count = self.log.len();
        while drop < self.log.len() && (count > LOG_KEEP || bytes > LOG_KEEP_BYTES) {
            bytes -= self.log[drop].len();
            count -= 1;
            drop += 1;
        }
        if drop > 0 {
            self.log.drain(..drop);
            self.log_bytes = bytes;
        }
    }

    /// The last error the installer logged, as it wrote it after its
    /// `[ERROR]` tag but without the script position it may add, for a
    /// failure message's details. Only the lines still held in memory are
    /// searched.
    pub fn last_error(&self) -> Option<&str> {
        self.log.iter().rev().find_map(|line| {
            let (_, error) = line.split_once(ERROR_TAG)?;
            let error = without_position(error.trim());
            (!error.is_empty()).then_some(error)
        })
    }

    /// This attempt stopped on the error the attempt before it stopped on,
    /// so trying the same again is unlikely to get any further.
    pub fn repeated(&self) -> bool {
        self.earlier_error.as_deref().is_some_and(|earlier| self.last_error() == Some(earlier))
    }

    /// The apps Windows wouldn't remove in this attempt, each once, named as
    /// the installer names them: a package family, without its wildcard.
    pub fn unremoved_apps(&self) -> Vec<String> {
        let mut apps: Vec<String> = Vec::new();
        for line in &self.log {
            let name = line
                .split_once(ERROR_TAG)
                .and_then(|(_, error)| error.trim_start().strip_prefix(APP_NOT_REMOVED))
                .and_then(|rest| rest.split_once('\''))
                .map(|(name, _)| name.trim_end_matches('*'));
            if let Some(name) = name.filter(|name| !name.is_empty())
                && !apps.iter().any(|app| app == name)
            {
                apps.push(name.to_owned());
            }
        }
        apps
    }
}

/// How the installer marks an error line in its log.
const ERROR_TAG: &str = "[ERROR]";
/// How the installer's error line for an app Windows wouldn't remove starts,
/// before the app's quoted name.
const APP_NOT_REMOVED: &str = "AppX removal failed for '";
/// What Atlas's log puts between an error and the script position it came
/// from. Errors that collect several failures join them with it too.
const POSITION_SEPARATOR: &str = " | ";
/// What starts each line of code a script position quotes, once the log has
/// put the position on one line.
const QUOTED_CODE: &str = " + ";

/// `error` without the script position Atlas's log appends to an error it
/// caught (" | At C:\...\Phase.ps1:86 char:5 + throw ... + ~~~"), which is
/// for the log, not the user. The position is told from a joined failure by
/// its shape: a first line that ends with the script line and column however
/// Windows PowerShell words it in the PC's language, then the code it quotes
/// after " + ". An error PowerShell knows no position for leaves only the
/// separator, which goes too.
fn without_position(error: &str) -> &str {
    if let Some(error) = error.strip_suffix(POSITION_SEPARATOR.trim_end()) {
        return error.trim_end();
    }
    let position = error.match_indices(POSITION_SEPARATOR).map(|(at, _)| at).find(|&at| {
        let rest = &error[at + POSITION_SEPARATOR.len()..];
        rest.split_once(QUOTED_CODE).is_some_and(|(first_line, _)| {
            !first_line.contains(POSITION_SEPARATOR)
                && first_line.ends_with(|c: char| c.is_ascii_digit())
                && first_line.split(':').skip(1).any(|part| part.starts_with(|c: char| c.is_ascii_digit()))
        })
    });
    position.map_or(error, |at| error[..at].trim_end())
}

impl AppModel {
    /// What closing the window now would interrupt.
    pub fn close_guard(&self) -> CloseGuard {
        match self.preparation {
            PreparationState::Running { .. } | PreparationState::WaitingExternal => {
                return CloseGuard::Preparation;
            }
            PreparationState::SavingRestart => return CloseGuard::Wait,
            // Windows has the restart and recovery is armed, so closing is safe.
            PreparationState::Restarting => return CloseGuard::None,
            _ => {}
        }
        if self.iso_busy {
            return CloseGuard::Media;
        }
        match self.flow.run {
            RunState::Preparing if !self.launching => CloseGuard::PreparingInstall,
            RunState::Preparing | RunState::Running => CloseGuard::Install,
            _ if self.restart_cancellable() => CloseGuard::Restart,
            _ if self.update_access_close_guard() => CloseGuard::WindowsUpdateAccess,
            _ if self.protection_left_off().is_some() => CloseGuard::ProtectionOff,
            _ => CloseGuard::None,
        }
    }

    /// The switches a setup under way has read off, if closing now would
    /// leave them so: a flow that hasn't finished, outside desktop setup,
    /// with Defender present and at least one switch that actually reads
    /// off. Unreadable switches aren't known to be off, so they don't count.
    pub fn protection_left_off(&self) -> Option<super::ProtectionReminder> {
        if !self.flow.active || self.flow.locked() || self.flow.run.succeeded() || self.before_desktop {
            return None;
        }
        super::ProtectionReminder::from_reading(super::ReminderReason::LeftFlow, &self.security)
            .filter(|reminder| !reminder.unreadable && !reminder.missing)
    }

    /// A failed install leaves no protection to turn back on: Defender is
    /// gone, or Atlas's package that removes it is installed and no switch
    /// reads off. Defender can come back through its own updates while Atlas
    /// 0.5's package stays installed, so the package alone isn't enough.
    pub fn defender_removed(&self) -> bool {
        !self.security.defender_present || (self.defender_package_installed() && !self.security.any_off())
    }

    /// Atlas's NoDefender servicing package is installed, as the PC read
    /// again whenever an attempt ends shows it: only once Windows has
    /// installed it.
    pub fn defender_package_installed(&self) -> bool {
        self.pc_facts.defender_package_installed()
    }

    /// What the result on screen bases its advice on, besides its outcome.
    pub fn attempt_facts(&self) -> describe::AttemptFacts {
        describe::AttemptFacts {
            phase: self.attempt.phase,
            // A retry of an install an earlier attempt began applying.
            resumed: self.original_options().is_some(),
            repeated: self.attempt.repeated(),
            defender_removed: self.defender_removed(),
            unremoved_apps: self.attempt.unremoved_apps(),
        }
    }

    /// The failed result offers Open Windows Security: the installer may
    /// have changed things once protection was off, and Defender is still
    /// there for the user to turn it back on.
    pub fn result_offers_windows_security(&self) -> bool {
        let RunState::Finished(outcome) = self.flow.run else { return false };
        !outcome.is_success()
            && !self.defender_removed()
            && (self.attempt.phase >= Phase::Applying
                || self.original_options().is_some()
                || outcome == InstallOutcome::Lost)
    }

    /// The launch is on its worker and has not answered. Closing now would
    /// end the worker mid-launch, so closing waits for the answer.
    pub fn launching(&self) -> bool {
        self.launching
    }

    /// Stops the final checks before anything has launched, so a window
    /// closed then leaves no install starting unwatched. Returns whether it
    /// did; once the launch is under way it is too late.
    pub fn abandon_preparing(&mut self, cx: &mut Context<Self>) -> bool {
        if self.flow.run != RunState::Preparing || self.launching {
            return false;
        }
        self.flow.stop_preparing().ok();
        self.sync_security_watch(cx);
        cx.notify();
        true
    }

    /// The window shows the dedicated installing view: while an install is
    /// preparing or running, and after it succeeded until the user leaves.
    pub fn install_in_progress(&self) -> bool {
        self.flow.active && (self.flow.locked() || self.flow.run.succeeded())
    }

    /// Whether the Install step describes the recorded install (running, or
    /// succeeded) rather than what the current choices would run.
    pub fn showing_recorded_install(&self) -> bool {
        self.session.is_some() && (self.flow.locked() || self.flow.run.succeeded())
    }

    /// The request the recorded install ran with, or the one the current
    /// choices would produce.
    pub fn install_request(&self) -> Option<InstallRequest> {
        if let Some(session) = &self.session
            && self.showing_recorded_install()
        {
            return Some(session.request.clone());
        }
        let source = self.playbook.as_ref()?;
        Some(InstallRequest {
            playbook_dir: source.dir.clone(),
            options: self.effective_options(),
            restart: self.settings.restart_after_install,
            windows_security_confirmed: self.security_confirmed_by_hand(),
            choose_again: self.choosing_again(),
        })
    }

    /// Starts the install: the mandatory checks and the Windows Security
    /// switches are read again first, and the child only starts if they still
    /// pass. The request is captured now; only whether Windows Security passed
    /// on the user's confirmation is taken from the final reading.
    ///
    /// The decision is made on the window's thread from the fresh readings;
    /// the launch itself (which takes the cross-process lock and spawns the
    /// child) runs on a worker while the flow stays locked in `Preparing`.
    pub fn start_install(&mut self, cx: &mut Context<Self>) {
        // A review fixture's package is a stand-in: nothing is installed from it.
        if preview::active() {
            log::info!("Installation not started: a preparation preview is showing");
            return;
        }
        self.refresh_atlas_state();
        if self.bundled() && !self.playbook.as_ref().is_some_and(|book| bundled_holds(&book.dir)) {
            // A recovered session can describe another package. It can be
            // looked at, not run: only the bundled package installs.
            log::warn!("The loaded package is not the bundled one; loading the bundled package instead");
            self.playbook = None;
            self.load_bundled_package(cx);
            cx.notify();
            return;
        }
        if !self.can_install() {
            cx.notify();
            return;
        }
        let Some(mut request) = self.install_request() else { return };
        // The installer refuses choices the package's pages don't accept, but
        // only once protection is off. An unfinished install may leave a
        // required page added since it began unchosen, as the installer allows.
        let choices = if self.resume_target().is_some() {
            iso::validate_resumed_options(self.manifest(), &request.options)
        } else {
            iso::validate_options(self.manifest(), &request.options)
        };
        if let Err(error) = installer::validate_options(&request.options).and(choices) {
            // The error names neither the page nor the option; the choices do.
            log::warn!("The package refuses these choices: {:?}", request.options);
            self.refuse_install(Preflight::InvalidOptions { error: format!("{error:#}") }, cx);
            return;
        }
        let resumed = self.original_options().is_some();
        if self.flow.start_preparing().is_err() {
            return;
        }
        self.preflight_problem = None;
        self.clear_session(cx);
        // Only a retry of an install already part-way through is told it
        // repeats: one that stopped before changing anything already says to
        // send a report if it stops again.
        if !resumed {
            self.attempt.earlier_error = None;
        }
        self.sync_security_watch(cx);
        cx.notify();

        let context = self.check_context();
        let run = self.env.adapters.run_check.clone();
        let read_security = self.env.adapters.read_security.clone();
        let is_elevated = self.env.adapters.is_elevated.clone();
        let paths = self.session_paths.clone();
        let arm_completion = self.env.adapters.arm_completion.clone();
        cx.spawn(async move |this, cx| {
            let readings = cx
                .background_executor()
                .spawn(async move {
                    let results: Vec<CheckResult> =
                        CheckId::ALL.iter().filter(|id| id.blocking()).map(|id| run(*id, &context)).collect();
                    (results, read_security(), is_elevated())
                })
                .await;
            // The front door hears whether the final reading, not the one at
            // the click, passed on the user's confirmation.
            let Some(confirmed) = this
                .update(cx, |this, cx| {
                    this.apply_preflight(readings, cx).then(|| this.security_confirmed_by_hand())
                })
                .ok()
                .flatten()
            else {
                return;
            };
            request.windows_security_confirmed = confirmed;
            // The draft names the install it is about to launch before the
            // child can run, so a window that closes (or crashes) during the
            // handoff leaves a record on disk and a draft that agree.
            let id = session::new_id();
            let Some(reservation) = this
                .update(cx, |this, _| {
                    this.own_session = Some(id.clone());
                    this.current_draft().map(|draft| this.write_owned_draft(draft))
                })
                .ok()
                .flatten()
            else {
                return;
            };
            let reserved = reservation.await;
            if !this.update(cx, |this, cx| this.after_reservation(reserved, cx)).unwrap_or(false) {
                return;
            }
            let (launch, armed) = cx
                .background_executor()
                .spawn(async move {
                    let launch = installer::start_as(id, request, &paths);
                    // Only an install that really started owes a completion
                    // window. It is armed before the window hears of the
                    // launch, so a failure reported at once finds the entry
                    // there to remove.
                    let armed = launch.is_ok().then(|| arm_completion(&paths));
                    (launch, armed)
                })
                .await;
            let started = launch.as_ref().ok().map(|(record, _)| record.id.clone());
            if this.update(cx, |this, cx| this.finish_launch(launch, armed, cx)).is_err()
                && let Some(id) = started
            {
                // The window closed before the launch answered. The child
                // runs under its record, with its completion window armed
                // unless that failed; the next window finds it.
                log::warn!(
                    "the window closed while install {id} was starting; it continues under its record"
                );
            }
        })
        .detach();
    }

    /// Applies the final readings and says whether the launch may go on. A
    /// refusal is shown on the Install step.
    fn apply_preflight(
        &mut self,
        (results, security, elevated): (Vec<CheckResult>, SecurityStatus, bool),
        cx: &mut Context<Self>,
    ) -> bool {
        if self.flow.run != RunState::Preparing {
            return false;
        }
        self.observe_security(security);
        self.elevated = self.elevated && elevated;
        for result in &results {
            if let Some(slot) = self.checks.iter_mut().find(|(id, _)| *id == result.id) {
                slot.1 = Some(result.clone());
            }
        }
        let decision = preflight_decision(
            &results,
            &self.acknowledged,
            &self.security,
            self.security_confirmation,
            self.elevated,
        );
        match decision {
            Ok(()) => true,
            Err(problem) => {
                self.refuse_install(problem, cx);
                false
            }
        }
    }

    /// Takes the answer of the draft write that names the install, and says
    /// whether the launch goes ahead. From then on the installer may start,
    /// and the window can no longer call it off.
    fn after_reservation(&mut self, reserved: DraftWrite, cx: &mut Context<Self>) -> bool {
        let problem = match reserved {
            DraftWrite::Written if self.flow.run == RunState::Preparing => {
                self.launching = true;
                return true;
            }
            // The final checks were abandoned meanwhile.
            DraftWrite::Written => {
                self.own_session = None;
                return false;
            }
            DraftWrite::TakenOver => Preflight::TakenOver,
            DraftWrite::Failed(error) => Preflight::Refused {
                error: format!("the install could not be recorded in the draft: {error}"),
            },
        };
        self.own_session = None;
        self.refuse_install(problem, cx);
        false
    }

    /// Records why the final checks did not start the install and returns
    /// the flow to the idle Install step. Every refusal counts, so one like
    /// the last is announced again.
    fn refuse_install(&mut self, problem: Preflight, cx: &mut Context<Self>) {
        log::warn!("Installation not started: {problem:?}");
        self.flow.stop_preparing().ok();
        self.preflight_problem = Some(problem);
        self.preflight_epoch += 1;
        self.sync_security_watch(cx);
        cx.notify();
    }

    fn finish_launch(
        &mut self,
        launch: anyhow::Result<(SessionRecord, Receiver<InstallEvent>)>,
        armed: Option<anyhow::Result<()>>,
        cx: &mut Context<Self>,
    ) {
        self.launching = false;
        if let Some(Err(error)) = armed {
            log::warn!("could not arrange the completion window after the restart: {error:#}");
        }
        if self.flow.run != RunState::Preparing {
            return;
        }
        match launch {
            Ok((record, events)) => {
                self.set_record_problem(None);
                self.flow.start_running().ok();
                self.follow_session(record, events, cx);
            }
            Err(error) => match error.downcast::<installer::AlreadyRunning>() {
                // Another instance's install is running (the launch lock saw
                // it first); follow that one instead. The id this window
                // reserved launched nothing.
                Ok(installer::AlreadyRunning(existing)) => {
                    self.set_record_problem(None);
                    self.own_session = None;
                    self.save_draft(cx);
                    self.flow.start_running().ok();
                    let events = installer::reattach(&existing, &self.session_paths.machine_log);
                    self.follow_session(existing, events, cx);
                }
                // The protocol guarantees nothing ran: back to idle with the
                // reason, not a fake "aborted" result.
                Err(error) => {
                    self.own_session = None;
                    self.save_draft(cx);
                    let problem = if error.downcast_ref::<session::Busy>().is_some() {
                        Preflight::Busy
                    } else if let Some(unreadable) = error.downcast_ref::<installer::RecordUnreadable>() {
                        // Get ready explains it and holds the flow until it reads cleanly.
                        self.set_record_problem(Some(unreadable.0.clone()));
                        Preflight::RecordUnreadable { error: unreadable.0.clone() }
                    } else {
                        Preflight::Refused { error: format!("{error:#}") }
                    };
                    self.refuse_install(problem, cx);
                }
            },
        }
        cx.notify();
    }

    /// Follows the install `record` describes, as a new attempt fed by `events`.
    pub(super) fn follow_session(
        &mut self,
        record: SessionRecord,
        events: Receiver<InstallEvent>,
        cx: &mut Context<Self>,
    ) {
        self.restart_timer = None;
        self.attempt.reset();
        self.session = Some(record);
        self.pump_install_events(events, cx);
    }

    fn pump_install_events(&mut self, mut events: Receiver<InstallEvent>, cx: &mut Context<Self>) {
        cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(ELAPSED_REDRAW).await;
                let running = this
                    .update(cx, |this, cx| {
                        cx.notify();
                        matches!(this.flow.run, RunState::Running)
                    })
                    .unwrap_or(false);
                if !running {
                    break;
                }
            }
        })
        .detach();
        cx.spawn(async move |this, cx| {
            while let Some(event) = events.next().await {
                let alive = this
                    .update(cx, |this, cx| {
                        match event {
                            InstallEvent::Lines(lines) => this.attempt.push_lines(lines),
                            InstallEvent::OutputProblem(problem) => {
                                this.attempt.output_problem = Some(problem)
                            }
                            InstallEvent::Finished(outcome) => this.finish_install(outcome, cx),
                        }
                        cx.notify();
                    })
                    .is_ok();
                if !alive {
                    break;
                }
            }
        })
        .detach();
    }

    /// The child ended. A success ends the flow and, if this window watched
    /// it end and no window chose "Restart later", starts the countdown. A
    /// failure keeps the result, the log and a ready retry on the Install
    /// step, running the checks if this window never did (an install found
    /// after reopening the app).
    fn finish_install(&mut self, outcome: InstallOutcome, cx: &mut Context<Self>) {
        log::info!("Installation outcome: {outcome:?}");
        if self.flow.finish(outcome).is_err() {
            return;
        }
        self.refresh_atlas_state();
        if outcome.is_success() {
            if let Some(record) = self.session.clone() {
                self.clear_draft_of(&record, |_, _, _| {}, cx);
            }
            // The install turned protection back on, or says to: no reminder
            // from an earlier flow is owed now.
            self.forget_pending_reminder(cx);
            let restart = self.session.as_ref().is_some_and(|s| s.request.restart);
            if restart && !self.attempt.recovered {
                if self.restart_declined() {
                    self.attempt.restart_cancelled = true;
                } else {
                    self.begin_restart_countdown(cx);
                }
            }
        } else {
            disarm_completion();
            if outcome.needs_preparation() {
                // Windows or the Store has more to do than this flow's
                // preparation saw; Get ready offers it again, also after a
                // relaunch.
                self.preparation = PreparationState::Idle;
                self.save_draft(cx);
            }
            if self.checks.is_empty() {
                self.run_checks(cx);
            }
        }
        self.sync_security_watch(cx);
    }

    /// Copies the in-memory log tail, with a note naming the full log file.
    pub fn copy_log(&self, cx: &mut Context<Self>) {
        let mut text = self.attempt.log.iter().map(|line| line.as_ref()).collect::<Vec<_>>().join("\r\n");
        if let Some(session) = &self.session {
            text.push_str("\r\n");
            text.push_str(&t!("log-full-log-note", path = session.log_path.display().to_string()));
        }
        cx.write_to_clipboard(ClipboardItem::new_string(text));
    }

    pub fn reveal_log(&self, cx: &mut Context<Self>) {
        if let Some(session) = &self.session {
            let machine = &self.session_paths.machine_log;
            cx.reveal_path(log_to_reveal(self.attempt.phase, &session.log_path, machine, machine.exists()));
        }
    }
}

/// Removes the Run entry that reopens the app after the restart: an attempt
/// that did not succeed owes no completion window, at this or any later
/// sign-in.
pub(super) fn disarm_completion() {
    if let Err(error) = session::unregister_completion() {
        log::warn!("could not remove the completion Run entry: {error:#}");
    }
}

/// The log "Open log file" shows: the machine log once this attempt has
/// reached Applying (before that it may hold an earlier install's lines),
/// otherwise the session log.
fn log_to_reveal<'a>(
    phase: Phase,
    session_log: &'a Path,
    machine_log: &'a Path,
    machine_exists: bool,
) -> &'a Path {
    if phase >= Phase::Applying && machine_exists { machine_log } else { session_log }
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::{InstallAttempt, LOG_KEEP, LOG_KEEP_BYTES, log_to_reveal, without_position};
    use crate::services::installer::Phase;

    #[test]
    fn open_log_file_shows_the_machine_log_only_once_the_install_plan_runs() {
        let session = Path::new(r"C:\App\Logs\install-1.log");
        let machine = Path::new(r"C:\Windows\AtlasModules\Logs\install\atlas-install.log");
        for phase in [Phase::Preflight, Phase::Staging] {
            assert_eq!(log_to_reveal(phase, session, machine, true), session, "{phase:?}");
        }
        for phase in [Phase::Applying, Phase::Done] {
            assert_eq!(log_to_reveal(phase, session, machine, true), machine, "{phase:?}");
            assert_eq!(log_to_reveal(phase, session, machine, false), session, "{phase:?}");
        }
    }

    #[test]
    fn the_log_tail_is_limited_by_lines_and_by_bytes() {
        let mut attempt = InstallAttempt::default();
        attempt.push_lines((0..3000).map(|i| format!("line {i}")).collect());
        assert_eq!(attempt.log.len(), LOG_KEEP);
        assert_eq!(attempt.log_total, 3000);
        assert_eq!(attempt.log.first().map(|l| l.as_ref()), Some("line 1000"));
        attempt.push_lines((0..400).map(|_| "x".repeat(8 * 1024)).collect());
        assert!(attempt.log_bytes <= LOG_KEEP_BYTES, "{} bytes", attempt.log_bytes);
        assert!(attempt.log.len() < 400, "{} lines", attempt.log.len());
        assert_eq!(attempt.log_total, 3400);
    }

    #[test]
    fn a_failure_names_the_last_error_the_installer_logged() {
        let mut attempt = InstallAttempt::default();
        attempt.push_lines(vec!["[Atlas] Running the install plan as TrustedInstaller.".into()]);
        assert_eq!(attempt.last_error(), None, "no error logged");
        attempt.push_lines(vec![
            "[2026-09-30 20:11:40] [-] [ERROR] Remove-Edge.ps1 failed: the file is in use.".into(),
            "[2026-09-30 20:11:40] [-] [ERROR] Atlas install stopped at step 18 of 40 (Browser).".into(),
            "[2026-09-30 20:11:41] [-] [INFO] Writing the state document".into(),
            "[2026-09-30 20:11:41] [-] [ERROR]   ".into(),
        ]);
        // The last tag with words after it, without its timestamp and tag.
        assert_eq!(attempt.last_error(), Some("Atlas install stopped at step 18 of 40 (Browser)."));
        attempt.reset();
        assert_eq!(attempt.last_error(), None);
    }

    /// The failure as the installer logged it after a phase threw, the
    /// position Atlas's log appends included.
    const APPX_FAILURE: &str = concat!(
        "[2026-10-28T16:26:05.2903365Z] [2026-10-28 17:26:05] [-] [ERROR] The AppX removal plan failed after ",
        "cleanup: AppX removal completed with 1 required failure(s): MSTeams*: 1 installed package(s) remain ",
        "registered. | At C:\\Windows\\AtlasModules\\Scripts\\Install\\Phases\\Invoke-AppxSupportPhase.ps1:86 ",
        "char:5 +     throw \"The AppX removal plan failed after cleanup: $($requiredFai ... +     ~~~~~~~~~~~~"
    );
    const APPX_ERROR: &str = "The AppX removal plan failed after cleanup: AppX removal completed with 1 required failure(s): MSTeams*: 1 installed package(s) remain registered.";

    /// The details show what failed, not where in which script: the
    /// position Atlas's log appends is dropped, in any language Windows
    /// PowerShell words it in, while failures an error joins with the same
    /// separator stay.
    #[test]
    fn the_details_leave_out_the_script_position_the_log_appends() {
        // The engine still appends the position this way.
        let logging = include_str!(
            "../../../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.Core/Domain/Logging.ps1"
        );
        assert!(logging.contains(
            r#"$line += " | $($ErrorRecord.InvocationInfo.PositionMessage -replace '\r?\n', ' ')""#
        ));
        let mut attempt = InstallAttempt::default();
        attempt.push_lines(vec![APPX_FAILURE.into()]);
        assert_eq!(attempt.last_error(), Some(APPX_ERROR));
        for (error, shown) in [
            (APPX_ERROR, APPX_ERROR),
            // Failures joined by the error itself, and a quoted line holding a pipeline.
            (
                "Plan failed: MSTeams*: 1 remain. | Clearing AppX caches failed: code 5 | At C:\\A\\Phase.ps1:86 char:5 +     Get-X | Out-Null +     ~~~~",
                "Plan failed: MSTeams*: 1 remain. | Clearing AppX caches failed: code 5",
            ),
            ("Step failed | In C:\\A\\Phase.ps1:86 Zeichen:5 +     throw $x +     ~~~~~~~~", "Step failed"),
            (
                "Step failed | Au caractère C:\\A\\Phase.ps1:86 : 5 +     throw $x +     ~~~~~~~~",
                "Step failed",
            ),
            ("Step failed | At line:1 char:1 + throw 'x' + ~~~~~~~~~", "Step failed"),
            // An error PowerShell knows no position for.
            ("Step failed |", "Step failed"),
            // Nothing that reads as a position is taken for one.
            ("Copy failed | 2 files left", "Copy failed | 2 files left"),
            ("Copy failed | code: 0x80070005", "Copy failed | code: 0x80070005"),
            ("Copy failed | timed out after 00:05:00", "Copy failed | timed out after 00:05:00"),
            ("Copy failed | D:1", "Copy failed | D:1"),
            ("Copy failed | code: 5 + 1 retry", "Copy failed | code: 5 + 1 retry"),
        ] {
            assert_eq!(without_position(error), shown, "{error}");
        }
    }

    #[test]
    fn the_apps_windows_would_not_remove_are_named_once_without_their_wildcard() {
        // The engine still words the failure this way.
        let removal = include_str!(
            "../../../playbook/Executables/AtlasModules/Scripts/Modules/Atlas.Appx/Domain/Removal.ps1"
        );
        assert!(removal.contains(r#"Write-AtlasLog -Level Error -Message "AppX removal failed for '$($Definition.Name)': $Message""#));
        let mut attempt = InstallAttempt::default();
        assert!(attempt.unremoved_apps().is_empty());
        attempt.push_lines(vec![
            "[2026-10-28 17:26:02] [-] [WARNING] Ignoring AppX removal failure for 'Microsoft.Edge.GameAssist*': 1 installed package(s) remain registered.".into(),
            // The front door's copy of the plan's output, then the machine log's.
            "[2026-10-28T16:26:02.6762625Z] [2026-10-28 17:26:02] [-] [ERROR] AppX removal failed for 'MSTeams*': 1 installed package(s) remain registered.".into(),
            "[2026-10-28 17:26:02] [-] [ERROR] AppX removal failed for 'MSTeams*': 1 installed package(s) remain registered.".into(),
            "[2026-10-28 17:26:03] [-] [ERROR] AppX removal failed for 'Ink.Handwriting.Main.Store.en-US1.0': 1 provisioned package(s) remain.".into(),
            APPX_FAILURE.into(),
        ]);
        assert_eq!(attempt.unremoved_apps(), ["MSTeams", "Ink.Handwriting.Main.Store.en-US1.0"]);
    }

    /// A repeat is the same error as the attempt before, after its position
    /// is dropped; another error, or none, is not.
    #[test]
    fn only_the_same_error_again_is_a_repeat() {
        let attempt = |earlier: Option<&str>, line: &str| {
            let mut attempt =
                InstallAttempt { earlier_error: earlier.map(str::to_owned), ..Default::default() };
            attempt.push_lines(vec![line.to_owned()]);
            attempt
        };
        assert!(attempt(Some(APPX_ERROR), APPX_FAILURE).repeated());
        assert!(!attempt(None, APPX_FAILURE).repeated(), "no attempt before it");
        let other = "[2026-10-28 17:26:05] [-] [ERROR] Removing Microsoft Edge failed: the file is in use.";
        assert!(!attempt(Some(APPX_ERROR), other).repeated(), "a new error");
        assert!(!attempt(Some(APPX_ERROR), "[Atlas] Running the install plan").repeated(), "no error");
    }

    /// A new attempt keeps nothing of the one before but the error it
    /// stopped on: what the next one is compared with. One that never ran
    /// passes on the error it held, and one that ran without an error leaves
    /// nothing to compare with.
    #[test]
    fn a_new_attempt_keeps_only_the_error_the_one_before_stopped_on() {
        let mut attempt = InstallAttempt::default();
        attempt.push_lines(vec!["[Atlas] Running the install plan".into(), APPX_FAILURE.into()]);
        attempt.reset();
        assert_eq!(attempt.earlier_error.as_deref(), Some(APPX_ERROR));
        assert_eq!(attempt.last_error(), None);
        assert!(!attempt.repeated(), "nothing has stopped yet");
        assert!(attempt.log.is_empty() && attempt.phase == Phase::Preflight);
        attempt.reset();
        assert_eq!(attempt.earlier_error.as_deref(), Some(APPX_ERROR), "a start refused before it ran");
        attempt.push_lines(vec!["[Atlas] Running the install plan".into()]);
        attempt.reset();
        assert_eq!(attempt.earlier_error, None, "an attempt that stopped without an error");
    }

    #[test]
    fn plan_progress_survives_log_trimming_and_replay_but_resets_with_the_attempt() {
        let mut attempt = InstallAttempt::default();
        attempt.push_lines(vec!["[AtlasProgress] 8/40".into()]);
        attempt.push_lines((0..3000).map(|i| format!("line {i}")).collect());
        attempt.push_lines(vec!["[AtlasProgress] 2/40".into(), "[AtlasProgress] 8/40".into()]);
        assert_eq!(attempt.plan_progress.unwrap().completed, 8);
        attempt.push_lines(vec!["[AtlasProgress] 39/40".into()]);
        assert_eq!(attempt.plan_progress.unwrap().completed, 39);
        attempt.reset();
        assert!(attempt.plan_progress.is_none());
    }
}
