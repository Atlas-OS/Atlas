//! Relaunching as administrator, from Home and from inside the flow.

use std::sync::{Arc, Mutex};

use crate::model::test_harness::{
    act, fixture, new_model, read, run_model_test, settle, wait_for, wait_on_disk, wait_until,
};
use crate::model::{Acquisition, ElevationProblem};
use crate::services::settings::{self, InstallDraft};

/// Home's Install runs the UAC prompt off the window's thread, once, and a
/// refusal ends the flow it began.
#[test]
fn elevation_runs_off_the_windows_thread_once_and_a_refusal_ends_the_flow() {
    run_model_test(|mut cx| async move {
        let (_temp, _, mut env) = fixture("elevation");
        env.adapters.is_elevated = Arc::new(|| false);
        let prompts = Arc::new(Mutex::new(Vec::new()));
        let (answer, answered) = std::sync::mpsc::channel::<()>();
        let answered = Mutex::new(answered);
        env.adapters.relaunch_elevated = Arc::new({
            let prompts = prompts.clone();
            move || {
                prompts.lock().unwrap().push(std::thread::current().id());
                // The prompt stays up until the test has tried again.
                answered.lock().unwrap().recv().ok();
                anyhow::bail!("the user chose No")
            }
        });
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(read(&cx, &model, |m| m.flow.active && m.elevating));
        wait_until(&cx, "the elevation prompt", || !prompts.lock().unwrap().is_empty()).await;
        // Start over and Try again do nothing while the prompt is up.
        act(&mut cx, &model, |m, cx| {
            m.begin_install(cx);
            m.relaunch_elevated(cx);
        });
        answer.send(()).unwrap();
        wait_for(&cx, &model, "the refusal", |m| m.elevation_error.is_some()).await;
        read(&cx, &model, |m| {
            assert_eq!(m.elevation_error, Some(ElevationProblem::Declined));
            assert!(!m.flow.active && !m.elevating);
        });
        let prompts = prompts.lock().unwrap().clone();
        assert_eq!(prompts.len(), 1);
        assert_ne!(prompts[0], std::thread::current().id(), "the prompt ran on the window's thread");
        wait_on_disk(&cx, &env, "the declined flow's draft to be cleared", |s| s.draft.is_none()).await;
    });
}

#[test]
fn a_relaunch_waits_for_the_package_and_reports_each_attempt() {
    run_model_test(async move |mut cx| {
        let (_temp, _, env) = fixture("model-relaunch");
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        wait_on_disk(&cx, &env, "this flow's draft", |s| s.draft.is_some()).await;
        act(&mut cx, &model, |m, cx| {
            m.elevated = false;
            // The draft cannot name a package that is still being unpacked,
            // so the elevated copy would fetch another in its place.
            m.acquisition = Acquisition::Extracting { done: 0, total: 1 };
            m.elevation_error = Some(ElevationProblem::DeclinedContinue);
            let draft = m.settings.draft.clone();
            assert!(!m.may_relaunch_elevated());
            m.relaunch_elevated(cx);
            assert_eq!(m.settings.draft, draft, "nothing is saved for a relaunch that is refused");
            assert_eq!(m.elevation_error, Some(ElevationProblem::DeclinedContinue));
            m.acquisition = Acquisition::Idle;
        });
        // Make the settings path unreadable as a document, so the draft
        // cannot be saved and the relaunch never reaches the UAC prompt.
        std::fs::remove_file(env.paths.settings()).unwrap();
        std::fs::create_dir(env.paths.settings()).unwrap();
        act(&mut cx, &model, |m, cx| {
            m.relaunch_elevated(cx);
            assert!(m.elevation_error.is_none(), "an attempt shows only its own result");
        });
        wait_for(&cx, &model, "the save failure", |m| {
            matches!(m.elevation_error, Some(ElevationProblem::DraftNotSaved { .. }))
        })
        .await;
        // Leaving the flow drops a problem that belonged to it.
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        assert!(read(&cx, &model, |m| m.elevation_error.is_none()));
        settle(&cx, &model).await;
    });
}

/// Relaunching can't help a setup another window took over, so it is no
/// longer offered; Start over, beside the message, takes the setup back.
#[test]
fn a_relaunch_is_not_offered_for_a_setup_another_window_took_over() {
    run_model_test(async move |mut cx| {
        let (_temp, _, env) = fixture("model-relaunch-taken-over");
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        // A tester build unpacks its bundled package first.
        wait_for(&cx, &model, "the checks", |m| m.checks_complete() && !m.acquisition.is_busy()).await;
        wait_on_disk(&cx, &env, "this flow's draft", |s| s.draft.is_some()).await;
        let foreign = InstallDraft {
            step: "options".into(),
            flow: Some("another-window".into()),
            ..InstallDraft::default()
        };
        settings::modify(&env.paths.settings(), settings::LOCK_WAIT, |doc| doc.draft = Some(foreign.clone()))
            .unwrap();
        act(&mut cx, &model, |m, cx| {
            m.elevated = false;
            assert!(m.may_relaunch_elevated());
            m.relaunch_elevated(cx);
        });
        wait_for(&cx, &model, "the refusal", |m| m.elevation_error == Some(ElevationProblem::TakenOver))
            .await;
        act(&mut cx, &model, |m, cx| {
            assert!(!m.may_relaunch_elevated(), "only Start over can help");
            m.relaunch_elevated(cx);
            assert!(!m.elevating);
            assert_eq!(m.elevation_error, Some(ElevationProblem::TakenOver));
        });
        settle(&cx, &model).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(foreign));
    });
}
