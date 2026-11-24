//! Settings, in sections as Windows Settings has them: Appearance, Language,
//! Installation, Privacy, Help and About, each a heading over its cards.

use gpui::{
    AnyElement, Context, Div, ElementId, Entity, IntoElement, ParentElement, Pixels, Render, ScrollHandle,
    SharedString, Styled, Window, div, prelude::*, px, rems,
};

use super::{
    Diagnostics, card_body, detail_row, detail_text, heading, manager_update_bar, page_frame, setting_row,
};
use crate::i18n::{self, Decision, Readiness, fmt};
use crate::model::AppModel;
use crate::services::settings::{LanguagePreference, ThemePreference, app_data_dir};
use crate::services::system::links;
use crate::t;
use crate::theme::{ActiveTheme, FONT_TEXT};
use crate::ui::{
    BODY_LINE_HEIGHT, Button, ComboBox, ComboItem, FocusHandles, Icon, ScrollbarState, ToggleSwitch,
    Typography, a11y_text, card, link_row,
};

/// The theme choices, in the order the box lists them.
const THEMES: [ThemePreference; 3] = [ThemePreference::System, ThemePreference::Light, ThemePreference::Dark];

/// Where Atlas says what usage analytics collect.
const PRIVACY_POLICY_URL: &str = "https://atlasos.net/privacy-policy/";

/// The widest a combo box grows, so a long language name wraps the row
/// rather than crowding its header.
const COMBO_MAX_WIDTH: f32 = 22.;

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
    (widest + px(12. + 8. + 12. + 10. + 2.))
        .ceil()
        .max(BODY_LINE_HEIGHT.to_pixels(window.rem_size()) * 4.)
        .min(rems(COMBO_MAX_WIDTH).to_pixels(window.rem_size()))
}

/// One section of the page: its heading, then its cards, 4px apart as
/// Windows Settings lists them.
fn section(cx: &gpui::App, key: &str, title: String, cards: impl IntoIterator<Item = AnyElement>) -> Div {
    div()
        .flex()
        .flex_col()
        .gap(px(8.))
        .child(heading(ElementId::Name(format!("settings-section-{key}").into()), 2, title, cx))
        .child(div().flex().flex_col().gap(px(4.)).children(cards))
}

/// The one note under the language box, if any changes what the person
/// sees: why the box shows English, that the language in use is a preview,
/// or that dates and numbers follow another region.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum LanguageNote {
    /// The language chosen isn't in this build; English shows.
    ChosenUnavailable,
    /// Match Windows found no language Atlas has; English shows.
    WindowsUnsupported,
    /// The Windows display languages couldn't be read; English shows.
    WindowsUnreadable,
    /// The language in use is a preview translation, and its notice was dismissed.
    Preview,
    /// Numbers, and dates unless they'd be right to left, follow a regional
    /// format of another language or region.
    Region { dates: bool },
}

/// What [`LanguageNote`] to show: the first that applies, most important
/// first. `preview` is whether the language in use is a preview translation
/// whose notice the person dismissed.
fn language_note(
    decision: &Decision,
    preview: bool,
    region_differs: bool,
    dates: bool,
) -> Option<LanguageNote> {
    match decision {
        Decision::SettingUnavailable(_) => Some(LanguageNote::ChosenUnavailable),
        Decision::WindowsUnmatched => Some(LanguageNote::WindowsUnsupported),
        Decision::WindowsUnavailable(_) => Some(LanguageNote::WindowsUnreadable),
        _ if preview => Some(LanguageNote::Preview),
        // A right-to-left regional format is never the app's language.
        _ if region_differs || !dates => Some(LanguageNote::Region { dates }),
        _ => None,
    }
}

/// Whether a regional format (`format`) is of another language than the
/// app's (`app`), or of another region when both name one: "en-GB" and
/// "en-US" differ, "de" and "de-AT" don't.
fn region_differs(app: &str, format: &str) -> bool {
    fn parts(tag: &str) -> (String, Option<String>) {
        let mut subtags = tag.split(['-', '_']);
        let language = subtags.next().unwrap_or_default().to_ascii_lowercase();
        let region = subtags
            .find(|subtag| {
                (subtag.len() == 2 && subtag.chars().all(|c| c.is_ascii_alphabetic()))
                    || (subtag.len() == 3 && subtag.chars().all(|c| c.is_ascii_digit()))
            })
            .map(str::to_ascii_uppercase);
        (language, region)
    }
    let ((app_language, app_region), (format_language, format_region)) = (parts(app), parts(format));
    app_language != format_language || matches!((app_region, format_region), (Some(a), Some(f)) if a != f)
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
        #[cfg(debug_assertions)]
        preview_export(&model, cx);
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
    fn language_card(&mut self, labels: &LanguageLabels, width: Pixels, cx: &mut Context<Self>) -> Div {
        let model = self.model.clone();
        let state = self.model.read(cx);
        let preference = state.settings.language.clone();
        let localization = &state.localization;
        let primary = localization.primary();
        let decision = localization.decision.clone();
        let note = language_note(
            &decision,
            primary.readiness < Readiness::Source && state.preview_notice().is_none(),
            region_differs(primary.tag, &localization.format_locale),
            fmt::dates_follow_region(),
        );
        let listed = listed_languages();
        let items = std::iter::once(ComboItem::new(labels.match_windows.clone())).chain(listed.iter().map(
            |locale| {
                let item = ComboItem::new(locale.native_name).lang(locale.tag);
                if locale.readiness < Readiness::Source {
                    item.chip(t!("settings-language-preview-tag"))
                } else {
                    item
                }
            },
        ));
        // The language in use where the saved choice can't be shown, so the
        // box is never empty.
        let selected = language_index(&preference, &listed)
            .or_else(|| language_index(&LanguagePreference::Explicit(primary.tag.to_owned()), &listed));
        let choices: Vec<LanguagePreference> = std::iter::once(LanguagePreference::System)
            .chain(listed.iter().map(|l| LanguagePreference::Explicit(l.tag.to_owned())))
            .collect();
        let note = note.map(|note| match note {
            LanguageNote::ChosenUnavailable => t!("settings-language-chosen-unavailable"),
            LanguageNote::WindowsUnsupported => t!("settings-language-windows-unsupported"),
            LanguageNote::WindowsUnreadable => t!("settings-language-windows-unreadable"),
            LanguageNote::Preview => t!("settings-language-preview-in-use"),
            LanguageNote::Region { dates: true } => {
                t!("settings-language-formats", locale = fmt::format_locale_name())
            }
            LanguageNote::Region { dates: false } => {
                t!("settings-language-formats-numbers-only", locale = fmt::format_locale_name())
            }
        });

        let combo = div()
            .w(width)
            .max_w_full()
            .child(
                ComboBox::new("language", t!("settings-app-language"))
                    .items(items)
                    .selected(selected)
                    .on_select(move |index, _, cx| {
                        let value = choices[index].clone();
                        model.update(cx, |m, cx| m.set_language(value, cx));
                    }),
            )
            .into_any_element();
        // Under the control, in the same card: what the choice changes.
        let below: Vec<AnyElement> = note
            .map(|note| setting_note("language-note", note, cx))
            .into_iter()
            .chain(std::iter::once(
                link_row()
                    .child(
                        Button::new("language-contribute", t!("settings-language-contribute"))
                            .hyperlink()
                            .compact()
                            .trailing_icon(Icon::OpenInNewWindow)
                            .opens(TRANSLATIONS_URL),
                    )
                    .into_any_element(),
            ))
            .collect();
        setting_row(cx, "language", t!("settings-app-language"), None, combo, below)
    }
}

/// The languages the box lists after Match Windows.
fn listed_languages() -> Vec<&'static i18n::Locale> {
    i18n::catalog::LOCALES.iter().filter(|l| l.listed()).collect()
}

/// The language box's own labels, which also size both boxes.
struct LanguageLabels {
    /// Match Windows with the language it gives, negotiated from the Windows
    /// list itself so it holds whichever language is chosen now: English
    /// when nothing matches or the list can't be read.
    match_windows: String,
    /// Every label in the list.
    all: Vec<String>,
}

impl LanguageLabels {
    fn of(state: &AppModel) -> Self {
        let listed = listed_languages();
        let windows_languages = &state.localization.windows_languages;
        let requested = i18n::negotiate::parse_tags(windows_languages.iter().map(String::as_str));
        let windows_language = i18n::negotiate::negotiate(&requested, &listed)
            .first()
            .map(|l| l.native_name)
            .unwrap_or(i18n::catalog::source().native_name);
        let match_windows = t!("settings-language-match-windows", language = windows_language);
        let all = std::iter::once(match_windows.clone())
            .chain(listed.iter().map(|locale| locale.native_name.to_owned()))
            .collect();
        Self { match_windows, all }
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

/// Opens Settings with an export in the state `ATLAS_DIAGNOSTICS_PREVIEW`
/// names, for review captures: `exporting`, `saved` or `failed`. Nothing is
/// collected.
#[cfg(debug_assertions)]
fn preview_export(model: &Entity<AppModel>, cx: &mut Context<SettingsPage>) {
    let Ok(state) = std::env::var("ATLAS_DIAGNOSTICS_PREVIEW") else { return };
    let zip = app_data_dir().join("Diagnostics").join("Atlas-diagnostics-2026-11-24-0612.zip");
    let (busy, result) = match state.as_str() {
        "exporting" => (true, None),
        "saved" => (false, Some(Ok(zip))),
        "failed" => (false, Some(Err("export Atlas diagnostics: Access is denied. (os error 5)".to_owned()))),
        _ => return,
    };
    model.update(cx, |m, _| {
        m.diagnostics_busy = busy;
        m.diagnostics_result = result;
    });
}

/// A note under a setting's control row, where the theme's and the
/// language's notes both go.
fn setting_note(id: &'static str, text: String, cx: &gpui::App) -> AnyElement {
    div().type_caption().text_color(cx.theme().text_secondary).child(a11y_text(id, text)).into_any_element()
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
        let language_labels = LanguageLabels::of(self.model.read(cx));
        // Both boxes take the width of the longest label either has.
        let box_width = combo_width(&[theme_labels.clone(), language_labels.all.clone()].concat(), window);
        let language = self.language_card(&language_labels, box_width, cx);
        let state = self.model.read(cx);
        let current = state.settings.theme;
        let locked = state.locked();
        let high_contrast = theme.high_contrast;
        // A contrast theme sets the colours, so the choice is unavailable.
        let note = high_contrast.then(|| setting_note("theme-note", t!("settings-theme-contrast-note"), cx));

        let theme_box = div()
            .w(box_width)
            .max_w_full()
            .child(
                ComboBox::new("theme", t!("settings-theme"))
                    .items(theme_labels.into_iter().map(ComboItem::new))
                    .selected(THEMES.iter().position(|value| *value == current))
                    // A contrast theme sets the colours; the note under the row says so.
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
            setting_row(cx, "theme", t!("settings-theme"), None, theme_box, note.into_iter().collect());

        // On or off: a toggle switch, and the whole card toggles it. Its
        // description is safety text, so it stays. The setting governs the
        // restart after installing and the one Windows and Store updates
        // need on Get ready.
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
        let restart_description = if locked {
            t!("settings-restart-locked")
        } else {
            t!("settings-restart-automatically-description")
        };
        let restart_switch =
            ToggleSwitch::new("settings-restart", t!("settings-restart-automatically"), restart_on)
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
                t!("settings-restart-automatically"),
                Some(restart_description.into()),
                restart_switch,
                Vec::new(),
            ));

        let analytics_model = model.clone();
        let analytics_label = t!("settings-share-usage");
        let analytics_description = t!("settings-share-usage-description");
        let analytics_switch = ToggleSwitch::new(
            "settings-analytics-switch",
            analytics_label.clone(),
            state.settings.usage_analytics,
        )
        .description(analytics_description.clone())
        .on_toggle(move |_, _, cx| {
            analytics_model.update(cx, |m, cx| m.set_usage_analytics(!m.settings.usage_analytics, cx));
        });
        let analytics = setting_row(
            cx,
            "analytics",
            analytics_label,
            Some(analytics_description.into()),
            analytics_switch.into_any_element(),
            vec![
                link_row()
                    .child(
                        Button::new("settings-privacy-policy", t!("settings-privacy-policy"))
                            .hyperlink()
                            .compact()
                            .trailing_icon(Icon::OpenInNewWindow)
                            .opens(PRIVACY_POLICY_URL),
                    )
                    .into_any_element(),
            ],
        );
        let manager_update = manager_update_bar(state, "about");
        let about = card(cx).child(
            card_body()
                // Above the version it supersedes.
                .when_some(manager_update, |this, bar| this.child(bar))
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
                    link_row()
                        .pt(px(4.))
                        .child(
                            Button::new("about-docs", t!("common-read-the-docs"))
                                .hyperlink()
                                .compact()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(links::DOCS),
                        )
                        .child(
                            Button::new("about-github", t!("settings-view-source"))
                                .hyperlink()
                                .compact()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(links::GITHUB),
                        )
                        .child(
                            Button::new("about-licenses", t!("settings-view-licences"))
                                .hyperlink()
                                .compact()
                                .on_click(cx.listener(|this, _, _, cx| this.open_licences(cx))),
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
        let help = card(cx).child(card_body().child(self.diagnostics.content_with_app_folder(
            &self.model,
            app_data_dir(),
            cx,
        )));
        self.diagnostics.settle(&self.model, window, cx);
        let sections = [
            section(cx, "appearance", t!("settings-appearance"), [appearance.into_any_element()]),
            section(cx, "language", t!("settings-language"), [language.into_any_element()]),
            section(cx, "installation", t!("settings-installation"), [install.into_any_element()]),
            section(cx, "privacy", t!("settings-privacy"), [analytics.into_any_element()]),
            section(cx, "help", t!("settings-help"), [help.into_any_element()]),
            section(cx, "about", t!("settings-about"), [about.into_any_element()]),
        ];
        page_frame(
            "settings-scroll",
            Some(t!("settings-title").into()),
            Some(&title_focus),
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            // Sections further apart than the page's cards, as Windows Settings sets them.
            sections.into_iter().enumerate().map(|(index, section)| {
                section.when(index > 0, |this| this.pt(px(SECTION_GAP))).into_any_element()
            }),
            None,
            cx,
        )
    }
}

/// Added to the page's 12px between sections, so a heading sits closer to
/// its own cards than to the section above, as in Windows Settings.
const SECTION_GAP: f32 = 16.;

/// The bundled Atlas package's digest on a tester build; empty elsewhere.
fn bundled_digest() -> String {
    #[cfg(feature = "embedded-package")]
    {
        crate::services::embedded::sha256().to_owned()
    }
    #[cfg(not(feature = "embedded-package"))]
    {
        String::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn a_regional_format_differs_only_by_language_or_a_named_region() {
        assert!(!region_differs("en-GB", "en-GB"));
        assert!(region_differs("en-GB", "en-US"));
        assert!(!region_differs("de", "de-AT"), "a language without a region takes any");
        assert!(region_differs("de", "fr-FR"));
        assert!(!region_differs("zh-TW", "zh-Hant-TW"), "scripts don't count");
        assert!(!region_differs("es", "es-419"));
        assert!(region_differs("es-ES", "es-419"), "numeric regions count");
        assert!(!region_differs("EN-gb", "en_GB"));
    }

    #[test]
    fn the_language_card_says_one_thing_and_only_what_changes_something() {
        let note =
            |decision: Decision, preview, differs, dates| language_note(&decision, preview, differs, dates);
        // Nothing to say where the app matches Windows and the region.
        assert_eq!(note(Decision::Windows, false, false, true), None);
        assert_eq!(note(Decision::Setting, false, false, true), None);
        // Why the box shows English comes before anything else.
        assert_eq!(
            note(Decision::SettingUnavailable("xx-ZZ".into()), true, true, true),
            Some(LanguageNote::ChosenUnavailable)
        );
        assert_eq!(
            note(Decision::WindowsUnmatched, false, true, true),
            Some(LanguageNote::WindowsUnsupported)
        );
        assert_eq!(
            note(Decision::WindowsUnavailable("error".into()), false, false, true),
            Some(LanguageNote::WindowsUnreadable)
        );
        // Then a preview translation, then the region.
        assert_eq!(note(Decision::Setting, true, true, true), Some(LanguageNote::Preview));
        assert_eq!(note(Decision::Setting, false, true, true), Some(LanguageNote::Region { dates: true }));
        // A right-to-left regional format always differs, and its dates fall back.
        assert_eq!(note(Decision::Windows, false, false, false), Some(LanguageNote::Region { dates: false }));
        // A review override says nothing of its own.
        assert_eq!(note(Decision::Override("de".into()), false, false, true), None);
    }
}
