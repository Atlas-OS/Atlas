### Atlas Manager: Chinese (Traditional) (zh-Hant), preview translation. Revised 1 October 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Serves zh-TW, zh-HK and zh-MO. Terminology follows Microsoft's Taiwan
### Windows glossary (設定, 系統管理員, 重新啟動, 檔案, 資料夾, 網路, 電腦).
### Full-width punctuation; one space between Chinese and Latin words or
### numbers. "重新開啟 Atlas" is reopening the app (and 重新開啟 also turns a
### protection back on); "重新啟動" is only restarting the PC / Windows. Chinese has only the "other" plural
### category; exact [1]/[2] variants are allowed.
### The .apbx file is the "Atlas 套件" (套件 alone once that is clear); the
### installation files card is 安裝檔案. Controls named in text are quoted
### with 「」 using their exact label from this catalog.

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
# Relaunches the Atlas Manager elevated (UAC), not the PC.
common-restart-as-administrator = 以系統管理員身分重新開啟 Atlas
common-try-again = 再試一次
common-read-the-docs = 閱讀 Atlas 使用指南
common-show-details = 顯示詳細資料
common-hide-details = 隱藏詳細資料
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }，{ $section }
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
# Joins the last two items of a list: "竄改防護和雲端提供的保護".
# $a may itself be several items joined with list-separator.
list-and = { $a }和{ $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }。{ $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = 要在 Atlas 安裝期間關閉視窗嗎？
window-close-message = 安裝會在背景繼續進行。再次開啟 Atlas 即可查看進度與結果。安裝完成前，請讓電腦保持開機。
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = 安裝會在背景繼續進行，但 Atlas 關閉期間，電腦不會自動重新啟動。再次開啟 Atlas 即可查看進度與結果。安裝完成前，請讓電腦保持開機。
window-close-keep = 保持開啟
window-close-close = 關閉視窗
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = 要在安裝開始前關閉視窗嗎？
window-close-preparing-message = Atlas 仍在檢查您的電腦，尚未開始安裝。如果現在關閉，安裝將不會開始。再次開啟 Atlas 即可繼續。
prepare-close-title = 更新仍在進行中
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = 更新期間請保持 Atlas 開啟。如果您選擇「停止更新」，更新會在目前步驟完成後停止，屆時您就可以關閉 Atlas。
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = 要關閉 Atlas 而不重新啟動嗎？
# "Restart now" is restart-now, one of this dialog's three buttons.
window-close-restart-message = 您的電腦需要重新啟動，才能完成 Atlas 設定。如果您現在關閉 Atlas，它不會重新啟動您的電腦，因此請在準備好後自行重新啟動。選擇「立即重新啟動」前，請先儲存您的工作。
window-close-restart-close = 關閉但不重新啟動
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = 要在防護關閉的狀態下關閉 Atlas 嗎？
window-close-protection-message = Windows 安全性中仍有部分防護處於關閉狀態：{ $switches }。如果您不打算完成 Atlas 的安裝，請在關閉前重新開啟這些防護。如果您會完成安裝，再次開啟 Atlas 時，它會繼續您的設定。
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = 開啟 Atlas 套件（.apbx）
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
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = 這台電腦上的 Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = 安裝於 { $date }
home-status-checking = 正在檢查更新
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
home-restart-title = 您的電腦需要重新啟動
home-security-reminder-title = 請重新開啟防護
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = 請確認防護已開啟
home-security-reminder-message = Atlas 目前沒有在安裝任何項目，但 Windows 安全性中仍有部分防護處於關閉狀態。請開啟 Windows 安全性，並確認下列項目已開啟：{ $switches }。
home-security-reminder-unreadable-message = Atlas 無法檢查所有防護開關。請在 Windows 安全性中確認下列項目已開啟：{ $switches }。
home-elevation-title = Atlas 需要權限才能安裝
home-state-error-title = 無法讀取 Atlas 的安裝資訊
home-state-error-message = 您的 Atlas 版本、選擇和安裝歷程可能無法正確顯示。請選擇「再次檢查」重試。詳細資料：{ $error }
home-whats-new = Atlas { $version } 的新功能
home-view-release = 在 GitHub 檢視版本資訊
home-released = 發行於 { $date }
home-show-less = 顯示較少
home-show-full-notes = 顯示完整版本資訊
home-your-install = 您的 Atlas 設定
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = 這台電腦未記錄 Atlas 的安裝方式，因此無法顯示您的選擇與安裝歷程。
# Row label: how Atlas was set up.
home-set-up = 設定方式
home-set-up-during-oobe = Windows 初始設定期間
home-history = 安裝歷程
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = 讓您的電腦為 Atlas 做好準備
home-step-1-detail = Atlas 會檢查您的電腦、安裝等待中的 Windows 與 Microsoft Store 更新，並下載安裝檔案。市集應用程式可能會關閉，電腦也可能需要重新啟動，因此請先儲存您的工作。
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas 會檢查您的電腦、安裝等待中的 Windows 與 Microsoft Store 更新，並準備內建的安裝檔案。市集應用程式可能會關閉，電腦也可能需要重新啟動，因此請先儲存您的工作。
home-step-2-detail = 選擇是否保留 Microsoft Defender 和處理器防護、Windows 要如何安裝更新，以及要加入哪些選用項目。
home-step-3-detail = 關閉 Windows 安全性中的四個防護開關，以免它們阻擋安裝。Atlas 會告訴您怎麼做。
home-step-4-detail = 安裝大約需要 { $minutes } 分鐘，之後您的電腦需要重新啟動。
# Accessible name of a numbered step.
home-step-a11y = 步驟 { $number }：{ $title }
home-github = 在 GitHub 檢視 Atlas 專案
home-discord = 加入 Atlas 的 Discord 社群
home-report-problem = 回報問題

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
# $error is a raw error message (text).
notice-settings-not-saved = Atlas 無法儲存您最近的變更，關閉 Atlas 後這些變更可能會遺失。如果還開著另一個 Atlas 視窗，請將其關閉，然後重新進行變更。詳細資料：{ $error }
notice-session-unreadable-title = 無法確認上次的安裝狀態
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = 第 { $number } 步，共 { $total } 步，{ $title }，{ $status }
stepper-status-completed = 已完成
stepper-status-current = 目前步驟
stepper-status-upcoming = 尚未進行
stepper-status-attention = 需要留意
# Heading above each step's content.
step-heading = 第 { $number } 步，共 { $total } 步：{ $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }。{ $progress }：{ $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }。{ $progress }

## Step 1: Get ready

ready-banner-busy-title = 正在準備您的電腦
ready-banner-busy-message = Atlas 正在檢查您的電腦並準備安裝檔案。
ready-banner-blocked-title = 您的電腦尚未準備就緒
ready-banner-blocked-message = 請處理「電腦檢查」中標示的項目，然後選擇「再次檢查」。
ready-banner-no-package-title = 請先下載 Atlas
ready-banner-no-package-message = 請在「安裝檔案」中下載 Atlas；如果您已有 Atlas 套件（.apbx），請選擇「開啟套件檔案」。
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = 請準備內建的 Atlas 套件以繼續
ready-banner-no-package-bundled-message = 此測試版內建的 Atlas 套件尚未就緒。請查看「安裝檔案」卡片。
ready-banner-updates-title = 請更新 Windows 和市集應用程式以繼續
ready-banner-updates-message = 請選擇「檢查並安裝更新」。更新完成後，Atlas 會再次檢查您的電腦。
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = 正在更新 Windows 和市集應用程式
ready-banner-updating-message = 這可能需要一段時間。請保持 Atlas 開啟。您可以在「更新 Windows 和市集應用程式」中查看進度。
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = 更新已停止
ready-banner-updates-stopped-message = 請在「更新 Windows 和市集應用程式」中選擇「檢查並安裝更新」，以完成更新。
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = 您的電腦已重新啟動
ready-banner-updates-resumed-message = 請在「更新 Windows 和市集應用程式」中選擇「繼續更新」，以完成更新。
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = 請查看「更新 Windows 和市集應用程式」中的處理方式，然後選擇「再試一次」。
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = 請先儲存您的工作，然後在「更新 Windows 和市集應用程式」中選擇「重新啟動並繼續」。
ready-banner-warnings-title = 有幾點需要留意
ready-banner-warnings-message = 您可以繼續，但請先閱讀「電腦檢查」中標示的項目。
ready-banner-ok-title = 準備就緒，可以開始進行選擇了
ready-banner-ok-message = 檢查已通過，安裝檔案也已就緒。

# Card title and accessible name of the list of checks.
ready-this-pc = 電腦檢查
ready-check-again = 再次檢查
ready-checks-passed = 已通過 { $count } 項檢查

package-title = 安裝檔案
# $received and $total are formatted numbers of megabytes (text).
package-downloading = 正在下載 Atlas { $version } · { $received } / { $total } MB
package-unpacking-progress = 正在解壓縮 · { $done } / { $total } 個檔案
package-unpacking = 正在解壓縮
package-looking = 正在查詢最新的 Atlas 版本。
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = 正在準備內建的 Atlas 套件。
package-none = 請下載 Atlas 以取得安裝檔案。如果您已有 Atlas 套件（.apbx），也可以直接開啟它。
# The GitHub release check failed. "Download latest version" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas 無法查詢最新版本。請檢查網際網路連線，然後選擇「下載最新版本」，或開啟已儲存的 Atlas 套件（.apbx）。
# Short status words beside the card title.
package-status-downloading = 下載中
package-status-unpacking = 解壓縮中
package-status-failed = 無法準備檔案
package-status-ready = 就緒
package-status-checking = 檢查中
package-status-preparing = 準備中
package-status-missing = 尚未下載
# Accessible name of the progress bar.
package-progress = 安裝檔案準備進度
package-download-again = 重新下載
package-download-version = 下載 Atlas { $version }
package-download-newest = 下載最新版本
package-cancel-download = 取消下載
package-open-file = 開啟套件檔案
# Where the package came from. $file is a file name (text).
package-from-release = 已從 GitHub 下載 Atlas { $version }，可以安裝。
package-from-file = 已從 { $file } 載入 Atlas { $version }，可以安裝。
package-unpacked = Atlas { $version } 已可安裝。
package-none-yet = 尚未選擇安裝檔案
acquire-no-asset = Atlas { $version } 沒有可下載的套件檔案。請開啟已儲存的 Atlas 套件（.apbx）以繼續。
acquire-unsupported = 這個應用程式可安裝 Atlas 0.6.0 及更新版本。若要安裝 Atlas { $version }，請改用 AME Wizard。
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } 缺少這個應用程式進行安裝所需的檔案。請重新下載，或開啟其他 Atlas 套件（.apbx）。
acquire-failed = 無法準備安裝檔案。請重新下載，或開啟其他 Atlas 套件（.apbx）。詳細資料：{ $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = 下載已停止回應。請檢查網際網路連線，然後重新下載，或開啟已儲存的 Atlas 套件（.apbx）。
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = 無法準備內建的 Atlas 套件。請選擇「再試一次」。詳細資料：{ $error }

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
check-fix-apps = 開啟「已安裝的應用程式」
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = 我已查看 Windows Update，沒有等待安裝的更新

detail-admin-ok = Atlas 已具備進行安裝變更所需的權限。
detail-admin-missing = 請以系統管理員身分重新開啟 Atlas，並在 Windows 要求權限時選擇「是」。
# $builds is a list of build numbers such as "26100 或 26200"; $build is this PC's (text).
detail-build-unsupported = 這個 Atlas 版本需要 Windows 組建 { $builds }，而這台電腦的組建為 { $build }。請先安裝支援的 Windows 版本再繼續。
detail-build-missing = 這個 Atlas 套件未列出任何支援的 Windows 組建。請使用完整組建的套件，而非 LocalTest 組建。
detail-updates-none = 沒有等待安裝的 Windows 更新。
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] 這個更新正在等待安裝：{ $titles }。Atlas 會在「更新 Windows 和市集應用程式」中安裝此更新。
        [2] 這些更新正在等待安裝：{ $titles }。Atlas 會在「更新 Windows 和市集應用程式」中安裝這些更新。
       *[other] 有 { $count } 個更新正在等待安裝，包括 { $titles }。Atlas 會在「更新 Windows 和市集應用程式」中安裝這些更新。
    }
detail-updates-unknown = 無法檢查 Windows 更新。請開啟 Windows Update 查看；如果沒有等待安裝的更新，請在下方確認。（{ $error }）
detail-reboot-none = Windows 目前不需要重新啟動。
detail-reboot-pending = Windows 需要重新啟動，才能完成先前的變更。當您選擇「檢查並安裝更新」時，Atlas 會先請您重新啟動。
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Windows 需要重新啟動，才能完成先前的變更（{ $reasons }）。當您選擇「檢查並安裝更新」時，Atlas 會先請您重新啟動。
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = 您可以繼續。Windows 有檔案要在下次重新啟動時取代或移除（{ $files }）。部分應用程式（例如 Xbox Gaming Services）每次重新啟動後都會如此。
detail-reboot-unknown = 無法確認 Windows 是否需要重新啟動。請重新啟動電腦，然後重新開啟 Atlas 並再次檢查。（{ $error }）
detail-antivirus-none = 未偵測到其他防毒軟體。
# $products is a list of product names (text).
detail-antivirus-found = Microsoft Defender 以外的防毒應用程式可能會阻擋安裝。請解除安裝 { $products }，然後選擇「再次檢查」。
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows 安全性仍列出 { $products }，但其檔案已不存在，因此它已不再安裝於電腦上。Atlas 仍可繼續安裝。
detail-antivirus-unknown = 無法檢查是否有其他防毒軟體。請選擇「再次檢查」。如果持續失敗，請重新啟動電腦後再次檢查。（{ $error }）
detail-internet-ok = 已連線。Atlas 下載並安裝軟體期間，請保持網路連線。
detail-internet-missing = 請連線到網際網路，然後再次檢查。
detail-power-mains = 電腦已接上電源。安裝完成前請保持連接。
detail-power-battery = 請將電腦接上電源，讓它在整個安裝期間保持開機。
detail-power-unknown = Atlas 無法判斷您的電腦是否已接上電源。如果是筆記型電腦，請接上電源，然後選擇「再次檢查」。如果持續發生這種情況，請選擇「傳送報告」。
detail-activation-ok = Windows 已啟用。Atlas 不會變更啟用狀態。
detail-activation-missing = Windows 尚未啟用。您可以繼續，但 Atlas 不會為您啟用 Windows。
detail-activation-no-licence = Windows 未回報授權。您可以繼續；Atlas 不會變更您的啟用狀態。
detail-activation-unknown = 無法檢查 Windows 啟用狀態。您可以繼續；Atlas 不會變更您的啟用狀態。（{ $error }）

## Step 2: Options

options-progress = 第 { $number } 項選擇，共 { $total } 項
options-progress-extras = 第 { $number } 項選擇，共 { $total } 項：選用項目
options-change-later = 您之後可以從桌面上的 Atlas 資料夾變更 Microsoft Defender、處理器防護和更新設定。
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
# Question for a required choice this app has no specific wording for.
screen-generic-question = 請為「{ $title }」選擇一個選項
learn-more-defender = 深入了解 Microsoft Defender
learn-more-mitigations = 深入了解處理器防護
learn-more-updates = 深入了解 Windows Update
learn-more-browser = 深入了解瀏覽器
learn-more-power = 深入了解電源與安全性
learn-more-apps = 深入了解應用程式
learn-more-eclean = eclean 如何與 AtlasOS 搭配使用
learn-more-generic = 閱讀設定指南
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = 保留 Windows 內建的防毒軟體，協助保護電腦免受病毒與其他威脅。
consequence-defender-disable = 同時會移除 SmartScreen。在您安裝其他防毒應用程式之前，電腦將沒有任何防毒保護，而且在您開啟無法辨識的應用程式或下載的檔案前，Windows 也不會警告您。
consequence-mitigations-default = 保留 Windows 的預設防護，抵禦處理器漏洞，以及利用應用程式錯誤的攻擊。
consequence-mitigations-disable = 同時會關閉應用程式的「惡意探索保護」，例如控制流程防護（CFG）。這會降低安全性。效能差異視您的處理器而定。
consequence-auto-updates-disable = 請定期開啟 Windows Update 安裝更新。更新通知仍會顯示。
consequence-auto-updates-default = Windows 會自動安裝更新，包括安全性修正。

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = 保留 Microsoft Defender（建議）
playbook-option-defender-disable = 移除 Microsoft Defender
playbook-option-mitigations-default = 保留處理器防護（建議）
playbook-option-mitigations-disable = 關閉處理器防護
playbook-option-auto-updates-disable = 自行安裝更新
playbook-option-auto-updates-default = 自動安裝更新
playbook-option-disable-hibernation = 關閉休眠
playbook-option-disable-power-saving = 關閉省電功能
playbook-option-disable-core-isolation = 關閉虛擬化型安全性（VBS）
playbook-option-remove-snipping-tool = 移除剪取工具
playbook-option-uninstall-edge = 移除 Microsoft Edge
playbook-option-install-another-browser = 安裝瀏覽器
playbook-option-install-toolbox = 安裝 Atlas Toolbox
playbook-option-install-eclean = 安裝 eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender 是 Windows 內建的防毒軟體。只有在您了解風險，並打算使用其他防毒應用程式時，才移除它。無論您選擇哪一項，Atlas 都會關閉「智慧型應用程式控制」、「增強式網路釣魚保護」和「尋找我的裝置」。
playbook-page-mitigations-default-description = 這些防護（也稱為安全性緩和措施）有助於抵禦 Spectre 和 Meltdown 等處理器漏洞，以及利用應用程式錯誤的攻擊。建議保留 Windows 的預設值。
playbook-page-auto-updates-disable-description = Windows 更新包含安全性修正。您可以讓 Windows 自動安裝更新，或自行安裝。無論選擇哪一種，Atlas 都會讓 Windows 維持在目前的版本，而該版本只會在 Microsoft 終止支援前收到安全性修正。Atlas 也會關閉 Microsoft Store 應用程式的自動更新，因此請在 Microsoft Store 中更新這些應用程式。
playbook-page-browser-brave-description = 選擇要安裝的瀏覽器。Atlas 不會變更您的瀏覽器設定。

## Step 3: Windows Security

security-banner-reading-title = 正在檢查 Windows 安全性
security-banner-reading-message = Atlas 正在檢查下方的四個防護開關。
security-banner-off-title = 四個防護開關都已關閉
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = 這台電腦未安裝 Microsoft Defender
security-banner-absent-message = 此步驟沒有需要關閉的項目。請選擇「繼續」。
security-banner-off-message = 請選擇「繼續」以檢視您的設定並安裝 Atlas。
security-banner-on-title = 請在 Windows 安全性中關閉防毒保護
security-banner-on-message = Microsoft Defender 可能會阻擋 Atlas 進行的變更。請選擇「開啟 Windows 安全性」，並關閉下方列出的每個開關。如果您保留 Microsoft Defender，請在安裝完成後重新開啟這些開關。
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
security-unknown-message = 請在 Windows 安全性中檢查四個開關都已關閉，然後在下方確認。
security-acknowledge = 我已檢查 Windows 安全性，四個開關都已關閉
security-unknown-unelevated-title = Atlas 需要權限才能檢查防護狀態
security-unknown-unelevated-message = 請以系統管理員身分重新開啟 Atlas，才能檢查 Microsoft Defender 的設定。
# The four switches, named as Windows Security names them in Traditional Chinese.
protection-tamper = 竄改防護
protection-tamper-why = 關閉此項，以免 Defender 阻止 Atlas 變更其安全性設定。
protection-realtime = 即時保護
protection-realtime-why = 關閉此項，以免 Defender 在掃描時阻擋 Atlas 的安裝檔案。
protection-cloud = 雲端提供的保護
protection-cloud-why = 關閉此項，以免線上威脅檢查阻擋 Atlas 的安裝檔案。
protection-samples = 自動提交範例
protection-samples-why = 避免 Defender 自動將 Atlas 的檔案傳送給 Microsoft 分析。

## Step 4: Install

# Accessible name of the progress bar.
install-progress = 安裝進度
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = Atlas 已安裝完成
outcome-lost-title = 無法確認安裝結果
outcome-failed-title = 安裝未完成
outcome-requirements = 您的電腦不符合安裝需求。未進行任何安裝變更。請返回「準備」重新執行檢查。
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = 您的電腦不符合安裝需求，因此這次嘗試已停止。先前的嘗試已開始進行變更。請返回「準備」重新執行檢查。
outcome-not-elevated = Atlas 沒有系統管理員權限。未進行任何安裝變更。請以系統管理員身分重新開啟 Atlas，然後再試一次。
outcome-not-elevated-resumed = Atlas 沒有系統管理員權限，因此這次嘗試已停止。先前的嘗試已開始進行變更。請以系統管理員身分重新開啟 Atlas，然後再試一次。
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "Check and install updates" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas 無法確認 Windows 和市集應用程式都已更新，因此安裝在變更 Windows 前已停止。請返回「準備」並選擇「檢查並安裝更新」。
outcome-preparation-stale-resumed = Atlas 無法確認 Windows 和市集應用程式都已更新，因此這次嘗試已停止，但先前的嘗試已開始進行變更。請返回「準備」並選擇「檢查並安裝更新」。
outcome-failed-preflight = 安裝在進行任何變更前已停止。您可以再試一次。如果再次停止，請選擇「傳送報告」。
outcome-failed-staging = 安裝在準備檔案時停止，尚未變更 Windows。您可以再試一次。如果再次停止，請選擇「傳送報告」。
outcome-failed-applying = 部分變更可能已經生效。您可以再試一次。如果您要就此停止，請在 Windows 安全性中重新開啟先前關閉的防護（如果它們仍然存在）。
outcome-failed-resumed = 這次嘗試提早停止，但先前的嘗試已開始進行變更。您可以再試一次。如果您要就此停止，請在 Windows 安全性中重新開啟先前關閉的防護（如果它們仍然存在）。
outcome-not-started = 安裝程式未能及時啟動。未進行任何安裝變更。您可以再試一次。
outcome-lost = 安裝程式在回報結果前就已停止，部分變更可能已經生效。您可以再試一次。如果您要就此停止，請在 Windows 安全性中重新開啟先前關閉的防護（如果它們仍然存在）。
restart-now-message = Windows 正在重新啟動，以完成 Atlas 設定。
restart-countdown = Windows 將在 { $seconds } 秒後重新啟動，以完成 Atlas 設定。若要先儲存您的工作，請選擇「稍後重新啟動」。
restart-stopped = 已取消自動重新啟動。請儲存您的工作，然後重新啟動電腦以完成 Atlas 設定。
restart-needed = 請儲存您的工作，然後重新啟動電腦以完成 Atlas 設定。
restart-dont-now = 稍後重新啟動
restart-now = 立即重新啟動
restart-start-failed = Atlas 無法重新啟動您的電腦。請儲存您的工作，然後從「開始」功能表重新啟動。詳細資料：{ $error }
preflight-title = 安裝尚未開始
preflight-invalid-options = Atlas 無法使用這些設定選擇。請返回「您的選擇」重新檢視，然後再試一次。詳細資料：{ $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = 您的電腦狀態在先前檢查後已有變化。請先解決下列問題，再試一次。{ $problems }
preflight-problem = { $title }：{ $detail }
# $summary is the Windows Security summary such as "2 個仍開啟".
preflight-security = Windows 安全性：{ $summary }。
preflight-busy = 另一個 Atlas 視窗正在開始安裝。請稍候片刻，然後再次選擇「安裝 Atlas」。
# Shown with the home-start-over button.
preflight-taken-over = 另一個 Atlas 視窗已接手這次設定，因此安裝尚未開始。請在該視窗中繼續，或選擇「重新開始」在這裡重新設定。
preflight-record-unreadable = Atlas 無法確認上次的安裝是否仍在進行，因此沒有開始新的安裝。請返回「準備」查看後續步驟。詳細資料：{ $error }
preflight-refused = 無法啟動安裝程式。未進行任何安裝變更。請選擇「安裝 Atlas」再試一次。如果持續發生，請選擇「傳送報告」。詳細資料：{ $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = 無法啟動安裝程式，因此這次嘗試已停止。先前的嘗試已開始進行變更。請選擇「安裝 Atlas」再試一次。如果持續發生，請選擇「傳送報告」。詳細資料：{ $error }
go-to-ready = 返回「準備」
go-to-options = 返回「您的選擇」
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = 返回「安裝」
output-problem-title = 無法讀取安裝進度
output-problem-message = Atlas 無法讀取記錄，但這不代表安裝已停止。請讓電腦保持開機，並嘗試開啟記錄檔。詳細資料：{ $error }
install-elevate-title = Atlas 需要權限才能安裝
install-no-package-title = 請先選擇安裝檔案
install-no-package-message = 請返回「準備」下載 Atlas，或開啟已儲存的 Atlas 套件（.apbx）。
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = 請返回「準備」，準備此測試版內建的 Atlas 套件。
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = 請先完成「準備」
install-not-ready-message = Atlas 需要先完成電腦檢查和 Windows 更新，才能開始安裝。
install-security-title = 安裝前請檢查防毒保護
install-security-reading = 正在再次檢查四個防護開關。
install-security-message = { $summary }。安裝之前，請開啟 Windows 安全性並確認四個開關都已關閉。
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
summary-copy-command-a11y = 複製安裝命令
summary-command-unavailable = 無法準備安裝命令。詳細資料：{ $error }
summary-not-chosen = 尚未選擇
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = 變更「{ $title }」
footer-still-checking = 正在準備安裝
footer-fix-items = 請先處理「電腦檢查」中的項目再繼續
footer-need-package = 請下載 Atlas 或開啟 Atlas 套件以繼續
# Tester build variant of footer-need-package.
footer-need-package-bundled = 請準備內建的 Atlas 套件以繼續
footer-reading-security = 正在檢查防護開關
footer-security-pending = 請關閉全部四個開關以繼續
footer-security-confirm = 若要繼續，請確認 Atlas 無法檢查的開關
footer-install-ready = 請先儲存您的工作並關閉應用程式
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
installing-restart-auto = 安裝完成後，電腦會自動重新啟動。請在那之前儲存您在其他應用程式中的工作。

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } 已安裝完成
installed-title = Atlas 已安裝完成
installed-ready = 一切就緒，您的電腦已可搭配 Atlas 使用。
installed-security-message = 您保留了 Microsoft Defender，但它的部分防護仍處於關閉狀態。請開啟 Windows 安全性，並確認下列項目已開啟：{ $switches }。
installed-defender-removed-title = 已移除 Microsoft Defender
installed-defender-removed-message = 在您安裝其他防毒應用程式之前，電腦將沒有任何防毒保護。SmartScreen 也已一併移除，因此在您開啟無法辨識的應用程式或下載的檔案前，Windows 不會警告您。
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = 您選擇了保留 Microsoft Defender，但目前找不到它。如果您沒有使用其他防毒應用程式，請安裝一個來保護您的電腦。如果不是您自行移除 Defender，請選擇「回報問題」。

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
settings-language-system-selected = { settings-language-system }（{ $language }）
# Under "與 Windows 一致": which language that gives. $language is a language's own name.
settings-language-system-detail = 選擇「與 Windows 一致」時：{ $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = 預覽版
# Under the language list, once, explaining the Preview tag.
settings-language-preview-note = 預覽版翻譯尚未經過母語人士審閱。
preview-notice = { $language }是預覽版翻譯，可能含有錯誤。
preview-notice-switch = 切換為英文
preview-notice-language = 變更語言
# $tag is a language tag (text).
settings-language-unavailable = 這個版本的 Atlas 沒有 { $tag }。目前顯示英文，您的語言選擇已保留。
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas 尚未支援您的 Windows 顯示語言（{ $languages }）。目前顯示英文。
settings-language-windows-unavailable = 無法檢查您的 Windows 顯示語言。目前顯示英文。詳細資料：{ $error }
# $locale is the regional format's own name, for example "中文 (台灣)".
settings-language-formats = 數字、日期與時間會依照您的 Windows 地區格式（{ $locale }）顯示。
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = 數字會依照您的 Windows 地區格式（{ $locale }）顯示。由於 Atlas 尚無法顯示由右至左的文字，日期與時間會使用標準格式。
settings-language-contribute = 在 GitHub 協助翻譯 Atlas
settings-restart-label = 安裝完成後自動重新啟動電腦
settings-restart-locked = 安裝完成後才能變更這項設定。
settings-restart-description = 開啟此設定後，電腦會在安裝完成後一分鐘內重新啟動，並關閉所有已開啟的應用程式。請在安裝前儲存您的工作。
settings-help = 說明與意見反應
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
consequence-disable-core-isolation = 關閉 Windows 的一層額外安全防護，包括記憶體完整性。這會降低防護，也可能影響需要這項功能的應用程式或遊戲。
consequence-remove-snipping-tool = 移除用來擷取螢幕畫面與錄製螢幕的 Windows 應用程式。
consequence-uninstall-edge = 移除 Microsoft Edge 瀏覽器。請確認您已有其他瀏覽器，或在下方選擇一個。
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = 移除 Microsoft Edge，並刪除這台電腦上 Edge 的「我的最愛」、歷程記錄和已儲存的密碼。未同步到 Microsoft 帳戶的資料都會遺失。請確認您已有其他瀏覽器，或在下方選擇一個。
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = 會刪除這台電腦上 Edge 的「我的最愛」、歷程記錄和已儲存的密碼。
consequence-install-another-browser = 在下方選擇瀏覽器，Atlas 會為您安裝。
consequence-install-toolbox = 加入 Atlas Toolbox，協助您管理 Atlas 設定。Toolbox 仍在測試階段，部分功能可能尚未完成。
consequence-install-eclean = AtlasOS 團隊打造的維護工具，協助您在設定完成後保持電腦整潔。檢查垃圾檔案和啟動應用程式。需要帳戶和網際網路連線。

# Introduction on the home page before Atlas is installed.
home-intro = Atlas 會調整 Windows，減少背景活動與干擾。請在全新安裝 Windows 後、加入您自己的應用程式和檔案之前安裝 Atlas。

## ISO creation (Beta)
iso-home-title = Windows 安裝媒體
iso-home-description = 建立包含 Atlas 的 Windows 安裝檔（ISO），然後用它在這台電腦或其他電腦上重新安裝 Windows。
iso-open = 建立 Atlas ISO
iso-title = 建立 Atlas ISO
iso-beta = 測試版
iso-beta-description = 在電腦上使用前，請先在虛擬機器中測試 ISO。安裝 Windows 前，請備份檔案。
iso-admin-description = Atlas 需要系統管理員權限，才能讀取您的 Windows ISO 並建立新的 ISO。請選擇「以系統管理員身分重新開啟 Atlas」，然後在 Windows 詢問時選擇「是」。
iso-files-description = Atlas 會複製一份 Windows 11 ISO 並加入 Atlas，用來重新安裝 Windows。請選擇從 Microsoft 下載的 Windows 11 ISO，下載最新的 Atlas 套件或選擇您已有的套件（.apbx），然後選擇新 ISO 的儲存位置。
# Tester build: no package picker.
iso-files-description-bundled = Atlas 會複製一份 Windows 11 ISO，並加入此測試版內建的 Atlas 套件。請選擇從 Microsoft 下載的 Windows 11 ISO，然後選擇新 ISO 的儲存位置。
iso-source = Windows ISO
iso-source-download = 從 Microsoft 下載 Windows 11
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Atlas 套件（{ $minimum } 或更新版本）
iso-output = 新 ISO 的儲存位置
iso-no-file = 尚未選取檔案
iso-browse = 瀏覽
iso-save-as = 另存新檔
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }：{ $field }
iso-inspect = 檢查檔案
iso-mode-title = 您要如何設定 Atlas？
iso-mode-interactive = 登入後進行 Atlas 選擇
iso-mode-interactive-description = 登入後，Atlas 會開啟並引導您完成更新、進行選擇並安裝 Atlas。
iso-mode-before = 立即進行 Atlas 選擇
iso-mode-before-description = Atlas 會將您的選擇儲存至 ISO。登入後，Atlas 會開啟並引導您完成更新，接著您就能依這些選擇安裝 Atlas。
iso-package-unsupported-title = 請選擇較新的 Atlas 套件
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported = 此 Atlas 套件無法將 Atlas 選擇儲存至 ISO。請選擇較新的套件，或選擇「登入後進行 Atlas 選擇」。
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = 此 Atlas 套件無法用來建立 ISO。請選擇適用於 Atlas { $minimum } 或更新版本的套件。
# Tester build: the bundled Atlas package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = 無法將 Atlas 選擇儲存至此 ISO
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported-bundled = 此測試版內建的 Atlas 套件不支援 ISO 設定。請改為選擇「登入後進行 Atlas 選擇」。
iso-atlas-options = Atlas 選擇
iso-review = 檢閱 ISO 設定
iso-review-description = 建立 ISO 不會在這台電腦上安裝任何項目，也不會變更您的原始 ISO。完成後，Atlas 可以將新 ISO 寫入 USB 磁碟機，讓您用它重新安裝 Windows。
iso-review-files = 檔案
iso-step-windows = Windows 安裝
iso-step-review = 檢閱
iso-review-package = Atlas 套件
iso-review-output = 新 ISO
iso-review-editions = 版本
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = 帳戶名稱
iso-review-target = 安裝到
iso-review-drivers = 驅動程式
iso-create = 建立 ISO
iso-progress-title = 正在建立您的 ISO
iso-stage-inspect = 正在檢查您的 Windows ISO
iso-stage-copy = 正在複製 Windows 檔案
iso-stage-add-atlas = 正在加入 Atlas
iso-stage-master = 正在寫入 ISO 檔案
iso-stage-verify = 正在檢查新 ISO
iso-stage-cleanup = 正在完成最後步驟
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }，{ $status }
iso-stage-status-current = 進行中
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = 失敗
iso-stage-status-not-started = 尚未開始
iso-progress-description = 請保持 Atlas 開啟。處理大型映像可能需要一些時間。
iso-cancel = 取消建立
iso-cancelling = 正在等待可安全取消的時機
iso-cancelled = 已取消建立 ISO
iso-cancelled-description = 您的原始 ISO 沒有任何變更。如果有遺留的暫存檔案，請選擇「開啟記錄資料夾」查看它們的位置。
iso-complete = ISO 已準備就緒
iso-complete-description = ISO 建立功能仍是測試版，因此請先在虛擬機器中測試此 ISO。接著選擇「建立安裝隨身碟」，並在重新安裝 Windows 前備份您的檔案。
iso-open-folder = 在資料夾中顯示
iso-failed = 無法完成 ISO 建立
iso-failed-description = 請確認您的檔案仍在選取的位置，且要儲存到的磁碟機仍已連接，然後選擇「建立 ISO」。如果持續失敗，請選擇「傳送報告」。
# Title while the Check files step fails; the messages below say why.
iso-check-failed = 無法檢查檔案
iso-check-failed-description = 請確認 ISO 和 Atlas 套件仍在您選取的位置，且已下載完成，然後選擇「檢查檔案」。如果持續失敗，請選擇「傳送報告」。
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas 需要權限才能建立 ISO
# Typed reasons reported by the image worker.
iso-failed-output-exists = 已有相同名稱的檔案。請選擇「另存新檔」並輸入新的檔名。
iso-failed-destination = Atlas 無法將新 ISO 儲存在該位置。請選擇「另存新檔」，並選取這台電腦上的資料夾，例如「下載」。網路位置以及格式化為 FAT32 或 exFAT 的磁碟機（許多 USB 磁碟機都是如此）都無法使用。
iso-failed-space = 目的地磁碟機的可用空間不足。請釋放空間，或將新 ISO 儲存到其他磁碟機。
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = 此 ISO 不包含支援的 Windows 版本。不支援 Windows Home 與 LTSC。請使用包含其他版本（例如 Pro、Education 或 Enterprise）的 ISO。
iso-failed-customised = 此 ISO 已包含自訂安裝檔案（例如 autounattend.xml）。請選擇 Microsoft 提供、未經修改的 Windows ISO。
iso-failed-windows-unsupported = Atlas 套件不支援此 Windows 映像。請使用未經修改的 64 位元 Windows 11 ISO，且版本須為此套件所支援。
iso-failed-network-architecture = 這台電腦的網路驅動程式與此 ISO 的架構不符。請返回並取消勾選「包含這台電腦的網路驅動程式」，或選擇適用於這台電腦的 ISO。
iso-failed-unstaged = Atlas 無法準備其工作資料夾，因此沒有進行任何變更。請再試一次。如果仍然失敗，請選擇「匯出診斷資訊」並附在錯誤報告中。
iso-failed-package-changed = 檢查檔案後，Atlas 套件已變更。請選擇「檔案」旁的「變更」，然後選擇「檢查檔案」。
iso-diagnostics = 開啟記錄資料夾
iso-close-title = ISO 仍在建立中
iso-close-message = 請保持此視窗開啟，直到建立或取消完成。取消作業會等待目前步驟可以安全停止後再執行。
iso-keep-open = 保持開啟
prepare-title = 更新 Windows 和市集應用程式
prepare-description = 安裝之前，Atlas 會更新 Windows、Microsoft Store 和您的市集應用程式。已開啟的市集應用程式（例如記事本、小畫家或 Windows 終端機）可能會在更新時關閉，因此請先儲存您在其中的工作。電腦也可能需要重新啟動。
prepare-complete = Atlas 沒有找到其他需要安裝的 Windows 或市集應用程式更新。
prepare-reboot-title = 請重新啟動電腦以繼續
prepare-reboot = 您的電腦需要重新啟動，才能完成更新的安裝。Atlas 會儲存您目前的選擇，並在您登入後重新開啟。
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = 您的電腦需要重新啟動，才能完成更新的安裝（{ $reasons }）。Atlas 會儲存您目前的選擇，並在您登入後重新開啟。
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = 請先儲存您的工作並關閉應用程式。選擇「重新啟動並繼續」後，電腦會立即重新啟動。
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = 電腦已重新啟動，但 Windows 仍表示需要重新啟動（{ $reasons }），因此再次重新啟動可能沒有幫助。請選擇「開啟 Windows Update」並完成其中所有等待中的項目，然後選擇「再試一次」。如果沒有等待中的項目，請選擇「傳送報告」。
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = Windows 元件服務
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = 等待取代的檔案
prepare-reason-update-agent = Windows Update 服務
prepare-reason-unknown = 未回報原因
prepare-failed = 請選擇「再試一次」。如果再次失敗，請在 Windows Update 或 Microsoft Store 中完成其餘的更新，或選擇「傳送報告」。
prepare-failed-title = 部分更新無法完成
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Try again" is common-try-again, the button beside it.
prepare-ended-unconfirmed = 更新在回報結果前就已停止，因此 Atlas 無法確認 Windows 和市集應用程式都已更新。請選擇「再試一次」檢查更新。
prepare-unconfirmed-title = 無法確認更新結果
# "Check and install updates" is prepare-start, its button in this state.
prepare-cancelled = 更新已停止。部分更新可能已經安裝。請選擇「檢查並安裝更新」完成更新後再繼續。
prepare-windows-search = 正在檢查 Windows 更新…
prepare-windows-download = 正在下載 Windows 更新…
prepare-windows-install = 正在安裝 Windows 更新…
prepare-store-search = 正在檢查 Microsoft Store…
prepare-store-install = 正在更新 Microsoft Store 及其應用程式…
prepare-stop-description = Atlas 會在目前步驟完成後停止。在那之前，請保持 Atlas 開啟。
prepare-stop = 停止更新
prepare-restart = 重新啟動並繼續
prepare-start = 檢查並安裝更新
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = 由於此安裝無法繼續，目前無法使用。請查看頁面頂端的訊息。
prepare-needs-build-check = 待「電腦檢查」中的「{ $check }」通過後即可使用。
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = 安裝檔案就緒後即可使用。
iso-username = 本機帳戶名稱
iso-account-description = Windows 安裝程式會以此名稱建立本機帳戶，因此您不需要 Microsoft 帳戶。第一次登入時，Windows 會請您設定密碼。
iso-username-placeholder = 您的名字
iso-account-empty = 請輸入本機帳戶名稱以繼續
iso-account-invalid = 最多可使用 20 個字元，開頭和結尾不能有空格，也不能包含下列任何符號：" / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = 名稱不能以句點「.」結尾。
iso-account-reserved = Windows 已將此名稱用於內建帳戶。請選擇其他名稱。
iso-privacy-defaults = 此 ISO 會略過 Windows 安裝程式中的授權、Microsoft 帳戶和隱私權畫面，並關閉選用的資料分享和個人化優惠。
prepare-drivers = 要如何安裝驅動程式？
prepare-drivers-auto = 透過 Windows Update 取得驅動程式
prepare-drivers-auto-detail = Windows 會為硬體尋找驅動程式。建議大多數電腦使用。
prepare-drivers-manual = 自行安裝驅動程式
prepare-drivers-manual-detail = Windows Update 不會安裝驅動程式，因此您需要向電腦或裝置製造商取得驅動程式。已安裝的驅動程式會保留。
prepare-drivers-description = 驅動程式讓 Windows 能使用您的硬體，例如顯示卡、音效和 Wi-Fi。如果您在更新後變更此設定，Atlas 需要再次檢查更新。
prepare-network-needed = 更新需要未設為計量付費的網際網路連線。請連線至 Wi-Fi 或乙太網路，然後選擇「再試一次」。如果看不到任何 Wi-Fi 網路，請先安裝網路驅動程式。
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows 回報此網路無法存取網際網路。如果網路要求登入，請先登入；或檢查路由器以及任何 DNS 或防火牆篩選，然後再試一次。
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = 此連線為計量付費連線，或設有資料使用量限制。請連線至未設為計量付費的網路，或在網路設定中關閉「計量付費連線」，然後再試一次。
prepare-network-settings = 開啟網路設定
iso-target-title = 要在哪台電腦上重新安裝 Windows？
iso-target-this = 這台電腦
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas 可以將這台電腦的 Wi-Fi 和乙太網路驅動程式加入 ISO，讓 Windows 重新安裝後就能立即連上網路。
iso-target-other = 另一台電腦
iso-copy-network = 包含這台電腦的網路驅動程式
iso-network-detail = 安裝 Windows 時沿用這台電腦的 Wi-Fi 和乙太網路驅動程式。重灌後需要重新連線至 Wi-Fi。
iso-network-source = 網路驅動程式來源
iso-network-installed = 使用已安裝的驅動程式
iso-network-updated = 先檢查 Windows Update
iso-network-updated-detail = 下載 Windows Update 提供的相符驅動程式，並保留已安裝的驅動程式作為備用。需要非計量付費的連線。
iso-stage-network-drivers = 正在準備網路驅動程式
iso-network-failed = 無法準備網路驅動程式。請查看診斷資訊，或返回並變更網路驅動程式選項。
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = 這台電腦的網路介面卡使用 Windows 內建的驅動程式，因此 ISO 不需要包含這些驅動程式。
iso-mode-desktop = 進入桌面前完成設定
iso-mode-desktop-description = Atlas 會將您的選擇儲存至 ISO。登入後，Atlas 會在 Windows 桌面開啟前完成更新與安裝。
desktop-setup-description = 請完成電腦設定。您的 Atlas 選擇已儲存，需要時可以返回 Windows。
desktop-setup-exit = 在 Windows 中繼續

# Windows installation USB (Beta)
usb-title = 建立安裝隨身碟
usb-existing = 使用現有 ISO 建立隨身碟
usb-description = 將 ISO 寫入 USB 磁碟機，以便用它重新安裝 Windows。使用 Atlas 建立的 ISO，即可同時安裝 Atlas。
usb-choose-iso = 選擇 ISO
usb-drive = USB 磁碟機
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = 找不到 USB 磁碟機。請連接至少 { $min } GB 的 USB 磁碟機，然後選擇「重新整理」。大於 { $max } TB 的磁碟機、唯讀磁碟機，以及正在執行 Windows 的磁碟機不會顯示在這裡。
usb-refresh = 重新整理
# Shown when the drive list could not be read.
usb-scan-failed = 請確認磁碟機已連接，然後選擇「重新整理」。如需詳細資料，請選擇「開啟記錄資料夾」。
usb-scan-failed-title = 無法列出 USB 磁碟機
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = 序號：{ $serial }
usb-detail-separator = { " · " }
usb-review = 檢查隨身碟
usb-erase-title = 要清除這個 USB 磁碟機嗎？
usb-erase-description = { $drive }（{ $size } GB）上的所有內容都將被永久清除，包括所有檔案與磁碟分割。請先將要保留的資料複製到其他磁碟機。您的 ISO 會保留。
usb-layout = Atlas 最多使用磁碟機的 32 GB，其餘空間不會使用。此 USB 磁碟機適用於以 UEFI 模式啟動的電腦，這是 Windows 11 的必要條件。
usb-ack = 我了解這個 USB 磁碟機上的所有內容都將被清除
usb-write = 清除並建立隨身碟
usb-stage-prepare = 正在準備安裝檔案…
usb-stage-format = 正在格式化隨身碟…
usb-stage-copy = 正在複製安裝檔案…
usb-stage-verify = 正在驗證隨身碟…
usb-working = 請保持 Atlas 開啟，並維持 USB 磁碟機連接。如果您取消，未完成的 USB 磁碟機將無法用來安裝 Windows。
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = 無法完成隨身碟建立作業
usb-complete-title = 隨身碟已準備就緒
usb-close-title = 隨身碟仍在建立中
# After erasing may have begun.
usb-failed = 磁碟機可能已被清除，因此目前還無法用來安裝 Windows。請確認磁碟機已連接，然後選擇「檢查隨身碟」再試一次。如果您曾重新連接磁碟機，請先選擇「重新整理」並再次選取它。
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = 您的 USB 磁碟機沒有任何變更。請選擇「開啟記錄資料夾」查看失敗原因，然後選擇「檢查隨身碟」再試一次。
usb-failed-iso = 此 ISO 無法用來建立安裝隨身碟。請選擇 Atlas 建立的 ISO，或從 Microsoft 取得、且為 Atlas 支援版本的 Windows 11 ISO。您的 USB 磁碟機沒有任何變更。
usb-failed-location = ISO 或 Atlas Manager 位於此 USB 磁碟機、網路位置或連結的資料夾中。請將其移至這台電腦的本機資料夾，然後再試一次。您的 USB 磁碟機沒有任何變更。
usb-failed-space = Windows 磁碟機的可用空間不足，無法準備安裝檔案。請釋放空間，然後再試一次。您的 USB 磁碟機沒有任何變更。
usb-failed-fit = 此 USB 磁碟機的容量不足以容納安裝檔案。請改用容量較大的磁碟機，然後再試一次。您的 USB 磁碟機沒有任何變更。
usb-failed-drive-changed = 讀取清單後，USB 磁碟機已被移除、重新連接或更換。請選擇「重新整理」，再次選取該磁碟機，然後選擇「檢查隨身碟」。您的 USB 磁碟機沒有任何變更。
usb-cancelled = 磁碟機上可能留有不完整的安裝檔案。請重新建立後再用來安裝 Windows。
usb-cancelled-title = 已取消建立隨身碟
usb-cancelled-unchanged = 您的 USB 磁碟機沒有任何變更。
usb-complete = Atlas 已檢查所有檔案。請選擇「退出隨身碟」，然後備份要重新安裝的電腦上的檔案。將隨身碟插入該電腦，然後透過其開機選單從 USB 磁碟機啟動（通常是在電腦啟動時按 F12、F11 或 Esc）。
usb-eject = 退出隨身碟
usb-ejected = 現在可以拔除 USB 磁碟機。請備份要重新安裝的電腦上的檔案，然後透過該電腦的開機選單從 USB 磁碟機啟動（通常是在電腦啟動時按 F12、F11 或 Esc）。
usb-eject-failed = 請關閉正在使用隨身碟的檔案或視窗，然後再試一次。
usb-eject-failed-title = 無法退出隨身碟
ready-fresh-title = Atlas 專為全新安裝的 Windows 設計
ready-fresh-description = 如果您已在這台電腦上使用 Windows 一段時間，請先備份檔案並重新安裝 Windows，然後再繼續。請先確認「電腦檢查」中的「Windows 相容性」已通過，以便重新安裝支援的版本。
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = 不支援 Windows 11 Home、LTSC 和 Server 版本。請使用其他版本，例如 Pro、Education 或 Enterprise。如果 Windows 無法識別您的版本，請先解決此問題再繼續。
install-source-title = 無法安裝
install-source-unsupported = Atlas { $source } 無法直接更新至 { $target }。若要使用此版本，請備份您的檔案並重新安裝 Windows。
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } 無法直接更新。若要使用較新的版本，請備份您的檔案並重新安裝 Windows。
# "Open package file" is package-open-file. $folder is a folder path (text).
install-source-resume = Atlas { $target } 的安裝尚未完成，只有 Atlas { $target } 套件才能完成這次安裝。請選擇「開啟套件檔案」並選取該 Atlas 套件（.apbx）。如果是由 Atlas 下載的，它位於 { $folder }。
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } 的安裝尚未完成。此測試版只能安裝其內建的 Atlas 套件，因此請在正式版 Atlas Manager 中使用 Atlas { $target } 套件完成該安裝。
install-source-unknown = Atlas 無法確認這台電腦上已安裝的內容，因此目前不會安裝任何項目。請選擇「傳送報告」，讓 Atlas 團隊協助您。
# $problem is one of the install-source-* messages, or the outcome-* advice for a failed
# installation; $error is a raw error message or the installer's last error line (text).
install-source-details = { $problem }詳細資料：{ $error }
iso-edition-selection = 僅包含支援的版本。安裝 Windows 時，請選擇您擁有 Windows 授權的版本。
detail-windows-preview = 不支援 Insider 預覽組建。請使用 Windows 11 的正式發行版本。
detail-windows-release-unknown = Atlas 無法確認此 Windows 組建是否已正式發行。請連線至網際網路後重新檢查。
iso-release-unknown = Atlas 無法確認此 ISO 是 Atlas 套件支援的 Windows 11 正式發行版本。請連線至網際網路，然後再次選擇「檢查檔案」。如果仍然失敗，請從 Microsoft 重新下載 ISO。
prepare-previous-worker = 先前開始的更新仍在執行。Atlas 會等待更新完成，之後您就可以再次檢查更新。

ready-used-windows-title = 這台電腦上的 Windows 似乎已使用過
ready-used-windows-description = 這台電腦上的 Windows 至少已安裝一週，或已有多個應用程式。在此安裝 Atlas 不受支援，也強烈不建議：您現有的應用程式和設定可能無法正常運作，而且 Atlas 會移除 OneDrive，因此其中的檔案將停止同步，您的「桌面」、「文件」和「圖片」也可能看起來是空的。請先備份檔案並重新安裝 Windows，或只在您接受風險時才繼續。
ready-used-windows-dismiss = 仍要繼續

prepare-resumed = 電腦已重新啟動，Atlas 已還原您目前的選擇。請選擇「繼續更新」，在安裝 Atlas 前完成更新。
prepare-continue = 繼續更新
prepare-saving-restart = 正在儲存您的選擇，並設定在 Windows 重新啟動後開啟 Atlas…
prepare-restart-save-failed = 無法儲存您的選擇。請在重新啟動前重試。
prepare-restart-registration-failed = 您的選擇已儲存，但 Atlas 無法設定在重新啟動後自動開啟。請再試一次，或自行重新啟動電腦，並在登入後開啟 Atlas。
prepare-restart-failed = Atlas 無法重新啟動您的電腦。請再試一次，或從「開始」功能表重新啟動。您的選擇已儲存，Atlas 會在您登入後重新開啟。
diagnostics-export = 匯出診斷資訊
diagnostics-exporting = 正在收集診斷資訊…
diagnostics-privacy = 您可以私下傳送報告給 Atlas 團隊，或匯出診斷 ZIP，以便在尋求協助時分享。Atlas 會從 ZIP 中移除您的使用者名稱、電腦名稱和電子郵件地址。
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = 已建立診斷 ZIP
diagnostics-failed-title = 無法匯出診斷資訊
# $error is the raw error (text).
diagnostics-failed = 請確認電腦有足夠的可用磁碟空間，然後再試一次。詳細資料：{ $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Atlas { $release } 測試版。此應用程式只會安裝內建的 Atlas 套件。
home-status-bundled = 測試版 { $release }
package-bundled = 此測試版內建的 Atlas { $version } 已可安裝。
rc-about-release = 測試版
rc-about-commit = 原始碼提交
rc-about-package = 內建 Atlas 套件（SHA-256）
iso-package-bundled = 此測試版內建的 Atlas 套件
prepare-percent = 此階段已完成 { $percent }%
prepare-count = 已完成的更新：{ $completed } / { $total }
prepare-bytes = 已下載 { $downloaded } MB，總量約 { $total } MB
prepare-elapsed = 已用時間：{ $minutes } 分 { $seconds } 秒
prepare-progress-waiting = 正在等候更新服務。此步驟暫無進度百分比。
prepare-progress-unchanged = 已有 { $minutes } 分鐘沒有進度。大型更新可能需要一段時間，請保持 Atlas 開啟。如需詳細資料，請選擇「開啟記錄資料夾」。
prepare-report-delayed = Windows 已有 { $seconds } 秒未回報進度。更新可能仍在進行，請保持 Atlas 開啟。

prepare-affected-app = 受影響的應用程式
prepare-app-in-use = 請關閉 { $app }，然後再試一次。應用程式開啟時，Windows 無法更新它。如果找不到它的視窗，請在工作管理員中將其關閉。如果仍然失敗，請重新啟動電腦，並在開啟 { $app } 之前再試一次。
prepare-install-busy = 其他安裝或必要的重新啟動正在阻擋更新。請等待其他安裝完成；如果 Windows 要求重新啟動，請重新啟動電腦，然後再試一次。
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas 執行時使用的帳戶與登入 Windows 的帳戶不同。請使用系統管理員帳戶登入 Windows，從該帳戶開啟 Atlas，然後再試一次。
prepare-failed-store-missing = 您的帳戶尚未設定 Microsoft Store。請開啟一次 Microsoft Store；如果找不到它，請重新安裝，然後再試一次。
prepare-failed-store-battery = Microsoft Store 為了節省電池電力而暫停了更新。請將電腦接上電源，然後再試一次。
prepare-failed-store-network = Microsoft Store 已暫停更新，需等電腦連上未設為計量付費的網路才會繼續。請連線至未設為計量付費的 Wi-Fi 或乙太網路，然後再試一次。
prepare-failed-store-timeout = 市集應用程式尚未完成更新。請在 Microsoft Store 中完成其餘的下載，然後再試一次。
prepare-failed-store-passes = Microsoft Store 持續提供新的更新。請在 Microsoft Store 中完成其餘的更新，然後再試一次。
prepare-failed-manual-updates = 部分 Windows 更新需要在 Windows Update 中完成。請開啟 Windows Update 完成這些更新，然後再試一次。
prepare-failed-windows-passes = Windows Update 持續提供新的更新。請在 Windows Update 中完成其餘的更新，然後再試一次。
prepare-error-code = 錯誤碼：{ $code }
prepare-open-store = 開啟 Microsoft Store

check-user-account = 使用者帳戶
detail-user-account-ok = UAC 已啟用，您的帳戶已準備好進行安裝。
detail-user-account-not-ready = 請啟用使用者帳戶控制（UAC），重新啟動電腦後再試。如果您使用的是內建 Administrator 帳戶，請使用另一個系統管理員帳戶登入。
detail-user-account-unknown = Atlas 無法檢查您的使用者帳戶。請在安裝前重新檢查。Windows 回報：{ $error }

footer-prepare-required = 請先完成 Windows 和市集應用程式的更新再繼續
footer-prepare-stopping = 目前步驟完成後即會停止更新…
resume-choices-title = 繼續上次安裝
resume-choices-detail = 為了完成該次安裝，Atlas 已還原您上次的選擇。在安裝完成前，您無法在「您的選擇」中變更它們。

## Voluntary reports
report-title = 傳送報告
report-received = 已收到報告
report-reference = 如需就此報告聯絡 Atlas 團隊，請保留此參考編號。如果您留下了聯絡方式，團隊可能會用它回覆您，但不保證一定會回覆。
# Accessible name of the Copy button beside the report reference.
report-copy-reference = 複製報告參考編號
report-another = 傳送另一份報告
# Label of the choice between the two kinds of report.
report-kind = 您想傳送什麼？
report-kind-issue = 問題
report-kind-suggestion = 建議
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = 請描述發生了什麼事，或您希望改變什麼（{ $min }–{ $max } 個字元）。請勿在訊息中包含密碼。
report-message = 您的訊息
report-message-placeholder = 我當時想要…
report-contact = 聯絡方式（選填）
report-contact-placeholder = 電子郵件或 Discord 使用者名稱
report-attach = 附加診斷資訊
report-attach-description = 有助於找出原因的記錄和系統詳細資料。Atlas 會移除您的使用者名稱、電腦名稱、電子郵件地址，以及已知的密碼或金鑰。錯誤詳細資料、硬體型號和應用程式名稱會保留。您可以在傳送前檢查 ZIP。
report-prepare = 準備診斷資訊
report-review = 檢查 ZIP
report-prepare-failed-title = 無法準備診斷資訊
# $error is a raw error message (text).
report-prepare-failed = 請重新準備診斷資訊，或取消勾選「附加診斷資訊」，改為傳送不含診斷資訊的報告。詳細資料：{ $error }
report-privacy = 您的報告會私下傳送給 reports.atlasos.net 上的 Atlas 團隊。您的訊息和聯絡方式會依原樣傳送。團隊可能會使用其他公司的 AI 服務協助調查。這些服務會取得您的訊息和診斷資訊，但不會取得您的聯絡方式。報告會在 90 天後刪除，伺服器安全性記錄可能會記錄您的 IP 位址。
report-website = 隱私與報告網站
report-consent = 我同意將此報告及附加的診斷資訊傳送給 Atlas 團隊
report-failed = 您的訊息仍保留在這裡。請檢查網際網路連線，然後選擇「再試一次」，或透過報告網站傳送報告。
report-failed-busy = 報告服務目前忙碌中。您的訊息仍保留在這裡。請稍後再試。
report-failed-outdated = 此版本的 Atlas Manager 已無法傳送報告。您的訊息仍保留在這裡，請將它複製到報告網站。如果您附加了診斷資訊，請選擇「檢查 ZIP」，並將 ZIP 一併附加到網站上。
report-failed-diagnostics = 無法傳送已準備的診斷資訊。您的訊息仍保留在這裡。請重新準備診斷資訊，或取消勾選「附加診斷資訊」。
# Link under a report that wasn't sent.
report-failed-website = 開啟報告網站
report-sending = 正在傳送…
report-send = 傳送報告

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = 請輸入 { $min }–{ $max } 個字元。

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = 請將聯絡資訊限制在 { $max } 個字元以內。

report-validation-consent = 請確認您同意傳送此報告。

report-failed-title = 報告未傳送
