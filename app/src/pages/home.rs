//! Home: what is on this PC, whether something newer exists, and the one
//! button that starts the install.

use gpui::{
    AnyElement, App, Context, Div, ElementId, Entity, FocusHandle, IntoElement, ParentElement, Pixels,
    Render, Role, ScrollHandle, Stateful, Styled, Window, div, prelude::*, px, rems, svg,
};

use super::stepper::step_marker;
use super::{
    StepStatus, badge, card_body, card_header, detail_row, detail_text, focusable_heading, heading, on_model,
    options_value, page_frame, recorded_options,
};
use crate::i18n::{describe, fmt};
use crate::model::{AppModel, InstallBlock, Page, ReleaseCheck, RestoreStatus, Step};
use crate::services::releases::Release;
use crate::services::system::links;
use crate::services::update_access::JournalKind;
use crate::services::windows_release::{self, TransitionNeed, WindowsBlock};
use crate::t;
use crate::theme::{ActiveTheme, FONT_TEXT};
use crate::ui::{
    BODY_LINE_HEIGHT, Button, CapCenteredText, Icon, InfoBar, LightState, Markdown, MarkdownBlock,
    ScrollbarState, Severity, StatusLight, Typography, a11y_text, card, dismiss_button, icon_sized,
    parse_markdown,
};

/// Release note blocks shown before "Show full notes".
const PREVIEW_BLOCKS: usize = 8;

/// Install history entries shown, newest first.
const HISTORY_SHOWN: usize = 4;

/// The blocks to draw. A collapsed preview copies only its first few, not the
/// whole release history, on every redraw.
fn visible_notes(blocks: &[MarkdownBlock], expanded: bool) -> Vec<MarkdownBlock> {
    let count = if expanded { blocks.len() } else { blocks.len().min(PREVIEW_BLOCKS) };
    blocks[..count].to_vec()
}

pub struct HomePage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    headline_focus: FocusHandle,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    /// Offered when Atlas can't tell what is installed.
    diagnostics: super::Diagnostics,
    notes_expanded: bool,
    /// The release notes parsed once per release body, not per frame.
    notes: Option<(String, Vec<MarkdownBlock>)>,
    /// The restart-owed bar, so a restart Windows refused, or didn't act on,
    /// is announced where its Restart now is.
    restart_focus: FocusHandle,
    /// The owed restart's failures last announced.
    shown_restart_epoch: u64,
}

impl HomePage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            headline_focus: cx.focus_handle(),
            seen_visit: 0,
            diagnostics: super::Diagnostics::new(cx),
            notes_expanded: false,
            notes: None,
            restart_focus: cx.focus_handle(),
            shown_restart_epoch: 0,
        }
    }

    /// The parsed notes for `body`, reusing the last parse when the text is the same.
    fn notes_for(&mut self, body: &str) -> &[MarkdownBlock] {
        if self.notes.as_ref().is_none_or(|(source, _)| source != body) {
            self.notes = Some((body.to_owned(), parse_markdown(body)));
        }
        self.notes.as_ref().map(|(_, blocks)| blocks.as_slice()).unwrap_or_default()
    }

    /// The version stamp: what is installed, the update status, and the
    /// button that starts, continues or finishes an install.
    fn hero(&self, state: &AppModel, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let model = &self.model;
        let installed = state.installed();
        let installed_version = state.installed_version().map(str::to_owned);
        let update = state.offered_update();
        let block = state.start_block();
        let resume_target = state.resume_target().map(str::to_owned);
        let system_text = describe::system_description(&state.system);
        // Until startup knows whether an install is running elsewhere,
        // nothing that could start one is offered.
        let recovering = state.recovering;

        let headline = match (&installed_version, &block) {
            (Some(version), _) => t!("home-version", version = version),
            // Not a PC to welcome: what is on it can't be told or installed over.
            (None, Some(_)) => t!("home-state-unknown"),
            (None, None) => t!("home-not-installed"),
        };
        let subline = installed
            .and_then(|state| state.installed_at_local())
            .map(|when| t!("home-installed-on", date = fmt::long_date(&when)))
            .unwrap_or_else(|| system_text.clone());

        let bundled = state.bundled();
        // Why nothing can be installed is the bar's to say; the status still
        // says what it knows about updates. Green means only a healthy
        // install that is up to date; a neutral fact is grey.
        let healthy = if block.is_some() { LightState::Unknown } else { LightState::Good };
        let (light, status_text) = if recovering {
            (LightState::Pending, t!("home-status-recovering"))
        } else if let Some(target) = &resume_target {
            (LightState::Caution, t!("home-status-unfinished", version = target))
        } else if let Some(rc_id) = crate::services::embedded::rc_id() {
            (healthy, t!("home-status-bundled", release = rc_id))
        } else {
            match (&state.release, &update, &installed_version) {
                (ReleaseCheck::Checking, _, _) => (LightState::Pending, t!("home-status-checking")),
                (ReleaseCheck::Failed, _, _) => (LightState::Unknown, t!("home-status-offline")),
                (ReleaseCheck::NotChecked, _, _) => (LightState::Unknown, t!("home-status-not-checked")),
                (ReleaseCheck::Ready { .. }, Some(release), _) => {
                    (LightState::Caution, t!("home-status-update", version = release.version()))
                }
                // A newer release this app can't install is named, not
                // reported as up to date.
                (ReleaseCheck::Ready { release, .. }, None, Some(_))
                    if state.update_available().is_some() =>
                {
                    (LightState::Unknown, t!("home-status-newest", version = release.version()))
                }
                (ReleaseCheck::Ready { .. }, None, Some(_)) => (healthy, t!("home-status-up-to-date")),
                (ReleaseCheck::Ready { release, .. }, None, None) => {
                    (LightState::Unknown, t!("home-status-newest", version = release.version()))
                }
            }
        };

        // Check again reads the installation state again too. A tester build
        // has no update check, so it offers that only while the state is in
        // question.
        let check_again = !bundled || block.is_some() || state.atlas.is_err();

        let flow_active = state.flow.active;
        let locked = state.locked();
        // Until Windows has answered the elevation prompt, the flow is
        // neither entered nor begun again.
        let elevating = state.elevating;
        let primary = if flow_active {
            Some(
                Button::new(
                    "home-continue",
                    if locked { t!("home-show-install") } else { t!("home-continue-installing") },
                )
                .accent()
                .trailing_icon(Icon::ChevronRight)
                .disabled(elevating)
                .on_click(on_model(model, |m, cx| m.navigate(Page::Install, cx))),
            )
        } else if block.is_some() || state.owed_restart().is_some() {
            // The bar below explains it and offers what there is to do.
            None
        } else {
            let accent = hero_is_accent(state);
            let (id, label, icon) = match (&resume_target, &update, &installed_version) {
                (Some(target), _, _) => {
                    ("home-finish-install", t!("home-finish-install", version = target), Icon::Download)
                }
                (None, Some(release), _) => {
                    ("home-update", t!("home-update-to", version = release.version()), Icon::Sync)
                }
                (None, None, Some(_)) => ("home-reinstall", t!("home-reinstall"), Icon::Download),
                (None, None, None) => ("home-install", t!("home-install"), Icon::Download),
            };
            Some(
                Button::new(id, label)
                    .when(accent, Button::accent)
                    .icon(icon)
                    .disabled(recovering)
                    .on_click(on_model(model, |m, cx| m.begin_install(cx))),
            )
        };
        let resume = (flow_active && !locked).then(|| {
            Button::new("home-start-over", t!("home-start-over"))
                .hyperlink()
                .compact()
                .disabled(elevating)
                .on_click(on_model(model, |m, cx| m.begin_install(cx)))
        });

        let text = div()
            .flex()
            .flex_col()
            .flex_1()
            .min_w_0()
            .gap(px(4.))
            // The focus border sits outside the headline's box, so the text keeps its place.
            .child(focusable_heading("home-headline", 1, headline, &self.headline_focus, cx).m(px(-1.)).map(
                |this| {
                    if installed_version.is_some() { this.type_title_large() } else { this.type_title() }
                },
            ))
            .child(
                div().type_body().text_color(theme.text_secondary).child(a11y_text("home-subline", subline)),
            )
            .child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap(px(10.))
                    .gap_y(px(4.))
                    .mt(px(6.))
                    .child(StatusLight::new(light, status_text).id("home-update-status"))
                    .when(check_again, |this| {
                        this.child(
                            // A repeat while checking is ignored, so the link
                            // keeps focus rather than leaving the tab order.
                            Button::new("home-check", t!("home-check-again"))
                                .hyperlink()
                                .compact()
                                .centre_label()
                                .on_click(on_model(model, move |m, cx| {
                                    if bundled { m.recheck_installation(cx) } else { m.check_for_updates(cx) }
                                })),
                        )
                    }),
            );

        // The mark and the text keep a minimum width side by side. When large
        // text leaves the button no room beside them, it wraps below.
        div()
            .flex()
            .flex_wrap()
            .items_center()
            .gap_x(px(24.))
            .gap_y(px(16.))
            .pt(px(36.))
            .pb(px(16.))
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(24.))
                    .flex_1()
                    .min_w(rems(14.))
                    .child(
                        div()
                            .flex_shrink_0()
                            .size(px(72.))
                            .flex()
                            .items_center()
                            .justify_center()
                            .child(svg().path("brand/atlas-mark.svg").size(px(64.)).text_color(theme.brand)),
                    )
                    .child(text),
            )
            .when_some(primary, |this, primary| {
                this.child(
                    div()
                        .ml_auto()
                        .flex()
                        .flex_col()
                        .items_end()
                        .gap(px(6.))
                        .flex_shrink_0()
                        .child(primary)
                        .when_some(resume, |this, resume| this.child(resume)),
                )
            })
            .into_any_element()
    }

    /// The bars below the hero: a restart still owed, why no install can
    /// start, a notice, the Windows Security reminder, a failed elevation and
    /// an unreadable state.
    fn notices(&self, state: &AppModel, diagnostics: Option<Div>) -> Vec<AnyElement> {
        let model = &self.model;
        let block = state.start_block();
        let bundled = state.bundled();
        let elevating = state.elevating;
        let mut body = Vec::new();
        if let Some(owed) = state.owed_restart() {
            let message = match (&owed.problem, owed.requested) {
                (Some(problem), _) => problem.text(),
                (None, true) => t!("restart-now-message"),
                (None, false) => t!("restart-needed"),
            };
            body.push(
                InfoBar::new(Severity::Warning, t!("home-restart-title"), message)
                    .id("home-restart")
                    .focus_handle(self.restart_focus.clone())
                    .action(
                        // A second press while Windows has the request is ignored.
                        Button::new("home-restart-now", t!("restart-now"))
                            .accent()
                            .icon(Icon::Power)
                            .on_click(on_model(model, |m, cx| m.restart_owed_now(cx))),
                    )
                    .into_any_element(),
            );
        }
        if let Some(block) = &block {
            let problem = block.text(bundled);
            // One cause, one bar: the state document's own error is its detail.
            let message = match &state.atlas {
                Err(error) => t!("install-source-details", problem = problem, error = error),
                Ok(_) => problem,
            };
            let mut bar =
                InfoBar::new(Severity::Error, t!("install-source-title"), message).id("home-eligibility");
            if let Some(diagnostics) = diagnostics {
                bar = bar.action(div().w_full().child(diagnostics));
            } else if matches!(
                block,
                InstallBlock::Unsupported { .. }
                    | InstallBlock::Windows { block: WindowsBlock::NoPath { .. }, .. }
            ) {
                // Reinstalling Windows is the way on, and an Atlas ISO is where it starts.
                bar = bar.action(
                    Button::new("home-eligibility-iso", t!("iso-open"))
                        .disabled(state.locked() || state.recovering)
                        .on_click(on_model(model, |m, cx| m.navigate_iso_for_this_pc(cx))),
                );
            } else if matches!(
                block,
                InstallBlock::Windows { block: WindowsBlock::Edition, ending: Some(_), .. }
            ) {
                // Windows Update moves this edition on, without Atlas.
                bar = bar.action(
                    Button::new("home-eligibility-windows-update", t!("check-fix-windows-update"))
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(links::WINDOWS_UPDATE),
                );
            }
            body.push(bar.into_any_element());
        }

        if let Some(bar) = end_of_updates_bar(state) {
            body.push(bar.into_any_element());
        }
        if let Some(bar) = self.update_access_bar(state) {
            body.push(bar.into_any_element());
        }
        if let Some(notice) = &state.notice {
            let (model, headline) = (model.clone(), self.headline_focus.clone());
            body.push(
                InfoBar::new(Severity::Warning, notice.title(), notice.message())
                    .id("home-notice")
                    // The bar and its button go; focus goes to the headline.
                    .close_button(dismiss_button("home-notice-dismiss", move |_, window, cx| {
                        model.update(cx, |m, cx| m.dismiss_notice(cx));
                        window.focus(&headline, cx);
                    }))
                    .into_any_element(),
            );
        }
        // The reminder's button is the page's one accent when nothing else on
        // Home is: a restart owed, or the hero's install or update.
        let accent = state.owed_restart().is_none() && !hero_is_accent(state);
        if let Some(reminder) = protection_reminder_bar(model, state, "home", accent, &self.headline_focus) {
            body.push(reminder.into_any_element());
        }
        if let Some(error) = &state.elevation_error {
            body.push(
                InfoBar::new(Severity::Warning, t!("home-elevation-title"), error.text())
                    .id("home-elevation")
                    .action(
                        Button::new("home-elevate", t!("common-try-again"))
                            .icon(Icon::Admin)
                            .disabled(elevating)
                            .on_click(on_model(model, |m, cx| m.begin_install(cx))),
                    )
                    .into_any_element(),
            );
        }
        if let Err(error) = &state.atlas
            && block.is_none()
        {
            // Check again, beside the status above, reads it again.
            body.push(
                InfoBar::new(
                    Severity::Error,
                    t!("home-state-error-title"),
                    t!("home-state-error-message", error = error.as_str()),
                )
                .id("home-state-error")
                .into_any_element(),
            );
        }
        body
    }

    /// Atlas changed Windows Update settings for an update that isn't
    /// finished: continue it, or put the settings back. A record Atlas can't
    /// read is reported, never acted on.
    fn update_access_bar(&self, state: &AppModel) -> Option<InfoBar> {
        let model = &self.model;
        let access = state.update_access.as_ref().filter(|access| access.open() && !state.flow.active)?;
        if access.journal.is_none() {
            return Some(
                InfoBar::new(
                    Severity::Error,
                    t!("home-update-access-title"),
                    t!("home-update-access-unreadable"),
                )
                .id("home-update-access"),
            );
        }
        let journal = access.journal.as_ref()?;
        let release = journal.target.as_ref().map(|target| target.release.clone()).unwrap_or_default();
        let message = match journal.kind {
            JournalKind::Access => t!("home-update-access-plain"),
            _ if journal.installed()
                || journal.target.as_ref().is_some_and(|t| t.build == state.system.build) =>
            {
                t!("home-update-access-after", release = release.as_str())
            }
            _ if state.transition_waiting_for_offer() => {
                t!("home-update-access-not-offered", release = release.as_str())
            }
            _ => t!("home-update-access-before", release = release.as_str()),
        };
        let continue_label = if state.transition_waiting_for_offer() {
            t!("prepare-check-again")
        } else {
            t!("home-continue-update")
        };
        let running = state.restore_status == RestoreStatus::Running;
        // The hero's Update button continues it when an update is on offer.
        // Waiting for an offer, Check again belongs here, beside its message.
        let continue_here = state.offered_update().is_none() || state.transition_waiting_for_offer();
        let actions = div()
            .flex()
            .flex_wrap()
            .gap(px(8.))
            .when(continue_here, |row| {
                row.child(
                    Button::new("home-continue-update", continue_label)
                        .disabled(state.recovering || state.elevating || state.start_block().is_some())
                        .on_click(on_model(model, |m, cx| m.begin_install(cx))),
                )
            })
            .child(
                Button::new(
                    "home-put-back",
                    if running { t!("home-putting-back") } else { t!("home-put-back") },
                )
                .when(!state.elevated, |button| button.icon(Icon::Admin))
                .disabled(!state.may_restore_update_access())
                .on_click(on_model(model, |m, cx| m.restore_update_access(cx))),
            );
        let mut bar = InfoBar::new(Severity::Warning, t!("home-update-access-title"), message)
            .id("home-update-access")
            .action(actions);
        // Why the settings didn't come back, or why they can't yet.
        let problem = match &state.restore_status {
            RestoreStatus::Failed(error) => Some(describe::restore_failure(error)),
            _ if state.resume_target().is_some() || state.rebuilt_windows_awaits_install() => {
                Some(t!("home-update-access-install-active"))
            }
            _ => None,
        };
        if let Some(problem) = problem {
            bar = bar.content(div().type_body().child(a11y_text("home-update-access-problem", problem)));
        }
        Some(bar)
    }

    /// The two parts of an update that also moves Windows, under the hero.
    fn update_plan(&self, state: &AppModel, window: &Window, cx: &App) -> Option<AnyElement> {
        // The update on offer, or, in a tester build, its bundled package
        // when that is newer than what's installed.
        let version = match state.offered_update() {
            Some(release) => release.version().to_owned(),
            None if state.bundled() && state.start_block().is_none() => {
                let bundled = state.manifest().version.clone();
                let installed = state.installed_version()?;
                crate::services::releases::compare_versions(&bundled, installed).is_gt().then_some(bundled)?
            }
            None => return None,
        };
        let (transition, need) = state.windows_transition()?;
        if state.flow.active {
            return None;
        }
        let theme = cx.theme();
        let windows_detail = match need {
            TransitionNeed::Required => t!("home-plan-windows-detail"),
            TransitionNeed::Optional => t!("home-plan-windows-optional"),
        };
        // How long the offer can take, said before anyone waits for it.
        let windows_detail = format!("{windows_detail} {}", t!("transition-offer-expectation"));
        let steps = [
            (t!("home-plan-windows-title", release = transition.target_release), windows_detail),
            (t!("home-plan-atlas-title", version = version.as_str()), t!("home-plan-atlas-detail")),
        ];
        // A move under way shows how far it got.
        let moved = state.system.build == transition.target_build;
        let steps_now = if moved {
            [StepStatus::Done, StepStatus::Current]
        } else {
            [StepStatus::Current, StepStatus::Upcoming]
        };
        let progress = state.transition_open().then_some(steps_now);
        let title_top = step_title_top(window, cx);
        Some(
            card(cx)
                .child(
                    div()
                        .px(px(16.))
                        .pt(px(16.))
                        .type_body()
                        .text_color(theme.text_secondary)
                        .child(a11y_text("home-plan-intro", t!("home-plan-intro"))),
                )
                .child(
                    div()
                        .id("home-plan")
                        .role(Role::List)
                        .aria_label(t!("home-plan-intro"))
                        .aria_size_of_set(2)
                        .child(card_body().children(steps.into_iter().enumerate().map(
                            |(index, (title, detail))| {
                                step_line(index, 2, title, detail, progress.map(|p| p[index]), title_top, cx)
                            },
                        ))),
                )
                .into_any_element(),
        )
    }

    /// "What's new" in the update Home offers.
    fn release_notes_card(&mut self, release: &Release, cx: &Context<Self>) -> AnyElement {
        let theme = cx.theme();
        // Release notes can run to dozens of lines; keep the fold short.
        // They are the project's own text and stay in the language they
        // were written in.
        let expanded = self.notes_expanded;
        let blocks = self.notes_for(&release.body);
        let collapsible = blocks.len() > PREVIEW_BLOCKS;
        let shown = visible_notes(blocks, expanded);
        card(cx)
            .child(card_header(
                cx,
                "whats-new",
                t!("home-whats-new", version = release.version()),
                Some(
                    Button::new("home-release", t!("home-view-release"))
                        .hyperlink()
                        .compact()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(if release.html_url.is_empty() {
                            links::RELEASES.to_owned()
                        } else {
                            release.html_url.clone()
                        })
                        .into_any_element(),
                ),
            ))
            .child(
                card_body()
                    .gap(px(2.))
                    .child(
                        div().type_caption().text_color(theme.text_secondary).pb(px(4.)).child(a11y_text(
                            "home-release-date",
                            fmt::parse_local(&release.published_at)
                                .map(|when| t!("home-released", date = fmt::long_date(&when)))
                                .unwrap_or_default(),
                        )),
                    )
                    // Under the card's level-2 header: a `#` heading is level 3.
                    .child(Markdown::new("home-notes", shown).under_heading(2))
                    .when(collapsible, |this| {
                        this.child(
                            div().flex().pt(px(6.)).child(
                                Button::new(
                                    "home-notes-toggle",
                                    if expanded { t!("home-show-less") } else { t!("home-show-full-notes") },
                                )
                                .hyperlink()
                                .compact()
                                .expanded(expanded)
                                .trailing_icon(if expanded { Icon::ChevronUp } else { Icon::ChevronDown })
                                .on_click(cx.listener(|this, _, _, cx| {
                                    this.notes_expanded = !this.notes_expanded;
                                    cx.notify();
                                })),
                            ),
                        )
                    }),
            )
            .into_any_element()
    }

    /// The entry to the installation media page: a settings card with its
    /// beta label and a standard button, so the hero keeps the one accent.
    fn media_entry(&self, state: &AppModel, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let locked = state.locked();
        let recovering = state.recovering;
        card(cx)
            .child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(16.))
                    .gap_y(px(12.))
                    .px(px(16.))
                    .py(px(14.))
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(16.))
                            .flex_1()
                            .min_w(rems(14.))
                            .child(icon_sized(Icon::Disc, 20.).flex_shrink_0().text_color(theme.text_primary))
                            .child(
                                div()
                                    .flex_1()
                                    .min_w_0()
                                    .flex()
                                    .flex_col()
                                    .gap(px(2.))
                                    .child(
                                        div()
                                            .flex()
                                            .flex_wrap()
                                            .items_center()
                                            .gap(px(8.))
                                            .child(
                                                heading("iso-home-title", 2, t!("iso-home-title"), cx)
                                                    .type_body(),
                                            )
                                            .child(badge("home-iso-beta", t!("iso-beta"), cx)),
                                    )
                                    .child(div().type_caption().text_color(theme.text_secondary).child(
                                        detail_text("iso-home-description", t!("iso-home-description")),
                                    )),
                            ),
                    )
                    .child(
                        div().ml_auto().child(
                            Button::new("home-create-iso", t!("iso-open"))
                                .disabled(locked || recovering)
                                .on_click(on_model(&self.model, |m, cx| m.navigate(Page::Iso, cx))),
                        ),
                    ),
            )
            .into_any_element()
    }
}

impl Render for HomePage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let model = self.model.clone();
        // Coming back from another page, focus starts at the top.
        let visit = self.model.read(cx).page_visit;
        if std::mem::replace(&mut self.seen_visit, visit) != visit {
            window.focus(&self.headline_focus, cx);
        }
        // A restart that didn't take is announced where Restart now is offered again.
        let restart_epoch = self.model.read(cx).owed_restart().map_or(0, |owed| owed.epoch);
        if std::mem::replace(&mut self.shown_restart_epoch, restart_epoch) < restart_epoch {
            window.focus(&self.restart_focus, cx);
            crate::ui::focus_reveal::request(window, cx);
        }
        let diagnostics = matches!(self.model.read(cx).start_block(), Some(InstallBlock::Unknown))
            .then(|| self.diagnostics.content(&model, cx));
        // A Windows Update record Atlas can't read, or settings it couldn't
        // put back, are worth a report; its panel goes right under the bar.
        let access_help = {
            let state = self.model.read(cx);
            diagnostics.is_none()
                && !state.flow.active
                && (state.update_access.as_ref().is_some_and(|access| access.journal_error.is_some())
                    || matches!(state.restore_status, RestoreStatus::Failed(_)))
        };
        let state = self.model.read(cx);
        let mut body: Vec<AnyElement> = vec![self.hero(state, cx)];
        body.extend(self.notices(state, diagnostics));
        if access_help {
            body.push(self.diagnostics.panel(&model, cx).into_any_element());
        }
        body.extend(self.update_plan(state, window, cx));
        if let Some(release) = state.offered_update() {
            body.push(self.release_notes_card(release, cx));
        }
        body.extend(setup_card_view(state, window, cx));
        // Installation media is the secondary path, after the setup card.
        body.push(self.media_entry(state, cx));
        body.push(project_links(&model, state));
        self.diagnostics.settle(&model, window, cx);
        page_frame("home-scroll", None, None, None, (&self.scroll, &self.scrollbar), body, None, cx)
    }
}

/// Windows 11, version 24H2 on Home and Pro stops getting security updates:
/// Home says when, and that the update moves it to a supported version.
fn end_of_updates_bar(state: &AppModel) -> Option<InfoBar> {
    let (transition, _) = state.windows_transition()?;
    let ending = windows_release::end_of_updates(&state.system)?;
    let current = state.system.display_version.as_str();
    let title = if chrono::Local::now().date_naive() > ending {
        t!("home-end-of-updates-past-title", current = current)
    } else {
        t!("home-end-of-updates-title", current = current, date = fmt::day(ending))
    };
    let version =
        state.release.release().map_or_else(|| state.manifest().version.clone(), |r| r.version().to_owned());
    Some(
        InfoBar::new(
            Severity::Warning,
            title,
            t!(
                "home-end-of-updates-message",
                version = version.as_str(),
                release = transition.target_release,
                until = fmt::day(transition.end_of_updates())
            ),
        )
        .id("home-end-of-updates"),
    )
}

/// The card that follows the hero.
#[derive(Debug, PartialEq, Eq)]
enum SetupCard<T> {
    /// The record of a completed install: how, with which options, and when.
    Recorded(T),
    /// Atlas is installed, but there is no record of the install to show.
    Unrecorded,
    /// Nothing is installed yet: how an install goes.
    FirstRun,
    /// What is on this PC can't be told or installed over, so a first-run
    /// guide would mislead.
    Hidden,
}

/// `unreadable` is a state document that couldn't be read: its bar says so,
/// and a card saying there is no record would contradict it.
fn setup_card<T>(record: Option<T>, version_known: bool, blocked: bool, unreadable: bool) -> SetupCard<T> {
    match record {
        Some(record) => SetupCard::Recorded(record),
        None if unreadable || (blocked && !version_known) => SetupCard::Hidden,
        None if version_known => SetupCard::Unrecorded,
        None => SetupCard::FirstRun,
    }
}

/// Where each step of a setup stands, for Home's list: while a setup is
/// unfinished, the steps before `current` are done while they still hold
/// (`satisfied`), and need attention otherwise, as in the stepper, and
/// `current` is under way; otherwise the list is a plain introduction.
fn step_progress(current: Option<Step>, satisfied: impl Fn(Step) -> bool) -> [Option<StepStatus>; 4] {
    Step::ALL.map(|step| {
        current.map(|current| StepStatus::visited(step.index(), current.index(), satisfied(step)))
    })
}

/// Whether the hero's button is the page's accent: continuing a setup, or
/// installing, finishing or updating where nothing stands in the way.
fn hero_is_accent(state: &AppModel) -> bool {
    state.flow.active
        || (state.start_block().is_none()
            && state.owed_restart().is_none()
            && (state.resume_target().is_some()
                || state.offered_update().is_some()
                || state.installed_version().is_none()))
}

/// The [`SetupCard`] for this PC: the record of its install, or how an
/// install goes.
fn setup_card_view(state: &AppModel, window: &Window, cx: &App) -> Option<AnyElement> {
    let theme = cx.theme();
    let system_text = describe::system_description(&state.system);
    match setup_card(
        state.installed(),
        state.installed_version().is_some(),
        state.start_block().is_some(),
        state.atlas.is_err(),
    ) {
        SetupCard::Recorded(installed) => {
            let options = recorded_options(state, &installed.options);
            let history: Vec<String> = installed
                .history
                .iter()
                .rev()
                .take(HISTORY_SHOWN)
                .map(|entry| {
                    let when =
                        entry.completed_at_local().map(|when| fmt::date_time(&when)).unwrap_or_default();
                    t!(
                        "home-history-entry",
                        version = entry.version.clone().unwrap_or_else(|| "?".into()),
                        mode = entry.install_mode().history_label(),
                        date = when
                    )
                })
                .collect();
            let mode = installed.install_mode().label();
            Some(
                card(cx)
                    .child(card_header(cx, "your-install", t!("home-your-install"), None))
                    .child(
                        card_body()
                            .child(detail_row(
                                cx,
                                "mode",
                                t!("common-installed-as"),
                                detail_text("mode", mode),
                            ))
                            .child(detail_row(
                                cx,
                                "windows",
                                t!("common-windows"),
                                detail_text("windows", system_text.clone()),
                            ))
                            .child(detail_row(
                                cx,
                                "options",
                                t!("common-options"),
                                options_value(cx, "options", "home-options", options),
                            ))
                            .when(installed.is_oobe, |this| {
                                this.child(detail_row(
                                    cx,
                                    "set-up",
                                    t!("home-set-up"),
                                    detail_text("set-up", t!("home-set-up-during-oobe")),
                                ))
                            })
                            // A single entry is this install, already described above.
                            .when(history.len() > 1, |this| {
                                this.child(detail_row(
                                    cx,
                                    "history",
                                    t!("home-history"),
                                    div()
                                        .id("home-history")
                                        .role(Role::List)
                                        .aria_label(t!("home-history"))
                                        .flex()
                                        .flex_col()
                                        .children(history.into_iter().enumerate().map(|(index, line)| {
                                            div()
                                                .id(("history", index))
                                                .role(Role::ListItem)
                                                .aria_label(line.clone())
                                                .type_caption()
                                                .text_color(theme.text_secondary)
                                                .child(line)
                                        })),
                                ))
                            }),
                    )
                    .into_any_element(),
            )
        }
        SetupCard::Unrecorded => Some(
            card(cx)
                .child(card_header(cx, "your-install", t!("home-your-install"), None))
                .child(
                    card_body().child(
                        div()
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-install-unrecorded", t!("home-install-unrecorded"))),
                    ),
                )
                .into_any_element(),
        ),
        SetupCard::Hidden => None,
        SetupCard::FirstRun => {
            let minutes = state.manifest().estimated_minutes;
            let details = [
                if state.bundled() { t!("home-step-1-detail-bundled") } else { t!("home-step-1-detail") },
                t!("home-step-2-detail"),
                t!("home-step-3-detail"),
                t!("home-step-4-detail", minutes = minutes),
            ];
            // An unfinished setup shows how far it got; Continue setup, above, goes on from there.
            let progress = step_progress(state.flow.active.then_some(state.flow.step), |step| {
                state.step_satisfied(step)
            });
            let count = Step::ALL.len();
            let title_top = step_title_top(window, cx);
            Some(
                card(cx)
                    .child(card_header(cx, "how-it-works", t!("home-how-it-works"), None))
                    .child(
                        div()
                            .px(px(16.))
                            .pt(px(16.))
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-intro", t!("home-intro"))),
                    )
                    .child(
                        div()
                            .id("home-steps")
                            .role(Role::List)
                            .aria_label(t!("home-how-it-works"))
                            .aria_size_of_set(count)
                            .child(card_body().children(
                                Step::ALL.into_iter().zip(details).zip(progress).map(
                                    |((step, detail), status)| {
                                        step_line(
                                            step.index(),
                                            count,
                                            step.title(),
                                            detail,
                                            status,
                                            title_top,
                                            cx,
                                        )
                                    },
                                ),
                            )),
                    )
                    .into_any_element(),
            )
        }
    }
}

/// The offset that lines a step's number up with the top of its title's capitals.
fn step_title_top(window: &Window, cx: &App) -> Pixels {
    let mut title_font = gpui::font(FONT_TEXT);
    title_font.weight = gpui::FontWeight::SEMIBOLD;
    let font_id = cx.text_system().resolve_font(&title_font);
    let cap_height = cx.text_system().cap_height(font_id, gpui::rems(14. / 16.).to_pixels(window.rem_size()));
    (BODY_LINE_HEIGHT.to_pixels(window.rem_size()) - cap_height) / 2.
}

/// A numbered line: the install really is a sequence, so the numbers carry
/// meaning. With a `status`, the marker shows it as the install steps' own
/// stepper does: a check when done, the accent behind the current number,
/// and "!" on the caution colour for a step that needs attention again.
fn step_line(
    index: usize,
    count: usize,
    title: String,
    detail: String,
    status: Option<StepStatus>,
    title_top: Pixels,
    cx: &App,
) -> Stateful<Div> {
    let theme = cx.theme();
    let number = index + 1;
    let name = match status {
        Some(status) => super::stepper::step_name(index, count, &title, status),
        None => t!("home-step-a11y", number = number, title = title.as_str()),
    };
    let marker = step_marker(number, status, cx).flex_shrink_0().mt(title_top);
    div()
        .id(("home-step", number))
        .role(Role::ListItem)
        .aria_label(name)
        .aria_description(detail.clone())
        // AccessKit counts from 0 and takes the size from the list.
        .aria_position_in_set(index)
        .flex()
        .items_start()
        .gap(px(12.))
        .py(px(4.))
        .child(marker)
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
                        .child(CapCenteredText(title.into())),
                )
                .child(div().type_caption().text_color(theme.text_secondary).child(detail)),
        )
}

/// Where to read more, follow the project, ask for help or report a problem.
/// A problem is reported privately, in the app; the rest open the browser.
fn project_links(model: &Entity<AppModel>, state: &AppModel) -> AnyElement {
    div()
        .flex()
        .flex_wrap()
        .gap(px(4.))
        .child(
            Button::new("home-docs", t!("common-read-the-docs"))
                .hyperlink()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::DOCS),
        )
        .child(
            Button::new("home-github", t!("home-github"))
                .hyperlink()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::GITHUB),
        )
        .child(
            Button::new("home-discord", t!("home-discord"))
                .hyperlink()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::DISCORD),
        )
        .child(
            Button::new("home-report", t!("home-report-problem"))
                .hyperlink()
                .disabled(!state.can_navigate(Page::Report))
                .on_click(on_model(model, |m, cx| m.navigate(Page::Report, cx))),
        )
        .into_any_element()
}

/// The Windows Security reminder, for Home and the "Atlas is installed"
/// window: the switches still off, or that Microsoft Defender is missing
/// though the install kept it, with what to do and a close button. `key`
/// prefixes its element ids; `accent` makes Open Windows Security the page's
/// accent; focus goes to `return_focus` once Dismiss has taken the bar away.
pub(super) fn protection_reminder_bar(
    model: &Entity<AppModel>,
    state: &AppModel,
    key: &str,
    accent: bool,
    return_focus: &FocusHandle,
) -> Option<InfoBar> {
    let reminder = state.protection_reminder()?;
    let id = |name: &str| ElementId::Name(format!("{key}-{name}").into());
    let (dismiss_model, back) = (model.clone(), return_focus.clone());
    let dismiss = dismiss_button(id("security-dismiss"), move |_, window, cx| {
        dismiss_model.update(cx, |m, cx| m.dismiss_security_reminder(cx));
        // A reminder for an earlier install can still show; then focus stays.
        if dismiss_model.read(cx).protection_reminder().is_none() {
            window.focus(&back, cx);
        }
    });
    let bar = if reminder.missing {
        // No antivirus where the user chose to keep one: Atlas may have
        // failed to bring Defender back, so it offers a report. Only those
        // who didn't remove it themselves need one, so it's never the accent.
        InfoBar::new(
            Severity::Warning,
            t!("security-banner-absent-title"),
            t!("installed-defender-missing-message"),
        )
        .action(
            Button::new(id("defender-missing-report"), t!("home-report-problem"))
                .disabled(!state.can_navigate(Page::Report))
                .on_click(on_model(model, |m, cx| m.navigate(Page::Report, cx))),
        )
    } else {
        // A switch that couldn't be read isn't known to be off.
        let (severity, title) = if reminder.unreadable {
            (Severity::Informational, t!("home-security-reminder-unreadable-title"))
        } else {
            (Severity::Warning, t!("home-security-reminder-title"))
        };
        InfoBar::new(severity, title, reminder.message()).action(
            Button::new(id("security-open"), t!("common-open-windows-security"))
                .icon(Icon::Shield)
                .when(accent, Button::accent)
                .opens(links::WINDOWS_SECURITY_PROTECTION),
        )
    };
    Some(bar.id(id("security-reminder")).close_button(dismiss))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collapsed_release_notes_show_at_most_the_preview_and_short_notes_whole() {
        let blocks = parse_markdown(&"a\n\n".repeat(10));
        assert!(blocks.len() > PREVIEW_BLOCKS);
        assert_eq!(visible_notes(&blocks, false).len(), PREVIEW_BLOCKS);
        assert_eq!(visible_notes(&blocks, true).len(), blocks.len());
        // A note shorter than the preview is shown whole, not sliced past its end.
        assert_eq!(visible_notes(&blocks[..2], false).len(), 2);
    }

    #[test]
    fn the_first_run_guide_shows_only_on_a_pc_without_atlas() {
        assert_eq!(setup_card(Some(()), true, false, false), SetupCard::Recorded(()));
        assert_eq!(setup_card(None::<()>, true, false, false), SetupCard::Unrecorded);
        assert_eq!(setup_card(None::<()>, true, true, false), SetupCard::Unrecorded);
        assert_eq!(setup_card(None::<()>, false, true, false), SetupCard::Hidden);
        assert_eq!(setup_card(None::<()>, false, false, false), SetupCard::FirstRun);
    }

    #[test]
    fn an_unreadable_state_document_hides_the_card_its_bar_would_contradict() {
        // Neither "no record of how Atlas was installed" nor a first-run guide.
        assert_eq!(setup_card(None::<()>, true, false, true), SetupCard::Hidden);
        assert_eq!(setup_card(None::<()>, false, false, true), SetupCard::Hidden);
    }

    #[test]
    fn the_step_list_marks_progress_only_while_a_setup_is_unfinished() {
        use StepStatus::{Attention, Current, Done, Upcoming};
        let all = |_| true;
        assert_eq!(step_progress(None, all), [None; 4], "a fresh PC keeps the plain list");
        assert_eq!(
            step_progress(Some(Step::Ready), all),
            [Some(Current), Some(Upcoming), Some(Upcoming), Some(Upcoming)]
        );
        assert_eq!(
            step_progress(Some(Step::Security), all),
            [Some(Done), Some(Done), Some(Current), Some(Upcoming)]
        );
        assert_eq!(
            step_progress(Some(Step::Install), all),
            [Some(Done), Some(Done), Some(Done), Some(Current)]
        );
        // Get ready no longer holds (reopened without permission): it needs
        // attention, as the stepper says, not done.
        assert_eq!(
            step_progress(Some(Step::Security), |step| step != Step::Ready),
            [Some(Attention), Some(Done), Some(Current), Some(Upcoming)]
        );
    }
}
