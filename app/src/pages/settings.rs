//! Settings: appearance, language, install behaviour, help and feedback, and about.

use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, Pixels, Render, ScrollHandle, SharedString,
    Styled, Window, div, prelude::*, px, rems,
};

use super::{Diagnostics, card_body, card_header, detail_row, detail_text, page_frame, setting_row};
use crate::i18n::{self, Decision, Readiness, fmt};
use crate::model::AppModel;
use crate::services::settings::{LanguagePreference, ThemePreference, app_data_dir};
use crate::services::system::links;
use crate::t;
use crate::theme::{ActiveTheme, FONT_TEXT};
use crate::ui::{
    BODY_LINE_HEIGHT, Button, ComboBox, ComboItem, FocusHandles, Icon, ScrollbarState, ToggleSwitch,
    Typography, a11y_text, card,
};

/// The theme choices, in the order the box lists them.
const THEMES: [ThemePreference; 3] = [ThemePreference::System, ThemePreference::Light, ThemePreference::Dark];

/// A combo box wide enough for the longest of `labels` at the current text
/// size: its padding, chevron and border around the text.
fn combo_width(labels: &[String], window: &Window) -> Pixels {
    let size = rems(14. / 16.).to_pixels(window.rem_size());
    let widest = labels
        .iter()
        .map(|label| {
            let text: SharedString = label.clone().into();
            let run = [gpui::TextRun {
                len: text.len(),
                font: gpui::font(FONT_TEXT),
                color: gpui::black(),
                background_color: None,
                underline: None,
                strikethrough: None,
            }];
            window.text_system().shape_line(text, size, &run, None).width
        })
        .fold(px(0.), Pixels::max);
    // 12px before the text, 8px gap, a 12px chevron, 10px after, 2px of border.
    (widest + px(12. + 8. + 12. + 10. + 2.)).ceil().max(BODY_LINE_HEIGHT.to_pixels(window.rem_size()) * 4.)
}

/// Where translations are contributed.
const TRANSLATIONS_URL: &str = "https://github.com/Atlas-OS/Atlas/tree/main/app/i18n";

pub struct SettingsPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    /// The model's page visit this page last drew, to announce each arrival.
    seen_visit: u64,
    diagnostics: Diagnostics,
    /// The licence notices could not be opened.
    licences_failed: bool,
}

impl SettingsPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            seen_visit: 0,
            diagnostics: Diagnostics::new(cx),
            licences_failed: false,
        }
    }

    /// Writing the notices out and asking Windows to open them can take a
    /// moment, so it happens off the UI thread.
    fn open_licences(&mut self, cx: &mut Context<Self>) {
        self.licences_failed = false;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result = cx.background_executor().spawn(async { crate::services::licenses::open() }).await;
            if let Err(error) = &result {
                log::error!("Could not open license notices: {error:#}");
            }
            this.update(cx, |this, cx| {
                this.licences_failed = result.is_err();
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// The language setting: a combo box with "Match Windows" first, then
    /// every language Atlas includes, under its own name and read in its own
    /// language. A choice takes effect when it's committed, and is kept;
    /// moving through the open list changes nothing, so the app and the
    /// screen reader keep their language until then.
    fn language_card(&mut self, cx: &mut Context<Self>) -> gpui::Div {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let (preference, decision, windows_languages, primary_tag) = {
            let state = self.model.read(cx);
            (
                state.settings.language.clone(),
                state.localization.decision.clone(),
                state.localization.windows_languages.clone(),
                state.localization.primary().tag,
            )
        };
        let listed: Vec<&'static i18n::Locale> =
            i18n::catalog::LOCALES.iter().filter(|l| l.listed()).collect();

        // What "Match Windows" gives, negotiated from the Windows list itself,
        // so the answer holds whichever language is chosen now. English when
        // nothing matches or the list can't be read.
        let requested = i18n::negotiate::parse_tags(windows_languages.iter().map(String::as_str));
        let windows_language = i18n::negotiate::negotiate(&requested, &listed)
            .first()
            .map(|l| l.native_name)
            .unwrap_or(i18n::catalog::source().native_name);

        let items = std::iter::once(
            ComboItem::new(t!("settings-language-system"))
                .selected_label(t!("settings-language-system-selected", language = windows_language)),
        )
        .chain(listed.iter().map(|locale| {
            let item = ComboItem::new(locale.native_name).lang(locale.tag);
            if locale.readiness < Readiness::Source {
                item.chip(t!("settings-language-preview-tag"))
            } else {
                item
            }
        }));
        let selected = language_index(&preference, &listed);
        let choices: Vec<LanguagePreference> = std::iter::once(LanguagePreference::System)
            .chain(listed.iter().map(|l| LanguagePreference::Explicit(l.tag.to_owned())))
            .collect();

        let mut notes: Vec<String> = Vec::new();
        match &decision {
            Decision::WindowsUnmatched => notes
                .push(t!("settings-language-windows-unmatched", languages = windows_languages.join(", "))),
            Decision::WindowsUnavailable(error) => {
                notes.push(t!("settings-language-windows-unavailable", error = error))
            }
            // The box already says what Match Windows gives while it's chosen.
            _ if matches!(preference, LanguagePreference::Explicit(_)) => {
                notes.push(t!("settings-language-system-detail", language = windows_language))
            }
            _ => {}
        }
        if let Decision::SettingUnavailable(tag) = &decision {
            notes.push(t!("settings-language-unavailable", tag = tag));
        }
        if let Decision::Override(tag) = &decision {
            notes.push(format!("--language {tag} ({primary_tag})"));
        }
        // What the Preview tag in the list means, said once.
        if listed.iter().any(|locale| locale.readiness < Readiness::Source) {
            notes.push(t!("settings-language-preview-note"));
        }
        let locale = fmt::format_locale_name();
        notes.push(if fmt::dates_follow_region() {
            t!("settings-language-formats", locale = locale)
        } else {
            t!("settings-language-formats-numbers-only", locale = locale)
        });

        // Wide enough for "Match Windows" and the language it gives, growing
        // with the text size up to 22rem.
        let combo = div()
            .w(rems(22.))
            .max_w_full()
            .child(
                ComboBox::new("language", t!("settings-language")).items(items).selected(selected).on_select(
                    move |index, _, cx| {
                        let value = choices[index].clone();
                        model.update(cx, |m, cx| m.set_language(value, cx));
                    },
                ),
            )
            .into_any_element();
        // Under the control, in the same card: what the choice means.
        let mut below: Vec<AnyElement> = notes
            .into_iter()
            .enumerate()
            .map(|(index, note)| {
                div()
                    .type_caption()
                    .text_color(theme.text_secondary)
                    .child(a11y_text(("language-note", index), note))
                    .into_any_element()
            })
            .collect();
        below.push(
            div()
                .flex()
                .child(
                    Button::new("language-contribute", t!("settings-language-contribute"))
                        .hyperlink()
                        .compact()
                        .trailing_icon(Icon::OpenInNewWindow)
                        .opens(TRANSLATIONS_URL),
                )
                .into_any_element(),
        );
        setting_row(cx, "language", t!("settings-language"), None, combo, below)
    }
}

/// The combo box's choice for `preference`: Match Windows comes first, then
/// the listed languages. `None` for a language this build doesn't list.
fn language_index(preference: &LanguagePreference, listed: &[&i18n::Locale]) -> Option<usize> {
    match preference {
        LanguagePreference::System => Some(0),
        LanguagePreference::Explicit(tag) => {
            listed.iter().position(|l| l.tag.eq_ignore_ascii_case(tag)).map(|index| index + 1)
        }
    }
}

/// The note under the theme choice, if one applies.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum ThemeNote {
    /// A contrast theme sets the colours, so the choice is unavailable.
    Contrast,
    /// The chosen theme differs from Windows', which turns the translucent
    /// background off. Nothing is said while it shows.
    Mica,
}

fn theme_note(high_contrast: bool, mica: bool) -> Option<ThemeNote> {
    if high_contrast {
        Some(ThemeNote::Contrast)
    } else if !mica {
        Some(ThemeNote::Mica)
    } else {
        None
    }
}

impl Render for SettingsPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let title_focus = self.focus.get("settings-title", cx);
        let visit = self.model.read(cx).page_visit;
        if std::mem::replace(&mut self.seen_visit, visit) != visit {
            window.focus(&title_focus, cx);
        }
        let theme_labels =
            vec![t!("settings-theme-system"), t!("settings-theme-light"), t!("settings-theme-dark")];
        let theme_width = combo_width(&theme_labels, window);
        let language = self.language_card(cx);
        let state = self.model.read(cx);
        let current = state.settings.theme;
        let locked = state.locked();
        let high_contrast = theme.high_contrast;
        let note = theme_note(high_contrast, theme.mica).map(|note| match note {
            ThemeNote::Contrast => t!("settings-theme-contrast-note"),
            ThemeNote::Mica => t!("settings-theme-mica-note"),
        });

        let theme_box = div()
            .w(theme_width)
            .max_w_full()
            .child(
                ComboBox::new("theme", t!("settings-theme"))
                    .items(theme_labels.into_iter().map(ComboItem::new))
                    .selected(THEMES.iter().position(|value| *value == current))
                    // A contrast theme sets the colours; the note under the header says so.
                    .disabled(high_contrast)
                    .on_select({
                        let model = model.clone();
                        move |index, _, cx| {
                            let value = THEMES[index];
                            model.update(cx, |m, cx| m.set_theme(value, cx));
                        }
                    }),
            )
            .into_any_element();
        let appearance =
            setting_row(cx, "theme", t!("settings-theme"), note.map(Into::into), theme_box, Vec::new());

        // On or off: a toggle switch, and the whole card toggles it. Its
        // description is safety text, so it stays in full.
        let restart_on = state.settings.restart_after_install;
        let toggle_restart = {
            let model = model.clone();
            move |cx: &mut gpui::App| {
                model.update(cx, |m, cx| {
                    let next = !m.settings.restart_after_install;
                    m.set_restart_after_install(next, cx);
                })
            }
        };
        let switch_toggle = toggle_restart.clone();
        let restart_description =
            if locked { t!("settings-restart-locked") } else { t!("settings-restart-description") };
        let restart_switch = ToggleSwitch::new("settings-restart", t!("settings-restart-label"), restart_on)
            .description(restart_description.clone())
            .disabled(locked)
            .on_toggle(move |_, _, cx| {
                // The card around it toggles too; one toggle per click.
                cx.stop_propagation();
                switch_toggle(cx);
            })
            .into_any_element();
        let hover = theme.subtle_hover;
        let install = div()
            .id("settings-restart-card")
            .when(!locked, |this| {
                this.cursor_pointer()
                    .rounded(px(8.))
                    .hover(move |style| style.bg(hover))
                    .on_click(move |_, _, cx| toggle_restart(cx))
            })
            .child(setting_row(
                cx,
                "restart",
                t!("settings-restart-label"),
                Some(restart_description.into()),
                restart_switch,
                Vec::new(),
            ));

        let about = card(cx).child(card_header(cx, "about", t!("settings-about"), None)).child(
            card_body()
                .child(detail_row(
                    cx,
                    "app",
                    t!("settings-about-app"),
                    detail_text("app", env!("CARGO_PKG_VERSION")),
                ))
                .when_some(crate::services::embedded::rc_id(), |this, rc_id| {
                    this.child(detail_row(cx, "rc", t!("rc-about-release"), detail_text("rc", rc_id)))
                        .child(detail_row(
                            cx,
                            "commit",
                            t!("rc-about-commit"),
                            detail_text(
                                "commit",
                                crate::services::embedded::source_commit().unwrap_or("unknown"),
                            ),
                        ))
                        .child(detail_row(
                            cx,
                            "bundled",
                            t!("rc-about-package"),
                            detail_text("bundled", bundled_digest()),
                        ))
                })
                .child(detail_row(
                    cx,
                    "licence",
                    t!("settings-about-licence"),
                    detail_text("licence", t!("settings-about-licence-value")),
                ))
                .child(
                    div()
                        .flex()
                        .flex_wrap()
                        .gap(px(4.))
                        .pt(px(4.))
                        .child(
                            Button::new("about-docs", t!("common-read-the-docs"))
                                .hyperlink()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(links::DOCS),
                        )
                        .child(
                            Button::new("about-github", t!("settings-view-source"))
                                .hyperlink()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(links::GITHUB),
                        )
                        .child(
                            Button::new("about-licenses", t!("settings-view-licences"))
                                .hyperlink()
                                .on_click(cx.listener(|this, _, _, cx| this.open_licences(cx))),
                        )
                        .child(
                            Button::new("about-data", t!("settings-open-data-folder")).hyperlink().on_click(
                                |_, _, cx| {
                                    let dir = app_data_dir();
                                    let _ = std::fs::create_dir_all(&dir);
                                    cx.reveal_path(&dir);
                                },
                            ),
                        ),
                )
                .when(self.licences_failed, |this| {
                    this.child(
                        div()
                            .type_caption()
                            .text_color(theme.text_secondary)
                            .child(a11y_text("licences-failed", t!("settings-licences-failed"))),
                    )
                }),
        );

        // Always here, so there is one place to ask for help from.
        let help = card(cx)
            .child(card_header(cx, "help", t!("settings-help"), None))
            .child(card_body().child(self.diagnostics.content(&self.model, cx)));
        self.diagnostics.settle(&self.model, window, cx);
        page_frame(
            "settings-scroll",
            Some(t!("settings-title").into()),
            Some(&title_focus),
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            vec![
                // Settings cards, 4px apart, as Windows Settings lists them.
                div()
                    .flex()
                    .flex_col()
                    .gap(px(4.))
                    .child(appearance)
                    .child(language)
                    .child(install)
                    .into_any_element(),
                help.into_any_element(),
                about.into_any_element(),
            ],
            None,
            cx,
        )
    }
}

/// The bundled Atlas package's digest on a tester build; empty elsewhere.
fn bundled_digest() -> String {
    #[cfg(feature = "embedded-playbook")]
    {
        crate::services::embedded::sha256().to_owned()
    }
    #[cfg(not(feature = "embedded-playbook"))]
    {
        String::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_mica_note_shows_only_while_the_background_is_opaque() {
        assert_eq!(theme_note(false, true), None, "nothing to fix while the background is translucent");
        assert_eq!(theme_note(false, false), Some(ThemeNote::Mica));
        // A contrast theme sets the colours, so only its own note applies.
        assert_eq!(theme_note(true, false), Some(ThemeNote::Contrast));
        assert_eq!(theme_note(true, true), Some(ThemeNote::Contrast));
    }

    #[test]
    fn the_language_box_shows_the_saved_choice() {
        let listed: Vec<&'static i18n::Locale> =
            i18n::catalog::LOCALES.iter().filter(|l| l.listed()).collect();
        let german = listed.iter().position(|l| l.tag == "de").expect("German is listed");
        assert_eq!(language_index(&LanguagePreference::System, &listed), Some(0));
        // Match Windows comes first, so every language is one further down.
        assert_eq!(language_index(&LanguagePreference::Explicit("de".into()), &listed), Some(german + 1));
        assert_eq!(language_index(&LanguagePreference::Explicit("DE".into()), &listed), Some(german + 1));
        assert_eq!(language_index(&LanguagePreference::Explicit("xx".into()), &listed), None);
    }
}
