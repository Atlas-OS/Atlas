## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Sistem operasi Windows yang bersumber terbuka dan transparan, didesain untuk performa dan latensi yang optimal.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Instalasi</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Forum</a>
</p>

## 🤔 **Apa itu Atlas?**

Atlas adalah versi modifkasi dari Windows 10 yang menghilangkan semua kekurangan, yang berdampak buruk pada performa game. Kami adalah proyek transparan dan sumber terbuka yang berjuang untuk hak yang sama bagi para pemain apakah kamu menjalankan kentang, atau komputer gaming.

Sambil menjaga fokus utama kami pada performa, kami juga merupakan pilihan yang bagus untuk mengurangi latensi sistem, latensi jaringan, keterlambatan input, dan menjaga sistem anda tetap privat.

## 📚 **Daftar Isi**

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Apa itu proyek Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Bagaimana cara menginstal Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Apa yang dihapus di Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Installation](https://github.com/Atlas-OS/Atlas/wiki/2.-Installing)
- [Pasca Instal](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Software](https://github.com/Atlas-OS/Atlas/wiki/4.-Software)
- [Branding kit](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
- [Legal](https://github.com/Atlas-OS/Atlas/wiki/Legal)

## 🆚 **Windows vs. Atlas**

### 🔒 Privat
Atlas menghapus semua jenis pelacakan yang ditanamkan di dalam Windows dan menerapkan berbagai kebijakan grup untuk meminimalisir pengumpulan data. Hal-hal di luar cakupan Windows tidak dapat kami tingkatkan privasinya, seperti laman situs yang kamu kunjungi.

### 🛡️ Aman
Atlas bertujuan menjadi seaman mungkin tanpa kehilangan performa. Kami melakukan ini dengan menonaktifkan fitur-fitur yang dapat membocorkan informasi atau dieksploitasi. Ada pengecualian untuk ini seperti [Spectre](https://spectreattack.com/spectre.pdf), dan [Meltdown](https://meltdownattack.com/meltdown.pdf). Mitigasi ini dinonaktifkan untuk meningkatkan performa.

Jika sebuah tindakan mitigasi keamanan menurunkan performa, mitigasi tersebut akan dinonaktifkan.
Di bawah ini adalah beberapa fitur/mitigasi yang telah diubah, jika itu mengandung (P) itu adalah risiko keamanan yang telah diperbaiki:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Kemungkinan pengambilan informasi*)

### 🚀 Debloated
Banyak yang dihilangkan dari Atlas, aplikasi-aplikasi pra-instal dan komponen lainnya dihapus. Terlepas dari kemungkinan masalah kompatibilitas, ini secara signifikan mengurangi ukuran ISO dan pemasangan. Fungsionalitas seperti Windows Defender, dan semacamnya dicopot sepenuhnya. 

Modifikasi ini terfokus pada gaming murni, tetapi sebagian besar aplikasi-aplikasi pekerjaan dan pendidikan berfungsi. [Cek juga apalagi yang telah kami copot di FAQ kami](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### ✅ Performa
Atlas sudah diutak-atik sebelumnya. Sambil mempertahankan kompatibilitas, tetapi juga mengupayakan performa, kami telah memeras setiap tetes performa terakhir ke dalam Image Windows kami. 

Beberapa dari perubahan-perubahan yang telah kami lakukan untuk meningkatkan Windows tercantum di bawah ini.

- Skema daya kustom
- Pengurangan jumlah layanan
- Pengurangan jumlah driver
- Penonaktifkan perangkat yang tidak dibutuhkan
- Penonaktifan penghematan daya
- Penonaktifkan mitigasi keamanan yang haus akan performa
- Otomatis mengaktifkan Mode MSI
- Optimalisasi konfigurasi boot
- Penjadwalan proses yang dioptimalkan

## 🎨 Branding kit
Apakah kamu ingin membuat wallpaper Atlas-mu sendiri? Mungkin mencoba hal baru dengan logo kami untuk membuat desainmu sendiri? Kami punya ini yang bisa diakses oleh publik untuk memicu ide-ide kreatif baru di seluruh komunitas. [Lihat Branding Kit kami dan buat sesuatu yang spektakuler.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

Kami juga memiliki [area khusus di tab diskusi](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), jadi kamu bisa membagikan kreasimu dengan jenius kreatif lainnya dan bahkan mungkin memicu beberapa inspirasi!

## ⚠️ Disclaimer
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Kontributor terjemahan)
[Memet Zx](https://github.com/zxce3) | 
[Kawaii Ghost](https://github.com/kawaii-ghost)
