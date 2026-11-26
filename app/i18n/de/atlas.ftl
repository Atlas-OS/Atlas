### Atlas Manager: German (de), preview translation. Revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog:
### - Sie-form throughout, "Ihr PC" for the computer, Atlas or Windows as actor.
### - Buttons are short infinitive phrases ("Atlas installieren"); familiar
###   controls keep their Windows names (Zurück, Weiter, Abbrechen, Fertig).
###   A button that opens a step is "Zu „<Schritt>“ wechseln".
### - "neu starten" / "Neustart" always mean the PC or Windows. Reopening the
###   Atlas Manager with administrator rights is "als Administrator ausführen";
###   reopening it otherwise is "Atlas erneut öffnen".
### - Windows feature names follow the German Windows Security app
###   (Manipulationsschutz, Echtzeitschutz, Cloudbasierter Schutz, Automatische
###   Übermittlung von Beispielen, Einstellungen für Viren- & Bedrohungsschutz).
###   The four switches are the "Schutzschalter".
### - Product names stay as they are: Atlas, Windows, Microsoft Defender,
###   Windows-Sicherheit, Windows Update, GitHub, Discord, Atlas Toolbox,
###   Snipping Tool, LocalTest. German quotation marks („ “) mark
###   button and step names quoted inside sentences.
### - The .atlaspkg file is the "Atlas-Paket" ("Paket" once that is clear; its file
###   is the "Paketdatei").
### - Install steps: Vorbereiten, Ihre Auswahl, Windows-Sicherheit, Installieren.
###   ISO steps: Windows, Einrichtung, Erstellen.
### - Windows' own installer is "Windows-Setup"; a USB drive is always "USB-Laufwerk".
### - Stopping the Windows and Store updates is "Updates anhalten"; updating on
###   Get ready is "Aktualisieren" ("wird beim Aktualisieren erledigt").
### - Key names follow German keyboards: Strg, Umschalt (Alt+Umschalt).
### - "Diagnose-ZIP" in titles, "Diagnose-ZIP-Datei" in body text.
### - Plural categories: one, other.

## Shared

app-name = Atlas Manager
common-done = Fertig
common-cancel = Abbrechen
common-back = Zurück
common-next = Weiter
common-dismiss = Schließen
# Link beside a summary row that jumps back to change that choice.
common-change = Ändern
common-copy = Kopieren
# Shown where a list of options is empty.
common-none = Keine
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Zurück zur Startseite
# Accessible name of the gear button in the title bar.
common-settings = Einstellungen
common-close-settings = Einstellungen schließen
common-open-windows-security = Windows-Sicherheit öffnen
# Reopens the Atlas Manager with administrator rights (UAC). Never the PC.
common-restart-as-administrator = Als Administrator ausführen
common-try-again = Erneut versuchen
common-read-the-docs = Atlas-Anleitung lesen
common-show-details = Details anzeigen
common-hide-details = Details ausblenden
# Accessible name of a button that acts on one card. $action is the button's label;
# $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Protokollordner öffnen
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Installationsprotokoll kopieren
common-install-log = Installationsprotokoll
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas-Paket
common-checking = Wird geprüft
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 oder 26200".
list-or = { $a } oder { $b }
# Joins the last two items of a list; $a may itself be several items.
list-and = { $a } und { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Fenster während der Installation schließen?
window-close-installing = Die Installation läuft weiter. Öffnen Sie Atlas erneut, um das Ergebnis zu sehen.
# Instead of window-close-installing when the installation restarts the PC afterwards.
window-close-installing-no-restart = Die Installation läuft weiter, aber Ihr PC wird nicht automatisch neu gestartet. Öffnen Sie Atlas erneut, um das Ergebnis zu sehen.
# The answer that keeps the window open when closing it would interrupt something.
window-close-keep = Offen lassen
window-close-close = Fenster schließen
# Closing during the final checks, before the installer has started. Its buttons are
# window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Vor der Installation abbrechen?
window-close-checks-unchanged = Die Installation hat noch nichts geändert. Wenn Sie das Fenster schließen, wird sie nicht gestartet.
window-close-keep-installing = Weiter installieren
window-close-stop-and-close = Abbrechen und schließen
# Closing while Windows and Store apps update. Its buttons are stop-update-keep and prepare-stop.
prepare-close-question = Updates anhalten?
# A stage of updating is a "Phase" (as in prepare-percent), never a "Schritt".
prepare-close-stops-after-stage = Atlas hält die Updates nach der aktuellen Phase an. Danach können Sie Atlas schließen.
# Closing during the restart countdown after a successful install. Its buttons are
# restart-now and restart-dont-now.
window-close-restart-question = Neu starten, um die Einrichtung von Atlas abzuschließen?
window-close-restart-closed = Nach dem Schließen kann Atlas Ihren PC nicht neu starten. Speichern Sie zuerst Ihre Arbeit.
# Closing while Get ready counts down to the restart updates need. Its buttons are
# restart-now and restart-dont-now.
window-close-update-restart-question = Neu starten, um die Updates abzuschließen?
window-close-update-restart-later = Speichern Sie zuerst Ihre Arbeit. Wenn Sie später neu starten, fährt Atlas nach dem Neustart fort.
# Closing during a setup with Windows Security switches still off. Its buttons are
# common-open-windows-security and window-close-close.
window-close-protection-title = Atlas mit ausgeschaltetem Schutz schließen?
window-close-protection-all = Die vier Schutzschalter der Windows-Sicherheit sind ausgeschaltet. Wenn Sie Atlas jetzt nicht installieren, schalten Sie sie zuerst wieder ein.
# $switches names the switches that are off, joined like a list; $count is how many.
window-close-protection-some = { $count ->
    [one] { $switches } ist in der Windows-Sicherheit ausgeschaltet. Wenn Sie Atlas jetzt nicht installieren, schalten Sie diesen Schalter zuerst wieder ein.
   *[other] { $switches } sind in der Windows-Sicherheit ausgeschaltet. Wenn Sie Atlas jetzt nicht installieren, schalten Sie sie zuerst wieder ein.
}
# Closing while an ISO or a USB drive is being created. Their buttons are
# window-close-keep-creating and window-close-stop.
iso-close-question = ISO-Erstellung abbrechen?
iso-close-safe-point = Atlas bricht am nächsten sicheren Punkt ab.
usb-close-question = Erstellung des USB-Laufwerks abbrechen?
usb-close-unfinished = Mit einem unfertigen Laufwerk lässt sich Windows nicht installieren.
window-close-keep-creating = Weiter erstellen
window-close-stop = Abbrechen
# The Open button of the file picker for an Atlas package (.atlaspkg) file. Keep it short.
file-dialog-open-package = Atlas-Paket (.atlaspkg) öffnen
# Message Windows shows in its restart notification.
shutdown-comment = Atlas ist installiert. Windows wird neu gestartet, um die Einrichtung abzuschließen.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas startet Windows neu, um die Installation der Updates abzuschließen.

## System

# "Windows 11 Pro 25H2 (Build 26200.1234)". All three values are text.
system-description = { $product } { $version } (Build { $build })

## Home page

home-not-installed = Willkommen bei Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". All three
# values are text.
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas reduziert Hintergrundaktivitäten und Ablenkungen in Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas auf diesem PC
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Installiert am { $date }
home-status-checking = Es wird nach Updates gesucht…
# While startup checks whether another window's installation is running.
home-status-recovering = Suche nach laufender Installation
home-status-offline = Suche nach Updates fehlgeschlagen
home-status-not-checked = Noch nicht nach Updates gesucht
home-status-update = Atlas { $version } ist verfügbar
home-status-up-to-date = Auf dem neuesten Stand
home-status-newest = Neueste Version: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Atlas { $version } ist nicht fertig installiert
home-check-again = Erneut prüfen
# Primary button while an install is running or waiting.
home-show-install = Fortschritt anzeigen
home-continue-installing = Einrichtung fortsetzen
home-update-to = Auf Atlas { $version } aktualisieren
home-reinstall = Atlas neu installieren
home-install = Atlas installieren
home-finish-install = Atlas { $version } fertig installieren
home-start-over = Von vorn beginnen
# Asked by Install Atlas where Windows on this PC has been in use. Its buttons are
# common-cancel and home-used-windows-install.
home-used-windows-title = Atlas auf diesem PC installieren?
home-used-windows-message = Vorhandene Apps und Einstellungen funktionieren möglicherweise nicht mehr, und Atlas entfernt OneDrive. Dateien darin werden dann nicht mehr synchronisiert, und Ordner wirken möglicherweise leer. Sichern Sie zuerst Ihre Dateien.
home-used-windows-install = Trotzdem installieren
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Windows mit Atlas neu installieren
# Under home-iso-title, with the Recommended badge.
home-iso-used = Windows wurde auf diesem PC bereits genutzt. Atlas funktioniert am besten nach einer Neuinstallation.
# A bar on Home after an installation finished, until the PC restarts.
home-restart-title = Ihr PC muss neu gestartet werden
# Instead of restart-needed when Windows refused to restart.
home-restart-failed = Atlas konnte Ihren PC nicht neu starten. Starten Sie ihn über das Startmenü neu.
home-security-reminder-title = Schalten Sie Ihren Schutz wieder ein
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read.
home-security-reminder-unreadable-title = Stellen Sie sicher, dass Ihr Schutz eingeschaltet ist
# Under home-security-reminder-title. $switches names the switches that read off, joined like a
# list; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] Dieser Schalter ist in der Windows-Sicherheit noch ausgeschaltet: { $switches }.
       *[other] Diese Schalter sind in der Windows-Sicherheit noch ausgeschaltet: { $switches }.
    }
# Instead of security-switches-still-off when no switch reads off but some couldn't be read.
home-security-reminder-unreadable-message = Atlas konnte nicht alle Schutzschalter lesen. Prüfen Sie in der Windows-Sicherheit, ob diese eingeschaltet sind: { $switches }.
home-elevation-title = Atlas benötigt eine Berechtigung für die Installation
# Under home-elevation-title when the setup choices couldn't be saved.
home-elevation-draft-not-saved = Atlas konnte Ihre Auswahl nicht speichern und wurde deshalb nicht als Administrator neu geöffnet.
home-state-error-title = Ihre Atlas-Installationsdaten konnten nicht gelesen werden
# Its button is common-try-again.
home-state-error-problem = Ihre Atlas-Version, Ihre Auswahl und Ihr Verlauf werden möglicherweise nicht richtig angezeigt.
# A bar on Home when the Atlas package needs a newer Atlas Manager.
home-manager-needed-title = Atlas Manager muss aktualisiert werden
home-whats-new = Neu in Atlas { $version }
home-view-release = Versionshinweise auf GitHub ansehen
home-show-less = Weniger anzeigen
home-show-full-notes = Alle Versionshinweise anzeigen
home-your-install = Ihre Atlas-Installation
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Auf diesem PC ist nicht erfasst, wie Atlas installiert wurde. Ihre Auswahl und der Installationsverlauf können daher nicht angezeigt werden.
home-history = Installationsverlauf
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Schritt { $number }: { $title }
# A numbered step with its sentence, as screen readers read each step of Home's lists. $step is
# home-step-a11y or stepper-item-a11y; $detail is the step's sentence, such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps on a PC without Atlas, each with its
# home-step-* sentence beside it.
home-steps-title = So läuft es ab
# Instead of home-steps-title while a setup is under way.
home-steps-under-way-title = Atlas wird eingerichtet
# Beside step-ready in that card.
home-step-ready = Atlas prüft Ihren PC und aktualisiert Windows.
# Instead of home-step-ready where Windows must move to a newer version first. $release is that
# version, such as "26H2" (text).
home-step-ready-move = Atlas prüft Ihren PC und stellt Windows auf Version { $release } um.
# Beside step-options in that card.
home-step-options = Sie wählen aus, was Sie behalten möchten, etwa Microsoft Defender.
# Beside step-security in that card.
home-step-security = Sie schalten die vier Schutzschalter der Windows-Sicherheit aus.
# Beside step-install in that card. $minutes is how long installing usually takes (a number). The
# first is shown when the PC restarts by itself, the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
        [one] Die Installation dauert meist etwa { $minutes } Minute, danach wird Ihr PC neu gestartet.
       *[other] Die Installation dauert meist etwa { $minutes } Minuten, danach wird Ihr PC neu gestartet.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] Die Installation dauert meist etwa { $minutes } Minute, danach starten Sie Ihren PC neu.
       *[other] Die Installation dauert meist etwa { $minutes } Minuten, danach starten Sie Ihren PC neu.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Speichern Sie zuerst Ihre Arbeit: Apps werden möglicherweise geschlossen, und Ihr PC wird neu gestartet.
home-github = Atlas auf GitHub ansehen
home-discord = Atlas-Community auf Discord beitreten
home-report-problem = Problem melden

## How an install was done (from the state document)

# Forms used inside a history row. German nouns stay capitalised.
history-mode-fresh = Erstinstallation
history-mode-upgrade = Update
history-mode-reapply = Neuinstallation
history-mode-unknown = Installation

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas verwendet die Standardeinstellungen der App
notice-settings-unreadable-problem = Atlas konnte Ihre gespeicherten App-Einstellungen nicht lesen. Ihre Windows-Einstellungen sind unverändert.
notice-settings-damaged-kept-problem = Die Datei mit Ihren App-Einstellungen war beschädigt. Atlas hat sie zurückgesetzt und eine Kopie der alten Datei behalten.
notice-settings-damaged-problem = Die Datei mit Ihren App-Einstellungen war beschädigt. Atlas verwendet vorerst die Standardeinstellungen.
notice-settings-not-saved-title = App-Einstellungen konnten nicht gespeichert werden
notice-settings-not-saved-problem = Atlas konnte Ihre letzten Änderungen nicht speichern. Sie gehen möglicherweise verloren, wenn Sie Atlas schließen. Wenn ein anderes Atlas-Fenster geöffnet ist, schließen Sie es und nehmen Sie die Änderung erneut vor.
notice-session-unreadable-title = Vorherige Installation konnte nicht geprüft werden
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas konnte nicht feststellen, ob eine frühere Installation noch läuft. Wenn Sie sicher sind, dass keine läuft, löschen Sie die Installationsaufzeichnung und öffnen Sie Atlas dann erneut.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas konnte nicht feststellen, ob eine frühere Installation noch läuft. Wenn Sie unsicher sind, bitten Sie die Atlas-Community um Hilfe. Nur wenn Sie sicher sind, dass keine Installation läuft, löschen Sie { $path } und versuchen Sie es erneut. Details: { $error }

## Administrator elevation

elevation-declined = Die Berechtigung wurde nicht erteilt. Versuchen Sie es erneut und wählen Sie „Ja“, wenn Windows fragt, ob Atlas Änderungen an Ihrem Gerät vornehmen darf.
elevation-declined-continue = Die Berechtigung wurde nicht erteilt. Versuchen Sie es erneut und wählen Sie „Ja“, wenn Windows fragt, ob Atlas Änderungen an Ihrem Gerät vornehmen darf. Ihre Auswahl ist gespeichert.
elevation-draft-not-saved = Atlas konnte Ihre Auswahl nicht speichern und wurde deshalb nicht als Administrator neu geöffnet. Versuchen Sie es erneut. Details: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Ein anderes Atlas-Fenster verwendet jetzt diese Einrichtung, daher wurde Atlas nicht als Administrator neu geöffnet. Fahren Sie in dem anderen Fenster fort oder wählen Sie „Von vorn beginnen“, um die Einrichtung hier noch einmal zu durchlaufen.

## The install flow

step-ready = Vorbereiten
step-options = Ihre Auswahl
step-security = Windows-Sicherheit
step-install = Installieren
install-title = Atlas einrichten
# Accessible name of the row of steps.
stepper-label = Schritte der Atlas-Einrichtung
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = abgeschlossen
stepper-status-current = aktueller Schritt
stepper-status-upcoming = späterer Schritt
# A step already visited whose requirements aren't met yet.
stepper-status-attention = erfordert Aufmerksamkeit
# Names the step showing; read when the current step takes focus.
step-heading = Schritt { $number } von { $total }: { $title }
# Accessible name of the current step on Your choices. $heading is stepper-item-a11y;
# $questions is what the screen asks.
step-heading-choices-a11y = { $heading }. { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates.

# Row title, as a checklist item.
ready-checks-title = PC prüfen
# Status line while the checks run.
ready-checks-running = Ihr PC wird geprüft…
ready-check-again = Erneut prüfen
# Status line once every check passed.
ready-checks-passed =
    { $count ->
        [one] { $count } Prüfung bestanden
       *[other] { $count } Prüfungen bestanden
    }
# Status line when some checks need attention.
ready-checks-passed-some =
    { $total ->
        [one] { $passed } von { $total } Prüfung bestanden
       *[other] { $passed } von { $total } Prüfungen bestanden
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of: "5 von 9 Prüfungen bestanden · 4 werden beim Aktualisieren erledigt".
ready-checks-handled =
    { $count ->
        [one] { $count } wird beim Aktualisieren erledigt
       *[other] { $count } werden beim Aktualisieren erledigt
    }
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = wird beim Aktualisieren erledigt
# Under the title of a check that updating takes care of.
check-updates-handled = Updates stehen aus. Atlas installiert sie beim Aktualisieren von Windows.
check-restart-handled = Windows muss neu gestartet werden, um frühere Änderungen abzuschließen. Das wird beim Aktualisieren erledigt.
check-handled = Das wird beim Aktualisieren erledigt.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Wird heruntergeladen…
ready-package-unpacking = Wird entpackt…
ready-package-ready = Bereit
ready-package-checking = Neueste Version wird gesucht…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Mitgeliefertes Atlas-Paket wird vorbereitet…
ready-package-none = Noch nicht heruntergeladen
ready-package-failed = Atlas-Paket konnte nicht abgerufen werden
# Under ready-package-failed, with package-download-again and package-open-file.
ready-package-failed-detail = Laden Sie es erneut herunter oder öffnen Sie ein anderes Atlas-Paket (.atlaspkg).
# Tester build: the same, with Try again as the only control.
ready-package-bundled-failed-detail = Das mit dieser Testversion mitgelieferte Atlas-Paket konnte nicht entpackt werden. Versuchen Sie es erneut.
ready-package-manager = Erfordert einen neueren Atlas Manager
ready-package-release-failed = Neueste Version konnte nicht ermittelt werden
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Prüfen Sie Ihre Internetverbindung und versuchen Sie es dann erneut. Wenn Sie ein Atlas-Paket (.atlaspkg) haben, können Sie stattdessen dieses öffnen.
# Row title.
ready-updates-title = Updates für Windows und Microsoft Store
# Status line before updating starts.
ready-updates-pending = Store-Apps wie Editor werden beim Aktualisieren möglicherweise geschlossen. Speichern Sie zuerst Ihre Arbeit darin.
# Status line while Windows moves to version $release.
ready-updates-after-move = Beginnt, nachdem Windows auf Version { $release } umgestellt wurde.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Wird nach dem Neustart fortgesetzt…
ready-updates-restarting = Ihr PC wird neu gestartet…
ready-updates-done = Windows und die Store-Apps sind auf dem neuesten Stand.
# Instead of ready-updates-done where Microsoft Store is turned off.
ready-updates-done-windows = Windows ist auf dem neuesten Stand.
# The countdown before the restart updating needs.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Ihr PC wird in { $seconds } Sekunde neu gestartet.
       *[other] Ihr PC wird in { $seconds } Sekunden neu gestartet.
    }
ready-updates-restart = Ihr PC muss neu gestartet werden, um die Updates abzuschließen.
ready-updates-restart-finish = Windows muss noch einmal neu gestartet werden, um die Installation von Version { $release } abzuschließen.
ready-updates-restart-failed = Ihr PC wurde nicht neu gestartet
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Speichern Sie zuerst Ihre Arbeit.
ready-updates-restart-persists = Windows verlangt weiterhin einen Neustart
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Ein weiterer Neustart hilft wahrscheinlich nicht. Schließen Sie alles ab, was in Windows Update aussteht, und versuchen Sie es dann erneut.
# $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Gründe für den Neustart: { $reasons }
ready-updates-network = Updates können diese Verbindung nicht nutzen
ready-updates-stopped = Aktualisierung angehalten. Einige Updates sind möglicherweise bereits installiert.
ready-updates-previous = Warten auf zuvor gestartete Updates…
# Button after the user stopped updating.
ready-updates-resume = Updates fortsetzen
ready-updates-start = Updates starten
# Why updating hasn't started, under the row.
ready-updates-blocked = Updates warten, bis Atlas auf diesem PC installiert werden kann.
ready-updates-needs-admin = Beginnt, sobald Atlas Administratorrechte hat.
ready-updates-needs-windows = Beginnt, sobald die Prüfung „Windows-Kompatibilität“ bestanden ist.
ready-updates-needs-drivers = Beginnt, sobald Sie festgelegt haben, wie Treiber installiert werden.
# The driver choice. $choice is ready-drivers-automatic or ready-drivers-manual.
ready-drivers-row = Treiber: { $choice }
ready-drivers-automatic = Über Windows Update
ready-drivers-manual = Selbst installieren
ready-drivers-change-a11y = Ändern, wie Treiber installiert werden
# Under the two answers, once updating has run.
ready-drivers-again = Wenn Sie das ändern, werden die Updates erneut ausgeführt.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } wird heruntergeladen · { $received } von { $total } MB
package-unpacking = Wird entpackt
package-status-ready = Bereit
# Accessible name of the progress bar.
package-progress = Fortschritt des Atlas-Pakets
package-download-again = Erneut herunterladen
package-download-version = Atlas { $version } herunterladen
package-download-newest = Neueste Version herunterladen
package-cancel-download = Download abbrechen
package-open-file = Paketdatei öffnen
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } wurde von GitHub heruntergeladen und ist bereit zur Installation.
package-from-file = Atlas { $version } wurde aus { $file } geladen und ist bereit zur Installation.
package-unpacked = Atlas { $version } ist bereit zur Installation.
package-none-yet = Noch kein Atlas-Paket
acquire-no-asset = Für Atlas { $version } gibt es keine Paketdatei zum Herunterladen. Öffnen Sie ein gespeichertes Atlas-Paket (.atlaspkg), um fortzufahren.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package.
acquire-unsupported = Diese App kann Atlas 0.6.0 und neuer aus Atlas-Paketen (.atlaspkg) installieren.
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = Das ist eine Windows-ISO, kein Atlas-Paket (.atlaspkg). Um Windows mit Atlas neu zu installieren, erstellen Sie damit eine Atlas-ISO.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = In Atlas { $version } fehlen Dateien, die diese App zur Installation benötigt. Laden Sie es erneut herunter oder öffnen Sie ein anderes Atlas-Paket (.atlaspkg).
acquire-failed = Das Atlas-Paket konnte nicht vorbereitet werden. Laden Sie es erneut herunter oder öffnen Sie ein anderes Atlas-Paket (.atlaspkg). Details: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Der Download reagiert nicht mehr. Prüfen Sie Ihre Internetverbindung und starten Sie den Download dann erneut oder öffnen Sie ein gespeichertes Atlas-Paket (.atlaspkg).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Das mitgelieferte Atlas-Paket konnte nicht vorbereitet werden. Wählen Sie „Erneut versuchen“. Details: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks
# for, such as 0.7.0. "Ihn" is the Atlas Manager downloaded; "die gerade geöffnete Version" is
# the Atlas Manager running now.
acquire-manager-update-needed = Dieses Atlas-Paket erfordert einen neueren Atlas Manager. Laden Sie Atlas Manager { $version } oder neuer herunter und verwenden Sie ihn statt der gerade geöffneten Version.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Dieses Atlas-Paket erfordert einen neueren Atlas Manager. Laden Sie den neuesten Atlas Manager herunter und verwenden Sie ihn statt der gerade geöffneten Version.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later.
acquire-manager-update-required = Um Atlas { $version } zu installieren, laden Sie Atlas Manager { $required } oder neuer herunter und verwenden Sie ihn statt der gerade geöffneten Version.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Um Atlas { $version } zu installieren, laden Sie den neuesten Atlas Manager herunter und verwenden Sie ihn statt der gerade geöffneten Version.

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Atlas Manager herunterladen
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } ist verfügbar
manager-update-message = Atlas Manager kann sich nicht selbst aktualisieren. Laden Sie die neue Version herunter und verwenden Sie sie statt dieser.

## System checks

check-administrator = Berechtigung zur Installation
check-supported-build = Windows-Kompatibilität
check-pending-updates = Windows-Updates
check-pending-reboot = Ausstehender Neustart
check-third-party-antivirus = Andere Antivirensoftware
check-internet = Internetverbindung
check-power = Stromversorgung
check-activation = Windows-Aktivierung
# Checks shown only where Atlas moves Windows to a newer version.
check-move-hardware = Hardware für Windows 11
check-move-space = Freier Speicherplatz
check-move-update-source = Updatequelle
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = wird geprüft
check-state-passed = in Ordnung
check-state-warning = Hinweis beachten
check-state-failed-blocking = vor der Installation zu beheben
check-state-failed = Hinweis beachten
check-state-unknown = konnte nicht geprüft werden
check-fix-windows-update = Windows Update öffnen
check-fix-network = Netzwerkeinstellungen öffnen
check-fix-power = Energieeinstellungen öffnen
check-fix-activation = Aktivierung öffnen
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = Speichereinstellungen öffnen
# Opens Installed apps in Windows Settings, the page "Installierte Apps" (as in fixed-installed).
check-fix-installed-apps = Installierte Apps öffnen
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Ich habe in Windows Update nachgesehen: Es warten keine Updates auf die Installation

detail-admin-ok = Atlas hat die Berechtigung, die für die Installation nötigen Änderungen vorzunehmen.
detail-admin-missing = Führen Sie Atlas als Administrator aus. Fragt Windows um Erlaubnis, wählen Sie „Ja“.
# $builds is a list of build numbers such as "26100 oder 26200"; $build is this PC's (text).
detail-build-unsupported = Diese Atlas-Version benötigt Windows-Build { $builds }. Ihr PC hat Build { $build }. Installieren Sie eine unterstützte Windows-Version, bevor Sie fortfahren.
detail-build-missing = Dieses Atlas-Paket gibt keine unterstützten Windows-Builds an. Verwenden Sie einen vollständigen Build des Pakets statt eines LocalTest-Builds.
detail-updates-none = Es warten keine Windows-Updates auf die Installation.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } Update steht noch aus. Installieren Sie es in Windows Update und prüfen Sie dann erneut.
       *[other] { $count } Updates stehen noch aus. Installieren Sie sie in Windows Update und prüfen Sie dann erneut.
    }
detail-updates-scan-failed = Atlas konnte nicht nach Windows-Updates suchen. Öffnen Sie Windows Update, um zu sehen, ob Updates ausstehen. ({ $error })
detail-reboot-none = Windows benötigt derzeit keinen Neustart.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows muss neu gestartet werden, um frühere Änderungen abzuschließen. Starten Sie Ihren PC neu und prüfen Sie dann erneut.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows muss neu gestartet werden, um frühere Änderungen abzuschließen ({ $reasons }). Starten Sie Ihren PC neu und prüfen Sie dann erneut.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Sie können fortfahren. Windows muss beim nächsten Neustart Dateien ersetzen oder entfernen ({ $files }). Manche Apps, etwa Xbox Gaming Services, verursachen das nach jedem Neustart.
detail-reboot-unknown = Es konnte nicht geprüft werden, ob Windows einen Neustart benötigt. Starten Sie Ihren PC neu, öffnen Sie Atlas erneut und prüfen Sie noch einmal. ({ $error })
detail-antivirus-none = Es wurde keine andere Antivirensoftware gefunden.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Andere Antivirensoftware als Microsoft Defender kann die Installation blockieren. Deinstallieren Sie { $products } und prüfen Sie dann erneut.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Die Windows-Sicherheit führt { $products } noch auf, aber die Dateien sind nicht mehr vorhanden, die Software ist also nicht mehr installiert. Atlas kann trotzdem installiert werden.
detail-antivirus-check-failed = Atlas konnte nicht prüfen, ob andere Antivirensoftware installiert ist. Wenn das Problem weiterhin auftritt, starten Sie Ihren PC neu und prüfen Sie erneut. ({ $error })
detail-internet-ok = Sie sind verbunden. Halten Sie die Verbindung aufrecht, während Atlas Software herunterlädt und installiert.
detail-internet-missing = Stellen Sie eine Internetverbindung her und prüfen Sie dann erneut.
detail-power-mains = Ihr PC ist an das Stromnetz angeschlossen. Lassen Sie ihn angeschlossen, bis die Installation abgeschlossen ist.
detail-power-battery = Schließen Sie Ihren PC ans Stromnetz an, damit er während der gesamten Installation eingeschaltet bleibt.
detail-power-check-failed = Atlas konnte nicht feststellen, ob Ihr PC am Stromnetz angeschlossen ist. Wenn es ein Laptop ist, schließen Sie ihn an und prüfen Sie dann erneut.
detail-activation-ok = Windows ist aktiviert. Atlas ändert daran nichts.
detail-activation-missing = Windows ist nicht aktiviert. Sie können fortfahren, aber Atlas aktiviert Windows nicht für Sie.
detail-activation-no-licence = Windows hat keine Lizenz gemeldet. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht.
detail-activation-unknown = Die Windows-Aktivierung konnte nicht geprüft werden. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas muss Windows auf diesem PC nicht auf eine neuere Version umstellen.
detail-move-hardware-ready = Dieser PC hat TPM 2.0 und UEFI-Firmware, die Windows 11 benötigt.
detail-move-hardware-missing = Diesem PC fehlt die erforderliche Hardware ({ $missing }), daher stellt Windows Update ihn nicht auf Version { $release } um. Sichern Sie Ihre Dateien und installieren Sie Windows dann mit einer Atlas-ISO neu.
detail-move-hardware-unread = Atlas konnte nicht die gesamte Hardware dieses PCs lesen, daher prüft Windows Update sie.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = Auf { $drive } sind { $free } GB frei.
detail-move-space-short = Version { $release } benötigt { $needed } GB freien Speicherplatz auf { $drive }, dort sind { $free } GB frei. Geben Sie Speicherplatz frei; Atlas prüft dann automatisch erneut.
detail-move-space-unknown = Der freie Speicherplatz für das Windows-Update konnte nicht geprüft werden. Starten Sie Ihren PC neu und prüfen Sie dann erneut. ({ $error })
detail-move-update-source-ok = Dieser PC erhält Updates über Windows Update.
detail-move-update-source-managed = Dieser PC erhält Updates vom Server seiner Organisation, der Version { $release } nicht anbietet. Wenden Sie sich an Ihre Organisation oder installieren Sie Windows mit einer Atlas-ISO neu.

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back.
options-change-later = Microsoft Defender, Prozessorschutz und Update-Einstellungen können Sie später im Atlas-Ordner auf Ihrem Desktop ändern.
# The status line of the folded Optional extras card.
options-extras-none = Keine ausgewählt
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = { $count } ausgewählt
# Links that unfold and fold the Optional extras card.
options-extras-show = Anzeigen
options-extras-hide = Ausblenden
# Under each question's title, one sentence at most.
question-defender-description = Microsoft Defender ist der in Windows integrierte Virenschutz.
question-mitigations-description = Diese Schutzfunktionen, auch Mitigationen genannt, schützen vor Prozessorschwachstellen wie Spectre und Meltdown und vor Angriffen, die Fehler in Apps ausnutzen.
question-auto-updates-description = In beiden Fällen belässt Atlas Windows auf der aktuellen Version und schaltet automatische Updates für Apps aus dem Microsoft Store aus.
question-browser-description = Atlas ändert Ihre Browsereinstellungen nicht.
# One line under an answer other than the recommended one: what it costs. cost-defender-disable
# is also the caution under Remove Microsoft Defender and the message after removing Defender.
cost-defender-disable = Ihr PC hat keinen Virenschutz, bis Sie eine andere Antivirensoftware installieren, und Windows warnt Sie nicht mehr, bevor Sie nicht erkannte Apps oder Downloads öffnen.
# "Exploit-Schutz" is the Windows Security page of that name.
cost-mitigations-disable = Das schaltet auch den Exploit-Schutz für Apps aus, etwa den Ablaufsteuerungsschutz (CFG), und verringert so die Sicherheit.
cost-auto-updates-disable = Öffnen Sie regelmäßig Windows Update, um Sicherheitskorrekturen zu erhalten.
cost-auto-updates-default = Windows startet Ihren PC möglicherweise neu, um Updates fertig zu installieren.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Umschalt und Strg+Umschalt wechseln nicht mehr die Sprache oder das Layout.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Gibt Speicherplatz frei, aber Ruhezustand und Schnellstart stehen nicht mehr zur Verfügung.
extra-disable-power-saving = Ihr PC verbraucht möglicherweise mehr Strom, wird wärmer und hält im Akkubetrieb kürzer durch.
extra-disable-core-isolation = Verringert den Schutz, und Spiele mit Anti-Cheat-Systemen wie Riot Vanguard oder FACEIT starten möglicherweise erst, wenn Sie die Speicherintegrität wieder einschalten.
extra-uninstall-edge = Ihre Favoriten, Ihr Verlauf und Ihre gespeicherten Kennwörter in Edge auf diesem PC werden gelöscht, sofern sie nicht mit Ihrem Microsoft-Konto synchronisiert sind.
extra-install-toolbox = Hilft Ihnen, Ihre Atlas-Einstellungen zu verwalten; in der Betaphase sind manche Funktionen eventuell noch unfertig.
extra-install-eclean = Ein Tool vom Team hinter AtlasOS zum Prüfen überflüssiger Dateien und Autostart-Apps. Erfordert ein Konto und eine Internetverbindung.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Microsoft Defender behalten?
screen-mitigations-title = Prozessorschutz
screen-mitigations-question = Prozessorschutz von Windows beibehalten?
screen-updates-title = Windows Update
screen-updates-question = Wie soll Windows Updates installieren?
screen-browser-title = Browser
screen-power-title = Energie und Sicherheit
screen-apps-title = Apps
screen-optional-apps-title = Optionale Apps
screen-choose-one-title = Option wählen
screen-extras-title = Optionale Extras
# Each decision's short name in the middle of a sentence, as in summary-change-a11y and
# update-path-differs. German nouns keep their capitals.
screen-update-path-name = Art des Updates
screen-defender-name = Microsoft Defender
screen-mitigations-name = Prozessorschutz
screen-updates-name = Windows Update
screen-keyboard-name = Tastatursprachen
screen-browser-name = Browser
screen-power-name = Energie und Sicherheit
screen-apps-name = Apps
screen-optional-apps-name = optionale Apps
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Feminine, so it reads the same after a colon and in summary-change-a11y.
screen-package-choice-name = eine Einstellung aus dem Atlas-Paket
screen-extras-name = optionale Extras
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wählen Sie eine Option für { $title }
learn-more-defender = Mehr über Microsoft Defender erfahren
learn-more-mitigations = Mehr über Prozessorschutz erfahren
learn-more-updates = Mehr über Windows Update erfahren
learn-more-browser = Mehr über Browser erfahren
learn-more-power = Mehr über Energie und Sicherheit erfahren
learn-more-apps = Mehr über Apps erfahren
learn-more-eclean = Mehr über eclean erfahren
learn-more-keyboard = Mehr über Tastatursprachen erfahren
learn-more-generic = Einrichtungsanleitung lesen
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Behält den integrierten Virenschutz von Windows bei, der hilft, Ihren PC vor Viren und anderen Bedrohungen zu schützen.
consequence-mitigations-default = Behält den Standardschutz von Windows gegen Prozessorschwachstellen und gegen Angriffe bei, die Fehler in Apps ausnutzen.
# Under Turn off processor protections. "Exploit-Schutz" is the Windows Security page of that name.
consequence-mitigations-disable = Schaltet auch den Exploit-Schutz für Apps aus, etwa den Ablaufsteuerungsschutz (CFG). Das verringert die Sicherheit. Ein möglicher Leistungsunterschied hängt von Ihrem Prozessor ab.
consequence-auto-updates-disable = Öffnen Sie regelmäßig Windows Update, um Updates zu installieren. Update-Benachrichtigungen bleiben eingeschaltet.
consequence-auto-updates-default = Windows installiert Updates automatisch, einschließlich Sicherheitskorrekturen.

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Wie möchten Sie auf Atlas { $version } aktualisieren?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Wie möchten Sie Atlas { $version } neu installieren?
# The two answers on that screen, each with the detail line under it. Keep each the same everywhere.
update-path-keep = Auswahl beibehalten
update-path-keep-detail = Atlas behält jede Auswahl so bei, wie sie jetzt auf diesem PC eingestellt ist, und ändert keine davon.
update-path-choose = Neu auswählen
update-path-choose-detail = Sie beginnen mit der aktuellen Einrichtung dieses PCs. Ihre Apps, Dateien und Ihre Personalisierung bleiben erhalten.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Ihre aktuelle Auswahl auf diesem PC
# The value of a row in that list for a choice nothing on the PC shows.
update-path-unknown = Atlas kann das auf Ihrem PC nicht erkennen und fragt Sie daher
# Above that list. $choices lists the screen-*-name messages, joined with list-and.
update-path-differs = In diesen Punkten weicht dieser PC von der Aufzeichnung von Atlas ab: { $choices }.
# A line above the questions Keep my choices still asks.
keep-choices-asked = Jede andere Auswahl behält Atlas so bei, wie sie jetzt auf diesem PC eingestellt ist.
# A short tag under the answer this PC has now, on the screens of Choose again.
option-now = Aktuell auf diesem PC
# Under an answer on a screen of Choose again, when choosing it changes this PC.
change-defender-enable = Atlas stellt Microsoft Defender wieder her. Schalten Sie nach dem Neustart seinen Schutz in der Windows-Sicherheit ein.
change-mitigations-default = Atlas schaltet den Prozessorschutz wieder so ein, wie Windows ihn standardmäßig einstellt. Das wird nach dem Neustart wirksam.
# Under Keep processor protections when every protection is turned on.
change-mitigations-all-on = Alle Prozessorschutzfunktionen sind jetzt eingeschaltet. Wenn Sie den Prozessorschutz behalten, bleiben sie alle eingeschaltet.
change-auto-updates-default = Atlas lässt Windows wieder automatisch Updates installieren.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas schaltet den Ruhezustand wieder ein.
change-power-saving-on = Atlas schaltet das Energiesparen wieder ein und kehrt zu Ihrem früheren Energiesparplan zurück oder, falls es keinen gibt, zu „Ausbalanciert“.
change-core-isolation-on = Atlas schaltet die virtualisierungsbasierte Sicherheit (VBS) wieder ein, sofern keine Richtlinie auf diesem PC sie steuert. Das wird nach dem Neustart wirksam.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Entfernt das Snipping Tool für alle Benutzer dieses PCs. Atlas kann es später nicht wiederherstellen, aber Sie können es aus dem Microsoft Store erneut installieren.
# "Install or Remove Edge" is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge wurde bereits entfernt, und ein Update von Atlas kann Edge nicht wiederherstellen. Um Edge erneut zu installieren, verwenden Sie „Install or Remove Edge“ im Atlas-Ordner.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
fixed-installed = { $app } ist installiert. Atlas deinstalliert keine Apps. Zum Entfernen öffnen Sie „Installierte Apps“ in den Windows-Einstellungen.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } bleibt installiert, und Atlas installiert zusätzlich { $browser }.

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too, without the
## recommendation, for places where the choice is already made.

package-option-defender-enable = Microsoft Defender behalten (empfohlen)
package-option-defender-enable-short = Microsoft Defender behalten
package-option-defender-disable = Microsoft Defender entfernen
package-option-mitigations-default = Prozessorschutz behalten (empfohlen)
package-option-mitigations-default-short = Prozessorschutz behalten
package-option-mitigations-disable = Prozessorschutz ausschalten
package-option-auto-updates-disable = Updates selbst installieren
package-option-auto-updates-default = Updates automatisch installieren
package-option-disable-hibernation = Ruhezustand ausschalten
package-option-disable-power-saving = Energiesparen ausschalten
package-option-disable-core-isolation = Virtualisierungsbasierte Sicherheit (VBS) ausschalten
package-option-remove-snipping-tool = Snipping Tool entfernen
package-option-uninstall-edge = Microsoft Edge entfernen
package-option-install-another-browser = Browser installieren
package-option-install-toolbox = Atlas Toolbox installieren
package-option-install-eclean = eclean installieren
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender ist der in Windows integrierte Virenschutz. Entfernen Sie ihn nur, wenn Sie die Risiken kennen und eine andere Antivirensoftware verwenden möchten. Unabhängig von Ihrer Wahl schaltet Atlas die Intelligente App-Steuerung, den Erweiterten Phishingschutz und „Mein Gerät suchen“ aus.
package-choice-mitigations-description = Diese Schutzfunktionen, auch Mitigationen genannt, helfen, Ihren PC vor Prozessorschwachstellen wie Spectre und Meltdown und vor Angriffen zu schützen, die Fehler in Apps ausnutzen. Es wird empfohlen, die Standardeinstellungen von Windows beizubehalten.
package-choice-auto-updates-description = Windows-Updates enthalten Sicherheitskorrekturen. Sie können sie von Windows automatisch installieren lassen oder selbst installieren. In beiden Fällen belässt Atlas Windows auf der aktuellen Version, die nur so lange Sicherheitskorrekturen erhält, bis Microsoft den Support dafür beendet. Atlas schaltet außerdem automatische Updates für Apps aus dem Microsoft Store aus. Aktualisieren Sie diese Apps daher im Microsoft Store.
package-choice-browser-description = Wählen Sie einen Browser, der installiert werden soll. Atlas ändert Ihre Browsereinstellungen nicht.

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender ist auf diesem PC nicht installiert
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Es gibt keine Schutzschalter zum Ausschalten.
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender.
security-banner-removed-title = Atlas hat Microsoft Defender von diesem PC entfernt
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas stellt Microsoft Defender bei dieser Installation wieder her
security-restore-nothing-to-turn-off = Defender läuft noch nicht, daher gibt es nichts auszuschalten. Schalten Sie nach dem Neustart seinen Schutz in der Windows-Sicherheit ein.
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it.
security-banner-missing-title = Microsoft Defender fehlt
security-banner-missing-message = Atlas hat ihn nicht entfernt und kann ihn daher nicht wiederherstellen. Sie können fortfahren, aber Ihr PC hat keinen Virenschutz, bis Sie eine andere Antivirensoftware installieren oder Windows reparieren.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches.
security-turn-off-title = Schalten Sie diese vier Schalter aus
security-turn-off-message = Microsoft Defender kann Atlas bei der Installation blockieren. Wenn Sie Defender behalten, schalten Sie die Schalter nach der Installation wieder ein.
# The page name in Windows Security.
security-list-title = Einstellungen für Viren- & Bedrohungsschutz
security-switch-off = Aus
security-switch-on = Ein
security-switch-unreadable = Lesen fehlgeschlagen
security-switch-reading = Wird geprüft
security-all-off = Alle aus
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 noch eingeschaltet und 1 konnte nicht gelesen werden".
security-count-still-on = { $count } noch eingeschaltet
security-count-unreadable =
    { $count ->
        [one] { $count } konnte nicht gelesen werden
       *[other] { $count } konnten nicht gelesen werden
    }
security-count-join = { $a } und { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# joined with list-and; $count is how many there are.
security-unread-switches-title =
    { $count ->
        [one] Atlas konnte diesen Schalter nicht lesen: { $switches }
       *[other] Atlas konnte diese Schalter nicht lesen: { $switches }
    }
security-unread-message =
    { $count ->
        [one] Stellen Sie sicher, dass dieser Schalter in der Windows-Sicherheit ausgeschaltet ist.
       *[other] Stellen Sie sicher, dass diese Schalter in der Windows-Sicherheit ausgeschaltet sind.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] Ich habe geprüft, dass { $switches } ausgeschaltet ist
       *[other] Ich habe geprüft, dass { $switches } ausgeschaltet sind
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Ich habe in der Windows-Sicherheit nachgesehen und alle vier Schalter sind aus
security-unknown-unelevated-title = Atlas benötigt eine Berechtigung, um den Schutz zu prüfen
security-unknown-unelevated-message = Führen Sie Atlas als Administrator aus, damit es die Einstellungen von Microsoft Defender lesen kann.
# The four switches, named as the German Windows Security app names them, each with why it must be off.
protection-tamper = Manipulationsschutz
protection-tamper-why = Damit Atlas Sicherheitseinstellungen ändern kann.
protection-realtime = Echtzeitschutz
protection-realtime-reason = Scans können die Dateien von Atlas blockieren.
protection-cloud = Cloudbasierter Schutz
protection-cloud-reason = Onlineprüfungen können die Dateien von Atlas blockieren.
protection-samples = Automatische Übermittlung von Beispielen
protection-samples-why = Damit die Dateien von Atlas nicht an Microsoft gesendet werden.

## Step 4: Install

outcome-succeeded-title = Atlas ist installiert
outcome-lost-title = Installationsergebnis konnte nicht bestätigt werden
outcome-failed-title = Installation nicht abgeschlossen
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. It never names the bar's button.
# Beside go-to-ready.
result-requirements = Ihr PC hat die Installationsvoraussetzungen nicht erfüllt, daher hat die Installation nichts geändert.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Ihr PC hat die Installationsvoraussetzungen nicht erfüllt, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits Änderungen vorgenommen.
# Beside common-restart-as-administrator.
result-not-elevated = Atlas hatte keine Administratorrechte, daher hat die Installation nichts geändert.
result-not-elevated-resumed = Atlas hatte keine Administratorrechte, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits Änderungen vorgenommen.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready.
result-preparation-stale = Atlas konnte nicht bestätigen, dass Windows und die Store-Apps auf dem neuesten Stand sind, daher wurde die Installation abgebrochen, bevor Windows geändert wurde.
result-preparation-stale-resumed = Atlas konnte nicht bestätigen, dass Windows und die Store-Apps auf dem neuesten Stand sind, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits Änderungen vorgenommen.
result-failed-preflight = Die Installation wurde abgebrochen, bevor etwas geändert wurde. Sie können es erneut versuchen.
result-failed-staging = Die Installation wurde beim Vorbereiten der Dateien abgebrochen, bevor Windows geändert wurde. Sie können es erneut versuchen.
# Beside common-open-windows-security. The "Schutzschalter" are the four the user turned off.
result-failed-applying = Einige Änderungen wurden möglicherweise bereits vorgenommen. Sie können es erneut versuchen oder, wenn Sie hier aufhören, die Schutzschalter in der Windows-Sicherheit wieder einschalten.
# The -defender-removed variants once Microsoft Defender has been removed.
result-failed-applying-defender-removed = Einige Änderungen wurden möglicherweise bereits vorgenommen. Sie können es erneut versuchen.
result-failed-resumed = Dieser Versuch wurde vorzeitig abgebrochen, aber ein früherer Versuch hat bereits Änderungen vorgenommen. Sie können es erneut versuchen oder, wenn Sie hier aufhören, die Schutzschalter in der Windows-Sicherheit wieder einschalten.
result-failed-resumed-defender-removed = Dieser Versuch wurde vorzeitig abgebrochen, aber ein früherer Versuch hat bereits Änderungen vorgenommen. Sie können es erneut versuchen.
# The -repeated variants follow a retry that stopped with the same error as the attempt before
# it. "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = Dieser Versuch wurde mit demselben Fehler abgebrochen wie der vorherige, ein weiterer Versuch hilft daher wahrscheinlich nicht. Senden Sie einen Bericht, damit das Atlas-Team die Ursache finden kann, und schalten Sie die Schutzschalter wieder ein, wenn Sie hier aufhören.
result-failed-repeated-defender-removed = Dieser Versuch wurde mit demselben Fehler abgebrochen wie der vorherige, ein weiterer Versuch hilft daher wahrscheinlich nicht. Senden Sie einen Bericht, damit das Atlas-Team die Ursache finden kann.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows hat { $apps } weiterhin nicht entfernt, ein weiterer Versuch hilft daher wahrscheinlich nicht. Senden Sie einen Bericht, damit das Atlas-Team die Ursache finden kann, und schalten Sie die Schutzschalter wieder ein, wenn Sie hier aufhören.
result-failed-repeated-apps-defender-removed = Windows hat { $apps } weiterhin nicht entfernt, ein weiterer Versuch hilft daher wahrscheinlich nicht. Senden Sie einen Bericht, damit das Atlas-Team die Ursache finden kann.
result-not-started = Das Installationsprogramm ist nicht rechtzeitig gestartet, daher hat die Installation nichts geändert. Sie können es erneut versuchen.
result-lost = Das Installationsprogramm wurde beendet, ohne ein Ergebnis zu melden, daher wurden möglicherweise schon Änderungen vorgenommen. Sie können es erneut versuchen oder, wenn Sie hier aufhören, die Schutzschalter in der Windows-Sicherheit wieder einschalten.
# Instead of result-lost once Defender is gone.
result-lost-defender-removed = Das Installationsprogramm wurde beendet, ohne ein Ergebnis zu melden, daher wurden möglicherweise schon Änderungen vorgenommen. Sie können es erneut versuchen.
restart-now-message = Windows wird neu gestartet, um die Einrichtung von Atlas abzuschließen.
restart-stopped = Automatischer Neustart abgebrochen. Speichern Sie Ihre Arbeit und starten Sie dann Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
restart-needed = Speichern Sie Ihre Arbeit und starten Sie dann Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
restart-dont-now = Später neu starten
restart-now = Jetzt neu starten
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix.
preflight-title = Installation wurde nicht gestartet
# Beside go-to-options. $choice is a screen-*-name message, after a colon.
preflight-choice-unanswered = Atlas benötigt Ihre Antwort zu diesem Punkt: { $choice }.
preflight-choices-unusable = Atlas konnte diese Auswahl nicht verwenden.
# Beside go-to-ready. $checks lists check-* names, joined with list-and; $count is how many.
preflight-checks-changed =
    { $count ->
        [one] Seit der Prüfung Ihres PCs erfordert { $checks } Aufmerksamkeit.
       *[other] Seit der Prüfung Ihres PCs erfordern { $checks } Aufmerksamkeit.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 noch eingeschaltet".
preflight-security-changed = Die Windows-Sicherheit hat sich geändert, seit Sie die Schalter ausgeschaltet haben: { $summary }.
preflight-busy-wait = Ein anderes Atlas-Fenster startet gerade eine Installation. Warten Sie einen Moment und versuchen Sie es dann erneut.
# Beside home-start-over.
preflight-taken-over-start-over = Ein anderes Atlas-Fenster verwendet jetzt diese Einrichtung. Fahren Sie dort fort oder beginnen Sie hier von vorn.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas konnte nicht prüfen, ob eine frühere Installation noch läuft, und hat deshalb keine weitere gestartet.
preflight-not-started = Atlas konnte das Installationsprogramm nicht starten, daher hat die Installation nichts geändert. Sie können es erneut versuchen.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas konnte das Installationsprogramm nicht starten, aber ein früherer Versuch hat bereits Änderungen vorgenommen. Sie können es erneut versuchen.
go-to-ready = Zu „Vorbereiten“ wechseln
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Zu „Ihre Auswahl“ wechseln
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Zu „Windows-Sicherheit“ wechseln
# Replaces Weiter on a choice opened from a Change link on the Install step.
go-to-install = Zurück zu „Installieren“
output-problem-title = Installationsfortschritt konnte nicht gelesen werden
install-elevate-title = Atlas benötigt eine Berechtigung für die Installation
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Wenn Atlas als Administrator ausgeführt wird, fragt Windows nach Ihrer Erlaubnis.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Das Atlas-Paket ist nicht bereit
# Step 4 when step 1 is incomplete for this session, with go-to-ready as the button.
install-not-ready-title = Schließen Sie zuerst „Vorbereiten“ ab
install-not-ready-message = Atlas muss die Prüfung Ihres PCs und die Windows-Updates abschließen, bevor es installieren kann.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 noch eingeschaltet".
install-switches-title = Schalten Sie die Schutzschalter erneut aus
install-switches-message = Windows-Sicherheit: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Bereit zur Installation
summary-setup-title = Ihre Atlas-Einrichtung
summary-activation = Aktivierung
summary-activation-ok = Aktiviert. Atlas ändert daran nichts.
summary-activation-missing = Nicht aktiviert. Sie können fortfahren, aber Atlas aktiviert Windows nicht.
summary-activation-unknown = Atlas ändert den Aktivierungsstatus von Windows nicht.
# How long installing usually takes: the first while the box below it is ticked, the second
# while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Meist etwa { $minutes } Minute, danach wird Ihr PC neu gestartet
       *[other] Meist etwa { $minutes } Minuten, danach wird Ihr PC neu gestartet
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Meist etwa { $minutes } Minute, danach starten Sie Ihren PC neu
       *[other] Meist etwa { $minutes } Minuten, danach starten Sie Ihren PC neu
    }
# The check box on the card. It's the same setting as settings-restart-automatically.
summary-restart-automatically = Nach Abschluss der Installation automatisch neu starten
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Ebenfalls ausgeschaltet
summary-turned-off-value = Intelligente App-Steuerung, Erweiterter Phishingschutz und „Mein Gerät suchen“
summary-show-command = Installationsbefehl anzeigen
summary-hide-command = Installationsbefehl ausblenden
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Installationsbefehl kopieren
summary-command-unavailable = Der Installationsbefehl konnte nicht erstellt werden. Details: { $error }
summary-not-chosen = Noch nicht gewählt
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = { $title } ändern
# The summary's first row on an update or reinstall.
summary-update-path = Art des Updates
# Why Continue waits on Get ready. 8 words or fewer.
footer-still-checking = Installation wird vorbereitet
footer-checks-blocked = Beheben Sie die gefundenen Probleme, um fortzufahren
footer-manager-outdated = Laden Sie einen neueren Atlas Manager herunter, um fortzufahren
footer-need-files = Zum Fortfahren wird das Atlas-Paket benötigt
# Tester build variant of footer-need-files.
footer-need-package-bundled = Bereiten Sie das mitgelieferte Atlas-Paket vor, um fortzufahren
footer-drivers = Wählen Sie die Treiberinstallation, um fortzufahren
footer-windows-terms = Akzeptieren Sie die Lizenzbedingungen, um fortzufahren
footer-updating = Windows und Store-Apps werden aktualisiert…
footer-restart = Starten Sie Ihren PC neu, um fortzufahren
footer-reading-security = Schutzschalter werden geprüft
# Why Continue waits on Windows Security.
footer-security-pending = Stellen Sie alle vier Schalter auf „Aus“, um fortzufahren
footer-security-confirm = Bestätigen Sie die Schalter, die Atlas nicht lesen konnte, um fortzufahren
# Beside Install Atlas while automatic restart is on.
footer-install-ready = Speichern Sie zuerst Ihre Arbeit und schließen Sie Ihre Apps
button-install = Atlas installieren
log-earlier-lines =
    { $count ->
        [one] { $count } frühere Zeile steht in der Protokolldatei.
       *[other] { $count } frühere Zeilen stehen in der Protokolldatei.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (vollständiges Protokoll: { $path })

## The installing view

installing-title = Atlas wird installiert
# What Atlas is doing, under installing-title and as the progress bar's accessible name.
installing-checking-label = Ihr PC wird geprüft…
installing-staging-label = Dateien von Atlas werden kopiert…
installing-applying-label = Windows wird eingerichtet…
installing-finishing-label = Wird abgeschlossen…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Lassen Sie Ihren PC eingeschaltet und am Stromnetz. Er wird nach Abschluss der Installation automatisch neu gestartet.
installing-keep-on = Lassen Sie Ihren PC eingeschaltet und am Stromnetz. Starten Sie ihn nach Abschluss der Installation neu.
# When Atlas can't follow the installer's log. Its title is output-problem-title.
installing-output-problem = Das bedeutet nicht, dass die Installation abgebrochen wurde.
installing-installed-title = Atlas ist installiert
# Under installing-installed-title while the restart counts down.
installing-restart-countdown =
    { $seconds ->
        [one] Ihr PC wird in { $seconds } Sekunde neu gestartet.
       *[other] Ihr PC wird in { $seconds } Sekunden neu gestartet.
    }
installing-restart-save = Speichern Sie zuerst Ihre Arbeit.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } ist installiert
installed-title = Atlas ist installiert
installed-ready = Alles erledigt. Ihr PC ist mit Atlas einsatzbereit.
# A line under the setup card where the user installs drivers themselves.
installed-manual-drivers-detail = Beziehen Sie Chipsatz-, Netzwerk- und Grafiktreiber vom Hersteller Ihres PCs, Mainboards oder Geräts.
installed-drivers-guide = Treiberanleitung öffnen
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender wurde entfernt
# After an installation that kept Microsoft Defender, when it is missing and no Atlas package
# removed it. Its title is security-banner-missing-title.
defender-missing-message = Atlas hat ihn nicht entfernt. Wenn Sie keine andere Antivirensoftware verwenden, installieren Sie eine, um Ihren PC zu schützen.
# When Atlas's record kept Microsoft Defender but Atlas's own package still removes it.
# 7. Security, Defender and Toggle Defender are names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender ist weiterhin entfernt
defender-not-restored-message = Ein früheres Atlas-Update hat ihn nicht wiederhergestellt, daher schützt Defender Ihren PC nicht. Installieren Sie Atlas neu und behalten Sie Defender, oder führen Sie im Atlas-Ordner unter „7. Security“ > „Defender“ „Toggle Defender“ aus.
# When what the installation recorded for some choices isn't what was chosen. $choices lists
# their names, joined with list-and.
installed-not-applied-title = Ein Teil Ihrer Auswahl wurde nicht übernommen
# $choices lists screen-*-name messages, joined with list-and, after a colon; $count is how
# many it names.
installed-not-applied-choices =
    { $count ->
        [one] Dieser Punkt ist unverändert geblieben: { $choices }.
       *[other] Diese Punkte sind unverändert geblieben: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again.
installed-update-off-title = Windows Update ist wie gewählt wieder ausgeschaltet
installed-update-off-message = Solange es ausgeschaltet ist, erhält Ihr PC keine Sicherheitsupdates.
installed-update-paused-title = Windows-Updates sind wie gewählt wieder ausgesetzt
installed-update-paused-message = Solange sie ausgesetzt sind, erhält Ihr PC keine Sicherheitsupdates.

## Settings

settings-title = Einstellungen
# Headings of the page's sections.
settings-appearance = Darstellung
settings-installation = Installation
settings-privacy = Datenschutz
settings-theme = App-Design
settings-theme-system = Wie Windows
settings-theme-light = Hell
settings-theme-dark = Dunkel
settings-theme-contrast-note = Atlas verwendet die Farben Ihres Windows-Kontrastdesigns.
settings-language = Sprache
# The setting in the Language section, and its box's name.
settings-app-language = App-Sprache
# The first choice in the language box. $language is that language's own name.
settings-language-match-windows = Wie Windows – { $language }

# A short tag after each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Vorschau
# Under the language box while the language in use is a preview translation.
settings-language-preview-in-use = Diese Übersetzung wurde noch nicht muttersprachlich geprüft.
# A bar at the top of the content while a preview translation is in use.
preview-notice = { $language } ist eine Vorschau-Übersetzung und kann Fehler enthalten.
preview-notice-switch = Zu Englisch wechseln
preview-notice-language = Sprache ändern
# Under the language box when the language chosen isn't in this version.
settings-language-chosen-unavailable = Die gewählte Sprache ist in dieser Version von Atlas nicht enthalten, daher zeigt Atlas Englisch an. Ihre Auswahl bleibt gespeichert.
# While Match Windows is chosen and Atlas has none of the Windows display languages.
settings-language-windows-unsupported = Atlas unterstützt Ihre Windows-Anzeigesprache noch nicht und zeigt daher Englisch an.
# While Match Windows is chosen and the Windows display languages couldn't be read.
settings-language-windows-unreadable = Atlas konnte Ihre Windows-Anzeigesprache nicht ermitteln und zeigt daher Englisch an.
# $locale is the regional format's own name, for example "Deutsch (Deutschland)".
settings-language-formats = Zahlen, Datum und Uhrzeit richten sich nach Ihrem regionalen Format in Windows: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Zahlen richten sich nach Ihrem regionalen Format in Windows: { $locale }. Datum und Uhrzeit werden in einem Standardformat angezeigt, da Atlas noch keinen Text von rechts nach links darstellen kann.
settings-language-contribute = Beim Übersetzen von Atlas helfen
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Nutzungsdaten mit Atlas teilen
settings-share-usage-description = Geöffnete Seiten, ISO-Erstellungen und Installationsergebnisse.
settings-privacy-policy = Datenschutzrichtlinie
# Covers the restart after installing and the restart that Windows and Store updates need.
settings-restart-automatically = Nach Installation und Updates automatisch neu starten
settings-restart-automatically-description = Ihr PC wird innerhalb einer Minute nach Abschluss neu gestartet, geöffnete Apps werden dabei geschlossen.
settings-restart-locked = Sie können das ändern, sobald die Installation abgeschlossen ist.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Hilfe
settings-about = Info
settings-about-app = Atlas Manager
settings-about-licence = Lizenz
settings-about-licence-value = GPL-3.0, kostenlos und Open Source
settings-view-source = Quellcode ansehen
# Link that opens the third-party licence notices.
settings-view-licences = Lizenzhinweise anzeigen
# Under the links when Windows could not open the notices.
settings-licences-failed = Die Lizenzhinweise konnten nicht geöffnet werden. Versuchen Sie es erneut oder sehen Sie sie im Quellcode auf GitHub nach.
settings-open-data-folder = App-Ordner öffnen

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Gibt den Speicherplatz frei, in dem Ihre Sitzung im Ruhezustand gespeichert wird. Ruhezustand und Schnellstart stehen dann nicht mehr zur Verfügung.
consequence-disable-power-saving = Schaltet Energiesparfunktionen aus. Ihr PC verbraucht dann möglicherweise mehr Strom, wird wärmer und hält im Akkubetrieb kürzer durch.
consequence-disable-core-isolation = Schaltet eine zusätzliche Sicherheitsebene von Windows aus, einschließlich der Speicherintegrität. Das verringert den Schutz, und Spiele mit Anti-Cheat-Systemen wie Riot Vanguard oder FACEIT starten möglicherweise erst, wenn Sie die Speicherintegrität wieder einschalten.
consequence-remove-snipping-tool = Entfernt die Windows-App für Screenshots und Bildschirmaufnahmen.
consequence-uninstall-edge = Entfernt den Browser Microsoft Edge. Stellen Sie sicher, dass Sie einen anderen Browser haben, oder wählen Sie unten einen aus.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Löscht Ihre Favoriten, Ihren Verlauf und Ihre gespeicherten Kennwörter in Edge auf diesem PC.
consequence-install-another-browser = Wählen Sie unten einen Browser aus; Atlas installiert ihn für Sie.
consequence-install-toolbox = Mit Atlas Toolbox verwalten Sie Ihre Atlas-Einstellungen. Toolbox ist in der Betaphase, einige Funktionen sind daher möglicherweise noch nicht fertig.
consequence-install-eclean = Ein Wartungstool vom Team hinter AtlasOS, mit dem Sie Ihren PC nach der Einrichtung aufräumen können. Prüfen Sie überflüssige Dateien und Autostart-Apps. Erfordert ein Konto und eine Internetverbindung.

## ISO creation
iso-open = Atlas-ISO erstellen
iso-title = Atlas-ISO erstellen
iso-recommended = Empfohlen
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Einrichtung
iso-step-create = Erstellen
# The first question on the Windows step.
iso-target-title = Für welchen PC ist diese ISO?
iso-target-this = Dieser PC
iso-target-another = Ein anderer PC
# When the ISO is for another kind of processor than this PC's. $architecture is
# iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = Diese ISO ist für { $architecture }-PCs.
iso-source = Windows-ISO
# Starts the Windows 11 download at once, in the language and architecture of iso-download-caption.
iso-download-windows = Von Microsoft herunterladen
# What the download gets. $language is Microsoft's own name for the language, in English;
# $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download for the accessible name of its Change link.
iso-download-what = Windows-Download
iso-download-language = Sprache
iso-download-arch = Architektur
iso-download-languages = Sprachen werden geladen…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2,4 GB" (size-gigabytes).
iso-downloading = Windows 11 wird heruntergeladen…
iso-download-amount = { $received } von { $total }
# Try again (common-try-again) is beside these.
iso-download-unreachable = Atlas konnte den Downloaddienst von Microsoft nicht erreichen. Prüfen Sie Ihre Internetverbindung und versuchen Sie es dann erneut.
iso-download-incomplete = Der Download wurde nicht abgeschlossen. Prüfen Sie Ihre Internetverbindung und den freien Speicherplatz und versuchen Sie es dann erneut.
iso-download-website = Downloadseite von Microsoft öffnen
# Opens the file picker for a Windows ISO, and is that picker's Open button.
iso-use-local = ISO-Datei auswählen
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Ihre Windows-ISO wird geprüft…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6,6 GB".
iso-checked-a11y = Windows-ISO bereit, { $facts }
iso-package-latest-label = Aktuell
# The latest Atlas release is older than this Atlas Manager can use; package-open-file is under it.
iso-package-release-old = Die neueste Atlas-Version ist älter, als dieser Atlas Manager verwenden kann.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Neueste Atlas-Version wird abgerufen…
# The release check failed; Try again is beside it.
iso-package-release-failed = Atlas konnte nicht nach der neuesten Version suchen. Prüfen Sie Ihre Internetverbindung und versuchen Sie es dann erneut.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Zum Fortfahren wird eine Windows-ISO benötigt
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Wann möchten Sie Ihre Atlas-Auswahl treffen?
iso-mode-after = Nach der Anmeldung
iso-mode-after-description = Atlas führt Sie nach der Anmeldung durch die Einrichtung.
iso-mode-now = Jetzt
iso-mode-now-description = Wird in der ISO gespeichert. Atlas installieren Sie nach der Anmeldung.
# A check box under Now.
iso-mode-before-desktop = Vor dem Öffnen des Desktops abschließen
iso-mode-before-desktop-description = Nach der Anmeldung läuft Atlas im Vollbildmodus, bis es installiert ist.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Dieses Atlas-Paket kann keine Auswahl in der ISO speichern, daher treffen Sie sie nach der Anmeldung.
iso-atlas-options = Atlas-Auswahl
# The line at the top of the Create step.
iso-create-intro = Das Erstellen der ISO ändert weder diesen PC noch Ihre ursprüngliche ISO.
iso-review-package = Atlas-Paket
iso-review-output = Neue ISO
iso-review-edition = Edition
iso-review-editions = Editionen
iso-edition = Windows-Edition
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Windows-Setup fragt nach
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Windows-Setup fragt nach
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Windows-Lizenzbedingungen akzeptieren, damit Windows-Setup nicht danach fragt
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Kontoname
iso-review-target = Ziel-PC
iso-review-drivers = Treiber
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows-Setup
iso-review-skips = Überspringt die Seiten für Microsoft-Konto und Datenschutz
iso-review-skips-terms = Überspringt die Seiten für Lizenz, Microsoft-Konto und Datenschutz
iso-review-network = Netzwerktreiber
iso-review-network-included = WLAN- und Ethernet-Treiber dieses PCs
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Jetzt, vor dem Öffnen des Desktops abgeschlossen
# Under the new ISO on the Create step. $needed and $free are sizes such as "35,0 GB";
# $drive is a drive such as "C:".
iso-destination-space = Benötigt { $needed } · { $free } frei auf { $drive }
iso-destination-short = Die ISO benötigt { $needed }, auf { $drive } sind { $free } frei. Geben Sie Speicherplatz frei oder speichern Sie die ISO auf einem anderen Laufwerk.
iso-destination-filesystem = { $drive } kann die großen Dateien der ISO nicht aufnehmen. Speichern Sie sie auf einem mit NTFS formatierten Laufwerk, etwa Ihrem Windows-Laufwerk.
iso-destination-unusable = Atlas kann die ISO nur in einem Ordner auf einem Laufwerk dieses PCs speichern.
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = Die Dateien der ISO bräuchten im Zielordner längere Pfade, als Windows zulässt. Speichern Sie die neue ISO in einem Ordner mit kürzerem Pfad, etwa auf Ihrem Windows-Laufwerk.
iso-create = ISO erstellen
# Heading above the progress bar and the list of stages while the ISO is being created.
iso-progress-title = Ihre ISO wird erstellt…
# The progress bar's label: the stage under way. $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Windows-ISO wird gelesen
iso-stage-copy = Windows-Dateien werden kopiert
iso-stage-add-atlas = Atlas wird hinzugefügt
iso-stage-master = ISO-Datei wird geschrieben
iso-stage-verify = Neue ISO wird geprüft
iso-stage-cleanup = Wird abgeschlossen
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = läuft
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = fehlgeschlagen
iso-stage-status-not-started = noch nicht gestartet
iso-progress-keep-open = Lassen Sie Atlas geöffnet, bis der Vorgang abgeschlossen ist.
iso-cancel = Erstellung abbrechen
iso-cancelling = Warten auf einen sicheren Abbruchpunkt
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Wird abgebrochen…
iso-cancelled = ISO-Erstellung abgebrochen
iso-cancelled-unchanged = Ihre ursprüngliche ISO wurde nicht geändert.
iso-complete = Ihre ISO ist fertig
iso-complete-backup = Sichern Sie Ihre Dateien, bevor Sie Windows damit neu installieren.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = USB-Laufwerk erstellen
iso-open-folder = Im Ordner anzeigen
iso-failed = ISO-Erstellung konnte nicht abgeschlossen werden
# Under iso-failed, beside Try again.
iso-failed-retry = Stellen Sie sicher, dass Ihre Dateien noch am gewählten Ort liegen und das Ziellaufwerk angeschlossen ist, und versuchen Sie es dann erneut.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Dateien konnten nicht geprüft werden
iso-check-failed-retry = Stellen Sie sicher, dass die ISO und das Atlas-Paket vollständig heruntergeladen sind, und versuchen Sie es dann erneut.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas konnte seinen Arbeitsordner nicht vorbereiten, daher wurde nichts geändert.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix.
iso-edition-unsupported-title = Diese ISO enthält keine von Atlas unterstützte Edition
iso-edition-unsupported = Windows Home und LTSC werden nicht unterstützt. Verwenden Sie eine ISO mit Pro, Education oder Enterprise.
iso-customised-title = Diese ISO wurde angepasst
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = Diese ISO wurde mit Atlas erstellt
iso-customised = Sie enthält bereits Setup-Dateien wie autounattend.xml. Verwenden Sie eine unveränderte ISO von Microsoft.
iso-preview-title = Diese ISO enthält einen Vorschau-Build
iso-preview = Ihr Windows-Build steht nicht in Microsofts Liste der regulär veröffentlichten Versionen. Verwenden Sie eine ISO von Microsoft.
iso-windows-unsupported-title = Dieses Atlas-Paket kann diese ISO nicht verwenden
iso-windows-unsupported = Verwenden Sie eine unveränderte Windows-11-ISO einer Version, die das Paket unterstützt.
iso-release-unknown-title = Atlas konnte diese Windows-Version nicht bestätigen
iso-release-unconfirmed = Atlas gleicht sie mit Microsofts Liste der regulär veröffentlichten Versionen ab. Prüfen Sie Ihre Internetverbindung und versuchen Sie es dann erneut.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Mit diesem Atlas-Paket kann keine ISO erstellt werden
iso-package-old = Verwenden Sie Atlas { $minimum } oder neuer.
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = Das ist eine Windows-ISO, kein Atlas-Paket
iso-package-windows-iso = Wählen Sie stattdessen ein Atlas-Paket (.atlaspkg) und diese ISO als Windows-ISO aus.
iso-manager-missing-title = Die Datei von Atlas Manager fehlt
iso-fix-package = Anderes Paket auswählen
# A package that needs a newer Atlas Manager; manager-download is beside it.
iso-manager-outdated-title = Atlas Manager muss aktualisiert werden
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas konnte die Netzwerktreiber dieses PCs nicht zur ISO hinzufügen.
iso-network-skip = Ohne sie erstellen
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas benötigt eine Berechtigung zum Erstellen einer ISO
iso-admin-reason = Atlas braucht sie, um Ihre Windows-ISO zu lesen und die neue zu erstellen.
iso-elevation-declined = Windows hat Atlas keine Berechtigung erteilt, daher kann Atlas Ihre Windows-ISO noch nicht lesen.
# The free space ran out while the ISO was being created.
iso-failed-space = Auf dem Ziellaufwerk ist nicht genügend freier Speicherplatz vorhanden. Geben Sie Speicherplatz frei oder speichern Sie die neue ISO auf einem anderen Laufwerk.
# Under iso-manager-missing-title.
iso-manager-missing = Laden Sie AtlasManager.exe in einen lokalen Ordner wie „Downloads“ herunter und öffnen Sie die Datei von dort.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Diese ISO enthält keine unterstützten Windows-Editionen. Windows Home und LTSC werden nicht unterstützt. Verwenden Sie eine ISO mit einer anderen Edition, etwa Pro, Education oder Enterprise.
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows konnte die ISO nicht öffnen. Starten Sie Ihren PC neu und versuchen Sie es dann erneut.
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows hat beim Öffnen der ISO nicht mehr reagiert. Starten Sie Ihren PC neu und versuchen Sie es dann erneut.
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows kann auf diesem PC keine ISO-Dateien öffnen, weil die dafür nötigen Treiber vdrvroot und cdrom deaktiviert sind. Aktivieren Sie sie wieder, starten Sie Ihren PC neu und versuchen Sie es dann erneut.
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows kann diese ISO nicht öffnen, weil die Datei komprimiert, verschlüsselt oder als Sparse-Datei gespeichert ist. Kopieren Sie sie in einen Ordner, der weder komprimiert noch verschlüsselt ist, und verwenden Sie die Kopie.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Protokollordner öffnen
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas ist gerade mit Windows Update beschäftigt. Sobald das abgeschlossen ist, können Sie hier fortfahren.
# Names of the markers Windows sets when it wants a restart. They complete
# "Windows muss neu gestartet werden, um frühere Änderungen abzuschließen (…)"; keep them short.
prepare-reason-servicing = Windows-Wartung
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = noch zu ersetzende Dateien
prepare-reason-update-agent = der Windows Update-Dienst
prepare-reason-unknown = Grund nicht gemeldet
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Wenn ein erneuter Versuch nicht hilft, schließen Sie die restlichen Updates in Windows Update oder im Microsoft Store ab.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Einige Updates konnten nicht abgeschlossen werden
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Die Aktualisierung wurde beendet, bevor ein Ergebnis gemeldet wurde.
prepare-unconfirmed-title = Update-Ergebnis konnte nicht bestätigt werden
prepare-affected-app = die betroffene App
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Schließen Sie { $app } und versuchen Sie es dann erneut. Wenn Sie die App nicht finden, beenden Sie sie im Task-Manager.
prepare-install-busy = Eine andere Installation oder ein erforderlicher Neustart blockiert Updates. Warten Sie, bis andere Installationen abgeschlossen sind, starten Sie Ihren PC neu, wenn Windows Sie dazu auffordert, und versuchen Sie es dann erneut.
# Updates failed after Atlas's own repair of the component store (DISM). The button is
# prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows konnte sich nicht selbst reparieren
prepare-components-damaged = Windows meldet Schäden, die die Installation von Updates verhindern. Ein Neustart kann sie beheben, und Atlas fährt nach der Anmeldung fort.
prepare-restart-and-retry = Neu starten und erneut versuchen
# Windows records damage to its component store that it can't repair. The one button is iso-open.
prepare-components-unrepairable-title = Windows ist für Updates zu stark beschädigt
prepare-components-unrepairable = Sichern Sie Ihre Dateien und installieren Sie Windows dann mit einer Atlas-ISO neu.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas läuft unter einem anderen Konto als dem, das bei Windows angemeldet ist. Melden Sie sich mit einem Administratorkonto bei Windows an, öffnen Sie Atlas unter diesem Konto und versuchen Sie es dann erneut.
prepare-failed-store-missing = Der Microsoft Store ist für Ihr Konto nicht eingerichtet. Öffnen Sie den Microsoft Store einmal oder installieren Sie ihn neu, falls er fehlt. Versuchen Sie es dann erneut.
prepare-failed-store-battery = Der Microsoft Store hat Updates angehalten, um Akku zu sparen. Schließen Sie Ihren PC ans Stromnetz an und versuchen Sie es dann erneut.
prepare-failed-store-network = Der Microsoft Store hat Updates angehalten, bis Ihr PC eine nicht getaktete Verbindung hat. Verbinden Sie sich über ein nicht getaktetes WLAN oder Ethernet und versuchen Sie es dann erneut.
prepare-failed-store-timeout = Die Store-Apps wurden noch nicht fertig aktualisiert. Schließen Sie die restlichen Downloads im Microsoft Store ab und versuchen Sie es dann erneut.
prepare-failed-store-passes = Der Microsoft Store hat immer wieder neue Updates angeboten. Schließen Sie die restlichen Updates im Microsoft Store ab und versuchen Sie es dann erneut.
prepare-failed-manual-updates = Einige Windows-Updates müssen in Windows Update abgeschlossen werden. Öffnen Sie Windows Update, schließen Sie die Updates dort ab und versuchen Sie es dann erneut.
prepare-failed-windows-passes = Windows Update hat immer wieder neue Updates angeboten. Schließen Sie die restlichen Updates in Windows Update ab und versuchen Sie es dann erneut.
prepare-failed-windows-update-unreachable = Windows Update konnte die Server von Microsoft nicht erreichen. Prüfen Sie Ihre Internetverbindung sowie eine Firewall, einen Proxy oder ein VPN und versuchen Sie es dann erneut.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic link).
prepare-failed-source-linked = Der Atlas Manager befindet sich in einem verknüpften Ordner. Schließen Sie Atlas, verschieben Sie den Atlas Manager in einen lokalen Ordner auf diesem PC und öffnen Sie ihn dann von dort aus.
prepare-error-code = Fehlercode: { $code }
prepare-open-store = Microsoft Store öffnen
prepare-windows-search = Windows Update wird geprüft…
prepare-percent = { $percent } % dieser Phase
prepare-count = Abgeschlossene Updates: { $completed } von { $total }
prepare-bytes = { $downloaded } von ungefähr { $total } MB heruntergeladen
prepare-progress-still = Seit { $minutes } Min. kein Fortschritt. Große Updates können eine Weile dauern, lassen Sie Atlas also geöffnet.
prepare-report-late = Windows hat seit einer Weile keinen Fortschritt gemeldet. Möglicherweise laufen noch Updates, lassen Sie Atlas also geöffnet.
prepare-windows-download = Windows-Updates werden heruntergeladen…
prepare-windows-install = Windows-Updates werden installiert…
# While DISM repairs Windows' component store, with prepare-windows-repair-detail under the
# progress bar. DISM reports no progress.
prepare-windows-repairing = Windows wird repariert…
prepare-windows-repair-detail = Windows meldet Schäden, die die Installation von Updates verhindern können. Das kann eine halbe Stunde oder länger dauern.
prepare-store-search = Microsoft Store wird geprüft…
prepare-store-install = Microsoft Store und seine Apps werden aktualisiert…
prepare-stop = Updates anhalten
prepare-start = Updates suchen und installieren
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Verfügbar, sobald das Atlas-Paket bereit ist.
iso-username = Name des lokalen Kontos
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Das Kennwort legen Sie bei der ersten Anmeldung fest.
iso-username-placeholder = Ihr Name
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Geben Sie einen Namen für das lokale Konto ein, um fortzufahren
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Verwenden Sie bis zu 20 Zeichen, ohne Leerzeichen am Anfang oder Ende und ohne diese Zeichen: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Der Name darf nicht mit einem Punkt enden.
iso-account-reserved = Windows verwendet diesen Namen für ein integriertes Konto. Wählen Sie einen anderen Namen.
# When the ISO doesn't accept the licence terms for Windows Setup.
iso-terms-in-setup = Windows-Setup fordert Sie auf, die Lizenzbedingungen zu akzeptieren.
prepare-drivers = Wie sollen Treiber installiert werden?
prepare-drivers-auto = Treiber über Windows Update beziehen
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Treiber über Windows Update beziehen (empfohlen)
prepare-drivers-auto-detail = Windows findet Treiber für Ihre Hardware.
prepare-drivers-manual = Treiber selbst installieren
prepare-drivers-manual-detail = Windows Update installiert keine Treiber. Sie müssen sie daher vom Hersteller Ihres PCs oder Geräts beziehen. Bereits installierte Treiber bleiben erhalten.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Treiber
iso-network-drivers = WLAN- und Ethernet-Treiber dieses PCs einbinden
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Nach der Anmeldung auswählen
prepare-network-unmetered = Für Updates ist eine nicht getaktete Internetverbindung erforderlich. Verbinden Sie sich mit einem WLAN oder über Ethernet und versuchen Sie es dann erneut.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows meldet, dass dieses Netzwerk keinen Internetzugang hat. Melden Sie sich beim Netzwerk an, falls Sie dazu aufgefordert werden, oder prüfen Sie Ihren Router sowie DNS- oder Firewall-Filter. Versuchen Sie es dann erneut.
# „Getaktete Verbindung“ is the switch's name in Windows network settings.
prepare-network-metered = Diese Verbindung ist getaktet oder hat ein Datenlimit. Verbinden Sie sich mit einem nicht getakteten Netzwerk oder schalten Sie „Getaktete Verbindung“ in den Netzwerkeinstellungen aus. Versuchen Sie es dann erneut.
prepare-network-settings = Netzwerkeinstellungen öffnen
iso-stage-network-drivers = Netzwerktreiber werden vorbereitet
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Die Netzwerkadapter dieses PCs verwenden Treiber, die in Windows enthalten sind. Die ISO muss sie daher nicht einbinden.
desktop-setup-description = Schließen Sie die Einrichtung Ihres PCs ab. Ihre Atlas-Auswahl ist gespeichert. Bei Bedarf können Sie zu Windows wechseln.
desktop-setup-exit = In Windows fortfahren

# Windows installation USB
usb-title = USB-Laufwerk erstellen
usb-existing = USB-Laufwerk aus einer vorhandenen ISO erstellen
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB-Laufwerk
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows-ISO
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = In Ihrem Ordner „Downloads“ befindet sich keine Atlas-ISO.
usb-iso-checking = ISO wird geprüft…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas kann aus dieser ISO kein USB-Laufwerk erstellen. Verwenden Sie eine mit Atlas erstellte ISO oder eine Windows-11-ISO von Microsoft in einer Version, die Atlas unterstützt.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = Die ISO oder der Atlas Manager befindet sich an einem Netzwerkspeicherort oder in einem verknüpften Ordner. Verschieben Sie die Datei in einen Ordner auf diesem PC, etwa „Downloads“.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Auf dem Windows-Laufwerk ist nicht genug Speicherplatz frei, um diese ISO vorzubereiten. Geben Sie Speicherplatz frei; Atlas prüft dann automatisch erneut.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas konnte diese ISO nicht lesen. Versuchen Sie es erneut oder verwenden Sie eine andere ISO.
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = Speichereinstellungen öffnen
usb-looking = Es wird nach USB-Laufwerken gesucht…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Schließen Sie ein USB-Laufwerk mit mindestens { $size } GB an.
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as in usb-connect.
usb-drive-too-small-needs = Zu klein. Mindestens { $size } GB erforderlich.
usb-drive-too-small-iso = Zu klein für diese ISO
usb-drive-has-iso = Ihre ISO befindet sich auf diesem Laufwerk
usb-drive-has-app = Atlas Manager wird von diesem Laufwerk ausgeführt
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = USB-Laufwerk erstellen
# Beside the unavailable Create USB drive while several drives are listed and none is picked.
usb-hint-pick = Wählen Sie zuerst ein USB-Laufwerk aus
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:".
usb-confirm-title-letters = { $drive } ({ $size }, { $letters }) löschen?
usb-confirm-title = { $drive } ({ $size }) löschen?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = USB-Laufwerk ({ $size }, { $letters }) löschen?
usb-confirm-title-unnamed = USB-Laufwerk ({ $size }) löschen?
usb-confirm-message = Der gesamte Inhalt wird gelöscht. Ihre ISO bleibt erhalten.
usb-confirm-erase = Löschen und erstellen
usb-progress-title = USB-Laufwerk wird erstellt…
# $percent is a whole number.
usb-percent = { $percent } %
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Dateien werden vorbereitet
usb-stage-formatting = Wird formatiert
usb-stage-copying = Dateien werden kopiert
usb-stage-checking = Laufwerk wird geprüft
usb-stage-ejecting = Wird ausgeworfen
usb-keep-open = Lassen Sie Atlas geöffnet und das Laufwerk angeschlossen.
usb-scan-failed-title = USB-Laufwerke konnten nicht aufgelistet werden
usb-scan-failed-retry = Atlas konnte die an diesen PC angeschlossenen Laufwerke nicht lesen. Versuchen Sie es erneut.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = USB-Laufwerk konnte nicht erstellt werden
usb-complete-title = Ihr USB-Laufwerk ist bereit
# F12, F11 and Esc are key names.
usb-ready = Ziehen Sie es ab, sichern Sie die Dateien auf dem PC, auf dem Sie Windows neu installieren, und starten Sie diesen PC dann vom USB-Laufwerk. Sein Boot-Menü öffnet sich oft mit F12, F11 oder Esc.
# After erasing may have begun.
usb-failed-partial = Das Laufwerk wurde teilweise beschrieben. Prüfen Sie, ob es angeschlossen ist, und versuchen Sie es dann erneut.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas hat abgebrochen, bevor das Laufwerk geändert wurde. Versuchen Sie es erneut.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
usb-drive-changed-title = Das USB-Laufwerk hat sich geändert
usb-drive-changed = Es wurde entfernt oder neu angeschlossen, bevor Atlas es gelöscht hat, daher wurde nichts darauf geändert.
usb-drive-cancelled-title = Erstellung des USB-Laufwerks abgebrochen
usb-cancelled-partial = Das Laufwerk ist unvollständig. Erstellen Sie es erneut, bevor Sie es verwenden.
usb-cancelled-unchanged = Ihr USB-Laufwerk wurde nicht verändert.
usb-eject-failed-title = USB-Laufwerk konnte nicht ausgeworfen werden
usb-eject-failed-ready = Es ist einsatzbereit. Schließen Sie alle Dateien und Fenster, die es verwenden, und versuchen Sie es dann erneut.
# Title of the bar with common-restart-as-administrator. Its message is usb-admin-reason,
# or usb-elevation-declined after Windows refused the relaunch (UAC declined).
usb-elevation-title = Atlas benötigt eine Berechtigung zum Erstellen eines USB-Laufwerks
usb-admin-reason = Atlas benötigt Administratorrechte, um das Laufwerk zu löschen und zu beschreiben.
usb-elevation-declined = Windows hat Atlas keine Berechtigung erteilt, daher kann Atlas das USB-Laufwerk noch nicht beschreiben.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Die Editionen Home, LTSC und Server von Windows 11 werden nicht unterstützt. Verwenden Sie eine andere Edition, etwa Pro, Education oder Enterprise. Wenn Windows Ihre Edition nicht erkennen konnte, klären Sie das, bevor Sie fortfahren.
install-source-title = Installation nicht möglich
install-source-unsupported = Atlas { $source } kann nicht direkt auf { $target } aktualisiert werden. Um diese Version zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows neu.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } kann nicht direkt aktualisiert werden. Um eine neuere Version zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows neu.
# $folder is a folder path (text).
install-source-resume-package = Eine Installation von Atlas { $target } wurde nicht abgeschlossen und kann nur mit dem Paket für Atlas { $target } abgeschlossen werden. Öffnen Sie dieses Atlas-Paket (.atlaspkg). Falls Atlas es heruntergeladen hat, finden Sie es in { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Eine Installation von Atlas { $target } wurde nicht abgeschlossen. Diese Testversion kann nur ihr mitgeliefertes Atlas-Paket installieren. Schließen Sie die Installation daher mit dem Paket für Atlas { $target } in einer regulären Version von Atlas Manager ab.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas konnte nicht feststellen, was auf diesem PC bereits installiert ist, und installiert deshalb vorerst nichts.
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = Auf diesem PC befinden sich Dateien einer früheren Atlas-Version, aber kein Nachweis einer abgeschlossenen Installation, deshalb kann sie nicht aktualisiert werden. Um Atlas zu installieren, sichern Sie Ihre Dateien und installieren Sie Windows neu.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Wählen Sie im Windows-Setup eine Edition, für die Sie eine Lizenz haben.
detail-windows-preview = Insider-Builds werden nicht unterstützt. Verwenden Sie eine regulär veröffentlichte Version von Windows 11.
detail-windows-release-unknown = Atlas konnte nicht bestätigen, dass dieser Windows-Build regulär veröffentlicht wurde. Stellen Sie eine Internetverbindung her und prüfen Sie erneut.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Build { $build } steht nicht in Microsofts Liste der regulär veröffentlichten Versionen von Windows 11, daher lässt sich Atlas darauf noch nicht installieren. Release-Preview-Builds und andere Vorschau-Builds werden nicht unterstützt. Prüfen Sie erneut, sobald Microsoft diesen Build aufführt.

prepare-continue = Updates fortsetzen
prepare-saving-restart = Ihre Auswahl wird gespeichert und Atlas wird so eingerichtet, dass es nach dem Neustart von Windows wieder geöffnet wird…
prepare-restart-save-failed = Ihre Auswahl konnte nicht gespeichert werden. Versuchen Sie es vor dem Neustart erneut.
prepare-restart-registration-failed = Ihre Auswahl ist gespeichert, aber Atlas konnte nicht einrichten, dass es sich nach dem Neustart wieder öffnet. Versuchen Sie es erneut oder starten Sie Ihren PC selbst neu und öffnen Sie Atlas nach der Anmeldung.
# The same cause as prepare-failed-source-linked, met while arranging the restart.
prepare-restart-source-linked = Ihre Auswahl ist gespeichert, aber solange sich der Atlas Manager in einem verknüpften Ordner befindet, kann Atlas nicht einrichten, dass es sich nach dem Neustart wieder öffnet. Schließen Sie Atlas und verschieben Sie den Atlas Manager in einen lokalen Ordner auf diesem PC. Öffnen Sie ihn dann von dort aus oder starten Sie Ihren PC selbst neu und öffnen Sie ihn nach der Anmeldung von dort aus.
prepare-restart-failed = Atlas konnte Ihren PC nicht neu starten. Versuchen Sie es erneut oder starten Sie ihn über das Startmenü neu. Ihre Auswahl ist gespeichert und Atlas öffnet sich nach der Anmeldung wieder.
diagnostics-export = Diagnose exportieren
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Diagnosedaten werden gesammelt…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Hilfe erhalten
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnose-ZIP gespeichert
# Under diagnostics-saved. $file is the ZIP's name and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Gespeichert als { $file } im Ordner „{ $folder }“ von Atlas.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas hat daraus Ihren Benutzernamen, Ihren PC-Namen, E-Mail-Adressen und bekannte Kennwörter oder Schlüssel entfernt.
# The bar when an export failed. Its button is common-try-again.
diagnostics-save-failed = Diagnose-ZIP konnte nicht gespeichert werden

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Testversion von Atlas { $release }. Diese App installiert nur das mitgelieferte Atlas-Paket.
home-status-bundled = Testversion { $release }
package-bundled = Das mit dieser Testversion mitgelieferte Atlas { $version } ist bereit zur Installation.
rc-about-release = Testversion
rc-about-commit = Quell-Commit
rc-about-package = Mitgeliefertes Atlas-Paket (SHA-256)
iso-package-bundled = Das mit dieser Testversion mitgelieferte Atlas-Paket

check-user-account = Benutzerkonto
detail-user-account-ok = Die Benutzerkontensteuerung ist aktiviert und Ihr Konto ist für die Installation bereit.
detail-user-account-not-ready = Aktivieren Sie die Benutzerkontensteuerung (UAC), starten Sie Ihren PC neu und versuchen Sie es dann erneut. Wenn Sie das integrierte Administratorkonto verwenden, melden Sie sich mit einem anderen Administratorkonto an.
detail-user-account-work-or-school = Atlas kann nicht unter einem Geschäfts-, Schul- oder Unikonto (Microsoft Entra ID) installiert werden. Melden Sie sich mit einem lokalen Konto oder einem Microsoft-Konto an und versuchen Sie es dann erneut.
detail-user-account-check-failed = Atlas konnte Ihr Benutzerkonto nicht prüfen. Starten Sie Ihren PC neu, öffnen Sie Atlas erneut und prüfen Sie noch einmal. Windows meldet: { $error }

footer-prepare-required = Schließen Sie die Updates für Windows und Store-Apps ab, um fortzufahren
# "Phase" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Updates werden nach der aktuellen Phase angehalten…
resume-choices-title = Vorherige Installation fortsetzen
# The bar on Your choices, above the choices an unfinished installation holds.
resume-choices-held = Atlas verwendet Ihre Auswahl vom letzten Mal, um diese Installation abzuschließen. Bis dahin lässt sie sich nicht ändern.

## Voluntary reports
report-title = Bericht senden
report-received = Bericht erhalten
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Bewahren Sie diese Referenz auf, falls Sie das Atlas-Team zu diesem Bericht kontaktieren. Wenn Sie Kontaktdaten angegeben haben, kann das Team Ihnen darüber antworten, eine Antwort ist aber nicht garantiert.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Berichtsreferenz kopieren
report-another = Weiteren Bericht senden
# Label of the choice between the two kinds of report.
report-kind = Was möchten Sie senden?
report-kind-issue = Ein Problem
report-kind-suggestion = Einen Vorschlag
report-message = Ihre Nachricht
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Was ist passiert, und was haben Sie gerade getan?
report-message-placeholder-suggestion = Was sollte sich ändern?
# Under the message box, which also reads it out.
report-message-help = Geben Sie keine Kennwörter an.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } von { $max } Zeichen
report-contact = Kontaktdaten (optional)
report-contact-placeholder = E-Mail oder Discord-Benutzername
report-attach = Diagnosedaten beifügen
# Under Include diagnostics. Part of the privacy notice the user agrees to, so keep every item.
report-attach-description = Protokolle und Systemdetails, die bei der Suche nach der Ursache helfen. Atlas entfernt Ihren Benutzernamen, Ihren PC-Namen, E-Mail-Adressen und bekannte Kennwörter oder Schlüssel. Fehlerdetails, Hardwaremodelle und App-Namen bleiben erhalten. Sie können die ZIP-Datei vor dem Senden prüfen.
report-review = ZIP prüfen
# A bar when diagnostics couldn't be prepared. Its button is common-try-again.
report-prepare-failed-title = Diagnosedaten konnten nicht vorbereitet werden
report-prepare-failed-advice = Versuchen Sie es erneut oder senden Sie den Bericht ohne Diagnosedaten.
# The privacy notice the user agrees to, with report-attach-description.
report-privacy = Ihr Bericht geht vertraulich an das Atlas-Team unter reports.atlasos.net. Ihre Nachricht und Ihre Kontaktdaten werden so gesendet, wie Sie sie eingegeben haben. Das Team kann zur Untersuchung KI-Dienste anderer Unternehmen nutzen. Diese erhalten Ihre Nachricht und die Diagnosedaten, aber nicht Ihre Kontaktdaten. Berichte werden nach 90 Tagen gelöscht, und Sicherheitsprotokolle des Servers können Ihre IP-Adresse erfassen.
report-website = Datenschutz und Berichtswebsite
report-consent = Ich stimme zu, diesen Bericht und alle beigefügten Diagnosedaten an das Atlas-Team zu senden
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website.
report-not-sent-retry = Prüfen Sie Ihre Internetverbindung und versuchen Sie es dann erneut. Sie können den Bericht auch über die Berichtswebsite senden.
report-not-sent-busy = Der Berichtsdienst ist ausgelastet. Warten Sie einige Minuten und versuchen Sie es dann erneut.
report-not-sent-outdated = Diese Version von Atlas Manager kann keine Berichte senden. Kopieren Sie Ihre Nachricht auf die Berichtswebsite und fügen Sie gegebenenfalls die Diagnose-ZIP-Datei bei.
report-not-sent-diagnostics = Die Diagnosedaten konnten nicht gesendet werden. Versuchen Sie es erneut oder senden Sie den Bericht ohne Diagnosedaten.
# The footer's button where this version can't send.
report-failed-website = Berichtswebsite öffnen
# Beside a spinner in the footer while the report is on its way.
report-sending = Wird gesendet…
report-send = Bericht senden

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = Geben Sie { $min }–{ $max } Zeichen ein.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = Die Kontaktdaten dürfen höchstens { $max } Zeichen lang sein.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Bestätigen Sie, dass Sie dem Senden dieses Berichts zustimmen.

report-failed-title = Bericht nicht gesendet

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, Version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Ihre Dateien und Apps bleiben erhalten.
home-plan-name = Dieses Update besteht aus zwei Teilen
home-plan-windows-title = Windows 11, Version { $release }
home-plan-windows-step = Atlas installiert sie über Windows Update, dann wird Ihr PC neu gestartet.
# The same step where moving is optional.
home-plan-windows-step-ask = Optional. Atlas fragt zuerst, installiert sie dann über Windows Update, und Ihr PC wird neu gestartet.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Installiert.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas wird aktualisiert und behält Ihre Auswahl bei, dann wird Ihr PC neu gestartet.
# $date and $until are dates.
home-end-of-updates-title = Für Windows 11, Version { $current }, enden die Sicherheitsupdates am { $date }
home-end-of-updates-past-title = Windows 11, Version { $current }, erhält keine Sicherheitsupdates mehr
home-end-of-updates-message = Mit dem Update auf Atlas { $version } wird dieser PC auch auf Windows 11, Version { $release }, umgestellt. Diese Version erhält Sicherheitsupdates bis zum { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts is under the bar.
home-end-of-support-plan = Windows 11, Version { $release }, erhält Sicherheitsupdates bis zum { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education und kann daher nicht unter { $product } installiert werden.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education und kann daher nicht unter { $product } installiert werden. Windows 11, Version { $current }, erhält Sicherheitsupdates bis zum { $date }, und Windows Update kann diesen PC auf eine neuere Version umstellen.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education und kann daher nicht unter { $product } installiert werden. Version { $current } erhält keine Sicherheitsupdates mehr, aktualisieren Sie Windows daher auch ohne Atlas.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education. LTSC-Editionen werden nicht unterstützt.
# $releases lists the supported releases, such as "25H2 oder 26H2".
install-windows-reinstall = Atlas { $version } benötigt Windows 11, Version { $releases }, und Windows Update kann diesen PC nicht dorthin umstellen. Sichern Sie Ihre Dateien und installieren Sie Windows dann mit einer Atlas-ISO neu.
# The same on Home, where the card that creates an Atlas ISO comes first.
home-windows-no-path = Atlas { $version } benötigt Windows 11, Version { $releases }, und Windows Update kann diesen PC nicht dorthin umstellen.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# "Put back" is "wiederherstellen" throughout; „Einstellungen wiederherstellen“ is home-put-back.
home-update-access-title = Windows Update-Einstellungen wurden für das Atlas-Update geändert
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas stellt diese Einstellungen nach Abschluss des Updates wieder her.
# When the last check found no offer yet.
home-update-access-waiting = Atlas hat Windows Update eingeschaltet, um diesen PC auf Windows 11, Version { $release }, umzustellen, aber Windows Update hat sie noch nicht angeboten.
home-update-access-updating = Atlas hat Windows Update eingeschaltet, um Updates zu installieren, und ist damit noch nicht fertig.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Aufzeichnung von Atlas zu Windows Update konnte nicht gelesen werden
# With Send a report and Export diagnostics under it.
home-update-access-unreadable-problem = Atlas kann seine Aufzeichnung der geänderten Windows Update-Einstellungen nicht lesen. Daher ändert Atlas nichts und stellt nichts wieder her.
# Under the bar when putting the settings back failed for another reason.
home-put-back-failed = Atlas konnte die Einstellungen nicht wiederherstellen.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage ("Phase", not "Schritt"). On Home,
# in the close question and under the Windows release choice on Get ready.
update-access-finish-install = Schließen Sie zuerst die Installation von Atlas ab. In ihrer letzten Phase stellt sie die von Atlas geänderten Windows Update-Einstellungen wieder her.
home-continue-update = Update fortsetzen
home-put-back = Einstellungen wiederherstellen
home-putting-back = Einstellungen werden wiederhergestellt…

# Get ready: the card of the move to a newer Windows version, first on the page.
windows-card-title = Windows 11, Version { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } unterstützt Version { $current } nicht, daher aktualisiert Atlas zuerst Windows.
# Under the title where moving is optional.
windows-optional = Atlas funktioniert mit beiden Versionen.
# The choice's accessible name; the two answers say it.
windows-card-question = Welche Windows-Version soll dieser PC verwenden?
windows-choice-move-recommended = Auf Windows 11, Version { $release }, aktualisieren (empfohlen)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Sicherheitsupdates bis zum { $date }.
windows-choice-keep = Windows 11, Version { $current }, behalten
windows-choice-keep-later = Bleibt auf Version { $current }. Ein Wechsel ist später in Atlas Manager möglich.
windows-card-facts = Was sich ändert
windows-fact-files = Ihre Dateien und Apps bleiben erhalten. Was das Update rückgängig macht, stellt Atlas wieder her.
windows-fact-time = Meist einige Minuten, bis zu 2 Stunden, dann ein Neustart.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Entfernt Windows PowerShell 2.0 und WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = So machen Sie das Update rückgängig
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Mit dem Update akzeptieren Sie die Microsoft-Software-Lizenzbedingungen.
windows-terms-link = Lizenzbedingungen lesen
windows-accept = Akzeptieren und aktualisieren
# Once the terms are accepted, before the move starts by itself.
windows-starting = Wird gestartet…
windows-starts-after-checks = Beginnt, sobald die Prüfungen bestanden sind.
windows-starts-after-package = Beginnt, sobald Atlas { $version } bereit ist.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = Version { $release } hat einige Änderungen von Atlas zurückgesetzt. Atlas { $version } stellt sie mit Ihrer bisherigen Auswahl wieder her.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Windows 11, Version { $current }, behalten?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas schaltet Windows Update vorübergehend ein
access-off = Windows Update ist auf diesem PC ausgeschaltet. Atlas schaltet es wieder ein, während es Windows aktualisiert.
access-paused = Windows-Updates sind auf diesem PC ausgesetzt. Atlas setzt sie fort, während es Windows aktualisiert.
access-delayed = Monatliche Updates sind auf diesem PC zurückgestellt. Atlas hebt die Zurückstellung auf, während es Windows aktualisiert.
# After the lines above.
access-back = Sobald Atlas { $version } installiert ist, sind diese Einstellungen wieder so wie vorher.
access-back-stop = Wenn Sie vorher abbrechen, stellt Atlas sie wieder her.

prepare-reason-feature-update = die neue Windows-Version
prepare-reason-feature-commit = Abschluss der neuen Windows-Version
prepare-reason-apprepository = das Entfernen übrig gebliebener App-Einträge
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Warten, bis Windows Update Windows 11, Version { $release }, anbietet…
windows-waiting-detail = Meist einige Minuten, bis zu 2 Stunden. Atlas fährt automatisch fort; Sie können Ihren PC weiter verwenden.
windows-waited =
    { $minutes ->
        [one] Atlas wartet seit { $minutes } Minute.
       *[other] Atlas wartet seit { $minutes } Minuten.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update hat Version { $release } nicht innerhalb von 2 Stunden angeboten
windows-wait-ended = Atlas hat Ihre Einstellungen wiederhergestellt. Versuchen Sie es später erneut oder installieren Sie Windows mit einer Atlas-ISO neu.
# Instead of the message above when putting the settings back failed. The button is home-put-back.
windows-wait-put-back-failed = Atlas konnte Ihre Windows Update-Einstellungen nicht wiederherstellen.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows konnte den Neustart nicht vorbereiten
windows-commit-failed = Ihr PC wurde nicht neu gestartet. Versuchen Sie es erneut.

# Outcomes of moving Windows, each a title and what to do next.
windows-outcome-not-offered-title = Windows Update hat Version { $release } noch nicht angeboten
windows-outcome-not-offered = Das kann bis zu 2 Stunden dauern. Ihr PC hat weiterhin Version { $current }.
windows-outcome-hardware-title = Dieser PC erfüllt die Anforderungen von Windows 11 nicht
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = Es fehlt die erforderliche Hardware ({ $missing }), daher bietet Windows Update Version { $release } nicht an. Sichern Sie Ihre Dateien und installieren Sie Windows dann mit einer Atlas-ISO neu.
hardware-tpm = TPM 2.0
hardware-uefi = UEFI-Firmware
windows-outcome-hidden-title = Version { $release } ist in Windows Update ausgeblendet
windows-outcome-hidden = Blenden Sie sie mit dem Tool wieder ein, mit dem Sie sie ausgeblendet haben, und versuchen Sie es dann erneut.
windows-outcome-disk-space-title = Nicht genügend freier Speicherplatz
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows benötigt { $needed } GB freien Speicherplatz auf { $drive }, dort sind { $free } GB frei. Sobald genug frei ist, fährt Atlas automatisch fort.
windows-outcome-managed-title = Dieser PC erhält Updates von seiner Organisation
windows-outcome-managed = Der Updateserver bietet Version { $release } nicht an, daher hat Atlas nichts geändert. Wenden Sie sich an Ihre Organisation oder installieren Sie Windows mit einer Atlas-ISO neu.
windows-outcome-policy-title = Etwas setzt Windows Update immer wieder zurück
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = { $setting } wird nach jeder Änderung durch Atlas zurückgesetzt, daher kann Atlas Windows nicht aktualisieren. Wenn eine Organisation diesen PC verwaltet, wenden Sie sich an sie.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Dienst deaktiviert: { $service }
windows-outcome-blocked-service = Windows Update benötigt diesen Dienst. Setzen Sie ihn unter „Dienste“ auf „Manuell“ und versuchen Sie es dann erneut.
windows-outcome-blocked-title = Etwas hält Windows Update ausgeschaltet
windows-outcome-blocked = Eine Einstellung, die Atlas nicht geändert hat, verhindert die Ausführung: { $setting }. Ändern Sie sie und versuchen Sie es dann erneut.
windows-outcome-rollback-title = Windows konnte die Installation von Version { $release } nicht abschließen
windows-outcome-rolled-back = Windows ist zu Version { $current } zurückgekehrt. Ihre Dateien und Apps sind nicht betroffen.
windows-outcome-components-lost-title = Einige Änderungen von Atlas fehlen
windows-outcome-components-lost = Atlas kann den Grund nicht feststellen und hat daher vor der Installation von Atlas { $version } abgebrochen.
windows-outcome-build-title = Windows hat während des Updates die Version gewechselt
windows-outcome-build = Stellen Sie die von Atlas geänderten Einstellungen wieder her und beginnen Sie dann auf der Startseite von vorn.
windows-outcome-journal-title = Atlas kann seine Aufzeichnung dieses Updates nicht lesen
windows-outcome-journal = Atlas ändert nichts und stellt nichts wieder her, bis das Atlas-Team sich das angesehen hat.
windows-outcome-pin-title = Eine Windows Update-Richtlinie kann nicht aufgezeichnet werden
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } hat einen Wert, den Atlas später nicht wiederherstellen kann, daher hat Atlas nichts geändert.
windows-outcome-terms-title = Die Lizenzbedingungen wurden nicht akzeptiert
windows-outcome-terms = Windows Update benötigt Ihre Zustimmung, bevor Version { $release } installiert wird.
windows-outcome-failed-title = Windows konnte Version { $release } nicht installieren
windows-outcome-failed = Ihr PC hat weiterhin Version { $current }.
# Windows services a move needs, as the German Services app lists them.
service-bits = Intelligenter Hintergrundübertragungsdienst (BITS)
service-cryptsvc = Kryptografiedienste
service-trusted-installer = Windows Modules Installer
prepare-open-services = Dienste öffnen
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Version { $current } behalten

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Update auf Atlas { $version } abbrechen?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Aktualisierung von Windows abbrechen?
stop-update-before = Atlas stellt die geänderten Windows Update-Einstellungen wieder her. Updates, die Windows bereits installiert hat, bleiben installiert, und Ihr PC behält Windows 11, Version { $current }.
stop-update-after = Ihr PC behält Windows 11, Version { $release }. Atlas stellt die geänderten Windows Update-Einstellungen wieder her.
stop-update-access = Atlas stellt die geänderten Windows Update-Einstellungen wieder her. Updates, die Windows bereits installiert hat, bleiben installiert.
stop-update-keep = Weiter aktualisieren
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Atlas schließen?
window-close-update-access-message = Atlas stellt vor dem Schließen die geänderten Windows Update-Einstellungen wieder her. Sie können das Update auf der Startseite erneut starten.
window-close-put-back = Wiederherstellen und schließen
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Schließen, ohne die Einstellungen wiederherzustellen?
window-close-put-back-failed-message = Wenn Sie Atlas jetzt schließen, bleiben die Windows Update-Einstellungen so, wie Atlas sie geändert hat. Wenn Sie Atlas wieder öffnen, bietet die Startseite an, sie wiederherzustellen.

# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-needs-release = Diese Atlas-Version benötigt Windows 11, Version { $release }, und dieser PC hat Version { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Die Windows-Aktualisierung für Atlas wurde nicht abgeschlossen. Details für das Atlas-Team:

# When Windows reinstalled itself while it moved to a newer version. German nouns stay capitalised.
history-mode-rebase = Neuinstallation nach Windows-Update
# Your choices after Windows reinstalled itself during a move.
rebase-choices-title = Ihre Auswahl aus Atlas { $previous }
rebase-choices-kept = Atlas stellt die Auswahl wieder her, die Sie für Atlas { $previous } getroffen haben. Ändern können Sie sie später durch eine Neuinstallation von Atlas.
# Above the questions the record of the move had no answer for.
rebase-choices-asked = Jede andere Auswahl, die Sie für Atlas { $previous } getroffen haben, stellt Atlas wieder her.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Neu starten, obwohl eine andere Person angemeldet ist?
restart-others-question = Neu starten, obwohl andere Personen angemeldet sind?
# $names lists their account names, such as "Alex und Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
        [one] { $names } ist ebenfalls angemeldet. Durch den Neustart werden die Apps dieser Person geschlossen, und ihre nicht gespeicherte Arbeit geht verloren.
       *[other] { $names } sind ebenfalls angemeldet. Durch den Neustart werden die Apps dieser Personen geschlossen, und ihre nicht gespeicherte Arbeit geht verloren.
    }
restart-others-keep = Nicht neu starten
restart-others-restart = Trotzdem neu starten
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Microsoft Store wird aktualisiert…
prepare-store-repairing = Microsoft Store wird repariert…
prepare-store-repair-detail = Das kann einige Minuten dauern.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
prepare-store-skipped-removed = Der Microsoft Store ist auf diesem PC ausgeschaltet, daher wurden Store-Apps nicht aktualisiert.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again.
prepare-store-broken-title = Der Microsoft Store funktioniert nicht
prepare-store-broken = Atlas konnte ihn nicht reparieren, und eine Installation von Atlas könnte jetzt Store-Apps beschädigen.
prepare-store-broken-iso = Wenn die Reparatur weiterhin fehlschlägt, sichern Sie Ihre Dateien und installieren Sie Windows mit einer Atlas-ISO neu.
prepare-repair-store-again = Erneut reparieren
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows kann seine integrierten Apps nicht aktualisieren
prepare-store-staging = Windows konnte Updates für diese integrierten Apps nicht installieren, und die Reparaturen von Atlas haben nicht geholfen: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Tastatursprachen
screen-keyboard-question = Verwenden Sie mehrere Tastatursprachen?
package-option-keyboard-shortcuts = Ja, mit Tastenkombinationen
package-option-keyboard-selector = Ja, mit der Auswahl in der Taskleiste
package-option-keyboard-single = Nein, ich verwende nur ein Tastaturlayout
consequence-keyboard-shortcuts = Alt+Umschalt wechselt die Sprache, Strg+Umschalt das Layout.
consequence-keyboard-selector = Schaltet Alt+Umschalt und Strg+Umschalt aus, um versehentliches Wechseln beim Spielen zu vermeiden.
package-choice-keyboard-description = Wählen Sie, wie Sie die Tastatursprache wechseln.
consequence-keyboard-single = { consequence-keyboard-selector }
