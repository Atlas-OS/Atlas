# Windows service and driver startup policy

Atlas leaves Windows service and driver startup values at their Windows defaults.
To turn a feature off, it uses a documented policy or feature interface first, and changes a startup value only when a feature choice needs it.
A generic startup override changes how Windows features behave, so it isn't a harmless performance tweak.
This page is for contributors and reviewers: it sets out where Atlas changes startup values, and the services and drivers Atlas has reviewed.

## Where Atlas changes startup values

Atlas changes a startup value only as part of a feature choice:

- **Fresh installs** apply the Disable state of the File Sharing and Location toggles; a Rebase applies them only where nothing was recorded.
  File Sharing sets the `NetBT` driver to Disabled (`Start=4`), and Location sets `lfsvc` and `MapsBroker` to Disabled and stops them.
  Enable File Sharing and Enable Location turn them back on.
- **The `disable-pca` privacy tweak** sets `PcaSvc` to Disabled, as the table below describes.
- **Choices and toggles you run** change the services they name.
  For example, Disable Printing disables `Spooler` and `PrintWorkFlowUserSvc`, and Enable Printing turns them back on.
  The [toggle reference](catalog/toggles.md) lists what each toggle changes.

Before it applies the File Sharing and Location defaults, the install saves the PC's service and driver startup values to `%windir%\AtlasModules\Other\winServices.reg`, keeping any earlier backup.

Advice written for VDI, Windows Server or fixed-purpose IoT devices doesn't automatically apply to a general-purpose Windows 11 PC.
A new startup override must pass the [VM gate](#vm-gate), and state the feature loss it accepts as an Atlas product decision.

## Reviewed services and drivers

| Entry | What Microsoft documents | Atlas behaviour |
| --- | --- | --- |
| `OneSyncSvc` | [Per-user services](https://learn.microsoft.com/windows/application-management/per-user-services-in-windows) shows how to set the template to `Start=4`, but says dependent mail, contact and calendar apps then don't work properly. | Windows default. A profile without mail and contacts would need a product decision and VM evidence. |
| `TrkWks` | [Distributed Link Tracking](https://learn.microsoft.com/windows/win32/fileio/distributed-link-tracking-and-object-identifiers) keeps shell shortcuts and OLE links working when NTFS files move. Disabling it is recommended only for fixed-function IoT. | Windows default. |
| `PcaSvc` | The [AppCompat policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-admx-appcompat#appcompatturnoffprogramcompatibilityassistant_2) provides the supported `DisablePCA` control and explains the compatibility help it removes. | The `disable-pca` tweak sets `DisablePCA` and related policies, then disables and stops `PcaSvc` before disabling `PcaPatchDbTask`, because a starting `PcaSvc` re-enables that task. |
| `DiagTrack` | [Diagnostic data guidance](https://learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization) defines `AllowTelemetry`, `LimitDumpCollection` and `LimitDiagnosticLogCollection` as the supported controls. | Uses those policies, and leaves the service and its autologger alone. |
| `diagnosticshub.standardcollector.service` | [IoT Enterprise service guidance](https://learn.microsoft.com/windows/iot/iot-enterprise/optimize/services) labels this manual collector "Don't disable". | Windows default. |
| `WerSvc` | Service guidance says not to disable Windows Error Reporting; the [ErrorReporting policy](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-errorreporting#disablewindowserrorreporting) is the supported privacy control. | Uses the documented `Disabled` policy, not a startup change. |
| `wercplsupport` | Service guidance lists this manual Problem Reports service as "No guidance", which means leave the default. | Windows default. |
| `UCPD` | The [app defaults platform](https://learn.microsoft.com/windows/apps/develop/windows-integration/default-apps-platform#security-considerations-for-the-app-defaults-platform) documents `UCPD.sys` as a filter driver that protects default-app choices. | Protection stays on. Atlas doesn't require `UCPDDisabled` or disable the UCPD velocity task. |
| `GpuEnergyDrv` | No Microsoft documentation supports `Start=4` on general-purpose Windows 11 PCs. | Windows default; a change needs the VM gate. |
| `NetBT` | [NetbiosOptions](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-netbt-interfaces-interface-netbiosoptions) is the per-interface control (`1` enables NetBIOS, `2` disables it). Microsoft doesn't prescribe changing the driver's `Start` value. | Disable File Sharing writes `NetbiosOptions` = `2` on every interface that has the value, reads it back, and disables the driver. Enable File Sharing writes `1` and restores system start (`Start=1`). |
| `Telemetry` | No Microsoft documentation establishes what this generic name is, or a supported `Start=4`. It can belong to software that isn't part of Windows. | Windows or vendor default; a change needs the VM gate. |

Microsoft's other service tables are evidence only for their own kind of deployment.
Keep that scope in every conclusion drawn from them:

| Guidance | Applies to |
| --- | --- |
| [Windows IoT Enterprise services](https://learn.microsoft.com/windows/iot/iot-enterprise/optimize/services) | Fixed-function IoT devices. "No guidance" means leave the default. |
| [VDI optimisation](https://learn.microsoft.com/windows-server/remote/remote-desktop-services/remote-desktop-services-vdi-optimize-configuration) | Persistent or non-persistent corporate virtual desktops. |
| [Windows Server services](https://learn.microsoft.com/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server) | Windows Server 2016 with Desktop Experience, not Windows 11 PCs. |

## VM gate

An entry kept at its Windows default may gain a production startup change only after a disposable-VM evidence record covers every release in the [supported releases](windows-release-policy.md#supported-releases) table, on both x64 and ARM64.

The record must include:

- from the clean image: the service key type, the default `Start`, the trigger and dependency configuration, and the signed binary's identity;
- the state after Windows servicing;
- the results of using dependent Windows features, update and repair flows, sleep and power telemetry, diagnostics, Windows Error Reporting, default-app protection, file sharing, per-user provisioning, and Atlas reapply and restore.

A service missing from one image doesn't prove that `-AllowMissing` is safe on every build.
