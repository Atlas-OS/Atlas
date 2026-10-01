//! The screens of Your choices.

use crate::model::ScreenKind;
use crate::model::test_harness::{act, fixture, new_model, read, run_model_test, wait_for};

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
                m.option_screens().into_iter().find(|screen| screen.kind == ScreenKind::Extras).unwrap();
            let kinds: Vec<ScreenKind> =
                extras.pages.iter().map(|&page| ScreenKind::of_page(&manifest.pages[page])).collect();
            assert_eq!(
                kinds,
                [ScreenKind::Power, ScreenKind::Apps, ScreenKind::Browser, ScreenKind::OptionalApps],
                "the built-in package lists the browser picker last"
            );
            let browser = extras.pages[2];
            let option = manifest.pages[browser].depends_on.as_deref().unwrap();
            assert!(manifest.pages[extras.pages[1]].options.iter().any(|offered| offered.name == option));
        });
        // Every page still shows exactly once, in one place.
        act(&mut cx, &model, |m, _| {
            let mut pages: Vec<usize> =
                m.option_screens().into_iter().flat_map(|screen| screen.pages).collect();
            pages.sort();
            assert_eq!(pages, (0..m.manifest().pages.len()).collect::<Vec<_>>());
        });
    });
}
