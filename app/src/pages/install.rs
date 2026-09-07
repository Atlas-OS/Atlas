//! Install: a four-step flow. Get ready (checks and the package), choose
//! options, turn off Windows Security, install.
//!
//! Every action goes through the model's flow rules; the page only decides
//! what to show and which controls look enabled. All words come from the
//! message catalog at render time, from the model's semantic state.

use gpui::{
    AnyElement, App, Context, Entity, IntoElement, ParentElement, Point, Render, Role, ScrollHandle, Styled,
    Window, div, prelude::*, px,
};

use super::{
    LogIds, LogView, card_body, card_header, chip_list, detail_row, detail_text, focusable_heading,
    page_frame,
};
use crate::i18n::{describe, fmt};
use crate::model::{Acquisition, AppModel, Preflight, RunState, ScreenKind, Step};
use crate::services::installer::{self, InstallOutcome, Phase};
use crate::services::playbook::PageKind;
use crate::services::requirements::Verdict as CheckVerdict;
use crate::services::requirements::{CheckId, Verdict};
use crate::services::security::{Protection, Switch};
use crate::services::system::links;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CheckBox, FocusHandles, Icon, InfoBar, LightState, ProgressBar, ProgressRing, RadioGroup,
    RadioItem, ScrollbarState, Severity, StatusLight, Typography, a11y_text, card, icon, icon_sized,
};

const LOG_IDS: LogIds = LogIds { log: "install-log", hidden: "log-hidden", line: "log-line" };

/// Log lines drawn; older lines are in the file.
const LOG_LINES_SHOWN: usize = 500;

pub struct InstallPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    log: LogView,
    scrollbar: ScrollbarState,
    show_command: bool,
    windows_installation: crate::services::windows_installation::Evidence,
    used_windows_warning_dismissed: bool,
    /// The step drawn last frame, to reset scrolling and focus on a change.
    shown_step: Option<(Step, usize)>,
    shown_run: Option<RunState>,
    focus: FocusHandles,
}

impl InstallPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        cx.spawn(async move |this, cx| {
            let evidence = cx
                .background_executor()
                .spawn(async { crate::services::windows_installation::Evidence::read() })
                .await;
            this.update(cx, |this, cx| {
                this.windows_installation = evidence;
                cx.notify();
            })
            .ok();
        })
        .detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            log: LogView::default(),
            scrollbar: ScrollbarState::new(),
            show_command: false,
            windows_installation: Default::default(),
            used_windows_warning_dismissed: false,
            shown_step: None,
            shown_run: None,
            focus: FocusHandles::default(),
        }
    }

    fn stepper(&self, current: Step, may_edit: bool, window: &Window, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let mut row = div()
            .id("stepper")
            .role(Role::List)
            .aria_label(t!("stepper-label"))
            .flex()
            .items_center()
            .flex_wrap()
            .gap_y(px(8.))
            .pb(px(4.));
        for (index, step) in Step::ALL.iter().enumerate() {
            let done = step.index() < current.index();
            let active = *step == current;
            let title = step.title();
            let marker = div()
                .flex()
                .items_center()
                .justify_center()
                .size(px(22.))
                .relative()
                .top(crate::ui::body_cap_center_offset(window, cx))
                .rounded_full()
                .map(|this| {
                    if done || active {
                        this.bg(theme.accent).text_color(theme.text_on_accent)
                    } else {
                        this.border_1()
                            .border_color(theme.control_strong_stroke)
                            .text_color(theme.text_secondary)
                    }
                })
                .child(if done {
                    icon_sized(Icon::CheckMark, 10.).into_any_element()
                } else {
                    crate::ui::centred_step_number(fmt::integer(index as u64 + 1)).into_any_element()
                });
            let label = div()
                .type_body()
                .when(active, |this| this.type_body_strong())
                .text_color(if active { theme.text_primary } else { theme.text_secondary })
                .child(title.clone());
            let model = self.model.clone();
            let target = *step;
            let status = if done {
                t!("stepper-status-completed")
            } else if active {
                t!("stepper-status-current")
            } else {
                t!("stepper-status-upcoming")
            };
            let name = t!(
                "stepper-step-a11y",
                number = index + 1,
                total = Step::ALL.len(),
                title = title.as_str(),
                status = status
            );
            let clickable = done && may_edit;
            let hover = theme.subtle_hover;
            let focus_outer = theme.focus_outer;
            row = row.child(
                div()
                    .id(("step", index))
                    .role(if clickable { Role::Button } else { Role::ListItem })
                    .aria_label(name)
                    .aria_position_in_set(index + 1)
                    .aria_size_of_set(Step::ALL.len())
                    .flex()
                    .items_center()
                    .gap(px(8.))
                    .px(px(8.))
                    .py(px(4.))
                    .rounded(px(4.))
                    .border_1()
                    .border_color(theme.transparent())
                    // Completed steps can be revisited; later steps cannot be skipped to.
                    .when(clickable, |this| {
                        this.tab_index(0)
                            .hover(move |style| style.bg(hover))
                            .focus_visible(move |style| style.border_color(focus_outer))
                            .on_a11y_action(gpui::AccessibleAction::Click, {
                                let model = model.clone();
                                move |_, _, cx| model.update(cx, |m, cx| m.set_step(target, cx))
                            })
                            .on_click(move |_, _, cx| model.update(cx, |m, cx| m.set_step(target, cx)))
                    })
                    .child(marker)
                    .child(label),
            );
            if index + 1 < Step::ALL.len() {
                row = row.child(
                    crate::ui::icon_in_line_sized(Icon::ChevronRight, 10., crate::ui::BODY_LINE_HEIGHT)
                        .text_color(theme.text_tertiary)
                        .mx(px(4.)),
                );
            }
        }
        row.into_any_element()
    }

    // ----- Step 1: get ready ---------------------------------------------

    fn package_card(&self, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let release = state.release.release().cloned();

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
                (problem.text(), LightState::Bad, t!("package-status-failed"))
            }
            (Acquisition::Idle, Some(source)) => {
                (source.describe(), LightState::Good, t!("package-status-ready"))
            }
            (Acquisition::Idle, None) => match &state.release {
                crate::model::ReleaseCheck::Checking | crate::model::ReleaseCheck::NotChecked => {
                    (t!("package-looking"), LightState::Pending, t!("package-status-checking"))
                }
                _ => (t!("package-none"), LightState::Caution, t!("package-status-missing")),
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
        let busy = state.acquisition.is_busy() || state.locked() || !state.flow.may_edit();
        let download_label = match (&release, &state.playbook) {
            (Some(r), Some(p)) if p.manifest.version == r.version() => t!("package-download-again"),
            (Some(r), _) => t!("package-download-version", version = r.version()),
            (None, _) => t!("package-download-newest"),
        };

        card(cx)
            .child(card_header(
                cx,
                "package",
                t!("package-title"),
                Some(StatusLight::new(light, light_label).id("package-status").into_any_element()),
            ))
            .child(
                card_body(cx)
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
                            .when(state.can_download_latest() || state.playbook.is_none(), |this| {
                                this.child(
                                    Button::new("source-download", download_label)
                                        .icon(Icon::Download)
                                        .disabled(busy || release.is_none())
                                        .on_click({
                                            let model = model.clone();
                                            move |_, _, cx| model.update(cx, |m, cx| m.acquire_latest(cx))
                                        }),
                                )
                            })
                            .child(
                                Button::new("source-local", t!("package-open-file"))
                                    .icon(Icon::Folder)
                                    .disabled(busy)
                                    .on_click({
                                        let model = model.clone();
                                        move |_, _, cx| model.update(cx, |m, cx| m.choose_local_playbook(cx))
                                    }),
                            ),
                    ),
            )
            .into_any_element()
    }

    fn ready_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let drivers = self.drivers_card(cx);
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let running = !state.checks_complete();
        let blocking = state.checks_blocking();
        let warnings = state.checks.iter().any(|(_, r)| matches!(r, Some(r) if r.verdict != Verdict::Pass));
        let may_edit = state.flow.may_edit() && !state.locked();

        let banner = if !state.preparation.ready() {
            InfoBar::new(Severity::Informational, t!("prepare-title"), t!("prepare-description"))
        } else if running || state.acquisition.is_busy() {
            InfoBar::new(
                Severity::Informational,
                t!("ready-banner-busy-title"),
                t!("ready-banner-busy-message"),
            )
        } else if blocking {
            InfoBar::new(
                Severity::Error,
                t!("ready-banner-blocked-title"),
                t!("ready-banner-blocked-message"),
            )
        } else if state.playbook.is_none() {
            InfoBar::new(
                Severity::Warning,
                t!("ready-banner-no-package-title"),
                t!("ready-banner-no-package-message"),
            )
        } else if warnings {
            InfoBar::new(
                Severity::Warning,
                t!("ready-banner-warnings-title"),
                t!("ready-banner-warnings-message"),
            )
        } else {
            InfoBar::new(Severity::Success, t!("ready-banner-ok-title"), t!("ready-banner-ok-message"))
        }
        .id("ready-banner");

        let mut list = div().id("checks").role(Role::List).aria_label(t!("ready-this-pc")).flex().flex_col();
        for (index, (id, result)) in state.checks.iter().enumerate() {
            let (glyph, colour): (AnyElement, gpui::Hsla) = match result {
                None => (ProgressRing::new().into_any_element(), theme.accent),
                Some(result) => match result.verdict {
                    Verdict::Pass => (icon(Icon::Completed).into_any_element(), theme.success),
                    Verdict::Fail if id.blocking() => {
                        (icon(Icon::ErrorBadge).into_any_element(), theme.critical)
                    }
                    Verdict::Warn | Verdict::Fail => (icon(Icon::Warning).into_any_element(), theme.caution),
                    Verdict::Unknown if id.blocking() => {
                        (icon(Icon::Unknown).into_any_element(), theme.critical)
                    }
                    Verdict::Unknown => (icon(Icon::Unknown).into_any_element(), theme.text_secondary),
                },
            };
            let detail = result
                .as_ref()
                .map(|r| r.detail.text(&state.system))
                .unwrap_or_else(|| t!("common-checking"));
            let state_word = match result {
                None => t!("check-state-checking"),
                Some(r) => match r.verdict {
                    Verdict::Pass => t!("check-state-passed"),
                    Verdict::Warn => t!("check-state-warning"),
                    Verdict::Fail if id.blocking() => t!("check-state-failed-blocking"),
                    Verdict::Fail => t!("check-state-failed"),
                    Verdict::Unknown => t!("check-state-unknown"),
                },
            };
            let fix = match (result, id.fix_target(), id.fix_label()) {
                (Some(r), Some(target), Some(label)) if r.verdict != Verdict::Pass => Some(
                    Button::new(("fix", index), label)
                        .compact()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(target)
                        .into_any_element(),
                ),
                (Some(r), None, _) if *id == CheckId::Administrator && r.verdict == Verdict::Fail => Some(
                    Button::new("fix-elevate", t!("common-restart-as-administrator"))
                        .compact()
                        .icon(Icon::Admin)
                        .disabled(!may_edit)
                        .on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.relaunch_elevated(cx))
                        })
                        .into_any_element(),
                ),
                _ => None,
            };
            let acknowledgement = result.as_ref().filter(|r| r.needs_acknowledgement()).map(|r| {
                let check = r.id;
                let confirmed = state.acknowledged.contains(&check);
                CheckBox::new(("acknowledge", index), check.acknowledgement(), confirmed)
                    .disabled(!may_edit)
                    .on_toggle({
                        let model = model.clone();
                        move |_, _, cx| {
                            model.update(cx, |m, cx| m.acknowledge_check(check, !confirmed, cx));
                        }
                    })
            });
            list = list.child(
                div()
                    .id(("check", index))
                    .role(Role::ListItem)
                    .aria_label(t!("check-a11y", title = id.title(), state = state_word))
                    .aria_description(detail.clone())
                    .flex()
                    .flex_col()
                    .when(index > 0, |this| this.border_t_1().border_color(theme.divider))
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(16.))
                            .px(px(16.))
                            .py(px(12.))
                            .child(
                                crate::ui::TextMark::new(
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
                                            .child(crate::ui::CapCenteredText(id.title().into())),
                                    )
                                    .child(
                                        div().type_caption().text_color(theme.text_secondary).child(detail),
                                    ),
                            )
                            .when_some(fix, |this, fix| this.child(fix)),
                    )
                    .when_some(acknowledgement, |this, acknowledgement| {
                        this.child(div().px(px(44.)).pb(px(8.)).child(acknowledgement))
                    }),
            );
        }

        let show_used_windows_warning =
            matches!(state.install_identity, Ok(crate::services::atlas_state::InstallIdentity::Fresh))
                && self.windows_installation.suggests_prior_use()
                && !self.used_windows_warning_dismissed;
        let mut cards = vec![
            drivers,
            self.preparation_card(cx),
            self.package_card(cx),
            card(cx)
                .child(card_header(
                    cx,
                    "checks",
                    t!("ready-this-pc"),
                    Some(
                        Button::new("checks-rerun", t!("ready-check-again"))
                            .compact()
                            .icon(Icon::Refresh)
                            .disabled(running || !may_edit)
                            .on_click({
                                let model = model.clone();
                                move |_, _, cx| model.update(cx, |m, cx| m.run_checks(cx))
                            })
                            .into_any_element(),
                    ),
                ))
                .child(list)
                .into_any_element(),
        ];
        if !show_used_windows_warning {
            cards.insert(
                0,
                InfoBar::new(Severity::Warning, t!("ready-fresh-title"), t!("ready-fresh-description"))
                    .into_any_element(),
            );
        }
        if let Some(problem) = state.install_eligibility_problem() {
            cards.insert(
                0,
                InfoBar::new(Severity::Error, t!("install-source-title"), problem).into_any_element(),
            );
        }
        if state.preparation.ready() {
            cards.insert(0, banner.into_any_element());
        }
        if show_used_windows_warning {
            cards.insert(
                0,
                InfoBar::new(
                    Severity::Warning,
                    t!("ready-used-windows-title"),
                    t!("ready-used-windows-description"),
                )
                .id("ready-used-windows-warning")
                .action(Button::new("ready-used-windows-dismiss", t!("ready-used-windows-dismiss")).on_click(
                    cx.listener(|this, _, _, cx| {
                        this.used_windows_warning_dismissed = true;
                        cx.notify();
                    }),
                ))
                .into_any_element(),
            );
        }
        cards
    }

    fn preparation_card(&self, cx: &App) -> AnyElement {
        use crate::services::preparation::{Stage, State};
        let state = self.model.read(cx);
        let message = match &state.preparation {
            State::Idle => t!("prepare-description"),
            State::Resumed => t!("prepare-resumed"),
            State::SavingRestart => t!("prepare-saving-restart"),
            State::Ready => t!("prepare-complete"),
            State::Reboot | State::Restarting => t!("prepare-reboot"),
            State::Failed => t!("prepare-failed"),
            State::Cancelled => t!("prepare-cancelled"),
            State::Network => t!("prepare-network-needed"),
            State::WaitingExternal => t!("prepare-previous-worker"),
            State::Running { stage, .. } => match stage {
                Stage::WindowsSearch | Stage::Verify => t!("prepare-windows-search"),
                Stage::WindowsDownload => t!("prepare-windows-download"),
                Stage::WindowsInstall => t!("prepare-windows-install"),
                Stage::StoreSearch => t!("prepare-store-search"),
                Stage::StoreInstall => t!("prepare-store-install"),
            },
        };
        let model = self.model.clone();
        let busy = state.preparation.busy();
        let reboot = state.preparation == State::Reboot;
        card(cx)
            .child(card_header(cx, "preparation", t!("prepare-title"), None))
            .child(
                card_body(cx)
                    .gap(px(12.))
                    .child(div().child(a11y_text("preparation-status", message.clone())))
                    .when_some(state.preparation_problem, |this, problem| {
                        use crate::services::preparation::RestartProblem;
                        let message = match problem {
                            RestartProblem::Save => t!("prepare-restart-save-failed"),
                            RestartProblem::Registration => t!("prepare-restart-registration-failed"),
                            RestartProblem::Restart => t!("prepare-restart-failed"),
                        };
                        this.child(a11y_text("preparation-restart-problem", message))
                    })
                    .when(state.preparation == State::Network, |this| {
                        this.child(
                            Button::new("prepare-network", t!("prepare-network-settings"))
                                .opens("ms-settings:network"),
                        )
                    })
                    .when(busy, |this| {
                        let value = match state.preparation {
                            State::Running { stage: Stage::StoreInstall, completed, total } if total > 0 => {
                                Some(completed as f32 / total as f32)
                            }
                            _ => None,
                        };
                        this.child(ProgressBar::new("preparation-progress", message.clone(), value)).when(
                            !matches!(
                                state.preparation,
                                State::WaitingExternal | State::SavingRestart | State::Restarting
                            ),
                            |this| {
                                this.child(detail_text(
                                    "preparation-stop-detail",
                                    t!("prepare-stop-description"),
                                ))
                            },
                        )
                    })
                    .when(state.preparation != State::WaitingExternal, |this| {
                        this.child(
                            Button::new(
                                "prepare-action",
                                if busy && state.preparation_cancel.load(std::sync::atomic::Ordering::Relaxed)
                                {
                                    t!("iso-cancelling")
                                } else if matches!(
                                    state.preparation,
                                    State::SavingRestart | State::Restarting
                                ) {
                                    t!("prepare-restart")
                                } else if busy {
                                    t!("prepare-stop")
                                } else if reboot {
                                    t!("prepare-restart")
                                } else if !state.elevated {
                                    t!("common-restart-as-administrator")
                                } else if state.preparation == State::Resumed {
                                    t!("prepare-continue")
                                } else {
                                    t!("prepare-start")
                                },
                            )
                            .when(!busy && !reboot && !state.elevated, |button| button.icon(Icon::Admin))
                            .disabled(
                                state.preparation.ready()
                                    || (!busy && !state.preparation_build_supported())
                                    || (!busy && state.install_eligibility_problem().is_some())
                                    || state.preparation == State::Restarting
                                    || state.preparation == State::SavingRestart
                                    || (busy
                                        && state
                                            .preparation_cancel
                                            .load(std::sync::atomic::Ordering::Relaxed)),
                            )
                            .on_click(move |_, _, cx| {
                                model.update(cx, |m, cx| {
                                    if m.preparation.busy() {
                                        m.preparation_cancel
                                            .store(true, std::sync::atomic::Ordering::Relaxed);
                                    } else if !m.elevated {
                                        m.relaunch_elevated(cx);
                                    } else if reboot {
                                        m.restart_preparation(cx);
                                    } else {
                                        m.prepare_windows(cx);
                                    }
                                    cx.notify();
                                })
                            }),
                        )
                    })
                    .when_some(state.preparation_job.clone(), |this, job| {
                        this.child(
                            Button::new("prepare-log", t!("iso-diagnostics"))
                                .on_click(move |_, _, cx| cx.reveal_path(&job)),
                        )
                    }),
            )
            .into_any_element()
    }

    // ----- Step 2: options ---------------------------------------------
    fn drivers_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        use crate::services::preparation::Drivers;
        let state = self.model.read(cx);
        let selected = usize::from(state.driver_preference() == Drivers::Manual);
        let disabled = state.locked() || !state.flow.may_edit();
        let model = self.model.clone();
        let items = [
            RadioItem::new("prepare-auto", t!("prepare-drivers-auto"), self.focus.get("prepare-auto", cx))
                .description(t!("prepare-drivers-auto-detail")),
            RadioItem::new(
                "prepare-manual",
                t!("prepare-drivers-manual"),
                self.focus.get("prepare-manual", cx),
            )
            .description(t!("prepare-drivers-manual-detail")),
        ];
        card(cx)
            .child(card_header(cx, "drivers", t!("prepare-drivers"), None))
            .child(
                card_body(cx).child(
                    RadioGroup::new("prepare-drivers", t!("prepare-drivers"))
                        .items(items)
                        .disabled(disabled)
                        .selected(Some(selected))
                        .on_select(move |index, _, cx| {
                            model.update(cx, |m, cx| {
                                m.set_drivers(
                                    if index == 0 { Drivers::Automatic } else { Drivers::Manual },
                                    cx,
                                )
                            });
                        }),
                ),
            )
            .into_any_element()
    }

    fn options_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme().clone();
        let (manifest, options, may_edit, screens, current, package_dir) = {
            let state = self.model.read(cx);
            (
                state.manifest().clone(),
                state.options.clone(),
                state.flow.may_edit(),
                state.option_screens(),
                state.current_option_screen(),
                state.playbook.as_ref().map(|package| package.dir.clone()),
            )
        };
        let Some(screen) = screens.get(current) else { return Vec::new() };
        let model = self.model.clone();
        let mut cards = Vec::new();

        // One decision at a time: the question is the heading, the choice
        // below it, with consequences visible before either answer is chosen.
        cards.push(
            div()
                .flex()
                .items_baseline()
                .gap(px(8.))
                .child(div().type_caption().text_color(theme.text_secondary).child(a11y_text(
                    "option-progress",
                    if screen.required {
                        t!("options-progress", number = current + 1, total = screens.len())
                    } else {
                        t!("options-progress-extras", number = current + 1, total = screens.len())
                    },
                )))
                .into_any_element(),
        );

        for &page_index in &screen.pages {
            let page = &manifest.pages[page_index];
            if page.depends_on.as_ref().is_some_and(|dependency| !options.contains(dependency)) {
                continue;
            }
            let kind = ScreenKind::of_page(page);
            let title = kind.title();
            let header = if screen.required { screen.kind.question() } else { title.clone() };
            let mut body = card_body(cx).gap(px(2.));
            if let Some(description) = describe::page_description(page) {
                body = body.child(
                    div()
                        .type_body()
                        .text_color(theme.text_secondary)
                        .pb(px(4.))
                        .child(a11y_text(("option-page-description", page_index), description)),
                );
            }
            let model = model.clone();
            match page.kind {
                PageKind::Radio => {
                    let items: Vec<RadioItem> = page
                        .options
                        .iter()
                        .map(|option| {
                            let key = format!("option-{page_index}-{}", option.name);
                            let handle = self.focus.get(&key, cx);
                            let mut item = RadioItem::new(
                                gpui::ElementId::Name(key.into()),
                                describe::option_label(&option.name, &option.text),
                                handle,
                            );
                            if kind == ScreenKind::Browser
                                && let Some(path) =
                                    package_dir.as_deref().and_then(|dir| option.image_path(dir))
                            {
                                item = item.image(path);
                            }
                            if let Some(consequence) =
                                describe::known_option_consequence(&option.name, &option.text)
                            {
                                item = item.description(consequence);
                            }
                            item
                        })
                        .collect();
                    let names: Vec<String> = page.options.iter().map(|o| o.name.clone()).collect();
                    let selected = page.options.iter().position(|o| options.contains(&o.name));
                    body = body.child(
                        RadioGroup::new(("option-group", page_index), header.clone())
                            .items(items)
                            .selected(selected)
                            .disabled(!may_edit)
                            .on_select(move |index, _, cx| {
                                let name = names[index].clone();
                                model.update(cx, |m, cx| m.choose_option(page_index, &name, cx));
                            }),
                    );
                }
                PageKind::Checkbox => {
                    let mut group = div()
                        .id(("option-group", page_index))
                        .role(Role::Group)
                        .aria_label(title.clone())
                        .flex()
                        .flex_col()
                        .gap(px(2.));
                    for option in &page.options {
                        let selected = options.contains(&option.name);
                        let model = model.clone();
                        let name = option.name.clone();
                        let id = gpui::ElementId::Name(format!("option-{page_index}-{}", option.name).into());
                        group = group.child(
                            CheckBox::new(id, describe::option_label(&option.name, &option.text), selected)
                                .map(|checkbox| match option.name.as_str() {
                                    "install-toolbox" => checkbox.image("brand/toolbox.png"),
                                    "install-eclean" => checkbox.image("brand/eclean.png"),
                                    _ => checkbox,
                                })
                                .map(|checkbox| {
                                    if let Some(description) =
                                        describe::known_option_consequence(&option.name, &option.text)
                                    {
                                        checkbox.description(description)
                                    } else {
                                        checkbox
                                    }
                                })
                                .disabled(!may_edit)
                                .on_toggle(move |_, _, cx| {
                                    let name = name.clone();
                                    model.update(cx, |m, cx| m.choose_option(page_index, &name, cx));
                                }),
                        );
                    }
                    body = body.child(group);
                }
            }
            if let Some(link) = &page.learn_more {
                body = body.child(
                    div().flex().pt(px(6.)).child(
                        Button::new(("learn", page_index), kind.learn_more())
                            .hyperlink()
                            .compact()
                            .trailing_icon(Icon::OpenInNewWindow)
                            .opens(link.url.clone()),
                    ),
                );
            }
            cards.push(
                card(cx)
                    .child(card_header(cx, &format!("option-page-{page_index}"), header, None))
                    .child(body)
                    .into_any_element(),
            );
        }
        cards
    }

    // ----- Step 3: Windows Security ------------------------------------

    fn security_cards(&self, cx: &App) -> Vec<AnyElement> {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let status = state.security;
        let counts = status.counts();
        let fresh = state.security_fresh();
        let may_edit = state.flow.may_edit();

        let banner = match security_banner(&status, fresh) {
            SecurityBanner::Reading => InfoBar::new(
                Severity::Informational,
                t!("security-banner-reading-title"),
                t!("security-banner-reading-message"),
            ),
            SecurityBanner::AllOff => InfoBar::new(
                Severity::Success,
                t!("security-banner-off-title"),
                t!("security-banner-off-message"),
            ),
            SecurityBanner::ReadableOff => InfoBar::new(
                Severity::Warning,
                t!("security-banner-readable-off-title"),
                t!("security-banner-readable-off-message"),
            )
            .action(
                Button::new("open-security", t!("common-open-windows-security"))
                    .icon(Icon::Shield)
                    .opens(links::WINDOWS_SECURITY_PROTECTION),
            ),
            SecurityBanner::TurnOff => InfoBar::new(
                Severity::Warning,
                t!("security-banner-on-title"),
                t!("security-banner-on-message"),
            )
            .action(
                Button::new("open-security", t!("common-open-windows-security"))
                    .accent()
                    .icon(Icon::Shield)
                    .opens(links::WINDOWS_SECURITY_PROTECTION),
            ),
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
            let (light, label) = match switch {
                Switch::Off => (LightState::Good, t!("security-switch-off")),
                Switch::On => (LightState::Bad, t!("security-switch-on")),
                Switch::Unknown if fresh => (LightState::Unknown, t!("security-switch-unreadable")),
                Switch::Unknown => (LightState::Pending, t!("security-switch-reading")),
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
                        crate::ui::TextMark::new(
                            div()
                                .flex()
                                .items_center()
                                .justify_center()
                                .size(px(32.))
                                .rounded(px(6.))
                                .bg(theme.subtle_hover)
                                .text_color(if switch.is_off() {
                                    theme.success
                                } else {
                                    theme.text_secondary
                                })
                                .child(icon(if switch.is_off() { Icon::Unlock } else { Icon::Lock })),
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
                                    .child(crate::ui::CapCenteredText(protection.title().into())),
                            )
                            .child(
                                div().type_caption().text_color(theme.text_secondary).child(protection.why()),
                            ),
                    )
                    .child(crate::ui::TextMark::new(StatusLight::new(light, label), true).strong()),
            );
        }

        let header_status = if !fresh {
            StatusLight::new(LightState::Pending, t!("security-switch-reading"))
        } else if status.all_off() {
            StatusLight::new(LightState::Good, t!("security-all-off"))
        } else if counts.on > 0 {
            StatusLight::new(LightState::Bad, describe::security_summary(&counts))
        } else {
            StatusLight::new(LightState::Unknown, describe::security_summary(&counts))
        }
        .id("security-summary");

        let unknown_hint = (fresh && counts.unknown > 0).then(|| {
            if state.elevated {
                let confirmed = state.security_acknowledged();
                InfoBar::new(
                    Severity::Informational,
                    t!("security-unknown-title"),
                    t!("security-unknown-message"),
                )
                .id("security-unknown")
                .action(
                    CheckBox::new("security-acknowledge", t!("security-acknowledge"), confirmed)
                        .disabled(!status.off_where_readable() || !may_edit)
                        .on_toggle({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.acknowledge_security(!confirmed, cx))
                        }),
                )
                .into_any_element()
            } else {
                InfoBar::new(
                    Severity::Informational,
                    t!("security-unknown-unelevated-title"),
                    t!("security-unknown-unelevated-message"),
                )
                .id("security-unknown")
                .action(
                    Button::new("security-elevate", t!("common-restart-as-administrator"))
                        .icon(Icon::Admin)
                        .disabled(!may_edit)
                        .on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.relaunch_elevated(cx))
                        }),
                )
                .into_any_element()
            }
        });

        let mut cards = vec![banner.into_any_element()];
        cards.push(
            card(cx)
                .child(card_header(
                    cx,
                    "security",
                    t!("security-list-title"),
                    Some(header_status.into_any_element()),
                ))
                .child(list)
                .into_any_element(),
        );
        if let Some(hint) = unknown_hint {
            cards.push(hint);
        }
        cards
    }

    // ----- Step 4: install -----------------------------------------------

    fn install_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let result_focus = self.focus.get("install-result", cx);
        let state = self.model.read(cx);
        let request = state.install_request();
        let run = state.flow.run;
        let mut cards = Vec::new();

        // The current phase or result comes first, so it is never hidden
        // below the summary at small window sizes.
        match run {
            RunState::Idle => {}
            RunState::Preparing => {
                cards.push(
                    InfoBar::new(
                        Severity::Informational,
                        t!("install-preparing-title"),
                        t!("install-preparing-message"),
                    )
                    .id("install-preparing")
                    .focus_handle(result_focus.clone())
                    .into_any_element(),
                );
            }
            RunState::Running => {
                let phase_text = match state.attempt.phase {
                    Phase::Preflight => t!("phase-preflight"),
                    Phase::Staging => t!("phase-staging"),
                    Phase::Applying => t!("phase-applying"),
                    Phase::Done => t!("phase-done"),
                };
                cards.push(
                    card(cx)
                        .child(card_header(
                            cx,
                            "installing",
                            t!("install-installing"),
                            Some(
                                StatusLight::new(LightState::Pending, t!("install-running"))
                                    .id("install-status")
                                    .into_any_element(),
                            ),
                        ))
                        .child(
                            div()
                                .px(px(16.))
                                .pt(px(12.))
                                .flex()
                                .flex_col()
                                .gap(px(8.))
                                .child(
                                    div()
                                        .type_body()
                                        .text_color(theme.text_primary)
                                        .child(a11y_text("install-phase", phase_text)),
                                )
                                .child(ProgressBar::new("install-progress", t!("install-progress"), None)),
                        )
                        .child(self.log_view(cx))
                        .into_any_element(),
                );
            }
            RunState::Finished(outcome) => {
                let severity = match outcome {
                    InstallOutcome::Succeeded => Severity::Success,
                    InstallOutcome::Lost => Severity::Warning,
                    _ => Severity::Error,
                };
                let message: String = match (
                    outcome.is_success(),
                    state.restart_countdown(),
                    state.attempt.restart_cancelled,
                ) {
                    (true, Some(0), _) => t!("restart-now-message"),
                    (true, Some(seconds), _) => t!("restart-countdown", seconds = seconds),
                    (true, None, true) => t!("restart-stopped"),
                    _ => outcome.advice(state.attempt.phase),
                };
                let mut bar = InfoBar::new(severity, outcome.title(), message)
                    .id("install-result")
                    .focus_handle(result_focus.clone());
                if outcome.is_success() && state.restart_countdown().is_some() {
                    bar = bar.action(Button::new("result-stop-restart", t!("restart-dont-now")).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.cancel_restart(cx))
                    }));
                }
                if !outcome.is_success() && state.attempt.phase >= Phase::Applying {
                    bar = bar.action(
                        Button::new("result-open-security", t!("common-open-windows-security"))
                            .icon(Icon::Shield)
                            .opens(links::WINDOWS_SECURITY_PROTECTION),
                    );
                }
                cards.push(bar.into_any_element());
                cards.push(
                    card(cx)
                        .child(card_header(
                            cx,
                            "log",
                            t!("common-install-log"),
                            Some(self.log_actions(cx).into_any_element()),
                        ))
                        .child(self.log_view(cx))
                        .into_any_element(),
                );
            }
        }

        let state = self.model.read(cx);
        if let Some(problem) = &state.preflight_problem {
            // The button leads to the step that fixes the problem: unusable
            // choices are corrected on step 2, everything else on step 1.
            let (label, target) = match problem {
                Preflight::InvalidOptions { .. } => (t!("go-to-options"), Step::Options),
                _ => (t!("go-to-ready"), Step::Ready),
            };
            cards.push(
                InfoBar::new(Severity::Error, t!("preflight-title"), problem.text(&state.system))
                    .id("install-preflight")
                    .action(Button::new("install-back-ready", label).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.set_step(target, cx))
                    }))
                    .into_any_element(),
            );
        }
        if let Some(problem) = &state.attempt.output_problem {
            cards.push(
                InfoBar::new(
                    Severity::Warning,
                    t!("output-problem-title"),
                    t!("output-problem-message", error = problem),
                )
                .id("install-output-problem")
                .into_any_element(),
            );
        }

        if run == RunState::Idle {
            if !state.elevated {
                cards.push(
                    InfoBar::new(
                        Severity::Error,
                        t!("install-elevate-title"),
                        state.elevation_error.as_ref().map(|e| e.text()).unwrap_or_default(),
                    )
                    .id("install-elevate-bar")
                    .action(
                        Button::new("install-elevate", t!("common-restart-as-administrator"))
                            .accent()
                            .icon(Icon::Admin)
                            .on_click({
                                let model = model.clone();
                                move |_, _, cx| model.update(cx, |m, cx| m.relaunch_elevated(cx))
                            }),
                    )
                    .into_any_element(),
                );
            } else if state.playbook.is_none() {
                cards.push(
                    InfoBar::new(
                        Severity::Warning,
                        t!("install-no-package-title"),
                        t!("install-no-package-message"),
                    )
                    .id("install-no-package")
                    .action(Button::new("install-back-ready", t!("go-to-ready")).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.set_step(Step::Ready, cx))
                    }))
                    .into_any_element(),
                );
            } else if !state.security_ok() {
                let message = if !state.security_fresh() {
                    t!("install-security-reading")
                } else {
                    t!(
                        "install-security-message",
                        summary = describe::security_summary(&state.security.counts())
                    )
                };
                cards.push(
                    InfoBar::new(Severity::Warning, t!("install-security-title"), message)
                        .id("install-security")
                        .action(
                            Button::new("install-open-security", t!("common-open-windows-security"))
                                .icon(Icon::Shield)
                                .opens(links::WINDOWS_SECURITY_PROTECTION),
                        )
                        .into_any_element(),
                );
            }
        }

        let option_names: Vec<String> = request
            .as_ref()
            .map(|r| r.options.iter().map(|o| state.option_label(o)).collect())
            .unwrap_or_default();
        let activation = state
            .checks
            .iter()
            .find(|(id, _)| *id == CheckId::Activation)
            .and_then(|(_, result)| result.as_ref())
            .map(|result| match result.verdict {
                CheckVerdict::Pass => t!("summary-activation-ok"),
                CheckVerdict::Warn => t!("summary-activation-missing"),
                _ => t!("summary-activation-unknown"),
            })
            .unwrap_or_else(|| t!("summary-activation-unknown"));
        let show_command = self.show_command;
        let restart = request.as_ref().map(|r| r.restart).unwrap_or(state.settings.restart_after_install);
        let recorded = state.showing_recorded_install();
        let package = match (&state.session, &state.playbook) {
            (Some(session), _) if recorded => {
                t!("package-at", path = installer::plain_path(&session.request.playbook_dir))
            }
            (_, Some(source)) => source.describe(),
            (_, None) => t!("package-none-yet"),
        };
        let summary_title = if recorded {
            t!("summary-this-install")
        } else if matches!(run, RunState::Finished(_)) {
            t!("summary-try-again")
        } else {
            t!("summary-ready")
        };
        let command = request.as_ref().map(|request| match installer::command_line(request) {
            Ok(command) => command,
            Err(error) => t!("summary-command-unavailable", error = format!("{error:#}")),
        });
        let summary = card(cx).child(card_header(cx, "summary", summary_title, None)).child(
            card_body(cx)
                .child(detail_row(cx, "package", t!("common-package"), detail_text("package", package)))
                .child(detail_row(
                    cx,
                    "windows",
                    t!("common-windows"),
                    detail_text("windows", describe::system_description(&state.system)),
                ))
                .map(|this| {
                    if recorded {
                        this.child(detail_row(
                            cx,
                            "options",
                            t!("common-options"),
                            chip_list(cx, "install-options", &t!("common-options"), option_names),
                        ))
                    } else {
                        this.children(self.choice_rows(cx))
                    }
                })
                .child(detail_row(
                    cx,
                    "activation",
                    t!("summary-activation"),
                    detail_text("activation", activation),
                ))
                .child(detail_row(
                    cx,
                    "duration",
                    t!("summary-duration"),
                    detail_text(
                        "duration",
                        t!("summary-duration-value", minutes = state.manifest().estimated_minutes),
                    ),
                ))
                .child(
                    CheckBox::new("install-restart", t!("summary-restart-checkbox"), restart)
                        .description(t!("settings-restart-description"))
                        .disabled(recorded)
                        .on_toggle({
                            let model = model.clone();
                            move |_, _, cx| {
                                model.update(cx, |m, cx| {
                                    let next = !m.settings.restart_after_install;
                                    m.set_restart_after_install(next, cx);
                                })
                            }
                        }),
                )
                .when_some(command, |this, command| {
                    this.child(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(6.))
                            .pt(px(4.))
                            .child(
                                div().flex().child(
                                    Button::new(
                                        "toggle-command",
                                        if show_command {
                                            t!("summary-hide-command")
                                        } else {
                                            t!("summary-show-command")
                                        },
                                    )
                                    .hyperlink()
                                    .compact()
                                    .trailing_icon(if show_command {
                                        Icon::ChevronUp
                                    } else {
                                        Icon::ChevronDown
                                    })
                                    .on_click(cx.listener(
                                        |this, _, _, cx| {
                                            this.show_command = !this.show_command;
                                            cx.notify();
                                        },
                                    )),
                                ),
                            )
                            .when(show_command, |this| {
                                // The exact command, as the installer receives it.
                                this.child(
                                    div()
                                        .px(px(12.))
                                        .py(px(8.))
                                        .rounded(px(4.))
                                        .bg(theme.subtle_hover)
                                        .type_mono()
                                        .text_color(theme.text_secondary)
                                        .child(a11y_text("install-command", command)),
                                )
                            }),
                    )
                }),
        );
        cards.push(summary.into_any_element());
        cards
    }

    /// "Your choices": one row per Options screen with a Change link back
    /// to it, so nothing has to be walked again to fix one thing.
    fn choice_rows(&self, cx: &App) -> Vec<AnyElement> {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let manifest = state.manifest();
        let mut rows = Vec::new();
        for (index, screen) in state.option_screens().into_iter().enumerate() {
            let chosen: Vec<String> = screen
                .pages
                .iter()
                .filter_map(|&page_index| manifest.pages.get(page_index))
                .filter(|page| {
                    page.depends_on.as_ref().is_none_or(|dependency| state.options.contains(dependency))
                })
                .flat_map(|page| page.options.iter())
                .filter(|option| state.options.contains(&option.name))
                .map(|option| describe::option_label(&option.name, &option.text))
                .collect();
            let title = screen.kind.title();
            let key = format!("choice-{index}");
            let change = Button::new(("change-choice", index), t!("common-change"))
                .hyperlink()
                .compact()
                .aria_label(t!("summary-change-a11y", title = title.as_str()))
                .disabled(!state.flow.may_edit())
                .on_click({
                    let model = model.clone();
                    move |_, _, cx| model.update(cx, |m, cx| m.edit_options(index, cx))
                });
            let value: AnyElement = if screen.required {
                div()
                    .flex()
                    .items_center()
                    .min_w_0()
                    .flex_wrap()
                    .gap(px(8.))
                    .child(div().min_w_0().max_w_full().child(detail_text(
                        &key,
                        chosen.first().cloned().unwrap_or_else(|| t!("summary-not-chosen")),
                    )))
                    .child(change)
                    .into_any_element()
            } else if chosen.is_empty() {
                div()
                    .flex()
                    .items_center()
                    .min_w_0()
                    .flex_wrap()
                    .gap(px(8.))
                    .child(div().text_color(theme.text_secondary).child(detail_text(&key, t!("common-none"))))
                    .child(change)
                    .into_any_element()
            } else {
                div()
                    .flex()
                    .items_center()
                    .min_w_0()
                    .flex_wrap()
                    .gap(px(8.))
                    .child(chip_list(cx, ("choices", index), &title, chosen))
                    .child(change)
                    .into_any_element()
            };
            rows.push(detail_row(cx, &key, title, value).into_any_element());
        }
        rows
    }

    fn log_actions(&self, cx: &App) -> gpui::Div {
        let model = self.model.clone();
        let has_log = self.model.read(cx).session.is_some();
        div()
            .flex()
            .gap(px(8.))
            .child(
                Button::new("log-copy", t!("common-copy"))
                    .compact()
                    .icon(Icon::Copy)
                    .aria_label(t!("common-copy-install-log"))
                    .on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.copy_log(cx))
                    }),
            )
            .child(
                Button::new("log-open", t!("common-open-log-file"))
                    .compact()
                    .icon(Icon::Folder)
                    .disabled(!has_log)
                    .on_click(move |_, _, cx| model.update(cx, |m, cx| m.reveal_log(cx))),
            )
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        let running = state.flow.run == RunState::Running;
        let actions = if running { Some(self.log_actions(cx)) } else { None };
        div()
            .flex()
            .flex_col()
            .when_some(actions, |this, actions| this.child(div().px(px(16.)).pt(px(12.)).child(actions)))
            .child(self.log.render(LOG_IDS, 280., LOG_LINES_SHOWN, &state.attempt, cx))
            .into_any_element()
    }

    fn footer(&self, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let step = state.flow.step;
        let run = state.flow.run;
        let locked = state.locked();
        let finished_ok = matches!(run, RunState::Finished(outcome) if outcome.is_success());

        let (hint, next_enabled): (String, bool) = match step {
            Step::Ready => {
                if state.install_eligibility_problem().is_some() {
                    (t!("install-source-title"), false)
                } else if !state.checks_complete() || state.acquisition.is_busy() {
                    (t!("footer-still-checking"), false)
                } else if state.checks_blocking() {
                    (t!("footer-fix-items"), false)
                } else if state.playbook.is_none() {
                    (t!("footer-need-package"), false)
                } else if !state.preparation.ready() {
                    (String::new(), false)
                } else {
                    (String::new(), true)
                }
            }
            Step::Options => (String::new(), true),
            Step::Security => {
                if state.security_ok() {
                    (String::new(), true)
                } else if !state.security_fresh() {
                    (t!("footer-reading-security"), false)
                } else {
                    (describe::security_summary(&state.security.counts()), false)
                }
            }
            Step::Install => (String::new(), false),
        };

        let cancel =
            Button::new("flow-cancel", if finished_ok { t!("common-done") } else { t!("common-cancel") })
                .subtle()
                .disabled(
                    locked
                        && !matches!(state.preparation, crate::services::preparation::State::Running { .. }),
                )
                .on_click({
                    let model = model.clone();
                    move |_, window, cx| {
                        if model.read(cx).before_desktop && !model.read(cx).preparation.busy() {
                            window.remove_window();
                            return;
                        }
                        model.update(cx, |m, cx| {
                            if m.preparation.busy() {
                                m.preparation_cancel.store(true, std::sync::atomic::Ordering::Relaxed);
                                cx.notify();
                            } else {
                                m.cancel_flow(cx);
                            }
                        })
                    }
                });
        let back = Button::new("flow-back", t!("common-back"))
            .disabled(step.previous().is_none() || locked || finished_ok)
            .on_click({
                let model = model.clone();
                move |_, _, cx| model.update(cx, |m, cx| m.previous_step(cx))
            });
        let forward = match step {
            Step::Install => Button::new(
                "flow-install",
                match run {
                    RunState::Preparing => t!("button-checking"),
                    RunState::Running => t!("button-installing"),
                    RunState::Finished(outcome) if !outcome.is_success() => t!("common-try-again"),
                    _ => t!("button-install"),
                },
            )
            .accent()
            .icon(Icon::Play)
            .disabled(!state.can_install())
            .on_click({
                let model = model.clone();
                move |_, _, cx| model.update(cx, |m, cx| m.start_install(cx))
            }),
            _ => Button::new("flow-next", t!("common-next"))
                .accent()
                .trailing_icon(Icon::ChevronRight)
                .disabled(!next_enabled || locked)
                .on_click({
                    let model = model.clone();
                    move |_, _, cx| model.update(cx, |m, cx| m.next_step(cx))
                }),
        };

        div()
            .flex()
            .items_center()
            .justify_between()
            .gap(px(12.))
            .child(div().flex().items_center().gap(px(12.)).child(cancel).child(
                div().type_caption().text_color(theme.text_secondary).child(a11y_text("footer-hint", hint)),
            ))
            .child(div().flex().gap(px(8.)).child(back).child(forward))
            .into_any_element()
    }
}

/// Which banner the Windows Security step shows for a reading.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum SecurityBanner {
    /// The first reading has not arrived yet.
    Reading,
    /// All four switches read off.
    AllOff,
    /// At least one switch read off, none read on, and the rest could not be
    /// read: the user checks the rest by hand.
    ReadableOff,
    /// A switch is on, or nothing could be read at all: the general
    /// instruction to turn protection off applies.
    TurnOff,
}

fn security_banner(status: &crate::services::security::SecurityStatus, fresh: bool) -> SecurityBanner {
    let counts = status.counts();
    if !fresh {
        SecurityBanner::Reading
    } else if status.all_off() {
        SecurityBanner::AllOff
    } else if counts.on == 0 && counts.off > 0 {
        SecurityBanner::ReadableOff
    } else {
        SecurityBanner::TurnOff
    }
}

impl Render for InstallPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let (step, run, may_edit, screen) = {
            let state = self.model.read(cx);
            (state.flow.step, state.flow.run, state.flow.may_edit(), state.current_option_screen())
        };
        let step_heading = self.focus.get("step-heading", cx);
        let result_focus = self.focus.get("install-result", cx);

        // A new step starts at the top with focus on its heading; a result
        // is brought into view and announced.
        if self.shown_step != Some((step, screen)) {
            let first = self.shown_step.is_none();
            self.shown_step = Some((step, screen));
            self.scroll.set_offset(Point::default());
            if !first {
                window.focus(&step_heading, cx);
            }
        }
        if self.shown_run != Some(run) {
            let was_finished = matches!(self.shown_run, Some(RunState::Finished(_)));
            self.shown_run = Some(run);
            if matches!(run, RunState::Finished(_) | RunState::Preparing) && !was_finished {
                self.scroll.set_offset(Point::default());
                window.focus(&result_focus, cx);
            }
        }

        let mut body = vec![
            self.stepper(step, may_edit, window, cx),
            focusable_heading(
                "step-heading",
                2,
                t!("step-heading", number = step.index() + 1, total = Step::ALL.len(), title = step.title()),
                &step_heading,
                cx,
            )
            .type_subtitle()
            .pb(px(4.))
            .into_any_element(),
        ];
        body.extend(match step {
            Step::Ready => self.ready_cards(cx),
            Step::Options => self.options_cards(cx),
            Step::Security => self.security_cards(cx),
            Step::Install => self.install_cards(cx),
        });
        let footer = self.footer(cx);
        page_frame(
            "install-scroll",
            Some(t!("install-title").into()),
            (!self.model.read(cx).before_desktop).then_some(&self.model),
            (&self.scroll, &self.scrollbar),
            body,
            Some(footer),
            cx,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::security::SecurityStatus;

    fn status(switches: [Switch; 4]) -> SecurityStatus {
        SecurityStatus {
            tamper_protection: switches[0],
            real_time_protection: switches[1],
            cloud_delivered: switches[2],
            sample_submission: switches[3],
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
        // No switch could be read: "the switches Atlas could check are off"
        // would describe a check that never happened.
        assert_eq!(security_banner(&nothing_readable, true), SecurityBanner::TurnOff);
    }
}
