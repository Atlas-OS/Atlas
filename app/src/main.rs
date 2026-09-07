//! Atlas Manager: install and update AtlasOS from a window that feels like part of
//! Windows 11.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod assets;
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
    App, Bounds, KeyBinding, TitlebarOptions, WindowBackgroundAppearance, WindowBounds, WindowOptions,
    prelude::*, px, size,
};

use crate::shell::{Shell, StartAt};
use crate::ui::actions::{FocusNext, FocusPrevious, RadioNext, RadioPrevious};

/// `atlas [--page home|install|iso|updates|settings|installed] [--step options|security|checks|install]
/// [--playbook <file.apbx>] [--language <tag>] [--just-installed]`. A bare `.apbx` argument (from
/// "Open with") also works. `--language` (or `ATLAS_LANGUAGE`) outranks the language setting, for review.
fn start_at() -> StartAt {
    let mut start = StartAt::default();
    let mut args = std::env::args().skip(1);
    while let Some(flag) = args.next() {
        match flag.as_str() {
            "--page" => start.page = args.next().as_deref().and_then(model::Page::parse),
            "--step" => start.step = args.next().as_deref().and_then(model::Step::parse),
            "--playbook" => start.playbook = args.next().map(std::path::PathBuf::from),
            "--language" => start.language = args.next(),
            // Opened by the payload's first-logon setup after the install's restart.
            "--just-installed" => start.page = Some(model::Page::Installed),
            other if other.to_ascii_lowercase().ends_with(".apbx") => {
                start.playbook = Some(std::path::PathBuf::from(other));
            }
            _ => {}
        }
    }
    if start.playbook.is_some() && start.page.is_none() {
        start.page = Some(model::Page::Install);
    }
    start
}

fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("warn")).init();
    let mut arguments = std::env::args_os().skip(1);
    if arguments.next().as_deref() == Some(std::ffi::OsStr::new("--licenses")) {
        let result = match arguments.next() {
            Some(path) => {
                services::licenses::write_to(std::path::Path::new(&path)).map_err(anyhow::Error::from)
            }
            None => services::licenses::open(),
        };
        if let Err(error) = result {
            log::error!("Could not export license notices: {error}");
            std::process::exit(1);
        }
        return;
    }
    let mut start = start_at();
    let before_desktop = services::desktop_setup::active();
    if before_desktop {
        start.page = Some(model::Page::Install);
        let paths = services::settings::AppPaths::from_process();
        if services::settings::load_from(&paths.settings()).settings.draft.is_none() {
            start.playbook =
                std::env::current_exe().ok().and_then(|p| p.parent().map(|p| p.join("Atlas.apbx")));
        }
        if services::atlas_state::read().ok().flatten().is_some_and(|state| state.has_completed_install()) {
            start.page = Some(model::Page::Installed);
            start.playbook = None;
        }
    }
    if std::env::args().any(|arg| arg == "--after-install-restart") {
        let paths = services::settings::AppPaths::from_process().session();
        if !services::session::completion_after_restart(&paths).unwrap_or(false) {
            return;
        }
        start.page = Some(model::Page::Installed);
    }

    application(false).with_assets(assets::Assets).run(move |cx: &mut App| {
        // Keyboard traversal is not built into GPUI; the root handles these.
        cx.bind_keys([
            KeyBinding::new("tab", FocusNext, None),
            KeyBinding::new("shift-tab", FocusPrevious, None),
            KeyBinding::new("down", RadioNext, Some("RadioGroup")),
            KeyBinding::new("right", RadioNext, Some("RadioGroup")),
            KeyBinding::new("up", RadioPrevious, Some("RadioGroup")),
            KeyBinding::new("left", RadioPrevious, Some("RadioGroup")),
        ]);

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
        let start = start.clone();
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
}
