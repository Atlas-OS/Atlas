//! The Windows Security gate, through to the final reading before launch.

use std::collections::BTreeSet;

use crate::model::checks::{preflight_decision, security_verified};
use crate::model::test_harness::{
    Machine, act, all_off, fixture, marking_package, new_model, passing, read, run_model_test,
    three_off_one_unreadable, wait_for, walk_to_install,
};
use crate::model::{
    AcquireProblem, Acquisition, Origin, PlaybookSource, Preflight, ReadyHelp, ReadyStatus, RunState, Step,
};
use crate::services::atlas_state::InstallIdentity;
use crate::services::installer::{InstallOutcome, Phase};
use crate::services::playbook::Manifest;
use crate::services::preparation::{Stage, State};
use crate::services::requirements::{CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::{SecurityStatus, Switch};
use crate::services::session;
use crate::services::test_support::TempDir;

/// Every check passing, with `results` in place of the passing ones.
fn checks_with(results: Vec<CheckResult>) -> Vec<(CheckId, Option<CheckResult>)> {
    CheckId::ALL
        .iter()
        .map(|&id| {
            let result =
                results.iter().find(|result| result.id == id).cloned().unwrap_or_else(|| passing(id));
            (id, Some(result))
        })
        .collect()
}

fn result(id: CheckId, verdict: Verdict, detail: CheckDetail) -> CheckResult {
    CheckResult { id, verdict, detail }
}

fn pending_updates() -> CheckResult {
    result(
        CheckId::PendingUpdates,
        Verdict::Fail,
        CheckDetail::UpdatesPending { titles: vec!["KB5129195".into()] },
    )
}

fn pending_restart() -> CheckResult {
    result(
        CheckId::PendingReboot,
        Verdict::Fail,
        CheckDetail::RebootPending { reasons: vec!["servicing".into()] },
    )
}

/// An unpacked package, as far as Get ready is concerned.
fn package() -> PlaybookSource {
    PlaybookSource {
        dir: std::env::temp_dir(),
        manifest: Manifest::builtin(),
        origin: Origin::Unpacked,
        archive: None,
    }
}

/// Before Get ready's updates have run, waiting updates and a wanted restart
/// are its next task, not a blocker: no red bar, no "fix the items". Once
/// the updates have run they block again, and the final checks before the
/// install count them either way.
#[test]
fn updates_wait_for_the_update_step_before_they_block() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("checks-pending-updates");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            m.playbook = Some(package());
            m.preparation = State::Idle;
            m.checks = checks_with(vec![pending_updates(), pending_restart()]);
            for (_, result) in &m.checks {
                let result = result.as_ref().unwrap();
                let waiting = matches!(result.id, CheckId::PendingUpdates | CheckId::PendingReboot);
                assert_eq!(m.handled_by_preparation(result), waiting, "{:?}", result.id);
            }
            assert!(!m.checks_blocking());
            assert_eq!(m.ready_status(), Some(ReadyStatus::Updates), "Check and install updates is next");
            assert_eq!(m.ready_help(), None, "nothing went wrong");
            assert!(!m.ready_to_continue(), "Continue still waits for the updates");
            assert!(!m.step_satisfied(Step::Ready));

            // Updated, and Windows still reports them: now they're the user's to fix.
            m.preparation = State::Ready;
            assert!(!m.handled_by_preparation(&pending_updates()));
            assert!(m.checks_blocking());
            assert_eq!(m.ready_status(), Some(ReadyStatus::Blocked));
            assert_eq!(m.ready_help(), Some(ReadyHelp::Checks));
        });
        // The last decision before launch never sets them aside.
        let decision = preflight_decision(&[pending_updates()], &BTreeSet::new(), &all_off(), None, true);
        assert!(matches!(decision, Err(Preflight::Changed { ref checks, .. }) if checks.len() == 1));
    });
}

/// Get ready's status bar says one thing, the most urgent, and nothing where
/// another message already says what's next.
#[test]
fn get_ready_reports_the_most_urgent_status() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("checks-status");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            m.preparation = State::Ready;
            m.checks = checks_with(vec![]);
            m.checks[0].1 = None;
            assert_eq!(m.ready_status(), Some(ReadyStatus::Busy), "a check is still running");
            m.checks = checks_with(vec![]);
            assert_eq!(m.ready_status(), Some(ReadyStatus::NoPackage));
            m.acquisition = Acquisition::Failed(AcquireProblem::Stalled);
            assert_eq!(m.ready_help(), Some(ReadyHelp::Package));
            m.acquisition = Acquisition::Idle;
            m.playbook = Some(package());
            assert_eq!(m.ready_status(), Some(ReadyStatus::Ready));
            assert!(m.step_satisfied(Step::Ready));
            m.checks =
                checks_with(vec![result(CheckId::Activation, Verdict::Warn, CheckDetail::ActivationMissing)]);
            assert_eq!(m.ready_status(), Some(ReadyStatus::Warnings));
            assert_eq!(m.ready_help(), None, "advice is no trouble");

            // Once only updates are left, the top says how updating stands
            // and names the card and its button, far down the page.
            for (preparation, status) in [
                (State::Idle, ReadyStatus::Updates),
                (
                    State::Running { stage: Stage::StoreInstall, completed: 1, total: 2 },
                    ReadyStatus::Updating,
                ),
                (State::WaitingExternal, ReadyStatus::Updating),
                (State::Cancelled, ReadyStatus::UpdatesStopped),
                (State::Resumed, ReadyStatus::UpdatesResumed),
                (State::Reboot, ReadyStatus::UpdatesRestart),
                (State::SavingRestart, ReadyStatus::UpdatesRestart),
                (State::Restarting, ReadyStatus::UpdatesRestart),
                (State::Network, ReadyStatus::UpdatesFailed),
                (State::RestartPersists { reasons: vec![] }, ReadyStatus::UpdatesFailed),
                // A run that ended without a report isn't called a failure.
                (State::Failed, ReadyStatus::UpdatesUnconfirmed),
            ] {
                m.preparation = preparation.clone();
                assert_eq!(m.ready_status(), Some(status), "{preparation:?}");
            }
            m.preparation_error = Some("the worker failed".into());
            assert_eq!(m.ready_status(), Some(ReadyStatus::UpdatesFailed));
            m.preparation_error = None;
            assert_eq!(m.ready_help(), Some(ReadyHelp::Preparation), "a failed update run");
            m.preparation = State::RestartPersists { reasons: vec![] };
            assert_eq!(m.ready_help(), Some(ReadyHelp::Preparation));

            // A blocker outranks the updates still to do.
            m.preparation = State::Idle;
            m.checks = checks_with(vec![result(CheckId::Power, Verdict::Fail, CheckDetail::PowerBattery)]);
            assert_eq!(m.ready_status(), Some(ReadyStatus::Blocked));
            assert_eq!(m.ready_help(), Some(ReadyHelp::Checks));

            // No installation can start here: the eligibility message says why.
            m.install_identity = Err("unreadable".into());
            assert_eq!(m.ready_status(), None);
            assert_eq!(m.ready_help(), Some(ReadyHelp::Eligibility));
            // A version that can't be updated isn't a fault: reinstalling
            // Windows is the way on, not a report.
            m.install_identity = Ok(InstallIdentity::Installed("0.3.2".into()));
            assert!(matches!(m.install_block(), Some(crate::model::InstallBlock::Unsupported { .. })));
            assert_ne!(m.ready_help(), Some(ReadyHelp::Eligibility));
        });
    });
}

/// The checks keep their usual order while they run. Once all have reported,
/// what needs attention comes first, most urgent first, and the passed checks
/// are set apart.
#[test]
fn get_ready_lists_what_needs_attention_first_once_the_checks_are_done() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("checks-order");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            let position = |id: CheckId| CheckId::ALL.iter().position(|check| *check == id).unwrap();
            m.preparation = State::Idle;
            m.checks = checks_with(vec![
                pending_updates(),
                result(CheckId::Activation, Verdict::Warn, CheckDetail::ActivationMissing),
                result(CheckId::Power, Verdict::Unknown, CheckDetail::PowerUnknown),
                result(
                    CheckId::ThirdPartyAntivirus,
                    Verdict::Fail,
                    CheckDetail::AntivirusFound { products: vec![] },
                ),
            ]);
            let rows = m.check_rows();
            let listed: Vec<CheckId> = rows.listed.iter().map(|&index| m.checks[index].0).collect();
            assert_eq!(
                listed,
                [CheckId::ThirdPartyAntivirus, CheckId::Power, CheckId::Activation, CheckId::PendingUpdates],
                "blocking, couldn't be checked, advice, then what the update step takes care of"
            );
            assert_eq!(rows.passed.len(), CheckId::ALL.len() - 4);
            assert!(rows.passed.windows(2).all(|pair| pair[0] < pair[1]), "passed checks keep their order");
            assert!(!rows.passed.contains(&position(CheckId::PendingUpdates)));

            // Confirming the update scan by hand leaves its row where it was,
            // above another check that couldn't run, rather than moving it
            // from under the pointer.
            let scan_failed = result(
                CheckId::PendingUpdates,
                Verdict::Unknown,
                CheckDetail::UpdatesUnknown { error: "0x8024402c".into() },
            );
            m.checks = checks_with(vec![
                scan_failed,
                result(CheckId::Power, Verdict::Unknown, CheckDetail::PowerUnknown),
            ]);
            let order = |m: &crate::model::AppModel| {
                m.check_rows().listed.iter().map(|&index| m.checks[index].0).collect::<Vec<_>>()
            };
            assert_eq!(order(m), [CheckId::PendingUpdates, CheckId::Power]);
            m.acknowledged.insert(CheckId::PendingUpdates);
            assert_eq!(order(m), [CheckId::PendingUpdates, CheckId::Power], "a confirmed row stays put");

            // A check still running: every row in its usual place, none folded.
            m.checks[position(CheckId::Internet)].1 = None;
            let rows = m.check_rows();
            assert_eq!(rows.listed, (0..CheckId::ALL.len()).collect::<Vec<_>>());
            assert!(rows.passed.is_empty());
        });
    });
}

/// A step already passed still needs attention when what it asked for came
/// undone: Get ready while it isn't satisfied, Windows Security once a
/// reading shows a switch back on.
#[test]
fn a_step_left_behind_is_satisfied_only_while_it_holds() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("checks-step-satisfied");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            assert!(m.step_satisfied(Step::Security), "no reading yet, nothing to flag");
            m.observe_security(all_off());
            assert!(m.step_satisfied(Step::Security));
            m.observe_security(SecurityStatus { tamper_protection: Switch::On, ..all_off() });
            assert!(!m.step_satisfied(Step::Security));
            assert!(m.step_satisfied(Step::Options) && m.step_satisfied(Step::Install));
        });
    });
}

/// A confirmation belongs to the reading it was given for.
#[test]
fn security_is_verified_against_the_reading_the_user_confirmed() {
    let confirmed = three_off_one_unreadable();
    let all_unknown = SecurityStatus::default();
    let one_on = SecurityStatus { tamper_protection: Switch::On, ..confirmed };
    assert!(security_verified(&confirmed, Some(confirmed), true));
    assert!(!security_verified(&confirmed, Some(confirmed), false), "only an elevated user can confirm");
    assert!(!security_verified(&confirmed, None, true));
    assert!(!security_verified(&all_unknown, Some(confirmed), true), "a broader unknown set is not covered");
    assert!(!security_verified(&one_on, Some(one_on), true), "a readable On is never confirmable");
    assert!(security_verified(&all_off(), None, false), "all off needs no confirmation");
}

/// The final decision lets through an update scan that could not run once
/// the user has acknowledged it, and nothing else.
#[test]
fn only_an_acknowledged_update_scan_that_could_not_run_passes_the_final_checks() {
    let unknown = CheckResult {
        id: CheckId::PendingUpdates,
        verdict: Verdict::Unknown,
        detail: CheckDetail::UpdatesUnknown { error: "the scan failed".into() },
    };
    let pending = CheckResult {
        verdict: Verdict::Fail,
        detail: CheckDetail::UpdatesPending { titles: vec!["KB5129195".into()] },
        ..unknown.clone()
    };
    let acknowledged = BTreeSet::from([CheckId::PendingUpdates]);
    let decide = |result: &CheckResult, acknowledged: &BTreeSet<CheckId>| {
        preflight_decision(std::slice::from_ref(result), acknowledged, &all_off(), None, true)
    };
    assert_eq!(decide(&unknown, &acknowledged), Ok(()));
    assert_eq!(
        decide(&unknown, &BTreeSet::new()),
        Err(Preflight::Changed {
            checks: vec![(CheckId::PendingUpdates, unknown.detail.clone())],
            security: None
        })
    );
    assert!(decide(&pending, &acknowledged).is_err(), "updates that were found still block");
}

#[test]
#[cfg(windows)]
fn a_confirmation_invalidated_by_the_final_reading_does_not_start_the_install() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-stale-confirmation");
        let machine = Machine::new(three_off_one_unreadable());
        let env = machine.environment(&temp.path().join("App"));
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());

        walk_to_install(&mut cx, &model, &package).await;
        assert!(read(&cx, &model, |m| m.security.off_where_readable()));
        act(&mut cx, &model, |m, cx| m.acknowledge_security(true, cx));
        assert!(read(&cx, &model, |m| m.security_acknowledged() && m.security_ok()));
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert!(read(&cx, &model, |m| m.flow.step == Step::Install && m.can_install()));

        // Between the confirmation and the click, every switch becomes
        // unreadable. The final preflight reads that, and must not reuse a
        // confirmation given for a narrower set.
        machine.set_security(SecurityStatus::default());
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        assert!(read(&cx, &model, |m| m.flow.run == RunState::Preparing));
        wait_for(&cx, &model, "the preflight decision", |m| m.flow.run != RunState::Preparing).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Idle);
            match &m.preflight_problem {
                Some(Preflight::Changed { checks, security: Some(counts) }) => {
                    assert!(checks.is_empty(), "{checks:?}");
                    assert_eq!(counts.unknown, 4);
                }
                other => panic!("expected a security refusal, got {other:?}"),
            }
            assert!(!m.security_acknowledged(), "the confirmation does not cover the new reading");
            assert!(m.session.is_none());
        });
        assert!(!marker.exists(), "the front door must not run");
        assert!(session::load(&env.paths.session()).unwrap().is_none(), "nothing was recorded");

        // Control: the reading the user confirmed comes back, and the same
        // confirmation lets the install start; the front door really runs.
        machine.set_security(three_off_one_unreadable());
        wait_for(&cx, &model, "the confirmed reading again", |m| m.can_install()).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Finished(InstallOutcome::Succeeded));
        assert!(marker.exists());
        assert!(read(&cx, &model, |m| m.attempt.phase >= Phase::Applying));
    });
}
