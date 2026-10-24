//! The installation files: release checks, refusals and downloads.

use crate::model::test_harness::{
    act, fixture, marking_package, new_model, read, run_model_test, settle, wait_for,
};
use crate::model::{Acquisition, AppModel, Origin};

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

/// "Open package file" stays enabled while a download runs, but not while
/// preparation holds the flow or a package unpacks.
#[test]
fn open_package_file_is_enabled_except_while_unpacking_or_preparing() {
    run_model_test(async move |mut cx| {
        use crate::services::preparation::{Stage, State};
        let (_temp, _, env) = fixture("model-choose-package");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        wait_for(&cx, &model, "the checks", AppModel::checks_complete).await;
        act(&mut cx, &model, |m, _| {
            m.acquisition = Acquisition::Downloading { received: 1, total: 2 };
            assert!(m.may_choose_playbook(), "while a download runs");
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

/// A file chosen while a download runs replaces the download, even one that
/// began unpacking while the dialog was open.
#[test]
fn a_chosen_file_replaces_a_download_under_way() {
    run_model_test(async move |mut cx| {
        let (temp, _, env) = fixture("model-choose-during-download");
        let (package, _) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        for busy in [
            Acquisition::Downloading { received: 1, total: 2 },
            Acquisition::Extracting { done: 1, total: 2 },
        ] {
            let what = format!("{busy:?}");
            act(&mut cx, &model, |m, cx| {
                m.playbook = None;
                m.acquisition = busy;
                m.open_chosen_playbook(package.clone(), cx);
                // The chosen file starts unpacking from nothing.
                assert!(matches!(m.acquisition, Acquisition::Extracting { done: 0, total: 0 }), "{what}");
            });
            wait_for(&cx, &model, "the chosen file", |m| !m.acquisition.is_busy()).await;
            read(&cx, &model, |m| {
                let origin = &m.playbook.as_ref().expect("the chosen file is loaded").origin;
                assert!(matches!(origin, Origin::LocalFile(path) if *path == package), "{what}");
                assert!(matches!(m.acquisition, Acquisition::Idle), "{what}");
            });
        }
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
        PATIENCE, act, fixture, marking_package, new_model, read, release, run_model_test, settle, wait_for,
        wait_until,
    };
    use crate::model::{AcquireProblem, Acquisition, AppModel, Origin, Page, ReleaseCheck};
    use crate::services::playbook::Manifest;
    use crate::services::test_support::apbx;
    use crate::services::{iso, releases};

    /// Download after a failed release check, as the ISO page offers it with
    /// no flow under way, checks again and downloads once that check ends.
    #[test]
    fn a_failed_release_check_is_retried_by_the_download_button() {
        run_model_test(async move |mut cx| {
            let (_temp, _, env) = fixture("model-release-retry");
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| m.check_for_updates(cx));
            wait_for(&cx, &model, "the failed release check", |m| matches!(m.release, ReleaseCheck::Failed))
                .await;
            read(&cx, &model, |m| {
                assert!(!m.flow.active && m.playbook.is_none());
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
                assert!(matches!(m.release, ReleaseCheck::Checking));
                assert!(m.download_pending(), "the download waits for the new check");
            });
            // With no flow at Ready, only the pending Download starts it when
            // the check ends. This release has no package, which ends the
            // attempt without a transfer.
            wait_for(&cx, &model, "the download to be attempted", |m| {
                matches!(&m.acquisition, Acquisition::Failed(AcquireProblem::NoPlaybookAsset { version }) if version == "9.9.9")
            })
            .await;
            assert!(!read(&cx, &model, AppModel::download_pending));
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

    /// A package given at launch ("Open with" or `--playbook`) replaces the
    /// download Get ready began by itself, rather than being dropped.
    #[test]
    fn a_package_given_at_launch_replaces_a_download_under_way() {
        run_model_test(async move |mut cx| {
            let (temp, _, env) = fixture("model-launch-package");
            let (package, _) = marking_package(&temp, 0);
            // A closed port: the download gets nowhere.
            let asset = releases::Asset {
                name: "Atlas.apbx".into(),
                size: 1,
                browser_download_url: "http://127.0.0.1:9/Atlas.apbx".into(),
                ..Default::default()
            };
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                // Opening the flow at Get ready starts the download first.
                m.release = ReleaseCheck::Ready { release: release("9.9.9", vec![asset]) };
                m.apply_start(Some(Page::Install), None, Some(package.clone()), cx);
            });
            wait_for(&cx, &model, "the package given at launch", |m| m.playbook.is_some()).await;
            read(&cx, &model, |m| {
                let book = m.playbook.as_ref().unwrap();
                assert!(matches!(&book.origin, Origin::LocalFile(path) if *path == package));
            });
            settle(&cx, &model).await;
        });
    }

    /// A package attempt that failed in an earlier flow is tried again by
    /// the next one, not shown as its own.
    #[test]
    fn a_new_flow_tries_again_after_a_failed_download() {
        run_model_test(async move |mut cx| {
            let (_temp, _, env) = fixture("model-download-retry");
            // A closed port: the download fails at once.
            let asset = releases::Asset {
                name: "Atlas.apbx".into(),
                size: 1,
                browser_download_url: "http://127.0.0.1:9/Atlas.apbx".into(),
                ..Default::default()
            };
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.release = ReleaseCheck::Ready { release: release("9.9.9", vec![asset]) };
                m.begin_install(cx);
            });
            wait_for(&cx, &model, "the failed download", |m| matches!(m.acquisition, Acquisition::Failed(_)))
                .await;
            act(&mut cx, &model, |m, cx| {
                m.cancel_flow(cx);
                m.begin_install(cx);
                assert!(matches!(m.acquisition, Acquisition::Downloading { .. }), "{:?}", m.acquisition);
            });
            settle(&cx, &model).await;
        });
    }

    /// Options staged with the ISO hold the choices in effect, so no browser
    /// while Install a Browser is unticked. The package that takes them keeps
    /// the picker's default, so ticking the box later finds a browser chosen.
    #[test]
    fn staged_iso_options_keep_the_browser_pickers_default() {
        run_model_test(async move |mut cx| {
            let (temp, _, env) = fixture("model-staged-browser");
            // A package with the repository's own pages.
            let mut contents = apbx::valid("0.6.0");
            contents.entries[0].data =
                include_bytes!(concat!(env!("CARGO_MANIFEST_DIR"), "/../playbook/playbook.conf")).to_vec();
            let package = apbx::write(&temp.path().join("package.apbx"), &contents);
            let model = new_model(&mut cx, env);
            wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
            act(&mut cx, &model, |m, cx| {
                m.begin_install(cx);
                m.iso_initial_options = Some(iso::default_options(&Manifest::builtin()));
                m.load_playbook_file(package.clone(), cx);
            });
            wait_for(&cx, &model, "the package", |m| m.playbook.is_some()).await;
            act(&mut cx, &model, |m, cx| {
                assert!(m.options.contains("browser-brave"), "kept, though not in effect");
                let page = m
                    .manifest()
                    .pages
                    .iter()
                    .position(|page| page.options.iter().any(|o| o.name == "install-another-browser"))
                    .unwrap();
                m.choose_option(page, "install-another-browser", cx);
            });
            let browsers: Vec<String> = read(&cx, &model, |m| {
                m.effective_options().into_iter().filter(|o| o.starts_with("browser-")).collect()
            });
            assert_eq!(browsers, ["browser-brave"]);
            settle(&cx, &model).await;
        });
    }
}

/// A tester build: the bundled package is the only one, and GitHub is
/// never asked. These need a binary that carries one.
#[cfg(feature = "embedded-playbook")]
mod bundled {
    use crate::model::test_harness::{
        act, fixture, marking_package, new_model, read, release, run_model_test, save_draft, wait_for,
    };
    use crate::model::{Acquisition, Environment, Origin, ReleaseCheck, Step};
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

            // The explicit actions are inert too, not merely hidden, even once
            // a release is known that a release build would download.
            act(&mut cx, &model, |m, cx| {
                m.check_for_updates(cx);
                assert!(matches!(m.release, ReleaseCheck::NotChecked), "no release check ran");
                // A closed port, so a download started by mistake fails fast.
                let asset = releases::Asset {
                    name: "Atlas.apbx".into(),
                    size: 1,
                    browser_download_url: "http://127.0.0.1:9/Atlas.apbx".into(),
                    ..Default::default()
                };
                m.release = ReleaseCheck::Ready { release: release("v9.9.9", vec![asset]) };
                m.acquire_latest(cx);
                m.download_latest(cx);
                assert!(matches!(m.acquisition, Acquisition::Idle), "no download started");
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
