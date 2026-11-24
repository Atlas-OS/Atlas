//! What Windows Security does by itself: it opens Windows Security at the
//! switches, moves on to Install once every switch reads off, and is passed
//! over when there's nothing to turn off. It never turns a switch off.

use std::cell::Cell;
use std::path::Path;
use std::rc::Rc;
use std::time::Duration;

use gpui::{AsyncApp, Entity, Subscription};

use crate::model::test_harness::{
    Machine, act, all_off, fixture, new_model, package_of, read, run_model_test, settle, wait_for,
};
use crate::model::{AppModel, Environment, ModelEvent, Page, Step};
use crate::services::security::{SecurityStatus, Switch};
use crate::services::test_support::TempDir;

/// A machine whose Windows Security step acts by itself, reading `security`.
fn automatic(name: &str, security: SecurityStatus) -> (TempDir, Machine, Environment) {
    let (temp, machine, mut env) = fixture(name);
    machine.set_security(security);
    env.automatic_security = true;
    (temp, machine, env)
}

/// Tamper Protection off and the other switches still on.
fn some_on() -> SecurityStatus {
    SecurityStatus {
        real_time_protection: Switch::On,
        cloud_delivered: Switch::On,
        sample_submission: Switch::On,
        ..all_off()
    }
}

/// Walks a fresh model to the last screen of Your choices, with the package
/// unpacked, Windows prepared and every check passed.
async fn walk_to_choices(cx: &mut AsyncApp, model: &Entity<AppModel>, package: &Path) {
    wait_for(cx, model, "startup recovery", |m| !m.recovering).await;
    act(cx, model, |m, cx| {
        m.begin_install(cx);
        // A new flow prepares again; this walk is on a PC already prepared.
        m.preparation = crate::services::preparation::State::Ready;
    });
    act(cx, model, |m, cx| m.load_package_file(package.to_path_buf(), cx));
    wait_for(cx, model, "the package and the checks", |m| m.package.is_some() && m.checks_complete()).await;
    act(cx, model, |m, cx| m.next_step(cx));
    assert_eq!(read(cx, model, |m| m.flow.step), Step::Options, "the test package has one options screen");
}

/// Counts the times the model asks the shell to bring the window to the front.
fn count_bring_to_front(cx: &mut AsyncApp, model: &Entity<AppModel>) -> (Rc<Cell<u32>>, Subscription) {
    let count = Rc::new(Cell::new(0));
    let seen = count.clone();
    let subscription = cx.update(|cx| {
        cx.subscribe(model, move |_, event: &ModelEvent, _| {
            if matches!(event, ModelEvent::BringToFront) {
                seen.set(seen.get() + 1);
            }
        })
    });
    (count, subscription)
}

/// Longer than the step shows every switch off before it moves on, so a
/// test can tell it stayed.
async fn longer_than_moving_on(cx: &AsyncApp) {
    cx.background_executor().timer(Duration::from_millis(2500)).await;
}

/// With a switch still on, the step opens Windows Security once for the
/// visit. Once every switch reads off, the window comes to the front, the
/// step shows it a moment and then goes on to Install. A switch turned back
/// on meanwhile keeps it there.
#[test]
fn windows_security_opens_by_itself_and_moves_on_once_every_switch_is_off() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = automatic("security-by-itself", some_on());
        let package = package_of(&temp, "0.6.0");
        let model = new_model(&mut cx, env);
        let (brought, _subscription) = count_bring_to_front(&mut cx, &model);
        walk_to_choices(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        wait_for(&cx, &model, "Windows Security to open", |_| *machine.security_opened.lock().unwrap() == 1)
            .await;
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security);
        // Readings that still need the user don't open it again.
        cx.background_executor().timer(Duration::from_millis(1500)).await;
        assert_eq!(*machine.security_opened.lock().unwrap(), 1, "once per visit");
        assert_eq!(read(&cx, &model, |m| m.security), some_on(), "Atlas changed no switch");

        // Every switch off: shown a moment, then on to Install.
        machine.set_security(all_off());
        wait_for(&cx, &model, "every switch off", AppModel::security_moving_on).await;
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security, "the step shows it done first");
        assert_eq!(brought.get(), 1, "the window came to the front");
        // A switch back on before it moves keeps it there.
        machine.set_security(some_on());
        wait_for(&cx, &model, "the switch back on", |m| !m.security_moving_on()).await;
        longer_than_moving_on(&cx).await;
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security);
        machine.set_security(all_off());
        wait_for(&cx, &model, "Install", |m| m.flow.step == Step::Install).await;
        assert_eq!(brought.get(), 2);
        assert!(read(&cx, &model, |m| m.step_satisfied(Step::Security)), "the stepper marks it done");
        settle(&cx, &model).await;
    });
}

/// Back on Windows Security on purpose, it opens Windows Security for a
/// switch that's on, but neither moves on nor is passed over by itself.
#[test]
fn windows_security_stays_when_the_user_comes_back_to_it() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = automatic("security-on-purpose", all_off());
        let package = package_of(&temp, "0.6.0");
        let model = new_model(&mut cx, env);
        walk_to_choices(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        wait_for(&cx, &model, "Install", |m| m.flow.step == Step::Install).await;

        for back in [true, false] {
            act(
                &mut cx,
                &model,
                |m, cx| {
                    if back { m.previous_step(cx) } else { m.set_step(Step::Security, cx) }
                },
            );
            assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security);
            longer_than_moving_on(&cx).await;
            assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security, "it stays: {back}");
            act(&mut cx, &model, |m, cx| m.next_step(cx));
        }
        assert_eq!(*machine.security_opened.lock().unwrap(), 0, "nothing was left to turn off");

        // A switch turned back on: coming back opens Windows Security for it.
        machine.set_security(some_on());
        wait_for(&cx, &model, "the switch back on", |m| m.security_fresh() && !m.security_ok()).await;
        act(&mut cx, &model, |m, cx| m.previous_step(cx));
        wait_for(&cx, &model, "Windows Security to open", |_| *machine.security_opened.lock().unwrap() == 1)
            .await;
        machine.set_security(all_off());
        wait_for(&cx, &model, "every switch off", AppModel::security_ok).await;
        longer_than_moving_on(&cx).await;
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security, "Continue is the user's");
        settle(&cx, &model).await;
    });
}

/// With nothing to turn off, every switch already off or Defender gone by
/// the user's choice, Continue on Your choices goes straight to Install and
/// the stepper marks Windows Security done. Defender kept but missing keeps
/// the step, which warns about it. Without the step acting by itself,
/// nothing of this happens.
#[test]
fn windows_security_is_passed_over_when_there_is_nothing_to_turn_off() {
    run_model_test(|mut cx| async move {
        let gone = SecurityStatus { defender_present: false, ..SecurityStatus::default() };
        for (name, reading, keep_defender, automatic_step, passed_over) in [
            ("security-skip-off", all_off(), true, true, true),
            ("security-skip-absent", gone, false, true, true),
            ("security-skip-missing", gone, true, true, false),
            ("security-skip-manual", all_off(), true, false, false),
        ] {
            let (temp, machine, mut env) = automatic(name, reading);
            env.automatic_security = automatic_step;
            let package = package_of(&temp, "0.6.0");
            let model = new_model(&mut cx, env);
            walk_to_choices(&mut cx, &model, &package).await;
            if !keep_defender {
                act(&mut cx, &model, |m, _| {
                    m.options.remove("defender-enable");
                    m.options.insert("defender-disable".into());
                });
            }
            act(&mut cx, &model, |m, cx| m.next_step(cx));
            if passed_over {
                wait_for(&cx, &model, "Install", |m| m.flow.step == Step::Install).await;
                assert!(read(&cx, &model, |m| m.step_satisfied(Step::Security)), "{name}");
            } else {
                wait_for(&cx, &model, "a reading", |m| m.security_fresh()).await;
                longer_than_moving_on(&cx).await;
                assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Security, "{name}");
            }
            assert_eq!(*machine.security_opened.lock().unwrap(), 0, "{name}: nothing to open it for");
            assert_eq!(read(&cx, &model, |m| m.page), Page::Install);
            settle(&cx, &model).await;
        }
    });
}

/// Without the step acting by itself, a switch that's on opens nothing:
/// Open Windows Security is the user's.
#[test]
fn windows_security_opens_nothing_unless_it_acts_by_itself() {
    run_model_test(|mut cx| async move {
        let (temp, machine, mut env) = automatic("security-not-automatic", some_on());
        env.automatic_security = false;
        let package = package_of(&temp, "0.6.0");
        let model = new_model(&mut cx, env);
        walk_to_choices(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        wait_for(&cx, &model, "a reading", |m| m.security_fresh()).await;
        cx.background_executor().timer(Duration::from_millis(1500)).await;
        assert_eq!(*machine.security_opened.lock().unwrap(), 0);
        // Open Windows Security, the button, opens it, as the step would.
        act(&mut cx, &model, |m, cx| m.open_windows_security(cx));
        wait_for(&cx, &model, "Windows Security to open", |_| *machine.security_opened.lock().unwrap() == 1)
            .await;
        settle(&cx, &model).await;
    });
}
