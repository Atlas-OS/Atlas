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
use std::path::Path;
use std::rc::Rc;

use gpui::{
    AnyElement, App, ClickEvent, Context, Div, ElementId, Entity, FocusHandle, ParentElement, Role,
    ScrollHandle, SharedString, Stateful, Styled, Window, div, prelude::*, px, relative, rems,
};

use crate::i18n::describe;
use crate::model::{AppModel, InstallAttempt, Page, RunState, ScreenKind};
use crate::services::playbook::{FeatureOption, FeaturePage, PageKind};
use crate::services::preparation::Drivers;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    BODY_LINE_HEIGHT, Button, CapCenteredText, CheckBox, FocusHandles, Icon, InfoBar, RadioGroup, RadioItem,
    Revealed, ScrollbarState, Severity, TextMark, Typography, a11y_text, card, focus_ring, icon_in_line,
    icon_in_line_sized, keyboard_scrolling, nested_scrollbar, scrollbar,
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

/// A page's diagnostics controls, which can go anywhere on the page, once.
/// When an export ends while the page stays on screen and focus is still
/// where it was when the export started, focus moves to its result so the
/// outcome is announced.
pub struct Diagnostics {
    result: FocusHandle,
    watch: ExportWatch<FocusHandle>,
    /// Whether the controls are part of the frame being built.
    drawn: Cell<bool>,
}

impl Diagnostics {
    pub fn new(cx: &App) -> Self {
        Self { result: cx.focus_handle(), watch: ExportWatch::default(), drawn: Cell::new(false) }
    }

    /// The controls in a card of their own.
    pub fn panel(&self, model: &Entity<AppModel>, cx: &App) -> Div {
        card(cx).p(px(16.)).child(self.content(model, cx))
    }

    /// The controls, for a card or section that already exists.
    pub fn content(&self, model: &Entity<AppModel>, cx: &App) -> Div {
        let repeated = self.drawn.replace(true);
        debug_assert!(!repeated, "diagnostics drawn twice in a frame, or `settle` was not called");
        diagnostics_content(model, &self.result, cx)
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

fn diagnostics_content(model: &Entity<AppModel>, result_focus: &FocusHandle, cx: &App) -> Div {
    let state = model.read(cx);
    div()
        .flex()
        .flex_col()
        .gap(px(8.))
        .child(
            div()
                .flex()
                .flex_wrap()
                .items_center()
                .gap(px(12.))
                .child(
                    div()
                        .flex_1()
                        .min_w(px(180.))
                        .type_caption()
                        .text_color(cx.theme().text_secondary)
                        .child(a11y_text("diagnostics-privacy", t!("diagnostics-privacy"))),
                )
                .child(
                    div()
                        .flex()
                        .flex_wrap()
                        .gap(px(8.))
                        // The installing view covers every page, so there is
                        // nowhere to report from until the install is over.
                        .when(!state.install_in_progress(), |this| {
                            this.child(
                                Button::new("send-report", t!("report-title"))
                                    .disabled(!state.can_navigate(Page::Report))
                                    .on_click(on_model(model, |m, cx| m.navigate(Page::Report, cx))),
                            )
                        })
                        .child(
                            Button::new(
                                "export-diagnostics",
                                if state.diagnostics_busy {
                                    t!("diagnostics-exporting")
                                } else {
                                    t!("diagnostics-export")
                                },
                            )
                            .icon(Icon::Diagnostic)
                            // The model ignores a click while an export runs, so
                            // the button stays enabled and keeps focus.
                            .on_click(on_model(model, |m, cx| m.export_diagnostics(cx))),
                        ),
                ),
        )
        .when_some(state.diagnostics_result.as_ref(), |this, result| {
            let bar = match result {
                Ok(path) => {
                    let path = path.clone();
                    InfoBar::new(Severity::Success, t!("diagnostics-saved"), "").action(
                        Button::new("diagnostics-reveal", t!("iso-open-folder"))
                            .icon(Icon::Folder)
                            .on_click(move |_, _, cx| cx.reveal_path(&path)),
                    )
                }
                // Export diagnostics, just above, is the retry.
                Err(error) => InfoBar::new(
                    Severity::Error,
                    t!("diagnostics-failed-title"),
                    t!("diagnostics-failed", error = error.as_str()),
                ),
            };
            this.child(bar.id("diagnostics-result").focus_handle(result_focus.clone()))
        })
}

/// A page's title, with an optional badge after it.
pub struct PageTitle {
    pub text: SharedString,
    /// Such as Beta: see [`badge`].
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
                    .py(px(14.))
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
                // The 24px compact link's text lines up with the 20px body line.
                .when_some(action, |this, action| {
                    this.child(div().ml_auto().flex_shrink_0().mt(px(-2.)).child(action))
                }),
        )
}

/// A readable text value for `detail_row`, keyed like its row.
pub fn detail_text(key: &str, text: impl Into<SharedString>) -> gpui::Text {
    a11y_text(ElementId::Name(format!("detail-{key}-value").into()), text)
}

/// A card header: title on the left, optional trailing element on the right.
/// `key` is a stable element id for the heading, reported at level 2, under
/// the page title.
pub fn card_header(cx: &App, key: &str, title: impl Into<SharedString>, trailing: Option<AnyElement>) -> Div {
    card_header_with_icon(cx, key, title, None, trailing, 2)
}

/// A [`card_header`] under a step heading ("Step 1 of 4: Get ready"), so
/// it's reported at level 3 and heading navigation follows the outline.
pub fn step_card_header(
    cx: &App,
    key: &str,
    title: impl Into<SharedString>,
    trailing: Option<AnyElement>,
) -> Div {
    card_header_with_icon(cx, key, title, None, trailing, 3)
}

/// Optional decorative Segoe glyph; the heading keeps its original accessible
/// name. `level` is the heading level: 2 under a page title, 3 under a step.
pub fn card_header_with_icon(
    cx: &App,
    key: &str,
    title: impl Into<SharedString>,
    leading: Option<Icon>,
    trailing: Option<AnyElement>,
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
        .when_some(trailing, |this, trailing| this.child(trailing))
}

pub fn card_body() -> Div {
    div().flex().flex_col().gap(px(8.)).px(px(16.)).py(px(12.))
}

/// A pill naming a feature's status, such as Beta. It is reported as text, so
/// screen readers read its words where they appear.
pub fn badge(id: impl Into<ElementId>, text: impl Into<SharedString>, cx: &App) -> Stateful<Div> {
    let theme = cx.theme();
    let text = text.into();
    // Violet on a tint of itself: apart from the accent and status colours, so
    // the badge never reads as a control or a warning.
    let violet: gpui::Hsla = gpui::rgb(if theme.is_dark() { 0xC4B5FD } else { 0x6941A5 }).into();
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
        .font_weight(gpui::FontWeight::SEMIBOLD)
        .map(|this| {
            if theme.high_contrast {
                this.text_color(theme.text_primary).border_1().border_color(theme.text_primary)
            } else {
                this.text_color(violet).bg(violet.opacity(if theme.is_dark() { 0.12 } else { 0.10 }))
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

    /// An option of the Atlas package, by its name and the package's own text.
    pub fn option(name: &str, package_text: &str) -> Self {
        Self { text: describe::option_label(name, package_text), caution: caution(name, package_text) }
    }

    /// An option as the install on this PC will apply it: as [`Self::option`],
    /// and removing Microsoft Edge also says it deletes the user's Edge data,
    /// which an install before the desktop exists has none of.
    pub fn install_option(name: &str, package_text: &str, before_desktop: bool) -> Self {
        let mut entry = Self::option(name, package_text);
        if entry.caution.is_none() && !before_desktop {
            entry.caution = describe::known_data_caution(name, package_text);
        }
        entry
    }
}

/// What choosing `name` means, when it reduces protection and its text is
/// the wording this app knows.
fn caution(name: &str, package_text: &str) -> Option<String> {
    REDUCES_PROTECTION
        .contains(&name)
        .then(|| describe::known_option_consequence(name, package_text))
        .flatten()
}

/// The options an install recorded, as this app labels them.
pub fn recorded_options(state: &AppModel, names: &[String]) -> Vec<ListEntry> {
    names
        .iter()
        .map(|name| match state.option_text(name) {
            Some(text) => ListEntry::option(name, text),
            None => ListEntry::new(name.as_str()),
        })
        .collect()
}

/// The options of an install as a list, or "None" when there are none.
pub fn options_value(cx: &App, key: &str, list_id: &'static str, options: Vec<ListEntry>) -> AnyElement {
    if options.is_empty() {
        div()
            .text_color(cx.theme().text_secondary)
            .child(detail_text(key, t!("common-none")))
            .into_any_element()
    } else {
        plain_list(cx, list_id, &t!("common-options"), options).into_any_element()
    }
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

/// How [`option_page_card`] reports a choice: the option chosen on a radio
/// page, or the option toggled on a checkbox page.
pub type OptionChoice = Rc<dyn Fn(&str, &mut App)>;

/// One page of the Atlas package's choices as a card, as the install flow
/// and ISO creation both show it: the header (the question, or the page's
/// title), a divider, the page's description, the choices with what each
/// means, and its "Learn more" link. `id` prefixes the element ids;
/// `consequence` words what an option means; `on_choose` gets the option's
/// name; `images` is the unpacked package, for the browser logos.
#[allow(clippy::too_many_arguments)]
pub fn option_page_card(
    cx: &mut App,
    id: &str,
    page_index: usize,
    page: &FeaturePage,
    header: String,
    selected: impl Fn(&str) -> bool,
    disabled: bool,
    focus: &mut FocusHandles,
    consequence: impl Fn(&FeatureOption) -> Option<String>,
    on_choose: OptionChoice,
    images: Option<&Path>,
) -> AnyElement {
    let theme = cx.theme().clone();
    let kind = ScreenKind::of_page(page);
    let title = kind.title();
    let mut body = card_body().gap(px(2.));
    if let Some(description) = describe::page_description(page) {
        body =
            body.child(div().type_body().text_color(theme.text_secondary).pb(px(4.)).child(a11y_text(
                ElementId::Name(format!("{id}-description-{page_index}").into()),
                description,
            )));
    }
    match page.kind {
        PageKind::Radio => {
            let items: Vec<RadioItem> = page
                .options
                .iter()
                .map(|option| {
                    let key = format!("{id}-{page_index}-{}", option.name);
                    let handle = focus.get(&key, cx);
                    let mut item = RadioItem::new(
                        ElementId::Name(key.into()),
                        describe::option_label(&option.name, &option.text),
                        handle,
                    );
                    if kind == ScreenKind::Browser
                        && let Some(path) = images.and_then(|dir| option.image_path(dir))
                    {
                        item = item.image(path);
                    }
                    if let Some(text) = consequence(option) {
                        item = item.description(text);
                    }
                    item
                })
                .collect();
            let names: Vec<String> = page.options.iter().map(|o| o.name.clone()).collect();
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
        PageKind::Checkbox => {
            let mut group = div()
                .id(ElementId::Name(format!("{id}-group-{page_index}").into()))
                .role(Role::Group)
                .aria_label(title.clone())
                .flex()
                .flex_col()
                .gap(px(2.));
            for option in &page.options {
                let name = option.name.clone();
                let choose = on_choose.clone();
                let mut checkbox = CheckBox::new(
                    ElementId::Name(format!("{id}-{page_index}-{}", option.name).into()),
                    describe::option_label(&option.name, &option.text),
                    selected(&option.name),
                )
                .map(|checkbox| match option.name.as_str() {
                    "install-toolbox" => checkbox.image("brand/toolbox.png"),
                    "install-eclean" => checkbox.image("brand/eclean.png"),
                    _ => checkbox,
                });
                if let Some(text) = consequence(option) {
                    checkbox = checkbox.description(text);
                }
                group = group.child(checkbox.disabled(disabled).on_toggle(move |_, _, cx| choose(&name, cx)));
            }
            body = body.child(group);
        }
    }
    if let Some(link) = &page.learn_more {
        body = body.child(
            div().flex().pt(px(6.)).child(
                Button::new(ElementId::Name(format!("{id}-learn-{page_index}").into()), kind.learn_more())
                    .hyperlink()
                    .compact()
                    .trailing_icon(Icon::OpenInNewWindow)
                    .opens(link.url.clone()),
            ),
        );
    }
    card(cx)
        .child(step_card_header(cx, &format!("{id}-page-{page_index}"), header, None))
        .child(body)
        .into_any_element()
}

/// The driver policy choice, as Get ready and the ISO page offer it. `id`
/// names the group; its items are `{id}-auto` and `{id}-manual`.
pub fn drivers_radio(
    id: &str,
    selected: Drivers,
    focus: &mut FocusHandles,
    cx: &mut App,
    on_select: impl Fn(Drivers, &mut App) + 'static,
) -> RadioGroup {
    let (auto, manual) = (format!("{id}-auto"), format!("{id}-manual"));
    let items = [
        RadioItem::new(auto.clone(), t!("prepare-drivers-auto"), focus.get(&auto, cx))
            .description(t!("prepare-drivers-auto-detail")),
        RadioItem::new(manual.clone(), t!("prepare-drivers-manual"), focus.get(&manual, cx))
            .description(t!("prepare-drivers-manual-detail")),
    ];
    RadioGroup::new(id.to_owned(), t!("prepare-drivers"))
        .items(items)
        .selected(Some(usize::from(selected == Drivers::Manual)))
        .on_select(move |index, _, cx| {
            on_select(if index == 0 { Drivers::Automatic } else { Drivers::Manual }, cx)
        })
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

/// Copy and Open log file, for the log view `ids` belongs to.
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
            Button::new(ids.open, t!("common-open-log-file"))
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

#[cfg(test)]
mod tests {
    use super::*;

    const VISIT: u64 = 3;

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
            let manifest = crate::services::playbook::Manifest::builtin();
            let mut cautions = Vec::new();
            for option in manifest.pages.iter().flat_map(|page| &page.options) {
                if ListEntry::option(&option.name, &option.text).caution.is_some() {
                    cautions.push(option.name.as_str());
                }
            }
            assert_eq!(cautions, REDUCES_PROTECTION);
            // Wording this app doesn't know is shown as the package has it, with no caption.
            assert_eq!(ListEntry::option("defender-disable", "Pause Defender").caution, None);
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
