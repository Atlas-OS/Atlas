//! GitHub-flavoured markdown for release notes: headings,
//! bullets, quotes, rules, bold, italics, inline code and clickable links.
//! Anything else is shown as plain text rather than guessed at.

use std::ops::Range;

use gpui::{
    AnyElement, App, ElementId, FontStyle, FontWeight, HighlightStyle, IntoElement, ParentElement,
    RenderOnce, Role, SharedString, StyledText, UnderlineStyle, Window, div, prelude::*, px,
};

use super::{Typography, focus_ring};
use crate::theme::ActiveTheme;

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
    let mut bold_open: Option<usize> = None;
    let mut italic_open: Option<usize> = None;

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
                Some(start) => out.bold.push(start..out.text.len()),
                None => bold_open = Some(out.text.len()),
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
            // Only treat as emphasis when it hugs a word, so "5 * 3" stays literal.
            let next_is_word = rest[1..].chars().next().is_some_and(|c| !c.is_whitespace());
            let prev_is_word = out.text.chars().last().is_some_and(|c| !c.is_whitespace());
            match italic_open.take() {
                Some(start) if prev_is_word => out.italic.push(start..out.text.len()),
                Some(start) => italic_open = Some(start),
                None if next_is_word => italic_open = Some(out.text.len()),
                None => out.text.push_str(&rest[..1]),
            }
            i += 1;
            continue;
        }

        let ch = rest.chars().next().unwrap_or(' ');
        out.text.push(ch);
        i += ch.len_utf8();
    }
    // Unbalanced markers were literal text after all.
    if let Some(start) = bold_open {
        out.text.insert_str(start, "**");
        shift_ranges(&mut out, start, 2);
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

/// Renders parsed blocks as a column of GPUI text elements, each exposed to
/// assistive technology the way the app's own controls are: headings with
/// their level, runs of bullets as a list of items, paragraphs and quotes as
/// readable text (a label's name is its value, as for `a11y_text`), and
/// every link as a focusable, activatable link element
/// rather than a coloured range inside a plain text run. A block's text is
/// reported once, on the block; the styled runs inside it are decorative.
#[derive(IntoElement)]
pub struct Markdown {
    id: SharedString,
    blocks: Vec<Block>,
}

impl Markdown {
    pub fn new(id: impl Into<SharedString>, blocks: Vec<Block>) -> Self {
        Self { id: id.into(), blocks }
    }
}

impl RenderOnce for Markdown {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme().clone();
        let mut column = div().flex().flex_col().gap(px(2.));
        let mut previous_was_space = true;
        let mut blocks = self.blocks.into_iter().enumerate().peekable();
        while let Some((index, block)) = blocks.next() {
            let id = format!("{}-{index}", self.id);
            let element: AnyElement = match block {
                Block::Space => {
                    column = column.child(div().h(px(6.)));
                    previous_was_space = true;
                    continue;
                }
                Block::Rule => div().h(px(1.)).my(px(6.)).bg(theme.divider).into_any_element(),
                Block::Heading(level, inline) => div()
                    .id(ElementId::Name(id.clone().into()))
                    .role(Role::Heading)
                    .aria_level(usize::from(level))
                    .aria_label(inline.text.clone())
                    .when(!previous_was_space, |this| this.pt(px(8.)))
                    .pb(px(2.))
                    .map(|this| if level <= 2 { this.type_body_large() } else { this.type_body_strong() })
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(inline_content(&id, inline, &theme))
                    .into_any_element(),
                Block::Paragraph(inline) => div()
                    .id(ElementId::Name(id.clone().into()))
                    .role(Role::Label)
                    .aria_value(inline.text.clone())
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(inline_content(&id, inline, &theme))
                    .into_any_element(),
                Block::Quote(inline) => div()
                    .id(ElementId::Name(id.clone().into()))
                    .role(Role::Label)
                    .aria_value(inline.text.clone())
                    .pl(px(12.))
                    .my(px(2.))
                    .border_l_2()
                    .border_color(theme.control_strong_stroke)
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(inline_content(&id, inline, &theme))
                    .into_any_element(),
                Block::Bullet { depth, marker, text } => {
                    // A run of bullets is one list; nested depth is shown by
                    // indentation and stays in the same list.
                    let mut items = vec![(id.clone(), depth, marker, text)];
                    while let Some((_, Block::Bullet { .. })) = blocks.peek() {
                        let Some((next_index, Block::Bullet { depth, marker, text })) = blocks.next() else {
                            break;
                        };
                        items.push((format!("{}-{next_index}", self.id), depth, marker, text));
                    }
                    let count = items.len();
                    div()
                        .id(ElementId::Name(format!("{id}-list").into()))
                        .role(Role::List)
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .children(items.into_iter().enumerate().map(
                            |(position, (id, depth, marker, text))| {
                                div()
                                    .id(ElementId::Name(id.clone().into()))
                                    .role(Role::ListItem)
                                    .aria_label(text.text.clone())
                                    .aria_position_in_set(position + 1)
                                    .aria_size_of_set(count)
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
                                    .child(div().flex_1().min_w_0().child(inline_content(&id, text, &theme)))
                            },
                        ))
                        .into_any_element()
                }
            };
            column = column.child(element);
            previous_was_space = false;
        }
        column
    }
}

/// The styled text of one block. Without links it is a single styled run.
/// With links, the run is split at each link into plain segments and link
/// elements that flow together and wrap; each link is a real control: a
/// tab stop with the focus ring, opened by click, keyboard or the
/// accessible action, and reported with the link's own text.
fn inline_content(id: &str, inline: Inline, theme: &crate::theme::Theme) -> AnyElement {
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
        row =
            row.child(inline_link(ElementId::Name(format!("{id}-link-{number}").into()), label, url, theme));
        cursor = range.end;
    }
    if cursor < inline.text.len() {
        row = row.child(div().min_w_0().child(styled_run(&inline, cursor..inline.text.len(), theme)));
    }
    row.into_any_element()
}

/// One segment of a block's text with its bold, italic and code runs.
fn styled_run(inline: &Inline, segment: Range<usize>, theme: &crate::theme::Theme) -> StyledText {
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
    theme: &crate::theme::Theme,
) -> impl IntoElement {
    let colour = theme.accent_text;
    let hover = theme.text_on_hover(theme.accent_text_hover);
    let focus_outer = theme.focus_outer;
    let focus_inner = theme.focus_inner;
    let open = std::rc::Rc::new(move |cx: &mut App| cx.open_url(&url));
    let by_action = open.clone();
    let text = StyledText::new(label.clone()).with_highlights(vec![(
        0..label.len(),
        HighlightStyle {
            underline: Some(UnderlineStyle { thickness: px(1.), color: Some(colour), wavy: false }),
            ..Default::default()
        },
    )]);
    div()
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
        .hover(move |style| style.text_color(hover))
        .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
        .on_click(move |_, _, cx| open(cx))
        .on_a11y_action(gpui::AccessibleAction::Click, move |_, _, cx| by_action(cx))
        .child(text)
}
