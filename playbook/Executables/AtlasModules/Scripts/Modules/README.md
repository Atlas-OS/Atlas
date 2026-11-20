# PowerShell modules

This folder holds the `Atlas.*` PowerShell modules that the installer, toggles, tweaks and entry scripts share.
It's for contributors who add or change module functions.
The [architecture overview](../../../../../docs/architecture.md) lists what each module is responsible for.

## Layout

Each module is a folder named after it.

- `Atlas.<Name>.psd1` is the manifest, and lists the module's public functions in `FunctionsToExport`.
- `Atlas.<Name>.psm1` imports the modules it depends on, dot-sources its domain files and exports its public functions.
- `Domain/` holds one `.ps1` file for each area the module covers, such as `Atlas.Software/Domain/CbsPackages.ps1`.
  Small modules keep their functions in the `.psm1` and have no `Domain` folder.

`Atlas.Core` also has a `Native` folder with `Atlas.Native.cs`, which holds every P/Invoke and COM interop declaration.

`tests/Atlas.Contracts.Tests.ps1` checks that each module folder has one manifest named after it, and that each module exports exactly the functions its manifest lists.

## Import a module

Atlas imports its modules by exact path, so a module with the same name elsewhere can't take their place.

- Scripts in `Scripts/Entry` dot-source `Scripts/Initialize-AtlasPowerShell.ps1` before anything else, and so do many other scripts that start their own process.
  The bootstrap sets `PSModulePath` to this folder followed by the inbox Windows PowerShell modules, and imports the inbox modules Atlas uses from their exact manifests.
- Entry scripts and install tasks import modules from their manifest path.

  ```powershell
  Import-Module -Name (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
  ```

- Toggle companions and tweak scripts call `Import-AtlasModule -Name Atlas.<Name>`, from `Atlas.Core`.
  It imports the manifest beside `Atlas.Core` into the global session state, and reuses a module that's already loaded.
- A module imports the modules it depends on from `..\Atlas.<Name>\Atlas.<Name>.psd1`, without `-Force`.
  In Windows PowerShell 5.1, a nested forced import unloads the caller's copy of the module.

A companion function never takes the name of the module function it calls, so it can't shadow that function.
