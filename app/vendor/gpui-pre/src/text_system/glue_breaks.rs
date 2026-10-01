//! Atlas patch: no line break straight after a no-break space or a
//! non-breaking hyphen.
//!
//! GPUI's wrappers treat a non-word character such as `?` as a break
//! opportunity whatever precedes it, so French "pilotes\u{00A0}?" could put
//! the `?` alone on the next line although the no-break space asks for it to
//! stay (UAX #14 LB12: no break after glue). The glue characters themselves
//! are word characters (see `LineWrapper::is_word_char`), so this only
//! decides the character after one. `foo?b=2` keeps its break before `?`.

/// Whether a line may break between `prev` and the non-word character after it.
pub(crate) fn may_break_after(prev: char) -> bool {
    !matches!(prev, '\u{00A0}' | '\u{202F}' | '\u{2011}')
}
