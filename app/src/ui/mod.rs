//! Fluent controls built on GPUI primitives. Each control is a `RenderOnce`
//! component that reads the active [`Theme`](crate::theme::Theme), carries
//! its accessible role and name, and takes part in keyboard traversal.

mod button;
mod card;
mod completion_backdrop;
mod icons;
mod infobar;
mod markdown;
mod progress;
mod scrollbar;
mod selection;
mod status;
mod text_mark;
mod titlebar;
mod typography;

pub use button::Button;
pub use card::card;
pub use completion_backdrop::CompletionBackdrop;
pub use icons::{Icon, icon, icon_in_line, icon_in_line_sized, icon_sized};
pub use infobar::{InfoBar, Severity};
pub use markdown::{Block as MarkdownBlock, Markdown, parse as parse_markdown};
pub use progress::{ProgressBar, ProgressRing};
pub use scrollbar::{ScrollbarState, scrollbar};
pub use selection::{CheckBox, FocusHandles, RadioGroup, RadioItem};
pub use status::{LightState, StatusLight};
pub use text_mark::TextMark;
pub use titlebar::TitleBar;
pub use typography::{
    BODY_LINE_HEIGHT, CapCenteredText, Typography, body_cap_center_offset, centred_step_number,
};

/// Keyboard actions the shell and controls respond to. The key bindings are
/// installed in `main`.
pub mod actions {
    gpui::actions!(atlas, [FocusNext, FocusPrevious, RadioNext, RadioPrevious]);
}

/// The Windows focus visual: a 2px outer ring with a 1px inner ring, drawn
/// with the element's border and inset shadows so it never paints behind a
/// transparent control. Elements need a 1px (transparent) border already.
pub fn focus_ring<S: gpui::Styled>(style: S, outer: gpui::Hsla, inner: gpui::Hsla) -> S {
    use gpui::{BoxShadow, point, px};
    style.border_color(outer).shadow(vec![
        BoxShadow {
            color: inner,
            offset: point(px(0.), px(0.)),
            blur_radius: px(0.),
            spread_radius: px(2.),
            inset: true,
        },
        BoxShadow {
            color: outer,
            offset: point(px(0.), px(0.)),
            blur_radius: px(0.),
            spread_radius: px(1.),
            inset: true,
        },
    ])
}

/// Accessible plain text: a labelled text node screen readers can read.
/// Ordinary string children are drawn but not reported.
pub fn a11y_text(id: impl Into<gpui::ElementId>, text: impl Into<gpui::SharedString>) -> gpui::Text {
    gpui::Text::new(id.into(), text.into())
}
pub mod text_input;
