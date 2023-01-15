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

Ngoài việc tập trung vào hiệu năng, chúng tôi còn là một lựa chọn tốt để giảm độ trễ hệ thống, mạng, nhập liệu và giữ cho hệ thống của bạn bảo mật.

## Mục lục

- [Các câu hỏi thường gặp (FAQ)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Dự án Atlas là gì?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Cách cài đặt Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Những gì đã được loại bỏ trong Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">So sánh Windows và Atlas</a>
- [Hậu cài đặt](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Bộ thương hiệu](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

## Windows vs. Atlas

### **Quyền riêng tư**

Atlas loại bỏ tất cả các trình theo dõi được nhúng trong Windows và triển khai nhiều nhóm chính sách để giảm thiểu sự thu thập dữ liệu. Chúng tôi không thể tăng cường sự riêng tư cho những thứ ngoài phạm vi của Windows, chẳng hạn như các trang web mà bạn truy cập.

### **Bảo mật**

Atlas hướng tới sự bảo mật tối đa mà không làm giảm hiệu năng bằng cách vô hiệu hoá các tính năng có thể gây rò rỉ thông tin hoặc có thể bị tin tặc khai thác. Có một số ngoại lệ như [Spectre](https://spectreattack.com/spectre.pdf) và [Meltdown](https://meltdownattack.com/meltdown.pdf). Các tinh chỉnh bảo mật này đã được vô hiệu hoá để cải thiện hiệu suất.
Nếu một biện pháp bảo mật làm giảm hiệu năng, nó sẽ bị vô hiệu hoá.
Dưới đây là một số tính năng/tinh chỉnh đã được thay đổi, các mục có ký hiệu (P) là các rủi ro bảo mật đã được vá:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Possible Information Retrieval_)

### **Loại bỏ**

Atlas loại bỏ rất nhiều thành phần, bao gồm các ứng dụng được cài sẵn và các thành phần khác. Dù có thể các vấn đề về tương thích có thể sẽ xảy ra, song nhờ vậy mà kích thước của ISO và bộ cài được giảm đi đáng kể. Các tính năng như Windows Defender hoặc tương tự đã bị loại bỏ hoàn toàn. Thay đổi này tập trung vào việc hỗ trợ trải nghiệm chơi game thuần tuý, tuy nhiên đa số các phần mềm dành cho giáo dục hay phần mềm để làm việc vẫn sẽ hoạt động được.

### **Hiệu suất**

Atlas là một bản hệ điều hành Windows được tinh chỉnh sẵn. Để duy trì sự tương thích, và cả hiệu năng, chúng tôi sẽ cung cấp cho bạn một phiên bản Windows với sức mạnh được đẩy tới cực hạn. Một số thay đổi và cải thiện có thể kể tới như sau:

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

Bạn có muốn tạo một hình nền Atlas của riêng bạn không? Hãy thử nghịch ngợm một chút với bộ logo của chúng tôi xem, có thể bạn sẽ nảy ra được ý tưởng hay ho đó! Chúng tôi có những mục công khai để giúp khơi dậy các ý tưởng sáng tạo mới trên toàn cộng đồng, xem thử nhé? [Bộ thương hiệu của Atlas.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

Chúng tôi cũng có [một mục riêng trong khu vục thảo luận](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), bạn có thể chia sẻ sự sáng tạo của mình với các nhà thiết kế khác, hoặc có thể bạn cũng sẽ tìm được nguồn cảm hứng ở đó thì sao!

## Disclaimer

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Những người đóng góp dịch thuật)

[Cuong Tien Dinh](https://github.com/dtcu0ng) | [Nguyễn Cao Hoài Nam](https://github.com/sant1ago-da-hanoi)