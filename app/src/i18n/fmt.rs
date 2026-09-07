//! Regional formatting of numbers, dates and times. These follow the Windows
//! regional format (with the user's customisations), not the app language,
//! because Windows treats them as separate settings and so do users.
//!
//! `ATLAS_FORMAT_LOCALE=<tag>` overrides the format locale for review, so a
//! German number format can be checked on an English machine.

use std::sync::OnceLock;

use chrono::{DateTime, Datelike, Local, Timelike};
use fluent_bundle::FluentValue;

use crate::services::locale::{self, LocalDateTime, LocaleName};

fn format_locale() -> &'static LocaleName {
    static LOCALE: OnceLock<LocaleName> = OnceLock::new();
    LOCALE.get_or_init(|| match std::env::var("ATLAS_FORMAT_LOCALE") {
        Ok(name) if !name.trim().is_empty() => LocaleName::Named(name.trim().to_owned()),
        _ => LocaleName::UserDefault,
    })
}

/// The regional format locale's tag, for the Settings page.
pub fn format_locale_tag() -> String {
    match format_locale() {
        LocaleName::Named(name) => name.clone(),
        LocaleName::UserDefault => locale::user_format_locale().unwrap_or_else(|| "en-US".to_owned()),
    }
}

/// The regional format locale's own name for itself.
pub fn format_locale_name() -> String {
    locale::display_name(format_locale(), true).unwrap_or_else(format_locale_tag)
}

/// A whole number with the regional grouping: "1,234" or "1.234" or "1 234".
pub fn integer(value: u64) -> String {
    locale::format_number(format_locale(), value as f64, 0).unwrap_or_else(|| value.to_string())
}

/// A decimal with a fixed number of fraction digits.
pub fn decimal(value: f64, fraction_digits: usize) -> String {
    locale::format_number(format_locale(), value, fraction_digits)
        .unwrap_or_else(|| format!("{value:.fraction_digits$}"))
}

/// Bytes as a number of MB with one decimal, regional separators.
pub fn megabytes_value(bytes: u64) -> String {
    decimal(bytes as f64 / (1024. * 1024.), 1)
}

fn local_parts(when: &DateTime<Local>) -> LocalDateTime {
    LocalDateTime {
        year: when.year(),
        month: when.month(),
        day: when.day(),
        weekday_sunday_zero: when.weekday().num_days_from_sunday(),
        hour: when.hour(),
        minute: when.minute(),
        second: when.second(),
    }
}

/// "21 October 2025" (en-GB), "October 21, 2025" (en-US), "21. Oktober 2025" (de).
pub fn long_date(when: &DateTime<Local>) -> String {
    locale::format_date(format_locale(), &local_parts(when))
        .unwrap_or_else(|| when.format("%Y-%m-%d").to_string())
}

/// "20:13" or "8:13 PM", as the regional format has it.
pub fn time(when: &DateTime<Local>) -> String {
    locale::format_time(format_locale(), &local_parts(when))
        .unwrap_or_else(|| when.format("%H:%M").to_string())
}

/// Date and time together, for history rows where two installs on one day
/// need telling apart.
pub fn date_time(when: &DateTime<Local>) -> String {
    format!("{}, {}", long_date(when), time(when))
}

/// Parses an RFC 3339 timestamp from a state document or release record.
pub fn parse_local(iso: &str) -> Option<DateTime<Local>> {
    DateTime::parse_from_rfc3339(iso).ok().map(|when| when.with_timezone(&Local))
}

/// The number formatter every Fluent bundle uses for `{ $count }`-style
/// placeables: the plural selector still sees the raw number, and the text
/// shows it in the user's regional format.
pub fn fluent_number<M>(value: &FluentValue<'_>, _memoizer: &M) -> Option<String> {
    let FluentValue::Number(number) = value else { return None };
    let options = &number.options;
    let min = options.minimum_fraction_digits.unwrap_or(0);
    let max = options.maximum_fraction_digits.unwrap_or(min.max(3));
    let digits = needed_fraction_digits(number.value, min, max);
    Some(decimal(number.value, digits))
}

/// The fewest fraction digits in `min..=max` that show the value exactly
/// (as far as `max` digits can).
pub fn needed_fraction_digits(value: f64, min: usize, max: usize) -> usize {
    let max = max.max(min);
    let scaled_max = (value * 10f64.powi(max as i32)).round();
    for digits in min..max {
        let scaled = (value * 10f64.powi(digits as i32)).round() * 10f64.powi((max - digits) as i32);
        if (scaled - scaled_max).abs() < 0.5 {
            return digits;
        }
    }
    max
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fraction_digits_are_the_fewest_that_show_the_value() {
        assert_eq!(needed_fraction_digits(12., 0, 3), 0);
        assert_eq!(needed_fraction_digits(12.5, 0, 3), 1);
        assert_eq!(needed_fraction_digits(12.25, 0, 3), 2);
        assert_eq!(needed_fraction_digits(12.2506, 0, 3), 3);
        assert_eq!(needed_fraction_digits(12., 2, 3), 2, "the minimum is respected");
        assert_eq!(needed_fraction_digits(12.5, 0, 0), 0);
    }

    #[test]
    fn regional_formatting_never_fails_outright() {
        // Whatever the machine's regional format, these produce something sensible.
        let text = integer(1234567);
        assert!(text.contains("1") && text.contains("567"), "{text}");
        let mb = megabytes_value(1536 * 1024);
        assert!(mb.contains("1") && mb.contains("5"), "{mb}");
        let when = parse_local("2025-10-21T20:13:05+00:00").unwrap();
        assert!(long_date(&when).contains("2025"));
        assert!(!time(&when).is_empty());
        assert!(parse_local("not a date").is_none());
    }
}
