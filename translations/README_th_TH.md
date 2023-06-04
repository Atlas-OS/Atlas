⚠️หมายเหตุ: นี่คือเวอร์ชันแปลของต้นฉบับ [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), ข้อมูลที่นี่อาจไม่ถูกต้องและอาจล้าสมัย
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="ใบอนุญาต" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="ผู้มีส่วนร่วม" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="เผยแพร่" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="ดาวน์โหลด เวอร์ชั่นเผยแพร่" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">การปรับเปลี่ยน Windows แบบเปิดและโปร่งใส ออกแบบมาเพื่อเพิ่มประสิทธิภาพ ความเป็นส่วนตัว และความเสถียร</h4>

<p align="center">
  <a href="https://atlasos.net">เว็บไซต์</a>
  •
  <a href="https://docs.atlasos.net">เอกสารประกอบ</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">ดิสคอร์ด</a>
  •
  <a href="https://forum.atlasos.net">ฟอรัม</a>
</p>

## 🤔 **Atlas คืออะไร**

Atlas เป็นการดัดแปลง Windows ซึ่งจะลบข้อเสียเกือบทั้งหมดของ Windows ที่ส่งผลเสียต่อประสิทธิภาพการเล่นเกม
Atlas ยังเป็นตัวเลือกที่ดีในการลดเวลาแฝงของระบบ เวลาแฝงของเครือข่าย ความหน่วงของการนำเข้า และทำให้ระบบของคุณเป็นส่วนตัวในขณะที่มุ่งเน้นไปที่ประสิทธิภาพ
คุณสามารถเรียนรู้เพิ่มเติมเกี่ยวกับ Atlas ได้ที่ [เว็บไซต์](https://atlasos.net).

## 📚 **สารบัญ**

- [แนวทางการมีส่วนร่วม](https://docs.atlasos.net/contributions)

- เริ่มต้นใช้งาน
  - [การติดตั้ง](https://docs.atlasos.net/getting-started/installation)
  - [วิธีการติดตั้งอื่นๆ](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [หลังการติดตั้ง](https://docs.atlasos.net/getting-started/post-installation/drivers)

- การแก้ไขปัญหา
  - [ฟีเจอร์ที่ถูกลบ](https://docs.atlasos.net/troubleshooting/removed-features)
  - [สคริปต์](https://docs.atlasos.net/troubleshooting/scripts)

- คำถามที่พบบ่อย
  - [Atlas](https://atlasos.net/faq)
  - [ปัญหาทั่วไป](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **ทำไมต้อง Atlas**

### 🔒 เป็นส่วนตัวกว่า
Windows ดังเดิม มีบริการติดตามที่รวบรวมข้อมูลของคุณและอัปโหลดไปยัง Microsoft
Atlas ลบการติดตามทุกประเภทที่ฝังอยู่ภายใน Windows และใช้นโยบายกลุ่มจำนวนมากเพื่อลดการรวบรวมข้อมูล

โปรดทราบว่า Atlas ไม่สามารถรับประกันความปลอดภัยสำหรับสิ่งที่อยู่นอกขอบเขตของ Windows (เช่น เบราว์เซอร์และแอปพลิเคชันของบุคคลที่สาม)

### 🛡️ปลอดภัยยิ่งขึ้น (มากกว่า Windows ISO แบบกำหนดเอง)
การดาวน์โหลด Windows ISO ที่แก้ไขแล้วจากอินเทอร์เน็ตมีความเสี่ยง ไม่เพียงแต่ผู้คนจะสามารถเปลี่ยนไฟล์ไบนารี/ไฟล์เรียกทำงานไฟล์ใดไฟล์หนึ่งจากหลายไฟล์ที่รวมอยู่ใน Windows โดยเจตนาร้ายได้อย่างง่ายดาย แต่ยังอาจไม่มีแพตช์ความปลอดภัยล่าสุดที่สามารถทำให้คอมพิวเตอร์ของคุณตกอยู่ภายใต้ความเสี่ยงด้านความปลอดภัยขั้นร้ายแรง

Atlas แตกต่างออกไป เราใช้ [AME Wizard](https://ameliorated.io) เพื่อติดตั้ง Atlas และสคริปต์ทั้งหมดที่เราใช้เป็นโอเพ่นซอร์สใน GitHub repository คุณสามารถดู Playbook ของ Atlas แบบแพ็กเกจ (`.apbx` - AME Wizard script package) เป็นไฟล์เก็บถาวร โดยมีรหัสผ่านเป็น `malte` (มาตรฐานสำหรับ Playbook ของ AME Wizard) ซึ่งใช้เพื่อเลี่ยงการติดธงเท็จจากโปรแกรมป้องกันไวรัสเท่านั้น

โปรแกรมสั่งการเฉพาะที่รวมอยู่ใน Playbook เป็นโอเพ่นซอร์ส [ที่นี่](https://github.com/Atlas-OS/Atlas-Utilities) ภายใต้ [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) โดยแฮชจะเหมือนกับการเผยแพร่ อย่างอื่นเป็นข้อความล้วน

คุณยังสามารถติดตั้งการอัปเดตความปลอดภัยล่าสุดก่อนที่จะติดตั้ง Atlas ซึ่งเราแนะนำให้คุณรักษาระบบของคุณให้ปลอดภัย

โปรดทราบว่าตั้งแต่ Atlas v0.2.0 เป็นต้นมา Atlas นั้น **ไม่ปลอดภัยเท่ากับ Windows ทั่วไป** เนื่องจากคุณลักษณะด้านความปลอดภัยที่ถูกลบ/ปิดใช้งาน เช่น Windows Defender ถูกลบออกไป อย่างไรก็ตาม ใน Atlas v0.3.0 คุณลักษณะเหล่านี้ส่วนใหญ่จะถูกเพิ่มกลับเป็นคุณสมบัติเสริม ดู[ที่นี่](https://docs.atlasos.net/troubleshooting/removed-features/) สำหรับข้อมูลเพิ่มเติม

### 🚀 พื้นที่มากขึ้น
แอปพลิเคชันที่ติดตั้งไว้ล่วงหน้าและส่วนประกอบที่ไม่สำคัญอื่นๆ จะถูกลบออกด้วย Atlas แม้จะมีปัญหาเรื่องความเข้ากันได้ แต่วิธีนี้ช่วยลดขนาดการติดตั้งลงได้อย่างมาก และทำให้ระบบของคุณคล่องขึ้น ดังนั้น ฟังก์ชันการทำงานบางอย่าง (เช่น Windows Defender) จึงถูกตัดออกทั้งหมด
ดูว่ามีอะไรอีกบ้างที่เรานำออกใน[คำถามที่พบบ่อย](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ ประสิทธิภาพมากขึ้น
ระบบที่ปรับแต่งบางระบบบนอินเทอร์เน็ตได้ปรับแต่ง Windows มากเกินไป ทำลายความเข้ากันได้ของคุณสมบัติหลัก เช่น Bluetooth, Wi-Fi และอื่นๆ
Atlas อยู่ในจุดที่น่าสนใจ มีจุดมุ่งหมายเพื่อให้ได้ประสิทธิภาพมากขึ้นในขณะที่รักษาระดับความเข้ากันได้ที่ดี

การเปลี่ยนแปลงหลายอย่างที่เราได้ทำเพื่อปรับปรุง Windows มีดังต่อไปนี้:
- รูปแบบพลังงานที่กำหนดเอง
- ลดจำนวนบริการและไดรเวอร์
- ปิดเสียงพิเศษ
- ปิดการใช้งานอุปกรณ์ที่ไม่จำเป็น
- ปิดการประหยัดพลังงาน (สำหรับคอมพิวเตอร์ส่วนบุคคล)
- ปิดใช้งานการบรรเทาความปลอดภัยที่กระหายประสิทธิภาพ
- เปิดใช้งานโหมด MSI โดยอัตโนมัติบนอุปกรณ์ทั้งหมด
- การกำหนดค่าการบูตที่ปรับให้เหมาะสม
- ปรับตารางกระบวนการให้เหมาะสม

### 🔒 ถูกกฎหมาย
ถูกกฎหมาย
ระบบปฏิบัติการ Windows แบบกำหนดเองจำนวนมากแจกจ่ายระบบของตนโดยจัดเตรียม ISO ของ Windows ที่ปรับแต่งแล้ว ไม่เพียงละเมิด[ข้อกำหนดในการให้บริการของ Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) แต่ยังไม่ใช่วิธีที่ปลอดภัยในการติดตั้งอีกด้วย

Atlas ร่วมมือกับ Windows Ameliorated Team เพื่อมอบวิธีที่ปลอดภัยและถูกกฎหมายแก่ผู้ใช้ในการติดตั้ง: the [AME Wizard](https://ameliorated.io) ด้วยวิธีนี้ Atlas จึงปฏิบัติตาม[ข้อกำหนดในการให้บริการของ Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) โดยสมบูรณ์

## 🎨 ชุดแบรนด์
รู้สึกสร้างสรรค์? ต้องการสร้างวอลเปเปอร์ Atlas ของคุณเองด้วยการออกแบบที่สร้างสรรค์หรือไม่? ชุดแบรนด์ของเราครอบคลุมคุณแล้ว!
ใครๆ ก็เข้าถึงชุดแบรนด์ Atlas ได้ — คุณสามารถดาวน์โหลดได้ [ที่นี่](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) และสร้างสิ่งที่น่าทึ่ง!

นอกจากนี้ เรายังมีพื้นที่เฉพาะใน [ฟอรัม](https://forum.atlasos.net/t/art-showcase) เพื่อให้คุณสามารถแบ่งปันผลงานสร้างสรรค์ของคุณกับอัจฉริยะด้านความคิดสร้างสรรค์คนอื่นๆ และอาจจุดประกายแรงบันดาลใจได้ด้วย! คุณยังสามารถค้นหาวอลเปเปอร์สุดสร้างสรรค์ที่ผู้ใช้รายอื่นแบ่งปันได้ที่นี่อีกด้วย!

## ⚠️ ข้อจำกัดความรับผิดชอบ
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## ผู้ร่วมแปล
[NginREV](https://github.com/NginREV)
