<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Lisans" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Katkıda Bulunanlar" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Son Sürüm" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="İndirmeler" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Açık kaynaklı ve şeffaf bir işletim sistemi, performans, gizlilik ve kararlılık için tasarlandı</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Dokümantasyon</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Atlas nedir?**

Atlas, Windows'un oyun performansını olumsuz etkileyen neredeyse tüm dezavantajlarını ortadan kaldıran bir Windows düzenlemesidir. Atlas, performansa odaklanmasının yanı sıra; sistem gecikmesi, ağ gecikmesi, girdi gecikmesi (input lag) ve sistem güvenliği için de iyi bir seçenektir. Atlas hakkında daha fazla bilgiyi [sitemizden](https://atlasos.net) öğrenebilirsiniz.

## 📚 **İçindekiler tablosu**

- [Contribution Guidelines](https://docs.atlasos.net/contributions)

- Getting Started
  - [Installation](https://docs.atlasos.net/getting-started/installation)
  - [Other installation methods](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Post-Installation](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Common Issues](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Neden Atlas?**

### 🔒 Daha gizli
Stok Windows, verilerinizi toplayan ve Microsoft'a gönderen izleme hizmetleri içerir. Atlas, Windows'a gömülü tüm izleme hizmetlerini kaldırır ve veri toplamayı en aza indirmek için çok sayıda grup ilkesi uygular.

Atlas'ın Windows kapsamı dışındaki şeyler (tarayıcılar ve üçüncü taraf uygulamalar gibi) için güvenlik sağlayamayacağını unutmayın.

### 🛡️ Daha güvenli (diğer düzenlenmiş Windows ISO'larına göre)
İnternetten düzenlenmiş bir Windows ISO'su indirmek risklidir. İnsanlar Windows ile birlikte gelen çalıştırılabilir dosyalara kötü amaçlı kod eklemekle kalmayıp, ayrıca bu  Windows sürümleri son güvenlik güncellemelerini içermeyip bilgisayarınızı ciddi risk altına sokabilir.

Atlas diğerlerinden farklıdır. Atlas'ı yüklemek için [AME Wizard](https://ameliorated.io) kullanıyoruz, ve kullandığımız bütün scriptler burada, GitHub'da açık kaynaklı bir şekilde bulunmakta. Atlas playbook'unu (`.apbx` - AME Wizard script package) kendiniz `malte` şifresi (AME Wizard playblookları için standart) ile inceleyebilirsiniz. Şifre koymamızın nedeni antivirüslerin yanlış sonuç vermemesi.

Playbook'un içindeki çalıştırılabilir dosyalar [burada](https://github.com/Atlas-OS/Atlas-Utilities) [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) lisansıyla açık kaynaklıdır ve  hashleri yayınlanan sürümlerle aynıdır. Geri kalan her şey düz metin halindedir.

Ayrıca Atlas'ı yüklemeden önce en son güvenlik güncellemelerini yükleyebilirsiniz, ki sisteminizi güvenli tutmak için öneriyoruz.

Mevcut Atlas v0.2.0 sürümünün, Windows Defender gibi güvenlik özelliklerinin kaldırılması/devre dışı bırakılması nedeniyle **stok Windows kadar güvenli olmadığını** unutmayın. Ancak Atlas v0.3.0'da bunların çoğu isteğe bağlı özellikler olarak geri eklenecektir. Daha fazla bilgi için [burayı](https://docs.atlasos.net/troubleshooting/removed-features/) inceleyebilirsiniz.

### 🚀 Daha fazla depolama
Önyüklü uygulamalar ve diğer önemsiz bileşenler Atlas'da kaldırıldı. Bu, uyumluluk sorunlarına neden olabileceği gibi, yükleme boyutunu önemli ölçüde azaltır ve sisteminizi daha akıcı hale getirir. Bu nedenle bazı özellikler (Windows Defender gibi) komple kaldırıldı.

Kaldırdığımız bütün özellikleri öğrenmek için [SSS](https://docs.atlasos.net/troubleshooting/removed-features)'ı kontrol edin.

### ✅ Daha fazla performans
İnternetteki bazı sistemler Windows'u gereğinden fazla düzenleyerek, Wi-Fi ve benzeri ana özelliklerin uyumluluğunu bozar. Atlas tam da bu noktada, hem uyumluluğu korurken hem de daha fazla performans vermeyi amaçlıyor.

Windows'u geliştirmek için yaptığımız bazı değişiklikler:
- Kişiselleştirilmiş güç planı
- Azaltılmış hizmet ve sürücü miktarı
- Özel kullanım modu (ses) devre dışı bırakıldı
- Gereksiz cihazlar devre dışı bırakıldı
- Güç tasarrufu devre dışı bırakıldı (masaüstü bilgisayarlar için)
- Performansa olumsuz etki eden güvenlik önlemleri devre dışı bırakıldı
- Bütün cihazlarda MSI modu otomatik olarak etkinleştirildi
- Optimize edilmiş önyükleme yapılandırması
- Optimize edilmiş işlem planlaması

### 🔒 Yasal
Çoğu düzenlenmiş Windows sistemleri, ISO dosyalarıyla paylaşılır. Bu [Microsoft'un Hizmet Şartları'nı](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) ihlal etmekle kalmayıp, yüklemek için güvenli bir yol da değildir.

Atlas, Windows Ameliorated Takımı ile partner olup kullanıcılarına Atlas'ı yüklemek için daha güvenli ve yasal bir yol, [AME Wizard'ı](https://ameliorated.io) sağladı. Bununla birlikte Atlas, [Microsoft'un Hizmet Şartları'na](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) tamamen uygundur.

## 🎨 Marka kiti
İlham mı geldi? Orijinal ve yaratıcı tasarımlarla kendi Atlas arka planını mı yapmak istiyorsun? Marka kitimiz tam da ihtiyacın olan şey! Herkes Atlas marka kitine [buradan](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) ulaşıp, muhteşem şeyler yapabilir!

Ayrıca [forumumuzda](https://forum.atlasos.net/t/art-showcase), yaptığın tasarımları başkalarıyla paylaşabilir ve onlara ilham kaynağı olabilirsin! Ayrıca diğer kullanıcıların paylaştığı yaratıcı duvar kağıtlarını da burada bulabilirsin!

## ⚠️ Disclaimer (Feragetname)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (Çeviriye katkıda bulunanlar)
[imribiy](https://github.com/imribiy) | 
[Anceph](https://github.com/Anceph)
[P1ns](https://github.com/p1ns)
