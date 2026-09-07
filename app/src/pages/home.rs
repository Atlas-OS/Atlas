//! Home: what is on this PC, whether something newer exists, and the one
//! button that starts the install.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Render, Role, ScrollHandle, Styled, Window, div,
    prelude::*, px, svg,
};

use super::{card_body, card_header, chip_list, detail_row, detail_text, heading, page_frame};
use crate::i18n::{describe, fmt};
use crate::model::{AppModel, ReleaseCheck};
use crate::services::system::links;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, Icon, InfoBar, LightState, ScrollbarState, Severity, StatusLight, Typography, a11y_text, card,
};

const PREVIEW_BLOCKS: usize = 8;

/// Clone only the blocks the renderer will consume. A collapsed preview
/// must not allocate a copy of the entire release history on every redraw.
fn visible_notes(blocks: &[crate::ui::MarkdownBlock], expanded: bool) -> Vec<crate::ui::MarkdownBlock> {
    let count = if expanded { blocks.len() } else { blocks.len().min(PREVIEW_BLOCKS) };
    blocks[..count].to_vec()
}

pub struct HomePage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    notes_expanded: bool,
    /// The release notes parsed once per release body, not per frame.
    notes: Option<(String, Vec<crate::ui::MarkdownBlock>)>,
}

impl HomePage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            notes_expanded: false,
            notes: None,
        }
    }

    /// The parsed notes for `body`, reusing the last parse when the text is the same.
    fn notes_for(&mut self, body: &str) -> &[crate::ui::MarkdownBlock] {
        if self.notes.as_ref().is_none_or(|(source, _)| source != body) {
            self.notes = Some((body.to_owned(), crate::ui::parse_markdown(body)));
        }
        self.notes.as_ref().map(|(_, blocks)| blocks.as_slice()).unwrap_or_default()
    }
}

impl Render for HomePage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let state = self.model.read(cx);
        let installed = state.installed();
        let installed_version = state.installed_version().map(str::to_owned);
        let update = state.update_available();
        let eligibility_problem = state.install_eligibility_problem();
        let checking = matches!(state.release, ReleaseCheck::Checking);
        let system_text = describe::system_description(&state.system);

        // --- Version stamp -------------------------------------------------
        let headline = match &installed_version {
            Some(version) => t!("home-version", version = version),
            None => t!("home-not-installed"),
        };
        let subline = match installed {
            Some(state) => match state.installed_at_local() {
                Some(when) => t!("home-installed-on", date = fmt::long_date(&when)),
                None => t!("common-installed"),
            },
            None => system_text.clone(),
        };

        let (light, status_text) = if eligibility_problem.is_some() {
            (LightState::Caution, t!("install-source-title"))
        } else {
            match (&state.release, &update, &installed_version) {
                (ReleaseCheck::Checking, _, _) => (LightState::Pending, t!("home-status-checking")),
                (ReleaseCheck::Failed, _, _) => (LightState::Unknown, t!("home-status-offline")),
                (ReleaseCheck::NotChecked, _, _) => (LightState::Unknown, t!("home-status-not-checked")),
                (ReleaseCheck::Ready { .. }, Some(release), _) => {
                    (LightState::Caution, t!("home-status-update", version = release.version()))
                }
                (ReleaseCheck::Ready { .. }, None, Some(_)) => {
                    (LightState::Good, t!("home-status-up-to-date"))
                }
                (ReleaseCheck::Ready { release, .. }, None, None) => {
                    (LightState::Good, t!("home-status-newest", version = release.version()))
                }
            }
        };

        let begin = {
            let model = model.clone();
            move |_: &gpui::ClickEvent, _: &mut Window, cx: &mut gpui::App| {
                model.update(cx, |m, cx| m.begin_install(cx))
            }
        };
        let flow_active = state.flow.active;
        let locked = state.locked();
        // Until startup knows whether an install is running elsewhere,
        // nothing that could start one is offered.
        let recovering = state.recovering;
        let primary = match (flow_active, &installed_version, &update) {
            (true, _, _) => Button::new(
                "home-continue",
                if locked { t!("home-show-install") } else { t!("home-continue-installing") },
            )
            .accent()
            .trailing_icon(Icon::ChevronRight)
            .on_click({
                let model = model.clone();
                move |_, _, cx| model.update(cx, |m, cx| m.navigate(crate::model::Page::Install, cx))
            }),
            (false, _, _) if eligibility_problem.is_some() => {
                Button::new("home-install-unavailable", t!("install-source-title")).disabled(true)
            }
            (false, _, Some(release)) => {
                Button::new("home-update", t!("home-update-to", version = release.version()))
                    .accent()
                    .icon(Icon::Sync)
                    .disabled(recovering)
                    .on_click(begin)
            }
            (false, Some(_), None) => Button::new("home-reinstall", t!("home-reinstall"))
                .icon(Icon::Download)
                .disabled(recovering)
                .on_click(begin),
            (false, None, None) => Button::new("home-install", t!("home-install"))
                .accent()
                .icon(Icon::Download)
                .disabled(recovering)
                .on_click(begin),
        };
        let resume = (flow_active && !locked).then(|| {
            Button::new("home-start-over", t!("home-start-over")).hyperlink().compact().on_click({
                let model = model.clone();
                move |_, _, cx| model.update(cx, |m, cx| m.begin_install(cx))
            })
        });

        let hero = div()
            .flex()
            .items_center()
            .gap(px(24.))
            .pt(px(36.))
            .pb(px(16.))
            .child(
                div()
                    .flex_shrink_0()
                    .size(px(72.))
                    .flex()
                    .items_center()
                    .justify_center()
                    .child(svg().path("brand/atlas-mark.svg").size(px(64.)).text_color(theme.brand)),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .flex_1()
                    .min_w_0()
                    .gap(px(4.))
                    .child(heading("home-headline", 1, headline, cx).map(|this| {
                        if installed_version.is_some() { this.type_title_large() } else { this.type_title() }
                    }))
                    .child(
                        div()
                            .type_body()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("home-subline", subline)),
                    )
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(10.))
                            .mt(px(6.))
                            .child(StatusLight::new(light, status_text).id("home-update-status"))
                            .child(
                                Button::new("home-check", t!("home-check-again"))
                                    .hyperlink()
                                    .compact()
                                    .centre_label()
                                    .disabled(checking)
                                    .on_click({
                                        let model = model.clone();
                                        move |_, _, cx| model.update(cx, |m, cx| m.check_for_updates(cx))
                                    }),
                            ),
                    ),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .items_end()
                    .gap(px(6.))
                    .flex_shrink_0()
                    .child(primary)
                    .when_some(resume, |this, resume| this.child(resume)),
            );

        let mut body: Vec<AnyElement> = vec![hero.into_any_element()];
        if let Some(problem) = eligibility_problem {
            body.push(
                InfoBar::new(Severity::Warning, t!("install-source-title"), problem).into_any_element(),
            );
        }

        if let Some(notice) = &state.notice {
            body.push(
                InfoBar::new(Severity::Warning, notice.title(), notice.message())
                    .id("home-notice")
                    .action(Button::new("home-notice-dismiss", t!("common-dismiss")).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.dismiss_notice(cx))
                    }))
                    .into_any_element(),
            );
        }
        if state.security_reminder {
            body.push(
                InfoBar::new(
                    Severity::Warning,
                    t!("home-security-reminder-title"),
                    t!("home-security-reminder-message"),
                )
                .id("home-security-reminder")
                .action(
                    div()
                        .flex()
                        .gap(px(8.))
                        .child(
                            Button::new("home-security-open", t!("common-open-windows-security"))
                                .icon(Icon::Shield)
                                .opens(links::WINDOWS_SECURITY_PROTECTION),
                        )
                        .child(Button::new("home-security-dismiss", t!("common-done")).subtle().on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.dismiss_security_reminder(cx))
                        })),
                )
                .into_any_element(),
            );
        }
        if let Some(error) = &state.elevation_error {
            body.push(
                InfoBar::new(Severity::Warning, t!("home-elevation-title"), error.text())
                    .id("home-elevation")
                    .action(Button::new("home-elevate", t!("common-try-again")).icon(Icon::Admin).on_click({
                        let model = model.clone();
                        move |_, _, cx| model.update(cx, |m, cx| m.begin_install(cx))
                    }))
                    .into_any_element(),
            );
        }
        if let Err(error) = &state.atlas {
            body.push(
                InfoBar::new(Severity::Error, t!("home-state-error-title"), error.clone())
                    .id("home-state-error")
                    .into_any_element(),
            );
        }

        // --- What's new ------------------------------------------------------
        if let Some(release) = &update {
            // Release notes can run to dozens of lines; keep the fold short.
            // They are the project's own text and stay in the language they
            // were written in.
            let expanded = self.notes_expanded;
            let blocks = self.notes_for(&release.body);
            let collapsible = blocks.len() > PREVIEW_BLOCKS;
            let shown = visible_notes(blocks, expanded);
            body.push(
                card(cx)
                    .child(card_header(
                        cx,
                        "whats-new",
                        t!("home-whats-new", version = release.version()),
                        Some(
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
                        ),
                    ))
                    .child(
                        card_body(cx)
                            .gap(px(2.))
                            .child(
                                div().type_caption().text_color(theme.text_tertiary).pb(px(4.)).child(
                                    a11y_text(
                                        "home-release-date",
                                        fmt::parse_local(&release.published_at)
                                            .map(|when| t!("home-released", date = fmt::long_date(&when)))
                                            .unwrap_or_default(),
                                    ),
                                ),
                            )
                            .child(crate::ui::Markdown::new("home-notes", shown))
                            .when(collapsible, |this| {
                                this.child(
                                    div().flex().pt(px(6.)).child(
                                        Button::new(
                                            "home-notes-toggle",
                                            if expanded {
                                                t!("home-show-less")
                                            } else {
                                                t!("home-show-full-notes")
                                            },
                                        )
                                        .hyperlink()
                                        .compact()
                                        .trailing_icon(if expanded {
                                            Icon::ChevronUp
                                        } else {
                                            Icon::ChevronDown
                                        })
                                        .on_click(cx.listener(
                                            |this, _, _, cx| {
                                                this.notes_expanded = !this.notes_expanded;
                                                cx.notify();
                                            },
                                        )),
                                    ),
                                )
                            }),
                    )
                    .into_any_element(),
            );
        }

        // --- Your install / how it works ------------------------------------
        match installed {
            Some(installed) => {
                let options: Vec<String> = installed.options.iter().map(|o| state.option_label(o)).collect();
                let history: Vec<String> = installed
                    .history
                    .iter()
                    .rev()
                    .take(4)
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
                let mode = installed.install_mode().label();
                body.push(
                    card(cx)
                        .child(card_header(cx, "your-install", t!("home-your-install"), None))
                        .child(
                            card_body(cx)
                                .child(detail_row(
                                    cx,
                                    "mode",
                                    t!("common-installed-as"),
                                    detail_text("mode", mode),
                                ))
                                .child(detail_row(
                                    cx,
                                    "windows",
                                    t!("common-windows"),
                                    detail_text("windows", system_text.clone()),
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
                                        chip_list(cx, "home-options", &t!("common-options"), options)
                                            .into_any_element()
                                    },
                                ))
                                .when(installed.is_oobe, |this| {
                                    this.child(detail_row(
                                        cx,
                                        "set-up",
                                        t!("home-set-up"),
                                        detail_text("set-up", t!("home-set-up-during-oobe")),
                                    ))
                                })
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
                                            .children(history.into_iter().enumerate().map(
                                                |(index, line)| {
                                                    div()
                                                        .id(("history", index))
                                                        .role(Role::ListItem)
                                                        .aria_label(line.clone())
                                                        .type_caption()
                                                        .text_color(theme.text_secondary)
                                                        .child(line)
                                                },
                                            )),
                                    ))
                                }),
                        )
                        .into_any_element(),
                );
            }
            None => {
                let minutes = state.manifest().estimated_minutes;
                body.push(
                    card(cx)
                        .child(card_header(cx, "how-it-works", t!("home-how-it-works"), None))
                        .child(
                            div()
                                .px(px(16.))
                                .pt(px(16.))
                                .type_body()
                                .text_color(theme.text_secondary)
                                .child(a11y_text("home-intro", t!("home-intro"))),
                        )
                        .child(
                            div()
                                .id("home-steps")
                                .role(Role::List)
                                .aria_label(t!("home-how-it-works"))
                                .child(
                                    card_body(cx)
                                        .child(step_line(
                                            window,
                                            cx,
                                            1,
                                            t!("home-step-1-title"),
                                            t!("home-step-1-detail"),
                                        ))
                                        .child(step_line(
                                            window,
                                            cx,
                                            2,
                                            t!("home-step-2-title"),
                                            t!("home-step-2-detail"),
                                        ))
                                        .child(step_line(
                                            window,
                                            cx,
                                            3,
                                            t!("home-step-3-title"),
                                            t!("home-step-3-detail"),
                                        ))
                                        .child(step_line(
                                            window,
                                            cx,
                                            4,
                                            t!("home-step-4-title"),
                                            t!("home-step-4-detail", minutes = minutes),
                                        )),
                                ),
                        )
                        .into_any_element(),
                );
            }
        }

        // Installation media is an alternative to setting up this PC. Keep it
        // after the setup overview, without a competing card or full-width CTA.
        body.push(
            div()
                .flex()
                .items_center()
                .gap(px(20.))
                .px(px(16.))
                .py(px(12.))
                .child(
                    div()
                        .flex_1()
                        .min_w_0()
                        .flex()
                        .flex_col()
                        .gap(px(4.))
                        .child(
                            div()
                                .flex()
                                .items_center()
                                .gap(px(8.))
                                .child(
                                    heading("iso-home-title", 2, t!("iso-home-title"), cx)
                                        .type_caption()
                                        .text_color(theme.text_secondary),
                                )
                                .child(
                                    div()
                                        .id("home-iso-beta")
                                        .role(Role::Label)
                                        .aria_label(t!("iso-beta"))
                                        .flex()
                                        .items_center()
                                        .min_h(px(20.))
                                        .px(px(8.))
                                        .py(px(2.))
                                        .rounded_full()
                                        .type_caption()
                                        .font_weight(gpui::FontWeight::SEMIBOLD)
                                        .text_color(if theme.high_contrast {
                                            theme.text_primary
                                        } else if theme.is_dark() {
                                            gpui::rgb(0xC4B5FD).into()
                                        } else {
                                            gpui::rgb(0x6941A5).into()
                                        })
                                        .bg(if theme.high_contrast {
                                            theme.transparent()
                                        } else if theme.is_dark() {
                                            gpui::rgb(0xC4B5FD).opacity(0.12).into()
                                        } else {
                                            gpui::rgb(0x6941A5).opacity(0.10).into()
                                        })
                                        .when(theme.high_contrast, |this| {
                                            this.border_1().border_color(theme.text_primary)
                                        })
                                        .child(crate::ui::CapCenteredText(t!("iso-beta").into())),
                                ),
                        )
                        .child(
                            div()
                                .type_caption()
                                .text_color(theme.text_secondary)
                                .child(detail_text("iso-home-description", t!("iso-home-description"))),
                        ),
                )
                .child(
                    Button::new("home-create-iso", t!("iso-open"))
                        .hyperlink()
                        .compact()
                        .disabled(locked || recovering)
                        .on_click({
                            let model = model.clone();
                            move |_, _, cx| model.update(cx, |m, cx| m.navigate(crate::model::Page::Iso, cx))
                        }),
                )
                .into_any_element(),
        );

        body.push(
            div()
                .flex()
                .flex_wrap()
                .gap(px(4.))
                .child(
                    Button::new("home-docs", t!("common-read-the-docs"))
                        .hyperlink()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(links::DOCS),
                )
                .child(
                    Button::new("home-github", t!("home-github"))
                        .hyperlink()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(links::GITHUB),
                )
                .child(
                    Button::new("home-discord", t!("home-discord"))
                        .hyperlink()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(links::DISCORD),
                )
                .child(
                    Button::new("home-issues", t!("home-report-problem"))
                        .hyperlink()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(links::ISSUES),
                )
                .into_any_element(),
        );

        page_frame("home-scroll", None, None, (&self.scroll, &self.scrollbar), body, None, cx)
    }
}

/// A numbered line: the install really is a sequence, so the numbers carry meaning.
fn step_line(
    window: &Window,
    cx: &gpui::App,
    number: usize,
    title: String,
    detail: String,
) -> gpui::Stateful<gpui::Div> {
    let theme = cx.theme();
    let mut title_font = gpui::font(crate::theme::FONT_TEXT);
    title_font.weight = gpui::FontWeight::SEMIBOLD;
    let font_id = cx.text_system().resolve_font(&title_font);
    let cap_height = cx.text_system().cap_height(font_id, gpui::rems(14. / 16.).to_pixels(window.rem_size()));
    let title_top = (crate::ui::BODY_LINE_HEIGHT.to_pixels(window.rem_size()) - cap_height) / 2.;
    div()
        .id(("home-step", number))
        .role(Role::ListItem)
        .aria_label(t!("home-step-a11y", number = number, title = title.as_str()))
        .aria_description(detail.clone())
        .aria_position_in_set(number)
        .aria_size_of_set(4)
        .flex()
        .items_start()
        .gap(px(12.))
        .py(px(4.))
        .child(
            div()
                .flex()
                .items_center()
                .justify_center()
                .flex_shrink_0()
                .size(px(22.))
                .mt(title_top)
                .rounded_full()
                .border_1()
                .border_color(theme.control_strong_stroke)
                .text_color(theme.text_secondary)
                .child(crate::ui::centred_step_number(number.to_string())),
        )
        .child(
            div()
                .flex()
                .flex_col()
                .flex_1()
                .min_w_0()
                .child(
                    div()
                        .type_body_strong()
                        .text_color(theme.text_primary)
                        .child(crate::ui::CapCenteredText(title.into())),
                )
                .child(div().type_caption().text_color(theme.text_secondary).child(detail)),
        )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn release_note_previews_keep_the_original_prefix_and_expand_completely() {
        let blocks = crate::ui::parse_markdown(&"A release note with **formatting**.\n\n".repeat(100));
        let preview = visible_notes(&blocks, false);
        assert_eq!(preview.len(), PREVIEW_BLOCKS);
        assert_eq!(format!("{preview:?}"), format!("{:?}", &blocks[..PREVIEW_BLOCKS]));
        assert_eq!(visible_notes(&blocks, true).len(), blocks.len());
        assert!(visible_notes(&[], false).is_empty());
        assert_eq!(visible_notes(&blocks[..2], false).len(), 2);
    }

    #[test]
    #[ignore = "manual allocation benchmark; run with --ignored --nocapture"]
    fn benchmark_collapsed_release_notes() {
        use std::hint::black_box;
        use std::time::Instant;
        let source = "A release note with **formatting** and [a link](https://atlasos.net).\n\n".repeat(5000);
        let blocks = crate::ui::parse_markdown(&source);
        let iterations = 1000;
        let before = Instant::now();
        for _ in 0..iterations {
            let copied = black_box(&blocks).clone();
            black_box(copied.into_iter().take(PREVIEW_BLOCKS).collect::<Vec<_>>());
        }
        let before = before.elapsed();
        let after = Instant::now();
        for _ in 0..iterations {
            black_box(visible_notes(black_box(&blocks), false));
        }
        let after = after.elapsed();
        println!(
            "{iterations} previews of {} parsed blocks: full clone {before:?}, visible prefix {after:?}",
            blocks.len()
        );
    }
}
