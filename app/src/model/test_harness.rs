//! The harness for tests that drive the real model inside a headless GPUI
//! application, with the machine behind controlled adapters.

use std::any::Any;
use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use futures::{FutureExt, StreamExt};
use gpui::{App, AppContext, AsyncApp, Context, Entity};

use super::{AppModel, Environment, Page, Step};
use crate::environment::Adapters;
use crate::services::atlas_state::{self, AtlasState};
use crate::services::installer::{self, InstallEvent, InstallRequest};
use crate::services::playbook;
use crate::services::releases::{self, Release};
use crate::services::requirements::{CheckContext, CheckId};
use crate::services::security::{SecurityStatus, Switch};
use crate::services::session::{self, SessionRecord};
use crate::services::settings::{self, AppSettings, InstallDraft, save_to};
use crate::services::test_support::{TempDir, apbx};

/// How long a test waits for the model to reach a state before failing.
pub(super) const PATIENCE: Duration = Duration::from_secs(30);

type Outcome = Result<(), Box<dyn Any + Send>>;

/// Runs `body` inside a headless GPUI application on this thread and
/// propagates its panic, if any, once the application has quit. The language
/// catalog is process-wide, so the test holds it exclusively.
pub(crate) fn run_model_test<Fut>(body: impl FnOnce(AsyncApp) -> Fut + 'static)
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

/// Polls `condition` until it holds, or fails after [`PATIENCE`].
pub(super) async fn wait_until(cx: &AsyncApp, what: &str, condition: impl Fn() -> bool) {
    let deadline = Instant::now() + PATIENCE;
    while !condition() {
        assert!(Instant::now() < deadline, "timed out waiting for {what}");
        cx.background_executor().timer(Duration::from_millis(25)).await;
    }
}

/// Polls the model until `condition` holds, or fails after [`PATIENCE`].
pub(super) async fn wait_for(
    cx: &AsyncApp,
    model: &Entity<AppModel>,
    what: &str,
    condition: impl Fn(&AppModel) -> bool,
) {
    wait_until(cx, what, || model.read_with(cx, |model, _| condition(model))).await;
}

/// Polls the settings document on disk until `condition` holds; the model
/// writes it from a thread of its own, so a change lands a moment after the
/// action that made it.
pub(super) async fn wait_on_disk(
    cx: &AsyncApp,
    env: &Environment,
    what: &str,
    condition: impl Fn(&AppSettings) -> bool,
) {
    let what = format!("{what} on disk");
    wait_until(cx, &what, || condition(&settings::load_from(&env.paths.settings()).settings)).await;
}

/// Waits until the shared install record has been released.
pub(super) async fn wait_for_release(cx: &AsyncApp, env: &Environment, what: &str) {
    wait_until(cx, what, || session::load(&env.paths.session()).unwrap().is_none()).await;
}

/// Waits until every settings write queued so far has finished and closed
/// its lock file. Writes are done in order on the store's own thread, so a
/// test that ends straight after an action that saves calls this last, or
/// its directory outlives it.
pub(super) async fn settle(cx: &AsyncApp, model: &Entity<AppModel>) {
    let flushed = read(cx, model, |m| m.store.transact(|_| ()));
    let _ = flushed.await;
}

pub(super) fn read<R>(cx: &AsyncApp, model: &Entity<AppModel>, f: impl FnOnce(&AppModel) -> R) -> R {
    model.read_with(cx, |model, _| f(model))
}

pub(super) fn act(
    cx: &mut AsyncApp,
    model: &Entity<AppModel>,
    f: impl FnOnce(&mut AppModel, &mut Context<AppModel>),
) {
    model.update(cx, f);
}

pub(crate) fn new_model(cx: &mut AsyncApp, env: Environment) -> Entity<AppModel> {
    cx.update(|cx| {
        cx.new(|cx| {
            let mut model = AppModel::with_environment(env, cx);
            // Most scenarios start on a PC that is already prepared;
            // tests/preparation.rs covers preparation itself.
            model.preparation = crate::services::preparation::State::Ready;
            model
        })
    })
}

/// A model built as the app builds it, without the preparation `new_model`
/// marks ready by hand.
pub(super) fn model_as_started(cx: &mut AsyncApp, env: Environment) -> Entity<AppModel> {
    cx.update(|cx| cx.new(|cx| AppModel::with_environment(env, cx)))
}

/// Walks a fresh model from Home to the Install step with the package
/// unpacked, every check passed and Windows Security read.
pub(super) async fn walk_to_install(cx: &mut AsyncApp, model: &Entity<AppModel>, package: &Path) {
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

/// A fresh test folder whose `App` folder holds the app's files, on a
/// machine with every Windows Security switch off. Keep the folder alive
/// for the whole test.
pub(super) fn fixture(name: &str) -> (TempDir, Machine, Environment) {
    let temp = TempDir::new(name);
    let root = temp.path().join("App");
    std::fs::create_dir_all(&root).unwrap();
    let machine = Machine::new(all_off());
    let env = machine.environment(&root);
    (temp, machine, env)
}

pub(crate) fn all_off() -> SecurityStatus {
    SecurityStatus {
        tamper_protection: Switch::Off,
        real_time_protection: Switch::Off,
        cloud_delivered: Switch::Off,
        sample_submission: Switch::Off,
        defender_present: true,
    }
}

pub(super) fn three_off_one_unreadable() -> SecurityStatus {
    SecurityStatus { cloud_delivered: Switch::Unknown, ..all_off() }
}

pub(super) use super::preview::passing;

/// A machine that is elevated, passes every check, and whose Windows
/// Security reading, install identity and state document are whatever the
/// test puts in the shared cells.
pub(crate) struct Machine {
    security: Arc<Mutex<SecurityStatus>>,
    pub(super) identity: Arc<Mutex<Option<atlas_state::InstallIdentity>>>,
    pub(super) state: Arc<Mutex<Option<AtlasState>>>,
    pub(super) scheduled: Arc<Mutex<u32>>,
    /// Completion windows armed for installs that started.
    pub(super) armed: Arc<Mutex<u32>>,
}

impl Machine {
    pub(crate) fn new(security: SecurityStatus) -> Self {
        Self {
            security: Arc::new(Mutex::new(security)),
            scheduled: Arc::new(Mutex::new(0)),
            identity: Arc::new(Mutex::new(Some(atlas_state::InstallIdentity::Fresh))),
            state: Arc::new(Mutex::new(None)),
            armed: Arc::new(Mutex::new(0)),
        }
    }

    pub(super) fn set_security(&self, status: SecurityStatus) {
        *self.security.lock().unwrap() = status;
    }

    fn adapters(&self) -> Adapters {
        let security = self.security.clone();
        let scheduled = self.scheduled.clone();
        let identity = self.identity.clone();
        let state = self.state.clone();
        let armed = self.armed.clone();
        Adapters {
            register_preparation_resume: Arc::new(|| Ok(())),
            is_elevated: Arc::new(|| true),
            read_security: Arc::new(move || *security.lock().unwrap()),
            read_install_identity: Arc::new(move || {
                identity.lock().unwrap().clone().ok_or_else(|| anyhow::anyhow!("unreadable identity"))
            }),
            read_atlas_state: Arc::new(move || Ok(state.lock().unwrap().clone())),
            run_check: Arc::new(|id: CheckId, _: &CheckContext| passing(id)),
            schedule_restart: Arc::new(move |_| {
                *scheduled.lock().unwrap() += 1;
                Ok(())
            }),
            relaunch_elevated: Arc::new(|| anyhow::bail!("an elevated test machine never relaunches")),
            arm_completion: Arc::new(move |_| {
                *armed.lock().unwrap() += 1;
                Ok(())
            }),
            fetch_release: Arc::new(|| anyhow::bail!("no network in tests")),
            read_driver_default: Arc::new(|| crate::services::preparation::Drivers::Automatic),
        }
    }

    pub(crate) fn environment(&self, root: &Path) -> Environment {
        Environment { adapters: self.adapters(), ..Environment::isolated(root) }
    }
}

/// A package whose front door records that it ran, then exits with `code`.
pub(super) fn marking_package(temp: &TempDir, code: i32) -> (PathBuf, PathBuf) {
    let marker = temp.path().join("front-door-ran.txt");
    let body = format!(
        "Write-Host '[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...'\r\nSet-Content -LiteralPath '{}' -Value 'ran'\r\nexit {code}",
        marker.display()
    );
    let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", &body));
    (package, marker)
}

/// A package of `version` that is never launched.
pub(super) fn package_of(temp: &TempDir, version: &str) -> PathBuf {
    apbx::write(&temp.path().join(format!("package-{version}.apbx")), &apbx::valid(version))
}

/// A package whose front door waits until `gate` exists, then succeeds.
pub(super) fn gated_package(temp: &TempDir, gate: &Path) -> PathBuf {
    let body = format!(
        "while (-not (Test-Path -LiteralPath '{}')) {{ Start-Sleep -Milliseconds 50 }}\r\nexit 0",
        gate.display()
    );
    apbx::write(&temp.path().join("gated.apbx"), &apbx::with_front_door("0.6.0", &body))
}

/// Runs the stub installer to completion outside any model, leaving the
/// record, log and exit file a reopened app would find.
pub(super) fn completed_session(env: &Environment, package: &Path, restart: bool) -> SessionRecord {
    let (dir, _) = playbook::extract_into(package, &env.paths.playbooks(), |_, _| {}).unwrap();
    let request = InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart };
    let (record, mut events) = installer::start(request, &env.paths.session()).expect("start the stub");
    futures::executor::block_on(async {
        while let Some(event) = events.next().await {
            if let InstallEvent::Finished(_) = event {
                break;
            }
        }
    });
    record
}

pub(super) fn save_draft(env: &Environment, draft: InstallDraft) {
    let settings = AppSettings { draft: Some(draft), ..AppSettings::default() };
    save_to(&env.paths.settings(), &settings).unwrap();
}

/// The state document Atlas.State writes on completion, timestamp included.
pub(super) fn completed_state(version: &str) -> AtlasState {
    serde_json::from_value(serde_json::json!({
        "schemaVersion": 1,
        "installedVersion": version,
        "installedAt": "2026-09-30T20:06:21.9690173+00:00",
        "mode": "Fresh",
    }))
    .unwrap()
}

pub(super) fn release(tag: &str, assets: Vec<releases::Asset>) -> Release {
    Release {
        tag_name: tag.into(),
        body: String::new(),
        html_url: String::new(),
        published_at: String::new(),
        assets,
    }
}
