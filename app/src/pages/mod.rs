//! The three pages: Home, the install flow and Settings. Shared layout
//! helpers live here so every page frames its content, headings and rows the
//! same way, for the eye and for assistive technology.

mod home;
mod install;
mod installed;
mod installing;
mod iso;
mod settings;
mod usb;

pub use home::HomePage;
pub use install::InstallPage;
pub use installed::InstalledPage;
pub use installing::InstallingPage;
pub use iso::IsoPage;
pub use settings::SettingsPage;

use gpui::{
    AnyElement, App, Div, ElementId, Entity, FocusHandle, ParentElement, Role, ScrollHandle, SharedString,
    Stateful, Styled, div, prelude::*, px,
};

use crate::model::{AppModel, InstallAttempt, Page};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{Button, Icon, ScrollbarState, Typography, a11y_text, scrollbar};

/// Horizontal page padding, matching Settings' content margin.
pub const PAGE_PADDING: f32 = 40.;
/// Widest the content column grows before it centres.
pub const CONTENT_MAX_WIDTH: f32 = 1000.;

/// A page: optional fixed title row (with a back button when `back` is given), then a
/// scrolling body. `footer` stays pinned. Everything sits in one centred column.
pub fn page_frame(
    id: &'static str,
    title: Option<SharedString>,
    back: Option<&Entity<AppModel>>,
    scroll: (&ScrollHandle, &ScrollbarState),
    body: impl IntoIterator<Item = AnyElement>,
    footer: Option<AnyElement>,
    cx: &App,
) -> Div {
    let theme = cx.theme();
    let column = || div().w_full().max_w(px(CONTENT_MAX_WIDTH)).px(px(PAGE_PADDING));
    let back = back.cloned();
    div()
        .flex()
        .flex_col()
        .size_full()
        .min_w_0()
        .when_some(title, |this, title| {
            this.child(
                div().flex_shrink_0().flex().justify_center().child(
                    column()
                        .flex()
                        .items_center()
                        .gap(px(8.))
                        .pt(px(22.))
                        .pb(px(14.))
                        .when_some(back, |this, model| {
                            this.child(
                                crate::ui::TextMark::new(
                                    Button::new("page-back", "")
                                        .aria_label(t!("common-back-to-home"))
                                        .subtle()
                                        .icon(Icon::Back)
                                        .on_click(move |_, _, cx| {
                                            model.update(cx, |m, cx| m.navigate(Page::Home, cx))
                                        }),
                                    false,
                                )
                                .title(),
                            )
                        })
                        .child(heading(ElementId::Name(format!("page-title-{id}").into()), 1, title, cx)),
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

/// A heading reported at `level` (1 for the page title, 2 for cards).
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
        .child(div().w(px(140.)).flex_shrink_0().type_body().text_color(theme.text_secondary).child(label))
        .child(div().flex_1().min_w_0().type_body().text_color(theme.text_primary).child(value))
}

/// A readable text value for `detail_row`, keyed like its row.
pub fn detail_text(key: &str, text: impl Into<SharedString>) -> gpui::Text {
    a11y_text(ElementId::Name(format!("detail-{key}-value").into()), text)
}

/// A card header: title on the left, optional trailing element on the right.
/// `key` is a stable element id for the heading.
pub fn card_header(cx: &App, key: &str, title: impl Into<SharedString>, trailing: Option<AnyElement>) -> Div {
    card_header_with_icon(cx, key, title, None, trailing)
}

/// Optional decorative Segoe glyph; the heading keeps its original accessible name.
pub fn card_header_with_icon(
    cx: &App,
    key: &str,
    title: impl Into<SharedString>,
    leading: Option<Icon>,
    trailing: Option<AnyElement>,
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
            let heading = heading(ElementId::Name(format!("card-{key}").into()), 2, title, cx);
            match leading {
                Some(icon) => div()
                    .flex()
                    .items_center()
                    .gap(px(12.))
                    .child(
                        crate::ui::icon_in_line(icon, crate::ui::BODY_LINE_HEIGHT)
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

pub fn card_body(cx: &App) -> Div {
    let _ = cx;
    div().flex().flex_col().gap(px(8.)).px(px(16.)).py(px(12.))
}

/// A small rounded chip, for option names.
pub fn chip(cx: &App, id: impl Into<ElementId>, text: impl Into<SharedString>) -> Stateful<Div> {
    let theme = cx.theme();
    let text = text.into();
    div()
        .id(id)
        .role(Role::ListItem)
        .aria_label(text.clone())
        .px(px(8.))
        .py(px(2.))
        .rounded(px(4.))
        .bg(theme.subtle_hover)
        .border_1()
        .border_color(theme.card_stroke)
        .type_caption()
        .text_color(theme.text_primary)
        .child(text)
}

/// Stable element ids for one log view, so two views on one page never share state.
#[derive(Clone, Copy)]
pub struct LogIds {
    pub log: &'static str,
    pub hidden: &'static str,
    pub line: &'static str,
}

/// The install log as every page shows it: a bounded tail of the installer's
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
        let total = attempt.log_total;
        let start = attempt.log.len().saturating_sub(lines_shown);
        let lines: Vec<SharedString> = attempt.log[start..].to_vec();
        let hidden = total.saturating_sub(lines.len());
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
        div()
            .relative()
            .child(
                div()
                    .id(ids.log)
                    .role(Role::Log)
                    .aria_label(t!("common-install-log"))
                    .max_h(px(max_height))
                    .overflow_y_scroll()
                    .track_scroll(&self.scroll)
                    .px(px(16.))
                    .py(px(12.))
                    .type_mono()
                    .text_color(theme.text_primary)
                    .when(hidden > 0, |this| {
                        this.child(
                            div()
                                .text_color(theme.text_tertiary)
                                .child(a11y_text(ids.hidden, t!("log-earlier-lines", count = hidden))),
                        )
                    })
                    .children(lines.into_iter().enumerate().map(|(index, line)| {
                        div().w_full().min_w_0().child(a11y_text((ids.line, start + index), line))
                    })),
            )
            .child(scrollbar(&self.scroll, &self.scrollbar))
            .into_any_element()
    }
}

/// A wrapping row of chips, reported as a list.
pub fn chip_list(cx: &App, id: impl Into<ElementId>, label: &str, items: Vec<String>) -> Stateful<Div> {
    div()
        .id(id)
        .role(Role::List)
        .aria_label(label.to_owned())
        .flex()
        .flex_wrap()
        .gap(px(6.))
        .children(items.into_iter().enumerate().map(|(index, item)| chip(cx, ("chip", index), item)))
}
