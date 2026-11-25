### Atlas Manager: Russian (ru). Preview translation, revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog: the reader is addressed as "вы" (lower case,
### as Windows does); the computer is "ПК", never "компьютер"; buttons are short
### infinitives; "перезапустить" is the Atlas Manager relaunching, "перезагрузить" is
### the PC or Windows restarting. Windows feature names follow the Russian Windows UI.
### The .atlaspkg file is the "пакет Atlas" (declined: пакета, пакетом), shortened to
### "пакет" once that is clear; the summary row is "Пакет Atlas". The user's choices
### are "настройки", the app's Settings page "параметры". A control the text tells
### people to choose is quoted with its exact label: нажмите «Повторить попытку»; a
### quote inside a label uses „…“. Update stages are "этап", the flow's steps "шаг".
### - Plurals use one, few, many and other; "other" (fractions) takes the genitive
###   singular, as in "1,5 минуты".
### - Install steps: Подготовка, Ваш выбор, Безопасность Windows, Установка.
###   ISO steps: Windows, Настройка, Создание. Windows' own installer is
###   "программа установки Windows".
### - A USB drive is "USB-накопитель", as File Explorer names an unlabelled one.
### - Windows versions: "Windows 11, версия 26H2" in titles, "Windows 11 версии 26H2"
###   in running text.
### - The four protection switch names are feminine (Защита от подделки…), so words
###   that agree with $switches are feminine.
### - First-person rows avoid the gendered past tense («Я подтверждаю…», «Когда я…»).
### - Lists of names that sit after a verb or preposition follow a colon, so they
###   stay in the nominative: «Изменить: { $title }».

## Shared

app-name = Atlas Manager
common-done = Готово
common-cancel = Отмена
common-back = Назад
common-next = Далее
common-dismiss = Закрыть
# Link beside a summary row that jumps back to change that choice.
common-change = Изменить
common-copy = Копировать
# Shown where a list of options is empty.
common-none = Нет
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = На главную
# Accessible name of the gear button in the title bar.
common-settings = Параметры
common-close-settings = Закрыть параметры
common-open-windows-security = Открыть «Безопасность Windows»
common-restart-as-administrator = Перезапустить от имени администратора
common-try-again = Повторить попытку
common-read-the-docs = Открыть руководство Atlas
common-show-details = Показать подробности
common-hide-details = Скрыть подробности
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Открыть папку журналов
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Копировать журнал установки
common-install-log = Журнал установки
# Row labels in summary cards.
common-windows = Windows
common-package = Пакет Atlas
common-checking = Проверка
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } или { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } и { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Закрыть окно, пока идёт установка?
window-close-installing = Установка продолжится. Чтобы увидеть результат, снова откройте Atlas.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = Установка продолжится, но ПК не перезагрузится автоматически. Чтобы увидеть результат, снова откройте Atlas.
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = Не закрывать
window-close-close = Закрыть окно
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Остановить до начала установки?
window-close-checks-unchanged = Установка пока ничего не изменила. Если закрыть окно, она не начнётся.
window-close-keep-installing = Продолжить установку
window-close-stop-and-close = Остановить и закрыть
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = Остановить обновление?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas остановится после текущего этапа. Затем его можно будет закрыть.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = Перезагрузить ПК, чтобы завершить настройку Atlas?
window-close-restart-closed = После закрытия Atlas не сможет перезагрузить ПК. Сначала сохраните работу.
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = Перезагрузить ПК, чтобы завершить обновление?
window-close-update-restart-later = Сначала сохраните работу. Если перезагрузить ПК позже, Atlas продолжит после перезагрузки.
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = Закрыть Atlas с отключённой защитой?
window-close-protection-all = Четыре переключателя защиты в приложении «Безопасность Windows» отключены. Если вы не устанавливаете Atlas сейчас, сначала снова включите их.
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are. The switch names are feminine.
window-close-protection-some = { $count ->
    [one] { $switches } отключена в приложении «Безопасность Windows». Если вы не устанавливаете Atlas сейчас, сначала снова включите её.
   *[other] { $switches } отключены в приложении «Безопасность Windows». Если вы не устанавливаете Atlas сейчас, сначала снова включите их.
}
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = Остановить создание ISO-образа?
iso-close-safe-point = Atlas остановится в ближайший безопасный момент.
usb-close-question = Остановить создание USB-накопителя?
usb-close-unfinished = С незавершённого накопителя нельзя установить Windows.
window-close-keep-creating = Продолжить создание
window-close-stop = Остановить
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Открыть пакет Atlas (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas установлен. Windows перезагружается, чтобы завершить настройку.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas перезагружает Windows, чтобы завершить установку обновлений.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (сборка { $build })

## Home page

home-not-installed = Добро пожаловать в Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". All three
# values are text.
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas снижает фоновую активность и число отвлекающих факторов в Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas на этом ПК
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = Установлено { $date }
home-status-checking = Проверка обновлений…
# While startup checks whether another window's installation is running.
home-status-recovering = Поиск выполняющейся установки
home-status-offline = Не удалось проверить обновления
home-status-not-checked = Обновления ещё не проверялись
home-status-update = Доступен Atlas { $version }
home-status-up-to-date = Установлена последняя версия
home-status-newest = Последняя версия: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Установка Atlas { $version } не завершена
home-check-again = Проверить снова
# Primary button while an install is running or waiting.
home-show-install = Показать ход установки
home-continue-installing = Продолжить настройку
home-update-to = Обновить до Atlas { $version }
home-reinstall = Переустановить Atlas
home-install = Установить Atlas
home-finish-install = Завершить установку Atlas { $version }
home-start-over = Начать заново
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = Установить Atlas на этот ПК?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = Имеющиеся приложения и параметры могут перестать работать, а Atlas удалит OneDrive, поэтому файлы в нём перестанут синхронизироваться и папки могут выглядеть пустыми. Сначала создайте резервную копию файлов.
home-used-windows-install = Всё равно установить
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Переустановить Windows с Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Windows на этом ПК уже использовалась, а Atlas лучше всего работает на чистой установке.
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = ПК нужно перезагрузить
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas не удалось перезагрузить ПК. Перезагрузите его через меню «Пуск».
home-security-reminder-title = Снова включите защиту
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Убедитесь, что защита включена
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names. The
# switch names are feminine.
security-switches-still-off =
    { $count ->
        [one] В приложении «Безопасность Windows» по-прежнему отключена: { $switches }.
        [few] В приложении «Безопасность Windows» по-прежнему отключены: { $switches }.
        [many] В приложении «Безопасность Windows» по-прежнему отключены: { $switches }.
       *[other] В приложении «Безопасность Windows» по-прежнему отключены: { $switches }.
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas не удалось проверить все переключатели защиты. Убедитесь, что в приложении «Безопасность Windows» включены: { $switches }.
home-elevation-title = Для установки Atlas нужны права администратора
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas не удалось сохранить выбранные настройки, поэтому приложение не перезапущено.
home-state-error-title = Не удалось прочитать сведения об установке Atlas
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = Версия Atlas, выбранные настройки и история установок могут отображаться неправильно.
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager нужно обновить
home-whats-new = Что нового в Atlas { $version }
home-view-release = Открыть заметки о выпуске на GitHub
home-show-less = Свернуть
home-show-full-notes = Показать все заметки о выпуске
home-your-install = Ваша установка Atlas
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = На этом ПК нет записи о том, как был установлен Atlas, поэтому нельзя показать выбранные настройки и историю установок.
home-history = История установок
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Шаг { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = Что произойдёт
# Instead of home-steps-title while a setup is under way: each step shows whether it's done,
# current or still to come.
home-steps-under-way-title = Идёт настройка Atlas
# Beside step-ready in that card. The home-step-* sentences are in the present tense because they
# also show beside finished steps while a setup is under way.
home-step-ready = Atlas проверяет ПК и обновляет Windows.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas проверяет ПК и переводит Windows на версию { $release }.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Вы выбираете, что оставить, например Microsoft Defender.
# Beside step-security in that card.
home-step-security = Вы отключаете четыре переключателя защиты в приложении «Безопасность Windows».
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it. "около" takes the
# genitive: около 1 минуты, около 3 минут, около 1,5 минуты.
home-step-install-restarts =
    { $minutes ->
        [one] Установка обычно занимает около { $minutes } минуты, затем ПК перезагрузится.
        [few] Установка обычно занимает около { $minutes } минут, затем ПК перезагрузится.
        [many] Установка обычно занимает около { $minutes } минут, затем ПК перезагрузится.
       *[other] Установка обычно занимает около { $minutes } минуты, затем ПК перезагрузится.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] Установка обычно занимает около { $minutes } минуты, затем перезагрузите ПК.
        [few] Установка обычно занимает около { $minutes } минут, затем перезагрузите ПК.
        [many] Установка обычно занимает около { $minutes } минут, затем перезагрузите ПК.
       *[other] Установка обычно занимает около { $minutes } минуты, затем перезагрузите ПК.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Сначала сохраните работу: приложения могут закрыться, а ПК перезагрузится.
home-github = Открыть Atlas на GitHub
home-discord = Сообщество Atlas в Discord
home-report-problem = Сообщить о проблеме

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = первая установка
history-mode-upgrade = обновление
history-mode-reapply = переустановка
history-mode-unknown = установка

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas использует параметры приложения по умолчанию
notice-settings-unreadable-problem = Atlas не удалось прочитать сохранённые параметры приложения. Параметры Windows не изменились.
notice-settings-damaged-kept-problem = Файл параметров приложения был повреждён, поэтому Atlas сбросил его и сохранил копию старого файла.
notice-settings-damaged-problem = Файл параметров приложения был повреждён. Пока Atlas использует параметры по умолчанию.
notice-settings-not-saved-title = Не удалось сохранить параметры приложения
notice-settings-not-saved-problem = Atlas не удалось сохранить последние изменения, поэтому они могут быть потеряны при закрытии Atlas. Если открыто другое окно Atlas, закройте его, затем внесите изменение снова.
notice-session-unreadable-title = Не удалось проверить предыдущую установку
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas не удалось определить, выполняется ли ещё предыдущая установка. Если вы уверены, что она не выполняется, удалите запись об установке и перезапустите Atlas.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas не удалось определить, выполняется ли ещё предыдущая установка. Если вы не уверены, обратитесь за помощью к сообществу Atlas. Только если вы уверены, что установка не выполняется, удалите { $path } и повторите попытку. Подробности: { $error }

## Administrator elevation

elevation-declined = Разрешение не получено. Повторите попытку и нажмите «Да», когда Windows спросит, разрешить ли Atlas вносить изменения.
elevation-declined-continue = Разрешение не получено. Повторите попытку и нажмите «Да», когда Windows спросит, разрешить ли Atlas вносить изменения. Выбранные вами настройки сохранены.
elevation-draft-not-saved = Atlas не удалось сохранить выбранные настройки, поэтому приложение не было перезапущено. Повторите попытку. Подробности: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Эта настройка теперь продолжается в другом окне Atlas, поэтому Atlas не был перезапущен. Продолжите в том окне или нажмите «Начать заново», чтобы снова пройти настройку здесь.

## The install flow

step-ready = Подготовка
step-options = Ваш выбор
step-security = Безопасность Windows
step-install = Установка
install-title = Настройка Atlas
# Accessible name of the row of steps.
stepper-label = Шаги настройки Atlas
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = завершён
stepper-status-current = текущий шаг
stepper-status-upcoming = предстоящий шаг
# A step already visited whose requirements aren't met yet.
stepper-status-attention = требует внимания
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = Шаг { $number } из { $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }. { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = Проверка ПК
# Status line while the checks run.
ready-checks-running = Идёт проверка ПК…
ready-check-again = Проверить снова
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [one] Пройдена { $count } проверка
        [few] Пройдены { $count } проверки
        [many] Пройдено { $count } проверок
       *[other] Пройдено { $count } проверки
    }
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
# "из N" takes the genitive: из 1 проверки, из 8 проверок.
ready-checks-passed-some =
    { $total ->
        [one] Пройдено { $passed } из { $total } проверки
        [few] Пройдено { $passed } из { $total } проверок
        [many] Пройдено { $passed } из { $total } проверок
       *[other] Пройдено { $passed } из { $total } проверки
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of. The verb agrees with $count, as in check-state-updates.
ready-checks-handled =
    { $count ->
        [one] { $count } устранится при обновлении
        [few] { $count } устранятся при обновлении
        [many] { $count } устранятся при обновлении
       *[other] { $count } устранятся при обновлении
    }
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = устранится при обновлении
# Under the title of a check that updating takes care of.
check-updates-handled = Есть ожидающие обновления. Atlas установит их при обновлении Windows.
check-restart-handled = Windows требуется перезагрузка, чтобы завершить предыдущие изменения. Она будет выполнена при обновлении.
check-handled = Это будет устранено при обновлении.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Скачивание…
ready-package-unpacking = Распаковка…
ready-package-ready = Готово
ready-package-checking = Поиск последней версии…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Подготовка встроенного пакета Atlas…
ready-package-none = Ещё не скачан
ready-package-failed = Не удалось получить пакет Atlas
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = Скачайте его снова или откройте другой пакет Atlas (.atlaspkg).
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = Не удалось распаковать пакет Atlas, встроенный в эту тестовую сборку. Повторите попытку.
ready-package-manager = Нужна более новая версия Atlas Manager
ready-package-release-failed = Не удалось проверить наличие последней версии
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Проверьте подключение к интернету и повторите попытку. Если у вас есть пакет Atlas (.atlaspkg), можно открыть его.
# Row title.
ready-updates-title = Обновления Windows и Microsoft Store
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Приложения Store, например Блокнот, могут закрыться во время обновления. Сначала сохраните в них работу.
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Начнётся после перехода Windows на версию { $release }.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Продолжение после перезагрузки…
ready-updates-restarting = Перезагрузка ПК…
ready-updates-done = Windows и приложения Store обновлены.
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows обновлена.
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] ПК перезагрузится через { $seconds } секунду.
        [few] ПК перезагрузится через { $seconds } секунды.
        [many] ПК перезагрузится через { $seconds } секунд.
       *[other] ПК перезагрузится через { $seconds } секунды.
    }
ready-updates-restart = Чтобы завершить обновление, нужно перезагрузить ПК.
ready-updates-restart-finish = Чтобы завершить установку версии { $release }, Windows требуется ещё одна перезагрузка.
ready-updates-restart-failed = ПК не перезагрузился
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Сначала сохраните работу.
ready-updates-restart-persists = Windows по-прежнему требует перезагрузки
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Повторная перезагрузка вряд ли поможет. Завершите всё, что ожидает в Центре обновления Windows, затем повторите попытку.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Причины перезагрузки: { $reasons }
ready-updates-network = Для обновлений нельзя использовать это подключение
ready-updates-stopped = Обновление остановлено. Некоторые обновления уже могли быть установлены.
ready-updates-previous = Ожидание обновлений, запущенных ранее…
# Button after the user stopped updating.
ready-updates-resume = Возобновить обновление
ready-updates-start = Начать обновление
# Why updating hasn't started, under the row.
ready-updates-blocked = Обновление начнётся, когда Atlas можно будет установить на этот ПК.
ready-updates-needs-admin = Начнётся, когда у Atlas будут права администратора.
ready-updates-needs-windows = Начнётся после прохождения проверки «Совместимость с Windows».
ready-updates-needs-drivers = Начнётся, когда вы выберете способ установки драйверов.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = Драйверы: { $choice }
ready-drivers-automatic = Через Центр обновления Windows
ready-drivers-manual = Самостоятельная установка
ready-drivers-change-a11y = Изменить способ установки драйверов
# Under the two answers, once updating has run.
ready-drivers-again = Если изменить этот вариант, обновление запустится снова.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Скачивание Atlas { $version } · { $received } из { $total } МБ
package-unpacking = Распаковка
package-status-ready = Готово
# Accessible name of the progress bar.
package-progress = Ход подготовки пакета Atlas
package-download-again = Скачать снова
package-download-version = Скачать Atlas { $version }
package-download-newest = Скачать последнюю версию
package-cancel-download = Отменить скачивание
package-open-file = Открыть файл пакета
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } скачан с GitHub и готов к установке.
package-from-file = Atlas { $version } загружен из { $file } и готов к установке.
package-unpacked = Atlas { $version } готов к установке.
package-none-yet = Пакета Atlas пока нет
acquire-no-asset = Для Atlas { $version } нет файла пакета для скачивания. Чтобы продолжить, откройте сохранённый пакет Atlas (.atlaspkg).
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Это приложение устанавливает Atlas 0.6.0 и новее из пакетов Atlas (.atlaspkg).
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = В Atlas { $version } отсутствуют файлы, которые нужны этому приложению для установки. Скачайте его снова или откройте другой пакет Atlas (.atlaspkg).
acquire-failed = Не удалось подготовить пакет Atlas. Скачайте его снова или откройте другой пакет Atlas (.atlaspkg). Подробности: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Скачивание остановлено, так как данные перестали поступать. Проверьте подключение к интернету, затем скачайте снова или откройте сохранённый пакет Atlas (.atlaspkg).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Не удалось подготовить встроенный пакет Atlas. Нажмите «Повторить попытку». Подробности: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now; «её … вместо этой» follows
# manager-update-message.
acquire-manager-update-needed = Для этого пакета Atlas нужна более новая версия Atlas Manager. Скачайте Atlas Manager версии { $version } или новее и используйте её вместо этой.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Для этого пакета Atlas нужна более новая версия Atlas Manager. Скачайте последнюю версию Atlas Manager и используйте её вместо этой.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = Чтобы установить Atlas { $version }, скачайте Atlas Manager версии { $required } или новее и используйте её вместо этой.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Чтобы установить Atlas { $version }, скачайте последнюю версию Atlas Manager и используйте её вместо этой.

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Скачать Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Доступен Atlas Manager { $version }
manager-update-message = Atlas Manager не может обновиться сам. Скачайте новую версию и используйте её вместо этой.

## System checks

check-administrator = Разрешение на установку
check-supported-build = Совместимость с Windows
check-pending-updates = Обновления Windows
check-pending-reboot = Перезагрузка Windows
check-third-party-antivirus = Другие антивирусы
check-internet = Подключение к интернету
check-power = Питание
check-activation = Активация Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Оборудование для Windows 11
check-move-space = Свободное место
check-move-update-source = Источник обновлений
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = проверяется
check-state-passed = пройдено
check-state-warning = требует внимания
check-state-failed-blocking = требуется действие перед установкой
check-state-failed = требует внимания
check-state-unknown = не удалось проверить
check-fix-windows-update = Открыть Центр обновления Windows
check-fix-network = Открыть параметры сети
check-fix-power = Открыть параметры питания
check-fix-activation = Открыть параметры активации
# Opens Storage in Windows Settings, where space is freed up ("Память" in Russian Windows).
check-fix-storage = Открыть параметры памяти
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed.
check-fix-installed-apps = Открыть «Установленные приложения»
# Check box the user ticks when the Windows Update scan could not run. Written
# without a gendered past tense so it reads the same for everyone.
check-ack-updates = Центр обновления Windows проверен: обновлений, ожидающих установки, нет

detail-admin-ok = У Atlas есть разрешение вносить изменения, необходимые для установки.
detail-admin-missing = Перезапустите Atlas от имени администратора и нажмите «Да», когда Windows запросит разрешение.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Этой версии Atlas нужна сборка Windows { $builds }. На этом ПК сборка { $build }. Прежде чем продолжить, установите поддерживаемую версию Windows.
detail-build-missing = В этом пакете Atlas не указаны поддерживаемые сборки Windows. Используйте полную сборку пакета вместо сборки LocalTest.
detail-updates-none = Обновлений Windows, ожидающих установки, нет.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [1] Ещё { $count } обновление ожидает установки. Установите его в Центре обновления Windows, затем проверьте снова.
        [one] Ещё { $count } обновление ожидает установки. Установите их в Центре обновления Windows, затем проверьте снова.
        [few] Ещё { $count } обновления ожидают установки. Установите их в Центре обновления Windows, затем проверьте снова.
        [many] Ещё { $count } обновлений ожидают установки. Установите их в Центре обновления Windows, затем проверьте снова.
       *[other] Ещё { $count } обновления ожидают установки. Установите их в Центре обновления Windows, затем проверьте снова.
    }
detail-updates-scan-failed = Не удалось проверить обновления Windows. Откройте Центр обновления Windows, чтобы узнать, есть ли ожидающие обновления. ({ $error })
detail-reboot-none = Сейчас Windows не требует перезагрузки.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows требуется перезагрузка, чтобы завершить предыдущие изменения. Перезагрузите ПК, затем проверьте снова.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows требуется перезагрузка, чтобы завершить предыдущие изменения ({ $reasons }). Перезагрузите ПК, затем проверьте снова.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Можно продолжить. При следующей перезагрузке Windows заменит или удалит файлы ({ $files }). Некоторые приложения, например Xbox Gaming Services, запрашивают это после каждой перезагрузки.
detail-reboot-unknown = Не удалось проверить, нужна ли Windows перезагрузка. Перезагрузите ПК, затем снова откройте Atlas и повторите проверку. ({ $error })
detail-antivirus-none = Других антивирусов не обнаружено.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Антивирусы, кроме Microsoft Defender, могут блокировать установку. Удалите { $products }, затем проверьте снова.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = «Безопасность Windows» всё ещё показывает { $products }, но файлов этой программы больше нет, то есть она уже не установлена. Atlas всё равно можно установить.
detail-antivirus-check-failed = Не удалось проверить наличие других антивирусов. Если ошибка повторяется, перезагрузите ПК и проверьте снова. ({ $error })
detail-internet-ok = Подключение есть. Не отключайтесь от интернета, пока Atlas скачивает и устанавливает программы.
detail-internet-missing = Подключитесь к интернету, затем проверьте снова.
detail-power-mains = ПК подключён к электросети. Не отключайте его от сети до завершения установки.
detail-power-battery = Подключите ПК к электросети, чтобы он не выключился во время установки.
detail-power-check-failed = Atlas не удалось определить, подключён ли ПК к электросети. Если у вас ноутбук, подключите его, затем проверьте снова.
detail-activation-ok = Windows активирована. Atlas это не изменит.
detail-activation-missing = Windows не активирована. Можно продолжить, но Atlas не активирует Windows.
detail-activation-no-licence = Windows не сообщила о лицензии. Можно продолжить; Atlas не меняет состояние активации.
detail-activation-unknown = Не удалось проверить активацию Windows. Можно продолжить; Atlas не меняет состояние активации. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi,
# in the nominative, so it follows "не поддерживает".
detail-move-not-needed = На этом ПК Atlas не нужно переводить Windows на более новую версию.
detail-move-hardware-ready = На этом ПК есть TPM 2.0 и встроенное ПО UEFI, необходимые для Windows 11.
detail-move-hardware-missing = Этот ПК не поддерживает { $missing }, поэтому Центр обновления Windows не переведёт его на версию { $release }. Создайте резервную копию файлов и переустановите Windows с помощью ISO-образа с Atlas.
detail-move-hardware-unread = Atlas не удалось проверить всё оборудование этого ПК, поэтому его проверит Центр обновления Windows.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = На диске { $drive } свободно { $free } ГБ.
detail-move-space-short = Для версии { $release } нужно { $needed } ГБ свободного места на диске { $drive }, а свободно { $free } ГБ. Освободите место, и Atlas сам проверит снова.
detail-move-space-unknown = Не удалось проверить свободное место для обновления Windows. Перезагрузите ПК, затем проверьте снова. ({ $error })
detail-move-update-source-ok = Этот ПК получает обновления из Центра обновления Windows.
detail-move-update-source-managed = Этот ПК получает обновления с сервера организации, который не предлагает версию { $release }. Обратитесь в организацию или переустановите Windows с помощью ISO-образа с Atlas.

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Параметры Microsoft Defender, защиты процессора и обновлений можно позже изменить в папке Atlas на рабочем столе.
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = Ничего не выбрано
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = Выбрано: { $count }
# Links that unfold and fold the Optional extras card.
options-extras-show = Показать
options-extras-hide = Скрыть
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender — встроенный антивирус Windows.
question-mitigations-description = Эти средства защиты, которые также называют мерами по снижению рисков, противостоят уязвимостям процессора, например Spectre и Meltdown, и атакам, использующим ошибки в приложениях.
question-auto-updates-description = В любом случае Atlas оставит Windows на текущей версии и отключит автоматическое обновление приложений Microsoft Store.
question-browser-description = Atlas не будет менять настройки браузера.
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = ПК останется без антивируса, пока вы не установите другой, а Windows перестанет предупреждать вас перед открытием неопознанных приложений и скачанных файлов.
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = Также отключается защита от эксплойтов для приложений, например защита потока управления (CFG), что снижает безопасность.
cost-auto-updates-disable = Регулярно открывайте Центр обновления Windows, чтобы получать исправления безопасности.
cost-auto-updates-default = Windows может перезагружать ПК, чтобы завершить установку обновлений.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift и Ctrl+Shift больше не будут переключать языки и раскладки.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Освобождает место на диске, но гибернация и быстрый запуск станут недоступны.
extra-disable-power-saving = ПК может потреблять больше энергии, сильнее нагреваться и быстрее разряжать батарею.
extra-disable-core-isolation = Это снижает защиту, включая целостность памяти, и может повлиять на приложения и игры, которым она нужна.
extra-uninstall-edge = Закладки, история просмотров и сохранённые пароли Edge на этом ПК будут удалены, кроме синхронизированных с учётной записью Майкрософт.
extra-install-toolbox = Помогает управлять параметрами Atlas; в бета-версии некоторые функции могут быть не доработаны.
extra-install-eclean = Инструмент от команды AtlasOS для просмотра ненужных файлов и приложений автозагрузки. Нужны учётная запись и подключение к интернету.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Оставить Microsoft Defender?
screen-mitigations-title = Защита процессора
screen-mitigations-question = Оставить защиту процессора, встроенную в Windows?
screen-updates-title = Центр обновления Windows
screen-updates-question = Как Windows должна устанавливать обновления?
screen-browser-title = Браузер
screen-power-title = Питание и безопасность
screen-apps-title = Приложения
screen-optional-apps-title = Дополнительные приложения
screen-choose-one-title = Выберите вариант
screen-extras-title = Необязательные дополнения
# Each decision's short name in the middle of a sentence, as in summary-change-a11y and
# update-path-differs. Lower case except product names; nominative, as the sentences put
# them after a colon.
screen-update-path-name = способ обновления Atlas
screen-defender-name = Microsoft Defender
screen-mitigations-name = защита процессора
screen-updates-name = Центр обновления Windows
screen-keyboard-name = языки клавиатуры
screen-browser-name = браузер
screen-power-name = питание и безопасность
screen-apps-name = приложения
screen-optional-apps-name = дополнительные приложения
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = настройка из пакета Atlas
screen-extras-name = необязательные дополнения
# Question for a required choice this app has no specific wording for.
screen-generic-question = Выберите вариант: { $title }
learn-more-defender = Подробнее о Microsoft Defender
learn-more-mitigations = Подробнее о защите процессора
learn-more-updates = Подробнее о Центре обновления Windows
learn-more-browser = Подробнее о браузерах
learn-more-power = Подробнее о питании и безопасности
learn-more-apps = Подробнее о приложениях
learn-more-eclean = Подробнее об eclean
learn-more-keyboard = Подробнее о языках клавиатуры
learn-more-generic = Открыть руководство по настройке
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Оставляет встроенный антивирус Windows, который помогает защитить ПК от вирусов и других угроз.
consequence-mitigations-default = Сохраняет стандартную защиту Windows от уязвимостей процессора и от атак, использующих ошибки в приложениях.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = Также отключает защиту от эксплойтов для приложений, например защиту потока управления (CFG). Это снижает безопасность. Разница в производительности зависит от процессора.
consequence-auto-updates-disable = Регулярно открывайте Центр обновления Windows, чтобы устанавливать обновления. Уведомления об обновлениях останутся включёнными.
consequence-auto-updates-default = Windows будет устанавливать обновления автоматически, включая исправления безопасности.

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Как вы хотите обновиться до Atlas { $version }?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Как вы хотите переустановить Atlas { $version }?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = Оставить мои настройки
update-path-keep-detail = Atlas оставит все настройки такими, какие они сейчас на этом ПК, и ничего в них не изменит.
update-path-choose = Выбрать заново
update-path-choose-detail = Начните с текущих настроек этого ПК. Ваши приложения, файлы и персонализация сохранятся.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Ваши текущие настройки на этом ПК
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = Atlas не может определить это по ПК, поэтому спросит вас
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = Состояние этого ПК не совпадает с записью Atlas: { $choices }.
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Остальные настройки останутся такими, какие они сейчас на этом ПК.
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = Сейчас на этом ПК
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas вернёт Microsoft Defender. После перезагрузки включите его защиту в приложении «Безопасность Windows».
change-mitigations-default = Atlas снова включит защиту процессора со стандартными параметрами Windows. Изменение вступит в силу после перезагрузки.
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = Сейчас включены все средства защиты процессора. Если оставить защиту, все они останутся включёнными.
change-auto-updates-default = Atlas снова позволит Windows устанавливать обновления автоматически.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas снова включит гибернацию.
change-power-saving-on = Atlas снова включит энергосбережение и вернёт прежнюю схему электропитания, а если её нет — схему «Сбалансированная».
change-core-isolation-on = Atlas снова включит безопасность на основе виртуализации (VBS), если ею не управляет политика на этом ПК. Изменение вступит в силу после перезагрузки.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Удаляет приложение «Ножницы» для всех пользователей этого ПК. Atlas не сможет вернуть его позже, но его можно снова установить из Microsoft Store.
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge уже удалён, и обновление Atlas не может его вернуть. Чтобы установить его снова, запустите «Install or Remove Edge» в папке Atlas.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = Приложение { $app } установлено. Atlas не удаляет приложения; чтобы удалить его, откройте «Параметры» > «Приложения» > «Установленные приложения».
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = Браузер { $installed } останется установленным, и Atlas также установит { $browser }.

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Оставить Microsoft Defender (рекомендуется)
package-option-defender-enable-short = Оставить Microsoft Defender
package-option-defender-disable = Удалить Microsoft Defender
package-option-mitigations-default = Оставить защиту процессора (рекомендуется)
package-option-mitigations-default-short = Оставить защиту процессора
package-option-mitigations-disable = Отключить защиту процессора
package-option-auto-updates-disable = Устанавливать обновления самостоятельно
package-option-auto-updates-default = Устанавливать обновления автоматически
package-option-disable-hibernation = Отключить гибернацию
package-option-disable-power-saving = Отключить энергосбережение
package-option-disable-core-isolation = Отключить безопасность на основе виртуализации (VBS)
package-option-remove-snipping-tool = Удалить приложение «Ножницы»
package-option-uninstall-edge = Удалить Microsoft Edge
package-option-install-another-browser = Установить браузер
package-option-install-toolbox = Установить Atlas Toolbox
package-option-install-eclean = Установить eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender — встроенный антивирус Windows. Удаляйте его, только если понимаете риски и собираетесь использовать другой антивирус. При любом выборе Atlas отключает функции «Интеллектуальное управление приложениями», «Расширенная защита от фишинга» и «Поиск устройства».
package-choice-mitigations-description = Эти средства защиты, которые также называют мерами по снижению рисков, помогают защититься от уязвимостей процессора, например Spectre и Meltdown, и от атак, использующих ошибки в приложениях. Рекомендуется оставить стандартные параметры Windows.
package-choice-auto-updates-description = Обновления Windows включают исправления безопасности. Windows может устанавливать их автоматически, или вы можете устанавливать их самостоятельно. В обоих случаях Atlas оставляет Windows на текущей версии, которая получает исправления безопасности, только пока Microsoft её поддерживает. Atlas также отключает автоматическое обновление приложений Microsoft Store, поэтому обновляйте их в Microsoft Store.
package-choice-browser-description = Выберите браузер для установки. Atlas не будет менять настройки браузера.

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender не установлен на этом ПК
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Переключателей защиты, которые нужно отключить, нет.
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas удалил Microsoft Defender с этого ПК
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas вернёт Microsoft Defender при этой установке
security-restore-nothing-to-turn-off = Defender ещё не запущен, поэтому отключать ничего не нужно. После перезагрузки включите его защиту в приложении «Безопасность Windows».
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = Microsoft Defender отсутствует
security-banner-missing-message = Atlas не удалял его, поэтому не может его вернуть. Можно продолжить, но ПК останется без антивируса, пока вы не установите другой антивирус или не восстановите Windows.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = Отключите эти четыре переключателя
security-turn-off-message = Microsoft Defender может блокировать Atlas во время установки. Если вы оставите Defender, после установки снова включите их.
# The page name in Windows Security.
security-list-title = Параметры защиты от вирусов и других угроз
security-switch-off = Откл.
security-switch-on = Вкл.
security-switch-unreadable = Не удалось прочитать
security-switch-reading = Проверка
security-all-off = Все отключены
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on =
    { $count ->
        [one] { $count } ещё включён
        [few] { $count } ещё включены
        [many] { $count } ещё включены
       *[other] { $count } ещё включены
    }
security-count-unreadable = { $count } не удалось прочитать
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. The
# names follow a colon, so they stay in the nominative.
security-unread-switches-title =
    { $count ->
        [one] Atlas не удалось прочитать переключатель: { $switches }
        [few] Atlas не удалось прочитать переключатели: { $switches }
        [many] Atlas не удалось прочитать переключатели: { $switches }
       *[other] Atlas не удалось прочитать переключатели: { $switches }
    }
security-unread-message =
    { $count ->
        [one] Убедитесь, что этот переключатель отключён в приложении «Безопасность Windows».
       *[other] Убедитесь, что эти переключатели отключены в приложении «Безопасность Windows».
    }
# The check box under security-unread-message. First person without a gendered past tense;
# the switch names are feminine.
security-unread-confirm =
    { $count ->
        [one] Я подтверждаю, что { $switches } отключена
       *[other] Я подтверждаю, что { $switches } отключены
    }
# The check box when Atlas couldn't read any of the four switches. Written without a
# gendered past tense.
security-acknowledge = «Безопасность Windows» проверена: все четыре переключателя отключены
security-unknown-unelevated-title = Для проверки защиты Atlas нужны права администратора
security-unknown-unelevated-message = Перезапустите Atlas от имени администратора, чтобы он мог прочитать параметры Microsoft Defender.
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = Защита от подделки
protection-tamper-why = Чтобы Atlas мог изменить параметры безопасности.
protection-realtime = Защита в режиме реального времени
protection-realtime-reason = Проверки могут заблокировать файлы Atlas.
protection-cloud = Облачная защита
protection-cloud-reason = Онлайн-проверки могут заблокировать файлы Atlas.
protection-samples = Автоматическая отправка образцов
protection-samples-why = Чтобы файлы Atlas не отправлялись в Microsoft.

## Step 4: Install

outcome-succeeded-title = Atlas установлен
outcome-lost-title = Не удалось подтвердить результат установки
outcome-failed-title = Установка не завершена
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = ПК не соответствует требованиям установки, поэтому установка ничего не изменила.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = ПК не соответствует требованиям установки, поэтому эта попытка остановлена. Предыдущая попытка уже внесла изменения.
# Beside common-restart-as-administrator.
result-not-elevated = У Atlas не было прав администратора, поэтому установка ничего не изменила.
result-not-elevated-resumed = У Atlas не было прав администратора, поэтому эта попытка остановлена. Предыдущая попытка уже внесла изменения.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas не удалось подтвердить, что Windows и приложения Store обновлены, поэтому установка остановлена до внесения изменений в Windows.
result-preparation-stale-resumed = Atlas не удалось подтвердить, что Windows и приложения Store обновлены, поэтому эта попытка остановлена. Предыдущая попытка уже внесла изменения.
result-failed-preflight = Установка остановилась, ничего не изменив. Можно повторить попытку.
result-failed-staging = Установка остановилась при подготовке файлов, до внесения изменений в Windows. Можно повторить попытку.
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = Часть изменений уже могла быть внесена. Можно повторить попытку, а если вы решите остановиться, снова включите переключатели защиты в приложении «Безопасность Windows».
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = Часть изменений уже могла быть внесена. Можно повторить попытку.
result-failed-resumed = Эта попытка рано прервалась, но предыдущая уже внесла изменения. Можно повторить попытку, а если вы решите остановиться, снова включите переключатели защиты в приложении «Безопасность Windows».
result-failed-resumed-defender-removed = Эта попытка рано прервалась, но предыдущая уже внесла изменения. Можно повторить попытку.
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = Эта попытка прервалась с той же ошибкой, что и предыдущая, поэтому повтор вряд ли поможет. Отправьте отчёт, чтобы команда Atlas нашла причину, а если вы решите остановиться, снова включите переключатели защиты.
result-failed-repeated-defender-removed = Эта попытка прервалась с той же ошибкой, что и предыдущая, поэтому повтор вряд ли поможет. Отправьте отчёт, чтобы команда Atlas нашла причину.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows по-прежнему не удаётся удалить { $apps }, поэтому повтор вряд ли поможет. Отправьте отчёт, чтобы команда Atlas нашла причину, а если вы решите остановиться, снова включите переключатели защиты.
result-failed-repeated-apps-defender-removed = Windows по-прежнему не удаётся удалить { $apps }, поэтому повтор вряд ли поможет. Отправьте отчёт, чтобы команда Atlas нашла причину.
result-not-started = Установщик не запустился вовремя, поэтому установка ничего не изменила. Можно повторить попытку.
result-lost = Установщик остановился, не сообщив о результате, поэтому часть изменений могла быть внесена. Можно повторить попытку, а если вы решите остановиться, снова включите переключатели защиты в приложении «Безопасность Windows».
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = Установщик остановился, не сообщив о результате, поэтому часть изменений могла быть внесена. Можно повторить попытку.
restart-now-message = Windows перезагружается, чтобы завершить настройку Atlas.
restart-stopped = Автоматическая перезагрузка отменена. Сохраните работу, затем перезагрузите ПК, чтобы завершить настройку Atlas.
restart-needed = Сохраните работу, затем перезагрузите ПК, чтобы завершить настройку Atlas.
restart-dont-now = Перезагрузить позже
restart-now = Перезагрузить сейчас
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = Установка не началась
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# защита процессора; it follows a colon, so it stays in the nominative.
preflight-choice-unanswered = Atlas нужен ваш выбор: { $choice }.
preflight-choices-unusable = Atlas не удалось использовать эти настройки.
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
        [one] С момента проверки ПК внимания требует: { $checks }.
       *[other] С момента проверки ПК внимания требуют: { $checks }.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = После отключения переключателей в приложении «Безопасность Windows» произошли изменения: { $summary }.
preflight-busy-wait = Другое окно Atlas уже запускает установку. Подождите немного и повторите попытку.
# Beside home-start-over.
preflight-taken-over-start-over = Эта настройка теперь продолжается в другом окне Atlas. Продолжите там или начните заново здесь.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas не удалось проверить, выполняется ли ещё предыдущая установка, поэтому новая не запущена.
preflight-not-started = Atlas не удалось запустить установщик, поэтому установка ничего не изменила. Можно повторить попытку.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas не удалось запустить установщик, но предыдущая попытка уже внесла изменения. Можно повторить попытку.
go-to-ready = Перейти к шагу «Подготовка»
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Перейти к шагу «Ваш выбор»
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Перейти к шагу «Безопасность Windows»
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Вернуться к шагу «Установка»
output-problem-title = Не удалось прочитать ход установки
install-elevate-title = Для установки Atlas нужны права администратора
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Когда Atlas перезапустится, Windows запросит разрешение.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Пакет Atlas не готов
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Сначала завершите шаг «Подготовка»
install-not-ready-message = Прежде чем начать установку, Atlas должен завершить проверку ПК и обновление Windows.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = Снова отключите переключатели защиты
install-switches-message = Безопасность Windows: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Всё готово к установке
summary-setup-title = Ваша установка Atlas
summary-activation = Активация
summary-activation-ok = Активирована. Atlas это не изменит.
summary-activation-missing = Не активирована. Можно продолжить, но Atlas не активирует Windows.
summary-activation-unknown = Atlas не меняет состояние активации Windows.
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't. "около" takes the genitive:
# около 1 минуты, около 3 минут.
summary-time-restarts =
    { $minutes ->
        [one] Обычно около { $minutes } минуты, затем ПК перезагрузится
        [few] Обычно около { $minutes } минут, затем ПК перезагрузится
        [many] Обычно около { $minutes } минут, затем ПК перезагрузится
       *[other] Обычно около { $minutes } минуты, затем ПК перезагрузится
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Обычно около { $minutes } минуты, затем перезагрузите ПК
        [few] Обычно около { $minutes } минут, затем перезагрузите ПК
        [many] Обычно около { $minutes } минут, затем перезагрузите ПК
       *[other] Обычно около { $minutes } минуты, затем перезагрузите ПК
    }
# The check box on the card. It's the same setting as settings-restart-automatically.
summary-restart-automatically = Автоматически перезагрузить ПК после установки
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Также отключаются
summary-turned-off-value = «Интеллектуальное управление приложениями», «Расширенная защита от фишинга» и «Поиск устройства»
summary-show-command = Показать команду установки
summary-hide-command = Скрыть команду установки
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Копировать команду установки
summary-command-unavailable = Не удалось подготовить команду установки. Подробности: { $error }
summary-not-chosen = Пока не выбрано
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = Изменить: { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Способ обновления
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = Подготовка к установке
footer-checks-blocked = Чтобы продолжить, устраните найденные проблемы
footer-manager-outdated = Чтобы продолжить, скачайте новую версию Atlas Manager
footer-need-files = Чтобы продолжить, получите пакет Atlas
# Tester build variant of footer-need-files.
footer-need-package-bundled = Чтобы продолжить, подготовьте встроенный пакет Atlas
footer-drivers = Чтобы продолжить, выберите способ установки драйверов
footer-windows-terms = Чтобы продолжить, примите условия лицензии
footer-updating = Обновление Windows и приложений Store…
footer-restart = Чтобы продолжить, перезагрузите ПК
footer-reading-security = Проверка переключателей защиты
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = Чтобы продолжить, отключите все четыре переключателя
footer-security-confirm = Чтобы продолжить, подтвердите состояние непроверенных переключателей
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = Сначала сохраните работу и закройте приложения
button-install = Установить Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } предыдущая строка находится в файле журнала.
        [few] { $count } предыдущие строки находятся в файле журнала.
        [many] { $count } предыдущих строк находятся в файле журнала.
       *[other] { $count } предыдущих строк находятся в файле журнала.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (полный журнал: { $path })

## The installing view

installing-title = Установка Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = Проверка ПК…
installing-staging-label = Копирование файлов Atlas…
installing-applying-label = Настройка Windows…
installing-finishing-label = Завершение…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Не выключайте ПК и не отключайте его от сети. После установки он перезагрузится автоматически.
installing-keep-on = Не выключайте ПК и не отключайте его от сети. После установки перезагрузите его.
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = Это не значит, что установка остановилась.
installing-installed-title = Atlas установлен
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown =
    { $seconds ->
        [one] ПК перезагрузится через { $seconds } секунду.
        [few] ПК перезагрузится через { $seconds } секунды.
        [many] ПК перезагрузится через { $seconds } секунд.
       *[other] ПК перезагрузится через { $seconds } секунды.
    }
installing-restart-save = Сначала сохраните работу.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } установлен
installed-title = Atlas установлен
installed-ready = Всё настроено. ПК готов к работе с Atlas.
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = Загрузите драйверы чипсета, сети и графики у производителя ПК, системной платы или устройства.
installed-drivers-guide = Открыть руководство по драйверам
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender удалён
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas его не удалял. Если другой антивирус не установлен, установите его, чтобы защитить ПК.
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender всё ещё удалён
defender-not-restored-message = Предыдущее обновление Atlas не вернуло его, поэтому Defender не защищает ПК. Переустановите Atlas, оставив Defender, или запустите «Toggle Defender» в папке Atlas: «7. Security» > «Defender».
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = Некоторые настройки не применились
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [one] Эта настройка осталась прежней: { $choices }.
        [few] Эти настройки остались прежними: { $choices }.
        [many] Эти настройки остались прежними: { $choices }.
       *[other] Эти настройки остались прежними: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Центр обновления Windows снова отключён, как вы выбрали
installed-update-off-message = Пока он отключён, ПК не получает обновления безопасности.
installed-update-paused-title = Обновления Windows снова приостановлены, как вы выбрали
installed-update-paused-message = Пока они приостановлены, ПК не получает обновления безопасности.

## Settings

settings-title = Параметры
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = Внешний вид
settings-installation = Установка
settings-privacy = Конфиденциальность
settings-theme = Тема приложения
settings-theme-system = Как в Windows
settings-theme-light = Светлая
settings-theme-dark = Тёмная
settings-theme-contrast-note = Atlas использует цвета контрастной темы Windows.
settings-language = Язык
# The setting in the Language section, and its box's name.
settings-app-language = Язык приложения
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Как в Windows — { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = Предварительный перевод
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = Этот перевод ещё не проверен носителем языка.
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } — предварительный перевод, в нём могут быть ошибки.
preview-notice-switch = Переключиться на английский
preview-notice-language = Изменить язык
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = Выбранного языка нет в этой версии Atlas, поэтому используется английский. Ваш выбор сохранён.
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas пока не поддерживает язык интерфейса Windows, поэтому используется английский.
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas не удалось определить язык интерфейса Windows, поэтому используется английский.
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = Числа, даты и время отображаются в региональном формате Windows: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Числа отображаются в региональном формате Windows: { $locale }. Даты и время показываются в стандартном формате, так как Atlas пока не может отображать текст справа налево.
settings-language-contribute = Помочь с переводом Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Отправлять Atlas данные об использовании
settings-share-usage-description = Открытые страницы, создание ISO-образов и успешность установок.
settings-privacy-policy = Политика конфиденциальности
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = Автоматически перезагружать ПК после установки и обновлений
settings-restart-automatically-description = ПК перезагрузится в течение минуты после завершения установки или обновления, а открытые приложения закроются.
settings-restart-locked = Это можно изменить после завершения установки.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Помощь
settings-about = О приложении
settings-about-app = Atlas Manager
settings-about-licence = Лицензия
settings-about-licence-value = GPL-3.0, свободное ПО с открытым исходным кодом
settings-view-source = Открыть исходный код на GitHub
# Link that opens the third-party licence notices.
settings-view-licences = Открыть сведения о лицензиях
# Under the links when Windows could not open the notices.
settings-licences-failed = Не удалось открыть сведения о лицензиях. Повторите попытку или найдите их в исходном коде на GitHub.
settings-open-data-folder = Открыть папку приложения

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Освобождает место на диске, которое используется для сохранения сеанса при гибернации. Гибернация и быстрый запуск станут недоступны.
consequence-disable-power-saving = Отключает функции энергосбережения. ПК может потреблять больше энергии, сильнее нагреваться и быстрее разряжать батарею.
consequence-disable-core-isolation = Отключает дополнительный уровень защиты Windows, включая целостность памяти. Это снижает защиту и может повлиять на приложения и игры, которым она нужна.
consequence-remove-snipping-tool = Удаляет приложение Windows для снимков и записи экрана.
consequence-uninstall-edge = Удаляет браузер Microsoft Edge. Убедитесь, что у вас есть другой браузер, или выберите его ниже.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Удаляет закладки, историю просмотров и сохранённые пароли Edge на этом ПК.
consequence-install-another-browser = Выберите браузер ниже, и Atlas установит его.
consequence-install-toolbox = Atlas Toolbox помогает управлять параметрами Atlas. Это бета-версия, поэтому некоторые функции могут быть не доработаны.
consequence-install-eclean = Инструмент обслуживания от команды AtlasOS, который помогает поддерживать порядок на ПК после настройки. Просматривайте ненужные файлы и приложения автозагрузки. Требуется учётная запись и подключение к интернету.

## ISO creation
iso-open = Создать ISO с Atlas
iso-title = Создать ISO с Atlas
iso-recommended = Рекомендуется
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Настройка
iso-step-create = Создание
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = Для какого ПК этот ISO-образ?
iso-target-this = Этот ПК
iso-target-another = Другой ПК
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = Этот ISO-образ — для ПК с архитектурой { $architecture }.
iso-source = ISO-образ Windows
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Скачать с сайта Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Скачивание Windows
iso-download-language = Язык
iso-download-arch = Архитектура
iso-download-languages = Загрузка списка языков…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Скачивание Windows 11…
iso-download-amount = { $received } из { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas не удалось подключиться к службе загрузки Microsoft. Проверьте подключение к интернету и повторите попытку.
iso-download-incomplete = Скачивание не завершено. Проверьте подключение к интернету и свободное место, затем повторите попытку.
iso-download-website = Перейти на страницу загрузки Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = Выбрать ISO-файл
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Проверка ISO-образа Windows…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = ISO-образ Windows готов, { $facts }
iso-package-latest-label = Последняя версия
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = Последний выпуск Atlas слишком старый для этой версии Atlas Manager.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Получение последней версии Atlas…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas не удалось проверить наличие последней версии. Проверьте подключение к интернету и повторите попытку.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Чтобы продолжить, получите ISO-образ Windows
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Когда вы хотите выбрать настройки Atlas?
iso-mode-after = После входа
iso-mode-after-description = После входа в систему Atlas проведёт вас через настройку.
iso-mode-now = Сейчас
iso-mode-now-description = Настройки сохранятся в ISO-образе. Установить Atlas нужно будет после входа.
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = Завершить до открытия рабочего стола
iso-mode-before-desktop-description = После входа Atlas будет работать в полноэкранном режиме до завершения установки.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Этот пакет Atlas не может сохранить настройки в ISO-образе, поэтому их нужно будет выбрать после входа.
iso-atlas-options = Настройки Atlas
# The line at the top of the Create step.
iso-create-intro = Создание ISO-образа не изменяет этот ПК и исходный ISO-образ.
iso-review-package = Пакет Atlas
iso-review-output = Новый ISO-образ
iso-review-edition = Редакция
iso-review-editions = Редакции
iso-edition = Редакция Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Выбор при установке
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Выбрать при установке
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Принять условия лицензии Windows, чтобы программа установки их не запрашивала
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } МБ
size-gigabytes = { $size } ГБ
iso-review-account = Имя учётной записи
# The row's value is iso-target-this or iso-target-another.
iso-review-target = Целевой ПК
iso-review-drivers = Драйверы
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Программа установки Windows
iso-review-skips = Пропускает экраны учётной записи Майкрософт и конфиденциальности
iso-review-skips-terms = Пропускает экраны лицензии, учётной записи Майкрософт и конфиденциальности
iso-review-network = Сетевые драйверы
iso-review-network-included = Драйверы Wi-Fi и Ethernet этого ПК
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Сейчас, с завершением до открытия рабочего стола
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = Нужно { $needed } · свободно { $free } на диске { $drive }
iso-destination-short = Для ISO-образа нужно { $needed }, а на диске { $drive } свободно { $free }. Освободите место или сохраните ISO-образ на другой диск.
iso-destination-filesystem = На диске { $drive } нельзя хранить большие файлы ISO-образа. Сохраните его на диск с файловой системой NTFS, например на диск с Windows.
iso-destination-unusable = Atlas может сохранить ISO-образ только в папку на диске этого ПК.
iso-create = Создать ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = Создание ISO-образа…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Чтение ISO-образа Windows
iso-stage-copy = Копирование файлов Windows
iso-stage-add-atlas = Добавление Atlas
iso-stage-master = Запись файла ISO
iso-stage-verify = Проверка нового ISO-образа
iso-stage-cleanup = Завершение
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = выполняется
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = ошибка
iso-stage-status-not-started = не начат
iso-progress-keep-open = Не закрывайте Atlas до завершения.
iso-cancel = Отменить создание
iso-cancelling = Ожидание безопасной остановки
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Отмена…
iso-cancelled = Создание ISO отменено
iso-cancelled-unchanged = Исходный ISO-образ не изменён.
iso-complete = ISO-образ готов
iso-complete-backup = Перед переустановкой Windows с этого образа создайте резервную копию файлов.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Создать USB-накопитель
iso-open-folder = Показать в папке
iso-failed = Не удалось завершить создание ISO
# Under iso-failed, beside Try again.
iso-failed-retry = Убедитесь, что файлы по-прежнему находятся там, где вы их выбрали, а диск для сохранения подключён, затем повторите попытку.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Не удалось проверить файлы
iso-check-failed-retry = Убедитесь, что ISO-образ и пакет Atlas полностью скачаны, затем повторите попытку.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas не удалось подготовить рабочую папку, поэтому ничего не изменилось.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = В этом ISO-образе нет редакций, которые поддерживает Atlas
iso-edition-unsupported = Windows Home и LTSC не поддерживаются. Используйте ISO-образ с редакцией Pro, Education или Enterprise.
iso-customised-title = Этот ISO-образ изменён
iso-customised = В нём уже есть файлы настройки установки, например autounattend.xml. Используйте неизменённый ISO-образ от Microsoft.
iso-preview-title = Этот ISO-образ — предварительная сборка
iso-preview = Его сборки Windows нет в списке общедоступных выпусков Microsoft. Используйте ISO-образ от Microsoft.
iso-windows-unsupported-title = Этот ISO-образ не подходит для этого пакета Atlas
iso-windows-unsupported = Используйте неизменённый ISO-образ Windows 11 той версии, которую поддерживает пакет.
iso-release-unknown-title = Atlas не удалось подтвердить этот выпуск Windows
iso-release-unconfirmed = Atlas сверяет его со списком общедоступных выпусков Microsoft. Проверьте подключение к интернету и повторите попытку.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = С этим пакетом Atlas нельзя создать ISO-образ
iso-package-old = Используйте Atlas { $minimum } или новее.
iso-manager-missing-title = Файл Atlas Manager не найден
iso-fix-package = Выбрать другой пакет
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager нужно обновить
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas не удалось добавить сетевые драйверы этого ПК в ISO-образ.
iso-network-skip = Создать без них
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Для создания ISO нужны права администратора
iso-admin-reason = Они нужны, чтобы прочитать ISO-образ Windows и создать новый.
iso-elevation-declined = Windows не предоставила Atlas разрешение, поэтому он пока не может прочитать ISO-образ Windows.
# The free space ran out while the ISO was being created.
iso-failed-space = На целевом диске недостаточно свободного места. Освободите место или сохраните новый ISO-образ на другом диске.
# Under iso-manager-missing-title.
iso-manager-missing = Скачайте AtlasManager.exe в локальную папку, например «Загрузки», и запустите его оттуда.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Этот ISO-образ не содержит поддерживаемых редакций Windows. Редакции Windows Home и LTSC не поддерживаются. Используйте ISO-образ с другой редакцией, например Pro, Education или Enterprise.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Открыть папку журналов
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas сейчас работает с Центром обновления Windows. Продолжить здесь можно будет после завершения.
# Names of the markers Windows sets when it wants a restart. They complete
# "ПК нужно перезагрузить, чтобы завершить установку обновлений (…)"; keep them short and
# lower case where the language allows.
prepare-reason-servicing = обслуживание Windows
prepare-reason-windows-update = Центр обновления Windows
prepare-reason-file-renames = ожидающие замены файлы
prepare-reason-update-agent = служба Центра обновления Windows
prepare-reason-unknown = причина не указана
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Если повторная попытка не поможет, завершите оставшиеся обновления в Центре обновления Windows или Microsoft Store.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Не удалось завершить некоторые обновления
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Обновление остановилось, не сообщив о результате.
# Title of the bar over prepare-ended-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = Не удалось подтвердить результат обновления
prepare-affected-app = приложение, вызвавшее ошибку
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Закройте { $app } и повторите попытку. Если не удаётся его найти, закройте его в диспетчере задач.
prepare-install-busy = Обновлению мешает другая установка или необходимость перезагрузки. Дождитесь завершения других установок, перезагрузите ПК, если Windows попросит об этом, затем повторите попытку.
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows не удалось выполнить восстановление
prepare-components-damaged = Windows сообщает о повреждении, которое мешает установке обновлений. Перезагрузка может это исправить, а Atlas продолжит после входа в систему.
prepare-restart-and-retry = Перезагрузить и повторить
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows слишком повреждена для обновления
prepare-components-unrepairable = Создайте резервную копию файлов и переустановите Windows с помощью ISO-образа с Atlas.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas запущен от имени учётной записи, отличной от той, под которой выполнен вход в Windows. Войдите в Windows с учётной записью администратора, запустите в ней Atlas и повторите попытку.
prepare-failed-store-missing = Microsoft Store не настроен для вашей учётной записи. Откройте Microsoft Store хотя бы раз или переустановите его, если он отсутствует, затем повторите попытку.
prepare-failed-store-battery = Microsoft Store приостановил обновления для экономии заряда батареи. Подключите ПК к электросети и повторите попытку.
prepare-failed-store-network = Microsoft Store приостановил обновления до появления нелимитного подключения. Подключитесь к нелимитной сети Wi-Fi или Ethernet и повторите попытку.
prepare-failed-store-timeout = Приложения Store ещё не обновились. Завершите оставшиеся загрузки в Microsoft Store и повторите попытку.
prepare-failed-store-passes = Microsoft Store продолжал предлагать новые обновления. Установите оставшиеся обновления в Microsoft Store и повторите попытку.
prepare-failed-manual-updates = Установку некоторых обновлений Windows нужно завершить в Центре обновления Windows. Откройте Центр обновления Windows, завершите установку и повторите попытку.
prepare-failed-windows-passes = Центр обновления Windows продолжал предлагать новые обновления. Установите оставшиеся обновления в Центре обновления Windows и повторите попытку.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-iso-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager находится в связанной папке. Закройте Atlas, переместите Atlas Manager в локальную папку на этом ПК, затем откройте его оттуда.
prepare-error-code = Код ошибки: { $code }
prepare-open-store = Открыть Microsoft Store
prepare-windows-search = Проверка обновлений Windows…
prepare-percent = { $percent }% этого этапа
prepare-count = Завершено обновлений: { $completed } из { $total }
prepare-bytes = Загружено { $downloaded } из примерно { $total } МБ
prepare-progress-still = Ход выполнения не менялся { $minutes } мин. Крупные обновления могут занять время, поэтому не закрывайте Atlas.
prepare-report-late = Windows давно не сообщает о ходе выполнения. Обновления могут ещё выполняться, поэтому не закрывайте Atlas.
prepare-windows-download = Загрузка обновлений Windows…
prepare-windows-install = Установка обновлений Windows…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Восстановление Windows…
prepare-windows-repair-detail = Windows сообщает о повреждении, которое может помешать установке обновлений. Это может занять полчаса или больше.
prepare-store-search = Проверка Microsoft Store…
prepare-store-install = Обновление Microsoft Store и приложений…
prepare-stop = Остановить обновление
prepare-start = Найти и установить обновления
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Станет доступно, когда пакет Atlas будет готов.
iso-username = Имя локальной учётной записи
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Пароль нужно будет задать при первом входе.
iso-username-placeholder = Ваше имя
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Чтобы продолжить, введите имя локальной учётной записи
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Используйте не более 20 символов, без пробела в начале и в конце и без этих символов: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Имя не может заканчиваться точкой.
iso-account-reserved = Windows использует это имя для встроенной учётной записи. Выберите другое имя.
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Программа установки Windows предложит принять условия лицензии.
prepare-drivers = Как устанавливать драйверы?
prepare-drivers-auto = Получать драйверы через Центр обновления Windows
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Получать драйверы через Центр обновления Windows (рекомендуется)
prepare-drivers-auto-detail = Windows найдёт драйверы для вашего оборудования.
prepare-drivers-manual = Устанавливать драйверы самостоятельно
prepare-drivers-manual-detail = Центр обновления Windows не будет устанавливать драйверы, поэтому их придётся скачивать с сайта производителя ПК или устройства. Уже установленные драйверы сохранятся.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Драйверы
iso-network-drivers = Добавить драйверы Wi-Fi и Ethernet этого ПК
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Выбрать после входа
prepare-network-unmetered = Для обновлений нужно нелимитное подключение к интернету. Подключитесь к Wi-Fi или Ethernet и повторите попытку.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows сообщает, что у этой сети нет доступа к интернету. Выполните вход в сеть, если она этого требует, или проверьте маршрутизатор и фильтрацию на уровне DNS или брандмауэра, затем повторите попытку.
# "Лимитное подключение" is the switch's name in Windows network settings.
prepare-network-metered = Это подключение лимитное, или для него установлен лимит трафика. Подключитесь к нелимитной сети или отключите «Лимитное подключение» в параметрах сети, затем повторите попытку.
prepare-network-settings = Открыть параметры сети
iso-stage-network-drivers = Подготовка сетевых драйверов
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Сетевые адаптеры этого ПК используют драйверы, входящие в состав Windows, поэтому добавлять их в ISO не нужно.
desktop-setup-description = Завершите настройку ПК. Настройки Atlas сохранены; при необходимости можно вернуться в Windows.
desktop-setup-exit = Продолжить в Windows

# Windows installation USB
usb-title = Создать USB-накопитель
usb-existing = Создать USB-накопитель из готового ISO-образа
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB-накопитель
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = ISO-образ Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = В папке «Загрузки» нет ISO-образа с Atlas.
usb-iso-checking = Проверка ISO-образа…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas не может создать USB-накопитель из этого ISO-образа. Используйте ISO-образ, созданный в Atlas, или ISO-образ от Microsoft с версией Windows 11, которую поддерживает Atlas.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO-образ или Atlas Manager находится в сетевом расположении или в связанной папке. Переместите его в папку на этом ПК, например «Загрузки».
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = На диске с Windows недостаточно места для подготовки этого ISO-образа. Освободите место, и Atlas сам проверит снова.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas не удалось прочитать этот ISO-образ. Повторите попытку или используйте другой ISO-образ.
# Opens the Storage page of Windows Settings, where space can be freed ("Память").
usb-open-storage = Открыть параметры памяти
usb-looking = Поиск USB-накопителей…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Подключите USB-накопитель объёмом не менее { $size } ГБ.
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = Слишком мал. Нужно не менее { $size } ГБ.
usb-drive-too-small-iso = Слишком мал для этого ISO-образа
usb-drive-has-iso = На этом накопителе ваш ISO-образ
usb-drive-has-app = Atlas Manager запущен с этого накопителя
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } ГБ
usb-drive-size-tb = { $size } ТБ
# Joins a drive's size and its letters, an ISO's architecture and size under its name, and
# ready-checks-passed-some and ready-checks-handled on Get ready.
usb-detail-separator = { " · " }
usb-create = Создать USB-накопитель
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = Сначала выберите USB-накопитель
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = Стереть накопитель { $drive } ({ $size }, { $letters })?
usb-confirm-title = Стереть накопитель { $drive } ({ $size })?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Стереть USB-накопитель ({ $size }, { $letters })?
usb-confirm-title-unnamed = Стереть USB-накопитель ({ $size })?
usb-confirm-message = Всё содержимое накопителя будет удалено. Ваш ISO-образ сохранится.
usb-confirm-erase = Стереть и создать
usb-progress-title = Создание USB-накопителя…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Подготовка файлов
usb-stage-formatting = Форматирование
usb-stage-copying = Копирование файлов
usb-stage-checking = Проверка накопителя
usb-stage-ejecting = Извлечение
usb-keep-open = Не закрывайте Atlas и не отключайте накопитель.
usb-scan-failed-title = Не удалось получить список USB-накопителей
usb-scan-failed-retry = Atlas не удалось прочитать список накопителей, подключённых к этому ПК. Повторите попытку.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Не удалось создать USB-накопитель
usb-complete-title = USB-накопитель готов
# F12, F11 and Esc are key names.
usb-ready = Отключите его, создайте резервную копию файлов на ПК, который будете переустанавливать, и загрузите тот ПК с USB-накопителя. Меню загрузки часто открывается клавишей F12, F11 или Esc.
# After erasing may have begun.
usb-failed-partial = Накопитель записан частично. Убедитесь, что он подключён, и повторите попытку.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas остановился, не изменив накопитель. Повторите попытку.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = USB-накопитель изменился
usb-drive-changed = Его извлекли или подключили заново до того, как Atlas его стёр, поэтому на нём ничего не изменилось.
usb-drive-cancelled-title = Создание USB-накопителя отменено
usb-cancelled-partial = Накопитель создан не полностью. Перед использованием создайте его заново.
usb-cancelled-unchanged = USB-накопитель не был изменён.
usb-eject-failed-title = USB-накопитель не извлечён
usb-eject-failed-ready = Он готов к использованию. Закройте файлы и окна, которые его используют, и повторите попытку.
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = Для создания USB-накопителя нужны права администратора
usb-admin-reason = Права администратора нужны, чтобы стереть накопитель и записать на него файлы.
usb-elevation-declined = Windows не предоставила Atlas разрешение, поэтому он пока не может записать USB-накопитель.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Редакции Windows 11 Home, LTSC и Server не поддерживаются. Используйте другую редакцию, например Pro, Education или Enterprise. Если Windows не удалось определить редакцию, устраните эту проблему перед продолжением.
install-source-title = Установка недоступна
install-source-unsupported = Atlas { $source } нельзя обновить напрямую до { $target }. Чтобы использовать эту версию, создайте резервную копию файлов и переустановите Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } нельзя обновить напрямую. Чтобы использовать более новую версию, создайте резервную копию файлов и переустановите Windows.
# $folder is a folder path (text).
install-source-resume-package = Установка Atlas { $target } не завершена, и завершить её можно только с помощью пакета Atlas { $target }. Откройте этот пакет Atlas (.atlaspkg). Если его скачал Atlas, он находится в папке { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Установка Atlas { $target } не была завершена. Эта тестовая сборка может установить только встроенный пакет Atlas, поэтому завершите установку с помощью пакета Atlas { $target } в релизной сборке Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas не удалось определить, что уже установлено на этом ПК, поэтому пока он ничего не будет устанавливать.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = В программе установки Windows выберите редакцию, на которую у вас есть лицензия.
detail-windows-preview = Сборки Insider не поддерживаются. Используйте общедоступную версию Windows 11.
detail-windows-release-unknown = Atlas не удалось подтвердить, что эта сборка Windows общедоступна. Подключитесь к интернету и повторите проверку.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Сборки { $build } нет в списке общедоступных выпусков Windows 11 от Microsoft, поэтому Atlas пока нельзя на неё установить. Сборки Release Preview и другие предварительные сборки не поддерживаются. Проверьте снова, когда Microsoft добавит эту сборку в список.

prepare-continue = Продолжить обновления
prepare-saving-restart = Сохранение настроек и подготовка к повторному открытию Atlas после перезагрузки Windows…
prepare-restart-save-failed = Не удалось сохранить настройки. Повторите попытку перед перезагрузкой.
prepare-restart-registration-failed = Настройки сохранены, но Atlas не удалось настроить автоматическое открытие после перезагрузки. Повторите попытку или перезагрузите ПК самостоятельно и откройте Atlas после входа в систему.
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = Настройки сохранены, но пока Atlas Manager находится в связанной папке, Atlas не может настроить автоматическое открытие после перезагрузки. Закройте Atlas и переместите Atlas Manager в локальную папку на этом ПК. Затем откройте его оттуда или перезагрузите ПК самостоятельно и откройте его оттуда после входа в систему.
prepare-restart-failed = Atlas не удалось перезагрузить ПК. Повторите попытку или перезагрузите ПК через меню «Пуск». Настройки сохранены, и Atlas снова откроется после входа в систему.
diagnostics-export = Экспорт диагностики
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Сбор диагностики…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Получить помощь
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Диагностика сохранена
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Сохранено как { $file } в папке { $folder } приложения Atlas.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas удалил из файла имя пользователя, имя ПК, адреса электронной почты и известные пароли или ключи.
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = Не удалось сохранить ZIP-архив с диагностикой

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Тестовая сборка Atlas { $release }. Это приложение устанавливает только встроенный пакет Atlas.
home-status-bundled = Тестовая сборка { $release }
package-bundled = Atlas { $version }, встроенный в эту тестовую сборку, готов к установке.
rc-about-release = Тестовая сборка
rc-about-commit = Исходный коммит
rc-about-package = Встроенный пакет Atlas (SHA-256)
iso-package-bundled = Пакет Atlas, встроенный в эту тестовую сборку

check-user-account = Учётная запись
detail-user-account-ok = Контроль учётных записей включён, и ваша учётная запись готова к установке.
detail-user-account-not-ready = Включите контроль учётных записей (UAC), перезагрузите ПК и повторите попытку. Если вы используете встроенную учётную запись Администратор, войдите под другой учётной записью администратора.
detail-user-account-work-or-school = Atlas нельзя установить под рабочей или учебной учётной записью (Microsoft Entra ID). Войдите под локальной учётной записью или учётной записью Майкрософт и повторите попытку.
detail-user-account-check-failed = Atlas не удалось проверить вашу учётную запись. Перезагрузите ПК, снова откройте Atlas и проверьте ещё раз. Сообщение Windows: { $error }

footer-prepare-required = Чтобы продолжить, завершите обновление Windows и приложений Store
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Остановка обновления после текущего этапа…
resume-choices-title = Продолжение предыдущей установки
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = Чтобы завершить ту установку, Atlas использует настройки, выбранные в прошлый раз, поэтому до её завершения их нельзя изменить.

## Voluntary reports
report-title = Отправить отчёт
report-received = Отчёт получен
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Сохраните этот номер, если будете обращаться к команде Atlas по поводу этого отчёта. Если вы оставили контактные данные, команда может ответить по ним, но ответ не гарантируется.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Копировать номер отчёта
report-another = Отправить ещё один отчёт
# Label of the choice between the two kinds of report.
report-kind = Что вы хотите отправить?
report-kind-issue = Сообщение о проблеме
report-kind-suggestion = Предложение
report-message = Ваше сообщение
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Что произошло и что вы делали в этот момент?
report-message-placeholder-suggestion = Что вы хотели бы изменить?
# Under the message box, which also reads it out.
report-message-help = Не указывайте пароли.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers. "из N" takes the genitive: из 1001 символа, из 2000 символов.
report-character-count =
    { $max ->
        [one] { $count } из { $max } символа
        [few] { $count } из { $max } символов
        [many] { $count } из { $max } символов
       *[other] { $count } из { $max } символа
    }
report-contact = Контактные данные (необязательно)
report-contact-placeholder = Электронная почта или имя пользователя Discord
report-attach = Приложить диагностику
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = Журналы и сведения о системе, которые помогают найти причину. Atlas удаляет имя пользователя, имя ПК, адреса электронной почты и известные пароли или ключи. Сведения об ошибках, модели оборудования и названия приложений сохраняются. Перед отправкой ZIP-архив можно проверить.
report-review = Проверить ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = Не удалось подготовить диагностику
report-prepare-failed-advice = Повторите попытку или отправьте отчёт без диагностики.
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = Отчёт конфиденциально передаётся команде Atlas на reports.atlasos.net. Сообщение и контактные данные отправляются в том виде, в каком вы их ввели. Чтобы разобраться в проблеме, команда может использовать ИИ-сервисы сторонних компаний. Они получают ваше сообщение и диагностику, но не контактные данные. Отчёты удаляются через 90 дней, а в журналах безопасности сервера может сохраняться ваш IP-адрес.
report-website = Конфиденциальность и сайт отчётов
report-consent = Я даю согласие на отправку этого отчёта и приложенной диагностики команде Atlas
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = Проверьте подключение к интернету и повторите попытку. Отчёт можно также отправить через сайт отчётов.
report-not-sent-busy = Служба отчётов занята. Подождите несколько минут и повторите попытку.
report-not-sent-outdated = Эта версия Atlas Manager не может отправлять отчёты. Скопируйте сообщение на сайт отчётов и приложите ZIP-архив, если добавляли диагностику.
report-not-sent-diagnostics = Не удалось отправить диагностику. Повторите попытку или отправьте отчёт без неё.
# The footer's button where this version can't send.
report-failed-website = Открыть сайт отчётов
# Beside a spinner in the footer while the report is on its way.
report-sending = Отправка…
report-send = Отправить отчёт

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = Введите от { $min } до { $max } символов.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = Укажите контактные данные длиной до { $max } символов.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Подтвердите согласие на отправку этого отчёта.

report-failed-title = Отчёт не отправлен

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# "Windows 11, версия 26H2" in titles, "Windows 11 версии 26H2" in running text.
# $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Ваши файлы и приложения сохранятся.
home-plan-name = Это обновление состоит из двух частей
home-plan-windows-title = Windows 11, версия { $release }
home-plan-windows-step = Atlas установит её через Центр обновления Windows, затем ПК перезагрузится.
# The same step where moving is optional.
home-plan-windows-step-ask = Необязательно. Atlas сначала спросит, затем установит её через Центр обновления Windows, и ПК перезагрузится.
# Instead of the step's own line, once Windows has moved. Agrees with "версия".
home-plan-step-installed = Установлена.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas обновится с сохранением ваших настроек, затем ПК перезагрузится.
# $date and $until are dates.
home-end-of-updates-title = Windows 11 версии { $current } перестанет получать обновления безопасности { $date }
home-end-of-updates-past-title = Windows 11 версии { $current } больше не получает обновления безопасности
home-end-of-updates-message = При обновлении до Atlas { $version } этот ПК также перейдёт на Windows 11 версии { $release }, которая будет получать обновления безопасности до { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11 версии { $release } будет получать обновления безопасности до { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } работает с Windows 11 Pro, Enterprise и Education, поэтому его нельзя установить на { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } работает с Windows 11 Pro, Enterprise и Education, поэтому его нельзя установить на { $product }. Windows 11 версии { $current } получает обновления безопасности до { $date }, а Центр обновления Windows может перевести этот ПК на более новую версию.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } работает с Windows 11 Pro, Enterprise и Education, поэтому его нельзя установить на { $product }. Версия { $current } больше не получает обновления безопасности, поэтому обновите Windows, даже если не будете устанавливать Atlas.
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Для Atlas { $version } нужна Windows 11 версии { $releases }, а Центр обновления Windows не может перевести на неё этот ПК. Создайте резервную копию файлов и переустановите Windows с помощью ISO-образа с Atlas.
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Для Atlas { $version } нужна Windows 11 версии { $releases }, а Центр обновления Windows не может перевести на неё этот ПК.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Параметры Центра обновления Windows изменены для обновления Atlas
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas вернёт эти параметры после завершения обновления.
# When the last check found no offer yet.
home-update-access-waiting = Atlas включил Центр обновления Windows, чтобы перевести этот ПК на Windows 11 версии { $release }, но Центр обновления Windows её ещё не предложил.
home-update-access-updating = Atlas включил Центр обновления Windows, чтобы установить обновления, и ещё не завершил их установку.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Не удалось прочитать запись Atlas о Центре обновления Windows
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas не удаётся прочитать собственную запись об изменённых им параметрах Центра обновления Windows, поэтому он ничего не будет ни менять, ни возвращать.
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas не удалось вернуть параметры.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = Сначала завершите установку Atlas. На её последнем этапе Atlas вернёт изменённые им параметры Центра обновления Windows.
home-continue-update = Продолжить обновление
home-put-back = Вернуть параметры
home-putting-back = Возврат параметров…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11, версия { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } не поддерживает версию { $current }, поэтому сначала Atlas обновит Windows.
# Under the title where moving is optional.
windows-optional = Atlas работает с обеими версиями.
# The choice's accessible name; the two answers say it.
windows-card-question = Какую версию Windows использовать на этом ПК?
windows-choice-move-recommended = Обновить до Windows 11 версии { $release } (рекомендуется)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Обновления безопасности до { $date }.
windows-choice-keep = Оставить Windows 11 версии { $current }
windows-choice-keep-later = ПК останется на версии { $current }. Перейти можно будет позже в Atlas Manager.
windows-card-facts = Что изменится
windows-fact-files = Ваши файлы и приложения сохранятся. Если обновление отменит какие-либо изменения, Atlas вернёт их.
windows-fact-time = Обычно несколько минут (до 2 часов), затем перезагрузка.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Удаляет Windows PowerShell 2.0 и WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Как отменить обновление
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Обновляя Windows, вы принимаете условия лицензии на программное обеспечение Microsoft.
windows-terms-link = Прочитать условия лицензии
windows-accept = Принять и обновить
# Once the terms are accepted, before the move starts by itself.
windows-starting = Запуск…
windows-starts-after-checks = Начнётся после прохождения проверок.
windows-starts-after-package = Начнётся, когда Atlas { $version } будет готов.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = Версия { $release } сбросила часть изменений Atlas. Atlas { $version } вернёт их с вашими прежними настройками.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Оставить Windows 11 версии { $current }?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas временно включит Центр обновления Windows
access-off = Центр обновления Windows на этом ПК отключён. Atlas снова включит его на время обновления Windows.
access-paused = Обновления Windows на этом ПК приостановлены. Atlas возобновит их на время обновления Windows.
access-delayed = Ежемесячные обновления на этом ПК отложены. Atlas отменит отсрочку на время обновления Windows.
# After the lines above.
access-back = После установки Atlas { $version } эти параметры вернутся в прежнее состояние.
access-back-stop = Если вы остановите обновление раньше, Atlas вернёт их.

prepare-reason-feature-update = новая версия Windows
prepare-reason-feature-commit = завершение установки новой версии Windows
prepare-reason-apprepository = удаление оставшихся записей приложений
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Ожидание, пока Центр обновления Windows предложит Windows 11 версии { $release }…
windows-waiting-detail = Обычно несколько минут (до 2 часов). Atlas продолжит сам, а ПК можно пока использовать.
windows-waited =
    { $minutes ->
        [one] Atlas ждёт уже { $minutes } минуту.
        [few] Atlas ждёт уже { $minutes } минуты.
        [many] Atlas ждёт уже { $minutes } минут.
       *[other] Atlas ждёт уже { $minutes } минуты.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Центр обновления Windows не предложил версию { $release } в течение 2 часов
windows-wait-ended = Atlas вернул параметры. Повторите попытку позже или переустановите Windows с помощью ISO-образа с Atlas.
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas не удалось вернуть параметры Центра обновления Windows.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows не удалось подготовиться к перезагрузке
windows-commit-failed = ПК не перезагрузился. Повторите попытку.

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Центр обновления Windows ещё не предложил версию { $release }
windows-outcome-not-offered = Это может занять до 2 часов. На ПК по-прежнему установлена версия { $current }.
windows-outcome-hardware-title = Этот ПК не соответствует требованиям Windows 11
# $missing lists the hardware this PC lacks, from the two messages below, in the nominative.
windows-outcome-hardware = Он не поддерживает { $missing }, поэтому Центр обновления Windows не предложит версию { $release }. Создайте резервную копию файлов и переустановите Windows с помощью ISO-образа с Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = встроенное ПО UEFI
windows-outcome-hidden-title = Версия { $release } скрыта в Центре обновления Windows
windows-outcome-hidden = Снова сделайте её видимой с помощью средства, которым вы её скрыли, и повторите попытку.
windows-outcome-disk-space-title = Недостаточно свободного места
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows нужно { $needed } ГБ свободного места на диске { $drive }, а свободно { $free } ГБ. Когда места станет достаточно, Atlas продолжит сам.
windows-outcome-managed-title = Этот ПК получает обновления от организации
windows-outcome-managed = Сервер обновлений организации не предлагает версию { $release }, поэтому Atlas ничего не изменил. Обратитесь в организацию или переустановите Windows с помощью ISO-образа с Atlas.
windows-outcome-policy-title = Что-то постоянно отменяет изменения в Центре обновления Windows
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = Параметр { $setting } возвращается к прежнему значению после изменения, поэтому Atlas не может обновить Windows. Если этим ПК управляет организация, обратитесь к ней.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Служба отключена: { $service }
windows-outcome-blocked-service = Она нужна Центру обновления Windows. Установите для неё тип запуска «Вручную» в оснастке «Службы» и повторите попытку.
windows-outcome-blocked-title = Что-то не даёт Центру обновления Windows работать
windows-outcome-blocked = Параметр { $setting }, который Atlas не изменял, не даёт ему работать. Измените его и повторите попытку.
windows-outcome-rollback-title = Windows не удалось завершить установку версии { $release }
windows-outcome-rolled-back = Система вернулась к версии { $current }. Ваши файлы и приложения не затронуты.
windows-outcome-components-lost-title = Часть изменений Atlas пропала
windows-outcome-components-lost = Atlas не может определить причину, поэтому остановился до установки Atlas { $version }.
windows-outcome-build-title = Версия Windows изменилась во время обновления
windows-outcome-build = Верните параметры, изменённые Atlas, и начните заново с главной страницы.
windows-outcome-journal-title = Atlas не удаётся прочитать свою запись об этом обновлении
windows-outcome-journal = Пока команда Atlas не разберётся, Atlas ничего не будет ни менять, ни возвращать.
windows-outcome-pin-title = Не удаётся сохранить политику Центра обновления Windows
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = У параметра { $setting } значение, которое Atlas не сможет потом вернуть, поэтому Atlas ничего не изменил.
windows-outcome-terms-title = Условия лицензии не приняты
windows-outcome-terms = Центр обновления Windows установит версию { $release } только после их принятия.
windows-outcome-failed-title = Windows не удалось установить версию { $release }
windows-outcome-failed = На ПК по-прежнему установлена версия { $current }.
# Windows services a move needs, as Services lists them.
service-bits = Фоновая интеллектуальная служба передачи (BITS)
service-cryptsvc = Службы криптографии
service-trusted-installer = Установщик модулей Windows
prepare-open-services = Открыть «Службы»
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Оставить версию { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Остановить обновление до Atlas { $version }?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Остановить обновление Windows?
stop-update-before = Atlas вернёт изменённые им параметры Центра обновления Windows. Уже установленные обновления Windows останутся, а на ПК сохранится Windows 11 версии { $current }.
stop-update-after = На ПК останется Windows 11 версии { $release }. Atlas вернёт изменённые им параметры Центра обновления Windows.
stop-update-access = Atlas вернёт изменённые им параметры Центра обновления Windows. Уже установленные обновления Windows останутся.
stop-update-keep = Не останавливать
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Закрыть Atlas?
window-close-update-access-message = Перед закрытием Atlas вернёт изменённые им параметры Центра обновления Windows. Начать обновление снова можно с главной страницы.
window-close-put-back = Вернуть и закрыть
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Закрыть, не вернув параметры?
window-close-put-back-failed-message = Если закрыть Atlas сейчас, параметры Центра обновления Windows останутся в том виде, в каком их изменил Atlas. Когда вы снова откроете Atlas, на главной странице будет предложено их вернуть.

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = Для этой версии Atlas нужна Windows 11 версии { $release }, а на этом ПК установлена версия { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Обновление Windows для Atlas не завершено. Подробности для команды Atlas:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = переустановка после обновления Windows
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Ваши настройки из Atlas { $previous }
rebase-choices-kept = Atlas вернёт настройки, выбранные вами для Atlas { $previous }. Изменить их можно позже, переустановив Atlas.
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas вернёт все остальные настройки, выбранные вами для Atlas { $previous }.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Перезагрузить, пока в системе работает другой пользователь?
restart-others-question = Перезагрузить, пока в системе работают другие пользователи?
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
# The names stand in apposition to «пользователь»/«пользователи», so they need no case
# ending, and the one-person branch avoids a gendered pronoun.
restart-others-signed-in =
    { $count ->
        [one] В системе также работает пользователь { $names }. Перезагрузка закроет приложения этого пользователя, и несохранённая работа будет потеряна.
        [few] В системе также работают пользователи { $names }. Перезагрузка закроет приложения этих пользователей, и несохранённая работа будет потеряна.
        [many] В системе также работают пользователи { $names }. Перезагрузка закроет приложения этих пользователей, и несохранённая работа будет потеряна.
       *[other] В системе также работают пользователи { $names }. Перезагрузка закроет приложения этих пользователей, и несохранённая работа будет потеряна.
    }
restart-others-keep = Не перезагружать
restart-others-restart = Всё равно перезагрузить
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Обновление Microsoft Store…
prepare-store-repairing = Исправление Microsoft Store…
prepare-store-repair-detail = Это может занять несколько минут.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = Microsoft Store на этом ПК отключён, поэтому приложения Store не обновлялись.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store не работает
prepare-store-broken = Atlas не удалось его исправить, а установка Atlas сейчас может нарушить работу приложений Store.
prepare-store-broken-iso = Если исправить его не удаётся, создайте резервную копию файлов и переустановите Windows с помощью ISO-образа с Atlas.
prepare-repair-store-again = Повторить исправление

screen-keyboard-title = Языки клавиатуры
screen-keyboard-question = Вы используете несколько языков клавиатуры?
package-option-keyboard-shortcuts = Да, переключаю сочетаниями клавиш
package-option-keyboard-selector = Да, выбираю язык на панели задач
package-option-keyboard-single = Нет, использую одну раскладку
consequence-keyboard-shortcuts = Alt+Shift переключает язык, Ctrl+Shift — раскладку.
consequence-keyboard-selector = Отключить Alt+Shift и Ctrl+Shift, чтобы избежать случайных переключений в играх.
package-choice-keyboard-description = Выберите способ переключения языка клавиатуры.
consequence-keyboard-single = { consequence-keyboard-selector }
