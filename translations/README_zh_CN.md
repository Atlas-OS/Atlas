⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
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
<h4 align="center">一个开放透明的Windows精简，旨在优化性能，隐私，和稳定性。</h4>

<p align="center">
  <a href="https://atlasos.net">官网</a>
  •
  <a href="https://docs.atlasos.net">文档（英文）</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">论坛</a>
</p>

## 🤔 **Atlas 是什么?**
Atlas 是一个精简版的Windows，删除了众多拖慢 Windows 系统的组件（游戏性能下降的罪魁祸首）。
同时，Atlas也是一个减少系统延迟，网络延迟，和输入延迟的好选择，在注重性能的同时也保证了系统的隐私性。
您可以在我们的[官方网站](https://atlasos.net)上了解更多关于Atlas的信息。

## 📚 **目录**

- [贡献指南](https://docs.atlasos.net/contributions)

- 安装Atlas
  - [安装](https://docs.atlasos.net/getting-started/installation)
  - [其他安装方式](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [安装后](https://docs.atlasos.net/getting-started/post-installation/drivers)

- 故障排除
  - [移除的功能](https://docs.atlasos.net/troubleshooting/removed-features)
  - [脚本](https://docs.atlasos.net/troubleshooting/scripts)

- 常见问题
  - [Atlas](https://atlasos.net/faq)
  - [常见故障](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **为什么选择Atlas？**

### 🔒 更有隐私
原版 Windows 内置了多种跟踪服务，他们会收集您的数据并将其上传到微软用于其他用途。 
Atlas 删除了 Windows 中所有类型的跟踪服务，并设置了多种不同组策略以最大限度地减少数据收集。

请注意，Atlas 无法确保 Windows 范围之外（例如浏览器和三方应用程序）的安全性。

### 🛡️ 更加安全 (相比传统精简Windows镜像)
一直以来，从网上下载魔改版的Windows镜像风险都极大。因为你根本不知道制作这些镜像的作者是否有在他们的镜像中加“盐”。同时，这些系统还可能缺少最新的安全补丁，让你的爱鸡只因面临严重的安全风险。

Atlas就不一样了，我们使用AME Wizard进行部署，并且所有我们使用的脚本，配置文件都开源在我们的GitHub Repo中。您可以将压缩的Atlas Playbook（.apbx - AME Wizard的部署文件）解压，密码为`malte`（AME Wizard playbook的通用密码），设置该密码也仅仅只是用于防止杀毒软件误报。

包含在部署文件中的可执行文件全部都在 [这里](https://github.com/Atlas-OS/Atlas-Utilities) 以 [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE)协议开源，其哈希校验值与发行版无异。 其余所有文件均以明文形式存储。

当然，我们推荐你在安装Atlas前通过Windows更新获取所有最新的安全补丁，确保你的系统安全有保障。

请注意，在当前Atlas版本 v0.2.0, Atlas **相比原版Windows安全性并不高**，因为我们把很大一部分的安全组件被删除禁用了（例如Defender）。 但在接下来发布的 Atlas v0.3.0，之前移除的安全组件都会被重新添加. 详见 [这里](https://docs.atlasos.net/troubleshooting/removed-features/)。

### 🚀 更多空间
Atlas移除了各种预装的应用程序和其他不重要的组件。尽管移除这些可能会带来兼容性问题，但能显著减少安装体积，并使系统更加流畅。
Check out what else we have removed in our [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

因此，包括Defender在内的一些功能完全移除。想要获取一份完整被移除组件的列表？请点[这里](https://docs.atlasos.net/troubleshooting/removed-features)！

### ✅ 更佳性能
与一些过度精简、甚至影响到基本功能（如 Wi-Fi、蓝牙）的精简系统不同，Atlas 的目标是在保持良好兼容性的同时相比原版系统提高更多性能。我们进行了许多改进来实现这一目标。

以下是其中的一些改进：

- 定制的电源计划
- 减少服务和驱动程序数量
- 禁用音频独占
- 禁用不需要的设备
- 禁用节电功能（仅针对个人PC）
- 禁用影响性能的安全缓解措施
- 自动启用 MSI（信息信号中断）模式
- 引导配置优化
- 优化线程调度

### 🔒 合法性
许多精简版 Windows 都是以镜像的形式进行分发的。这不仅违反了[微软许可条款](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_SimplifiedChinese.htm)，而且安装修改过的镜像风险都极大。

而 Atlas 与 Windows Ameliorated 团队合作，提供了一个更安全、完全合法的安装方式：[AME Wizard](https://ameliorated.io)。使用 AME Wizard 部署的 Atlas 完全符合[微软许可条款](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_SimplifiedChinese.htm)，妈妈再也不用担心我会收到律师函啦！

## 🎨 品牌工具包
想制作自己的 Atlas 壁纸吗？也许你可以用我们的 logo 来制作你自己的设计？
谁都可以访问到这个品牌工具包—仅需轻轻点击 [这里](https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) 下载即可！（[中国境内镜像链接](https://jsd.cdn.zzko.cn/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)）

我们同时也在官方[论坛](https://forum.atlasos.net/t/art-showcase)有一个壁纸分享区。在这里，你可以分享你独一无二，有趣新奇的设计，供大家欣赏，使用！

## ⚠️ Disclaimer （免责声明）
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## Translation contributors (翻译贡献者)
[PencilNavigator](https://github.com/PencilNavigator) |
[Colin](https://github.com/0bo) |
[Pea Soft](https://github.com/peasoft)
