# Atlas DirectX flowing gradient

Vendored from the published Apache-2.0 `gpui-pre-windows` 0.3.3 crate,
upstream Zed revision `5b055fa789a8b8d38ac951a6e0cde272f66b4495`.
Original LICENSE-APACHE is retained. Cargo patches this backend and gpui-pre together.

`src/shaders.hlsl` adds the visual change described below. `build.rs` also supports
Linux cross-builds using checked-in production bytecode in `prebuilt/`. Windows
still compiles with FXC and warns if the result differs. Run
`app/tools/Export-ShaderBytes.ps1` on Windows (or use the `atlas-gpui-shaders` CI
artifact) and commit its output after changing any of the three HLSL inputs,
compiler flags, profiles or entrypoints. Linux checks all input hashes before
using this output. The prebuilt README records the generating compiler.

Background tag 4
adds the completion-page procedural effect. It reuses the 72-byte Background
layout: solid is the resting dot colour, colors carry the glow and lit dot
colours, the first percentage carries the dot pitch in device pixels, and
gradient_angle_or_pattern_height carries phase. The existing quad vertex/pixel
pipeline, clipping, alpha blending, device-loss recovery, and release shader
compilation remain in use. Existing background tags keep their original shader
branches. The effect is Windows-only.

The shader is original Atlas code: light through water printed as a halftone.
A domain-warped sum of four sine octaves, each on an integer multiple of the
phase so the loop has no seam, is folded into a caustic-like network of bright
folds of varying width. That light drives a fixed device-pixel dot grid: dots
rest tiny and faint, and swell and brighten as a fold passes over them, with a
soft glow beneath. A mask keeps the heading and buttons clear and lets the
light gather low and at the sides. No textures or frame-dependent noise.

`app/src/ui/completion_backdrop.rs` uses one full-size background quad, limits
updates to 30 fps, animates regardless of the Windows animation setting (Atlas
turns that setting off, so the page would otherwise always be static), and omits
artwork in high contrast. The phase closes at 2*pi over 48 seconds. Palette
colours and alphas come from the app theme; the dot pitch is 11 logical pixels
scaled by the window's scale factor.

When upgrading GPUI, preserve tag/layout agreement with `gpui-pre/src/color.rs`
and its style dispatch, or replace this extension with upstream custom shader
support. Run `app/tools/Test-CompletionShader.ps1` to compile all native shader
entrypoints with the production profiles; build/test Atlas and check both themes,
resize, reduced motion and high contrast. Compare unrelated views as well.
