//! Step 2, Setup: the Windows the ISO installs (its edition and licence
//! terms, the local account and the drivers) and how Atlas is set up from
//! it. The Now mode, which makes the Atlas choices on the ISO, shows the
//! package's questions inline, as Your choices asks them, with the optional
//! extras folded.

use std::collections::BTreeSet;

use gpui::ElementId;

use super::*;
use crate::model::ScreenKind;
use crate::pages::{OptionChoice, OptionNote, option_page_body};
use crate::services::package::ChoiceKind;
use crate::ui::CheckBox;

/// The focus key, and element id, of the edition menu's item at `index`.
fn edition_item_key(index: usize) -> String {
    format!("iso-menu-edition-{index}")
}

/// Whether the questions on `pages` include one the Atlas folder on the
/// desktop can change later: Defender, processor protections or updates.
fn changeable_later(manifest: &Manifest, pages: &[usize]) -> bool {
    pages.iter().any(|&index| {
        matches!(
            ScreenKind::of_choice(&manifest.choices[index]),
            ScreenKind::Defender | ScreenKind::Mitigations | ScreenKind::Updates
        )
    })
}

/// The manifest's choices as Setup asks them: each top-level single choice
/// as a question card, then the rest as the optional extras, in the order
/// the install flow shows them.
fn question_pages(manifest: &Manifest) -> (Vec<usize>, Vec<usize>) {
    let (questions, extras): (Vec<usize>, Vec<usize>) = (0..manifest.choices.len()).partition(|&index| {
        let choice = &manifest.choices[index];
        choice.kind == ChoiceKind::Single && choice.depends_on.is_none()
    });
    (questions, package::follow_parents(&manifest.choices, extras))
}

/// How many of the extras on `pages` are ticked, counting only the pages
/// that show.
fn extras_ticked(manifest: &Manifest, pages: &[usize], options: &BTreeSet<String>) -> usize {
    pages
        .iter()
        .map(|&index| &manifest.choices[index])
        .filter(|page| page.depends_on.as_ref().is_none_or(|parent| options.contains(parent)))
        .flat_map(|page| page.options.iter())
        .filter(|option| options.contains(&option.id))
        .count()
}

/// The line under an option, as Your choices words it: what an answer other
/// than the recommended one costs, and what a check box does. A fresh
/// Windows has no Edge data, so removing Edge needs no warning.
fn option_note(page_kind: ChoiceKind, option: &crate::services::package::ChoiceOption) -> OptionNote {
    let name = option.id.as_str();
    let recommended =
        page_kind == ChoiceKind::Single && option.default && !describe::cost_shown_as_default(name);
    OptionNote::from(if recommended { None } else { describe::option_line(name, true) })
}

impl IsoPage {
    pub(super) fn setup_cards(&mut self, window: &mut Window, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let mut cards = vec![self.edition_card(window, cx), self.account_card(cx), self.drivers_card(cx)];
        cards.push(self.mode_card(cx));
        if self.effective_mode() != Mode::Interactive {
            cards.extend(self.question_cards(cx));
        }
        cards
    }

    /// The edition the ISO installs, with Change when it has several, which
    /// opens the list of them at once, and the licence terms to accept now
    /// so Windows Setup doesn't ask.
    fn edition_card(&mut self, window: &mut Window, cx: &mut Context<Self>) -> AnyElement {
        let mut body = card_body().child(card_title(cx, "iso-edition", t!("iso-edition"), 3));
        let Some(image) = self.image.clone() else { return card(cx).child(body).into_any_element() };
        let several = image.editions.len() > 1;
        let label = self
            .edition
            .clone()
            .or_else(|| (!several).then(|| image.editions.first().cloned()).flatten())
            .unwrap_or_else(|| t!("iso-edition-auto"));
        let change_focus = self.focus.get("iso-change-edition", cx);
        let anchor = self.edition_menu_anchor.clone();
        body = body.child(
            div()
                .flex()
                .flex_wrap()
                .items_center()
                .gap_x(px(8.))
                .child(div().type_body().child(detail_text("iso-selected-edition", label)))
                .when(several, |row| {
                    row.child(
                        div()
                            .relative()
                            .child(
                                Button::new("iso-change-edition", t!("common-change"))
                                    .compact()
                                    .hyperlink()
                                    // Invokable rather than expandable: the menu it
                                    // opens takes focus, which is what announces it.
                                    .focus_handle(change_focus.clone())
                                    .aria_label(t!(
                                        "iso-pick-a11y",
                                        action = t!("common-change"),
                                        field = t!("iso-edition")
                                    ))
                                    .on_click(cx.listener(|this, _, window, cx| {
                                        this.edition_menu = !this.edition_menu;
                                        if this.edition_menu {
                                            let current = this.edition_menu_current();
                                            let item = this.focus.get(&edition_item_key(current), cx);
                                            window.focus(&item, cx);
                                        }
                                        cx.notify();
                                    })),
                            )
                            .child(menu::anchor(anchor)),
                    )
                }),
        );
        if several && self.edition_menu {
            body = body.child(self.edition_menu_flyout(&image.editions, change_focus, window, cx));
        }
        if let Some(hash) = image.terms(self.edition.as_deref()) {
            let terms = self.terms_folder.as_ref().map(|dir| dir.join(format!("windows-terms-{hash}.txt")));
            body = body
                .child(
                    CheckBox::new("iso-accept-terms", t!("iso-accept-terms-optional"), self.accept_terms)
                        .on_toggle(cx.listener(|this, _, _, cx| {
                            this.accept_terms = !this.accept_terms;
                            cx.notify();
                        })),
                )
                // On the card's text edge, as every line that starts the card's column.
                .child(link_row().child(
                    Button::new("iso-read-terms", t!("windows-terms-link")).compact().hyperlink().on_click(
                        move |_, _, cx| {
                            if let Some(path) = &terms {
                                cx.open_url(&path.to_string_lossy());
                            }
                        },
                    ),
                ));
        } else {
            body = body.child(
                div()
                    .type_body()
                    .text_color(cx.theme().text_secondary)
                    .child(detail_text("iso-terms-in-setup", t!("iso-terms-in-setup"))),
            );
        }
        card(cx).child(body).into_any_element()
    }

    /// Takes the edition chosen in the menu, `None` for Windows Setup to
    /// ask. Terms accepted for another edition no longer stand.
    pub(super) fn choose_edition(&mut self, choice: Option<String>) {
        if self.edition != choice {
            self.edition = choice;
            self.accept_terms = false;
        }
        self.edition_chosen = true;
        self.edition_menu = false;
    }

    /// The menu item that stands for the edition chosen now: Windows Setup
    /// asks first, then each edition in the ISO's order.
    pub(super) fn edition_menu_current(&self) -> usize {
        let editions = self.image.as_ref().map(|image| image.editions.as_slice()).unwrap_or_default();
        self.edition
            .as_ref()
            .and_then(|edition| editions.iter().position(|name| name == edition))
            .map_or(0, |i| i + 1)
    }

    /// The edition's Change menu: Windows Setup asks, or one of the ISO's
    /// editions, with the current one checked.
    fn edition_menu_flyout(
        &mut self,
        editions: &[String],
        change: FocusHandle,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let entity = cx.entity();
        let close: menu::Command = {
            let (entity, change) = (entity.clone(), change.clone());
            Rc::new(move |window, cx| {
                entity.update(cx, |this, cx| {
                    this.edition_menu = false;
                    cx.notify();
                });
                window.focus(&change, cx);
            })
        };
        let current = self.edition_menu_current();
        let choices = std::iter::once((t!("iso-edition-auto-menu"), None))
            .chain(editions.iter().map(|edition| (edition.clone(), Some(edition.clone()))));
        let commands = choices
            .enumerate()
            .map(|(index, (label, choice))| {
                let entity = entity.clone();
                let run: menu::Command = Rc::new(move |_, cx| {
                    let choice = choice.clone();
                    entity.update(cx, |this, cx| {
                        this.choose_edition(choice);
                        cx.notify();
                    })
                });
                let key = edition_item_key(index);
                menu::MenuCommand {
                    id: ElementId::Name(key.clone().into()),
                    label,
                    focus: self.focus.get(&key, cx),
                    checked: Some(index == current),
                    run,
                }
            })
            .collect();
        menu::flyout(t!("iso-edition").into(), commands, self.edition_menu_anchor.get(), close, window, cx)
    }

    /// The local account Windows Setup creates: its name, with the help
    /// under the field and any problem marked on it.
    fn account_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let error = account_error(self.username.read(cx).value());
        let help = t!("iso-account-help");
        self.username.update(cx, |input, _| {
            input.set_error(error.map(Into::into));
            input.set_description(Some(help.clone().into()));
        });
        card(cx)
            .child(
                card_body()
                    .child(card_title(cx, "iso-account", t!("iso-username"), 3))
                    .child(self.username.clone())
                    // The field's description reads the help, so the line shows it only.
                    .child(div().type_caption().text_color(cx.theme().text_secondary).child(help)),
            )
            .into_any_element()
    }

    /// The drivers: this PC's network drivers on the ISO, when it's for this
    /// PC, and how drivers are installed after sign-in, asked as Get ready
    /// asks it, with Get ready itself asking as the third answer.
    fn drivers_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let entity = cx.entity();
        let choices = [Some(Drivers::Automatic), Some(Drivers::Manual), None];
        let question = t!("prepare-drivers");
        let drivers = RadioGroup::new("iso-drivers", question.clone())
            .items(crate::pages::driver_radio_items("iso-drivers", &mut self.focus, cx))
            .items([RadioItem::new(
                "iso-drivers-defer",
                t!("iso-drivers-defer"),
                self.focus.get("iso-drivers-defer", cx),
            )])
            .selected(choices.iter().position(|&choice| choice == self.drivers))
            .on_select(move |index, _, cx| {
                entity.update(cx, |this, cx| {
                    this.drivers = choices[index];
                    cx.notify();
                })
            });
        let theme = cx.theme().clone();
        let mut body = card_body().child(card_title(cx, "iso-drivers", t!("iso-drivers-card"), 3));
        if self.reinstall_this_pc {
            body = body.child(
                CheckBox::new("iso-copy-network", t!("iso-network-drivers"), self.copy_network_drivers)
                    .on_toggle(cx.listener(|this, _, _, cx| {
                        this.copy_network_drivers = !this.copy_network_drivers;
                        cx.notify();
                    })),
            );
        }
        // The group carries the question as its name, so the label shows it only.
        body = body
            .child(div().pt(px(4.)).type_body_strong().text_color(theme.text_primary).child(question))
            .child(drivers);
        card(cx).child(body).into_any_element()
    }

    /// When the Atlas choices are made: after sign-in, which needs nothing
    /// more, or now, saved in the ISO, optionally finishing before the
    /// desktop opens. A package that can't carry choices says so instead.
    fn mode_card(&mut self, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        if !self.setup_available {
            // Nothing to answer, so the card names what it's about, not the question.
            let body = card_body().child(card_title(cx, "iso-mode", t!("iso-atlas-options"), 3)).child(
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(detail_text("iso-mode-unavailable", t!("iso-mode-unavailable"))),
            );
            return card(cx).child(body).into_any_element();
        }
        let entity = cx.entity();
        let now = self.mode != Mode::Interactive;
        let mut body = card_body().child(card_title(cx, "iso-mode", t!("iso-mode-question"), 3)).child(
            RadioGroup::new("iso-mode", t!("iso-mode-question"))
                .items([
                    RadioItem::new(
                        "iso-mode-after",
                        t!("iso-mode-after"),
                        self.focus.get("iso-mode-after", cx),
                    )
                    .description(t!("iso-mode-after-description")),
                    RadioItem::new("iso-mode-now", t!("iso-mode-now"), self.focus.get("iso-mode-now", cx))
                        .description(t!("iso-mode-now-description")),
                ])
                .selected(Some(usize::from(now)))
                .on_select(move |index, _, cx| {
                    entity.update(cx, |this, cx| {
                        this.mode = if index == 0 { Mode::Interactive } else { Mode::Configured };
                        cx.notify();
                    })
                }),
        );
        if now {
            // Under Now's label: the radio's 20px glyph and 12px gap.
            body = body.child(
                div().pl(px(32.)).child(
                    CheckBox::new(
                        "iso-mode-before-desktop",
                        t!("iso-mode-before-desktop"),
                        self.mode == Mode::BeforeDesktop,
                    )
                    .description(t!("iso-mode-before-desktop-description"))
                    .on_toggle(cx.listener(|this, _, _, cx| {
                        this.mode = if this.mode == Mode::BeforeDesktop {
                            Mode::Configured
                        } else {
                            Mode::BeforeDesktop
                        };
                        cx.notify();
                    })),
                ),
            );
        }
        card(cx).child(body).into_any_element()
    }

    /// The package's questions, a card each with the question as its title,
    /// then the optional extras folded into one card. One line above them
    /// says which choices the Atlas folder can change later, as Your choices
    /// says it, when one of those is asked.
    fn question_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let Some(manifest) = self.manifest.clone() else { return Vec::new() };
        let options: BTreeSet<String> = self.options.iter().cloned().collect();
        let (questions, extras) = question_pages(&manifest);
        let mut cards = Vec::new();
        if changeable_later(&manifest, &questions) {
            cards.push(
                div()
                    .type_caption()
                    .text_color(cx.theme().text_secondary)
                    .child(a11y_text("iso-option-change-later", t!("options-change-later")))
                    .into_any_element(),
            );
        }
        for page_index in questions {
            let page = &manifest.choices[page_index];
            let question = ScreenKind::of_choice(page).question();
            let chosen = options.clone();
            let kind = page.kind;
            let choose = self.choose(page_index, cx);
            let body = option_page_body(
                cx,
                "iso-option",
                page_index,
                page,
                question.clone(),
                describe::question_description(page),
                move |name| chosen.contains(name),
                false,
                &mut self.focus,
                |option| option_note(kind, option),
                choose,
                None,
            );
            let title = card_title(cx, &format!("iso-option-page-{page_index}"), question, 3);
            cards.push(card(cx).child(card_body().child(title).child(body)).into_any_element());
        }
        if !extras.is_empty() {
            cards.push(self.extras_card(&manifest, &extras, &options, cx));
        }
        cards
    }

    /// The optional extras as one card: its title and how many are ticked,
    /// with Show to unfold them, each page under a heading of its own.
    fn extras_card(
        &mut self,
        manifest: &Manifest,
        pages: &[usize],
        options: &BTreeSet<String>,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let theme = cx.theme().clone();
        let shown = self.extras_shown;
        let title = ScreenKind::Extras.title();
        let ticked = extras_ticked(manifest, pages, options);
        let status =
            if ticked == 0 { t!("options-extras-none") } else { t!("options-extras-ticked", count = ticked) };
        let label = if shown { t!("options-extras-hide") } else { t!("options-extras-show") };
        let toggle = Button::new("iso-extras-toggle", label.clone())
            .aria_label(t!("common-details-a11y", action = label, section = title.as_str()))
            .expanded(shown)
            .hyperlink()
            .compact()
            .trailing_icon(if shown { Icon::ChevronUp } else { Icon::ChevronDown })
            .on_click(cx.listener(|this, _, _, cx| {
                this.extras_shown = !this.extras_shown;
                cx.notify();
            }));
        // The title and the line under it read as one block, with no gap.
        let mut extras = card(cx).child(
            card_body().gap_0().child(card_title(cx, "iso-extras", title, 3)).child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(6.))
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(detail_text("iso-extras-status", status))
                    .child(div().child("·"))
                    // The link's own padding stands in for the gap after the dot.
                    .child(div().ml(-crate::ui::COMPACT_INSET).child(toggle)),
            ),
        );
        if shown {
            for &page_index in pages {
                let page = &manifest.choices[page_index];
                if page.depends_on.as_ref().is_some_and(|parent| !options.contains(parent)) {
                    continue;
                }
                let page_title = ScreenKind::of_choice(page).title();
                let chosen = options.clone();
                let kind = page.kind;
                let choose = self.choose(page_index, cx);
                let body = option_page_body(
                    cx,
                    "iso-option",
                    page_index,
                    page,
                    page_title.clone(),
                    describe::question_description(page),
                    move |name| chosen.contains(name),
                    false,
                    &mut self.focus,
                    |option| option_note(kind, option),
                    choose,
                    None,
                );
                // Each page of extras is a row of the card's list, under a divider.
                extras = extras.child(
                    card_body()
                        .border_t_1()
                        .border_color(theme.divider)
                        .child(card_title(cx, &format!("iso-option-page-{page_index}"), page_title, 4))
                        .child(body),
                );
            }
        }
        extras.into_any_element()
    }

    /// Takes an answer on page `page_index`: one answer for a question, a
    /// tick toggled for an extra, then the pages that follow from it.
    fn choose(&self, page_index: usize, cx: &mut Context<Self>) -> OptionChoice {
        let entity = cx.entity();
        Rc::new(move |name: &str, cx: &mut App| {
            let name = name.to_owned();
            entity.update(cx, |this, cx| {
                let Some(page) = this.manifest.as_ref().and_then(|m| m.choices.get(page_index)).cloned()
                else {
                    return;
                };
                let names: Vec<String> = page.options.iter().map(|option| option.id.clone()).collect();
                if page.kind == ChoiceKind::Single {
                    this.options.retain(|option| !names.contains(option));
                    this.options.push(name);
                } else if this.options.contains(&name) {
                    this.options.retain(|option| option != &name);
                } else {
                    this.options.push(name);
                }
                this.clean_options();
                cx.notify();
            })
        })
    }

    /// Drops the answers of pages that no longer show and gives every
    /// question that has none its default.
    pub(super) fn clean_options(&mut self) {
        if let Some(manifest) = &self.manifest {
            for page in &manifest.choices {
                if page.depends_on.as_ref().is_some_and(|n| !self.options.contains(n)) {
                    self.options.retain(|n| !page.options.iter().any(|o| &o.id == n));
                } else if page.kind == ChoiceKind::Single
                    && !page.options.iter().any(|o| self.options.contains(&o.id))
                    && let Some(default) = page.options.iter().find(|o| o.default)
                {
                    self.options.push(default.id.clone());
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_questions_come_first_and_the_extras_follow_their_parents() {
        let manifest = Manifest::builtin();
        let (questions, extras) = question_pages(&manifest);
        let kinds = |pages: &[usize]| -> Vec<ScreenKind> {
            pages.iter().map(|&index| ScreenKind::of_choice(&manifest.choices[index])).collect()
        };
        assert!(kinds(&questions).contains(&ScreenKind::Defender));
        assert!(!kinds(&questions).contains(&ScreenKind::Browser), "the browser picker is an extra");
        // As in the install flow, the browser picker comes straight after the
        // apps that offer it.
        let extras = kinds(&extras);
        let apps = extras.iter().position(|kind| *kind == ScreenKind::Apps).unwrap();
        assert_eq!(extras[apps + 1], ScreenKind::Browser);
    }

    #[test]
    fn only_ticked_extras_on_pages_that_show_are_counted() {
        let manifest = Manifest::builtin();
        let (_, extras) = question_pages(&manifest);
        let options = |names: &[&str]| names.iter().map(|name| name.to_string()).collect::<BTreeSet<_>>();
        assert_eq!(extras_ticked(&manifest, &extras, &options(&[])), 0);
        // A browser answer without the box that asks for one doesn't count.
        assert_eq!(extras_ticked(&manifest, &extras, &options(&["browser-brave"])), 0);
        assert_eq!(
            extras_ticked(&manifest, &extras, &options(&["install-another-browser", "browser-brave"])),
            2
        );
    }

    #[test]
    fn only_answers_other_than_the_recommended_one_say_what_they_cost() {
        crate::i18n::testing::english(|| {
            let manifest = Manifest::builtin();
            let defender = manifest.choices.iter().find(|choice| choice.id == "defender").unwrap();
            for option in &defender.options {
                let note = option_note(defender.kind, option);
                assert_eq!(note.consequence.is_some(), !option.default, "{}", option.id);
            }
        });
    }
}
