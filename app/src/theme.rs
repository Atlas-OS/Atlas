//! Fluent design tokens for Windows 11, in Atlas blue.
//!
//! Every colour the UI paints comes from here. The values follow the WinUI 3
//! common resource dictionary (text, control, card, layer and subtle fills as
//! black/white at fixed opacities) so the app reads as native next to Settings,
//! with the brand blue standing in for the system accent. When a Windows
//! contrast theme is active the palette is built from the system colours
//! instead, and the Ease of Access text size and animation preferences are
//! carried here so every control can honour them.

use gpui::{App, Global, Hsla, Rgba, WindowAppearance, rgb};

use crate::services::settings::ThemePreference;
use crate::services::system::{AccessibilityPreferences, SystemColors};

pub const FONT_TEXT: &str = "Segoe UI Variable Text";
pub const FONT_DISPLAY: &str = "Segoe UI Variable Display";
pub const FONT_ICONS: &str = "Segoe Fluent Icons";
pub const FONT_MONO: &str = "Cascadia Mono";

/// Brand blue from the website and logo. Used for artwork; control fills use
/// a shade that keeps white text readable.
pub const ATLAS_BLUE: u32 = 0x1A91FF;
/// The light-mode accent fill: Atlas blue darkened until white text on it
/// clears the 4.5:1 contrast benchmark, as WinUI does with AccentDark1.
pub const ATLAS_BLUE_DARK1: u32 = 0x0A6BD4;
pub const ATLAS_BLUE_DARK2: u32 = 0x0862C2;
pub const ATLAS_BLUE_DARK3: u32 = 0x0759AF;
/// The dark-mode accent: lifted so near-black text sits on it.
pub const ATLAS_BLUE_LIGHT2: u32 = 0x5EB5FF;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Appearance {
    Light,
    Dark,
}

impl Appearance {
    pub fn from_window(appearance: WindowAppearance) -> Self {
        match appearance {
            WindowAppearance::Dark | WindowAppearance::VibrantDark => Appearance::Dark,
            WindowAppearance::Light | WindowAppearance::VibrantLight => Appearance::Light,
        }
    }

    pub fn is_dark(self) -> bool {
        matches!(self, Appearance::Dark)
    }
}

#[derive(Clone, Debug)]
pub struct Theme {
    pub appearance: Appearance,
    /// True when the window can show Mica: the app follows the system
    /// appearance, so DWM's tint matches the UI. Otherwise the root paints
    /// `solid_background` itself.
    pub mica: bool,
    /// A Windows contrast theme is active: system colours, no translucency.
    pub high_contrast: bool,
    /// "Show animations in Windows" is off: progress indicators hold still.
    pub reduce_motion: bool,
    /// The Ease of Access text size, applied through the window's rem size.
    pub text_scale: f32,

    /// The Atlas mark and other artwork.
    pub brand: Hsla,

    pub text_primary: Hsla,
    pub text_secondary: Hsla,
    pub text_tertiary: Hsla,
    pub text_disabled: Hsla,
    pub text_on_accent: Hsla,
    pub text_on_accent_disabled: Hsla,

    pub accent: Hsla,
    pub accent_hover: Hsla,
    pub accent_pressed: Hsla,
    pub accent_disabled: Hsla,
    pub accent_text: Hsla,
    pub accent_text_hover: Hsla,

    pub control_fill: Hsla,
    pub control_fill_hover: Hsla,
    pub control_fill_pressed: Hsla,
    pub control_fill_disabled: Hsla,
    /// A focused text box's fill (WinUI ControlFillColorInputActive).
    pub control_fill_input_active: Hsla,
    pub control_stroke: Hsla,
    pub control_stroke_secondary: Hsla,
    pub control_stroke_on_accent_secondary: Hsla,
    pub control_strong_stroke: Hsla,
    pub control_strong_stroke_disabled: Hsla,

    pub subtle_hover: Hsla,
    pub subtle_pressed: Hsla,

    pub card_fill: Hsla,
    pub card_stroke: Hsla,
    pub layer_fill: Hsla,
    pub layer_stroke: Hsla,
    pub solid_background: Hsla,
    pub divider: Hsla,
    /// Tooltips and flyouts: the solid colour WinUI's acrylic falls back to.
    pub flyout_fill: Hsla,
    pub flyout_stroke: Hsla,

    pub focus_outer: Hsla,
    pub focus_inner: Hsla,

    pub success: Hsla,
    pub success_fill: Hsla,
    pub caution: Hsla,
    pub caution_fill: Hsla,
    pub critical: Hsla,
    pub critical_fill: Hsla,
    pub info: Hsla,
    pub info_fill: Hsla,
}

impl Global for Theme {}

fn c(hex: u32) -> Hsla {
    rgb(hex).into()
}

fn tint(rgb_hex: u32, alpha: f32) -> Hsla {
    let mut colour: Rgba = rgb(rgb_hex);
    colour.a = alpha;
    colour.into()
}

impl Theme {
    pub fn resolve(
        preference: ThemePreference,
        system: Appearance,
        accessibility: &AccessibilityPreferences,
    ) -> Theme {
        let mut theme = match accessibility.system_colors {
            Some(colors) if accessibility.high_contrast => Theme::high_contrast(colors),
            _ => {
                let (appearance, mica) = match preference {
                    ThemePreference::System => (system, true),
                    ThemePreference::Light => (Appearance::Light, system == Appearance::Light),
                    ThemePreference::Dark => (Appearance::Dark, system == Appearance::Dark),
                };
                let mut theme = match appearance {
                    Appearance::Light => Theme::light(),
                    Appearance::Dark => Theme::dark(),
                };
                theme.mica = mica;
                theme
            }
        };
        theme.reduce_motion = accessibility.reduce_motion;
        theme.text_scale = accessibility.text_scale;
        theme
    }

    pub fn light() -> Theme {
        Theme {
            appearance: Appearance::Light,
            mica: true,
            high_contrast: false,
            reduce_motion: false,
            text_scale: 1.0,

            brand: c(ATLAS_BLUE),

            text_primary: tint(0x000000, 0.896),
            text_secondary: tint(0x000000, 0.606),
            text_tertiary: tint(0x000000, 0.446),
            text_disabled: tint(0x000000, 0.361),
            text_on_accent: c(0xFFFFFF),
            text_on_accent_disabled: c(0xFFFFFF),

            accent: c(ATLAS_BLUE_DARK1),
            accent_hover: c(ATLAS_BLUE_DARK2),
            accent_pressed: c(ATLAS_BLUE_DARK3),
            accent_disabled: tint(0x000000, 0.217),
            accent_text: c(ATLAS_BLUE_DARK1),
            accent_text_hover: c(0x0857AD),

            control_fill: tint(0xFFFFFF, 0.7),
            control_fill_hover: tint(0xF9F9F9, 0.5),
            control_fill_pressed: tint(0xF9F9F9, 0.3),
            control_fill_disabled: tint(0xF9F9F9, 0.3),
            control_fill_input_active: c(0xFFFFFF),
            control_stroke: tint(0x000000, 0.0578),
            control_stroke_secondary: tint(0x000000, 0.1622),
            control_stroke_on_accent_secondary: tint(0x000000, 0.14),
            control_strong_stroke: tint(0x000000, 0.4458),
            control_strong_stroke_disabled: tint(0x000000, 0.2169),

            subtle_hover: tint(0x000000, 0.0373),
            subtle_pressed: tint(0x000000, 0.0241),

            card_fill: tint(0xFFFFFF, 0.7),
            card_stroke: tint(0x000000, 0.0578),
            layer_fill: tint(0xFFFFFF, 0.5),
            layer_stroke: tint(0x000000, 0.0578),
            solid_background: c(0xF3F3F3),
            divider: tint(0x000000, 0.0803),
            flyout_fill: c(0xF9F9F9),
            flyout_stroke: tint(0x000000, 0.0578),

            focus_outer: tint(0x000000, 0.896),
            focus_inner: c(0xFFFFFF),

            success: c(0x0F7B0F),
            success_fill: c(0xDFF6DD),
            caution: c(0x9D5D00),
            caution_fill: c(0xFFF4CE),
            critical: c(0xC42B1C),
            critical_fill: c(0xFDE7E9),
            info: c(0x0A6BD4),
            info_fill: tint(0xFFFFFF, 0.5),
        }
    }

    pub fn dark() -> Theme {
        Theme {
            appearance: Appearance::Dark,
            mica: true,
            high_contrast: false,
            reduce_motion: false,
            text_scale: 1.0,

            brand: c(ATLAS_BLUE_LIGHT2),

            text_primary: c(0xFFFFFF),
            text_secondary: tint(0xFFFFFF, 0.786),
            text_tertiary: tint(0xFFFFFF, 0.544),
            text_disabled: tint(0xFFFFFF, 0.363),
            text_on_accent: tint(0x000000, 0.896),
            text_on_accent_disabled: tint(0xFFFFFF, 0.53),

            // Windows lifts the accent in dark mode so black text sits on it.
            accent: c(ATLAS_BLUE_LIGHT2),
            accent_hover: c(0x4FA8F5),
            accent_pressed: c(0x3F97E0),
            accent_disabled: tint(0xFFFFFF, 0.158),
            accent_text: c(0x7CC2FF),
            accent_text_hover: c(0x9BD0FF),

            control_fill: tint(0xFFFFFF, 0.0605),
            control_fill_hover: tint(0xFFFFFF, 0.0837),
            control_fill_pressed: tint(0xFFFFFF, 0.0326),
            control_fill_disabled: tint(0xFFFFFF, 0.0419),
            control_fill_input_active: tint(0x1E1E1E, 0.70),
            control_stroke: tint(0xFFFFFF, 0.0698),
            control_stroke_secondary: tint(0xFFFFFF, 0.093),
            control_stroke_on_accent_secondary: tint(0x000000, 0.14),
            control_strong_stroke: tint(0xFFFFFF, 0.544),
            control_strong_stroke_disabled: tint(0xFFFFFF, 0.158),

            subtle_hover: tint(0xFFFFFF, 0.0605),
            subtle_pressed: tint(0xFFFFFF, 0.0419),

            card_fill: tint(0xFFFFFF, 0.0512),
            card_stroke: tint(0xFFFFFF, 0.0698),
            layer_fill: tint(0x3A3A3A, 0.3),
            layer_stroke: tint(0xFFFFFF, 0.0698),
            solid_background: c(0x202020),
            divider: tint(0xFFFFFF, 0.0837),
            flyout_fill: c(0x2C2C2C),
            flyout_stroke: tint(0x000000, 0.2),

            focus_outer: c(0xFFFFFF),
            focus_inner: tint(0x000000, 0.7),

            success: c(0x6CCB5F),
            success_fill: c(0x393D1B),
            caution: c(0xFCE100),
            caution_fill: c(0x433519),
            critical: c(0xFF99A4),
            critical_fill: c(0x442726),
            info: c(0x7CC2FF),
            info_fill: tint(0xFFFFFF, 0.0326),
        }
    }

    /// A palette drawn entirely from the active Windows contrast theme, the
    /// way WinUI maps its brushes: window/window text for surfaces and body
    /// text, button face/text for controls, highlight for selection and the
    /// accent, hot light for links, gray text for disabled and tertiary text.
    /// Status colours collapse to text colour, so meaning is carried by the
    /// words and icons beside them. No translucency anywhere.
    pub fn high_contrast(colors: SystemColors) -> Theme {
        let window = c(colors.window);
        let text = c(colors.window_text);
        let button_face = c(colors.button_face);
        let button_text = c(colors.button_text);
        let highlight = c(colors.highlight);
        let highlight_text = c(colors.highlight_text);
        let gray = c(colors.gray_text);
        let link = c(colors.hot_light);
        let appearance = if relative_luminance(window) < 0.5 { Appearance::Dark } else { Appearance::Light };
        Theme {
            appearance,
            mica: false,
            high_contrast: true,
            reduce_motion: false,
            text_scale: 1.0,

            brand: text,

            text_primary: text,
            text_secondary: text,
            text_tertiary: gray,
            text_disabled: gray,
            text_on_accent: highlight_text,
            text_on_accent_disabled: gray,

            accent: highlight,
            accent_hover: highlight,
            accent_pressed: highlight,
            accent_disabled: button_face,
            accent_text: link,
            accent_text_hover: highlight,

            control_fill: button_face,
            control_fill_hover: highlight,
            control_fill_pressed: highlight,
            control_fill_disabled: button_face,
            control_fill_input_active: button_face,
            control_stroke: button_text,
            control_stroke_secondary: button_text,
            control_stroke_on_accent_secondary: button_text,
            control_strong_stroke: text,
            control_strong_stroke_disabled: gray,

            subtle_hover: highlight,
            subtle_pressed: highlight,

            card_fill: window,
            card_stroke: text,
            layer_fill: window,
            layer_stroke: text,
            solid_background: window,
            divider: text,
            flyout_fill: window,
            flyout_stroke: text,

            focus_outer: text,
            focus_inner: window,

            success: text,
            success_fill: window,
            caution: text,
            caution_fill: window,
            critical: text,
            critical_fill: window,
            info: text,
            info_fill: window,
        }
    }

    pub fn is_dark(&self) -> bool {
        self.appearance.is_dark()
    }

    /// Close button hover uses the same red on both appearances.
    pub fn caption_close_hover(&self) -> Hsla {
        if self.high_contrast { self.accent } else { c(0xC42B1C) }
    }

    /// The close glyph on [`Self::caption_close_hover`].
    pub fn caption_close_text(&self) -> Hsla {
        if self.high_contrast { self.text_on_accent } else { c(0xFFFFFF) }
    }

    /// Transparent, for elements that should let Mica through.
    pub fn transparent(&self) -> Hsla {
        Hsla::transparent_black()
    }

    /// Text colour for hovered controls: the high-contrast palette swaps to
    /// the highlight text colour whenever a highlight fill is used.
    pub fn text_on_hover(&self, normal: Hsla) -> Hsla {
        if self.high_contrast { self.text_on_accent } else { normal }
    }

    /// The fill behind selected text: the accent tinted, as Windows text
    /// boxes show it, or a contrast theme's highlight, opaque.
    pub fn selection_fill(&self) -> Hsla {
        if self.high_contrast { self.accent } else { self.accent.opacity(0.4) }
    }

    /// The colour selected text takes on [`Self::selection_fill`]: the
    /// highlight text colour in a contrast theme; elsewhere it keeps its own.
    pub fn selection_text(&self) -> Option<Hsla> {
        self.high_contrast.then_some(self.text_on_accent)
    }
}

/// WCAG relative luminance of an opaque colour.
fn relative_luminance(colour: Hsla) -> f32 {
    let rgba: Rgba = colour.into();
    fn channel(c: f32) -> f32 {
        if c <= 0.03928 { c / 12.92 } else { ((c + 0.055) / 1.055).powf(2.4) }
    }
    0.2126 * channel(rgba.r) + 0.7152 * channel(rgba.g) + 0.0722 * channel(rgba.b)
}

/// Composites `over` onto an opaque `under`.
#[cfg(test)]
pub fn composite(over: Hsla, under: Hsla) -> Hsla {
    let top: Rgba = over.into();
    let bottom: Rgba = under.into();
    let a = top.a;
    Rgba {
        r: top.r * a + bottom.r * (1. - a),
        g: top.g * a + bottom.g * (1. - a),
        b: top.b * a + bottom.b * (1. - a),
        a: 1.,
    }
    .into()
}

/// WCAG contrast ratio between text and its background; both are composited
/// onto `backdrop` first so translucent tokens are judged as painted.
#[cfg(test)]
pub fn contrast_ratio(text: Hsla, background: Hsla, backdrop: Hsla) -> f32 {
    let background = composite(background, backdrop);
    let text = composite(text, background);
    let (a, b) = (relative_luminance(text), relative_luminance(background));
    let (light, dark) = if a > b { (a, b) } else { (b, a) };
    (light + 0.05) / (dark + 0.05)
}

pub trait ActiveTheme {
    fn theme(&self) -> &Theme;
}

impl ActiveTheme for App {
    fn theme(&self) -> &Theme {
        self.global::<Theme>()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const AA_NORMAL_TEXT: f32 = 4.5;

    fn assert_readable(name: &str, text: Hsla, background: Hsla, backdrop: Hsla) {
        let ratio = contrast_ratio(text, background, backdrop);
        assert!(ratio >= AA_NORMAL_TEXT, "{name}: {ratio:.2}:1 is below {AA_NORMAL_TEXT}:1");
    }

    #[test]
    fn accent_buttons_keep_readable_labels_in_every_state() {
        for theme in [Theme::light(), Theme::dark()] {
            let name = format!("{:?}", theme.appearance);
            let backdrop = theme.solid_background;
            let layer = composite(theme.layer_fill, backdrop);
            assert_readable(&format!("{name} accent"), theme.text_on_accent, theme.accent, layer);
            assert_readable(&format!("{name} accent hover"), theme.text_on_accent, theme.accent_hover, layer);
            assert_readable(
                &format!("{name} accent pressed"),
                theme.text_on_accent,
                theme.accent_pressed,
                layer,
            );
            assert_readable(&format!("{name} link"), theme.accent_text, theme.card_fill, layer);
            assert_readable(
                &format!("{name} link hover"),
                theme.accent_text_hover,
                theme.subtle_hover,
                layer,
            );
            assert_readable(&format!("{name} body"), theme.text_primary, theme.card_fill, layer);
            assert_readable(&format!("{name} secondary"), theme.text_secondary, theme.card_fill, layer);
            assert_readable(
                &format!("{name} secondary on the layer"),
                theme.text_secondary,
                theme.layer_fill,
                backdrop,
            );
            assert_readable(
                &format!("{name} standard button"),
                theme.text_primary,
                theme.control_fill,
                layer,
            );
            assert_readable(&format!("{name} flyout"), theme.text_primary, theme.flyout_fill, backdrop);
            assert_readable(&format!("{name} error caption"), theme.critical, theme.card_fill, layer);
        }
    }

    #[test]
    fn a_contrast_theme_uses_only_system_colours_and_no_translucency() {
        let colors = SystemColors {
            window: 0x000000,
            window_text: 0xFFFFFF,
            button_face: 0x000000,
            button_text: 0xFFFFFF,
            highlight: 0x1AEBFF,
            highlight_text: 0x000000,
            gray_text: 0x3FF23F,
            hot_light: 0xFFFF00,
        };
        let theme = Theme::resolve(
            ThemePreference::Light,
            Appearance::Light,
            &AccessibilityPreferences {
                high_contrast: true,
                reduce_motion: true,
                text_scale: 1.5,
                system_colors: Some(colors),
            },
        );
        assert!(theme.high_contrast);
        assert!(!theme.mica);
        assert!(theme.reduce_motion);
        assert_eq!(theme.text_scale, 1.5);
        assert_eq!(theme.appearance, Appearance::Dark, "follows the contrast theme, not the preference");
        for colour in
            [theme.card_fill, theme.layer_fill, theme.control_fill, theme.subtle_hover, theme.text_secondary]
        {
            assert_eq!(colour.a, 1.0, "high contrast never blends");
        }
        assert_eq!(theme.accent_text, c(0xFFFF00));
        assert_eq!(theme.text_on_accent, c(0x000000));
    }

    /// The Windows 11 contrast themes, as `Ease of Access Themes\*.theme` define them.
    fn windows_contrast_themes() -> [(&'static str, SystemColors); 4] {
        let theme = |window, window_text, button_face, button_text, highlight, highlight_text, gray, link| {
            SystemColors {
                window,
                window_text,
                button_face,
                button_text,
                highlight,
                highlight_text,
                gray_text: gray,
                hot_light: link,
            }
        };
        [
            (
                "Aquatic",
                theme(0x202020, 0xFFFFFF, 0x202020, 0xFFFFFF, 0x8EE3F0, 0x263B50, 0xA6A6A6, 0x75E9FC),
            ),
            ("Desert", theme(0xFFFAEF, 0x3D3D3D, 0xFFFAEF, 0x202020, 0x903909, 0xFFF5E3, 0x676767, 0x1C5E75)),
            ("Dusk", theme(0x2D3236, 0xFFFFFF, 0x2D3236, 0xB6F6F0, 0xA1BFDE, 0x212D3B, 0xA6A6A6, 0x70EBDE)),
            (
                "Night sky",
                theme(0x000000, 0xFFFFFF, 0x000000, 0xFFEE32, 0xD6B4FD, 0x2B2B2B, 0xA6A6A6, 0x8080FF),
            ),
        ]
    }

    #[test]
    fn contrast_themes_pair_text_with_the_fill_it_sits_on() {
        for (name, colors) in windows_contrast_themes() {
            let theme = Theme::high_contrast(colors);
            let window = theme.solid_background;
            let highlight = theme.subtle_hover;
            assert_readable(
                &format!("{name} hovered row"),
                theme.text_on_hover(theme.text_primary),
                highlight,
                window,
            );
            assert_readable(
                &format!("{name} selected gear"),
                theme.text_on_hover(theme.accent_text),
                highlight,
                window,
            );
            assert_readable(
                &format!("{name} hovered link"),
                theme.text_on_hover(theme.accent_text_hover),
                highlight,
                window,
            );
            assert_readable(&format!("{name} link"), theme.accent_text, theme.card_fill, window);
            // Why hovered rows must not keep their own text colour: window
            // text on the highlight fill is unreadable in every theme.
            assert!(contrast_ratio(theme.text_primary, highlight, window) < AA_NORMAL_TEXT, "{name}");
        }
    }

    #[test]
    fn contrast_themes_select_text_with_the_system_highlight_pair() {
        for (name, colors) in windows_contrast_themes() {
            let theme = Theme::high_contrast(colors);
            let field = theme.control_fill;
            let fill = theme.selection_fill();
            assert_eq!(fill.a, 1.0, "{name}: high contrast never blends");
            let text = theme.selection_text().expect(name);
            assert_readable(&format!("{name} selected text"), text, fill, field);
            // Non-text contrast: the selection stands out from the field.
            let ratio = contrast_ratio(fill, field, field);
            assert!(ratio >= 3.0, "{name}: the selection is {ratio:.2}:1 against the field");
        }
        for theme in [Theme::light(), Theme::dark()] {
            assert_eq!(theme.selection_text(), None, "selected text keeps its colour on the tint");
            assert!(theme.selection_fill().a < 1.0);
        }
    }

    #[test]
    fn contrast_ratio_matches_the_wcag_reference_values() {
        let ratio = contrast_ratio(c(0x000000), c(0xFFFFFF), c(0xFFFFFF));
        assert!((ratio - 21.0).abs() < 0.01);
        // #767676 is the lightest grey that clears AA on white.
        let ratio = contrast_ratio(c(0x767676), c(0xFFFFFF), c(0xFFFFFF));
        assert!((ratio - 4.54).abs() < 0.01, "{ratio}");
    }
}
