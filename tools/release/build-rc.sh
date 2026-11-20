#!/usr/bin/env bash
# Builds one release-candidate ZIP for testers on Linux: the production Atlas package,
# the Atlas Manager executable that carries it, notices and a tester note.
# Nothing is tagged or published; the maintainer posts the ZIP by hand.
#
#   tools/release/build-rc.sh --rc N [--allow-dirty]
#       [--toolbox AtlasToolbox-Setup.exe --toolbox-version X.Y.Z]
#
# --toolbox bundles that Toolbox installer in the package, so the candidate installs it
# instead of the latest Toolbox release on GitHub (tools/release/Add-BundledToolbox.ps1).
#
# Output: artifacts/rc/<version>-rc.N/ with the ZIP, the .atlaspkg and SHA256SUMS.txt.
# A failed run leaves a previous candidate in place.
set -euo pipefail

rc=''
allow_dirty=0
toolbox=''
toolbox_version=''
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rc) rc="${2:-}"; shift 2 ;;
        --allow-dirty) allow_dirty=1; shift ;;
        --toolbox) toolbox="${2:-}"; shift 2 ;;
        --toolbox-version) toolbox_version="${2:-}"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$rc" =~ ^[1-9][0-9]*$ ]] || { echo 'Pass --rc N with a positive integer.' >&2; exit 2; }
if [[ -n "$toolbox" || -n "$toolbox_version" ]]; then
    [[ -f "$toolbox" ]] || { echo 'Pass --toolbox with the Toolbox installer file.' >&2; exit 2; }
    [[ "$toolbox_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Pass --toolbox-version X.Y.Z with --toolbox.' >&2; exit 2; }
    toolbox="$(cd -- "$(dirname -- "$toolbox")" && pwd -P)/$(basename -- "$toolbox")"
fi

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
if [[ "$root" == *' '* ]]; then
    echo 'The checkout path must not contain spaces.' >&2
    exit 1
fi
if [[ ${RUSTFLAGS+x} || ${CARGO_ENCODED_RUSTFLAGS+x} ]]; then
    echo 'Unset RUSTFLAGS and CARGO_ENCODED_RUSTFLAGS; the build uses target-scoped CRT flags.' >&2
    exit 1
fi
for tool in pwsh cargo git tar sha256sum 7z; do
    command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done
cargo xwin --version >/dev/null 2>&1 || { echo 'cargo-xwin is missing; run tools/release/setup-linux.sh.' >&2; exit 1; }

cd "$root"
dirty=0
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    dirty=1
fi
if [[ $dirty -eq 1 && $allow_dirty -eq 0 ]]; then
    echo 'The tree has uncommitted changes. Commit them or pass --allow-dirty for a non-publishable build.' >&2
    exit 1
fi
commit="$(git rev-parse --short HEAD)"
# Matches the commit build.rs records for About and diagnostics.
if [[ $dirty -eq 1 ]]; then
    commit+='-dirty'
fi
# PowerShell, which the build needs anyway, reads the manifest: one line each for the
# version, the supported builds and the versions this one updates. The lists come as
# "a, b and c" for README-RC.txt, and every value is checked to be safe in a sed replacement.
manifest="$(pwsh -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "Stop"
    $manifest = Get-Content -LiteralPath "package/atlas.json" -Raw | ConvertFrom-Json
    function Join-Item([string[]]$Item) {
        if ($Item.Count -eq 0) { throw "atlas.json has an empty list." }
        if ($Item.Count -eq 1) { return $Item[0] }
        return ($Item[0..($Item.Count - 2)] -join ", ") + " and " + $Item[-1]
    }
    $versionPattern = "^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$"
    $version = [string]$manifest.version
    if ($version -cnotmatch $versionPattern) { throw "atlas.json has no valid version." }
    $builds = @($manifest.supportedBuilds | ForEach-Object {
            if ("$($_.build)" -cnotmatch "^[0-9]+$" -or "$($_.release)" -cnotmatch "^[0-9A-Za-z.]+$") {
                throw "atlas.json has a supportedBuilds entry without a numeric build and a release name."
            }
            "$($_.build) ($($_.release))"
        })
    $sources = @($manifest.updatableFrom | ForEach-Object {
            if ("$_" -cnotmatch $versionPattern) { throw "atlas.json has an updatableFrom entry that is not a version." }
            "$_"
        })
    $version
    Join-Item $builds
    Join-Item $sources
')" || { echo 'Cannot read version, supportedBuilds and updatableFrom from package/atlas.json.' >&2; exit 1; }
mapfile -t manifest_fields <<<"${manifest//$'\r'/}"
if [[ ${#manifest_fields[@]} -ne 3 ]]; then
    echo 'Cannot read version, supportedBuilds and updatableFrom from package/atlas.json.' >&2
    exit 1
fi
version="${manifest_fields[0]}"
supported_builds="${manifest_fields[1]}"
updatable_from="${manifest_fields[2]}"
# build.rs refuses a mismatch too, but only after the Atlas package is built and verified.
cargo_version="$(sed -n '/^\[package\]/,/^\[/s/^version *= *"\([^"]*\)".*/\1/p' app/Cargo.toml | head -1)"
if [[ "$cargo_version" != "$version" ]]; then
    echo "app/Cargo.toml is at ${cargo_version:-no version} but package/atlas.json is at $version; bump both." >&2
    exit 1
fi
rc_id="$version-rc.$rc"
final="$root/artifacts/rc/$rc_id"
work="$root/artifacts/rc/.$rc_id.building"
rm -rf "$work"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT

echo "== Atlas $rc_id from $commit"

# 1. The production Atlas package. The build packs every file in the folder it's given, so a
#    committed tree builds from an export of the commit's package/: untracked or ignored
#    files in the checkout would otherwise reach testers and still pass verification.
source_package="$root/package"
if [[ $dirty -eq 0 ]]; then
    mkdir -p "$work/source"
    git archive --format=tar HEAD package | tar -x -C "$work/source"
    source_package="$work/source/package"
elif [[ -n "$toolbox" ]]; then
    # The bundled Toolbox goes into a copy, never the checkout.
    mkdir -p "$work/source"
    cp -a "$root/package" "$work/source/"
    source_package="$work/source/package"
fi
if [[ -n "$toolbox" ]]; then
    pwsh -NoProfile -File tools/release/Add-BundledToolbox.ps1 -PackagePath "$source_package" \
        -Installer "$toolbox" -Version "$toolbox_version"
fi
package_name="Atlas-v$rc_id.atlaspkg"
pwsh -NoProfile -File tools/build/Build-Package.ps1 -PackagePath "$source_package" \
    -FileName "Atlas-v$rc_id" -OutputPath "$work" -ReplaceExisting -NoExplorer
pwsh -NoProfile -File tools/build/Test-Package.ps1 -Path "$work/$package_name" -PackagePath "$source_package"

# 2. The executable that carries exactly those bytes.
export XWIN_CACHE_DIR="$root/artifacts/xwin"
export XWIN_ACCEPT_LICENSE=1
export XWIN_SDK_VERSION="${XWIN_SDK_VERSION:-10.0.26100}"
export XWIN_CRT_VERSION="${XWIN_CRT_VERSION:-14.44.17.14}"
export ATLAS_EMBED_PACKAGE="$work/$package_name"
export ATLAS_RC_ID="$rc_id"
(
    cd app
    pwsh -NoProfile -File tools/Export-DependencyNotices.ps1 -Check
    CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS='-C target-feature=+crt-static' \
        cargo xwin build --release --locked --target x86_64-pc-windows-msvc --features embedded-package
)
exe="app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe"
[[ -f "$exe" ]] || { echo "Missing $exe" >&2; exit 1; }

# 3. The ZIP: executable, standalone Atlas package, notices and the tester note.
stage="$work/zip"
mkdir -p "$stage"
cp "$exe" "$stage/AtlasManager.exe"
cp "$work/$package_name" "$stage/"
cp LICENSE "$stage/LICENSE.txt"
cp app/licenses/THIRD-PARTY-NOTICES.txt "$stage/"
cp app/vendor/gpui-pre/LICENSE-APACHE "$stage/GPUI-LICENSE-APACHE.txt"
toolbox_note='/@TOOLBOX_NOTE@/d'
if [[ -n "$toolbox" ]]; then
    toolbox_note="s|@TOOLBOX_NOTE@|- The package also carries AtlasOS Toolbox $toolbox_version. Installing the\\n  Toolbox, from Your choices or the Atlas folder, uses that copy instead of\\n  the latest Toolbox release on GitHub.|"
fi
sed -e "s/@RC_ID@/$rc_id/g" -e "s/@COMMIT@/$commit/g" -e "s/@SUPPORTED_BUILDS@/$supported_builds/g" \
    -e "s/@UPDATABLE_FROM@/$updatable_from/g" -e "$toolbox_note" \
    tools/release/README-RC.txt >"$stage/README-RC.txt"
if grep -q '@[A-Z_][A-Z_]*@' "$stage/README-RC.txt"; then
    echo 'README-RC.txt has a placeholder that build-rc.sh does not fill in.' >&2
    exit 1
fi
zip_name="AtlasManager-$rc_id-windows-x64.zip"
(cd "$stage" && 7z a -tzip -bso0 -bsp0 "../$zip_name" .)

# 4. Checksums for what testers receive, in the release workflow's format.
(
    cd "$work"
    cp "zip/AtlasManager.exe" "AtlasManager.exe"
    sha256sum "$zip_name" "$package_name" "AtlasManager.exe" | tee SHA256SUMS.txt
    rm -f "AtlasManager.exe"
    rm -rf zip source
)

# 5. Publish the finished directory in one move.
rm -rf "$final"
mv "$work" "$final"
trap - EXIT
echo
echo "== Built Atlas $rc_id"
echo "commit:   $commit"
echo "rustc:    $(cd app && rustc --version)"
echo "cargo-xwin: $(cargo xwin --version)"
echo "sdk/crt:  $XWIN_SDK_VERSION / $XWIN_CRT_VERSION"
echo "output:   $final"
cat "$final/SHA256SUMS.txt"
