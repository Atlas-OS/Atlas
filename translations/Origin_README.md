
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">An open and transparent Windows operating system, designed to optimize performance and latency.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net/FAQ/Installation/">FAQ</a>
  •
  <a href="https://discord.com/invite/atlasos" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **What is Atlas?**

Atlas is a modified version of Windows 10, which removes all the negative drawbacks of Windows that adversely affect gaming performance. We are a transparent and open source project striving for equal rights for players whether you are running a low-end, or a gaming PC.

We are also a great option to reduce system latency, network latency, input lag, and keep your system private while keeping our main focus on performance.

You can learn more about Atlas in our official [Website](https://atlasos.net).

## 📚 **Table of contents**
- FAQ
  - [Install](https://docs.atlasos.net/FAQ/Installation/)
  - [Contribute](https://docs.atlasos.net/FAQ/Contribute/)

- Getting Started
  - [Installation](https://docs.atlasos.net/Getting%20started/Installation/)
  - [Other install methods](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [Post Install](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [Scripts](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Branding kit](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

## 🆚 **Windows vs. Atlas**

### 🔒 Private
Atlas removes all types of tracking embedded within Windows and implements numerous group policies to minimize data collection. Things outside the scope of Windows we can not increase privacy for, such as websites you visit.

### 🛡️ Secure
Atlas aims to be secure as possible without losing performance. We do this by disabling features that can leak information or be exploited. There are exceptions to this such as [Spectre](https://spectreattack.com/spectre.pdf), and [Meltdown](https://meltdownattack.com/meltdown.pdf). These mitigations are disabled to improve performance.

If a security mitigation measure decreases performance, it will be disabled.
Below are some features/mitigations that have been altered, if they contain a (P) they are security risks that have been fixed:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Possible information retrieval*)

### 🚀 Debloated
Atlas is heavily stripped, with pre-installed applications and other components are removed. Despite the possibility of compatibility issues, this significantly decreases ISO and install size. Functionalities such as Windows Defender, and such are stripped completely.

This modification is focused on pure gaming, but most work and education applications work. Check out what else we have removed in our [FAQ](https://docs.atlasos.net/Troubleshooting/Removed%20features/).

### ✅ Performant
Atlas is pre-tweaked. While maintaining compatibility, but also striving for performance, we have squeezed every last drop of performance into our Windows images.

Some of the many changes that we have done to improve Windows have been listed below.

- Customized power scheme
- Reduced amount of services and drivers
- Disabled audio exclusive
- Disabled unneeded devices
- Disabled power savings
- Disabled performance-hungry security mitigations
- Automatically enabled MSI mode on all devices
- Boot configuration optimization
- Optimized process scheduling

## 🎨 Branding kit
Would you like to create your own Atlas wallpaper? Maybe mess around with our logo to make your own design? We have this accessible to the public to spark new creative ideas across the community. [Check out our brand kit and make something spectacular.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

We also have a dedicated area on our [Forum](https://forum.atlasos.net/t/art-showcase), so you can share your creations with other creative geniuses and maybe even spark some inspiration!

## ⚠️ Disclaimer
AtlasOS is **NOT** a pre-activated version of Windows, you **must** use a genuine key to run Atlas. Before you buy a Windows 10 (Pro OR Home) license, make sure the seller is trusted and the key is legitimate, no matter where you buy it. Atlas is based on Microsoft Windows, by using Windows you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## Translation contributors (!!Translation contributor in the translated language)
[Contributor A](https://github.com/A) |
[Contributor B](https://github.com/B) |
[Contributor C](https://github.com/C)
