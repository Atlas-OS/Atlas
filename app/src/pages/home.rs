//! Home: what is on this PC, whether something newer exists, and the one
//! button that takes it on: install, continue, update or reinstall.
//!
//! Home shows at most one bar, the most urgent that applies (see
//! [`HomeBar`]), and at most one accent button: the hero's, except where the
//! way on is reinstalling Windows, when the card that creates an Atlas ISO
//! comes first and takes it, and where the bar carries the way on, as Restart
//! now does while a restart is owed. Where nothing calls for a step, as on an
//! Atlas that is up to date, no button is the accent.

use gpui::{
    AnyElement, App, Context, Div, ElementId, Entity, FocusHandle, IntoElement, ParentElement, Pixels,
    PromptLevel, Render, Role, ScrollHandle, Stateful, Styled, Window, div, prelude::*, px, relative, rems,
    svg,
};

use super::install::details_toggle;
use super::stepper::step_marker;
use super::{
    ListEntry, StepStatus, badge, card_body, card_header, card_title, detail_row, detail_text,
    focusable_heading, heading, manager_download_button, manager_update_bar, on_model, page_frame,
    plain_list,
};
use crate::i18n::{describe, fmt};
use crate::model::{
    AcquireProblem, Acquisition, AppModel, ElevationProblem, InstallBlock, Page, ReleaseCheck,
    RestartProblem, RestoreStatus, Step,
};
use crate::services::atlas_state::AtlasState;
use crate::services::package::{ChoiceOption, Manifest};
use crate::services::releases::Release;
use crate::services::system::links;
use crate::services::update_access::JournalKind;
use crate::services::windows_release::{self, Transition, TransitionNeed, WindowsBlock};
use crate::t;
use crate::theme::{ActiveTheme, FONT_TEXT};
use crate::ui::{
    BODY_LINE_HEIGHT, Button, CapCenteredText, Icon, InfoBar, LightState, Markdown, MarkdownBlock,
    ScrollbarState, Severity, StatusLight, Typography, a11y_text, body_cap_center_offset, card,
    dismiss_button, icon_in_line_sized, link_row, parse_markdown,
};

/// Release note blocks shown before "Show full notes".
const PREVIEW_BLOCKS: usize = 8;

/// Install history entries shown, newest first.
const HISTORY_SHOWN: usize = 4;

/// The width, in rems, of the install steps' titles, so their sentences
/// start in one column.
const STEP_TITLE_WIDTH: f32 = 9.;

/// The blocks to draw. A collapsed preview copies only its first few, not the
/// whole release history, on every redraw.
fn visible_notes(blocks: &[MarkdownBlock], expanded: bool) -> Vec<MarkdownBlock> {
    let count = if expanded { blocks.len() } else { blocks.len().min(PREVIEW_BLOCKS) };
    blocks[..count].to_vec()
}

/// The notes without a heading at their top that only names the release,
/// which the card's own header already does.
fn without_version_heading<'a>(blocks: &'a [MarkdownBlock], version: &str) -> &'a [MarkdownBlock] {
    let space = |block: &MarkdownBlock| matches!(block, MarkdownBlock::Space);
    let start = blocks.iter().take_while(|block| space(block)).count();
    match blocks.get(start) {
        Some(MarkdownBlock::Heading(_, text)) if names_only_the_release(&text.text, version) => {
            let rest = &blocks[start + 1..];
            &rest[rest.iter().take_while(|block| space(block)).count()..]
        }
        _ => &blocks[start..],
    }
}

/// Whether `heading` says nothing but which release this is, such as
/// "Atlas 0.6.0" or "AtlasOS v0.6.0".
fn names_only_the_release(heading: &str, version: &str) -> bool {
    if !heading.contains(version) {
        return false;
    }
    let rest = heading.replace(version, " ").replace("AtlasOS", " ").replace("Atlas", " ");
    rest.split(|c: char| !c.is_alphanumeric()).all(|word| word.is_empty() || word.eq_ignore_ascii_case("v"))
}

/// The bars Home can show. Only the first that applies, in
/// [`HomeBar::PRIORITY`] order, shows: a restart owed, then protection,
/// then an update under way, then the end of support, then the rest.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum HomeBar {
    /// A finished install still owes its restart.
    Restart,
    /// Windows Security protection still off, or Microsoft Defender missing.
    Protection,
    /// Microsoft Defender still removed though the record kept it.
    DefenderNotRestored,
    /// Windows Update settings Atlas changed for an update that isn't finished.
    UpdateAccess,
    /// This Windows version stops getting security updates.
    EndOfSupport,
    /// Why no install can start from Home.
    Unavailable,
    /// The package needs a newer Atlas Manager.
    ManagerNeeded,
    /// A relaunch as administrator that didn't happen.
    Elevation,
    /// The installation state couldn't be read.
    StateError,
    /// A problem with the app's own files.
    Notice,
    /// A newer Atlas Manager has been released.
    ManagerUpdate,
}

impl HomeBar {
    const PRIORITY: [HomeBar; 11] = [
        HomeBar::Restart,
        HomeBar::Protection,
        HomeBar::DefenderNotRestored,
        HomeBar::UpdateAccess,
        HomeBar::EndOfSupport,
        HomeBar::Unavailable,
        HomeBar::ManagerNeeded,
        HomeBar::Elevation,
        HomeBar::StateError,
        HomeBar::Notice,
        HomeBar::ManagerUpdate,
    ];
}

/// The most urgent bar of those that apply.
fn first_bar(applies: impl Fn(HomeBar) -> bool) -> Option<HomeBar> {
    HomeBar::PRIORITY.into_iter().find(|bar| applies(*bar))
}

/// The bar Home shows for `state`, if any.
fn home_bar(state: &AppModel) -> Option<HomeBar> {
    first_bar(|bar| match bar {
        HomeBar::Restart => state.owed_restart().is_some(),
        HomeBar::Protection => state.protection_reminder().is_some(),
        HomeBar::DefenderNotRestored => state.defender_not_restored_shown(),
        HomeBar::UpdateAccess => {
            !state.flow.active && state.update_access.as_ref().is_some_and(|access| access.open())
        }
        HomeBar::EndOfSupport => end_of_support(state).is_some(),
        HomeBar::Unavailable => state.start_block().is_some(),
        HomeBar::ManagerNeeded => !state.flow.active && state.package_needs_newer_manager(),
        HomeBar::Elevation => state.elevation_error.is_some(),
        HomeBar::StateError => state.atlas.is_err() && state.start_block().is_none(),
        HomeBar::Notice => state.notice.is_some(),
        HomeBar::ManagerUpdate => state.manager_update().is_some(),
    })
}

/// What the hero's button does: the next step on this PC.
#[derive(Clone, Debug, PartialEq, Eq)]
enum HeroAction {
    /// Back to the setup under way, or to the install it runs.
    Continue,
    /// Install Atlas on a PC without it.
    Install,
    /// Finish the unfinished install of this version.
    Finish(String),
    /// Continue the update Atlas changed Windows Update settings for.
    ContinueUpdate,
    /// Update to this release.
    Update(String),
    /// Download the newer Atlas Manager the package needs.
    DownloadManager,
    /// Install the installed version again.
    Reinstall,
}

/// The hero's button, if it has one. A restart owed has its own Restart now,
/// and where no install can start the bar says why and what to do instead.
fn hero_action(state: &AppModel) -> Option<HeroAction> {
    if state.flow.active {
        return Some(HeroAction::Continue);
    }
    if state.owed_restart().is_some() || state.start_block().is_some() {
        return None;
    }
    if state.package_needs_newer_manager() {
        return Some(HeroAction::DownloadManager);
    }
    if let Some(target) = state.resume_target() {
        return Some(HeroAction::Finish(target.to_owned()));
    }
    if state.update_access.as_ref().is_some_and(|access| access.journal.is_some()) {
        return Some(HeroAction::ContinueUpdate);
    }
    if let Some(release) = state.offered_update() {
        return Some(HeroAction::Update(release.version().to_owned()));
    }
    Some(if state.installed_version().is_some() { HeroAction::Reinstall } else { HeroAction::Install })
}

/// Whether the hero's button is the page's accent: it is the next step,
/// except Install on Windows that looks used, where reinstalling Windows is
/// recommended, and Reinstall on an Atlas that is up to date, which nothing
/// asks for. Without it, a bar's action can be the accent.
fn hero_accent(action: &HeroAction, used_windows: bool) -> bool {
    match action {
        HeroAction::Install => !used_windows,
        HeroAction::Reinstall => false,
        _ => true,
    }
}

/// Whether the card that creates an Atlas ISO comes first, recommended: on
/// Windows that looks used, before a setup starts, and where the only way
/// to the package is reinstalling Windows.
fn media_recommended(state: &AppModel) -> bool {
    let used = state.windows_looks_used()
        && !state.flow.active
        && state.resume_target().is_none()
        && state.owed_restart().is_none();
    used || media_is_the_way_on(state.start_block().as_ref())
}

/// A block that only reinstalling Windows gets past, which starts with an
/// Atlas ISO.
fn media_is_the_way_on(block: Option<&InstallBlock>) -> bool {
    matches!(
        block,
        Some(
            InstallBlock::Unsupported { .. }
                | InstallBlock::Windows { block: WindowsBlock::NoPath { .. }, .. }
        )
    )
}

/// A PC without Atlas, and without anything that keeps Home from installing
/// it or from knowing what is installed.
fn first_install(state: &AppModel) -> bool {
    state.installed_version().is_none()
        && state.resume_target().is_none()
        && state.start_block().is_none()
        && state.atlas.is_ok()
}

/// Starts the install flow from Home. On Windows that looks used it starts
/// only once the user has accepted the risk.
fn start_install(model: &Entity<AppModel>, window: &mut Window, cx: &mut App) {
    if model.read(cx).windows_looks_used() {
        ask_about_used_windows(model, window, cx);
    } else {
        model.update(cx, |m, cx| m.begin_install(cx));
    }
}

/// Installing over Windows in use can break what the user has: the question
/// names the risk, and Cancel is the safe answer, which Escape chooses.
fn ask_about_used_windows(model: &Entity<AppModel>, window: &mut Window, cx: &mut App) {
    if window.has_active_prompt() {
        return;
    }
    let (title, message) = (t!("home-used-windows-title"), t!("home-used-windows-message"));
    let answers = [
        crate::ui::content_dialog::safe_answer(t!("common-cancel")),
        crate::ui::content_dialog::answer(t!("home-used-windows-install")),
    ];
    let answer = window.prompt(PromptLevel::Warning, &title, Some(&message), &answers, cx);
    let model = model.clone();
    cx.spawn(async move |cx| {
        if answer.await == Ok(1) {
            model.update(cx, |m, cx| m.begin_install_on_used_windows(cx));
        }
    })
    .detach();
}

pub struct HomePage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    headline_focus: FocusHandle,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    /// The help row, under the bar of an unexpected failure.
    diagnostics: super::Diagnostics,
    notes_expanded: bool,
    /// The release notes parsed once per release body, not per frame.
    notes: Option<(String, Vec<MarkdownBlock>)>,
    /// The restart-owed bar, so a restart Windows refused, or didn't act on,
    /// is announced where its button is.
    restart_focus: FocusHandle,
    /// The owed restart's failures last announced.
    shown_restart_epoch: u64,
    /// The bar last drawn, and whether its raw details are shown: another
    /// bar starts with them folded.
    shown_bar: Option<HomeBar>,
    bar_details: bool,
    /// A review preview opens with the question Install Atlas asks on
    /// Windows that looks used.
    ask_on_open: bool,
}

impl HomePage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        let ask_on_open = cfg!(debug_assertions)
            && std::env::var("ATLAS_PREPARATION_PREVIEW").is_ok_and(|state| state == "home-used-question");
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
            shown_bar: None,
            bar_details: false,
            ask_on_open,
        }
    }

    /// The parsed notes for `body`, reusing the last parse when the text is the same.
    fn notes_for(&mut self, body: &str) -> &[MarkdownBlock] {
        if self.notes.as_ref().is_none_or(|(source, _)| source != body) {
            self.notes = Some((body.to_owned(), parse_markdown(body)));
        }
        self.notes.as_ref().map(|(_, blocks)| blocks.as_slice()).unwrap_or_default()
    }

    /// The version stamp: what is installed and whether something newer is,
    /// with the button for the next step.
    fn hero(
        &self,
        state: &AppModel,
        action: Option<HeroAction>,
        accent: bool,
        cx: &Context<Self>,
    ) -> AnyElement {
        let theme = cx.theme();
        let model = &self.model;
        let installed_version = state.installed_version().map(str::to_owned);
        let block = state.start_block();
        let recovering = state.recovering;

        let headline = match (&installed_version, &block) {
            (Some(version), _) => t!("home-version", version = version),
            // Not a PC to welcome: what is on it can't be told or installed over.
            (None, Some(_)) => t!("home-state-unknown"),
            (None, None) => t!("home-not-installed"),
        };
        // Installed: when, on the status line. Otherwise this PC's Windows,
        // above it.
        let installed_on = installed_version.as_ref().and_then(|_| {
            let when = state.installed()?.installed_at_local()?;
            Some(t!("home-installed-on", date = fmt::long_date(&when)))
        });

        let bundled = state.bundled();
        // Why nothing can be installed, or what can't be read, is the bar's
        // to say; the status still says what it knows about updates. Green
        // means only a healthy install that is up to date; a neutral fact is
        // grey.
        let healthy =
            if block.is_some() || state.atlas.is_err() { LightState::Unknown } else { LightState::Good };
        let update = state.offered_update();
        // On a PC without Atlas, the release the check found goes beside
        // Windows, as what installing brings. The status stays for what is
        // still to know, such as a check under way or one that failed.
        let mut latest = None;
        let status = if recovering {
            Some((LightState::Pending, t!("home-status-recovering")))
        } else if let Some(target) = state.resume_target() {
            Some((LightState::Caution, t!("home-status-unfinished", version = target)))
        } else if let Some(rc_id) = crate::services::embedded::rc_id() {
            Some((healthy, t!("home-status-bundled", release = rc_id)))
        } else {
            match (&state.release, &update, &installed_version) {
                (ReleaseCheck::Checking, _, _) => Some((LightState::Pending, t!("home-status-checking"))),
                (ReleaseCheck::Failed, _, _) => Some((LightState::Unknown, t!("home-status-offline"))),
                (ReleaseCheck::NotChecked, _, _) => {
                    Some((LightState::Unknown, t!("home-status-not-checked")))
                }
                (ReleaseCheck::Ready { .. }, Some(release), _) => {
                    Some((LightState::Caution, t!("home-status-update", version = release.version())))
                }
                // A newer release this app can't install is named, not
                // reported as up to date.
                (ReleaseCheck::Ready { release, .. }, None, Some(_))
                    if state.update_available().is_some() =>
                {
                    Some((LightState::Unknown, t!("home-status-newest", version = release.version())))
                }
                // Up to date says nothing while the installation can't be
                // read: the version it vouches for may not be what's there.
                (ReleaseCheck::Ready { .. }, None, Some(_)) if state.atlas.is_err() => None,
                (ReleaseCheck::Ready { .. }, None, Some(_)) => Some((healthy, t!("home-status-up-to-date"))),
                (ReleaseCheck::Ready { release, .. }, None, None) => {
                    latest = Some(release.version().to_owned());
                    None
                }
            }
        };
        let windows = installed_version.is_none().then(|| {
            let (product, version) =
                (state.system.product_name.as_str(), state.system.display_version.as_str());
            match &latest {
                Some(atlas) => {
                    t!("home-windows-atlas", product = product, version = version, atlas = atlas.as_str())
                }
                None => t!("home-windows", product = product, version = version),
            }
        });
        // What Atlas does, for a PC about to get it.
        let about = first_install(state).then(|| t!("home-about"));

        // Atlas checks for updates by itself as it opens, so the link offers
        // only a check that failed, tried again, which reads the installation
        // state again too. A tester build has no update check, so it offers
        // reading the state again while that is in question.
        let check = if bundled {
            (block.is_some() || state.atlas.is_err()).then(|| t!("home-check-again"))
        } else {
            matches!(state.release, ReleaseCheck::Failed).then(|| t!("common-try-again"))
        };

        let primary = action.map(|action| self.hero_button(state, action, accent));
        let locked = state.locked();
        let elevating = state.elevating;
        let start_over = (state.flow.active && !locked).then(|| {
            let model = model.clone();
            Button::new("home-start-over", t!("home-start-over"))
                .hyperlink()
                .compact()
                .disabled(elevating)
                .on_click(move |_, window, cx| start_install(&model, window, cx))
        });

        // Where the release joined the Windows line, the status row has
        // nothing left to say.
        let status_row = latest.is_none().then(|| {
            div()
                .flex()
                .flex_wrap()
                .items_center()
                .gap(px(10.))
                .gap_y(px(4.))
                .mt(px(6.))
                .when_some(installed_on, |this, installed_on| {
                    this.child(
                        div()
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-installed-on", installed_on)),
                    )
                })
                .when_some(status, |this, (light, text)| {
                    this.child(StatusLight::new(light, text).id("home-update-status").live())
                })
                .when_some(check, |this, label| {
                    let (model, headline) = (model.clone(), self.headline_focus.clone());
                    // The 24px link takes no more height than the 20px status
                    // beside it, so the cards below stay put as it comes and goes.
                    this.child(div().my(px(-2.)).child(
                        Button::new("home-check", label).hyperlink().compact().centre_label().on_click(
                            move |_, window, cx| {
                                model.update(cx, |m, cx| {
                                    if m.bundled() {
                                        m.recheck_installation(cx)
                                    } else {
                                        m.check_for_updates(cx)
                                    }
                                });
                                // The link goes while Atlas checks, so focus
                                // waits on the headline; the status says how
                                // the check went.
                                window.focus(&headline, cx);
                            },
                        ),
                    ))
                })
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
            .when_some(windows, |this, windows| {
                this.child(
                    div()
                        .type_body()
                        .text_color(theme.text_secondary)
                        .child(a11y_text("home-subline", windows)),
                )
            })
            .when_some(status_row, |this, status_row| this.child(status_row))
            .when_some(about, |this, about| {
                this.child(
                    div()
                        .mt(px(4.))
                        .type_body()
                        .text_color(theme.text_primary)
                        .child(a11y_text("home-about", about)),
                )
            });

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
                        .when_some(start_over, |this, start_over| this.child(start_over)),
                )
            })
            .into_any_element()
    }

    /// The hero's button for `action`.
    fn hero_button(&self, state: &AppModel, action: HeroAction, accent: bool) -> Button {
        let model = self.model.clone();
        // Until startup knows whether an install is running elsewhere, and
        // until Windows has answered the elevation prompt, nothing that
        // could start one is offered.
        let blocked = state.recovering || state.locked() || state.elevating;
        let start =
            move |_: &gpui::ClickEvent, window: &mut Window, cx: &mut App| start_install(&model, window, cx);
        let button = match action {
            HeroAction::Continue => Button::new(
                "home-continue",
                if state.locked() { t!("home-show-install") } else { t!("home-continue-installing") },
            )
            .trailing_icon(Icon::ChevronRight)
            .disabled(state.elevating)
            .on_click(on_model(&self.model, |m, cx| m.navigate(Page::Install, cx))),
            HeroAction::Install => Button::new("home-install", t!("home-install"))
                .icon(Icon::Download)
                .disabled(blocked)
                .on_click(start),
            HeroAction::Finish(target) => {
                Button::new("home-finish-install", t!("home-finish-install", version = target))
                    .icon(Icon::Download)
                    .disabled(blocked)
                    .on_click(start)
            }
            HeroAction::ContinueUpdate => Button::new("home-continue-update", t!("home-continue-update"))
                .icon(Icon::Sync)
                .disabled(blocked)
                .on_click(start),
            HeroAction::Update(version) => {
                Button::new("home-update", t!("home-update-to", version = version))
                    .icon(Icon::Sync)
                    .disabled(blocked)
                    .on_click(start)
            }
            HeroAction::DownloadManager => manager_download_button("home-manager-download"),
            HeroAction::Reinstall => Button::new("home-reinstall", t!("home-reinstall"))
                .icon(Icon::Download)
                .disabled(blocked)
                .on_click(start),
        };
        button.when(accent, Button::accent)
    }

    /// The raw text behind a bar's Show details, which names `section`.
    fn details(&self, section: String, raw: String, cx: &Context<Self>) -> Div {
        let shown = self.bar_details;
        div()
            .flex()
            .flex_col()
            .gap(px(4.))
            .child(link_row().child(details_toggle(
                "home-bar-details",
                section,
                shown,
                |page: &mut Self| &mut page.bar_details,
                cx,
            )))
            .when(shown, |this| {
                this.child(
                    div()
                        .type_caption()
                        .text_color(cx.theme().text_secondary)
                        .child(a11y_text("home-bar-raw", raw)),
                )
            })
    }

    /// What goes under a bar's actions: its raw details, and the help row
    /// under an unexpected failure.
    fn bar_content(
        &self,
        section: String,
        raw: Option<String>,
        help: bool,
        cx: &Context<Self>,
    ) -> Option<Div> {
        if raw.is_none() && !help {
            return None;
        }
        Some(
            div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .when_some(raw, |this, raw| this.child(self.details(section, raw, cx)))
                .when(help, |this| this.child(self.diagnostics.content(&self.model, cx))),
        )
    }

    /// Home's one bar. `plan` is whether the update plan shows, and `accent`
    /// whether the bar's action is the page's accent, as when nothing else is.
    fn bar(
        &self,
        which: HomeBar,
        state: &AppModel,
        plan: bool,
        accent: bool,
        cx: &Context<Self>,
    ) -> Option<AnyElement> {
        let model = &self.model;
        let bar = match which {
            HomeBar::Restart => {
                let owed = state.owed_restart()?;
                let title = t!("home-restart-title");
                let (message, raw) = match (&owed.problem, owed.requested) {
                    (Some(RestartProblem::Start { error }), _) => {
                        (t!("home-restart-failed"), Some(error.clone()))
                    }
                    (None, true) => (t!("restart-now-message"), None),
                    (None, false) => (t!("restart-needed"), None),
                };
                let label = if owed.problem.is_some() { t!("common-try-again") } else { t!("restart-now") };
                let mut bar = InfoBar::new(Severity::Warning, title.clone(), message)
                    .id("home-restart")
                    .focus_handle(self.restart_focus.clone())
                    .action(
                        // A second press while Windows has the request is ignored.
                        Button::new("home-restart-now", label)
                            .accent()
                            .icon(Icon::Power)
                            .on_click(on_model(model, |m, cx| m.restart_owed_now(cx))),
                    );
                if let Some(content) = self.bar_content(title, raw, false, cx) {
                    bar = bar.content(content);
                }
                bar
            }
            HomeBar::Protection => {
                protection_reminder_bar(model, state, "home", accent, &self.headline_focus)?
            }
            HomeBar::DefenderNotRestored => {
                // Where the hero already offers an install that goes on,
                // such as an update, that is the way back to Defender.
                let reinstall = hero_action(state) == Some(HeroAction::Reinstall);
                not_restored_bar(model, state, "home", reinstall.then_some(accent), &self.headline_focus)?
            }
            HomeBar::UpdateAccess => self.update_access_bar(state, cx)?,
            HomeBar::EndOfSupport => end_of_support_bar(state, plan)?,
            HomeBar::Unavailable => {
                let block = state.start_block()?;
                let title = t!("install-source-title");
                // Windows that no update path reaches is no fault: the ISO
                // card, first and recommended, is the way on, so the bar
                // leaves reinstalling to it.
                let (severity, message) = match &block {
                    InstallBlock::Windows {
                        block: WindowsBlock::NoPath { .. }, version, releases, ..
                    } => (
                        Severity::Warning,
                        t!(
                            "home-windows-no-path",
                            version = version.as_str(),
                            releases = describe::join_or(releases)
                        ),
                    ),
                    _ => (Severity::Error, block.text(state.bundled())),
                };
                let mut bar = InfoBar::new(severity, title.clone(), message).id("home-eligibility");
                if matches!(
                    block,
                    InstallBlock::Windows { block: WindowsBlock::Edition, ending: Some(_), .. }
                ) {
                    // Windows Update moves this edition on, without Atlas.
                    bar = bar.action(
                        Button::new("home-eligibility-windows-update", t!("check-fix-windows-update"))
                            .trailing_icon(Icon::OpenInNewWindow)
                            .when(accent, Button::accent)
                            .opens(links::WINDOWS_UPDATE),
                    );
                }
                // One cause, one bar: the state document's own error is its detail.
                let raw = state.atlas.as_ref().err().cloned();
                let help = matches!(block, InstallBlock::Unknown);
                if let Some(content) = self.bar_content(title, raw, help, cx) {
                    bar = bar.content(content);
                }
                bar
            }
            HomeBar::ManagerNeeded => {
                let required = match &state.acquisition {
                    Acquisition::Failed(AcquireProblem::ManagerOutdated { required }) => required.clone(),
                    _ => None,
                };
                // Named as Get ready names the package's version.
                let version = state
                    .package
                    .as_ref()
                    .map(|package| package.manifest.version.clone())
                    .or_else(|| state.release.release().map(|release| release.version().to_owned()))
                    .unwrap_or_else(|| state.manifest().version.clone());
                // The hero's Download Atlas Manager is the way on.
                InfoBar::new(
                    Severity::Warning,
                    t!("home-manager-needed-title"),
                    describe::manager_needed(&version, required.as_deref()),
                )
                .id("home-manager-needed")
            }
            HomeBar::Elevation => {
                let error = state.elevation_error.as_ref()?;
                let title = t!("home-elevation-title");
                let (message, raw) = match error {
                    ElevationProblem::DraftNotSaved { error } => {
                        (t!("home-elevation-draft-not-saved"), Some(error.clone()))
                    }
                    other => (other.text(), None),
                };
                let retry = model.clone();
                let mut bar =
                    InfoBar::new(Severity::Warning, title.clone(), message).id("home-elevation").action(
                        Button::new("home-elevate", t!("common-try-again"))
                            .icon(Icon::Admin)
                            .disabled(state.elevating)
                            .on_click(move |_, window, cx| start_install(&retry, window, cx)),
                    );
                if let Some(content) = self.bar_content(title, raw, false, cx) {
                    bar = bar.content(content);
                }
                bar
            }
            HomeBar::StateError => {
                let error = state.atlas.as_ref().err()?;
                let title = t!("home-state-error-title");
                let mut bar = InfoBar::new(Severity::Error, title.clone(), t!("home-state-error-problem"))
                    .id("home-state-error")
                    .action(
                        Button::new("home-state-retry", t!("common-try-again"))
                            .when(accent, Button::accent)
                            .on_click(on_model(model, |m, cx| m.recheck_installation(cx))),
                    );
                if let Some(content) = self.bar_content(title, Some(error.clone()), true, cx) {
                    bar = bar.content(content);
                }
                bar
            }
            HomeBar::Notice => {
                let notice = state.notice.as_ref()?;
                let (dismiss_model, headline) = (model.clone(), self.headline_focus.clone());
                let mut bar = InfoBar::new(Severity::Warning, notice.title(), notice.message())
                    .id("home-notice")
                    // The bar and its button go; focus goes to the headline.
                    .close_button(dismiss_button("home-notice-dismiss", move |_, window, cx| {
                        dismiss_model.update(cx, |m, cx| m.dismiss_notice(cx));
                        window.focus(&headline, cx);
                    }));
                // Only the user can tell whether an install still runs; the
                // record to delete if none does is a click away.
                let unexpected = if let crate::model::Notice::SessionUnreadable { record, .. } = notice {
                    let record = record.clone();
                    bar = bar.action(
                        Button::new("home-notice-reveal", t!("iso-open-folder"))
                            .icon(Icon::Folder)
                            .on_click(move |_, _, cx| cx.reveal_path(&record)),
                    );
                    true
                } else {
                    false
                };
                if let Some(content) =
                    self.bar_content(notice.title(), Some(notice.details()), unexpected, cx)
                {
                    bar = bar.content(content);
                }
                bar
            }
            HomeBar::ManagerUpdate => manager_update_bar(state, "home")?,
        };
        Some(bar.into_any_element())
    }

    /// Atlas changed Windows Update settings for an update that isn't
    /// finished. The hero's Continue update goes on with it; the bar puts
    /// the settings back. A record Atlas can't read is reported, never acted on.
    fn update_access_bar(&self, state: &AppModel, cx: &Context<Self>) -> Option<InfoBar> {
        let model = &self.model;
        let access = state.update_access.as_ref().filter(|access| access.open())?;
        let title = t!("home-update-access-title");
        let Some(journal) = access.journal.as_ref() else {
            let title = t!("home-update-access-unreadable-title");
            let mut bar =
                InfoBar::new(Severity::Error, title.clone(), t!("home-update-access-unreadable-problem"))
                    .id("home-update-access");
            if let Some(content) = self.bar_content(title, access.journal_error.clone(), true, cx) {
                bar = bar.content(content);
            }
            return Some(bar);
        };
        let release = journal.target.as_ref().map(|target| target.release.clone()).unwrap_or_default();
        let message = match journal.kind {
            JournalKind::Access => t!("home-update-access-updating"),
            _ if state.transition_waiting_for_offer()
                && !journal.installed()
                && journal.target.as_ref().is_none_or(|t| t.build != state.system.build) =>
            {
                t!("home-update-access-waiting", release = release.as_str())
            }
            _ => t!("home-update-access-put-back-later"),
        };
        // Why the settings didn't come back, or why they can't yet. An
        // unfinished install puts them back itself, which is no failure,
        // and leaves nothing to put back by hand.
        let (problem, raw, help, install_active) = match &state.restore_status {
            RestoreStatus::Failed(error) => {
                let expected =
                    crate::services::preparation::operation_reason(error) == Some("feature-install-active");
                match describe::restore_failure_cause(error) {
                    Some(cause) => (Some(cause), None, !expected, expected),
                    None => (Some(t!("home-put-back-failed")), Some(error.clone()), true, false),
                }
            }
            _ if state.resume_target().is_some() || state.rebuilt_windows_awaits_install() => {
                (Some(t!("update-access-finish-install")), None, false, true)
            }
            _ => (None, None, false, false),
        };
        let running = state.restore_status == RestoreStatus::Running;
        let mut bar = InfoBar::new(Severity::Warning, title.clone(), message).id("home-update-access");
        if !install_active {
            bar = bar.action(
                Button::new(
                    "home-put-back",
                    if running { t!("home-putting-back") } else { t!("home-put-back") },
                )
                .when(!state.elevated, |button| button.icon(Icon::Admin))
                .disabled(!state.may_restore_update_access())
                .on_click(on_model(model, |m, cx| m.restore_update_access(cx))),
            );
        }
        if problem.is_some() || help {
            bar = bar.content(
                div()
                    .flex()
                    .flex_col()
                    .gap(px(8.))
                    .when_some(problem, |this, problem| {
                        this.child(div().type_body().child(a11y_text("home-update-access-problem", problem)))
                    })
                    .when_some(self.bar_content(title, raw, help, cx), |this, content| this.child(content)),
            );
        }
        Some(bar)
    }

    /// The two parts of an update that also moves Windows, under the hero.
    fn plan_card(&self, plan: &Plan, window: &Window, cx: &App) -> AnyElement {
        let theme = cx.theme();
        let windows_done = plan.progress.is_some_and(|progress| progress[0] == StepStatus::Done);
        let windows_detail = match plan.need {
            _ if windows_done => t!("home-plan-step-installed"),
            TransitionNeed::Required => t!("home-plan-windows-step"),
            TransitionNeed::Optional => t!("home-plan-windows-step-ask"),
        };
        let status = |index: usize| plan.progress.map(|progress| progress[index]);
        let lines = vec![
            StepLine {
                title: t!("home-plan-windows-title", release = plan.transition.target_release),
                detail: windows_detail,
                status: status(0),
            },
            StepLine {
                title: t!("home-plan-atlas-title", version = plan.version.as_str()),
                detail: t!("home-plan-atlas-step"),
                status: status(1),
            },
        ];
        card(cx)
            .child(
                card_body()
                    .child(
                        div()
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-plan-intro", t!("home-plan-files"))),
                    )
                    .child(step_list(
                        "home-plan",
                        t!("home-plan-name"),
                        StepLayout::Under,
                        lines,
                        window,
                        cx,
                    )),
            )
            .into_any_element()
    }

    /// "What's new" in the update Home offers: its notes under one header,
    /// which names the release, so the notes' own heading for it goes.
    fn release_notes_card(&mut self, release: &Release, cx: &Context<Self>) -> AnyElement {
        // Release notes can run to dozens of lines; keep the fold short.
        // They are the project's own text and stay in the language they
        // were written in.
        let expanded = self.notes_expanded;
        let version = release.version().to_owned();
        let blocks = without_version_heading(self.notes_for(&release.body), &version);
        let collapsible = blocks.len() > PREVIEW_BLOCKS;
        let shown = visible_notes(blocks, expanded);
        card(cx)
            .child(card_header(
                cx,
                "whats-new",
                t!("home-whats-new", version = version.as_str()),
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
            ))
            .child(
                card_body()
                    .gap(px(2.))
                    // Under the card's level-2 header: a `#` heading is level 3.
                    .child(Markdown::new("home-notes", shown).under_heading(2))
                    .when(collapsible, |this| {
                        this.child(
                            link_row().pt(px(6.)).child(
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

    /// The card that leads to creating an Atlas ISO, to reinstall Windows
    /// with Atlas. Recommended, it comes first with the page's accent; on
    /// Windows that looks used, `reason` says why.
    fn media_entry(&self, state: &AppModel, recommended: bool, reason: bool, cx: &App) -> AnyElement {
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
                    // As a settings card pads a setting and its control.
                    .p(px(16.))
                    .child(
                        div()
                            .flex()
                            .items_start()
                            .gap(px(16.))
                            .flex_1()
                            .min_w(rems(14.))
                            // On the title's line, not the middle of the block.
                            .child(
                                icon_in_line_sized(Icon::Disc, 20., BODY_LINE_HEIGHT)
                                    .flex_shrink_0()
                                    .text_color(theme.text_primary),
                            )
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
                                                heading("home-iso-title", 2, t!("home-iso-title"), cx)
                                                    .type_body(),
                                            )
                                            .when(recommended, |this| {
                                                this.child(badge(
                                                    "home-iso-recommended",
                                                    t!("iso-recommended"),
                                                    cx,
                                                ))
                                            }),
                                    )
                                    .when(reason, |this| {
                                        this.child(
                                            div()
                                                .type_caption()
                                                .text_color(theme.text_secondary)
                                                .child(detail_text("home-iso-used", t!("home-iso-used"))),
                                        )
                                    }),
                            ),
                    )
                    .child(
                        div().ml_auto().child(
                            Button::new("home-create-iso", t!("iso-open"))
                                .when(recommended, Button::accent)
                                .disabled(
                                    locked || recovering || state.elevating || !state.can_navigate(Page::Iso),
                                )
                                .on_click(on_model(&self.model, move |m, cx| {
                                    if recommended {
                                        m.navigate_iso_for_this_pc(cx)
                                    } else {
                                        m.navigate(Page::Iso, cx)
                                    }
                                })),
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
        // A restart that didn't take is announced where its button is.
        let restart_epoch = self.model.read(cx).owed_restart().map_or(0, |owed| owed.epoch);
        if std::mem::replace(&mut self.shown_restart_epoch, restart_epoch) < restart_epoch {
            window.focus(&self.restart_focus, cx);
            crate::ui::focus_reveal::request(window, cx);
        }
        if std::mem::take(&mut self.ask_on_open) {
            let model = model.clone();
            cx.defer_in(window, move |_, window, cx| ask_about_used_windows(&model, window, cx));
        }
        let bar = home_bar(self.model.read(cx));
        if std::mem::replace(&mut self.shown_bar, bar) != bar {
            self.bar_details = false;
        }

        let state = self.model.read(cx);
        // The bar that says Defender wasn't brought back carries Reinstall
        // Atlas itself, so the hero doesn't repeat it.
        let action = hero_action(state).filter(|action| {
            !(*action == HeroAction::Reinstall && bar == Some(HomeBar::DefenderNotRestored))
        });
        let accent = action.as_ref().is_some_and(|action| hero_accent(action, state.windows_looks_used()));
        let recommend_iso = media_recommended(state);
        let plan = update_plan(state);
        let mut body: Vec<AnyElement> = vec![self.hero(state, action, accent, cx)];
        // A bar's action is the accent only when nothing else is.
        let bar_accent = !accent && !recommend_iso;
        body.extend(bar.and_then(|bar| self.bar(bar, state, plan.is_some(), bar_accent, cx)));
        if recommend_iso {
            let reason = state.windows_looks_used();
            body.push(self.media_entry(state, true, reason, cx));
        }
        // After the recommended ISO card, so installing anyway still says
        // what it involves.
        body.extend(steps_card(state).map(|steps| install_steps_card(state, steps, window, cx)));
        body.extend(plan.as_ref().map(|plan| self.plan_card(plan, window, cx)));
        if let Some(release) = state.offered_update() {
            body.push(self.release_notes_card(release, cx));
        }
        let setup = setup_card(
            state.installed(),
            state.installed_version().is_some(),
            state.start_block().is_some(),
            state.atlas.is_err(),
        );
        body.extend(setup_card_view(state, setup, cx));
        if !recommend_iso {
            body.push(self.media_entry(state, false, false, cx));
        }
        body.push(project_links(&model, state));
        self.diagnostics.settle(&model, window, cx);
        page_frame("home-scroll", None, None, None, (&self.scroll, &self.scrollbar), body, None, cx)
    }
}

/// This Windows version's end of security updates, where the update that
/// moves Windows on is the way past it: the move and the date.
fn end_of_support(state: &AppModel) -> Option<(&'static Transition, chrono::NaiveDate)> {
    let (transition, _) = state.windows_transition()?;
    Some((transition, windows_release::end_of_updates(&state.system)?))
}

/// Windows 11, version 24H2 on Home and Pro stops getting security updates:
/// Home says when, and how long the version the update moves it to gets
/// them. The plan, when it shows, already says the update moves Windows.
fn end_of_support_bar(state: &AppModel, plan: bool) -> Option<InfoBar> {
    let (transition, ending) = end_of_support(state)?;
    let current = state.system.display_version.as_str();
    let title = if chrono::Local::now().date_naive() > ending {
        t!("home-end-of-updates-past-title", current = current)
    } else {
        t!("home-end-of-updates-title", current = current, date = fmt::day(ending))
    };
    let until = fmt::day(transition.end_of_updates());
    let message = if plan {
        t!("home-end-of-support-plan", release = transition.target_release, until = until)
    } else {
        let version = state
            .release
            .release()
            .map_or_else(|| state.manifest().version.clone(), |r| r.version().to_owned());
        t!(
            "home-end-of-updates-message",
            version = version.as_str(),
            release = transition.target_release,
            until = until
        )
    };
    Some(InfoBar::new(Severity::Warning, title, message).id("home-end-of-updates"))
}

/// An update that also moves Windows: the Atlas version it installs, the
/// move, whether the package needs it, and how far each part got.
struct Plan {
    version: String,
    transition: &'static Transition,
    need: TransitionNeed,
    progress: Option<[StepStatus; 2]>,
}

/// The plan for the update on offer, or, in a tester build, for its bundled
/// package when that is newer than what's installed.
fn update_plan(state: &AppModel) -> Option<Plan> {
    if state.flow.active {
        return None;
    }
    let version = match state.offered_update() {
        Some(release) => release.version().to_owned(),
        None if state.bundled() && state.start_block().is_none() => {
            let bundled = state.manifest().version.clone();
            let installed = state.installed_version()?;
            crate::services::releases::compare_versions(&bundled, installed).is_gt().then_some(bundled)?
        }
        None => return None,
    };
    let (transition, need, progress) =
        plan_move(state.recorded_transition(), state.windows_transition(), state.system.build)?;
    Some(Plan { version, transition, need, progress })
}

/// The card that follows the hero and the plan.
#[derive(Debug, PartialEq, Eq)]
enum SetupCard<T> {
    /// The record of a completed install: its choices, Windows and history.
    Recorded(T),
    /// Atlas is installed, but there is no record of the install to show.
    Unrecorded,
    /// Nothing is installed, or what is on this PC can't be told.
    Hidden,
}

/// `unreadable` is a state document that couldn't be read: its bar says so,
/// and a card saying there is no record would contradict it.
fn setup_card<T>(record: Option<T>, version_known: bool, blocked: bool, unreadable: bool) -> SetupCard<T> {
    match record {
        Some(record) => SetupCard::Recorded(record),
        None if unreadable || (blocked && !version_known) => SetupCard::Hidden,
        None if version_known => SetupCard::Unrecorded,
        None => SetupCard::Hidden,
    }
}

/// The move Home's update plan describes, and how far its two parts got on
/// `build`: the move Atlas's record has under way, also once Windows has
/// moved, or else the one this PC can make, not started.
fn plan_move(
    recorded: Option<&'static Transition>,
    offered: Option<(&'static Transition, TransitionNeed)>,
    build: u32,
) -> Option<(&'static Transition, TransitionNeed, Option<[StepStatus; 2]>)> {
    let Some(transition) = recorded else {
        return offered.map(|(transition, need)| (transition, need, None));
    };
    // Once Windows has moved there's no move left to offer, or to recommend.
    let need = offered.map_or(TransitionNeed::Required, |(_, need)| need);
    let progress = if build == transition.target_build {
        [StepStatus::Done, StepStatus::Current]
    } else {
        [StepStatus::Current, StepStatus::Upcoming]
    };
    Some((transition, need, Some(progress)))
}

/// A row of "Your Atlas setup": a question of the package, labelled as the
/// Install step's summary labels it, with the answers this PC has.
#[derive(Debug, PartialEq, Eq)]
struct SetupRow {
    title: String,
    /// A single choice, answered once; otherwise a list, which may be empty.
    single: bool,
    chosen: Vec<String>,
}

/// The options among `options` that `pages` of `manifest` offer. A page
/// asked only once another option is chosen counts only then, as in the
/// Install step's summary.
fn offered_on<'a>(manifest: &'a Manifest, pages: &[usize], options: &[String]) -> Vec<&'a ChoiceOption> {
    pages
        .iter()
        .filter_map(|&page| manifest.choices.get(page))
        .filter(|page| page.depends_on.as_ref().is_none_or(|dependency| options.contains(dependency)))
        .flat_map(|page| page.options.iter())
        .filter(|option| options.contains(&option.id))
        .collect()
}

/// The setup card's rows of choices, as this PC shows them: one per
/// question the package asks that this PC has an answer for, then the
/// optional extras, with any recorded option the package no longer offers.
fn setup_rows(state: &AppModel) -> Vec<(SetupRow, Vec<ListEntry>)> {
    let manifest = state.manifest();
    let options = state.installed_options();
    let entry = |id: &str| ListEntry::option(id, state.option_text(id).unwrap_or(id));
    let mut rows = Vec::new();
    let mut extras = None;
    for group in state.choice_groups() {
        let chosen: Vec<ListEntry> = offered_on(manifest, &group.pages, &options)
            .into_iter()
            .map(|option| entry(&option.id))
            .collect();
        if group.required {
            // An earlier release may have recorded no answer to a question
            // asked since: there's nothing to show for it.
            if !chosen.is_empty() {
                rows.push((group.kind.title(), true, chosen));
            }
        } else {
            extras = Some((group.kind.title(), chosen));
        }
    }
    let offered: Vec<&str> =
        manifest.choices.iter().flat_map(|choice| &choice.options).map(|option| option.id.as_str()).collect();
    let others: Vec<ListEntry> =
        options.iter().filter(|id| !offered.contains(&id.as_str())).map(|id| entry(id)).collect();
    if extras.is_some() || !others.is_empty() {
        let (title, mut chosen) =
            extras.unwrap_or_else(|| (crate::model::ScreenKind::Extras.title(), Vec::new()));
        chosen.extend(others);
        rows.push((title, false, chosen));
    }
    rows.into_iter()
        .map(|(title, single, entries)| {
            let chosen = entries.iter().map(|entry| entry.text.clone()).collect();
            (SetupRow { title, single, chosen }, entries)
        })
        .collect()
}

/// A setup row's value, keyed like its row: a single answer, or the list of
/// extras, or None. A record says what was chosen, not what choosing it
/// meant: the cautions shown where the choice is made stay there.
fn setup_value(cx: &App, key: &str, index: usize, row: &SetupRow, entries: Vec<ListEntry>) -> AnyElement {
    let entries: Vec<ListEntry> = entries.into_iter().map(|entry| ListEntry::new(entry.text)).collect();
    if row.single {
        let Some(ListEntry { text, .. }) = entries.into_iter().next() else {
            return div().into_any_element();
        };
        div().min_w_0().child(detail_text(key, text)).into_any_element()
    } else if entries.is_empty() {
        div()
            .text_color(cx.theme().text_secondary)
            .child(detail_text(key, t!("common-none")))
            .into_any_element()
    } else {
        plain_list(cx, ("home-setup-list", index), &row.title, entries).w_full().into_any_element()
    }
}

/// The setup card of a recorded install, as Home shows it, for the "Atlas is
/// installed" window, so both say the same about the same install.
pub(super) fn recorded_setup_card(state: &AppModel, installed: &AtlasState, cx: &App) -> Option<AnyElement> {
    setup_card_view(state, SetupCard::Recorded(installed), cx)
}

/// The [`SetupCard`] for this PC.
fn setup_card_view(state: &AppModel, setup: SetupCard<&AtlasState>, cx: &App) -> Option<AnyElement> {
    let theme = cx.theme();
    match setup {
        SetupCard::Recorded(installed) => {
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
            let choices = setup_rows(state).into_iter().enumerate().map(|(index, (row, entries))| {
                let key = format!("setup-{index}");
                let value = setup_value(cx, &key, index, &row, entries);
                detail_row(cx, &key, row.title, value)
            });
            Some(
                card(cx)
                    .child(
                        card_body()
                            .child(card_title(cx, "your-install", t!("home-your-install"), 2))
                            // As this PC has them: an earlier update may have
                            // recorded a choice it never applied.
                            .children(choices)
                            .child(detail_row(
                                cx,
                                "windows",
                                t!("common-windows"),
                                detail_text("windows", describe::system_description(&state.system)),
                            ))
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
                                        // Body, as every other value of the card,
                                        // so the first line sits level with the label.
                                        .children(history.into_iter().enumerate().map(|(index, line)| {
                                            div()
                                                .id(("history", index))
                                                .role(Role::ListItem)
                                                .aria_label(line.clone())
                                                .type_body()
                                                .text_color(theme.text_primary)
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
                .child(
                    card_body().child(card_title(cx, "your-install", t!("home-your-install"), 2)).child(
                        div()
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-install-unrecorded", t!("home-install-unrecorded"))),
                    ),
                )
                .into_any_element(),
        ),
        SetupCard::Hidden => None,
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

/// The install steps Home lists under the hero.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StepsCard {
    /// What happens in each step, on a PC without Atlas.
    Ahead,
    /// A setup under way: where each step stands, as the install flow's
    /// stepper shows it.
    UnderWay([StepStatus; 4]),
}

/// The install steps for this PC, if Home lists them: while a setup is
/// under way, and before one starts on a PC without Atlas. An installed
/// Atlas has its own setup card instead.
fn steps_card(state: &AppModel) -> Option<StepsCard> {
    if state.flow.active {
        let current = state.flow.step.index();
        Some(StepsCard::UnderWay(
            Step::ALL.map(|step| StepStatus::visited(step.index(), current, state.step_satisfied(step))),
        ))
    } else if first_install(state) {
        Some(StepsCard::Ahead)
    } else {
        None
    }
}

/// What happens in `step` on this PC, in one sentence: Get ready names the
/// Windows version it moves to where the package needs a newer one, and
/// Install says how long installing usually takes, from the package, and
/// how it ends.
fn step_detail(state: &AppModel, step: Step) -> String {
    match step {
        Step::Ready => match state.windows_transition() {
            Some((transition, TransitionNeed::Required)) => {
                t!("home-step-ready-move", release = transition.target_release)
            }
            _ => t!("home-step-ready"),
        },
        Step::Options => t!("home-step-options"),
        Step::Security => t!("home-step-security"),
        Step::Install => {
            let minutes = state.manifest().estimated_minutes;
            if state.install_restarts() {
                t!("home-step-install-restarts", minutes = minutes)
            } else {
                t!("home-step-install-restart-yourself", minutes = minutes)
            }
        }
    }
}

/// The card of install steps: each step's title as the stepper names it,
/// with its sentence beside it, then what to do before starting.
fn install_steps_card(state: &AppModel, steps: StepsCard, window: &Window, cx: &App) -> AnyElement {
    let (title, statuses) = match steps {
        StepsCard::Ahead => (t!("home-steps-title"), None),
        StepsCard::UnderWay(statuses) => (t!("home-steps-under-way-title"), Some(statuses)),
    };
    let lines = Step::ALL
        .into_iter()
        .map(|step| StepLine {
            title: step.title(),
            detail: step_detail(state, step),
            status: statuses.map(|statuses| statuses[step.index()]),
        })
        .collect();
    card(cx)
        .child(
            card_body()
                .child(card_title(cx, "steps", title.clone(), 2))
                .child(step_list("home-steps", title, StepLayout::Beside, lines, window, cx))
                .child(
                    div()
                        .pt(px(4.))
                        .type_body()
                        .text_color(cx.theme().text_primary)
                        .child(a11y_text("home-steps-save-work", t!("home-steps-save-work"))),
                ),
        )
        .into_any_element()
}

/// One numbered line: a title, its sentence, and, in a sequence under way,
/// where it stands.
struct StepLine {
    title: String,
    detail: String,
    status: Option<StepStatus>,
}

/// Where a numbered line puts its sentence.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StepLayout {
    /// Under the title, as a caption: the two parts of an update.
    Under,
    /// Beside the title, starting in one column from line to line, and under
    /// it where the line is too narrow for both: the install steps.
    Beside,
}

/// Numbered lines, reported as a list named `name`: the steps really are a
/// sequence, so the numbers carry meaning.
fn step_list(
    id: &'static str,
    name: String,
    layout: StepLayout,
    lines: Vec<StepLine>,
    window: &Window,
    cx: &App,
) -> Stateful<Div> {
    let count = lines.len();
    let marker_offset = match layout {
        StepLayout::Under => step_title_top(window, cx),
        StepLayout::Beside => body_cap_center_offset(window, cx),
    };
    div()
        .id(id)
        .role(Role::List)
        .aria_label(name)
        .aria_size_of_set(count)
        .flex()
        .flex_col()
        .gap(px(if layout == StepLayout::Under { 8. } else { 4. }))
        .children(
            lines
                .into_iter()
                .enumerate()
                .map(|(index, line)| step_line(index, count, line, layout, marker_offset, cx)),
        )
}

/// A numbered line of a [`step_list`]. Its accessible name says the number,
/// the title and the sentence. With a status, the marker shows it as the
/// install steps' own stepper does: a check when done, the accent behind
/// the current number, and "!" on the caution colour for a step that needs
/// attention again. `marker_offset` places the marker by the title's
/// capitals: from their top under [`StepLayout::Under`], and from the line's
/// centre to theirs under [`StepLayout::Beside`].
fn step_line(
    index: usize,
    count: usize,
    line: StepLine,
    layout: StepLayout,
    marker_offset: Pixels,
    cx: &App,
) -> Stateful<Div> {
    let theme = cx.theme();
    let number = index + 1;
    let StepLine { title, detail, status } = line;
    let step = match status {
        Some(status) => super::stepper::step_name(index, count, &title, status),
        None => t!("home-step-a11y", number = number, title = title.as_str()),
    };
    let item = div()
        .id(("home-step", number))
        .role(Role::ListItem)
        .aria_label(t!("home-step-detail-a11y", step = step, detail = detail.as_str()))
        // AccessKit counts from 0 and takes the size from the list.
        .aria_position_in_set(index)
        .flex()
        .items_start()
        .gap(px(12.))
        .py(px(4.));
    let marker = step_marker(number, status, cx).flex_shrink_0();
    match layout {
        StepLayout::Under => item.child(marker.mt(marker_offset)).child(
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
        ),
        // The marker centres on the title's capitals, as the stepper's do.
        StepLayout::Beside => item
            .child(
                div()
                    .flex()
                    .flex_shrink_0()
                    .items_center()
                    .h(BODY_LINE_HEIGHT)
                    .child(marker.relative().top(marker_offset)),
            )
            .child(
                div()
                    .flex()
                    .flex_wrap()
                    .flex_1()
                    .min_w_0()
                    .gap_x(px(16.))
                    // Scales with the text size; capped so the sentence keeps
                    // room at the largest sizes.
                    .child(
                        div()
                            .w(rems(STEP_TITLE_WIDTH))
                            .max_w(relative(0.4))
                            .flex_shrink_0()
                            .type_body_strong()
                            .text_color(theme.text_primary)
                            .child(title),
                    )
                    .child(
                        div()
                            .flex_1()
                            .min_w(rems(12.))
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(detail),
                    ),
            ),
    }
}

/// Where to read more, follow the project, ask for help or report a problem.
/// A problem is reported privately, in the app; the rest open the browser.
fn project_links(model: &Entity<AppModel>, state: &AppModel) -> AnyElement {
    link_row()
        .child(
            Button::new("home-docs", t!("common-read-the-docs"))
                .hyperlink()
                .compact()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::DOCS),
        )
        .child(
            Button::new("home-github", t!("home-github"))
                .hyperlink()
                .compact()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::GITHUB),
        )
        .child(
            Button::new("home-discord", t!("home-discord"))
                .hyperlink()
                .compact()
                .trailing_icon(Icon::OpenInNewWindow)
                .opens(links::DISCORD),
        )
        .child(
            Button::new("home-report", t!("home-report-problem"))
                .hyperlink()
                .compact()
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
        // No antivirus where the user chose to keep one, and no Atlas package
        // removed it: something Atlas doesn't know about did, so it offers a
        // report. Only those who didn't remove it themselves need one, so
        // it's never the accent.
        InfoBar::new(Severity::Warning, t!("security-banner-missing-title"), t!("defender-missing-message"))
            .action(
                Button::new(id("defender-missing-report"), t!("report-title"))
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
        // Through the model, which shows a page an Atlas 0.5 policy hides
        // first. A button, as on the install steps: it opens an app, not a page.
        let model = model.clone();
        InfoBar::new(severity, title, reminder.message()).action(
            Button::new(id("security-open"), t!("common-open-windows-security"))
                .icon(Icon::Shield)
                .when(accent, Button::accent)
                .on_click(move |_, _, cx| model.update(cx, |m, cx| m.open_windows_security(cx))),
        )
    };
    Some(bar.id(id("security-reminder")).close_button(dismiss))
}

/// The warning, for the "Atlas is installed" window, that Microsoft Defender
/// is still removed, with Reinstall Atlas as the window's accent: see
/// [`not_restored_bar`].
pub(super) fn defender_not_restored_bar(
    model: &Entity<AppModel>,
    state: &AppModel,
    key: &str,
    return_focus: &FocusHandle,
) -> Option<InfoBar> {
    not_restored_bar(model, state, key, Some(true), return_focus)
}

/// The warning, for Home and the "Atlas is installed" window, that Microsoft
/// Defender is still removed: Atlas's record kept it, but an earlier update
/// left Atlas's NoDefender package installed. It says how to bring Defender
/// back, and offers no report, as Atlas knows why. With `reinstall`, it
/// carries Reinstall Atlas, the accent if `reinstall` is true; the
/// reinstall's first screen offers Choose again, where Defender can be
/// kept. `key` prefixes its element ids; focus goes to `return_focus` once
/// Dismiss has taken it away.
fn not_restored_bar(
    model: &Entity<AppModel>,
    state: &AppModel,
    key: &str,
    reinstall: Option<bool>,
    return_focus: &FocusHandle,
) -> Option<InfoBar> {
    if !state.defender_not_restored_shown() {
        return None;
    }
    let id = |name: &str| ElementId::Name(format!("{key}-{name}").into());
    let (dismiss_model, back) = (model.clone(), return_focus.clone());
    let dismiss = dismiss_button(id("not-restored-dismiss"), move |_, window, cx| {
        dismiss_model.update(cx, |m, cx| m.dismiss_defender_not_restored(cx));
        window.focus(&back, cx);
    });
    let blocked = state.recovering || state.locked() || state.elevating;
    let mut bar = InfoBar::new(
        Severity::Warning,
        t!("installed-defender-not-restored-title"),
        t!("defender-not-restored-message"),
    )
    .id(id("defender-not-restored"))
    .close_button(dismiss);
    if let Some(accent) = reinstall {
        let model = model.clone();
        bar = bar.action(
            Button::new(id("not-restored-reinstall"), t!("home-reinstall"))
                .icon(Icon::Download)
                .when(accent, Button::accent)
                .disabled(blocked)
                .on_click(move |_, window, cx| start_install(&model, window, cx)),
        );
    }
    Some(bar)
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;
    use std::time::{Duration, Instant};

    use gpui::AsyncApp;

    use super::*;
    use crate::model::test_harness::{Machine, all_off, new_model, run_model_test, supported_system};
    use crate::model::{Origin, PackageSource};
    use crate::pages::testing::{NO_TELEMETRY, installed_model, rebuilt};
    use crate::services::legacy_choices::Facts;
    use crate::services::system::SystemInfo;
    use crate::services::test_support::TempDir;
    use crate::services::windows_installation::Evidence;

    /// Polls the model until `condition` holds; the model reads some of what
    /// Home shows on a worker.
    async fn until(cx: &AsyncApp, model: &Entity<AppModel>, condition: impl Fn(&AppModel) -> bool) {
        let deadline = Instant::now() + Duration::from_secs(30);
        while !model.read_with(cx, |m, _| condition(m)) {
            assert!(Instant::now() < deadline, "timed out");
            cx.background_executor().timer(Duration::from_millis(25)).await;
        }
    }

    fn release(version: &str) -> ReleaseCheck {
        ReleaseCheck::Ready {
            release: Release {
                tag_name: version.into(),
                body: String::new(),
                html_url: String::new(),
                assets: Vec::new(),
            },
        }
    }

    #[test]
    fn collapsed_release_notes_show_at_most_the_preview_and_short_notes_whole() {
        let blocks = parse_markdown(&"a\n\n".repeat(10));
        assert!(blocks.len() > PREVIEW_BLOCKS);
        assert_eq!(visible_notes(&blocks, false).len(), PREVIEW_BLOCKS);
        assert_eq!(visible_notes(&blocks, true).len(), blocks.len());
        // A note shorter than the preview is shown whole, not sliced past its end.
        assert_eq!(visible_notes(&blocks[..2], false).len(), 2);
    }

    /// The card's header names the release, so a heading at the top of the
    /// notes that says only that goes; one that says more stays.
    #[test]
    fn the_notes_lose_only_a_heading_that_repeats_the_release() {
        let first = |source: &str| match without_version_heading(&parse_markdown(source), "0.6.0").first() {
            Some(MarkdownBlock::Heading(_, text) | MarkdownBlock::Paragraph(text)) => text.text.clone(),
            other => format!("{other:?}"),
        };
        assert_eq!(first("## Atlas 0.6.0\n\nFaster setup."), "Faster setup.");
        assert_eq!(first("\n# AtlasOS v0.6.0\n\n### Atlas Manager"), "Atlas Manager");
        assert_eq!(first("## What's new in 0.6.0\n\nFaster setup."), "What's new in 0.6.0");
        assert_eq!(first("## Atlas 0.5.0\n\nOlder."), "Atlas 0.5.0");
        assert_eq!(first("Faster setup."), "Faster setup.");
        assert!(without_version_heading(&parse_markdown("# Atlas 0.6.0"), "0.6.0").is_empty());
    }

    #[test]
    fn home_shows_the_most_urgent_bar_alone() {
        use HomeBar::*;
        assert_eq!(first_bar(|_| false), None);
        assert_eq!(first_bar(|_| true), Some(Restart));
        assert_eq!(first_bar(|bar| matches!(bar, Protection | UpdateAccess | Notice)), Some(Protection));
        assert_eq!(first_bar(|bar| matches!(bar, EndOfSupport | UpdateAccess)), Some(UpdateAccess));
        assert_eq!(
            first_bar(|bar| matches!(bar, EndOfSupport | Unavailable | ManagerUpdate)),
            Some(EndOfSupport)
        );
        assert_eq!(first_bar(|bar| matches!(bar, Notice | ManagerUpdate)), Some(Notice));
    }

    #[test]
    fn setup_cards_show_only_what_is_known_of_an_install() {
        assert_eq!(setup_card(Some(()), true, false, false), SetupCard::Recorded(()));
        assert_eq!(setup_card(None::<()>, true, false, false), SetupCard::Unrecorded);
        assert_eq!(setup_card(None::<()>, true, true, false), SetupCard::Unrecorded);
        assert_eq!(setup_card(None::<()>, false, true, false), SetupCard::Hidden);
        // A PC without Atlas has no card: the install steps say how an install goes.
        assert_eq!(setup_card(None::<()>, false, false, false), SetupCard::Hidden);
    }

    #[test]
    fn an_unreadable_state_document_hides_the_card_its_bar_would_contradict() {
        // Neither "no record of how Atlas was installed" nor anything else.
        assert_eq!(setup_card(None::<()>, true, false, true), SetupCard::Hidden);
        assert_eq!(setup_card(None::<()>, false, false, true), SetupCard::Hidden);
    }

    #[test]
    fn the_update_plan_follows_a_move_until_atlas_is_installed() {
        use StepStatus::{Current, Done, Upcoming};
        use TransitionNeed::{Optional, Required};
        let to_26h2 = windows_release::transition_to("26H2").unwrap();
        assert_eq!(plan_move(None, Some((to_26h2, Optional)), 26200), Some((to_26h2, Optional, None)));
        assert_eq!(
            plan_move(Some(to_26h2), Some((to_26h2, Required)), 26100),
            Some((to_26h2, Required, Some([Current, Upcoming])))
        );
        // On the new build this PC has no move to make, but the record says
        // Windows is done and Atlas is next.
        assert_eq!(plan_move(Some(to_26h2), None, 26300), Some((to_26h2, Required, Some([Done, Current]))));
        assert_eq!(plan_move(None, None, 26300), None);
    }

    /// A PC without Atlas installs from the hero. Where Windows looks used,
    /// reinstalling it comes first and takes the accent, and Install asks.
    #[test]
    fn used_windows_moves_the_accent_to_reinstalling_windows() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-used-windows");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            model.update(&mut cx, |m, _| {
                assert!(first_install(m));
                assert_eq!(hero_action(m), Some(HeroAction::Install));
                assert!(hero_accent(&HeroAction::Install, m.windows_looks_used()));
                assert!(!media_recommended(m), "a fresh Windows keeps the ISO card quiet");
            });

            let temp = TempDir::new("home-used-windows-old");
            let mut env = Machine::new(all_off()).environment(temp.path());
            env.adapters.read_windows_installation =
                Arc::new(|| Evidence { age_days: Some(400), desktop_apps: 12 });
            let model = new_model(&mut cx, env);
            until(&cx, &model, AppModel::windows_looks_used).await;
            model.update(&mut cx, |m, _| {
                assert_eq!(hero_action(m), Some(HeroAction::Install));
                assert!(!hero_accent(&HeroAction::Install, m.windows_looks_used()));
                assert!(media_recommended(m));
                // Once the user went on anyway, the setup is the way on.
                m.flow.begin().unwrap();
                assert_eq!(hero_action(m), Some(HeroAction::Continue));
                assert!(hero_accent(&HeroAction::Continue, m.windows_looks_used()));
                assert!(!media_recommended(m));
            });
        });
    }

    /// The hero names the next step: the update on offer, continuing one
    /// under way, a newer Atlas Manager the package needs, or reinstalling.
    #[test]
    fn the_hero_names_the_next_step_on_an_installed_pc() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-hero-installed");
            let pc = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
            let model = installed_model(&mut cx, &temp, Some(&["mitigations-default"]), pc);
            model.update(&mut cx, |m, _| {
                let version = m.manifest().version.clone();
                m.release = release(&version);
                assert_eq!(hero_action(m), Some(HeroAction::Reinstall));
                assert!(
                    !hero_accent(&HeroAction::Reinstall, m.windows_looks_used()),
                    "nothing asks for a reinstall, so it isn't the accent"
                );
                assert!(!first_install(m));

                m.release = release("99.0.0");
                assert_eq!(hero_action(m), Some(HeroAction::Update("99.0.0".into())));

                // The bar says what's under way; the hero continues it.
                m.update_access = Some(rebuilt(&["defender-enable"]));
                assert_eq!(hero_action(m), Some(HeroAction::ContinueUpdate));
                assert_eq!(home_bar(m), Some(HomeBar::UpdateAccess));

                m.acquisition =
                    Acquisition::Failed(AcquireProblem::ManagerOutdated { required: Some("99.0.0".into()) });
                assert_eq!(hero_action(m), Some(HeroAction::DownloadManager));

                // Nothing to start where the installation can't be told.
                m.install_identity = Err("unreadable".into());
                assert_eq!(hero_action(m), None);
            });
        });
    }

    /// Protection outranks an update under way, which outranks the rest; a
    /// newer Atlas Manager comes last.
    #[test]
    fn home_picks_its_one_bar_by_priority() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-one-bar");
            let pc = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
            let model = installed_model(&mut cx, &temp, Some(&["mitigations-default"]), pc);
            model.update(&mut cx, |m, _| {
                assert_eq!(home_bar(m), None);
                m.notice = Some(crate::model::Notice::SettingsNotSaved { error: "denied".into() });
                assert_eq!(home_bar(m), Some(HomeBar::Notice));
                m.elevation_error = Some(ElevationProblem::Declined);
                assert_eq!(home_bar(m), Some(HomeBar::Elevation));
                m.update_access = Some(rebuilt(&["defender-enable"]));
                assert_eq!(home_bar(m), Some(HomeBar::UpdateAccess));
                // Left a setup with switches off.
                m.security_reminder = true;
                m.security = all_off();
                assert_eq!(home_bar(m), Some(HomeBar::Protection));
            });
        });
    }

    /// The setup card labels each question as the Install step's summary
    /// does, with the answer this PC has and not whether it was recommended,
    /// and keeps an option the package no longer offers among the extras.
    #[test]
    fn the_setup_card_lists_each_choice_under_its_question() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-setup-rows");
            let pc = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
            let model = installed_model(
                &mut cx,
                &temp,
                Some(&["defender-enable", "mitigations-default", "retired-option"]),
                pc,
            );
            model.update(&mut cx, |m, _| {
                let rows: Vec<SetupRow> = setup_rows(m).into_iter().map(|(row, _)| row).collect();
                let defender = rows.iter().find(|row| row.title == t!("screen-defender-title")).unwrap();
                assert!(defender.single);
                assert_eq!(defender.chosen, [describe::option_answer("defender-enable", "")]);
                assert_ne!(defender.chosen[0], describe::option_label("defender-enable", ""));
                let extras = rows.last().unwrap();
                assert_eq!(extras.title, t!("screen-extras-title"));
                assert!(!extras.single);
                assert!(extras.chosen.contains(&"retired-option".to_owned()), "{extras:?}");
                assert_eq!(rows.iter().filter(|row| !row.single).count(), 1, "one list of extras");
            });
        });
    }

    /// A PC without Atlas lists what happens in each install step, also on
    /// Windows that looks used, where the recommended ISO card comes first.
    /// A setup under way lists where each step stands, as the stepper does,
    /// and an installed Atlas lists none.
    #[test]
    fn home_lists_the_install_steps_until_atlas_is_installed() {
        use StepStatus::{Attention, Current, Done, Upcoming};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-steps-fresh");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            model.update(&mut cx, |m, cx| {
                assert_eq!(steps_card(m), Some(StepsCard::Ahead));
                assert!(!media_recommended(m));
                m.run_checks(cx);
            });
            until(&cx, &model, AppModel::checks_complete).await;
            model.update(&mut cx, |m, _| {
                m.package = Some(PackageSource {
                    dir: temp.path().to_path_buf(),
                    manifest: Manifest::builtin(),
                    origin: Origin::Unpacked,
                    archive: None,
                });
                m.flow.resume(Step::Options).unwrap();
                assert!(m.ready_to_continue());
                assert_eq!(steps_card(m), Some(StepsCard::UnderWay([Done, Current, Upcoming, Upcoming])));
                m.flow.resume(Step::Install).unwrap();
                assert_eq!(steps_card(m), Some(StepsCard::UnderWay([Done, Done, Done, Current])));
                // Get ready no longer holds: it needs attention, as on the stepper.
                m.package = None;
                assert_eq!(steps_card(m), Some(StepsCard::UnderWay([Attention, Done, Done, Current])));
            });

            let temp = TempDir::new("home-steps-used");
            let mut env = Machine::new(all_off()).environment(temp.path());
            env.adapters.read_windows_installation =
                Arc::new(|| Evidence { age_days: Some(400), desktop_apps: 12 });
            let model = new_model(&mut cx, env);
            until(&cx, &model, AppModel::windows_looks_used).await;
            model.update(&mut cx, |m, _| {
                assert!(media_recommended(m), "the ISO card comes first");
                assert_eq!(steps_card(m), Some(StepsCard::Ahead), "and the steps still follow it");
            });

            let temp = TempDir::new("home-steps-installed");
            let pc = Facts { packages: vec![NO_TELEMETRY.into()], ..Facts::default() };
            let model = installed_model(&mut cx, &temp, Some(&["mitigations-default"]), pc);
            model.update(&mut cx, |m, _| {
                assert_eq!(steps_card(m), None, "the setup card describes an installed Atlas");
                // Updating or reinstalling goes through the same four steps.
                m.flow.resume(Step::Security).unwrap();
                assert!(matches!(steps_card(m), Some(StepsCard::UnderWay([_, Done, Current, Upcoming]))));
            });
        });
    }

    /// Get ready says where it moves Windows when the package needs a newer
    /// version, and only then: an optional move is asked about on Get ready.
    /// Install says how long the package usually takes, and how it ends.
    #[test]
    fn the_install_steps_say_what_happens_on_this_pc() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("home-steps-details");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            model.update(&mut cx, |m, _| {
                let on = |build: u32, release: &str| SystemInfo {
                    display_version: release.into(),
                    build,
                    build_lab: format!("{build}.9550.amd64fre.ge_release.260918-1415"),
                    ..supported_system()
                };
                assert_eq!(step_detail(m, Step::Ready), t!("home-step-ready"));
                m.system = on(26100, "24H2");
                assert_eq!(step_detail(m, Step::Ready), t!("home-step-ready-move", release = "26H2"));
                m.system = on(26200, "25H2");
                assert!(m.windows_transition().is_some(), "25H2 may move, but doesn't have to");
                assert_eq!(step_detail(m, Step::Ready), t!("home-step-ready"));

                // Before a setup starts, as the Restart automatically setting says.
                let minutes = m.manifest().estimated_minutes;
                m.settings.restart_after_install = true;
                assert_eq!(
                    step_detail(m, Step::Install),
                    t!("home-step-install-restarts", minutes = minutes)
                );
                m.settings.restart_after_install = false;
                assert_eq!(
                    step_detail(m, Step::Install),
                    t!("home-step-install-restart-yourself", minutes = minutes)
                );
            });
        });
    }

    #[test]
    fn the_install_time_reads_for_one_minute_and_for_several() {
        crate::i18n::testing::english(|| {
            assert_eq!(
                t!("home-step-install-restarts", minutes = 1),
                "Installing usually takes about 1 minute, then your PC restarts."
            );
            assert_eq!(
                t!("home-step-install-restarts", minutes = 15),
                "Installing usually takes about 15 minutes, then your PC restarts."
            );
            assert_eq!(
                t!("home-step-install-restart-yourself", minutes = 15),
                "Installing usually takes about 15 minutes, then restart your PC."
            );
        });
    }

    /// Each step's accessible name says its number, its title and its sentence.
    #[test]
    fn a_step_is_named_with_its_sentence() {
        crate::i18n::testing::english(|| {
            let step = t!("home-step-a11y", number = 1, title = "Get ready");
            assert_eq!(
                t!("home-step-detail-a11y", step = step, detail = t!("home-step-ready")),
                "Step 1: Get ready. Atlas checks your PC and updates Windows."
            );
        });
    }
}
