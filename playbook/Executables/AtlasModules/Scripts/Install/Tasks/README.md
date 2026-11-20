# Install tasks

This folder holds scripts that only the installer runs.
It's for contributors who change how Atlas installs.

The install orchestrator, `Scripts/Entry/Invoke-AtlasInstall.ps1`, and the install phases under `Scripts/Install/Phases` call these tasks.
Some tasks start in their own PowerShell process, and others are dot-sourced into the phase that uses them.
They run from the extracted Atlas package or from `%windir%\AtlasModules\Scripts\Install\Tasks`.
Toggle and post-install scripts live under `Scripts/Entry` and `Scripts/Operations` instead.

Tasks find the Atlas `Scripts` folder two levels above this one.
Many tasks that start in their own process dot-source the shared bootstrap, `Scripts/Initialize-AtlasPowerShell.ps1`.
Others import only the modules they need from `Scripts/Modules`, by exact manifest path.
Dot-sourced tasks use what their caller has already loaded.
The [modules guide](../../Modules/README.md) explains how scripts import modules.
