### Atlas Manager: Chinese (Simplified) (zh-Hans), preview translation. Revised 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### 译者说明：
### - 称呼用户为“你”（与 Windows 11 简体中文界面一致），称呼计算机为“电脑”。
### - “重启”“重新启动”只用于电脑/Windows；重新打开 Atlas 应用一律说“重新打开”。
### - Windows 功能名称与简体中文版 Windows 保持一致，尤其是“病毒和威胁防护”设置
###   页中的四个开关：篡改防护、实时保护、云提供的保护、自动提交样本。
### - 中文与拉丁字母、数字之间留一个空格；中文语境使用全角标点，仅含拉丁字母的
###   括注（如 (.apbx)、(VBS)）使用半角括号并前后留空格。
### - 标记为“文本”的值（版本、内部版本号、路径、文件名、错误信息）原样插入，不翻译。
### - 中文只有 other 一种复数类别，不使用 [one]；允许精确数字分支 [1]、[2]。

## 共享

app-name = Atlas Manager
common-done = 完成
common-cancel = 取消
common-back = 返回
common-next = 继续
common-dismiss = 关闭
# 摘要行旁边的链接，用于跳回并更改该选择。
common-change = 更改
common-copy = 复制
# 选项列表为空时显示。
common-none = 无
# 已禁用控件的辅助功能说明。
common-not-available = 目前不可用
# “安装”和“设置”页面上返回箭头的辅助功能名称。
common-back-to-home = 返回主页
# 标题栏中齿轮按钮的辅助功能名称。
common-settings = 设置
common-close-settings = 关闭设置
common-open-windows-security = 打开 Windows 安全中心
# 指的是以管理员身份重新打开 Atlas 应用，不是重启电脑。
common-restart-as-administrator = 以管理员身份重新打开
common-try-again = 重试
common-read-the-docs = 阅读 Atlas 使用指南
common-show-details = 显示详细信息
common-hide-details = 隐藏详细信息
common-open-log-file = 打开日志文件
# 安装日志旁边“复制”按钮的辅助功能名称。
common-copy-install-log = 复制安装日志
common-install-log = 安装日志
# 摘要卡片中的行标签。
common-windows = Windows
common-options = 选项
common-package = 安装文件
common-installed-as = 安装类型
common-installed = 已安装
common-checking = 正在检查
# 连接列表中的两项：“Brave、Firefox”。花括号用于保留分隔符。
list-separator = { "、" }
# 连接两个备选项：“26100 或 26200”。
list-or = { $a } 或 { $b }

## 窗口

# 安装进行中关闭窗口时显示的对话框。
window-close-title = 安装期间要关闭窗口吗？
window-close-message = 安装会在后台继续进行。重新打开 Atlas 即可查看进度和结果。安装完成前请保持电脑开机。
window-close-keep = 保持打开
window-close-close = 关闭窗口
# 选择 Playbook (.apbx) 文件时文件选择器的标题。
file-dialog-open-playbook = 打开 Atlas Playbook (.apbx) 文件
# Windows 在重启通知中显示的消息。
shutdown-comment = Atlas 已安装。Windows 即将重启以完成设置。

## 系统

# “Windows 11 专业版 25H2（内部版本 26200.1234）”。三个值均为文本。
system-description = { $product } { $version }（内部版本 { $build }）

## 主页

home-not-installed = 欢迎使用 Atlas
# 已安装 Atlas 时的标题。$version 为文本。
home-version = Atlas { $version }
# $date 为格式化后的日期。
home-installed-on = 安装于 { $date }
home-status-checking = 正在检查更新
home-status-offline = 无法检查更新
home-status-not-checked = 尚未检查更新
home-status-update = 新版本 Atlas { $version } 已发布
home-status-up-to-date = 已是最新版本
home-status-newest = 最新版本：Atlas { $version }
home-check-again = 重新检查
# 安装正在运行或等待时的主按钮。
home-show-install = 查看进度
home-continue-installing = 继续安装
home-update-to = 更新到 Atlas { $version }
home-reinstall = 重新安装 Atlas
home-install = 安装 Atlas
home-start-over = 重新开始
home-security-reminder-title = 请重新开启防护
home-security-reminder-message = 当前没有正在进行的安装。请打开 Windows 安全中心，重新开启篡改防护、实时保护、云提供的保护和自动提交样本。
home-elevation-title = Atlas 需要权限才能安装
home-state-error-title = 无法读取 Atlas 的安装详情
home-whats-new = Atlas { $version } 新增内容
home-view-release = 在 GitHub 上查看发行说明
home-released = 发布于 { $date }
home-show-less = 收起
home-show-full-notes = 显示全部发行说明
home-your-install = Atlas 安装详情
# 行标签：Atlas 是如何安装的。
home-set-up = 安装方式
home-set-up-during-oobe = 在 Windows 初始设置期间
home-history = 安装历史记录
# 一行历史记录。$version 为文本，$mode 为 history-mode-* 消息之一，$date 为格式化后的日期和时间。
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = 为安装 Atlas 做好准备
home-step-1-title = 检查电脑
home-step-1-detail = Atlas 会检查 Windows 并下载安装文件。你的 Windows 设置保持不变。
home-step-2-title = 选择设置
home-step-2-detail = 选择 Windows 处理防护和更新的方式，再按需挑选额外的应用和设置。
home-step-3-title = 暂停防病毒保护
home-step-3-detail = Atlas 会引导你关闭 Windows 安全中心的四个开关，以免它们阻止安装。
home-step-4-title = 安装并重启
# 中文不区分单复数，因此不需要选择表达式。
home-step-4-detail = 大约 { $minutes } 分钟。
# 带编号步骤的辅助功能名称。
home-step-a11y = 第 { $number } 步：{ $title }
home-github = 在 GitHub 上查看 Atlas
home-discord = 加入 Atlas 社区 (Discord)
home-report-problem = 报告问题

## 安装方式（来自状态文档）

mode-fresh = 首次安装
mode-upgrade = 从早期版本更新
mode-reapply = 重新安装同一版本
mode-unknown = 安装
# 在历史记录行中使用的简短形式。
history-mode-fresh = 首次安装
history-mode-upgrade = 更新
history-mode-reapply = 重新安装
history-mode-unknown = 安装

## 主页上的通知

notice-settings-reset-title = Atlas 正在使用默认的应用设置
# $error 为原始错误消息（文本）。
notice-settings-unreadable = Atlas 无法读取已保存的应用设置。你的 Windows 设置没有改变。详细信息：{ $error }
# $file 为文件名（文本）。
notice-settings-damaged-kept = 应用设置文件已损坏，现已重置。旧文件的副本已另存为 { $file }。详细信息：{ $error }
notice-settings-damaged = 应用设置文件已损坏。Atlas 暂时使用默认设置。详细信息：{ $error }
notice-settings-not-saved-title = 无法保存应用设置
notice-session-unreadable-title = 无法检查上次的安装
# $path 为文件路径（文本）。
notice-session-unreadable-message = Atlas 无法读取 { $path }，因此无法确定是否仍有安装正在进行。如果你不确定，请先向 Atlas 社区求助，再考虑删除此文件。只有在确认没有安装正在进行后，才删除它并重试。详细信息：{ $error }

## 管理员提升

elevation-declined = 未获得权限。请重试，并在 Windows 询问是否允许此应用对你的设备进行更改时选择“是”。
elevation-declined-continue = 未获得权限。请重试，并在 Windows 询问是否允许此应用对你的设备进行更改时选择“是”。你的设置选择已保存。
elevation-draft-not-saved = Atlas 无法保存你的设置选择，因此未以管理员身份重新打开。请重试。详细信息：{ $error }

## 安装流程

step-ready = 准备
step-options = 你的选择
step-security = Windows 安全中心
step-install = 安装
install-title = 安装 Atlas
# 步骤行的辅助功能名称。
stepper-label = Atlas 安装步骤
# 单个步骤的辅助功能名称。$status 为 stepper-status-* 消息之一。
stepper-step-a11y = 第 { $number } 步，共 { $total } 步，{ $title }，{ $status }
stepper-status-completed = 已完成
stepper-status-current = 当前步骤
stepper-status-upcoming = 后续步骤
# 每个步骤内容上方的标题。
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }

## 第 1 步：准备

ready-banner-busy-title = 正在准备你的电脑
ready-banner-busy-message = Atlas 正在检查你的电脑并准备安装文件。
ready-banner-blocked-title = 电脑还需要做些准备
ready-banner-blocked-message = 请按照下方说明操作，然后选择“重新检查”。
ready-banner-no-package-title = 下载 Atlas 以继续
ready-banner-no-package-message = 请在下方下载最新版本，或打开已保存的 Atlas Playbook (.apbx) 文件。
ready-banner-warnings-title = 有几项需要留意
ready-banner-warnings-message = 继续之前，请阅读下方说明并按建议处理。
ready-banner-ok-title = 可以开始选择设置了
ready-banner-ok-message = 检查已通过，安装文件已就绪。

# 卡片标题以及检查列表的辅助功能名称。
ready-this-pc = 电脑检查
ready-check-again = 重新检查

package-title = 安装文件
# $received 和 $total 为格式化后的兆字节数（文本）。
package-downloading = 正在下载 Atlas { $version } · { $received } / { $total } MB
# 中文不区分单复数，因此不需要选择表达式。
package-unpacking-progress = 正在解压 · { $done } / { $total } 个文件
package-unpacking = 正在解压
package-looking = 正在检查 Atlas 的最新版本。
package-none = 尚无安装文件。Playbook (.apbx) 文件包含 Atlas 所需的安装指令和文件。
# 卡片标题旁边的简短状态词。
package-status-downloading = 正在下载
package-status-unpacking = 正在解压
package-status-failed = 无法准备文件
package-status-ready = 已就绪
package-status-checking = 正在检查
package-status-missing = 未下载
# 进度条的辅助功能名称。
package-progress = 安装文件进度
package-download-again = 重新下载
package-download-version = 下载 Atlas { $version }
package-download-newest = 下载最新版本
package-open-file = 打开 Playbook 文件
# 安装包的来源。$file 为文件名，$path 为文件夹路径（文本）。
package-from-release = Atlas { $version } 已从 GitHub 下载，可以安装。
package-from-file = Atlas { $version } 已从 { $file } 加载，可以安装。
package-unpacked = Atlas { $version } 已就绪，可以安装。
package-at = 安装文件：{ $path }
package-none-yet = 尚未选择安装文件
acquire-no-asset = Atlas { $version } 没有可下载的 Playbook 文件。请打开已保存的 Atlas Playbook (.apbx) 文件以继续。
acquire-unsupported = 此应用只能安装 Atlas 0.6.0 及更高版本。要安装 Atlas { $version }，请改用 AME Wizard。
acquire-failed = 无法准备安装文件。请重新下载，或打开其他 Atlas Playbook (.apbx) 文件。详细信息：{ $error }

## 系统检查

check-administrator = 安装权限
check-supported-build = Windows 兼容性
check-pending-updates = Windows 更新
check-pending-reboot = 重启状态
check-third-party-antivirus = 其他防病毒软件
check-internet = Internet 连接
check-power = 电源
check-activation = Windows 激活
# 检查行的辅助功能名称。$state 为 check-state-* 消息之一。
check-a11y = { $title }：{ $state }
check-state-checking = 正在检查
check-state-passed = 已通过
check-state-warning = 需要注意
check-state-failed-blocking = 安装前需要处理
check-state-failed = 需要注意
check-state-unknown = 无法检查
check-fix-windows-update = 打开 Windows 更新
check-fix-network = 打开网络设置
check-fix-power = 打开电源设置
check-fix-activation = 打开激活设置
# 某项检查无法运行时，用户勾选的复选框。
check-ack-updates = 我已查看 Windows 更新，没有等待安装的更新
check-ack-reboot = 我已重启 Windows，无需再次重启
check-ack-internet = 这台电脑已连接到 Internet
check-ack-generic = 我已自行检查此项要求

detail-admin-ok = Atlas 已获得安装所需的权限。
detail-admin-missing = 请以管理员身份重新打开 Atlas，并在 Windows 请求权限时选择“是”。
# $builds 为内部版本号列表，例如“26100 或 26200”；$build 为这台电脑的内部版本（文本）。
detail-build-unsupported = 此版本的 Atlas 需要 Windows 内部版本 { $builds }。这台电脑的内部版本是 { $build }。请先安装受支持的 Windows 版本再继续。
detail-updates-none = 没有等待安装的 Windows 更新。
# $titles 列出最多两个更新名称（文本）；$count 为总数。
detail-updates-pending =
    { $count ->
        [1] 请先安装此更新：{ $titles }。
        [2] 请先安装这些更新：{ $titles }。
       *[other] 请先安装 { $count } 个更新，包括 { $titles }。
    }
detail-updates-unknown = 无法检查 Windows 更新。请打开 Windows 更新，如果没有等待安装的更新，请在下方确认。（{ $error }）
detail-reboot-none = Windows 目前不需要重启。
detail-reboot-pending = 请重启电脑以完成之前的更改，然后重新打开 Atlas 并重新检查。
detail-reboot-unknown = 无法检查 Windows 是否需要重启。请重启电脑，然后重新打开 Atlas 并重新检查。（{ $error }）
detail-antivirus-none = 未检测到其他防病毒软件。
# $products 为产品名称列表（文本）。
detail-antivirus-found = 以下防病毒软件可能会阻止安装：{ $products }。请先卸载再继续。
detail-antivirus-unknown = 无法检查是否有其他防病毒软件。继续之前请查看已安装的应用。（{ $error }）
detail-internet-ok = 已连接。Atlas 下载和安装软件期间请保持连接。
detail-internet-missing = 请连接到 Internet，然后重新检查。
detail-power-mains = 电脑已接通电源。安装完成前请勿断开电源。
detail-power-battery = 请将电脑接通电源，确保整个安装过程中保持开机。
detail-power-unknown = 无法检查电源状态。如果你使用的是笔记本电脑，请先接通电源再继续。
detail-activation-ok = Windows 已激活。Atlas 不会更改此状态。
detail-activation-missing = Windows 尚未激活。你可以继续，但 Atlas 不会为你激活 Windows。
detail-activation-no-licence = Windows 未报告许可证。你可以继续；Atlas 不会更改你的激活状态。
detail-activation-unknown = 无法检查 Windows 激活状态。你可以继续；Atlas 不会更改你的激活状态。（{ $error }）

## 第 2 步：选项

options-progress = 第 { $number } 项选择，共 { $total } 项
options-progress-extras = 第 { $number } 项选择，共 { $total } 项：可选附加项
# 每项决定的简短名称（摘要行）以及每个页面提出的问题。
screen-defender-title = Microsoft Defender
screen-defender-question = 是否保留防病毒保护？
screen-mitigations-title = 处理器安全
screen-mitigations-question = 是否保留 Windows 的处理器防护？
screen-updates-title = Windows 更新
screen-updates-question = Windows 应如何安装更新？
screen-browser-title = 浏览器
screen-power-title = 电源和安全
screen-apps-title = 应用
screen-optional-apps-title = 可选应用
screen-choose-one-title = 选择一项
screen-extras-title = 可选附加项
screen-extras-question = 按需选择附加项
# 此应用没有专门措辞的必选项所使用的问题。
screen-generic-question = 为“{ $title }”选择一项
learn-more-defender = 详细了解 Microsoft Defender
learn-more-mitigations = 了解处理器安全
learn-more-updates = 详细了解 Windows 更新
learn-more-browser = 详细了解浏览器
learn-more-power = 详细了解电源和安全
learn-more-apps = 详细了解应用
learn-more-eclean = eclean 如何与 AtlasOS 配合使用
learn-more-generic = 阅读安装指南
# 所选答案下方的一行文字：这对电脑意味着什么。
consequence-defender-enable = 保留 Windows 内置的防病毒软件，帮助保护电脑免受病毒和其他威胁。
consequence-defender-disable = 移除 Microsoft Defender。在你安装其他防病毒应用之前，电脑将没有防病毒保护。
consequence-mitigations-default = 保留 Windows 默认的防护，抵御利用处理器工作方式的攻击。
consequence-mitigations-disable = 关闭这些防护，安全性会降低。性能表现取决于处理器，也可能变差。
consequence-auto-updates-disable = 你需要自行打开 Windows 更新并安装更新。更新通知仍会保留。
consequence-auto-updates-default = Windows 会自动安装更新，包括安全修复。

## Playbook 文本
## Playbook 安装包为每个选项自带英文文本。只有当安装包中的文本与
## i18n/playbook-source.ftl 完全一致时才使用下面的界面标签和说明。将来措辞不同的
## 安装包会显示自己的文字，而不是可能已过时的说明。

playbook-option-defender-enable = 保留 Microsoft Defender（推荐）
playbook-option-defender-disable = 移除 Microsoft Defender
playbook-option-mitigations-default = 保留默认防护（推荐）
playbook-option-mitigations-disable = 关闭处理器防护
playbook-option-auto-updates-disable = 由我自行安装更新
playbook-option-auto-updates-default = 自动安装更新
playbook-option-disable-hibernation = 关闭休眠
playbook-option-disable-power-saving = 关闭节能功能
playbook-option-disable-core-isolation = 关闭基于虚拟化的安全性 (VBS)
playbook-option-remove-snipping-tool = 卸载截图工具
playbook-option-uninstall-edge = 卸载 Microsoft Edge
playbook-option-install-another-browser = 安装浏览器
playbook-option-install-toolbox = 安装 Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender 是 Windows 内置的防病毒软件，建议保留。只有在了解风险并打算使用其他防病毒应用时，才应移除它。
playbook-page-mitigations-default-description = 这些防护也称为安全缓解措施，有助于抵御利用处理器漏洞的攻击。建议保留 Windows 的默认设置。
playbook-page-auto-updates-disable-description = Windows 更新包含安全修复。你可以让 Windows 自动安装，也可以自行安装。
consequence-install-toolbox = 添加 Atlas Toolbox，方便管理 Atlas 设置。Toolbox 目前处于测试阶段，部分功能可能尚未完善。
playbook-page-browser-brave-description = 选择要安装的浏览器。Atlas 不会更改你的浏览器设置。

## 第 3 步：Windows 安全中心

security-banner-reading-title = 正在检查 Windows 安全中心
security-banner-reading-message = Atlas 正在检查下方的四个防护开关。
security-banner-off-title = 四个防护开关均已关闭
security-banner-off-message = 现在可以在安装前核对你的选择了。
security-banner-readable-off-title = Atlas 能读取的开关均已关闭
security-banner-readable-off-message = 请在 Windows 安全中心检查其余开关。
security-banner-on-title = 暂时关闭防病毒保护
security-banner-on-message = 这些防护可能会阻止 Atlas 需要进行的更改。
# Windows 安全中心中的页面名称。
security-list-title = “病毒和威胁防护”设置
security-switch-off = 关
security-switch-on = 开
security-switch-unreadable = 无法读取
security-switch-reading = 正在检查
security-all-off = 全部关闭
# 开关行的辅助功能名称。$state 为 security-switch-* 消息之一。
security-a11y = { $title }：{ $state }
# 摘要“2 个仍开启，1 个无法读取”的组成部分。
security-count-still-on = { $count } 个仍开启
security-count-unreadable = { $count } 个无法读取
security-count-join = { $a }，{ $b }
security-unknown-title = 请确认 Atlas 无法读取的开关
security-unknown-message = 在 Windows 安全中心确认四个开关均已关闭后，请在下方确认。
security-acknowledge = 我已检查 Windows 安全中心，四个开关均已关闭
security-unknown-unelevated-title = Atlas 需要权限才能检查防护设置
security-unknown-unelevated-message = 请以管理员身份重新打开 Atlas，以便它检查 Microsoft Defender 的设置。
# 四个开关，名称与简体中文版 Windows 安全中心一致。
protection-tamper = 篡改防护
protection-tamper-why = 请先关闭此项，Defender 才会允许更改其防护设置。
protection-realtime = 实时保护
protection-realtime-why = 暂停文件扫描，以免 Defender 阻止 Atlas 的安装文件。
protection-cloud = 云提供的保护
protection-cloud-why = 暂停在线威胁检查，以免它阻止 Atlas 的安装文件。
protection-samples = 自动提交样本
protection-samples-why = 阻止 Defender 自动将 Atlas 的文件发送给 Microsoft 分析。

## 第 4 步：安装

install-preparing-title = 安装前的最后一次检查
install-preparing-message = 在进行更改之前，Atlas 正在再次检查你的电脑和防护设置。
install-installing = 正在安装
install-running = 正在运行
# 进度条的辅助功能名称。
install-progress = 安装进度
phase-preflight = 正在检查电脑并准备文件
phase-staging = 正在准备安装文件
phase-applying = 正在设置 Windows。请保持电脑开机。
phase-done = 正在完成设置
outcome-succeeded-title = Atlas 已安装
outcome-lost-title = 无法确认安装结果
outcome-failed-title = 安装未完成
outcome-succeeded = 请重启电脑以完成 Atlas 的设置。
outcome-requirements = 你的电脑不满足安装要求。未进行任何安装更改。请返回“准备”步骤并重新运行检查。
outcome-not-elevated = 未进行任何安装更改。请以管理员身份重新打开 Atlas，然后重试。
outcome-failed-preflight = 安装在更改任何内容之前已停止。请打开日志文件查看原因，然后重试。
outcome-failed-staging = 安装在准备文件时停止，尚未更改 Windows。请打开日志文件查看原因，然后重试。
outcome-failed-applying = 部分更改可能已经生效。如果你不再继续安装，请在 Windows 安全中心重新开启你之前关闭的防护（如果它们仍然存在）。
outcome-not-started = 安装程序未能及时启动。未进行任何安装更改。请选择“重试”。
outcome-lost = 安装程序已停止但没有报告结果，部分更改可能已经生效。请打开日志文件查看原因，然后选择“重试”以继续安装。
restart-now-message = Windows 正在重启，以完成 Atlas 的设置。
# 中文不区分单复数，因此不需要选择表达式。
restart-countdown = Windows 将在 { $seconds } 秒后重启，以便 Atlas 完成设置。
restart-stopped = 已取消自动重启。请保存工作，然后重启电脑以完成 Atlas 的设置。
restart-needed = 请保存工作，然后重启 Windows 以完成 Atlas 的设置。
restart-dont-now = 稍后重启
restart-now = 立即重启
# 倒计时条的辅助功能名称。
restart-progress = 距离重启的剩余时间
restart-start-failed = 无法重启 Windows。请保存工作，然后从“开始”菜单重启。详细信息：{ $error }
preflight-title = 安装尚未开始
preflight-invalid-options = Atlas 无法使用这些设置选择。请返回“你的选择”检查后重试。详细信息：{ $error }
# $problems 为由 preflight-problem 和 preflight-security 组成的一两句话。
preflight-changed = 自上次检查后，电脑的状态发生了变化。请先解决以下问题，然后重试。{ $problems }
preflight-problem = { $title }：{ $detail }
# $summary 为 Windows 安全中心摘要，例如“2 个仍开启”。
preflight-security = Windows 安全中心：{ $summary }。
preflight-busy = 另一个 Atlas 窗口正在启动安装。请稍候片刻，然后重试。
preflight-record-unreadable = Atlas 无法确定上次安装是否仍在进行，因此没有开始新的安装。请关闭并重新打开 Atlas 以查看恢复说明。详细信息：{ $error }
preflight-refused = 无法启动安装程序。未进行任何安装更改。详细信息：{ $error }
go-to-ready = 返回“准备”
go-to-options = 返回“你的选择”
output-problem-title = 无法读取安装进度
output-problem-message = Atlas 无法读取日志，但这并不表示安装已停止。请保持电脑开机，并尝试打开日志文件。详细信息：{ $error }
install-elevate-title = Atlas 需要权限才能安装
install-no-package-title = 请先选择安装文件
install-no-package-message = 请返回“准备”步骤下载 Atlas，或打开已保存的 Playbook (.apbx) 文件。
install-security-title = 安装前请检查防病毒保护
install-security-reading = 正在再次检查四个防护开关。
install-security-message = { $summary }。继续之前，请打开 Windows 安全中心，确认四个开关均已关闭。
summary-this-install = 安装摘要
summary-try-again = 重试前请核对
summary-ready = 核对你的 Atlas 设置
summary-activation = 激活
summary-activation-ok = 已激活。Atlas 不会更改此状态。
summary-activation-missing = 未激活。你可以继续，但 Atlas 不会激活 Windows。
summary-activation-unknown = Atlas 不会更改你的 Windows 激活状态。
summary-duration = 预计用时
# 中文不区分单复数，因此不需要选择表达式。
summary-duration-value = { $minutes } 分钟，然后重启
summary-restart-checkbox = 安装完成后自动重启电脑
summary-show-command = 显示安装命令
summary-hide-command = 隐藏安装命令
summary-command-unavailable = 无法准备安装命令。详细信息：{ $error }
summary-not-chosen = 尚未选择
# “更改”链接的辅助功能名称。$title 为 screen-*-title 消息之一。
summary-change-a11y = 更改“{ $title }”
footer-still-checking = 正在为安装做准备
footer-fix-items = 请完成上方的检查以继续
footer-need-package = 请下载 Atlas 或打开 Playbook 以继续
footer-reading-security = 正在检查防护开关
button-checking = 正在检查
button-installing = 正在安装
button-install = 安装 Atlas
# 中文不区分单复数，因此不需要选择表达式。
log-earlier-lines = 日志文件中还有之前的 { $count } 行。
# 复制日志时追加。$path 为文件路径（文本）。
log-full-log-note = （完整日志：{ $path }）

## 安装中视图

installing-checking-title = 最后一次检查
installing-checking-line = 在进行更改之前，Atlas 正在检查你的电脑。这可能需要一点时间。
installing-title = 正在安装 Atlas
installing-phase-preflight = 正在检查电脑并准备安装文件。
installing-phase-staging = 正在准备安装文件。请保持电脑开机。
installing-phase-applying = 正在按你的选择设置 Windows。请保持电脑开机并接通电源。
installing-phase-done = 正在完成安装。请保持电脑开机。
installing-installed-title = Atlas 已安装
# $time 为格式化后的时钟时间。
installing-started-just-now = 开始于 { $time }，不到一分钟前
# 中文不区分单复数，因此不需要选择表达式。
installing-started-minutes = 开始于 { $time }，{ $minutes } 分钟前

## 重启后的“Atlas 已安装”窗口

installed-title-version = Atlas { $version } 已安装
installed-title = Atlas 已安装
installed-ready = 一切就绪。你的电脑现在可以使用 Atlas 了。
installed-open-atlas = 查看 Atlas 安装详情

## 设置

settings-title = 设置
settings-theme = 应用主题
settings-theme-system = 跟随 Windows
settings-theme-light = 浅色
settings-theme-dark = 深色
settings-theme-contrast-note = Atlas 正在使用你的 Windows 对比主题的颜色。
settings-theme-mica-note = 要显示半透明背景，请选择与 Windows 相同的浅色或深色主题。
settings-language = 语言
settings-language-system = 跟随 Windows
# “跟随 Windows”下方：由此得到的语言。$language 为该语言的本地名称。
settings-language-system-detail = 跟随 Windows 时使用：{ $language }
# 已翻译但尚未经母语者审校的语言下方；此类语言不会被自动选择。
settings-language-preview = 预览版 · 等待语言审校
preview-notice = { $language }是预览版翻译。
preview-notice-switch = 切换到英文
preview-notice-language = 更改语言
# $tag 为语言标记（文本）。
settings-language-unavailable = 此版本的 Atlas 不提供 { $tag }。暂时显示英语，你的语言选择已保存。
# $languages 为 Windows 显示语言列表（文本）。
settings-language-windows-unmatched = Atlas 尚不支持你的 Windows 显示语言（{ $languages }）。暂时显示英语。
settings-language-windows-unavailable = 无法检查你的 Windows 显示语言。Atlas 暂时使用英语。详细信息：{ $error }
# $locale 为区域格式的本地名称，例如“中文(简体，中国)”。
settings-language-formats = 数字、日期和时间遵循你的 Windows 区域格式（{ $locale }）。
settings-language-contribute = 在 GitHub 上帮助翻译 Atlas
settings-installing = 安装
settings-restart-label = 安装完成后自动重启电脑
settings-restart-locked = 安装完成后才能更改此设置。
settings-restart-description = 需要重启才能完成设置。如果开启了自动重启，请在安装前保存工作。
settings-about = 关于
settings-about-app = Atlas Manager
settings-about-data = 应用文件
settings-about-licence = 许可证
settings-about-licence-value = GPL-3.0，自由开源
settings-view-source = 在 GitHub 上查看源代码
settings-open-data-folder = 打开应用文件夹

## 可选项：选择前显示的说明。

consequence-disable-hibernation = 释放休眠时用于保存会话的磁盘空间。休眠和快速启动将不可用。
consequence-disable-power-saving = 关闭节能功能。电脑可能更耗电、温度更高，电池续航也可能变短。
consequence-disable-core-isolation = 关闭 Windows 的一层额外安全防护，包括内存完整性。这会降低防护，并可能影响需要此功能的应用或游戏。
consequence-remove-snipping-tool = 卸载用于截屏和录屏的 Windows 应用。
consequence-uninstall-edge = 卸载 Microsoft Edge 浏览器。请确保已有其他浏览器，或在下方选择一个。
consequence-install-another-browser = 在下方选择一款浏览器，Atlas 会为你安装。

# 主页上安装 Atlas 之前显示的简介。
home-intro = Atlas 会调整 Windows，减少后台活动和干扰。在进行更改之前，我们会引导你完成检查和选择。

detail-build-missing = 此 Playbook 未声明支持的 Windows 内部版本。请选择完整的 Playbook 版本，而不是 LocalTest 安装包。
## ISO creation (Beta)
iso-home-title = Windows 安装介质
iso-home-description = 创建包含 Atlas 的 Windows ISO，用于在这台或其他电脑上全新安装。
iso-open = 创建 Atlas ISO
iso-title = 创建 Atlas ISO
iso-beta = 测试版
iso-beta-description = 在电脑上使用前，请先在虚拟机中测试 ISO。安装 Windows 前，请备份文件。
iso-admin-description = 读取 Windows 映像和创建安装介质需要管理员权限。
iso-files-description = 选择未经修改的 Windows 11 x64 ISO、Atlas Playbook (.apbx)，并为生成的文件指定一个新名称。
iso-source = Windows ISO
iso-package = Atlas Playbook (0.6+)
iso-output = 新 ISO 的保存位置
iso-no-file = 尚未选择文件
iso-browse = 浏览
iso-save-as = 另存为
iso-inspect = 检查文件
iso-mode-title = Windows 和 Atlas 偏好设置
iso-mode-interactive = 登录后选择 Atlas 设置
iso-mode-interactive-description = 登录后，Atlas 应用会帮助你更新 Windows 和商店应用、选择设置并应用 Atlas。
iso-mode-before = 现在选择 Atlas 设置
iso-mode-before-description = 将 Atlas 设置保存到 ISO 中。登录后，先更新 Windows 和商店应用，再按这些设置应用 Atlas。
iso-package-unsupported-title = 请选择更新的 Playbook
iso-package-unsupported = ISO 设置需要支持 ISO 的 Atlas 0.6 或更新版本。请选择兼容的 Playbook。
iso-atlas-options = Atlas 设置
iso-review = 检查 ISO 配置
iso-review-description = Atlas 会创建新的 ISO，并保留原文件。要安装 Windows，请从新 ISO 启动。创建 ISO 不会在这台电脑上安装 Atlas。
iso-review-files = 文件
iso-review-package = Atlas Playbook
iso-review-output = 新 ISO
iso-review-editions = 版本
iso-review-size = 大小
iso-review-size-value = { $size } MB
iso-review-account = 账户名
iso-review-target = 安装到
iso-review-drivers = 驱动程序
iso-create = 创建 ISO
iso-stage-inspect = 正在检查 Windows 映像
iso-stage-copy = 正在复制 Windows 文件
iso-stage-inject = 正在添加 Atlas
iso-stage-master = 正在创建 ISO
iso-stage-verify = 正在验证生成的文件
iso-stage-cleanup = 正在完成最后步骤
iso-progress-description = 请保持应用打开。处理较大的映像可能需要一些时间。
iso-cancel = 取消创建
iso-cancelling = 正在等待安全的取消时机
iso-cancelled = 已取消创建 ISO
iso-cancelled-description = 原始 ISO 已保留。如果仍有需要清理的临时文件，诊断日志中会有记录。
iso-complete = ISO 已准备就绪
iso-complete-description = 请先在虚拟机中测试，再用它创建 Windows 安装介质。
iso-open-folder = 在文件夹中显示
iso-failed = 未能完成 ISO 创建
iso-failed-description = 打开诊断查看失败原因。解决问题后，请使用新的输出文件名重试。
iso-diagnostics = 打开诊断
iso-close-title = ISO 仍在创建中
iso-close-message = 请保持此窗口打开，直到创建或取消完成。取消操作会等待当前步骤可以安全停止后再执行。
iso-keep-open = 保持打开
prepare-title = 更新 Windows 和商店应用
prepare-description = 应用 Atlas 前，请安装 Windows 更新，并更新 Microsoft Store 及所有已安装的商店应用。更新期间，商店应用可能会关闭。
prepare-complete = Windows 和商店应用均已更新。
prepare-reboot = Windows 需要重启。你的 Atlas 选项会被保存。登录后，请再次检查更新。
prepare-failed = 部分更新未能完成。请查看诊断日志，解决 Windows 或商店错误后重试。
prepare-cancelled = 准备已停止。继续之前，请再次检查更新。
prepare-windows-search = 正在检查 Windows 更新…
prepare-windows-download = 正在下载 Windows 更新…
prepare-windows-install = 正在安装 Windows 更新…
prepare-store-search = 正在检查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其应用…
prepare-stop-description = 当前更新操作完成后才会停止。请在停止前保持 Atlas 打开。
prepare-stop = 当前操作完成后停止
prepare-restart = 重启并继续
prepare-start = 检查并安装更新
iso-username = 本地账户名
iso-account-description = 重新安装 Windows 后，会提示你设置密码。
iso-username-placeholder = 你的名字
iso-account-invalid = 请输入 1–20 个字符，首尾不能有空格，也不能包含 Windows 账户名中不允许的符号。
iso-privacy-defaults = Windows 安装程序会自动关闭可选数据共享和个性化优惠。
prepare-drivers = 如何安装驱动程序？
prepare-drivers-auto = 通过 Windows 更新获取驱动程序
prepare-drivers-auto-detail = Windows 会为硬件查找驱动程序。推荐大多数电脑使用。
prepare-drivers-manual = 自行安装驱动程序
prepare-drivers-manual-detail = 阻止 Windows 更新下载驱动程序。你需要自行获取驱动程序；已安装的驱动程序会保留。
prepare-network-needed = 请连接未设为按流量计费的 Wi-Fi 或以太网，然后重试。如果没有 Wi-Fi 选项，请先安装网卡驱动程序。
prepare-network-settings = 打开网络设置
iso-target-title = 要在哪台电脑上重新安装 Windows？
iso-target-this = 这台电脑
iso-target-other = 另一台电脑
iso-copy-network = 包含这台电脑的网卡驱动程序
iso-network-detail = 安装 Windows 时复用这台电脑的 Wi-Fi 和以太网驱动程序。重装后需要重新连接 Wi-Fi。
iso-network-source = 网卡驱动程序来源
iso-network-installed = 使用已安装的驱动程序
iso-network-updated = 先检查 Windows 更新
iso-network-updated-detail = 下载 Windows 更新提供的匹配驱动程序，同时保留已安装的驱动程序作为备用。需要非按流量计费的连接。
iso-stage-network-drivers = 正在准备网卡驱动程序…
iso-network-failed = 无法准备网卡驱动程序。请查看诊断信息，或返回并更改网卡驱动程序选项。
iso-mode-desktop = 进入桌面前完成设置
iso-mode-desktop-description = 现在选择 Atlas 设置。登录后，先完成更新和 Atlas 设置，再进入 Windows 桌面。
desktop-setup-description = 请完成电脑设置。你的 Atlas 选项已保存，需要时可以返回 Windows。
desktop-setup-exit = 在 Windows 中继续

# Windows installation USB (Beta)
usb-title = 创建安装 U 盘
usb-existing = 使用现有 ISO 创建 U 盘
usb-description = 创建 Windows 11 25H2 启动 U 盘，用于在电脑上安装 Windows 和 Atlas。
usb-choose-iso = 选择 ISO
usb-drive = USB 驱动器
usb-empty = 连接 USB 驱动器后刷新列表。这里只显示可写入且不包含当前运行的 Windows 系统的 USB 驱动器。
usb-refresh = 刷新
usb-drive-detail = { $size } GB · { $volumes } · 序列号：{ $serial }
usb-review = 检查 U 盘
usb-erase-title = 要清空此 USB 驱动器吗？
usb-erase-description = { $drive }（{ $size } GB）上的所有文件和分区都将被永久删除。ISO 文件会保留。
usb-layout = Windows 安装文件最多使用 32 GB，剩余空间将保持未分配状态。此 U 盘适用于通过 UEFI 启动的电脑。
usb-ack = 我了解此 USB 驱动器上的所有内容都将被删除。
usb-write = 清空并创建 U 盘
usb-stage-prepare = 正在准备安装文件…
usb-stage-format = 正在格式化 U 盘…
usb-stage-copy = 正在复制安装文件…
usb-stage-verify = 正在验证 U 盘…
usb-working = 请保持 Atlas 打开，并保持 U 盘连接。取消操作会等待当前任务安全停止。未完成的 U 盘无法用于安装 Windows。
usb-failed = 无法完成 U 盘创建。请检查连接，并打开诊断查看详情。重新选择驱动器后再试。
usb-cancelled = U 盘创建已停止。驱动器上可能存在不完整的安装文件。请重新创建后再用于安装 Windows。
usb-complete = U 盘已准备就绪，所有文件均已验证。请先弹出 U 盘，再将其连接到要重装系统的电脑，并在该电脑的 UEFI 启动菜单中选择它。
usb-eject = 弹出 U 盘
usb-ejected = 现在可以安全拔出 U 盘。安装 Windows 时，请在电脑的 UEFI 启动菜单中选择它。
usb-eject-failed = Windows 无法弹出 U 盘。请关闭正在使用它的文件或窗口，然后重试。
ready-fresh-title = 请先全新安装 Windows
ready-fresh-description = 除受支持的 Atlas 升级外，Atlas 需要全新安装的 Windows。全新安装 Atlas 0.6 需要 Windows 11 25H2。重新安装 Windows 前，请备份文件。
detail-edition-unsupported = 请使用 Windows 11 Pro、Pro for Workstations 或 Enterprise。不支持 Home、LTSC 和 Server 版本。如果无法识别您的版本，请先解决此问题再继续。
install-source-title = 无法安装
install-source-unsupported = Atlas { $source } 无法直接更新到 { $target }。请重新安装 Windows 后再使用此版本。
install-source-unknown = Atlas 无法确认安装状态。请先处理未完成的安装并检查诊断信息，然后重试。
iso-edition-selection = 仅包含受支持的版本。安装 Windows 时，请选择你拥有 Windows 许可证的版本。
detail-windows-preview = 不支持 Insider 预览版本。请使用 Windows 11 的正式发布版本。
detail-windows-release-unknown = Atlas 无法确认此 Windows 内部版本是否已正式发布。请连接互联网后重新检查。
iso-release-unknown = 无法确认此 ISO 是否包含正式发布的 Windows 11 25H2。请连接互联网后重试，或选择官方安装介质。
prepare-previous-worker = 之前的更新操作仍在运行。Atlas 会等待其完成，之后你可以重试。

ready-used-windows-title = 请先重新安装 Windows 再继续
ready-used-windows-description = 此 Windows 系统存在已使用的迹象。在此系统上安装 Atlas 不受支持，我们强烈建议不要这样做。仅在你了解风险的情况下继续。
ready-used-windows-dismiss = 我了解风险
playbook-option-install-eclean = 安装 eclean
consequence-install-eclean = AtlasOS 团队打造的维护工具，帮助您在设置完成后保持电脑整洁。检查垃圾文件和启动应用。需要账户和互联网连接。
