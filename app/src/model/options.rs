//! The Options step: one screen per decision, the user's choices, and the
//! option names passed to the installer.

use gpui::Context;

use super::AppModel;
use crate::services::playbook::{FeaturePage, PageKind};

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
            let pages = follow_parents(&manifest.pages, extras);
            screens.push(OptionScreen { kind: ScreenKind::Extras, pages, required: false });
        }
        screens
    }

    /// The screen that is showing, clamped to what the manifest offers.
    pub fn current_option_screen(&self) -> usize {
        self.option_screen.min(self.option_screens().len().saturating_sub(1))
    }

    pub fn choose_option(&mut self, page_index: usize, name: &str, cx: &mut Context<Self>) {
        if self.locked_options().is_some() || self.locked() || !self.flow.may_edit() {
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
        self.save_draft(cx);
        cx.notify();
    }
}

/// Orders `pages` (indexes into `all`) so a page shown only when an option is
/// chosen comes straight after the page that offers that option: the browser
/// picker follows the apps that ask to "choose one below". A page whose
/// option is on no page in `pages` keeps its place, as do pages that depend
/// on each other in a loop.
fn follow_parents(all: &[FeaturePage], pages: Vec<usize>) -> Vec<usize> {
    let parent = |index: usize| {
        let option = all[index].depends_on.as_ref()?;
        pages.iter().copied().find(|&candidate| {
            candidate != index && all[candidate].options.iter().any(|offered| &offered.name == option)
        })
    };
    let mut ordered = Vec::with_capacity(pages.len());
    for &index in pages.iter().filter(|&&index| parent(index).is_none()) {
        place_with_children(index, &pages, &parent, &mut ordered);
    }
    let rest: Vec<usize> = pages.iter().copied().filter(|index| !ordered.contains(index)).collect();
    ordered.extend(rest);
    ordered
}

/// Appends `index`, then the pages that depend on it, each followed by its own.
fn place_with_children(
    index: usize,
    pages: &[usize],
    parent: &dyn Fn(usize) -> Option<usize>,
    out: &mut Vec<usize>,
) {
    if out.contains(&index) {
        return;
    }
    out.push(index);
    for &child in pages.iter().filter(|&&child| parent(child) == Some(index)) {
        place_with_children(child, pages, parent, out);
    }
}

impl AppModel {
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

#[cfg(test)]
mod tests {
    use super::follow_parents;
    use crate::services::playbook::{FeatureOption, FeaturePage, PageKind};

    fn page(option: &str, depends_on: Option<&str>) -> FeaturePage {
        FeaturePage {
            kind: PageKind::Checkbox,
            description: String::new(),
            learn_more: None,
            depends_on: depends_on.map(str::to_owned),
            options: vec![FeatureOption {
                name: option.into(),
                text: option.into(),
                image: None,
                default: false,
            }],
        }
    }

    #[test]
    fn dependent_pages_follow_their_parents_in_manifest_order() {
        let pages = [
            page("a", None),
            page("b-child", Some("a")),
            page("c", None),
            page("d-grandchild", Some("b-child")),
            page("e-child", Some("a")),
            page("f-elsewhere", Some("not-on-these-pages")),
        ];
        assert_eq!(follow_parents(&pages, (0..6).collect()), [0, 1, 3, 4, 2, 5]);
        // Pages that depend on each other keep their manifest order, after the rest.
        let looped = [page("x", Some("y")), page("y", Some("x")), page("z", None)];
        assert_eq!(follow_parents(&looped, vec![0, 1, 2]), [2, 0, 1]);
    }
}
