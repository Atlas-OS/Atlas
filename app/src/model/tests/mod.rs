//! Orchestration tests: the real model, driven through its actions inside a
//! headless GPUI application (no window, no text system), with the machine
//! behind controlled adapters. The installer child is real Windows PowerShell
//! running a harmless stub front door, so "the install started" means the
//! launch protocol ran end to end.

mod checks;
mod drafts;
mod elevation;
mod eligibility;
mod install;
mod navigation;
mod options;
mod package;
mod preferences;
mod preparation;
mod recovery;
mod restart;

use crate::model::test_harness::{act, fixture, new_model, read, run_model_test, wait_for};

#[test]
fn a_diagnostic_export_that_cannot_save_ends_with_its_error() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("diagnostics-blocked");
        // A file where the exports folder belongs fails before the collector runs.
        std::fs::write(env.paths.root.join("Diagnostics"), "not a folder").unwrap();
        let model = new_model(&mut cx, env);
        act(&mut cx, &model, |m, cx| m.export_diagnostics(cx));
        assert!(read(&cx, &model, |m| m.diagnostics_busy));
        wait_for(&cx, &model, "the export to end", |m| !m.diagnostics_busy).await;
        assert!(matches!(read(&cx, &model, |m| m.diagnostics_result.clone()), Some(Err(_))));
    });
}
