//! Step 1, Get ready, in the order its tasks depend on each other: the
//! installation files, the checks of this PC, the drivers choice and the
//! Windows and Store updates.

use gpui::{AnyElement, App, Context, Hsla, IntoElement, ParentElement, Role, Styled, div, prelude::*, px};

use super::{InstallPage, details_toggle, elevation_problem};
use std::sync::atomic::Ordering;

use crate::i18n::fmt;
use crate::model::{Acquisition, AppModel, InstallBlock, Page, ReadyHelp, ReadyStatus, ReleaseCheck};
use crate::pages::{card_body, detail_text, drivers_radio, on_model, step_card_header};
use crate::services::atlas_state::InstallIdentity;
use crate::services::requirements::{CheckId, CheckResult, Verdict};
use crate::services::windows_release::TransitionNeed;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    BODY_LINE_HEIGHT, Button, CapCenteredText, CheckBox, Icon, InfoBar, LightState, ProgressBar,
    ProgressRing, RadioGroup, RadioItem, Severity, StatusLight, TextMark, Typography, a11y_text, card, icon,
    icon_in_line_sized,
};

impl InstallPage {
    pub(super) fn ready_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let drivers = self.drivers_card(cx);
        let windows = self.windows_card(cx);
        let preparation_focus = self.focus.get("preparation-status", cx);
        let action_focus = self.focus.get("prepare-action", cx);
        let model = self.model.clone();
        let state = self.model.read(cx);
        let help = state.ready_help();

        // The fresh-install note applies to a first install on Windows that
        // shows no prior use. Once the used-Windows warning applies, it takes
        // over; dismissing it must not bring another bar back in its place.
        let fresh_identity = matches!(state.install_identity, Ok(InstallIdentity::Fresh));
        let used_windows = fresh_identity && self.windows_installation.suggests_prior_use();
        let rebase = state.rebase_choices();
        let note = if state.original_options().is_some() {
            Some(
                InfoBar::new(
                    Severity::Informational,
                    t!("resume-choices-title"),
                    t!("resume-choices-detail"),
                )
                .id("ready-resume-note"),
            )
        } else if let Some(choices) = rebase {
            // After a move during which Windows reinstalled itself instead of
            // switching the new version on in place.
            Some(
                InfoBar::new(
                    Severity::Informational,
                    t!("ready-rebase-title"),
                    t!(
                        "ready-rebase-message",
                        release = state.system.display_version.as_str(),
                        version = state.manifest().version.as_str(),
                        previous = choices.previous.as_str()
                    ),
                )
                .id("ready-rebase-note"),
            )
        } else if fresh_identity && !used_windows && !self.staged_iso_setup {
            Some(
                InfoBar::new(Severity::Informational, t!("ready-fresh-title"), t!("ready-fresh-description"))
                    .id("ready-fresh-note"),
            )
        } else {
            None
        };
        // One informational bar at most above the first card: the status
        // when it asks for something or says what updating is doing,
        // otherwise a note, otherwise the status. After Atlas's own restart
        // the top says how updating stands, not to reinstall Windows.
        let status = state.ready_status();
        let status_first =
            status.is_some_and(|status| !matches!(status, ReadyStatus::Busy | ReadyStatus::Ready));
        let (status, note) = if status_first || note.is_none() { (status, None) } else { (None, note) };

        let mut cards = Vec::new();
        // Errors and the used-Windows warning always show.
        cards.extend(elevation_problem(state, &model));
        if used_windows && !self.used_windows_warning_dismissed {
            cards.push(self.used_windows_warning(state, cx));
        }
        if let Some(status) = status {
            cards.push(status_bar(status, state).into_any_element());
        }
        if let Some(block) = state.install_block() {
            let mut bar =
                InfoBar::new(Severity::Error, t!("install-source-title"), block.text(state.bundled()))
                    .id("ready-eligibility");
            // Reinstalling Windows is the way on, and an Atlas ISO is where it starts.
            if matches!(block, InstallBlock::Unsupported { .. }) && state.can_navigate(Page::Iso) {
                bar = bar.action(
                    Button::new("ready-eligibility-iso", t!("iso-open"))
                        .on_click(on_model(&model, |m, cx| m.navigate_iso_for_this_pc(cx))),
                );
            }
            cards.push(bar.into_any_element());
            if help == Some(ReadyHelp::Eligibility) {
                cards.push(self.diagnostics.panel(&self.model, cx).into_any_element());
            }
        }
        cards.extend(note.map(IntoElement::into_any_element));

        cards.push(self.package_card(cx));
        if help == Some(ReadyHelp::Package) {
            cards.push(self.diagnostics.panel(&self.model, cx).into_any_element());
        }
        cards.push(self.checks_card(cx));
        // Under the checks that stand in the way, which the user can often fix.
        if state.ready_status() == Some(ReadyStatus::Blocked) && help == Some(ReadyHelp::Checks) {
            cards.push(self.diagnostics.panel(&self.model, cx).into_any_element());
        }
        cards.push(drivers);
        cards.extend(windows);
        cards.push(self.preparation_card(
            help == Some(ReadyHelp::Preparation),
            preparation_focus,
            action_focus,
            cx,
        ));
        cards
    }

    /// Windows here looks used: the safe path, reinstalling from an Atlas
    /// ISO, comes first; going on anyway second, with neither as the default.
    fn used_windows_warning(&self, state: &AppModel, cx: &Context<Self>) -> AnyElement {
        let model = self.model.clone();
        let actions = div()
            .flex()
            .flex_wrap()
            .gap(px(8.))
            .when(state.can_navigate(Page::Iso), |this| {
                this.child(
                    Button::new("ready-used-windows-iso", t!("iso-open"))
                        .on_click(on_model(&model, |m, cx| m.navigate_iso_for_this_pc(cx))),
                )
            })
            .child(Button::new("ready-used-windows-dismiss", t!("ready-used-windows-dismiss")).on_click(
                // The bar and its button go away; focus goes back to the step heading.
                cx.listener(|this, _, window, cx| {
                    this.used_windows_warning_dismissed = true;
                    let heading = this.focus.get("step-heading", cx);
                    window.focus(&heading, cx);
                    cx.notify();
                }),
            ));
        InfoBar::new(Severity::Warning, t!("ready-used-windows-title"), t!("ready-used-windows-description"))
            .id("ready-used-windows-warning")
            .action(actions)
            .into_any_element()
    }

    /// PC checks. While they run, every row shows in the usual order; once
    /// they have all reported, what needs attention comes first and the
    /// passed checks fold into one line that can be opened.
    fn checks_card(&self, cx: &Context<Self>) -> AnyElement {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let rows = state.check_rows();
        let show_passed = self.show_passed_checks;
        let mut list = div().id("checks").role(Role::List).aria_label(t!("ready-this-pc")).flex().flex_col();
        let mut drawn = 0;
        for &index in &rows.listed {
            list = list.child(self.check_row(index, drawn > 0, cx));
            drawn += 1;
        }
        if !rows.passed.is_empty() {
            list = list.child(self.passed_checks_row(rows.passed.len(), drawn > 0, cx));
            drawn += 1;
            if show_passed {
                for &index in &rows.passed {
                    list = list.child(self.check_row(index, drawn > 0, cx));
                    drawn += 1;
                }
            }
        }
        card(cx)
            .child(step_card_header(
                cx,
                "checks",
                t!("ready-this-pc"),
                Some(
                    // Stays enabled while the checks run, so it keeps focus;
                    // choosing it again starts them over.
                    // Named with its card: the Windows card can show its own Check again.
                    Button::new("checks-rerun", t!("ready-check-again"))
                        .aria_label(t!(
                            "common-details-a11y",
                            action = t!("ready-check-again"),
                            section = t!("ready-this-pc")
                        ))
                        .compact()
                        .icon(Icon::Refresh)
                        .disabled(state.locked())
                        .on_click(on_model(&model, |m, cx| m.run_checks(cx)))
                        .into_any_element(),
                ),
            ))
            .child(list)
            .into_any_element()
    }

    /// The line that stands for every check that passed, with the control
    /// that shows them.
    fn passed_checks_row(&self, count: usize, divided: bool, cx: &Context<Self>) -> AnyElement {
        let theme = cx.theme();
        let shown = self.show_passed_checks;
        let label = t!("ready-checks-passed", count = count);
        div()
            .id("checks-passed")
            .role(Role::ListItem)
            .aria_label(label.clone())
            .flex()
            .items_center()
            .gap(px(16.))
            .px(px(16.))
            .py(px(12.))
            .when(divided, |this| this.border_t_1().border_color(theme.divider))
            .child(
                TextMark::new(
                    div()
                        .flex_shrink_0()
                        .size(px(20.))
                        .flex()
                        .items_center()
                        .justify_center()
                        .text_color(theme.success)
                        .child(icon(Icon::Completed)),
                    false,
                )
                .strong(),
            )
            .child(
                div()
                    .flex_1()
                    .min_w_0()
                    .type_body_strong()
                    .text_color(theme.text_primary)
                    .child(CapCenteredText(label.into())),
            )
            .child(details_toggle(
                "checks-passed-toggle",
                t!("ready-this-pc"),
                shown,
                |page| &mut page.show_passed_checks,
                cx,
            ))
            .into_any_element()
    }

    /// One check: its verdict as a glyph and words, what it found, and the
    /// fix or confirmation it offers.
    fn check_row(&self, index: usize, divided: bool, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let may_edit = !state.locked();
        let (id, result) = &state.checks[index];
        let id = *id;
        let handled = result.as_ref().is_some_and(|r| state.handled_by_preparation(r));
        let (glyph, colour, state_word): (AnyElement, Hsla, String) = match result.as_ref().map(|r| r.verdict)
        {
            None => (ProgressRing::new().into_any_element(), theme.accent, t!("check-state-checking")),
            Some(Verdict::Pass) => {
                (icon(Icon::Completed).into_any_element(), theme.success, t!("check-state-passed"))
            }
            // Update Windows and Store apps takes care of it: a note, not a failure.
            Some(_) if handled => {
                (icon(Icon::Info).into_any_element(), theme.text_secondary, t!("check-state-failed"))
            }
            Some(Verdict::Warn) => {
                (icon(Icon::Warning).into_any_element(), theme.caution, t!("check-state-warning"))
            }
            Some(Verdict::Fail) if id.blocking() => {
                (icon(Icon::ErrorBadge).into_any_element(), theme.critical, t!("check-state-failed-blocking"))
            }
            Some(Verdict::Fail) => {
                (icon(Icon::Warning).into_any_element(), theme.caution, t!("check-state-failed"))
            }
            Some(Verdict::Unknown) if id.blocking() => {
                (icon(Icon::Unknown).into_any_element(), theme.critical, t!("check-state-unknown"))
            }
            Some(Verdict::Unknown) => {
                (icon(Icon::Unknown).into_any_element(), theme.text_secondary, t!("check-state-unknown"))
            }
        };
        let detail =
            result.as_ref().map(|r| r.detail.text(&state.system)).unwrap_or_else(|| t!("common-checking"));
        let fix = match (result, id.fix_target(), id.fix_label()) {
            (Some(r), Some(target), Some(label)) if offers_fix(r) && !handled => Some(
                Button::new(("fix", index), label)
                    .compact()
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(target)
                    .into_any_element(),
            ),
            (Some(r), None, _) if id == CheckId::Administrator && r.verdict == Verdict::Fail => {
                let enabled = may_edit && state.may_relaunch_elevated();
                Some(
                    Button::new("fix-elevate", t!("common-restart-as-administrator"))
                        .compact()
                        .icon(Icon::Admin)
                        // The next task once there is a package: everything after it waits for it.
                        .when(enabled && state.playbook.is_some(), Button::accent)
                        .disabled(!enabled)
                        .on_click(on_model(&model, |m, cx| m.relaunch_elevated(cx)))
                        .into_any_element(),
                )
            }
            _ => None,
        };
        // Relaunching waits for the installation files; say so beside the button.
        let elevate_waits = id == CheckId::Administrator
            && result.as_ref().is_some_and(|r| r.verdict == Verdict::Fail)
            && state.acquisition.is_busy();
        let acknowledgement = result
            .as_ref()
            .and_then(|r| r.acknowledgement().map(|label| (r.id, label)))
            .map(|(check, label)| {
                let confirmed = state.acknowledged.contains(&check);
                CheckBox::new(("acknowledge", index), label, confirmed)
                    .disabled(!may_edit)
                    .on_toggle(on_model(&model, move |m, cx| m.acknowledge_check(check, !confirmed, cx)))
            });
        div()
            .id(("check", index))
            .role(Role::ListItem)
            .aria_label(t!("check-a11y", title = id.title(), state = state_word))
            .aria_description(detail.clone())
            .flex()
            .flex_col()
            .when(divided, |this| this.border_t_1().border_color(theme.divider))
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(16.))
                    .px(px(16.))
                    .py(px(12.))
                    .child(
                        TextMark::new(
                            div()
                                .flex_shrink_0()
                                .size(px(20.))
                                .flex()
                                .items_center()
                                .justify_center()
                                .text_color(colour)
                                .child(glyph),
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
                                    .child(CapCenteredText(id.title().into())),
                            )
                            .child(div().type_caption().text_color(theme.text_secondary).child(detail)),
                    )
                    .when_some(fix, |this, fix| this.child(fix)),
            )
            .when_some(acknowledgement, |this, acknowledgement| {
                this.child(div().px(px(44.)).pb(px(8.)).child(acknowledgement))
            })
            .when(elevate_waits, |this| {
                this.child(
                    div()
                        .px(px(44.))
                        .pb(px(8.))
                        .type_caption()
                        .text_color(theme.text_secondary)
                        .child(detail_text("fix-elevate-unavailable", t!("prepare-wait-for-package"))),
                )
            })
            .into_any_element()
    }

    fn drivers_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let (selected, disabled) = {
            let state = self.model.read(cx);
            (state.driver_preference(), state.locked() || state.preparation_choices_fixed())
        };
        let model = self.model.clone();
        let drivers = drivers_radio("prepare-drivers", selected, &mut self.focus, cx, move |drivers, cx| {
            model.update(cx, |m, cx| m.set_drivers(drivers, cx))
        });
        let theme = cx.theme();
        card(cx)
            .child(step_card_header(cx, "drivers", t!("prepare-drivers"), None))
            .child(
                card_body()
                    .child(
                        div().type_body().text_color(theme.text_secondary).pb(px(4.)).child(a11y_text(
                            "prepare-drivers-description",
                            t!("prepare-drivers-description"),
                        )),
                    )
                    .child(drivers.disabled(disabled)),
            )
            .into_any_element()
    }

    /// The Windows version Atlas moves this PC to before installing: what
    /// changes, the choice where moving is optional, and Microsoft's licence
    /// terms. It never takes the accent; the update card's button starts it.
    fn windows_card(&mut self, cx: &mut Context<Self>) -> Option<AnyElement> {
        let (transition, need, current, build, version, chosen, terms, locked, open) = {
            let state = self.model.read(cx);
            let (transition, need) = state.windows_transition()?;
            (
                transition,
                need,
                state.system.display_version.clone(),
                state.system.build,
                state.manifest().version.clone(),
                state.transition_chosen(),
                state.windows_terms_accepted,
                state.locked(),
                state.transition_open(),
            )
        };
        let terms_fixed = terms && self.model.read(cx).preparation_choices_fixed();
        let release = transition.target_release;
        let model = self.model.clone();
        let choice = (need == TransitionNeed::Optional).then(|| {
            let (move_key, keep_key) = ("windows-release-move", "windows-release-keep");
            let items = [
                RadioItem::new(
                    move_key,
                    t!("windows-choice-move", release = release),
                    self.focus.get(move_key, cx),
                )
                .description(t!("windows-choice-move-detail", date = fmt::day(transition.end_of_updates()))),
                RadioItem::new(
                    keep_key,
                    t!("windows-choice-keep", current = current.as_str()),
                    self.focus.get(keep_key, cx),
                )
                .description(t!("windows-choice-keep-detail")),
            ];
            let model = model.clone();
            RadioGroup::new("windows-release", t!("windows-card-question"))
                .items(items)
                .selected(Some(usize::from(!chosen)))
                .disabled(locked || open)
                .on_select(move |index, _, cx| {
                    model.update(cx, |m, cx| m.set_windows_transition(index == 1, cx))
                })
        });
        let theme = cx.theme();
        let mut body = card_body().gap(px(8.));
        body = match choice {
            None => body.child(div().type_body().text_color(theme.text_secondary).child(a11y_text(
                "windows-card-required",
                t!("windows-card-required", version = version.as_str(), release = release),
            ))),
            Some(group) => body
                .child(div().type_body().text_color(theme.text_secondary).child(t!("windows-card-question")))
                .child(group)
                .when(open, |this| {
                    this.child(div().type_caption().text_color(theme.text_secondary).child(detail_text(
                        "windows-card-locked",
                        t!("windows-card-locked", current = current.as_str()),
                    )))
                }),
        };
        if chosen {
            let mut facts = vec![
                t!("windows-fact-keep"),
                t!("windows-fact-restart"),
                t!("transition-offer-expectation"),
                t!("windows-fact-stays", release = release),
            ];
            // 25H2 removed both already; only a PC on 24H2 loses them now.
            if build == 26100 {
                facts.push(t!("windows-fact-removed", release = release));
            }
            let undo = if need == TransitionNeed::Required {
                t!("windows-card-undo", version = version.as_str(), current = current.as_str())
            } else {
                t!("windows-card-undo-optional")
            };
            let terms_box = CheckBox::new("windows-terms", t!("windows-terms", release = release), terms)
                .disabled(locked || terms_fixed)
                .on_toggle(on_model(&model, move |m, cx| m.accept_windows_terms(!terms, cx)));
            body = body
                .child(fact_list(&facts, cx))
                .child(
                    div()
                        .type_caption()
                        .text_color(theme.text_secondary)
                        .child(detail_text("windows-card-undo", undo)),
                )
                .child(
                    div().flex().flex_col().gap(px(2.)).pt(px(4.)).child(terms_box).child(
                        div().flex().child(
                            Button::new("windows-terms-link", t!("windows-terms-link"))
                                .hyperlink()
                                .compact()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(WINDOWS_TERMS),
                        ),
                    ),
                );
        }
        Some(
            card(cx)
                .child(step_card_header(
                    cx,
                    "windows-version",
                    t!("windows-card-title", release = release),
                    None,
                ))
                .child(body)
                .into_any_element(),
        )
    }

    fn package_card(&self, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let release = state.release.release().cloned();
        let bundled = state.bundled();

        let (line, light, light_label) = match (&state.acquisition, &state.playbook) {
            (Acquisition::Downloading { received, total }, _) => (
                t!(
                    "package-downloading",
                    version = release.as_ref().map(|r| r.version()).unwrap_or(""),
                    received = fmt::megabytes_value(*received),
                    total = fmt::megabytes_value(*total)
                ),
                LightState::Pending,
                t!("package-status-downloading"),
            ),
            (Acquisition::Extracting { done, total }, _) => (
                if *total > 0 {
                    t!("package-unpacking-progress", done = *done, total = *total)
                } else {
                    t!("package-unpacking")
                },
                LightState::Pending,
                t!("package-status-unpacking"),
            ),
            (Acquisition::Failed(problem), _) => {
                (problem.text(bundled), LightState::Bad, t!("package-status-failed"))
            }
            (Acquisition::Idle, Some(source)) => {
                (source.describe(), LightState::Good, t!("package-status-ready"))
            }
            // A tester build never checks for a release: before its bundled
            // package is unpacked it is preparing, not checking.
            (Acquisition::Idle, None) if bundled => {
                (t!("package-looking-bundled"), LightState::Pending, t!("package-status-preparing"))
            }
            (Acquisition::Idle, None) => match &state.release {
                ReleaseCheck::Checking | ReleaseCheck::NotChecked => {
                    (t!("package-looking"), LightState::Pending, t!("package-status-checking"))
                }
                ReleaseCheck::Failed => {
                    (t!("package-release-failed"), LightState::Caution, t!("package-status-missing"))
                }
                ReleaseCheck::Ready { .. } => {
                    (t!("package-none"), LightState::Caution, t!("package-status-missing"))
                }
            },
        };
        let progress = match &state.acquisition {
            Acquisition::Downloading { received, total } => {
                Some(Some(*received as f32 / (*total).max(1) as f32))
            }
            Acquisition::Extracting { done, total } if *total > 0 => Some(Some(*done as f32 / *total as f32)),
            Acquisition::Extracting { .. } => Some(None),
            _ => None,
        };
        let busy = state.acquisition.is_busy() || state.locked();
        let downloading = matches!(state.acquisition, Acquisition::Downloading { .. });
        // Getting the files is the first task: its button is the accent one
        // until there is a package.
        let first_task = state.playbook.is_none();
        let download_label = match (&release, &state.playbook) {
            (Some(r), Some(p)) if p.manifest.version == r.version() => t!("package-download-again"),
            (Some(r), _) => t!("package-download-version", version = r.version()),
            (None, _) => t!("package-download-newest"),
        };

        card(cx)
            .child(step_card_header(
                cx,
                "package",
                t!("package-title"),
                Some(
                    StatusLight::new(light, light_label.clone())
                        .id("package-status")
                        .aria_label(t!("check-a11y", title = t!("package-title"), state = light_label))
                        .live()
                        .into_any_element(),
                ),
            ))
            .child(
                card_body()
                    .child(
                        div()
                            .type_body()
                            .text_color(theme.text_primary)
                            .child(a11y_text("package-line", line)),
                    )
                    .when_some(progress, |this, value| {
                        this.child(ProgressBar::new("package-progress", t!("package-progress"), value))
                    })
                    .child(
                        div()
                            .flex()
                            .flex_wrap()
                            .gap(px(8.))
                            .pt(px(4.))
                            // A tester build offers its bundled package and nothing else.
                            .when(bundled && matches!(state.acquisition, Acquisition::Failed(_)), |this| {
                                this.child(
                                    Button::new("source-bundled", t!("common-try-again"))
                                        .accent()
                                        .icon(Icon::Sync)
                                        .disabled(busy)
                                        .on_click(on_model(&model, |m, cx| m.load_bundled_package(cx))),
                                )
                            })
                            .when(
                                !bundled && !state.latest_predates_app() && state.offers_download(),
                                |this| {
                                    let disabled = busy || matches!(state.release, ReleaseCheck::Checking);
                                    this.child(
                                        Button::new("source-download", download_label)
                                            .when(first_task && !disabled, Button::accent)
                                            .icon(Icon::Download)
                                            .disabled(disabled)
                                            .on_click(on_model(&model, |m, cx| m.download_latest(cx))),
                                    )
                                },
                            )
                            .when(!bundled && downloading, |this| {
                                this.child(
                                    Button::new("source-cancel", t!("package-cancel-download"))
                                        .on_click(on_model(&model, |m, cx| m.cancel_download(cx))),
                                )
                            })
                            .when(!bundled, |this| {
                                this.child(
                                    Button::new("source-local", t!("package-open-file"))
                                        .icon(Icon::Folder)
                                        // A running download gives way to a chosen file.
                                        .disabled(!state.may_choose_playbook())
                                        .on_click(on_model(&model, |m, cx| m.choose_local_playbook(cx))),
                                )
                            }),
                    ),
            )
            .into_any_element()
    }
}

/// Where Microsoft publishes the licence terms of the Windows version a
/// feature-update policy asks for, as the policy's own help names it.
const WINDOWS_TERMS: &str = "https://aka.ms/WindowsTargetVersioninfo";

/// What moving Windows keeps and changes, one line each, with a check mark.
fn fact_list(facts: &[String], cx: &App) -> AnyElement {
    let theme = cx.theme();
    div()
        .id("windows-facts")
        .role(Role::List)
        .aria_label(t!("windows-card-facts"))
        .flex()
        .flex_col()
        .gap(px(4.))
        .children(facts.iter().enumerate().map(|(index, fact)| {
            div()
                .id(("windows-fact", index))
                .role(Role::ListItem)
                .aria_label(fact.clone())
                .flex()
                .items_start()
                .gap(px(8.))
                .child(
                    icon_in_line_sized(Icon::CheckMark, 12., BODY_LINE_HEIGHT)
                        .flex_shrink_0()
                        .text_color(theme.success),
                )
                .child(
                    div().flex_1().min_w_0().type_body().text_color(theme.text_primary).child(fact.clone()),
                )
        }))
        .into_any_element()
}

/// Whether a check's row offers its Settings page: whenever the check didn't
/// pass, except for an antivirus app that is already gone, which nothing in
/// Settings can remove.
fn offers_fix(result: &CheckResult) -> bool {
    match result.verdict {
        Verdict::Pass => false,
        Verdict::Warn => result.id != CheckId::ThirdPartyAntivirus,
        Verdict::Fail | Verdict::Unknown => true,
    }
}

/// Get ready's status bar for `status`. The update states name the update
/// card and the button that comes next on it, in words only: the button
/// stays in the card, beside what explains it.
fn status_bar(status: ReadyStatus, state: &AppModel) -> InfoBar {
    use crate::services::preparation::State as Preparation;
    let bundled = state.bundled();
    let (severity, title, message) = match status {
        ReadyStatus::Busy => {
            (Severity::Informational, t!("ready-banner-busy-title"), t!("ready-banner-busy-message"))
        }
        ReadyStatus::Blocked => {
            (Severity::Error, t!("ready-banner-blocked-title"), t!("ready-banner-blocked-message"))
        }
        ReadyStatus::NoPackage if bundled => (
            Severity::Warning,
            t!("ready-banner-no-package-bundled-title"),
            t!("ready-banner-no-package-bundled-message"),
        ),
        ReadyStatus::NoPackage => {
            (Severity::Warning, t!("ready-banner-no-package-title"), t!("ready-banner-no-package-message"))
        }
        ReadyStatus::Updates => {
            (Severity::Informational, t!("ready-banner-updates-title"), t!("ready-banner-updates-message"))
        }
        ReadyStatus::WindowsTerms => {
            let release = state.windows_transition().map_or("", |(transition, _)| transition.target_release);
            (
                Severity::Informational,
                t!("ready-banner-terms-title"),
                t!("ready-banner-terms-message", release = release),
            )
        }
        // A look for the offer while Atlas waits for it leaves the live bar
        // as it was, so only a change is announced.
        ReadyStatus::Updating
            if state.offer_wait_running()
                && matches!(
                    state.preparation,
                    Preparation::Running {
                        stage: crate::services::preparation::Stage::WindowsSearch
                            | crate::services::preparation::Stage::Verify,
                        ..
                    }
                ) =>
        {
            let release =
                state.transition_request().map(|request| request.target_release).unwrap_or_default();
            (
                Severity::Informational,
                t!("prepare-not-offered-title", release = release.as_str()),
                t!("ready-banner-not-offered-message"),
            )
        }
        ReadyStatus::Updating => {
            let message = if state.preparation == Preparation::WaitingExternal {
                t!("prepare-previous-worker")
            } else if state.preparation_cancel.load(Ordering::Relaxed) {
                t!("prepare-stop-description")
            } else {
                t!("ready-banner-updating-message")
            };
            (Severity::Informational, t!("ready-banner-updating-title"), message)
        }
        ReadyStatus::UpdatesStopped => (
            Severity::Informational,
            t!("ready-banner-updates-stopped-title"),
            t!("ready-banner-updates-stopped-message"),
        ),
        ReadyStatus::UpdatesResumed => (
            Severity::Informational,
            t!("ready-banner-updates-resumed-title"),
            t!("ready-banner-updates-resumed-message"),
        ),
        ReadyStatus::UpdatesFailed => {
            // A move between Windows releases that stopped is named as such,
            // as the update card does.
            let failure = state.preparation_progress.as_ref().and_then(|progress| progress.failure());
            let reason =
                failure.and_then(|failure| failure.reason.as_deref()).filter(|r| r.starts_with("feature-"));
            let release =
                state.transition_request().map(|request| request.target_release).unwrap_or_default();
            match (failure, reason) {
                (Some(failure), Some(_)) if failure.not_offered() => (
                    Severity::Informational,
                    t!("prepare-not-offered-title", release = release.as_str()),
                    t!("ready-banner-not-offered-message"),
                ),
                (Some(_), Some(_)) => (
                    Severity::Error,
                    t!("prepare-transition-failed-title", release = release.as_str()),
                    t!("ready-banner-transition-failed-message"),
                ),
                _ => (Severity::Error, t!("prepare-failed-title"), t!("ready-banner-updates-failed-message")),
            }
        }
        ReadyStatus::UpdatesUnconfirmed => {
            (Severity::Warning, t!("prepare-unconfirmed-title"), t!("ready-banner-updates-failed-message"))
        }
        ReadyStatus::UpdatesRestart => {
            let severity =
                if state.preparation_problem.is_some() { Severity::Error } else { Severity::Warning };
            let message = match state.preparation {
                Preparation::SavingRestart => t!("prepare-saving-restart"),
                Preparation::Restarting => t!("prepare-shutdown-comment"),
                _ => t!("ready-banner-reboot-message"),
            };
            (severity, t!("prepare-reboot-title"), message)
        }
        ReadyStatus::Warnings => {
            (Severity::Warning, t!("ready-banner-warnings-title"), t!("ready-banner-warnings-message"))
        }
        ReadyStatus::Ready => (Severity::Success, t!("ready-banner-ok-title"), t!("ready-banner-ok-message")),
    };
    InfoBar::new(severity, title, message).id("ready-banner")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::requirements::CheckDetail;

    #[test]
    fn a_settings_page_is_offered_only_where_it_can_help() {
        let result = |id, verdict| CheckResult { id, verdict, detail: CheckDetail::AntivirusNone };
        assert!(offers_fix(&result(CheckId::ThirdPartyAntivirus, Verdict::Fail)));
        assert!(offers_fix(&result(CheckId::ThirdPartyAntivirus, Verdict::Unknown)));
        // Its files are gone already: there's nothing to uninstall.
        assert!(!offers_fix(&result(CheckId::ThirdPartyAntivirus, Verdict::Warn)));
        assert!(offers_fix(&result(CheckId::Activation, Verdict::Warn)));
        assert!(!offers_fix(&result(CheckId::Power, Verdict::Pass)));
    }
}
