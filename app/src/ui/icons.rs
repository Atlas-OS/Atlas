//! Segoe Fluent Icons glyphs, the same font Windows 11 shell surfaces use.

use gpui::{
    App, Div, IntoElement, ParentElement, Pixels, Rems, RenderOnce, Styled, Window, canvas, div, point, px,
};

use super::Typography;
use super::typography::cap_center_offset;
use crate::theme::FONT_ICONS;

/// The full Segoe Fluent set the app draws from; not every glyph is in use.
#[allow(dead_code)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Icon {
    Home,
    PC,
    Devices,
    Usb,
    Disc,
    Download,
    Sync,
    Settings,
    Shield,
    CheckMark,
    Cancel,
    Warning,
    Info,
    ErrorBadge,
    Completed,
    ChevronRight,
    ChevronDown,
    ChevronUp,
    OpenInNewWindow,
    Refresh,
    Wifi,
    Power,
    Folder,
    Copy,
    Link,
    History,
    Lock,
    Unlock,
    Cloud,
    Globe,
    Unknown,
    Play,
    Diagnostic,
    Admin,
    Package,
    Back,
    Minimize,
    Maximize,
    Restore,
    Close,
}

impl Icon {
    pub fn glyph(self) -> &'static str {
        match self {
            Icon::PC => "\u{E7F4}",
            Icon::Devices => "\u{E772}",
            Icon::Usb => "\u{E88E}",
            Icon::Disc => "\u{E958}",
            Icon::Home => "\u{E80F}",
            Icon::Download => "\u{E896}",
            Icon::Sync => "\u{E895}",
            Icon::Settings => "\u{E713}",
            Icon::Shield => "\u{EA18}",
            Icon::CheckMark => "\u{E73E}",
            Icon::Cancel => "\u{E711}",
            Icon::Warning => "\u{E7BA}",
            Icon::Info => "\u{E946}",
            Icon::ErrorBadge => "\u{EA39}",
            Icon::Completed => "\u{E930}",
            Icon::ChevronRight => "\u{E76C}",
            Icon::ChevronDown => "\u{E70D}",
            Icon::ChevronUp => "\u{E70E}",
            Icon::OpenInNewWindow => "\u{E8A7}",
            Icon::Refresh => "\u{E72C}",
            Icon::Wifi => "\u{E701}",
            Icon::Power => "\u{E7E8}",
            Icon::Folder => "\u{E8B7}",
            Icon::Copy => "\u{E8C8}",
            Icon::Link => "\u{E71B}",
            Icon::History => "\u{E81C}",
            Icon::Lock => "\u{E72E}",
            Icon::Unlock => "\u{E785}",
            Icon::Cloud => "\u{E753}",
            Icon::Globe => "\u{E774}",
            Icon::Unknown => "\u{E9CE}",
            Icon::Play => "\u{E768}",
            Icon::Diagnostic => "\u{E9D9}",
            Icon::Admin => "\u{E7EF}",
            Icon::Package => "\u{E7B8}",
            Icon::Back => "\u{E72B}",
            Icon::Minimize => "\u{E921}",
            Icon::Maximize => "\u{E922}",
            Icon::Restore => "\u{E923}",
            Icon::Close => "\u{E8BB}",
        }
    }
}

/// A 16px glyph that inherits the surrounding text colour.
pub fn icon(icon: Icon) -> Div {
    icon_sized(icon, 16.)
}

/// A 16px glyph centred on the visible capitals of the adjacent body text.
/// Override typography on the returned wrapper when the label uses another weight.
pub fn icon_in_line(icon: Icon, line_height: Rems) -> Div {
    icon_in_line_sized(icon, 16., line_height)
}

pub fn icon_in_line_sized(icon: Icon, size: f32, line_height: Rems) -> Div {
    div().flex().flex_shrink_0().items_center().h(line_height).type_body().child(InlineIcon { icon, size })
}

#[derive(IntoElement)]
struct InlineIcon {
    icon: Icon,
    size: f32,
}

impl RenderOnce for InlineIcon {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let style = window.text_style();
        let offset =
            cap_center_offset(style.font(), style.font_size.to_pixels(window.rem_size()), window, cx);
        icon_with_offset(self.icon, self.size, offset)
    }
}

pub fn icon_sized(icon: Icon, size: f32) -> Div {
    icon_with_offset(icon, size, px(0.))
}

fn icon_with_offset(icon: Icon, size: f32, text_offset: Pixels) -> Div {
    div()
        .flex()
        .flex_shrink_0()
        .items_center()
        .justify_center()
        .size(px(size))
        .font_family(FONT_ICONS)
        .font_weight(gpui::FontWeight::NORMAL)
        .text_size(px(size))
        .line_height(px(size))
        .child(CentredGlyph { icon, text_offset })
}

/// Icon fonts have their own bearings. Centre the actual glyph ink inside
/// its square before positioning that square beside text or inside a control.
#[derive(IntoElement)]
struct CentredGlyph {
    icon: Icon,
    text_offset: Pixels,
}

impl RenderOnce for CentredGlyph {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let style = window.text_style();
        let font_size = style.font_size.to_pixels(window.rem_size());
        let glyph = self.icon.glyph();
        let font_id = cx.text_system().resolve_font(&style.font());
        let line =
            window.text_system().shape_line(glyph.into(), font_size, &[style.to_run(glyph.len())], None);
        let (x, y) = cx
            .text_system()
            .typographic_bounds(font_id, font_size, glyph.chars().next().unwrap())
            // Typographic bounds use an upward-positive baseline coordinate.
            .map(|bounds| {
                (
                    line.width / 2. - bounds.origin.x - bounds.size.width / 2.,
                    bounds.origin.y + bounds.size.height / 2. - (line.ascent - line.descent) / 2.,
                )
            })
            .unwrap_or((px(0.), px(0.)));
        // Combine the icon's bearings and the label's cap alignment before the
        // renderer quantizes once. Relative layout offsets round separately.
        canvas(
            |_, _, _| (),
            move |bounds, (), window, cx| {
                let origin =
                    bounds.origin + point((bounds.size.width - line.width) / 2. + x, y + self.text_offset);
                if let Err(error) =
                    line.paint(origin, bounds.size.height, gpui::TextAlign::Left, None, window, cx)
                {
                    log::error!("Could not paint icon: {error}");
                }
            },
        )
        .size(font_size)
    }
}
