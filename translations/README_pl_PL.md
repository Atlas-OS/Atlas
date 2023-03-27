<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Otwarty i przejrzysty system operacyjny Windows, zaprojektowany w celu optymalizacji wydajności i opóźnień.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Instalacja</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Co to jest AtlasOS?**

Atlas jest zmodyfikowaną wersją systemu Windows 10, która usuwa wszystkie negatywne wady systemu Windows, które powodują spadek wydajności w grach. Jesteśmy przejrzystym i otwartym projektem, który dąży do równych praw dla graczy, niezależnie od tego, czy uruchamiasz komputer z niskiej półki, czy komputer do gier.

Koncentrując się głównie na wydajności, jesteśmy również świetną opcją, aby zmniejszyć opóźnienia systemu, opóźnienia sieci, input lag i zachować prywatność systemu.

## 📚 **Spis treści**

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Co to jest projekt Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Jak zainstalować system Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Co jest usunięte w systemie Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Installation](https://github.com/Atlas-OS/Atlas/wiki/2.-Installing)
- [Post Install](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Software](https://github.com/Atlas-OS/Atlas/wiki/4.-Software)
- [Branding kit](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
- [Legal](https://github.com/Atlas-OS/Atlas/wiki/Legal)

## 🆚 **Windows vs. Atlas**

### 🔒 Prywatny
Atlas usuwa wszystkie rodzaje śledzenia wbudowane w system Windows i wprowadza setki zasad grupowych, aby zminimalizować gromadzenie danych. W przypadku rzeczy spoza zakresu systemu Windows nie możemy zwiększyć prywatności, takich jak odwiedzane witryny internetowe.

### 🛡️ Bezpieczny
Atlas dąży do zapewnienia maksymalnego bezpieczeństwa bez utraty wydajności. Robimy to poprzez wyłączenie funkcji, które mogą wyciekać informacje lub być wykorzystywane. Istnieją wyjątki od tej zasady, takie jak [Spectre](https://spectreattack.com/spectre.pdf) i [Meltdown](https://meltdownattack.com/meltdown.pdf). Te środki łagodzące są wyłączone, aby poprawić wydajność. 

Jeśli środek zaradczy zmniejszy wydajność, zostanie wyłączony. 
Poniżej znajdują się niektóre funkcje, które zostały zmienione, jeśli zawierają (P) to są to zagrożenia bezpieczeństwa, które zostały naprawione:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Możliwość pozyskiwania informacji*)

### 🚀 Okrojony
Atlas jest mocno okrojony, usuwane są preinstalowane przez Windows aplikacje i inne komponenty. Chociaż może to zaburzyć kompatybilność, to znacznie zmniejsza rozmiar ISO i instalacji. Funkcje takie jak Windows Defender i podobne są usunięte całkowicie. 

Ta modyfikacja skupia się na czystym graniu, ale większość aplikacji do pracy i edukacji działa. [Sprawdź co jeszcze usunęliśmy w naszym FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### ✅ Wydajny
Atlas jest wstępnie zoptymalizowany. Zachowując kompatybilność, ale także dążąc do wydajności, wycisnęliśmy każdą kroplę wydajności w naszych obrazach systemu Windows. Niektóre z wielu zmian, które wprowadziliśmy w celu ulepszenia systemu Windows, zostały wymienione poniżej:

- Niestandardowy plan zasilania
- Zmniejszona ilość usług
- Zmniejszona ilość sterowników
- Wyłączono zbędne urządzenia
- Wyłączono oszczędzanie energii
- Wyłączono ograniczenia bezpieczeństwa redukujące wydajność
- Automatycznie włączono tryb MSI
- Zopytmalizowano konfiguracje startu systemu
- Zoptymalizowano harmonogramowanie procesów

## 🎨 Zestaw marki
Chcesz stworzyć własną tapetę Atlas? A może pobawić się naszym logo i stworzyć własne? Mamy to dostępne publicznie, aby pobudzić nowe kreatywne pomysły w całej społeczności. [Sprawdź nasz zestaw marki i stwórz coś niesamowitego](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip).

Mamy też [dedykowany obszar w zakładce dyskusje](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), więc możesz podzielić się swoimi projektami z innymi kreatywnymi twórcami, a może nawet zaskoczyć jakąś inspiracją!

## ⚠️ Disclaimer
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Twórcy tłumaczenia)

[Xyueta](https://github.com/Xyueta)
