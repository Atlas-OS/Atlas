//! The Windows 11 type ramp, applied to any styled element.
//!
//! Sizes are in rems so the Ease of Access text size scales the whole ramp:
//! the shell sets the window's rem size to 16px times the user's text scale.

use gpui::{
    App, Div, Font, FontWeight, IntoElement, ParentElement, Pixels, Rems, RenderOnce, SharedString, Styled,
    TextRun, Window, black, canvas, div, font, point, px,
};

use crate::theme::{FONT_DISPLAY, FONT_MONO, FONT_TEXT};

/// Pixels at the default text size, as rems.
const fn r(px: f32) -> Rems {
    Rems(px / 16.)
}

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

/// A single step digit centred by its visible bounds, including side bearings.
/// The surrounding circle controls its colour and diameter.
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
        let style = window.text_style();
        let font_size = style.font_size.to_pixels(window.rem_size());
        let font_id = cx.text_system().resolve_font(&style.font());
        let line =
            window.text_system().shape_line(self.0.clone(), font_size, &[style.to_run(self.0.len())], None);
        let bounds = self
            .0
            .chars()
            .next()
            .and_then(|digit| cx.text_system().typographic_bounds(font_id, font_size, digit).ok());
        let (x, y) = bounds
            .map(|bounds| {
                (
                    line.width / 2. - bounds.origin.x - bounds.size.width / 2.,
                    bounds.origin.y + bounds.size.height / 2. - (line.ascent - line.descent) / 2.,
                )
            })
            .unwrap_or((px(0.), px(0.)));
        // Layout snaps relative offsets to device pixels. Apply the alignment
        // during painting so the glyph renderer retains horizontal subpixels.
        // The parent step already exposes the number through its accessible name.
        canvas(
            |_, _, _| (),
            move |bounds, (), window, cx| {
                let line_height = bounds.size.height;
                let origin = bounds.origin + point((bounds.size.width - line.width) / 2. + x, y);
                if let Err(error) = line.paint(origin, line_height, gpui::TextAlign::Left, None, window, cx) {
                    log::error!("Could not paint step number: {error}");
                }
            },
        )
        .w_full()
        .h(px(20.))
    }
}

/// Offset from the body line's centre to the centre of its capital letters.
/// GPUI centres ascent + descent, not visible ink; reducing line height does
/// not remove that difference. Use the resolved font metrics for adjacent marks.
pub fn body_cap_center_offset(window: &Window, cx: &App) -> Pixels {
    cap_center_offset(font(FONT_TEXT), r(14.).to_pixels(window.rem_size()), window, cx)
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
        self.font_family(FONT_TEXT).text_size(r(12.)).line_height(r(16.)).font_weight(FontWeight::NORMAL)
    }

    /// 14/20 regular. Default reading size.
    fn type_body(self) -> Self {
        self.font_family(FONT_TEXT).text_size(r(14.)).line_height(r(20.)).font_weight(FontWeight::NORMAL)
    }

    /// 14/20 semibold. Control labels, list item titles.
    fn type_body_strong(self) -> Self {
        self.font_family(FONT_TEXT).text_size(r(14.)).line_height(r(20.)).font_weight(FontWeight::SEMIBOLD)
    }

    /// 18/24 regular.
    fn type_body_large(self) -> Self {
        self.font_family(FONT_TEXT).text_size(r(18.)).line_height(r(24.)).font_weight(FontWeight::NORMAL)
    }

    /// 20/28 semibold. Section headings.
    fn type_subtitle(self) -> Self {
        self.font_family(FONT_DISPLAY).text_size(r(20.)).line_height(r(28.)).font_weight(FontWeight::SEMIBOLD)
    }

    /// 28/36 semibold. Page titles.
    fn type_title(self) -> Self {
        self.font_family(FONT_DISPLAY).text_size(r(28.)).line_height(r(36.)).font_weight(FontWeight::SEMIBOLD)
    }

    /// 40/52 semibold. The version stamp on the home page.
    fn type_title_large(self) -> Self {
        self.font_family(FONT_DISPLAY).text_size(r(40.)).line_height(r(52.)).font_weight(FontWeight::SEMIBOLD)
    }

    /// 12/18 monospace. Command lines and logs.
    fn type_mono(self) -> Self {
        self.font_family(FONT_MONO).text_size(r(12.)).line_height(r(18.)).font_weight(FontWeight::NORMAL)
    }
}

impl<T: Styled> Typography for T {}
