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

Atlas là một phiên bản Windows 10 đã được chỉnh sửa, loại bỏ tất cả những nhược điểm của Windows làm ảnh hưởng tới hiệu năng chơi game.
Ngoài việc tập trung vào hiệu năng, chúng tôi còn là một lựa chọn tốt để giảm độ trễ hệ thống, mạng, nhập liệu và giữ cho hệ thống của bạn được bảo mật.
Bạn có thể tìm hiểu thêm về Atlas trên [trang web chính thức của chúng tôi](https://atlasos.net).

## 📚 **Mục lục**

- Bắt đầu
  - [Cài đặt](https://docs.atlasos.net/Getting%20started/Installation)
  - [Các cách cài đặt khác](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB)
  - [Sau khi cài đặt](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers)

- Xử lý sự cố
  - [Những tính năng bị gỡ bỏ](https://docs.atlasos.net/Troubleshooting/Removed%20features)
  - [Các tập lệnh](https://docs.atlasos.net/Troubleshooting/Scripts)

- FAQ
  - [Cài đặt](https://docs.atlasos.net/FAQ/Installation)
  - [Đóng góp](https://docs.atlasos.net/FAQ/Contribute)

## 👀 **Tại sao nên dùng Atlas?**

### 🔒 Riêng tư hơn
Phiên bản Windows gốc có chứa dịch vụ theo dõi, nó thu thập dữ liệu của bạn và gửi chúng tới Microsoft.
Atlas loại bỏ tất cả các trình theo dõi được nhúng trong Windows và triển khai nhiều nhóm chính sách để giảm thiểu sự thu thập dữ liệu.

(Lưu ý. Chúng tôi không thể đảm bảo việc bảo mật cho những thứ ngoài phạm vi của Windows, chẳng hạn như các trình duyệt và ứng dụng bên thứ ba.)

### 🛡️ Bảo mật hơn
Việc tải xuống một ISO đã được tuỳ chỉnh từ internet khá rủi ro. Nó không chỉ có thể chứa các tập lệnh độc hại mà khiến máy tính của bạn gặp rủi ro bảo mật nghiêm trọng.
Atlas thì khác. Chúng tôi sử dụng [AME Wizard](https://ameliorated.io) để cài đặt, và tất cả các tập lệnh được dùng đều có mã nguồn mở tại repository này của chúng tôi. Bạn còn có thể cài đặt những bản cập nhật bảo mật mới nhất trước khi cài đặt Atlas, giúp hệ thống của bạn an toàn và bảo mật.

### 🚀 Nhiều khoảng trống hơn
Những ứng dụng được cài đặt sẵn và những thành phần không cần thiết đã bị loại bỏ khỏi Atlas. Mặc dù sẽ có khả năng về các vấn đề tương thích, nhưng điều này làm giảm đáng kể kích thước bản cài đặt và khiến cho hệ thống của bạn mượt mà hơn. Do đó, các chức năng như Windows Defender và những thứ tương tự đã bị loại bỏ hoàn toàn. Hãy xem nhưng gì đã được loại bỏ trong [FAQ của chúng tôi](https://docs.atlasos.net/Troubleshooting/Removed%20features).

### ✅ Hiệu suất hơn
Một số tinh chỉnh hệ thống trên internet đã tinh chỉnh quá sâu, phá vỡ khả năng tương thích với những tính năng chính như Bluetooth, Wi-Fi, và hơn thế nữa. Atlas là một nơi tuyệt vời để bạn có thể nhận thêm hiệu năng, nhưng cũng duy trì được khả năng tương thích tốt.

Một số thay đổi mà chúng tôi đã làm để cải thiện Windows có thể kể tới như sau:

- Power scheme được tuỳ chỉnh riêng
- Giảm số lượng tiến trình và driver
- Vô hiệu hoá chế độ độc quyền âm thanh
- Vô hiệu hoá các thiết bị không cần thiết
- Vô hiệu hoá chế độ tiết kiệm pin (cho máy tính cá nhân)
- Vô hiệu hoá các biện pháp bảo mật mà ảnh hưởng tới hiệu năng
- Tự động kích hoạt chế độ MSI cho tất cả thiết bị
- Tối ưu cấu hình khởi động
- Tối ưu lên lịch tiến trình

### 🔒 Tính pháp lý
Rất nhiều phiên bản Windows được tuỳ chỉnh phân phối phiên bản của họ bằng cách đưa ra một tập tin ISO Windows được tuỳ chỉnh. Nó không chỉ vi phạm [Điều khoản dịch vụ của Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), mà nó cũng không phải là cách an toàn để cài đặt.

Atlas đã hợp tác với nhóm Windows Ameliorated để đưa ra cho người dùng một cách hợp pháp và an toàn hơn cho việc cài đặt, sử dụng [AME Wizard](https://ameliorated.io). Bằng cách này, Atlas hoàn toàn tuân thủ [Điều khoản dịch vụ của Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Bộ thương hiệu
Bạn cảm thấy sáng tạo? Bạn muốn tạo một hình nền Atlas của riêng bạn với những thiết kế sáng tạo? Bộ thương hiệu của chúng tôi là dành cho bạn!
Bộ thương hiệu của Atlas có thể truy cập một cách công khai, bạn có thể tải nó xuống [ở đây](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) và làm thứ gì đó thật đặc biệt!

Chúng tôi cũng có [một mục riêng trong diễn đàn của chúng tôi](https://forum.atlasos.net/t/art-showcase), bạn có thể chia sẻ sự sáng tạo của mình với các nhà thiết kế khác, hoặc có thể bạn cũng sẽ tìm được nguồn cảm hứng ở đó!

## ⚠️ Disclaimer
AtlasOS is **NOT** a pre-activated version of Windows, you **must** use a genuine key to activate Windows. Before you buy a Windows 10 (Pro OR Home) license, make sure the seller is trusted and the key is legitimate, no matter where you buy it. Atlas is based on Microsoft Windows, by using Windows you agree to [Microsoft's Terms of Service](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## Translation contributors (Những người đóng góp dịch thuật)

[Cuong Tien Dinh](https://github.com/dtcu0ng) | 
[Nguyễn Cao Hoài Nam](https://github.com/sant1ago-da-hanoi) |
[Nguyen Thuy Linh](https://github.com/WhiteSnow00)