//! The accented, expanded pseudo-locale (`qps-ploc`): English text with
//! diacritics on every letter and about a third more length, so untranslated
//! strings and layouts that cannot take longer text stand out. Placeables
//! are untouched because the transform only sees literal text.

use std::borrow::Cow;

/// Applied by the Fluent bundle to every text element of every message.
pub fn transform(text: &str) -> Cow<'_, str> {
    if text.trim().is_empty() {
        return Cow::Borrowed(text);
    }
    let mut out = String::with_capacity(text.len() * 3 / 2 + 2);
    let mut letters = 0usize;
    for ch in text.chars() {
        let mapped = accent(ch);
        if mapped != ch {
            letters += 1;
        }
        out.push(mapped);
    }
    // Real translations run up to a third longer than English.
    let padding = letters.div_ceil(3);
    if padding > 0 && text.ends_with(|c: char| !c.is_whitespace()) {
        out.push_str(&"~".repeat(padding));
    }
    Cow::Owned(out)
}

fn accent(ch: char) -> char {
    match ch {
        'a' => 'á',
        'b' => 'ƀ',
        'c' => 'ċ',
        'd' => 'đ',
        'e' => 'é',
        'f' => 'ƒ',
        'g' => 'ġ',
        'h' => 'ħ',
        'i' => 'í',
        'j' => 'ĵ',
        'k' => 'ķ',
        'l' => 'ŀ',
        'm' => 'ḿ',
        'n' => 'ñ',
        'o' => 'ó',
        'p' => 'þ',
        'q' => 'ɋ',
        'r' => 'ŕ',
        's' => 'š',
        't' => 'ŧ',
        'u' => 'ú',
        'v' => 'ṽ',
        'w' => 'ŵ',
        'x' => 'ẋ',
        'y' => 'ý',
        'z' => 'ž',
        'A' => 'Á',
        'B' => 'Ɓ',
        'C' => 'Ċ',
        'D' => 'Đ',
        'E' => 'É',
        'F' => 'Ƒ',
        'G' => 'Ġ',
        'H' => 'Ħ',
        'I' => 'Í',
        'J' => 'Ĵ',
        'K' => 'Ķ',
        'L' => 'Ŀ',
        'M' => 'Ḿ',
        'N' => 'Ñ',
        'O' => 'Ó',
        'P' => 'Þ',
        'Q' => 'Q',
        'R' => 'Ŕ',
        'S' => 'Š',
        'T' => 'Ŧ',
        'U' => 'Ú',
        'V' => 'Ṽ',
        'W' => 'Ŵ',
        'X' => 'Ẋ',
        'Y' => 'Ý',
        'Z' => 'Ž',
        other => other,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn text_is_accented_and_expanded_but_punctuation_and_numbers_survive() {
        let out = transform("Install Atlas 0.6.0 now.");
        assert!(out.starts_with("Íñšŧáŀŀ Áŧŀáš 0.6.0 ñóŵ."), "{out}");
        assert!(out.ends_with('~'), "{out}");
        assert!(out.chars().count() > "Install Atlas 0.6.0 now.".chars().count());
        assert_eq!(transform(" "), " ");
        assert_eq!(transform(""), "");
    }

    #[test]
    fn a_trailing_space_before_a_placeable_is_kept_verbatim() {
        // "Atlas " precedes "{ $version }" in a message; padding must not land
        // between the word and the value.
        assert_eq!(transform("Atlas "), "Áŧŀáš ");
    }
}
