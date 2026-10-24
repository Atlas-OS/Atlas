//! The Options step: one screen per decision, the user's choices, and the
//! option names passed to the installer.

use gpui::Context;

use super::AppModel;
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

/// What a page of options controls, derived from its first option's stable
/// name. The words for each kind live in the message catalog.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ScreenKind {
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

    /// The Options step, one decision per screen: every required choice
    /// (radio page) gets its own screen, phrased as a question, and the
    /// optional extras share the last one.
    pub fn option_screens(&self) -> Vec<OptionScreen> {
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
        if self.locked_options().is_some() || self.locked() {
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
}
