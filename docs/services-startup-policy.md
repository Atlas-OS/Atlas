# Windows service and driver startup policy

Atlas supports Windows 11 build families 26100 (24H2) and 26200 (25H2). Generic
service and driver startup overrides are not treated as harmless performance tweaks:
they change Windows feature contracts, and an older VDI, Windows Server, or fixed-purpose
IoT recommendation is not automatically applicable to a general-purpose Windows 11
client.

The Services phase therefore leaves the following audited startup values at their
Windows defaults. Feature choices use a documented policy or feature-specific interface
where Microsoft provides one. A future startup override must pass the VM gate below and
must describe the accepted feature loss as an Atlas product decision.

## Source audit

| Entry | Primary-source result | Atlas behavior |
| --- | --- | --- |
| `OneSyncSvc` | Microsoft's general [per-user services](https://learn.microsoft.com/en-us/windows/application-management/per-user-services-in-windows) documentation covers Windows 11 and shows how administrators can set a template to `Start=4`, but also says dependent mail, contact, and calendar applications do not work properly. It documents a mechanism, not a safe general-client default. | Keep the Windows default. A no-mail/no-contact profile would require an explicit product contract and VM evidence. |
| `TrkWks` | [Distributed Link Tracking](https://learn.microsoft.com/en-us/windows/win32/fileio/distributed-link-tracking-and-object-identifiers) maintains shell-shortcut and OLE links when NTFS files move. The positive disable recommendation is limited to fixed-function IoT. | Keep the Windows default. |
| `PcaSvc` | The Windows 11 [AppCompat policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-appcompat#appcompatturnoffprogramcompatibilityassistant_2) provides the supported `DisablePCA` control and explains the compatibility assistance lost when it is enabled. | Use the existing `DisablePCA` policy; do not disable the service startup. |
| `DiagTrack` | [Windows diagnostic-data guidance](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization) defines `AllowTelemetry`, `LimitDumpCollection`, and `LimitDiagnosticLogCollection` as the supported Windows 11 controls. | Use those policy values; do not disable the service or its autologger. |
| `diagnosticshub.standardcollector.service` | Current [Windows IoT Enterprise service guidance](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/optimize/services) labels the manual Diagnostics Hub collector "Don't disable" and says reconfiguration is not recommended. | Keep the Windows default. |
| `WerSvc` | Microsoft documents WER as crash, hang, kernel-fault, troubleshooting, and solution-delivery infrastructure. Current service guidance says not to disable it, while the Windows 11 [ErrorReporting policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-errorreporting#disablewindowserrorreporting) provides a supported privacy control. | Use the documented `Disabled` policy; do not disable the service startup. |
| `wercplsupport` | Current service guidance classifies the manual Problem Reports control-panel support service as "No guidance," which explicitly means leave the default unchanged. | Keep the Windows default. |
| `UCPD` | The [Windows app-defaults platform](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/default-apps-platform#security-considerations-for-the-app-defaults-platform) documents `UCPD.sys` as a filter driver protecting app-default choices and directs managed devices to supported Group Policy or MDM controls. | Keep the protection enabled. Atlas no longer requires `UCPDDisabled` or disables the UCPD velocity task. |
| `GpuEnergyDrv` | No Microsoft product documentation establishes a supported general-client `Start=4` contract for builds 26100 and 26200. | Keep the Windows default; future mutation is VM-blocked. |
| `NetBT` | Microsoft documents [NetbiosOptions](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-netbt-interfaces-interface-netbiosoptions) as the interface-specific control: `1` enables NetBIOS and `2` disables it. It does not prescribe changing the global NetBT driver `Start` value. | File Sharing uses and reads back `NetbiosOptions`; it does not change the NetBT driver startup. |
| `Telemetry` | The generic service/driver name has no Microsoft product documentation establishing its identity or a supported general-client `Start=4` contract across both declared builds. It can also collide with non-inbox software. | Keep the Windows or vendor default; future mutation is VM-blocked. |

The contextual Microsoft tables remain useful evidence, but their scope must stay
attached to every conclusion:

- [Windows IoT Enterprise service guidance](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/optimize/services)
  is for fixed-function, specialized IoT devices. It defines "No guidance" as leaving
  the default unchanged.
- [VDI optimization guidance](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remote-desktop-services-vdi-optimize-configuration)
  is for persistent or non-persistent corporate virtual desktops and describes services
  that may be considered in that deployment model.
- [Windows Server service guidance](https://learn.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server)
  applies to Windows Server 2016 with Desktop Experience, not a Windows 11 client.

## Reintroduction gate

No entry above may regain a production startup mutation until a disposable-VM evidence
artifact covers all of these platforms:

- Windows 11 24H2 build 26100, amd64;
- Windows 11 25H2 build 26200, amd64;
- Windows 11 24H2 build 26100, arm64; and
- Windows 11 25H2 build 26200, arm64.

The artifact must record the clean-image service key type, default `Start`, trigger and
dependency configuration, signed binary identity, and post-servicing state. It must then
exercise the dependent Windows features, update/repair flows, sleep and power telemetry,
diagnostics, WER, default-app protection, file sharing, per-user provisioning, and Atlas
reapply/restore behavior. Absence on one image is not evidence that `-AllowMissing` is a
safe cross-build policy. Until that gate passes, the production mutation remains absent.
