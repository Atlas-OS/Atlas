//! Align a control against the actual height of neighbouring text, after wrapping.
use gpui::{
    AlignSelf, AnyElement, App, Bounds, Element, ElementId, FontWeight, GlobalElementId, InspectorElementId,
    IntoElement, LayoutId, Pixels, Style, Window, point, px,
};

use super::typography::{BODY_LINE_HEIGHT, BODY_SIZE, cap_center_offset, title_metrics};
use crate::theme::{FONT_DISPLAY, FONT_TEXT};

/// Places a mark (check box, icon, status light) beside text: centred on a
/// single line, or with its top on the first line's capitals when the text
/// wraps or has a detail line (`detail`).
pub struct TextMark {
    child: AnyElement,
    detail: bool,
    strong: bool,
    title: bool,
    natural_text: bool,
}

impl TextMark {
    pub fn new(child: impl IntoElement, detail: bool) -> Self {
        Self { child: child.into_any_element(), detail, strong: false, title: false, natural_text: false }
    }
    /// Measures against semibold body text.
    pub fn strong(mut self) -> Self {
        self.strong = true;
        self
    }
    /// Centres on the capitals of a page title instead: of its first line,
    /// when the title wraps.
    pub fn title(mut self) -> Self {
        self.title = true;
        self
    }
    /// For plain GPUI text rather than [`super::CapCenteredText`]: its
    /// capitals sit off the line's centre, so the mark moves with them.
    pub fn natural_text(mut self) -> Self {
        self.natural_text = true;
        self
    }
}

impl IntoElement for TextMark {
    type Element = Self;
    fn into_element(self) -> Self {
        self
    }
}

impl Element for TextMark {
    type RequestLayoutState = LayoutId;
    type PrepaintState = ();
    fn id(&self) -> Option<ElementId> {
        None
    }
    fn source_location(&self) -> Option<&'static core::panic::Location<'static>> {
        None
    }
    fn request_layout(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (LayoutId, LayoutId) {
        let child = self.child.request_layout(window, cx);
        let style = Style { align_self: Some(AlignSelf::Stretch), flex_shrink: 0., ..Default::default() };
        (window.request_layout(style, [child], cx), child)
    }
    fn prepaint(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        bounds: Bounds<Pixels>,
        child: &mut LayoutId,
        window: &mut Window,
        cx: &mut App,
    ) {
        let child_bounds = window.layout_bounds(*child);
        let mut font = gpui::font(if self.title { FONT_DISPLAY } else { FONT_TEXT });
        font.weight = if self.strong || self.title { FontWeight::SEMIBOLD } else { FontWeight::NORMAL };
        let (title_size, title_line) = title_metrics();
        let font_size = if self.title { title_size } else { BODY_SIZE }.to_pixels(window.rem_size());
        let line_height = if self.title { title_line } else { BODY_LINE_HEIGHT }.to_pixels(window.rem_size());
        let cap_height = cx.text_system().cap_height(cx.text_system().resolve_font(&font), font_size);
        let offset = if self.title {
            title_mark_top(bounds.size.height, child_bounds.size.height, line_height)
                + cap_center_offset(font, font_size, window, cx)
        } else {
            mark_top(bounds.size.height, child_bounds.size.height, line_height, cap_height, self.detail)
                + if self.natural_text { cap_center_offset(font, font_size, window, cx) } else { px(0.) }
        };
        window.with_element_offset(point(px(0.), offset), |window| {
            self.child.prepaint(window, cx);
        });
    }
    fn paint(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        _: Bounds<Pixels>,
        _: &mut LayoutId,
        _: &mut (),
        window: &mut Window,
        cx: &mut App,
    ) {
        self.child.paint(window, cx);
    }
}

/// Where a mark beside a page title goes: centred in a one-line row, or on
/// the first line of a title that wraps, rather than between its lines.
fn title_mark_top(row: Pixels, mark: Pixels, line: Pixels) -> Pixels {
    if row > line + px(1.) { (line - mark) / 2. } else { (row - mark) / 2. }
}

fn mark_top(row: Pixels, mark: Pixels, line: Pixels, cap: Pixels, detail: bool) -> Pixels {
    if detail || row > line.max(mark) + px(1.) { (line - cap) / 2. } else { (row - mark) / 2. }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn a_mark_beside_a_wrapped_title_stays_on_its_first_line() {
        // One 50px line: centred in the row.
        assert_eq!(title_mark_top(px(50.), px(32.), px(50.)), px(9.));
        // Two lines: on the first, not between them.
        assert_eq!(title_mark_top(px(100.), px(32.), px(50.)), px(9.));
        assert_eq!(title_mark_top(px(100.), px(20.), px(50.)), px(15.));
    }

    #[test]
    fn wrapped_labels_use_title_top_without_a_description() {
        assert_eq!(mark_top(px(20.), px(20.), px(20.), px(10.), false), px(0.));
        assert_eq!(mark_top(px(40.), px(20.), px(20.), px(10.), false), px(5.));
        assert_eq!(mark_top(px(36.), px(20.), px(20.), px(10.), true), px(5.));
        assert_eq!(mark_top(px(40.), px(20.), px(40.), px(20.), false), px(10.));
        assert_eq!(mark_top(px(80.), px(20.), px(40.), px(20.), false), px(10.));
    }
}
