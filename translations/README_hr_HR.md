<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Licenca" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Suradnici" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Izdanje" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Preuzimanja izdanja" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Otvoren i transparentan operativni sustav, dizajniran za optimizaciju performansi, privatnost i stabilnost.</h4>

<p align="center">
  <a href="https://atlasos.net">Web stranica</a>
  •
  <a href="https://docs.atlasos.net">Dokumentacija</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Što je Atlas?**

Atlas je modificirana verzija sustava Windows 10 koja uklanja gotovo sve nedostatke sustava Windows koji negativno utječu na performanse igranja.
Atlas je također dobra opcija za smanjenje latencije sustava, latencije mreže, kašnjenja unosa te zadržava privatnost vašeg sustava dok se fokusira na performanse.
Više o Atlasu možete saznati na našoj službenoj [web stranici](https://atlasos.net).

## 📚 **Sadržaj**

- Početak rada
  - [Instalacija](https://docs.atlasos.net/getting-started/installation)
  - [Druge metode instalacije](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Poslije instalacije](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Rješavanje problema
  - [Uklonjene značajke](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Skripte](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Discord](https://docs.atlasos.net/faq/community/discord)
  - [Forumi](https://docs.atlasos.net/faq/community/forums)
  - [GitHub](https://docs.atlasos.net/faq/community/github)

## 👀 **Zašto Atlas?**

### 🔒 Privatniji
Stock Windows contains tracking services that collect your data and upload it to Microsoft.
Atlas removes all types of tracking embedded within Windows and implements numerous group policies to minimize data collection. 

Note that Atlas cannot ensure the security for things outside the scope of Windows (such as browsers and third-party applications).

### 🛡️ Sigurniji (u odnosu na prilagođene Windows ISO-ove)
Preuzimanje modificiranog Windows ISO-a s interneta je rizično. Ne samo da ljudi mogu lako zlonamjerno promijeniti jednu od mnogih binarnih/izvršnih datoteka uključenih u sustavu Windows, on također možda nema najnovije sigurnosne zakrpe koje mogu ozbiljno ugroziti vaše računalo.

Atlas je drugačiji. Mi koristimo [AME Wizard](https://ameliorated.io) za instalaciju Atlasa, a sve skripte koje koristimo otvorenog su koda ovdje u našem GitHub repozitoriju. Možete pogledati zapakiran Atlas playbook (`.apbx` - AME Wizard paket skripti) kao arhivu, sa lozinkom `malte` (standard za priručnike AME Wizard-a), što je samo za zaobilaženje lažnih detekcija antivirusa.

Jedine izvršne datoteke uključene u playbook-u otvorenog su koda [ovdje](https://github.com/Atlas-OS/Atlas-Utilities) pod [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), s hashovima koji su identični izdanjima. Sve ostalo je u običnom tekstu.

Također možete instalirati najnovija sigurnosna ažuriranja prije instaliranja Atlasa, što preporučujemo kako bi vaš sustav bio sigurniji.

Imajte na umu da od Atlasa v0.2.0, Atlas uglavnom **nije tako siguran kao obični Windows** zbog uklonjenih/onemogućenih sigurnosnih značajki, poput uklanjanja Windows Defendera. Međutim, u Atlasu v0.3.0, većina njih bit će ponovno dodana kao dodatne značajke. Pogledajte [ovdje](https://docs.atlasos.net/troubleshooting/removed-features/) za više informacija.

### 🚀 Više mjesta
Unaprijed instalirane aplikacije i druge beznačajne komponente uklanjaju se s Atlasom. Unatoč mogućnosti problema s kompatibilnošću, ovo značajno smanjuje veličinu instalacije i vaš sustav čini tečnijim. Stoga su neke funkcije (kao što je Windows Defender) potpuno uklonjene.
Provjerite što smo još uklonili u našem [FAQ-u](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Više performanse
Neki dotjerani sustavi na internetu previše su dotjerali Windows, prekidajući kompatibilnost za glavne značajke kao što su Bluetooth, Wi-Fi i tako dalje.
Atlas je na vrhuncu. Cilj mu je postići više performanse uz održavanje dobre razine kompatibilnosti.

Neke od mnogih promjena koje smo učinili kako bismo poboljšali sustav Windows navedene su u nastavku:
- Prilagođen power scheme
- Smanjena količina servisa and drajvera
- Onemogućen audio exclusive
- Onemogućeni nepotrebni uređaji
- Onemogućena ušteda energije (za osobna računala)
- Onemogućena sigurnosna ublažavanja koja zahtijevaju izvođenje
- Automatski omogućen MSI način rada na svim uređajima
- Optimizirana konfiguracija pokretanja
- Optimizirano planiranje procesa

### 🔒 Legalnost
Mnogi prilagođeni operacijski sustavi Windows distribuiraju svoje sustave pružajući prilagođeni ISO sustava Windows. Ne samo da krši [Licencne odredbe za Microsoftov softver](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_Croatian.htm), ali također nije siguran način instaliranja.

Atlas se udružio s Windows Ameliorated Teamom kako bi korisnicima pružio sigurniji i legalniji način instalacije: [AME Wizard](https://ameliorated.io). S njim Atlas u potpunosti ispunjava [Licencne odredbe za Microsoftov softver](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/Useterms_Retail_Windows_10_Croatian.htm).

## 🎨 Brand komplet
Osjećate se kreativno? Želite li izraditi vlastitu Atlas pozadinu s originalnim kreativnim dizajnom? Naš brand komplet vas pokriva!
Svatko može pristupiti kompletu marke Atlas — možete ga preuzeti [ovdje](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) i napravite nešto spektakularno!

Također imamo namjenjeni prostor na našem [forumu](https://forum.atlasos.net/t/art-showcase), tako da možete podijeliti svoje kreacije s drugim kreativnim genijima i možda čak potaknuti malo inspiracije! Ovdje također možete pronaći kreativne pozadine koje drugih korisnika!

## ⚠️ Izjava o ograničenju odgovornosti
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer
