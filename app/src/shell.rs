//! The window: title bar and one content layer over Mica. The app has a single
//! destination (Home); every other page offers a way back to it, so there is
//! no navigation pane.
//!
//! The shell also owns what is window-wide: keyboard traversal (Tab and
//! Shift+Tab), the theme (appearance, contrast, text size), and the close
//! guard that keeps a running install from being abandoned unknowingly.

use std::cell::Cell;
use std::path::PathBuf;
use std::sync::atomic::Ordering;
use std::time::{Duration, Instant};

use gpui::{
    Context, Div, Entity, FocusHandle, IntoElement, ParentElement, Pixels, PromptLevel, Render, ScrollHandle,
    Styled, Subscription, Window, WindowBackgroundAppearance, div, prelude::*, px,
};

use crate::i18n::{Localization, describe};
use crate::model::{AppModel, CloseGuard, ModelEvent, Page, RestoreStatus, Step};
use crate::pages::{
    CONTENT_MAX_WIDTH, HomePage, InstallPage, InstalledPage, InstallingPage, IsoPage, PAGE_PADDING,
    ReportPage, SettingsPage, back_arrow,
};
use crate::services::system::links;
use crate::t;
use crate::theme::{ActiveTheme, Appearance, FONT_TEXT, Theme};
use crate::ui::actions::{FocusNext, FocusPrevious, NavigateBack};
use crate::ui::{
    Button, InfoBar, ScrollbarState, Severity, TitleBar, Typography, a11y_text, dismiss_button, focus_reveal,
    nested_scrollbar, page_keyboard_scrolling,
};

/// The share of the window's height the app-wide notices may take. Past it
/// they scroll on their own, so very large text never leaves the page
/// without room.
const NOTICES_MAX_SHARE: f32 = 0.4;

/// Where the window opens, from the command line and the launch state.
#[derive(Clone, Debug, Default)]
pub struct StartAt {
    pub page: Option<Page>,
    pub step: Option<Step>,
    /// An .apbx to unpack on launch.
    pub playbook: Option<PathBuf>,
    /// A language tag that outranks the setting (`--language`), for review.
    pub language: Option<String>,
}

pub struct Shell {
    model: Entity<AppModel>,
    home: Entity<HomePage>,
    iso: Entity<IsoPage>,
    install: Entity<InstallPage>,
    installing: Entity<InstallingPage>,
    installed: Entity<InstalledPage>,
    settings: Entity<SettingsPage>,
    report: Entity<ReportPage>,
    system_appearance: Appearance,
    focus_handle: FocusHandle,
    /// The user confirmed closing while an install runs.
    close_confirmed: bool,
    /// Whether a restart countdown was running last time the model changed,
    /// to flash the taskbar button when one starts unseen.
    countdown_seen: bool,
    /// The dialog asking to restart over other people's sessions is open.
    asking_about_sessions: bool,
    /// The backdrop last handed to Windows; the platform call is not cheap
    /// and not guarded, so it is made only on a change.
    applied_backdrop: Cell<Option<WindowBackgroundAppearance>>,
    notices_scroll: ScrollHandle,
    notices_scrollbar: ScrollbarState,
    _subscriptions: Vec<Subscription>,
}

impl Shell {
    pub fn new(start: StartAt, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let language = start.language.clone();
        let model = cx.new(|cx| AppModel::new(language, cx));
        model.update(cx, |model, cx| model.apply_start(start.page, start.step, start.playbook, cx));
        let system_appearance = Appearance::from_window(window.appearance());
        {
            let (theme, localization) = {
                let model = model.read(cx);
                (
                    Theme::resolve(model.settings.theme, system_appearance, &model.accessibility),
                    model.localization.clone(),
                )
            };
            cx.set_global(theme);
            cx.set_global(localization);
        }

        let focus_handle = cx.focus_handle();
        window.focus(&focus_handle, cx);

        model.update(cx, |model, _| model.set_window_active(window.is_window_active()));
        let subscriptions = vec![
            cx.observe_in(&model, window, |this, model, window, cx| {
                // A countdown that starts while the window is behind others
                // flashes its taskbar button until the user comes back.
                let counting = model.read(cx).restart_countdown().is_some();
                if counting
                    && !std::mem::replace(&mut this.countdown_seen, true)
                    && !window.is_window_active()
                {
                    crate::services::system::flash_until_foreground(window);
                }
                this.countdown_seen = counting;
                if model.read(cx).restart_confirmation().is_some() && !this.asking_about_sessions {
                    // After the event that held the restart, such as another dialog's answer.
                    cx.defer_in(window, |this, window, cx| this.ask_about_other_sessions(window, cx));
                }
                cx.notify();
            }),
            cx.subscribe_in(&model, window, |this, _, event: &ModelEvent, window, cx| match event {
                ModelEvent::ThemeChanged => this.apply_theme(cx),
                ModelEvent::LanguageChanged => this.apply_language(cx),
                // Get ready's live status says what happened; the taskbar
                // button brings the user back to it.
                ModelEvent::NeedsAttention => {
                    if !window.is_window_active() {
                        crate::services::system::flash_until_foreground(window);
                    }
                }
            }),
            cx.observe_window_appearance(window, |this, window, cx| {
                this.system_appearance = Appearance::from_window(window.appearance());
                this.model.update(cx, |model, cx| model.refresh_accessibility(cx));
                this.apply_theme(cx);
            }),
            cx.observe_window_activation(window, |this, window, cx| {
                // Ease of Access and language settings change outside the
                // app; re-read them whenever the user comes back to the window.
                let active = window.is_window_active();
                this.model.update(cx, |model, _| model.set_window_active(active));
                if active {
                    this.model.update(cx, |model, cx| {
                        model.refresh_accessibility(cx);
                        model.refresh_language(cx);
                        // Back from Windows Security, a reminder names what is still off.
                        model.refresh_protection(cx);
                    });
                }
                // Chrome and the completion backdrop draw differently for
                // an inactive window, whether or not the model changed.
                cx.notify();
            }),
        ];

        let this = cx.entity().downgrade();
        window.on_window_should_close(cx, move |window, cx| {
            this.update(cx, |shell, cx| shell.should_close(window, cx)).unwrap_or(true)
        });

        let shell = Self {
            home: cx.new(|cx| HomePage::new(model.clone(), cx)),
            iso: cx.new(|cx| IsoPage::new(model.clone(), cx)),
            install: cx.new(|cx| InstallPage::new(model.clone(), cx)),
            installing: cx.new(|cx| InstallingPage::new(model.clone(), cx)),
            installed: cx.new(|cx| InstalledPage::new(model.clone(), cx)),
            settings: cx.new(|cx| SettingsPage::new(model.clone(), cx)),
            report: cx.new(|cx| ReportPage::new(model.clone(), cx)),
            model,
            system_appearance,
            focus_handle,
            close_confirmed: false,
            countdown_seen: false,
            asking_about_sessions: false,
            applied_backdrop: Cell::new(None),
            notices_scroll: ScrollHandle::new(),
            notices_scrollbar: ScrollbarState::new(),
            _subscriptions: subscriptions,
        };
        shell.sync_backdrop(window, cx);
        // A preview can open with a restart already held.
        cx.defer_in(window, |this, window, cx| this.ask_about_other_sessions(window, cx));
        shell
    }

    /// Other people are signed in, so a restart would close their apps:
    /// the user restarts anyway or keeps the PC running. Don't restart is
    /// the safe answer, and Escape chooses it.
    fn ask_about_other_sessions(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(confirmation) = self.model.read(cx).restart_confirmation().cloned() else { return };
        if self.asking_about_sessions || window.has_active_prompt() {
            return;
        }
        self.asking_about_sessions = true;
        let title = match confirmation.people.len() {
            1 => t!("restart-other-title"),
            _ => t!("restart-others-title"),
        };
        let message =
            t!("restart-others-message", names = crate::i18n::describe::join_and(&confirmation.people));
        let (keep, restart) = (t!("restart-others-keep"), t!("restart-others-restart"));
        let answer = window.prompt(
            PromptLevel::Warning,
            &title,
            Some(&message),
            &[keep.as_str(), restart.as_str()],
            cx,
        );
        cx.spawn_in(window, async move |this, cx| {
            let answer = answer.await;
            this.update_in(cx, |shell, _, cx| {
                shell.asking_about_sessions = false;
                shell.model.update(cx, |model, cx| match answer {
                    Ok(1) => model.confirm_restart(cx),
                    _ => model.decline_restart_confirmation(cx),
                });
            })
            .ok();
        })
        .detach();
    }

    /// Lets the window close only once the user knows what closing does to the
    /// job under way (see [`CloseGuard`]).
    fn should_close(&mut self, window: &mut Window, cx: &mut Context<Self>) -> bool {
        // A dialog is already asking; it answers, not a second one.
        if window.has_active_prompt() {
            return false;
        }
        let state = self.model.read(cx);
        // Closing ends desktop setup, so before the desktop it waits until nothing runs.
        if state.before_desktop && state.locked() {
            return false;
        }
        if self.close_confirmed {
            // A close already confirmed waits for the launch hand-off.
            return !state.launching();
        }
        let guard = state.close_guard();
        let usb = state.usb_busy;
        // A dialog opens over the window, so a minimised or hidden window
        // comes back first (closing from the taskbar, for example).
        if !matches!(guard, CloseGuard::None | CloseGuard::Wait) && !window.is_window_active() {
            window.activate_window();
        }
        let (title, message) = match guard {
            CloseGuard::None => return true,
            CloseGuard::ProtectionOff => {
                self.confirm_closing_with_protection_off(window, cx);
                return false;
            }
            // Saving a preparation restart takes a moment; then Windows restarts.
            CloseGuard::Wait => return false,
            CloseGuard::Restart => {
                self.confirm_restart_before_closing(window, cx);
                return false;
            }
            CloseGuard::WindowsUpdateAccess => {
                self.confirm_put_back_before_closing(window, cx);
                return false;
            }
            CloseGuard::Preparation => {
                let (title, message) = (t!("prepare-close-title"), t!("prepare-close-message"));
                let stop = |m: &mut AppModel| m.preparation_cancel.store(true, Ordering::Relaxed);
                self.offer_stop(&title, &message, &t!("prepare-stop"), stop, window, cx);
                return false;
            }
            CloseGuard::Media => {
                let (title, message) = if usb {
                    (t!("usb-close-title"), t!("usb-working"))
                } else {
                    (t!("iso-close-title"), t!("iso-close-message"))
                };
                let stop = |m: &mut AppModel| m.iso_cancel.store(true, Ordering::Relaxed);
                self.offer_stop(&title, &message, &t!("iso-cancel"), stop, window, cx);
                return false;
            }
            CloseGuard::PreparingInstall => {
                (t!("window-close-preparing-title"), t!("window-close-preparing-message"))
            }
            CloseGuard::Install => {
                // Only an open window restarts the PC when installing ends.
                let restart = state
                    .session
                    .as_ref()
                    .map_or(state.settings.restart_after_install, |session| session.request.restart);
                let message =
                    if restart { t!("window-close-message-restart") } else { t!("window-close-message") };
                (t!("window-close-title"), message)
            }
        };
        let (keep, close) = (t!("window-close-keep"), t!("window-close-close"));
        let answer =
            window.prompt(PromptLevel::Warning, &title, Some(&message), &[keep.as_str(), close.as_str()], cx);
        cx.spawn_in(window, async move |this, cx| {
            if answer.await == Ok(1) {
                this.update_in(cx, |shell, window, cx| {
                    // Still before the launch: stop it, so closing starts
                    // nothing. If the installer started while the question
                    // was open, ask again in the words for that.
                    if guard == CloseGuard::PreparingInstall
                        && !shell.model.update(cx, |model, cx| model.abandon_preparing(cx))
                        && !shell.should_close(window, cx)
                    {
                        return;
                    }
                    shell.close_after_launch(window, cx);
                })
                .ok();
            }
        })
        .detach();
        false
    }

    /// Windows Update is turned on for an update that hasn't changed Windows
    /// yet. Closing puts the settings back first, then closes as any other
    /// close would; if that failed, it says why and leaves the choice to close.
    fn confirm_put_back_before_closing(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let (title, message) =
            (t!("window-close-update-access-title"), t!("window-close-update-access-message"));
        let (keep, close) = (t!("iso-keep-open"), t!("window-close-put-back"));
        let answer =
            window.prompt(PromptLevel::Warning, &title, Some(&message), &[keep.as_str(), close.as_str()], cx);
        cx.spawn_in(window, async move |this, cx| {
            if answer.await != Ok(1) {
                return;
            }
            let (finished, mut put_back) = futures::channel::oneshot::channel();
            let mut finished = Some(finished);
            this.update(cx, |shell, cx| {
                shell.model.update(cx, |model, cx| {
                    model.restore_before_closing(
                        move |_, done, _| {
                            if let Some(finished) = finished.take() {
                                let _ = finished.send(done);
                            }
                        },
                        cx,
                    )
                })
            })
            .ok();
            match (&mut put_back).await {
                // Anything else closing asks about, such as protection left
                // off, is asked now.
                Ok(true) => {
                    this.update_in(cx, |shell, window, cx| {
                        if shell.should_close(window, cx) {
                            shell.close_after_launch(window, cx);
                        }
                    })
                    .ok();
                }
                Ok(false) => {
                    this.update_in(cx, |shell, window, cx| {
                        shell.confirm_closing_without_put_back(window, cx)
                    })
                    .ok();
                }
                Err(_) => {}
            }
        })
        .detach();
    }

    /// Putting the settings back failed: says why, and closes only if the
    /// user still wants to.
    fn confirm_closing_without_put_back(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let cause = match &self.model.read(cx).restore_status {
            RestoreStatus::Failed(error) => describe::restore_failure_cause(error),
            _ => return,
        };
        let title = t!("window-close-put-back-failed-title");
        let message = match cause {
            Some(cause) => format!("{cause}\n\n{}", t!("window-close-put-back-failed-message")),
            None => t!("window-close-put-back-failed-message"),
        };
        let (keep, close) = (t!("window-close-keep"), t!("window-close-close"));
        let answer =
            window.prompt(PromptLevel::Warning, &title, Some(&message), &[keep.as_str(), close.as_str()], cx);
        cx.spawn_in(window, async move |this, cx| {
            if answer.await == Ok(1) {
                this.update_in(cx, |shell, window, cx| shell.close_after_launch(window, cx)).ok();
            }
        })
        .detach();
    }

    /// Offers to stop a job that stops at a safe point. The window stays open
    /// either way; it can be closed once the job has ended.
    fn offer_stop(
        &mut self,
        title: &str,
        message: &str,
        stop_label: &str,
        stop: fn(&mut AppModel),
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let keep = t!("iso-keep-open");
        let answer =
            window.prompt(PromptLevel::Warning, title, Some(message), &[keep.as_str(), stop_label], cx);
        let model = self.model.clone();
        cx.spawn(async move |_, cx| {
            if answer.await == Ok(1) {
                model.update(cx, |model, cx| {
                    stop(model);
                    cx.notify();
                });
            }
        })
        .detach();
    }

    /// Closes the window once a confirmed close may go ahead. The process
    /// ends with its last window, and a launch still on its worker (the
    /// installer starting, its completion window being armed) would end with
    /// it, so the close waits for the launch to answer, for a while at most.
    fn close_after_launch(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        const LAUNCH_WAIT: Duration = Duration::from_secs(15);
        self.close_confirmed = true;
        if !self.model.read(cx).launching() {
            window.remove_window();
            return;
        }
        cx.spawn_in(window, async move |this, cx| {
            let deadline = Instant::now() + LAUNCH_WAIT;
            loop {
                let launching =
                    this.update_in(cx, |shell, _, cx| shell.model.read(cx).launching()).unwrap_or(false);
                if !launching || Instant::now() >= deadline {
                    break;
                }
                cx.background_executor().timer(Duration::from_millis(50)).await;
            }
            this.update_in(cx, |_, window, _| window.remove_window()).ok();
        })
        .detach();
    }

    /// Atlas keeps the restart countdown, so closing the window would drop
    /// the restart without a word. The user keeps the window, restarts now,
    /// or closes knowing the PC must be restarted by hand. The countdown is
    /// held while the prompt is open and starts again if the window stays.
    fn confirm_restart_before_closing(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let (title, message) = (t!("window-close-restart-title"), t!("window-close-restart-message"));
        let (keep, restart, close) =
            (t!("window-close-keep"), t!("restart-now"), t!("window-close-restart-close"));
        self.model.update(cx, |model, _| model.hold_restart());
        let answer = window.prompt(
            PromptLevel::Warning,
            &title,
            Some(&message),
            &[keep.as_str(), restart.as_str(), close.as_str()],
            cx,
        );
        cx.spawn_in(window, async move |this, cx| {
            let answer = answer.await;
            this.update_in(cx, |shell, window, cx| match answer {
                Ok(1) => shell.model.update(cx, |model, cx| model.restart_now(cx)),
                Ok(2) => {
                    shell.model.update(cx, |model, cx| model.cancel_restart(cx));
                    shell.close_after_launch(window, cx);
                }
                // Keep open, or the prompt went away without an answer.
                _ => shell.model.update(cx, |model, cx| model.resume_restart(cx)),
            })
            .ok();
        })
        .detach();
    }

    /// Closing during a setup with protection switches read off would leave
    /// them off. The user keeps the window, opens Windows Security to turn
    /// them back on, or closes knowing the setup continues when Atlas opens
    /// again.
    fn confirm_closing_with_protection_off(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let Some(reminder) = self.model.read(cx).protection_left_off() else { return };
        let names: Vec<String> = reminder.switches.iter().map(|switch| switch.title()).collect();
        let title = t!("window-close-protection-title");
        let message =
            t!("window-close-protection-message", switches = crate::i18n::describe::join_and(&names));
        let (keep, open, close) =
            (t!("window-close-keep"), t!("common-open-windows-security"), t!("window-close-close"));
        let answer = window.prompt(
            PromptLevel::Warning,
            &title,
            Some(&message),
            &[keep.as_str(), open.as_str(), close.as_str()],
            cx,
        );
        cx.spawn_in(window, async move |this, cx| {
            let answer = answer.await;
            this.update_in(cx, |shell, window, cx| match answer {
                Ok(1) => cx.open_url(links::WINDOWS_SECURITY_PROTECTION),
                Ok(2) => shell.close_after_launch(window, cx),
                _ => {}
            })
            .ok();
        })
        .detach();
    }

    /// Escape does what the page's back arrow does, and nothing where no arrow is drawn.
    fn navigate_back(&mut self, cx: &mut Context<Self>) {
        // Escape inside the USB panel goes back there first, as its Back button does.
        if self.model.read(cx).page == Page::Iso && self.iso.update(cx, |iso, cx| iso.usb_back(cx)) {
            return;
        }
        if let Some(target) = back_arrow(self.model.read(cx)) {
            self.model.update(cx, |model, cx| model.navigate(target, cx));
        }
    }

    /// The catalog has already been swapped by the model; every view
    /// re-renders from semantic state, so nothing else needs resetting.
    fn apply_language(&mut self, cx: &mut Context<Self>) {
        let localization = self.model.read(cx).localization.clone();
        cx.set_global(localization);
        cx.refresh_windows();
        cx.notify();
    }

    fn apply_theme(&mut self, cx: &mut Context<Self>) {
        let model = self.model.read(cx);
        let theme = Theme::resolve(model.settings.theme, self.system_appearance, &model.accessibility);
        cx.set_global(theme);
        cx.refresh_windows();
        cx.notify();
    }

    /// Mica only looks right when DWM's tint and our text colours agree, so
    /// the backdrop is dropped to a solid fill when the user overrides the
    /// system appearance (or a contrast theme is active).
    fn sync_backdrop(&self, window: &mut Window, cx: &mut Context<Self>) {
        let wanted = if cx.theme().mica {
            WindowBackgroundAppearance::MicaBackdrop
        } else {
            WindowBackgroundAppearance::Opaque
        };
        if self.applied_backdrop.get() != Some(wanted) {
            self.applied_backdrop.set(Some(wanted));
            window.set_background_appearance(wanted);
        }
    }
}

impl Render for Shell {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        self.sync_backdrop(window, cx);
        let theme = cx.theme();
        // The type ramp is in rems; the Ease of Access text size scales it,
        // and the display sizes follow it as WinUI's do.
        window.set_rem_size(px(16. * theme.text_scale));
        crate::ui::set_text_scale(theme.text_scale);
        // Screen readers read the window in the language it's shown in.
        let tag = cx.global::<Localization>().primary().tag;
        window.set_accessibility_language(Some(tag.into()));
        let (page, installing, preview_notice, settings_reachable, before_desktop, may_exit_setup) = {
            let state = self.model.read(cx);
            (
                state.page,
                state.install_in_progress(),
                state.preview_notice().map(|locale| locale.native_name),
                state.can_navigate(Page::Settings),
                state.before_desktop,
                // Leaving drops a restart countdown as closing would.
                !state.locked() && !state.restart_cancellable(),
            )
        };
        let model = self.model.clone();
        // Script-specific font fallbacks for the current language, inherited
        // by every element; families set lower down override only the family.
        let font_fallbacks = cx.global::<Localization>().font_fallbacks();

        div()
            .id("atlas-root")
            .track_focus(&self.focus_handle)
            .on_action(|_: &FocusNext, window, cx| {
                window.focus_next(cx);
                focus_reveal::request(window, cx);
            })
            .on_action(|_: &FocusPrevious, window, cx| {
                window.focus_prev(cx);
                focus_reveal::request(window, cx);
            })
            .on_action(cx.listener(|this, _: &NavigateBack, _, cx| this.navigate_back(cx)))
            .map(page_keyboard_scrolling)
            .size_full()
            .flex()
            .flex_col()
            .when(!theme.mica, |this| this.bg(theme.solid_background))
            .text_color(theme.text_primary)
            .font(gpui::Font {
                family: FONT_TEXT.into(),
                features: gpui::FontFeatures::default(),
                fallbacks: font_fallbacks,
                weight: gpui::FontWeight::NORMAL,
                style: gpui::FontStyle::Normal,
            })
            .type_body()
            .child(TitleBar::new(t!("app-name")).when(
                !before_desktop && page != Page::Installed && settings_reachable,
                |bar| {
                    // Settings cannot open during an install, a preparation or
                    // an ISO job; the gear goes with them.
                    bar.settings(page == Page::Settings, move |_, _, cx| {
                        model.update(cx, |model, cx| {
                            let target =
                                if model.page == Page::Settings { Page::Home } else { Page::Settings };
                            model.navigate(target, cx);
                        })
                    })
                },
            ))
            .when(before_desktop && page != Page::Installed, |this| {
                this.child(
                    div()
                        .px(px(24.))
                        .py(px(12.))
                        .flex()
                        .items_center()
                        .gap(px(16.))
                        .child(
                            div().flex_1().min_w_0().whitespace_normal().child(a11y_text(
                                "desktop-setup-description",
                                t!("desktop-setup-description"),
                            )),
                        )
                        .child(
                            div().flex_shrink_0().child(
                                Button::new("desktop-exit", t!("desktop-setup-exit"))
                                    .disabled(!may_exit_setup)
                                    .on_click(|_, window, _| window.remove_window()),
                            ),
                        ),
                )
            })
            .child(
                div()
                    .flex()
                    .flex_1()
                    .min_h_0()
                    .mx(px(8.))
                    .rounded_t(px(8.))
                    .bg(theme.layer_fill)
                    .border_t_1()
                    .border_l_1()
                    .border_r_1()
                    .border_color(theme.layer_stroke)
                    .overflow_hidden()
                    .flex_col()
                    .when_some(
                        self.app_notices(
                            page,
                            preview_notice,
                            settings_reachable,
                            window.viewport_size().height * NOTICES_MAX_SHARE,
                        ),
                        |this, notices| this.child(notices),
                    )
                    .child(if installing {
                        // One thing at a time: the whole layer is the install.
                        self.installing.clone().into_any_element()
                    } else {
                        match page {
                            Page::Home => self.home.clone().into_any_element(),
                            Page::Iso => self.iso.clone().into_any_element(),
                            Page::Install => self.install.clone().into_any_element(),
                            Page::Settings => self.settings.clone().into_any_element(),
                            Page::Report => self.report.clone().into_any_element(),
                            Page::Installed => self.installed.clone().into_any_element(),
                        }
                    }),
            )
    }
}

impl Shell {
    /// What holds for the whole app, inset at the top of the content: a
    /// tester build, which installs nothing else, and a preview translation,
    /// with the two ways out of it until the user dismisses it for this
    /// language or picks English. They stay above every page, at most
    /// `max_height` tall.
    fn app_notices(
        &self,
        page: Page,
        preview_language: Option<&'static str>,
        settings_reachable: bool,
        max_height: Pixels,
    ) -> Option<Div> {
        let rc = crate::services::embedded::rc_id().map(|rc_id| {
            InfoBar::new(Severity::Informational, "", t!("rc-banner", release = rc_id)).id("rc-banner")
        });
        let preview = preview_language.map(|language| {
            let (switch, change, dismiss) = (self.model.clone(), self.model.clone(), self.model.clone());
            let actions = div()
                .flex()
                .flex_wrap()
                .gap(px(8.))
                .child(
                    Button::new("preview-notice-english", t!("preview-notice-switch"))
                        .hyperlink()
                        .compact()
                        .on_click(move |_, _, cx| switch.update(cx, |model, cx| model.switch_to_english(cx))),
                )
                // Settings is out of reach while an install or a job runs, and
                // needs no link while it shows; English stays one click away.
                .when(settings_reachable && page != Page::Settings, |this| {
                    this.child(
                        Button::new("preview-notice-language", t!("preview-notice-language"))
                            .hyperlink()
                            .compact()
                            .on_click(move |_, _, cx| {
                                change.update(cx, |model, cx| model.navigate(Page::Settings, cx))
                            }),
                    )
                });
            InfoBar::new(Severity::Informational, "", t!("preview-notice", language = language))
                .id("preview-notice")
                .action(actions)
                .close_button(dismiss_button("preview-notice-dismiss", move |_, _, cx| {
                    dismiss.update(cx, |model, cx| model.dismiss_preview_notice(cx))
                }))
        });
        if rc.is_none() && preview.is_none() {
            return None;
        }
        // In the page's column, so the bars line up with the content below.
        Some(
            div()
                .relative()
                .flex_shrink_0()
                .child(
                    div()
                        .id("app-notices")
                        .max_h(max_height)
                        .overflow_y_scroll()
                        .track_scroll(&self.notices_scroll)
                        .flex()
                        // The column keeps its own height, so what is past the cap scrolls.
                        .items_start()
                        .justify_center()
                        .child(
                            div()
                                .w_full()
                                .max_w(px(CONTENT_MAX_WIDTH))
                                .px(px(PAGE_PADDING))
                                .pt(px(16.))
                                .flex()
                                .flex_col()
                                .gap(px(8.))
                                .children(rc)
                                .children(preview),
                        ),
                )
                .child(nested_scrollbar(&self.notices_scroll, &self.notices_scrollbar)),
        )
    }
}
