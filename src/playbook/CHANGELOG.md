# EBOS Changelog

## 1.4.0
- Windhawk decoupled: `SetupComplete.cmd` only auto-installs Windhawk when
  `Stage-ImageFiles.ps1 -IncludeWindhawk` created the `include-windhawk.txt`
  marker (matches the wizard default of unchecked). The playbook option
  `windhawk-transparency` still installs on demand when selected.
- `Install-Software.ps1`: winget stub detection (`--version` check), best-effort
  App Installer bootstrap (VCLibs + UI.Xaml + `aka.ms/getwinget`), 3 install
  attempts with backoff.
- `Install-StreamElements.ps1`: TLS ensure (append, not overwrite), `--source
  winget` in OBS fallback, `User-Agent` header.
- `Install-VoicemeeterBanana.ps1`, `LIBREWOLF.ps1`,
  `Install-WindhawkTransparentTaskbar.ps1`, `Install-OBS.ps1`: TLS ensure /
  `User-Agent: EBOS-Playbook` for API calls.

## 1.3.1
- `APPLYDUHIVE.ps1`: `-like 'HKCU'` never matched `HKCU\...` paths, so the
  default-user hive got no HKCU settings for new users. Fixed with wildcard +
  prefix strip.
- `SETPATHS.ps1`: crashed mid-loop on service keys without a `path` value
  (missing `-ErrorAction`, null `Substring`/`IndexOf`). Added guards.
- `FirstLogonCommands.xml`: `Start-Process pwsh` fails silently without PS7;
  now `powershell.exe` with `Test-Path` guard (script self-elevates).
- Assets verified (DEFAULT.reg, Layout.xml, FirstLogonCommands.xml,
  playbook.conf well-formed).

## 1.3.0
- `config-oem-information.yml`: `EBOSVersionUndefined` placeholder went live
  into boot entry/winver — now versioned; bare `bcdedit /set description`
  (missing `{current}`, fails) removed to end conflict with final-fixes;
  `SupportPhone=GitHub-URL` removed; missing elevation added.
- `ebos-final-fixes.yml`: power-scheme GUID off-by-one fixed (regex),
  per-user `BingSearchEnabled=0` added, single versioned boot entry
  (`EBOS 11 <ver>` via `{current}`).
- `Verify-EBOS.ps1` 2.0.0 → 2.1.0: +9 tests (service consistency, security
  hardening, QoL registry) incl. fixes; own GUID-parse and bare-bcdedit bugs
  fixed.

## 1.2.0
- `ebos-security-hardening.yml`: `NoViewContextMenu=1` removed (killed all
  right-click menus); `EnableLUA` moved to real path; dead firewall path
  removed; real Spotlight kill-switch added.
- `ebos-service-optimizations.yml`: SysMain 4→3 (ends conflict with gaming
  file + verify script); ClipSVC 4→3 (Disabled breaks Store); PowerShell
  applies per-service targets.
- `ebos-gaming-profile-switcher.yml`: `powercfg ... None` (invalid) →
  `SCHEME_CURRENT`; `PROCESSOR` → `SUB_PROCESSOR`.
- `ebos-process-optimization.yml`: `%PLAYBOOK_PATH%`/`$PSScriptRoot` never
  resolve in AME Wizard — candidate-search + `reg.exe import`.
- `ebos-privacy-hardening.yml`: fake keys replaced (`DisableWindowsTelemetry`
  → `AllowTelemetry`, fake `SPI\SPIEnabled` → tailored-experiences opt-out,
  fake `DisableConvenienceFeed` → `ShowSyncProviderNotifications`).
- `ebos-taskbar.yml`: HKLM→HKCU, fake `TaskbarSbHoverSettings` →
  `SearchboxTaskbarMode`, dead pinning placeholder removed.
- `ebos-network-optimizations.yml`: fake global `DisableNagle` → real
  per-interface `TcpNoDelay`/`TcpAckFrequency` + real Cloudflare DNS.
- `ebos-power-plan.yml`: GUID parsing fixed (old filter excluded its own plan).
- `ebos-startup-optimizer.yml`: fake keys → real `StartupDelayInMSec` (HKCU +
  default profile). `ebos-boot-asset.yml`: no more empty System32 folder.

## 1.1.0
- ViVeTool 0.3.3 → 0.3.4 (new asset names `IntelAmd`/`SnapdragonArm64`);
  detection in `CLIENTCBS.ps1`/`Scripts.psm1` updated (supports both).
- `config-pins.yml`: duplicate `browser-librewolf` entry wiped the LibreWolf
  choice — now `!install-another-browser`.
- `Stage-ImageFiles.ps1`: icon path mismatch fixed.
- `custom.yml`: `Remove-Item` hardened; `Install-OBS.ps1` User-Agent;
  `SetupComplete.cmd` + Windhawk script pwsh→powershell fallback.
- `Build-Playbook.ps1`: self-contained `.apbx` builder (replaces
  `..\dependencies\local-build.ps1`).
