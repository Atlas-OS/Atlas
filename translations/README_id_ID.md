<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Sistem operasi Windows yang open source dan transparan, dirancang untuk mengoptimalkan.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Instalasi</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net/">Forum</a>
</p>


# Apa itu Atlas?

Atlas adalah versi Windows yang dimodifikasi yang menghilangkan semua kelemahan negatif Windows, yang berdampak buruk pada kinerja game. Kami adalah proyek open source dan transparan yang berjuang untuk hak yang sama bagi para pemain meskipun anda menjalankan kentang, atau PC gaming.

Sambil menjaga fokus utama kami pada kinerja, kami juga merupakan opsi yang bagus untuk mengurangi latensi sistem, latensi jaringan, kelambatan input, dan menjaga privasi sistem anda.

## Table of contents

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Apa itu Atlas Projek?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Bagaimana cara menginstall Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Apa yang dihapus di Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Post Install](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Branding kit](./img/brand-kit.zip)

## Windows vs. Atlas

### **Privasi**

Atlas menghapus semua jenis pelacakan yang disematkan di dalam Windows dan menerapkan berbagai kebijakan grup untuk meminimalkan pengumpulan data. Hal-hal di luar cakupan Windows tidak dapat kami tingkatkan privasinya, seperti situs web yang anda kunjungi.

### **Keamanan**

Atlas bertujuan seaman mungkin tanpa kehilangan kinerja. Kami melakukan ini dengan menonaktifkan fitur yang dapat membocorkan informasi atau dieksploitasi. Ada pengecualian untuk ini seperti [Spectre](https://spectreattack.com/spectre.pdf), dan [Meltdown](https://meltdownattack.com/meltdown.pdf). Mitigasi ini dinonaktifkan untuk meningkatkan kinerja.
Jika tindakan mitigasi keamanan menurunkan kinerja, tindakan tersebut akan dinonaktifkan.
Di bawah ini adalah beberapa fitur/mitigasi yang telah diubah, jika mengandung (P) itu adalah risiko keamanan yang telah diperbaiki:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Kemungkinan Pengambilan Informasi_)

### **Debloated**

Atlas banyak dilucuti, aplikasi pra-instal dan komponen lainnya dihapus. Terlepas dari kemungkinan masalah kompatibilitas, ini secara signifikan mengurangi ukuran ISO dan pemasangan. Fungsionalitas seperti Windows Defender, dan semacamnya dilucuti sepenuhnya. Modifikasi ini difokuskan pada game murni, tetapi sebagian besar aplikasi pekerjaan dan pendidikan berfungsi. [Lihat apa lagi yang telah kami hapus di FAQ kami](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Performa**

Atlas sudah di-tweak sebelumnya. Sambil mempertahankan kompatibilitas, tetapi juga mengupayakan kinerja, kami telah memeras setiap tetes kinerja terakhir ke dalam citra Windows kami. Beberapa dari banyak perubahan yang telah kami lakukan untuk meningkatkan Windows tercantum di bawah ini.

- Skema daya khusus
- Mengurangi jumlah layanan
- Mengurangi jumlah driver
- Nonaktifkan perangkat yang tidak dibutuhkan
- Penghematan daya yang dinonaktifkan
- Nonaktifkan mitigasi keamanan yang haus akan kinerja
- Mode MSI diaktifkan secara otomatis
- Optimalisasi konfigurasi boot
- Penjadwalan proses yang dioptimalkan

## Branding kit

Apakah anda ingin membuat wallpaper Atlas anda sendiri? Mungkin mencoba hal baru dengan logo kami untuk membuat desain anda sendiri? Kami punya ini yang bisa diakses oleh publik untuk memicu ide-ide kreatif baru di seluruh komunitas. [Lihat kit merek kami dan buat sesuatu yang spektakuler.](./img/brand-kit.zip)

Kami juga memiliki [area khusus di tab diskusi](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), sehingga anda dapat membagikan kreasi anda dengan jenius kreatif lainnya dan bahkan mungkin memicu beberapa inspirasi!

## Disclaimer(Disclaimer)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Kontributor terjemahan)

- [Memet Zx](https://github.com/zxce3)