# Atlas changes to gpui-pre-windows 0.3.3

This directory vendors the published Apache-2.0 `gpui-pre-windows` 0.3.3 crate, from upstream Zed revision `5b055fa789a8b8d38ac951a6e0cde272f66b4495`, with the changes below.
The original `LICENSE-APACHE` is kept.
Cargo patches this backend and [`gpui-pre`](../gpui-pre/ATLAS-PATCH.md) together, because the shader reads a background tag that `gpui-pre` defines.

| Change | Files | Check after a GPUI upgrade |
| --- | --- | --- |
| [Completion page shader](#completion-page-shader) | `src/shaders.hlsl` | `app/tools/Test-CompletionShader.ps1`, then the completion page in both themes. |
| [Precompiled shaders for Linux builds](#precompiled-shaders-for-linux-builds) | `build.rs`, `prebuilt/` | `app/tools/Export-ShaderBytes.ps1`, and commit its output. |

## Completion page shader

`src/shaders.hlsl` adds background tag 4, the procedural effect behind the completion page.
It reuses the 72-byte `Background` layout as follows.

| Field | Carries |
| --- | --- |
| `solid` | The resting dot colour. |
| `colors[0].color` | The glow colour. |
| `colors[0].percentage` | The dot pitch in device pixels. |
| `colors[1].color` | The lit dot colour. |
| `colors[1].percentage` | The keep-out feather in device pixels. |
| `gradient_angle_or_pattern_height` | The phase. |
| The quad's `corner_radii` and `border_widths` | Two keep-out rectangles, each as (right, bottom, width, height) in device pixels from the quad origin; a zero width means none. |

A tag-4 quad draws no border or rounding, so `quad_fragment` returns the effect directly.
The existing quad vertex and pixel pipeline, clipping, alpha blending, device-loss recovery and release shader compilation stay in use.
Existing background tags keep their original shader branches.
The effect is Windows-only.

The shader is original Atlas code that draws light through water, printed as a halftone:

- A domain-warped sum of four sine octaves, each on an integer multiple of the phase so the loop has no seam, folds into a caustic-like network of bright folds of varying width.
- That light drives a fixed grid of dots in device pixels.
  Dots rest tiny and faint, and swell and brighten as a fold passes over them, with a soft glow beneath.
- The artwork is fully clear inside each keep-out rectangle, rounded so it reads as a halo, and returns over the feather distance outside it.
  The light flows around the page's text instead of under it.
- The effect uses no textures and no noise that depends on the frame.

`app/src/ui/completion_backdrop.rs` draws one full-size background quad and limits updates to 30 frames per second.
It animates whatever the Windows animation setting says, because Atlas turns that setting off and the page would otherwise always be still.
It omits the artwork in high contrast.

- The phase completes a full turn (2π) every 48 seconds.
- Palette colours and alphas come from the app theme.
- The dot pitch is 11 logical pixels, scaled by the window's scale factor.
- The completion page reports its text column and details card through `Div::on_children_prepainted` each frame.
  The element pads each block by 12 logical pixels and feathers over 48.

When you upgrade GPUI, keep the tag and layout in step with `gpui-pre/src/color.rs` and its style dispatch, or replace this change with upstream support for custom shaders.
Then:

1. Run `app/tools/Test-CompletionShader.ps1`, which compiles every native shader entry point with the production profiles.
2. Build and test Atlas Manager.
3. Check the completion page in both themes, while resizing, with reduced motion and in high contrast.
4. Compare unrelated views as well.

## Precompiled shaders for Linux builds

`build.rs` lets Linux cross-builds use the production bytecode committed in `prebuilt/`.
Windows builds still compile with FXC, and warn if the result differs from `prebuilt/`.
Linux builds check the hashes of all three HLSL inputs before they use the committed output.

After changing any of the three HLSL inputs, the compiler flags, the profiles or the entry points, run `app/tools/Export-ShaderBytes.ps1` on Windows and commit its output.
Without Windows, download the `atlas-gpui-shaders` artifact from the Desktop app workflow instead.
The [precompiled shaders README](prebuilt/README.md) records the compiler that generated them.
