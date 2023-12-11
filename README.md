<h1 align="center">
  <a href="http://atlasos.net" target="_blank"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/branding@main/github-banner.png" alt="Atlas" width="800"></a>
</h1>
  <p align="center">
    <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
  </p>
<p align="center">A transparent and lightweight modification to Windows, designed to optimize performance, privacy and usability.</p>

<p align="center">
  <a href="https://atlasos.net" target="_blank">🌐 Website</a>
  •
  <a href="https://docs.atlasos.net" target="_blank">📚 Documentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">☎️ Discord</a>
  •
  <a href="https://forum.atlasos.net" target="_blank">💬 Forum</a>
</p>

## 📚 **Important Documentation**
- [Installation](https://docs.atlasos.net/getting-started/installation/)
- [FAQ & Common Issues](https://docs.atlasos.net/faq-and-troubleshooting/removed-features/)
- [Contribution Guidelines](https://docs.atlasos.net/contributions/)
- [Branding](https://docs.atlasos.net/branding/)

## 🤔 What is Atlas?
Atlas is an open source project that enhances Windows by eliminating factors that negatively impact gaming performance. We optimize for minimal stutters and input lag, enhanced privacy, usability, and performance, all with a focus on maintaining functionality.

## 👀 Why Atlas?
### 🔒 Enhanced Privacy
Atlas removes the majority of telemetry embedded within Windows and implements numerous group policies to minimize data collection. However, it cannot ensure privacy outside the scope of Windows, such as browsers and other third-party applications.

### ✅ Optimized Performance
Atlas strikes a balance between performance and compatibility. It implements numerous meaningful changes to improve Windows performance and responsiveness without breaking essential features. Atlas will not do tweaks for a placebo effect or very marginal gains, making Atlas more stable and compatible.

### 🛡️ Security Features
Unlike most other Windows modifications, we don't remove key security features that most users need to maintain a secure system. However, Atlas allows power users to have more customisation over disabling certain security features within their needs, including informing users with information about the [pros and cons](https://docs.atlasos.net/getting-started/post-installation/atlas-folder/security/) of each option.

Some security features which are optional are:

- Windows Defender & SmartScreen
- Windows Update
  - No automatic updates (will be customisable next release)
  - No major feature updates (potentially customisable in the future)
- CPU mitigations
- User Account Control
- Core isolation features

### 😄 Increased Usability
Atlas applies many modifications and default settings to make Windows easier to use. This includes removing commonly unneeded applications (which are reinstallable), configuring many aspects of the interface, disabling advertisements, and much more.

### 🔍 Open Source and Transparent
Atlas is open source with the [GPLv3 license](https://github.com/Atlas-OS/Atlas/blob/main/LICENSE).

Unlike custom Windows ISOs, Atlas is easier to audit due to Atlas' use of the software [AME Wizard](https://ameliorated.io). AME Wizard is controlled by Playbooks, a heavily customizable script-esque system that can perform a wide range of tasks, including deep modifications to Windows. AME Wizard's backend is [open source](https://git.ameliorated.info/Styris/trusted-uninstaller-cli), meaning that you can see exactly what is ran.

Playbooks are renamed **.zip** archives (with the password [`malte`](https://docs.ameliorated.io/developers/getting-started/creation.html)) which primarily consists of plain text scripts, meaning that Atlas is much easier to audit to see exactly what is changed. This is unlike custom Windows ISOs, which have many more entry points for malicious activity. The minimal amount of binaries included in the Playbook are open source in our [utilities](https://github.com/Atlas-OS/utilities) repository, with the [hashes being listed here](https://github.com/Atlas-OS/Atlas/blob/main/src/playbook/Executables/AtlasModules/README.md).

### 🔒 Legal Compliance
As Atlas doesn't redistrbute a modified Windows ISO, Atlas fully complies with [Microsoft's Terms of Service](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). In addition, activation in Windows is not modified.

## 🎨 Brand kit
Want to create your own Atlas wallpaper with some original creative designs? Download our brand kit [here](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip) and share your creations on our [forum](https://forum.atlasos.net/t/art-showcase).
