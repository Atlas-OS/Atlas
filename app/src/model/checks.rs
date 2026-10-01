//! The readiness checks and the Windows Security gate, up to the final
//! decision taken just before the install starts.

use std::collections::BTreeSet;
use std::sync::Arc;
use std::time::{Duration, Instant};

use gpui::Context;

use super::{Acquisition, AppModel, InstallBlock, Page, Preflight, Step};
use crate::services::preparation::State as Preparation;
use crate::services::requirements::{CheckContext, CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::SecurityStatus;

/// A Windows Security reading older than this is not trusted for the gate.
const SECURITY_FRESH: Duration = Duration::from_secs(5);
/// How often Windows Security is read while the gate can show it; well under
/// [`SECURITY_FRESH`], so a live reading never goes stale.
const SECURITY_POLL: Duration = Duration::from_secs(1);

/// What Get ready's status bar reports, most urgent first. The page words it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReadyStatus {
    /// The checks are running, or the installation files are on their way.
    Busy,
    /// A check stands in the way of installing.
    Blocked,
    /// There are no installation files yet.
    NoPackage,
    /// Only Windows and Store updates are left, and Check and install updates
    /// hasn't run yet.
    Updates,
    /// Windows and Store apps are updating, or waiting on an earlier run.
    Updating,
    /// Updating was stopped before it finished; Check and install updates
    /// finishes it.
    UpdatesStopped,
    /// Atlas reopened after its own restart; Continue updates finishes them.
    UpdatesResumed,
    /// Updating failed, needs a connection, or a restart didn't clear.
    UpdatesFailed,
    /// Updating ended without reporting a result.
    UpdatesUnconfirmed,
    /// Updating needs a restart, which is being saved or made, or waits for
    /// Restart and continue.
    UpdatesRestart,
    /// Advisory results to review before continuing.
    Warnings,
    /// Everything passed.
    Ready,
}

/// Where on Get ready something went wrong that diagnostics or a report can
/// help with, so their panel sits under the message about it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReadyHelp {
    /// Atlas can't read or confirm what's installed, so no installation can
    /// start here.
    Eligibility,
    /// A check stands in the way, or couldn't run.
    Checks,
    /// The installation files couldn't be prepared.
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
        self.checks
            .iter()
            .filter_map(|(_, result)| result.as_ref())
            .any(|result| check_blocks(result, &self.acknowledged) && !self.handled_by_preparation(result))
    }

    /// Whether Update Windows and Store apps deals with this result rather
    /// than the user: Windows updates waiting, or a restart Windows wants,
    /// found before the updates have run. It installs the one and asks for
    /// the other, so until then the result is a note, not a blocker.
    pub fn handled_by_preparation(&self, result: &CheckResult) -> bool {
        !self.preparation.ready()
            && result.verdict == Verdict::Fail
            && matches!(result.id, CheckId::PendingUpdates | CheckId::PendingReboot)
    }

    /// Whether the "Get ready" step is satisfied. Preparation must be done,
    /// so every failed check counts here.
    pub fn ready_to_continue(&self) -> bool {
        self.install_block().is_none()
            && self.preparation.ready()
            && self.playbook.is_some()
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

    /// What Get ready's status bar says. Nothing while no installation can
    /// start here, as the eligibility message says why. Once only updates are
    /// left, it says what updating is doing and names the card and button
    /// that come next, which can be far down the page.
    pub fn ready_status(&self) -> Option<ReadyStatus> {
        if self.install_block().is_some() {
            return None;
        }
        Some(if !self.checks_complete() || self.acquisition.is_busy() {
            ReadyStatus::Busy
        } else if self.checks_blocking() {
            ReadyStatus::Blocked
        } else if self.playbook.is_none() {
            ReadyStatus::NoPackage
        } else if !self.preparation.ready() {
            match self.preparation {
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
        } else if self
            .checks
            .iter()
            .any(|(_, result)| result.as_ref().is_some_and(|r| r.verdict != Verdict::Pass))
        {
            ReadyStatus::Warnings
        } else {
            ReadyStatus::Ready
        })
    }

    /// What went wrong on Get ready that diagnostics could help with, if
    /// anything, in the order the page shows the messages about it. Of the
    /// reasons no installation can start here, only an install state Atlas
    /// can't read or confirm needs help; one that says what to do (reinstall
    /// Windows, or open the package an unfinished install needs) gets none.
    pub fn ready_help(&self) -> Option<ReadyHelp> {
        if matches!(self.install_block(), Some(InstallBlock::Unknown | InstallBlock::RecordUnreadable { .. }))
        {
            Some(ReadyHelp::Eligibility)
        } else if self.checks_blocking() {
            Some(ReadyHelp::Checks)
        } else if matches!(self.acquisition, Acquisition::Failed(_)) {
            Some(ReadyHelp::Package)
        } else if matches!(self.preparation, Preparation::Failed | Preparation::RestartPersists { .. }) {
            Some(ReadyHelp::Preparation)
        } else {
            None
        }
    }

    /// The order Get ready lists the checks in; see [`CheckRows`].
    pub fn check_rows(&self) -> CheckRows {
        if !self.checks_complete() {
            return CheckRows { listed: (0..self.checks.len()).collect(), passed: Vec::new() };
        }
        let mut passed = Vec::new();
        let mut attention: Vec<(u8, usize)> = Vec::new();
        for (index, (_, result)) in self.checks.iter().enumerate() {
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

    pub fn can_install(&self) -> bool {
        self.flow.active
            && self.flow.step == Step::Install
            && !self.locked()
            && !self.flow.run.succeeded()
            && self.ready_to_continue()
            && self.elevated
            && self.security_ok()
    }

    /// The watcher runs only while a reading can matter: on the Security and
    /// Install steps of an idle flow, and on an Options screen opened from
    /// the Install step, which returns there. A running or finished install
    /// reads nothing from it (the final preflight takes its own reading), so
    /// it stops rather than polling and redrawing for no one.
    pub(super) fn sync_security_watch(&mut self, cx: &mut Context<Self>) {
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
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.security_confirmation = confirmed.then_some(self.security);
        cx.notify();
    }

    /// Runs every check again. The previous batch's tasks are dropped and
    /// their late results ignored; a provider still busy on a worker is
    /// joined by the new batch rather than duplicated (see
    /// `requirements::bounded`).
    pub fn run_checks(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.recheck_record(cx);
        let generation = self.checks_generation.next();
        self.checks = CheckId::ALL.iter().map(|id| (*id, None)).collect();
        self.acknowledged.clear();
        self.preflight_problem = None;
        let context = self.check_context();
        let run = self.env.adapters.run_check.clone();
        let elevated = self.env.adapters.is_elevated.clone();
        self.check_tasks = CheckId::ALL
            .iter()
            .map(|&id| {
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
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        if confirmed {
            self.acknowledged.insert(id);
        } else {
            self.acknowledged.remove(&id);
        }
        cx.notify();
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
    // No Defender, no switches: an earlier Atlas install removed it.
    !status.defender_present
        || status.all_off()
        || (elevated && confirmation == Some(*status) && status.off_where_readable())
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
