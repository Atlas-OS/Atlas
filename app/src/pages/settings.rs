//! Settings: appearance, language, install behaviour and about.

use gpui::{Context, Entity, IntoElement, ParentElement, Render, ScrollHandle, Styled, Window, div, px};

use super::{card_body, card_header, detail_row, detail_text, page_frame};
use crate::i18n::{self, Decision, Readiness, fmt};
use crate::model::AppModel;
use crate::services::settings::{LanguagePreference, ThemePreference, app_data_dir};
use crate::services::system::links;
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CheckBox, FocusHandles, Icon, RadioGroup, RadioItem, ScrollbarState, Typography, card,
};

const THEMES: [(&str, ThemePreference); 3] = [
    ("theme-system", ThemePreference::System),
    ("theme-light", ThemePreference::Light),
    ("theme-dark", ThemePreference::Dark),
];

/// Where translations are contributed.
const TRANSLATIONS_URL: &str = "https://github.com/Atlas-OS/Atlas/tree/main/app/i18n";

pub struct SettingsPage {
    model: Entity<AppModel>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
}

impl SettingsPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        Self {
            model,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
        }
    }

    /// The language card: "Match Windows" first, then every shipped language
    /// under its own name. The choice takes effect at once and is kept.
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

        // What "Match Windows" gives right now, under that option.
        let system_detail = match &decision {
            Decision::Windows
            | Decision::Override(_)
            | Decision::Setting
            | Decision::SettingUnavailable(_) => {
                // While an explicit language is chosen, say what Windows
                // would give by looking at the Windows list directly.
                let requested = i18n::negotiate::parse_tags(windows_languages.iter().map(String::as_str));
                let auto: Vec<&'static i18n::Locale> =
                    listed.iter().copied().filter(|l| l.auto_selectable()).collect();
                let chain = i18n::negotiate::negotiate(&requested, &auto);
                let name =
                    chain.first().map(|l| l.native_name).unwrap_or(i18n::catalog::source().native_name);
                Some(t!("settings-language-system-detail", language = name))
            }
            Decision::WindowsPreview(tag) => {
                // Only reachable if the auto-select threshold is raised again:
                // Match Windows would then give English, and the preview is listed below.
                let name = i18n::catalog::find(tag).map(|l| l.native_name).unwrap_or(tag.as_str());
                let _ = name;
                Some(t!("settings-language-system-detail", language = i18n::catalog::source().native_name))
            }
            Decision::WindowsUnmatched => {
                Some(t!("settings-language-windows-unmatched", languages = windows_languages.join(", ")))
            }
            Decision::WindowsUnavailable(error) => {
                Some(t!("settings-language-windows-unavailable", error = error))
            }
        };

        let mut items = vec![{
            let mut item = RadioItem::new(
                "language-system",
                t!("settings-language-system"),
                self.focus.get("language-system", cx),
            );
            if let Some(detail) = system_detail {
                item = item.description(detail);
            }
            item
        }];
        for locale in &listed {
            let key = format!("language-{}", locale.tag);
            let handle = self.focus.get(&key, cx);
            let mut item = RadioItem::new(gpui::ElementId::Name(key.into()), locale.native_name, handle);
            if locale.readiness < Readiness::Source {
                item = item.description(t!("settings-language-preview"));
            }
            items.push(item);
        }
        let selected = match &preference {
            LanguagePreference::System => Some(0),
            LanguagePreference::Explicit(tag) => {
                listed.iter().position(|l| l.tag.eq_ignore_ascii_case(tag)).map(|index| index + 1)
            }
        };
        let choices: Vec<LanguagePreference> = std::iter::once(LanguagePreference::System)
            .chain(listed.iter().map(|l| LanguagePreference::Explicit(l.tag.to_owned())))
            .collect();

        let mut notes: Vec<String> = Vec::new();
        if let Decision::SettingUnavailable(tag) = &decision {
            notes.push(t!("settings-language-unavailable", tag = tag));
        }
        if let Decision::Override(tag) = &decision {
            notes.push(format!("--language {tag} ({primary_tag})"));
        }
        notes.push(t!("settings-language-formats", locale = fmt::format_locale_name()));

        card(cx).child(card_header(cx, "language", t!("settings-language"), None)).child(
            card_body(cx)
                .gap(px(2.))
                .child(
                    RadioGroup::new("language-group", t!("settings-language"))
                        .items(items)
                        .selected(selected)
                        .on_select(move |index, _, cx| {
                            let value = choices[index].clone();
                            model.update(cx, |m, cx| m.set_language(value, cx));
                        }),
                )
                .children(notes.into_iter().enumerate().map(|(index, note)| {
                    div()
                        .pt(px(6.))
                        .type_caption()
                        .text_color(theme.text_secondary)
                        .child(crate::ui::a11y_text(("language-note", index), note))
                }))
                .child(
                    div().flex().pt(px(4.)).child(
                        Button::new("language-contribute", t!("settings-language-contribute"))
                            .hyperlink()
                            .compact()
                            .trailing_icon(Icon::OpenInNewWindow)
                            .opens(TRANSLATIONS_URL),
                    ),
                ),
        )
    }
}

impl Render for SettingsPage {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme().clone();
        let model = self.model.clone();
        let theme_labels =
            [t!("settings-theme-system"), t!("settings-theme-light"), t!("settings-theme-dark")];
        let items: Vec<RadioItem> = THEMES
            .iter()
            .zip(theme_labels)
            .map(|((id, _), label)| RadioItem::new(*id, label, self.focus.get(id, cx)))
            .collect();
        let language = self.language_card(cx);
        let state = self.model.read(cx);
        let current = state.settings.theme;
        let locked = state.locked();
        let high_contrast = theme.high_contrast;

        let appearance = card(cx).child(card_header(cx, "theme", t!("settings-theme"), None)).child(
            card_body(cx)
                .gap(px(2.))
                .child(
                    RadioGroup::new("theme-group", t!("settings-theme"))
                        .items(items)
                        .selected(THEMES.iter().position(|(_, value)| *value == current))
                        .disabled(high_contrast)
                        .on_select({
                            let model = model.clone();
                            move |index, _, cx| {
                                let value = THEMES[index].1;
                                model.update(cx, |m, cx| m.set_theme(value, cx));
                            }
                        }),
                )
                .child(div().pt(px(6.)).type_caption().text_color(theme.text_secondary).child(
                    if high_contrast {
                        t!("settings-theme-contrast-note")
                    } else {
                        t!("settings-theme-mica-note")
                    },
                )),
        );

        let install = card(cx).child(card_header(cx, "installing", t!("settings-installing"), None)).child(
            card_body(cx).child(
                CheckBox::new(
                    "settings-restart",
                    t!("settings-restart-label"),
                    state.settings.restart_after_install,
                )
                .description(if locked {
                    t!("settings-restart-locked")
                } else {
                    t!("settings-restart-description")
                })
                .disabled(locked)
                .on_toggle({
                    let model = model.clone();
                    move |_, _, cx| {
                        model.update(cx, |m, cx| {
                            let next = !m.settings.restart_after_install;
                            m.set_restart_after_install(next, cx);
                        })
                    }
                }),
            ),
        );

        let about = card(cx).child(card_header(cx, "about", t!("settings-about"), None)).child(
            card_body(cx)
                .child(detail_row(
                    cx,
                    "app",
                    t!("settings-about-app"),
                    detail_text("app", env!("CARGO_PKG_VERSION")),
                ))
                .child(detail_row(
                    cx,
                    "data",
                    t!("settings-about-data"),
                    detail_text("data", app_data_dir().display().to_string()),
                ))
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
                            Button::new("about-licenses", t!("settings-about-licence")).hyperlink().on_click(
                                |_, _, _| {
                                    if let Err(error) = crate::services::licenses::open() {
                                        log::error!("Could not open license notices: {error}");
                                    }
                                },
                            ),
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
                ),
        );

        page_frame(
            "settings-scroll",
            Some(t!("settings-title").into()),
            Some(&self.model),
            (&self.scroll, &self.scrollbar),
            vec![
                appearance.into_any_element(),
                language.into_any_element(),
                install.into_any_element(),
                about.into_any_element(),
            ],
            None,
            cx,
        )
    }
}
