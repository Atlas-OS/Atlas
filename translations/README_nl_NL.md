⚠️Let op: Dit is een vertaling van de originele [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), de informatie kan verouderd zijn.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Release Downloads" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Een open en transparante modificatie voor Windows, ontworpen om framerate, privacy en stabiliteit te verbeteren..</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Documentatie</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Wat is Atlas?**

Atlas is een modificatie voor Windows, welke prestatie-beïnvloedende onderdelen verwijderd.
Ook is Atlas uitermate geschikt om systeemlatentie, netwerklatentie, input lag, en zorgt ervoor dat je systeem privé blijft, zonder dat het perstaties verminderd.
Je kan meer informatie vinden over Atlas op onze [website](https://atlasos.net).

## 📚 **Inhoudsopgave**

- [Richtlijnen voor bijdragers](https://docs.atlasos.net/contributions)

- Aan de slag
  - [Atlas installeren](https://docs.atlasos.net/getting-started/installation)
  - [Andere installatiemethodes](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Na de installatie](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Problemen oplossen
  - [Verwijderde onderdelen](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Veelvoorkomende problemen](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Waarom Atlas?**

### 🔒 Meer privacy
Een standaard Windows-installatie bevat onderdelen welke gebruiksgegevens verzamelen en uploaden naar Microsoft.
Atlas verwijdert elke soort van tracking welke in Windows geembed zijn en implementeert enkele beveligingsbeleiden om dataverzameling te verminderen. 

Houd er rekening mee dat Atlas de beveiliging voor programma's buiten het bereik van Windows (zoals browsers en toepassingen van derden) niet kan garanderen.

### 🛡️ Veiliger (dan aangepaste Windows ISO's)
Een aangepaste Windows-ISO downloaden brengt risico's met zich mee. Niet alleen kunnen mensen gemakkelijk kwaadwillig een van de vele binaire/uitvoerbare bestanden in Windows wijzigen, het kan ook zijn dat Windows niet de laatste beveiligingspatches heeft waardoor je computer ernstige beveiligingsrisico's loopt. 

Atlas is anders. Wij gebruiken [AME Wizard](https://ameliorated.io) om Atlas te installeren, En alle scripts die wij gebruiken zijn open-source, en terug te vinden in deze GitHub repository. Je kan de Atlas Playbook (`.apbx` - AME Wizard script package) als een archief bekijken, met als wachtwoord `malte` (standaard voor AME Wizard playbooks), wat noodzakelijk is om valse virusmeldingen van antivirussoftware te voorkomen.

De bestanden [here](https://github.com/Atlas-OS/Atlas-Utilities) zijn onder de [GPLv3-licentie](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) gepubliceerd, waarbij de hashes identiek zijn aan de releases. Al het andere is in platte tekst.

Je kan, voordat je Atlas installeert, de laatste beveiligingspatches installeren, wat wij aanbevelen om je systeem veilig te houden.

Let op: vanaf Atlas v0.2.0 is Atlas meestal **niet zo veilig als gewone Windows** vanwege verwijderde/uitgeschakelde beveiligingsfuncties, zoals Windows Defender die verwijderd is. Echter, in Atlas v0.3.0 zullen de meeste van deze functies weer worden toegevoegd als optionele functies. Klik [hier](https://docs.atlasos.net/troubleshooting/removed-features/) voor meer informatie.

### 🚀 Meer ruimte
Voorgeïnstalleerde programma's en andere onbelangrijke onderdelen zijn in Atlas niet aanwezig.  Ondanks de mogelijkheid van compatibiliteitsproblemen, verkleint dit de installatie aanzienlijk en maakt het je systeem sneller. Daarom zijn onderdelen zoals Windows Defender **compleet** verwijderd
Voor meer informatie over verwijderde onderdelen kun je terecht bij onze [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Betere prestaties
Sommige getweakte systemen op het internet hebben Windows te veel getweakt, waardoor de compatibiliteit voor hoofdfuncties zoals onder andere Bluetooth en Wi-Fi niet gegarandeerd kunnen worden.
Met Atlas zit je precies goed. Atlas richt zich op het verbeteren van de prestaties met behoud van goede compatibiliteit.

Hieronder een lijst met een van de vele dingen die wij hebben gedaan om Windows te verbeteren:
- Aangepast verbruikschema
- Minder services en stuurprogramma's
- Audio Exclusive-modus uitgeschakeld
- Onnodige apparaten uitgeschakeld
- Energiebesparing uitgeschakeld (voor pc's)
- Prestatievretende beveiligingsbeperkingen uitgeschakeld
- Automatisch MSI-modus ingeschakeld op alle apparaten
- Geoptimaliseerde bootconfiguratie
- Geoptimaliseerde procesplanning

### 🔒 Legal
Veel aangepaste Windows besturingssystemen distributeren hun systemen door een aangepaste ISO van Windows te leveren. Dit schendt niet alleen [de Gebruiksvoorwaarden van Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/11/Useterms_Retail_Windows_11_Dutch.htm), maar het is ook niet zo veilig om te installeren.

Atlas werkt samen met Windows Ameliorated Team om gebruikers een veiligere en legale manier te bieden om te installeren, namelijk de [AME Wizard](https://ameliorated.io). waarmee Atlas voldoet aan de [Gebruiksvoorwaarden van Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/11/Useterms_Retail_Windows_11_Dutch.htm).

## 🎨 Brand kit
In een creatieve bui? Wil je je eigen Atlas-bureaubladachtergrond maken met originele, creatieve ontwerpen? Dan is onze brand kit wat je zoekt!
Iedereen heeft toegang tot onze Brand Kit—Je kan het [hier](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip) downloaden, en wat spectaculairs maken!

We hebben ook een speciaal gedeelte op ons [forum](https://forum.atlasos.net/t/art-showcase), zodat je je creaties kunt delen met andere creatieve genieën en misschien zelfs wat inspiratie kunt opdoen! Je kunt hier ook creatieve achtergronden vinden die andere gebruikers delen!

## ⚠️ Disclaimer
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## Vertalers
[Kevin Heijsteeg](https://github.com/OVSpotterKevin) |
