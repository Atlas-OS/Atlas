//! What a window finds when it opens: a held or unreadable install record,
//! and installs that ended while no window was open.

use std::time::Duration;

use crate::model::recovery::StartupInspection;
use crate::model::test_harness::{
    act, completed_session, fixture, marking_package, model_as_started, new_model, read, run_model_test,
    save_draft, settle, wait_for, wait_for_release, wait_on_disk,
};
use crate::model::{InstallBlock, Notice, Page, RunState, Step};
use crate::services::installer::{InstallOutcome, Phase};
use crate::services::session::{self, LaunchLock};
use crate::services::settings::InstallDraft;

/// While another window holds the launch lock, startup can't tell whether an
/// install is running, and Home starts nothing until it can.
#[test]
fn nothing_starts_while_startup_waits_for_the_launch_lock() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("startup-lock");
        let held = LaunchLock::acquire(&env.paths.session()).unwrap();
        let model = new_model(&mut cx, env);
        assert!(read(&cx, &model, |m| m.recovering));
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(!read(&cx, &model, |m| m.flow.active));
        drop(held);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(read(&cx, &model, |m| m.flow.active));
        settle(&cx, &model).await;
    });
}

/// An install record that can't be read holds the flow at Get ready, which
/// explains it, until a new reading succeeds. The record itself is never
/// removed: whose it is is unknown.
#[test]
fn an_unreadable_install_record_holds_the_flow_at_get_ready_until_it_reads_cleanly() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("record-unreadable");
        let record = env.paths.session().record;
        std::fs::create_dir_all(record.parent().unwrap()).unwrap();
        std::fs::write(&record, "{ not json").unwrap();
        save_draft(
            &env,
            InstallDraft {
                step: "security".into(),
                flow: Some("earlier-window".into()),
                preparation_ready: true,
                ..InstallDraft::default()
            },
        );
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the draft", |m| m.flow.active && m.checks_complete()).await;
        read(&cx, &model, |m| {
            assert!(matches!(m.install_block(), Some(InstallBlock::RecordUnreadable { .. })));
            assert!(m.start_block().is_none(), "the elevated window reads it again for itself");
            assert!(matches!(m.notice, Some(Notice::SessionUnreadable { .. })));
            assert_eq!(m.flow.step, Step::Ready, "not past the step that explains it");
            assert_eq!(m.page, Page::Install);
            assert!(!m.ready_to_continue());
        });
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Ready);

        // A reading that finds it still unreadable keeps the flow held.
        act(&mut cx, &model, |m, cx| m.run_checks(cx));
        wait_for(&cx, &model, "the checks", |m| m.checks_complete()).await;
        cx.background_executor().timer(Duration::from_millis(200)).await;
        assert!(read(&cx, &model, |m| m.record_problem.is_some()));
        assert!(record.exists(), "an unreadable record is never removed");

        // A launch's answer outranks a reading that was already under way.
        act(&mut cx, &model, |m, cx| {
            let earlier = m.record_generation;
            m.set_record_problem(Some("found by the launch".into()));
            m.finish_record_check(earlier, StartupInspection::None, cx);
            assert_eq!(m.record_problem.as_deref(), Some("found by the launch"));
        });

        std::fs::remove_file(&record).unwrap();
        act(&mut cx, &model, |m, cx| m.run_checks(cx));
        wait_for(&cx, &model, "a clean reading", |m| m.record_problem.is_none()).await;
        read(&cx, &model, |m| {
            assert!(m.notice.is_none(), "Home no longer reports it");
            assert!(m.install_block().is_none());
        });
    });
}

#[test]
#[cfg(windows)]
fn a_success_found_on_reopening_shows_its_result_and_clears_its_draft() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-recovered-success");
        let (package, _) = marking_package(&temp, 0);
        let record = completed_session(&env, &package, true);
        assert_eq!(record.exit_code(), Some(0));
        save_draft(
            &env,
            InstallDraft {
                step: "install".into(),
                options: vec!["defender-enable".into()],
                playbook_dir: Some(record.request.playbook_dir.clone()),
                session: Some(record.id.clone()),
                flow: Some("launcher".into()),
                ..InstallDraft::default()
            },
        );

        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the recovered result", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Finished(InstallOutcome::Succeeded));
            assert!(m.install_in_progress(), "the success view shows until the user leaves it");
            assert_eq!(m.session.as_ref().map(|s| s.id.as_str()), Some(record.id.as_str()));
            assert!(m.attempt.log_total > 0, "the log was replayed");
            assert!(m.attempt.recovered);
            assert!(m.restart_countdown().is_none(), "no countdown is claimed for a restart nobody watched");
            assert!(m.settings.draft.is_none(), "the draft that launched this install is finished");
        });
        wait_on_disk(&cx, &env, "the launching draft to be cleared", |s| s.draft.is_none()).await;
        assert!(
            session::load(&env.paths.session()).unwrap().is_some(),
            "the record stays until acknowledged"
        );

        // Leaving releases the record, and a new flow starts from nothing.
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        wait_for_release(&cx, &env, "the record to be released on leaving").await;
        assert!(read(&cx, &model, |m| !m.flow.active && m.page == Page::Home));
    });
}

#[test]
#[cfg(windows)]
fn a_failure_found_on_reopening_runs_the_checks_its_retry_needs() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-recovered-failure");
        let (package, marker) = marking_package(&temp, 1);
        let record = completed_session(&env, &package, false);
        assert_eq!(record.exit_code(), Some(1));
        std::fs::remove_file(&marker).unwrap();

        save_draft(
            &env,
            InstallDraft {
                step: "install".into(),
                options: record.request.options.clone(),
                playbook_dir: Some(record.request.playbook_dir.clone()),
                session: Some(record.id.clone()),
                flow: Some("failed-install-launcher".into()),
                // An install only launches once Windows is prepared.
                preparation_ready: true,
                ..InstallDraft::default()
            },
        );

        let model = model_as_started(&mut cx, env);
        wait_for(&cx, &model, "the recovered failure", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Finished(InstallOutcome::Failed(1)));
            assert_eq!(m.flow_id.as_deref(), Some("failed-install-launcher"));
            assert!(m.preparation.ready(), "the launching draft's finished preparation is kept");
            assert_eq!(m.flow.step, Step::Install);
            assert!(m.playbook.is_some(), "the recorded package is picked up");
            assert!(!m.checks.is_empty(), "the readiness checks the retry depends on were started");
            assert!(m.attempt.phase >= Phase::Applying, "the replayed log set the phase");
        });
        wait_for(&cx, &model, "the checks and a security reading", |m| {
            m.checks_complete() && m.security_fresh()
        })
        .await;
        assert!(read(&cx, &model, |m| m.can_install()), "Try again is usable without going back a step");

        // And the retry is a real new attempt with the current choices.
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the retry to run", |m| {
            matches!(m.flow.run, RunState::Finished(_))
                && m.session.as_ref().is_some_and(|s| s.id != record.id)
        })
        .await;
        assert!(marker.exists(), "the retry ran the front door");
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Finished(InstallOutcome::Failed(1)));
    });
}

/// Only the draft that launched the recovered install speaks for its
/// preparation, and only as far as it goes.
#[test]
#[cfg(windows)]
fn a_recovered_failure_is_not_ready_on_a_draft_that_does_not_vouch_for_it() {
    run_model_test(async move |mut cx| {
        for (launcher, prepared) in [(false, true), (true, false)] {
            let (temp, _, env) = fixture("model-recovered-unprepared");
            let (package, _) = marking_package(&temp, 1);
            let record = completed_session(&env, &package, false);
            save_draft(
                &env,
                InstallDraft {
                    step: "install".into(),
                    options: record.request.options.clone(),
                    playbook_dir: Some(record.request.playbook_dir.clone()),
                    session: Some(if launcher { record.id.clone() } else { "another-install".into() }),
                    flow: Some("some-flow".into()),
                    preparation_ready: prepared,
                    ..InstallDraft::default()
                },
            );
            let model = model_as_started(&mut cx, env);
            wait_for(&cx, &model, "the recovered failure", |m| matches!(m.flow.run, RunState::Finished(_)))
                .await;
            wait_for(&cx, &model, "the checks and a security reading", |m| {
                m.checks_complete() && m.security_fresh()
            })
            .await;
            read(&cx, &model, |m| {
                assert!(!m.preparation.ready(), "launcher={launcher} prepared={prepared}");
                assert!(!m.ready_to_continue());
                assert!(!m.can_install());
            });
        }
    });
}
