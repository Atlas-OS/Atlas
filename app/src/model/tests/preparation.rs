//! Windows preparation: how it holds the install back, its restart, and what
//! a draft remembers of it.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use crate::model::test_harness::{
    act, fixture, marking_package, model_as_started, new_model, read, run_model_test, save_draft, settle,
    wait_for, wait_on_disk, walk_to_install,
};
use crate::model::{AppModel, RunState, Step};
use crate::services::installer::InstallOutcome;
use crate::services::playbook;
use crate::services::preparation::{Drivers, RestartProblem, State, StoreOutcome};
use crate::services::settings::{self, InstallDraft};
use crate::services::test_support::apbx;

#[test]
fn incomplete_preparation_blocks_install_even_when_checks_pass() {
    run_model_test(|mut cx| async move {
        let (temp, _, env) = fixture("preparation-gate");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert!(read(&cx, &model, AppModel::can_install), "a prepared PC may install");
        act(&mut cx, &model, |m, _| m.preparation = State::Idle);
        read(&cx, &model, |m| {
            assert!(!m.ready_to_continue());
            assert!(!m.can_install());
        });
        settle(&cx, &model).await;
    });
}

#[test]
fn preparation_arms_recovery_without_requesting_shutdown_and_restores_choices() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env) = fixture("preparation-auto-resume");
        let path = env.paths.settings();
        let registered = Arc::new(Mutex::new(0));
        let count = registered.clone();
        env.adapters.register_preparation_resume = Arc::new(move || {
            let draft = settings::load_from(&path).settings.draft.unwrap();
            assert!(draft.preparation_restart_at.is_some(), "save must precede registration");
            assert!(draft.playbook_dir.is_some());
            *count.lock().unwrap() += 1;
            Ok(())
        });
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        let choices = read(&cx, &model, |m| m.options.clone());
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Reboot;
            m.save_preparation_restart(false, cx);
        });
        wait_for(&cx, &model, "automatic recovery registration", |m| m.preparation == State::Reboot).await;
        assert_eq!(*registered.lock().unwrap(), 1);
        assert_eq!(*machine.scheduled.lock().unwrap(), 0, "detection must not restart Windows");
        let mut saved = settings::load_from(&env.paths.settings()).settings;
        act(&mut cx, &model, |m, cx| {
            m.settings = saved.clone();
            m.resume_draft(cx);
        });
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
        saved.draft.as_mut().unwrap().preparation_restart_at = Some("2001-01-01T00:00:00Z".into());
        act(&mut cx, &model, |m, cx| {
            m.options.clear();
            m.settings = saved;
            m.resume_draft(cx);
        });
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Resumed);
        assert_eq!(read(&cx, &model, |m| m.options.clone()), choices);
    });
}

#[test]
fn preparation_restart_failures_are_visible_and_do_not_schedule_shutdown() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("preparation-restart-errors");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Reboot;
            m.env.adapters.register_preparation_resume = Arc::new(|| anyhow::bail!("registration denied"));
            m.restart_preparation(cx);
        });
        wait_for(&cx, &model, "registration error", |m| {
            m.preparation_problem == Some(RestartProblem::Registration)
        })
        .await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.register_preparation_resume = Arc::new(|| Ok(()));
            m.env.adapters.schedule_restart = Arc::new(|_| anyhow::bail!("shutdown denied"));
            m.restart_preparation(cx);
        });
        wait_for(&cx, &model, "shutdown error", |m| m.preparation_problem == Some(RestartProblem::Restart))
            .await;
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
        // Another window's newer choices must survive automatic recovery saving.
        let foreign = InstallDraft { flow: Some("newer-window".into()), ..InstallDraft::default() };
        settings::modify(&env.paths.settings(), settings::LOCK_WAIT, |doc| doc.draft = Some(foreign.clone()))
            .unwrap();
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.register_preparation_resume = Arc::new(|| panic!("must own the draft"));
            m.restart_preparation(cx);
        });
        wait_for(&cx, &model, "foreign draft refusal", |m| {
            m.preparation_problem == Some(RestartProblem::Save)
        })
        .await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(foreign));
        // Make the fixture settings path unreadable as a document.
        std::fs::remove_file(env.paths.settings()).unwrap();
        std::fs::create_dir(env.paths.settings()).unwrap();
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.register_preparation_resume = Arc::new(|| panic!("must save first"));
            m.restart_preparation(cx);
        });
        wait_for(&cx, &model, "draft save error", |m| m.preparation_problem == Some(RestartProblem::Save))
            .await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
    });
}

#[test]
fn preparation_restart_returns_to_a_retry_when_windows_does_not_exit() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env) = fixture("preparation-restart-grace");
        env.restart.grace = Duration::from_millis(50);
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Reboot;
            m.restart_preparation(cx);
        });
        wait_for(&cx, &model, "shutdown grace period", |m| {
            m.preparation_problem == Some(RestartProblem::Restart)
        })
        .await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
    });
}

#[test]
fn a_resumed_draft_keeps_a_finished_preparation() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-draft-preparation-ready");
        let (package, _) = marking_package(&temp, 0);
        let (dir, _) = playbook::extract_into(&package, &env.paths.playbooks(), |_, _| {}).unwrap();
        save_draft(
            &env,
            InstallDraft {
                step: "install".into(),
                options: vec!["defender-enable".into()],
                playbook_dir: Some(dir),
                flow: Some("earlier-window".into()),
                preparation_ready: true,
                ..InstallDraft::default()
            },
        );
        let model = model_as_started(&mut cx, env.clone());
        wait_for(&cx, &model, "the draft and its checks", |m| m.flow.active && m.checks_complete()).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Install);
            assert!(m.preparation.ready(), "the draft carries the finished preparation");
            assert!(m.ready_to_continue(), "Install is not held back for a preparation already done");
        });

        // Changing the driver policy starts preparation over, on disk too.
        act(&mut cx, &model, |m, cx| m.set_drivers(Drivers::Manual, cx));
        assert!(!read(&cx, &model, |m| m.preparation.ready()));
        wait_on_disk(&cx, &env, "the draft to forget the finished preparation", |s| {
            s.draft.as_ref().is_some_and(|draft| !draft.preparation_ready)
        })
        .await;
        // A restart still owed wins over the flag.
        let mut saved = settings::load_from(&env.paths.settings()).settings;
        let draft = saved.draft.as_mut().unwrap();
        draft.preparation_ready = true;
        draft.preparation_restart_at = Some("2001-01-01T00:00:00Z".into());
        act(&mut cx, &model, |m, cx| {
            m.settings = saved;
            m.resume_draft(cx);
        });
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Resumed);
    });
}

#[test]
#[cfg(windows)]
fn an_install_that_finds_preparation_out_of_date_offers_it_again() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-preparation-stale");
        // The stub front door exits with whatever code the test has written.
        let code = temp.path().join("exit-code.txt");
        std::fs::write(&code, "1").unwrap();
        let body = format!(
            "Write-Host '[Atlas] Copying Atlas''s files to a protected folder...'\r\nexit ([int](Get-Content -LiteralPath '{}'))",
            code.display()
        );
        let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", &body));
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "an ordinary failure", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Finished(InstallOutcome::Failed(1)));
            assert!(m.preparation.ready(), "other failures leave preparation as it was");
        });

        std::fs::write(&code, "5").unwrap();
        wait_for(&cx, &model, "Try again to be usable", |m| m.can_install()).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the out-of-date result", |m| {
            m.flow.run == RunState::Finished(InstallOutcome::Failed(5))
        })
        .await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Idle, "Get ready offers the update check again");
            assert!(!m.can_install(), "Try again waits for Get ready");
        });
        wait_on_disk(&cx, &env, "the draft to forget the finished preparation", |s| {
            s.draft.as_ref().is_some_and(|draft| !draft.preparation_ready)
        })
        .await;
    });
}

#[test]
fn checking_again_after_a_finished_preparation_stops_vouching_for_it() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-preparation-recheck");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        act(&mut cx, &model, |m, cx| m.load_playbook_file(package, cx));
        wait_for(&cx, &model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete())
            .await;
        wait_on_disk(&cx, &env, "a draft with the finished preparation", |s| {
            s.draft.as_ref().is_some_and(|draft| draft.preparation_ready)
        })
        .await;
        // Unit tests never start a real worker, so this run fails at once;
        // however a run ends, the draft no longer says preparation is done.
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the run to end", |m| m.preparation == State::Failed).await;
        wait_on_disk(&cx, &env, "the draft to stop vouching for preparation", |s| {
            s.draft.as_ref().is_some_and(|draft| !draft.preparation_ready)
        })
        .await;
    });
}

/// The machine's driver policy is read when the model starts, not on every
/// render of the Ready step, and the user's choice overrides it.
#[test]
fn the_driver_default_is_not_read_per_render_and_a_choice_overrides_it() {
    run_model_test(async move |mut cx| {
        let (_temp, _, mut env) = fixture("model-driver-default");
        let reads = Arc::new(Mutex::new(0));
        let count = reads.clone();
        env.adapters.read_driver_default = Arc::new(move || {
            *count.lock().unwrap() += 1;
            Drivers::Manual
        });
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        let before = *reads.lock().unwrap();
        for _ in 0..10 {
            assert_eq!(read(&cx, &model, AppModel::driver_preference), Drivers::Manual);
        }
        assert_eq!(*reads.lock().unwrap(), before, "rendering does not read the machine");
        act(&mut cx, &model, |m, cx| m.set_drivers(Drivers::Automatic, cx));
        assert_eq!(read(&cx, &model, AppModel::driver_preference), Drivers::Automatic, "a choice wins");
        settle(&cx, &model).await;
    });
}

/// A worker double that reports `report` as its last word and ends in `state`,
/// counting its runs.
fn store_worker(
    report: serde_json::Value,
    state: State,
    runs: Arc<Mutex<u32>>,
) -> Arc<crate::environment::RunPreparation> {
    Arc::new(move |_, _, _, mut progress| {
        *runs.lock().unwrap() += 1;
        progress(serde_json::from_value(report.clone()).unwrap());
        Ok(state.clone())
    })
}

/// A run that updated Microsoft Store and then needed a restart still says so
/// when updating is done after the restart, from the draft the restart kept.
#[test]
fn what_updating_did_about_microsoft_store_is_said_after_a_restart() {
    run_model_test(|mut cx| async move {
        let (temp, _, env) = fixture("preparation-store-restart");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        act(&mut cx, &model, |m, cx| m.load_playbook_file(package.clone(), cx));
        wait_for(&cx, &model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete())
            .await;
        let runs = Arc::new(Mutex::new(0));
        let restart = serde_json::json!({
            "schema": 1, "status": "reboot", "stage": "windows-install", "completed": 0, "total": 0,
            "activity": { "storeOutcome": "store-updated", "restartReasons": ["servicing"] }
        });
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.run_preparation = store_worker(restart, State::Reboot, runs.clone());
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the restart to be owed", |m| m.preparation == State::Reboot).await;
        assert_eq!(read(&cx, &model, |m| m.store_outcome()), None, "not before updating is done");
        crate::model::test_harness::wait_on_disk(&cx, &env, "the Store outcome in the draft", |s| {
            s.draft.as_ref().is_some_and(|d| d.store_outcome.as_deref() == Some("store-updated"))
        })
        .await;

        // After the restart: a new window restores the draft, and the run
        // that finishes says nothing more about the Store.
        let draft = crate::services::settings::load_from(&env.paths.settings()).settings.draft.unwrap();
        let done = serde_json::json!({
            "schema": 1, "status": "complete", "stage": "verify", "completed": 0, "total": 0, "activity": {}
        });
        act(&mut cx, &model, |m, cx| {
            m.store_outcome_seen = None;
            m.restore_preparation(&draft);
            m.preparation = State::Resumed;
            m.env.adapters.run_preparation = store_worker(done, State::Ready, runs.clone());
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the run after the restart", |m| m.preparation == State::Ready).await;
        assert_eq!(read(&cx, &model, |m| m.store_outcome()), Some(StoreOutcome::Updated));
    });
}

/// Get ready says what it did about Microsoft Store itself once it's done, and
/// a Store it couldn't repair is offered the repairs again and a report.
#[test]
fn get_ready_says_what_it_did_about_microsoft_store() {
    run_model_test(|mut cx| async move {
        let (temp, _, env) = fixture("preparation-store-outcome");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        act(&mut cx, &model, |m, cx| m.load_playbook_file(package.clone(), cx));
        wait_for(&cx, &model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete())
            .await;
        let runs = Arc::new(Mutex::new(0));

        for (id, outcome) in [
            ("store-updated", StoreOutcome::Updated),
            ("store-bootstrapped", StoreOutcome::Bootstrapped),
            ("store-repaired", StoreOutcome::Repaired),
            ("store-skipped-removed", StoreOutcome::SkippedRemoved),
        ] {
            let report = serde_json::json!({
                "schema": 1, "status": "complete", "stage": "verify", "completed": 0, "total": 0,
                "activity": { "storeOutcome": id }
            });
            act(&mut cx, &model, |m, cx| {
                m.env.adapters.run_preparation = store_worker(report, State::Ready, runs.clone());
                m.preparation = State::Idle;
                m.prepare_windows(cx);
            });
            wait_for(&cx, &model, "the run to finish", |m| m.preparation == State::Ready).await;
            assert_eq!(read(&cx, &model, |m| m.store_outcome()), Some(outcome), "{id}");
            assert!(!read(&cx, &model, |m| m.store_repair_failed()));
        }

        // A run that says nothing about the Store, and an outcome this build doesn't know.
        for activity in [serde_json::json!({}), serde_json::json!({ "storeOutcome": "store-later" })] {
            let report = serde_json::json!({
                "schema": 1, "status": "complete", "stage": "verify", "completed": 0, "total": 0, "activity": activity
            });
            act(&mut cx, &model, |m, cx| {
                m.env.adapters.run_preparation = store_worker(report, State::Ready, runs.clone());
                m.preparation = State::Idle;
                m.prepare_windows(cx);
            });
            wait_for(&cx, &model, "the run to finish", |m| m.preparation == State::Ready).await;
            assert_eq!(read(&cx, &model, |m| m.store_outcome()), None);
        }

        // The repairs didn't help: the failure is the Store's own, and trying
        // again runs the worker, and so the repairs, again.
        let failed = serde_json::json!({
            "schema": 1, "status": "failed", "stage": "store-repair", "completed": 0, "total": 0,
            "activity": { "reason": "store-repair-failed", "failureMessage": "Microsoft Store couldn't be repaired." }
        });
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.run_preparation = store_worker(failed, State::Failed, runs.clone());
            m.preparation = State::Idle;
            m.prepare_windows(cx);
        });
        wait_for(&cx, &model, "the failed run", |m| m.preparation == State::Failed).await;
        read(&cx, &model, |m| {
            assert!(m.store_repair_failed());
            assert_eq!(m.store_outcome(), None);
            let failure = m.preparation_progress.as_ref().and_then(|p| p.failure());
            assert_eq!(
                crate::i18n::describe::preparation_failure(failure, false),
                crate::t!("prepare-failed-store-repair-failed")
            );
        });
        let before = *runs.lock().unwrap();
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the second try", |m| {
            m.preparation == State::Failed && *runs.lock().unwrap() > before
        })
        .await;
        settle(&cx, &model).await;
    });
}
