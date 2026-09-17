//! A single procedural DirectX background quad for the completion page. The
//! artwork keeps clear of the text: the page reports the blocks it lays out
//! and the shader fades the dots out around them.
use std::cell::RefCell;
use std::rc::Rc;
use std::time::Duration;

use gpui::{
    Animation, AnimationExt, App, Background, BorderStyle, Bounds, Corners, Edges, Element, ElementId,
    GlobalElementId, Hsla, InspectorElementId, IntoElement, LayoutId, PaintQuad, ParentElement, Pixels,
    RenderOnce, Style, Styled, Window, div, flowing_gradient, px, quad, relative, size,
};

use crate::theme::ActiveTheme;

/// Dot grid spacing in logical pixels.
const DOT_PITCH: f32 = 11.;
/// Logical pixels of clear space around a keep-out block before any dot returns.
const KEEP_OUT_PADDING: f32 = 12.;
/// Logical pixels over which the dots return outside that clear space.
const KEEP_OUT_FEATHER: f32 = 48.;
/// Keep-out blocks one quad can carry, one per borrowed quad field (see the shader).
pub const KEEP_OUT_SLOTS: usize = 2;

/// The text blocks the artwork keeps clear of. Create one per render, hand
/// [`KeepOut::record`] listeners to the blocks' containers and the same value
/// to [`CompletionBackdrop`]. The blocks report their bounds during prepaint,
/// which precedes every paint in the frame, so the quad reads this frame's
/// layout even while the page scrolls.
#[derive(Clone, Default)]
pub struct KeepOut(Rc<RefCell<[Option<Bounds<Pixels>>; KEEP_OUT_SLOTS]>>);

impl KeepOut {
    /// A `Div::on_children_prepainted` listener that stores the union of the
    /// children's bounds in `slot`.
    pub fn record(&self, slot: usize) -> impl Fn(Vec<Bounds<Pixels>>, &mut Window, &mut App) + 'static {
        let blocks = self.0.clone();
        move |children, _, _| blocks.borrow_mut()[slot] = union(&children)
    }
}

fn union(bounds: &[Bounds<Pixels>]) -> Option<Bounds<Pixels>> {
    bounds.iter().copied().reduce(|a, b| a.union(&b))
}

#[derive(IntoElement)]
pub struct CompletionBackdrop {
    keep_out: KeepOut,
}

impl CompletionBackdrop {
    pub fn new(keep_out: KeepOut) -> Self {
        Self { keep_out }
    }
}

impl RenderOnce for CompletionBackdrop {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let surface = div().absolute().size_full();
        if theme.high_contrast {
            return surface.into_any_element();
        }
        let dark = theme.is_dark();
        let scale = window.scale_factor();
        let halftone = Halftone {
            rest: theme.brand.opacity(if dark { 0.06 } else { 0.08 }),
            glow: theme.accent.opacity(if dark { 0.07 } else { 0.05 }),
            lit: theme.brand.opacity(0.30),
            pitch: DOT_PITCH * scale,
            feather: KEEP_OUT_FEATHER * scale,
            phase: 0.,
            keep_out: self.keep_out,
        };
        // Atlas itself switches Windows animations off (the Interface/Animation
        // toggle clears the client-area animation bit), so `theme.reduce_motion`
        // is true on practically every machine that reaches this page. Honouring
        // it here would freeze the artwork for everyone, so the loop always runs;
        // it is slow, low-contrast and 30 fps, and never carries information.
        //
        // It only runs while the window is active. An inactive window shows
        // the loop's first frame; dropping the animation element resets its
        // clock, so the motion resumes from that same frame on activation.
        if !window.is_window_active() {
            return surface.child(halftone).into_any_element();
        }
        surface
            .child(halftone.with_animation(
                "installed-flowing-gradient",
                Animation::new(Duration::from_secs(48)).repeat().with_max_fps(30.),
                |halftone, progress| Halftone { phase: progress * std::f32::consts::TAU, ..halftone },
            ))
            .into_any_element()
    }
}

/// The artwork quad. An [`Element`] rather than a styled div so it can paint
/// the keep-out rectangles alongside the background.
struct Halftone {
    rest: Hsla,
    glow: Hsla,
    lit: Hsla,
    /// Device pixels.
    pitch: f32,
    /// Device pixels.
    feather: f32,
    phase: f32,
    keep_out: KeepOut,
}

impl IntoElement for Halftone {
    type Element = Self;

    fn into_element(self) -> Self {
        self
    }
}

impl Element for Halftone {
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
        let style = Style { size: size(relative(1.), relative(1.)).map(Into::into), ..Default::default() };
        (window.request_layout(style, None, cx), ())
    }

    fn prepaint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        _bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        _window: &mut Window,
        _cx: &mut App,
    ) -> Self::PrepaintState {
    }

    fn paint(
        &mut self,
        _id: Option<&GlobalElementId>,
        _inspector_id: Option<&InspectorElementId>,
        bounds: Bounds<Pixels>,
        _request_layout: &mut Self::RequestLayoutState,
        _prepaint: &mut Self::PrepaintState,
        window: &mut Window,
        _cx: &mut App,
    ) {
        let background =
            flowing_gradient(self.phase, self.rest, self.glow, self.lit, self.pitch, self.feather);
        let blocks = *self.keep_out.0.borrow();
        window.paint_quad(keep_out_quad(bounds, background, blocks));
    }
}

/// One quad filling `bounds`, with each keep-out block (grown by
/// [`KEEP_OUT_PADDING`]) encoded as its right edge, bottom edge, width and
/// height in logical pixels from the quad's origin. A tag-4 quad draws no
/// border or rounding, so the shader reads the first block from the corner
/// radii and the second from the border widths; an absent block is all zeros.
/// Edges are stored rather than origins because the renderer clamps border
/// widths at zero, and a block whose right or bottom edge is short of the
/// quad is off screen anyway.
fn keep_out_quad(
    bounds: Bounds<Pixels>,
    background: Background,
    blocks: [Option<Bounds<Pixels>>; KEEP_OUT_SLOTS],
) -> PaintQuad {
    let encode = |block: Option<Bounds<Pixels>>| -> [Pixels; 4] {
        let Some(block) = block else { return [px(0.); 4] };
        let block = block.dilate(px(KEEP_OUT_PADDING));
        [
            block.right() - bounds.origin.x,
            block.bottom() - bounds.origin.y,
            block.size.width,
            block.size.height,
        ]
    };
    let [right, bottom, width, height] = encode(blocks[0]);
    let corners = Corners { top_left: right, top_right: bottom, bottom_right: width, bottom_left: height };
    let [right, bottom, width, height] = encode(blocks[1]);
    let edges = Edges { top: right, right: bottom, bottom: width, left: height };
    quad(bounds, corners, background, edges, Hsla::transparent_black(), BorderStyle::default())
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::{hsla, point};

    fn colour() -> Hsla {
        hsla(0.6, 0.8, 0.5, 0.5)
    }

    #[test]
    fn shader_parameters_preserve_the_gpu_abi_and_loop_seam() {
        // DirectX StructuredBuffer<Background> uses this exact existing stride.
        assert_eq!(std::mem::size_of::<Background>(), 72);
        let c = colour();
        let start = flowing_gradient(0., c, c, c, 10., 40.);
        assert_eq!(start, flowing_gradient(std::f32::consts::TAU, c, c, c, 10., 40.));
        assert_eq!(start, flowing_gradient(f32::NAN, c, c, c, 10., 40.));
        assert!(start.opacity(0.).is_transparent());
        assert!(!flowing_gradient(0., c.opacity(0.), c, c, 0., 0.).is_transparent());
        let encoded = serde_json::to_value(start).unwrap();
        assert_eq!(encoded["tag"], "FlowingGradient");
        assert_eq!(encoded["colors"][0]["percentage"], serde_json::json!(10_f32));
        assert_eq!(encoded["colors"][1]["percentage"], serde_json::json!(40_f32));
        // The pitch never collapses the grid and the feather never collapses
        // the fade: NaN and zero fall back to the minimum.
        let tiny = serde_json::to_value(flowing_gradient(0., c, c, c, f32::NAN, f32::NAN)).unwrap();
        assert_eq!(tiny["colors"][0]["percentage"], serde_json::json!(2_f32));
        assert_eq!(tiny["colors"][1]["percentage"], serde_json::json!(1_f32));
        let zero = serde_json::to_value(flowing_gradient(0., c, c, c, 0., 0.)).unwrap();
        assert_eq!(zero["colors"][1]["percentage"], serde_json::json!(1_f32));
    }

    #[test]
    fn keep_out_blocks_travel_as_padded_edges_from_the_quad_origin() {
        let quad_bounds = Bounds::new(point(px(100.), px(50.)), size(px(800.), px(600.)));
        let heading = Bounds::new(point(px(300.), px(200.)), size(px(200.), px(40.)));
        let card = Bounds::new(point(px(250.), px(400.)), size(px(500.), px(150.)));
        let c = colour();
        let background = flowing_gradient(0., c, c, c, 10., 40.);

        let quad = keep_out_quad(quad_bounds, background, [Some(heading), Some(card)]);
        assert_eq!(quad.bounds, quad_bounds);
        assert_eq!(quad.background, background);
        assert!(quad.border_color.is_transparent());
        // First block in the corner radii: padded right and bottom edges, then the padded size.
        assert_eq!(quad.corner_radii.top_left, px(300. + 200. + 12. - 100.));
        assert_eq!(quad.corner_radii.top_right, px(200. + 40. + 12. - 50.));
        assert_eq!(quad.corner_radii.bottom_right, px(200. + 24.));
        assert_eq!(quad.corner_radii.bottom_left, px(40. + 24.));
        // Second block in the border widths.
        assert_eq!(quad.border_widths.top, px(250. + 500. + 12. - 100.));
        assert_eq!(quad.border_widths.right, px(400. + 150. + 12. - 50.));
        assert_eq!(quad.border_widths.bottom, px(500. + 24.));
        assert_eq!(quad.border_widths.left, px(150. + 24.));

        // An absent block is all zeros, which the shader reads as no keep-out.
        let none = keep_out_quad(quad_bounds, background, [None, Some(card)]);
        assert_eq!(none.corner_radii, Corners::default());
        assert_eq!(none.border_widths, quad.border_widths);
    }

    #[test]
    fn a_block_is_the_union_of_its_children() {
        assert_eq!(union(&[]), None);
        let a = Bounds::new(point(px(10.), px(10.)), size(px(20.), px(5.)));
        let b = Bounds::new(point(px(5.), px(30.)), size(px(10.), px(10.)));
        assert_eq!(union(&[a]), Some(a));
        assert_eq!(union(&[a, b]), Some(Bounds::new(point(px(5.), px(10.)), size(px(25.), px(30.)))));
    }
}
