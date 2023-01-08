<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Một phiên bản Windows được thiết kế để tối ưu hiệu năng và độ trễ.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Cài đặt</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">Những câu hỏi thường gặp (FAQ)</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net/">Diễn đàn</a>
</p>


# Atlas là gì?

Atlas là một phiên bản Windows đã được chỉnh sửa, loại bỏ tất cả những nhược điểm của Windows làm ảnh hưởng tới hiệu năng chơi game. Chúng tôi là một dự án mở và minh bạch, hướng tới sự công bằng cho người chơi cho dù bạn sử dụng một chiếc PC cùi bắp hay là gaming PC.

Trong khi tập trung chính vào hiệu năng, chúng tôi cũng là một lựa chọn tốt để giảm độ trễ hệ thống, mạng, nhập liệu và giữ cho hệ thống của bạn bảo mật.

## Mục lục

- [Các câu hỏi thường gặp (FAQ)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Dự án Atlas là gì?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Làm thế nào để tôi cài đật Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Những gì đã được loại bỏ trong Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Sau khi cài đặt](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Bộ thương hiệu](./img/brand-kit.zip)

## Windows vs. Atlas

### **Riêng tư**

Atlas loại bỏ tất cả các trình theo dõi được nhúng trong Windows và triển khai nhiều nhóm chính sách để giảm thiểu sự thu thập dữ liệu. Chúng tôi không thể tăng cường sự riêng tư cho những thứ ngoài phạm vi của Windows, như là các trang web mà bạn truy cập.

### **Bảo mật**

Atlas hướng tới sự bảo mật tối đa nhất có thể mà không làm giảm hiệu năng. Chúng tôi làm vậy bằng cách vô hiệu hoá các tính năng mà có thể gây rò rỉ thông tin hoặc có thể bị khai thác. Có một số ngoại lệ như [Spectre](https://spectreattack.com/spectre.pdf) và [Meltdown](https://meltdownattack.com/meltdown.pdf). Những biện pháp bảo mật này đã được vô hiệu hoá để cải thiện hiệu suất.
Nếu một biện pháp bảo mật làm giảm hiệu năng, nó sẽ bị vô hiệu hoá.
Dưới đây là một số tính năng/biện pháp đã được thay đổi, nếu chúng chứa ký hiệu (P) thì chúng là các rủi ro bảo mật đã được vá:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Possible Information Retrieval_)

### **Loại bỏ**

Atlas loại bỏ sâu những ứng dụng được cài đặt sẵn và những thành phần khác cũng bị loại bỏ. Mặc dù có thể xảy ra các vấn đề về tương thích, điều này giảm kích thước của ISO và bộ cài đáng kể. Các tính năng như Windows Defender và những thứ tương tự đã bị loại bỏ hoàn toàn. Thay đổi này tập trung vào việc chơi game thuần tuý, nhưng đa số phần mềm làm việc và giáo dục sẽ hoạt động.

### **Hiệu suất**

Atlas đã được tinh chỉnh sẵn. Trong khi duy trì sự tương thích, nhưng cũng hướng tới hiệu năng, chúng tôi đã vắt tới giọt cuối cùng của hiệu năng vào trong ảnh Windows của chúng tôi. Một số thay đổi mà chúng tôi đã làm để cải thiện Windows được liệt kê bên dưới.

- Power scheme được tuỳ chỉnh riêng
- Giảm số lượng dịch vụ
- Giảm số lượng driver
- Vô hiệu hoá các thiết bị không cần thiết
- Vô hiệu hoá tiết kiệm năng lượng
- Vô hiệu hoá các biện pháp bảo mật mà ảnh hưởng tới hiệu năng
- Tự động kích hoạt chế độ MSI
- Tối ưu cấu hình khởi động
- Tối ưu lên lịch tiến trình

## Bộ thương hiệu

Bạn muốn tạo một hình nền Atlas của riêng bạn? Nghịch ngợm với logo của chúng tôi và làm ra thiết kế của riêng bạn? Chúng tôi có những mục công khai để giúp khơi dậy các ý tưởng sáng tạo mới trên toàn cộng đồng. [Xem thử bộ thương hiệu của chúng tôi và làm thứ gì đó thật ngoạn mục.](./img/brand-kit.zip)

Chúng tôi cũng có [một mục riêng trong khu vục thảo luận](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), nên bạn có thể chia sẻ sự sáng tạo của bạn với các thiên tài sáng tạo khác và cũng có thể khơi gợi một số cảm hứng!

## Disclaimer

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.
