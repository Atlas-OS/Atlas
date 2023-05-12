⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Release Downloads" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">An open and transparent modification to Windows, designed to optimize performance, privacy and stability.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Documentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **What is Atlas?**

Atlas is a modification to Windows operating system, which removes nearly all the drawbacks of Windows that negatively affect gaming performance.
Atlas is also a good option to reduce system latency, network latency, input lag, and keep your system private while focusing on performance.
You can learn more about Atlas on our official [website](https://atlasos.net).

## 📚 **Table of contents**

- Getting Started
  - [Installation](https://docs.atlasos.net/getting-started/installation)
  - [Other installation methods](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Post-Installation](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Discord](https://docs.atlasos.net/faq/community/discord)
  - [Forums](https://docs.atlasos.net/faq/community/forums)
  - [GitHub](https://docs.atlasos.net/faq/community/github)

## 👀 **Why Atlas?**

### 🔒 More private
Stock Windows contains tracking services that collect your data and upload it to Microsoft.
Atlas removes all types of tracking embedded within Windows and implements numerous group policies to minimize data collection. 

Note that Atlas cannot ensure the security for things outside the scope of Windows (such as browsers and third-party applications).

### 🛡️ More secure (over custom Windows ISOs)
Downloading a modified Windows ISO from the internet is risky. Not only can people easily maliciously change one of the many binary/executable files included in Windows, it also may not have the latest security patches that can put your computer under serious security risks. 

Atlas is different. We use [AME Wizard](https://ameliorated.io) to install Atlas, and all the scripts we use are open source here in our GitHub repository. You can view the packaged Atlas playbook (`.apbx` - AME Wizard script package) as an archive, with the password being `malte` (the standard for AME Wizard playbooks), which is only to bypass false flags from antiviruses.

The only executables included in the playbook are open sourced [here](https://github.com/Atlas-OS/Atlas-Utilities) under [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), with the hashes being identical to the releases. Everything else is in plain text.

You can also install the latest security updates before installing Atlas, which we recommend to keep your system safe and secure.

Please note that as of Atlas v0.2.0, Atlas is mostly **not as secure as regular Windows** due to removed/disabled security features, like Windows Defender being removed. However, in Atlas v0.3.0, most of these will be added back as optional features. See [here](https://docs.atlasos.net/troubleshooting/removed-features/) for more info.

### 🚀 More space
Pre-installed applications and other insignificant components are removed with Atlas. Despite the possibility of compatibility issues, this significantly reduces the install size and makes your system more fluent. Therefore, some functionalities (such as Windows Defender) are stripped completely.
Check out what else we have removed in our [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ More performance
Some tweaked systems on the internet have tweaked Windows too much, breaking compatibility for main features such as Bluetooth, Wi-Fi, and so on.
Atlas is on the sweet point. It aims at getting more performance while maintaining a good level of compatibility.

Some of the many changes that we have done to improve Windows are listed below:
- Customized power scheme
- Reduced amount of services and drivers
- Disabled audio exclusive
- Disabled unneeded devices
- Disabled power saving (for personal computers)
- Disabled performance-hungry security mitigations
- Automatically enabled MSI mode on all devices
- Optimized boot configuration
- Optimized process scheduling

### 🔒 Legal
Many custom Windows OSes distribute their systems by providing a tweaked ISO of Windows. Not only it violates [Microsoft's Terms of Service](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), but it is also not a safe way to install.

Atlas partnered with Windows Ameliorated Team to provide users a safer and legal way to install: the [AME Wizard](https://ameliorated.io). With it, Atlas fully complies with [Microsoft's Terms of Service](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Brand kit
Feeling creative? Want to create your own Atlas wallpaper with some original creative designs? Our brand kit has got you covered!
Anyone can access the Atlas brand kit — you can download it [here](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) and make something spetacular!

We also have a dedicated area on our [forum](https://forum.atlasos.net/t/art-showcase), so you can share your creations with other creative geniuses and maybe even spark some inspiration! You can also find creative wallpapers that other users share here too!

## ⚠️ Disclaimer
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer
