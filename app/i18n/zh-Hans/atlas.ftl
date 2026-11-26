### Atlas Manager: Chinese (Simplified) (zh-Hans), preview translation. Revised 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### 译者说明：
### - 称呼用户为“你”（与 Windows 11 简体中文界面一致），称呼计算机为“电脑”。
### - “重启”“重新启动”只用于电脑/Windows；重新打开 Atlas 应用一律说“重新打开”。
### - Windows 功能名称与简体中文版 Windows 保持一致，尤其是“病毒和威胁防护”设置
###   页中的四个开关：篡改防护、实时保护、云提供的保护、自动提交样本。
### - 中文与拉丁字母、数字之间留一个空格；中文语境使用全角标点，仅含拉丁字母的
###   括注（如 (.atlaspkg)、(VBS)）使用半角括号并前后留空格。
### - 变量可能是中文也可能是拉丁字母时（如开关名称、选择名称列表），尽量放在冒号之后，
###   避免空格问题。
### - 标记为“文本”的值（版本、内部版本号、路径、文件名、错误信息）原样插入，不翻译。
### - 中文只有 other 一种复数类别，不使用 [one]；允许精确数字分支 [1]、[2]。
###   源消息按变量选择时，保留选择表达式，只写 *[other]，以免丢失变量。
### - .atlaspkg 文件统称“Atlas 安装包”，上下文明确时可简称“安装包”；“安装文件”指
###   准备好的文件，不用来指 .atlaspkg 文件本身。
### - 安装步骤：准备、你的选择、Windows 安全中心、安装。ISO 步骤：Windows、配置、创建
###   （“配置”避免与应用的“设置”页面混淆）。
### - “Go to …”按钮译为 转到“…”，“Return to …”译为 返回“…”。
### - 省略号使用“…”（U+2026）。进度阶段名称（iso-stage-*、usb-stage-*）是不带“正在”的
###   动词短语，iso-progress-stage 再加上“正在…”。
### - 折叠卡片的“Show/Hide”链接译为“展开/收起”。
### - Windows 服务名称（BITS 等）按简体中文版“服务”列表显示的英文名称保留。
### - 失败标题中的“Couldn't …”一般译为“无法…”，个别过去发生的失败译为“未能…”
###   （如“未能读取”的开关状态）。

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
# 作用于单张卡片的按钮的辅助功能名称。$action 为按钮标签，$section 为卡片标题。
common-details-a11y = { $action }，{ $section }
# 打开安装日志所在的文件夹，并选中日志。
common-open-log-folder = 打开日志文件夹
# 安装日志旁边“复制”按钮的辅助功能名称。
common-copy-install-log = 复制安装日志
common-install-log = 安装日志
# 摘要卡片中的行标签。
common-windows = Windows
common-package = Atlas 安装包
common-checking = 正在检查
# 连接列表中的两项：“Brave、Firefox”。花括号用于保留分隔符。
list-separator = { "、" }
# 连接两个备选项：“26100 或 26200”。
list-or = { $a } 或 { $b }
# 连接列表的最后两项；$a 可能已包含用 list-separator 连接的多项。
list-and = { $a }和{ $b }
# 自动朗读的消息栏的辅助功能名称：先标题，后消息。
infobar-a11y = { $title }。{ $message }

## 窗口

# 安装进行中关闭窗口时显示的对话框。按钮为 window-close-keep 和 window-close-close。
window-close-title = 安装期间要关闭窗口吗？
window-close-installing = 安装会继续进行。重新打开 Atlas 即可查看结果。
# 安装完成后需重启电脑时代替 window-close-installing：只有打开的 Atlas 窗口才会重启电脑。
window-close-installing-no-restart = 安装会继续进行，但电脑不会自动重启。重新打开 Atlas 即可查看结果。
# 关闭窗口会中断某项操作时，保持窗口打开的按钮。
window-close-keep = 保持打开
window-close-close = 关闭窗口
# 在最后检查期间、安装程序启动之前关闭窗口时显示的对话框。
window-close-checks-question = 要在安装前停止吗？
window-close-checks-unchanged = 安装尚未进行任何更改。如果现在关闭，安装将不会开始。
window-close-keep-installing = 继续安装
window-close-stop-and-close = 停止并关闭
# 更新 Windows 和商店应用期间关闭窗口时显示的对话框。按钮为 stop-update-keep 和 prepare-stop。
prepare-close-question = 要停止更新吗？
# “阶段”指更新过程中的阶段（同 prepare-percent），不是四个流程步骤之一。
prepare-close-stops-after-stage = Atlas 会在当前阶段完成后停止。届时你可以将其关闭。
# 安装成功后在重启倒计时期间关闭窗口时显示的对话框。按钮为 restart-now 和 restart-dont-now。
window-close-restart-question = 要重启以完成 Atlas 的设置吗？
window-close-restart-closed = Atlas 关闭后将无法重启电脑。请先保存工作。
# “准备”步骤为完成更新而倒计时重启期间关闭窗口时显示。按钮为 restart-now 和 restart-dont-now。
window-close-update-restart-question = 要重启以完成更新吗？
window-close-update-restart-later = 请先保存工作。如果稍后重启，Atlas 会在重启后继续。
# 防护开关仍处于关闭状态时关闭窗口显示的对话框。
window-close-protection-title = 要在防护关闭的状态下关闭 Atlas 吗？
window-close-protection-all = Windows 安全中心的四个防护开关均已关闭。如果你现在不安装 Atlas，请先将它们重新开启。
# $switches 为已关闭的开关名称（与 Windows 安全中心一致），以列表形式连接；$count 为数量。
window-close-protection-some =
    { $count ->
       *[other] Windows 安全中心中的{ $switches }已关闭。如果你现在不安装 Atlas，请先将其重新开启。
    }
# 创建 ISO 或 U 盘期间关闭窗口时显示的对话框。按钮为 window-close-keep-creating 和 window-close-stop。
iso-close-question = 要停止创建 ISO 吗？
iso-close-safe-point = Atlas 会在下一个安全时机停止。
usb-close-question = 要停止创建 U 盘吗？
usb-close-unfinished = 未完成的 U 盘无法用于安装 Windows。
window-close-keep-creating = 继续创建
window-close-stop = 停止
# 选择 Atlas 安装包 (.atlaspkg) 的文件选择器中“打开”按钮的标签。这是按钮标签，请保持简短。
file-dialog-open-package = 打开 Atlas 安装包 (.atlaspkg)
# Windows 在重启通知中显示的消息。
shutdown-comment = Atlas 已安装。Windows 即将重启以完成设置。
# “准备”步骤为完成 Windows 更新的安装而重启时，Windows 在重启通知中显示的消息。
prepare-shutdown-comment = Atlas 正在重启 Windows，以完成更新的安装。

## 系统

# “Windows 11 专业版 25H2（内部版本 26200.1234）”。三个值均为文本。
system-description = { $product } { $version }（内部版本 { $build }）

## 主页

home-not-installed = 欢迎使用 Atlas
# home-not-installed 下方：这台电脑的 Windows，例如“Windows 11 专业版 25H2”。两个值均为文本。
home-windows = { $product } { $version }
# Atlas 找到其最新版本后代替 home-windows：这台电脑的 Windows 以及“安装 Atlas”将安装的 Atlas 版本，
# 例如“Windows 11 专业版 25H2 · Atlas 0.6.1”。$product 和 $version 为这台电脑的 Windows 产品名称和
# 版本号，$atlas 为 Atlas 版本（均为文本）。
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# 未安装 Atlas 的电脑上，位于 home-windows 或 home-windows-atlas 下方：用一句话说明 Atlas 的作用。
# 只说 Atlas 会改变什么，不要承诺电脑会变快。
home-about = Atlas 可减少 Windows 中的后台活动和干扰。
# Atlas Manager 无法确定这台电脑上安装了什么时的标题。
home-state-unknown = 这台电脑上的 Atlas
# 已安装 Atlas 时的标题。$version 为文本。
home-version = Atlas { $version }
# $date 为格式化后的日期。
home-installed-on = 安装于 { $date }
home-status-checking = 正在检查更新…
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
# 这台电脑上的 Windows 已被使用过时，“安装 Atlas”提出的问题。按钮为 common-cancel 和 home-used-windows-install。
home-used-windows-title = 要在这台电脑上安装 Atlas 吗？
home-used-windows-message = 你已有的应用和设置可能会无法正常工作；Atlas 还会移除 OneDrive，因此其中的文件将停止同步，文件夹可能会显示为空。请先备份文件。
home-used-windows-install = 仍要安装
# 打开 ISO 创建的卡片；按钮为 iso-open。
home-iso-title = 使用 Atlas 重新安装 Windows
# home-iso-title 下方，带“推荐”标记。
home-iso-used = 这台电脑上的 Windows 已使用过一段时间，而 Atlas 在全新安装的 Windows 上效果最好。
# 安装完成后、电脑重启前主页上的消息栏。消息为 restart-needed，按钮为 restart-now。
home-restart-title = 电脑需要重启
# Windows 拒绝重启时代替 restart-needed；按钮为 common-try-again。
home-restart-failed = Atlas 无法重启电脑。请从“开始”菜单重启。
home-security-reminder-title = 请重新开启防护
# 没有读到关闭的开关、但有开关无法读取时代替 home-security-reminder-title。
home-security-reminder-unreadable-title = 请确认防护已开启
# 位于 home-security-reminder-title 下方，在离开安装流程或保留 Microsoft Defender 的安装之后显示。
# $switches 为读取为关闭的开关名称（与 Windows 安全中心一致，即 protection-*），以 list-separator
# 和 list-and 连接；$count 为数量。
security-switches-still-off =
    { $count ->
       *[other] Windows 安全中心中的以下各项仍处于关闭状态：{ $switches }。
    }
# 没有读到关闭的开关、但有开关无法读取时代替 security-switches-still-off。$switches 为无法读取的开关名称，以列表形式连接。
home-security-reminder-unreadable-message = Atlas 无法读取部分防护开关。请在 Windows 安全中心检查以下各项是否已开启：{ $switches }。
home-elevation-title = Atlas 需要权限才能安装
# home-elevation-title 下方，无法保存设置选择时显示；原始错误在“显示详细信息”中。
home-elevation-draft-not-saved = Atlas 无法保存你的选择，因此未重新打开。
home-state-error-title = 无法读取 Atlas 的安装详情
# 按钮为 common-try-again；原始错误在“显示详细信息”中。
home-state-error-problem = 你的 Atlas 版本、选择和安装历史记录可能无法正确显示。
# Atlas 安装包需要更新版本的 Atlas Manager 时主页上的消息栏。
home-manager-needed-title = Atlas Manager 需要更新
home-whats-new = Atlas { $version } 新增内容
home-view-release = 在 GitHub 上查看发行说明
home-show-less = 收起
home-show-full-notes = 显示全部发行说明
home-your-install = Atlas 安装详情
# 已安装 Atlas，但没有 Atlas Manager 保存的安装记录（旧版本不会写入此记录）。
home-install-unrecorded = 这台电脑上没有 Atlas 安装方式的记录，因此无法显示你的选择和安装历史记录。
home-history = 安装历史记录
# 一行历史记录。$version 为文本，$mode 为 history-mode-* 消息之一，$date 为格式化后的日期和时间。
home-history-entry = Atlas { $version } · { $mode } · { $date }
# 带编号步骤的辅助功能名称。
home-step-a11y = 第 { $number } 步：{ $title }
# 带说明的编号步骤的辅助功能名称，屏幕阅读器朗读主页列表中的每个步骤时使用。$step 为 home-step-a11y
# 或 stepper-item-a11y，$detail 为该步骤的说明，例如 home-step-ready。
home-step-detail-a11y = { $step }。{ $detail }
# 未安装 Atlas 的电脑上，主页中列出四个安装步骤（step-ready、step-options、step-security 和
# step-install）的卡片，每个步骤旁边是对应的 home-step-* 说明。
home-steps-title = 安装流程
# 安装进行中时代替 home-steps-title：每个步骤会显示已完成、当前步骤或尚未开始。
home-steps-under-way-title = Atlas 安装进行中
# 在该卡片中位于 step-ready 旁边。
home-step-ready = Atlas 会检查你的电脑并更新 Windows。
# Windows 必须先更新到较新的版本才能安装 Atlas 时代替 home-step-ready。$release 为该版本，
# 例如“26H2”（文本）。
home-step-ready-move = Atlas 会检查你的电脑，并将 Windows 更新到版本 { $release }。
# 在该卡片中位于 step-options 旁边。Microsoft Defender 是该步骤询问的选择之一。
home-step-options = 由你决定保留哪些内容，例如 Microsoft Defender。
# 在该卡片中位于 step-security 旁边。
home-step-security = 由你手动关闭 Windows 安全中心的四个防护开关。
# 在该卡片中位于 step-install 旁边。$minutes 为安装通常所需的分钟数，来自 Atlas 安装包（数字）。
# 安装后电脑会自动重启时（按 settings-restart-automatically 的设置）显示第一条，需要用户自行重启时
# 显示第二条。
home-step-install-restarts =
    { $minutes ->
       *[other] 安装通常约需 { $minutes } 分钟，之后电脑会重启。
    }
home-step-install-restart-yourself =
    { $minutes ->
       *[other] 安装通常约需 { $minutes } 分钟，之后请重启电脑。
    }
# 位于该卡片底部、四个步骤下方。
home-steps-save-work = 应用可能会关闭，电脑也会重启，因此请先保存工作。
home-github = 在 GitHub 上查看 Atlas
home-discord = 加入 Atlas 社区 (Discord)
home-report-problem = 报告问题

## 安装方式（来自状态文档）

# 在历史记录行中使用的简短形式。
history-mode-fresh = 首次安装
history-mode-upgrade = 更新
history-mode-reapply = 重新安装
history-mode-unknown = 安装

## 主页上的通知

# 每条通知的原始错误及相关文件都在“显示详细信息”中。
notice-settings-reset-title = Atlas 正在使用默认的应用设置
notice-settings-unreadable-problem = Atlas 无法读取已保存的应用设置。你的 Windows 设置没有改变。
notice-settings-damaged-kept-problem = 应用设置文件已损坏，因此 Atlas 已将其重置，并保留了旧文件的副本。
notice-settings-damaged-problem = 应用设置文件已损坏。Atlas 暂时使用默认设置。
notice-settings-not-saved-title = 无法保存应用设置
notice-settings-not-saved-problem = Atlas 无法保存你最近的更改，关闭 Atlas 后这些更改可能会丢失。如果打开了另一个 Atlas 窗口，请将其关闭，然后重新进行更改。
notice-session-unreadable-title = 无法检查上次的安装
# 按钮 iso-open-folder 会在文件资源管理器中显示安装记录。
notice-session-unreadable-problem = Atlas 无法判断之前的安装是否仍在进行。如果你确定没有，请删除其安装记录，然后重新打开 Atlas。
# “准备”步骤中无法读取安装记录时显示。$path 为文件路径（文本）。
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
# 单个步骤的辅助功能名称。$heading 为 step-heading；$status 为 stepper-status-* 消息之一。
stepper-item-a11y = { $heading }，{ $status }
stepper-status-completed = 已完成
stepper-status-current = 当前步骤
stepper-status-upcoming = 后续步骤
# 已访问过但尚未满足要求的步骤。
stepper-status-attention = 需要注意
# 当前步骤的名称，获得焦点时朗读，不显示。
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }
# “你的选择”中当前步骤的辅助功能名称。$heading 为 stepper-item-a11y；$questions 为该页面提出的问题。
step-heading-choices-a11y = { $heading }。{ $questions }

## 第 1 步：准备
## 一个检查清单，共三行：电脑检查、Atlas 安装包和更新。每行有标题和一行状态。

# 行标题：以检查清单项目的形式说明这一行做什么。
ready-checks-title = 检查你的电脑
# 检查运行期间的状态行。
ready-checks-running = 正在检查你的电脑…
ready-check-again = 重新检查
# 所有检查均通过时的状态行。
ready-checks-passed =
    { $count ->
       *[other] { $count } 项检查已通过
    }
# 部分检查需要注意时的状态行。
ready-checks-passed-some =
    { $total ->
       *[other] { $total } 项检查中已通过 { $passed } 项
    }
# 位于 ready-checks-passed-some 之后，未通过的检查都由更新处理时显示，例如
# “9 项检查中已通过 5 项 · 4 项将在更新时处理”。$count 为由更新处理的检查数量。
ready-checks-handled = { $count } 项将在更新时处理
# 由更新处理的检查项的辅助功能状态，位于 check-a11y 的标题之后。
check-state-updates = 将在更新时处理
# 由更新处理的检查项标题下方。
check-updates-handled = 有更新等待安装。Atlas 会在更新 Windows 时安装它们。
check-restart-handled = Windows 需要重启以完成之前的更改。更新时会一并处理。
check-handled = 更新时会处理此项。
# 行标题：安装包中的 Atlas 版本。
ready-package-title = Atlas { $version }
# 安装包行的状态。
ready-package-downloading = 正在下载…
ready-package-unpacking = 正在解压…
ready-package-ready = 已就绪
ready-package-checking = 正在检查最新版本…
# 测试版：正在解压内置的 Atlas 安装包，不需要下载。
ready-package-bundled = 正在准备内置的 Atlas 安装包…
ready-package-none = 尚未下载
ready-package-failed = 无法获取 Atlas 安装包
# ready-package-failed 下方，旁边是 package-download-again 和 package-open-file。
ready-package-failed-detail = 请重新下载，或打开其他 Atlas 安装包 (.atlaspkg)。
# 测试版：唯一的操作是“重试”。
ready-package-bundled-failed-detail = 此测试版内置的 Atlas 安装包无法解压。请重试。
ready-package-manager = 需要更新版本的 Atlas Manager
ready-package-release-failed = 无法检查最新版本
ready-package-release-failed-detail = 请检查 Internet 连接，然后重试。如果你有 Atlas 安装包 (.atlaspkg)，也可以直接打开它。
# 行标题。
ready-updates-title = Windows 和 Microsoft Store 更新
# 开始更新前的状态行。“准备”步骤会自动开始更新。
ready-updates-pending = 记事本等商店应用可能会在更新时关闭，请先保存其中的工作。
# Windows 正在更新到版本 $release 时的状态行。
ready-updates-after-move = 将在 Windows 更新到版本 { $release } 后开始。
# Atlas 自己重启电脑后、更新自动继续之前的状态行。
ready-updates-resumed = 重启完成，正在继续…
ready-updates-restarting = 正在重启电脑…
ready-updates-done = Windows 和商店应用已是最新版本。
# Microsoft Store 已关闭、只更新了 Windows 时代替 ready-updates-done。
ready-updates-done-windows = Windows 已是最新版本。
# 更新所需重启前的倒计时，下方是 restart-now 和 restart-dont-now。
ready-updates-restart-countdown =
    { $seconds ->
       *[other] 电脑将在 { $seconds } 秒后重启。
    }
ready-updates-restart = 电脑需要重启才能完成更新。
ready-updates-restart-finish = Windows 还需要再重启一次，才能完成版本 { $release } 的安装。
ready-updates-restart-failed = 电脑没有重启
# 重启状态行下方，“立即重启”之前。
ready-updates-restart-save = 请先保存工作。
ready-updates-restart-persists = Windows 仍要求重启
# ready-updates-restart-persists 下方，旁边是“重试”和 check-fix-windows-update。
ready-updates-restart-persists-advice = 再次重启可能没有帮助。请先完成 Windows 更新中所有等待处理的项目，然后重试。
# 在“显示详细信息”中。$reasons 列出 prepare-reason-* 消息。
ready-updates-restart-persists-reasons = 重启原因：{ $reasons }
ready-updates-network = 更新无法使用此连接
ready-updates-stopped = 更新已停止。部分更新可能已经安装。
ready-updates-previous = 正在等待之前开始的更新…
# 用户停止更新后的按钮。
ready-updates-resume = 恢复更新
ready-updates-start = 开始更新
# 更新尚未开始的原因，显示在行下方。
ready-updates-blocked = 要等 Atlas 能在这台电脑上安装后，才会开始更新。
ready-updates-needs-admin = Atlas 获得管理员权限后开始。
ready-updates-needs-windows = Windows 兼容性检查通过后开始。
ready-updates-needs-drivers = 选择驱动程序的安装方式后开始。
# 更新行下方的驱动程序选择。$choice 为 ready-drivers-automatic 或 ready-drivers-manual。
ready-drivers-row = 驱动程序：{ $choice }
ready-drivers-automatic = 通过 Windows 更新
ready-drivers-manual = 自行安装
ready-drivers-change-a11y = 更改驱动程序的安装方式
# 更新运行过之后，显示在两个答案下方。
ready-drivers-again = 更改此项会重新运行更新。

# $received 和 $total 为格式化后的兆字节数（文本）。
package-downloading = 正在下载 Atlas { $version } · { $received } / { $total } MB
package-unpacking = 正在解压
package-status-ready = 已就绪
# 进度条的辅助功能名称。
package-progress = Atlas 安装包进度
package-download-again = 重新下载
package-download-version = 下载 Atlas { $version }
package-download-newest = 下载最新版本
package-cancel-download = 取消下载
package-open-file = 打开安装包文件
# 安装包的来源。$file 为文件名（文本）。
package-from-release = Atlas { $version } 已从 GitHub 下载，可以安装。
package-from-file = Atlas { $version } 已从 { $file } 加载，可以安装。
package-unpacked = Atlas { $version } 已就绪，可以安装。
package-none-yet = 尚无 Atlas 安装包
acquire-no-asset = Atlas { $version } 没有可下载的安装包。请打开已保存的 Atlas 安装包 (.atlaspkg) 以继续。
# 早于 Atlas 0.6.0 的安装包，以及不是 Atlas 安装包的文件（例如 0.6 之前的 .apbx 文件）。
acquire-unsupported = 此应用只能通过 Atlas 安装包 (.atlaspkg) 安装 Atlas 0.6.0 及更高版本。
# 打开的 Atlas 安装包是 Windows ISO 时代替 acquire-unsupported。旁边提供“创建 Atlas ISO”（iso-open）。
acquire-windows-iso = 这是 Windows ISO，不是 Atlas 安装包 (.atlaspkg)。要使用 Atlas 重新安装 Windows，请用它创建 Atlas ISO。
# 安装包足够新，本应包含此应用驱动的安装脚本，但缺少该脚本。
acquire-incomplete = Atlas { $version } 缺少此应用安装所需的文件。请重新下载，或打开其他 Atlas 安装包 (.atlaspkg)。
acquire-failed = 无法准备 Atlas 安装包。请重新下载，或打开其他 Atlas 安装包 (.atlaspkg)。详细信息：{ $error }
# 下载在一分钟内未收到任何数据，已被停止。
acquire-stalled = 下载已停止响应。请检查 Internet 连接，然后重新下载，或打开已保存的 Atlas 安装包 (.atlaspkg)。
# 测试版：内置的 Atlas 安装包无法解压。“重试”是唯一提供的操作。
acquire-failed-bundled = 无法准备内置的 Atlas 安装包。请选择“重试”。详细信息：{ $error }
# Atlas 安装包要求比当前版本更新的 Atlas Manager。$version 为其要求的版本，例如 0.7.0。旁边是
# manager-download。“它”指下载的 Atlas Manager，“当前版本”指正在运行的 Atlas Manager。
acquire-manager-update-needed = 此 Atlas 安装包需要更新版本的 Atlas Manager。请下载 Atlas Manager { $version } 或更高版本，并用它代替当前版本。
# 同上，用于未注明所需版本的安装包。
acquire-manager-update-needed-any = 此 Atlas 安装包需要更新版本的 Atlas Manager。请下载最新版本的 Atlas Manager，并用它代替当前版本。
# 适用于 Atlas $version 的安装包要求 Atlas Manager $required 或更高版本，例如 0.7.0。在“准备”步骤和
# 主页上，旁边是 manager-download。
acquire-manager-update-required = 要安装 Atlas { $version }，请下载 Atlas Manager { $required } 或更高版本，并用它代替当前版本。
# 同上，用于未注明所需 Atlas Manager 版本的安装包。
acquire-manager-update-required-any = 要安装 Atlas { $version }，请下载最新版本的 Atlas Manager，并用它代替当前版本。

## 新版 Atlas Manager

# 在浏览器中打开 GitHub 上最新的 Atlas 发布版本，从那里下载 Atlas Manager。
manager-download = 下载 Atlas Manager
# 主页和设置中提示已发布更新版本的 Atlas Manager。$version 为其版本，例如 0.7.0。
manager-update-title = 新版本 Atlas Manager { $version } 已发布
manager-update-message = Atlas Manager 无法自行更新。请下载新版本，并用它代替当前版本。

## 系统检查

check-administrator = 安装权限
check-supported-build = Windows 兼容性
check-pending-updates = Windows 更新
check-pending-reboot = 重启状态
check-third-party-antivirus = 其他防病毒软件
check-internet = Internet 连接
check-power = 电源
check-activation = Windows 激活
# 仅在 Atlas 需要将 Windows 更新到较新版本时显示：此次更新的要求。
check-move-hardware = Windows 11 硬件要求
check-move-space = 可用空间
check-move-update-source = 更新来源
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
# 打开 Windows 设置中的“存储”页面，可在其中释放空间。
check-fix-storage = 打开存储设置
# 从“其他防病毒软件”检查打开 Windows 设置中的“已安装的应用”页面（同 fixed-installed）。
check-fix-installed-apps = 打开“已安装的应用”
# 无法运行 Windows 更新扫描时，用户勾选的复选框。
check-ack-updates = 我已查看 Windows 更新，没有等待安装的更新

detail-admin-ok = Atlas 已获得安装所需的权限。
detail-admin-missing = 请以管理员身份重新打开 Atlas，并在 Windows 请求权限时选择“是”。
# $builds 为内部版本号列表，例如“26100 或 26200”；$build 为这台电脑的内部版本（文本）。
detail-build-unsupported = 此版本的 Atlas 需要 Windows 内部版本 { $builds }。这台电脑的内部版本是 { $build }。请先安装受支持的 Windows 版本再继续。
detail-build-missing = 此 Atlas 安装包未列出任何受支持的 Windows 内部版本。请使用完整版安装包，而不是 LocalTest 版本。
detail-updates-none = 没有等待安装的 Windows 更新。
# 更新运行后仍在等待的更新。$count 为数量。
detail-updates-left =
    { $count ->
       *[other] 仍有 { $count } 个更新等待安装。请在 Windows 更新中安装，然后重新检查。
    }
detail-updates-scan-failed = 无法检查 Windows 更新。请打开 Windows 更新，查看是否有等待安装的更新。（{ $error }）
detail-reboot-none = Windows 目前不需要重启。
# 更新运行后：更新留下的重启，或 Windows 仍需要的重启。
detail-restart-pending = Windows 需要重启以完成之前的更改。请重启电脑，然后重新检查。
# $reasons：Windows 设置的待重启标记，取自 prepare-reason-* 各项名称。
detail-restart-pending-reasons = Windows 需要重启以完成之前的更改（{ $reasons }）。请重启电脑，然后重新检查。
# 这是警告而非阻止项：$files 列出 Windows 将在下次重启时替换或删除的文件路径，最多三个。
detail-reboot-file-renames = 你可以继续。Windows 有一些文件要在下次重启时替换或删除（{ $files }）。Xbox Gaming Services 等部分应用每次重启后都会这样做。
detail-reboot-unknown = 无法检查 Windows 是否需要重启。请重启电脑，然后重新打开 Atlas 并重新检查。（{ $error }）
detail-antivirus-none = 未检测到其他防病毒软件。
# $products 为产品名称列表（文本）。该行提供 check-fix-installed-apps。
detail-antivirus-uninstall = Microsoft Defender 以外的防病毒软件可能会阻止安装。请卸载 { $products }，然后重新检查。
# 这是警告而非阻止项：安全中心仍列出该产品，但其文件已不存在。
detail-antivirus-stale = Windows 安全中心仍列出了 { $products }，但其文件已不存在，因此它已不再安装在电脑上。Atlas 仍可继续安装。
detail-antivirus-check-failed = 无法检查是否有其他防病毒软件。如果此问题反复出现，请重启电脑，然后重新检查。（{ $error }）
detail-internet-ok = 已连接。Atlas 下载和安装软件期间请保持连接。
detail-internet-missing = 请连接到 Internet，然后重新检查。
detail-power-mains = 电脑已接通电源。安装完成前请勿断开电源。
detail-power-battery = 请将电脑接通电源，确保整个安装过程中保持开机。
detail-power-check-failed = Atlas 无法判断电脑是否已接通电源。如果是笔记本电脑，请接通电源，然后重新检查。
detail-activation-ok = Windows 已激活。Atlas 不会更改此状态。
detail-activation-missing = Windows 尚未激活。你可以继续，但 Atlas 不会为你激活 Windows。
detail-activation-no-licence = Windows 未报告许可证。你可以继续；Atlas 不会更改你的激活状态。
detail-activation-unknown = 无法检查 Windows 激活状态。你可以继续；Atlas 不会更改你的激活状态。（{ $error }）
# 将 Windows 更新到版本 $release 的要求。$missing 列出 hardware-tpm 和 hardware-uefi。
detail-move-not-needed = 在这台电脑上，Atlas 无需将 Windows 更新到较新的版本。
detail-move-hardware-ready = 这台电脑具备 Windows 11 所需的 TPM 2.0 和 UEFI 固件。
detail-move-hardware-missing = 这台电脑缺少 { $missing }，因此 Windows 更新不会将其更新到版本 { $release }。请备份文件，然后使用 Atlas ISO 重新安装 Windows。
detail-move-hardware-unread = Atlas 无法读取这台电脑的全部硬件信息，因此将由 Windows 更新进行检查。
# $drive 为驱动器，例如 C:；$free 和 $needed 为整数 GB。
detail-move-space-ok = { $drive } 有 { $free } GB 可用空间。
detail-move-space-short = 版本 { $release } 需要 { $drive } 上有 { $needed } GB 可用空间，当前只有 { $free } GB。请释放空间，Atlas 会自动重新检查。
detail-move-space-unknown = 无法检查 Windows 更新所需的可用空间。请重启电脑，然后重新检查。（{ $error }）
detail-move-update-source-ok = 这台电脑从 Windows 更新获取更新。
detail-move-update-source-managed = 这台电脑从其组织的服务器获取更新，而该服务器不提供版本 { $release }。请联系你的组织，或使用 Atlas ISO 重新安装 Windows。

## 第 2 步：你的选择
## 一个页面列出所有问题，每个问题一张卡片，可选附加项折叠在下方。

# 显示在“你的选择”顶部，只列出 Atlas 文件夹中可以改回的选择。
options-change-later = 之后，你可以在桌面上的 Atlas 文件夹中更改 Microsoft Defender、处理器防护和更新设置。
# 折叠的“可选附加项”卡片的状态行，旁边是 options-extras-show 或 options-extras-hide。
options-extras-none = 未选择
# $count 为已勾选的附加项数量。
options-extras-ticked =
    { $count ->
       *[other] 已选择 { $count } 项
    }
# 展开和收起“可选附加项”卡片的链接。
options-extras-show = 展开
options-extras-hide = 收起
# 每个问题标题下方，最多一句话。
question-defender-description = Microsoft Defender 是 Windows 内置的防病毒软件。
question-mitigations-description = 这些防护也称为安全缓解措施，可抵御 Spectre 和 Meltdown 等处理器漏洞，以及利用应用缺陷发起的攻击。
question-auto-updates-description = 无论选择哪种方式，Atlas 都会让 Windows 保持在当前版本，并关闭 Microsoft Store 应用的自动更新。
question-browser-description = Atlas 不会更改你的浏览器设置。
# 非推荐答案下方的一行：它的代价。cost-defender-disable 也用于“安装”步骤、主页和移除 Defender 后的消息。
cost-defender-disable = 在你安装其他防病毒软件之前，电脑将没有防病毒保护；打开无法识别的应用或下载的文件前，Windows 也不会再发出警告。
# “Exploit Protection”为 Windows 安全中心中的页面名称。
cost-mitigations-disable = 这还会关闭 Exploit Protection 中针对应用的防护，例如控制流保护 (CFG)，从而降低安全性。
cost-auto-updates-disable = 请定期打开 Windows 更新以获取安全修复。
cost-auto-updates-default = Windows 可能会为完成更新的安装而重启电脑。
# 任务栏选择器答案下方：此答案会关闭切换用的快捷键。
cost-keyboard-shortcuts-off = Alt+Shift 和 Ctrl+Shift 将不再切换语言或布局。
# 可选附加项下方的一行：勾选后会发生什么。
extra-disable-hibernation = 可释放磁盘空间，但休眠和快速启动将不可用。
extra-disable-power-saving = 电脑可能更耗电、温度更高，电池续航也会变短。
extra-disable-core-isolation = 这会降低防护，使用 Riot Vanguard 或 FACEIT 等反作弊系统的游戏，可能要在你重新开启内存完整性后才能启动。
extra-uninstall-edge = 将删除这台电脑上的 Edge 收藏夹、历史记录和已保存的密码，已同步到 Microsoft 账户的内容除外。
extra-install-toolbox = 帮助你管理 Atlas 设置。目前处于测试阶段，部分功能可能尚未完善。
extra-install-eclean = AtlasOS 团队打造的工具，可检查垃圾文件和启动应用，需要账户和 Internet 连接。
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
# 每项决定在句中使用的简短名称，例如 summary-change-a11y、update-path-differs、
# preflight-choice-unanswered 和 installed-not-applied-choices。
screen-update-path-name = Atlas 更新方式
screen-defender-name = Microsoft Defender
screen-mitigations-name = 处理器防护
screen-updates-name = Windows 更新
screen-keyboard-name = 键盘语言
screen-browser-name = 浏览器
screen-power-name = 电源和安全
screen-apps-name = 应用
screen-optional-apps-name = 可选应用
# 此应用没有专门名称的单选问题，例如较新的 Atlas 安装包新增的问题。其标题为 screen-choose-one-title。
screen-package-choice-name = Atlas 安装包中的一项选择
screen-extras-name = 可选附加项
# 此应用没有专门措辞的必选项所使用的问题。
screen-generic-question = 为“{ $title }”选择一项
learn-more-defender = 详细了解 Microsoft Defender
learn-more-mitigations = 详细了解处理器防护
learn-more-updates = 详细了解 Windows 更新
learn-more-browser = 详细了解浏览器
learn-more-power = 详细了解电源和安全
learn-more-apps = 详细了解应用
learn-more-eclean = 详细了解 eclean
learn-more-keyboard = 详细了解键盘语言
learn-more-generic = 阅读安装指南
# 所选答案下方的一行文字：这对电脑意味着什么。
consequence-defender-enable = 保留 Windows 内置的防病毒软件，帮助保护电脑免受病毒和其他威胁。
consequence-mitigations-default = 保留 Windows 的默认防护，抵御处理器漏洞以及利用应用缺陷发起的攻击。
# “关闭处理器防护”下方。“Exploit Protection”为 Windows 安全中心中的页面名称。
consequence-mitigations-disable = 同时会关闭 Exploit Protection 中针对应用的防护，例如控制流保护 (CFG)。这会降低安全性。性能是否有变化取决于你的处理器。
consequence-auto-updates-disable = 请定期打开 Windows 更新来安装更新。更新通知保持开启。
consequence-auto-updates-default = Windows 会自动安装更新，包括安全修复。

## 更新或重新安装已安装的 Atlas 时的第 2 步

# 更新已安装的 Atlas 时“你的选择”的第一个页面。$version 为要安装的 Atlas 版本，例如 0.6.1。
update-path-update-title = 你想如何更新到 Atlas { $version }？
# 重新安装这台电脑已有的 Atlas 版本时的同一页面。
update-path-reinstall-title = 你想如何重新安装 Atlas { $version }？
# 该页面上的两个答案，各带一行说明。其他消息也会引用这两个答案，请保持一致。
update-path-keep = 保留我的选择
update-path-keep-detail = Atlas 会按这台电脑的当前设置保留每一项选择，不做任何更改。
update-path-choose = 重新选择
update-path-choose-detail = 以这台电脑的当前设置为起点。你的应用、文件和个性化设置都会保留。
# 两个答案下方列表的标题：每项选择一行，显示这台电脑当前的设置。
update-path-now-title = 你在这台电脑上的当前选择
# 电脑上无法判断的选择在该列表中的值。“保留我的选择”随后会询问此项。
update-path-unknown = Atlas 无法从你的电脑判断此项，因此会询问你
# 列表上方。$choices 列出 screen-*-name 消息，以 list-and 连接。
update-path-differs = 这台电脑的以下设置与 Atlas 的记录不符：{ $choices }。
# “保留我的选择”仍会询问的问题上方的一行，这些是电脑上无法判断的问题。
keep-choices-asked = Atlas 会按这台电脑的当前设置保留其他所有选择。
# “重新选择”页面上，这台电脑当前答案下方单独一行的简短标记。
option-now = 这台电脑的当前设置
# “重新选择”页面上，选择该答案会更改这台电脑时，代替通常的说明。
change-defender-enable = Atlas 会恢复 Microsoft Defender。重启后，请在 Windows 安全中心开启它的防护。
change-mitigations-default = Atlas 会按 Windows 默认设置重新开启处理器防护。重启后生效。
# 所有防护均已开启时，“保留处理器防护”下方：Atlas 会让它们全部保持开启，而不是恢复 Windows 默认设置。
change-mitigations-all-on = 目前所有处理器防护均已开启。保留防护会让它们全部保持开启。
change-auto-updates-default = Atlas 会让 Windows 重新自动安装更新。
# 这台电脑已关闭这些功能、而复选框被取消勾选时显示。
change-hibernation-on = Atlas 会重新开启休眠。
change-power-saving-on = Atlas 会重新开启节能功能，并恢复你之前的电源计划；如果没有，则改用“平衡”。
change-core-isolation-on = Atlas 会重新开启基于虚拟化的安全性 (VBS)，除非这台电脑上有策略控制此项。重启后生效。
# 这台电脑仍有截图工具、且勾选了“卸载截图工具”时显示。
change-remove-snipping-tool = 为这台电脑上的所有用户卸载截图工具。Atlas 之后无法恢复它，但你可以从 Microsoft Store 重新安装。
# “Install or Remove Edge”为 Atlas 文件夹中的文件名，在所有电脑上均为英文。
fixed-uninstall-edge = Microsoft Edge 已被卸载，更新 Atlas 无法恢复它。要重新安装，请使用 Atlas 文件夹中的“Install or Remove Edge”。
# $app 为 Atlas 安装的应用名称，例如 Atlas Toolbox 或 Brave。
fixed-installed = { $app } 已安装。Atlas 不会卸载应用；如需卸载，请前往 Windows 设置中的“已安装的应用”。
# $installed 和 $browser 为浏览器名称，例如 Brave 和 Firefox。
browser-also = { $installed } 会保留，Atlas 还会安装 { $browser }。

## Atlas 安装包文本
## Atlas 安装包中各选项和问题的标签与说明，按安装包 atlas.json 中的 ID 对应。
## 应用会用这些文字代替安装包自带的英文；较新的安装包新增的选项或问题
## 在这里没有对应消息时，显示安装包自带的英文。
## 标签中带“推荐”的选项另有 -short 形式：去掉推荐字样，用于“安装”步骤的摘要、主页和记录。

package-option-defender-enable = 保留 Microsoft Defender（推荐）
package-option-defender-enable-short = 保留 Microsoft Defender
package-option-defender-disable = 移除 Microsoft Defender
package-option-mitigations-default = 保留处理器防护（推荐）
package-option-mitigations-default-short = 保留处理器防护
package-option-mitigations-disable = 关闭处理器防护
package-option-auto-updates-disable = 由我自行安装更新
package-option-auto-updates-default = 自动安装更新
package-option-disable-hibernation = 关闭休眠
package-option-disable-power-saving = 关闭节能功能
package-option-disable-core-isolation = 关闭基于虚拟化的安全性 (VBS)
package-option-remove-snipping-tool = 卸载截图工具
package-option-uninstall-edge = 卸载 Microsoft Edge
package-option-install-another-browser = 安装浏览器
package-option-install-toolbox = 安装 Atlas Toolbox
package-option-install-eclean = 安装 eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender 是 Windows 内置的防病毒软件。只有在你了解风险并打算使用其他防病毒软件时，才应将其移除。无论你如何选择，Atlas 都会关闭“智能应用控制”“增强型网络钓鱼防护”和“查找我的设备”。
package-choice-mitigations-description = 这些防护也称为安全缓解措施，可帮助抵御 Spectre 和 Meltdown 等处理器漏洞，以及利用应用缺陷发起的攻击。建议保留 Windows 默认设置。
package-choice-auto-updates-description = Windows 更新包含安全修复。你可以让 Windows 自动安装更新，也可以自行安装。无论哪种方式，Atlas 都会让 Windows 保持在当前版本，而该版本只会在 Microsoft 终止支持之前获得安全修复。Atlas 还会关闭 Microsoft Store 应用的自动更新，因此请在 Microsoft Store 中更新这些应用。
package-choice-browser-description = 选择要安装的浏览器。Atlas 不会更改你的浏览器设置。

## 第 3 步：Windows 安全中心

# 这台电脑上没有 Microsoft Defender、且用户选择移除它时，代替开关列表显示。
security-banner-absent-title = 这台电脑未安装 Microsoft Defender
# security-banner-absent-title 和 security-banner-removed-title 下方的消息。
security-nothing-to-turn-off = 没有需要关闭的防护开关。
# Atlas 自己的安装包移除了 Microsoft Defender 且保持移除时，代替 security-banner-absent-title。
security-banner-removed-title = Atlas 已从这台电脑移除 Microsoft Defender
# Atlas 自己的安装包移除了 Microsoft Defender、而本次安装会恢复它时显示。
security-banner-restore-title = Atlas 将在本次安装中恢复 Microsoft Defender
security-restore-nothing-to-turn-off = Defender 尚未运行，因此没有需要关闭的项目。重启后，请在 Windows 安全中心开启它的防护。
# 不阻止此步骤的警告：用户选择保留 Microsoft Defender，但它不在这台电脑上，且不是 Atlas 移除的。
security-banner-missing-title = 找不到 Microsoft Defender
security-banner-missing-message = Microsoft Defender 不是 Atlas 移除的，因此 Atlas 无法恢复它。你可以继续，但在你安装其他防病毒软件或修复 Windows 之前，电脑将没有防病毒保护。
# 有开关仍开启或全部无法读取时显示。Atlas 已在开关所在位置打开 Windows 安全中心。
security-turn-off-title = 关闭这四个开关
security-turn-off-message = Microsoft Defender 可能会在安装期间阻止 Atlas。如果你保留 Defender，请在安装完成后将它们重新开启。
# Windows 安全中心中的页面名称。
security-list-title = “病毒和威胁防护”设置
security-switch-off = 关
security-switch-on = 开
security-switch-unreadable = 未能读取
security-switch-reading = 正在检查
security-all-off = 全部关闭
# 开关行的辅助功能名称。$state 为 security-switch-* 消息之一。
security-a11y = { $title }：{ $state }
# 摘要“2 个仍开启，1 个未能读取”的组成部分。
security-count-still-on = { $count } 个仍开启
security-count-unreadable = { $count } 个未能读取
security-count-join = { $a }，{ $b }
# Atlas 能读取的开关均已关闭，其余无法读取。$switches 为这些开关的名称，以 list-and 连接；$count 为数量。
security-unread-switches-title =
    { $count ->
       *[other] Atlas 无法读取开关：{ $switches }
    }
security-unread-message =
    { $count ->
       *[other] 请在 Windows 安全中心确认其已关闭。
    }
# security-unread-message 下方的复选框。
security-unread-confirm =
    { $count ->
       *[other] 我已确认{ $switches }已关闭
    }
# Atlas 无法读取四个开关中的任何一个时的复选框。
security-acknowledge = 我已检查 Windows 安全中心，四个开关均已关闭
security-unknown-unelevated-title = Atlas 需要权限才能检查防护设置
security-unknown-unelevated-message = 请以管理员身份重新打开 Atlas，以便它检查 Microsoft Defender 的设置。
# 四个开关，名称与简体中文版 Windows 安全中心一致，各带一行关闭原因。
protection-tamper = 篡改防护
protection-tamper-why = 让 Atlas 能够更改安全设置。
protection-realtime = 实时保护
protection-realtime-reason = 扫描可能会阻止 Atlas 的文件。
protection-cloud = 云提供的保护
protection-cloud-reason = 在线检查可能会阻止 Atlas 的文件。
protection-samples = 自动提交样本
protection-samples-why = 避免 Atlas 的文件被发送给 Microsoft。

## 第 4 步：安装

outcome-succeeded-title = Atlas 已安装
outcome-lost-title = 无法确认安装结果
outcome-failed-title = 安装未完成
# 安装未成功后结果栏的消息：发生了什么，然后怎么做，最多两句。不要提及按钮名称。
# 与 go-to-ready 一起显示。
result-requirements = 你的电脑不满足安装要求，因此未进行任何安装更改。
# -resumed 变体用于重试一个之前的尝试已开始应用更改的安装。
result-requirements-resumed = 你的电脑不满足安装要求，因此本次尝试已停止。之前的尝试已进行了更改。
# 与 common-restart-as-administrator 一起显示。
result-not-elevated = Atlas 没有管理员权限，因此未进行任何安装更改。
result-not-elevated-resumed = Atlas 没有管理员权限，因此本次尝试已停止。之前的尝试已进行了更改。
# 安装程序的实时检查发现 Windows 或商店更新尚未完成。与 go-to-ready 一起显示。
result-preparation-stale = Atlas 无法确认 Windows 和商店应用均为最新版本，因此安装在更改 Windows 之前已停止。
result-preparation-stale-resumed = Atlas 无法确认 Windows 和商店应用均为最新版本，因此本次尝试已停止。之前的尝试已进行了更改。
result-failed-preflight = 安装在更改任何内容之前已停止。你可以重试。
result-failed-staging = 安装在准备文件时停止，尚未更改 Windows。你可以重试。
# 与 common-open-windows-security 一起显示。“防护开关”指用户关闭的四个开关。
result-failed-applying = 部分更改可能已经应用。你可以重试；如果就此停止，请在 Windows 安全中心重新开启防护开关。
# -defender-removed 变体：Microsoft Defender 已被移除，没有需要重新开启的防护开关。
result-failed-applying-defender-removed = 部分更改可能已经应用。你可以重试。
result-failed-resumed = 本次尝试提前停止，但之前的尝试已进行了更改。你可以重试；如果就此停止，请在 Windows 安全中心重新开启防护开关。
result-failed-resumed-defender-removed = 本次尝试提前停止，但之前的尝试已进行了更改。你可以重试。
# -repeated 变体：重试时因与上次相同的错误而停止，因此建议发送报告。“发送报告”即 report-title。
result-failed-repeated = 本次尝试因与上次相同的错误而停止，重试很可能无济于事。请发送报告，以便 Atlas 团队查明原因；如果就此停止，请重新开启防护开关。
result-failed-repeated-defender-removed = 本次尝试因与上次相同的错误而停止，重试很可能无济于事。请发送报告，以便 Atlas 团队查明原因。
# $apps 为 Windows 给这些应用的包名称，例如 MSTeams（文本），以 list-and 连接。
result-failed-repeated-apps = Windows 仍未能移除 { $apps }，因此重试很可能无济于事。请发送报告，以便 Atlas 团队查明原因；如果就此停止，请重新开启防护开关。
result-failed-repeated-apps-defender-removed = Windows 仍未能移除 { $apps }，因此重试很可能无济于事。请发送报告，以便 Atlas 团队查明原因。
result-not-started = 安装程序未能及时启动，因此未进行任何安装更改。你可以重试。
result-lost = 安装程序未报告结果就停止了，因此部分更改可能已经应用。你可以重试；如果就此停止，请在 Windows 安全中心重新开启防护开关。
# Defender 已被移除时代替 result-lost。
result-lost-defender-removed = 安装程序未报告结果就停止了，因此部分更改可能已经应用。你可以重试。
restart-now-message = Windows 正在重启，以完成 Atlas 的设置。
restart-stopped = 已取消自动重启。请保存工作，然后重启电脑以完成 Atlas 的设置。
restart-needed = 请保存工作，然后重启电脑以完成 Atlas 的设置。
restart-dont-now = 稍后重启
restart-now = 立即重启
# 最后检查拒绝启动安装程序时的消息栏。消息说明需要处理的问题；按钮即解决方法。
preflight-title = 安装尚未开始
# 与 go-to-options 一起显示。$choice 为 screen-*-name 消息（句中形式），例如“处理器防护”。
preflight-choice-unanswered = Atlas 需要你的回答：{ $choice }。
preflight-choices-unusable = Atlas 无法使用这些选择。
# 与 go-to-ready 一起显示。$checks 列出 check-* 名称，以 list-and 连接；$count 为数量。
preflight-checks-changed =
    { $count ->
       *[other] 自 Atlas 检查电脑以来，以下项目需要处理：{ $checks }。
    }
# 与 common-open-windows-security 一起显示。$summary 为 Windows 安全中心摘要，例如“1 个仍开启”。
preflight-security-changed = 你关闭开关后，Windows 安全中心发生了变化：{ $summary }。
preflight-busy-wait = 另一个 Atlas 窗口正在启动安装。请稍候片刻，然后重试。
# 与 home-start-over 一起显示。
preflight-taken-over-start-over = 另一个 Atlas 窗口已接管此次安装。请在那个窗口中继续，或在此处重新开始。
# 与 go-to-ready 一起显示。
preflight-record-unreadable-check = Atlas 无法检查之前的安装是否仍在进行，因此没有开始新的安装。
preflight-not-started = Atlas 无法启动安装程序，因此未进行任何安装更改。你可以重试。
# 重试之前的尝试已开始应用的安装时，代替 preflight-not-started 显示。
preflight-not-started-resumed = Atlas 无法启动安装程序，但之前的尝试已进行了更改。你可以重试。
go-to-ready = 转到“准备”
# 有问题未回答时“安装”步骤消息栏上的按钮；打开“你的选择”中的该问题。
go-to-options = 转到“你的选择”
# Atlas 无法读取的开关需要在“Windows 安全中心”步骤确认时的按钮。
go-to-security = 转到“Windows 安全中心”
# 从“安装”步骤的“更改”链接打开某项选择，且“继续”会直接返回“安装”时，代替“继续”按钮。
go-to-install = 返回“安装”
output-problem-title = 无法读取安装进度
install-elevate-title = Atlas 需要权限才能安装
# install-elevate-title 下方，旁边是 common-restart-as-administrator。
install-elevate-uac = Atlas 重新打开时，Windows 会请求你的许可。
# 没有就绪的 Atlas 安装包时“安装”步骤上的消息栏，旁边是 go-to-ready。
install-package-missing = Atlas 安装包尚未就绪
# 本次会话中第 1 步（检查或 Windows 更新）未完成时的第 4 步，按钮为 go-to-ready。
install-not-ready-title = 请先完成“准备”步骤
install-not-ready-message = Atlas 需要先完成电脑检查和 Windows 更新，然后才能安装。
# 重新读取的防护开关状态不再符合要求时“安装”步骤上的消息栏。$summary 为 Windows 安全中心摘要。
install-switches-title = 请重新关闭防护开关
install-switches-message = Windows 安全中心：{ $summary }。
# “安装”步骤的卡片：没有任何阻碍时用前者，否则用后者。
summary-ready-title = 已准备好安装
summary-setup-title = Atlas 安装详情
summary-activation = 激活
summary-activation-ok = 已激活。Atlas 不会更改此状态。
summary-activation-missing = 未激活。你可以继续，但 Atlas 不会激活 Windows。
summary-activation-unknown = Atlas 不会更改你的 Windows 激活状态。
# 安装通常需要的时间，来自 Atlas 安装包。勾选下方复选框时显示前者，未勾选时显示后者。
summary-time-restarts =
    { $minutes ->
       *[other] 通常约需 { $minutes } 分钟，之后电脑会重启
    }
summary-time-restart-yourself =
    { $minutes ->
       *[other] 通常约需 { $minutes } 分钟，之后请重启电脑
    }
# 卡片上的复选框，与 settings-restart-automatically 是同一设置。
summary-restart-automatically = 安装完成后自动重启电脑
# 卡片详细信息中的一行：无论 Microsoft Defender 选择哪个答案，Atlas 都会关闭的功能。
summary-turned-off = 还会关闭
summary-turned-off-value = 智能应用控制、增强型网络钓鱼防护和查找我的设备
summary-show-command = 显示安装命令
summary-hide-command = 隐藏安装命令
# 安装命令下方“复制”按钮的辅助功能名称。
summary-copy-command-a11y = 复制安装命令
summary-command-unavailable = 无法准备安装命令。详细信息：{ $error }
summary-not-chosen = 尚未选择
# “更改”链接的辅助功能名称。$title 为 screen-*-name 消息之一。
summary-change-a11y = 更改“{ $title }”
# 更新或重新安装时摘要的第一行。其值为 update-path-keep 或 update-path-choose。
summary-update-path = Atlas 更新方式
# “准备”步骤上“继续”不可用的原因：作为其描述朗读，并在页面未说明时显示在旁边。不超过 8 个词。
footer-still-checking = 正在为安装做准备
footer-checks-blocked = 请处理检查发现的问题以继续
footer-manager-outdated = 请下载更新版本的 Atlas Manager 以继续
footer-need-files = 请获取 Atlas 安装包以继续
# footer-need-files 的测试版变体。
footer-need-package-bundled = 请准备内置的 Atlas 安装包以继续
footer-drivers = 请选择驱动程序的安装方式以继续
footer-windows-terms = 请接受许可条款以继续
footer-updating = 正在更新 Windows 和商店应用…
footer-restart = 请重启电脑以继续
footer-reading-security = 正在检查防护开关
# “Windows 安全中心”步骤上“继续”不可用的原因：有开关仍开启时，以及只剩无法读取的开关需要确认时。
footer-security-pending = 请关闭全部四个开关以继续
footer-security-confirm = 要继续，请确认 Atlas 无法读取的开关
# 开启自动重启时显示在“安装 Atlas”旁边：安装完成后电脑会重启。
footer-install-ready = 请先保存工作并关闭其他应用
button-install = 安装 Atlas
log-earlier-lines =
    { $count ->
       *[other] 日志文件中还有之前的 { $count } 行。
    }
# 复制日志时追加。$path 为文件路径（文本）。
log-full-log-note = （完整日志：{ $path }）

## 安装中视图

installing-title = 正在安装 Atlas
# Atlas 正在做什么，显示在 installing-title 下方，也是进度条的辅助功能名称：以省略号结尾的简短动词短语。
installing-checking-label = 正在检查你的电脑…
installing-staging-label = 正在复制 Atlas 文件…
installing-applying-label = 正在设置 Windows…
installing-finishing-label = 正在完成…
# 进度条下方的一行：安装完成后电脑会自动重启时用前者，不会时用后者。
installing-keep-on-restart = 请保持电脑开机并接通电源。安装完成后，电脑会自动重启。
installing-keep-on = 请保持电脑开机并接通电源。安装完成后，请重启电脑。
# Atlas 无法跟踪安装程序的日志时显示。标题为 output-problem-title，按钮为 common-open-log-folder。
installing-output-problem = 这并不表示安装已停止。
installing-installed-title = Atlas 已安装
# 重启倒计时期间显示在 installing-installed-title 下方，其下是 installing-restart-save，然后是 restart-now 和 restart-dont-now。
installing-restart-countdown =
    { $seconds ->
       *[other] 电脑将在 { $seconds } 秒后重启。
    }
installing-restart-save = 请先保存工作。

## 重启后的“Atlas 已安装”窗口

installed-title-version = Atlas { $version } 已安装
installed-title = Atlas 已安装
installed-ready = 一切就绪。你的电脑现在可以使用 Atlas 了。
# 用户自行安装驱动程序时，设置卡片下方的一行，其下是链接 installed-drivers-guide。
installed-manual-drivers-detail = 请从电脑、主板或设备制造商处获取芯片组、网络和显卡驱动程序。
installed-drivers-guide = 打开驱动程序指南
# 安装移除了 Microsoft Defender 之后。消息为 cost-defender-disable。
installed-defender-removed-title = 已移除 Microsoft Defender
# 主页和“Atlas 已安装”窗口：安装保留了 Microsoft Defender，但它不见了，且不是 Atlas 安装包移除的。
# 标题为 security-banner-missing-title；按钮为 report-title。
defender-missing-message = Atlas 没有移除它。如果你没有使用其他防病毒软件，请安装一款来保护电脑。
# Atlas 的记录保留了 Microsoft Defender，但 Atlas 自己的安装包仍会移除它。按钮为 home-reinstall。
# “7. Security”“Defender”和“Toggle Defender”为 Atlas 文件夹中的文件夹和文件名，在所有电脑上均为英文。
installed-defender-not-restored-title = Microsoft Defender 仍未恢复
defender-not-restored-message = 之前的 Atlas 更新没有恢复它，因此 Defender 目前没有保护你的电脑。请重新安装 Atlas 并保留 Defender，或运行 Atlas 文件夹中“7. Security”>“Defender”里的“Toggle Defender”。
# 安装记录的某些选择与用户所选不符时的“Atlas 已安装”窗口。之后是帮助链接（发送报告、导出诊断信息、打开日志文件夹）。
installed-not-applied-title = 部分选择未生效
# $choices 列出这些选择的名称（screen-*-name 的句中形式），例如“Microsoft Defender和处理器防护”，
# 以 list-and 连接；$count 为数量。
installed-not-applied-choices =
    { $count ->
       *[other] 以下各项保持原样：{ $choices }。
    }
# 更新的最后一步按用户自己的 Atlas 选择再次关闭或暂停 Windows 更新之后。
installed-update-off-title = 已按你的选择重新关闭 Windows 更新
installed-update-off-message = 关闭期间，你的电脑不会获得安全更新。
installed-update-paused-title = 已按你的选择重新暂停 Windows 更新
installed-update-paused-message = 暂停期间，你的电脑不会获得安全更新。

## 设置

settings-title = 设置
# 页面各部分的标题。settings-language 和 settings-help 也是部分标题。
settings-appearance = 外观
settings-installation = 安装
settings-privacy = 隐私
settings-theme = 应用主题
settings-theme-system = 跟随 Windows
settings-theme-light = 浅色
settings-theme-dark = 深色
settings-theme-contrast-note = Atlas 正在使用你的 Windows 对比主题的颜色。
settings-language = 语言
# “语言”部分中的设置，也是其下拉框的名称。
settings-app-language = 应用语言
# 语言下拉框中的第一项：跟随 Windows，然后是由此得到的语言。$language 为该语言的本地名称，例如“简体中文”。
settings-language-match-windows = 跟随 Windows：{ $language }

# 每种已翻译但尚未经母语者审校的语言后显示的简短标签。
settings-language-preview-tag = 预览版
# 正在使用预览版翻译、且其通知（preview-notice）已关闭时，显示在语言下拉框下方。
settings-language-preview-in-use = 此翻译尚未经过母语人士审校。
# 使用预览版翻译时内容顶部的消息栏，直到用户将其关闭。$language 为该语言的本地名称。
preview-notice = { $language }是预览版翻译，可能存在错误。
preview-notice-switch = 切换到英文
preview-notice-language = 更改语言
# 所选语言不在此版本中、下拉框显示正在使用的英语时，显示在下拉框下方。
settings-language-chosen-unavailable = 此版本的 Atlas 不提供你选择的语言，因此显示英语。你的选择已保留。
# 选择“跟随 Windows”、而 Atlas 不支持任何 Windows 显示语言时。
settings-language-windows-unsupported = Atlas 尚不支持你的 Windows 显示语言，因此显示英语。
# 选择“跟随 Windows”、而无法读取 Windows 显示语言时。
settings-language-windows-unreadable = Atlas 无法检查你的 Windows 显示语言，因此显示英语。
# 区域格式与应用语言不同时。$locale 为区域格式的本地名称，例如“中文(简体，中国)”。
settings-language-formats = 数字、日期和时间遵循你的 Windows 区域格式：{ $locale }。
# Windows 区域格式从右到左书写日期或时间时，代替 settings-language-formats 显示。
# $locale 为该格式的英文名称，例如“Arabic (Saudi Arabia)”。
settings-language-formats-numbers-only = 数字遵循你的 Windows 区域格式：{ $locale }。由于 Atlas 暂时无法显示从右到左的文字，日期和时间使用标准格式。
settings-language-contribute = 在 GitHub 上帮助翻译 Atlas
# 使用情况分析开关，带说明和隐私政策链接。
settings-share-usage = 与 Atlas 共享使用情况数据
settings-share-usage-description = 你打开的页面、ISO 创建情况以及安装是否成功。
settings-privacy-policy = 隐私政策
# 此开关同时适用于安装后的重启，以及安装前 Windows 和商店更新所需的重启。
settings-restart-automatically = 安装和更新完成后自动重启
settings-restart-automatically-description = Atlas 完成后一分钟内，电脑会重启并关闭已打开的应用。
settings-restart-locked = 安装完成后才能更改此设置。
# “发送报告”“导出诊断信息”和 settings-open-data-folder 上方的标题。
settings-help = 帮助
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
consequence-disable-core-isolation = 关闭 Windows 的一层额外安全防护，包括内存完整性。这会降低防护，使用 Riot Vanguard 或 FACEIT 等反作弊系统的游戏，可能要在你重新开启内存完整性后才能启动。
consequence-remove-snipping-tool = 卸载用于截屏和录屏的 Windows 应用。
consequence-uninstall-edge = 卸载 Microsoft Edge 浏览器。请确保已有其他浏览器，或在下方选择一个。
# “安装”步骤摘要中“卸载 Microsoft Edge”下方，带警示图标。
caution-uninstall-edge = 将删除这台电脑上的 Edge 收藏夹、历史记录和已保存的密码。
consequence-install-another-browser = 在下方选择一款浏览器，Atlas 会为你安装。
consequence-install-toolbox = 添加 Atlas Toolbox，方便管理 Atlas 设置。Toolbox 目前处于测试阶段，部分功能可能尚未完善。
consequence-install-eclean = AtlasOS 团队打造的维护工具，帮助你在设置完成后保持电脑整洁。检查垃圾文件和启动应用。需要账户和 Internet 连接。

## 创建 ISO
iso-open = 创建 Atlas ISO
iso-title = 创建 Atlas ISO
iso-recommended = 推荐
# 步骤条中三个 ISO 步骤的标题：Windows 从哪里来、如何配置，以及创建 ISO 的核对步骤。
iso-step-source = Windows
iso-step-setup = 配置
iso-step-create = 创建
# “Windows”步骤的第一个问题，决定之后的默认值：体系结构、语言、版本、账户名以及这台电脑的网卡驱动程序。
iso-target-title = 此 ISO 用于哪台电脑？
iso-target-this = 这台电脑
iso-target-another = 另一台电脑
# ISO 适用于与这台电脑不同的处理器时显示。$architecture 为 iso-architecture-x64 或 iso-architecture-arm64。
iso-target-arch = 此 ISO 适用于 { $architecture } 电脑。
iso-source = Windows ISO
# 立即开始下载 Windows 11，语言和体系结构见下方的 iso-download-caption。
iso-download-windows = 从 Microsoft 下载
# 下载的内容。$language 为 Microsoft 对该语言的英文称呼，例如“English International”；$architecture 为 x64 或 Arm64。
iso-download-caption = Windows 11 · { $language } · { $architecture }
# 同上，Microsoft 的语言列表加载期间。
iso-download-caption-loading = Windows 11 · { $architecture }
# 用于“更改”链接的辅助功能名称，指下载的语言和体系结构。
iso-download-what = Windows 下载
iso-download-language = 语言
iso-download-arch = 体系结构
iso-download-languages = 正在加载语言…
# 下载 Windows 时进度条的标签，然后是已下载的量。$received 和 $total 为大小，例如“2.4 GB”。
iso-downloading = 正在下载 Windows 11…
iso-download-amount = { $received } / { $total }
# 无法通过 Atlas 连接到 Microsoft 的下载服务，或下载中途停止。旁边是“重试”。
iso-download-unreachable = Atlas 无法连接到 Microsoft 的下载服务。请检查 Internet 连接，然后重试。
iso-download-incomplete = 下载未完成。请检查 Internet 连接和可用空间，然后重试。
iso-download-website = 打开 Microsoft 下载页面
# 打开 Windows ISO 的文件选择器，也是该选择器中“打开”按钮的标签。
iso-use-local = 选择 ISO 文件
# 检查文件期间的状态标记，之后“继续”才可用。
iso-checking = 正在检查你的 Windows ISO…
# 检查通过后“已就绪”标记的辅助功能名称。$facts 为 ISO 的体系结构和大小，例如“x64 · 6.6 GB”。
iso-checked-a11y = Windows ISO 已就绪，{ $facts }
iso-package-latest-label = 最新版
# 最新的 Atlas 发布版本比此 Atlas Manager 能使用的版本旧；下方是 package-open-file。
iso-package-release-old = 最新发布的 Atlas 版本过旧，此 Atlas Manager 无法使用。
# Atlas 自动查找并下载最新的 Atlas 安装包期间。
iso-package-fetching = 正在获取最新版 Atlas…
# 发布版本检查失败，无法找到最新的安装包；旁边是“重试”。
iso-package-release-failed = Atlas 无法检查最新版本。请检查 Internet 连接，然后重试。
# 文件旁“更改”按钮的辅助功能名称：$action 为按钮文字，$field 为文件的标签。
iso-pick-a11y = { $action }：{ $field }
# 还没有 Windows ISO 时，显示在“Windows”步骤不可用的“继续”旁边。
iso-need-windows = 请获取 Windows ISO 以继续
# “配置”步骤中关于何时做出安装包选择的问题。
iso-mode-question = 你想在什么时候做出 Atlas 选择？
iso-mode-after = 登录后
iso-mode-after-description = 登录后，Atlas 会引导你完成设置。
iso-mode-now = 现在
iso-mode-now-description = 保存到 ISO 中。登录后再安装 Atlas。
# “现在”下方的复选框，“现在”的说明已提到选择会保存到 ISO 中。
iso-mode-before-desktop = 在进入桌面前完成
iso-mode-before-desktop-description = 登录后，Atlas 会全屏运行，直到安装完成。
# Atlas 安装包无法将选择保存到 ISO 中时，代替该问题显示。
iso-mode-unavailable = 此 Atlas 安装包无法将选择保存到 ISO 中，因此需要在登录后做出选择。
iso-atlas-options = Atlas 选择
# “创建”步骤顶部的一行。
iso-create-intro = 创建 ISO 不会更改这台电脑或原始 ISO。
iso-review-package = Atlas 安装包
iso-review-output = 新 ISO
iso-review-edition = 版本
iso-review-editions = 版本
iso-edition = Windows 版本
# Windows 安装程序询问要安装哪个版本时，“配置”步骤版本卡片上显示的版本。
iso-edition-auto = 由 Windows 安装程序询问
# 该卡片版本菜单中的第一项，位于 ISO 自带的版本之上：让 Windows 安装程序询问要安装哪个版本的选项。
iso-edition-auto-menu = 由 Windows 安装程序询问
# 可选复选框：在此接受许可条款后，Windows 安装程序就不会再询问。
iso-accept-terms-optional = 接受 Windows 许可条款，Windows 安装程序将不再询问
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# 文件大小；$size 为格式化后的数字（文本）。小于 1 GB 时以 MB 显示。
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = 账户名
iso-review-target = 安装到
iso-review-drivers = 驱动程序
# 核对行：ISO 的应答文件会跳过的 Windows 安装程序页面。
iso-review-setup-screens = Windows 安装程序
iso-review-skips = 跳过 Microsoft 账户和隐私设置页面
iso-review-skips-terms = 跳过许可条款、Microsoft 账户和隐私设置页面
iso-review-network = 网卡驱动程序
iso-review-network-included = 这台电脑的 Wi-Fi 和以太网驱动程序
# 选择保存在 ISO 中、并在桌面打开前完成时，“Atlas 选择”行的值。
iso-review-mode-before-desktop = 现在，在进入桌面前完成
# “创建”步骤中新 ISO 的下方。$needed 和 $free 为大小，例如“35.0 GB”；$drive 为驱动器，例如“C:”。
iso-destination-space = 需要 { $needed } · { $drive } 可用 { $free }
iso-destination-short = ISO 需要 { $needed }，而 { $drive } 只有 { $free } 可用空间。请释放空间，或将 ISO 保存到其他驱动器。
iso-destination-filesystem = { $drive } 无法存放 ISO 中的大文件。请将其保存到格式化为 NTFS 的驱动器，例如 Windows 所在的驱动器。
iso-destination-unusable = Atlas 只能将 ISO 保存到这台电脑上某个驱动器中的文件夹。
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = 在你保存到的文件夹中，ISO 中的文件所需的路径会超出 Windows 允许的长度。请将新 ISO 保存到路径较短的文件夹，例如 Windows 所在驱动器上的文件夹。
iso-create = 创建 ISO
# 创建 ISO 期间，进度条和阶段列表（iso-stage-*）上方的标题。
iso-progress-title = 正在创建 ISO…
# 进度条的标签：进行中的阶段，以省略号结尾。$stage 为 iso-stage-* 消息之一（不带“正在”）。
iso-progress-stage = 正在{ $stage }…
iso-stage-read = 读取 Windows ISO
iso-stage-copy = 复制 Windows 文件
iso-stage-add-atlas = 添加 Atlas
iso-stage-master = 写入 ISO 文件
iso-stage-verify = 检查新 ISO
iso-stage-cleanup = 完成最后步骤
# 创建 ISO 期间单个阶段的辅助功能名称。不要加“第 N 步”：屏幕阅读器会读出“第 4 项，共 6 项”。
iso-stage-a11y = { $title }，{ $status }
iso-stage-status-current = 进行中
# 创建 ISO 因错误而停止时所在的阶段。
iso-stage-status-failed = 失败
iso-stage-status-not-started = 未开始
iso-progress-keep-open = 请保持 Atlas 打开，直到完成。
iso-cancel = 取消创建
iso-cancelling = 正在等待安全的取消时机
# 请求取消后，ISO 或 U 盘进度条上方的标题。
iso-cancelling-short = 正在取消…
iso-cancelled = 已取消创建 ISO
iso-cancelled-unchanged = 原始 ISO 未被更改。
iso-complete = ISO 已就绪
iso-complete-backup = 用它重新安装 Windows 之前，请先备份文件。
# 完成页面的主按钮，打开 U 盘面板。
iso-create-usb = 创建 U 盘
iso-open-folder = 在文件夹中显示
iso-failed = 未能完成 ISO 创建
# iso-failed 下方，旁边是“重试”。
iso-failed-retry = 请确保文件仍在你选择的位置，且保存位置所在的驱动器已连接，然后重试。
# 检查文件失败时的标题；下方的消息说明原因。
iso-check-failed = 无法检查文件
iso-check-failed-retry = 请确保 ISO 和 Atlas 安装包均已下载完成，然后重试。
# 无法创建工作进程运行所需的文件夹，因此什么都没有运行。
iso-unstaged = Atlas 无法准备其工作文件夹，因此未做任何更改。
# Atlas 无法使用的 ISO 或安装包的标题和消息。消息栏提供解决方法。
iso-edition-unsupported-title = 此 ISO 中没有 Atlas 支持的版本
iso-edition-unsupported = 不支持 Windows 家庭版和 LTSC 版本。请使用包含专业版、教育版或企业版的 ISO。
iso-customised-title = 此 ISO 已被自定义
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = 此 ISO 由 Atlas 创建
iso-customised = 它已包含安装配置文件，例如 autounattend.xml。请使用 Microsoft 提供的未经修改的 ISO。
iso-preview-title = 此 ISO 是预览版本
iso-preview = 它的 Windows 内部版本不在 Microsoft 的正式发布版本列表中。请使用 Microsoft 提供的 ISO。
iso-windows-unsupported-title = 此 Atlas 安装包无法使用此 ISO
iso-windows-unsupported = 请使用未经修改、且版本受此安装包支持的 Windows 11 ISO。
iso-release-unknown-title = Atlas 无法确认此 Windows 版本
iso-release-unconfirmed = Atlas 会根据 Microsoft 的正式发布版本列表进行核对。请检查 Internet 连接，然后重试。
# $minimum 为能够创建 ISO 的最早 Atlas 版本，例如“0.6.0”。
iso-package-old-title = 此 Atlas 安装包无法创建 ISO
iso-package-old = 请使用 Atlas { $minimum } 或更高版本。
# 选作 Atlas 安装包的文件是 Windows ISO 时，代替 iso-package-old-title 和 iso-package-old。“Windows ISO”指名为 iso-source 的字段。
iso-package-windows-iso-title = 这是 Windows ISO，不是 Atlas 安装包
iso-package-windows-iso = 请改为选择 Atlas 安装包 (.atlaspkg)，并将此 ISO 选为 Windows ISO。
iso-manager-missing-title = Atlas Manager 文件缺失
iso-fix-package = 选择其他安装包
# 安装包需要更新版本的 Atlas Manager；旁边是 manager-download，acquire-manager-update-needed 说明所需版本。
iso-manager-outdated-title = Atlas Manager 需要更新
# 无法导出这台电脑的网卡驱动程序；旁边的按钮会在不包含它们的情况下创建。
iso-network-not-added = Atlas 无法将这台电脑的网卡驱动程序添加到 ISO 中。
iso-network-skip = 跳过并创建
# 请求管理员权限的消息栏标题。消息为 iso-admin-reason；Windows 拒绝重新打开（UAC 被拒绝）后为 iso-elevation-declined。
iso-elevation-title = Atlas 需要权限才能创建 ISO
iso-admin-reason = 需要此权限才能读取你的 Windows ISO 并创建新的 ISO。
iso-elevation-declined = Windows 未授予 Atlas 权限，因此暂时无法读取你的 Windows ISO。
# 创建 ISO 期间可用空间耗尽。
iso-failed-space = 目标驱动器的可用空间不足。请释放空间，或将新 ISO 保存到其他驱动器。
# iso-manager-missing-title 下方。
iso-manager-missing = 请将 AtlasManager.exe 下载到“下载”等本地文件夹，然后从那里打开它。
# 家庭版和 LTSC 是创建 ISO 时会剔除的版本；其他为会保留的版本示例。版本名称与简体中文版 Windows 显示的一致。
iso-failed-edition = 此 ISO 不包含受支持的 Windows 版本。不支持 Windows 家庭版和 LTSC 版本。请使用包含其他版本（例如专业版、教育版或企业版）的 ISO。
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows 无法打开 ISO。请重启电脑，然后重试。
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows 在打开 ISO 时停止响应。请重启电脑，然后重试。
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows 无法在这台电脑上打开 ISO 文件，因为它所需的驱动程序 vdrvroot 和 cdrom 已被禁用。请重新启用它们，重启电脑，然后重试。
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows 无法打开此 ISO，因为该文件已压缩、已加密或为稀疏文件。请将其复制到未压缩且未加密的文件夹，然后使用该副本。
# 打开 ISO 或 U 盘任务原始日志所在的文件夹。
iso-diagnostics = 打开日志文件夹
# Atlas 从其他页面更新 Windows 或还原 Windows 更新设置期间，显示在 ISO 和 U 盘页面上。完成前，这两个页面上的控件不可用。
iso-locked = Atlas 正在处理 Windows 更新。完成后即可在此继续。
# Windows 需要重启时所设置标记的名称。它们用于补全“电脑需要重启才能完成更新的安装（…）”；请保持简短。
prepare-reason-servicing = Windows 组件服务
prepare-reason-windows-update = Windows 更新
prepare-reason-file-renames = 等待替换的文件
prepare-reason-update-agent = Windows 更新服务
prepare-reason-unknown = 未报告原因
# prepare-failed-title 下方，旁边是“重试”。
prepare-failed-retry = 如果重试没有帮助，请在 Windows 更新或 Microsoft Store 中完成剩余的更新。
# 更新卡片上错误栏的标题；原因是其消息。
prepare-failed-title = 部分更新未能完成
# prepare-unconfirmed-title 下方：更新运行结束但没有写入任何结果，例如在运行期间关闭了 Atlas。
prepare-unconfirmed = 更新在报告结果之前已停止。
# 未报告失败，因此不称为失败。
prepare-unconfirmed-title = 无法确认更新结果
prepare-affected-app = 受影响的应用
# 商店应用因处于打开状态而无法更新。$app 为其名称，例如 NanaZip，或 prepare-affected-app。
prepare-close-app = 请关闭 { $app }，然后重试。如果找不到它，请在任务管理器中关闭它。
prepare-install-busy = 其他安装或待完成的重启阻止了更新。请等待其他安装完成，如果 Windows 要求重启，请重启电脑，然后重试。
# Atlas 自己修复组件存储 (DISM) 后，更新仍因 0x80073712 失败。按钮为 prepare-restart-and-retry；重启后更新会自动继续。
prepare-components-damaged-title = Windows 无法自行修复
prepare-components-damaged = Windows 报告存在阻止更新安装的损坏。重启可能会清除它，登录后 Atlas 会继续。
prepare-restart-and-retry = 重启并重试
# Windows 记录了无法修复的组件存储损坏，因此 Atlas 在任何更新之前停止。唯一的按钮为 iso-open。
prepare-components-unrepairable-title = Windows 损坏严重，无法更新
prepare-components-unrepairable = 请备份文件，然后使用 Atlas ISO 重新安装 Windows。
# 更新进程报告的原因。进程自己的英文消息会作为详细信息显示在下方。
prepare-failed-session-owner = Atlas 正在以与当前 Windows 登录账户不同的账户运行。请使用管理员账户登录 Windows，从该账户打开 Atlas，然后重试。
prepare-failed-store-missing = 你的账户尚未设置好 Microsoft Store。请打开一次 Microsoft Store（如果找不到，请重新安装），然后重试。
prepare-failed-store-battery = Microsoft Store 为节省电量暂停了更新。请将电脑接通电源，然后重试。
prepare-failed-store-network = Microsoft Store 已暂停更新，需等电脑使用未设为按流量计费的连接后才会继续。请连接未设为按流量计费的 Wi-Fi 或以太网，然后重试。
prepare-failed-store-timeout = 商店应用尚未完成更新。请在 Microsoft Store 中完成剩余的下载，然后重试。
prepare-failed-store-passes = Microsoft Store 不断提供新的更新。请在 Microsoft Store 中完成剩余的更新，然后重试。
prepare-failed-manual-updates = 部分更新需要在 Windows 更新中完成。请打开 Windows 更新，完成这些更新，然后重试。
prepare-failed-windows-passes = Windows 更新不断提供新的更新。请在 Windows 更新中完成剩余的更新，然后重试。
prepare-failed-windows-update-unreachable = Windows 更新无法连接到 Microsoft 的服务器。请检查 Internet 连接以及防火墙、代理或 VPN 设置，然后重试。
# Atlas Manager 位于链接到其他位置的文件夹（联接或符号链接）中。Atlas 会继续使用打开它的文件夹，因此在同一窗口中重试没有帮助。
prepare-failed-source-linked = Atlas Manager 位于链接文件夹中。请关闭 Atlas，将 Atlas Manager 移到这台电脑上的本地文件夹，然后从那里打开它。
prepare-error-code = 错误代码：{ $code }
prepare-open-store = 打开 Microsoft Store
prepare-windows-search = 正在检查 Windows 更新…
prepare-percent = 此阶段已完成 { $percent }%
prepare-count = 已完成的更新：{ $completed } / { $total }
prepare-bytes = 已下载 { $downloaded } MB，总量约 { $total } MB
prepare-progress-still = 已有 { $minutes } 分钟没有进度。大型更新可能需要较长时间，请保持 Atlas 打开。
prepare-report-late = Windows 已有一段时间未报告进度。更新可能仍在运行，请保持 Atlas 打开。
prepare-windows-download = 正在下载 Windows 更新…
prepare-windows-install = 正在安装 Windows 更新…
# DISM 修复 Windows 组件存储期间（在更新之前，或更新因此失败之后），进度条下方是 prepare-windows-repair-detail。DISM 不报告进度。
prepare-windows-repairing = 正在修复 Windows…
prepare-windows-repair-detail = Windows 报告存在可能导致更新无法安装的损坏。这可能需要半小时或更长时间。
prepare-store-search = 正在检查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其应用…
prepare-stop = 停止更新
prepare-start = 检查并安装更新
# Atlas 安装包仍在下载或解压时，显示在“安装权限”检查项下方。
prepare-wait-for-package = Atlas 安装包就绪后即可使用。
iso-username = 本地账户名
# 本地账户名下方：首次登录时 Windows 会要求设置密码。
iso-account-help = 首次登录时，你需要设置密码。
iso-username-placeholder = 你的名字
# 本地账户名为空时，显示在不可用的“继续”按钮旁边。
iso-account-empty = 请输入本地账户名以继续
# 请原样保留符号列表：Windows 不允许账户名包含这些符号。
iso-account-invalid = 最多可使用 20 个字符，开头和结尾不能有空格，且不能包含以下字符：" / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = 名称不能以句点 (.) 结尾。
iso-account-reserved = Windows 已将此名称用于内置账户。请选择其他名称。
# ISO 上的应答文件会隐藏这些 Windows 安装程序页面。
iso-terms-in-setup = Windows 安装程序会请你接受许可条款。
prepare-drivers = 如何安装驱动程序？
prepare-drivers-auto = 通过 Windows 更新获取驱动程序
# 同一答案作为单选按钮的标签，在做出选择的位置使用。
prepare-drivers-auto-recommended = 通过 Windows 更新获取驱动程序（推荐）
prepare-drivers-auto-detail = Windows 会为你的硬件查找驱动程序。
prepare-drivers-manual = 自行安装驱动程序
prepare-drivers-manual-detail = Windows 更新不会安装驱动程序，因此你需要从电脑或设备制造商处获取。已安装的驱动程序会保留。
# “配置”步骤的驱动程序卡片：ISO 中这台电脑的网卡驱动程序，然后是登录后 Atlas Manager 应用的选择（以 prepare-drivers 询问）。
iso-drivers-card = 驱动程序
iso-network-drivers = 包含这台电脑的 Wi-Fi 和以太网驱动程序
# 第三个驱动程序答案，也是它在“创建”步骤中的值：“准备”步骤会在新电脑上询问。
iso-drivers-defer = 登录后选择
prepare-network-unmetered = 更新需要未设为按流量计费的 Internet 连接。请连接 Wi-Fi 或以太网，然后重试。
# 已连接，但 Windows 发现无法访问 Internet（强制登录门户，或 DNS、防火墙过滤）。
prepare-network-limited = Windows 报告此网络无法访问 Internet。如果网络要求登录，请先登录；或者检查路由器以及 DNS 或防火墙过滤设置，然后重试。
# “按流量计费的连接”是 Windows 网络设置中开关的名称。
prepare-network-metered = 此连接按流量计费或设置了数据限制。请连接未设为按流量计费的网络，或在网络设置中关闭“按流量计费的连接”，然后重试。
prepare-network-settings = 打开网络设置
iso-stage-network-drivers = 准备网卡驱动程序
# iso-complete 下方：请求包含这台电脑的网卡驱动程序，但网卡使用 Windows 自带的驱动程序，因此未添加任何驱动程序。
iso-network-inbox = 这台电脑的网卡使用 Windows 自带的驱动程序，因此 ISO 无需包含它们。
desktop-setup-description = 请完成电脑设置。你的 Atlas 选择已保存，需要时可以返回 Windows。
desktop-setup-exit = 在 Windows 中继续

# Windows 安装 U 盘
usb-title = 创建 U 盘
usb-existing = 从现有 ISO 创建 U 盘
# 驱动器卡片的标题，也是未报告名称的驱动器的名称。
usb-drive = USB 驱动器
# 用于创建 U 盘的 ISO 所在卡片的标题。
usb-iso-title = Windows ISO
# 未提供 ISO，且“下载”中没有名称以“Atlas”开头的 ISO。
usb-iso-missing = “下载”文件夹中没有 Atlas ISO。
usb-iso-checking = 正在检查 ISO…
# 检查 ISO 的结果。检查在清空任何内容之前进行，因此都不提及驱动器。
usb-iso-not-usable = Atlas 无法用此 ISO 创建 U 盘。请使用 Atlas 创建的 ISO，或来自 Microsoft 且版本受 Atlas 支持的 Windows 11 ISO。
# 链接文件夹指向其他位置（联接或符号链接）。
usb-iso-location = ISO 或 Atlas Manager 位于网络位置或链接文件夹中。请将其移到这台电脑上的文件夹，例如“下载”。
# 拆分较大的 Windows 映像需要 Windows 所在驱动器上的空间。Atlas 每 30 秒重新检查一次。
usb-working-space = Windows 所在驱动器的可用空间不足，无法准备此 ISO。请释放一些空间，Atlas 会自动重新检查。
# 由于其他原因（例如文件损坏）无法读取 ISO。
usb-iso-unreadable = Atlas 无法读取此 ISO。请重试，或使用其他 ISO。
# 打开 Windows 设置中的“存储”页面，可在其中释放空间。
usb-open-storage = 打开存储设置
usb-looking = 正在查找 USB 驱动器…
# $size 为整数 GB，按驱动器标称容量计算。
usb-connect = 请连接容量为 { $size } GB 或以上的 USB 驱动器。
# 无法使用的驱动器下方，位于其容量和盘符之后：原因。$size 为整数 GB。
usb-drive-too-small-needs = 容量太小。需要 { $size } GB 或以上。
usb-drive-too-small-iso = 容量太小，无法容纳此 ISO
usb-drive-has-iso = 你的 ISO 位于此驱动器
usb-drive-has-app = Atlas Manager 正在从此驱动器运行
# 驱动器的标称容量，与 Windows 显示的容量不同。$size 为整数 GB，或 TB 数（文本）。
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# 连接驱动器的容量和盘符，以及 ISO 名称下方的体系结构和大小。
usb-detail-separator = { " · " }
usb-create = 创建 U 盘
# 列出多个驱动器且未选中任何一个时，显示在不可用的“创建 U 盘”旁边。
usb-hint-pick = 请先选择一个 USB 驱动器
# 清空前的确认问题。$drive 为驱动器名称；$size 为 usb-drive-size 或 usb-drive-size-tb；$letters 为盘符，例如“F:”或“F:, G:”。
usb-confirm-title-letters = 要清空 { $drive }（{ $size }，{ $letters }）吗？
usb-confirm-title = 要清空 { $drive }（{ $size }）吗？
# 未报告名称的驱动器的同一问题。
usb-confirm-title-unnamed-letters = 要清空 U 盘（{ $size }，{ $letters }）吗？
usb-confirm-title-unnamed = 要清空 U 盘（{ $size }）吗？
usb-confirm-message = 其中的所有内容都将被永久删除。你的 ISO 会保留。
usb-confirm-erase = 清空并创建
usb-progress-title = 正在创建 U 盘…
# $percent 为整数。
usb-percent = { $percent }%
# 创建 U 盘的各个阶段，以检查清单形式显示在 usb-progress-title 下方。
usb-stage-prepare-files = 准备文件
usb-stage-formatting = 格式化
usb-stage-copying = 复制文件
usb-stage-checking = 检查驱动器
usb-stage-ejecting = 弹出
usb-keep-open = 请保持 Atlas 打开，并保持 U 盘连接。
usb-scan-failed-title = 无法列出 USB 驱动器
usb-scan-failed-retry = Atlas 无法读取连接到这台电脑的驱动器。请重试。
# U 盘错误栏的标题，以及完成页面的标题。
usb-failed-title = 无法创建 U 盘
usb-complete-title = U 盘已就绪
# F12、F11 和 Esc 为按键名称。
usb-ready = 请拔出 U 盘，备份要重装系统的电脑上的文件，然后从 U 盘启动该电脑。启动菜单通常可以按 F12、F11 或 Esc 打开。
# 可能已开始清空驱动器之后。
usb-failed-partial = 驱动器已被部分写入。请检查它是否已连接，然后重试。
# 驱动器尚未发生任何更改之前。
usb-failed-before-erase = Atlas 在更改驱动器之前已停止。请重试。
# 清空前，驱动器与列表不再一致：已被移除、重新连接或更换。Atlas 会重新读取列表，如果驱动器回来了，会再次选中它。
usb-drive-changed-title = U 盘已发生变化
usb-drive-changed = 在 Atlas 清空它之前，它已被移除或重新连接，因此其中的内容没有任何更改。
usb-drive-cancelled-title = 已取消创建 U 盘
usb-cancelled-partial = U 盘尚未创建完成。请重新创建后再使用。
usb-cancelled-unchanged = 你的 USB 驱动器未被更改。
usb-eject-failed-title = 未能弹出 U 盘
usb-eject-failed-ready = U 盘已可使用。请关闭正在使用它的文件或窗口，然后重试。
# 带“以管理员身份重新打开”的消息栏标题。消息为 usb-admin-reason；Windows 拒绝重新打开后为 usb-elevation-declined。
usb-elevation-title = Atlas 需要权限才能创建 U 盘
usb-admin-reason = Atlas 需要管理员权限才能清空并写入驱动器。
usb-elevation-declined = Windows 未授予 Atlas 权限，因此暂时无法写入 U 盘。
# 家庭版、LTSC 和 Server 是检查会拒绝的版本；其他为检查接受的版本示例。版本名称与简体中文版 Windows 显示的一致。
detail-edition-unsupported = 不支持 Windows 11 家庭版、LTSC 和 Server 版本。请使用其他版本，例如专业版、教育版或企业版。如果 Windows 无法识别你的版本，请先解决此问题再继续。
install-source-title = 无法安装
install-source-unsupported = Atlas { $source } 无法直接更新到 { $target }。要使用此版本，请备份文件并重新安装 Windows。
# 尚未选择安装包，因此还不知道可用的版本。
install-source-unsupported-any = Atlas { $source } 无法直接更新。要使用较新的版本，请备份文件并重新安装 Windows。
# $folder 为文件夹路径（文本）。
install-source-resume-package = Atlas { $target } 的安装未完成，只有 Atlas { $target } 安装包才能完成该安装。请打开该 Atlas 安装包 (.atlaspkg)。如果它是由 Atlas 下载的，则位于 { $folder } 中。
# 测试版：只能安装内置的 Atlas 安装包。
install-source-resume-bundled = Atlas { $target } 的安装未完成。此测试版只能安装其内置的 Atlas 安装包，因此请在 Atlas Manager 正式版中使用 Atlas { $target } 安装包完成该安装。
# 同时提供“发送报告”和“导出诊断信息”。
install-source-unconfirmed = Atlas 无法确认这台电脑上已安装了什么，因此暂时不会安装任何内容。
# 这台电脑上有 Atlas 的文件，但没有完成安装的记录。旁边提供“创建 Atlas ISO”（iso-open）。
install-source-unrecorded = 这台电脑上有早期版本 Atlas 的文件，但没有完成安装的记录，因此无法更新。要安装 Atlas，请备份文件并重新安装 Windows。
# “创建”步骤中版本下方，Windows 安装程序询问要安装哪个版本时显示。
iso-edition-selection = 请在 Windows 安装程序中选择你拥有许可证的版本。
detail-windows-preview = 不支持 Insider 预览版本。请使用 Windows 11 的正式发布版本。
detail-windows-release-unknown = Atlas 无法确认此 Windows 内部版本是否已正式发布。请连接 Internet 后重新检查。
# $build 为这台电脑的 Windows 内部版本和更新号，例如 26300.9807（文本）。
detail-windows-release-not-listed = 内部版本 { $build } 不在 Microsoft 的 Windows 11 正式发布版本列表中，因此 Atlas 暂时无法在其上安装。不支持 Release Preview 和其他预览版本。等 Microsoft 将此内部版本列入列表后，请重新检查。


prepare-continue = 继续更新
prepare-saving-restart = 正在保存你的选择，并设置在 Windows 重新启动后打开 Atlas…
prepare-restart-save-failed = 无法保存你的选择。请在重新启动前重试。
prepare-restart-registration-failed = 你的选择已保存，但 Atlas 无法设置为在重启后重新打开。请重试，或自行重启电脑，并在登录后打开 Atlas。
# 与 prepare-failed-source-linked 原因相同，在设置重启时遇到。
prepare-restart-source-linked = 你的选择已保存，但 Atlas Manager 位于链接文件夹中时，Atlas 无法设置为在重启后重新打开。请关闭 Atlas，并将 Atlas Manager 移到这台电脑上的本地文件夹。然后从那里打开它，或自行重启电脑，并在登录后从那里打开它。
prepare-restart-failed = Atlas 无法重启电脑。请重试，或从“开始”菜单重启。你的选择已保存，登录后 Atlas 会重新打开。
diagnostics-export = 导出诊断信息
# 导出期间显示在加载图标旁边，也在收集诊断信息时显示在“发送报告”页脚中。
diagnostics-exporting = 正在收集诊断信息…
# 帮助链接行的辅助功能名称：report-title、diagnostics-export 和 iso-diagnostics。
diagnostics-help-a11y = 获取帮助
# 导出后结果栏的标题；其按钮为 iso-open-folder。
diagnostics-saved = 诊断信息已保存
# diagnostics-saved 下方。$file 为 ZIP 文件名，$folder 为其所在文件夹的名称“Diagnostics”（均为文本，不翻译）。
diagnostics-saved-in-folder = 已保存为 { $file }，位于 Atlas 的 { $folder } 文件夹中。
# diagnostics-saved 下方。准确说明导出时删除的内容，请保留每一项。
diagnostics-saved-privacy = Atlas 已从中删除你的用户名、电脑名称、电子邮件地址以及已知的密码或密钥。
# 导出失败时单独显示的消息栏。按钮为 common-try-again，原始错误在“显示详细信息”中。
diagnostics-save-failed = 无法保存诊断 ZIP

## 测试版（内置安装包功能）

# 候选发布版本上内容顶部的消息栏。
rc-banner = Atlas { $release } 测试版。此应用只安装内置的 Atlas 安装包。
home-status-bundled = 测试版 { $release }
package-bundled = 此测试版内置的 Atlas { $version } 已就绪，可以安装。
rc-about-release = 测试版
rc-about-commit = 源代码提交
rc-about-package = 内置 Atlas 安装包 (SHA-256)
iso-package-bundled = 此测试版内置的 Atlas 安装包

check-user-account = 用户账户
detail-user-account-ok = UAC 已启用，你的账户已准备好进行安装。
detail-user-account-not-ready = 请启用用户账户控制 (UAC)，重启电脑后再试。如果你使用的是内置 Administrator 账户，请使用另一个管理员账户登录。
detail-user-account-work-or-school = 无法从工作或学校账户 (Microsoft Entra ID) 安装 Atlas。请使用本地账户或 Microsoft 账户登录，然后重试。
detail-user-account-check-failed = Atlas 无法检查你的用户账户。请重启电脑，然后重新打开 Atlas 并重新检查。Windows 报告：{ $error }

footer-prepare-required = 请完成 Windows 和商店应用的更新以继续
# “阶段”同 prepare-close-stops-after-stage。
footer-prepare-stopping-stage = 将在当前阶段完成后停止更新…
resume-choices-title = 继续上次安装
# “你的选择”上的消息栏，位于未完成的安装所使用的选择上方；这些选择会显示但无法更改。
resume-choices-held = Atlas 会使用你上次做出的选择来完成那次安装，因此在完成之前无法更改这些选择。

## 自愿报告
report-title = 发送报告
report-received = 报告已收到
# 报告参考编号下方，参考编号单独一行并带“复制”按钮。
report-reference = 如果你就此报告联系 Atlas 团队，请保留此参考编号。如果你留下了联系方式，团队可能会通过它回复你，但不保证一定回复。
# 参考编号旁“复制”按钮的辅助功能名称。
report-copy-reference = 复制报告参考编号
report-another = 再发送一份报告
# 在两类报告之间进行选择的标签。
report-kind = 你想发送哪类内容？
report-kind-issue = 问题
report-kind-suggestion = 建议
report-message = 你的消息
# 消息框为空时显示的占位文字，按报告类型区分。
report-message-placeholder-issue = 发生了什么？你当时在做什么？
report-message-placeholder-suggestion = 你希望改进什么？
# 消息框下方，也会随消息框一起朗读。
report-message-help = 请勿包含密码。
# 消息或联系方式接近报告服务接受的最大长度时，显示在其下方。$count 和 $max 为数字。
report-character-count = { $count } / { $max } 个字符
report-contact = 联系方式（可选）
report-contact-placeholder = 电子邮箱或 Discord 用户名
report-attach = 附加诊断信息
# “附加诊断信息”下方。属于用户同意的隐私声明：准确说明 Atlas 删除和保留的内容，请保留每一项。
report-attach-description = 有助于查找原因的日志和系统详细信息。Atlas 会删除你的用户名、电脑名称、电子邮件地址以及已知的密码或密钥。错误详细信息、硬件型号和应用名称会保留。发送前，你可以检查 ZIP。
report-review = 检查 ZIP
# 无法准备诊断信息时的消息栏。按钮为 common-try-again，原始错误在“显示详细信息”中。
report-prepare-failed-title = 无法准备诊断信息
report-prepare-failed-advice = 请重试，或不附带诊断信息发送。
# 用户同意的隐私声明（与 report-attach-description 一起）。更改它需要在应用、报告服务和网站中同时更新 PRIVACY_VERSION。
report-privacy = 你的报告会私密发送给 reports.atlasos.net 上的 Atlas 团队。你的消息和联系方式会按原样发送。团队可能会使用其他公司的 AI 服务协助调查。这些服务会获得你的消息和诊断信息，但不会获得你的联系方式。报告会在 90 天后删除，服务器安全日志可能会记录你的 IP 地址。
report-website = 隐私与报告网站
report-consent = 我同意将此报告及附带的诊断信息发送给 Atlas 团队
# “报告未发送”下方。页脚按钮为 common-try-again；report-not-sent-outdated 时为 report-failed-website，消息栏按钮为 manager-download。
report-not-sent-retry = 请检查 Internet 连接，然后重试。你也可以通过报告网站发送。
report-not-sent-busy = 报告服务繁忙。请等待几分钟，然后重试。
report-not-sent-outdated = 此版本的 Atlas Manager 无法发送报告。请将你的消息复制到报告网站；如果附加了诊断信息，请一并附上 ZIP。
report-not-sent-diagnostics = 无法发送诊断信息。请重试，或不附带诊断信息发送。
# 此版本无法发送时的页脚按钮。
report-failed-website = 打开报告网站
# 报告发送期间，显示在页脚加载图标旁边。
report-sending = 正在发送…
report-send = 发送报告

# 消息过短或过长时显示在消息框下方。$min 和 $max 为数字：报告服务接受的消息长度。
report-validation-message = 请输入 { $min }–{ $max } 个字符。

# 联系方式框下方。$max 为数字：报告服务接受的联系信息最大长度。
report-validation-contact = 请将联系信息限制在 { $max } 个字符以内。

# 未勾选同意复选框就选择“发送报告”时显示在其下方。
report-validation-consent = 请确认你同意发送此报告。

report-failed-title = 报告未发送

## Windows 版本更新
# Atlas 在安装前通过 Windows 更新将 Windows 更新到较新的版本。
# $release 为目标版本（26H2），$current 为电脑当前的版本（24H2）；按 Microsoft 的写法在前面加“Windows 11 版本”。
# $version 为 Atlas 版本。

# 主页上更新按钮下方，更新同时会更新 Windows 时显示：列出更新两部分的卡片。home-plan-name 为该列表的辅助功能名称。
home-plan-files = 你的文件和应用都会保留。
home-plan-name = 此次更新分为两部分
home-plan-windows-title = Windows 11 版本 { $release }
home-plan-windows-step = Atlas 会通过 Windows 更新安装此版本，然后电脑会重启。
# 同一步骤，更新 Windows 为可选时。
home-plan-windows-step-ask = 可选。Atlas 会先征求你的同意，然后通过 Windows 更新安装此版本，之后电脑会重启。
# Windows 更新完成后，代替该步骤的说明。
home-plan-step-installed = 已安装。
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas 会更新并保留你的选择，然后电脑会重启。
# $date 和 $until 为日期。
home-end-of-updates-title = Windows 11 版本 { $current } 将于 { $date } 停止获得安全更新
home-end-of-updates-past-title = Windows 11 版本 { $current } 已不再获得安全更新
home-end-of-updates-message = 更新到 Atlas { $version } 时，这台电脑也会更新到 Windows 11 版本 { $release }，该版本的安全更新将持续到 { $until }。
# 消息栏下方有列出更新两部分的卡片时，代替 home-end-of-updates-message。
home-end-of-support-plan = Windows 11 版本 { $release } 的安全更新将持续到 { $until }。

# 主页：此 Windows 完全无法安装该 Atlas 版本。$product 为 Windows 对该版本的名称，例如 Windows 11 家庭版。
install-windows-edition-only = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版，因此无法安装在 { $product } 上。
# 同上，当前版本的安全更新即将结束，带“打开 Windows 更新”。$date 为日期。
install-windows-edition-until = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版，因此无法安装在 { $product } 上。Windows 11 版本 { $current } 的安全更新将持续到 { $date }，Windows 更新可以将这台电脑更新到较新的版本。
# 同上，该日期已过。
install-windows-edition-ended-update = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版，因此无法安装在 { $product } 上。版本 { $current } 已不再获得安全更新，因此即使不使用 Atlas，也请更新 Windows。
# 在 LTSC 版本上代替 install-windows-edition-only：Windows 为这类版本起的名称带有年份，看起来像是 Windows 版本号。
install-windows-edition-ltsc = Atlas { $version } 适用于 Windows 11 专业版、企业版和教育版。不支持 LTSC 版本。
# $releases 列出受支持的版本，例如“25H2 或 26H2”。
install-windows-reinstall = Atlas { $version } 需要 Windows 11 版本 { $releases }，而 Windows 更新无法将这台电脑更新到该版本。请备份文件，然后使用 Atlas ISO 重新安装 Windows。
# 同上，用于主页：创建 Atlas ISO 的卡片在前，并说明如何重新安装。
home-windows-no-path = Atlas { $version } 需要 Windows 11 版本 { $releases }，而 Windows 更新无法将这台电脑更新到该版本。

# 主页：Atlas 为更新更改了 Windows 更新设置，但尚未还原。按钮为 home-put-back。
home-update-access-title = Windows 更新设置已因 Atlas 更新而更改
# 更新 Windows 的更新正在进行时，显示在 home-update-access-title 下方。
home-update-access-put-back-later = 更新完成后，Atlas 会还原这些设置。
# 上次检查时尚未提供该版本。
home-update-access-waiting = Atlas 已开启 Windows 更新，以便将这台电脑更新到 Windows 11 版本 { $release }，但 Windows 更新尚未提供该版本。
home-update-access-updating = Atlas 已开启 Windows 更新来安装更新，但尚未完成。
# Atlas 无法读取其更改设置的记录时，代替 home-update-access-title。
home-update-access-unreadable-title = 无法读取 Atlas 的 Windows 更新记录
# 下方是“发送报告”和“导出诊断信息”；原始错误在“显示详细信息”中。
home-update-access-unreadable-problem = Atlas 无法读取它更改 Windows 更新设置时留下的记录，因此不会更改或还原任何设置。
# 因其他原因还原设置失败时显示在消息栏下方。“还原设置”会重试；原始错误在“显示详细信息”中。
home-put-back-failed = Atlas 无法还原这些设置。
# 暂时无法还原 Atlas 更改的 Windows 更新设置的原因：未完成的 Atlas 安装或更新会在其最后阶段还原这些设置。
# 显示在主页（此期间隐藏“还原设置”）、还原失败时的关闭确认中，以及“准备”步骤的 Windows 版本选择下方。
# “阶段”指安装过程中的阶段，不是四个流程步骤之一。
update-access-finish-install = 请先完成 Atlas 的安装。安装的最后阶段会还原 Atlas 更改过的 Windows 更新设置。
home-continue-update = 继续更新
home-put-back = 还原设置
home-putting-back = 正在还原设置…

# “准备”步骤：更新到较新 Windows 版本的卡片，位于页面最上方。标题为 windows-card-title，其下一行说明进展。
windows-card-title = Windows 11 版本 { $release }
# Atlas 安装包需要此次更新时，同意之前显示在标题下方。
windows-required = Atlas { $version } 不支持版本 { $current }，因此 Atlas 会先更新 Windows。
# 更新为可选时，显示在标题下方。
windows-optional = Atlas 支持这两个版本。
# 该选择的辅助功能名称；两个答案会说明内容。
windows-card-question = 这台电脑应使用哪个版本的 Windows？
windows-choice-move-recommended = 更新到 Windows 11 版本 { $release }（推荐）
# $date 为新版本停止获得安全更新的日期。
windows-choice-move-support = 安全更新持续到 { $date }。
windows-choice-keep = 保留 Windows 11 版本 { $current }
windows-choice-keep-later = 保持在版本 { $current }。你以后可以通过 Atlas Manager 更新。
windows-card-facts = 会有哪些变化
windows-fact-files = 你的文件和应用都会保留。更新撤销的任何更改，Atlas 都会重新应用。
windows-fact-time = 通常需要几分钟，最长 2 小时，之后需要重启。
# 在“显示详细信息”中，仅在当前版本仍包含这些组件的电脑上显示。
windows-fact-removes = 会移除 Windows PowerShell 2.0 和 WMIC。
# 更新为可选时，打开 Atlas 文档中关于撤销此次更新的页面。
windows-undo-link = 如何撤销此更新
# windows-accept 之前：接受条款和开始更新是同一个选择。
windows-terms-line = 更新即表示你接受 Microsoft 软件许可条款。
windows-terms-link = 阅读许可条款
windows-accept = 接受并更新
# 接受条款后、更新自动开始之前。
windows-starting = 正在开始…
windows-starts-after-checks = 检查通过后开始。
windows-starts-after-package = Atlas { $version } 就绪后开始。
# 更新后，Windows 通过重新安装自身来启用新版本时。
windows-rebuilt = 版本 { $release } 重置了 Atlas 的部分更改。Atlas { $version } 会按你之前的选择重新应用这些更改。
# 更新开始后、保留此版本之前提出的问题；消息为 stop-update-before，按钮为 common-cancel 和 prepare-keep-version。
windows-keep-title = 要保留 Windows 11 版本 { $current } 吗？


# 列出 Atlas 为更新开启的每项 Windows 更新设置的消息栏。
access-notice-title = Atlas 会暂时开启 Windows 更新
access-off = 这台电脑上的 Windows 更新已关闭。Atlas 在更新 Windows 期间会将其重新开启。
access-paused = 这台电脑上的 Windows 更新已暂停。Atlas 在更新 Windows 期间会取消暂停。
access-delayed = 这台电脑上的每月更新已推迟。Atlas 在更新 Windows 期间会取消推迟。
# 位于以上各行之后。
access-back = Atlas { $version } 安装完成后，这些设置会改回原来的状态。
access-back-stop = 如果你在此之前停止，Atlas 会还原这些设置。

prepare-reason-feature-update = 新的 Windows 版本
prepare-reason-feature-commit = 完成新 Windows 版本的安装
# 等待 Windows 更新提供新版本：进度条的标签和状态行、进度条下方的一行，以及已等待的整数分钟数。
windows-waiting = 正在等待 Windows 更新提供 Windows 11 版本 { $release }…
windows-waiting-detail = 通常需要几分钟，最长 2 小时。Atlas 会自动继续，你可以继续使用电脑。
windows-waited =
    { $minutes ->
       *[other] 已等待 { $minutes } 分钟。
    }
# 重新检查 2 小时后仍未提供。按钮为 common-try-again 和 iso-open。
windows-wait-ended-title = Windows 更新未在 2 小时内提供版本 { $release }
windows-wait-ended = Atlas 已还原你的设置。请稍后重试，或使用 Atlas ISO 重新安装 Windows。
# 还原设置失败时代替上一条消息。按钮为 home-put-back；原始错误在“显示详细信息”中。
windows-wait-put-back-failed = Atlas 无法还原你的 Windows 更新设置。
# Windows 无法让新版本在重启时完成，因此电脑没有重启。“重试”会再次重启。
windows-commit-failed-title = Windows 未能做好重启准备
windows-commit-failed = 电脑没有重启。请重试。

# 更新 Windows 的各种结果，每种都有标题和下一步操作。只有 Atlas 团队能排查的原因以 report-title 为按钮；ISO 能解决的以 iso-open 为按钮。
windows-outcome-not-offered-title = Windows 更新尚未提供版本 { $release }
windows-outcome-not-offered = 最长可能需要 2 小时。你的电脑仍是版本 { $current }。
windows-outcome-hardware-title = 这台电脑不满足 Windows 11 的要求
# $missing 列出这台电脑缺少的硬件，取自以下两条消息。
windows-outcome-hardware = 它缺少 { $missing }，因此 Windows 更新不会提供版本 { $release }。请备份文件，然后使用 Atlas ISO 重新安装 Windows。
hardware-tpm = TPM 2.0
hardware-uefi = UEFI 固件
windows-outcome-hidden-title = 版本 { $release } 已在 Windows 更新中被隐藏
windows-outcome-hidden = 请使用你隐藏它时所用的工具重新显示它，然后重试。
windows-outcome-disk-space-title = 可用空间不足
# $needed 和 $free 为整数 GB；$drive 为驱动器，例如 C:。按钮为 check-fix-storage；Atlas 会自动重新读取可用空间。
windows-outcome-disk-space = Windows 需要 { $drive } 上有 { $needed } GB 可用空间，当前只有 { $free } GB。空间足够后，Atlas 会自动继续。
windows-outcome-managed-title = 这台电脑从其组织获取更新
windows-outcome-managed = 其更新服务器不提供版本 { $release }，因此 Atlas 未做任何更改。请联系你的组织，或使用 Atlas ISO 重新安装 Windows。
windows-outcome-policy-title = Windows 更新设置不断被改回
# $setting 为 Windows 更新策略值的技术名称，例如 NoAutoUpdate，原样显示。
windows-outcome-policy = Atlas 更改 { $setting } 后，它会被改回，因此 Atlas 无法更新 Windows。如果这台电脑由组织管理，请联系该组织。
# $service 为 service-* 名称，放在固定短语之后，无需与句子搭配。按钮为 common-try-again 和 prepare-open-services。
windows-outcome-service-off-title = 服务已被禁用：{ $service }
windows-outcome-blocked-service = Windows 更新需要此服务。请在“服务”中将其启动类型设为“手动”，然后重试。
windows-outcome-blocked-title = 有设置阻止 Windows 更新运行
windows-outcome-blocked = 一项并非由 Atlas 更改的设置阻止了它运行：{ $setting }。请更改此设置，然后重试。
windows-outcome-rollback-title = Windows 无法完成版本 { $release } 的安装
windows-outcome-rolled-back = 它已回退到版本 { $current }。你的文件和应用不受影响。
windows-outcome-components-lost-title = Atlas 的部分更改已丢失
windows-outcome-components-lost = Atlas 无法判断原因，因此在安装 Atlas { $version } 之前停止了。
windows-outcome-build-title = Windows 版本在更新期间发生了变化
windows-outcome-build = 请还原 Atlas 更改的设置，然后从“主页”重新开始。
windows-outcome-journal-title = Atlas 无法读取此次更新的记录
windows-outcome-journal = 在 Atlas 团队查看之前，Atlas 不会更改或还原任何内容。
windows-outcome-pin-title = 无法记录某项 Windows 更新策略
# $setting 为 Windows 更新策略值的名称，例如 TargetReleaseVersionInfo。
windows-outcome-pin = Atlas 之后无法还原 { $setting } 的当前值，因此未做任何更改。
windows-outcome-terms-title = 尚未接受许可条款
windows-outcome-terms = Windows 更新需要你先接受许可条款，才能安装版本 { $release }。
windows-outcome-failed-title = Windows 无法安装版本 { $release }
windows-outcome-failed = 你的电脑仍是版本 { $current }。
# 更新所需的 Windows 服务，与“服务”列表中的名称一致（简体中文版 Windows 显示英文名称）。
service-bits = Background Intelligent Transfer Service (BITS)
service-cryptsvc = Cryptographic Services
service-trusted-installer = Windows Modules Installer
prepare-open-services = 打开“服务”
# 在 windows-keep-title 问题中确认保留此版本。
prepare-keep-version = 保留版本 { $current }

# 在 Windows 更新设置已更改的情况下退出更新前提出的问题。
stop-update-title = 要停止更新到 Atlas { $version } 吗？
# 首次安装或重新安装时的 stop-update-title，到目前为止只更新了 Windows。
stop-update-title-windows = 要停止更新 Windows 吗？
stop-update-before = Atlas 会还原它更改过的 Windows 更新设置。Windows 已安装的更新会保留，你的电脑仍使用 Windows 11 版本 { $current }。
stop-update-after = 你的电脑会保留 Windows 11 版本 { $release }。Atlas 会还原它更改过的 Windows 更新设置。
stop-update-access = Atlas 会还原它更改过的 Windows 更新设置。Windows 已安装的更新会保留。
stop-update-keep = 继续更新
# 为更新而开启 Windows 更新期间关闭窗口时显示的对话框；按钮为 window-close-keep 和 window-close-put-back。
window-close-update-access-title = 要关闭 Atlas 吗？
window-close-update-access-message = 关闭前，Atlas 会还原它更改过的 Windows 更新设置。你可以稍后从“主页”重新开始更新。
window-close-put-back = 还原并关闭
# 关闭前还原设置失败时。先显示原因，然后是此消息；按钮为 window-close-keep 和 window-close-close。
window-close-put-back-failed-title = 要在不还原设置的情况下关闭吗？
window-close-put-back-failed-message = 如果现在关闭 Atlas，Windows 更新设置会保持 Atlas 更改后的状态。重新打开 Atlas 后，“主页”会提供还原这些设置的选项。

# 电脑检查：Atlas 需要从当前版本更新 Windows 时的“Windows 兼容性”。更新卡片会说明更新进展。
detail-build-needs-release = 此版本的 Atlas 需要 Windows 11 版本 { $release }，而这台电脑是版本 { $current }。

# 关于未完成的 Windows 更新的报告开头几行；之后是英文技术详细信息。
report-transition-intro = 为 Atlas 更新 Windows 的过程未完成。供 Atlas 团队参考的详细信息：

# Windows 在更新到较新版本时重新安装了自身，而不是就地启用新版本。Atlas 随后会重新应用其所有更改。
history-mode-rebase = Windows 更新后重新安装
# Windows 在更新期间重新安装自身后的“你的选择”，此时会沿用之前 Atlas 的选择。
rebase-choices-title = 你在 Atlas { $previous } 中的选择
rebase-choices-kept = Atlas 会重新应用你为 Atlas { $previous } 做出的选择。之后，你可以通过重新安装 Atlas 来更改它们。
# 记录中没有答案的问题上方，“你的选择”只询问这些问题。
rebase-choices-asked = Atlas 会重新应用你为 Atlas { $previous } 做出的其他所有选择。
# 有其他用户登录这台电脑时，Atlas 重启前提出的问题。按钮为 restart-others-keep（默认）和 restart-others-restart。
restart-other-question = 要在另一位用户已登录时重启吗？
restart-others-question = 要在其他用户已登录时重启吗？
# $names 列出这些用户的账户名称，例如“Alex和Sam”；$count 为人数。
restart-others-signed-in =
    { $count ->
       *[other] 以下用户也已登录：{ $names }。重启会关闭其应用，未保存的工作将会丢失。
    }
restart-others-keep = 不重启
restart-others-restart = 仍要重启
# Microsoft Store 本身（在商店应用之前）：更新或修复它时“准备”步骤的状态行；修复期间进度条下方是 prepare-store-repair-detail。
prepare-store-updating = 正在更新 Microsoft Store…
prepare-store-repairing = 正在修复 Microsoft Store…
prepare-store-repair-detail = 这可能需要几分钟。
# “准备”步骤完成后、Microsoft Store 已关闭时，显示在 ready-updates-done-windows 下方。
prepare-store-skipped-removed = 这台电脑上的 Microsoft Store 已关闭，因此商店应用未更新。
# Atlas 的修复都没能让 Microsoft Store 正常工作。按钮为 prepare-repair-store-again；prepare-store-broken-iso 和 iso-open 在“显示详细信息”中。
prepare-store-broken-title = Microsoft Store 无法正常工作
prepare-store-broken = Atlas 无法修复它，现在安装 Atlas 可能会导致商店应用无法使用。
prepare-store-broken-iso = 如果修复一直失败，请备份文件，然后使用 Atlas ISO 重新安装 Windows。
prepare-repair-store-again = 再次尝试修复
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows 无法更新内置应用
prepare-store-staging = Windows 未能安装以下内置应用的更新，Atlas 的修复也没有解决问题：{ $apps }。{ prepare-components-unrepairable }

screen-keyboard-title = 键盘语言
screen-keyboard-question = 你使用多种键盘语言吗？
package-option-keyboard-shortcuts = 是，使用键盘快捷键
package-option-keyboard-selector = 是，使用任务栏选择器
package-option-keyboard-single = 否，只使用一种键盘布局
consequence-keyboard-shortcuts = Alt+Shift 切换语言；Ctrl+Shift 切换布局。
consequence-keyboard-selector = 关闭 Alt+Shift 和 Ctrl+Shift，避免游戏时意外切换。
package-choice-keyboard-description = 选择切换键盘语言的方式。
consequence-keyboard-single = { consequence-keyboard-selector }
