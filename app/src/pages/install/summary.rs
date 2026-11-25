//! Step 4, Install: one bar for what stands in the way of starting, or for
//! how the last attempt ended, and the Ready to install card. The installing
//! view covers this page while an install runs and once one has succeeded,
//! so only an idle step or an attempt that didn't succeed shows here.

use gpui::{
    AnyElement, App, ClipboardItem, Context, Entity, IntoElement, ParentElement, Styled, div, prelude::*, px,
};

use super::{InstallPage, LOG_IDS, LOG_LINES_SHOWN, details_toggle, start_over_button};
use crate::i18n::describe;
use crate::model::{AppModel, ElevationProblem, Preflight, RunState, ScreenKind, Step, UpdatePath};
use crate::pages::{
    ListEntry, card_body, card_title, caution_caption, detail_row, detail_row_with_action, detail_text,
    log_actions, on_model, plain_list,
};
use crate::services::installer::{self, InstallOutcome};
use crate::services::package::{ChoiceKind, ChoiceOption, Manifest};
use crate::services::requirements::{CheckId, Verdict};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{Button, CheckBox, Icon, InfoBar, Severity, Typography, a11y_text, card, link_row};

/// The one bar the Install step shows, the first that applies.
#[derive(Clone, Debug, PartialEq, Eq)]
enum InstallBar {
    /// The last attempt didn't succeed.
    Result(InstallOutcome),
    /// The final checks refused to start the installer.
    Refusal(Preflight),
    /// Atlas runs without administrator permission.
    Elevate,
    /// No Atlas package is ready.
    NoPackage,
    /// Get ready no longer holds for this session.
    NotReady,
    /// A fresh reading of the protection switches no longer passes.
    Security,
}

/// What a bar's button does.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum BarAction {
    Relaunch,
    /// Begins the setup again here, when another window has taken it over.
    StartOver,
    GetReady,
    /// Opens Your choices at a question, or at the extras.
    Choices(ScreenKind),
    OpenWindowsSecurity,
    /// Goes back to the Windows Security step, which confirms switches
    /// Atlas can't read.
    SecurityStep,
}

/// The bar the Install step shows, if any: how the last attempt ended, a
/// refusal of the final checks, or else what stands in the way of starting.
/// A state the card shows already gets none, and while the security
/// switches are being read again nothing is said, as the reading takes a
/// moment and changes nothing the user would do.
fn install_bar(state: &AppModel) -> Option<InstallBar> {
    let run = state.flow.run;
    if let RunState::Finished(outcome) = run
        && !outcome.is_success()
    {
        return Some(InstallBar::Result(outcome));
    }
    if let Some(problem) = &state.preflight_problem {
        return Some(InstallBar::Refusal(problem.clone()));
    }
    if !run.may_start() {
        return None;
    }
    if !state.elevated {
        Some(InstallBar::Elevate)
    } else if state.package.is_none() {
        Some(InstallBar::NoPackage)
    } else if !state.ready_to_continue() {
        Some(InstallBar::NotReady)
    } else if state.security_fresh() && !state.security_ok() {
        Some(InstallBar::Security)
    } else {
        None
    }
}

/// Relaunching as administrator, or starting over when another window owns
/// the setup and a relaunch can't help; nothing while neither can work.
fn elevation_action(state: &AppModel) -> Option<BarAction> {
    if state.elevation_error == Some(ElevationProblem::TakenOver) {
        Some(BarAction::StartOver)
    } else {
        state.may_relaunch_elevated().then_some(BarAction::Relaunch)
    }
}

/// The question, or page of the extras, that the choices leave without an
/// answer, as the installer reads them: a single choice they make apply
/// that has no answer, or more than one. Named by its own kind, and opened
/// by the kind of the question or extras it's part of.
fn unanswered_choice(state: &AppModel) -> Option<(ScreenKind, ScreenKind)> {
    let manifest = state.manifest();
    let options = state.effective_options();
    let (index, page) = manifest.choices.iter().enumerate().find(|(_, page)| {
        let applies = page.depends_on.as_ref().is_none_or(|dependency| options.contains(dependency));
        let answers = page.options.iter().filter(|option| options.contains(&option.id)).count();
        page.kind == ChoiceKind::Single && applies && answers != 1
    })?;
    let group = state.choice_groups().into_iter().find(|group| group.pages.contains(&index))?;
    Some((ScreenKind::of_choice(page), group.kind))
}

impl InstallBar {
    /// The bar's own button, when it's the next step: then Install Atlas,
    /// or Try again, isn't, as it can't help yet.
    fn action(&self, state: &AppModel) -> Option<BarAction> {
        match self {
            InstallBar::Result(_) if !state.elevated => elevation_action(state),
            InstallBar::Result(outcome) => (outcome.needs_preparation()
                || *outcome == InstallOutcome::Failed(2))
            .then_some(BarAction::GetReady),
            InstallBar::Refusal(problem) => match problem {
                Preflight::InvalidOptions { .. } => {
                    let open = unanswered_choice(state).map_or(ScreenKind::Defender, |(_, open)| open);
                    Some(BarAction::Choices(open))
                }
                Preflight::TakenOver => Some(BarAction::StartOver),
                Preflight::Changed { checks, .. } if checks.is_empty() => {
                    Some(BarAction::OpenWindowsSecurity)
                }
                Preflight::Changed { .. } | Preflight::RecordUnreadable { .. } => Some(BarAction::GetReady),
                Preflight::Refused { .. } | Preflight::Busy => None,
            },
            InstallBar::Elevate => elevation_action(state),
            InstallBar::NoPackage | InstallBar::NotReady => Some(BarAction::GetReady),
            InstallBar::Security if state.security.counts().on > 0 => Some(BarAction::OpenWindowsSecurity),
            InstallBar::Security => Some(BarAction::SecurityStep),
        }
    }

    /// A second button, where one helps beside the next step: Windows
    /// Security, for turning protection back on after a failure that may
    /// have changed things, or for the switches a refusal also found on.
    fn secondary(&self, state: &AppModel) -> Option<BarAction> {
        match self {
            InstallBar::Result(_)
                if self.action(state).is_none() && state.result_offers_windows_security() =>
            {
                Some(BarAction::OpenWindowsSecurity)
            }
            InstallBar::Refusal(Preflight::Changed { checks, security: Some(_) }) if !checks.is_empty() => {
                Some(BarAction::OpenWindowsSecurity)
            }
            _ => None,
        }
    }

    /// Whether the help row goes under it: only for an unexpected failure,
    /// not one whose cause the user can fix with the bar's button, nor a
    /// refusal that says what to do.
    fn needs_help(&self, state: &AppModel) -> bool {
        match self {
            InstallBar::Result(_) => self.action(state).is_none(),
            InstallBar::Refusal(problem) => {
                matches!(problem, Preflight::Refused { .. } | Preflight::RecordUnreadable { .. })
            }
            _ => false,
        }
    }

    /// The installer's own words or the raw error behind Show details.
    fn raw(&self, state: &AppModel) -> Vec<String> {
        match self {
            InstallBar::Result(_) => state
                .attempt
                .last_error()
                .into_iter()
                .chain(state.attempt.output_problem.as_deref())
                .map(str::to_owned)
                .collect(),
            InstallBar::Refusal(
                Preflight::InvalidOptions { error }
                | Preflight::RecordUnreadable { error }
                | Preflight::Refused { error },
            ) => vec![error.clone()],
            _ => Vec::new(),
        }
    }
}

/// Whether the Install step's bar holds the next step, so the footer's
/// Install Atlas, or Try again, isn't the screen's accent button.
pub(super) fn bar_leads(state: &AppModel) -> bool {
    install_bar(state).is_some_and(|bar| bar.action(state).is_some())
}

/// Whether the footer leaves Try again out: the last attempt's bar holds the
/// fix, such as a relaunch as administrator or Get ready, and the same
/// attempt again can't work until that's done.
pub(super) fn retry_hidden(state: &AppModel) -> bool {
    install_bar(state).is_some_and(|bar| matches!(bar, InstallBar::Result(_)) && bar.action(state).is_some())
}

/// The button for `action`, as the bar's next step (`main`) or beside it.
fn action_button(
    action: BarAction,
    main: bool,
    state: &AppModel,
    page: &Entity<InstallPage>,
    model: &Entity<AppModel>,
) -> Button {
    let button = match action {
        BarAction::Relaunch => Button::new("install-elevate", t!("common-restart-as-administrator"))
            .icon(Icon::Admin)
            .on_click(on_model(model, |m, cx| m.relaunch_elevated(cx))),
        BarAction::StartOver => start_over_button("install-start-over", state, model),
        BarAction::GetReady => Button::new("install-back-ready", t!("go-to-ready"))
            .on_click(on_model(model, |m, cx| m.set_step(Step::Ready, cx))),
        BarAction::Choices(kind) => {
            let page = page.clone();
            Button::new("install-back-options", t!("go-to-options"))
                .on_click(move |_, _, cx| page.update(cx, |page, cx| page.open_change(kind, cx)))
        }
        BarAction::OpenWindowsSecurity => {
            // Through the model, which shows a page an Atlas 0.5 policy hides
            // first. A button, as everywhere Atlas offers it.
            let model = model.clone();
            Button::new("install-open-security", t!("common-open-windows-security"))
                .icon(Icon::Shield)
                .on_click(move |_, _, cx| model.update(cx, |m, cx| m.open_windows_security(cx)))
        }
        BarAction::SecurityStep => Button::new("install-back-security", t!("go-to-security"))
            .on_click(on_model(model, |m, cx| m.set_step(Step::Security, cx))),
    };
    if main { button.accent() } else { button }
}

impl InstallPage {
    pub(super) fn install_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let bar = install_bar(self.model.read(cx));
        let mut cards = Vec::new();
        if let Some(bar) = bar {
            cards.push(self.bar(bar, cx));
        }
        cards.push(self.summary_card(cx));
        cards
    }

    /// The step's one bar: what happened or what stands in the way, its
    /// button, the raw words behind Show details and, under an unexpected
    /// failure, the help row. A result and a refusal take focus when they
    /// come (see the page's render), so they're announced.
    fn bar(&mut self, bar: InstallBar, cx: &mut Context<Self>) -> AnyElement {
        let result_focus = self.focus.get("install-result", cx);
        let preflight_focus = self.focus.get("install-preflight", cx);
        let page = cx.entity();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let resumed = state.original_options().is_some();
        let (severity, title, message) = match &bar {
            InstallBar::Result(outcome) => {
                let facts = state.attempt_facts();
                let severity =
                    if *outcome == InstallOutcome::Lost { Severity::Warning } else { Severity::Error };
                (severity, outcome.heading(facts.resumed), outcome.advice(&facts))
            }
            InstallBar::Refusal(problem) => {
                let missing = unanswered_choice(state).map(|(name, _)| name);
                (Severity::Error, t!("preflight-title"), problem.text(resumed, missing))
            }
            InstallBar::Elevate => {
                let why = state
                    .elevation_error
                    .as_ref()
                    .map(|e| e.text())
                    .unwrap_or_else(|| t!("install-elevate-uac"));
                (Severity::Warning, t!("install-elevate-title"), why)
            }
            InstallBar::NoPackage => (Severity::Warning, t!("install-package-missing"), String::new()),
            InstallBar::NotReady => {
                (Severity::Warning, t!("install-not-ready-title"), t!("install-not-ready-message"))
            }
            InstallBar::Security => {
                let summary = describe::security_summary(&state.security.counts());
                (
                    Severity::Warning,
                    t!("install-switches-title"),
                    t!("install-switches-message", summary = summary),
                )
            }
        };
        let actions: Vec<Button> = [
            bar.action(state).map(|action| (action, true)),
            bar.secondary(state).map(|action| (action, false)),
        ]
        .into_iter()
        .flatten()
        .map(|(action, main)| action_button(action, main, state, &page, &model))
        .collect();
        // Why the last relaunch didn't happen, under a result that offers it again.
        let elevation = matches!(bar, InstallBar::Result(_))
            .then(|| state.elevation_error.as_ref().filter(|_| !state.elevated).map(|e| e.text()))
            .flatten();
        let raw = bar.raw(state);
        let finished = matches!(bar, InstallBar::Result(_));
        let help = bar.needs_help(state);
        let mut info = InfoBar::new(severity, title.clone(), message);
        info = match &bar {
            InstallBar::Result(_) => info.id("install-result").focus_handle(result_focus),
            InstallBar::Refusal(_) => info.id("install-preflight").focus_handle(preflight_focus),
            InstallBar::Elevate => info.id("install-elevate-bar"),
            InstallBar::NoPackage => info.id("install-no-package"),
            InstallBar::NotReady => info.id("install-not-ready"),
            InstallBar::Security => info.id("install-security"),
        };
        if !actions.is_empty() {
            info = info.action(div().flex().flex_wrap().gap(px(8.)).children(actions));
        }
        let details = (finished || !raw.is_empty()).then(|| self.bar_details(&title, raw, finished, cx));
        // The help row goes under Show details, inside the bar it helps with.
        let help = help.then(|| self.diagnostics.content(&self.model, cx).into_any_element());
        let content: Vec<AnyElement> = elevation
            .map(|text| {
                div().type_body().child(a11y_text("install-result-elevation", text)).into_any_element()
            })
            .into_iter()
            .chain(details)
            .chain(help)
            .collect();
        if !content.is_empty() {
            info = info.content(div().flex().flex_col().gap(px(4.)).children(content));
        }
        info.into_any_element()
    }

    /// What a bar keeps behind Show details: the raw lines, and for a
    /// finished attempt its log, with Copy and Open log folder.
    fn bar_details(
        &mut self,
        section: &str,
        raw: Vec<String>,
        log: bool,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let shown = self.show_result_details;
        let toggle = details_toggle(
            "result-details",
            section.to_owned(),
            shown,
            |page| &mut page.show_result_details,
            cx,
        );
        let theme = cx.theme().clone();
        let mut column = div().flex().flex_col().gap(px(6.)).child(link_row().child(toggle));
        if shown {
            for (index, line) in raw.into_iter().enumerate() {
                column = column.child(
                    div()
                        .type_mono()
                        .text_color(theme.text_secondary)
                        .child(a11y_text(("result-raw", index), line)),
                );
            }
            if log {
                column = column.child(log_actions(&self.model, LOG_IDS, cx)).child(self.log_view(cx));
            }
        }
        column.into_any_element()
    }

    /// Opens Your choices at what a Change link's row lists, and puts focus
    /// there once it shows (see [`InstallPage::change_focus`]).
    pub(super) fn open_change(&mut self, kind: ScreenKind, cx: &mut Context<Self>) {
        self.change_target = Some(kind);
        self.model.update(cx, |m, cx| m.edit_options(kind, cx));
        if self.model.read(cx).flow.step != Step::Options {
            self.change_target = None;
        }
    }

    /// Ready to install: the choices, with a caution under those that
    /// reduce protection or delete the user's data and Change beside those
    /// that can change; how long the install usually takes and the restart
    /// after it, which the box below decides for this install alone; and the
    /// details behind a toggle. While the footer offers no install, the card
    /// is the setup it will install, not one that's ready.
    fn summary_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let rows = self.choice_rows(cx);
        let details = self.show_summary_details.then(|| self.summary_details(cx));
        let theme = cx.theme();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let request = state.install_request();
        let restart = request.as_ref().map_or_else(|| state.install_restarts(), |request| request.restart);
        let title = if state.can_install() && !retry_hidden(state) {
            t!("summary-ready-title")
        } else {
            t!("summary-setup-title")
        };
        let minutes = state.manifest().estimated_minutes;
        let time = if restart {
            t!("summary-time-restarts", minutes = minutes)
        } else {
            t!("summary-time-restart-yourself", minutes = minutes)
        };
        let toggle = details_toggle(
            "summary-details",
            title.clone(),
            self.show_summary_details,
            |page| &mut page.show_summary_details,
            cx,
        );
        let heading = card_title(cx, "summary", title, 3);
        card(cx)
            .child(
                card_body()
                    .child(heading)
                    .children(rows)
                    .child(
                        div()
                            .pt(px(4.))
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("summary-time", time)),
                    )
                    .child(
                        CheckBox::new("install-restart", t!("summary-restart-automatically"), restart)
                            .disabled(state.locked())
                            .on_toggle(on_model(&model, |m, cx| {
                                let next = !m.install_restarts();
                                m.set_install_restart(next, cx);
                            })),
                    )
                    .child(link_row().child(toggle))
                    .children(details.into_iter().flatten())
                    .map(|this| this.text_color(theme.text_primary)),
            )
            .into_any_element()
    }

    /// The facts already seen on Get ready, what every Defender answer turns
    /// off, and the installation command.
    fn summary_details(&self, cx: &Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme();
        let state = self.model.read(cx);
        let request = state.install_request();
        let activation = state
            .checks
            .iter()
            .find(|(id, _)| *id == CheckId::Activation)
            .and_then(|(_, result)| result.as_ref())
            .map(|result| match result.verdict {
                Verdict::Pass => t!("summary-activation-ok"),
                Verdict::Warn => t!("summary-activation-missing"),
                _ => t!("summary-activation-unknown"),
            })
            .unwrap_or_else(|| t!("summary-activation-unknown"));
        let package =
            state.package.as_ref().map(|source| source.describe()).unwrap_or_else(|| t!("package-none-yet"));
        let show_command = self.show_command;
        // Built only while shown, not on every frame.
        let command = request.as_ref().filter(|_| show_command).map(|request| {
            installer::command_line(request)
                .unwrap_or_else(|error| t!("summary-command-unavailable", error = format!("{error:#}")))
        });
        let mut details = vec![
            detail_row(cx, "package", t!("common-package"), detail_text("package", package))
                .into_any_element(),
            detail_row(
                cx,
                "windows",
                t!("common-windows"),
                detail_text("windows", describe::system_description(&state.system)),
            )
            .into_any_element(),
            detail_row(cx, "activation", t!("summary-activation"), detail_text("activation", activation))
                .into_any_element(),
            detail_row(
                cx,
                "turned-off",
                t!("summary-turned-off"),
                detail_text("turned-off", t!("summary-turned-off-value")),
            )
            .into_any_element(),
        ];
        if request.is_some() {
            details.push(
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .pt(px(4.))
                    .child(
                        link_row().child(
                            Button::new(
                                "toggle-command",
                                if show_command {
                                    t!("summary-hide-command")
                                } else {
                                    t!("summary-show-command")
                                },
                            )
                            .hyperlink()
                            .compact()
                            .expanded(show_command)
                            .trailing_icon(if show_command { Icon::ChevronUp } else { Icon::ChevronDown })
                            .on_click(cx.listener(|this, _, _, cx| {
                                this.show_command = !this.show_command;
                                cx.notify();
                            })),
                        ),
                    )
                    .when_some(command, |this, command| {
                        // The exact command, as the installer receives it.
                        let copied = command.clone();
                        this.child(
                            div()
                                .px(px(12.))
                                .py(px(8.))
                                .rounded(px(4.))
                                .bg(theme.subtle_hover)
                                .type_mono()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("install-command", command)),
                        )
                        .child(
                            div().flex().child(
                                Button::new("copy-command", t!("common-copy"))
                                    .compact()
                                    .icon(Icon::Copy)
                                    .aria_label(t!("summary-copy-command-a11y"))
                                    .on_click(move |_, _, cx| {
                                        cx.write_to_clipboard(ClipboardItem::new_string(copied.clone()))
                                    }),
                            ),
                        )
                    })
                    .into_any_element(),
            );
        }
        details
    }

    /// One row per choice, with a Change link at its trailing edge when it
    /// can change (see [`choice_row_plan`]). Choices that reduce protection,
    /// or delete the user's data, carry a caution.
    fn choice_rows(&self, cx: &Context<Self>) -> Vec<AnyElement> {
        let state = self.model.read(cx);
        let manifest = state.manifest();
        let options = state.effective_options();
        let editable = state.flow.may_edit();
        let mut rows = Vec::new();
        for (index, row) in choice_row_plan(state).into_iter().enumerate() {
            let (key, title) = if row.kind == ScreenKind::UpdatePath {
                ("choice-path".to_owned(), t!("summary-update-path"))
            } else {
                (format!("choice-{index}"), row.kind.title())
            };
            let kind = row.kind;
            let action = row.change.then(|| {
                Button::new(("change-choice", index), t!("common-change"))
                    .hyperlink()
                    .compact()
                    .aria_label(t!("summary-change-a11y", title = kind.name()))
                    .disabled(!editable)
                    .on_click(cx.listener(move |this, _, _, cx| this.open_change(kind, cx)))
                    .into_any_element()
            });
            let value = if row.kind == ScreenKind::UpdatePath {
                let path = match path_taken(state) {
                    UpdatePath::Keep => t!("update-path-keep"),
                    UpdatePath::ChooseAgain => t!("update-path-choose"),
                };
                detail_text(&key, path).into_any_element()
            } else {
                let chosen = chosen_on(manifest, &row.pages, &options, |option| {
                    ListEntry::install_option(&option.id, &option.label, state.before_desktop)
                });
                choice_value(
                    cx,
                    &key,
                    ("choices", index),
                    &title,
                    row.required,
                    chosen,
                    t!("summary-not-chosen"),
                )
            };
            rows.push(detail_row_with_action(cx, &key, title, value, action).into_any_element());
        }
        rows
    }

    fn log_view(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let state = self.model.read(cx);
        self.log.render(LOG_IDS, 280., LOG_LINES_SHOWN, &state.attempt, cx)
    }
}

/// A row of the summary's choices: the question or extras whose choices it
/// lists, or how an update or reinstall treats them
/// ([`ScreenKind::UpdatePath`]), and whether its Change link shows.
#[derive(Clone, Debug, PartialEq, Eq)]
struct ChoiceRow {
    kind: ScreenKind,
    pages: Vec<usize>,
    required: bool,
    change: bool,
}

/// The summary's rows of choices. An update or reinstall says first how it
/// treats them, with a link to its first screen; an unfinished install that
/// chose again says so too, without one, as it can't change. Then one row
/// per question and one for the extras, each with a link when Your choices
/// asks it and it can change: every one a first install asks, or choosing
/// again; only what's missing when keeping the choices, after Windows
/// rebuilt itself, or in an unfinished update that keeps them; none where
/// the choices are held. A question Atlas answers itself shows its answer
/// without one.
fn choice_row_plan(state: &AppModel) -> Vec<ChoiceRow> {
    let update = state.update_choices().is_some();
    let mut rows = Vec::new();
    if update || state.choosing_again() {
        rows.push(ChoiceRow {
            kind: ScreenKind::UpdatePath,
            pages: Vec::new(),
            required: false,
            change: update,
        });
    }
    let editable = state.locked_options().is_none();
    let asked: Vec<Vec<usize>> = state
        .option_screens()
        .iter()
        .flat_map(|screen| screen.groups().iter().map(|group| group.pages.clone()))
        .collect();
    rows.extend(state.choice_groups().into_iter().map(|group| ChoiceRow {
        change: editable && asked.contains(&group.pages),
        kind: group.kind,
        pages: group.pages,
        required: group.required,
    }));
    rows
}

/// How the summary says the install treats the choices: as this flow chose,
/// or, for an unfinished install, as it began.
fn path_taken(state: &AppModel) -> UpdatePath {
    if state.choosing_again() { UpdatePath::ChooseAgain } else { UpdatePath::Keep }
}

/// The options among `options` that the group of `pages` has chosen, each
/// as `entry` lists it. A page shown only once another option is chosen
/// counts only then.
pub(super) fn chosen_on<T>(
    manifest: &Manifest,
    pages: &[usize],
    options: &[String],
    entry: impl Fn(&ChoiceOption) -> T,
) -> Vec<T> {
    pages
        .iter()
        .filter_map(|&page_index| manifest.choices.get(page_index))
        .filter(|page| page.depends_on.as_ref().is_none_or(|dependency| options.contains(dependency)))
        .flat_map(|page| page.options.iter())
        .filter(|option| options.contains(&option.id))
        .map(entry)
        .collect()
}

/// A row's value in a list of choices, keyed like its row: a required
/// choice's answer, with its caution, or `unmade` when there is none; or the
/// extras chosen, in list `list`, or None.
pub(super) fn choice_value(
    cx: &App,
    key: &str,
    list: (&'static str, usize),
    title: &str,
    required: bool,
    chosen: Vec<ListEntry>,
    unmade: String,
) -> AnyElement {
    if required {
        let (text, caution) = match chosen.into_iter().next() {
            Some(ListEntry { text, caution }) => (text, caution),
            None => (unmade, None),
        };
        div()
            .flex()
            .flex_col()
            .gap(px(2.))
            .min_w_0()
            .child(detail_text(key, text))
            .when_some(caution, |this, caution| {
                this.child(caution_caption(cx, detail_text(&format!("{key}-caution"), caution)))
            })
            .into_any_element()
    } else if chosen.is_empty() {
        div()
            .text_color(cx.theme().text_secondary)
            .child(detail_text(key, t!("common-none")))
            .into_any_element()
    } else {
        plain_list(cx, list, title, chosen).w_full().into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::test_harness::{all_off, run_model_test};
    use crate::pages::testing::{NO_TELEMETRY, installed_model, records};
    use crate::services::atlas_state::{InstallIdentity, InstallMode, Unfinished};
    use crate::services::legacy_choices::Facts;
    use crate::services::requirements::CheckDetail;
    use crate::services::security::SwitchCounts;
    use crate::services::test_support::TempDir;

    /// The rows' kinds and whether each has a Change link.
    fn plan(m: &AppModel) -> Vec<(ScreenKind, bool)> {
        choice_row_plan(m).into_iter().map(|row| (row.kind, row.change)).collect()
    }

    /// An update or reinstall says first how it treats the choices. Keeping
    /// them, only that row can be changed, as every other choice is the
    /// PC's; choosing again, every row opens the questions.
    #[test]
    fn the_summary_says_how_atlas_updates_and_links_only_what_can_change() {
        use ScreenKind::{Defender, Extras, Keyboard, Mitigations, Updates};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-rows");
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("Mitigations", 1), ("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, _| {
                let choices = [Defender, Mitigations, Updates, Keyboard, Extras];
                assert!(m.update_choices().unwrap().complete());
                let with = |change: bool| -> Vec<(ScreenKind, bool)> {
                    std::iter::once((ScreenKind::UpdatePath, true))
                        .chain(choices.iter().map(|kind| (*kind, change)))
                        .collect()
                };
                assert_eq!(plan(m), with(false));
                m.update_path = UpdatePath::ChooseAgain;
                assert_eq!(plan(m), with(true));

                // A first install has no such row, and links every choice.
                m.install_identity = Ok(InstallIdentity::Fresh);
                let first: Vec<_> = choices.iter().map(|kind| (*kind, true)).collect();
                assert_eq!(plan(m), first);
                // One Atlas answers itself shows without a link.
                m.keyboard_layouts = Some(1);
                let detected: Vec<_> = choices.iter().map(|kind| (*kind, *kind != Keyboard)).collect();
                assert_eq!(plan(m), detected);
                m.keyboard_layouts = Some(2);
                // An unfinished install that chose again says so, and nothing can change.
                let unfinished = Unfinished {
                    held: Some(vec!["defender-enable".into()]),
                    choose_again: true,
                    mode: InstallMode::Reapply,
                };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
                m.update_path = UpdatePath::Keep;
                let resumed: Vec<_> = std::iter::once((ScreenKind::UpdatePath, false))
                    .chain(choices.iter().map(|kind| (*kind, false)))
                    .collect();
                assert_eq!(plan(m), resumed);
                assert_eq!(path_taken(m), UpdatePath::ChooseAgain, "as it began, whatever this flow has");
                m.install_identity = Ok(InstallIdentity::Installed("0.6.0".into()));
                assert_eq!(path_taken(m), UpdatePath::Keep);
            });
        });
    }

    /// Keeping the choices, and an unfinished update that will keep them,
    /// link only the question this PC can't show; with every one shown,
    /// none.
    #[test]
    fn keeping_the_choices_links_only_what_it_asks() {
        use ScreenKind::{Defender, Extras, Keyboard, Mitigations, Updates};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-unfinished-keep");
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, _| {
                let asking = [
                    (Defender, false),
                    (Mitigations, true),
                    (Updates, false),
                    (Keyboard, false),
                    (Extras, false),
                ];
                let keeping: Vec<_> = std::iter::once((ScreenKind::UpdatePath, true)).chain(asking).collect();
                assert_eq!(plan(m), keeping);
                let unfinished = Unfinished { held: None, choose_again: false, mode: InstallMode::Upgrade };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
                assert_eq!(plan(m), asking);
                m.pc_facts.toggles.insert("Mitigations".into(), 1);
                let none: Vec<_> = asking.iter().map(|(kind, _)| (*kind, false)).collect();
                assert_eq!(plan(m), none, "nothing to ask");
            });
        });
    }

    /// How Atlas updates leads through Your choices again from its first
    /// screen, so the questions its answer leads to aren't skipped on the
    /// way back to the summary. Any other row opens the questions and
    /// returns straight there; the extras' row unfolds them.
    #[test]
    fn changing_how_atlas_updates_goes_through_the_screens_its_answer_leads_to() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-path-change");
            // No record of processor protections, so keeping the choices asks it.
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, cx| {
                use crate::model::OptionScreen;
                let at = |m: &AppModel| {
                    let screen = m.option_screens()[m.current_option_screen()].clone();
                    let asked: Vec<ScreenKind> = screen.groups().iter().map(|group| group.kind).collect();
                    (m.flow.step, screen == OptionScreen::UpdatePath, asked)
                };
                assert_eq!(m.update_choices().unwrap().missing, [ScreenKind::Mitigations]);
                m.flow.resume(Step::Install).unwrap();
                m.edit_options(ScreenKind::UpdatePath, cx);
                assert_eq!(at(m), (Step::Options, true, Vec::new()));
                m.next_step(cx);
                assert_eq!(
                    at(m),
                    (Step::Options, false, vec![ScreenKind::Mitigations]),
                    "what keeping still asks"
                );

                m.flow.resume(Step::Install).unwrap();
                m.edit_options(ScreenKind::UpdatePath, cx);
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                m.next_step(cx);
                assert_eq!(at(m).2.first(), Some(&ScreenKind::Defender), "every question, choosing again");

                m.flow.resume(Step::Install).unwrap();
                m.show_extras(false, cx);
                assert!(!m.extras_shown);
                m.edit_options(ScreenKind::Extras, cx);
                assert!(m.extras_shown && at(m).0 == Step::Options && !at(m).1);
                m.next_step(cx);
                assert!(m.flow.step > Step::Options, "back towards the summary: {:?}", m.flow.step);
            });
        });
    }

    /// Each bar's button is the next step, so Install Atlas, or Try again,
    /// isn't the accent: a relaunch without permission, Get ready for unmet
    /// requirements, out-of-date updates and changed checks, Your choices at
    /// the question left unanswered. A failure Try again answers has none,
    /// only Windows Security beside it while protection can be turned back
    /// on, and the help row under it.
    #[test]
    fn each_bar_offers_the_next_step_and_help_only_for_unexpected_failures() {
        use InstallOutcome::{Failed, Lost};
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("summary-bars");
            let model = installed_model(&mut cx, &temp, None, Facts::default());
            model.update(&mut cx, |m, _| {
                m.install_identity = Ok(InstallIdentity::Fresh);
                // Defender is here, with its switches off for the install.
                m.security = all_off();
                m.flow.resume(Step::Install).unwrap();
                let result = |m: &mut AppModel, outcome| {
                    m.flow.run = RunState::Finished(outcome);
                    let bar = install_bar(m).unwrap();
                    (bar.action(m), bar.secondary(m), bar.needs_help(m))
                };
                assert_eq!(result(m, Failed(2)), (Some(BarAction::GetReady), None, false));
                assert!(retry_hidden(m), "Try again can't work until Get ready passes again");
                assert_eq!(result(m, Failed(5)), (Some(BarAction::GetReady), None, false));
                assert!(retry_hidden(m));
                assert_eq!(result(m, Failed(1)), (None, None, true), "nothing changed, nothing to turn on");
                assert!(!retry_hidden(m), "Try again is the next step");
                m.attempt.push_lines(vec!["[Atlas] Running the install plan as TrustedInstaller.".into()]);
                assert_eq!(result(m, Failed(1)), (None, Some(BarAction::OpenWindowsSecurity), true));
                assert_eq!(result(m, Lost), (None, Some(BarAction::OpenWindowsSecurity), true));
                m.elevated = false;
                assert_eq!(result(m, Failed(3)), (Some(BarAction::Relaunch), None, false));
                assert!(retry_hidden(m));
                m.elevation_error = Some(ElevationProblem::TakenOver);
                assert_eq!(result(m, Failed(1)).0, Some(BarAction::StartOver));
                m.elevation_error = None;
                m.elevated = true;

                m.flow.run = RunState::Idle;
                let refusal = |m: &mut AppModel, problem| {
                    m.preflight_problem = Some(problem);
                    let bar = install_bar(m).unwrap();
                    (bar.action(m), bar.secondary(m), bar.needs_help(m))
                };
                let counts = SwitchCounts { off: 3, on: 1, unknown: 0 };
                let check = (CheckId::Power, CheckDetail::PowerUnknown);
                assert_eq!(
                    refusal(m, Preflight::Changed { checks: vec![check.clone()], security: Some(counts) }),
                    (Some(BarAction::GetReady), Some(BarAction::OpenWindowsSecurity), false)
                );
                assert_eq!(
                    refusal(m, Preflight::Changed { checks: vec![], security: Some(counts) }),
                    (Some(BarAction::OpenWindowsSecurity), None, false)
                );
                assert!(!retry_hidden(m), "a refusal leaves Install Atlas where it is");
                assert_eq!(refusal(m, Preflight::TakenOver), (Some(BarAction::StartOver), None, false));
                assert_eq!(refusal(m, Preflight::Busy), (None, None, false));
                assert_eq!(refusal(m, Preflight::Refused { error: "x".into() }), (None, None, true));
                assert_eq!(
                    refusal(m, Preflight::RecordUnreadable { error: "x".into() }),
                    (Some(BarAction::GetReady), None, true)
                );
                // The browser picker left without an answer opens the extras, and names it.
                m.options.insert("install-another-browser".into());
                m.options.remove("browser-brave");
                assert_eq!(unanswered_choice(m), Some((ScreenKind::Browser, ScreenKind::Extras)));
                assert_eq!(
                    refusal(m, Preflight::InvalidOptions { error: "x".into() }).0,
                    Some(BarAction::Choices(ScreenKind::Extras))
                );
                assert!(bar_leads(m));
                m.preflight_problem = None;
                m.options.insert("browser-brave".into());
                assert_eq!(unanswered_choice(m), None);
            });
        });
    }
}
