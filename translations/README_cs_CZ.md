⚠️Poznámka: Toto je přeložená verze originálu [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), informace zde nemusí být přesné a mohou být zastaralé.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Licence" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF&label=Licence"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Přispěvatelé" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF &label=Přispěvatelé" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Vydání" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF &label=Vydání" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Verze ke stažení" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF&label=Verze ke stažení" />
    </a>
  </p>
<h4 align="center">Otevřený a transparentní operační systém, vyvinutý pro zvýšený výkon, soukromí and stabilitu.</h4>

<p align="center">
  <a href="https://atlasos.net">Webové stránky</a>
  •
  <a href="https://docs.atlasos.net">Dokumentace</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Fórum</a>
</p>

## 🤔 **Co je Atlas?**

Atlas je modifikovaná verze Windows 10, která odstraňuje téměř všechny nevýhody Windows které negativně ovlivňují herní výkon.
Atlas je také skvělá volba pro snížení latence v systému, latence sítě, vstupní latence, a pro zachování soukromí s důrazem na výkon.
Můžete se toho o Atlase dočíst více na našem [webu](https://atlasos.net).

## 📚 **Obsah**

- [Pravidla přispívání](https://docs.atlasos.net/contributions)

- První kroky
  - [Instalace](https://docs.atlasos.net/getting-started/installation)
  - [Jiné instalační metody](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Po instalaci](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Odstranění potíží
  - [Odstraněné funkce](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripty](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Common Issues](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Proč Atlas?**

### 🔒 Více soukromí
Systém Windows obsahuje sledovací služby, které shromažďují vaše údaje a odesílají je do společnosti Microsoft. 
Atlas odstraňuje všechny typy sledování zabudované ve Windows a implementuje četné skupinové zásady, aby minimalizoval sběr dat.

Všimněte si, že Atlas nemůže zajistit zabezpečení věcí mimo oblast působnosti systému Windows (například prohlížečů a aplikací třetích stran).

### 🛡️ Více bezpečný (oproti jiným modifikacím Windows ISOs)
Stahování upravených ISO systému Windows z internetu je riskantní. Nejenže lidé mohou snadno zlomyslně změnit jeden z mnoha binárních/spustitelných souborů obsažených ve Windows, ale také nemusí obsahovat nejnovější bezpečnostní záplaty, které mohou váš počítač vážně ohrozit. 

Atlas je jiný. Používáme [Průvodce AME](https://ameliorated.io) na instalaci Atlas, a všechny skripty, které používáme, mají otevřený zdrojový kód v našem repozitáři GitHub. Zabalený atlasový playbook (`.apbx` - balíček skriptů průvodce AME) si můžete prohlédnout jako archiv s heslem `malte` (standard pro playbooky průvodce AME), které slouží pouze k obcházení falešných příznaků od antivirů.

Jediné spustitelné soubory obsažené v příručce mají otevřený zdroj [tady](https://github.com/Atlas-OS/Atlas-Utilities) pod [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), přičemž hashe jsou shodné s vydáními. Vše ostatní je v prostém textu.

Před instalací Atlasu můžete také nainstalovat nejnovější bezpečnostní aktualizace, což doporučujeme, aby byl váš systém bezpečný.

Vezměte prosím na vědomí, že od verze Atlas v0.2.0 není Atlas většinou **tak bezpečný jako běžný systém Windows**, protože byly odstraněny/zakázány bezpečnostní funkce, jako je například odstraněný Windows Defender. V Atlasu v0.3.0 však bude většina z nich přidána zpět jako volitelné funkce. Více informací naleznete na [zde](https://docs.atlasos.net/troubleshooting/removed-features/).

### 🚀 Více místa v úložišti
Předinstalované aplikace a další nevýznamné součásti jsou odstraněny pomocí aplikace Atlas. I přes možnost problémů s kompatibilitou se tím výrazně sníží velikost instalace a systém bude plynulejší. Proto jsou některé funkce (například Windows Defender) zcela odstraněny.
Podívejte se, co dalšího jsme odstranili v našich [Často kladených otázkách](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Více výkonu
Některé upravené systémy na internetu příliš upravily systém Windows, čímž porušily kompatibilitu hlavních funkcí, jako je Bluetooth, Wi-Fi atd.
Atlas je zlatou střední cestou. Jeho cílem je získat vyšší výkon při zachování dobré úrovně kompatibility.

Některé z mnoha změn, které jsme provedli za účelem vylepšení systému Windows, jsou uvedeny níže:
- Přizpůsobené schéma napájení
- Snížené množství služeb a ovladačů
- Vypnutí exkluzivního zvuku
- Zakázána nepotřebná zařízení
- Vypnutá úspora energie (pro osobní počítače)
- Zakázané zmírnění zabezpečení náročné na výkon
- Automaticky povolen režim MSI na všech zařízeních
- Optimalizovaná konfigurace spouštění systému
- Optimalizované plánování procesů

### 🔒 Právní stránka
Mnoho vlastních operačních systémů Windows distribuuje své systémy tak, že poskytuje upravené ISO systému Windows. Nejenže tím porušují [podmínky služby společnosti Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), ale není to ani bezpečný způsob instalace.

Společnost Atlas navázala spolupráci s týmem Windows Ameliorated Team, aby uživatelům poskytla bezpečnější a legální způsob instalace: [Průvodce AME](https://ameliorated.io). Díky němu společnost Atlas plně vyhovuje [Podmínkám služby společnosti Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Souprava značky
Cítíte se kreativně? Chcete si vytvořit vlastní tapetu Atlas s originálními kreativními vzory? Naše sada pro značku vám pomůže!
Přístup ke značkové sadě Atlas má každý - můžete si ji stáhnout [zde](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) a vytvořit něco velkolepého!

Na našem [fóru](https://forum.atlasos.net/t/art-showcase) máme také vyhrazený prostor, kde se můžete podělit o své výtvory s ostatními kreativními génii a možná i načerpat inspiraci! Můžete zde také najít kreativní tapety, které sdílejí ostatní uživatelé!

## ⚠️ Disclaimer (Vyloučení odpovědnosti)
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## Translation contributors (Translation contributor in the translated language)
[Contributor A](https://github.com/A) |
[Contributor B](https://github.com/B) |
[Contributor C](https://github.com/C)
