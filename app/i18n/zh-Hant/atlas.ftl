### Atlas Manager: Chinese (Traditional) (zh-Hant), preview translation. Revised 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Serves zh-TW, zh-HK and zh-MO. Terminology follows Microsoft's Taiwan
### Windows glossary (設定, 系統管理員, 重新啟動, 檔案, 資料夾, 網路, 電腦).
### Full-width punctuation; one space between Chinese and Latin words or
### numbers. "重新開啟 Atlas" is reopening the app (and 重新開啟 also turns a
### protection back on); "重新啟動" is only restarting the PC / Windows. Chinese has only the "other" plural
### category; exact [1]/[2] variants are allowed.

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
# Accessible description of a disabled control.
common-not-available = 目前無法使用
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = 返回首頁
# Accessible name of the gear button in the title bar.
common-settings = 設定
common-close-settings = 關閉設定
common-open-windows-security = 開啟 Windows 安全性
# Relaunches the Atlas Manager elevated (UAC), not the PC.
common-restart-as-administrator = 以系統管理員身分重新開啟 Atlas
common-try-again = 再試一次
common-read-the-docs = 閱讀 Atlas 使用指南
common-show-details = 顯示詳細資料
common-hide-details = 隱藏詳細資料
common-open-log-file = 開啟記錄檔
# Accessible name of the Copy button beside the install log.
common-copy-install-log = 複製安裝記錄
common-install-log = 安裝記錄
# Row labels in summary cards.
common-windows = Windows
common-options = 選項
common-package = 安裝檔案
common-installed-as = 安裝類型
common-installed = 已安裝
common-checking = 檢查中
# Joins two items in a list: "Brave、Firefox". The braces keep the literal.
list-separator = { "、" }
# Joins two alternatives: "26100 或 26200".
list-or = { $a } 或 { $b }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = 要在 Atlas 安裝期間關閉視窗嗎？
window-close-message = 安裝會在背景繼續進行。再次開啟 Atlas 即可查看進度與結果。安裝完成前，請讓電腦保持開機。
window-close-keep = 保持開啟
window-close-close = 關閉視窗
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = 開啟 Atlas Playbook（.apbx）
# Message Windows shows in its restart notification.
shutdown-comment = Atlas 已安裝完成。Windows 即將重新啟動以完成設定。

## System

# "Windows 11 Pro 25H2（組建 26200.1234）". All three values are text.
system-description = { $product } { $version }（組建 { $build }）

## Home page

home-not-installed = 歡迎使用 Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = 安裝於 { $date }
home-status-checking = 正在檢查更新
home-status-offline = 無法檢查更新
home-status-not-checked = 尚未檢查更新
home-status-update = Atlas { $version } 已推出
home-status-up-to-date = 已是最新版本
home-status-newest = 最新版本：Atlas { $version }
home-check-again = 再次檢查
# Primary button while an install is running or waiting.
home-show-install = 檢視進度
home-continue-installing = 繼續設定
home-update-to = 更新至 Atlas { $version }
home-reinstall = 重新安裝 Atlas
home-install = 安裝 Atlas
home-start-over = 重新開始
home-security-reminder-title = 請重新開啟防護
home-security-reminder-message = 目前沒有進行中的安裝。請前往 Windows 安全性，重新開啟竄改防護、即時保護、雲端提供的保護與自動提交範例。
home-elevation-title = Atlas 需要權限才能安裝
home-state-error-title = 無法讀取 Atlas 的安裝資訊
home-whats-new = Atlas { $version } 的新功能
home-view-release = 在 GitHub 檢視版本資訊
home-released = 發行於 { $date }
home-show-less = 顯示較少
home-show-full-notes = 顯示完整版本資訊
home-your-install = 您的 Atlas 設定
# Row label: how Atlas was set up.
home-set-up = 設定方式
home-set-up-during-oobe = Windows 初始設定期間
home-history = 安裝歷程
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = 讓您的電腦為 Atlas 做好準備
home-step-1-title = 檢查電腦
home-step-1-detail = Atlas 會檢查 Windows 並下載安裝檔案，不會變更您的 Windows 設定。
home-step-2-title = 自訂您的設定
home-step-2-detail = 選擇 Windows 處理防護與更新的方式，再依需要加入其他應用程式與設定。
home-step-3-title = 暫時關閉防毒保護
home-step-3-detail = Atlas 會引導您暫時關閉 Windows 安全性的四個防護開關，以免它們阻擋安裝。
home-step-4-title = 安裝並重新啟動
home-step-4-detail = 大約 { $minutes } 分鐘。
# Accessible name of a numbered step.
home-step-a11y = 步驟 { $number }：{ $title }
home-github = 在 GitHub 檢視 Atlas 專案
home-discord = 加入 Atlas 的 Discord 社群
home-report-problem = 在 GitHub 回報問題

## How an install was done (from the state document)

mode-fresh = 首次安裝
mode-upgrade = 從舊版本更新
mode-reapply = 重新安裝相同版本
mode-unknown = 安裝
# Forms used inside a history row.
history-mode-fresh = 首次安裝
history-mode-upgrade = 更新
history-mode-reapply = 重新安裝
history-mode-unknown = 安裝

## Notices on the Home page

notice-settings-reset-title = Atlas 正在使用預設的應用程式設定
# $error is a raw error message (text).
notice-settings-unreadable = Atlas 無法讀取已儲存的應用程式設定。您的 Windows 設定未受影響。詳細資料：{ $error }
# $file is a file name (text).
notice-settings-damaged-kept = 應用程式設定檔已損毀，並已重設為預設值。舊檔案已另存為 { $file }。詳細資料：{ $error }
notice-settings-damaged = 應用程式設定檔已損毀。Atlas 目前使用預設值。詳細資料：{ $error }
notice-settings-not-saved-title = 無法儲存應用程式設定
notice-session-unreadable-title = 無法確認上次的安裝狀態
# $path is a file path (text).
notice-session-unreadable-message = Atlas 無法讀取 { $path }，因此無法確認是否仍有安裝正在進行。如果您不確定，請先向 Atlas 社群求助，再考慮移除這個檔案。只有在確認沒有安裝正在進行後，才可刪除這個檔案並再試一次。詳細資料：{ $error }

## Administrator elevation

elevation-declined = 尚未取得權限。請再試一次，並在 Windows 詢問是否允許 Atlas 變更您的裝置時選擇「是」。
elevation-declined-continue = 尚未取得權限。請再試一次，並在 Windows 詢問是否允許 Atlas 變更您的裝置時選擇「是」。您的設定選擇已儲存。
elevation-draft-not-saved = Atlas 無法儲存您的設定選擇，因此尚未重新開啟。請再試一次。詳細資料：{ $error }

## The install flow

step-ready = 準備
step-options = 您的選擇
step-security = Windows 安全性
step-install = 安裝
install-title = 設定 Atlas
# Accessible name of the row of steps.
stepper-label = Atlas 設定步驟
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = 第 { $number } 步，共 { $total } 步，{ $title }，{ $status }
stepper-status-completed = 已完成
stepper-status-current = 目前步驟
stepper-status-upcoming = 尚未進行
# Heading above each step's content.
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }

## Step 1: Get ready

ready-banner-busy-title = 正在準備您的電腦
ready-banner-busy-message = Atlas 正在檢查你的電腦並準備安裝檔案。
ready-banner-blocked-title = 您的電腦還需要一些準備
ready-banner-blocked-message = 請依照下方說明處理，然後選擇「再次檢查」。
ready-banner-no-package-title = 請先下載 Atlas
ready-banner-no-package-message = 請在下方下載最新版本，或開啟已儲存的 Atlas Playbook（.apbx）。
ready-banner-warnings-title = 有幾點需要留意
ready-banner-warnings-message = 繼續之前，請閱讀下方說明並採取建議的做法。
ready-banner-ok-title = 可以開始選擇設定了
ready-banner-ok-message = 檢查已通過，安裝檔案也已就緒。

# Card title and accessible name of the list of checks.
ready-this-pc = 電腦檢查
ready-check-again = 再次檢查

package-title = 安裝檔案
# $received and $total are formatted numbers of megabytes (text).
package-downloading = 正在下載 Atlas { $version } · { $received } / { $total } MB
package-unpacking-progress = 正在解壓縮 · { $done } / { $total } 個檔案
package-unpacking = 正在解壓縮
package-looking = 正在查詢最新的 Atlas 版本。
package-none = 尚無安裝檔案。Playbook（.apbx）包含 Atlas 所需的設定指令與檔案。
# Short status words beside the card title.
package-status-downloading = 下載中
package-status-unpacking = 解壓縮中
package-status-failed = 無法準備檔案
package-status-ready = 就緒
package-status-checking = 檢查中
package-status-missing = 尚未下載
# Accessible name of the progress bar.
package-progress = 安裝檔案準備進度
package-download-again = 重新下載
package-download-version = 下載 Atlas { $version }
package-download-newest = 下載最新版本
package-open-file = 開啟 Playbook 檔案
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = 已從 GitHub 下載 Atlas { $version }，可以安裝。
package-from-file = 已從 { $file } 載入 Atlas { $version }，可以安裝。
package-unpacked = Atlas { $version } 已可安裝。
package-at = 安裝檔案：{ $path }
package-none-yet = 尚未選擇安裝檔案
acquire-no-asset = Atlas { $version } 沒有可下載的 Playbook 檔案。請開啟已儲存的 Atlas Playbook（.apbx）以繼續。
acquire-unsupported = 這個應用程式可安裝 Atlas 0.6.0 及更新版本。若要安裝 Atlas { $version }，請改用 AME Wizard。
acquire-failed = 無法準備安裝檔案。請重新下載，或開啟其他 Atlas Playbook（.apbx）。詳細資料：{ $error }

## System checks

check-administrator = 安裝權限
check-supported-build = Windows 相容性
check-pending-updates = Windows 更新
check-pending-reboot = 待處理的重新啟動
check-third-party-antivirus = 其他防毒軟體
check-internet = 網際網路連線
check-power = 電源
check-activation = Windows 啟用
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
# Check boxes the user ticks when a check could not run.
check-ack-updates = 我已查看 Windows Update，沒有等待安裝的更新
check-ack-reboot = 我已重新啟動 Windows，目前不需要再重新啟動
check-ack-internet = 這台電腦已連線到網際網路
check-ack-generic = 我已自行確認這項需求

detail-admin-ok = Atlas 已具備進行安裝變更所需的權限。
detail-admin-missing = 請以系統管理員身分重新開啟 Atlas，並在 Windows 要求權限時選擇「是」。
# $builds is a list of build numbers such as "26100 或 26200"; $build is this PC's (text).
detail-build-unsupported = 這個 Atlas 版本需要 Windows 組建 { $builds }，而這台電腦的組建為 { $build }。請先安裝支援的 Windows 版本再繼續。
detail-updates-none = 沒有等待安裝的 Windows 更新。
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] 請先安裝這個更新：{ $titles }。
        [2] 請先安裝這些更新：{ $titles }。
       *[other] 請先安裝 { $count } 個更新，包括 { $titles }。
    }
detail-updates-unknown = 無法檢查 Windows 更新。請開啟 Windows Update 查看；如果沒有等待安裝的更新，請在下方確認。（{ $error }）
detail-reboot-none = Windows 目前不需要重新啟動。
detail-reboot-pending = 請重新啟動電腦以完成先前的變更，然後重新開啟 Atlas 並再次檢查。
detail-reboot-unknown = 無法確認 Windows 是否需要重新啟動。請重新啟動電腦，然後重新開啟 Atlas 並再次檢查。（{ $error }）
detail-antivirus-none = 未偵測到其他防毒軟體。
# $products is a list of product names (text).
detail-antivirus-found = 下列防毒軟體可能會阻擋安裝：{ $products }。請先解除安裝再繼續。
detail-antivirus-unknown = 無法檢查是否有其他防毒軟體。繼續之前，請先查看已安裝的應用程式。（{ $error }）
detail-internet-ok = 已連線。Atlas 下載並安裝軟體期間，請保持網路連線。
detail-internet-missing = 請連線到網際網路，然後再次檢查。
detail-power-mains = 電腦已接上電源。安裝完成前請保持連接。
detail-power-battery = 請將電腦接上電源，讓它在整個安裝期間保持開機。
detail-power-unknown = 無法檢查電源狀態。如果您使用筆記型電腦，請先接上電源再繼續。
detail-activation-ok = Windows 已啟用。Atlas 不會變更啟用狀態。
detail-activation-missing = Windows 尚未啟用。您可以繼續，但 Atlas 不會為您啟用 Windows。
detail-activation-no-licence = Windows 未回報授權。您可以繼續；Atlas 不會變更您的啟用狀態。
detail-activation-unknown = 無法檢查 Windows 啟用狀態。您可以繼續；Atlas 不會變更您的啟用狀態。（{ $error }）

## Step 2: Options

options-progress = 第 { $number } 項選擇，共 { $total } 項
options-progress-extras = 第 { $number } 項選擇，共 { $total } 項：選用項目
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = 要保留防毒保護嗎？
screen-mitigations-title = 處理器安全性
screen-mitigations-question = 要保留 Windows 的處理器防護嗎？
screen-updates-title = Windows Update
screen-updates-question = Windows 該如何安裝更新？
screen-browser-title = 瀏覽器
screen-power-title = 電源與安全性
screen-apps-title = 應用程式
screen-optional-apps-title = 選用應用程式
screen-choose-one-title = 選擇一個選項
screen-extras-title = 選用項目
screen-extras-question = 選擇您想要的選用項目
# Question for a required choice this app has no specific wording for.
screen-generic-question = 請為「{ $title }」選擇一個選項
learn-more-defender = 深入了解 Microsoft Defender
learn-more-mitigations = 閱讀處理器安全性說明
learn-more-updates = 深入了解 Windows Update
learn-more-browser = 深入了解瀏覽器
learn-more-power = 深入了解電源與安全性
learn-more-apps = 深入了解應用程式
learn-more-eclean = eclean 如何與 AtlasOS 搭配使用
learn-more-generic = 閱讀設定指南
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = 保留 Windows 內建的防毒軟體，協助保護電腦免受病毒與其他威脅。
consequence-defender-disable = 移除 Microsoft Defender。在您安裝其他防毒軟體之前，電腦將沒有防毒保護。
consequence-mitigations-default = 保留 Windows 的預設防護，抵禦利用處理器運作方式的攻擊。
consequence-mitigations-disable = 關閉這些防護，安全性會降低。效能取決於您的處理器，也可能變差。
consequence-auto-updates-disable = 您需要自行開啟 Windows Update 安裝更新。更新通知仍會顯示。
consequence-auto-updates-default = Windows 會自動安裝更新，包括安全性修正。

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = 保留 Microsoft Defender（建議）
playbook-option-defender-disable = 移除 Microsoft Defender
playbook-option-mitigations-default = 保留預設防護（建議）
playbook-option-mitigations-disable = 關閉處理器防護
playbook-option-auto-updates-disable = 由我自行安裝更新
playbook-option-auto-updates-default = 自動安裝更新
playbook-option-disable-hibernation = 關閉休眠
playbook-option-disable-power-saving = 關閉省電功能
playbook-option-disable-core-isolation = 關閉虛擬化型安全性（VBS）
playbook-option-remove-snipping-tool = 移除剪取工具
playbook-option-uninstall-edge = 移除 Microsoft Edge
playbook-option-install-another-browser = 安裝瀏覽器
playbook-option-install-toolbox = 安裝 Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender 是 Windows 內建的防毒軟體，建議保留。只有在了解風險並打算使用其他防毒軟體時，才應移除。
playbook-page-mitigations-default-description = 這些防護也稱為安全性緩和措施，可協助抵禦處理器漏洞。建議保留 Windows 預設值。
playbook-page-auto-updates-disable-description = Windows 更新包含安全性修正。您可以讓 Windows 自動安裝，也可以自行安裝。
consequence-install-toolbox = 加入 Atlas Toolbox，協助您管理 Atlas 設定。Toolbox 仍在測試階段，部分功能可能尚未完成。
playbook-page-browser-brave-description = 選擇要安裝的瀏覽器。Atlas 不會變更您的瀏覽器設定。

## Step 3: Windows Security

security-banner-reading-title = 正在檢查 Windows 安全性
security-banner-reading-message = Atlas 正在檢查下方的四個防護開關。
security-banner-off-title = 四個防護開關都已關閉
security-banner-off-message = 現在可以在安裝前檢視您的選擇。
security-banner-readable-off-title = Atlas 能檢查的開關都已關閉
security-banner-readable-off-message = 請在 Windows 安全性中檢查其餘的開關。
security-banner-on-title = 暫時關閉防毒保護
security-banner-on-message = 這些防護可能會阻擋 Atlas 需要進行的變更。
# The page name in Windows Security.
security-list-title = 病毒與威脅防護設定
security-switch-off = 關閉
security-switch-on = 開啟
security-switch-unreadable = 無法檢查
security-switch-reading = 檢查中
security-all-off = 全部關閉
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }：{ $state }
# Parts of the summary "2 個仍開啟，1 個無法檢查".
security-count-still-on = { $count } 個仍開啟
security-count-unreadable = { $count } 個無法檢查
security-count-join = { $a }，{ $b }
security-unknown-title = 請確認 Atlas 無法檢查的開關
security-unknown-message = 在 Windows 安全性中查看四個開關都已關閉後，請在下方確認。
security-acknowledge = 我已檢查 Windows 安全性，四個開關都已關閉
security-unknown-unelevated-title = Atlas 需要權限才能檢查防護狀態
security-unknown-unelevated-message = 請以系統管理員身分重新開啟 Atlas，才能檢查 Microsoft Defender 的設定。
# The four switches, named as Windows Security names them in Traditional Chinese.
protection-tamper = 竄改防護
protection-tamper-why = 請先關閉這一項，Defender 才會允許變更其防護設定。
protection-realtime = 即時保護
protection-realtime-why = 暫停檔案掃描，以免 Defender 阻擋 Atlas 的安裝檔案。
protection-cloud = 雲端提供的保護
protection-cloud-why = 暫停可能阻擋 Atlas 安裝檔案的線上威脅檢查。
protection-samples = 自動提交範例
protection-samples-why = 避免 Defender 自動將 Atlas 的檔案傳送給 Microsoft 分析。

## Step 4: Install

install-preparing-title = 安裝前的最後一次檢查
install-preparing-message = 進行變更之前，Atlas 正在再次檢查您的電腦與防護設定。
install-installing = 安裝中
install-running = 執行中
# Accessible name of the progress bar.
install-progress = 安裝進度
phase-preflight = 正在檢查電腦並準備檔案
phase-staging = 正在準備安裝檔案
phase-applying = 正在設定 Windows。請讓電腦保持開機。
phase-done = 正在完成設定
outcome-succeeded-title = Atlas 已安裝完成
outcome-lost-title = 無法確認安裝結果
outcome-failed-title = 安裝未完成
outcome-succeeded = 請重新啟動電腦以完成 Atlas 設定。
outcome-requirements = 您的電腦不符合安裝需求。未進行任何安裝變更。請返回「準備」重新執行檢查。
outcome-not-elevated = 未進行任何安裝變更。請以系統管理員身分重新開啟 Atlas，然後再試一次。
outcome-failed-preflight = 安裝在進行任何變更前已停止。請開啟記錄檔查看原因，然後再試一次。
outcome-failed-staging = 安裝在準備檔案時停止，尚未變更 Windows。請開啟記錄檔查看原因，然後再試一次。
outcome-failed-applying = 部分變更可能已經生效。如果您要就此停止，請在 Windows 安全性中重新開啟先前關閉的防護（如果它們仍然存在）。
outcome-not-started = 安裝程式未能及時啟動。未進行任何安裝變更。請選擇「再試一次」。
outcome-lost = 安裝程式已停止，但沒有回報結果，部分變更可能已經生效。請開啟記錄檔查看原因，然後選擇「再試一次」以繼續安裝。
restart-now-message = Windows 正在重新啟動，以完成 Atlas 設定。
restart-countdown = Windows 將在 { $seconds } 秒後重新啟動，以完成 Atlas 設定。
restart-stopped = 已取消自動重新啟動。請儲存您的工作，然後重新啟動電腦以完成 Atlas 設定。
restart-needed = 請儲存您的工作，然後重新啟動 Windows 以完成 Atlas 設定。
restart-dont-now = 稍後重新啟動
restart-now = 立即重新啟動
# Accessible name of the countdown bar.
restart-progress = 距離重新啟動的剩餘時間
restart-start-failed = 無法重新啟動 Windows。請儲存您的工作，然後從「開始」功能表重新啟動。詳細資料：{ $error }
preflight-title = 安裝尚未開始
preflight-invalid-options = Atlas 無法使用這些設定選擇。請返回「您的選擇」重新檢視，然後再試一次。詳細資料：{ $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = 您的電腦狀態在先前檢查後已有變化。請先解決下列問題，再試一次。{ $problems }
preflight-problem = { $title }：{ $detail }
# $summary is the Windows Security summary such as "2 個仍開啟".
preflight-security = Windows 安全性：{ $summary }。
preflight-busy = 另一個 Atlas 視窗正在開始安裝。請稍候片刻，然後再試一次。
preflight-record-unreadable = Atlas 無法確認上次的安裝是否仍在進行，因此沒有開始新的安裝。請關閉並重新開啟 Atlas，以查看復原說明。詳細資料：{ $error }
preflight-refused = 無法啟動安裝程式。未進行任何安裝變更。詳細資料：{ $error }
go-to-ready = 返回「準備」
go-to-options = 返回「您的選擇」
output-problem-title = 無法讀取安裝進度
output-problem-message = Atlas 無法讀取記錄，但這不代表安裝已停止。請讓電腦保持開機，並嘗試開啟記錄檔。詳細資料：{ $error }
install-elevate-title = Atlas 需要權限才能安裝
install-no-package-title = 請先選擇安裝檔案
install-no-package-message = 請返回「準備」下載 Atlas，或開啟已儲存的 Playbook（.apbx）。
install-security-title = 安裝前請檢查防毒保護
install-security-reading = 正在再次檢查四個防護開關。
install-security-message = { $summary }。繼續之前，請開啟 Windows 安全性並確認四個開關都已關閉。
summary-this-install = 安裝摘要
summary-try-again = 再試一次前請先檢視設定
summary-ready = 檢視您的 Atlas 設定
summary-activation = 啟用
summary-activation-ok = 已啟用。Atlas 不會變更啟用狀態。
summary-activation-missing = 尚未啟用。您可以繼續，但 Atlas 不會啟用 Windows。
summary-activation-unknown = Atlas 不會變更您的 Windows 啟用狀態。
summary-duration = 預估時間
summary-duration-value = { $minutes } 分鐘，然後重新啟動
summary-restart-checkbox = 安裝完成後自動重新啟動電腦
summary-show-command = 顯示安裝命令
summary-hide-command = 隱藏安裝命令
summary-command-unavailable = 無法準備安裝命令。詳細資料：{ $error }
summary-not-chosen = 尚未選擇
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = 變更「{ $title }」
footer-still-checking = 正在準備安裝
footer-fix-items = 請先完成上方的檢查再繼續
footer-need-package = 請下載 Atlas 或開啟 Playbook 以繼續
footer-reading-security = 正在檢查防護開關
button-checking = 檢查中
button-installing = 安裝中
button-install = 安裝 Atlas
log-earlier-lines = 記錄檔中另有較早的 { $count } 行。
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = （完整記錄：{ $path }）

## The installing view

installing-checking-title = 最後一次檢查
installing-checking-line = 進行變更之前，Atlas 正在檢查您的電腦。這可能需要一點時間。
installing-title = 正在安裝 Atlas
installing-phase-preflight = 正在檢查電腦並準備安裝檔案。
installing-phase-staging = 正在準備安裝檔案。請讓電腦保持開機。
installing-phase-applying = 正在依您的選擇設定 Windows。請讓電腦保持開機並接上電源。
installing-phase-done = 正在完成安裝。請讓電腦保持開機。
installing-installed-title = Atlas 已安裝完成
# $time is a formatted clock time.
installing-started-just-now = 開始於 { $time }（不到一分鐘前）
installing-started-minutes = 開始於 { $time }（{ $minutes } 分鐘前）

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } 已安裝完成
installed-title = Atlas 已安裝完成
installed-ready = 一切就緒，您的電腦已可搭配 Atlas 使用。
installed-open-atlas = 檢視您的 Atlas 設定

## Settings

settings-title = 設定
settings-theme = 應用程式佈景主題
settings-theme-system = 與 Windows 一致
settings-theme-light = 淺色
settings-theme-dark = 深色
settings-theme-contrast-note = Atlas 正在使用您的 Windows 對比佈景主題色彩。
settings-theme-mica-note = 若要顯示半透明背景，請選擇與 Windows 相同的淺色或深色佈景主題。
settings-language = 語言
settings-language-system = 與 Windows 一致
# Under "與 Windows 一致": which language that gives. $language is a language's own name.
settings-language-system-detail = 選擇「與 Windows 一致」時：{ $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = 預覽 · 尚待語言審閱
preview-notice = { $language }是預覽版翻譯。
preview-notice-switch = 切換為英文
preview-notice-language = 變更語言
# $tag is a language tag (text).
settings-language-unavailable = 這個版本的 Atlas 沒有 { $tag }。目前顯示英文，您的語言選擇已保留。
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas 尚未支援您的 Windows 顯示語言（{ $languages }）。目前顯示英文。
settings-language-windows-unavailable = 無法檢查您的 Windows 顯示語言。目前顯示英文。詳細資料：{ $error }
# $locale is the regional format's own name, for example "中文 (台灣)".
settings-language-formats = 數字、日期與時間會依照您的 Windows 地區格式（{ $locale }）顯示。
settings-language-contribute = 在 GitHub 協助翻譯 Atlas
settings-installing = 安裝
settings-restart-label = 安裝完成後自動重新啟動電腦
settings-restart-locked = 安裝完成後才能變更這項設定。
settings-restart-description = 需要重新啟動才能完成設定。如果已開啟自動重新啟動，請在安裝前儲存您的工作。
settings-about = 關於
settings-about-app = Atlas Manager
settings-about-data = 應用程式檔案
settings-about-licence = 授權
settings-about-licence-value = GPL-3.0，自由且開放原始碼
settings-view-source = 在 GitHub 檢視原始程式碼
settings-open-data-folder = 開啟應用程式資料夾

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = 釋放休眠時用來儲存工作狀態的磁碟空間。休眠與快速啟動將無法使用。
consequence-disable-power-saving = 關閉省電功能。電腦可能耗電更多、溫度更高，電池續航力也可能縮短。
consequence-disable-core-isolation = 關閉 Windows 的一層額外安全防護，包括記憶體完整性。這會降低防護，也可能影響需要這項功能的應用程式或遊戲。
consequence-remove-snipping-tool = 移除用來擷取螢幕畫面與錄製螢幕的 Windows 應用程式。
consequence-uninstall-edge = 移除 Microsoft Edge 瀏覽器。請確認您已有其他瀏覽器，或在下方選擇一個。
consequence-install-another-browser = 在下方選擇瀏覽器，Atlas 會為您安裝。

# Introduction on the home page before Atlas is installed.
home-intro = Atlas 會調整 Windows，減少背景活動與干擾。在進行任何變更之前，我們會引導您完成檢查與各項選擇。

detail-build-missing = 這個 Playbook 未宣告任何支援的 Windows 組建。請選擇完整的 Playbook 組建，而非 LocalTest 套件。
## ISO creation (Beta)
iso-home-title = Windows 安裝媒體
iso-home-description = 建立包含 Atlas 的 Windows ISO，以便在這部或其他電腦上全新安裝。
iso-open = 建立 Atlas ISO
iso-title = 建立 Atlas ISO
iso-beta = 測試版
iso-beta-description = 在電腦上使用前，請先在虛擬機器中測試 ISO。安裝 Windows 前，請備份檔案。
iso-admin-description = 讀取 Windows 映像及建立安裝媒體需要系統管理員權限。
iso-files-description = 選取未經修改的 Windows 11 x64 ISO、Atlas Playbook (.apbx)，並為產生的檔案指定新名稱。
iso-source = Windows ISO
iso-package = Atlas Playbook (0.6+)
iso-output = 新 ISO 的儲存位置
iso-no-file = 尚未選取檔案
iso-browse = 瀏覽
iso-save-as = 另存新檔
iso-inspect = 檢查檔案
iso-mode-title = Windows 和 Atlas 偏好設定
iso-mode-interactive = 登入後選擇 Atlas 設定
iso-mode-interactive-description = 登入後，Atlas 應用程式會協助你更新 Windows 和市集應用程式、選擇設定並套用 Atlas。
iso-mode-before = 立即選擇 Atlas 設定
iso-mode-before-description = 將 Atlas 設定儲存至 ISO。登入後，先更新 Windows 和市集應用程式，再依這些設定套用 Atlas。
iso-package-unsupported-title = 請選擇較新的 Playbook
iso-package-unsupported = ISO 設定需要支援 ISO 的 Atlas 0.6 或更新版本。請選擇相容的 Playbook。
iso-atlas-options = Atlas 設定
iso-review = 檢閱 ISO 設定
iso-review-description = Atlas 會建立新的 ISO，並保留原始檔案。若要安裝 Windows，請從新 ISO 啟動。建立 ISO 不會在這部電腦上安裝 Atlas。
iso-review-files = 檔案
iso-review-package = Atlas Playbook
iso-review-output = 新 ISO
iso-review-editions = 版本
iso-review-size = 大小
iso-review-size-value = { $size } MB
iso-review-account = 帳戶名稱
iso-review-target = 安裝到
iso-review-drivers = 驅動程式
iso-create = 建立 ISO
iso-stage-inspect = 正在檢查 Windows 映像
iso-stage-copy = 正在複製 Windows 檔案
iso-stage-inject = 正在加入 Atlas
iso-stage-master = 正在建立 ISO
iso-stage-verify = 正在驗證產生的檔案
iso-stage-cleanup = 正在完成最後步驟
iso-progress-description = 請保持應用程式開啟。處理大型映像可能需要一些時間。
iso-cancel = 取消建立
iso-cancelling = 正在等待可安全取消的時機
iso-cancelled = 已取消建立 ISO
iso-cancelled-description = 原始 ISO 已保留。若仍有需要清理的暫存檔案，診斷記錄中會有說明。
iso-complete = ISO 已準備就緒
iso-complete-description = 請先在虛擬機器中測試，再用它建立 Windows 安裝媒體。
iso-open-folder = 在資料夾中顯示
iso-failed = 無法完成 ISO 建立
iso-failed-description = 開啟診斷以查看失敗原因。解決問題後，請使用新的輸出檔名再試一次。
iso-diagnostics = 開啟診斷
iso-close-title = ISO 仍在建立中
iso-close-message = 請保持此視窗開啟，直到建立或取消完成。取消作業會等待目前步驟可以安全停止後再執行。
iso-keep-open = 保持開啟
prepare-title = 更新 Windows 和市集應用程式
prepare-description = 套用 Atlas 前，請安裝 Windows 更新，並更新 Microsoft Store 及所有已安裝的市集應用程式。更新期間，市集應用程式可能會關閉。
prepare-complete = Windows 和市集應用程式都已更新。
prepare-reboot = Windows 需要重新啟動。你的 Atlas 選項將會儲存。登入後，請再次檢查更新。
prepare-failed = 部分更新無法完成。請查看診斷記錄，排除 Windows 或市集錯誤後再試一次。
prepare-cancelled = 準備已停止。繼續之前，請再次檢查更新。
prepare-windows-search = 正在檢查 Windows 更新…
prepare-windows-download = 正在下載 Windows 更新…
prepare-windows-install = 正在安裝 Windows 更新…
prepare-store-search = 正在檢查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其應用程式…
prepare-stop-description = 目前的更新作業完成後才會停止。停止前，請保持 Atlas 開啟。
prepare-stop = 此作業完成後停止
prepare-restart = 重新啟動並繼續
prepare-start = 檢查並安裝更新
iso-username = 本機帳戶名稱
iso-account-description = 重新安裝 Windows 後，會提示你設定密碼。
iso-username-placeholder = 你的名字
iso-account-invalid = 請輸入 1–20 個字元，開頭和結尾不得有空格，也不能包含 Windows 帳戶名稱中不允許的符號。
iso-privacy-defaults = Windows 安裝程式會自動關閉選用資料分享和個人化優惠。
prepare-drivers = 要如何安裝驅動程式？
prepare-drivers-auto = 透過 Windows Update 取得驅動程式
prepare-drivers-auto-detail = Windows 會為硬體尋找驅動程式。建議大多數電腦使用。
prepare-drivers-manual = 自行安裝驅動程式
prepare-drivers-manual-detail = 封鎖 Windows Update 下載驅動程式。你需要自行取得驅動程式；已安裝的驅動程式會保留。
prepare-network-needed = 請連線至未設為計量付費的 Wi-Fi 或乙太網路，然後再試一次。如果沒有 Wi-Fi 選項，請先安裝網路驅動程式。
prepare-network-settings = 開啟網路設定
iso-target-title = 要在哪台電腦上重新安裝 Windows？
iso-target-this = 這台電腦
iso-target-other = 另一台電腦
iso-copy-network = 包含這台電腦的網路驅動程式
iso-network-detail = 安裝 Windows 時沿用這台電腦的 Wi-Fi 和乙太網路驅動程式。重灌後需要重新連線至 Wi-Fi。
iso-network-source = 網路驅動程式來源
iso-network-installed = 使用已安裝的驅動程式
iso-network-updated = 先檢查 Windows Update
iso-network-updated-detail = 下載 Windows Update 提供的相符驅動程式，並保留已安裝的驅動程式作為備用。需要非計量付費的連線。
iso-stage-network-drivers = 正在準備網路驅動程式…
iso-network-failed = 無法準備網路驅動程式。請查看診斷資訊，或返回並變更網路驅動程式選項。
iso-mode-desktop = 進入桌面前完成設定
iso-mode-desktop-description = 現在選擇 Atlas 設定。登入後，先完成更新和 Atlas 設定，再進入 Windows 桌面。
desktop-setup-description = 請完成電腦設定。你的 Atlas 選項已儲存，需要時可以返回 Windows。
desktop-setup-exit = 在 Windows 中繼續

# Windows installation USB (Beta)
usb-title = 建立安裝隨身碟
usb-existing = 使用現有 ISO 建立隨身碟
usb-description = 建立 Windows 11 25H2 開機隨身碟，用來在電腦上安裝 Windows 和 Atlas。
usb-choose-iso = 選擇 ISO
usb-drive = USB 磁碟機
usb-empty = 連接 USB 磁碟機後重新整理清單。這裡只會顯示可寫入，且未包含目前執行中 Windows 系統的 USB 磁碟機。
usb-refresh = 重新整理
usb-drive-detail = { $size } GB · { $volumes } · 序號：{ $serial }
usb-review = 檢查隨身碟
usb-erase-title = 要清除這個 USB 磁碟機嗎？
usb-erase-description = { $drive }（{ $size } GB）上的所有檔案與磁碟分割都將永久刪除。ISO 檔案會保留。
usb-layout = Windows 安裝檔案最多使用 32 GB，其餘空間維持未配置狀態。此隨身碟適用於 UEFI 電腦。
usb-ack = 我了解這個 USB 磁碟機上的所有內容都將被刪除。
usb-write = 清除並建立隨身碟
usb-stage-prepare = 正在準備安裝檔案…
usb-stage-format = 正在格式化隨身碟…
usb-stage-copy = 正在複製安裝檔案…
usb-stage-verify = 正在驗證隨身碟…
usb-working = 請保持 Atlas 開啟，並維持隨身碟連線。取消作業會等待目前的處理程序安全停止。未完成的隨身碟無法用來安裝 Windows。
usb-failed = 無法完成隨身碟建立作業。請檢查連線，並開啟診斷查看詳細資訊。重新選擇磁碟機後再試一次。
usb-cancelled = 隨身碟建立作業已停止。磁碟機上可能留有不完整的安裝檔案。請重新建立後再用來安裝 Windows。
usb-complete = 隨身碟已準備就緒，所有檔案均已驗證。請先退出隨身碟，再連接到要重灌的電腦，並在該電腦的 UEFI 開機選單中選擇它。
usb-eject = 退出隨身碟
usb-ejected = 現在可以安全拔除隨身碟。安裝 Windows 時，請在電腦的 UEFI 開機選單中選擇它。
usb-eject-failed = Windows 無法退出隨身碟。請關閉正在使用它的檔案或視窗，然後再試一次。
ready-fresh-title = 請先全新安裝 Windows
ready-fresh-description = 除支援的 Atlas 升級外，Atlas 需要全新安裝的 Windows。全新安裝 Atlas 0.6 需要 Windows 11 25H2。重新安裝 Windows 前，請備份檔案。
detail-edition-unsupported = 請使用 Windows 11 Pro、Pro for Workstations 或 Enterprise。不支援 Home、LTSC 和 Server 版本。如果無法識別您的版本，請先解決此問題再繼續。
install-source-title = 無法安裝
install-source-unsupported = Atlas { $source } 無法直接更新至 { $target }。請重新安裝 Windows 後再使用此版本。
install-source-unknown = Atlas 無法確認安裝狀態。請先處理尚未完成的安裝並檢查診斷資訊，然後再試一次。
iso-edition-selection = 僅包含支援的版本。安裝 Windows 時，請選擇你擁有 Windows 授權的版本。
detail-windows-preview = 不支援 Insider 預覽組建。請使用 Windows 11 的正式發行版本。
detail-windows-release-unknown = Atlas 無法確認此 Windows 組建是否已正式發行。請連線至網際網路後重新檢查。
iso-release-unknown = 無法確認此 ISO 是否包含正式發行的 Windows 11 25H2。請連線至網際網路後重試，或選擇官方安裝媒體。
prepare-previous-worker = 先前的更新作業仍在執行。Atlas 會等待作業完成，之後您就可以重試。

ready-used-windows-title = 請先重新安裝 Windows 再繼續
ready-used-windows-description = 此 Windows 系統存在已使用的跡象。在此系統上安裝 Atlas 不受支援，我們強烈建議不要這樣做。僅在你了解風險的情況下繼續。
ready-used-windows-dismiss = 我了解風險
playbook-option-install-eclean = 安裝 eclean
consequence-install-eclean = AtlasOS 團隊打造的維護工具，協助您在設定完成後保持電腦整潔。檢查垃圾檔案和啟動應用程式。需要帳戶和網際網路連線。

prepare-resumed = Windows 已重新啟動。你的 Atlas 選項已還原。請在安裝 Atlas 前繼續更新。
prepare-continue = 繼續更新
prepare-saving-restart = 正在儲存你的選項，並設定在 Windows 重新啟動後開啟 Atlas…
prepare-restart-save-failed = 無法儲存你的選項。請在重新啟動前重試。
prepare-restart-registration-failed = 你的選項已儲存，但無法設定自動重新開啟。請重試，或重新啟動 Windows 後手動開啟 Atlas。
prepare-restart-failed = Windows 無法重新啟動。請重試，或透過 Windows 重新啟動。你的選項已儲存，Atlas 已設定為重新開啟。
