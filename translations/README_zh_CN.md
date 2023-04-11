## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">一个开放的Windows操作系统，旨在优化性能和延迟。</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">安装</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">常见问题(FAQ)</a>
  •
  <a href="https://discord.atlasos.net">加入我们的 Discord</a>
  •
  <a href="https://forum.atlasos.net">前往我们的论坛</a>
</p>


## 🤔 Atlas 是什么?

Atlas 是一个修改版的 Windows 10，删除了众多拖慢 Windows 系统的组件（游戏性能下降的罪魁祸首）。Atlas 是一个透明且开源的项目，致力于让玩家享受到同等的待遇（无论是在一台土豆服务器，还是高性能 PC 上运行）。

Atlas 在主要优化性能的同时，也是减少系统、网络、输入延迟的一个极佳选择。

## 📚 **目录**

- 常见问题
  - [安装相关](https://docs.atlasos.net/FAQ/Installation/)
  - [贡献相关](https://docs.atlasos.net/FAQ/Contribute/)

- 开始安装
  - [安装](https://docs.atlasos.net/Getting%20started/Installation/)
  - [其他安装方式](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [安装后](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- 解决问题
  - [被移除的功能](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [脚本](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [品牌工具包](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)
## 🆚 **Windows 对比 Atlas**

### 🔒 隐私
Atlas 删除了 Windows 中嵌入的所有跟踪器，并在部署时强制执行数百个组策略以最小化数据收集。我们无法保证除 Windows 系统之外的隐私问题，例如您访问的网站。

### 🛡️ 安全性
Atlas 的目标是在不损失性能的情况下保证系统尽可能的安全。我们通过禁用可能泄露信息或被利用的功能来做到这一点。但也有一些例外，比如 [Spectre](https://spectreattack.com/spectre.pdf)和[Meltdown](https://meltdownattack.com/meltdown.pdf)。您需要禁用这些缓解措施以提高性能。

如果该安全缓解措施降低了性能，我们将会禁用该措施。
以下是一些被修改的功能/缓解措施，如果它们包含(P)，则表示其安全风险已被修复：

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [远程桌面](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*可能存在信息检索* )

### 🚀 精简
我们删除,剥离了大量的预装的应用程序和其他组件。尽管有可能出现兼容性问题，但这大大减少了ISO镜像和安装空间。诸如Windows Defender之类的功能被完全剥离。

这种修改主要针对游戏，（理论上）不会影响大多数教育和工作程序正常工作。您可以前往[常见问题](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)，查看我们删除了什么。

### ✅ 性能
Atlas是被预调试过的。在保持兼容性的同时，也努力追求性能，我们将每一滴性能都挤进了我们的Windows镜像。

- 自定义电源计划
- 减少服务程序
- 减少驱动程序
- 禁用不需要的设备
- 禁用节电功能
- 禁用影响性能的安全缓解措施
- 自动启用 MSI（信息信号中断）模式
- 引导配置优化
- 优化线程调度

## 🎨 品牌工具包

想制作自己的 Atlas 壁纸吗？也许你可以用我们的 logo 来制作你自己的设计？功能面向社区开放，以激发整个社区的创意。[尝试制作一些让人眼前一亮的东西！](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

我们在 论坛 页面有专门的分区用于分享社区制作的壁纸，您可以前往[这里](https://forum.atlasos.net/t/art-showcase)发布您独一无二的创意作品！

## ⚠️ Disclaimer (免责声明)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (翻译贡献者)
[PencilNavigator](https://github.com/PencilNavigator) |
[Colin](https://github.com/0bo) |
[Pea Soft](https://github.com/peasoft)
