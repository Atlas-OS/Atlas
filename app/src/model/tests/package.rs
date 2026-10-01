//! The installation files: release checks, refusals and downloads.

use crate::model::test_harness::{
    act, fixture, marking_package, new_model, read, run_model_test, settle, wait_for,
};
use crate::model::{Acquisition, AppModel};

/// A package still unpacking when a running install is attached never
/// replaces the package or the choices that install runs with.
#[test]
fn an_unpacking_package_never_lands_under_a_running_install() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-acquisition-locked");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        let options = read(&cx, &model, |m| m.options.clone());
        act(&mut cx, &model, |m, cx| {
            m.load_playbook_file(package.clone(), cx);
            m.flow.attach_running().unwrap();
        });
        wait_for(&cx, &model, "the extraction to end", |m| !m.acquisition.is_busy()).await;
        read(&cx, &model, |m| {
            assert!(m.playbook.is_none());
            assert_eq!(m.options, options);
        });
    });
}

/// "Open package file" is offered exactly when a chosen file would load:
/// a download gives way to it, a running preparation or an unpacking
/// package does not.
#[test]
fn open_package_file_is_offered_only_when_a_chosen_file_would_load() {
    run_model_test(async move |mut cx| {
        use crate::services::preparation::{Stage, State};
        let (_temp, _, env) = fixture("model-choose-package");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        wait_for(&cx, &model, "the checks", AppModel::checks_complete).await;
        act(&mut cx, &model, |m, _| {
            m.acquisition = Acquisition::Downloading { received: 1, total: 2 };
            assert!(m.may_choose_playbook(), "a download gives way to a chosen file");
            m.preparation = State::Running { stage: Stage::StoreInstall, completed: 0, total: 1 };
            assert!(!m.may_choose_playbook(), "not while preparation holds the flow");
            m.preparation = State::Ready;
            m.acquisition = Acquisition::Extracting { done: 0, total: 1 };
            assert!(!m.may_choose_playbook(), "not while a package unpacks");
            m.acquisition = Acquisition::Idle;
            assert!(m.may_choose_playbook());
        });
        settle(&cx, &model).await;
    });
}

/// A release build takes its package from GitHub, so these need a binary
/// without a built-in package.
#[cfg(not(feature = "embedded-playbook"))]
mod download {
    use std::sync::{Arc, Mutex};
    use std::time::{Duration, Instant};

    use crate::model::test_harness::{
        PATIENCE, act, fixture, new_model, read, release, run_model_test, settle, wait_for, wait_until,
    };
    use crate::model::{AcquireProblem, Acquisition, AppModel, ReleaseCheck};
    use crate::services::releases;

    #[test]
    fn a_failed_release_check_is_retried_by_the_download_button() {
        run_model_test(async move |mut cx| {
            let (_temp, _, env) = fixture("model-release-retry");
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| m.check_for_updates(cx));
            wait_for(&cx, &model, "the failed release check", |m| matches!(m.release, ReleaseCheck::Failed))
                .await;
            act(&mut cx, &model, |m, cx| m.begin_install(cx));
            read(&cx, &model, |m| {
                assert!(m.playbook.is_none());
                assert!(matches!(m.acquisition, Acquisition::Idle), "nothing is known to download yet");
            });
            let fetches = Arc::new(Mutex::new(0));
            let count = fetches.clone();
            act(&mut cx, &model, |m, cx| {
                m.env.adapters.fetch_release = Arc::new(move || {
                    *count.lock().unwrap() += 1;
                    Ok(release("v9.9.9", vec![]))
                });
                m.download_latest(cx);
            });
            // The new check's completion starts the download at Ready. This
            // release has no package, which ends the attempt without a transfer.
            wait_for(&cx, &model, "the download to be attempted", |m| {
                matches!(&m.acquisition, Acquisition::Failed(AcquireProblem::NoPlaybookAsset { version }) if version == "9.9.9")
            })
            .await;
            assert_eq!(*fetches.lock().unwrap(), 1);
        });
    }

    #[test]
    fn a_release_older_than_the_front_door_is_refused_before_downloading() {
        run_model_test(async move |mut cx| {
            let (_temp, _, mut env) = fixture("model-release-predates");
            let asset = releases::Asset {
                name: "AtlasPlaybook_v0.5.0-hotfix.apbx".into(),
                size: 48_024_713,
                browser_download_url: "http://127.0.0.1:9/unreachable".into(),
                ..Default::default()
            };
            env.adapters.fetch_release = Arc::new(move || Ok(release("0.5.0-hotfix", vec![asset.clone()])));
            let model = new_model(&mut cx, env.clone());
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.check_for_updates(cx);
                m.begin_install(cx);
            });
            wait_for(&cx, &model, "the refusal", |m| {
                matches!(&m.acquisition, Acquisition::Failed(AcquireProblem::Unsupported { version }) if version == "0.5.0-hotfix")
            })
            .await;
            assert!(read(&cx, &model, AppModel::latest_predates_app));
            let downloads = env.paths.downloads();
            assert!(
                std::fs::read_dir(&downloads).map_or(true, |mut entries| entries.next().is_none()),
                "nothing was downloaded"
            );
        });
    }

    #[test]
    fn a_download_that_stops_receiving_is_abandoned() {
        run_model_test(async move |mut cx| {
            let (_temp, _, mut env) = fixture("model-download-stall");
            // A server that sends its headers and a few bytes, then nothing, and
            // closes the connection only well after the stall limit.
            let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
            let port = listener.local_addr().unwrap().port();
            let (give_up, server_gives_up) = std::sync::mpsc::channel::<()>();
            std::thread::spawn(move || {
                use std::io::{Read, Write};
                let (mut stream, _) = listener.accept().unwrap();
                let mut request = [0u8; 4096];
                let _ = stream.read(&mut request);
                let _ = stream.write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 1000000\r\n\r\npartial");
                let _ = server_gives_up.recv_timeout(PATIENCE);
            });
            let asset = releases::Asset {
                name: "Atlas.apbx".into(),
                size: 1_000_000,
                browser_download_url: format!("http://127.0.0.1:{port}/Atlas.apbx"),
                ..Default::default()
            };
            env.adapters.fetch_release = Arc::new(move || Ok(release("9.9.9", vec![asset.clone()])));
            let model = new_model(&mut cx, env.clone());
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.check_for_updates(cx);
                m.begin_install(cx);
            });
            wait_for(&cx, &model, "the download to start", |m| {
                matches!(m.acquisition, Acquisition::Downloading { .. })
            })
            .await;
            wait_for(&cx, &model, "the stall", |m| {
                matches!(m.acquisition, Acquisition::Failed(AcquireProblem::Stalled))
            })
            .await;
            let _ = give_up.send(());
            // Once the server gives up too, the transfer removes its partial file,
            // and its late failure is not applied.
            let downloads = env.paths.downloads();
            wait_until(&cx, "the abandoned transfer to end on its own", || {
                !std::fs::read_dir(&downloads)
                    .unwrap()
                    .flatten()
                    .any(|entry| entry.file_name().to_string_lossy().ends_with(".partial"))
            })
            .await;
            cx.background_executor().timer(Duration::from_millis(200)).await;
            assert!(read(&cx, &model, |m| matches!(
                m.acquisition,
                Acquisition::Failed(AcquireProblem::Stalled)
            )));
            settle(&cx, &model).await;
        });
    }

    /// Cancel download stops the transfer itself, at its next chunk, rather
    /// than only hiding it while it runs on.
    #[test]
    fn a_cancelled_download_stops_its_transfer() {
        run_model_test(async move |mut cx| {
            let (_temp, _, mut env) = fixture("model-download-cancel");
            // A server that keeps sending, far too slowly to finish while the
            // test runs, until the client goes away.
            let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
            let port = listener.local_addr().unwrap().port();
            let size = 100_000_000;
            std::thread::spawn(move || {
                use std::io::{Read, Write};
                let (mut stream, _) = listener.accept().unwrap();
                let mut request = [0u8; 4096];
                let _ = stream.read(&mut request);
                let _ =
                    stream.write_all(format!("HTTP/1.1 200 OK\r\nContent-Length: {size}\r\n\r\n").as_bytes());
                let deadline = Instant::now() + PATIENCE * 2;
                while Instant::now() < deadline && stream.write_all(&[0u8; 1024]).is_ok() {
                    std::thread::sleep(Duration::from_millis(20));
                }
            });
            let asset = releases::Asset {
                name: "Atlas.apbx".into(),
                size,
                browser_download_url: format!("http://127.0.0.1:{port}/Atlas.apbx"),
                ..Default::default()
            };
            env.adapters.fetch_release = Arc::new(move || Ok(release("9.9.9", vec![asset.clone()])));
            let model = new_model(&mut cx, env.clone());
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.check_for_updates(cx);
                m.begin_install(cx);
            });
            let downloads = env.paths.downloads();
            let partial = || {
                std::fs::read_dir(&downloads).is_ok_and(|entries| {
                    entries.flatten().any(|entry| entry.file_name().to_string_lossy().ends_with(".partial"))
                })
            };
            wait_until(&cx, "the transfer", &partial).await;
            act(&mut cx, &model, |m, cx| m.cancel_download(cx));
            assert!(read(&cx, &model, |m| matches!(m.acquisition, Acquisition::Idle)));
            // Well before the server would stop sending.
            let deadline = Instant::now() + Duration::from_secs(10);
            while partial() {
                assert!(Instant::now() < deadline, "the cancelled transfer ran on");
                cx.background_executor().timer(Duration::from_millis(25)).await;
            }
            assert!(read(&cx, &model, |m| matches!(m.acquisition, Acquisition::Idle) && m.playbook.is_none()));
            settle(&cx, &model).await;
        });
    }
}

/// A tester build: the bundled package is the only one, and GitHub is
/// never asked. These need a binary that carries one.
#[cfg(feature = "embedded-playbook")]
mod bundled {
    use crate::model::test_harness::{
        act, fixture, marking_package, new_model, read, run_model_test, save_draft, wait_for,
    };
    use crate::model::{Environment, Origin, ReleaseCheck, Step};
    use crate::services::settings::InstallDraft;
    use crate::services::test_support::TempDir;
    use crate::services::{embedded, playbook, releases};

    fn tester_fixture(name: &str) -> (TempDir, Environment) {
        let (temp, _, env) = fixture(name);
        (temp, Environment { embedded_startup: true, ..env })
    }

    #[test]
    fn a_tester_build_loads_its_bundled_package_and_never_asks_github() {
        run_model_test(async move |mut cx| {
            let (_temp, env) = tester_fixture("bundled-startup");
            let model = new_model(&mut cx, env.clone());
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| m.begin_install(cx));
            wait_for(&cx, &model, "the bundled package", |m| m.playbook.is_some()).await;
            read(&cx, &model, |m| {
                let book = m.playbook.as_ref().unwrap();
                assert!(embedded::holds(&book.dir), "the loaded package is the embedded archive");
                assert!(matches!(book.origin, Origin::Bundled));
                assert!(matches!(m.release, ReleaseCheck::NotChecked));
            });
            let archive = env.paths.downloads().join(format!("Atlas-{}.apbx", embedded::rc_id().unwrap()));
            assert_eq!(releases::sha256_file(&archive).unwrap(), embedded::sha256());

            // The explicit actions are inert too, not merely hidden.
            act(&mut cx, &model, |m, cx| {
                m.check_for_updates(cx);
                m.acquire_latest(cx);
            });
            read(&cx, &model, |m| {
                assert!(matches!(m.release, ReleaseCheck::NotChecked), "no release check ran");
                assert!(!m.acquisition.is_busy(), "no download started");
                assert!(matches!(m.playbook.as_ref().unwrap().origin, Origin::Bundled));
            });
        });
    }

    #[test]
    fn a_draft_from_another_package_yields_to_the_bundled_one() {
        run_model_test(async move |mut cx| {
            let (temp, env) = tester_fixture("bundled-foreign-draft");
            let (package, _) = marking_package(&temp, 0);
            let (foreign, _) = playbook::extract_into(&package, &env.paths.playbooks(), |_, _| {}).unwrap();
            save_draft(
                &env,
                InstallDraft {
                    step: "ready".into(),
                    playbook_dir: Some(foreign.clone()),
                    flow: Some("other-window".into()),
                    ..InstallDraft::default()
                },
            );
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "the bundled package", |m| {
                m.playbook.as_ref().is_some_and(|book| embedded::holds(&book.dir))
            })
            .await;
            read(&cx, &model, |m| {
                assert!(m.flow.active && m.flow.step == Step::Ready, "the draft's step is resumed");
                assert_ne!(m.playbook.as_ref().unwrap().dir, foreign, "the foreign package is not adopted");
            });
        });
    }
}
