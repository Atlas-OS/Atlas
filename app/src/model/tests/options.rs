//! Your choices: its questions on one screen, the optional extras, and the
//! keyboard question Atlas answers itself on a PC with one layout.

use crate::model::test_harness::{act, fixture, new_model, read, run_model_test, settle, wait_for};
use crate::model::{AppModel, FixedChoice, OptionScreen, ScreenKind, Step};
use crate::services::atlas_state::{AtlasState, InstallIdentity};

/// The kinds of the questions, and extras, the screen showing asks.
fn asked(m: &AppModel) -> Vec<ScreenKind> {
    m.option_screens()[m.current_option_screen()].groups().iter().map(|group| group.kind).collect()
}

fn page_of(m: &AppModel, option: &str) -> usize {
    m.manifest().choices.iter().position(|page| page.options.iter().any(|o| o.id == option)).unwrap()
}

/// A completed install of `version` whose record says it chose `options`.
fn recorded(version: &str, options: &[&str]) -> AtlasState {
    serde_json::from_value(serde_json::json!({
        "schemaVersion": 1, "installedVersion": version, "installedAt": "2026-10-30T18:00:00+00:00",
        "mode": "Reapply", "options": options,
    }))
    .unwrap()
}

/// A first install asks every question on one screen, in the package's
/// order, with the optional extras after them, folded.
#[test]
fn a_first_install_asks_every_question_on_one_screen() {
    use ScreenKind::{Defender, Extras, Keyboard, Mitigations, Updates};
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("options-one-screen");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Options, cx));
        read(&cx, &model, |m| {
            assert_eq!(m.option_screens().len(), 1);
            assert_eq!(asked(m), [Defender, Mitigations, Updates, Keyboard, Extras]);
            assert_eq!(m.choices_screen(), Some(0));
            assert!(!m.extras_shown, "the extras start folded");
            let groups = m.option_screens()[0].groups().to_vec();
            assert!(groups[..4].iter().all(|group| group.required && group.pages.len() == 1));
            assert!(!groups[4].required);
        });
        // Continue goes straight on to Windows Security.
        act(&mut cx, &model, |m, cx| {
            m.show_extras(true, cx);
            m.next_step(cx);
            assert_eq!(m.flow.step, Step::Security);
            m.previous_step(cx);
            assert_eq!(m.flow.step, Step::Options);
            assert!(m.extras_shown, "as the user left them");
            m.begin_install(cx);
            assert!(!m.extras_shown, "folded again in a new flow");
        });
        settle(&cx, &model).await;
    });
}

#[test]
fn keyboard_switching_is_one_exclusive_choice_passed_to_the_installer() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("keyboard-choice");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let page = read(&cx, &model, |m| {
            let group =
                m.choice_groups().into_iter().find(|group| group.kind == ScreenKind::Keyboard).unwrap();
            assert!(group.required);
            assert_eq!(group.pages.len(), 1);
            assert!(m.effective_options().iter().any(|o| o == "keyboard-shortcuts"));
            group.pages[0]
        });
        for name in ["keyboard-selector", "keyboard-single", "keyboard-shortcuts"] {
            act(&mut cx, &model, |m, cx| m.choose_option(page, name, cx));
            read(&cx, &model, |m| {
                let chosen: Vec<_> =
                    m.effective_options().into_iter().filter(|o| o.starts_with("keyboard-")).collect();
                assert_eq!(chosen, [name]);
            });
        }
    });
}

/// With one keyboard layout there's nothing to switch between, so a first
/// install doesn't ask, and tells the installer so. Windows is asked again
/// as Your choices opens, so a layout added meanwhile brings the question
/// back. When Windows can't say, Your choices asks.
#[test]
fn one_keyboard_layout_answers_the_keyboard_question() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("options-one-layout");
        *machine.layouts.lock().unwrap() = Some(1);
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Options, cx));
        read(&cx, &model, |m| {
            assert!(!asked(m).contains(&ScreenKind::Keyboard));
            let keyboard: Vec<_> =
                m.effective_options().into_iter().filter(|o| o.starts_with("keyboard-")).collect();
            assert_eq!(keyboard, ["keyboard-single"], "whatever the package's default");
        });
        for (layouts, asks) in [(Some(2), true), (None, true), (Some(1), false)] {
            *machine.layouts.lock().unwrap() = layouts;
            act(&mut cx, &model, |m, cx| {
                m.set_step(Step::Ready, cx);
                m.next_step(cx);
            });
            read(&cx, &model, |m| {
                assert_eq!(m.flow.step, Step::Options);
                assert_eq!(asked(m).contains(&ScreenKind::Keyboard), asks, "{layouts:?}");
                let single = m.effective_options().iter().any(|o| o == "keyboard-single");
                assert_eq!(single, !asks, "{layouts:?}");
            });
        }
        // Before the desktop exists, the ISO's choices were made already.
        act(&mut cx, &model, |m, _| m.before_desktop = true);
        read(&cx, &model, |m| assert!(asked(m).contains(&ScreenKind::Keyboard)));
        settle(&cx, &model).await;
    });
}

/// An update that keeps the choices keeps a recorded keyboard answer on a
/// PC with one layout. One nothing recorded or shows is the answer Atlas
/// finds, so it isn't asked, and neither the first screen nor the record
/// says the PC disagrees.
#[test]
fn keeping_the_choices_keeps_a_recorded_keyboard_answer() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("options-one-layout-update");
        *machine.layouts.lock().unwrap() = Some(1);
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        let answers = ["defender-enable", "mitigations-default", "auto-updates-disable"];
        let with_keyboard = [&answers[..], &["keyboard-shortcuts"]].concat();
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", &with_keyboard));
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        read(&cx, &model, |m| {
            let update = m.update_choices().unwrap();
            assert!(update.complete() && update.kept.iter().any(|o| o == "keyboard-shortcuts"));
            assert_eq!(m.option_screens(), [OptionScreen::UpdatePath], "nothing to ask");
            assert!(m.effective_options().iter().any(|o| o == "keyboard-shortcuts"));
        });
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", &answers));
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            let update = m.update_choices().unwrap();
            assert!(update.complete(), "{update:?}");
            assert!(update.kept.iter().any(|o| o == "keyboard-single"));
            assert!(!update.differs.contains(&ScreenKind::Keyboard), "{:?}", update.differs);
            assert!(m.effective_options().iter().any(|o| o == "keyboard-single"));
        });
        // Choosing again asks every question but the one Atlas answers.
        act(&mut cx, &model, |m, cx| {
            m.start_flow_at(Step::Options, cx);
            m.set_update_path(crate::model::UpdatePath::ChooseAgain, cx);
            m.next_step(cx);
            assert!(!asked(m).contains(&ScreenKind::Keyboard) && asked(m).contains(&ScreenKind::Defender));
        });
        settle(&cx, &model).await;
    });
}

/// After Windows rebuilt itself, Your choices asks only what the record of
/// the move lacks, and the choices it kept can't change.
#[test]
fn a_rebuilt_windows_asks_only_what_its_record_lacks() {
    run_model_test(|mut cx| async move {
        use crate::pages::testing::rebuilt;
        let (_temp, _, env) = fixture("options-rebase-partial");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
            m.atlas = Ok(None);
            m.update_access =
                Some(rebuilt(&["defender-disable", "auto-updates-disable", "keyboard-shortcuts"]));
            m.start_flow_at(Step::Options, cx);
            assert_eq!(asked(m), [ScreenKind::Mitigations]);
            assert_eq!(m.fixed_option("defender-enable"), Some(FixedChoice::Kept));
            assert_eq!(m.fixed_option("mitigations-disable"), None);
            let before = m.options.clone();
            m.choose_option(page_of(m, "defender-enable"), "defender-enable", cx);
            assert_eq!(m.options, before, "a kept choice can't change");
            m.choose_option(page_of(m, "mitigations-disable"), "mitigations-disable", cx);
            assert!(m.effective_options().iter().any(|o| o == "mitigations-disable"));
        });
        settle(&cx, &model).await;
    });
}

/// A page shown only when an option is chosen comes straight after the page
/// that offers that option: the browser picker follows the apps that say
/// "choose one below", not the optional apps in between.
#[test]
fn a_dependent_page_follows_the_page_it_depends_on() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("options-order");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        read(&cx, &model, |m| {
            let manifest = m.manifest();
            let extras =
                m.choice_groups().into_iter().find(|group| group.kind == ScreenKind::Extras).unwrap();
            let kinds: Vec<ScreenKind> =
                extras.pages.iter().map(|&page| ScreenKind::of_choice(&manifest.choices[page])).collect();
            assert_eq!(
                kinds,
                [ScreenKind::Power, ScreenKind::Apps, ScreenKind::Browser, ScreenKind::OptionalApps],
                "the built-in package lists the browser picker last"
            );
            let browser = extras.pages[2];
            let option = manifest.choices[browser].depends_on.as_deref().unwrap();
            assert!(manifest.choices[extras.pages[1]].options.iter().any(|offered| offered.id == option));
        });
        // Every page still shows exactly once, in one place.
        act(&mut cx, &model, |m, _| {
            let mut pages: Vec<usize> = m.choice_groups().into_iter().flat_map(|group| group.pages).collect();
            pages.sort();
            assert_eq!(pages, (0..m.manifest().choices.len()).collect::<Vec<_>>());
        });
    });
}

/// Ticking Install a Browser finds a browser chosen, whatever the choices
/// came from. Drafts and install records hold only the choices in effect, so
/// none of them names a browser while the box is unticked, and the installer
/// refuses the browser choice left unmade.
#[test]
fn ticking_install_a_browser_finds_one_chosen() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("browser-default");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            let in_effect = crate::services::iso::default_options(m.manifest());
            assert!(!in_effect.iter().any(|o| o.starts_with("browser-")), "{in_effect:?}");
            m.options = in_effect.into_iter().collect();
            let page = m
                .manifest()
                .choices
                .iter()
                .position(|page| page.options.iter().any(|o| o.id == "install-another-browser"))
                .unwrap();
            m.choose_option(page, "install-another-browser", cx);
        });
        let browsers: Vec<String> = read(&cx, &model, |m| {
            m.effective_options().into_iter().filter(|o| o.starts_with("browser-")).collect()
        });
        assert_eq!(browsers, ["browser-brave"]);
    });
}
