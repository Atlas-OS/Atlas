//! A single procedural DirectX background quad for the completion page.
use crate::theme::ActiveTheme;
use gpui::{Animation, AnimationExt, App, IntoElement, RenderOnce, Styled, Window, div, flowing_gradient};
use std::time::Duration;

#[derive(IntoElement)]
pub struct CompletionBackdrop;

impl RenderOnce for CompletionBackdrop {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let surface = div().absolute().size_full();
        if theme.high_contrast {
            return surface.into_any_element();
        }
        let base = theme.brand.opacity(0.);
        let middle = theme.accent.opacity(if theme.is_dark() { 0.24 } else { 0.12 });
        let highlight = theme.brand.opacity(if theme.is_dark() { 0.51 } else { 0.28 });
        let fill = move |phase| flowing_gradient(phase, base, middle, highlight, 0.09);
        let surface = surface.bg(fill(0.));
        if theme.reduce_motion {
            surface.into_any_element()
        } else {
            surface
                .with_animation(
                    "installed-flowing-gradient",
                    Animation::new(Duration::from_secs(64)).repeat().with_max_fps(30.),
                    move |surface, progress| surface.bg(fill(progress * std::f32::consts::TAU)),
                )
                .into_any_element()
        }
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
        let start = flowing_gradient(0., c, c, c, 0.09);
        assert_eq!(start, flowing_gradient(std::f32::consts::TAU, c, c, c, 0.09));
        assert_eq!(start, flowing_gradient(f32::NAN, c, c, c, 0.09));
        assert!(start.opacity(0.).is_transparent());
        assert!(!flowing_gradient(0., c.opacity(0.), c, c, 0.).is_transparent());
        let encoded = serde_json::to_value(start).unwrap();
        assert_eq!(encoded["tag"], "FlowingGradient");
        assert_eq!(encoded["colors"][0]["percentage"], serde_json::json!(0.09_f32));
    }
}
