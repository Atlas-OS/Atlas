//! Pages, steps and Change links, and the start request a launch makes.

use crate::model::test_harness::{
    act, all_off, fixture, marking_package, new_model, read, run_model_test, save_draft, settle, wait_for,
    walk_to_install,
};
use crate::model::{AppModel, Page, Step};
use crate::services::installer::InstallOutcome;
use crate::services::security::{SecurityStatus, Switch};
use crate::services::settings::{self, InstallDraft};
use crate::services::{playbook, session};

#[test]
fn navigation_goes_only_where_the_window_can_show_the_page() {
    run_model_test(|mut cx| async move {
        use crate::services::preparation::{Stage, State};
        let (_temp, _, env) = fixture("navigation");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;

        // Each change of page is a new visit; staying put is not.
        act(&mut cx, &model, |m, cx| {
            m.navigate(Page::Settings, cx);
            m.navigate(Page::Settings, cx);
            assert_eq!((m.page, m.page_visit), (Page::Settings, 1));
            m.navigate(Page::Home, cx);
            assert_eq!((m.page, m.page_visit), (Page::Home, 2));
        });

        // A running preparation keeps the window where it is, but its
        // progress and Stop on the Install page can always be reached: a look
        // for the update offer can start while the window shows another page.
        act(&mut cx, &model, |m, cx| {
            m.navigate(Page::Settings, cx);
            m.preparation = State::Running { stage: Stage::StoreInstall, completed: 1, total: 2 };
            assert!(!m.can_navigate(Page::Home) && !m.can_navigate(Page::Report));
            assert_eq!(m.back_target(), Page::Install, "the back arrow leads to the progress");
            m.navigate(Page::Home, cx);
            assert_eq!((m.page, m.page_visit), (Page::Settings, 3));
            m.navigate(Page::Install, cx);
            assert_eq!((m.page, m.page_visit), (Page::Install, 4));
            assert_eq!(m.back_target(), Page::Home);
            assert!(!m.can_navigate(Page::Home) && !m.can_navigate(Page::Settings), "nothing leaves it");
            m.preparation = State::Ready;
            m.navigate(Page::Home, cx);
            assert_eq!((m.page, m.page_visit), (Page::Home, 5));
        });

        // An ISO job allows only the ISO page.
        act(&mut cx, &model, |m, cx| {
            m.iso_busy = true;
            assert!(m.can_navigate(Page::Iso));
            assert!(!m.can_navigate(Page::Report) && !m.can_navigate(Page::Home));
            m.navigate(Page::Report, cx);
            assert_eq!(m.page, Page::Home);
            m.iso_busy = false;
        });

        // The installing view covers every page while an install runs and
        // after it succeeds, so nothing underneath changes; a failure ends
        // on the Install page with its result.
        act(&mut cx, &model, |m, cx| {
            for outcome in [InstallOutcome::Succeeded, InstallOutcome::Failed(1)] {
                m.flow.attach_running().unwrap();
                m.navigate(Page::Install, cx);
                for page in [Page::Settings, Page::Report, Page::Home] {
                    assert!(!m.can_navigate(page), "{page:?}");
                    m.navigate(page, cx);
                }
                assert_eq!(m.page, Page::Install);
                m.flow.finish(outcome).unwrap();
                assert_eq!(m.can_navigate(Page::Report), !outcome.is_success(), "{outcome:?}");
                assert_eq!(m.page, Page::Install);
            }
        });
    });
}

#[test]
fn the_report_page_goes_back_to_where_it_was_opened() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("report-back");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            assert_eq!(m.back_target(), Page::Home);
            m.navigate(Page::Settings, cx);
            m.navigate(Page::Report, cx);
            assert_eq!(m.back_target(), Page::Settings);
            // Desktop setup reports from the install flow and returns to it.
            m.flow.resume(Step::Options).unwrap();
            m.navigate(Page::Install, cx);
            m.navigate(Page::Report, cx);
            assert_eq!(m.back_target(), Page::Install);
            // A flow that has ended has no step to return to.
            m.flow.cancel().unwrap();
            assert_eq!(m.back_target(), Page::Home);
        });
    });
}

/// Install and Continue update on Home begin nothing while Windows Update
/// settings are being put back: the new flow's checks and package couldn't
/// run under it.
#[test]
fn no_flow_begins_while_settings_are_put_back() {
    run_model_test(|mut cx| async move {
        use crate::model::RestoreStatus;
        let (_temp, _, env) = fixture("model-begin-during-put-back");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.restore_status = RestoreStatus::Running;
            m.begin_install(cx);
            assert!(!m.flow.active, "nothing begins under the put-back");
            m.restore_status = RestoreStatus::Idle;
            m.begin_install(cx);
            assert!(m.flow.active && !m.checks.is_empty(), "it begins once the put-back ends");
        });
        settle(&cx, &model).await;
    });
}

/// Back on Your choices steps from the screen showing, also when a draft's
/// index is past the last screen of a package that has fewer.
#[test]
fn back_steps_from_the_options_screen_that_shows() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("model-options-back");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.start_flow_at(Step::Options, cx);
            let last = m.option_screens().len() - 1;
            assert!(last > 0, "the built-in package has more than one screen");
            m.option_screen = last + 3;
            m.previous_step(cx);
            assert_eq!((m.flow.step, m.current_option_screen()), (Step::Options, last - 1));
        });
        settle(&cx, &model).await;
    });
}

/// A Change link on the Install step brings the user back to it, through
/// Windows Security only when its reading no longer passes.
#[test]
fn a_change_link_returns_to_the_summary() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-change-link");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Install);

        act(&mut cx, &model, |m, cx| m.edit_options(0, cx));
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Options);
            assert!(m.returning_to_install);
            assert!(m.security_fresh(), "Windows Security is still watched");
        });
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Install, "straight back to the summary");
            assert!(!m.returning_to_install);
        });

        // A switch was turned back on meanwhile: Windows Security comes first.
        act(&mut cx, &model, |m, cx| m.edit_options(0, cx));
        machine.set_security(SecurityStatus { real_time_protection: Switch::On, ..all_off() });
        wait_for(&cx, &model, "the new reading", |m| m.security_fresh() && !m.security_ok()).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security);

        // Going back instead walks the steps as usual.
        machine.set_security(all_off());
        wait_for(&cx, &model, "an all-off reading", AppModel::security_ok).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.edit_options(0, cx));
        act(&mut cx, &model, |m, cx| m.previous_step(cx));
        assert!(!read(&cx, &model, |m| m.returning_to_install));
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security);
        settle(&cx, &model).await;
    });
}

/// A start request (the command line, "Open with", desktop setup) that
/// arrives while startup recovery is still running waits for it, so the
/// saved draft resumes instead of being replaced.
#[test]
fn a_start_request_waits_for_startup_recovery() {
    run_model_test(async move |mut cx| {
        use crate::services::preparation::State;
        for (step, resumed) in [(None, true), (Some(Step::Security), false)] {
            let (temp, _, env) = fixture("model-start-during-recovery");
            let (package, _) = marking_package(&temp, 0);
            let (dir, _) = playbook::extract_into(&package, &env.paths.playbooks(), |_, _| {}).unwrap();
            let draft = InstallDraft {
                step: "options".into(),
                options: vec!["defender-disable".into()],
                playbook_dir: Some(dir.clone()),
                flow: Some("saved-flow".into()),
                preparation_restart_at: Some("2001-01-01T00:00:00Z".into()),
                ..InstallDraft::default()
            };
            save_draft(&env, draft.clone());
            // Another window holds the install record for a moment.
            let held = session::LaunchLock::acquire(&env.paths.session()).unwrap();
            let model = new_model(&mut cx, env.clone());
            assert!(read(&cx, &model, |m| m.recovering), "recovery outlasted the startup wait");
            act(&mut cx, &model, |m, cx| m.apply_start(Some(Page::Install), step, None, cx));
            assert!(read(&cx, &model, |m| m.page == Page::Home && !m.flow.active), "nothing is begun yet");
            settle(&cx, &model).await;
            assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(draft.clone()));
            drop(held);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering && m.flow.active).await;
            read(&cx, &model, |m| {
                assert_eq!(m.page, Page::Install);
                if resumed {
                    assert_eq!(m.flow.step, Step::Options);
                    assert_eq!(m.flow_id.as_deref(), Some("saved-flow"));
                    assert!(m.options.contains("defender-disable"));
                    assert_eq!(m.playbook.as_ref().map(|p| p.dir.clone()), Some(dir.clone()));
                    assert_eq!(m.preparation, State::Resumed);
                } else {
                    // A command-line step still takes precedence over the draft.
                    assert_eq!(m.flow.step, Step::Security);
                    assert_ne!(m.flow_id.as_deref(), Some("saved-flow"));
                }
            });
        }
    });
}

/// A page given at launch opens at once while startup recovery runs and
/// still wins over a resumed draft, unless the user has gone elsewhere
/// meanwhile: recovery's end never pulls them back to it.
#[test]
fn a_start_page_the_user_left_during_recovery_is_not_shown_again() {
    run_model_test(async move |mut cx| {
        for (page, draft, leave, expected) in
            [(Page::Installed, false, true, Page::Home), (Page::Settings, true, false, Page::Settings)]
        {
            let (_temp, _, env) = fixture("model-start-page-left");
            if draft {
                save_draft(
                    &env,
                    InstallDraft {
                        step: "options".into(),
                        flow: Some("saved-flow".into()),
                        ..InstallDraft::default()
                    },
                );
            }
            // Another window holds the install record for a moment.
            let held = session::LaunchLock::acquire(&env.paths.session()).unwrap();
            let model = new_model(&mut cx, env.clone());
            assert!(read(&cx, &model, |m| m.recovering), "recovery outlasted the startup wait");
            act(&mut cx, &model, |m, cx| m.apply_start(Some(page), None, None, cx));
            assert_eq!(read(&cx, &model, |m| m.page), page, "the page opens at once");
            if leave {
                act(&mut cx, &model, |m, cx| m.navigate(Page::Home, cx));
            }
            drop(held);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering && m.flow.active == draft).await;
            assert_eq!(read(&cx, &model, |m| m.page), expected, "{page:?}");
            settle(&cx, &model).await;
        }
    });
}
