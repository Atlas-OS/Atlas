//! The command line: every flag Atlas Manager accepts, read into one launch
//! description. Atlas's Windows PowerShell scripts, ISO setup and the Run
//! entries depend on these flags.

use std::ffi::OsString;
use std::path::PathBuf;

use crate::model::{Page, Step};
use crate::shell::StartAt;

/// What this launch does, from the command line.
pub enum Launch {
    /// `--export-diagnostics`, anywhere: collect diagnostics without a window.
    ExportDiagnostics,
    /// `--licenses [<file>]` as the first argument: write the license notices
    /// to the file, or open them.
    Licenses(Option<PathBuf>),
    /// Everything else opens the window.
    Window(WindowLaunch),
}

/// A launch that opens the window.
pub struct WindowLaunch {
    pub start: StartAt,
    /// `--after-preparation-restart`: the preparation Run entry.
    pub after_preparation_restart: bool,
    /// `--setup`: ISO setup, which needs an elevated window.
    pub setup: bool,
    /// `--after-install-restart`: the completion Run entry.
    pub after_install_restart: bool,
}

/// Reads the arguments that follow the program name. They are read as OS
/// strings, so a path Windows allows but Unicode does not still arrives intact.
pub fn parse(args: impl IntoIterator<Item = OsString>) -> Launch {
    let args: Vec<OsString> = args.into_iter().collect();
    let flag = |name: &str| args.iter().any(|arg| arg == name);
    if flag("--export-diagnostics") {
        return Launch::ExportDiagnostics;
    }
    if args.first().is_some_and(|arg| arg == "--licenses") {
        return Launch::Licenses(args.get(1).map(PathBuf::from));
    }
    Launch::Window(WindowLaunch {
        start: start_at(&args),
        after_preparation_restart: flag("--after-preparation-restart"),
        setup: flag("--setup"),
        after_install_restart: flag("--after-install-restart"),
    })
}

/// Where the window opens: `--page`, `--step`, `--playbook`, `--language` and
/// `--just-installed`, or a bare `.apbx` path from "Open with". app/README.md
/// lists the values.
fn start_at(args: &[OsString]) -> StartAt {
    let text = |arg: Option<&OsString>| arg.and_then(|arg| arg.to_str()).map(str::to_owned);
    let mut start = StartAt::default();
    let mut args = args.iter();
    while let Some(arg) = args.next() {
        match arg.to_str() {
            Some("--page") => start.page = text(args.next()).as_deref().and_then(Page::parse),
            Some("--step") => start.step = text(args.next()).as_deref().and_then(Step::parse),
            Some("--playbook") => start.playbook = args.next().map(PathBuf::from),
            Some("--language") => start.language = text(args.next()),
            // Atlas's new-user script opens this for accounts set up after the install.
            Some("--just-installed") => start.page = Some(Page::Installed),
            _ if arg.to_string_lossy().to_ascii_lowercase().ends_with(".apbx") => {
                start.playbook = Some(PathBuf::from(arg));
            }
            _ => {}
        }
    }
    if start.playbook.is_some() && start.page.is_none() {
        start.page = Some(Page::Install);
    }
    if cfg!(feature = "embedded-playbook")
        && let Some(path) = start.playbook.take()
    {
        log::info!("Ignoring {}: this tester build installs only its bundled Atlas package", path.display());
    }
    start
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::windows::ffi::OsStringExt;

    #[test]
    fn an_argument_that_is_not_unicode_neither_stops_the_launch_nor_loses_its_path() {
        // An unpaired surrogate: a valid Windows file name that is not valid Unicode.
        let mut name = OsString::from_wide(&[0xD800]);
        name.push(" Atlas.apbx");
        let Launch::Licenses(Some(path)) = parse([OsString::from("--licenses"), name.clone()]) else {
            panic!("--licenses with a file");
        };
        assert_eq!(path.as_os_str(), name);
        let Launch::Window(launch) = parse([name.clone(), OsString::from("--setup")]) else {
            panic!("a window launch");
        };
        assert!(launch.setup);
        if !cfg!(feature = "embedded-playbook") {
            assert_eq!(launch.start.playbook.as_deref().map(|path| path.as_os_str()), Some(name.as_os_str()));
        }
    }
}
