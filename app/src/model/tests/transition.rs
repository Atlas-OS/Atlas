//! Moving Windows to the release a package needs: what Home offers, when Get
//! ready may start the move, the restart that finishes it and putting the
//! Windows Update settings back. The worker is a scripted adapter.

use std::sync::{Arc, Mutex};

use gpui::{AsyncApp, Entity};

use crate::model::test_harness::{
    Machine, act, all_off, model_as_started, new_model, passing, read, release, run_model_test, settle,
    wait_for, wait_until,
};
use crate::model::{
    AppModel, CloseGuard, Environment, InstallBlock, Page, ReadyStatus, RestoreStatus, Step, StopQuestion,
};
use crate::services::atlas_state::InstallIdentity;
use crate::services::preparation::{Drivers, PreparationRequest, Progress, RestartProblem, State};
use crate::services::requirements::{self, CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::settings::{self, InstallDraft};
use crate::services::system::SystemInfo;
use crate::services::test_support::{TempDir, package};
use crate::services::update_access::{Blocker, BlockerKind, UpdateAccess, parse_journal};
use crate::services::windows_release::WindowsBlock;

fn system(build: u32, release: &str, edition: &str) -> SystemInfo {
    SystemInfo {
        product_name: if edition.starts_with("Core") {
            "Windows 11 Home".into()
        } else {
            "Windows 11 Pro".into()
        },
        display_version: release.into(),
        build,
        revision: 9550,
        edition_id: edition.into(),
        installation_type: "Client".into(),
        build_lab: format!("{build}.9550.amd64fre.ge_release.260918-1415"),
    }
}

/// What the scripted machine was asked to do, in order.
type Calls = Arc<Mutex<Vec<String>>>;

struct Scene {
    _temp: TempDir,
    machine: Machine,
    env: Environment,
    calls: Calls,
    requests: Arc<Mutex<Vec<PreparationRequest>>>,
    access: Arc<Mutex<UpdateAccess>>,
    package: std::path::PathBuf,
}

/// A PC on `system` whose Windows compatibility check is the real one and
/// whose other checks pass, with a package that supports 25H2 and 26H2.
fn scene(name: &str, system: SystemInfo) -> Scene {
    let temp = TempDir::new(name);
    let root = temp.path().join("App");
    std::fs::create_dir_all(&root).unwrap();
    let machine = Machine::new(all_off());
    let mut env = machine.environment(&root);
    let calls: Calls = Arc::default();
    let requests: Arc<Mutex<Vec<PreparationRequest>>> = Arc::default();
    let access: Arc<Mutex<UpdateAccess>> = Arc::default();
    env.adapters.read_system = Arc::new(move || system.clone());
    env.adapters.run_check = Arc::new(|id, context| match id {
        CheckId::SupportedBuild => requirements::run(id, context),
        _ => passing(id),
    });
    let shared = access.clone();
    env.adapters.read_update_access = Arc::new(move || Ok(shared.lock().unwrap().clone()));
    let log = calls.clone();
    let path = env.paths.settings();
    env.adapters.register_preparation_resume = Arc::new(move || {
        let saved =
            settings::load_from(&path).settings.draft.is_some_and(|d| d.preparation_restart_at.is_some());
        log.lock().unwrap().push(if saved { "register after save" } else { "register before save" }.into());
        Ok(())
    });
    let log = calls.clone();
    env.adapters.schedule_restart = Arc::new(move |_| {
        log.lock().unwrap().push("restart".into());
        Ok(())
    });
    let log = calls.clone();
    env.adapters.run_operation = Arc::new(move |_, operation| {
        log.lock().unwrap().push(format!("{operation:?}"));
        Ok(())
    });
    let package = package::write(
        &temp.path().join("package.atlaspkg"),
        &package::valid_with_builds("0.6.0", &[26200, 26300]),
    );
    Scene { _temp: temp, machine, env, calls, requests, access, package }
}

impl Scene {
    /// The worker reports `progress` and ends in `state`.
    fn worker(&mut self, progress: serde_json::Value, state: State) {
        let requests = self.requests.clone();
        self.env.adapters.run_preparation = Arc::new(move |_, request, _, mut report| {
            requests.lock().unwrap().push(request.clone());
            report(serde_json::from_value::<Progress>(progress.clone()).unwrap());
            Ok(state.clone())
        });
    }

    fn calls(&self) -> Vec<String> {
        self.calls.lock().unwrap().clone()
    }
}

fn record(kind: &str, phase: &str) -> UpdateAccess {
    let fixtures = concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/windows-transition");
    let text = std::fs::read_to_string(format!("{fixtures}/journal-{kind}.json")).unwrap();
    let text = text.replacen("\"phase\":\"targeted\"", &format!("\"phase\":\"{phase}\""), 1).replacen(
        "\"phase\":\"lifted\"",
        &format!("\"phase\":\"{phase}\""),
        1,
    );
    UpdateAccess { journal: Some(parse_journal(&text).unwrap()), ..UpdateAccess::default() }
}

fn report(status: &str, reasons: &[&str], reason: Option<&str>) -> serde_json::Value {
    serde_json::json!({
        "schema": 1, "status": status, "stage": "windows-install", "completed": 0, "total": 0,
        "activity": { "restartReasons": reasons, "reason": reason, "failureMessage": reason.map(|_| "worker text") }
    })
}

/// Begins the flow and loads the package, then waits for every check.
async fn to_get_ready(cx: &mut AsyncApp, model: &Entity<AppModel>, package: &std::path::Path) {
    wait_for(cx, model, "startup recovery", |m| !m.recovering).await;
    act(cx, model, |m, cx| {
        m.preparation = State::Idle;
        m.begin_install(cx);
    });
    assert!(read(cx, model, |m| m.flow.active && m.flow.step == Step::Ready), "the flow begins");
    act(cx, model, |m, cx| m.load_package_file(package.to_path_buf(), cx));
    wait_for(cx, model, "the package and the checks", |m| m.package.is_some() && m.checks_complete()).await;
}

fn set_check(model: &mut AppModel, id: CheckId, verdict: Verdict, detail: CheckDetail) {
    let slot = model.checks.iter_mut().find(|(check, _)| *check == id).unwrap();
    slot.1 = Some(CheckResult { id, verdict, detail });
}

#[test]
fn home_offers_the_update_on_24h2_pro_and_says_why_not_on_home_or_23h2() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-home", system(26100, "24H2", "Professional"));
        *scene.machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        let model = new_model(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            m.release = crate::model::ReleaseCheck::Ready { release: release("0.6.0", vec![]) }
        });
        read(&cx, &model, |m| {
            assert!(m.offered_update().is_some(), "24H2 Pro is offered the update");
            assert!(m.start_block().is_none());
            assert_eq!(m.windows_transition().map(|(t, _)| t.target_release), Some("26H2"));
        });

        for (system, expected) in [
            (system(26100, "24H2", "Core"), WindowsBlock::Edition),
            (system(22631, "23H2", "Professional"), WindowsBlock::NoPath { build: 22631 }),
        ] {
            act(&mut cx, &model, |m, cx| {
                m.system = system;
                m.begin_install(cx);
            });
            read(&cx, &model, |m| {
                assert!(m.offered_update().is_none());
                assert!(!m.flow.active, "begin_install refuses");
                let block = m.start_block().unwrap();
                assert_eq!(block.windows(), Some(expected));
                if expected == WindowsBlock::Edition {
                    assert!(
                        matches!(block, InstallBlock::Windows { ending: Some(_), .. }),
                        "24H2 Home is told when its security updates end"
                    );
                }
            });
        }
        settle(&cx, &model).await;
    });
}

#[test]
fn the_move_waits_for_the_licence_terms_and_for_everything_else_that_would_stop_atlas() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-gate", system(26100, "24H2", "Professional"));
        scene.worker(report("reboot", &["feature-update"], None), State::Reboot);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        read(&cx, &model, |m| {
            let build =
                m.checks.iter().find(|(id, _)| *id == CheckId::SupportedBuild).unwrap().1.clone().unwrap();
            assert!(matches!(build.detail, CheckDetail::BuildTransition { .. }));
            assert!(m.handled_by_preparation(&build), "a note while the move is chosen");
            assert!(!m.checks_blocking());
            assert!(!m.preparation_may_start(), "the terms come first");
            assert_eq!(m.ready_status(), Some(ReadyStatus::WindowsTerms));
        });
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        assert!(
            read(&cx, &model, |m| m.preparation_job.is_none() && !m.preparation.busy()),
            "nothing runs before the terms are accepted"
        );

        act(&mut cx, &model, |m, cx| m.accept_windows_terms(true, cx));
        for (id, detail) in [
            (CheckId::Power, CheckDetail::PowerBattery),
            (CheckId::ThirdPartyAntivirus, CheckDetail::AntivirusFound { products: vec!["Contoso".into()] }),
            (CheckId::UserAccount, CheckDetail::UserAccountNotReady),
        ] {
            act(&mut cx, &model, |m, _| set_check(m, id, Verdict::Fail, detail));
            assert!(!read(&cx, &model, AppModel::preparation_may_start), "{id:?} would still stop Atlas");
            act(&mut cx, &model, |m, _| {
                *m.checks.iter_mut().find(|(c, _)| *c == id).unwrap() = (id, Some(passing(id)))
            });
        }
        act(&mut cx, &model, |m, _| {
            set_check(
                m,
                CheckId::PendingUpdates,
                Verdict::Fail,
                CheckDetail::UpdatesPending { titles: vec!["LCU".into()] },
            );
            set_check(
                m,
                CheckId::PendingReboot,
                Verdict::Fail,
                CheckDetail::RebootPending { reasons: vec!["servicing".into()] },
            );
        });
        assert!(read(&cx, &model, AppModel::preparation_may_start), "updating handles what's left");

        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to ask for a restart", |m| {
            m.preparation == State::Reboot && !m.preparation.busy()
        })
        .await;
        let request = scene.requests.lock().unwrap()[0].clone();
        let transition = request.transition.expect("the run moves Windows");
        assert_eq!(
            (transition.target_release.as_str(), transition.kbs.as_slice()),
            ("26H2", &[5_121_794, 5_129_195][..])
        );
        assert!(transition.accept_license);
        assert!(
            !scene.calls().iter().any(|call| call == "Commit" || call == "restart"),
            "detection never commits or restarts"
        );
        settle(&cx, &model).await;
    });
}

/// Where Get ready updates by itself, a move waits for the licence terms,
/// and accepting them starts it straight away. Keeping an optional
/// version needs no terms, so updating starts without the move.
#[test]
fn accepting_the_licence_terms_starts_the_move_by_itself() {
    run_model_test(|mut cx| async move {
        let mut required = scene("transition-terms-start", system(26100, "24H2", "Professional"));
        required.env.automatic_get_ready = true;
        required.worker(report("reboot", &["feature-update"], None), State::Reboot);
        let model = new_model(&mut cx, required.env.clone());
        to_get_ready(&mut cx, &model, &required.package).await;
        cx.background_executor().timer(std::time::Duration::from_millis(300)).await;
        assert!(required.requests.lock().unwrap().is_empty(), "nothing runs before the terms are accepted");
        act(&mut cx, &model, |m, cx| m.accept_windows_terms(true, cx));
        assert!(read(&cx, &model, |m| m.preparation.busy()), "the move starts as the terms are accepted");
        wait_for(&cx, &model, "the run to ask for a restart", |m| m.preparation == State::Reboot).await;
        let request = required.requests.lock().unwrap()[0].clone();
        assert!(request.transition.is_some_and(|transition| transition.accept_license));
        settle(&cx, &model).await;

        // 25H2, where moving is optional: keeping it starts plain updates.
        let mut optional = scene("transition-keep-start", system(26200, "25H2", "Professional"));
        optional.env.automatic_get_ready = true;
        optional.worker(report("complete", &[], None), State::Ready);
        let model = new_model(&mut cx, optional.env.clone());
        to_get_ready(&mut cx, &model, &optional.package).await;
        cx.background_executor().timer(std::time::Duration::from_millis(300)).await;
        assert!(optional.requests.lock().unwrap().is_empty(), "the move is chosen until the user keeps 25H2");
        act(&mut cx, &model, |m, cx| m.keep_windows_version(true, cx));
        wait_for(&cx, &model, "updates without the move", |m| m.preparation.ready()).await;
        assert!(optional.requests.lock().unwrap()[0].transition.is_none());
        settle(&cx, &model).await;
    });
}

#[test]
fn restart_and_continue_saves_registers_commits_and_only_then_restarts() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-commit", system(26100, "24H2", "Professional"));
        scene.worker(report("reboot", &["feature-update"], None), State::Reboot);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| {
            m.accept_windows_terms(true, cx);
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the restart to be owed", |m| m.preparation == State::Reboot).await;
        scene.calls.lock().unwrap().clear();
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        wait_for(&cx, &model, "the restart", |m| m.preparation == State::Restarting).await;
        assert_eq!(scene.calls(), ["register after save", "Commit", "restart"]);

        // A commit that fails leaves Windows running and says so.
        scene.calls.lock().unwrap().clear();
        let log = scene.calls.clone();
        act(&mut cx, &model, |m, _| {
            m.preparation = State::Reboot;
            m.env.adapters.run_operation = Arc::new(move |_, operation| {
                log.lock().unwrap().push(format!("{operation:?}"));
                anyhow::bail!("Commit returned 0x80240016")
            });
        });
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        wait_for(&cx, &model, "the commit problem", |m| {
            m.preparation_problem == Some(RestartProblem::Commit)
        })
        .await;
        assert_eq!(scene.calls(), ["register after save", "Commit"]);
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
        settle(&cx, &model).await;
    });
}

/// Reopened before the restart, the window has only the record to go on: a
/// version change it says is installed still gets Atlas's commit first.
#[test]
fn reopened_before_the_restart_the_version_change_is_still_committed() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-commit-reopened", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "installed");
        let (dir, _) =
            crate::services::package::extract_into(&scene.package, &scene.env.paths.packages(), |_, _| {})
                .unwrap();
        crate::model::test_harness::save_draft(
            &scene.env,
            InstallDraft {
                step: "ready".into(),
                package_dir: Some(dir),
                preparation_restart_at: Some(chrono::Utc::now().to_rfc3339()),
                windows_terms_accepted: true,
                flow: Some("earlier-window".into()),
                ..InstallDraft::default()
            },
        );
        let model = model_as_started(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "the reopened flow and its checks", |m| m.flow.active && m.checks_complete())
            .await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Reboot, "the restart is still owed");
            assert!(m.preparation_progress.is_none(), "no run in this window");
        });
        scene.calls.lock().unwrap().clear();
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        wait_for(&cx, &model, "the restart", |m| m.preparation == State::Restarting).await;
        assert_eq!(scene.calls(), ["register after save", "Commit", "restart"]);
        settle(&cx, &model).await;
    });
}

#[test]
fn after_the_restart_the_flow_resumes_on_26h2_and_is_ready_to_continue() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-resume", system(26300, "26H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "installed");
        scene.worker(report("complete", &[], None), State::Ready);
        let (dir, _) =
            crate::services::package::extract_into(&scene.package, &scene.env.paths.packages(), |_, _| {})
                .unwrap();
        crate::model::test_harness::save_draft(
            &scene.env,
            InstallDraft {
                step: "ready".into(),
                package_dir: Some(dir),
                preparation_restart_at: Some("2001-01-01T00:00:00Z".into()),
                windows_terms_accepted: true,
                flow: Some("earlier-window".into()),
                ..InstallDraft::default()
            },
        );
        let model = model_as_started(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "the resumed flow and its checks", |m| m.flow.active && m.checks_complete())
            .await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Resumed);
            assert!(m.windows_terms_accepted, "the draft keeps the accepted terms");
            assert!(m.preparation_may_start());
            assert!(m.transition_request().is_some(), "the open record continues the move on 26H2");
        });
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to finish", |m| m.preparation.ready()).await;
        assert!(read(&cx, &model, AppModel::ready_to_continue));
        assert!(scene.requests.lock().unwrap()[0].transition.is_some());
        settle(&cx, &model).await;
    });
}

#[test]
fn on_24h2_the_install_never_continues_even_with_updates_marked_done() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-never-ready", system(26100, "24H2", "Professional"));
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| {
            m.accept_windows_terms(true, cx);
            m.preparation = State::Ready;
        });
        read(&cx, &model, |m| {
            assert!(m.checks_blocking(), "Windows compatibility blocks once updating is done");
            assert!(!m.ready_to_continue());
        });
        settle(&cx, &model).await;
    });
}

#[test]
fn a_scan_windows_update_refused_is_left_to_updating_when_atlas_can_turn_it_on() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-blocked-scan", system(26300, "26H2", "Professional"));
        scene.access.lock().unwrap().blockers = vec![Blocker { kind: BlockerKind::Off, owned: true }];
        scene.worker(report("complete", &[], None), State::Ready);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, _| {
            set_check(
                m,
                CheckId::PendingUpdates,
                Verdict::Unknown,
                CheckDetail::UpdatesUnknown { error: "0x8024002E".into() },
            )
        });
        read(&cx, &model, |m| {
            assert!(!m.checks_blocking(), "updating turns Windows Update on");
            assert!(m.preparation_may_start());
        });
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run", |m| m.preparation.ready()).await;
        let request = scene.requests.lock().unwrap()[0].clone();
        assert!(request.open_update_access && request.transition.is_none());
        // Without a blocker the same unknown scan needs the user's confirmation.
        scene.access.lock().unwrap().blockers.clear();
        wait_for(&cx, &model, "the checks after the run", AppModel::checks_complete).await;
        act(&mut cx, &model, |m, _| {
            m.preparation = State::Idle;
            m.refresh_update_access();
            set_check(
                m,
                CheckId::PendingUpdates,
                Verdict::Unknown,
                CheckDetail::UpdatesUnknown { error: "0x8024002E".into() },
            );
        });
        assert!(read(&cx, &model, AppModel::checks_blocking));
        settle(&cx, &model).await;
    });
}

/// Windows can still be finishing its servicing just after a restart, so the
/// checks may find a restart owed that clears by itself soon after. It never
/// stops the updates from starting, and the checks read it again when the run
/// ends, so it doesn't stay on screen once Windows has cleared it.
#[test]
fn a_restart_windows_stops_wanting_while_updating_is_gone_when_the_run_ends() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-restart-clears", system(26100, "24H2", "Professional"));
        let pending = Arc::new(Mutex::new(true));
        let owed = pending.clone();
        scene.env.adapters.run_check = Arc::new(move |id, context| match id {
            CheckId::SupportedBuild => requirements::run(id, context),
            CheckId::PendingReboot if *owed.lock().unwrap() => CheckResult {
                id,
                verdict: Verdict::Fail,
                detail: CheckDetail::RebootPending { reasons: vec!["servicing".into()] },
            },
            _ => passing(id),
        });
        // Servicing finishes while the worker looks for the offer.
        let requests = scene.requests.clone();
        let owed = pending.clone();
        scene.env.adapters.run_preparation = Arc::new(move |_, request, _, mut progress| {
            requests.lock().unwrap().push(request.clone());
            *owed.lock().unwrap() = false;
            progress(serde_json::from_value(report("failed", &[], Some("feature-not-offered"))).unwrap());
            Ok(State::Failed)
        });
        let restart = |m: &AppModel| m.checks.iter().find(|(id, _)| *id == CheckId::PendingReboot)?.1.clone();
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.accept_windows_terms(true, cx));
        read(&cx, &model, |m| {
            let owed = restart(m).unwrap();
            assert_eq!(owed.verdict, Verdict::Fail);
            assert!(m.handled_by_preparation(&owed), "a note until updating has run");
            assert!(!m.checks_blocking());
            assert!(m.preparation_may_start());
        });
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the checks read again after the run", |m| {
            m.preparation == State::Failed && restart(m).is_some_and(|result| result.verdict == Verdict::Pass)
        })
        .await;
        assert_eq!(scene.requests.lock().unwrap().len(), 1);
        assert!(!read(&cx, &model, AppModel::checks_blocking));
        settle(&cx, &model).await;
    });
}

#[test]
fn stopping_before_the_move_puts_the_settings_back_once_and_never_during_an_unfinished_install() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-stop", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "targeted");
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        assert_eq!(
            read(&cx, &model, AppModel::stop_question),
            Some(StopQuestion::BeforeMove { current: "24H2".into() })
        );
        // Cancel asks from the later steps too, until the install starts.
        for step in [Step::Options, Step::Security, Step::Install] {
            act(&mut cx, &model, |m, _| m.flow.step = step);
            assert_eq!(
                read(&cx, &model, AppModel::stop_question),
                Some(StopQuestion::BeforeMove { current: "24H2".into() }),
                "{step:?}"
            );
        }
        act(&mut cx, &model, |m, _| m.flow.step = Step::Ready);
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::WindowsUpdateAccess);
        act(&mut cx, &model, |m, cx| m.stop_updating(cx));
        wait_for(&cx, &model, "the flow to end", |m| !m.flow.active).await;
        assert_eq!(scene.calls(), ["Restore"]);
        assert_eq!(read(&cx, &model, |m| m.page), Page::Home);

        // An unfinished Atlas install puts them back itself. The record is
        // still open here, so only the install keeps Put back from running.
        assert!(read(&cx, &model, AppModel::may_restore_update_access), "the record is still open");
        *scene.machine.identity.lock().unwrap() =
            Some(InstallIdentity::Resume("0.6.0".into(), Default::default()));
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        assert!(!read(&cx, &model, AppModel::may_restore_update_access));
        act(&mut cx, &model, |m, cx| m.restore_update_access(cx));
        assert_eq!(
            read(&cx, &model, |m| m.restore_status.clone()),
            RestoreStatus::Idle,
            "nothing is put back"
        );
        settle(&cx, &model).await;
    });
}

/// While a move is under way its record decides what runs next, and an owed
/// restart must not be forgotten: the licence terms can't be withdrawn and
/// the drivers choice can't change, since either would start updating over.
/// A new flow continuing the move can still accept the terms.
#[test]
fn an_open_move_or_an_owed_restart_keeps_the_terms_and_the_drivers_choice() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-fixed-choices", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "targeted");
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        let not_offered: Progress =
            serde_json::from_value(report("failed", &[], Some("feature-not-offered"))).unwrap();
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Failed;
            m.preparation_progress = Some(not_offered.clone());
            m.accept_windows_terms(true, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_terms_accepted, "a new flow continuing the move accepts them");
            assert_eq!(m.preparation, State::Failed, "accepting doesn't start over");
        });
        let drivers = read(&cx, &model, AppModel::driver_preference);
        let other = match drivers {
            Drivers::Automatic => Drivers::Manual,
            Drivers::Manual => Drivers::Automatic,
        };
        act(&mut cx, &model, |m, cx| {
            m.accept_windows_terms(false, cx);
            m.set_drivers(other, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_terms_accepted);
            assert_eq!(m.driver_preference(), drivers);
            assert_eq!(m.preparation, State::Failed);
        });

        // Without a record, an owed restart holds them just the same.
        *scene.access.lock().unwrap() = UpdateAccess::default();
        act(&mut cx, &model, |m, cx| {
            m.refresh_update_access();
            m.preparation = State::Reboot;
            m.accept_windows_terms(false, cx);
            m.set_drivers(other, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_terms_accepted);
            assert_eq!(m.preparation, State::Reboot);
            assert_eq!(m.driver_preference(), drivers);
        });
        settle(&cx, &model).await;
    });
}

#[test]
fn closing_puts_settings_back_only_before_the_package_is_installed() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-close", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "lifted");
        let model = new_model(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::WindowsUpdateAccess);
        act(&mut cx, &model, |m, _| m.preparation = State::Reboot);
        assert_eq!(
            read(&cx, &model, AppModel::close_guard),
            CloseGuard::None,
            "a restart is owed and recovery is armed"
        );
        act(&mut cx, &model, |m, _| m.preparation = State::Resumed);
        assert_eq!(
            read(&cx, &model, AppModel::close_guard),
            CloseGuard::WindowsUpdateAccess,
            "reopened after the restart, nothing would bring the user back"
        );
        act(&mut cx, &model, |m, _| m.preparation = State::Idle);
        *scene.access.lock().unwrap() = record("transition", "installed");
        act(&mut cx, &model, |m, _| m.refresh_update_access());
        assert_eq!(
            read(&cx, &model, AppModel::close_guard),
            CloseGuard::None,
            "only the restart is owed now"
        );
        // Closing after the put-back closes; one that fails keeps the window.
        *scene.access.lock().unwrap() = record("transition", "lifted");
        let closed = Arc::new(Mutex::new(false));
        let flag = closed.clone();
        act(&mut cx, &model, |m, cx| {
            m.refresh_update_access();
            m.restore_before_closing(move |_, done, _| *flag.lock().unwrap() = done, cx);
        });
        wait_until(&cx, "the window to close", || *closed.lock().unwrap()).await;
        let log = scene.calls.clone();
        let closed = Arc::new(Mutex::new(false));
        let flag = closed.clone();
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.run_operation = Arc::new(move |_, op| {
                log.lock().unwrap().push(format!("{op:?}"));
                anyhow::bail!("feature-install-active: An Atlas install is unfinished")
            });
            m.restore_before_closing(move |_, done, _| *flag.lock().unwrap() = done, cx);
        });
        wait_for(&cx, &model, "the put-back to fail", |m| {
            matches!(m.restore_status, RestoreStatus::Failed(_))
        })
        .await;
        assert!(!*closed.lock().unwrap());
        assert_eq!(scene.calls(), ["Restore", "Restore"]);
        settle(&cx, &model).await;
    });
}

#[test]
fn put_back_from_home_runs_elevated_or_relaunches_for_it() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-home-put-back", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("access", "lifted");
        let relaunched = Arc::new(Mutex::new(0));
        let count = relaunched.clone();
        scene.env.adapters.relaunch_elevated = Arc::new(move || {
            *count.lock().unwrap() += 1;
            anyhow::bail!("declined")
        });
        let model = new_model(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        assert!(
            read(&cx, &model, |m| m.update_access.as_ref().is_some_and(UpdateAccess::open) && !m.flow.active)
        );
        act(&mut cx, &model, |m, cx| m.restore_update_access(cx));
        wait_for(&cx, &model, "the put-back", |m| m.restore_status == RestoreStatus::Idle).await;
        assert_eq!(scene.calls(), ["Restore"]);
        // A second press before the prompt shows starts no second prompt.
        act(&mut cx, &model, |m, cx| {
            m.elevated = false;
            m.restore_update_access(cx);
            m.restore_update_access(cx);
        });
        assert!(
            read(&cx, &model, |m| m.elevating && !m.may_restore_update_access()),
            "Put back waits for the prompt"
        );
        wait_for(&cx, &model, "the prompt to be declined", |m| !m.elevating).await;
        assert_eq!(*relaunched.lock().unwrap(), 1, "one prompt");
        assert!(read(&cx, &model, AppModel::may_restore_update_access), "declined, it's offered again");
        assert_eq!(scene.calls(), ["Restore"], "nothing runs without administrator rights");
        settle(&cx, &model).await;
    });
}

#[test]
fn the_version_choice_and_terms_are_kept_reset_preparation_and_wait_while_anything_runs() {
    run_model_test(|mut cx| async move {
        let scene = scene("transition-choice", system(26200, "25H2", "Professional"));
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        read(&cx, &model, |m| {
            assert!(m.transition_chosen(), "the move is recommended and preselected on 25H2");
            assert!(!m.preparation_may_start(), "and needs the terms");
        });
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Ready;
            m.keep_windows_version(true, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_transition_declined);
            assert_eq!(m.preparation, State::Idle, "updating starts over for the new choice");
            assert!(m.transition_request().is_none());
            assert!(m.preparation_may_start(), "keeping 25H2 needs no terms");
        });
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Running { stage: Default::default(), completed: 0, total: 0 };
            m.keep_windows_version(false, cx);
            m.accept_windows_terms(true, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_transition_declined && !m.windows_terms_accepted, "refused while running")
        });
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Idle;
            m.accept_windows_terms(true, cx);
        });
        crate::model::test_harness::wait_on_disk(&cx, &scene.env, "the choice and terms in the draft", |s| {
            s.draft.as_ref().is_some_and(|d| d.windows_transition_declined && d.windows_terms_accepted)
        })
        .await;
        // An open move can't be declined: stopping it decides that.
        *scene.access.lock().unwrap() = record("transition", "targeted");
        act(&mut cx, &model, |m, cx| {
            m.refresh_update_access();
            m.windows_transition_declined = false;
            m.keep_windows_version(true, cx);
        });
        assert!(!read(&cx, &model, |m| m.windows_transition_declined));
        // Drafts written before these fields still load.
        let old: InstallDraft = serde_json::from_str(r#"{"step":"ready","options":[]}"#).unwrap();
        assert!(!old.windows_terms_accepted && !old.windows_transition_declined);
        settle(&cx, &model).await;
    });
}

/// A move whose run failed before any record was made, as when an
/// organisation manages updates: keeping the version forgets that failure
/// with the run, so Get ready offers to start updating again.
#[test]
fn a_new_version_choice_forgets_the_failure_of_the_last_run() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-choice-failure", system(26200, "25H2", "Professional"));
        scene.worker(report("failed", &[], Some("feature-managed")), State::Failed);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| {
            m.accept_windows_terms(true, cx);
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the move to fail and the checks after it", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        read(&cx, &model, |m| {
            assert!(!m.transition_open(), "no record was made");
            assert!(m.preparation_progress.as_ref().is_some_and(|p| p.failure().is_some()));
        });
        // The scripted run fails without an error of its own, so one is planted.
        let plant_error = |m: &mut AppModel| {
            m.preparation_error = Some("worker text".into());
            m.preparation_source_linked = true;
        };
        let forgotten = |m: &AppModel| {
            m.preparation_progress.is_none() && m.preparation_error.is_none() && !m.preparation_source_linked
        };
        act(&mut cx, &model, |m, cx| {
            plant_error(m);
            m.keep_windows_version(true, cx);
        });
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Idle);
            assert!(forgotten(m), "the failure goes too");
            assert!(m.preparation_may_start(), "keeping 25H2 can start updating");
        });
        // A new driver policy forgets a failure the same way.
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to fail again and the checks after it", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        let other = match read(&cx, &model, AppModel::driver_preference) {
            Drivers::Automatic => Drivers::Manual,
            Drivers::Manual => Drivers::Automatic,
        };
        act(&mut cx, &model, |m, cx| {
            plant_error(m);
            m.set_drivers(other, cx);
        });
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Idle);
            assert!(forgotten(m), "the failure goes too");
        });
        settle(&cx, &model).await;
    });
}

/// A restart owed, or one just made, outlasts a new version choice: the
/// draft still says so, and the run after it still knows it follows a
/// restart, so a marker that survives restarts is named, not restarted for.
#[test]
fn a_new_version_choice_keeps_a_restart_owed_or_just_made() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-choice-restart", system(26200, "25H2", "Professional"));
        // Windows asks for a restart again without updating anything.
        scene.worker(report("reboot", &["windows-update"], None), State::Reboot);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.accept_windows_terms(true, cx));
        for state in [State::Reboot, State::Resumed] {
            act(&mut cx, &model, |m, cx| {
                m.preparation = state.clone();
                m.preparation_restart_at = Some("2026-10-01T09:00:00Z".into());
                let keep = !m.windows_transition_declined;
                m.keep_windows_version(keep, cx);
            });
            assert_eq!(read(&cx, &model, |m| m.preparation.clone()), state, "the new choice keeps it");
        }
        crate::model::test_harness::wait_on_disk(&cx, &scene.env, "the owed restart and the choice", |s| {
            s.draft
                .as_ref()
                .is_some_and(|d| d.preparation_restart_at.is_some() && !d.windows_transition_declined)
        })
        .await;
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run", |m| !m.preparation.busy() && m.preparation != State::Resumed).await;
        assert_eq!(
            read(&cx, &model, |m| m.preparation.clone()),
            State::RestartPersists { reasons: vec!["windows-update".into()] }
        );
        settle(&cx, &model).await;
    });
}

#[test]
fn a_marker_that_survives_a_restart_is_still_named_after_a_version_change_restart() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-persists", system(26300, "26H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "installed");
        scene.worker(report("reboot", &["windows-update"], None), State::Reboot);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Resumed;
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the run", |m| !m.preparation.busy() && m.preparation != State::Resumed).await;
        assert_eq!(
            read(&cx, &model, |m| m.preparation.clone()),
            State::RestartPersists { reasons: vec!["windows-update".into()] }
        );
        settle(&cx, &model).await;
    });
}

#[test]
fn a_report_about_a_move_that_stopped_starts_with_its_cause_and_state() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-report", system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "targeted");
        scene.worker(report("failed", &[], Some("feature-not-offered")), State::Failed);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        assert!(read(&cx, &model, AppModel::report_context).is_none(), "nothing to report yet");
        act(&mut cx, &model, |m, cx| {
            m.accept_windows_terms(true, cx);
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the run to fail", |m| m.preparation == State::Failed).await;
        let context = read(&cx, &model, AppModel::report_context).unwrap();
        for expected in [
            "Reason: feature-not-offered",
            "Windows: 26100.9550 24H2 Professional",
            "Target: 26H2 (26300, KB5121794, KB5129195)",
            "Transition, Targeted",
        ] {
            assert!(context.contains(expected), "{expected} in {context}");
        }
        settle(&cx, &model).await;
    });
}

/// From the worker's installed phase on, Windows has the new version, or only
/// waits for the restart that switches it on.
#[test]
fn a_move_counts_as_installed_from_the_installed_phase_on() {
    for (phase, installed) in
        [("lifted", false), ("targeted", false), ("installed", true), ("on-target", true)]
    {
        let access = record("transition", phase);
        assert_eq!(access.transition().map(|journal| journal.installed()), Some(installed), "{phase}");
    }
}

/// On the target already, no move is left to choose, yet the record still
/// names one: Home's plan and Get ready's next run both read it from there.
#[test]
fn home_and_get_ready_agree_on_a_move_already_on_its_target() {
    run_model_test(|mut cx| async move {
        use crate::services::preparation::TransitionRequest;
        use crate::services::windows_release;
        let scene = scene("transition-on-target", system(26300, "26H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "on-target");
        let model = new_model(&mut cx, scene.env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let to_26h2 = windows_release::transition_to("26H2");
        assert!(to_26h2.is_some());
        read(&cx, &model, |m| {
            assert!(!m.flow.active);
            assert_eq!(m.recorded_transition(), to_26h2);
            assert!(m.windows_transition().is_none(), "nothing left to choose on 26H2");
            assert_eq!(
                m.transition_request(),
                to_26h2.map(|transition| TransitionRequest::new(transition, m.windows_terms_accepted))
            );
        });
        settle(&cx, &model).await;
    });
}

/// Too little free space for the move, as the worker refuses it.
fn space_low() -> CheckDetail {
    CheckDetail::SpaceLow { drive: "C:".into(), free_gb: 3, needed_gb: 6, release: "26H2".into() }
}

/// What a move needs is checked as Get ready opens, where a move applies.
/// It counts only while the move is chosen, and an optional move this PC
/// can't make is kept without asking.
#[test]
fn what_a_move_needs_is_checked_first_and_counts_only_while_the_move_is_chosen() {
    run_model_test(|mut cx| async move {
        // 24H2, where the move is required, with too little free space.
        let mut required = scene("transition-move-checks", system(26100, "24H2", "Professional"));
        required.env.adapters.run_check = Arc::new(|id, context| match id {
            CheckId::SupportedBuild => requirements::run(id, context),
            CheckId::MoveSpace => CheckResult { id, verdict: Verdict::Fail, detail: space_low() },
            _ => passing(id),
        });
        let model = new_model(&mut cx, required.env.clone());
        to_get_ready(&mut cx, &model, &required.package).await;
        read(&cx, &model, |m| {
            assert!(CheckId::MOVE.iter().all(|id| m.checks.iter().any(|(check, _)| check == id)));
            assert!(m.checks_blocking(), "too little space stops the move before it starts");
            assert_eq!(m.ready_status(), Some(ReadyStatus::Blocked));
            assert!(!m.preparation_may_start());
            assert!(
                m.windows_card_shown() && m.move_shows_preparation(),
                "the move's card says how it stands"
            );
        });
        settle(&cx, &model).await;

        // 25H2, where moving is optional, on hardware below Windows 11's.
        let mut optional = scene("transition-move-ruled-out", system(26200, "25H2", "Professional"));
        optional.env.adapters.run_check = Arc::new(|id, context| match id {
            CheckId::SupportedBuild => requirements::run(id, context),
            CheckId::MoveHardware => CheckResult {
                id,
                verdict: Verdict::Fail,
                detail: CheckDetail::HardwareMissing { missing: vec!["tpm".into()], release: "26H2".into() },
            },
            _ => passing(id),
        });
        let model = new_model(&mut cx, optional.env.clone());
        to_get_ready(&mut cx, &model, &optional.package).await;
        read(&cx, &model, |m| {
            assert!(m.move_ruled_out());
            assert!(!m.transition_chosen(), "Atlas keeps 25H2 without asking");
            assert!(!m.windows_card_shown() && !m.move_shows_preparation());
            assert!(!m.checks_blocking(), "what the move needs counts only for the move");
            let rows = m.check_rows();
            assert!(rows.listed.iter().chain(&rows.passed).all(|index| !m.checks[*index].0.for_move()));
            assert_eq!(m.ready_status(), Some(ReadyStatus::Updates));
            assert!(m.preparation_may_start(), "updating goes on without the move");
        });
        settle(&cx, &model).await;

        // 26H2, where no move applies, checks none of it.
        let none = scene("transition-move-none", system(26300, "26H2", "Professional"));
        let model = new_model(&mut cx, none.env.clone());
        to_get_ready(&mut cx, &model, &none.package).await;
        read(&cx, &model, |m| {
            assert!(m.checks.iter().all(|(id, _)| !id.for_move()));
            assert!(!m.windows_card_shown());
        });
        settle(&cx, &model).await;
    });
}

/// A move short of space reads the free space again by itself, and once
/// there's room it carries on without a click: one not started yet starts,
/// and one the worker stopped for space starts over.
#[test]
fn a_move_short_of_space_carries_on_by_itself_once_there_is_room() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-space-watch", system(26100, "24H2", "Professional"));
        scene.env.automatic_get_ready = true;
        scene.env.offer_recheck.space = std::time::Duration::from_millis(40);
        // Room at first; once the first run has started, too little, until
        // the test makes room again.
        let room = Arc::new(Mutex::new(true));
        let space = room.clone();
        let requests = scene.requests.clone();
        scene.env.adapters.run_check = Arc::new(move |id, context| match id {
            CheckId::SupportedBuild => requirements::run(id, context),
            CheckId::MoveSpace if !*space.lock().unwrap() => {
                CheckResult { id, verdict: Verdict::Fail, detail: space_low() }
            }
            _ => passing(id),
        });
        let short = room.clone();
        scene.env.adapters.run_preparation = Arc::new(move |_, request, _, mut send| {
            let mut seen = requests.lock().unwrap();
            seen.push(request.clone());
            let (progress, state) = if seen.len() == 1 {
                *short.lock().unwrap() = false;
                (report("failed", &[], Some("feature-disk-space")), State::Failed)
            } else {
                (report("reboot", &["feature-update"], None), State::Reboot)
            };
            send(serde_json::from_value::<Progress>(progress).unwrap());
            Ok(state)
        });
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
        wait_for(&cx, &model, "the worker to stop for space, and the checks after", |m| {
            m.preparation == State::Failed && m.checks_complete() && m.checks_blocking()
        })
        .await;
        cx.background_executor().timer(std::time::Duration::from_millis(200)).await;
        assert_eq!(scene.requests.lock().unwrap().len(), 1, "no new run without the room");
        assert!(read(&cx, &model, |m| m.move_shows_preparation()), "the outcome is the move's");
        assert!(
            read(&cx, &model, |m| m.move_outcome_held_by_check()),
            "the free space check says it, so the move's card doesn't say it again"
        );
        *room.lock().unwrap() = true;
        wait_for(&cx, &model, "the move to start over by itself", |m| m.preparation == State::Reboot).await;
        assert_eq!(scene.requests.lock().unwrap().len(), 2);
        settle(&cx, &model).await;
    });
}

/// A move Windows Update refused for the hardware says so once: as the
/// failed check, with its fix, once the checks after the run find it too,
/// and as the move's own outcome only where Atlas couldn't read it.
#[test]
fn a_move_outcome_a_check_reports_too_is_said_once_by_the_check() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-held-by-check", system(26100, "24H2", "Professional"));
        let refused = serde_json::json!({
            "schema": 1, "status": "failed", "stage": "windows-search", "completed": 0, "total": 0,
            "activity": { "reason": "feature-hardware", "hardware": "tpm", "failureMessage": "worker text" }
        });
        scene.worker(refused, State::Failed);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
        wait_for(&cx, &model, "the move to stop for the hardware, and the checks after", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        read(&cx, &model, |m| {
            assert!(!m.move_outcome_held_by_check(), "the check passed: the outcome is the only place");
            assert!(m.move_shows_preparation());
        });
        let missing = CheckDetail::HardwareMissing { missing: vec!["tpm".into()], release: "26H2".into() };
        act(&mut cx, &model, |m, _| set_check(m, CheckId::MoveHardware, Verdict::Fail, missing.clone()));
        read(&cx, &model, |m| {
            assert!(m.move_outcome_held_by_check(), "the check says it now");
            assert!(m.checks_blocking());
        });
        // Another cause is the move's own to say.
        act(&mut cx, &model, |m, _| {
            if let Some(progress) = m.preparation_progress.as_mut() {
                progress.activity.reason = Some("feature-rolled-back".into());
            }
        });
        assert!(!read(&cx, &model, |m| m.move_outcome_held_by_check()));
        settle(&cx, &model).await;
    });
}

/// Accept and update is the go-ahead and the start in one: it starts the
/// move at once, also where Get ready doesn't start updating by itself, and
/// after the user stopped updating.
#[test]
fn accept_and_update_starts_the_move_even_after_a_stop() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-accept-update", system(26100, "24H2", "Professional"));
        scene.worker(report("reboot", &["feature-update"], None), State::Reboot);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| {
            m.updates_held = true;
            m.accept_and_update(cx);
        });
        read(&cx, &model, |m| {
            assert!(m.windows_terms_accepted && !m.updates_held());
            assert!(m.preparation.busy(), "the move starts as the terms are accepted");
        });
        wait_for(&cx, &model, "the run to ask for a restart", |m| m.preparation == State::Reboot).await;
        let request = scene.requests.lock().unwrap()[0].clone();
        assert!(request.transition.is_some_and(|transition| transition.accept_license));
        read(&cx, &model, |m| assert!(m.move_shows_preparation(), "the restart that finishes the move"));
        settle(&cx, &model).await;
    });
}

/// Updates that still failed on the component store after Atlas's repair
/// restart and carry on after the restart, as any restart updating asks for.
#[test]
fn restart_and_try_again_saves_the_flow_registers_and_restarts() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-components-restart", system(26300, "26H2", "Professional"));
        scene.worker(
            serde_json::json!({
                "schema": 1, "status": "failed", "stage": "windows-install", "completed": 0, "total": 0,
                "activity": { "errorCode": "0x80073712", "failureMessage": "worker text" }
            }),
            State::Failed,
        );
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to fail on the component store", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        act(&mut cx, &model, |m, cx| m.restart_to_retry(cx));
        wait_until(&cx, "the restart", || scene.calls().iter().any(|call| call == "restart")).await;
        assert_eq!(scene.calls(), ["register after save", "restart"], "nothing to commit, then the restart");
        crate::model::test_harness::wait_on_disk(&cx, &scene.env, "the restart in the draft", |s| {
            s.draft.as_ref().is_some_and(|d| d.preparation_restart_at.is_some())
        })
        .await;
        settle(&cx, &model).await;
    });
}

/// With other people signed in, Restart and try again asks first. Kept
/// running for them, Get ready still shows the failure it offered to fix,
/// with nothing saved for a restart; confirmed, it saves, registers and
/// restarts.
#[test]
fn restart_and_try_again_declined_for_other_people_keeps_the_failure() {
    run_model_test(|mut cx| async move {
        let mut scene = scene("transition-components-others", system(26300, "26H2", "Professional"));
        scene.worker(
            serde_json::json!({
                "schema": 1, "status": "failed", "stage": "windows-install", "completed": 0, "total": 0,
                "activity": { "errorCode": "0x80073712", "failureMessage": "worker text" }
            }),
            State::Failed,
        );
        *scene.machine.others.lock().unwrap() = Some(vec!["Alex".into()]);
        let model = new_model(&mut cx, scene.env.clone());
        to_get_ready(&mut cx, &model, &scene.package).await;
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to fail on the component store", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        act(&mut cx, &model, |m, cx| m.restart_to_retry(cx));
        read(&cx, &model, |m| {
            assert!(m.restart_confirmation().is_some(), "it asks first");
            assert_eq!(m.preparation, State::Failed, "the failure shows while it asks");
        });
        act(&mut cx, &model, |m, cx| m.decline_restart_confirmation(cx));
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Failed, "the failure and its fix stay");
            assert!(m.preparation_restart_at.is_none(), "nothing is saved for a restart");
        });
        assert!(scene.calls().is_empty(), "nothing registered or restarted");

        act(&mut cx, &model, |m, cx| m.restart_to_retry(cx));
        act(&mut cx, &model, |m, cx| m.confirm_restart(cx));
        wait_until(&cx, "the restart", || scene.calls().iter().any(|call| call == "restart")).await;
        assert_eq!(scene.calls(), ["register after save", "restart"]);
        settle(&cx, &model).await;
    });
}

/// While Get ready waits for Windows Update to offer the new version, it
/// looks again by itself (offer only), continues when the offer comes, and
/// stops when the flow stops. A wait that runs out puts the settings back.
mod offer_wait {
    use super::*;
    use crate::environment::OfferRecheckTiming;
    use std::time::Duration;

    /// A worker that finds no offer for its first `misses` runs, then installs it.
    fn offering_after(scene: &mut Scene, misses: usize) {
        let requests = scene.requests.clone();
        scene.env.adapters.run_preparation = Arc::new(move |_, request, _, mut report| {
            let mut seen = requests.lock().unwrap();
            seen.push(request.clone());
            if seen.len() <= misses {
                report(
                    serde_json::from_value::<Progress>(super::report(
                        "failed",
                        &[],
                        Some("feature-not-offered"),
                    ))
                    .unwrap(),
                );
                Ok(State::Failed)
            } else {
                report(
                    serde_json::from_value::<Progress>(super::report("reboot", &["feature-update"], None))
                        .unwrap(),
                );
                Ok(State::Reboot)
            }
        });
    }

    fn scene_waiting(name: &str, interval_ms: u64, window_ms: u64) -> Scene {
        let mut scene = scene(name, system(26100, "24H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "targeted");
        scene.env.offer_recheck = OfferRecheckTiming {
            interval: Duration::from_millis(interval_ms),
            window: Duration::from_millis(window_ms),
            tick: Duration::from_millis(10),
            ..OfferRecheckTiming::default()
        };
        scene
    }

    #[test]
    fn it_looks_again_by_itself_and_continues_when_the_offer_comes() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-found", 60, 10_000);
            offering_after(&mut scene, 2);
            let model = new_model(&mut cx, scene.env.clone());
            // Each time the user's attention is asked for.
            let attention = Arc::new(Mutex::new(0));
            let count = attention.clone();
            let _subscription = cx.update(|app| {
                app.subscribe(&model, move |_, event: &crate::model::ModelEvent, _| {
                    if matches!(event, crate::model::ModelEvent::NeedsAttention) {
                        *count.lock().unwrap() += 1;
                    }
                })
            });
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| {
                m.accept_windows_terms(true, cx);
                m.prepare_windows(cx);
            });
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            assert_eq!(*attention.lock().unwrap(), 0, "finding nothing asks nothing of the user");
            wait_for(&cx, &model, "the offer to come on a later look", |m| m.preparation == State::Reboot)
                .await;
            // The offer came while the user may be away, and the restart it
            // needs counts down: each asks for them.
            assert_eq!(*attention.lock().unwrap(), 2, "the offer came, and its restart counts down");
            let requests = scene.requests.lock().unwrap().clone();
            assert_eq!(requests.len(), 3);
            let offer_only: Vec<bool> =
                requests.iter().map(|r| r.transition.as_ref().unwrap().offer_only).collect();
            assert_eq!(offer_only, [false, true, true], "the automatic looks only look for the offer");
            assert!(read(&cx, &model, |m| m.offer_wait.is_none()), "the wait ends with the offer");
            assert!(!scene.calls().iter().any(|call| call == "Restore"));
            settle(&cx, &model).await;
        });
    }

    #[test]
    fn a_wait_that_runs_out_puts_the_settings_back_and_says_to_check_later() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-ended", 60, 200);
            offering_after(&mut scene, usize::MAX);
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| {
                m.accept_windows_terms(true, cx);
                m.prepare_windows(cx);
            });
            wait_for(&cx, &model, "the wait to run out", |m| m.offer_wait.is_some_and(|w| w.expired)).await;
            wait_until(&cx, "the settings to go back", || scene.calls().iter().any(|call| call == "Restore"))
                .await;
            let looks = scene.requests.lock().unwrap().len();
            assert!((2..=5).contains(&looks), "a few looks within the window, then none: {looks}");
            cx.background_executor().timer(Duration::from_millis(300)).await;
            assert_eq!(scene.requests.lock().unwrap().len(), looks, "no look after the wait ended");
            settle(&cx, &model).await;
        });
    }

    /// A worker whose runs end, in turn, as `outcomes` says: a failure reason,
    /// or `network`; after the last, the offer comes.
    fn worker_ending(scene: &mut Scene, outcomes: &'static [&'static str]) {
        let requests = scene.requests.clone();
        scene.env.adapters.run_preparation = Arc::new(move |_, request, _, mut report| {
            let mut seen = requests.lock().unwrap();
            seen.push(request.clone());
            let (progress, state) = match outcomes.get(seen.len() - 1) {
                Some(&"network") => (super::report("network", &[], None), State::Network),
                Some(reason) => (super::report("failed", &[], Some(reason)), State::Failed),
                None => (super::report("reboot", &["feature-update"], None), State::Reboot),
            };
            report(serde_json::from_value::<Progress>(progress).unwrap());
            Ok(state)
        });
    }

    async fn start_waiting(cx: &mut gpui::AsyncApp, scene: &Scene) -> Entity<AppModel> {
        let model = new_model(cx, scene.env.clone());
        to_get_ready(cx, &model, &scene.package).await;
        act(cx, &model, |m, cx| {
            m.accept_windows_terms(true, cx);
            m.prepare_windows(cx);
        });
        model
    }

    /// Between looks, Get ready shows the wait, with the minutes waited once
    /// there's a whole one to say; once the offer comes, there is no wait to
    /// show.
    #[test]
    fn between_looks_the_wait_shows_without_a_ticking_clock() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-clock", 400, 10_000);
            offering_after(&mut scene, 2);
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            read(&cx, &model, |m| {
                assert!(m.offer_wait_shown(), "the wait shows between looks");
                assert_eq!(m.offer_waited_minutes(), None, "under a minute says nothing");
                assert!(m.move_shows_preparation(), "on the move's card");
            });
            wait_for(&cx, &model, "the offer", |m| m.preparation == State::Reboot).await;
            read(&cx, &model, |m| {
                assert!(!m.offer_wait_shown());
                assert_eq!(m.offer_waited_minutes(), None);
            });
            settle(&cx, &model).await;
        });
    }

    /// A look that loses the connection doesn't end the wait: the next look
    /// comes as planned, and so does the end of the wait.
    #[test]
    fn a_look_that_loses_the_connection_keeps_waiting() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-network", 60, 10_000);
            worker_ending(&mut scene, &["feature-not-offered", "network"]);
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the offer on the look after", |m| m.preparation == State::Reboot).await;
            assert_eq!(scene.requests.lock().unwrap().len(), 3);
            assert!(!scene.calls().iter().any(|call| call == "Restore"));
            settle(&cx, &model).await;
        });
    }

    /// A look refused before it starts, as when a check now fails, keeps the
    /// wait going and still lets it end on time.
    #[test]
    fn a_refused_look_still_lets_the_wait_end() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-refused", 40, 300);
            offering_after(&mut scene, usize::MAX);
            // Once the first look has run the power check fails, so every
            // later look is refused before a run starts.
            let looked = scene.requests.clone();
            scene.env.adapters.run_check = Arc::new(move |id, context| match id {
                CheckId::Power if !looked.lock().unwrap().is_empty() => {
                    CheckResult { id, verdict: Verdict::Fail, detail: CheckDetail::PowerBattery }
                }
                CheckId::SupportedBuild => requirements::run(id, context),
                _ => passing(id),
            });
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the wait to run out", |m| m.offer_wait.is_some_and(|wait| wait.expired))
                .await;
            assert_eq!(scene.requests.lock().unwrap().len(), 1, "no run while the looks are refused");
            settle(&cx, &model).await;
        });
    }

    /// A move that waits for a newer monthly update looks again with full
    /// runs, the only ones that install it.
    #[test]
    fn a_missing_monthly_update_is_looked_for_with_full_runs() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-prerequisite", 60, 10_000);
            worker_ending(&mut scene, &["feature-prerequisite", "feature-not-offered"]);
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the offer", |m| m.preparation == State::Reboot).await;
            let offer_only: Vec<bool> = scene
                .requests
                .lock()
                .unwrap()
                .iter()
                .map(|request| request.transition.as_ref().unwrap().offer_only)
                .collect();
            assert_eq!(offer_only, [false, false, true]);
            settle(&cx, &model).await;
        });
    }

    /// A wait that runs out while something else runs puts the settings back
    /// once it's done, and says it did only then.
    #[test]
    fn a_wait_that_runs_out_while_something_runs_puts_the_settings_back_after() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-deferred", 40, 120);
            worker_ending(&mut scene, &["feature-not-offered"; 64]);
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            act(&mut cx, &model, |m, _| m.iso_busy = true);
            cx.background_executor().timer(Duration::from_millis(400)).await;
            assert!(!scene.calls().iter().any(|call| call == "Restore"), "nothing is put back meanwhile");
            assert!(read(&cx, &model, |m| m.offer_wait.is_some_and(|wait| !wait.expired)));
            act(&mut cx, &model, |m, _| m.iso_busy = false);
            wait_until(&cx, "the settings to go back", || scene.calls().iter().any(|call| call == "Restore"))
                .await;
            assert!(read(&cx, &model, |m| m.offer_wait.is_some_and(|wait| wait.expired)));
            settle(&cx, &model).await;
        });
    }

    /// An unfinished Atlas install puts the settings back as its last step,
    /// so a wait that runs out meanwhile stops looking and leaves them on.
    #[test]
    fn a_wait_that_runs_out_during_an_unfinished_install_stops_looking() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-install-active", 40, 120);
            *scene.machine.identity.lock().unwrap() =
                Some(InstallIdentity::Resume("0.6.0".into(), Default::default()));
            offering_after(&mut scene, usize::MAX);
            let model = start_waiting(&mut cx, &scene).await;
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            wait_for(&cx, &model, "the looks to stop", |m| !m.offer_wait_running()).await;
            read(&cx, &model, |m| {
                assert!(m.offer_wait.is_none(), "nothing was put back, so the wait isn't shown as ended");
                assert!(m.waiting_for_offer(), "Get ready offers Check again");
            });
            let looks = scene.requests.lock().unwrap().len();
            cx.background_executor().timer(Duration::from_millis(300)).await;
            assert_eq!(scene.requests.lock().unwrap().len(), looks, "no look after the wait ended");
            assert!(!scene.calls().iter().any(|call| call == "Restore"), "the install puts them back");
            settle(&cx, &model).await;
        });
    }

    /// With every later look refused, the wait's own timer ends it, and Get
    /// ready is drawn again without the wait.
    #[test]
    fn a_wait_ended_by_its_timer_during_an_unfinished_install_redraws_get_ready() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-install-refused", 40, 300);
            *scene.machine.identity.lock().unwrap() =
                Some(InstallIdentity::Resume("0.6.0".into(), Default::default()));
            offering_after(&mut scene, usize::MAX);
            let looked = scene.requests.clone();
            scene.env.adapters.run_check = Arc::new(move |id, context| match id {
                CheckId::Power if !looked.lock().unwrap().is_empty() => {
                    CheckResult { id, verdict: Verdict::Fail, detail: CheckDetail::PowerBattery }
                }
                CheckId::SupportedBuild => requirements::run(id, context),
                _ => passing(id),
            });
            let model = start_waiting(&mut cx, &scene).await;
            // Whether the wait showed at the last redraw.
            let shown = Arc::new(Mutex::new(None));
            let _observation = cx.update(|app| {
                let shown = shown.clone();
                app.observe(&model, move |model, app| {
                    *shown.lock().unwrap() = Some(model.read(app).offer_wait_running());
                })
            });
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            wait_for(&cx, &model, "the looks to stop", |m| !m.offer_wait_running()).await;
            wait_until(&cx, "a redraw without the wait", || *shown.lock().unwrap() == Some(false)).await;
            assert_eq!(scene.requests.lock().unwrap().len(), 1, "no run while the looks are refused");
            settle(&cx, &model).await;
        });
    }

    #[test]
    fn stopping_the_flow_stops_the_looks() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-stopped", 150, 10_000);
            offering_after(&mut scene, usize::MAX);
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| {
                m.accept_windows_terms(true, cx);
                m.prepare_windows(cx);
            });
            wait_for(&cx, &model, "the first look to find nothing", |m| m.offer_rechecks_active()).await;
            act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
            cx.background_executor().timer(Duration::from_millis(400)).await;
            assert_eq!(scene.requests.lock().unwrap().len(), 1, "no look after the flow stopped");
            assert!(read(&cx, &model, |m| m.offer_wait.is_none()));
            settle(&cx, &model).await;
        });
    }

    /// 25H2, waiting for the offer of 26H2 with the record open: a move run
    /// waits for the offer until it's stopped, a run without the move
    /// finishes, and putting the settings back closes the record.
    fn scene_optional_waiting(name: &str) -> Scene {
        let mut scene = scene(name, system(26200, "25H2", "Professional"));
        *scene.access.lock().unwrap() = record("transition", "targeted");
        scene.env.offer_recheck =
            OfferRecheckTiming { interval: Duration::from_secs(600), ..OfferRecheckTiming::default() };
        let requests = scene.requests.clone();
        scene.env.adapters.run_preparation = Arc::new(move |_, request, cancel, mut report| {
            requests.lock().unwrap().push(request.clone());
            if request.transition.is_none() {
                report(serde_json::from_value::<Progress>(super::report("complete", &[], None)).unwrap());
                return Ok(State::Ready);
            }
            report(
                serde_json::from_value::<Progress>(serde_json::json!({
                    "schema": 1, "status": "running", "stage": "windows-search", "completed": 0, "total": 0,
                    "activity": { "waiting": "feature-offer" }
                }))
                .unwrap(),
            );
            while !cancel.load(std::sync::atomic::Ordering::Relaxed) {
                std::thread::sleep(Duration::from_millis(10));
            }
            Ok(State::Cancelled)
        });
        let (log, access) = (scene.calls.clone(), scene.access.clone());
        scene.env.adapters.run_operation = Arc::new(move |_, operation| {
            log.lock().unwrap().push(format!("{operation:?}"));
            *access.lock().unwrap() = UpdateAccess::default();
            Ok(())
        });
        scene
    }

    /// Keep stays a choice while Atlas waits for the offer. Choosing it
    /// stops the run waiting for it, puts the settings back, and updates
    /// Windows without the move.
    #[test]
    fn keeping_this_version_while_waiting_stops_the_move_and_updates_without_it() {
        run_model_test(|mut cx| async move {
            let scene = scene_optional_waiting("offer-wait-keep");
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
            wait_for(&cx, &model, "the run to wait for the offer", |m| m.offer_wait_shown()).await;
            read(&cx, &model, |m| {
                assert!(m.preparation.busy());
                assert!(m.may_keep_windows_version(), "Keep stays a choice while Atlas waits");
                assert!(m.keeping_stops_the_move(), "and asks first");
                assert_eq!(m.ready_status(), Some(ReadyStatus::Updating));
            });
            act(&mut cx, &model, |m, cx| m.keep_windows_version_now(cx));
            wait_for(&cx, &model, "the version kept and updated without the move", |m| {
                m.windows_transition_declined && m.preparation == State::Idle && !m.transition_open()
            })
            .await;
            assert_eq!(scene.calls(), ["Restore"], "the settings went back once");
            read(&cx, &model, |m| {
                assert!(!m.updates_held(), "updating isn't held by the stop that kept the version");
                assert!(!m.windows_card_shown() || !m.move_shows_preparation());
            });
            act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
            wait_for(&cx, &model, "updates without the move", |m| m.preparation.ready()).await;
            let requests = scene.requests.lock().unwrap().clone();
            assert!(requests.last().is_some_and(|request| request.transition.is_none()));
            settle(&cx, &model).await;
        });
    }

    /// A move's first run opens Atlas's record before Atlas reads it. While
    /// an Atlas install is unfinished, its own last step puts the settings
    /// back, so keeping this version can't stop the move: Keep isn't
    /// offered, the run keeps waiting, and Get ready says why.
    #[test]
    fn keeping_this_version_waits_for_an_unfinished_install_without_stopping_the_run() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_optional_waiting("offer-wait-keep-install");
            *scene.access.lock().unwrap() = UpdateAccess::default();
            let (opened, waiting) = (scene.access.clone(), scene.env.adapters.run_preparation.clone());
            scene.env.adapters.run_preparation = Arc::new(move |job, request, cancel, report| {
                if request.transition.is_some() {
                    *opened.lock().unwrap() = record("transition", "targeted");
                }
                waiting(job, request, cancel, report)
            });
            *scene.machine.identity.lock().unwrap() =
                Some(InstallIdentity::Resume("0.6.0".into(), Default::default()));
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
            wait_for(&cx, &model, "the run to wait for the offer", |m| m.offer_wait_shown()).await;
            read(&cx, &model, |m| {
                assert!(!m.transition_open(), "Atlas hasn't read the record the run opened");
                assert!(!m.may_keep_windows_version(), "the install puts the settings back");
                assert!(m.keep_waits_for_install(), "and Get ready says so");
            });
            act(&mut cx, &model, |m, cx| m.keep_windows_version_now(cx));
            cx.background_executor().timer(Duration::from_millis(100)).await;
            read(&cx, &model, |m| {
                assert!(!m.preparation_cancel.load(std::sync::atomic::Ordering::Relaxed), "nothing stops");
                assert!(m.preparation.busy() && m.offer_wait_shown(), "the run keeps waiting");
            });
            act(&mut cx, &model, |m, _| {
                m.preparation_cancel.store(true, std::sync::atomic::Ordering::Relaxed)
            });
            wait_for(&cx, &model, "the run to stop", |m| !m.preparation.busy()).await;
            assert!(!scene.calls().iter().any(|call| call == "Restore"));
            settle(&cx, &model).await;
        });
    }

    /// Should the settings become the unfinished install's to put back while
    /// the run stops for Keep, the move stays: updating, stopped only to keep
    /// this version, isn't held, and Get ready says why the version wasn't kept.
    #[test]
    fn a_keep_the_stop_can_no_longer_finish_leaves_updating_to_carry_on() {
        run_model_test(|mut cx| async move {
            let scene = scene_optional_waiting("offer-wait-keep-changed");
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
            wait_for(&cx, &model, "the run to wait for the offer", |m| m.offer_wait_shown()).await;
            assert!(read(&cx, &model, AppModel::may_keep_windows_version));
            let identity = scene.machine.identity.clone();
            act(&mut cx, &model, |m, cx| {
                m.keep_windows_version_now(cx);
                // Read again as the run ends.
                *identity.lock().unwrap() = Some(InstallIdentity::Resume("0.6.0".into(), Default::default()));
            });
            wait_for(&cx, &model, "the run to stop", |m| !m.preparation.busy()).await;
            read(&cx, &model, |m| {
                assert!(!m.windows_transition_declined && m.transition_open(), "the move stays");
                assert!(!m.updates_held(), "updating isn't held by a stop made only to keep the version");
                assert_eq!(m.preparation, State::Idle, "updating can start again");
                assert!(m.keep_waits_for_install(), "Get ready says why the version wasn't kept");
            });
            assert!(!scene.calls().iter().any(|call| call == "Restore"));
            settle(&cx, &model).await;
        });
    }

    /// Stop updating while Atlas waits for the offer stops the run waiting
    /// for it, puts the settings back and ends the setup, as Cancel does.
    #[test]
    fn stopping_while_waiting_puts_the_settings_back_and_leaves() {
        run_model_test(|mut cx| async move {
            let scene = scene_optional_waiting("offer-wait-stop");
            let model = new_model(&mut cx, scene.env.clone());
            to_get_ready(&mut cx, &model, &scene.package).await;
            act(&mut cx, &model, |m, cx| m.accept_and_update(cx));
            wait_for(&cx, &model, "the run to wait for the offer", |m| m.offer_wait_shown()).await;
            act(&mut cx, &model, |m, cx| m.stop_waiting_for_offer(cx));
            wait_for(&cx, &model, "the setup to end", |m| !m.flow.active).await;
            assert_eq!(scene.calls(), ["Restore"]);
            assert_eq!(scene.requests.lock().unwrap().len(), 1, "nothing ran after the stop");
            settle(&cx, &model).await;
        });
    }

    #[test]
    fn opened_again_on_a_move_still_waiting_it_looks_once_by_itself() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-reopen", 10_000, 100_000);
            let mut access = record("transition", "targeted");
            if let Some(journal) = access.journal.as_mut() {
                journal.history.push(crate::services::update_access::HistoryEntry {
                    at: "2026-10-02T09:00:00Z".into(),
                    event: "outcome".into(),
                    detail:
                        "reason=feature-not-offered code= Windows Update does not offer 26H2 to this PC yet."
                            .into(),
                });
            }
            *scene.access.lock().unwrap() = access;
            offering_after(&mut scene, usize::MAX);
            let model = new_model(&mut cx, scene.env.clone());
            assert!(read(&cx, &model, AppModel::transition_waiting_for_offer), "Home offers Check again");
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.preparation = State::Idle;
                m.windows_terms_accepted = true;
                m.begin_install(cx);
                m.windows_terms_accepted = true;
            });
            act(&mut cx, &model, |m, cx| m.load_package_file(scene.package.clone(), cx));
            wait_until(&cx, "one look by itself", || !scene.requests.lock().unwrap().is_empty()).await;
            let request = scene.requests.lock().unwrap()[0].clone();
            assert!(request.transition.unwrap().offer_only);
            // A new flow in the same window starts updating over, and its
            // checks don't look again.
            wait_for(&cx, &model, "the look to find nothing", |m| m.preparation == State::Failed).await;
            act(&mut cx, &model, |m, cx| {
                m.cancel_flow(cx);
                m.begin_install(cx);
                m.windows_terms_accepted = true;
            });
            wait_for(&cx, &model, "the new flow's checks", |m| m.flow.active && m.checks_complete()).await;
            assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Idle, "only once per window");
            assert_eq!(scene.requests.lock().unwrap().len(), 1);
            settle(&cx, &model).await;
        });
    }

    /// Opened again on a move whose last run needed a newer monthly update,
    /// Get ready's own look is a full run, the only kind that installs it.
    #[test]
    fn opened_again_on_a_move_waiting_for_a_monthly_update_it_looks_with_a_full_run() {
        run_model_test(|mut cx| async move {
            let mut scene = scene_waiting("offer-wait-reopen-prerequisite", 10_000, 100_000);
            let mut access = record("transition", "targeted");
            if let Some(journal) = access.journal.as_mut() {
                journal.history.push(crate::services::update_access::HistoryEntry {
                    at: "2026-10-02T09:00:00Z".into(),
                    event: "outcome".into(),
                    detail: "reason=feature-prerequisite code= This PC needs a newer monthly update first."
                        .into(),
                });
            }
            *scene.access.lock().unwrap() = access;
            offering_after(&mut scene, usize::MAX);
            let model = new_model(&mut cx, scene.env.clone());
            assert!(read(&cx, &model, AppModel::transition_waiting_for_offer), "Home offers Check again");
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.preparation = State::Idle;
                m.begin_install(cx);
                m.windows_terms_accepted = true;
            });
            act(&mut cx, &model, |m, cx| m.load_package_file(scene.package.clone(), cx));
            wait_until(&cx, "one look by itself", || !scene.requests.lock().unwrap().is_empty()).await;
            let request = scene.requests.lock().unwrap()[0].clone();
            assert!(!request.transition.unwrap().offer_only, "a full run installs the monthly update");
            wait_for(&cx, &model, "the look to end", |m| !m.preparation.busy()).await;
            settle(&cx, &model).await;
        });
    }
}

/// An Atlas 0.5.0 install with Windows Update turned off by its toggle: the
/// record of the update lifted only the pause and the delay, because the
/// service had been turned on before it was made, yet the PC ends with
/// Windows Update off by the user's recorded choice. The Done window says so.
#[test]
fn the_done_window_says_windows_update_is_off_again_when_the_users_choice_turned_it_off() {
    run_model_test(|mut cx| async move {
        let scene = scene("done-update-off-again", system(26200, "25H2", "Professional"));
        let fixtures = concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/windows-transition");
        let state: serde_json::Value = serde_json::from_str(
            &std::fs::read_to_string(format!("{fixtures}/atlas050-updates-off-paused-delayed.json")).unwrap(),
        )
        .unwrap();
        let last =
            crate::services::update_access::parse_last_result(&state["lastResultSeen"].to_string()).unwrap();
        assert!(last.replayed().is_empty(), "the record lifted nothing the toggle owns");
        *scene.machine.state.lock().unwrap() = Some(
            serde_json::from_value(serde_json::json!({
                "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-10-02T04:31:30Z",
                "mode": "Upgrade", "options": ["defender-enable", "auto-updates-disable"]
            }))
            .unwrap(),
        );
        // After the install: the toggle's choice turned the service off again;
        // the pause and the delay came back as they were.
        let after = UpdateAccess {
            blockers: vec![
                Blocker { kind: BlockerKind::Off, owned: true },
                Blocker { kind: BlockerKind::Paused, owned: false },
                Blocker { kind: BlockerKind::Delayed, owned: false },
            ],
            last_result: Some(last.clone()),
            ..UpdateAccess::default()
        };
        *scene.access.lock().unwrap() = after;
        let model = new_model(&mut cx, scene.env.clone());
        act(&mut cx, &model, |m, _| {
            m.refresh_atlas_state();
            m.refresh_update_access();
        });
        assert_eq!(read(&cx, &model, |m| m.update_choice_after_install()), Some(vec![BlockerKind::Off]));

        // Nothing the user chose holds Windows Update back: nothing to say.
        *scene.access.lock().unwrap() = UpdateAccess {
            blockers: vec![Blocker { kind: BlockerKind::Paused, owned: false }],
            last_result: Some(last),
            ..UpdateAccess::default()
        };
        act(&mut cx, &model, |m, _| m.refresh_update_access());
        assert_eq!(read(&cx, &model, |m| m.update_choice_after_install()), Some(vec![]));
        settle(&cx, &model).await;
    });
}
