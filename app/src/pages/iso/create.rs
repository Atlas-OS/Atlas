//! Step 3, Create: where the new ISO goes and whether it fits there, then
//! everything it's built from, a card per earlier step with Change; then
//! the build's progress, and the finished ISO.

use super::*;
use crate::model::ScreenKind;
use crate::pages::{ListEntry, card_header, caution_caption, detail_row, plain_list};
use crate::services::package::ChoiceKind;

impl IsoPage {
    pub(super) fn create_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let secondary = cx.theme().text_secondary;
        let mut cards = Vec::new();
        // Where a build stopped, as the checklist it showed while running,
        // under the bar that says so.
        if self.failed_stage().is_some() {
            cards.push(card(cx).child(card_body().child(self.stage_list(true, cx))).into_any_element());
        }
        // A result's bar says what became of the original ISO already.
        if self.result == JobResult::None {
            cards.push(
                div()
                    .type_body()
                    .text_color(secondary)
                    .child(detail_text("iso-create-intro", t!("iso-create-intro")))
                    .into_any_element(),
            );
        }
        // First, so a destination without room is in view.
        cards.push(self.output_card(cx));
        cards.push(self.review_windows(cx));
        cards.push(self.review_setup(cx));
        cards
    }

    fn change_link(&self, id: &'static str, step: IsoStep, cx: &mut Context<Self>) -> AnyElement {
        Button::new(id, t!("common-change"))
            .hyperlink()
            .compact()
            // The step's title as shown, after a colon: titles aren't
            // written to read mid-sentence.
            .aria_label(t!("iso-pick-a11y", action = t!("common-change"), field = step.title()))
            .on_click(cx.listener(move |this, _, _, cx| this.go_to_step(step, cx)))
            .into_any_element()
    }

    /// The Windows step: the PC, the Windows ISO, its editions and the package.
    fn review_windows(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let secondary = cx.theme().text_secondary;
        let mut rows = card_body().gap(px(4.)).child(detail_row(
            cx,
            "iso-target",
            t!("iso-review-target"),
            detail_text(
                "iso-review-target",
                if self.reinstall_this_pc { t!("iso-target-this") } else { t!("iso-target-another") },
            ),
        ));
        if let Some(path) = &self.source {
            // The image's architecture and size, under its name and folder.
            let facts = self.image.as_ref().map(|image| {
                [architecture_text(image.architecture), describe::file_size(image.bytes)]
                    .join(&t!("usb-detail-separator"))
            });
            rows = rows.child(detail_row(
                cx,
                "iso-source",
                t!("iso-source"),
                file_value("iso-review-source", path, cx).when_some(facts, |this, facts| {
                    this.child(
                        div()
                            .type_caption()
                            .text_color(secondary)
                            .child(detail_text("iso-review-image", facts)),
                    )
                }),
            ));
        }
        if let Some(image) = &self.image {
            let editions: Vec<String> =
                self.edition.as_ref().map(std::slice::from_ref).unwrap_or(&image.editions).to_vec();
            let several = editions.len() > 1;
            let label = if several { t!("iso-review-editions") } else { t!("iso-review-edition") };
            let value = if several {
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .min_w_0()
                    .child(plain_list(
                        cx,
                        "iso-editions",
                        &label,
                        editions.into_iter().map(ListEntry::new).collect(),
                    ))
                    .child(
                        div()
                            .type_caption()
                            .text_color(secondary)
                            .child(detail_text("iso-edition-selection", t!("iso-edition-selection"))),
                    )
                    .into_any_element()
            } else {
                detail_text("iso-review-edition", editions.into_iter().next().unwrap_or_default())
                    .into_any_element()
            };
            rows = rows.child(detail_row(cx, "iso-editions", label, value));
        }
        let package = if self.model.read(cx).bundled() && self.archive.is_none() {
            // A tester build adds its bundled package; say so rather than
            // leaving the row out.
            Some(t!("iso-package-bundled"))
        } else {
            self.manifest.as_ref().map(|manifest| format!("Atlas {}", manifest.version))
        };
        if let Some(package) = package {
            rows = rows.child(detail_row(
                cx,
                "iso-package",
                t!("iso-review-package"),
                detail_text("iso-review-package", package),
            ));
        }
        let change = self.change_link("iso-change-windows", IsoStep::Windows, cx);
        card(cx)
            .child(card_header(cx, "iso-review-windows", IsoStep::Windows.title(), change))
            .child(rows)
            .into_any_element()
    }

    /// The Setup step: the account, the setup screens it skips, the licence
    /// terms, the drivers and the Atlas choices. Rows that would say "None"
    /// are left out.
    fn review_setup(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let accepted = self.accept_terms
            && self.image.as_ref().is_some_and(|image| image.terms(self.edition.as_deref()).is_some());
        let mut rows = card_body()
            .gap(px(4.))
            .child(detail_row(
                cx,
                "iso-account",
                t!("iso-review-account"),
                detail_text("iso-review-account", self.username.read(cx).value().to_string()),
            ))
            .child(detail_row(
                cx,
                "iso-setup-screens",
                t!("iso-review-setup-screens"),
                detail_text(
                    "iso-review-setup-screens",
                    if accepted { t!("iso-review-skips-terms") } else { t!("iso-review-skips") },
                ),
            ))
            .child(detail_row(
                cx,
                "iso-drivers",
                t!("iso-review-drivers"),
                // The values Get ready's driver row shows.
                detail_text(
                    "iso-review-drivers",
                    match self.drivers {
                        Some(Drivers::Automatic) => t!("ready-drivers-automatic"),
                        Some(Drivers::Manual) => t!("ready-drivers-manual"),
                        None => t!("iso-drivers-defer"),
                    },
                ),
            ));
        if self.reinstall_this_pc && self.copy_network_drivers {
            rows = rows.child(detail_row(
                cx,
                "iso-network",
                t!("iso-review-network"),
                detail_text("iso-review-network", t!("iso-review-network-included")),
            ));
        }
        let mode = match self.effective_mode() {
            Mode::Interactive => t!("iso-mode-after"),
            Mode::Configured => t!("iso-mode-now"),
            Mode::BeforeDesktop => t!("iso-review-mode-before-desktop"),
        };
        rows = rows
            .child(detail_row(cx, "iso-mode", t!("iso-atlas-options"), detail_text("iso-review-mode", mode)))
            .children(self.choice_rows(cx));
        let change = self.change_link("iso-change-setup", IsoStep::Setup, cx);
        card(cx)
            .child(card_header(cx, "iso-review-setup", IsoStep::Setup.title(), change))
            .child(rows)
            .into_any_element()
    }

    /// One row per choice page the ISO carries, with what was chosen on it.
    /// A choice that reduces protection says what it means; extras with
    /// nothing ticked are left out.
    fn choice_rows(&self, cx: &App) -> Vec<AnyElement> {
        let Some(manifest) = self.manifest.as_ref().filter(|_| self.effective_mode() != Mode::Interactive)
        else {
            return vec![];
        };
        package::follow_parents(&manifest.choices, (0..manifest.choices.len()).collect())
            .into_iter()
            .map(|index| (index, &manifest.choices[index]))
            .filter(|(_, page)| page.depends_on.as_ref().is_none_or(|name| self.options.contains(name)))
            .filter_map(|(index, page)| {
                let title = ScreenKind::of_choice(page).title();
                let key = format!("iso-choice-{index}");
                let chosen: Vec<ListEntry> = page
                    .options
                    .iter()
                    .filter(|option| self.options.contains(&option.id))
                    .map(|option| ListEntry::option(&option.id, &option.label))
                    .collect();
                let value = if page.kind == ChoiceKind::Single {
                    let ListEntry { text, caution } = chosen.into_iter().next()?;
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .min_w_0()
                        .child(detail_text(&key, text))
                        .when_some(caution, |this, caution| {
                            this.child(caution_caption(cx, detail_text(&format!("{key}-caution"), caution)))
                        })
                        .into_any_element()
                } else if chosen.is_empty() {
                    return None;
                } else {
                    plain_list(cx, ("iso-choice-list", index), &title, chosen).into_any_element()
                };
                Some(detail_row(cx, &key, title, value).into_any_element())
            })
            .collect()
    }

    /// Where the new ISO goes, with Change, and whether it fits there: the
    /// space it needs against the space free, or what stops it.
    fn output_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        let mut body = card_body().gap(px(4.));
        if let Some(path) = &self.output {
            body = body.child(file_value("iso-review-output", path, cx));
        }
        if let Some(destination) = &self.destination {
            let size = describe::file_size;
            let (text, colour) = match destination.problem {
                None => (
                    t!(
                        "iso-destination-space",
                        needed = size(destination.needed),
                        free = size(destination.free),
                        drive = destination.drive.as_str()
                    ),
                    theme.text_secondary,
                ),
                Some(iso::DestinationProblem::Space) => (
                    t!(
                        "iso-destination-short",
                        needed = size(destination.needed),
                        free = size(destination.free),
                        drive = destination.drive.as_str()
                    ),
                    theme.critical,
                ),
                Some(iso::DestinationProblem::FileSystem) => {
                    (t!("iso-destination-filesystem", drive = destination.drive.as_str()), theme.critical)
                }
                Some(iso::DestinationProblem::Unusable) => (t!("iso-destination-unusable"), theme.critical),
            };
            body = body.child(
                div()
                    .id("iso-destination")
                    .role(Role::Status)
                    .aria_label(text.clone())
                    .type_caption()
                    .text_color(colour)
                    .child(text),
            );
            // Space can be freed where Windows manages it; the page reads the
            // volume again by itself. Create ISO waits, so this is the way on.
            if destination.problem == Some(iso::DestinationProblem::Space) {
                body = body.child(
                    div().pt(px(4.)).flex().child(
                        Button::new("iso-open-storage", t!("usb-open-storage"))
                            .accent()
                            .trailing_icon(Icon::OpenInNewWindow)
                            .opens(STORAGE_SETTINGS),
                    ),
                );
            }
        }
        // Hidden while it can't work, as the Windows step's Change is.
        let change = if self.model.read(cx).locked() {
            div().into_any_element()
        } else {
            Button::new("iso-change-output", t!("common-change"))
                .hyperlink()
                .compact()
                .aria_label(t!(
                    "iso-pick-a11y",
                    action = t!("common-change"),
                    field = t!("iso-review-output")
                ))
                .on_click(cx.listener(|this, _, _, cx| this.pick_output(cx)))
                .into_any_element()
        };
        card(cx)
            .child(card_header(cx, "iso-review-output", t!("iso-review-output"), change))
            .child(body)
            .into_any_element()
    }

    /// The build under way, laid out as the USB page's write: the heading
    /// with the percentage, one bar that only grows and is named after the
    /// stage, then the checklist of stages. Cancelling changes the heading.
    pub(super) fn progress_card(&mut self, focus: &FocusHandle, cx: &mut Context<Self>) -> AnyElement {
        let secondary = cx.theme().text_secondary;
        let cancelling = self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
        let heading = if cancelling { t!("iso-cancelling-short") } else { t!("iso-progress-title") };
        let label = t!("iso-progress-stage", stage = stage_text(self.stage));
        let value = self.peak;
        let percent = (value * 100.).floor() as u64;
        card(cx)
            .child(
                card_body()
                    .gap(px(12.))
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap(px(8.))
                            .child(
                                div()
                                    .flex()
                                    .items_center()
                                    .justify_between()
                                    .gap(px(16.))
                                    .child(
                                        super::super::focusable_heading(
                                            "iso-progress-title",
                                            2,
                                            heading,
                                            focus,
                                            cx,
                                        )
                                        .m(px(-1.))
                                        .min_w_0(),
                                    )
                                    .child(div().flex_shrink_0().type_body().text_color(secondary).child(
                                        a11y_text("iso-percent", t!("usb-percent", percent = percent)),
                                    )),
                            )
                            // The one live node while creating: it names the stage.
                            .child(ProgressBar::new("iso-progress", label, Some(value)).live()),
                    )
                    .child(self.stage_list(false, cx))
                    .child(
                        div()
                            .type_body()
                            .text_color(secondary)
                            .child(detail_text("iso-progress-keep-open", t!("iso-progress-keep-open"))),
                    ),
            )
            .into_any_element()
    }

    /// The finished ISO: that it's ready, the backup to make before using
    /// it, where it is, and what the build found about network drivers.
    pub(super) fn complete_card(&mut self, focus: &FocusHandle, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        let mut body = card_body()
            .gap(px(8.))
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(12.))
                    .child(
                        TextMark::new(div().text_color(theme.success).child(icon(Icon::Completed)), false)
                            .natural_text(),
                    )
                    .child(
                        super::super::focusable_heading("iso-complete", 2, t!("iso-complete"), focus, cx)
                            .type_subtitle(),
                    ),
            )
            .child(div().type_body().child(detail_text("iso-complete-backup", t!("iso-complete-backup"))));
        if self.network_inbox {
            body = body.child(
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(detail_text("iso-network-inbox", t!("iso-network-inbox"))),
            );
        }
        if let Some(path) = self.output.clone() {
            body = body.child(
                div()
                    .pt(px(4.))
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(12.))
                    .gap_y(px(4.))
                    .child(div().min_w_0().child(file_value("iso-created-file", &path, cx)))
                    .child(
                        Button::new("iso-reveal", t!("iso-open-folder"))
                            .icon(Icon::Folder)
                            .on_click(move |_, _, cx| cx.reveal_path(&path)),
                    ),
            );
        }
        card(cx).child(body).into_any_element()
    }
}
