### Atlas Manager: Russian (ru). Preview translation, revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog: the reader is addressed as "вы" (lower case,
### as Windows does); the computer is "ПК"; buttons are short imperatives;
### "перезапустить" is the Atlas Manager relaunching, "перезагрузить" is the PC or
### Windows restarting. Windows feature names follow the Russian Windows UI.

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
# Accessible description of a disabled control.
common-not-available = Сейчас недоступно
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
common-open-log-file = Открыть файл журнала
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Копировать журнал установки
common-install-log = Журнал установки
# Row labels in summary cards.
common-windows = Windows
common-options = Выбранные настройки
common-package = Установочные файлы
common-installed-as = Тип установки
common-installed = Установлено
common-checking = Проверка
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } или { $b }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Закрыть окно, пока идёт установка?
window-close-message = Установка продолжится в фоновом режиме. Чтобы увидеть ход и результат, снова откройте Atlas. Не выключайте ПК до завершения установки.
window-close-keep = Не закрывать
window-close-close = Закрыть окно
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Открыть playbook Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas установлен. Windows перезагружается, чтобы завершить настройку.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (сборка { $build })

## Home page

home-not-installed = Добро пожаловать в Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Установлено { $date }
home-status-checking = Проверка обновлений
home-status-offline = Не удалось проверить обновления
home-status-not-checked = Обновления ещё не проверялись
home-status-update = Доступен Atlas { $version }
home-status-up-to-date = Установлена последняя версия
home-status-newest = Последняя версия: Atlas { $version }
home-check-again = Проверить снова
# Primary button while an install is running or waiting.
home-show-install = Показать ход установки
home-continue-installing = Продолжить настройку
home-update-to = Обновить до Atlas { $version }
home-reinstall = Переустановить Atlas
home-install = Установить Atlas
home-start-over = Начать заново
home-security-reminder-title = Снова включите защиту
home-security-reminder-message = Установка не выполняется. Откройте «Безопасность Windows» и включите защиту от подделки, защиту в режиме реального времени, облачную защиту и автоматическую отправку образцов.
home-elevation-title = Для установки Atlas нужны права администратора
home-state-error-title = Не удалось прочитать сведения об установке Atlas
home-whats-new = Что нового в Atlas { $version }
home-view-release = Открыть заметки о выпуске на GitHub
home-released = Дата выпуска: { $date }
home-show-less = Свернуть
home-show-full-notes = Показать все заметки о выпуске
home-your-install = Ваша установка Atlas
# Row label: how Atlas was set up.
home-set-up = Способ настройки
home-set-up-during-oobe = При первоначальной настройке Windows
home-history = История установок
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Подготовим ПК к установке Atlas
home-step-1-title = Проверка ПК
home-step-1-detail = Atlas проверит Windows и скачает установочные файлы. Параметры Windows при этом не изменятся.
home-step-2-title = Настройка под себя
home-step-2-detail = Вы выберете, как Windows будет защищать ПК и устанавливать обновления, а также дополнительные приложения и настройки.
home-step-3-title = Временное отключение антивирусной защиты
home-step-3-detail = Atlas поможет отключить четыре переключателя в приложении «Безопасность Windows», чтобы они не мешали установке.
home-step-4-title = Установка и перезагрузка
home-step-4-detail =
    { $minutes ->
        [one] Около { $minutes } минуты.
        [few] Около { $minutes } минут.
        [many] Около { $minutes } минут.
       *[other] Около { $minutes } минуты.
    }
# Accessible name of a numbered step.
home-step-a11y = Шаг { $number }: { $title }
home-github = Открыть Atlas на GitHub
home-discord = Сообщество Atlas в Discord
home-report-problem = Сообщить о проблеме на GitHub

## How an install was done (from the state document)

mode-fresh = Первая установка
mode-upgrade = Обновление с предыдущей версии
mode-reapply = Переустановка той же версии
mode-unknown = Установка
# Lower-case forms used inside a history row.
history-mode-fresh = первая установка
history-mode-upgrade = обновление
history-mode-reapply = переустановка
history-mode-unknown = установка

## Notices on the Home page

notice-settings-reset-title = Atlas использует параметры приложения по умолчанию
# $error is a raw error message (text).
notice-settings-unreadable = Atlas не удалось прочитать сохранённые параметры приложения. Параметры Windows не изменились. Подробности: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = Файл параметров приложения был повреждён и сброшен. Копия старого файла сохранена как { $file }. Подробности: { $error }
notice-settings-damaged = Файл параметров приложения был повреждён. Пока Atlas использует параметры по умолчанию. Подробности: { $error }
notice-settings-not-saved-title = Не удалось сохранить параметры приложения
notice-session-unreadable-title = Не удалось проверить предыдущую установку
# $path is a file path (text).
notice-session-unreadable-message = Atlas не может прочитать { $path }, а без этого не знает, выполняется ли ещё установка. Если вы не уверены, обратитесь за помощью к сообществу Atlas, прежде чем удалять этот файл. Удаляйте его и повторяйте попытку, только если убедились, что установка не выполняется. Подробности: { $error }

## Administrator elevation

elevation-declined = Разрешение не получено. Повторите попытку и нажмите «Да», когда Windows спросит, разрешить ли Atlas вносить изменения.
elevation-declined-continue = Разрешение не получено. Повторите попытку и нажмите «Да», когда Windows спросит, разрешить ли Atlas вносить изменения. Выбранные вами настройки сохранены.
elevation-draft-not-saved = Atlas не удалось сохранить выбранные настройки, поэтому приложение не было перезапущено. Повторите попытку. Подробности: { $error }

## The install flow

step-ready = Подготовка
step-options = Ваш выбор
step-security = Безопасность Windows
step-install = Установка
install-title = Настройка Atlas
# Accessible name of the row of steps.
stepper-label = Шаги настройки Atlas
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Шаг { $number } из { $total }, { $title }, { $status }
stepper-status-completed = завершён
stepper-status-current = текущий шаг
stepper-status-upcoming = предстоящий шаг
# Heading above each step's content.
step-heading = Шаг { $number } из { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = Подготовка ПК
ready-banner-busy-message = Atlas проверяет ваш ПК и подготавливает установочные файлы.
ready-banner-blocked-title = ПК нужно немного подготовить
ready-banner-blocked-message = Выполните указания ниже, затем нажмите «Проверить снова».
ready-banner-no-package-title = Скачайте Atlas, чтобы продолжить
ready-banner-no-package-message = Скачайте последнюю версию ниже или откройте сохранённый playbook Atlas (.apbx).
ready-banner-warnings-title = Есть несколько замечаний
ready-banner-warnings-message = Прочитайте замечания ниже и при необходимости выполните рекомендации, прежде чем продолжить.
ready-banner-ok-title = Можно переходить к выбору настроек
ready-banner-ok-message = Проверки пройдены, установочные файлы готовы.

# Card title and accessible name of the list of checks.
ready-this-pc = Проверки ПК
ready-check-again = Проверить снова

package-title = Установочные файлы
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Скачивание Atlas { $version } · { $received } из { $total } МБ
package-unpacking-progress =
    { $total ->
        [one] Распаковка · { $done } из { $total } файла
        [few] Распаковка · { $done } из { $total } файлов
        [many] Распаковка · { $done } из { $total } файлов
       *[other] Распаковка · { $done } из { $total } файлов
    }
package-unpacking = Распаковка
package-looking = Поиск последней версии Atlas.
package-none = Установочных файлов пока нет. Playbook (.apbx) содержит инструкции и файлы, необходимые Atlas.
# Short status words beside the card title.
package-status-downloading = Скачивание
package-status-unpacking = Распаковка
package-status-failed = Не удалось подготовить
package-status-ready = Готово
package-status-checking = Проверка
package-status-missing = Не скачано
# Accessible name of the progress bar.
package-progress = Ход подготовки установочных файлов
package-download-again = Скачать снова
package-download-version = Скачать Atlas { $version }
package-download-newest = Скачать последнюю версию
package-open-file = Открыть файл playbook
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } скачан с GitHub и готов к установке.
package-from-file = Atlas { $version } загружен из { $file } и готов к установке.
package-unpacked = Atlas { $version } готов к установке.
package-at = Установочные файлы: { $path }
package-none-yet = Установочные файлы не выбраны
acquire-no-asset = Для Atlas { $version } нет файла playbook, доступного для скачивания. Чтобы продолжить, откройте сохранённый playbook Atlas (.apbx).
acquire-unsupported = Это приложение устанавливает Atlas 0.6.0 и новее. Чтобы установить Atlas { $version }, используйте AME Wizard.
acquire-failed = Не удалось подготовить установочные файлы. Попробуйте скачать снова или откройте другой playbook Atlas (.apbx). Подробности: { $error }

## System checks

check-administrator = Разрешение на установку
check-supported-build = Совместимость с Windows
check-pending-updates = Обновления Windows
check-pending-reboot = Перезагрузка Windows
check-third-party-antivirus = Другие антивирусы
check-internet = Подключение к интернету
check-power = Питание
check-activation = Активация Windows
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
# Check boxes the user ticks when a check could not run. Written without a
# gendered past tense so they read the same for everyone.
check-ack-updates = Центр обновления Windows проверен: обновлений, ожидающих установки, нет
check-ack-reboot = Windows уже перезагружена, повторная перезагрузка не требуется
check-ack-internet = Этот ПК подключён к интернету
check-ack-generic = Это требование проверено мной вручную

detail-admin-ok = У Atlas есть разрешение вносить изменения, необходимые для установки.
detail-admin-missing = Перезапустите Atlas от имени администратора и нажмите «Да», когда Windows запросит разрешение.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Этой версии Atlas нужна сборка Windows { $builds }. На этом ПК сборка { $build }. Прежде чем продолжить, установите поддерживаемую версию Windows.
detail-updates-none = Обновлений Windows, ожидающих установки, нет.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Сначала установите это обновление: { $titles }.
        [2] Сначала установите эти обновления: { $titles }.
        [one] Сначала установите { $count } обновление, в том числе { $titles }.
        [few] Сначала установите { $count } обновления, в том числе { $titles }.
        [many] Сначала установите { $count } обновлений, в том числе { $titles }.
       *[other] Сначала установите { $count } обновлений, в том числе { $titles }.
    }
detail-updates-unknown = Не удалось проверить обновления Windows. Откройте Центр обновления Windows и, если ожидающих установки обновлений нет, подтвердите это ниже. ({ $error })
detail-reboot-none = Сейчас Windows не требует перезагрузки.
detail-reboot-pending = Перезагрузите ПК, чтобы завершить предыдущие изменения, затем снова откройте Atlas и проверьте снова.
detail-reboot-unknown = Не удалось проверить, нужна ли Windows перезагрузка. Перезагрузите ПК, затем снова откройте Atlas и повторите проверку. ({ $error })
detail-antivirus-none = Других антивирусов не обнаружено.
# $products is a list of product names (text).
detail-antivirus-found = Антивирусные программы могут блокировать установку: { $products }. Удалите их, прежде чем продолжить.
detail-antivirus-unknown = Не удалось проверить наличие других антивирусов. Прежде чем продолжить, проверьте установленные приложения. ({ $error })
detail-internet-ok = Подключение есть. Не отключайтесь от интернета, пока Atlas скачивает и устанавливает программы.
detail-internet-missing = Подключитесь к интернету, затем проверьте снова.
detail-power-mains = ПК подключён к электросети. Не отключайте его от сети до завершения установки.
detail-power-battery = Подключите ПК к электросети, чтобы он не выключился во время установки.
detail-power-unknown = Не удалось проверить питание. Если у вас ноутбук, подключите его к электросети, прежде чем продолжить.
detail-activation-ok = Windows активирована. Atlas это не изменит.
detail-activation-missing = Windows не активирована. Можно продолжить, но Atlas не активирует Windows.
detail-activation-no-licence = Windows не сообщила о лицензии. Можно продолжить; Atlas не меняет состояние активации.
detail-activation-unknown = Не удалось проверить активацию Windows. Можно продолжить; Atlas не меняет состояние активации. ({ $error })

## Step 2: Options

options-progress = Выбор { $number } из { $total }
options-progress-extras = Выбор { $number } из { $total }: необязательные дополнения
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Оставить антивирусную защиту включённой?
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
screen-extras-question = Выберите нужные дополнения
# Question for a required choice this app has no specific wording for.
screen-generic-question = Выберите вариант: { $title }
learn-more-defender = Подробнее о Microsoft Defender
learn-more-mitigations = Подробнее о защите процессора
learn-more-updates = Подробнее о Центре обновления Windows
learn-more-browser = Подробнее о браузерах
learn-more-power = Подробнее о питании и безопасности
learn-more-apps = Подробнее о приложениях
learn-more-eclean = Как eclean работает с AtlasOS
learn-more-generic = Открыть руководство по настройке
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Оставляет встроенный антивирус Windows, который помогает защитить ПК от вирусов и других угроз.
consequence-defender-disable = Удаляет Microsoft Defender. На ПК не будет антивирусной защиты, пока вы не установите другой антивирус.
consequence-mitigations-default = Оставляет стандартную защиту Windows от атак, использующих особенности работы процессора.
consequence-mitigations-disable = Отключает эту защиту и снижает безопасность. Производительность зависит от процессора и может ухудшиться.
consequence-auto-updates-disable = Вам придётся самостоятельно открывать Центр обновления Windows и устанавливать обновления. Уведомления об обновлениях останутся включёнными.
consequence-auto-updates-default = Windows будет устанавливать обновления автоматически, включая исправления безопасности.

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Оставить Microsoft Defender (рекомендуется)
playbook-option-defender-disable = Удалить Microsoft Defender
playbook-option-mitigations-default = Оставить стандартную защиту (рекомендуется)
playbook-option-mitigations-disable = Отключить защиту процессора
playbook-option-auto-updates-disable = Устанавливать обновления вручную
playbook-option-auto-updates-default = Устанавливать обновления автоматически
playbook-option-disable-hibernation = Отключить гибернацию
playbook-option-disable-power-saving = Отключить энергосбережение
playbook-option-disable-core-isolation = Отключить безопасность на основе виртуализации (VBS)
playbook-option-remove-snipping-tool = Удалить приложение «Ножницы»
playbook-option-uninstall-edge = Удалить Microsoft Edge
playbook-option-install-another-browser = Установить браузер
playbook-option-install-toolbox = Установить Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender — встроенный антивирус Windows. Рекомендуем оставить его. Удаляйте его, только если понимаете риски и собираетесь использовать другой антивирус.
playbook-page-mitigations-default-description = Эти средства защиты помогают противостоять атакам через уязвимости процессора. Рекомендуем оставить стандартные параметры Windows.
playbook-page-auto-updates-disable-description = Обновления Windows содержат исправления безопасности. Windows может устанавливать их автоматически, или вы можете устанавливать их самостоятельно.
consequence-install-toolbox = Atlas Toolbox помогает управлять параметрами Atlas. Это бета-версия, поэтому некоторые функции могут быть не доработаны.
playbook-page-browser-brave-description = Выберите браузер для установки. Atlas не будет менять настройки браузера.

## Step 3: Windows Security

security-banner-reading-title = Проверка параметров защиты
security-banner-reading-message = Atlas проверяет четыре переключателя защиты, перечисленные ниже.
security-banner-off-title = Все четыре переключателя защиты отключены
security-banner-off-message = Теперь можно проверить выбранные настройки перед установкой.
security-banner-readable-off-title = Переключатели, которые Atlas удалось проверить, отключены
security-banner-readable-off-message = Проверьте остальные переключатели в приложении «Безопасность Windows».
security-banner-on-title = Временно отключите антивирусную защиту
security-banner-on-message = Эти средства защиты могут блокировать изменения, которые нужно внести Atlas.
# The page name in Windows Security.
security-list-title = Параметры защиты от вирусов и других угроз
security-switch-off = Откл.
security-switch-on = Вкл.
security-switch-unreadable = Не удалось проверить
security-switch-reading = Проверка
security-all-off = Все отключены
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 can't be read".
security-count-still-on =
    { $count ->
        [one] { $count } ещё включён
        [few] { $count } ещё включены
        [many] { $count } ещё включены
       *[other] { $count } ещё включены
    }
security-count-unreadable = { $count } не удалось проверить
security-count-join = { $a }, { $b }
security-unknown-title = Подтвердите состояние переключателей, которые Atlas не удалось проверить
security-unknown-message = Убедившись в приложении «Безопасность Windows», что все четыре переключателя отключены, подтвердите это ниже.
# First-person statement; written without a gendered past tense.
security-acknowledge = «Безопасность Windows» проверена: все четыре переключателя отключены
security-unknown-unelevated-title = Для проверки защиты Atlas нужны права администратора
security-unknown-unelevated-message = Перезапустите Atlas от имени администратора, чтобы он мог прочитать параметры Microsoft Defender.
# The four switches, named as Windows Security names them.
protection-tamper = Защита от подделки
protection-tamper-why = Отключите её первой, чтобы Defender разрешил менять свои параметры защиты.
protection-realtime = Защита в режиме реального времени
protection-realtime-why = Приостановите проверку файлов, чтобы Defender не блокировал установочные файлы Atlas.
protection-cloud = Облачная защита
protection-cloud-why = Приостановите онлайн-проверку угроз, которая может блокировать установочные файлы Atlas.
protection-samples = Автоматическая отправка образцов
protection-samples-why = Отключите её, чтобы Defender не отправлял файлы Atlas в Microsoft на анализ.

## Step 4: Install

install-preparing-title = Последняя проверка перед установкой
install-preparing-message = Перед внесением изменений Atlas ещё раз проверяет ПК и параметры защиты.
install-installing = Установка
install-running = Выполняется
# Accessible name of the progress bar.
install-progress = Ход установки
phase-preflight = Проверка ПК и подготовка файлов
phase-staging = Подготовка установочных файлов
phase-applying = Настройка Windows. Не выключайте ПК.
phase-done = Завершение настройки
outcome-succeeded-title = Atlas установлен
outcome-lost-title = Не удалось подтвердить результат установки
outcome-failed-title = Установка не завершена
outcome-succeeded = Перезагрузите ПК, чтобы завершить настройку Atlas.
outcome-requirements = ПК не соответствует требованиям установки. Изменения не вносились. Вернитесь на шаг «Подготовка» и запустите проверки снова.
outcome-not-elevated = Изменения не вносились. Перезапустите Atlas от имени администратора и повторите попытку.
outcome-failed-preflight = Установка остановилась, ничего не изменив. Откройте файл журнала, чтобы узнать причину, затем повторите попытку.
outcome-failed-staging = Установка остановилась при подготовке файлов, до внесения изменений в Windows. Откройте файл журнала, чтобы узнать причину, затем повторите попытку.
outcome-failed-applying = Часть изменений уже могла быть внесена. Если вы решите не продолжать, снова включите отключённые средства защиты в приложении «Безопасность Windows», если они ещё доступны.
outcome-not-started = Установщик не запустился вовремя. Изменения не вносились. Нажмите «Повторить попытку».
outcome-lost = Установщик завершил работу, не сообщив результат, и часть изменений уже могла быть внесена. Откройте файл журнала, чтобы узнать причину, затем нажмите «Повторить попытку», чтобы продолжить установку.
restart-now-message = Windows перезагружается, чтобы завершить настройку Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows перезагрузится через { $seconds } секунду, чтобы завершить настройку Atlas.
        [few] Windows перезагрузится через { $seconds } секунды, чтобы завершить настройку Atlas.
        [many] Windows перезагрузится через { $seconds } секунд, чтобы завершить настройку Atlas.
       *[other] Windows перезагрузится через { $seconds } секунды, чтобы завершить настройку Atlas.
    }
restart-stopped = Автоматическая перезагрузка отменена. Сохраните работу, затем перезагрузите ПК, чтобы завершить настройку Atlas.
restart-needed = Сохраните работу, затем перезагрузите Windows, чтобы завершить настройку Atlas.
restart-dont-now = Перезагрузить позже
restart-now = Перезагрузить сейчас
# Accessible name of the countdown bar.
restart-progress = Время до перезагрузки
restart-start-failed = Не удалось перезагрузить Windows. Сохраните работу, затем перезагрузите ПК через меню «Пуск». Подробности: { $error }
preflight-title = Установка не началась
preflight-invalid-options = Atlas не удалось использовать выбранные настройки. Вернитесь на шаг «Ваш выбор», проверьте их и повторите попытку. Подробности: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Состояние ПК изменилось после предыдущих проверок. Прежде чем повторить попытку, устраните следующее. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Безопасность Windows: { $summary }.
preflight-busy = Другое окно Atlas уже запускает установку. Подождите немного и повторите попытку.
preflight-record-unreadable = Atlas не удалось проверить, выполняется ли ещё предыдущая установка, поэтому новая не запущена. Закройте и снова откройте Atlas, чтобы получить инструкции по восстановлению. Подробности: { $error }
preflight-refused = Не удалось запустить установщик. Изменения не вносились. Подробности: { $error }
go-to-ready = Вернуться к шагу «Подготовка»
go-to-options = Вернуться к шагу «Ваш выбор»
output-problem-title = Не удалось прочитать ход установки
output-problem-message = Atlas не удалось прочитать журнал. Это не значит, что установка остановилась. Не выключайте ПК и попробуйте открыть файл журнала. Подробности: { $error }
install-elevate-title = Для установки Atlas нужны права администратора
install-no-package-title = Сначала выберите установочные файлы
install-no-package-message = Вернитесь на шаг «Подготовка», чтобы скачать Atlas или открыть сохранённый playbook (.apbx).
install-security-title = Перед установкой проверьте антивирусную защиту
install-security-reading = Повторная проверка четырёх переключателей защиты.
install-security-message = { $summary }. Откройте «Безопасность Windows» и убедитесь, что все четыре переключателя отключены, прежде чем продолжить.
summary-this-install = Сводка установки
summary-try-again = Проверьте перед повторной попыткой
summary-ready = Проверьте настройки Atlas
summary-activation = Активация
summary-activation-ok = Активирована. Atlas это не изменит.
summary-activation-missing = Не активирована. Можно продолжить, но Atlas не активирует Windows.
summary-activation-unknown = Atlas не меняет состояние активации Windows.
summary-duration = Примерное время
summary-duration-value =
    { $minutes ->
        [one] { $minutes } минута, затем перезагрузка
        [few] { $minutes } минуты, затем перезагрузка
        [many] { $minutes } минут, затем перезагрузка
       *[other] { $minutes } минуты, затем перезагрузка
    }
summary-restart-checkbox = Автоматически перезагрузить ПК после установки
summary-show-command = Показать команду установки
summary-hide-command = Скрыть команду установки
summary-command-unavailable = Не удалось подготовить команду установки. Подробности: { $error }
summary-not-chosen = Пока не выбрано
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Изменить: { $title }
footer-still-checking = Подготовка к установке
footer-fix-items = Чтобы продолжить, выполните указания выше
footer-need-package = Чтобы продолжить, скачайте Atlas или откройте playbook
footer-reading-security = Проверка переключателей защиты
button-checking = Проверка
button-installing = Установка
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

installing-checking-title = Последняя проверка
installing-checking-line = Перед внесением изменений Atlas проверяет ПК. Это может занять некоторое время.
installing-title = Установка Atlas
installing-phase-preflight = Проверка ПК и подготовка установочных файлов.
installing-phase-staging = Подготовка установочных файлов. Не выключайте ПК.
installing-phase-applying = Настройка Windows согласно вашему выбору. Не выключайте ПК и не отключайте его от электросети.
installing-phase-done = Завершение установки. Не выключайте ПК.
installing-installed-title = Atlas установлен
# $time is a formatted clock time.
installing-started-just-now = Начало в { $time }, меньше минуты назад
installing-started-minutes =
    { $minutes ->
        [one] Начало в { $time }, { $minutes } минуту назад
        [few] Начало в { $time }, { $minutes } минуты назад
        [many] Начало в { $time }, { $minutes } минут назад
       *[other] Начало в { $time }, { $minutes } минуты назад
    }

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } установлен
installed-title = Atlas установлен
installed-ready = Всё настроено. ПК готов к работе с Atlas.
installed-open-atlas = Посмотреть установку Atlas

## Settings

settings-title = Параметры
settings-theme = Тема приложения
settings-theme-system = Как в Windows
settings-theme-light = Светлая
settings-theme-dark = Тёмная
settings-theme-contrast-note = Atlas использует цвета контрастной темы Windows.
settings-theme-mica-note = Полупрозрачный фон показывается, когда выбранная здесь тема, светлая или тёмная, совпадает с темой Windows.
settings-language = Язык
settings-language-system = Как в Windows
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = При выборе «Как в Windows»: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Предварительный перевод · ожидает проверки носителем
preview-notice = { $language } — предварительный перевод.
preview-notice-switch = Переключиться на английский
preview-notice-language = Изменить язык
# $tag is a language tag (text).
settings-language-unavailable = Язык { $tag } недоступен в этой версии Atlas. Пока показывается английский, а ваш выбор языка сохранён.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas пока не поддерживает языки интерфейса вашей Windows ({ $languages }). Пока показывается английский.
settings-language-windows-unavailable = Не удалось определить язык интерфейса Windows. Пока Atlas использует английский. Подробности: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = Числа, даты и время отображаются в региональном формате Windows ({ $locale }).
settings-language-contribute = Помочь с переводом Atlas на GitHub
settings-installing = Установка
settings-restart-label = Автоматически перезагрузить ПК после установки
settings-restart-locked = Это можно изменить после завершения установки.
settings-restart-description = Для завершения настройки нужна перезагрузка. Если автоматическая перезагрузка включена, сохраните работу перед установкой.
settings-about = О приложении
settings-about-app = Atlas Manager
settings-about-data = Файлы приложения
settings-about-licence = Лицензия
settings-about-licence-value = GPL-3.0, свободное ПО с открытым исходным кодом
settings-view-source = Открыть исходный код на GitHub
settings-open-data-folder = Открыть папку приложения

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Освобождает место на диске, которое используется для сохранения сеанса при гибернации. Гибернация и быстрый запуск станут недоступны.
consequence-disable-power-saving = Отключает функции энергосбережения. ПК может потреблять больше энергии, сильнее нагреваться и быстрее разряжать батарею.
consequence-disable-core-isolation = Отключает дополнительный уровень защиты Windows, включая целостность памяти. Это снижает защиту и может повлиять на приложения и игры, которым она нужна.
consequence-remove-snipping-tool = Удаляет приложение Windows для снимков и записи экрана.
consequence-uninstall-edge = Удаляет браузер Microsoft Edge. Убедитесь, что у вас есть другой браузер, или выберите его ниже.
consequence-install-another-browser = Выберите браузер ниже, и Atlas установит его.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas настраивает Windows так, чтобы уменьшить фоновую активность и убрать отвлекающие элементы. Перед внесением изменений мы проведём вас через проверки и выбор настроек.

detail-build-missing = В этом playbook не указаны поддерживаемые сборки Windows. Выберите полную сборку playbook вместо пакета LocalTest.
## ISO creation (Beta)
iso-home-title = Установочный носитель Windows
iso-home-description = Создайте ISO-образ Windows с Atlas для чистой установки на этом или другом ПК.
iso-open = Создать ISO с Atlas
iso-title = Создать ISO с Atlas
iso-beta = Бета
iso-beta-description = Проверьте ISO-образ в виртуальной машине, прежде чем использовать его на ПК. Перед установкой Windows сделайте резервную копию файлов.
iso-admin-description = Для чтения образов Windows и создания установочных носителей нужны права администратора.
iso-files-description = Выберите неизменённый ISO-образ Windows 11 x64, плейбук Atlas (.apbx) и новое имя для готового файла.
iso-source = ISO-образ Windows
iso-package = Плейбук Atlas (0.6+)
iso-output = Сохранить новый ISO-образ в
iso-no-file = Файл не выбран
iso-browse = Обзор
iso-save-as = Сохранить как
iso-inspect = Проверить файлы
iso-mode-title = Настройки Windows и Atlas
iso-mode-interactive = Выбрать настройки Atlas после входа
iso-mode-interactive-description = После входа Atlas поможет обновить Windows и приложения Store, выбрать настройки и применить Atlas.
iso-mode-before = Выбрать настройки Atlas сейчас
iso-mode-before-description = Сохраните настройки Atlas в ISO. После входа обновите Windows и приложения Store, затем примените Atlas с этими настройками.
iso-package-unsupported-title = Выберите более новый плейбук
iso-package-unsupported = Для установки из ISO требуется Atlas 0.6 или новее с поддержкой ISO. Выберите совместимый плейбук.
iso-atlas-options = Настройки Atlas
iso-review = Проверить параметры ISO
iso-review-description = Atlas создаст отдельный ISO-образ и сохранит исходный. Загрузитесь с нового образа, чтобы установить Windows. Создание образа не устанавливает Atlas на этот ПК.
iso-review-files = Файлы
iso-review-package = Плейбук Atlas
iso-review-output = Новый ISO-образ
iso-review-editions = Редакции
iso-review-size = Размер
iso-review-size-value = { $size } МБ
iso-review-account = Имя учётной записи
iso-review-target = Установка на
iso-review-drivers = Драйверы
iso-create = Создать ISO
iso-stage-inspect = Проверка образа Windows
iso-stage-copy = Копирование файлов Windows
iso-stage-inject = Добавление Atlas
iso-stage-master = Создание ISO-образа
iso-stage-verify = Проверка результата
iso-stage-cleanup = Завершение
iso-progress-description = Не закрывайте приложение. Обработка больших образов может занять некоторое время.
iso-cancel = Отменить создание
iso-cancelling = Ожидание безопасной остановки
iso-cancelled = Создание ISO отменено
iso-cancelled-description = Исходный ISO-образ сохранён. В журнале диагностики указано, остались ли временные файлы, которые нужно удалить.
iso-complete = ISO-образ готов
iso-complete-description = Проверьте его в виртуальной машине, а затем используйте для создания установочного носителя Windows.
iso-open-folder = Показать в папке
iso-failed = Не удалось завершить создание ISO
iso-failed-description = Откройте диагностику, чтобы узнать причину. Устраните проблему и повторите попытку с новым именем выходного файла.
iso-diagnostics = Открыть диагностику
iso-close-title = ISO-образ ещё создаётся
iso-close-message = Не закрывайте окно до завершения создания или отмены. Отмена произойдёт, когда текущую операцию можно будет безопасно остановить.
iso-keep-open = Оставить открытым
prepare-title = Обновление Windows и приложений Store
prepare-description = Перед применением Atlas установите обновления Windows и обновите Microsoft Store и все установленные приложения из него. Приложения из Store могут закрыться во время обновления.
prepare-complete = Windows и приложения Store обновлены.
prepare-reboot = Требуется перезагрузка Windows. Ваши настройки Atlas будут сохранены. После входа снова проверьте обновления.
prepare-failed = Не удалось завершить некоторые обновления. Проверьте журнал диагностики, устраните ошибки Windows или Store и повторите попытку.
prepare-cancelled = Подготовка остановлена. Перед продолжением снова проверьте обновления.
prepare-windows-search = Проверка обновлений Windows…
prepare-windows-download = Загрузка обновлений Windows…
prepare-windows-install = Установка обновлений Windows…
prepare-store-search = Проверка Microsoft Store…
prepare-store-install = Обновление Microsoft Store и приложений…
prepare-stop-description = Подготовка остановится после завершения текущей операции обновления. До этого не закрывайте Atlas.
prepare-stop = Остановить после этой операции
prepare-restart = Перезагрузить и продолжить
prepare-start = Найти и установить обновления
iso-username = Имя локальной учётной записи
iso-account-description = После переустановки Windows предложит задать пароль.
iso-username-placeholder = Ваше имя
iso-account-invalid = Используйте от 1 до 20 символов без пробелов по краям и символов, запрещённых в именах учётных записей Windows.
iso-privacy-defaults = При настройке Windows автоматически отключаются необязательная отправка данных и персонализированные предложения.
prepare-drivers = Как устанавливать драйверы?
prepare-drivers-auto = Получать драйверы через Центр обновления Windows
prepare-drivers-auto-detail = Windows найдёт драйверы для вашего оборудования. Рекомендуется для большинства ПК.
prepare-drivers-manual = Устанавливать драйверы самостоятельно
prepare-drivers-manual-detail = Блокирует загрузку драйверов через Центр обновления Windows. Вам нужно будет найти их самостоятельно; установленные драйверы сохранятся.
prepare-network-needed = Подключитесь по Wi-Fi или Ethernet без лимитного подключения и повторите попытку. Если Wi-Fi недоступен, сначала установите сетевой драйвер.
prepare-network-settings = Открыть параметры сети
iso-target-title = На каком ПК вы переустановите Windows?
iso-target-this = На этом ПК
iso-target-other = На другом ПК
iso-copy-network = Добавить сетевые драйверы этого ПК
iso-network-detail = Использует драйверы Wi-Fi и Ethernet этого ПК при установке Windows. После переустановки нужно будет снова подключиться к Wi-Fi.
iso-network-source = Источник сетевых драйверов
iso-network-installed = Использовать установленные драйверы
iso-network-updated = Сначала проверить Центр обновления Windows
iso-network-updated-detail = Загружает подходящие драйверы из Центра обновления Windows и сохраняет установленные как запасной вариант. Требуется нелимитное подключение.
iso-stage-network-drivers = Подготовка сетевых драйверов…
iso-network-failed = Не удалось подготовить сетевые драйверы. Проверьте диагностику или вернитесь назад и измените вариант подготовки сетевых драйверов.
iso-mode-desktop = Завершить настройку до открытия рабочего стола
iso-mode-desktop-description = Выберите параметры Atlas сейчас. После входа завершите обновления и настройку Atlas перед открытием рабочего стола Windows.
desktop-setup-description = Завершите настройку ПК. Параметры Atlas сохранены; при необходимости можно вернуться в Windows.
desktop-setup-exit = Продолжить в Windows

# Windows installation USB (Beta)
usb-title = Создать установочную флешку
usb-existing = Создать флешку из готового ISO
usb-description = Создайте загрузочную флешку с Windows 11 25H2 для установки Windows и Atlas на компьютер.
usb-choose-iso = Выбрать ISO
usb-drive = USB-накопитель
usb-empty = Подключите USB-накопитель и обновите список. Здесь отображаются только доступные для записи USB-накопители, на которых нет запущенной Windows.
usb-refresh = Обновить
usb-drive-detail = { $size } ГБ · { $volumes } · Серийный номер: { $serial }
usb-review = Проверить выбор
usb-erase-title = Стереть этот USB-накопитель?
usb-erase-description = Все файлы и разделы на { $drive } ({ $size } ГБ) будут безвозвратно удалены. Ваш ISO сохранится.
usb-layout = Для установки Windows будет выделено до 32 ГБ. Остальное место останется нераспределённым. Этот накопитель предназначен для компьютеров с загрузкой через UEFI.
usb-ack = Я понимаю, что всё содержимое этого USB-накопителя будет удалено.
usb-write = Стереть и создать флешку
usb-stage-prepare = Подготовка установочных файлов…
usb-stage-format = Форматирование USB-накопителя…
usb-stage-copy = Копирование установочных файлов…
usb-stage-verify = Проверка USB-накопителя…
usb-working = Не закрывайте Atlas и не отключайте накопитель. Отмена дождётся безопасной остановки текущей операции. Незавершённый накопитель нельзя использовать для установки Windows.
usb-failed = Не удалось закончить создание флешки. Проверьте подключение и откройте диагностику. Для повторной попытки выберите накопитель заново.
usb-cancelled = Создание флешки остановлено. На накопителе могут остаться неполные установочные файлы. Создайте его заново перед установкой Windows.
usb-complete = Флешка готова, все файлы проверены. Извлеките её, подключите к компьютеру для переустановки Windows и выберите в меню загрузки UEFI.
usb-eject = Извлечь USB-накопитель
usb-ejected = Теперь накопитель можно безопасно отключить. Для установки Windows выберите его в меню загрузки UEFI компьютера.
usb-eject-failed = Windows не удалось извлечь накопитель. Закройте файлы и окна, которые его используют, и повторите попытку.
ready-fresh-title = Начните с чистой установки Windows
ready-fresh-description = Atlas требует чистой установки Windows, кроме поддерживаемых обновлений Atlas. Для новой установки Atlas 0.6 требуется Windows 11 25H2. Перед переустановкой Windows создайте резервную копию файлов.
detail-edition-unsupported = Используйте Windows 11 Pro, Pro for Workstations или Enterprise. Редакции Home, LTSC и Server не поддерживаются. Если редакцию не удалось определить, устраните эту проблему перед продолжением.
install-source-title = Установка недоступна
install-source-unsupported = Atlas { $source } нельзя обновить напрямую до { $target }. Чтобы использовать эту версию, переустановите Windows.
install-source-unknown = Atlas не удалось проверить состояние установки. Разберитесь с незавершённой установкой и проверьте диагностику перед повторной попыткой.
iso-edition-selection = Включены только поддерживаемые редакции. При установке Windows выберите редакцию, для которой у вас есть лицензия Windows.
detail-windows-preview = Сборки Insider не поддерживаются. Используйте общедоступную версию Windows 11.
detail-windows-release-unknown = Atlas не удалось подтвердить, что эта сборка Windows общедоступна. Подключитесь к интернету и повторите проверку.
iso-release-unknown = Не удалось подтвердить, что этот ISO-образ содержит общедоступную версию Windows 11 25H2. Подключитесь к интернету и повторите попытку или выберите официальный установочный образ.
prepare-previous-worker = Предыдущее обновление ещё выполняется. Atlas дождётся его завершения, после чего можно будет повторить попытку.

ready-used-windows-title = Переустановите Windows перед продолжением
ready-used-windows-description = Эта система Windows имеет признаки предыдущего использования. Установка Atlas здесь не поддерживается и настоятельно не рекомендуется. Продолжайте, только если понимаете риски.
ready-used-windows-dismiss = Я понимаю риски
playbook-option-install-eclean = Установить eclean
consequence-install-eclean = Инструмент обслуживания от команды AtlasOS, который помогает поддерживать порядок на ПК после настройки. Просматривайте ненужные файлы и приложения автозагрузки. Требуется учётная запись и подключение к интернету.

prepare-resumed = Windows перезапущена. Ваши настройки Atlas восстановлены. Продолжите обновления перед установкой Atlas.
prepare-continue = Продолжить обновления
prepare-saving-restart = Сохранение настроек и настройка повторного открытия Atlas после перезапуска Windows…
prepare-restart-save-failed = Не удалось сохранить настройки. Повторите попытку перед перезапуском.
prepare-restart-registration-failed = Настройки сохранены, но настроить автоматическое открытие не удалось. Повторите попытку или перезапустите Windows и откройте Atlas вручную.
prepare-restart-failed = Не удалось перезапустить Windows. Повторите попытку или перезапустите через Windows. Настройки сохранены, Atlas настроен на повторное открытие.
