//! Which installs this PC accepts: the installed version, an unfinished
//! install, and the update Home offers.

use std::sync::Arc;

use gpui::AsyncApp;

use crate::model::test_harness::{
    Machine, act, completed_state, fixture, marking_package, new_model, package_of, read, release,
    run_model_test, settle, wait_for, walk_to_install,
};
use crate::model::{Acquisition, AppModel, Environment, InstallBlock, Page, ReleaseCheck, RunState, Step};
use crate::services::{atlas_state, playbook};

#[test]
fn resume_uses_protected_choices_even_when_the_local_draft_is_missing_or_changed() {
    run_model_test(|mut cx| async move {
        let (_temp, _, mut env) = fixture("resume-options");
        let options = crate::services::iso::default_options(&playbook::Manifest::builtin());
        let saved = options.clone();
        env.adapters.read_install_identity =
            Arc::new(move || Ok(atlas_state::InstallIdentity::Resume("0.6.0".into(), Some(saved.clone()))));
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.options.clear();
            assert_eq!(m.effective_options(), options);
            assert!(m.install_eligibility_problem().is_none());
            m.choose_option(0, "changed-local-choice", cx);
            assert_eq!(m.effective_options(), options);
            assert!(m.options.is_empty());
            m.flow.resume(Step::Options).unwrap();
            assert_eq!(m.current_draft().unwrap().options, options);
        });
    });
}

#[test]
fn unsupported_or_unreadable_identity_blocks_before_preparation_and_is_rechecked_before_launch() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("source-gate");
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
        read(&cx, &model, |m| {
            assert_eq!(m.flow.run, RunState::Idle, "the identity is read again before the final checks");
            assert!(matches!(m.install_block(), Some(InstallBlock::Unsupported { .. })));
            assert!(!m.can_install());
        });
        assert!(!marker.exists());
        act(&mut cx, &model, |m, cx| {
            m.flow.step = Step::Ready;
            m.preparation = crate::services::preparation::State::Idle;
            m.prepare_windows(cx);
        });
        assert!(read(&cx, &model, |m| m.preparation_job.is_none() && !m.preparation.busy()));
        settle(&cx, &model).await;
    });
}

/// This app's built-in manifest can't judge a version newer than itself:
/// until a package is chosen the newer install is let through, and the
/// package that loads applies the exact rule.
#[test]
fn a_newer_installed_version_is_judged_by_the_package_not_the_built_in_manifest() {
    run_model_test(|mut cx| async move {
        use atlas_state::InstallIdentity::Installed;
        let (temp, machine, env) = fixture("newer-installed");
        let (package, marker) = marking_package(&temp, 0);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        for version in ["0.6.1", "0.6.0-hotfix"] {
            *machine.identity.lock().unwrap() = Some(Installed(version.into()));
            act(&mut cx, &model, |m, _| m.refresh_atlas_state());
            assert!(read(&cx, &model, |m| m.install_eligibility_problem().is_none()), "{version}");
        }
        // A version that can't be ordered is still refused.
        *machine.identity.lock().unwrap() = Some(Installed("dev".into()));
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(read(&cx, &model, |m| !m.flow.active && m.start_block().is_some()));

        *machine.identity.lock().unwrap() = Some(Installed("0.6.1".into()));
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(read(&cx, &model, |m| m.flow.active && m.page == Page::Install));
        // The 0.6.0 package doesn't accept 0.6.1: refused at Get ready, and never launched.
        act(&mut cx, &model, |m, cx| m.load_playbook_file(package, cx));
        wait_for(&cx, &model, "the package and the checks", |m| m.playbook.is_some() && m.checks_complete())
            .await;
        read(&cx, &model, |m| {
            assert_eq!(
                m.install_block(),
                Some(InstallBlock::Unsupported { source: "0.6.1".into(), target: Some("0.6.0".into()) })
            );
            assert!(!m.ready_to_continue());
        });
        act(&mut cx, &model, |m, cx| m.next_step(cx));
        assert_eq!(read(&cx, &model, |m| m.flow.step), Step::Ready, "Next is refused, not only disabled");
        act(&mut cx, &model, |m, cx| {
            m.flow.step = Step::Install;
            m.start_install(cx);
        });
        assert_eq!(read(&cx, &model, |m| m.flow.run), RunState::Idle);
        assert!(!marker.exists());
    });
}

/// A tester build installs only its bundled package, so the built-in
/// manifest is the package and nothing is left for later.
#[test]
fn a_tester_build_judges_the_install_identity_against_its_bundled_package() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("bundled-identity");
        let env = Environment { embedded_startup: true, ..env };
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        for identity in [
            atlas_state::InstallIdentity::Installed("0.6.1".into()),
            atlas_state::InstallIdentity::Resume("0.5.9".into(), None),
        ] {
            *machine.identity.lock().unwrap() = Some(identity.clone());
            act(&mut cx, &model, |m, cx| m.begin_install(cx));
            assert!(read(&cx, &model, |m| !m.flow.active && m.start_block().is_some()), "{identity:?}");
        }
        assert!(matches!(
            read(&cx, &model, AppModel::start_block),
            Some(InstallBlock::ResumeOther { target, .. }) if target == "0.5.9"
        ));
    });
}

/// An unfinished install can only be finished by its own version's
/// package: Home lets the flow start, no other release is offered or
/// downloaded, and Get ready says which package to open.
#[test]
fn an_unfinished_install_of_another_version_waits_for_its_own_package() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("resume-other-version");
        // Choices the built-in manifest can't take; only the target's package judges them.
        let saved = vec!["defender-enable".to_owned()];
        *machine.identity.lock().unwrap() =
            Some(atlas_state::InstallIdentity::Resume("0.6.1".into(), Some(saved.clone())));
        let (other, marker) = marking_package(&temp, 0);
        let own = package_of(&temp, "0.6.1");
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        assert!(read(&cx, &model, |m| m.start_block().is_none() && m.install_block().is_none()));
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        read(&cx, &model, |m| {
            assert!(m.flow.active && m.page == Page::Install);
            assert!(!m.ready_to_continue());
            assert!(matches!(m.acquisition, Acquisition::Idle), "nothing is downloaded");
        });

        // Another release can't finish it: not offered, and Get ready says why.
        let waiting = InstallBlock::ResumeOther { target: "0.6.1".into(), downloads: env.paths.downloads() };
        act(&mut cx, &model, |m, _| m.release = ReleaseCheck::Ready { release: release("v0.6.2", vec![]) });
        read(&cx, &model, |m| {
            assert!(m.offered_update().is_none());
            assert!(!m.can_download_latest() && !m.offers_download());
            assert_eq!(m.install_block(), Some(waiting.clone()));
            assert!(m.start_block().is_none(), "the flow can still be entered to open the package");
        });
        act(&mut cx, &model, |m, _| m.release = ReleaseCheck::Failed);
        assert_eq!(read(&cx, &model, AppModel::install_block), Some(waiting.clone()));
        act(&mut cx, &model, |m, _| m.release = ReleaseCheck::Ready { release: release("v0.6.1", vec![]) });
        read(&cx, &model, |m| {
            assert!(m.can_download_latest() && m.offers_download());
            assert!(m.install_block().is_none());
        });

        // A package of another version is refused and never launched.
        act(&mut cx, &model, |m, cx| {
            m.release = ReleaseCheck::Failed;
            m.load_playbook_file(other, cx);
        });
        wait_for(&cx, &model, "the other package", |m| m.playbook.is_some() && m.checks_complete()).await;
        assert_eq!(read(&cx, &model, AppModel::install_block), Some(waiting));
        act(&mut cx, &model, |m, cx| {
            m.flow.step = Step::Install;
            m.start_install(cx);
            m.flow.step = Step::Ready;
        });
        assert!(!marker.exists());

        // Its own package finishes it, with the original choices.
        act(&mut cx, &model, |m, cx| m.load_playbook_file(own, cx));
        wait_for(&cx, &model, "its own package", |m| {
            m.playbook.as_ref().is_some_and(|book| book.manifest.version == "0.6.1") && m.checks_complete()
        })
        .await;
        read(&cx, &model, |m| {
            assert!(m.install_block().is_none());
            assert_eq!(m.effective_options(), saved);
            assert!(m.ready_to_continue());
        });
    });
}

#[test]
fn home_offers_no_update_that_this_pc_cannot_start() {
    run_model_test(|mut cx| async move {
        use atlas_state::InstallIdentity::{Installed, Resume};
        let (_temp, machine, env) = fixture("offered-update");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let offered = |machine: &Machine, identity, cx: &mut AsyncApp| {
            *machine.identity.lock().unwrap() = Some(identity);
            act(cx, &model, |m, _| m.refresh_atlas_state());
            read(cx, &model, |m| m.offered_update().map(|release| release.version().to_owned()))
        };
        act(&mut cx, &model, |m, _| m.release = ReleaseCheck::Ready { release: release("v0.5.0", vec![]) });
        assert_eq!(offered(&machine, Installed("0.4.0".into()), &mut cx), None);
        read(&cx, &model, |m| {
            assert!(m.update_available().is_some(), "newer, but this PC can't take it");
            assert_eq!(
                m.start_block(),
                Some(InstallBlock::Unsupported { source: "0.4.0".into(), target: None }),
                "no version is named before a package is chosen"
            );
        });
        act(&mut cx, &model, |m, _| m.release = ReleaseCheck::Ready { release: release("v0.6.0", vec![]) });
        assert_eq!(offered(&machine, Installed("0.5.0".into()), &mut cx).as_deref(), Some("0.6.0"));
        // An unfinished install of 0.5.0 is finished, not updated.
        *machine.state.lock().unwrap() = Some(completed_state("0.4.1"));
        assert_eq!(offered(&machine, Resume("0.5.0".into(), None), &mut cx), None);
    });
}

/// A state document captured before the install finished is not an
/// installed PC.
#[test]
fn a_partial_state_document_is_not_an_installed_pc() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("partial-state");
        *machine.state.lock().unwrap() = Some(
            serde_json::from_value(serde_json::json!({
                "schemaVersion": 1, "installedVersion": null, "installedAt": null, "mode": null, "options": []
            }))
            .unwrap(),
        );
        let model = new_model(&mut cx, env);
        read(&cx, &model, |m| {
            assert!(m.atlas.as_ref().is_ok_and(|state| state.is_some()));
            assert!(m.installed().is_none());
            assert!(m.installed_version().is_none());
        });
        *machine.state.lock().unwrap() = Some(completed_state("0.6.0"));
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            assert!(m.installed().is_some());
            assert_eq!(m.installed_version(), Some("0.6.0"));
        });
    });
}
