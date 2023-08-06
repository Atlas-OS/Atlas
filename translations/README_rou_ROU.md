⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.

<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
    <img alt="Licență" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
  </a>
  <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
    <img alt="Contribuitori" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
  </a>
  <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
    <img alt="Versiune" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
  </a>
  <a href="https://github.com/Atlas-OS/Atlas/releases">
    <img alt="Descărcări ale versiunii" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
  </a>
</p>
<h4 align="center">O modificare deschisă și transparentă a sistemului de operare Windows, concepută pentru a optimiza performanța, confidențialitatea și stabilitatea.</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Documentație</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 Ce este Atlas?

Atlas este o modificare a sistemului de operare Windows, care elimină aproape toate dezavantajele Windows care afectează negativ performanța în jocuri.
Atlas este, de asemenea, o opțiune bună pentru a reduce latența sistemului, latența rețelei, întârzierea la tastatură și pentru a menține confidențialitatea sistemului, concentrându-se pe performanță.
Puteți afla mai multe despre Atlas pe website-ul nostru oficial.

## 📚 Cuprins

- [Ghiduri de contribuție](https://docs.atlasos.net/contributions)

- Începerea lucrului
  - [Instalare](https://docs.atlasos.net/getting-started/installation)
  - [Alte metode de instalare](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [După instalare](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Depanare
  - [Funcționalități eliminate](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripturi](https://docs.atlasos.net/troubleshooting/scripts)

- Întrebări frecvente
  - [Atlas](https://atlasos.net/faq)
  - [Probleme comune](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 De ce Atlas?

### 🔒 Mai multă confidențialitate
Windows-ul standard conține servicii de urmărire care colectează datele dvs. și le încarcă la Microsoft.
Atlas elimină toate tipurile de urmărire încorporate în Windows și implementează numeroase politici de grup pentru a minimiza colectarea de date.

Rețineți că Atlas nu poate asigura securitatea lucrurilor din afara domeniului Windows (cum ar fi browserele și aplicațiile terțe).

### 🛡️ Mai multă securitate (față de ISO-urile personalizate Windows)
Descărcarea unui ISO modificat al Windows de pe internet este periculos. Nu numai că oamenii pot schimba cu ușurință unul dintre multele fișiere binare/executabile incluse în Windows în mod malitios, dar acesta poate să nu conțină cele mai recente patch-uri de securitate care pot pune calculatorul dvs. în pericol.

Atlas este diferit. Folosim [AME Wizard](https://ameliorated.io) pentru a instala Atlas, iar toate scripturile pe care le folosim sunt open-source, aici, în depozitul nostru GitHub. Puteți vedea pachetul Atlas împachetat (`.apbx` - pachetul de scripturi AME Wizard) ca un arhivă, cu parola fiind `malte` (standardul pentru pachetele AME Wizard), care servește doar pentru a evita semnalele false de la antivirus.

Singurele executabile incluse în pachet sunt open-source [aici](https://github.com/Atlas-OS/Atlas-Utilities) sub licența [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), cu hash-urile identice cu versiunile publicate. Totul este în text clar.

De asemenea, puteți instala cele mai recente actualizări de securitate înainte de a instala Atlas, ceea ce vă recomandăm pentru a menține sistemul în siguranță.

Vă rugăm să rețineți că, începând cu versiunea Atlas v0.2.0, Atlas este în mare parte **nu la fel de sigur ca Windows-ul obișnuit** din cauza funcțiilor de securitate eliminate/dezactivate, cum ar fi Windows Defender care a fost eliminat. Cu toate acestea, în versiunea Atlas v0.3.0, majoritatea acestora vor fi adăugate din nou ca funcții opționale. Vedeți [aici](https://docs.atlasos.net/troubleshooting/removed-features/) pentru mai multe informații.

### 🚀 Mai mult spațiu
Aplicațiile preinstalate și alte componente nesemnificative sunt eliminate cu Atlas. Cu toate că există posibilitatea unor probleme de compatibilitate, acest lucru reduce semnificativ dimensiunea instalării și face sistemul mai fluent. De aceea, unele funcționalități (cum ar fi Windows Defender) sunt eliminate complet. Consultați ce am mai eliminat în [FAQ-ul](https://docs.atlasos.net/troubleshooting/removed-features) nostru.

### ✅ Mai multă performanță
Unele sisteme modificate de pe internet au ajustat prea mult Windows-ul, rupând compatibilitatea pentru funcții principale precum Bluetooth, Wi-Fi și altele.
Atlas se află la punctul optim. Scopul său este de a obține mai multă performanță menținând în același timp un bun nivel de compatibilitate.

Unele dintre multele modificări pe care le-am făcut pentru a îmbunătăți Windows-ul sunt enumerate mai jos:
- Schema personalizată de alimentare
- Număr redus de servicii și drivere
- Exclusivitate audio dezactivată
- Dispozitive nefolosite dezactivate
- Economisirea energiei dezactivată (pentru calculatoare personale)
- Mitigări de securitate care consumă multă energie dezactivate
- Modul MSI activat automat pe toate dispozitivele
- Configurația de boot optimizată
- Programare procese optimizată

### 🔒 Legal
Multe sisteme personalizate Windows distribuie sistemele lor furnizând un ISO ajustat al Windows-ului. Nu numai că încalcă [Termenii de utilizare ai Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), dar nu este nici o modalitate sigură de instalare.

Atlas a colaborat cu echipa Windows Ameliorated pentru a oferi utilizatorilor o modalitate mai sigură și legală de instalare: [AME Wizard](https://ameliorated.io). Cu acesta, Atlas respectă în întregime [Termenii de utilizare ai Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Kit de brand
Vă simțiți creativ? Vreți să creați propriul wallpaper Atlas cu câteva design-uri creative originale? Kitul nostru de brand vă acoperă!
Oricine poate accesa kitul nostru de brand Atlas - îl puteți descărca [aici](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) și să creați ceva spectaculos!

De asemenea, avem o secțiune dedicată pe [forumul](https://forum.atlasos.net/t/art-showcase) nostru, astfel încât să puteți împărtăși creațiile dvs. cu alți genii creative și poate chiar să aprindeți puțină inspirație! Acolo veți găsi și wallpapere creative împărtășite de alți utilizatori!

## ⚠️ Avertisment
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer


## Contrubuitori Traduceri
[KOzDroid-New](https://github.com/KOzDroid-New)
