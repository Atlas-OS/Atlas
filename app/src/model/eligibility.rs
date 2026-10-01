//! Whether an install may start on this PC with the package at hand: the
//! installed Atlas, an unfinished install and the shared install record.

use std::path::PathBuf;

use gpui::Context;

use super::{AppModel, ReleaseCheck};
use crate::services::atlas_state::{AtlasState, InstallIdentity};
use crate::services::{iso, releases};

/// Why no install can start on this PC with the package at hand. Worded
/// when rendered.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum InstallBlock {
    /// The installed Atlas can't be updated to this package. The target is
    /// unknown until a package is chosen.
    Unsupported { source: String, target: Option<String> },
    /// An unfinished installation of another version must be finished
    /// first, with that version's own package.
    ResumeOther { target: String, downloads: PathBuf },
    /// The shared install record can't be read, so whether an install is
    /// still running is unknown.
    RecordUnreadable { error: String, record: PathBuf },
    /// The installation state couldn't be established.
    Unknown,
}

impl AppModel {
    /// The record of a completed install. Capture writes a partial document
    /// before the install has finished, which is not an installed PC.
    pub fn installed(&self) -> Option<&AtlasState> {
        self.atlas
            .as_ref()
            .ok()
            .and_then(|state| state.as_ref())
            .filter(|state| state.has_completed_install())
    }

    pub fn installed_version(&self) -> Option<&str> {
        self.installed()
            .and_then(|state| state.installed_version.as_deref())
            .filter(|v| !v.trim().is_empty())
            .or(match &self.install_identity {
                Ok(InstallIdentity::Installed(version)) => Some(version.as_str()),
                _ => None,
            })
    }

    /// Why no install can start with the package at hand, in words.
    #[cfg(test)]
    pub fn install_eligibility_problem(&self) -> Option<String> {
        self.install_block().map(|block| block.text(self.bundled()))
    }

    /// Why no install can start with the package at hand, if anything.
    pub fn install_block(&self) -> Option<InstallBlock> {
        self.identity_block().or_else(|| {
            self.record_problem.as_ref().map(|error| InstallBlock::RecordUnreadable {
                error: error.clone(),
                record: self.session_paths.record.clone(),
            })
        })
    }

    /// What keeps Home from starting the flow. Get ready deals with an
    /// unfinished install of another version (outside tester builds), where
    /// its package can be opened, and with an unreadable install record.
    pub fn start_block(&self) -> Option<InstallBlock> {
        self.identity_block()
            .filter(|block| self.bundled() || !matches!(block, InstallBlock::ResumeOther { .. }))
    }

    /// Judges the install identity against the package that will run. Until
    /// a release build has a package, the built-in manifest cannot rule out
    /// a newer or unfinished install; the package loaded at Get ready
    /// decides. A tester build judges against its bundled package, which
    /// the built-in manifest describes.
    fn identity_block(&self) -> Option<InstallBlock> {
        let manifest = self.manifest();
        let provisional = self.playbook.is_none() && !self.bundled();
        match &self.install_identity {
            Err(_) => Some(InstallBlock::Unknown),
            Ok(InstallIdentity::Fresh) => None,
            Ok(InstallIdentity::Resume(target, options)) => {
                // Install-Atlas.ps1 refuses any other version until this one
                // finishes. Before a package is chosen, the release on offer
                // is the one Get ready would download.
                let package_matches = if provisional {
                    match &self.release {
                        ReleaseCheck::NotChecked | ReleaseCheck::Checking => true,
                        ReleaseCheck::Ready { release } => release.version() == target,
                        ReleaseCheck::Failed => false,
                    }
                } else {
                    &manifest.version == target
                };
                if !package_matches {
                    return Some(InstallBlock::ResumeOther {
                        target: target.clone(),
                        downloads: self.env.paths.downloads(),
                    });
                }
                // The original choices are judged against the target's own package.
                let invalid = !provisional
                    && options
                        .as_ref()
                        .is_some_and(|options| iso::validate_options(manifest, options).is_err());
                invalid.then_some(InstallBlock::Unknown)
            }
            Ok(identity @ InstallIdentity::Installed(version)) => {
                let newer = releases::AtlasVersion::parse(version)
                    .zip(releases::AtlasVersion::parse(&manifest.version))
                    .is_some_and(|(installed, builtin)| installed >= builtin);
                if identity.allows(manifest) || (provisional && newer) {
                    return None;
                }
                Some(InstallBlock::Unsupported {
                    source: version.clone(),
                    target: (!provisional).then(|| manifest.version.clone()),
                })
            }
        }
    }

    pub fn original_options(&self) -> Option<&[String]> {
        match &self.install_identity {
            Ok(InstallIdentity::Resume(_, Some(options))) => Some(options),
            _ => None,
        }
    }

    /// The version an unfinished install was installing, if one is waiting.
    pub fn resume_target(&self) -> Option<&str> {
        match &self.install_identity {
            Ok(InstallIdentity::Resume(target, _)) => Some(target),
            _ => None,
        }
    }

    /// Reads the installation state again, for a tester build's "Check
    /// again", which has no update check to do it.
    pub fn recheck_installation(&mut self, cx: &mut Context<Self>) {
        self.refresh_atlas_state();
        cx.notify();
    }

    pub fn refresh_atlas_state(&mut self) {
        self.atlas = (self.env.adapters.read_atlas_state)().map_err(|e| format!("{e:#}"));
        self.install_identity = (self.env.adapters.read_install_identity)().map_err(|e| format!("{e:#}"));
        if let Err(error) = &self.install_identity {
            log::warn!("could not establish Atlas installation eligibility: {error}");
        }
    }
}
