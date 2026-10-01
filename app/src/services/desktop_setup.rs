//! Before-desktop setup: on a PC installed from Atlas media, the installing
//! user's shell (Desktop.ps1) starts the app before the desktop. Ordinary
//! launches never take over the desktop.

use anyhow::Result;

use super::iso::{self, Mode};

/// Whether this is the before-desktop app: launched with `--before-desktop`
/// as the media's own staged copy, whose setup.json asks for that mode. The
/// flag alone is not trusted.
pub fn active() -> bool {
    std::env::args_os().any(|arg| arg == "--before-desktop")
        && iso::staged_mode() == Some(Mode::BeforeDesktop)
}

/// Tells Desktop.ps1 the app is closing for a restart, so it keeps the
/// before-desktop shell for the next sign-in instead of treating the exit as
/// the user leaving.
pub fn note_restart() -> Result<()> {
    if active() {
        windows_registry::CURRENT_USER
            .create(r"Software\AtlasOS\DesktopSetup")?
            .set_u64("RestartRequested", chrono::Utc::now().timestamp() as u64)?;
    }
    Ok(())
}
