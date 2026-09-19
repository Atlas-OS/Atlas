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
The wrapper exits with code 2 for unsuccessful/uncertain results, including
preflight failures. It exits successfully for lookup, installation or an already
provisioned package.

## Evidence and release gate

On 2026-09-19, the real lookup passed using Windows PowerShell 5.1 on Windows
build 26200, App Installer 1.29.290.0, in a non-elevated user context. It returned
NanaZip from `msstore` with version `Unknown`. No app installation was attempted
on the developer PC. Automated tests cover lookup failure, wrong product,
checkpointing, failed/uncertain mutation, missing provisioning and successful
provisioning. They do not establish Store availability on a Chinese network.

Before production integration, complete the remaining cases below, including
existing user-only installation, unavailable COM/Store, disabled Store updates,
network loss and cancellation during download/deployment. Confirm there is no active Store job
before testing a manual download fallback after a failed mutation. Also decide
how to package the COM projection/module without runtime dependency downloads.
Store installation alone does not guarantee automatic updates if Store updates
or required services are disabled.

### Hyper-V validation, 2026-09-19

Tested on `Atlas-Test`, Windows build 26200, Windows PowerShell 5.1.26100.9278,
App Installer 1.29.289.0 and module 1.29.280. NanaZip was absent initially.
A checkpoint was taken before installation; it was restored before the SYSTEM
test so an existing installation could not hide a failure.

| Test | Result |
| --- | --- |
| Elevated user, Store, System scope | Passed: COM status `Ok`, installer code 0, NanaZip 7.0.1843.0 provisioned, no restart required. |
| SYSTEM scheduled task, Store, Windows PowerShell 5.1 | Failed before mutation: `This cmdlet is not supported in Windows PowerShell.`, HRESULT -2146233087. |
| SYSTEM scheduled task, current Atlas download/provisioning implementation | Passed: verified GitHub bundle and license downloaded; NanaZip 7.0.1843.0 provisioned. |

The SYSTEM result is an intentional upstream limitation, not a Store outage.
`Common/Utilities.cs` sets `UsesInProcWinget` for SYSTEM;
`Commands/Common/ManagementDeploymentCommand.cs` rejects this path in its
Windows PowerShell build. The probe now detects that combination before COM
activation and reports an actionable error. These tests do not establish that
all WinGet COM implementations are unsupported under SYSTEM.

Recommended integration: attempt Store from a protected **elevated user** stage
before Atlas enters its SYSTEM software phase. Retain verified NanaZip downloads
for a failure before mutation. Do not attempt another installer after uncertain
Store mutation. This integration is not implemented by the developer probe.

Still untested: a fresh user's first logon, automatic Store updating, regional
connectivity, cancellation during real deployment, and the exact TrustedInstaller
broker token. The live download test used GitHub; SourceForge failover remains
covered by download verification and unit tests, not a forced VM network failure.

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
