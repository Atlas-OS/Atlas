//! Keyboard traversal can land on a control the page has scrolled out of
//! view. GPUI moves focus but knows nothing of scroll containers, so the
//! controls and the scrollbar close the gap between them:
//!
//! 1. After Tab (or an arrow key inside a radio group) moves focus, the
//!    caller arms a request with [`request`].
//! 2. On the next frame every focusable control is wrapped in [`Revealed`],
//!    which reports the bounds of the one that now holds focus.
//! 3. The [`scrollbar`](super::scrollbar) that shares a scroll container's
//!    handle runs after the container's content and, if the reported bounds
//!    lie in that content, scrolls them into view for the frame after.
//!
//! The request is cleared once that second frame has drawn, so a focus
//! change by mouse never scrolls anything.

use gpui::{
    AnyElement, App, Bounds, Element, ElementId, Global, GlobalElementId, InspectorElementId, IntoElement,
    LayoutId, Pixels, ScrollHandle, Window, point, px,
};

/// Space kept between the revealed control and the viewport edge.
const MARGIN: f32 = 12.;

#[derive(Default)]
struct FocusReveal {
    /// Set by [`request`]; reports are ignored otherwise.
    armed: bool,
    /// The focused control's bounds, from the innermost wrapper to report.
    focused: Option<Bounds<Pixels>>,
}

impl Global for FocusReveal {}

/// Arms a reveal for the control that holds focus on the next frame.
pub fn request(window: &mut Window, cx: &mut App) {
    let state = cx.default_global::<FocusReveal>();
    state.armed = true;
    state.focused = None;
    // Reports arrive while the next frame draws; the frame after starts clean.
    window.on_next_frame(|window, _| {
        window.on_next_frame(|_, cx| {
            *cx.default_global::<FocusReveal>() = FocusReveal::default();
        });
    });
}

fn report(bounds: Bounds<Pixels>, cx: &mut App) {
    let state = cx.default_global::<FocusReveal>();
    if state.armed && state.focused.is_none() {
        state.focused = Some(bounds);
    }
}

/// Scrolls `handle`'s container so the reported control is in view, if the
/// control is part of that container's content. Call during prepaint, after
/// the container has laid out.
pub(super) fn reveal_in(handle: &ScrollHandle, window: &mut Window, cx: &mut App) {
    let Some(target) = cx.default_global::<FocusReveal>().focused else { return };
    let viewport = handle.bounds();
    if viewport.size.height <= px(0.) {
        return;
    }
    let offset = handle.offset();
    // Children are laid out before the scroll offset applies; add it to
    // compare them with the reported bounds, which are as painted.
    let mut content: Option<Bounds<Pixels>> = None;
    let mut index = 0;
    while let Some(child) = handle.bounds_for_item(index) {
        let child = Bounds { origin: child.origin + offset, size: child.size };
        content = Some(match content {
            Some(existing) => Bounds::from_corners(
                existing.origin.min(&child.origin),
                existing.bottom_right().max(&child.bottom_right()),
            ),
            None => child,
        });
        index += 1;
    }
    let Some(content) = content else { return };
    if !content.intersects(&target) {
        return;
    }
    cx.default_global::<FocusReveal>().focused = None;

    let margin = px(MARGIN);
    // Positive `above` means the control starts above the viewport; negative
    // `below` means it ends past it. A control taller than the viewport keeps
    // its top in view.
    let above = viewport.top() + margin - target.top();
    let below = viewport.bottom() - margin - target.bottom();
    let delta = if above > px(0.) {
        above
    } else if below < px(0.) {
        below.max(above)
    } else {
        return;
    };
    let y = (offset.y + delta).clamp(-handle.max_offset().y, px(0.));
    if y != offset.y {
        handle.set_offset(point(offset.x, y));
        window.on_next_frame(|window, _| window.refresh());
    }
}

/// Wraps a focusable control so a keyboard focus move can scroll it into
/// view. Transparent to layout: it takes the control's own layout node.
pub struct Revealed {
    child: AnyElement,
}

impl Revealed {
    pub fn new(child: impl IntoElement) -> Self {
        Self { child: child.into_any_element() }
    }
}

impl IntoElement for Revealed {
    type Element = Self;

    fn into_element(self) -> Self::Element {
        self
    }
}

impl Element for Revealed {
    type RequestLayoutState = ();
    type PrepaintState = ();

    fn id(&self) -> Option<ElementId> {
        None
    }

    fn source_location(&self) -> Option<&'static core::panic::Location<'static>> {
        None
    }

    fn request_layout(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (LayoutId, Self::RequestLayoutState) {
        (self.child.request_layout(window, cx), ())
    }

    fn prepaint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        window: &mut Window,
        cx: &mut App,
    ) -> Self::PrepaintState {
        // `Some` only when the focused element is inside this subtree.
        if self.child.prepaint(window, cx).is_some() {
            report(bounds, cx);
        }
    }

    fn paint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        _bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        _prepaint: &mut Self::PrepaintState,
        window: &mut Window,
        cx: &mut App,
    ) {
        self.child.paint(window, cx);
    }
}
