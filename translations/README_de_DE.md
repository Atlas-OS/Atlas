⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Lizenz" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF&label=Lizenz"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Mitwirkende" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=Mitwirkende" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Aktuelle Version" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=Aktuelle Version" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Release Downloads" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
      </a>
  </p>
<h4 align="center">Ein offenes und transparentes Windows-Betriebssystem, das zur Optimierung von Leistung, Privatsphäre und Stabilität entwickelt wurde.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Dokumentation</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Was ist Atlas?**
Atlas ist eine modifizierte Version von Windows 10, welche alle negativen Nachteile von Windows beseitigt, die sich negativ auf die Spieleleistung auswirken. Atlas ist auch eine gute Option um System-, Netzwerk- und Eingabelatenzen zu verringern, aber dennoch dein System sicher zu halten während der Fokus auf der Leistung liegt.
Auf unserer [Website](https://atlasos.net) kannst du mehr über Atlas erfahren.

## 📚 **Inhaltsverzeichnis**

- [Contribution Guidelines](https://docs.atlasos.net/contributions)

- Getting Started
  - [Installation](https://docs.atlasos.net/getting-started/installation)
  - [Other installation methods](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Post-Installation](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Common Issues](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Warum Atlas?**

### 🔒 Mehr Privatsphäre
Normales Windows enthält Tracking-Dienste, die deine Daten sammeln und sie zu Microsoft hochladen.
Atlas entfernt alle Arten von Tracking, die in Windows eingebettet sind, und implementiert zahlreiche Gruppenrichtlinien, um die Datenerfassung zu minimieren.

Was außerhalb des Bereichs von Windows liegt, können wir jedoch hinsichtlich des Datenschutzes nicht verbessern, wie zum Beispiel Websites, die Sie besuchen oder Programme von Drittherstellern.

### 🛡️ Mehr Sicherheit (gegenüber benutzerdefinierten Windows-ISOs)
Eine veränderte Windows ISO aus dem Internet herunterzuladen ist riskant. Nicht nur können Personen einfach eine der vielen binären/ausführbaren Dateien, die in Windows enthalten sind, böswillig ändern, sie enthält möglicherweise nicht die neuesten Sicherheitsupdates, was ein Sicherheitsrisiko für deinen Computer darstellt.

Atlas ist anders. Wir benutzen [AME Wizard](https://ameliorated.io) um Atlas zu installieren und alle unsere Skripte sind Open-Source hier in unserem Repository zu finden. Du kannst das gepackte Atlas-Playbook (`.apbx` - AME Wizard script package) als Archiv anschauen, indem du `malte` (das Standardpasswort für AME Wizard Playbooks) als Passwort verwendest, damit Antiviruse es nicht fälschlicherweise Weise als Virus erkennen.

Die einzigen ausführbaren Dateien, die im Playbook enthalten sind, sind Open-Sourced [hier](https://github.com/Atlas-OS/Atlas-Utilities) unter [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), wobei die Hashes mit denen aus dem neustem Release (der neusten Atlas-Version) übereinstimmen. Alles andere ist im Klartext.

Du kannst auch alle neusten Sicherheitsupdates anwenden bevor du Atlas installierst um dein System sicher und geschützt zu halten.

Bitte beachte, das mit Atlas v0.2.0, Atlas größtenteils **nicht so sicher wie normales Windows ist**, aufgrund von entfernten/deaktivieten Sicherheitsfunktionen, wie z.B Windows Defender. Allerdings werden in Atlas v0.3.0 die meisten Funktionen als optionale Funktionen hinzugefügt. Schau [hier](https://docs.atlasos.net/troubleshooting/removed-features/) für mehr Informationen.

### 🚀 Mehr Speicherplatz
Vorinstallierte Anwendungen und andere Komponenten wurden entfernt. Trotz möglicher Kompatibilitätsprobleme wird dadurch die Installationsgröße erheblich verringert und das System läuft flüssiger. Aus diesem Grund sind bestimmte Funktionen wie Windows Defender usw. vollständig entfernt.
Was wir sonst noch entfernt haben, finden Sie in unserem [FAQ](https://docs.atlasos.net/troubleshooting/removed-features/).

### ✅ Mehr Leistung
Einige optimierte Systeme im Internet haben Windows zu viel optimiert und zerstören die Kompatibilität von Standard-Funktionen wie Bluetooth, Wi-Fi usw. Atlas ist im Sweet-Spot. Es zielt darauf ab, mehr Leistung zu erzielen, aber dennoch ein gutes Level an Kompatibilität beizubehalten.

Einige der vielen Änderungen, die wir vorgenommen haben, um Windows zu optimieren, sind unten aufgeführt:
- Individuelles Energieschema
- Reduzierte Anzahl von Diensten und Treibern
- Deaktivierung des exklusiven Audios
- Deaktivierung nicht benötigter Geräte
- Deaktivierung des Energiesparmodus (für Desktop-Computer)
- Deaktivierung leistungsintensiver Sicherheitsfunktionen
- Automatisch aktivierter MSI-Modus auf allen Geräten
- Optimierung der Boot-Konfiguration
- Optimierte Prozessplanung

### 🔒 Legal
Viele benutzerdefinierte Windows-Versionen verteilen veränderte ISO-Dateien von Windows. Das verletzt nicht nur die [Nutzungsbedingungen von Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), es ist auch kein sicherer Weg der Installation.

Atlas hat sich mit dem Windows Ameliorated Team zusammengeschlossen, um Nutzern einen sicheren und legalen Weg der Installation zu ermöglichen: der [AME Wizard](https://ameliorated.io). Mit diesem hält sich Atlas vollständig an die [Nutzungsbedingungen von Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Branding-Kit
Möchten Sie Ihr eigenes Atlas-Hintergrundbild erstellen? Vielleicht mit unserem Logo herumspielen, um Ihr eigenes Design zu entwerfen? Usere Branding-Kit ist für die Öffentlichkeit frei zugänglich. Wir freuen uns über neue kreative Ideen der Gemeinschaft. [Sehen Sie sich unser Branding-Kit an und machen Sie etwas Spektakuläres.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

Wir haben auch einen eigenen Bereich in unserem [Forum](https://forum.atlasos.net/t/art-showcase), damit du deine Kreationen mit anderen kreativen Genies teilen kannst und vielleicht etwas Inspiration findest.

## ⚠️ Disclaimer (Haftungsausschluss)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (Beitragende zur Übersetzung)
[DedBash](https://github.com/DedBash/) |
[GhostZero](https://github.com/ghostzero/) |
[Alino001](https://github.com/Alino001) |
[Mahele](https://github.com/leonmartinhess)