#![allow(clippy::disallowed_methods, reason = "build scripts are exempt")]

fn main() {
    println!("cargo::rustc-check-cfg=cfg(gles)");

    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();

    if target_os == "windows" {
        #[cfg(feature = "windows-manifest")]
        embed_resource();
    }
}

#[cfg(feature = "windows-manifest")]
fn embed_resource() {
    let manifest = std::path::Path::new("resources/windows/gpui.manifest.xml");
    let rc_file = std::path::Path::new("resources/windows/gpui.rc");
    println!("cargo:rerun-if-changed={}", manifest.display());
    println!("cargo:rerun-if-changed={}", rc_file.display());
    // llvm-rc resolves file resources from the preprocessed RC's output directory.
    let root = std::path::PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR").unwrap());
    let absolute_manifest = root.join(manifest).to_string_lossy().replace('\\', "/");
    let resource = std::fs::read_to_string(rc_file)
        .unwrap()
        .replace("resources/windows/gpui.manifest.xml", &absolute_manifest);
    let output = std::path::PathBuf::from(std::env::var_os("OUT_DIR").unwrap()).join("gpui.rc");
    std::fs::write(&output, resource).unwrap();
    embed_resource::compile(&output, embed_resource::NONE).manifest_required().unwrap();
}
