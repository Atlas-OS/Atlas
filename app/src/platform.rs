//! Windows application construction, shared by the app, probes and tests.
//! Uses gpui-pre-windows directly, without gpui-pre-platform's other OS backends.

use std::rc::Rc;

pub fn application(headless: bool) -> gpui::Application {
    let platform =
        gpui_windows::WindowsPlatform::new(headless).expect("failed to initialise the Windows platform");
    gpui::Application::with_platform(Rc::new(platform))
}
