<h1 align="center">
  <a href="https://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/branding@main/banners/banner-v3.png" alt="Atlas" width="800"></a>
</h1>
<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE"><img alt="Licence" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF" /></a>
  <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" /></a>
  <a href="https://github.com/Atlas-OS/Atlas/releases/latest"><img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" /></a>
  <a href="https://github.com/Atlas-OS/Atlas/actions/workflows/build.yml"><img alt="Build Atlas package workflow status" src="https://img.shields.io/github/actions/workflow/status/atlas-os/atlas/build.yml?branch=main&style=for-the-badge&logo=github&label=Build" /></a>
  <a href="https://github.com/Atlas-OS/.github/blob/main/profile/CODE_OF_CONDUCT.md"><img alt="Code of Conduct" src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg?style=for-the-badge&color=1A91FF" /></a>
</p>
<p align="center">An open and lightweight modification to Windows, designed to optimise performance, privacy and usability.</p>

<p align="center">
  <a href="https://atlasos.net">🌐 Website</a>
  •
  <a href="https://atlasos.net/docs/">📚 Documentation</a>
  •
  <a href="https://discord.atlasos.net">☎️ Discord</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/discussions">💬 Discussions</a>
</p>

## Install Atlas

1. Download `AtlasManager.exe` from the [latest release](https://github.com/Atlas-OS/Atlas/releases/latest).
2. Run it.
   Atlas Manager checks your PC, installs Windows and Microsoft Store updates, and asks for your choices.
3. Atlas Manager installs Atlas and restarts your PC.

Atlas needs a supported edition and release of Windows 11.
Check the [requirements](https://atlasos.net/docs/install/requirements/) and the [supported Windows releases](docs/windows-release-policy.md#supported-releases) before you start.
The [installation guide](https://atlasos.net/docs/install/manager/) walks through each step.

Atlas Manager can also create an Atlas ISO and an installation USB (Beta).

## What Atlas changes

Atlas changes Windows settings in four areas.

| Area | What Atlas does | Read more |
| --- | --- | --- |
| Privacy | Turns off selected Windows telemetry and sets policies that reduce data collection. | [Privacy tweaks](docs/catalog/tweaks.md#privacy) |
| Performance | Reduces background activity and adjusts services and power settings. | [Power-saving policy](docs/power-saving-policy.md), [service startup policy](docs/services-startup-policy.md) |
| Security | Lets you choose how Microsoft Defender and SmartScreen, Windows Update, CPU mitigations and core isolation are set. | [Security choices and their consequences](https://atlasos.net/docs/atlas-configuration/security/) |
| Usability | Changes interface defaults, and removes Windows ads and selected apps. | [Atlas settings](https://atlasos.net/docs/atlas-configuration/settings/), [what was removed from Windows](https://atlasos.net/docs/faq/installation/#what-was-removed-from-windows) |

Privacy settings in your browser and other apps stay as you set them.
Performance results depend on your hardware and workload.

After installing, the AtlasDesktop folder has controls for changing individual choices, including putting some settings back to the Windows defaults.
Controls that restore removed features may need an internet connection.

## Check what Atlas does

You can inspect Atlas before you install it and check its changes afterwards.

- The Atlas package (`.apbx`) is a password-protected ZIP file that you can open with the password `malte`.
  Most of it is PowerShell and data.
- The [binary inventory](playbook/Executables/AtlasModules/README.md) lists every executable in the Atlas package, with its source and licence.
- After installing, `AtlasDesktop\9. Troubleshooting\Check Atlas Health.cmd` reports what Atlas installed and what has changed since, without changing anything.
- The [toggle catalog](docs/catalog/toggles.md) and [install tweak catalog](docs/catalog/tweaks.md) list every AtlasDesktop toggle and install tweak.
- [Atlas Manager's source code](app/) is in this repository.
- Atlas Toolbox isn't part of the Atlas package.
  If you choose to install it, Atlas downloads the latest stable Toolbox release at install time.

## Get help

- Read the [Atlas documentation](https://atlasos.net/docs/) and the [FAQ](https://atlasos.net/docs/faq/).
- Ask questions on [Discord](https://discord.atlasos.net) or in [GitHub Discussions](https://github.com/Atlas-OS/Atlas/discussions).
- Report a bug or request a feature with the [issue forms](https://github.com/Atlas-OS/Atlas/issues/new/choose).
- To send a report privately from Atlas Manager, open **Settings** and choose **Send a report**.
- Report a security vulnerability as the [security policy](.github/SECURITY.md) describes.

## Contribute

Start with the [contributing guide](.github/CONTRIBUTING.md), which covers the build and test quick start, commit messages and pull requests.
The [developer documentation](docs/README.md) explains how Atlas works, and the [Atlas Manager guide](app/README.md) covers the app.
[The front door](docs/front-door.md) describes the install script that Atlas Manager runs, and how to run it when testing.
All documentation follows the [writing style guide](docs/style.md).

## Licence

The Atlas package and Atlas Manager are free software under the [GNU General Public License v3.0](LICENSE).
Atlas Manager's [third-party notices](app/licenses/README.md) list the licences of the code it includes.

Atlas doesn't include Windows and doesn't change Windows activation.
You need your own copy of Windows and a Windows licence.

## Brand kit

Use the [Atlas brand kit](https://atlasos.net/docs/branding/) to create your own wallpapers and artwork.
Share what you make in [Community Artwork](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork) on GitHub Discussions.

## Contributors

<a href="https://github.com/Atlas-OS/Atlas/graphs/contributors"><img src="https://contrib.rocks/image?repo=Atlas-OS/Atlas&columns=18" alt="Avatars of all contributors"></a>
