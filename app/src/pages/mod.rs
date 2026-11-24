//! The app's pages. Shared layout helpers live here so every page frames
//! its content, headings and rows the same way, for the eye and for
//! assistive technology.

mod footer;
mod home;
mod install;
mod installed;
mod installing;
mod iso;
mod report;
mod settings;
mod stepper;
mod usb;

pub use footer::CommandBar;
pub use home::HomePage;
pub use install::InstallPage;
pub use installed::InstalledPage;
pub use installing::InstallingPage;
pub use iso::IsoPage;
pub use report::ReportPage;
pub use settings::SettingsPage;
pub use stepper::{StepStatus, Stepper};

use std::cell::Cell;
use std::path::{Path, PathBuf};
use std::rc::Rc;

use gpui::{
    AnyElement, App, ClickEvent, Context, Div, ElementId, Entity, FocusHandle, ParentElement, Role,
    ScrollHandle, SharedString, Stateful, Styled, Window, div, prelude::*, px, relative, rems,
};

use crate::i18n::describe;
use crate::model::{AppModel, InstallAttempt, Page, RunState, ScreenKind};
use crate::services::package::{Choice, ChoiceKind, ChoiceOption};
use crate::services::preparation::Drivers;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    BODY_LINE_HEIGHT, Button, COMPACT_INSET, CapCenteredText, CheckBox, FocusHandles, Icon, InfoBar,
    RadioGroup, RadioItem, Revealed, ScrollbarState, Severity, TextMark, Typography, a11y_text, card,
    focus_ring, icon_in_line, icon_in_line_sized, keyboard_scrolling, link_row, nested_scrollbar, scrollbar,
};

/// Horizontal page padding, matching Settings' content margin.
pub const PAGE_PADDING: f32 = 40.;
/// Widest the content column grows before it centres.
pub const CONTENT_MAX_WIDTH: f32 = 1000.;

/// A click handler that runs `action` on the model.
pub fn on_model(
    model: &Entity<AppModel>,
    action: impl Fn(&mut AppModel, &mut Context<AppModel>) + 'static,
) -> impl Fn(&ClickEvent, &mut Window, &mut App) + 'static {
    let model = model.clone();
    move |_, _, cx| model.update(cx, |model, cx| action(model, cx))
}

/// The button that opens the latest release in the browser, where the
/// newest Atlas Manager is downloaded. Atlas Manager can't update itself.
pub(super) fn manager_download_button(id: impl Into<ElementId>) -> Button {
    Button::new(id, t!("manager-download"))
        .trailing_icon(Icon::OpenInNewWindow)
        .opens(crate::services::system::links::LATEST_RELEASE)
}

/// The note, on Home and in Settings' About section, that a newer Atlas
/// Manager has been released, with the button that downloads it. It holds
/// nothing up. `key` prefixes its element ids.
pub(super) fn manager_update_bar(state: &AppModel, key: &str) -> Option<InfoBar> {
    let version = state.manager_update()?;
    Some(
        InfoBar::new(
            Severity::Informational,
            t!("manager-update-title", version = version),
            t!("manager-update-message"),
        )
        .id(ElementId::Name(format!("{key}-manager-update").into()))
        .action(manager_download_button(ElementId::Name(format!("{key}-manager-download").into()))),
    )
}

/// The page's back arrow, if it has one: where it leads, and whether it can be
/// used now. While navigation is blocked the arrow is drawn disabled rather
/// than left out, so the title keeps its place.
fn back_arrow_state(state: &AppModel) -> Option<(Page, bool)> {
    let drawn = match state.page {
        Page::Settings | Page::Report | Page::Iso => true,
        // Desktop setup has no Home to go back to.
        Page::Install => !state.before_desktop,
        Page::Home | Page::Installed => false,
    };
    let target = state.back_target();
    drawn.then(|| (target, state.can_navigate(target)))
}

/// Where the page's back arrow leads, while it can be used. Escape goes the
/// same way, so it does nothing where the arrow is missing or disabled.
pub fn back_arrow(state: &AppModel) -> Option<Page> {
    back_arrow_state(state).and_then(|(target, enabled)| enabled.then_some(target))
}

/// A page's help row: Send a report, Export diagnostics and, where a log
/// exists, Open log folder, as one compact row of links. It goes under an
/// unexpected failure, once per page, and under nothing the user can put
/// right themselves. It carries no privacy text: Send a report and the
/// export's result say what leaves the PC, where it does.
///
/// When an export ends while the page stays on screen and focus is still
/// where it was when the export started, focus moves to its result so the
/// outcome is announced.
pub struct Diagnostics {
    result: FocusHandle,
    watch: ExportWatch<FocusHandle>,
    /// Whether the controls are part of the frame being built.
    drawn: Cell<bool>,
    /// A failed export's raw error is showing.
    details: Rc<Cell<bool>>,
}

/// A folder the help row opens, after its other links.
struct FolderLink {
    id: &'static str,
    label: String,
    path: PathBuf,
    /// Made first if it doesn't exist yet, as the app's own folder may not.
    create: bool,
}

impl Diagnostics {
    pub fn new(cx: &App) -> Self {
        Self {
            result: cx.focus_handle(),
            watch: ExportWatch::default(),
            drawn: Cell::new(false),
            details: Rc::default(),
        }
    }

    /// The help row, inside a card, a bar or a row that already exists.
    pub fn content(&self, model: &Entity<AppModel>, cx: &App) -> Div {
        self.content_with_log(model, None, cx)
    }

    /// The help row with Open log folder for `log`, when there is one.
    pub fn content_with_log(&self, model: &Entity<AppModel>, log: Option<PathBuf>, cx: &App) -> Div {
        let folder = log.map(|path| FolderLink {
            id: "open-log-folder",
            label: t!("iso-diagnostics"),
            path,
            create: false,
        });
        self.content_with_folder(model, folder, cx)
    }

    /// The help row with Open app folder, for Settings.
    pub fn content_with_app_folder(&self, model: &Entity<AppModel>, path: PathBuf, cx: &App) -> Div {
        let folder =
            FolderLink { id: "open-app-folder", label: t!("settings-open-data-folder"), path, create: true };
        self.content_with_folder(model, Some(folder), cx)
    }

    fn content_with_folder(&self, model: &Entity<AppModel>, folder: Option<FolderLink>, cx: &App) -> Div {
        let repeated = self.drawn.replace(true);
        debug_assert!(!repeated, "diagnostics drawn twice in a frame, or `settle` was not called");
        diagnostics_content(model, &self.result, &self.details, folder, cx)
    }

    /// Call once per render, after the body is built. When the controls are
    /// on screen and an export has just ended, moves focus to its result.
    pub fn settle(&mut self, model: &Entity<AppModel>, window: &mut Window, cx: &mut App) {
        if !self.drawn.take() {
            return;
        }
        let state = model.read(cx);
        let now = (state.diagnostics_busy, state.page_visit, state.flow.run);
        if self.watch.ended(now, window.focused(cx)) {
            window.focus(&self.result, cx);
        }
    }
}

/// Follows a page's exports from one drawing of its diagnostics controls to
/// the next, to tell when a result may take focus.
struct ExportWatch<F> {
    /// Whether an export was running when the controls were last drawn, and
    /// the page visit and install state they were drawn in.
    seen: Option<(bool, u64, RunState)>,
    /// Where focus was when the running export started.
    origin: Option<F>,
}

impl<F> Default for ExportWatch<F> {
    fn default() -> Self {
        Self { seen: None, origin: None }
    }
}

impl<F: PartialEq> ExportWatch<F> {
    /// Records one drawing of `now` (busy, visit, install state) and the focus.
    /// True when an export just ended on the same visit and install state with
    /// focus still where it started, or nowhere. A new visit or install result
    /// moves focus itself, and a user who moved on keeps their place.
    fn ended(&mut self, now: (bool, u64, RunState), focused: Option<F>) -> bool {
        let before = self.seen.replace(now);
        let was_busy = before.is_some_and(|(busy, ..)| busy);
        if now.0 {
            if !was_busy {
                self.origin = focused;
            }
            return false;
        }
        let origin = self.origin.take();
        was_busy
            && before.is_some_and(|(_, visit, run)| (visit, run) == (now.1, now.2))
            && (focused.is_none() || focused == origin)
    }
}

fn diagnostics_content(
    model: &Entity<AppModel>,
    result_focus: &FocusHandle,
    details: &Rc<Cell<bool>>,
    folder: Option<FolderLink>,
    cx: &App,
) -> Div {
    let state = model.read(cx);
    let theme = cx.theme();
    let link = |id: &'static str, label: String| Button::new(id, label).hyperlink().compact();
    if state.diagnostics_busy {
        // The next result starts with its details folded.
        details.set(false);
    }
    div()
        .flex()
        .flex_col()
        .gap(px(8.))
        .child(
            link_row()
                .id("diagnostics-help")
                .role(Role::Group)
                .aria_label(t!("diagnostics-help-a11y"))
                // The installing view covers every page, so there is nowhere
                // to report from until the install is over.
                .when(!state.install_in_progress() && state.can_navigate(Page::Report), |this| {
                    this.child(
                        link("send-report", t!("report-title"))
                            .on_click(on_model(model, |m, cx| m.navigate(Page::Report, cx))),
                    )
                })
                // Its label stays while an export runs, so the row doesn't
                // move; the model ignores a click meanwhile, so the link
                // stays enabled and keeps focus.
                .child(
                    link("export-diagnostics", t!("diagnostics-export"))
                        .on_click(on_model(model, |m, cx| m.export_diagnostics(cx))),
                )
                .when_some(folder, |this, FolderLink { id, label, path, create }| {
                    this.child(link(id, label).on_click(move |_, _, cx| {
                        if create {
                            let _ = std::fs::create_dir_all(&path);
                        }
                        cx.reveal_path(&path);
                    }))
                }),
        )
        // Where the result will be: what's happening, as it happens.
        .when(state.diagnostics_busy, |this| {
            let text = t!("diagnostics-exporting");
            this.child(
                div()
                    .id("diagnostics-exporting")
                    .role(Role::Status)
                    .aria_label(text.clone())
                    .aria_live(gpui::Live::Polite)
                    .flex()
                    .items_center()
                    .gap(px(8.))
                    .child(
                        div().flex().items_center().h(BODY_LINE_HEIGHT).child(crate::ui::ProgressRing::new()),
                    )
                    .child(div().type_body().text_color(theme.text_secondary).child(text)),
            )
        })
        .when_some(state.diagnostics_result.as_ref().filter(|_| !state.diagnostics_busy), |this, result| {
            let bar = match result {
                // Where the ZIP is, and what it leaves out, where the user
                // decides what to do with it.
                Ok(path) => {
                    let message = [saved_location(path), t!("diagnostics-saved-privacy")].join("\n");
                    let path = path.clone();
                    InfoBar::new(Severity::Success, t!("diagnostics-saved"), message).action(
                        Button::new("diagnostics-reveal", t!("iso-open-folder"))
                            .icon(Icon::Folder)
                            .on_click(move |_, _, cx| cx.reveal_path(&path)),
                    )
                }
                // The title says what happened, Try again is what to do, and
                // the raw error is behind Show details.
                Err(error) => {
                    let title = t!("diagnostics-save-failed");
                    let shown = details.get();
                    let toggle = {
                        let details = details.clone();
                        let label = if shown { t!("common-hide-details") } else { t!("common-show-details") };
                        Button::new("diagnostics-details", label.clone())
                            .aria_label(t!("common-details-a11y", action = label, section = title.as_str()))
                            .expanded(shown)
                            .hyperlink()
                            .compact()
                            .trailing_icon(if shown { Icon::ChevronUp } else { Icon::ChevronDown })
                            .on_click(move |_, window, _| {
                                details.set(!details.get());
                                window.refresh();
                            })
                    };
                    let raw = shown.then(|| {
                        div()
                            .type_caption()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("diagnostics-error", error.clone()))
                    });
                    InfoBar::new(Severity::Error, title, "")
                        .action(
                            Button::new("diagnostics-retry", t!("common-try-again"))
                                .on_click(on_model(model, |m, cx| m.export_diagnostics(cx))),
                        )
                        .content(
                            div().flex().flex_col().gap(px(4.)).child(link_row().child(toggle)).children(raw),
                        )
                }
            };
            this.child(bar.id("diagnostics-result").focus_handle(result_focus.clone()))
        })
}

/// "Saved as <file> in Atlas's <folder> folder": the folder by its own name
/// alone, which Show in folder opens, so the text carries no path and no
/// user name.
fn saved_location(path: &Path) -> String {
    let name = |path: Option<&Path>| {
        path.and_then(Path::file_name).map(|name| name.to_string_lossy().into_owned()).unwrap_or_default()
    };
    t!("diagnostics-saved-in-folder", file = name(Some(path)), folder = name(path.parent()))
}

/// A page's title, with an optional badge after it.
pub struct PageTitle {
    pub text: SharedString,
    /// Such as Recommended: see [`badge`].
    pub badge: Option<SharedString>,
    /// A back arrow of the title's own, for a panel shown over its page: it
    /// goes back within the panel, or out of it, not off the page.
    pub back: Option<PanelBack>,
}

impl From<SharedString> for PageTitle {
    fn from(text: SharedString) -> Self {
        Self { text, badge: None, back: None }
    }
}

impl From<String> for PageTitle {
    fn from(text: String) -> Self {
        SharedString::from(text).into()
    }
}

/// What a back arrow does when it is chosen.
pub type BackHandler = Rc<dyn Fn(&mut Window, &mut App)>;

/// The back arrow of a panel: whether it can be used now, and what it does.
pub struct PanelBack {
    pub enabled: bool,
    pub on_back: BackHandler,
}

/// A page: optional fixed title row, then a scrolling body. `footer` stays pinned.
/// Everything sits in one centred column. The title row has a back arrow when
/// `back` is given and the page has one (see [`back_arrow`]), or when the title
/// brings a panel's own. `title_focus` lets the page move focus to its title
/// when it is shown, so the new page is announced.
#[allow(clippy::too_many_arguments)]
pub fn page_frame(
    id: &'static str,
    title: Option<PageTitle>,
    title_focus: Option<&FocusHandle>,
    back: Option<&Entity<AppModel>>,
    scroll: (&ScrollHandle, &ScrollbarState),
    body: impl IntoIterator<Item = AnyElement>,
    footer: Option<AnyElement>,
    cx: &App,
) -> Div {
    let theme = cx.theme();
    let column = || div().w_full().max_w(px(CONTENT_MAX_WIDTH)).px(px(PAGE_PADDING));
    let page_back = |model: &Entity<AppModel>| {
        back_arrow_state(model.read(cx)).map(|(target, enabled)| {
            let label = if target == Page::Home { t!("common-back-to-home") } else { t!("common-back") };
            let model = model.clone();
            let on_back: BackHandler =
                Rc::new(move |_, cx| model.update(cx, |m, cx| m.navigate(m.back_target(), cx)));
            (label, enabled, on_back)
        })
    };
    div()
        .flex()
        .flex_col()
        .size_full()
        .min_w_0()
        .when_some(title, |this, PageTitle { text, badge: badge_text, back: panel_back }| {
            let back = match panel_back {
                Some(PanelBack { enabled, on_back }) => Some((t!("common-back"), enabled, on_back)),
                None => back.and_then(page_back),
            };
            this.child(
                div().flex_shrink_0().flex().justify_center().child(
                    column()
                        .flex()
                        .items_center()
                        .gap(px(8.))
                        .pt(px(22.))
                        .pb(px(14.))
                        // The back arrow's glyph starts on the content's edge,
                        // and its hover fill reaches into the page margin, as a
                        // link's does in a link row.
                        .when(back.is_some(), |this| this.pl(px(PAGE_PADDING) - COMPACT_INSET))
                        .when_some(back, |this, (label, enabled, on_back)| {
                            this.child(
                                TextMark::new(
                                    Button::new("page-back", "")
                                        .aria_label(label)
                                        .subtle()
                                        .icon(Icon::Back)
                                        .disabled(!enabled)
                                        .on_click(move |_, window, cx| on_back(window, cx)),
                                    false,
                                )
                                .title(),
                            )
                        })
                        .child({
                            let id = ElementId::Name(format!("page-title-{id}").into());
                            match title_focus {
                                // The focus border sits outside the title's box,
                                // so the title keeps its place.
                                Some(focus) => focusable_heading(id, 1, text, focus, cx).m(px(-1.)),
                                None => heading(id, 1, text, cx),
                            }
                            // A long title wraps rather than pushing the badge out of view.
                            .min_w_0()
                        })
                        .when_some(badge_text, |this, text| {
                            this.child(TextMark::new(badge("page-badge", text, cx), false).title())
                        }),
                ),
            )
        })
        .child(
            div()
                .relative()
                .flex_1()
                .min_h_0()
                .child(
                    div()
                        .id(id)
                        .size_full()
                        .overflow_y_scroll()
                        .track_scroll(scroll.0)
                        .flex()
                        .flex_col()
                        .items_center()
                        .pb(px(32.))
                        .child(column().flex().flex_col().gap(px(12.)).children(body)),
                )
                .child(scrollbar(scroll.0, scroll.1)),
        )
        .when_some(footer, |this, footer| {
            this.child(
                div()
                    .flex_shrink_0()
                    .flex()
                    .justify_center()
                    .py(px(16.))
                    .border_t_1()
                    .border_color(theme.divider)
                    .child(column().child(footer)),
            )
        })
}

/// A Windows Settings card row: the setting's header, with an optional
/// description under it, on the left, and its control on the right,
/// vertically centred. When both don't fit (a narrow window, large text) the
/// control drops below the header, at its own width; it is never cut short.
/// `below` holds what belongs to the setting under the row, such as notes.
pub fn setting_row(
    cx: &App,
    key: &str,
    header: impl Into<SharedString>,
    description: Option<SharedString>,
    control: AnyElement,
    below: Vec<AnyElement>,
) -> Div {
    let theme = cx.theme();
    card(cx).child(
        div()
            .flex()
            .flex_col()
            .gap(px(8.))
            .p(px(16.))
            .min_h(px(68.))
            .justify_center()
            .child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(16.))
                    .gap_y(px(8.))
                    .child(
                        div()
                            .flex_1()
                            .min_w(px(180.))
                            .flex()
                            .flex_col()
                            .child(div().type_body().text_color(theme.text_primary).child(a11y_text(
                                ElementId::Name(format!("setting-{key}").into()),
                                header.into(),
                            )))
                            .when_some(description, |this, description| {
                                this.child(div().type_caption().text_color(theme.text_secondary).child(
                                    a11y_text(
                                        ElementId::Name(format!("setting-{key}-description").into()),
                                        description,
                                    ),
                                ))
                            }),
                    )
                    .child(div().flex_shrink_0().max_w_full().child(control)),
            )
            .children(below),
    )
}

/// A heading reported at `level`: 1 for the page title, 2 for a step heading
/// or a page's cards, 3 for the cards under a step.
pub fn heading(
    id: impl Into<ElementId>,
    level: usize,
    text: impl Into<SharedString>,
    cx: &App,
) -> Stateful<Div> {
    let theme = cx.theme();
    let text = text.into();
    div()
        .id(id)
        .role(Role::Heading)
        .aria_level(level)
        .aria_label(text.clone())
        .map(|this| if level == 1 { this.type_title() } else { this.type_body_strong() })
        .text_color(theme.text_primary)
        .child(text)
}

/// A heading that can take keyboard focus, so a page can announce a change
/// of step or result by moving focus to it.
pub fn focusable_heading(
    id: impl Into<ElementId>,
    level: usize,
    text: impl Into<SharedString>,
    focus: &FocusHandle,
    cx: &App,
) -> Stateful<Div> {
    let focus_outer = cx.theme().focus_outer;
    let transparent = cx.theme().transparent();
    heading(id, level, text, cx)
        .track_focus(&focus.clone().tab_stop(false))
        .rounded(px(4.))
        .border_1()
        .border_color(transparent)
        .focus_visible(move |style| style.border_color(focus_outer))
}

/// "Label     value" row used inside cards. `key` is a stable, language-
/// independent element id; the label and text values are readable by
/// assistive technology, and element values carry their own semantics.
pub fn detail_row(
    cx: &App,
    key: &str,
    label: impl Into<SharedString>,
    value: impl IntoElement,
) -> Stateful<Div> {
    detail_row_with_action(cx, key, label, value, None)
}

/// A [`detail_row`] with an action, such as Change, at the card's trailing
/// edge on the value's first line, so the actions of a list of rows line up
/// in one column. When the value would get narrower than about 10rem (large
/// text in a small window) the action wraps under it, still at the trailing
/// edge, as a Windows 11 settings card does.
pub fn detail_row_with_action(
    cx: &App,
    key: &str,
    label: impl Into<SharedString>,
    value: impl IntoElement,
    action: Option<AnyElement>,
) -> Stateful<Div> {
    let theme = cx.theme();
    let label = label.into();
    div()
        .id(ElementId::Name(format!("detail-{key}").into()))
        .role(Role::Group)
        .aria_label(label.clone())
        .flex()
        .items_start()
        .gap(px(16.))
        .py(px(4.))
        // Scales with the text size; capped so the value keeps room at the largest sizes.
        .child(
            div()
                .w(rems(140. / 16.))
                .max_w(relative(0.4))
                .flex_shrink_0()
                .type_body()
                .text_color(theme.text_secondary)
                .child(label),
        )
        .child(
            div()
                .flex_1()
                .min_w_0()
                .flex()
                .flex_wrap()
                .items_start()
                .gap_x(px(16.))
                .child(
                    div().flex_1().min_w(rems(10.)).type_body().text_color(theme.text_primary).child(value),
                )
                // The 24px compact link's text lines up with the 20px body
                // line, and takes no more height than it, so a row with an
                // action is as tall as one without.
                .when_some(action, |this, action| {
                    this.child(div().ml_auto().flex_shrink_0().mt(px(-2.)).mb(px(-2.)).child(action))
                }),
        )
}

/// A readable text value for `detail_row`, keyed like its row.
pub fn detail_text(key: &str, text: impl Into<SharedString>) -> gpui::Text {
    a11y_text(ElementId::Name(format!("detail-{key}-value").into()), text)
}

/// A card's title at the top of its body, for a card whose header would
/// carry nothing at its trailing edge: Body Strong, with the body's 8px gap
/// to what follows, as Windows titles a card in a confined space. `key` is a
/// stable element id for the heading, reported at `level`: 2 under a page
/// title, 3 under a step.
pub fn card_title(cx: &App, key: &str, title: impl Into<SharedString>, level: usize) -> Stateful<Div> {
    heading(ElementId::Name(format!("card-{key}").into()), level, title, cx)
}

/// A card header strip: the title on the left, `trailing` (a status pill, a
/// button or a link) on the right, and a divider under them. A card with
/// nothing to put there takes a [`card_title`] instead. `key` is a stable
/// element id for the heading, reported at level 2, under the page title.
pub fn card_header(cx: &App, key: &str, title: impl Into<SharedString>, trailing: AnyElement) -> Div {
    card_header_with_icon(cx, key, title, None, trailing, 2)
}

/// A [`card_header`] for a card under a step, reported at level 3: under
/// the step heading on ISO creation, and under the stepper's step on the
/// install steps.
pub fn step_card_header(cx: &App, key: &str, title: impl Into<SharedString>, trailing: AnyElement) -> Div {
    card_header_with_icon(cx, key, title, None, trailing, 3)
}

/// Optional decorative Segoe glyph; the heading keeps its original accessible
/// name. `level` is the heading level: 2 under a page title, 3 under a step.
pub fn card_header_with_icon(
    cx: &App,
    key: &str,
    title: impl Into<SharedString>,
    leading: Option<Icon>,
    trailing: AnyElement,
    level: usize,
) -> Div {
    let theme = cx.theme();
    let title = title.into();
    div()
        .flex()
        .items_center()
        .justify_between()
        .gap(px(12.))
        .px(px(16.))
        .py(px(12.))
        .border_b_1()
        .border_color(theme.divider)
        .child({
            let heading = heading(ElementId::Name(format!("card-{key}").into()), level, title, cx);
            match leading {
                Some(icon) => div()
                    .flex()
                    .items_center()
                    .gap(px(12.))
                    .child(
                        icon_in_line(icon, BODY_LINE_HEIGHT)
                            .type_body_strong()
                            .text_color(theme.text_primary),
                    )
                    .child(heading)
                    .into_any_element(),
                None => heading.into_any_element(),
            }
        })
        .child(trailing)
}

pub fn card_body() -> Div {
    div().flex().flex_col().gap(px(8.)).px(px(16.)).py(px(12.))
}

/// A pill naming a feature's status, such as Recommended. It is reported as text, so
/// screen readers read its words where they appear. Its caption stays regular:
/// Windows sets no text under 14px in semibold, which some scripts can't be
/// read in.
pub fn badge(id: impl Into<ElementId>, text: impl Into<SharedString>, cx: &App) -> Stateful<Div> {
    let theme = cx.theme();
    let text = text.into();
    div()
        .id(id)
        .role(Role::Label)
        .aria_value(text.clone())
        .flex()
        .flex_shrink_0()
        .items_center()
        .min_h(px(20.))
        .px(px(8.))
        .py(px(2.))
        .rounded_full()
        .type_caption()
        .map(|this| {
            if theme.high_contrast {
                this.text_color(theme.text_primary).border_1().border_color(theme.text_primary)
            } else {
                this.text_color(theme.success).bg(theme.success_fill)
            }
        })
        .child(CapCenteredText(text))
}

/// The options that leave a PC with less protection than Windows gives it.
/// Lists of choices mark them with a caution glyph and say what they mean.
const REDUCES_PROTECTION: [&str; 3] = ["defender-disable", "mitigations-disable", "disable-core-isolation"];

/// One line of a [`plain_list`]: its text, and a caution under it when the
/// line names a choice that reduces protection.
pub struct ListEntry {
    pub text: String,
    pub caution: Option<String>,
}

impl ListEntry {
    pub fn new(text: impl Into<String>) -> Self {
        Self { text: text.into(), caution: None }
    }

    /// An option of the Atlas package as an answer already given, by its id
    /// and the manifest's label: lists of choices are records and summaries,
    /// so a recommended answer doesn't say it's recommended.
    pub fn option(id: &str, label: &str) -> Self {
        Self { text: describe::option_answer(id, label), caution: caution(id) }
    }

    /// An option as the install on this PC will apply it: as [`Self::option`],
    /// and removing Microsoft Edge also says it deletes the user's Edge data,
    /// which an install before the desktop exists has none of.
    pub fn install_option(id: &str, label: &str, before_desktop: bool) -> Self {
        let mut entry = Self::option(id, label);
        if entry.caution.is_none() && !before_desktop {
            entry.caution = describe::data_caution(id);
        }
        entry
    }
}

/// What choosing option `id` means, when it reduces protection.
fn caution(id: &str) -> Option<String> {
    REDUCES_PROTECTION.contains(&id).then(|| describe::option_consequence(id)).flatten()
}

/// A caption beside a caution glyph: what a choice that reduces protection means.
pub fn caution_caption(cx: &App, text: impl IntoElement) -> Div {
    let theme = cx.theme();
    div()
        .flex()
        .items_start()
        .gap(px(6.))
        .type_caption()
        .text_color(theme.text_secondary)
        .child(icon_in_line_sized(Icon::Warning, 12., rems(1.)).type_caption().text_color(theme.caution))
        .child(div().flex_1().min_w_0().child(text))
}

/// How [`option_page_body`] reports an answer: the option chosen for a
/// single choice, or the option toggled for a multiple one.
pub type OptionChoice = Rc<dyn Fn(&str, &mut App)>;

/// What [`option_page_body`] says under one option. ISO creation and a first
/// install say what it means; choosing again on an update also says what it
/// changes on this PC, which answer the PC has, and why an option an update
/// can't undo is fixed.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct OptionNote {
    /// What choosing it means.
    pub consequence: Option<String>,
    /// What choosing it changes on this PC, said instead of what it means.
    pub change: Option<String>,
    /// This PC has it now.
    pub now: bool,
    /// Why it can't be changed; its box is disabled.
    pub fixed: Option<String>,
}

impl From<Option<String>> for OptionNote {
    fn from(consequence: Option<String>) -> Self {
        Self { consequence, ..Self::default() }
    }
}

impl OptionNote {
    /// The text under the option: why it is fixed, or else what it changes
    /// or means, after the tag that says the PC has it. A fixed option says
    /// that itself.
    fn description(&self) -> Option<String> {
        let line = self.fixed.clone().or_else(|| self.change.clone()).or_else(|| self.consequence.clone());
        if !self.now || self.fixed.is_some() {
            return line;
        }
        let tag = t!("option-now");
        Some(match line {
            Some(line) => format!("{tag}\n{line}"),
            None => tag,
        })
    }
}

/// The inside of one of the Atlas package's choices, under its heading in a
/// card body: `description`, its options with what each says under it, and
/// its "Learn more" link, 8px apart. `header` names a single choice's radio
/// group. `id` prefixes the element ids; `note` says what goes under an
/// option (see [`OptionNote`]); `on_choose` gets the option's id; `images` is
/// the unpacked package, for the browser logos.
#[allow(clippy::too_many_arguments)]
pub fn option_page_body<N: Into<OptionNote>>(
    cx: &mut App,
    id: &str,
    page_index: usize,
    choice: &Choice,
    header: String,
    description: Option<String>,
    selected: impl Fn(&str) -> bool,
    disabled: bool,
    focus: &mut FocusHandles,
    note: impl Fn(&ChoiceOption) -> N,
    on_choose: OptionChoice,
    images: Option<&Path>,
) -> Div {
    let theme = cx.theme().clone();
    let kind = ScreenKind::of_choice(choice);
    let title = kind.title();
    let mut body = div().flex().flex_col().gap(px(8.));
    if let Some(description) = description {
        body =
            body.child(div().type_body().text_color(theme.text_secondary).child(a11y_text(
                ElementId::Name(format!("{id}-description-{page_index}").into()),
                description,
            )));
    }
    match choice.kind {
        ChoiceKind::Single => {
            let items: Vec<RadioItem> = choice
                .options
                .iter()
                .map(|option| {
                    let key = format!("{id}-{page_index}-{}", option.id);
                    let handle = focus.get(&key, cx);
                    let mut item = RadioItem::new(
                        ElementId::Name(key.into()),
                        describe::option_label(&option.id, &option.label),
                        handle,
                    );
                    if kind == ScreenKind::Browser
                        && let Some(path) = images.and_then(|dir| option.image_path(dir))
                    {
                        item = item.image(path);
                    }
                    if let Some(text) = note(option).into().description() {
                        item = item.description(text);
                    }
                    item
                })
                .collect();
            let names: Vec<String> = choice.options.iter().map(|o| o.id.clone()).collect();
            let chosen = names.iter().position(|name| selected(name));
            body = body.child(
                RadioGroup::new(ElementId::Name(format!("{id}-group-{page_index}").into()), header.clone())
                    .items(items)
                    .selected(chosen)
                    .disabled(disabled)
                    .on_select(move |index, _, cx| {
                        if let Some(name) = names.get(index) {
                            on_choose(name, cx);
                        }
                    }),
            );
        }
        ChoiceKind::Multiple => {
            let mut group = div()
                .id(ElementId::Name(format!("{id}-group-{page_index}").into()))
                .role(Role::Group)
                .aria_label(title.clone())
                .flex()
                .flex_col()
                .gap(px(2.));
            for option in &choice.options {
                let name = option.id.clone();
                let choose = on_choose.clone();
                let mut checkbox = CheckBox::new(
                    ElementId::Name(format!("{id}-{page_index}-{}", option.id).into()),
                    describe::option_label(&option.id, &option.label),
                    selected(&option.id),
                )
                .map(|checkbox| match option.id.as_str() {
                    "install-toolbox" => checkbox.image("brand/toolbox.png"),
                    "install-eclean" => checkbox.image("brand/eclean.png"),
                    _ => checkbox,
                });
                let note = note(option).into();
                if let Some(text) = note.description() {
                    checkbox = checkbox.description(text);
                }
                let fixed = note.fixed.is_some();
                group = group
                    .child(checkbox.disabled(disabled || fixed).on_toggle(move |_, _, cx| choose(&name, cx)));
            }
            body = body.child(group);
        }
    }
    if let Some(link) = &choice.learn_more {
        body = body.child(
            link_row().child(
                Button::new(ElementId::Name(format!("{id}-learn-{page_index}").into()), kind.learn_more())
                    .hyperlink()
                    .compact()
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(link.clone()),
            ),
        );
    }
    body
}

pub fn driver_label(drivers: Drivers) -> String {
    match drivers {
        Drivers::Automatic => t!("prepare-drivers-auto"),
        Drivers::Manual => t!("prepare-drivers-manual"),
    }
}

/// The two driver policies, in the order both driver pickers show them. The
/// recommended one says so in its label, where the choice is made.
pub fn driver_radio_items(id: &str, focus: &mut FocusHandles, cx: &mut App) -> [RadioItem; 2] {
    let (auto, manual) = (format!("{id}-auto"), format!("{id}-manual"));
    [
        RadioItem::new(auto.clone(), t!("prepare-drivers-auto-recommended"), focus.get(&auto, cx))
            .description(t!("prepare-drivers-auto-detail")),
        RadioItem::new(manual.clone(), driver_label(Drivers::Manual), focus.get(&manual, cx))
            .description(t!("prepare-drivers-manual-detail")),
    ]
}

/// Stable element ids for one log view, so two views on one page never share state.
#[derive(Clone, Copy)]
pub struct LogIds {
    pub log: &'static str,
    pub hidden: &'static str,
    pub line: &'static str,
    pub copy: &'static str,
    pub open: &'static str,
}

/// Copy and Open log folder, for the log view `ids` belongs to. The folder
/// opens with the log selected.
pub fn log_actions(model: &Entity<AppModel>, ids: LogIds, cx: &App) -> Div {
    let has_log = model.read(cx).session.is_some();
    div()
        .flex()
        .gap(px(8.))
        .child(
            Button::new(ids.copy, t!("common-copy"))
                .compact()
                .icon(Icon::Copy)
                .aria_label(t!("common-copy-install-log"))
                .on_click(on_model(model, |m, cx| m.copy_log(cx))),
        )
        .child(
            Button::new(ids.open, t!("common-open-log-folder"))
                .compact()
                .icon(Icon::Folder)
                .disabled(!has_log)
                .on_click(on_model(model, |m, cx| m.reveal_log(cx))),
        )
}

/// The install log as every page shows it: the last lines of the installer's
/// raw output (never translated), reported as a log region, that follows new
/// output only while the reader is already at the bottom. The lines are
/// shared with the model, not copied per frame.
pub struct LogView {
    pub scroll: ScrollHandle,
    pub scrollbar: ScrollbarState,
    total_seen: usize,
}

impl Default for LogView {
    fn default() -> Self {
        Self { scroll: ScrollHandle::new(), scrollbar: ScrollbarState::new(), total_seen: 0 }
    }
}

impl LogView {
    pub fn render(
        &mut self,
        ids: LogIds,
        max_height: f32,
        lines_shown: usize,
        attempt: &InstallAttempt,
        cx: &App,
    ) -> AnyElement {
        let theme = cx.theme();
        let (focus_outer, focus_inner) = (theme.focus_outer, theme.focus_inner);
        let total = attempt.log_total;
        let start = attempt.log.len().saturating_sub(lines_shown);
        let shown = &attempt.log[start..];
        let hidden = total.saturating_sub(shown.len());
        // Follow new output only while the view is already at the bottom;
        // a user reading earlier lines keeps their place.
        if total != self.total_seen {
            let offset = self.scroll.offset().y;
            let max = self.scroll.max_offset().y;
            let at_bottom = self.total_seen == 0 || (-offset) >= max - px(24.);
            self.total_seen = total;
            if at_bottom {
                self.scroll.scroll_to_bottom();
            }
        }
        // A tab stop, so the log can be scrolled from the keyboard.
        let log = div()
            .id(ids.log)
            .role(Role::Log)
            .aria_label(t!("common-install-log"))
            .key_context("Log")
            .tab_index(0)
            .rounded(px(4.))
            .border_1()
            .border_color(theme.transparent())
            .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
            .max_h(px(max_height))
            .overflow_y_scroll()
            .track_scroll(&self.scroll)
            // The focus ring's 1px border comes out of the padding.
            .px(px(15.))
            .py(px(11.))
            .type_mono()
            .text_color(theme.text_primary)
            .when(hidden > 0, |this| {
                this.child(
                    div()
                        .text_color(theme.text_secondary)
                        .child(a11y_text(ids.hidden, t!("log-earlier-lines", count = hidden))),
                )
            })
            .children(shown.iter().enumerate().map(|(index, line)| {
                div().w_full().min_w_0().child(a11y_text((ids.line, start + index), line.clone()))
            }));
        div()
            .relative()
            .child(Revealed::new(keyboard_scrolling(log, &self.scroll)))
            .child(nested_scrollbar(&self.scroll, &self.scrollbar))
            .into_any_element()
    }
}

/// A list read as text, one entry per line. Entries that reduce protection
/// carry their caution as a caption, and as the item's description.
pub fn plain_list(cx: &App, id: impl Into<ElementId>, label: &str, entries: Vec<ListEntry>) -> Stateful<Div> {
    let theme = cx.theme();
    let count = entries.len();
    div()
        .id(id)
        .role(Role::List)
        .aria_label(label.to_owned())
        .aria_size_of_set(count)
        .flex()
        .flex_col()
        .min_w_0()
        .gap(px(4.))
        .children(entries.into_iter().enumerate().map(|(index, entry)| {
            div()
                .id(("entry", index))
                .role(Role::ListItem)
                .aria_label(entry.text.clone())
                .when_some(entry.caution.clone(), |this, caution| this.aria_description(caution))
                // AccessKit counts from 0 and takes the size from the list.
                .aria_position_in_set(index)
                .flex()
                .flex_col()
                .gap(px(2.))
                .child(div().type_body().text_color(theme.text_primary).child(entry.text))
                .when_some(entry.caution, |this, caution| this.child(caution_caption(cx, caution)))
        }))
}

/// Builds the model the page tests read: what the PC has and the built-in
/// package, set as the model would have read them.
#[cfg(test)]
pub(crate) mod testing {
    use gpui::{AsyncApp, Entity};

    use crate::model::test_harness::{Machine, all_off, new_model};
    use crate::model::{AppModel, Origin, PackageSource};
    use crate::services::atlas_state::{AtlasState, InstallIdentity};
    use crate::services::legacy_choices::Facts;
    use crate::services::package::Manifest;
    use crate::services::test_support::TempDir;
    use crate::services::update_access::{Carry, Rebuild, UpdateAccess, parse_journal};

    /// Atlas's NoDefender servicing package, installed.
    pub(crate) const NO_DEFENDER: &str = "Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0";
    pub(crate) const NO_TELEMETRY: &str = "Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0";

    /// A completed install of `version` whose record says it chose `options`.
    pub(crate) fn recorded(version: &str, options: &[&str]) -> AtlasState {
        serde_json::from_value(serde_json::json!({
            "schemaVersion": 1, "installedVersion": version, "installedAt": "2026-10-30T18:00:00+00:00",
            "mode": "Reapply", "options": options,
        }))
        .unwrap()
    }

    /// Toggle records, by name.
    pub(crate) fn records(records: &[(&str, u32)]) -> std::collections::HashMap<String, u32> {
        records.iter().map(|(name, state)| ((*name).to_owned(), *state)).collect()
    }

    /// The record of a move to 26H2 during which Windows reinstalled itself,
    /// keeping an Atlas 0.5.0 install whose choices showed `options`. It kept
    /// no toggle records, so no Mitigations choice stands.
    pub(crate) fn rebuilt(options: &[&str]) -> UpdateAccess {
        let journal = serde_json::json!({
            "schema": 1, "kind": "transition", "phase": "on-target",
            "source": { "build": 26100, "ubr": 9550, "displayVersion": "24H2", "editionId": "Professional" },
            "target": { "release": "26H2", "build": 26300, "kb": "5121794" },
            "createdAt": "2026-10-01T15:41:43Z",
        });
        let mut journal = parse_journal(&journal.to_string()).unwrap();
        journal.rebuild = Some(Rebuild { rebuilt: true, signals: vec!["packages-missing".into()] });
        journal.carry = Some(Carry {
            atlas_version: Some("0.5.0".into()),
            options: options.iter().map(|option| (*option).to_owned()).collect(),
            option_source: "observed".into(),
            edge: false,
            toggles: Vec::new(),
        });
        UpdateAccess { journal: Some(journal), ..UpdateAccess::default() }
    }

    /// A model on a PC with Atlas 0.6.0 installed, whose record says it
    /// chose `options` (none: no record), and which shows `facts`.
    pub(crate) fn installed_model(
        cx: &mut AsyncApp,
        temp: &TempDir,
        options: Option<&[&str]>,
        facts: Facts,
    ) -> Entity<AppModel> {
        let model = new_model(cx, Machine::new(all_off()).environment(temp.path()));
        model.update(cx, |m, _| {
            let manifest = Manifest::builtin();
            m.install_identity = Ok(InstallIdentity::Installed(manifest.version.clone()));
            m.atlas = Ok(options.map(|options| recorded(&manifest.version, options)));
            m.pc_facts = facts;
            m.package = Some(PackageSource {
                dir: temp.path().to_path_buf(),
                manifest,
                origin: Origin::Unpacked,
                archive: None,
            });
        });
        model
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const VISIT: u64 = 3;

    /// The tag goes on a line of its own above what the option means or
    /// changes; a fixed option says why it's fixed, which says the PC has it.
    #[test]
    fn an_option_on_this_pc_is_tagged_above_its_line() {
        crate::i18n::testing::english(|| {
            let tag = t!("option-now");
            let note = |now, fixed: Option<&str>, change: Option<&str>| OptionNote {
                consequence: Some("means".into()),
                change: change.map(str::to_owned),
                now,
                fixed: fixed.map(str::to_owned),
            };
            assert_eq!(OptionNote::from(Some("means".to_owned())).description().as_deref(), Some("means"));
            assert_eq!(OptionNote::default().description(), None);
            assert_eq!(note(false, None, Some("changes")).description().as_deref(), Some("changes"));
            assert_eq!(note(true, None, None).description(), Some(format!("{tag}\nmeans")));
            assert_eq!(note(true, None, Some("changes")).description(), Some(format!("{tag}\nchanges")));
            assert_eq!(note(true, Some("fixed"), Some("changes")).description().as_deref(), Some("fixed"));
            let alone = OptionNote { now: true, ..OptionNote::default() };
            assert_eq!(alone.description(), Some(tag));
        });
    }

    fn drawn(busy: bool) -> (bool, u64, RunState) {
        (busy, VISIT, RunState::Idle)
    }

    #[test]
    fn a_finished_export_takes_focus_only_from_where_it_started() {
        // Still on Export, or with nothing focused: the result is announced.
        let mut watch = ExportWatch::default();
        assert!(!watch.ended(drawn(false), Some("export")));
        assert!(!watch.ended(drawn(true), Some("export")));
        assert!(!watch.ended(drawn(true), Some("export")));
        assert!(watch.ended(drawn(false), Some("export")));
        assert!(!watch.ended(drawn(false), Some("result")), "only once");
        assert!(!watch.ended(drawn(true), Some("export")));
        assert!(watch.ended(drawn(false), None));

        // Typing a name meanwhile keeps focus in the field.
        assert!(!watch.ended(drawn(true), Some("export")));
        assert!(!watch.ended(drawn(true), Some("username")));
        assert!(!watch.ended(drawn(false), Some("username")));
    }

    #[test]
    fn the_back_arrow_stays_in_place_while_navigation_is_blocked() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("back-arrow");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            model.update(&mut cx, |m, _| {
                m.page = Page::Iso;
                assert_eq!(back_arrow_state(m), Some((Page::Home, true)));
                assert_eq!(back_arrow(m), Some(Page::Home));
                // A build keeps the window here: the arrow stays, disabled, and Escape does nothing.
                m.iso_busy = true;
                assert_eq!(back_arrow_state(m), Some((Page::Home, false)));
                assert_eq!(back_arrow(m), None);
                m.iso_busy = false;

                m.page = Page::Home;
                assert_eq!(back_arrow_state(m), None);
                // Desktop setup has nowhere to go back to.
                m.page = Page::Install;
                m.before_desktop = true;
                assert_eq!(back_arrow_state(m), None);
            });
        });
    }

    #[test]
    fn only_choices_that_reduce_protection_carry_a_caution() {
        crate::i18n::testing::english(|| {
            let manifest = crate::services::package::Manifest::builtin();
            let mut cautions = Vec::new();
            for option in manifest.choices.iter().flat_map(|choice| &choice.options) {
                if ListEntry::option(&option.id, &option.label).caution.is_some() {
                    cautions.push(option.id.as_str());
                }
            }
            assert_eq!(cautions, REDUCES_PROTECTION);
            // The id decides, whatever the manifest's English says; an id this app
            // doesn't know is shown as the manifest has it, with no caption.
            let known = ListEntry::option("defender-disable", "Pause Defender");
            assert_eq!(known.text, t!("package-option-defender-disable"));
            assert!(known.caution.is_some());
            let unknown = ListEntry::option("pause-defender", "Pause Defender");
            assert_eq!((unknown.text.as_str(), unknown.caution), ("Pause Defender", None));
        });
    }

    #[test]
    fn a_result_shown_later_does_not_take_focus() {
        // The controls were hidden (details collapsed) while the export
        // ended; showing them again took focus to the toggle.
        let mut watch = ExportWatch::default();
        watch.ended(drawn(false), Some("export"));
        watch.ended(drawn(true), Some("export"));
        assert!(!watch.ended(drawn(false), Some("show-details")));

        // Another visit, or the install state changing, is not announced.
        watch.ended(drawn(true), Some("export"));
        assert!(!watch.ended((false, VISIT + 1, RunState::Idle), Some("export")));
        watch.ended(drawn(true), Some("export"));
        assert!(!watch.ended((false, VISIT, RunState::Running), Some("export")));
    }
}
