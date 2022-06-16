<h1 align="center">
<img src="https://github.com/Atlas-OS/Atlas/blob/main/img/banner.jpg" alt="Banner"</img>
  <br>
  Atlas
  <br>
</h1>
<h4 align="center">An open and transparent modification of the Windows 10 operating system, designed to optimize performance and latency.</h4>

<p align="center">
  <a href="#Private">Overview</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="#Discord">Community</a>
</p>

### What are the benefits compared to regular windows?

#### **Private**

Atlas removes all types of tracking embedded within Windows 10 and enforces hundreds of group policies to minimize data collection. Things outside the scope of Windows we cannot increase privacy for, such as websites you visit.

#### **Secure**

Atlas aims to be secure as possible without losing performance by disabling features that can leak information or be exploited. There are exceptions to this such as [Spectre](https://spectreattack.com/spectre.pdf) and [Meltdown](https://meltdownattack.com/meltdown.pdf). These mitigations are disabled to improve performance.
If a security mitigation measure decreases performance, it will be disabled.
Below are some features/mitigations that have been changed, if they contain a (P) they are security risks that have been fixed:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [ATMFD Exploit (P)](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [Print Nightmare (P)](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)

Below are features that are removed from Atlas that have possible security issues:

- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- NetBIOS (*Possible Information Retrieval*)

#### **Debloated**

Atlas is heavily stripped, preinstalled apps and other components are removed. Although this can break some compatibility, it significantly reduces ISO and install size. Functionalities such as Windows Defender, are [removed](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os). This modification is focused on pure gaming, but most work and education applications work.

#### **Performant**

Atlas is pre-tweaked. We've done almost everything to squeeze out the most performance, minimize latency and input lag.
We've done the following to do this:

- Custom Powerplan
- Minimized Services
- Disabled Drivers
- Disabled Devices
- Disabled Power Saving
- Disabled Performance-Hungry Security Mitigations
- Automatically enabled MSI Mode
- Boot Configuration Optimization
- Optimized Process Scheduling

## Discord
Go ahead and join our [discord](https://discord.gg/xx6S3g3HzE) if you have any questions!

## Brand kit
Want to make your own Atlas wallpaper? Maybe mess around with our logo to make your own design? We have this accessible to the public to spark new creative ideas across the community. [Check out our brand kit](https://github.com/Atlas-OS/Atlas/blob/main/src/atlas_os_logo.ps?raw=true)

We also have a dedicated area in the discussions tab so you can share your work with other creative geniuses and maybe even spark some inspiration too! [Here](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork).

## Disclaimer

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.
