//! Step 2, Your choices: every question the Atlas package asks on one
//! screen, a card each, with the optional extras under them.
//! Updating or reinstalling an installed Atlas first asks, on a screen of
//! its own, whether to keep the choices this PC has or to choose again.

use std::collections::{BTreeSet, HashMap};
use std::rc::Rc;

use gpui::{AnyElement, App, Context, FocusHandle, IntoElement, ParentElement, Styled, div, px};

use super::summary::{choice_value, chosen_on};
use super::{InstallPage, ready::status_line};
use crate::i18n::describe;
use crate::model::{AppModel, ChoiceGroup, FixedChoice, OptionScreen, ScreenKind, UpdatePath};
use crate::pages::{
    ListEntry, OptionChoice, OptionNote, card_body, card_title, detail_row, option_page_body,
};
use crate::services::package::{ChoiceKind, Manifest};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{Button, Icon, InfoBar, RadioGroup, RadioItem, Severity, Typography, a11y_text, card};

/// The focus key of the extras' Show and Hide link.
const EXTRAS_TOGGLE: &str = "extras-toggle";

impl InstallPage {
    pub(super) fn options_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let screen = {
            let state = self.model.read(cx);
            state.option_screens().get(state.current_option_screen()).cloned()
        };
        match screen {
            Some(OptionScreen::UpdatePath) => self.update_path_cards(cx),
            Some(OptionScreen::Choices(groups)) => self.choices_cards(&groups, cx),
            None => Vec::new(),
        }
    }

    /// The questions, one card each with the question as its title and the
    /// cost under any answer other than the recommended one, then the
    /// optional extras in one card. Above them, a bar where the
    /// choices can't change, or a line on what this flow keeps, and a line
    /// saying which choices the Atlas folder can change later, while one of
    /// those is asked.
    fn choices_cards(&mut self, groups: &[ChoiceGroup], cx: &mut Context<Self>) -> Vec<AnyElement> {
        let (manifest, options, may_edit, package_dir, notes) = {
            let state = self.model.read(cx);
            let pages: Vec<usize> = groups.iter().flat_map(|group| group.pages.iter().copied()).collect();
            (
                state.manifest().clone(),
                state.effective_options().into_iter().collect::<BTreeSet<_>>(),
                !state.locked() && state.locked_options().is_none(),
                state.package.as_ref().map(|package| package.dir.clone()),
                option_notes(state, &pages),
            )
        };
        let theme = cx.theme().clone();
        let note = choices_note(self.model.read(cx));
        let mut cards: Vec<AnyElement> = note.as_ref().and_then(ChoicesNote::bar).into_iter().collect();
        // Plain lines, read in order: what this flow keeps, then, as a
        // secondary note, what can change later.
        let keeps = note.as_ref().and_then(ChoicesNote::line).map(|line| {
            div().type_body().text_color(theme.text_secondary).child(a11y_text("options-note", line))
        });
        let later = changeable_later(groups).then(|| {
            div()
                .type_caption()
                .text_color(theme.text_secondary)
                .child(a11y_text("option-change-later", t!("options-change-later")))
        });
        if keeps.is_some() || later.is_some() {
            cards
                .push(div().flex().flex_col().gap(px(4.)).children(keeps).children(later).into_any_element());
        }
        let model = self.model.clone();
        let choose = |page_index: usize| -> OptionChoice {
            let model = model.clone();
            Rc::new(move |name: &str, cx: &mut App| {
                let name = name.to_owned();
                model.update(cx, |m, cx| m.choose_option(page_index, &name, cx))
            })
        };
        for group in groups {
            if !group.required {
                cards.push(self.extras_card(group, &manifest, &options, may_edit, &notes, &choose, cx));
                continue;
            }
            for &page_index in &group.pages {
                let page = &manifest.choices[page_index];
                let question = group.kind.question();
                let chosen = options.clone();
                let body = option_page_body(
                    cx,
                    "option",
                    page_index,
                    page,
                    question.clone(),
                    describe::question_description(page),
                    move |name| chosen.contains(name),
                    !may_edit,
                    &mut self.focus,
                    |option| notes.get(&option.id).cloned().unwrap_or_default(),
                    choose(page_index),
                    package_dir.as_deref(),
                );
                let title = card_title(cx, &format!("option-page-{page_index}"), question, 3);
                cards.push(card(cx).child(card_body().child(title).child(body)).into_any_element());
            }
        }
        cards
    }

    /// The optional extras as one card: its title and how many are ticked,
    /// with Hide to fold them and Show to unfold them again, each page of
    /// them under a heading of its own. A page that depends on an option
    /// shows once that's ticked.
    #[allow(clippy::too_many_arguments)]
    fn extras_card(
        &mut self,
        group: &ChoiceGroup,
        manifest: &Manifest,
        options: &BTreeSet<String>,
        may_edit: bool,
        notes: &HashMap<String, OptionNote>,
        choose: &dyn Fn(usize) -> OptionChoice,
        cx: &mut Context<Self>,
    ) -> AnyElement {
        let shown = self.model.read(cx).extras_shown;
        let title = group.kind.title();
        let ticked = extras_ticked(manifest, &group.pages, options);
        let status =
            if ticked == 0 { t!("options-extras-none") } else { t!("options-extras-ticked", count = ticked) };
        let label = if shown { t!("options-extras-hide") } else { t!("options-extras-show") };
        let model = self.model.clone();
        let toggle = Button::new("extras-toggle", label.clone())
            .aria_label(t!("common-details-a11y", action = label, section = title.as_str()))
            .expanded(shown)
            .hyperlink()
            .compact()
            .trailing_icon(if shown { Icon::ChevronUp } else { Icon::ChevronDown })
            .focus_handle(self.focus.get(EXTRAS_TOGGLE, cx))
            .on_click(move |_, _, cx| model.update(cx, |m, cx| m.show_extras(!shown, cx)));
        // The title and the line under it read as one block, with no gap.
        let mut card =
            card(cx).child(
                card_body()
                    .gap_0()
                    .child(card_title(cx, "option-extras", title.clone(), 3))
                    .child(status_line("option-extras", status, Some(toggle), cx)),
            );
        if shown {
            for &page_index in &group.pages {
                let page = &manifest.choices[page_index];
                if page.depends_on.as_ref().is_some_and(|dependency| !options.contains(dependency)) {
                    continue;
                }
                let kind = ScreenKind::of_choice(page);
                let page_title = kind.title();
                let chosen = options.clone();
                let package_dir = self.model.read(cx).package.as_ref().map(|package| package.dir.clone());
                let body = option_page_body(
                    cx,
                    "option",
                    page_index,
                    page,
                    page_title.clone(),
                    describe::question_description(page),
                    move |name| chosen.contains(name),
                    !may_edit,
                    &mut self.focus,
                    |option| notes.get(&option.id).cloned().unwrap_or_default(),
                    choose(page_index),
                    package_dir.as_deref(),
                );
                // Each page of extras is a section of the card, set apart by
                // its title and the space around it rather than a divider.
                card = card.child(
                    card_body()
                        .child(card_title(cx, &format!("option-page-{page_index}"), page_title, 4))
                        .child(body),
                );
            }
        }
        card.into_any_element()
    }

    /// Where focus goes when a Change link on the Install step opens Your
    /// choices at what its row lists: the answer chosen for its question, or
    /// the extras' Show and Hide link. Each is read with its question or
    /// title. How Atlas updates leads to the first screen, which the
    /// stepper names.
    pub(super) fn change_focus(&mut self, kind: ScreenKind, cx: &mut App) -> Option<FocusHandle> {
        match kind {
            ScreenKind::UpdatePath => None,
            ScreenKind::Extras => Some(self.focus.get(EXTRAS_TOGGLE, cx)),
            kind => {
                let key = {
                    let state = self.model.read(cx);
                    let screens = state.option_screens();
                    let group = screens.iter().flat_map(|screen| screen.groups()).find(|g| g.kind == kind)?;
                    let page_index = *group.pages.first()?;
                    let page = state.manifest().choices.get(page_index)?;
                    let options = state.effective_options();
                    let option = page
                        .options
                        .iter()
                        .find(|option| options.contains(&option.id))
                        .or_else(|| page.options.first())?;
                    format!("option-{page_index}-{}", option.id)
                };
                Some(self.focus.get(&key, cx))
            }
        }
    }

    /// The first screen of an update or reinstall: keep the choices this PC
    /// has, or choose again, above what the PC has now, choice by choice, as
    /// the summary lists them. Choosing again starts every question from
    /// that list too. The answer can be changed while the choices it keeps
    /// can't.
    fn update_path_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let focus = [self.focus.get("update-path-keep", cx), self.focus.get("update-path-choose", cx)];
        let model = self.model.clone();
        let state = self.model.read(cx);
        let (Some(update), Some(question)) = (state.update_choices(), update_path_question(state)) else {
            return Vec::new();
        };
        let theme = cx.theme();
        let [keep, choose] = focus;
        let paths = [UpdatePath::Keep, UpdatePath::ChooseAgain];
        let group = RadioGroup::new("update-path", question.clone())
            .items([
                RadioItem::new("update-path-keep", t!("update-path-keep"), keep)
                    .description(t!("update-path-keep-detail")),
                RadioItem::new("update-path-choose", t!("update-path-choose"), choose)
                    .description(t!("update-path-choose-detail")),
            ])
            .selected(paths.iter().position(|path| *path == state.update_path))
            .disabled(state.locked())
            .on_select(move |index, _, cx| {
                if let Some(&path) = paths.get(index) {
                    model.update(cx, |m, cx| m.set_update_path(path, cx));
                }
            });

        let mut now = card_body().child(card_title(cx, "update-path-now", t!("update-path-now-title"), 3));
        if let Some(line) = differs_line(&update.differs) {
            now = now.child(
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .pb(px(4.))
                    .child(a11y_text("update-path-differs", line)),
            );
        }
        for (index, row) in now_rows(state, &update.kept).into_iter().enumerate() {
            // A record of the PC, as Home's is: no caution from when the choice was made.
            let chosen = row
                .chosen
                .iter()
                .filter_map(|name| {
                    Some(ListEntry::new(describe::option_answer(name, state.option_text(name)?)))
                })
                .collect();
            let title = row.kind.title();
            let key = format!("now-{index}");
            let unknown = t!("update-path-unknown");
            let value = choice_value(cx, &key, ("now-choices", index), &title, row.required, chosen, unknown);
            now = now.child(detail_row(cx, &key, title, value));
        }
        // No question here can change later from the Atlas folder, so that
        // line waits for the questions.
        vec![
            card(cx)
                .child(card_body().child(card_title(cx, "update-path", question, 3)).child(group))
                .into_any_element(),
            card(cx).child(now).into_any_element(),
        ]
    }
}

/// How many of the extras' check boxes on `pages` are ticked among
/// `options`. A browser picked under Install a browser is part of that box.
fn extras_ticked(manifest: &Manifest, pages: &[usize], options: &BTreeSet<String>) -> usize {
    pages
        .iter()
        .filter_map(|&page| manifest.choices.get(page))
        .filter(|page| page.kind == ChoiceKind::Multiple)
        .flat_map(|page| page.options.iter())
        .filter(|option| options.contains(&option.id))
        .count()
}

/// A row of the first screen's list of what this PC has: a choice, as the
/// summary lists it, and the options the PC has for it, by name. A required
/// choice with none is one Atlas can't tell from the PC, which keeping the
/// choices then asks.
#[derive(Clone, Debug, PartialEq, Eq)]
struct NowRow {
    kind: ScreenKind,
    required: bool,
    chosen: Vec<String>,
}

/// The first screen's list, one row per choice in the summary's order, from
/// `kept`, the choices this PC has.
fn now_rows(state: &AppModel, kept: &[String]) -> Vec<NowRow> {
    let manifest = state.manifest();
    state
        .choice_groups()
        .into_iter()
        .map(|group| NowRow {
            kind: group.kind,
            required: group.required,
            chosen: chosen_on(manifest, &group.pages, kept, |option| option.id.clone()),
        })
        .collect()
}

/// The line above that list when Atlas's record of the last installation
/// doesn't match this PC, naming each choice of the kinds `differs` as it's
/// named mid-sentence.
fn differs_line(differs: &[ScreenKind]) -> Option<String> {
    let choices: Vec<String> = differs.iter().map(|kind| kind.name()).collect();
    (!choices.is_empty()).then(|| t!("update-path-differs", choices = describe::join_and(&choices)))
}

/// Whether the screen asks a question the Atlas folder can change later:
/// Microsoft Defender, processor protections or updates.
fn changeable_later(groups: &[ChoiceGroup]) -> bool {
    groups.iter().any(|group| {
        group.required
            && matches!(group.kind, ScreenKind::Defender | ScreenKind::Mitigations | ScreenKind::Updates)
    })
}

/// What the current step reads after its name on Your choices: what the
/// screen asks. On the first screen of an update or reinstall, its question;
/// on the screen of questions, each question in turn, then the optional
/// extras, so moving between the two is announced as a new screen.
pub(super) fn choice_heading_name(state: &AppModel) -> Option<String> {
    let screens = state.option_screens();
    match screens.get(state.current_option_screen())? {
        OptionScreen::UpdatePath => update_path_question(state),
        OptionScreen::Choices(groups) => {
            let asks: Vec<String> = groups
                .iter()
                .map(|group| if group.required { group.kind.question() } else { group.kind.title() })
                .collect();
            Some(asks.join(" "))
        }
    }
}

/// The question the first screen of an update or reinstall asks, if this
/// flow has one: updating to the package's version, or installing again the
/// version this PC has.
fn update_path_question(state: &AppModel) -> Option<String> {
    let update = state.update_choices()?;
    let version = state.manifest().version.as_str();
    Some(if update.reinstall {
        t!("update-path-reinstall-title", version = version)
    } else {
        t!("update-path-update-title", version = version)
    })
}

/// Which bar the screen of questions shows above them, if any.
#[derive(Clone, Debug, PartialEq, Eq)]
enum ChoicesNote {
    /// An unfinished install keeps the options it began with.
    Resume,
    /// Windows rebuilt itself: Atlas puts back the choices the record of the
    /// move kept from Atlas `previous`, and `complete`, there are none left
    /// to ask.
    Rebase { previous: String, complete: bool },
    /// Keeping the choices of the installed Atlas asks only what this PC
    /// can't show.
    Keep,
    /// Choosing again starts each question from how this PC is set up.
    ChooseAgain,
}

/// The note above the questions: an unfinished install's, a rebuilt
/// Windows's, or how an update or reinstall treats them. An unfinished
/// update that will keep them, with nothing held yet, says so as keeping
/// them does while it asks a question, and otherwise as an unfinished
/// install. A first install has none.
fn choices_note(state: &AppModel) -> Option<ChoicesNote> {
    if state.original_options().is_some() {
        return Some(ChoicesNote::Resume);
    }
    if let Some(choices) = state.rebase_choices() {
        return Some(ChoicesNote::Rebase { complete: choices.complete(), previous: choices.previous });
    }
    if let Some(choices) = state.unfinished_choices() {
        return Some(if choices.complete() { ChoicesNote::Resume } else { ChoicesNote::Keep });
    }
    state.update_choices()?;
    Some(match state.update_path {
        UpdatePath::ChooseAgain => ChoicesNote::ChooseAgain,
        UpdatePath::Keep => ChoicesNote::Keep,
    })
}

impl ChoicesNote {
    /// The bar's title, then its message, where the choices showing can't
    /// change and the bar says why: an unfinished install's, or a rebuilt
    /// Windows's when nothing is left to ask.
    fn words(&self) -> Option<(String, String)> {
        match self {
            ChoicesNote::Resume => Some((t!("resume-choices-title"), t!("resume-choices-held"))),
            ChoicesNote::Rebase { previous, complete: true } => Some((
                t!("rebase-choices-title", previous = previous.as_str()),
                t!("rebase-choices-kept", previous = previous.as_str()),
            )),
            _ => None,
        }
    }

    /// The bar [`ChoicesNote::words`] gives, if any.
    fn bar(&self) -> Option<AnyElement> {
        let (title, message) = self.words()?;
        let bar = InfoBar::new(Severity::Informational, title, message);
        let id = match self {
            ChoicesNote::Resume => "options-resume-note",
            _ => "options-rebase-note",
        };
        Some(bar.id(id).into_any_element())
    }

    /// The plain line above questions a partial record leaves to ask: the
    /// rest stay as they are, which the questions alone don't say. It
    /// doesn't name them again. Choosing again needs none: each answer says
    /// what it changes.
    fn line(&self) -> Option<String> {
        match self {
            ChoicesNote::Rebase { previous, complete: false } => {
                Some(t!("rebase-choices-asked", previous = previous.as_str()))
            }
            ChoicesNote::Keep => Some(t!("keep-choices-asked")),
            _ => None,
        }
    }
}

/// What each option on the pages `pages` says under it, by name: what an
/// answer other than the package's default costs, and what each check box
/// does, removing Edge that it deletes its data on this PC. A recommended
/// answer says nothing. Choosing again on an update or reinstall, an option
/// also says what it changes on this PC instead, whether the PC has it, and
/// why an update can't change it; a browser chosen beside one an update
/// keeps installed says both stay.
fn option_notes(state: &AppModel, pages: &[usize]) -> HashMap<String, OptionNote> {
    let manifest = state.manifest();
    let options = state.effective_options();
    let chosen = |name: &str| options.iter().any(|option| option == name);
    let choosing_again = state.update_choices().filter(|_| state.update_path == UpdatePath::ChooseAgain);
    let facts = state.choice_facts();
    // In sentences about what this PC has, so without "(recommended)".
    let label = |id: &str| describe::option_answer(id, state.option_text(id).unwrap_or(id));
    let kept_browser = match state.fixed_option("install-another-browser") {
        Some(FixedChoice::Installed(browser)) if choosing_again.is_some() => Some(browser),
        _ => None,
    };
    let mut notes = HashMap::new();
    for page in pages.iter().filter_map(|&index| manifest.choices.get(index)) {
        for option in &page.options {
            let name = option.id.as_str();
            let recommended =
                page.kind == ChoiceKind::Single && option.default && !describe::cost_shown_as_default(name);
            let line = if recommended { None } else { describe::option_line(name, state.before_desktop) };
            let mut note = OptionNote::from(line);
            if let Some(update) = &choosing_again {
                let answered = page.kind == ChoiceKind::Single || chosen(name);
                note.change = describe::change_line(name, answered, &facts);
                note.now = update.kept.iter().any(|kept| kept == name);
                note.fixed = state.fixed_option(name).and_then(|fixed| describe::fixed_reason(&fixed, label));
                if let Some(installed) = kept_browser.as_deref()
                    && name.starts_with("browser-")
                    && name != installed
                    && chosen(name)
                {
                    note.change =
                        Some(t!("browser-also", installed = label(installed), browser = label(name)));
                }
            }
            notes.insert(option.id.clone(), note);
        }
    }
    notes
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::test_harness::run_model_test;
    use crate::pages::testing::{NO_DEFENDER, NO_TELEMETRY, installed_model, rebuilt, records};
    use crate::services::atlas_state::{InstallIdentity, InstallMode, Unfinished};
    use crate::services::legacy_choices::Facts;
    use crate::services::test_support::TempDir;

    /// A PC whose record kept Microsoft Defender while Atlas's NoDefender
    /// package removes it, with every processor protection on, updates and
    /// hibernation off, Edge removed and a Toolbox and Brave installed.
    fn removed_pc() -> Facts {
        Facts {
            packages: vec![NO_DEFENDER.into(), NO_TELEMETRY.into()],
            toggles: records(&[("Mitigations", 2), ("AutomaticUpdates", 0), ("Hibernation", 0)]),
            edge: Some(false),
            appx: vec![
                "Microsoft.ScreenSketch_8wekyb3d8bbwe".into(),
                "Microsoft.WindowsCalculator_8wekyb3d8bbwe".into(),
            ],
            toolbox: Some(true),
            toolbox_program: Some(true),
            browser: Some("Brave".into()),
            browsers: Some(vec!["browser-brave".into()]),
            defender: Some(false),
            ..Facts::default()
        }
    }

    fn page_of(m: &AppModel, option: &str) -> usize {
        m.manifest().choices.iter().position(|page| page.options.iter().any(|o| o.id == option)).unwrap()
    }

    fn line(id: &str) -> Option<String> {
        Some(crate::i18n::text(id, &[]))
    }

    /// Choosing again on a PC its record contradicts, each answer that
    /// changes the PC says so, the PC's own answers are tagged, what an
    /// update can't undo is fixed with why, and a browser picked beside the
    /// one installed says both stay. Keeping the choices, or a first install,
    /// says only what an answer other than the recommended one costs and
    /// what each check box does.
    #[test]
    fn choosing_again_says_what_each_answer_changes_on_this_pc() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("option-notes");
            let record =
                ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-shortcuts"];
            let model = installed_model(&mut cx, &temp, Some(&record), removed_pc());
            let all = |m: &AppModel| (0..m.manifest().choices.len()).collect::<Vec<_>>();
            model.update(&mut cx, |m, cx| {
                m.update_path = UpdatePath::ChooseAgain;
                m.set_update_path(UpdatePath::Keep, cx);
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                let notes = option_notes(m, &all(m));
                let note = |name: &str| notes[name].clone();
                assert_eq!(note("defender-enable").change, line("change-defender-enable"));
                assert!(!note("defender-enable").now);
                let removed = note("defender-disable");
                assert!(removed.now && removed.change.is_none());
                assert_eq!(removed.consequence, line("cost-defender-disable"), "still says what it costs");
                let protections = note("mitigations-default");
                assert!(protections.now);
                assert_eq!(protections.change, line("change-mitigations-all-on"));
                assert_eq!(note("auto-updates-default").change, line("change-auto-updates-default"));
                assert!(note("auto-updates-disable").now && note("auto-updates-disable").change.is_none());
                assert_eq!(note("uninstall-edge").fixed, line("fixed-uninstall-edge"));
                assert_eq!(note("install-toolbox").fixed, Some(t!("fixed-installed", app = "Atlas Toolbox")));
                assert_eq!(note("install-another-browser").fixed, Some(t!("fixed-installed", app = "Brave")));
                assert!(note("browser-brave").now && note("browser-brave").change.is_none());
                // Ticked as the PC has them: nothing changes until cleared.
                assert!(note("disable-hibernation").now && note("disable-hibernation").change.is_none());
                assert!(note("remove-snipping-tool").change.is_none() && !note("remove-snipping-tool").now);
                assert!(note("install-eclean").fixed.is_none() && note("install-eclean").change.is_none());

                m.choose_option(page_of(m, "disable-hibernation"), "disable-hibernation", cx);
                m.choose_option(page_of(m, "remove-snipping-tool"), "remove-snipping-tool", cx);
                m.choose_option(page_of(m, "browser-firefox"), "browser-firefox", cx);
                let notes = option_notes(m, &all(m));
                assert_eq!(notes["disable-hibernation"].change, line("change-hibernation-on"));
                assert_eq!(notes["remove-snipping-tool"].change, line("change-remove-snipping-tool"));
                assert_eq!(
                    notes["browser-firefox"].change,
                    Some(t!("browser-also", installed = "Brave", browser = "Firefox"))
                );
                assert!(notes["browser-brave"].change.is_none(), "only the browser chosen says it");

                // Keeping them, or a first install, only says what an answer
                // costs, under the answers that aren't recommended.
                m.set_update_path(UpdatePath::Keep, cx);
                for notes in [option_notes(m, &all(m)), {
                    m.install_identity = Ok(InstallIdentity::Fresh);
                    option_notes(m, &all(m))
                }] {
                    for (name, note) in &notes {
                        assert!(
                            !note.now && note.change.is_none() && note.fixed.is_none(),
                            "{name}: {note:?}"
                        );
                    }
                    assert_eq!(notes["defender-disable"].consequence, line("cost-defender-disable"));
                    for recommended in ["defender-enable", "mitigations-default", "keyboard-shortcuts"] {
                        assert_eq!(notes[recommended].consequence, None, "{recommended}");
                    }
                    assert_eq!(notes["disable-hibernation"].consequence, line("extra-disable-hibernation"));
                }
            });
        });
    }

    /// On a PC before 0.6, a Mitigations record without a launcher's name
    /// beside it is the old Toolbox's, which never changed the PC, so keeping
    /// processor protections says only what it means. The record Atlas 0.5's
    /// launcher left says every protection is on.
    #[test]
    fn choosing_again_reads_an_old_toolbox_s_record_for_what_it_means() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("option-notes-before-0-6");
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("Mitigations", 2)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, None, pc);
            model.update(&mut cx, |m, cx| {
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                let pages = [page_of(m, "mitigations-default")];
                assert_eq!(option_notes(m, &pages)["mitigations-default"].change, None);
                m.pc_facts.launchers =
                    [("Mitigations".to_owned(), "Enable All Mitigations.cmd".to_owned())].into();
                assert_eq!(
                    option_notes(m, &pages)["mitigations-default"].change,
                    line("change-mitigations-all-on")
                );
            });
        });
    }

    /// The first screen offers both answers, keeping them selected, and
    /// lists what this PC has: where Atlas's record says otherwise, then each
    /// choice as the PC has it, a required one it can't show as one Atlas
    /// asks. Its question names the version this flow installs, as an update
    /// or as a reinstall.
    #[test]
    fn the_first_screen_asks_how_to_update_or_reinstall() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("update-path-question");
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), removed_pc());
            model.update(&mut cx, |m, _| {
                assert_eq!(m.update_path, UpdatePath::Keep);
                let update = m.update_choices().unwrap();
                assert_eq!(update.missing, [ScreenKind::Keyboard], "nothing shows the keyboard choice");
                let rows = now_rows(m, &update.kept);
                let kinds: Vec<ScreenKind> = rows.iter().map(|row| row.kind).collect();
                let groups: Vec<ScreenKind> = m.choice_groups().iter().map(|group| group.kind).collect();
                assert_eq!(kinds, groups, "the summary's rows");
                let unknown: Vec<ScreenKind> = rows
                    .iter()
                    .filter(|row| row.required && row.chosen.is_empty())
                    .map(|row| row.kind)
                    .collect();
                assert_eq!(unknown, update.missing, "read as update-path-unknown");
                assert_eq!(rows[0].chosen, ["defender-disable"], "the PC's answer, not the record's");
                let extras = rows.last().unwrap();
                assert!(
                    !extras.required && extras.chosen.iter().any(|o| o == "uninstall-edge"),
                    "{extras:?}"
                );

                assert_eq!(update.differs.first(), Some(&ScreenKind::Defender));
                let names: Vec<String> = update.differs.iter().map(|kind| kind.name()).collect();
                assert_eq!(
                    differs_line(&update.differs),
                    Some(t!("update-path-differs", choices = describe::join_and(&names)))
                );
                assert_eq!(differs_line(&[]), None, "a record that matches says nothing");

                let version = m.manifest().version.clone();
                assert_eq!(
                    update_path_question(m),
                    Some(t!("update-path-reinstall-title", version = &version))
                );
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                assert_eq!(update_path_question(m), Some(t!("update-path-update-title", version = &version)));
                m.install_identity = Ok(InstallIdentity::Fresh);
                assert_eq!(update_path_question(m), None, "a first install has no first screen");
            });
        });
    }

    /// The questions' screen says how its choices are treated: keeping them
    /// asks only what this PC can't show, choosing again starts each from
    /// the PC. An unfinished install and a rebuilt Windows have bars of
    /// their own, and a first install has none.
    #[test]
    fn the_bar_above_the_questions_says_how_the_choices_are_treated() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("choices-note");
            // No record of processor protections, so keeping the choices asks it.
            let pc = Facts {
                packages: vec![NO_TELEMETRY.into()],
                toggles: records(&[("AutomaticUpdates", 0), ("KeyboardShortcuts", 1)]),
                ..Facts::default()
            };
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), pc);
            model.update(&mut cx, |m, cx| {
                assert_eq!(choices_note(m), Some(ChoicesNote::Keep));
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                assert_eq!(choices_note(m), Some(ChoicesNote::ChooseAgain));
                let unfinished = Unfinished {
                    held: Some(vec!["defender-enable".into()]),
                    choose_again: true,
                    mode: InstallMode::Reapply,
                };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unfinished));
                assert_eq!(choices_note(m), Some(ChoicesNote::Resume));
                // One that will keep them, with nothing held yet, asks as keeping them does.
                let unheld = Unfinished { held: None, choose_again: false, mode: InstallMode::Reapply };
                m.install_identity = Ok(InstallIdentity::Resume("0.6.0".into(), unheld));
                assert_eq!(choices_note(m), Some(ChoicesNote::Keep));
                m.pc_facts.toggles.insert("Mitigations".into(), 1);
                assert_eq!(choices_note(m), Some(ChoicesNote::Resume), "nothing to ask");
                m.pc_facts.toggles.remove("Mitigations");
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                m.atlas = Ok(None);
                m.update_access =
                    Some(rebuilt(&["defender-disable", "auto-updates-disable", "keyboard-shortcuts"]));
                assert_eq!(
                    choices_note(m),
                    Some(ChoicesNote::Rebase { previous: "0.5.0".into(), complete: false })
                );
                m.install_identity = Ok(InstallIdentity::Fresh);
                m.update_access = None;
                assert_eq!(choices_note(m), None, "a first install has none");
            });
        });
        // A bar only where the choices can't change, and says why; a line
        // where some stay as they are; nothing when each answer says it.
        crate::i18n::testing::english(|| {
            assert_eq!(ChoicesNote::Keep.words(), None);
            assert_eq!(ChoicesNote::Keep.line(), Some(t!("keep-choices-asked")));
            assert_eq!(ChoicesNote::ChooseAgain.words(), None);
            assert_eq!(ChoicesNote::ChooseAgain.line(), None);
            let complete = ChoicesNote::Rebase { previous: "0.5.0".into(), complete: true };
            assert_eq!(complete.words().unwrap().1, t!("rebase-choices-kept", previous = "0.5.0"));
            assert_eq!(complete.line(), None);
            let partial = ChoicesNote::Rebase { previous: "0.5.0".into(), complete: false };
            assert_eq!(partial.words(), None);
            assert_eq!(partial.line(), Some(t!("rebase-choices-asked", previous = "0.5.0")));
            assert!(ChoicesNote::Resume.words().is_some() && ChoicesNote::Resume.line().is_none());
        });
    }

    /// The current step reads, after its name, what the screen asks: the
    /// first screen its question, the screen of questions each of them and
    /// the optional extras.
    #[test]
    fn the_step_name_says_what_the_screen_asks() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("choice-heading");
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), removed_pc());
            model.update(&mut cx, |m, cx| {
                let question = t!("update-path-reinstall-title", version = &m.manifest().version);
                assert_eq!(choice_heading_name(m), Some(question));
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                m.option_screen = 1;
                let asks = [
                    ScreenKind::Defender.question(),
                    ScreenKind::Mitigations.question(),
                    ScreenKind::Updates.question(),
                    ScreenKind::Keyboard.question(),
                    ScreenKind::Extras.title(),
                ];
                assert_eq!(choice_heading_name(m), Some(asks.join(" ")));
            });
        });
    }

    /// The line about Atlas's record names the choices as a sentence does,
    /// one or several, and the line about changing them later shows only
    /// beside a question the Atlas folder changes.
    #[test]
    fn the_screen_s_lines_read_as_sentences_and_show_where_they_apply() {
        crate::i18n::testing::english(|| {
            assert_eq!(
                differs_line(&[ScreenKind::Mitigations]).as_deref(),
                Some("This PC doesn't match Atlas's record for processor protections.")
            );
            assert_eq!(
                differs_line(&[ScreenKind::Defender, ScreenKind::Mitigations, ScreenKind::Updates])
                    .as_deref(),
                Some(
                    "This PC doesn't match Atlas's record for Microsoft Defender, processor protections and Windows Update."
                )
            );
        });
        let group = |kind, required| ChoiceGroup { kind, pages: vec![0], required };
        assert!(changeable_later(&[group(ScreenKind::Mitigations, true), group(ScreenKind::Keyboard, true)]));
        assert!(!changeable_later(&[group(ScreenKind::Keyboard, true), group(ScreenKind::Extras, false)]));
        assert!(!changeable_later(&[]), "the first screen of an update");
    }

    /// The extras' card counts the boxes ticked, a browser picked under
    /// Install a browser not counted again.
    #[test]
    fn the_extras_count_their_ticked_boxes() {
        let manifest = Manifest::builtin();
        let pages: Vec<usize> = (0..manifest.choices.len()).collect();
        let options = |names: &[&str]| names.iter().map(|name| (*name).to_owned()).collect::<BTreeSet<_>>();
        assert_eq!(extras_ticked(&manifest, &pages, &options(&["defender-enable", "keyboard-single"])), 0);
        let ticked =
            options(&["defender-enable", "install-another-browser", "browser-brave", "remove-snipping-tool"]);
        assert_eq!(extras_ticked(&manifest, &pages, &ticked), 2);
    }
}
