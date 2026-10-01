//! The Fluent InfoBar: a tinted strip with a status icon, a title, a message,
//! optional actions and optional content below them, and an optional close
//! button. Errors and warnings are reported as alerts; everything else as
//! status.
//!
//! Like WinUI's InfoBar, a bar announces itself when it appears or its words
//! change: it is a polite live region, named by its title and message
//! together. A bar the page moves focus to is announced by that instead.

use gpui::{
    AnyElement, App, ClickEvent, ElementId, FocusHandle, IntoElement, Live, ParentElement, RenderOnce, Role,
    SharedString, Styled, Window, div, prelude::*, px,
};

use super::typography::BODY_LINE_HEIGHT;
use super::{Button, Icon, Revealed, Typography, icon_in_line};
use crate::t;
use crate::theme::ActiveTheme;

/// The close button WinUI puts in an InfoBar's top trailing corner, for
/// [`InfoBar::close_button`]: a cancel glyph named and tooltipped "Dismiss".
pub fn dismiss_button(
    id: impl Into<ElementId>,
    on_click: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static,
) -> Button {
    let label = t!("common-dismiss");
    Button::new(id, "")
        .icon(Icon::Cancel)
        .subtle()
        .aria_label(label.clone())
        .tooltip(label)
        .on_click(on_click)
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Severity {
    Informational,
    Success,
    Warning,
    Error,
}

#[derive(IntoElement)]
pub struct InfoBar {
    id: Option<ElementId>,
    severity: Severity,
    title: SharedString,
    message: SharedString,
    action: Option<AnyElement>,
    content: Option<AnyElement>,
    focus: Option<FocusHandle>,
    close: Option<AnyElement>,
}

impl InfoBar {
    pub fn new(severity: Severity, title: impl Into<SharedString>, message: impl Into<SharedString>) -> Self {
        Self {
            id: None,
            severity,
            title: title.into(),
            message: message.into(),
            action: None,
            content: None,
            focus: None,
            close: None,
        }
    }

    /// A stable element id; the title is used when none is given.
    pub fn id(mut self, id: impl Into<ElementId>) -> Self {
        self.id = Some(id.into());
        self
    }

    pub fn action(mut self, action: impl IntoElement) -> Self {
        self.action = Some(action.into_any_element());
        self
    }

    /// Content under the message and actions, as WinUI places it: a check
    /// box that confirms what the bar asks for, for example.
    pub fn content(mut self, content: impl IntoElement) -> Self {
        self.content = Some(content.into_any_element());
        self
    }

    /// Lets the page move keyboard focus here, so a result is announced.
    pub fn focus_handle(mut self, handle: FocusHandle) -> Self {
        self.focus = Some(handle);
        self
    }

    /// The close button WinUI puts in the top trailing corner: give it a
    /// cancel glyph, an accessible name and a tooltip.
    pub fn close_button(mut self, button: impl IntoElement) -> Self {
        self.close = Some(button.into_any_element());
        self
    }
}

impl RenderOnce for InfoBar {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let (fill, colour, glyph) = match self.severity {
            Severity::Informational => (theme.info_fill, theme.info, Icon::Info),
            Severity::Success => (theme.success_fill, theme.success, Icon::Completed),
            Severity::Warning => (theme.caution_fill, theme.caution, Icon::Warning),
            Severity::Error => (theme.critical_fill, theme.critical, Icon::ErrorBadge),
        };
        let role = match self.severity {
            Severity::Warning | Severity::Error => Role::Alert,
            Severity::Informational | Severity::Success => Role::Status,
        };
        let has_message = !self.message.is_empty();
        // A bar may be a message alone, as in WinUI; the message is then its name.
        let has_title = !self.title.is_empty();
        // A live bar is read by its name when it appears or changes, so the
        // name carries the message too. A focused bar reads its description.
        let live = self.focus.is_none();
        let name: SharedString = match (has_title, has_message) {
            (true, true) if live => {
                t!("infobar-a11y", title = self.title.as_ref(), message = self.message.as_ref()).into()
            }
            (true, _) => self.title.clone(),
            (false, _) => self.message.clone(),
        };
        let id = self.id.unwrap_or_else(|| {
            ElementId::Name(if has_title { self.title.clone() } else { self.message.clone() })
        });
        let focus_outer = theme.focus_outer;
        let bar = div()
            .id(id)
            .role(role)
            .aria_label(name)
            .when(has_title && has_message && !live, |this| this.aria_description(self.message.clone()))
            .when(live, |this| this.aria_live(Live::Polite))
            .flex()
            .items_start()
            .gap(px(12.))
            .w_full()
            .px(px(14.))
            .py(px(10.))
            .rounded(px(4.))
            .bg(fill)
            .border_1()
            .border_color(theme.card_stroke)
            // The glyph sits on the title's letters, not on the top of the column.
            .child(icon_in_line(glyph, BODY_LINE_HEIGHT).type_body_strong().text_color(colour))
            .child(
                div()
                    .flex()
                    .flex_col()
                    .flex_1()
                    .min_w_0()
                    .text_color(theme.text_primary)
                    .when(has_title, |this| this.child(div().type_body_strong().child(self.title)))
                    .when(has_message, |this| this.child(div().type_body().child(self.message)))
                    // Below the copy, so a long translated action can't squeeze
                    // it. The wrapping row keeps a button at its natural width,
                    // as WinUI does, and still lets a check box take the full width.
                    .when_some(self.action, |this, action| {
                        this.child(
                            div()
                                .flex()
                                .flex_wrap()
                                .items_start()
                                .gap(px(8.))
                                .w_full()
                                .min_w_0()
                                .pt(px(8.))
                                .child(action),
                        )
                    })
                    .when_some(self.content, |this, content| {
                        this.child(div().w_full().pt(px(8.)).child(content))
                    }),
            )
            // Level with the title, in the corner's padding.
            .when_some(self.close, |this, close| {
                this.child(div().flex_shrink_0().my(px(-4.)).mr(px(-6.)).child(close))
            });
        match self.focus {
            // A bar the page moves focus to is scrolled into view with it.
            Some(handle) => Revealed::new(
                bar.track_focus(&handle.tab_stop(false))
                    .focus_visible(move |style| style.border_color(focus_outer)),
            )
            .into_any_element(),
            None => bar.into_any_element(),
        }
    }
}
