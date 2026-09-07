//! The "Atlas is installed" window: opened by the payload's first-logon
//! setup once the restart has finished, so the person who left the PC to
//! install comes back to a proper completion screen rather than a toast.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, Role, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::{card_body, card_header, chip_list, detail_row, detail_text};
use crate::i18n::{describe, fmt};
use crate::model::{AppModel, Page};
use crate::services::system::links;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CompletionBackdrop, FocusHandles, Icon, ScrollbarState, Typography, a11y_text, card, icon_sized,
    scrollbar,
};

pub struct InstalledPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    focused_once: bool,
}

impl InstalledPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            focused_once: false,
        }
    }
}

impl Render for InstalledPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let heading_focus = self.focus.get("installed-heading", cx);
        if !self.focused_once {
            self.focused_once = true;
            window.focus(&heading_focus, cx);
        }
        let state = self.model.read(cx);
        let installed = state.installed();
        let version = state.installed_version().map(str::to_owned);
        let title = match &version {
            Some(version) => t!("installed-title-version", version = version),
            None => t!("installed-title"),
        };
        let options: Vec<String> =
            installed.map(|i| i.options.iter().map(|o| state.option_label(o)).collect()).unwrap_or_default();
        let mode = installed.map(|i| i.install_mode().label());
        let when = installed.and_then(|i| i.installed_at_local()).map(|when| fmt::long_date(&when));
        let system_text = describe::system_description(&state.system);

        let details: Option<AnyElement> = installed.map(|_| {
            card(cx)
                .w_full()
                .child(card_header(cx, "your-install", t!("home-your-install"), None))
                .child(
                    card_body(cx)
                        .when_some(mode, |this, mode| {
                            this.child(detail_row(
                                cx,
                                "mode",
                                t!("common-installed-as"),
                                detail_text("mode", mode),
                            ))
                        })
                        .when_some(when, |this, when| {
                            this.child(detail_row(
                                cx,
                                "installed",
                                t!("common-installed"),
                                detail_text("installed", when),
                            ))
                        })
                        .child(detail_row(
                            cx,
                            "windows",
                            t!("common-windows"),
                            detail_text("windows", system_text),
                        ))
                        .child(detail_row(
                            cx,
                            "options",
                            t!("common-options"),
                            if options.is_empty() {
                                div()
                                    .text_color(theme.text_secondary)
                                    .child(detail_text("options", t!("common-none")))
                                    .into_any_element()
                            } else {
                                chip_list(cx, "installed-options", &t!("common-options"), options)
                                    .into_any_element()
                            },
                        )),
                )
                .into_any_element()
        });

        let column = div()
            .flex()
            .flex_col()
            .items_center()
            .w_full()
            .max_w(px(560.))
            .gap(px(16.))
            .flex_shrink_0()
            .my_auto()
            .child(
                div()
                    .relative()
                    .w(px(72.))
                    .h(px(72.))
                    .child(
                        svg()
                            .path("brand/atlas-mark.svg")
                            .absolute()
                            .bottom(px(0.))
                            .size(px(72.))
                            .text_color(theme.brand),
                    )
                    .child(
                        div()
                            .absolute()
                            .right(px(-4.))
                            .bottom(px(-4.))
                            .size(px(24.))
                            .rounded_full()
                            .bg(theme.success)
                            .flex()
                            .items_center()
                            .justify_center()
                            .child(icon_sized(Icon::CheckMark, 14.).text_color(theme.text_on_accent)),
                    ),
            )
            .child(
                div()
                    .id("installed-heading")
                    .role(Role::Heading)
                    .aria_level(1)
                    .aria_label(title.clone())
                    .track_focus(&heading_focus.clone().tab_stop(false))
                    .type_title()
                    .text_color(theme.text_primary)
                    .text_center()
                    .child(title),
            )
            .child(
                div()
                    .type_body_large()
                    .text_color(theme.text_secondary)
                    .text_center()
                    .child(a11y_text("installed-line", t!("installed-ready"))),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .items_center()
                    .gap(px(8.))
                    .pt(px(8.))
                    .child(
                        Button::new("installed-done", t!("common-done"))
                            .accent()
                            .on_click(|_, window, _| window.remove_window()),
                    )
                    .child(
                        div()
                            .flex()
                            .flex_wrap()
                            .justify_center()
                            .gap(px(8.))
                            .child(
                                Button::new("installed-docs", t!("common-read-the-docs"))
                                    .hyperlink()
                                    .trailing_icon(Icon::OpenInNewWindow)
                                    .opens(links::DOCS),
                            )
                            .child(
                                Button::new("installed-home", t!("installed-open-atlas"))
                                    .hyperlink()
                                    .on_click({
                                        let model = model.clone();
                                        move |_, _, cx| model.update(cx, |m, cx| m.navigate(Page::Home, cx))
                                    }),
                            ),
                    ),
            )
            .when_some(details, |this, details| this.child(div().w_full().pt(px(16.)).child(details)));

        div()
            .relative()
            .size_full()
            .overflow_hidden()
            .child(CompletionBackdrop)
            .child(
                div()
                    .id("installed-scroll")
                    .size_full()
                    .overflow_y_scroll()
                    .track_scroll(&self.scroll)
                    .flex()
                    .flex_col()
                    .items_center()
                    .px(px(40.))
                    .py(px(40.))
                    .child(column),
            )
            .child(scrollbar(&self.scroll, &self.scrollbar))
    }
}
