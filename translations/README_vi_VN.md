⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Giấy phép" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Những người đóng góp" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Bản phát hành" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Tải bản phát hành" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Bản tinh chỉnh mở và minh bạch cho Windows, được thiết kế để tối ưu hiệu năng, sự riêng tư và ổn định</h4>

<p align="center">
  <a href="https://atlasos.net">Website</a>
  •
  <a href="https://docs.atlasos.net">Tài liệu</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Diễn đàn</a>
</p>

## 🤔 **Atlas là gì?**

Atlas là một công cụ tinh chỉnh cho Windows, loại bỏ hầu như tất cả những nhược điểm của Windows làm ảnh hưởng tới hiệu năng chơi game.
Ngoài ra, Atlas còn là một lựa chọn tốt để giảm độ trễ của hệ thống, mạng, đầu vào và giữ cho hệ thống của bạn bảo mật trong khi tập trung vào hiệu năng.
Bạn có thể tìm hiểu thêm về Atlas trên [trang web chính thức của chúng tôi](https://atlasos.net).

## 📚 **Mục lục**

- [Nguyên tắc đóng góp](https://docs.atlasos.net/contributions)

- Bắt đầu
  - [Cài đặt](https://docs.atlasos.net/getting-started/installation)
  - [Các cách cài đặt khác](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Sau khi cài đặt](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Xử lý sự cố
  - [Những tính năng đã bị loại bỏ](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Các tập lệnh](https://docs.atlasos.net/troubleshooting/scripts)

- Các câu hỏi thường gặp (FAQ)
  - [Atlas](https://atlasos.net/faq)
  - [Các vấn đề chung](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Tại sao nên dùng Atlas?**

### 🔒 Riêng tư hơn
Phiên bản Windows gốc có chứa những dịch vụ theo dõi, nó thu thập dữ liệu của bạn và gửi chúng tới Microsoft.
Atlas loại bỏ tất cả các trình theo dõi được nhúng trong Windows và triển khai nhiều nhóm chính sách để giảm thiểu sự thu thập dữ liệu.

Lưu ý rằng chúng tôi không thể đảm bảo việc bảo mật cho những thứ ngoài phạm vi của Windows (chẳng hạn như là các trình duyệt và ứng dụng bên thứ ba).

### 🛡️ Bảo mật hơn (những ISO Windows đã được tuỳ chỉnh)
Việc tải xuống một ISO đã được tuỳ chỉnh từ internet khá rủi ro. Ngoài việc mọi người có thể dễ dàng thêm mã độc và thay đổi những thành phần được đi cùng với Windows, nó còn có thể không có những bản vá bảo mật mới nhất khiến máy tính của bạn gặp những rủi ro bảo mật nghiêm trọng.

Atlas thì khác. Chúng tôi sử dụng [AME Wizard](https://ameliorated.io) để cài đặt, và tất cả các tập lệnh được sử dụng đều có mã nguồn mở tại kho lưu trữ này của chúng tôi. Bạn có thể xem playbook Atlas đã được đóng gói (`.apbx` - gói tập lệnh AME Wizard) như là một tập tin nén, với mật khẩu là `malte` (mật khẩu mặc định cho các playbook của AME Wizard), với mục đích chỉ để vượt qua những phát hiện giả của các trình diệt virus.

Những tệp thực thi được đưa vào trong playbook đều có mã nguồn mở [tại đây](https://github.com/Atlas-OS/Atlas-Utilities) dưới [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), với các giá trị băm giống với các bản phát hành. Mọi thứ khác đều ở dạng văn bản thuần túy.

Bạn còn có thể cài đặt những bản cập nhật bảo mật mới nhất trước khi cài đặt Atlas, điều mà chúng tôi khuyên làm để giữ cho hệ thống của bạn an toàn và bảo mật.

Vui lòng lưu ý là ở phiên bản Atlas v0.2.0, Atlas hầu như **không bảo mật như phiên bản Windows thường** bởi vì đã loại bỏ/tắt những tính năng bảo mật, như là Windows Defender bị loại bỏ. Nhưng trong phiên bản Atlas v0.3.0, hầu hết chúng sẽ được thêm trở lại như là một tính năng tuỳ chọn. Xem [tại đây](https://docs.atlasos.net/troubleshooting/removed-features/) để biết thêm chi tiết.

### 🚀 Nhiều khoảng trống hơn
Những ứng dụng được cài đặt sẵn và những thành phần không cần thiết đã bị loại bỏ khỏi Atlas. Mặc dù sẽ có khả năng về các vấn đề tương thích, nhưng điều này làm giảm đáng kể kích thước bản cài đặt và khiến cho hệ thống của bạn mượt mà hơn. Do đó, các chức năng như Windows Defender và những thứ tương tự đã bị loại bỏ hoàn toàn. Hãy xem những gì đã được chúng tôi loại bỏ trong mục [Những tính năng Bị loại bỏ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Hiệu năng hơn
Một số tinh chỉnh hệ thống trên internet đã tinh chỉnh quá sâu, làm mất đi khả năng tương thích với những tính năng chính như Bluetooth, Wi-Fi, và hơn thế nữa. Atlas là một nơi tuyệt vời để bạn có thể nhận thêm hiệu năng, nhưng cũng duy trì được khả năng tương thích tốt.

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
Rất nhiều phiên bản Windows được tuỳ chỉnh phân phối phiên bản của họ bằng cách đưa ra cho người dùng một tập tin ISO Windows đã bị chỉnh sửa. Nó không chỉ vi phạm [Điều khoản dịch vụ của Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), mà nó cũng không phải là cách an toàn để cài đặt.

Atlas đã hợp tác với nhóm Windows Ameliorated để đưa ra cho người dùng một cách hợp pháp và an toàn hơn cho việc cài đặt, sử dụng [AME Wizard](https://ameliorated.io). Bằng cách này, Atlas hoàn toàn tuân thủ [Điều khoản dịch vụ của Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Bộ thương hiệu
Bạn cảm thấy sáng tạo? Bạn muốn tạo một hình nền Atlas của riêng bạn với những thiết kế sáng tạo? Bộ thương hiệu của chúng tôi là dành cho bạn!
Bộ thương hiệu của Atlas có thể truy cập một cách công khai, bạn có thể tải nó xuống [ở đây](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) và làm thứ gì đó thật đặc biệt!

Chúng tôi cũng có [một mục riêng trong diễn đàn của chúng tôi](https://forum.atlasos.net/t/art-showcase), bạn có thể chia sẻ sự sáng tạo của mình với các nhà thiết kế khác, hoặc có thể bạn cũng sẽ tìm được nguồn cảm hứng ở đó!

## ⚠️ Disclaimer (Tuyên bố từ chối trách nhiệm)
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## Translation contributors (Những người đóng góp dịch thuật)
[Cuong Tien Dinh](https://github.com/dtcu0ng) | 
[Nguyễn Cao Hoài Nam](https://github.com/sant1ago-da-hanoi) | 
[Nguyen Thuy Linh](https://github.com/WhiteSnow00)
