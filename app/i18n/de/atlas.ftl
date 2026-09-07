### Atlas Manager: German (de), preview translation. Revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
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
# Accessible description of a disabled control.
common-not-available = Zurzeit nicht verfügbar
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

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Fenster während der Installation schließen?
window-close-message = Die Installation läuft im Hintergrund weiter. Öffnen Sie Atlas erneut, um den Fortschritt und das Ergebnis zu sehen. Lassen Sie Ihren PC eingeschaltet, bis die Installation abgeschlossen ist.
window-close-keep = Offen lassen
window-close-close = Fenster schließen
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Atlas-Playbook (.apbx) öffnen
# Message Windows shows in its restart notification.
shutdown-comment = Atlas ist installiert. Windows wird neu gestartet, um die Einrichtung abzuschließen.

## System

# "Windows 11 Pro 25H2 (Build 26200.1234)". All three values are text.
system-description = { $product } { $version } (Build { $build })

## Home page

home-not-installed = Willkommen bei Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Installiert am { $date }
home-status-checking = Es wird nach Updates gesucht
home-status-offline = Suche nach Updates fehlgeschlagen
home-status-not-checked = Noch nicht nach Updates gesucht
home-status-update = Atlas { $version } ist verfügbar
home-status-up-to-date = Auf dem neuesten Stand
home-status-newest = Neueste Version: Atlas { $version }
home-check-again = Erneut prüfen
# Primary button while an install is running or waiting.
home-show-install = Fortschritt anzeigen
home-continue-installing = Einrichtung fortsetzen
home-update-to = Auf Atlas { $version } aktualisieren
home-reinstall = Atlas neu installieren
home-install = Atlas installieren
home-start-over = Von vorn beginnen
home-security-reminder-title = Schalten Sie Ihren Schutz wieder ein
# Names the four switches exactly as the German Windows Security app labels them.
home-security-reminder-message = Es läuft keine Installation. Öffnen Sie die Windows-Sicherheit und schalten Sie die vier Schalter Manipulationsschutz, Echtzeitschutz, Cloudbasierter Schutz und Automatische Übermittlung von Beispielen wieder ein.
home-elevation-title = Atlas benötigt eine Berechtigung für die Installation
home-state-error-title = Ihre Atlas-Installationsdaten konnten nicht gelesen werden
home-whats-new = Neu in Atlas { $version }
home-view-release = Versionshinweise auf GitHub ansehen
home-released = Veröffentlicht am { $date }
home-show-less = Weniger anzeigen
home-show-full-notes = Alle Versionshinweise anzeigen
home-your-install = Ihre Atlas-Installation
# Row label: how Atlas was set up.
home-set-up = Eingerichtet
home-set-up-during-oobe = Während der Windows-Ersteinrichtung
home-history = Installationsverlauf
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = So machen Sie Ihren PC bereit für Atlas
home-step-1-title = PC prüfen
home-step-1-detail = Atlas prüft Windows und lädt die Installationsdateien herunter. Ihre Windows-Einstellungen bleiben dabei unverändert.
home-step-2-title = Auswahl treffen
home-step-2-detail = Legen Sie fest, wie Windows mit Schutz und Updates umgeht, und wählen Sie bei Bedarf zusätzliche Apps und Einstellungen.
home-step-3-title = Virenschutz vorübergehend ausschalten
home-step-3-detail = Atlas zeigt Ihnen vier Schalter in der Windows-Sicherheit, die Sie ausschalten, damit sie die Installation nicht blockieren.
home-step-4-title = Installieren und neu starten
home-step-4-detail =
    { $minutes ->
        [one] Etwa eine Minute.
       *[other] Etwa { $minutes } Minuten.
    }
# Accessible name of a numbered step.
home-step-a11y = Schritt { $number }: { $title }
home-github = Atlas auf GitHub ansehen
home-discord = Atlas-Community auf Discord beitreten
home-report-problem = Problem auf GitHub melden

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
notice-session-unreadable-title = Vorherige Installation konnte nicht geprüft werden
# $path is a file path (text).
notice-session-unreadable-message = Atlas kann { $path } nicht lesen und muss wissen, ob noch eine Installation läuft. Wenn Sie unsicher sind, holen Sie sich Hilfe in der Atlas-Community, bevor Sie diese Datei entfernen. Löschen Sie die Datei nur, wenn Sie sicher wissen, dass keine Installation läuft, und versuchen Sie es dann erneut. Details: { $error }

## Administrator elevation

elevation-declined = Die Berechtigung wurde nicht erteilt. Versuchen Sie es erneut und wählen Sie „Ja“, wenn Windows fragt, ob Atlas Änderungen an Ihrem Gerät vornehmen darf.
elevation-declined-continue = Die Berechtigung wurde nicht erteilt. Versuchen Sie es erneut und wählen Sie „Ja“, wenn Windows fragt, ob Atlas Änderungen an Ihrem Gerät vornehmen darf. Ihre Auswahl ist gespeichert.
elevation-draft-not-saved = Atlas konnte Ihre Auswahl nicht speichern und wurde deshalb nicht als Administrator neu geöffnet. Versuchen Sie es erneut. Details: { $error }

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
# Heading above each step's content.
step-heading = Schritt { $number } von { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = Ihr PC wird vorbereitet
ready-banner-busy-message = Atlas prüft Ihren PC und bereitet die Installationsdateien vor.
ready-banner-blocked-title = Ihr PC braucht noch etwas Vorbereitung
ready-banner-blocked-message = Folgen Sie den Hinweisen unten und wählen Sie dann „Erneut prüfen“.
ready-banner-no-package-title = Laden Sie Atlas herunter, um fortzufahren
ready-banner-no-package-message = Laden Sie unten die neueste Version herunter oder öffnen Sie ein gespeichertes Atlas-Playbook (.apbx).
ready-banner-warnings-title = Ein paar Punkte zum Prüfen
ready-banner-warnings-message = Lesen Sie die Hinweise unten und führen Sie die empfohlenen Schritte aus, bevor Sie fortfahren.
ready-banner-ok-title = Sie können jetzt Ihre Auswahl treffen
ready-banner-ok-message = Alle Prüfungen sind bestanden und die Installationsdateien sind bereit.

# Card title and accessible name of the list of checks.
ready-this-pc = PC-Prüfungen
ready-check-again = Erneut prüfen

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
package-none = Noch keine Installationsdateien. Ein Playbook (.apbx) enthält die Anweisungen und Dateien, die Atlas benötigt.
# Short status words beside the card title.
package-status-downloading = Wird heruntergeladen
package-status-unpacking = Wird entpackt
package-status-failed = Vorbereitung fehlgeschlagen
package-status-ready = Bereit
package-status-checking = Wird geprüft
package-status-missing = Nicht heruntergeladen
# Accessible name of the progress bar.
package-progress = Fortschritt der Installationsdateien
package-download-again = Erneut herunterladen
package-download-version = Atlas { $version } herunterladen
package-download-newest = Neueste Version herunterladen
package-open-file = Playbook-Datei öffnen
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } wurde von GitHub heruntergeladen und ist bereit zur Installation.
package-from-file = Atlas { $version } wurde aus { $file } geladen und ist bereit zur Installation.
package-unpacked = Atlas { $version } ist bereit zur Installation.
package-at = Installationsdateien: { $path }
package-none-yet = Keine Installationsdateien ausgewählt
acquire-no-asset = Für Atlas { $version } steht keine Playbook-Datei zum Herunterladen bereit. Öffnen Sie ein gespeichertes Atlas-Playbook (.apbx), um fortzufahren.
acquire-unsupported = Diese App kann Atlas 0.6.0 und neuer installieren. Verwenden Sie für Atlas { $version } stattdessen den AME Wizard.
acquire-failed = Die Installationsdateien konnten nicht vorbereitet werden. Laden Sie sie erneut herunter oder öffnen Sie ein anderes Atlas-Playbook (.apbx). Details: { $error }

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
# Check boxes the user ticks when a check could not run.
check-ack-updates = Ich habe in Windows Update nachgesehen: Es warten keine Updates auf die Installation
check-ack-reboot = Ich habe Windows neu gestartet und es ist kein weiterer Neustart nötig
check-ack-internet = Dieser PC ist mit dem Internet verbunden
check-ack-generic = Ich habe diese Anforderung selbst geprüft

detail-admin-ok = Atlas hat die Berechtigung, die für die Installation nötigen Änderungen vorzunehmen.
detail-admin-missing = Führen Sie Atlas als Administrator aus und wählen Sie „Ja“, wenn Windows um Erlaubnis fragt.
# $builds is a list of build numbers such as "26100 oder 26200"; $build is this PC's (text).
detail-build-unsupported = Diese Atlas-Version benötigt Windows-Build { $builds }. Ihr PC hat Build { $build }. Installieren Sie eine unterstützte Windows-Version, bevor Sie fortfahren.
detail-updates-none = Es warten keine Windows-Updates auf die Installation.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Installieren Sie zuerst dieses Update: { $titles }.
        [2] Installieren Sie zuerst diese Updates: { $titles }.
       *[other] Installieren Sie zuerst { $count } Updates, darunter { $titles }.
    }
detail-updates-unknown = Windows-Updates konnten nicht geprüft werden. Öffnen Sie Windows Update und bestätigen Sie unten, falls keine Updates warten. ({ $error })
detail-reboot-none = Windows benötigt derzeit keinen Neustart.
detail-reboot-pending = Starten Sie Ihren PC neu, um frühere Änderungen abzuschließen. Öffnen Sie danach Atlas erneut und prüfen Sie noch einmal.
detail-reboot-unknown = Es konnte nicht geprüft werden, ob Windows einen Neustart benötigt. Starten Sie Ihren PC neu, öffnen Sie Atlas erneut und prüfen Sie noch einmal. ({ $error })
detail-antivirus-none = Es wurde keine andere Antivirensoftware gefunden.
# $products is a list of product names (text).
detail-antivirus-found = Antivirensoftware kann die Installation blockieren: { $products }. Deinstallieren Sie diese Software, bevor Sie fortfahren.
detail-antivirus-unknown = Andere Antivirensoftware konnte nicht geprüft werden. Sehen Sie Ihre installierten Apps durch, bevor Sie fortfahren. ({ $error })
detail-internet-ok = Sie sind verbunden. Halten Sie die Verbindung aufrecht, während Atlas Software herunterlädt und installiert.
detail-internet-missing = Stellen Sie eine Internetverbindung her und prüfen Sie dann erneut.
detail-power-mains = Ihr PC ist an das Stromnetz angeschlossen. Lassen Sie ihn angeschlossen, bis die Installation abgeschlossen ist.
detail-power-battery = Schließen Sie Ihren PC ans Stromnetz an, damit er während der gesamten Installation eingeschaltet bleibt.
detail-power-unknown = Die Stromversorgung konnte nicht geprüft werden. Wenn Sie einen Laptop verwenden, schließen Sie ihn ans Stromnetz an, bevor Sie fortfahren.
detail-activation-ok = Windows ist aktiviert. Atlas ändert daran nichts.
detail-activation-missing = Windows ist nicht aktiviert. Sie können fortfahren, aber Atlas aktiviert Windows nicht für Sie.
detail-activation-no-licence = Windows hat keine Lizenz gemeldet. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht.
detail-activation-unknown = Die Windows-Aktivierung konnte nicht geprüft werden. Sie können fortfahren; Atlas ändert den Aktivierungsstatus nicht. ({ $error })

## Step 2: Options

options-progress = Auswahl { $number } von { $total }
options-progress-extras = Auswahl { $number } von { $total }: optionale Extras
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Virenschutz eingeschaltet lassen?
screen-mitigations-title = Prozessorsicherheit
screen-mitigations-question = Prozessorschutz von Windows beibehalten?
screen-updates-title = Windows Update
screen-updates-question = Wie soll Windows Updates installieren?
screen-browser-title = Browser
screen-power-title = Energie und Sicherheit
screen-apps-title = Apps
screen-optional-apps-title = Optionale Apps
screen-choose-one-title = Option wählen
screen-extras-title = Optionale Extras
screen-extras-question = Wählen Sie die Extras, die Sie möchten
# Question for a required choice this app has no specific wording for.
screen-generic-question = Wählen Sie eine Option für { $title }
learn-more-defender = Mehr über Microsoft Defender erfahren
learn-more-mitigations = Mehr über Prozessorsicherheit erfahren
learn-more-updates = Mehr über Windows Update erfahren
learn-more-browser = Mehr über Browser erfahren
learn-more-power = Mehr über Energie und Sicherheit erfahren
learn-more-apps = Mehr über Apps erfahren
learn-more-eclean = Wie eclean mit AtlasOS zusammenarbeitet
learn-more-generic = Einrichtungsanleitung lesen
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Behält den integrierten Virenschutz von Windows bei, der hilft, Ihren PC vor Viren und anderen Bedrohungen zu schützen.
consequence-defender-disable = Entfernt Microsoft Defender. Ihr PC hat dann keinen Virenschutz, bis Sie eine andere Antiviren-App installieren.
consequence-mitigations-default = Behält die Standardschutzmaßnahmen von Windows gegen Angriffe bei, die Schwachstellen des Prozessors ausnutzen.
consequence-mitigations-disable = Schaltet diese Schutzmaßnahmen aus und verringert die Sicherheit. Die Leistung hängt von Ihrem Prozessor ab und kann sich verschlechtern.
consequence-auto-updates-disable = Sie müssen Windows Update selbst öffnen und Updates installieren. Update-Benachrichtigungen bleiben eingeschaltet.
consequence-auto-updates-default = Windows installiert Updates automatisch, einschließlich Sicherheitskorrekturen.

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender behalten (empfohlen)
playbook-option-defender-disable = Microsoft Defender entfernen
playbook-option-mitigations-default = Standardschutz behalten (empfohlen)
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
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender ist der integrierte Virenschutz von Windows. Es wird empfohlen, ihn zu behalten. Entfernen Sie ihn nur, wenn Sie die Risiken kennen und eine andere Antiviren-App verwenden möchten.
playbook-page-mitigations-default-description = Diese Schutzmaßnahmen, auch „Mitigations“ genannt, helfen gegen Schwachstellen im Prozessor. Es wird empfohlen, die Windows-Standardeinstellungen beizubehalten.
playbook-page-auto-updates-disable-description = Windows-Updates enthalten Sicherheitskorrekturen. Windows kann sie automatisch installieren, oder Sie installieren sie selbst.
consequence-install-toolbox = Mit Atlas Toolbox verwalten Sie Ihre Atlas-Einstellungen. Toolbox ist in der Betaphase, einige Funktionen sind daher möglicherweise noch nicht fertig.
playbook-page-browser-brave-description = Wählen Sie einen Browser, der installiert werden soll. Atlas ändert Ihre Browsereinstellungen nicht.

## Step 3: Windows Security

security-banner-reading-title = Windows-Sicherheit wird geprüft
security-banner-reading-message = Atlas prüft die vier Schutzschalter unten.
security-banner-off-title = Alle vier Schutzschalter sind aus
security-banner-off-message = Sie können jetzt Ihre Auswahl überprüfen, bevor Sie installieren.
security-banner-readable-off-title = Alle Schalter, die Atlas lesen konnte, sind aus
security-banner-readable-off-message = Prüfen Sie die übrigen Schalter in der Windows-Sicherheit.
security-banner-on-title = Virenschutz vorübergehend ausschalten
security-banner-on-message = Diese Schutzfunktionen können die Änderungen blockieren, die Atlas vornehmen muss.
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
security-unknown-message = Wenn Sie in der Windows-Sicherheit geprüft haben, dass alle vier Schalter aus sind, bestätigen Sie das unten.
security-acknowledge = Ich habe in der Windows-Sicherheit nachgesehen und alle vier Schalter sind aus
security-unknown-unelevated-title = Atlas benötigt eine Berechtigung, um den Schutz zu prüfen
security-unknown-unelevated-message = Führen Sie Atlas als Administrator aus, damit es die Einstellungen von Microsoft Defender lesen kann.
# The four switches, named as the German Windows Security app names them.
protection-tamper = Manipulationsschutz
protection-tamper-why = Muss zuerst aus sein, damit Defender Änderungen an seinen Schutzeinstellungen zulässt.
protection-realtime = Echtzeitschutz
protection-realtime-why = Muss aus sein, damit die Dateiprüfung pausiert und Defender die Atlas-Installationsdateien nicht blockiert.
protection-cloud = Cloudbasierter Schutz
protection-cloud-why = Muss aus sein, damit keine Online-Bedrohungsprüfung die Atlas-Installationsdateien blockiert.
protection-samples = Automatische Übermittlung von Beispielen
protection-samples-why = Muss aus sein, damit Defender Atlas-Dateien nicht automatisch zur Analyse an Microsoft sendet.

## Step 4: Install

install-preparing-title = Eine letzte Prüfung vor der Installation
install-preparing-message = Atlas prüft Ihren PC und die Schutzeinstellungen noch einmal, bevor Änderungen vorgenommen werden.
install-installing = Wird installiert
install-running = Läuft
# Accessible name of the progress bar.
install-progress = Installationsfortschritt
phase-preflight = PC wird geprüft und Dateien werden vorbereitet
phase-staging = Installationsdateien werden bereitgestellt
phase-applying = Windows wird eingerichtet. Lassen Sie Ihren PC eingeschaltet.
phase-done = Einrichtung wird abgeschlossen
outcome-succeeded-title = Atlas ist installiert
outcome-lost-title = Installationsergebnis konnte nicht bestätigt werden
outcome-failed-title = Installation nicht abgeschlossen
outcome-succeeded = Starten Sie Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
outcome-requirements = Ihr PC hat die Voraussetzungen für die Installation nicht erfüllt. An Ihrem PC wurde nichts geändert. Gehen Sie zurück zu „Vorbereiten“ und führen Sie die Prüfungen erneut aus.
outcome-not-elevated = An Ihrem PC wurde nichts geändert. Führen Sie Atlas als Administrator aus und versuchen Sie es erneut.
outcome-failed-preflight = Die Installation ist abgebrochen, bevor etwas geändert wurde. Öffnen Sie die Protokolldatei, um die Ursache zu sehen, und versuchen Sie es dann erneut.
outcome-failed-staging = Die Installation ist beim Vorbereiten der Dateien abgebrochen, bevor Windows geändert wurde. Öffnen Sie die Protokolldatei, um die Ursache zu sehen, und versuchen Sie es dann erneut.
outcome-failed-applying = Einige Änderungen wurden möglicherweise bereits vorgenommen. Wenn Sie hier aufhören, schalten Sie die zuvor ausgeschalteten Schutzfunktionen in der Windows-Sicherheit wieder ein, sofern sie noch verfügbar sind.
outcome-not-started = Das Installationsprogramm ist nicht rechtzeitig gestartet. An Ihrem PC wurde nichts geändert. Wählen Sie „Erneut versuchen“.
outcome-lost = Das Installationsprogramm wurde beendet, ohne ein Ergebnis zu melden; einige Änderungen wurden möglicherweise bereits vorgenommen. Öffnen Sie die Protokolldatei, um die Ursache zu sehen, und wählen Sie dann „Erneut versuchen“, um die Installation fortzusetzen.
restart-now-message = Windows wird neu gestartet, um die Einrichtung von Atlas abzuschließen.
restart-countdown =
    { $seconds ->
        [one] Windows startet in { $seconds } Sekunde neu, damit Atlas die Einrichtung abschließen kann.
       *[other] Windows startet in { $seconds } Sekunden neu, damit Atlas die Einrichtung abschließen kann.
    }
restart-stopped = Automatischer Neustart abgebrochen. Speichern Sie Ihre Arbeit und starten Sie dann Ihren PC neu, um die Einrichtung von Atlas abzuschließen.
restart-needed = Speichern Sie Ihre Arbeit und starten Sie dann Windows neu, um die Einrichtung von Atlas abzuschließen.
restart-dont-now = Später neu starten
restart-now = Jetzt neu starten
# Accessible name of the countdown bar.
restart-progress = Zeit bis zum Neustart
restart-start-failed = Windows konnte nicht neu gestartet werden. Speichern Sie Ihre Arbeit und starten Sie Ihren PC dann über das Startmenü neu. Details: { $error }
preflight-title = Installation wurde nicht gestartet
preflight-invalid-options = Atlas konnte diese Auswahl nicht verwenden. Gehen Sie zurück zu „Ihre Auswahl“, überprüfen Sie sie und versuchen Sie es dann erneut. Details: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Der Zustand Ihres PCs hat sich seit den letzten Prüfungen geändert. Beheben Sie Folgendes, bevor Sie es erneut versuchen. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 noch eingeschaltet".
preflight-security = Windows-Sicherheit: { $summary }.
preflight-busy = Ein anderes Atlas-Fenster startet gerade eine Installation. Warten Sie einen Moment und versuchen Sie es dann erneut.
preflight-record-unreadable = Atlas konnte nicht prüfen, ob die vorherige Installation noch läuft, und hat deshalb keine neue gestartet. Schließen Sie Atlas und öffnen Sie es erneut, um Hinweise zur Wiederherstellung zu erhalten. Details: { $error }
preflight-refused = Das Installationsprogramm konnte nicht gestartet werden. An Ihrem PC wurde nichts geändert. Details: { $error }
go-to-ready = Zurück zu „Vorbereiten“
go-to-options = Zurück zu „Ihre Auswahl“
output-problem-title = Installationsfortschritt konnte nicht gelesen werden
output-problem-message = Atlas konnte das Protokoll nicht lesen. Das bedeutet nicht, dass die Installation gestoppt wurde. Lassen Sie Ihren PC eingeschaltet und versuchen Sie, die Protokolldatei zu öffnen. Details: { $error }
install-elevate-title = Atlas benötigt eine Berechtigung für die Installation
install-no-package-title = Wählen Sie zuerst Ihre Installationsdateien
install-no-package-message = Gehen Sie zurück zu „Vorbereiten“, um Atlas herunterzuladen oder ein gespeichertes Playbook (.apbx) zu öffnen.
install-security-title = Virenschutz vor der Installation prüfen
install-security-reading = Die vier Schutzschalter werden noch einmal geprüft.
install-security-message = { $summary }. Öffnen Sie die Windows-Sicherheit und stellen Sie sicher, dass alle vier Schalter aus sind, bevor Sie fortfahren.
summary-this-install = Installationsübersicht
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
summary-command-unavailable = Der Installationsbefehl konnte nicht erstellt werden. Details: { $error }
summary-not-chosen = Noch nicht gewählt
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } ändern
footer-still-checking = Installation wird vorbereitet
footer-fix-items = Schließen Sie die Prüfungen oben ab, um fortzufahren
footer-need-package = Laden Sie Atlas herunter oder öffnen Sie ein Playbook, um fortzufahren
footer-reading-security = Schutzschalter werden geprüft
button-checking = Wird geprüft
button-installing = Wird installiert
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

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } ist installiert
installed-title = Atlas ist installiert
installed-ready = Alles erledigt. Ihr PC ist mit Atlas einsatzbereit.
installed-open-atlas = Atlas-Installation ansehen

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
# Under "Wie Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Bei „Wie Windows“: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Vorschau · sprachliche Prüfung steht noch aus
preview-notice = { $language } ist eine Vorschau-Übersetzung.
preview-notice-switch = Zu Englisch wechseln
preview-notice-language = Sprache ändern
# $tag is a language tag (text).
settings-language-unavailable = { $tag } ist in dieser Version von Atlas nicht verfügbar. Vorerst wird Englisch angezeigt; Ihre Sprachauswahl bleibt gespeichert.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas unterstützt Ihre Windows-Anzeigesprachen ({ $languages }) noch nicht. Vorerst wird Englisch angezeigt.
settings-language-windows-unavailable = Ihre Windows-Anzeigesprache konnte nicht ermittelt werden. Atlas verwendet vorerst Englisch. Details: { $error }
# $locale is the regional format's own name, for example "Deutsch (Deutschland)".
settings-language-formats = Zahlen, Datum und Uhrzeit folgen Ihrem regionalen Format in Windows ({ $locale }).
settings-language-contribute = Beim Übersetzen von Atlas auf GitHub helfen
settings-installing = Installation
settings-restart-label = PC nach der Installation automatisch neu starten
settings-restart-locked = Sie können das ändern, sobald die Installation abgeschlossen ist.
settings-restart-description = Zum Abschluss der Einrichtung ist ein Neustart nötig. Speichern Sie Ihre Arbeit vor der Installation, wenn der automatische Neustart eingeschaltet ist.
settings-about = Info
settings-about-app = Atlas Manager
settings-about-data = App-Dateien
settings-about-licence = Lizenz
settings-about-licence-value = GPL-3.0, kostenlos und Open Source
settings-view-source = Quellcode auf GitHub ansehen
settings-open-data-folder = App-Ordner öffnen

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Gibt den Speicherplatz frei, in dem Ihre Sitzung im Ruhezustand gespeichert wird. Ruhezustand und Schnellstart stehen dann nicht mehr zur Verfügung.
consequence-disable-power-saving = Schaltet Energiesparfunktionen aus. Ihr PC verbraucht dann möglicherweise mehr Strom, wird wärmer und hält im Akkubetrieb kürzer durch.
consequence-disable-core-isolation = Schaltet eine zusätzliche Sicherheitsebene von Windows aus, einschließlich der Speicherintegrität. Das verringert den Schutz und kann Apps oder Spiele beeinträchtigen, die darauf angewiesen sind.
consequence-remove-snipping-tool = Entfernt die Windows-App für Screenshots und Bildschirmaufnahmen.
consequence-uninstall-edge = Entfernt den Browser Microsoft Edge. Stellen Sie sicher, dass Sie einen anderen Browser haben, oder wählen Sie unten einen aus.
consequence-install-another-browser = Wählen Sie unten einen Browser aus; Atlas installiert ihn für Sie.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas passt Windows so an, dass weniger im Hintergrund läuft und weniger ablenkt. Wir führen Sie durch alle Prüfungen und Entscheidungen, bevor Änderungen vorgenommen werden.

detail-build-missing = Dieses Playbook gibt keine unterstützten Windows-Builds an. Wählen Sie ein vollständiges Playbook statt eines LocalTest-Pakets.
## ISO creation (Beta)
iso-home-title = Windows-Installationsmedium
iso-home-description = Erstellen Sie eine Windows-ISO mit Atlas für eine Neuinstallation auf diesem oder einem anderen PC.
iso-open = Atlas-ISO erstellen
iso-title = Atlas-ISO erstellen
iso-beta = Beta
iso-beta-description = Testen Sie die ISO in einer virtuellen Maschine, bevor Sie sie auf einem PC verwenden. Sichern Sie Ihre Dateien, bevor Sie Windows installieren.
iso-admin-description = Zum Lesen von Windows-Abbildern und Erstellen von Installationsmedien sind Administratorrechte erforderlich.
iso-files-description = Wählen Sie eine unveränderte Windows-11-ISO für x64, ein Atlas-Playbook (.apbx) und einen neuen Dateinamen für das Ergebnis.
iso-source = Windows-ISO
iso-package = Atlas-Playbook (0.6+)
iso-output = Neue ISO speichern unter
iso-no-file = Keine Datei ausgewählt
iso-browse = Durchsuchen
iso-save-as = Speichern unter
iso-inspect = Dateien prüfen
iso-mode-title = Windows- und Atlas-Einstellungen
iso-mode-interactive = Atlas-Einstellungen nach der Anmeldung wählen
iso-mode-interactive-description = Nach der Anmeldung hilft Ihnen Atlas, Windows und die Store-Apps zu aktualisieren, Ihre Einstellungen zu wählen und Atlas anzuwenden.
iso-mode-before = Atlas-Einstellungen jetzt wählen
iso-mode-before-description = Speichern Sie Ihre Atlas-Einstellungen in der ISO. Aktualisieren Sie nach der Anmeldung Windows und die Store-Apps und wenden Sie Atlas mit diesen Einstellungen an.
iso-package-unsupported-title = Neueres Playbook wählen
iso-package-unsupported = Für die ISO-Einrichtung wird Atlas 0.6 oder neuer mit ISO-Unterstützung benötigt. Wählen Sie ein kompatibles Playbook.
iso-atlas-options = Atlas-Einstellungen
iso-review = ISO überprüfen
iso-review-title = Bereit zum Erstellen Ihrer ISO
iso-editions = Enthaltene Editionen: { $editions }
iso-source-size = Quell-ISO: { $size } MB
iso-review-description = Atlas erstellt eine neue ISO. Die ursprüngliche Datei bleibt erhalten. Starten Sie von der neuen ISO, um Windows zu installieren. Beim Erstellen wird Atlas nicht auf diesem PC installiert.
iso-create = ISO erstellen
iso-stage-inspect = Windows-Abbild wird geprüft
iso-stage-copy = Windows-Dateien werden kopiert
iso-stage-inject = Atlas wird hinzugefügt
iso-stage-master = ISO wird erstellt
iso-stage-verify = Ergebnis wird überprüft
iso-stage-cleanup = Wird abgeschlossen
iso-progress-description = Lassen Sie die App geöffnet. Die Verarbeitung großer Abbilder kann einige Zeit dauern.
iso-cancel = Erstellung abbrechen
iso-cancelling = Warten auf einen sicheren Abbruchpunkt
iso-cancelled = ISO-Erstellung abgebrochen
iso-cancelled-description = Ihre ursprüngliche ISO bleibt erhalten. Im Diagnoseprotokoll steht, ob noch temporäre Dateien entfernt werden müssen.
iso-complete = Ihre ISO ist fertig
iso-complete-description = Testen Sie die ISO in einer virtuellen Maschine und erstellen Sie damit anschließend ein Windows-Installationsmedium.
iso-open-folder = Im Ordner anzeigen
iso-failed = ISO-Erstellung konnte nicht abgeschlossen werden
iso-failed-description = Öffnen Sie die Diagnose, um die Ursache zu sehen. Beheben Sie das Problem und versuchen Sie es mit einem neuen Dateinamen erneut.
iso-diagnostics = Diagnose öffnen
iso-close-title = Die ISO wird noch erstellt
iso-close-message = Lassen Sie dieses Fenster geöffnet, bis die Erstellung oder der Abbruch abgeschlossen ist. Beim Abbrechen wird gewartet, bis der laufende Vorgang sicher beendet werden kann.
iso-keep-open = Geöffnet lassen
prepare-title = Windows und Store-Apps aktualisieren
prepare-description = Installieren Sie vor Atlas die Windows-Updates und aktualisieren Sie den Microsoft Store sowie alle installierten Store-Apps. Store-Apps können beim Aktualisieren geschlossen werden.
prepare-complete = Windows und die Store-Apps sind auf dem neuesten Stand.
prepare-reboot = Windows muss neu gestartet werden. Ihre Atlas-Auswahl wird gespeichert. Suchen Sie nach der Anmeldung erneut nach Updates.
prepare-failed = Einige Updates konnten nicht abgeschlossen werden. Prüfen Sie das Diagnoseprotokoll, beheben Sie Fehler in Windows oder im Store und versuchen Sie es erneut.
prepare-cancelled = Die Vorbereitung wurde angehalten. Suchen Sie vor dem Fortfahren erneut nach Updates.
prepare-windows-search = Windows Update wird geprüft…
prepare-windows-download = Windows-Updates werden heruntergeladen…
prepare-windows-install = Windows-Updates werden installiert…
prepare-store-search = Microsoft Store wird geprüft…
prepare-store-install = Microsoft Store und seine Apps werden aktualisiert…
prepare-stop-description = Zum Anhalten muss der laufende Updatevorgang abgeschlossen werden. Lassen Sie Atlas bis dahin geöffnet.
prepare-stop = Nach diesem Vorgang anhalten
prepare-restart = Neu starten und fortfahren
prepare-start = Updates suchen und installieren
iso-username = Name des lokalen Kontos
iso-account-description = Nach der Neuinstallation fordert Windows Sie auf, ein Kennwort festzulegen.
iso-username-placeholder = Ihr Name
iso-account-invalid = Verwenden Sie 1–20 Zeichen ohne Leerzeichen am Anfang oder Ende und ohne unzulässige Zeichen für Windows-Kontonamen.
iso-privacy-defaults = Windows deaktiviert bei der Einrichtung automatisch die optionale Datenfreigabe und personalisierte Angebote.
prepare-drivers = Wie sollen Treiber installiert werden?
prepare-drivers-auto = Treiber über Windows Update beziehen
prepare-drivers-auto-detail = Windows sucht passende Treiber für Ihre Hardware. Für die meisten PCs empfohlen.
prepare-drivers-manual = Treiber selbst installieren
prepare-drivers-manual-detail = Treiberdownloads über Windows Update werden blockiert. Sie müssen Treiber selbst beschaffen; vorhandene Treiber bleiben installiert.
prepare-network-needed = Verbinden Sie sich über ein nicht getaktetes WLAN oder Ethernet und versuchen Sie es erneut. Fehlt WLAN, installieren Sie zuerst den Netzwerktreiber.
prepare-network-settings = Netzwerkeinstellungen öffnen
iso-target-title = Auf welchem PC möchten Sie Windows neu installieren?
iso-target-this = Auf diesem PC
iso-target-other = Auf einem anderen PC
iso-copy-network = Netzwerktreiber dieses PCs einbinden
iso-network-detail = Verwendet die WLAN- und Ethernet-Treiber dieses PCs bei der Windows-Installation. Verbinden Sie sich danach erneut mit dem WLAN.
iso-network-source = Quelle der Netzwerktreiber
iso-network-installed = Installierte Treiber verwenden
iso-network-updated = Zuerst bei Windows Update suchen
iso-network-updated-detail = Lädt passende Treiber von Windows Update herunter und behält installierte Treiber als Reserve. Erfordert eine nicht getaktete Verbindung.
iso-stage-network-drivers = Netzwerktreiber werden vorbereitet…
iso-network-failed = Die Netzwerktreiber konnten nicht vorbereitet werden. Prüfen Sie die Diagnoseinformationen oder gehen Sie zurück und ändern Sie die Netzwerktreiberoption.
iso-mode-desktop = Einrichtung vor dem Desktop abschließen
iso-mode-desktop-description = Wählen Sie die Atlas-Einstellungen jetzt. Nach der Anmeldung schließen Sie Updates und die Atlas-Einrichtung ab, bevor der Windows-Desktop geöffnet wird.
desktop-setup-description = Schließen Sie die Einrichtung Ihres PCs ab. Ihre Atlas-Auswahl ist gespeichert. Bei Bedarf können Sie zu Windows wechseln.
desktop-setup-exit = In Windows fortfahren

# Windows installation USB (Beta)
usb-title = Installations-USB erstellen
usb-existing = USB aus einer vorhandenen ISO erstellen
usb-description = Erstellen Sie einen startfähigen USB-Stick für Windows 11 25H2, um Windows und Atlas auf Ihrem PC zu installieren.
usb-choose-iso = ISO auswählen
usb-drive = USB-Laufwerk
usb-empty = Schließen Sie ein USB-Laufwerk an und aktualisieren Sie die Liste. Angezeigt werden nur beschreibbare USB-Laufwerke ohne die laufende Windows-Installation.
usb-refresh = Aktualisieren
usb-drive-detail = { $size } GB · { $volumes } · Seriennummer: { $serial }
usb-review = USB-Auswahl prüfen
usb-erase-title = Dieses USB-Laufwerk löschen?
usb-erase-description = Alle Dateien und Partitionen auf { $drive } ({ $size } GB) werden dauerhaft gelöscht. Ihre ISO bleibt erhalten.
usb-layout = Die Windows-Installation belegt bis zu 32 GB. Verbleibender Speicher bleibt nicht zugeordnet. Der USB-Stick ist für PCs mit UEFI vorgesehen.
usb-ack = Mir ist bewusst, dass der gesamte Inhalt dieses USB-Laufwerks gelöscht wird.
usb-write = Löschen und USB erstellen
usb-stage-prepare = Installationsdateien werden vorbereitet…
usb-stage-format = USB wird formatiert…
usb-stage-copy = Installationsdateien werden kopiert…
usb-stage-verify = USB wird überprüft…
usb-working = Lassen Sie Atlas geöffnet und das USB-Laufwerk angeschlossen. Beim Abbrechen wird auf einen sicheren Haltepunkt gewartet. Ein unfertiger USB-Stick eignet sich nicht zur Windows-Installation.
usb-failed = Der USB-Stick konnte nicht fertiggestellt werden. Prüfen Sie die Verbindung und öffnen Sie die Diagnose. Wählen Sie das Laufwerk für einen neuen Versuch erneut aus.
usb-cancelled = Die USB-Erstellung wurde angehalten. Das Laufwerk enthält möglicherweise unvollständige Installationsdateien. Erstellen Sie es vor der Windows-Installation erneut.
usb-complete = Ihr USB-Stick ist bereit. Alle Dateien wurden überprüft. Werfen Sie ihn aus, schließen Sie ihn am Ziel-PC an und wählen Sie ihn im UEFI-Startmenü aus.
usb-eject = USB auswerfen
usb-ejected = Sie können das USB-Laufwerk sicher entfernen. Wählen Sie es im UEFI-Startmenü Ihres PCs aus, um Windows zu installieren.
usb-eject-failed = Windows konnte das USB-Laufwerk nicht auswerfen. Schließen Sie geöffnete Dateien und Fenster auf dem Laufwerk und versuchen Sie es erneut.
ready-fresh-title = Beginnen Sie mit einer Neuinstallation von Windows
ready-fresh-description = Atlas erfordert eine Neuinstallation von Windows, außer bei unterstützten Atlas-Upgrades. Für eine Neuinstallation von Atlas 0.6 ist Windows 11 25H2 erforderlich. Sichern Sie Ihre Dateien, bevor Sie Windows neu installieren.
detail-edition-unsupported = Verwenden Sie Windows 11 Pro, Pro for Workstations oder Enterprise. Home, LTSC und Server werden nicht unterstützt. Wenn Ihre Edition nicht erkannt wurde, klären Sie dies vor dem Fortfahren.
install-source-title = Installation nicht möglich
install-source-unsupported = Atlas { $source } kann nicht direkt auf { $target } aktualisiert werden. Installieren Sie Windows neu, um diese Version zu verwenden.
install-source-unknown = Atlas konnte den Installationsstatus nicht prüfen. Beheben Sie Probleme mit ausstehenden Installationen und prüfen Sie die Diagnose, bevor Sie es erneut versuchen.
iso-edition-selection = Es werden nur unterstützte Editionen übernommen. Wählen Sie bei der Windows-Installation eine Edition, für die Sie eine Windows-Lizenz haben.
detail-windows-preview = Insider-Builds werden nicht unterstützt. Verwenden Sie eine regulär veröffentlichte Version von Windows 11.
detail-windows-release-unknown = Atlas konnte nicht bestätigen, dass dieser Windows-Build regulär veröffentlicht wurde. Stellen Sie eine Internetverbindung her und prüfen Sie erneut.
iso-release-unknown = Atlas konnte nicht bestätigen, dass diese ISO eine regulär veröffentlichte Version von Windows 11 25H2 enthält. Stellen Sie eine Internetverbindung her und versuchen Sie es erneut, oder wählen Sie ein offizielles Installationsmedium.
prepare-previous-worker = Ein zuvor gestarteter Updatevorgang läuft noch. Atlas wartet, bis er abgeschlossen ist. Danach können Sie es erneut versuchen.

ready-used-windows-title = Installiere Windows neu, bevor du fortfährst
ready-used-windows-description = Diese Windows-Installation zeigt Spuren früherer Nutzung. Atlas hier zu installieren wird nicht unterstützt; davon wird dringend abgeraten. Fahre nur fort, wenn du die Risiken verstehst.
ready-used-windows-dismiss = Ich verstehe die Risiken
playbook-option-install-eclean = eclean installieren
consequence-install-eclean = Ein Wartungstool vom Team hinter AtlasOS, mit dem Sie Ihren PC nach der Einrichtung aufräumen können. Prüfen Sie überflüssige Dateien und Autostart-Apps. Erfordert ein Konto und eine Internetverbindung.
