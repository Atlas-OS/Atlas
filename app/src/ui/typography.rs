//! The Windows 11 type ramp, applied to any styled element.
//!
//! Sizes are in rems so the Ease of Access text size scales the whole ramp:
//! the shell sets the window's rem size to 16px times the user's text scale.
//! The display end of the ramp (body large, subtitle, title, title large)
//! grows less, as WinUI's does: proportionally less the larger it already is,
//! so at 225% a page title stays a title rather than taking the window. Body
//! text keeps growing by the whole factor, so each display size keeps the
//! proportion to body text that WinUI gives it, and a heading is never drawn
//! smaller than the text under it.

use std::sync::atomic::{AtomicU32, Ordering};

use gpui::{
    App, Canvas, Div, Font, FontWeight, IntoElement, ParentElement, Pixels, Rems, RenderOnce, SharedString,
    Styled, TextAlign, TextRun, Window, black, canvas, div, font, point, px,
};

use crate::theme::{FONT_DISPLAY, FONT_MONO, FONT_TEXT};

/// Pixels at the default text size, as rems.
const fn r(px: f32) -> Rems {
    Rems(px / 16.)
}

/// The Ease of Access text scale the shell last applied, as f32 bits (1.0
/// until it does), for the display sizes below.
static TEXT_SCALE: AtomicU32 = AtomicU32::new(0x3F80_0000);

/// Records the text scale the window's rem size was set from. The shell
/// calls this beside `set_rem_size` on every render.
pub fn set_text_scale(scale: f32) {
    TEXT_SCALE.store(scale.max(1.).to_bits(), Ordering::Relaxed);
}

fn text_scale() -> f32 {
    f32::from_bits(TEXT_SCALE.load(Ordering::Relaxed))
}

/// The size WinUI draws `px` at for text scale `scale`
/// (TextFormatting::GetScaledFontSize): small text grows by nearly the whole
/// factor, display text by much less, and nothing at or above about 754px.
pub fn scaled_text_px(px: f32, scale: f32) -> f32 {
    let size = px.max(1.);
    size + (18. - std::f32::consts::E * size.ln()).max(0.) * (scale - 1.)
}

/// Body text's size at the default text scale, in pixels.
const BODY_PX: f32 = 14.;

/// The size a display style of `px` is drawn at for text scale `scale`:
/// WinUI's scaled size for it, in the proportion WinUI keeps to body text.
/// Body text here grows by the whole factor (layout across the app is built
/// on it), while WinUI's grows a little less; without this, a 20px subtitle
/// would come out smaller than 14px body text at 225%.
pub fn display_px(px: f32, scale: f32) -> f32 {
    scaled_text_px(px, scale) * (BODY_PX * scale) / scaled_text_px(BODY_PX, scale)
}

/// A display size and its line height, as rems that render at
/// [`display_px`] once the shell has set the rem size to 16px times the scale.
fn display(size: f32, line_height: f32) -> (Rems, Rems) {
    let scale = text_scale();
    let scaled = display_px(size, scale);
    let rem = 16. * scale;
    (Rems(scaled / rem), Rems(line_height * scaled / size / rem))
}

/// A page title's size and line height at the current text scale.
pub(super) fn title_metrics() -> (Rems, Rems) {
    display(28., 36.)
}
pub(super) const CAPTION_SIZE: Rems = r(12.);
pub(super) const CAPTION_LINE_HEIGHT: Rems = r(16.);
pub(super) const BODY_SIZE: Rems = r(BODY_PX);
/// The line height of `type_body` and `type_body_strong`, for marks that
/// must centre on a line of body text.
pub const BODY_LINE_HEIGHT: Rems = r(20.);

/// Text whose visible capitals are centred in its line box. Keep GPUI's
/// normal measurement and wrapping; adjust the painted origin after layout.
/// The containing control supplies the accessible name.
pub struct CapCenteredText(pub SharedString);

impl IntoElement for CapCenteredText {
    type Element = Self;
    fn into_element(self) -> Self {
        self
    }
}

impl gpui::Element for CapCenteredText {
    type RequestLayoutState = (<SharedString as gpui::Element>::RequestLayoutState, Pixels);
    type PrepaintState = ();

    fn id(&self) -> Option<gpui::ElementId> {
        None
    }
    fn source_location(&self) -> Option<&'static core::panic::Location<'static>> {
        None
    }

    fn request_layout(
        &mut self,
        id: Option<&gpui::GlobalElementId>,
        inspector: Option<&gpui::InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (gpui::LayoutId, Self::RequestLayoutState) {
        let style = window.text_style();
        let offset =
            cap_center_offset(style.font(), style.font_size.to_pixels(window.rem_size()), window, cx);
        let (layout, state) = self.0.request_layout(id, inspector, window, cx);
        (layout, (state, offset))
    }

    fn prepaint(
        &mut self,
        id: Option<&gpui::GlobalElementId>,
        inspector: Option<&gpui::InspectorElementId>,
        mut bounds: gpui::Bounds<Pixels>,
        state: &mut Self::RequestLayoutState,
        window: &mut Window,
        cx: &mut App,
    ) {
        bounds.origin.y -= state.1;
        self.0.prepaint(id, inspector, bounds, &mut state.0, window, cx);
    }

    fn paint(
        &mut self,
        id: Option<&gpui::GlobalElementId>,
        inspector: Option<&gpui::InspectorElementId>,
        mut bounds: gpui::Bounds<Pixels>,
        state: &mut Self::RequestLayoutState,
        prepaint: &mut (),
        window: &mut Window,
        cx: &mut App,
    ) {
        bounds.origin.y -= state.1;
        self.0.paint(id, inspector, bounds, &mut state.0, prepaint, window, cx);
    }
}

/// A step digit centred on its ink. Sized in px, not rems, so it fits the
/// fixed 22px step circle at any text size; the circle sets its colour.
pub fn centred_step_number(number: impl Into<SharedString>) -> Div {
    div()
        .flex()
        .justify_center()
        .w_full()
        .font_family(FONT_TEXT)
        .font_weight(FontWeight::SEMIBOLD)
        .text_size(px(11.))
        .line_height(px(20.))
        .child(CentredStepNumber(number.into()))
}

#[derive(IntoElement)]
struct CentredStepNumber(SharedString);

impl RenderOnce for CentredStepNumber {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        // Not accessible itself: the step around it carries the number in its name.
        ink_centred(self.0, px(0.), window, cx).w_full().h(px(20.))
    }
}

/// `text` painted so the ink of its first character, rather than its line
/// box, is centred in the element, then moved down by `shift`. Both offsets
/// are applied when painting, so the glyph renderer rounds their sum once and
/// keeps horizontal subpixels; layout offsets would each snap to a pixel.
pub(super) fn ink_centred(text: SharedString, shift: Pixels, window: &Window, cx: &App) -> Canvas<()> {
    let style = window.text_style();
    let font_size = style.font_size.to_pixels(window.rem_size());
    let font_id = cx.text_system().resolve_font(&style.font());
    let line = window.text_system().shape_line(text.clone(), font_size, &[style.to_run(text.len())], None);
    let (x, y) = text
        .chars()
        .next()
        .and_then(|first| cx.text_system().typographic_bounds(font_id, font_size, first).ok())
        // Typographic bounds measure upwards from the baseline.
        .map(|ink| {
            (
                line.width / 2. - ink.origin.x - ink.size.width / 2.,
                ink.origin.y + ink.size.height / 2. - (line.ascent - line.descent) / 2.,
            )
        })
        .unwrap_or_default();
    canvas(
        |_, _, _| (),
        move |bounds, (), window, cx| {
            let origin = bounds.origin + point((bounds.size.width - line.width) / 2. + x, y + shift);
            if let Err(error) = line.paint(origin, bounds.size.height, TextAlign::Left, None, window, cx) {
                log::error!("could not paint {text:?}: {error}");
            }
        },
    )
}

/// Offset from a body line's centre to the centre of its capitals, for marks
/// beside body text. GPUI centres the line box (ascent + descent), not the ink.
pub fn body_cap_center_offset(window: &Window, cx: &App) -> Pixels {
    cap_center_offset(font(FONT_TEXT), BODY_SIZE.to_pixels(window.rem_size()), window, cx)
}

/// Centre of visible capitals relative to the centre of the font's line box.
pub fn cap_center_offset(font: Font, font_size: Pixels, window: &Window, cx: &App) -> Pixels {
    let text_system = cx.text_system();
    let font_id = text_system.resolve_font(&font);
    // Use the same shaped metrics as line painting. On DirectWrite the raw
    // font descent is negative, while the shaped line's descent is positive.
    let line = window.text_system().shape_line(
        "H".into(),
        font_size,
        &[TextRun {
            len: 1,
            font,
            color: black(),
            background_color: None,
            underline: None,
            strikethrough: None,
        }],
        None,
    );
    // (line_height - ascent - descent) / 2 + ascent - cap_height / 2
    // minus line_height / 2 simplifies to the expression below.
    (line.ascent - line.descent - text_system.cap_height(font_id, font_size)) / 2.
}

pub trait Typography: Styled + Sized {
    /// 12/16 regular. Timestamps, hints, captions.
    fn type_caption(self) -> Self {
        self.font_family(FONT_TEXT)
            .text_size(CAPTION_SIZE)
            .line_height(CAPTION_LINE_HEIGHT)
            .font_weight(FontWeight::NORMAL)
    }

    /// 14/20 regular. Default reading size.
    fn type_body(self) -> Self {
        self.font_family(FONT_TEXT)
            .text_size(BODY_SIZE)
            .line_height(BODY_LINE_HEIGHT)
            .font_weight(FontWeight::NORMAL)
    }

    /// 14/20 semibold. Control labels, list item titles.
    fn type_body_strong(self) -> Self {
        self.font_family(FONT_TEXT)
            .text_size(BODY_SIZE)
            .line_height(BODY_LINE_HEIGHT)
            .font_weight(FontWeight::SEMIBOLD)
    }

    /// 18/24 regular, scaled as WinUI scales display text.
    fn type_body_large(self) -> Self {
        let (size, line) = display(18., 24.);
        self.font_family(FONT_TEXT).text_size(size).line_height(line).font_weight(FontWeight::NORMAL)
    }

    /// 20/28 semibold. Section headings.
    fn type_subtitle(self) -> Self {
        let (size, line) = display(20., 28.);
        self.font_family(FONT_DISPLAY).text_size(size).line_height(line).font_weight(FontWeight::SEMIBOLD)
    }

    /// 28/36 semibold. Page titles.
    fn type_title(self) -> Self {
        let (size, line) = title_metrics();
        self.font_family(FONT_DISPLAY).text_size(size).line_height(line).font_weight(FontWeight::SEMIBOLD)
    }

    /// 40/52 semibold. The version stamp on the home page.
    fn type_title_large(self) -> Self {
        let (size, line) = display(40., 52.);
        self.font_family(FONT_DISPLAY).text_size(size).line_height(line).font_weight(FontWeight::SEMIBOLD)
    }

    /// 12/18 monospace. Command lines and logs.
    fn type_mono(self) -> Self {
        self.font_family(FONT_MONO).text_size(r(12.)).line_height(r(18.)).font_weight(FontWeight::NORMAL)
    }
}

impl<T: Styled> Typography for T {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn display_text_grows_less_than_body_text_as_windows_scales_it() {
        assert_eq!(scaled_text_px(28., 1.), 28.);
        // WinUI's own figures at 225%: a 28px title near 39px, 14px body near 27.5px.
        assert!((scaled_text_px(28., 2.25) - 39.2).abs() < 0.2, "{}", scaled_text_px(28., 2.25));
        assert!((scaled_text_px(14., 2.25) - 27.5).abs() < 0.2, "{}", scaled_text_px(14., 2.25));
        assert!(scaled_text_px(40., 2.25) < 40. * 2.25 && scaled_text_px(40., 2.25) > 40.);
        // Very large text doesn't grow at all.
        assert_eq!(scaled_text_px(800., 2.25), 800.);
    }

    #[test]
    fn display_text_stays_larger_than_body_text_at_every_scale() {
        for scale in [1., 1.25, 1.5, 2., 2.25] {
            let body = BODY_PX * scale;
            let [large, subtitle, title, title_large] = [18., 20., 28., 40.].map(|px| display_px(px, scale));
            assert!(body < large && large < subtitle && subtitle < title && title < title_large, "{scale}");
        }
        // Unscaled, every size is its own; at 225% a title still grows far
        // less than linearly (63px), about 45px beside 31.5px body text.
        assert_eq!(display_px(28., 1.), 28.);
        let title = display_px(28., 2.25);
        assert!((44. ..46.).contains(&title), "{title}");
    }
}
