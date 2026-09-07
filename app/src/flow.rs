//! The install flow as a small state machine: which step is showing, whether
//! an install is preparing or running, and which transitions are allowed.
//! Every route in the UI goes through these rules, so a running install
//! cannot be edited, navigated away from or restarted by any button.

use crate::services::installer::InstallOutcome;

/// The install flow. Checks come first so nothing is switched off for
/// nothing; Windows Security comes last so protection is off for the shortest
/// possible time.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Step {
    Ready,
    Options,
    Security,
    Install,
}

impl Step {
    pub const ALL: [Step; 4] = [Step::Ready, Step::Options, Step::Security, Step::Install];

    /// Command-line and draft spelling.
    pub fn parse(name: &str) -> Option<Step> {
        match name.to_ascii_lowercase().as_str() {
            "ready" | "checks" => Some(Step::Ready),
            "options" => Some(Step::Options),
            "security" => Some(Step::Security),
            "install" => Some(Step::Install),
            _ => None,
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Step::Ready => "ready",
            Step::Options => "options",
            Step::Security => "security",
            Step::Install => "install",
        }
    }

    pub fn index(self) -> usize {
        Step::ALL.iter().position(|s| *s == self).unwrap_or(0)
    }

    pub fn next(self) -> Option<Step> {
        Step::ALL.get(self.index() + 1).copied()
    }

    pub fn previous(self) -> Option<Step> {
        self.index().checked_sub(1).and_then(|i| Step::ALL.get(i).copied())
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RunState {
    Idle,
    /// Final checks are running again just before the child starts.
    Preparing,
    Running,
    Finished(InstallOutcome),
}

impl RunState {
    /// The install is in progress: nothing that feeds it may change.
    pub fn is_locked(self) -> bool {
        matches!(self, RunState::Preparing | RunState::Running)
    }
}

/// Why a transition was refused. Callers show nothing for these: the UI
/// disables the controls, and the refusal is the backstop for every other route.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Refusal {
    /// No flow is active.
    NotActive,
    /// An install is preparing or running.
    Locked,
    /// Steps ahead of the current one cannot be jumped to.
    CannotSkipAhead,
    /// The install succeeded; the flow is over.
    Complete,
    /// Not applicable in the current run state.
    WrongState,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Flow {
    pub active: bool,
    pub step: Step,
    pub run: RunState,
}

impl Default for Flow {
    fn default() -> Self {
        Self { active: false, step: Step::Ready, run: RunState::Idle }
    }
}

impl Flow {
    pub fn locked(&self) -> bool {
        self.run.is_locked()
    }

    /// Whether the package, options and install settings may change.
    pub fn may_edit(&self) -> bool {
        !self.locked()
    }

    fn require_unlocked(&self) -> Result<(), Refusal> {
        if self.locked() { Err(Refusal::Locked) } else { Ok(()) }
    }

    fn require_active(&self) -> Result<(), Refusal> {
        self.require_unlocked()?;
        if self.active { Ok(()) } else { Err(Refusal::NotActive) }
    }

    /// Starts (or restarts) the flow at the first step.
    pub fn begin(&mut self) -> Result<(), Refusal> {
        self.require_unlocked()?;
        self.active = true;
        self.step = Step::Ready;
        self.run = RunState::Idle;
        Ok(())
    }

    /// Picks the flow up where a draft or a startup flag left it.
    pub fn resume(&mut self, step: Step) -> Result<(), Refusal> {
        self.require_unlocked()?;
        self.active = true;
        self.step = step;
        self.run = RunState::Idle;
        Ok(())
    }

    /// Follows an install that is already running (found via its session).
    pub fn attach_running(&mut self) -> Result<(), Refusal> {
        self.require_unlocked()?;
        self.active = true;
        self.step = Step::Install;
        self.run = RunState::Running;
        Ok(())
    }

    /// Moving between steps after an unsuccessful attempt starts a new
    /// attempt: the old result no longer describes what would run next.
    fn leave_result(&mut self) {
        if matches!(self.run, RunState::Finished(outcome) if !outcome.is_success()) {
            self.run = RunState::Idle;
        }
    }

    /// Revisits an earlier step. Later steps cannot be skipped to.
    pub fn go_to(&mut self, step: Step) -> Result<(), Refusal> {
        self.require_active()?;
        if step > self.step {
            return Err(Refusal::CannotSkipAhead);
        }
        self.step = step;
        self.leave_result();
        Ok(())
    }

    pub fn advance(&mut self) -> Result<Step, Refusal> {
        self.require_active()?;
        let next = self.step.next().ok_or(Refusal::WrongState)?;
        self.step = next;
        self.leave_result();
        Ok(next)
    }

    pub fn back(&mut self) -> Result<Step, Refusal> {
        self.require_active()?;
        if matches!(self.run, RunState::Finished(outcome) if outcome.is_success()) {
            return Err(Refusal::Complete);
        }
        let previous = self.step.previous().ok_or(Refusal::WrongState)?;
        self.step = previous;
        self.leave_result();
        Ok(previous)
    }

    /// Leaves the flow. Refused while an install is in progress.
    pub fn cancel(&mut self) -> Result<(), Refusal> {
        self.require_unlocked()?;
        self.active = false;
        self.step = Step::Ready;
        self.run = RunState::Idle;
        Ok(())
    }

    /// Final checks before the child process starts.
    pub fn start_preparing(&mut self) -> Result<(), Refusal> {
        self.require_active()?;
        if self.step != Step::Install {
            return Err(Refusal::WrongState);
        }
        if matches!(self.run, RunState::Finished(outcome) if outcome.is_success()) {
            return Err(Refusal::Complete);
        }
        self.run = RunState::Preparing;
        Ok(())
    }

    /// The final checks failed; back to the idle install step.
    pub fn stop_preparing(&mut self) -> Result<(), Refusal> {
        if self.run != RunState::Preparing {
            return Err(Refusal::WrongState);
        }
        self.run = RunState::Idle;
        Ok(())
    }

    pub fn start_running(&mut self) -> Result<(), Refusal> {
        if self.run != RunState::Preparing {
            return Err(Refusal::WrongState);
        }
        self.run = RunState::Running;
        Ok(())
    }

    /// The child ended. A success ends the flow; anything else keeps the
    /// user on the install step with the result and log.
    pub fn finish(&mut self, outcome: InstallOutcome) -> Result<(), Refusal> {
        if self.run != RunState::Running {
            return Err(Refusal::WrongState);
        }
        self.run = RunState::Finished(outcome);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn running() -> Flow {
        let mut flow = Flow::default();
        flow.begin().unwrap();
        flow.advance().unwrap();
        flow.advance().unwrap();
        flow.advance().unwrap();
        flow.start_preparing().unwrap();
        flow.start_running().unwrap();
        flow
    }

    #[test]
    fn nothing_moves_while_an_install_is_in_progress() {
        for locked in [running(), {
            let mut flow = running();
            flow.run = RunState::Preparing;
            flow
        }] {
            let mut flow = locked;
            assert!(flow.locked());
            assert!(!flow.may_edit());
            assert_eq!(flow.begin(), Err(Refusal::Locked));
            assert_eq!(flow.resume(Step::Options), Err(Refusal::Locked));
            assert_eq!(flow.attach_running(), Err(Refusal::Locked));
            assert_eq!(flow.go_to(Step::Ready), Err(Refusal::Locked));
            assert_eq!(flow.advance(), Err(Refusal::Locked));
            assert_eq!(flow.back(), Err(Refusal::Locked));
            assert_eq!(flow.cancel(), Err(Refusal::Locked));
            assert_eq!(flow.start_preparing(), Err(Refusal::Locked));
            assert_eq!(flow, locked, "a refused transition changes nothing");
        }
    }

    #[test]
    fn steps_can_be_revisited_but_not_skipped() {
        let mut flow = Flow::default();
        assert_eq!(flow.go_to(Step::Options), Err(Refusal::NotActive));
        flow.begin().unwrap();
        assert_eq!(flow.go_to(Step::Options), Err(Refusal::CannotSkipAhead));
        assert_eq!(flow.advance(), Ok(Step::Options));
        assert_eq!(flow.advance(), Ok(Step::Security));
        assert_eq!(flow.go_to(Step::Ready), Ok(()));
        assert_eq!(flow.step, Step::Ready);
        assert_eq!(flow.back(), Err(Refusal::WrongState));
        assert_eq!(flow.start_preparing(), Err(Refusal::WrongState), "only the install step installs");
    }

    #[test]
    fn a_successful_install_ends_the_flow_and_a_failure_allows_a_retry() {
        let mut flow = running();
        assert_eq!(flow.finish(InstallOutcome::Failed(1)), Ok(()));
        assert!(flow.may_edit());
        assert_eq!(flow.back(), Ok(Step::Security), "the user can go back after a failure");
        assert_eq!(flow.run, RunState::Idle, "leaving the result starts a new attempt");
        assert_eq!(flow.advance(), Ok(Step::Install));
        assert_eq!(flow.start_preparing(), Ok(()));
        assert_eq!(flow.stop_preparing(), Ok(()), "failed final checks return to idle");
        assert_eq!(flow.run, RunState::Idle);
        assert_eq!(flow.start_running(), Err(Refusal::WrongState));

        let mut flow = running();
        flow.finish(InstallOutcome::Succeeded).unwrap();
        assert_eq!(flow.back(), Err(Refusal::Complete));
        assert_eq!(flow.start_preparing(), Err(Refusal::Complete));
        assert_eq!(flow.cancel(), Ok(()));
        assert!(!flow.active);
        assert_eq!(flow.run, RunState::Idle);
    }

    #[test]
    fn finishing_requires_a_running_install() {
        let mut flow = Flow::default();
        assert_eq!(flow.finish(InstallOutcome::Succeeded), Err(Refusal::WrongState));
        flow.begin().unwrap();
        assert_eq!(flow.finish(InstallOutcome::Succeeded), Err(Refusal::WrongState));
        assert_eq!(flow.attach_running(), Ok(()));
        assert_eq!(flow.step, Step::Install);
        assert_eq!(flow.finish(InstallOutcome::Lost), Ok(()));
    }
}
