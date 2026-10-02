### Atlas Manager: Chinese (Simplified) (zh-Hans), preview translation. Revised 30 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
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
### - .apbx 文件统称“Atlas 安装包”，上下文明确时可简称“安装包”；“安装文件”指准备好的文件（如“安装文件”卡片中的文件），
###   不用来指 .apbx 文件本身。

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }，{ $section }
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
list-and = { $a }和{ $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }。{ $message }

## 窗口

# 安装进行中关闭窗口时显示的对话框。
window-close-title = 安装期间要关闭窗口吗？
window-close-message = 安装会在后台继续进行。重新打开 Atlas 即可查看进度和结果。安装完成前请保持电脑开机。
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = 安装会在后台继续进行，但 Atlas 关闭期间，电脑不会自动重启。重新打开 Atlas 即可查看进度和结果。安装完成前请保持电脑开机。
window-close-keep = 保持打开
window-close-close = 关闭窗口
# 在最后检查期间、安装程序启动之前关闭窗口时显示的对话框；按钮为 window-close-keep 和 window-close-close。
window-close-preparing-title = 要在安装开始前关闭窗口吗？
window-close-preparing-message = Atlas 仍在检查你的电脑，尚未开始安装。如果现在关闭，安装将不会开始。重新打开 Atlas 即可继续。
prepare-close-title = 更新仍在进行
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = 更新期间请保持 Atlas 打开。如果选择“停止更新”，更新会在当前步骤完成后停止，届时即可关闭 Atlas。
# 安装成功后在重启倒计时期间关闭窗口时显示的对话框；按钮为 window-close-keep、restart-now 和 window-close-restart-close。
window-close-restart-title = 要关闭 Atlas 而不重启电脑吗？
# “立即重启”即 restart-now，是此对话框的三个按钮之一。
window-close-restart-message = 电脑需要重启才能完成 Atlas 的设置。如果现在关闭 Atlas，它不会重启电脑，请在准备好后自行重启。选择“立即重启”前，请先保存工作。
window-close-restart-close = 关闭但不重启
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = 要在防护关闭的状态下关闭 Atlas 吗？
window-close-protection-message = Windows 安全中心的部分防护仍处于关闭状态：{ $switches }。如果你不打算完成 Atlas 的安装，请在关闭前将其重新开启。如果你要完成安装，重新打开 Atlas 后即可继续设置。
# 选择 Atlas 安装包 (.apbx) 时文件选择器的标题。
file-dialog-open-package = 打开 Atlas 安装包 (.apbx)
# Windows 在重启通知中显示的消息。
shutdown-comment = Atlas 已安装。Windows 即将重启以完成设置。
# “准备”步骤为完成 Windows 更新的安装而重启时，Windows 在重启通知中显示的消息。
prepare-shutdown-comment = Atlas 正在重启 Windows，以完成更新的安装。

## 系统

# “Windows 11 专业版 25H2（内部版本 26200.1234）”。三个值均为文本。
system-description = { $product } { $version }（内部版本 { $build }）

## 主页

home-not-installed = 欢迎使用 Atlas
# Atlas Manager 无法确定这台电脑上安装了什么时的标题。
home-state-unknown = 这台电脑上的 Atlas
# 已安装 Atlas 时的标题。$version 为文本。
home-version = Atlas { $version }
# $date 为格式化后的日期。
home-installed-on = 安装于 { $date }
home-status-checking = 正在检查更新
# 启动时检查另一个窗口的安装是否正在运行。
home-status-recovering = 正在检查是否有进行中的安装
home-status-offline = 无法检查更新
home-status-not-checked = 尚未检查更新
home-status-update = 新版本 Atlas { $version } 已发布
home-status-up-to-date = 已是最新版本
home-status-newest = 最新版本：Atlas { $version }
# 之前的 Atlas { $version } 安装在完成前已停止。
home-status-unfinished = Atlas { $version } 的安装尚未完成
home-check-again = 重新检查
# 安装正在运行或等待时的主按钮。
home-show-install = 查看进度
home-continue-installing = 继续安装
home-update-to = 更新到 Atlas { $version }
home-reinstall = 重新安装 Atlas
home-install = 安装 Atlas
home-finish-install = 完成 Atlas { $version } 的安装
home-start-over = 重新开始
home-restart-title = 电脑需要重启
home-security-reminder-title = 请重新开启防护
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = 请确认防护已开启
home-security-reminder-message = Atlas 当前没有在安装任何内容，但 Windows 安全中心的部分防护仍处于关闭状态。请打开 Windows 安全中心，确保以下各项已开启：{ $switches }。
home-security-reminder-unreadable-message = Atlas 无法读取部分防护开关。请在 Windows 安全中心检查以下各项是否已开启：{ $switches }。
home-elevation-title = Atlas 需要权限才能安装
home-state-error-title = 无法读取 Atlas 的安装详情
home-state-error-message = 你的 Atlas 版本、选择和安装历史记录可能无法正确显示。请选择“重新检查”重试。详细信息：{ $error }
home-whats-new = Atlas { $version } 新增内容
home-view-release = 在 GitHub 上查看发行说明
home-released = 发布于 { $date }
home-show-less = 收起
home-show-full-notes = 显示全部发行说明
home-your-install = Atlas 安装详情
# 已安装 Atlas，但没有 Atlas Manager 保存的安装记录（旧版本不会写入此记录）。
home-install-unrecorded = 这台电脑上没有 Atlas 安装方式的记录，因此无法显示你的选择和安装历史记录。
# 行标签：Atlas 是如何安装的。
home-set-up = 安装方式
home-set-up-during-oobe = 在 Windows 初始设置期间
home-history = 安装历史记录
# 一行历史记录。$version 为文本，$mode 为 history-mode-* 消息之一，$date 为格式化后的日期和时间。
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = 为安装 Atlas 做好准备
home-step-1-detail = Atlas 会检查你的电脑，安装待处理的 Windows 和 Microsoft Store 更新，并下载安装文件。商店应用可能会关闭，电脑也可能需要重启，因此请先保存工作。
# 测试版：Atlas 安装包已内置，不需要下载。
home-step-1-detail-bundled = Atlas 会检查你的电脑，安装待处理的 Windows 和 Microsoft Store 更新，并准备内置的安装文件。商店应用可能会关闭，电脑也可能需要重启，因此请先保存工作。
home-step-2-detail = 选择是否保留 Microsoft Defender 和处理器防护，决定 Windows 更新的安装方式，并挑选可选附加项。
home-step-3-detail = 关闭 Windows 安全中心的四个防护开关，以免它们阻止安装。Atlas 会告诉你如何操作。
# 中文不区分单复数，因此不需要选择表达式。
home-step-4-detail = 安装大约需要 { $minutes } 分钟。之后电脑需要重启。
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
# $error 为原始错误消息（文本）。
notice-settings-not-saved = Atlas 无法保存你最近的更改，关闭 Atlas 后这些更改可能会丢失。如果打开了另一个 Atlas 窗口，请将其关闭，然后重新进行更改。详细信息：{ $error }
notice-session-unreadable-title = 无法检查上次的安装
# $path 为文件路径（文本）。
notice-session-unreadable-message = Atlas 无法判断之前的安装是否仍在进行。如果你不确定，请向 Atlas 社区求助。只有在确定没有安装正在进行时，才删除 { $path } 并重试。详细信息：{ $error }

## 管理员提升

elevation-declined = 未获得权限。请重试，并在 Windows 询问是否允许此应用对你的设备进行更改时选择“是”。
elevation-declined-continue = 未获得权限。请重试，并在 Windows 询问是否允许此应用对你的设备进行更改时选择“是”。你的选择已保存。
elevation-draft-not-saved = Atlas 无法保存你的选择，因此未以管理员身份重新打开。请重试。详细信息：{ $error }
# 与 home-start-over 按钮一起显示。
elevation-taken-over = 另一个 Atlas 窗口已接管此次安装流程，因此 Atlas 未以管理员身份重新打开。请在那个窗口中继续，或选择“重新开始”，改在此窗口中进行。

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
stepper-status-attention = 需要注意
# 每个步骤内容上方的标题。
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }。{ $progress }：{ $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }。{ $progress }

## 第 1 步：准备

ready-banner-busy-title = 正在准备你的电脑
ready-banner-busy-message = Atlas 正在检查你的电脑并准备安装文件。
ready-banner-blocked-title = 电脑尚未准备就绪
ready-banner-blocked-message = 请处理“电脑检查”中标出的项目，然后选择“重新检查”。
ready-banner-no-package-title = 下载 Atlas 以继续
ready-banner-no-package-message = 请在“安装文件”中下载 Atlas；如果你已有 Atlas 安装包 (.apbx)，请选择“打开安装包文件”。
# 测试版：内置的 Atlas 安装包无法解压。
ready-banner-no-package-bundled-title = 准备内置的 Atlas 安装包以继续
ready-banner-no-package-bundled-message = 此测试版内置的 Atlas 安装包尚未就绪。请查看“安装文件”卡片。
ready-banner-updates-title = 更新 Windows 和商店应用以继续
ready-banner-updates-message = 请选择“检查并安装更新”。更新完成后，Atlas 会再次检查你的电脑。
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = 正在更新 Windows 和商店应用
ready-banner-updating-message = 这可能需要一些时间。请保持 Atlas 打开。你可以在“更新 Windows 和商店应用”中查看进度。
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = 更新已停止
ready-banner-updates-stopped-message = 请在“更新 Windows 和商店应用”中选择“检查并安装更新”以完成更新。
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = 电脑已重启
ready-banner-updates-resumed-message = 请在“更新 Windows 和商店应用”中选择“继续更新”，以完成更新。
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = 请在“更新 Windows 和商店应用”中查看处理方法，然后选择“重试”。
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = 请先保存工作，然后在“更新 Windows 和商店应用”中选择“重启并继续”。
ready-banner-warnings-title = 有几项需要留意
ready-banner-warnings-message = 你可以继续，但请先阅读“电脑检查”中标出的项目。
ready-banner-ok-title = 可以开始做出选择了
ready-banner-ok-message = 检查已通过，安装文件已就绪。

# 卡片标题以及检查列表的辅助功能名称。
ready-this-pc = 电脑检查
ready-check-again = 重新检查
ready-checks-passed = { $count } 项检查已通过

package-title = 安装文件
# $received 和 $total 为格式化后的兆字节数（文本）。
package-downloading = 正在下载 Atlas { $version } · { $received } / { $total } MB
# 中文不区分单复数，因此不需要选择表达式。
package-unpacking-progress = 正在解压 · { $done } / { $total } 个文件
package-unpacking = 正在解压
package-looking = 正在检查 Atlas 的最新版本。
# 测试版：正在解压内置的 Atlas 安装包，不需要下载。
package-looking-bundled = 正在准备内置的 Atlas 安装包。
package-none = 下载 Atlas 以获取安装文件。如果你已有 Atlas 安装包 (.apbx)，也可以直接打开它。
# GitHub 发布版本检查失败。“下载最新版本”即 package-download-newest，是此状态下提供的按钮，它会重新检查。
package-release-failed = Atlas 无法检查最新版本。请检查 Internet 连接，然后选择“下载最新版本”，或打开已保存的 Atlas 安装包 (.apbx)。
# 卡片标题旁边的简短状态词。
package-status-downloading = 正在下载
package-status-unpacking = 正在解压
package-status-failed = 无法准备文件
package-status-ready = 已就绪
package-status-checking = 正在检查
package-status-preparing = 正在准备
package-status-missing = 未下载
# 进度条的辅助功能名称。
package-progress = 安装文件进度
package-download-again = 重新下载
package-download-version = 下载 Atlas { $version }
package-download-newest = 下载最新版本
package-cancel-download = 取消下载
package-open-file = 打开安装包文件
# 安装包的来源。$file 为文件名，$path 为文件夹路径（文本）。
package-from-release = Atlas { $version } 已从 GitHub 下载，可以安装。
package-from-file = Atlas { $version } 已从 { $file } 加载，可以安装。
package-unpacked = Atlas { $version } 已就绪，可以安装。
package-none-yet = 尚未选择安装文件
acquire-no-asset = Atlas { $version } 没有可下载的安装包。请打开已保存的 Atlas 安装包 (.apbx) 以继续。
acquire-unsupported = 此应用只能安装 Atlas 0.6.0 及更高版本。要安装 Atlas { $version }，请改用 AME Wizard。
# 安装包足够新，本应包含此应用驱动的安装脚本，但缺少该脚本。
acquire-incomplete = Atlas { $version } 缺少此应用安装所需的文件。请重新下载，或打开其他 Atlas 安装包 (.apbx)。
acquire-failed = 无法准备安装文件。请重新下载，或打开其他 Atlas 安装包 (.apbx)。详细信息：{ $error }
# 下载在一分钟内未收到任何数据，已被停止。
acquire-stalled = 下载已停止响应。请检查 Internet 连接，然后重新下载，或打开已保存的 Atlas 安装包 (.apbx)。
# 测试版：内置的 Atlas 安装包无法解压。“重试”是唯一提供的操作。
acquire-failed-bundled = 无法准备内置的 Atlas 安装包。请选择“重试”。详细信息：{ $error }

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
check-fix-apps = 打开“已安装的应用”
# 无法运行 Windows 更新扫描时，用户勾选的复选框。
check-ack-updates = 我已查看 Windows 更新，没有等待安装的更新

detail-admin-ok = Atlas 已获得安装所需的权限。
detail-admin-missing = 请以管理员身份重新打开 Atlas，并在 Windows 请求权限时选择“是”。
# $builds 为内部版本号列表，例如“26100 或 26200”；$build 为这台电脑的内部版本（文本）。
detail-build-unsupported = 此版本的 Atlas 需要 Windows 内部版本 { $builds }。这台电脑的内部版本是 { $build }。请先安装受支持的 Windows 版本再继续。
detail-build-missing = 此 Atlas 安装包未列出任何受支持的 Windows 内部版本。请使用完整版安装包，而不是 LocalTest 版本。
detail-updates-none = 没有等待安装的 Windows 更新。
# $titles 列出最多两个更新名称（文本）；$count 为总数。
detail-updates-pending =
    { $count ->
        [1] 此更新正在等待安装：{ $titles }。Atlas 会在“更新 Windows 和商店应用”中安装它。
        [2] 这些更新正在等待安装：{ $titles }。Atlas 会在“更新 Windows 和商店应用”中安装它们。
       *[other] 有 { $count } 个更新正在等待安装，包括 { $titles }。Atlas 会在“更新 Windows 和商店应用”中安装它们。
    }
detail-updates-unknown = 无法检查 Windows 更新。请打开 Windows 更新，如果没有等待安装的更新，请在下方确认。（{ $error }）
detail-reboot-none = Windows 目前不需要重启。
detail-reboot-pending = Windows 需要重启以完成之前的更改。选择“检查并安装更新”后，Atlas 会先请你重启。
# $reasons：Windows 设置的待重启标记，取自 prepare-reason-* 各项名称。
detail-reboot-pending-reasons = Windows 需要重启以完成之前的更改（{ $reasons }）。选择“检查并安装更新”后，Atlas 会先请你重启。
# 这是警告而非阻止项：$files 列出 Windows 将在下次重启时替换或删除的文件路径，最多三个。
detail-reboot-file-renames = 你可以继续。Windows 有一些文件要在下次重启时替换或删除（{ $files }）。Xbox Gaming Services 等部分应用每次重启后都会这样做。
detail-reboot-unknown = 无法检查 Windows 是否需要重启。请重启电脑，然后重新打开 Atlas 并重新检查。（{ $error }）
detail-antivirus-none = 未检测到其他防病毒软件。
# $products 为产品名称列表（文本）。
detail-antivirus-found = Microsoft Defender 以外的防病毒软件可能会阻止安装。请卸载 { $products }，然后选择“重新检查”。
# 这是警告而非阻止项：安全中心仍列出该产品，但其文件已不存在。
detail-antivirus-stale = Windows 安全中心仍列出了 { $products }，但其文件已不存在，因此它已不再安装在电脑上。Atlas 仍可继续安装。
detail-antivirus-unknown = 无法检查是否有其他防病毒软件。请选择“重新检查”。如果仍然失败，请重启电脑，然后再次检查。（{ $error }）
detail-internet-ok = 已连接。Atlas 下载和安装软件期间请保持连接。
detail-internet-missing = 请连接到 Internet，然后重新检查。
detail-power-mains = 电脑已接通电源。安装完成前请勿断开电源。
detail-power-battery = 请将电脑接通电源，确保整个安装过程中保持开机。
detail-power-unknown = Atlas 无法判断电脑是否已接通电源。如果是笔记本电脑，请接通电源，然后选择“重新检查”。如果此问题持续出现，请选择“发送报告”。
detail-activation-ok = Windows 已激活。Atlas 不会更改此状态。
detail-activation-missing = Windows 尚未激活。你可以继续，但 Atlas 不会为你激活 Windows。
detail-activation-no-licence = Windows 未报告许可证。你可以继续；Atlas 不会更改你的激活状态。
detail-activation-unknown = 无法检查 Windows 激活状态。你可以继续；Atlas 不会更改你的激活状态。（{ $error }）

## 第 2 步：你的选择

options-progress = 第 { $number } 项选择，共 { $total } 项
options-progress-extras = 第 { $number } 项选择，共 { $total } 项：可选附加项
options-change-later = 之后，你可以在桌面上的 Atlas 文件夹中更改 Microsoft Defender、处理器防护和更新设置。
# 每项决定的简短名称（摘要行）以及每个页面提出的问题。
screen-defender-title = Microsoft Defender
screen-defender-question = 是否保留 Microsoft Defender？
screen-mitigations-title = 处理器防护
screen-mitigations-question = 是否保留 Windows 的处理器防护？
screen-updates-title = Windows 更新
screen-updates-question = Windows 应如何安装更新？
screen-browser-title = 浏览器
screen-power-title = 电源和安全
screen-apps-title = 应用
screen-optional-apps-title = 可选应用
screen-choose-one-title = 选择一项
screen-extras-title = 可选附加项
# 此应用没有专门措辞的必选项所使用的问题。
screen-generic-question = 为“{ $title }”选择一项
learn-more-defender = 详细了解 Microsoft Defender
learn-more-mitigations = 详细了解处理器防护
learn-more-updates = 详细了解 Windows 更新
learn-more-browser = 详细了解浏览器
learn-more-power = 详细了解电源和安全
learn-more-apps = 详细了解应用
learn-more-eclean = eclean 如何与 AtlasOS 配合使用
learn-more-generic = 阅读安装指南
# 所选答案下方的一行文字：这对电脑意味着什么。
consequence-defender-enable = 保留 Windows 内置的防病毒软件，帮助保护电脑免受病毒和其他威胁。
consequence-defender-disable = 同时会移除 SmartScreen。在你安装其他防病毒软件之前，电脑将没有防病毒保护；打开无法识别的应用或下载的文件前，Windows 也不会发出警告。
consequence-mitigations-default = 保留 Windows 的默认防护，抵御处理器漏洞以及利用应用缺陷发起的攻击。
consequence-mitigations-disable = 同时会关闭 Exploit Protection 中针对应用的防护，例如控制流保护 (CFG)。这会降低安全性。性能是否有变化取决于你的处理器。
consequence-auto-updates-disable = 请定期打开 Windows 更新来安装更新。更新通知保持开启。
consequence-auto-updates-default = Windows 会自动安装更新，包括安全修复。

## Atlas 安装包文本
## Atlas 安装包为每个选项自带英文文本。只有当安装包中的文本与
## i18n/playbook-source.ftl 完全一致时才使用下面的界面标签和说明。将来措辞不同的
## 安装包会显示自己的文字，而不是可能已过时的说明。

playbook-option-defender-enable = 保留 Microsoft Defender（推荐）
playbook-option-defender-disable = 移除 Microsoft Defender
playbook-option-mitigations-default = 保留处理器防护（推荐）
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
playbook-option-install-eclean = 安装 eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender 是 Windows 内置的防病毒软件。只有在你了解风险并打算使用其他防病毒软件时，才应将其移除。无论你如何选择，Atlas 都会关闭“智能应用控制”“增强型网络钓鱼防护”和“查找我的设备”。
playbook-page-mitigations-default-description = 这些防护也称为安全缓解措施，可帮助抵御 Spectre 和 Meltdown 等处理器漏洞，以及利用应用缺陷发起的攻击。建议保留 Windows 默认设置。
playbook-page-auto-updates-disable-description = Windows 更新包含安全修复。你可以让 Windows 自动安装更新，也可以自行安装。无论哪种方式，Atlas 都会让 Windows 保持在当前版本，而该版本只会在 Microsoft 终止支持之前获得安全修复。Atlas 还会关闭 Microsoft Store 应用的自动更新，因此请在 Microsoft Store 中更新这些应用。
playbook-page-browser-brave-description = 选择要安装的浏览器。Atlas 不会更改你的浏览器设置。

## 第 3 步：Windows 安全中心

security-banner-reading-title = 正在检查 Windows 安全中心
security-banner-reading-message = Atlas 正在检查下方的四个防护开关。
security-banner-off-title = 四个防护开关均已关闭
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = 这台电脑未安装 Microsoft Defender
security-banner-absent-message = 此步骤中没有需要关闭的项目。请选择“继续”。
security-banner-off-message = 请选择“继续”，核对设置并安装 Atlas。
security-banner-on-title = 在 Windows 安全中心关闭防病毒保护
security-banner-on-message = Microsoft Defender 可能会阻止 Atlas 进行的更改。请选择“打开 Windows 安全中心”，然后关闭下方列出的每个开关。如果你保留 Microsoft Defender，请在安装完成后重新开启这些开关。
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
security-unknown-message = 请确保 Windows 安全中心中的四个开关均已关闭，然后在下方确认。
security-acknowledge = 我已检查 Windows 安全中心，四个开关均已关闭
security-unknown-unelevated-title = Atlas 需要权限才能检查防护设置
security-unknown-unelevated-message = 请以管理员身份重新打开 Atlas，以便它检查 Microsoft Defender 的设置。
# 四个开关，名称与简体中文版 Windows 安全中心一致。
protection-tamper = 篡改防护
protection-tamper-why = 关闭此项，以免 Defender 阻止 Atlas 更改 Defender 的安全设置。
protection-realtime = 实时保护
protection-realtime-why = 关闭此项，以免 Defender 在扫描时阻止 Atlas 的安装文件。
protection-cloud = 云提供的保护
protection-cloud-why = 关闭此项，以免在线威胁检查阻止 Atlas 的安装文件。
protection-samples = 自动提交样本
protection-samples-why = 阻止 Defender 自动将 Atlas 的文件发送给 Microsoft 分析。

## 第 4 步：安装

# 进度条的辅助功能名称。
install-progress = 安装进度
# 显示在进度条旁边的安装进度。$percent 为 0 到 99 之间的整数。
install-percent = { $percent }%
outcome-succeeded-title = Atlas 已安装
outcome-lost-title = 无法确认安装结果
outcome-failed-title = 安装未完成
outcome-requirements = 你的电脑不满足安装要求。未进行任何安装更改。请返回“准备”步骤并重新运行检查。
# -resumed 变体用于重试一个之前的尝试已开始应用更改的安装。
outcome-requirements-resumed = 你的电脑不满足安装要求，因此本次尝试已停止。之前的尝试已经开始进行更改。请返回“准备”步骤并重新运行检查。
outcome-not-elevated = Atlas 没有管理员权限。未进行任何安装更改。请以管理员身份重新打开 Atlas，然后重试。
outcome-not-elevated-resumed = Atlas 没有管理员权限，因此本次尝试已停止。之前的尝试已经开始进行更改。请以管理员身份重新打开 Atlas，然后重试。
# 安装程序的实时检查发现 Windows 或商店更新尚未完成。“准备”步骤会再次提供更新检查；
# “检查并安装更新”即 prepare-start，是该状态下的按钮。
outcome-preparation-stale = Atlas 无法确认 Windows 和商店应用均已更新，因此安装在更改 Windows 之前已停止。请返回“准备”步骤，然后选择“检查并安装更新”。
outcome-preparation-stale-resumed = Atlas 无法确认 Windows 和商店应用均已更新，因此本次尝试已停止，但之前的尝试已经开始进行更改。请返回“准备”步骤，然后选择“检查并安装更新”。
outcome-failed-preflight = 安装在更改任何内容之前已停止。你可以重试。如果再次停止，请选择“发送报告”。
outcome-failed-staging = 安装在准备文件时停止，尚未更改 Windows。你可以重试。如果再次停止，请选择“发送报告”。
outcome-failed-applying = 部分更改可能已经生效。你可以重试。如果你不再继续，请在 Windows 安全中心重新开启你之前关闭的防护（如果它们仍然存在）。
outcome-failed-resumed = 本次尝试提前停止，但之前的尝试已经开始进行更改。你可以重试。如果你不再继续，请在 Windows 安全中心重新开启你之前关闭的防护（如果它们仍然存在）。
outcome-not-started = 安装程序未能及时启动。未进行任何安装更改。你可以重试。
outcome-lost = 安装程序未报告结果就停止了，部分更改可能已经生效。你可以重试。如果你不再继续，请在 Windows 安全中心重新开启你之前关闭的防护（如果它们仍然存在）。
restart-now-message = Windows 正在重启，以完成 Atlas 的设置。
# 中文不区分单复数，因此不需要选择表达式。
restart-countdown = Windows 将在 { $seconds } 秒后重启，以完成 Atlas 的设置。要先保存工作，请选择“稍后重启”。
restart-stopped = 已取消自动重启。请保存工作，然后重启电脑以完成 Atlas 的设置。
restart-needed = 请保存工作，然后重启电脑以完成 Atlas 的设置。
restart-dont-now = 稍后重启
restart-now = 立即重启
restart-start-failed = Atlas 无法重启电脑。请保存工作，然后从“开始”菜单重启。详细信息：{ $error }
preflight-title = 安装尚未开始
preflight-invalid-options = Atlas 无法使用这些选择。请返回“你的选择”检查后重试。详细信息：{ $error }
# $problems 为由 preflight-problem 和 preflight-security 组成的一两句话。
preflight-changed = 自上次检查后，电脑的状态发生了变化。请先解决以下问题，然后重试。{ $problems }
preflight-problem = { $title }：{ $detail }
# $summary 为 Windows 安全中心摘要，例如“2 个仍开启”。
preflight-security = Windows 安全中心：{ $summary }。
preflight-busy = 另一个 Atlas 窗口正在启动安装。请稍候片刻，然后再次选择“安装 Atlas”。
# 与 home-start-over 按钮一起显示。
preflight-taken-over = 另一个 Atlas 窗口已接管此次安装流程，因此安装尚未开始。请在那个窗口中继续，或选择“重新开始”，改在此窗口中进行。
preflight-record-unreadable = Atlas 无法确定上次安装是否仍在进行，因此没有开始新的安装。请返回“准备”，查看接下来该怎么做。详细信息：{ $error }
preflight-refused = 无法启动安装程序。未进行任何安装更改。请选择“安装 Atlas”重试。如果问题持续出现，请选择“发送报告”。详细信息：{ $error }
# 重试之前的尝试已开始应用的安装时，代替 preflight-refused 显示。
preflight-refused-resumed = 无法启动安装程序，因此本次尝试已停止。之前的尝试已经开始进行更改。请选择“安装 Atlas”重试。如果问题持续出现，请选择“发送报告”。详细信息：{ $error }
go-to-ready = 返回“准备”
go-to-options = 返回“你的选择”
# 从“安装”步骤的“更改”链接打开某项选择，且“继续”会直接返回“安装”时，代替“继续”按钮。
go-to-install = 返回“安装”
output-problem-title = 无法读取安装进度
output-problem-message = Atlas 无法读取日志，但这并不表示安装已停止。请保持电脑开机，并尝试打开日志文件。详细信息：{ $error }
install-elevate-title = Atlas 需要权限才能安装
install-no-package-title = 请先选择安装文件
install-no-package-message = 请返回“准备”步骤下载 Atlas，或打开已保存的 Atlas 安装包 (.apbx)。
# install-no-package-message 的测试版变体。
install-no-package-bundled-message = 请返回“准备”步骤，准备此测试版内置的 Atlas 安装包。
# 本次会话中第 1 步（检查或 Windows 更新）未完成时的第 4 步，按钮为 go-to-ready。
install-not-ready-title = 请先完成“准备”步骤
install-not-ready-message = Atlas 需要先完成电脑检查和 Windows 更新，然后才能安装。
install-security-title = 安装前请检查防病毒保护
install-security-reading = 正在再次检查四个防护开关。
install-security-message = { $summary }。安装前，请打开 Windows 安全中心，确认四个开关均已关闭。
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
summary-copy-command-a11y = 复制安装命令
summary-command-unavailable = 无法准备安装命令。详细信息：{ $error }
summary-not-chosen = 尚未选择
# “更改”链接的辅助功能名称。$title 为 screen-*-title 消息之一。
summary-change-a11y = 更改“{ $title }”
footer-still-checking = 正在为安装做准备
footer-fix-items = 请处理“电脑检查”中的项目以继续
footer-need-package = 请下载 Atlas 或打开 Atlas 安装包以继续
# footer-need-package 的测试版变体。
footer-need-package-bundled = 请准备内置的 Atlas 安装包以继续
footer-reading-security = 正在检查防护开关
footer-security-pending = 请关闭全部四个开关以继续
footer-security-confirm = 要继续，请确认 Atlas 无法读取的开关
footer-install-ready = 请先保存工作并关闭其他应用
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
installing-restart-auto = 安装完成后，电脑会自动重启。请在此之前保存其他应用中的工作。

## 重启后的“Atlas 已安装”窗口

installed-title-version = Atlas { $version } 已安装
installed-title = Atlas 已安装
installed-ready = 一切就绪。你的电脑现在可以使用 Atlas 了。
installed-security-message = 你保留了 Microsoft Defender，但它的部分防护仍处于关闭状态。请打开 Windows 安全中心，确保以下各项已开启：{ $switches }。
installed-defender-removed-title = 已移除 Microsoft Defender
installed-defender-removed-message = 在你安装其他防病毒软件之前，电脑将没有防病毒保护。SmartScreen 也已被移除，因此打开无法识别的应用或下载的文件前，Windows 不会发出警告。
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = 你选择了保留 Microsoft Defender，但这台电脑上找不到它。如果你没有使用其他防病毒软件，请安装一款防病毒软件来保护电脑。如果 Defender 不是你自己移除的，请选择“报告问题”。

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
settings-language-system-selected = { settings-language-system }（{ $language }）
# “跟随 Windows”下方：由此得到的语言。$language 为该语言的本地名称。
settings-language-system-detail = 跟随 Windows 时使用：{ $language }
# 每种已翻译但尚未经母语者审校的语言下方显示的简短标签。
settings-language-preview-tag = 预览版
# 语言列表下方显示一次，用于解释“预览版”标签。
settings-language-preview-note = 预览版翻译尚未经过母语人士审校。
preview-notice = { $language }是预览版翻译，可能存在错误。
preview-notice-switch = 切换到英文
preview-notice-language = 更改语言
# $tag 为语言标记（文本）。
settings-language-unavailable = 此版本的 Atlas 不提供 { $tag }。暂时显示英语，你的语言选择已保存。
# $languages 为 Windows 显示语言列表（文本）。
settings-language-windows-unmatched = Atlas 尚不支持你的 Windows 显示语言（{ $languages }）。暂时显示英语。
settings-language-windows-unavailable = 无法检查你的 Windows 显示语言。Atlas 暂时使用英语。详细信息：{ $error }
# $locale 为区域格式的本地名称，例如“中文(简体，中国)”。
settings-language-formats = 数字、日期和时间遵循你的 Windows 区域格式（{ $locale }）。
# Windows 区域格式从右到左书写日期或时间时，代替 settings-language-formats 显示。
# $locale 为该格式的英文名称，例如“Arabic (Saudi Arabia)”。
settings-language-formats-numbers-only = 数字遵循你的 Windows 区域格式（{ $locale }）。由于 Atlas 暂时无法显示从右到左的文字，日期和时间使用标准格式。
settings-language-contribute = 在 GitHub 上帮助翻译 Atlas
settings-restart-label = 安装完成后自动重启电脑
settings-restart-locked = 安装完成后才能更改此设置。
settings-restart-description = 开启此项后，电脑会在安装完成后一分钟内重启，这会关闭你打开的应用。请在安装前保存工作。
settings-help = 帮助和反馈
settings-about = 关于
settings-about-app = Atlas Manager
settings-about-licence = 许可证
settings-about-licence-value = GPL-3.0，自由开源
settings-view-source = 在 GitHub 上查看源代码
# 打开第三方许可证声明的链接。
settings-view-licences = 查看许可证声明
# Windows 无法打开许可证声明时，显示在链接下方。
settings-licences-failed = 无法打开许可证声明。请重试，或在 GitHub 上的源代码中查找。
settings-open-data-folder = 打开应用文件夹

## 可选项：选择前显示的说明。

consequence-disable-hibernation = 释放休眠时用于保存会话的磁盘空间。休眠和快速启动将不可用。
consequence-disable-power-saving = 关闭节能功能。电脑可能更耗电、温度更高，电池续航也可能变短。
consequence-disable-core-isolation = 关闭 Windows 的一层额外安全防护，包括内存完整性。这会降低防护，并可能影响需要此功能的应用或游戏。
consequence-remove-snipping-tool = 卸载用于截屏和录屏的 Windows 应用。
consequence-uninstall-edge = 卸载 Microsoft Edge 浏览器。请确保已有其他浏览器，或在下方选择一个。
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = 卸载 Microsoft Edge，并删除这台电脑上的 Edge 收藏夹、历史记录和已保存的密码。未同步到 Microsoft 账户的内容都会丢失。请确保已有其他浏览器，或在下方选择一个。
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = 将删除这台电脑上的 Edge 收藏夹、历史记录和已保存的密码。
consequence-install-another-browser = 在下方选择一款浏览器，Atlas 会为你安装。
consequence-install-toolbox = 添加 Atlas Toolbox，方便管理 Atlas 设置。Toolbox 目前处于测试阶段，部分功能可能尚未完善。
consequence-install-eclean = AtlasOS 团队打造的维护工具，帮助你在设置完成后保持电脑整洁。检查垃圾文件和启动应用。需要账户和 Internet 连接。

# 主页上安装 Atlas 之前显示的简介。
home-intro = Atlas 会调整 Windows，减少后台活动和干扰。请在全新安装 Windows 后、添加自己的应用和文件之前安装 Atlas。

## ISO creation (Beta)
iso-home-title = Windows 安装介质
iso-home-description = 创建包含 Atlas 的 Windows 安装映像 (ISO)，然后用它在这台电脑或其他电脑上重新安装 Windows。
iso-open = 创建 Atlas ISO
iso-title = 创建 Atlas ISO
iso-beta = 测试版
iso-beta-description = 在电脑上使用前，请先在虚拟机中测试 ISO。安装 Windows 前，请备份文件。
iso-admin-description = Atlas 需要管理员权限才能读取你的 Windows ISO 并创建新的 ISO。请选择“以管理员身份重新打开”，然后在 Windows 询问时选择“是”。
iso-files-description = Atlas 会复制一份 Windows 11 ISO 并在其中加入 Atlas，用于重新安装 Windows。请选择从 Microsoft 下载的 Windows 11 ISO，下载最新的 Atlas 安装包或选择已有的安装包 (.apbx)，然后选择新 ISO 的保存位置。
# 测试版：没有安装包选择器。
iso-files-description-bundled = Atlas 会复制一份 Windows 11 ISO，并在其中加入此测试版内置的 Atlas 安装包。请选择从 Microsoft 下载的 Windows 11 ISO，然后选择新 ISO 的保存位置。
iso-source = Windows ISO
iso-source-download = 从 Microsoft 下载 Windows 11
# $minimum 为可使用的最低 Atlas 版本（文本，例如 0.6.0）。
iso-package = Atlas 安装包（{ $minimum } 或更高版本）
iso-output = 新 ISO 的保存位置
iso-no-file = 尚未选择文件
iso-browse = 浏览
iso-save-as = 另存为
# 文件字段旁“浏览”或“另存为”按钮的辅助功能名称：$action 为按钮文字，$field 为字段标签。
iso-pick-a11y = { $action }：{ $field }
iso-inspect = 检查文件
iso-mode-title = 你想如何设置 Atlas？
iso-mode-interactive = 登录后做出 Atlas 选择
iso-mode-interactive-description = 登录后，Atlas 会打开并引导你完成更新、做出选择并安装 Atlas。
iso-mode-before = 现在做出 Atlas 选择
iso-mode-before-description = Atlas 会将你的选择保存到 ISO 中。登录后，Atlas 会打开并引导你完成更新，然后你按这些选择安装 Atlas。
iso-package-unsupported-title = 请选择较新的 Atlas 安装包
# “登录后做出 Atlas 选择”即 iso-mode-interactive。
iso-package-unsupported = 此 Atlas 安装包无法将 Atlas 选择保存到 ISO 中。请选择较新的安装包，或选择“登录后做出 Atlas 选择”。
# “检查文件”拒绝该 Atlas 安装包时显示；$minimum 与 iso-package 中的相同。
iso-failed-package-unsupported = 此 Atlas 安装包无法用于创建 ISO。请选择适用于 Atlas { $minimum } 或更高版本的安装包。
# 测试版：内置的 Atlas 安装包无法更换，因此只能选择“登录后做出 Atlas 选择”模式。
iso-package-unsupported-bundled-title = 无法将 Atlas 选择保存到此 ISO 中
# “登录后做出 Atlas 选择”即 iso-mode-interactive。
iso-package-unsupported-bundled = 此测试版内置的 Atlas 安装包不支持 ISO 设置。请改为选择“登录后做出 Atlas 选择”。
iso-atlas-options = Atlas 选择
iso-review = 检查 ISO 配置
iso-review-description = 创建 ISO 不会在这台电脑上安装任何内容，也不会更改原始 ISO。之后，Atlas 可以将新 ISO 写入 U 盘，以便你用它重新安装 Windows。
iso-review-files = 文件
iso-step-windows = Windows 安装设置
iso-step-review = 检查
iso-review-package = Atlas 安装包
iso-review-output = 新 ISO
iso-review-editions = 版本
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# 文件大小；$size 为格式化后的数字（文本）。小于 1 GB 时以 MB 显示。
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = 账户名
iso-review-target = 安装到
iso-review-drivers = 驱动程序
iso-create = 创建 ISO
iso-progress-title = 正在创建 ISO
iso-stage-inspect = 正在检查 Windows ISO
iso-stage-copy = 正在复制 Windows 文件
iso-stage-add-atlas = 正在添加 Atlas
iso-stage-master = 正在写入 ISO 文件
iso-stage-verify = 正在检查新 ISO
iso-stage-cleanup = 正在完成最后步骤
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }，{ $status }
iso-stage-status-current = 进行中
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = 失败
iso-stage-status-not-started = 未开始
iso-progress-description = 请保持 Atlas 打开。处理较大的映像可能需要一些时间。
iso-cancel = 取消创建
iso-cancelling = 正在等待安全的取消时机
iso-cancelled = 已取消创建 ISO
iso-cancelled-description = 原始 ISO 未被更改。如果留下了临时文件，请选择“打开日志文件夹”查看它们的位置。
iso-complete = ISO 已准备就绪
iso-complete-description = ISO 创建功能仍处于测试阶段，因此请先在虚拟机中测试此 ISO。然后选择“创建安装 U 盘”，并在重新安装 Windows 前备份文件。
iso-open-folder = 在文件夹中显示
iso-failed = 未能完成 ISO 创建
iso-failed-description = 请确保文件仍在你选择的位置，并且保存位置所在的驱动器已连接，然后选择“创建 ISO”。如果仍然失败，请选择“发送报告”。
# “检查文件”步骤失败时的标题；下方的消息说明原因。
iso-check-failed = 无法检查文件
iso-check-failed-description = 请确保 ISO 和 Atlas 安装包仍在你选择的位置，并且已下载完成，然后选择“检查文件”。如果仍然失败，请选择“发送报告”。
# 请求管理员权限的消息栏标题。消息为 iso-admin-description；Windows 拒绝以管理员身份重新打开（UAC 被拒绝）后为 elevation-declined。
iso-elevation-title = Atlas 需要权限才能创建 ISO
# 映像处理进程报告的具体原因。
iso-failed-output-exists = 已存在同名文件。请选择“另存为”并输入新的文件名。
iso-failed-destination = Atlas 无法将新 ISO 保存到该位置。请选择“另存为”，然后选择这台电脑上的文件夹，例如“下载”。不能使用网络位置，也不能使用格式化为 FAT32 或 exFAT 的驱动器（许多 U 盘都是这种格式）。
iso-failed-space = 目标驱动器的可用空间不足。请释放空间，或将新 ISO 保存到其他驱动器。
# 家庭版和 LTSC 是创建 ISO 时会剔除的版本；其他为会保留的版本示例。版本名称与简体中文版 Windows 显示的一致。
iso-failed-edition = 此 ISO 不包含受支持的 Windows 版本。不支持 Windows 家庭版和 LTSC 版本。请使用包含其他版本（例如专业版、教育版或企业版）的 ISO。
iso-failed-customised = 此 ISO 已包含自定义安装文件（例如 autounattend.xml）。请选择 Microsoft 提供的未经修改的 Windows ISO。
iso-failed-windows-unsupported = Atlas 安装包不支持此 Windows 映像。请使用未经修改的 64 位 Windows 11 ISO，且其版本须受此安装包支持。
iso-failed-network-architecture = 这台电脑的网卡驱动程序与此 ISO 的体系结构不匹配。请返回并取消勾选“包含这台电脑的网卡驱动程序”，或选择适用于这台电脑的 ISO。
iso-failed-unstaged = Atlas 无法准备其工作文件夹，因此未做任何更改。请重试。如果仍然失败，请选择“导出诊断信息”并附在错误报告中。
iso-failed-package-changed = 检查文件后，Atlas 安装包已更改。请选择“文件”旁的“更改”，然后选择“检查文件”。
iso-diagnostics = 打开日志文件夹
iso-close-title = ISO 仍在创建中
iso-close-message = 请保持此窗口打开，直到创建或取消完成。取消操作会等待当前步骤可以安全停止后再执行。
iso-keep-open = 保持打开
prepare-title = 更新 Windows 和商店应用
prepare-description = 安装前，Atlas 会更新 Windows、Microsoft Store 和你的商店应用。已打开的商店应用（例如记事本、画图或 Windows 终端）可能会在更新时关闭，因此请先保存其中的工作。电脑也可能需要重启。
prepare-complete = Atlas 未发现其他需要安装的 Windows 或商店更新。
prepare-reboot-title = 重启电脑以继续
prepare-reboot = 电脑需要重启才能完成更新的安装。Atlas 会保存你目前的选择，并在你登录后重新打开。
# $reasons：Windows 设置的待重启标记，取自 prepare-reason-* 各项名称。
prepare-reboot-reasons = 电脑需要重启才能完成更新的安装（{ $reasons }）。Atlas 会保存你目前的选择，并在你登录后重新打开。
# 显示在重启消息下方：该按钮会立即重启 Windows，没有倒计时。
prepare-reboot-save-work = 请先保存工作并关闭其他应用。选择“重启并继续”后，电脑会立即重启。
# 刚重启后 Windows 又要求重启时显示，代替再次重启。
prepare-restart-persists = 电脑已重启，但 Windows 仍提示需要重启（{ $reasons }），因此再次重启可能没有帮助。请选择“打开 Windows 更新”，完成其中所有等待中的项目，然后选择“重试”。如果没有等待中的项目，请选择“发送报告”。
# Windows 需要重启时所设置标记的名称。它们用于补全“Windows 需要重启（…）”；
# 请保持简短。
prepare-reason-servicing = Windows 组件服务
prepare-reason-windows-update = Windows 更新
prepare-reason-file-renames = 等待替换的文件
prepare-reason-update-agent = Windows 更新服务
prepare-reason-unknown = 未报告原因
prepare-failed = 请选择“重试”。如果再次失败，请在 Windows 更新或 Microsoft Store 中完成剩余的更新，或选择“发送报告”。
prepare-failed-title = 部分更新未能完成
# 更新运行结束但没有写入任何结果，例如在运行期间关闭了 Atlas。“重试”即 common-try-again，是旁边的按钮。
prepare-ended-unconfirmed = 更新在报告结果之前已停止，因此 Atlas 无法确认 Windows 和商店应用均已更新到最新版本。请选择“重试”来检查更新。
prepare-unconfirmed-title = 无法确认更新结果
# “检查并安装更新”即 prepare-start，是该状态下的按钮。
prepare-cancelled = 更新已停止，部分更新可能已经安装。请选择“检查并安装更新”完成剩余更新，然后再继续。
prepare-windows-search = 正在检查 Windows 更新…
prepare-windows-download = 正在下载 Windows 更新…
prepare-windows-install = 正在安装 Windows 更新…
prepare-store-search = 正在检查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其应用…
prepare-stop-description = Atlas 会在当前步骤完成后停止更新。在此之前，请保持 Atlas 打开。
prepare-stop = 停止更新
prepare-restart = 重启并继续
prepare-start = 检查并安装更新
# 准备按钮不可用时显示在其下方。$check 为 check-supported-build 的标题。
prepare-blocked-source = 此安装无法继续，因此暂不可用。请查看页面顶部的消息。
# 更新按钮不可用时显示在其下方。$check 为必须先通过的检查项标题：check-supported-build 或 check-administrator。
prepare-needs-build-check = “电脑检查”中的“{ $check }”通过后即可使用。
# 安装文件仍在下载或解压时，显示在准备按钮和“安装权限”检查项下方。
prepare-wait-for-package = 安装文件就绪后即可使用。
iso-username = 本地账户名
iso-account-description = Windows 安装程序会用此名称创建本地账户，因此你不需要 Microsoft 账户。首次登录时，Windows 会要求你设置密码。
iso-username-placeholder = 你的名字
iso-account-empty = 请输入本地账户名以继续
iso-account-invalid = 最多可使用 20 个字符，开头和结尾不能有空格，且不能包含以下字符：" / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = 名称不能以句点 (.) 结尾。
iso-account-reserved = Windows 已将此名称用于内置账户。请选择其他名称。
iso-privacy-defaults = 此 ISO 会跳过 Windows 安装程序中的许可条款、Microsoft 账户和隐私设置页面，并关闭可选数据共享和个性化优惠。
prepare-drivers = 如何安装驱动程序？
prepare-drivers-auto = 通过 Windows 更新获取驱动程序
prepare-drivers-auto-detail = Windows 会为硬件查找驱动程序。推荐大多数电脑使用。
prepare-drivers-manual = 自行安装驱动程序
prepare-drivers-manual-detail = Windows 更新不会安装驱动程序，因此你需要从电脑或设备制造商处获取。已安装的驱动程序会保留。
prepare-drivers-description = 驱动程序让 Windows 能够使用你的硬件，例如显卡、声卡和 Wi-Fi。如果在更新后更改此项，Atlas 需要重新检查更新。
prepare-network-needed = 更新需要未设为按流量计费的 Internet 连接。请连接 Wi-Fi 或以太网，然后选择“重试”。如果看不到任何 Wi-Fi 网络，请先安装网卡驱动程序。
# 已连接，但 Windows 发现无法访问 Internet（强制登录门户，或 DNS、防火墙过滤）。
prepare-network-limited = Windows 报告此网络无法访问 Internet。如果网络要求登录，请先登录；或者检查路由器以及 DNS 或防火墙过滤设置，然后重试。
# “按流量计费的连接”是 Windows 网络设置中开关的名称。
prepare-network-metered = 此连接按流量计费或设置了数据限制。请连接未设为按流量计费的网络，或在网络设置中关闭“按流量计费的连接”，然后重试。
prepare-network-settings = 打开网络设置
iso-target-title = 要在哪台电脑上重新安装 Windows？
iso-target-this = 这台电脑
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas 可以将这台电脑的 Wi-Fi 和以太网驱动程序添加到 ISO 中，让 Windows 重新安装后可以立即联网。
iso-target-other = 另一台电脑
iso-copy-network = 包含这台电脑的网卡驱动程序
iso-network-detail = 安装 Windows 时复用这台电脑的 Wi-Fi 和以太网驱动程序。重装后需要重新连接 Wi-Fi。
iso-network-source = 网卡驱动程序来源
iso-network-installed = 使用已安装的驱动程序
iso-network-updated = 先检查 Windows 更新
iso-network-updated-detail = 下载 Windows 更新提供的匹配驱动程序，同时保留已安装的驱动程序作为备用。需要未设为按流量计费的连接。
iso-stage-network-drivers = 正在准备网卡驱动程序
iso-network-failed = 无法准备网卡驱动程序。请查看诊断信息，或返回并更改网卡驱动程序选项。
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = 这台电脑的网卡使用 Windows 自带的驱动程序，因此 ISO 无需包含它们。
iso-mode-desktop = 进入桌面前完成设置
iso-mode-desktop-description = Atlas 会将你的选择保存到 ISO 中。登录后，Atlas 会在 Windows 桌面打开前完成更新和安装。
desktop-setup-description = 请完成电脑设置。你的 Atlas 选择已保存，需要时可以返回 Windows。
desktop-setup-exit = 在 Windows 中继续

# Windows installation USB (Beta)
usb-title = 创建安装 U 盘
usb-existing = 使用现有 ISO 创建 U 盘
usb-description = 将 ISO 写入 U 盘，以便用它重新安装 Windows。使用 Atlas 创建的 ISO 可以同时安装 Atlas。
usb-choose-iso = 选择 ISO
usb-drive = USB 驱动器
# $min 和 $max 为格式化后的数字（文本），单位分别为 GB 和 TB。
usb-empty = 未找到 USB 驱动器。请连接容量至少为 { $min } GB 的 USB 驱动器，然后选择“刷新”。容量大于 { $max } TB 的驱动器、只读驱动器以及正在运行 Windows 的驱动器不会显示。
usb-refresh = 刷新
# 无法读取驱动器列表时显示。
usb-scan-failed = 请检查驱动器是否已连接，然后选择“刷新”。如需了解详情，请选择“打开日志文件夹”。
usb-scan-failed-title = 无法列出 USB 驱动器
# 驱动器详情行的各部分，以 usb-detail-separator 连接；空的部分会省略。
# $size 为格式化后的 GB 数（文本）；$volumes 和 $serial 为文本。
usb-drive-size = { $size } GB
usb-drive-serial = 序列号：{ $serial }
usb-detail-separator = { " · " }
usb-review = 检查 U 盘
usb-erase-title = 要清空此 USB 驱动器吗？
usb-erase-description = { $drive }（{ $size } GB）上的所有内容都将被永久删除，包括所有文件和分区。请先将要保留的内容复制到其他驱动器。你的 ISO 会保留。
usb-layout = Atlas 最多使用该驱动器的 32 GB，其余空间保持未使用。此 U 盘适用于以 UEFI 模式启动的电脑，这也是 Windows 11 的要求。
usb-ack = 我了解此 USB 驱动器上的所有内容都将被删除
usb-write = 清空并创建 U 盘
usb-stage-prepare = 正在准备安装文件…
usb-stage-format = 正在格式化 U 盘…
usb-stage-copy = 正在复制安装文件…
usb-stage-verify = 正在验证 U 盘…
usb-working = 请保持 Atlas 打开，并保持 U 盘连接。如果取消，未完成的 U 盘将无法用于安装 Windows。
# 写入 U 盘期间错误栏、成功栏和关闭提示的标题。
usb-failed-title = 无法完成 U 盘创建
usb-complete-title = U 盘已准备就绪
usb-close-title = U 盘仍在创建中
# 可能已开始清空驱动器之后。
usb-failed = 驱动器可能已被清空，因此暂时无法用于安装 Windows。请确保它已连接，然后选择“检查 U 盘”重试。如果你重新连接过它，请先选择“刷新”，然后重新选择该驱动器。
# 驱动器尚未发生任何更改之前：先是一般情况，然后是写入进程报告的具体原因。
usb-failed-unchanged = 你的 USB 驱动器未被更改。请选择“打开日志文件夹”查看失败原因，然后选择“检查 U 盘”重试。
usb-failed-iso = 此 ISO 无法用于创建安装 U 盘。请选择由 Atlas 创建的 ISO，或从 Microsoft 获取的、Atlas 支持版本的 Windows 11 ISO。你的 USB 驱动器未被更改。
usb-failed-location = ISO 或 Atlas Manager 位于此 USB 驱动器、网络位置或链接文件夹中。请将其移到这台电脑上的本地文件夹，然后重试。你的 USB 驱动器未被更改。
usb-failed-space = Windows 所在驱动器的可用空间不足，无法准备安装文件。请释放空间，然后重试。你的 USB 驱动器未被更改。
usb-failed-fit = 此 USB 驱动器容量不足，无法容纳安装文件。请使用容量更大的驱动器，然后重试。你的 USB 驱动器未被更改。
usb-failed-drive-changed = 读取列表后，USB 驱动器已被移除、重新连接或更换。请选择“刷新”，重新选择该驱动器，然后选择“检查 U 盘”。你的 USB 驱动器未被更改。
usb-cancelled = 驱动器上可能存在不完整的安装文件。请重新创建后再用于安装 Windows。
usb-cancelled-title = 已取消创建 U 盘
usb-cancelled-unchanged = 你的 USB 驱动器未被更改。
usb-complete = Atlas 已检查所有文件。请选择“弹出 U 盘”，然后备份要重装系统的电脑上的文件。将 U 盘插入该电脑，然后通过其启动菜单从 U 盘启动（通常在电脑启动时按 F12、F11 或 Esc）。
usb-eject = 弹出 U 盘
usb-ejected = 现在可以拔出 U 盘了。请备份要重装系统的电脑上的文件，然后通过该电脑的启动菜单从 U 盘启动（通常在电脑启动时按 F12、F11 或 Esc）。
usb-eject-failed = 请关闭正在使用该 U 盘的文件或窗口，然后重试。
usb-eject-failed-title = 无法弹出 U 盘
ready-fresh-title = Atlas 适用于全新安装的 Windows
ready-fresh-description = 如果你已经在这台电脑上使用过 Windows，请先备份文件并重新安装 Windows，然后再继续。重新安装前，请先确认“电脑检查”中的“Windows 兼容性”已通过，以确保重新安装的是受支持的版本。
# 家庭版、LTSC 和 Server 是检查会拒绝的版本；其他为检查接受的版本示例。版本名称与简体中文版 Windows 显示的一致。
detail-edition-unsupported = 不支持 Windows 11 家庭版、LTSC 和 Server 版本。请使用其他版本，例如专业版、教育版或企业版。如果 Windows 无法识别你的版本，请先解决此问题再继续。
install-source-title = 无法安装
install-source-unsupported = Atlas { $source } 无法直接更新到 { $target }。要使用此版本，请备份文件并重新安装 Windows。
# 尚未选择安装包，因此还不知道可用的版本。
install-source-unsupported-any = Atlas { $source } 无法直接更新。要使用较新的版本，请备份文件并重新安装 Windows。
# “打开安装包文件”即 package-open-file。$folder 为文件夹路径（文本）。
install-source-resume = Atlas { $target } 的安装未完成，只有 Atlas { $target } 安装包才能完成该安装。请选择“打开安装包文件”，然后选择该 Atlas 安装包 (.apbx)。如果它是由 Atlas 下载的，则位于 { $folder } 中。
# 测试版：只能安装内置的 Atlas 安装包。
install-source-resume-bundled = Atlas { $target } 的安装未完成。此测试版只能安装其内置的 Atlas 安装包，因此请在 Atlas Manager 正式版中使用 Atlas { $target } 安装包完成该安装。
install-source-unknown = Atlas 无法确认这台电脑上已安装了什么，因此暂时不会安装任何内容。请选择“发送报告”，以便 Atlas 团队提供帮助。
# $problem 为 install-source-* 消息之一；$error 为原始错误消息（文本）。
install-source-details = { $problem }详细信息：{ $error }
iso-edition-selection = 仅包含受支持的版本。安装 Windows 时，请选择你拥有 Windows 许可证的版本。
detail-windows-preview = 不支持 Insider 预览版本。请使用 Windows 11 的正式发布版本。
detail-windows-release-unknown = Atlas 无法确认此 Windows 内部版本是否已正式发布。请连接 Internet 后重新检查。
iso-release-unknown = Atlas 无法确认此 ISO 是否为 Atlas 安装包支持的 Windows 11 正式发布版本。请连接 Internet，然后再次选择“检查文件”。如果仍然失败，请从 Microsoft 重新下载 ISO。
prepare-previous-worker = 之前开始的更新仍在运行。Atlas 会等待它们完成，之后你可以再次检查更新。

ready-used-windows-title = 这台电脑上的 Windows 似乎已被使用过
ready-used-windows-description = 这台电脑上的 Windows 至少在一周前就已安装，或者已经装有多个应用。在此安装 Atlas 不受支持，强烈不建议这样做：你已有的应用和设置可能无法按预期工作；Atlas 还会移除 OneDrive，因此其中的文件将停止同步，你的“桌面”“文档”和“图片”文件夹可能会显示为空。请先备份文件并重新安装 Windows；只有在你接受这些风险时才继续。
ready-used-windows-dismiss = 仍要继续

prepare-resumed = 电脑已重启，Atlas 已恢复你目前的选择。请选择“继续更新”完成更新，然后再安装 Atlas。
prepare-continue = 继续更新
prepare-saving-restart = 正在保存你的选择，并设置在 Windows 重新启动后打开 Atlas…
prepare-restart-save-failed = 无法保存你的选择。请在重新启动前重试。
prepare-restart-registration-failed = 你的选择已保存，但 Atlas 无法设置为在重启后重新打开。请重试，或自行重启电脑，并在登录后打开 Atlas。
prepare-restart-failed = Atlas 无法重启电脑。请重试，或从“开始”菜单重启。你的选择已保存，登录后 Atlas 会重新打开。
diagnostics-export = 导出诊断信息
diagnostics-exporting = 正在收集诊断信息…
diagnostics-privacy = 你可以将报告私密发送给 Atlas 团队，或导出诊断 ZIP，在求助时分享。Atlas 会从中删除你的用户名、电脑名称和电子邮件地址。
# 导出后结果栏的标题；其按钮为 iso-open-folder。
diagnostics-saved = 已创建诊断 ZIP
diagnostics-failed-title = 无法导出诊断信息
# $error 为原始错误（文本）。
diagnostics-failed = 请确认电脑有足够的可用磁盘空间，然后重试。详细信息：{ $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Atlas { $release } 测试版。此应用只安装内置的 Atlas 安装包。
home-status-bundled = 测试版 { $release }
package-bundled = 此测试版内置的 Atlas { $version } 已就绪，可以安装。
rc-about-release = 测试版
rc-about-commit = 源代码提交
rc-about-package = 内置 Atlas 安装包 (SHA-256)
iso-package-bundled = 此测试版内置的 Atlas 安装包
prepare-percent = 此阶段已完成 { $percent }%
prepare-count = 已完成的更新：{ $completed } / { $total }
prepare-bytes = 已下载 { $downloaded } MB，总量约 { $total } MB
prepare-elapsed = 已用时间：{ $minutes } 分 { $seconds } 秒
prepare-progress-waiting = 正在等待更新服务。此步骤暂无进度百分比。
prepare-progress-unchanged = 已有 { $minutes } 分钟没有进度更新。大型更新可能需要较长时间，请保持 Atlas 打开。如需了解详情，请选择“打开日志文件夹”。
prepare-report-delayed = Windows 已有 { $seconds } 秒未报告进度。更新可能仍在运行，请保持 Atlas 打开。

prepare-affected-app = 受影响的应用
prepare-app-in-use = 请关闭 { $app }，然后重试。应用处于打开状态时，Windows 无法更新它。如果找不到它的窗口，请在任务管理器中关闭它。如果仍然失败，请重启电脑，并在打开 { $app } 之前重试。
prepare-install-busy = 其他安装或待完成的重启阻止了更新。请等待其他安装完成，如果 Windows 要求重启，请重启电脑，然后重试。
# 更新进程报告的原因。进程自己的英文消息会作为详细信息显示在下方。
prepare-failed-session-owner = Atlas 正在以与当前 Windows 登录账户不同的账户运行。请使用管理员账户登录 Windows，从该账户打开 Atlas，然后重试。
prepare-failed-store-missing = 你的账户尚未设置好 Microsoft Store。请打开一次 Microsoft Store（如果找不到，请重新安装），然后重试。
prepare-failed-store-battery = Microsoft Store 为节省电量暂停了更新。请将电脑接通电源，然后重试。
prepare-failed-store-network = Microsoft Store 已暂停更新，需等电脑使用未设为按流量计费的连接后才会继续。请连接未设为按流量计费的 Wi-Fi 或以太网，然后重试。
prepare-failed-store-timeout = 商店应用尚未完成更新。请在 Microsoft Store 中完成剩余的下载，然后重试。
prepare-failed-store-passes = Microsoft Store 不断提供新的更新。请在 Microsoft Store 中完成剩余的更新，然后重试。
prepare-failed-manual-updates = 部分更新需要在 Windows 更新中完成。请打开 Windows 更新，完成这些更新，然后重试。
prepare-failed-windows-passes = Windows 更新不断提供新的更新。请在 Windows 更新中完成剩余的更新，然后重试。
prepare-error-code = 错误代码：{ $code }
prepare-open-store = 打开 Microsoft Store

check-user-account = 用户账户
detail-user-account-ok = UAC 已启用，你的账户已准备好进行安装。
detail-user-account-not-ready = 请启用用户账户控制 (UAC)，重启电脑后再试。如果你使用的是内置 Administrator 账户，请使用另一个管理员账户登录。
detail-user-account-unknown = Atlas 无法检查你的用户账户。请在安装前重新检查。Windows 报告：{ $error }

footer-prepare-required = 请完成 Windows 和商店应用的更新以继续
footer-prepare-stopping = 将在当前步骤完成后停止更新…
resume-choices-title = 继续上次安装
resume-choices-detail = 为完成上次的安装，Atlas 已恢复你上次做出的选择。在安装完成之前，无法在“你的选择”中更改它们。

## Voluntary reports
report-title = 发送报告
report-received = 报告已收到
report-reference = 如果你就此报告联系 Atlas 团队，请保留此参考编号。如果你留下了联系方式，团队可能会通过它回复你，但不保证一定回复。
# 参考编号旁“复制”按钮的辅助功能名称。
report-copy-reference = 复制报告参考编号
report-another = 再发送一份报告
# 在两类报告之间进行选择的标签。
report-kind = 你想发送哪类内容？
report-kind-issue = 问题
report-kind-suggestion = 建议
# $min 和 $max 为数字：报告服务接受的消息长度。
report-intro = 描述发生了什么，或你希望改进什么（{ $min }–{ $max } 个字符）。请勿在消息中包含密码。
report-message = 你的消息
report-message-placeholder = 我当时想要…
report-contact = 联系方式（可选）
report-contact-placeholder = 电子邮箱或 Discord 用户名
report-attach = 附加诊断信息
report-attach-description = 有助于查找原因的日志和系统详细信息。Atlas 会删除你的用户名、电脑名称、电子邮件地址以及已知的密码或密钥。错误详细信息、硬件型号和应用名称会保留。发送前，你可以检查 ZIP。
report-prepare = 准备诊断信息
report-review = 检查 ZIP
report-prepare-failed-title = 无法准备诊断信息
# $error 为原始错误消息（文本）。
report-prepare-failed = 请重新准备诊断信息，或关闭“附加诊断信息”，在不附带诊断信息的情况下发送报告。详细信息：{ $error }
report-privacy = 你的报告会私密发送给 reports.atlasos.net 上的 Atlas 团队。你的消息和联系方式会按原样发送。团队可能会使用其他公司的 AI 服务协助调查。这些服务会获得你的消息和诊断信息，但不会获得你的联系方式。报告会在 90 天后删除，服务器安全日志可能会记录你的 IP 地址。
report-website = 隐私与报告网站
report-consent = 我同意将此报告及附带的诊断信息发送给 Atlas 团队
report-failed = 你的消息仍保留在这里。请检查 Internet 连接，然后选择“重试”，或通过报告网站发送报告。
report-failed-busy = 报告服务繁忙。你的消息仍保留在这里。请稍后重试。
report-failed-outdated = 此版本的 Atlas Manager 已无法发送报告。你的消息仍保留在这里，请将其复制到报告网站。如果你附加了诊断信息，请选择“检查 ZIP”，并将 ZIP 也附加到网站上。
report-failed-diagnostics = 无法发送已准备的诊断信息。你的消息仍保留在这里。请重新准备诊断信息，或关闭“附加诊断信息”。
# 未发送的报告下方的链接。
report-failed-website = 打开报告网站
report-sending = 正在发送…
report-send = 发送报告

# $min 和 $max 为数字：报告服务接受的消息长度。
report-validation-message = 请输入 { $min }–{ $max } 个字符。

# $max 为数字：报告服务接受的联系信息最大长度。
report-validation-contact = 请将联系信息限制在 { $max } 个字符以内。

report-validation-consent = 请确认你同意发送此报告。

report-failed-title = 报告未发送

## Windows version update
home-plan-intro = 此次更新分为两部分。你的文件和应用都会保留。如果更新 Windows 撤销了 Atlas 的部分更改，Atlas 会重新应用这些更改。
home-plan-windows-title = Windows 11 版本 { $release }
home-plan-windows-detail = Atlas 会通过 Windows 更新安装此版本。电脑需要重启才能完成安装。
home-plan-windows-optional = 推荐。Atlas 会通过 Windows 更新安装此版本。电脑需要重启才能完成安装。
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas 会更新其文件，并保留你做出的选择。最后电脑会重启。
home-end-of-updates-title = Windows 11 版本 { $current } 将于 { $date } 停止获得安全更新
home-end-of-updates-past-title = Windows 11 版本 { $current } 已不再获得安全更新
home-end-of-updates-message = 更新到 Atlas { $version } 时，这台电脑也会更新到 Windows 11 版本 { $release }，该版本的安全更新将持续到 { $until }。
install-windows-edition = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版。这台电脑使用的是 { $product }，因此无法安装 Atlas。
install-windows-edition-ending = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版。这台电脑使用的是 { $product }，因此无法安装 Atlas。Windows 11 版本 { $current } 将于 { $date } 停止获得安全更新。Windows 更新可以将这台电脑更新到较新的版本。
install-windows-no-path = Atlas { $version } 需要 Windows 11 版本 { $releases }，而 Windows 更新无法将这台电脑从当前的 Windows 更新到该版本。要使用 Atlas { $version }，请备份文件，然后使用 Atlas ISO 重新安装 Windows。
home-update-access-title = Windows 更新设置已因 Atlas 更新而更改
home-update-access-not-offered = Atlas 已开启 Windows 更新，以便将这台电脑更新到 Windows 11 版本 { $release }，但 Windows 更新尚未提供该版本。请选择“重新检查”或“还原设置”。
home-update-access-before = Atlas 已开启 Windows 更新，以便将这台电脑更新到 Windows 11 版本 { $release }，但尚未完成。请继续更新，或选择“还原设置”。
home-update-access-after = 这台电脑已是 Windows 11 版本 { $release }。请完成 Atlas 的安装，或选择“还原设置”。
home-update-access-plain = Atlas 已开启 Windows 更新来安装更新，但尚未完成。请继续更新，或选择“还原设置”。
home-update-access-unreadable = Atlas 无法读取它更改 Windows 更新设置时留下的记录，因此不会更改或还原任何设置。请选择“发送报告”，以便 Atlas 团队提供帮助。
home-update-access-failed = Atlas 无法还原这些设置。请重试，或选择“发送报告”。详细信息：{ $error }
home-update-access-install-active = 请先完成 Atlas 的安装。安装的最后一步会还原这些设置。
home-continue-update = 继续更新
home-put-back = 还原设置
home-putting-back = 正在还原设置…
windows-card-title = Windows 11 版本 { $release }
windows-card-required = Atlas { $version } 需要较新版本的 Windows。Atlas 在下方更新 Windows 时，还会通过 Windows 更新安装 Windows 11 版本 { $release }。
windows-card-question = 这台电脑应使用哪个版本的 Windows？
windows-choice-move = 更新到 Windows 11 版本 { $release }
windows-choice-move-detail = 推荐。安全更新持续到 { $date }。需要多重启一次。
windows-choice-keep = 保留 Windows 11 版本 { $current }
windows-choice-keep-detail = 电脑会保持在此版本。Windows 更新不会将其更新到较新的版本，因此以后若要更新版本，需要在 Atlas Manager 中再进行一次更新。
windows-card-facts = 会有哪些变化
windows-fact-keep = 你的文件和应用都会保留。如果更新撤销了 Atlas 的部分更改，Atlas 会在安装时重新应用这些更改。
windows-fact-restart = 电脑至少还要重启一次才能完成更新。
transition-offer-expectation = Windows 更新通常会在几分钟内提供该版本，但最长可能需要 2 小时；Atlas 会自动等待并检查。
windows-fact-stays = 之后，Windows 会保持在版本 { $release }，不会自行更新到较新的版本。
windows-fact-removed = 版本 { $release } 不包含 Windows PowerShell 2.0 和 WMIC 工具。
windows-card-undo = 如果之后要撤销，请在 Windows 更新的“更新历史记录”中卸载该更新。如果 Windows 是通过重新安装自身完成更新的，请改为在 10 天内前往“设置”>“系统”>“恢复”，选择“返回”。Atlas { $version } 不支持版本 { $current }，因此安装 Atlas { $version } 后请勿撤销。
windows-card-undo-optional = 如果之后要撤销，请在 Windows 更新的“更新历史记录”中卸载该更新。如果 Windows 是通过重新安装自身完成更新的，请改为在 10 天内前往“设置”>“系统”>“恢复”，选择“返回”。
windows-terms = 我接受适用于 Windows 11 版本 { $release } 的 Microsoft 软件许可条款
windows-terms-link = 阅读许可条款
windows-card-locked = 要保留版本 { $current }，请选择“取消”，然后选择“停止更新”。
prepare-description-transition = 安装前，Atlas 会先安装 Windows 正在等待安装的更新，然后安装 Windows 11 版本 { $release }，再更新 Microsoft Store 和你的商店应用。已打开的商店应用可能会在更新时关闭，因此请先保存其中的工作。电脑至少会重启一次。
prepare-start-transition = 将 Windows 更新到版本 { $release }
prepare-needs-terms = 在“Windows 11 版本 { $release }”中接受许可条款后即可使用。
ready-banner-not-offered-message = 请在“更新 Windows 和商店应用”中查看你现在可以采取的操作。
ready-banner-transition-failed-message = 请在“更新 Windows 和商店应用”中查看接下来该怎么做。
ready-banner-terms-title = 接受许可条款以继续
ready-banner-terms-message = 许可条款位于本页下方的“Windows 11 版本 { $release }”中。接受后，请选择“将 Windows 更新到版本 { $release }”。
access-notice-title = Atlas 会暂时开启 Windows 更新
access-off = 这台电脑上的 Windows 更新已关闭。Atlas 在更新 Windows 期间会将其重新开启。
access-paused = 这台电脑上的 Windows 更新已暂停。Atlas 在更新 Windows 期间会取消暂停。
access-delayed = 这台电脑上的每月更新已推迟。Atlas 在更新 Windows 期间会取消推迟。
access-back-chosen = Atlas { $version } 安装完成后，这些设置会改回你选择的状态。
access-back = Atlas { $version } 安装完成后，这些设置会改回原来的状态。
access-back-stop = 如果你在此之前停止，Atlas 会还原这些设置。
prepare-reboot-transition = Windows 11 版本 { $release } 已安装。请选择“重启并继续”以完成安装。登录后，Atlas 会重新打开。
prepare-reboot-commit = Windows 还需要重启一次才能完成版本 { $release } 的安装。登录后，Atlas 会重新打开。
prepare-restart-commit-failed = Windows 未能做好在重启时完成版本 { $release } 安装的准备，因此电脑没有重启。请选择“重启并继续”重试。
prepare-reason-feature-update = 新的 Windows 版本
prepare-reason-feature-commit = 完成新 Windows 版本的安装
prepare-resumed-transition = 电脑已重启。请选择“继续更新”，以便 Atlas 检查 Windows 11 版本 { $release } 是否已完成安装，并安装剩余的更新。
prepare-waiting-offer = 正在等待 Windows 更新提供 Windows 11 版本 { $release }。这通常需要几分钟，但最长可能需要 2 小时。你可以继续使用电脑，但请保持 Atlas 打开。
prepare-resumed-before-move = 电脑已重启以完成更新的安装。请选择“继续更新”，以便 Atlas 安装剩余的更新，然后安装 Windows 11 版本 { $release }。
prepare-not-offered-title = 正在等待 Windows 更新提供 Windows 11 版本 { $release }
prepare-transition-failed-title = Windows 无法更新到版本 { $release }
prepare-failed-feature-not-offered = Windows 更新可能需要一段时间才会向电脑提供 Windows 11 版本 { $release }。你的电脑仍是版本 { $current }。
prepare-offer-rechecking = Atlas 会每 10 分钟重新检查一次，一旦 Windows 更新提供该版本，就会自动继续。你也可以选择“重新检查”。
# 中文不区分单复数，因此不需要选择表达式。
prepare-offer-waited = 已等待 { $minutes } 分钟。
# 中文不区分单复数，因此不需要选择表达式。
prepare-offer-next-check = { $minutes } 分钟后再次检查。
prepare-offer-checking-now = 正在检查。
prepare-offer-check-again = 选择“重新检查”可立即检查。
prepare-offer-wait-ended-title = Windows 更新尚未提供 Windows 11 版本 { $release }
prepare-offer-wait-ended = Windows 更新在 2 小时内未提供 Windows 11 版本 { $release }，因此 Atlas 已停止等待，并还原了你的 Windows 更新设置。请稍后选择“重新检查”。如果你无法等待，请备份文件，然后使用 Atlas ISO 重新安装 Windows。
prepare-offer-wait-put-back-failed = Windows 更新在 2 小时内未提供 Windows 11 版本 { $release }，且 Atlas 无法还原你的 Windows 更新设置。请选择“还原设置”重试。详细信息：{ $error }
prepare-failed-feature-hardware = 这台电脑不满足 Windows 11 的硬件要求（{ $missing }），因此 Windows 更新不会将其更新到版本 { $release }。你的电脑仍是版本 { $current }。要使用 Atlas { $version }，请备份文件，然后使用 Atlas ISO 重新安装 Windows。
hardware-tpm = TPM 2.0
hardware-uefi = UEFI 固件
prepare-failed-feature-hidden = 在这台电脑上，Windows 11 版本 { $release } 已在 Windows 更新中被隐藏。请使用你隐藏它时所用的工具重新显示它，然后选择“重试”。
prepare-failed-feature-disk-space = Windows 需要驱动器 { $drive } 上至少有 { $needed } GB 可用空间才能进行此更新，而当前只有 { $free } GB。Atlas 未做任何更改。请释放空间，然后选择“重试”。
prepare-failed-feature-servicing = Windows 报告其组件存储已损坏且无法修复，因此 Atlas 未做任何更改。请修复 Windows，然后选择“重试”。
prepare-failed-feature-managed = 这台电脑从组织的更新服务器获取更新，因此 Atlas 无法将其更新到版本 { $release }。Atlas 未做任何更改。
prepare-failed-feature-policy = 在 Atlas 更改 { $setting } 后，这台电脑上的某项设置或程序不断将其改回，因此 Atlas 无法更新 Windows。如果这台电脑由组织管理，请联系该组织。你停止后，Atlas 会还原它所做的更改。
prepare-failed-feature-blocked = 一项并非由 Atlas 更改的设置阻止了 Windows 更新运行：{ $setting }。请更改此设置，让 Windows 更新可以运行，然后选择“重试”。
prepare-failed-feature-rolled-back = Windows 在重启期间无法完成版本 { $release } 的安装，已回退到版本 { $current }。你的文件和应用不受影响。请选择“重试”，或选择“发送报告”。
prepare-failed-feature-components-lost = Windows 更新后，Atlas 的部分更改已丢失，但没有迹象表明 Windows 重新安装了自身，因此 Atlas 无法判断发生了什么。Atlas { $version } 未安装。请选择“发送报告”，以便 Atlas 团队提供帮助。
prepare-failed-feature-build = 在 Atlas 更新 Windows 期间，这台电脑的 Windows 版本发生了变化。请选择“还原设置”，然后从“主页”重新开始。
prepare-failed-feature-journal = Atlas 无法读取它更改 Windows 更新设置时留下的记录，因此不会更改或还原任何设置。请选择“发送报告”，以便 Atlas 团队提供帮助。
prepare-failed-feature-pin = 这台电脑上的 Windows 更新策略 { $setting } 的值无法被 Atlas 记录，因此 Atlas 未做任何更改。请选择“发送报告”，以便 Atlas 团队提供帮助。
prepare-failed-feature-terms = 请接受适用于 Windows 11 版本 { $release } 的许可条款，然后选择“重试”。
prepare-failed-feature-failed = Windows 无法安装版本 { $release }。你的电脑仍是版本 { $current }。请选择“重试”。如果再次失败，请选择“发送报告”。
prepare-check-again = 重新检查
prepare-keep-version = 保留版本 { $current }
stop-update-title = 要停止更新到 Atlas { $version } 吗？
stop-update-before = Atlas 会还原它更改过的 Windows 更新设置。Windows 已安装的更新会保留，你的电脑仍使用 Windows 11 版本 { $current }。
stop-update-after = 你的电脑会保留 Windows 11 版本 { $release }。Atlas 会还原它更改过的 Windows 更新设置。
stop-update-access = Atlas 会还原它更改过的 Windows 更新设置。Windows 已安装的更新会保留。
stop-update-keep = 继续更新
window-close-update-access-title = 要关闭 Atlas 吗？
window-close-update-access-message = 关闭前，Atlas 会还原它更改过的 Windows 更新设置。你可以稍后从“主页”重新开始更新。
window-close-put-back = 还原并关闭
window-close-put-back-failed-title = 要在不还原设置的情况下关闭吗？
window-close-put-back-failed-message = 如果现在关闭 Atlas，Windows 更新设置会保持 Atlas 更改后的状态。重新打开 Atlas 后，“主页”会提供还原这些设置的选项。
installed-update-off-again = 已按你的选择重新关闭 Windows 更新。Windows 更新关闭期间，你的电脑不会获得安全更新。
installed-update-paused-again = 已按你的选择重新暂停 Windows 更新。暂停期间，你的电脑不会获得安全更新。
detail-build-transition = 这台电脑使用的是 Windows 11 版本 { $current }，此版本的 Atlas 不支持该版本。Atlas 在下方更新 Windows 时，会将 Windows 更新到版本 { $release }。
report-transition-intro = 为 Atlas 更新 Windows 的过程未完成。供 Atlas 团队参考的详细信息：
mode-rebase = Windows 更新后重新安装
history-mode-rebase = Windows 更新后重新安装
ready-rebase-title = Windows 在更新时重新安装了自身
ready-rebase-message = Windows 11 版本 { $release } 替换了这台电脑原有的 Windows，因此 Atlas 的部分更改已丢失。Atlas { $version } 会按你为 Atlas { $previous } 做出的选择重新应用这些更改。
upgrade-choices-title = 你在 Atlas { $previous } 中的选择
upgrade-choices-detail = Atlas 以 Atlas { $previous } 在这台电脑上的设置为起点。更新会保留这些选择已产生的效果，因此在此处取消勾选某个附加项并不会撤销它。之后若要更改，请使用 Atlas 文件夹或 Windows 设置。
rebase-choices-title = 你在 Atlas { $previous } 中的选择
rebase-choices-detail = Atlas 会沿用你为 Atlas { $previous } 做出的选择，因此此处无需选择。之后你可以在 Atlas 文件夹中更改它们。
rebase-choices-partial = Atlas 会沿用你为 Atlas { $previous } 做出的选择。以下选择未能找到，请检查：{ $missing }
restart-other-title = 另一位用户已登录这台电脑
restart-others-title = 其他用户已登录这台电脑
restart-others-message = 重启会关闭他们的应用，他们未保存的工作将会丢失。已登录：{ $names }。
restart-others-keep = 不重启
restart-others-restart = 仍要重启
prepare-store-self-update = 正在先更新 Microsoft Store。这台电脑上的 Microsoft Store 版本已过时。
prepare-store-repair = 正在修复 Microsoft Store。这可能需要几分钟。
prepare-store-updated = Microsoft Store 版本已过时，因此 Atlas 在更新你的应用之前先更新了它。
prepare-store-bootstrapped = Microsoft Store 无法自行更新，因此 Atlas 从 Microsoft 安装了最新的应用安装程序和 Microsoft Store。
prepare-store-repaired = Microsoft Store 无法正常工作，因此 Atlas 已将其修复。
prepare-store-skipped-removed = 这台电脑上的 Microsoft Store 已关闭，因此 Atlas 跳过了商店应用的更新。
prepare-failed-store-repair-failed = Microsoft Store 无法正常工作，Atlas 也无法修复它。请选择“修复 Microsoft Store”重试。如果仍然无法正常工作，请选择“发送报告”。
prepare-repair-store = 修复 Microsoft Store
