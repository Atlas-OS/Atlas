#!/usr/bin/env bash
# Install only the user-scoped Rust cross-build tools; system prerequisites are
# documented in docs/building.md and remain managed by the distribution.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
if [[ "$root" == *' '* ]]; then
    echo 'The Linux cross-build checkout and xwin cache must have paths without spaces.' >&2
    exit 1
fi
if [[ ${RUSTFLAGS+x} || ${CARGO_ENCODED_RUSTFLAGS+x} ]]; then
    echo 'Unset RUSTFLAGS and CARGO_ENCODED_RUSTFLAGS; the build uses target-scoped CRT flags.' >&2
    exit 1
fi
cd "$root/app"
for tool in rustup cargo clang-cl lld-link llvm-rc llvm-lib sha256sum; do
    command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done
toolchain="$(sed -n 's/^channel = "\([^"]*\)"$/\1/p' rust-toolchain.toml)"
[[ -n "$toolchain" ]] || { echo 'Cannot read the pinned Rust toolchain.' >&2; exit 1; }
rustup toolchain install "$toolchain" --profile minimal --component rustfmt,clippy
rustup target add --toolchain "$toolchain" x86_64-pc-windows-msvc
xwin_version="$(cargo xwin --version 2>/dev/null || true)"
if [[ "${xwin_version##* }" != '0.23.1' ]]; then
    cargo install cargo-xwin --version 0.23.1 --locked
fi
mkdir -p "$root/artifacts/xwin"
echo "Cross-build tools ready. Install PowerShell 7 (pwsh) and 7-Zip as described in docs/building.md."
