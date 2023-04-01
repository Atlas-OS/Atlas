## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Ein offenes und transparentes Windows-Betriebssystem, das zur Optimierung von Leistung und Latenzzeit entwickelt wurde.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net/FAQ/Installation/">FAQ</a>
  •
  <a href="https://discord.com/invite/atlasos" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Was ist Atlas?**

Atlas ist eine modifizierte Version von Windows 10, welche alle negativen Nachteile von Windows beseitigt, die sich negativ auf die Spieleleistung auswirken. Wir sind ein transparentes und quelloffenes Projekt, dass die Gleichberechtigung der Spieler anstrebt, unabhängig davon, ob Sie einen Schlechten- oder einen Gaming-PC verwenden.

Obwohl unser Hauptthema auf der Leistung liegt, sind wir auch eine hervorragende Option zur Reduzierung von System- und Netzwerklatenz, Eingabeverzögerung und zum Schutz Ihrer Privatsphäre.

You can learn more about Atlas in our official [Website](https://atlasos.net).

## 📚 **Table of contents**

- FAQ
  - [Install](https://docs.atlasos.net/FAQ/Installation/)
  - [Contribute](https://docs.atlasos.net/FAQ/Contribute/)

- Getting Started
  - [Installation](https://docs.atlasos.net/Getting%20started/Installation/)
  - [Other install methods](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [Post Install](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [Scripts](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Branding kit](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

## Windows vs. Atlas

### 🔒 Privatsphäre
Atlas entfernt alle Arten von Tracking, die in Windows eingebettet sind, und implementiert zahlreiche Gruppenrichtlinien, um die Datenerfassung zu minimieren. Was außerhalb des Bereichs von Windows liegt, können wir jedoch nicht hinsichtlich des Datenschutzes verbessern, wie zum Beispiel Websites, die Sie besuchen.

### 🛡️ Sicherheit
Atlas strebt danach, so sicher wie möglich zu sein, ohne Leistungseinbußen zu haben. Dies tun wir, indem wir Funktionen deaktivieren, die Informationen preisgeben oder ausgenutzt werden können. Ausnahmen hiervon sind zum Beispiel [Spectre](https://spectreattack.com/spectre.pdf) und [Meltdown](https://meltdownattack.com/meltdown.pdf). Diese Schutzmaßnahmen werden deaktiviert, um die Leistung zu verbessern.

 Wenn eine Sicherheitsmaßnahme die Leistung beeinträchtigt, wird sie deaktiviert. 
 Unten finden Sie einige Funktionen/Schutzmaßnahmen, die geändert wurden, wenn sie ein (P) enthalten, sind es Sicherheitsrisiken, die behoben wurden:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Mögliche Informationsbeschaffung*)

### 🚀 Debloated
Atlas ist sehr stark zerlegt. Vorinstallierte Anwendungen und andere Komponenten wurden entfernt. Trotz möglicher Kompatibilitätsprobleme wird dadurch die ISO- und Installationsgröße erheblich verringert. Funktionen wie Windows Defender usw. wurden vollständig entfernt. 

Diese Änderungen sind auf Gaming ausgerichtet, aber die meisten Arbeits- und Bildungsanwendungen funktionieren. [Was wir sonst noch entfernt haben, finden Sie in unserer FAQ](https://docs.atlasos.net/Troubleshooting/Removed%20features/).

### ✅ Leistungsstark

Atlas ist voroptimiert. Unter Beibehaltung der Kompatibilität, aber auch in dem Bestreben, die Leistung zu steigern, haben wir jeden einzelnen Tropfen Leistung in unsere Windows-Images gepresst. Einige der vielen Änderungen, die wir zur Verbesserung von Windows vorgenommen haben, sind unten aufgeführt.

- Individuelles Energieschema
- Reduzierte Anzahl von Diensten
- Reduzierte Anzahl von Treibern
- Deaktivierte nicht benötigte Komponenten
- Deaktivierte Energieeinsparungen
- Deaktivierung leistungsintensiver Sicherheitsfunktionen
- Automatisch aktivierter MSI-Modus
- Optimierung der Boot-Konfiguration
- Optimierte Prozessplanung

## 🎨 Branding-Kit

Möchten Sie Ihr eigenes Atlas-Hintergrundbild erstellen? Vielleicht mit unserem Logo herumspielen, um Ihr eigenes Design zu entwerfen? Usere Branding-Kit ist für die Öffentlichkeit frei zugänglich. Wir freuen uns über neue kreative Ideen der Gemeinschaft. [Sehen Sie sich unser Branding-Kit an und machen Sie etwas Spektakuläres.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

We also have a dedicated area on our [Forum](https://forum.atlasos.net/t/art-showcase), so you can share your creations with other creative geniuses and maybe even spark some inspiration! 

## ⚠️ Disclaimer (Haftungsausschluss)

AtlasOS is **NOT** a pre-activated version of Windows, you **must** use a genuine key to run Atlas. Before you buy a Windows 10 (Pro OR Home) license, make sure the seller is trusted and the key is legitimate, no matter where you buy it. Atlas is based on Microsoft Windows, by using Windows you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). 

## Translation contributors (Beitragende zur Übersetzung)

[DedBash](https://github.com/DedBash/) | 
[GhostZero](https://github.com/ghostzero/) | 
[Alino001](https://github.com/Alino001)
