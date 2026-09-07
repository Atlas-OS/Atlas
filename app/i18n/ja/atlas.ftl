### Atlas Manager: Japanese (ja), preview translation. Revised 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog:
### - Polite です・ます form for sentences; noun-stop or verb-stem labels for
###   buttons and headings, as Windows does (再起動, キャンセル, 完了).
### - A half-width space between Japanese and Latin words or numbers, and
###   between katakana compounds (インストール ファイル), as Microsoft does.
### - Full-width 。、 with half-width ( ) and : plus a half-width space, as
###   Microsoft Japanese UI does; half-width "?" in questions.
### - Japanese has only the "other" plural category; exact [1]/[2] are used
###   where the wording changes.
### - "Relaunch" (the Atlas Manager) is 再実行 / 開き直す; "restart" (the PC or
###   Windows) is 再起動. Never swap them.

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
# Accessible description of a disabled control.
common-not-available = 現在は利用できません
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
common-open-log-file = ログ ファイルを開く
# Accessible name of the Copy button beside the install log.
common-copy-install-log = インストール ログをコピー
common-install-log = インストール ログ
# Row labels in summary cards.
common-windows = Windows
common-options = オプション
common-package = インストール ファイル
common-installed-as = インストールの種類
common-installed = インストール済み
common-checking = 確認中
# Joins two items in a list: "Brave、Firefox". The braces keep the literal.
list-separator = { "、" }
# Joins two alternatives: "26100 または 26200".
list-or = { $a } または { $b }

## ウィンドウ

# Dialog shown when the window is closed while an install runs.
window-close-title = インストール中にウィンドウを閉じますか?
window-close-message = インストールはバックグラウンドで続行されます。進行状況と結果を確認するには、Atlas をもう一度開いてください。インストールが終わるまで PC の電源を切らないでください。
window-close-keep = 開いたままにする
window-close-close = ウィンドウを閉じる
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Atlas の Playbook (.apbx) を開く
# Message Windows shows in its restart notification.
shutdown-comment = Atlas のインストールが完了しました。セットアップを完了するため、Windows を再起動します。

## システム

# "Windows 11 Pro 25H2（ビルド 26200.1234）". All three values are text.
system-description = { $product } { $version } (ビルド { $build })

## ホーム ページ

home-not-installed = Atlas へようこそ
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = インストール日: { $date }
home-status-checking = 更新プログラムを確認しています
home-status-offline = 更新プログラムを確認できませんでした
home-status-not-checked = 更新プログラムはまだ確認していません
home-status-update = Atlas { $version } が利用可能です
home-status-up-to-date = 最新の状態です
home-status-newest = 最新バージョン: Atlas { $version }
home-check-again = もう一度確認
# Primary button while an install is running or waiting.
home-show-install = 進行状況を表示
home-continue-installing = セットアップを続行
home-update-to = Atlas { $version } に更新
home-reinstall = Atlas を再インストール
home-install = Atlas をインストール
home-start-over = 最初からやり直す
home-security-reminder-title = 保護をオンに戻してください
home-security-reminder-message = 実行中のインストールはありません。Windows セキュリティを開き、改ざん防止、リアルタイム保護、クラウド提供の保護、サンプルの自動送信をオンに戻してください。
home-elevation-title = インストールには管理者権限が必要です
home-state-error-title = Atlas のインストール情報を読み取れませんでした
home-whats-new = Atlas { $version } の新機能
home-view-release = GitHub でリリース ノートを表示
home-released = リリース日: { $date }
home-show-less = 折りたたむ
home-show-full-notes = リリース ノートをすべて表示
home-your-install = Atlas のインストール情報
# Row label: how Atlas was set up.
home-set-up = セットアップ方法
home-set-up-during-oobe = Windows のセットアップ中
home-history = インストール履歴
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = インストールの流れ
home-step-1-title = PC の確認
home-step-1-detail = Atlas が Windows を確認し、インストール ファイルをダウンロードします。この段階では Windows の設定は変更されません。
home-step-2-title = 設定の選択
home-step-2-detail = Windows の保護と更新プログラムの扱いを選び、必要に応じて追加のアプリや設定を選択します。
home-step-3-title = ウイルス対策の一時停止
home-step-3-detail = インストールを妨げないよう、Windows セキュリティの 4 つのスイッチをオフにする手順を Atlas がご案内します。
home-step-4-title = インストールと再起動
# Japanese has no plural forms; the same wording serves every count.
home-step-4-detail = 約 { $minutes } 分です。
# Accessible name of a numbered step.
home-step-a11y = 手順 { $number }: { $title }
# Link buttons: say where they lead, not just the brand.
home-github = GitHub で Atlas を見る
home-discord = Discord の Atlas コミュニティに参加
home-report-problem = 問題を報告

## インストールの種類（状態ドキュメントから）

mode-fresh = 新規インストール
mode-upgrade = 以前のバージョンからの更新
mode-reapply = 同じバージョンの再インストール
mode-unknown = インストール
# Short forms used inside a history row.
history-mode-fresh = 新規インストール
history-mode-upgrade = 更新
history-mode-reapply = 再インストール
history-mode-unknown = インストール

## ホーム ページの通知

notice-settings-reset-title = Atlas は既定のアプリ設定を使用しています
# $error is a raw error message (text).
notice-settings-unreadable = 保存されたアプリの設定を読み取れませんでした。Windows の設定は変更されていません。詳細: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = アプリの設定ファイルが破損していたため、リセットしました。以前のファイルは { $file } として保存してあります。詳細: { $error }
notice-settings-damaged = アプリの設定ファイルが破損していました。当面は既定の設定を使用します。詳細: { $error }
notice-settings-not-saved-title = アプリの設定を保存できませんでした
notice-session-unreadable-title = 前回のインストールの状態を確認できませんでした
# $path is a file path (text).
notice-session-unreadable-message = Atlas は { $path } を読み取れないため、インストールがまだ実行中かどうかを確認できません。判断できない場合は、このファイルを削除する前に Atlas コミュニティに相談してください。インストールが実行されていないことを確認できた場合に限り、ファイルを削除してから再試行してください。詳細: { $error }

## 管理者への昇格

elevation-declined = 許可が得られませんでした。再試行し、Atlas による変更を許可するかどうか Windows が確認したら「はい」を選んでください。
elevation-declined-continue = 許可が得られませんでした。再試行し、Atlas による変更を許可するかどうか Windows が確認したら「はい」を選んでください。選択した設定は保存されています。
elevation-draft-not-saved = 選択した設定を保存できなかったため、Atlas は再実行されていません。再試行してください。詳細: { $error }

## インストールの流れ

step-ready = 準備
step-options = 設定の選択
step-security = Windows セキュリティ
step-install = インストール
install-title = Atlas のセットアップ
# Accessible name of the row of steps.
stepper-label = Atlas セットアップの手順
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = 手順 { $number }/{ $total }、{ $title }、{ $status }
stepper-status-completed = 完了
stepper-status-current = 現在の手順
stepper-status-upcoming = 今後の手順
# Heading above each step's content.
step-heading = 手順 { $number }/{ $total }: { $title }

## 手順 1: 準備

ready-banner-busy-title = PC を準備しています
ready-banner-busy-message = Atlas が PC を確認し、インストールファイルを準備しています。
ready-banner-blocked-title = 先に対処が必要な項目があります
ready-banner-blocked-message = 下の指示に従ってから、「もう一度確認」を選んでください。
ready-banner-no-package-title = 続行するには Atlas をダウンロードしてください
ready-banner-no-package-message = 下から最新バージョンをダウンロードするか、保存済みの Atlas Playbook (.apbx) を開いてください。
ready-banner-warnings-title = 確認しておきたい点があります
ready-banner-warnings-message = 下の注意事項を読み、推奨される対処があれば続行前に済ませてください。
ready-banner-ok-title = 設定を選ぶ準備ができました
ready-banner-ok-message = 確認はすべて完了し、インストール ファイルの準備ができました。

# Card title and accessible name of the list of checks.
ready-this-pc = PC の確認
ready-check-again = もう一度確認

package-title = インストール ファイル
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } をダウンロード中 · { $received } / { $total } MB
# Japanese has no plural forms; the same wording serves every count.
package-unpacking-progress = 展開中 · { $done } / { $total } ファイル
package-unpacking = 展開中
package-looking = 最新の Atlas バージョンを確認しています。
package-none = インストール ファイルはまだありません。Playbook (.apbx) には、Atlas に必要な手順とファイルが含まれています。
# Short status words beside the card title.
package-status-downloading = ダウンロード中
package-status-unpacking = 展開中
package-status-failed = 準備できませんでした
package-status-ready = 準備完了
package-status-checking = 確認中
package-status-missing = 未ダウンロード
# Accessible name of the progress bar.
package-progress = インストール ファイルの進行状況
package-download-again = もう一度ダウンロード
package-download-version = Atlas { $version } をダウンロード
package-download-newest = 最新バージョンをダウンロード
package-open-file = Playbook ファイルを開く
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } を GitHub からダウンロードしました。インストールの準備ができています。
package-from-file = Atlas { $version } を { $file } から読み込みました。インストールの準備ができています。
package-unpacked = Atlas { $version } のインストール準備ができています。
package-at = インストール ファイル: { $path }
package-none-yet = インストール ファイルが選択されていません
acquire-no-asset = Atlas { $version } にはダウンロードできる Playbook ファイルがありません。続行するには、保存済みの Atlas Playbook (.apbx) を開いてください。
acquire-unsupported = このアプリでインストールできるのは Atlas 0.6.0 以降です。Atlas { $version } をインストールするには、代わりに AME Wizard を使ってください。
acquire-failed = インストール ファイルを準備できませんでした。もう一度ダウンロードするか、別の Atlas Playbook (.apbx) を開いてください。詳細: { $error }

## システム チェック

check-administrator = インストールの権限
check-supported-build = Windows の互換性
check-pending-updates = Windows 更新プログラム
check-pending-reboot = 保留中の再起動
check-third-party-antivirus = 他のウイルス対策ソフト
check-internet = インターネット接続
check-power = 電源
check-activation = Windows のライセンス認証
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
# Check boxes the user ticks when a check could not run.
check-ack-updates = Windows Update で、インストール待ちの更新プログラムがないことを確認しました
check-ack-reboot = Windows を再起動済みで、追加の再起動は必要ありません
check-ack-internet = この PC はインターネットに接続されています
check-ack-generic = この要件は自分で確認しました

detail-admin-ok = Atlas には、インストールに必要な変更を行う権限があります。
detail-admin-missing = Atlas を管理者として再実行し、Windows が許可を求めたら「はい」を選んでください。
# $builds is a list of build numbers such as "26100 または 26200"; $build is this PC's (text).
detail-build-unsupported = このバージョンの Atlas には Windows ビルド { $builds } が必要です。この PC のビルドは { $build } です。続行する前に、対応する Windows バージョンをインストールしてください。
detail-updates-none = インストール待ちの Windows 更新プログラムはありません。
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
 { $count ->
 [1] 先にこの更新プログラムをインストールしてください: { $titles }。
 [2] 先にこれらの更新プログラムをインストールしてください: { $titles }。
 *[other] 先に { $count } 個の更新プログラム ({ $titles } など) をインストールしてください。
 }
detail-updates-unknown = Windows 更新プログラムを確認できませんでした。Windows Update を開き、インストール待ちの更新プログラムがなければ下でチェックを入れてください。 ({ $error })
detail-reboot-none = 現在、Windows の再起動は必要ありません。
detail-reboot-pending = 以前の変更を完了するために PC を再起動し、Atlas を開き直してからもう一度確認してください。
detail-reboot-unknown = Windows に再起動が必要かどうかを確認できませんでした。PC を再起動し、Atlas を開き直してからもう一度確認してください。 ({ $error })
detail-antivirus-none = 他のウイルス対策ソフトは検出されませんでした。
# $products is a list of product names (text).
detail-antivirus-found = ウイルス対策ソフトがインストールを妨げる可能性があります: { $products }。続行する前に、このソフトをアンインストールしてください。
detail-antivirus-unknown = 他のウイルス対策ソフトを確認できませんでした。続行する前に、インストール済みのアプリを確認してください。 ({ $error })
detail-internet-ok = インターネットに接続されています。Atlas がソフトウェアをダウンロードしてインストールする間、接続を維持してください。
detail-internet-missing = インターネットに接続してから、もう一度確認してください。
detail-power-mains = PC は電源に接続されています。インストールが終わるまで接続したままにしてください。
detail-power-battery = インストール中に電源が切れないよう、PC を電源に接続してください。
detail-power-unknown = 電源の状態を確認できませんでした。ノート PC をお使いの場合は、続行する前に電源に接続してください。
detail-activation-ok = Windows はライセンス認証されています。Atlas はこれを変更しません。
detail-activation-missing = Windows はライセンス認証されていません。続行できますが、Atlas が代わりにライセンス認証を行うことはありません。
detail-activation-no-licence = Windows からライセンス情報が報告されませんでした。続行できます。Atlas はライセンス認証の状態を変更しません。
detail-activation-unknown = Windows のライセンス認証を確認できませんでした。続行できます。Atlas はライセンス認証の状態を変更しません。 ({ $error })

## 手順 2: 設定の選択

options-progress = 選択 { $number }/{ $total }
options-progress-extras = 選択 { $number }/{ $total }: 追加オプション
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = ウイルス対策の保護を残しますか?
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
screen-extras-question = 必要な追加オプションを選んでください
# Question for a required choice this app has no specific wording for.
screen-generic-question = 「{ $title }」のオプションを選んでください
learn-more-defender = Microsoft Defender の詳細
learn-more-mitigations = プロセッサの保護の詳細
learn-more-updates = Windows Update の詳細
learn-more-browser = ブラウザーの詳細
learn-more-power = 電源とセキュリティの詳細
learn-more-apps = アプリの詳細
learn-more-eclean = eclean と AtlasOS の連携について
learn-more-generic = セットアップ ガイドを読む
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Windows 標準のウイルス対策を残し、ウイルスなどの脅威から PC を保護します。
consequence-defender-disable = Microsoft Defender を削除します。別のウイルス対策アプリをインストールするまで、PC にはウイルス対策の保護がなくなります。
consequence-mitigations-default = プロセッサの仕組みを悪用する攻撃に対する、Windows の既定の保護を維持します。
consequence-mitigations-disable = これらの保護をオフにするため、セキュリティが低下します。パフォーマンスはプロセッサによって異なり、低下することもあります。
consequence-auto-updates-disable = Windows Update を開いて、更新プログラムをご自身でインストールする必要があります。更新の通知は引き続き表示されます。
consequence-auto-updates-default = Windows がセキュリティ修正を含む更新プログラムを自動的にインストールします。

## Playbook のテキスト
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender を残す (推奨)
playbook-option-defender-disable = Microsoft Defender を削除する
playbook-option-mitigations-default = 既定の保護を維持する (推奨)
playbook-option-mitigations-disable = プロセッサの保護をオフにする
playbook-option-auto-updates-disable = 更新プログラムを自分でインストールする
playbook-option-auto-updates-default = 更新プログラムを自動的にインストールする
playbook-option-disable-hibernation = 休止状態をオフにする
playbook-option-disable-power-saving = 省電力機能をオフにする
playbook-option-disable-core-isolation = 仮想化ベースのセキュリティ (VBS) をオフにする
playbook-option-remove-snipping-tool = Snipping Tool を削除する
playbook-option-uninstall-edge = Microsoft Edge を削除する
playbook-option-install-another-browser = ブラウザーをインストールする
playbook-option-install-toolbox = Atlas Toolbox をインストールする
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender は Windows 標準のウイルス対策です。残しておくことをお勧めします。削除するのは、リスクを理解し、別のウイルス対策アプリを使う予定がある場合だけにしてください。
playbook-page-mitigations-default-description = これらの保護 (セキュリティ緩和策とも呼ばれます) は、プロセッサの脆弱性を悪用する攻撃を防ぐのに役立ちます。Windows の既定の設定を維持することをお勧めします。
playbook-page-auto-updates-disable-description = Windows の更新プログラムにはセキュリティ修正が含まれます。Windows に自動でインストールさせるか、ご自身でインストールするかを選べます。
consequence-install-toolbox = Atlas Toolbox を追加すると、Atlas の設定を管理しやすくなります。Toolbox はベータ版のため、一部の機能は未完成の場合があります。
playbook-page-browser-brave-description = インストールするブラウザーを選んでください。Atlas はブラウザーの設定を変更しません。

## 手順 3: Windows セキュリティ

security-banner-reading-title = Windows セキュリティを確認しています
security-banner-reading-message = Atlas が下の 4 つの保護スイッチを確認しています。
security-banner-off-title = 4 つの保護スイッチはすべてオフです
security-banner-off-message = インストール前に、選択した設定を確認できます。
security-banner-readable-off-title = 読み取れたスイッチはオフです
security-banner-readable-off-message = 残りのスイッチを Windows セキュリティで確認してください。
security-banner-on-title = ウイルス対策の保護を一時的にオフにしてください
security-banner-on-message = これらの保護は、Atlas に必要な変更を妨げることがあります。
# The page name in Windows Security.
security-list-title = ウイルスと脅威の防止の設定
security-switch-off = オフ
security-switch-on = オン
security-switch-unreadable = 読み取れません
security-switch-reading = 確認中
security-all-off = すべてオフ
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 個がまだオン、1 個が読み取れません".
security-count-still-on = { $count } 個がまだオン
security-count-unreadable = { $count } 個が読み取れません
security-count-join = { $a }、{ $b }
security-unknown-title = Atlas が読み取れなかったスイッチを確認してください
security-unknown-message = Windows セキュリティで 4 つのスイッチがすべてオフになっていることを確認したら、下でチェックを入れてください。
security-acknowledge = Windows セキュリティで、4 つのスイッチがすべてオフになっていることを確認しました
security-unknown-unelevated-title = 保護の確認には管理者権限が必要です
security-unknown-unelevated-message = Microsoft Defender の設定を確認できるよう、Atlas を管理者として再実行してください。
# The four switches, named as Windows Security names them in Japanese.
protection-tamper = 改ざん防止
protection-tamper-why = Defender の保護設定を変更できるようにするため、最初にこれをオフにしてください。
protection-realtime = リアルタイム保護
protection-realtime-why = オフにすると、ファイルのスキャンが一時停止され、Defender が Atlas のインストール ファイルをブロックしなくなります。
protection-cloud = クラウド提供の保護
protection-cloud-why = オフにすると、Atlas のインストール ファイルをブロックする可能性があるオンラインの脅威チェックが一時停止されます。
protection-samples = サンプルの自動送信
protection-samples-why = オフにすると、Defender が Atlas のファイルを分析のために Microsoft へ自動送信しなくなります。

## 手順 4: インストール

install-preparing-title = インストール前の最終確認
install-preparing-message = 変更を加える前に、Atlas が PC と保護設定をもう一度確認しています。
install-installing = インストール中
install-running = 実行中
# Accessible name of the progress bar.
install-progress = インストールの進行状況
phase-preflight = PC を確認し、ファイルを準備しています
phase-staging = インストール ファイルを準備しています
phase-applying = Windows を設定しています。PC の電源を切らないでください。
phase-done = セットアップを完了しています
outcome-succeeded-title = Atlas がインストールされました
outcome-lost-title = インストール結果を確認できませんでした
outcome-failed-title = インストールが完了しませんでした
outcome-succeeded = PC を再起動して Atlas のセットアップを完了してください。
outcome-requirements = この PC はインストール要件を満たしていませんでした。インストールによる変更はありません。「準備」に戻って、もう一度確認を実行してください。
outcome-not-elevated = インストールによる変更はありません。Atlas を管理者として再実行し、もう一度お試しください。
outcome-failed-preflight = 変更を加える前にインストールが停止しました。ログ ファイルを開いて原因を確認し、再試行してください。
outcome-failed-staging = ファイルの準備中、Windows を変更する前にインストールが停止しました。ログ ファイルを開いて原因を確認し、再試行してください。
outcome-failed-applying = 一部の変更はすでに適用されている可能性があります。ここで中止する場合は、オフにした保護のうちまだ利用できるものを Windows セキュリティでオンに戻してください。
outcome-not-started = インストーラーが時間内に起動しませんでした。インストールによる変更はありません。「再試行」を選んでください。
outcome-lost = インストーラーが結果を報告せずに終了しました。一部の変更はすでに適用されている可能性があります。ログ ファイルを開いて原因を確認し、「再試行」を選ぶとインストールを再開できます。
restart-now-message = Atlas のセットアップを完了するため、Windows を再起動しています。
# Japanese has no plural forms; the same wording serves every count.
restart-countdown = Atlas のセットアップを完了するため、{ $seconds } 秒後に Windows を再起動します。
restart-stopped = 自動再起動をキャンセルしました。作業を保存してから PC を再起動し、Atlas のセットアップを完了してください。
restart-needed = 作業を保存してから Windows を再起動し、Atlas のセットアップを完了してください。
restart-dont-now = 後で再起動
restart-now = 今すぐ再起動
# Accessible name of the countdown bar.
restart-progress = 再起動までの時間
restart-start-failed = Windows を再起動できませんでした。作業を保存してから、スタート メニューから再起動してください。詳細: { $error }
preflight-title = インストールは開始されていません
preflight-invalid-options = 選択した設定を Atlas で使用できませんでした。「設定の選択」に戻って内容を確認し、再試行してください。詳細: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = 前回の確認の後で PC の状態が変わりました。次の問題を解決してから再試行してください。{ $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 個がまだオン".
preflight-security = Windows セキュリティ: { $summary }。
preflight-busy = 別の Atlas ウィンドウがインストールを開始しています。少し待ってから再試行してください。
preflight-record-unreadable = 前回のインストールがまだ実行中かどうかを確認できなかったため、Atlas は新しいインストールを開始していません。Atlas を閉じて開き直すと、復旧の手順が表示されます。詳細: { $error }
preflight-refused = インストーラーを起動できませんでした。インストールによる変更はありません。詳細: { $error }
go-to-ready = 「準備」に戻る
go-to-options = 「設定の選択」に戻る
output-problem-title = インストールの進行状況を読み取れませんでした
output-problem-message = Atlas はログを読み取れませんでした。インストールが停止したとは限りません。PC の電源を切らずに、ログ ファイルを開いてみてください。詳細: { $error }
install-elevate-title = インストールには管理者権限が必要です
install-no-package-title = 先にインストール ファイルを選んでください
install-no-package-message = 「準備」に戻って Atlas をダウンロードするか、保存済みの Playbook (.apbx) を開いてください。
install-security-title = インストール前にウイルス対策の保護を確認してください
install-security-reading = 4 つの保護スイッチをもう一度確認しています。
install-security-message = { $summary }。続行する前に、Windows セキュリティを開いて 4 つのスイッチがすべてオフになっていることを確認してください。
summary-this-install = インストールの概要
summary-try-again = 再試行前の確認
summary-ready = Atlas のセットアップ内容を確認
summary-activation = ライセンス認証
summary-activation-ok = ライセンス認証済み。Atlas はこれを変更しません。
summary-activation-missing = ライセンス認証されていません。続行できますが、Atlas が Windows のライセンス認証を行うことはありません。
summary-activation-unknown = Atlas は Windows のライセンス認証の状態を変更しません。
summary-duration = 推定時間
# Japanese has no plural forms; the same wording serves every count.
summary-duration-value = { $minutes } 分、その後に再起動
summary-restart-checkbox = インストール後に PC を自動的に再起動する
summary-show-command = インストール コマンドを表示
summary-hide-command = インストール コマンドを非表示
summary-command-unavailable = インストール コマンドを準備できませんでした。詳細: { $error }
summary-not-chosen = まだ選択されていません
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } を変更
footer-still-checking = インストールの準備中
footer-fix-items = 続行するには、上の確認項目をすべて完了してください
footer-need-package = 続行するには、Atlas をダウンロードするか Playbook を開いてください
footer-reading-security = 保護スイッチを確認中
button-checking = 確認中
button-installing = インストール中
button-install = Atlas をインストール
# Japanese has no plural forms; the same wording serves every count.
log-earlier-lines = これより前の { $count } 行はログ ファイルにあります。
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (完全なログ: { $path })

## インストール中の画面

installing-checking-title = 最終確認
installing-checking-line = 変更を加える前に、Atlas が PC を確認しています。少し時間がかかる場合があります。
installing-title = Atlas をインストールしています
installing-phase-preflight = PC を確認し、インストール ファイルを準備しています。
installing-phase-staging = インストール ファイルを準備しています。PC の電源を切らないでください。
installing-phase-applying = 選択した設定に従って Windows を設定しています。PC の電源を切らず、電源に接続したままにしてください。
installing-phase-done = インストールを完了しています。PC の電源を切らないでください。
installing-installed-title = Atlas がインストールされました
# $time is a formatted clock time.
installing-started-just-now = { $time } に開始 (経過 1 分未満)
# Japanese has no plural forms; the same wording serves every count.
installing-started-minutes = { $time } に開始 (経過 { $minutes } 分)

## 再起動後の「Atlas がインストールされました」ウィンドウ

installed-title-version = Atlas { $version } がインストールされました
installed-title = Atlas がインストールされました
installed-ready = セットアップが完了しました。Atlas を適用した PC をお使いいただけます。
installed-open-atlas = Atlas のインストール情報を表示

## 設定

settings-title = 設定
settings-theme = アプリのテーマ
settings-theme-system = Windows に合わせる
settings-theme-light = ライト
settings-theme-dark = ダーク
settings-theme-contrast-note = Atlas は Windows のコントラスト テーマの配色を使用しています。
settings-theme-mica-note = 半透明の背景を表示するには、Windows と同じライトまたはダークのテーマを選んでください。
settings-language = 言語
settings-language-system = Windows に合わせる
# Under "Windows に合わせる": which language that gives. $language is a language's own name.
settings-language-system-detail = 「Windows に合わせる」の場合: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = プレビュー · 言語レビュー待ち
preview-notice = { $language }はプレビュー翻訳です。
preview-notice-switch = 英語に切り替える
preview-notice-language = 言語を変更
# $tag is a language tag (text).
settings-language-unavailable = { $tag } はこのバージョンの Atlas では利用できません。現在は英語で表示しています。選択した言語は保存されています。
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas は Windows の表示言語 ({ $languages }) にまだ対応していません。現在は英語で表示しています。
settings-language-windows-unavailable = Windows の表示言語を確認できませんでした。現在は英語で表示しています。詳細: { $error }
# $locale is the regional format's own name, for example "日本語 (日本)".
settings-language-formats = 数値、日付、時刻は Windows の地域設定の形式 ({ $locale }) に従います。
settings-language-contribute = GitHub で Atlas の翻訳に協力する
settings-installing = インストール
settings-restart-label = インストール後に PC を自動的に再起動する
settings-restart-locked = この設定はインストールが終わってから変更できます。
settings-restart-description = セットアップを完了するには再起動が必要です。自動再起動がオンの場合は、インストール前に作業を保存してください。
settings-about = バージョン情報
settings-about-app = Atlas Manager
settings-about-data = アプリのファイル
settings-about-licence = ライセンス
settings-about-licence-value = GPL-3.0、無料のオープン ソース
settings-view-source = GitHub でソース コードを表示
settings-open-data-folder = アプリのフォルダーを開く

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = 休止状態でセッションを保存するために使うディスク領域を解放します。休止状態と高速スタートアップは使えなくなります。
consequence-disable-power-saving = 省電力機能をオフにします。消費電力や発熱が増え、バッテリー駆動時間が短くなる場合があります。
consequence-disable-core-isolation = メモリ整合性を含む、Windows の追加のセキュリティ層をオフにします。保護が弱まり、この機能を必要とするアプリやゲームに影響する場合があります。
consequence-remove-snipping-tool = スクリーンショットや画面録画に使う Windows のアプリを削除します。
consequence-uninstall-edge = Microsoft Edge ブラウザーを削除します。別のブラウザーがあることを確認するか、下で選んでください。
consequence-install-another-browser = 下でブラウザーを選ぶと、Atlas がインストールします。

# Introduction on the home page before Atlas is installed.
home-intro = Atlas は Windows を調整して、バックグラウンドの動作や気を散らす要素を減らします。変更を加える前に、確認と選択の手順をご案内します。

detail-build-missing = この Playbook には対応する Windows ビルドが指定されていません。LocalTest パッケージではなく、完全な Playbook ビルドを選んでください。
## ISO creation (Beta)
iso-home-title = Windows インストールメディア
iso-home-description = Atlas を含む Windows ISO を作成し、この PC や別の PC に新規インストールできます。
iso-open = Atlas ISO を作成
iso-title = Atlas ISO を作成
iso-beta = ベータ
iso-beta-description = PC で使用する前に、仮想マシンで ISO をテストしてください。Windows のインストール前にファイルをバックアップしてください。
iso-admin-description = Windows イメージの読み取りとインストールメディアの作成には、管理者権限が必要です。
iso-files-description = 未変更の Windows 11 x64 ISO、Atlas プレイブック（.apbx）、出力先の新しいファイル名を指定してください。
iso-source = Windows ISO
iso-package = Atlas プレイブック (0.6+)
iso-output = 新しい ISO の保存先
iso-no-file = ファイル未選択
iso-browse = 参照
iso-save-as = 名前を付けて保存
iso-inspect = ファイルを確認
iso-mode-title = Windows と Atlas の設定
iso-mode-interactive = サインイン後に Atlas の設定を選択
iso-mode-interactive-description = サインイン後、Atlas アプリで Windows と Store アプリを更新し、設定を選択して Atlas を適用します。
iso-mode-before = Atlas の設定を今すぐ選択
iso-mode-before-description = Atlas の設定を ISO に保存します。サインイン後に Windows と Store アプリを更新してから、この設定で Atlas を適用します。
iso-package-unsupported-title = 新しいプレイブックを選んでください
iso-package-unsupported = ISO のセットアップには、ISO に対応した Atlas 0.6 以降が必要です。対応する Playbook を選択してください。
iso-atlas-options = Atlas の設定
iso-review = ISO の内容を確認
iso-review-description = Atlas は元の ISO を残して、新しい ISO を作成します。Windows をインストールするには、新しい ISO から起動してください。ISO の作成だけでは、この PC に Atlas はインストールされません。
iso-review-files = ファイル
iso-review-package = Atlas プレイブック
iso-review-output = 新しい ISO
iso-review-editions = エディション
iso-review-size = サイズ
iso-review-size-value = { $size } MB
iso-review-account = アカウント名
iso-review-target = インストール先
iso-review-drivers = ドライバー
iso-create = ISO を作成
iso-stage-inspect = Windows イメージを確認中
iso-stage-copy = Windows ファイルをコピー中
iso-stage-inject = Atlas を追加中
iso-stage-master = ISO を作成中
iso-stage-verify = 出力を検証中
iso-stage-cleanup = 最終処理中
iso-progress-description = アプリを開いたままにしてください。大きなイメージの処理には時間がかかる場合があります。
iso-cancel = 作成をキャンセル
iso-cancelling = 安全にキャンセルできる時点を待っています
iso-cancelled = ISO の作成をキャンセルしました
iso-cancelled-description = 元の ISO は保持されています。削除が必要な一時ファイルが残っている場合は、診断ログに記録されます。
iso-complete = ISO が完成しました
iso-complete-description = 仮想マシンでテストしてから、Windows インストールメディアの作成に使用してください。
iso-open-folder = フォルダーに表示
iso-failed = ISO の作成を完了できませんでした
iso-failed-description = 診断を開いて原因を確認してください。問題を解決したら、新しい出力ファイル名でやり直してください。
iso-diagnostics = 診断を開く
iso-close-title = ISO を作成しています
iso-close-message = 作成またはキャンセルが完了するまで、このウィンドウを開いたままにしてください。キャンセルは、現在の処理を安全に停止できる時点まで待機します。
iso-keep-open = 開いたままにする
prepare-title = Windows と Store アプリの更新
prepare-description = Atlas を適用する前に、Windows の更新プログラムをインストールし、Microsoft Store とインストール済みのすべての Store アプリを更新します。更新中に Store アプリが終了することがあります。
prepare-complete = Windows と Store アプリは最新の状態です。
prepare-reboot = Windows の再起動が必要です。Atlas の設定は保存されます。サインイン後に、もう一度更新を確認してください。
prepare-failed = 一部の更新を完了できませんでした。診断ログを確認し、Windows または Store のエラーを解消してから、もう一度お試しください。
prepare-cancelled = 準備を停止しました。続行する前に、もう一度更新を確認してください。
prepare-windows-search = Windows の更新を確認しています…
prepare-windows-download = Windows の更新プログラムをダウンロードしています…
prepare-windows-install = Windows の更新プログラムをインストールしています…
prepare-store-search = Microsoft Store を確認しています…
prepare-store-install = Microsoft Store とアプリを更新しています…
prepare-stop-description = 現在の更新処理が完了してから停止します。停止するまで Atlas を開いたままにしてください。
prepare-stop = この処理が完了したら停止
prepare-restart = 再起動して続行
prepare-start = 更新を確認してインストール
iso-username = ローカルアカウント名
iso-account-description = パスワードは Windows の再インストール後に設定します。
iso-username-placeholder = お名前
iso-account-invalid = 1～20 文字で入力してください。前後の空白や、Windows のアカウント名で使用できない記号は使えません。
iso-privacy-defaults = Windows のセットアップでは、任意のデータ共有と個人向けのおすすめを自動的にオフにします。
prepare-drivers = ドライバーのインストール方法
prepare-drivers-auto = Windows Update から取得する
prepare-drivers-auto-detail = Windows がハードウェアに適したドライバーを探します。通常はこちらをおすすめします。
prepare-drivers-manual = 自分でインストールする
prepare-drivers-manual-detail = Windows Update からのドライバーのダウンロードをブロックします。ドライバーは自分で用意してください。インストール済みのドライバーは保持されます。
prepare-network-needed = 従量制課金接続ではない Wi-Fi またはイーサネットに接続して、再試行してください。Wi-Fi が表示されない場合は、先にネットワークドライバーをインストールしてください。
prepare-network-settings = ネットワーク設定を開く
iso-target-title = どの PC に Windows を再インストールしますか？
iso-target-this = この PC
iso-target-other = 別の PC
iso-copy-network = この PC のネットワークドライバーを含める
iso-network-detail = Windows のインストール時に、この PC の Wi-Fi とイーサネットのドライバーを再利用します。再インストール後は Wi-Fi に接続し直してください。
iso-network-source = ネットワークドライバーの取得元
iso-network-installed = インストール済みのドライバーを使う
iso-network-updated = 先に Windows Update で確認する
iso-network-updated-detail = Windows Update が提供する適合ドライバーをダウンロードし、インストール済みのドライバーも予備として保持します。従量制課金ではない接続が必要です。
iso-stage-network-drivers = ネットワークドライバーを準備しています…
iso-network-failed = ネットワークドライバーを準備できませんでした。診断情報を確認するか、前の画面に戻ってネットワークドライバーの設定を変更してください。
iso-mode-desktop = デスクトップを開く前にセットアップを完了
iso-mode-desktop-description = Atlas の設定を今選びます。サインイン後、更新と Atlas のセットアップを終えてから Windows デスクトップを開きます。
desktop-setup-description = PC のセットアップを完了しましょう。Atlas の設定は保存されています。必要に応じて Windows に戻れます。
desktop-setup-exit = Windows で続ける

# Windows installation USB (Beta)
usb-title = インストール USB を作成
usb-existing = 既存の ISO から USB を作成
usb-description = Windows 11 25H2 の起動用 USB を作成します。この USB から PC に Windows と Atlas をインストールできます。
usb-choose-iso = ISO を選択
usb-drive = USB ドライブ
usb-empty = USB ドライブを接続し、一覧を更新してください。書き込み可能で、現在実行中の Windows が含まれていない USB ドライブだけが表示されます。
usb-refresh = 更新
usb-drive-detail = { $size } GB · { $volumes } · シリアル番号: { $serial }
usb-review = USB を確認
usb-erase-title = この USB ドライブを消去しますか？
usb-erase-description = { $drive }（{ $size } GB）のすべてのファイルとパーティションが完全に消去されます。ISO ファイルは保持されます。
usb-layout = Windows のインストール用に最大 32 GB を使用します。残りの領域は未割り当てになります。この USB は UEFI で起動する PC 用です。
usb-ack = この USB ドライブの内容がすべて消去されることを理解しました。
usb-write = 消去して USB を作成
usb-stage-prepare = インストールファイルを準備しています…
usb-stage-format = USB をフォーマットしています…
usb-stage-copy = インストールファイルをコピーしています…
usb-stage-verify = USB を検証しています…
usb-working = Atlas を開いたまま、USB を接続しておいてください。キャンセルすると、現在の処理が安全に停止するまで待機します。未完成の USB では Windows をインストールできません。
usb-failed = USB の作成を完了できませんでした。接続を確認し、診断を開いて詳細を確認してください。再試行するにはドライブを選び直してください。
usb-cancelled = USB の作成を停止しました。ドライブに不完全なインストールファイルが残っている可能性があります。Windows のインストール前に作成し直してください。
usb-complete = USB の準備ができ、すべてのファイルの検証が完了しました。USB を取り出して再インストール先の PC に接続し、その PC の UEFI ブートメニューで選択してください。
usb-eject = USB を取り出す
usb-ejected = USB を安全に取り外せます。Windows をインストールするには、PC の UEFI ブートメニューでこの USB を選択してください。
usb-eject-failed = Windows で USB を取り出せませんでした。USB を使用しているファイルやウィンドウを閉じてから、もう一度お試しください。
ready-fresh-title = Windows を新規インストールしてください
ready-fresh-description = 対応する Atlas のアップグレードを除き、Atlas には Windows の新規インストールが必要です。Atlas 0.6 の新規インストールには Windows 11 25H2 が必要です。Windows を再インストールする前に、ファイルをバックアップしてください。
detail-edition-unsupported = Windows 11 Pro、Pro for Workstations、または Enterprise を使用してください。Home、LTSC、Server エディションには対応していません。エディションを識別できなかった場合は、続行する前に問題を解決してください。
install-source-title = インストールできません
install-source-unsupported = Atlas { $source } から { $target } へ直接更新することはできません。このバージョンを使用するには、Windows を再インストールしてください。
install-source-unknown = Atlas のインストール状態を確認できませんでした。未完了のインストールを解決し、診断情報を確認してから再試行してください。
iso-edition-selection = 対応するエディションのみが含まれます。Windows のセットアップでは、Windows ライセンスをお持ちのエディションを選択してください。
detail-windows-preview = Insider ビルドには対応していません。Windows 11 の一般公開版を使用してください。
detail-windows-release-unknown = この Windows ビルドが一般公開版かどうかを確認できませんでした。インターネットに接続して、もう一度確認してください。
iso-release-unknown = この ISO に Windows 11 25H2 の一般公開版が含まれているか確認できませんでした。インターネットに接続して再試行するか、公式のインストールメディアを選択してください。
prepare-previous-worker = 前の更新処理がまだ実行中です。処理が完了するまでお待ちください。完了後に再試行できます。

ready-used-windows-title = 続行する前に Windows を再インストールしてください
ready-used-windows-description = この Windows 環境には使用済みの兆候があります。ここへの Atlas のインストールはサポート対象外で、強く非推奨です。リスクを理解している場合のみ続行してください。
ready-used-windows-dismiss = リスクを理解しました
playbook-option-install-eclean = eclean をインストールする
consequence-install-eclean = セットアップ後の PC を整える、AtlasOS 開発チームのメンテナンスツールです。不要なファイルやスタートアップアプリを確認できます。アカウントとインターネット接続が必要です。
