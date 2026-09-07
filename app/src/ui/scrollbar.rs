//! A Windows 11 overlay scrollbar: a 2px line that widens to a 6px thumb on
//! hover, drawn over the content instead of reserving a gutter.
//!
//! GPUI's scroll containers do not draw a scrollbar; this element sits over
//! one, reads its [`ScrollHandle`] and drives it on drag or track click.

use std::cell::RefCell;
use std::rc::Rc;

use gpui::{
    App, BorderStyle, Bounds, Corners, DispatchPhase, Div, Edges, Element, ElementId, GlobalElementId,
    Hitbox, HitboxBehavior, Hsla, InspectorElementId, IntoElement, LayoutId, MouseButton, MouseDownEvent,
    MouseMoveEvent, MouseUpEvent, ParentElement, Pixels, ScrollHandle, Style, Styled, Window, div, point, px,
    quad, relative, size,
};

use crate::theme::ActiveTheme;

const RAIL_WIDTH: f32 = 12.;
const THUMB_IDLE: f32 = 2.;
const THUMB_HOVER: f32 = 6.;
const THUMB_MIN: f32 = 24.;
const EDGE_PADDING: f32 = 3.;

#[derive(Default)]
struct Inner {
    /// Distance from the thumb's top to the grab point while dragging.
    drag: Option<Pixels>,
    hovered: bool,
    thumb: Option<Bounds<Pixels>>,
}

/// Shared between frames; keep one per scroll container.
#[derive(Clone, Default)]
pub struct ScrollbarState(Rc<RefCell<Inner>>);

impl ScrollbarState {
    pub fn new() -> Self {
        Self::default()
    }
}

pub struct Scrollbar {
    handle: ScrollHandle,
    state: ScrollbarState,
}

pub struct Layout {
    track: Bounds<Pixels>,
    thumb: Bounds<Pixels>,
    hitbox: Hitbox,
    max_offset: Pixels,
}

/// Wraps the scrollbar in an absolutely positioned rail on the right edge.
/// Place it inside a `relative()` container that also holds the scroll view.
pub fn scrollbar(handle: &ScrollHandle, state: &ScrollbarState) -> Div {
    div()
        .absolute()
        .top_0()
        .right_0()
        .bottom_0()
        .w(px(RAIL_WIDTH))
        .child(Scrollbar { handle: handle.clone(), state: state.clone() })
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
        _cx: &mut App,
    ) -> Self::PrepaintState {
        let max_offset = self.handle.max_offset().y;
        let viewport = bounds.size.height;
        if max_offset <= px(0.) || viewport <= px(0.) {
            self.state.0.borrow_mut().thumb = None;
            return None;
        }
        let content = viewport + max_offset;
        let track_len = viewport - px(EDGE_PADDING * 2.);
        let thumb_len = (track_len * (viewport / content)).max(px(THUMB_MIN)).min(track_len);
        let scrolled = (-self.handle.offset().y).clamp(px(0.), max_offset);
        let thumb_top =
            bounds.origin.y + px(EDGE_PADDING) + (track_len - thumb_len) * (scrolled / max_offset);

        let inner = self.state.0.borrow();
        let width = if inner.hovered || inner.drag.is_some() { THUMB_HOVER } else { THUMB_IDLE };
        drop(inner);
        let thumb = Bounds::new(
            point(bounds.origin.x + bounds.size.width - px(width) - px(EDGE_PADDING), thumb_top),
            size(px(width), thumb_len),
        );
        let track = Bounds::new(
            point(bounds.origin.x, bounds.origin.y + px(EDGE_PADDING)),
            size(bounds.size.width, track_len),
        );
        self.state.0.borrow_mut().thumb = Some(thumb);
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
        let active = self.state.0.borrow().hovered || self.state.0.borrow().drag.is_some();

        if active {
            window.paint_quad(quad(
                layout.track,
                Corners::all(px(6.)),
                theme.card_fill,
                Edges::default(),
                Hsla::transparent_black(),
                BorderStyle::default(),
            ));
        }
        let thumb_colour = if active { theme.text_secondary } else { theme.text_tertiary };
        window.paint_quad(quad(
            layout.thumb,
            Corners::all(px(3.)),
            thumb_colour,
            Edges::default(),
            Hsla::transparent_black(),
            BorderStyle::default(),
        ));

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
                if thumb.contains(&event.position) {
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
    }
}
