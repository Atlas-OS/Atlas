//! Closing while an install starts or runs, arming the completion window,
//! a launch refused because another window took the setup over or the
//! choices don't fit the package, and a retry that fails the same way.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use crate::environment::RestartTiming;
use crate::model::test_harness::{
    PATIENCE, act, fixture, gated_package, held, marking_package, new_model, passing, read, run_model_test,
    settle, wait_for, wait_on_disk, wait_until, walk_to_install,
};
use crate::model::{AppModel, CloseGuard, Environment, Preflight, RunState};
use crate::services::requirements::{CheckContext, CheckId};
use crate::services::session;
use crate::services::settings::{self, InstallDraft};

/// Closing asks according to what it would interrupt: nothing while the
/// final checks run (the install never starts), the running install (it
/// carries on), and the restart countdown (only this window keeps it).
#[test]
fn closing_is_guarded_by_what_it_would_interrupt() {
    run_model_test(async move |mut cx| {
        use crate::services::preparation::State;
        use std::sync::atomic::{AtomicBool, Ordering};
        let (temp, machine, env) = fixture("model-close-guard");
        let timing = RestartTiming {
            countdown: Duration::from_secs(30),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(300),
            ..RestartTiming::default()
        };
        let env = Environment { restart: timing, ..env };
        let gate = temp.path().join("gate");
        let package = gated_package(&temp, &gate);
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        // The setup has the protection switches off: closing would leave them so.
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::ProtectionOff);
        let left_off = read(&cx, &model, |m| m.protection_left_off().unwrap());
        assert_eq!(left_off.switches.len(), 4);

        // Windows preparation: closing waits while a restart is being saved,
        // and is free once Windows has the restart.
        for (state, guard) in [
            (State::Running { stage: Default::default(), completed: 0, total: 0 }, CloseGuard::Preparation),
            (State::WaitingExternal, CloseGuard::Preparation),
            (State::SavingRestart, CloseGuard::Wait),
            (State::Restarting, CloseGuard::None),
        ] {
            act(&mut cx, &model, |m, _| m.preparation = state.clone());
            assert_eq!(read(&cx, &model, AppModel::close_guard), guard, "{state:?}");
        }
        act(&mut cx, &model, |m, _| m.preparation = State::Ready);

        // The final checks: closing then stops them, and nothing launches.
        let open = Arc::new(AtomicBool::new(false));
        act(&mut cx, &model, |m, _| {
            let open = open.clone();
            m.env.adapters.run_check = Arc::new(move |id: CheckId, _: &CheckContext| {
                while !open.load(Ordering::SeqCst) {
                    std::thread::sleep(Duration::from_millis(10));
                }
                passing(id)
            });
        });
        wait_for(&cx, &model, "the install to be possible", AppModel::can_install).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::PreparingInstall);
        assert!(model.update(&mut cx, |m, cx| m.abandon_preparing(cx)));
        open.store(true, Ordering::SeqCst);
        cx.background_executor().timer(Duration::from_millis(500)).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Idle);
            assert!(m.session.is_none(), "nothing launched");
        });
        assert!(session::load(&env.paths.session()).unwrap().is_none());

        // A running install carries on without the window.
        wait_for(&cx, &model, "the install to be possible again", AppModel::can_install).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the install to run", |m| m.flow.run == RunState::Running).await;
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::Install);
        assert!(!model.update(&mut cx, |m, cx| m.abandon_preparing(cx)), "too late to call it off");

        // The countdown is this window's alone; once stopped, closing is free.
        std::fs::write(&gate, "").unwrap();
        wait_for(&cx, &model, "the countdown", |m| m.restart_countdown().is_some()).await;
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::Restart);
        act(&mut cx, &model, |m, cx| m.cancel_restart(cx));
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::None);
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
    });
}

/// Arming the completion window stages the app with Windows PowerShell;
/// it happens on the launch worker, once, and only for an install that
/// really started. Until it has, the launch is still being handed over,
/// and a confirmed close waits for it.
#[test]
fn the_completion_window_is_armed_off_the_windows_thread_for_a_started_install_only() {
    run_model_test(async move |mut cx| {
        let (temp, machine, mut env) = fixture("model-arm-completion");
        let arming = Arc::new(Mutex::new(None));
        let (release, released) = std::sync::mpsc::channel::<()>();
        let released = Mutex::new(released);
        let armed = machine.armed.clone();
        env.adapters.arm_completion = Arc::new({
            let arming = arming.clone();
            move |_| {
                *arming.lock().unwrap() = Some(std::thread::current().id());
                // Held until the test has looked, with a time limit, so arming
                // on the window's thread fails the test instead of hanging it.
                released.lock().unwrap().recv_timeout(PATIENCE).ok();
                *armed.lock().unwrap() += 1;
                Ok(())
            }
        });
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));

        // A launch the protocol refuses owes no completion window.
        std::fs::write(&env.paths.session().record, "{ not json").unwrap();
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the refusal", |m| m.flow.run == RunState::Idle).await;
        assert!(matches!(
            read(&cx, &model, |m| m.preflight_problem.clone()),
            Some(Preflight::RecordUnreadable { .. })
        ));
        assert!(!marker.exists());
        assert_eq!(*machine.armed.lock().unwrap(), 0);
        std::fs::remove_file(&env.paths.session().record).unwrap();
        // Checking again reads the record again.
        act(&mut cx, &model, |m, cx| m.run_checks(cx));

        wait_for(&cx, &model, "the install to be possible again", AppModel::can_install).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_until(&cx, "the arming", || arming.lock().unwrap().is_some()).await;
        let worker = arming.lock().unwrap().unwrap();
        assert_ne!(worker, std::thread::current().id(), "armed on the window's thread");
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Preparing, "the launch is reported once armed");
            assert!(m.launching(), "a close waits for the hand-off");
            assert_eq!(m.close_guard(), CloseGuard::Install);
        });
        release.send(()).unwrap();
        wait_for(&cx, &model, "the launch to answer", |m| !m.launching()).await;
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert_eq!(*machine.armed.lock().unwrap(), 1);
        settle(&cx, &model).await;
    });
}

/// Another window began a setup of its own: the install refuses, as often
/// as it is asked, without touching that window's draft, and Start over
/// takes the setup back here, starting it from nothing.
#[test]
fn a_setup_another_window_took_over_is_refused_each_time_until_started_over() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-taken-over");
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        // Under the settings lock, so a save this window has in flight lands first.
        let foreign = InstallDraft {
            step: "options".into(),
            flow: Some("another-window".into()),
            ..InstallDraft::default()
        };
        settings::modify(&env.paths.settings(), settings::LOCK_WAIT, |doc| doc.draft = Some(foreign.clone()))
            .unwrap();
        for attempt in 1..=2 {
            wait_for(&cx, &model, "the install to be possible", AppModel::can_install).await;
            act(&mut cx, &model, |m, cx| m.start_install(cx));
            wait_for(&cx, &model, "the refusal", |m| m.flow.run == RunState::Idle).await;
            read(&cx, &model, |m| {
                assert_eq!(m.preflight_problem, Some(Preflight::TakenOver));
                assert_eq!(m.preflight_epoch, attempt, "each refusal is news");
                assert!(m.own_session.is_none() && m.session.is_none());
            });
        }
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(foreign));
        assert!(!marker.exists());

        act(&mut cx, &model, |m, cx| {
            m.acknowledge_security(true, cx);
            assert!(m.security_acknowledged());
            m.begin_install(cx);
            assert!(!m.security_acknowledged(), "a confirmation belongs to the flow it was given in");
        });
        let mine = read(&cx, &model, |m| m.flow_id.clone());
        wait_on_disk(&cx, &env, "the setup to be taken back", |s| {
            s.draft.as_ref().is_some_and(|draft| draft.flow == mine)
        })
        .await;
    });
}

/// Choices the package's pages don't accept, here two answers to one
/// question, refuse the install before the final checks begin: the
/// installer would refuse them only once protection is off.
#[test]
fn choices_the_package_does_not_accept_refuse_the_install_at_once() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-invalid-choices");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        wait_for(&cx, &model, "the install to be possible", AppModel::can_install).await;
        act(&mut cx, &model, |m, cx| {
            m.options.extend(["defender-enable", "defender-disable"].map(String::from));
            m.start_install(cx);
            assert_eq!(m.flow.run, RunState::Idle, "the final checks never began");
            assert!(matches!(m.preflight_problem, Some(Preflight::InvalidOptions { .. })));
        });
        settle(&cx, &model).await;
    });
}

/// An unfinished install keeps the choices it began with, so one begun
/// before its package gained a required page starts without an answer to
/// that page. The same choices refuse a fresh install.
#[test]
fn a_resumed_install_starts_without_an_answer_to_a_page_added_since() {
    run_model_test(async move |mut cx| {
        use crate::model::Step;
        use crate::model::test_harness::ps_literal;
        use crate::services::atlas_state::InstallIdentity;
        use crate::services::test_support::apbx;
        let (temp, machine, env) = fixture("model-resumed-choices");
        let marker = temp.path().join("front-door-ran.txt");
        let body = format!("Set-Content -LiteralPath {} -Value 'ran'\r\nexit 0", ps_literal(&marker));
        let mut contents = apbx::with_front_door("0.6.0", &body);
        // A second required question, the keyboard page's kind.
        contents.entries[0].data = concat!(
            "<Playbook><Version>0.6.0</Version><SupportedBuilds><string>26100</string></SupportedBuilds>",
            "<FeaturePages><RadioPage DefaultOption=\"defender-enable\"><Options>",
            "<RadioOption><Name>defender-enable</Name><Text>Keep Defender</Text></RadioOption>",
            "<RadioOption><Name>defender-disable</Name><Text>Remove Defender</Text></RadioOption>",
            "</Options></RadioPage><RadioPage DefaultOption=\"keyboard-single\"><Options>",
            "<RadioOption><Name>keyboard-single</Name><Text>One layout</Text></RadioOption>",
            "<RadioOption><Name>keyboard-selector</Name><Text>Layout selector</Text></RadioOption>",
            "</Options></RadioPage></FeaturePages></Playbook>"
        )
        .into();
        let package = apbx::write(&temp.path().join("package.apbx"), &contents);
        let model = new_model(&mut cx, env);
        act(&mut cx, &model, |m, cx| {
            m.begin_install(cx);
            m.preparation = crate::services::preparation::State::Ready;
        });
        act(&mut cx, &model, |m, cx| m.load_playbook_file(package, cx));
        wait_for(&cx, &model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete())
            .await;
        for _ in 0..3 {
            act(&mut cx, &model, |m, cx| m.next_step(cx));
        }
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security, "two screens of choices");
        wait_for(&cx, &model, "a Windows Security reading", |m| m.security_fresh()).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        wait_for(&cx, &model, "the install to be possible", AppModel::can_install).await;
        let saved = vec!["defender-enable".to_string()];
        act(&mut cx, &model, |m, cx| {
            m.options.retain(|name| saved.contains(name));
            m.start_install(cx);
            assert_eq!(m.flow.run, RunState::Idle, "a fresh install answers every page");
            assert!(matches!(m.preflight_problem, Some(Preflight::InvalidOptions { .. })));
        });
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Resume("0.6.0".into(), held(saved)));
        act(&mut cx, &model, |m, cx| {
            m.start_install(cx);
            assert_eq!(m.flow.run, RunState::Preparing, "the resumed install goes on to the final checks");
            assert!(m.preflight_problem.is_none());
        });
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert!(marker.exists(), "the front door ran");
        settle(&cx, &model).await;
    });
}

/// A retry of an unfinished install that stops on the error the attempt
/// before it stopped on is told apart from a new failure, past a visit to
/// another step and a retry the final checks refused. A fresh install that
/// fails twice is not, as its own advice already leads to a report. The
/// result names the app Windows kept, and offers Windows Security while a
/// switch reads off, even with Atlas's package that removes Defender
/// installed; once there is nothing left to turn back on, it doesn't.
#[test]
fn a_retry_that_stops_on_the_same_error_is_told_apart_even_past_a_refusal() {
    run_model_test(async move |mut cx| {
        use crate::model::Step;
        use crate::model::test_harness::all_off;
        use crate::services::atlas_state::InstallIdentity;
        use crate::services::legacy_choices::Facts;
        use crate::services::security::{SecurityStatus, Switch};
        use crate::services::test_support::apbx;
        // What the result on screen says to do.
        let advice = |m: &AppModel| match m.flow.run {
            RunState::Finished(outcome) => outcome.advice(&m.attempt_facts()),
            run => panic!("no result: {run:?}"),
        };
        let (temp, machine, env) = fixture("model-repeated-failure");
        let body = concat!(
            "Write-Host '[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...'\r\n",
            "Write-Host '[2026-10-28 17:26:02] [-] [ERROR] AppX removal failed for ''MSTeams*'': 1 installed package(s) remain registered.'\r\n",
            "Write-Host '[2026-10-28 17:26:05] [-] [ERROR] The AppX removal plan failed after cleanup: MSTeams*: 1 installed package(s) remain registered. | At C:\\Phases\\Invoke-AppxSupportPhase.ps1:86 char:5 +     throw +     ~~~~~'\r\n",
            "exit 1"
        );
        let error =
            "The AppX removal plan failed after cleanup: MSTeams*: 1 installed package(s) remain registered.";
        let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", body));
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));

        // A fresh install has nothing to repeat, even when it fails the same way twice.
        for failure in ["the first failure", "the fresh install's second failure"] {
            wait_for(&cx, &model, "the install to be possible", AppModel::can_install).await;
            act(&mut cx, &model, |m, cx| m.start_install(cx));
            wait_for(&cx, &model, failure, |m| matches!(m.flow.run, RunState::Finished(_))).await;
            read(&cx, &model, |m| {
                assert_eq!(m.attempt.last_error(), Some(error), "without the script position");
                assert!(!m.attempt.repeated(), "{failure}");
                assert_eq!(m.attempt.unremoved_apps(), ["MSTeams"]);
                assert!(!m.defender_removed());
                assert_eq!(advice(m), crate::t!("outcome-failed-applying"), "{failure}");
                assert!(m.result_offers_windows_security());
            });
        }
        // The installer now holds the install to the choices it began with.
        let options = read(&cx, &model, |m| m.session.as_ref().unwrap().request.options.clone());
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Resume("0.6.0".into(), held(options)));

        // Leaving the result for another step and coming back starts a new attempt.
        act(&mut cx, &model, |m, cx| {
            m.set_step(Step::Security, cx);
            m.next_step(cx);
        });
        read(&cx, &model, |m| {
            assert_eq!((m.flow.step, m.flow.run), (Step::Install, RunState::Idle));
            assert!(m.session.is_none() && m.attempt.log.is_empty(), "the result is gone");
            assert_eq!(m.attempt.earlier_error.as_deref(), Some(error), "kept past another step");
        });

        // Protection turned back on refuses the retry at the final checks.
        machine.set_security(SecurityStatus { real_time_protection: Switch::On, ..all_off() });
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the refusal", |m| {
            m.flow.run == RunState::Idle && m.preflight_problem.is_some()
        })
        .await;
        read(&cx, &model, |m| {
            assert!(matches!(m.preflight_problem, Some(Preflight::Changed { .. })));
            assert_eq!(m.attempt.earlier_error.as_deref(), Some(error), "kept past the refusal");
        });

        // Atlas 0.5's package that removes Defender is installed, but Defender
        // came back through its updates, and its switches read off.
        *machine.facts.lock().unwrap() = Facts {
            packages: vec!["Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~0.5.0.0".into()],
            ..Facts::default()
        };
        machine.set_security(all_off());
        wait_for(&cx, &model, "the install to be possible again", AppModel::can_install).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the repeated failure", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        read(&cx, &model, |m| {
            assert!(m.attempt.repeated(), "the same error again");
            assert_eq!(m.attempt.unremoved_apps(), ["MSTeams"]);
            assert!(!m.defender_removed(), "its switches are off");
            assert_eq!(advice(m), crate::t!("outcome-failed-repeated-apps", apps = "MSTeams"));
            assert!(m.result_offers_windows_security());
        });

        // With that package and every switch back on, or with Defender gone,
        // there is nothing left to turn back on.
        let all_on = SecurityStatus {
            tamper_protection: Switch::On,
            real_time_protection: Switch::On,
            cloud_delivered: Switch::On,
            sample_submission: Switch::On,
            defender_present: true,
        };
        for (status, what) in [
            (all_on, "every switch on"),
            (SecurityStatus { defender_present: false, ..all_off() }, "no Defender"),
        ] {
            machine.set_security(status);
            wait_for(&cx, &model, what, |m| m.security == status).await;
            read(&cx, &model, |m| {
                assert!(m.defender_removed(), "{what}");
                assert_eq!(
                    advice(m),
                    crate::t!("outcome-failed-repeated-apps-defender-removed", apps = "MSTeams"),
                    "{what}"
                );
                assert!(!m.result_offers_windows_security(), "{what}");
            });
        }
        settle(&cx, &model).await;
    });
}

/// Closing during a setup asks only while a switch actually reads off:
/// not with every switch on, without Defender, or with only unreadable ones.
#[test]
fn closing_with_protection_off_asks_only_while_a_switch_reads_off() {
    run_model_test(|mut cx| async move {
        use crate::model::test_harness::all_off;
        use crate::services::security::{SecurityStatus, Switch};
        let (_temp, _, env) = fixture("model-close-protection");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(crate::model::Step::Security, cx));
        let all_on = SecurityStatus {
            tamper_protection: Switch::On,
            real_time_protection: Switch::On,
            cloud_delivered: Switch::On,
            sample_submission: Switch::On,
            defender_present: true,
        };
        for (reading, guard) in [
            (SecurityStatus { tamper_protection: Switch::Off, ..all_on }, CloseGuard::ProtectionOff),
            (all_on, CloseGuard::None),
            (SecurityStatus { defender_present: false, ..all_off() }, CloseGuard::None),
            (SecurityStatus { tamper_protection: Switch::Unknown, ..all_on }, CloseGuard::None),
        ] {
            act(&mut cx, &model, |m, _| m.security = reading);
            assert_eq!(read(&cx, &model, AppModel::close_guard), guard, "{reading:?}");
        }
        // Before the desktop exists, closing ends setup anyway.
        act(&mut cx, &model, |m, _| {
            m.security = all_off();
            m.before_desktop = true;
        });
        assert_eq!(read(&cx, &model, AppModel::close_guard), CloseGuard::None);
        settle(&cx, &model).await;
    });
}
