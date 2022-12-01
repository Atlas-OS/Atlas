<h1 align="center">
  <br>
  <a href="http://atlasos.net/"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">一个专注优化性能与延迟的开源透明Windows操作系统.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">安装</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.gg/xx6S3g3HzE">Discord</a>
</p>

# Atlas是什么?

Atlas是一个定制版的Windows，移除了 Windows系统中那些降低游戏性能的部分。 作为一个透明的开源项目，我们致力于为玩家争取平等权利，无论您是在土豆上，还是高性能PC上玩游戏。

在关注性能的同时，我们也非常重视减少系统、网络以及输入延迟并保持系统的私密性。

## 目录

- [常见问题](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Atlas项目是什么?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [如何安装Atlas OS?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Atlas OS移除了什么?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#Windows vs. Atlas">Windows vs. Atlas</a>
- [后续安装步骤](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [品牌组件](./img/brand-kit.zip)

## Windows vs. Atlas

### 隐私保护

Atlas 删除了 Windows 中嵌入的所有类型的跟踪，同时利用数百个强制执行的组策略来减少数据收集。但对于那些超出 Windows 范围的部分，我们无法增强其隐私保护，例如您访问的网站。

### 安全性

Atlas 的目标是在不损失性能的情况下尽可能的安全。 我们通过禁用可能泄露信息或被利用的功能来实现这一点。 当然也有例外情况，例如 [Spectre](https://spectreattack.com/spectre.pdf) 和 [Meltdown](https://meltdownattack.com/meltdown.pdf)。 我们禁用了这些缓解措施以提高性能。
即，如果安全缓解措施降低了性能，那么它将被禁用。
以下是一些已被移除的功能/缓解措施，如果有 (P)这一标记，则代表它们的安全风险已经修复了：

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Possible Information Retrieval*)

### **去除冗余**

Atlas 经过充分的瘦身，许多预装的应用程序和其他组件被移除。 尽管这会破坏一些兼容性，但它会显着减少 ISO 和安装大小。 例如Windows Defender 等一些功能被被完全剥离。 我们的修改专注服务于游戏体验，但大多数工作和教育应用程序依旧可以使用。 [你可以在FAQ中查看我们删除的其他内容](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)。

### 高性能

Atlas 经过了预先调整。 在保持兼容性的同时，努力提高性能，在我们的镜像中已经榨干了Windows的每一滴性能。 下面列出了我们为改进 Windows 所做部分更改。

- 自定义电源计划
- 最小化服务
- 最小化驱动程序
- 禁用不需要的设备
- 禁用省电
- 禁用占用太多性能的安全缓解措施
- 自动启用 MSI 模式
- 引导配置优化
- 优化流程调度

## 品牌组件
想制作自己的Atlas壁纸吗？ 或者用我们的logo来制作您自己的设计？ 我们让您可以获得它，以此激发整个社区的新创意。 [请查看我们的品牌工具包，期待您的创意。](./img/brand-kit.zip)

我们还有一个[单独的讨论区](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork)，您可以在此与其他创意天才分享您的设计，甚至激发更多灵感！

## 声明

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.
