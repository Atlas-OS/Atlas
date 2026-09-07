//! Windows-facing services. Everything here is plain, synchronous Rust that the
//! UI runs on GPUI's background executor; nothing in this module touches the UI.

pub mod atlas_state;
pub mod installer;
pub mod licenses;
pub mod locale;
pub mod playbook;
pub mod releases;
pub mod requirements;
pub mod security;
pub mod session;
pub mod settings;
pub mod system;

pub mod desktop_setup;
pub mod iso;
pub mod preparation;
pub mod recovery_app;
#[cfg(test)]
pub mod test_support;
pub mod usb;
pub mod windows_release;
