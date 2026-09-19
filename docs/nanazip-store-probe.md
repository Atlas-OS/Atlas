# NanaZip Store COM experiment

`tools/dev/Test-NanaZipStore.ps1` uses Microsoft's COM-backed
`Microsoft.WinGet.Client` module, not `winget.exe`. It searches only the stable
NanaZip Store product `9N8G7TSCL18R`. Default mode only queries the catalog.
`-Install` requests **System** scope, retains dependency/signature validation,
and checks DISM provisioning afterward. A user-only install is not success.
The Store decides the version; its catalog may report `Unknown`, so this path
cannot promise the pinned GitHub release version.

This is not part of the playbook, and does not change the previously built RC5
Desktop artifacts. Production still uses the verified GitHub -> SourceForge
NanaZip downloads. 7-Zip app installation has been removed from source.

## Run

Use Windows PowerShell 5.1. Save Microsoft's pinned module to a local tools
directory (not the playbook). No global module installation is required:

```powershell
Save-Module Microsoft.WinGet.Client -RequiredVersion 1.29.280 -Path .\artifacts\store-probe\modules -Repository PSGallery
$client = '.\artifacts\store-probe\modules\Microsoft.WinGet.Client\1.29.280\Microsoft.WinGet.Client.psd1'
.\tools\dev\Test-NanaZipStore.ps1 -ClientManifest $client
```

If Gallery's API is unavailable, its official package CDN serves
`https://cdn.powershellgallery.com/packages/microsoft.winget.client.1.29.280.nupkg`.
The tested package SHA-256 is
`726602001e6137efff66aa73c197c6ab6396ae2f9634d0adaada17ec5068ee46`.
Verify the hash before extracting it as a ZIP into the versioned module folder.
Do not obtain this privileged module from an unofficial mirror.

On an **elevated disposable Windows 11 25H2 VM**, add `-Install`:

```powershell
.\tools\dev\Test-NanaZipStore.ps1 -ClientManifest $client -Install -TimeoutSeconds 600
```

Each run writes its own `artifacts/store-probe/runs/<id>/report.json`, including
context, phase, COM result/HRESULT, correlation data and provisioning before/after.
These developer reports are outside the app's redacted diagnostics export;
review before sharing. A durable `InstallStarted` checkpoint is written before
calling COM. Failed installation, cancellation, readback failure or timeout
requires inspection before another installer is started. Stopping the client
does not prove that the Store service cancelled the operation. The probe never
runs download fallbacks itself or removes installed applications.

## Evidence and release gate

On 2026-09-19, the real lookup passed using Windows PowerShell 5.1 on Windows
build 26200, App Installer 1.29.290.0, in a non-elevated user context. It returned
NanaZip from `msstore` with version `Unknown`. No app installation was attempted
on the developer PC. Automated tests cover lookup failure, wrong product,
checkpointing, failed/uncertain mutation, missing provisioning and successful
provisioning. They do not establish Store availability on a Chinese network.

Before production integration, test clean elevated-user and TrustedInstaller/
SYSTEM runs, existing user-only installation, a new user's registration after
provisioning, unavailable COM/Store, disabled Store updates, network loss and
cancellation during download/deployment. Confirm there is no active Store job
before testing a manual download fallback after a failed mutation. Also decide
how to package the COM projection/module without runtime dependency downloads.
Store installation alone does not guarantee automatic updates if Store updates
or required services are disabled.

Source research used `microsoft/winget-cli` ref
`5b62860167520b1503b3880d5a026809eb07c6f4` from the local docs cache:

- `src/PowerShell/Microsoft.WinGet.Client.Engine/Helpers/ManagementDeploymentFactory.cs`
  handles normal/elevated COM activation.
- `src/PowerShell/Microsoft.WinGet.Client.Engine/Commands/InstallerPackageCommand.cs`
  calls `InstallPackageAsync` with the selected scope.
- `src/AppInstallerCommonCore/MSStore.cpp` uses Store installation and machine
  provisioning APIs. Its offline download/license route has different auth
  requirements; this experiment uses installation, not offline Store downloads.

Official references: [WinGet source](https://github.com/microsoft/winget-cli),
[module](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client/1.29.280),
[NanaZip Store link](https://github.com/M2Team/NanaZip/blob/main/ReadMe.md).
