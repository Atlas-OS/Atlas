### Atlas Manager: Chinese (Traditional) (zh-Hant), preview translation. Revised 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Serves zh-TW, zh-HK and zh-MO. Terminology follows Microsoft's Taiwan
### Windows glossary (設定, 系統管理員, 重新啟動, 檔案, 資料夾, 網路, 電腦).
### Full-width punctuation; one space between Chinese and Latin words or
### numbers. "重新開啟 Atlas" is reopening the app (and 重新開啟 also turns a
### protection back on); "重新啟動" is only restarting the PC / Windows. Chinese has only the "other" plural
### category; exact [1]/[2] variants are allowed. A count that is only selected on, never shown,
### keeps its select with *[other] (plus [1] where the wording differs).
### The .atlaspkg file is the "Atlas 套件" (套件 alone once that is clear). Controls named in text are quoted
### with 「」 using their exact label from this catalog.
### - ISO steps: Windows, 安裝設定, 建立. Windows Setup, the installer, is Windows 安裝程式.
### - A USB drive is "USB 磁碟機" everywhere (磁碟機 once clear), never 隨身碟.
### - A switch Atlas can't read is 無法讀取; 檢查 is checking.
### - "Go to <step>" is 前往「…」; "Windows 11, version 25H2" is "Windows 11 版本 25H2".
### - Settings' Help is 說明, privacy is 隱私權, and Storage settings is 「儲存體」設定.

## Shared

app-name = Atlas Manager
common-done = 完成
common-cancel = 取消
common-back = 上一步
common-next = 繼續
common-dismiss = 關閉
# Link beside a summary row that jumps back to change that choice.
common-change = 變更
common-copy = 複製
# Shown where a list of options is empty.
common-none = 無
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = 返回首頁
# Accessible name of the gear button in the title bar.
common-settings = 設定
common-close-settings = 關閉設定
common-open-windows-security = 開啟 Windows 安全性
common-restart-as-administrator = 以系統管理員身分重新開啟 Atlas
common-try-again = 再試一次
common-read-the-docs = 閱讀 Atlas 使用指南
common-show-details = 顯示詳細資料
common-hide-details = 隱藏詳細資料
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }，{ $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = 開啟記錄資料夾
# Accessible name of the Copy button beside the install log.
common-copy-install-log = 複製安裝記錄
common-install-log = 安裝記錄
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas 套件
common-checking = 檢查中
# Joins two items in a list: "Brave、Firefox". The braces keep the literal.
list-separator = { "、" }
# Joins two alternatives: "26100 或 26200".
list-or = { $a } 或 { $b }
# Joins the last two items of a list: "竄改防護和雲端提供的保護".
# $a may itself be several items joined with list-separator.
list-and = { $a }和{ $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }。{ $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = 要在 Atlas 安裝期間關閉視窗嗎？
window-close-installing = 安裝會繼續進行。重新開啟 Atlas 即可查看結果。
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = 安裝會繼續進行，但電腦不會自動重新啟動。重新開啟 Atlas 即可查看結果。
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = 保持開啟
window-close-close = 關閉視窗
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = 要在安裝前停止嗎？
window-close-checks-unchanged = 安裝尚未進行任何變更。如果您關閉視窗，安裝就不會開始。
window-close-keep-installing = 繼續安裝
window-close-stop-and-close = 停止並關閉
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = 要停止更新嗎？
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas 會在目前階段完成後停止。屆時您就可以關閉 Atlas。
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = 要重新啟動以完成 Atlas 設定嗎？
window-close-restart-closed = Atlas 關閉後就無法重新啟動您的電腦。請先儲存您的工作。
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = 要重新啟動以完成更新嗎？
window-close-update-restart-later = 請先儲存您的工作。如果您稍後再重新啟動，Atlas 會在重新啟動後繼續。
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = 要在防護關閉的狀態下關閉 Atlas 嗎？
window-close-protection-all = 四個 Windows 安全性防護開關都已關閉。如果您現在不安裝 Atlas，請先將它們重新開啟。
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
        [1] Windows 安全性中的{ $switches }已關閉。如果您現在不安裝 Atlas，請先將它重新開啟。
       *[other] Windows 安全性中的{ $switches }已關閉。如果您現在不安裝 Atlas，請先將它們重新開啟。
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = 要停止建立 ISO 嗎？
iso-close-safe-point = Atlas 會在下一個可安全停止的時間點停止。
usb-close-question = 要停止建立 USB 磁碟機嗎？
usb-close-unfinished = 未完成的磁碟機無法用來安裝 Windows。
window-close-keep-creating = 繼續建立
window-close-stop = 停止
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = 開啟 Atlas 套件（.atlaspkg）
# Message Windows shows in its restart notification.
shutdown-comment = Atlas 已安裝完成。Windows 即將重新啟動以完成設定。
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas 正在重新啟動 Windows，以完成更新的安裝。

## System

# "Windows 11 Pro 25H2（組建 26200.1234）". All three values are text.
system-description = { $product } { $version }（組建 { $build }）

## Home page

home-not-installed = 歡迎使用 Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas 可減少 Windows 中的背景活動和干擾。
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = 這台電腦上的 Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = 安裝於 { $date }
home-status-checking = 正在檢查更新…
# While startup checks whether another window's installation is running.
home-status-recovering = 正在檢查是否有進行中的安裝
home-status-offline = 無法檢查更新
home-status-not-checked = 尚未檢查更新
home-status-update = Atlas { $version } 已推出
home-status-up-to-date = 已是最新版本
home-status-newest = 最新版本：Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Atlas { $version } 尚未安裝完成
home-check-again = 再次檢查
# Primary button while an install is running or waiting.
home-show-install = 檢視進度
home-continue-installing = 繼續設定
home-update-to = 更新至 Atlas { $version }
home-reinstall = 重新安裝 Atlas
home-install = 安裝 Atlas
home-finish-install = 完成安裝 Atlas { $version }
home-start-over = 重新開始
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = 要在這台電腦上安裝 Atlas 嗎？
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = 您現有的應用程式和設定可能無法正常運作，而且 Atlas 會移除 OneDrive，因此其中的檔案將停止同步，資料夾也可能看起來是空的。請先備份您的檔案。
home-used-windows-install = 仍要安裝
# The card that opens ISO creation; its button is iso-open.
home-iso-title = 使用 Atlas 重新安裝 Windows
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = 這台電腦上的 Windows 已使用一段時間，而 Atlas 最適合全新安裝的 Windows。
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = 您的電腦需要重新啟動
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas 無法重新啟動您的電腦。請從「開始」功能表重新啟動。
home-security-reminder-title = 請重新開啟防護
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = 請確認防護已開啟
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [1] Windows 安全性中的這個開關仍處於關閉狀態：{ $switches }。
       *[other] Windows 安全性中的這些開關仍處於關閉狀態：{ $switches }。
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas 無法讀取所有防護開關。請在 Windows 安全性中確認下列項目已開啟：{ $switches }。
home-elevation-title = Atlas 需要權限才能安裝
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas 無法儲存您的設定選擇，因此尚未重新開啟。
home-state-error-title = 無法讀取 Atlas 的安裝資訊
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = 您的 Atlas 版本、選擇和安裝歷程可能無法正確顯示。
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager 需要更新
home-whats-new = Atlas { $version } 的新功能
home-view-release = 在 GitHub 檢視版本資訊
home-show-less = 顯示較少
home-show-full-notes = 顯示完整版本資訊
home-your-install = 您的 Atlas 設定
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = 這台電腦未記錄 Atlas 的安裝方式，因此無法顯示您的選擇與安裝歷程。
home-history = 安裝歷程
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = 步驟 { $number }：{ $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }。{ $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = 設定流程
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = 正在設定 Atlas
# Beside step-ready in that card.
home-step-ready = Atlas 會檢查您的電腦並更新 Windows。
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas 會檢查您的電腦，並將 Windows 更新至版本 { $release }。
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = 由您決定要保留哪些項目，例如 Microsoft Defender。
# Beside step-security in that card.
home-step-security = 由您手動關閉四個 Windows 安全性防護開關。
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
       *[other] 安裝通常約需 { $minutes } 分鐘，之後電腦會重新啟動。
    }
home-step-install-restart-yourself =
    { $minutes ->
       *[other] 安裝通常約需 { $minutes } 分鐘，之後請重新啟動電腦。
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = 應用程式可能會關閉，電腦也會重新啟動，因此請先儲存您的工作。
home-github = 在 GitHub 檢視 Atlas 專案
home-discord = 加入 Atlas 的 Discord 社群
home-report-problem = 回報問題

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = 首次安裝
history-mode-upgrade = 更新
history-mode-reapply = 重新安裝
history-mode-unknown = 安裝

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas 正在使用預設的應用程式設定
notice-settings-unreadable-problem = Atlas 無法讀取已儲存的應用程式設定。您的 Windows 設定未受影響。
notice-settings-damaged-kept-problem = 您的應用程式設定檔已損毀，因此 Atlas 已將其重設，並保留了舊檔案的副本。
notice-settings-damaged-problem = 您的應用程式設定檔已損毀。Atlas 目前使用預設值。
notice-settings-not-saved-title = 無法儲存應用程式設定
notice-settings-not-saved-problem = Atlas 無法儲存您最近的變更，關閉 Atlas 後這些變更可能會遺失。如果還開著另一個 Atlas 視窗，請將其關閉，然後重新進行變更。
notice-session-unreadable-title = 無法確認上次的安裝狀態
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas 無法判斷先前的安裝是否仍在進行。如果您確定沒有，請刪除其安裝狀態檔案，然後重新開啟 Atlas。
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas 無法判斷先前的安裝是否仍在進行。如果您不確定，請向 Atlas 社群求助。只有在確定沒有安裝正在進行時，才可刪除 { $path } 並再試一次。詳細資料：{ $error }

## Administrator elevation

elevation-declined = 尚未取得權限。請再試一次，並在 Windows 詢問是否允許 Atlas 變更您的裝置時選擇「是」。
elevation-declined-continue = 尚未取得權限。請再試一次，並在 Windows 詢問是否允許 Atlas 變更您的裝置時選擇「是」。您的設定選擇已儲存。
elevation-draft-not-saved = Atlas 無法儲存您的設定選擇，因此尚未重新開啟。請再試一次。詳細資料：{ $error }
# Shown with the home-start-over button.
elevation-taken-over = 另一個 Atlas 視窗已接手這次設定，因此 Atlas 尚未重新開啟。請在該視窗中繼續，或選擇「重新開始」在這裡重新設定。

## The install flow

step-ready = 準備
step-options = 您的選擇
step-security = Windows 安全性
step-install = 安裝
install-title = 設定 Atlas
# Accessible name of the row of steps.
stepper-label = Atlas 設定步驟
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }，{ $status }
stepper-status-completed = 已完成
stepper-status-current = 目前步驟
stepper-status-upcoming = 尚未進行
# A step already visited whose requirements aren't met yet.
stepper-status-attention = 需要留意
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }。{ $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = 檢查您的電腦
# Status line while the checks run.
ready-checks-running = 正在檢查您的電腦…
ready-check-again = 再次檢查
# Status line once every check passed; common-show-details lists them.
ready-checks-passed = 已通過 { $count } 項檢查
# Status line when some checks need attention, which are listed under it.
ready-checks-passed-some = 已通過 { $passed } / { $total } 項檢查
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of.
ready-checks-handled = { $count } 項會在更新時處理
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = 更新時會處理
# Under the title of a check that updating takes care of.
check-updates-handled = 有更新正在等待安裝。Atlas 會在更新 Windows 時安裝。
check-restart-handled = Windows 需要重新啟動，才能完成先前的變更。更新時會處理此項。
check-handled = 更新時會處理此項。
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = 正在下載…
ready-package-unpacking = 正在解壓縮…
ready-package-ready = 就緒
ready-package-checking = 正在檢查最新版本…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = 正在準備內建的 Atlas 套件…
ready-package-none = 尚未下載
ready-package-failed = 無法取得 Atlas 套件
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = 請重新下載，或開啟其他 Atlas 套件（.atlaspkg）。
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = 無法解壓縮此測試版內建的 Atlas 套件。請再試一次。
ready-package-manager = 需要較新版本的 Atlas Manager
ready-package-release-failed = 無法檢查最新版本
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = 請檢查網際網路連線，然後再試一次。如果您有 Atlas 套件（.atlaspkg），也可以改為開啟它。
# Row title.
ready-updates-title = Windows 和 Microsoft Store 更新
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = 記事本等市集應用程式可能會在更新時關閉。請先儲存您在其中的工作。
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = 會在 Windows 更新至版本 { $release } 後開始。
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = 重新啟動完成，正在繼續…
ready-updates-restarting = 正在重新啟動您的電腦…
ready-updates-done = Windows 和市集應用程式都已是最新狀態。
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows 已是最新狀態。
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown = 您的電腦將在 { $seconds } 秒後重新啟動。
ready-updates-restart = 您的電腦需要重新啟動，才能完成更新。
ready-updates-restart-finish = Windows 需要再重新啟動一次，才能完成版本 { $release } 的安裝。
ready-updates-restart-failed = 您的電腦沒有重新啟動
# Under the restart's status line, before Restart now.
ready-updates-restart-save = 請先儲存您的工作。
ready-updates-restart-persists = Windows 仍要求重新啟動
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = 再次重新啟動很可能沒有幫助。請完成 Windows Update 中所有等待中的項目，然後再試一次。
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = 重新啟動原因：{ $reasons }
ready-updates-network = 更新無法使用此連線
ready-updates-stopped = 更新已停止。部分更新可能已經安裝。
ready-updates-previous = 正在等待先前開始的更新…
# Button after the user stopped updating.
ready-updates-resume = 繼續更新
ready-updates-start = 開始更新
# Why updating hasn't started, under the row.
ready-updates-blocked = 更新會等到 Atlas 可在這台電腦上安裝後才開始。
ready-updates-needs-admin = Atlas 取得系統管理員權限後開始。
ready-updates-needs-windows = Windows 相容性檢查通過後開始。
ready-updates-needs-drivers = 您決定驅動程式的安裝方式後開始。
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = 驅動程式：{ $choice }
ready-drivers-automatic = 透過 Windows Update
ready-drivers-manual = 自行安裝
ready-drivers-change-a11y = 變更驅動程式的安裝方式
# Under the two answers, once updating has run.
ready-drivers-again = 變更此選項會重新執行更新。

# $received and $total are formatted numbers of megabytes (text).
package-downloading = 正在下載 Atlas { $version } · { $received } / { $total } MB
package-unpacking = 正在解壓縮
package-status-ready = 就緒
# Accessible name of the progress bar.
package-progress = Atlas 套件進度
package-download-again = 重新下載
package-download-version = 下載 Atlas { $version }
package-download-newest = 下載最新版本
package-cancel-download = 取消下載
package-open-file = 開啟套件檔案
# Where the package came from. $file is a file name (text).
package-from-release = 已從 GitHub 下載 Atlas { $version }，可以安裝。
package-from-file = 已從 { $file } 載入 Atlas { $version }，可以安裝。
package-unpacked = Atlas { $version } 已可安裝。
package-none-yet = 尚無 Atlas 套件
acquire-no-asset = Atlas { $version } 沒有可下載的套件檔案。請開啟已儲存的 Atlas 套件（.atlaspkg）以繼續。
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = 這個應用程式可透過 Atlas 套件（.atlaspkg）安裝 Atlas 0.6.0 及更新版本。
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = 這是 Windows ISO，不是 Atlas 套件（.atlaspkg）。若要使用 Atlas 重新安裝 Windows，請用它建立 Atlas ISO。
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } 缺少這個應用程式進行安裝所需的檔案。請重新下載，或開啟其他 Atlas 套件（.atlaspkg）。
acquire-failed = 無法準備 Atlas 套件。請重新下載，或開啟其他 Atlas 套件（.atlaspkg）。詳細資料：{ $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = 下載已停止回應。請檢查網際網路連線，然後重新下載，或開啟已儲存的 Atlas 套件（.atlaspkg）。
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = 無法準備內建的 Atlas 套件。請選擇「再試一次」。詳細資料：{ $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = 此 Atlas 套件需要較新版本的 Atlas Manager。請下載並改用 Atlas Manager { $version } 或更新版本。
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = 此 Atlas 套件需要較新版本的 Atlas Manager。請下載並改用最新版本的 Atlas Manager。
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = 若要安裝 Atlas { $version }，請下載並改用 Atlas Manager { $required } 或更新版本。
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = 若要安裝 Atlas { $version }，請下載並改用最新版本的 Atlas Manager。

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = 下載 Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } 已推出
manager-update-message = Atlas Manager 無法自行更新。請下載並改用新版本。

## System checks

check-administrator = 安裝權限
check-supported-build = Windows 相容性
check-pending-updates = Windows 更新
check-pending-reboot = 待處理的重新啟動
check-third-party-antivirus = 其他防毒軟體
check-internet = 網際網路連線
check-power = 電源
check-activation = Windows 啟用
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Windows 11 硬體
check-move-space = 可用空間
check-move-update-source = 更新來源
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }：{ $state }
check-state-checking = 檢查中
check-state-passed = 已通過
check-state-warning = 需要留意
check-state-failed-blocking = 安裝前需要處理
check-state-failed = 需要留意
check-state-unknown = 無法檢查
check-fix-windows-update = 開啟 Windows Update
check-fix-network = 開啟網路設定
check-fix-power = 開啟電源設定
check-fix-activation = 開啟「啟用」設定
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = 開啟「儲存體」設定
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = 開啟「已安裝的應用程式」
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = 我已查看 Windows Update，沒有等待安裝的更新

detail-admin-ok = Atlas 已具備進行安裝變更所需的權限。
detail-admin-missing = 請以系統管理員身分重新開啟 Atlas，並在 Windows 要求權限時選擇「是」。
# $builds is a list of build numbers such as "26100 或 26200"; $build is this PC's (text).
detail-build-unsupported = 這個 Atlas 版本需要 Windows 組建 { $builds }，而這台電腦的組建為 { $build }。請先安裝支援的 Windows 版本再繼續。
detail-build-missing = 這個 Atlas 套件未列出任何支援的 Windows 組建。請使用完整組建的套件，而非 LocalTest 組建。
detail-updates-none = 沒有等待安裝的 Windows 更新。
# Updates still waiting once updating has run. $count is how many.
detail-updates-left = 仍有 { $count } 個更新等待安裝。請在 Windows Update 中安裝，然後再次檢查。
detail-updates-scan-failed = 無法檢查 Windows 更新。請開啟 Windows Update，查看是否有等待安裝的更新。（{ $error }）
detail-reboot-none = Windows 目前不需要重新啟動。
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows 需要重新啟動，才能完成先前的變更。請重新啟動電腦，然後再次檢查。
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows 需要重新啟動，才能完成先前的變更（{ $reasons }）。請重新啟動電腦，然後再次檢查。
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = 您可以繼續。Windows 有檔案要在下次重新啟動時取代或移除（{ $files }）。部分應用程式（例如 Xbox Gaming Services）每次重新啟動後都會如此。
detail-reboot-unknown = 無法確認 Windows 是否需要重新啟動。請重新啟動電腦，然後重新開啟 Atlas 並再次檢查。（{ $error }）
detail-antivirus-none = 未偵測到其他防毒軟體。
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Microsoft Defender 以外的防毒應用程式可能會阻擋安裝。請解除安裝 { $products }，然後再次檢查。
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows 安全性仍列出 { $products }，但其檔案已不存在，因此它已不再安裝於電腦上。Atlas 仍可繼續安裝。
detail-antivirus-check-failed = 無法檢查是否有其他防毒軟體。如果持續發生，請重新啟動電腦，然後再次檢查。（{ $error }）
detail-internet-ok = 已連線。Atlas 下載並安裝軟體期間，請保持網路連線。
detail-internet-missing = 請連線到網際網路，然後再次檢查。
detail-power-mains = 電腦已接上電源。安裝完成前請保持連接。
detail-power-battery = 請將電腦接上電源，讓它在整個安裝期間保持開機。
detail-power-check-failed = Atlas 無法判斷您的電腦是否已接上電源。如果是筆記型電腦，請接上電源，然後再次檢查。
detail-activation-ok = Windows 已啟用。Atlas 不會變更啟用狀態。
detail-activation-missing = Windows 尚未啟用。您可以繼續，但 Atlas 不會為您啟用 Windows。
detail-activation-no-licence = Windows 未回報授權。您可以繼續；Atlas 不會變更您的啟用狀態。
detail-activation-unknown = 無法檢查 Windows 啟用狀態。您可以繼續；Atlas 不會變更您的啟用狀態。（{ $error }）
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas 不需要將這台電腦的 Windows 更新至較新的版本。
detail-move-hardware-ready = 這台電腦具備 Windows 11 所需的 TPM 2.0 和 UEFI 韌體。
detail-move-hardware-missing = 這台電腦沒有 { $missing }，因此 Windows Update 不會將它更新至版本 { $release }。請備份您的檔案，然後使用 Atlas ISO 重新安裝 Windows。
detail-move-hardware-unread = Atlas 無法讀取這台電腦的所有硬體資訊，因此會由 Windows Update 檢查。
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } 有 { $free } GB 可用空間。
detail-move-space-short = 版本 { $release } 需要 { $drive } 上有 { $needed } GB 可用空間，目前只有 { $free } GB。請釋放空間，Atlas 會自動再次檢查。
detail-move-space-unknown = 無法檢查 Windows 更新所需的可用空間。請重新啟動電腦，然後再次檢查。（{ $error }）
detail-move-update-source-ok = 這台電腦從 Windows Update 取得更新。
detail-move-update-source-managed = 這台電腦從所屬組織的伺服器取得更新，而該伺服器不提供版本 { $release }。請洽詢您的組織，或使用 Atlas ISO 重新安裝 Windows。

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = 您之後可以從桌面上的 Atlas 資料夾變更 Microsoft Defender、處理器防護和更新設定。
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = 未選取任何項目
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = 已選取 { $count } 項
# Links that unfold and fold the Optional extras card.
options-extras-show = 顯示
options-extras-hide = 隱藏
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender 是 Windows 內建的防毒軟體。
question-mitigations-description = 這些防護（也稱為安全性緩和措施）可抵禦 Spectre 和 Meltdown 等處理器漏洞，以及利用應用程式錯誤的攻擊。
question-auto-updates-description = 無論選擇哪一種，Atlas 都會讓 Windows 維持在目前的版本，並關閉 Microsoft Store 應用程式的自動更新。
question-browser-description = Atlas 不會變更您的瀏覽器設定。
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = 在您安裝其他防毒軟體之前，電腦將沒有防毒保護，Windows 也不會在您開啟無法辨識的應用程式或下載的檔案前發出警告。
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = 這也會關閉應用程式的「惡意探索保護」（例如控制流程防護），因而降低安全性。
cost-auto-updates-disable = 請定期開啟 Windows Update 以取得安全性修正。
cost-auto-updates-default = Windows 可能會重新啟動您的電腦，以完成更新的安裝。
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift 和 Ctrl+Shift 將不再切換語言或配置。
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = 可釋放磁碟空間，但休眠與快速啟動將無法使用。
extra-disable-power-saving = 電腦可能耗電更多、溫度更高，電池續航力也可能縮短。
extra-disable-core-isolation = 這會降低防護，使用 Riot Vanguard 或 FACEIT 等反作弊系統的遊戲，可能要在您重新開啟記憶體完整性後才能啟動。
extra-uninstall-edge = 會刪除這台電腦上 Edge 的「我的最愛」、歷程記錄和已儲存的密碼，已同步到 Microsoft 帳戶的資料除外。
extra-install-toolbox = 協助您管理 Atlas 設定。測試階段期間，部分功能可能尚未完成。
extra-install-eclean = AtlasOS 團隊打造的工具，可檢查垃圾檔案和啟動應用程式，需要帳戶和網際網路連線。
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = 要保留 Microsoft Defender 嗎？
screen-mitigations-title = 處理器防護
screen-mitigations-question = 要保留 Windows 的處理器防護嗎？
screen-updates-title = Windows Update
screen-updates-question = Windows 該如何安裝更新？
screen-browser-title = 瀏覽器
screen-power-title = 電源與安全性
screen-apps-title = 應用程式
screen-optional-apps-title = 選用應用程式
screen-choose-one-title = 選擇一個選項
screen-extras-title = 選用項目
# Each decision's short name in the middle of a sentence, as in summary-change-a11y and
# update-path-differs. Write it as the language does mid-sentence: in English, product names
# keep their capitals and other names are lower case.
screen-update-path-name = Atlas 更新方式
screen-defender-name = Microsoft Defender
screen-mitigations-name = 處理器防護
screen-updates-name = Windows Update
screen-keyboard-name = 鍵盤語言
screen-browser-name = 瀏覽器
screen-power-name = 電源與安全性
screen-apps-name = 應用程式
screen-optional-apps-name = 選用應用程式
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = Atlas 套件中的一項選擇
screen-extras-name = 選用項目
# Question for a required choice this app has no specific wording for.
screen-generic-question = 請為「{ $title }」選擇一個選項
learn-more-defender = 深入了解 Microsoft Defender
learn-more-mitigations = 深入了解處理器防護
learn-more-updates = 深入了解 Windows Update
learn-more-browser = 深入了解瀏覽器
learn-more-power = 深入了解電源與安全性
learn-more-apps = 深入了解應用程式
learn-more-eclean = 深入了解 eclean
learn-more-keyboard = 深入了解鍵盤語言
learn-more-generic = 閱讀設定指南
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = 保留 Windows 內建的防毒軟體，協助保護電腦免受病毒與其他威脅。
consequence-mitigations-default = 保留 Windows 的預設防護，抵禦處理器漏洞，以及利用應用程式錯誤的攻擊。
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = 同時會關閉應用程式的「惡意探索保護」，例如控制流程防護（CFG）。這會降低安全性。效能差異視您的處理器而定。
consequence-auto-updates-disable = 請定期開啟 Windows Update 安裝更新。更新通知仍會顯示。
consequence-auto-updates-default = Windows 會自動安裝更新，包括安全性修正。

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = 您要如何更新至 Atlas { $version }？
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = 您要如何重新安裝 Atlas { $version }？
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = 保留我的選擇
update-path-keep-detail = Atlas 會依這台電腦目前的設定保留每一項選擇，不做任何變更。
update-path-choose = 重新選擇
update-path-choose-detail = 從這台電腦目前的設定開始。您的應用程式、檔案和個人化設定都會保留。
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = 您在這台電腦上目前的選擇
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = Atlas 無法從您的電腦判斷這一項，因此會詢問您
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = 這台電腦的下列項目與 Atlas 的記錄不符：{ $choices }。
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas 會依這台電腦目前的設定保留其他所有選擇。
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = 這台電腦目前的設定
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas 會恢復 Microsoft Defender。重新啟動後，請在 Windows 安全性中開啟它的防護。
change-mitigations-default = Atlas 會依 Windows 的預設值重新開啟處理器防護。重新啟動後生效。
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = 目前所有處理器防護都已開啟。保留防護會讓它們全部維持開啟。
change-auto-updates-default = Atlas 會讓 Windows 重新自動安裝更新。
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas 會重新開啟休眠。
change-power-saving-on = Atlas 會重新開啟省電功能，並改回您先前的電源計劃；如果沒有，則改用「平衡」。
change-core-isolation-on = Atlas 會重新開啟虛擬化型安全性（VBS），除非這台電腦上有原則控制此項。重新啟動後生效。
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = 為這台電腦上的所有使用者移除剪取工具。Atlas 之後無法將它恢復，但您可以從 Microsoft Store 重新安裝。
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge 已移除，更新 Atlas 無法將它恢復。若要重新安裝，請使用 Atlas 資料夾中的「Install or Remove Edge」。
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } 已安裝。Atlas 不會解除安裝應用程式；若要移除，請前往 Windows 設定中的「已安裝的應用程式」。
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } 會保留，Atlas 也會安裝 { $browser }。

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = 保留 Microsoft Defender（建議）
package-option-defender-enable-short = 保留 Microsoft Defender
package-option-defender-disable = 移除 Microsoft Defender
package-option-mitigations-default = 保留處理器防護（建議）
package-option-mitigations-default-short = 保留處理器防護
package-option-mitigations-disable = 關閉處理器防護
package-option-auto-updates-disable = 自行安裝更新
package-option-auto-updates-default = 自動安裝更新
package-option-disable-hibernation = 關閉休眠
package-option-disable-power-saving = 關閉省電功能
package-option-disable-core-isolation = 關閉虛擬化型安全性（VBS）
package-option-remove-snipping-tool = 移除剪取工具
package-option-uninstall-edge = 移除 Microsoft Edge
package-option-install-another-browser = 安裝瀏覽器
package-option-install-toolbox = 安裝 Atlas Toolbox
package-option-install-eclean = 安裝 eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender 是 Windows 內建的防毒軟體。只有在您了解風險，並打算使用其他防毒應用程式時，才移除它。無論您選擇哪一項，Atlas 都會關閉「智慧型應用程式控制」、「增強式網路釣魚保護」和「尋找我的裝置」。
package-choice-mitigations-description = 這些防護（也稱為安全性緩和措施）有助於抵禦 Spectre 和 Meltdown 等處理器漏洞，以及利用應用程式錯誤的攻擊。建議保留 Windows 的預設值。
package-choice-auto-updates-description = Windows 更新包含安全性修正。您可以讓 Windows 自動安裝更新，或自行安裝。無論選擇哪一種，Atlas 都會讓 Windows 維持在目前的版本，而該版本只會在 Microsoft 終止支援前收到安全性修正。Atlas 也會關閉 Microsoft Store 應用程式的自動更新，因此請在 Microsoft Store 中更新這些應用程式。
package-choice-browser-description = 選擇要安裝的瀏覽器。Atlas 不會變更您的瀏覽器設定。

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = 這台電腦未安裝 Microsoft Defender
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = 沒有需要關閉的防護開關。
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas 已從這台電腦移除 Microsoft Defender
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas 會在這次安裝中恢復 Microsoft Defender
security-restore-nothing-to-turn-off = Defender 尚未執行，因此沒有需要關閉的項目。重新啟動後，請在 Windows 安全性中開啟它的防護。
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = 找不到 Microsoft Defender
security-banner-missing-message = Microsoft Defender 不是 Atlas 移除的，因此 Atlas 無法將它恢復。您可以繼續，但在您安裝其他防毒應用程式或修復 Windows 之前，電腦將沒有任何防毒保護。
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = 請關閉這四個開關
security-turn-off-message = Microsoft Defender 可能會在安裝期間阻擋 Atlas。如果您保留 Defender，請在安裝後重新開啟這些開關。
# The page name in Windows Security.
security-list-title = 病毒與威脅防護設定
security-switch-off = 關閉
security-switch-on = 開啟
security-switch-unreadable = 無法讀取
security-switch-reading = 檢查中
security-all-off = 全部關閉
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }：{ $state }
# Parts of the summary "2 個仍開啟，1 個無法讀取".
security-count-still-on = { $count } 個仍開啟
security-count-unreadable = { $count } 個無法讀取
security-count-join = { $a }，{ $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. English
# reads the same for one or several; agree with $count where your language needs to.
security-unread-switches-title =
    { $count ->
       *[other] Atlas 無法讀取{ $switches }的狀態
    }
security-unread-message =
    { $count ->
        [1] 請在 Windows 安全性中確認它已關閉。
       *[other] 請在 Windows 安全性中確認它們已關閉。
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
       *[other] 我已確認{ $switches }已關閉
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = 我已檢查 Windows 安全性，四個開關都已關閉
security-unknown-unelevated-title = Atlas 需要權限才能檢查防護狀態
security-unknown-unelevated-message = 請以系統管理員身分重新開啟 Atlas，才能檢查 Microsoft Defender 的設定。
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = 竄改防護
protection-tamper-why = 讓 Atlas 能夠變更安全性設定。
protection-realtime = 即時保護
protection-realtime-reason = 掃描可能會阻擋 Atlas 的檔案。
protection-cloud = 雲端提供的保護
protection-cloud-reason = 線上檢查可能會阻擋 Atlas 的檔案。
protection-samples = 自動提交範例
protection-samples-why = 避免 Atlas 的檔案被傳送給 Microsoft。

## Step 4: Install

outcome-succeeded-title = Atlas 已安裝完成
outcome-lost-title = 無法確認安裝結果
outcome-failed-title = 安裝未完成
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = 您的電腦不符合安裝需求，因此未進行任何安裝變更。
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = 您的電腦不符合安裝需求，因此這次嘗試已停止。先前的嘗試已進行了變更。
# Beside common-restart-as-administrator.
result-not-elevated = Atlas 沒有系統管理員權限，因此未進行任何安裝變更。
result-not-elevated-resumed = Atlas 沒有系統管理員權限，因此這次嘗試已停止。先前的嘗試已進行了變更。
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas 無法確認 Windows 和市集應用程式都已是最新狀態，因此安裝在變更 Windows 前已停止。
result-preparation-stale-resumed = Atlas 無法確認 Windows 和市集應用程式都已是最新狀態，因此這次嘗試已停止。先前的嘗試已進行了變更。
result-failed-preflight = 安裝在進行任何變更前已停止。您可以再試一次。
result-failed-staging = 安裝在準備檔案時停止，尚未變更 Windows。您可以再試一次。
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = 可能已進行部分變更。您可以再試一次；如果要就此停止，請在 Windows 安全性中重新開啟防護開關。
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = 可能已進行部分變更。您可以再試一次。
result-failed-resumed = 這次嘗試提早停止，但先前的嘗試已進行了變更。您可以再試一次；如果要就此停止，請在 Windows 安全性中重新開啟防護開關。
result-failed-resumed-defender-removed = 這次嘗試提早停止，但先前的嘗試已進行了變更。您可以再試一次。
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = 這次嘗試因與上次相同的錯誤而停止，再試一次很可能也沒有幫助。請傳送報告，讓 Atlas 團隊找出原因；如果要就此停止，請重新開啟防護開關。
result-failed-repeated-defender-removed = 這次嘗試因與上次相同的錯誤而停止，再試一次很可能也沒有幫助。請傳送報告，讓 Atlas 團隊找出原因。
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows 仍無法移除 { $apps }，因此再試一次很可能沒有幫助。請傳送報告，讓 Atlas 團隊找出原因；如果要就此停止，請重新開啟防護開關。
result-failed-repeated-apps-defender-removed = Windows 仍無法移除 { $apps }，因此再試一次很可能沒有幫助。請傳送報告，讓 Atlas 團隊找出原因。
result-not-started = 安裝程式未能及時啟動，因此未進行任何安裝變更。您可以再試一次。
result-lost = 安裝程式在回報結果前就已停止，因此可能已進行部分變更。您可以再試一次；如果要就此停止，請在 Windows 安全性中重新開啟防護開關。
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = 安裝程式在回報結果前就已停止，因此可能已進行部分變更。您可以再試一次。
restart-now-message = Windows 正在重新啟動，以完成 Atlas 設定。
restart-stopped = 已取消自動重新啟動。請儲存您的工作，然後重新啟動電腦以完成 Atlas 設定。
restart-needed = 請儲存您的工作，然後重新啟動電腦以完成 Atlas 設定。
restart-dont-now = 稍後重新啟動
restart-now = 立即重新啟動
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = 安裝尚未開始
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = Atlas 需要您回答此項目：{ $choice }。
preflight-choices-unusable = Atlas 無法使用這些選擇。
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
       *[other] 自 Atlas 檢查您的電腦以來，{ $checks }需要留意。
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = 您關閉開關後，Windows 安全性已有變化：{ $summary }。
preflight-busy-wait = 另一個 Atlas 視窗正準備開始安裝。請稍候片刻，然後再試一次。
# Beside home-start-over.
preflight-taken-over-start-over = 另一個 Atlas 視窗已接手這次設定。請在該視窗中繼續，或在這裡重新開始。
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas 無法確認先前的安裝是否仍在進行，因此沒有開始新的安裝。
preflight-not-started = Atlas 無法啟動安裝程式，因此未進行任何安裝變更。您可以再試一次。
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas 無法啟動安裝程式，但先前的嘗試已進行了變更。您可以再試一次。
go-to-ready = 前往「準備」
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = 前往「您的選擇」
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = 前往「Windows 安全性」
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = 返回「安裝」
output-problem-title = 無法讀取安裝進度
install-elevate-title = Atlas 需要權限才能安裝
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Atlas 重新開啟時，Windows 會請您授予權限。
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Atlas 套件尚未就緒
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = 請先完成「準備」
install-not-ready-message = Atlas 需要先檢查您的電腦並更新 Windows，才能開始安裝。
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = 請再次關閉防護開關
install-switches-message = Windows 安全性：{ $summary }。
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = 已準備好安裝
summary-setup-title = 您的 Atlas 設定
summary-activation = 啟用
summary-activation-ok = 已啟用。Atlas 不會變更啟用狀態。
summary-activation-missing = 尚未啟用。您可以繼續，但 Atlas 不會啟用 Windows。
summary-activation-unknown = Atlas 不會變更您的 Windows 啟用狀態。
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts = 通常約需 { $minutes } 分鐘，之後電腦會重新啟動
summary-time-restart-yourself = 通常約需 { $minutes } 分鐘，之後請重新啟動電腦
# The check box on the card. It starts from settings-restart-automatically and applies to this install only.
summary-restart-automatically = 安裝完成後自動重新啟動
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = 一併關閉
summary-turned-off-value = 「智慧型應用程式控制」、「增強式網路釣魚保護」和「尋找我的裝置」
summary-show-command = 顯示安裝命令
summary-hide-command = 隱藏安裝命令
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = 複製安裝命令
summary-command-unavailable = 無法準備安裝命令。詳細資料：{ $error }
summary-not-chosen = 尚未選擇
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = 變更「{ $title }」
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Atlas 更新方式
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = 正在準備安裝
footer-checks-blocked = 請處理檢查發現的問題以繼續
footer-manager-outdated = 請下載較新版本的 Atlas Manager 以繼續
footer-need-files = 請取得 Atlas 套件以繼續
# Tester build variant of footer-need-files.
footer-need-package-bundled = 請準備內建的 Atlas 套件以繼續
footer-drivers = 請決定驅動程式的安裝方式以繼續
footer-windows-terms = 請接受授權條款以繼續
footer-updating = 正在更新 Windows 和市集應用程式…
footer-restart = 請重新啟動電腦以繼續
footer-reading-security = 正在檢查防護開關
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = 請關閉全部四個開關以繼續
footer-security-confirm = 若要繼續，請確認 Atlas 無法讀取的開關
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = 請先儲存您的工作並關閉應用程式
button-install = 安裝 Atlas
log-earlier-lines = 記錄檔中另有較早的 { $count } 行。
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = （完整記錄：{ $path }）

## The installing view

installing-title = 正在安裝 Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = 正在檢查您的電腦…
installing-staging-label = 正在複製 Atlas 的檔案…
installing-applying-label = 正在設定 Windows…
installing-finishing-label = 正在完成…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = 請讓電腦保持開機並接上電源。安裝完成後，電腦會自動重新啟動。
installing-keep-on = 請讓電腦保持開機並接上電源。安裝完成後，請重新啟動電腦。
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = 這不代表安裝已停止。
installing-installed-title = Atlas 已安裝完成
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown = 您的電腦將在 { $seconds } 秒後重新啟動。
installing-restart-save = 請先儲存您的工作。

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } 已安裝完成
installed-title = Atlas 已安裝完成
installed-ready = 一切就緒，您的電腦已可搭配 Atlas 使用。
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = 請向電腦、主機板或裝置製造商取得晶片組、網路和顯示卡驅動程式。
installed-drivers-guide = 開啟驅動程式指南
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = 已移除 Microsoft Defender
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = 它不是 Atlas 移除的。如果您沒有使用其他防毒應用程式，請安裝一個來保護您的電腦。
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender 仍未恢復
defender-not-restored-message = 先前的 Atlas 更新沒有將它恢復，因此 Defender 目前沒有保護您的電腦。請重新安裝 Atlas 並保留 Defender，或執行 Atlas 資料夾中「7. Security > Defender」內的「Toggle Defender」。
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. $choices lists their names, such as "Microsoft Defender", joined with
# list-and. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = 部分選擇未生效
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [1] 這項選擇維持原狀：{ $choices }。
       *[other] 這些選擇維持原狀：{ $choices }。
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Windows Update 已依您的選擇再次關閉
installed-update-off-message = 關閉期間，您的電腦不會收到安全性更新。
installed-update-paused-title = Windows 更新已依您的選擇再次暫停
installed-update-paused-message = 暫停期間，您的電腦不會收到安全性更新。

## Settings

settings-title = 設定
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = 外觀
settings-installation = 安裝
settings-privacy = 隱私權
settings-theme = 應用程式佈景主題
settings-theme-system = 與 Windows 一致
settings-theme-light = 淺色
settings-theme-dark = 深色
settings-theme-contrast-note = Atlas 正在使用您的 Windows 對比佈景主題色彩。
settings-language = 語言
# The setting in the Language section, and its box's name.
settings-app-language = 應用程式語言
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = 與 Windows 一致（{ $language }）

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = 預覽版
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = 此翻譯尚未經過母語人士審閱。
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language }是預覽版翻譯，可能含有錯誤。
preview-notice-switch = 切換為英文
preview-notice-language = 變更語言
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = 這個版本的 Atlas 沒有您選擇的語言，因此顯示英文。您的選擇會保留。
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas 尚未支援您的 Windows 顯示語言，因此顯示英文。
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas 無法檢查您的 Windows 顯示語言，因此顯示英文。
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = 數字、日期與時間會依照您的 Windows 地區格式顯示：{ $locale }。
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = 數字會依照您的 Windows 地區格式顯示：{ $locale }。由於 Atlas 尚無法顯示由右至左的文字，日期與時間會使用標準格式。
settings-language-contribute = 在 GitHub 協助翻譯 Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = 與 Atlas 分享使用狀況資料
settings-share-usage-description = 您開啟的頁面、ISO 建立情形，以及安裝是否成功。
settings-privacy-policy = 隱私權原則
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = 安裝和更新後自動重新啟動
settings-restart-automatically-description = Atlas 完成後一分鐘內，電腦會重新啟動並關閉已開啟的應用程式。
settings-restart-locked = 安裝完成後才能變更這項設定。
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = 說明
settings-about = 關於
settings-about-app = Atlas Manager
settings-about-licence = 授權
settings-about-licence-value = GPL-3.0，自由且開放原始碼
settings-view-source = 在 GitHub 檢視原始程式碼
# Link that opens the third-party licence notices.
settings-view-licences = 檢視授權聲明
# Under the links when Windows could not open the notices.
settings-licences-failed = 無法開啟授權聲明。請再試一次，或在 GitHub 的原始程式碼中查看。
settings-open-data-folder = 開啟應用程式資料夾

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = 釋放休眠時用來儲存工作狀態的磁碟空間。休眠與快速啟動將無法使用。
consequence-disable-power-saving = 關閉省電功能。電腦可能耗電更多、溫度更高，電池續航力也可能縮短。
consequence-disable-core-isolation = 關閉 Windows 的一層額外安全防護，包括記憶體完整性。這會降低防護，使用 Riot Vanguard 或 FACEIT 等反作弊系統的遊戲，可能要在您重新開啟記憶體完整性後才能啟動。
consequence-remove-snipping-tool = 移除用來擷取螢幕畫面與錄製螢幕的 Windows 應用程式。
consequence-uninstall-edge = 移除 Microsoft Edge 瀏覽器。請確認您已有其他瀏覽器，或在下方選擇一個。
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = 會刪除這台電腦上 Edge 的「我的最愛」、歷程記錄和已儲存的密碼。
consequence-install-another-browser = 在下方選擇瀏覽器，Atlas 會為您安裝。
consequence-install-toolbox = 加入 Atlas Toolbox，協助您管理 Atlas 設定。Toolbox 仍在測試階段，部分功能可能尚未完成。
consequence-install-eclean = AtlasOS 團隊打造的維護工具，協助您在設定完成後保持電腦整潔。檢查垃圾檔案和啟動應用程式。需要帳戶和網際網路連線。

## ISO creation
iso-open = 建立 Atlas ISO
iso-title = 建立 Atlas ISO
iso-recommended = 建議
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = 安裝設定
iso-step-create = 建立
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = 這個 ISO 要用於哪台電腦？
iso-target-this = 這台電腦
iso-target-another = 另一台電腦
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = 此 ISO 適用於 { $architecture } 電腦。
iso-source = Windows ISO
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = 從 Microsoft 下載
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Windows 下載
iso-download-language = 語言
iso-download-arch = 架構
iso-download-languages = 正在載入語言…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = 正在下載 Windows 11…
iso-download-amount = { $received } / { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas 無法連線至 Microsoft 的下載服務。請檢查網際網路連線，然後再試一次。
iso-download-incomplete = 下載未完成。請檢查網際網路連線和可用空間，然後再試一次。
iso-download-website = 開啟 Microsoft 下載頁面
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = 選擇 ISO 檔案
# A status pill while the files are checked, before Continue becomes available.
iso-checking = 正在檢查您的 Windows ISO…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = Windows ISO 已就緒，{ $facts }
iso-package-latest-label = 最新版
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = 最新的 Atlas 版本太舊，此 Atlas Manager 無法使用。
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = 正在取得最新的 Atlas…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas 無法檢查最新版本。請檢查網際網路連線，然後再試一次。
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }：{ $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = 請取得 Windows ISO 以繼續
# The question on the Setup step about when the package's choices are made.
iso-mode-question = 您想在何時進行 Atlas 選擇？
iso-mode-after = 登入後
iso-mode-after-description = 登入後，Atlas 會引導您完成設定。
iso-mode-now = 現在
iso-mode-now-description = 選擇會儲存在 ISO 中，登入後再安裝 Atlas。
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = 在進入桌面前完成
iso-mode-before-desktop-description = 登入後，Atlas 會以全螢幕執行，直到安裝完成。
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = 此 Atlas 套件無法將選擇儲存至 ISO，因此請在登入後進行選擇。
iso-atlas-options = Atlas 選擇
# The line at the top of the Create step.
iso-create-intro = 建立 ISO 不會變更這台電腦或您的原始 ISO。
iso-review-package = Atlas 套件
iso-review-output = 新 ISO
iso-review-edition = 版本
iso-review-editions = 版本
iso-edition = Windows 版本
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = 由 Windows 安裝程式詢問
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = 由 Windows 安裝程式詢問
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = 接受 Windows 授權條款，讓 Windows 安裝程式不再詢問
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = 帳戶名稱
iso-review-target = 安裝到
iso-review-drivers = 驅動程式
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows 安裝程式
iso-review-skips = 略過 Microsoft 帳戶和隱私權畫面
iso-review-skips-terms = 略過授權、Microsoft 帳戶和隱私權畫面
iso-review-network = 網路驅動程式
iso-review-network-included = 這台電腦的 Wi-Fi 和乙太網路驅動程式
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = 現在，並在進入桌面前完成
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = 需要 { $needed } · { $drive } 可用 { $free }
iso-destination-short = ISO 需要 { $needed }，而 { $drive } 只有 { $free } 可用。請釋放空間，或將 ISO 儲存到其他磁碟機。
iso-destination-filesystem = { $drive } 無法存放 ISO 中的大型檔案。請將它儲存到格式化為 NTFS 的磁碟機，例如您的 Windows 磁碟機。
iso-destination-unusable = Atlas 只能將 ISO 儲存到這台電腦上磁碟機中的資料夾。
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = 在您儲存到的資料夾中，ISO 中的檔案所需的路徑會超過 Windows 允許的長度。請將新 ISO 儲存到路徑較短的資料夾，例如您 Windows 磁碟機上的資料夾。
iso-create = 建立 ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = 正在建立您的 ISO…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = 正在讀取 Windows ISO
iso-stage-copy = 正在複製 Windows 檔案
iso-stage-add-atlas = 正在加入 Atlas
iso-stage-master = 正在寫入 ISO 檔案
iso-stage-verify = 正在檢查新 ISO
iso-stage-cleanup = 正在進行最後處理
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }，{ $status }
iso-stage-status-current = 進行中
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = 失敗
iso-stage-status-not-started = 尚未開始
iso-progress-keep-open = 完成前請保持 Atlas 開啟。
iso-cancel = 取消建立
iso-cancelling = 正在等待可安全取消的時機
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = 正在取消…
iso-cancelled = 已取消建立 ISO
iso-cancelled-unchanged = 您的原始 ISO 沒有任何變更。
iso-complete = 您的 ISO 已準備就緒
iso-complete-backup = 從此 ISO 重新安裝 Windows 前，請先備份您的檔案。
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = 建立 USB 磁碟機
iso-open-folder = 在資料夾中顯示
iso-failed = 無法完成 ISO 建立
# Under iso-failed, beside Try again.
iso-failed-retry = 請確認您的檔案仍在選取的位置，且要儲存到的磁碟機仍已連接，然後再試一次。
# Title while checking the files fails; the messages below say why.
iso-check-failed = 無法檢查檔案
iso-check-failed-retry = 請確認 ISO 和 Atlas 套件都已下載完成，然後再試一次。
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas 無法準備其工作資料夾，因此沒有進行任何變更。
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = 此 ISO 沒有 Atlas 支援的版本
iso-edition-unsupported = 不支援 Windows Home 和 LTSC。請使用包含 Pro、Education 或 Enterprise 的 ISO。
iso-customised-title = 此 ISO 已經過自訂
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = 此 ISO 由 Atlas 建立
iso-customised = 它已包含安裝檔案（例如 autounattend.xml）。請使用 Microsoft 提供、未經修改的 ISO。
iso-preview-title = 此 ISO 是預覽組建
iso-preview = 它的 Windows 組建不在 Microsoft 的正式發行版本清單中。請使用 Microsoft 提供的 ISO。
iso-windows-unsupported-title = 此 Atlas 套件無法使用這個 ISO
iso-windows-unsupported = 請使用未經修改、且版本受此套件支援的 Windows 11 ISO。
iso-release-unknown-title = Atlas 無法確認此 Windows 版本
iso-release-unconfirmed = Atlas 會將它與 Microsoft 的正式發行版本清單比對。請檢查網際網路連線，然後再試一次。
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = 此 Atlas 套件無法建立 ISO
iso-package-old = 請使用 Atlas { $minimum } 或更新版本。
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = 這是 Windows ISO，不是 Atlas 套件
iso-package-windows-iso = 請改為選擇 Atlas 套件（.atlaspkg），並將此 ISO 選為 Windows ISO。
iso-manager-missing-title = 找不到 Atlas Manager 的檔案
iso-fix-package = 選擇其他套件
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager 需要更新
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas 無法將這台電腦的網路驅動程式加入 ISO。
iso-network-skip = 不含驅動程式繼續建立
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas 需要權限才能建立 ISO
iso-admin-reason = 讀取您的 Windows ISO 並建立新 ISO 時需要此權限。
iso-elevation-declined = Windows 未授予 Atlas 權限，因此目前還無法讀取您的 Windows ISO。
# The free space ran out while the ISO was being created.
iso-failed-space = 目的地磁碟機的可用空間不足。請釋放空間，或將新 ISO 儲存到其他磁碟機。
# Under iso-manager-missing-title.
iso-manager-missing = 請將 AtlasManager.exe 下載到「下載」等本機資料夾，然後從該處開啟。
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = 此 ISO 不包含支援的 Windows 版本。不支援 Windows Home 與 LTSC。請使用包含其他版本（例如 Pro、Education 或 Enterprise）的 ISO。
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows 無法開啟 ISO。請重新啟動電腦，然後再試一次。
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows 在開啟 ISO 時停止回應。請重新啟動電腦，然後再試一次。
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows 無法在這台電腦上開啟 ISO 檔案，因為它所需的驅動程式 vdrvroot 和 cdrom 已停用。請重新啟用它們、重新啟動電腦，然後再試一次。
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows 無法開啟此 ISO，因為該檔案已壓縮、已加密或為疏鬆檔案。請將它複製到未壓縮且未加密的資料夾，然後使用該複本。
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = 開啟記錄資料夾
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas 正在處理 Windows Update。完成後即可在此繼續。
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = Windows 元件服務
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = 等待取代的檔案
prepare-reason-update-agent = Windows Update 服務
prepare-reason-unknown = 未回報原因
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = 如果再試一次沒有幫助，請在 Windows Update 或 Microsoft Store 中完成其餘的更新。
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = 部分更新無法完成
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = 更新在回報結果前就已停止。
# Title of the bar over prepare-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = 無法確認更新結果
prepare-affected-app = 受影響的應用程式
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = 請關閉 { $app }，然後再試一次。如果找不到它，請在工作管理員中將其關閉。
prepare-install-busy = 其他安裝或必要的重新啟動正在阻擋更新。請等待其他安裝完成；如果 Windows 要求重新啟動，請重新啟動電腦，然後再試一次。
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows 無法自行修復
prepare-components-damaged = Windows 回報系統有損毀，導致更新無法安裝。重新啟動或許能解決此問題，Atlas 會在您登入後繼續。
prepare-restart-and-retry = 重新啟動並再試一次
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows 損毀過於嚴重，無法更新
prepare-components-unrepairable = 請備份您的檔案，然後使用 Atlas ISO 重新安裝 Windows。
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas 執行時使用的帳戶與登入 Windows 的帳戶不同。請使用系統管理員帳戶登入 Windows，從該帳戶開啟 Atlas，然後再試一次。
prepare-failed-store-missing = 您的帳戶尚未設定 Microsoft Store。請開啟一次 Microsoft Store；如果找不到它，請重新安裝，然後再試一次。
prepare-failed-store-battery = Microsoft Store 為了節省電池電力而暫停了更新。請將電腦接上電源，然後再試一次。
prepare-failed-store-network = Microsoft Store 已暫停更新，需等電腦連上未設為計量付費的網路才會繼續。請連線至未設為計量付費的 Wi-Fi 或乙太網路，然後再試一次。
prepare-failed-store-timeout = 市集應用程式尚未完成更新。請在 Microsoft Store 中完成其餘的下載，然後再試一次。
prepare-failed-store-passes = Microsoft Store 持續提供新的更新。請在 Microsoft Store 中完成其餘的更新，然後再試一次。
prepare-failed-manual-updates = 部分 Windows 更新需要在 Windows Update 中完成。請開啟 Windows Update 完成這些更新，然後再試一次。
prepare-failed-windows-passes = Windows Update 持續提供新的更新。請在 Windows Update 中完成其餘的更新，然後再試一次。
prepare-failed-windows-update-unreachable = Windows Update 無法連線至 Microsoft 的伺服器。請檢查網際網路連線，以及任何防火牆、Proxy 或 VPN，然後再試一次。
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-failed-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager 位於連結的資料夾中。請關閉 Atlas，將 Atlas Manager 移至這台電腦的本機資料夾，然後從該處開啟。
prepare-error-code = 錯誤碼：{ $code }
prepare-open-store = 開啟 Microsoft Store
prepare-windows-search = 正在檢查 Windows 更新…
prepare-percent = 此階段已完成 { $percent }%
prepare-count = 已完成的更新：{ $completed } / { $total }
prepare-bytes = 已下載 { $downloaded } MB，總量約 { $total } MB
prepare-progress-still = 已有 { $minutes } 分鐘沒有進度。大型更新可能需要一段時間，請保持 Atlas 開啟。
prepare-report-late = Windows 已有一段時間未回報進度。更新可能仍在進行，請保持 Atlas 開啟。
prepare-windows-download = 正在下載 Windows 更新…
prepare-windows-install = 正在安裝 Windows 更新…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = 正在修復 Windows…
prepare-windows-repair-detail = Windows 回報系統有損毀，可能導致更新無法安裝。這可能需要半小時或更久。
prepare-store-search = 正在檢查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其應用程式…
prepare-stop = 停止更新
prepare-start = 檢查並安裝更新
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Atlas 套件就緒後即可使用。
iso-username = 本機帳戶名稱
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = 您會在第一次登入時設定密碼。
iso-username-placeholder = 您的名字
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = 請輸入本機帳戶名稱以繼續
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = 最多可使用 20 個字元，開頭和結尾不能有空格，也不能包含下列任何符號：" / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = 名稱不能以句點「.」結尾。
iso-account-reserved = Windows 已將此名稱用於內建帳戶。請選擇其他名稱。
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Windows 安裝程式會請您接受授權條款。
prepare-drivers = 要如何安裝驅動程式？
prepare-drivers-auto = 透過 Windows Update 取得驅動程式
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = 透過 Windows Update 取得驅動程式（建議）
prepare-drivers-auto-detail = Windows 會為您的硬體尋找驅動程式。
prepare-drivers-manual = 自行安裝驅動程式
prepare-drivers-manual-detail = Windows Update 不會安裝驅動程式，因此您需要向電腦或裝置製造商取得驅動程式。已安裝的驅動程式會保留。
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = 驅動程式
iso-network-drivers = 包含這台電腦的 Wi-Fi 和乙太網路驅動程式
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = 登入後選擇
prepare-network-unmetered = 更新需要未設為計量付費的網際網路連線。請連線至 Wi-Fi 或乙太網路，然後再試一次。
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows 回報此網路無法存取網際網路。如果網路要求登入，請先登入；或檢查路由器以及任何 DNS 或防火牆篩選，然後再試一次。
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = 此連線為計量付費連線，或設有資料使用量限制。請連線至未設為計量付費的網路，或在網路設定中關閉「計量付費連線」，然後再試一次。
prepare-network-settings = 開啟網路設定
iso-stage-network-drivers = 正在準備網路驅動程式
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = 這台電腦的網路介面卡使用 Windows 內建的驅動程式，因此 ISO 不需要包含這些驅動程式。
desktop-setup-description = 請完成電腦設定。您的 Atlas 選擇已儲存，需要時可以返回 Windows。
desktop-setup-exit = 在 Windows 中繼續

# Windows installation USB
usb-title = 建立 USB 磁碟機
usb-existing = 使用現有 ISO 建立 USB 磁碟機
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB 磁碟機
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows ISO
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = 您的「下載」資料夾中沒有 Atlas ISO。
usb-iso-checking = 正在檢查 ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas 無法使用此 ISO 建立 USB 磁碟機。請使用 Atlas 建立的 ISO，或由 Microsoft 提供且為 Atlas 支援版本的 Windows 11 ISO。
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO 或 Atlas Manager 位於網路位置或連結的資料夾中。請將它移至這台電腦上的資料夾，例如「下載」。
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Windows 磁碟機的可用空間不足，無法準備此 ISO。請釋放一些空間，Atlas 會自動再次檢查。
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas 無法讀取此 ISO。請再試一次，或使用其他 ISO。
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = 開啟「儲存體」設定
usb-looking = 正在尋找 USB 磁碟機…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = 請連接 { $size } GB 以上的 USB 磁碟機。
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = 容量太小，需要 { $size } GB 以上。
usb-drive-too-small-iso = 容量不足以容納此 ISO
usb-drive-has-iso = 您的 ISO 位於此磁碟機
usb-drive-has-app = Atlas Manager 正從此磁碟機執行
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = 建立 USB 磁碟機
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = 請先選取 USB 磁碟機
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = 要清除 { $drive }（{ $size }，{ $letters }）嗎？
usb-confirm-title = 要清除 { $drive }（{ $size }）嗎？
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = 要清除 USB 磁碟機（{ $size }，{ $letters }）嗎？
usb-confirm-title-unnamed = 要清除 USB 磁碟機（{ $size }）嗎？
usb-confirm-message = 磁碟機上的所有內容都會被刪除。您的 ISO 會保留。
usb-confirm-erase = 清除並建立
usb-progress-title = 正在建立 USB 磁碟機…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = 正在準備檔案
usb-stage-formatting = 正在格式化
usb-stage-copying = 正在複製檔案
usb-stage-checking = 正在檢查磁碟機
usb-stage-ejecting = 正在退出
usb-keep-open = 請保持 Atlas 開啟，並讓磁碟機保持連接。
usb-scan-failed-title = 無法列出 USB 磁碟機
usb-scan-failed-retry = Atlas 無法讀取連接到這台電腦的磁碟機。請再試一次。
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = 無法建立 USB 磁碟機
usb-complete-title = 您的 USB 磁碟機已準備就緒
# F12, F11 and Esc are key names.
usb-ready = 請拔除磁碟機、備份要重新安裝的電腦，然後從此 USB 磁碟機啟動該電腦。開機選單通常可按 F12、F11 或 Esc 開啟。
# After erasing may have begun.
usb-failed-partial = 磁碟機只寫入了一部分。請確認它已連接，然後再試一次。
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas 在變更磁碟機前已停止。請再試一次。
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = USB 磁碟機已變更
usb-drive-changed = 磁碟機在 Atlas 清除前已被移除或重新連接，因此其內容沒有任何變更。
usb-drive-cancelled-title = 已取消建立 USB 磁碟機
usb-cancelled-partial = 磁碟機尚未完成。請重新建立後再使用。
usb-cancelled-unchanged = 您的 USB 磁碟機沒有任何變更。
usb-eject-failed-title = 無法退出 USB 磁碟機
usb-eject-failed-ready = 磁碟機已可使用。請關閉正在使用它的檔案或視窗，然後再試一次。
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = Atlas 需要權限才能建立 USB 磁碟機
usb-admin-reason = Atlas 需要系統管理員權限才能清除並寫入磁碟機。
usb-elevation-declined = Windows 未授予 Atlas 權限，因此目前還無法寫入 USB 磁碟機。
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = 不支援 Windows 11 Home、LTSC 和 Server 版本。請使用其他版本，例如 Pro、Education 或 Enterprise。如果 Windows 無法識別您的版本，請先解決此問題再繼續。
install-source-title = 無法安裝
install-source-unsupported = Atlas { $source } 無法直接更新至 { $target }。若要使用此版本，請備份您的檔案並重新安裝 Windows。
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } 無法直接更新。若要使用較新的版本，請備份您的檔案並重新安裝 Windows。
# $folder is a folder path (text).
install-source-resume-package = Atlas { $target } 的安裝尚未完成，只有 Atlas { $target } 套件才能完成這次安裝。請開啟該 Atlas 套件（.atlaspkg）。如果是由 Atlas 下載的，它位於 { $folder }。
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } 的安裝尚未完成。此測試版只能安裝其內建的 Atlas 套件，因此請在正式版 Atlas Manager 中使用 Atlas { $target } 套件完成該安裝。
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas 無法確認這台電腦上已安裝的內容，因此目前不會安裝任何項目。
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = 這台電腦上有舊版 Atlas 的檔案，但沒有完成安裝的記錄，因此無法更新。若要安裝 Atlas，請備份您的檔案並重新安裝 Windows。
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = 請在 Windows 安裝程式中選擇您擁有授權的版本。
detail-windows-preview = 不支援 Insider 預覽組建。請使用 Windows 11 的正式發行版本。
detail-windows-release-unknown = Atlas 無法確認此 Windows 組建是否已正式發行。請連線至網際網路後重新檢查。
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Microsoft 的 Windows 11 正式發行版本清單中沒有組建 { $build }，因此 Atlas 目前還無法安裝在此組建上。不支援 Release Preview 和其他預覽組建。待 Microsoft 將此組建列入清單後，請再次檢查。

prepare-continue = 繼續更新
prepare-saving-restart = 正在儲存您的選擇，並設定在 Windows 重新啟動後開啟 Atlas…
prepare-restart-save-failed = 無法儲存您的選擇。請在重新啟動前重試。
prepare-restart-registration-failed = 您的選擇已儲存，但 Atlas 無法設定在重新啟動後自動開啟。請再試一次，或自行重新啟動電腦，並在登入後開啟 Atlas。
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = 您的選擇已儲存，但 Atlas Manager 位於連結的資料夾中時，Atlas 無法設定在重新啟動後自動開啟。請關閉 Atlas，並將 Atlas Manager 移至這台電腦的本機資料夾。然後從該處開啟，或自行重新啟動電腦，並在登入後從該處開啟。
prepare-restart-failed = Atlas 無法重新啟動您的電腦。請再試一次，或從「開始」功能表重新啟動。您的選擇已儲存，Atlas 會在您登入後重新開啟。
diagnostics-export = 匯出診斷資訊
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = 正在收集診斷資訊…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = 取得協助
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = 已儲存診斷資訊
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = 已儲存為 { $file }，位於 Atlas 的 { $folder } 資料夾中。
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas 已從中移除您的使用者名稱、電腦名稱、電子郵件地址，以及已知的密碼或金鑰。
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = 無法儲存診斷 ZIP

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } 測試版。此應用程式只會安裝內建的 Atlas 套件。
home-status-bundled = 測試版 { $release }
package-bundled = 此測試版內建的 Atlas { $version } 已可安裝。
rc-about-release = 測試版
rc-about-commit = 原始碼提交
rc-about-package = 內建 Atlas 套件（SHA-256）
iso-package-bundled = 此測試版內建的 Atlas 套件

check-user-account = 使用者帳戶
detail-user-account-ok = UAC 已啟用，您的帳戶已準備好進行安裝。
detail-user-account-not-ready = 請啟用使用者帳戶控制（UAC），重新啟動電腦後再試。如果您使用的是內建 Administrator 帳戶，請使用另一個系統管理員帳戶登入。
detail-user-account-work-or-school = 無法從公司或學校帳戶（Microsoft Entra ID）安裝 Atlas。請使用本機帳戶或 Microsoft 帳戶登入，然後再試一次。
detail-user-account-check-failed = Atlas 無法檢查您的使用者帳戶。請重新啟動電腦，然後重新開啟 Atlas 並再次檢查。Windows 回報：{ $error }

footer-prepare-required = 請先完成 Windows 和市集應用程式的更新再繼續
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = 目前階段完成後將停止更新…
resume-choices-title = 繼續上次安裝
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = Atlas 會使用您上次的選擇完成該次安裝，因此在安裝完成前無法變更。

## Voluntary reports
report-title = 傳送報告
report-received = 已收到報告
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = 如需就此報告聯絡 Atlas 團隊，請保留此參考編號。如果您留下了聯絡方式，團隊可能會用它回覆您，但不保證一定會回覆。
# Accessible name of the Copy button beside the report reference.
report-copy-reference = 複製報告參考編號
report-another = 傳送另一份報告
# Label of the choice between the two kinds of report.
report-kind = 您想傳送什麼？
report-kind-issue = 問題
report-kind-suggestion = 建議
report-message = 您的訊息
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = 發生了什麼事？您當時在做什麼？
report-message-placeholder-suggestion = 您希望改變什麼？
# Under the message box, which also reads it out.
report-message-help = 請勿包含密碼。
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } / { $max } 個字元
report-contact = 聯絡方式（選填）
report-contact-placeholder = 電子郵件或 Discord 使用者名稱
report-attach = 附加診斷資訊
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = 有助於找出原因的記錄和系統詳細資料。Atlas 會移除您的使用者名稱、電腦名稱、電子郵件地址，以及已知的密碼或金鑰。錯誤詳細資料、硬體型號和應用程式名稱會保留。您可以在傳送前檢查 ZIP。
report-review = 檢查 ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = 無法準備診斷資訊
report-prepare-failed-advice = 請再試一次，或傳送不含診斷資訊的報告。
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = 您的報告會私下傳送給 reports.atlasos.net 上的 Atlas 團隊。您的訊息和聯絡方式會依原樣傳送。團隊可能會使用其他公司的 AI 服務協助調查。這些服務會取得您的訊息和診斷資訊，但不會取得您的聯絡方式。報告會在 90 天後刪除，伺服器安全性記錄可能會記錄您的 IP 位址。
report-website = 隱私權與報告網站
report-consent = 我同意將此報告及附加的診斷資訊傳送給 Atlas 團隊
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = 請檢查網際網路連線，然後再試一次。您也可以透過報告網站傳送。
report-not-sent-busy = 報告服務目前忙碌中。請稍候幾分鐘，然後再試一次。
report-not-sent-outdated = 此版本的 Atlas Manager 無法傳送報告。請將您的訊息複製到報告網站；如果您附加了診斷資訊，請一併附上 ZIP。
report-not-sent-diagnostics = 無法傳送診斷資訊。請再試一次，或傳送不含診斷資訊的報告。
# The footer's button where this version can't send.
report-failed-website = 開啟報告網站
# Beside a spinner in the footer while the report is on its way.
report-sending = 正在傳送…
report-send = 傳送報告

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = 請輸入 { $min }–{ $max } 個字元。

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = 請將聯絡資訊限制在 { $max } 個字元以內。

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = 請確認您同意傳送此報告。

report-failed-title = 報告未傳送

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = 您的檔案和應用程式都會保留。
home-plan-name = 這次更新分為兩個部分
home-plan-windows-title = Windows 11 版本 { $release }
home-plan-windows-step = Atlas 會從 Windows Update 安裝此版本，之後電腦會重新啟動。
# The same step where moving is optional.
home-plan-windows-step-ask = 選用。Atlas 會先詢問您，再從 Windows Update 安裝此版本，之後電腦會重新啟動。
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = 已安裝。
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas 會更新並保留您的選擇，之後電腦會重新啟動。
# $date and $until are dates.
home-end-of-updates-title = Windows 11 版本 { $current } 將於 { $date } 停止接收安全性更新
home-end-of-updates-past-title = Windows 11 版本 { $current } 已不再接收安全性更新
home-end-of-updates-message = 更新至 Atlas { $version } 時，也會將這台電腦更新至 Windows 11 版本 { $release }，此版本會持續接收安全性更新至 { $until }。
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11 版本 { $release } 會持續接收安全性更新至 { $until }。

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } 適用於 Windows 11 Pro、Enterprise 和 Education，因此無法安裝在 { $product } 上。
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } 適用於 Windows 11 Pro、Enterprise 和 Education，因此無法安裝在 { $product } 上。Windows 11 版本 { $current } 會接收安全性更新至 { $date }，而 Windows Update 可以將這台電腦更新至較新的版本。
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } 適用於 Windows 11 Pro、Enterprise 和 Education，因此無法安裝在 { $product } 上。版本 { $current } 已不再接收安全性更新，因此即使不安裝 Atlas，也請更新 Windows。
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version } 適用於 Windows 11 Pro、Enterprise 和 Education。不支援 LTSC 版本。
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } 需要 Windows 11 版本 { $releases }，而 Windows Update 無法將這台電腦更新至該版本。請備份您的檔案，然後使用 Atlas ISO 重新安裝 Windows。
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } 需要 Windows 11 版本 { $releases }，而 Windows Update 無法將這台電腦更新至該版本。

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Windows Update 設定已因 Atlas 更新而變更
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = 更新完成後，Atlas 會還原這些設定。
# When the last check found no offer yet.
home-update-access-waiting = Atlas 已開啟 Windows Update，以將這台電腦更新至 Windows 11 版本 { $release }，但 Windows Update 尚未提供此版本。
home-update-access-updating = Atlas 已開啟 Windows Update 來安裝更新，但尚未完成。
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = 無法讀取 Atlas 的 Windows Update 記錄
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas 無法讀取其 Windows Update 設定變更記錄，因此不會變更或還原任何項目。
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas 無法還原設定。
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = 請先完成 Atlas 的安裝。安裝的最後階段會還原 Atlas 變更過的 Windows Update 設定。
home-continue-update = 繼續更新
home-put-back = 還原設定
home-putting-back = 正在還原設定…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11 版本 { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } 不支援版本 { $current }，因此 Atlas 會先更新 Windows。
# Under the title where moving is optional.
windows-optional = Atlas 可搭配任一版本使用。
# The choice's accessible name; the two answers say it.
windows-card-question = 這台電腦要使用哪個 Windows 版本？
windows-choice-move-recommended = 更新至 Windows 11 版本 { $release }（建議）
# $date is when the new version stops getting security updates.
windows-choice-move-support = 安全性更新提供至 { $date }。
windows-choice-keep = 保留 Windows 11 版本 { $current }
windows-choice-keep-later = 維持在版本 { $current }。您之後可以從 Atlas Manager 更新。
windows-card-facts = 變更內容
windows-fact-files = 您的檔案和應用程式都會保留。更新撤銷的任何變更，Atlas 都會重新套用。
windows-fact-time = 通常需要幾分鐘，最多 2 小時，之後會重新啟動。
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = 會移除 Windows PowerShell 2.0 和 WMIC。
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = 如何撤銷此更新
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = 更新即表示您接受 Microsoft 軟體授權條款。
windows-terms-link = 閱讀授權條款
windows-accept = 接受並更新
# Once the terms are accepted, before the move starts by itself.
windows-starting = 正在開始…
windows-starts-after-checks = 檢查通過後開始。
windows-starts-after-package = Atlas { $version } 就緒後開始。
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = 版本 { $release } 重設了 Atlas 的部分變更。Atlas { $version } 會依您先前的選擇重新套用。
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = 要保留 Windows 11 版本 { $current } 嗎？

# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas 會暫時開啟 Windows Update
access-off = 這台電腦已關閉 Windows Update。Atlas 更新 Windows 期間會重新開啟它。
access-paused = 這台電腦已暫停 Windows 更新。Atlas 更新 Windows 期間會解除暫停。
access-delayed = 這台電腦已延遲每月更新。Atlas 更新 Windows 期間會取消延遲。
# After the lines above.
access-back = 安裝 Atlas { $version } 後，這些設定會恢復原狀。
access-back-stop = 如果您在那之前停止，Atlas 會還原這些設定。

prepare-reason-feature-update = 新的 Windows 版本
prepare-reason-feature-commit = 完成新 Windows 版本的安裝
prepare-reason-apprepository = 修復 Microsoft Store
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = 正在等待 Windows Update 提供 Windows 11 版本 { $release }…
windows-waiting-detail = 通常只需幾分鐘，最多 2 小時。Atlas 會自動繼續，您可以繼續使用電腦。
windows-waited = 已等待 { $minutes } 分鐘。
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update 未在 2 小時內提供版本 { $release }
windows-wait-ended = Atlas 已還原您的設定。請稍後再試，或使用 Atlas ISO 重新安裝 Windows。
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas 無法還原您的 Windows Update 設定。
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows 無法準備重新啟動
windows-commit-failed = 您的電腦沒有重新啟動。請再試一次。

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update 尚未提供版本 { $release }
windows-outcome-not-offered = 最多可能需要 2 小時。您的電腦目前仍是版本 { $current }。
windows-outcome-hardware-title = 這台電腦不符合 Windows 11 的需求
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = 這台電腦沒有 { $missing }，因此 Windows Update 不會提供版本 { $release }。請備份您的檔案，然後使用 Atlas ISO 重新安裝 Windows。
hardware-tpm = TPM 2.0
hardware-uefi = UEFI 韌體
windows-outcome-hidden-title = 版本 { $release } 已在 Windows Update 中隱藏
windows-outcome-hidden = 請使用您當初隱藏它的工具將其重新顯示，然後再試一次。
windows-outcome-disk-space-title = 可用空間不足
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows 需要 { $drive } 上有 { $needed } GB 可用空間，目前只有 { $free } GB。空間足夠後，Atlas 會自動繼續。
windows-outcome-managed-title = 這台電腦從所屬組織取得更新
windows-outcome-managed = 組織的更新伺服器不提供版本 { $release }，因此 Atlas 沒有進行任何變更。請洽詢您的組織，或使用 Atlas ISO 重新安裝 Windows。
windows-outcome-policy-title = Windows Update 一再被改回原狀
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = Atlas 變更 { $setting } 後，它又被改回，因此 Atlas 無法更新 Windows。如果這台電腦由組織管理，請洽詢該組織。
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = 服務已停用：{ $service }
windows-outcome-blocked-service = Windows Update 需要此服務。請在「服務」中將它設為「手動」，然後再試一次。
windows-outcome-blocked-title = 有其他設定讓 Windows Update 保持關閉
windows-outcome-blocked = 有一項不是由 Atlas 變更的設定（{ $setting }）使它無法執行。請變更此設定，然後再試一次。
windows-outcome-rollback-title = Windows 無法完成版本 { $release } 的安裝
windows-outcome-rolled-back = Windows 已回復為版本 { $current }。您的檔案和應用程式不受影響。
windows-outcome-components-lost-title = Atlas 的部分變更已消失
windows-outcome-components-lost = Atlas 無法判斷原因，因此在安裝 Atlas { $version } 前就已停止。
windows-outcome-build-title = 更新期間 Windows 版本發生了變更
windows-outcome-build = 請還原 Atlas 變更的設定，然後從首頁重新開始。
windows-outcome-journal-title = Atlas 無法讀取這次更新的記錄
windows-outcome-journal = 在 Atlas 團隊查看之前，Atlas 不會變更或還原任何項目。
windows-outcome-pin-title = 無法記錄某項 Windows Update 原則
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } 的值 Atlas 之後無法還原，因此 Atlas 沒有進行任何變更。
windows-outcome-terms-title = 尚未接受授權條款
windows-outcome-terms = Windows Update 需要您先接受授權條款，才能安裝版本 { $release }。
windows-outcome-failed-title = Windows 無法安裝版本 { $release }
windows-outcome-failed = 您的電腦目前仍是版本 { $current }。
# Windows services a move needs, as Services lists them.
service-bits = 背景智慧型傳送服務（BITS）
service-cryptsvc = 密碼編譯服務
service-trusted-installer = Windows Modules Installer
prepare-open-services = 開啟「服務」
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = 保留版本 { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = 要停止更新至 Atlas { $version } 嗎？
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = 要停止更新 Windows 嗎？
stop-update-before = Atlas 會還原它變更的 Windows Update 設定。Windows 已安裝的更新會保留，您的電腦會維持在 Windows 11 版本 { $current }。
stop-update-after = 您的電腦會維持在 Windows 11 版本 { $release }。Atlas 會還原它變更的 Windows Update 設定。
stop-update-access = Atlas 會還原它變更的 Windows Update 設定。Windows 已安裝的更新會保留。
stop-update-keep = 繼續進行更新
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = 要關閉 Atlas 嗎？
window-close-update-access-message = Atlas 會在關閉前還原它變更的 Windows Update 設定。您可以從首頁重新開始更新。
window-close-put-back = 還原並關閉
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = 要關閉而不還原設定嗎？
window-close-put-back-failed-message = 如果您現在關閉 Atlas，Windows Update 設定會維持 Atlas 變更後的狀態。再次開啟 Atlas 時，首頁會讓您還原這些設定。

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = 這個 Atlas 版本需要 Windows 11 版本 { $release }，而這台電腦是版本 { $current }。

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = 為 Atlas 更新 Windows 的作業未完成。以下是提供給 Atlas 團隊的詳細資料：

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = Windows 更新後重新安裝
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = 您在 Atlas { $previous } 的選擇
rebase-choices-kept = Atlas 會還原您為 Atlas { $previous } 所做的選擇，您之後可以重新安裝 Atlas 來變更。
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas 會還原您為 Atlas { $previous } 所做的其他所有選擇。
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = 要在另一位使用者仍登入時重新啟動嗎？
restart-others-question = 要在其他使用者仍登入時重新啟動嗎？
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
        [1] 另一位使用者也已登入：{ $names }。重新啟動會關閉對方的應用程式，對方未儲存的工作將會遺失。
       *[other] 其他使用者也已登入：{ $names }。重新啟動會關閉他們的應用程式，他們未儲存的工作將會遺失。
    }
restart-others-keep = 不要重新啟動
restart-others-restart = 仍要重新啟動
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = 正在更新 Microsoft Store…
prepare-store-repairing = 正在修復 Microsoft Store…
prepare-store-repair-detail = 這可能需要幾分鐘。
prepare-store-repair-notice = Atlas 正在修復 Microsoft Store。修復完成前，「開始」功能表和工作列可能無法運作，登入時啟動的應用程式可能會顯示錯誤。請讓電腦保持開機並接上電源。修復完成後，電腦會自動重新啟動。
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = 這台電腦已關閉 Microsoft Store，因此市集應用程式未更新。
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store 無法運作
prepare-store-broken = Atlas 無法修復它，現在安裝 Atlas 可能會導致市集應用程式無法運作。
prepare-store-broken-iso = 如果修復一再失敗，請備份您的檔案，並使用 Atlas ISO 重新安裝 Windows。
prepare-repair-store-again = 再次嘗試修復
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows 無法更新內建應用程式
prepare-store-staging = Windows 無法安裝下列內建應用程式的更新，Atlas 的修復也無法解決問題：{ $apps }。{ prepare-components-unrepairable }

screen-keyboard-title = 鍵盤語言
screen-keyboard-question = 您使用多種鍵盤語言嗎？
package-option-keyboard-shortcuts = 是，使用鍵盤快捷鍵
package-option-keyboard-selector = 是，使用工作列選擇器
package-option-keyboard-single = 否，只使用一種鍵盤配置
consequence-keyboard-shortcuts = Alt+Shift 切換語言；Ctrl+Shift 切換配置。
consequence-keyboard-selector = 關閉 Alt+Shift 和 Ctrl+Shift，避免遊戲時意外切換。
package-choice-keyboard-description = 選擇切換鍵盤語言的方式。
consequence-keyboard-single = { consequence-keyboard-selector }
