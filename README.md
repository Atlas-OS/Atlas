<h1 align="center">
  <a href="https://atlasos.net" target="_blank"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/branding@main/banners/banner-v3.png" alt="Atlas" width="800"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/></a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" /></a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest"><img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" /></a>
    <a href="https://github.com/Atlas-OS/.github/blob/main/profile/CODE_OF_CONDUCT.md"><img alt="Code of Conduct" src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg?style=for-the-badge&color=1A91FF" /></a>
  </p>
<p align="center">A transparent and lightweight modification to Windows, designed to optimize performance, privacy and usability.</p>

<p align="center">
  <a href="https://atlasos.net" target="_blank">🌐 Website</a>
  •
  <a href="https://docs.atlasos.net" target="_blank">📚 Documentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">☎️ Discord</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/discussions" target="_blank">💬 Discussions</a>
</p>

## 📚 **Important Documentation**

- [Installation](https://docs.atlasos.net/docs/install/playbook/)
- [Install FAQ](https://docs.atlasos.net/docs/faq/installation/#what-was-removed-from-windows)
- [General FAQ](https://docs.atlasos.net/docs/faq/general/#security-and-atlasos)
- [Contribution Guidelines](https://docs.atlasos.net/docs/contributing/)
- [Branding](https://docs.atlasos.net/docs/branding/)

## 🤔 What is Atlas?

AtlasOS, or Atlas, is an open-source Windows configuration project. Its playbook applies privacy, usability and performance settings, with [AtlasDesktop controls](https://docs.atlasos.net/docs/atlas-configuration/settings/) for changing individual choices after installation.

## 👀 Why Atlas?
### 🔒 Enhanced Privacy
Atlas disables selected Windows telemetry components and configures policies to reduce data collection. Browser and third-party application privacy settings remain separate.

### 📈 Optimized Performance
Atlas configures background activity, services and power settings. Results depend on the workload and hardware; review the [power-saving policy](docs/power-saving-policy.md) and [service startup policy](docs/services-startup-policy.md) for the intended behavior and tradeoffs.

### 🛡️ Security Features
Atlas exposes security choices with documented [consequences](https://docs.atlasos.net/docs/atlas-configuration/security/). Review those consequences before changing a protection setting.

Some optional security features are:

- Windows Defender & SmartScreen
- Windows Update and automatic updates
- CPU mitigations
- User Account Control
- Core isolation features

### ✅ Increased Usability
Atlas changes interface defaults, disables Windows advertisements and removes selected applications. AtlasDesktop includes configuration and restoration controls; restoration may require available packages and a working download source.

### 🔍 Open Source and Transparent

Atlas is distributed as an [AME Wizard](https://amelabs.net) Playbook whose payload can be inspected before it runs.

Playbooks are renamed **.zip** archives, with the password [`malte`](https://docs.amelabs.net/developers/getting-started/creation.html). Most of the Atlas payload is PowerShell, data definitions and supporting assets.

Atlas keeps AME Wizard as a thin packaging and application host. The YAML layer captures install facts and invokes fixed entry points; it does not use AME task includes as Atlas's workflow engine. Live installation, retry, and feature logic live in the auditable PowerShell framework shipped with the Playbook. The target payload uses the inbox Windows PowerShell 5.1 host, while repository build tooling uses PowerShell 7. See [`docs/architecture.md`](docs/architecture.md) for how an install runs, and [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md) for the build/test quick start.

Atlas can also be installed without AME Wizard. Extract the Playbook (it is a renamed ZIP), open an elevated Windows PowerShell prompt in its `Executables` folder, and run `.\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable, mitigations-default, auto-updates-disable`. The script stages the payload in a protected directory and runs the identical install plan as TrustedInstaller; see [`docs/architecture.md`](docs/architecture.md#the-atlas-front-door).

After installing, `AtlasDesktop\9. Troubleshooting\Check Atlas Health.cmd` reports what Atlas installed and which settings have since drifted, without changing anything. The full list of toggles and install tweaks is generated into [`docs/catalog`](docs/catalog/toggles.md).

Optional Atlas Toolbox installation resolves the latest stable Toolbox release at install time. Toolbox is intentionally not pinned to an Atlas Playbook version, so a Toolbox update does not require a new Playbook release.

The [binary inventory](playbook/Executables/AtlasModules/README.md) lists shipped executables and packages, their hashes, source repositories, licensing and known provenance limits.

Although the AME Wizard GUI is not open source, its [TrustedUninstaller backend](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli) is available under MIT. Atlas uses that host to apply the package and establish the initial execution identities; Atlas feature logic does not depend on a separate AME task implementation. The Atlas Playbook itself is open source under the [GPLv3 license](https://github.com/Atlas-OS/Atlas/blob/main/LICENSE).

### Windows licensing

Atlas distributes configuration files and tools rather than a Windows ISO. It does not change Windows activation; users need their own Windows installation and license.

## Developing Atlas

Atlas 0.6 fresh installations and ISO creation target Windows 11 25H2 (build
26200). A fresh Windows installation is required unless upgrading from a declared
Atlas source version. The playbook declares upgrades from 0.4.1, 0.5.0 and 0.5.1;
the Windows build requirement applies separately. See the [upgrade requirements
and validation gaps](docs/upgrading.md). ISO creation and USB writing are **Beta**.

Start with the [contributor quick start](.github/CONTRIBUTING.md), then follow the
[build instructions](docs/building.md) and [testing guide](docs/testing.md). The
[architecture](docs/architecture.md) describes the installer, identity boundaries and
shared modules. The [desktop app guide](app/README.md) covers the Rust UI.
Use the [publication checklist](docs/publication.md) to review source contents,
generated artifacts and release evidence before publishing.

Release evidence requirements and historical coverage limits are in the
[reliability verification matrix](docs/reliability-verification-matrix.md).

## 🎨 Brand kit
Want to create your own Atlas wallpaper with some original creative designs? Visit our [Branding Kit on Docs](https://docs.atlasos.net/docs/branding/) and share your creations on our [GitHub Discussions](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork)!

## 💙 Contributors
<a href="https://github.com/Atlas-OS/Atlas/graphs/contributors" target="_blank"><img src="https://contrib.rocks/image?repo=Atlas-OS/Atlas&columns=18" alt="Avatars of all contributors"></a>
