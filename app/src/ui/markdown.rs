//! GitHub-flavoured markdown for release notes: headings,
//! bullets, quotes, rules, bold, italics, inline code and clickable links.
//! Anything else is shown as plain text rather than guessed at.

use std::ops::Range;
use std::rc::Rc;

use gpui::{
    AnyElement, App, ElementId, FontStyle, FontWeight, HighlightStyle, IntoElement, ParentElement,
    RenderOnce, Role, SharedString, StyledText, UnderlineStyle, Window, div, prelude::*, px,
};

use super::{Revealed, Typography, focus_ring, on_activate, pointer_hover};
use crate::theme::{ActiveTheme, Theme};

#[derive(Clone, Debug, Default)]
pub struct Inline {
    pub text: String,
    pub bold: Vec<Range<usize>>,
    pub italic: Vec<Range<usize>>,
    pub code: Vec<Range<usize>>,
    pub links: Vec<(Range<usize>, String)>,
}

#[derive(Clone, Debug)]
pub enum Block {
    Heading(u8, Inline),
    Paragraph(Inline),
    Bullet {
        depth: usize,
        marker: String,
        text: Inline,
    },
    Quote(Inline),
    Rule,
    /// A blank line in the source: a little extra space.
    Space,
}

pub fn parse(source: &str) -> Vec<Block> {
    let mut blocks = Vec::new();
    let mut in_comment = false;
    let mut in_code_fence = false;
    for raw in source.lines() {
        let line = raw.trim_end_matches('\r');
        let trimmed = line.trim();

        if in_comment {
            if trimmed.contains("-->") {
                in_comment = false;
            }
            continue;
        }
        if trimmed.starts_with("<!--") {
            in_comment = !trimmed.contains("-->");
            continue;
        }
        if trimmed.starts_with("```") {
            in_code_fence = !in_code_fence;
            continue;
        }
        if in_code_fence {
            blocks.push(Block::Paragraph(Inline {
                text: line.to_owned(),
                code: std::iter::once(0..line.len()).collect(),
                ..Default::default()
            }));
            continue;
        }
        if trimmed.is_empty() {
            if !matches!(blocks.last(), Some(Block::Space) | None) {
                blocks.push(Block::Space);
            }
            continue;
        }
        // Bare HTML lines (<details>, <img>, <p align=...>) carry nothing worth showing.
        if trimmed.starts_with('<') && trimmed.ends_with('>') && !trimmed.starts_with("<http") {
            continue;
        }

        if let Some(rest) = trimmed.strip_prefix('#') {
            let level = 1 + rest.chars().take_while(|c| *c == '#').count();
            let text = rest.trim_start_matches('#').trim();
            if !text.is_empty() {
                blocks.push(Block::Heading(level.min(6) as u8, parse_inline(text)));
                continue;
            }
        }
        if trimmed.len() >= 3 && trimmed.chars().all(|c| c == '-' || c == '*' || c == '_' || c == ' ') {
            blocks.push(Block::Rule);
            continue;
        }
        if let Some(rest) = trimmed.strip_prefix('>') {
            blocks.push(Block::Quote(parse_inline(rest.trim())));
            continue;
        }
        let indent = line.len() - line.trim_start().len();
        if let Some(rest) = trimmed
            .strip_prefix("- ")
            .or_else(|| trimmed.strip_prefix("* "))
            .or_else(|| trimmed.strip_prefix("+ "))
        {
            blocks.push(Block::Bullet {
                depth: indent / 2,
                marker: "\u{2022}".into(),
                text: parse_inline(rest.trim()),
            });
            continue;
        }
        if let Some((number, rest)) = numbered_item(trimmed) {
            blocks.push(Block::Bullet {
                depth: indent / 2,
                marker: format!("{number}."),
                text: parse_inline(rest),
            });
            continue;
        }
        blocks.push(Block::Paragraph(parse_inline(trimmed)));
    }
    while matches!(blocks.last(), Some(Block::Space)) {
        blocks.pop();
    }
    blocks
}

fn numbered_item(line: &str) -> Option<(&str, &str)> {
    let digits = line.chars().take_while(char::is_ascii_digit).count();
    if digits == 0 || digits > 3 {
        return None;
    }
    let rest = &line[digits..];
    let rest = rest.strip_prefix('.').or_else(|| rest.strip_prefix(')'))?;
    let rest = rest.strip_prefix(' ')?;
    Some((&line[..digits], rest.trim()))
}

/// Walks a line once, emitting plain text and recording styled byte ranges.
fn parse_inline(source: &str) -> Inline {
    let source = strip_tags(source);
    let mut out = Inline::default();
    let bytes = source.as_bytes();
    let mut i = 0;
    // Where each open marker went in the output and the source, so an
    // unclosed one can be put back as written.
    let mut bold_open: Option<(usize, usize)> = None;
    let mut italic_open: Option<(usize, usize)> = None;

    while i < bytes.len() {
        let rest = &source[i..];

        if let Some(after) = rest.strip_prefix('`')
            && let Some(end) = after.find('`')
        {
            let start = out.text.len();
            out.text.push_str(&after[..end]);
            out.code.push(start..out.text.len());
            i += 1 + end + 1;
            continue;
        }
        if rest.starts_with("**") || rest.starts_with("__") {
            match bold_open.take() {
                Some((start, _)) => out.bold.push(start..out.text.len()),
                None => bold_open = Some((out.text.len(), i)),
            }
            i += 2;
            continue;
        }
        if let Some(after) = rest.strip_prefix('[')
            && let Some(close) = after.find("](")
            && let Some(end) = after[close + 2..].find(')')
        {
            let label = &after[..close];
            let url = &after[close + 2..close + 2 + end];
            let start = out.text.len();
            out.text.push_str(label);
            out.links.push((start..out.text.len(), url.to_owned()));
            i += 1 + close + 2 + end + 1;
            continue;
        }
        if let Some(after) = rest.strip_prefix('<')
            && after.starts_with("http")
            && let Some(end) = after.find('>')
        {
            let url = &after[..end];
            let start = out.text.len();
            out.text.push_str(url);
            out.links.push((start..out.text.len(), url.to_owned()));
            i += 1 + end + 1;
            continue;
        }
        if rest.starts_with("https://") || rest.starts_with("http://") {
            let end = rest.find(|c: char| c.is_whitespace() || c == ')' || c == ']').unwrap_or(rest.len());
            let url = rest[..end].trim_end_matches(['.', ',', ';']);
            let start = out.text.len();
            out.text.push_str(url);
            out.links.push((start..out.text.len(), url.to_owned()));
            i += url.len();
            continue;
        }
        if (rest.starts_with('*') || rest.starts_with('_'))
            && !rest.starts_with("**")
            && !rest.starts_with("__")
        {
            // GFM flanking, simplified: an opener hugs the word after it and
            // does not follow one ("1920*1080" and "snake_case" stay
            // literal, as does "5 * 3"); a closer hugs the word before it.
            let marker = rest.chars().next().unwrap_or('*');
            let next_is_word = rest[1..].chars().next().is_some_and(|c| !c.is_whitespace());
            let prev = out.text.chars().last();
            let prev_is_word = prev.is_some_and(|c| !c.is_whitespace());
            let prev_is_alphanumeric = prev.is_some_and(char::is_alphanumeric);
            match italic_open.take() {
                Some((start, opener)) if source[opener..].starts_with(marker) && prev_is_word => {
                    out.italic.push(start..out.text.len());
                }
                Some(open) => {
                    italic_open = Some(open);
                    out.text.push(marker);
                }
                None if next_is_word && !prev_is_alphanumeric => italic_open = Some((out.text.len(), i)),
                None => out.text.push(marker),
            }
            i += 1;
            continue;
        }

        let ch = rest.chars().next().unwrap_or(' ');
        out.text.push(ch);
        i += ch.len_utf8();
    }
    // Unclosed markers were literal text after all. Put back the one opened
    // later first, so the earlier one's position still holds.
    let mut unclosed: Vec<(usize, usize, usize)> = Vec::new();
    unclosed.extend(bold_open.map(|(at, opener)| (at, opener, 2)));
    unclosed.extend(italic_open.map(|(at, opener)| (at, opener, 1)));
    unclosed.sort_by_key(|&(_, opener, _)| std::cmp::Reverse(opener));
    for (at, opener, len) in unclosed {
        out.text.insert_str(at, &source[opener..opener + len]);
        shift_ranges(&mut out, at, len);
    }
    out
}

fn shift_ranges(inline: &mut Inline, from: usize, by: usize) {
    let shift = |r: &mut Range<usize>| {
        if r.start >= from {
            r.start += by;
            r.end += by;
        }
    };
    inline.bold.iter_mut().for_each(shift);
    inline.italic.iter_mut().for_each(shift);
    inline.code.iter_mut().for_each(shift);
    inline.links.iter_mut().for_each(|(r, _)| shift(r));
}

/// Removes HTML tags but keeps their text ("<b>x</b>" becomes "x").
fn strip_tags(source: &str) -> String {
    let mut out = String::with_capacity(source.len());
    let mut in_tag = false;
    let mut chars = source.char_indices().peekable();
    while let Some((index, ch)) = chars.next() {
        if in_tag {
            if ch == '>' {
                in_tag = false;
            }
            continue;
        }
        let opens_tag = ch == '<'
            && !source[index..].starts_with("<http")
            && chars.peek().is_some_and(|(_, next)| next.is_ascii_alphabetic() || *next == '/');
        if opens_tag {
            in_tag = true;
        } else {
            out.push(ch);
        }
    }
    out
}

/// Renders parsed blocks with the app's accessibility: headings carry their
/// level, a run of bullets is one list, paragraphs and quotes are labels
/// whose value is their text, and links are real link controls. Inline
/// styling is decorative.
#[derive(IntoElement)]
pub struct Markdown {
    id: SharedString,
    blocks: Vec<Block>,
    /// The heading level of the card the notes sit in: a `#` heading is
    /// reported one level below it, so the page's outline holds.
    base_level: usize,
}

impl Markdown {
    pub fn new(id: impl Into<SharedString>, blocks: Vec<Block>) -> Self {
        Self { id: id.into(), blocks, base_level: 0 }
    }

    /// Nests the notes' headings under a heading at `level`.
    pub fn under_heading(mut self, level: usize) -> Self {
        self.base_level = level;
        self
    }
}

/// The level a Markdown heading of `level` is reported at, under a heading at
/// `base`: at most 9, which UIA's heading levels stop at.
fn nested_level(base: usize, level: u8) -> usize {
    (base + usize::from(level)).min(9)
}

impl RenderOnce for Markdown {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let mut column = div().flex().flex_col().gap(px(2.));
        let mut previous_was_space = true;
        let mut blocks = self.blocks.into_iter().enumerate().peekable();
        while let Some((index, block)) = blocks.next() {
            let id = ElementId::named_usize(self.id.clone(), index);
            let element: AnyElement = match block {
                Block::Space => {
                    column = column.child(div().h(px(6.)));
                    previous_was_space = true;
                    continue;
                }
                Block::Rule => div().h(px(1.)).my(px(6.)).bg(theme.divider).into_any_element(),
                Block::Heading(level, inline) => div()
                    .id(id)
                    .role(Role::Heading)
                    .aria_level(nested_level(self.base_level, level))
                    .aria_label(inline.text.clone())
                    .when(!previous_was_space, |this| this.pt(px(8.)))
                    .pb(px(2.))
                    .map(|this| if level <= 2 { this.type_body_large() } else { this.type_body_strong() })
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(inline_content(inline, window, theme))
                    .into_any_element(),
                Block::Paragraph(inline) => div()
                    .id(id)
                    .role(Role::Label)
                    .aria_value(inline.text.clone())
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(inline_content(inline, window, theme))
                    .into_any_element(),
                Block::Quote(inline) => div()
                    .id(id)
                    .role(Role::Label)
                    .aria_value(inline.text.clone())
                    .pl(px(12.))
                    .my(px(2.))
                    .border_l_2()
                    .border_color(theme.control_strong_stroke)
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(inline_content(inline, window, theme))
                    .into_any_element(),
                Block::Bullet { depth, marker, text } => {
                    // A run of bullets is one list; nested depth is shown by
                    // indentation and stays in the same list.
                    let mut items = vec![(depth, marker, text)];
                    while let Some((_, Block::Bullet { .. })) = blocks.peek() {
                        let Some((_, Block::Bullet { depth, marker, text })) = blocks.next() else {
                            break;
                        };
                        items.push((depth, marker, text));
                    }
                    let count = items.len();
                    div()
                        .id(id)
                        .role(Role::List)
                        .aria_size_of_set(count)
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .children(items.into_iter().enumerate().map(|(position, (depth, marker, text))| {
                            div()
                                .id(("item", position))
                                .role(Role::ListItem)
                                .aria_label(text.text.clone())
                                // AccessKit counts from 0 and takes the size from the list.
                                .aria_position_in_set(position)
                                .flex()
                                .items_start()
                                .gap(px(8.))
                                .pl(px(4. + depth as f32 * 16.))
                                .type_body()
                                .text_color(theme.text_secondary)
                                .child(
                                    div()
                                        .flex_shrink_0()
                                        .min_w(px(10.))
                                        .text_color(theme.text_tertiary)
                                        .child(marker),
                                )
                                .child(div().flex_1().min_w_0().child(inline_content(text, window, theme)))
                        }))
                        .into_any_element()
                }
            };
            column = column.child(element);
            previous_was_space = false;
        }
        column
    }
}

/// One block's text. Links split it into plain runs and focusable link
/// controls that wrap together.
fn inline_content(inline: Inline, window: &Window, theme: &Theme) -> AnyElement {
    if inline.links.is_empty() {
        return styled_run(&inline, 0..inline.text.len(), theme).into_any_element();
    }
    let mut links = inline.links.clone();
    links.sort_by_key(|(range, _)| range.start);
    let mut row = div().flex().flex_wrap().items_baseline();
    let mut cursor = 0;
    for (number, (range, url)) in links.into_iter().enumerate() {
        if range.start > cursor {
            row = row.child(div().min_w_0().child(styled_run(&inline, cursor..range.start, theme)));
        }
        let label: SharedString = inline.text[range.clone()].to_owned().into();
        row = row.child(inline_link(("link", number).into(), label, url, window, theme));
        cursor = range.end;
    }
    if cursor < inline.text.len() {
        row = row.child(div().min_w_0().child(styled_run(&inline, cursor..inline.text.len(), theme)));
    }
    row.into_any_element()
}

/// One segment of a block's text with its bold, italic and code runs.
fn styled_run(inline: &Inline, segment: Range<usize>, theme: &Theme) -> StyledText {
    let clip = |range: &Range<usize>| -> Option<Range<usize>> {
        let start = range.start.max(segment.start);
        let end = range.end.min(segment.end);
        (start < end).then(|| start - segment.start..end - segment.start)
    };
    let mut highlights: Vec<(Range<usize>, HighlightStyle)> = Vec::new();
    for range in inline.bold.iter().filter_map(&clip) {
        highlights
            .push((range, HighlightStyle { font_weight: Some(FontWeight::SEMIBOLD), ..Default::default() }));
    }
    for range in inline.italic.iter().filter_map(&clip) {
        highlights
            .push((range, HighlightStyle { font_style: Some(FontStyle::Italic), ..Default::default() }));
    }
    for range in inline.code.iter().filter_map(&clip) {
        highlights.push((
            range,
            HighlightStyle {
                background_color: Some(theme.subtle_hover),
                color: Some(theme.text_primary),
                ..Default::default()
            },
        ));
    }
    highlights.sort_by_key(|(range, _)| range.start);
    StyledText::new(inline.text[segment].to_owned()).with_highlights(highlights)
}

/// A link inside running text, drawn as the app's hyperlinks are.
fn inline_link(
    id: ElementId,
    label: SharedString,
    url: String,
    window: &Window,
    theme: &Theme,
) -> impl IntoElement {
    let colour = theme.accent_text;
    let hover = theme.text_on_hover(theme.accent_text_hover);
    // A contrast theme pairs the hover text with the highlight fill, as the
    // app's hyperlink buttons do; the underline then follows the text.
    let hover_fill = theme.high_contrast.then_some(theme.subtle_hover);
    let underline = (!theme.high_contrast).then_some(colour);
    let focus_outer = theme.focus_outer;
    let focus_inner = theme.focus_inner;
    let text = StyledText::new(label.clone()).with_highlights(vec![(
        0..label.len(),
        HighlightStyle {
            underline: Some(UnderlineStyle { thickness: px(1.), color: underline, wavy: false }),
            ..Default::default()
        },
    )]);
    let link = div()
        .id(id)
        .role(Role::Link)
        .aria_label(label)
        .tab_index(0)
        .min_w_0()
        .rounded(px(2.))
        .border_1()
        .border_color(theme.transparent())
        .text_color(colour)
        .cursor_pointer()
        .map(|this| {
            pointer_hover(this, window, move |style| {
                let style = style.text_color(hover);
                match hover_fill {
                    Some(fill) => style.bg(fill),
                    None => style,
                }
            })
        })
        .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
        .child(text);
    Revealed::new(on_activate(link, Rc::new(move |_, _, cx| cx.open_url(&url))))
}

#[cfg(test)]
mod tests {
    use super::{nested_level, parse_inline};

    #[test]
    fn notes_headings_sit_under_their_card() {
        assert_eq!(nested_level(2, 1), 3, "a # heading in a level-2 card");
        assert_eq!(nested_level(2, 3), 5);
        assert_eq!(nested_level(0, 2), 2, "on its own, its own level");
        assert_eq!(nested_level(5, 6), 9, "never past HeadingLevel9");
    }

    #[test]
    fn a_marker_inside_a_word_is_text() {
        assert_eq!(parse_inline("1920*1080 and 2560*1440").text, "1920*1080 and 2560*1440");
        let snake = parse_inline("use snake_case_name here");
        assert_eq!(snake.text, "use snake_case_name here");
        assert!(snake.italic.is_empty());
        assert_eq!(parse_inline("5 * 3 = 15").text, "5 * 3 = 15");
    }

    #[test]
    fn emphasis_still_marks_a_word() {
        let inline = parse_inline("very *important* and _also_ this");
        assert_eq!(inline.text, "very important and also this");
        assert_eq!(inline.italic, vec![5..14, 19..23]);
    }

    #[test]
    fn an_unclosed_opener_is_restored() {
        let inline = parse_inline("a *dangling opener");
        assert_eq!(inline.text, "a *dangling opener");
        assert!(inline.italic.is_empty());
        // Each as written, in place, whichever opened first.
        for text in ["*a **b", "**a *b", "__a *b", "*a __b"] {
            assert_eq!(parse_inline(text).text, text);
        }
        let mixed = parse_inline("_open then `code` and [link](https://x.y)");
        assert_eq!(mixed.text, "_open then code and link");
        assert_eq!(mixed.code, vec![11..15]);
        assert_eq!(mixed.links[0].0, 20..24);
    }

    #[test]
    fn a_stray_marker_while_open_stays_in_the_text() {
        assert_eq!(parse_inline("*a * b*").text, "a * b");
        // One level of emphasis: a different marker inside it is literal.
        let nested = parse_inline("*a _b_ c*");
        assert_eq!(nested.text, "a _b_ c");
        assert_eq!(nested.italic, vec![0..7]);
    }
}
