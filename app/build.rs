fn main() {
    let rc_id = embedded_playbook();
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        println!("cargo:rerun-if-changed=resources/atlas.rc");
        println!("cargo:rerun-if-changed=resources/atlas.ico");
        // File Properties show the RC id on a tester build. The numeric
        // FILEVERSION/PRODUCTVERSION take the Cargo version, with the fourth
        // component set to the candidate number (0.6.0-rc.2 -> 0,6,0,2) so
        // two candidates' executables differ in Explorer and in installers
        // that compare binary versions; a stable build is x,y,z,0.
        let version =
            rc_id.clone().unwrap_or_else(|| std::env::var("CARGO_PKG_VERSION").expect("package version"));
        let numeric_version = ["MAJOR", "MINOR", "PATCH"]
            .map(|part| std::env::var(format!("CARGO_PKG_VERSION_{part}")).unwrap())
            .join(",")
            + &format!(",{}", rc_id.as_deref().map_or(0, rc_number));
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

/// With the `embedded-playbook` feature, bakes the APBX named by
/// `ATLAS_EMBED_APBX` and the id in `ATLAS_RC_ID` into the executable and
/// returns the id. Either missing fails the build: a tester build must never
/// quietly become a stable one.
fn embedded_playbook() -> Option<String> {
    std::env::var_os("CARGO_FEATURE_EMBEDDED_PLAYBOOK")?;
    println!("cargo:rerun-if-env-changed=ATLAS_EMBED_APBX");
    println!("cargo:rerun-if-env-changed=ATLAS_RC_ID");
    let rc_id = std::env::var("ATLAS_RC_ID").ok().filter(|id| !id.trim().is_empty());
    let Some(rc_id) = rc_id else {
        panic!("embedded-playbook builds need ATLAS_RC_ID, for example 0.6.0-rc.1")
    };
    let valid = rc_id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-');
    assert!(valid, "ATLAS_RC_ID {rc_id:?} may only contain letters, digits, dots and dashes");
    let apbx = std::env::var_os("ATLAS_EMBED_APBX")
        .map(std::path::PathBuf::from)
        .and_then(|path| path.canonicalize().ok())
        .filter(|path| path.is_file());
    let Some(apbx) = apbx else {
        panic!("embedded-playbook builds need ATLAS_EMBED_APBX to name a readable .apbx")
    };
    println!("cargo:rerun-if-changed={}", apbx.display());
    let root = std::path::Path::new(&std::env::var("CARGO_MANIFEST_DIR").unwrap()).join("..");
    println!("cargo:rerun-if-changed={}", root.join(".git/HEAD").display());
    println!("cargo:rerun-if-changed={}", root.join(".git/index").display());
    println!("cargo:rustc-env=ATLAS_SOURCE_COMMIT={}", source_commit(&root));
    let generated = format!(
        "pub const RC_ID: &str = {rc_id:?};\npub static APBX: &[u8] = include_bytes!({:?});\n",
        apbx.to_string_lossy().replace('\\', "/")
    );
    let out = std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).join("embedded.rs");
    std::fs::write(&out, generated).expect("write the embedded playbook binding");
    Some(rc_id)
}

/// The candidate number of an RC id such as `0.6.0-rc.12`, for the version
/// resource's fourth component. Any other suffix, or a number the 16-bit
/// field cannot hold, fails the build rather than misnumbering the executable.
fn rc_number(rc_id: &str) -> u16 {
    let (_, suffix) =
        rc_id.split_once("-rc.").unwrap_or_else(|| panic!("ATLAS_RC_ID {rc_id:?} must look like 0.6.0-rc.1"));
    let number: u16 =
        suffix.parse().ok().filter(|number| *number > 0 && !suffix.starts_with('0')).unwrap_or_else(|| {
            panic!("ATLAS_RC_ID {rc_id:?} needs a candidate number from 1 to 65535 after -rc.")
        });
    number
}

/// Short commit, with `-dirty` when the tree has changes; `unknown` without Git.
fn source_commit(root: &std::path::Path) -> String {
    let git = |args: &[&str]| {
        std::process::Command::new("git")
            .args(args)
            .current_dir(root)
            .output()
            .ok()
            .filter(|output| output.status.success())
            .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_owned())
    };
    match git(&["rev-parse", "--short", "HEAD"]) {
        Some(commit) => match git(&["status", "--porcelain", "--untracked-files=no"]) {
            Some(status) if status.is_empty() => commit,
            _ => format!("{commit}-dirty"),
        },
        None => "unknown".to_owned(),
    }
}
