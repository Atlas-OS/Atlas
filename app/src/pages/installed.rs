//! The "Atlas is installed" page: opened by the completion Run entry after the
//! install's restart, or by the Atlas package's new-user script for accounts set
//! up later, so whoever left the PC to install comes back to a completion screen
//! rather than a toast. When the install left the PC with less protection, it
//! says so before it says "you're all set".

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::home::{defender_not_restored_bar, protection_reminder_bar};
use super::{
    card_body, card_header, detail_row, detail_text, focusable_heading, on_model, options_value,
    recorded_options,
};
use crate::i18n::{describe, fmt};
use crate::model::{AppModel, ScreenKind};
use crate::services::playbook::Manifest;
use crate::services::system::links;
use crate::services::update_access::BlockerKind;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CompletionBackdrop, FocusHandles, Icon, InfoBar, KeepOut, ScrollbarState, Severity, Typography,
    a11y_text, card, icon_sized, scrollbar,
};

pub struct InstalledPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    focused_once: bool,
}

impl InstalledPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            focused_once: false,
        }
    }
}

impl Render for InstalledPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let heading_focus = self.focus.get("installed-heading", cx);
        if !self.focused_once {
            self.focused_once = true;
            window.focus(&heading_focus, cx);
        }
        let state = self.model.read(cx);
        let installed = state.installed();
        let version = state.installed_version().map(str::to_owned);
        let title = match &version {
            Some(version) => t!("installed-title-version", version = version),
            None => t!("installed-title"),
        };
        // As this PC has them, which the install recorded, and what it shows since.
        let installed_options = state.installed_options();
        let options = installed.map(|_| recorded_options(state, &installed_options)).unwrap_or_default();
        let mode = installed.map(|i| i.install_mode().label());
        let when = installed.and_then(|i| i.installed_at_local()).map(|when| fmt::long_date(&when));
        let system_text = describe::system_description(&state.system);
        // Protection the install reduced comes before "you're all set", and
        // turning it back on is the page's one accent while it shows. A
        // missing Defender has no such action, so Done stays the accent.
        let reminder = protection_reminder_bar(&model, state, "installed", true, &heading_focus);
        let reminding = state.protection_reminder().is_some_and(|reminder| !reminder.missing);
        let not_restored = defender_not_restored_bar(&model, state, "installed", &heading_focus);
        let defender_removed = defender_removed_shown(state).then(|| {
            InfoBar::new(
                Severity::Warning,
                t!("installed-defender-removed-title"),
                t!("installed-defender-removed-message"),
            )
            .id("installed-defender-removed")
        });
        // The user's own choice turned Windows Update off or paused it again
        // after Atlas had it on for the update; say what that means.
        let update_choice = state.update_choice_after_install().and_then(|kinds| {
            if kinds.contains(&BlockerKind::Off) {
                Some(t!("installed-update-off-again"))
            } else if kinds.contains(&BlockerKind::Paused) {
                Some(t!("installed-update-paused-again"))
            } else {
                None
            }
        });
        let update_choice = update_choice
            .map(|message| InfoBar::new(Severity::Informational, message, "").id("installed-update-choice"));
        // What the install recorded where it couldn't do what was asked, such
        // as VBS a policy controls: the log says why, so its button opens it.
        let differs = state
            .choices_not_applied()
            .map(|options| choices_not_applied(state.manifest(), options))
            .unwrap_or_default();
        let not_applied = (!differs.is_empty()).then(|| {
            let choices: Vec<String> = differs.iter().map(|kind| kind.title()).collect();
            InfoBar::new(
                Severity::Warning,
                t!("choices-not-applied-title"),
                t!("choices-not-applied-message", choices = describe::join_and(&choices)),
            )
            .id("installed-choices-not-applied")
            .action(
                Button::new("installed-open-log", t!("common-open-log-file"))
                    .icon(Icon::Folder)
                    .on_click(on_model(&model, |m, cx| m.reveal_install_log(cx))),
            )
        });
        // "You're all set" only where a reading confirms it: an install that
        // kept Defender needs Defender there with every switch on. Dismissing
        // a reminder hides the bar, not what Windows Security reports, and
        // dismissing that Defender is still removed doesn't bring it back.
        let all_set = reminder.is_none()
            && defender_removed.is_none()
            && !state.defender_not_restored()
            && not_applied.is_none()
            && !state.protection_reading_pending()
            && (!state.kept_defender_recorded() || state.protection_confirmed_on());

        let details: Option<AnyElement> = installed.map(|_| {
            card(cx)
                .w_full()
                .child(card_header(cx, "your-install", t!("home-your-install"), None))
                .child(
                    card_body()
                        .when_some(mode, |this, mode| {
                            this.child(detail_row(
                                cx,
                                "mode",
                                t!("common-installed-as"),
                                detail_text("mode", mode),
                            ))
                        })
                        .when_some(when, |this, when| {
                            this.child(detail_row(
                                cx,
                                "installed",
                                t!("common-installed"),
                                detail_text("installed", when),
                            ))
                        })
                        .child(detail_row(
                            cx,
                            "windows",
                            t!("common-windows"),
                            detail_text("windows", system_text),
                        ))
                        .child(detail_row(
                            cx,
                            "options",
                            t!("common-options"),
                            options_value(cx, "options", "installed-options", options),
                        )),
                )
                .into_any_element()
        });

        let keep_out = KeepOut::default();
        let column = div()
            .flex()
            .flex_col()
            .items_center()
            .w_full()
            .max_w(px(560.))
            .gap(px(16.))
            .flex_shrink_0()
            .my_auto()
            .child(
                div()
                    .relative()
                    .w(px(72.))
                    .h(px(72.))
                    .child(
                        svg()
                            .path("brand/atlas-mark.svg")
                            .absolute()
                            .bottom(px(0.))
                            .size(px(72.))
                            .text_color(theme.brand),
                    )
                    .child(
                        div()
                            .absolute()
                            .right(px(-4.))
                            .bottom(px(-4.))
                            .size(px(24.))
                            .rounded_full()
                            .bg(theme.success)
                            .flex()
                            .items_center()
                            .justify_center()
                            .child(icon_sized(Icon::CheckMark, 14.).text_color(theme.text_on_accent)),
                    ),
            )
            .child(
                // The text block the artwork keeps clear of; it reports its bounds each frame.
                div()
                    .flex()
                    .flex_col()
                    .items_center()
                    .gap(px(16.))
                    .w_full()
                    .on_children_prepainted(keep_out.record(0))
                    .child(
                        focusable_heading("installed-heading", 1, title, &heading_focus, cx)
                            .m(px(-1.))
                            .text_center(),
                    )
                    .when(all_set, |this| {
                        this.child(
                            div()
                                .type_body_large()
                                .text_color(theme.text_secondary)
                                .text_center()
                                .child(a11y_text("installed-line", t!("installed-ready"))),
                        )
                    })
                    .children(not_restored)
                    .children(defender_removed)
                    .children(reminder)
                    .children(not_applied)
                    .children(update_choice)
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .items_center()
                            .gap(px(8.))
                            .pt(px(8.))
                            .child(
                                Button::new("installed-done", t!("common-done"))
                                    .when(!reminding, Button::accent)
                                    .on_click(|_, window, _| window.remove_window()),
                            )
                            .child(
                                Button::new("installed-docs", t!("common-read-the-docs"))
                                    .hyperlink()
                                    .trailing_icon(Icon::OpenInNewWindow)
                                    .opens(links::DOCS),
                            ),
                    ),
            )
            .when_some(details, |this, details| {
                this.child(
                    div().w_full().pt(px(16.)).on_children_prepainted(keep_out.record(1)).child(details),
                )
            });

        div()
            .relative()
            .size_full()
            .overflow_hidden()
            .child(CompletionBackdrop::new(keep_out))
            .child(
                div()
                    .id("installed-scroll")
                    .size_full()
                    .overflow_y_scroll()
                    .track_scroll(&self.scroll)
                    .flex()
                    .flex_col()
                    .items_center()
                    .px(px(40.))
                    .py(px(40.))
                    .child(column),
            )
            .child(scrollbar(&self.scroll, &self.scrollbar))
    }
}

/// Whether the window says Microsoft Defender was removed: the install
/// removed it, as this PC shows its choices. A record that kept Defender
/// while Atlas's package still removes it has a bar of its own, which says
/// how to bring Defender back.
fn defender_removed_shown(state: &AppModel) -> bool {
    state.installed().is_some()
        && state.installed_options().iter().any(|option| option == "defender-disable")
        && !state.defender_not_restored()
}

/// The pages of `manifest` with an option among `not_applied`, the options
/// of each choice the install tried to apply and didn't get, by kind, in page
/// order (see [`AppModel::choices_not_applied`]): the completion records what
/// the PC has, and says in its log why that isn't what was asked.
fn choices_not_applied(manifest: &Manifest, not_applied: &[String]) -> Vec<ScreenKind> {
    let mut kinds = Vec::new();
    for page in &manifest.pages {
        let kind = ScreenKind::of_page(page);
        if page.options.iter().any(|option| not_applied.contains(&option.name)) && !kinds.contains(&kind) {
            kinds.push(kind);
        }
    }
    kinds
}

#[cfg(test)]
mod tests {
    use super::*;

    fn names(options: &[&str]) -> Vec<String> {
        options.iter().map(|option| (*option).to_owned()).collect()
    }

    /// Defender removed is said as this PC shows it, whatever the record
    /// says, except where the record kept it: that has its own bar.
    #[test]
    fn defender_removed_follows_the_pc_but_leaves_a_kept_record_to_its_own_bar() {
        use crate::model::test_harness::run_model_test;
        use crate::pages::testing::{NO_DEFENDER, NO_TELEMETRY, installed_model, recorded};
        use crate::services::legacy_choices::Facts;
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("installed-defender");
            let removed =
                Facts { packages: vec![NO_DEFENDER.into(), NO_TELEMETRY.into()], ..Facts::default() };
            let model = installed_model(&mut cx, &temp, Some(&["defender-disable"]), removed.clone());
            model.update(&mut cx, |m, _| {
                assert!(defender_removed_shown(m));
                m.atlas = Ok(Some(recorded("0.6.0", &["defender-enable"])));
                assert!(
                    m.defender_not_restored() && !defender_removed_shown(m),
                    "the not-restored bar says it"
                );
                // Removed by the record, but the PC shows Defender kept.
                m.atlas = Ok(Some(recorded("0.6.0", &["defender-disable"])));
                m.pc_facts =
                    Facts { packages: vec![NO_TELEMETRY.into()], defender: Some(true), ..Facts::default() };
                assert!(!defender_removed_shown(m));
                m.atlas = Ok(None);
                m.pc_facts = removed;
                assert!(!defender_removed_shown(m), "no recorded install");
            });
        });
    }

    /// The notice names each choice the install tried and didn't get, as its
    /// page is titled, and nothing when it got them all.
    #[test]
    fn the_notice_names_the_choices_the_install_tried_and_did_not_get() {
        let manifest = Manifest::builtin();
        assert_eq!(choices_not_applied(&manifest, &[]), []);
        // A policy kept VBS on, and Defender couldn't be removed.
        let not_applied = names(&["defender-disable", "defender-enable", "disable-core-isolation"]);
        assert_eq!(choices_not_applied(&manifest, &not_applied), [ScreenKind::Defender, ScreenKind::Power]);
        // Options the package doesn't offer don't count.
        assert_eq!(choices_not_applied(&manifest, &names(&["retired-option"])), []);
        // A browser the install didn't put on names both its pages.
        let browser = names(&["browser-brave", "install-another-browser"]);
        assert_eq!(choices_not_applied(&manifest, &browser), [ScreenKind::Apps, ScreenKind::Browser]);
    }

    /// Only the install's own record of what it couldn't apply counts: a
    /// record that differs from the request where the install had nothing to
    /// do, such as VBS already off on a first install that left its box
    /// clear, says nothing, and neither does one that couldn't read the PC.
    #[test]
    fn the_notice_follows_what_the_install_recorded_it_tried() {
        use crate::model::test_harness::run_model_test;
        use crate::pages::testing::{NO_TELEMETRY, installed_model};
        use crate::services::atlas_state::AtlasState;
        use crate::services::installer::InstallRequest;
        use crate::services::legacy_choices::Facts;
        use crate::services::session::SessionRecord;
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("installed-not-applied");
            let pc = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
            let recorded = ["defender-enable", "disable-core-isolation", "uninstall-edge"];
            let model = installed_model(&mut cx, &temp, Some(&recorded), pc);
            model.update(&mut cx, |m, _| {
                let record = |not_applied: serde_json::Value| -> AtlasState {
                    serde_json::from_value(serde_json::json!({
                        "schemaVersion": 1, "installedVersion": "0.6.0", "installedAt": "2026-11-01T12:00:00+00:00",
                        "mode": "Fresh", "options": recorded,
                        "history": [{ "version": "0.6.0", "mode": "Fresh", "completedAt": "2026-11-01T12:00:00+00:00",
                            "notApplied": not_applied }],
                    }))
                    .unwrap()
                };
                let log = temp.path().join("install.log");
                m.finished_session = Some(SessionRecord {
                    id: "test".into(),
                    pid: 0,
                    process_start: 0,
                    started_at: "2026-11-01T11:00:00Z".into(),
                    exit_path: log.with_extension("exit"),
                    log_path: log,
                    request: InstallRequest {
                        playbook_dir: temp.path().to_path_buf(),
                        options: names(&["defender-enable"]),
                        restart: true,
                        windows_security_confirmed: false,
                        choose_again: false,
                    },
                });
                // VBS was off and Edge gone before this first install.
                m.atlas = Ok(Some(record(serde_json::json!([]))));
                let notice = |m: &AppModel| {
                    m.choices_not_applied().map(|options| choices_not_applied(m.manifest(), options))
                };
                assert_eq!(notice(m), Some(Vec::new()));
                m.atlas = Ok(Some(record(serde_json::Value::Null)));
                assert_eq!(notice(m), None, "a completion that couldn't read the PC");
                m.atlas = Ok(Some(record(serde_json::json!(["disable-core-isolation"]))));
                assert_eq!(notice(m), Some(vec![ScreenKind::Power]));
                m.finished_session = None;
                assert_eq!(notice(m), None, "not an install this window followed");
            });
        });
    }
}
