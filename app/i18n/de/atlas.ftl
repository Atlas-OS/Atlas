### Atlas Manager: German (de), preview translation. Revised on 1 October 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for this catalog:
### - Sie-form throughout, "Ihr PC" for the computer, Atlas or Windows as actor.
### - Buttons are short infinitive phrases ("Atlas installieren"); familiar
###   controls keep their Windows names (Zurück, Weiter, Abbrechen, Fertig).
### - "neu starten" / "Neustart" always mean the PC or Windows. Reopening the
###   Atlas Manager with administrator rights is "als Administrator ausführen".
### - Windows feature names follow the German Windows Security app
###   (Manipulationsschutz, Echtzeitschutz, Cloudbasierter Schutz, Automatische
###   Übermittlung von Beispielen, Einstellungen für Viren- & Bedrohungsschutz).
### - Product names stay as they are: Atlas, Windows, Microsoft Defender,
###   Windows-Sicherheit, Windows Update, GitHub, Discord, Atlas Toolbox,
###   AME Wizard, Snipping Tool, LocalTest. German quotation marks („ “) mark
###   button and step names quoted inside sentences.
### - The .apbx file is the "Atlas-Paket" ("Paket" once that is clear; its file
###   is the "Paketdatei"). "Playbook" only where a text explains that AME
###   Wizard calls it that.
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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
common-open-log-file = Protokolldatei öffnen
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Installationsprotokoll kopieren
common-install-log = Installationsprotokoll
# Row labels in summary cards.
common-windows = Windows
common-options = Optionen
common-package = Installationsdateien
common-installed-as = Installationsart
common-installed = Installiert
common-checking = Wird geprüft
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 oder 26200".
list-or = { $a } oder { $b }
list-and = { $a } und { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Fenster während der Installation schließen?
window-close-message = Die Installation läuft im Hintergrund weiter. Öffnen Sie Atlas erneut, um den Fortschritt und das Ergebnis zu sehen. Lassen Sie Ihren PC eingeschaltet, bis die Installation abgeschlossen ist.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = Die Installation läuft im Hintergrund weiter, aber Ihr PC wird nicht automatisch neu gestartet, solange Atlas geschlossen ist. Öffnen Sie Atlas erneut, um den Fortschritt und das Ergebnis zu sehen. Lassen Sie Ihren PC eingeschaltet, bis die Installation abgeschlossen ist.
window-close-keep = Offen lassen
window-close-close = Fenster schließen
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = Fenster vor Beginn der Installation schließen?
window-close-preparing-message = Atlas prüft gerade Ihren PC und hat mit der Installation noch nicht begonnen. Wenn Sie jetzt schließen, wird die Installation nicht gestartet. Öffnen Sie Atlas erneut, um fortzufahren.
prepare-close-title = Updates laufen noch
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Lassen Sie Atlas geöffnet, während Updates laufen. Wenn Sie „Updates anhalten“ wählen, werden die Updates nach dem aktuellen Schritt angehalten und Sie können Atlas danach schließen.
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = Atlas ohne Neustart schließen?
# „Jetzt neu starten“ is restart-now, one of this dialog's three buttons.
window-close-restart-message = Ihr PC muss neu gestartet werden, um die Einrichtung von Atlas abzuschließen. Wenn Sie Atlas jetzt schließen, wird Ihr PC nicht neu gestartet. Starten Sie ihn dann selbst neu, sobald Sie bereit sind. Speichern Sie Ihre Arbeit, bevor Sie „Jetzt neu starten“ wählen.
window-close-restart-close = Ohne Neustart schließen
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Atlas mit ausgeschaltetem Schutz schließen?
window-close-protection-message = Einige Schutzfunktionen in der Windows-Sicherheit sind noch ausgeschaltet: { $switches }. Wenn Sie Atlas nicht fertig installieren möchten, schalten Sie diese Schutzfunktionen vor dem Schließen wieder ein. Wenn Sie Atlas fertig installieren möchten, setzt Atlas die Einrichtung fort, sobald Sie es wieder öffnen.
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Atlas-Paket (.apbx) öffnen
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
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas auf diesem PC
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Installiert am { $date }
home-status-checking = Es wird nach Updates gesucht
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
home-restart-title = Ihr PC muss neu gestartet werden
home-security-reminder-title = Schalten Sie Ihren Schutz wieder ein
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Stellen Sie sicher, dass Ihr Schutz eingeschaltet ist
home-security-reminder-message = Atlas installiert gerade nichts, aber einige Schutzfunktionen in der Windows-Sicherheit sind noch ausgeschaltet. Öffnen Sie die Windows-Sicherheit und stellen Sie sicher, dass diese eingeschaltet sind: { $switches }.
home-security-reminder-unreadable-message = Atlas konnte nicht alle Schutzschalter lesen. Prüfen Sie in der Windows-Sicherheit, ob diese eingeschaltet sind: { $switches }.
home-elevation-title = Atlas benötigt eine Berechtigung für die Installation
home-state-error-title = Ihre Atlas-Installationsdaten konnten nicht gelesen werden
home-state-error-message = Ihre Atlas-Version, Ihre Auswahl und Ihr Verlauf werden möglicherweise nicht richtig angezeigt. Wählen Sie „Erneut prüfen“, um es noch einmal zu versuchen. Details: { $error }
home-whats-new = Neu in Atlas { $version }
home-view-release = Versionshinweise auf GitHub ansehen
home-released = Veröffentlicht am { $date }
home-show-less = Weniger anzeigen
home-show-full-notes = Alle Versionshinweise anzeigen
home-your-install = Ihre Atlas-Installation
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Auf diesem PC ist nicht erfasst, wie Atlas installiert wurde. Ihre Auswahl und der Installationsverlauf können daher nicht angezeigt werden.
# Row label: how Atlas was set up.
home-set-up = Eingerichtet
home-set-up-during-oobe = Während der Windows-Ersteinrichtung
home-history = Installationsverlauf
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = So machen Sie Ihren PC bereit für Atlas
home-step-1-detail = Atlas prüft Ihren PC, installiert ausstehende Updates für Windows und aus dem Microsoft Store und lädt die Installationsdateien herunter. Dabei werden möglicherweise Store-Apps geschlossen und Ihr PC muss eventuell neu gestartet werden. Speichern Sie deshalb zuerst Ihre Arbeit.
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas prüft Ihren PC, installiert ausstehende Updates für Windows und aus dem Microsoft Store und bereitet die mitgelieferten Installationsdateien vor. Dabei werden möglicherweise Store-Apps geschlossen und Ihr PC muss eventuell neu gestartet werden. Speichern Sie deshalb zuerst Ihre Arbeit.
home-step-2-detail = Entscheiden Sie, ob Sie Microsoft Defender und den Prozessorschutz behalten, wie Windows-Updates installiert werden und welche optionalen Extras Sie möchten.
home-step-3-detail = Schalten Sie vier Schutzschalter in der Windows-Sicherheit aus, damit sie die Installation nicht blockieren. Atlas zeigt Ihnen, wie das geht.
home-step-4-detail =
    { $minutes ->
        [one] Die Installation dauert etwa eine Minute. Danach muss Ihr PC neu gestartet werden.
       *[other] Die Installation dauert etwa { $minutes } Minuten. Danach muss Ihr PC neu gestartet werden.
    }
# Accessible name of a numbered step.
home-step-a11y = Schritt { $number }: { $title }
home-github = Atlas auf GitHub ansehen
home-discord = Atlas-Community auf Discord beitreten
home-report-problem = Problem melden

## How an install was done (from the state document)

mode-fresh = Erstinstallation
mode-upgrade = Update von einer früheren Version
mode-reapply = Neuinstallation derselben Version
mode-unknown = Installation
# Forms used inside a history row. German nouns stay capitalised.
history-mode-fresh = Erstinstallation
history-mode-upgrade = Update
history-mode-reapply = Neuinstallation
history-mode-unknown = Installation

## Notices on the Home page

notice-settings-reset-title = Atlas verwendet die Standardeinstellungen der App
# $error is a raw error message (text).
notice-settings-unreadable = Atlas konnte Ihre gespeicherten App-Einstellungen nicht lesen. Ihre Windows-Einstellungen sind unverändert. Details: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = Die Datei mit Ihren App-Einstellungen war beschädigt und wurde zurückgesetzt. Eine Kopie der alten Datei ist als { $file } gespeichert. Details: { $error }
notice-settings-damaged = Die Datei mit Ihren App-Einstellungen war beschädigt. Atlas verwendet vorerst die Standardeinstellungen. Details: { $error }
notice-settings-not-saved-title = App-Einstellungen konnten nicht gespeichert werden
# $error is a raw error message (text).
notice-settings-not-saved = Atlas konnte Ihre letzten Änderungen nicht speichern. Sie gehen möglicherweise verloren, wenn Sie Atlas schließen. Wenn ein anderes Atlas-Fenster geöffnet ist, schließen Sie es und nehmen Sie die Änderung erneut vor. Details: { $error }
notice-session-unreadable-title = Vorherige Installation konnte nicht geprüft werden
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Schritt { $number } von { $total }, { $title }, { $status }
stepper-status-completed = abgeschlossen
stepper-status-current = aktueller Schritt
stepper-status-upcoming = späterer Schritt
stepper-status-attention = erfordert Aufmerksamkeit
# Heading above each step's content.
step-heading = Schritt { $number } von { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Step 1: Get ready

ready-banner-busy-title = Ihr PC wird vorbereitet
ready-banner-busy-message = Atlas prüft Ihren PC und bereitet die Installationsdateien vor.
ready-banner-blocked-title = Ihr PC ist noch nicht bereit
ready-banner-blocked-message = Beheben Sie die markierten Punkte unter „PC-Prüfungen“ und wählen Sie dann „Erneut prüfen“.
ready-banner-no-package-title = Laden Sie Atlas herunter, um fortzufahren
ready-banner-no-package-message = Laden Sie Atlas unter „Installationsdateien“ herunter oder wählen Sie „Paketdatei öffnen“, wenn Sie bereits ein Atlas-Paket (.apbx) haben.
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = Bereiten Sie das mitgelieferte Atlas-Paket vor, um fortzufahren
ready-banner-no-package-bundled-message = Das mit dieser Testversion mitgelieferte Atlas-Paket ist noch nicht bereit. Sehen Sie sich die Karte „Installationsdateien“ an.
ready-banner-updates-title = Aktualisieren Sie Windows und die Store-Apps, um fortzufahren
ready-banner-updates-message = Wählen Sie „Updates suchen und installieren“. Wenn die Updates abgeschlossen sind, prüft Atlas Ihren PC erneut.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Windows und Store-Apps werden aktualisiert
ready-banner-updating-message = Das kann eine Weile dauern. Lassen Sie Atlas geöffnet. Den Fortschritt sehen Sie unter „Windows und Store-Apps aktualisieren“.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Aktualisierung angehalten
ready-banner-updates-stopped-message = Wählen Sie „Updates suchen und installieren“ unter „Windows und Store-Apps aktualisieren“, um die Updates abzuschließen.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Ihr PC wurde neu gestartet
ready-banner-updates-resumed-message = Wählen Sie „Updates fortsetzen“ unter „Windows und Store-Apps aktualisieren“, um die Updates abzuschließen.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Unter „Windows und Store-Apps aktualisieren“ erfahren Sie, was zu tun ist. Wählen Sie danach „Erneut versuchen“.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Speichern Sie zuerst Ihre Arbeit und wählen Sie dann „Neu starten und fortfahren“ unter „Windows und Store-Apps aktualisieren“.
ready-banner-warnings-title = Ein paar Punkte zum Prüfen
ready-banner-warnings-message = Sie können fortfahren, aber lesen Sie zuerst die markierten Punkte unter „PC-Prüfungen“.
ready-banner-ok-title = Sie können jetzt Ihre Auswahl treffen
ready-banner-ok-message = Alle Prüfungen sind bestanden und die Installationsdateien sind bereit.

# Card title and accessible name of the list of checks.
ready-this-pc = PC-Prüfungen
ready-check-again = Erneut prüfen
ready-checks-passed =
    { $count ->
        [one] { $count } Prüfung bestanden
       *[other] { $count } Prüfungen bestanden
    }

package-title = Installationsdateien
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } wird heruntergeladen · { $received } von { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Wird entpackt · { $done } von { $total } Datei
       *[other] Wird entpackt · { $done } von { $total } Dateien
    }
package-unpacking = Wird entpackt
package-looking = Die neueste Atlas-Version wird gesucht.
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = Das mitgelieferte Atlas-Paket wird vorbereitet.
package-none = Laden Sie Atlas herunter, um die Installationsdateien zu erhalten. Wenn Sie bereits ein Atlas-Paket (.apbx) haben, öffnen Sie stattdessen dieses.
# The GitHub release check failed. „Neueste Version herunterladen“ is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas konnte nicht nach der neuesten Version suchen. Prüfen Sie Ihre Internetverbindung und wählen Sie dann „Neueste Version herunterladen“ oder öffnen Sie ein gespeichertes Atlas-Paket (.apbx).
# Short status words beside the card title.
package-status-downloading = Wird heruntergeladen
package-status-unpacking = Wird entpackt
package-status-failed = Vorbereitung fehlgeschlagen
package-status-ready = Bereit
package-status-checking = Wird geprüft
package-status-preparing = Wird vorbereitet
package-status-missing = Nicht heruntergeladen
# Accessible name of the progress bar.
package-progress = Fortschritt der Installationsdateien
package-download-again = Erneut herunterladen
package-download-version = Atlas { $version } herunterladen
package-download-newest = Neueste Version herunterladen
package-cancel-download = Download abbrechen
package-open-file = Paketdatei öffnen
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } wurde von GitHub heruntergeladen und ist bereit zur Installation.
package-from-file = Atlas { $version } wurde aus { $file } geladen und ist bereit zur Installation.
package-unpacked = Atlas { $version } ist bereit zur Installation.
package-none-yet = Keine Installationsdateien ausgewählt
acquire-no-asset = Für Atlas { $version } gibt es keine Paketdatei zum Herunterladen. Öffnen Sie ein gespeichertes Atlas-Paket (.apbx), um fortzufahren.
acquire-unsupported = Diese App kann Atlas 0.6.0 und neuer installieren. Verwenden Sie für Atlas { $version } stattdessen den AME Wizard.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = In Atlas { $version } fehlen Dateien, die diese App zur Installation benötigt. Laden Sie es erneut herunter oder öffnen Sie ein anderes Atlas-Paket (.apbx).
acquire-failed = Die Installationsdateien konnten nicht vorbereitet werden. Laden Sie sie erneut herunter oder öffnen Sie ein anderes Atlas-Paket (.apbx). Details: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Der Download reagiert nicht mehr. Prüfen Sie Ihre Internetverbindung und laden Sie die Dateien dann erneut herunter oder öffnen Sie ein gespeichertes Atlas-Paket (.apbx).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Das mitgelieferte Atlas-Paket konnte nicht vorbereitet werden. Wählen Sie „Erneut versuchen“. Details: { $error }

## System checks

check-administrator = Berechtigung zur Installation
check-supported-build = Windows-Kompatibilität
check-pending-updates = Windows-Updates
check-pending-reboot = Ausstehender Neustart
check-third-party-antivirus = Andere Antivirensoftware
check-internet = Internetverbindung
check-power = Stromversorgung
check-activation = Windows-Aktivierung
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
check-fix-apps = Installierte Apps öffnen
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Ich habe in Windows Update nachgesehen: Es warten keine Updates auf die Installation

detail-admin-ok = Atlas hat die Berechtigung, die für die Installation nötigen Änderungen vorzunehmen.
detail-admin-missing = Führen Sie Atlas als Administrator aus. Fragt Windows um Erlaubnis, wählen Sie „Ja“.
# $builds is a list of build numbers such as "26100 oder 26200"; $build is this PC's (text).
detail-build-unsupported = Diese Atlas-Version benötigt Windows-Build { $builds }. Ihr PC hat Build { $build }. Installieren Sie eine unterstützte Windows-Version, bevor Sie fortfahren.
detail-build-missing = Dieses Atlas-Paket gibt keine unterstützten Windows-Builds an. Verwenden Sie einen vollständigen Build des Pakets statt eines LocalTest-Builds.
detail-updates-none = Es warten keine Windows-Updates auf die Installation.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Dieses Update steht aus: { $titles }. Atlas installiert es unter „Windows und Store-Apps aktualisieren“.
        [2] Diese Updates stehen aus: { $titles }. Atlas installiert sie unter „Windows und Store-Apps aktualisieren“.
       *[other] { $count } Updates stehen aus, darunter { $titles }. Atlas installiert sie unter „Windows und Store-Apps aktualisieren“.
    }
detail-updates-unknown = Windows-Updates konnten nicht geprüft werden. Öffnen Sie Windows Update und bestätigen Sie unten, falls keine Updates warten. ({ $error })
detail-reboot-none = Windows benötigt derzeit keinen Neustart.
detail-reboot-pending = Windows muss neu gestartet werden, um frühere Änderungen abzuschließen. Wenn Sie „Updates suchen und installieren“ wählen, bittet Atlas Sie zuerst um einen Neustart.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Windows muss neu gestartet werden, um frühere Änderungen abzuschließen ({ $reasons }). Wenn Sie „Updates suchen und installieren“ wählen, bittet Atlas Sie zuerst um einen Neustart.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Sie können fortfahren. Windows muss beim nächsten Neustart Dateien ersetzen oder entfernen ({ $files }). Manche Apps, etwa Xbox Gaming Services, verursachen das nach jedem Neustart.
detail-reboot-unknown = Es konnte nicht geprüft werden, ob Windows einen Neustart benötigt. Starten Sie Ihren PC neu, öffnen Sie Atlas erneut und prüfen Sie noch einmal. ({ $error })
detail-antivirus-none = Es wurde keine andere Antivirensoftware gefunden.
# $products is a list of product names (text).
detail-antivirus-found = Andere Antivirensoftware als Microsoft Defender kann die Installation blockieren. Deinstallieren Sie { $products } und wählen Sie dann „Erneut prüfen“.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Die Windows-Sicherheit führt { $products } noch auf, aber die Dateien sind nicht mehr vorhanden, die Software ist also nicht mehr installiert. Atlas kann trotzdem installiert werden.
detail-antivirus-unknown = Andere Antivirensoftware konnte nicht geprüft werden. Wählen Sie „Erneut prüfen“. Wenn die Prüfung weiterhin fehlschlägt, starten Sie Ihren PC neu und prüfen Sie erneut. ({ $error })
detail-internet-ok = Sie sind verbunden. Halten Sie die Verbindung aufrecht, während Atlas Software herunterlädt und installiert.
detail-internet-missing = Stellen Sie eine Internetverbindung her und prüfen Sie dann erneut.
detail-power-mains = Ihr PC ist an das Stromnetz angeschlossen. Lassen Sie ihn angeschlossen, bis die Installation abgeschlossen ist.
detail-power-battery = Schließen Sie Ihren PC ans Stromnetz an, damit er während der gesamten Installation eingeschaltet bleibt.
detail-power-unknown = Atlas konnte nicht feststellen, ob Ihr PC am Stromnetz angeschlossen ist. Wenn es ein Laptop ist, schließen Sie ihn ans Stromnetz an und wählen Sie dann „Erneut prüfen“. Wenn das immer wieder passiert, wählen Sie „Bericht senden“.
detail-activation-ok = Windows ist aktiviert. Atlas ändert daran nichts.
detail-activation-missing = Windows ist nicht aktiviert. Sie können fortfahren, aber Atlas aktiviert Windows nicht für Sie.
detail-activation-no-licence = Windows hat keine Lizenz gemeldet. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht.
detail-activation-unknown = Die Windows-Aktivierung konnte nicht geprüft werden. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht. ({ $error })

## Step 2: Options

options-progress = Auswahl { $number } von { $total }
options-progress-extras = Auswahl { $number } von { $total }: optionale Extras
options-change-later = Microsoft Defender, Prozessorschutz und Update-Einstellungen können Sie später im Atlas-Ordner auf Ihrem Desktop ändern.
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
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wählen Sie eine Option für { $title }
learn-more-defender = Mehr über Microsoft Defender erfahren
learn-more-mitigations = Mehr über Prozessorschutz erfahren
learn-more-updates = Mehr über Windows Update erfahren
learn-more-browser = Mehr über Browser erfahren
learn-more-power = Mehr über Energie und Sicherheit erfahren
learn-more-apps = Mehr über Apps erfahren
learn-more-eclean = Wie eclean mit AtlasOS zusammenarbeitet
learn-more-generic = Einrichtungsanleitung lesen
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Behält den integrierten Virenschutz von Windows bei, der hilft, Ihren PC vor Viren und anderen Bedrohungen zu schützen.
consequence-defender-disable = Entfernt auch SmartScreen. Ihr PC hat keinen Virenschutz, bis Sie eine andere Antivirensoftware installieren, und Windows warnt Sie nicht mehr, bevor Sie nicht erkannte Apps oder Downloads öffnen.
consequence-mitigations-default = Behält den Standardschutz von Windows gegen Prozessorschwachstellen und gegen Angriffe bei, die Fehler in Apps ausnutzen.
consequence-mitigations-disable = Schaltet auch den Exploit-Schutz für Apps aus, etwa den Ablaufsteuerungsschutz (CFG). Das verringert die Sicherheit. Ein möglicher Leistungsunterschied hängt von Ihrem Prozessor ab.
consequence-auto-updates-disable = Öffnen Sie regelmäßig Windows Update, um Updates zu installieren. Update-Benachrichtigungen bleiben eingeschaltet.
consequence-auto-updates-default = Windows installiert Updates automatisch, einschließlich Sicherheitskorrekturen.

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender behalten (empfohlen)
playbook-option-defender-disable = Microsoft Defender entfernen
playbook-option-mitigations-default = Prozessorschutz behalten (empfohlen)
playbook-option-mitigations-disable = Prozessorschutz ausschalten
playbook-option-auto-updates-disable = Updates selbst installieren
playbook-option-auto-updates-default = Updates automatisch installieren
playbook-option-disable-hibernation = Ruhezustand ausschalten
playbook-option-disable-power-saving = Energiesparen ausschalten
playbook-option-disable-core-isolation = Virtualisierungsbasierte Sicherheit (VBS) ausschalten
playbook-option-remove-snipping-tool = Snipping Tool entfernen
playbook-option-uninstall-edge = Microsoft Edge entfernen
playbook-option-install-another-browser = Browser installieren
playbook-option-install-toolbox = Atlas Toolbox installieren
playbook-option-install-eclean = eclean installieren
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender ist der in Windows integrierte Virenschutz. Entfernen Sie ihn nur, wenn Sie die Risiken kennen und eine andere Antivirensoftware verwenden möchten. Unabhängig von Ihrer Wahl schaltet Atlas die Intelligente App-Steuerung, den Erweiterten Phishingschutz und „Mein Gerät suchen“ aus.
playbook-page-mitigations-default-description = Diese Schutzfunktionen, auch Mitigationen genannt, helfen, Ihren PC vor Prozessorschwachstellen wie Spectre und Meltdown und vor Angriffen zu schützen, die Fehler in Apps ausnutzen. Es wird empfohlen, die Standardeinstellungen von Windows beizubehalten.
playbook-page-auto-updates-disable-description = Windows-Updates enthalten Sicherheitskorrekturen. Sie können sie von Windows automatisch installieren lassen oder selbst installieren. In beiden Fällen belässt Atlas Windows auf der aktuellen Version, die nur so lange Sicherheitskorrekturen erhält, bis Microsoft den Support dafür beendet. Atlas schaltet außerdem automatische Updates für Apps aus dem Microsoft Store aus. Aktualisieren Sie diese Apps daher im Microsoft Store.
playbook-page-browser-brave-description = Wählen Sie einen Browser, der installiert werden soll. Atlas ändert Ihre Browsereinstellungen nicht.

## Step 3: Windows Security

security-banner-reading-title = Windows-Sicherheit wird geprüft
security-banner-reading-message = Atlas prüft die vier Schutzschalter unten.
security-banner-off-title = Alle vier Schutzschalter sind aus
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender ist auf diesem PC nicht installiert
security-banner-absent-message = In diesem Schritt müssen Sie nichts ausschalten. Wählen Sie „Weiter“.
security-banner-off-message = Wählen Sie „Weiter“, um Ihre Einrichtung zu überprüfen und Atlas zu installieren.
security-banner-on-title = Virenschutz in der Windows-Sicherheit ausschalten
security-banner-on-message = Microsoft Defender kann die Änderungen blockieren, die Atlas vornimmt. Wählen Sie „Windows-Sicherheit öffnen“ und schalten Sie jeden unten aufgeführten Schalter aus. Wenn Sie Microsoft Defender behalten, schalten Sie die Schalter nach Abschluss der Installation wieder ein.
# The page name in Windows Security.
security-list-title = Einstellungen für Viren- & Bedrohungsschutz
security-switch-off = Aus
security-switch-on = Ein
security-switch-unreadable = Nicht lesbar
security-switch-reading = Wird geprüft
security-all-off = Alle aus
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 noch eingeschaltet und 1 nicht lesbar".
security-count-still-on = { $count } noch eingeschaltet
security-count-unreadable = { $count } nicht lesbar
security-count-join = { $a } und { $b }
security-unknown-title = Bestätigen Sie die Schalter, die Atlas nicht lesen konnte
security-unknown-message = Stellen Sie sicher, dass in der Windows-Sicherheit alle vier Schalter aus sind, und bestätigen Sie das dann unten.
security-acknowledge = Ich habe in der Windows-Sicherheit nachgesehen und alle vier Schalter sind aus
security-unknown-unelevated-title = Atlas benötigt eine Berechtigung, um den Schutz zu prüfen
security-unknown-unelevated-message = Führen Sie Atlas als Administrator aus, damit es die Einstellungen von Microsoft Defender lesen kann.
# The four switches, named as the German Windows Security app names them.
protection-tamper = Manipulationsschutz
protection-tamper-why = Schalten Sie diesen Schutz aus, damit Defender Atlas nicht daran hindert, die Sicherheitseinstellungen von Defender zu ändern.
protection-realtime = Echtzeitschutz
protection-realtime-why = Schalten Sie diesen Schutz aus, damit Defender die Atlas-Installationsdateien beim Prüfen nicht blockiert.
protection-cloud = Cloudbasierter Schutz
protection-cloud-why = Schalten Sie diesen Schutz aus, damit Online-Bedrohungsprüfungen die Atlas-Installationsdateien nicht blockieren.
protection-samples = Automatische Übermittlung von Beispielen
protection-samples-why = Muss aus sein, damit Defender Atlas-Dateien nicht automatisch zur Analyse an Microsoft sendet.

## Step 4: Install

# Accessible name of the progress bar.
install-progress = Installationsfortschritt
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent } %
outcome-succeeded-title = Atlas ist installiert
outcome-lost-title = Installationsergebnis konnte nicht bestätigt werden
outcome-failed-title = Installation nicht abgeschlossen
outcome-requirements = Ihr PC hat die Voraussetzungen für die Installation nicht erfüllt. Die Installation hat nichts geändert. Gehen Sie zurück zu „Vorbereiten“ und führen Sie die Prüfungen erneut aus.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = Ihr PC hat die Voraussetzungen für die Installation nicht erfüllt, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits mit Änderungen begonnen. Gehen Sie zurück zu „Vorbereiten“ und führen Sie die Prüfungen erneut aus.
outcome-not-elevated = Atlas hatte keine Administratorrechte. Die Installation hat nichts geändert. Führen Sie Atlas als Administrator aus und versuchen Sie es dann erneut.
outcome-not-elevated-resumed = Atlas hatte keine Administratorrechte, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits mit Änderungen begonnen. Führen Sie Atlas als Administrator aus und versuchen Sie es dann erneut.
# The installer's live check found Windows or Store updates unfinished. „Vorbereiten“ offers the
# update check again; „Updates suchen und installieren“ is prepare-start, its button in that state.
outcome-preparation-stale = Atlas konnte nicht bestätigen, dass Windows und die Store-Apps auf dem neuesten Stand sind, daher wurde die Installation abgebrochen, bevor Windows geändert wurde. Gehen Sie zurück zu „Vorbereiten“ und wählen Sie „Updates suchen und installieren“.
outcome-preparation-stale-resumed = Atlas konnte nicht bestätigen, dass Windows und die Store-Apps auf dem neuesten Stand sind, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat jedoch bereits mit Änderungen begonnen. Gehen Sie zurück zu „Vorbereiten“ und wählen Sie „Updates suchen und installieren“.
outcome-failed-preflight = Die Installation ist abgebrochen, bevor etwas geändert wurde. Sie können es erneut versuchen. Wenn sie wieder abbricht, wählen Sie „Bericht senden“.
outcome-failed-staging = Die Installation ist beim Vorbereiten der Dateien abgebrochen, bevor Windows geändert wurde. Sie können es erneut versuchen. Wenn sie wieder abbricht, wählen Sie „Bericht senden“.
outcome-failed-applying = Einige Änderungen wurden möglicherweise bereits vorgenommen. Sie können es erneut versuchen. Wenn Sie hier aufhören, schalten Sie die zuvor ausgeschalteten Schutzfunktionen in der Windows-Sicherheit wieder ein, sofern sie noch verfügbar sind.
outcome-failed-resumed = Dieser Versuch wurde vorzeitig abgebrochen, aber ein früherer Versuch hat bereits mit Änderungen begonnen. Sie können es erneut versuchen. Wenn Sie hier aufhören, schalten Sie die zuvor ausgeschalteten Schutzfunktionen in der Windows-Sicherheit wieder ein, sofern sie noch verfügbar sind.
outcome-not-started = Das Installationsprogramm ist nicht rechtzeitig gestartet. Die Installation hat nichts geändert. Sie können es erneut versuchen.
outcome-lost = Das Installationsprogramm wurde beendet, ohne ein Ergebnis zu melden, und einige Änderungen wurden möglicherweise bereits vorgenommen. Sie können es erneut versuchen. Wenn Sie hier aufhören, schalten Sie die zuvor ausgeschalteten Schutzfunktionen in der Windows-Sicherheit wieder ein, sofern sie noch verfügbar sind.
restart-now-message = Windows wird neu gestartet, um die Einrichtung von Atlas abzuschließen.
restart-countdown =
    { $seconds ->
        [one] Windows startet in { $seconds } Sekunde neu, um die Einrichtung von Atlas abzuschließen. Wenn Sie zuerst Ihre Arbeit speichern möchten, wählen Sie „Später neu starten“.
       *[other] Windows startet in { $seconds } Sekunden neu, um die Einrichtung von Atlas abzuschließen. Wenn Sie zuerst Ihre Arbeit speichern möchten, wählen Sie „Später neu starten“.
    }
restart-stopped = Automatischer Neustart abgebrochen. Speichern Sie Ihre Arbeit und starten Sie dann Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
restart-needed = Speichern Sie Ihre Arbeit und starten Sie dann Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
restart-dont-now = Später neu starten
restart-now = Jetzt neu starten
restart-start-failed = Atlas konnte Ihren PC nicht neu starten. Speichern Sie Ihre Arbeit und starten Sie den PC dann über das Startmenü neu. Details: { $error }
preflight-title = Installation wurde nicht gestartet
preflight-invalid-options = Atlas konnte diese Auswahl nicht verwenden. Gehen Sie zurück zu „Ihre Auswahl“, überprüfen Sie sie und versuchen Sie es dann erneut. Details: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Der Zustand Ihres PCs hat sich seit den letzten Prüfungen geändert. Beheben Sie Folgendes, bevor Sie es erneut versuchen. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 noch eingeschaltet".
preflight-security = Windows-Sicherheit: { $summary }.
preflight-busy = Ein anderes Atlas-Fenster startet gerade eine Installation. Warten Sie einen Moment und wählen Sie dann erneut „Atlas installieren“.
# Shown with the home-start-over button.
preflight-taken-over = Ein anderes Atlas-Fenster verwendet jetzt diese Einrichtung, daher wurde die Installation nicht gestartet. Fahren Sie in dem anderen Fenster fort oder wählen Sie „Von vorn beginnen“, um die Einrichtung hier noch einmal zu durchlaufen.
preflight-record-unreadable = Atlas konnte nicht prüfen, ob die vorherige Installation noch läuft, und hat deshalb keine neue gestartet. Gehen Sie zurück zu „Vorbereiten“, um zu sehen, wie es weitergeht. Details: { $error }
preflight-refused = Das Installationsprogramm konnte nicht gestartet werden. Die Installation hat nichts geändert. Wählen Sie „Atlas installieren“, um es erneut zu versuchen. Wenn das immer wieder passiert, wählen Sie „Bericht senden“. Details: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = Das Installationsprogramm konnte nicht gestartet werden, daher wurde dieser Versuch abgebrochen. Ein früherer Versuch hat bereits mit Änderungen begonnen. Wählen Sie „Atlas installieren“, um es erneut zu versuchen. Wenn das immer wieder passiert, wählen Sie „Bericht senden“. Details: { $error }
go-to-ready = Zurück zu „Vorbereiten“
go-to-options = Zurück zu „Ihre Auswahl“
# Replaces Weiter on a choice opened from a Change link on the Install step, while Weiter leads straight back there.
go-to-install = Zurück zu „Installieren“
output-problem-title = Installationsfortschritt konnte nicht gelesen werden
output-problem-message = Atlas konnte das Protokoll nicht lesen. Das bedeutet nicht, dass die Installation gestoppt wurde. Lassen Sie Ihren PC eingeschaltet und versuchen Sie, die Protokolldatei zu öffnen. Details: { $error }
install-elevate-title = Atlas benötigt eine Berechtigung für die Installation
install-no-package-title = Wählen Sie zuerst Ihre Installationsdateien
install-no-package-message = Gehen Sie zurück zu „Vorbereiten“, um Atlas herunterzuladen oder ein gespeichertes Atlas-Paket (.apbx) zu öffnen.
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = Gehen Sie zurück zu „Vorbereiten“, um das mit dieser Testversion mitgelieferte Atlas-Paket vorzubereiten.
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Schließen Sie zuerst „Vorbereiten“ ab
install-not-ready-message = Atlas muss die Prüfung Ihres PCs und die Windows-Updates abschließen, bevor es installieren kann.
install-security-title = Virenschutz vor der Installation prüfen
install-security-reading = Die vier Schutzschalter werden noch einmal geprüft.
install-security-message = { $summary }. Öffnen Sie die Windows-Sicherheit und stellen Sie sicher, dass alle vier Schalter aus sind, bevor Sie installieren.
summary-try-again = Vor dem nächsten Versuch überprüfen
summary-ready = Ihre Atlas-Einrichtung überprüfen
summary-activation = Aktivierung
summary-activation-ok = Aktiviert. Atlas ändert daran nichts.
summary-activation-missing = Nicht aktiviert. Sie können fortfahren, aber Atlas aktiviert Windows nicht.
summary-activation-unknown = Atlas ändert den Aktivierungsstatus von Windows nicht.
summary-duration = Geschätzte Dauer
summary-duration-value =
    { $minutes ->
        [one] { $minutes } Minute, dann ein Neustart
       *[other] { $minutes } Minuten, dann ein Neustart
    }
summary-restart-checkbox = PC nach der Installation automatisch neu starten
summary-show-command = Installationsbefehl anzeigen
summary-hide-command = Installationsbefehl ausblenden
summary-copy-command-a11y = Installationsbefehl kopieren
summary-command-unavailable = Der Installationsbefehl konnte nicht erstellt werden. Details: { $error }
summary-not-chosen = Noch nicht gewählt
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } ändern
footer-still-checking = Installation wird vorbereitet
footer-fix-items = Beheben Sie die Punkte unter „PC-Prüfungen“, um fortzufahren
footer-need-package = Laden Sie Atlas herunter oder öffnen Sie ein Atlas-Paket, um fortzufahren
# Tester build variant of footer-need-package.
footer-need-package-bundled = Bereiten Sie das mitgelieferte Atlas-Paket vor, um fortzufahren
footer-reading-security = Schutzschalter werden geprüft
footer-security-pending = Stellen Sie alle vier Schalter auf „Aus“, um fortzufahren
footer-security-confirm = Bestätigen Sie die Schalter, die Atlas nicht lesen konnte, um fortzufahren
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

installing-checking-title = Eine letzte Prüfung
installing-checking-line = Atlas prüft Ihren PC, bevor Änderungen vorgenommen werden. Das kann einen Moment dauern.
installing-title = Atlas wird installiert
installing-phase-preflight = Ihr PC wird geprüft und die Installationsdateien werden vorbereitet.
installing-phase-staging = Die Installationsdateien werden bereitgestellt. Lassen Sie Ihren PC eingeschaltet.
installing-phase-applying = Windows wird mit Ihrer Auswahl eingerichtet. Lassen Sie Ihren PC eingeschaltet und am Stromnetz.
installing-phase-done = Die Installation wird abgeschlossen. Lassen Sie Ihren PC eingeschaltet.
installing-installed-title = Atlas ist installiert
# $time is a formatted clock time.
installing-started-just-now = Gestartet um { $time }, vor weniger als einer Minute
installing-started-minutes =
    { $minutes ->
        [one] Gestartet um { $time }, vor einer Minute
       *[other] Gestartet um { $time }, vor { $minutes } Minuten
    }
installing-restart-auto = Ihr PC wird automatisch neu gestartet, wenn die Installation abgeschlossen ist. Speichern Sie bis dahin Ihre Arbeit in anderen Apps.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } ist installiert
installed-title = Atlas ist installiert
installed-ready = Alles erledigt. Ihr PC ist mit Atlas einsatzbereit.
installed-security-message = Sie haben Microsoft Defender behalten, aber einige seiner Schutzfunktionen sind noch ausgeschaltet. Öffnen Sie die Windows-Sicherheit und stellen Sie sicher, dass diese eingeschaltet sind: { $switches }.
installed-defender-removed-title = Microsoft Defender wurde entfernt
installed-defender-removed-message = Ihr PC hat keinen Virenschutz, bis Sie eine andere Antivirensoftware installieren. SmartScreen wurde ebenfalls entfernt, daher warnt Windows Sie nicht mehr, bevor Sie nicht erkannte Apps oder Downloads öffnen.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Sie haben sich entschieden, Microsoft Defender zu behalten, aber er fehlt. Wenn Sie keine andere Antivirensoftware verwenden, installieren Sie eine, um Ihren PC zu schützen. Wenn Sie Defender nicht selbst entfernt haben, wählen Sie „Problem melden“.

## Settings

settings-title = Einstellungen
settings-theme = App-Design
settings-theme-system = Wie Windows
settings-theme-light = Hell
settings-theme-dark = Dunkel
settings-theme-contrast-note = Atlas verwendet die Farben Ihres Windows-Kontrastdesigns.
settings-theme-mica-note = Der durchscheinende Hintergrund wird angezeigt, wenn Sie dasselbe helle oder dunkle Design wie Windows wählen.
settings-language = Sprache
settings-language-system = Wie Windows
settings-language-system-selected = { settings-language-system } ({ $language })
# Under "Wie Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Bei „Wie Windows“: { $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Vorschau
# Under the language list, once, explaining the Vorschau tag.
settings-language-preview-note = Vorschau-Übersetzungen wurden noch nicht muttersprachlich geprüft.
preview-notice = { $language } ist eine Vorschau-Übersetzung und kann Fehler enthalten.
preview-notice-switch = Zu Englisch wechseln
preview-notice-language = Sprache ändern
# $tag is a language tag (text).
settings-language-unavailable = { $tag } ist in dieser Version von Atlas nicht verfügbar. Vorerst wird Englisch angezeigt; Ihre Sprachauswahl bleibt gespeichert.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas unterstützt Ihre Windows-Anzeigesprachen ({ $languages }) noch nicht. Vorerst wird Englisch angezeigt.
settings-language-windows-unavailable = Ihre Windows-Anzeigesprache konnte nicht ermittelt werden. Atlas verwendet vorerst Englisch. Details: { $error }
# $locale is the regional format's own name, for example "Deutsch (Deutschland)".
settings-language-formats = Zahlen, Datum und Uhrzeit folgen Ihrem regionalen Format in Windows ({ $locale }).
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Zahlen folgen Ihrem regionalen Format in Windows ({ $locale }). Datum und Uhrzeit werden in einem Standardformat angezeigt, da Atlas noch keinen Text von rechts nach links darstellen kann.
settings-language-contribute = Beim Übersetzen von Atlas auf GitHub helfen
settings-restart-label = PC nach der Installation automatisch neu starten
settings-restart-locked = Sie können das ändern, sobald die Installation abgeschlossen ist.
settings-restart-description = Wenn diese Option eingeschaltet ist, wird Ihr PC innerhalb einer Minute nach Abschluss der Installation neu gestartet. Dabei werden Ihre geöffneten Apps geschlossen. Speichern Sie Ihre Arbeit, bevor Sie installieren.
settings-help = Hilfe und Feedback
settings-about = Info
settings-about-app = Atlas Manager
settings-about-licence = Lizenz
settings-about-licence-value = GPL-3.0, kostenlos und Open Source
settings-view-source = Quellcode auf GitHub ansehen
# Link that opens the third-party licence notices.
settings-view-licences = Lizenzhinweise anzeigen
# Under the links when Windows could not open the notices.
settings-licences-failed = Die Lizenzhinweise konnten nicht geöffnet werden. Versuchen Sie es erneut oder sehen Sie sie im Quellcode auf GitHub nach.
settings-open-data-folder = App-Ordner öffnen

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Gibt den Speicherplatz frei, in dem Ihre Sitzung im Ruhezustand gespeichert wird. Ruhezustand und Schnellstart stehen dann nicht mehr zur Verfügung.
consequence-disable-power-saving = Schaltet Energiesparfunktionen aus. Ihr PC verbraucht dann möglicherweise mehr Strom, wird wärmer und hält im Akkubetrieb kürzer durch.
consequence-disable-core-isolation = Schaltet eine zusätzliche Sicherheitsebene von Windows aus, einschließlich der Speicherintegrität. Das verringert den Schutz und kann Apps oder Spiele beeinträchtigen, die darauf angewiesen sind.
consequence-remove-snipping-tool = Entfernt die Windows-App für Screenshots und Bildschirmaufnahmen.
consequence-uninstall-edge = Entfernt den Browser Microsoft Edge. Stellen Sie sicher, dass Sie einen anderen Browser haben, oder wählen Sie unten einen aus.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Entfernt Microsoft Edge und löscht Ihre Favoriten, Ihren Verlauf und Ihre gespeicherten Kennwörter in Edge auf diesem PC. Alles, was nicht mit Ihrem Microsoft-Konto synchronisiert ist, geht verloren. Stellen Sie sicher, dass Sie einen anderen Browser haben, oder wählen Sie unten einen aus.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Löscht Ihre Favoriten, Ihren Verlauf und Ihre gespeicherten Kennwörter in Edge auf diesem PC.
consequence-install-another-browser = Wählen Sie unten einen Browser aus; Atlas installiert ihn für Sie.
consequence-install-toolbox = Mit Atlas Toolbox verwalten Sie Ihre Atlas-Einstellungen. Toolbox ist in der Betaphase, einige Funktionen sind daher möglicherweise noch nicht fertig.
consequence-install-eclean = Ein Wartungstool vom Team hinter AtlasOS, mit dem Sie Ihren PC nach der Einrichtung aufräumen können. Prüfen Sie überflüssige Dateien und Autostart-Apps. Erfordert ein Konto und eine Internetverbindung.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas passt Windows so an, dass weniger im Hintergrund läuft und weniger ablenkt. Installieren Sie Atlas direkt nach einer Neuinstallation von Windows, bevor Sie eigene Apps und Dateien hinzufügen.

## ISO creation (Beta)
iso-home-title = Windows-Installationsmedium
iso-home-description = Erstellen Sie eine Windows-Installationsdatei (ISO) mit Atlas und installieren Sie damit Windows auf diesem oder einem anderen PC neu.
iso-open = Atlas-ISO erstellen
iso-title = Atlas-ISO erstellen
iso-beta = Beta
iso-beta-description = Testen Sie die ISO in einer virtuellen Maschine, bevor Sie sie auf einem PC verwenden. Sichern Sie Ihre Dateien, bevor Sie Windows installieren.
iso-admin-description = Atlas benötigt Administratorrechte, um Ihre Windows-ISO zu lesen und die neue zu erstellen. Wählen Sie „Als Administrator ausführen“ und dann „Ja“, wenn Windows nachfragt.
iso-files-description = Atlas erstellt eine Kopie einer Windows-11-ISO und fügt Atlas hinzu, sodass Sie Windows damit neu installieren können. Wählen Sie eine von Microsoft heruntergeladene Windows-11-ISO, laden Sie das neueste Atlas-Paket herunter oder wählen Sie ein vorhandenes (.apbx), und legen Sie dann fest, wo die neue ISO gespeichert wird.
# Tester build: no package picker.
iso-files-description-bundled = Atlas erstellt eine Kopie einer Windows-11-ISO und fügt das mit dieser Testversion mitgelieferte Atlas-Paket hinzu. Wählen Sie eine von Microsoft heruntergeladene Windows-11-ISO und legen Sie dann fest, wo die neue ISO gespeichert wird.
iso-source = Windows-ISO
iso-source-download = Windows 11 bei Microsoft herunterladen
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Atlas-Paket ({ $minimum } oder neuer)
iso-output = Neue ISO speichern unter
iso-no-file = Keine Datei ausgewählt
iso-browse = Durchsuchen
iso-save-as = Speichern unter
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Dateien prüfen
iso-mode-title = Wie möchten Sie Atlas einrichten?
iso-mode-interactive = Atlas-Auswahl nach der Anmeldung treffen
iso-mode-interactive-description = Nach der Anmeldung öffnet sich Atlas und führt Sie durch die Updates, Ihre Auswahl und die Installation von Atlas.
iso-mode-before = Atlas-Auswahl jetzt treffen
iso-mode-before-description = Atlas speichert Ihre Auswahl in der ISO. Nach der Anmeldung öffnet sich Atlas und führt Sie durch die Updates. Danach installieren Sie Atlas mit dieser Auswahl.
iso-package-unsupported-title = Neueres Atlas-Paket wählen
# „Atlas-Auswahl nach der Anmeldung treffen“ is iso-mode-interactive.
iso-package-unsupported = Dieses Atlas-Paket kann keine Atlas-Auswahl in der ISO speichern. Wählen Sie ein neueres Paket oder „Atlas-Auswahl nach der Anmeldung treffen“.
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = Mit diesem Atlas-Paket kann keine ISO erstellt werden. Wählen Sie ein Paket für Atlas { $minimum } oder neuer.
# Tester build: the bundled Atlas package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = Atlas-Auswahl kann nicht in dieser ISO gespeichert werden
# „Atlas-Auswahl nach der Anmeldung treffen“ is iso-mode-interactive.
iso-package-unsupported-bundled = Das mit dieser Testversion mitgelieferte Atlas-Paket unterstützt die ISO-Einrichtung nicht. Wählen Sie stattdessen „Atlas-Auswahl nach der Anmeldung treffen“.
iso-atlas-options = Atlas-Auswahl
iso-review = ISO überprüfen
iso-review-description = Beim Erstellen der ISO wird nichts auf diesem PC installiert und Ihre ursprüngliche ISO bleibt unverändert. Danach kann Atlas die neue ISO auf ein USB-Laufwerk übertragen, damit Sie Windows davon neu installieren können.
iso-review-files = Dateien
iso-step-windows = Windows-Einrichtung
iso-step-review = Überprüfung
iso-review-package = Atlas-Paket
iso-review-output = Neue ISO
iso-review-editions = Editionen
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Kontoname
iso-review-target = Installation auf
iso-review-drivers = Treiber
iso-create = ISO erstellen
iso-progress-title = Ihre ISO wird erstellt
iso-stage-inspect = Ihre Windows-ISO wird geprüft
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
iso-progress-description = Lassen Sie Atlas geöffnet. Die Verarbeitung großer Abbilder kann einige Zeit dauern.
iso-cancel = Erstellung abbrechen
iso-cancelling = Warten auf einen sicheren Abbruchpunkt
iso-cancelled = ISO-Erstellung abgebrochen
iso-cancelled-description = Ihre ursprüngliche ISO ist unverändert. Falls temporäre Dateien zurückgeblieben sind, wählen Sie „Protokollordner öffnen“, um zu sehen, wo sie liegen.
iso-complete = Ihre ISO ist fertig
iso-complete-description = Die ISO-Erstellung ist in der Betaphase. Testen Sie die ISO daher zuerst in einer virtuellen Maschine. Wählen Sie dann „Installations-USB erstellen“ und sichern Sie Ihre Dateien, bevor Sie Windows neu installieren.
iso-open-folder = Im Ordner anzeigen
iso-failed = ISO-Erstellung konnte nicht abgeschlossen werden
iso-failed-description = Stellen Sie sicher, dass Ihre Dateien noch am gewählten Ort liegen und das Laufwerk, auf dem Sie speichern, angeschlossen ist, und wählen Sie dann „ISO erstellen“. Wenn es weiterhin fehlschlägt, wählen Sie „Bericht senden“.
# Title while the Check files step fails; the messages below say why.
iso-check-failed = Dateien konnten nicht geprüft werden
iso-check-failed-description = Stellen Sie sicher, dass die ISO und das Atlas-Paket noch am gewählten Ort liegen und vollständig heruntergeladen sind, und wählen Sie dann „Dateien prüfen“. Wenn es weiterhin fehlschlägt, wählen Sie „Bericht senden“.
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas benötigt eine Berechtigung zum Erstellen einer ISO
# Typed reasons reported by the image worker.
iso-failed-output-exists = Eine Datei mit diesem Namen ist bereits vorhanden. Wählen Sie „Speichern unter“ und geben Sie einen neuen Dateinamen ein.
iso-failed-destination = Atlas kann die neue ISO dort nicht speichern. Wählen Sie „Speichern unter“ und dann einen Ordner auf diesem PC, etwa „Downloads“. Netzwerkorte und mit FAT32 oder exFAT formatierte Laufwerke können nicht verwendet werden. Das betrifft viele USB-Laufwerke.
iso-failed-space = Auf dem Ziellaufwerk ist nicht genügend freier Speicherplatz vorhanden. Geben Sie Speicherplatz frei oder speichern Sie die neue ISO auf einem anderen Laufwerk.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Diese ISO enthält keine unterstützten Windows-Editionen. Windows Home und LTSC werden nicht unterstützt. Verwenden Sie eine ISO mit einer anderen Edition, etwa Pro, Education oder Enterprise.
iso-failed-customised = Diese ISO enthält bereits angepasste Setup-Dateien wie autounattend.xml. Wählen Sie eine unveränderte Windows-ISO von Microsoft.
iso-failed-windows-unsupported = Dieses Windows-Abbild wird vom Atlas-Paket nicht unterstützt. Verwenden Sie eine unveränderte 64-Bit-ISO einer Windows-11-Version, die dieses Paket unterstützt.
iso-failed-network-architecture = Die Netzwerktreiber dieses PCs passen nicht zur Architektur dieser ISO. Gehen Sie zurück und deaktivieren Sie „Netzwerktreiber dieses PCs einbinden“ oder wählen Sie eine ISO für diesen PC.
iso-failed-unstaged = Atlas konnte seinen Arbeitsordner nicht vorbereiten, daher wurde nichts geändert. Versuchen Sie es erneut. Wenn der Fehler weiterhin auftritt, wählen Sie „Diagnose exportieren“ für einen Fehlerbericht.
iso-failed-package-changed = Das Atlas-Paket wurde nach der Prüfung der Dateien geändert. Wählen Sie „Ändern“ neben „Dateien“ und dann „Dateien prüfen“.
iso-diagnostics = Protokollordner öffnen
iso-close-title = Die ISO wird noch erstellt
iso-close-message = Lassen Sie dieses Fenster geöffnet, bis die Erstellung oder der Abbruch abgeschlossen ist. Beim Abbrechen wird gewartet, bis der laufende Vorgang sicher beendet werden kann.
iso-keep-open = Geöffnet lassen
prepare-title = Windows und Store-Apps aktualisieren
prepare-description = Vor der Installation aktualisiert Atlas Windows, den Microsoft Store und Ihre Store-Apps. Geöffnete Store-Apps wie Editor, Paint oder Windows-Terminal werden beim Aktualisieren möglicherweise geschlossen. Speichern Sie deshalb vorher Ihre Arbeit darin. Möglicherweise muss Ihr PC auch neu gestartet werden.
prepare-complete = Atlas hat keine weiteren Windows- oder Store-Updates zum Installieren gefunden.
prepare-reboot-title = Starten Sie Ihren PC neu, um fortzufahren
prepare-reboot = Ihr PC muss neu gestartet werden, um die Installation der Updates abzuschließen. Atlas speichert Ihre bisherige Auswahl und öffnet sich nach der Anmeldung wieder.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = Ihr PC muss neu gestartet werden, um die Installation der Updates abzuschließen ({ $reasons }). Atlas speichert Ihre bisherige Auswahl und öffnet sich nach der Anmeldung wieder.
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = Speichern Sie zuerst Ihre Arbeit und schließen Sie Ihre Apps. Ihr PC wird sofort neu gestartet, wenn Sie „Neu starten und fortfahren“ wählen.
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = Ihr PC wurde neu gestartet, aber Windows meldet weiterhin, dass ein Neustart nötig ist ({ $reasons }). Ein weiterer Neustart hilft daher wahrscheinlich nicht. Wählen Sie „Windows Update öffnen“, schließen Sie dort alles ab, was noch aussteht, und wählen Sie dann „Erneut versuchen“. Wenn nichts aussteht, wählen Sie „Bericht senden“.
# Names of the markers Windows sets when it wants a restart. They complete
# "Ihr PC muss neu gestartet werden, um die Installation der Updates abzuschließen (…)";
# keep them short.
prepare-reason-servicing = Windows-Wartung
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = noch zu ersetzende Dateien
prepare-reason-update-agent = der Windows Update-Dienst
prepare-reason-unknown = Grund nicht gemeldet
prepare-failed = Wählen Sie „Erneut versuchen“. Wenn es wieder fehlschlägt, schließen Sie die restlichen Updates in Windows Update oder im Microsoft Store ab oder wählen Sie „Bericht senden“.
prepare-failed-title = Einige Updates konnten nicht abgeschlossen werden
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. „Erneut versuchen“ is common-try-again, the button beside it.
prepare-ended-unconfirmed = Die Aktualisierung wurde beendet, bevor ein Ergebnis gemeldet wurde. Atlas kann daher nicht bestätigen, dass Windows und die Store-Apps auf dem neuesten Stand sind. Wählen Sie „Erneut versuchen“, um nach Updates zu suchen.
prepare-unconfirmed-title = Update-Ergebnis konnte nicht bestätigt werden
# „Updates suchen und installieren“ is prepare-start, its button in this state.
prepare-cancelled = Die Aktualisierung wurde angehalten. Einige Updates wurden möglicherweise bereits installiert. Wählen Sie „Updates suchen und installieren“, um die Updates abzuschließen, bevor Sie fortfahren.
prepare-windows-search = Windows Update wird geprüft…
prepare-windows-download = Windows-Updates werden heruntergeladen…
prepare-windows-install = Windows-Updates werden installiert…
prepare-store-search = Microsoft Store wird geprüft…
prepare-store-install = Microsoft Store und seine Apps werden aktualisiert…
prepare-stop-description = Atlas hält an, sobald der aktuelle Schritt abgeschlossen ist. Lassen Sie Atlas bis dahin geöffnet.
prepare-stop = Updates anhalten
prepare-restart = Neu starten und fortfahren
prepare-start = Updates suchen und installieren
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = Nicht verfügbar, weil diese Installation nicht fortgesetzt werden kann. Beachten Sie die Meldung oben auf der Seite.
prepare-needs-build-check = Verfügbar, sobald die Prüfung „{ $check }“ unter „PC-Prüfungen“ bestanden ist.
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = Verfügbar, sobald die Installationsdateien bereit sind.
iso-username = Name des lokalen Kontos
iso-account-description = Bei der Windows-Einrichtung wird ein lokales Konto mit diesem Namen erstellt, Sie brauchen also kein Microsoft-Konto. Bei der ersten Anmeldung fordert Windows Sie auf, ein Kennwort festzulegen.
iso-username-placeholder = Ihr Name
iso-account-empty = Geben Sie einen Namen für das lokale Konto ein, um fortzufahren
iso-account-invalid = Verwenden Sie bis zu 20 Zeichen, ohne Leerzeichen am Anfang oder Ende und ohne diese Zeichen: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Der Name darf nicht mit einem Punkt enden.
iso-account-reserved = Windows verwendet diesen Namen für ein integriertes Konto. Wählen Sie einen anderen Namen.
iso-privacy-defaults = Diese ISO überspringt bei der Windows-Einrichtung die Seiten für Lizenz, Microsoft-Konto und Datenschutz und schaltet die optionale Datenfreigabe und personalisierte Angebote aus.
prepare-drivers = Wie sollen Treiber installiert werden?
prepare-drivers-auto = Treiber über Windows Update beziehen
prepare-drivers-auto-detail = Windows sucht passende Treiber für Ihre Hardware. Für die meisten PCs empfohlen.
prepare-drivers-manual = Treiber selbst installieren
prepare-drivers-manual-detail = Windows Update installiert keine Treiber. Sie müssen sie daher vom Hersteller Ihres PCs oder Geräts beziehen. Bereits installierte Treiber bleiben erhalten.
prepare-drivers-description = Mit Treibern kann Windows Ihre Hardware nutzen, etwa Grafik, Sound und WLAN. Wenn Sie dies nach dem Aktualisieren ändern, muss Atlas erneut nach Updates suchen.
prepare-network-needed = Für Updates ist eine nicht getaktete Internetverbindung erforderlich. Verbinden Sie sich mit einem WLAN oder über Ethernet und wählen Sie dann „Erneut versuchen“. Wenn Sie keine WLAN-Netzwerke sehen, installieren Sie zuerst Ihren Netzwerktreiber.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows meldet, dass dieses Netzwerk keinen Internetzugang hat. Melden Sie sich beim Netzwerk an, falls Sie dazu aufgefordert werden, oder prüfen Sie Ihren Router sowie DNS- oder Firewall-Filter. Versuchen Sie es dann erneut.
# „Getaktete Verbindung“ is the switch's name in Windows network settings.
prepare-network-metered = Diese Verbindung ist getaktet oder hat ein Datenlimit. Verbinden Sie sich mit einem nicht getakteten Netzwerk oder schalten Sie „Getaktete Verbindung“ in den Netzwerkeinstellungen aus. Versuchen Sie es dann erneut.
prepare-network-settings = Netzwerkeinstellungen öffnen
iso-target-title = Auf welchem PC möchten Sie Windows neu installieren?
iso-target-this = Auf diesem PC
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas kann die WLAN- und Ethernet-Treiber dieses PCs in die ISO einbinden, damit Windows direkt nach der Neuinstallation online gehen kann.
iso-target-other = Auf einem anderen PC
iso-copy-network = Netzwerktreiber dieses PCs einbinden
iso-network-detail = Verwendet die WLAN- und Ethernet-Treiber dieses PCs bei der Windows-Installation. Verbinden Sie sich danach erneut mit dem WLAN.
iso-network-source = Quelle der Netzwerktreiber
iso-network-installed = Installierte Treiber verwenden
iso-network-updated = Zuerst bei Windows Update suchen
iso-network-updated-detail = Lädt passende Treiber von Windows Update herunter und behält installierte Treiber als Reserve. Erfordert eine nicht getaktete Verbindung.
iso-stage-network-drivers = Netzwerktreiber werden vorbereitet
iso-network-failed = Die Netzwerktreiber konnten nicht vorbereitet werden. Prüfen Sie die Diagnoseinformationen oder gehen Sie zurück und ändern Sie die Netzwerktreiberoption.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Die Netzwerkadapter dieses PCs verwenden Treiber, die in Windows enthalten sind. Die ISO muss sie daher nicht einbinden.
iso-mode-desktop = Einrichtung vor dem Desktop abschließen
iso-mode-desktop-description = Atlas speichert Ihre Auswahl in der ISO. Nach der Anmeldung schließt Atlas Updates und Installation ab, bevor der Windows-Desktop geöffnet wird.
desktop-setup-description = Schließen Sie die Einrichtung Ihres PCs ab. Ihre Atlas-Auswahl ist gespeichert. Bei Bedarf können Sie zu Windows wechseln.
desktop-setup-exit = In Windows fortfahren

# Windows installation USB (Beta)
usb-title = Installations-USB erstellen
usb-existing = USB aus einer vorhandenen ISO erstellen
usb-description = Übertragen Sie eine ISO auf ein USB-Laufwerk, um Windows davon neu zu installieren. Verwenden Sie eine mit Atlas erstellte ISO, um Atlas gleich mit zu installieren.
usb-choose-iso = ISO auswählen
usb-drive = USB-Laufwerk
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = Keine USB-Laufwerke gefunden. Schließen Sie ein USB-Laufwerk mit mindestens { $min } GB an und wählen Sie dann „Aktualisieren“. Laufwerke über { $max } TB, schreibgeschützte Laufwerke und das Laufwerk, von dem Windows läuft, werden nicht angezeigt.
usb-refresh = Aktualisieren
# Shown when the drive list could not be read.
usb-scan-failed = Prüfen Sie, ob das Laufwerk angeschlossen ist, und wählen Sie dann „Aktualisieren“. Wählen Sie für Details „Protokollordner öffnen“.
usb-scan-failed-title = USB-Laufwerke konnten nicht aufgelistet werden
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = Seriennummer: { $serial }
usb-detail-separator = { " · " }
usb-review = USB-Auswahl prüfen
usb-erase-title = Dieses USB-Laufwerk löschen?
usb-erase-description = Der gesamte Inhalt von { $drive } ({ $size } GB) wird dauerhaft gelöscht, einschließlich aller Dateien und Partitionen. Kopieren Sie zuerst alles, was Sie behalten möchten, auf ein anderes Laufwerk. Ihre ISO bleibt erhalten.
usb-layout = Atlas belegt bis zu 32 GB des Laufwerks und lässt den Rest ungenutzt. Das USB-Laufwerk funktioniert auf PCs, die im UEFI-Modus starten. Diesen Modus setzt Windows 11 voraus.
usb-ack = Mir ist bewusst, dass der gesamte Inhalt dieses USB-Laufwerks gelöscht wird
usb-write = Löschen und USB erstellen
usb-stage-prepare = Installationsdateien werden vorbereitet…
usb-stage-format = USB wird formatiert…
usb-stage-copy = Installationsdateien werden kopiert…
usb-stage-verify = USB wird überprüft…
usb-working = Lassen Sie Atlas geöffnet und das USB-Laufwerk angeschlossen. Wenn Sie abbrechen, kann das unfertige USB-Laufwerk nicht zur Windows-Installation verwendet werden.
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = USB-Erstellung konnte nicht abgeschlossen werden
usb-complete-title = Ihr USB-Stick ist bereit
usb-close-title = Der USB-Stick wird noch erstellt
# After erasing may have begun.
usb-failed = Das Laufwerk wurde möglicherweise bereits gelöscht und kann daher noch nicht zur Windows-Installation verwendet werden. Stellen Sie sicher, dass es angeschlossen ist, und wählen Sie dann „USB-Auswahl prüfen“, um es erneut zu versuchen. Wenn Sie es neu angeschlossen haben, wählen Sie zuerst „Aktualisieren“ und dann erneut das Laufwerk.
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = Ihr USB-Laufwerk wurde nicht verändert. Wählen Sie „Protokollordner öffnen“, um die Ursache zu sehen, und dann „USB-Auswahl prüfen“, um es erneut zu versuchen.
usb-failed-iso = Mit dieser ISO kann kein Installations-USB erstellt werden. Wählen Sie eine mit Atlas erstellte ISO oder eine Windows-11-ISO von Microsoft für eine Version, die Atlas unterstützt. Ihr USB-Laufwerk wurde nicht verändert.
usb-failed-location = Die ISO oder der Atlas Manager befindet sich auf diesem USB-Laufwerk, an einem Netzwerkort oder in einem verknüpften Ordner. Verschieben Sie die Datei in einen lokalen Ordner auf diesem PC und versuchen Sie es dann erneut. Ihr USB-Laufwerk wurde nicht verändert.
usb-failed-space = Auf dem Windows-Laufwerk ist nicht genügend Speicherplatz frei, um die Installationsdateien vorzubereiten. Geben Sie Speicherplatz frei und versuchen Sie es dann erneut. Ihr USB-Laufwerk wurde nicht verändert.
usb-failed-fit = Die Installationsdateien passen nicht auf dieses USB-Laufwerk. Verwenden Sie ein größeres Laufwerk und versuchen Sie es dann erneut. Ihr USB-Laufwerk wurde nicht verändert.
usb-failed-drive-changed = Das USB-Laufwerk wurde entfernt, neu angeschlossen oder ersetzt, nachdem die Liste gelesen wurde. Wählen Sie „Aktualisieren“, wählen Sie das Laufwerk erneut aus und wählen Sie dann „USB-Auswahl prüfen“. Ihr USB-Laufwerk wurde nicht verändert.
usb-cancelled = Das Laufwerk enthält möglicherweise unvollständige Installationsdateien. Erstellen Sie es vor der Windows-Installation erneut.
usb-cancelled-title = USB-Erstellung abgebrochen
usb-cancelled-unchanged = Ihr USB-Laufwerk wurde nicht verändert.
usb-complete = Atlas hat alle Dateien geprüft. Wählen Sie „USB auswerfen“ und sichern Sie dann die Dateien auf dem PC, auf dem Sie Windows neu installieren möchten. Schließen Sie das Laufwerk an diesen PC an und starten Sie ihn über sein Boot-Menü vom USB-Laufwerk (oft mit F12, F11 oder Esc beim Starten des PCs).
usb-eject = USB auswerfen
usb-ejected = Sie können das USB-Laufwerk jetzt abziehen. Sichern Sie die Dateien auf dem PC, auf dem Sie Windows neu installieren möchten. Starten Sie diesen PC dann über sein Boot-Menü vom USB-Laufwerk (oft mit F12, F11 oder Esc beim Starten).
usb-eject-failed = Schließen Sie alle Dateien und Fenster, die das Laufwerk verwenden, und versuchen Sie es dann erneut.
usb-eject-failed-title = USB konnte nicht ausgeworfen werden
ready-fresh-title = Atlas ist für eine Neuinstallation von Windows gedacht
ready-fresh-description = Wenn Sie Windows auf diesem PC bereits verwenden, sichern Sie Ihre Dateien und installieren Sie Windows neu, bevor Sie fortfahren. Stellen Sie vorher sicher, dass die Prüfung „Windows-Kompatibilität“ unter „PC-Prüfungen“ bestanden ist, damit Sie eine unterstützte Version neu installieren.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Die Editionen Home, LTSC und Server von Windows 11 werden nicht unterstützt. Verwenden Sie eine andere Edition, etwa Pro, Education oder Enterprise. Wenn Windows Ihre Edition nicht erkennen konnte, klären Sie das, bevor Sie fortfahren.
install-source-title = Installation nicht möglich
install-source-unsupported = Atlas { $source } kann nicht direkt auf { $target } aktualisiert werden. Um diese Version zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows neu.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } kann nicht direkt aktualisiert werden. Um eine neuere Version zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows neu.
# „Paketdatei öffnen“ is package-open-file. $folder is a folder path (text).
install-source-resume = Eine Installation von Atlas { $target } wurde nicht abgeschlossen und kann nur mit dem Paket für Atlas { $target } abgeschlossen werden. Wählen Sie „Paketdatei öffnen“ und dann dieses Atlas-Paket (.apbx). Falls Atlas es heruntergeladen hat, finden Sie es in { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Eine Installation von Atlas { $target } wurde nicht abgeschlossen. Diese Testversion kann nur ihr mitgeliefertes Atlas-Paket installieren. Schließen Sie die Installation daher mit dem Paket für Atlas { $target } in einer regulären Version von Atlas Manager ab.
install-source-unknown = Atlas konnte nicht feststellen, was auf diesem PC bereits installiert ist, und installiert deshalb vorerst nichts. Wählen Sie „Bericht senden“, damit das Atlas-Team helfen kann.
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } Details: { $error }
iso-edition-selection = Es werden nur unterstützte Editionen übernommen. Wählen Sie bei der Windows-Installation eine Edition, für die Sie eine Windows-Lizenz haben.
detail-windows-preview = Insider-Builds werden nicht unterstützt. Verwenden Sie eine regulär veröffentlichte Version von Windows 11.
detail-windows-release-unknown = Atlas konnte nicht bestätigen, dass dieser Windows-Build regulär veröffentlicht wurde. Stellen Sie eine Internetverbindung her und prüfen Sie erneut.
iso-release-unknown = Atlas konnte nicht bestätigen, dass diese ISO eine regulär veröffentlichte Version von Windows 11 enthält, die das Atlas-Paket unterstützt. Stellen Sie eine Internetverbindung her und wählen Sie dann erneut „Dateien prüfen“. Wenn es weiterhin fehlschlägt, laden Sie die ISO erneut von Microsoft herunter.
prepare-previous-worker = Zuvor gestartete Updates laufen noch. Atlas wartet, bis sie abgeschlossen sind. Danach können Sie erneut nach Updates suchen.

ready-used-windows-title = Windows auf diesem PC wurde offenbar schon genutzt
ready-used-windows-description = Windows wurde auf diesem PC vor mindestens einer Woche installiert oder enthält bereits mehrere Apps. Die Installation von Atlas wird hier nicht unterstützt und es wird dringend davon abgeraten: Vorhandene Apps und Einstellungen funktionieren möglicherweise nicht wie erwartet, und Atlas entfernt OneDrive. Dateien darin werden dann nicht mehr synchronisiert, und Ihre Ordner „Desktop“, „Dokumente“ und „Bilder“ wirken möglicherweise leer. Sichern Sie zuerst Ihre Dateien und installieren Sie Windows neu, oder fahren Sie nur fort, wenn Sie das Risiko in Kauf nehmen.
ready-used-windows-dismiss = Trotzdem fortfahren

prepare-resumed = Ihr PC wurde neu gestartet und Atlas hat Ihre bisherige Auswahl wiederhergestellt. Wählen Sie „Updates fortsetzen“, um die Updates abzuschließen, bevor Sie Atlas installieren.
prepare-continue = Updates fortsetzen
prepare-saving-restart = Ihre Auswahl wird gespeichert und Atlas wird so eingerichtet, dass es nach dem Neustart von Windows wieder geöffnet wird…
prepare-restart-save-failed = Ihre Auswahl konnte nicht gespeichert werden. Versuchen Sie es vor dem Neustart erneut.
prepare-restart-registration-failed = Ihre Auswahl ist gespeichert, aber Atlas konnte nicht einrichten, dass es sich nach dem Neustart wieder öffnet. Versuchen Sie es erneut oder starten Sie Ihren PC selbst neu und öffnen Sie Atlas nach der Anmeldung.
prepare-restart-failed = Atlas konnte Ihren PC nicht neu starten. Versuchen Sie es erneut oder starten Sie ihn über das Startmenü neu. Ihre Auswahl ist gespeichert und Atlas öffnet sich nach der Anmeldung wieder.
diagnostics-export = Diagnose exportieren
diagnostics-exporting = Diagnosedaten werden gesammelt…
diagnostics-privacy = Senden Sie einen Bericht vertraulich an das Atlas-Team oder exportieren Sie eine Diagnose-ZIP-Datei, die Sie weitergeben können, wenn Sie um Hilfe bitten. Atlas entfernt daraus Ihren Benutzernamen, Ihren PC-Namen und E-Mail-Adressen.
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnose-ZIP erstellt
diagnostics-failed-title = Diagnose konnte nicht exportiert werden
# $error is the raw error (text).
diagnostics-failed = Prüfen Sie, ob auf Ihrem PC genügend Speicherplatz frei ist, und versuchen Sie es dann erneut. Details: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Testversion von Atlas { $release }. Diese App installiert nur das mitgelieferte Atlas-Paket.
home-status-bundled = Testversion { $release }
package-bundled = Das mit dieser Testversion mitgelieferte Atlas { $version } ist bereit zur Installation.
rc-about-release = Testversion
rc-about-commit = Quell-Commit
rc-about-package = Mitgeliefertes Atlas-Paket (SHA-256)
iso-package-bundled = Das mit dieser Testversion mitgelieferte Atlas-Paket
prepare-percent = { $percent } % dieser Phase
prepare-count = Abgeschlossene Updates: { $completed } von { $total }
prepare-bytes = { $downloaded } von ungefähr { $total } MB heruntergeladen
prepare-elapsed = Verstrichen: { $minutes } Min. { $seconds } Sek.
prepare-progress-waiting = Warten auf den Updatedienst. Für diesen Schritt ist keine Prozentangabe verfügbar.
prepare-progress-unchanged = Seit { $minutes } Min. kein Fortschritt. Große Updates können eine Weile dauern. Lassen Sie Atlas daher geöffnet. Wählen Sie für Details „Protokollordner öffnen“.
prepare-report-delayed = Windows hat seit { $seconds } Sek. keinen Fortschritt gemeldet. Möglicherweise laufen noch Updates. Lassen Sie Atlas daher geöffnet.

prepare-affected-app = die betroffene App
prepare-app-in-use = Schließen Sie { $app } und versuchen Sie es dann erneut. Windows kann die App nicht aktualisieren, solange sie geöffnet ist. Wenn Sie ihr Fenster nicht finden, beenden Sie sie im Task-Manager. Wenn es weiterhin fehlschlägt, starten Sie Ihren PC neu und versuchen Sie es erneut, bevor Sie { $app } öffnen.
prepare-install-busy = Eine andere Installation oder ein erforderlicher Neustart blockiert Updates. Warten Sie, bis andere Installationen abgeschlossen sind, starten Sie Ihren PC neu, wenn Windows Sie dazu auffordert, und versuchen Sie es dann erneut.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas läuft unter einem anderen Konto als dem, das bei Windows angemeldet ist. Melden Sie sich mit einem Administratorkonto bei Windows an, öffnen Sie Atlas unter diesem Konto und versuchen Sie es dann erneut.
prepare-failed-store-missing = Der Microsoft Store ist für Ihr Konto nicht eingerichtet. Öffnen Sie den Microsoft Store einmal oder installieren Sie ihn neu, falls er fehlt. Versuchen Sie es dann erneut.
prepare-failed-store-battery = Der Microsoft Store hat Updates angehalten, um Akku zu sparen. Schließen Sie Ihren PC ans Stromnetz an und versuchen Sie es dann erneut.
prepare-failed-store-network = Der Microsoft Store hat Updates angehalten, bis Ihr PC eine nicht getaktete Verbindung hat. Verbinden Sie sich über ein nicht getaktetes WLAN oder Ethernet und versuchen Sie es dann erneut.
prepare-failed-store-timeout = Die Store-Apps wurden noch nicht fertig aktualisiert. Schließen Sie die restlichen Downloads im Microsoft Store ab und versuchen Sie es dann erneut.
prepare-failed-store-passes = Der Microsoft Store hat immer wieder neue Updates angeboten. Schließen Sie die restlichen Updates im Microsoft Store ab und versuchen Sie es dann erneut.
prepare-failed-manual-updates = Einige Windows-Updates müssen in Windows Update abgeschlossen werden. Öffnen Sie Windows Update, schließen Sie die Updates dort ab und versuchen Sie es dann erneut.
prepare-failed-windows-passes = Windows Update hat immer wieder neue Updates angeboten. Schließen Sie die restlichen Updates in Windows Update ab und versuchen Sie es dann erneut.
prepare-error-code = Fehlercode: { $code }
prepare-open-store = Microsoft Store öffnen

check-user-account = Benutzerkonto
detail-user-account-ok = Die Benutzerkontensteuerung ist aktiviert und Ihr Konto ist für die Installation bereit.
detail-user-account-not-ready = Aktivieren Sie die Benutzerkontensteuerung (UAC), starten Sie Ihren PC neu und versuchen Sie es dann erneut. Wenn Sie das integrierte Administratorkonto verwenden, melden Sie sich mit einem anderen Administratorkonto an.
detail-user-account-unknown = Atlas konnte Ihr Benutzerkonto nicht prüfen. Prüfen Sie es vor der Installation erneut. Windows meldet: { $error }

footer-prepare-required = Schließen Sie die Updates für Windows und Store-Apps ab, um fortzufahren
footer-prepare-stopping = Updates werden nach dem aktuellen Schritt angehalten…
resume-choices-title = Vorherige Installation fortsetzen
resume-choices-detail = Um diese Installation abzuschließen, hat Atlas Ihre Auswahl vom letzten Mal wiederhergestellt. Unter „Ihre Auswahl“ können Sie sie erst ändern, wenn die Installation abgeschlossen ist.

## Voluntary reports
report-title = Bericht senden
report-received = Bericht erhalten
report-reference = Bewahren Sie diese Referenz auf, falls Sie das Atlas-Team zu diesem Bericht kontaktieren. Wenn Sie Kontaktdaten angegeben haben, kann das Team Ihnen darüber antworten, eine Antwort ist aber nicht garantiert.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Berichtsreferenz kopieren
report-another = Weiteren Bericht senden
# Label of the choice between the two kinds of report.
report-kind = Was möchten Sie senden?
report-kind-issue = Ein Problem
report-kind-suggestion = Einen Vorschlag
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = Beschreiben Sie, was passiert ist oder was Sie sich anders wünschen ({ $min }–{ $max } Zeichen). Geben Sie in Ihrer Nachricht keine Kennwörter an.
report-message = Ihre Nachricht
report-message-placeholder = Ich wollte…
report-contact = Kontaktdaten (optional)
report-contact-placeholder = E-Mail oder Discord-Benutzername
report-attach = Diagnosedaten beifügen
report-attach-description = Protokolle und Systemdetails, die bei der Suche nach der Ursache helfen. Atlas entfernt Ihren Benutzernamen, Ihren PC-Namen, E-Mail-Adressen und bekannte Kennwörter oder Schlüssel. Fehlerdetails, Hardwaremodelle und App-Namen bleiben erhalten. Sie können die ZIP-Datei vor dem Senden prüfen.
report-prepare = Diagnosedaten vorbereiten
report-review = ZIP prüfen
report-prepare-failed-title = Diagnosedaten konnten nicht vorbereitet werden
# $error is a raw error message (text).
report-prepare-failed = Wählen Sie erneut „Diagnosedaten vorbereiten“ oder deaktivieren Sie „Diagnosedaten beifügen“, um Ihren Bericht ohne sie zu senden. Details: { $error }
report-privacy = Ihr Bericht geht vertraulich an das Atlas-Team unter reports.atlasos.net. Ihre Nachricht und Ihre Kontaktdaten werden so gesendet, wie Sie sie eingegeben haben. Das Team kann zur Untersuchung KI-Dienste anderer Unternehmen nutzen. Diese erhalten Ihre Nachricht und die Diagnosedaten, aber nicht Ihre Kontaktdaten. Berichte werden nach 90 Tagen gelöscht, und Sicherheitsprotokolle des Servers können Ihre IP-Adresse erfassen.
report-website = Datenschutz und Berichtswebsite
report-consent = Ich stimme zu, diesen Bericht und alle beigefügten Diagnosedaten an das Atlas-Team zu senden
report-failed = Ihre Nachricht bleibt erhalten. Prüfen Sie Ihre Internetverbindung und wählen Sie dann „Erneut versuchen“ oder senden Sie Ihren Bericht über die Berichtswebsite.
report-failed-busy = Der Berichtsdienst ist ausgelastet. Ihre Nachricht bleibt erhalten. Versuchen Sie es später erneut.
report-failed-outdated = Diese Version von Atlas Manager kann keine Berichte mehr senden. Ihre Nachricht bleibt erhalten: Kopieren Sie sie und fügen Sie sie auf der Berichtswebsite ein. Wenn Sie Diagnosedaten beigefügt haben, wählen Sie „ZIP prüfen“ und hängen Sie die ZIP-Datei dort ebenfalls an.
report-failed-diagnostics = Die vorbereiteten Diagnosedaten können nicht gesendet werden. Ihre Nachricht bleibt erhalten. Wählen Sie erneut „Diagnosedaten vorbereiten“ oder deaktivieren Sie „Diagnosedaten beifügen“.
# Link under a report that wasn't sent.
report-failed-website = Berichtswebsite öffnen
report-sending = Wird gesendet…
report-send = Bericht senden

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = Geben Sie { $min }–{ $max } Zeichen ein.

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = Die Kontaktdaten dürfen höchstens { $max } Zeichen lang sein.

report-validation-consent = Bestätigen Sie, dass Sie dem Senden dieses Berichts zustimmen.

report-failed-title = Bericht nicht gesendet

## Windows version update
home-plan-intro = Dieses Update besteht aus zwei Teilen. Ihre Dateien und Apps bleiben erhalten. Wenn das Windows-Update Änderungen von Atlas rückgängig macht, stellt Atlas sie wieder her.
home-plan-windows-title = Windows 11, Version { $release }
home-plan-windows-detail = Atlas installiert sie über Windows Update. Ihr PC wird neu gestartet, um die Installation abzuschließen.
home-plan-windows-optional = Empfohlen. Atlas installiert sie über Windows Update. Ihr PC wird neu gestartet, um die Installation abzuschließen.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas aktualisiert seine Dateien und behält Ihre Auswahl bei. Am Ende wird Ihr PC neu gestartet.
# $date and $until are dates.
home-end-of-updates-title = Für Windows 11, Version { $current }, enden die Sicherheitsupdates am { $date }
home-end-of-updates-past-title = Windows 11, Version { $current }, erhält keine Sicherheitsupdates mehr
home-end-of-updates-message = Mit dem Update auf Atlas { $version } wird dieser PC auch auf Windows 11, Version { $release }, umgestellt. Diese Version erhält Sicherheitsupdates bis zum { $until }.
# $product is Windows' own name for the edition, such as Windows 11 Home.
install-windows-edition = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education. Auf diesem PC ist { $product } installiert, daher kann Atlas hier nicht installiert werden.
install-windows-edition-ending = Atlas { $version } funktioniert mit Windows 11 Pro, Enterprise und Education. Auf diesem PC ist { $product } installiert, daher kann Atlas hier nicht installiert werden. Für Windows 11, Version { $current }, enden die Sicherheitsupdates am { $date }. Windows Update kann diesen PC auf eine neuere Version umstellen.
# $releases lists the supported releases, such as "25H2 oder 26H2".
install-windows-no-path = Atlas { $version } benötigt Windows 11, Version { $releases }, und Windows Update kann diesen PC von seiner jetzigen Windows-Version aus nicht dorthin umstellen. Um Atlas { $version } zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows mit einer Atlas-ISO neu.
# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# "Put back" is "wiederherstellen" throughout; „Einstellungen wiederherstellen“ is home-put-back.
home-update-access-title = Windows Update-Einstellungen wurden für das Atlas-Update geändert
home-update-access-not-offered = Atlas hat Windows Update eingeschaltet, um diesen PC auf Windows 11, Version { $release }, umzustellen, aber Windows Update hat diese Version noch nicht angeboten. Wählen Sie „Erneut prüfen“ oder „Einstellungen wiederherstellen“.
home-update-access-before = Atlas hat Windows Update eingeschaltet, um diesen PC auf Windows 11, Version { $release }, umzustellen, und ist damit noch nicht fertig. Setzen Sie das Update fort oder wählen Sie „Einstellungen wiederherstellen“.
home-update-access-after = Auf diesem PC läuft Windows 11, Version { $release }. Schließen Sie die Installation von Atlas ab oder wählen Sie „Einstellungen wiederherstellen“.
home-update-access-plain = Atlas hat Windows Update eingeschaltet, um Updates zu installieren, und ist damit noch nicht fertig. Setzen Sie das Update fort oder wählen Sie „Einstellungen wiederherstellen“.
home-update-access-unreadable = Atlas kann seine Aufzeichnung der geänderten Windows Update-Einstellungen nicht lesen. Daher ändert Atlas nichts und stellt auch nichts wieder her. Wählen Sie „Bericht senden“, damit das Atlas-Team helfen kann.
# $error is the raw error.
home-update-access-failed = Atlas konnte die Einstellungen nicht wiederherstellen. Wählen Sie „Erneut versuchen“ oder „Bericht senden“. Details: { $error }
home-update-access-install-active = Schließen Sie zuerst die Installation von Atlas ab. In ihrem letzten Schritt stellt Atlas diese Einstellungen wieder her.
home-continue-update = Update fortsetzen
home-put-back = Einstellungen wiederherstellen
home-putting-back = Einstellungen werden wiederhergestellt…
# Get ready: the Windows version card.
windows-card-title = Windows 11, Version { $release }
windows-card-required = Atlas { $version } benötigt eine neuere Windows-Version. Wenn Atlas Windows weiter unten aktualisiert, installiert es dabei auch Windows 11, Version { $release }, über Windows Update.
windows-card-question = Welche Windows-Version soll dieser PC verwenden?
windows-choice-move = Auf Windows 11, Version { $release }, aktualisieren
# $date is when the new version stops getting security updates.
windows-choice-move-detail = Empfohlen. Sicherheitsupdates bis zum { $date }. Ein zusätzlicher Neustart.
windows-choice-keep = Windows 11, Version { $current }, behalten
windows-choice-keep-detail = Ihr PC bleibt auf dieser Version. Windows Update stellt ihn nicht auf eine neuere Version um. Für einen späteren Wechsel ist daher ein weiteres Update in Atlas Manager nötig.
windows-card-facts = Was sich ändert
windows-fact-keep = Ihre Dateien und Apps bleiben erhalten. Wenn das Update Änderungen von Atlas rückgängig macht, stellt Atlas sie bei der Installation wieder her.
windows-fact-restart = Ihr PC wird mindestens ein weiteres Mal neu gestartet, um das Update abzuschließen.
# Also after home-plan-windows-detail on Home: how long Windows Update can take to offer the
# new version, which Atlas waits for by itself. „sie“ is the new version.
transition-offer-expectation = Windows Update bietet sie meist innerhalb weniger Minuten an, manchmal dauert es aber bis zu 2 Stunden. Atlas wartet darauf und sieht regelmäßig für Sie nach.
windows-fact-stays = Danach bleibt Windows auf Version { $release } und wechselt nicht von selbst auf eine neuere Version.
windows-fact-removed = Version { $release } enthält weder Windows PowerShell 2.0 noch das WMIC-Tool.
# Updateverlauf, System, Wiederherstellung and Zurück are the German Windows 11 labels
# (Einstellungen > Windows Update > Updateverlauf; Einstellungen > System > Wiederherstellung > Zurück).
windows-card-undo = Um das Update später rückgängig zu machen, deinstallieren Sie es in Windows Update unter „Updateverlauf“. Falls Windows sich für das Update neu installiert hat, wählen Sie stattdessen innerhalb von 10 Tagen in den Einstellungen unter „System“ > „Wiederherstellung“ die Option „Zurück“. Atlas { $version } unterstützt Version { $current } nicht. Machen Sie das Update daher nicht rückgängig, sobald Atlas { $version } installiert ist.
windows-card-undo-optional = Um das Update später rückgängig zu machen, deinstallieren Sie es in Windows Update unter „Updateverlauf“. Falls Windows sich für das Update neu installiert hat, wählen Sie stattdessen innerhalb von 10 Tagen in den Einstellungen unter „System“ > „Wiederherstellung“ die Option „Zurück“.
windows-terms = Ich akzeptiere die Microsoft-Software-Lizenzbedingungen für Windows 11, Version { $release }
windows-terms-link = Lizenzbedingungen lesen
# „Abbrechen“ is the flow's own button (common-cancel); „Updates anhalten“ confirms it (prepare-stop).
windows-card-locked = Um Version { $current } zu behalten, wählen Sie „Abbrechen“ und dann „Updates anhalten“.
# Get ready: the update card while Windows moves.
prepare-description-transition = Vor der Installation installiert Atlas zuerst die ausstehenden Windows-Updates, dann Windows 11, Version { $release }, und aktualisiert danach den Microsoft Store und Ihre Store-Apps. Geöffnete Store-Apps werden beim Aktualisieren möglicherweise geschlossen. Speichern Sie deshalb vorher Ihre Arbeit darin. Ihr PC wird mindestens einmal neu gestartet.
prepare-start-transition = Windows auf Version { $release } aktualisieren
prepare-needs-terms = Verfügbar, sobald Sie unter „Windows 11, Version { $release }“ die Lizenzbedingungen akzeptieren.
ready-banner-not-offered-message = Unter „Windows und Store-Apps aktualisieren“ erfahren Sie, was Sie jetzt tun können.
ready-banner-transition-failed-message = Unter „Windows und Store-Apps aktualisieren“ erfahren Sie, wie es weitergeht.
ready-banner-terms-title = Akzeptieren Sie die Lizenzbedingungen, um fortzufahren
ready-banner-terms-message = Sie finden sie weiter unten auf dieser Seite unter „Windows 11, Version { $release }“. Wählen Sie danach „Windows auf Version { $release } aktualisieren“.
# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas schaltet Windows Update vorübergehend ein
access-off = Windows Update ist auf diesem PC ausgeschaltet. Atlas schaltet es wieder ein, während es Windows aktualisiert.
access-paused = Windows-Updates sind auf diesem PC ausgesetzt. Atlas setzt sie fort, während es Windows aktualisiert.
access-delayed = Monatliche Updates sind auf diesem PC zurückgestellt. Atlas hebt die Zurückstellung auf, während es Windows aktualisiert.
access-back-chosen = Sobald Atlas { $version } installiert ist, sind diese Einstellungen wieder so, wie Sie sie gewählt haben.
access-back = Sobald Atlas { $version } installiert ist, sind diese Einstellungen wieder so wie vorher.
access-back-stop = Wenn Sie vorher abbrechen, stellt Atlas sie wieder her.
# The restart that finishes the new version.
prepare-reboot-transition = Windows 11, Version { $release }, ist installiert. Wählen Sie „Neu starten und fortfahren“, um die Installation abzuschließen. Atlas öffnet sich nach der Anmeldung wieder.
prepare-reboot-commit = Windows muss noch einmal neu gestartet werden, um die Installation von Version { $release } abzuschließen. Atlas öffnet sich nach der Anmeldung wieder.
prepare-restart-commit-failed = Windows konnte Version { $release } nicht für den Abschluss beim Neustart vorbereiten, daher wurde Ihr PC nicht neu gestartet. Wählen Sie „Neu starten und fortfahren“, um es erneut zu versuchen.
prepare-reason-feature-update = die neue Windows-Version
prepare-reason-feature-commit = Abschluss der neuen Windows-Version
prepare-resumed-transition = Ihr PC wurde neu gestartet. Wählen Sie „Updates fortsetzen“, damit Atlas prüft, ob die Installation von Windows 11, Version { $release }, abgeschlossen ist, und noch ausstehende Updates installiert.
# Under the progress bar while Windows Update has yet to offer the new version.
prepare-waiting-offer = Es wird gewartet, bis Windows Update Windows 11, Version { $release }, anbietet. Das dauert meist nur wenige Minuten, manchmal aber bis zu 2 Stunden. Sie können Ihren PC weiter verwenden, lassen Sie Atlas aber geöffnet.
# After a restart for the updates Windows installs before the new version.
prepare-resumed-before-move = Ihr PC wurde neu gestartet, um die Installation der Updates abzuschließen. Wählen Sie „Updates fortsetzen“, damit Atlas die noch ausstehenden Updates und danach Windows 11, Version { $release }, installiert.
# Outcomes of moving Windows. Each says what changed and what to do next.
prepare-not-offered-title = Warten, bis Windows Update Windows 11, Version { $release }, anbietet
prepare-transition-failed-title = Windows konnte nicht auf Version { $release } umgestellt werden
prepare-failed-feature-not-offered = Es kann eine Weile dauern, bis Windows Update einem PC Windows 11, Version { $release }, anbietet. Auf Ihrem PC ist weiterhin Version { $current } installiert.
prepare-offer-rechecking = Atlas prüft alle 10 Minuten erneut und fährt von selbst fort, sobald Windows Update die neue Version anbietet. Sie können auch „Erneut prüfen“ wählen.
# Under the progress bar while Atlas waits, updated as time passes: how long it has waited,
# then when it looks again, or that it's looking now. Shown together on one line.
prepare-offer-waited =
    { $minutes ->
        [one] Atlas wartet seit { $minutes } Minute.
       *[other] Atlas wartet seit { $minutes } Minuten.
    }
prepare-offer-next-check =
    { $minutes ->
        [one] Nächste Prüfung in { $minutes } Minute.
       *[other] Nächste Prüfung in { $minutes } Minuten.
    }
prepare-offer-checking-now = Prüfung läuft.
prepare-offer-check-again = Wählen Sie „Erneut prüfen“, um jetzt nachzusehen.
prepare-offer-wait-ended-title = Windows Update hat Windows 11, Version { $release }, noch nicht angeboten
prepare-offer-wait-ended = Windows Update hat Windows 11, Version { $release }, nicht innerhalb von 2 Stunden angeboten. Atlas hat daher aufgehört zu warten und Ihre Windows Update-Einstellungen wiederhergestellt. Wählen Sie später „Erneut prüfen“. Wenn Sie nicht warten können, sichern Sie Ihre Dateien und installieren Sie Windows mit einer Atlas-ISO neu.
# Instead of the message above when putting the settings back at the end of the wait failed.
# $error is the raw error.
prepare-offer-wait-put-back-failed = Windows Update hat Windows 11, Version { $release }, nicht innerhalb von 2 Stunden angeboten, und Atlas konnte Ihre Windows Update-Einstellungen nicht wiederherstellen. Wählen Sie „Einstellungen wiederherstellen“, um es erneut zu versuchen. Details: { $error }
# $missing lists the hardware this PC lacks, from hardware-tpm and hardware-uefi.
prepare-failed-feature-hardware = Dieser PC erfüllt die Hardwareanforderungen von Windows 11 nicht ({ $missing }), daher stellt Windows Update ihn nicht auf Version { $release } um. Auf Ihrem PC ist weiterhin Version { $current } installiert. Um Atlas { $version } zu verwenden, sichern Sie Ihre Dateien und installieren Sie Windows mit einer Atlas-ISO neu.
hardware-tpm = TPM 2.0
hardware-uefi = UEFI-Firmware
prepare-failed-feature-hidden = Windows 11, Version { $release }, ist in Windows Update auf diesem PC ausgeblendet. Blenden Sie die Version mit dem Tool wieder ein, mit dem Sie sie ausgeblendet haben, und wählen Sie dann „Erneut versuchen“.
# $needed and $free are whole gigabytes; $drive is a drive such as C:.
prepare-failed-feature-disk-space = Windows benötigt für dieses Update mindestens { $needed } GB freien Speicherplatz auf Laufwerk { $drive }, dort sind aber nur { $free } GB frei. Atlas hat nichts geändert. Geben Sie Speicherplatz frei und wählen Sie dann „Erneut versuchen“.
prepare-failed-feature-servicing = Windows meldet Schäden an seinem Komponentenspeicher, die es nicht reparieren kann. Atlas hat daher nichts geändert. Reparieren Sie Windows und wählen Sie dann „Erneut versuchen“.
prepare-failed-feature-managed = Dieser PC erhält Updates vom Updateserver einer Organisation, daher kann Atlas ihn nicht auf Version { $release } umstellen. Atlas hat nichts geändert.
# $setting is the technical name of a Windows Update policy value or service, such as
# NoAutoUpdate or BITS, shown as it is.
prepare-failed-feature-policy = Etwas auf diesem PC macht die Änderungen von Atlas an { $setting } immer wieder rückgängig, daher kann Atlas Windows nicht aktualisieren. Wenn dieser PC von einer Organisation verwaltet wird, wenden Sie sich an diese. Wenn Sie abbrechen, stellt Atlas wieder her, was es geändert hat.
prepare-failed-feature-blocked = Eine Einstellung, die Atlas nicht geändert hat, verhindert, dass Windows Update ausgeführt wird: { $setting }. Ändern Sie sie so, dass Windows Update ausgeführt werden kann, und wählen Sie dann „Erneut versuchen“.
prepare-failed-feature-rolled-back = Windows konnte die Installation von Version { $release } beim Neustart nicht abschließen und ist zu Version { $current } zurückgekehrt. Ihre Dateien und Apps sind nicht betroffen. Wählen Sie „Erneut versuchen“ oder „Bericht senden“.
prepare-failed-feature-components-lost = Einige Änderungen von Atlas sind nach dem Windows-Update nicht mehr vorhanden, aber nichts deutet darauf hin, dass Windows sich neu installiert hat. Atlas kann daher nicht feststellen, was passiert ist. Atlas { $version } wurde nicht installiert. Wählen Sie „Bericht senden“, damit das Atlas-Team helfen kann.
prepare-failed-feature-build = Die Windows-Version dieses PCs hat sich geändert, während Atlas sie aktualisiert hat. Wählen Sie „Einstellungen wiederherstellen“ und beginnen Sie dann auf der Startseite von vorn.
prepare-failed-feature-journal = Atlas kann seine Aufzeichnung der geänderten Windows Update-Einstellungen nicht lesen. Daher ändert Atlas nichts und stellt auch nichts wieder her. Wählen Sie „Bericht senden“, damit das Atlas-Team helfen kann.
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
prepare-failed-feature-pin = Eine Windows Update-Richtlinie auf diesem PC, { $setting }, hat einen Wert, den Atlas nicht aufzeichnen kann. Atlas hat daher nichts geändert. Wählen Sie „Bericht senden“, damit das Atlas-Team helfen kann.
prepare-failed-feature-terms = Akzeptieren Sie die Lizenzbedingungen für Windows 11, Version { $release }, und wählen Sie dann „Erneut versuchen“.
prepare-failed-feature-failed = Windows konnte Version { $release } nicht installieren. Auf Ihrem PC ist weiterhin Version { $current } installiert. Wählen Sie „Erneut versuchen“. Wenn es wieder fehlschlägt, wählen Sie „Bericht senden“.
prepare-check-again = Erneut prüfen
prepare-keep-version = Version { $current } behalten
# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Update auf Atlas { $version } abbrechen?
stop-update-before = Atlas stellt die geänderten Windows Update-Einstellungen wieder her. Updates, die Windows bereits installiert hat, bleiben installiert, und Ihr PC behält Windows 11, Version { $current }.
stop-update-after = Ihr PC behält Windows 11, Version { $release }. Atlas stellt die geänderten Windows Update-Einstellungen wieder her.
stop-update-access = Atlas stellt die geänderten Windows Update-Einstellungen wieder her. Updates, die Windows bereits installiert hat, bleiben installiert.
stop-update-keep = Weiter aktualisieren
window-close-update-access-title = Atlas schließen?
window-close-update-access-message = Atlas stellt vor dem Schließen die geänderten Windows Update-Einstellungen wieder her. Sie können das Update auf der Startseite erneut starten.
window-close-put-back = Wiederherstellen und schließen
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Schließen, ohne die Einstellungen wiederherzustellen?
window-close-put-back-failed-message = Wenn Sie Atlas jetzt schließen, bleiben die Windows Update-Einstellungen so, wie Atlas sie geändert hat. Wenn Sie Atlas wieder öffnen, bietet die Startseite an, sie wiederherzustellen.
# The "Atlas is installed" window, when the user's choice turned Windows Update off again.
installed-update-off-again = Windows Update ist wie von Ihnen gewählt wieder ausgeschaltet. Solange es ausgeschaltet ist, erhält Ihr PC keine Sicherheitsupdates.
installed-update-paused-again = Windows-Updates sind wie von Ihnen gewählt wieder ausgesetzt. Solange sie ausgesetzt sind, erhält Ihr PC keine Sicherheitsupdates.
# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-transition = Auf diesem PC läuft Windows 11, Version { $current }. Diese Atlas-Version unterstützt sie nicht. Atlas stellt Windows auf Version { $release } um, wenn es Windows weiter unten aktualisiert.
# The first lines of a report; technical details follow in English.
report-transition-intro = Die Windows-Aktualisierung für Atlas wurde nicht abgeschlossen. Details für das Atlas-Team:
# When Windows reinstalled itself while it moved to a newer version. German nouns stay capitalised.
mode-rebase = Neuinstallation nach einem Windows-Update
history-mode-rebase = Neuinstallation nach Windows-Update
ready-rebase-title = Windows hat sich beim Update neu installiert
# $previous is the Atlas version the PC had before.
ready-rebase-message = Windows 11, Version { $release }, hat das bisherige Windows auf diesem PC ersetzt, daher fehlen einige Änderungen von Atlas. Atlas { $version } stellt sie mit der Auswahl wieder her, die Sie für Atlas { $previous } getroffen haben.
# Your choices on an update, started from what the installed Atlas chose.
upgrade-choices-title = Ihre Auswahl aus Atlas { $previous }
upgrade-choices-detail = Atlas geht von dem aus, was Atlas { $previous } auf diesem PC eingerichtet hat. Beim Update bleibt erhalten, was diese Auswahl bewirkt hat. Wenn Sie hier ein Extra deaktivieren, wird es also nicht rückgängig gemacht. Um eine Auswahl später zu ändern, verwenden Sie den Atlas-Ordner oder die Windows-Einstellungen.
rebase-choices-title = Ihre Auswahl aus Atlas { $previous }
rebase-choices-detail = Atlas verwendet die Auswahl, die Sie für Atlas { $previous } getroffen haben. Hier müssen Sie daher nichts auswählen. Sie können Ihre Auswahl später im Atlas-Ordner ändern.
# $missing lists the choices, such as "Microsoft Defender, Prozessorschutz".
rebase-choices-partial = Atlas verwendet die Auswahl, die Sie für Atlas { $previous } getroffen haben. Diese Punkte konnte Atlas nicht finden. Prüfen Sie sie daher: { $missing }
# Asked before any restart Atlas makes while other people are signed in to the PC.
restart-other-title = Eine andere Person ist an diesem PC angemeldet
restart-others-title = Andere Personen sind an diesem PC angemeldet
# $names lists their account names, such as "Alex und Sam".
restart-others-message = Durch den Neustart werden ihre Apps geschlossen, und ihre nicht gespeicherte Arbeit geht verloren. Angemeldet: { $names }.
restart-others-keep = Nicht neu starten
restart-others-restart = Trotzdem neu starten
# Microsoft Store itself, before the Store apps. Get ready's status line while it updates or is repaired.
prepare-store-self-update = Zuerst wird der Microsoft Store aktualisiert. Er ist auf diesem PC veraltet.
prepare-store-repair = Der Microsoft Store wird repariert. Das kann einige Minuten dauern.
# Under prepare-complete, once Get ready has finished.
prepare-store-updated = Der Microsoft Store war veraltet, daher hat Atlas ihn vor Ihren Apps aktualisiert.
prepare-store-bootstrapped = Der Microsoft Store konnte sich nicht selbst aktualisieren, daher hat Atlas den neuesten App-Installer und den Microsoft Store von Microsoft installiert.
prepare-store-repaired = Der Microsoft Store funktionierte nicht, daher hat Atlas ihn repariert.
prepare-store-skipped-removed = Der Microsoft Store ist auf diesem PC ausgeschaltet, daher hat Atlas die Updates für Store-Apps übersprungen.
# „Microsoft Store reparieren“ is prepare-repair-store; „Bericht senden“ is report-title.
prepare-failed-store-repair-failed = Der Microsoft Store funktioniert nicht, und Atlas konnte ihn nicht reparieren. Wählen Sie „Microsoft Store reparieren“, um es erneut zu versuchen. Wenn er weiterhin nicht funktioniert, wählen Sie „Bericht senden“.
prepare-repair-store = Microsoft Store reparieren
