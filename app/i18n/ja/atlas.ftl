### Atlas Manager: Japanese (ja), preview translation. Revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog:
### - Polite です・ます form for sentences; noun-stop or verb-stem labels for
###   buttons and headings, as Windows does (再起動, キャンセル, 完了).
### - A half-width space between Japanese and Latin words or numbers, and
###   between katakana compounds (ログ フォルダー, スタート メニュー), as Microsoft does.
### - Full-width 。、 with half-width ( ) and : plus a half-width space, as
###   Microsoft Japanese UI does; half-width "?" in questions.
### - Japanese has only the "other" plural category; exact [1]/[2] are used
###   where the wording changes. Where English selects only for is/are, the
###   Japanese drops the selector.
### - "Relaunch" (the Atlas Manager) is 再実行 / 開き直す; "restart" (the PC or
###   Windows) is 再起動. Never swap them.
### - "Atlas package" (the .atlaspkg file) is "Atlas パッケージ", shortened to
###   "パッケージ" once it's clear; "package file" is パッケージ ファイル.
### - Install steps: 準備, 設定の選択, Windows セキュリティ, インストール.
###   ISO steps: Windows, セットアップ, 作成. "Go to <step>" is 「<step>」に移動;
###   "Return to Install" stays 「インストール」に戻る.
### - Status lines in progress end in 〜しています…. ISO and USB stage names
###   (iso-stage-*, usb-stage-*) are plain nouns without 中 (ファイルのコピー),
###   because the checklist shows them done, current or pending;
###   iso-progress-stage adds 中… (ファイルのコピー中…).
### - A stage of updating, installing, or creating an ISO or USB drive is a
###   段階; 手順 is only a flow step.
### - A check that updating takes care of is 更新時に対処 (状態) and
###   更新時に対処されます (説明).
### - Countdowns: "{ $seconds } 秒後に PC が再起動します。"
### - Storage settings is ストレージ設定; personalisation is 個人用設定; the
###   Services console is 「サービス」 and its startup type 「手動」; the
###   Windows regional format is 地域のフォーマット, as Settings names it.
### - Windows service names (BITS, Cryptographic Services, Windows Modules
###   Installer) stay in English, as Japanese Windows lists them.

## 共通

app-name = Atlas Manager
common-done = 完了
common-cancel = キャンセル
common-back = 戻る
common-next = 続行
common-dismiss = 閉じる
# Link beside a summary row that jumps back to change that choice.
common-change = 変更
common-copy = コピー
# Shown where a list of options is empty.
common-none = なし
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = ホームに戻る
# Accessible name of the gear button in the title bar.
common-settings = 設定
common-close-settings = 設定を閉じる
common-open-windows-security = Windows セキュリティを開く
# Relaunches the Atlas Manager with administrator rights (UAC). Not a PC restart.
common-restart-as-administrator = 管理者として再実行
common-try-again = 再試行
common-read-the-docs = Atlas のガイドを読む
common-show-details = 詳細を表示
common-hide-details = 詳細を非表示
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }、{ $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = ログ フォルダーを開く
# Accessible name of the Copy button beside the install log.
common-copy-install-log = インストール ログをコピー
common-install-log = インストール ログ
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas パッケージ
common-checking = 確認中
# Joins two items in a list: "Brave、Firefox". The braces keep the literal.
list-separator = { "、" }
# Joins two alternatives: "26100 または 26200".
list-or = { $a } または { $b }
# Joins the last two items of a list: "改ざん防止、クラウド提供の保護" (CLDR ja uses 、 here too).
# $a may itself be several items joined with list-separator.
list-and = { $a }、{ $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }。{ $message }

## ウィンドウ

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = インストール中にウィンドウを閉じますか?
window-close-installing = インストールは続行されます。Atlas をもう一度開くと、結果を確認できます。
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = インストールは続行されますが、PC は自動的に再起動しません。Atlas をもう一度開くと、結果を確認できます。
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = 開いたままにする
window-close-close = ウィンドウを閉じる
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = インストールの前に停止しますか?
window-close-checks-unchanged = インストールによる変更はまだありません。ここで閉じると、インストールは開始されません。
window-close-keep-installing = インストールを続行
window-close-stop-and-close = 停止して閉じる
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = 更新を停止しますか?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas は現在の段階が終わると停止します。その後、Atlas を閉じることができます。
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = 再起動して Atlas のセットアップを完了しますか?
window-close-restart-closed = Atlas を閉じると、PC を再起動できなくなります。先に作業を保存してください。
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = 再起動して更新を完了しますか?
window-close-update-restart-later = 先に作業を保存してください。後で再起動した場合も、再起動後に Atlas が続行します。
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = 保護がオフのまま Atlas を閉じますか?
window-close-protection-all = Windows セキュリティの 4 つの保護スイッチがオフになっています。今 Atlas をインストールしない場合は、先にオンに戻してください。
# $switches names the switches that are off as Windows Security does, joined like a list.
# Japanese needs no plural forms here, so $count isn't used.
window-close-protection-some =
    { $count ->
       *[other] Windows セキュリティで { $switches } がオフになっています。今 Atlas をインストールしない場合は、先にオンに戻してください。
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = ISO の作成を停止しますか?
iso-close-safe-point = Atlas は、次に安全に停止できる時点で停止します。
usb-close-question = USB ドライブの作成を停止しますか?
usb-close-unfinished = 作成途中のドライブでは Windows をインストールできません。
window-close-keep-creating = 作成を続行
window-close-stop = 停止
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Atlas パッケージ (.atlaspkg) を開く
# Message Windows shows in its restart notification.
shutdown-comment = Atlas のインストールが完了しました。セットアップを完了するため、Windows を再起動します。
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = 更新プログラムのインストールを完了するため、Atlas が Windows を再起動します。

## システム

# "Windows 11 Pro 25H2 (ビルド 26200.1234)". All three values are text.
system-description = { $product } { $version } (ビルド { $build })

## ホーム ページ

home-not-installed = Atlas へようこそ
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas は、Windows のバックグラウンド処理と気が散る要素を減らします。
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = この PC の Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = インストール日: { $date }
home-status-checking = 更新プログラムを確認しています…
# While startup checks whether another window's installation is running.
home-status-recovering = 実行中のインストールを確認しています
home-status-offline = 更新プログラムを確認できませんでした
home-status-not-checked = 更新プログラムはまだ確認していません
home-status-update = Atlas { $version } が利用可能です
home-status-up-to-date = 最新の状態です
home-status-newest = 最新バージョン: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Atlas { $version } のインストールが完了していません
home-check-again = もう一度確認
# Primary button while an install is running or waiting.
home-show-install = 進行状況を表示
home-continue-installing = セットアップを続行
home-update-to = Atlas { $version } に更新
home-reinstall = Atlas を再インストール
home-install = Atlas をインストール
home-finish-install = Atlas { $version } のインストールを完了
home-start-over = 最初からやり直す
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = この PC に Atlas をインストールしますか?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = 既存のアプリや設定が動作しなくなる可能性があります。また、Atlas は OneDrive を削除するため、OneDrive 内のファイルは同期されなくなり、フォルダーが空に見える場合があります。先にファイルをバックアップしてください。
home-used-windows-install = このままインストール
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Atlas で Windows を再インストール
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = この PC の Windows はすでに使用されています。Atlas は新規インストールした Windows に最適です。
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = PC の再起動が必要です
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas は PC を再起動できませんでした。スタート メニューから再起動してください。
home-security-reminder-title = 保護をオンに戻してください
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = 保護がオンになっているか確認してください
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
# Japanese needs no plural forms here.
security-switches-still-off =
    { $count ->
       *[other] Windows セキュリティで、次の保護がまだオフになっています: { $switches }。
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas は一部の保護スイッチを読み取れませんでした。Windows セキュリティで、次の保護がオンになっていることを確認してください: { $switches }。
home-elevation-title = インストールには管理者権限が必要です
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas はセットアップの選択内容を保存できなかったため、再実行していません。
home-state-error-title = Atlas のインストール情報を読み取れませんでした
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = Atlas のバージョン、選択内容、履歴が正しく表示されない可能性があります。
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager の更新が必要です
home-whats-new = Atlas { $version } の新機能
home-view-release = GitHub でリリース ノートを表示
home-show-less = 折りたたむ
home-show-full-notes = リリース ノートをすべて表示
home-your-install = Atlas のインストール情報
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = この PC には Atlas のインストール方法の記録がないため、選択内容とインストール履歴を表示できません。
home-history = インストール履歴
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = 手順 { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }。{ $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = セットアップの流れ
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Atlas をセットアップしています
# Beside step-ready in that card.
home-step-ready = Atlas が PC を確認し、Windows を更新します。
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas が PC を確認し、Windows をバージョン { $release } に移行します。
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Microsoft Defender など、残すものを選びます。
# Beside step-security in that card.
home-step-security = Windows セキュリティの 4 つの保護スイッチを手動でオフにします。
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
# Japanese needs no plural forms here.
home-step-install-restarts =
    { $minutes ->
       *[other] インストールは通常、約 { $minutes } 分で完了し、その後 PC が再起動します。
    }
home-step-install-restart-yourself =
    { $minutes ->
       *[other] インストールは通常、約 { $minutes } 分で完了します。その後、PC を再起動してください。
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = アプリが終了することがあり、PC も再起動するため、先に作業を保存してください。
home-github = GitHub で Atlas を見る
home-discord = Discord の Atlas コミュニティに参加
home-report-problem = 問題を報告

## インストールの種類 (状態ドキュメントから)

# Lower-case forms used inside a history row.
history-mode-fresh = 新規インストール
history-mode-upgrade = 更新
history-mode-reapply = 再インストール
history-mode-unknown = インストール

## ホーム ページの通知

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas は既定のアプリ設定を使用しています
notice-settings-unreadable-problem = Atlas は保存されたアプリの設定を読み取れませんでした。Windows の設定は変更されていません。
notice-settings-damaged-kept-problem = アプリの設定ファイルが破損していたため、Atlas はリセットし、以前のファイルのコピーを保存しました。
notice-settings-damaged-problem = アプリの設定ファイルが破損していました。当面は既定の設定を使用します。
notice-settings-not-saved-title = アプリの設定を保存できませんでした
notice-settings-not-saved-problem = Atlas は最新の変更を保存できなかったため、Atlas を閉じると変更が失われる可能性があります。別の Atlas ウィンドウが開いている場合は閉じてから、もう一度変更してください。
notice-session-unreadable-title = 前回のインストールの状態を確認できませんでした
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = 以前のインストールがまだ実行中かどうかを、Atlas は確認できませんでした。実行中のものがないと確信できる場合は、そのインストール記録を削除してから Atlas を開き直してください。
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = 以前のインストールがまだ実行中かどうかを、Atlas は確認できませんでした。判断できない場合は、Atlas コミュニティに相談してください。実行中のインストールがないと確信できる場合に限り、{ $path } を削除してから再試行してください。詳細: { $error }

## 管理者への昇格

elevation-declined = 許可が得られませんでした。再試行し、Atlas による変更を許可するかどうか Windows が確認したら「はい」を選んでください。
elevation-declined-continue = 許可が得られませんでした。再試行し、Atlas による変更を許可するかどうか Windows が確認したら「はい」を選んでください。選択した設定は保存されています。
elevation-draft-not-saved = 選択した設定を保存できなかったため、Atlas は再実行されていません。再試行してください。詳細: { $error }
# Shown with the home-start-over button.
elevation-taken-over = 別の Atlas ウィンドウがこのセットアップを使用しているため、Atlas は再実行されていません。そのウィンドウで続行するか、「最初からやり直す」を選んでここでもう一度セットアップしてください。

## インストールの流れ

step-ready = 準備
step-options = 設定の選択
step-security = Windows セキュリティ
step-install = インストール
install-title = Atlas のセットアップ
# Accessible name of the row of steps.
stepper-label = Atlas セットアップの手順
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }、{ $status }
stepper-status-completed = 完了
stepper-status-current = 現在の手順
stepper-status-upcoming = 今後の手順
# A step already visited whose requirements aren't met yet.
stepper-status-attention = 要注意
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = 手順 { $number }/{ $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }。{ $questions }

## 手順 1: 準備
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = PC の確認
# Status line while the checks run.
ready-checks-running = PC を確認しています…
ready-check-again = もう一度確認
# Status line once every check passed; common-show-details lists them.
ready-checks-passed = { $count } 項目は問題ありません
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
ready-checks-passed-some = { $total } 項目中 { $passed } 項目は問題ありません
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "9 項目中 5 項目は問題ありません · 4 項目は更新時に対処されます".
# $count is how many updating takes care of.
ready-checks-handled = { $count } 項目は更新時に対処されます
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = 更新時に対処
# Under the title of a check that updating takes care of.
check-updates-handled = インストール待ちの更新プログラムがあります。Windows の更新時に Atlas がインストールします。
check-restart-handled = 以前の変更を完了するため、Windows の再起動が必要です。更新時に対処されます。
check-handled = 更新時に対処されます。
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = ダウンロードしています…
ready-package-unpacking = 展開しています…
ready-package-ready = 準備完了
ready-package-checking = 最新バージョンを確認しています…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = 同梱の Atlas パッケージを準備しています…
ready-package-none = 未ダウンロード
ready-package-failed = Atlas パッケージを入手できませんでした
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = もう一度ダウンロードするか、別の Atlas パッケージ (.atlaspkg) を開いてください。
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = このテスト ビルドに同梱された Atlas パッケージを展開できませんでした。再試行してください。
ready-package-manager = 新しい Atlas Manager が必要です
ready-package-release-failed = 最新バージョンを確認できませんでした
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = インターネット接続を確認してから、再試行してください。Atlas パッケージ (.atlaspkg) をお持ちの場合は、代わりにそれを開くこともできます。
# Row title.
ready-updates-title = Windows と Microsoft Store の更新
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = メモ帳などの Store アプリは、更新中に終了することがあります。先にそれらのアプリで作業内容を保存してください。
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Windows がバージョン { $release } に移行した後に開始します。
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = 再起動後の処理を続けています…
ready-updates-restarting = PC を再起動しています…
ready-updates-done = Windows と Store アプリは最新の状態です。
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows は最新の状態です。
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown = { $seconds } 秒後に PC が再起動します。
ready-updates-restart = 更新を完了するには、PC の再起動が必要です。
ready-updates-restart-finish = バージョン { $release } のインストールを完了するには、Windows の再起動がもう一度必要です。
ready-updates-restart-failed = PC が再起動しませんでした
# Under the restart's status line, before Restart now.
ready-updates-restart-save = 先に作業を保存してください。
ready-updates-restart-persists = Windows がまだ再起動を求めています
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = もう一度再起動しても解決しない可能性があります。Windows Update で待機中の処理を完了してから、再試行してください。
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = 再起動の理由: { $reasons }
ready-updates-network = この接続では更新できません
ready-updates-stopped = 更新を停止しました。一部の更新プログラムはすでにインストールされている可能性があります。
ready-updates-previous = 以前に開始した更新を待っています…
# Button after the user stopped updating.
ready-updates-resume = 更新を再開
ready-updates-start = 更新を開始
# Why updating hasn't started, under the row.
ready-updates-blocked = Atlas がこの PC にインストールできる状態になるまで、更新は開始されません。
ready-updates-needs-admin = Atlas に管理者権限が付与されると開始します。
ready-updates-needs-windows = 「Windows の互換性」に問題がなければ開始します。
ready-updates-needs-drivers = ドライバーのインストール方法を決めると開始します。
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = ドライバー: { $choice }
ready-drivers-automatic = Windows Update から取得
ready-drivers-manual = 自分でインストール
ready-drivers-change-a11y = ドライバーのインストール方法を変更
# Under the two answers, once updating has run.
ready-drivers-again = 変更すると、更新がもう一度実行されます。

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } をダウンロード中 · { $received } / { $total } MB
package-unpacking = 展開中
package-status-ready = 準備完了
# Accessible name of the progress bar.
package-progress = Atlas パッケージの進行状況
package-download-again = もう一度ダウンロード
package-download-version = Atlas { $version } をダウンロード
package-download-newest = 最新バージョンをダウンロード
package-cancel-download = ダウンロードをキャンセル
package-open-file = パッケージ ファイルを開く
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } を GitHub からダウンロードしました。インストールの準備ができています。
package-from-file = Atlas { $version } を { $file } から読み込みました。インストールの準備ができています。
package-unpacked = Atlas { $version } のインストール準備ができています。
package-none-yet = Atlas パッケージはまだありません
acquire-no-asset = Atlas { $version } にはダウンロードできるパッケージ ファイルがありません。続行するには、保存済みの Atlas パッケージ (.atlaspkg) を開いてください。
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = このアプリでインストールできるのは Atlas 0.6.0 以降の Atlas パッケージ (.atlaspkg) です。
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } には、このアプリでのインストールに必要なファイルが含まれていません。もう一度ダウンロードするか、別の Atlas パッケージ (.atlaspkg) を開いてください。
acquire-failed = Atlas パッケージを準備できませんでした。もう一度ダウンロードするか、別の Atlas パッケージ (.atlaspkg) を開いてください。詳細: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = ダウンロードが応答しなくなりました。インターネット接続を確認してからもう一度ダウンロードするか、保存済みの Atlas パッケージ (.atlaspkg) を開いてください。
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = 同梱の Atlas パッケージを準備できませんでした。「再試行」を選んでください。詳細: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = この Atlas パッケージには、新しい Atlas Manager が必要です。Atlas Manager { $version } 以降をダウンロードし、現在お使いの Atlas Manager の代わりに使ってください。
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = この Atlas パッケージには、新しい Atlas Manager が必要です。最新の Atlas Manager をダウンロードし、現在お使いの Atlas Manager の代わりに使ってください。
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = Atlas { $version } をインストールするには、Atlas Manager { $required } 以降をダウンロードし、現在お使いの Atlas Manager の代わりに使ってください。
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Atlas { $version } をインストールするには、最新の Atlas Manager をダウンロードし、現在お使いの Atlas Manager の代わりに使ってください。

## 新しい Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Atlas Manager をダウンロード
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } が利用可能です
manager-update-message = Atlas Manager は自身を更新できません。新しいバージョンをダウンロードして、このバージョンの代わりに使ってください。

## システム チェック

check-administrator = インストールの権限
check-supported-build = Windows の互換性
check-pending-updates = Windows 更新プログラム
check-pending-reboot = 保留中の再起動
check-third-party-antivirus = 他のウイルス対策ソフト
check-internet = インターネット接続
check-power = 電源
check-activation = Windows のライセンス認証
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Windows 11 のハードウェア
check-move-space = 空き領域
check-move-update-source = 更新プログラムの取得元
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = 確認中
check-state-passed = 問題なし
check-state-warning = 要注意
check-state-failed-blocking = インストール前に対処が必要
check-state-failed = 要注意
check-state-unknown = 確認できませんでした
check-fix-windows-update = Windows Update を開く
check-fix-network = ネットワーク設定を開く
check-fix-power = 電源設定を開く
check-fix-activation = ライセンス認証の設定を開く
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = ストレージ設定を開く
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = 「インストールされているアプリ」を開く
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Windows Update で、インストール待ちの更新プログラムがないことを確認しました

detail-admin-ok = Atlas には、インストールに必要な変更を行う権限があります。
detail-admin-missing = Atlas を管理者として再実行し、Windows が許可を求めたら「はい」を選んでください。
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = このバージョンの Atlas には Windows ビルド { $builds } が必要です。この PC のビルドは { $build } です。続行する前に、対応する Windows バージョンをインストールしてください。
detail-build-missing = この Atlas パッケージには、対応する Windows ビルドが記載されていません。LocalTest ビルドではなく、パッケージの完全なビルドを使用してください。
detail-updates-none = インストール待ちの Windows 更新プログラムはありません。
# Updates still waiting once updating has run. $count is how many.
detail-updates-left = { $count } 件の更新プログラムがまだインストール待ちです。Windows Update でインストールしてから、もう一度確認してください。
detail-updates-scan-failed = Windows 更新プログラムを確認できませんでした。Windows Update を開いて、インストール待ちの更新プログラムがあるかどうかを確認してください。({ $error })
detail-reboot-none = 現在、Windows の再起動は必要ありません。
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = 以前の変更を完了するため、Windows の再起動が必要です。PC を再起動してから、もう一度確認してください。
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = 以前の変更を完了するため、Windows の再起動が必要です ({ $reasons })。PC を再起動してから、もう一度確認してください。
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = このまま続行できます。Windows には、次回の再起動時に置き換えまたは削除するファイルがあります ({ $files })。Xbox Gaming Services など一部のアプリは、再起動のたびにこの処理を予約します。
detail-reboot-unknown = Windows に再起動が必要かどうかを確認できませんでした。PC を再起動し、Atlas を開き直してからもう一度確認してください。({ $error })
detail-antivirus-none = 他のウイルス対策ソフトは検出されませんでした。
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Microsoft Defender 以外のウイルス対策アプリは、インストールを妨げることがあります。{ $products } をアンインストールしてから、もう一度確認してください。
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows セキュリティには { $products } がまだ表示されていますが、そのファイルはすでに削除されているため、インストールされていない状態です。Atlas はこのままインストールできます。
detail-antivirus-check-failed = 他のウイルス対策ソフトを確認できませんでした。この問題が続く場合は、PC を再起動してからもう一度確認してください。({ $error })
detail-internet-ok = インターネットに接続されています。Atlas がソフトウェアをダウンロードしてインストールする間、接続を維持してください。
detail-internet-missing = インターネットに接続してから、もう一度確認してください。
detail-power-mains = PC は電源に接続されています。インストールが終わるまで接続したままにしてください。
detail-power-battery = インストール中に電源が切れないよう、PC を電源に接続してください。
detail-power-check-failed = PC が電源に接続されているかどうかを、Atlas は確認できませんでした。ノート PC の場合は電源に接続してから、もう一度確認してください。
detail-activation-ok = Windows はライセンス認証されています。Atlas はこれを変更しません。
detail-activation-missing = Windows はライセンス認証されていません。続行できますが、Atlas が代わりにライセンス認証を行うことはありません。
detail-activation-no-licence = Windows からライセンス情報が報告されませんでした。続行できます。Atlas はライセンス認証の状態を変更しません。
detail-activation-unknown = Windows のライセンス認証を確認できませんでした。続行できます。Atlas はライセンス認証の状態を変更しません。({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = この PC では、Atlas が Windows を新しいバージョンに移行する必要はありません。
detail-move-hardware-ready = この PC には、Windows 11 に必要な TPM 2.0 と UEFI ファームウェアがあります。
detail-move-hardware-missing = この PC には { $missing } がないため、Windows Update でバージョン { $release } に移行できません。ファイルをバックアップしてから、Atlas ISO で Windows を再インストールしてください。
detail-move-hardware-unread = Atlas はこの PC のハードウェアをすべて読み取れなかったため、確認は Windows Update が行います。
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } の空き領域は { $free } GB です。
detail-move-space-short = バージョン { $release } には { $drive } に { $needed } GB の空き領域が必要ですが、現在は { $free } GB です。空き領域を確保すると、Atlas が自動的にもう一度確認します。
detail-move-space-unknown = Windows の更新に必要な空き領域を確認できませんでした。PC を再起動してから、もう一度確認してください。({ $error })
detail-move-update-source-ok = この PC は Windows Update から更新プログラムを受け取っています。
detail-move-update-source-managed = この PC は組織のサーバーから更新プログラムを受け取っていますが、そのサーバーはバージョン { $release } を提供していません。組織に問い合わせるか、Atlas ISO で Windows を再インストールしてください。

## 手順 2: 設定の選択
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Microsoft Defender、プロセッサの保護、更新の設定は、後からデスクトップの Atlas フォルダーで変更できます。
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = 選択なし
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = { $count } 個を選択済み
# Links that unfold and fold the Optional extras card.
options-extras-show = 表示
options-extras-hide = 非表示
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender は Windows に組み込まれたウイルス対策です。
question-mitigations-description = これらの保護はセキュリティの軽減策とも呼ばれ、Spectre や Meltdown などのプロセッサの欠陥や、アプリのバグを悪用する攻撃から PC を守ります。
question-auto-updates-description = どちらの場合も、Atlas は Windows を現在のバージョンのまま維持し、Microsoft Store アプリの自動更新をオフにします。
question-browser-description = Atlas はブラウザーの設定を変更しません。
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = 別のウイルス対策アプリをインストールするまで PC はウイルス対策による保護を受けられず、認識されないアプリやダウンロードを開く前に Windows が警告しなくなります。
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = 制御フロー ガードなど、アプリに対する Exploit Protection もオフになり、セキュリティが低下します。
cost-auto-updates-disable = セキュリティ修正を入手するには、定期的に Windows Update を開いてください。
cost-auto-updates-default = 更新プログラムのインストールを完了するため、Windows が PC を再起動することがあります。
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift と Ctrl+Shift で言語やレイアウトを切り替えられなくなります。
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = ディスク領域が解放されますが、休止状態と高速スタートアップは使えなくなります。
extra-disable-power-saving = 消費電力や発熱が増え、バッテリー駆動時間が短くなる場合があります。
extra-disable-core-isolation = メモリ整合性などの保護が弱まり、それを必要とするアプリやゲームに影響する場合があります。
extra-uninstall-edge = この PC の Edge のお気に入り、履歴、保存したパスワードが削除されます。Microsoft アカウントに同期されているものは除きます。
extra-install-toolbox = Atlas の設定を管理しやすくなります。ベータ版のため、一部の機能は未完成の場合があります。
extra-install-eclean = 不要なファイルやスタートアップ アプリを確認できる、AtlasOS 開発チームのツールです。アカウントとインターネット接続が必要です。
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Microsoft Defender を残しますか?
screen-mitigations-title = プロセッサの保護
screen-mitigations-question = Windows のプロセッサ保護を維持しますか?
screen-updates-title = Windows Update
screen-updates-question = 更新プログラムをどのようにインストールしますか?
screen-browser-title = ブラウザー
screen-power-title = 電源とセキュリティ
screen-apps-title = アプリ
screen-optional-apps-title = 任意のアプリ
screen-choose-one-title = オプションを選択
screen-extras-title = 追加オプション
# Each decision's short name in the middle of a sentence, as in summary-change-a11y,
# update-path-differs, preflight-choice-unanswered and installed-not-applied-choices. Write it as
# the language does mid-sentence: in English, product names keep their capitals and other names
# are lower case.
screen-update-path-name = Atlas の更新方法
screen-defender-name = Microsoft Defender
screen-mitigations-name = プロセッサの保護
screen-updates-name = Windows Update
screen-keyboard-name = キーボードの言語
screen-browser-name = ブラウザー
screen-power-name = 電源とセキュリティ
screen-apps-name = アプリ
screen-optional-apps-name = 任意のアプリ
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = Atlas パッケージ内の選択項目
screen-extras-name = 追加オプション
# Question for a required choice this app has no specific wording for.
screen-generic-question = 「{ $title }」のオプションを選んでください
learn-more-defender = Microsoft Defender の詳細
learn-more-mitigations = プロセッサの保護の詳細
learn-more-updates = Windows Update の詳細
learn-more-browser = ブラウザーの詳細
learn-more-power = 電源とセキュリティの詳細
learn-more-apps = アプリの詳細
learn-more-eclean = eclean の詳細
learn-more-keyboard = キーボードの言語の詳細
learn-more-generic = セットアップ ガイドを読む
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Windows 標準のウイルス対策を残し、ウイルスなどの脅威から PC を保護します。
consequence-mitigations-default = プロセッサの欠陥や、アプリのバグを悪用する攻撃に対する Windows の既定の保護を維持します。
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = 制御フロー ガードなど、アプリに対する Exploit Protection もオフにします。これによりセキュリティが低下します。パフォーマンスに差が出るかどうかは、プロセッサによって異なります。
consequence-auto-updates-disable = 定期的に Windows Update を開いて、更新プログラムをインストールしてください。更新の通知は引き続き表示されます。
consequence-auto-updates-default = Windows がセキュリティ修正を含む更新プログラムを自動的にインストールします。

## 手順 2: インストール済みの Atlas の更新と再インストール

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Atlas { $version } にどのように更新しますか?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Atlas { $version } をどのように再インストールしますか?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = 選択内容を維持する
update-path-keep-detail = Atlas は、すべての選択をこの PC の現在の設定のまま維持し、どれも変更しません。
update-path-choose = 選択をやり直す
update-path-choose-detail = この PC の現在の設定から始めます。アプリ、ファイル、個人用設定はそのまま残ります。
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = この PC の現在の選択内容
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = PC から判断できないため、Atlas がお尋ねします
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = { $choices } について、この PC が Atlas の記録と一致しません。
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas は、その他の選択をすべてこの PC の現在の設定のまま維持します。
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = この PC の現在の設定
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas は Microsoft Defender を復元します。再起動後に、Windows セキュリティで Defender の保護をオンにしてください。
change-mitigations-default = Atlas はプロセッサの保護を Windows の既定どおりにオンに戻します。再起動後に有効になります。
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = 現在、プロセッサの保護はすべてオンになっています。保護を維持すると、すべてオンのままになります。
change-auto-updates-default = Atlas は、Windows が更新プログラムを再び自動的にインストールするようにします。
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas は休止状態をオンに戻します。
change-power-saving-on = Atlas は省電力機能をオンに戻し、以前の電源プランに戻します。以前の電源プランがない場合は「バランス」にします。
change-core-isolation-on = Atlas は仮想化ベースのセキュリティ (VBS) をオンに戻します。ただし、この PC のポリシーで管理されている場合は変更しません。再起動後に有効になります。
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = この PC のすべてのユーザーから Snipping Tool を削除します。Atlas では後から元に戻せませんが、Microsoft Store から再インストールできます。
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge はすでに削除されており、Atlas を更新しても元に戻りません。再インストールするには、Atlas フォルダーにある「Install or Remove Edge」を使用してください。
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } はインストール済みです。Atlas はアプリをアンインストールしません。削除するには、Windows の「設定」で「インストールされているアプリ」を開いてください。
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } はそのまま残り、Atlas が { $browser } もインストールします。

## Atlas パッケージのテキスト
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Microsoft Defender を残す (推奨)
package-option-defender-enable-short = Microsoft Defender を残す
package-option-defender-disable = Microsoft Defender を削除する
package-option-mitigations-default = プロセッサの保護を維持する (推奨)
package-option-mitigations-default-short = プロセッサの保護を維持する
package-option-mitigations-disable = プロセッサの保護をオフにする
package-option-auto-updates-disable = 更新プログラムを自分でインストールする
package-option-auto-updates-default = 更新プログラムを自動的にインストールする
package-option-disable-hibernation = 休止状態をオフにする
package-option-disable-power-saving = 省電力機能をオフにする
package-option-disable-core-isolation = 仮想化ベースのセキュリティ (VBS) をオフにする
package-option-remove-snipping-tool = Snipping Tool を削除する
package-option-uninstall-edge = Microsoft Edge を削除する
package-option-install-another-browser = ブラウザーをインストールする
package-option-install-toolbox = Atlas Toolbox をインストールする
package-option-install-eclean = eclean をインストールする
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender は Windows に組み込まれたウイルス対策です。削除するのは、リスクを理解したうえで、別のウイルス対策アプリを使う予定がある場合だけにしてください。どちらを選んでも、Atlas はスマート アプリ コントロール、拡張フィッシング保護、デバイスの検索をオフにします。
package-choice-mitigations-description = これらの保護はセキュリティの軽減策とも呼ばれ、Spectre や Meltdown などのプロセッサの欠陥や、アプリのバグを悪用する攻撃から PC を守ります。Windows の既定のまま維持することをおすすめします。
package-choice-auto-updates-description = Windows の更新プログラムには、セキュリティ修正が含まれています。Windows に自動でインストールさせることも、自分でインストールすることもできます。どちらの場合も、Atlas は Windows を現在のバージョンのまま維持します。このバージョンにセキュリティ修正が提供されるのは、Microsoft のサポートが終了するまでです。また、Atlas は Microsoft Store アプリの自動更新をオフにするため、Store アプリは Microsoft Store で更新してください。
package-choice-browser-description = インストールするブラウザーを選んでください。Atlas はブラウザーの設定を変更しません。

## 手順 3: Windows セキュリティ

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = この PC に Microsoft Defender はインストールされていません
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = オフにする保護スイッチはありません。
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = この PC の Microsoft Defender は Atlas によって削除されています
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = このインストールで Atlas が Microsoft Defender を復元します
security-restore-nothing-to-turn-off = Defender はまだ実行されていないため、オフにするものはありません。再起動後に、Windows セキュリティで Defender の保護をオンにしてください。
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = Microsoft Defender が見つかりません
security-banner-missing-message = Atlas が削除したものではないため、Atlas では復元できません。続行できますが、別のウイルス対策アプリをインストールするか Windows を修復するまで、PC はウイルス対策による保護を受けられません。
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = 次の 4 つのスイッチをオフにしてください
security-turn-off-message = Microsoft Defender は、インストール中に Atlas をブロックすることがあります。Defender を残す場合は、インストール後にスイッチをオンに戻してください。
# The page name in Windows Security.
security-list-title = ウイルスと脅威の防止の設定
security-switch-off = オフ
security-switch-on = オン
security-switch-unreadable = 読み取り不可
security-switch-reading = 確認中
security-all-off = すべてオフ
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 個がまだオン、1 個を読み取れませんでした".
security-count-still-on = { $count } 個がまだオン
security-count-unreadable = { $count } 個を読み取れませんでした
security-count-join = { $a }、{ $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are.
# Japanese reads the same for one or several.
security-unread-switches-title =
    { $count ->
       *[other] Atlas は { $switches } の状態を読み取れませんでした
    }
security-unread-message =
    { $count ->
       *[other] Windows セキュリティでオフになっていることを確認してください。
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
       *[other] { $switches } がオフになっていることを確認しました
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Windows セキュリティで、4 つのスイッチがすべてオフになっていることを確認しました
security-unknown-unelevated-title = 保護の確認には管理者権限が必要です
security-unknown-unelevated-message = Microsoft Defender の設定を確認できるよう、Atlas を管理者として再実行してください。
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = 改ざん防止
protection-tamper-why = Atlas がセキュリティ設定を変更できるようにするためです。
protection-realtime = リアルタイム保護
protection-realtime-reason = スキャンによって Atlas のファイルがブロックされることがあります。
protection-cloud = クラウド提供の保護
protection-cloud-reason = オンラインのチェックによって Atlas のファイルがブロックされることがあります。
protection-samples = サンプルの自動送信
protection-samples-why = Atlas のファイルが Microsoft に送信されないようにするためです。

## 手順 4: インストール

outcome-succeeded-title = Atlas がインストールされました
outcome-lost-title = インストール結果を確認できませんでした
outcome-failed-title = インストールが完了しませんでした
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = この PC はインストール要件を満たしていなかったため、インストールによる変更はありません。
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = この PC はインストール要件を満たしていなかったため、今回の試行は停止しました。以前の試行ですでに変更が加えられています。
# Beside common-restart-as-administrator.
result-not-elevated = Atlas に管理者権限がなかったため、インストールによる変更はありません。
result-not-elevated-resumed = Atlas に管理者権限がなかったため、今回の試行は停止しました。以前の試行ですでに変更が加えられています。
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Windows と Store アプリが最新の状態であることを Atlas が確認できなかったため、Windows を変更する前にインストールを停止しました。
result-preparation-stale-resumed = Windows と Store アプリが最新の状態であることを Atlas が確認できなかったため、今回の試行は停止しました。以前の試行ですでに変更が加えられています。
result-failed-preflight = 変更を加える前にインストールが停止しました。もう一度試すことができます。
result-failed-staging = ファイルの準備中、Windows を変更する前にインストールが停止しました。もう一度試すことができます。
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = 一部の変更はすでに適用されている可能性があります。もう一度試すか、ここで中止する場合は Windows セキュリティで保護スイッチをオンに戻してください。
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = 一部の変更はすでに適用されている可能性があります。もう一度試すことができます。
result-failed-resumed = 今回の試行は途中で停止しましたが、以前の試行ですでに変更が加えられています。もう一度試すか、ここで中止する場合は Windows セキュリティで保護スイッチをオンに戻してください。
result-failed-resumed-defender-removed = 今回の試行は途中で停止しましたが、以前の試行ですでに変更が加えられています。もう一度試すことができます。
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = 今回の試行は前回と同じエラーで停止したため、もう一度試しても解決する可能性は低いです。Atlas チームが原因を調べられるようレポートを送信し、ここで中止する場合は保護スイッチをオンに戻してください。
result-failed-repeated-defender-removed = 今回の試行は前回と同じエラーで停止したため、もう一度試しても解決する可能性は低いです。Atlas チームが原因を調べられるよう、レポートを送信してください。
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows が依然として { $apps } を削除しないため、もう一度試しても解決する可能性は低いです。Atlas チームが原因を調べられるようレポートを送信し、ここで中止する場合は保護スイッチをオンに戻してください。
result-failed-repeated-apps-defender-removed = Windows が依然として { $apps } を削除しないため、もう一度試しても解決する可能性は低いです。Atlas チームが原因を調べられるよう、レポートを送信してください。
result-not-started = インストーラーが時間内に起動しなかったため、インストールによる変更はありません。もう一度試すことができます。
result-lost = インストーラーが結果を報告せずに停止したため、一部の変更が適用されている可能性があります。もう一度試すか、ここで中止する場合は Windows セキュリティで保護スイッチをオンに戻してください。
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = インストーラーが結果を報告せずに停止したため、一部の変更が適用されている可能性があります。もう一度試すことができます。
restart-now-message = Atlas のセットアップを完了するため、Windows を再起動しています。
restart-stopped = 自動再起動をキャンセルしました。作業を保存してから PC を再起動し、Atlas のセットアップを完了してください。
restart-needed = 作業を保存してから PC を再起動し、Atlas のセットアップを完了してください。
restart-dont-now = 後で再起動
restart-now = 今すぐ再起動
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = インストールは開始されていません
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = { $choice } についての回答が必要です。
preflight-choices-unusable = Atlas はこれらの選択内容を使用できませんでした。
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
       *[other] PC の確認後に状態が変わり、{ $checks } に対処が必要になりました。
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = スイッチをオフにした後に、Windows セキュリティの状態が変わりました: { $summary }。
preflight-busy-wait = 別の Atlas ウィンドウがインストールを開始しています。少し待ってから、再試行してください。
# Beside home-start-over.
preflight-taken-over-start-over = 別の Atlas ウィンドウがこのセットアップを使用しています。そのウィンドウで続行するか、ここで最初からやり直してください。
# Beside go-to-ready.
preflight-record-unreadable-check = 以前のインストールがまだ実行中かどうかを確認できなかったため、Atlas は新しいインストールを開始していません。
preflight-not-started = Atlas はインストーラーを起動できなかったため、インストールによる変更はありません。もう一度試すことができます。
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas はインストーラーを起動できませんでしたが、以前の試行ですでに変更が加えられています。もう一度試すことができます。
go-to-ready = 「準備」に移動
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = 「設定の選択」に移動
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = 「Windows セキュリティ」に移動
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = 「インストール」に戻る
output-problem-title = インストールの進行状況を読み取れませんでした
install-elevate-title = インストールには管理者権限が必要です
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Atlas を再実行すると、Windows が許可を求めます。
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Atlas パッケージの準備ができていません
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = 先に「準備」を完了してください
install-not-ready-message = インストールを始める前に、Atlas が PC の確認と Windows の更新を完了する必要があります。
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = 保護スイッチをもう一度オフにしてください
install-switches-message = Windows セキュリティ: { $summary }。
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = インストールの準備ができました
summary-setup-title = Atlas のセットアップ内容
summary-activation = ライセンス認証
summary-activation-ok = ライセンス認証済み。Atlas はこれを変更しません。
summary-activation-missing = ライセンス認証されていません。続行できますが、Atlas が Windows のライセンス認証を行うことはありません。
summary-activation-unknown = Atlas は Windows のライセンス認証の状態を変更しません。
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts = 通常は約 { $minutes } 分で完了し、その後 PC が再起動します
summary-time-restart-yourself = 通常は約 { $minutes } 分で完了し、その後 PC の再起動が必要です
# The check box on the card. It's the same setting as settings-restart-label.
summary-restart-automatically = インストールが完了したら自動的に再起動する
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = 同時にオフになる機能
summary-turned-off-value = スマート アプリ コントロール、拡張フィッシング保護、デバイスの検索
summary-show-command = インストール コマンドを表示
summary-hide-command = インストール コマンドを非表示
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = インストール コマンドをコピー
summary-command-unavailable = インストール コマンドを準備できませんでした。詳細: { $error }
summary-not-chosen = まだ選択されていません
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = { $title } を変更
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Atlas の更新方法
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = インストールの準備中
footer-checks-blocked = 続行するには、確認で見つかった問題を解決してください
footer-manager-outdated = 続行するには、新しい Atlas Manager をダウンロードしてください
footer-need-files = 続行するには、Atlas パッケージを入手してください
# Tester build variant of footer-need-files.
footer-need-package-bundled = 続行するには、同梱の Atlas パッケージを準備してください
footer-drivers = 続行するには、ドライバーのインストール方法を決めてください
footer-windows-terms = 続行するには、ライセンス条項に同意してください
footer-updating = Windows と Store アプリを更新しています…
footer-restart = 続行するには、PC を再起動してください
footer-reading-security = 保護スイッチを確認中
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = 続行するには、4 つのスイッチをすべてオフにしてください
footer-security-confirm = 続行するには、Atlas が読み取れなかったスイッチを確認してください
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = 先に作業を保存し、アプリを閉じてください
button-install = Atlas をインストール
log-earlier-lines = これより前の { $count } 行はログ ファイルにあります。
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (完全なログ: { $path })

## インストール中の画面

installing-title = Atlas をインストールしています
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = PC を確認しています…
installing-staging-label = Atlas のファイルをコピーしています…
installing-applying-label = Windows を設定しています…
installing-finishing-label = 最終処理を行っています…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = PC の電源を入れたまま、電源に接続しておいてください。インストールが完了すると自動的に再起動します。
installing-keep-on = PC の電源を入れたまま、電源に接続しておいてください。インストールが完了したら、PC を再起動してください。
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = インストールが停止したとは限りません。
installing-installed-title = Atlas がインストールされました
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown = { $seconds } 秒後に PC が再起動します。
installing-restart-save = 先に作業を保存してください。

## 再起動後の「Atlas がインストールされました」ウィンドウ

installed-title-version = Atlas { $version } がインストールされました
installed-title = Atlas がインストールされました
installed-ready = セットアップが完了しました。Atlas を適用した PC をお使いいただけます。
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = チップセット、ネットワーク、グラフィックスのドライバーは、PC、マザーボード、またはデバイスのメーカーから入手してください。
installed-drivers-guide = ドライバー ガイドを開く
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender は削除されました
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas が削除したものではありません。他のウイルス対策アプリを使っていない場合は、インストールして PC を保護してください。
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender は削除されたままです
defender-not-restored-message = 以前の Atlas の更新で復元されなかったため、Defender は PC を保護していません。Atlas を再インストールして Defender を残すか、Atlas フォルダーの「7. Security」>「Defender」にある「Toggle Defender」を実行してください。
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = 一部の選択が反映されませんでした
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender、プロセッサの保護", joined with list-and; $count is how many it names. Japanese
# needs no plural forms here.
installed-not-applied-choices =
    { $count ->
       *[other] 次の項目は以前の状態のままです: { $choices }。
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = 選択したとおり、Windows Update は再びオフになりました
installed-update-off-message = オフの間、PC はセキュリティ更新プログラムを受け取りません。
installed-update-paused-title = 選択したとおり、Windows の更新は再び一時停止されました
installed-update-paused-message = 一時停止中、PC はセキュリティ更新プログラムを受け取りません。

## 設定

settings-title = 設定
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = 外観
settings-installation = インストール
settings-privacy = プライバシー
settings-theme = アプリのテーマ
settings-theme-system = Windows に合わせる
settings-theme-light = ライト
settings-theme-dark = ダーク
settings-theme-contrast-note = Atlas は Windows のコントラスト テーマの配色を使用しています。
settings-language = 言語
# The setting in the Language section, and its box's name.
settings-app-language = アプリの言語
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Windows に合わせる ({ $language })

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = プレビュー
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = この翻訳は、まだネイティブ スピーカーによるレビューを受けていません。
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language }はプレビュー翻訳のため、誤りが含まれている可能性があります。
preview-notice-switch = 英語に切り替える
preview-notice-language = 言語を変更
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = 選択した言語はこのバージョンの Atlas にないため、英語で表示しています。選択内容は保存されています。
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas は Windows の表示言語にまだ対応していないため、英語で表示しています。
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Windows の表示言語を確認できなかったため、英語で表示しています。
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "日本語 (日本)".
settings-language-formats = 数値、日付、時刻は Windows の地域のフォーマットに従います: { $locale }。
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = 数値は Windows の地域のフォーマットに従います: { $locale }。Atlas はまだ右から左に書くテキストを表示できないため、日付と時刻には標準の形式を使用します。
settings-language-contribute = GitHub で Atlas の翻訳に協力する
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = 使用状況データを Atlas と共有する
settings-share-usage-description = 開いたページ、ISO の作成、インストールの成否が対象です。
settings-privacy-policy = プライバシー ポリシー
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = インストールと更新の後に自動的に再起動する
settings-restart-automatically-description = Atlas の処理が終わると 1 分以内に PC が再起動し、開いているアプリは閉じられます。
settings-restart-locked = この設定はインストールが終わってから変更できます。
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = ヘルプ
settings-about = バージョン情報
settings-about-app = Atlas Manager
settings-about-licence = ライセンス
settings-about-licence-value = GPL-3.0、無料のオープン ソース
settings-view-source = GitHub でソース コードを表示
# Link that opens the third-party licence notices.
settings-view-licences = サードパーティのライセンス情報を表示
# Under the links when Windows could not open the notices.
settings-licences-failed = ライセンス情報を開けませんでした。再試行するか、GitHub のソース コードで確認してください。
settings-open-data-folder = アプリのフォルダーを開く

## 追加オプション: 選択前に表示する説明

consequence-disable-hibernation = 休止状態でセッションを保存するために使うディスク領域を解放します。休止状態と高速スタートアップは使えなくなります。
consequence-disable-power-saving = 省電力機能をオフにします。消費電力や発熱が増え、バッテリー駆動時間が短くなる場合があります。
consequence-disable-core-isolation = メモリ整合性を含む、Windows の追加のセキュリティ層をオフにします。保護が弱まり、この機能を必要とするアプリやゲームに影響する場合があります。
consequence-remove-snipping-tool = スクリーンショットや画面録画に使う Windows のアプリを削除します。
consequence-uninstall-edge = Microsoft Edge ブラウザーを削除します。別のブラウザーがあることを確認するか、下で選んでください。
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = この PC の Edge のお気に入り、履歴、保存したパスワードを削除します。
consequence-install-another-browser = 下でブラウザーを選ぶと、Atlas がインストールします。
consequence-install-toolbox = Atlas Toolbox を追加すると、Atlas の設定を管理しやすくなります。Toolbox はベータ版のため、一部の機能は未完成の場合があります。
consequence-install-eclean = セットアップ後の PC を整える、AtlasOS 開発チームのメンテナンス ツールです。不要なファイルやスタートアップ アプリを確認できます。アカウントとインターネット接続が必要です。

## ISO の作成
iso-open = Atlas ISO を作成
iso-title = Atlas ISO を作成
iso-recommended = おすすめ
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = セットアップ
iso-step-create = 作成
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = この ISO はどの PC 用ですか?
iso-target-this = この PC
iso-target-another = 別の PC
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = この ISO は { $architecture } の PC 用です。
iso-source = Windows ISO
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Microsoft からダウンロード
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Windows のダウンロード
iso-download-language = 言語
iso-download-arch = アーキテクチャ
iso-download-languages = 言語を読み込み中…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Windows 11 をダウンロードしています…
iso-download-amount = { $received } / { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas は Microsoft のダウンロード サービスに接続できませんでした。インターネット接続を確認してから、再試行してください。
iso-download-incomplete = ダウンロードが完了しませんでした。インターネット接続と空き領域を確認してから、再試行してください。
iso-download-website = Microsoft のダウンロード ページを開く
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = ISO ファイルを選ぶ
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Windows ISO を確認しています…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = Windows ISO の準備完了、{ $facts }
iso-package-latest-label = 最新版
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = 最新の Atlas リリースは古いため、この Atlas Manager では使用できません。
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = 最新の Atlas を入手しています…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas は最新バージョンを確認できませんでした。インターネット接続を確認してから、再試行してください。
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = 続行するには、Windows ISO を入手してください
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Atlas の選択はいつ行いますか?
iso-mode-after = サインイン後
iso-mode-after-description = サインイン後に、Atlas がセットアップを案内します。
iso-mode-now = 今すぐ
iso-mode-now-description = 選択内容は ISO に保存され、サインイン後に Atlas をインストールします。
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = デスクトップが開く前に完了する
iso-mode-before-desktop-description = サインイン後、インストールが終わるまで Atlas が全画面で実行されます。
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = この Atlas パッケージは選択内容を ISO に保存できないため、選択はサインイン後に行います。
iso-atlas-options = Atlas の選択内容
# The line at the top of the Create step.
iso-create-intro = ISO を作成しても、この PC と元の ISO は変更されません。
iso-review-package = Atlas パッケージ
iso-review-output = 新しい ISO
iso-review-edition = エディション
iso-review-editions = エディション
iso-edition = Windows エディション
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Windows セットアップで選択
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Windows セットアップで選択
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Windows のライセンス条項に同意し、Windows セットアップでの確認を省略する
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = アカウント名
iso-review-target = インストール先
iso-review-drivers = ドライバー
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows セットアップ
iso-review-skips = Microsoft アカウントとプライバシーの画面を省略
iso-review-skips-terms = ライセンス条項、Microsoft アカウント、プライバシーの画面を省略
iso-review-network = ネットワーク ドライバー
iso-review-network-included = この PC の Wi-Fi とイーサネットのドライバー
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = 今すぐ (デスクトップが開く前に完了)
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = 必要な領域: { $needed } · { $drive } の空き領域: { $free }
iso-destination-short = ISO には { $needed } が必要ですが、{ $drive } の空き領域は { $free } です。空き領域を確保するか、別のドライブに保存してください。
iso-destination-filesystem = { $drive } には ISO の大きなファイルを保存できません。Windows ドライブなど、NTFS でフォーマットされたドライブに保存してください。
iso-destination-unusable = Atlas が ISO を保存できるのは、この PC 内のドライブにあるフォルダーだけです。
iso-create = ISO を作成
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = ISO を作成しています…
# The progress bar's label while an ISO or a USB drive is created: the stage under way, ending
# in an ellipsis. $stage is one of the iso-stage-* or usb-stage-* names. Those names also label
# the list of stages, each shown as completed, in progress or not started, so add here any
# in-progress form your language needs. Japanese adds 中 to the noun: "Windows ISO の読み取り中…".
iso-progress-stage = { $stage }中…
# The stages of creating the ISO, as a list under iso-progress-title. Each name reads as
# completed, in progress or not started (iso-stage-a11y), so write it as a noun or plain verb
# phrase, without an in-progress form; Japanese uses a plain noun (〜の読み取り), without 中.
iso-stage-read = Windows ISO の読み取り
iso-stage-copy = Windows ファイルのコピー
iso-stage-add-atlas = Atlas の追加
iso-stage-master = ISO ファイルの書き込み
iso-stage-verify = 新しい ISO の確認
iso-stage-cleanup = 最終処理
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }、{ $status }
iso-stage-status-current = 進行中
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = 失敗
iso-stage-status-not-started = 未開始
iso-progress-keep-open = 完了するまで Atlas を開いたままにしてください。
iso-cancel = 作成をキャンセル
iso-cancelling = 安全にキャンセルできる時点を待っています
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = キャンセルしています…
iso-cancelled = ISO の作成をキャンセルしました
iso-cancelled-unchanged = 元の ISO は変更されていません。
iso-complete = ISO が完成しました
iso-complete-backup = この ISO から Windows を再インストールする前に、ファイルをバックアップしてください。
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = USB ドライブを作成
iso-open-folder = フォルダーに表示
iso-failed = ISO の作成を完了できませんでした
# Under iso-failed, beside Try again.
iso-failed-retry = ファイルが選択した場所にあり、保存先のドライブが接続されていることを確認してから、再試行してください。
# Title while checking the files fails; the messages below say why.
iso-check-failed = ファイルを確認できませんでした
iso-check-failed-retry = ISO と Atlas パッケージのダウンロードが完了していることを確認してから、再試行してください。
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas は作業フォルダーを準備できなかったため、何も変更されていません。
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = この ISO には Atlas が対応するエディションがありません
iso-edition-unsupported = Windows Home と LTSC には対応していません。Pro、Education、Enterprise を含む ISO を使用してください。
iso-customised-title = この ISO はカスタマイズされています
iso-customised = autounattend.xml などのセットアップ ファイルがすでに含まれています。Microsoft が提供する未変更の ISO を使用してください。
iso-preview-title = この ISO はプレビュー ビルドです
iso-preview = この Windows ビルドは、Microsoft の一般公開版の一覧にありません。Microsoft が提供する ISO を使用してください。
iso-windows-unsupported-title = この Atlas パッケージでは、この ISO を使用できません
iso-windows-unsupported = パッケージが対応するバージョンの、未変更の Windows 11 ISO を使用してください。
iso-release-unknown-title = Atlas はこの Windows リリースを確認できませんでした
iso-release-unconfirmed = Atlas は Microsoft の一般公開版の一覧で確認します。インターネット接続を確認してから、再試行してください。
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = この Atlas パッケージでは ISO を作成できません
iso-package-old = Atlas { $minimum } 以降を使用してください。
iso-manager-missing-title = Atlas Manager のファイルが見つかりません
iso-fix-package = 別のパッケージを選択
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager の更新が必要です
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas は、この PC のネットワーク ドライバーを ISO に追加できませんでした。
iso-network-skip = ドライバーなしで作成
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = ISO の作成には管理者権限が必要です
iso-admin-reason = Windows ISO を読み取って新しい ISO を作成するために必要です。
iso-elevation-declined = Windows が Atlas に許可を与えなかったため、まだ Windows ISO を読み取れません。
# The free space ran out while the ISO was being created.
iso-failed-space = 保存先ドライブの空き領域が不足しています。空き領域を確保するか、新しい ISO を別のドライブに保存してください。
# Under iso-manager-missing-title.
iso-manager-missing = AtlasManager.exe を「ダウンロード」などのローカル フォルダーにダウンロードし、そこから開いてください。
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = この ISO には対応する Windows エディションが含まれていません。Windows Home と LTSC には対応していません。Pro、Education、Enterprise など、別のエディションを含む ISO を使用してください。
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = ログ フォルダーを開く
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas は Windows Update の処理中です。完了すると、ここで続行できます。
# Names of the markers Windows sets when it wants a restart. They complete
# "Windows の再起動が必要です (…)"; keep them short, noun-stop, in the half-width parentheses.
prepare-reason-servicing = Windows サービシング
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = 置き換え待ちのファイル
prepare-reason-update-agent = Windows Update サービス
prepare-reason-unknown = 理由の報告なし
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = 再試行しても解決しない場合は、Windows Update または Microsoft Store で残りの更新を完了してください。
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = 一部の更新を完了できませんでした
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after


# Atlas was closed while it ran.
prepare-unconfirmed = 更新が結果を報告する前に停止しました。
# Title of the bar over prepare-ended-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = 更新の結果を確認できませんでした
prepare-affected-app = 対象のアプリ
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = { $app } を閉じてから、再試行してください。見つからない場合は、タスク マネージャーで終了してください。
prepare-install-busy = 別のインストールまたは必要な再起動により、更新がブロックされています。他のインストールが終わるのを待ち、Windows から再起動を求められた場合は PC を再起動してから、再試行してください。
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows を修復できませんでした
prepare-components-damaged = 更新プログラムのインストールを妨げる破損があると Windows が報告しています。再起動で解消できることがあり、サインイン後に Atlas が続行します。
prepare-restart-and-retry = 再起動して再試行
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows の破損が大きいため更新できません
prepare-components-unrepairable = ファイルをバックアップしてから、Atlas ISO で Windows を再インストールしてください。
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas は、Windows にサインインしているアカウントとは別のアカウントで実行されています。管理者アカウントで Windows にサインインし、そのアカウントから Atlas を開いてから、再試行してください。
prepare-failed-store-missing = お使いのアカウントでは Microsoft Store がセットアップされていません。Microsoft Store を一度開くか、見つからない場合は再インストールしてから、再試行してください。
prepare-failed-store-battery = バッテリーを節約するため、Microsoft Store が更新を一時停止しました。PC を電源に接続してから、再試行してください。
prepare-failed-store-network = PC が従量制課金接続ではないネットワークに接続されるまで、Microsoft Store は更新を一時停止しています。従量制課金接続ではない Wi-Fi またはイーサネットに接続してから、再試行してください。
prepare-failed-store-timeout = Store アプリの更新が完了していません。Microsoft Store で残りのダウンロードを完了してから、再試行してください。
prepare-failed-store-passes = Microsoft Store から新しい更新プログラムが提供され続けました。Microsoft Store で残りの更新を完了してから、再試行してください。
prepare-failed-manual-updates = 一部の Windows 更新プログラムは Windows Update で完了する必要があります。Windows Update を開いて完了してから、再試行してください。
prepare-failed-windows-passes = Windows Update から新しい更新プログラムが提供され続けました。Windows Update で残りの更新を完了してから、再試行してください。
prepare-failed-windows-update-unreachable = Windows Update が Microsoft のサーバーに接続できませんでした。インターネット接続と、ファイアウォール、プロキシ、VPN の設定を確認してから、再試行してください。
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-failed-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager がリンクされたフォルダーにあります。Atlas を閉じ、Atlas Manager をこの PC のローカル フォルダーに移動してから、そこから開いてください。
prepare-error-code = エラー コード: { $code }
prepare-open-store = Microsoft Store を開く
prepare-windows-search = Windows の更新を確認しています…
prepare-percent = この段階の { $percent }% が完了
prepare-count = 完了した更新: { $completed } / { $total }
prepare-bytes = 約 { $total } MB 中 { $downloaded } MB をダウンロード済み
prepare-progress-still = { $minutes } 分間、進捗がありません。大きな更新には時間がかかることがあるため、Atlas を開いたままにしてください。
prepare-report-late = Windows からしばらく進捗が報告されていません。更新はまだ実行中の可能性があるため、Atlas を開いたままにしてください。
prepare-windows-download = Windows の更新プログラムをダウンロードしています…
prepare-windows-install = Windows の更新プログラムをインストールしています…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Windows を修復しています…
prepare-windows-repair-detail = 更新プログラムのインストールを妨げる可能性のある破損があると Windows が報告しています。30 分以上かかることがあります。
prepare-store-search = Microsoft Store を確認しています…
prepare-store-install = Microsoft Store とアプリを更新しています…
prepare-stop = 更新を停止
prepare-start = 更新を確認してインストール
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Atlas パッケージの準備ができると利用できます。
iso-username = ローカル アカウント名
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = パスワードは、初めてサインインするときに設定します。
iso-username-placeholder = お名前
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = 続行するには、ローカル アカウント名を入力してください
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = 20 文字以内で入力してください。先頭と末尾には空白を使えません。また、次の記号は使えません: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = 名前の末尾にピリオド (.) は使用できません。
iso-account-reserved = この名前は Windows の組み込みアカウントで使用されています。別の名前を入力してください。
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Windows セットアップでライセンス条項への同意を求められます。
prepare-drivers = ドライバーのインストール方法
prepare-drivers-auto = Windows Update から取得する
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Windows Update から取得する (推奨)
prepare-drivers-auto-detail = Windows がハードウェアに適したドライバーを探します。
prepare-drivers-manual = 自分でインストールする
prepare-drivers-manual-detail = Windows Update はドライバーをインストールしなくなるため、PC やデバイスのメーカーから入手する必要があります。インストール済みのドライバーは保持されます。
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = ドライバー
iso-network-drivers = この PC の Wi-Fi とイーサネットのドライバーを含める
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = サインイン後に選ぶ
prepare-network-unmetered = 更新には、従量制課金接続ではないインターネット接続が必要です。Wi-Fi またはイーサネットに接続してから、再試行してください。
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows の報告によると、このネットワークはインターネットに接続できません。ネットワークからサインインを求められた場合はサインインするか、ルーターのほか、DNS やファイアウォールによるフィルタリングも確認してから、再試行してください。
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = この接続は従量制課金接続に設定されているか、データ使用量の上限が設定されています。従量制課金接続ではないネットワークに接続するか、ネットワーク設定で「従量制課金接続」をオフにしてから、再試行してください。
prepare-network-settings = ネットワーク設定を開く
iso-stage-network-drivers = ネットワーク ドライバーの準備
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = この PC のネットワーク アダプターは Windows 付属のドライバーを使用しているため、ISO に含める必要はありません。
desktop-setup-description = PC のセットアップを完了しましょう。Atlas の選択内容は保存されています。必要に応じて Windows に戻れます。
desktop-setup-exit = Windows で続ける

# Windows installation USB
usb-title = USB ドライブを作成
usb-existing = 既存の ISO から USB ドライブを作成
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB ドライブ
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows ISO
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = 「ダウンロード」フォルダーに Atlas ISO がありません。
usb-iso-checking = ISO を確認しています…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas はこの ISO から USB ドライブを作成できません。Atlas で作成した ISO か、Microsoft が提供する Atlas 対応バージョンの Windows 11 ISO を使用してください。
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO または Atlas Manager が、ネットワーク上の場所かリンクされたフォルダーにあります。「ダウンロード」など、この PC 上のフォルダーに移動してください。
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Windows ドライブの空き領域が不足しているため、この ISO を準備できません。空き領域を確保すると、Atlas が自動的にもう一度確認します。
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas はこの ISO を読み取れませんでした。再試行するか、別の ISO を使用してください。
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = ストレージ設定を開く
usb-looking = USB ドライブを探しています…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = { $size } GB 以上の USB ドライブを接続してください。
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = 容量不足です。{ $size } GB 以上が必要です。
usb-drive-too-small-iso = この ISO には容量が足りません
usb-drive-has-iso = このドライブに ISO があります
usb-drive-has-app = Atlas Manager はこのドライブから実行されています
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, an ISO's architecture and size under its name, and
# ready-checks-passed-some and ready-checks-handled on Get ready.
usb-detail-separator = { " · " }
usb-create = USB ドライブを作成
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = 先に USB ドライブを選んでください
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = { $drive } ({ $size }、{ $letters }) を消去しますか?
usb-confirm-title = { $drive } ({ $size }) を消去しますか?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = USB ドライブ ({ $size }、{ $letters }) を消去しますか?
usb-confirm-title-unnamed = USB ドライブ ({ $size }) を消去しますか?
usb-confirm-message = ドライブ上のすべてのデータが削除されます。ISO は保持されます。
usb-confirm-erase = 消去して作成
usb-progress-title = USB ドライブを作成しています…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title, which
# iso-progress-stage also names while each runs. Each name reads as completed, in progress or not
# started, as the ISO's stages do, so write it as a noun or plain verb phrase; Japanese uses a
# plain noun, without 中.
usb-stage-prepare-files = ファイルの準備
usb-stage-formatting = フォーマット
usb-stage-copying = ファイルのコピー
usb-stage-checking = ドライブの確認
usb-stage-ejecting = 取り出し
usb-keep-open = Atlas を開いたまま、ドライブを接続しておいてください。
usb-scan-failed-title = USB ドライブの一覧を取得できませんでした
usb-scan-failed-retry = Atlas は、この PC に接続されているドライブを読み取れませんでした。再試行してください。
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = USB ドライブを作成できませんでした
usb-complete-title = USB ドライブの準備ができました
# F12, F11 and Esc are key names.
usb-ready = ドライブを取り外し、再インストールする PC のファイルをバックアップしてから、その PC を USB ドライブから起動してください。ブート メニューは多くの場合、F12、F11、Esc のいずれかのキーで開きます。
# After erasing may have begun.
usb-failed-partial = ドライブへの書き込みが途中で終わりました。接続されていることを確認してから、再試行してください。
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas はドライブを変更する前に停止しました。再試行してください。
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = USB ドライブが変わりました
usb-drive-changed = Atlas が消去する前にドライブが取り外されたか接続し直されたため、ドライブの内容は変更されていません。
usb-drive-cancelled-title = USB ドライブの作成をキャンセルしました
usb-cancelled-partial = ドライブは不完全な状態です。使用する前にもう一度作成してください。
usb-cancelled-unchanged = USB ドライブは変更されていません。
usb-eject-failed-title = USB ドライブを取り出せませんでした
usb-eject-failed-ready = ドライブは使用できる状態です。ドライブを使用しているファイルやウィンドウを閉じてから、再試行してください。
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = USB ドライブの作成には管理者権限が必要です
usb-admin-reason = ドライブを消去して書き込むには、Atlas に管理者権限が必要です。
usb-elevation-declined = Windows が Atlas に許可を与えなかったため、まだ USB ドライブに書き込めません。
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 の Home、LTSC、Server エディションには対応していません。Pro、Education、Enterprise など、別のエディションを使用してください。Windows がエディションを識別できなかった場合は、続行する前に問題を解決してください。
install-source-title = インストールできません
install-source-unsupported = Atlas { $source } から { $target } へ直接更新することはできません。このバージョンを使用するには、ファイルをバックアップしてから Windows を再インストールしてください。
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } から直接更新することはできません。新しいバージョンを使用するには、ファイルをバックアップしてから Windows を再インストールしてください。
# $folder is a folder path (text).
install-source-resume-package = Atlas { $target } のインストールが完了していません。このインストールを完了できるのは Atlas { $target } のパッケージだけです。その Atlas パッケージ (.atlaspkg) を開いてください。Atlas がダウンロードした場合は、{ $folder } にあります。
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } のインストールが完了していません。このテスト ビルドは同梱の Atlas パッケージしかインストールできないため、Atlas Manager のリリース ビルドで Atlas { $target } のパッケージを使用して、このインストールを完了してください。
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = この PC に何がインストールされているかを Atlas が確認できなかったため、今はインストールを行いません。
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Windows セットアップで、ライセンスをお持ちのエディションを選んでください。
detail-windows-preview = Insider ビルドには対応していません。Windows 11 の一般公開版を使用してください。
detail-windows-release-unknown = この Windows ビルドが一般公開版かどうかを確認できませんでした。インターネットに接続して、もう一度確認してください。
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = ビルド { $build } は Microsoft の Windows 11 一般公開版の一覧に含まれていないため、Atlas はまだこのビルドにインストールできません。Release Preview ビルドやその他のプレビュー ビルドには対応していません。Microsoft がこのビルドを一覧に追加したら、もう一度確認してください。


prepare-continue = 更新を続ける
prepare-saving-restart = 選択内容を保存し、Windows の再起動後に Atlas を開くよう設定しています…
prepare-restart-save-failed = 選択内容を保存できませんでした。再起動する前にもう一度お試しください。
prepare-restart-registration-failed = 選択内容は保存されましたが、再起動後に Atlas が自動で開くよう設定できませんでした。もう一度試すか、ご自身で PC を再起動し、サインイン後に Atlas を開いてください。
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = 選択内容は保存されましたが、Atlas Manager がリンクされたフォルダーにある間は、再起動後に Atlas が自動で開くよう設定できません。Atlas を閉じ、Atlas Manager をこの PC のローカル フォルダーに移動してください。その後、そこから開くか、ご自身で PC を再起動し、サインイン後にそこから開いてください。
prepare-restart-failed = Atlas は PC を再起動できませんでした。もう一度試すか、スタート メニューから再起動してください。選択内容は保存されており、サインイン後に Atlas が再び開きます。
diagnostics-export = 診断情報をエクスポート
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = 診断情報を収集中…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = ヘルプを表示
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = 診断情報を保存しました
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Atlas の { $folder } フォルダーに { $file } として保存しました。
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas は、この ZIP からユーザー名、PC 名、メール アドレス、既知のパスワードやキーを削除しました。
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = 診断情報の ZIP を保存できませんでした

## テスト ビルド (embedded-package 機能)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } テスト ビルド。このアプリは同梱の Atlas パッケージのみをインストールします。
home-status-bundled = テスト ビルド { $release }
package-bundled = このテスト ビルドに同梱された Atlas { $version } のインストール準備ができています。
rc-about-release = テスト ビルド
rc-about-commit = ソース コミット
rc-about-package = 同梱の Atlas パッケージ (SHA-256)
iso-package-bundled = このテスト ビルドに同梱された Atlas パッケージ

check-user-account = ユーザー アカウント
detail-user-account-ok = UAC が有効で、アカウントのインストール準備が整っています。
detail-user-account-not-ready = ユーザー アカウント制御 (UAC) を有効にし、PC を再起動してから、もう一度お試しください。組み込みの Administrator アカウントを使用している場合は、別の管理者アカウントでサインインしてください。
detail-user-account-work-or-school = 職場または学校アカウント (Microsoft Entra ID) からは Atlas をインストールできません。ローカル アカウントまたは Microsoft アカウントでサインインしてから、再試行してください。
detail-user-account-check-failed = Atlas はユーザー アカウントを確認できませんでした。PC を再起動し、Atlas を開き直してからもう一度確認してください。Windows の報告: { $error }

footer-prepare-required = 続行するには、Windows と Store アプリの更新を完了してください
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = 現在の段階が終わり次第、更新を停止します…
resume-choices-title = 前回のインストールを再開
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = 前回のインストールを完了するため、Atlas は前回の選択内容を使用します。完了するまで変更できません。

## レポートの送信
report-title = レポートを送信
report-received = レポートを受信しました
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = このレポートについて Atlas チームに問い合わせる場合に備えて、この参照番号を控えておいてください。連絡先を入力した場合はチームから返信することがありますが、返信は保証されません。
# Accessible name of the Copy button beside the report reference.
report-copy-reference = 参照番号をコピー
report-another = 別のレポートを送信
# Label of the choice between the two kinds of report.
report-kind = 何を送信しますか?
report-kind-issue = 問題
report-kind-suggestion = 提案
report-message = メッセージ
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = 何が起きましたか? そのとき何をしていましたか?
report-message-placeholder-suggestion = どのような変更をご希望ですか?
# Under the message box, which also reads it out.
report-message-help = パスワードは含めないでください。
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } / { $max } 文字
report-contact = 連絡先 (任意)
report-contact-placeholder = メール アドレスまたは Discord ユーザー名
report-attach = 診断情報を添付
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = 原因の特定に役立つログとシステムの詳細情報です。Atlas は、ユーザー名、PC 名、メール アドレス、既知のパスワードやキーを削除します。エラーの詳細、ハードウェアのモデル、アプリ名は残ります。送信前に ZIP の内容を確認できます。
report-review = ZIP を確認
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = 診断情報を準備できませんでした
report-prepare-failed-advice = 再試行するか、診断情報なしで送信してください。
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = レポートは reports.atlasos.net の Atlas チームに非公開で送信されます。メッセージと連絡先は、入力したとおりに送信されます。チームは調査のために他社の AI サービスを利用することがあります。AI サービスにはメッセージと診断情報が渡されますが、連絡先は渡されません。レポートは 90 日後に削除されます。また、サーバーのセキュリティ ログに IP アドレスが記録される場合があります。
report-website = プライバシーとレポート サイト
report-consent = このレポートと添付した診断情報を Atlas チームに送信することに同意します
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = インターネット接続を確認してから、再試行してください。レポート サイトから送信することもできます。
report-not-sent-busy = レポート サービスが混み合っています。数分待ってから、再試行してください。
report-not-sent-outdated = このバージョンの Atlas Manager ではレポートを送信できません。メッセージをレポート サイトにコピーし、診断情報を添付していた場合は ZIP も添付してください。
report-not-sent-diagnostics = 診断情報を送信できませんでした。再試行するか、診断情報なしで送信してください。
# The footer's button where this version can't send.
report-failed-website = レポート サイトを開く
# Beside a spinner in the footer while the report is on its way.
report-sending = 送信中…
report-send = レポートを送信

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = { $min }～{ $max } 文字で入力してください。

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = 連絡先は { $max } 文字以内で入力してください。

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = このレポートの送信に同意してください。

report-failed-title = レポートを送信できませんでした

## Windows のバージョンの更新
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = ファイルとアプリはそのまま残ります。
home-plan-name = この更新は 2 段階で行われます
home-plan-windows-title = Windows 11 バージョン { $release }
home-plan-windows-step = Atlas が Windows Update からインストールし、その後 PC が再起動します。
# The same step where moving is optional.
home-plan-windows-step-ask = 任意です。Atlas が事前に確認を求めたうえで Windows Update からインストールし、その後 PC が再起動します。
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = インストール済みです。
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas が選択内容を維持したまま更新され、その後 PC が再起動します。
# $date and $until are dates.
home-end-of-updates-title = Windows 11 バージョン { $current } のセキュリティ更新プログラムの提供は { $date } に終了します
home-end-of-updates-past-title = Windows 11 バージョン { $current } のセキュリティ更新プログラムの提供は終了しました
home-end-of-updates-message = Atlas { $version } に更新すると、この PC は Windows 11 バージョン { $release } にも移行します。このバージョンには { $until } までセキュリティ更新プログラムが提供されます。
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11 バージョン { $release } には { $until } までセキュリティ更新プログラムが提供されます。

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } は Windows 11 Pro、Enterprise、Education に対応しているため、{ $product } にはインストールできません。
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } は Windows 11 Pro、Enterprise、Education に対応しているため、{ $product } にはインストールできません。Windows 11 バージョン { $current } のセキュリティ更新プログラムは { $date } まで提供されます。Windows Update で、この PC を新しいバージョンに移行できます。
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } は Windows 11 Pro、Enterprise、Education に対応しているため、{ $product } にはインストールできません。バージョン { $current } のセキュリティ更新プログラムの提供は終了しているため、Atlas を使わない場合でも Windows を更新してください。
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } には Windows 11 バージョン { $releases } が必要ですが、Windows Update でこの PC をそのバージョンに移行することはできません。ファイルをバックアップしてから、Atlas ISO で Windows を再インストールしてください。
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } には Windows 11 バージョン { $releases } が必要ですが、Windows Update でこの PC をそのバージョンに移行することはできません。

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Atlas の更新のため、Windows Update の設定が変更されています
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = 更新が完了すると、Atlas がこれらの設定を元に戻します。
# When the last check found no offer yet.
home-update-access-waiting = Atlas はこの PC を Windows 11 バージョン { $release } に移行するために Windows Update をオンにしましたが、Windows Update ではまだ提供されていません。
home-update-access-updating = Atlas は更新プログラムをインストールするために Windows Update をオンにしましたが、まだ完了していません。
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Atlas の Windows Update の記録を読み取れませんでした
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas は、変更した Windows Update の設定の記録を読み取れないため、何も変更せず、元にも戻しません。
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas は設定を元に戻せませんでした。
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = 先に Atlas のインストールを完了してください。Atlas が変更した Windows Update の設定は、インストールの最後の段階で元に戻ります。
home-continue-update = 更新を続行
home-put-back = 設定を元に戻す
home-putting-back = 設定を元に戻しています…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11 バージョン { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } はバージョン { $current } に対応していないため、Atlas が先に Windows を更新します。
# Under the title where moving is optional.
windows-optional = Atlas はどちらのバージョンでも動作します。
# The choice's accessible name; the two answers say it.
windows-card-question = この PC でどのバージョンの Windows を使用しますか?
windows-choice-move-recommended = Windows 11 バージョン { $release } に更新 (推奨)
# $date is when the new version stops getting security updates.
windows-choice-move-support = { $date } までセキュリティ更新プログラムが提供されます。
windows-choice-keep = Windows 11 バージョン { $current } を維持
windows-choice-keep-later = バージョン { $current } のままです。後で Atlas Manager から移行できます。
windows-card-facts = 変更内容
windows-fact-files = ファイルとアプリはそのまま残ります。更新で元に戻された変更は、Atlas が適用し直します。
windows-fact-time = 通常は数分、最大 2 時間かかり、その後に再起動します。
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Windows PowerShell 2.0 と WMIC が削除されます。
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = 更新を元に戻す方法
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = 更新すると、マイクロソフト ソフトウェア ライセンス条項に同意したことになります。
windows-terms-link = ライセンス条項を読む
windows-accept = 同意して更新
# Once the terms are accepted, before the move starts by itself.
windows-starting = 開始しています…
windows-starts-after-checks = 確認に問題がなければ開始します。
windows-starts-after-package = Atlas { $version } の準備ができると開始します。
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = バージョン { $release } で Atlas の変更の一部がリセットされました。Atlas { $version } が以前の選択内容に従って適用し直します。
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Windows 11 バージョン { $current } を維持しますか?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas は一時的に Windows Update をオンにします
access-off = この PC では Windows Update がオフになっています。Windows の更新中は、Atlas がオンに戻します。
access-paused = この PC では Windows の更新が一時停止されています。Windows の更新中は、Atlas が一時停止を解除します。
access-delayed = この PC では毎月の更新プログラムが延期されています。Windows の更新中は、Atlas が延期を解除します。
# After the lines above.
access-back = Atlas { $version } のインストールが完了すると、これらの設定は元の状態に戻ります。
access-back-stop = それより前に停止した場合も、Atlas が元に戻します。

prepare-reason-feature-update = 新しい Windows バージョン
prepare-reason-feature-commit = 新しい Windows バージョンの完了処理
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Windows Update で Windows 11 バージョン { $release } が提供されるのを待っています…
windows-waiting-detail = 通常は数分、最大 2 時間かかります。Atlas が自動的に続行するため、その間も PC を使用できます。
windows-waited = { $minutes } 分間待機しています。
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update で 2 時間以内にバージョン { $release } が提供されませんでした
windows-wait-ended = Atlas は設定を元に戻しました。後でもう一度試すか、Atlas ISO で Windows を再インストールしてください。
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas は Windows Update の設定を元に戻せませんでした。
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows は再起動の準備ができませんでした
windows-commit-failed = PC は再起動していません。再試行してください。

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update でバージョン { $release } がまだ提供されていません
windows-outcome-not-offered = 最大 2 時間かかることがあります。PC は現在もバージョン { $current } です。
windows-outcome-hardware-title = この PC は Windows 11 の要件を満たしていません
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = この PC には { $missing } がないため、Windows Update でバージョン { $release } は提供されません。ファイルをバックアップしてから、Atlas ISO で Windows を再インストールしてください。
hardware-tpm = TPM 2.0
hardware-uefi = UEFI ファームウェア
windows-outcome-hidden-title = Windows Update でバージョン { $release } が非表示になっています
windows-outcome-hidden = 非表示にしたときのツールで再表示してから、再試行してください。
windows-outcome-disk-space-title = 空き領域が不足しています
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows には { $drive } に { $needed } GB の空き領域が必要ですが、現在は { $free } GB です。十分な空き領域ができると、Atlas が自動的に続行します。
windows-outcome-managed-title = この PC は組織から更新プログラムを受け取っています
windows-outcome-managed = 組織の更新サーバーはバージョン { $release } を提供していないため、Atlas は何も変更していません。組織に問い合わせるか、Atlas ISO で Windows を再インストールしてください。
windows-outcome-policy-title = Windows Update の設定が繰り返し元に戻されています
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = Atlas が { $setting } を変更しても元に戻されるため、Windows を更新できません。この PC が組織によって管理されている場合は、組織に問い合わせてください。
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = サービスが無効になっています: { $service }
windows-outcome-blocked-service = Windows Update にはこのサービスが必要です。「サービス」でスタートアップの種類を「手動」に設定してから、再試行してください。
windows-outcome-blocked-title = Windows Update がオフのままになっています
windows-outcome-blocked = Atlas が変更していない設定 { $setting } によって、Windows Update を実行できません。この設定を変更してから、再試行してください。
windows-outcome-rollback-title = Windows はバージョン { $release } のインストールを完了できませんでした
windows-outcome-rolled-back = バージョン { $current } に戻りました。ファイルとアプリに影響はありません。
windows-outcome-components-lost-title = Atlas の変更の一部が失われています
windows-outcome-components-lost = 原因を判断できないため、Atlas は Atlas { $version } をインストールする前に停止しました。
windows-outcome-build-title = 更新中に Windows のバージョンが変わりました
windows-outcome-build = Atlas が変更した設定を元に戻してから、ホームからやり直してください。
windows-outcome-journal-title = Atlas はこの更新の記録を読み取れません
windows-outcome-journal = Atlas チームが確認するまで、Atlas は何も変更せず、元にも戻しません。
windows-outcome-pin-title = Windows Update ポリシーを記録できません
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } には Atlas が後で元に戻せない値が設定されているため、Atlas は何も変更していません。
windows-outcome-terms-title = ライセンス条項に同意していません
windows-outcome-terms = Windows Update でバージョン { $release } をインストールするには、ライセンス条項への同意が必要です。
windows-outcome-failed-title = Windows はバージョン { $release } をインストールできませんでした
windows-outcome-failed = PC は現在もバージョン { $current } です。
# Windows services a move needs, as Services lists them. Japanese Windows shows these three
# names in English.
service-bits = Background Intelligent Transfer Service (BITS)
service-cryptsvc = Cryptographic Services
service-trusted-installer = Windows Modules Installer
prepare-open-services = 「サービス」を開く
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = バージョン { $current } を維持

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Atlas { $version } への更新を停止しますか?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Windows の更新を停止しますか?
stop-update-before = Atlas は変更した Windows Update の設定を元に戻します。Windows がすでにインストールした更新プログラムはそのまま残り、PC は Windows 11 バージョン { $current } のままです。
stop-update-after = PC は Windows 11 バージョン { $release } のままです。Atlas は変更した Windows Update の設定を元に戻します。
stop-update-access = Atlas は変更した Windows Update の設定を元に戻します。Windows がすでにインストールした更新プログラムはそのまま残ります。
stop-update-keep = 更新を継続
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Atlas を閉じますか?
window-close-update-access-message = Atlas は閉じる前に、変更した Windows Update の設定を元に戻します。更新はホームからもう一度開始できます。
window-close-put-back = 元に戻して閉じる
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = 設定を元に戻さずに閉じますか?
window-close-put-back-failed-message = 今 Atlas を閉じると、Windows Update の設定は Atlas が変更したままになります。次に Atlas を開くと、ホームから設定を元に戻せます。

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = このバージョンの Atlas には Windows 11 バージョン { $release } が必要ですが、この PC はバージョン { $current } です。

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Atlas のための Windows の更新が完了しませんでした。Atlas チーム向けの詳細:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = Windows 更新後の再インストール
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Atlas { $previous } からの選択内容
rebase-choices-kept = Atlas { $previous } で選んだ内容を Atlas が適用し直します。Atlas を再インストールすると、後で変更できます。
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas { $previous } で選んだその他の内容は、すべて Atlas が適用し直します。
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = 別のユーザーがサインインしたまま再起動しますか?
restart-others-question = 他のユーザーがサインインしたまま再起動しますか?
# $names lists their account names, such as "Alex、Sam"; $count is how many there are.
# Japanese needs no plural forms here.
restart-others-signed-in =
    { $count ->
       *[other] { $names } もサインインしています。再起動すると、そのユーザーのアプリが終了し、保存されていない作業は失われます。
    }
restart-others-keep = 再起動しない
restart-others-restart = このまま再起動
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Microsoft Store を更新しています…
prepare-store-repairing = Microsoft Store を修復しています…
prepare-store-repair-detail = 数分かかることがあります。
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = この PC では Microsoft Store がオフになっているため、Store アプリは更新されませんでした。
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store が動作していません
prepare-store-broken = Atlas は修復できませんでした。今 Atlas をインストールすると、Store アプリが動作しなくなるおそれがあります。
prepare-store-broken-iso = 修復が失敗し続ける場合は、ファイルをバックアップしてから、Atlas ISO で Windows を再インストールしてください。
prepare-repair-store-again = もう一度修復

screen-keyboard-title = キーボードの言語
screen-keyboard-question = 複数のキーボード言語を使いますか?
package-option-keyboard-shortcuts = はい、キーボード ショートカットで切り替える
package-option-keyboard-selector = はい、タスク バーの選択メニューで切り替える
package-option-keyboard-single = いいえ、1 つのキーボード レイアウトだけを使う
consequence-keyboard-shortcuts = Alt+Shift で言語を、Ctrl+Shift でキーボード レイアウトを切り替えます。
consequence-keyboard-selector = ゲーム中に誤って切り替わらないよう、Alt+Shift と Ctrl+Shift をオフにします。
package-choice-keyboard-description = キーボード言語の切り替え方法を選んでください。
consequence-keyboard-single = { consequence-keyboard-selector }
