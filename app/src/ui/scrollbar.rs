//! A Windows 11 overlay scrollbar: a 2px line that widens to a 6px thumb on
//! hover, drawn over the content instead of reserving a gutter.
//!
//! GPUI's scroll containers do not draw a scrollbar or scroll from the
//! keyboard; this element sits over one, reads its [`ScrollHandle`] and
//! drives it on drag or track click. The keyboard scrolling actions (Page
//! Up, Page Down, Ctrl+Home and Ctrl+End, and the arrows, Home and End in a
//! focused log) are handled here too.

use std::cell::RefCell;
use std::rc::Rc;

use gpui::{
    App, Bounds, DispatchPhase, Div, Element, ElementId, Global, GlobalElementId, Hitbox, HitboxBehavior,
    InspectorElementId, InteractiveElement, IntoElement, LayoutId, MouseButton, MouseDownEvent,
    MouseExitEvent, MouseMoveEvent, MouseUpEvent, ParentElement, Pixels, ScrollHandle, Stateful, Style,
    Styled, Window, div, fill, point, px, relative, size,
};

use super::actions::{
    ScrollLineDown, ScrollLineUp, ScrollLogToBottom, ScrollLogToTop, ScrollPageDown, ScrollPageUp,
    ScrollToBottom, ScrollToTop,
};
use crate::theme::ActiveTheme;

const RAIL_WIDTH: f32 = 12.;
const THUMB_IDLE: f32 = 2.;
const THUMB_HOVER: f32 = 6.;
const THUMB_MIN: f32 = 24.;
const EDGE_PADDING: f32 = 3.;
/// Kept in view across a Page Up or Page Down, so reading can carry on.
const PAGE_OVERLAP: f32 = 40.;

#[derive(Default)]
struct Inner {
    /// Distance from the thumb's top to the grab point while dragging.
    drag: Option<Pixels>,
    hovered: bool,
}

impl Inner {
    /// Hovered or dragged: the thumb is widened and the track shows.
    fn active(&self) -> bool {
        self.hovered || self.drag.is_some()
    }
}

/// Shared between frames; keep one per scroll container.
#[derive(Clone, Default)]
pub struct ScrollbarState(Rc<RefCell<Inner>>);

impl ScrollbarState {
    pub fn new() -> Self {
        Self::default()
    }
}

struct Scrollbar {
    handle: ScrollHandle,
    state: ScrollbarState,
    /// The page's own scroller, which the window's scrolling keys reach.
    page: bool,
}

/// The scroll container of the page on screen, recorded by its scrollbar as
/// it draws, so the window's scrolling keys reach it wherever focus is.
#[derive(Default)]
struct PageScroll(Option<ScrollHandle>);

impl Global for PageScroll {}

struct Layout {
    track: Bounds<Pixels>,
    thumb: Bounds<Pixels>,
    hitbox: Hitbox,
    max_offset: Pixels,
}

/// Wraps the scrollbar in an absolutely positioned rail on the right edge.
/// Place it inside a `relative()` container that also holds the scroll view.
/// This is the page's scrollbar: while it is on screen, Page Up, Page Down,
/// Ctrl+Home and Ctrl+End scroll its container.
pub fn scrollbar(handle: &ScrollHandle, state: &ScrollbarState) -> Div {
    rail(handle, state, true)
}

/// A scrollbar for a container inside a page, such as the install log. The
/// container scrolls from the keyboard while it has focus; see
/// [`keyboard_scrolling`].
pub fn nested_scrollbar(handle: &ScrollHandle, state: &ScrollbarState) -> Div {
    rail(handle, state, false)
}

fn rail(handle: &ScrollHandle, state: &ScrollbarState, page: bool) -> Div {
    div().absolute().top_0().right_0().bottom_0().w(px(RAIL_WIDTH)).child(Scrollbar {
        handle: handle.clone(),
        state: state.clone(),
        page,
    })
}

/// What a scrolling key asks for.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum ScrollKey {
    LineUp,
    LineDown,
    PageUp,
    PageDown,
    Top,
    Bottom,
}

/// The offset `key` scrolls to, in GPUI's terms: 0 at the top, `-max` at
/// the bottom. A page is the viewport less a small overlap.
fn keyboard_offset(offset: Pixels, viewport: Pixels, max: Pixels, line: Pixels, key: ScrollKey) -> Pixels {
    let page = (viewport - px(PAGE_OVERLAP)).max(line);
    let target = match key {
        ScrollKey::LineUp => offset + line,
        ScrollKey::LineDown => offset - line,
        ScrollKey::PageUp => offset + page,
        ScrollKey::PageDown => offset - page,
        ScrollKey::Top => px(0.),
        ScrollKey::Bottom => -max,
    };
    target.clamp(-max.max(px(0.)), px(0.))
}

/// Scrolls `handle`'s container for `key`. False when it cannot move.
fn scroll_by_key(handle: &ScrollHandle, key: ScrollKey, window: &mut Window) -> bool {
    let offset = handle.offset();
    let line = super::BODY_LINE_HEIGHT.to_pixels(window.rem_size());
    let y = keyboard_offset(offset.y, handle.bounds().size.height, handle.max_offset().y, line, key);
    if y == offset.y {
        return false;
    }
    handle.set_offset(point(offset.x, y));
    window.refresh();
    true
}

fn scroll_page(key: ScrollKey, window: &mut Window, cx: &mut App) {
    if let Some(handle) = cx.try_global::<PageScroll>().and_then(|page| page.0.clone()) {
        scroll_by_key(&handle, key, window);
    }
}

/// Handles the window's scrolling keys on `element`, which must be on every
/// dispatch path (the window's root), by scrolling the page on screen.
pub fn page_keyboard_scrolling<E: InteractiveElement>(element: E) -> E {
    element
        .on_action(|_: &ScrollPageUp, window, cx| scroll_page(ScrollKey::PageUp, window, cx))
        .on_action(|_: &ScrollPageDown, window, cx| scroll_page(ScrollKey::PageDown, window, cx))
        .on_action(|_: &ScrollToTop, window, cx| scroll_page(ScrollKey::Top, window, cx))
        .on_action(|_: &ScrollToBottom, window, cx| scroll_page(ScrollKey::Bottom, window, cx))
}

/// Scrolls a focusable container nested in a page from the keyboard while
/// focus is in it. A page key it cannot act on (already at that end, or
/// nothing to scroll) goes on to the page; Home and End stay with it.
pub fn keyboard_scrolling(element: Stateful<Div>, handle: &ScrollHandle) -> Stateful<Div> {
    let scroll = |key: ScrollKey| {
        let handle = handle.clone();
        move |window: &mut Window, cx: &mut App| {
            if !scroll_by_key(&handle, key, window) {
                cx.propagate();
            }
        }
    };
    let own = |key: ScrollKey| {
        let handle = handle.clone();
        move |window: &mut Window| {
            scroll_by_key(&handle, key, window);
        }
    };
    let (line_up, line_down) = (scroll(ScrollKey::LineUp), scroll(ScrollKey::LineDown));
    let (page_up, page_down) = (scroll(ScrollKey::PageUp), scroll(ScrollKey::PageDown));
    let (top, bottom) = (scroll(ScrollKey::Top), scroll(ScrollKey::Bottom));
    let (own_top, own_bottom) = (own(ScrollKey::Top), own(ScrollKey::Bottom));
    element
        .on_action(move |_: &ScrollLineUp, window, cx| line_up(window, cx))
        .on_action(move |_: &ScrollLineDown, window, cx| line_down(window, cx))
        .on_action(move |_: &ScrollPageUp, window, cx| page_up(window, cx))
        .on_action(move |_: &ScrollPageDown, window, cx| page_down(window, cx))
        .on_action(move |_: &ScrollToTop, window, cx| top(window, cx))
        .on_action(move |_: &ScrollToBottom, window, cx| bottom(window, cx))
        .on_action(move |_: &ScrollLogToTop, window, _| own_top(window))
        .on_action(move |_: &ScrollLogToBottom, window, _| own_bottom(window))
}

impl IntoElement for Scrollbar {
    type Element = Self;

    fn into_element(self) -> Self {
        self
    }
}

impl Element for Scrollbar {
    type RequestLayoutState = ();
    type PrepaintState = Option<Layout>;

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
        let style = Style { size: size(relative(1.), relative(1.)).map(Into::into), ..Default::default() };
        (window.request_layout(style, None, cx), ())
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
        // The container's content has just been laid out; if keyboard focus
        // moved into it, bring the focused control into view.
        super::focus_reveal::reveal_in(&self.handle, window, cx);
        if self.page {
            cx.default_global::<PageScroll>().0 = Some(self.handle.clone());
        }
        let max_offset = self.handle.max_offset().y;
        let viewport = bounds.size.height;
        if max_offset <= px(0.) || viewport <= px(0.) {
            return None;
        }
        let content = viewport + max_offset;
        let track_len = viewport - px(EDGE_PADDING * 2.);
        let thumb_len = (track_len * (viewport / content)).max(px(THUMB_MIN)).min(track_len);
        let scrolled = (-self.handle.offset().y).clamp(px(0.), max_offset);
        let thumb_top =
            bounds.origin.y + px(EDGE_PADDING) + (track_len - thumb_len) * (scrolled / max_offset);

        let width = if self.state.0.borrow().active() { THUMB_HOVER } else { THUMB_IDLE };
        let thumb = Bounds::new(
            point(bounds.origin.x + bounds.size.width - px(width) - px(EDGE_PADDING), thumb_top),
            size(px(width), thumb_len),
        );
        let track = Bounds::new(
            point(bounds.origin.x, bounds.origin.y + px(EDGE_PADDING)),
            size(bounds.size.width, track_len),
        );
        let hitbox = window.insert_hitbox(bounds, HitboxBehavior::Normal);
        Some(Layout { track, thumb, hitbox, max_offset })
    }

    fn paint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        _bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        prepaint: &mut Self::PrepaintState,
        window: &mut Window,
        cx: &mut App,
    ) {
        let Some(layout) = prepaint.take() else { return };
        let theme = cx.theme();
        let active = self.state.0.borrow().active();

        if active {
            window.paint_quad(fill(layout.track, theme.card_fill).corner_radii(px(RAIL_WIDTH / 2.)));
        }
        let thumb_colour = if active { theme.text_secondary } else { theme.text_tertiary };
        window.paint_quad(fill(layout.thumb, thumb_colour).corner_radii(px(THUMB_HOVER / 2.)));

        let handle = self.handle.clone();
        let state = self.state.clone();
        let track = layout.track;
        let thumb = layout.thumb;
        let max_offset = layout.max_offset;
        let hitbox = layout.hitbox;

        let scroll_to_thumb_top = move |handle: &ScrollHandle, thumb_top: Pixels| {
            let range = track.size.height - thumb.size.height;
            if range <= px(0.) {
                return;
            }
            let ratio = ((thumb_top - track.origin.y) / range).clamp(0., 1.);
            let mut offset = handle.offset();
            offset.y = -max_offset * ratio;
            handle.set_offset(offset);
        };

        window.on_mouse_event({
            let handle = handle.clone();
            let state = state.clone();
            let hitbox = hitbox.clone();
            move |event: &MouseDownEvent, phase, window, cx| {
                if phase != DispatchPhase::Bubble || event.button != MouseButton::Left {
                    return;
                }
                if !hitbox.is_hovered(window) {
                    return;
                }
                // The thumb is 2-6px wide inside a 12px rail: anywhere across
                // the rail at the thumb's height grabs it.
                let on_thumb = event.position.y >= thumb.top() && event.position.y <= thumb.bottom();
                if on_thumb {
                    state.0.borrow_mut().drag = Some(event.position.y - thumb.origin.y);
                } else {
                    // Jump so the thumb centres on the click.
                    scroll_to_thumb_top(&handle, event.position.y - thumb.size.height / 2.);
                    state.0.borrow_mut().drag = Some(thumb.size.height / 2.);
                }
                cx.stop_propagation();
                window.refresh();
            }
        });

        window.on_mouse_event({
            let handle = handle.clone();
            let state = state.clone();
            let hitbox = hitbox.clone();
            move |event: &MouseMoveEvent, phase, window, cx| {
                if phase != DispatchPhase::Bubble {
                    return;
                }
                let drag = state.0.borrow().drag;
                match drag {
                    Some(grab) if event.dragging() => {
                        scroll_to_thumb_top(&handle, event.position.y - grab);
                        cx.stop_propagation();
                        window.refresh();
                    }
                    _ => {
                        let hovered = hitbox.is_hovered(window);
                        let mut inner = state.0.borrow_mut();
                        if inner.hovered != hovered {
                            inner.hovered = hovered;
                            window.refresh();
                        }
                    }
                }
            }
        });

        window.on_mouse_event({
            let state = state.clone();
            move |_: &MouseUpEvent, phase, window, _| {
                if phase != DispatchPhase::Bubble {
                    return;
                }
                if state.0.borrow_mut().drag.take().is_some() {
                    window.refresh();
                }
            }
        });

        // Leaving the window over the rail sends no further moves, so the
        // widened thumb would stick until the pointer came back.
        window.on_mouse_event({
            let state = state.clone();
            move |_: &MouseExitEvent, phase, window, _| {
                if phase != DispatchPhase::Bubble {
                    return;
                }
                let mut inner = state.0.borrow_mut();
                if inner.hovered {
                    inner.hovered = false;
                    window.refresh();
                }
            }
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn at(offset: f32, key: ScrollKey) -> Pixels {
        // A 400px viewport over 1000px of content, 20px lines.
        keyboard_offset(px(offset), px(400.), px(600.), px(20.), key)
    }

    #[test]
    fn keyboard_scrolling_moves_by_lines_and_pages_within_the_content() {
        assert_eq!(at(0., ScrollKey::LineDown), px(-20.));
        assert_eq!(at(-100., ScrollKey::LineUp), px(-80.));
        assert_eq!(at(0., ScrollKey::PageDown), px(-360.), "a page keeps an overlap in view");
        assert_eq!(at(-360., ScrollKey::PageUp), px(0.));
        assert_eq!(at(-360., ScrollKey::PageDown), px(-600.), "clamped at the bottom");
        assert_eq!(at(-100., ScrollKey::PageUp), px(0.), "clamped at the top");
        assert_eq!(at(0., ScrollKey::LineUp), px(0.));
        assert_eq!(at(-250., ScrollKey::Top), px(0.));
        assert_eq!(at(-250., ScrollKey::Bottom), px(-600.));
    }

    #[test]
    fn content_that_fits_does_not_scroll() {
        for key in [ScrollKey::LineDown, ScrollKey::PageDown, ScrollKey::Bottom, ScrollKey::PageUp] {
            assert_eq!(keyboard_offset(px(0.), px(400.), px(0.), px(20.), key), px(0.));
        }
        // A viewport shorter than the overlap still moves by at least a line.
        assert_eq!(keyboard_offset(px(0.), px(30.), px(600.), px(20.), ScrollKey::PageDown), px(-20.));
    }
}
