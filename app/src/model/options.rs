//! Your choices: the Atlas package's questions on one screen, with its
//! optional extras folded under them, the user's answers, and the option ids
//! passed to the installer. Updating or reinstalling an installed Atlas first
//! asks, on a screen of its own, whether to keep its choices or choose again.

use gpui::Context;

use super::AppModel;
use crate::environment::Environment;
use crate::services::atlas_state::InstallIdentity;
use crate::services::package::{self, Choice, ChoiceKind};

/// The keyboard choice's answer for a PC with one keyboard layout.
const ONE_LAYOUT: &str = "keyboard-single";

/// One question of Your choices, or the optional extras: a card, or the
/// folded section the extras share, on the choices screen, and one row of
/// the Install summary.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ChoiceGroup {
    /// What it decides; its title and question are worded at render.
    pub kind: ScreenKind,
    /// Indexes into the manifest's choices it shows.
    pub pages: Vec<usize>,
    /// A question, which takes exactly one answer. The extras are optional.
    pub required: bool,
}

/// A screen of Your choices.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum OptionScreen {
    /// The first screen of an update or reinstall: keep the choices this PC
    /// has, or choose again.
    UpdatePath,
    /// The questions this flow asks, a card each, then the optional extras
    /// when it asks them.
    Choices(Vec<ChoiceGroup>),
}

impl OptionScreen {
    /// What the screen asks of the package's choices.
    pub fn groups(&self) -> &[ChoiceGroup] {
        match self {
            OptionScreen::UpdatePath => &[],
            OptionScreen::Choices(groups) => groups,
        }
    }
}

/// How an update or reinstall of the installed Atlas treats its choices.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum UpdatePath {
    /// Every choice stays as this PC has it; only what the PC can't show is
    /// asked.
    #[default]
    Keep,
    /// Every choice is asked again, starting from how this PC is set up, and
    /// the install applies each one (the front door's `-ChooseAgain`).
    ChooseAgain,
}

impl UpdatePath {
    /// The draft's name for it.
    pub fn id(self) -> &'static str {
        match self {
            UpdatePath::Keep => "keep",
            UpdatePath::ChooseAgain => "choose-again",
        }
    }

    pub fn from_id(id: &str) -> Option<UpdatePath> {
        [UpdatePath::Keep, UpdatePath::ChooseAgain].into_iter().find(|path| path.id() == id)
    }
}

/// Why an option can't be changed on this update.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum FixedChoice {
    /// Keep my choices keeps it as this PC has it.
    Kept,
    /// Microsoft Edge is already removed, and an update can't put it back.
    EdgeRemoved,
    /// What the option installs is on this PC, and Atlas doesn't uninstall
    /// apps. Names it by option: `install-toolbox`, or the `browser-*` there.
    Installed(String),
}

/// What a question or group of choices controls, from the stable id of the
/// choice it shows. The words for each kind live in the message catalog.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ScreenKind {
    /// How an update or reinstall treats the installed Atlas's choices: the
    /// first screen, and the Install summary's first row. It shows no choice
    /// of the package.
    UpdatePath,
    Defender,
    Mitigations,
    Updates,
    Keyboard,
    Browser,
    Power,
    Apps,
    OptionalApps,
    /// A single choice this app doesn't know.
    ChooseOne,
    /// A multiple choice this app doesn't know, and the group the optional
    /// choices share.
    Extras,
}

impl ScreenKind {
    pub fn of_choice(choice: &Choice) -> ScreenKind {
        match choice.id.as_str() {
            "defender" => ScreenKind::Defender,
            "mitigations" => ScreenKind::Mitigations,
            "auto-updates" => ScreenKind::Updates,
            "keyboard" => ScreenKind::Keyboard,
            "browser" => ScreenKind::Browser,
            "system" => ScreenKind::Power,
            "apps" => ScreenKind::Apps,
            "extras" => ScreenKind::OptionalApps,
            _ => match choice.kind {
                ChoiceKind::Single => ScreenKind::ChooseOne,
                ChoiceKind::Multiple => ScreenKind::Extras,
            },
        }
    }
}

/// How many keyboard layouts this user can switch between, or `None`, with
/// the reason logged, when Windows can't say.
pub(super) fn read_keyboard_layouts(env: &Environment) -> Option<usize> {
    match (env.adapters.read_keyboard_layouts)() {
        Ok(count) => Some(count),
        Err(error) => {
            log::warn!(
                "Couldn't list the keyboard layouts, so Your choices asks how to switch them: {error:#}"
            );
            None
        }
    }
}

impl AppModel {
    /// An option's text in the loaded package, or in the app's own when the
    /// loaded one doesn't have it.
    pub fn option_text(&self, name: &str) -> Option<&str> {
        self.manifest().option_label(name).or_else(|| self.builtin_manifest.option_label(name))
    }

    /// Lists the keyboard layouts again, as the user may have added or
    /// removed one since. A preview keeps the count it shows.
    pub(super) fn refresh_keyboard_layouts(&mut self) {
        if !super::preview::active() {
            self.keyboard_layouts = read_keyboard_layouts(&self.env);
        }
    }

    /// The answer Atlas gives `choice` itself instead of asking it: the
    /// keyboard choice, on a PC with one keyboard layout, which has nothing
    /// to switch between. Not when Windows can't list the layouts, nor for
    /// choices made when an Atlas ISO was created: before the desktop exists,
    /// and in the Windows such an ISO has just installed.
    pub fn detected_answer(&self, choice: &Choice) -> Option<&'static str> {
        (ScreenKind::of_choice(choice) == ScreenKind::Keyboard
            && self.keyboard_layouts == Some(1)
            && !self.before_desktop
            && !self.staged_iso_setup
            && choice.options.iter().any(|option| option.id == ONE_LAYOUT))
        .then_some(ONE_LAYOUT)
    }

    /// `options` with the answer Atlas finds itself (see
    /// [`Self::detected_answer`]) for each choice they leave unanswered. An
    /// answer they hold, such as a recorded one, stands.
    pub(super) fn with_detected(&self, mut options: Vec<String>) -> Vec<String> {
        for choice in &self.manifest().choices {
            if let Some(answer) = self.detected_answer(choice)
                && !choice.options.iter().any(|option| options.contains(&option.id))
            {
                options.push(answer.to_owned());
            }
        }
        options
    }

    /// Whether this flow asks every question, so the ones Atlas answers
    /// itself are left out and take its answer: a first install, and
    /// choosing again. The other flows start from choices an install
    /// recorded, which stand, and fill only what they lack.
    fn asks_every_question(&self) -> bool {
        self.original_options().is_none()
            && self.unfinished_choices().is_none()
            && self.rebase_choices().is_none()
            && !(self.update_path == UpdatePath::Keep && self.update_choices().is_some())
    }

    /// Whether Atlas answers `group`'s question itself in a flow that asks
    /// every one.
    fn answered_itself(&self, group: &ChoiceGroup) -> bool {
        let manifest = self.manifest();
        group.required
            && group.pages.iter().any(|&page| {
                manifest.choices.get(page).is_some_and(|choice| self.detected_answer(choice).is_some())
            })
    }

    /// Your choices' screens. An update or reinstall of the installed Atlas
    /// first asks how to treat its choices. Then one screen asks the
    /// questions this flow asks, with the optional extras under them. A
    /// first install, and choosing again, ask every question but the ones
    /// Atlas answers itself. Keeping the choices, after Windows rebuilt
    /// itself during a move, and in an unfinished update that keeps them,
    /// only what nothing recorded or shows is asked; with nothing to ask, an
    /// update has only its first screen, while the others show every choice
    /// as it stays. So does an unfinished install, which holds its own.
    pub fn option_screens(&self) -> Vec<OptionScreen> {
        let groups = self.choice_groups();
        let update = self.update_choices();
        let unanswered = |groups: Vec<ChoiceGroup>, kept: &[String]| -> Vec<ChoiceGroup> {
            groups.into_iter().filter(|group| self.unanswered(group, kept)).collect()
        };
        let asked = if self.original_options().is_some() {
            groups
        } else if let Some(unfinished) = self.unfinished_choices() {
            if unfinished.complete() { groups } else { unanswered(groups, &unfinished.kept) }
        } else if let Some(rebase) = self.rebase_choices() {
            if rebase.complete() { groups } else { unanswered(groups, &rebase.options) }
        } else if let Some(update) = update.as_ref().filter(|_| self.update_path == UpdatePath::Keep) {
            unanswered(groups, &update.kept)
        } else {
            groups.into_iter().filter(|group| !self.answered_itself(group)).collect()
        };
        let first = update.is_some().then_some(OptionScreen::UpdatePath);
        let choices = (!asked.is_empty()).then_some(OptionScreen::Choices(asked));
        first.into_iter().chain(choices).collect()
    }

    /// The package's choices as Your choices groups them: each required
    /// choice (a single choice asked whatever else is chosen) is a question
    /// of its own, and the optional ones share the extras, where a page that
    /// depends on an option comes straight after the page that offers it.
    pub fn choice_groups(&self) -> Vec<ChoiceGroup> {
        let manifest = self.manifest();
        let mut groups = Vec::new();
        let mut extras = Vec::new();
        for (index, choice) in manifest.choices.iter().enumerate() {
            if choice.kind == ChoiceKind::Single && choice.depends_on.is_none() {
                groups.push(ChoiceGroup {
                    kind: ScreenKind::of_choice(choice),
                    pages: vec![index],
                    required: true,
                });
            } else {
                extras.push(index);
            }
        }
        if !extras.is_empty() {
            let pages = package::follow_parents(&manifest.choices, extras);
            groups.push(ChoiceGroup { kind: ScreenKind::Extras, pages, required: false });
        }
        groups
    }

    /// The screen that is showing, clamped to what the manifest offers.
    pub fn current_option_screen(&self) -> usize {
        self.option_screen.min(self.option_screens().len().saturating_sub(1))
    }

    /// Where the screen of questions is among [`Self::option_screens`], if
    /// this flow has one.
    pub fn choices_screen(&self) -> Option<usize> {
        self.option_screens().iter().position(|screen| matches!(screen, OptionScreen::Choices(_)))
    }

    /// Unfolds or folds the optional extras on Your choices.
    pub fn show_extras(&mut self, shown: bool, cx: &mut Context<Self>) {
        if self.extras_shown != shown {
            self.extras_shown = shown;
            cx.notify();
        }
    }

    pub fn choose_option(&mut self, page_index: usize, name: &str, cx: &mut Context<Self>) {
        if self.locked_options().is_some() || self.locked() || self.fixed_option(name).is_some() {
            return;
        }
        let Some(choice) = self.manifest().choices.get(page_index) else { return };
        match choice.kind {
            ChoiceKind::Single => {
                let siblings: Vec<String> = choice.options.iter().map(|o| o.id.clone()).collect();
                for sibling in siblings {
                    self.options.remove(&sibling);
                }
                self.options.insert(name.to_owned());
            }
            ChoiceKind::Multiple => {
                if !self.options.remove(name) {
                    self.options.insert(name.to_owned());
                }
            }
        }
        // A page this choice reveals opens with its default chosen; the
        // installer refuses a required choice left unmade.
        self.fill_radio_defaults();
        self.save_draft(cx);
        cx.notify();
    }

    /// Option ids to pass to the installer: an unfinished install's
    /// original choices, a rebuilt Windows's kept ones, or the current ones
    /// honouring each choice's `dependsOn`. A flow that asks every question
    /// gives the ones Atlas answers itself that answer, as they aren't shown.
    pub fn effective_options(&self) -> Vec<String> {
        if let Some(options) = self.locked_options() {
            return options;
        }
        let manifest = self.manifest();
        let detect = self.asks_every_question();
        let mut names = Vec::new();
        for choice in &manifest.choices {
            if choice.depends_on.as_ref().is_some_and(|dependency| !self.options.contains(dependency)) {
                continue;
            }
            if let Some(answer) = self.detected_answer(choice).filter(|_| detect) {
                names.push(answer.to_owned());
                continue;
            }
            for option in &choice.options {
                if self.options.contains(&option.id) {
                    names.push(option.id.clone());
                }
            }
        }
        names
    }

    /// Chooses how this update or reinstall treats the installed Atlas's
    /// choices. Keeping them starts again from what this PC has, so nothing
    /// changed while choosing again is sent.
    pub fn set_update_path(&mut self, path: UpdatePath, cx: &mut Context<Self>) {
        if self.locked() || self.update_path == path || self.update_choices().is_none() {
            return;
        }
        self.update_path = path;
        if path == UpdatePath::Keep {
            self.recorded_choices_applied = false;
            self.apply_recorded_choices();
        }
        self.save_draft(cx);
        cx.notify();
    }

    /// Whether the install goes through every choice again (`-ChooseAgain`):
    /// on an update or reinstall, the path this flow chose; for an unfinished
    /// install, the one it began with. Until a step has run the install would
    /// take another, but Your choices has no first screen to ask for one, so
    /// a new flow goes on as the install began.
    pub fn choosing_again(&self) -> bool {
        match &self.install_identity {
            Ok(InstallIdentity::Resume(_, unfinished)) => unfinished.choose_again,
            _ => self.update_path == UpdatePath::ChooseAgain && self.update_choices().is_some(),
        }
    }
}
