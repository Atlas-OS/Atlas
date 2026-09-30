use super::{card_body, card_header, page_frame};
use crate::{
    model::AppModel,
    t,
    theme::ActiveTheme,
    ui::{
        Button, CheckBox, Icon, InfoBar, ScrollbarState, Severity, Typography, card, text_input::TextInput,
    },
};
use gpui::{
    Context, Entity, FocusHandle, Focusable, IntoElement, Render, ScrollHandle, Window, div, prelude::*, px,
};

#[derive(Clone, Copy, PartialEq, Eq)]
enum Validation {
    Message,
    Contact,
    Diagnostics,
    Collecting,
    Consent,
}
impl Validation {
    fn text(self) -> String {
        match self {
            Self::Message => t!("report-validation-message"),
            Self::Contact => t!("report-validation-contact"),
            Self::Diagnostics => t!("report-validation-diagnostics"),
            Self::Collecting => t!("report-validation-collecting"),
            Self::Consent => t!("report-validation-consent"),
        }
    }
}

pub struct ReportPage {
    model: Entity<AppModel>,
    message: Entity<TextInput>,
    contact: Entity<TextInput>,
    consent: bool,
    attach: bool,
    busy: bool,
    receipt: Option<String>,
    failed: bool,
    validation: Option<Validation>,
    result_focus: FocusHandle,
    focus_result: bool,
    last_message: String,
    last_contact: String,
    key: Option<String>,
    fingerprint: String,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
}
impl ReportPage {
    fn validation_bar(&self) -> InfoBar {
        InfoBar::new(
            Severity::Error,
            t!("report-validation-title"),
            self.validation.expect("visible validation").text(),
        )
        .id("report-validation")
        .focus_handle(self.result_focus.clone())
    }
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        let message = cx.new(|cx| {
            let mut input = TextInput::new(cx);
            input.labels("report-message", "report-message-placeholder", "report-message-input");
            input
        });
        let contact = cx.new(|cx| {
            let mut input = TextInput::new(cx);
            input.labels("report-contact", "report-contact-placeholder", "report-contact-input");
            input
        });
        cx.observe(&message, |this, input, cx| {
            let value = input.read(cx).value().to_owned();
            if !this.busy && this.last_message != value {
                this.consent = false;
                this.validation = None;
                this.last_message = value;
            }
            cx.notify();
        })
        .detach();
        cx.observe(&contact, |this, input, cx| {
            let value = input.read(cx).value().to_owned();
            if !this.busy && this.last_contact != value {
                this.consent = false;
                this.validation = None;
                this.last_contact = value;
            }
            cx.notify();
        })
        .detach();
        Self {
            model,
            message,
            contact,
            consent: false,
            attach: true,
            busy: false,
            receipt: None,
            failed: false,
            validation: None,
            result_focus: cx.focus_handle(),
            focus_result: false,
            last_message: String::new(),
            last_contact: String::new(),
            key: None,
            fingerprint: String::new(),
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
        }
    }
    fn send(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.busy {
            return;
        }
        let message = self.message.read(cx).value().to_owned();
        let contact = self.contact.read(cx).value().to_owned();
        let path = if self.attach {
            self.model.read(cx).diagnostics_result.as_ref().and_then(|r| r.as_ref().ok()).cloned()
        } else {
            None
        };
        let invalid = if !(10..=4000).contains(&message.trim().chars().count()) {
            Some(Validation::Message)
        } else if contact.trim().chars().count() > 254 {
            Some(Validation::Contact)
        } else if self.attach && self.model.read(cx).diagnostics_busy {
            Some(Validation::Collecting)
        } else if self.attach && path.is_none() {
            Some(Validation::Diagnostics)
        } else if !self.consent {
            Some(Validation::Consent)
        } else {
            None
        };
        self.validation = invalid;
        if let Some(invalid) = invalid {
            self.failed = false;
            let focus = match invalid {
                Validation::Message => self.message.read(cx).focus_handle(cx),
                Validation::Contact => self.contact.read(cx).focus_handle(cx),
                _ => self.result_focus.clone(),
            };
            window.focus(&focus, cx);
            cx.notify();
            return;
        }
        let fingerprint = format!("{message}\0{contact}\0{path:?}");
        if self.fingerprint != fingerprint {
            self.key = None;
            self.fingerprint = fingerprint;
        }
        if self.key.is_none() {
            self.key = crate::services::reports::new_key().ok();
        }
        let Some(key) = self.key.clone() else {
            self.failed = true;
            self.focus_result = true;
            cx.notify();
            return;
        };
        self.busy = true;
        self.failed = false;
        cx.spawn(async move |this, cx| {
            let result = cx
                .background_executor()
                .spawn(
                    async move { crate::services::reports::send(&key, &message, &contact, path.as_deref()) },
                )
                .await;
            this.update(cx, |this, cx| {
                this.busy = false;
                match result {
                    Ok(id) => this.receipt = Some(id),
                    Err(_) => this.failed = true,
                }
                this.focus_result = true;
                cx.notify();
            })
            .ok();
        })
        .detach();
        cx.notify();
    }
}
impl Render for ReportPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if self.focus_result {
            window.focus(&self.result_focus, cx);
            self.focus_result = false;
        }
        let theme = cx.theme().clone();
        self.message.update(cx, |input, _| input.set_read_only(self.busy));
        self.contact.update(cx, |input, _| input.set_read_only(self.busy));
        let state = self.model.read(cx);
        let path = state.diagnostics_result.as_ref().and_then(|r| r.as_ref().ok()).cloned();
        let collecting = state.diagnostics_busy;
        let length = self.message.read(cx).value().trim().chars().count();
        let content = if let Some(receipt) = &self.receipt {
            card(cx).child(
                card_body(cx).child(
                    InfoBar::new(
                        Severity::Success,
                        t!("report-received"),
                        t!("report-reference", reference = receipt.as_str()),
                    )
                    .id("report-result")
                    .focus_handle(self.result_focus.clone()),
                ),
            )
        } else {
            card(cx).child(card_header(cx, "report-details", t!("report-details"), None)).child(
                card_body(cx)
                    .gap(px(14.))
                    .child(div().type_body().text_color(theme.text_secondary).child(t!("report-intro")))
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(6.))
                            .child(div().type_body_strong().child(t!("report-message")))
                            .child(self.message.clone()),
                    )
                    .when(self.validation == Some(Validation::Message), |this| {
                        this.child(self.validation_bar())
                    })
                    .when(length > 80, |this| {
                        this.child(
                            div()
                                .type_body()
                                .whitespace_normal()
                                .child(self.message.read(cx).value().to_owned()),
                        )
                    })
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(6.))
                            .child(div().type_body_strong().child(t!("report-contact")))
                            .child(self.contact.clone()),
                    )
                    .when(self.validation == Some(Validation::Contact), |this| {
                        this.child(self.validation_bar())
                    })
                    .child(
                        CheckBox::new("report-attach", t!("report-attach"), self.attach)
                            .disabled(self.busy)
                            .on_toggle(cx.listener(|this, _, _, cx| {
                                this.attach = !this.attach;
                                this.consent = false;
                                this.validation = None;
                                cx.notify();
                            })),
                    )
                    .when(self.attach, |this| {
                        this.child(
                            div()
                                .flex()
                                .flex_wrap()
                                .gap(px(8.))
                                .child(
                                    Button::new(
                                        "report-prepare",
                                        if collecting {
                                            t!("diagnostics-exporting")
                                        } else {
                                            t!("report-prepare")
                                        },
                                    )
                                    .disabled(self.busy || collecting)
                                    .on_click(cx.listener(
                                        |this, _, _, cx| {
                                            this.consent = false;
                                            this.validation = None;
                                            this.model.update(cx, |m, cx| m.export_diagnostics(cx));
                                            cx.notify();
                                        },
                                    )),
                                )
                                .when_some(path.clone(), |this, path| {
                                    this.child(
                                        Button::new("report-review", t!("report-review"))
                                            .icon(Icon::Folder)
                                            .disabled(self.busy)
                                            .on_click(move |_, _, cx| cx.reveal_path(&path)),
                                    )
                                }),
                        )
                    })
                    .when(
                        matches!(self.validation, Some(Validation::Diagnostics | Validation::Collecting)),
                        |this| this.child(self.validation_bar()),
                    )
                    .child(div().type_caption().text_color(theme.text_secondary).child(t!("report-privacy")))
                    .child(
                        Button::new("report-website", t!("report-website"))
                            .hyperlink()
                            .opens(crate::services::reports::ORIGIN),
                    )
                    .child(
                        CheckBox::new("report-consent", t!("report-consent"), self.consent)
                            .disabled(self.busy)
                            .on_toggle(cx.listener(|this, _, _, cx| {
                                this.consent = !this.consent;
                                this.validation = None;
                                cx.notify();
                            })),
                    )
                    .when(self.validation == Some(Validation::Consent), |this| {
                        this.child(self.validation_bar())
                    })
                    .when(self.failed, |this| {
                        this.child(
                            InfoBar::new(Severity::Error, t!("report-failed-title"), t!("report-failed"))
                                .id("report-result")
                                .focus_handle(self.result_focus.clone()),
                        )
                    })
                    .child(
                        div().flex().justify_end().child(
                            Button::new(
                                "report-send",
                                if self.busy { t!("report-sending") } else { t!("report-send") },
                            )
                            .accent()
                            .disabled(self.busy)
                            .on_click(cx.listener(|this, _, window, cx| this.send(window, cx))),
                        ),
                    ),
            )
        };
        page_frame(
            "report",
            Some(t!("report-title").into()),
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            vec![content.into_any_element()],
            None,
            cx,
        )
    }
}
