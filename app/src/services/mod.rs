//! Windows-facing services: plain synchronous Rust with no GPUI types. Pages
//! run the slow calls on GPUI's background executor.

pub mod atlas_state;
pub mod desktop_setup;
pub mod diagnostics;
mod diagnostics_redaction;
pub mod embedded;
mod files;
pub mod installer;
pub mod iso;
pub mod licenses;
pub mod locale;
pub mod playbook;
mod powershell;
pub mod preparation;
pub mod recovery_app;
mod registry;
pub mod releases;
pub mod reports;
pub mod requirements;
pub mod security;
pub mod session;
pub mod settings;
pub mod system;
#[cfg(test)]
pub mod test_support;
pub mod usb;
pub mod windows_installation;
pub mod windows_release;
