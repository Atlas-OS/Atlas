### Atlas Manager: Polish (pl). Preview translation, revised on 30 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog: the reader is addressed directly in the
### second person singular (Twój, Ci), as Microsoft Polish does; "Atlas" is
### declined like an ordinary masculine noun (Atlasa, Atlasie, Atlasem);
### "Windows" and "Microsoft Defender" are never declined, while "Zabezpieczenia
### Windows" declines like an ordinary noun phrase (w Zabezpieczeniach Windows); "otwórz Atlas ponownie" means relaunching
### this app, "uruchom ponownie" always means restarting the PC or Windows. The .apbx
### file is "pakiet Atlasa" ("plik pakietu" for the file itself); "playbook" stays
### only where a string explains that AME Wizard calls it that.

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
common-open-log-file = Otwórz plik dziennika
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Kopiuj dziennik instalacji
common-install-log = Dziennik instalacji
# Row labels in summary cards.
common-windows = Windows
common-options = Opcje
common-package = Pliki instalacyjne
common-installed-as = Typ instalacji
common-installed = Zainstalowano
common-checking = Sprawdzanie
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 lub 26200".
list-or = { $a } lub { $b }
list-and = { $a } i { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Okno

# Dialog shown when the window is closed while an install runs.
window-close-title = Zamknąć okno podczas instalacji?
window-close-message = Instalacja będzie kontynuowana w tle. Otwórz Atlas ponownie, aby zobaczyć postęp i wynik. Nie wyłączaj komputera, dopóki instalacja się nie zakończy.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = Instalacja będzie kontynuowana w tle, ale gdy Atlas jest zamknięty, komputer nie uruchomi się ponownie automatycznie. Otwórz Atlas ponownie, aby zobaczyć postęp i wynik. Nie wyłączaj komputera, dopóki instalacja się nie zakończy.
window-close-keep = Pozostaw otwarte
window-close-close = Zamknij okno
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = Zamknąć okno przed rozpoczęciem instalacji?
window-close-preparing-message = Atlas nadal sprawdza komputer i jeszcze nie rozpoczął instalacji. Jeśli teraz zamkniesz okno, instalacja się nie rozpocznie. Aby kontynuować, otwórz Atlas ponownie.
prepare-close-title = Aktualizacje nadal trwają
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Pozostaw Atlas otwarty, gdy trwają aktualizacje. Jeśli wybierzesz Zatrzymaj aktualizowanie, aktualizacje zatrzymają się po bieżącym etapie i wtedy możesz zamknąć Atlas.
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = Zamknąć Atlas bez ponownego uruchomienia?
# "Uruchom ponownie teraz" is restart-now, one of this dialog's three buttons.
window-close-restart-message = Aby dokończyć konfigurację Atlasa, trzeba uruchomić komputer ponownie. Jeśli teraz zamkniesz Atlas, nie uruchomi on ponownie komputera, więc zrób to samodzielnie w dogodnej chwili. Zapisz pracę, zanim wybierzesz Uruchom ponownie teraz.
window-close-restart-close = Zamknij bez ponownego uruchomienia
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Zamknąć Atlas z wyłączoną ochroną?
window-close-protection-message = Niektóre funkcje ochrony w Zabezpieczeniach Windows są nadal wyłączone: { $switches }. Jeśli nie zamierzasz dokończyć instalacji Atlasa, włącz je ponownie przed zamknięciem. Jeśli zamierzasz ją dokończyć, Atlas wznowi konfigurację, gdy otworzysz go ponownie.
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Otwórz pakiet Atlasa (.apbx)
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
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas na tym komputerze
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Zainstalowano { $date }
home-status-checking = Sprawdzanie aktualizacji
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
home-restart-title = Komputer wymaga ponownego uruchomienia
home-security-reminder-title = Włącz ochronę ponownie
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Upewnij się, że ochrona jest włączona
home-security-reminder-message = Atlas niczego teraz nie instaluje, ale niektóre funkcje ochrony w Zabezpieczeniach Windows są nadal wyłączone. Otwórz Zabezpieczenia Windows i upewnij się, że te przełączniki są włączone: { $switches }.
home-security-reminder-unreadable-message = Atlas nie mógł sprawdzić wszystkich przełączników ochrony. Sprawdź w Zabezpieczeniach Windows, czy te przełączniki są włączone: { $switches }.
home-elevation-title = Do instalacji potrzebne są uprawnienia administratora
home-state-error-title = Nie udało się odczytać informacji o instalacji Atlasa
home-state-error-message = Wersja Atlasa, wybrane opcje i historia instalacji mogą być wyświetlane niepoprawnie. Wybierz Sprawdź ponownie, aby spróbować jeszcze raz. Szczegóły: { $error }
home-whats-new = Co nowego w Atlasie { $version }
home-view-release = Zobacz informacje o wydaniu w serwisie GitHub
home-released = Wydano { $date }
home-show-less = Pokaż mniej
home-show-full-notes = Pokaż pełne informacje o wydaniu
home-your-install = Twoja instalacja Atlasa
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Na tym komputerze nie ma zapisu o tym, jak zainstalowano Atlas, więc nie można wyświetlić wybranych opcji ani historii instalacji.
# Row label: how Atlas was set up.
home-set-up = Sposób instalacji
home-set-up-during-oobe = Podczas konfiguracji Windows
home-history = Historia instalacji
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Przygotujmy komputer do instalacji Atlasa
home-step-1-detail = Atlas sprawdza komputer, instaluje oczekujące aktualizacje Windows i Microsoft Store oraz pobiera pliki instalacyjne. Aplikacje ze sklepu mogą zostać zamknięte, a komputer może wymagać ponownego uruchomienia, więc najpierw zapisz pracę.
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas sprawdza komputer, instaluje oczekujące aktualizacje Windows i Microsoft Store oraz przygotowuje dołączone pliki instalacyjne. Aplikacje ze sklepu mogą zostać zamknięte, a komputer może wymagać ponownego uruchomienia, więc najpierw zapisz pracę.
home-step-2-detail = Zdecyduj, czy zachować Microsoft Defender i zabezpieczenia procesora, jak instalować aktualizacje Windows i które opcjonalne dodatki wybrać.
home-step-3-detail = Wyłącz cztery przełączniki ochrony w Zabezpieczeniach Windows, aby nie blokowały instalacji. Atlas pokaże Ci, jak to zrobić.
home-step-4-detail =
    { $minutes ->
        [one] Instalacja trwa około minuty. Potem trzeba uruchomić komputer ponownie.
        [few] Instalacja trwa około { $minutes } minut. Potem trzeba uruchomić komputer ponownie.
        [many] Instalacja trwa około { $minutes } minut. Potem trzeba uruchomić komputer ponownie.
       *[other] Instalacja trwa około { $minutes } minuty. Potem trzeba uruchomić komputer ponownie.
    }
# Accessible name of a numbered step.
home-step-a11y = Krok { $number }: { $title }
home-github = Zobacz Atlas w serwisie GitHub
home-discord = Dołącz do społeczności Atlasa
home-report-problem = Zgłoś problem

## Sposób wykonania instalacji (z dokumentu stanu)

mode-fresh = Pierwsza instalacja
mode-upgrade = Aktualizacja z wcześniejszej wersji
mode-reapply = Ponowna instalacja tej samej wersji
mode-unknown = Instalacja
# Lower-case forms used inside a history row.
history-mode-fresh = pierwsza instalacja
history-mode-upgrade = aktualizacja
history-mode-reapply = ponowna instalacja
history-mode-unknown = instalacja

## Powiadomienia na stronie głównej

notice-settings-reset-title = Atlas używa domyślnych ustawień aplikacji
# $error is a raw error message (text).
notice-settings-unreadable = Atlas nie mógł odczytać zapisanych ustawień aplikacji. Ustawienia Windows nie zostały zmienione. Szczegóły: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = Plik ustawień aplikacji był uszkodzony i został przywrócony do wartości domyślnych. Kopię starego pliku zapisano jako { $file }. Szczegóły: { $error }
notice-settings-damaged = Plik ustawień aplikacji był uszkodzony. Atlas używa na razie ustawień domyślnych. Szczegóły: { $error }
notice-settings-not-saved-title = Nie udało się zapisać ustawień aplikacji
# $error is a raw error message (text).
notice-settings-not-saved = Atlas nie mógł zapisać ostatnich zmian, więc mogą one zostać utracone po zamknięciu Atlasa. Jeśli otwarte jest inne okno Atlasa, zamknij je, a potem wprowadź zmianę ponownie. Szczegóły: { $error }
notice-session-unreadable-title = Nie udało się sprawdzić poprzedniej instalacji
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Krok { $number } z { $total }, { $title }, { $status }
stepper-status-completed = ukończono
stepper-status-current = bieżący krok
stepper-status-upcoming = kolejny krok
stepper-status-attention = wymaga uwagi
# Heading above each step's content.
step-heading = Krok { $number } z { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Krok 1: Przygotowanie

ready-banner-busy-title = Przygotowywanie komputera
ready-banner-busy-message = Atlas sprawdza Twój komputer i przygotowuje pliki instalacyjne.
ready-banner-blocked-title = Komputer nie jest jeszcze gotowy
ready-banner-blocked-message = Napraw oznaczone elementy w sekcji Sprawdzanie komputera, a potem wybierz Sprawdź ponownie.
ready-banner-no-package-title = Pobierz Atlas, aby kontynuować
ready-banner-no-package-message = Pobierz Atlas w sekcji Pliki instalacyjne albo wybierz Otwórz plik pakietu, jeśli masz już pakiet Atlasa (.apbx).
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = Przygotuj dołączony pakiet Atlasa, aby kontynuować
ready-banner-no-package-bundled-message = Pakiet Atlasa dołączony do tej wersji testowej nie jest jeszcze gotowy. Sprawdź sekcję Pliki instalacyjne.
ready-banner-updates-title = Zaktualizuj Windows i aplikacje ze sklepu, aby kontynuować
ready-banner-updates-message = Wybierz Sprawdź i zainstaluj aktualizacje. Po zakończeniu aktualizacji Atlas ponownie sprawdzi komputer.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Aktualizowanie Windows i aplikacji ze sklepu
ready-banner-updating-message = Może to trochę potrwać. Pozostaw Atlas otwarty. Postęp możesz śledzić w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Zatrzymano aktualizowanie
ready-banner-updates-stopped-message = Aby dokończyć, wybierz Sprawdź i zainstaluj aktualizacje w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Komputer został uruchomiony ponownie
ready-banner-updates-resumed-message = Wybierz Kontynuuj aktualizacje w sekcji Zaktualizuj Windows i aplikacje ze sklepu, aby dokończyć aktualizowanie.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Sprawdź w sekcji Zaktualizuj Windows i aplikacje ze sklepu, co zrobić, a potem wybierz Spróbuj ponownie.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Najpierw zapisz pracę, a potem wybierz Uruchom ponownie i kontynuuj w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
ready-banner-warnings-title = Kilka rzeczy do sprawdzenia
ready-banner-warnings-message = Możesz kontynuować, ale najpierw przeczytaj oznaczone elementy w sekcji Sprawdzanie komputera.
ready-banner-ok-title = Możesz już wybrać opcje
ready-banner-ok-message = Sprawdzanie zakończyło się pomyślnie, a pliki instalacyjne są gotowe.

# Card title and accessible name of the list of checks.
ready-this-pc = Sprawdzanie komputera
ready-check-again = Sprawdź ponownie
ready-checks-passed =
    { $count ->
        [one] { $count } sprawdzenie zakończone pomyślnie
        [few] { $count } sprawdzenia zakończone pomyślnie
        [many] { $count } sprawdzeń zakończonych pomyślnie
       *[other] { $count } sprawdzeń zakończonych pomyślnie
    }

package-title = Pliki instalacyjne
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Pobieranie Atlasa { $version } · { $received } z { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Rozpakowywanie · { $done } z { $total } pliku
        [few] Rozpakowywanie · { $done } z { $total } plików
        [many] Rozpakowywanie · { $done } z { $total } plików
       *[other] Rozpakowywanie · { $done } z { $total } plików
    }
package-unpacking = Rozpakowywanie
package-looking = Sprawdzanie najnowszej wersji Atlasa.
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = Przygotowywanie dołączonego pakietu Atlasa.
package-none = Pobierz Atlas, aby uzyskać pliki instalacyjne. Jeśli masz już pakiet Atlasa (.apbx), otwórz go.
# The GitHub release check failed. "Pobierz najnowszą wersję" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas nie mógł sprawdzić, jaka jest najnowsza wersja. Sprawdź połączenie z internetem, a potem wybierz Pobierz najnowszą wersję albo otwórz zapisany pakiet Atlasa (.apbx).
# Short status words beside the card title.
package-status-downloading = Pobieranie
package-status-unpacking = Rozpakowywanie
package-status-failed = Nie udało się przygotować
package-status-ready = Gotowe
package-status-checking = Sprawdzanie
package-status-preparing = Przygotowywanie
package-status-missing = Nie pobrano
# Accessible name of the progress bar.
package-progress = Postęp przygotowania plików instalacyjnych
package-download-again = Pobierz ponownie
package-download-version = Pobierz Atlas { $version }
package-download-newest = Pobierz najnowszą wersję
package-cancel-download = Anuluj pobieranie
package-open-file = Otwórz plik pakietu
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } został pobrany z serwisu GitHub i jest gotowy do instalacji.
package-from-file = Atlas { $version } został wczytany z pliku { $file } i jest gotowy do instalacji.
package-unpacked = Atlas { $version } jest gotowy do instalacji.
package-none-yet = Nie wybrano plików instalacyjnych
acquire-no-asset = Atlas { $version } nie ma pliku pakietu do pobrania. Aby kontynuować, otwórz zapisany pakiet Atlasa (.apbx).
acquire-unsupported = Ta aplikacja instaluje Atlas w wersji 0.6.0 i nowszych. Aby zainstalować Atlas { $version }, użyj AME Wizard.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = W Atlasie { $version } brakuje plików, których ta aplikacja potrzebuje, aby go zainstalować. Pobierz go ponownie albo otwórz inny pakiet Atlasa (.apbx).
acquire-failed = Nie udało się przygotować plików instalacyjnych. Spróbuj pobrać je ponownie albo otwórz inny pakiet Atlasa (.apbx). Szczegóły: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Pobieranie przestało odpowiadać. Sprawdź połączenie z internetem, a potem pobierz pliki ponownie albo otwórz zapisany pakiet Atlasa (.apbx).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Nie udało się przygotować dołączonego pakietu Atlasa. Wybierz Spróbuj ponownie. Szczegóły: { $error }

## Sprawdzanie systemu

check-administrator = Uprawnienia do instalacji
check-supported-build = Zgodność z Windows
check-pending-updates = Aktualizacje Windows
check-pending-reboot = Oczekujące ponowne uruchomienie
check-third-party-antivirus = Inne programy antywirusowe
check-internet = Połączenie z internetem
check-power = Zasilanie
check-activation = Aktywacja Windows
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
check-fix-apps = Otwórz zainstalowane aplikacje
# Check box the user ticks when the Windows Update scan could not run. "Potwierdzam, że"
# keeps the first person without a gendered past-tense verb.
check-ack-updates = Potwierdzam, że w Windows Update żadne aktualizacje nie czekają na instalację

detail-admin-ok = Atlas ma uprawnienia do wprowadzenia zmian potrzebnych do instalacji.
detail-admin-missing = Otwórz Atlas ponownie jako administrator i wybierz Tak, gdy Windows poprosi o zezwolenie.
# $builds is a list of build numbers such as "26100 lub 26200"; $build is this PC's (text).
detail-build-unsupported = Ta wersja Atlasa wymaga kompilacji Windows { $builds }. Ten komputer ma kompilację { $build }. Zainstaluj obsługiwaną wersję Windows, zanim przejdziesz dalej.
detail-build-missing = Ten pakiet Atlasa nie podaje obsługiwanych kompilacji Windows. Użyj pełnej wersji pakietu zamiast wersji LocalTest.
detail-updates-none = Żadne aktualizacje Windows nie czekają na instalację.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Ta aktualizacja czeka na instalację: { $titles }. Atlas zainstaluje ją w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
        [2] Te aktualizacje czekają na instalację: { $titles }. Atlas zainstaluje je w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
        [few] { $count } aktualizacje czekają na instalację, w tym { $titles }. Atlas zainstaluje je w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
        [many] { $count } aktualizacji czeka na instalację, w tym { $titles }. Atlas zainstaluje je w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
       *[other] { $count } aktualizacji czeka na instalację, w tym { $titles }. Atlas zainstaluje je w sekcji Zaktualizuj Windows i aplikacje ze sklepu.
    }
detail-updates-unknown = Nie udało się sprawdzić aktualizacji Windows. Otwórz Windows Update, a jeśli żadne aktualizacje nie czekają na instalację, potwierdź to poniżej. ({ $error })
detail-reboot-none = Windows nie wymaga teraz ponownego uruchomienia.
detail-reboot-pending = Windows wymaga ponownego uruchomienia, aby dokończyć wcześniejsze zmiany. Gdy wybierzesz Sprawdź i zainstaluj aktualizacje, Atlas najpierw poprosi Cię o ponowne uruchomienie.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Windows wymaga ponownego uruchomienia, aby dokończyć wcześniejsze zmiany ({ $reasons }). Gdy wybierzesz Sprawdź i zainstaluj aktualizacje, Atlas najpierw poprosi Cię o ponowne uruchomienie.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Możesz kontynuować. Windows ma pliki do zastąpienia lub usunięcia przy następnym ponownym uruchomieniu ({ $files }). Niektóre aplikacje, na przykład Xbox Gaming Services, oznaczają takie pliki po każdym ponownym uruchomieniu.
detail-reboot-unknown = Nie udało się sprawdzić, czy Windows wymaga ponownego uruchomienia. Uruchom komputer ponownie, a potem otwórz Atlas i sprawdź ponownie. ({ $error })
detail-antivirus-none = Nie wykryto innego oprogramowania antywirusowego.
# $products is a list of product names (text).
detail-antivirus-found = Aplikacje antywirusowe inne niż Microsoft Defender mogą blokować instalację. Odinstaluj { $products }, a potem wybierz Sprawdź ponownie.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Zabezpieczenia Windows nadal wymieniają { $products }, ale pliki tego programu już nie istnieją, więc nie jest on już zainstalowany. Atlas można mimo to zainstalować.
detail-antivirus-unknown = Nie udało się sprawdzić, czy jest zainstalowane inne oprogramowanie antywirusowe. Wybierz Sprawdź ponownie. Jeśli problem się powtarza, uruchom komputer ponownie i sprawdź jeszcze raz. ({ $error })
detail-internet-ok = Masz połączenie z internetem. Nie przerywaj go, gdy Atlas będzie pobierać i instalować oprogramowanie.
detail-internet-missing = Połącz się z internetem, a potem sprawdź ponownie.
detail-power-mains = Komputer jest podłączony do zasilania. Nie odłączaj go do końca instalacji.
detail-power-battery = Podłącz komputer do zasilania, aby nie wyłączył się w trakcie instalacji.
detail-power-unknown = Atlas nie mógł ustalić, czy komputer jest podłączony do zasilania. Jeśli to laptop, podłącz go do zasilania, a potem wybierz Sprawdź ponownie. Jeśli to się powtarza, wybierz Wyślij zgłoszenie.
detail-activation-ok = Windows jest aktywowany. Atlas tego nie zmieni.
detail-activation-missing = Windows nie jest aktywowany. Możesz kontynuować, ale Atlas nie aktywuje Windows za Ciebie.
detail-activation-no-licence = Windows nie zgłosił licencji. Możesz kontynuować, Atlas nie zmieni stanu aktywacji.
detail-activation-unknown = Nie udało się sprawdzić aktywacji Windows. Możesz kontynuować, Atlas nie zmieni stanu aktywacji. ({ $error })

## Krok 2: Opcje

options-progress = Wybór { $number } z { $total }
options-progress-extras = Wybór { $number } z { $total }: opcjonalne dodatki
options-change-later = Ustawienia Microsoft Defender, zabezpieczeń procesora i aktualizacji możesz później zmienić w folderze Atlas na pulpicie.
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
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wybierz opcję dla: { $title }
learn-more-defender = Dowiedz się więcej o Microsoft Defender
learn-more-mitigations = Dowiedz się więcej o zabezpieczeniach procesora
learn-more-updates = Dowiedz się więcej o Windows Update
learn-more-browser = Dowiedz się więcej o przeglądarkach
learn-more-power = Dowiedz się więcej o zasilaniu i zabezpieczeniach
learn-more-apps = Dowiedz się więcej o aplikacjach
learn-more-eclean = Jak eclean współpracuje z AtlasOS
learn-more-generic = Przeczytaj przewodnik konfiguracji
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Zachowuje wbudowany program antywirusowy Windows, który pomaga chronić komputer przed wirusami i innymi zagrożeniami.
consequence-defender-disable = Usuwa też SmartScreen. Komputer nie będzie mieć ochrony antywirusowej, dopóki nie zainstalujesz innej aplikacji antywirusowej, a Windows nie będzie Cię ostrzegać przed otwarciem nierozpoznanych aplikacji lub pobranych plików.
consequence-mitigations-default = Zachowuje domyślne zabezpieczenia Windows chroniące przed lukami w procesorach i atakami wykorzystującymi błędy w aplikacjach.
consequence-mitigations-disable = Wyłącza też Ochronę przed lukami w zabezpieczeniach dla aplikacji, na przykład Ochronę przepływu sterowania (CFG). Zmniejsza to bezpieczeństwo. Ewentualna różnica w wydajności zależy od procesora.
consequence-auto-updates-disable = Regularnie otwieraj Windows Update, aby instalować aktualizacje. Powiadomienia o aktualizacjach pozostaną włączone.
consequence-auto-updates-default = Windows będzie automatycznie instalować aktualizacje, w tym poprawki zabezpieczeń.

## Tekst pakietu Atlasa
## Pakiet Atlasa zawiera własny angielski tekst każdej opcji. Te tłumaczenia
## są używane tylko wtedy, gdy tekst pakietu jest dokładnie taki jak w
## i18n/playbook-source.ftl, więc przyszły pakiet, który zmieni brzmienie opcji,
## pokaże własne słowa zamiast nieaktualnego tłumaczenia.

playbook-option-defender-enable = Zachowaj Microsoft Defender (zalecane)
playbook-option-defender-disable = Usuń Microsoft Defender
playbook-option-mitigations-default = Zachowaj zabezpieczenia procesora (zalecane)
playbook-option-mitigations-disable = Wyłącz zabezpieczenia procesora
playbook-option-auto-updates-disable = Będę instalować aktualizacje samodzielnie
playbook-option-auto-updates-default = Instaluj aktualizacje automatycznie
playbook-option-disable-hibernation = Wyłącz hibernację
playbook-option-disable-power-saving = Wyłącz oszczędzanie energii
playbook-option-disable-core-isolation = Wyłącz zabezpieczenia oparte na wirtualizacji (VBS)
playbook-option-remove-snipping-tool = Usuń Narzędzie Wycinanie
playbook-option-uninstall-edge = Usuń Microsoft Edge
playbook-option-install-another-browser = Zainstaluj przeglądarkę
playbook-option-install-toolbox = Zainstaluj Atlas Toolbox
playbook-option-install-eclean = Zainstaluj eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender to program antywirusowy wbudowany w Windows. Usuń go tylko wtedy, gdy rozumiesz ryzyko i zamierzasz używać innej aplikacji antywirusowej. Niezależnie od wyboru Atlas wyłącza Inteligentną kontrolę aplikacji, Rozszerzoną ochronę przed wyłudzaniem informacji i funkcję Znajdź moje urządzenie.
playbook-page-mitigations-default-description = Te zabezpieczenia, nazywane też środkami zaradczymi, pomagają chronić przed lukami w procesorach, takimi jak Spectre i Meltdown, oraz przed atakami wykorzystującymi błędy w aplikacjach. Zalecane jest zachowanie ustawień domyślnych Windows.
playbook-page-auto-updates-disable-description = Aktualizacje Windows zawierają poprawki zabezpieczeń. Windows może instalować je automatycznie albo możesz instalować je samodzielnie. W obu przypadkach Atlas pozostawia Windows w bieżącej wersji, która otrzymuje poprawki zabezpieczeń tylko do czasu, gdy Microsoft zakończy jej obsługę. Atlas wyłącza też automatyczne aktualizacje aplikacji z Microsoft Store, więc aktualizuj je w Microsoft Store.
playbook-page-browser-brave-description = Wybierz przeglądarkę do zainstalowania. Atlas nie zmieni ustawień przeglądarki.

## Krok 3: Zabezpieczenia Windows

security-banner-reading-title = Sprawdzanie Zabezpieczeń Windows
security-banner-reading-message = Atlas sprawdza cztery poniższe przełączniki ochrony.
security-banner-off-title = Cztery przełączniki ochrony są wyłączone
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender nie jest zainstalowany na tym komputerze
security-banner-absent-message = W tym kroku nie ma nic do wyłączenia. Wybierz Dalej.
security-banner-off-message = Wybierz Dalej, aby przejrzeć konfigurację i zainstalować Atlas.
security-banner-on-title = Wyłącz ochronę antywirusową w Zabezpieczeniach Windows
security-banner-on-message = Microsoft Defender może blokować zmiany wprowadzane przez Atlas. Wybierz Otwórz Zabezpieczenia Windows i wyłącz każdy z przełączników wymienionych poniżej. Jeśli zachowujesz Microsoft Defender, po zakończeniu instalacji włącz te przełączniki ponownie.
# The page name in Windows Security.
security-list-title = Ustawienia ochrony przed wirusami i zagrożeniami
security-switch-off = Wyłączone
security-switch-on = Włączone
security-switch-unreadable = Nie udało się sprawdzić
security-switch-reading = Sprawdzanie
security-all-off = Wszystkie wyłączone
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 nadal włączone, 1 niesprawdzony".
security-count-still-on =
    { $count ->
        [one] { $count } nadal włączony
        [few] { $count } nadal włączone
        [many] { $count } nadal włączonych
       *[other] { $count } nadal włączonych
    }
security-count-unreadable =
    { $count ->
        [one] { $count } niesprawdzony
        [few] { $count } niesprawdzone
        [many] { $count } niesprawdzonych
       *[other] { $count } niesprawdzonych
    }
security-count-join = { $a }, { $b }
security-unknown-title = Potwierdź przełączniki, których Atlas nie mógł sprawdzić
security-unknown-message = Upewnij się, że w Zabezpieczeniach Windows wszystkie cztery przełączniki są wyłączone, a potem potwierdź to poniżej.
security-acknowledge = Potwierdzam, że w Zabezpieczeniach Windows wszystkie cztery przełączniki są wyłączone
security-unknown-unelevated-title = Atlas potrzebuje uprawnień, aby sprawdzić ochronę
security-unknown-unelevated-message = Otwórz Atlas ponownie jako administrator, aby mógł sprawdzić ustawienia Microsoft Defender.
# The four switches, named as Windows Security names them.
protection-tamper = Ochrona przed naruszeniami
protection-tamper-why = Wyłącz tę ochronę, aby Defender nie blokował zmian, które Atlas wprowadza w jego ustawieniach zabezpieczeń.
protection-realtime = Ochrona w czasie rzeczywistym
protection-realtime-why = Wyłącz tę ochronę, aby Defender nie blokował plików instalacyjnych Atlasa podczas ich skanowania.
protection-cloud = Ochrona dostarczana z chmury
protection-cloud-why = Wyłącz tę ochronę, aby sprawdzanie zagrożeń online nie blokowało plików instalacyjnych Atlasa.
protection-samples = Automatyczne przesyłanie próbek
protection-samples-why = Wyłącz automatyczne wysyłanie plików Atlasa do firmy Microsoft w celu analizy.

## Krok 4: Instalacja

# Accessible name of the progress bar.
install-progress = Postęp instalacji
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = Atlas jest zainstalowany
outcome-lost-title = Nie udało się potwierdzić wyniku instalacji
outcome-failed-title = Instalacja nie została ukończona
outcome-requirements = Komputer nie spełnia wymagań instalacji. Nie wprowadzono żadnych zmian. Wróć do kroku Przygotowanie i wybierz Sprawdź ponownie.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = Komputer nie spełnił wymagań instalacji, więc ta próba została przerwana. Wcześniejsza próba zaczęła już wprowadzać zmiany. Wróć do kroku Przygotowanie i sprawdź komputer jeszcze raz.
outcome-not-elevated = Atlas nie miał uprawnień administratora. Nie wprowadzono żadnych zmian. Otwórz Atlas ponownie jako administrator i spróbuj jeszcze raz.
outcome-not-elevated-resumed = Atlas nie miał uprawnień administratora, więc ta próba została przerwana. Wcześniejsza próba zaczęła już wprowadzać zmiany. Otwórz Atlas ponownie jako administrator i spróbuj jeszcze raz.
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "Sprawdź i zainstaluj aktualizacje" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas nie mógł potwierdzić, że Windows i aplikacje ze sklepu są aktualne, więc instalacja zatrzymała się przed wprowadzeniem zmian w Windows. Wróć do kroku Przygotowanie i wybierz Sprawdź i zainstaluj aktualizacje.
outcome-preparation-stale-resumed = Atlas nie mógł potwierdzić, że Windows i aplikacje ze sklepu są aktualne, więc ta próba została przerwana, ale wcześniejsza próba zaczęła już wprowadzać zmiany. Wróć do kroku Przygotowanie i wybierz Sprawdź i zainstaluj aktualizacje.
outcome-failed-preflight = Instalacja zatrzymała się, zanim cokolwiek zmieniono. Możesz spróbować ponownie. Jeśli znów się zatrzyma, wybierz Wyślij zgłoszenie.
outcome-failed-staging = Instalacja zatrzymała się podczas przygotowywania plików, zanim cokolwiek zmieniono w Windows. Możesz spróbować ponownie. Jeśli znów się zatrzyma, wybierz Wyślij zgłoszenie.
outcome-failed-applying = Część zmian mogła już zostać wprowadzona. Możesz spróbować ponownie. Jeśli na tym poprzestaniesz, włącz ponownie w Zabezpieczeniach Windows wyłączone wcześniej funkcje ochrony, o ile są nadal dostępne.
outcome-failed-resumed = Ta próba została przerwana na wczesnym etapie, ale wcześniejsza próba zaczęła już wprowadzać zmiany. Możesz spróbować ponownie. Jeśli na tym poprzestaniesz, włącz ponownie w Zabezpieczeniach Windows wyłączone wcześniej funkcje ochrony, o ile są nadal dostępne.
outcome-not-started = Instalator nie uruchomił się na czas. Nie wprowadzono żadnych zmian. Możesz spróbować ponownie.
outcome-lost = Instalator zatrzymał się bez zgłoszenia wyniku, a część zmian mogła już zostać wprowadzona. Możesz spróbować ponownie. Jeśli na tym poprzestaniesz, włącz ponownie w Zabezpieczeniach Windows wyłączone wcześniej funkcje ochrony, o ile są nadal dostępne.
restart-now-message = Windows uruchamia się ponownie, aby dokończyć konfigurację Atlasa.
restart-countdown =
    { $seconds ->
        [one] Windows uruchomi się ponownie za { $seconds } sekundę, aby dokończyć konfigurację Atlasa. Jeśli chcesz najpierw zapisać pracę, wybierz Uruchom ponownie później.
        [few] Windows uruchomi się ponownie za { $seconds } sekundy, aby dokończyć konfigurację Atlasa. Jeśli chcesz najpierw zapisać pracę, wybierz Uruchom ponownie później.
        [many] Windows uruchomi się ponownie za { $seconds } sekund, aby dokończyć konfigurację Atlasa. Jeśli chcesz najpierw zapisać pracę, wybierz Uruchom ponownie później.
       *[other] Windows uruchomi się ponownie za { $seconds } sekundy, aby dokończyć konfigurację Atlasa. Jeśli chcesz najpierw zapisać pracę, wybierz Uruchom ponownie później.
    }
restart-stopped = Anulowano automatyczne ponowne uruchomienie. Zapisz pracę, a potem uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
restart-needed = Zapisz pracę, a potem uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
restart-dont-now = Uruchom ponownie później
restart-now = Uruchom ponownie teraz
restart-start-failed = Atlas nie mógł uruchomić komputera ponownie. Zapisz pracę, a potem uruchom go ponownie z menu Start. Szczegóły: { $error }
preflight-title = Instalacja się nie rozpoczęła
preflight-invalid-options = Atlas nie mógł użyć wybranych opcji. Wróć do kroku Opcje, przejrzyj je i spróbuj ponownie. Szczegóły: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Stan komputera zmienił się od wcześniejszego sprawdzenia. Rozwiąż następujące problemy, zanim spróbujesz ponownie. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 nadal włączone".
preflight-security = Zabezpieczenia Windows: { $summary }.
preflight-busy = Inne okno Atlasa rozpoczyna instalację. Poczekaj chwilę, a potem ponownie wybierz Zainstaluj Atlas.
# Shown with the home-start-over button.
preflight-taken-over = Inne okno Atlasa używa teraz tej konfiguracji, więc instalacja się nie rozpoczęła. Kontynuuj w tamtym oknie albo wybierz Zacznij od nowa, aby skonfigurować wszystko ponownie tutaj.
preflight-record-unreadable = Atlas nie mógł sprawdzić, czy poprzednia instalacja nadal trwa, więc nie rozpoczął kolejnej. Wróć do kroku Przygotowanie, aby zobaczyć, co zrobić dalej. Szczegóły: { $error }
preflight-refused = Nie udało się uruchomić instalatora. Nie wprowadzono żadnych zmian. Wybierz Zainstaluj Atlas, aby spróbować ponownie. Jeśli to się powtarza, wybierz Wyślij zgłoszenie. Szczegóły: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = Nie udało się uruchomić instalatora, więc ta próba została przerwana. Wcześniejsza próba zaczęła już wprowadzać zmiany. Wybierz Zainstaluj Atlas, aby spróbować ponownie. Jeśli to się powtarza, wybierz Wyślij zgłoszenie. Szczegóły: { $error }
go-to-ready = Wróć do kroku Przygotowanie
go-to-options = Wróć do kroku Opcje
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Wróć do kroku Instalacja
output-problem-title = Nie udało się odczytać postępu instalacji
output-problem-message = Atlas nie mógł odczytać dziennika. Nie oznacza to, że instalacja się zatrzymała. Nie wyłączaj komputera i spróbuj otworzyć plik dziennika. Szczegóły: { $error }
install-elevate-title = Do instalacji potrzebne są uprawnienia administratora
install-no-package-title = Najpierw wybierz pliki instalacyjne
install-no-package-message = Wróć do kroku Przygotowanie, aby pobrać Atlas lub otworzyć zapisany pakiet Atlasa (.apbx).
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = Wróć do kroku Przygotowanie, aby przygotować pakiet Atlasa dołączony do tej wersji testowej.
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Najpierw ukończ krok Przygotowanie
install-not-ready-message = Zanim Atlas będzie mógł rozpocząć instalację, musi dokończyć sprawdzanie komputera i aktualizowanie Windows.
install-security-title = Sprawdź ochronę antywirusową przed instalacją
install-security-reading = Ponowne sprawdzanie czterech przełączników ochrony.
install-security-message = { $summary }. Otwórz Zabezpieczenia Windows i upewnij się, że wszystkie cztery przełączniki są wyłączone, zanim rozpoczniesz instalację.
summary-try-again = Sprawdź przed kolejną próbą
summary-ready = Przejrzyj konfigurację Atlasa
summary-activation = Aktywacja
summary-activation-ok = Aktywowano. Atlas tego nie zmieni.
summary-activation-missing = Nie aktywowano. Możesz kontynuować, ale Atlas nie aktywuje Windows.
summary-activation-unknown = Atlas nie zmieni stanu aktywacji Windows.
summary-duration = Szacowany czas
summary-duration-value =
    { $minutes ->
        [one] { $minutes } minuta, potem ponowne uruchomienie
        [few] { $minutes } minuty, potem ponowne uruchomienie
        [many] { $minutes } minut, potem ponowne uruchomienie
       *[other] { $minutes } minuty, potem ponowne uruchomienie
    }
summary-restart-checkbox = Automatycznie uruchom komputer ponownie po instalacji
summary-show-command = Pokaż polecenie instalacji
summary-hide-command = Ukryj polecenie instalacji
summary-copy-command-a11y = Kopiuj polecenie instalacji
summary-command-unavailable = Nie udało się przygotować polecenia instalacji. Szczegóły: { $error }
summary-not-chosen = Jeszcze nie wybrano
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Zmień: { $title }
footer-still-checking = Przygotowywanie do instalacji
footer-fix-items = Napraw elementy w sekcji Sprawdzanie komputera, aby kontynuować
footer-need-package = Pobierz Atlas lub otwórz pakiet Atlasa, aby kontynuować
# Tester build variant of footer-need-package.
footer-need-package-bundled = Przygotuj dołączony pakiet Atlasa, aby kontynuować
footer-reading-security = Sprawdzanie przełączników ochrony
footer-security-pending = Wyłącz wszystkie cztery przełączniki, aby kontynuować
footer-security-confirm = Aby kontynuować, potwierdź przełączniki, których Atlas nie mógł sprawdzić
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

installing-checking-title = Ostatnie sprawdzenie
installing-checking-line = Atlas sprawdza komputer, zanim wprowadzi zmiany. Może to chwilę potrwać.
installing-title = Instalowanie Atlasa
installing-phase-preflight = Sprawdzanie komputera i przygotowywanie plików instalacyjnych.
installing-phase-staging = Przygotowywanie plików instalacyjnych. Nie wyłączaj komputera.
installing-phase-applying = Nie wyłączaj komputera i nie odłączaj zasilania, gdy Atlas konfiguruje Windows.
installing-phase-done = Kończenie instalacji. Nie wyłączaj komputera.
installing-installed-title = Atlas jest zainstalowany
# $time is a formatted clock time.
installing-started-just-now = Rozpoczęto o { $time }, mniej niż minutę temu
installing-started-minutes =
    { $minutes ->
        [one] Rozpoczęto o { $time }, minutę temu
        [few] Rozpoczęto o { $time }, { $minutes } minuty temu
        [many] Rozpoczęto o { $time }, { $minutes } minut temu
       *[other] Rozpoczęto o { $time }, { $minutes } minuty temu
    }
installing-restart-auto = Po zakończeniu instalacji komputer automatycznie uruchomi się ponownie. Do tego czasu zapisz pracę w innych aplikacjach.

## Okno „Atlas jest zainstalowany” po ponownym uruchomieniu

installed-title-version = Atlas { $version } jest zainstalowany
installed-title = Atlas jest zainstalowany
installed-ready = To wszystko. Komputer jest gotowy do pracy z Atlasem.
installed-security-message = Microsoft Defender został zachowany, ale niektóre jego funkcje ochrony są nadal wyłączone. Otwórz Zabezpieczenia Windows i upewnij się, że te przełączniki są włączone: { $switches }.
installed-defender-removed-title = Microsoft Defender został usunięty
installed-defender-removed-message = Komputer nie będzie mieć ochrony antywirusowej, dopóki nie zainstalujesz innej aplikacji antywirusowej. Usunięto też SmartScreen, więc Windows nie będzie Cię ostrzegać przed otwarciem nierozpoznanych aplikacji lub pobranych plików.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Wybrano zachowanie Microsoft Defender, ale nie ma go na tym komputerze. Jeśli nie używasz innej aplikacji antywirusowej, zainstaluj taką aplikację, aby chronić komputer. Jeśli Defender nie został usunięty przez Ciebie, wybierz Zgłoś problem.

## Ustawienia

settings-title = Ustawienia
settings-theme = Motyw aplikacji
settings-theme-system = Jak w Windows
settings-theme-light = Jasny
settings-theme-dark = Ciemny
settings-theme-contrast-note = Atlas używa kolorów motywu kontrastowego Windows.
settings-theme-mica-note = Aby wyświetlić przezroczyste tło, wybierz ten sam motyw (jasny lub ciemny) co w Windows.
settings-language = Język
settings-language-system = Jak w Windows
settings-language-system-selected = { settings-language-system } ({ $language })
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Po wybraniu „Jak w Windows”: { $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Wersja wstępna
# Under the language list, once, explaining the Preview tag.
settings-language-preview-note = Tłumaczenia w wersji wstępnej nie zostały jeszcze sprawdzone przez rodzimego użytkownika języka.
preview-notice = To tłumaczenie ({ $language }) jest wersją wstępną i może zawierać błędy.
preview-notice-switch = Przełącz na angielski
preview-notice-language = Zmień język
# $tag is a language tag (text).
settings-language-unavailable = Język { $tag } nie jest dostępny w tej wersji Atlasa. Na razie wyświetlany jest angielski, a Twój wybór pozostaje zapisany.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas nie obsługuje jeszcze Twoich języków wyświetlania Windows ({ $languages }). Na razie wyświetlany jest angielski.
settings-language-windows-unavailable = Nie udało się sprawdzić języka wyświetlania Windows. Na razie Atlas używa angielskiego. Szczegóły: { $error }
# $locale is the regional format's own name, for example "polski (Polska)".
settings-language-formats = Liczby, daty i godziny są zgodne z formatem regionalnym Windows ({ $locale }).
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Liczby są zgodne z formatem regionalnym Windows ({ $locale }). Daty i godziny są wyświetlane w formacie standardowym, ponieważ Atlas nie może jeszcze wyświetlać tekstu pisanego od prawej do lewej.
settings-language-contribute = Pomóż tłumaczyć Atlas w serwisie GitHub
settings-restart-label = Automatycznie uruchom komputer ponownie po instalacji
settings-restart-locked = Możesz to zmienić po zakończeniu instalacji.
settings-restart-description = Gdy ta opcja jest włączona, komputer uruchomi się ponownie w ciągu minuty od zakończenia instalacji, co zamknie otwarte aplikacje. Zapisz pracę przed instalacją.
settings-help = Pomoc i opinie
settings-about = Informacje
settings-about-app = Atlas Manager
settings-about-licence = Licencja
settings-about-licence-value = GPL-3.0, wolne i otwarte oprogramowanie
settings-view-source = Zobacz kod źródłowy w serwisie GitHub
# Link that opens the third-party licence notices.
settings-view-licences = Zobacz informacje o licencjach
# Under the links when Windows could not open the notices.
settings-licences-failed = Nie udało się otworzyć informacji o licencjach. Spróbuj ponownie lub znajdź je w kodzie źródłowym w serwisie GitHub.
settings-open-data-folder = Otwórz folder aplikacji

## Opcjonalne dodatki: objaśnienia widoczne przed wyborem.

consequence-disable-hibernation = Zwalnia miejsce na dysku, w którym zapisywana jest sesja podczas hibernacji. Hibernacja i szybkie uruchamianie będą niedostępne.
consequence-disable-power-saving = Wyłącza funkcje oszczędzania energii. Komputer może zużywać więcej prądu, mocniej się nagrzewać i krócej działać na baterii.
consequence-disable-core-isolation = Wyłącza dodatkową warstwę zabezpieczeń Windows, w tym integralność pamięci. Zmniejsza to ochronę i może wpływać na aplikacje lub gry, które jej wymagają.
consequence-remove-snipping-tool = Usuwa aplikację Windows do robienia zrzutów ekranu i nagrywania ekranu.
consequence-uninstall-edge = Usuwa przeglądarkę Microsoft Edge. Upewnij się, że masz inną przeglądarkę, lub wybierz jedną poniżej.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Usuwa Microsoft Edge oraz zakładki, historię i zapisane hasła przeglądarki Edge na tym komputerze. Wszystko, czego nie zsynchronizowano z kontem Microsoft, zostanie utracone. Upewnij się, że masz inną przeglądarkę, lub wybierz jedną poniżej.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Usuwa zakładki, historię i zapisane hasła przeglądarki Edge na tym komputerze.
consequence-install-another-browser = Wybierz przeglądarkę poniżej, a Atlas ją zainstaluje.
consequence-install-toolbox = Atlas Toolbox pomaga zarządzać ustawieniami Atlasa. Jest w wersji beta, więc niektóre funkcje mogą być jeszcze niedokończone.
consequence-install-eclean = Narzędzie do konserwacji od zespołu AtlasOS, które pomaga utrzymać porządek na komputerze po konfiguracji. Przeglądaj zbędne pliki i aplikacje startowe. Wymaga konta i połączenia z internetem.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas dostosowuje Windows, aby ograniczyć aktywność w tle i rozpraszające elementy. Zainstaluj Atlas na czystej instalacji Windows, zanim dodasz własne aplikacje i pliki.

## ISO creation (Beta)
iso-home-title = Nośnik instalacyjny Windows
iso-home-description = Utwórz plik instalacyjny Windows (ISO) z Atlasem, a potem użyj go do ponownej instalacji Windows na tym lub innym komputerze.
iso-open = Utwórz ISO z Atlasem
iso-title = Utwórz ISO z Atlasem
iso-beta = Beta
iso-beta-description = Przetestuj obraz ISO na maszynie wirtualnej, zanim użyjesz go na komputerze. Przed instalacją Windows zrób kopię zapasową plików.
iso-admin-description = Atlas potrzebuje uprawnień administratora, aby odczytać obraz ISO Windows i utworzyć nowy. Wybierz Otwórz ponownie jako administrator, a potem wybierz Tak, gdy Windows zapyta.
iso-files-description = Atlas tworzy kopię obrazu ISO Windows 11 z dodanym Atlasem, przeznaczoną do ponownej instalacji Windows. Wybierz obraz ISO Windows 11 pobrany od firmy Microsoft, pobierz najnowszy pakiet Atlasa lub wybierz posiadany już pakiet (.apbx), a potem wskaż, gdzie zapisać nowy obraz ISO.
# Tester build: no package picker.
iso-files-description-bundled = Atlas tworzy kopię obrazu ISO Windows 11 z dodanym pakietem Atlasa dołączonym do tej wersji testowej. Wybierz obraz ISO Windows 11 pobrany od firmy Microsoft, a potem wskaż, gdzie zapisać nowy obraz ISO.
iso-source = Obraz ISO Windows
iso-source-download = Pobierz Windows 11 od firmy Microsoft
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Pakiet Atlasa ({ $minimum } lub nowszy)
iso-output = Zapisz nowy obraz ISO w
iso-no-file = Nie wybrano pliku
iso-browse = Przeglądaj
iso-save-as = Zapisz jako
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Sprawdź pliki
iso-mode-title = Jak chcesz skonfigurować Atlas?
iso-mode-interactive = Wybierz opcje Atlasa po zalogowaniu
iso-mode-interactive-description = Po zalogowaniu Atlas otworzy się i przeprowadzi Cię przez aktualizacje, wybór opcji i instalację Atlasa.
iso-mode-before = Wybierz opcje Atlasa teraz
iso-mode-before-description = Atlas zapisze wybrane opcje w obrazie ISO. Po zalogowaniu Atlas otworzy się i przeprowadzi Cię przez aktualizacje, a potem zainstalujesz Atlas z tymi opcjami.
iso-package-unsupported-title = Wybierz nowszy pakiet Atlasa
# "Wybierz opcje Atlasa po zalogowaniu" is iso-mode-interactive.
iso-package-unsupported = Ten pakiet Atlasa nie pozwala zapisać opcji Atlasa w obrazie ISO. Wybierz nowszy pakiet albo zaznacz Wybierz opcje Atlasa po zalogowaniu.
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = Tego pakietu Atlasa nie można użyć do utworzenia obrazu ISO. Wybierz pakiet Atlasa w wersji { $minimum } lub nowszej.
# Tester build: the bundled Atlas package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = Nie można zapisać opcji Atlasa w tym obrazie ISO
# "Wybierz opcje Atlasa po zalogowaniu" is iso-mode-interactive.
iso-package-unsupported-bundled = Pakiet Atlasa dołączony do tej wersji testowej nie obsługuje konfiguracji z ISO. Zamiast tego zaznacz Wybierz opcje Atlasa po zalogowaniu.
iso-atlas-options = Opcje Atlasa
iso-review = Sprawdź podsumowanie
iso-review-description = Utworzenie obrazu ISO niczego nie instaluje na tym komputerze i nie zmienia oryginalnego obrazu ISO. Potem Atlas może zapisać nowy obraz na dysku USB, z którego zainstalujesz ponownie Windows.
iso-review-files = Pliki
iso-step-windows = Konfiguracja Windows
iso-step-review = Podsumowanie
iso-review-package = Pakiet Atlasa
iso-review-output = Nowy obraz ISO
iso-review-editions = Edycje
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nazwa konta
iso-review-target = Instalacja na
iso-review-drivers = Sterowniki
iso-create = Utwórz ISO
iso-progress-title = Tworzenie obrazu ISO
iso-stage-inspect = Sprawdzanie obrazu ISO Windows
iso-stage-copy = Kopiowanie plików Windows
iso-stage-add-atlas = Dodawanie Atlasa
iso-stage-master = Zapisywanie pliku ISO
iso-stage-verify = Sprawdzanie nowego obrazu ISO
iso-stage-cleanup = Kończenie
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = w toku
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = nie powiodło się
iso-stage-status-not-started = nie rozpoczęto
iso-progress-description = Pozostaw Atlas otwarty. Przetwarzanie dużych obrazów może potrwać.
iso-cancel = Anuluj tworzenie
iso-cancelling = Oczekiwanie na bezpieczne zatrzymanie
iso-cancelled = Anulowano tworzenie ISO
iso-cancelled-description = Oryginalny obraz ISO nie został zmieniony. Jeśli pozostały jakieś pliki tymczasowe, wybierz Otwórz folder dzienników, aby zobaczyć, gdzie się znajdują.
iso-complete = Obraz ISO jest gotowy
iso-complete-description = Tworzenie obrazów ISO jest w wersji beta, więc najpierw przetestuj obraz na maszynie wirtualnej. Potem wybierz Utwórz USB instalacyjne i zrób kopię zapasową plików, zanim zainstalujesz ponownie Windows.
iso-open-folder = Pokaż w folderze
iso-failed = Nie udało się utworzyć obrazu ISO
iso-failed-description = Upewnij się, że wybrane pliki nadal są na swoim miejscu i dysk docelowy jest podłączony, a potem wybierz Utwórz ISO. Jeśli problem się powtarza, wybierz Wyślij zgłoszenie.
# Title while the Check files step fails; the messages below say why.
iso-check-failed = Nie udało się sprawdzić plików
iso-check-failed-description = Upewnij się, że obraz ISO i pakiet Atlasa nadal są w wybranym miejscu i zostały w pełni pobrane, a potem wybierz Sprawdź pliki. Jeśli problem się powtarza, wybierz Wyślij zgłoszenie.
# Title when Windows refused the administrator relaunch (UAC declined); elevation-declined is the message.
iso-elevation-title = Atlas potrzebuje uprawnień, aby utworzyć obraz ISO
# Typed reasons reported by the image worker.
iso-failed-output-exists = Plik o tej nazwie już istnieje. Wybierz Zapisz jako i wpisz nową nazwę pliku.
iso-failed-destination = Atlas nie może zapisać tam nowego obrazu ISO. Wybierz Zapisz jako i wskaż folder na tym komputerze, na przykład Pobrane. Nie można używać lokalizacji sieciowych ani dysków sformatowanych w systemie FAT32 lub exFAT, takich jak wiele dysków USB.
iso-failed-space = Na dysku docelowym nie ma wystarczającej ilości wolnego miejsca. Zwolnij miejsce lub zapisz nowy obraz ISO na innym dysku.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Ten obraz ISO nie zawiera żadnej obsługiwanej edycji Windows. Edycje Windows Home i LTSC nie są obsługiwane. Użyj obrazu ISO z inną edycją, na przykład Pro, Education lub Enterprise.
iso-failed-customised = Ten obraz ISO zawiera już niestandardowe pliki instalacyjne, takie jak autounattend.xml. Wybierz niezmodyfikowany obraz ISO Windows od firmy Microsoft.
iso-failed-windows-unsupported = Ten obraz Windows nie jest obsługiwany przez pakiet Atlasa. Użyj niezmodyfikowanego 64-bitowego obrazu ISO Windows 11 w wersji obsługiwanej przez ten pakiet.
iso-failed-network-architecture = Sterowniki sieciowe tego komputera nie pasują do architektury obrazu ISO. Wróć i wyłącz opcję Dołącz sterowniki sieciowe tego komputera albo wybierz obraz ISO przeznaczony dla tego komputera.
iso-failed-unstaged = Atlas nie mógł przygotować folderu roboczego, więc nic nie zostało zmienione. Spróbuj ponownie. Jeśli problem się powtarza, wybierz Eksportuj diagnostykę i dołącz ją do zgłoszenia błędu.
iso-failed-package-changed = Pakiet Atlasa zmienił się po sprawdzeniu plików. Wybierz Zmień obok sekcji Pliki, a potem wybierz Sprawdź pliki.
iso-diagnostics = Otwórz folder dzienników
iso-close-title = Tworzenie ISO nadal trwa
iso-close-message = Pozostaw to okno otwarte, aż tworzenie lub anulowanie się zakończy. Anulowanie nastąpi, gdy bieżącą operację będzie można bezpiecznie zatrzymać.
iso-keep-open = Pozostaw otwarte
prepare-title = Zaktualizuj Windows i aplikacje ze sklepu
prepare-description = Przed instalacją Atlas aktualizuje Windows, Microsoft Store i aplikacje ze sklepu. Otwarte aplikacje ze sklepu, takie jak Notatnik, Paint czy Terminal Windows, mogą zostać zamknięte podczas aktualizacji, więc najpierw zapisz w nich pracę. Komputer może też wymagać ponownego uruchomienia.
prepare-complete = Atlas nie znalazł już żadnych aktualizacji Windows ani aplikacji ze sklepu do zainstalowania.
prepare-reboot-title = Uruchom komputer ponownie, aby kontynuować
prepare-reboot = Komputer wymaga ponownego uruchomienia, aby dokończyć instalowanie aktualizacji. Atlas zapisze dotychczas wybrane opcje i otworzy się ponownie po zalogowaniu.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = Komputer wymaga ponownego uruchomienia, aby dokończyć instalowanie aktualizacji ({ $reasons }). Atlas zapisze dotychczas wybrane opcje i otworzy się ponownie po zalogowaniu.
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = Najpierw zapisz pracę i zamknij aplikacje. Komputer uruchomi się ponownie natychmiast, gdy wybierzesz Uruchom ponownie i kontynuuj.
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = Komputer został uruchomiony ponownie, ale Windows nadal zgłasza, że wymaga ponownego uruchomienia ({ $reasons }), więc kolejne ponowne uruchomienie raczej nie pomoże. Wybierz Otwórz Windows Update i dokończ wszystko, co tam czeka, a potem wybierz Spróbuj ponownie. Jeśli nic nie czeka, wybierz Wyślij zgłoszenie.
# Names of the markers Windows sets when it wants a restart. They complete
# "Windows wymaga ponownego uruchomienia (…)"; keep them short and lower case.
prepare-reason-servicing = obsługa serwisowa Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = pliki oczekujące na zastąpienie
prepare-reason-update-agent = usługa Windows Update
prepare-reason-unknown = nie podano przyczyny
prepare-failed = Wybierz Spróbuj ponownie. Jeśli znów się nie uda, dokończ pozostałe aktualizacje w Windows Update lub Microsoft Store albo wybierz Wyślij zgłoszenie.
prepare-failed-title = Nie udało się ukończyć części aktualizacji
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Spróbuj ponownie" is common-try-again, the button beside it.
prepare-ended-unconfirmed = Aktualizowanie zatrzymało się przed zgłoszeniem wyniku, więc Atlas nie może potwierdzić, że Windows i aplikacje ze sklepu są aktualne. Wybierz Spróbuj ponownie, aby sprawdzić aktualizacje.
prepare-unconfirmed-title = Nie udało się potwierdzić wyniku aktualizacji
# "Sprawdź i zainstaluj aktualizacje" is prepare-start, its button in this state.
prepare-cancelled = Aktualizowanie zostało zatrzymane. Część aktualizacji mogła już zostać zainstalowana. Wybierz Sprawdź i zainstaluj aktualizacje, aby je dokończyć, zanim przejdziesz dalej.
prepare-windows-search = Sprawdzanie aktualizacji Windows…
prepare-windows-download = Pobieranie aktualizacji Windows…
prepare-windows-install = Instalowanie aktualizacji Windows…
prepare-store-search = Sprawdzanie Microsoft Store…
prepare-store-install = Aktualizowanie Microsoft Store i aplikacji…
prepare-stop-description = Atlas zatrzyma się po zakończeniu bieżącego etapu. Do tego czasu pozostaw Atlas otwarty.
prepare-stop = Zatrzymaj aktualizowanie
prepare-restart = Uruchom ponownie i kontynuuj
prepare-start = Sprawdź i zainstaluj aktualizacje
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = Niedostępne, ponieważ tej instalacji nie można kontynuować. Zobacz komunikat u góry strony.
prepare-needs-build-check = Dostępne, gdy pozycja { $check } w sekcji Sprawdzanie komputera będzie w porządku.
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = Dostępne, gdy pliki instalacyjne będą gotowe.
iso-username = Nazwa konta lokalnego
iso-account-description = Podczas konfiguracji Windows zostanie utworzone konto lokalne o tej nazwie, więc konto Microsoft nie będzie potrzebne. Przy pierwszym logowaniu Windows poprosi Cię o ustawienie hasła.
iso-username-placeholder = Twoje imię
iso-account-empty = Wpisz nazwę konta lokalnego, aby kontynuować
iso-account-invalid = Użyj maksymalnie 20 znaków, bez spacji na początku i na końcu oraz bez tych znaków: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Nazwa nie może kończyć się kropką.
iso-account-reserved = Windows używa tej nazwy dla wbudowanego konta. Wybierz inną nazwę.
iso-privacy-defaults = Ten obraz ISO pomija ekrany licencji, konta Microsoft i prywatności podczas konfiguracji Windows oraz wyłącza opcjonalne udostępnianie danych i spersonalizowane oferty.
prepare-drivers = Jak chcesz instalować sterowniki?
prepare-drivers-auto = Pobieraj sterowniki przez Windows Update
prepare-drivers-auto-detail = Windows wyszuka sterowniki do Twojego sprzętu. Zalecane dla większości komputerów.
prepare-drivers-manual = Zainstaluję sterowniki samodzielnie
prepare-drivers-manual-detail = Windows Update nie będzie instalować sterowników, więc trzeba będzie pobrać je od producenta komputera lub urządzenia. Już zainstalowane sterowniki zostaną zachowane.
prepare-drivers-description = Sterowniki pozwalają Windows korzystać ze sprzętu, takiego jak karta graficzna, dźwięk i Wi-Fi. Jeśli zmienisz to ustawienie po aktualizacji, Atlas będzie musiał ponownie sprawdzić aktualizacje.
prepare-network-needed = Aktualizacje wymagają połączenia z internetem, które nie jest taryfowe. Połącz się przez Wi-Fi lub Ethernet, a potem wybierz Spróbuj ponownie. Jeśli nie widzisz żadnych sieci Wi-Fi, najpierw zainstaluj sterownik sieciowy.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows zgłasza, że ta sieć nie ma dostępu do internetu. Zaloguj się do sieci, jeśli o to prosi, lub sprawdź router oraz ewentualne filtrowanie przez DNS lub zaporę, a potem spróbuj ponownie.
# "Połączenie taryfowe" is the switch's name in Windows network settings.
prepare-network-metered = To połączenie jest taryfowe lub ma ustawiony limit danych. Połącz się z siecią bez takich ograniczeń albo wyłącz opcję Połączenie taryfowe w ustawieniach sieci, a potem spróbuj ponownie.
prepare-network-settings = Otwórz ustawienia sieci
iso-target-title = Na którym komputerze chcesz ponownie zainstalować Windows?
iso-target-this = Na tym komputerze
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas może dodać do obrazu ISO sterowniki Wi-Fi i Ethernet tego komputera, aby Windows mógł połączyć się z internetem od razu po ponownej instalacji.
iso-target-other = Na innym komputerze
iso-copy-network = Dołącz sterowniki sieciowe tego komputera
iso-network-detail = Wykorzystuje sterowniki Wi-Fi i Ethernet tego komputera podczas instalacji Windows. Po instalacji połącz się ponownie z Wi-Fi.
iso-network-source = Źródło sterowników sieciowych
iso-network-installed = Użyj zainstalowanych sterowników
iso-network-updated = Najpierw sprawdź Windows Update
iso-network-updated-detail = Pobiera pasujące sterowniki z Windows Update i zachowuje zainstalowane jako zapasowe. Wymaga połączenia nietaryfowego.
iso-stage-network-drivers = Przygotowywanie sterowników sieciowych
iso-network-failed = Nie udało się przygotować sterowników sieciowych. Sprawdź dane diagnostyczne lub wróć i zmień opcję sterowników sieciowych.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Karty sieciowe tego komputera używają sterowników wbudowanych w Windows, więc obraz ISO nie musi ich zawierać.
iso-mode-desktop = Dokończ konfigurację przed otwarciem pulpitu
iso-mode-desktop-description = Atlas zapisze wybrane opcje w obrazie ISO. Po zalogowaniu Atlas dokończy aktualizacje i instalację, zanim otworzy się pulpit Windows.
desktop-setup-description = Dokończ konfigurację komputera. Wybrane opcje Atlasa są zapisane; w razie potrzeby możesz wrócić do Windows.
desktop-setup-exit = Kontynuuj w Windows

# Windows installation USB (Beta)
usb-title = Utwórz USB instalacyjne
usb-existing = Utwórz USB z istniejącego obrazu ISO
usb-description = Zapisz obraz ISO na dysku USB, aby zainstalować z niego ponownie Windows. Użyj obrazu ISO utworzonego przez Atlas, aby jednocześnie zainstalować Atlas.
usb-choose-iso = Wybierz ISO
usb-drive = Dysk USB
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = Nie znaleziono dysków USB. Podłącz dysk USB o pojemności co najmniej { $min } GB, a potem wybierz Odśwież. Dyski większe niż { $max } TB, dyski tylko do odczytu i dysk, z którego działa Windows, nie są wyświetlane.
usb-refresh = Odśwież
# Shown when the drive list could not be read.
usb-scan-failed = Sprawdź, czy dysk jest podłączony, a potem wybierz Odśwież. Aby zobaczyć szczegóły, wybierz Otwórz folder dzienników.
usb-scan-failed-title = Nie udało się odczytać listy dysków USB
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = Numer seryjny: { $serial }
usb-detail-separator = { " · " }
usb-review = Sprawdź USB
usb-erase-title = Wymazać ten dysk USB?
usb-erase-description = Cała zawartość dysku { $drive } ({ $size } GB) zostanie trwale wymazana, w tym wszystkie pliki i partycje. Najpierw skopiuj na inny dysk wszystko, co chcesz zachować. Obraz ISO nie zostanie usunięty.
usb-layout = Atlas użyje do 32 GB dysku, a resztę pozostawi niewykorzystaną. Dysk USB działa na komputerach uruchamianych w trybie UEFI, którego wymaga Windows 11.
usb-ack = Rozumiem, że cała zawartość tego dysku USB zostanie wymazana
usb-write = Wymaż i utwórz USB
usb-stage-prepare = Przygotowywanie plików instalacyjnych…
usb-stage-format = Formatowanie USB…
usb-stage-copy = Kopiowanie plików instalacyjnych…
usb-stage-verify = Weryfikowanie USB…
usb-working = Pozostaw Atlas otwarty i dysk USB podłączony. Jeśli anulujesz, nieukończonego dysku USB nie będzie można użyć do instalacji Windows.
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = Nie udało się ukończyć tworzenia USB
usb-complete-title = Nośnik USB jest gotowy
usb-close-title = Tworzenie USB nadal trwa
# After erasing may have begun.
usb-failed = Dysk mógł już zostać wymazany, więc nie nadaje się jeszcze do instalacji Windows. Upewnij się, że jest podłączony, a potem wybierz Sprawdź USB, aby spróbować ponownie. Jeśli dysk został ponownie podłączony, najpierw wybierz Odśwież i zaznacz go jeszcze raz.
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = Na dysku USB nie wprowadzono zmian. Wybierz Otwórz folder dzienników, aby sprawdzić, co się nie powiodło, a potem wybierz Sprawdź USB, aby spróbować ponownie.
usb-failed-iso = Tego obrazu ISO nie można użyć do utworzenia instalacyjnego dysku USB. Wybierz obraz ISO utworzony przez Atlas albo obraz ISO Windows 11 od firmy Microsoft w wersji obsługiwanej przez Atlas. Na dysku USB nie wprowadzono zmian.
usb-failed-location = Obraz ISO lub Atlas Manager znajduje się na tym dysku USB, w lokalizacji sieciowej lub w połączonym folderze. Przenieś go do lokalnego folderu na tym komputerze i spróbuj ponownie. Na dysku USB nie wprowadzono zmian.
usb-failed-space = Na dysku z systemem Windows nie ma wystarczającej ilości wolnego miejsca, aby przygotować pliki instalacyjne. Zwolnij miejsce i spróbuj ponownie. Na dysku USB nie wprowadzono zmian.
usb-failed-fit = Pliki instalacyjne nie mieszczą się na tym dysku USB. Użyj większego dysku i spróbuj ponownie. Na dysku USB nie wprowadzono zmian.
usb-failed-drive-changed = Dysk USB został odłączony, ponownie podłączony lub wymieniony po odczytaniu listy. Wybierz Odśwież, zaznacz dysk jeszcze raz, a potem wybierz Sprawdź USB. Na dysku USB nie wprowadzono zmian.
usb-cancelled = Dysk może zawierać niekompletne pliki instalacyjne. Utwórz go ponownie, zanim użyjesz go do instalacji Windows.
usb-cancelled-title = Anulowano tworzenie USB
usb-cancelled-unchanged = Na dysku USB nie wprowadzono zmian.
usb-complete = Atlas sprawdził wszystkie pliki. Wybierz Wysuń USB, a potem zrób kopię zapasową plików na komputerze, na którym chcesz ponownie zainstalować Windows. Podłącz dysk do tego komputera i uruchom go z dysku USB za pomocą menu rozruchowego (często F12, F11 lub Esc podczas uruchamiania komputera).
usb-eject = Wysuń USB
usb-ejected = Możesz teraz odłączyć dysk USB. Zrób kopię zapasową plików na komputerze, na którym chcesz ponownie zainstalować Windows. Potem uruchom ten komputer z dysku USB za pomocą jego menu rozruchowego (często F12, F11 lub Esc podczas uruchamiania).
usb-eject-failed = Zamknij pliki lub okna, które korzystają z tego dysku, i spróbuj ponownie.
usb-eject-failed-title = Nie udało się wysunąć dysku USB
ready-fresh-title = Atlas jest przeznaczony do czystej instalacji Windows
ready-fresh-description = Jeśli korzystasz już z Windows na tym komputerze, zrób kopię zapasową plików i zainstaluj ponownie Windows, zanim przejdziesz dalej. Najpierw sprawdź, czy pozycja Zgodność z Windows w sekcji Sprawdzanie komputera jest w porządku, aby zainstalować ponownie obsługiwaną wersję.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Edycje Windows 11 Home, LTSC i Server nie są obsługiwane. Użyj innej edycji, na przykład Pro, Education lub Enterprise. Jeśli Windows nie mógł rozpoznać Twojej edycji, rozwiąż ten problem, zanim przejdziesz dalej.
install-source-title = Instalacja niedostępna
install-source-unsupported = Nie można zaktualizować Atlasa { $source } bezpośrednio do { $target }. Aby użyć tej wersji, zrób kopię zapasową plików i zainstaluj ponownie Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Nie można bezpośrednio zaktualizować Atlasa { $source }. Aby użyć nowszej wersji, zrób kopię zapasową plików i zainstaluj ponownie Windows.
# "Otwórz plik pakietu" is package-open-file. $folder is a folder path (text).
install-source-resume = Instalacja Atlasa { $target } nie została ukończona i można ją dokończyć tylko za pomocą pakietu Atlasa { $target }. Wybierz Otwórz plik pakietu i wskaż ten pakiet Atlasa (.apbx). Jeśli Atlas go pobrał, znajduje się w folderze { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Instalacja Atlasa { $target } nie została ukończona. Ta wersja testowa może zainstalować tylko dołączony do niej pakiet Atlasa, więc dokończ tę instalację za pomocą pakietu Atlasa { $target } w oficjalnym wydaniu aplikacji Atlas Manager.
install-source-unknown = Atlas nie mógł ustalić, co jest już zainstalowane na tym komputerze, więc na razie niczego nie zainstaluje. Wybierz Wyślij zgłoszenie, aby zespół Atlasa mógł pomóc.
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } Szczegóły: { $error }
iso-edition-selection = Uwzględnione są tylko obsługiwane edycje. Podczas instalacji Windows wybierz edycję, na którą masz licencję Windows.
detail-windows-preview = Kompilacje Insider nie są obsługiwane. Użyj publicznie wydanej wersji systemu Windows 11.
detail-windows-release-unknown = Atlas nie mógł potwierdzić, że ta kompilacja systemu Windows została publicznie wydana. Połącz się z internetem i sprawdź ponownie.
iso-release-unknown = Atlas nie mógł potwierdzić, że ten obraz ISO zawiera publicznie wydaną wersję Windows 11 obsługiwaną przez pakiet Atlasa. Połącz się z internetem, a potem ponownie wybierz Sprawdź pliki. Jeśli to nie pomoże, pobierz obraz ISO od firmy Microsoft jeszcze raz.
prepare-previous-worker = Wcześniej rozpoczęte aktualizacje nadal trwają. Atlas poczeka na ich zakończenie, a potem możesz ponownie sprawdzić aktualizacje.

ready-used-windows-title = Windows na tym komputerze wygląda na używany
ready-used-windows-description = Windows na tym komputerze został zainstalowany co najmniej tydzień temu lub ma już kilka aplikacji. Instalowanie Atlasa w takim systemie nie jest obsługiwane i jest stanowczo odradzane: istniejące aplikacje i ustawienia mogą nie działać zgodnie z oczekiwaniami. Atlas usuwa też OneDrive, więc pliki w OneDrive przestaną się synchronizować, a foldery Pulpit, Dokumenty i Obrazy mogą wyglądać na puste. Najpierw zrób kopię zapasową plików i zainstaluj ponownie Windows albo kontynuuj tylko wtedy, gdy akceptujesz to ryzyko.
ready-used-windows-dismiss = Kontynuuj mimo to

prepare-resumed = Komputer został uruchomiony ponownie, a Atlas przywrócił dotychczas wybrane opcje. Wybierz Kontynuuj aktualizacje, aby dokończyć aktualizowanie przed instalacją Atlasa.
prepare-continue = Kontynuuj aktualizacje
prepare-saving-restart = Zapisywanie wybranych opcji i ustawianie ponownego otwarcia Atlasa po ponownym uruchomieniu Windows…
prepare-restart-save-failed = Nie udało się zapisać wybranych opcji. Spróbuj ponownie przed ponownym uruchomieniem.
prepare-restart-registration-failed = Wybrane opcje zostały zapisane, ale Atlas nie mógł ustawić automatycznego otwarcia po ponownym uruchomieniu. Spróbuj jeszcze raz albo uruchom komputer ponownie samodzielnie i otwórz Atlas po zalogowaniu.
prepare-restart-failed = Atlas nie mógł uruchomić komputera ponownie. Spróbuj jeszcze raz albo uruchom go ponownie z menu Start. Wybrane opcje są zapisane, a Atlas otworzy się ponownie po zalogowaniu.
diagnostics-export = Eksportuj diagnostykę
diagnostics-exporting = Zbieranie danych diagnostycznych…
diagnostics-privacy = Wyślij zgłoszenie prywatnie do zespołu Atlasa albo wyeksportuj plik ZIP z diagnostyką, aby udostępnić go, gdy poprosisz o pomoc. Atlas usuwa z niego Twoją nazwę użytkownika, nazwę komputera i adresy e-mail.
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Utworzono ZIP z diagnostyką
diagnostics-failed-title = Nie udało się wyeksportować diagnostyki
# $error is the raw error (text).
diagnostics-failed = Sprawdź, czy na dysku komputera jest wolne miejsce, i spróbuj ponownie. Szczegóły: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Wersja testowa Atlasa { $release }. Ta aplikacja instaluje tylko dołączony pakiet Atlasa.
home-status-bundled = Wersja testowa { $release }
package-bundled = Atlas { $version } dołączony do tej wersji testowej jest gotowy do instalacji.
rc-about-release = Wersja testowa
rc-about-commit = Commit źródłowy
rc-about-package = Dołączony pakiet Atlasa (SHA-256)
iso-package-bundled = Pakiet Atlasa dołączony do tej wersji testowej
prepare-percent = { $percent }% tego etapu
prepare-count = Ukończone aktualizacje: { $completed } z { $total }
prepare-bytes = Pobrano { $downloaded } z około { $total } MB
prepare-elapsed = Upłynęło: { $minutes } min { $seconds } s
prepare-progress-waiting = Oczekiwanie na usługę aktualizacji. Dla tego etapu nie jest dostępny postęp procentowy.
prepare-progress-unchanged = Brak postępu od { $minutes } min. Duże aktualizacje mogą trochę potrwać, więc pozostaw Atlas otwarty. Aby zobaczyć szczegóły, wybierz Otwórz folder dzienników.
prepare-report-delayed = Windows nie zgłasza postępu od { $seconds } s. Aktualizacje mogą nadal trwać, więc pozostaw Atlas otwarty.

prepare-affected-app = aplikację powodującą problem
prepare-app-in-use = Zamknij { $app }, a potem spróbuj ponownie. Windows nie może zaktualizować aplikacji, gdy jest otwarta. Jeśli nie możesz znaleźć jej okna, zamknij ją w Menedżerze zadań. Jeśli to nie pomoże, uruchom komputer ponownie i spróbuj jeszcze raz, zanim otworzysz { $app }.
prepare-install-busy = Inna instalacja lub wymagane ponowne uruchomienie blokuje aktualizacje. Poczekaj na zakończenie innych instalacji, uruchom komputer ponownie, jeśli Windows o to poprosi, a potem spróbuj ponownie.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas działa na innym koncie niż to, na którym zalogowano się do Windows. Zaloguj się do Windows na koncie administratora, otwórz Atlas na tym koncie i spróbuj ponownie.
prepare-failed-store-missing = Microsoft Store nie jest skonfigurowany dla Twojego konta. Otwórz Microsoft Store choć raz albo zainstaluj go ponownie, jeśli go brakuje, a potem spróbuj ponownie.
prepare-failed-store-battery = Microsoft Store wstrzymał aktualizacje, aby oszczędzać baterię. Podłącz komputer do zasilania i spróbuj ponownie.
prepare-failed-store-network = Microsoft Store wstrzymał aktualizacje do czasu, aż komputer będzie mieć połączenie nietaryfowe. Połącz się z nietaryfową siecią Wi-Fi lub Ethernet i spróbuj ponownie.
prepare-failed-store-timeout = Aplikacje ze sklepu nie zakończyły aktualizacji. Dokończ pozostałe pobierania w Microsoft Store i spróbuj ponownie.
prepare-failed-store-passes = W Microsoft Store wciąż pojawiały się nowe aktualizacje. Dokończ pozostałe aktualizacje w Microsoft Store i spróbuj ponownie.
prepare-failed-manual-updates = Niektóre aktualizacje Windows trzeba dokończyć w Windows Update. Otwórz Windows Update, dokończ je i spróbuj ponownie.
prepare-failed-windows-passes = W Windows Update wciąż pojawiały się nowe aktualizacje. Dokończ pozostałe aktualizacje w Windows Update i spróbuj ponownie.
prepare-error-code = Kod błędu: { $code }
prepare-open-store = Otwórz Microsoft Store

check-user-account = Konto użytkownika
detail-user-account-ok = Kontrola konta użytkownika jest włączona, a konto jest gotowe do instalacji.
detail-user-account-not-ready = Włącz kontrolę konta użytkownika (UAC), uruchom ponownie komputer i spróbuj jeszcze raz. Jeśli używasz wbudowanego konta Administrator, zaloguj się na inne konto administratora.
detail-user-account-unknown = Atlas nie mógł sprawdzić konta użytkownika. Sprawdź ponownie przed instalacją. Komunikat systemu Windows: { $error }

footer-prepare-required = Dokończ aktualizowanie Windows i aplikacji ze sklepu, aby kontynuować
footer-prepare-stopping = Zatrzymywanie aktualizacji po bieżącym etapie…
resume-choices-title = Wznawianie poprzedniej instalacji
resume-choices-detail = Aby dokończyć tę instalację, Atlas przywrócił opcje wybrane poprzednio. Nie możesz ich zmienić w kroku Opcje, dopóki instalacja się nie zakończy.

## Voluntary reports
report-title = Wyślij zgłoszenie
report-received = Otrzymano zgłoszenie
report-reference = Zachowaj ten numer, jeśli skontaktujesz się z zespołem Atlasa w sprawie tego zgłoszenia. Jeśli zgłoszenie zawiera dane kontaktowe, zespół może ich użyć do odpowiedzi, ale odpowiedź nie jest gwarantowana.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Kopiuj numer zgłoszenia
report-another = Wyślij kolejne zgłoszenie
# Label of the choice between the two kinds of report.
report-kind = Co chcesz wysłać?
report-kind-issue = Problem
report-kind-suggestion = Sugestia
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = Opisz, co się stało lub co chcesz zmienić ({ $min }–{ $max } znaków). Nie podawaj w wiadomości żadnych haseł.
report-message = Twoja wiadomość
report-message-placeholder = Próbowałem…
report-contact = Dane kontaktowe (opcjonalnie)
report-contact-placeholder = E-mail lub nazwa użytkownika Discord
report-attach = Dołącz diagnostykę
report-attach-description = Dzienniki i informacje o systemie, które pomagają znaleźć przyczynę. Atlas usuwa Twoją nazwę użytkownika, nazwę komputera, adresy e-mail oraz znane hasła lub klucze. Szczegóły błędów, modele sprzętu i nazwy aplikacji są zachowywane. Przed wysłaniem możesz przejrzeć plik ZIP.
report-prepare = Przygotuj diagnostykę
report-review = Sprawdź ZIP
report-prepare-failed-title = Nie udało się przygotować diagnostyki
# $error is a raw error message (text).
report-prepare-failed = Przygotuj diagnostykę ponownie lub wyłącz Dołącz diagnostykę, aby wysłać zgłoszenie bez niej. Szczegóły: { $error }
report-privacy = Twoje zgłoszenie trafia prywatnie do zespołu Atlasa pod adresem reports.atlasos.net. Wiadomość i dane kontaktowe są wysyłane w takiej postaci, w jakiej je wpiszesz. Zespół może korzystać z usług sztucznej inteligencji innych firm, aby pomóc w analizie zgłoszenia. Usługi te otrzymują Twoją wiadomość i diagnostykę, ale nie Twoje dane kontaktowe. Zgłoszenia są usuwane po 90 dniach, a dzienniki zabezpieczeń serwera mogą zapisywać Twój adres IP.
report-website = Prywatność i strona zgłoszeń
report-consent = Zgadzam się na wysłanie tego zgłoszenia i dołączonej diagnostyki do zespołu Atlasa
report-failed = Twoja wiadomość jest zachowana. Sprawdź połączenie z internetem, a potem wybierz Spróbuj ponownie albo wyślij zgłoszenie przez stronę zgłoszeń.
report-failed-busy = Usługa zgłoszeń jest zajęta. Twoja wiadomość jest zachowana. Spróbuj ponownie później.
report-failed-outdated = Ta wersja aplikacji Atlas Manager nie może już wysyłać zgłoszeń. Twoja wiadomość jest zachowana: skopiuj ją i wklej na stronie zgłoszeń. Jeśli dołączono diagnostykę, wybierz Sprawdź ZIP i tam również dołącz plik ZIP.
report-failed-diagnostics = Nie można wysłać przygotowanej diagnostyki. Twoja wiadomość jest zachowana. Przygotuj diagnostykę ponownie lub wyłącz Dołącz diagnostykę.
# Link under a report that wasn't sent.
report-failed-website = Otwórz stronę zgłoszeń
report-sending = Wysyłanie…
report-send = Wyślij zgłoszenie

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = Wpisz od { $min } do { $max } znaków.

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = Ogranicz dane kontaktowe do { $max } znaków.

report-validation-consent = Potwierdź zgodę na wysłanie tego zgłoszenia.

report-failed-title = Zgłoszenie nie zostało wysłane

## Windows version update
home-plan-intro = Ta aktualizacja składa się z dwóch części. Twoje pliki i aplikacje zostaną zachowane. Jeśli aktualizacja Windows cofnie którąś ze zmian Atlasa, Atlas ją przywróci.
home-plan-windows-title = Windows 11, wersja { $release }
home-plan-windows-detail = Atlas zainstaluje tę wersję z Windows Update. Aby dokończyć jej instalację, komputer uruchomi się ponownie.
home-plan-windows-optional = Zalecane. Atlas zainstaluje tę wersję z Windows Update. Aby dokończyć jej instalację, komputer uruchomi się ponownie.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas zaktualizuje swoje pliki i zachowa wybrane opcje. Na koniec komputer uruchomi się ponownie.
home-end-of-updates-title = Windows 11 w wersji { $current } przestanie otrzymywać aktualizacje zabezpieczeń { $date }
home-end-of-updates-past-title = Windows 11 w wersji { $current } nie otrzymuje już aktualizacji zabezpieczeń
home-end-of-updates-message = Wraz z aktualizacją do Atlasa { $version } ten komputer przejdzie też na Windows 11 w wersji { $release }, która będzie otrzymywać aktualizacje zabezpieczeń do { $until }.
install-windows-edition = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education. Na tym komputerze jest { $product }, więc nie można na nim zainstalować Atlasa.
install-windows-edition-ending = Atlas { $version } działa z Windows 11 Pro, Enterprise i Education. Na tym komputerze jest { $product }, więc nie można na nim zainstalować Atlasa. Windows 11 w wersji { $current } przestanie otrzymywać aktualizacje zabezpieczeń { $date }. Windows Update może zaktualizować ten komputer do nowszej wersji.
install-windows-no-path = Atlas { $version } wymaga Windows 11 w wersji { $releases }, a Windows Update nie może przenieść tego komputera na taką wersję z obecnie zainstalowanego Windows. Aby używać Atlasa { $version }, zrób kopię zapasową plików i zainstaluj ponownie Windows z obrazu ISO z Atlasem.
home-update-access-title = Ustawienia Windows Update są zmienione na potrzeby aktualizacji Atlasa
home-update-access-not-offered = Atlas włączył Windows Update, aby zaktualizować ten komputer do Windows 11 w wersji { $release }, ale Windows Update jeszcze jej nie udostępnia. Wybierz Sprawdź ponownie albo Przywróć ustawienia.
home-update-access-before = Atlas włączył Windows Update, aby zaktualizować ten komputer do Windows 11 w wersji { $release }, ale jeszcze nie skończył. Dokończ aktualizację albo wybierz Przywróć ustawienia.
home-update-access-after = Na tym komputerze jest już Windows 11 w wersji { $release }. Dokończ instalację Atlasa albo wybierz Przywróć ustawienia.
home-update-access-plain = Atlas włączył Windows Update, aby zainstalować aktualizacje, ale jeszcze nie skończył. Dokończ aktualizację albo wybierz Przywróć ustawienia.
home-update-access-unreadable = Atlas nie może odczytać zapisu zmienionych przez siebie ustawień Windows Update, więc niczego nie zmieni ani nie przywróci. Wybierz Wyślij zgłoszenie, aby zespół Atlasa mógł pomóc.
home-update-access-failed = Atlas nie mógł przywrócić ustawień. Spróbuj ponownie albo wybierz Wyślij zgłoszenie. Szczegóły: { $error }
home-update-access-install-active = Najpierw dokończ instalację Atlasa. Jej ostatni etap przywraca te ustawienia.
home-continue-update = Kontynuuj aktualizację
home-put-back = Przywróć ustawienia
home-putting-back = Przywracanie ustawień…
windows-card-title = Windows 11, wersja { $release }
windows-card-required = Atlas { $version } wymaga nowszej wersji Windows. Podczas aktualizowania Windows w sekcji poniżej Atlas zainstaluje też Windows 11 w wersji { $release } z Windows Update.
windows-card-question = Której wersji Windows ma używać ten komputer?
windows-choice-move = Zaktualizuj do Windows 11 w wersji { $release }
windows-choice-move-detail = Zalecane. Aktualizacje zabezpieczeń do { $date }. Jedno dodatkowe ponowne uruchomienie.
windows-choice-keep = Zachowaj Windows 11 w wersji { $current }
windows-choice-keep-detail = Komputer pozostanie przy tej wersji. Windows Update nie zaktualizuje go do nowszej wersji, więc późniejsze przejście na nią będzie wymagać kolejnej aktualizacji w aplikacji Atlas Manager.
windows-card-facts = Co się zmieni
windows-fact-keep = Twoje pliki i aplikacje zostaną zachowane. Jeśli aktualizacja cofnie którąś ze zmian Atlasa, Atlas przywróci ją podczas instalacji.
windows-fact-restart = Aby dokończyć aktualizację, komputer uruchomi się ponownie jeszcze co najmniej raz.
transition-offer-expectation = Windows Update zwykle udostępnia tę wersję w ciągu kilku minut, ale może to potrwać do 2 godzin; Atlas sam czeka i sprawdza za Ciebie.
windows-fact-stays = Potem Windows pozostanie w wersji { $release } i nie przejdzie samodzielnie na nowszą wersję.
windows-fact-removed = Wersja { $release } nie zawiera Windows PowerShell 2.0 ani narzędzia WMIC.
windows-card-undo = Aby później cofnąć tę aktualizację, odinstaluj ją w Windows Update > Historia aktualizacji. Jeśli Windows zainstalował się ponownie podczas aktualizacji, zamiast tego w ciągu 10 dni wybierz Wróć w Ustawieniach, na stronie System > Odzyskiwanie. Atlas { $version } nie obsługuje wersji { $current }, więc po zainstalowaniu Atlasa { $version } nie cofaj tej aktualizacji.
windows-card-undo-optional = Aby później cofnąć tę aktualizację, odinstaluj ją w Windows Update > Historia aktualizacji. Jeśli Windows zainstalował się ponownie podczas aktualizacji, zamiast tego w ciągu 10 dni wybierz Wróć w Ustawieniach, na stronie System > Odzyskiwanie.
windows-terms = Akceptuję postanowienia licencyjne dotyczące oprogramowania firmy Microsoft dla Windows 11 w wersji { $release }
windows-terms-link = Przeczytaj postanowienia licencyjne
windows-card-locked = Aby zachować wersję { $current }, wybierz Anuluj, a potem Zatrzymaj aktualizowanie.
prepare-description-transition = Przed instalacją Atlas zainstaluje aktualizacje, na które czeka Windows, potem Windows 11 w wersji { $release }, a na koniec zaktualizuje Microsoft Store i aplikacje ze sklepu. Otwarte aplikacje ze sklepu mogą zostać zamknięte podczas aktualizacji, więc najpierw zapisz w nich pracę. Komputer uruchomi się ponownie co najmniej raz.
prepare-start-transition = Zaktualizuj Windows do wersji { $release }
prepare-needs-terms = Dostępne, gdy zaakceptujesz postanowienia licencyjne w sekcji Windows 11, wersja { $release }.
ready-banner-not-offered-message = Sprawdź w sekcji Zaktualizuj Windows i aplikacje ze sklepu, co możesz teraz zrobić.
ready-banner-transition-failed-message = Sprawdź w sekcji Zaktualizuj Windows i aplikacje ze sklepu, co zrobić dalej.
ready-banner-terms-title = Zaakceptuj postanowienia licencyjne, aby kontynuować
ready-banner-terms-message = Znajdziesz je niżej na tej stronie, w sekcji Windows 11, wersja { $release }. Potem wybierz Zaktualizuj Windows do wersji { $release }.
access-notice-title = Atlas tymczasowo włącza Windows Update
access-off = Windows Update jest wyłączony na tym komputerze. Atlas włączy go ponownie na czas aktualizacji Windows.
access-paused = Aktualizacje Windows są wstrzymane na tym komputerze. Atlas wznowi je na czas aktualizacji Windows.
access-delayed = Comiesięczne aktualizacje są odroczone na tym komputerze. Atlas usunie odroczenie na czas aktualizacji Windows.
access-back-chosen = Po zainstalowaniu Atlasa { $version } te ustawienia wrócą do stanu zgodnego z Twoim wyborem.
access-back = Po zainstalowaniu Atlasa { $version } te ustawienia wrócą do poprzedniego stanu.
access-back-stop = Jeśli wcześniej zatrzymasz aktualizowanie, Atlas je przywróci.
prepare-reboot-transition = Windows 11 w wersji { $release } jest zainstalowany. Wybierz Uruchom ponownie i kontynuuj, aby dokończyć jego instalację. Atlas otworzy się ponownie po zalogowaniu.
prepare-reboot-commit = Windows potrzebuje jeszcze jednego ponownego uruchomienia, aby dokończyć instalowanie wersji { $release }. Atlas otworzy się ponownie po zalogowaniu.
prepare-restart-commit-failed = Windows nie mógł przygotować wersji { $release } do dokończenia instalacji przy ponownym uruchomieniu, więc komputer nie został uruchomiony ponownie. Wybierz Uruchom ponownie i kontynuuj, aby spróbować jeszcze raz.
prepare-reason-feature-update = nowa wersja Windows
prepare-reason-feature-commit = kończenie instalacji nowej wersji Windows
prepare-resumed-transition = Komputer został uruchomiony ponownie. Wybierz Kontynuuj aktualizacje, aby Atlas sprawdził, czy instalacja Windows 11 w wersji { $release } się zakończyła, i zainstalował pozostałe aktualizacje.
prepare-waiting-offer = Oczekiwanie na udostępnienie Windows 11 w wersji { $release } w Windows Update. Zwykle trwa to kilka minut, ale może potrwać do 2 godzin. W tym czasie możesz korzystać z komputera; nie zamykaj Atlasa.
prepare-resumed-before-move = Komputer został uruchomiony ponownie, aby dokończyć instalowanie aktualizacji. Wybierz Kontynuuj aktualizacje, aby Atlas zainstalował pozostałe aktualizacje, a potem Windows 11 w wersji { $release }.
prepare-not-offered-title = Oczekiwanie na udostępnienie Windows 11 w wersji { $release } w Windows Update
prepare-transition-failed-title = Nie udało się zaktualizować Windows do wersji { $release }
prepare-failed-feature-not-offered = Windows Update może udostępnić Windows 11 w wersji { $release } na danym komputerze dopiero po pewnym czasie. Komputer nadal ma wersję { $current }.
prepare-offer-rechecking = Atlas sprawdza ponownie co 10 minut i automatycznie kontynuuje, gdy tylko Windows Update udostępni tę wersję. Możesz też wybrać Sprawdź ponownie.
prepare-offer-waited =
    { $minutes ->
        [one] Atlas czeka już { $minutes } minutę.
        [few] Atlas czeka już { $minutes } minuty.
        [many] Atlas czeka już { $minutes } minut.
       *[other] Atlas czeka już { $minutes } minuty.
    }
prepare-offer-next-check =
    { $minutes ->
        [one] Następne sprawdzenie za { $minutes } minutę.
        [few] Następne sprawdzenie za { $minutes } minuty.
        [many] Następne sprawdzenie za { $minutes } minut.
       *[other] Następne sprawdzenie za { $minutes } minuty.
    }
prepare-offer-checking-now = Trwa sprawdzanie.
prepare-offer-check-again = Wybierz Sprawdź ponownie, aby sprawdzić teraz.
prepare-offer-wait-ended-title = Windows 11 w wersji { $release } nie jest jeszcze dostępny w Windows Update
prepare-offer-wait-ended = Windows 11 w wersji { $release } nie pojawił się w Windows Update w ciągu 2 godzin, więc Atlas przestał czekać i przywrócił ustawienia Windows Update. Wybierz później Sprawdź ponownie. Jeśli nie możesz czekać, zrób kopię zapasową plików i zainstaluj ponownie Windows z obrazu ISO z Atlasem.
prepare-offer-wait-put-back-failed = Windows Update nie udostępnił Windows 11 w wersji { $release } w ciągu 2 godzin, a Atlas nie mógł przywrócić Twoich ustawień Windows Update. Wybierz Przywróć ustawienia, aby spróbować ponownie. Szczegóły: { $error }
prepare-failed-feature-hardware = Ten komputer nie spełnia wymagań sprzętowych Windows 11 ({ $missing }), więc Windows Update nie zaktualizuje go do wersji { $release }. Komputer nadal ma wersję { $current }. Aby używać Atlasa { $version }, zrób kopię zapasową plików i zainstaluj ponownie Windows z obrazu ISO z Atlasem.
hardware-tpm = TPM 2.0
hardware-uefi = oprogramowanie układowe UEFI
prepare-failed-feature-hidden = Windows 11 w wersji { $release } jest ukryty w Windows Update na tym komputerze. Pokaż go ponownie za pomocą narzędzia, którym go ukryto, a potem wybierz Spróbuj ponownie.
prepare-failed-feature-disk-space = Do tej aktualizacji Windows potrzebuje co najmniej { $needed } GB wolnego miejsca na dysku { $drive }, a jest tam { $free } GB. Atlas niczego nie zmienił. Zwolnij miejsce, a potem wybierz Spróbuj ponownie.
prepare-failed-feature-servicing = Windows zgłasza uszkodzenie magazynu składników, którego nie może naprawić, więc Atlas niczego nie zmienił. Napraw Windows, a potem wybierz Spróbuj ponownie.
prepare-failed-feature-managed = Ten komputer pobiera aktualizacje z serwera aktualizacji organizacji, więc Atlas nie może zaktualizować go do wersji { $release }. Atlas niczego nie zmienił.
prepare-failed-feature-policy = Coś na tym komputerze ciągle przywraca poprzedni stan elementu { $setting }, gdy Atlas go zmieni, więc Atlas nie może zaktualizować Windows. Jeśli tym komputerem zarządza organizacja, zwróć się do niej o pomoc. Gdy zatrzymasz aktualizowanie, Atlas przywróci to, co zmienił.
prepare-failed-feature-blocked = Ustawienie, którego Atlas nie zmieniał, nie pozwala na działanie Windows Update: { $setting }. Zmień je tak, aby Windows Update mógł działać, a potem wybierz Spróbuj ponownie.
prepare-failed-feature-rolled-back = Windows nie mógł dokończyć instalowania wersji { $release } podczas ponownego uruchomienia i wrócił do wersji { $current }. Nie ma to wpływu na Twoje pliki i aplikacje. Wybierz Spróbuj ponownie albo Wyślij zgłoszenie.
prepare-failed-feature-components-lost = Po aktualizacji Windows brakuje części zmian Atlasa, a nic nie wskazuje na to, że Windows zainstalował się ponownie, więc Atlas nie może ustalić, co się stało. Atlas { $version } nie został zainstalowany. Wybierz Wyślij zgłoszenie, aby zespół Atlasa mógł pomóc.
prepare-failed-feature-build = Wersja Windows na tym komputerze zmieniła się podczas aktualizacji przeprowadzanej przez Atlas. Wybierz Przywróć ustawienia, a potem zacznij od nowa na stronie głównej.
prepare-failed-feature-journal = Atlas nie może odczytać zapisu zmienionych przez siebie ustawień Windows Update, więc niczego nie zmieni ani nie przywróci. Wybierz Wyślij zgłoszenie, aby zespół Atlasa mógł pomóc.
prepare-failed-feature-pin = Zasada Windows Update { $setting } ma na tym komputerze wartość, której Atlas nie może zapisać, więc Atlas niczego nie zmienił. Wybierz Wyślij zgłoszenie, aby zespół Atlasa mógł pomóc.
prepare-failed-feature-terms = Zaakceptuj postanowienia licencyjne dla Windows 11 w wersji { $release }, a potem wybierz Spróbuj ponownie.
prepare-failed-feature-failed = Windows nie mógł zainstalować wersji { $release }. Komputer nadal ma wersję { $current }. Wybierz Spróbuj ponownie. Jeśli znów się nie uda, wybierz Wyślij zgłoszenie.
prepare-check-again = Sprawdź ponownie
prepare-keep-version = Zachowaj wersję { $current }
stop-update-title = Zatrzymać aktualizację do Atlasa { $version }?
stop-update-before = Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizacje już zainstalowane przez Windows pozostaną zainstalowane, a komputer zachowa Windows 11 w wersji { $current }.
stop-update-after = Komputer zachowa Windows 11 w wersji { $release }. Atlas przywróci zmienione przez siebie ustawienia Windows Update.
stop-update-access = Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizacje już zainstalowane przez Windows pozostaną zainstalowane.
stop-update-keep = Kontynuuj aktualizowanie
window-close-update-access-title = Zamknąć Atlas?
window-close-update-access-message = Przed zamknięciem Atlas przywróci zmienione przez siebie ustawienia Windows Update. Aktualizację możesz rozpocząć ponownie na stronie głównej.
window-close-put-back = Przywróć i zamknij
window-close-put-back-failed-title = Zamknąć bez przywracania ustawień?
window-close-put-back-failed-message = Jeśli teraz zamkniesz Atlas, ustawienia Windows Update pozostaną w stanie zmienionym przez Atlas. Gdy ponownie otworzysz Atlas, strona główna zaproponuje ich przywrócenie.
installed-update-off-again = Windows Update jest znowu wyłączony, zgodnie z Twoim wyborem. Dopóki jest wyłączony, komputer nie otrzymuje aktualizacji zabezpieczeń.
installed-update-paused-again = Aktualizacje Windows są znowu wstrzymane, zgodnie z Twoim wyborem. Dopóki są wstrzymane, komputer nie otrzymuje aktualizacji zabezpieczeń.
detail-build-transition = Ten komputer ma Windows 11 w wersji { $current }, której ta wersja Atlasa nie obsługuje. Podczas aktualizowania Windows w sekcji poniżej Atlas zaktualizuje go do wersji { $release }.
report-transition-intro = Aktualizacja Windows na potrzeby Atlasa nie została ukończona. Szczegóły dla zespołu Atlasa:
mode-rebase = Ponowna instalacja po aktualizacji Windows
history-mode-rebase = ponowna instalacja po aktualizacji Windows
ready-rebase-title = Windows zainstalował się ponownie podczas aktualizacji
ready-rebase-message = Windows 11 w wersji { $release } zastąpił Windows, który był na tym komputerze, więc części zmian Atlasa już nie ma. Atlas { $version } przywróci je zgodnie z opcjami wybranymi dla Atlasa { $previous }.
upgrade-choices-title = Opcje z Atlasa { $previous }
upgrade-choices-detail = Atlas przyjął za punkt wyjścia to, co Atlas { $previous } skonfigurował na tym komputerze. Aktualizacja zachowuje skutki tych opcji, więc odznaczenie tutaj dodatku nie cofnie jego działania. Aby później zmienić którąś z opcji, skorzystaj z folderu Atlas lub Ustawień Windows.
rebase-choices-title = Opcje z Atlasa { $previous }
rebase-choices-detail = Atlas używa opcji wybranych dla Atlasa { $previous }, więc nie ma tu nic do wyboru. Możesz je później zmienić w folderze Atlas.
rebase-choices-partial = Atlas używa opcji wybranych dla Atlasa { $previous }. Nie udało się odnaleźć tych opcji, więc je sprawdź: { $missing }
restart-other-title = Ktoś inny jest zalogowany na tym komputerze
restart-others-title = Inne osoby są zalogowane na tym komputerze
restart-others-message = Ponowne uruchomienie zamknie aplikacje otwarte na innych kontach, a niezapisana praca na tych kontach zostanie utracona. Zalogowane konta: { $names }.
restart-others-keep = Nie uruchamiaj ponownie
restart-others-restart = Uruchom ponownie mimo to
prepare-store-self-update = Najpierw aktualizowanie Microsoft Store, ponieważ jego wersja na tym komputerze jest nieaktualna.
prepare-store-repair = Naprawianie Microsoft Store. Może to potrwać kilka minut.
prepare-store-updated = Microsoft Store był nieaktualny, więc Atlas zaktualizował go przed aplikacjami.
prepare-store-bootstrapped = Microsoft Store nie mógł zaktualizować się samodzielnie, więc Atlas zainstalował od firmy Microsoft najnowsze wersje Instalatora aplikacji i Microsoft Store.
prepare-store-repaired = Microsoft Store nie działał, więc Atlas go naprawił.
prepare-store-skipped-removed = Microsoft Store jest wyłączony na tym komputerze, więc Atlas pominął aktualizacje aplikacji ze sklepu.
prepare-failed-store-repair-failed = Microsoft Store nie działa, a Atlas nie mógł go naprawić. Wybierz Napraw Microsoft Store, aby spróbować ponownie. Jeśli nadal nie działa, wybierz Wyślij zgłoszenie.
prepare-repair-store = Napraw Microsoft Store

screen-keyboard-title = Języki klawiatury
screen-keyboard-question = Czy używasz wielu języków klawiatury?
playbook-option-keyboard-shortcuts = Tak, przełączam skrótami klawiszowymi
playbook-option-keyboard-selector = Tak, używam selektora na pasku zadań
playbook-option-keyboard-single = Nie, używam jednego układu
consequence-keyboard-shortcuts = Alt+Shift zmienia język, a Ctrl+Shift zmienia układ.
consequence-keyboard-selector = Wyłącz Alt+Shift i Ctrl+Shift, aby uniknąć przypadkowego przełączania podczas gry.
playbook-page-keyboard-shortcuts-description = Wybierz sposób przełączania języka klawiatury.
consequence-keyboard-single = { consequence-keyboard-selector }
