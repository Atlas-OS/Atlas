//! Step 1, Get ready, as one checklist: the checks of this PC, the Atlas
//! package, and the Windows and Store updates with the driver choice under
//! them. Get ready starts updating and moves on by itself (see
//! `AppModel::advance_ready`), so each row says where it stands and offers an
//! action only when the user has something to do. A move to a newer Windows
//! release has a card of its own, first, which holds the move from the
//! go-ahead to its outcome.

use gpui::{
    AnyElement, App, Context, ElementId, Entity, FocusHandle, Hsla, IntoElement, ParentElement, PromptLevel,
    Role, Styled, Window, div, prelude::*, px,
};

use super::preparation::{RunView, access_notice};
use super::{InstallPage, details_toggle, elevation_problem};

use crate::i18n::{describe, fmt};
use crate::model::{
    AcquireProblem, Acquisition, AppModel, InstallBlock, Page, ReadyHelp, ReleaseCheck, StopQuestion,
};
use crate::pages::{detail_text, driver_radio_items, manager_download_button, on_model};
use crate::services::preparation::{Drivers, State as Preparation};
use crate::services::requirements::{CheckId, CheckResult, Verdict};
use crate::services::windows_release::TransitionNeed;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, COMPACT_INSET, CapCenteredText, CheckBox, Icon, InfoBar, ProgressBar, ProgressRing, RadioGroup,
    RadioItem, Revealed, Severity, TextMark, Typography, a11y_text, card, icon, link_row,
};

/// Where a row of the checklist stands, as its leading mark shows it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(super) enum Mark {
    /// Not started: an empty circle.
    Pending,
    /// Under way: a spinning ring.
    Busy,
    /// Done: a tick.
    Done,
    /// Something to read that needn't stop anything, such as waiting updates.
    Note,
    /// Something for the user to look at or do.
    Warning,
    /// Something went wrong.
    Error,
}

/// One row of Get ready's checklist: its leading mark, a title, one status
/// line, an action at the trailing edge when there is one, and what unfolds
/// under it, which lines up with the title. `focus` lets the page move focus
/// to the row when how it stands is news. A row that is a card of its own,
/// as the move's is, gives its title a `heading` level and is read as a
/// group rather than a list item.
pub(super) struct ChecklistRow {
    pub id: &'static str,
    pub mark: Mark,
    pub title: String,
    pub status: AnyElement,
    /// What the row is read as: its title and how it stands.
    pub name: String,
    /// Read after the name: what the status line and what's under it say.
    pub description: Option<String>,
    pub action: Option<AnyElement>,
    pub below: Vec<AnyElement>,
    pub divided: bool,
    pub focus: Option<FocusHandle>,
    pub heading: Option<usize>,
}

impl ChecklistRow {
    pub fn render(self, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let focus_outer = theme.focus_outer;
        let title = div().type_body_strong().text_color(theme.text_primary);
        let title = match self.heading {
            Some(level) => title
                .id(ElementId::Name(format!("{}-title", self.id).into()))
                .role(Role::Heading)
                .aria_level(level)
                .aria_label(self.title.clone())
                .child(CapCenteredText(self.title.into()))
                .into_any_element(),
            None => title.child(CapCenteredText(self.title.into())).into_any_element(),
        };
        let row = div()
            .id(self.id)
            .role(if self.heading.is_some() { Role::Group } else { Role::ListItem })
            .aria_label(self.name)
            .when_some(self.description, |this, description| this.aria_description(description))
            .flex()
            .flex_col()
            // Room for the focus ring, which news brings here.
            .border_1()
            .border_color(theme.transparent())
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(16.))
                    .px(px(15.))
                    .py(px(11.))
                    .child(TextMark::new(mark(self.mark, cx), true).strong())
                    .child(div().flex().flex_col().flex_1().min_w_0().child(title).child(self.status))
                    .when_some(self.action, |this, action| this.child(div().flex_shrink_0().child(action))),
            )
            .when(!self.below.is_empty(), |this| {
                this.child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(12.))
                        // Under the title: the mark's 20px and the 16px gap past the row's padding.
                        .pl(px(51.))
                        .pr(px(15.))
                        .pb(px(15.))
                        .children(self.below),
                )
            });
        let row = match self.focus {
            // Focus comes here only to announce news, never by Tab.
            Some(handle) => Revealed::new(
                row.track_focus(&handle.tab_stop(false))
                    .rounded(px(7.))
                    .focus_visible(move |style| style.border_color(focus_outer)),
            )
            .into_any_element(),
            None => row.into_any_element(),
        };
        div()
            .flex()
            .flex_col()
            .when(self.divided, |this| this.child(div().h(px(1.)).bg(theme.divider)))
            .child(row)
            .into_any_element()
    }
}

/// A row's leading mark: 20px, coloured by what it says, with words beside
/// it in the row so colour is never the only signal.
fn mark(mark: Mark, cx: &App) -> AnyElement {
    let theme = cx.theme();
    let frame = || div().flex_shrink_0().size(px(20.)).flex().items_center().justify_center();
    let glyph = |glyph: Icon, colour: Hsla| frame().text_color(colour).child(icon(glyph)).into_any_element();
    match mark {
        Mark::Pending => frame()
            .child(div().size(px(14.)).rounded_full().border_1().border_color(theme.control_strong_stroke))
            .into_any_element(),
        Mark::Busy => frame().child(ProgressRing::new()).into_any_element(),
        Mark::Done => glyph(Icon::Completed, theme.success),
        Mark::Note => glyph(Icon::Info, theme.text_secondary),
        Mark::Warning => glyph(Icon::Warning, theme.caution),
        Mark::Error => glyph(Icon::ErrorBadge, theme.critical),
    }
}

/// A row's status line, with an inline link after it, such as Show details.
pub(super) fn status_line(id: &'static str, text: String, link: Option<Button>, cx: &App) -> AnyElement {
    let theme = cx.theme();
    let text = a11y_text(ElementId::Name(format!("{id}-status").into()), text);
    div()
        .flex()
        .flex_wrap()
        .items_center()
        .gap_x(px(6.))
        .type_body()
        .text_color(theme.text_secondary)
        // A long line wraps within the row rather than running past it.
        .child(div().flex_shrink(1.).min_w_0().child(text))
        .when_some(link, |this, link| {
            // The link's own padding stands in for the gap after the dot.
            this.child(div().child("·")).child(div().ml(-COMPACT_INSET).child(link))
        })
        .into_any_element()
}

/// Body text under a row: what happened, or what to do.
pub(super) fn row_text(id: &str, text: String, cx: &App) -> AnyElement {
    div().type_body().text_color(cx.theme().text_primary).child(detail_text(id, text)).into_any_element()
}

/// A note under a row, in Body like every line a row shows by default:
/// why its action waits, what to expect, or what to do before it.
pub(super) fn row_note(id: &str, text: String, cx: &App) -> AnyElement {
    div().type_body().text_color(cx.theme().text_secondary).child(detail_text(id, text)).into_any_element()
}

/// A caption, only for the raw details behind Show details: an error as
/// Windows or the worker wrote it, which is for troubleshooting.
pub(super) fn row_caption(id: &str, text: String, cx: &App) -> AnyElement {
    div().type_caption().text_color(cx.theme().text_secondary).child(detail_text(id, text)).into_any_element()
}

/// Which control on Get ready is its one accent button, most pressing
/// first: creating an Atlas ISO where reinstalling Windows is the only way
/// on, relaunching as administrator, getting the Atlas package again, the
/// fix of the one check that stands in the way, accepting the move's
/// licence terms, or updating's own next step.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Accent {
    /// No installation can start on this Windows: the bar's Create an Atlas ISO.
    IsoBar,
    /// The move this PC needs can't happen here: the first such check's
    /// Create an Atlas ISO.
    IsoCheck(CheckId),
    Elevate,
    Package,
    /// The only check that stands in the way, by its Settings page.
    Fix(CheckId),
    Accept,
    Run,
}

impl Accent {
    fn of(state: &AppModel) -> Self {
        let iso = state.can_navigate(Page::Iso);
        let iso_bar = iso && state.install_block().as_ref().is_some_and(reinstall_is_the_way_on);
        let iso_check = state
            .blocking_results()
            .find(|result| {
                matches!(result.id, CheckId::MoveHardware | CheckId::MoveUpdateSource)
                    && result.verdict == Verdict::Fail
            })
            .map(|result| result.id)
            .filter(|_| iso);
        let blocking: Vec<CheckId> = state.blocking_results().map(|result| result.id).collect();
        let fix = match blocking.as_slice() {
            [only] if only.fix_target().is_some() && !state.locked() => Some(*only),
            _ => None,
        };
        let elevate = state.package.is_some()
            && !state.locked()
            && state.may_relaunch_elevated()
            && state.checks.iter().any(|(id, result)| {
                *id == CheckId::Administrator && result.as_ref().is_some_and(|r| r.verdict == Verdict::Fail)
            });
        // As the package row offers its button (see `package_row`).
        let package = match (&state.acquisition, &state.package) {
            (Acquisition::Failed(_), _) => true,
            (Acquisition::Idle, None) if !state.bundled() => match &state.release {
                ReleaseCheck::Failed => true,
                ReleaseCheck::Ready { .. } => state.offers_download() && !state.latest_predates_app(),
                ReleaseCheck::Checking | ReleaseCheck::NotChecked => false,
            },
            _ => false,
        };
        if iso_bar {
            Self::IsoBar
        } else if let Some(id) = iso_check {
            Self::IsoCheck(id)
        } else if elevate {
            Self::Elevate
        } else if package {
            Self::Package
        } else if let Some(id) = fix {
            Self::Fix(id)
        } else if offers_accept(state) {
            Self::Accept
        } else {
            Self::Run
        }
    }
}

/// Whether only reinstalling Windows gets past `block`: an installed Atlas
/// no package updates, or Atlas's files without a record of a finished
/// install.
fn reinstall_is_the_way_on(block: &InstallBlock) -> bool {
    matches!(block, InstallBlock::Unsupported { .. } | InstallBlock::Unrecorded)
}

/// Whether the move's card asks for its licence terms: the move is chosen,
/// its terms aren't accepted yet, and nothing runs or waits for a restart.
fn asks_for_terms(state: &AppModel) -> bool {
    state.windows_card_shown()
        && state.transition_chosen()
        && !state.windows_terms_accepted
        && matches!(
            state.preparation,
            Preparation::Idle | Preparation::Cancelled | Preparation::Failed | Preparation::Network
        )
}

/// Whether the card offers Accept and update: it asks for the terms, and no
/// check stands in the way, which would keep the update from starting.
fn offers_accept(state: &AppModel) -> bool {
    asks_for_terms(state) && !state.checks_blocking()
}

impl InstallPage {
    pub(super) fn ready_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let drivers = self.driver_row(cx);
        let row_focus = self.focus.get("preparation-status", cx);
        let action_focus = self.focus.get("prepare-action", cx);
        let later_focus = self.focus.get("prepare-not-now", cx);
        let (help, accent, card_shown, card_runs) = {
            let state = self.model.read(cx);
            (
                state.ready_help(),
                Accent::of(state),
                state.windows_card_shown(),
                state.move_shows_preparation(),
            )
        };
        // How updating stands goes on the move's card while Windows moves,
        // and in the update row otherwise; focus follows it there.
        let run = self.run_view(
            help == Some(ReadyHelp::Preparation),
            accent == Accent::Run,
            action_focus,
            later_focus,
            cx,
        );
        let (card_run, row_run) = if card_runs { (Some(run), None) } else { (None, Some(run)) };

        let mut cards = Vec::new();
        cards.extend(self.ready_bar(help, accent == Accent::IsoBar, cx));
        if card_shown {
            let focus = card_runs.then(|| row_focus.clone());
            cards.push(self.windows_card(card_run, focus, accent == Accent::Accept, cx));
        }
        let checks = self.checks_row(help == Some(ReadyHelp::Checks), accent, cx);
        let package = self.package_row(help == Some(ReadyHelp::Package), accent == Accent::Package, cx);
        let updates = self.preparation_row(row_run, drivers, (!card_runs).then_some(row_focus), cx);
        cards.push(
            card(cx)
                .child(
                    div()
                        .id("get-ready")
                        .role(Role::List)
                        .aria_label(t!("step-ready"))
                        .flex()
                        .flex_col()
                        .child(checks)
                        .child(package)
                        .child(updates),
                )
                .into_any_element(),
        );
        cards
    }

    /// The one bar at the top of Get ready, if any: the first that applies
    /// of why no installation can start here and a relaunch that didn't
    /// happen. How the checklist's rows and the move's card stand never gets
    /// a bar as well. `iso_accent` makes Create an Atlas ISO the accent, as
    /// the only way on.
    fn ready_bar(&self, help: Option<ReadyHelp>, iso_accent: bool, cx: &Context<Self>) -> Option<AnyElement> {
        let model = self.model.clone();
        let state = self.model.read(cx);
        if let Some(block) = state.install_block() {
            let mut bar =
                InfoBar::new(Severity::Error, t!("install-source-title"), block.text(state.bundled()))
                    .id("ready-eligibility");
            // Reinstalling Windows is the way on, and an Atlas ISO is where it starts.
            if reinstall_is_the_way_on(&block) && state.can_navigate(Page::Iso) {
                bar = bar.action(
                    Button::new("ready-eligibility-iso", t!("iso-open"))
                        .when(iso_accent, Button::accent)
                        .on_click(on_model(&model, |m, cx| m.navigate_iso_for_this_pc(cx))),
                );
            }
            if help == Some(ReadyHelp::Eligibility) {
                bar = bar.content(self.diagnostics.content(&self.model, cx));
            }
            return Some(bar.into_any_element());
        }
        // An unfinished install carrying on needs no bar here: Your choices
        // says its choices are held, where that matters.
        elevation_problem(state, &model, state.ready_to_continue())
    }

    /// Check your PC. While the checks run, the row says so. Then what
    /// needs attention unfolds under it, most urgent first, with its fix;
    /// what passed, and what updating takes care of, is behind Show details.
    /// `accent` says which of the checks' fixes, if any, is the page's accent.
    fn checks_row(&self, with_help: bool, accent: Accent, cx: &Context<Self>) -> AnyElement {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let title = t!("ready-checks-title");
        if !state.checks_complete() {
            let status = t!("ready-checks-running");
            return ChecklistRow {
                id: "ready-checks",
                mark: Mark::Busy,
                name: t!("check-a11y", title = title.as_str(), state = status.as_str()),
                title,
                status: status_line("ready-checks", status, None, cx),
                description: None,
                action: None,
                below: Vec::new(),
                divided: false,
                focus: None,
                heading: None,
            }
            .render(cx);
        }
        let rows = state.check_rows();
        let handled = |index: &usize| {
            state.checks[*index].1.as_ref().is_some_and(|result| state.handled_by_preparation(result))
        };
        let attention: Vec<usize> = rows.listed.iter().copied().filter(|index| !handled(index)).collect();
        let folded: Vec<usize> =
            rows.listed.iter().copied().filter(handled).chain(rows.passed.iter().copied()).collect();
        let total = rows.listed.len() + rows.passed.len();
        let handled_count = rows.listed.len() - attention.len();
        let status = checks_status(rows.passed.len(), total, handled_count, !attention.is_empty());
        let mark = if state.checks_blocking() {
            Mark::Error
        } else if !attention.is_empty() {
            Mark::Warning
        } else if handled_count > 0 {
            Mark::Note
        } else {
            Mark::Done
        };
        let shown = self.show_passed_checks;
        let toggle = (!folded.is_empty()).then(|| {
            details_toggle(
                "checks-passed-toggle",
                title.clone(),
                shown,
                |page| &mut page.show_passed_checks,
                cx,
            )
        });
        let mut below = Vec::new();
        if !attention.is_empty() {
            below.push(self.check_list("checks-attention", &attention, accent, cx));
        }
        if with_help {
            below.push(self.diagnostics.content(&self.model, cx).into_any_element());
        }
        if shown && !folded.is_empty() {
            below.push(self.check_list("checks-passed", &folded, accent, cx));
        }
        // Choosing it again starts the checks over; it's offered while
        // something needs attention, as fixing it is then what's next.
        let check_again = (!attention.is_empty() && !state.locked()).then(|| {
            Button::new("checks-rerun", t!("ready-check-again"))
                .aria_label(t!(
                    "common-details-a11y",
                    action = t!("ready-check-again"),
                    section = title.as_str()
                ))
                .compact()
                .icon(Icon::Refresh)
                .on_click(on_model(&model, |m, cx| m.run_checks(cx)))
                .into_any_element()
        });
        ChecklistRow {
            id: "ready-checks",
            mark,
            name: t!("check-a11y", title = title.as_str(), state = status.as_str()),
            title,
            status: status_line("ready-checks", status, toggle, cx),
            description: None,
            action: check_again,
            below,
            divided: false,
            focus: None,
            heading: None,
        }
        .render(cx)
    }

    /// The checks at `indexes`, one line each.
    fn check_list(
        &self,
        id: &'static str,
        indexes: &[usize],
        accent: Accent,
        cx: &Context<Self>,
    ) -> AnyElement {
        div()
            .id(id)
            .role(Role::List)
            .aria_label(t!("ready-checks-title"))
            .flex()
            .flex_col()
            .gap(px(12.))
            .children(indexes.iter().map(|&index| self.check_item(index, accent, cx)))
            .into_any_element()
    }

    /// One check: its verdict as a glyph and words, what it found, and the
    /// fix or confirmation it offers. What it found is a text of its own
    /// under the title, so a screen reader reads it with the fix.
    fn check_item(&self, index: usize, accent: Accent, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let may_edit = !state.locked();
        let (id, result) = &state.checks[index];
        let id = *id;
        let handled = result.as_ref().is_some_and(|r| state.handled_by_preparation(r));
        let (glyph, colour, state_word): (Icon, Hsla, String) = match result.as_ref().map(|r| r.verdict) {
            None => (Icon::Unknown, theme.text_secondary, t!("check-state-checking")),
            Some(Verdict::Pass) => (Icon::Completed, theme.success, t!("check-state-passed")),
            // Updating takes care of it: a note, not a failure.
            Some(_) if handled => (Icon::Info, theme.text_secondary, t!("check-state-updates")),
            Some(Verdict::Warn) => (Icon::Warning, theme.caution, t!("check-state-warning")),
            Some(Verdict::Fail) if id.blocking() => {
                (Icon::ErrorBadge, theme.critical, t!("check-state-failed-blocking"))
            }
            Some(Verdict::Fail) => (Icon::Warning, theme.caution, t!("check-state-failed")),
            Some(Verdict::Unknown) if id.blocking() => {
                (Icon::Unknown, theme.critical, t!("check-state-unknown"))
            }
            Some(Verdict::Unknown) => (Icon::Unknown, theme.text_secondary, t!("check-state-unknown")),
        };
        let detail = result
            .as_ref()
            .map(|r| if handled { handled_detail(r) } else { r.detail.text(&state.system) })
            .unwrap_or_else(|| t!("common-checking"));
        let fix = match (result, id.fix_target(), id.fix_label()) {
            (Some(r), Some(target), Some(label)) if offers_fix(r) && !handled => Some(
                Button::new(("fix", index), label)
                    .compact()
                    .when(accent == Accent::Fix(id), Button::accent)
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(target)
                    .into_any_element(),
            ),
            // A move this PC can't make: reinstalling Windows from an Atlas
            // ISO is the way on.
            (Some(r), None, _)
                if matches!(id, CheckId::MoveHardware | CheckId::MoveUpdateSource)
                    && r.verdict == Verdict::Fail
                    && state.can_navigate(Page::Iso) =>
            {
                Some(
                    Button::new(("fix", index), t!("iso-open"))
                        .compact()
                        .when(accent == Accent::IsoCheck(id), Button::accent)
                        .on_click(on_model(&model, |m, cx| m.navigate_iso_for_this_pc(cx)))
                        .into_any_element(),
                )
            }
            (Some(r), None, _) if id == CheckId::Administrator && r.verdict == Verdict::Fail => {
                let enabled = may_edit && state.may_relaunch_elevated();
                // Relaunching waits for the installation files.
                enabled.then(|| {
                    Button::new("fix-elevate", t!("common-restart-as-administrator"))
                        .compact()
                        .icon(Icon::Admin)
                        .when(accent == Accent::Elevate, Button::accent)
                        .on_click(on_model(&model, |m, cx| m.relaunch_elevated(cx)))
                        .into_any_element()
                })
            }
            _ => None,
        };
        let elevate_waits = id == CheckId::Administrator
            && result.as_ref().is_some_and(|r| r.verdict == Verdict::Fail)
            && state.acquisition.is_busy();
        let acknowledgement = result
            .as_ref()
            .and_then(|r| r.acknowledgement().map(|label| (r.id, label)))
            .filter(|_| may_edit)
            .map(|(check, label)| {
                let confirmed = state.acknowledged.contains(&check);
                CheckBox::new(("acknowledge", index), label, confirmed)
                    .on_toggle(on_model(&model, move |m, cx| m.acknowledge_check(check, !confirmed, cx)))
            });
        div()
            .id(("check", index))
            .role(Role::ListItem)
            .aria_label(t!("check-a11y", title = id.title(), state = state_word))
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(
                div()
                    .flex()
                    .items_start()
                    .gap(px(12.))
                    .child(
                        TextMark::new(
                            div()
                                .flex_shrink_0()
                                .size(px(16.))
                                // Centred on the title's 20px line, however
                                // many lines what the check found takes.
                                .mt(px(2.))
                                .flex()
                                .items_center()
                                .justify_center()
                                .text_color(colour)
                                .child(icon(glyph)),
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
                            .child(
                                div()
                                    .type_body()
                                    .text_color(theme.text_secondary)
                                    .child(detail_text(&format!("check-{index}"), detail)),
                            ),
                    )
                    .when_some(fix, |this, fix| this.child(div().flex_shrink_0().self_center().child(fix))),
            )
            // Under the check's title: the glyph's 16px and the 12px gap.
            .when_some(acknowledgement, |this, acknowledgement| {
                this.child(div().pl(px(28.)).child(acknowledgement))
            })
            .when(elevate_waits, |this| {
                this.child(div().pl(px(28.)).child(row_note(
                    "fix-elevate-unavailable",
                    t!("prepare-wait-for-package"),
                    cx,
                )))
            })
            .into_any_element()
    }

    /// The Atlas package: unpacked and ready, on its way, or what stopped
    /// it. Getting it again is offered only after a failure; a file the user
    /// already has can be opened from the row at any time. `accent` makes
    /// the row's button the page's accent.
    fn package_row(&self, with_help: bool, accent: bool, cx: &Context<Self>) -> AnyElement {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let bundled = state.bundled();
        let release = state.release.release().cloned();
        let version = state
            .package
            .as_ref()
            .map(|package| package.manifest.version.clone())
            .or_else(|| release.as_ref().map(|release| release.version().to_owned()))
            .unwrap_or_else(|| state.manifest().version.clone());
        let title = t!("ready-package-title", version = version.as_str());
        let manager_outdated = state.package_needs_newer_manager();
        let mut below = Vec::new();
        let (mark, status) = match (&state.acquisition, &state.package) {
            (Acquisition::Downloading { received, total }, _) => {
                below.push(
                    ProgressBar::new(
                        "package-progress",
                        t!("package-progress"),
                        Some(*received as f32 / (*total).max(1) as f32),
                    )
                    .into_any_element(),
                );
                (Mark::Busy, t!("ready-package-downloading"))
            }
            (Acquisition::Extracting { done, total }, _) => {
                let value = (*total > 0).then(|| *done as f32 / *total as f32);
                below.push(
                    ProgressBar::new("package-progress", t!("package-progress"), value).into_any_element(),
                );
                (Mark::Busy, t!("ready-package-unpacking"))
            }
            (Acquisition::Failed(problem), _) => {
                // What to do in the row; the raw error behind Show details.
                let (text, raw) = match problem {
                    AcquireProblem::Other { error } if bundled => {
                        (t!("ready-package-bundled-failed-detail"), Some(error.clone()))
                    }
                    AcquireProblem::Other { error } => {
                        (t!("ready-package-failed-detail"), Some(error.clone()))
                    }
                    AcquireProblem::ManagerOutdated { required } => {
                        (describe::manager_needed(&version, required.as_deref()), None)
                    }
                    _ => (problem.text(bundled), None),
                };
                below.push(row_text("package-problem", text, cx));
                let retry = if manager_outdated {
                    manager_download_button("source-manager-download")
                } else if bundled {
                    Button::new("source-bundled", t!("common-try-again"))
                        .on_click(on_model(&model, |m, cx| m.load_bundled_package(cx)))
                } else {
                    Button::new("source-download", t!("package-download-again"))
                        .on_click(on_model(&model, |m, cx| m.download_latest(cx)))
                }
                .when(accent, Button::accent);
                // A Windows ISO goes into an Atlas ISO, which reinstalls Windows with Atlas.
                let iso =
                    (*problem == AcquireProblem::WindowsIso && state.can_navigate(Page::Iso)).then(|| {
                        Button::new("source-iso", t!("iso-open"))
                            .on_click(on_model(&model, |m, cx| m.navigate_iso_for_this_pc(cx)))
                    });
                below.push(
                    div()
                        .flex()
                        .flex_wrap()
                        .gap(px(8.))
                        .child(retry)
                        .when_some(iso, |row, iso| row.child(iso))
                        .into_any_element(),
                );
                if let Some(raw) = raw {
                    let shown = self.show_package_details;
                    below.push(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(4.))
                            .child(link_row().child(details_toggle(
                                "package-details",
                                title.clone(),
                                shown,
                                |page| &mut page.show_package_details,
                                cx,
                            )))
                            .when(shown, |this| this.child(row_caption("package-error", raw, cx)))
                            .into_any_element(),
                    );
                }
                if with_help {
                    below.push(self.diagnostics.content(&self.model, cx).into_any_element());
                }
                if manager_outdated {
                    (Mark::Warning, t!("ready-package-manager"))
                } else {
                    (Mark::Error, t!("ready-package-failed"))
                }
            }
            (Acquisition::Idle, Some(_)) => (Mark::Done, t!("ready-package-ready")),
            // A tester build never checks for a release: before its bundled
            // package is unpacked it is preparing, not checking.
            (Acquisition::Idle, None) if bundled => (Mark::Busy, t!("ready-package-bundled")),
            (Acquisition::Idle, None) => match &state.release {
                // A download chosen meanwhile starts when the check ends.
                ReleaseCheck::Checking | ReleaseCheck::NotChecked => {
                    (Mark::Busy, t!("ready-package-checking"))
                }
                ReleaseCheck::Failed => {
                    below.push(row_text("package-problem", t!("ready-package-release-failed-detail"), cx));
                    below.push(
                        div()
                            .flex()
                            .child(
                                Button::new("source-download", t!("package-download-again"))
                                    .when(accent, Button::accent)
                                    .on_click(on_model(&model, |m, cx| m.download_latest(cx))),
                            )
                            .into_any_element(),
                    );
                    (Mark::Error, t!("ready-package-release-failed"))
                }
                // Get ready downloads the latest release by itself; one it
                // can't take, such as one an unfinished install rules out,
                // leaves opening a file, unless downloading is still possible.
                ReleaseCheck::Ready { .. } => {
                    if state.offers_download() && !state.latest_predates_app() {
                        let label = release.as_ref().map_or_else(
                            || t!("package-download-newest"),
                            |r| t!("package-download-version", version = r.version()),
                        );
                        below.push(
                            div()
                                .flex()
                                .child(
                                    Button::new("source-download", label)
                                        .when(accent, Button::accent)
                                        .icon(Icon::Download)
                                        .on_click(on_model(&model, |m, cx| m.download_latest(cx))),
                                )
                                .into_any_element(),
                        );
                    }
                    (Mark::Pending, t!("ready-package-none"))
                }
            },
        };
        // A running download gives way to a chosen file; a tester build
        // offers its bundled package and nothing else.
        let open = (!bundled && state.may_choose_package()).then(|| {
            Button::new("source-local", t!("package-open-file"))
                .hyperlink()
                .compact()
                .on_click(on_model(&model, |m, cx| m.choose_local_package(cx)))
                .into_any_element()
        });
        ChecklistRow {
            id: "ready-package",
            mark,
            name: t!("check-a11y", title = title.as_str(), state = status.as_str()),
            title,
            status: status_line("ready-package", status, None, cx),
            description: None,
            action: open,
            below,
            divided: true,
            focus: None,
            heading: None,
        }
        .render(cx)
    }

    /// The driver choice under the update row: one line that says it, with
    /// Change to unfold today's two answers. An ISO that left the choice
    /// until after sign-in asks it here, unfolded, before updating starts;
    /// an ISO that made it shows it, fixed.
    fn driver_row(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let (staged, required, preference, fixed, has_run) = {
            let state = self.model.read(cx);
            (
                state.staged_driver_preference(),
                state.driver_choice_required(),
                state.driver_preference(),
                state.locked() || state.preparation_choices_fixed(),
                state.preparation != Preparation::Idle,
            )
        };
        let open = required || (self.show_driver_choice && staged.is_none() && !fixed);
        let radios = open.then(|| {
            let model = self.model.clone();
            RadioGroup::new("prepare-drivers", t!("prepare-drivers"))
                .items(driver_radio_items("prepare-drivers", &mut self.focus, cx))
                .selected((!required).then(|| usize::from(preference == Drivers::Manual)))
                .disabled(fixed)
                .on_select(move |index, _, cx| {
                    let drivers = [Drivers::Automatic, Drivers::Manual][index];
                    model.update(cx, |m, cx| m.set_drivers(drivers, cx));
                })
        });
        let theme = cx.theme();
        let mut column = div().id("ready-drivers").flex().flex_col().gap(px(4.));
        if required {
            column = column.child(
                div()
                    .type_body_strong()
                    .text_color(theme.text_primary)
                    .child(a11y_text("ready-drivers-question", t!("prepare-drivers"))),
            );
        } else {
            let choice = match preference {
                Drivers::Automatic => t!("ready-drivers-automatic"),
                Drivers::Manual => t!("ready-drivers-manual"),
            };
            let change = (staged.is_none() && !fixed).then(|| {
                let shown = self.show_driver_choice;
                Button::new("ready-drivers-change", t!("common-change"))
                    .aria_label(t!("ready-drivers-change-a11y"))
                    .expanded(shown)
                    .hyperlink()
                    .compact()
                    .on_click(cx.listener(|this, _, _, cx| {
                        this.show_driver_choice = !this.show_driver_choice;
                        cx.notify();
                    }))
            });
            column = column.child(status_line(
                "ready-drivers",
                t!("ready-drivers-row", choice = choice),
                change,
                cx,
            ));
        }
        if let Some(radios) = radios {
            column = column.child(div().pt(px(4.)).child(radios));
            // Only while the answers show: what changing one does now.
            if has_run && !required {
                column = column.child(row_note("ready-drivers-again", t!("ready-drivers-again"), cx));
            }
        }
        column.into_any_element()
    }

    /// The move to a newer Windows release, first under the stepper: the
    /// choice where moving is optional, what the move keeps, and Microsoft's
    /// licence terms, whose acceptance starts it. Once it runs, how updating
    /// stands (`run`), its waiting and every outcome, with their buttons,
    /// until Windows has the release; and afterwards, that Windows
    /// reinstalled itself, when it did. `focus` is the card's while it shows
    /// how updating stands, and `accent` makes Accept and update the page's
    /// accent.
    fn windows_card(
        &mut self,
        run: Option<RunView>,
        focus: Option<FocusHandle>,
        accent: bool,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let model = self.model.clone();
        let (
            offer,
            release,
            current,
            build,
            version,
            chosen,
            terms,
            pre_run,
            may_keep,
            keep_waits,
            editable,
            rebuilt,
        ) = {
            let state = self.model.read(cx);
            let offer = state.windows_transition();
            let release = offer
                .map(|(transition, _)| transition.target_release.to_owned())
                .or_else(|| state.transition_request().map(|request| request.target_release))
                .unwrap_or_else(|| state.system.display_version.clone());
            let held = state.updates_held();
            (
                offer,
                release,
                state.system.display_version.clone(),
                state.system.build,
                state.manifest().version.clone(),
                state.transition_chosen(),
                state.windows_terms_accepted,
                (state.preparation == Preparation::Idle && !held) || asks_for_terms(state),
                state.may_keep_windows_version(),
                state.keep_waits_for_install(),
                !state.locked() && !state.transition_open(),
                state.rebase_choices().is_some(),
            )
        };
        let optional = offer.is_some_and(|(_, need)| need == TransitionNeed::Optional);
        // The choice, where moving is optional. Keeping this version once the
        // move has begun stops it, which asks first.
        let choice = offer.filter(|_| optional).map(|(transition, _)| {
            let (move_key, keep_key) = ("windows-release-move", "windows-release-keep");
            let items = [
                RadioItem::new(
                    move_key,
                    t!("windows-choice-move-recommended", release = release.as_str()),
                    self.focus.get(move_key, cx),
                )
                .description(t!("windows-choice-move-support", date = fmt::day(transition.end_of_updates()))),
                RadioItem::new(
                    keep_key,
                    t!("windows-choice-keep", current = current.as_str()),
                    self.focus.get(keep_key, cx),
                )
                .description(t!("windows-choice-keep-later", current = current.as_str())),
            ];
            let model = model.clone();
            RadioGroup::new("windows-release", t!("windows-card-question"))
                .items(items)
                .selected(Some(usize::from(!chosen)))
                .disabled(!editable && !may_keep)
                .on_select(move |index, window, cx| {
                    let keep = index == 1;
                    let (asks, chosen) = {
                        let state = model.read(cx);
                        (keep && state.keeping_stops_the_move(), state.transition_chosen())
                    };
                    if asks {
                        ask_to_keep_version(&model, window, cx);
                    } else if keep == chosen {
                        model.update(cx, |m, cx| m.keep_windows_version(keep, cx));
                    }
                })
                .into_any_element()
        });
        let title = t!("windows-card-title", release = release.as_str());
        let mut below: Vec<AnyElement> = choice.into_iter().collect();
        // Why keeping this version isn't a choice now, under it. The setup
        // waiting may be a first install as well as an update, so the words
        // name neither.
        if optional && keep_waits {
            below.push(row_note("windows-keep-waits", t!("update-access-finish-install"), cx));
        }
        let mut trailing = None;
        let mut description = None;
        let (mark, status) = match run {
            // How updating stands, while the move runs or once it ended: its
            // bar or what happened straight under the status line, then the
            // choice.
            Some(view) if !pre_run => {
                below.splice(0..0, view.below);
                trailing = view.trailing;
                description = view.description;
                (view.mark, view.status)
            }
            // The go-ahead: what the move keeps, and the licence terms.
            _ if chosen && !terms => {
                below.push(fact_list(&[t!("windows-fact-files"), t!("windows-fact-time")], cx));
                // 25H2 removed both already; only a PC on 24H2 loses them now.
                if build == 26100 {
                    below.push(self.windows_details(&title, cx));
                }
                if optional {
                    below.push(
                        link_row()
                            .child(
                                Button::new("windows-undo", t!("windows-undo-link"))
                                    .hyperlink()
                                    .compact()
                                    .trailing_icon(Icon::OpenInNewWindow)
                                    .opens(UNDO_DOCS),
                            )
                            .into_any_element(),
                    );
                }
                below.extend(access_notice(self.model.read(cx), &version, cx));
                below.push(terms_line(cx));
                // Hidden while a check stands in the way, which would keep
                // the update from starting: the check's fix comes first.
                if offers_accept(self.model.read(cx)) {
                    let page_focus = focus.clone();
                    below.push(
                        div()
                            .flex()
                            .child(
                                Button::new("windows-accept", t!("windows-accept"))
                                    .when(accent, Button::accent)
                                    .on_click(cx.listener(move |this, _, window, cx| {
                                        this.preparation_asked = true;
                                        this.model.update(cx, |m, cx| m.accept_and_update(cx));
                                        // The button goes with the go-ahead: focus
                                        // follows to how the move stands.
                                        if let Some(focus) = &page_focus {
                                            super::reveal_focus(focus, window, cx);
                                        }
                                    })),
                            )
                            .into_any_element(),
                    );
                }
                let status = if optional {
                    t!("windows-optional")
                } else {
                    t!("windows-required", version = version.as_str(), current = current.as_str())
                };
                (Mark::Pending, status)
            }
            // Accepted, and about to start, or waiting for what holds it.
            _ if chosen => {
                below.extend(access_notice(self.model.read(cx), &version, cx));
                match move_waits_for(self.model.read(cx), &version) {
                    Some(reason) => (Mark::Pending, reason),
                    None => (Mark::Busy, t!("windows-starting")),
                }
            }
            // Windows reinstalled itself on the way; the install puts Atlas back.
            _ if rebuilt => {
                (Mark::Note, t!("windows-rebuilt", release = current.as_str(), version = version.as_str()))
            }
            // This version stays.
            _ => (Mark::Done, t!("windows-optional")),
        };
        let row = ChecklistRow {
            id: "windows-move",
            mark,
            name: t!("check-a11y", title = title.as_str(), state = status.as_str()),
            title,
            status: status_line("windows-move", status, None, cx),
            description,
            action: trailing,
            below,
            divided: false,
            focus,
            heading: Some(3),
        };
        card(cx).child(row.render(cx)).into_any_element()
    }

    /// Show details, with what the move removes from Windows.
    fn windows_details(&self, title: &str, cx: &Context<Self>) -> AnyElement {
        let shown = self.show_windows_details;
        div()
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(link_row().child(details_toggle(
                "windows-details",
                title.to_owned(),
                shown,
                |page| &mut page.show_windows_details,
                cx,
            )))
            .when(shown, |this| this.child(row_text("windows-removes", t!("windows-fact-removes"), cx)))
            .into_any_element()
    }
}

/// What holds a move whose terms are accepted from starting, if anything:
/// the checks, the installation files or what the update row would name.
fn move_waits_for(state: &AppModel, version: &str) -> Option<String> {
    if state.install_block().is_some() {
        Some(t!("ready-updates-blocked"))
    } else if state.driver_choice_required() {
        Some(t!("ready-updates-needs-drivers"))
    } else if !state.blocking_checks_complete() || state.checks_blocking() || !state.elevated {
        Some(t!("windows-starts-after-checks"))
    } else if state.package.is_none() || state.acquisition.is_busy() {
        Some(t!("windows-starts-after-package", version = version))
    } else {
        None
    }
}

/// The line that says updating accepts Microsoft's licence terms, and the
/// link to them.
fn terms_line(cx: &App) -> AnyElement {
    div()
        .flex()
        .flex_wrap()
        .items_center()
        .gap_x(px(4.))
        .type_body()
        .text_color(cx.theme().text_secondary)
        .child(div().flex_shrink(1.).min_w_0().child(detail_text("windows-terms", t!("windows-terms-line"))))
        .child(
            div().ml(-COMPACT_INSET).child(
                Button::new("windows-terms-link", t!("windows-terms-link"))
                    .hyperlink()
                    .compact()
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(WINDOWS_TERMS),
            ),
        )
        .into_any_element()
}

/// Asks before keeping this version once the move has begun: keeping it
/// puts back the Windows Update settings Atlas turned on.
fn ask_to_keep_version(model: &Entity<AppModel>, window: &mut Window, cx: &mut App) {
    let current = model.read(cx).system.display_version.clone();
    let StopQuestion::BeforeMove { current: kept } = model.read(cx).move_stop_question() else {
        return;
    };
    let title = t!("windows-keep-title", current = current.as_str());
    let message = t!("stop-update-before", current = kept);
    let (cancel, keep) = (t!("common-cancel"), t!("prepare-keep-version", current = current.as_str()));
    let answer =
        window.prompt(PromptLevel::Info, &title, Some(&message), &[cancel.as_str(), keep.as_str()], cx);
    let model = model.clone();
    cx.spawn(async move |cx| {
        if answer.await == Ok(1) {
            model.update(cx, |model, cx| model.keep_windows_version_now(cx));
        }
    })
    .detach();
}

/// What a check that updating takes care of says, without the update titles
/// a Windows Update search found: those are for the log.
fn handled_detail(result: &CheckResult) -> String {
    match result.id {
        CheckId::PendingUpdates => t!("check-updates-handled"),
        CheckId::PendingReboot => t!("check-restart-handled"),
        _ => t!("check-handled"),
    }
}

/// Microsoft's licence terms by product, acquisition channel and language.
const WINDOWS_TERMS: &str = "https://www.microsoft.com/useterms";
/// How to undo a move, in the Atlas documentation.
const UNDO_DOCS: &str = "https://atlasos.net/docs/upgrade/windows-release/#undo-the-move";

/// What moving Windows keeps and how long it takes, one plain bullet each.
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
                .type_body()
                .child(div().flex_shrink_0().text_color(theme.text_secondary).child("•"))
                .child(div().flex_1().min_w_0().text_color(theme.text_primary).child(fact.clone()))
        }))
        .into_any_element()
}

/// The checks row's status line, in one format: "9 checks passed", "5 of 9
/// checks passed", and, when updating takes care of every check left, how
/// many after a dot. Those are two messages, so each count has plural forms
/// of its own.
fn checks_status(passed: usize, total: usize, handled: usize, attention: bool) -> String {
    if passed == total {
        t!("ready-checks-passed", count = total)
    } else if !attention {
        [
            t!("ready-checks-passed-some", passed = passed, total = total),
            t!("ready-checks-handled", count = handled),
        ]
        .join(&t!("usb-detail-separator"))
    } else {
        t!("ready-checks-passed-some", passed = passed, total = total)
    }
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

    /// Create an Atlas ISO goes on the bar only where reinstalling Windows is
    /// the way on; a state Atlas can't read or confirm gets the help row.
    #[test]
    fn the_bar_offers_an_atlas_iso_only_where_reinstalling_windows_is_the_way_on() {
        assert!(reinstall_is_the_way_on(&InstallBlock::Unsupported { source: "0.4.0".into(), target: None }));
        assert!(reinstall_is_the_way_on(&InstallBlock::Unrecorded));
        for block in [
            InstallBlock::Unknown,
            InstallBlock::ResumeOther { target: "0.6.1".into(), downloads: "D".into() },
            InstallBlock::RecordUnreadable { error: "denied".into(), record: "R".into() },
        ] {
            assert!(!reinstall_is_the_way_on(&block), "{block:?}");
        }
    }

    #[test]
    fn the_checks_status_counts_what_updating_takes_care_of_on_its_own() {
        crate::i18n::testing::english(|| {
            assert_eq!(checks_status(9, 9, 0, false), "9 checks passed");
            assert_eq!(checks_status(5, 9, 0, true), "5 of 9 checks passed");
            assert_eq!(checks_status(8, 9, 1, false), "8 of 9 checks passed · 1 handled by updating");
        });
    }
}
