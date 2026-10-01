//! Atlas Manager: install and update AtlasOS from a window that feels like part of
//! Windows 11.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// The one place the Windows-only assumption is enforced; no other code needs
// a `cfg(windows)` guard.
#[cfg(not(windows))]
compile_error!("Atlas Manager builds only for Windows.");

mod assets;
mod cli;
mod environment;
mod flow;
mod i18n;
mod model;
mod pages;
mod platform;
mod services;
mod shell;
mod theme;
mod ui;

use crate::platform::application;
use gpui::{
    App, Bounds, TitlebarOptions, WindowBackgroundAppearance, WindowBounds, WindowOptions, prelude::*, px,
    size,
};

use crate::cli::Launch;
use crate::shell::Shell;

/// Removes the Run entries this launch came from once sign-in has had time
/// to start the other programs the key lists: Explorer may still be working
/// through the key, and a program it started must not write to it meanwhile
/// (see `services::preparation::RESUME_SETTLE`).
fn settle_and_clear(resume: bool, completion: bool, launched_at: std::time::Instant) {
    if !resume && !completion {
        return;
    }
    std::thread::sleep(services::preparation::RESUME_SETTLE.saturating_sub(launched_at.elapsed()));
    if resume {
        services::preparation::clear_resume();
    }
    if completion {
        services::session::clear_completion();
    }
}

/// Collects diagnostics without a window and reports where they went.
fn export_diagnostics() {
    let result = services::diagnostics::export(&services::settings::app_data_dir(), None);
    match &result {
        Ok(path) => {
            log::info!("Diagnostic export: {}", path.display());
            println!("{}", path.display());
        }
        Err(error) => {
            log::error!("Diagnostic export failed: {error:#}");
            eprintln!("{error:#}");
        }
    }
    // The release build has no console, so the path is also shown in a message box.
    services::diagnostics::report_headless_export(&result);
    if result.is_err() {
        std::process::exit(1);
    }
}

/// Writes the license notices to `path`, or opens them.
fn export_licenses(path: Option<std::path::PathBuf>) {
    let result = match path {
        Some(path) => services::licenses::write_to(&path).map_err(anyhow::Error::from),
        None => services::licenses::open(),
    };
    if let Err(error) = result {
        log::error!("Could not export license notices: {error}");
        std::process::exit(1);
    }
}

fn main() {
    let launched_at = std::time::Instant::now();
    services::diagnostics::init_logging();
    let launch = match cli::parse(std::env::args_os().skip(1)) {
        // Headless collection also works when the window cannot initialize.
        Launch::ExportDiagnostics => {
            export_diagnostics();
            return;
        }
        Launch::Licenses(path) => {
            export_licenses(path);
            return;
        }
        Launch::Window(launch) => launch,
    };
    let mut start = launch.start;
    let mut clear_resume = false;
    let mut clear_completion = false;
    if launch.after_preparation_restart {
        use services::preparation::Resume;
        let paths = services::settings::AppPaths::from_process();
        match services::preparation::resume_after_restart(&paths.settings()) {
            Resume::Wait => return,
            Resume::Abandoned => {
                settle_and_clear(true, false, launched_at);
                return;
            }
            Resume::Open => clear_resume = true,
            Resume::Unreadable => {}
        }
    }
    let before_desktop = services::desktop_setup::active();
    if before_desktop {
        start.page = Some(model::Page::Install);
        let paths = services::settings::AppPaths::from_process();
        // A tester build unpacks its bundled package once the flow is Ready.
        if !cfg!(feature = "embedded-playbook")
            && services::settings::read_from(&paths.settings()).settings.draft.is_none()
        {
            // Installation media stages Atlas.apbx beside AtlasManager.exe.
            start.playbook =
                std::env::current_exe().ok().and_then(|p| p.parent().map(|p| p.join("Atlas.apbx")));
        }
        if services::atlas_state::read().ok().flatten().is_some_and(|state| state.has_completed_install()) {
            start.page = Some(model::Page::Installed);
            start.playbook = None;
        }
    }
    if (launch.setup || launch.after_preparation_restart) && !services::system::is_elevated() {
        let launched = if launch.after_preparation_restart {
            // Let asynchronous draft recovery choose the page and package.
            services::system::relaunch_elevated()
        } else {
            services::system::relaunch_setup_elevated(start.playbook.as_deref())
        };
        match launched {
            // The elevated copy decides for itself; this launch opens no
            // window. Windows may elevate without asking, so the entry waits
            // out sign-in here rather than relying on a prompt to delay it.
            Ok(()) => {
                settle_and_clear(clear_resume, false, launched_at);
                return;
            }
            // Cancelling UAC leaves the normal window and its elevation
            // action available; the entry is removed behind it.
            Err(error) => log::warn!("Setup elevation was not completed: {error:#}"),
        }
    }
    if launch.after_install_restart {
        use services::session::Completion;
        let paths = services::settings::AppPaths::from_process().session();
        match services::session::completion_after_restart(&paths) {
            Completion::Wait => return,
            Completion::Clear => {
                settle_and_clear(clear_resume, true, launched_at);
                return;
            }
            Completion::Show => clear_completion = true,
        }
        start.page = Some(model::Page::Installed);
    }
    // Removed behind the window; a window closed sooner waits for it below.
    let settle = (clear_resume || clear_completion)
        .then(|| std::thread::spawn(move || settle_and_clear(clear_resume, clear_completion, launched_at)));

    application(false).with_assets(assets::Assets).run(move |cx: &mut App| {
        cx.bind_keys(ui::key_bindings());
        // Prompts are Fluent ContentDialogs over the window, in its theme.
        cx.set_prompt_builder(ui::content_dialog::build);

        let bounds = Bounds::centered(None, size(px(900.), px(680.)), cx);
        let options = WindowOptions {
            is_minimizable: !before_desktop,
            is_resizable: !before_desktop,
            window_bounds: Some(if before_desktop {
                WindowBounds::Fullscreen(bounds)
            } else {
                WindowBounds::Windowed(bounds)
            }),
            titlebar: Some(TitlebarOptions {
                title: Some("Atlas Manager".into()),
                appears_transparent: true,
                traffic_light_position: None,
            }),
            window_background: WindowBackgroundAppearance::MicaBackdrop,
            window_min_size: Some(size(px(700.), px(520.))),
            app_id: Some("AtlasOS.Atlas".into()),
            icon: assets::window_icon(),
            ..Default::default()
        };
        cx.open_window(options, move |window, cx| cx.new(|cx| Shell::new(start, window, cx)))
            .expect("open the Atlas Manager window");
        cx.on_window_closed(|cx, _| {
            if cx.windows().is_empty() {
                cx.quit();
            }
        })
        .detach();
        cx.activate(true);
    });
    // The window has closed. The process ends once the entries are gone, or
    // they would open Atlas again at the next sign-in.
    if let Some(settle) = settle {
        let _ = settle.join();
    }
}
