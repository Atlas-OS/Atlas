#!/bin/bash

echo "Building Playbook..."
pwsh -NoP -EP Bypass -C "& \"$(dirname "$PWD")/local-build.ps1\" -AddLiveLog -ReplaceOldPlaybook -Removals WinverRequirement, Verification -DontOpenPbLocation"
