//! Orchestration tests: the real model, driven through its actions inside a
//! headless GPUI application (no window, no text system), with the machine
//! behind controlled adapters. The installer child is real Windows PowerShell
//! running a harmless stub front door, so "the install started" means the
//! launch protocol ran end to end.

use std::any::Any;
use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use futures::FutureExt;
use gpui::{App, AppContext, AsyncApp, Entity};

use super::*;
use crate::environment::{Adapters, RestartTiming};
use crate::services::installer::InstallOutcome;
use crate::services::requirements::{CheckContext, CheckDetail, CheckId, CheckResult, Verdict};
use crate::services::security::{SecurityStatus, Switch};
use crate::services::session::SessionRecord;
use crate::services::settings::{AppSettings, InstallDraft, ThemePreference, save_to};
use crate::services::test_support::{TempDir, apbx};

/// How long a test waits for the model to reach a state before failing.
const PATIENCE: Duration = Duration::from_secs(30);

// Harness.

/// Runs `body` inside a headless GPUI application on this thread and
/// propagates its panic, if any, once the application has quit. The language
/// catalog is process-wide, so the test holds it exclusively.
type Outcome = Result<(), Box<dyn Any + Send>>;

fn run_model_test<Fut>(body: impl FnOnce(AsyncApp) -> Fut + 'static)
where
    Fut: Future<Output = ()> + 'static,
{
    crate::i18n::testing::exclusive(|| {
        let outcome: Rc<RefCell<Option<Outcome>>> = Rc::new(RefCell::new(None));
        let sink = outcome.clone();
        crate::platform::application(true).run(move |cx: &mut App| {
            cx.spawn(async move |cx| {
                let result = std::panic::AssertUnwindSafe(body(cx.clone())).catch_unwind().await;
                *sink.borrow_mut() = Some(result);
                cx.update(|cx| cx.quit());
            })
            .detach();
        });
        match outcome.borrow_mut().take() {
            Some(Ok(())) => {}
            Some(Err(panic)) => std::panic::resume_unwind(panic),
            None => panic!("the test body did not run to completion"),
        }
    });
}

/// Polls the model until `condition` holds, or fails after [`PATIENCE`].
async fn wait_for(
    cx: &AsyncApp,
    model: &Entity<AppModel>,
    what: &str,
    condition: impl Fn(&AppModel) -> bool,
) {
    let deadline = Instant::now() + PATIENCE;
    loop {
        if model.read_with(cx, |model, _| condition(model)) {
            return;
        }
        assert!(Instant::now() < deadline, "timed out waiting for {what}");
        cx.background_executor().timer(Duration::from_millis(25)).await;
    }
}

/// Polls the settings document on disk until `condition` holds; the model
/// writes it from a thread of its own, so a change lands a moment after the
/// action that made it.
async fn wait_on_disk(
    cx: &AsyncApp,
    env: &Environment,
    what: &str,
    condition: impl Fn(&AppSettings) -> bool,
) {
    let deadline = Instant::now() + PATIENCE;
    loop {
        if condition(&settings::load_from(&env.paths.settings()).settings) {
            return;
        }
        assert!(Instant::now() < deadline, "timed out waiting for {what} on disk");
        cx.background_executor().timer(Duration::from_millis(25)).await;
    }
}

fn read<R>(cx: &AsyncApp, model: &Entity<AppModel>, f: impl FnOnce(&AppModel) -> R) -> R {
    model.read_with(cx, |model, _| f(model))
}

fn act(cx: &mut AsyncApp, model: &Entity<AppModel>, f: impl FnOnce(&mut AppModel, &mut Context<AppModel>)) {
    model.update(cx, f);
}

fn new_model(cx: &mut AsyncApp, env: Environment) -> Entity<AppModel> {
    cx.update(|cx| {
        cx.new(|cx| {
            let mut model = AppModel::with_environment(env, cx);
            // These install-orchestration scenarios use an already updated machine.
            // Preparation's own negative gating is covered separately below.
            model.preparation = crate::services::preparation::State::Ready;
            model
        })
    })
}

#[test]
fn incomplete_preparation_blocks_install_even_when_checks_pass() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("preparation-gate");
        let machine = Machine::new(all_off());
        let env = machine.environment(temp.path());
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        walk_to_install(&mut cx, &model, &package).await;
        for state in [
            crate::services::preparation::State::Idle,
            crate::services::preparation::State::Failed,
            crate::services::preparation::State::Reboot,
        ] {
            act(&mut cx, &model, |m, _| {
                m.preparation = state;
            });
            assert!(!read(&cx, &model, AppModel::ready_to_continue));
            assert!(!read(&cx, &model, AppModel::can_install));
        }
    });
}

#[test]
fn preparation_arms_recovery_without_requesting_shutdown_and_restores_choices() {
    run_model_test(|mut cx| async move {
        use crate::services::preparation::State;
        let temp = TempDir::new("preparation-auto-resume");
        let machine = Machine::new(all_off());
        let mut env = machine.environment(temp.path());
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
        assert!(!read(&cx, &model, AppModel::can_install));
    });
}

#[test]
fn preparation_restart_failures_are_visible_and_do_not_schedule_shutdown() {
    run_model_test(|mut cx| async move {
        use crate::services::preparation::{RestartProblem, State};
        let temp = TempDir::new("preparation-restart-errors");
        let machine = Machine::new(all_off());
        let env = machine.environment(temp.path());
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
        settings::modify(&env.paths.settings(), |doc| doc.draft = Some(foreign.clone())).unwrap();
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
        use crate::services::preparation::{RestartProblem, State};
        let temp = TempDir::new("preparation-restart-grace");
        let machine = Machine::new(all_off());
        let mut env = machine.environment(temp.path());
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

// Controlled machine.

#[test]
fn unsupported_or_unreadable_identity_blocks_before_preparation_and_is_rechecked_before_launch() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("source-gate");
        let machine = Machine::new(all_off());
        let env = machine.environment(temp.path());
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        for identity in [Some(atlas_state::InstallIdentity::Installed("0.3.2".into())), None] {
            *machine.identity.lock().unwrap() = identity;
            act(&mut cx, &model, |m, cx| m.begin_install(cx));
            assert!(!read(&cx, &model, |m| m.flow.active));
            assert!(read(&cx, &model, |m| m.install_eligibility_problem().is_some()));
        }
        *machine.identity.lock().unwrap() = Some(atlas_state::InstallIdentity::Fresh);
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert!(read(&cx, &model, AppModel::can_install));
        *machine.identity.lock().unwrap() = Some(atlas_state::InstallIdentity::Installed("0.3.2".into()));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        assert!(!marker.exists());
        assert!(!read(&cx, &model, AppModel::can_install));
        act(&mut cx, &model, |m, cx| {
            m.flow.step = Step::Ready;
            m.preparation = crate::services::preparation::State::Idle;
            m.prepare_windows(cx);
        });
        assert!(read(&cx, &model, |m| m.preparation_job.is_none() && !m.preparation.busy()));
    });
}

fn all_off() -> SecurityStatus {
    SecurityStatus {
        tamper_protection: Switch::Off,
        real_time_protection: Switch::Off,
        cloud_delivered: Switch::Off,
        sample_submission: Switch::Off,
    }
}

fn three_off_one_unreadable() -> SecurityStatus {
    SecurityStatus { cloud_delivered: Switch::Unknown, ..all_off() }
}

fn pass(id: CheckId) -> CheckResult {
    use CheckDetail as D;
    let detail = match id {
        CheckId::Administrator => D::AdministratorOk,
        CheckId::SupportedBuild => D::BuildSupported,
        CheckId::PendingUpdates => D::UpdatesNone,
        CheckId::PendingReboot => D::RebootNone,
        CheckId::ThirdPartyAntivirus => D::AntivirusNone,
        CheckId::Internet => D::InternetOk,
        CheckId::Power => D::PowerMains,
        CheckId::Activation => D::ActivationOk,
    };
    CheckResult { id, verdict: Verdict::Pass, detail }
}

/// A machine that is elevated, passes every check, and whose Windows
/// Security reading is whatever the test puts in the shared cell.
struct Machine {
    security: Arc<Mutex<SecurityStatus>>,
    identity: Arc<Mutex<Option<atlas_state::InstallIdentity>>>,
    scheduled: Arc<Mutex<u32>>,
}

impl Machine {
    fn new(security: SecurityStatus) -> Self {
        Self {
            security: Arc::new(Mutex::new(security)),
            scheduled: Arc::new(Mutex::new(0)),
            identity: Arc::new(Mutex::new(Some(atlas_state::InstallIdentity::Fresh))),
        }
    }

    fn set_security(&self, status: SecurityStatus) {
        *self.security.lock().unwrap() = status;
    }

    fn adapters(&self) -> Adapters {
        let security = self.security.clone();
        let scheduled = self.scheduled.clone();
        let identity = self.identity.clone();
        Adapters {
            register_preparation_resume: Arc::new(|| Ok(())),
            is_elevated: Arc::new(|| true),
            read_security: Arc::new(move || *security.lock().unwrap()),
            read_install_identity: Arc::new(move || {
                identity.lock().unwrap().clone().ok_or_else(|| anyhow::anyhow!("unreadable identity"))
            }),
            run_check: Arc::new(|id: CheckId, _: &CheckContext| pass(id)),
            schedule_restart: Arc::new(move |_| {
                *scheduled.lock().unwrap() += 1;
                Ok(())
            }),
        }
    }

    fn environment(&self, root: &Path) -> Environment {
        Environment { adapters: self.adapters(), ..Environment::isolated(root) }
    }
}

/// A package whose front door records that it ran, then exits with `code`.
fn marking_package(temp: &TempDir, code: i32) -> (PathBuf, PathBuf) {
    let marker = temp.path().join("front-door-ran.txt");
    let body = format!(
        "Write-Host '[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...'\r\nSet-Content -LiteralPath '{}' -Value 'ran'\r\nexit {code}",
        marker.display()
    );
    let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", &body));
    (package, marker)
}

/// Walks a fresh model from Home to the Install step with the package
/// unpacked, every check passed and Windows Security read.
async fn walk_to_install(cx: &mut AsyncApp, model: &Entity<AppModel>, package: &Path) {
    act(cx, model, |m, cx| m.begin_install(cx));
    assert!(read(cx, model, |m| m.flow.active && m.flow.step == Step::Ready && m.page == Page::Install));
    act(cx, model, |m, cx| m.load_playbook_file(package.to_path_buf(), cx));
    wait_for(cx, model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete()).await;
    assert!(read(cx, model, |m| m.ready_to_continue()));
    act(cx, model, |m, cx| m.next_step(cx));
    assert_eq!(read(cx, model, |m| m.flow.step), Step::Options);
    act(cx, model, |m, cx| m.next_step(cx));
    assert_eq!(read(cx, model, |m| m.flow.step), Step::Security, "the test package has one options screen");
    wait_for(cx, model, "a Windows Security reading", |m| m.security_fresh()).await;
}

/// Runs the stub installer to completion outside any model, leaving the
/// record, log and exit file a reopened app would find.
fn completed_session(env: &Environment, package: &Path, restart: bool) -> SessionRecord {
    let (dir, _) = playbook::extract_into(package, &env.paths.playbooks(), |_, _| {}).unwrap();
    let request = InstallRequest {
        playbook_dir: dir,
        options: vec!["defender-enable".into()],
        restart,
        restart_comment: None,
    };
    let (record, mut events) = installer::start(request, &env.paths.session()).expect("start the stub");
    futures::executor::block_on(async {
        use futures::StreamExt;
        while let Some(event) = events.next().await {
            if let InstallEvent::Finished(_) = event {
                break;
            }
        }
    });
    record
}

fn save_draft(env: &Environment, draft: InstallDraft) {
    let settings = AppSettings { draft: Some(draft), ..AppSettings::default() };
    save_to(&env.paths.settings(), &settings).unwrap();
}

// A confirmation belongs to the reading it was given for.

#[test]
fn security_is_verified_against_the_reading_the_user_confirmed() {
    let confirmed = three_off_one_unreadable();
    let all_unknown = SecurityStatus::default();
    let one_on = SecurityStatus { tamper_protection: Switch::On, ..confirmed };
    assert!(security_verified(&confirmed, Some(confirmed), true));
    assert!(!security_verified(&confirmed, Some(confirmed), false), "only an elevated user can confirm");
    assert!(!security_verified(&confirmed, None, true));
    assert!(!security_verified(&all_unknown, Some(confirmed), true), "a broader unknown set is not covered");
    assert!(!security_verified(&one_on, Some(one_on), true), "a readable On is never confirmable");
    assert!(security_verified(&all_off(), None, false), "all off needs no confirmation");

    // The final decision uses the same rule and the same confirmation.
    let acknowledged = BTreeSet::new();
    let results: Vec<CheckResult> =
        CheckId::ALL.iter().filter(|id| id.blocking()).map(|id| pass(*id)).collect();
    assert_eq!(preflight_decision(&results, &acknowledged, &confirmed, Some(confirmed), true), Ok(()));
    match preflight_decision(&results, &acknowledged, &all_unknown, Some(confirmed), true) {
        Err(Preflight::Changed { checks, security: Some(counts) }) => {
            assert!(checks.is_empty());
            assert_eq!(counts.unknown, 4);
        }
        other => panic!("a changed reading must refuse: {other:?}"),
    }
}

#[test]
#[cfg(windows)]
fn a_confirmation_invalidated_by_the_final_reading_does_not_start_the_install() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-stale-confirmation");
        let machine = Machine::new(three_off_one_unreadable());
        let env = machine.environment(&temp.path().join("App"));
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env.clone());

        walk_to_install(&mut cx, &model, &package).await;
        assert!(read(&cx, &model, |m| m.security.off_where_readable()));
        act(&mut cx, &model, |m, cx| m.acknowledge_security(true, cx));
        assert!(read(&cx, &model, |m| m.security_acknowledged() && m.security_ok()));
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert!(read(&cx, &model, |m| m.flow.step == Step::Install && m.can_install()));

        // Between the confirmation and the click, every switch becomes
        // unreadable. The final preflight reads that, and must not reuse a
        // confirmation given for a narrower set.
        machine.set_security(SecurityStatus::default());
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        assert!(read(&cx, &model, |m| m.flow.run == RunState::Preparing));
        wait_for(&cx, &model, "the preflight decision", |m| m.flow.run != RunState::Preparing).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Idle);
            match &m.preflight_problem {
                Some(Preflight::Changed { checks, security: Some(counts) }) => {
                    assert!(checks.is_empty(), "{checks:?}");
                    assert_eq!(counts.unknown, 4);
                }
                other => panic!("expected a security refusal, got {other:?}"),
            }
            assert!(!m.security_acknowledged(), "the confirmation does not cover the new reading");
            assert!(m.session.is_none());
        });
        assert!(!marker.exists(), "the front door must not run");
        assert!(session::load(&env.paths.session()).unwrap().is_none(), "nothing was recorded");

        // Control: the reading the user confirmed comes back, and the same
        // confirmation lets the install start; the front door really runs.
        machine.set_security(three_off_one_unreadable());
        wait_for(&cx, &model, "the confirmed reading again", |m| m.can_install()).await;
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Finished(InstallOutcome::Succeeded));
        assert!(marker.exists());
        assert!(read(&cx, &model, |m| m.attempt.phase >= Phase::Applying));
    });
}

// A success completed while the app was closed.

#[test]
#[cfg(windows)]
fn a_success_found_on_reopening_shows_its_result_and_clears_its_draft() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-recovered-success");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        let record = completed_session(&env, &package, true);
        assert_eq!(record.exit_code(), Some(0));
        save_draft(
            &env,
            InstallDraft {
                step: "install".into(),
                options: vec!["defender-enable".into()],
                playbook_dir: Some(record.request.playbook_dir.clone()),
                option_screen: 0,
                session: Some(record.id.clone()),
                flow: Some("launcher".into()),
                preparation_restart_at: None,
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
        let deadline = Instant::now() + PATIENCE;
        while session::load(&env.paths.session()).unwrap().is_some() {
            assert!(Instant::now() < deadline, "the record is released on leaving");
            cx.background_executor().timer(Duration::from_millis(25)).await;
        }
        assert!(read(&cx, &model, |m| !m.flow.active && m.page == Page::Home));
    });
}

#[test]
#[cfg(windows)]
fn a_success_from_before_a_restart_is_closed_out_and_a_foreign_draft_survives() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-recovered-rebooted");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        let mut record = completed_session(&env, &package, true);
        // The install was started before Windows last booted.
        record.started_at = "2001-01-01T00:00:00+00:00".into();
        session::save(&env.paths.session(), &record).unwrap();
        // A draft another flow saved later, not the one that launched this install.
        save_draft(
            &env,
            InstallDraft {
                step: "options".into(),
                options: vec!["defender-disable".into()],
                playbook_dir: Some(record.request.playbook_dir.clone()),
                option_screen: 0,
                session: None,
                flow: Some("another-window".into()),
                preparation_restart_at: None,
            },
        );

        let model = new_model(&mut cx, env.clone());
        let deadline = Instant::now() + PATIENCE;
        while session::load(&env.paths.session()).unwrap().is_some() {
            assert!(Instant::now() < deadline, "a completed, rebooted install's record is released");
            cx.background_executor().timer(Duration::from_millis(25)).await;
        }
        // The unrelated draft resumed instead, once the cleanup transaction returned.
        wait_for(&cx, &model, "the other flow to resume", |m| m.flow.active).await;
        read(&cx, &model, |m| {
            assert!(m.session.is_none());
            assert!(!m.install_in_progress());
            assert_eq!(m.flow.step, Step::Options);
            assert!(m.options.contains("defender-disable"));
            assert_eq!(m.settings.draft.as_ref().and_then(|d| d.flow.as_deref()), Some("another-window"));
        });
        assert!(settings::load_from(&env.paths.settings()).settings.draft.is_some());
    });
}

#[test]
fn a_draft_is_the_launching_one_by_id_or_by_the_old_shape() {
    let record = SessionRecord {
        id: "s1".into(),
        pid: 0,
        process_start: 0,
        started_at: String::new(),
        log_path: PathBuf::new(),
        exit_path: PathBuf::new(),
        request: InstallRequest {
            playbook_dir: PathBuf::from(r"C:\P\0.6.0_abc"),
            options: vec![],
            restart: false,
            restart_comment: None,
        },
    };
    let by_id =
        InstallDraft { session: Some("s1".into()), step: "options".into(), ..InstallDraft::default() };
    let other_id =
        InstallDraft { session: Some("s2".into()), step: "install".into(), ..InstallDraft::default() };
    let old_shape = InstallDraft {
        step: "install".into(),
        playbook_dir: Some(PathBuf::from(r"C:\P\0.6.0_abc")),
        options: vec!["defender-enable".into(), "extras".into()],
        ..InstallDraft::default()
    };
    let old_other_package =
        InstallDraft { playbook_dir: Some(PathBuf::from(r"C:\P\0.6.0_def")), ..old_shape.clone() };
    let old_earlier_step = InstallDraft { step: "options".into(), ..old_shape.clone() };
    let old_other_choices = InstallDraft { options: vec!["defender-disable".into()], ..old_shape.clone() };
    // A current flow that has an identity but has not launched is never the
    // launcher, however alike it looks (the follow-up verification's case).
    let current_unlaunched = InstallDraft { flow: Some("current".into()), ..old_shape.clone() };
    let mut record = record;
    record.request.options = vec!["defender-enable".into()];
    assert!(draft_launched(&by_id, &record));
    assert!(!draft_launched(&other_id, &record));
    assert!(draft_launched(&old_shape, &record));
    assert!(!draft_launched(&old_other_package, &record));
    assert!(!draft_launched(&old_earlier_step, &record));
    assert!(!draft_launched(&old_other_choices, &record));
    assert!(!draft_launched(&current_unlaunched, &record));
    // Ownership of the draft slot.
    assert!(draft_owned_by(&None, Some("me")));
    assert!(draft_owned_by(&Some(old_shape.clone()), Some("me")), "a draft without an owner is anyone's");
    assert!(draft_owned_by(&Some(current_unlaunched.clone()), Some("current")));
    assert!(!draft_owned_by(&Some(current_unlaunched), Some("me")));
}

#[test]
#[cfg(windows)]
fn a_draft_from_before_drafts_named_their_install_is_finished_with_it() {
    run_model_test(async move |mut cx| {
        // Before the restart: the old-shape draft is cleared, not resumed.
        let temp = TempDir::new("model-old-draft-rebooted");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        let mut record = completed_session(&env, &package, true);
        record.started_at = "2001-01-01T00:00:00+00:00".into();
        session::save(&env.paths.session(), &record).unwrap();
        let old_shape = InstallDraft {
            preparation_restart_at: None,
            step: "install".into(),
            options: vec!["defender-enable".into()],
            playbook_dir: Some(record.request.playbook_dir.clone()),
            option_screen: 0,
            session: None,
            flow: None,
        };
        save_draft(&env, old_shape.clone());
        let model = new_model(&mut cx, env.clone());
        let deadline = Instant::now() + PATIENCE;
        while session::load(&env.paths.session()).unwrap().is_some() {
            assert!(Instant::now() < deadline);
            cx.background_executor().timer(Duration::from_millis(25)).await;
        }
        wait_on_disk(&cx, &env, "the old-shape draft to be cleared", |s| s.draft.is_none()).await;
        cx.background_executor().timer(Duration::from_millis(200)).await;
        read(&cx, &model, |m| {
            assert!(!m.flow.active, "a known success does not offer its install draft again");
            assert!(m.settings.draft.is_none());
        });
        drop(model);

        // In the same boot: the recovered success clears it on completion.
        let temp = TempDir::new("model-old-draft-same-boot");
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        let record = completed_session(&env, &package, false);
        save_draft(
            &env,
            InstallDraft { playbook_dir: Some(record.request.playbook_dir.clone()), ..old_shape },
        );
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the recovered success", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Finished(InstallOutcome::Succeeded));
        wait_on_disk(&cx, &env, "the old-shape draft to be cleared", |s| s.draft.is_none()).await;
    });
}

#[test]
#[cfg(windows)]
fn the_draft_names_its_install_before_the_front_door_runs() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-draft-association");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let body = "Start-Sleep -Seconds 2\r\nexit 0";
        let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", body));
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the install to run", |m| m.flow.run == RunState::Running).await;
        let id = read(&cx, &model, |m| m.session.as_ref().map(|s| s.id.clone())).unwrap();
        let on_disk = settings::load_from(&env.paths.settings())
            .settings
            .draft
            .expect("the draft is kept while running");
        assert_eq!(on_disk.session.as_deref(), Some(id.as_str()), "the draft names the running install");
        assert_eq!(on_disk.step, "install");
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert!(settings::load_from(&env.paths.settings()).settings.draft.is_none());
    });
}

// A foreign draft survives Done and stale writes.

#[test]
#[cfg(windows)]
fn a_foreign_draft_survives_done_after_a_recovered_success_and_is_resumed() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-foreign-draft-done");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        completed_session(&env, &package, false);
        let foreign = InstallDraft {
            step: "options".into(),
            options: vec!["defender-disable".into()],
            playbook_dir: Some(temp.path().join("somewhere-else")),
            option_screen: 0,
            session: None,
            flow: Some("other-window".into()),
            preparation_restart_at: None,
        };
        save_draft(&env, foreign.clone());
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the recovered success", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Finished(InstallOutcome::Succeeded));
        cx.background_executor().timer(Duration::from_millis(200)).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(foreign.clone()));
        // Done.
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        wait_for(&cx, &model, "the other flow to be picked up", |m| m.flow.active).await;
        assert_eq!(
            settings::load_from(&env.paths.settings()).settings.draft,
            Some(foreign.clone()),
            "Done abandons nothing"
        );
        read(&cx, &model, |m| {
            assert_eq!(m.flow.step, Step::Options);
            assert!(m.options.contains("defender-disable"));
            assert!(m.session.is_none());
        });
    });
}

/// The follow-up verification's case: a second, current flow for the same
/// package stands at the Install step, unlaunched, with other choices, when
/// the first flow's install succeeds. It is not the launcher and survives
/// completion, Done, and the after-reboot cleanup.
#[test]
#[cfg(windows)]
fn a_current_install_step_draft_for_the_same_package_survives_another_flows_success() {
    run_model_test(async move |mut cx| {
        for rebooted in [false, true] {
            let temp = TempDir::new("model-same-package-draft");
            let machine = Machine::new(all_off());
            let env = machine.environment(&temp.path().join("App"));
            let (package, _) = marking_package(&temp, 0);
            let mut record = completed_session(&env, &package, false);
            if rebooted {
                record.started_at = "2001-01-01T00:00:00+00:00".into();
                session::save(&env.paths.session(), &record).unwrap();
            }
            let second_flow = InstallDraft {
                step: "install".into(),
                options: vec!["defender-disable".into()],
                playbook_dir: Some(record.request.playbook_dir.clone()),
                option_screen: 0,
                session: None,
                flow: Some("second-window".into()),
                preparation_restart_at: None,
            };
            save_draft(&env, second_flow.clone());
            let model = new_model(&mut cx, env.clone());
            if rebooted {
                wait_for(&cx, &model, "the other flow to resume", |m| m.flow.active).await;
            } else {
                wait_for(&cx, &model, "the recovered success", |m| {
                    matches!(m.flow.run, RunState::Finished(_))
                })
                .await;
                cx.background_executor().timer(Duration::from_millis(200)).await;
                assert_eq!(
                    settings::load_from(&env.paths.settings()).settings.draft,
                    Some(second_flow.clone())
                );
                act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
                wait_for(&cx, &model, "the other flow to be picked up", |m| m.flow.active).await;
            }
            assert_eq!(
                settings::load_from(&env.paths.settings()).settings.draft,
                Some(second_flow.clone()),
                "rebooted={rebooted}: the second flow's draft is not the launcher's"
            );
            read(&cx, &model, |m| {
                assert_eq!(m.flow.step, Step::Install);
                assert!(m.options.contains("defender-disable"));
                assert!(m.session.is_none());
            });
        }
    });
}

#[test]
#[cfg(windows)]
fn a_newer_draft_written_by_another_window_is_not_overwritten() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-stale-settings");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let model = new_model(&mut cx, env.clone());
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        wait_on_disk(&cx, &env, "this flow's draft", |s| s.draft.is_some()).await;
        let mine = settings::load_from(&env.paths.settings()).settings.draft.expect("this flow's draft");
        assert_eq!(mine.step, "ready");
        assert!(mine.flow.is_some(), "a current draft names its flow");
        // Another window begins a newer flow after this one loaded its settings.
        let newer = InstallDraft {
            step: "security".into(),
            options: vec!["defender-disable".into()],
            flow: Some("another-window".into()),
            ..mine.clone()
        };
        save_draft(&env, newer.clone());
        // A preference change from this window updates that field alone.
        act(&mut cx, &model, |m, cx| m.set_theme(ThemePreference::Dark, cx));
        wait_on_disk(&cx, &env, "the theme", |s| s.theme == ThemePreference::Dark).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(newer.clone()));
        // Stepping on in this window no longer overwrites the other flow's draft.
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        cx.background_executor().timer(Duration::from_millis(200)).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(newer.clone()));
        // Nor does cancelling here clear it.
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        cx.background_executor().timer(Duration::from_millis(200)).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(newer));
        assert!(read(&cx, &model, |m| !m.flow.active));
    });
}

/// A completed install is closed out in order: its record goes only after
/// the draft that launched it has been cleared. With the settings lock held
/// past the transaction's deadline, the record survives (so the next window
/// can finish the job) and the flow is not offered again; with the lock
/// free, the next window completes it.
#[test]
#[cfg(windows)]
fn a_completed_record_outlives_a_failed_draft_cleanup() {
    use std::os::windows::fs::OpenOptionsExt;
    run_model_test(async move |mut cx| {
        for (label, rebooted) in [("after a reboot", true), ("Done in the same boot", false)] {
            let temp = TempDir::new("model-ordered-finalize");
            let machine = Machine::new(all_off());
            let env = machine.environment(&temp.path().join("App"));
            let (package, _) = marking_package(&temp, 0);
            let mut record = completed_session(&env, &package, false);
            if rebooted {
                record.started_at = "2001-01-01T00:00:00+00:00".into();
                session::save(&env.paths.session(), &record).unwrap();
            }
            let launching = InstallDraft {
                step: "install".into(),
                options: vec!["defender-enable".into()],
                playbook_dir: Some(record.request.playbook_dir.clone()),
                option_screen: 0,
                session: Some(record.id.clone()),
                flow: Some("launching-flow".into()),
                preparation_restart_at: None,
            };
            save_draft(&env, launching.clone());
            let lock_path = env.paths.settings().with_extension("json.lock");
            let held = std::fs::OpenOptions::new()
                .read(true)
                .write(true)
                .create(true)
                .truncate(false)
                .share_mode(0)
                .open(&lock_path)
                .unwrap();

            let model = new_model(&mut cx, env.clone());
            if !rebooted {
                wait_for(&cx, &model, "the recovered success", |m| {
                    matches!(m.flow.run, RunState::Finished(_))
                })
                .await;
                act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
            }
            // Well past the transaction's two-second deadline.
            wait_for(&cx, &model, "the failed transaction to be reported", |m| {
                matches!(m.notice, Some(Notice::SettingsNotSaved { .. }))
            })
            .await;
            assert!(
                session::load(&env.paths.session()).unwrap().is_some(),
                "{label}: the record must not go while its draft could not be cleared"
            );
            assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(launching.clone()));
            assert!(read(&cx, &model, |m| !m.flow.active), "{label}: the finished flow is not offered again");
            drop(model);
            drop(held);

            // The next window finishes the job.
            let model = new_model(&mut cx, env.clone());
            if !rebooted {
                // Same boot: the success shows once more and Done closes it out.
                wait_for(&cx, &model, "the success again", |m| matches!(m.flow.run, RunState::Finished(_)))
                    .await;
                act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
            }
            wait_on_disk(&cx, &env, "the launching draft to be cleared", |s| s.draft.is_none()).await;
            let deadline = Instant::now() + PATIENCE;
            while session::load(&env.paths.session()).unwrap().is_some() {
                assert!(Instant::now() < deadline, "{label}: the record is released after the draft");
                cx.background_executor().timer(Duration::from_millis(25)).await;
            }
            cx.background_executor().timer(Duration::from_millis(300)).await;
            assert!(read(&cx, &model, |m| !m.flow.active), "{label}: nothing to resume");
            assert!(settings::load_from(&env.paths.settings()).settings.draft.is_none());
        }
    });
}

/// The settings lock is held by someone else while the model persists: the
/// window's thread must not wait for it. Actions return at once and the
/// writes land when the lock is free.
#[test]
#[cfg(windows)]
fn persistence_never_waits_on_the_windows_thread() {
    use std::os::windows::fs::OpenOptionsExt;
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-settings-lock");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
        let (package, _) = marking_package(&temp, 0);
        completed_session(&env, &package, false);
        let lock_path = env.paths.settings().with_extension("json.lock");
        std::fs::create_dir_all(lock_path.parent().unwrap()).unwrap();
        let held = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .truncate(false)
            .share_mode(0)
            .open(&lock_path)
            .unwrap();
        // Recovery of a success (draft cleanup) and completion happen while the lock is held.
        let started = Instant::now();
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the recovered success", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        act(&mut cx, &model, |m, cx| m.set_theme(ThemePreference::Dark, cx));
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        let elapsed = started.elapsed();
        assert!(elapsed < Duration::from_millis(1500), "the window's thread waited {elapsed:?} for the lock");
        assert_ne!(settings::load_from(&env.paths.settings()).settings.theme, ThemePreference::Dark);
        drop(held);
        wait_on_disk(&cx, &env, "the theme once the lock is free", |s| s.theme == ThemePreference::Dark)
            .await;
        assert!(read(&cx, &model, |m| m.notice.is_none()), "waiting is not an error");
    });
}

// A failure found on reopening is ready to retry.

#[test]
#[cfg(windows)]
fn a_failure_found_on_reopening_runs_the_checks_its_retry_needs() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-recovered-failure");
        let machine = Machine::new(all_off());
        let env = machine.environment(&temp.path().join("App"));
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
                option_screen: 0,
                session: Some(record.id.clone()),
                flow: Some("failed-install-launcher".into()),
                preparation_restart_at: None,
            },
        );

        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "the recovered failure", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Finished(InstallOutcome::Failed(1)));
            assert_eq!(m.flow_id.as_deref(), Some("failed-install-launcher"));
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

// The restart timer belongs to its countdown.

#[test]
#[cfg(windows)]
fn an_old_restart_timer_cannot_touch_a_newer_countdown() {
    run_model_test(async move |mut cx| {
        let temp = TempDir::new("model-restart-timer");
        let machine = Machine::new(all_off());
        let timing = RestartTiming {
            countdown: Duration::from_secs(2),
            tick: Duration::from_millis(50),
            grace: Duration::from_millis(500),
        };
        let env = Environment { restart: timing, ..machine.environment(&temp.path().join("App")) };
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
        let started = Instant::now();
        assert_eq!(read(&cx, &model, |m| m.restart_countdown()), Some(2));

        // Stop it part-way, then restart: a new countdown, a new deadline.
        cx.background_executor().timer(Duration::from_millis(1200)).await;
        act(&mut cx, &model, |m, cx| m.cancel_restart(cx));
        read(&cx, &model, |m| {
            assert!(m.restart_countdown().is_none());
            assert!(m.attempt.restart_cancelled);
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        act(&mut cx, &model, |m, cx| m.restart_now(cx));
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        let restarted = Instant::now();
        assert_eq!(read(&cx, &model, |m| m.restart_countdown()), Some(2));

        // Past the first countdown's deadline and its grace period: had the
        // first timer survived, it would have counted this countdown down
        // early and then cleared it. The new countdown is untouched.
        let first_grace_end = started + timing.countdown + timing.grace + Duration::from_millis(200);
        cx.background_executor().timer(first_grace_end.saturating_duration_since(Instant::now())).await;
        read(&cx, &model, |m| {
            let expected = timing.countdown.saturating_sub(restarted.elapsed());
            let left = m.restart_countdown().expect("the new countdown is still running");
            assert!(
                left as f32 >= expected.as_secs_f32().floor(),
                "left {left}, expected about {expected:?}"
            );
            assert!(!m.attempt.restart_cancelled);
        });
        assert_eq!(*machine.scheduled.lock().unwrap(), 0);
        // And it reaches "restarting now", then its own grace ends it.
        wait_for(&cx, &model, "the new countdown to reach zero", |m| m.restart_countdown() == Some(0)).await;
        wait_for(&cx, &model, "the new grace period to end", |m| m.restart_countdown().is_none()).await;
        assert!(read(&cx, &model, |m| !m.attempt.restart_cancelled));
        assert_eq!(*machine.scheduled.lock().unwrap(), 1);
    });
}

// Log tail bounds.

#[test]
fn the_log_tail_is_bounded_by_lines_and_by_bytes() {
    let mut attempt = InstallAttempt::default();
    attempt.push_lines((0..3000).map(|i| format!("line {i}")).collect());
    assert_eq!(attempt.log.len(), LOG_KEEP);
    assert_eq!(attempt.log_total, 3000);
    assert_eq!(attempt.log.first().map(|l| l.as_ref()), Some("line 1000"));
    attempt.push_lines((0..400).map(|_| "x".repeat(8 * 1024)).collect());
    assert!(attempt.log_bytes <= LOG_KEEP_BYTES, "{} bytes", attempt.log_bytes);
    assert!(attempt.log.len() < 400, "{} lines", attempt.log.len());
    assert_eq!(attempt.log_total, 3400);
    attempt.push_lines(vec![
        "[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...".into(),
    ]);
    assert_eq!(attempt.phase, Phase::Applying);
}

#[test]
fn plan_progress_survives_log_trimming_and_replay_but_resets_with_the_attempt() {
    let mut attempt = InstallAttempt::default();
    attempt.push_lines(vec!["[AtlasProgress] 8/40".into()]);
    attempt.push_lines((0..3000).map(|i| format!("line {i}")).collect());
    attempt.push_lines(vec!["[AtlasProgress] 2/40".into(), "[AtlasProgress] 8/40".into()]);
    assert_eq!(attempt.plan_progress.unwrap().completed, 8);
    attempt.push_lines(vec!["[AtlasProgress] 39/40".into()]);
    assert_eq!(attempt.plan_progress.unwrap().completed, 39);
    attempt.reset();
    assert!(attempt.plan_progress.is_none());
}

#[test]
fn a_preview_translation_is_announced_until_dismissed_or_english_is_chosen() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("preview-notice");
        let machine = Machine::new(all_off());
        let env = machine.environment(temp.path());
        save_to(
            &env.paths.settings(),
            &AppSettings { language: LanguagePreference::Explicit("de".into()), ..AppSettings::default() },
        )
        .unwrap();
        let model = new_model(&mut cx, env.clone());
        assert_eq!(read(&cx, &model, |m| m.preview_notice().map(|l| l.tag)), Some("de"));

        act(&mut cx, &model, |m, cx| m.dismiss_preview_notice(cx));
        assert!(read(&cx, &model, |m| m.preview_notice().is_none()), "dismissed for this language");
        wait_on_disk(&cx, &env, "the dismissal", |s| s.dismissed_preview_notices == vec!["de".to_owned()])
            .await;
        // Dismissing twice does not duplicate the entry.
        act(&mut cx, &model, |m, cx| m.dismiss_preview_notice(cx));
        assert_eq!(read(&cx, &model, |m| m.settings.dismissed_preview_notices.len()), 1);

        // A different preview language is announced again; choosing English ends it.
        act(&mut cx, &model, |m, cx| m.set_language(LanguagePreference::Explicit("ja".into()), cx));
        assert_eq!(read(&cx, &model, |m| m.preview_notice().map(|l| l.tag)), Some("ja"));
        act(&mut cx, &model, |m, cx| m.switch_to_english(cx));
        let language = read(&cx, &model, |m| m.settings.language.clone());
        assert!(
            matches!(&language, LanguagePreference::Explicit(tag) if tag.starts_with("en")),
            "{language:?}"
        );
        assert!(read(&cx, &model, |m| m.preview_notice().is_none()));
        wait_on_disk(&cx, &env, "the English choice", |s| s.language == language).await;
    });
}

#[test]
fn english_follows_the_windows_variant_when_there_is_one() {
    assert_eq!(english_for(&["en-US".into()]), "en-US");
    assert_eq!(english_for(&["de-DE".into(), "en-US".into()]), "en-US");
    assert_eq!(english_for(&["en-AU".into()]), "en-GB", "British spelling regions prefer en-GB");
    assert_eq!(english_for(&["de-DE".into()]), "en-GB", "no English in the list: the source");
    assert_eq!(english_for(&[]), "en-GB");
}
