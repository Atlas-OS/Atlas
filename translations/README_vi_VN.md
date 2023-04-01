<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Một phiên bản Windows được thiết kế để tối ưu hiệu năng và độ trễ.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Cài đặt</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">Những câu hỏi thường gặp (FAQ)</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Diễn đàn</a>
</p>

## 🤔 **Atlas là gì?**

Atlas là một phiên bản Windows 10 đã được tinh chỉnh, loại bỏ tất cả nhược điểm của Windows gây ảnh hưởng tới hiệu năng chơi game. Đây là một dự án mở và minh bạch, hướng tới sự tiện dụng cho người chơi cho dù bạn sử dụng một chiếc PC cùi hay là gaming PC.

Đây cũng là một lựa chọn tuyệt vời để giảm độ trễ hệ thống, độ trễ mạng, độ trễ đầu vào, và giữ hệ thống của bạn bảo mật bên cạnh việc tập trung ở hiệu năng

## 📚 **Mục lục**

- [Các câu hỏi thường gặp (FAQ)](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Dự án Atlas là gì?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Cách cài đặt Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Những thành phần nào được giản lược trong Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">So sánh Windows với Atlas</a>
- [Cách cài đặt](https://github.com/Atlas-OS/Atlas/wiki/2.-Installing)
- [Sau khi cài đặt](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Phần Mềm Hỗ Trợ](https://github.com/Atlas-OS/Atlas/wiki/4.-Software)
- [Bộ thương hiệu](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)
- [Tính pháp lý](https://github.com/Atlas-OS/Atlas/wiki/Legal)

## 🆚 **Windows vs. Atlas**

### 🔒 Quyền riêng tư
Atlas loại bỏ tất cả các trình theo dõi được nhúng trong Windows và triển khai nhiều nhóm chính sách để giảm thiểu việc thu thập dữ liệu. Chúng tôi không thể tăng cường tính riêng tư ở những thứ ngoài phạm vi của Windows, chẳng hạn như các trang web mà bạn truy cập.

### 🛡️ Bảo mật
Atlas hướng tới sự bảo mật tối đa mà không làm giảm hiệu năng bằng cách vô hiệu hoá các tính năng có thể gây rò rỉ thông tin hoặc có thể bị tin tặc khai thác. Có một số ngoại lệ như [Spectre](https://spectreattack.com/spectre.pdf) và [Meltdown](https://meltdownattack.com/meltdown.pdf). Các tinh chỉnh bảo mật này đã được vô hiệu hoá để cải thiện hiệu suất.

Nếu một biện pháp bảo mật làm giảm hiệu năng, nó sẽ bị vô hiệu hoá.
Dưới đây là một số tính năng/tinh chỉnh đã được thay đổi, trong đó các mục được ký hiệu (P) là các rủi ro bảo mật đã được vá:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Khả năng tìm được thông tin*)

### 🚀 Tinh giản
Atlas được rút gọn rất nhiều, những ứng dụng cài sẵn cũng như các thành phần khác đã được lược đi. Dù có thể gây ra các vấn đề về tương thích, việc này làm giảm đáng kể kích thước ISO và cài đặt. Các chức năng như Windows Defender, và những thành phần tương tự đã được lược bỏ hoàn toàn.

Sự tinh chỉnh này tập trung vào hiệu năng chơi game thuần túy, nhưng đa số các ứng dụng cho công việc và học tập đều hoạt động. [Cùng xem chúng tôi đã lược bỏ thêm những gì trong phần FAQ] (https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ # 13-whats-in-Atlas-os).

### ✅ Hiệu suất
Atlas đã được tinh chỉnh sẵn. Trong lúc duy trì sự tương thích, nhưng vẫn đảm bảo cả hiệu năng, chúng tôi đẩy hiệu năng tới cực hạn cho các bản Windows. 

Một trong vô số thay đổi chúng tôi đã thực hiện để cải thiện Windows được liệt kê dưới đây.

- Chế độ năng lượng được tuỳ chỉnh riêng
- Giảm số lượng tiến trình và trình điều khiển (driver)
- Vô hiệu hóa chức năng tối ưu âm thanh
- Vô hiệu hoá các thiết bị không cần thiết
- Vô hiệu hoá tiết kiệm pin
- Vô hiệu hoá các biện pháp bảo mật gây ảnh hưởng tới hiệu năng
- Tự động kích hoạt chế độ MSI trên mọi thiết bị.
- Tối ưu cấu hình khởi động
- Tối ưu lên lịch tiến trình

## 🎨 Bộ thương hiệu
Bạn muốn tạo một hình nền Atlas của riêng bạn? Hay là thử vọc vạch bộ logo của chúng tôi để tạo ra thiết kế cho riêng mình? Chúng tôi công khai quyền truy cập chúng nhằm khơi dậy các ý tưởng sáng tạo mới trên toàn cộng đồng. [Bộ thương hiệu của Atlas.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

Chúng tôi cũng có [một mục riêng trong khu vục thảo luận](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), để bạn có thể chia sẻ tác phẩm của mình với những nhà thiết kế khác và có khi lại khơi lên cho bạn vài cảm hứng đấy!

## ⚠️ Disclaimer
By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms.](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Những người đóng góp dịch thuật)

[Cuong Tien Dinh](https://github.com/dtcu0ng) | 
[Nguyễn Cao Hoài Nam](https://github.com/sant1ago-da-hanoi) |
[Nguyen Thuy Linh](https://github.com/WhiteSnow00) |
[Nguyễn Trường Sơn (Alaire Sena)](github.com/alaireselene)
