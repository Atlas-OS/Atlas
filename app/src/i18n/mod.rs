//! Localization: which language the app speaks, how that was decided, and
//! the message lookup every page uses through the [`t!`] macro.
//!
//! The language is chosen once at startup and again whenever the setting
//! changes or (while "Match Windows" is on) Windows reports a different
//! display-language list. Text is never stored: pages hold semantic state
//! and translate when they render, so switching language redraws every
//! existing notice, error and status without touching the flow, selections
//! or a running install.
//!
//! Regional formats (numbers, dates, times) come from [`fmt`] and follow the
//! Windows regional format independently of the app language.

pub mod catalog;
#[cfg(test)]
mod checks;
pub mod describe;
pub mod fmt;
pub mod negotiate;
mod pseudo;

use std::sync::{Arc, RwLock};

use gpui::{FontFallbacks, Global};
use unic_langid::LanguageIdentifier;

pub use catalog::{Arg, Catalog, Locale, Readiness};

use crate::services::locale;
use crate::services::settings::LanguagePreference;

/// Environment variable that overrides the language for review and tests
/// (`ATLAS_LANGUAGE=de`, or `qps-ploc` for the pseudo-locale).
pub const LANGUAGE_ENV: &str = "ATLAS_LANGUAGE";

/// How the current language chain was decided.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Decision {
    /// A test or review override (`--language`, `ATLAS_LANGUAGE`).
    Override(String),
    /// The setting names a shipped language.
    Setting,
    /// The setting names a language this build does not ship; English is
    /// showing and the preference is kept as it was.
    SettingUnavailable(String),
    /// "Match Windows" found a shipped language in the display-language list.
    Windows,
    /// "Match Windows" found none of the display languages; English is showing.
    WindowsUnmatched,
    /// "Match Windows" found a display language that ships only as a preview
    /// translation (tag); English is showing until the user opts in.
    WindowsPreview(String),
    /// The display-language list could not be read; English is showing.
    WindowsUnavailable(String),
}

/// The live localization state. A GPUI global so the shell can observe it;
/// the catalog itself is process-wide so any code can format a message.
#[derive(Clone, Debug)]
pub struct Localization {
    pub decision: Decision,
    /// The language chain, first choice first, English source last.
    pub chain: Vec<&'static Locale>,
    /// The Windows display-language list as last read, in order.
    pub windows_languages: Vec<String>,
    /// The regional format tag when the state was built, so a change made
    /// while the app was in the background triggers a redraw.
    pub format_locale: String,
}

impl Global for Localization {}

impl Localization {
    pub fn primary(&self) -> &'static Locale {
        self.chain.first().copied().unwrap_or_else(catalog::source)
    }

    /// Whether "Match Windows" should look at the Windows list again when
    /// the window is activated: every outcome that depends on that list,
    /// including a failed query, which must not stick.
    pub fn follows_windows(&self) -> bool {
        matches!(
            self.decision,
            Decision::Windows
                | Decision::WindowsUnmatched
                | Decision::WindowsPreview(_)
                | Decision::WindowsUnavailable(_)
        )
    }

    /// Font families to try ahead of the system fallback for this language.
    pub fn font_fallbacks(&self) -> Option<FontFallbacks> {
        let list = self.primary().font_fallbacks;
        (!list.is_empty())
            .then(|| FontFallbacks::from_fonts(list.iter().map(|name| (*name).to_owned()).collect()))
    }
}

static CATALOG: RwLock<Option<Arc<Catalog>>> = RwLock::new(None);

fn install(catalog: Catalog) {
    if let Ok(mut slot) = CATALOG.write() {
        *slot = Some(Arc::new(catalog));
    }
}

/// The active catalog. Before [`activate`] runs (unit tests, mostly) this is
/// the English source on its own.
pub fn current() -> Arc<Catalog> {
    if let Ok(slot) = CATALOG.read()
        && let Some(catalog) = slot.as_ref()
    {
        return catalog.clone();
    }
    let catalog = Arc::new(Catalog::new(&[catalog::source()]));
    if let Ok(mut slot) = CATALOG.write()
        && slot.is_none()
    {
        *slot = Some(catalog.clone());
    }
    catalog
}

/// Formats a message in the current language. Prefer the [`t!`] macro.
pub fn text(id: &str, args: &[(&str, Arg)]) -> String {
    current().format(id, None, args)
}

/// The override in force, if any: the explicit argument (from `--language`)
/// wins over the environment variable.
fn override_tag(argument: Option<&str>) -> Option<String> {
    argument
        .map(str::to_owned)
        .or_else(|| std::env::var(LANGUAGE_ENV).ok())
        .map(|tag| tag.trim().to_owned())
        .filter(|tag| !tag.is_empty())
}

/// Chooses the language chain for a preference and installs its catalog.
///
/// Order of precedence: a review override, then an explicit setting, then
/// the Windows display-language list, then English. A failure anywhere
/// leaves the app usable in English and is recorded in the decision.
pub fn activate(preference: &LanguagePreference, override_argument: Option<&str>) -> Localization {
    activate_with(preference, override_argument, windows_languages())
}

/// Environment variable that stands in for the Windows display-language
/// list for review and tests: a comma-separated list of tags, or `error` to
/// act as a failed query.
pub const WINDOWS_LANGUAGES_ENV: &str = "ATLAS_WINDOWS_LANGUAGES";

/// The Windows display-language list as the app sees it (honouring the
/// review override), for the activation re-check.
pub fn current_windows_languages() -> Result<Vec<String>, String> {
    windows_languages()
}

fn windows_languages() -> Result<Vec<String>, String> {
    match std::env::var(WINDOWS_LANGUAGES_ENV) {
        Ok(value) if value.trim().eq_ignore_ascii_case("error") => {
            Err("simulated failure (ATLAS_WINDOWS_LANGUAGES=error)".to_owned())
        }
        Ok(value) if !value.trim().is_empty() => {
            Ok(value.split(',').map(str::trim).filter(|tag| !tag.is_empty()).map(str::to_owned).collect())
        }
        _ => locale::ui_languages().map_err(|error| format!("{error:#}")),
    }
}

/// [`activate`] with the Windows display-language query's result supplied,
/// so the decision logic can be tested without Windows.
pub fn activate_with(
    preference: &LanguagePreference,
    override_argument: Option<&str>,
    windows: Result<Vec<String>, String>,
) -> Localization {
    let windows_languages = windows.as_ref().cloned().unwrap_or_default();
    let all: Vec<&'static Locale> = catalog::LOCALES.iter().collect();
    let listed: Vec<&'static Locale> = catalog::LOCALES.iter().filter(|locale| locale.listed()).collect();
    let auto: Vec<&'static Locale> =
        catalog::LOCALES.iter().filter(|locale| locale.auto_selectable()).collect();

    let (decision, chain) = if let Some(tag) = override_tag(override_argument) {
        // Overrides may name anything shipped, including the pseudo-locale.
        let chain = match catalog::find(&tag) {
            Some(locale) => vec![locale, catalog::source()],
            None => negotiate::negotiate(&negotiate::parse_tags([tag.as_str()]), &all),
        };
        (Decision::Override(tag), chain)
    } else {
        match preference {
            LanguagePreference::Explicit(tag) => match catalog::find(tag).filter(|locale| locale.listed()) {
                Some(locale) => {
                    // The explicit language first, then whatever Windows
                    // would have given, for messages a translation lacks.
                    let mut requested = vec![locale.id()];
                    requested.extend(negotiate::parse_tags(windows_languages.iter().map(String::as_str)));
                    (Decision::Setting, negotiate::negotiate(&requested, &all))
                }
                None => (Decision::SettingUnavailable(tag.clone()), vec![catalog::source()]),
            },
            LanguagePreference::System => match &windows {
                Ok(list) => {
                    let requested = negotiate::parse_tags(list.iter().map(String::as_str));
                    let chain = negotiate::negotiate(&requested, &auto);
                    // Which of the user's languages the automatic choice
                    // satisfied, and whether a preview translation of an
                    // earlier one exists to opt into.
                    let matched = chain.first().and_then(|first| request_index(&requested, first));
                    let preview = negotiate::negotiate(&requested, &listed)
                        .first()
                        .copied()
                        .filter(|first| !first.auto_selectable())
                        .and_then(|first| request_index(&requested, first).map(|index| (index, first)));
                    let decision = match (matched, preview) {
                        (Some(used), Some((wanted, locale))) if wanted < used => {
                            Decision::WindowsPreview(locale.tag.to_owned())
                        }
                        (Some(_), _) => Decision::Windows,
                        (None, Some((_, locale))) => Decision::WindowsPreview(locale.tag.to_owned()),
                        (None, None) => Decision::WindowsUnmatched,
                    };
                    (decision, chain)
                }
                Err(error) => {
                    log::warn!("could not read the Windows display languages: {error}");
                    (Decision::WindowsUnavailable(error.clone()), vec![catalog::source()])
                }
            },
        }
    };

    install(Catalog::new(&chain));
    log::info!(
        "language: {} ({decision:?}); Windows display languages: {windows_languages:?}; regional format: {}",
        chain
            .iter()
            .map(|locale| format!("{} ({})", locale.tag, locale.english_name))
            .collect::<Vec<_>>()
            .join(" > "),
        fmt::format_locale_tag()
    );
    Localization { decision, chain, windows_languages, format_locale: fmt::format_locale_tag() }
}

/// Whether a requested tag and a shipped locale share a language (so English
/// chosen as the fallback is not mistaken for a Windows match).
fn language_matches(requested: &LanguageIdentifier, shipped: &LanguageIdentifier) -> bool {
    requested.language == shipped.language
}

/// The position in the user's list of the first language `locale` serves.
fn request_index(requested: &[LanguageIdentifier], locale: &Locale) -> Option<usize> {
    let id = locale.id();
    requested.iter().position(|request| language_matches(request, &id))
}

/// Formats a message: `t!("id")` or `t!("id", count = 3, name = "x")`.
/// Message ids are literals so a test can check every use against the
/// source catalog.
#[macro_export]
macro_rules! t {
    ($id:literal) => {
        $crate::i18n::text($id, &[])
    };
    ($id:literal, $($key:ident = $value:expr),+ $(,)?) => {
        $crate::i18n::text($id, &[$((stringify!($key), $crate::i18n::Arg::from($value))),+])
    };
}

/// Test support: language switches are process-wide, so tests that read
/// English take a shared lock and tests that switch take it exclusively.
#[cfg(test)]
pub mod testing {
    use super::*;

    static LANGUAGE: RwLock<()> = RwLock::new(());

    /// Runs `f` with the English source guaranteed active.
    pub fn english<T>(f: impl FnOnce() -> T) -> T {
        let _shared = LANGUAGE.read().unwrap_or_else(|poisoned| poisoned.into_inner());
        install(Catalog::new(&[catalog::source()]));
        f()
    }

    /// Runs `f` with the given chain active, then restores English.
    pub fn with_chain<T>(tags: &[&str], f: impl FnOnce() -> T) -> T {
        let _exclusive = LANGUAGE.write().unwrap_or_else(|poisoned| poisoned.into_inner());
        let chain: Vec<&'static Locale> = tags.iter().map(|tag| catalog::find(tag).expect(tag)).collect();
        install(Catalog::new(&chain));
        let result = f();
        install(Catalog::new(&[catalog::source()]));
        result
    }

    /// Runs `f` while holding the language exclusively (for `activate`).
    pub fn exclusive<T>(f: impl FnOnce() -> T) -> T {
        let _exclusive = LANGUAGE.write().unwrap_or_else(|poisoned| poisoned.into_inner());
        let result = f();
        install(Catalog::new(&[catalog::source()]));
        result
    }
}

#[cfg(test)]
mod tests {
    use super::testing::{english, exclusive, with_chain};
    use super::*;

    #[test]
    fn text_falls_through_the_chain_and_never_shows_a_broken_message() {
        with_chain(&["pl"], || {
            assert_eq!(t!("common-cancel"), "Anuluj");
            // A missing translation falls back to the source, not the id.
            assert_ne!(t!("app-name"), "app-name");
        });
        with_chain(&["qps-ploc"], || {
            let text = t!("common-cancel");
            assert!(text.starts_with("Ċáñċéŀ"), "{text}");
        });
        english(|| {
            assert_eq!(t!("common-cancel"), "Cancel");
            assert_eq!(text("no-such-message", &[]), "no-such-message");
        });
    }

    #[test]
    fn plural_counts_select_the_right_form_and_format_regionally() {
        english(|| {
            assert_eq!(t!("security-count-still-on", count = 1u32), "1 still on");
            assert_eq!(t!("security-count-still-on", count = 2u32), "2 still on");
            assert_eq!(t!("log-earlier-lines", count = 1u32), "1 earlier line is in the log file.");
        });
        with_chain(&["pl"], || {
            for (count, expected) in
                [(1u32, "wiersz"), (2, "wiersze"), (5, "wierszy"), (22, "wiersze"), (12, "wierszy")]
            {
                let text = t!("log-earlier-lines", count = count);
                assert!(text.contains(expected), "{count}: {text}");
            }
        });
    }

    #[test]
    fn russian_duration_keeps_counts_ending_in_one() {
        with_chain(&["ru"], || {
            for (minutes, noun) in [
                (1u32, "минута"),
                (2, "минуты"),
                (5, "минут"),
                (21, "минута"),
                (22, "минуты"),
                (101, "минута"),
            ] {
                let summary = t!("summary-duration-value", minutes = minutes);
                assert!(summary.contains(&format!("{minutes} {noun}")), "{summary}");
                let introduction = t!("home-step-4-detail", minutes = minutes);
                assert!(introduction.contains(&minutes.to_string()), "{minutes}: {introduction}");
            }
        });
    }

    #[test]
    fn match_windows_recovers_after_a_failed_query_and_offers_previews_explicitly() {
        exclusive(|| {
            let failed = activate_with(&LanguagePreference::System, None, Err("boom".into()));
            assert_eq!(failed.decision, Decision::WindowsUnavailable("boom".into()));
            assert_eq!(failed.primary().tag, "en-GB");
            assert!(failed.follows_windows(), "a failed query must be retried on activation");

            // A later successful query with an English source language takes effect.
            let recovered = activate_with(&LanguagePreference::System, None, Ok(vec!["en-US".into()]));
            assert_eq!(recovered.decision, Decision::Windows);
            assert_eq!(recovered.primary().tag, "en-US");

            // A preview language is selected like any other; the shell's
            // notice, not the negotiation, tells the user it is a preview.
            let german =
                activate_with(&LanguagePreference::System, None, Ok(vec!["de-DE".into(), "en-US".into()]));
            assert_eq!(german.decision, Decision::Windows);
            assert_eq!(german.primary().tag, "de");
            assert!(german.primary().readiness < Readiness::Source);
            assert!(german.follows_windows());

            let nothing = activate_with(&LanguagePreference::System, None, Ok(vec!["xx-YY".into()]));
            assert_eq!(nothing.decision, Decision::WindowsUnmatched);
            let empty = activate_with(&LanguagePreference::System, None, Ok(vec![]));
            assert_eq!(empty.decision, Decision::WindowsUnmatched);

            // An explicit choice of a preview language is honoured, and does
            // not follow Windows.
            let chosen =
                activate_with(&LanguagePreference::Explicit("de".into()), None, Ok(vec!["en-US".into()]));
            assert_eq!(chosen.decision, Decision::Setting);
            assert_eq!(chosen.primary().tag, "de");
            assert!(!chosen.follows_windows());
            // The override is preserved whatever Windows says.
            let forced = activate_with(&LanguagePreference::System, Some("pl"), Err("boom".into()));
            assert_eq!(forced.primary().tag, "pl");
        });
    }

    #[test]
    fn the_decision_reports_how_the_language_was_chosen() {
        exclusive(|| {
            let windows = locale::ui_languages().unwrap_or_default();
            let state = activate(&LanguagePreference::System, None);
            assert!(!state.chain.is_empty());
            assert!(state.chain.iter().any(|l| l.tag == "en-GB"), "{:?}", state.chain);
            assert_eq!(state.windows_languages, windows);
            let german = activate(&LanguagePreference::Explicit("de".into()), None);
            assert_eq!(german.decision, Decision::Setting);
            assert_eq!(german.primary().tag, "de");
            let unknown = activate(&LanguagePreference::Explicit("xx".into()), None);
            assert_eq!(unknown.decision, Decision::SettingUnavailable("xx".into()));
            assert_eq!(unknown.primary().tag, "en-GB");
            let pseudo = activate(&LanguagePreference::System, Some("qps-ploc"));
            assert_eq!(pseudo.decision, Decision::Override("qps-ploc".into()));
            assert!(pseudo.primary().pseudo);
            let traditional = activate(&LanguagePreference::System, Some("zh-TW"));
            assert_eq!(traditional.primary().tag, "zh-Hant");
            assert!(traditional.font_fallbacks().is_some());
            assert_eq!(traditional.primary().direction, catalog::Direction::LeftToRight);
        });
    }
}

// Exercise the exact line-break helper used by our pinned GPUI patch.
#[cfg(test)]
#[path = "../../vendor/gpui-pre/src/text_system/complex_script_breaks.rs"]
mod complex_script_break_tests;
