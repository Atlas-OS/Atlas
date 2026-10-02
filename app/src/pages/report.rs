//! Sends a problem report or a suggestion to the Atlas team, with diagnostics if
//! the user includes them.
//!
//! Diagnostics are collected as soon as they're included, so one Send is
//! enough: chosen while they're still being collected, it waits for them.

use std::path::{Path, PathBuf};
use std::sync::Arc;

use super::{CommandBar, card_body, focusable_heading, on_model, page_frame};
use crate::{
    i18n::describe,
    model::{AppModel, Page, RunState},
    services::reports::{self, Category, SendProblem},
    t,
    theme::{ActiveTheme, FONT_MONO},
    ui::{
        BODY_LINE_HEIGHT, Button, CheckBox, FocusHandles, Icon, InfoBar, ProgressRing, RadioGroup, RadioItem,
        Revealed, ScrollbarState, Severity, Typography, a11y_text, card, focus_reveal, icon_in_line,
        text_input::TextInput,
    },
};
use gpui::{
    AnyElement, App, ClipboardItem, Context, Div, Entity, FocusHandle, Focusable, IntoElement, Render, Role,
    ScrollHandle, Window, div, prelude::*, px,
};

/// Sends one report: its submission key, kind, message, contact details and
/// diagnostics ZIP. Returns the reference the service gave it.
type Sender = Arc<dyn Fn(&str, Category, &str, &str, Option<&Path>) -> anyhow::Result<String> + Send + Sync>;

/// The report service. In tests, a sender that refuses, so no test can
/// reach the real service by accident; tests that send give their own.
fn service() -> Sender {
    if cfg!(test) {
        Arc::new(|_: &str, _: Category, _: &str, _: &str, _: Option<&Path>| -> anyhow::Result<String> {
            anyhow::bail!("tests never contact the report service")
        })
    } else {
        Arc::new(reports::send)
    }
}

/// Where sending stands.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Delivery {
    Idle,
    /// Send was chosen while the diagnostics were being collected. The report
    /// goes once they're ready, unless collecting fails or the user leaves.
    Waiting,
    /// The report is on its way.
    Sending,
}

/// What stops the report from being sent, each shown under its own field.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct Problems {
    message: bool,
    contact: bool,
    consent: bool,
}

impl Problems {
    fn of(message: &str, contact: &str, consent: bool) -> Self {
        Self {
            message: !reports::message_fits(message),
            contact: !reports::contact_fits(contact),
            consent: !consent,
        }
    }

    /// The first field to fix, in the order the form shows them.
    fn first(self) -> Option<Field> {
        if self.message {
            Some(Field::Message)
        } else if self.contact {
            Some(Field::Contact)
        } else if self.consent {
            Some(Field::Consent)
        } else {
            None
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Field {
    Message,
    Contact,
    Consent,
}

pub struct ReportPage {
    model: Entity<AppModel>,
    message: Entity<TextInput>,
    contact: Entity<TextInput>,
    category: Category,
    /// The user agreed to send. Agreement covers edits to the message and
    /// contact details, but not diagnostics added or removed.
    consent: bool,
    attach: bool,
    delivery: Delivery,
    receipt: Option<String>,
    failure: Option<SendProblem>,
    problems: Problems,
    /// Held by the result: the bar saying the report wasn't sent, or the
    /// heading saying it was.
    result_focus: FocusHandle,
    focus_result: bool,
    title_focus: FocusHandle,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    /// The page visit whose arrival was last handled.
    arrived_visit: u64,
    /// The user was on this page at the last model change, to tell when they leave.
    on_page: bool,
    /// An export was running at the last model change, to tell when one starts.
    exporting: bool,
    /// Where the latest export was asked for: the page visit and the install's state.
    export_asked: Option<(u64, RunState)>,
    attach_focus: FocusHandle,
    consent_focus: FocusHandle,
    /// Held by the bar that says preparing diagnostics failed.
    prepare_focus: FocusHandle,
    focus_prepare: bool,
    /// The user asked to prepare diagnostics again, so a failure takes
    /// focus. Diagnostics prepared on their own never do: the user may be
    /// typing.
    preparing: bool,
    focus_message: bool,
    last_message: String,
    last_contact: String,
    key: Option<String>,
    fingerprint: String,
    /// A ZIP not to send: it went with the last report, the service refused
    /// it, or it was asked for before the page the user came here from, so it
    /// may miss what this report is about. The report prepares its own.
    spent_diagnostics: Option<PathBuf>,
    sender: Sender,
    /// A review preview: diagnostics are never collected.
    preview: bool,
    focus: FocusHandles,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
}

impl ReportPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |this, _, cx| this.model_changed(cx)).detach();
        let message = cx.new(|cx| {
            let mut input = TextInput::new(
                cx,
                "report-message-input",
                || t!("report-message"),
                || t!("report-message-placeholder"),
            );
            input.multiline();
            input
        });
        let contact = cx.new(|cx| {
            TextInput::new(
                cx,
                "report-contact-input",
                || t!("report-contact"),
                || t!("report-contact-placeholder"),
            )
        });
        watch_field(&message, |this| &mut this.last_message, |problems| problems.message = false, cx);
        watch_field(&contact, |this| &mut this.last_contact, |problems| problems.contact = false, cx);
        let page = Self {
            model,
            message,
            contact,
            category: Category::Issue,
            consent: false,
            attach: true,
            delivery: Delivery::Idle,
            receipt: None,
            failure: None,
            problems: Problems::default(),
            result_focus: cx.focus_handle(),
            focus_result: false,
            title_focus: cx.focus_handle(),
            seen_visit: 0,
            arrived_visit: 0,
            on_page: false,
            exporting: false,
            export_asked: None,
            attach_focus: cx.focus_handle(),
            consent_focus: cx.focus_handle(),
            prepare_focus: cx.focus_handle(),
            focus_prepare: false,
            preparing: false,
            focus_message: false,
            last_message: String::new(),
            last_contact: String::new(),
            key: None,
            fingerprint: String::new(),
            spent_diagnostics: None,
            sender: service(),
            preview: false,
            focus: FocusHandles::default(),
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
        };
        #[cfg(debug_assertions)]
        let page = page.with_preview(cx);
        page
    }

    /// The page in the state `ATLAS_REPORT_PREVIEW` names, for review
    /// captures. Nothing is collected, and Send fails without connecting.
    #[cfg(debug_assertions)]
    fn with_preview(mut self, cx: &mut Context<Self>) -> Self {
        let Ok(state) = std::env::var("ATLAS_REPORT_PREVIEW") else { return self };
        self.preview = true;
        self.sender =
            Arc::new(|_: &str, _: Category, _: &str, _: &str, _: Option<&Path>| -> anyhow::Result<String> {
                anyhow::bail!("previews never contact the report service")
            });
        let zip = crate::services::settings::app_data_dir()
            .join("Diagnostics")
            .join("Atlas-diagnostics-preview.zip");
        let filled = !matches!(state.as_str(), "invalid" | "collecting" | "ready" | "prepare-failed");
        // Recorded as seen, so filling them in doesn't count as an edit.
        let mut fill = |message: &str, contact: String, cx: &mut Context<Self>| {
            self.message.update(cx, |input, cx| input.set_value(message.to_owned(), cx));
            self.contact.update(cx, |input, cx| input.set_value(contact.clone(), cx));
            (self.last_message, self.last_contact) = (message.to_owned(), contact);
        };
        if filled {
            fill(
                "Atlas stopped at the Windows Security step and didn't install.",
                "someone@example.org".into(),
                cx,
            );
            self.consent = true;
        } else if state == "invalid" {
            fill("", "x".repeat(reports::CONTACT_MAX_CHARS + 1), cx);
        }
        let (busy, result): (bool, Option<Result<PathBuf, String>>) = match state.as_str() {
            "collecting" | "waiting" => (true, None),
            "prepare-failed" => {
                (false, Some(Err("There is not enough space on the disk. (os error 112)".into())))
            }
            "invalid" => {
                self.problems = Problems { message: true, contact: true, consent: true };
                (false, Some(Ok(zip.clone())))
            }
            _ => (false, Some(Ok(zip.clone()))),
        };
        match state.as_str() {
            "waiting" => self.delivery = Delivery::Waiting,
            "sending" => self.delivery = Delivery::Sending,
            "sent" => self.receipt = Some("29e43f22-3eff-48ab-a4f3-2d2da90e1410".into()),
            "failed" => self.failure = Some(SendProblem::Retry),
            "busy" => self.failure = Some(SendProblem::Busy),
            "outdated" => self.failure = Some(SendProblem::Outdated),
            "diagnostics" => {
                // As `finish` leaves it: the refused ZIP isn't offered again.
                self.failure = Some(SendProblem::Diagnostics);
                self.spent_diagnostics = Some(zip);
            }
            _ => {}
        }
        self.model.update(cx, |m, _| {
            m.diagnostics_busy = busy;
            m.diagnostics_result = result;
        });
        self
    }

    /// The diagnostics prepared for this report: the latest export, unless
    /// it is spent.
    fn prepared(&self, cx: &App) -> Option<PathBuf> {
        let state = self.model.read(cx);
        let path = state.diagnostics_result.as_ref()?.as_ref().ok()?;
        (self.spent_diagnostics.as_ref() != Some(path)).then(|| path.clone())
    }

    /// Why the latest export failed, if it did.
    fn export_error(&self, cx: &App) -> Option<String> {
        self.model.read(cx).diagnostics_result.as_ref()?.as_ref().err().cloned()
    }

    /// Starts collecting diagnostics for this report, unless they aren't
    /// included, are already being collected or are ready to send.
    fn prepare_diagnostics(&mut self, cx: &mut Context<Self>) {
        if self.attach
            && !self.preview
            && !self.model.read(cx).diagnostics_busy
            && self.prepared(cx).is_none()
        {
            self.model.update(cx, |m, cx| m.export_diagnostics(cx));
        }
    }

    /// The user asked for diagnostics again after they couldn't be prepared
    /// or sent.
    fn prepare_again(&mut self, cx: &mut Context<Self>) {
        if self.failure == Some(SendProblem::Diagnostics) {
            self.failure = None;
        }
        self.preparing = true;
        self.prepare_diagnostics(cx);
        cx.notify();
    }

    /// Follows the model: notes where each export was asked for, handles
    /// arriving and leaving, and sends a waiting report once its diagnostics
    /// are ready.
    fn model_changed(&mut self, cx: &mut Context<Self>) {
        let (page, visit, run, collecting) = {
            let state = self.model.read(cx);
            (state.page, state.page_visit, state.flow.run, state.diagnostics_busy)
        };
        if collecting && !self.exporting {
            self.export_asked = Some((visit, run));
        }
        self.exporting = collecting;
        let on_page = page == Page::Report;
        if std::mem::replace(&mut self.on_page, on_page) && !on_page {
            self.leave(cx);
        } else if on_page && visit != self.arrived_visit {
            self.arrived_visit = visit;
            self.arrive(visit, run, cx);
        }
        if !collecting {
            if self.delivery == Delivery::Waiting {
                if self.prepared(cx).is_some() {
                    self.start_sending(cx);
                } else {
                    // The bar that says why is the next thing to read.
                    self.delivery = Delivery::Idle;
                    self.focus_prepare = true;
                }
            }
            if std::mem::take(&mut self.preparing) && self.export_error(cx).is_some() {
                self.focus_prepare = true;
            }
        }
        cx.notify();
    }

    /// Leaving cancels a report that hasn't gone yet, and puts away one that
    /// has, however the user leaves, so the next visit starts afresh.
    fn leave(&mut self, cx: &mut Context<Self>) {
        if self.delivery == Delivery::Waiting {
            self.delivery = Delivery::Idle;
        }
        if self.receipt.is_some() {
            self.clear(cx);
        }
    }

    /// Prepares diagnostics on arrival. A ZIP is used as it is only if it was
    /// asked for on this visit or on the page the user came from, with the
    /// install where it is now: an older one may miss what the report is
    /// about. A report that went while the user was away shows its receipt.
    fn arrive(&mut self, visit: u64, run: RunState, cx: &mut Context<Self>) {
        if self.receipt.is_some() || self.preview {
            return;
        }
        // A Windows update that stopped starts the report with its cause, so
        // one Send carries what the team needs. The user's own words stay.
        if self.message.read(cx).value().trim().is_empty()
            && let Some(context) = self.model.read(cx).report_context()
        {
            self.message.update(cx, |input, cx| input.set_value(context.clone(), cx));
            self.last_message = context;
        }
        let recent = self.export_asked.is_some_and(|(asked, then)| asked + 1 >= visit && then == run);
        if !recent && let Some(path) = self.prepared(cx) {
            self.spent_diagnostics = Some(path);
        }
        self.prepare_diagnostics(cx);
    }

    /// Includes or leaves out diagnostics. Agreement covered what was to be
    /// sent, so it is withdrawn when that changes.
    fn set_attach(&mut self, attach: bool, cx: &mut Context<Self>) {
        if self.attach != attach {
            self.attach = attach;
            self.consent = false;
        }
        self.prepare_diagnostics(cx);
        cx.notify();
    }

    fn choose_category(&mut self, category: Category, cx: &mut Context<Self>) {
        if self.category == category {
            return;
        }
        self.category = category;
        // An issue is easier to investigate with diagnostics; a suggestion
        // rarely needs them.
        self.set_attach(category == Category::Issue, cx);
    }

    fn send(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(field) = self.submit(cx) else { return };
        let focus = match field {
            Field::Message => self.message.read(cx).focus_handle(cx),
            Field::Contact => self.contact.read(cx).focus_handle(cx),
            Field::Consent => self.consent_focus.clone(),
        };
        // The field reads its problem out as it takes focus.
        reveal_focus(&focus, window, cx);
    }

    /// Checks the report and sends it, or waits for its diagnostics first.
    /// Returns the first field with a problem, for the caller to focus.
    fn submit(&mut self, cx: &mut Context<Self>) -> Option<Field> {
        if self.delivery != Delivery::Idle {
            return None;
        }
        let message = self.message.read(cx).value().to_owned();
        let contact = self.contact.read(cx).value().to_owned();
        self.problems = Problems::of(&message, &contact, self.consent);
        self.failure = None;
        cx.notify();
        if let Some(field) = self.problems.first() {
            return Some(field);
        }
        if self.attach && self.prepared(cx).is_none() {
            // Collecting again after a failure is part of sending.
            self.delivery = Delivery::Waiting;
            if !self.model.read(cx).diagnostics_busy {
                self.model.update(cx, |m, cx| m.export_diagnostics(cx));
            }
            return None;
        }
        self.start_sending(cx);
        None
    }

    fn start_sending(&mut self, cx: &mut Context<Self>) {
        let message = self.message.read(cx).value().to_owned();
        let contact = self.contact.read(cx).value().to_owned();
        let path = if self.attach { self.prepared(cx) } else { None };
        let Some(key) = self.submission_key(&message, &contact, path.as_deref()) else {
            self.delivery = Delivery::Idle;
            self.failure = Some(SendProblem::Retry);
            self.focus_result = true;
            cx.notify();
            return;
        };
        self.delivery = Delivery::Sending;
        let category = self.category;
        let sender = self.sender.clone();
        cx.spawn(async move |this, cx| {
            let attached = path.clone();
            let result = cx
                .background_executor()
                .spawn(async move { sender(&key, category, &message, &contact, path.as_deref()) })
                .await;
            this.update(cx, |this, cx| this.finish(result, attached, cx)).ok();
        })
        .detach();
        cx.notify();
    }

    /// The key to send this report with: the last one while nothing sent has
    /// changed, so a retry reuses the same submission; a new one otherwise.
    fn submission_key(&mut self, message: &str, contact: &str, path: Option<&Path>) -> Option<String> {
        let fingerprint = format!("{:?}\0{message}\0{contact}\0{path:?}", self.category);
        if self.fingerprint != fingerprint {
            self.key = None;
            self.fingerprint = fingerprint;
        }
        if self.key.is_none() {
            self.key =
                reports::new_key().inspect_err(|error| log::warn!("Report was not sent: {error:#}")).ok();
        }
        self.key.clone()
    }

    fn finish(&mut self, result: anyhow::Result<String>, attached: Option<PathBuf>, cx: &mut Context<Self>) {
        self.delivery = Delivery::Idle;
        match result {
            Ok(id) => {
                // The reference only: the key would let anyone fetch an
                // upload token for this report.
                log::info!("Report sent; reference {id}");
                self.receipt = Some(id);
                if attached.is_some() {
                    self.spent_diagnostics = attached;
                }
            }
            Err(error) => {
                log::warn!("Report was not sent: {error:#}");
                let problem = reports::problem(&error);
                if problem == SendProblem::Diagnostics {
                    // Not offered again: Send collects another first.
                    self.spent_diagnostics = attached;
                }
                self.failure = Some(problem);
            }
        }
        self.focus_result = true;
        cx.notify();
    }

    /// Empties the form for another report, keeping the kind and whether to
    /// include diagnostics.
    fn clear(&mut self, cx: &mut Context<Self>) {
        self.receipt = None;
        self.failure = None;
        self.problems = Problems::default();
        self.consent = false;
        self.key = None;
        self.fingerprint.clear();
        self.message.update(cx, |input, cx| input.set_value("", cx));
        self.contact.update(cx, |input, cx| input.set_value("", cx));
        cx.notify();
    }

    /// Another report, here and now. Its diagnostics are collected afresh.
    fn start_new(&mut self, cx: &mut Context<Self>) {
        self.clear(cx);
        self.focus_message = true;
        self.prepare_diagnostics(cx);
    }

    /// Under Include diagnostics: being collected, ready to review, or
    /// nothing while they're left out or couldn't be prepared.
    fn diagnostics_status(&self, collecting: bool, path: Option<PathBuf>, cx: &App) -> Option<Div> {
        let theme = cx.theme();
        let (glyph, text, review) = if collecting {
            (ProgressRing::new().into_any_element(), t!("diagnostics-exporting"), None)
        } else {
            let glyph = icon_in_line(Icon::Completed, BODY_LINE_HEIGHT).text_color(theme.success);
            (glyph.into_any_element(), t!("diagnostics-saved"), Some(path?))
        };
        Some(
            // In line with the check box's label.
            div().pl(px(40.)).child(
                div()
                    .id("report-diagnostics-status")
                    .role(Role::Status)
                    .aria_label(text.clone())
                    // "Collecting", then "created": announced as it changes.
                    .aria_live(gpui::Live::Polite)
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(8.))
                    .child(div().flex().items_center().h(BODY_LINE_HEIGHT).child(glyph))
                    .child(div().type_body().text_color(theme.text_primary).child(text))
                    .when_some(review, |this, path| {
                        this.child(
                            Button::new("report-review", t!("report-review"))
                                .hyperlink()
                                .compact()
                                .disabled(self.delivery != Delivery::Idle)
                                .on_click(move |_, _, cx| cx.reveal_path(&path)),
                        )
                    }),
            ),
        )
    }

    /// Why the report wasn't sent, with what can be done about it.
    fn failure_bar(&self, problem: SendProblem, path: Option<PathBuf>, cx: &mut Context<Self>) -> AnyElement {
        let try_again = matches!(problem, SendProblem::Retry | SendProblem::Busy).then(|| {
            Button::new("report-try-again", t!("common-try-again"))
                .on_click(cx.listener(|this, _, window, cx| this.send(window, cx)))
        });
        // The website takes the report instead, with the ZIP attached there.
        let website = matches!(problem, SendProblem::Retry | SendProblem::Outdated);
        let review = path.filter(|_| website).map(|path| {
            Button::new("report-failed-review", t!("report-review"))
                .icon(Icon::Folder)
                .on_click(move |_, _, cx| cx.reveal_path(&path))
        });
        let prepare = (problem == SendProblem::Diagnostics).then(|| {
            Button::new("report-failed-prepare", t!("report-prepare")).on_click(cx.listener(
                |this, _, window, cx| {
                    this.prepare_again(cx);
                    window.focus(&this.attach_focus, cx);
                },
            ))
        });
        let actions = div()
            .flex()
            .flex_wrap()
            .items_center()
            .gap(px(8.))
            .children(try_again)
            .children(prepare)
            .when(website, |this| {
                this.child(
                    Button::new("report-failed-website", t!("report-failed-website"))
                        .hyperlink()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(reports::ORIGIN),
                )
            })
            .children(review);
        Revealed::new(
            InfoBar::new(Severity::Error, t!("report-failed-title"), describe::report_failure(problem))
                .id("report-result")
                .focus_handle(self.result_focus.clone())
                .action(actions),
        )
        .into_any_element()
    }

    fn form(&mut self, cx: &mut Context<Self>) -> Div {
        let theme = cx.theme().clone();
        let busy = self.delivery != Delivery::Idle;
        let collecting = self.model.read(cx).diagnostics_busy;
        let export_error = self.export_error(cx).filter(|_| self.attach && !collecting);
        let path = self.prepared(cx);
        let entity = cx.entity();
        let kinds = [
            RadioItem::new(
                "report-kind-issue",
                t!("report-kind-issue"),
                self.focus.get("report-kind-issue", cx),
            ),
            RadioItem::new(
                "report-kind-suggestion",
                t!("report-kind-suggestion"),
                self.focus.get("report-kind-suggestion", cx),
            ),
        ];
        let label = |text: String| div().type_body_strong().text_color(theme.text_primary).child(text);
        let status = if self.attach { self.diagnostics_status(collecting, path.clone(), cx) } else { None };
        let failure = self.failure.map(|problem| self.failure_bar(problem, path.filter(|_| self.attach), cx));
        card(cx).child(
            card_body()
                .gap(px(16.))
                .child(
                    div().flex().flex_col().gap(px(6.)).child(label(t!("report-kind"))).child(
                        RadioGroup::new("report-kind", t!("report-kind"))
                            .items(kinds)
                            .selected(Some(usize::from(self.category == Category::Suggestion)))
                            .disabled(busy)
                            .on_select(move |index, _, cx| {
                                let category =
                                    if index == 0 { Category::Issue } else { Category::Suggestion };
                                entity.update(cx, |this, cx| this.choose_category(category, cx))
                            }),
                    ),
                )
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(6.))
                        .child(label(t!("report-message")))
                        // The box reads this out as its description.
                        .child(div().type_caption().text_color(theme.text_secondary).child(intro()))
                        .child(self.message.clone()),
                )
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(6.))
                        .child(label(t!("report-contact")))
                        .child(self.contact.clone()),
                )
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(4.))
                        .child(
                            CheckBox::new("report-attach", t!("report-attach"), self.attach)
                                .description(t!("report-attach-description"))
                                .focus_handle(self.attach_focus.clone())
                                .disabled(busy)
                                .on_toggle(cx.listener(|this, _, _, cx| this.set_attach(!this.attach, cx))),
                        )
                        .children(status)
                        .when_some(export_error, |this, error| {
                            this.child(Revealed::new(
                                InfoBar::new(
                                    Severity::Error,
                                    t!("report-prepare-failed-title"),
                                    t!("report-prepare-failed", error = error.as_str()),
                                )
                                .id("report-prepare-error")
                                .focus_handle(self.prepare_focus.clone())
                                .action(
                                    Button::new("report-prepare", t!("report-prepare"))
                                        .disabled(busy)
                                        .on_click(cx.listener(|this, _, window, cx| {
                                            this.prepare_again(cx);
                                            window.focus(&this.attach_focus, cx);
                                        })),
                                ),
                            ))
                        }),
                )
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(4.))
                        .child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("report-privacy", t!("report-privacy"))),
                        )
                        .child(
                            div().flex().child(
                                Button::new("report-website", t!("report-website"))
                                    .hyperlink()
                                    .compact()
                                    .trailing_icon(Icon::OpenInNewWindow)
                                    .opens(reports::ORIGIN),
                            ),
                        ),
                )
                .child(
                    CheckBox::new("report-consent", t!("report-consent"), self.consent)
                        .focus_handle(self.consent_focus.clone())
                        .error(self.problems.consent.then(|| t!("report-validation-consent").into()))
                        .disabled(busy)
                        .on_toggle(cx.listener(|this, _, _, cx| {
                            this.consent = !this.consent;
                            this.problems.consent = false;
                            cx.notify();
                        })),
                )
                .children(failure),
        )
    }

    /// The reference on a line of its own with Copy, what to keep it for, and
    /// where to go next.
    fn sent_panel(&self, reference: String, cx: &mut Context<Self>) -> Div {
        let theme = cx.theme().clone();
        let copied = reference.clone();
        card(cx).child(
            div()
                .flex()
                .flex_col()
                .gap(px(12.))
                .px(px(16.))
                .py(px(16.))
                .child(
                    div()
                        .flex()
                        .items_start()
                        .gap(px(12.))
                        .child(
                            icon_in_line(Icon::Completed, BODY_LINE_HEIGHT)
                                .type_body_strong()
                                .text_color(theme.success),
                        )
                        .child(Revealed::new(focusable_heading(
                            "report-received",
                            2,
                            t!("report-received"),
                            &self.result_focus,
                            cx,
                        ))),
                )
                .child(
                    div()
                        .flex()
                        .flex_wrap()
                        .items_center()
                        .gap(px(8.))
                        .child(
                            div()
                                .min_w_0()
                                .type_body()
                                .font_family(FONT_MONO)
                                .text_color(theme.text_primary)
                                .child(a11y_text("report-reference-value", reference)),
                        )
                        .child(
                            Button::new("report-copy", t!("common-copy"))
                                .compact()
                                .icon(Icon::Copy)
                                .aria_label(t!("report-copy-reference"))
                                .on_click(move |_, _, cx| {
                                    cx.write_to_clipboard(ClipboardItem::new_string(copied.clone()))
                                }),
                        ),
                )
                .child(
                    div()
                        .type_body()
                        .text_color(theme.text_secondary)
                        .child(a11y_text("report-reference", t!("report-reference"))),
                )
                .child(
                    div()
                        .flex()
                        .flex_wrap()
                        .gap(px(8.))
                        .pt(px(4.))
                        .child(
                            Button::new("report-done", t!("common-done"))
                                .accent()
                                // Leaving puts the report away.
                                .on_click(on_model(&self.model, |m, cx| m.navigate(m.back_target(), cx))),
                        )
                        .child(
                            Button::new("report-another", t!("report-another"))
                                .on_click(cx.listener(|this, _, _, cx| this.start_new(cx))),
                        ),
                ),
        )
    }

    /// Cancel, what is happening, and Send report.
    fn command_bar(&self, cx: &mut Context<Self>) -> CommandBar {
        let busy = self.delivery != Delivery::Idle;
        let state = self.model.read(cx);
        // Nothing has gone while it waits for diagnostics, so leaving then
        // cancels the report; once it's on its way it can't be called back.
        let can_cancel = self.delivery != Delivery::Sending && state.can_navigate(state.back_target());
        let hint =
            if self.delivery == Delivery::Waiting { t!("diagnostics-exporting") } else { String::new() };
        CommandBar::new()
            .cancel(
                "report-cancel",
                t!("common-cancel"),
                !can_cancel,
                on_model(&self.model, |m, cx| m.navigate(m.back_target(), cx)),
            )
            .hint(hint)
            .primary(
                div()
                    .flex()
                    .items_center()
                    .gap(px(12.))
                    .when(busy, |this| this.child(ProgressRing::new()))
                    .child(
                        Button::new(
                            "report-send",
                            if busy { t!("report-sending") } else { t!("report-send") },
                        )
                        .accent()
                        .disabled(busy)
                        .on_click(cx.listener(|this, _, window, cx| this.send(window, cx))),
                    ),
            )
    }
}

/// What to write, and what to leave out.
fn intro() -> String {
    t!("report-intro", min = *reports::MESSAGE_CHARS.start(), max = *reports::MESSAGE_CHARS.end())
}

/// Moves focus to `focus` and scrolls it into view.
fn reveal_focus(focus: &FocusHandle, window: &mut Window, cx: &mut App) {
    window.focus(focus, cx);
    focus_reveal::request(window, cx);
}

/// An edit to a field clears the problem shown under it. Agreement to send
/// stays: it covers the message and contact details as they change.
fn watch_field(
    input: &Entity<TextInput>,
    last: fn(&mut ReportPage) -> &mut String,
    fixed: fn(&mut Problems),
    cx: &mut Context<ReportPage>,
) {
    cx.observe(input, move |this, input, cx| {
        let value = input.read(cx).value().to_owned();
        if *last(this) != value {
            fixed(&mut this.problems);
            *last(this) = value;
        }
        cx.notify();
    })
    .detach();
}

impl Render for ReportPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let visit = self.model.read(cx).page_visit;
        if std::mem::replace(&mut self.seen_visit, visit) != visit {
            window.focus(&self.title_focus, cx);
        }
        if std::mem::take(&mut self.focus_result) {
            reveal_focus(&self.result_focus, window, cx);
        }
        if std::mem::take(&mut self.focus_prepare) {
            reveal_focus(&self.prepare_focus, window, cx);
        }
        if std::mem::take(&mut self.focus_message) {
            window.focus(&self.message.read(cx).focus_handle(cx), cx);
        }
        let busy = self.delivery != Delivery::Idle;
        let message_error = self.problems.message.then(|| {
            t!(
                "report-validation-message",
                min = *reports::MESSAGE_CHARS.start(),
                max = *reports::MESSAGE_CHARS.end()
            )
            .into()
        });
        let contact_error = self
            .problems
            .contact
            .then(|| t!("report-validation-contact", max = reports::CONTACT_MAX_CHARS).into());
        self.message.update(cx, |input, _| {
            input.set_read_only(busy);
            input.set_error(message_error);
            input.set_description(Some(intro().into()));
        });
        self.contact.update(cx, |input, _| {
            input.set_read_only(busy);
            input.set_error(contact_error);
        });
        let (content, footer) = match self.receipt.clone() {
            Some(reference) => (self.sent_panel(reference, cx), None),
            None => (self.form(cx), Some(self.command_bar(cx).into_any_element())),
        };
        page_frame(
            "report",
            Some(t!("report-title").into()),
            Some(&self.title_focus),
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            vec![content.into_any_element()],
            footer,
            cx,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
    use crate::services::test_support::TempDir;

    #[test]
    fn a_failed_send_keeps_the_report_for_a_retry_with_the_same_key() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-retry");
            block_exports(&temp);
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            page.update(&mut cx, |page, cx| {
                let message = "Setup stopped at the Defender step";
                let zip = temp.path().join("Atlas-diagnostics.zip");
                page.message.update(cx, |input, cx| input.set_value(message, cx));
                let first = page.submission_key(message, "", Some(&zip)).expect("a key");
                page.delivery = Delivery::Sending;
                page.finish(Err(anyhow::anyhow!("connection reset")), Some(zip.clone()), cx);
                assert!(page.delivery == Delivery::Idle && page.receipt.is_none());
                assert_eq!(page.failure, Some(SendProblem::Retry));
                assert_eq!(page.message.read(cx).value(), message);
                // Sending the same report again is the same submission.
                assert_eq!(page.submission_key(message, "", Some(&zip)), Some(first.clone()));

                // Anything sent that changed makes it another report.
                let edited = "Setup stopped at the Install step";
                let changed = page.submission_key(edited, "", Some(&zip));
                assert!(changed.is_some() && changed != Some(first));
                let contact = page.submission_key(edited, "someone@example.org", Some(&zip));
                assert_ne!(contact, changed);
                let newer = temp.path().join("newer.zip");
                let rezipped = page.submission_key(edited, "someone@example.org", Some(&newer));
                assert_ne!(rezipped, contact);
                page.category = Category::Suggestion;
                let recategorised = page.submission_key(edited, "someone@example.org", Some(&newer));
                assert_ne!(recategorised, rezipped);
                assert_eq!(page.submission_key(edited, "someone@example.org", Some(&newer)), recategorised);

                // Another report after this one never reuses its key.
                page.start_new(cx);
                assert_ne!(page.submission_key(edited, "someone@example.org", Some(&newer)), recategorised);
            });
        });
    }

    #[test]
    fn after_a_report_is_sent_another_starts_clean_and_prepares_its_own_diagnostics() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-another");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let zip = temp.path().join("Atlas-diagnostics.zip");
            model.update(&mut cx, |m, _| m.diagnostics_result = Some(Ok(zip.clone())));
            page.update(&mut cx, |page, cx| {
                page.category = Category::Suggestion;
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.contact.update(cx, |input, cx| input.set_value("someone@example.org", cx));
                page.consent = true;
                page.key = Some("submission".into());
                page.fingerprint = "sent".into();
                assert_eq!(page.prepared(cx), Some(zip.clone()));
                page.finish(Ok("reference".into()), Some(zip.clone()), cx);
                assert_eq!(page.receipt.as_deref(), Some("reference"));
            });
            block_exports(&temp);
            page.update(&mut cx, |page, cx| {
                page.start_new(cx);
                assert!(
                    page.receipt.is_none() && page.failure.is_none() && page.problems == Problems::default()
                );
                assert!(!page.consent && page.key.is_none() && page.fingerprint.is_empty());
                assert!(page.message.read(cx).value().is_empty() && page.contact.read(cx).value().is_empty());
                assert_eq!(page.category, Category::Suggestion);
                // The ZIP went with the first report, so another is being collected.
                assert_eq!(page.prepared(cx), None);
            });
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy), "the next report collects its own");
            settle_export(&cx, &model).await;
            model.update(&mut cx, |m, _| m.diagnostics_result = Some(Ok(temp.path().join("newer.zip"))));
            page.update(&mut cx, |page, cx| {
                assert_eq!(page.prepared(cx), Some(temp.path().join("newer.zip")))
            });
        });
    }

    /// Exports fail at once, before collecting anything from this PC.
    fn block_exports(temp: &TempDir) {
        std::fs::write(temp.path().join("Diagnostics"), "not a folder").unwrap();
    }

    /// Waits for a blocked export to end.
    async fn settle_export(cx: &gpui::AsyncApp, model: &Entity<AppModel>) {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(30);
        while model.read_with(cx, |m, _| m.diagnostics_busy) {
            assert!(std::time::Instant::now() < deadline, "the export never ended");
            cx.background_executor().timer(std::time::Duration::from_millis(25)).await;
        }
    }

    /// An export from the current page that saved `zip`.
    fn exported(cx: &mut gpui::AsyncApp, model: &Entity<AppModel>, zip: &Path) {
        model.update(cx, |m, cx| {
            m.diagnostics_busy = true;
            cx.notify();
        });
        model.update(cx, |m, cx| {
            m.diagnostics_busy = false;
            m.diagnostics_result = Some(Ok(zip.to_path_buf()));
            cx.notify();
        });
    }

    /// Waits until the page has a result for the report it sent.
    async fn settle_send(cx: &gpui::AsyncApp, page: &Entity<ReportPage>) {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(30);
        while page.read_with(cx, |page, _| page.delivery != Delivery::Idle) {
            assert!(std::time::Instant::now() < deadline, "the report never finished sending");
            cx.background_executor().timer(std::time::Duration::from_millis(25)).await;
        }
    }

    /// The message and ZIP of each report a test sent.
    type Sent = Arc<std::sync::Mutex<Vec<(String, Option<PathBuf>)>>>;

    /// A sender that records what it was given and accepts every report.
    fn recording() -> (Sender, Sent) {
        let sent = Arc::new(std::sync::Mutex::new(Vec::new()));
        let log = sent.clone();
        let sender: Sender = Arc::new(
            move |_: &str,
                  _: Category,
                  message: &str,
                  _: &str,
                  path: Option<&Path>|
                  -> anyhow::Result<String> {
                log.lock().unwrap().push((message.to_owned(), path.map(Path::to_path_buf)));
                Ok("29e43f22-3eff-48ab-a4f3-2d2da90e1410".into())
            },
        );
        (sender, sent)
    }

    #[test]
    fn opening_the_page_prepares_diagnostics_once_per_visit_unless_a_recent_zip_exists() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-arrival");
            block_exports(&temp);
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            assert!(!model.read_with(&cx, |m, _| m.diagnostics_busy), "nothing before the page opens");
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy), "an issue includes diagnostics");
            settle_export(&cx, &model).await;
            // A failure on its own doesn't take focus, and isn't retried on the same visit.
            page.read_with(&cx, |page, _| assert!(!page.focus_prepare));
            model.update(&mut cx, |_, cx| cx.notify());
            assert!(!model.read_with(&cx, |m, _| m.diagnostics_busy));

            // A ZIP exported on the page the user came from is used as it is.
            let zip = temp.path().join("ready.zip");
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            exported(&mut cx, &model, &zip);
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            assert!(!model.read_with(&cx, |m, _| m.diagnostics_busy));
            page.read_with(&cx, |page, cx| assert_eq!(page.prepared(cx), Some(zip.clone())));

            // Coming back later, it may miss what the report is about, so
            // another is collected.
            model.update(&mut cx, |m, cx| m.navigate(Page::Settings, cx));
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy));
            settle_export(&cx, &model).await;

            // As it is after an export from before the install finished.
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            exported(&mut cx, &model, &temp.path().join("before.zip"));
            model.update(&mut cx, |m, cx| {
                m.flow.run = RunState::Finished(crate::services::installer::InstallOutcome::Failed(1));
                m.navigate(Page::Report, cx);
            });
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy));
            settle_export(&cx, &model).await;

            // A suggestion leaves them out, so opening the page collects nothing.
            page.update(&mut cx, |page, cx| page.choose_category(Category::Suggestion, cx));
            model.update(&mut cx, |m, cx| {
                m.navigate(Page::Home, cx);
                m.diagnostics_result = None;
            });
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            assert!(!model.read_with(&cx, |m, _| m.diagnostics_busy));
            // Including them again collects them at once.
            page.update(&mut cx, |page, cx| page.set_attach(true, cx));
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy));
            settle_export(&cx, &model).await;
        });
    }

    #[test]
    fn agreement_survives_edits_but_not_a_change_of_diagnostics() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-consent");
            block_exports(&temp);
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            page.update(&mut cx, |page, cx| {
                page.consent = true;
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.contact.update(cx, |input, cx| input.set_value("someone@example.org", cx));
            });
            page.read_with(&cx, |page, _| assert!(page.consent, "edits keep agreement"));
            // A ZIP finishing doesn't withdraw it either.
            model.update(&mut cx, |m, cx| {
                m.diagnostics_result = Some(Ok(temp.path().join("ready.zip")));
                cx.notify();
            });
            page.read_with(&cx, |page, _| assert!(page.consent));

            page.update(&mut cx, |page, cx| page.set_attach(false, cx));
            page.read_with(&cx, |page, _| assert!(!page.consent, "diagnostics removed"));
            page.update(&mut cx, |page, cx| {
                page.consent = true;
                page.set_attach(true, cx);
                assert!(!page.consent, "diagnostics added");
                page.consent = true;
                // Switching to a suggestion leaves the diagnostics out.
                page.choose_category(Category::Suggestion, cx);
                assert!(!page.attach && !page.consent);
                page.consent = true;
                page.set_attach(false, cx);
                assert!(page.consent, "nothing changed");
            });
        });
    }

    #[test]
    fn send_shows_every_problem_and_focuses_the_first() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-problems");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let (sender, sent) = recording();
            page.update(&mut cx, |page, cx| {
                page.sender = sender;
                page.attach = false;
                page.contact.update(cx, |input, cx| input.set_value("x".repeat(255), cx));
            });
            page.update(&mut cx, |page, cx| {
                assert_eq!(page.submit(cx), Some(Field::Message));
                assert_eq!(page.problems, Problems { message: true, contact: true, consent: true });
                // Fixing a field clears its own problem only.
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
            });
            page.update(&mut cx, |page, cx| {
                assert_eq!(page.problems, Problems { message: false, contact: true, consent: true });
                page.contact.update(cx, |input, cx| input.set_value("someone@example.org", cx));
            });
            page.update(&mut cx, |page, cx| {
                assert_eq!(page.submit(cx), Some(Field::Consent));
                assert_eq!(page.delivery, Delivery::Idle, "nothing is sent without agreement");
                page.consent = true;
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Sending);
            });
            settle_send(&cx, &page).await;
            page.read_with(&cx, |page, _| assert!(page.receipt.is_some()));
            assert_eq!(*sent.lock().unwrap(), [("Setup stopped at the Defender step".to_owned(), None)]);
        });
    }

    #[test]
    fn send_while_collecting_waits_and_then_sends_the_zip() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-waiting");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let (sender, sent) = recording();
            // An export is already running, as one does when the page opens.
            model.update(&mut cx, |m, cx| {
                m.diagnostics_busy = true;
                m.navigate(Page::Report, cx);
            });
            page.update(&mut cx, |page, cx| {
                page.sender = sender;
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.consent = true;
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Waiting);
                assert_eq!(page.submit(cx), None, "a second Send changes nothing");
            });
            assert!(sent.lock().unwrap().is_empty(), "nothing goes before the ZIP is ready");
            let zip = temp.path().join("Atlas-diagnostics.zip");
            model.update(&mut cx, |m, cx| {
                m.diagnostics_busy = false;
                m.diagnostics_result = Some(Ok(zip.clone()));
                cx.notify();
            });
            settle_send(&cx, &page).await;
            page.read_with(&cx, |page, cx| {
                assert!(page.receipt.is_some());
                assert_eq!(page.prepared(cx), None, "the ZIP went with this report");
            });
            assert_eq!(*sent.lock().unwrap(), [("Setup stopped at the Defender step".to_owned(), Some(zip))]);
        });
    }

    #[test]
    fn a_waiting_report_stays_unsent_when_collecting_fails_or_the_user_leaves() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-unsent");
            block_exports(&temp);
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let (sender, sent) = recording();
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            settle_export(&cx, &model).await;
            page.update(&mut cx, |page, cx| {
                page.sender = sender;
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.consent = true;
                // Send collects again after a failure, and waits for it.
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Waiting);
            });
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy));
            settle_export(&cx, &model).await;
            page.read_with(&cx, |page, _| {
                assert_eq!(page.delivery, Delivery::Idle);
                assert!(page.focus_prepare, "the failure is the next thing to read");
                assert!(page.consent, "the form is kept as it was");
            });

            // Leaving before the ZIP is ready cancels the report.
            model.update(&mut cx, |m, _| m.diagnostics_busy = true);
            page.update(&mut cx, |page, cx| {
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Waiting);
            });
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            page.read_with(&cx, |page, _| assert_eq!(page.delivery, Delivery::Idle));
            model.update(&mut cx, |m, cx| {
                m.diagnostics_busy = false;
                m.diagnostics_result = Some(Ok(temp.path().join("late.zip")));
                cx.notify();
            });
            page.read_with(&cx, |page, _| assert_eq!(page.delivery, Delivery::Idle));
            assert!(sent.lock().unwrap().is_empty());
        });
    }

    #[test]
    fn a_sent_report_shows_until_the_user_leaves() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-leave");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let (sender, sent) = recording();
            page.update(&mut cx, |page, _| {
                page.sender = sender;
                page.attach = false;
            });
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            page.update(&mut cx, |page, cx| {
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.consent = true;
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Sending);
            });
            // Leaving doesn't call it back, and the receipt waits for the next visit.
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            settle_send(&cx, &page).await;
            model.update(&mut cx, |_, cx| cx.notify());
            assert_eq!(sent.lock().unwrap().len(), 1);
            model.update(&mut cx, |m, cx| m.navigate(Page::Report, cx));
            page.read_with(&cx, |page, _| assert!(page.receipt.is_some(), "the user learns it went"));

            // Done, the back arrow and Escape all leave, and the next visit starts afresh.
            model.update(&mut cx, |m, cx| m.navigate(Page::Home, cx));
            page.read_with(&cx, |page, cx| {
                assert!(page.receipt.is_none() && !page.consent);
                assert!(page.message.read(cx).value().is_empty());
            });
        });
    }

    #[test]
    fn diagnostics_the_service_refused_are_never_sent_again() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("report-refused");
            block_exports(&temp);
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let page = cx.update(|cx| cx.new(|cx| ReportPage::new(model.clone(), cx)));
            let (sender, sent) = recording();
            let zip = temp.path().join("refused.zip");
            model.update(&mut cx, |m, _| m.diagnostics_result = Some(Ok(zip.clone())));
            page.update(&mut cx, |page, cx| {
                page.sender = sender;
                page.message
                    .update(cx, |input, cx| input.set_value("Setup stopped at the Defender step", cx));
                page.consent = true;
                page.finish(Err(missing_zip()), Some(zip.clone()), cx);
                assert_eq!(page.failure, Some(SendProblem::Diagnostics));
                assert_eq!(page.prepared(cx), None, "the refused ZIP isn't offered again");
                // Send report collects another first.
                assert_eq!(page.submit(cx), None);
                assert_eq!(page.delivery, Delivery::Waiting);
            });
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy), "a new ZIP is collected");
            settle_export(&cx, &model).await;
            assert!(sent.lock().unwrap().is_empty(), "nothing went without its diagnostics");

            // So does Prepare diagnostics in the bar, and its failure takes focus.
            page.update(&mut cx, |page, cx| {
                (page.failure, page.focus_prepare) = (Some(SendProblem::Diagnostics), false);
                page.prepare_again(cx);
                assert_eq!(page.failure, None);
            });
            assert!(model.read_with(&cx, |m, _| m.diagnostics_busy));
            settle_export(&cx, &model).await;
            page.read_with(&cx, |page, _| {
                assert!(page.focus_prepare, "asked for, so its failure takes focus")
            });
        });
    }

    /// A ZIP that can't be read, which `send` refuses before connecting to
    /// anything, as `reports::problem` reads unusable diagnostics.
    fn missing_zip() -> anyhow::Error {
        let missing = std::env::temp_dir().join(format!("atlas-missing-{}.zip", reports::new_key().unwrap()));
        reports::send(&reports::new_key().unwrap(), Category::Issue, "Valid test message", "", Some(&missing))
            .unwrap_err()
    }

    #[test]
    fn problems_are_checked_field_by_field() {
        assert_eq!(Problems::of("Setup stopped at the Defender step", "", true), Problems::default());
        assert_eq!(Problems::of("Short", "", true).first(), Some(Field::Message));
        assert_eq!(Problems::of("Setup stopped", &"x".repeat(255), true).first(), Some(Field::Contact));
        assert_eq!(Problems::of("Setup stopped", "", false).first(), Some(Field::Consent));
        assert_eq!(Problems::default().first(), None);
    }
}
