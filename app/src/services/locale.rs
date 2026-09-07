//! What Windows says about language and region: the user's ordered display
//! languages (for choosing the app language) and the regional format locale
//! (for numbers, dates and times). The two are independent settings in
//! Windows and stay independent here: someone can read an English UI with
//! German number formats, and Atlas preserves that.
//!
//! Everything here is a thin, checked adapter over the Win32 NLS APIs. It
//! never guesses from the keyboard layout, the install language or a LANGID.

use anyhow::{Context, Result};
use windows::Win32::Foundation::{ERROR_INSUFFICIENT_BUFFER, LPARAM, SYSTEMTIME};
use windows::Win32::Globalization::{
    DATE_LONGDATE, EnumDateFormatsExEx, GetDateFormatEx, GetLocaleInfoEx, GetNumberFormatEx, GetTimeFormatEx,
    GetUserDefaultLocaleName, GetUserPreferredUILanguages, LOCALE_ILZERO, LOCALE_INEGNUMBER, LOCALE_SDECIMAL,
    LOCALE_SENGLISHDISPLAYNAME, LOCALE_SGROUPING, LOCALE_SLONGDATE, LOCALE_SNATIVEDISPLAYNAME,
    LOCALE_STHOUSAND, MUI_LANGUAGE_NAME, NUMBERFMTW, TIME_NOSECONDS,
};
use windows::core::BOOL;
use windows::core::{HSTRING, PCWSTR, PWSTR};

/// `LOCALE_NAME_MAX_LENGTH` from the Windows SDK: the longest locale name, with its terminator.
const LOCALE_NAME_MAX_LENGTH: usize = 85;

/// A locale name for the NLS functions: an explicit BCP 47 name, or the
/// user's regional format (Settings > Time & language > Language & region >
/// Regional format), including any customisations made there.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum LocaleName {
    #[default]
    UserDefault,
    Named(String),
}

impl LocaleName {
    fn as_hstring(&self) -> Option<HSTRING> {
        match self {
            LocaleName::UserDefault => None,
            LocaleName::Named(name) => Some(HSTRING::from(name.as_str())),
        }
    }
}

/// Calls `f` with the PCWSTR for a locale name (null for the user default).
fn with_locale<T>(locale: &LocaleName, f: impl FnOnce(PCWSTR) -> T) -> T {
    match locale.as_hstring() {
        Some(name) => f(PCWSTR(name.as_ptr())),
        None => f(PCWSTR::null()),
    }
}

/// The user's display languages in preference order, as BCP 47 names
/// (for example `["de-DE", "en-US"]`). This is the "Windows display
/// language" list, the same one Windows itself uses to pick a UI language.
pub fn ui_languages() -> Result<Vec<String>> {
    // Two-call sizing with a bounded retry, because the list can change
    // between the size query and the read.
    for _ in 0..4 {
        let mut count = 0u32;
        let mut size = 0u32;
        unsafe { GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &mut count, None, &mut size) }
            .context("ask Windows for the display language list size")?;
        let mut buffer = vec![0u16; size as usize];
        match unsafe {
            GetUserPreferredUILanguages(
                MUI_LANGUAGE_NAME,
                &mut count,
                Some(PWSTR(buffer.as_mut_ptr())),
                &mut size,
            )
        } {
            Ok(()) => return Ok(split_multi_sz(&buffer[..(size as usize).min(buffer.len())])),
            Err(error) if error.code() == ERROR_INSUFFICIENT_BUFFER.to_hresult() => continue,
            Err(error) => return Err(error).context("read the Windows display language list"),
        }
    }
    anyhow::bail!("the Windows display language list kept changing while it was read")
}

/// Splits a double-NUL-terminated UTF-16 list into strings, dropping empties
/// and anything that is not valid UTF-16.
fn split_multi_sz(buffer: &[u16]) -> Vec<String> {
    buffer
        .split(|unit| *unit == 0)
        .filter(|part| !part.is_empty())
        .filter_map(|part| String::from_utf16(part).ok())
        .collect()
}

/// The regional format locale (`GetUserDefaultLocaleName`), such as `en-GB`.
pub fn user_format_locale() -> Option<String> {
    let mut buffer = [0u16; LOCALE_NAME_MAX_LENGTH];
    let written = unsafe { GetUserDefaultLocaleName(&mut buffer) };
    if written <= 0 {
        return None;
    }
    String::from_utf16(&buffer[..(written as usize).saturating_sub(1)]).ok().filter(|name| !name.is_empty())
}

fn locale_info(locale: &LocaleName, kind: u32) -> Option<String> {
    with_locale(locale, |name| {
        let needed = unsafe { GetLocaleInfoEx(name, kind, None) };
        if needed <= 0 {
            return None;
        }
        let mut buffer = vec![0u16; needed as usize];
        let written = unsafe { GetLocaleInfoEx(name, kind, Some(&mut buffer)) };
        if written <= 0 {
            return None;
        }
        String::from_utf16(&buffer[..(written as usize).saturating_sub(1)]).ok()
    })
}

/// How the locale calls itself ("Deutsch (Deutschland)"), or in English.
pub fn display_name(locale: &LocaleName, native: bool) -> Option<String> {
    locale_info(locale, if native { LOCALE_SNATIVEDISPLAYNAME } else { LOCALE_SENGLISHDISPLAYNAME })
}

/// `LOCALE_SGROUPING` ("3;0", "3;2;0", "3") as the `NUMBERFMT.Grouping`
/// number the formatter wants (3, 32, 30).
pub fn grouping_from_locale_string(grouping: &str) -> u32 {
    let parts: Vec<u32> = grouping.split(';').filter_map(|part| part.trim().parse().ok()).collect();
    let (digits, repeats) = match parts.split_last() {
        Some((0, rest)) => (rest, true),
        Some((_, _)) => (parts.as_slice(), false),
        None => return 3,
    };
    if digits.is_empty() {
        return 0;
    }
    let mut value = 0u32;
    for digit in digits {
        value = value * 10 + digit.min(&9);
    }
    if repeats { value } else { value * 10 }
}

/// Formats a decimal number with exactly `fraction_digits` decimals, using the
/// locale's separators, grouping and negative style, with the user's
/// overrides. `None` when Windows cannot format it.
pub fn format_number(locale: &LocaleName, value: f64, fraction_digits: usize) -> Option<String> {
    if !value.is_finite() {
        return None;
    }
    let decimal = HSTRING::from(locale_info(locale, LOCALE_SDECIMAL)?);
    let thousand = HSTRING::from(locale_info(locale, LOCALE_STHOUSAND)?);
    let grouping = grouping_from_locale_string(&locale_info(locale, LOCALE_SGROUPING)?);
    let negative_order = locale_info(locale, LOCALE_INEGNUMBER)?.trim().parse().unwrap_or(1);
    let leading_zero = locale_info(locale, LOCALE_ILZERO)?.trim().parse().unwrap_or(1);
    let format = NUMBERFMTW {
        NumDigits: fraction_digits as u32,
        LeadingZero: leading_zero,
        Grouping: grouping,
        lpDecimalSep: PWSTR(decimal.as_ptr() as *mut u16),
        lpThousandSep: PWSTR(thousand.as_ptr() as *mut u16),
        NegativeOrder: negative_order,
    };
    // The input must be culture-invariant: '.' decimal, '-' sign, no grouping.
    let text = HSTRING::from(format!("{value:.fraction_digits$}"));
    with_locale(locale, |name| {
        let needed = unsafe {
            GetNumberFormatEx(name, 0, PCWSTR(text.as_ptr()), Some(&format as *const NUMBERFMTW), None)
        };
        if needed <= 0 {
            return None;
        }
        let mut buffer = vec![0u16; needed as usize];
        let written = unsafe {
            GetNumberFormatEx(
                name,
                0,
                PCWSTR(text.as_ptr()),
                Some(&format as *const NUMBERFMTW),
                Some(&mut buffer),
            )
        };
        if written <= 0 {
            return None;
        }
        String::from_utf16(&buffer[..(written as usize).saturating_sub(1)]).ok()
    })
}

/// A calendar date and wall-clock time in the user's local zone.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct LocalDateTime {
    pub year: i32,
    pub month: u32,
    pub day: u32,
    pub weekday_sunday_zero: u32,
    pub hour: u32,
    pub minute: u32,
    pub second: u32,
}

impl LocalDateTime {
    fn system_time(&self) -> SYSTEMTIME {
        SYSTEMTIME {
            wYear: self.year.clamp(1601, 30827) as u16,
            wMonth: self.month as u16,
            wDayOfWeek: self.weekday_sunday_zero as u16,
            wDay: self.day as u16,
            wHour: self.hour as u16,
            wMinute: self.minute as u16,
            wSecond: self.second as u16,
            wMilliseconds: 0,
        }
    }
}

/// Whether a Windows date pattern shows a weekday (`ddd` or `dddd`) outside
/// quoted literals.
pub fn has_weekday(pattern: &str) -> bool {
    let mut in_quote = false;
    let mut run = 0usize;
    for ch in pattern.chars() {
        if ch == '\'' {
            in_quote = !in_quote;
            run = 0;
            continue;
        }
        if !in_quote && ch == 'd' {
            run += 1;
            if run >= 3 {
                return true;
            }
        } else {
            run = 0;
        }
    }
    false
}

/// The long date patterns Windows offers for the locale's calendar, in the
/// order Windows lists them (`EnumDateFormatsExEx`).
fn long_date_patterns(locale: &LocaleName) -> Vec<String> {
    unsafe extern "system" fn collect(pattern: PCWSTR, _calendar: u32, lparam: LPARAM) -> BOOL {
        // SAFETY: `lparam` is the address of the Vec below for the duration
        // of the enumeration, and the pattern is a NUL-terminated string
        // Windows owns for the duration of this call.
        let patterns = unsafe { &mut *(lparam.0 as *mut Vec<String>) };
        if let Ok(text) = unsafe { pattern.to_string() } {
            patterns.push(text);
        }
        BOOL(1)
    }
    let mut patterns: Vec<String> = Vec::new();
    with_locale(locale, |name| {
        let result = unsafe {
            EnumDateFormatsExEx(
                Some(collect),
                name,
                DATE_LONGDATE,
                LPARAM(&mut patterns as *mut Vec<String> as isize),
            )
        };
        if let Err(error) = result {
            log::debug!("EnumDateFormatsExEx failed: {error}");
        }
    });
    patterns
}

/// The pattern used for dates. Patterns are never edited: the user's own
/// long date is used when it has no weekday (so customisations are kept);
/// otherwise the first weekday-free long date Windows itself lists for the
/// locale; otherwise the user's long date unchanged, weekday and all.
pub fn date_pattern(locale: &LocaleName) -> Option<String> {
    let own = locale_info(locale, LOCALE_SLONGDATE)?;
    if !has_weekday(&own) {
        return Some(own);
    }
    Some(long_date_patterns(locale).into_iter().find(|pattern| !has_weekday(pattern)).unwrap_or(own))
}

/// The date in the locale's long format, without the weekday where Windows
/// offers such a format ("21 October 2025" in en-GB, "October 21, 2025" in
/// en-US, "2025. október 21." in hu-HU), honouring user overrides.
pub fn format_date(locale: &LocaleName, when: &LocalDateTime) -> Option<String> {
    let time = when.system_time();
    let pattern = HSTRING::from(date_pattern(locale)?);
    with_locale(locale, |name| {
        let flags = windows::Win32::Globalization::ENUM_DATE_FORMATS_FLAGS(0);
        let needed = unsafe {
            GetDateFormatEx(name, flags, Some(&time), PCWSTR(pattern.as_ptr()), None, PCWSTR::null())
        };
        if needed <= 0 {
            return None;
        }
        let mut buffer = vec![0u16; needed as usize];
        let written = unsafe {
            GetDateFormatEx(
                name,
                flags,
                Some(&time),
                PCWSTR(pattern.as_ptr()),
                Some(&mut buffer),
                PCWSTR::null(),
            )
        };
        if written <= 0 {
            return None;
        }
        String::from_utf16(&buffer[..(written as usize).saturating_sub(1)]).ok()
    })
}

/// The wall-clock time without seconds ("20:13" or "8:13 PM"), as the user's
/// regional format has it.
pub fn format_time(locale: &LocaleName, when: &LocalDateTime) -> Option<String> {
    let time = when.system_time();
    with_locale(locale, |name| {
        let needed = unsafe { GetTimeFormatEx(name, TIME_NOSECONDS, Some(&time), PCWSTR::null(), None) };
        if needed <= 0 {
            return None;
        }
        let mut buffer = vec![0u16; needed as usize];
        let written =
            unsafe { GetTimeFormatEx(name, TIME_NOSECONDS, Some(&time), PCWSTR::null(), Some(&mut buffer)) };
        if written <= 0 {
            return None;
        }
        String::from_utf16(&buffer[..(written as usize).saturating_sub(1)]).ok()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn named(name: &str) -> LocaleName {
        LocaleName::Named(name.to_owned())
    }

    const SAMPLE: LocalDateTime = LocalDateTime {
        year: 2025,
        month: 10,
        day: 21,
        weekday_sunday_zero: 2,
        hour: 20,
        minute: 13,
        second: 5,
    };

    #[test]
    fn grouping_strings_convert_to_numberfmt_values() {
        assert_eq!(grouping_from_locale_string("3;0"), 3);
        assert_eq!(grouping_from_locale_string("3;2;0"), 32);
        assert_eq!(grouping_from_locale_string("3"), 30);
        assert_eq!(grouping_from_locale_string("0"), 0);
        assert_eq!(grouping_from_locale_string(""), 3);
    }

    #[test]
    fn numbers_follow_the_named_locale_not_the_ui_language() {
        assert_eq!(format_number(&named("en-US"), 1234.5, 2).as_deref(), Some("1,234.50"));
        assert_eq!(format_number(&named("de-DE"), 1234.5, 2).as_deref(), Some("1.234,50"));
        assert_eq!(format_number(&named("de-CH"), 1234.5, 2).as_deref(), Some("1’234.50"));
        // Polish groups with a (non-breaking) space and uses a comma.
        let polish = format_number(&named("pl-PL"), 1234.5, 2).unwrap();
        assert!(polish.ends_with(",50") && polish.starts_with('1'), "{polish:?}");
        assert!(polish.chars().any(|c| c == '\u{a0}' || c == ' '), "{polish:?}");
        assert_eq!(format_number(&named("en-US"), 12., 0).as_deref(), Some("12"));
        assert_eq!(format_number(&named("en-US"), 12., 1).as_deref(), Some("12.0"));
        assert_eq!(format_number(&named("en-US"), -0.5, 1).as_deref(), Some("-0.5"));
        assert_eq!(format_number(&named("en-US"), 1234567., 0).as_deref(), Some("1,234,567"));
        // Indian grouping: 12,34,567.
        assert_eq!(format_number(&named("hi-IN"), 1234567., 0).as_deref(), Some("12,34,567"));
        assert!(format_number(&named("en-US"), f64::NAN, 0).is_none());
    }

    #[test]
    fn weekday_detection_is_quote_aware_and_patterns_are_never_edited() {
        assert!(has_weekday("dddd, MMMM d, yyyy"));
        assert!(has_weekday("d MMMM yyyy (dddd)"));
        assert!(has_weekday("ddd d MMM yyyy"));
        assert!(!has_weekday("dd MMMM yyyy"));
        assert!(!has_weekday("yyyy'年'M'月'd'日'"));
        assert!(!has_weekday("'dddd' d MMMM yyyy"), "a quoted literal is not a token");
        assert!(has_weekday("'วัน'dddd'ที่' d MMMM yyyy"));
        // A locale whose own long date has no weekday keeps it verbatim.
        assert_eq!(date_pattern(&named("en-GB")).as_deref(), Some("dd MMMM yyyy"));
        // One whose default carries a weekday gets a weekday-free pattern
        // Windows itself lists, never a transformed one.
        let american = date_pattern(&named("en-US")).unwrap();
        assert!(!has_weekday(&american), "{american}");
        assert!(long_date_patterns(&named("en-US")).contains(&american), "{american}");
        for tag in ["hu-HU", "th-TH", "de-DE", "pl-PL", "ko-KR", "fa-IR", "sv-SE"] {
            let pattern = date_pattern(&named(tag)).unwrap();
            let offered = long_date_patterns(&named(tag));
            let own = locale_info(&named(tag), LOCALE_SLONGDATE).unwrap();
            assert!(
                pattern == own || offered.contains(&pattern),
                "{tag}: {pattern} is not a Windows pattern"
            );
        }
    }

    #[test]
    fn dates_and_times_follow_the_named_locale() {
        assert_eq!(format_date(&named("en-GB"), &SAMPLE).as_deref(), Some("21 October 2025"));
        assert_eq!(format_date(&named("en-US"), &SAMPLE).as_deref(), Some("October 21, 2025"));
        assert_eq!(format_date(&named("de-DE"), &SAMPLE).as_deref(), Some("21. Oktober 2025"));
        assert_eq!(format_date(&named("ja-JP"), &SAMPLE).as_deref(), Some("2025年10月21日"));
        assert_eq!(format_date(&named("fr-FR"), &SAMPLE).as_deref(), Some("21 octobre 2025"));
        assert_eq!(format_date(&named("pt-BR"), &SAMPLE).as_deref(), Some("21 de outubro de 2025"));
        // Preserve locale punctuation and the Thai Buddhist year when omitting weekdays.
        let hungarian = format_date(&named("hu-HU"), &SAMPLE).unwrap();
        assert!(hungarian == "2025. október 21." || hungarian.contains("kedd"), "{hungarian}");
        let thai = format_date(&named("th-TH"), &SAMPLE).unwrap();
        assert!(!thai.contains('\''), "{thai}");
        assert!(thai.contains("2568") && thai.contains("ตุลาคม"), "{thai}");
        assert_eq!(format_time(&named("de-DE"), &SAMPLE).as_deref(), Some("20:13"));
        let us = format_time(&named("en-US"), &SAMPLE).unwrap();
        assert!(us.starts_with("8:13") && us.contains("PM"), "{us:?}");
    }

    #[test]
    fn the_machine_reports_its_languages_and_format_locale() {
        let languages = ui_languages().expect("the display language list is readable");
        assert!(!languages.is_empty());
        for language in &languages {
            assert!(language.parse::<unic_langid::LanguageIdentifier>().is_ok(), "{language:?}");
        }
        let format = user_format_locale().expect("a regional format locale");
        assert!(format.parse::<unic_langid::LanguageIdentifier>().is_ok(), "{format:?}");
        assert!(display_name(&LocaleName::UserDefault, true).is_some());
        assert_eq!(display_name(&named("de-DE"), false).as_deref(), Some("German (Germany)"));
    }

    #[test]
    fn multi_sz_lists_split_cleanly() {
        let buffer: Vec<u16> = "en-GB\0en-US\0\0".encode_utf16().collect();
        assert_eq!(split_multi_sz(&buffer), vec!["en-GB".to_owned(), "en-US".to_owned()]);
        assert!(split_multi_sz(&[0, 0]).is_empty());
    }
}
