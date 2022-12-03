<h1 align="center">
  <br>
  <a href="http://atlasos.net/"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">一个开放的Windows操作系统，旨在优化性能和延迟。</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">安装</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">常见问题(FAQ)</a>
  •
  <a href="https://discord.gg/atlasos">加入我们的Discord</a>
</p>

# Atlas是什么?

Atlas是一个魔改版本的Windows，删除了众多拖慢Windows系统的组件（游戏性能下降的罪魁祸首）。Atlas是一个透明且开源的项目，致力于为玩家争取平等的权利，无论您是在土豆，还是高性能PC上运行。

Atlas在主要优化性能的同时，也同时是减少系统，网络，输入延迟的一个极佳选择。

## 目录

- [常见问题](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Atlas项目在哪?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [如何安装Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Atlas移除了什么?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#Windows对比Atlas">Windows对比Atlas</a>
- [Post安装](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [品牌工具包](./img/brand-kit.zip)

## Windows对比Atlas

### **隐私**

Atlas删除了Windows中嵌入的所有类型的跟踪，并在部署时强制执行数百个组策略以最小化数据收集。我们无法保证除Windows系统之外的隐私问题，例如您访问的网站。

### **安全性**

Atlas的目标是在不损失性能的情况下保证系统尽可能的安全。我们通过禁用可能泄露信息或被利用的功能来做到这一点。但也有一些例外，比如 [Spectre](https://spectreattack.com/spectre.pdf), 和[Meltdown](https://meltdownattack.com/meltdown.pdf). 您需要禁用这些缓解措施以提高性能。
如果该安全缓解措施降低了性能，我们将会禁用该措施。
以下是一些被修改的功能/缓解措施，如果它们包含(P)，则表示其安全风险已被修复:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*可能的信息检索*)

### **精简**

Atlas删除了大量预先安装的应用程序和其他组件。尽管这可能会破坏一些兼容性，但它会显著减少镜像的大小 (例如删除Windows Defender之类的功能)。这种修改是主要针对游戏的。但大多数教育和工作程序（理论上）都可以工作。[前往常见问题，看看我们删除了什么](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)。

### **性能**

Atlas预先调整了一些东西。在保持兼容性的同时，也在努力提高其性能，我们把每一滴可能压榨性能的点点滴滴都压缩到了Windows映像中。下面列出了我们为改进Windows所做的许多改变中的一些。

- 定制的电源计划
- 最小化的服务程序
- 最小化的驱动程序
- 禁用无需的驱动程序
- 删除节电功能
- 禁用影响性能的安全缓解措施
- 自动启用MSI（信息信号中断）模式
- 引导配置优化
- 优化的线程调度

## 品牌工具包

想制作自己的Atlas壁纸吗?也许你可以用我们的logo来做你自己的设计?该功能面向社区开放，以激发整个社区的创意。 [尝试制作一些让人眼前一亮的东西](./img/brand-kit.zip)。

我们在 [Discussion](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork)页面有专门的分区用于分享社区制作的壁纸, 您可以前往这里发布您独一无二的创意作品！

## DISCLAIMER（免责声明）

This is an unofficial translation of the AtlasOS Disclamer into Simplified Chinese. It was not published by the AtlasOS Team, and does not legally state the Disclaimer. However, we hope that this translation will help Simplified Chinese speakers understand this Disclaimer better. 
这是免责声明的非正式简体中文翻译。它并未由AtlasOS团队发布，也不是一个正式的法律声明——只有AtlasOS的原始英文版免责声明才有法律意义。不过，我们希望该翻译能够帮助简体中文用户更好地理解该法律声明。 

下载、修改以及使用这些镜像即代表您同意[微软公司的条款](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm)这些镜像都不是预激活的，您**必须**使用正版的密钥。

## Translation Contributor 翻译贡献者

[PencilNavigator](https://github.com/PencilNavigator) | [Colin](https://github.com/0bo)
