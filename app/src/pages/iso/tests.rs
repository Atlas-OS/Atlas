use super::*;
use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
use crate::services::test_support::TempDir;

#[test]
fn a_check_sends_no_network_driver_choices() {
    // Made on the Setup step, which applies to the build only.
    assert_eq!(network_choices(true, true, true), (false, false));
    assert_eq!(network_choices(false, true, true), (true, true));
    assert_eq!(network_choices(false, true, false), (true, false));
    assert_eq!(network_choices(false, false, true), (false, false));
}

const ALL_DONE: Gates = Gates { checked: true, account: true };

#[test]
fn the_stepper_goes_back_freely_and_forward_only_to_visited_steps_that_still_hold() {
    use IsoStep::*;
    // Back to any earlier step; never to the step showing.
    assert!(ALL_DONE.reachable(Create, Windows, Create));
    assert!(Gates::default().reachable(Setup, Windows, Setup));
    assert!(!ALL_DONE.reachable(Setup, Setup, Create));
    // Forward only as far as the furthest step reached.
    assert!(ALL_DONE.reachable(Windows, Create, Create));
    assert!(!ALL_DONE.reachable(Windows, Create, Setup));
    // Never past a step that no longer holds: an account name cleared on
    // Setup keeps Create out of reach from there and from Windows.
    let no_account = Gates { account: false, ..ALL_DONE };
    assert!(!no_account.reachable(Setup, Create, Create));
    assert!(!no_account.reachable(Windows, Create, Create));
    assert!(no_account.reachable(Windows, Setup, Create));
    // Files that no longer passed the check keep everything after them out of reach.
    let unchecked = Gates { checked: false, ..ALL_DONE };
    assert!(!unchecked.reachable(Windows, Setup, Create));
}

#[test]
fn steps_the_user_went_past_stay_done_while_an_earlier_one_shows() {
    use IsoStep::*;
    let statuses =
        |current, furthest, gates| IsoStep::ALL.map(|step| step_status(step, current, furthest, gates));
    use StepStatus::{Attention, Current, Done, Upcoming};
    assert_eq!(statuses(Setup, Setup, ALL_DONE), [Done, Current, Upcoming]);
    // Back on Windows from Create: Setup is still done, and Create, never
    // finished, is still to come.
    assert_eq!(statuses(Windows, Create, ALL_DONE), [Current, Done, Upcoming]);
    // Visited but not gone past.
    assert_eq!(statuses(Windows, Setup, ALL_DONE), [Current, Upcoming, Upcoming]);
    let no_account = Gates { account: false, ..ALL_DONE };
    assert_eq!(statuses(Windows, Create, no_account), [Current, Upcoming, Upcoming]);
    assert_eq!(statuses(Create, Create, no_account), [Done, Attention, Current]);
}

#[test]
fn a_build_ticks_off_its_stages_and_marks_the_one_that_failed() {
    let states = |reported, failed| {
        Stage::build(false).into_iter().map(|stage| stage_state(stage, reported, failed)).collect::<Vec<_>>()
    };
    use StageState::*;
    assert_eq!(
        states(Stage::Inspect, false),
        [Current, NotStarted, NotStarted, NotStarted, NotStarted, NotStarted]
    );
    assert_eq!(states(Stage::Master, false), [Done, Done, Done, Current, NotStarted, NotStarted]);
    assert_eq!(states(Stage::Master, true), [Done, Done, Done, Failed, NotStarted, NotStarted]);
    assert_eq!(states(Stage::Cleanup, false), [Done, Done, Done, Done, Done, Current]);
}

#[test]
fn the_progress_bar_grows_by_the_stages_finished_and_never_goes_back() {
    for network in [false, true] {
        let stages = Stage::build(network);
        let values: Vec<f32> = stages.iter().map(|stage| build_progress(*stage, network, None)).collect();
        assert_eq!(values[0], 0., "nothing is finished while the ISO is read");
        assert!(values.windows(2).all(|pair| pair[0] < pair[1]), "{values:?}");
        assert!(*values.last().unwrap() < 1.);
    }
    // Copying Windows and writing the ISO take most of a build.
    let before_master = build_progress(Stage::Master, false, None);
    let after_master = build_progress(Stage::Verify, false, None);
    assert!(after_master - before_master > 0.25);
    // Within a stage the bar follows its bytes, and reaches the next stage's
    // start once they're all written.
    let half = build_progress(Stage::Master, false, Some(0.5));
    assert!(before_master < half && half < after_master);
    assert!((build_progress(Stage::Master, false, Some(1.)) - after_master).abs() < 1e-6);
    // A stage a build without network drivers doesn't have adds nothing.
    assert_eq!(
        build_progress(Stage::NetworkDrivers, false, Some(0.5)),
        build_progress(Stage::NetworkDrivers, false, None)
    );
}

#[test]
fn a_stage_says_plainly_where_it_stands() {
    crate::i18n::testing::english(|| {
        assert_eq!(
            stage_name(&stage_text(Stage::Master), StageState::Failed),
            "Writing the ISO file, failed"
        );
        assert_eq!(
            stage_name(&stage_text(Stage::Copy), StageState::Done),
            "Copying Windows files, completed"
        );
        assert!(!stage_name("x", StageState::Current).contains("Step"));
        // The bar's label is a verb phrase that ends in an ellipsis.
        assert_eq!(t!("iso-progress-stage", stage = stage_text(Stage::Inspect)), "Reading the Windows ISO…");
        assert!(t!("iso-cancelling-short").ends_with('…'));
    });
}

#[test]
fn an_empty_account_name_waits_and_a_refused_one_says_what_to_change() {
    crate::i18n::testing::english(|| {
        assert_eq!(account_error(""), None);
        assert_eq!(account_error("Atlas"), None);
        assert_eq!(account_error("Atlas/PC"), Some(t!("iso-account-invalid")));
        assert_eq!(account_error("Atlas."), Some(t!("iso-account-trailing-dot")));
        assert_eq!(account_error("Guest"), Some(t!("iso-account-reserved")));
    });
    // The message lists every symbol the check refuses, in every language.
    // The symbols are found by asking the check, so the two can't drift apart.
    let refused: Vec<char> = (' '..='~')
        .filter(|c| c.is_ascii_punctuation())
        .filter(|c| iso::username_problem(&format!("Atlas{c}PC")) == Some(UsernameProblem::Invalid))
        .collect();
    for locale in crate::i18n::catalog::LOCALES.iter().filter(|locale| !locale.pseudo) {
        crate::i18n::testing::with_chain(&[locale.tag], || {
            let message = t!("iso-account-invalid");
            for symbol in &refused {
                assert!(message.contains(*symbol), "{}: {symbol}", locale.tag);
            }
        });
    }
}

#[test]
fn the_suggested_iso_never_overwrites_a_file() {
    let folder = Path::new(r"C:\Downloads");
    assert_eq!(free_output(folder, |_| false), folder.join("Atlas-Windows.iso"));
    let taken = [folder.join("Atlas-Windows.iso"), folder.join("Atlas-Windows (2).iso")];
    assert_eq!(
        free_output(folder, |path| taken.iter().any(|t| t == path)),
        folder.join("Atlas-Windows (3).iso")
    );
}

#[test]
fn a_name_that_appeared_since_it_was_chosen_moves_to_the_next_free_one() {
    let folder = Path::new(r"C:\Downloads");
    let taken = [folder.join("Mine.iso"), folder.join("Mine (2).iso"), folder.join("Other (4).iso")];
    let exists = |path: &Path| taken.iter().any(|t| t == path);
    assert_eq!(unused_path(&folder.join("Free.iso"), exists), folder.join("Free.iso"));
    assert_eq!(unused_path(&folder.join("Mine.iso"), exists), folder.join("Mine (3).iso"));
    assert_eq!(unused_path(&folder.join("Mine (2).iso"), exists), folder.join("Mine (3).iso"));
    // A number of its own counts on from the base name.
    assert_eq!(unused_path(&folder.join("Other (4).iso"), exists), folder.join("Other.iso"));
}

#[test]
fn this_pc_s_edition_is_found_by_its_windows_name() {
    let editions = ["Windows 11 Pro".to_string(), "Windows 11 Education".into(), "Windows 11 Pro N".into()];
    assert_eq!(this_pc_edition("Professional", &editions).as_deref(), Some("Windows 11 Pro"));
    assert_eq!(this_pc_edition("ProfessionalN", &editions).as_deref(), Some("Windows 11 Pro N"));
    assert_eq!(this_pc_edition("Education", &editions).as_deref(), Some("Windows 11 Education"));
    // Not on the ISO, or not an edition Atlas installs: Windows Setup asks.
    assert_eq!(this_pc_edition("Enterprise", &editions), None);
    assert_eq!(this_pc_edition("Core", &editions), None);
    assert_eq!(this_pc_edition("", &editions), None);
}

#[test]
fn only_failures_nothing_on_the_page_fixes_get_the_help_row() {
    use FailureReason::*;
    // Other media, a package to change, a connection or free space: the bar has the fix.
    for reason in [
        EditionUnsupported,
        IsoCustomised,
        IsoCreatedByAtlas,
        IsoMountFile,
        WindowsReleaseUnlisted,
        WindowsUnsupported,
    ] {
        assert!(!failure_needs_help(Some(reason), true, true), "{reason:?}");
    }
    for reason in [
        WindowsReleaseUnknown,
        PackageUnsupported,
        PackageIsWindowsIso,
        ManagerOutdated,
        DiskSpace,
        DestinationPath,
        IsoMountDrivers,
    ] {
        assert!(!failure_needs_help(Some(reason), true, true), "{reason:?}");
        assert!(!failure_needs_help(Some(reason), false, true), "{reason:?}");
    }
    // Unexpected failures, and a job that never started, do.
    for reason in
        [Some(Check), Some(Build), Some(ManagerMissing), Some(IsoMount), Some(IsoMountTimeout), None]
    {
        assert!(failure_needs_help(reason, true, true), "{reason:?}");
        assert!(failure_needs_help(reason, false, true), "{reason:?}");
    }
    assert!(failure_needs_help(Some(EditionUnsupported), true, false), "nothing ran");
}

fn page(cx: &mut gpui::AsyncApp, temp: &TempDir) -> Entity<IsoPage> {
    let model = new_model(cx, Machine::new(all_off()).environment(temp.path()));
    cx.update(|cx| cx.new(|cx| IsoPage::new(model.clone(), cx)))
}

fn image(architecture: Architecture) -> ImageInfo {
    ImageInfo {
        edition_terms: vec!["0".repeat(64)],
        editions: vec!["Windows 11 Pro".into()],
        bytes: 1,
        architecture,
    }
}

#[test]
fn each_failure_is_named_and_says_what_to_do() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-failure-text");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            page.result = JobResult::Failed(None);
            page.job = None;
            assert_eq!(page.failure_text(), (t!("iso-check-failed"), t!("iso-unstaged")));
            page.step = IsoStep::Create;
            assert_eq!(page.failure_text(), (t!("iso-failed"), t!("iso-unstaged")));

            page.job = Some(temp.path().to_path_buf());
            assert_eq!(page.failure_text().1, t!("iso-failed-retry"));
            page.step = IsoStep::Windows;
            assert_eq!(page.failure_text().1, t!("iso-check-failed-retry"));
            // The title names the problem with the media.
            for (reason, title) in [
                (FailureReason::EditionUnsupported, t!("iso-edition-unsupported-title")),
                (FailureReason::IsoCustomised, t!("iso-customised-title")),
                (FailureReason::IsoCreatedByAtlas, t!("iso-created-by-atlas-title")),
                (FailureReason::WindowsReleaseUnlisted, t!("iso-preview-title")),
                (FailureReason::WindowsReleaseUnknown, t!("iso-release-unknown-title")),
                (FailureReason::PackageUnsupported, t!("iso-package-old-title")),
                (FailureReason::PackageIsWindowsIso, t!("iso-package-windows-iso-title")),
            ] {
                page.result = JobResult::Failed(Some(reason));
                assert_eq!(page.failure_text().0, title, "{reason:?}");
            }
            // A Windows ISO chosen as the package isn't sent to another Atlas version.
            page.result = JobResult::Failed(Some(FailureReason::PackageIsWindowsIso));
            let message = page.failure_text().1;
            assert_eq!(message, t!("iso-package-windows-iso"));
            assert!(!message.contains(iso::MINIMUM_VERSION), "{message}");
            // An ISO Atlas created has the setup files an altered ISO has.
            page.result = JobResult::Failed(Some(FailureReason::IsoCreatedByAtlas));
            assert_eq!(page.failure_text().1, t!("iso-customised"));
            assert!(other_media_fixes(Some(FailureReason::IsoCreatedByAtlas)));
            // An ISO Windows couldn't open says so, whether checking or building.
            page.result = JobResult::Failed(Some(FailureReason::IsoMount));
            assert_eq!(page.failure_text(), (t!("iso-check-failed"), t!("iso-mount-failed")));
            page.step = IsoStep::Create;
            assert_eq!(page.failure_text(), (t!("iso-failed"), t!("iso-mount-failed")));
            page.step = IsoStep::Windows;
            // Why Windows couldn't, when the worker knows: each says what to do about it.
            for (reason, message) in [
                (FailureReason::IsoMountDrivers, t!("iso-mount-drivers")),
                (FailureReason::IsoMountFile, t!("iso-mount-file")),
                (FailureReason::IsoMountTimeout, t!("iso-mount-timeout")),
            ] {
                page.result = JobResult::Failed(Some(reason));
                assert_eq!(page.failure_text(), (t!("iso-check-failed"), message), "{reason:?}");
            }
            // A copy of the ISO is the fix, so the bar offers another file.
            assert!(other_media_fixes(Some(FailureReason::IsoMountFile)));
            assert!(!other_media_fixes(Some(FailureReason::IsoMountDrivers)));
            // A network driver export that failed says so, with the way to leave them out.
            page.step = IsoStep::Create;
            // A folder too deep for the ISO's files, even at the drive's root.
            page.result = JobResult::Failed(Some(FailureReason::DestinationPath));
            assert_eq!(page.failure_text(), (t!("iso-failed"), t!("iso-path-too-long")));
            page.network_build = true;
            page.stage = Stage::NetworkDrivers;
            page.result = JobResult::Failed(Some(FailureReason::Build));
            assert_eq!(page.failure_text().1, t!("iso-network-not-added"));
        });
    });
}

#[test]
fn only_a_build_the_worker_ran_shows_the_stage_it_failed_at() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-failed-stage");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            page.step = IsoStep::Create;
            page.stage = Stage::Master;
            page.job = Some(temp.path().to_path_buf());
            page.result = JobResult::Failed(Some(FailureReason::Build));
            assert_eq!(page.failed_stage(), Some(Stage::Master));
            // Refused by Atlas before the worker started.
            page.result = JobResult::Failed(Some(FailureReason::PackageChanged));
            assert_eq!(page.failed_stage(), None);
            // No job: nothing ran.
            page.result = JobResult::Failed(None);
            page.job = None;
            assert_eq!(page.failed_stage(), None);
            // A failed check has no stages to show.
            page.job = Some(temp.path().to_path_buf());
            page.step = IsoStep::Windows;
            assert_eq!(page.failed_stage(), None);
            page.step = IsoStep::Create;
            page.result = JobResult::Cancelled;
            assert_eq!(page.failed_stage(), None);
        });
    });
}

#[test]
fn the_new_iso_follows_the_source_until_the_user_chooses_where_to_save_it() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-output");
        let (first, second) = (temp.path().join("first"), temp.path().join("second"));
        std::fs::create_dir_all(&first).unwrap();
        std::fs::create_dir_all(&second).unwrap();
        // An ISO made earlier keeps its name.
        std::fs::write(first.join("Atlas-Windows.iso"), b"earlier").unwrap();
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            page.source = Some(first.join("Windows.iso"));
            page.suggest_output();
            assert_eq!(page.output, Some(first.join("Atlas-Windows (2).iso")));
            page.source = Some(second.join("Windows.iso"));
            page.suggest_output();
            assert_eq!(page.output, Some(second.join("Atlas-Windows.iso")));
            // Chosen with Save as: it stays where the user put it.
            let chosen = temp.path().join("Mine.iso");
            page.output = Some(chosen.clone());
            page.output_suggested = false;
            page.source = Some(first.join("Windows.iso"));
            page.suggest_output();
            assert_eq!(page.output, Some(chosen));
        });
    });
}

#[test]
fn going_back_and_forward_keeps_every_choice_and_a_new_file_starts_again() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-steps");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            page.image = Some(image(Architecture::X64));
            page.username.update(cx, |input, cx| input.set_value("Ada", cx));
            page.go_to_step(IsoStep::Setup, cx);
            page.drivers = Some(Drivers::Manual);
            // Made now, which the package supports, with a choice of its own.
            page.setup_available = true;
            page.mode = Mode::Configured;
            let chosen: Vec<String> = vec!["defender-disable".into()];
            page.options = chosen.clone();
            page.go_to_step(IsoStep::Create, cx);
            page.go_to_step(IsoStep::Windows, cx);
            assert_eq!(page.furthest, IsoStep::Create);
            assert!(page.gates(cx).reachable(page.step, IsoStep::Create, page.furthest));
            assert_eq!(page.username.read(cx).value(), "Ada");
            assert_eq!(page.drivers, Some(Drivers::Manual));
            assert_eq!((page.mode, &page.options), (Mode::Configured, &chosen));
            // Choosing another file means checking again from the start.
            page.invalidate(cx);
            assert_eq!((page.step, page.furthest), (IsoStep::Windows, IsoStep::Windows));
            assert!(!page.gates(cx).reachable(IsoStep::Windows, IsoStep::Setup, page.furthest));
            assert_eq!(page.username.read(cx).value(), "Ada");
            // Kept for the next check, which carries them over for the same package.
            assert_eq!((page.mode, &page.options), (Mode::Configured, &chosen));
        });
    });
}

#[test]
fn a_result_stays_with_its_step() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-result-step");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            page.image = Some(image(Architecture::X64));
            page.step = IsoStep::Create;
            page.furthest = IsoStep::Create;
            page.finish(false, false, Err(anyhow::anyhow!("worker failed")), cx);
            // The step showing keeps its result.
            page.go_to_step(IsoStep::Create, cx);
            assert_eq!(page.result, JobResult::Failed(None));
            assert!(page.gates(cx).checked, "a failed build leaves the check standing");
            page.go_to_step(IsoStep::Setup, cx);
            assert_eq!(page.result, JobResult::None);
            // A cancelled check says nothing; a cancelled build says the ISO is as it was.
            page.finish(true, true, Err(anyhow::anyhow!("cancelled")), cx);
            assert_eq!(page.result, JobResult::None);
            page.step = IsoStep::Create;
            page.finish(false, true, Err(anyhow::anyhow!("cancelled")), cx);
            assert_eq!(page.result, JobResult::Cancelled);
        });
    });
}

#[test]
fn a_package_that_changed_before_create_is_checked_again_by_itself() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-package-changed");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            page.image = Some(image(Architecture::X64));
            page.step = IsoStep::Create;
            page.furthest = IsoStep::Create;
            page.finish(
                false,
                false,
                Err(iso::Failure::new(FailureReason::PackageChanged, "test").into()),
                cx,
            );
            // No failure to read: the check runs again, and then the build.
            assert_eq!(page.result, JobResult::None);
            assert!(page.rebuild);
            assert!(page.image.is_none());
            // A second change during that check isn't chased again.
            page.finish(
                false,
                false,
                Err(iso::Failure::new(FailureReason::PackageChanged, "test").into()),
                cx,
            );
            assert_eq!(page.result, JobResult::Failed(Some(FailureReason::PackageChanged)));
            assert!(!page.rebuild);
        });
    });
}

#[test]
fn an_iso_for_another_kind_of_processor_is_for_another_pc() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-architecture");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            assert!(page.reinstall_this_pc, "This PC is the default");
            let other = match iso::host_architecture() {
                Architecture::X64 => Architecture::Arm64,
                Architecture::Arm64 => Architecture::X64,
            };
            page.image = Some(image(other));
            assert!(!page.suits_this_pc());
            page.set_target(true, true, cx);
            assert!(!page.reinstall_this_pc, "This PC can't be chosen for it");
            // So the build can't refuse this PC's network drivers for it.
            let (reinstall, copy) = network_choices(false, page.reinstall_this_pc, page.copy_network_drivers);
            assert!(!reinstall && !copy);
            page.image = Some(image(iso::host_architecture()));
            page.set_target(true, true, cx);
            assert!(page.reinstall_this_pc);
        });
    });
}

#[test]
fn the_footer_says_what_an_unavailable_step_still_needs() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-hint");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            assert_eq!(page.hint(true, cx), t!("iso-need-windows"));
            // Without administrator permission the bar says it, not the footer.
            assert_eq!(page.hint(false, cx), "");
            page.step = IsoStep::Setup;
            assert_eq!(page.hint(true, cx), t!("iso-account-empty"));
            // A name with a problem says so in the field, not here.
            page.username.update(cx, |input, cx| input.set_value("Atlas/PC", cx));
            assert!(!page.gates(cx).account);
            assert_eq!(page.hint(true, cx), "");
            // Another job holding the app is why every step waits.
            page.model.update(cx, |m, _| {
                m.preparation = crate::services::preparation::State::Running {
                    stage: Default::default(),
                    completed: 0,
                    total: 0,
                }
            });
            assert_eq!(page.hint(true, cx), t!("iso-locked"));
            page.model.update(cx, |m, _| m.preparation = crate::services::preparation::State::Ready);
            assert_eq!(page.hint(true, cx), "");
        });
    });
}

#[test]
fn a_package_that_needs_a_newer_atlas_manager_is_known_before_any_check() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-manager-outdated");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, cx| {
            assert_eq!(page.manager_outdated(cx), None);
            page.model.update(cx, |m, _| {
                m.acquisition =
                    Acquisition::Failed(AcquireProblem::ManagerOutdated { required: Some("9.9.9".into()) })
            });
            assert_eq!(page.manager_outdated(cx), Some(Some("9.9.9".into())));
            // A package the user chose is judged by its own check.
            page.archive = Some(temp.path().join("Mine.atlaspkg"));
            assert_eq!(page.manager_outdated(cx), None);
            page.manager_required = None;
            page.result = JobResult::Failed(Some(FailureReason::ManagerOutdated));
            assert_eq!(page.manager_outdated(cx), Some(None));
        });
    });
}

#[test]
fn the_edition_menu_checks_the_current_edition_and_a_new_one_drops_the_accepted_terms() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-edition-menu");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            page.image = Some(ImageInfo {
                editions: vec!["Windows 11 Pro".into(), "Windows 11 Education".into()],
                ..image(Architecture::X64)
            });
            // Windows Setup asks, the first item, until an edition is chosen.
            assert_eq!(page.edition_menu_current(), 0);
            page.accept_terms = true;
            page.edition_menu = true;
            page.choose_edition(Some("Windows 11 Education".into()));
            assert_eq!(page.edition_menu_current(), 2);
            assert!(!page.accept_terms, "the terms accepted were another edition's");
            assert!(page.edition_chosen && !page.edition_menu);
            // Choosing the edition already shown keeps the terms.
            page.accept_terms = true;
            page.choose_edition(Some("Windows 11 Education".into()));
            assert!(page.accept_terms);
            page.choose_edition(None);
            assert_eq!(page.edition_menu_current(), 0);
        });
    });
}

#[test]
fn only_a_create_step_short_of_space_is_watched_for_space_freed() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-space");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            let destination = |problem| iso::Destination { drive: "C:".into(), free: 1, needed: 2, problem };
            page.step = IsoStep::Create;
            page.destination = Some(destination(Some(iso::DestinationProblem::Space)));
            assert!(page.short_of_space());
            // A volume of the wrong kind needs another folder, not space.
            page.destination = Some(destination(Some(iso::DestinationProblem::FileSystem)));
            assert!(!page.short_of_space());
            page.destination = Some(destination(Some(iso::DestinationProblem::Space)));
            page.step = IsoStep::Setup;
            assert!(!page.short_of_space());
        });
    });
}

#[test]
fn a_mode_the_package_cant_carry_builds_with_choices_after_sign_in() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-mode");
        let page = page(&mut cx, &temp);
        page.update(&mut cx, |page, _| {
            page.mode = Mode::BeforeDesktop;
            page.setup_available = false;
            assert_eq!(page.effective_mode(), Mode::Interactive);
            page.setup_available = true;
            assert_eq!(page.effective_mode(), Mode::BeforeDesktop);
        });
    });
}

/// Done on a USB drive made from the finished ISO ends the job as the page's
/// own Done does: Home, with the page ready for another ISO. Back from the
/// panel returns to the finished ISO.
#[test]
fn done_on_a_usb_drive_made_from_the_finished_iso_goes_home() {
    run_model_test(|mut cx| async move {
        let temp = TempDir::new("iso-usb-done");
        let page = page(&mut cx, &temp);
        let output = temp.path().join("Atlas-Windows.iso");
        let open = |cx: &mut gpui::AsyncApp| {
            page.update(cx, |page, cx| {
                page.model.update(cx, |m, _| m.page = Page::Iso);
                page.result = JobResult::Complete;
                page.output = Some(output.clone());
                let model = page.model.clone();
                let panel =
                    cx.new(|cx| UsbPage::new(model, Some(output.clone()), vec![], Some("usb-complete"), cx));
                page.show_usb(panel.clone(), cx);
                panel
            })
        };

        let panel = open(&mut cx);
        panel.update(&mut cx, |panel, cx| panel.back(cx));
        page.update(&mut cx, |page, cx| {
            assert_eq!(page.model.read(cx).page, Page::Iso, "Back stays on the page");
            assert_eq!(page.result, JobResult::Complete);
            assert_eq!(page.output.as_deref(), Some(output.as_path()));
        });

        let panel = open(&mut cx);
        panel.update(&mut cx, |panel, cx| panel.finish(cx));
        page.update(&mut cx, |page, cx| {
            assert_eq!(page.model.read(cx).page, Page::Home, "Done goes Home");
            assert!(page.usb.is_none());
            assert_eq!(page.result, JobResult::None, "ready for another ISO");
            assert_ne!(
                page.output.as_deref(),
                Some(output.as_path()),
                "the file just written isn't offered again"
            );
        });
    });
}
