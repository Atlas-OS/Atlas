//! The Options step: one screen per decision, the user's choices, and the
//! option names passed to the installer. Updating or reinstalling an
//! installed Atlas first asks whether to keep its choices or choose again.

use gpui::Context;

use super::AppModel;
use crate::services::atlas_state::InstallIdentity;
use crate::services::playbook::{self, FeaturePage, PageKind};

/// One screen of the Options step.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OptionScreen {
    /// What the screen decides; its title and question are worded at render.
    pub kind: ScreenKind,
    /// Indexes into the manifest's pages shown on this screen.
    pub pages: Vec<usize>,
    /// Exactly one choice is required.
    pub required: bool,
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

/// What a page of options controls, derived from its first option's stable
/// name. The words for each kind live in the message catalog.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ScreenKind {
    /// The first screen of an update or reinstall: keep the choices this PC
    /// has, or choose again. It has no pages of its own.
    UpdatePath,
    Defender,
    Mitigations,
    Updates,
    Keyboard,
    Browser,
    Power,
    Apps,
    OptionalApps,
    ChooseOne,
    Extras,
}

impl ScreenKind {
    pub fn of_page(page: &FeaturePage) -> ScreenKind {
        let first = page.options.first().map(|o| o.name.as_str()).unwrap_or_default();
        match first {
            n if n.starts_with("defender") => ScreenKind::Defender,
            n if n.starts_with("mitigations") => ScreenKind::Mitigations,
            n if n.starts_with("auto-updates") => ScreenKind::Updates,
            n if n.starts_with("keyboard-") => ScreenKind::Keyboard,
            n if n.starts_with("browser") => ScreenKind::Browser,
            n if n.starts_with("disable-hibernation") || n.starts_with("disable-power") => ScreenKind::Power,
            n if n.starts_with("remove-")
                || n.starts_with("uninstall-")
                || n.starts_with("install-another") =>
            {
                ScreenKind::Apps
            }
            "install-toolbox" | "install-eclean" => ScreenKind::OptionalApps,
            _ => match page.kind {
                PageKind::Radio => ScreenKind::ChooseOne,
                PageKind::Checkbox => ScreenKind::Extras,
            },
        }
    }
}

impl AppModel {
    /// An option's text in the loaded package, or in the app's own when the
    /// loaded one doesn't have it.
    pub fn option_text(&self, name: &str) -> Option<&str> {
        self.manifest().option_label(name).or_else(|| self.builtin_manifest.option_label(name))
    }

    /// The Options step's screens: the package's choices, after the update
    /// path on an update or reinstall of the installed Atlas. Keeping its
    /// choices shows only those this PC can't show, and so does an unfinished
    /// update that will keep them, which has no first screen as it goes on
    /// as it began; with every choice shown, each screen shows what it keeps.
    pub fn option_screens(&self) -> Vec<OptionScreen> {
        let screens = self.choice_screens();
        if let Some(unfinished) = self.unfinished_choices() {
            if unfinished.complete() {
                return screens;
            }
            return screens.into_iter().filter(|screen| self.unanswered(screen, &unfinished.kept)).collect();
        }
        let Some(update) = self.update_choices() else { return screens };
        let keep = self.update_path == UpdatePath::Keep;
        std::iter::once(OptionScreen { kind: ScreenKind::UpdatePath, pages: Vec::new(), required: false })
            .chain(screens.into_iter().filter(|screen| !keep || self.unanswered(screen, &update.kept)))
            .collect()
    }

    /// The package's choices, one decision per screen: every required choice
    /// (radio page) gets its own screen, phrased as a question, and the
    /// optional extras share the last one.
    pub fn choice_screens(&self) -> Vec<OptionScreen> {
        let manifest = self.manifest();
        let mut screens = Vec::new();
        let mut extras = Vec::new();
        for (index, page) in manifest.pages.iter().enumerate() {
            if page.kind == PageKind::Radio && page.depends_on.is_none() {
                screens.push(OptionScreen {
                    kind: ScreenKind::of_page(page),
                    pages: vec![index],
                    required: true,
                });
            } else {
                extras.push(index);
            }
        }
        if !extras.is_empty() {
            let pages = playbook::follow_parents(&manifest.pages, extras);
            screens.push(OptionScreen { kind: ScreenKind::Extras, pages, required: false });
        }
        screens
    }

    /// The screen that is showing, clamped to what the manifest offers.
    pub fn current_option_screen(&self) -> usize {
        self.option_screen.min(self.option_screens().len().saturating_sub(1))
    }

    pub fn choose_option(&mut self, page_index: usize, name: &str, cx: &mut Context<Self>) {
        if self.locked_options().is_some() || self.locked() || self.fixed_option(name).is_some() {
            return;
        }
        let Some(page) = self.manifest().pages.get(page_index) else { return };
        match page.kind {
            PageKind::Radio => {
                let siblings: Vec<String> = page.options.iter().map(|o| o.name.clone()).collect();
                for sibling in siblings {
                    self.options.remove(&sibling);
                }
                self.options.insert(name.to_owned());
            }
            PageKind::Checkbox => {
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

    /// Option names to pass to the installer: an unfinished install's
    /// original choices, a rebuilt Windows's kept ones, or the current ones
    /// honouring `DependsOn` pages.
    pub fn effective_options(&self) -> Vec<String> {
        if let Some(options) = self.locked_options() {
            return options;
        }
        let manifest = self.manifest();
        let mut names = Vec::new();
        for page in &manifest.pages {
            if page.depends_on.as_ref().is_some_and(|dependency| !self.options.contains(dependency)) {
                continue;
            }
            for option in &page.options {
                if self.options.contains(&option.name) {
                    names.push(option.name.clone());
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
