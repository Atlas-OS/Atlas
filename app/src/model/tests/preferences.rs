//! The preview-translation notice and switching to English, and the
//! Windows Security reminders on Home and the "Atlas is installed" window.

use crate::model::preferences::english_for;
use crate::model::test_harness::{
    act, all_off, fixture, new_model, read, run_model_test, settle, wait_for, wait_on_disk,
};
use crate::model::{Page, ReminderReason, Step};
use crate::services::atlas_state::AtlasState;
use crate::services::security::{Protection, SecurityStatus, Switch};
use crate::services::settings::{AppSettings, LanguagePreference, save_to};

/// A recorded install, finished at `installed_at`, with `options`.
fn recorded(installed_at: &str, options: &[&str]) -> AtlasState {
    serde_json::from_value(serde_json::json!({
        "schemaVersion": 1,
        "installedVersion": "0.6.0",
        "installedAt": installed_at,
        "mode": "Fresh",
        "options": options,
    }))
    .unwrap()
}

fn all_on() -> SecurityStatus {
    SecurityStatus {
        tamper_protection: Switch::On,
        real_time_protection: Switch::On,
        cloud_delivered: Switch::On,
        sample_submission: Switch::On,
        defender_present: true,
    }
}

/// After an install that kept Microsoft Defender, the reminder names only
/// the switches still off, follows the live reading, and once dismissed
/// stays dismissed for that install, and only that one.
#[test]
fn the_kept_defender_reminder_names_what_reads_off_until_dismissed_for_that_install() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-reminder");
        let first = "2026-09-30T20:06:21+00:00";
        *machine.state.lock().unwrap() = Some(recorded(first, &["defender-enable", "mitigations-default"]));
        machine.set_security(SecurityStatus { real_time_protection: Switch::On, ..all_off() });
        let model = new_model(&mut cx, env.clone());
        // Until Windows Security has been read, nothing says the PC is all set.
        assert!(read(&cx, &model, |m| m.protection_reading_pending()));
        wait_for(&cx, &model, "the reading", |m| m.protection_reminder().is_some()).await;
        assert!(!read(&cx, &model, |m| m.protection_reading_pending()));
        let reminder = read(&cx, &model, |m| m.protection_reminder().unwrap());
        assert_eq!(reminder.reason, ReminderReason::KeptDefender);
        assert!(!reminder.unreadable);
        assert_eq!(
            reminder.switches,
            [Protection::CloudDelivered, Protection::SampleSubmission, Protection::TamperProtection]
        );

        // Back from Windows Security with everything on: the reminder goes.
        machine.set_security(all_on());
        act(&mut cx, &model, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &model, "the new reading", |m| m.protection_reminder().is_none()).await;

        // A switch that can't be read is named without being called off.
        machine.set_security(SecurityStatus { tamper_protection: Switch::Unknown, ..all_on() });
        act(&mut cx, &model, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &model, "the unreadable reading", |m| m.protection_reminder().is_some()).await;
        let reminder = read(&cx, &model, |m| m.protection_reminder().unwrap());
        assert!(reminder.unreadable);
        assert_eq!(reminder.switches, [Protection::TamperProtection]);

        // Dismissed for this install, on disk too, so a relaunch keeps it dismissed.
        act(&mut cx, &model, |m, cx| m.dismiss_security_reminder(cx));
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        assert!(!read(&cx, &model, |m| m.protection_reading_pending()), "nothing left to wait for");
        wait_on_disk(&cx, &env, "the dismissal", |s| {
            s.protection_reminder_dismissed.as_deref() == Some(first)
        })
        .await;
        let relaunched = new_model(&mut cx, env.clone());
        settle(&cx, &relaunched).await;
        assert!(read(&cx, &relaunched, |m| m.protection_reminder().is_none()));

        // A later install that kept Defender has a reminder of its own.
        *machine.state.lock().unwrap() = Some(recorded("2026-10-01T09:00:00+00:00", &["defender-enable"]));
        let later = new_model(&mut cx, env.clone());
        wait_for(&cx, &later, "the later install's reminder", |m| m.protection_reminder().is_some()).await;
        settle(&cx, &later).await;

        // An install that removed Defender has no switch reminder.
        *machine.state.lock().unwrap() = Some(recorded("2026-10-01T10:00:00+00:00", &["defender-disable"]));
        machine.set_security(all_off());
        let removed = new_model(&mut cx, env);
        act(&mut cx, &removed, |m, cx| m.refresh_protection(cx));
        settle(&cx, &removed).await;
        assert!(read(&cx, &removed, |m| m.protection_reminder().is_none()));
    });
}

/// Leaving a flow with switches off reminds the user to turn them back on,
/// naming only those still off; a reading of none off ends it.
#[test]
fn leaving_a_flow_with_switches_off_names_the_ones_still_off() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-reminder-left");
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Security, cx));
        wait_for(&cx, &model, "a Windows Security reading", |m| m.security_fresh()).await;
        // Real-time protection came back on by itself meanwhile.
        machine.set_security(SecurityStatus { real_time_protection: Switch::On, ..all_off() });
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        assert_eq!(read(&cx, &model, |m| m.page), Page::Home);
        wait_for(&cx, &model, "the live reading", |m| {
            m.protection_reminder().is_some_and(|r| !r.switches.contains(&Protection::RealTimeProtection))
        })
        .await;
        let reminder = read(&cx, &model, |m| m.protection_reminder().unwrap());
        assert_eq!(reminder.reason, ReminderReason::LeftFlow);
        assert_eq!(reminder.switches.len(), 3);

        machine.set_security(all_on());
        act(&mut cx, &model, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &model, "every switch on", |m| m.protection_reminder().is_none()).await;
        settle(&cx, &model).await;
    });
}

/// Back on Home from a flow, the reminder names what the flow last read at
/// once, not what Home read before the flow began.
#[test]
fn leaving_a_flow_names_its_own_reading_not_an_older_one_from_home() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-reminder-older");
        *machine.state.lock().unwrap() = Some(recorded("2026-09-30T20:06:21+00:00", &["defender-enable"]));
        machine.set_security(all_on());
        let model = new_model(&mut cx, env);
        wait_for(&cx, &model, "Home's reading", |m| !m.protection_reading_pending()).await;
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;

        machine.set_security(all_off());
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Security, cx));
        wait_for(&cx, &model, "the flow's reading", |m| m.security_fresh()).await;
        act(&mut cx, &model, |m, cx| {
            m.cancel_flow(cx);
            // Before Home's new reading arrives.
            let reminder = m.protection_reminder().expect("the flow's reading names the switches");
            assert_eq!(reminder.reason, ReminderReason::LeftFlow);
            assert_eq!(reminder.switches.len(), 4);
        });
        settle(&cx, &model).await;
    });
}

/// An install that kept Microsoft Defender, read with Defender missing,
/// warns that there is no antivirus: once its restart is done, and never
/// for a flow left (nothing was turned off) or an install that removed it.
#[test]
fn a_kept_defender_that_is_missing_is_a_warning_once_the_restart_is_done() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-missing");
        let absent = SecurityStatus { defender_present: false, ..all_off() };
        *machine.state.lock().unwrap() = Some(recorded("2026-09-30T20:06:21+00:00", &["defender-enable"]));
        machine.set_security(absent);
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the reading", |m| m.protection_reminder().is_some()).await;
        let reminder = read(&cx, &model, |m| m.protection_reminder().unwrap());
        assert!(reminder.missing && reminder.switches.is_empty());
        assert!(!read(&cx, &model, |m| m.protection_confirmed_on()), "no Defender is not all set");

        // Before the restart, Defender may still be on its way back.
        act(&mut cx, &model, |m, _| m.owed_restart = Some(Default::default()));
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        act(&mut cx, &model, |m, _| m.owed_restart = None);

        // Dismissed for this install on Home, apart from the switches reminder.
        act(&mut cx, &model, |m, cx| m.dismiss_security_reminder(cx));
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        wait_on_disk(&cx, &env, "the dismissal", |s| s.defender_missing_dismissed.is_some()).await;
        assert!(read(&cx, &model, |m| m.settings.protection_reminder_dismissed.is_none()));

        // An install that removed Defender has its own bar, not this one.
        *machine.state.lock().unwrap() = Some(recorded("2026-10-01T10:00:00+00:00", &["defender-disable"]));
        let removed = new_model(&mut cx, env.clone());
        act(&mut cx, &removed, |m, cx| m.refresh_protection(cx));
        settle(&cx, &removed).await;
        assert!(read(&cx, &removed, |m| m.protection_reminder().is_none()));

        // Leaving a flow where Defender is gone: nothing to turn back on.
        let left = new_model(&mut cx, env);
        wait_for(&cx, &left, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &left, |m, _| {
            m.security_reminder = true;
            m.security = absent;
        });
        assert!(read(&cx, &left, |m| m.protection_reminder().is_none()));
        settle(&cx, &left).await;
    });
}

/// "You're all set" follows what Windows Security reports, not the bar: a
/// dismissed reminder with switches still off isn't all set, and the
/// "Atlas is installed" window shows a reminder dismissed before it opened.
#[test]
fn all_set_needs_every_switch_on_whatever_was_dismissed() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-all-set");
        *machine.state.lock().unwrap() = Some(recorded("2026-09-30T20:06:21+00:00", &["defender-enable"]));
        machine.set_security(SecurityStatus { real_time_protection: Switch::On, ..all_off() });
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "the reading", |m| m.protection_reminder().is_some()).await;
        act(&mut cx, &model, |m, cx| m.dismiss_security_reminder(cx));
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        assert!(!read(&cx, &model, |m| m.protection_confirmed_on()), "the switches are still off");
        assert!(read(&cx, &model, |m| m.kept_defender_recorded()));

        // The window after the restart reads again and shows the reminder.
        act(&mut cx, &model, |m, cx| m.navigate(Page::Installed, cx));
        wait_for(&cx, &model, "the Installed window's reminder", |m| m.protection_reminder().is_some()).await;
        // Dismissed there, it goes, and still isn't all set.
        act(&mut cx, &model, |m, cx| m.dismiss_security_reminder(cx));
        assert!(read(&cx, &model, |m| m.protection_reminder().is_none()));
        assert!(!read(&cx, &model, |m| m.protection_confirmed_on()));

        // Every switch on: all set.
        machine.set_security(all_on());
        act(&mut cx, &model, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &model, "every switch on", |m| m.protection_confirmed_on()).await;
        // An unreadable switch isn't on.
        machine.set_security(SecurityStatus { sample_submission: Switch::Unknown, ..all_on() });
        act(&mut cx, &model, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &model, "the unreadable switch", |m| !m.protection_confirmed_on()).await;
        settle(&cx, &model).await;
    });
}

/// Leaving a flow with switches off is remembered, so the reminder comes
/// back after a relaunch, once a live reading names what is still off.
#[test]
fn the_reminder_a_flow_left_survives_a_relaunch() {
    run_model_test(|mut cx| async move {
        let (_temp, machine, env) = fixture("protection-pending");
        let model = new_model(&mut cx, env.clone());
        wait_for(&cx, &model, "startup recovery", |m| !m.recovering).await;
        act(&mut cx, &model, |m, cx| m.start_flow_at(Step::Security, cx));
        wait_for(&cx, &model, "a Windows Security reading", |m| m.security_fresh()).await;
        act(&mut cx, &model, |m, cx| m.cancel_flow(cx));
        wait_on_disk(&cx, &env, "the pending reminder", |s| s.protection_reminder_pending).await;

        machine.set_security(SecurityStatus { tamper_protection: Switch::On, ..all_off() });
        let relaunched = new_model(&mut cx, env.clone());
        wait_for(&cx, &relaunched, "the live reading", |m| m.protection_reminder().is_some()).await;
        let reminder = read(&cx, &relaunched, |m| m.protection_reminder().unwrap());
        assert_eq!(reminder.reason, ReminderReason::LeftFlow);
        assert_eq!(reminder.switches.len(), 3, "named from the live reading");

        // Everything back on: the reminder goes, and so does the flag.
        machine.set_security(all_on());
        act(&mut cx, &relaunched, |m, cx| m.refresh_protection(cx));
        wait_for(&cx, &relaunched, "every switch on", |m| m.protection_reminder().is_none()).await;
        wait_on_disk(&cx, &env, "the flag cleared", |s| !s.protection_reminder_pending).await;
    });
}

#[test]
fn a_preview_translation_is_announced_until_dismissed_or_english_is_chosen() {
    run_model_test(|mut cx| async move {
        let (_temp, _, env) = fixture("preview-notice");
        save_to(
            &env.paths.settings(),
            &AppSettings { language: LanguagePreference::Explicit("de".into()), ..AppSettings::default() },
        )
        .unwrap();
        let model = new_model(&mut cx, env.clone());
        assert_eq!(read(&cx, &model, |m| m.preview_notice().map(|l| l.tag)), Some("de"));

        act(&mut cx, &model, |m, cx| m.dismiss_preview_notice(cx));
        assert!(read(&cx, &model, |m| m.preview_notice().is_none()), "dismissed for this language");
        wait_on_disk(&cx, &env, "the dismissal", |s| s.dismissed_preview_notices == vec!["de".to_owned()])
            .await;
        // Dismissing twice does not duplicate the entry.
        act(&mut cx, &model, |m, cx| m.dismiss_preview_notice(cx));
        assert_eq!(read(&cx, &model, |m| m.settings.dismissed_preview_notices.len()), 1);

        // A different preview language is announced again; choosing English ends it.
        act(&mut cx, &model, |m, cx| m.set_language(LanguagePreference::Explicit("ja".into()), cx));
        assert_eq!(read(&cx, &model, |m| m.preview_notice().map(|l| l.tag)), Some("ja"));
        act(&mut cx, &model, |m, cx| m.switch_to_english(cx));
        let language = read(&cx, &model, |m| m.settings.language.clone());
        assert!(
            matches!(&language, LanguagePreference::Explicit(tag) if tag.starts_with("en")),
            "{language:?}"
        );
        assert!(read(&cx, &model, |m| m.preview_notice().is_none()));
        wait_on_disk(&cx, &env, "the English choice", |s| s.language == language).await;
    });
}

#[test]
fn english_follows_the_windows_variant_when_there_is_one() {
    assert_eq!(english_for(&["en-US".into()]), "en-US");
    assert_eq!(english_for(&["de-DE".into(), "en-US".into()]), "en-US");
    assert_eq!(english_for(&["en-AU".into()]), "en-GB", "British spelling regions prefer en-GB");
    assert_eq!(english_for(&["de-DE".into()]), "en-GB", "no English in the list: the source");
    assert_eq!(english_for(&[]), "en-GB");
}
