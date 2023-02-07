<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Isang bukas at transparent na operating system ng Windows, na idinisenyo upang i-optimize ang performance at latency.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

# Ano ang Atlas?

Ang Atlas ay isang binagong bersyon ng Windows 10 na nag-aalis ng lahat ng negatibong disbentaha ng Windows, na negatibong nakakaapekto sa pagganap ng paglalaro. Ang Atlas ay isang transparent at open source na proyekto na nagsusumikap para sa pantay na karapatan para sa mga manlalaro kung gumagamit ka ng isang low-end, o isang gaming PC.

Isa rin kaming magandang opsyon para bawasan ang latency ng system, network latency, input lag, at panatilihing pribado ang iyong system habang pinapanatili ang aming pangunahing pagtuon sa performance.

## Mga talahanayan ng nilalaman

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

By downloading, modifying, or utilizing any of these images, you agree to Microsoft's Terms. None of these images are pre-activated, you must use a genuine key.

## Translation contributors (Mga tagapag-ambag ng pagsasalin)

[yCyanx](https://github.com/yCyanxs)
