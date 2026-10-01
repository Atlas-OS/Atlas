//! Step 3, Windows Security: the Defender switches an install needs off, as a
//! checklist with one message about what is left to do.

use gpui::{AnyElement, App, IntoElement, ParentElement, Role, Styled, div, prelude::*, px};

use super::{InstallPage, elevation_problem};
use crate::i18n::describe;
use crate::model::AppModel;
use crate::pages::{on_model, step_card_header};
use crate::services::security::{Protection, SecurityStatus, Switch};
use crate::services::system::links;
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
        let open_security = || {
            Button::new("open-security", t!("common-open-windows-security"))
                .icon(Icon::Shield)
                .opens(links::WINDOWS_SECURITY_PROTECTION)
        };

        let kind = security_banner(&status, fresh);
        let confirm = confirm_placement(kind, &status, fresh, state.elevated);
        let banner = match kind {
            SecurityBanner::Reading => InfoBar::new(
                Severity::Informational,
                t!("security-banner-reading-title"),
                t!("security-banner-reading-message"),
            ),
            // Informational, not a success: no antivirus isn't the step done well.
            SecurityBanner::Absent => InfoBar::new(
                Severity::Informational,
                t!("security-banner-absent-title"),
                t!("security-banner-absent-message"),
            ),
            SecurityBanner::AllOff => InfoBar::new(
                Severity::Success,
                t!("security-banner-off-title"),
                t!("security-banner-off-message"),
            ),
            // Every switch Atlas could read is off: the rest are confirmed by
            // hand, in the same bar that asks for it.
            SecurityBanner::ReadableOff => unreadable_bar(state, &model, Some(open_security()))
                .unwrap_or_else(|| {
                    InfoBar::new(
                        Severity::Warning,
                        t!("security-banner-on-title"),
                        t!("security-banner-on-message"),
                    )
                }),
            // Nothing could be read and Atlas can't read it as it is: relaunching
            // is the one thing that helps, so that bar is the message.
            SecurityBanner::TurnOff if confirm == Confirm::Relaunch => {
                unreadable_bar(state, &model, None).expect("switches that couldn't be read")
            }
            SecurityBanner::TurnOff => InfoBar::new(
                Severity::Warning,
                t!("security-banner-on-title"),
                t!("security-banner-on-message"),
            )
            .action(open_security().accent())
            // Nothing could be read: after the instructions, the confirmation,
            // in the same bar, under Open Windows Security.
            .when(confirm == Confirm::InBanner, |bar| bar.content(acknowledge_box(state, &model))),
        }
        .id("security-banner");

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
                                .rounded(px(6.))
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

        let (light, summary) = if !fresh {
            (LightState::Pending, t!("security-switch-reading"))
        } else if status.all_off() {
            (LightState::Good, t!("security-all-off"))
        } else if counts.on > 0 {
            (LightState::Caution, describe::security_summary(&counts))
        } else {
            (LightState::Unknown, describe::security_summary(&counts))
        };
        // Announced as it changes while the user is in Windows Security,
        // with what it counts.
        let header_status = StatusLight::new(light, summary.clone())
            .id("security-summary")
            .aria_label(t!("check-a11y", title = t!("security-list-title"), state = summary))
            .live();

        let mut cards = vec![banner.into_any_element()];
        cards.extend(elevation_problem(state, &model));
        // A switch is still on and others couldn't be read: the relaunch
        // that lets Atlas read them, above the list rather than under it.
        if confirm == Confirm::RelaunchBelowBanner
            && let Some(bar) = unreadable_bar(state, &model, None)
        {
            cards.push(bar.id("security-unknown").into_any_element());
        }
        // Without Defender there are no switches to list or to confirm.
        if kind == SecurityBanner::Absent {
            return cards;
        }
        cards.push(
            card(cx)
                .child(step_card_header(
                    cx,
                    "security",
                    t!("security-list-title"),
                    Some(header_status.into_any_element()),
                ))
                .child(list)
                .into_any_element(),
        );
        cards
    }
}

/// The confirmation of switches Atlas couldn't read, which unblocks the
/// step once every readable switch is off. It lines up with the bar's text
/// and buttons.
fn acknowledge_box(state: &AppModel, model: &gpui::Entity<AppModel>) -> CheckBox {
    let confirmed = state.security_acknowledged();
    CheckBox::new("security-acknowledge", t!("security-acknowledge"), confirmed)
        .flush_start()
        .disabled(!state.security.off_where_readable() || !state.flow.may_edit())
        .on_toggle(on_model(model, move |m, cx| m.acknowledge_security(!confirmed, cx)))
}

/// Where the step offers what unblocks switches Atlas couldn't read, beside
/// the one bar at the top, so it's never below the list.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Confirm {
    /// Nothing to offer: every switch was read, or one is on and Atlas can
    /// read the rest once it's off.
    None,
    /// No switch could be read: the confirmation goes in the instructions' bar.
    InBanner,
    /// No switch could be read without permission: the relaunch bar is the
    /// message.
    Relaunch,
    /// A switch is on and others need permission to read: the relaunch bar
    /// follows the instructions.
    RelaunchBelowBanner,
}

fn confirm_placement(kind: SecurityBanner, status: &SecurityStatus, fresh: bool, elevated: bool) -> Confirm {
    let counts = status.counts();
    if kind != SecurityBanner::TurnOff || !fresh || counts.unknown == 0 {
        return Confirm::None;
    }
    match (counts.on == 0, elevated) {
        (true, true) => Confirm::InBanner,
        (true, false) => Confirm::Relaunch,
        (false, false) => Confirm::RelaunchBelowBanner,
        (false, true) => Confirm::None,
    }
}

/// The bar for switches Atlas couldn't read: the confirmation, with `open`
/// to check them, or, without administrator rights, the relaunch that lets
/// Atlas read them. `None` when every switch could be read.
fn unreadable_bar(state: &AppModel, model: &gpui::Entity<AppModel>, open: Option<Button>) -> Option<InfoBar> {
    let status = state.security;
    if status.counts().unknown == 0 {
        return None;
    }
    let may_edit = state.flow.may_edit();
    Some(if state.elevated {
        InfoBar::new(Severity::Warning, t!("security-unknown-title"), t!("security-unknown-message"))
            .when_some(open, InfoBar::action)
            .content(acknowledge_box(state, model))
    } else {
        InfoBar::new(
            Severity::Warning,
            t!("security-unknown-unelevated-title"),
            t!("security-unknown-unelevated-message"),
        )
        .action(
            Button::new("security-elevate", t!("common-restart-as-administrator"))
                .icon(Icon::Admin)
                .disabled(!may_edit || !state.may_relaunch_elevated())
                .on_click(on_model(model, |m, cx| m.relaunch_elevated(cx))),
        )
    })
}

/// Which banner the Windows Security step shows for a reading.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum SecurityBanner {
    /// The first reading has not arrived yet.
    Reading,
    /// The Defender service is gone (an earlier Atlas install removed it).
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
        SecurityBanner::Reading
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
        assert_eq!(security_banner(&all_off, false), SecurityBanner::Reading);
        assert_eq!(security_banner(&all_off, true), SecurityBanner::AllOff);
        assert_eq!(security_banner(&all_on, true), SecurityBanner::TurnOff);
        assert_eq!(security_banner(&partly_readable, true), SecurityBanner::ReadableOff);
        assert_eq!(security_banner(&one_on, true), SecurityBanner::TurnOff);
        // No switch could be read: the instructions to turn them off come
        // first, not a confirmation of switches nobody has turned off.
        assert_eq!(security_banner(&nothing_readable, true), SecurityBanner::TurnOff);
        // Defender removed by an earlier install: nothing to read, nothing to turn off.
        let removed = SecurityStatus { defender_present: false, ..nothing_readable };
        assert_eq!(security_banner(&removed, false), SecurityBanner::Reading);
        assert_eq!(security_banner(&removed, true), SecurityBanner::Absent);
        assert!(crate::model::security_verified(&removed, None, false));
    }

    /// Whatever unblocks unreadable switches is in the bar at the top, or
    /// right under it: never a second bar under the list.
    #[test]
    fn what_unblocks_unreadable_switches_is_offered_at_the_top() {
        let nothing_readable = status([Switch::Unknown; 4]);
        let turn_off = security_banner(&nothing_readable, true);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, true, true), Confirm::InBanner);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, true, false), Confirm::Relaunch);
        let one_on = status([Switch::On, Switch::Unknown, Switch::Unknown, Switch::Unknown]);
        let kind = security_banner(&one_on, true);
        assert_eq!(confirm_placement(kind, &one_on, true, false), Confirm::RelaunchBelowBanner);
        // Elevated, the switch is turned off first; then the readable-off bar confirms the rest.
        assert_eq!(confirm_placement(kind, &one_on, true, true), Confirm::None);
        // The readable-off bar has its own confirmation, and a stale reading offers nothing.
        let partly = status([Switch::Off, Switch::Off, Switch::Unknown, Switch::Unknown]);
        assert_eq!(confirm_placement(security_banner(&partly, true), &partly, true, true), Confirm::None);
        assert_eq!(confirm_placement(turn_off, &nothing_readable, false, true), Confirm::None);
    }
}
