//! Picks the language chain for a list of requested languages.
//!
//! Matching is CLDR-aware (likely subtags), so `zh-TW` and `zh-HK` resolve
//! to Traditional Chinese and `zh-CN` and `zh` to Simplified; scripts are
//! never crossed by accident. A regional request (`pt-PT`, `fr-CA`, `en-AU`)
//! takes the closest shipped variant of its language. The English source
//! always ends the chain.

use fluent_langneg::{NegotiationStrategy, negotiate_languages};
use unic_langid::LanguageIdentifier;

use super::catalog::{self, Locale};

/// English regions whose spelling follows British usage. Windows itself
/// falls these back to en-GB before en-US; CLDR's likely subtags would
/// send a bare "en" to en-US, so the preference is stated here.
const BRITISH_SPELLING_REGIONS: &[&str] = &[
    "GB", "IE", "AU", "NZ", "IN", "ZA", "SG", "MY", "HK", "PK", "NG", "KE", "GH", "MT", "CY", "JE", "GG",
    "IM",
];

/// A shipped variant to try first for a request, before the general
/// negotiation, when the general rules would pick a poorer match.
fn preferred_variant(request: &LanguageIdentifier, available: &[&'static Locale]) -> Option<&'static Locale> {
    if request.language.as_str() == "en"
        && let Some(region) = request.region
        && BRITISH_SPELLING_REGIONS.contains(&region.as_str())
    {
        return available.iter().copied().find(|locale| locale.tag == "en-GB");
    }
    None
}

/// Shipped locales that share a language and script with `locale`: regional
/// overlays of one another (en-US over en-GB), which must stay adjacent so a
/// message missing from the overlay comes from its base, never from a
/// later language in the Windows list. Scripts are never crossed.
fn same_language_and_script(locale: &Locale, available: &[&'static Locale]) -> Vec<&'static Locale> {
    let mut own = locale.id();
    own.maximize();
    available
        .iter()
        .copied()
        .filter(|candidate| {
            let mut id = candidate.id();
            id.maximize();
            !std::ptr::eq(*candidate, locale) && id.language == own.language && id.script == own.script
        })
        .collect()
}

/// The ordered chain for `requested`, chosen from `available`, ending with
/// the source. `available` order breaks ties, so list preferred variants
/// first.
pub fn negotiate(requested: &[LanguageIdentifier], available: &[&'static Locale]) -> Vec<&'static Locale> {
    let source = catalog::source();
    // Fluent's bundles still use unic-langid; langneg 0.14 negotiates with
    // ICU identifiers. Convert at this boundary, once per language change.
    let ids: Vec<fluent_langneg::LanguageIdentifier> =
        available.iter().map(|locale| locale.tag.parse().expect("valid shipped locale")).collect();

    let mut ordered: Vec<&'static Locale> = Vec::new();
    let push = |locale: &'static Locale, ordered: &mut Vec<&'static Locale>| {
        if !ordered.iter().any(|known| std::ptr::eq(*known, locale)) {
            ordered.push(locale);
        }
    };
    // One request at a time, so the Windows list's order is kept exactly:
    // an explicit regional preference, then the CLDR-aware matches.
    for request in requested {
        if let Some(locale) = preferred_variant(request, available) {
            push(locale, &mut ordered);
        }
        let Ok(request) = request.to_string().parse::<fluent_langneg::LanguageIdentifier>() else {
            continue;
        };
        let matched =
            negotiate_languages(std::slice::from_ref(&request), &ids, None, NegotiationStrategy::Matching);
        for id in matched {
            if let Some(index) = ids.iter().position(|candidate| candidate == id) {
                push(available[index], &mut ordered);
            }
        }
    }
    push(source, &mut ordered);

    // Keep each language's regional variants together, right after the
    // first one that was chosen. The source is complete on its own, so
    // nothing needs to follow it.
    let mut chain: Vec<&'static Locale> = Vec::new();
    for locale in &ordered {
        push(locale, &mut chain);
        if !std::ptr::eq(*locale, source) {
            for sibling in same_language_and_script(locale, available) {
                push(sibling, &mut chain);
            }
        }
    }
    push(source, &mut chain);
    chain
}

/// Parses language tags leniently: anything Windows or a settings file
/// produces that is not a language identifier is skipped, not fatal.
pub fn parse_tags<'a>(tags: impl IntoIterator<Item = &'a str>) -> Vec<LanguageIdentifier> {
    tags.into_iter().filter_map(|tag| tag.trim().parse::<LanguageIdentifier>().ok()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::i18n::catalog::LOCALES;

    /// The pool an explicit choice (and the preview hint) negotiates against.
    fn listed() -> Vec<&'static Locale> {
        LOCALES.iter().filter(|locale| locale.listed()).collect()
    }

    fn chain(requested: &[&str]) -> Vec<&'static str> {
        negotiate(&parse_tags(requested.iter().copied()), &listed())
            .into_iter()
            .map(|locale| locale.tag)
            .collect()
    }

    #[test]
    fn match_windows_negotiates_against_every_real_language() {
        use crate::i18n::catalog::Readiness;
        let auto: Vec<&'static Locale> = LOCALES.iter().filter(|locale| locale.auto_selectable()).collect();
        assert!(auto.iter().all(|locale| locale.readiness >= Readiness::Preview && !locale.pseudo));
        assert!(auto.iter().any(|locale| locale.tag == "en-GB"));
        // A preview translation is reachable automatically; the shell announces it.
        let german = negotiate(&parse_tags(["de-DE"]), &auto);
        assert_eq!(german.iter().map(|l| l.tag).collect::<Vec<_>>(), ["de", "en-GB"]);
    }

    #[test]
    fn chinese_requests_keep_their_script() {
        assert_eq!(chain(&["zh-TW"]), ["zh-Hant", "en-GB"]);
        assert_eq!(chain(&["zh-HK"]), ["zh-Hant", "en-GB"]);
        assert_eq!(chain(&["zh-MO"]), ["zh-Hant", "en-GB"]);
        assert_eq!(chain(&["zh-Hant-TW"]), ["zh-Hant", "en-GB"]);
        assert_eq!(chain(&["zh-CN"]), ["zh-Hans", "en-GB"]);
        assert_eq!(chain(&["zh-SG"]), ["zh-Hans", "en-GB"]);
        assert_eq!(chain(&["zh"]), ["zh-Hans", "en-GB"]);
        // A Traditional Chinese user with English second never sees Simplified.
        assert_eq!(chain(&["zh-TW", "en-US"]), ["zh-Hant", "en-US", "en-GB"]);
        assert_eq!(chain(&["zh-Hans"]), ["zh-Hans", "en-GB"], "Simplified never pulls in Traditional");
    }

    #[test]
    fn regional_requests_take_the_shipped_variant_of_their_language() {
        assert_eq!(chain(&["id-ID"]), ["id", "en-GB"]);
        assert_eq!(chain(&["th-TH"]), ["th", "en-GB"]);
        assert_eq!(chain(&["hi-IN"]), ["hi", "en-GB"]);
        assert_eq!(chain(&["pt-PT"]), ["pt-BR", "en-GB"]);
        assert_eq!(chain(&["pt"]), ["pt-BR", "en-GB"]);
        assert_eq!(chain(&["fr-CA"]), ["fr", "en-GB"]);
        assert_eq!(chain(&["es-MX"]), ["es", "en-GB"]);
        assert_eq!(chain(&["de-AT"]), ["de", "en-GB"]);
        assert_eq!(chain(&["de-CH", "fr-CH"]), ["de", "fr", "en-GB"]);
        assert_eq!(chain(&["ja-JP"]), ["ja", "en-GB"]);
        assert_eq!(chain(&["tr-TR"]), ["tr", "en-GB"]);
        assert_eq!(chain(&["ru-RU"]), ["ru", "en-GB"]);
        assert_eq!(chain(&["pl-PL"]), ["pl", "en-GB"]);
    }

    #[test]
    fn english_variants_resolve_to_the_right_spelling() {
        assert_eq!(chain(&["en-US"]), ["en-US", "en-GB"]);
        assert_eq!(chain(&["en-GB"]), ["en-GB"]);
        assert_eq!(chain(&["en"]), ["en-US", "en-GB"], "bare English maximises to en-US");
        assert_eq!(chain(&["en-AU"]), ["en-GB", "en-US"], "British spelling regions take en-GB");
        assert_eq!(chain(&["en-IN"]), ["en-GB", "en-US"]);
        assert_eq!(chain(&["en-CA"]), ["en-US", "en-GB"]);
        assert_eq!(chain(&["en-PH"]), ["en-US", "en-GB"]);
    }

    #[test]
    fn unsupported_and_malformed_requests_fall_back_to_english() {
        assert_eq!(chain(&["xx-YY"]), ["en-GB"]);
        assert_eq!(chain(&["ar-SA"]), ["en-GB"], "no right-to-left catalog is shipped");
        assert_eq!(chain(&[]), ["en-GB"]);
        assert_eq!(chain(&["xx-YY", "pl-PL"]), ["pl", "en-GB"], "the next Windows language is used");
        assert_eq!(chain(&["not a tag!!", "de-DE"]), ["de", "en-GB"]);
        assert_eq!(chain(&["", "  "]), ["en-GB"]);
    }

    #[test]
    fn ordered_windows_lists_are_honoured() {
        assert_eq!(chain(&["pl-PL", "de-DE", "en-US"]), ["pl", "de", "en-US", "en-GB"]);
        assert_eq!(
            chain(&["en-US", "de-DE"]),
            ["en-US", "en-GB", "de"],
            "an overlay's base follows it at once"
        );
        assert_eq!(chain(&["de-DE", "en-US"]), ["de", "en-US", "en-GB"]);
        assert_eq!(
            chain(&["zh-TW", "zh-CN"]),
            ["zh-Hant", "zh-Hans", "en-GB"],
            "different scripts stay apart"
        );
    }

    #[test]
    fn scripts_are_never_crossed_even_for_the_same_language() {
        // Serbian is not shipped; this checks the negotiation rule itself with
        // synthetic locales so a future sr-Latn/sr-Cyrl pair behaves.
        use crate::i18n::catalog::{Direction, Readiness};
        static SR: [Locale; 2] = [
            Locale {
                tag: "sr-Cyrl",
                native_name: "",
                english_name: "",
                direction: Direction::LeftToRight,
                readiness: Readiness::Source,
                font_fallbacks: &[],
                ftl: "",
                pseudo: false,
            },
            Locale {
                tag: "sr-Latn",
                native_name: "",
                english_name: "",
                direction: Direction::LeftToRight,
                readiness: Readiness::Source,
                font_fallbacks: &[],
                ftl: "",
                pseudo: false,
            },
        ];
        let available: Vec<&'static Locale> = SR.iter().collect();
        let tags = |requested: &[&str]| -> Vec<&'static str> {
            negotiate(&parse_tags(requested.iter().copied()), &available).into_iter().map(|l| l.tag).collect()
        };
        assert_eq!(tags(&["sr-Latn-RS"]), ["sr-Latn", "en-GB"]);
        assert_eq!(tags(&["sr-Cyrl-RS"]), ["sr-Cyrl", "en-GB"]);
        assert_eq!(tags(&["sr"]), ["sr-Cyrl", "en-GB"], "bare Serbian maximises to Cyrillic");
        assert_eq!(tags(&["sr-ME"]), ["sr-Latn", "en-GB"], "Montenegro maximises to Latin");
    }

    #[test]
    fn the_pseudo_locale_is_never_chosen_automatically() {
        assert_eq!(chain(&["qps-ploc"]), ["en-GB"]);
        assert!(
            catalog::find("qps-ploc").is_some_and(|locale| !locale.auto_selectable() && !locale.listed())
        );
    }
}
