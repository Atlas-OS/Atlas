# Windows service and driver startup policy

This page lists the Windows service and driver startup values Atlas has reviewed, for
contributors and reviewers. Atlas keeps them at their Windows defaults, except
`PcaSvc` and `NetBT` as the table describes.

Generic startup overrides change how Windows features behave; they are not harmless
performance tweaks. Advice for VDI, Windows Server or fixed-purpose IoT does not
automatically apply to a general-purpose Windows 11 client
([supported builds](windows-release-policy.md)). Feature choices use a documented
policy or feature-specific interface where Microsoft provides one. A new startup
override must pass the [VM gate](#vm-gate) and state the accepted feature loss as an
Atlas product decision.

## Reviewed services and drivers

| Entry | What Microsoft documents | Atlas behavior |
| --- | --- | --- |
| `OneSyncSvc` | [Per-user services](https://learn.microsoft.com/en-us/windows/application-management/per-user-services-in-windows) shows how to set the template to `Start=4` on Windows 11, but says dependent mail, contact and calendar apps then do not work properly. A mechanism, not a safe client default. | Windows default. A no-mail/no-contact profile would need an explicit product decision and VM evidence. |
| `TrkWks` | [Distributed Link Tracking](https://learn.microsoft.com/en-us/windows/win32/fileio/distributed-link-tracking-and-object-identifiers) maintains shell-shortcut and OLE links when NTFS files move. Disabling it is recommended only for fixed-function IoT. | Windows default. |
| `PcaSvc` | The Windows 11 [AppCompat policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-appcompat#appcompatturnoffprogramcompatibilityassistant_2) provides the supported `DisablePCA` control and explains the compatibility assistance it removes. | The `disable-pca` privacy tweak sets `DisablePCA` and related AppCompat policies. It also sets `PcaSvc` to Disabled (`Start=4`) and stops it before disabling `PcaPatchDbTask`, because a starting PcaSvc re-enables that task even with `DisablePCA` set. |
| `DiagTrack` | [Diagnostic-data guidance](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization) defines `AllowTelemetry`, `LimitDumpCollection` and `LimitDiagnosticLogCollection` as the supported Windows 11 controls. | Uses those policies. Does not disable the service or its autologger. |
| `diagnosticshub.standardcollector.service` | [IoT Enterprise service guidance](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/optimize/services) labels this manual Diagnostics Hub collector "Don't disable" and advises against reconfiguring it. | Windows default. |
| `WerSvc` | WER is crash, hang, kernel-fault, troubleshooting and solution-delivery infrastructure. Service guidance says not to disable it; the Windows 11 [ErrorReporting policy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-errorreporting#disablewindowserrorreporting) is the supported privacy control. | Uses the documented `Disabled` policy, not a startup change. |
| `wercplsupport` | Service guidance lists this manual Problem Reports control-panel service as "No guidance", meaning leave the default unchanged. | Windows default. |
| `UCPD` | The [app-defaults platform](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/default-apps-platform#security-considerations-for-the-app-defaults-platform) documents `UCPD.sys` as a filter driver that protects app-default choices, and points managed devices to Group Policy or MDM. | Protection stays on. Atlas does not require `UCPDDisabled` or disable the UCPD velocity task. |
| `GpuEnergyDrv` | No Microsoft documentation supports `Start=4` on general-purpose Windows 11 clients. | Windows default; a change needs the VM gate. |
| `NetBT` | [NetbiosOptions](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-netbt-interfaces-interface-netbiosoptions) is the per-interface control (`1` enables NetBIOS, `2` disables it). Microsoft does not prescribe changing the global NetBT driver `Start` value. | Disable File Sharing, which the fresh-install Services phase applies, writes `NetbiosOptions` = `2` on every interface that has the value, reads it back, and sets the NetBT driver to Disabled (`Start=4`). Enable File Sharing writes `1` and restores system start (`Start=1`). |
| `Telemetry` | No Microsoft documentation establishes this generic name's identity or a supported client `Start=4`. It can collide with non-inbox software. | Windows or vendor default; a change needs the VM gate. |

Microsoft's other service tables are evidence only for their own deployment type.
Keep that scope in every conclusion drawn from them:

| Guidance | Applies to |
| --- | --- |
| [Windows IoT Enterprise services](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/optimize/services) | Fixed-function, specialized IoT devices. "No guidance" means leave the default unchanged. |
| [VDI optimization](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remote-desktop-services-vdi-optimize-configuration) | Persistent or non-persistent corporate virtual desktops; lists services that may be considered there. |
| [Windows Server services](https://learn.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server) | Windows Server 2016 with Desktop Experience, not Windows 11 clients. |

## VM gate

An entry kept at the Windows default may gain a production startup change only after
a disposable-VM evidence artifact covers every supported build on both architectures.
With the current `SupportedBuilds` in `playbook/playbook.conf`:

| Release | Build | Architectures |
| --- | --- | --- |
| Windows 11 25H2 | 26200 | amd64, arm64 |
| Windows 11 26H2 | 26300 | amd64, arm64 |

The artifact must record:

- from the clean image: the service key type, default `Start`, trigger and dependency
  configuration, and signed binary identity;
- the state after Windows servicing;
- the results of exercising dependent Windows features, update and repair flows,
  sleep and power telemetry, diagnostics, WER, default-app protection, file sharing,
  per-user provisioning, and Atlas reapply and restore.

A service missing from one image does not prove that `-AllowMissing` is safe on every
build.
