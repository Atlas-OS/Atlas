fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        println!("cargo:rerun-if-changed=resources/atlas.rc");
        println!("cargo:rerun-if-changed=resources/atlas.ico");
        let version = std::env::var("CARGO_PKG_VERSION").expect("package version");
        let numeric_version = ["MAJOR", "MINOR", "PATCH"]
            .map(|part| std::env::var(format!("CARGO_PKG_VERSION_{part}")).unwrap())
            .join(",")
            + ",0";
        let icon = std::path::Path::new(&std::env::var("CARGO_MANIFEST_DIR").unwrap())
            .join("resources/atlas.ico")
            .to_string_lossy()
            .replace('\\', "/");
        let resource = std::fs::read_to_string("resources/atlas.rc")
            .expect("read app resources")
            .replace("@ICON@", &icon)
            .replace("@NUMERIC_VERSION@", &numeric_version)
            .replace("@VERSION@", &version);
        let resource_path = std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).join("atlas.rc");
        std::fs::write(&resource_path, resource).expect("write app resources");
        embed_resource::compile(&resource_path, embed_resource::NONE)
            .manifest_optional()
            .expect("embed the Atlas icon resource");
    }
}
