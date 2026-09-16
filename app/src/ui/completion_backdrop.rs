//! A single procedural DirectX background quad for the completion page.
use crate::theme::ActiveTheme;
use gpui::{Animation, AnimationExt, App, IntoElement, RenderOnce, Styled, Window, div, flowing_gradient};
use std::time::Duration;

/// Dot grid spacing in logical pixels.
const DOT_PITCH: f32 = 11.;

#[derive(IntoElement)]
pub struct CompletionBackdrop;

impl RenderOnce for CompletionBackdrop {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let surface = div().absolute().size_full();
        if theme.high_contrast {
            return surface.into_any_element();
        }
        let dark = theme.is_dark();
        let rest = theme.brand.opacity(if dark { 0.06 } else { 0.08 });
        let glow = theme.accent.opacity(if dark { 0.07 } else { 0.05 });
        let lit = theme.brand.opacity(0.30);
        let pitch = DOT_PITCH * window.scale_factor();
        let fill = move |phase| flowing_gradient(phase, rest, glow, lit, pitch);
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
            return surface.bg(fill(0.)).into_any_element();
        }
        surface
            .bg(fill(0.))
            .with_animation(
                "installed-flowing-gradient",
                Animation::new(Duration::from_secs(48)).repeat().with_max_fps(30.),
                move |surface, progress| surface.bg(fill(progress * std::f32::consts::TAU)),
            )
            .into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::{Background, hsla};

    #[test]
    fn shader_parameters_preserve_the_gpu_abi_and_loop_seam() {
        // DirectX StructuredBuffer<Background> uses this exact existing stride.
        assert_eq!(std::mem::size_of::<Background>(), 72);
        let c = hsla(0.6, 0.8, 0.5, 0.5);
        let start = flowing_gradient(0., c, c, c, 10.);
        assert_eq!(start, flowing_gradient(std::f32::consts::TAU, c, c, c, 10.));
        assert_eq!(start, flowing_gradient(f32::NAN, c, c, c, 10.));
        assert!(start.opacity(0.).is_transparent());
        assert!(!flowing_gradient(0., c.opacity(0.), c, c, 0.).is_transparent());
        let encoded = serde_json::to_value(start).unwrap();
        assert_eq!(encoded["tag"], "FlowingGradient");
        assert_eq!(encoded["colors"][0]["percentage"], serde_json::json!(10_f32));
        // The pitch never collapses the grid: NaN and zero fall back to the minimum.
        let tiny = serde_json::to_value(flowing_gradient(0., c, c, c, f32::NAN)).unwrap();
        assert_eq!(tiny["colors"][0]["percentage"], serde_json::json!(2_f32));
    }
}
