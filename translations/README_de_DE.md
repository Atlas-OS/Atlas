⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net" target="_blank"><img src="/img/github-banner.png" alt="Atlas" width="800"></a>
</h1>
  <p align="center">
    <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
  </p>
<p align="center">Eine offene und leichtgewichtige Modifikation von Windows, die Leistung, Datenschutz und Sicherheit optimieren soll.</p>

<p align="center">
  <a href="https://atlasos.net" target="_blank">🌐 Website</a>
  •
  <a href="https://docs.atlasos.net" target="_blank">📚 Dokumentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">☎️ Discord</a>
  •
  <a href="https://forum.atlasos.net" target="_blank">💬 Forum</a>
</p>

## 📚 **Inhaltsverzeichnis**

- [Contribution Guidelines](https://docs.atlasos.net/contributions/)
- [Installation](https://docs.atlasos.net/getting-started/installation/)

- Post Installation
  - [Atlas folder](https://docs.atlasos.net/getting-started/post-installation/atlas-folder/configuration/)
  - [Drivers](https://docs.atlasos.net/getting-started/post-installation/drivers/getting-started/)

- Troubleshooting
  - [FAQ & Common Issues](https://docs.atlasos.net/faq-and-troubleshooting/removed-features/)
  - [Scripts](https://docs.atlasos.net/faq-and-troubleshooting/atlas-folder-scripts/)

## 🤔 **Was ist Atlas?**

Atlas ist eine modifizierte Version von Windows, welche nahezu alle Nachteile von Windows beseitigt, die sich negativ auf die Spieleleistung auswirken.
Atlas ist auch eine gute Option, um System- , Netzwerk- und Eingabelatenzen zu reduzieren und dein System privat zu halten, während der Fokus auf der Leistung liegt.
Auf unserer offiziellen [Website](https://atlasos.net) kannst du mehr über Atlas erfahren.

## 👀 **Warum Atlas?**

### 🔒 Mehr Privatsphäre
Standard-Windows enthält Tracking-Dienste, die deine Daten sammeln und sie zu Microsoft hochladen.
Atlas entfernt alle Arten von Tracking, die in Windows eingebettet sind, und implementiert zahlreiche Gruppenrichtlinien, um die Datenerfassung zu minimieren.

Beachte, dass Atlas die Sicherheit für Dinge außerhalb des Bereichs von Windows (wie Browser und andere Anwendungen von Drittanbietern) nicht gewährleisten kann.

### 🛡️ Mehr Sicherheit (gegenüber benutzerdefinierten Windows-ISOs)
Das Herunterladen einer modifizierten Windows-ISO aus dem Internet ist riskant. Nicht nur können Personen leicht eine der vielen binären/ausführbaren Dateien, die in Windows enthalten sind, böswillig verändern, sondern es fehlen möglicherweise auch die neuesten Windows-Sicherheitspatches, was ein ernstes Sicherheitsrisiko für Ihren Computer darstellen kann.

Atlas verfügt außerdem über die folgenden optionalen Sicherheitsfunktionen, die bei anderen benutzerdefinierten Windows-Betriebssystemen fehlen:
- Windows-Sicherheit
  - Windows Defender und SmartScreen (optional)
  - Kernisolierung (optional)
  - CPU-Abschwächungen (optional)
- Windows-Updates (manuell)

Atlas ist anders. Wir verwenden [AME Wizard] (https://ameliorated.io), um Atlas zu instalieren, und alle Skripte, die wir verwenden, sind Open Source hier in unserem GitHub-Repository. Sie können das gepackte Atlas-Playbook (`.apbx` - AME Wizard script package) als Archiv ansehen, mit dem Passwort `malte` (der Standard für AME Wizard-Playbooks), das nur dazu dient, Falschmeldungen von Antivirenprogrammen zu umgehen.

Die einzigen ausführbaren Dateien, die im Playbook enthalten sind, sind [hier](https://github.com/Atlas-OS/utilities) unter [GPLv3](https://github.com/Atlas-OS/utilities/blob/main/LICENSE) als Open Source erhältlich, wobei die Hashes mit den Veröffentlichungen identisch sind. Alles andere ist im Klartext.

### ✅ Improved Performance
Einige optimierte Systeme im Internet haben Windows zu sehr verändert, sodass wichtige Funktionen wie Bluetooth, Wi-Fi usw. nicht mehr kompatibel sind.
Atlas befindet sich auf einem guten Weg. Es zielt darauf ab, mehr Leistung zu erhalten und gleichzeitig ein gutes Maß an Kompatibilität zu wahren.

Einige der vielen Änderungen, die wir zur Verbesserung von Windows vorgenommen haben, sind im Folgenden aufgeführt:
- Angepasster Energiesparplan
- Reduzierte Anzahl an Diensten und Treibern
- Deaktivierung exklusiver Audiofunktionen
- Deaktivierung nicht benötigter Geräte
- Deaktivierung der Energiesparfunktion (für PCs)
- Deaktivierung leistungsintensiver Sicherheitsabschwächungen
- Automatisch aktivierter MSI-Modus auf allen Geräten
- Optimierte Boot-Konfiguration
- Optimierte Prozessplanung

### 🔒 Legal
Viele benutzerdefinierte Windows-Betriebssysteme vertreiben ihre Systeme, indem sie eine modifizierte ISO-Datei von Windows bereitstellen. Dies verstößt nicht nur gegen die [Nutzungsbedingungen von Microsoft] (https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), sondern ist auch keine sichere Installationsmethode.

Atlas hat sich mit dem Ameliorated-Team zusammengetan, um den Benutzern mit [AME Wizard](https://ameliorated.io) eine sicherere und legale Installationsmethode zu bieten. Damit erfüllt Atlas die [Nutzungsbedingungen von Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) vollständig.

## 🎨 Brand kit
Sind Sie kreativ? Möchten Sie Ihre eigenes Atlas-Hintergrundbild mit kreativen Designs entwerfen? Unser Brand Kit bietet Ihnen alles, was Sie brauchen!
Jeder kann auf das Atlas Brand Kit zugreifen - Sie können es [hier](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) herunterladen und etwas Spektakuläres gestalten!

Wir haben auch einen eigenen Bereich in unserem [Forum](https://forum.atlasos.net/t/art-showcase), in dem du deine Kreationen mit anderen Kreativen teilen und dich vielleicht sogar inspirieren lassen kannst! Hier findest du auch kreative Hintergrundbilder, die andere Nutzer teilen!

## ⚠️ Disclaimer (Haftungsausschluss)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-not-pre-activated

## Translation contributors (Beitragende zur Übersetzung)
[DedBash](https://github.com/DedBash) |
[GhostZero](https://github.com/ghostzero) |
[Alino001](https://github.com/Alino001) |
[Mahele](https://github.com/leonmartinhess) |
[elNino0916](https://github.com/elNino0916) |
[A-Loot](https://github.com/A-Loot)
