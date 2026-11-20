#!/usr/bin/env bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pushd "$script_dir" >/dev/null || exit 1
echo "Building the Atlas package..."
if ! command -v pwsh >/dev/null 2>&1; then
  echo "PowerShell 7 (pwsh) is required. See docs/building.md." >&2
  popd >/dev/null || exit 1
  exit 127
fi

pwsh -NoProfile -ExecutionPolicy Bypass -File "$script_dir/tools/build/Build-Playbook.ps1" -LocalTest
build_exit=$?
if [ "$build_exit" -ne 0 ] && [ "$#" -eq 0 ]; then
  read -r -p "Press Enter to exit...: "
fi
popd >/dev/null || exit 1
exit "$build_exit"
