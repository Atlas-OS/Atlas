//! Putting Atlas back on a Windows that rebuilt itself while Get ready moved
//! it to a newer release. The update worker decides that from what Setup
//! left; its record keeps the Atlas version and the choices from before the
//! move, so the user isn't asked again for what it already knows.

use std::collections::BTreeSet;

use super::{AppModel, ScreenKind};
use crate::services::atlas_state::InstallIdentity;
use crate::services::playbook::PageKind;

/// The option that removes Microsoft Edge.
const UNINSTALL_EDGE: &str = "uninstall-edge";

/// The choices the record of a rebuilt Windows kept, for this package.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RebaseChoices {
    /// The Atlas version the PC had before Windows moved.
    pub previous: String,
    /// The kept option names this package offers.
    pub options: Vec<String>,
    /// Required choices nothing in the record shows; the user makes them.
    pub missing: Vec<ScreenKind>,
}

impl RebaseChoices {
    /// Every required choice is known, so Your choices has nothing to ask.
    pub fn complete(&self) -> bool {
        self.missing.is_empty()
    }
}

impl AppModel {
    /// The choices to put Atlas back with, when Windows rebuilt itself during
    /// the move and the record kept the install it had.
    pub fn rebase_choices(&self) -> Option<RebaseChoices> {
        let carry = self.update_access.as_ref()?.journal.as_ref()?.rebase()?;
        let previous = carry.atlas_version.clone()?;
        let manifest = self.manifest();
        let offered: BTreeSet<&str> = manifest
            .pages
            .iter()
            .flat_map(|page| page.options.iter().map(|option| option.name.as_str()))
            .collect();
        // Someone kept Edge or put it back, so the Rebase leaves it, and
        // Your choices shows it kept.
        let options: Vec<String> = carry
            .options
            .iter()
            .filter(|name| offered.contains(name.as_str()))
            .filter(|name| !(carry.edge && name.as_str() == UNINSTALL_EDGE))
            .cloned()
            .collect();
        let missing = self
            .option_screens()
            .into_iter()
            .filter(|screen| screen.required)
            .filter(|screen| {
                !screen.pages.iter().any(|&index| {
                    manifest.pages[index].options.iter().any(|option| options.contains(&option.name))
                })
            })
            .map(|screen| screen.kind)
            .collect();
        Some(RebaseChoices { previous, options, missing })
    }

    /// Choices Your choices may not change: an unfinished install's, or a
    /// rebuilt Windows's when its record kept every required one.
    pub fn locked_options(&self) -> Option<Vec<String>> {
        if let Some(options) = self.original_options() {
            return Some(options.to_vec());
        }
        self.rebase_choices().filter(RebaseChoices::complete).map(|choices| choices.options)
    }

    /// The installed Atlas and the choices it made, to start Your choices
    /// from on an update: a recorded install's options; for an older Atlas,
    /// those the record of a Windows move kept, or what the PC shows now.
    pub fn installed_choices(&self) -> Option<(String, Vec<String>)> {
        let Ok(InstallIdentity::Installed(version)) = &self.install_identity else { return None };
        let recorded =
            self.installed().map(|state| state.options.clone()).filter(|options| !options.is_empty());
        let carried = || {
            let journal = self.update_access.as_ref()?.journal.as_ref()?;
            journal.carry.as_ref().map(|carry| carry.options.clone()).filter(|options| !options.is_empty())
        };
        let observed = || Some(self.legacy_choices.clone()).filter(|options| !options.is_empty());
        let options = recorded.or_else(carried).or_else(observed)?;
        let offered: BTreeSet<&str> = self
            .manifest()
            .pages
            .iter()
            .flat_map(|page| page.options.iter().map(|option| option.name.as_str()))
            .collect();
        let options = options.into_iter().filter(|name| offered.contains(name.as_str())).collect();
        Some((version.clone(), options))
    }

    /// Starts Your choices, once per flow, from the choices a rebuilt
    /// Windows's record kept, or else from the installed Atlas's. A required
    /// choice neither shows keeps the current one.
    pub(super) fn apply_recorded_choices(&mut self) {
        if self.recorded_choices_applied {
            return;
        }
        let kept = match self.rebase_choices() {
            Some(choices) => choices.options,
            None => match self.installed_choices() {
                Some((_, options)) => options,
                None => return,
            },
        };
        self.recorded_choices_applied = true;
        let mut options: BTreeSet<String> = kept.into_iter().collect();
        for page in &self.manifest().pages {
            if page.kind != PageKind::Radio || page.depends_on.is_some() {
                continue;
            }
            if page.options.iter().any(|option| options.contains(&option.name)) {
                continue;
            }
            let current = page
                .options
                .iter()
                .find(|option| self.options.contains(&option.name))
                .or_else(|| page.options.iter().find(|option| option.default));
            if let Some(current) = current {
                options.insert(current.name.clone());
            }
        }
        self.options = options;
    }
}
