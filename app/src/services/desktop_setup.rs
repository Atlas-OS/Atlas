//! Destination-only custom-shell handoff; normal app launches never own a desktop.
use anyhow::Result;

pub fn active() -> bool {
    if !std::env::args().any(|arg| arg == "--before-desktop") {
        return false;
    }
    super::iso::staged_settings().is_some_and(|settings| settings["mode"] == "before-desktop")
}

pub fn note_restart() -> Result<()> {
    if active() {
        windows_registry::CURRENT_USER
            .create(r"Software\AtlasOS\DesktopSetup")?
            .set_u64("RestartRequested", chrono::Utc::now().timestamp() as u64)?;
    }
    Ok(())
}
