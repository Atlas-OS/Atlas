//! Your choices after Windows reinstalled itself during the move: the
//! choices the record kept are used, and only what it lacks is asked again.

use crate::model::ScreenKind;
use crate::model::test_harness::{act, fixture, new_model, read, run_model_test, wait_for};
use crate::services::update_access::{UpdateAccess, parse_journal};

/// The record of a move after which Windows rebuilt itself, keeping an Atlas
/// 0.5.0 install whose choices showed `options`.
fn rebuilt(options: &[&str], rebuilt: bool) -> UpdateAccess {
    let fixtures = concat!(env!("CARGO_MANIFEST_DIR"), "/../tests/fixtures/windows-transition");
    let mut journal: serde_json::Value =
        serde_json::from_str(&std::fs::read_to_string(format!("{fixtures}/journal-rebuilt.json")).unwrap())
            .unwrap();
    journal["carry"]["options"] = serde_json::json!(options);
    journal["rebuild"]["rebuilt"] = serde_json::json!(rebuilt);
    UpdateAccess { journal: Some(parse_journal(&journal.to_string()).unwrap()), ..UpdateAccess::default() }
}

const KEPT: &[&str] = &[
    "defender-disable",
    "mitigations-default",
    "auto-updates-disable",
    "keyboard-shortcuts",
    "disable-hibernation",
    "uninstall-edge",
];

#[test]
fn every_kept_choice_is_used_and_none_is_asked_again() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-complete");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| m.update_access = Some(rebuilt(KEPT, true)));
        read(&cx, &model, |m| {
            let choices = m.rebase_choices().expect("Windows rebuilt itself");
            assert_eq!(choices.previous, "0.5.0");
            assert!(choices.complete(), "every required choice was kept");
            let locked = m.locked_options().expect("nothing to choose");
            assert_eq!(locked, KEPT, "the kept choices, in the order the record has them");
            let mut effective = m.effective_options();
            effective.sort();
            let mut kept: Vec<String> = KEPT.iter().map(|option| (*option).to_owned()).collect();
            kept.sort();
            assert_eq!(effective, kept, "the install gets exactly the kept choices");
        });
        act(&mut cx, &model, |m, cx| m.choose_option(1, "mitigations-disable", cx));
        read(&cx, &model, |m| {
            assert!(!m.effective_options().iter().any(|option| option == "mitigations-disable"), "locked");
        });
    });
}

/// After Windows rebuilt itself, the record is what the install puts Atlas
/// back from, so Put back settings waits for the install, which puts the
/// settings back itself.
#[test]
fn a_rebuilt_windows_keeps_its_record_until_atlas_is_installed() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-put-back");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            m.elevated = true;
            m.update_access = Some(rebuilt(KEPT, true));
        });
        assert!(!read(&cx, &model, |m| m.may_restore_update_access()));
        act(&mut cx, &model, |m, cx| m.begin_install(cx));
        assert!(read(&cx, &model, |m| m.flow.active));
        assert_eq!(read(&cx, &model, |m| m.stop_question()), None, "stopping would put nothing back");
        act(&mut cx, &model, |m, _| m.update_access = Some(rebuilt(KEPT, false)));
        assert!(read(&cx, &model, |m| m.may_restore_update_access()), "switched on in place");
        assert!(read(&cx, &model, |m| m.stop_question().is_some()), "there, stopping puts them back");
    });
}

/// A Rebase leaves Edge when it was installed before Windows moved, so Your
/// choices doesn't show it being removed.
#[test]
fn edge_installed_before_the_move_is_shown_kept() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-edge-kept");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let mut access = rebuilt(KEPT, true);
        access.journal.as_mut().unwrap().carry.as_mut().unwrap().edge = true;
        act(&mut cx, &model, |m, _| m.update_access = Some(access));
        read(&cx, &model, |m| {
            let locked = m.locked_options().expect("every required choice was kept");
            assert!(!locked.iter().any(|option| option == "uninstall-edge"), "{locked:?}");
            assert_eq!(locked.len(), KEPT.len() - 1, "the other kept choices stay");
            assert!(!m.effective_options().iter().any(|option| option == "uninstall-edge"));
        });
        // Edge removed before the move stays removed.
        act(&mut cx, &model, |m, _| m.update_access = Some(rebuilt(KEPT, true)));
        assert!(read(&cx, &model, |m| m.effective_options().iter().any(|option| option == "uninstall-edge")));
    });
}

#[test]
fn a_choice_the_record_lacks_is_asked_again_and_the_rest_are_kept() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-partial");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let partial = ["defender-disable", "auto-updates-disable", "uninstall-edge"];
        act(&mut cx, &model, |m, _| {
            m.update_access = Some(rebuilt(&partial, true));
            m.options.insert("mitigations-disable".into());
            m.options.remove("mitigations-default");
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            let choices = m.rebase_choices().unwrap();
            assert_eq!(choices.missing, vec![ScreenKind::Mitigations, ScreenKind::Keyboard]);
            assert!(m.locked_options().is_none(), "the user makes the missing choice");
            for option in partial {
                assert!(m.options.contains(option), "{option} is kept");
            }
            assert!(m.options.contains("mitigations-disable"), "the missing choice keeps what was chosen");
            assert!(!m.options.contains("disable-hibernation"), "an extra nothing kept is not chosen");
        });
        act(&mut cx, &model, |m, cx| {
            let page = m
                .manifest()
                .pages
                .iter()
                .position(|page| page.options.iter().any(|o| o.name == "mitigations-default"))
                .unwrap();
            m.choose_option(page, "mitigations-default", cx);
            // Entering Your choices again keeps the user's change.
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            assert!(m.effective_options().iter().any(|option| option == "mitigations-default"));
            assert!(!m.options.contains("mitigations-disable"));
        });
    });
}

#[test]
fn a_windows_switched_on_in_place_asks_as_usual() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-none");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| {
            m.update_access = Some(rebuilt(KEPT, false));
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            assert!(m.rebase_choices().is_none());
            assert!(m.locked_options().is_none());
            assert!(!m.options.contains("defender-disable"), "nothing is changed for the user");
        });
    });
}

/// An update from an Atlas 0.5.0 install with its default extras: Your choices
/// starts from them, the user can still change them, and the install gets
/// what is ticked.
#[test]
fn an_update_from_0_5_0_starts_from_the_extras_the_pc_shows() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, mut env) = fixture("upgrade-extras");
        *machine.identity.lock().unwrap() =
            Some(crate::services::atlas_state::InstallIdentity::Installed("0.5.0".into()));
        let facts = crate::services::legacy_choices::Facts {
            packages: vec!["Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0".into()],
            toggles: [("Mitigations", 2), ("AutomaticUpdates", 0), ("Hibernation", 0), ("PowerSaving", 0)]
                .into_iter()
                .map(|(name, state)| (name.to_owned(), state))
                .collect(),
            browser: Some("Brave".into()),
            edge: false,
            appx: vec!["Microsoft.WindowsCalculator_8wekyb3d8bbwe".into()],
            toolbox: true,
            core_isolation_off: true,
            browsers: vec!["browser-brave".into()],
        };
        let observed = crate::services::legacy_choices::observed_options(&facts);
        env.adapters.read_legacy_choices = std::sync::Arc::new(move || observed.clone());
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| m.apply_recorded_choices());
        let extras = [
            "disable-hibernation",
            "disable-power-saving",
            "disable-core-isolation",
            "remove-snipping-tool",
            "uninstall-edge",
            "install-another-browser",
            "browser-brave",
            "install-toolbox",
        ];
        read(&cx, &model, |m| {
            let (previous, _) = m.installed_choices().expect("an update from Atlas 0.5.0");
            assert_eq!(previous, "0.5.0");
            assert!(m.locked_options().is_none(), "the user can still change them");
            let effective = m.effective_options();
            for option in
                extras.iter().chain(["defender-enable", "mitigations-default", "auto-updates-disable"].iter())
            {
                assert!(effective.iter().any(|chosen| chosen == option), "{option} is preselected");
            }
        });
        act(&mut cx, &model, |m, cx| {
            let page = m
                .manifest()
                .pages
                .iter()
                .position(|page| page.options.iter().any(|o| o.name == "install-toolbox"))
                .unwrap();
            m.choose_option(page, "install-toolbox", cx);
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            assert!(
                !m.effective_options().iter().any(|o| o == "install-toolbox"),
                "the user's change stands"
            );
        });
    });
}
