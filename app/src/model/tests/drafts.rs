//! Draft ownership: which flow may write or clear the draft, and saving that
//! never waits on the window's thread.

use std::path::PathBuf;
use std::time::{Duration, Instant};

use crate::model::drafts::{draft_launched, draft_owned_by};
use crate::model::test_harness::{
    act, completed_session, fixture, marking_package, model_as_started, new_model, read, run_model_test,
    save_draft, settle, wait_for, wait_for_release, wait_on_disk, wait_until, walk_to_install,
};
use crate::model::{Environment, Notice, Page, RunState, Step};
use crate::services::installer::{InstallOutcome, InstallRequest};
use crate::services::session::{self, SessionRecord};
use crate::services::settings::{self, InstallDraft, ThemePreference};
use crate::services::system;
use crate::services::test_support::apbx;

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
            options: vec!["defender-enable".into()],
            restart: false,
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
    // launcher, however alike it looks.
    let current_unlaunched = InstallDraft { flow: Some("current".into()), ..old_shape.clone() };
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
        // After a restart: the old-shape draft is cleared, not resumed.
        let (temp, _, env) = fixture("model-old-draft-rebooted");
        let (package, _) = marking_package(&temp, 0);
        let mut record = completed_session(&env, &package, true);
        record.started_at = "2001-01-01T00:00:00+00:00".into();
        session::save(&env.paths.session(), &record).unwrap();
        let old_shape = InstallDraft {
            step: "install".into(),
            options: vec!["defender-enable".into()],
            playbook_dir: Some(record.request.playbook_dir.clone()),
            ..InstallDraft::default()
        };
        save_draft(&env, old_shape.clone());
        let model = new_model(&mut cx, env.clone());
        wait_for_release(&cx, &env, "the completed install's record to be released").await;
        wait_on_disk(&cx, &env, "the old-shape draft to be cleared", |s| s.draft.is_none()).await;
        settle(&cx, &model).await;
        read(&cx, &model, |m| {
            assert!(!m.flow.active, "a known success does not offer its install draft again");
            assert!(m.settings.draft.is_none());
        });
        drop(model);

        // In the same boot: the recovered success clears it on completion.
        let (temp, _, env) = fixture("model-old-draft-same-boot");
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

/// The draft names the install it launches before the front door runs, so a
/// window that closes during the handoff leaves a record and a draft that
/// agree.
#[test]
#[cfg(windows)]
fn the_draft_names_its_install_before_the_front_door_runs() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-draft-association");
        // The front door first copies the settings it finds (whole, through a
        // rename), then waits for the gate.
        let seen = temp.path().join("seen.json");
        let gate = temp.path().join("gate");
        let body = format!(
            "Copy-Item -LiteralPath '{settings}' -Destination '{seen}.tmp'\r\nMove-Item -LiteralPath '{seen}.tmp' -Destination '{seen}'\r\nwhile (-not (Test-Path -LiteralPath '{gate}')) {{ Start-Sleep -Milliseconds 50 }}\r\nexit 0",
            settings = env.paths.settings().display(),
            seen = seen.display(),
            gate = gate.display()
        );
        let package = apbx::write(&temp.path().join("package.apbx"), &apbx::with_front_door("0.6.0", &body));
        let model = new_model(&mut cx, env.clone());
        walk_to_install(&mut cx, &model, &package).await;
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        act(&mut cx, &model, |m, cx| m.start_install(cx));
        wait_for(&cx, &model, "the install to run", |m| m.flow.run == RunState::Running).await;
        wait_until(&cx, "the front door to start", || seen.exists()).await;
        let id = read(&cx, &model, |m| m.session.as_ref().map(|s| s.id.clone())).unwrap();
        let found = settings::read_from(&seen).settings.draft.expect("the draft the front door found");
        assert_eq!(found.session.as_deref(), Some(id.as_str()), "the draft named the install before it ran");
        assert_eq!(found.step, "install");
        std::fs::write(&gate, "").unwrap();
        wait_for(&cx, &model, "the install to finish", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        wait_on_disk(&cx, &env, "the launching draft to be cleared", |s| s.draft.is_none()).await;
    });
}

/// A second, current flow for the same package stands at the Install step,
/// unlaunched, with other choices, when the first flow's install succeeds.
/// It is not the launcher: it survives completion, Done, and the cleanup
/// after a restart, and is resumed.
#[test]
#[cfg(windows)]
fn a_current_install_step_draft_for_the_same_package_survives_another_flows_success() {
    run_model_test(async move |mut cx| {
        for rebooted in [false, true] {
            let (temp, _, env) = fixture("model-same-package-draft");
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
                flow: Some("second-window".into()),
                ..InstallDraft::default()
            };
            save_draft(&env, second_flow.clone());
            let model = new_model(&mut cx, env.clone());
            if rebooted {
                wait_for(&cx, &model, "the other flow to resume", |m| m.flow.active).await;
                wait_for_release(&cx, &env, "the completed install's record to be released").await;
            } else {
                wait_for(&cx, &model, "the recovered success", |m| {
                    matches!(m.flow.run, RunState::Finished(_))
                })
                .await;
                settle(&cx, &model).await;
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
                assert!(!m.install_in_progress());
            });
        }
    });
}

/// A window that follows a recorded install it did not launch saves its
/// draft under a flow id of its own, so no other window takes it for an
/// unowned one.
#[test]
#[cfg(windows)]
fn a_flow_following_an_install_it_did_not_launch_owns_its_draft() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-attached-owner");
        let (package, _) = marking_package(&temp, 1);
        completed_session(&env, &package, false);
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the recovered failure", |m| matches!(m.flow.run, RunState::Finished(_))).await;
        // Going back a step starts a new attempt and saves the draft.
        act(&mut cx, &model, |m, cx| m.previous_step(cx));
        let mine = read(&cx, &model, |m| m.flow_id.clone());
        assert!(mine.is_some(), "the flow has an id");
        wait_on_disk(&cx, &env, "the draft", |s| s.draft.is_some()).await;
        let on_disk = settings::load_from(&env.paths.settings()).settings.draft.unwrap();
        assert_eq!(on_disk.flow, mine, "the draft names its owner");
        settle(&cx, &model).await;
    });
}

/// A preparation still running when the app opens is followed at Get ready
/// by a flow with an id of its own, so the draft it saves has an owner.
#[test]
#[cfg(windows)]
fn a_flow_following_a_preparation_found_at_startup_owns_its_draft() {
    run_model_test(async move |mut cx| {
        let (_temp, _, env) = fixture("model-running-preparation");
        // A stand-in worker that runs about a minute, and the journal it keeps.
        let mut worker = std::process::Command::new("ping")
            .args(["-n", "60", "127.0.0.1"])
            .stdout(std::process::Stdio::null())
            .spawn()
            .unwrap();
        let pid = worker.id();
        let job = env.paths.settings().with_file_name("Preparation").join(format!("{pid}-1"));
        std::fs::create_dir_all(&job).unwrap();
        let journal = serde_json::json!({
            "schema": 1, "status": "running", "stage": "windows-search", "completed": 0, "total": 1,
            "pid": pid, "processStart": system::process_start_time(pid).unwrap()
        });
        std::fs::write(job.join("state.json"), journal.to_string()).unwrap();
        // Not `new_model`: that helper marks preparation ready by hand.
        let model = model_as_started(&mut cx, env.clone());
        wait_for(&cx, &model, "the running preparation", |m| !m.recovering && m.preparation.busy()).await;
        let mine = read(&cx, &model, |m| {
            assert!(m.flow.active && m.flow.step == Step::Ready && m.page == Page::Install);
            m.flow_id.clone()
        });
        assert!(mine.is_some(), "the flow has an id");
        wait_on_disk(&cx, &env, "the draft", |s| s.draft.is_some()).await;
        let on_disk = settings::load_from(&env.paths.settings()).settings.draft.unwrap();
        assert_eq!(on_disk.flow, mine, "the draft names its owner");
        worker.kill().unwrap();
        worker.wait().unwrap();
        wait_for(&cx, &model, "the preparation to end", |m| !m.preparation.busy()).await;
        settle(&cx, &model).await;
    });
}

#[test]
#[cfg(windows)]
fn a_newer_draft_written_by_another_window_is_not_overwritten() {
    run_model_test(async move |mut cx| {
        let (_temp, _, env) = fixture("model-stale-settings");
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
        settle(&cx, &model).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(newer.clone()));
        // Nor does cancelling here clear it.
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        settle(&cx, &model).await;
        assert_eq!(settings::load_from(&env.paths.settings()).settings.draft, Some(newer));
        assert!(read(&cx, &model, |m| !m.flow.active));
    });
}

/// A completed install is closed out in order: its record goes only after
/// the draft that launched it has been cleared. While another holder keeps
/// the settings lock, the record survives (so the next window can finish
/// the job) and the flow is not offered again; with the lock free, the next
/// window completes it.
#[test]
#[cfg(windows)]
fn a_completed_record_outlives_a_failed_draft_cleanup() {
    use std::os::windows::fs::OpenOptionsExt;
    run_model_test(async move |mut cx| {
        for (label, rebooted) in [("after a reboot", true), ("Done in the same boot", false)] {
            let (temp, _, env) = fixture("model-ordered-finalize");
            let env = Environment { settings_lock_wait: Duration::from_millis(100), ..env };
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
                session: Some(record.id.clone()),
                flow: Some("launching-flow".into()),
                ..InstallDraft::default()
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
            wait_for(&cx, &model, "the failed transaction to be reported", |m| {
                matches!(m.notice, Some(Notice::SettingsNotSaved { .. }))
            })
            .await;
            // Every cleanup queued so far has given up on the lock.
            settle(&cx, &model).await;
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
            wait_for_release(&cx, &env, &format!("{label}: the record to be released after the draft")).await;
            settle(&cx, &model).await;
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
        let (temp, _, env) = fixture("model-settings-lock");
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
        // Waiting for the lock on the window's thread would take a full lock wait.
        let elapsed = started.elapsed();
        assert!(
            elapsed < env.settings_lock_wait * 3 / 4,
            "the window's thread waited {elapsed:?} for the lock"
        );
        assert_ne!(settings::load_from(&env.paths.settings()).settings.theme, ThemePreference::Dark);
        drop(held);
        wait_on_disk(&cx, &env, "the theme once the lock is free", |s| s.theme == ThemePreference::Dark)
            .await;
        assert!(read(&cx, &model, |m| m.notice.is_none()), "waiting is not an error");
    });
}

/// After a settings save failed, making the change again, as the notice
/// asks, saves it together with any other change that was lost, and the
/// notice goes once that has worked.
#[test]
fn making_a_change_again_after_a_failed_save_saves_it() {
    run_model_test(async move |mut cx| {
        let (_temp, _, env) = fixture("model-settings-retry");
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        // Something in the settings file's place: every save fails.
        let path = env.paths.settings();
        let _ = std::fs::remove_file(&path);
        std::fs::create_dir_all(&path).unwrap();
        act(&mut cx, &model, |m, cx| m.set_theme(ThemePreference::Dark, cx));
        wait_for(&cx, &model, "the failure", |m| matches!(m.notice, Some(Notice::SettingsNotSaved { .. })))
            .await;
        act(&mut cx, &model, |m, cx| m.set_restart_after_install(false, cx));
        settle(&cx, &model).await;
        std::fs::remove_dir(&path).unwrap();

        // The same choice again saves it, and the change lost after it.
        act(&mut cx, &model, |m, cx| m.set_theme(ThemePreference::Dark, cx));
        wait_on_disk(&cx, &env, "both changes", |s| {
            s.theme == ThemePreference::Dark && !s.restart_after_install
        })
        .await;
        wait_for(&cx, &model, "the notice to go", |m| m.notice.is_none()).await;
        settle(&cx, &model).await;
    });
}
