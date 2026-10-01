//! The vendored GPUI patches that keep a mark after a no-break character,
//! and closing punctuation, with the word before it. They're checked through
//! both wrappers rather than through the helpers alone, so a GPUI upgrade
//! that drops either fails here. GPUI's headless text system needs no fonts: every character is 6px
//! wide at 10px.

use std::sync::Arc;

use gpui::{
    Hsla, LineFragment, NoopTextSystem, SharedString, TextRun, TextSystem, WindowTextSystem, font, px,
};

/// Six and a half characters.
const WIDTH: f32 = 39.;

fn text_system() -> Arc<TextSystem> {
    Arc::new(TextSystem::new(Arc::new(NoopTextSystem::new())))
}

/// Where `LineLayout::compute_wrap_boundaries`, which wraps every shaped
/// label and paragraph, breaks `text`: the glyph each row starts with.
fn laid_out(text: &'static str) -> Vec<usize> {
    let run = TextRun {
        len: text.len(),
        font: font("Segoe UI"),
        color: Hsla::default(),
        background_color: None,
        underline: None,
        strikethrough: None,
    };
    let lines = WindowTextSystem::new(text_system())
        .shape_text(SharedString::from(text), px(10.), &[run], Some(px(WIDTH)), None)
        .unwrap();
    lines[0].wrap_boundaries().iter().map(|boundary| boundary.glyph_ix).collect()
}

/// Where `LineWrapper::wrap_line` breaks `text`: the byte each row starts at.
fn wrapped(text: &str) -> Vec<usize> {
    let mut wrapper = text_system().line_wrapper(font("Segoe UI"), px(10.));
    wrapper.wrap_line(&[LineFragment::text(text)], px(WIDTH)).map(|boundary| boundary.ix).collect()
}

#[test]
fn a_mark_after_a_no_break_character_wraps_with_its_word() {
    // No-break space, narrow no-break space and non-breaking hyphen.
    for text in ["ab cd\u{00A0}?", "ab cd\u{202F}?", "ab cd\u{2011}?"] {
        assert_eq!(laid_out(text), [3], "{text:?}");
        assert_eq!(wrapped(text), [3], "{text:?}");
    }
    // `?` after anything else is still a break opportunity (`foo?b=2`).
    assert_eq!(laid_out("ab cde?"), [6]);
    assert_eq!(wrapped("ab cde?"), [6]);
}

#[test]
fn closing_punctuation_never_starts_a_row() {
    // The German closing quote and CJK stops move down with the word before them.
    assert_eq!(laid_out("ab \u{201E}Ja\u{201C}"), [3]);
    assert_eq!(wrapped("ab \u{201E}Ja\u{201C}"), [3]);
    assert_eq!(laid_out("日本語ですね。次"), [5]);
    assert_eq!(wrapped("日本語ですね。次"), [15]);
    // An English opening quote after a space is still a break opportunity.
    assert_eq!(laid_out("abcd \u{201C}x"), [5]);
}
