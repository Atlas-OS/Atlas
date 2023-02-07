<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">An open and transparent Windows operating system, designed to optimize performance and latency.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

# Translations

<kbd>[<img title="中文（简体）" alt="中文（简体）" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/cn.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_zh_CN.md)</kbd>
<kbd>[<img title="Française" alt="Française" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/fr.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_fr_FR.md)</kbd>
<kbd>[<img title="Bahasa Indonesia" alt="Bahasa Indonesia" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/id.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_id_ID.md)</kbd>
<kbd>[<img title="Tagalog" alt="Tagalog" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/ph.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_ph_PH.md)</kbd>
<kbd>[<img title="Polski" alt="Polski" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/pl.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_pl_PL.md)</kbd>
<kbd>[<img title="Русский" alt="Русский" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/ru.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_ru_RU.md)</kbd>
<kbd>[<img title="Tiếng Việt" alt="Tiếng Việt" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/vn.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_vi_VN.md)</kbd>
<kbd>[<img title="Deutsch" alt="Deutsch" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/de.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_de_DE.md)</kbd>
<kbd>[<img title="Türkçe" alt="Türkçe" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/tr.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_tr_TR.md)</kbd>
<kbd>[<img title="Українська" alt="Українська" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/ua.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_ua_UA.md)</kbd>

#### _Want to help us by translating documents? Please follow this [README](translations/README.md)._

# Ano ang Atlas?

Ang Atlas ay isang binagong bersyon ng Windows 10 na nag-aalis ng lahat ng negatibong disbentaha ng Windows, na negatibong nakakaapekto sa pagganap ng paglalaro. Ang Atlas ay isang transparent at open source na proyekto na nagsusumikap para sa pantay na karapatan para sa mga manlalaro kung gumagamit ka ng isang low-end, o isang gaming PC.

Isa rin kaming magandang opsyon para bawasan ang latency ng system, network latency, input lag, at panatilihing pribado ang iyong system habang pinapanatili ang aming pangunahing pagtuon sa performance.

## Table of contents

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Ano ang proyekto ng Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Paano ko mai-install ang Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Ano ang tinanggal sa Atlas??](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Post Install](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Branding kit](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)

## Windows vs. Atlas

### **Pribado**

Tinatanggal ng Atlas ang lahat ng uri ng pagsubaybay na naka-embed sa loob ng Windows at nagpapatupad ng maraming patakaran ng grupo para mabawasan ang pangongolekta ng data. Mga bagay na wala sa saklaw ng Windows na hindi namin madaragdagan ang privacy, gaya ng mga website na binibisita mo.

### **Seguridad**

Nilalayon ng Atlas na maging secure hangga't maaari nang hindi nawawala ang performance. Ginagawa namin ito sa pamamagitan ng hindi pagpapagana ng mga feature na maaaring mag-leak ng impormasyon o mapagsamantalahan. May mga pagbubukod dito gaya ng [Spectre](https://spectreattack.com/spectre.pdf), at [Meltdown](https://meltdownattack.com/meltdown.pdf). Ang mga pagpapagaan na ito ay hindi pinagana upang mapabuti ang pagganap.
Kung ang isang hakbang sa pagpapagaan ng seguridad ay nagpapababa sa pagganap, ito ay hindi papaganahin.
Nasa ibaba ang ilang feature/mitigation na binago, kung naglalaman ang mga ito ng (P) ang mga ito ay mga panganib sa seguridad na naayos na:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Possible Information Retrieval_)

### **Debloated**

Ang Atlas ay mabigat na hinubad, ang mga paunang naka-install na application at iba pang mga bahagi ay tinanggal. Sa kabila ng posibilidad ng mga isyu sa compatibility, makabuluhang binabawasan nito ang ISO at laki ng pag-install. Ang mga function tulad ng Windows Defender, at tulad nito ay ganap na tinanggal. Nakatuon ang pagbabagong ito sa purong paglalaro, ngunit gumagana ang karamihan sa mga application sa trabaho at edukasyon. [Tingnan kung ano pa ang inalis namin sa aming FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Performant**

Ang Atlas ay pre-tweaked. Habang pinapanatili ang pagiging tugma, ngunit nagsusumikap din para sa pagganap, iniipit namin ang bawat huling patak ng pagganap sa aming mga larawan sa Windows. Nakalista sa ibaba ang ilan sa maraming pagbabago na ginawa namin upang mapabuti ang Windows.

- Customized na powerplan o scheme
- Nabawasan ang dami ng mga serbisyo at driver
- Naka-disable ang eksklusibong audio
- Naka-disable ang mga hindi kailangang device
- Hindi pinagana ang pagtitipid ng kuryente
- Hindi pinagana ang pagpapagaan sa seguridad na gutom sa performance
- Awtomatikong pinagana ang MSI mode sa lahat ng device
- Pag-optimize ng configuration ng boot
- Na-optimize na pag-iiskedyul ng proseso

## Branding kit

Gusto mo bang gumawa ng sarili mong wallpaper ng Atlas? Baka magulo ang aming logo para gumawa ng sarili mong disenyo? Naa-access namin ito sa publiko para makapagsimula ng mga bagong malikhaing ideya sa buong komunidad. [Tingnan ang aming brand kit at gumawa ng kamangha-manghang bagay.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Mayroon din kaming [nakalaang lugar sa tab ng mga talakayan](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), para maibahagi mo ang iyong mga likha sa iba pang mga magagaling sa pag-drawing at maaaring maging spark ng inspirasyon!

## Disclaimer

Sa pamamagitan ng pag-download, pagbabago, o paggamit ng alinman sa mga larawang ito, sumasang-ayon ka sa [Mga Tuntunin ng Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). Wala sa mga larawang ito ang na-pre-activate, **dapat** kang gumamit ng tunay na  Windows key o lisensiya.
