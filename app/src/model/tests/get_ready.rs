//! What Get ready does by itself: it starts updating once nothing else waits,
//! carries on after Atlas's own restart, counts down to the restart updating
//! needs, and moves on to Your choices once it's done. And the evidence that
//! Windows here was used before, which Home reads.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use gpui::{AsyncApp, Entity};

use crate::environment::{RestartTiming, RunPreparation};
use crate::model::test_harness::{
    Machine, act, fixture, model_as_started, new_model, package_of, read, run_model_test, save_draft, settle,
    wait_for,
};
use crate::model::{AppModel, Environment, Page, RestartKind, Step};
use crate::services::atlas_state::InstallIdentity;
use crate::services::iso::StagedDrivers;
use crate::services::preparation::{Drivers, State};
use crate::services::requirements::{CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::settings::InstallDraft;
use crate::services::test_support::TempDir;
use crate::services::windows_installation::Evidence;

/// The worker's last report and the state a run ends in.
fn ending(status: &str, stage: &str) -> serde_json::Value {
    serde_json::json!({ "schema": 1, "status": status, "stage": stage, "completed": 0, "total": 0 })
}

/// A worker that ends its runs in `outcomes`, in turn, the last one for every
/// run after, after reporting update work so a restart it asks for is real.
/// `runs` counts them.
fn worker(outcomes: Vec<State>, runs: Arc<Mutex<usize>>) -> Arc<RunPreparation> {
    Arc::new(move |_, _, _, mut report| {
        let run = {
            let mut runs = runs.lock().unwrap();
            *runs += 1;
            *runs
        };
        let state = outcomes[(run - 1).min(outcomes.len() - 1)].clone();
        let status = match &state {
            State::Ready => "complete",
            State::Reboot => "reboot",
            State::Cancelled => "cancelled",
            State::Network => "network",
            _ => "failed",
        };
        report(serde_json::from_value(ending("running", "windows-install")).unwrap());
        let mut last = ending(status, "windows-install");
        if state == State::Failed {
            last["activity"] = serde_json::json!({ "failureMessage": "worker text" });
        }
        report(serde_json::from_value(last).unwrap());
        Ok(state)
    })
}

/// A machine whose Get ready acts by itself, with a worker that ends its
/// runs in `outcomes` (see [`worker`]).
fn automatic(name: &str, outcomes: Vec<State>) -> (TempDir, Machine, Environment, Arc<Mutex<usize>>) {
    let (temp, machine, mut env) = fixture(name);
    let runs = Arc::new(Mutex::new(0));
    env.automatic_get_ready = true;
    env.adapters.run_preparation = worker(outcomes, runs.clone());
    (temp, machine, env, runs)
}

/// Begins the flow, then gives Get ready its package.
async fn begin_with_package(cx: &mut AsyncApp, model: &Entity<AppModel>, temp: &TempDir) {
    wait_for(cx, model, "startup recovery", |m| !m.recovering).await;
    act(cx, model, |m, cx| m.begin_install(cx));
    let package = package_of(temp, "0.6.0");
    act(cx, model, |m, cx| m.load_package_file(package, cx));
}

/// Lets anything already started by itself show, before asserting that
/// nothing did.
async fn a_moment(cx: &AsyncApp) {
    cx.background_executor().timer(Duration::from_millis(300)).await;
}

#[test]
fn get_ready_updates_by_itself_once_nothing_else_waits_then_moves_on() {
    run_model_test(|mut cx| async move {
        let (temp, _, env, runs) = automatic("ready-by-itself", vec![State::Ready]);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        // Without the package, nothing starts: the install would have nothing to run.
        wait_for(&cx, &model, "the checks", |m| m.checks_complete()).await;
        a_moment(&cx).await;
        assert_eq!(*runs.lock().unwrap(), 0, "updating waits for the package");
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Idle);

        let package = package_of(&temp, "0.6.0");
        act(&mut cx, &model, |m, cx| m.load_package_file(package, cx));
        wait_for(&cx, &model, "Your choices", |m| m.flow.step == Step::Options).await;
        assert_eq!(*runs.lock().unwrap(), 1, "one run, started by itself");
        read(&cx, &model, |m| {
            assert!(m.preparation.ready());
            assert_eq!(m.page, Page::Install);
        });

        // Back on Get ready on purpose: it stays, however often it checks again.
        act(&mut cx, &model, |m, cx| m.previous_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Ready);
        act(&mut cx, &model, |m, cx| m.run_checks(cx));
        wait_for(&cx, &model, "the checks", |m| m.checks_complete()).await;
        a_moment(&cx).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Ready, "a visit made on purpose doesn't move on");
            assert!(m.ready_to_continue());
        });
        assert_eq!(*runs.lock().unwrap(), 1, "updating done stays done");
        settle(&cx, &model).await;
    });
}

/// Checks that pass with a note, or wait for the user to confirm one, leave
/// Get ready showing them: the user may want to read them first.
#[test]
fn a_check_with_a_note_keeps_get_ready_from_moving_on() {
    run_model_test(|mut cx| async move {
        let (temp, _, mut env, runs) = automatic("ready-note", vec![State::Ready]);
        env.adapters.run_check = Arc::new(|id, _| match id {
            CheckId::Activation => {
                CheckResult { id, verdict: Verdict::Warn, detail: CheckDetail::ActivationMissing }
            }
            _ => crate::model::test_harness::passing(id),
        });
        let model = new_model(&mut cx, env);
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "updating to finish and the checks after it", |m| {
            m.preparation.ready() && m.checks_complete()
        })
        .await;
        a_moment(&cx).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Ready);
            assert!(m.ready_to_continue(), "Continue is the user's");
        });
        assert_eq!(*runs.lock().unwrap(), 1, "a note doesn't hold updating back");
        settle(&cx, &model).await;
    });
}

/// A run that fails offers Try again rather than trying again by itself.
/// A run the user stopped stays stopped until they resume it, even when a
/// choice starts updating over; resuming lets Get ready go on by itself.
#[test]
fn a_failed_or_stopped_run_is_not_started_again_by_itself() {
    run_model_test(|mut cx| async move {
        let outcomes = vec![State::Failed, State::Cancelled, State::Ready];
        let (temp, _, env, runs) = automatic("ready-no-loop", outcomes);
        let model = new_model(&mut cx, env);
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the failed run and the checks after it", |m| {
            m.preparation == State::Failed && m.checks_complete()
        })
        .await;
        a_moment(&cx).await;
        assert_eq!(*runs.lock().unwrap(), 1, "a failure isn't retried by itself");

        // Try again: this run is stopped by the user.
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "the stopped run", |m| {
            m.preparation == State::Cancelled && m.checks_complete()
        })
        .await;
        assert!(read(&cx, &model, AppModel::updates_held));
        // A new driver choice starts updating over, but not while it's stopped.
        act(&mut cx, &model, |m, cx| m.set_drivers(Drivers::Manual, cx));
        a_moment(&cx).await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Idle);
            assert!(!m.updates_start_by_themselves());
        });
        assert_eq!(*runs.lock().unwrap(), 2);

        // Resume updates: it runs, finishes, and Get ready moves on.
        act(&mut cx, &model, |m, cx| m.prepare_windows(cx));
        wait_for(&cx, &model, "Your choices", |m| m.flow.step == Step::Options).await;
        assert_eq!(*runs.lock().unwrap(), 3);
        assert!(!read(&cx, &model, AppModel::updates_held));
        settle(&cx, &model).await;
    });
}

/// An ISO that left the driver choice until after sign-in holds updating
/// back until it's made; making it starts updating.
#[test]
fn updating_waits_for_a_driver_choice_the_iso_left_open() {
    run_model_test(|mut cx| async move {
        let (temp, _, env, runs) = automatic("ready-drivers", vec![State::Ready]);
        let model = new_model(&mut cx, env);
        act(&mut cx, &model, |m, _| m.iso_drivers = Some(StagedDrivers::ChooseAfterSignIn));
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the package and the checks", |m| m.package.is_some() && m.checks_complete())
            .await;
        a_moment(&cx).await;
        read(&cx, &model, |m| {
            assert!(m.driver_choice_required());
            assert_eq!(m.preparation, State::Idle);
        });
        assert_eq!(*runs.lock().unwrap(), 0);
        act(&mut cx, &model, |m, cx| m.set_drivers(Drivers::Automatic, cx));
        wait_for(&cx, &model, "Your choices", |m| m.flow.step == Step::Options).await;
        assert_eq!(*runs.lock().unwrap(), 1);
        settle(&cx, &model).await;
    });
}

/// After Atlas's own restart, the resumed draft carries on updating without
/// a click. A restart Windows asks for again straight after, with no update
/// work between, is named, not made again.
#[test]
fn after_atlas_restart_updating_carries_on_by_itself() {
    run_model_test(|mut cx| async move {
        let (temp, _, mut env, runs) = automatic("ready-resumed", vec![State::Ready]);
        let package = package_of(&temp, "0.6.0");
        let (dir, _) =
            crate::services::package::extract_into(&package, &env.paths.packages(), |_, _| {}).unwrap();
        // A restart asked for long before this boot: Windows has restarted since.
        let draft = InstallDraft {
            step: "ready".into(),
            package_dir: Some(dir),
            flow: Some("before-restart".into()),
            preparation_restart_at: Some("2001-01-01T00:00:00Z".into()),
            ..InstallDraft::default()
        };
        save_draft(&env, draft.clone());
        let model = model_as_started(&mut cx, env.clone());
        wait_for(&cx, &model, "Your choices", |m| m.flow.step == Step::Options).await;
        assert_eq!(*runs.lock().unwrap(), 1, "it carried on without a click");
        settle(&cx, &model).await;

        // The same, where the run that carries on only looked, and Windows
        // asked for another restart.
        let marker = Arc::new(Mutex::new(0));
        let count = marker.clone();
        env.adapters.run_preparation = Arc::new(move |_, _, _, mut report| {
            *count.lock().unwrap() += 1;
            report(serde_json::from_value(ending("running", "windows-search")).unwrap());
            report(serde_json::from_value(ending("reboot", "windows-search")).unwrap());
            Ok(State::Reboot)
        });
        save_draft(&env, draft);
        let model = model_as_started(&mut cx, env);
        wait_for(&cx, &model, "the run after the restart", |m| {
            matches!(m.preparation, State::RestartPersists { .. })
        })
        .await;
        assert_eq!(*marker.lock().unwrap(), 1);
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()), "nothing counts down to it");
        settle(&cx, &model).await;
    });
}

/// Fast restart timings for a countdown a test can watch end.
fn quick(env: &mut Environment) {
    env.restart = RestartTiming {
        preparation: Duration::from_millis(400),
        tick: Duration::from_millis(25),
        grace: Duration::from_secs(30),
        ..RestartTiming::default()
    };
}

/// Updating that needs a restart counts down to it, then restarts: the
/// draft and recovery are in place first. Not now stops the countdown and
/// leaves Restart now.
#[test]
fn a_restart_updating_needs_counts_down_and_not_now_stops_it() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env, _) = automatic("ready-countdown", vec![State::Reboot]);
        quick(&mut env);
        let model = new_model(&mut cx, env.clone());
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the countdown", |m| m.preparation_countdown().is_some()).await;
        assert!(
            read(&cx, &model, |m| m.preparation_restart_at.is_some()),
            "the draft says a restart is owed"
        );
        wait_for(&cx, &model, "the restart", |m| m.preparation == State::Restarting).await;
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
        settle(&cx, &model).await;

        // Not now, in another flow that needs a restart.
        let (temp, machine, mut env, _) = automatic("ready-countdown-not-now", vec![State::Reboot]);
        quick(&mut env);
        let model = new_model(&mut cx, env);
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the countdown", |m| m.preparation_countdown().is_some()).await;
        // Only this window keeps the countdown, so closing asks about it, and
        // holding it for the question stops it until the question goes away.
        read(&cx, &model, |m| assert_eq!(m.close_guard(), crate::model::CloseGuard::PreparationRestart));
        act(&mut cx, &model, |m, _| m.hold_preparation_countdown());
        read(&cx, &model, |m| assert!(m.preparation_countdown().is_none(), "held while asked"));
        act(&mut cx, &model, |m, cx| m.resume_preparation_countdown(cx));
        read(&cx, &model, |m| assert!(m.preparation_countdown().is_some(), "counting again"));
        act(&mut cx, &model, |m, cx| m.decline_preparation_restart(cx));
        read(&cx, &model, |m| assert_ne!(m.close_guard(), crate::model::CloseGuard::PreparationRestart));
        cx.background_executor().timer(Duration::from_millis(800)).await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Reboot, "Restart now is still offered");
            assert!(m.preparation_countdown().is_none());
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        settle(&cx, &model).await;
    });
}

/// Only Get ready counts down to the restart updating needs. Leaving it for
/// another page, a running ISO or USB job, or Restart automatically turned
/// off stops the countdown as Not now does, and leaves Restart now, which
/// waits for the media job too.
#[test]
fn leaving_get_ready_a_media_job_or_the_setting_stops_the_countdown() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env, _) = automatic("ready-countdown-leave", vec![State::Reboot]);
        quick(&mut env);
        let model = new_model(&mut cx, env);
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the countdown", |m| m.preparation_countdown().is_some()).await;
        // Past the end of the countdown, on another page.
        let past_the_end = Duration::from_millis(800);
        act(&mut cx, &model, |m, cx| m.navigate(Page::Home, cx));
        cx.background_executor().timer(past_the_end).await;
        read(&cx, &model, |m| {
            assert_eq!(m.preparation, State::Reboot, "the restart is still owed");
            assert!(m.preparation_countdown().is_none());
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0, "nothing restarts away from Get ready");
        act(&mut cx, &model, |m, cx| m.navigate(Page::Install, cx));
        a_moment(&cx).await;
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()), "Restart now is offered");

        // An ISO or USB job, which a restart would break off.
        act(&mut cx, &model, |m, cx| m.resume_preparation_countdown(cx));
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_some()));
        act(&mut cx, &model, |m, _| {
            m.iso_busy = true;
            m.usb_busy = true;
        });
        cx.background_executor().timer(past_the_end).await;
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()));
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        a_moment(&cx).await;
        assert_eq!(read(&cx, &model, |m| m.preparation.clone()), State::Reboot);
        assert_eq!(*machine.scheduled.lock().unwrap(), 0, "Restart now waits for the media job");
        act(&mut cx, &model, |m, _| {
            m.iso_busy = false;
            m.usb_busy = false;
        });

        // Restart automatically turned off while it counts down.
        act(&mut cx, &model, |m, cx| m.resume_preparation_countdown(cx));
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_some()));
        act(&mut cx, &model, |m, cx| m.set_restart_after_install(false, cx));
        cx.background_executor().timer(past_the_end).await;
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()));
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        settle(&cx, &model).await;
    });
}

/// Nothing counts down with Restart automatically off, nor while someone
/// else is signed in: Restart now asks first, as it always has.
#[test]
fn no_countdown_with_automatic_restart_off_or_others_signed_in() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env, _) = automatic("ready-countdown-off", vec![State::Reboot]);
        quick(&mut env);
        let model = new_model(&mut cx, env);
        act(&mut cx, &model, |m, cx| m.set_restart_after_install(false, cx));
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the restart to be owed", |m| {
            m.preparation == State::Reboot && m.preparation_restart_at.is_some()
        })
        .await;
        a_moment(&cx).await;
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()));
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        settle(&cx, &model).await;

        let (temp, machine, mut env, _) = automatic("ready-countdown-others", vec![State::Reboot]);
        quick(&mut env);
        *machine.others.lock().unwrap() = Some(vec!["Alex".into()]);
        let model = new_model(&mut cx, env);
        begin_with_package(&mut cx, &model, &temp).await;
        wait_for(&cx, &model, "the restart to be owed", |m| {
            m.preparation == State::Reboot && m.preparation_restart_at.is_some()
        })
        .await;
        a_moment(&cx).await;
        assert!(read(&cx, &model, |m| m.preparation_countdown().is_none()), "nothing counts down");
        act(&mut cx, &model, |m, cx| m.restart_preparation(cx));
        let asked = read(&cx, &model, |m| m.restart_confirmation().map(|asked| asked.kind));
        assert_eq!(asked, Some(RestartKind::Preparation), "Restart now asks first");
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        settle(&cx, &model).await;
    });
}

/// Windows that shows signs of earlier use is told apart only on a PC
/// without Atlas, and never where Atlas's own media has just installed it.
#[test]
fn windows_looks_used_only_on_a_pc_without_atlas_that_its_media_did_not_install() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, mut env) = fixture("ready-used-windows");
        env.adapters.read_windows_installation =
            Arc::new(|| Evidence { age_days: Some(400), desktop_apps: 12 });
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the evidence", |m| m.windows_installation.is_some()).await;
        assert!(read(&cx, &model, AppModel::windows_looks_used));
        act(&mut cx, &model, |m, _| m.before_desktop = true);
        assert!(!read(&cx, &model, AppModel::windows_looks_used), "set up before the desktop");
        act(&mut cx, &model, |m, _| {
            m.before_desktop = false;
            m.staged_iso_setup = true;
        });
        assert!(!read(&cx, &model, AppModel::windows_looks_used), "staged by an Atlas ISO");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        act(&mut cx, &model, |m, _| {
            m.staged_iso_setup = false;
            m.refresh_atlas_state();
        });
        assert!(!read(&cx, &model, AppModel::windows_looks_used), "Atlas is installed");

        // The harness's own Windows is new.
        let (_temp, _, env) = fixture("ready-new-windows");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "the evidence", |m| m.windows_installation.is_some()).await;
        assert!(!read(&cx, &model, AppModel::windows_looks_used));
    });
}
