//! Keyboard traversal can land on a control the page has scrolled out of
//! view. GPUI moves focus but knows nothing of scroll containers, so the
//! controls and the scrollbar close the gap between them:
//!
//! 1. After Tab (or an arrow key inside a radio group) moves focus, the
//!    caller arms a request with [`request`].
//! 2. On the next frame every focusable control is wrapped in [`Revealed`],
//!    which reports where the one that now holds focus is drawn, and what it
//!    is clipped to.
//! 3. The [`scrollbar`](super::scrollbar) that shares a scroll container's
//!    handle runs after the container's content and, if the reported control
//!    is part of that content, scrolls it into view for the frame after.
//!
//! The request is cleared as that frame after begins, so a focus change by
//! mouse never scrolls anything.

use gpui::{
    AnyElement, App, Bounds, Element, ElementId, Global, GlobalElementId, InspectorElementId, IntoElement,
    LayoutId, Pixels, ScrollHandle, Window, point, px,
};

/// Space kept between the revealed control and the viewport edge.
const MARGIN: f32 = 12.;
/// Layout rounding a clip may carry past the viewport it was cut from.
const CLIP_SLACK: f32 = 1.;

#[derive(Default)]
struct FocusReveal {
    /// Set by [`request`]; reports are ignored otherwise.
    armed: bool,
    /// Numbers the requests, so the reset an earlier one left behind spares
    /// a later one.
    generation: u64,
    /// The focused control, from the innermost wrapper to report.
    focused: Option<Target>,
    /// For a control its clip can't place, the last container, and so the
    /// outermost, whose content holds it; see [`reveal_hidden`].
    hidden_in: Option<ScrollHandle>,
}

impl Global for FocusReveal {}

impl FocusReveal {
    /// Starts a new request and returns its number.
    fn arm(&mut self) -> u64 {
        *self = FocusReveal { armed: true, generation: self.generation.wrapping_add(1), ..Self::default() };
        self.generation
    }

    /// Ends request `generation`, unless a later request has taken over.
    fn expire(&mut self, generation: u64) {
        if self.generation == generation {
            *self = FocusReveal { generation, ..Self::default() };
        }
    }
}

/// The focused control as drawn.
#[derive(Clone, Copy)]
struct Target {
    bounds: Bounds<Pixels>,
    /// The content mask it was drawn in. A scroll container masks its
    /// content to its viewport, so this lies within the viewport of every
    /// container the control is in; beside a container, as a button above
    /// the install log is, it reaches past that container's viewport, unless
    /// that viewport takes in all the clip around it (see [`holds`]).
    clip: Bounds<Pixels>,
}

/// Arms a reveal for the control that holds focus on the next frame.
pub fn request(window: &mut Window, cx: &mut App) {
    let generation = cx.default_global::<FocusReveal>().arm();
    // Reports arrive while the next frame draws; the frame after starts clean.
    window.on_next_frame(move |window, _| {
        window.on_next_frame(move |_, cx| cx.default_global::<FocusReveal>().expire(generation));
    });
}

fn report(target: Target, cx: &mut App) {
    let state = cx.default_global::<FocusReveal>();
    if state.armed && state.focused.is_none() {
        state.focused = Some(target);
    }
}

/// Scrolls `handle`'s container so the reported control is in view, if the
/// control is part of that container's content. Call during prepaint, after
/// the container has laid out.
pub(super) fn reveal_in(handle: &ScrollHandle, window: &mut Window, cx: &mut App) {
    let Some(target) = cx.default_global::<FocusReveal>().focused else { return };
    let viewport = handle.bounds();
    // A focused scroll container (the install log) is revealed by the
    // container around it, not scrolled within itself.
    if viewport.size.height <= px(0.) || target.bounds == viewport {
        return;
    }
    let offset = handle.offset();
    // Children are laid out before the scroll offset applies; add it to
    // compare them with the reported bounds, which are as painted.
    let Some(content) = (0..)
        .map_while(|index| handle.bounds_for_item(index))
        .map(|child| Bounds { origin: child.origin + offset, ..child })
        .reduce(|a, b| a.union(&b))
    else {
        return;
    };
    // The scrollbar draws beside the container, in the clip around it.
    let outer = window.content_mask().bounds;
    match holds(viewport, outer, content, target) {
        Some(true) => {
            cx.default_global::<FocusReveal>().focused = None;
            scroll_into_view(handle, target.bounds, window);
        }
        Some(false) => {}
        None => {
            let first = cx.default_global::<FocusReveal>().hidden_in.replace(handle.clone()).is_none();
            if first {
                window.defer(cx, reveal_hidden);
            }
        }
    }
}

/// Whether the control is part of the content of a scroll container with
/// this viewport and this content, as painted, inside the clip `outer`.
/// `None` when the control's mask says nothing: a clip around the control
/// hides it entirely, which leaves its mask empty, or the viewport takes in
/// all of `outer`, so a control beside the container is masked as one
/// inside it, as beside the install log on a page no taller than the log.
///
/// The content alone isn't enough: a scrolled container's content reaches
/// far past its viewport, over the controls around it.
fn holds(
    viewport: Bounds<Pixels>,
    outer: Bounds<Pixels>,
    content: Bounds<Pixels>,
    target: Target,
) -> Option<bool> {
    if !content.intersects(&target.bounds) {
        return Some(false);
    }
    // Masks that miss each other leave no height, at a meaningless position.
    // The outer containers place a control this one's viewport can't.
    if target.clip.size.height <= px(0.) || within(outer, viewport) {
        return None;
    }
    Some(within(target.clip, viewport))
}

/// Whether `clip` lies within `viewport`. Containers here scroll vertically,
/// so the top and bottom decide.
fn within(clip: Bounds<Pixels>, viewport: Bounds<Pixels>) -> bool {
    let slack = px(CLIP_SLACK);
    clip.top() >= viewport.top() - slack && clip.bottom() <= viewport.bottom() + slack
}

/// Reveals a control whose clip can't place it, such as a button in a card
/// scrolled wholly out of view. Of the containers whose content holds it,
/// the outermost scrolls: containers draw inside out, so that is the last
/// one recorded once the frame has drawn.
fn reveal_hidden(window: &mut Window, cx: &mut App) {
    let state = cx.default_global::<FocusReveal>();
    if let (Some(target), Some(handle)) = (state.focused.take(), state.hidden_in.take()) {
        scroll_into_view(&handle, target.bounds, window);
    }
}

/// Scrolls `handle`'s container the least that brings `target`, as painted,
/// into view; the change shows on the next frame.
fn scroll_into_view(handle: &ScrollHandle, target: Bounds<Pixels>, window: &mut Window) {
    let viewport = handle.bounds();
    let offset = handle.offset();
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
            report(Target { bounds, clip: window.content_mask().bounds }, cx);
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

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::size;

    fn rect(x: f32, y: f32, width: f32, height: f32) -> Bounds<Pixels> {
        Bounds::new(point(px(x), px(y)), size(px(width), px(height)))
    }

    /// The window, which clips the page's viewport.
    fn window() -> Bounds<Pixels> {
        rect(0., 0., 716., 600.)
    }

    #[test]
    fn a_scrolled_log_leaves_the_controls_around_it_to_the_page() {
        // The page's viewport, and its content scrolled 300px down.
        let page = rect(8., 100., 700., 400.);
        let page_content = rect(48., -200., 620., 1400.);
        // A card with a 49px header over a 220px log of 300 lines that
        // follows output at the bottom, so its lines reach about 5,800px above it.
        let card = rect(48., 200., 620., 400.);
        let log = rect(49., 250., 618., 220.);
        let lines = rect(65., 470. - 12. - 6000., 586., 6000.);
        let clip = card.intersect(&page);

        let copy = Target { bounds: rect(560., 212., 90., 24.), clip };
        assert_eq!(holds(log, clip, lines, copy), Some(false), "a header button isn't the log's");
        assert_eq!(holds(page, window(), page_content, copy), Some(true), "the page reveals it");

        // Something the log does hold is masked to its viewport.
        let line = Target { bounds: rect(65., 100., 586., 20.), clip: log.intersect(&clip) };
        assert_eq!(holds(log, clip, lines, line), Some(true));

        // A card wholly below the viewport leaves a button in it no clip to go by.
        let below =
            Target { bounds: rect(64., 1000., 90., 32.), clip: rect(48., 980., 620., 200.).intersect(&page) };
        assert_eq!(holds(page, window(), page_content, below), None);
        assert_eq!(holds(log, clip, lines, below), Some(false), "outside the log's content");
    }

    #[test]
    fn a_log_that_fills_the_page_leaves_the_controls_beside_it_to_the_page() {
        // At large text sizes the page shows 260px, all of it log: the
        // finished install's 280px log, scrolled to span the page.
        let page = rect(8., 100., 700., 260.);
        let page_content = rect(48., -400., 620., 1400.);
        let log = rect(49., 90., 618., 280.);
        let lines = rect(65., 370. - 12. - 6000., 586., 6000.);

        // Hide log, above the log and scrolled out of view, is masked to the
        // page just as the log's own lines are.
        let hide = Target { bounds: rect(560., 52., 90., 24.), clip: page };
        assert_eq!(holds(log, page, lines, hide), None, "the log can't tell");
        assert_eq!(holds(page, window(), page_content, hide), Some(true), "the page reveals it");
    }

    #[test]
    fn a_reset_left_by_an_earlier_request_spares_a_later_one() {
        let mut state = FocusReveal::default();
        let first = state.arm();
        let second = state.arm();
        state.expire(first);
        assert!(state.armed, "the later request still reveals");
        state.expire(second);
        assert!(!state.armed);
    }
}
