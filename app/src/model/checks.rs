//! The readiness checks and the Windows Security gate, up to the final
//! decision taken just before the install starts, and what the PC shows of
//! Microsoft Defender and the install choices, which the gate and the pages
//! around it put into words, up to what a finished install recorded.

use std::borrow::Cow;
use std::collections::BTreeSet;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, Instant};

use gpui::Context;

use super::{AcquireProblem, Acquisition, AppModel, InstallBlock, ModelEvent, Page, Preflight, Step};
use crate::i18n::describe::DefenderAbsence;
use crate::services::atlas_state::{InstallIdentity, InstallMode};
use crate::services::legacy_choices::Facts;
use crate::services::preparation::State as Preparation;
use crate::services::requirements::{CheckContext, CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::SecurityStatus;
use crate::services::windows_installation::Evidence;

/// A Windows Security reading older than this is not trusted for the gate.
const SECURITY_FRESH: Duration = Duration::from_secs(5);
/// How often Windows Security is read while the gate can show it; well under
/// [`SECURITY_FRESH`], so a live reading never goes stale.
const SECURITY_POLL: Duration = Duration::from_secs(1);
/// How long Windows Security shows every switch off before it moves on to
/// Install by itself, so the user coming back from Windows Security sees
/// the step done rather than a step gone.
const SECURITY_MOVE_ON: Duration = Duration::from_millis(1500);

/// What Windows Security does by itself on one visit to it, from the flow
/// arriving on the step until it leaves (see [`AppModel::advance_security`]).
#[derive(Clone, Copy, Debug, Default)]
pub(super) struct SecurityVisit {
    /// The flow is on Windows Security, and this is its visit.
    here: bool,
    /// Windows Security has been opened for this visit.
    opened: bool,
    /// No reading on this visit has needed the user yet, so one that passes
    /// passes the step over. Never on a visit the user made on purpose.
    skips: bool,
    /// The step moves on to Install once every switch reads off: once, and
    /// never on a visit the user made on purpose.
    moves_on: bool,
    /// Since when every switch has read off while the step shows it, before
    /// it moves on. It also tells the timer that moves on whether the
    /// all-off reading it was started for still stands.
    all_off_since: Option<Instant>,
}

/// Where Get ready stands, most urgent first: what the footer says while
/// Continue waits, and whether Get ready is done. The page words it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReadyStatus {
    /// The checks are running, or the installation files are on their way.
    Busy,
    /// A check stands in the way of installing.
    Blocked,
    /// There are no installation files yet.
    NoPackage,
    /// There are no installation files, and the package tried needs a newer
    /// Atlas Manager.
    ManagerOutdated,
    /// The ISO deferred the driver choice until sign-in.
    Drivers,
    /// Only Windows and Store updates are left, and they haven't started.
    Updates,
    /// Only updates are left, and they move Windows to a new version, whose
    /// licence terms the user hasn't accepted yet.
    WindowsTerms,
    /// Windows and Store apps are updating, or waiting on an earlier run.
    Updating,
    /// The user stopped updating before it finished.
    UpdatesStopped,
    /// Atlas reopened after its own restart, and updating hasn't carried on yet.
    UpdatesResumed,
    /// Updating failed, needs a connection, or a restart didn't clear.
    UpdatesFailed,
    /// Updating ended without reporting a result.
    UpdatesUnconfirmed,
    /// Updating needs a restart, which is being saved, counted down or made.
    UpdatesRestart,
    /// Advisory results to review before continuing.
    Warnings,
    /// Everything passed.
    Ready,
}

/// Where on Get ready something went wrong unexpectedly, so the help row
/// (Send a report, Export diagnostics) sits under it. A problem the user can
/// fix themselves, such as a battery, a connection or a check that found
/// what it says to fix, gets no help row.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReadyHelp {
    /// Atlas can't read or confirm what's installed, so no installation can
    /// start here.
    Eligibility,
    /// A check that stands in the way couldn't run.
    Checks,
    /// The installation files couldn't be prepared, for a reason a new
    /// download or another file doesn't fix.
    Package,
    /// Updating Windows and Store apps failed, or a restart didn't clear.
    Preparation,
}

/// How Get ready lists the checks, as indexes into the model's checks. While
/// the checks run they keep their usual order, so nothing moves under the
/// pointer. Once every check has reported, what needs attention comes first,
/// most urgent first, and the passed checks are set apart so they can be
/// folded into one line.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct CheckRows {
    pub listed: Vec<usize>,
    pub passed: Vec<usize>,
}

impl AppModel {
    /// Every check has reported, advisory ones included.
    pub fn checks_complete(&self) -> bool {
        !self.checks.is_empty() && self.checks.iter().all(|(_, result)| result.is_some())
    }

    /// Every required check has reported. Activation remains advisory.
    pub fn blocking_checks_complete(&self) -> bool {
        !self.checks.is_empty()
            && self.checks.iter().filter(|(id, _)| id.blocking()).all(|(_, result)| result.is_some())
    }

    /// Whether a check stands in the way, as Get ready reports it: updates
    /// or a restart that Update Windows and Store apps takes care of don't
    /// count until it has run (see [`AppModel::handled_by_preparation`]).
    /// The final checks before the install starts count everything.
    pub fn checks_blocking(&self) -> bool {
        self.blocking_results().next().is_some()
    }

    /// The results that stand in the way, as [`AppModel::checks_blocking`]
    /// counts them, in the checks' usual order.
    pub fn blocking_results(&self) -> impl Iterator<Item = &CheckResult> {
        self.counted_results()
            .filter(|result| check_blocks(result, &self.acknowledged) && !self.handled_by_preparation(result))
    }

    /// The checks Get ready runs: every check the install needs, and where a
    /// move to a newer Windows release applies, what the move needs.
    fn wanted_checks(&self) -> Vec<CheckId> {
        let mut ids = CheckId::ALL.to_vec();
        if self.windows_transition().is_some() {
            ids.extend(CheckId::MOVE);
        }
        ids
    }

    /// Whether check `id` counts on Get ready: what a move needs counts only
    /// while the move is chosen, so keeping this version leaves it aside.
    pub fn check_counts(&self, id: CheckId) -> bool {
        !id.for_move() || self.transition_chosen()
    }

    /// The results of the checks that count (see [`AppModel::check_counts`]).
    fn counted_results(&self) -> impl Iterator<Item = &CheckResult> {
        self.checks.iter().filter(|(id, _)| self.check_counts(*id)).filter_map(|(_, result)| result.as_ref())
    }

    /// Whether Update Windows and Store apps deals with this result rather
    /// than the user: Windows updates waiting, or a restart Windows wants,
    /// found before the updates have run. It installs the one and asks for
    /// the other, so until then the result is a note, not a blocker.
    /// The same holds for a Windows version Atlas moves from, once the move
    /// is chosen, and for an update scan that couldn't run because Windows
    /// Update is turned off, which updating turns on.
    pub fn handled_by_preparation(&self, result: &CheckResult) -> bool {
        if self.preparation.ready() {
            return false;
        }
        match (result.id, result.verdict, &result.detail) {
            (CheckId::PendingUpdates | CheckId::PendingReboot, Verdict::Fail, _) => true,
            (CheckId::SupportedBuild, Verdict::Fail, CheckDetail::BuildTransition { .. }) => {
                self.transition_chosen()
            }
            (CheckId::PendingUpdates, Verdict::Unknown, _) => {
                self.update_access.as_ref().is_some_and(|access| !access.blockers.is_empty())
            }
            _ => false,
        }
    }

    /// Whether the "Get ready" step is satisfied. Preparation must be done,
    /// so every failed check counts here.
    pub fn ready_to_continue(&self) -> bool {
        self.install_block().is_none()
            && !self.driver_choice_required()
            && self.preparation.ready()
            && self.package.is_some()
            && !self.acquisition.is_busy()
            && self.blocking_checks_complete()
            && !self.checks_blocking()
    }

    /// Whether a step the user has already been through still holds: Get
    /// ready while it's satisfied, and Windows Security while its switches
    /// pass, or until a reading has come in. The other steps ask nothing that
    /// can come undone.
    pub fn step_satisfied(&self, step: Step) -> bool {
        match step {
            Step::Ready => self.ready_to_continue(),
            Step::Security => !self.security_fresh() || self.security_ok(),
            Step::Options | Step::Install => true,
        }
    }

    /// Where Get ready stands. Nothing while no installation can start here,
    /// as the eligibility message says why.
    pub fn ready_status(&self) -> Option<ReadyStatus> {
        if self.install_block().is_some() {
            return None;
        }
        Some(if !self.checks_complete() || self.acquisition.is_busy() {
            ReadyStatus::Busy
        } else if self.checks_blocking() {
            ReadyStatus::Blocked
        } else if self.package.is_none() && self.package_needs_newer_manager() {
            ReadyStatus::ManagerOutdated
        } else if self.package.is_none() {
            ReadyStatus::NoPackage
        } else if self.driver_choice_required() {
            ReadyStatus::Drivers
        } else if !self.preparation.ready() {
            match self.preparation {
                // Waiting for Windows Update's offer is updating at work,
                // between looks too.
                _ if self.offer_wait_shown() => ReadyStatus::Updating,
                Preparation::Idle if self.transition_chosen() && !self.windows_terms_accepted => {
                    ReadyStatus::WindowsTerms
                }
                Preparation::Idle => ReadyStatus::Updates,
                Preparation::Cancelled => ReadyStatus::UpdatesStopped,
                Preparation::Resumed => ReadyStatus::UpdatesResumed,
                Preparation::Running { .. } | Preparation::WaitingExternal => ReadyStatus::Updating,
                Preparation::Reboot | Preparation::SavingRestart | Preparation::Restarting => {
                    ReadyStatus::UpdatesRestart
                }
                // A run that ended without a report isn't called a failure.
                Preparation::Failed
                    if self.preparation_progress.as_ref().and_then(|p| p.failure()).is_none()
                        && self.preparation_error.is_none() =>
                {
                    ReadyStatus::UpdatesUnconfirmed
                }
                Preparation::Failed | Preparation::Network | Preparation::RestartPersists { .. } => {
                    ReadyStatus::UpdatesFailed
                }
                Preparation::Ready => return None,
            }
        } else if self.counted_results().any(|result| result.verdict != Verdict::Pass) {
            ReadyStatus::Warnings
        } else {
            ReadyStatus::Ready
        })
    }

    /// What went wrong unexpectedly on Get ready, which a report or the
    /// diagnostics could help with, if anything, in the order the page shows
    /// it. Of the reasons no installation can start here, only an install
    /// state Atlas can't read or confirm needs help; one that says what to do
    /// (reinstall Windows, or open the package an unfinished install needs)
    /// gets none. Neither does a problem whose fix is at hand: a check that
    /// found what it says to fix, a download to try again or another file to
    /// open, or updates paused for the battery or the connection.
    pub fn ready_help(&self) -> Option<ReadyHelp> {
        if matches!(self.install_block(), Some(InstallBlock::Unknown | InstallBlock::RecordUnreadable { .. }))
        {
            Some(ReadyHelp::Eligibility)
        } else if self.counted_results().any(|result| {
            // A check that failed found a known condition, and its row says
            // what to do; one that couldn't run is the unexpected kind.
            result.verdict == Verdict::Unknown
                && check_blocks(result, &self.acknowledged)
                && !self.handled_by_preparation(result)
        }) {
            Some(ReadyHelp::Checks)
        } else if matches!(
            self.acquisition,
            Acquisition::Failed(
                AcquireProblem::NoPackageAsset { .. }
                    | AcquireProblem::Incomplete { .. }
                    | AcquireProblem::Other { .. }
            )
        ) {
            Some(ReadyHelp::Package)
        } else if self.preparation_failed_unexpectedly() {
            Some(ReadyHelp::Preparation)
        } else {
            None
        }
    }

    /// Updating failed, or a restart didn't clear, for a reason the user
    /// can't put right as Get ready says: not a wait for Windows Update's
    /// offer, and none of the causes whose advice is the fix, such as an app
    /// left open, a pause for the battery or the connection, Windows Update
    /// out of reach, updates to finish in Windows Update or Microsoft Store,
    /// the wrong account, too little disk space, a Windows too damaged to
    /// update or a linked Atlas Manager folder. Of a move's own causes, only an update Windows
    /// couldn't install or rolled back is unexpected: the others name what
    /// stands in the way, or offer Send a report as their one button.
    fn preparation_failed_unexpectedly(&self) -> bool {
        match self.preparation {
            Preparation::RestartPersists { .. } => true,
            Preparation::Failed if self.preparation_source_linked => false,
            Preparation::Failed => {
                let failure = self.preparation_progress.as_ref().and_then(|progress| progress.failure());
                !failure.is_some_and(|failure| {
                    failure.not_offered()
                        || failure.error_code.as_deref().is_some_and(|code| {
                            // An app open while it updates; another install or a restart first.
                            ["0x80073D02", "0x80240016"].iter().any(|known| code.eq_ignore_ascii_case(known))
                        })
                        || matches!(
                            failure.reason.as_deref(),
                            Some(
                                "store-paused-battery"
                                    | "store-paused-network"
                                    | "store-timeout"
                                    | "store-missing"
                                    | "manual-updates"
                                    | "windows-update-unreachable"
                                    | "session-owner"
                                    | "component-store-unrepairable"
                            )
                        )
                        || failure.reason.as_deref().is_some_and(|reason| {
                            reason.starts_with("feature-")
                                && !matches!(reason, "feature-failed" | "feature-rolled-back")
                        })
                })
            }
            _ => false,
        }
    }

    /// The order Get ready lists the checks in; see [`CheckRows`]. A check
    /// that doesn't count isn't listed.
    pub fn check_rows(&self) -> CheckRows {
        let counted = || (0..self.checks.len()).filter(|index| self.check_counts(self.checks[*index].0));
        if !self.checks_complete() {
            return CheckRows { listed: counted().collect(), passed: Vec::new() };
        }
        let mut passed = Vec::new();
        let mut attention: Vec<(u8, usize)> = Vec::new();
        for index in counted() {
            let result = &self.checks[index].1;
            match result.as_ref().and_then(|result| self.attention_rank(result)) {
                Some(rank) => attention.push((rank, index)),
                None => passed.push(index),
            }
        }
        // Equal ranks keep their usual order.
        attention.sort();
        CheckRows { listed: attention.into_iter().map(|(_, index)| index).collect(), passed }
    }

    /// How urgently a result needs the user, lowest first, or `None` once it
    /// has passed: what blocks, then what couldn't be checked, then advice,
    /// then what Update Windows and Store apps takes care of. Confirming a
    /// row by hand doesn't change its rank, so the row stays under the
    /// pointer that ticked it.
    fn attention_rank(&self, result: &CheckResult) -> Option<u8> {
        let handled = self.handled_by_preparation(result);
        let blocks = result.blocks_install() && !handled;
        Some(match result.verdict {
            Verdict::Pass => return None,
            Verdict::Fail if blocks => 0,
            Verdict::Unknown if blocks => 1,
            _ if handled => 3,
            _ => 2,
        })
    }

    /// Whether the Windows Security reading is recent enough to trust.
    pub fn security_fresh(&self) -> bool {
        self.security_read_at.is_some_and(|read| read.elapsed() < SECURITY_FRESH)
    }

    /// Whether the user's manual confirmation covers the current reading.
    pub fn security_acknowledged(&self) -> bool {
        self.security_confirmation == Some(self.security)
    }

    /// Whether Windows Security is verified off: every switch reads off, or
    /// every readable switch does and the user confirmed the rest by hand.
    pub fn security_ok(&self) -> bool {
        self.security_fresh() && security_verified(&self.security, self.security_confirmation, self.elevated)
    }

    /// Whether Windows Security passes the gate only on the user's word for
    /// the switches that can't be read. The front door is told so, as it
    /// refuses what it can't read otherwise.
    pub fn security_confirmed_by_hand(&self) -> bool {
        confirmed_by_hand(&self.security, self.security_confirmation, self.elevated)
    }

    pub fn can_install(&self) -> bool {
        self.flow.active
            && self.flow.step == Step::Install
            && !self.locked()
            && !self.flow.run.succeeded()
            && self.ready_to_continue()
            && self.elevated
            && self.security_ok()
    }

    /// Starts or stops the watcher (see [`AppModel::watch_security`]) and
    /// begins or ends the visit to Windows Security, as the page or the step
    /// changes.
    pub(super) fn sync_security_watch(&mut self, cx: &mut Context<Self>) {
        self.watch_security(cx);
        self.sync_security_visit(cx);
    }

    /// The watcher runs only while a reading can matter: on the Security and
    /// Install steps of an idle flow, and on an Options screen opened from
    /// the Install step, which returns there. A running or finished install
    /// reads nothing from it (the final preflight takes its own reading), so
    /// it stops rather than polling and redrawing for no one.
    fn watch_security(&mut self, cx: &mut Context<Self>) {
        let wanted = self.page == Page::Install
            && (matches!(self.flow.step, Step::Security | Step::Install)
                || (self.flow.step == Step::Options && self.returning_to_install))
            && !self.flow.locked()
            && !self.flow.run.succeeded();
        if wanted == self.security_watch.is_some() {
            return;
        }
        let generation = self.security_generation.next();
        // Whatever was read before the watcher paused is stale now.
        self.security_read_at = None;
        if !wanted {
            self.security_watch = None;
            return;
        }
        let read = self.env.adapters.read_security.clone();
        self.security_watch = Some(cx.spawn(async move |this, cx| {
            let mut first = true;
            loop {
                let read = read.clone();
                let status = cx.background_executor().spawn(async move { read() }).await;
                let keep_going = this
                    .update(cx, |this, cx| {
                        if this.security_generation != generation {
                            return false;
                        }
                        let changed = this.observe_security(status);
                        // The first reading turns "Reading" into a verdict;
                        // after that only a different reading is news.
                        if changed || first {
                            cx.notify();
                        }
                        first = false;
                        this.advance_security(cx);
                        true
                    })
                    .unwrap_or(false);
                if !keep_going {
                    break;
                }
                cx.background_executor().timer(SECURITY_POLL).await;
            }
        }));
    }

    /// Begins a visit as the flow arrives on Windows Security, and ends it as
    /// the flow leaves. A visit the user didn't make on purpose may pass the
    /// step over, so it takes its first reading at once, waiting a moment for
    /// it, rather than show the step before it knows there's nothing to do.
    fn sync_security_visit(&mut self, cx: &mut Context<Self>) {
        let here = self.flow.active && self.flow.step == Step::Security;
        let on_purpose = std::mem::take(&mut self.security_on_purpose);
        if here == self.security_visit.here {
            return;
        }
        if !here {
            self.security_visit = SecurityVisit::default();
            return;
        }
        let acts = !on_purpose && self.env.automatic_security;
        self.security_visit =
            SecurityVisit { here, opened: false, skips: acts, moves_on: acts, all_off_since: None };
        if acts && self.security_watch.is_some() && !self.security_fresh() {
            const ARRIVAL_READING_WAIT: Duration = Duration::from_millis(250);
            let read = self.env.adapters.read_security.clone();
            let reading = cx.background_executor().spawn(async move { read() });
            if let Ok(status) = cx.foreground_executor().block_with_timeout(ARRIVAL_READING_WAIT, reading) {
                self.observe_security(status);
            }
        }
        // Once whatever brought the flow here has finished, as acting can
        // move it on again.
        let this = cx.weak_entity();
        cx.defer(move |cx| {
            this.update(cx, |this, cx| this.advance_security(cx)).ok();
        });
    }

    /// Whether Windows Security may act by itself now: the app's own flow,
    /// not a review preview, on the step showing, with a reading to act on.
    fn security_acts_by_itself(&self) -> bool {
        self.env.automatic_security
            && !super::preview::active()
            && self.page == Page::Install
            && self.flow.active
            && self.flow.step == Step::Security
            && !self.locked()
            && self.security_fresh()
    }

    /// What Windows Security does by itself on a visit (see
    /// [`SecurityVisit`]), from the latest reading. It never changes a
    /// switch: they're the user's to turn off.
    /// - While a switch reads on or can't be read, it opens Windows Security
    ///   at the switches, once per visit, where Atlas has the permission to
    ///   tell them apart.
    /// - A first reading that already passes, with Defender gone or every
    ///   switch off, passes the step over and goes on to Install, unless
    ///   the user chose to keep a Defender that's missing: that warning is
    ///   theirs to read.
    /// - Once every switch reads off later in the visit, the window comes to
    ///   the front and shows it for [`SECURITY_MOVE_ON`], then goes on to
    ///   Install, unless a switch comes back on meanwhile.
    ///
    /// None of it happens on a visit the user made on purpose, except
    /// opening Windows Security.
    pub(super) fn advance_security(&mut self, cx: &mut Context<Self>) {
        if !self.security_acts_by_itself() {
            return;
        }
        if !self.security_ok() {
            self.security_visit.skips = false;
            self.security_visit.all_off_since = None;
            if !self.security_visit.opened && self.elevated && self.security.defender_present {
                self.security_visit.opened = true;
                log::info!("Opening Windows Security for the protection switches still to turn off");
                self.open_windows_security(cx);
            }
            return;
        }
        if std::mem::take(&mut self.security_visit.skips) {
            if self.security.defender_present || self.defender_absence() != DefenderAbsence::Missing {
                log::info!("Windows Security has nothing to turn off; going on to Install");
                self.next_step(cx);
            }
            return;
        }
        if !self.security_visit.moves_on || !self.security.all_off() {
            self.security_visit.all_off_since = None;
            return;
        }
        if self.security_visit.all_off_since.is_some() {
            return;
        }
        let since = Instant::now();
        self.security_visit.all_off_since = Some(since);
        log::info!("Every Windows Security protection switch reads off; going on to Install");
        cx.emit(ModelEvent::BringToFront);
        cx.spawn(async move |this, cx| {
            cx.background_executor().timer(SECURITY_MOVE_ON).await;
            this.update(cx, |this, cx| {
                // Only for the all-off reading this timer was started for,
                // and only while it still stands.
                if this.security_visit.all_off_since == Some(since)
                    && this.security_acts_by_itself()
                    && this.security_ok()
                    && this.security.all_off()
                {
                    this.security_visit.moves_on = false;
                    this.security_visit.all_off_since = None;
                    this.next_step(cx);
                }
            })
            .ok();
        })
        .detach();
    }

    /// Whether Windows Security is showing every switch off before it moves
    /// on to Install by itself.
    #[cfg(test)]
    pub(super) fn security_moving_on(&self) -> bool {
        self.security_visit.all_off_since.is_some()
    }

    /// Opens Windows Security at Virus & threat protection settings, where
    /// the switches are: Open Windows Security, and the step by itself. A
    /// page an Atlas 0.5 policy hides is shown again first.
    pub fn open_windows_security(&mut self, cx: &mut Context<Self>) {
        self.show_hidden_virus_page();
        let open = self.env.adapters.open_windows_security.clone();
        cx.background_executor()
            .spawn(async move {
                if let Err(error) = open() {
                    log::warn!("couldn't open Windows Security: {error:#}");
                }
            })
            .detach();
    }

    /// Records a reading. Returns whether it differs from the last one. A
    /// confirmation given for the previous reading no longer matches, so a
    /// change in what can be read invalidates it by construction.
    pub(super) fn observe_security(&mut self, status: SecurityStatus) -> bool {
        let changed = self.security != status;
        self.security = status;
        self.security_read_at = Some(Instant::now());
        changed
    }

    pub fn acknowledge_security(&mut self, confirmed: bool, cx: &mut Context<Self>) {
        if self.locked() {
            return;
        }
        self.security_confirmation = confirmed.then_some(self.security);
        cx.notify();
    }

    /// Runs every check again. The previous batch's tasks are dropped and
    /// their late results ignored; a provider still busy on a worker is
    /// joined by the new batch rather than duplicated (see
    /// `requirements::deadline`).
    pub fn run_checks(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if self.locked() {
            return;
        }
        self.recheck_record(cx);
        let generation = self.checks_generation.next();
        let wanted = self.wanted_checks();
        self.checks = wanted.iter().map(|id| (*id, None)).collect();
        self.acknowledged.clear();
        self.preflight_problem = None;
        let context = self.check_context();
        let run = self.env.adapters.run_check.clone();
        let elevated = self.env.adapters.is_elevated.clone();
        self.check_tasks = wanted
            .into_iter()
            .map(|id| {
                let context = context.clone();
                let run = run.clone();
                let elevated = elevated.clone();
                cx.spawn(async move |this, cx| {
                    let result = cx.background_executor().spawn(async move { run(id, &context) }).await;
                    this.update(cx, |this, cx| {
                        if this.checks_generation != generation {
                            return;
                        }
                        if let Some(slot) = this.checks.iter_mut().find(|(check, _)| *check == id) {
                            slot.1 = Some(result);
                        }
                        if id == CheckId::Administrator {
                            this.elevated = elevated();
                        }
                        if this.checks_complete() {
                            this.check_offer_on_reopen(cx);
                            this.follow_free_space(cx);
                            this.advance_ready(cx);
                        }
                        cx.notify();
                    })
                    .ok();
                })
            })
            .collect();
        cx.notify();
    }

    /// What every check is judged against: this PC and the builds the
    /// package supports.
    pub(super) fn check_context(&self) -> Arc<CheckContext> {
        Arc::new(CheckContext {
            system: self.system.clone(),
            supported_builds: self.manifest().supported_builds.clone(),
        })
    }

    pub fn acknowledge_check(&mut self, id: CheckId, confirmed: bool, cx: &mut Context<Self>) {
        if self.locked() {
            return;
        }
        if confirmed {
            self.acknowledged.insert(id);
        } else {
            self.acknowledged.remove(&id);
        }
        self.advance_ready(cx);
        cx.notify();
    }

    /// Before Windows Security opens: Atlas 0.5's Defender remover hid the
    /// Virus & threat protection page with a policy, and Defender can come back
    /// through its own updates while the page stays hidden. Updating from 0.5
    /// shows the page again, so its switches can be turned off.
    pub fn show_hidden_virus_page(&mut self) {
        let from_0_5 = matches!(&self.install_identity,
            Ok(InstallIdentity::Installed(version)) if version.starts_with("0.5"));
        if !from_0_5 || !self.elevated {
            return;
        }
        match (self.env.adapters.show_hidden_virus_page)() {
            Ok(true) => {
                log::info!("Showed Windows Security's Virus & threat protection page, which Atlas 0.5 hid")
            }
            Ok(false) => {}
            Err(error) => {
                log::warn!("couldn't show Windows Security's Virus & threat protection page: {error:#}")
            }
        }
    }

    /// Whether Windows on this PC shows signs of earlier use, on a PC
    /// without Atlas: installed a week ago or more, or with several apps
    /// (see [`Evidence`]). Installing Atlas over a used Windows can break
    /// what the user already has, so Home recommends reinstalling Windows
    /// from an Atlas ISO first. Never for the Windows that Atlas's own media
    /// has just installed, before the desktop or after it: its age and apps
    /// come with the image. `false` until the evidence has been read.
    pub fn windows_looks_used(&self) -> bool {
        matches!(self.install_identity, Ok(InstallIdentity::Fresh))
            && !self.before_desktop
            && !self.staged_iso_setup
            && self.windows_installation.as_ref().is_some_and(Evidence::suggests_prior_use)
    }

    /// Reads, on a worker, what this PC shows of earlier use of Windows. The
    /// log keeps it, so a report from a used Windows says so.
    pub(super) fn read_windows_installation(&mut self, cx: &mut Context<Self>) {
        let read = self.env.adapters.read_windows_installation.clone();
        cx.spawn(async move |this, cx| {
            let evidence = cx.background_executor().spawn(async move { read() }).await;
            this.update(cx, |this, cx| {
                log::info!(
                    "Windows on this PC: installed {} days ago, {} desktop apps",
                    evidence
                        .age_days
                        .map_or_else(|| "an unknown number of".to_owned(), |days| days.to_string()),
                    evidence.desktop_apps,
                );
                this.windows_installation = Some(evidence);
                log::info!("Windows on this PC looks used to Atlas: {}", this.windows_looks_used());
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// Why Microsoft Defender isn't on this PC, for the Windows Security
    /// step's bar, from the choice this installation makes and whether
    /// Atlas's NoDefender package is installed. Keeping the choices on an
    /// update leaves Defender as the PC has it; a first install, a Rebase and
    /// choosing again apply the choice. An unfinished install goes on as its
    /// record says it began, as the front door reads it: keeping the choices
    /// on an update leaves Defender removed even where the options it holds
    /// keep Defender, as a capture by an earlier release or another tool
    /// left them while Atlas's package still removes it.
    pub fn defender_absence(&self) -> DefenderAbsence {
        let keeps = self.effective_options().iter().any(|option| option == "defender-enable");
        let applied = match &self.install_identity {
            Ok(InstallIdentity::Resume(_, unfinished)) => {
                unfinished.choose_again || matches!(unfinished.mode, InstallMode::Fresh | InstallMode::Rebase)
            }
            _ => self.update_choices().is_none() || self.choosing_again(),
        };
        match (self.pc_facts.defender_package_installed(), keeps) {
            (true, true) if applied => DefenderAbsence::Restore,
            (true, _) => DefenderAbsence::Removed,
            (false, true) => DefenderAbsence::Missing,
            (false, false) => DefenderAbsence::Absent,
        }
    }

    /// What this PC shows of the install choices, as an update or reinstall
    /// reads it, for what Your choices says each answer changes.
    pub fn choice_facts(&self) -> Cow<'_, Facts> {
        self.update_facts()
    }

    /// Whether Home and the "Atlas is installed" window warn that Microsoft
    /// Defender is still removed though Atlas's record kept it (see
    /// [`AppModel::defender_not_restored`]), until the warning is dismissed
    /// for this install. Not while an install runs or waits for Done: one
    /// that chose again may be bringing Defender back.
    pub fn defender_not_restored_shown(&self) -> bool {
        let installed_at = self.installed().and_then(|state| state.installed_at.as_ref());
        self.defender_not_restored()
            && !self.install_in_progress()
            && self.settings.defender_not_restored_dismissed.as_ref() != installed_at
    }

    /// Dismisses that warning for good for the recorded install. The warning
    /// that a kept Defender is missing is dismissed apart: it shows once
    /// Atlas's package is gone, as when Toggle Defender took it off and
    /// Defender still didn't come back, which is what its report is for.
    pub fn dismiss_defender_not_restored(&mut self, cx: &mut Context<Self>) {
        let Some(installed_at) = self.installed().and_then(|state| state.installed_at.clone()) else {
            return;
        };
        self.settings.defender_not_restored_dismissed = Some(installed_at.clone());
        self.persist_preference(move |doc| doc.defender_not_restored_dismissed = Some(installed_at), cx);
        cx.notify();
    }

    /// What the install the "Atlas is installed" window is about tried to
    /// apply and didn't get, as its completion recorded it (the options of
    /// each such choice): the install this window followed, or the one
    /// startup found finished after the restart it asked for, which recovery
    /// has closed out since. A choice recorded otherwise only because the
    /// install had nothing to do for it, such as VBS already off on a first
    /// install that left its box clear, isn't among them.
    pub fn choices_not_applied(&self) -> Option<&[String]> {
        self.session.as_ref().or(self.finished_session.as_ref())?;
        self.installed()?.history.last()?.not_applied.as_deref()
    }

    /// The log of that install, for the "Atlas is installed" window's help:
    /// the machine's copy, which a successful install's plan wrote to, while
    /// it's there, or else the log of the install this window followed or
    /// startup closed out.
    pub fn install_log_path(&self) -> Option<PathBuf> {
        let record = self.session.as_ref().or(self.finished_session.as_ref())?;
        let machine = &self.session_paths.machine_log;
        Some(if machine.exists() { machine.clone() } else { record.log_path.clone() })
    }
}

/// Whether a check still stands in the way: a blocking result the user has
/// not acknowledged (only an update scan that could not run can be).
fn check_blocks(result: &CheckResult, acknowledged: &BTreeSet<CheckId>) -> bool {
    result.blocks_install() && !(result.needs_acknowledgement() && acknowledged.contains(&result.id))
}

/// Whether Windows Security counts as off for the gate: every switch reads
/// off, or every readable switch does and the user confirmed the unreadable
/// rest by hand for this very reading. One rule for the step's Next button,
/// the Install button and the final preflight.
pub fn security_verified(
    status: &SecurityStatus,
    confirmation: Option<SecurityStatus>,
    elevated: bool,
) -> bool {
    // No Defender, no switches to turn off, whatever took it away and
    // whatever the choices ask: the step's bar says which (see
    // `AppModel::defender_absence`), and none of its cases stops the install.
    !status.defender_present || status.all_off() || confirmed_by_hand(status, confirmation, elevated)
}

/// The part of [`security_verified`] that rests on the user's confirmation:
/// every readable switch is off and the rest were confirmed by hand.
fn confirmed_by_hand(status: &SecurityStatus, confirmation: Option<SecurityStatus>, elevated: bool) -> bool {
    status.defender_present && elevated && confirmation == Some(*status) && status.off_where_readable()
}

/// The last decision before the child starts, from the readings taken a
/// moment ago: which checks still stand in the way, and whether Windows
/// Security is verified off under the current confirmation.
pub fn preflight_decision(
    results: &[CheckResult],
    acknowledged: &BTreeSet<CheckId>,
    security: &SecurityStatus,
    confirmation: Option<SecurityStatus>,
    elevated: bool,
) -> Result<(), Preflight> {
    let problems: Vec<(CheckId, CheckDetail)> = results
        .iter()
        .filter(|result| check_blocks(result, acknowledged))
        .map(|result| (result.id, result.detail.clone()))
        .collect();
    let security_problem = (!security_verified(security, confirmation, elevated)).then(|| security.counts());
    if problems.is_empty() && security_problem.is_none() {
        Ok(())
    } else {
        Err(Preflight::Changed { checks: problems, security: security_problem })
    }
}
