//! Regional formatting of numbers, dates and times. These follow the Windows
//! regional format (with the user's customisations), not the app language,
//! because Windows treats them as separate settings and so do users.
//!
//! `ATLAS_FORMAT_LOCALE=<tag>` overrides the format locale for review, so a
//! German number format can be checked on an English machine.
//!
//! The pinned GPUI cannot draw right-to-left text (see `docs/i18n.md`), so a
//! date, time or locale name that Windows gives in a right-to-left script is
//! replaced: dates and times by a standard numeric form, the name by its
//! English form. Numbers keep the regional format; their digits and
//! separators are never right-to-left.

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

/// Whether text has characters of a right-to-left script: Hebrew, Arabic,
/// Syriac, Thaana, N'Ko and their neighbours, the Hebrew and Arabic
/// presentation forms, and the right-to-left blocks beyond the BMP, such as
/// Adlam.
fn shows_rtl(text: &str) -> bool {
    text.chars().any(|c| {
        matches!(
            u32::from(c),
            0x0590..=0x08FF | 0xFB1D..=0xFDFF | 0xFE70..=0xFEFF | 0x10800..=0x10FFF | 0x1E800..=0x1EFFF
        )
    })
}

/// The regional format locale's tag.
pub fn format_locale_tag() -> String {
    locale_tag_in(format_locale())
}

fn locale_tag_in(locale: &LocaleName) -> String {
    match locale {
        LocaleName::Named(name) => name.clone(),
        LocaleName::UserDefault => locale::user_format_locale().unwrap_or_else(|| "en-US".to_owned()),
    }
}

/// The locale's own name for itself, or its English name when its own is
/// right-to-left.
fn locale_name_in(locale: &LocaleName) -> String {
    locale::display_name(locale, true)
        .filter(|name| !shows_rtl(name))
        .or_else(|| locale::display_name(locale, false))
        .unwrap_or_else(|| locale_tag_in(locale))
}

/// The regional format locale's own name for itself, for the Settings page.
pub fn format_locale_name() -> String {
    locale_name_in(format_locale())
}

/// Whether dates and times show as the regional format has them; false
/// when that format writes them right to left, so they fall back.
pub fn dates_follow_region() -> bool {
    let now = local_parts(&Local::now());
    let locale = format_locale();
    ![locale::format_date(locale, &now), locale::format_time(locale, &now)]
        .iter()
        .flatten()
        .any(|text| shows_rtl(text))
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

const MIB: f64 = 1024. * 1024.;

/// Bytes as a number of MB with one decimal, regional separators.
pub fn megabytes_value(bytes: u64) -> String {
    decimal(bytes as f64 / MIB, 1)
}

/// The unit a file size is shown in: whole megabytes below a gigabyte and
/// gigabytes with one decimal from there, as Windows does. Binary units,
/// matching Explorer.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SizeUnit {
    Megabytes,
    Gigabytes,
}

impl SizeUnit {
    /// The unit for `bytes`. A pair such as "done of total" uses the total's.
    pub fn of(bytes: u64) -> Self {
        // Anything that would round to 1,024 MB is shown as 1.0 GB instead.
        if (bytes as f64 / MIB).round() >= 1024. { Self::Gigabytes } else { Self::Megabytes }
    }

    /// `bytes` as a number in this unit, with regional separators.
    pub fn value(self, bytes: u64) -> String {
        match self {
            Self::Megabytes => decimal(bytes as f64 / MIB, 0),
            Self::Gigabytes => decimal(bytes as f64 / (MIB * 1024.), 1),
        }
    }
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
    long_date_in(format_locale(), when)
}

fn long_date_in(locale: &LocaleName, when: &DateTime<Local>) -> String {
    locale::format_date(locale, &local_parts(when))
        .filter(|text| !shows_rtl(text))
        .unwrap_or_else(|| when.format("%Y-%m-%d").to_string())
}

/// A calendar day, such as an end-of-support date, as [`long_date`] words it.
pub fn day(date: chrono::NaiveDate) -> String {
    use chrono::TimeZone;
    match date.and_hms_opt(12, 0, 0).and_then(|noon| Local.from_local_datetime(&noon).single()) {
        Some(when) => long_date(&when),
        None => date.format("%Y-%m-%d").to_string(),
    }
}

/// "20:13" or "8:13 PM", as the regional format has it.
pub fn time(when: &DateTime<Local>) -> String {
    time_in(format_locale(), when)
}

fn time_in(locale: &LocaleName, when: &DateTime<Local>) -> String {
    locale::format_time(locale, &local_parts(when))
        .filter(|text| !shows_rtl(text))
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
fn needed_fraction_digits(value: f64, min: usize, max: usize) -> usize {
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
    fn right_to_left_scripts_are_recognised() {
        assert!(shows_rtl("עברית"));
        assert!(shows_rtl("08:13 م"));
        assert!(shows_rtl("ދިވެހި"), "Thaana");
        assert!(shows_rtl("\u{1E900}"), "Adlam, beyond the BMP");
        assert!(!shows_rtl("21 October 2025, 20:13"));
        assert!(!shows_rtl("2025年10月21日"));
        assert!(!shows_rtl("21 ตุลาคม 2568"));
        assert!(!shows_rtl("२१ अक्टूबर २०२५"));
    }

    #[test]
    fn right_to_left_regional_formats_fall_back_to_forms_atlas_can_draw() {
        use chrono::TimeZone;
        let named = |tag: &str| LocaleName::Named(tag.to_owned());
        let when = Local.with_ymd_and_hms(2025, 10, 21, 20, 13, 5).single().unwrap();
        for tag in ["ar-SA", "ar-EG", "he-IL", "fa-IR", "ur-PK", "ckb-IQ", "dv-MV", "syr-SY"] {
            for text in
                [long_date_in(&named(tag), &when), time_in(&named(tag), &when), locale_name_in(&named(tag))]
            {
                assert!(!shows_rtl(&text), "{tag}: {text}");
            }
        }
        assert_eq!(long_date_in(&named("ar-SA"), &when), "2025-10-21");
        assert_eq!(locale_name_in(&named("he-IL")), "Hebrew (Israel)");
        // The fallback is per string: a right-to-left locale whose time is already Latin keeps it.
        assert_eq!(time_in(&named("he-IL"), &when), "20:13");
        // Left-to-right formats are unchanged.
        assert_eq!(long_date_in(&named("en-GB"), &when), "21 October 2025");
    }

    #[test]
    fn sizes_move_to_gigabytes_at_a_gigabyte() {
        const MB: u64 = 1024 * 1024;
        assert_eq!(SizeUnit::of(900 * MB), SizeUnit::Megabytes);
        assert_eq!(SizeUnit::of(1023 * MB), SizeUnit::Megabytes);
        assert_eq!(SizeUnit::of(1024 * MB - 1), SizeUnit::Gigabytes, "it would round to 1,024 MB");
        assert_eq!(SizeUnit::of(1024 * MB), SizeUnit::Gigabytes);
        let whole = SizeUnit::Megabytes.value(900 * MB);
        assert_eq!(whole, "900", "no decimal below a gigabyte");
        let gb = SizeUnit::Gigabytes.value(1536 * MB);
        assert!(gb.len() == 3 && gb.starts_with('1') && gb.ends_with('5'), "{gb}");
        // Download progress counts binary megabytes, as Explorer does.
        let mb = megabytes_value(1536 * 1024);
        assert!(mb.len() == 3 && mb.starts_with('1') && mb.ends_with('5'), "{mb}");
        // A progress pair shares its total's unit, so the smaller value stays in GB.
        let done = SizeUnit::of(1536 * MB).value(512 * MB);
        assert!(done.len() == 3 && done.starts_with('0') && done.ends_with('5'), "{done}");
    }
}
