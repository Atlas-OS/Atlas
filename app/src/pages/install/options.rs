//! Step 2, Your choices: one screen of the Atlas package's choices at a time.
//! Updating or reinstalling an installed Atlas first asks whether to keep the
//! choices this PC has or to choose again.

use std::collections::{BTreeSet, HashMap};
use std::rc::Rc;

use gpui::{AnyElement, Context, IntoElement, ParentElement, Styled, div, px};

use super::InstallPage;
use super::summary::{choice_value, chosen_on};
use crate::i18n::describe;
use crate::model::{AppModel, FixedChoice, ScreenKind, UpdatePath};
use crate::pages::{ListEntry, OptionNote, card_body, detail_row, option_page_card, step_card_header};
use crate::services::playbook::PageKind;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{InfoBar, RadioGroup, RadioItem, Severity, Typography, a11y_text, card};

impl InstallPage {
    pub(super) fn options_cards(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let theme = cx.theme().clone();
        let (manifest, options, may_edit, screens, current, package_dir, notes) = {
            let state = self.model.read(cx);
            let screens = state.option_screens();
            let current = state.current_option_screen();
            let notes =
                screens.get(current).map(|screen| option_notes(state, &screen.pages)).unwrap_or_default();
            (
                state.manifest().clone(),
                state.effective_options().into_iter().collect::<BTreeSet<_>>(),
                !state.locked() && state.locked_options().is_none(),
                screens,
                current,
                state.playbook.as_ref().map(|package| package.dir.clone()),
                notes,
            )
        };
        let Some(screen) = screens.get(current) else { return Vec::new() };
        if screen.kind == ScreenKind::UpdatePath {
            return self.update_path_cards(cx);
        }
        let model = self.model.clone();
        let mut cards: Vec<AnyElement> =
            choices_bar(self.model.read(cx)).into_iter().map(IntoElement::into_any_element).collect();

        // One decision at a time: the question is the heading, the choice
        // below it, with consequences visible before either answer is chosen.
        // Beside where the user is, which choices can be changed afterwards.
        let kinds: Vec<ScreenKind> = screens.iter().map(|screen| screen.kind).collect();
        let (number, total) = choice_progress(&kinds, current).unwrap_or((current + 1, screens.len()));
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
                        t!("options-progress", number = number, total = total)
                    } else {
                        t!("options-progress-extras", number = number, total = total)
                    },
                )))
                .child(change_later())
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
                |option| notes.get(&option.name).cloned().unwrap_or_default(),
                Rc::new(move |name: &str, cx: &mut gpui::App| {
                    let name = name.to_owned();
                    model.update(cx, |m, cx| m.choose_option(page_index, &name, cx))
                }),
                package_dir.as_deref(),
            ));
        }
        cards
    }

    /// The first screen of an update or reinstall: keep the choices this PC
    /// has, or choose again, above what the PC has now, choice by choice, as
    /// the summary lists them. Choosing again starts every screen from that
    /// list too. The answer can be changed while the choices it keeps can't.
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

        let mut now = card_body();
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
            let chosen = row
                .chosen
                .iter()
                .filter_map(|name| Some(ListEntry::option(name, state.option_text(name)?)))
                .collect();
            let title = row.kind.title();
            let key = format!("now-{index}");
            let unknown = t!("update-path-unknown");
            let value = choice_value(cx, &key, ("now-choices", index), &title, row.required, chosen, unknown);
            now = now.child(detail_row(cx, &key, title, value));
        }
        vec![
            // No "Choice 1 of N": this asks how to treat the choices, not one of them.
            div()
                .flex()
                .type_caption()
                .text_color(theme.text_secondary)
                .child(change_later())
                .into_any_element(),
            card(cx)
                .child(step_card_header(cx, "update-path", question, None))
                .child(card_body().child(group))
                .into_any_element(),
            card(cx)
                .child(step_card_header(cx, "update-path-now", t!("update-path-now-title"), None))
                .child(now)
                .into_any_element(),
        ]
    }
}

/// Which choices can be changed afterwards, beside where the user is.
fn change_later() -> gpui::Div {
    div().flex_1().min_w(px(240.)).child(a11y_text("option-change-later", t!("options-change-later")))
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
        .choice_screens()
        .into_iter()
        .map(|screen| NowRow {
            kind: screen.kind,
            required: screen.required,
            chosen: chosen_on(manifest, &screen.pages, kept, |option| option.name.clone()),
        })
        .collect()
}

/// The line above that list when Atlas's record of the last installation
/// doesn't match this PC, naming each choice of the kinds `differs`.
fn differs_line(differs: &[ScreenKind]) -> Option<String> {
    let choices: Vec<String> = differs.iter().map(|kind| kind.title()).collect();
    (!choices.is_empty()).then(|| t!("update-path-differs", choices = describe::join_and(&choices)))
}

/// The step heading's accessible name on a screen of Your choices, after
/// `heading`, the step: which choice and its question, or the optional
/// extras; on the first screen of an update or reinstall, what it asks.
pub(super) fn choice_heading_name(state: &AppModel, heading: &str) -> Option<String> {
    let screens = state.option_screens();
    let current = state.current_option_screen();
    let screen = screens.get(current)?;
    let kinds: Vec<_> = screens.iter().map(|screen| screen.kind).collect();
    let Some((number, total)) = choice_progress(&kinds, current) else {
        let question = update_path_question(state)?;
        return Some(t!("step-heading-update-path-a11y", heading = heading, question = question));
    };
    Some(if screen.required {
        t!(
            "step-heading-choice-a11y",
            heading = heading,
            progress = t!("options-progress", number = number, total = total),
            question = screen.kind.question()
        )
    } else {
        t!(
            "step-heading-extras-a11y",
            heading = heading,
            progress = t!("options-progress-extras", number = number, total = total)
        )
    })
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

/// Which choice of how many the screen at `current` is, given the kinds of
/// every screen: the first screen of an update or reinstall asks nothing of
/// the package, so it isn't counted, and has no number itself.
fn choice_progress(kinds: &[ScreenKind], current: usize) -> Option<(usize, usize)> {
    let asked = usize::from(kinds.first() == Some(&ScreenKind::UpdatePath));
    let kind = kinds.get(current)?;
    (*kind != ScreenKind::UpdatePath).then(|| (current + 1 - asked, kinds.len() - asked))
}

/// Which bar a screen of choices shows above it, and what it names.
#[derive(Clone, Debug, PartialEq, Eq)]
enum ChoicesNote {
    /// An unfinished install keeps the options it began with.
    Resume,
    /// Windows rebuilt itself: the choices the record of the move kept from
    /// Atlas `previous`, and the required ones it couldn't find, if any.
    Rebase { previous: String, missing: Vec<ScreenKind> },
    /// Keeping the choices of the installed Atlas asks only these, which
    /// this PC can't show.
    Keep(Vec<ScreenKind>),
    /// Choosing again starts each screen from how this PC is set up.
    ChooseAgain,
}

/// The note above a screen of choices: an unfinished install's, a rebuilt
/// Windows's, or how an update or reinstall treats them. An unfinished
/// update that will keep them, with nothing held yet, says so as keeping
/// them does while it asks a choice, and otherwise as an unfinished install.
/// A first install has none.
fn choices_note(state: &AppModel) -> Option<ChoicesNote> {
    if state.original_options().is_some() {
        return Some(ChoicesNote::Resume);
    }
    if let Some(choices) = state.rebase_choices() {
        return Some(ChoicesNote::Rebase { previous: choices.previous, missing: choices.missing });
    }
    if let Some(choices) = state.unfinished_choices() {
        return Some(if choices.complete() {
            ChoicesNote::Resume
        } else {
            ChoicesNote::Keep(choices.missing)
        });
    }
    let update = state.update_choices()?;
    Some(match state.update_path {
        UpdatePath::ChooseAgain => ChoicesNote::ChooseAgain,
        UpdatePath::Keep => ChoicesNote::Keep(update.missing),
    })
}

impl ChoicesNote {
    /// The bar's title, then its message. Keeping the choices names the
    /// screens it shows, which are what this PC can't show.
    fn words(&self) -> (String, String) {
        let titles = |kinds: &[ScreenKind]| {
            let titles: Vec<String> = kinds.iter().map(|kind| kind.title()).collect();
            describe::join_and(&titles)
        };
        match self {
            ChoicesNote::Resume => (t!("resume-choices-title"), t!("resume-choices-detail")),
            ChoicesNote::Rebase { previous, missing } => {
                let previous = previous.as_str();
                let detail = if missing.is_empty() {
                    t!("rebase-choices-detail", previous = previous)
                } else {
                    t!("rebase-choices-partial", previous = previous, missing = titles(missing).as_str())
                };
                (t!("rebase-choices-title", previous = previous), detail)
            }
            ChoicesNote::Keep(missing) => {
                (t!("keep-choices-title"), t!("keep-choices-partial", missing = titles(missing)))
            }
            ChoicesNote::ChooseAgain => (t!("choose-again-title"), t!("choose-again-detail")),
        }
    }
}

/// The bar [`choices_note`] decides, if any.
fn choices_bar(state: &AppModel) -> Option<InfoBar> {
    let note = choices_note(state)?;
    let (title, message) = note.words();
    let bar = InfoBar::new(Severity::Informational, title, message);
    Some(match note {
        ChoicesNote::Resume => bar,
        ChoicesNote::Rebase { .. } => bar.id("options-rebase-note"),
        ChoicesNote::Keep(_) => bar.id("options-keep-note"),
        ChoicesNote::ChooseAgain => bar.id("options-choose-again-note"),
    })
}

/// What each option on the pages `pages` says under it, by name. Every
/// option says what it means, removing Edge that it deletes its data on this
/// PC. Choosing again on an update or reinstall, an option also says what it
/// changes on this PC instead, whether the PC has it, and why an update
/// can't change it; a browser chosen beside one an update keeps installed
/// says both stay.
fn option_notes(state: &AppModel, pages: &[usize]) -> HashMap<String, OptionNote> {
    let manifest = state.manifest();
    let options = state.effective_options();
    let chosen = |name: &str| options.iter().any(|option| option == name);
    let choosing_again = state.update_choices().filter(|_| state.update_path == UpdatePath::ChooseAgain);
    let facts = state.choice_facts();
    let label = |name: &str| {
        state.option_text(name).map_or_else(|| name.to_owned(), |text| describe::option_label(name, text))
    };
    let kept_browser = match state.fixed_option("install-another-browser") {
        Some(FixedChoice::Installed(browser)) if choosing_again.is_some() => Some(browser),
        _ => None,
    };
    let mut notes = HashMap::new();
    for page in pages.iter().filter_map(|&index| manifest.pages.get(index)) {
        for option in &page.options {
            let name = option.name.as_str();
            let mut note = OptionNote::from(describe::known_install_consequence(
                name,
                &option.text,
                state.before_desktop,
            ));
            if let Some(update) = &choosing_again {
                let answered = page.kind == PageKind::Radio || chosen(name);
                note.change = describe::change_line(name, &option.text, answered, &facts);
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
            notes.insert(option.name.clone(), note);
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
        m.manifest().pages.iter().position(|page| page.options.iter().any(|o| o.name == option)).unwrap()
    }

    fn line(id: &str) -> Option<String> {
        Some(crate::i18n::text(id, &[]))
    }

    /// Choosing again on a PC its record contradicts, each answer that
    /// changes the PC says so, the PC's own answers are tagged, what an
    /// update can't undo is fixed with why, and a browser picked beside the
    /// one installed says both stay. Keeping the choices, or a first install,
    /// says only what each option means.
    #[test]
    fn choosing_again_says_what_each_answer_changes_on_this_pc() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("option-notes");
            let record =
                ["defender-enable", "mitigations-default", "auto-updates-disable", "keyboard-shortcuts"];
            let model = installed_model(&mut cx, &temp, Some(&record), removed_pc());
            let all = |m: &AppModel| (0..m.manifest().pages.len()).collect::<Vec<_>>();
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
                assert_eq!(
                    removed.consequence,
                    line("consequence-defender-disable"),
                    "still says what it means"
                );
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

                // Keeping them, or a first install, only says what each means.
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
                    assert_eq!(notes["defender-disable"].consequence, line("consequence-defender-disable"));
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
                let screens: Vec<ScreenKind> = m.choice_screens().iter().map(|screen| screen.kind).collect();
                assert_eq!(kinds, screens, "the summary's rows");
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
                let titles: Vec<String> = update.differs.iter().map(|kind| kind.title()).collect();
                assert_eq!(
                    differs_line(&update.differs),
                    Some(t!("update-path-differs", choices = describe::join_and(&titles)))
                );
                assert_eq!(differs_line(&[]), None, "a record that matches says nothing");

                assert_eq!(
                    update_path_question(m),
                    Some(t!("update-path-reinstall-title", version = "0.6.0"))
                );
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                assert_eq!(update_path_question(m), Some(t!("update-path-update-title", version = "0.6.0")));
                m.install_identity = Ok(InstallIdentity::Fresh);
                assert_eq!(update_path_question(m), None, "a first install has no first screen");
            });
        });
    }

    /// A screen after the first says how its choices are treated: keeping
    /// them names the ones this PC can't show, choosing again says each
    /// starts from the PC. An unfinished install and a rebuilt Windows have
    /// bars of their own, and a first install has none.
    #[test]
    fn the_bar_above_a_screen_says_how_its_choices_are_treated() {
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
                assert_eq!(choices_note(m), Some(ChoicesNote::Keep(vec![ScreenKind::Mitigations])));
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
                assert_eq!(choices_note(m), Some(ChoicesNote::Keep(vec![ScreenKind::Mitigations])));
                m.pc_facts.toggles.insert("Mitigations".into(), 1);
                assert_eq!(choices_note(m), Some(ChoicesNote::Resume), "nothing to ask");
                m.pc_facts.toggles.remove("Mitigations");
                m.install_identity = Ok(InstallIdentity::Installed("0.5.0".into()));
                m.atlas = Ok(None);
                m.update_access =
                    Some(rebuilt(&["defender-disable", "auto-updates-disable", "keyboard-shortcuts"]));
                assert_eq!(
                    choices_note(m),
                    Some(ChoicesNote::Rebase {
                        previous: "0.5.0".into(),
                        missing: vec![ScreenKind::Mitigations]
                    })
                );
                m.install_identity = Ok(InstallIdentity::Fresh);
                m.update_access = None;
                assert_eq!(choices_note(m), None, "a first install has none");
            });
        });
        crate::i18n::testing::english(|| {
            let missing = ChoicesNote::Keep(vec![ScreenKind::Mitigations, ScreenKind::Keyboard]).words();
            let titles = [ScreenKind::Mitigations.title(), ScreenKind::Keyboard.title()];
            let partial = t!("keep-choices-partial", missing = describe::join_and(&titles));
            assert!(partial.ends_with(&format!("{} and {}", titles[0], titles[1])), "{partial}");
            assert_eq!(missing, (t!("keep-choices-title"), partial));
            assert_eq!(
                ChoicesNote::ChooseAgain.words(),
                (t!("choose-again-title"), t!("choose-again-detail"))
            );
            let complete = ChoicesNote::Rebase { previous: "0.5.0".into(), missing: Vec::new() }.words();
            assert_eq!(complete.1, t!("rebase-choices-detail", previous = "0.5.0"));
            let partial =
                ChoicesNote::Rebase { previous: "0.5.0".into(), missing: vec![ScreenKind::Defender] };
            assert!(partial.words().1.ends_with(&ScreenKind::Defender.title()), "{:?}", partial.words());
        });
    }

    /// The step heading's accessible name says what the screen asks: the
    /// first screen its question, the next ones which choice they are, the
    /// first screen not counted.
    #[test]
    fn the_step_heading_names_what_the_screen_asks() {
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("choice-heading");
            let model = installed_model(&mut cx, &temp, Some(&["defender-enable"]), removed_pc());
            model.update(&mut cx, |m, cx| {
                let heading = "Step 2 of 4: Your choices";
                let question = t!("update-path-reinstall-title", version = "0.6.0");
                assert_eq!(
                    choice_heading_name(m, heading),
                    Some(t!("step-heading-update-path-a11y", heading = heading, question = question))
                );
                m.set_update_path(UpdatePath::ChooseAgain, cx);
                m.option_screen = 1;
                let progress = t!("options-progress", number = 1, total = 5);
                assert_eq!(
                    choice_heading_name(m, heading),
                    Some(t!(
                        "step-heading-choice-a11y",
                        heading = heading,
                        progress = progress,
                        question = ScreenKind::Defender.question()
                    ))
                );
            });
        });
    }

    #[test]
    fn the_first_screen_of_an_update_is_not_counted_among_the_choices() {
        use ScreenKind::{Defender, Extras, Mitigations, UpdatePath};
        let update = [UpdatePath, Defender, Mitigations, Extras];
        assert_eq!(choice_progress(&update, 0), None, "it asks nothing of the package");
        assert_eq!(choice_progress(&update, 1), Some((1, 3)));
        assert_eq!(choice_progress(&update, 3), Some((3, 3)));
        assert_eq!(choice_progress(&update, 4), None);
        let first_install = [Defender, Mitigations, Extras];
        assert_eq!(choice_progress(&first_install, 0), Some((1, 3)));
        assert_eq!(choice_progress(&first_install, 2), Some((3, 3)));
    }
}
