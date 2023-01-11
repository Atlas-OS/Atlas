<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Ein offenes und transparentes Windows-Betriebssystem, das zur Optimierung von Leistung und Latenzzeit entwickelt wurde.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net/">Forum</a>
</p>


# Was ist Atlas?

Atlas ist eine modifizierte Version von Windows, die alle negativen Nachteile von Windows beseitigt, die sich negativ auf die Spieleleistung auswirken. Wir sind ein transparentes und quelloffenes Projekt, das die Gleichberechtigung der Spieler anstrebt, unabhängig davon, ob Sie einen Kartoffel- oder einen Gaming-PC verwenden.

Während unser Hauptaugenmerk auf der Leistung liegt, sind wir auch eine großartige Option, um Systemlatenz, Netzwerklatenz und Eingabeverzögerung zu reduzieren und Ihr System privat zu halten.

## Table of contents

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Was ist das Atlas-Projekt?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Wie kann ich Atlas installieren?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Was wird in Atlas entfernt?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Post Install](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Branding-Kit](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

## Windows vs. Atlas

### **Private**

Atlas entfernt alle Arten von Tracking, die in Windows eingebettet sind, und implementiert zahlreiche Gruppenrichtlinien, um die Datenerfassung zu minimieren. Für Dinge, die nicht in Windows eingebettet sind, können wir den Datenschutz nicht erhöhen, z. B. für Websites, die Sie besuchen.

### **Sicherheit**

Atlas ist bestrebt, so sicher wie möglich zu sein, ohne an Leistung zu verlieren. Wir tun dies, indem wir Funktionen deaktivieren, die Informationen preisgeben oder ausgenutzt werden können. Es gibt Ausnahmen wie [Spectre](https://spectreattack.com/spectre.pdf) und [Meltdown](https://meltdownattack.com/meltdown.pdf). Diese Abhilfemaßnahmen werden deaktiviert, um die Leistung zu verbessern.
Wenn eine Sicherheitsabschwächungsmaßnahme die Leistung verringert, wird sie deaktiviert.
Nachfolgend sind einige Funktionen/Maßnahmen aufgeführt, die geändert wurden. Wenn sie ein (P) enthalten, handelt es sich um Sicherheitsrisiken, die behoben wurden:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Possible Information Retrieval_)

### **Debloated**

Atlas ist stark entschlackt, vorinstallierte Anwendungen und andere Komponenten wurden entfernt. Trotz möglicher Kompatibilitätsprobleme wird dadurch die ISO- und Installationsgröße erheblich verringert. Funktionen wie Windows Defender usw. wurden vollständig entfernt. Diese Änderung ist auf reine Spiele ausgerichtet, aber die meisten Arbeits- und Bildungsanwendungen funktionieren.[Was wir sonst noch entfernt haben, finden Sie in unserer FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Leistung**

Atlas ist voroptimiert. Unter Beibehaltung der Kompatibilität, aber auch in dem Bestreben, die Leistung zu steigern, haben wir jeden einzelnen Tropfen Leistung in unsere Windows-Images gepresst. Einige der vielen Änderungen, die wir zur Verbesserung von Windows vorgenommen haben, sind unten aufgeführt.

- Individuelles Energieschema
- Reduzierte Anzahl von Diensten
- Reduzierte Anzahl von Treibern
- Deaktivierte nicht benötigte Geräte
- Deaktivierte Energieeinsparungen
- Deaktivierung leistungshungriger Sicherheitsabschwächungen
- Automatisch aktivierter MSI-Modus
- Optimierung der Boot-Konfiguration
- Optimierte Prozessplanung

## Branding-Kit

Möchten Sie Ihr eigenes Atlas-Hintergrundbild erstellen? Vielleicht mit unserem Logo herumspielen, um Ihr eigenes Design zu entwerfen? Wir haben dies für die Öffentlichkeit zugänglich gemacht, um neue kreative Ideen in der Gemeinschaft zu wecken. [Sehen Sie sich unser Marken-Kit an und machen Sie etwas Spektakuläres.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Wir haben auch einen [speziellen Bereich auf der Registerkarte Diskussionen](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), damit Sie Ihre Kreationen mit anderen kreativen Genies teilen und sich vielleicht sogar inspirieren lassen können!

## Disclaimer (Haftungsausschluss)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

### Übersetzung Haftungsausschluss

Durch das Herunterladen, Ändern oder Verwenden eines dieser Bilder erklären Sie sich mit [Microsofts Bedingungen](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) einverstanden. Keines dieser Bilder ist voraktiviert, Sie **müssen** einen echten Schlüssel verwenden.

## Translator (Übersetzer)
[DedBash](https://github.com/DedBash/)