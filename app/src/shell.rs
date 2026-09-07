//! The window: title bar and one content layer over Mica. The app has a single
//! destination (Home); the install flow and Settings open from it and offer a
//! way back, so there is no navigation pane.
//!
//! The shell also owns what is window-wide: keyboard traversal (Tab and
//! Shift+Tab), the theme (appearance, contrast, text size), and the close
//! guard that keeps a running install from being abandoned unknowingly.

use gpui::{
    Context, Entity, FocusHandle, IntoElement, ParentElement, PromptLevel, Render, Styled, Subscription,
    Window, WindowBackgroundAppearance, div, prelude::*, px,
};

use crate::i18n::Localization;
use crate::model::{AppModel, ModelEvent, Page};
use crate::pages::{HomePage, InstallPage, InstalledPage, InstallingPage, IsoPage, SettingsPage};
use crate::t;
use crate::theme::{ActiveTheme, Appearance, FONT_TEXT, Theme};
use crate::ui::actions::{FocusNext, FocusPrevious};
use crate::ui::{BODY_LINE_HEIGHT, Button, Icon, TitleBar, Typography, icon_in_line};

/// Where the window opens. Set from the command line for review and testing.
#[derive(Clone, Debug, Default)]
pub struct StartAt {
    pub page: Option<Page>,
    pub step: Option<crate::model::Step>,
    /// An .apbx to unpack on launch.
    pub playbook: Option<std::path::PathBuf>,
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
    system_appearance: Appearance,
    focus_handle: FocusHandle,
    /// The user confirmed closing while an install runs.
    close_confirmed: bool,
    /// The backdrop last handed to Windows; the platform call is not cheap
    /// and not guarded, so it is made only on a change.
    applied_backdrop: std::cell::Cell<Option<WindowBackgroundAppearance>>,
    _subscriptions: Vec<Subscription>,
}

impl Shell {
    pub fn new(start: StartAt, window: &mut Window, cx: &mut Context<Self>) -> Self {
        let language = start.language.clone();
        let model = cx.new(|cx| AppModel::new(language, cx));
        model.update(cx, |model, cx| {
            if let Some(page) = start.page {
                if page == Page::Install && !model.flow.active {
                    model.start_flow_at(crate::model::Step::Ready, cx);
                }
                model.navigate(page, cx);
            }
            if let Some(step) = start.step {
                model.start_flow_at(step, cx);
            }
            if let Some(path) = start.playbook.clone() {
                model.load_playbook_file(path, cx);
            }
        });
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

        let subscriptions = vec![
            cx.observe(&model, |_, _, cx| cx.notify()),
            cx.subscribe(&model, |this, _, event: &ModelEvent, cx| match event {
                ModelEvent::ThemeChanged => this.apply_theme(cx),
                ModelEvent::LanguageChanged => this.apply_language(cx),
            }),
            cx.observe_window_appearance(window, |this, window, cx| {
                this.system_appearance = Appearance::from_window(window.appearance());
                this.model.update(cx, |model, cx| model.refresh_accessibility(cx));
                this.apply_theme(cx);
            }),
            cx.observe_window_activation(window, |this, window, cx| {
                // Ease of Access and language settings change outside the
                // app; re-read them whenever the user comes back to the window.
                if window.is_window_active() {
                    this.model.update(cx, |model, cx| {
                        model.refresh_accessibility(cx);
                        model.refresh_language(cx);
                    });
                }
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
            model,
            system_appearance,
            focus_handle,
            close_confirmed: false,
            applied_backdrop: std::cell::Cell::new(None),
            _subscriptions: subscriptions,
        };
        shell.sync_backdrop(window, cx);
        shell
    }

    /// Closing while an install runs is allowed, but only knowingly: the
    /// install carries on in the background and the app can be reopened to
    /// follow it, and the user is told so first.
    fn should_close(&mut self, window: &mut Window, cx: &mut Context<Self>) -> bool {
        if self.model.read(cx).before_desktop && self.model.read(cx).locked() {
            return false;
        }
        if self.model.read(cx).preparation.busy() {
            let response = window.prompt(
                PromptLevel::Warning,
                &t!("prepare-title"),
                Some(&t!("prepare-stop-description")),
                &[t!("iso-keep-open").as_str(), t!("prepare-stop").as_str()],
                cx,
            );
            let model = self.model.clone();
            cx.spawn(async move |_, cx| {
                if response.await == Ok(1) {
                    model.update(cx, |m, cx| {
                        m.preparation_cancel.store(true, std::sync::atomic::Ordering::Relaxed);
                        cx.notify();
                    });
                }
            })
            .detach();
            return false;
        }
        if self.model.read(cx).iso_busy {
            let title = if self.model.read(cx).usb_busy { t!("usb-title") } else { t!("iso-close-title") };
            let message =
                if self.model.read(cx).usb_busy { t!("usb-working") } else { t!("iso-close-message") };
            let keep = t!("iso-keep-open");
            let cancel = t!("iso-cancel");
            let response = window.prompt(
                PromptLevel::Warning,
                &title,
                Some(&message),
                &[keep.as_str(), cancel.as_str()],
                cx,
            );
            let model = self.model.clone();
            cx.spawn(async move |_, cx| {
                if response.await == Ok(1) {
                    model.update(cx, |m, cx| {
                        m.iso_cancel.store(true, std::sync::atomic::Ordering::Relaxed);
                        cx.notify();
                    });
                }
            })
            .detach();
            return false;
        }
        if self.close_confirmed || !self.model.read(cx).locked() {
            return true;
        }
        let (title, message, keep, close) = (
            t!("window-close-title"),
            t!("window-close-message"),
            t!("window-close-keep"),
            t!("window-close-close"),
        );
        let answer =
            window.prompt(PromptLevel::Warning, &title, Some(&message), &[keep.as_str(), close.as_str()], cx);
        cx.spawn_in(window, async move |this, cx| {
            if answer.await == Ok(1) {
                this.update_in(cx, |shell, window, _cx| {
                    shell.close_confirmed = true;
                    window.remove_window();
                })
                .ok();
            }
        })
        .detach();
        false
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
        // The type ramp is in rems; the Ease of Access text size scales it.
        window.set_rem_size(px(16. * theme.text_scale));
        let (page, installing, preview_notice) = {
            let state = self.model.read(cx);
            (state.page, state.install_in_progress(), state.preview_notice().map(|locale| locale.native_name))
        };
        let model = self.model.clone();
        // Script-specific font fallbacks for the current language, inherited
        // by every element; families set lower down override only the family.
        let font_fallbacks = cx.global::<Localization>().font_fallbacks();

        div()
            .id("atlas-root")
            .track_focus(&self.focus_handle)
            .on_action(|_: &FocusNext, window, cx| window.focus_next(cx))
            .on_action(|_: &FocusPrevious, window, cx| window.focus_prev(cx))
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
                !self.model.read(cx).before_desktop && !installing && page != Page::Installed,
                |bar| {
                    // Settings cannot change during an install; the gear goes with them.
                    bar.settings(page == Page::Settings, move |_, _, cx| {
                        model.update(cx, |model, cx| {
                            let target =
                                if model.page == Page::Settings { Page::Home } else { Page::Settings };
                            model.navigate(target, cx);
                        })
                    })
                },
            ))
            // A preview translation is in use: one line of chrome under the
            // title bar says so, with the two ways out, until the user
            // dismisses it for this language or picks English.
            .when_some(preview_notice, |this, language| {
                let switch = self.model.clone();
                let change = self.model.clone();
                let dismiss = self.model.clone();
                this.child(
                    div()
                        .id("preview-notice")
                        .role(gpui::Role::Status)
                        .flex_shrink_0()
                        .flex()
                        .items_start()
                        .gap(px(8.))
                        .pl(px(16.))
                        .pr(px(8.))
                        .pt(px(2.))
                        .pb(px(8.))
                        .child(icon_in_line(Icon::Info, BODY_LINE_HEIGHT).text_color(theme.info))
                        .child(
                            div()
                                .flex_1()
                                .min_w_0()
                                .flex()
                                .flex_wrap()
                                .items_center()
                                .gap_x(px(4.))
                                .child(
                                    div()
                                        .type_body()
                                        .whitespace_normal()
                                        .mr(px(4.))
                                        .child(t!("preview-notice", language = language)),
                                )
                                .child(
                                    Button::new("preview-notice-english", t!("preview-notice-switch"))
                                        .hyperlink()
                                        .compact()
                                        .on_click(move |_, _, cx| {
                                            switch.update(cx, |model, cx| model.switch_to_english(cx))
                                        }),
                                )
                                .child(div().text_color(theme.text_tertiary).child("·"))
                                .child(
                                    Button::new("preview-notice-language", t!("preview-notice-language"))
                                        .hyperlink()
                                        .compact()
                                        .on_click(move |_, _, cx| {
                                            change.update(cx, |model, cx| model.navigate(Page::Settings, cx))
                                        }),
                                ),
                        )
                        .child(
                            Button::new("preview-notice-dismiss", "")
                                .icon(Icon::Cancel)
                                .subtle()
                                .compact()
                                .aria_label(t!("common-dismiss"))
                                .on_click(move |_, _, cx| {
                                    dismiss.update(cx, |model, cx| model.dismiss_preview_notice(cx))
                                }),
                        ),
                )
            })
            .when(self.model.read(cx).before_desktop && page != Page::Installed, |this| {
                this.child(
                    div()
                        .px(px(24.))
                        .py(px(12.))
                        .flex()
                        .items_center()
                        .gap(px(16.))
                        .child(
                            div()
                                .flex_1()
                                .min_w_0()
                                .whitespace_normal()
                                .child(t!("desktop-setup-description")),
                        )
                        .child(
                            div().flex_shrink_0().child(
                                crate::ui::Button::new("desktop-exit", t!("desktop-setup-exit"))
                                    .disabled(self.model.read(cx).locked())
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
                    .child(if installing {
                        // One thing at a time: the whole layer is the install.
                        self.installing.clone().into_any_element()
                    } else {
                        match page {
                            Page::Home => self.home.clone().into_any_element(),
                            Page::Iso => self.iso.clone().into_any_element(),
                            Page::Install => self.install.clone().into_any_element(),
                            Page::Settings => self.settings.clone().into_any_element(),
                            Page::Installed => self.installed.clone().into_any_element(),
                        }
                    }),
            )
    }
}
