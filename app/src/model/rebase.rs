//! The choices an update starts from. After Windows rebuilt itself while Get
//! ready moved it to a newer release, the update worker's record keeps the
//! Atlas version and the choices from before the move, so the user isn't
//! asked again for what it already knows. Otherwise an update or reinstall
//! starts from what this PC has, which wins over Atlas's record of the last
//! installation: an earlier update may have recorded a choice it never
//! applied.

use std::borrow::Cow;
use std::collections::BTreeSet;

use super::options::OptionScreen;
use super::{AppModel, FixedChoice, ScreenKind, UpdatePath};
use crate::services::atlas_state::{InstallIdentity, InstallMode};
use crate::services::legacy_choices::{self, Facts};
use crate::services::playbook::PageKind;
use crate::services::releases::AtlasVersion;

/// The option that removes Microsoft Edge.
const UNINSTALL_EDGE: &str = "uninstall-edge";

/// Whether `version`, an installed Atlas's, is older than 0.6, as the update
/// worker's `Test-AtlasVersionBefore06` reads it.
fn version_before_0_6(version: &str) -> bool {
    AtlasVersion::parse(version).is_some_and(|version| (version.core.0, version.core.1) < (0, 6))
}

/// What an update or reinstall of the installed Atlas starts from.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UpdateChoices {
    /// The Atlas version installed now.
    pub previous: String,
    /// This flow installs that version again rather than updating it.
    pub reinstall: bool,
    /// The choices this PC has, for this package: what it shows, then, for
    /// what it can't show, Atlas's record of the last installation, else
    /// what the record of a Windows move kept.
    pub kept: Vec<String>,
    /// Required choices neither shows; keeping the choices asks only these.
    pub missing: Vec<ScreenKind>,
    /// Where Atlas's record of the last installation doesn't match this PC:
    /// the kind of each page whose choice differs, in page order.
    pub differs: Vec<ScreenKind>,
}

impl UpdateChoices {
    /// Every required choice is known, so keeping them asks nothing.
    pub fn complete(&self) -> bool {
        self.missing.is_empty()
    }
}

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

/// What an unfinished update or reinstall that has run no step goes on with
/// when it began keeping the choices: its capture starts again and, as Keep
/// my choices does, takes every choice this PC shows, whatever is sent.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UnfinishedChoices {
    /// The choices this PC has, for this package, as keeping them reads them.
    pub kept: Vec<String>,
    /// Required choices this PC doesn't show; the user makes them.
    pub missing: Vec<ScreenKind>,
}

impl UnfinishedChoices {
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
        // A record of a move from an Atlas before 0.6 that an earlier update
        // wrote took its Mitigations choice from the toggle records as they
        // were, the old Toolbox's own among them, which never changed the PC,
        // and the Rebase would apply it. Only the record a launcher left
        // gives that choice, as the update's own repair reads the records.
        let carried = if version_before_0_6(&previous) {
            let mitigations = carry.toggles.iter().find(|record| record.name == "Mitigations");
            legacy_choices::rebase_options_before_0_6(
                &carry.options,
                mitigations.map(|record| (record.state, record.path.as_deref())),
            )
        } else {
            carry.options.clone()
        };
        // Someone kept Edge or put it back, so the Rebase leaves it, and
        // Your choices shows it kept.
        let options: Vec<String> = carried
            .iter()
            .filter(|name| manifest.option_label(name).is_some())
            .filter(|name| !(carry.edge && name.as_str() == UNINSTALL_EDGE))
            .cloned()
            .collect();
        let missing = self.missing_choices(&options);
        Some(RebaseChoices { previous, options, missing })
    }

    /// Whether `options` leave the required choice `screen` asks unmade.
    pub(super) fn unanswered(&self, screen: &OptionScreen, options: &[String]) -> bool {
        let manifest = self.manifest();
        screen.required
            && !screen.pages.iter().any(|&index| {
                manifest.pages[index].options.iter().any(|option| options.contains(&option.name))
            })
    }

    /// Choices Your choices may not change: an unfinished install's, a
    /// rebuilt Windows's when its record kept every required one, or this
    /// PC's when keeping them and it shows every required one, as for an
    /// unfinished update that will keep them.
    pub fn locked_options(&self) -> Option<Vec<String>> {
        if let Some(options) = self.original_options() {
            return Some(options.to_vec());
        }
        if let Some(choices) = self.rebase_choices() {
            return choices.complete().then_some(choices.options);
        }
        if let Some(choices) = self.unfinished_choices() {
            return choices.complete().then_some(choices.kept);
        }
        self.update_choices()
            .filter(|choices| self.update_path == UpdatePath::Keep && choices.complete())
            .map(|choices| choices.kept)
    }

    /// What updating or reinstalling the installed Atlas starts Your choices
    /// from. Not after Windows rebuilt itself during a move, whose record
    /// decides, nor for an unfinished install, which keeps its own, nor
    /// before the desktop exists.
    pub fn update_choices(&self) -> Option<UpdateChoices> {
        let Ok(InstallIdentity::Installed(version)) = &self.install_identity else { return None };
        if self.before_desktop || self.rebase_choices().is_some() {
            return None;
        }
        let (kept, recorded) = self.pc_choices();
        let missing = self.missing_choices(&kept);
        let manifest = self.manifest();
        let mut differs = Vec::new();
        if let Some(recorded) = recorded {
            for page in &manifest.pages {
                let chosen = |options: &[String]| -> BTreeSet<String> {
                    page.options
                        .iter()
                        .filter(|o| options.contains(&o.name))
                        .map(|o| o.name.clone())
                        .collect()
                };
                let kind = ScreenKind::of_page(page);
                if chosen(&recorded) != chosen(&kept) && !differs.contains(&kind) {
                    differs.push(kind);
                }
            }
        }
        Some(UpdateChoices {
            previous: version.clone(),
            reinstall: *version == manifest.version,
            kept,
            missing,
            differs,
        })
    }

    /// What an unfinished update or reinstall goes on with when it has run
    /// no step and began keeping the choices: its capture starts again and
    /// takes every choice this PC shows, as Keep my choices does, so Your
    /// choices holds them as keeping them does. Not for one that holds its
    /// options or chose again, nor after Windows rebuilt itself during a
    /// move, whose record decides.
    pub fn unfinished_choices(&self) -> Option<UnfinishedChoices> {
        let Ok(InstallIdentity::Resume(_, unfinished)) = &self.install_identity else { return None };
        let keeps = unfinished.held.is_none()
            && !unfinished.choose_again
            && matches!(unfinished.mode, InstallMode::Upgrade | InstallMode::Reapply);
        if !keeps || self.before_desktop || self.rebase_choices().is_some() {
            return None;
        }
        let (kept, _) = self.pc_choices();
        let missing = self.missing_choices(&kept);
        Some(UnfinishedChoices { kept, missing })
    }

    /// The choices this PC has, for this package: what it shows, then, for
    /// what it can't show, Atlas's record of the last installation, else what
    /// the record of a Windows move kept. Then that record of the last
    /// installation, if it names any.
    fn pc_choices(&self) -> (Vec<String>, Option<Vec<String>>) {
        let facts = self.update_facts();
        let recorded =
            self.installed().map(|state| state.options.clone()).filter(|options| !options.is_empty());
        let carried = || {
            let carry = self.update_access.as_ref()?.journal.as_ref()?.carry.as_ref()?;
            let options = if self.before_0_6() {
                legacy_choices::carried_before_0_6(&carry.options)
            } else {
                carry.options.clone()
            };
            Some(options).filter(|options| !options.is_empty())
        };
        // Without either, the PC is all an Atlas before 0.6 has to show its
        // choices, which then read as Atlas 0.5.0 left them.
        let base =
            recorded.clone().or_else(carried).unwrap_or_else(|| legacy_choices::observed_options(&facts));
        let manifest = self.manifest();
        let offered = |name: &String| manifest.option_label(name).is_some();
        let kept = legacy_choices::kept_options(&base, &facts).into_iter().filter(offered).collect();
        (kept, recorded)
    }

    /// The required choices `kept` leaves unmade, which keeping them asks.
    fn missing_choices(&self, kept: &[String]) -> Vec<ScreenKind> {
        self.choice_screens()
            .into_iter()
            .filter(|screen| self.unanswered(screen, kept))
            .map(|screen| screen.kind)
            .collect()
    }

    /// Whether keeping the choices `kept` asks `name`: it is on a required
    /// screen they leave unmade.
    fn asked_when_keeping(&self, kept: &[String], name: &str) -> bool {
        let manifest = self.manifest();
        self.choice_screens().into_iter().any(|screen| {
            self.unanswered(&screen, kept)
                && screen
                    .pages
                    .iter()
                    .any(|&page| manifest.pages[page].options.iter().any(|o| o.name == name))
        })
    }

    /// Why `name` can't be changed on this update or reinstall, if it can't.
    /// Keeping the choices fixes every option on a screen this PC answers,
    /// as does an unfinished update that will keep them. Choosing again
    /// fixes what an update can't undo: Edge already removed, and a Toolbox
    /// or browser Atlas installed, which it never uninstalls; another browser
    /// can still be picked. Not Snipping Tool: only this account's apps can
    /// be read, and other accounts may still have it, which ticking it
    /// removes for good.
    pub fn fixed_option(&self, name: &str) -> Option<FixedChoice> {
        if let Some(unfinished) = self.unfinished_choices() {
            return (!self.asked_when_keeping(&unfinished.kept, name)).then_some(FixedChoice::Kept);
        }
        let update = self.update_choices()?;
        if self.update_path == UpdatePath::Keep {
            return (!self.asked_when_keeping(&update.kept, name)).then_some(FixedChoice::Kept);
        }
        let facts = self.update_facts();
        let kept = update.kept.iter().any(|option| option == name);
        match name {
            "uninstall-edge" if facts.edge == Some(false) => Some(FixedChoice::EdgeRemoved),
            // Atlas's record of the last installation, which ticks it,
            // outlives a Toolbox someone uninstalled.
            "install-toolbox" if kept && facts.toolbox_program == Some(true) => {
                Some(FixedChoice::Installed(name.to_owned()))
            }
            "install-another-browser" if kept => {
                let installed = facts.browsers.as_deref().unwrap_or_default();
                update
                    .kept
                    .iter()
                    .find(|option| option.starts_with("browser-") && installed.contains(option))
                    .map(|browser| FixedChoice::Installed(browser.clone()))
            }
            _ => None,
        }
    }

    /// The choices the installed Atlas has now: its record, with what this
    /// PC shows winning. Home, the "Atlas is installed" window and the
    /// Defender reminders show these.
    pub fn installed_options(&self) -> Vec<String> {
        self.installed()
            .map(|state| legacy_choices::kept_options(&state.options, &self.pc_facts))
            .unwrap_or_default()
    }

    /// What this PC shows, with the records an Atlas before 0.6 left read as
    /// they mean there.
    pub(super) fn update_facts(&self) -> Cow<'_, Facts> {
        if self.before_0_6() {
            Cow::Owned(self.pc_facts.clone().before_0_6())
        } else {
            Cow::Borrowed(&self.pc_facts)
        }
    }

    /// The installed Atlas is older than 0.6: only an install from 0.6 on
    /// writes a state document with its version.
    fn before_0_6(&self) -> bool {
        !matches!(&self.atlas, Ok(Some(state))
            if state.installed_version.as_deref().is_some_and(|version| !version.trim().is_empty()))
    }

    /// Starts Your choices, once per flow, from the choices a rebuilt
    /// Windows's record kept, or else from the ones this PC has. A radio
    /// choice neither shows keeps the current one, or else its default,
    /// including one on a page shown only once another option is ticked.
    pub(super) fn apply_recorded_choices(&mut self) {
        if self.recorded_choices_applied {
            return;
        }
        let kept = if let Some(choices) = self.rebase_choices() {
            choices.options
        } else if let Some(choices) = self.unfinished_choices() {
            choices.kept
        } else if let Some(choices) = self.update_choices() {
            choices.kept
        } else {
            return;
        };
        self.recorded_choices_applied = true;
        let mut options: BTreeSet<String> = kept.into_iter().collect();
        let manifest = self.manifest();
        // The browser picker too: a record names a browser only when one was
        // installed, and the installer refuses the picker left empty once shown.
        for page in manifest.pages.iter().filter(|page| page.kind == PageKind::Radio) {
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
