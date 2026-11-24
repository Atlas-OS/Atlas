//! Step 3, Windows Security: the Defender switches an install needs off, as a
//! checklist with at most one bar about what is left to do. The step opens
//! Windows Security, moves on once every switch reads off, and is passed over
//! when there's nothing to turn off, by itself (see
//! `AppModel::advance_security`); this page only shows where it stands.

use gpui::{AnyElement, App, IntoElement, ParentElement, Role, Styled, div, prelude::*, px};

use super::{InstallPage, elevation_problem};
use crate::i18n::describe::{self, DefenderAbsence};
use crate::model::AppModel;
use crate::pages::{on_model, step_card_header};
use crate::services::security::{Protection, SecurityStatus, Switch};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CapCenteredText, CheckBox, Icon, InfoBar, LightState, Severity, StatusLight, TextMark,
    Typography, card, icon,
};

impl InstallPage {
    pub(super) fn security_cards(&self, cx: &App) -> Vec<AnyElement> {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let status = state.security;
        let counts = status.counts();
        let fresh = state.security_fresh();

        let kind = security_banner(&status, fresh);
        let confirm = confirm_placement(kind, &status, fresh, state.elevated);
        // One bar at most, the first that applies: a relaunch that didn't
        // happen, then what is left to do. While Atlas reads, and once every
        // switch reads off, the list says it all.
        let banner = match kind {
            SecurityBanner::Checking | SecurityBanner::AllOff => None,
            SecurityBanner::Absent => {
                let absence = state.defender_absence();
                let (title, message) = absence.banner();
                Some(InfoBar::new(absence_severity(absence), title, message))
            }
            // Every switch Atlas could read is off: the rest are confirmed by
            // hand, in the same bar that asks for it.
            SecurityBanner::ReadableOff => unreadable_bar(state, &model, Some(open_security(&model, state))),
            // Nothing could be read and Atlas can't read it as it is: relaunching
            // is the one thing that helps, so that bar is the message.
            SecurityBanner::TurnOff if confirm == Confirm::Relaunch => unreadable_bar(state, &model, None),
            SecurityBanner::TurnOff => Some(
                InfoBar::new(
                    Severity::Warning,
                    t!("security-turn-off-title"),
                    t!("security-turn-off-message"),
                )
                .action(open_security(&model, state))
                // Nothing could be read: after the instructions, the
                // confirmation, in the same bar, under Open Windows Security.
                .when(confirm == Confirm::InBanner, |bar| bar.content(acknowledge_box(state, &model))),
            ),
        }
        .map(|bar| bar.id("security-banner").into_any_element());

        let mut cards: Vec<AnyElement> =
            elevation_problem(state, &model, state.security_ok()).or(banner).into_iter().collect();
        // Without Defender there are no switches to list or to confirm.
        if kind == SecurityBanner::Absent {
            return cards;
        }

        let mut list = div()
            .id("security-list")
            .role(Role::List)
            .aria_label(t!("security-list-title"))
            .flex()
            .flex_col();
        for (index, protection) in Protection::ALL.iter().enumerate() {
            let switch = if fresh { status.get(*protection) } else { Switch::Unknown };
            let label = match switch {
                Switch::Off => t!("security-switch-off"),
                Switch::On => t!("security-switch-on"),
                Switch::Unknown if fresh => t!("security-switch-unreadable"),
                Switch::Unknown => t!("security-switch-reading"),
            };
            // A switch turned off is this step's task done: a check mark
            // rather than the status dot, so "Off" reads as the step done,
            // not as protection being off for the better.
            let reading = match switch {
                Switch::Off => {
                    StatusLight::new(LightState::Good, label.clone()).check_mark().into_any_element()
                }
                Switch::On => StatusLight::new(LightState::Caution, label.clone()).into_any_element(),
                Switch::Unknown if fresh => {
                    StatusLight::new(LightState::Unknown, label.clone()).into_any_element()
                }
                Switch::Unknown => StatusLight::new(LightState::Pending, label.clone()).into_any_element(),
            };
            list = list.child(
                div()
                    .id(("security", index))
                    .role(Role::ListItem)
                    .aria_label(t!("security-a11y", title = protection.title(), state = label.as_str()))
                    .aria_description(protection.why())
                    .flex()
                    .items_center()
                    .gap(px(16.))
                    .px(px(16.))
                    .py(px(12.))
                    .when(index > 0, |this| this.border_t_1().border_color(theme.divider))
                    .child(
                        TextMark::new(
                            div()
                                .flex()
                                .items_center()
                                .justify_center()
                                .size(px(32.))
                                .rounded(px(4.))
                                // A contrast theme's subtle fill is its highlight colour.
                                .when(!theme.high_contrast, |this| this.bg(theme.subtle_hover))
                                .text_color(theme.text_secondary)
                                .child(icon(Icon::Shield)),
                            true,
                        )
                        .strong(),
                    )
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .flex_1()
                            .min_w_0()
                            .child(
                                div()
                                    .type_body_strong()
                                    .text_color(theme.text_primary)
                                    .child(CapCenteredText(protection.title().into())),
                            )
                            .child(
                                div().type_caption().text_color(theme.text_secondary).child(protection.why()),
                            ),
                    )
                    .child(TextMark::new(reading, true).strong()),
            );
        }

        // While Atlas reads, the rows' own marks are the only status.
        let header_status = fresh.then(|| {
            let (light, summary) = if status.all_off() {
                (LightState::Good, t!("security-all-off"))
            } else if counts.on > 0 {
                (LightState::Caution, describe::security_summary(&counts))
            } else {
                (LightState::Unknown, describe::security_summary(&counts))
            };
            // Announced as it changes while the user is in Windows Security,
            // with what it counts.
            StatusLight::new(light, summary.clone())
                .id("security-summary")
                .aria_label(t!("check-a11y", title = t!("security-list-title"), state = summary))
                .live()
                .into_any_element()
        });
        // The header keeps its strip while Atlas reads, so the list doesn't
        // move when the summary arrives in its trailing slot.
        let header_status = header_status.unwrap_or_else(|| div().into_any_element());
        cards.push(
            card(cx)
                .child(step_card_header(cx, "security", t!("security-list-title"), header_status))
                .child(list)
                .into_any_element(),
        );
        cards
    }
}

/// Open Windows Security, which shows the Virus & threat protection page
/// again first where an Atlas 0.5 policy hides it. The step opens it by
/// itself once per visit; the button opens it again, and it's the accent
/// until the step passes, when Continue is. A button, as the question
/// before closing offers it too.
fn open_security(model: &gpui::Entity<AppModel>, state: &AppModel) -> Button {
    let model = model.clone();
    Button::new("open-security", t!("common-open-windows-security"))
        .icon(Icon::Shield)
        .when(!state.security_ok(), Button::accent)
        .on_click(move |_, _, cx| model.update(cx, |m, cx| m.open_windows_security(cx)))
}

/// How the bar without Microsoft Defender reads: informational, not a
/// success, as no antivirus isn't the step done well. A Defender the user
/// keeps but Atlas can't bring back is a warning, though it doesn't stop the
/// step either.
fn absence_severity(absence: DefenderAbsence) -> Severity {
    if absence == DefenderAbsence::Missing { Severity::Warning } else { Severity::Informational }
}

/// The confirmation of switches Atlas couldn't read, which unblocks the
/// step once every readable switch is off. It names them, or all four when
/// none could be read, and lines up with the bar's text and buttons.
fn acknowledge_box(state: &AppModel, model: &gpui::Entity<AppModel>) -> CheckBox {
    let confirmed = state.security_acknowledged();
    let unreadable = state.security.switches(Switch::Unknown);
    let label = if unreadable.len() == Protection::ALL.len() {
        t!("security-acknowledge")
    } else {
        t!("security-unread-confirm", count = unreadable.len(), switches = switch_names(&unreadable))
    };
    CheckBox::new("security-acknowledge", label, confirmed)
        .disabled(!state.security.off_where_readable() || state.locked())
        .on_toggle(on_model(model, move |m, cx| m.acknowledge_security(!confirmed, cx)))
}

/// The switches' names as Windows Security shows them, joined as a list.
fn switch_names(switches: &[Protection]) -> String {
    let names: Vec<String> = switches.iter().map(|switch| switch.title()).collect();
    describe::join_and(&names)
}

/// Where the step offers what unblocks switches Atlas couldn't read: in the
/// one bar at the top, never below the list.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Confirm {
    /// Nothing to offer: every switch was read, or one is on, and Atlas
    /// asks about the rest once it's off.
    None,
    /// No switch could be read: the confirmation goes in the instructions' bar.
    InBanner,
    /// No switch could be read without permission: the relaunch bar is the
    /// message.
    Relaunch,
}

fn confirm_placement(kind: SecurityBanner, status: &SecurityStatus, fresh: bool, elevated: bool) -> Confirm {
    let counts = status.counts();
    if kind != SecurityBanner::TurnOff || !fresh || counts.unknown == 0 || counts.on > 0 {
        return Confirm::None;
    }
    if elevated { Confirm::InBanner } else { Confirm::Relaunch }
}

/// The bar for switches Atlas couldn't read: the confirmation, naming only
/// those switches, with `open` to check them, or, without administrator
/// rights, the relaunch that lets Atlas read them. `None` when every switch
/// could be read.
fn unreadable_bar(state: &AppModel, model: &gpui::Entity<AppModel>, open: Option<Button>) -> Option<InfoBar> {
    let unreadable = state.security.switches(Switch::Unknown);
    if unreadable.is_empty() {
        return None;
    }
    Some(if state.elevated {
        InfoBar::new(
            Severity::Warning,
            t!(
                "security-unread-switches-title",
                switches = switch_names(&unreadable),
                count = unreadable.len()
            ),
            t!("security-unread-message", count = unreadable.len()),
        )
        .when_some(open, InfoBar::action)
        .content(acknowledge_box(state, model))
    } else {
        InfoBar::new(
            Severity::Warning,
            t!("security-unknown-unelevated-title"),
            t!("security-unknown-unelevated-message"),
        )
        // The one way on: Continue waits for switches only an administrator can read.
        .action(
            Button::new("security-elevate", t!("common-restart-as-administrator"))
                .accent()
                .icon(Icon::Admin)
                .disabled(!state.may_relaunch_elevated())
                .on_click(on_model(model, |m, cx| m.relaunch_elevated(cx))),
        )
    })
}

/// Where the Windows Security step stands for a reading, which decides its
/// bar, if any.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum SecurityBanner {
    /// The first reading has not arrived yet.
    Checking,
    /// The Defender service isn't on this PC, so there are no switches; the
    /// model says why (see `AppModel::defender_absence`).
    Absent,
    /// All four switches read off.
    AllOff,
    /// At least one switch read off, none read on, and the rest could not be
    /// read: the user checks the rest by hand.
    ReadableOff,
    /// A switch is on, or nothing could be read at all: the general
    /// instruction to turn protection off applies.
    TurnOff,
}

fn security_banner(status: &SecurityStatus, fresh: bool) -> SecurityBanner {
    let counts = status.counts();
    if !fresh {
        SecurityBanner::Checking
    } else if !status.defender_present {
        SecurityBanner::Absent
    } else if status.all_off() {
        SecurityBanner::AllOff
    } else if counts.on == 0 && counts.off > 0 {
        SecurityBanner::ReadableOff
    } else {
        SecurityBanner::TurnOff
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn status(switches: [Switch; 4]) -> SecurityStatus {
        SecurityStatus {
            tamper_protection: switches[0],
            real_time_protection: switches[1],
            cloud_delivered: switches[2],
            sample_submission: switches[3],
            defender_present: true,
        }
    }

    #[test]
    fn the_security_banner_never_claims_a_check_that_did_not_happen() {
        let all_off = status([Switch::Off; 4]);
        let all_on = status([Switch::On; 4]);
        let nothing_readable = status([Switch::Unknown; 4]);
        let partly_readable = status([Switch::Off, Switch::Off, Switch::Unknown, Switch::Unknown]);
        let one_on = status([Switch::Off, Switch::On, Switch::Unknown, Switch::Off]);
        assert_eq!(security_banner(&all_off, false), SecurityBanner::Checking);
        assert_eq!(security_banner(&all_off, true), SecurityBanner::AllOff);
        assert_eq!(security_banner(&all_on, true), SecurityBanner::TurnOff);
        assert_eq!(security_banner(&partly_readable, true), SecurityBanner::ReadableOff);
        assert_eq!(security_banner(&one_on, true), SecurityBanner::TurnOff);
        // No switch could be read: the instructions to turn them off come
        // first, not a confirmation of switches nobody has turned off.
        assert_eq!(security_banner(&nothing_readable, true), SecurityBanner::TurnOff);
        // Defender not on the PC: nothing to read, nothing to turn off.
        let removed = SecurityStatus { defender_present: false, ..nothing_readable };
        assert_eq!(security_banner(&removed, false), SecurityBanner::Checking);
        assert_eq!(security_banner(&removed, true), SecurityBanner::Absent);
    }

    /// Without Defender the bar says why from what was checked: Atlas's own
    /// package, and whether this installation keeps Defender and applies
    /// that. Only a Defender kept that Atlas can't bring back is a warning.
    #[test]
    fn the_bar_without_defender_says_why_from_what_was_checked() {
        use crate::model::UpdatePath;
        use crate::model::test_harness::run_model_test;
        use crate::pages::testing::{NO_DEFENDER, NO_TELEMETRY, installed_model, rebuilt};
        use crate::services::atlas_state::{InstallIdentity, InstallMode, Unfinished};
        use crate::services::legacy_choices::Facts;
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("defender-absence");
            let removed = Facts {
                packages: vec![NO_DEFENDER.into(), NO_TELEMETRY.into()],
                defender: Some(false),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), removed);
            model.update(&mut cx, |m, cx| {
                let keep = |m: &mut AppModel, keep: bool| {
                    let (on, off) = if keep {
                        ("defender-enable", "defender-disable")
                    } else {
                        ("defender-disable", "defender-enable")
                    };
                    m.options.remove(off);
                    m.options.insert(on.into());
                };
                // Keeping the choices keeps what the PC has: Defender removed.
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed);
                // Choosing again to keep it brings it back.
                m.update_path = UpdatePath::ChooseAgain;
                m.set_update_path(UpdatePath::Keep, cx);
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed, "the PC's answer, removed");
                keep(m, true);
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore);
                // A first install applies the choice too.
                m.install_identity = Ok(InstallIdentity::Fresh);
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore);
                keep(m, false);
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed);
                keep(m, true);

                // An unfinished install goes on as its record says it began:
                // a first install or a Rebase applies the choice it holds, and
                // so does an update that chose again.
                let resume = |held: Option<&[&str]>, choose_again, mode| {
                    let held = held.map(|options| options.iter().map(|o| (*o).to_owned()).collect());
                    Ok(InstallIdentity::Resume("0.6.0".into(), Unfinished { held, choose_again, mode }))
                };
                let kept =
                    ["defender-enable", "mitigations-default", "auto-updates-default", "keyboard-shortcuts"];
                for mode in [InstallMode::Fresh, InstallMode::Rebase] {
                    m.install_identity = resume(Some(&kept[..]), false, mode);
                    assert_eq!(m.defender_absence(), DefenderAbsence::Restore, "{mode:?}");
                }
                m.install_identity = resume(Some(&kept[..]), true, InstallMode::Reapply);
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore);
                // An update keeping the choices that a release candidate
                // captured with Defender kept, its record naming no way, so
                // keeping them: nothing in it brings Defender back.
                m.install_identity = resume(Some(&kept[..]), false, InstallMode::Upgrade);
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed, "as the front door warns");
                m.install_identity =
                    resume(Some(&["defender-disable", "mitigations-default"][..]), false, InstallMode::Fresh);
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed);
                // One that hasn't run a step is captured again: keeping the
                // choices takes Defender from the PC, choosing again applies it.
                m.install_identity = resume(None, false, InstallMode::Reapply);
                assert_eq!(m.defender_absence(), DefenderAbsence::Removed, "captured again, keeping");
                m.install_identity = resume(None, true, InstallMode::Reapply);
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore);
                // Putting Atlas back after Windows rebuilt itself applies the choices it kept.
                m.update_access = Some(rebuilt(&kept));
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore);
                m.install_identity = resume(None, false, InstallMode::Rebase);
                assert_eq!(m.defender_absence(), DefenderAbsence::Restore, "a Rebase captured again");
                m.update_access = None;
                m.install_identity = Ok(InstallIdentity::Fresh);
                keep(m, false);

                // No Atlas package removed it.
                m.pc_facts =
                    Facts { packages: vec![NO_TELEMETRY.into()], defender: Some(false), ..Facts::default() };
                assert_eq!(m.defender_absence(), DefenderAbsence::Absent);
                keep(m, true);
                assert_eq!(m.defender_absence(), DefenderAbsence::Missing);
            });
        });
        crate::i18n::testing::english(|| {
            let banners: Vec<(String, String)> = [
                DefenderAbsence::Restore,
                DefenderAbsence::Removed,
                DefenderAbsence::Missing,
                DefenderAbsence::Absent,
            ]
            .map(DefenderAbsence::banner)
            .to_vec();
            let severities = [
                DefenderAbsence::Restore,
                DefenderAbsence::Removed,
                DefenderAbsence::Missing,
                DefenderAbsence::Absent,
            ]
            .map(absence_severity);
            assert_eq!(
                severities,
                [
                    Severity::Informational,
                    Severity::Informational,
                    Severity::Warning,
                    Severity::Informational
                ]
            );
            let titles: std::collections::BTreeSet<&String> =
                banners.iter().map(|(title, _)| title).collect();
            assert_eq!(titles.len(), 4, "each says why in its own words: {banners:?}");
            // Only where Atlas's package removed it does the bar say Atlas did.
            for (title, message) in &banners[2..] {
                assert!(!title.contains("Atlas removed") && !message.contains("Atlas removed"), "{title}");
            }
            assert!(banners[1].0.contains("Atlas removed"));
        });
    }

    /// Whatever unblocks unreadable switches is in the one bar at the top:
    /// never a second bar, and never under the list.
    #[test]
    fn what_unblocks_unreadable_switches_is_offered_at_the_top() {
        let nothing_readable = status([Switch::Unknown; 4]);
        let turn_off = security_banner(&nothing_readable, true);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, true, true), Confirm::InBanner);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, true, false), Confirm::Relaunch);
        // A switch is on: it's turned off first, and then the readable-off
        // bar confirms the rest, or relaunches to read them.
        let one_on = status([Switch::On, Switch::Unknown, Switch::Unknown, Switch::Unknown]);
        let kind = security_banner(&one_on, true);
        assert_eq!(confirm_placement(kind, &one_on, true, false), Confirm::None);
        assert_eq!(confirm_placement(kind, &one_on, true, true), Confirm::None);
        // The readable-off bar has its own confirmation, and a stale reading offers nothing.
        let partly = status([Switch::Off, Switch::Off, Switch::Unknown, Switch::Unknown]);
        assert_eq!(confirm_placement(security_banner(&partly, true), &partly, true, true), Confirm::None);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, false, true), Confirm::None);
    }

    /// The readable-off confirmation names only the switches Atlas couldn't
    /// read, as Windows Security names them; with none read, all four.
    #[test]
    fn the_confirmation_names_only_the_switches_atlas_could_not_read() {
        crate::i18n::testing::english(|| {
            let partly = status([Switch::Off, Switch::Off, Switch::Off, Switch::Unknown]);
            let unreadable = partly.switches(Switch::Unknown);
            let label =
                t!("security-unread-confirm", count = unreadable.len(), switches = switch_names(&unreadable));
            assert!(label.contains("Automatic sample submission"), "{label}");
            for named in
                [Protection::TamperProtection, Protection::RealTimeProtection, Protection::CloudDelivered]
            {
                assert!(!label.contains(&named.title()), "{label}");
            }
            let title = t!(
                "security-unread-switches-title",
                switches = switch_names(&unreadable),
                count = unreadable.len()
            );
            assert!(title.contains("Automatic sample submission") && !title.contains("Tamper"), "{title}");
        });
    }
}
