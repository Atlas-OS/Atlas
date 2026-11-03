//! Your choices on an update: after Windows reinstalled itself during the
//! move, the choices the record kept are used, and only what it lacks is
//! asked again. Otherwise an update or reinstall keeps the choices this PC
//! has, asking only what it can't show, or chooses again.

use std::collections::HashMap;

use crate::model::test_harness::{
    act, fixture, held, new_model, read, run_model_test, settle, wait_for, wait_on_disk,
};
use crate::model::{AppModel, FixedChoice, Origin, PlaybookSource, ScreenKind, Step, UpdatePath};
use crate::services::atlas_state::{AtlasState, InstallIdentity, InstallMode, Unfinished};
use crate::services::legacy_choices::Facts;
use crate::services::playbook::Manifest;
use crate::services::update_access::{CarryToggle, UpdateAccess, parse_journal};

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
        act(&mut cx, &model, |m, cx| {
            let page = m
                .manifest()
                .pages
                .iter()
                .position(|page| page.options.iter().any(|o| o.name == "mitigations-disable"))
                .unwrap();
            let before = m.options.clone();
            m.choose_option(page, "mitigations-disable", cx);
            assert_eq!(m.options, before, "a choice the record kept can't be changed");
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

/// A record of a move from Atlas 0.5.0 that an earlier release wrote kept
/// the old Toolbox's own Mitigations record, which never changed the PC, and
/// took a choice from it. The Rebase, which would apply it, asks it instead,
/// unless the record Atlas 0.5.0's launcher left gives it. Atlas 0.6 leaves
/// no launcher beside its own records, so a move from it keeps the choice.
#[test]
fn a_rebase_asks_the_mitigations_choice_an_old_toolbox_record_gave() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("rebase-toolbox-mitigations");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let carried =
            ["defender-disable", "mitigations-disable", "auto-updates-disable", "keyboard-shortcuts"];
        let record = |version: &str, path: Option<&str>| {
            let mut access = rebuilt(&carried, true);
            let carry = access.journal.as_mut().unwrap().carry.as_mut().unwrap();
            carry.atlas_version = Some(version.into());
            carry.toggles =
                vec![CarryToggle { name: "Mitigations".into(), state: 0, path: path.map(str::to_owned) }];
            access
        };
        act(&mut cx, &model, |m, _| {
            m.update_access = Some(record("0.5.0", None));
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            let choices = m.rebase_choices().unwrap();
            assert_eq!(choices.missing, [ScreenKind::Mitigations]);
            assert_eq!(choices.options, ["defender-disable", "auto-updates-disable", "keyboard-shortcuts"]);
            assert!(m.locked_options().is_none(), "the user makes it");
            assert!(!m.effective_options().iter().any(|o| o == "mitigations-disable"));
        });
        for (version, path) in [("0.5.0", Some("Disable All Mitigations.cmd")), ("0.6.0-rc11", None)] {
            act(&mut cx, &model, |m, _| m.update_access = Some(record(version, path)));
            read(&cx, &model, |m| {
                assert_eq!(m.locked_options().as_deref(), Some(&carried.map(str::to_owned)[..]))
            });
        }
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
/// starts from them, keeping them sends exactly those, and choosing again
/// lets the user change them.
#[test]
fn an_update_from_0_5_0_starts_from_the_extras_the_pc_shows() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("upgrade-extras");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        *machine.facts.lock().unwrap() = Facts {
            packages: vec![NO_TELEMETRY.into()],
            toggles: records(&[
                ("Mitigations", 2),
                ("AutomaticUpdates", 0),
                ("Hibernation", 0),
                ("PowerSaving", 0),
            ]),
            // The record of Atlas 0.5.0's launcher that turned every protection on.
            launchers: [("Mitigations".to_owned(), "Enable All Mitigations.cmd".to_owned())].into(),
            browser: Some("Brave".into()),
            edge: Some(false),
            appx: vec!["Microsoft.WindowsCalculator_8wekyb3d8bbwe".into()],
            toolbox: Some(true),
            core_isolation_off: Some(true),
            browsers: Some(vec!["browser-brave".into()]),
            // Atlas 0.5.0 turned the language hotkeys off; this user has two layouts.
            language_hotkey: Some("3".into()),
            keyboard_layouts: Some(2),
            ..Facts::default()
        };
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
            let choices = m.update_choices().expect("an update from Atlas 0.5.0");
            assert_eq!((choices.previous.as_str(), choices.reinstall), ("0.5.0", false));
            assert!(choices.complete() && choices.differs.is_empty(), "{choices:?}");
            let locked = m.locked_options().expect("keeping them changes none");
            for option in extras.iter().chain(
                ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-selector"]
                    .iter(),
            ) {
                assert!(locked.iter().any(|chosen| chosen == option), "{option} is kept");
            }
            assert_eq!(m.effective_options(), locked);
        });
        act(&mut cx, &model, |m, cx| {
            m.set_update_path(UpdatePath::ChooseAgain, cx);
            assert!(m.locked_options().is_none(), "the user can change them now");
            let page = page_of(m, "disable-hibernation");
            m.choose_option(page, "disable-hibernation", cx);
            m.apply_recorded_choices();
        });
        read(&cx, &model, |m| {
            assert!(
                !m.effective_options().iter().any(|o| o == "disable-hibernation"),
                "the user's change stands"
            );
        });
        settle(&cx, &model).await;
    });
}

/// An update whose recorded choices name no browser keeps the browser
/// picker's default, so ticking Install a Browser finds one chosen.
#[test]
fn an_update_with_no_browser_recorded_keeps_the_pickers_default() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("upgrade-no-browser");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        *machine.facts.lock().unwrap() = Facts {
            packages: vec![NO_TELEMETRY.into()],
            toggles: records(&[("Mitigations", 1), ("AutomaticUpdates", 0)]),
            launchers: [("Mitigations".to_owned(), "Set Windows Default Mitigations.cmd".to_owned())].into(),
            ..Facts::default()
        };
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.apply_recorded_choices();
            m.set_update_path(UpdatePath::ChooseAgain, cx);
            assert!(m.options.contains("browser-brave"), "kept, though not in effect");
            let page = page_of(m, "install-another-browser");
            m.choose_option(page, "install-another-browser", cx);
        });
        let browsers: Vec<String> = read(&cx, &model, |m| {
            m.effective_options().into_iter().filter(|o| o.starts_with("browser-")).collect()
        });
        assert_eq!(browsers, ["browser-brave"]);
        settle(&cx, &model).await;
    });
}

const NO_DEFENDER: &str = "Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0";
const NO_TELEMETRY: &str = "Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0";

fn records(records: &[(&str, u32)]) -> HashMap<String, u32> {
    records.iter().map(|(name, state)| ((*name).to_owned(), *state)).collect()
}

/// A completed install of `version` whose record says it chose `options`.
fn recorded(version: &str, options: &[&str]) -> AtlasState {
    serde_json::from_value(serde_json::json!({
        "schemaVersion": 1, "installedVersion": version, "installedAt": "2026-10-30T18:00:00+00:00",
        "mode": "Reapply", "options": options,
    }))
    .unwrap()
}

fn page_of(m: &AppModel, option: &str) -> usize {
    m.manifest().pages.iter().position(|page| page.options.iter().any(|o| o.name == option)).unwrap()
}

fn sorted(options: &[impl AsRef<str>]) -> Vec<String> {
    let mut options: Vec<String> = options.iter().map(|option| option.as_ref().to_owned()).collect();
    options.sort();
    options
}

/// The built-in package, loaded, so the model can build its request.
fn load_builtin(m: &mut AppModel, dir: &std::path::Path) {
    m.playbook = Some(PlaybookSource {
        dir: dir.to_path_buf(),
        manifest: Manifest::builtin(),
        origin: Origin::Unpacked,
        archive: None,
    });
}

/// A release candidate's record that the PC contradicts: Defender kept while
/// Atlas's NoDefender package still removes it, Windows Update and the
/// processor protections off while their records turned them back on, and
/// VBS off without its option.
const CONTRADICTED: &[&str] = &[
    "auto-updates-disable",
    "defender-enable",
    "disable-power-saving",
    "install-toolbox",
    "keyboard-single",
    "mitigations-disable",
    "uninstall-edge",
];

fn contradicting_pc() -> Facts {
    Facts {
        packages: vec![NO_DEFENDER.into(), NO_TELEMETRY.into()],
        toggles: records(&[("AutomaticUpdates", 1), ("Mitigations", 2), ("PowerSaving", 0), ("VbsState", 0)]),
        edge: Some(false),
        appx: vec![
            "Microsoft.ScreenSketch_8wekyb3d8bbwe".into(),
            "Microsoft.WindowsCalculator_8wekyb3d8bbwe".into(),
        ],
        toolbox: Some(true),
        core_isolation_off: Some(true),
        browsers: Some(Vec::new()),
        defender: Some(false),
        ..Facts::default()
    }
}

/// What that PC has: what it shows, and the keyboard choice from the record.
const ON_THE_PC: &[&str] = &[
    "auto-updates-default",
    "defender-disable",
    "disable-core-isolation",
    "disable-power-saving",
    "install-toolbox",
    "keyboard-single",
    "mitigations-default",
    "uninstall-edge",
];

/// Updating or reinstalling an installed Atlas asks first whether to keep its
/// choices; a first install, an unfinished one, Atlas put back after Windows
/// rebuilt itself, and an ISO's setup don't.
#[test]
fn only_an_update_or_reinstall_of_an_installed_atlas_asks_how() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("update-path-when");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", CONTRADICTED));
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let asks = |m: &AppModel| {
            let first = m.option_screens()[0].kind == ScreenKind::UpdatePath;
            assert_eq!(first, m.update_choices().is_some());
            first
        };
        read(&cx, &model, |m| {
            assert!(asks(m));
            let choices = m.update_choices().unwrap();
            assert_eq!((choices.previous.as_str(), choices.reinstall), ("0.6.0", true), "a reinstall");
        });
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| assert!(asks(m) && !m.update_choices().unwrap().reinstall, "an update"));

        let others = [
            InstallIdentity::Fresh,
            InstallIdentity::Resume(
                "0.6.0".into(),
                held(CONTRADICTED.iter().map(|o| (*o).to_owned()).collect()),
            ),
            InstallIdentity::Resume("0.6.0".into(), Default::default()),
        ];
        for identity in others {
            *machine.identity.lock().unwrap() = Some(identity.clone());
            act(&mut cx, &model, |m, _| m.refresh_atlas_state());
            read(&cx, &model, |m| assert!(!asks(m), "{identity:?}"));
        }
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        act(&mut cx, &model, |m, _| {
            m.refresh_atlas_state();
            m.update_access = Some(rebuilt(KEPT, true));
            assert!(!asks(m), "after Windows rebuilt itself the record decides");
            m.update_access = Some(rebuilt(KEPT, false));
            assert!(asks(m), "Windows moved in place");
            m.before_desktop = true;
            assert!(!asks(m), "an ISO's setup");
        });
    });
}

/// Keeping the choices sends what this PC has, which wins over a record an
/// earlier update wrote without applying it, names where the two disagree,
/// and changes none of them; with every one known, Your choices is just the
/// first screen.
#[test]
fn keeping_the_choices_sends_what_the_pc_has_whatever_the_record_says() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("update-path-keep");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", CONTRADICTED));
        *machine.facts.lock().unwrap() = contradicting_pc();
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            load_builtin(m, temp.path());
            m.start_flow_at(Step::Options, cx);
        });
        read(&cx, &model, |m| {
            assert_eq!(m.update_path, UpdatePath::Keep, "the default");
            let choices = m.update_choices().unwrap();
            assert_eq!(sorted(&choices.kept), sorted(ON_THE_PC));
            assert!(choices.complete());
            assert_eq!(
                choices.differs,
                [ScreenKind::Defender, ScreenKind::Mitigations, ScreenKind::Updates, ScreenKind::Power]
            );
            assert_eq!(sorted(&m.locked_options().unwrap()), sorted(ON_THE_PC));
            assert_eq!(sorted(&m.effective_options()), sorted(ON_THE_PC));
            assert_eq!(m.option_screens().len(), 1, "nothing to ask");
            for option in ["defender-enable", "mitigations-disable", "disable-hibernation", "uninstall-edge"]
            {
                assert_eq!(m.fixed_option(option), Some(FixedChoice::Kept), "{option}");
            }
            let request = m.install_request().unwrap();
            assert!(!request.choose_again);
            assert_eq!(sorted(&request.options), sorted(ON_THE_PC));
        });
        act(&mut cx, &model, |m, cx| {
            let before = m.options.clone();
            m.choose_option(page_of(m, "defender-enable"), "defender-enable", cx);
            m.choose_option(page_of(m, "disable-hibernation"), "disable-hibernation", cx);
            assert_eq!(m.options, before, "a choice kept as the PC has it can't be changed");
            // Continue goes straight on to Windows Security.
            m.next_step(cx);
            assert_eq!(m.flow.step, Step::Security);
        });
        settle(&cx, &model).await;
    });
}

/// An Atlas 0.5.0 PC shows no Mitigations choice when only the old Toolbox
/// wrote its record, so keeping the choices asks that one alone and fixes
/// the rest. Atlas 0.5.0's own launcher, or Atlas 0.6, leaves a record that
/// shows it.
#[test]
fn keeping_the_choices_asks_only_what_the_pc_cannot_show() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("update-path-partial");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        // The Toolbox's 2 is Windows' default there, every protection on here.
        let toolbox_record = Facts {
            packages: vec![NO_TELEMETRY.into()],
            toggles: records(&[("Mitigations", 2), ("AutomaticUpdates", 0)]),
            edge: Some(true),
            language_hotkey: Some("1".into()),
            ..Facts::default()
        };
        *machine.facts.lock().unwrap() = toolbox_record.clone();
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Options, cx));
        read(&cx, &model, |m| {
            let choices = m.update_choices().unwrap();
            assert_eq!(choices.missing, [ScreenKind::Mitigations]);
            assert_eq!(
                sorted(&choices.kept),
                sorted(&["auto-updates-disable", "defender-enable", "keyboard-shortcuts"])
            );
            assert!(m.locked_options().is_none());
            let kinds: Vec<ScreenKind> = m.option_screens().iter().map(|screen| screen.kind).collect();
            assert_eq!(kinds, [ScreenKind::UpdatePath, ScreenKind::Mitigations]);
            assert_eq!(m.fixed_option("mitigations-disable"), None);
            assert_eq!(m.fixed_option("auto-updates-default"), Some(FixedChoice::Kept));
            assert_eq!(m.fixed_option("disable-hibernation"), Some(FixedChoice::Kept));
        });
        act(&mut cx, &model, |m, cx| {
            m.choose_option(page_of(m, "mitigations-disable"), "mitigations-disable", cx);
            m.choose_option(page_of(m, "auto-updates-default"), "auto-updates-default", cx);
            // The first screen, then the one choice asked, then Windows Security.
            m.next_step(cx);
            assert_eq!((m.flow.step, m.current_option_screen()), (Step::Options, 1));
            m.next_step(cx);
            assert_eq!(m.flow.step, Step::Security);
        });
        read(&cx, &model, |m| {
            assert_eq!(
                sorted(&m.effective_options()),
                sorted(&[
                    "auto-updates-disable",
                    "defender-enable",
                    "keyboard-shortcuts",
                    "mitigations-disable"
                ])
            );
        });

        // Atlas 0.5.0's launcher leaves its name beside the record it applied.
        let mut launcher_record = toolbox_record.clone();
        launcher_record.launchers.insert("Mitigations".into(), "Disable All Mitigations.cmd".into());
        *machine.facts.lock().unwrap() = launcher_record;
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            let choices = m.update_choices().unwrap();
            assert!(
                choices.complete() && choices.kept.iter().any(|o| o == "mitigations-disable"),
                "{choices:?}"
            );
        });
        // Atlas 0.6 records its own choices without one.
        *machine.facts.lock().unwrap() = toolbox_record;
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        *machine.state.lock().unwrap() = Some(recorded(
            "0.6.0",
            &["defender-enable", "mitigations-disable", "auto-updates-disable", "keyboard-shortcuts"],
        ));
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            let choices = m.update_choices().unwrap();
            assert!(choices.kept.iter().any(|o| o == "mitigations-default"), "{choices:?}");
            assert_eq!(choices.differs, [ScreenKind::Mitigations]);
        });
        settle(&cx, &model).await;
    });
}

/// Get ready's record of a move read an Atlas 0.5.0's toggle records as they
/// were, so the Mitigations choice it took from the old Toolbox's own record
/// isn't kept: the PC shows none, so keeping the choices asks it, as with no
/// record. The rest of what it carried fills what the PC can't show.
#[test]
fn a_mitigations_choice_carried_from_the_old_toolbox_s_record_is_asked() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("update-path-carried");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        // The Toolbox's Disable mitigations, which never reached the PC.
        let toolbox_record = Facts {
            packages: vec![NO_TELEMETRY.into()],
            toggles: records(&[("Mitigations", 0), ("AutomaticUpdates", 0)]),
            edge: Some(true),
            ..Facts::default()
        };
        *machine.facts.lock().unwrap() = toolbox_record.clone();
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        let carried = ["defender-enable", "mitigations-disable", "auto-updates-disable", "keyboard-single"];
        act(&mut cx, &model, |m, _| m.update_access = Some(rebuilt(&carried, false)));
        read(&cx, &model, |m| {
            let choices = m.update_choices().expect("Windows moved in place");
            assert_eq!(choices.missing, [ScreenKind::Mitigations], "{choices:?}");
            assert_eq!(
                sorted(&choices.kept),
                sorted(&["auto-updates-disable", "defender-enable", "keyboard-single"])
            );
            assert!(m.locked_options().is_none());
            assert_eq!(m.fixed_option("mitigations-disable"), None);
        });
        // Atlas 0.5.0's launcher leaves its name beside the record it applied.
        let mut launcher_record = toolbox_record;
        launcher_record.launchers.insert("Mitigations".into(), "Set Windows Default Mitigations.cmd".into());
        *machine.facts.lock().unwrap() = launcher_record;
        act(&mut cx, &model, |m, _| {
            m.refresh_atlas_state();
            m.update_access = Some(rebuilt(&carried, false));
        });
        read(&cx, &model, |m| {
            let choices = m.update_choices().unwrap();
            assert!(choices.complete(), "{choices:?}");
            assert!(choices.kept.iter().any(|o| o == "mitigations-default"), "what the PC shows");
            assert!(!choices.kept.iter().any(|o| o == "mitigations-disable"));
        });
    });
}

/// Atlas 0.5.0 recorded LibreWolf as an empty browser name, so on its PCs
/// the one browser installed is the one it chose, and keeping the choices
/// sends it. With two installed, neither is taken for a choice.
#[test]
fn an_update_from_0_5_0_keeps_the_librewolf_it_recorded_without_a_name() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("update-path-librewolf");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.5.0".into()));
        let librewolf = Facts {
            packages: vec![NO_TELEMETRY.into()],
            toggles: records(&[("Mitigations", 1), ("AutomaticUpdates", 0)]),
            launchers: [("Mitigations".to_owned(), "Set Windows Default Mitigations.cmd".to_owned())].into(),
            browser: Some(String::new()),
            browsers: Some(vec!["browser-librewolf".into()]),
            language_hotkey: Some("1".into()),
            ..Facts::default()
        };
        *machine.facts.lock().unwrap() = librewolf.clone();
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            load_builtin(m, temp.path());
            m.start_flow_at(Step::Options, cx);
        });
        read(&cx, &model, |m| {
            let choices = m.update_choices().unwrap();
            assert!(choices.complete(), "{choices:?}");
            let locked = m.locked_options().expect("keeping them changes none");
            let request = m.install_request().unwrap();
            for option in ["install-another-browser", "browser-librewolf"] {
                assert!(locked.iter().any(|o| o == option), "{option}: {locked:?}");
                assert!(request.options.iter().any(|o| o == option), "{option}: {:?}", request.options);
            }
        });
        let both =
            Facts { browsers: Some(vec!["browser-firefox".into(), "browser-librewolf".into()]), ..librewolf };
        *machine.facts.lock().unwrap() = both;
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            let kept = m.update_choices().unwrap().kept;
            assert!(
                !kept.iter().any(|o| o == "install-another-browser" || o.starts_with("browser-")),
                "{kept:?}"
            );
        });
        settle(&cx, &model).await;
    });
}

/// Choosing again opens every screen, starting from the same choices, and
/// asks the install to apply them; what an update can't undo stays ticked.
/// Snipping Tool gone from this account may be on others, so it stays open.
/// Keeping the choices again goes back to what the PC has.
#[test]
fn choosing_again_opens_every_choice_but_what_an_update_cannot_undo() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("update-path-choose-again");
        let record = [
            "defender-enable",
            "mitigations-disable",
            "auto-updates-disable",
            "keyboard-single",
            "uninstall-edge",
            "install-another-browser",
            "browser-brave",
            "install-toolbox",
        ];
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", &record));
        *machine.facts.lock().unwrap() = Facts {
            appx: vec!["Microsoft.WindowsCalculator_8wekyb3d8bbwe".into()],
            core_isolation_off: Some(false),
            browser: Some("Brave".into()),
            browsers: Some(vec!["browser-brave".into()]),
            toolbox_program: Some(true),
            ..contradicting_pc()
        };
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            load_builtin(m, temp.path());
            m.start_flow_at(Step::Options, cx);
        });
        let kept = read(&cx, &model, |m| m.update_choices().unwrap().kept);
        assert!(
            kept.iter().any(|o| o == "remove-snipping-tool") && kept.iter().any(|o| o == "defender-disable")
        );
        act(&mut cx, &model, |m, cx| {
            let start = m.options.clone();
            m.set_update_path(UpdatePath::ChooseAgain, cx);
            assert_eq!(m.options, start, "the same start as keeping them");
            assert_eq!(m.option_screens().len(), m.choice_screens().len() + 1, "every screen");
            assert!(m.locked_options().is_none());
            assert_eq!(m.fixed_option("uninstall-edge"), Some(FixedChoice::EdgeRemoved));
            assert_eq!(
                m.fixed_option("install-toolbox"),
                Some(FixedChoice::Installed("install-toolbox".into()))
            );
            assert_eq!(
                m.fixed_option("install-another-browser"),
                Some(FixedChoice::Installed("browser-brave".into()))
            );
            for open in [
                "defender-enable",
                "mitigations-disable",
                "disable-hibernation",
                "browser-firefox",
                "remove-snipping-tool",
            ] {
                assert_eq!(m.fixed_option(open), None, "{open}");
            }
            m.choose_option(page_of(m, "uninstall-edge"), "uninstall-edge", cx);
            m.choose_option(page_of(m, "install-toolbox"), "install-toolbox", cx);
            assert!(
                m.options.contains("uninstall-edge") && m.options.contains("install-toolbox"),
                "still ticked"
            );
            assert!(m.options.contains("remove-snipping-tool"), "ticked as this account shows it");
            m.choose_option(page_of(m, "remove-snipping-tool"), "remove-snipping-tool", cx);
            m.choose_option(page_of(m, "defender-enable"), "defender-enable", cx);
            m.choose_option(page_of(m, "browser-firefox"), "browser-firefox", cx);
        });
        read(&cx, &model, |m| {
            let request = m.install_request().unwrap();
            assert!(request.choose_again);
            for option in ["defender-enable", "install-another-browser", "browser-firefox", "uninstall-edge"]
            {
                assert!(request.options.iter().any(|o| o == option), "{option}: {:?}", request.options);
            }
            assert!(
                !request.options.iter().any(|o| o == "remove-snipping-tool"),
                "the other accounts keep it"
            );
            // Brave stays installed while Atlas installs Firefox as well.
            assert_eq!(
                m.fixed_option("install-another-browser"),
                Some(FixedChoice::Installed("browser-brave".into()))
            );
        });
        act(&mut cx, &model, |m, cx| m.set_update_path(UpdatePath::Keep, cx));
        read(&cx, &model, |m| {
            assert_eq!(
                sorted(&m.options.iter().collect::<Vec<_>>()),
                sorted(&kept),
                "back to what the PC has"
            );
            assert_eq!(m.locked_options(), Some(kept.clone()));
            assert!(!m.install_request().unwrap().choose_again);
        });

        // A Toolbox someone uninstalled is still ticked by Atlas's record of
        // the last installation, but nothing is installed to fix it.
        let uninstalled = Facts {
            toolbox: Some(false),
            toolbox_program: Some(false),
            ..machine.facts.lock().unwrap().clone()
        };
        *machine.facts.lock().unwrap() = uninstalled;
        act(&mut cx, &model, |m, cx| {
            m.refresh_atlas_state();
            m.set_update_path(UpdatePath::ChooseAgain, cx);
            assert!(m.options.contains("install-toolbox"));
            assert_eq!(m.fixed_option("install-toolbox"), None);
            m.choose_option(page_of(m, "install-toolbox"), "install-toolbox", cx);
            assert!(!m.effective_options().iter().any(|o| o == "install-toolbox"));
        });
        settle(&cx, &model).await;
    });
}

/// How the update treats the choices is part of the draft: the elevated copy,
/// or the app started again, goes on with it, and a new flow starts over
/// with keeping them.
#[test]
fn the_update_path_survives_a_relaunch_and_a_new_flow_keeps_the_choices() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("update-path-draft");
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Installed("0.6.0".into()));
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", CONTRADICTED));
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            m.start_flow_at(Step::Options, cx);
            m.set_update_path(UpdatePath::ChooseAgain, cx);
        });
        wait_on_disk(&cx, &env, "choosing again", |s| {
            s.draft.as_ref().is_some_and(|draft| draft.update_path.as_deref() == Some("choose-again"))
        })
        .await;
        settle(&cx, &model).await;

        let relaunched = new_model(&mut cx, env.clone());
        wait_for(&cx, &relaunched, "the resumed draft", |m| !m.recovering && m.flow.active).await;
        read(&cx, &relaunched, |m| {
            assert_eq!((m.flow.step, m.update_path), (Step::Options, UpdatePath::ChooseAgain));
            assert!(m.choosing_again());
        });
        act(&mut cx, &relaunched, |m, cx| m.begin_install(cx));
        assert_eq!(read(&cx, &relaunched, |m| m.update_path), UpdatePath::Keep);
        wait_on_disk(&cx, &env, "the new flow keeping them", |s| {
            s.draft.as_ref().is_some_and(|draft| draft.update_path.as_deref() == Some("keep"))
        })
        .await;
        settle(&cx, &relaunched).await;
    });
}

/// An unfinished update that hasn't run a step and began keeping the
/// choices starts its capture again, which keeps every choice this PC shows
/// whatever is sent. So Your choices holds them as keeping them does, asking
/// only what the PC can't show, and the install records what was sent.
/// Choosing again, or a first install, leaves every choice open.
#[test]
fn an_unfinished_update_that_will_keep_the_choices_holds_what_the_pc_has() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("update-path-resume-keep");
        let resume = |choose_again, mode| {
            InstallIdentity::Resume("0.6.0".into(), Unfinished { held: None, choose_again, mode })
        };
        *machine.identity.lock().unwrap() = Some(resume(false, InstallMode::Reapply));
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", CONTRADICTED));
        *machine.facts.lock().unwrap() = contradicting_pc();
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| {
            load_builtin(m, temp.path());
            m.start_flow_at(Step::Options, cx);
        });
        read(&cx, &model, |m| {
            assert!(m.update_choices().is_none(), "no first screen: it goes on as it began");
            assert_eq!(sorted(&m.locked_options().unwrap()), sorted(ON_THE_PC));
            assert_eq!(m.option_screens(), m.choice_screens(), "each screen shows what it keeps");
            assert_eq!(m.fixed_option("defender-enable"), Some(FixedChoice::Kept));
            let request = m.install_request().unwrap();
            assert!(!request.choose_again);
            assert_eq!(sorted(&request.options), sorted(ON_THE_PC));
        });
        act(&mut cx, &model, |m, cx| {
            let before = m.effective_options();
            m.choose_option(page_of(m, "defender-enable"), "defender-enable", cx);
            assert_eq!(m.effective_options(), before, "the capture takes it from the PC");
        });

        // Neither the record nor the PC shows processor protections, which alone are asked.
        let unrecorded: Vec<&str> =
            CONTRADICTED.iter().copied().filter(|option| !option.starts_with("mitigations-")).collect();
        *machine.state.lock().unwrap() = Some(recorded("0.6.0", &unrecorded));
        let mut pc = contradicting_pc();
        pc.toggles.remove("Mitigations");
        *machine.facts.lock().unwrap() = pc;
        act(&mut cx, &model, |m, _| m.refresh_atlas_state());
        read(&cx, &model, |m| {
            assert!(m.locked_options().is_none());
            let kinds: Vec<ScreenKind> = m.option_screens().iter().map(|screen| screen.kind).collect();
            assert_eq!(kinds, [ScreenKind::Mitigations]);
            assert_eq!(m.fixed_option("mitigations-disable"), None);
            assert_eq!(m.fixed_option("auto-updates-disable"), Some(FixedChoice::Kept));
        });

        for identity in [resume(true, InstallMode::Reapply), resume(false, InstallMode::Fresh)] {
            *machine.identity.lock().unwrap() = Some(identity.clone());
            act(&mut cx, &model, |m, _| m.refresh_atlas_state());
            read(&cx, &model, |m| {
                assert!(m.unfinished_choices().is_none() && m.locked_options().is_none(), "{identity:?}");
                assert_eq!(m.fixed_option("defender-enable"), None, "{identity:?}");
                assert_eq!(m.option_screens(), m.choice_screens(), "{identity:?}");
            });
        }
        settle(&cx, &model).await;
    });
}

/// An unfinished install has no first screen, so it chooses again only if
/// it began so, whatever this flow says: once a step has run, and before,
/// in a new flow that starts over keeping the choices.
#[test]
fn an_unfinished_install_chooses_again_only_as_it_began() {
    run_model_test(|mut cx| async move {
        let (temp, machine, env) = fixture("update-path-resume");
        let options: Vec<String> = ON_THE_PC.iter().map(|o| (*o).to_owned()).collect();
        let resume = |held: bool, choose_again| {
            let held = held.then(|| options.clone());
            InstallIdentity::Resume(
                "0.6.0".into(),
                Unfinished { held, choose_again, mode: InstallMode::Reapply },
            )
        };
        *machine.identity.lock().unwrap() = Some(resume(true, true));
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, _| load_builtin(m, temp.path()));
        read(&cx, &model, |m| {
            assert!(m.update_choices().is_none() && m.option_screens()[0].kind != ScreenKind::UpdatePath);
            let request = m.install_request().unwrap();
            assert!(request.choose_again && request.options == options);
        });
        for held in [true, false] {
            *machine.identity.lock().unwrap() = Some(resume(held, false));
            act(&mut cx, &model, |m, _| {
                m.refresh_atlas_state();
                m.update_path = UpdatePath::ChooseAgain;
                assert!(!m.install_request().unwrap().choose_again, "it began keeping them, held {held}");
            });
        }
        // Choose again's capture ran, then the plan stopped before any step:
        // the next flow, which starts over keeping the choices, goes on with it.
        *machine.identity.lock().unwrap() = Some(resume(false, true));
        act(&mut cx, &model, |m, cx| {
            m.elevated = true;
            m.begin_install(cx);
            assert!(m.flow.active);
            load_builtin(m, temp.path());
            assert_eq!(m.update_path, UpdatePath::Keep);
            assert!(m.update_choices().is_none(), "no first screen");
            assert!(m.install_request().unwrap().choose_again);
        });
        settle(&cx, &model).await;
        // A first install never chooses again.
        *machine.identity.lock().unwrap() = Some(InstallIdentity::Fresh);
        act(&mut cx, &model, |m, _| {
            m.refresh_atlas_state();
            m.update_path = UpdatePath::ChooseAgain;
            assert!(!m.choosing_again());
        });
    });
}
