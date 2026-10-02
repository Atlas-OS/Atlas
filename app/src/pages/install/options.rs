//! Step 2, Your choices: one screen of the Atlas package's choices at a time.

use std::rc::Rc;

use gpui::{AnyElement, Context, IntoElement, ParentElement, Styled, div, px};

use super::InstallPage;
use crate::i18n::describe;
use crate::model::ScreenKind;
use crate::pages::option_page_card;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{InfoBar, Severity, Typography, a11y_text};

impl InstallPage {
    pub(super) fn options_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme().clone();
        let (manifest, options, may_edit, screens, current, package_dir, before_desktop) = {
            let state = self.model.read(cx);
            (
                state.manifest().clone(),
                state.effective_options().into_iter().collect::<std::collections::BTreeSet<_>>(),
                state.flow.may_edit() && state.locked_options().is_none(),
                state.option_screens(),
                state.current_option_screen(),
                state.playbook.as_ref().map(|package| package.dir.clone()),
                state.before_desktop,
            )
        };
        let Some(screen) = screens.get(current) else { return Vec::new() };
        let model = self.model.clone();
        let mut cards = Vec::new();
        if self.model.read(cx).original_options().is_some() {
            cards.push(
                InfoBar::new(
                    Severity::Informational,
                    t!("resume-choices-title"),
                    t!("resume-choices-detail"),
                )
                .into_any_element(),
            );
        } else if let Some(choices) = self.model.read(cx).rebase_choices() {
            let detail = if choices.complete() {
                t!("rebase-choices-detail", previous = choices.previous.as_str())
            } else {
                let missing: Vec<String> = choices.missing.iter().map(|kind| kind.title()).collect();
                t!(
                    "rebase-choices-partial",
                    previous = choices.previous.as_str(),
                    missing = describe::join_and(&missing).as_str()
                )
            };
            cards.push(
                InfoBar::new(
                    Severity::Informational,
                    t!("rebase-choices-title", previous = choices.previous.as_str()),
                    detail,
                )
                .id("options-rebase-note")
                .into_any_element(),
            );
        } else if let Some((previous, _)) = self.model.read(cx).installed_choices() {
            // An update starts from what the installed Atlas chose; Upgrade
            // keeps what those choices did, ticked or not.
            cards.push(
                InfoBar::new(
                    Severity::Informational,
                    t!("upgrade-choices-title", previous = previous.as_str()),
                    t!("upgrade-choices-detail", previous = previous.as_str()),
                )
                .id("options-upgrade-note")
                .into_any_element(),
            );
        }

        // One decision at a time: the question is the heading, the choice
        // below it, with consequences visible before either answer is chosen.
        // Beside where the user is, which choices can be changed afterwards.
        cards.push(
            div()
                .flex()
                .flex_wrap()
                .items_start()
                .gap_x(px(16.))
                .gap_y(px(2.))
                .type_caption()
                .text_color(theme.text_secondary)
                .child(div().flex_shrink_0().child(a11y_text(
                    "option-progress",
                    if screen.required {
                        t!("options-progress", number = current + 1, total = screens.len())
                    } else {
                        t!("options-progress-extras", number = current + 1, total = screens.len())
                    },
                )))
                .child(
                    div()
                        .flex_1()
                        .min_w(px(240.))
                        .child(a11y_text("option-change-later", t!("options-change-later"))),
                )
                .into_any_element(),
        );

        for &page_index in &screen.pages {
            let page = &manifest.pages[page_index];
            if page.depends_on.as_ref().is_some_and(|dependency| !options.contains(dependency)) {
                continue;
            }
            let header =
                if screen.required { screen.kind.question() } else { ScreenKind::of_page(page).title() };
            let model = model.clone();
            let chosen = options.clone();
            cards.push(option_page_card(
                cx,
                "option",
                page_index,
                page,
                header,
                move |name| chosen.contains(name),
                !may_edit,
                &mut self.focus,
                // This PC has the user's data, so removing Edge says it deletes it.
                |option| describe::known_install_consequence(&option.name, &option.text, before_desktop),
                Rc::new(move |name: &str, cx: &mut gpui::App| {
                    let name = name.to_owned();
                    model.update(cx, |m, cx| m.choose_option(page_index, &name, cx))
                }),
                package_dir.as_deref(),
            ));
        }
        cards
    }
}
