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
layout: solid is the base colour, colors contain the middle/highlight, the first
percentage carries grain, and gradient_angle_or_pattern_height carries phase.
The existing quad vertex/pixel pipeline, clipping, alpha blending, device-loss
recovery, and release shader compilation remain in use. Existing background
tags keep their original shader branches. The effect is Windows-only.

The shader is original Atlas code. Paper's Grain Gradient was the visual reference,
reviewed in `paper-design/shaders` at `7002061d8389781a45e479584deeca0cf538474e`,
`packages/shaders/src/shaders/grain-gradient.ts`; no npm runtime or Paper code
is included. It uses analytical wave distortion and a stationary integer hash
for fine grain, avoiding texture uploads and frame-to-frame grain flicker.

`app/src/ui/completion_backdrop.rs` uses one full-size background quad, limits
updates to 30 fps, holds a static frame for Windows reduced motion, and omits
artwork in high contrast. The phase closes at 2*pi over 64 seconds. Palette
colours come from the app theme and are translucent over its existing material.

When upgrading GPUI, preserve tag/layout agreement with `gpui-pre/src/color.rs`
and its style dispatch, or replace this extension with upstream custom shader
support. Run `app/tools/Test-CompletionShader.ps1` to compile all native shader
entrypoints with the production profiles; build/test Atlas and check both themes,
resize, reduced motion and high contrast. Compare unrelated views as well.
