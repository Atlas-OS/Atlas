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

AtlasOS, or Atlas, is an open-source Windows configuration project. It applies privacy, usability and performance settings, with [AtlasDesktop controls](https://docs.atlasos.net/docs/atlas-configuration/settings/) for changing individual choices after installation.

## 🚀 Installing Atlas

**Atlas Manager** is the recommended way to install Atlas. It checks your PC, installs Windows and Microsoft Store updates, walks you through your choices and then installs Atlas. It can also create an Atlas ISO and an installation USB (Beta). Download `AtlasManager.exe` from the [latest release](https://github.com/Atlas-OS/Atlas/releases/latest).

Atlas Manager is new. If it doesn't work for you, use the alternative installer, [AME Wizard](https://amelabs.net), with the Atlas package (`.apbx`) from the same release. AME Wizard calls the package a playbook.

Atlas 0.6 needs a fresh installation of Windows 11 25H2 (build 26200) or 26H2 (build 26300), unless you're upgrading from Atlas 0.4.1, 0.5.0 or 0.5.1 on a supported build. See the [upgrade requirements](docs/upgrading.md).

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

Atlas comes as a package whose files you can inspect before it runs. The Atlas package is a renamed **.zip** archive, with the password [`malte`](https://docs.amelabs.net/developers/getting-started/creation.html). Most of the package is PowerShell, data definitions and supporting assets.

Atlas Manager and AME Wizard install the same Atlas package, and the installation itself is Atlas PowerShell either way: every feature, retry and check is code included in the package, where you can read it. Atlas Manager is open source, in [`app/`](app/README.md). With AME Wizard, Atlas's AME configuration records your choices and runs the same fixed PowerShell entry points. The package's scripts run on Windows PowerShell 5.1, which is built into Windows; the build tools in this repository use PowerShell 7. See [`docs/architecture.md`](docs/architecture.md) for how an install runs, and [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md) for the build and test quick start.

You can also run the installer yourself, without either app. Extract the Atlas package (it is a renamed ZIP), open an elevated Windows PowerShell prompt in its `Executables` folder, and run `.\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable, mitigations-default, auto-updates-disable`. The script checks that Windows and Microsoft Store updates are finished, copies Atlas's files to a protected directory and runs the same install plan as TrustedInstaller; see [`docs/architecture.md`](docs/architecture.md#the-atlas-front-door).

After installing, `AtlasDesktop\9. Troubleshooting\Check Atlas Health.cmd` reports what Atlas installed and which of its settings have changed since, without changing anything. The full list of toggles and install tweaks is generated into [`docs/catalog`](docs/catalog/toggles.md).

Optional Atlas Toolbox installation resolves the latest stable Toolbox release at install time. Toolbox is intentionally not pinned to an Atlas version, so a Toolbox update does not require a new Atlas release.

The [binary inventory](playbook/Executables/AtlasModules/README.md) lists the executables and Windows component packages included in the Atlas package, their hashes, source repositories, licensing and known provenance limits.

The Atlas package and Atlas Manager are open source under the [GPLv3 license](https://github.com/Atlas-OS/Atlas/blob/main/LICENSE). Atlas Manager starts the install through Atlas's own TrustedInstaller broker. The AME Wizard interface is not open source, but its [TrustedUninstaller backend](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli), which applies the package when you use AME Wizard, is available under MIT.

### Windows licensing

Atlas distributes configuration files and tools rather than a Windows ISO. It does not change Windows activation; users need their own Windows installation and license.

## Developing Atlas

Start with the [contributor quick start](.github/CONTRIBUTING.md), then follow the
[build instructions](docs/building.md) and [testing guide](docs/testing.md). The
[architecture](docs/architecture.md) describes the installer, identity boundaries and
shared modules. The [Atlas Manager guide](app/README.md) covers the desktop app.
Use the [publication checklist](docs/publication.md) to review source contents,
generated artifacts and release evidence before publishing.

The [reliability verification matrix](docs/reliability-verification-matrix.md) lists
the evidence a release needs and what is still to be verified.

## 🎨 Brand kit
Want to create your own Atlas wallpaper with some original creative designs? Visit our [Branding Kit on Docs](https://docs.atlasos.net/docs/branding/) and share your creations on our [GitHub Discussions](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork)!

## 💙 Contributors
<a href="https://github.com/Atlas-OS/Atlas/graphs/contributors" target="_blank"><img src="https://contrib.rocks/image?repo=Atlas-OS/Atlas&columns=18" alt="Avatars of all contributors"></a>
