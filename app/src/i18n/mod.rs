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
    /// The setting names a language the app includes.
    Setting,
    /// The setting names a language this build doesn't include; English is
    /// showing and the preference is kept as it was.
    SettingUnavailable(String),
    /// "Match Windows" found an included language in the display-language list.
    Windows,
    /// "Match Windows" found none of the display languages; English is showing.
    WindowsUnmatched,
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
            Decision::Windows | Decision::WindowsUnmatched | Decision::WindowsUnavailable(_)
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
    activate_with(preference, override_argument, current_windows_languages())
}

/// Environment variable that stands in for the Windows display-language
/// list for review and tests: a comma-separated list of tags, or `error` to
/// act as a failed query.
pub const WINDOWS_LANGUAGES_ENV: &str = "ATLAS_WINDOWS_LANGUAGES";

/// The Windows display-language list, or its stand-in from
/// [`WINDOWS_LANGUAGES_ENV`].
pub fn current_windows_languages() -> Result<Vec<String>, String> {
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

    let (decision, chain) = if let Some(tag) = override_tag(override_argument) {
        // Overrides may name any included language, even the pseudo-locale.
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
                    let chain = negotiate::negotiate(&requested, &listed);
                    let matched = chain.first().is_some_and(|first| serves_a_request(&requested, first));
                    (if matched { Decision::Windows } else { Decision::WindowsUnmatched }, chain)
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

/// Whether `locale` speaks one of the requested languages, so English that
/// ends the chain as the fallback is not mistaken for a Windows match.
fn serves_a_request(requested: &[LanguageIdentifier], locale: &Locale) -> bool {
    let language = locale.id().language;
    requested.iter().any(|request| request.language == language)
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
    fn text_comes_from_the_chain_and_an_unknown_id_shows_as_itself() {
        let cancel = english(|| t!("common-cancel"));
        with_chain(&["pl"], || assert_ne!(t!("common-cancel"), cancel));
        with_chain(&["qps-ploc"], || {
            let text = t!("common-cancel");
            assert!(text.starts_with("Ċáñċéŀ"), "{text}");
        });
        english(|| assert_eq!(text("no-such-message", &[]), "no-such-message"));
    }

    #[test]
    fn counts_reach_plural_selectors_as_numbers() {
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
    fn match_windows_recovers_after_a_failed_query_and_auto_selects_previews() {
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
            // Windows can list the pseudo-locale; it is never picked, or offered.
            let pseudo = activate_with(&LanguagePreference::System, None, Ok(vec!["qps-ploc".into()]));
            assert!(!pseudo.primary().pseudo);
            assert_eq!(pseudo.decision, Decision::WindowsUnmatched);
            let pseudo = activate_with(&LanguagePreference::Explicit("qps-ploc".into()), None, Ok(vec![]));
            assert_eq!(pseudo.decision, Decision::SettingUnavailable("qps-ploc".into()));

            // An explicit choice of a preview language is honoured, and does
            // not follow Windows.
            let chosen =
                activate_with(&LanguagePreference::Explicit("de".into()), None, Ok(vec!["en-US".into()]));
            assert_eq!(chosen.decision, Decision::Setting);
            assert_eq!(chosen.primary().tag, "de");
            assert!(!chosen.follows_windows());
            let unknown =
                activate_with(&LanguagePreference::Explicit("xx".into()), None, Ok(vec!["en-US".into()]));
            assert_eq!(unknown.decision, Decision::SettingUnavailable("xx".into()));
            assert_eq!(unknown.primary().tag, "en-GB");

            // The override is preserved whatever Windows says, and may name the pseudo-locale.
            let forced = activate_with(&LanguagePreference::System, Some("pl"), Err("boom".into()));
            assert_eq!(forced.primary().tag, "pl");
            let pseudo =
                activate_with(&LanguagePreference::System, Some("qps-ploc"), Ok(vec!["en-US".into()]));
            assert_eq!(pseudo.decision, Decision::Override("qps-ploc".into()));
            assert!(pseudo.primary().pseudo);
            let traditional =
                activate_with(&LanguagePreference::System, Some("zh-TW"), Ok(vec!["en-US".into()]));
            assert_eq!(traditional.primary().tag, "zh-Hant");
            assert!(traditional.font_fallbacks().is_some());
        });
    }
}

// The vendored GPUI's own tests don't build outside the Zed workspace, so
// the app runs its complex-script line-breaking tests here.
#[cfg(test)]
#[path = "../../vendor/gpui-pre/src/text_system/complex_script_breaks.rs"]
mod complex_script_break_tests;
#[cfg(test)]
mod line_breaks;
