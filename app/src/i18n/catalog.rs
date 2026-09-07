//! The shipped languages and their message catalogs.
//!
//! Every catalog is a Fluent file compiled into the executable, so the
//! translations are available offline, during elevation and inside the
//! installing window. A [`Catalog`] is an ordered chain of bundles: the
//! message is looked up in the first language, then each fallback, and
//! finally the English source, which is complete by construction (a test
//! enforces it).

use std::borrow::Cow;
use std::collections::HashSet;
use std::sync::Mutex;

use fluent_bundle::concurrent::FluentBundle;
use fluent_bundle::{FluentArgs, FluentError, FluentResource, FluentValue};
use unic_langid::LanguageIdentifier;

use super::pseudo;

/// Text direction of a language. The pinned GPUI renders left-to-right text
/// only (see `docs/i18n.md`), so a right-to-left locale would be excluded
/// from the language list; none ships yet.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Direction {
    LeftToRight,
    #[allow(dead_code)]
    RightToLeft,
}

/// How far a translation has come. Decides whether "Match Windows" may pick
/// it on its own; an explicit choice in Settings can pick any shipped
/// language and sees the readiness beside it.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Readiness {
    /// Translation awaiting native-speaker review. Labelled as a preview.
    Preview,
    /// English source copy and its regional variant; no review certification.
    Source,
}

/// The lowest readiness that "Match Windows" selects without being asked.
/// Preview translations are chosen like any other, so a user whose Windows
/// speaks the language sees Atlas in it; because no native speaker has
/// reviewed them, the shell shows a dismissible notice naming the preview
/// and offering English (see `AppModel::preview_notice`).
pub const AUTO_SELECT_MIN_READINESS: Readiness = Readiness::Preview;

/// A shipped language.
#[derive(Debug)]
pub struct Locale {
    /// BCP 47 tag; also the catalog directory under `i18n/`.
    pub tag: &'static str,
    /// The language's own name for itself, shown in the language list.
    pub native_name: &'static str,
    pub english_name: &'static str,
    pub direction: Direction,
    pub readiness: Readiness,
    /// Font families to try before the system fallback, so CJK text uses the
    /// glyph forms of its own language instead of whichever CJK font Windows
    /// picks for a Latin format locale.
    pub font_fallbacks: &'static [&'static str],
    /// The Fluent source.
    pub ftl: &'static str,
    /// A pseudo-locale: the English source passed through a transform, for
    /// layout testing. Never offered to users.
    pub pseudo: bool,
}

impl Locale {
    pub fn id(&self) -> LanguageIdentifier {
        self.tag.parse().expect("every shipped locale tag is a valid language identifier")
    }

    /// Whether "Match Windows" may select this locale on its own.
    pub fn auto_selectable(&self) -> bool {
        !self.pseudo
            && self.direction == Direction::LeftToRight
            && self.readiness >= AUTO_SELECT_MIN_READINESS
    }

    /// Whether the language appears in the Settings list.
    pub fn listed(&self) -> bool {
        !self.pseudo && self.direction == Direction::LeftToRight
    }
}

/// The complete English source every other catalog falls back to.
pub const SOURCE_TAG: &str = "en-GB";
/// The Windows pseudo-locale name for accented, expanded English.
pub const PSEUDO_TAG: &str = "qps-ploc";

const SOURCE_FTL: &str = include_str!("../../i18n/en-GB/atlas.ftl");

const CJK_HANS: &[&str] = &["Microsoft YaHei UI"];
const CJK_HANT: &[&str] = &["Microsoft JhengHei UI"];
const CJK_JA: &[&str] = &["Yu Gothic UI", "Meiryo UI"];

/// Every shipped locale, source first. Order matters for negotiation ties:
/// a request that matches several entries equally well takes the first.
pub static LOCALES: &[Locale] = &[
    Locale {
        tag: SOURCE_TAG,
        native_name: "English (United Kingdom)",
        english_name: "English (United Kingdom)",
        direction: Direction::LeftToRight,
        readiness: Readiness::Source,
        font_fallbacks: &[],
        ftl: SOURCE_FTL,
        pseudo: false,
    },
    Locale {
        tag: "en-US",
        native_name: "English (United States)",
        english_name: "English (United States)",
        direction: Direction::LeftToRight,
        readiness: Readiness::Source,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/en-US/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "de",
        native_name: "Deutsch",
        english_name: "German",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/de/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "es",
        native_name: "Español",
        english_name: "Spanish",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/es/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "fr",
        native_name: "Français",
        english_name: "French",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/fr/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "pt-BR",
        native_name: "Português (Brasil)",
        english_name: "Portuguese (Brazil)",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/pt-BR/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "pl",
        native_name: "Polski",
        english_name: "Polish",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/pl/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "ru",
        native_name: "Русский",
        english_name: "Russian",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/ru/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "tr",
        native_name: "Türkçe",
        english_name: "Turkish",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/tr/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "zh-Hans",
        native_name: "简体中文",
        english_name: "Chinese (Simplified)",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: CJK_HANS,
        ftl: include_str!("../../i18n/zh-Hans/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "zh-Hant",
        native_name: "繁體中文",
        english_name: "Chinese (Traditional)",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: CJK_HANT,
        ftl: include_str!("../../i18n/zh-Hant/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "ja",
        native_name: "日本語",
        english_name: "Japanese",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: CJK_JA,
        ftl: include_str!("../../i18n/ja/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "id",
        native_name: "Bahasa Indonesia",
        english_name: "Indonesian",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &[],
        ftl: include_str!("../../i18n/id/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "th",
        native_name: "ไทย",
        english_name: "Thai",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &["Leelawadee UI"],
        ftl: include_str!("../../i18n/th/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: "hi",
        native_name: "हिन्दी",
        english_name: "Hindi",
        direction: Direction::LeftToRight,
        readiness: Readiness::Preview,
        font_fallbacks: &["Nirmala UI"],
        ftl: include_str!("../../i18n/hi/atlas.ftl"),
        pseudo: false,
    },
    Locale {
        tag: PSEUDO_TAG,
        native_name: "Pseudo (accented, expanded)",
        english_name: "Pseudo-locale",
        direction: Direction::LeftToRight,
        readiness: Readiness::Source,
        font_fallbacks: &[],
        ftl: SOURCE_FTL,
        pseudo: true,
    },
];

pub fn source() -> &'static Locale {
    &LOCALES[0]
}

pub fn find(tag: &str) -> Option<&'static Locale> {
    LOCALES.iter().find(|locale| locale.tag.eq_ignore_ascii_case(tag))
}

/// A message argument. Numbers stay numbers so plural selectors see them;
/// the bundle's formatter renders them with the regional format.
#[derive(Clone, Debug, PartialEq)]
pub enum Arg {
    Text(String),
    Int(i64),
    Float(f64),
}

impl From<&str> for Arg {
    fn from(value: &str) -> Self {
        Arg::Text(value.to_owned())
    }
}
impl From<String> for Arg {
    fn from(value: String) -> Self {
        Arg::Text(value)
    }
}
impl From<&String> for Arg {
    fn from(value: &String) -> Self {
        Arg::Text(value.clone())
    }
}
impl From<u32> for Arg {
    fn from(value: u32) -> Self {
        Arg::Int(value as i64)
    }
}
impl From<u64> for Arg {
    fn from(value: u64) -> Self {
        Arg::Int(value.min(i64::MAX as u64) as i64)
    }
}
impl From<usize> for Arg {
    fn from(value: usize) -> Self {
        Arg::Int(value.min(i64::MAX as usize) as i64)
    }
}
impl From<i32> for Arg {
    fn from(value: i32) -> Self {
        Arg::Int(value as i64)
    }
}
impl From<i64> for Arg {
    fn from(value: i64) -> Self {
        Arg::Int(value)
    }
}
impl From<f64> for Arg {
    fn from(value: f64) -> Self {
        Arg::Float(value)
    }
}

impl Arg {
    pub(crate) fn fluent(&self) -> FluentValue<'_> {
        match self {
            Arg::Text(text) => FluentValue::String(Cow::Borrowed(text)),
            Arg::Int(value) => FluentValue::from(*value),
            Arg::Float(value) => FluentValue::from(*value),
        }
    }
}

struct Layer {
    tag: &'static str,
    bundle: FluentBundle<FluentResource>,
}

/// Parses a catalog's text into a bundle, returning the problems found
/// (syntax errors, duplicate ids) as text. The validation tests build every
/// shipped catalog this way, on its own, so a translation's own errors are
/// never masked by a fallback.
pub(crate) fn compile(
    id: LanguageIdentifier,
    ftl: &str,
    pseudo: bool,
) -> (FluentBundle<FluentResource>, Vec<String>) {
    let mut problems = Vec::new();
    let resource = match FluentResource::try_new(ftl.to_owned()) {
        Ok(resource) => resource,
        Err((resource, errors)) => {
            problems.extend(errors.iter().map(|error| format!("syntax error: {error:?}")));
            resource
        }
    };
    let mut bundle = FluentBundle::new_concurrent(vec![id]);
    if let Err(errors) = bundle.add_resource(resource) {
        problems.extend(errors.iter().map(|error| format!("duplicate entry: {error:?}")));
    }
    // Fluent can wrap interpolated values in FSI/PDI isolates for bidi
    // text. Every shipped language is left-to-right and the pinned GPUI
    // cannot shape right-to-left scripts, so the marks would only leak
    // into accessible names and copied text. Turn them on with the first
    // right-to-left locale.
    bundle.set_use_isolating(false);
    bundle.set_formatter(Some(super::fmt::fluent_number));
    if pseudo {
        bundle.set_transform(Some(pseudo::transform));
    }
    (bundle, problems)
}

/// An ordered chain of languages, first choice first, English source last.
pub struct Catalog {
    bundles: Vec<Layer>,
    reported: Mutex<HashSet<String>>,
}

impl std::fmt::Debug for Catalog {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_list().entries(self.bundles.iter().map(|b| b.tag)).finish()
    }
}

/// Fluent writes an unresolved placeable as `{$name}` or `{message-id}`.
/// When no catalog can format a message, the sentence is shown with those
/// parts elided instead of Fluent's syntax.
pub fn elide_placeables(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut depth = 0usize;
    for ch in text.chars() {
        match ch {
            '{' => {
                if depth == 0 {
                    out.push('\u{2026}');
                }
                depth += 1;
            }
            '}' => depth = depth.saturating_sub(1),
            _ if depth == 0 => out.push(ch),
            _ => {}
        }
    }
    out
}

/// Parses a locale's catalog into a bundle. Problems in a shipped catalog
/// are a defect the tests catch; at runtime the good entries are kept and
/// the rest fall through to the next language.
fn build_layer(locale: &'static Locale) -> Layer {
    let (bundle, problems) = compile(locale.id(), locale.ftl, locale.pseudo);
    for problem in problems {
        log::error!("the {} catalog: {problem}", locale.tag);
    }
    Layer { tag: locale.tag, bundle }
}

impl Catalog {
    /// Builds the chain. The source is always appended last if missing.
    pub fn new(chain: &[&'static Locale]) -> Self {
        let mut locales: Vec<&'static Locale> = Vec::new();
        for locale in chain {
            if !locales.iter().any(|known| std::ptr::eq(*known, *locale)) {
                locales.push(locale);
            }
        }
        if !locales.iter().any(|locale| locale.tag == SOURCE_TAG && !locale.pseudo) {
            locales.push(source());
        }
        Self { bundles: locales.into_iter().map(build_layer).collect(), reported: Mutex::new(HashSet::new()) }
    }

    /// A chain built from raw catalog text, for tests of the lookup policy.
    #[cfg(test)]
    pub(crate) fn from_texts(layers: &[(&'static str, &str)]) -> Self {
        let bundles = layers
            .iter()
            .map(|(tag, ftl)| Layer { tag, bundle: compile(tag.parse().unwrap(), ftl, false).0 })
            .collect();
        Self { bundles, reported: Mutex::new(HashSet::new()) }
    }

    /// The message's value in the given locale only, unformatted arguments
    /// aside. Used by the catalog validation tests.
    #[cfg(test)]
    pub fn plain(&self, locale_tag: &str, id: &str) -> Option<String> {
        let bundle = self.bundles.iter().find(|bundle| bundle.tag == locale_tag)?;
        let message = bundle.bundle.get_message(id)?;
        let pattern = message.value()?;
        let mut errors = Vec::new();
        let text = bundle.bundle.format_pattern(pattern, None, &mut errors);
        errors.is_empty().then(|| text.into_owned())
    }

    /// Formats a message (or one of its attributes). A language whose
    /// translation fails to format, for example because it references a
    /// message that does not exist, is skipped in favour of the next one.
    /// The tests keep every shipped catalog formatting cleanly on its own,
    /// so the only way every language can fail is a caller passing the
    /// wrong arguments; that case shows the sentence with the unresolved
    /// parts elided (never Fluent's `{...}` syntax), logs an error, and
    /// fails loudly in debug builds.
    pub fn format(&self, id: &str, attribute: Option<&str>, args: &[(&str, Arg)]) -> String {
        let fluent_args = if args.is_empty() {
            None
        } else {
            let mut fluent_args = FluentArgs::new();
            for (name, value) in args {
                fluent_args.set(*name, value.fluent());
            }
            Some(fluent_args)
        };
        let mut last_resort: Option<String> = None;
        for bundle in &self.bundles {
            let Some(message) = bundle.bundle.get_message(id) else { continue };
            let pattern = match attribute {
                Some(name) => message.get_attribute(name).map(|attribute| attribute.value()),
                None => message.value(),
            };
            let Some(pattern) = pattern else { continue };
            let mut errors: Vec<FluentError> = Vec::new();
            let text = bundle.bundle.format_pattern(pattern, fluent_args.as_ref(), &mut errors);
            if errors.is_empty() {
                return text.into_owned();
            }
            self.report(bundle.tag, id, attribute, &errors);
            last_resort.get_or_insert_with(|| text.into_owned());
        }
        if let Some(text) = last_resort {
            log::error!(
                "no catalog could format {id}{}; showing it with the unresolved parts elided",
                dotted(attribute)
            );
            debug_assert!(false, "no catalog could format {id}{} with {args:?}", dotted(attribute));
            return elide_placeables(&text);
        }
        self.report_missing(id, attribute);
        match attribute {
            Some(name) => format!("{id}.{name}"),
            None => id.to_owned(),
        }
    }

    fn report(&self, tag: &str, id: &str, attribute: Option<&str>, errors: &[FluentError]) {
        let key = format!("{tag}:{id}:{}", attribute.unwrap_or_default());
        if self.reported.lock().map(|mut seen| seen.insert(key)).unwrap_or(false) {
            log::warn!("{tag}: message {id}{} did not format cleanly: {errors:?}", dotted(attribute));
        }
    }

    fn report_missing(&self, id: &str, attribute: Option<&str>) {
        let key = format!("missing:{id}:{}", attribute.unwrap_or_default());
        if self.reported.lock().map(|mut seen| seen.insert(key)).unwrap_or(false) {
            log::error!("no catalog defines the message {id}{}", dotted(attribute));
        }
    }
}

fn dotted(attribute: Option<&str>) -> String {
    attribute.map(|name| format!(".{name}")).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_layer_that_fails_is_skipped_and_a_total_failure_is_elided_not_leaked() {
        let broken = "greeting = Hello { nonexistent-reference }\nplain = Plain\n";
        let good = "greeting = Hello { $name }\n";
        // The broken first layer is skipped for the message it breaks.
        let chain = Catalog::from_texts(&[("de", broken), ("en-GB", good)]);
        assert_eq!(chain.format("greeting", None, &[("name", Arg::Text("Ada".into()))]), "Hello Ada");
        assert_eq!(chain.format("plain", None, &[]), "Plain");
        // Nothing valid anywhere: no `{...}` reaches the screen.
        let alone = Catalog::from_texts(&[("de", broken)]);
        let shown =
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| alone.format("greeting", None, &[])));
        if cfg!(debug_assertions) {
            assert!(shown.is_err(), "debug builds fail loudly");
        } else {
            let shown = shown.unwrap();
            assert!(!shown.contains('{') && !shown.contains('}'), "{shown}");
            assert!(shown.starts_with("Hello"), "{shown}");
        }
        assert_eq!(elide_placeables("Atlas {$version} is available"), "Atlas \u{2026} is available");
        assert_eq!(elide_placeables("no braces"), "no braces");
        assert_eq!(elide_placeables("{a{b}c}"), "\u{2026}");
    }
}
