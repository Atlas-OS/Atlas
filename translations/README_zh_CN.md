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
<h4 align="center">一个开放透明的操作系统，旨在优化性能、隐私和稳定性。</h4>

<p align="center">
  <a href="https://atlasos.net">官网</a>
  •
  <a href="https://docs.atlasos.net">文档</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">论坛</a>
</p>


## 🤔 Atlas 是什么?

Atlas 是 Windows 10 的修改版本，几乎消除了 Windows 对游戏性能产生负面影响的所有缺点。

如果您希望减少系统延迟、网络延迟、输入延迟，并在提升性能的同时保持系统的隐私性，Atlas 也是一个很好的选择。您可以在我们的[官方网站](https://atlasos.net/)上了解更多关于 Atlas 的信息。

## 📚 **目录**

- 入门
  - [安装相关](https://docs.atlasos.net/getting-started/installation)
  - [其他安装方式](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [安装之后](https://docs.atlasos.net/getting-started/post-installation/drivers)

- 故障排除
  - [移除功能列表](https://docs.atlasos.net/troubleshooting/removed-features)
  - [脚本](https://docs.atlasos.net/troubleshooting/scripts)

- 常见问题
  - [Discord](https://docs.atlasos.net/faq/community/discord)
  - [论坛](https://docs.atlasos.net/faq/community/forums)
  - [GitHub](https://docs.atlasos.net/faq/community/github)

## 👀 **为什么选择 Atlas？**

### 🔒 隐私
未经修改的 Windows 包含跟踪服务，收集您的数据并将其上传到 Microsoft。 Atlas 删除了 Windows 中内嵌的所有类型的跟踪器，并设置了许多组策略以最大限度地减少数据收集。

请注意，Atlas 无法确保 Windows 范围之外（例如浏览器和第三方应用程序）的安全性。

### 🛡️ 安全
从互联网下载修改后的 Windows ISO 是有风险的。人们不仅可以轻易地恶意更改 Windows 中包含的众多二进制/可执行文件中的一个，还可能没有最新的安全补丁，这会使您的计算机面临严重的安全风险。

Atlas 与他们不同。我们采用 AME Wizard 来部署 Atlas，使用的所有脚本都 GitHub 存储库中开源。您可以将 Atlas playbook（`.apbx`，AME Wizard 脚本包）作为压缩包打开，密码为 `malte` （AME Wizard playbook 的标准，用以绕过杀毒软件误报）。

Playbook 中包含的二进制文件很少，并且都在[此处](https://github.com/Atlas-OS/Atlas-Utilities)以 [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) 协议开源，哈希值与发行版相同。其他内容都是纯文本。

您还可以在安装 Atlas 之前安装最新的安全更新，并且我们建议您这样做，以保证您的系统安全。

请注意，Atlas v0.2.0 及之前版本删除/禁用了某些安全功能（例如 Windows Defender），因此不如未经修改的 Windows 安全。不过，这些功能中的大部分将在 Atlas v0.3.0 中可选地添加回来。更多信息请参见[此处](https://docs.atlasos.net/troubleshooting/removed-features/)。

### 🚀 精简
在 Atlas 中，预安装应用程序与其他无关紧要的组件被移除。尽管可能存在兼容性问题，但这能显著减少安装大小，并使您的系统更加流畅。

因此，例如 Windows Defender 的一些功能被完全剥离。完整的功能移除列表参见 [FAQ](https://docs.atlasos.net/troubleshooting/removed-features)。

### ✅ 性能
不同于一些过度优化，甚至影响基本功能（如 Wi-Fi、蓝牙）的精简系统，Atlas 旨在提高性能的同时保持良好的兼容性。我们进行了许多改进来实现这一目标。

以下是其中的一些改进：

- 自定义电源计划
- 减少服务和驱动程序数量
- 禁用音频独占
- 禁用不需要的设备
- 禁用节电功能（对于个人计算机）
- 禁用影响性能的安全缓解措施
- 自动启用 MSI（信息信号中断）模式
- 引导配置优化
- 优化线程调度

### 🔒 合法
许多修改版 Windows 被打包为 Windows ISO 镜像来分发。这不仅违反了[微软软件许可条款](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_SimplifiedChinese.htm)，而且也不是一种安全的安装方式。

而 Atlas 与 Windows Ameliorated 团队合作，为用户提供更安全、合法的安装方式：[AME Wizard](https://ameliorated.io)。使用 AME Wizard 部署的 Atlas 完全符合[微软软件许可条款](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_SimplifiedChinese.htm)。


## 🎨 视觉形象包
感到灵感爆发？想要使用原创设计制作属于自己的 Atlas 壁纸？我们的视觉形象包能够助您一臂之力！

任何人都可以使用 Atlas 视觉形象包 - 您可以在[这里](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)下载它，创作一些令人惊叹的作品！

我们还在[论坛](https://forum.atlasos.net/t/art-showcase)上设置了专用版块，以便您与其他创意天才分享讨论，激发灵感！您还可以在此找到其他用户分享的创意壁纸！

## ⚠️ Disclaimer | 免责声明
参见 https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors | 翻译贡献者
[PencilNavigator](https://github.com/PencilNavigator) |
[Colin](https://github.com/0bo) |
[Pea Soft](https://github.com/peasoft) |
[Alex3236](https://github.com/alex3236)
