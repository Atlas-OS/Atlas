//! The Fluent InfoBar: a tinted strip with a status icon, a title, a message
//! and an optional action. Errors and warnings are reported as alerts;
//! everything else as status.

use gpui::{
    AnyElement, App, ElementId, FocusHandle, IntoElement, ParentElement, RenderOnce, Role, SharedString,
    Styled, Window, div, prelude::*, px,
};

use super::typography::BODY_LINE_HEIGHT;
use super::{Icon, Typography, icon_in_line};
use crate::theme::ActiveTheme;

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
    focus: Option<FocusHandle>,
}

impl InfoBar {
    pub fn new(severity: Severity, title: impl Into<SharedString>, message: impl Into<SharedString>) -> Self {
        Self { id: None, severity, title: title.into(), message: message.into(), action: None, focus: None }
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

    /// Lets the page move keyboard focus here, so a result is announced.
    pub fn focus_handle(mut self, handle: FocusHandle) -> Self {
        self.focus = Some(handle);
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
        let id = self.id.unwrap_or_else(|| ElementId::Name(self.title.clone()));
        let focus_outer = theme.focus_outer;
        let bar = div()
            .id(id)
            .role(role)
            .aria_label(self.title.clone())
            .when(has_message, |this| this.aria_description(self.message.clone()))
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
                    .child(div().type_body_strong().child(self.title))
                    .when(has_message, |this| this.child(div().type_body().child(self.message)))
                    // Actions may contain a full translated acknowledgement. Keep
                    // them below the copy rather than squeezing it into a sliver.
                    .when_some(self.action, |this, action| {
                        this.child(div().w_full().min_w_0().pt(px(8.)).child(action))
                    }),
            );
        match self.focus {
            Some(handle) => bar
                .track_focus(&handle.tab_stop(false))
                .focus_visible(move |style| style.border_color(focus_outer))
                .into_any_element(),
            None => bar.into_any_element(),
        }
    }
}
