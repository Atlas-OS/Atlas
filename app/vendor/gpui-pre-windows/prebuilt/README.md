# Precompiled Windows GPUI shaders

`app/tools/Export-ShaderBytes.ps1` generates these files from the output directory of Cargo's release build script.
Linux builds check `inputs.sha256`, then copy `shaders_bytes.rs` into their own build output, so they never run FXC or Wine.

- FXC file version: `10.0.26100.7705 (WinBuild.160101.0800)`
- FXC SHA-256: `31fa10504b1551337de4d06ec2194143885a76a8b5a81177999e2faa34729183`
- Profiles: `vs_4_1` and `ps_4_1`, with optimisation level `/O3`.
- Flags: `/T <profile> /E <entry> /Fh <header> /Vn <constant> /O3 <source>`.
- `shaders.hlsl`: vertex and fragment pairs for `quad`, `opaque_quad`, `shadow`, `path_tile`, `underline`, `monochrome_sprite`, `subpixel_sprite` and `polychrome_sprite`.
- The source includes `alpha_correction.hlsl`. Both inputs are hashed.

Regenerate these files on Windows after changing any input, entry point, profile, compiler or compiler flag.
Without Windows, download the `atlas-gpui-shaders` artifact from the Desktop app workflow.
Commit all three files together.
Inputs and exported text use LF line endings.
