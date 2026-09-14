#!/usr/bin/env bash
# Builds one release-candidate ZIP for testers on Linux: the production APBX,
# the Atlas Manager executable that carries it, notices and a tester note.
# Nothing is tagged or published; the maintainer posts the ZIP by hand.
#
#   tools/release/build-rc.sh --rc N [--allow-dirty]
#
# Output: artifacts/rc/<version>-rc.N/ with the ZIP, the APBX and SHA256SUMS.txt.
# A failed run leaves a previous candidate in place.
set -euo pipefail

rc=''
allow_dirty=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rc) rc="${2:-}"; shift 2 ;;
        --allow-dirty) allow_dirty=1; shift ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$rc" =~ ^[1-9][0-9]*$ ]] || { echo 'Pass --rc N with a positive integer.' >&2; exit 2; }

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
if [[ "$root" == *' '* ]]; then
    echo 'The checkout path must not contain spaces.' >&2
    exit 1
fi
if [[ ${RUSTFLAGS+x} || ${CARGO_ENCODED_RUSTFLAGS+x} ]]; then
    echo 'Unset RUSTFLAGS and CARGO_ENCODED_RUSTFLAGS; the build uses target-scoped CRT flags.' >&2
    exit 1
fi
for tool in pwsh cargo git sha256sum 7z; do
    command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done
cargo xwin --version >/dev/null 2>&1 || { echo 'cargo-xwin is missing; run tools/release/setup-linux.sh.' >&2; exit 1; }

cd "$root"
if [[ -n "$(git status --porcelain --untracked-files=no)" && $allow_dirty -eq 0 ]]; then
    echo 'The tree has uncommitted changes. Commit them or pass --allow-dirty for a non-publishable build.' >&2
    exit 1
fi
commit="$(git rev-parse --short HEAD)"
version="$(sed -n 's/.*<Version>\([^<]*\)<\/Version>.*/\1/p' playbook/playbook.conf | head -1)"
[[ -n "$version" ]] || { echo 'Cannot read <Version> from playbook/playbook.conf.' >&2; exit 1; }
rc_id="$version-rc.$rc"
final="$root/artifacts/rc/$rc_id"
work="$root/artifacts/rc/.$rc_id.building"
rm -rf "$work"
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT

echo "== Atlas $rc_id from $commit"

# 1. The production playbook, verified against the tracked source tree.
apbx_name="Atlas v$rc_id.apbx"
pwsh -NoProfile -File tools/build/Build-Playbook.ps1 -FileName "Atlas v$rc_id" -OutputPath "$work" \
    -ReplaceOldPlaybook -DontOpenPbLocation
pwsh -NoProfile -File tools/build/Test-Apbx.ps1 -Path "$work/$apbx_name"

# 2. The executable that carries exactly those bytes.
export XWIN_CACHE_DIR="$root/artifacts/xwin"
export XWIN_ACCEPT_LICENSE=1
export XWIN_SDK_VERSION="${XWIN_SDK_VERSION:-10.0.26100}"
export XWIN_CRT_VERSION="${XWIN_CRT_VERSION:-14.44.17.14}"
export ATLAS_EMBED_APBX="$work/$apbx_name"
export ATLAS_RC_ID="$rc_id"
(
    cd app
    pwsh -NoProfile -File tools/Export-DependencyNotices.ps1 -Check
    CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS='-C target-feature=+crt-static' \
        cargo xwin build --release --locked --target x86_64-pc-windows-msvc --features embedded-playbook
)
exe="app/target/x86_64-pc-windows-msvc/release/AtlasManager.exe"
[[ -f "$exe" ]] || { echo "Missing $exe" >&2; exit 1; }

# 3. The ZIP: executable, standalone APBX, notices and the tester note.
stage="$work/zip"
mkdir -p "$stage"
cp "$exe" "$stage/AtlasManager.exe"
cp "$work/$apbx_name" "$stage/"
cp LICENSE "$stage/LICENSE.txt"
cp app/licenses/THIRD-PARTY-NOTICES.txt "$stage/"
cp app/vendor/gpui-pre/LICENSE-APACHE "$stage/GPUI-LICENSE-APACHE.txt"
sed -e "s/@RC_ID@/$rc_id/g" -e "s/@COMMIT@/$commit/g" tools/release/README-RC.txt >"$stage/README-RC.txt"
zip_name="AtlasManager-$rc_id-windows-x64.zip"
(cd "$stage" && 7z a -tzip -bso0 -bsp0 "../$zip_name" .)

# 4. Checksums for what testers receive, in the release workflow's format.
(
    cd "$work"
    cp "zip/AtlasManager.exe" "AtlasManager.exe"
    sha256sum "$zip_name" "$apbx_name" "AtlasManager.exe" | tee SHA256SUMS.txt
    rm -f "AtlasManager.exe"
    rm -rf zip
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
