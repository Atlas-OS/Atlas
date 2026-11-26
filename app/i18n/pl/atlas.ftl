### Atlas Manager: Polish (pl). Preview translation, revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog:
### - The reader is addressed in the second person singular, with Twój and Ci capitalised, as
###   Microsoft Polish does, and never with a gendered past tense ("wybrano", "Potwierdzam, że…").
### - "Atlas" is declined like an ordinary masculine noun (Atlasa, Atlasie, Atlasem); "Windows"
###   and "Microsoft Defender" are never declined, while "Zabezpieczenia Windows" declines like
###   an ordinary noun phrase (w Zabezpieczeniach Windows).
### - "otwórz Atlas ponownie" means relaunching this app; "uruchom ponownie" always means
###   restarting the PC or Windows.
### - The .atlaspkg file is "pakiet Atlasa", then "pakiet" ("plik pakietu" for the file itself).
### - Install steps (krok): Przygotowanie, Opcje, Zabezpieczenia Windows, Instalacja. ISO steps:
###   Windows, Konfiguracja, Tworzenie. Update, ISO and USB stages are "etap".
### - Buttons are named without quotes after "wybierz"; options and check boxes take "zaznacz".
### - Windows Setup is "Instalator Windows"; Storage settings are "ustawienia magazynu".
### - Names inserted mid-sentence (screen-*-name, check and switch names) follow a colon, so they
###   stay in the nominative: "Zmień: przeglądarka".
### - Plurals use one, few, many and other on every count.

## Wspólne

app-name = Atlas Manager
common-done = Gotowe
common-cancel = Anuluj
common-back = Wstecz
common-next = Dalej
common-dismiss = Odrzuć
# Link beside a summary row that jumps back to change that choice.
common-change = Zmień
common-copy = Kopiuj
# Shown where a list of options is empty.
common-none = Brak
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Wróć do strony głównej
# Accessible name of the gear button in the title bar.
common-settings = Ustawienia
common-close-settings = Zamknij ustawienia
common-open-windows-security = Otwórz Zabezpieczenia Windows
# Relaunches this app (not the PC) with administrator rights.
common-restart-as-administrator = Otwórz ponownie jako administrator
common-try-again = Spróbuj ponownie
common-read-the-docs = Przeczytaj przewodnik po Atlasie
common-show-details = Pokaż szczegóły
common-hide-details = Ukryj szczegóły
# Accessible name of a button that acts on one card. $action is the button's label;
# $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Otwórz folder dzienników
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Kopiuj dziennik instalacji
common-install-log = Dziennik instalacji
# Row labels in summary cards.
common-windows = Windows
common-package = Pakiet Atlasa
common-checking = Sprawdzanie
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 lub 26200".
list-or = { $a } lub { $b }
# Joins the last two items of a list; $a may itself be several items.
list-and = { $a } i { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Okno

# Dialog shown when the window is closed while an install runs.
window-close-title = Zamknąć okno podczas instalacji?
window-close-installing = Instalacja będzie kontynuowana. Otwórz Atlas ponownie, aby zobaczyć wynik.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = Instalacja będzie kontynuowana, ale komputer nie uruchomi się ponownie automatycznie. Otwórz Atlas ponownie, aby zobaczyć wynik.
# The answer that keeps the window open when closing it would interrupt something.
window-close-keep = Pozostaw otwarte
window-close-close = Zamknij okno
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Zatrzymać przed instalacją?
window-close-checks-unchanged = Instalacja jeszcze niczego nie zmieniła. Jeśli zamkniesz okno, nie rozpocznie się.
window-close-keep-installing = Kontynuuj instalację
window-close-stop-and-close = Zatrzymaj i zamknij
# Dialog shown when the window is closed while Windows and Store apps update.
prepare-close-question = Zatrzymać aktualizowanie?
# "Etap" is a stage of updating (as in prepare-percent), not one of the four flow steps (krok).
prepare-close-stops-after-stage = Atlas zatrzyma się po zakończeniu bieżącego etapu. Wtedy możesz go zamknąć.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now.
window-close-restart-question = Uruchomić ponownie, aby dokończyć konfigurację Atlasa?
window-close-restart-closed = Po zamknięciu Atlas nie uruchomi ponownie komputera. Najpierw zapisz pracę.
# Closing while Get ready counts down to the restart that updates need.
window-close-update-restart-question = Uruchomić ponownie, aby dokończyć aktualizowanie?
window-close-update-restart-later = Najpierw zapisz pracę. Jeśli uruchomisz komputer ponownie później, Atlas będzie kontynuować po ponownym uruchomieniu.
# Dialog shown when the window is closed during a setup with Windows Security switches still off.
window-close-protection-title = Zamknąć Atlas z wyłączoną ochroną?
window-close-protection-all = Cztery przełączniki ochrony w Zabezpieczeniach Windows są wyłączone. Jeśli nie instalujesz teraz Atlasa, najpierw włącz je ponownie.
# $switches names the switches that are off, joined like a list; $count is how many there are.
window-close-protection-some =
    { $count ->
        [one] W Zabezpieczeniach Windows jest wyłączony przełącznik: { $switches }. Jeśli nie instalujesz teraz Atlasa, najpierw włącz go ponownie.
        [few] W Zabezpieczeniach Windows są wyłączone przełączniki: { $switches }. Jeśli nie instalujesz teraz Atlasa, najpierw włącz je ponownie.
        [many] W Zabezpieczeniach Windows są wyłączone przełączniki: { $switches }. Jeśli nie instalujesz teraz Atlasa, najpierw włącz je ponownie.
       *[other] W Zabezpieczeniach Windows są wyłączone przełączniki: { $switches }. Jeśli nie instalujesz teraz Atlasa, najpierw włącz je ponownie.
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
iso-close-question = Zatrzymać tworzenie obrazu ISO?
iso-close-safe-point = Atlas zatrzyma się w najbliższym bezpiecznym momencie.
usb-close-question = Zatrzymać tworzenie dysku USB?
usb-close-unfinished = Z nieukończonego dysku nie można zainstalować Windows.
window-close-keep-creating = Kontynuuj tworzenie
window-close-stop = Zatrzymaj
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Otwórz pakiet Atlasa (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas jest zainstalowany. Windows uruchomi się ponownie, aby dokończyć konfigurację.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas uruchamia Windows ponownie, aby dokończyć instalowanie aktualizacji.

## System

# "Windows 11 Pro 25H2 (kompilacja 26200.1234)". All three values are text.
system-description = { $product } { $version } (kompilacja { $build })

## Strona główna

home-not-installed = Witaj w Atlasie
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". All three
# values are text.
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas ogranicza aktywność w tle i elementy rozpraszające uwagę w Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas na tym komputerze
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Zainstalowano { $date }
home-status-checking = Sprawdzanie aktualizacji…
# While startup checks whether another window's installation is running.
home-status-recovering = Sprawdzanie, czy trwa instalacja
home-status-offline = Nie udało się sprawdzić aktualizacji
home-status-not-checked = Nie sprawdzono jeszcze aktualizacji
home-status-update = Dostępny jest Atlas { $version }
home-status-up-to-date = Masz najnowszą wersję
home-status-newest = Najnowsza wersja: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Instalacja Atlasa { $version } nie jest ukończona
home-check-again = Sprawdź ponownie
# Primary button while an install is running or waiting.
home-show-install = Pokaż postęp
home-continue-installing = Kontynuuj konfigurację
home-update-to = Zaktualizuj do wersji { $version }
home-reinstall = Zainstaluj Atlas ponownie
home-install = Zainstaluj Atlas
home-finish-install = Dokończ instalację Atlasa { $version }
home-start-over = Zacznij od nowa
# Asked by Install Atlas where Windows on this PC has been in use. Its buttons are
# common-cancel and home-used-windows-install.
home-used-windows-title = Zainstalować Atlas na tym komputerze?
home-used-windows-message = Istniejące aplikacje i ustawienia mogą przestać działać. Atlas usuwa też OneDrive, więc pliki w nim przestaną się synchronizować, a foldery mogą wyglądać na puste. Najpierw zrób kopię zapasową plików.
home-used-windows-install = Zainstaluj mimo to
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Zainstaluj ponownie Windows z Atlasem
home-iso-used = Windows na tym komputerze jest już używany, a Atlas działa najlepiej na czystej instalacji.
# A bar on Home after an installation finished, until the PC restarts.
home-restart-title = Komputer wymaga ponownego uruchomienia
# Instead of restart-needed when Windows refused to restart.
home-restart-failed = Atlas nie mógł uruchomić komputera ponownie. Uruchom go ponownie z menu Start.
home-security-reminder-title = Włącz ochronę ponownie
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Upewnij się, że ochrona jest włączona
# Under home-security-reminder-title. $switches names the switches that read off, joined with
# list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] W Zabezpieczeniach Windows nadal jest wyłączony przełącznik: { $switches }.
        [few] W Zabezpieczeniach Windows nadal są wyłączone przełączniki: { $switches }.
        [many] W Zabezpieczeniach Windows nadal są wyłączone przełączniki: { $switches }.
       *[other] W Zabezpieczeniach Windows nadal są wyłączone przełączniki: { $switches }.
    }
home-security-reminder-unreadable-message = Atlas nie mógł odczytać wszystkich przełączników ochrony. Sprawdź w Zabezpieczeniach Windows, czy te przełączniki są włączone: { $switches }.
home-elevation-title = Do instalacji potrzebne są uprawnienia administratora
# Under home-elevation-title when the setup choices couldn't be saved.
home-elevation-draft-not-saved = Atlas nie mógł zapisać wybranych opcji instalacji, więc nie otworzył się ponownie.
home-state-error-title = Nie udało się odczytać informacji o instalacji Atlasa
home-state-error-problem = Wersja Atlasa, wybrane opcje i historia instalacji mogą być wyświetlane niepoprawnie.
# A bar on Home when the Atlas package needs a newer Atlas Manager.
home-manager-needed-title = Atlas Manager wymaga aktualizacji
home-whats-new = Co nowego w Atlasie { $version }
home-view-release = Zobacz informacje o wydaniu w serwisie GitHub
home-show-less = Pokaż mniej
home-show-full-notes = Pokaż pełne informacje o wydaniu
home-your-install = Twoja konfiguracja Atlasa
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Na tym komputerze nie ma zapisu o tym, jak zainstalowano Atlas, więc nie można wyświetlić wybranych opcji ani historii instalacji.
home-history = Historia instalacji
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Krok { $number }: { $title }
# A numbered step with its sentence, as screen readers read each step of Home's lists. $step is
# home-step-a11y or stepper-item-a11y; $detail is the step's sentence, such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps on a PC without Atlas, each with its
# home-step-* sentence beside it.
home-steps-title = Co się stanie
# Instead of home-steps-title while a setup is under way: each step shows whether it's done,
# current or still to come.
home-steps-under-way-title = Konfigurowanie Atlasa
# Beside step-ready in that card. The home-step-* sentences are in the present tense because they
# also show beside finished steps while a setup is under way.
home-step-ready = Atlas sprawdza komputer i aktualizuje Windows.
# Instead of home-step-ready where Windows must move to a newer version first. $release is that
# version, such as "26H2" (text).
home-step-ready-move = Atlas sprawdza komputer i aktualizuje Windows do wersji { $release }.
# Beside step-options in that card.
home-step-options = Wybierasz, co zachować, na przykład Microsoft Defender.
# Beside step-security in that card.
home-step-security = Wyłączasz cztery przełączniki ochrony w Zabezpieczeniach Windows.
# Beside step-install in that card. $minutes is how long installing usually takes (a number). The
# first is shown when the PC restarts by itself, the second when the person restarts it.
# "około" takes the genitive: około 1 minuty, około 3 minut, około 1,5 minuty.
home-step-install-restarts =
    { $minutes ->
        [one] Instalacja trwa zwykle około { $minutes } minuty, potem komputer uruchomi się ponownie.
        [few] Instalacja trwa zwykle około { $minutes } minut, potem komputer uruchomi się ponownie.
        [many] Instalacja trwa zwykle około { $minutes } minut, potem komputer uruchomi się ponownie.
       *[other] Instalacja trwa zwykle około { $minutes } minuty, potem komputer uruchomi się ponownie.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] Instalacja trwa zwykle około { $minutes } minuty, potem uruchom komputer ponownie.
        [few] Instalacja trwa zwykle około { $minutes } minut, potem uruchom komputer ponownie.
        [many] Instalacja trwa zwykle około { $minutes } minut, potem uruchom komputer ponownie.
       *[other] Instalacja trwa zwykle około { $minutes } minuty, potem uruchom komputer ponownie.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Najpierw zapisz pracę: aplikacje mogą zostać zamknięte, a komputer uruchomi się ponownie.
home-github = Zobacz Atlas w serwisie GitHub
home-discord = Dołącz do społeczności Atlasa
home-report-problem = Zgłoś problem

## Sposób wykonania instalacji (z dokumentu stanu)

# Lower-case forms used inside a history row.
history-mode-fresh = pierwsza instalacja
history-mode-upgrade = aktualizacja
history-mode-reapply = ponowna instalacja
history-mode-unknown = instalacja

## Powiadomienia na stronie głównej

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas używa domyślnych ustawień aplikacji
notice-settings-unreadable-problem = Atlas nie mógł odczytać zapisanych ustawień aplikacji. Ustawienia Windows nie zostały zmienione.
notice-settings-damaged-kept-problem = Plik ustawień aplikacji był uszkodzony, więc Atlas przywrócił ustawienia domyślne i zachował kopię starego pliku.
notice-settings-damaged-problem = Plik ustawień aplikacji był uszkodzony. Atlas używa na razie ustawień domyślnych.
notice-settings-not-saved-title = Nie udało się zapisać ustawień aplikacji
notice-settings-not-saved-problem = Atlas nie mógł zapisać ostatnich zmian, więc mogą one zostać utracone po zamknięciu Atlasa. Jeśli otwarte jest inne okno Atlasa, zamknij je, a potem wprowadź zmianę ponownie.
notice-session-unreadable-title = Nie udało się sprawdzić poprzedniej instalacji
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas nie mógł ustalić, czy wcześniejsza instalacja nadal trwa. Jeśli masz pewność, że żadna nie trwa, usuń zapis instalacji, a potem otwórz Atlas ponownie.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas nie mógł ustalić, czy wcześniejsza instalacja nadal trwa. Jeśli nie masz pewności, poproś o pomoc społeczność Atlasa. Tylko jeśli masz pewność, że żadna instalacja nie trwa, usuń plik { $path } i spróbuj ponownie. Szczegóły: { $error }

## Uprawnienia administratora

elevation-declined = Nie udzielono uprawnień. Spróbuj ponownie i wybierz Tak, gdy Windows zapyta, czy zezwolić aplikacji Atlas na wprowadzanie zmian.
elevation-declined-continue = Nie udzielono uprawnień. Spróbuj ponownie i wybierz Tak, gdy Windows zapyta, czy zezwolić aplikacji Atlas na wprowadzanie zmian. Wybrane opcje instalacji zostały zapisane.
elevation-draft-not-saved = Atlas nie mógł zapisać wybranych opcji instalacji, więc nie otworzył się ponownie. Spróbuj ponownie. Szczegóły: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Inne okno Atlasa używa teraz tej konfiguracji, więc Atlas nie otworzył się ponownie. Kontynuuj w tamtym oknie albo wybierz Zacznij od nowa, aby skonfigurować wszystko ponownie tutaj.

## Przebieg instalacji

step-ready = Przygotowanie
step-options = Opcje
step-security = Zabezpieczenia Windows
step-install = Instalacja
install-title = Skonfiguruj Atlas
# Accessible name of the row of steps.
stepper-label = Kroki instalacji Atlasa
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = ukończono
stepper-status-current = bieżący krok
stepper-status-upcoming = kolejny krok
# A step already visited whose requirements aren't met yet.
stepper-status-attention = wymaga uwagi
# Names the step showing; read when the current step takes focus.
step-heading = Krok { $number } z { $total }: { $title }
# Accessible name of the current step on Your choices. $heading is stepper-item-a11y;
# $questions is what the screen asks.
step-heading-choices-a11y = { $heading }. { $questions }

## Krok 1: Przygotowanie
## One checklist with three rows: the checks, the Atlas package and the updates.

# Row title, as a checklist item.
ready-checks-title = Sprawdzenie komputera
# Status line while the checks run.
ready-checks-running = Sprawdzanie komputera…
ready-check-again = Sprawdź ponownie
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [one] { $count } sprawdzenie zakończone pomyślnie
        [few] { $count } sprawdzenia zakończone pomyślnie
        [many] { $count } sprawdzeń zakończonych pomyślnie
       *[other] { $count } sprawdzeń zakończonych pomyślnie
    }
# Status line when some checks need attention, which are listed under it.
ready-checks-passed-some =
    { $total ->
        [one] Zakończono pomyślnie { $passed } z { $total } sprawdzenia
        [few] Zakończono pomyślnie { $passed } z { $total } sprawdzeń
        [many] Zakończono pomyślnie { $passed } z { $total } sprawdzeń
       *[other] Zakończono pomyślnie { $passed } z { $total } sprawdzenia
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of: "Zakończono pomyślnie 5 z 9 sprawdzeń · 4 zostaną rozwiązane przez aktualizowanie".
# $count is how many; the participle agrees with "sprawdzenie".
ready-checks-handled =
    { $count ->
        [one] { $count } zostanie rozwiązane przez aktualizowanie
        [few] { $count } zostaną rozwiązane przez aktualizowanie
        [many] { $count } zostanie rozwiązanych przez aktualizowanie
       *[other] { $count } zostanie rozwiązanych przez aktualizowanie
    }
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = rozwiąże to aktualizowanie
# Under the title of a check that updating takes care of.
check-updates-handled = Aktualizacje czekają na instalację. Atlas zainstaluje je podczas aktualizowania Windows.
check-restart-handled = Windows wymaga ponownego uruchomienia, aby dokończyć wcześniejsze zmiany. Rozwiąże to aktualizowanie.
check-handled = Rozwiąże to aktualizowanie.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Pobieranie…
ready-package-unpacking = Rozpakowywanie…
ready-package-ready = Gotowe
ready-package-checking = Sprawdzanie najnowszej wersji…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Przygotowywanie dołączonego pakietu Atlasa…
ready-package-none = Jeszcze nie pobrano
ready-package-failed = Nie udało się przygotować pakietu Atlasa
# Under ready-package-failed, with package-download-again and package-open-file.
ready-package-failed-detail = Pobierz go ponownie albo otwórz inny pakiet Atlasa (.atlaspkg).
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = Nie udało się rozpakować pakietu Atlasa dołączonego do tej wersji testowej. Spróbuj ponownie.
ready-package-manager = Wymaga nowszej wersji aplikacji Atlas Manager
ready-package-release-failed = Nie udało się sprawdzić najnowszej wersji
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Sprawdź połączenie z internetem i spróbuj ponownie. Jeśli masz pakiet Atlasa (.atlaspkg), możesz go otworzyć.
# Row title.
ready-updates-title = Aktualizacje Windows i Microsoft Store
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Aplikacje ze sklepu, takie jak Notatnik, mogą zostać zamknięte podczas aktualizacji. Najpierw zapisz w nich pracę.
# Status line while Windows moves to version $release.
ready-updates-after-move = Rozpocznie się po przejściu Windows na wersję { $release }.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Kontynuowanie po ponownym uruchomieniu…
ready-updates-restarting = Ponowne uruchamianie komputera…
ready-updates-done = Windows i aplikacje ze sklepu są aktualne.
# Instead of ready-updates-done where Microsoft Store is turned off.
ready-updates-done-windows = Windows jest aktualny.
# The countdown before the restart updating needs. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Komputer uruchomi się ponownie za { $seconds } sekundę.
        [few] Komputer uruchomi się ponownie za { $seconds } sekundy.
        [many] Komputer uruchomi się ponownie za { $seconds } sekund.
       *[other] Komputer uruchomi się ponownie za { $seconds } sekundy.
    }
ready-updates-restart = Komputer wymaga ponownego uruchomienia, aby dokończyć aktualizowanie.
ready-updates-restart-finish = Windows wymaga jeszcze jednego ponownego uruchomienia, aby dokończyć instalowanie wersji { $release }.
ready-updates-restart-failed = Komputer nie uruchomił się ponownie
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Najpierw zapisz pracę.
ready-updates-restart-persists = Windows nadal wymaga ponownego uruchomienia
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Kolejne ponowne uruchomienie raczej nie pomoże. Dokończ wszystko, co czeka w Windows Update, a potem spróbuj ponownie.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Przyczyny ponownego uruchomienia: { $reasons }
ready-updates-network = Aktualizacje nie mogą korzystać z tego połączenia
ready-updates-stopped = Zatrzymano aktualizowanie. Część aktualizacji mogła już zostać zainstalowana.
ready-updates-previous = Oczekiwanie na wcześniej rozpoczęte aktualizacje…
# Button after the user stopped updating.
ready-updates-resume = Wznów aktualizacje
ready-updates-start = Rozpocznij aktualizowanie
# Why updating hasn't started, under the row.
ready-updates-blocked = Aktualizacje zaczekają, aż instalacja Atlasa na tym komputerze będzie możliwa.
ready-updates-needs-admin = Rozpocznie się, gdy Atlas otrzyma uprawnienia administratora.
ready-updates-needs-windows = Rozpocznie się, gdy zgodność z Windows zostanie potwierdzona.
ready-updates-needs-drivers = Rozpocznie się, gdy zdecydujesz, jak instalować sterowniki.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual.
ready-drivers-row = Sterowniki: { $choice }
ready-drivers-automatic = Przez Windows Update
ready-drivers-manual = Zainstaluję je samodzielnie
ready-drivers-change-a11y = Zmień sposób instalowania sterowników
# Under the two answers, once updating has run.
ready-drivers-again = Po zmianie tego ustawienia Atlas ponownie przeprowadzi aktualizacje.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Pobieranie Atlasa { $version } · { $received } z { $total } MB
package-unpacking = Rozpakowywanie
package-status-ready = Gotowe
# Accessible name of the progress bar.
package-progress = Postęp przygotowania pakietu Atlasa
package-download-again = Pobierz ponownie
package-download-version = Pobierz Atlas { $version }
package-download-newest = Pobierz najnowszą wersję
package-cancel-download = Anuluj pobieranie
package-open-file = Otwórz plik pakietu
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } został pobrany z serwisu GitHub i jest gotowy do instalacji.
package-from-file = Atlas { $version } został wczytany z pliku { $file } i jest gotowy do instalacji.
package-unpacked = Atlas { $version } jest gotowy do instalacji.
package-none-yet = Nie ma jeszcze pakietu Atlasa
acquire-no-asset = Atlas { $version } nie ma pliku pakietu do pobrania. Aby kontynuować, otwórz zapisany pakiet Atlasa (.atlaspkg).
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Ta aplikacja instaluje Atlas w wersji 0.6.0 i nowszych z pakietów Atlasa (.atlaspkg).
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = To jest obraz ISO Windows, a nie pakiet Atlasa (.atlaspkg). Aby zainstalować ponownie Windows z Atlasem, utwórz z niego ISO z Atlasem.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = W Atlasie { $version } brakuje plików, których ta aplikacja potrzebuje, aby go zainstalować. Pobierz go ponownie albo otwórz inny pakiet Atlasa (.atlaspkg).
acquire-failed = Nie udało się przygotować pakietu Atlasa. Pobierz go ponownie albo otwórz inny pakiet Atlasa (.atlaspkg). Szczegóły: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Pobieranie przestało odpowiadać. Sprawdź połączenie z internetem, a potem spróbuj pobrać ponownie albo otwórz zapisany pakiet Atlasa (.atlaspkg).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Nie udało się przygotować dołączonego pakietu Atlasa. Wybierz Spróbuj ponownie. Szczegóły: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks
# for, such as 0.7.0. Pobierz Atlas Manager (manager-download) is beside it. "jej" is the new
# version downloaded, and "tej" the version running now, as in manager-update-message.
acquire-manager-update-needed = Ten pakiet Atlasa wymaga nowszej wersji aplikacji Atlas Manager. Pobierz Atlas Manager w wersji { $version } lub nowszej i używaj jej zamiast tej.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Ten pakiet Atlasa wymaga nowszej wersji aplikacji Atlas Manager. Pobierz najnowszą wersję aplikacji Atlas Manager i używaj jej zamiast tej.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
acquire-manager-update-required = Aby zainstalować Atlas { $version }, pobierz Atlas Manager w wersji { $required } lub nowszej i używaj jej zamiast tej.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Aby zainstalować Atlas { $version }, pobierz najnowszą wersję aplikacji Atlas Manager i używaj jej zamiast tej.

## Nowszy Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Pobierz Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Dostępny jest Atlas Manager { $version }
manager-update-message = Atlas Manager nie może zaktualizować się sam. Pobierz nową wersję i używaj jej zamiast tej.

## Sprawdzanie systemu

check-administrator = Uprawnienia do instalacji
check-supported-build = Zgodność z Windows
check-pending-updates = Aktualizacje Windows
check-pending-reboot = Oczekujące ponowne uruchomienie
check-third-party-antivirus = Inne programy antywirusowe
check-internet = Połączenie z internetem
check-power = Zasilanie
check-activation = Aktywacja Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Wymagania sprzętowe Windows 11
check-move-space = Wolne miejsce
check-move-update-source = Źródło aktualizacji
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = sprawdzanie
check-state-passed = w porządku
check-state-warning = wymaga uwagi
check-state-failed-blocking = wymaga działania przed instalacją
check-state-failed = wymaga uwagi
check-state-unknown = nie udało się sprawdzić
check-fix-windows-update = Otwórz Windows Update
check-fix-network = Otwórz ustawienia sieci
check-fix-power = Otwórz ustawienia zasilania
check-fix-activation = Otwórz ustawienia aktywacji
# Opens Storage ("Magazyn") in Windows Settings, where space is freed up.
check-fix-storage = Otwórz ustawienia magazynu
# Opens Installed apps ("Zainstalowane aplikacje") in Windows Settings, from the Other antivirus
# software check; the same page as in fixed-installed.
check-fix-installed-apps = Otwórz Zainstalowane aplikacje
# Check box the user ticks when the Windows Update scan could not run. "Potwierdzam, że"
# keeps the first person without a gendered past-tense verb.
check-ack-updates = Potwierdzam, że w Windows Update żadne aktualizacje nie czekają na instalację

detail-admin-ok = Atlas ma uprawnienia do wprowadzenia zmian potrzebnych do instalacji.
detail-admin-missing = Otwórz Atlas ponownie jako administrator i wybierz Tak, gdy Windows poprosi o zezwolenie.
# $builds is a list of build numbers such as "26100 lub 26200"; $build is this PC's (text).
detail-build-unsupported = Ta wersja Atlasa wymaga kompilacji Windows { $builds }. Ten komputer ma kompilację { $build }. Zainstaluj obsługiwaną wersję Windows, zanim przejdziesz dalej.
detail-build-missing = Ten pakiet Atlasa nie podaje obsługiwanych kompilacji Windows. Użyj pełnej wersji pakietu zamiast wersji LocalTest.
detail-updates-none = Żadne aktualizacje Windows nie czekają na instalację.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } aktualizacja nadal czeka na instalację. Zainstaluj ją w Windows Update, a potem sprawdź ponownie.
        [few] { $count } aktualizacje nadal czekają na instalację. Zainstaluj je w Windows Update, a potem sprawdź ponownie.
        [many] { $count } aktualizacji nadal czeka na instalację. Zainstaluj je w Windows Update, a potem sprawdź ponownie.
       *[other] { $count } aktualizacji nadal czeka na instalację. Zainstaluj je w Windows Update, a potem sprawdź ponownie.
    }
detail-updates-scan-failed = Nie udało się sprawdzić aktualizacji Windows. Otwórz Windows Update, aby zobaczyć, czy jakieś czekają na instalację. ({ $error })
detail-reboot-none = Windows nie wymaga teraz ponownego uruchomienia.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows wymaga ponownego uruchomienia, aby dokończyć wcześniejsze zmiany. Uruchom komputer ponownie i sprawdź jeszcze raz.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows wymaga ponownego uruchomienia, aby dokończyć wcześniejsze zmiany ({ $reasons }). Uruchom komputer ponownie i sprawdź jeszcze raz.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Możesz kontynuować. Windows ma pliki do zastąpienia lub usunięcia przy następnym ponownym uruchomieniu ({ $files }). Niektóre aplikacje, na przykład Xbox Gaming Services, oznaczają takie pliki po każdym ponownym uruchomieniu.
detail-reboot-unknown = Nie udało się sprawdzić, czy Windows wymaga ponownego uruchomienia. Uruchom komputer ponownie, a potem otwórz Atlas i sprawdź ponownie. ({ $error })
detail-antivirus-none = Nie wykryto innego oprogramowania antywirusowego.
# $products is a list of product names (text). The row offers check-fix-apps.
detail-antivirus-uninstall = Aplikacje antywirusowe inne niż Microsoft Defender mogą blokować instalację. Odinstaluj { $products }, a potem sprawdź ponownie.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Zabezpieczenia Windows nadal wymieniają { $products }, ale pliki tego programu już nie istnieją, więc nie jest on już zainstalowany. Atlas można mimo to zainstalować.
detail-antivirus-check-failed = Nie udało się sprawdzić, czy jest zainstalowane inne oprogramowanie antywirusowe. Jeśli to się powtarza, uruchom komputer ponownie i sprawdź jeszcze raz. ({ $error })
detail-internet-ok = Masz połączenie z internetem. Nie przerywaj go, gdy Atlas będzie pobierać i instalować oprogramowanie.
detail-internet-missing = Połącz się z internetem, a potem sprawdź ponownie.
detail-power-mains = Komputer jest podłączony do zasilania. Nie odłączaj go do końca instalacji.
detail-power-battery = Podłącz komputer do zasilania, aby nie wyłączył się w trakcie instalacji.
detail-power-check-failed = Atlas nie mógł ustalić, czy komputer jest podłączony do zasilania. Jeśli to laptop, podłącz go, a potem sprawdź ponownie.
detail-activation-ok = Windows jest aktywowany. Atlas tego nie zmieni.
detail-activation-missing = Windows nie jest aktywowany. Możesz kontynuować, ale Atlas nie aktywuje Windows za Ciebie.
detail-activation-no-licence = Windows nie zgłosił licencji. Możesz kontynuować, Atlas nie zmieni stanu aktywacji.
detail-activation-unknown = Nie udało się sprawdzić aktywacji Windows. Możesz kontynuować, Atlas nie zmieni stanu aktywacji. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Na tym komputerze Atlas nie musi aktualizować Windows do nowszej wersji.
detail-move-hardware-ready = Ten komputer ma moduł TPM 2.0 i oprogramowanie układowe UEFI wymagane przez Windows 11.
detail-move-hardware-missing = Ten komputer nie ma wymaganego sprzętu ({ $missing }), więc Windows Update nie zaktualizuje go do wersji { $release }. Zrób kopię zapasową plików, a potem zainstaluj ponownie Windows z obrazu ISO z Atlasem.
detail-move-hardware-unread = Atlas nie mógł odczytać wszystkich informacji o sprzęcie, więc sprawdzi to Windows Update.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = Na dysku { $drive } jest { $free } GB wolnego miejsca.
detail-move-space-short = Wersja { $release } wymaga { $needed } GB wolnego miejsca na dysku { $drive }, a jest tam { $free } GB. Zwolnij miejsce, a Atlas sam sprawdzi ponownie.
detail-move-space-unknown = Nie udało się sprawdzić wolnego miejsca na potrzeby aktualizacji Windows. Uruchom komputer ponownie i sprawdź jeszcze raz. ({ $error })
detail-move-update-source-ok = Ten komputer pobiera aktualizacje z Windows Update.
detail-move-update-source-managed = Ten komputer pobiera aktualizacje z serwera organizacji, który nie udostępnia wersji { $release }. Zwróć się do organizacji albo zainstaluj ponownie Windows z obrazu ISO z Atlasem.

## Krok 2: Opcje
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices.
options-change-later = Ustawienia Microsoft Defender, zabezpieczeń procesora i aktualizacji możesz później zmienić w folderze Atlas na pulpicie.
# The status line of the folded Optional extras card.
options-extras-none = Nic nie wybrano
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked =
    { $count ->
        [one] { $count } wybrany
        [few] { $count } wybrane
        [many] { $count } wybranych
       *[other] { $count } wybranych
    }
# Links that unfold and fold the Optional extras card.
options-extras-show = Pokaż
options-extras-hide = Ukryj
# Under each question's title, one sentence at most.
question-defender-description = Microsoft Defender to program antywirusowy wbudowany w Windows.
question-mitigations-description = Te zabezpieczenia, nazywane też środkami zaradczymi, chronią przed lukami w procesorach, takimi jak Spectre i Meltdown, oraz przed atakami wykorzystującymi błędy w aplikacjach.
question-auto-updates-description = W obu przypadkach Atlas pozostawia Windows w bieżącej wersji i wyłącza automatyczne aktualizacje aplikacji z Microsoft Store.
question-browser-description = Atlas nie zmieni ustawień przeglądarki.
# One line under an answer other than the recommended one: what it costs.
cost-defender-disable = Komputer nie będzie mieć programu antywirusowego, dopóki nie zainstalujesz innego, a Windows przestanie Cię ostrzegać przed otwieraniem nierozpoznanych aplikacji i pobranych plików.
# "Exploit protection" is the Windows Security page of that name.
cost-mitigations-disable = Wyłącza też Ochronę przed lukami w zabezpieczeniach dla aplikacji, na przykład Ochronę przepływu sterowania (CFG), co zmniejsza bezpieczeństwo.
cost-auto-updates-disable = Regularnie otwieraj Windows Update, aby instalować poprawki zabezpieczeń.
cost-auto-updates-default = Windows może uruchamiać komputer ponownie, aby dokończyć instalowanie aktualizacji.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift i Ctrl+Shift nie będą już przełączać języków ani układów.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Zwalnia miejsce na dysku, ale hibernacja i szybkie uruchamianie będą niedostępne.
extra-disable-power-saving = Komputer może zużywać więcej energii, mocniej się nagrzewać i krócej działać na baterii.
extra-disable-core-isolation = Zmniejsza to ochronę, a gry korzystające z systemów anti-cheat, takich jak Riot Vanguard czy FACEIT, mogą się nie uruchomić, dopóki nie włączysz ponownie integralności pamięci.
extra-uninstall-edge = Zakładki, historia i zapisane hasła przeglądarki Edge na tym komputerze zostaną usunięte, z wyjątkiem danych zsynchronizowanych z kontem Microsoft.
extra-install-toolbox = Pomaga zarządzać ustawieniami Atlasa, ale w wersji beta niektóre funkcje mogą być niedokończone.
extra-install-eclean = Narzędzie od zespołu AtlasOS do przeglądania zbędnych plików i aplikacji startowych, wymagające konta i połączenia z internetem.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Zachować Microsoft Defender?
screen-mitigations-title = Zabezpieczenia procesora
screen-mitigations-question = Zachować zabezpieczenia procesora w Windows?
screen-updates-title = Windows Update
screen-updates-question = Jak Windows ma instalować aktualizacje?
screen-browser-title = Przeglądarka
screen-power-title = Zasilanie i zabezpieczenia
screen-apps-title = Aplikacje
screen-optional-apps-title = Opcjonalne aplikacje
screen-choose-one-title = Wybierz opcję
screen-extras-title = Opcjonalne dodatki
# Each decision's short name mid-sentence, as in summary-change-a11y and update-path-differs.
# They follow a colon there, so they stay in the nominative and in lower case.
screen-update-path-name = sposób aktualizacji Atlasa
screen-defender-name = Microsoft Defender
screen-mitigations-name = zabezpieczenia procesora
screen-updates-name = Windows Update
screen-keyboard-name = języki klawiatury
screen-browser-name = przeglądarka
screen-power-name = zasilanie i zabezpieczenia
screen-apps-name = aplikacje
screen-optional-apps-name = opcjonalne aplikacje
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = opcja z pakietu Atlasa
screen-extras-name = opcjonalne dodatki
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wybierz opcję dla: { $title }
learn-more-defender = Dowiedz się więcej o Microsoft Defender
learn-more-mitigations = Dowiedz się więcej o zabezpieczeniach procesora
learn-more-updates = Dowiedz się więcej o Windows Update
learn-more-browser = Dowiedz się więcej o przeglądarkach
learn-more-power = Dowiedz się więcej o zasilaniu i zabezpieczeniach
learn-more-apps = Dowiedz się więcej o aplikacjach
learn-more-eclean = Dowiedz się więcej o eclean
learn-more-keyboard = Dowiedz się więcej o językach klawiatury
learn-more-generic = Przeczytaj przewodnik konfiguracji
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Zachowuje wbudowany program antywirusowy Windows, który pomaga chronić komputer przed wirusami i innymi zagrożeniami.
consequence-mitigations-default = Zachowuje domyślne zabezpieczenia Windows chroniące przed lukami w procesorach i atakami wykorzystującymi błędy w aplikacjach.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page of that name.
consequence-mitigations-disable = Wyłącza też Ochronę przed lukami w zabezpieczeniach dla aplikacji, na przykład Ochronę przepływu sterowania (CFG). Zmniejsza to bezpieczeństwo. Ewentualna różnica w wydajności zależy od procesora.
consequence-auto-updates-disable = Regularnie otwieraj Windows Update, aby instalować aktualizacje. Powiadomienia o aktualizacjach pozostaną włączone.
consequence-auto-updates-default = Windows będzie automatycznie instalować aktualizacje, w tym poprawki zabezpieczeń.

## Krok 2 przy aktualizacji lub ponownej instalacji Atlasa

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Jak chcesz zaktualizować Atlas do wersji { $version }?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Jak chcesz ponownie zainstalować Atlas { $version }?
# The two answers on that screen. Other messages name them too, so keep each the same everywhere.
update-path-keep = Zachowaj moje opcje
update-path-keep-detail = Atlas zachowa każdą opcję tak, jak jest teraz ustawiona na tym komputerze, i żadnej nie zmieni.
update-path-choose = Wybierz ponownie
update-path-choose-detail = Zacznij od obecnej konfiguracji tego komputera. Twoje aplikacje, pliki i personalizacja pozostaną bez zmian.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Obecne opcje na tym komputerze
# The value of a row for a choice nothing on the PC shows.
update-path-unknown = Atlas nie może tego odczytać z komputera, więc zapyta Cię o to
# Above that list. $choices lists screen-*-name messages, joined with list-and.
update-path-differs = Zapis Atlasa nie zgadza się ze stanem tego komputera w tych kwestiach: { $choices }.
# A line above the questions Keep my choices still asks.
keep-choices-asked = Pozostałe opcje Atlas zachowa tak, jak są teraz ustawione na tym komputerze.
# A short tag under the answer this PC has now, on the screens of Choose again.
option-now = Obecnie na tym komputerze
# Under an answer on a screen of Choose again when choosing it changes this PC.
change-defender-enable = Atlas przywróci Microsoft Defender. Po ponownym uruchomieniu włącz jego ochronę w Zabezpieczeniach Windows.
change-mitigations-default = Atlas ponownie włączy zabezpieczenia procesora zgodnie z ustawieniami domyślnymi Windows. Zmiana zacznie obowiązywać po ponownym uruchomieniu.
# Under Keep processor protections when every protection is turned on.
change-mitigations-all-on = Wszystkie zabezpieczenia procesora są teraz włączone. Jeśli je zachowasz, wszystkie pozostaną włączone.
change-auto-updates-default = Atlas znów pozwoli Windows automatycznie instalować aktualizacje.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas ponownie włączy hibernację.
change-power-saving-on = Atlas ponownie włączy oszczędzanie energii i przywróci poprzedni plan zasilania, a jeśli go nie ma, plan Zrównoważony.
change-core-isolation-on = Atlas ponownie włączy zabezpieczenia oparte na wirtualizacji (VBS), chyba że steruje nimi zasada na tym komputerze. Zmiana zacznie obowiązywać po ponownym uruchomieniu.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Usuwa Narzędzie Wycinanie dla wszystkich użytkowników tego komputera. Atlas nie będzie mógł go później przywrócić, ale możesz zainstalować je ponownie z Microsoft Store.
# Under a box Choose again shows ticked and can't clear. Install or Remove Edge is a file name
# in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Przeglądarka Microsoft Edge jest już usunięta, a aktualizacja Atlasa nie może jej przywrócić. Aby zainstalować ją ponownie, użyj Install or Remove Edge w folderze Atlas.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
fixed-installed = Aplikacja { $app } jest zainstalowana. Atlas nie odinstalowuje aplikacji. Aby ją usunąć, otwórz stronę Zainstalowane aplikacje w Ustawieniach Windows.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = Przeglądarka { $installed } pozostanie zainstalowana, a Atlas zainstaluje dodatkowo { $browser }.

## Tekst pakietu Atlasa
## Etykiety i opisy opcji oraz pytań pakietu Atlasa, według ich identyfikatorów
## w pliku atlas.json pakietu. Aplikacja pokazuje je zamiast angielskiego tekstu
## pakietu; opcja lub pytanie dodane przez nowszy pakiet, bez komunikatu tutaj,
## pokazuje angielski tekst pakietu. Forma -short to ta sama odpowiedź bez
## zalecenia, do podsumowania, strony głównej i zapisów.

package-option-defender-enable = Zachowaj Microsoft Defender (zalecane)
package-option-defender-enable-short = Zachowaj Microsoft Defender
package-option-defender-disable = Usuń Microsoft Defender
package-option-mitigations-default = Zachowaj zabezpieczenia procesora (zalecane)
package-option-mitigations-default-short = Zachowaj zabezpieczenia procesora
package-option-mitigations-disable = Wyłącz zabezpieczenia procesora
package-option-auto-updates-disable = Będę instalować aktualizacje samodzielnie
package-option-auto-updates-default = Instaluj aktualizacje automatycznie
package-option-disable-hibernation = Wyłącz hibernację
package-option-disable-power-saving = Wyłącz oszczędzanie energii
package-option-disable-core-isolation = Wyłącz zabezpieczenia oparte na wirtualizacji (VBS)
package-option-remove-snipping-tool = Usuń Narzędzie Wycinanie
package-option-uninstall-edge = Usuń Microsoft Edge
package-option-install-another-browser = Zainstaluj przeglądarkę
package-option-install-toolbox = Zainstaluj Atlas Toolbox
package-option-install-eclean = Zainstaluj eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender to program antywirusowy wbudowany w Windows. Usuń go tylko wtedy, gdy rozumiesz ryzyko i zamierzasz używać innej aplikacji antywirusowej. Niezależnie od wyboru Atlas wyłącza Inteligentną kontrolę aplikacji, Rozszerzoną ochronę przed wyłudzaniem informacji i funkcję Znajdź moje urządzenie.
package-choice-mitigations-description = Te zabezpieczenia, nazywane też środkami zaradczymi, pomagają chronić przed lukami w procesorach, takimi jak Spectre i Meltdown, oraz przed atakami wykorzystującymi błędy w aplikacjach. Zalecane jest zachowanie ustawień domyślnych Windows.
package-choice-auto-updates-description = Aktualizacje Windows zawierają poprawki zabezpieczeń. Windows może instalować je automatycznie albo możesz instalować je samodzielnie. W obu przypadkach Atlas pozostawia Windows w bieżącej wersji, która otrzymuje poprawki zabezpieczeń tylko do czasu, gdy Microsoft zakończy jej obsługę. Atlas wyłącza też automatyczne aktualizacje aplikacji z Microsoft Store, więc aktualizuj je w Microsoft Store.
package-choice-browser-description = Wybierz przeglądarkę do zainstalowania. Atlas nie zmieni ustawień przeglądarki.

## Krok 3: Zabezpieczenia Windows

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender nie jest zainstalowany na tym komputerze
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Nie ma przełączników ochrony do wyłączenia.
# When Atlas's own package removed Microsoft Defender and it stays removed.
security-banner-removed-title = Atlas usunął Microsoft Defender z tego komputera
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas przywróci Microsoft Defender podczas tej instalacji
security-restore-nothing-to-turn-off = Defender jeszcze nie działa, więc nie ma nic do wyłączenia. Po ponownym uruchomieniu włącz jego ochronę w Zabezpieczeniach Windows.
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it.
security-banner-missing-title = Brak Microsoft Defender
security-banner-missing-message = Atlas go nie usunął, więc nie może go przywrócić. Możesz kontynuować, ale komputer nie będzie mieć ochrony antywirusowej, dopóki nie zainstalujesz innej aplikacji antywirusowej lub nie naprawisz Windows.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches.
security-turn-off-title = Wyłącz te cztery przełączniki
security-turn-off-message = Microsoft Defender może blokować Atlas podczas instalacji. Jeśli zachowujesz Defender, po instalacji włącz je ponownie.
# The page name in Windows Security.
security-list-title = Ustawienia ochrony przed wirusami i zagrożeniami
security-switch-off = Wyłączone
security-switch-on = Włączone
security-switch-unreadable = Nie udało się odczytać
security-switch-reading = Sprawdzanie
security-all-off = Wszystkie wyłączone
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 nadal włączone, 1 nieodczytany".
security-count-still-on =
    { $count ->
        [one] { $count } nadal włączony
        [few] { $count } nadal włączone
        [many] { $count } nadal włączonych
       *[other] { $count } nadal włączonych
    }
security-count-unreadable =
    { $count ->
        [one] { $count } nieodczytany
        [few] { $count } nieodczytane
        [many] { $count } nieodczytanych
       *[other] { $count } nieodczytanych
    }
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# joined with list-and; $count is how many there are.
security-unread-switches-title =
    { $count ->
        [one] Atlas nie mógł odczytać przełącznika: { $switches }
        [few] Atlas nie mógł odczytać przełączników: { $switches }
        [many] Atlas nie mógł odczytać przełączników: { $switches }
       *[other] Atlas nie mógł odczytać przełączników: { $switches }
    }
security-unread-message =
    { $count ->
        [one] Upewnij się, że ten przełącznik jest wyłączony w Zabezpieczeniach Windows.
        [few] Upewnij się, że te przełączniki są wyłączone w Zabezpieczeniach Windows.
        [many] Upewnij się, że te przełączniki są wyłączone w Zabezpieczeniach Windows.
       *[other] Upewnij się, że te przełączniki są wyłączone w Zabezpieczeniach Windows.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] Potwierdzam, że ten przełącznik jest wyłączony: { $switches }
        [few] Potwierdzam, że te przełączniki są wyłączone: { $switches }
        [many] Potwierdzam, że te przełączniki są wyłączone: { $switches }
       *[other] Potwierdzam, że te przełączniki są wyłączone: { $switches }
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Potwierdzam, że w Zabezpieczeniach Windows wszystkie cztery przełączniki są wyłączone
security-unknown-unelevated-title = Atlas potrzebuje uprawnień, aby sprawdzić ochronę
security-unknown-unelevated-message = Otwórz Atlas ponownie jako administrator, aby mógł sprawdzić ustawienia Microsoft Defender.
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = Ochrona przed naruszeniami
protection-tamper-why = Aby Atlas mógł zmienić ustawienia zabezpieczeń.
protection-realtime = Ochrona w czasie rzeczywistym
protection-realtime-reason = Skanowanie może blokować pliki Atlasa.
protection-cloud = Ochrona dostarczana z chmury
protection-cloud-reason = Sprawdzanie online może blokować pliki Atlasa.
protection-samples = Automatyczne przesyłanie próbek
protection-samples-why = Aby pliki Atlasa nie były wysyłane do firmy Microsoft.

## Krok 4: Instalacja

outcome-succeeded-title = Atlas jest zainstalowany
outcome-lost-title = Nie udało się potwierdzić wyniku instalacji
outcome-failed-title = Instalacja nie została ukończona
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button is the next step, so the message never names it.
# Beside go-to-ready.
result-requirements = Komputer nie spełnił wymagań instalacji, więc instalacja niczego nie zmieniła.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Komputer nie spełnił wymagań instalacji, więc ta próba została przerwana. Wcześniejsza próba wprowadziła już zmiany.
# Beside common-restart-as-administrator.
result-not-elevated = Atlas nie miał uprawnień administratora, więc instalacja niczego nie zmieniła.
result-not-elevated-resumed = Atlas nie miał uprawnień administratora, więc ta próba została przerwana. Wcześniejsza próba wprowadziła już zmiany.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready.
result-preparation-stale = Atlas nie mógł potwierdzić, że Windows i aplikacje ze sklepu są aktualne, więc instalacja zatrzymała się przed wprowadzeniem zmian w Windows.
result-preparation-stale-resumed = Atlas nie mógł potwierdzić, że Windows i aplikacje ze sklepu są aktualne, więc ta próba została przerwana. Wcześniejsza próba wprowadziła już zmiany.
result-failed-preflight = Instalacja zatrzymała się, zanim cokolwiek zmieniła. Możesz spróbować ponownie.
result-failed-staging = Instalacja zatrzymała się podczas przygotowywania plików, przed wprowadzeniem zmian w Windows. Możesz spróbować ponownie.
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = Część zmian mogła już zostać wprowadzona. Możesz spróbować ponownie, a jeśli na tym poprzestaniesz, włącz ponownie przełączniki ochrony w Zabezpieczeniach Windows.
# The -defender-removed variants once Microsoft Defender has been removed.
result-failed-applying-defender-removed = Część zmian mogła już zostać wprowadzona. Możesz spróbować ponownie.
result-failed-resumed = Ta próba została wcześnie przerwana, ale wcześniejsza próba wprowadziła już zmiany. Możesz spróbować ponownie, a jeśli na tym poprzestaniesz, włącz ponownie przełączniki ochrony w Zabezpieczeniach Windows.
result-failed-resumed-defender-removed = Ta próba została wcześnie przerwana, ale wcześniejsza próba wprowadziła już zmiany. Możesz spróbować ponownie.
# The -repeated variants follow a retry that stopped with the same error as the attempt before
# it. "Wyślij zgłoszenie" is report-title, in the row of links under the bar.
result-failed-repeated = Ta próba zatrzymała się na tym samym błędzie co poprzednia, więc ponowna próba raczej nie pomoże. Wyślij zgłoszenie, aby zespół Atlasa mógł znaleźć przyczynę, a jeśli na tym poprzestaniesz, włącz ponownie przełączniki ochrony.
result-failed-repeated-defender-removed = Ta próba zatrzymała się na tym samym błędzie co poprzednia, więc ponowna próba raczej nie pomoże. Wyślij zgłoszenie, aby zespół Atlasa mógł znaleźć przyczynę.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows nadal nie usunął aplikacji { $apps }, więc ponowna próba raczej nie pomoże. Wyślij zgłoszenie, aby zespół Atlasa mógł znaleźć przyczynę, a jeśli na tym poprzestaniesz, włącz ponownie przełączniki ochrony.
result-failed-repeated-apps-defender-removed = Windows nadal nie usunął aplikacji { $apps }, więc ponowna próba raczej nie pomoże. Wyślij zgłoszenie, aby zespół Atlasa mógł znaleźć przyczynę.
result-not-started = Instalator nie uruchomił się na czas, więc instalacja niczego nie zmieniła. Możesz spróbować ponownie.
result-lost = Instalator zatrzymał się bez zgłoszenia wyniku, więc część zmian mogła zostać wprowadzona. Możesz spróbować ponownie, a jeśli na tym poprzestaniesz, włącz ponownie przełączniki ochrony w Zabezpieczeniach Windows.
# Instead of result-lost once Defender is gone.
result-lost-defender-removed = Instalator zatrzymał się bez zgłoszenia wyniku, więc część zmian mogła zostać wprowadzona. Możesz spróbować ponownie.
restart-now-message = Windows uruchamia się ponownie, aby dokończyć konfigurację Atlasa.
restart-stopped = Anulowano automatyczne ponowne uruchomienie. Zapisz pracę, a potem uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
restart-needed = Zapisz pracę, a potem uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
restart-dont-now = Uruchom ponownie później
restart-now = Uruchom ponownie teraz
# The bar when the final checks refuse to start the installer. The bar's button is the fix,
# and raw errors are behind Show details.
preflight-title = Instalacja się nie rozpoczęła
# Beside go-to-options. $choice is a screen-*-name message, after a colon so it stays in the
# nominative, such as zabezpieczenia procesora.
preflight-choice-unanswered = Atlas potrzebuje Twojej odpowiedzi na pytanie: { $choice }.
preflight-choices-unusable = Atlas nie mógł użyć tych opcji.
# Beside go-to-ready. $checks lists check-* names joined with list-and; $count is how many.
preflight-checks-changed =
    { $count ->
        [one] Od ostatniego sprawdzenia komputera uwagi wymaga: { $checks }.
        [few] Od ostatniego sprawdzenia komputera uwagi wymagają: { $checks }.
        [many] Od ostatniego sprawdzenia komputera uwagi wymagają: { $checks }.
       *[other] Od ostatniego sprawdzenia komputera uwagi wymagają: { $checks }.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 nadal włączony".
preflight-security-changed = Stan Zabezpieczeń Windows zmienił się od wyłączenia przełączników: { $summary }.
preflight-busy-wait = Inne okno Atlasa rozpoczyna instalację. Poczekaj chwilę, a potem spróbuj ponownie.
# Beside home-start-over.
preflight-taken-over-start-over = Inne okno Atlasa używa teraz tej konfiguracji. Kontynuuj w tamtym oknie albo zacznij od nowa tutaj.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas nie mógł sprawdzić, czy wcześniejsza instalacja nadal trwa, więc nie rozpoczął kolejnej.
preflight-not-started = Atlas nie mógł uruchomić instalatora, więc instalacja niczego nie zmieniła. Możesz spróbować ponownie.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas nie mógł uruchomić instalatora, ale wcześniejsza próba wprowadziła już zmiany. Możesz spróbować ponownie.
go-to-ready = Przejdź do kroku Przygotowanie
# Button on the Install step's bar when a question has no answer.
go-to-options = Przejdź do kroku Opcje
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Przejdź do kroku Zabezpieczenia Windows
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Wróć do kroku Instalacja
output-problem-title = Nie udało się odczytać postępu instalacji
install-elevate-title = Do instalacji potrzebne są uprawnienia administratora
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Gdy Atlas otworzy się ponownie, Windows poprosi Cię o zgodę.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Pakiet Atlasa nie jest gotowy
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Najpierw ukończ krok Przygotowanie
install-not-ready-message = Zanim Atlas będzie mógł rozpocząć instalację, musi dokończyć sprawdzanie komputera i aktualizowanie Windows.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 nadal włączony".
install-switches-title = Ponownie wyłącz przełączniki ochrony
install-switches-message = Zabezpieczenia Windows: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Gotowe do instalacji
summary-setup-title = Twoja konfiguracja Atlasa
summary-activation = Aktywacja
summary-activation-ok = Aktywowano. Atlas tego nie zmieni.
summary-activation-missing = Nie aktywowano. Możesz kontynuować, ale Atlas nie aktywuje Windows.
summary-activation-unknown = Atlas nie zmieni stanu aktywacji Windows.
# How long installing usually takes. The first while the box below it is ticked, the second
# while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Zwykle około { $minutes } minuty, potem komputer uruchomi się ponownie
        [few] Zwykle około { $minutes } minut, potem komputer uruchomi się ponownie
        [many] Zwykle około { $minutes } minut, potem komputer uruchomi się ponownie
       *[other] Zwykle około { $minutes } minuty, potem komputer uruchomi się ponownie
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Zwykle około { $minutes } minuty, potem uruchom komputer ponownie
        [few] Zwykle około { $minutes } minut, potem uruchom komputer ponownie
        [many] Zwykle około { $minutes } minut, potem uruchom komputer ponownie
       *[other] Zwykle około { $minutes } minuty, potem uruchom komputer ponownie
    }
# The check box on the card. It's the same setting as settings-restart-automatically.
summary-restart-automatically = Automatycznie uruchom komputer ponownie po zakończeniu instalacji
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Dodatkowo wyłączane
summary-turned-off-value = Inteligentna kontrola aplikacji, Rozszerzona ochrona przed wyłudzaniem informacji i Znajdź moje urządzenie
summary-show-command = Pokaż polecenie instalacji
summary-hide-command = Ukryj polecenie instalacji
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Kopiuj polecenie instalacji
summary-command-unavailable = Nie udało się przygotować polecenia instalacji. Szczegóły: { $error }
summary-not-chosen = Jeszcze nie wybrano
# Accessible name of a Change link. $title is a screen-*-name message.
summary-change-a11y = Zmień: { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Sposób aktualizacji
# Why Continue waits on Get ready. 8 words or fewer.
footer-still-checking = Przygotowywanie do instalacji
footer-checks-blocked = Rozwiąż wykryte problemy, aby kontynuować
footer-manager-outdated = Pobierz nowszy Atlas Manager, aby kontynuować
footer-need-files = Pobierz lub otwórz pakiet Atlasa, aby kontynuować
# Tester build variant of footer-need-files.
footer-need-package-bundled = Przygotuj dołączony pakiet Atlasa, aby kontynuować
footer-drivers = Wybierz sposób instalowania sterowników, aby kontynuować
footer-windows-terms = Zaakceptuj postanowienia licencyjne, aby kontynuować
footer-updating = Aktualizowanie Windows i aplikacji ze sklepu…
footer-restart = Uruchom komputer ponownie, aby kontynuować
footer-reading-security = Sprawdzanie przełączników ochrony
# Why Continue waits on Windows Security: while a switch is on, then while only switches
# Atlas couldn't read are left to confirm.
footer-security-pending = Wyłącz wszystkie cztery przełączniki, aby kontynuować
footer-security-confirm = Aby kontynuować, potwierdź przełączniki, których Atlas nie mógł odczytać
# Beside Install Atlas while automatic restart is on.
footer-install-ready = Najpierw zapisz pracę i zamknij aplikacje
button-install = Zainstaluj Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } wcześniejszy wiersz znajduje się w pliku dziennika.
        [few] { $count } wcześniejsze wiersze znajdują się w pliku dziennika.
        [many] { $count } wcześniejszych wierszy znajduje się w pliku dziennika.
       *[other] { $count } wcześniejszych wierszy znajduje się w pliku dziennika.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (pełny dziennik: { $path })

## Widok instalowania

installing-title = Instalowanie Atlasa
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis.
installing-checking-label = Sprawdzanie komputera…
installing-staging-label = Kopiowanie plików Atlasa…
installing-applying-label = Konfigurowanie Windows…
installing-finishing-label = Kończenie…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Nie wyłączaj komputera i nie odłączaj zasilania. Po zakończeniu instalacji komputer uruchomi się ponownie automatycznie.
installing-keep-on = Nie wyłączaj komputera i nie odłączaj zasilania. Po zakończeniu instalacji uruchom go ponownie.
# When Atlas can't follow the installer's log. Its title is output-problem-title.
installing-output-problem = Nie oznacza to, że instalacja się zatrzymała.
installing-installed-title = Atlas jest zainstalowany
# Under installing-installed-title while the restart counts down.
installing-restart-countdown =
    { $seconds ->
        [one] Komputer uruchomi się ponownie za { $seconds } sekundę.
        [few] Komputer uruchomi się ponownie za { $seconds } sekundy.
        [many] Komputer uruchomi się ponownie za { $seconds } sekund.
       *[other] Komputer uruchomi się ponownie za { $seconds } sekundy.
    }
installing-restart-save = Najpierw zapisz pracę.

## Okno „Atlas jest zainstalowany” po ponownym uruchomieniu

installed-title-version = Atlas { $version } jest zainstalowany
installed-title = Atlas jest zainstalowany
installed-ready = To wszystko. Komputer jest gotowy do pracy z Atlasem.
# A line under the setup card where the user installs drivers themselves.
installed-manual-drivers-detail = Pobierz sterowniki chipsetu, sieci i grafiki od producenta komputera, płyty głównej lub urządzenia.
installed-drivers-guide = Otwórz przewodnik po sterownikach
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender został usunięty
# After an installation that kept Microsoft Defender, when it is missing and no Atlas package
# removed it. Its title is security-banner-missing-title; its button is report-title.
defender-missing-message = Atlas go nie usunął. Jeśli nie używasz innej aplikacji antywirusowej, zainstaluj taką aplikację, aby chronić komputer.
# When Atlas's record kept Microsoft Defender but Atlas's own package still removes it. Its
# button is home-reinstall. 7. Security, Defender and Toggle Defender are folder and file names
# in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender jest nadal usunięty
defender-not-restored-message = Wcześniejsza aktualizacja Atlasa go nie przywróciła, więc Defender nie chroni komputera. Zainstaluj Atlas ponownie i zachowaj Defender albo uruchom Toggle Defender z lokalizacji 7. Security > Defender w folderze Atlas.
# When what the installation recorded for some choices isn't what was chosen.
installed-not-applied-title = Niektóre opcje nie zostały zastosowane
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender i zabezpieczenia procesora", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [one] Ta opcja pozostała bez zmian: { $choices }.
        [few] Te opcje pozostały bez zmian: { $choices }.
        [many] Te opcje pozostały bez zmian: { $choices }.
       *[other] Te opcje pozostały bez zmian: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Windows Update jest znowu wyłączony, zgodnie z Twoim wyborem
installed-update-off-message = Dopóki jest wyłączony, komputer nie otrzymuje aktualizacji zabezpieczeń.
installed-update-paused-title = Aktualizacje Windows są znowu wstrzymane, zgodnie z Twoim wyborem
installed-update-paused-message = Dopóki są wstrzymane, komputer nie otrzymuje aktualizacji zabezpieczeń.

## Ustawienia

settings-title = Ustawienia
# Headings of the page's sections, over their cards.
settings-appearance = Wygląd
settings-installation = Instalacja
settings-privacy = Prywatność
settings-theme = Motyw aplikacji
settings-theme-system = Jak w Windows
settings-theme-light = Jasny
settings-theme-dark = Ciemny
settings-theme-contrast-note = Atlas używa kolorów motywu kontrastowego Windows.
settings-language = Język
# The setting in the Language section, and its box's name.
settings-app-language = Język aplikacji
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name.
settings-language-match-windows = Jak w Windows – { $language }

# A short tag after each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Wersja wstępna
# Under the language box while the language in use is a preview translation.
settings-language-preview-in-use = To tłumaczenie nie zostało jeszcze sprawdzone przez rodzimego użytkownika języka.
# A bar at the top of the content while a preview translation is in use. $language is the
# language's own name.
preview-notice = To tłumaczenie ({ $language }) jest wersją wstępną i może zawierać błędy.
preview-notice-switch = Przełącz na angielski
preview-notice-language = Zmień język
# Under the language box when the language chosen isn't in this version.
settings-language-chosen-unavailable = Wybranego języka nie ma w tej wersji Atlasa, więc Atlas wyświetla angielski. Twój wybór pozostaje zapisany.
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas nie obsługuje jeszcze Twojego języka wyświetlania Windows, więc wyświetla angielski.
# The same when the Windows display languages couldn't be read.
settings-language-windows-unreadable = Atlas nie mógł sprawdzić Twojego języka wyświetlania Windows, więc wyświetla angielski.
# $locale is the regional format's own name, for example "polski (Polska)".
settings-language-formats = Liczby, daty i godziny są zgodne z formatem regionalnym Windows: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Liczby są zgodne z formatem regionalnym Windows: { $locale }. Daty i godziny są wyświetlane w formacie standardowym, ponieważ Atlas nie może jeszcze wyświetlać tekstu pisanego od prawej do lewej.
settings-language-contribute = Pomóż tłumaczyć Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Udostępniaj Atlasowi dane o użyciu
settings-share-usage-description = Otwierane strony, tworzone obrazy ISO i wyniki instalacji.
settings-privacy-policy = Polityka prywatności
# Covers the restart after installing and the restart that updates need before installing.
settings-restart-automatically = Automatycznie uruchamiaj komputer ponownie po instalacji i aktualizacjach
settings-restart-automatically-description = Komputer uruchomi się ponownie w ciągu minuty od zakończenia pracy Atlasa, zamykając otwarte aplikacje.
settings-restart-locked = Możesz to zmienić po zakończeniu instalacji.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Pomoc
settings-about = Informacje
settings-about-app = Atlas Manager
settings-about-licence = Licencja
settings-about-licence-value = GPL-3.0, wolne i otwarte oprogramowanie
settings-view-source = Zobacz kod źródłowy
# Link that opens the third-party licence notices.
settings-view-licences = Zobacz informacje o licencjach
# Under the links when Windows could not open the notices.
settings-licences-failed = Nie udało się otworzyć informacji o licencjach. Spróbuj ponownie lub znajdź je w kodzie źródłowym w serwisie GitHub.
settings-open-data-folder = Otwórz folder aplikacji

## Opcjonalne dodatki: objaśnienia widoczne przed wyborem.

consequence-disable-hibernation = Zwalnia miejsce na dysku, w którym zapisywana jest sesja podczas hibernacji. Hibernacja i szybkie uruchamianie będą niedostępne.
consequence-disable-power-saving = Wyłącza funkcje oszczędzania energii. Komputer może zużywać więcej prądu, mocniej się nagrzewać i krócej działać na baterii.
consequence-disable-core-isolation = Wyłącza dodatkową warstwę zabezpieczeń Windows, w tym integralność pamięci. Zmniejsza to ochronę, a gry korzystające z systemów anti-cheat, takich jak Riot Vanguard czy FACEIT, mogą się nie uruchomić, dopóki nie włączysz ponownie integralności pamięci.
consequence-remove-snipping-tool = Usuwa aplikację Windows do robienia zrzutów ekranu i nagrywania ekranu.
consequence-uninstall-edge = Usuwa przeglądarkę Microsoft Edge. Upewnij się, że masz inną przeglądarkę, lub wybierz jedną poniżej.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Usuwa zakładki, historię i zapisane hasła przeglądarki Edge na tym komputerze.
consequence-install-another-browser = Wybierz przeglądarkę poniżej, a Atlas ją zainstaluje.
consequence-install-toolbox = Atlas Toolbox pomaga zarządzać ustawieniami Atlasa. Jest w wersji beta, więc niektóre funkcje mogą być jeszcze niedokończone.
consequence-install-eclean = Narzędzie do konserwacji od zespołu AtlasOS, które pomaga utrzymać porządek na komputerze po konfiguracji. Przeglądaj zbędne pliki i aplikacje startowe. Wymaga konta i połączenia z internetem.

## Tworzenie obrazu ISO

iso-open = Utwórz ISO z Atlasem
iso-title = Utwórz ISO z Atlasem
iso-recommended = Zalecane
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set up,
# and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Konfiguracja
iso-step-create = Tworzenie
# The first question on the Windows step. It sets the defaults that follow.
iso-target-title = Dla którego komputera jest ten obraz ISO?
iso-target-this = Ten komputer
iso-target-another = Inny komputer
# When the ISO is for another kind of processor than this PC's. $architecture is
# iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = Ten obraz ISO jest dla komputerów { $architecture }.
iso-source = Obraz ISO Windows
# Starts the Windows 11 download at once, in the language and architecture of iso-download-caption.
iso-download-windows = Pobierz od firmy Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English;
# $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download for the accessible name of its Change link.
iso-download-what = Pobieranie Windows
iso-download-language = Język
iso-download-arch = Architektura
iso-download-languages = Wczytywanie języków…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2,4 GB" (size-gigabytes).
iso-downloading = Pobieranie Windows 11…
iso-download-amount = { $received } z { $total }
# The download couldn't start, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas nie mógł połączyć się z usługą pobierania firmy Microsoft. Sprawdź połączenie z internetem i spróbuj ponownie.
iso-download-incomplete = Pobieranie nie zostało ukończone. Sprawdź połączenie z internetem i ilość wolnego miejsca, a potem spróbuj ponownie.
iso-download-website = Otwórz stronę pobierania firmy Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button.
iso-use-local = Wybierz plik ISO
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Sprawdzanie obrazu ISO Windows…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6,6 GB".
iso-checked-a11y = Obraz ISO Windows gotowy, { $facts }
iso-package-latest-label = Najnowsza
# The latest Atlas release is older than this Atlas Manager can use; package-open-file is under it.
iso-package-release-old = Najnowsze wydanie Atlasa jest zbyt stare dla tej wersji aplikacji Atlas Manager.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Pobieranie najnowszej wersji Atlasa…
# The release check failed; Try again is beside it.
iso-package-release-failed = Atlas nie mógł sprawdzić najnowszej wersji. Sprawdź połączenie z internetem i spróbuj ponownie.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Pobierz lub wybierz obraz ISO Windows, aby kontynuować
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Kiedy chcesz wybrać opcje Atlasa?
iso-mode-after = Po zalogowaniu
iso-mode-after-description = Po zalogowaniu Atlas przeprowadzi Cię przez konfigurację.
iso-mode-now = Teraz
iso-mode-now-description = Opcje zostaną zapisane w obrazie ISO. Atlas zainstalujesz po zalogowaniu.
# A check box under Now.
iso-mode-before-desktop = Dokończ przed otwarciem pulpitu
iso-mode-before-desktop-description = Po zalogowaniu Atlas działa na pełnym ekranie aż do zakończenia instalacji.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Ten pakiet Atlasa nie może zapisać opcji w obrazie ISO, więc wybierzesz je po zalogowaniu.
iso-atlas-options = Opcje Atlasa
# The line at the top of the Create step.
iso-create-intro = Utworzenie obrazu ISO nie zmienia tego komputera ani oryginalnego obrazu ISO.
iso-review-package = Pakiet Atlasa
iso-review-output = Nowy obraz ISO
iso-review-edition = Edycja
iso-review-editions = Edycje
iso-edition = Edycja systemu Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Instalator Windows zapyta
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Instalator Windows zapyta
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Zaakceptuj postanowienia licencyjne Windows teraz, a nie w Instalatorze Windows
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nazwa konta
# Its value is iso-target-this or iso-target-another.
iso-review-target = Komputer docelowy
iso-review-drivers = Sterowniki
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Instalator Windows
iso-review-skips = Pomija ekrany konta Microsoft i prywatności
iso-review-skips-terms = Pomija ekrany licencji, konta Microsoft i prywatności
iso-review-network = Sterowniki sieciowe
iso-review-network-included = Sterowniki Wi-Fi i Ethernet tego komputera
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Teraz, instalacja przed otwarciem pulpitu
# Under the new ISO on the Create step. $needed and $free are sizes such as "35,0 GB";
# $drive is a drive such as "C:".
iso-destination-space = Wymaga { $needed } · { $free } wolnego miejsca na dysku { $drive }
iso-destination-short = Obraz ISO wymaga { $needed }, a na dysku { $drive } jest { $free } wolnego miejsca. Zwolnij miejsce albo zapisz obraz ISO na innym dysku.
iso-destination-filesystem = Dysk { $drive } nie może przechowywać dużych plików obrazu ISO. Zapisz go na dysku sformatowanym w systemie NTFS, na przykład na dysku z Windows.
iso-destination-unusable = Atlas może zapisać obraz ISO tylko w folderze na dysku tego komputera.
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = W folderze docelowym pliki obrazu ISO wymagałyby dłuższych ścieżek, niż pozwala Windows. Zapisz nowy obraz ISO w folderze o krótszej ścieżce, na przykład na dysku z Windows.
iso-create = Utwórz ISO
# Heading above the progress bar and the list of stages while the ISO is being created.
iso-progress-title = Tworzenie obrazu ISO…
# The progress bar's label: the stage under way, ending in an ellipsis. $stage is one of the
# iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Odczytywanie obrazu ISO Windows
iso-stage-copy = Kopiowanie plików Windows
iso-stage-add-atlas = Dodawanie Atlasa
iso-stage-master = Zapisywanie pliku ISO
iso-stage-verify = Sprawdzanie nowego obrazu ISO
iso-stage-cleanup = Kończenie
# Accessible name of one stage while the ISO is created. No "Etap": the screen reader adds
# "4 z 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = w toku
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = nie powiodło się
iso-stage-status-not-started = nie rozpoczęto
iso-progress-keep-open = Pozostaw Atlas otwarty do zakończenia.
iso-cancel = Anuluj tworzenie
iso-cancelling = Oczekiwanie na bezpieczne zatrzymanie
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Anulowanie…
iso-cancelled = Anulowano tworzenie ISO
iso-cancelled-unchanged = Oryginalny obraz ISO nie został zmieniony.
iso-complete = Obraz ISO jest gotowy
iso-complete-backup = Zanim zainstalujesz z niego ponownie Windows, zrób kopię zapasową plików.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Utwórz dysk USB
iso-open-folder = Pokaż w folderze
iso-failed = Nie udało się utworzyć obrazu ISO
# Under iso-failed, beside Try again.
iso-failed-retry = Upewnij się, że wybrane pliki nadal są na swoim miejscu, a dysk docelowy jest podłączony, i spróbuj ponownie.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Nie udało się sprawdzić plików
iso-check-failed-retry = Upewnij się, że obraz ISO i pakiet Atlasa zostały w pełni pobrane, i spróbuj ponownie.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas nie mógł przygotować folderu roboczego, więc nic nie zostało zmienione.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix.
iso-edition-unsupported-title = Ten obraz ISO nie zawiera edycji obsługiwanej przez Atlas
iso-edition-unsupported = Edycje Windows Home i LTSC nie są obsługiwane. Użyj obrazu ISO z edycją Pro, Education lub Enterprise.
iso-customised-title = Ten obraz ISO został zmodyfikowany
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = Ten obraz ISO utworzył Atlas
iso-customised = Zawiera już pliki instalacyjne, takie jak autounattend.xml. Użyj niezmodyfikowanego obrazu ISO od firmy Microsoft.
iso-preview-title = Ten obraz ISO zawiera kompilację zapoznawczą
iso-preview = Jego kompilacji Windows nie ma na liście publicznych wydań firmy Microsoft. Użyj obrazu ISO od firmy Microsoft.
iso-windows-unsupported-title = Ten pakiet Atlasa nie obsługuje tego obrazu ISO
iso-windows-unsupported = Użyj niezmodyfikowanego obrazu ISO Windows 11 w wersji obsługiwanej przez pakiet.
iso-release-unknown-title = Atlas nie mógł potwierdzić tego wydania Windows
iso-release-unconfirmed = Atlas porównuje je z listą publicznych wydań firmy Microsoft. Sprawdź połączenie z internetem i spróbuj ponownie.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Ten pakiet Atlasa nie może utworzyć obrazu ISO
iso-package-old = Użyj Atlasa w wersji { $minimum } lub nowszej.
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = To jest obraz ISO Windows, a nie pakiet Atlasa
iso-package-windows-iso = Zamiast tego wybierz pakiet Atlasa (.atlaspkg), a ten obraz wybierz jako obraz ISO Windows.
iso-manager-missing-title = Brakuje pliku aplikacji Atlas Manager
iso-fix-package = Wybierz inny pakiet
# A package that needs a newer Atlas Manager; manager-download is beside it.
iso-manager-outdated-title = Atlas Manager wymaga aktualizacji
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas nie mógł dodać sterowników sieciowych tego komputera do obrazu ISO.
iso-network-skip = Utwórz bez nich
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas potrzebuje uprawnień, aby utworzyć obraz ISO
iso-admin-reason = Uprawnienia są potrzebne do odczytania obrazu ISO Windows i utworzenia nowego.
iso-elevation-declined = Windows nie udzielił Atlasowi uprawnień, więc Atlas nie może jeszcze odczytać obrazu ISO Windows.
# The free space ran out while the ISO was being created.
iso-failed-space = Na dysku docelowym nie ma wystarczającej ilości wolnego miejsca. Zwolnij miejsce lub zapisz nowy obraz ISO na innym dysku.
# Under iso-manager-missing-title.
iso-manager-missing = Pobierz plik AtlasManager.exe do folderu lokalnego, takiego jak Pobrane, a potem otwórz go stamtąd.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Ten obraz ISO nie zawiera żadnej obsługiwanej edycji Windows. Edycje Windows Home i LTSC nie są obsługiwane. Użyj obrazu ISO z inną edycją, na przykład Pro, Education lub Enterprise.
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows nie mógł otworzyć obrazu ISO. Uruchom ponownie komputer i spróbuj jeszcze raz.
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows przestał odpowiadać podczas otwierania obrazu ISO. Uruchom ponownie komputer i spróbuj jeszcze raz.
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows nie może otwierać plików ISO na tym komputerze, ponieważ sterowniki, których do tego używa, vdrvroot i cdrom, są wyłączone. Włącz je ponownie, uruchom ponownie komputer i spróbuj jeszcze raz.
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows nie może otworzyć tego obrazu ISO, ponieważ plik jest skompresowany, zaszyfrowany lub rozrzedzony. Skopiuj go do folderu, który nie jest skompresowany ani zaszyfrowany, i użyj kopii.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Otwórz folder dzienników
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas korzysta teraz z Windows Update. Możesz kontynuować tutaj, gdy skończy.
# Names of the markers Windows sets when it wants a restart. They complete
# "Windows wymaga ponownego uruchomienia (…)"; keep them short and lower case.
prepare-reason-servicing = obsługa serwisowa Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = pliki oczekujące na zastąpienie
prepare-reason-update-agent = usługa Windows Update
prepare-reason-unknown = nie podano przyczyny
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Jeśli ponowna próba nie pomoże, dokończ pozostałe aktualizacje w Windows Update lub Microsoft Store.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Nie udało się ukończyć części aktualizacji
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Aktualizowanie zatrzymało się przed zgłoszeniem wyniku.
# Not called a failure, as none was reported.
prepare-unconfirmed-title = Nie udało się potwierdzić wyniku aktualizacji
# Accusative: it completes "Zamknij …" in prepare-close-app.
prepare-affected-app = aplikację powodującą problem
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Zamknij { $app }, a potem spróbuj ponownie. Jeśli nie możesz znaleźć tej aplikacji, zamknij ją w Menedżerze zadań.
prepare-install-busy = Inna instalacja lub wymagane ponowne uruchomienie blokuje aktualizacje. Poczekaj na zakończenie innych instalacji, uruchom komputer ponownie, jeśli Windows o to poprosi, a potem spróbuj ponownie.
# Updates failed after Atlas's own repair of the component store (DISM). The button is
# prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows nie mógł się naprawić
prepare-components-damaged = Windows zgłasza uszkodzenie, które uniemożliwia instalowanie aktualizacji. Ponowne uruchomienie może je usunąć, a Atlas będzie kontynuować po zalogowaniu.
prepare-restart-and-retry = Uruchom ponownie i spróbuj jeszcze raz
# Windows records damage to its component store that it can't repair. The one button is iso-open.
prepare-components-unrepairable-title = Windows jest zbyt uszkodzony, aby go zaktualizować
prepare-components-unrepairable = Zrób kopię zapasową plików, a potem zainstaluj ponownie Windows z obrazu ISO z Atlasem.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas działa na innym koncie niż to, na którym zalogowano się do Windows. Zaloguj się do Windows na koncie administratora, otwórz Atlas na tym koncie i spróbuj ponownie.
prepare-failed-store-missing = Microsoft Store nie jest skonfigurowany dla Twojego konta. Otwórz Microsoft Store choć raz albo zainstaluj go ponownie, jeśli go brakuje, a potem spróbuj ponownie.
prepare-failed-store-battery = Microsoft Store wstrzymał aktualizacje, aby oszczędzać baterię. Podłącz komputer do zasilania i spróbuj ponownie.
prepare-failed-store-network = Microsoft Store wstrzymał aktualizacje do czasu, aż komputer będzie mieć połączenie nietaryfowe. Połącz się z nietaryfową siecią Wi-Fi lub Ethernet i spróbuj ponownie.
prepare-failed-store-timeout = Aplikacje ze sklepu nie zakończyły aktualizacji. Dokończ pozostałe pobierania w Microsoft Store i spróbuj ponownie.
prepare-failed-store-passes = W Microsoft Store wciąż pojawiały się nowe aktualizacje. Dokończ pozostałe aktualizacje w Microsoft Store i spróbuj ponownie.
prepare-failed-manual-updates = Niektóre aktualizacje Windows trzeba dokończyć w Windows Update. Otwórz Windows Update, dokończ je i spróbuj ponownie.
prepare-failed-windows-passes = W Windows Update wciąż pojawiały się nowe aktualizacje. Dokończ pozostałe aktualizacje w Windows Update i spróbuj ponownie.
prepare-failed-windows-update-unreachable = Windows Update nie mógł połączyć się z serwerami firmy Microsoft. Sprawdź połączenie z internetem oraz ewentualną zaporę, serwer proxy lub VPN, a potem spróbuj ponownie.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic link).
prepare-failed-source-linked = Atlas Manager znajduje się w połączonym folderze. Zamknij Atlas, przenieś Atlas Manager do lokalnego folderu na tym komputerze, a potem otwórz go stamtąd.
prepare-error-code = Kod błędu: { $code }
prepare-open-store = Otwórz Microsoft Store
prepare-windows-search = Sprawdzanie aktualizacji Windows…
prepare-percent = { $percent }% tego etapu
prepare-count = Ukończone aktualizacje: { $completed } z { $total }
prepare-bytes = Pobrano { $downloaded } z około { $total } MB
prepare-progress-still = Brak postępu od { $minutes } min. Duże aktualizacje mogą trochę potrwać, więc pozostaw Atlas otwarty.
prepare-report-late = Windows od pewnego czasu nie zgłasza postępu. Aktualizacje mogą nadal trwać, więc pozostaw Atlas otwarty.
prepare-windows-download = Pobieranie aktualizacji Windows…
prepare-windows-install = Instalowanie aktualizacji Windows…
# While DISM repairs Windows' component store, with prepare-windows-repair-detail under the
# progress bar. DISM reports no progress.
prepare-windows-repairing = Naprawianie Windows…
prepare-windows-repair-detail = Windows zgłasza uszkodzenie, które może uniemożliwić instalowanie aktualizacji. Może to potrwać pół godziny lub dłużej.
prepare-store-search = Sprawdzanie Microsoft Store…
prepare-store-install = Aktualizowanie Microsoft Store i aplikacji…
prepare-stop = Zatrzymaj aktualizowanie
prepare-start = Sprawdź i zainstaluj aktualizacje
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Dostępne, gdy pakiet Atlasa będzie gotowy.
iso-username = Nazwa konta lokalnego
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Hasło ustawisz przy pierwszym logowaniu.
iso-username-placeholder = Twoje imię
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Wpisz nazwę konta lokalnego, aby kontynuować
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Użyj maksymalnie 20 znaków, bez spacji na początku i na końcu oraz bez tych znaków: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Nazwa nie może kończyć się kropką.
iso-account-reserved = Windows używa tej nazwy dla wbudowanego konta. Wybierz inną nazwę.
iso-terms-in-setup = Instalator Windows poprosi o zaakceptowanie postanowień licencyjnych.
prepare-drivers = Jak chcesz instalować sterowniki?
prepare-drivers-auto = Pobieraj sterowniki przez Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Pobieraj sterowniki przez Windows Update (zalecane)
prepare-drivers-auto-detail = Windows wyszuka sterowniki do Twojego sprzętu.
prepare-drivers-manual = Zainstaluję sterowniki samodzielnie
prepare-drivers-manual-detail = Windows Update nie będzie instalować sterowników, więc trzeba będzie pobrać je od producenta komputera lub urządzenia. Już zainstalowane sterowniki zostaną zachowane.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Sterowniki
iso-network-drivers = Dołącz sterowniki Wi-Fi i Ethernet tego komputera
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Wybierz po zalogowaniu
prepare-network-unmetered = Aktualizacje wymagają nietaryfowego połączenia z internetem. Połącz się przez Wi-Fi lub Ethernet, a potem spróbuj ponownie.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows zgłasza, że ta sieć nie ma dostępu do internetu. Zaloguj się do sieci, jeśli o to prosi, lub sprawdź router oraz ewentualne filtrowanie przez DNS lub zaporę, a potem spróbuj ponownie.
# "Połączenie taryfowe" is the switch's name in Windows network settings.
prepare-network-metered = To połączenie jest taryfowe lub ma ustawiony limit danych. Połącz się z siecią bez takich ograniczeń albo wyłącz opcję Połączenie taryfowe w ustawieniach sieci, a potem spróbuj ponownie.
prepare-network-settings = Otwórz ustawienia sieci
iso-stage-network-drivers = Przygotowywanie sterowników sieciowych
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Karty sieciowe tego komputera używają sterowników wbudowanych w Windows, więc obraz ISO nie musi ich zawierać.
desktop-setup-description = Dokończ konfigurację komputera. Wybrane opcje Atlasa są zapisane; w razie potrzeby możesz wrócić do Windows.
desktop-setup-exit = Kontynuuj w Windows

## Dysk USB do instalacji Windows

usb-title = Utwórz dysk USB
usb-existing = Utwórz dysk USB z istniejącego obrazu ISO
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = Dysk USB
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Obraz ISO Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = W folderze Pobrane nie ma obrazu ISO z Atlasem.
usb-iso-checking = Sprawdzanie obrazu ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas nie może utworzyć dysku USB z tego obrazu ISO. Użyj obrazu ISO utworzonego przez Atlas albo obrazu ISO Windows 11 od firmy Microsoft w wersji obsługiwanej przez Atlas.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = Obraz ISO lub Atlas Manager znajduje się w lokalizacji sieciowej lub w połączonym folderze. Przenieś go do folderu na tym komputerze, na przykład Pobrane.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Na dysku z Windows nie ma wystarczającej ilości wolnego miejsca, aby przygotować ten obraz ISO. Zwolnij miejsce, a Atlas sam sprawdzi ponownie.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas nie mógł odczytać tego obrazu ISO. Spróbuj ponownie albo użyj innego obrazu ISO.
# Opens the Storage page ("Magazyn") of Windows Settings, where space can be freed.
usb-open-storage = Otwórz ustawienia magazynu
usb-looking = Wyszukiwanie dysków USB…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Podłącz dysk USB o pojemności co najmniej { $size } GB.
# Under a drive that can't be used, after its size and letters: why.
usb-drive-too-small-needs = Za mały. Wymagane co najmniej { $size } GB.
usb-drive-too-small-iso = Za mały na ten obraz ISO
usb-drive-has-iso = Na tym dysku jest Twój obraz ISO
usb-drive-has-app = Atlas Manager działa z tego dysku
# A drive's size as it's sold. $size is a whole number of gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = Utwórz dysk USB
# Beside the unavailable Create USB drive while several drives are listed and none is picked.
usb-hint-pick = Najpierw wybierz dysk USB
# The question before erasing. $drive is the name the drive reports, such as Kingston
# DataTraveler Max (text); $size is usb-drive-size or usb-drive-size-tb; $letters is its drive
# letters, such as "F:" or "F:, G:". A drive with no letter is asked with usb-confirm-title.
usb-confirm-title-letters = Wymazać { $drive } ({ $size }, { $letters })?
usb-confirm-title = Wymazać { $drive } ({ $size })?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Wymazać dysk USB ({ $size }, { $letters })?
usb-confirm-title-unnamed = Wymazać dysk USB ({ $size })?
usb-confirm-message = Cała jego zawartość zostanie usunięta. Obraz ISO zostanie zachowany.
usb-confirm-erase = Wymaż i utwórz
usb-progress-title = Tworzenie dysku USB…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Przygotowywanie plików
usb-stage-formatting = Formatowanie
usb-stage-copying = Kopiowanie plików
usb-stage-checking = Sprawdzanie dysku
usb-stage-ejecting = Wysuwanie
usb-keep-open = Pozostaw Atlas otwarty, a dysk podłączony.
usb-scan-failed-title = Nie udało się odczytać listy dysków USB
usb-scan-failed-retry = Atlas nie mógł odczytać dysków podłączonych do tego komputera. Spróbuj ponownie.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Nie udało się utworzyć dysku USB
usb-complete-title = Dysk USB jest gotowy
# F12, F11 and Esc are key names.
usb-ready = Odłącz go, zrób kopię zapasową plików na komputerze, na którym instalujesz ponownie Windows, a potem uruchom ten komputer z dysku USB. Menu rozruchowe często otwiera klawisz F12, F11 lub Esc.
# After erasing may have begun.
usb-failed-partial = Dysk został zapisany tylko częściowo. Sprawdź, czy jest podłączony, i spróbuj ponownie.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas zatrzymał się przed wprowadzeniem zmian na dysku. Spróbuj ponownie.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
usb-drive-changed-title = Dysk USB się zmienił
usb-drive-changed = Został odłączony lub ponownie podłączony, zanim Atlas go wymazał, więc nic na nim nie zmieniono.
usb-drive-cancelled-title = Anulowano tworzenie dysku USB
usb-cancelled-partial = Dysk jest niekompletny. Utwórz go ponownie, zanim go użyjesz.
usb-cancelled-unchanged = Na dysku USB nie wprowadzono zmian.
usb-eject-failed-title = Nie można wysunąć dysku USB
usb-eject-failed-ready = Dysk jest gotowy do użycia. Zamknij pliki lub okna, które z niego korzystają, i spróbuj ponownie.
# Title of the bar with Relaunch as administrator. Its message is usb-admin-reason, or
# usb-elevation-declined after Windows refused the relaunch (UAC declined).
usb-elevation-title = Atlas potrzebuje uprawnień, aby utworzyć dysk USB
usb-admin-reason = Atlas potrzebuje uprawnień administratora, aby wymazać dysk i zapisać na nim dane.
usb-elevation-declined = Windows nie udzielił Atlasowi uprawnień, więc Atlas nie może jeszcze zapisać dysku USB.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Edycje Windows 11 Home, LTSC i Server nie są obsługiwane. Użyj innej edycji, na przykład Pro, Education lub Enterprise. Jeśli Windows nie mógł rozpoznać Twojej edycji, rozwiąż ten problem, zanim przejdziesz dalej.
install-source-title = Instalacja niedostępna
install-source-unsupported = Nie można zaktualizować Atlasa { $source } bezpośrednio do { $target }. Aby użyć tej wersji, zrób kopię zapasową plików i zainstaluj ponownie Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Nie można bezpośrednio zaktualizować Atlasa { $source }. Aby użyć nowszej wersji, zrób kopię zapasową plików i zainstaluj ponownie Windows.
# $folder is a folder path (text).
install-source-resume-package = Instalacja Atlasa { $target } nie została ukończona i można ją dokończyć tylko za pomocą pakietu Atlasa { $target }. Otwórz ten pakiet Atlasa (.atlaspkg). Jeśli Atlas go pobrał, znajduje się w folderze { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Instalacja Atlasa { $target } nie została ukończona. Ta wersja testowa może zainstalować tylko dołączony do niej pakiet Atlasa, więc dokończ tę instalację za pomocą pakietu Atlasa { $target } w oficjalnym wydaniu aplikacji Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas nie mógł ustalić, co jest już zainstalowane na tym komputerze, więc na razie niczego nie zainstaluje.
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = Na tym komputerze są pliki wcześniejszej wersji Atlasa, ale brak zapisu o ukończonej instalacji, więc nie można jej zaktualizować. Aby zainstalować Atlasa, zrób kopię zapasową plików i zainstaluj ponownie Windows.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = W Instalatorze Windows wybierz edycję, na którą masz licencję.
detail-windows-preview = Kompilacje Insider nie są obsługiwane. Użyj publicznie wydanej wersji systemu Windows 11.
detail-windows-release-unknown = Atlas nie mógł potwierdzić, że ta kompilacja systemu Windows została publicznie wydana. Połącz się z internetem i sprawdź ponownie.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Kompilacji { $build } nie ma na liście publicznych wydań Windows 11 firmy Microsoft, więc nie można jeszcze zainstalować na niej Atlasa. Kompilacje Release Preview i inne kompilacje zapoznawcze nie są obsługiwane. Sprawdź ponownie, gdy Microsoft doda tę kompilację do listy.

prepare-continue = Kontynuuj aktualizacje
prepare-saving-restart = Zapisywanie wybranych opcji i ustawianie ponownego otwarcia Atlasa po ponownym uruchomieniu Windows…
prepare-restart-save-failed = Nie udało się zapisać wybranych opcji. Spróbuj ponownie przed ponownym uruchomieniem.
prepare-restart-registration-failed = Wybrane opcje zostały zapisane, ale Atlas nie mógł ustawić automatycznego otwarcia po ponownym uruchomieniu. Spróbuj jeszcze raz albo uruchom komputer ponownie samodzielnie i otwórz Atlas po zalogowaniu.
# The same cause as prepare-failed-source-linked, met while arranging the restart.
prepare-restart-source-linked = Wybrane opcje zostały zapisane, ale dopóki Atlas Manager znajduje się w połączonym folderze, Atlas nie może ustawić automatycznego otwarcia po ponownym uruchomieniu. Zamknij Atlas i przenieś Atlas Manager do lokalnego folderu na tym komputerze. Potem otwórz go stamtąd albo uruchom komputer ponownie samodzielnie i otwórz go stamtąd po zalogowaniu.
prepare-restart-failed = Atlas nie mógł uruchomić komputera ponownie. Spróbuj jeszcze raz albo uruchom go ponownie z menu Start. Wybrane opcje są zapisane, a Atlas otworzy się ponownie po zalogowaniu.
diagnostics-export = Eksportuj diagnostykę
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Zbieranie danych diagnostycznych…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Uzyskaj pomoc
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Zapisano diagnostykę
# $file is the ZIP's name and $folder the name of the folder it's in, "Diagnostics" (both text,
# never translated).
diagnostics-saved-in-folder = Zapisano jako { $file } w folderze { $folder } Atlasa.
# Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas usunął z tego pliku Twoją nazwę użytkownika, nazwę komputera, adresy e-mail oraz znane hasła lub klucze.
# The bar when an export failed. Its button is common-try-again.
diagnostics-save-failed = Nie udało się zapisać pliku ZIP z diagnostyką

## Wersje testowe (funkcja embedded-package)

# A bar at the top of the content on a release-candidate build.
rc-banner = Wersja testowa Atlasa { $release }. Ta aplikacja instaluje tylko dołączony pakiet Atlasa.
home-status-bundled = Wersja testowa { $release }
package-bundled = Atlas { $version } dołączony do tej wersji testowej jest gotowy do instalacji.
rc-about-release = Wersja testowa
rc-about-commit = Commit źródłowy
rc-about-package = Dołączony pakiet Atlasa (SHA-256)
iso-package-bundled = Pakiet Atlasa dołączony do tej wersji testowej

check-user-account = Konto użytkownika
detail-user-account-ok = Kontrola konta użytkownika jest włączona, a konto jest gotowe do instalacji.
detail-user-account-not-ready = Włącz kontrolę konta użytkownika (UAC), uruchom ponownie komputer i spróbuj jeszcze raz. Jeśli używasz wbudowanego konta Administrator, zaloguj się na inne konto administratora.
detail-user-account-work-or-school = Atlasa nie można zainstalować z konta służbowego lub szkolnego (Microsoft Entra ID). Zaloguj się na konto lokalne lub konto Microsoft i spróbuj ponownie.
detail-user-account-check-failed = Atlas nie mógł sprawdzić konta użytkownika. Uruchom komputer ponownie, a potem otwórz Atlas i sprawdź ponownie. Komunikat systemu Windows: { $error }

footer-prepare-required = Dokończ aktualizowanie Windows i aplikacji ze sklepu, aby kontynuować
# "Etap" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Zatrzymywanie aktualizacji po zakończeniu bieżącego etapu…
resume-choices-title = Wznawianie poprzedniej instalacji
# The bar on Your choices, above the choices an unfinished installation holds.
resume-choices-held = Aby dokończyć tamtą instalację, Atlas używa opcji wybranych poprzednio, więc do jej zakończenia nie można ich zmienić.

## Zgłoszenia

report-title = Wyślij zgłoszenie
report-received = Otrzymano zgłoszenie
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Zachowaj ten numer, jeśli skontaktujesz się z zespołem Atlasa w sprawie tego zgłoszenia. Jeśli zgłoszenie zawiera dane kontaktowe, zespół może ich użyć do odpowiedzi, ale odpowiedź nie jest gwarantowana.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Kopiuj numer zgłoszenia
report-another = Wyślij kolejne zgłoszenie
# Label of the choice between the two kinds of report.
report-kind = Co chcesz wysłać?
report-kind-issue = Problem
report-kind-suggestion = Sugestia
report-message = Twoja wiadomość
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Co się stało i w jakiej sytuacji?
report-message-placeholder-suggestion = Co Twoim zdaniem warto zmienić?
# Under the message box, which also reads it out.
report-message-help = Nie podawaj haseł.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } z { $max } znaków
report-contact = Dane kontaktowe (opcjonalnie)
report-contact-placeholder = E-mail lub nazwa użytkownika Discord
report-attach = Dołącz diagnostykę
# Part of the privacy notice the user agrees to: keep every item.
report-attach-description = Dzienniki i informacje o systemie, które pomagają znaleźć przyczynę. Atlas usuwa Twoją nazwę użytkownika, nazwę komputera, adresy e-mail oraz znane hasła lub klucze. Szczegóły błędów, modele sprzętu i nazwy aplikacji są zachowywane. Przed wysłaniem możesz przejrzeć plik ZIP.
report-review = Sprawdź ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again.
report-prepare-failed-title = Nie udało się przygotować diagnostyki
report-prepare-failed-advice = Spróbuj ponownie albo wyślij zgłoszenie bez diagnostyki.
# The privacy notice the user agrees to, with report-attach-description.
report-privacy = Twoje zgłoszenie trafia prywatnie do zespołu Atlasa pod adresem reports.atlasos.net. Wiadomość i dane kontaktowe są wysyłane w takiej postaci, w jakiej je wpiszesz. Zespół może korzystać z usług sztucznej inteligencji innych firm, aby pomóc w analizie zgłoszenia. Usługi te otrzymują Twoją wiadomość i diagnostykę, ale nie Twoje dane kontaktowe. Zgłoszenia są usuwane po 90 dniach, a dzienniki zabezpieczeń serwera mogą zapisywać Twój adres IP.
report-website = Prywatność i strona zgłoszeń
report-consent = Zgadzam się na wysłanie tego zgłoszenia i dołączonej diagnostyki do zespołu Atlasa
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website.
report-not-sent-retry = Sprawdź połączenie z internetem i spróbuj ponownie. Możesz też wysłać zgłoszenie przez stronę zgłoszeń.
report-not-sent-busy = Usługa zgłoszeń jest zajęta. Poczekaj kilka minut i spróbuj ponownie.
report-not-sent-outdated = Ta wersja aplikacji Atlas Manager nie może wysyłać zgłoszeń. Skopiuj wiadomość na stronę zgłoszeń i dołącz plik ZIP, jeśli zgłoszenie ma zawierać diagnostykę.
report-not-sent-diagnostics = Nie udało się wysłać diagnostyki. Spróbuj ponownie albo wyślij zgłoszenie bez niej.
# The footer's button where this version can't send.
report-failed-website = Otwórz stronę zgłoszeń
# Beside a spinner in the footer while the report is on its way.
report-sending = Wysyłanie…
report-send = Wyślij zgłoszenie

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = Wpisz od { $min } do { $max } znaków.

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = Ogranicz dane kontaktowe do { $max } znaków.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Potwierdź zgodę na wysłanie tego zgłoszenia.

report-failed-title = Zgłoszenie nie zostało wysłane

## Aktualizacja wersji Windows
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2).
# Titles say "Windows 11, wersja"; sentences say "Windows 11 w wersji".

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Twoje pliki i aplikacje zostaną zachowane.
home-plan-name = Ta aktualizacja składa się z dwóch części
home-plan-windows-title = Windows 11, wersja { $release }
home-plan-windows-step = Atlas zainstaluje ją z Windows Update, a potem komputer uruchomi się ponownie.
# The same step where moving is optional.
home-plan-windows-step-ask = Opcjonalnie. Atlas najpierw zapyta, potem zainstaluje ją z Windows Update, a komputer uruchomi się ponownie.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Zainstalowano.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas zaktualizuje się i zachowa Twoje opcje, a potem komputer uruchomi się ponownie.
# $date and $until are dates.
home-end-of-updates-title = Windows 11 w wersji { $current } przestanie otrzymywać aktualizacje zabezpieczeń { $date }
home-end-of-updates-past-title = Windows 11 w wersji { $current } nie otrzymuje już aktualizacji zabezpieczeń
home-end-of-updates-message = Wraz z aktualizacją do Atlasa { $version } ten komputer przejdzie też na Windows 11 w wersji { $release }, która będzie otrzymywać aktualizacje zabezpieczeń do { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts is under the bar.
home-end-of-support-plan = Windows 11 w wersji { $release } będzie otrzymywać aktualizacje zabezpieczeń do { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education, więc nie można go zainstalować w systemie { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education, więc nie można go zainstalować w systemie { $product }. Windows 11 w wersji { $current } otrzymuje aktualizacje zabezpieczeń do { $date }, a Windows Update może zaktualizować ten komputer do nowszej wersji.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education, więc nie można go zainstalować w systemie { $product }. Wersja { $current } nie otrzymuje już aktualizacji zabezpieczeń, więc zaktualizuj Windows nawet bez Atlasa.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education. Edycje LTSC nie są obsługiwane.
# $releases lists the supported releases, such as "25H2 lub 26H2".
install-windows-reinstall = Atlas { $version } wymaga Windows 11 w wersji { $releases }, a Windows Update nie może zaktualizować tego komputera do takiej wersji. Zrób kopię zapasową plików, a potem zainstaluj ponownie Windows z obrazu ISO z Atlasem.
# The same on Home, where the card that creates an Atlas ISO comes first.
home-windows-no-path = Atlas { $version } wymaga Windows 11 w wersji { $releases }, a Windows Update nie może zaktualizować tego komputera do takiej wersji.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back.
home-update-access-title = Ustawienia Windows Update są zmienione na potrzeby aktualizacji Atlasa
# While an update that moves Windows is under way.
home-update-access-put-back-later = Atlas przywróci te ustawienia po zakończeniu aktualizacji.
# When the last check found no offer yet.
home-update-access-waiting = Atlas włączył Windows Update, aby zaktualizować ten komputer do Windows 11 w wersji { $release }, ale Windows Update jeszcze jej nie udostępnia.
home-update-access-updating = Atlas włączył Windows Update, aby zainstalować aktualizacje, i jeszcze nie skończył.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Nie udało się odczytać zapisu Atlasa dotyczącego Windows Update
home-update-access-unreadable-problem = Atlas nie może odczytać zapisu zmienionych przez siebie ustawień Windows Update, więc niczego nie zmieni ani nie przywróci.
# When putting the settings back failed for another reason. Put back settings tries again.
home-put-back-failed = Atlas nie mógł przywrócić ustawień.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage ("etap", not a flow step). On Home,
# in the close question, and under the Windows release choice on Get ready.
update-access-finish-install = Najpierw dokończ instalację Atlasa. Jej ostatni etap przywróci ustawienia Windows Update zmienione przez Atlas.
home-continue-update = Kontynuuj aktualizację
home-put-back = Przywróć ustawienia
home-putting-back = Przywracanie ustawień…

# Get ready: the card of the move to a newer Windows version, first on the page.
windows-card-title = Windows 11, wersja { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } nie obsługuje wersji { $current }, więc najpierw zaktualizuje Windows.
# Under the title where moving is optional.
windows-optional = Atlas działa z obiema wersjami.
# The choice's accessible name; the two answers say it.
windows-card-question = Której wersji Windows ma używać ten komputer?
windows-choice-move-recommended = Zaktualizuj do Windows 11 w wersji { $release } (zalecane)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Aktualizacje zabezpieczeń do { $date }.
windows-choice-keep = Zachowaj Windows 11 w wersji { $current }
windows-choice-keep-later = Komputer pozostanie przy wersji { $current }. Możesz przejść na nowszą wersję później w aplikacji Atlas Manager.
windows-card-facts = Co się zmieni
windows-fact-files = Twoje pliki i aplikacje zostaną zachowane. Atlas przywróci wszystko, co aktualizacja cofnie.
windows-fact-time = Zwykle kilka minut, maksymalnie 2 godziny, a potem ponowne uruchomienie.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Usuwa Windows PowerShell 2.0 i narzędzie WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Jak cofnąć aktualizację
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Aktualizując, akceptujesz postanowienia licencyjne dotyczące oprogramowania firmy Microsoft.
windows-terms-link = Przeczytaj postanowienia licencyjne
windows-accept = Zaakceptuj i zaktualizuj
# Once the terms are accepted, before the move starts by itself.
windows-starting = Rozpoczynanie…
windows-starts-after-checks = Rozpocznie się po pomyślnym sprawdzeniu.
windows-starts-after-package = Rozpocznie się, gdy Atlas { $version } będzie gotowy.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = Wersja { $release } cofnęła część zmian Atlasa. Atlas { $version } przywróci je zgodnie z Twoimi wcześniejszymi opcjami.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Zachować Windows 11 w wersji { $current }?

# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas tymczasowo włącza Windows Update
access-off = Windows Update jest wyłączony na tym komputerze. Atlas włączy go ponownie na czas aktualizacji Windows.
access-paused = Aktualizacje Windows są wstrzymane na tym komputerze. Atlas wznowi je na czas aktualizacji Windows.
access-delayed = Comiesięczne aktualizacje są odroczone na tym komputerze. Atlas usunie odroczenie na czas aktualizacji Windows.
# After the lines above.
access-back = Po zainstalowaniu Atlasa { $version } te ustawienia wrócą do poprzedniego stanu.
access-back-stop = Jeśli wcześniej zatrzymasz aktualizowanie, Atlas je przywróci.

prepare-reason-feature-update = nowa wersja Windows
prepare-reason-feature-commit = kończenie instalacji nowej wersji Windows
prepare-reason-apprepository = usuwanie pozostałych wpisów aplikacji
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes.
windows-waiting = Oczekiwanie na udostępnienie Windows 11 w wersji { $release } w Windows Update…
windows-waiting-detail = Zwykle kilka minut, maksymalnie 2 godziny. Atlas będzie kontynuować sam; w tym czasie możesz korzystać z komputera.
windows-waited =
    { $minutes ->
        [one] Atlas czeka już { $minutes } minutę.
        [few] Atlas czeka już { $minutes } minuty.
        [many] Atlas czeka już { $minutes } minut.
       *[other] Atlas czeka już { $minutes } minuty.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update nie udostępnił wersji { $release } w ciągu 2 godzin
windows-wait-ended = Atlas przywrócił Twoje ustawienia. Spróbuj ponownie później albo zainstaluj ponownie Windows z obrazu ISO z Atlasem.
# Instead of the message above when putting the settings back failed. The button is home-put-back.
windows-wait-put-back-failed = Atlas nie mógł przywrócić Twoich ustawień Windows Update.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't restart.
windows-commit-failed-title = Windows nie mógł przygotować ponownego uruchomienia
windows-commit-failed = Komputer nie uruchomił się ponownie. Spróbuj jeszcze raz.

# Outcomes of moving Windows, each a title and what to do next.
windows-outcome-not-offered-title = Windows Update nie udostępnił jeszcze wersji { $release }
windows-outcome-not-offered = Może to potrwać do 2 godzin. Komputer nadal ma wersję { $current }.
windows-outcome-hardware-title = Ten komputer nie spełnia wymagań Windows 11
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = Nie ma wymaganego sprzętu ({ $missing }), więc Windows Update nie udostępni wersji { $release }. Zrób kopię zapasową plików, a potem zainstaluj ponownie Windows z obrazu ISO z Atlasem.
hardware-tpm = moduł TPM 2.0
hardware-uefi = oprogramowanie układowe UEFI
windows-outcome-hidden-title = Wersja { $release } jest ukryta w Windows Update
windows-outcome-hidden = Pokaż ją ponownie za pomocą narzędzia, którym została ukryta, a potem spróbuj ponownie.
windows-outcome-disk-space-title = Za mało wolnego miejsca
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows potrzebuje { $needed } GB wolnego miejsca na dysku { $drive }, a jest tam { $free } GB. Atlas będzie kontynuować sam, gdy miejsca wystarczy.
windows-outcome-managed-title = Ten komputer otrzymuje aktualizacje od organizacji
windows-outcome-managed = Serwer aktualizacji organizacji nie udostępnia wersji { $release }, więc Atlas niczego nie zmienił. Zwróć się do organizacji albo zainstaluj ponownie Windows z obrazu ISO z Atlasem.
windows-outcome-policy-title = Coś ciągle przywraca poprzednie ustawienia Windows Update
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate.
windows-outcome-policy = Ustawienie { $setting } wraca do poprzedniej wartości po zmianie przez Atlas, więc Atlas nie może zaktualizować Windows. Jeśli tym komputerem zarządza organizacja, zwróć się do niej.
# $service is a service-* name, after a colon so that it needs no agreement. The buttons are
# common-try-again and prepare-open-services.
windows-outcome-service-off-title = Usługa jest wyłączona: { $service }
# "Ręczny" is the Manual startup type in Services.
windows-outcome-blocked-service = Windows Update jej potrzebuje. W oknie Usługi ustaw dla niej typ uruchomienia Ręczny, a potem spróbuj ponownie.
windows-outcome-blocked-title = Coś blokuje działanie Windows Update
windows-outcome-blocked = Ustawienie { $setting }, którego Atlas nie zmieniał, blokuje Windows Update. Zmień je, a potem spróbuj ponownie.
windows-outcome-rollback-title = Windows nie mógł dokończyć instalowania wersji { $release }
windows-outcome-rolled-back = Windows wrócił do wersji { $current }. Twoje pliki i aplikacje są nienaruszone.
windows-outcome-components-lost-title = Brakuje części zmian Atlasa
windows-outcome-components-lost = Atlas nie może ustalić przyczyny, więc zatrzymał się przed instalacją Atlasa { $version }.
windows-outcome-build-title = Wersja Windows zmieniła się podczas aktualizacji
windows-outcome-build = Przywróć ustawienia zmienione przez Atlas, a potem zacznij od nowa na stronie głównej.
windows-outcome-journal-title = Atlas nie może odczytać zapisu tej aktualizacji
windows-outcome-journal = Do czasu sprawdzenia przez zespół Atlasa niczego nie zmieni ani nie przywróci.
windows-outcome-pin-title = Nie można zapisać zasady Windows Update
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = Zasada { $setting } ma wartość, której Atlas nie mógłby później przywrócić, więc niczego nie zmienił.
windows-outcome-terms-title = Nie zaakceptowano postanowień licencyjnych
windows-outcome-terms = Windows Update wymaga ich akceptacji przed zainstalowaniem wersji { $release }.
windows-outcome-failed-title = Windows nie mógł zainstalować wersji { $release }
windows-outcome-failed = Komputer nadal ma wersję { $current }.
# Windows services a move needs, as Services lists them.
service-bits = Usługa inteligentnego transferu w tle (BITS)
service-cryptsvc = Usługi kryptograficzne
service-trusted-installer = Instalator modułów systemu Windows
prepare-open-services = Otwórz Usługi
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Zachowaj wersję { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Zatrzymać aktualizację do Atlasa { $version }?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Zatrzymać aktualizację systemu Windows?
stop-update-before = Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizacje już zainstalowane przez Windows pozostaną zainstalowane, a komputer zachowa Windows 11 w wersji { $current }.
stop-update-after = Komputer zachowa Windows 11 w wersji { $release }. Atlas przywróci zmienione przez siebie ustawienia Windows Update.
stop-update-access = Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizacje już zainstalowane przez Windows pozostaną zainstalowane.
stop-update-keep = Kontynuuj aktualizowanie
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Zamknąć Atlas?
window-close-update-access-message = Przed zamknięciem Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizację możesz rozpocząć ponownie na stronie głównej.
window-close-put-back = Przywróć i zamknij
# When putting the settings back before closing failed; the buttons are window-close-keep and
# window-close-close.
window-close-put-back-failed-title = Zamknąć bez przywracania ustawień?
window-close-put-back-failed-message = Jeśli teraz zamkniesz Atlas, ustawienia Windows Update pozostaną w stanie zmienionym przez Atlas. Gdy ponownie otworzysz Atlas, strona główna zaproponuje ich przywrócenie.

# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-needs-release = Ta wersja Atlasa wymaga Windows 11 w wersji { $release }, a ten komputer ma wersję { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Aktualizacja Windows na potrzeby Atlasa nie została ukończona. Szczegóły dla zespołu Atlasa:

# When Windows reinstalled itself while it moved to a newer version.
history-mode-rebase = ponowna instalacja po aktualizacji Windows
# Your choices after Windows reinstalled itself during a move.
rebase-choices-title = Opcje z Atlasa { $previous }
rebase-choices-kept = Atlas przywróci opcje wybrane dla Atlasa { $previous }. Możesz je później zmienić, instalując Atlas ponownie.
# Above the questions the record of the move had no answer for.
rebase-choices-asked = Atlas przywróci pozostałe opcje wybrane dla Atlasa { $previous }.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Uruchomić ponownie, gdy ktoś inny jest zalogowany?
restart-others-question = Uruchomić ponownie, gdy inne osoby są zalogowane?
# $names lists their account names, such as "Alex i Sam", after a colon; $count is how many
# there are. "konto" keeps the sentences free of the other people's gender.
restart-others-signed-in =
    { $count ->
        [one] Zalogowane jest też konto: { $names }. Ponowne uruchomienie zamknie aplikacje na tym koncie, a niezapisana praca zostanie utracona.
        [few] Zalogowane są też konta: { $names }. Ponowne uruchomienie zamknie aplikacje na tych kontach, a niezapisana praca zostanie utracona.
        [many] Zalogowane są też konta: { $names }. Ponowne uruchomienie zamknie aplikacje na tych kontach, a niezapisana praca zostanie utracona.
       *[other] Zalogowane są też konta: { $names }. Ponowne uruchomienie zamknie aplikacje na tych kontach, a niezapisana praca zostanie utracona.
    }
restart-others-keep = Nie uruchamiaj ponownie
restart-others-restart = Uruchom ponownie mimo to
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Aktualizowanie Microsoft Store…
prepare-store-repairing = Naprawianie Microsoft Store…
prepare-store-repair-detail = Może to potrwać kilka minut.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
prepare-store-skipped-removed = Microsoft Store jest wyłączony na tym komputerze, więc aplikacje ze sklepu nie zostały zaktualizowane.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again.
prepare-store-broken-title = Microsoft Store nie działa
prepare-store-broken = Atlas nie mógł go naprawić, a instalacja Atlasa w tej chwili mogłaby uszkodzić aplikacje ze sklepu.
prepare-store-broken-iso = Jeśli naprawa nadal się nie udaje, zrób kopię zapasową plików i zainstaluj ponownie Windows z obrazu ISO z Atlasem.
prepare-repair-store-again = Spróbuj naprawić ponownie
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows nie może zaktualizować wbudowanych aplikacji
prepare-store-staging = Windows nie mógł zainstalować aktualizacji tych wbudowanych aplikacji, a naprawy Atlasa nie pomogły: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Języki klawiatury
screen-keyboard-question = Czy używasz wielu języków klawiatury?
package-option-keyboard-shortcuts = Tak, przełączam skrótami klawiszowymi
package-option-keyboard-selector = Tak, używam selektora na pasku zadań
package-option-keyboard-single = Nie, używam jednego układu
consequence-keyboard-shortcuts = Alt+Shift zmienia język, a Ctrl+Shift zmienia układ.
consequence-keyboard-selector = Wyłącz Alt+Shift i Ctrl+Shift, aby uniknąć przypadkowego przełączania podczas gry.
package-choice-keyboard-description = Wybierz sposób przełączania języka klawiatury.
consequence-keyboard-single = { consequence-keyboard-selector }
