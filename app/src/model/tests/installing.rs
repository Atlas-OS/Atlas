//! The review fixtures of the installing view and the completion window open
//! on the state they're named for, and restart nothing.

use crate::model::test_harness::{fixture, new_model, run_model_test};
use crate::model::{AppModel, Page, RunState, preview};
use crate::services::installer::{InstallOutcome, Phase};

#[test]
fn the_installing_fixtures_open_on_the_state_they_are_named_for() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("preview-installing");
        let mut shown = |name: &str, check: &dyn Fn(&AppModel)| {
            let model = new_model(&mut cx, env.clone());
            model.update(&mut cx, |m, _| {
                preview::apply(m, name);
                assert_eq!(m.page, Page::Install, "{name}");
                assert!(m.install_in_progress(), "{name}: the installing view covers the page");
                check(m);
            });
        };
        shown("installing-checking", &|m| assert_eq!(m.flow.run, RunState::Preparing));
        for (name, phase, progress) in [
            ("installing-preflight", Phase::Preflight, false),
            ("installing-staging", Phase::Staging, false),
            ("installing-applying", Phase::Applying, true),
            ("installing-finishing", Phase::Done, true),
        ] {
            shown(name, &|m| {
                assert_eq!((m.flow.run, m.attempt.phase), (RunState::Running, phase), "{name}");
                assert_eq!(m.attempt.plan_progress.is_some(), progress, "{name}");
                assert!(m.install_request().unwrap().restart, "{name}");
            });
        }
        shown("installing-manual", &|m| assert!(!m.install_request().unwrap().restart));
        shown("installing-output-error", &|m| assert!(m.attempt.output_problem.is_some()));
        let succeeded = RunState::Finished(InstallOutcome::Succeeded);
        shown("installing-countdown", &|m| {
            assert_eq!(m.flow.run, succeeded);
            assert!(m.restart_cancellable());
        });
        shown("installing-restart-error", &|m| {
            assert!(m.attempt.restart_problem.is_some());
            assert!(m.env.adapters.schedule_restart.as_ref()("preview").is_err(), "Try again is refused too");
        });
        shown("installing-restart-later", &|m| assert!(m.attempt.restart_cancelled));
        shown("installing-restart-off", &|m| {
            assert!(
                !m.restart_cancellable()
                    && !m.attempt.restart_cancelled
                    && m.attempt.restart_problem.is_none()
            );
            assert!(!m.install_request().unwrap().restart);
        });
        shown("installing-restart-others", &|m| assert!(m.restart_confirmation().is_some()));
        shown("installing-restarting", &|m| assert!(m.attempt.restart_requested));
    });
}

#[test]
fn the_completion_fixtures_open_on_the_state_they_are_named_for() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("preview-installed");
        for (name, kept) in [("installed", true), ("installed-defender-removed", false)] {
            let model = new_model(&mut cx, env.clone());
            model.update(&mut cx, |m, _| {
                preview::apply(m, name);
                assert_eq!(m.page, Page::Installed, "{name}");
                assert_eq!(m.kept_defender_recorded(), kept, "{name}");
                assert_eq!(m.installed_options().iter().any(|o| o == "defender-disable"), !kept, "{name}");
                assert!(!m.defender_not_restored() && !m.manual_driver_policy(), "{name}");
            });
        }
        let model = new_model(&mut cx, env.clone());
        model.update(&mut cx, |m, _| {
            preview::apply(m, "installed-defender-not-restored");
            assert_eq!(m.page, Page::Installed);
            assert!(m.defender_not_restored(), "the record kept Defender that Atlas's package removes");
        });
        let model = new_model(&mut cx, env.clone());
        model.update(&mut cx, |m, _| {
            preview::apply(m, "installed-manual-drivers");
            assert!(m.page == Page::Installed && m.manual_driver_policy());
        });
    });
}
