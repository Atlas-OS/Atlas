<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Performansı ve gecikmeyi optimize etmek için tasarlanmış, açık kaynaklı ve şeffaf bir Windows işletim sistemi.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Installation</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net/">Forum</a>
</p>


# Translations

<kbd>[<img title="中文（简体）" alt="中文（简体）" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/cn.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_zh_CN.md)</kbd>
<kbd>[<img title="Française" alt="Française" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/fr.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_fr_FR.md)</kbd>
<kbd>[<img title="Bahasa Indonesia" alt="Bahasa Indonesia" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/id.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_id_ID.md)</kbd>
<kbd>[<img title="Polski" alt="Polski" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/pl.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_pl_PL.md)</kbd>
<kbd>[<img title="Русский язык" alt="Русский язык" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/ru.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_ru_RU.md)</kbd>
<kbd>[<img title="Tiếng Việt" alt="Tiếng Việt" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/vn.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_vi_VN.md)</kbd>
<kbd>[<img title="Deutsch" alt="Deutsch" src="https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/de.svg" width="22">](https://github.com/Atlas-OS/Atlas/blob/main/translations/README_de_DE.md)</kbd>

#### _Bize çeviri konusunda yardımcı olmak mı istiyorsunuz? Lütfen burayı takip edin: [BENİ OKU](translations/README.md)._


# Atlas Nedir?

Atlas, Windows'un oyun performansını olumsuz etkileyen bileşenlerin ortadan kaldırıldığı modifiye edilmiş bir Windows sürümüdür. İster hesap makinesinden hallice bir bilgisayar ister son model bir oyun bilgisayarı kullanıyor olun, oyuncular için eşit haklar için çabalayan şeffaf ve açık kaynaklı bir projeyiz.

Ana odağımızı sistem gecikmesi, ağ gecikmesi ve giriş gecikmesini azaltmak ve genel sistem performansını arttırmak üzerinde tutarken, ayrıca işletim sisteminizi gizli ve güvenli tutmak için de harika bir seçeneğiz.


## İçerik tablosu

- [SSS](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Atlas projesi nedir?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Atlas'ı nasıl kurabilirim?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Atlas'tan neler silindi?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Kurulum Sonrası](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Marka Kiti](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

## Windows vs. Atlas

### **Özel**

Atlas, Windows içine gömülü her türlü izleyiciyi kaldırır ve veri paylaşımını en aza indirmek için çok sayıda grup ilkesi uygular. Ziyaret ettiğiniz web siteleri gibi Windows kapsamı dışındaki şeyler için gizliliği artıramayız.

### **Güvenli**

Atlas, performans kaybı olmadan mümkün olduğunca güvenli olmayı hedefler. Bunu, bilgi sızdırabilecek veya istismar edilebilecek özellikleri devre dışı bırakarak yapıyoruz. [Spectre](https://spectreattack.com/spectre.pdf), ve [Meltdown](https://meltdownattack.com/meltdown.pdf) bir istisnadır. Bu önlemler performansı artırmak için devre dışı bırakılmıştır.
Eğer bir güvenlik önlemi ölçülebilir ölçüde performansı düşürürse, devre dışı bırakılır.
Aşağıda değiştirilen bazı özellikler/önlemler yer almaktadır, eğer (P) içeriyorlarsa bunlar düzeltilen güvenlik riskleridir:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Uzak Masaüstü](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Olası Bilgi Erişimi_)

### **Arındırılmış**

Atlas büyük ölçüde temizlenmiş, önceden yüklenmiş uygulamalar ve diğer bileşenler kaldırılmıştır. Uyumluluk sorunları olasılığına rağmen, bu ISO ve yükleme boyutunu önemli ölçüde azaltır. Windows Defender gibi işlevler tamamen kaldırılmıştır. Bu değişiklik saf oyun oynamaya odaklanmıştır, ancak çoğu iş ve eğitim uygulaması çalışır.  [Neleri kaldırdığımıza FAQ kısmından bakabilirsin.](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Performanslı**

Atlas önceden optimize edilmiştir. Uyumluluk sorunlarını minimize ederken performansı artırmak için de çabalayarak, Windows imajımızın performansını son raddeye kadar zorladık. Windows'u iyileştirmek için yaptığımız birçok değişiklikten bazıları aşağıda listelenmiştir.

- Özelleştirilmiş güç planı
- Azaltılmış hizmetler
- Azaltılmış sürücüler
- Aygıt yöneticisi optimize edildi
- Güç tasarruf özellikleri kapatıldı
- Performansı baltalayan güvenlik önlemleri devre dışı bırakıldı
- MSI modu otomatik olarak etkinleştirildi
- İşletim sistemi yükleme ayarları optimize edildi
- Optimize edilmiş süreç programlama

## Marka kiti

Kendi Atlas duvar kağıdınızı tasarlamak ister misiniz? Belki kendi tasarımınızı yapmak için logomuzla uğraşabilirsiniz? Topluluk genelinde yeni yaratıcı fikirleri harekete geçirmek için bunu topluluğun erişimine açtık. [Marka kitimize göz atın ve muhteşem bir şey yapın.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Ayrıca tartışmalar sekmesinde [özel bir alanımız var] (https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), böylece yarattıklarınızı diğer yaratıcı dahilerle paylaşabilir ve belki biraz ilham bile uyandırabilirsiniz!

## Yasal Uyarı

Bu görüntülerden herhangi birini indirerek, değiştirerek veya kullanarak [Microsoft'un Şartlarını] kabul etmiş olursunuz. (https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) Bu imajların hiçbiri önceden etkinleştirilmemiştir, **mutlaka** orijinal bir anahtar kullanmalısınız.
