//! Assets compiled into the binary so the executable is self-contained.

use std::borrow::Cow;

use anyhow::Result;
use gpui::{AssetSource, SharedString};

pub struct Assets;

const FILES: &[(&str, &[u8])] = &[
    ("brand/atlas-mark.svg", include_bytes!("../assets/brand/atlas-mark.svg")),
    ("brand/atlas-wordmark.svg", include_bytes!("../assets/brand/atlas-wordmark.svg")),
    ("icons/ring.svg", include_bytes!("../assets/icons/ring.svg")),
    ("icons/status-dot.svg", include_bytes!("../assets/icons/status-dot.svg")),
];

impl AssetSource for Assets {
    fn load(&self, path: &str) -> Result<Option<Cow<'static, [u8]>>> {
        Ok(FILES.iter().find(|(name, _)| *name == path).map(|(_, bytes)| Cow::Borrowed(*bytes)))
    }

    fn list(&self, path: &str) -> Result<Vec<SharedString>> {
        Ok(FILES
            .iter()
            .filter(|(name, _)| name.starts_with(path))
            .map(|(name, _)| SharedString::from(*name))
            .collect())
    }
}

/// The window icon, decoded once at startup.
pub fn window_icon() -> Option<std::sync::Arc<image::RgbaImage>> {
    let bytes = include_bytes!("../assets/brand/atlas-icon-256.png");
    let image = image::load_from_memory(bytes).ok()?.to_rgba8();
    Some(std::sync::Arc::new(image))
}
