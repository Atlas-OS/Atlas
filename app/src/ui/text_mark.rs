//! Align a control against the actual height of neighbouring text, after wrapping.
use gpui::{
    AlignSelf, AnyElement, App, Bounds, Element, ElementId, FontWeight, GlobalElementId, InspectorElementId,
    IntoElement, LayoutId, Pixels, Style, Window, point, px,
};

use super::typography::{BODY_LINE_HEIGHT, cap_center_offset};
use crate::theme::{FONT_DISPLAY, FONT_TEXT};

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
    pub fn strong(mut self) -> Self {
        self.strong = true;
        self
    }
    pub fn title(mut self) -> Self {
        self.title = true;
        self
    }
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
        let font_size =
            gpui::rems(if self.title { 28. / 16. } else { 14. / 16. }).to_pixels(window.rem_size());
        let line_height =
            if self.title { gpui::rems(36. / 16.) } else { BODY_LINE_HEIGHT }.to_pixels(window.rem_size());
        let cap_height = cx.text_system().cap_height(cx.text_system().resolve_font(&font), font_size);
        let offset = if self.title {
            (bounds.size.height - child_bounds.size.height) / 2.
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

fn mark_top(row: Pixels, mark: Pixels, line: Pixels, cap: Pixels, detail: bool) -> Pixels {
    if detail || row > line.max(mark) + px(1.) { (line - cap) / 2. } else { (row - mark) / 2. }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn wrapped_labels_use_title_top_without_a_description() {
        assert_eq!(mark_top(px(20.), px(20.), px(20.), px(10.), false), px(0.));
        assert_eq!(mark_top(px(40.), px(20.), px(20.), px(10.), false), px(5.));
        assert_eq!(mark_top(px(36.), px(20.), px(20.), px(10.), true), px(5.));
        assert_eq!(mark_top(px(40.), px(20.), px(40.), px(20.), false), px(10.));
        assert_eq!(mark_top(px(80.), px(20.), px(40.), px(20.), false), px(10.));
    }
}
