//! The restart countdown after a success, and every way it is stopped,
//! held or brought forward; and the restart Home offers while one is owed.

use std::path::Path;
use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::environment::RestartTiming;
use crate::model::test_harness::{
    act, fixture, gated_package, marking_package, new_model, read, run_model_test, settle, wait_for,
    walk_to_install,
};
use gpui::{AsyncApp, Entity};

use crate::model::test_harness::Machine;
use crate::model::{AppModel, CloseGuard, Environment, Page, RestartKind, RestartProblem, RunState};
use crate::services::atlas_state::AtlasState;
use crate::services::installer::InstallOutcome;
use crate::services::preparation::State;
use crate::services::session;
use crate::services::test_support::TempDir;

/// The state document an install that finished `minutes` from now writes.
fn installed_at(minutes: i64) -> AtlasState {
    let at = chrono::Local::now() + chrono::Duration::minutes(minutes);
    serde_json::from_value(serde_json::json!({
        "schemaVersion": 1,
        "installedVersion": "0.6.0",
        "installedAt": at.to_rfc3339(),
        "mode": "Fresh",
        "options": ["defender-disable"],
    }))
    .unwrap()
}

/// After Done on a success, Home says the PC still needs its restart and
/// offers it, from the launch record alone: a relaunched app offers it too,
/// and nothing of its own is saved. The installing view, which has its own
/// Restart now, never shows it.
#[test]
#[cfg(windows)]
fn home_offers_the_restart_a_finished_install_still_owes() {
    run_model_test(async move |mut cx| {
        let (temp, machine, mut env) = fixture("model-restart-owed");
        env.restart = RestartTiming {
            countdown: Duration::from_secs(30),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(300),
            ..RestartTiming::default()
        };
        // Arming writes the launch record, as the app's own arming does.
        env.adapters.arm_completion = Arc::new(|paths| {
            session::write_launcher(paths, Path::new(r"C:\Atlas\AtlasManager.exe")).map(|_| ())
        });
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());
        assert!(read(&cx, &model, |m| m.owed_restart().is_none()), "nothing installed yet");
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        // The installer records the finished install as it ends.
        *machine.state.lock().unwrap() = Some(installed_at(1));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the countdown", |m| m.restart_countdown().is_some()).await;
        assert!(read(&cx, &model, |m| m.owed_restart().is_none()), "the installing view has its own");

        // Restart later, then Done: Home offers the restart.
        act(&mut cx, &model, |m, cx| {
            m.cancel_restart(cx);
            m.cancel_flow(cx);
        });
        read(&cx, &model, |m| {
            assert_eq!(m.page, Page::Home);
            assert_eq!(m.owed_restart().cloned(), Some(Default::default()));
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);

        // Restart now asks Windows once, and again only once the request
        // has had its grace period without a restart.
        act(&mut cx, &model, |m, cx| m.restart_owed_now(cx));
        act(&mut cx, &model, |m, cx| m.restart_owed_now(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        assert!(read(&cx, &model, |m| m.owed_restart().is_some_and(|owed| owed.requested)));
        wait_for(&cx, &model, "the grace period to end", |m| {
            m.owed_restart().is_some_and(|owed| !owed.requested)
        })
        .await;

        // A refusal is shown, with the restart offered again.
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.schedule_restart = Arc::new(|_| anyhow::bail!("shutdown denied"));
            m.restart_owed_now(cx);
        });
        read(&cx, &model, |m| {
            let owed = m.owed_restart().unwrap();
            assert!(!owed.requested);
            assert!(matches!(owed.problem, Some(RestartProblem::Start { .. })));
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);

        // Only Home offers it.
        act(&mut cx, &model, |m, cx| m.navigate(Page::Settings, cx));
        assert!(read(&cx, &model, |m| m.owed_restart().is_none()));
        settle(&cx, &model).await;

        // A relaunched app finds it in the launch record.
        let relaunched = new_model(&mut cx, env.clone());
        assert!(read(&cx, &relaunched, |m| m.owed_restart().is_some()));
        settle(&cx, &relaunched).await;

        // No install recorded since the launch (it failed, or was abandoned):
        // no restart is owed.
        *machine.state.lock().unwrap() = Some(installed_at(-60 * 24));
        let failed = new_model(&mut cx, env);
        assert!(read(&cx, &failed, |m| m.owed_restart().is_none()));
    });
}

/// Cancelling a countdown stops its timer: a countdown begun straight after
/// asks Windows to restart once, not once per timer.
#[test]
#[cfg(windows)]
fn an_old_restart_timer_cannot_touch_a_newer_countdown() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-restart-timer");
        let timing = RestartTiming {
            countdown: Duration::from_millis(500),
            tick: Duration::from_millis(25),
            grace: Duration::from_millis(200),
            ..RestartTiming::default()
        };
        let env = Environment { restart: timing, ..env };
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert!(read(&cx, &model, |m| m.settings.restart_after_install && m.can_install()));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "a successful install", |m| {
            m.flow.run == RunState::Finished(InstallOutcome::Succeeded)
        })
        .await;

        // A new countdown begins while the first one's timer would still be
        // running, had cancelling not stopped it.
        act(&mut cx, &model, |m, cx| {
            m.cancel_restart(cx);
            assert!(m.attempt.restart_cancelled && m.restart_countdown().is_none());
            // The decline is shared with other windows; this countdown is a new one.
            std::fs::remove_file(session::restart_declined_path(m.session.as_ref().unwrap())).unwrap();
            m.begin_restart_countdown(cx);
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        wait_for(&cx, &model, "Windows to be asked", |m| m.attempt.restart_requested).await;
        wait_for(&cx, &model, "the grace period to end", |m| !m.attempt.restart_requested).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 1, "only the new countdown asked Windows");
        assert!(read(&cx, &model, |m| m.restart_countdown().is_none()));
    });
}

#[test]
#[cfg(windows)]
fn restart_now_asks_windows_at_once_and_the_request_cannot_be_taken_back() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-restart-now");
        let timing = RestartTiming {
            countdown: Duration::from_secs(30),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(300),
            ..RestartTiming::default()
        };
        let env = Environment { restart: timing, ..env };
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "a successful install", |m| {
            m.flow.run == RunState::Finished(InstallOutcome::Succeeded)
        })
        .await;
        assert!(read(&cx, &model, |m| m.restart_cancellable()));
        act(&mut cx, &model, |m, cx| m.cancel_restart(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);

        // "Restart now" asks Windows straight away; no second countdown.
        act(&mut cx, &model, |m, cx| m.restart_now(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        read(&cx, &model, |m| {
            assert!(m.attempt.restart_requested);
            assert!(m.restart_countdown().is_none());
            assert!(!m.restart_cancellable());
            assert!(!m.attempt.restart_cancelled);
        });
        // While Windows has the request, neither button can do anything.
        act(&mut cx, &model, |m, cx| m.cancel_restart(cx));
        act(&mut cx, &model, |m, cx| m.restart_now(cx));
        read(&cx, &model, |m| assert!(m.attempt.restart_requested && !m.attempt.restart_cancelled));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        // Windows did not go: the restart is offered again, not claimed.
        wait_for(&cx, &model, "the grace period to end", |m| !m.attempt.restart_requested).await;
        read(&cx, &model, |m| {
            assert!(m.restart_countdown().is_none());
            assert!(!m.attempt.restart_cancelled);
            assert!(m.attempt.restart_problem.is_none());
        });

        // A refusal is shown, with the restart offered again.
        act(&mut cx, &model, |m, cx| {
            m.env.adapters.schedule_restart = Arc::new(|_| anyhow::bail!("shutdown denied"));
            m.restart_now(cx);
        });
        read(&cx, &model, |m| {
            assert!(!m.attempt.restart_requested);
            assert!(m.restart_countdown().is_none());
            assert!(matches!(m.attempt.restart_problem, Some(RestartProblem::Start { .. })));
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
    });
}

/// Every window following an install counts down to its restart; "Restart
/// later" in any of them stops them all, and Done in the window that
/// declined does not bring the restart back.
#[test]
#[cfg(windows)]
fn restart_later_in_one_window_stops_every_window_following_the_install() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-restart-declined");
        let timing = RestartTiming {
            countdown: Duration::from_secs(1),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(300),
            ..RestartTiming::default()
        };
        let env = Environment { restart: timing, ..env };
        let gate = temp.path().join("gate");
        let package = gated_package(&temp, &gate);
        let first = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &first, &package).await;
        act(&mut cx, &first, |m, cx| m.next_step(cx));
        act(&mut cx, &first, |m, cx| m.start_install(cx));
        wait_for(&cx, &first, "the install to run", |m| m.flow.run == RunState::Running).await;
        // The app opened again while it runs follows the same install.
        let second = new_model(&mut cx, env.clone());
        wait_for(&cx, &second, "the second window to follow it", |m| m.flow.run == RunState::Running).await;
        std::fs::write(&gate, "").unwrap();
        let mut deadlines = Vec::new();
        for model in [&first, &second] {
            wait_for(&cx, model, "the success and its countdown", |m| m.restart_countdown().is_some()).await;
            deadlines.extend(read(&cx, model, |m| m.attempt.restart.map(|countdown| countdown.deadline)));
        }
        act(&mut cx, &first, |m, cx| m.cancel_restart(cx));
        act(&mut cx, &first, |m, cx| m.cancel_flow(cx));
        wait_for(&cx, &second, "the other countdown to stop", |m| m.restart_countdown().is_none()).await;
        // Past the later deadline, and the grace a restart request would have.
        let quiet_until = deadlines.into_iter().max().unwrap() + timing.grace;
        cx.background_executor().timer(quiet_until.saturating_duration_since(Instant::now())).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0, "no window restarted Windows");
        read(&cx, &second, |m| {
            assert!(m.attempt.restart_cancelled, "it says the restart was cancelled");
            assert!(!m.attempt.restart_requested);
        });
    });
}

/// The close prompt holds the restart countdown: nothing restarts while it
/// is open, Keep open starts the countdown again, and Close without
/// restarting still declines it for every window.
#[test]
#[cfg(windows)]
fn the_close_prompt_holds_the_restart_countdown() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-restart-held");
        let timing = RestartTiming {
            countdown: Duration::from_millis(300),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(300),
            ..RestartTiming::default()
        };
        let env = Environment { restart: timing, ..env };
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the countdown", |m| m.restart_countdown().is_some()).await;

        // The prompt is open past the deadline: nothing restarts under it.
        act(&mut cx, &model, |m, _| m.hold_restart());
        cx.background_executor().timer(timing.countdown * 2).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        read(&cx, &model, |m| {
            assert!(m.restart_cancellable());
            assert_eq!(m.close_guard(), CloseGuard::Restart);
        });

        // Keep open: the countdown starts again and runs out as usual.
        act(&mut cx, &model, |m, cx| m.resume_restart(cx));
        assert!(read(&cx, &model, |m| m.restart_countdown().is_some_and(|left| left > 0)));
        wait_for(&cx, &model, "Windows to be asked", |m| m.attempt.restart_requested).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);

        // Close without restarting, answered after the deadline, declines it.
        wait_for(&cx, &model, "the grace period to end", |m| !m.attempt.restart_requested).await;
        act(&mut cx, &model, |m, cx| m.begin_restart_countdown(cx));
        act(&mut cx, &model, |m, _| m.hold_restart());
        cx.background_executor().timer(timing.countdown * 2).await;
        act(&mut cx, &model, |m, cx| m.cancel_restart(cx));
        read(&cx, &model, |m| {
            assert!(m.attempt.restart_cancelled && m.restart_countdown().is_none());
            assert!(session::restart_declined(m.session.as_ref().unwrap()), "other windows are told");
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        settle(&cx, &model).await;
    });
}

/// A countdown that starts while nobody looks at the window runs a minute,
/// so there is time to notice and choose Restart later; one in front runs
/// the usual time. It's chosen once, as it starts.
#[test]
fn a_countdown_started_unseen_runs_longer() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("restart-unseen");
        let timing = RestartTiming {
            countdown: Duration::from_secs(10),
            background_countdown: Duration::from_secs(60),
            ..RestartTiming::default()
        };
        let model = new_model(&mut cx, Environment { restart: timing, ..env });
        act(&mut cx, &model, |m, cx| m.begin_restart_countdown(cx));
        assert_eq!(read(&cx, &model, |m| m.attempt.restart.unwrap().total), Duration::from_secs(10));
        act(&mut cx, &model, |m, cx| {
            m.set_window_active(false);
            m.begin_restart_countdown(cx);
        });
        assert_eq!(read(&cx, &model, |m| m.attempt.restart.unwrap().total), Duration::from_secs(60));
        // Coming back doesn't shorten it.
        act(&mut cx, &model, |m, _| m.set_window_active(true));
        assert_eq!(read(&cx, &model, |m| m.attempt.restart.unwrap().total), Duration::from_secs(60));
        act(&mut cx, &model, |m, _| m.hold_restart());
    });
}

/// Runs an install to its success with other people signed in from the
/// start, or nobody, and a countdown of `countdown`.
async fn installed_with_others(
    cx: &mut AsyncApp,
    name: &str,
    others: &[&str],
    countdown: Duration,
) -> (TempDir, Machine, Entity<AppModel>) {
    let (temp, machine, env) = fixture(name);
    *machine.others.lock().unwrap() = Some(others.iter().map(|name| name.to_string()).collect());
    let timing = RestartTiming {
        countdown,
        tick: Duration::from_millis(25),
        grace: Duration::from_millis(200),
        ..RestartTiming::default()
    };
    let env = Environment { restart: timing, ..env };
    let (package, _) = marking_package(&temp, 0);
    let model = new_model(cx, env);
    walk_to_install(cx, &model, &package).await;
    act(cx, &model, |m, cx| m.next_step(cx));
    act(cx, &model, |m, cx| m.start_install(cx));
    wait_for(cx, &model, "a successful install", |m| {
        m.flow.run == RunState::Finished(InstallOutcome::Succeeded)
    })
    .await;
    (temp, machine, model)
}

/// With someone else signed in, nothing counts down: Atlas asks, Don't
/// restart keeps the PC running with the restart still owed, and only an
/// explicit Restart anyway asks Windows.
#[test]
#[cfg(windows)]
fn a_restart_over_other_peoples_sessions_waits_for_the_user() {
    run_model_test(async move |mut cx| {
        let (_temp, machine, model) = installed_with_others(
            &mut cx,
            "model-restart-others",
            &["Alex", "Sam"],
            Duration::from_millis(200),
        )
        .await;
        read(&cx, &model, |m| {
            assert!(m.restart_countdown().is_none(), "no countdown while others are signed in");
            let asked = m.restart_confirmation().unwrap();
            assert_eq!(asked.kind, RestartKind::Install);
            assert_eq!(asked.people, ["Alex", "Sam"]);
        });
        settle(&cx, &model).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);

        act(&mut cx, &model, |m, cx| m.decline_restart_confirmation(cx));
        read(&cx, &model, |m| {
            assert!(m.restart_confirmation().is_none());
            assert!(m.restart_countdown().is_none() && !m.attempt.restart_requested);
        });

        // Restart now asks again rather than restarting.
        act(&mut cx, &model, |m, cx| m.restart_now(cx));
        assert!(read(&cx, &model, |m| m.restart_confirmation().is_some()));
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        act(&mut cx, &model, |m, cx| m.confirm_restart(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        assert!(read(&cx, &model, |m| m.attempt.restart_requested && m.restart_confirmation().is_none()));
        wait_for(&cx, &model, "the grace period to end", |m| !m.attempt.restart_requested).await;
    });
}

/// Someone who signs in while the countdown runs holds it at the end: the
/// countdown goes, and Atlas asks instead of restarting.
#[test]
#[cfg(windows)]
fn someone_signing_in_during_the_countdown_holds_the_restart() {
    run_model_test(async move |mut cx| {
        let (_temp, machine, model) =
            installed_with_others(&mut cx, "model-restart-others-later", &[], Duration::from_millis(300))
                .await;
        assert!(read(&cx, &model, |m| m.restart_countdown().is_some()));
        *machine.others.lock().unwrap() = Some(vec!["Alex".into()]);
        wait_for(&cx, &model, "the question", |m| m.restart_confirmation().is_some()).await;
        read(&cx, &model, |m| {
            assert!(m.restart_countdown().is_none());
            assert!(!m.attempt.restart_requested);
        });
        settle(&cx, &model).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
    });
}

/// A session list Windows won't give doesn't stop the restart: the
/// countdown was the warning, as before Atlas looked.
#[test]
#[cfg(windows)]
fn an_unreadable_session_list_does_not_hold_the_restart() {
    run_model_test(async move |mut cx| {
        let (temp, machine, env) = fixture("model-restart-others-unreadable");
        *machine.others.lock().unwrap() = None;
        let env = Environment {
            restart: RestartTiming {
                countdown: Duration::from_millis(200),
                tick: Duration::from_millis(25),
                grace: Duration::from_millis(200),
                ..RestartTiming::default()
            },
            ..env
        };
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "Windows to be asked", |m| m.attempt.restart_requested).await;
        assert!(read(&cx, &model, |m| m.restart_confirmation().is_none()));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        settle(&cx, &model).await;
    });
}

/// Get ready's restart and Home's Restart now ask the same question.
#[test]
#[cfg(windows)]
fn get_ready_and_home_ask_before_restarting_over_others() {
    run_model_test(async move |mut cx| {
        let (temp, machine, mut env) = fixture("model-restart-others-home");
        env.adapters.arm_completion = Arc::new(|paths| {
            session::write_launcher(paths, Path::new(r"C:\Atlas\AtlasManager.exe")).map(|_| ())
        });
        env.restart = RestartTiming {
            countdown: Duration::from_secs(30),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(200),
            ..RestartTiming::default()
        };
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        walk_to_install(&mut cx, &model, &package).await;

        // Get ready: the restart waits, and Don't restart leaves it owed.
        *machine.others.lock().unwrap() = Some(vec!["Alex".into()]);
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Reboot;
            m.restart_preparation(cx);
        });
        read(&cx, &model, |m| {
            assert_eq!(m.restart_confirmation().map(|asked| asked.kind), Some(RestartKind::Preparation));
            assert_eq!(m.preparation, State::Reboot);
        });
        act(&mut cx, &model, |m, cx| m.decline_restart_confirmation(cx));
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        act(&mut cx, &model, |m, cx| m.confirm_restart(cx));
        wait_for(&cx, &model, "the preparation restart", |m| m.preparation == State::Restarting).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        wait_for(&cx, &model, "the grace period to end", |m| m.preparation == State::Reboot).await;

        // Home: an install that owes its restart.
        *machine.others.lock().unwrap() = Some(Vec::new());
        act(&mut cx, &model, |m, cx| {
            m.preparation = State::Ready;
            m.preparation_problem = None;
            m.next_step(cx);
        });
        *machine.state.lock().unwrap() = Some(installed_at(1));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the countdown", |m| m.restart_countdown().is_some()).await;
        act(&mut cx, &model, |m, cx| {
            m.cancel_restart(cx);
            m.cancel_flow(cx);
        });
        assert!(read(&cx, &model, |m| m.owed_restart().is_some()));
        *machine.others.lock().unwrap() = Some(vec!["Sam".into()]);
        act(&mut cx, &model, |m, cx| m.restart_owed_now(cx));
        read(&cx, &model, |m| {
            assert_eq!(m.restart_confirmation().map(|asked| asked.kind), Some(RestartKind::Owed));
            assert!(!m.owed_restart().unwrap().requested);
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        act(&mut cx, &model, |m, cx| m.confirm_restart(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 2);
        assert!(read(&cx, &model, |m| m.owed_restart().unwrap().requested));
        settle(&cx, &model).await;
    });
}
