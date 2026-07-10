#!/bin/bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pushd "$script_dir" >/dev/null || exit 1
echo "Building Playbook..."
pwsh -NoProfile -ExecutionPolicy Bypass -File "$script_dir/tools/build/Build-Playbook.ps1" -LocalTest
build_exit=$?
if [ "$build_exit" -ne 0 ] && [ "$#" -eq 0 ]; then
  read -r -p "Press Enter to exit...: "
fi
popd >/dev/null || exit 1
exit "$build_exit"
