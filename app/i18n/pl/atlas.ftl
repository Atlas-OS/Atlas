### Atlas Manager: Polish (pl). Preview translation, revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog: the reader is addressed directly in the
### second person singular (Twój, Ci), as Microsoft Polish does; "Atlas" is
### declined like an ordinary masculine noun (Atlasa, Atlasie, Atlasem);
### "Windows" and "Microsoft Defender" are never declined, while "Zabezpieczenia
### Windows" declines like an ordinary noun phrase (w Zabezpieczeniach Windows); "otwórz Atlas ponownie" means relaunching
### this app, "uruchom ponownie" always means restarting the PC or Windows.

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
# Accessible description of a disabled control.
common-not-available = Obecnie niedostępne
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

## Okno

# Dialog shown when the window is closed while an install runs.
window-close-title = Zamknąć okno podczas instalacji?
window-close-message = Instalacja będzie kontynuowana w tle. Otwórz Atlas ponownie, aby zobaczyć postęp i wynik. Nie wyłączaj komputera, dopóki instalacja się nie zakończy.
window-close-keep = Pozostaw otwarte
window-close-close = Zamknij okno
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Otwórz plik playbook Atlasa (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas jest zainstalowany. Windows uruchomi się ponownie, aby dokończyć konfigurację.

## System

# "Windows 11 Pro 25H2 (kompilacja 26200.1234)". All three values are text.
system-description = { $product } { $version } (kompilacja { $build })

## Strona główna

home-not-installed = Witaj w Atlasie
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Zainstalowano { $date }
home-status-checking = Sprawdzanie aktualizacji
home-status-offline = Nie udało się sprawdzić aktualizacji
home-status-not-checked = Nie sprawdzono jeszcze aktualizacji
home-status-update = Dostępny jest Atlas { $version }
home-status-up-to-date = Masz najnowszą wersję
home-status-newest = Najnowsza wersja: Atlas { $version }
home-check-again = Sprawdź ponownie
# Primary button while an install is running or waiting.
home-show-install = Pokaż postęp
home-continue-installing = Kontynuuj konfigurację
home-update-to = Zaktualizuj do wersji { $version }
home-reinstall = Zainstaluj Atlas ponownie
home-install = Zainstaluj Atlas
home-start-over = Zacznij od nowa
home-security-reminder-title = Włącz ochronę ponownie
home-security-reminder-message = Nie trwa teraz żadna instalacja. Otwórz Zabezpieczenia Windows i włącz ochronę przed naruszeniami, ochronę w czasie rzeczywistym, ochronę dostarczaną z chmury i automatyczne przesyłanie próbek.
home-elevation-title = Do instalacji potrzebne są uprawnienia administratora
home-state-error-title = Nie udało się odczytać informacji o instalacji Atlasa
home-whats-new = Co nowego w Atlasie { $version }
home-view-release = Zobacz informacje o wydaniu w serwisie GitHub
home-released = Wydano { $date }
home-show-less = Pokaż mniej
home-show-full-notes = Pokaż pełne informacje o wydaniu
home-your-install = Twoja instalacja Atlasa
# Row label: how Atlas was set up.
home-set-up = Sposób instalacji
home-set-up-during-oobe = Podczas konfiguracji Windows
home-history = Historia instalacji
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Przygotujmy komputer do instalacji Atlasa
home-step-1-title = Sprawdź komputer
home-step-1-detail = Atlas sprawdza Windows i pobiera pliki instalacyjne. Ustawienia Windows pozostają bez zmian.
home-step-2-title = Wybierz ustawienia
home-step-2-detail = Zdecyduj, jak Windows ma dbać o ochronę i aktualizacje, a potem wybierz dodatkowe aplikacje i ustawienia.
home-step-3-title = Wstrzymaj ochronę antywirusową
home-step-3-detail = Atlas pokaże Ci cztery przełączniki w Zabezpieczeniach Windows, które trzeba wyłączyć na czas instalacji.
home-step-4-title = Zainstaluj i uruchom komputer ponownie
home-step-4-detail =
    { $minutes ->
        [one] Około minuty.
        [few] Około { $minutes } minut.
        [many] Około { $minutes } minut.
       *[other] Około { $minutes } minuty.
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
notice-session-unreadable-title = Nie udało się sprawdzić poprzedniej instalacji
# $path is a file path (text).
notice-session-unreadable-message = Atlas nie może odczytać pliku { $path }, a musi wiedzieć, czy jakaś instalacja nadal trwa. Jeśli nie masz pewności, poproś o pomoc społeczność Atlasa, zanim usuniesz ten plik. Usuń go i spróbuj ponownie tylko wtedy, gdy masz pewność, że żadna instalacja nie trwa. Szczegóły: { $error }

## Uprawnienia administratora

elevation-declined = Nie udzielono uprawnień. Spróbuj ponownie i wybierz Tak, gdy Windows zapyta, czy zezwolić aplikacji Atlas na wprowadzanie zmian.
elevation-declined-continue = Nie udzielono uprawnień. Spróbuj ponownie i wybierz Tak, gdy Windows zapyta, czy zezwolić aplikacji Atlas na wprowadzanie zmian. Wybrane opcje instalacji zostały zapisane.
elevation-draft-not-saved = Atlas nie mógł zapisać wybranych opcji instalacji, więc nie otworzył się ponownie. Spróbuj ponownie. Szczegóły: { $error }

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
stepper-status-completed = ukończony
stepper-status-current = bieżący krok
stepper-status-upcoming = kolejny krok
# Heading above each step's content.
step-heading = Krok { $number } z { $total }: { $title }

## Krok 1: Przygotowanie

ready-banner-busy-title = Przygotowywanie komputera
ready-banner-busy-message = Atlas sprawdza Twój komputer i przygotowuje pliki instalacyjne.
ready-banner-blocked-title = Komputer trzeba jeszcze przygotować
ready-banner-blocked-message = Wykonaj poniższe instrukcje, a potem wybierz Sprawdź ponownie.
ready-banner-no-package-title = Pobierz Atlas, aby kontynuować
ready-banner-no-package-message = Pobierz poniżej najnowszą wersję albo otwórz zapisany plik playbook Atlasa (.apbx).
ready-banner-warnings-title = Kilka rzeczy do sprawdzenia
ready-banner-warnings-message = Przeczytaj poniższe uwagi i wykonaj zalecane kroki, zanim przejdziesz dalej.
ready-banner-ok-title = Możesz już wybrać ustawienia
ready-banner-ok-message = Sprawdzanie zakończyło się pomyślnie, a pliki instalacyjne są gotowe.

# Card title and accessible name of the list of checks.
ready-this-pc = Sprawdzanie komputera
ready-check-again = Sprawdź ponownie

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
package-none = Nie ma jeszcze plików instalacyjnych. Plik playbook (.apbx) zawiera instrukcje i pliki, których Atlas potrzebuje.
# Short status words beside the card title.
package-status-downloading = Pobieranie
package-status-unpacking = Rozpakowywanie
package-status-failed = Nie udało się przygotować
package-status-ready = Gotowe
package-status-checking = Sprawdzanie
package-status-missing = Nie pobrano
# Accessible name of the progress bar.
package-progress = Postęp przygotowania plików instalacyjnych
package-download-again = Pobierz ponownie
package-download-version = Pobierz Atlas { $version }
package-download-newest = Pobierz najnowszą wersję
package-open-file = Otwórz plik playbook
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } został pobrany z serwisu GitHub i jest gotowy do instalacji.
package-from-file = Atlas { $version } został wczytany z pliku { $file } i jest gotowy do instalacji.
package-unpacked = Atlas { $version } jest gotowy do instalacji.
package-at = Pliki instalacyjne: { $path }
package-none-yet = Nie wybrano plików instalacyjnych
acquire-no-asset = Atlas { $version } nie ma pliku playbook do pobrania. Aby kontynuować, otwórz zapisany plik playbook Atlasa (.apbx).
acquire-unsupported = Ta aplikacja instaluje Atlas w wersji 0.6.0 i nowszych. Aby zainstalować Atlas { $version }, użyj AME Wizard.
acquire-failed = Nie udało się przygotować plików instalacyjnych. Spróbuj pobrać je ponownie lub otwórz inny plik playbook Atlasa (.apbx). Szczegóły: { $error }

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
# Check boxes the user ticks when a check could not run. "Potwierdzam, że" keeps
# the first person without a gendered past-tense verb.
check-ack-updates = Potwierdzam, że w Windows Update żadne aktualizacje nie czekają na instalację
check-ack-reboot = Potwierdzam, że komputer został ponownie uruchomiony i nie wymaga kolejnego ponownego uruchomienia
check-ack-internet = Ten komputer jest połączony z internetem
check-ack-generic = Potwierdzam, że to wymaganie zostało przeze mnie sprawdzone

detail-admin-ok = Atlas ma uprawnienia do wprowadzenia zmian potrzebnych do instalacji.
detail-admin-missing = Otwórz Atlas ponownie jako administrator i wybierz Tak, gdy Windows poprosi o zezwolenie.
# $builds is a list of build numbers such as "26100 lub 26200"; $build is this PC's (text).
detail-build-unsupported = Ta wersja Atlasa wymaga kompilacji Windows { $builds }. Ten komputer ma kompilację { $build }. Zainstaluj obsługiwaną wersję Windows, zanim przejdziesz dalej.
detail-updates-none = Żadne aktualizacje Windows nie czekają na instalację.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Najpierw zainstaluj tę aktualizację: { $titles }.
        [2] Najpierw zainstaluj te aktualizacje: { $titles }.
        [few] Najpierw zainstaluj { $count } aktualizacje, w tym { $titles }.
        [many] Najpierw zainstaluj { $count } aktualizacji, w tym { $titles }.
       *[other] Najpierw zainstaluj { $count } aktualizacji, w tym { $titles }.
    }
detail-updates-unknown = Nie udało się sprawdzić aktualizacji Windows. Otwórz Windows Update, a jeśli żadne aktualizacje nie czekają na instalację, potwierdź to poniżej. ({ $error })
detail-reboot-none = Windows nie wymaga teraz ponownego uruchomienia.
detail-reboot-pending = Uruchom komputer ponownie, aby dokończyć wcześniejsze zmiany, a potem otwórz Atlas i sprawdź ponownie.
detail-reboot-unknown = Nie udało się sprawdzić, czy Windows wymaga ponownego uruchomienia. Uruchom komputer ponownie, a potem otwórz Atlas i sprawdź ponownie. ({ $error })
detail-antivirus-none = Nie wykryto innego oprogramowania antywirusowego.
# $products is a list of product names (text).
detail-antivirus-found = Oprogramowanie antywirusowe może blokować instalację: { $products }. Odinstaluj je, zanim przejdziesz dalej.
detail-antivirus-unknown = Nie udało się sprawdzić, czy jest zainstalowane inne oprogramowanie antywirusowe. Przejrzyj zainstalowane aplikacje, zanim przejdziesz dalej. ({ $error })
detail-internet-ok = Masz połączenie z internetem. Nie przerywaj go, gdy Atlas będzie pobierać i instalować oprogramowanie.
detail-internet-missing = Połącz się z internetem, a potem sprawdź ponownie.
detail-power-mains = Komputer jest podłączony do zasilania. Nie odłączaj go do końca instalacji.
detail-power-battery = Podłącz komputer do zasilania, aby nie wyłączył się w trakcie instalacji.
detail-power-unknown = Nie udało się sprawdzić zasilania. Jeśli używasz laptopa, podłącz go do zasilania, zanim przejdziesz dalej.
detail-activation-ok = Windows jest aktywowany. Atlas tego nie zmieni.
detail-activation-missing = Windows nie jest aktywowany. Możesz kontynuować, ale Atlas nie aktywuje Windows za Ciebie.
detail-activation-no-licence = Windows nie zgłosił licencji. Możesz kontynuować, Atlas nie zmieni stanu aktywacji.
detail-activation-unknown = Nie udało się sprawdzić aktywacji Windows. Możesz kontynuować, Atlas nie zmieni stanu aktywacji. ({ $error })

## Krok 2: Opcje

options-progress = Wybór { $number } z { $total }
options-progress-extras = Wybór { $number } z { $total }: opcjonalne dodatki
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Zachować ochronę antywirusową?
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
screen-extras-question = Wybierz dodatki, które Cię interesują
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wybierz opcję dla: { $title }
learn-more-defender = Dowiedz się więcej o Microsoft Defender
learn-more-mitigations = Przeczytaj o zabezpieczeniach procesora
learn-more-updates = Dowiedz się więcej o Windows Update
learn-more-browser = Dowiedz się więcej o przeglądarkach
learn-more-power = Dowiedz się więcej o zasilaniu i zabezpieczeniach
learn-more-apps = Dowiedz się więcej o aplikacjach
learn-more-eclean = Jak eclean współpracuje z AtlasOS
learn-more-generic = Przeczytaj przewodnik konfiguracji
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Zachowuje wbudowany program antywirusowy Windows, który pomaga chronić komputer przed wirusami i innymi zagrożeniami.
consequence-defender-disable = Usuwa Microsoft Defender. Komputer pozostanie bez ochrony antywirusowej, dopóki nie zainstalujesz innego programu antywirusowego.
consequence-mitigations-default = Zachowuje domyślne zabezpieczenia Windows przed atakami wykorzystującymi sposób działania procesora.
consequence-mitigations-disable = Wyłącza te zabezpieczenia i zmniejsza bezpieczeństwo. Wydajność zależy od procesora i może się pogorszyć.
consequence-auto-updates-disable = Aktualizacje trzeba będzie instalować samodzielnie w Windows Update. Powiadomienia o aktualizacjach pozostaną włączone.
consequence-auto-updates-default = Windows będzie automatycznie instalować aktualizacje, w tym poprawki zabezpieczeń.

## Tekst pliku playbook
## Pakiet playbook zawiera własny angielski tekst każdej opcji. Te tłumaczenia
## są używane tylko wtedy, gdy tekst pakietu jest dokładnie taki jak w
## i18n/playbook-source.ftl, więc przyszły pakiet, który zmieni brzmienie opcji,
## pokaże własne słowa zamiast nieaktualnego tłumaczenia.

playbook-option-defender-enable = Zachowaj Microsoft Defender (zalecane)
playbook-option-defender-disable = Usuń Microsoft Defender
playbook-option-mitigations-default = Zachowaj domyślne zabezpieczenia (zalecane)
playbook-option-mitigations-disable = Wyłącz zabezpieczenia procesora
playbook-option-auto-updates-disable = Chcę instalować aktualizacje samodzielnie
playbook-option-auto-updates-default = Instaluj aktualizacje automatycznie
playbook-option-disable-hibernation = Wyłącz hibernację
playbook-option-disable-power-saving = Wyłącz oszczędzanie energii
playbook-option-disable-core-isolation = Wyłącz zabezpieczenia oparte na wirtualizacji (VBS)
playbook-option-remove-snipping-tool = Usuń Narzędzie Wycinanie
playbook-option-uninstall-edge = Usuń Microsoft Edge
playbook-option-install-another-browser = Zainstaluj przeglądarkę
playbook-option-install-toolbox = Zainstaluj Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender to wbudowany program antywirusowy Windows. Zalecamy jego zachowanie. Usuń go tylko wtedy, gdy rozumiesz ryzyko i planujesz używać innego programu antywirusowego.
playbook-page-mitigations-default-description = Te zabezpieczenia, nazywane też środkami zaradczymi, pomagają chronić przed lukami w zabezpieczeniach procesora. Zalecamy zachowanie ustawień domyślnych Windows.
playbook-page-auto-updates-disable-description = Aktualizacje Windows zawierają poprawki zabezpieczeń. Windows może instalować je automatycznie albo możesz instalować je samodzielnie.
consequence-install-toolbox = Atlas Toolbox pomaga zarządzać ustawieniami Atlasa. Jest w wersji beta, więc niektóre funkcje mogą być jeszcze niedokończone.
playbook-page-browser-brave-description = Wybierz przeglądarkę do zainstalowania. Atlas nie zmieni ustawień przeglądarki.

## Krok 3: Zabezpieczenia Windows

security-banner-reading-title = Sprawdzanie Zabezpieczeń Windows
security-banner-reading-message = Atlas sprawdza cztery poniższe przełączniki ochrony.
security-banner-off-title = Cztery przełączniki ochrony są wyłączone
security-banner-off-message = Możesz teraz przejrzeć wybrane ustawienia przed instalacją.
security-banner-readable-off-title = Przełączniki, które Atlas mógł sprawdzić, są wyłączone
security-banner-readable-off-message = Sprawdź pozostałe przełączniki w Zabezpieczeniach Windows.
security-banner-on-title = Tymczasowo wyłącz ochronę antywirusową
security-banner-on-message = Te zabezpieczenia mogą blokować zmiany, które Atlas musi wprowadzić.
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
security-unknown-message = Gdy sprawdzisz w Zabezpieczeniach Windows, że wszystkie cztery przełączniki są wyłączone, potwierdź to poniżej.
security-acknowledge = Potwierdzam, że w Zabezpieczeniach Windows wszystkie cztery przełączniki są wyłączone
security-unknown-unelevated-title = Atlas potrzebuje uprawnień, aby sprawdzić ochronę
security-unknown-unelevated-message = Otwórz Atlas ponownie jako administrator, aby mógł sprawdzić ustawienia Microsoft Defender.
# The four switches, named as Windows Security names them.
protection-tamper = Ochrona przed naruszeniami
protection-tamper-why = Wyłącz ją jako pierwszą, aby Defender pozwolił zmienić ustawienia ochrony.
protection-realtime = Ochrona w czasie rzeczywistym
protection-realtime-why = Wstrzymaj skanowanie plików, aby Defender nie blokował plików instalacyjnych Atlasa.
protection-cloud = Ochrona dostarczana z chmury
protection-cloud-why = Wstrzymaj sprawdzanie zagrożeń online, które może blokować pliki instalacyjne Atlasa.
protection-samples = Automatyczne przesyłanie próbek
protection-samples-why = Wyłącz automatyczne wysyłanie plików Atlasa do firmy Microsoft w celu analizy.

## Krok 4: Instalacja

install-preparing-title = Ostatnie sprawdzenie przed instalacją
install-preparing-message = Atlas ponownie sprawdza komputer i ustawienia ochrony, zanim wprowadzi zmiany.
install-installing = Instalowanie
install-running = W toku
# Accessible name of the progress bar.
install-progress = Postęp instalacji
phase-preflight = Sprawdzanie komputera i przygotowywanie plików
phase-staging = Przygotowywanie plików instalacyjnych
phase-applying = Konfigurowanie Windows. Nie wyłączaj komputera.
phase-done = Kończenie konfiguracji
outcome-succeeded-title = Atlas jest zainstalowany
outcome-lost-title = Nie udało się potwierdzić wyniku instalacji
outcome-failed-title = Instalacja nie została ukończona
outcome-succeeded = Uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
outcome-requirements = Komputer nie spełnia wymagań instalacji. Nie wprowadzono żadnych zmian. Wróć do kroku Przygotowanie i wybierz Sprawdź ponownie.
outcome-not-elevated = Nie wprowadzono żadnych zmian. Otwórz Atlas ponownie jako administrator i spróbuj jeszcze raz.
outcome-failed-preflight = Instalacja zatrzymała się, zanim cokolwiek zmieniono. Otwórz plik dziennika, aby zobaczyć, co się stało, a potem spróbuj ponownie.
outcome-failed-staging = Instalacja zatrzymała się podczas przygotowywania plików, zanim cokolwiek zmieniono w Windows. Otwórz plik dziennika, aby zobaczyć, co się stało, a potem spróbuj ponownie.
outcome-failed-applying = Część zmian mogła już zostać wprowadzona. Jeśli na tym poprzestaniesz, włącz ponownie w Zabezpieczeniach Windows wyłączone wcześniej funkcje ochrony, o ile są nadal dostępne.
outcome-not-started = Instalator nie uruchomił się na czas. Nie wprowadzono żadnych zmian. Wybierz Spróbuj ponownie.
outcome-lost = Instalator zakończył działanie bez zgłoszenia wyniku, a część zmian mogła już zostać wprowadzona. Otwórz plik dziennika, aby zobaczyć, co się stało, a potem wybierz Spróbuj ponownie, aby wznowić instalację.
restart-now-message = Windows uruchamia się ponownie, aby dokończyć konfigurację Atlasa.
restart-countdown =
    { $seconds ->
        [one] Windows uruchomi się ponownie za { $seconds } sekundę, aby Atlas mógł dokończyć konfigurację.
        [few] Windows uruchomi się ponownie za { $seconds } sekundy, aby Atlas mógł dokończyć konfigurację.
        [many] Windows uruchomi się ponownie za { $seconds } sekund, aby Atlas mógł dokończyć konfigurację.
       *[other] Windows uruchomi się ponownie za { $seconds } sekundy, aby Atlas mógł dokończyć konfigurację.
    }
restart-stopped = Anulowano automatyczne ponowne uruchomienie. Zapisz pracę, a potem uruchom komputer ponownie, aby dokończyć konfigurację Atlasa.
restart-needed = Zapisz pracę, a potem uruchom Windows ponownie, aby dokończyć konfigurację Atlasa.
restart-dont-now = Uruchom ponownie później
restart-now = Uruchom ponownie teraz
# Accessible name of the countdown bar.
restart-progress = Czas do ponownego uruchomienia
restart-start-failed = Nie udało się uruchomić Windows ponownie. Zapisz pracę, a potem uruchom komputer ponownie z menu Start. Szczegóły: { $error }
preflight-title = Instalacja się nie rozpoczęła
preflight-invalid-options = Atlas nie mógł użyć wybranych opcji. Wróć do kroku Opcje, przejrzyj je i spróbuj ponownie. Szczegóły: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Stan komputera zmienił się od wcześniejszego sprawdzenia. Rozwiąż następujące problemy, zanim spróbujesz ponownie. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 nadal włączone".
preflight-security = Zabezpieczenia Windows: { $summary }.
preflight-busy = Inne okno Atlasa rozpoczyna instalację. Poczekaj chwilę i spróbuj ponownie.
preflight-record-unreadable = Atlas nie mógł sprawdzić, czy poprzednia instalacja nadal trwa, więc nie rozpoczął kolejnej. Zamknij Atlas i otwórz go ponownie, aby zobaczyć instrukcje odzyskiwania. Szczegóły: { $error }
preflight-refused = Nie udało się uruchomić instalatora. Nie wprowadzono żadnych zmian. Szczegóły: { $error }
go-to-ready = Wróć do kroku Przygotowanie
go-to-options = Wróć do kroku Opcje
output-problem-title = Nie udało się odczytać postępu instalacji
output-problem-message = Atlas nie mógł odczytać dziennika. Nie oznacza to, że instalacja się zatrzymała. Nie wyłączaj komputera i spróbuj otworzyć plik dziennika. Szczegóły: { $error }
install-elevate-title = Do instalacji potrzebne są uprawnienia administratora
install-no-package-title = Najpierw wybierz pliki instalacyjne
install-no-package-message = Wróć do kroku Przygotowanie, aby pobrać Atlas lub otworzyć zapisany plik playbook (.apbx).
install-security-title = Sprawdź ochronę antywirusową przed instalacją
install-security-reading = Ponowne sprawdzanie czterech przełączników ochrony.
install-security-message = { $summary }. Otwórz Zabezpieczenia Windows i upewnij się, że wszystkie cztery przełączniki są wyłączone, zanim przejdziesz dalej.
summary-this-install = Podsumowanie instalacji
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
summary-command-unavailable = Nie udało się przygotować polecenia instalacji. Szczegóły: { $error }
summary-not-chosen = Jeszcze nie wybrano
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Zmień: { $title }
footer-still-checking = Przygotowywanie do instalacji
footer-fix-items = Napraw lub potwierdź powyższe elementy, aby kontynuować
footer-need-package = Pobierz Atlas lub otwórz plik playbook, aby kontynuować
footer-reading-security = Sprawdzanie przełączników ochrony
button-checking = Sprawdzanie
button-installing = Instalowanie
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
installing-phase-applying = Konfigurowanie Windows zgodnie z Twoimi wyborami. Nie wyłączaj komputera i nie odłączaj zasilania.
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

## Okno „Atlas jest zainstalowany” po ponownym uruchomieniu

installed-title-version = Atlas { $version } jest zainstalowany
installed-title = Atlas jest zainstalowany
installed-ready = To wszystko. Komputer jest gotowy do pracy z Atlasem.
installed-open-atlas = Zobacz swoją instalację Atlasa

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
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Po wybraniu „Jak w Windows”: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Tłumaczenie wstępne · czeka na weryfikację językową
preview-notice = To tłumaczenie ({ $language }) jest wersją wstępną.
preview-notice-switch = Przełącz na angielski
preview-notice-language = Zmień język
# $tag is a language tag (text).
settings-language-unavailable = Język { $tag } nie jest dostępny w tej wersji Atlasa. Na razie wyświetlany jest angielski, a Twój wybór pozostaje zapisany.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas nie obsługuje jeszcze Twoich języków wyświetlania Windows ({ $languages }). Na razie wyświetlany jest angielski.
settings-language-windows-unavailable = Nie udało się sprawdzić języka wyświetlania Windows. Na razie Atlas używa angielskiego. Szczegóły: { $error }
# $locale is the regional format's own name, for example "polski (Polska)".
settings-language-formats = Liczby, daty i godziny są zgodne z formatem regionalnym Windows ({ $locale }).
settings-language-contribute = Pomóż tłumaczyć Atlas w serwisie GitHub
settings-installing = Instalacja
settings-restart-label = Automatycznie uruchom komputer ponownie po instalacji
settings-restart-locked = Możesz to zmienić po zakończeniu instalacji.
settings-restart-description = Do dokończenia konfiguracji potrzebne jest ponowne uruchomienie komputera. Jeśli automatyczne ponowne uruchomienie jest włączone, zapisz pracę przed instalacją.
settings-about = Informacje
settings-about-app = Atlas Manager
settings-about-data = Pliki aplikacji
settings-about-licence = Licencja
settings-about-licence-value = GPL-3.0, wolne i otwarte oprogramowanie
settings-view-source = Zobacz kod źródłowy w serwisie GitHub
settings-open-data-folder = Otwórz folder aplikacji

## Opcjonalne dodatki: objaśnienia widoczne przed wyborem.

consequence-disable-hibernation = Zwalnia miejsce na dysku, w którym zapisywana jest sesja podczas hibernacji. Hibernacja i szybkie uruchamianie będą niedostępne.
consequence-disable-power-saving = Wyłącza funkcje oszczędzania energii. Komputer może zużywać więcej prądu, mocniej się nagrzewać i krócej działać na baterii.
consequence-disable-core-isolation = Wyłącza dodatkową warstwę zabezpieczeń Windows, w tym integralność pamięci. Zmniejsza to ochronę i może wpływać na aplikacje lub gry, które jej wymagają.
consequence-remove-snipping-tool = Usuwa aplikację Windows do robienia zrzutów ekranu i nagrywania ekranu.
consequence-uninstall-edge = Usuwa przeglądarkę Microsoft Edge. Upewnij się, że masz inną przeglądarkę, lub wybierz jedną poniżej.
consequence-install-another-browser = Wybierz przeglądarkę poniżej, a Atlas ją zainstaluje.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas dostosowuje Windows, aby ograniczyć aktywność w tle i rozpraszające elementy. Przeprowadzimy Cię przez sprawdzanie komputera i wybór ustawień, zanim wprowadzimy zmiany.

detail-build-missing = Ten plik playbook nie określa obsługiwanych kompilacji Windows. Wybierz pełny plik playbook zamiast pakietu LocalTest.
## ISO creation (Beta)
iso-home-title = Nośnik instalacyjny Windows
iso-home-description = Utwórz obraz ISO systemu Windows z Atlasem do czystej instalacji na tym lub innym komputerze.
iso-open = Utwórz ISO z Atlasem
iso-title = Utwórz ISO z Atlasem
iso-beta = Beta
iso-beta-description = Przetestuj obraz ISO na maszynie wirtualnej, zanim użyjesz go na komputerze. Przed instalacją Windows zrób kopię zapasową plików.
iso-admin-description = Odczytywanie obrazów Windows i tworzenie nośników instalacyjnych wymaga uprawnień administratora.
iso-files-description = Wybierz niezmodyfikowany obraz ISO Windows 11 x64, playbook Atlasa (.apbx) oraz nową nazwę pliku wynikowego.
iso-source = Obraz ISO Windows
iso-package = Playbook Atlasa (0.6+)
iso-output = Zapisz nowy obraz ISO w
iso-no-file = Nie wybrano pliku
iso-browse = Przeglądaj
iso-save-as = Zapisz jako
iso-inspect = Sprawdź pliki
iso-mode-title = Ustawienia Windows i Atlasa
iso-mode-interactive = Wybierz ustawienia Atlasa po zalogowaniu
iso-mode-interactive-description = Po zalogowaniu Atlas pomoże Ci zaktualizować Windows i aplikacje ze sklepu, wybrać ustawienia i zainstalować Atlasa.
iso-mode-before = Wybierz ustawienia Atlasa teraz
iso-mode-before-description = Zapisz ustawienia Atlasa w obrazie ISO. Po zalogowaniu zaktualizuj Windows i aplikacje ze sklepu, a następnie zainstaluj Atlasa z tymi ustawieniami.
iso-package-unsupported-title = Wybierz nowszy playbook
iso-package-unsupported = Instalacja z ISO wymaga Atlas 0.6 lub nowszej wersji z obsługą ISO. Wybierz zgodny playbook.
iso-atlas-options = Ustawienia Atlasa
iso-review = Sprawdź podsumowanie
iso-review-description = Atlas utworzy nowy obraz ISO i zachowa oryginał. Uruchom komputer z nowego obrazu, aby zainstalować Windows. Utworzenie obrazu nie instaluje Atlasa na tym komputerze.
iso-review-files = Pliki
iso-review-package = Playbook Atlasa
iso-review-output = Nowy obraz ISO
iso-review-editions = Edycje
iso-review-size = Rozmiar
iso-review-size-value = { $size } MB
iso-review-account = Nazwa konta
iso-review-target = Instalacja na
iso-review-drivers = Sterowniki
iso-create = Utwórz ISO
iso-stage-inspect = Sprawdzanie obrazu Windows
iso-stage-copy = Kopiowanie plików Windows
iso-stage-inject = Dodawanie Atlasa
iso-stage-master = Tworzenie obrazu ISO
iso-stage-verify = Weryfikowanie wyniku
iso-stage-cleanup = Kończenie
iso-progress-description = Pozostaw aplikację otwartą. Przetwarzanie dużych obrazów może potrwać.
iso-cancel = Anuluj tworzenie
iso-cancelling = Oczekiwanie na bezpieczne zatrzymanie
iso-cancelled = Anulowano tworzenie ISO
iso-cancelled-description = Oryginalny obraz ISO został zachowany. Dziennik diagnostyczny wskazuje pliki tymczasowe, które mogą jeszcze wymagać usunięcia.
iso-complete = Obraz ISO jest gotowy
iso-complete-description = Przetestuj go na maszynie wirtualnej, a następnie użyj do utworzenia nośnika instalacyjnego Windows.
iso-open-folder = Pokaż w folderze
iso-failed = Nie udało się utworzyć obrazu ISO
iso-failed-description = Otwórz diagnostykę, aby sprawdzić przyczynę. Rozwiąż problem i spróbuj ponownie z nową nazwą pliku wynikowego.
iso-diagnostics = Otwórz diagnostykę
iso-close-title = Tworzenie ISO nadal trwa
iso-close-message = Pozostaw to okno otwarte, aż tworzenie lub anulowanie się zakończy. Anulowanie nastąpi, gdy bieżącą operację będzie można bezpiecznie zatrzymać.
iso-keep-open = Pozostaw otwarte
prepare-title = Zaktualizuj Windows i aplikacje ze sklepu
prepare-description = Przed instalacją Atlasa zainstaluj aktualizacje Windows oraz zaktualizuj Microsoft Store i wszystkie zainstalowane aplikacje ze sklepu. Aplikacje ze sklepu mogą zostać zamknięte podczas aktualizacji.
prepare-complete = Windows i aplikacje ze sklepu są aktualne.
prepare-reboot = Windows wymaga ponownego uruchomienia. Twoje ustawienia Atlasa zostaną zapisane. Po zalogowaniu ponownie sprawdź aktualizacje.
prepare-failed = Nie udało się ukończyć części aktualizacji. Sprawdź dziennik diagnostyczny, rozwiąż problemy z Windows lub sklepem i spróbuj ponownie.
prepare-cancelled = Przygotowanie zostało zatrzymane. Przed kontynuowaniem ponownie sprawdź aktualizacje.
prepare-windows-search = Sprawdzanie aktualizacji Windows…
prepare-windows-download = Pobieranie aktualizacji Windows…
prepare-windows-install = Instalowanie aktualizacji Windows…
prepare-store-search = Sprawdzanie Microsoft Store…
prepare-store-install = Aktualizowanie Microsoft Store i aplikacji…
prepare-stop-description = Zatrzymanie nastąpi po zakończeniu bieżącej operacji aktualizacji. Do tego czasu pozostaw Atlas otwarty.
prepare-stop = Zatrzymaj po tej operacji
prepare-restart = Uruchom ponownie i kontynuuj
prepare-start = Sprawdź i zainstaluj aktualizacje
iso-username = Nazwa konta lokalnego
iso-account-description = Po ponownej instalacji Windows poprosi Cię o ustawienie hasła.
iso-username-placeholder = Twoje imię
iso-account-invalid = Użyj od 1 do 20 znaków, bez spacji na początku lub końcu i bez symboli niedozwolonych w nazwach kont Windows.
iso-privacy-defaults = Podczas konfiguracji Windows automatycznie wyłącza opcjonalne udostępnianie danych i spersonalizowane oferty.
prepare-drivers = Jak chcesz instalować sterowniki?
prepare-drivers-auto = Pobieraj sterowniki przez Windows Update
prepare-drivers-auto-detail = Windows wyszuka sterowniki do Twojego sprzętu. Zalecane dla większości komputerów.
prepare-drivers-manual = Zainstaluję sterowniki samodzielnie
prepare-drivers-manual-detail = Blokuje pobieranie sterowników przez Windows Update. Musisz zdobyć je samodzielnie; zainstalowane sterowniki pozostaną na komputerze.
prepare-network-needed = Połącz się przez Wi-Fi lub Ethernet bez ustawionego limitu i spróbuj ponownie. Jeśli brakuje Wi-Fi, najpierw zainstaluj sterownik sieciowy.
prepare-network-settings = Otwórz ustawienia sieci
iso-target-title = Na którym komputerze chcesz ponownie zainstalować Windows?
iso-target-this = Na tym komputerze
iso-target-other = Na innym komputerze
iso-copy-network = Dołącz sterowniki sieciowe tego komputera
iso-network-detail = Wykorzystuje sterowniki Wi-Fi i Ethernet tego komputera podczas instalacji Windows. Po instalacji połącz się ponownie z Wi-Fi.
iso-network-source = Źródło sterowników sieciowych
iso-network-installed = Użyj zainstalowanych sterowników
iso-network-updated = Najpierw sprawdź Windows Update
iso-network-updated-detail = Pobiera pasujące sterowniki z Windows Update i zachowuje zainstalowane jako zapasowe. Wymaga połączenia bez ustawionego limitu.
iso-stage-network-drivers = Przygotowywanie sterowników sieciowych…
iso-network-failed = Nie udało się przygotować sterowników sieciowych. Sprawdź dane diagnostyczne lub wróć i zmień opcję sterowników sieciowych.
iso-mode-desktop = Dokończ konfigurację przed otwarciem pulpitu
iso-mode-desktop-description = Wybierz teraz ustawienia Atlasa. Po zalogowaniu dokończ aktualizacje i konfigurację, zanim otworzy się pulpit Windows.
desktop-setup-description = Dokończ konfigurację komputera. Twoje ustawienia Atlasa są zapisane; w razie potrzeby możesz wrócić do Windows.
desktop-setup-exit = Kontynuuj w Windows

# Windows installation USB (Beta)
usb-title = Utwórz USB instalacyjne
usb-existing = Utwórz USB z istniejącego obrazu ISO
usb-description = Utwórz rozruchowy nośnik USB z Windows 11 25H2, aby zainstalować Windows i Atlasa na swoim komputerze.
usb-choose-iso = Wybierz ISO
usb-drive = Dysk USB
usb-empty = Podłącz dysk USB i odśwież listę. Wyświetlane są tylko zapisywalne dyski USB, które nie zawierają uruchomionej instalacji Windows.
usb-refresh = Odśwież
usb-drive-detail = { $size } GB · { $volumes } · Numer seryjny: { $serial }
usb-review = Sprawdź USB
usb-erase-title = Wymazać ten dysk USB?
usb-erase-description = Wszystkie pliki i partycje na dysku { $drive } ({ $size } GB) zostaną trwale usunięte. Obraz ISO zostanie zachowany.
usb-layout = Instalator Windows użyje do 32 GB. Pozostałe miejsce będzie nieprzydzielone. Ten nośnik jest przeznaczony dla komputerów uruchamianych w trybie UEFI.
usb-ack = Rozumiem, że cała zawartość tego dysku USB zostanie usunięta.
usb-write = Wymaż i utwórz USB
usb-stage-prepare = Przygotowywanie plików instalacyjnych…
usb-stage-format = Formatowanie USB…
usb-stage-copy = Kopiowanie plików instalacyjnych…
usb-stage-verify = Weryfikowanie USB…
usb-working = Pozostaw Atlas otwarty i dysk USB podłączony. Anulowanie zaczeka na bezpieczne zatrzymanie bieżącej operacji. Nieukończony nośnik nie nadaje się do instalacji Windows.
usb-failed = Nie udało się ukończyć nośnika USB. Sprawdź połączenie i otwórz diagnostykę, aby poznać szczegóły. Wybierz dysk ponownie, aby ponowić próbę.
usb-cancelled = Tworzenie USB zostało zatrzymane. Dysk może zawierać niekompletne pliki instalacyjne. Utwórz go ponownie przed instalacją Windows.
usb-complete = Nośnik USB jest gotowy, a wszystkie pliki zostały zweryfikowane. Wysuń go, podłącz do komputera, na którym chcesz ponownie zainstalować Windows, i wybierz go w menu rozruchowym UEFI.
usb-eject = Wysuń USB
usb-ejected = Możesz bezpiecznie odłączyć USB. Aby zainstalować Windows, wybierz ten nośnik w menu rozruchowym UEFI komputera.
usb-eject-failed = Windows nie mógł wysunąć USB. Zamknij pliki lub okna korzystające z tego dysku i spróbuj ponownie.
ready-fresh-title = Zacznij od czystej instalacji Windows
ready-fresh-description = Atlas wymaga czystej instalacji Windows, z wyjątkiem obsługiwanych uaktualnień Atlasa. Nowa instalacja Atlasa 0.6 wymaga Windows 11 25H2. Przed ponowną instalacją Windows utwórz kopię zapasową plików.
detail-edition-unsupported = Użyj Windows 11 Pro, Pro for Workstations lub Enterprise. Wersje Home, LTSC i Server nie są obsługiwane. Jeśli nie udało się rozpoznać wersji, rozwiąż ten problem przed kontynuowaniem.
install-source-title = Instalacja niedostępna
install-source-unsupported = Nie można zaktualizować Atlas { $source } bezpośrednio do { $target }. Aby użyć tej wersji, zainstaluj ponownie Windows.
install-source-unknown = Atlas nie mógł sprawdzić stanu instalacji. Rozwiąż problemy z niedokończoną instalacją i sprawdź dane diagnostyczne, zanim spróbujesz ponownie.
iso-edition-selection = Uwzględnione są tylko obsługiwane edycje. Podczas instalacji Windows wybierz edycję, na którą masz licencję Windows.
detail-windows-preview = Kompilacje Insider nie są obsługiwane. Użyj publicznie wydanej wersji systemu Windows 11.
detail-windows-release-unknown = Atlas nie mógł potwierdzić, że ta kompilacja systemu Windows została publicznie wydana. Połącz się z internetem i sprawdź ponownie.
iso-release-unknown = Nie udało się potwierdzić, że ten obraz ISO zawiera publicznie wydaną wersję systemu Windows 11 25H2. Połącz się z internetem i spróbuj ponownie lub wybierz oficjalny nośnik instalacyjny.
prepare-previous-worker = Wcześniejsza aktualizacja nadal trwa. Atlas poczeka na jej zakończenie, zanim umożliwi ponowną próbę.

ready-used-windows-title = Zainstaluj Windows ponownie przed kontynuowaniem
ready-used-windows-description = Ta instalacja Windows wykazuje ślady wcześniejszego użytkowania. Instalowanie tu Atlas nie jest wspierane i jest zdecydowanie odradzane. Kontynuuj tylko wtedy, gdy rozumiesz ryzyko.
ready-used-windows-dismiss = Rozumiem ryzyko
playbook-option-install-eclean = Zainstaluj eclean
consequence-install-eclean = Narzędzie do konserwacji od zespołu AtlasOS, które pomaga utrzymać porządek na komputerze po konfiguracji. Przeglądaj zbędne pliki i aplikacje startowe. Wymaga konta i połączenia z internetem.

prepare-resumed = System Windows został ponownie uruchomiony. Twoje wybory w Atlasie zostały przywrócone. Kontynuuj aktualizacje przed instalacją Atlasa.
prepare-continue = Kontynuuj aktualizacje
prepare-saving-restart = Zapisywanie wyborów i ustawianie ponownego otwarcia Atlasa po ponownym uruchomieniu Windows…
prepare-restart-save-failed = Nie udało się zapisać wyborów. Spróbuj ponownie przed ponownym uruchomieniem.
prepare-restart-registration-failed = Wybory zostały zapisane, ale nie udało się ustawić automatycznego otwarcia. Spróbuj ponownie lub uruchom ponownie Windows i otwórz Atlasa ręcznie.
prepare-restart-failed = Nie udało się uruchomić ponownie Windows. Spróbuj ponownie lub uruchom ponownie przez Windows. Wybory są zapisane i Atlas jest ustawiony do ponownego otwarcia.
