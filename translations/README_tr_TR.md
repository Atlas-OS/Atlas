<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
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

Atlas Windows 10'un düzenlenmiş, oyun performansını olumsuz etkileyen tüm bileşenlerin kaldırılmış bir halidir. Atlas, performansa odaklanırken ayrıca; sistem gecikmesi, ağ gecikmesi, giriş gecikmesi (input lag) ve sistem güvenliği için de iyi bir seçenektir. Atlas hakkında daha fazla bilgiyi [sitemizden](https://atlasos.net) öğrenebilirsiniz.

## 📚 **İçerik tablosu**

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

### 🔒 Daha gizlilik odaklı
Stok Windows sizin bilgilerinizi toplayan ve Microsoft'a gönderen servisler içerir.
Atlas Windows'a gömülü bir şekilde gelen bilgi toplama servislerinin hepsini kaldırır ve grup ilkeleri ile bilgi toplamayı en aza çekmeyi amaçlar.

Atlas'ın Windows'un kontrolünde olmayan şeylerde (tarayıcılar ve üçüncü parti uygulamalar gibi) güvenliğinizi sağlayamayacağını unutmayın.

### 🛡️ Daha güvenli (öbür düzenlenmiş Windows ISO'larına göre)
İnternetten düzenlenmiş bir Windows ISO'su indirmek riskli bir şey. İnsanlar Windows ile birlikte gelen çalıştırılabilir dosyalara kötü amaçlı kod eklemekle kalmayıp, ayrıca Windows'un son güvenlik güncellemelerini içermeyip bilgisayarınızı ciddi risk altına sokabilir.

Atlas diğerlerinden farklı. Atlas'ı yüklemek için [AME Wizard](https://ameliorated.io) kullanıyoruz, ve kullandığımız bütün scriptler burada, GitHub'da açık kaynaklı bir şekilde bulunmakta. Atlas playbook'unu (`.apbx` - AME Wizard script package) kendiniz `malte` şifresi (AME Wizard playblookları için standart) ile inceleyebilirsiniz. Şifre koymamızın nedeni antivirüslerin yanlış sonuç vermemesi.

Playbook'un içindeki çalıştırılabilir dosyalar [burada](https://github.com/Atlas-OS/Atlas-Utilities) [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) lisansıyla açık kaynaklı, hashleri aynı bir şekilde mevcut. Geri kalan her şey düz metin halinde.

Ayrıca Atlas'ı yüklemeden önce en son güvenlik güncellemelerini yükleyebilirsiniz, ki sisteminizi güvenli tutmak için öneriyoruz.

Atlas v0.2.0 ile Atlas şu an **düzenlenmemiş bir Windows kadar güvenli değil**. Bunun sebebi kaldırılan/kapatılan özellikler, Windows Defender'ın kaldırılması gibi. Ancak Atlas v0.3.0 ile çoğu özellik isteğe bağlı olarak geri dönecek. Daha fazla bilgi için [burayı](https://docs.atlasos.net/troubleshooting/removed-features/) inceleyebilirsiniz.

### 🚀 Daha fazla alan
Hazır gelen uygulamalar ve diğer önemsiz bileşenler Atlas'da kaldırıldı. Uyumluluk sorunlarına nazaran, indirdiğiniz boyutu önemli ölçüde düşürüyor ve sisteminizi daha akıcı yapıyor. Bu nedenle bazı özellikler (Windows Defender gibi) komple kaldırıldı.
Kaldırdığımız bütün özellikleri öğrenmek için [SSS](https://docs.atlasos.net/troubleshooting/removed-features)'ı kontrol edin.

### ✅ Daha fazla performans
İnternette dolaşan bazı düzenlenmiş sistemler Windows'u o kadar düzenliyor ki, önemli olan Bluetooth, Wi-Fi gibi özelliklerin uyumluluğunu bozuyorlar. Atlas tam ortasını, iyi bir performans alırken iyi seviyede bir uyumluluk da hedefliyor.

Windows'u geliştirmek için yaptığımız bazı değişiklikler:
- Kişiselleştirilmiş güç planı
- Azaltılmış hizmet ve sürücü miktarı
- Özel ses devre dışı bırakıldı
- Gereksiz cihazlar devre dışı bırakıldı
- Pil koruma devre dışı bırakıldı (bilgisayarlar için)
- Performansa olumsuz etki eden güvenlik hafifletmeleri devre dışı bırakıldı
- Bütün cihazlarda MSI modu otomatik olarak aktifleştirildi
- Optimize edilmiş önyükleme yapılandırması
- Optimize edilmiş işlem planlaması

### 🔒 Yasal
Çoğu düzenlenmiş Windows işletim sistemleri, bir ISO dosyasıyla paylaşılır. Bu [Microsoft'un Hizmet Şartları'nı](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) ihlal etmekle kalmayıp, yüklemek için güvenli bir yol da değildir.

Atlas Windows Ameliorated Takımı ile partner olup kullanıcılarına Atlas'ı yüklemek için daha güvenli ve yasal bir yol, [AME Wizard'ı](https://ameliorated.io) sağladı. Bununla Atlas [Microsoft'un Hizmet Şartları'na](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) tamamen uygun.

## 🎨 Marka kiti
İlham mı geldi? Orijinal ve yaratıcı tasarımlarla kendi Atlas arkaplanını mı yapmak istiyorsun? Marka kitimiz tam da ihtiyacın olan şey! Herkes Atlas marka kitine [buradan](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip) ulaşıp, muhteşem şeyler yapabilir!

Ayrıca [forumumuzda](https://forum.atlasos.net/t/art-showcase), yaptığın tasarımları öbür insanlarla paylaşabilir ve hatta belki bazılarına ilham kaynağı olabilirsin! İlham kaynağı bulamadıysan başkalarının paylaştığı arkaplanlarını da kullanabilirsin.

## ⚠️ Disclaimer (Feragetname)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (Çeviriye katkıda bulunanlar)
[imribiy](https://github.com/imribiy) | 
[Anceph](https://github.com/Anceph)