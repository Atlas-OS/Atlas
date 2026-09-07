### Atlas Manager: ไทย (Thai) — preview translation, revised on 6 September 2026 from the en-GB source.
###
### This complete translation follows the en-GB source semantically, not
### sentence by sentence. Ids are stable identifiers, never shown to users.
### Comments above a message say where it appears and what its variables hold.
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically. Thai has only the CLDR category "other", so use a plain
###   sentence with a classifier ("{ $count } รายการ"); exact selectors such
###   as [1] and [2] are allowed where the wording changes.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
### - "Atlas", "AtlasOS", "Windows", "Defender", "GitHub" are product names.
###   Windows features use the names Thai Windows shows: the app is
###   "ความปลอดภัยของ Windows" (written "แอป ความปลอดภัยของ Windows" when it is
###   the object of "open"), and the four switches are named on the
###   "การตั้งค่าการป้องกันไวรัสและภัยคุกคาม" page.
### - Thai punctuation: no full stop at the end of a sentence; separate
###   sentences and clauses with a space; put a space on both sides of Latin
###   words and numbers. Buttons are short and verb-first.
### - "รีสตาร์ต" always means restarting the PC / Windows; "เปิด Atlas ใหม่"
###   always means reopening this app.

## Shared

app-name = Atlas Manager
common-done = เสร็จสิ้น
common-cancel = ยกเลิก
common-back = ย้อนกลับ
common-next = ดำเนินการต่อ
common-dismiss = ปิด
# Link beside a summary row that jumps back to change that choice.
common-change = เปลี่ยน
common-copy = คัดลอก
# Shown where a list of options is empty.
common-none = ไม่มี
# Accessible description of a disabled control.
common-not-available = ยังใช้ไม่ได้ในขณะนี้
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = กลับไปหน้าหลัก
# Accessible name of the gear button in the title bar.
common-settings = การตั้งค่า
common-close-settings = ปิดการตั้งค่า
# "แอป" avoids reading "เปิดความปลอดภัย" as "turn on security".
common-open-windows-security = เปิดแอป ความปลอดภัยของ Windows
common-restart-as-administrator = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ
common-try-again = ลองอีกครั้ง
common-read-the-docs = อ่านคู่มือ Atlas
common-show-details = แสดงรายละเอียด
common-hide-details = ซ่อนรายละเอียด
common-open-log-file = เปิดไฟล์บันทึก
# Accessible name of the Copy button beside the install log.
common-copy-install-log = คัดลอกบันทึกการติดตั้ง
common-install-log = บันทึกการติดตั้ง
# Row labels in summary cards.
common-windows = Windows
common-options = ตัวเลือก
common-package = ไฟล์ติดตั้ง
common-installed-as = ประเภทการติดตั้ง
common-installed = ติดตั้งแล้ว
common-checking = กำลังตรวจสอบ
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } หรือ { $b }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = ปิดหน้าต่างขณะที่ Atlas กำลังติดตั้งหรือไม่
window-close-message = การติดตั้งจะดำเนินต่อไปในเบื้องหลัง เปิด Atlas อีกครั้งเพื่อดูความคืบหน้าและผลลัพธ์ และเปิดพีซีไว้จนกว่าจะเสร็จ
window-close-keep = เปิดหน้าต่างไว้
window-close-close = ปิดหน้าต่าง
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = เปิด playbook ของ Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = ติดตั้ง Atlas แล้ว กำลังรีสตาร์ต Windows เพื่อตั้งค่าให้เสร็จสมบูรณ์

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (บิลด์ { $build })

## Home page

home-not-installed = ยินดีต้อนรับสู่ Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = ติดตั้งเมื่อ { $date }
home-status-checking = กำลังตรวจหาการอัปเดต
home-status-offline = ตรวจหาการอัปเดตไม่ได้
home-status-not-checked = ยังไม่ได้ตรวจหาการอัปเดต
home-status-update = มี Atlas { $version } ให้อัปเดต
home-status-up-to-date = เป็นเวอร์ชันล่าสุดแล้ว
home-status-newest = เวอร์ชันล่าสุด: Atlas { $version }
home-check-again = ตรวจสอบอีกครั้ง
# Primary button while an install is running or waiting.
home-show-install = ดูความคืบหน้า
home-continue-installing = ตั้งค่าต่อ
home-update-to = อัปเดตเป็น Atlas { $version }
home-reinstall = ติดตั้ง Atlas ใหม่
home-install = ติดตั้ง Atlas
home-start-over = เริ่มใหม่ตั้งแต่ต้น
home-security-reminder-title = เปิดการป้องกันของคุณอีกครั้ง
home-security-reminder-message = ขณะนี้ไม่มีการติดตั้งที่กำลังทำงาน เปิดแอป ความปลอดภัยของ Windows แล้วเปิดสวิตช์ทั้งสี่รายการ ได้แก่ การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย การป้องกันแบบเรียลไทม์ การป้องกันบนระบบคลาวด์ และการส่งตัวอย่างโดยอัตโนมัติ
home-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
home-state-error-title = อ่านรายละเอียดการติดตั้ง Atlas ของคุณไม่ได้
home-whats-new = มีอะไรใหม่ใน Atlas { $version }
home-view-release = ดูบันทึกประจำรุ่นบน GitHub
home-released = เผยแพร่เมื่อ { $date }
home-show-less = แสดงน้อยลง
home-show-full-notes = แสดงบันทึกประจำรุ่นทั้งหมด
home-your-install = การตั้งค่า Atlas ของคุณ
# Row label: how Atlas was set up.
home-set-up = วิธีการตั้งค่า
home-set-up-during-oobe = ระหว่างการตั้งค่า Windows
home-history = ประวัติการติดตั้ง
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = เตรียมพีซีของคุณให้พร้อมสำหรับ Atlas
home-step-1-title = ตรวจสอบพีซีของคุณ
home-step-1-detail = Atlas จะตรวจสอบ Windows และดาวน์โหลดไฟล์ติดตั้ง โดยการตั้งค่า Windows ของคุณจะยังคงเดิม
home-step-2-title = เลือกให้เหมาะกับคุณ
home-step-2-detail = เลือกวิธีที่ Windows จัดการการป้องกันและการอัปเดต แล้วเลือกแอปหรือการตั้งค่าเพิ่มเติมตามต้องการ
home-step-3-title = พักการป้องกันไวรัสไว้ชั่วคราว
home-step-3-detail = Atlas จะแนะนำวิธีปิดสวิตช์สี่รายการในแอป ความปลอดภัยของ Windows เพื่อไม่ให้ขัดขวางการติดตั้ง
home-step-4-title = ติดตั้งและรีสตาร์ต
home-step-4-detail = ประมาณ { $minutes } นาที
# Accessible name of a numbered step.
home-step-a11y = ขั้นตอนที่ { $number }: { $title }
home-github = ดู Atlas บน GitHub
home-discord = เข้าร่วมชุมชน Atlas บน Discord
home-report-problem = รายงานปัญหาบน GitHub

## How an install was done (from the state document)

mode-fresh = การติดตั้งครั้งแรก
mode-upgrade = การอัปเดตจากเวอร์ชันก่อนหน้า
mode-reapply = การติดตั้งเวอร์ชันเดิมซ้ำ
mode-unknown = การติดตั้ง
# Lower-case forms used inside a history row.
history-mode-fresh = ติดตั้งครั้งแรก
history-mode-upgrade = อัปเดต
history-mode-reapply = ติดตั้งซ้ำ
history-mode-unknown = ติดตั้ง

## Notices on the Home page

notice-settings-reset-title = Atlas กำลังใช้การตั้งค่าเริ่มต้นของแอป
# $error is a raw error message (text).
notice-settings-unreadable = Atlas อ่านการตั้งค่าแอปที่บันทึกไว้ไม่ได้ การตั้งค่า Windows ของคุณไม่ได้เปลี่ยนแปลง รายละเอียด: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = ไฟล์การตั้งค่าแอปของคุณเสียหายและถูกรีเซ็ตแล้ว โดยบันทึกสำเนาของไฟล์เดิมไว้เป็น { $file } รายละเอียด: { $error }
notice-settings-damaged = ไฟล์การตั้งค่าแอปของคุณเสียหาย Atlas จะใช้ค่าเริ่มต้นไปก่อน รายละเอียด: { $error }
notice-settings-not-saved-title = บันทึกการตั้งค่าแอปไม่ได้
notice-session-unreadable-title = ตรวจสอบการติดตั้งครั้งก่อนไม่ได้
# $path is a file path (text).
notice-session-unreadable-message = Atlas อ่าน { $path } ไม่ได้ จึงไม่ทราบว่ายังมีการติดตั้งที่กำลังทำงานอยู่หรือไม่ หากไม่แน่ใจ ให้ขอความช่วยเหลือจากชุมชน Atlas ก่อนลบไฟล์นี้ และลบไฟล์แล้วลองอีกครั้งเฉพาะเมื่อยืนยันแล้วว่าไม่มีการติดตั้งที่กำลังทำงานอยู่ รายละเอียด: { $error }

## Administrator elevation

elevation-declined = ไม่ได้รับสิทธิ์ ลองอีกครั้ง แล้วเลือก ใช่ เมื่อ Windows ถามว่าจะอนุญาตให้ Atlas ทำการเปลี่ยนแปลงหรือไม่
elevation-declined-continue = ไม่ได้รับสิทธิ์ ลองอีกครั้ง แล้วเลือก ใช่ เมื่อ Windows ถามว่าจะอนุญาตให้ Atlas ทำการเปลี่ยนแปลงหรือไม่ ตัวเลือกการตั้งค่าของคุณบันทึกไว้แล้ว
elevation-draft-not-saved = Atlas บันทึกตัวเลือกการตั้งค่าของคุณไม่ได้ จึงยังไม่ได้เปิด Atlas ใหม่ ลองอีกครั้ง รายละเอียด: { $error }

## The install flow

step-ready = เตรียมความพร้อม
step-options = ตัวเลือกของคุณ
step-security = ความปลอดภัยของ Windows
step-install = ติดตั้ง
install-title = ตั้งค่า Atlas
# Accessible name of the row of steps.
stepper-label = ขั้นตอนการตั้งค่า Atlas
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = ขั้นตอนที่ { $number } จาก { $total }, { $title }, { $status }
stepper-status-completed = เสร็จแล้ว
stepper-status-current = ขั้นตอนปัจจุบัน
stepper-status-upcoming = ยังไม่ถึง
# Heading above each step's content.
step-heading = ขั้นตอนที่ { $number } จาก { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = กำลังเตรียมพีซีของคุณ
ready-banner-busy-message = Atlas กำลังตรวจสอบ PC และเตรียมไฟล์ติดตั้ง
ready-banner-blocked-title = พีซีของคุณยังต้องเตรียมการอีกเล็กน้อย
ready-banner-blocked-message = ทำตามคำแนะนำด้านล่าง แล้วเลือก ตรวจสอบอีกครั้ง
ready-banner-no-package-title = ดาวน์โหลด Atlas เพื่อดำเนินการต่อ
ready-banner-no-package-message = ดาวน์โหลดเวอร์ชันล่าสุดด้านล่าง หรือเปิด playbook ของ Atlas (.apbx) ที่บันทึกไว้
ready-banner-warnings-title = มีบางอย่างที่ควรตรวจดู
ready-banner-warnings-message = อ่านหมายเหตุด้านล่างและทำตามคำแนะนำก่อนดำเนินการต่อ
ready-banner-ok-title = พร้อมเลือกการตั้งค่าแล้ว
ready-banner-ok-message = ผ่านการตรวจสอบทุกรายการ และไฟล์ติดตั้งพร้อมแล้ว

# Card title and accessible name of the list of checks.
ready-this-pc = การตรวจสอบพีซี
ready-check-again = ตรวจสอบอีกครั้ง
package-title = ไฟล์ติดตั้ง
# $received and $total are formatted numbers of megabytes (text).
package-downloading = กำลังดาวน์โหลด Atlas { $version } · { $received } จาก { $total } MB
package-unpacking-progress = กำลังแตกไฟล์ · { $done } จาก { $total } ไฟล์
package-unpacking = กำลังแตกไฟล์
package-looking = กำลังตรวจหา Atlas เวอร์ชันล่าสุด
package-none = ยังไม่มีไฟล์ติดตั้ง โดย playbook (.apbx) คือไฟล์ที่มีคำสั่งและไฟล์ต่าง ๆ ที่ Atlas ต้องใช้
# Short status words beside the card title.
package-status-downloading = กำลังดาวน์โหลด
package-status-unpacking = กำลังแตกไฟล์
package-status-failed = เตรียมไฟล์ไม่ได้
package-status-ready = พร้อม
package-status-checking = กำลังตรวจสอบ
package-status-missing = ยังไม่ได้ดาวน์โหลด
# Accessible name of the progress bar.
package-progress = ความคืบหน้าของไฟล์ติดตั้ง
package-download-again = ดาวน์โหลดอีกครั้ง
package-download-version = ดาวน์โหลด Atlas { $version }
package-download-newest = ดาวน์โหลดเวอร์ชันล่าสุด
package-open-file = เปิดไฟล์ playbook
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = ดาวน์โหลด Atlas { $version } จาก GitHub แล้ว พร้อมติดตั้ง
package-from-file = โหลด Atlas { $version } จาก { $file } แล้ว พร้อมติดตั้ง
package-unpacked = Atlas { $version } พร้อมติดตั้งแล้ว
package-at = ไฟล์ติดตั้ง: { $path }
package-none-yet = ยังไม่ได้เลือกไฟล์ติดตั้ง
acquire-no-asset = Atlas { $version } ไม่มีไฟล์ playbook ให้ดาวน์โหลด เปิด playbook ของ Atlas (.apbx) ที่บันทึกไว้เพื่อดำเนินการต่อ
acquire-unsupported = แอปนี้ติดตั้งได้เฉพาะ Atlas 0.6.0 ขึ้นไป หากต้องการติดตั้ง Atlas { $version } ให้ใช้ AME Wizard แทน
acquire-failed = เตรียมไฟล์ติดตั้งไม่ได้ ลองดาวน์โหลดอีกครั้ง หรือเปิด playbook ของ Atlas (.apbx) อีกไฟล์หนึ่ง รายละเอียด: { $error }

## System checks

check-administrator = สิทธิ์ในการติดตั้ง
check-supported-build = ความเข้ากันได้กับ Windows
check-pending-updates = การอัปเดต Windows
check-pending-reboot = การรีสตาร์ตที่ค้างอยู่
check-third-party-antivirus = โปรแกรมป้องกันไวรัสอื่น
check-internet = การเชื่อมต่ออินเทอร์เน็ต
check-power = แหล่งจ่ายไฟ
check-activation = การเปิดใช้งาน Windows
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = กำลังตรวจสอบ
check-state-passed = ผ่าน
check-state-warning = ควรตรวจดู
check-state-failed-blocking = ต้องแก้ไขก่อนติดตั้ง
check-state-failed = ควรตรวจดู
check-state-unknown = ตรวจสอบไม่ได้
check-fix-windows-update = เปิด Windows Update
check-fix-network = เปิดการตั้งค่าเครือข่าย
check-fix-power = เปิดการตั้งค่าพลังงาน
check-fix-activation = ไปที่การตั้งค่าการเปิดใช้งาน
# Check boxes the user ticks when a check could not run.
check-ack-updates = ฉันตรวจสอบ Windows Update แล้ว ไม่มีการอัปเดตที่รอติดตั้ง
check-ack-reboot = ฉันรีสตาร์ต Windows แล้ว และไม่ต้องรีสตาร์ตอีก
check-ack-internet = พีซีเครื่องนี้เชื่อมต่ออินเทอร์เน็ตอยู่
check-ack-generic = ฉันตรวจสอบข้อกำหนดนี้ด้วยตนเองแล้ว

detail-admin-ok = Atlas มีสิทธิ์ทำการเปลี่ยนแปลงที่จำเป็นสำหรับการติดตั้ง
detail-admin-missing = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วเลือก ใช่ เมื่อ Windows ขอสิทธิ์
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas เวอร์ชันนี้ต้องใช้ Windows บิลด์ { $builds } แต่พีซีของคุณเป็นบิลด์ { $build } ติดตั้ง Windows เวอร์ชันที่รองรับก่อนดำเนินการต่อ
detail-updates-none = ไม่มีการอัปเดต Windows ที่รอติดตั้ง
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] ติดตั้งการอัปเดตนี้ก่อน: { $titles }
        [2] ติดตั้งการอัปเดตเหล่านี้ก่อน: { $titles }
       *[other] ติดตั้งการอัปเดต { $count } รายการก่อน รวมถึง { $titles }
    }
detail-updates-unknown = ตรวจหาการอัปเดต Windows ไม่ได้ เปิด Windows Update แล้วยืนยันด้านล่างหากไม่มีการอัปเดตที่รอติดตั้ง ({ $error })
detail-reboot-none = Windows ไม่จำเป็นต้องรีสตาร์ตในขณะนี้
detail-reboot-pending = รีสตาร์ตพีซีเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ จากนั้นเปิด Atlas อีกครั้งแล้วตรวจสอบใหม่
detail-reboot-unknown = ตรวจสอบไม่ได้ว่า Windows ต้องรีสตาร์ตหรือไม่ รีสตาร์ตพีซี จากนั้นเปิด Atlas อีกครั้งแล้วตรวจสอบใหม่ ({ $error })
detail-antivirus-none = ไม่พบโปรแกรมป้องกันไวรัสอื่น
# $products is a list of product names (text).
detail-antivirus-found = โปรแกรมป้องกันไวรัสอาจขัดขวางการติดตั้ง: { $products } ถอนการติดตั้งซอฟต์แวร์นี้ก่อนดำเนินการต่อ
detail-antivirus-unknown = ตรวจหาโปรแกรมป้องกันไวรัสอื่นไม่ได้ ตรวจดูแอปที่ติดตั้งไว้ก่อนดำเนินการต่อ ({ $error })
detail-internet-ok = เชื่อมต่ออินเทอร์เน็ตอยู่ เชื่อมต่อไว้ตลอดขณะที่ Atlas ดาวน์โหลดและติดตั้งซอฟต์แวร์
detail-internet-missing = เชื่อมต่ออินเทอร์เน็ต แล้วตรวจสอบอีกครั้ง
detail-power-mains = พีซีของคุณเสียบปลั๊กอยู่ เสียบปลั๊กไว้จนกว่าการติดตั้งจะเสร็จ
detail-power-battery = เสียบปลั๊กพีซีของคุณเพื่อให้เปิดอยู่ตลอดการติดตั้ง
detail-power-unknown = ตรวจสอบแหล่งจ่ายไฟไม่ได้ หากใช้แล็ปท็อป ให้เสียบปลั๊กก่อนดำเนินการต่อ
detail-activation-ok = Windows เปิดใช้งานแล้ว Atlas จะไม่เปลี่ยนแปลงสิ่งนี้
detail-activation-missing = Windows ยังไม่ได้เปิดใช้งาน คุณดำเนินการต่อได้ แต่ Atlas จะไม่เปิดใช้งาน Windows ให้
detail-activation-no-licence = Windows ไม่ได้รายงานสิทธิ์การใช้งาน คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ
detail-activation-unknown = ตรวจสอบการเปิดใช้งาน Windows ไม่ได้ คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ ({ $error })

## Step 2: Options

options-progress = ตัวเลือกที่ { $number } จาก { $total }
options-progress-extras = ตัวเลือกที่ { $number } จาก { $total }: รายการเพิ่มเติม
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = เปิดการป้องกันไวรัสไว้ต่อไปหรือไม่
screen-mitigations-title = ความปลอดภัยของตัวประมวลผล
screen-mitigations-question = เก็บการป้องกันตัวประมวลผลของ Windows ไว้หรือไม่
screen-updates-title = Windows Update
screen-updates-question = ต้องการให้ Windows ติดตั้งการอัปเดตอย่างไร
screen-browser-title = เบราว์เซอร์
screen-power-title = พลังงานและความปลอดภัย
screen-apps-title = แอป
screen-optional-apps-title = แอปเสริม
screen-choose-one-title = เลือกหนึ่งตัวเลือก
screen-extras-title = รายการเพิ่มเติม
screen-extras-question = เลือกรายการเพิ่มเติมที่คุณต้องการ
# Question for a required choice this app has no specific wording for.
screen-generic-question = เลือกตัวเลือกสำหรับ { $title }
learn-more-defender = เรียนรู้เพิ่มเติมเกี่ยวกับ Microsoft Defender
learn-more-mitigations = อ่านเกี่ยวกับความปลอดภัยของตัวประมวลผล
learn-more-updates = เรียนรู้เพิ่มเติมเกี่ยวกับ Windows Update
learn-more-browser = เรียนรู้เพิ่มเติมเกี่ยวกับเบราว์เซอร์
learn-more-power = เรียนรู้เพิ่มเติมเกี่ยวกับพลังงานและความปลอดภัย
learn-more-apps = เรียนรู้เพิ่มเติมเกี่ยวกับแอป
learn-more-eclean = eclean ทำงานร่วมกับ AtlasOS อย่างไร
learn-more-generic = อ่านคู่มือการตั้งค่า
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = เก็บโปรแกรมป้องกันไวรัสที่มาพร้อม Windows ไว้ เพื่อช่วยปกป้องพีซีของคุณจากไวรัสและภัยคุกคามอื่น ๆ
consequence-defender-disable = นำ Microsoft Defender ออก พีซีของคุณจะไม่มีการป้องกันไวรัสจนกว่าคุณจะติดตั้งแอปป้องกันไวรัสอื่น
consequence-mitigations-default = เก็บการป้องกันเริ่มต้นของ Windows ไว้ เพื่อป้องกันการโจมตีที่อาศัยช่องโหว่ในการทำงานของตัวประมวลผล
consequence-mitigations-disable = ปิดการป้องกันเหล่านี้ ซึ่งทำให้ความปลอดภัยลดลง ส่วนประสิทธิภาพขึ้นอยู่กับตัวประมวลผลของคุณและอาจแย่ลง
consequence-auto-updates-disable = คุณจะต้องเปิด Windows Update และติดตั้งการอัปเดตด้วยตนเอง โดยการแจ้งเตือนการอัปเดตจะยังเปิดอยู่
consequence-auto-updates-default = Windows จะติดตั้งการอัปเดตโดยอัตโนมัติ รวมถึงการแก้ไขด้านความปลอดภัย

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = เก็บ Microsoft Defender ไว้ (แนะนำ)
playbook-option-defender-disable = นำ Microsoft Defender ออก
playbook-option-mitigations-default = เก็บการป้องกันเริ่มต้นไว้ (แนะนำ)
playbook-option-mitigations-disable = ปิดการป้องกันตัวประมวลผล
playbook-option-auto-updates-disable = ให้ฉันติดตั้งการอัปเดตเอง
playbook-option-auto-updates-default = ติดตั้งการอัปเดตโดยอัตโนมัติ
playbook-option-disable-hibernation = ปิดไฮเบอร์เนต
playbook-option-disable-power-saving = ปิดการประหยัดพลังงาน
playbook-option-disable-core-isolation = ปิดความปลอดภัยที่ใช้การจำลองเสมือน (VBS)
# Thai Windows localizes Snipping Tool as "เครื่องมือสนิป".
playbook-option-remove-snipping-tool = นำเครื่องมือสนิปออก
playbook-option-uninstall-edge = นำ Microsoft Edge ออก
playbook-option-install-another-browser = ติดตั้งเบราว์เซอร์
playbook-option-install-toolbox = ติดตั้ง Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender คือโปรแกรมป้องกันไวรัสที่มาพร้อม Windows แนะนำให้เก็บไว้ นำออกเฉพาะเมื่อคุณเข้าใจความเสี่ยงและตั้งใจจะใช้แอปป้องกันไวรัสอื่น
playbook-page-mitigations-default-description = การป้องกันเหล่านี้ (หรือที่เรียกว่า security mitigations) ช่วยป้องกันการโจมตีผ่านช่องโหว่ของตัวประมวลผล แนะนำให้ใช้ค่าเริ่มต้นของ Windows
playbook-page-auto-updates-disable-description = การอัปเดต Windows มีการแก้ไขด้านความปลอดภัยรวมอยู่ด้วย คุณจะให้ Windows ติดตั้งโดยอัตโนมัติหรือติดตั้งเองก็ได้
consequence-install-toolbox = เพิ่ม Atlas Toolbox เพื่อช่วยจัดการการตั้งค่า Atlas ของคุณ โดย Toolbox ยังอยู่ในรุ่นเบตา บางฟีเจอร์จึงอาจยังไม่สมบูรณ์
playbook-page-browser-brave-description = เลือกเบราว์เซอร์ที่ต้องการติดตั้ง โดย Atlas จะไม่เปลี่ยนการตั้งค่าเบราว์เซอร์ของคุณ

## Step 3: Windows Security

security-banner-reading-title = กำลังตรวจสอบความปลอดภัยของ Windows
security-banner-reading-message = Atlas กำลังตรวจสอบสวิตช์การป้องกันทั้งสี่รายการด้านล่าง
security-banner-off-title = สวิตช์การป้องกันทั้งสี่รายการปิดอยู่
security-banner-off-message = ตอนนี้คุณตรวจทานตัวเลือกก่อนติดตั้งได้แล้ว
security-banner-readable-off-title = สวิตช์ที่ Atlas อ่านค่าได้นั้นปิดอยู่
security-banner-readable-off-message = ตรวจดูสวิตช์ที่เหลือในแอป ความปลอดภัยของ Windows
security-banner-on-title = ปิดการป้องกันไวรัสชั่วคราว
security-banner-on-message = การป้องกันเหล่านี้อาจขัดขวางการเปลี่ยนแปลงที่ Atlas จำเป็นต้องทำ
# The page name in Windows Security.
security-list-title = การตั้งค่าการป้องกันไวรัสและภัยคุกคาม
security-switch-off = ปิด
security-switch-on = เปิด
security-switch-unreadable = อ่านค่าไม่ได้
security-switch-reading = กำลังตรวจสอบ
security-all-off = ปิดทั้งหมด
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 can't be read". Thai joins the two
# parts with "และ" rather than a comma.
security-count-still-on = ยังเปิดอยู่ { $count } รายการ
security-count-unreadable = อ่านค่าไม่ได้ { $count } รายการ
security-count-join = { $a } และ{ $b }
security-unknown-title = ยืนยันสวิตช์ที่ Atlas ตรวจสอบไม่ได้
security-unknown-message = เมื่อตรวจดูในแอป ความปลอดภัยของ Windows แล้วว่าสวิตช์ทั้งสี่รายการปิดอยู่ ให้ยืนยันด้านล่าง
security-acknowledge = ฉันตรวจดูในแอป ความปลอดภัยของ Windows แล้ว สวิตช์ทั้งสี่รายการปิดอยู่
security-unknown-unelevated-title = Atlas ต้องได้รับสิทธิ์จึงจะตรวจสอบการป้องกันได้
security-unknown-unelevated-message = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบเพื่อให้ Atlas ตรวจสอบการตั้งค่าของ Microsoft Defender ได้
# The four switches, named as Thai Windows Security names them (checked against
# Microsoft's Thai support pages on 6 September 2026; not yet compared with a
# Thai-language Windows installation).
protection-tamper = การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย
protection-tamper-why = ปิดรายการนี้ก่อน เพื่อให้ Defender ยอมให้เปลี่ยนการตั้งค่าการป้องกันได้
protection-realtime = การป้องกันแบบเรียลไทม์
protection-realtime-why = พักการสแกนไฟล์ไว้ก่อน เพื่อไม่ให้ Defender บล็อกไฟล์ติดตั้งของ Atlas
protection-cloud = การป้องกันบนระบบคลาวด์
protection-cloud-why = พักการตรวจสอบภัยคุกคามทางออนไลน์ที่อาจบล็อกไฟล์ติดตั้งของ Atlas
protection-samples = การส่งตัวอย่างโดยอัตโนมัติ
protection-samples-why = หยุดไม่ให้ Defender ส่งไฟล์ของ Atlas ไปให้ Microsoft วิเคราะห์โดยอัตโนมัติ

## Step 4: Install

install-preparing-title = ตรวจสอบครั้งสุดท้ายก่อนติดตั้ง
install-preparing-message = Atlas กำลังตรวจสอบพีซีและการตั้งค่าการป้องกันอีกครั้งก่อนทำการเปลี่ยนแปลง
install-installing = กำลังติดตั้ง
install-running = กำลังทำงาน
# Accessible name of the progress bar.
install-progress = ความคืบหน้าการติดตั้ง
phase-preflight = กำลังตรวจสอบพีซีและเตรียมไฟล์
phase-staging = กำลังเตรียมไฟล์ติดตั้ง
phase-applying = กำลังตั้งค่า Windows อยู่ เปิดพีซีไว้
phase-done = กำลังตั้งค่าขั้นสุดท้าย
outcome-succeeded-title = ติดตั้ง Atlas แล้ว
outcome-lost-title = ยืนยันผลการติดตั้งไม่ได้
outcome-failed-title = การติดตั้งไม่เสร็จสมบูรณ์
outcome-succeeded = รีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
outcome-requirements = พีซีของคุณไม่ตรงตามข้อกำหนดการติดตั้ง ยังไม่มีการเปลี่ยนแปลงใด ๆ กลับไปที่ เตรียมความพร้อม แล้วตรวจสอบอีกครั้ง
outcome-not-elevated = ยังไม่มีการเปลี่ยนแปลงใด ๆ เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบแล้วลองอีกครั้ง
outcome-failed-preflight = การติดตั้งหยุดลงก่อนที่จะเปลี่ยนแปลงสิ่งใด เปิดไฟล์บันทึกเพื่อดูสาเหตุ แล้วลองอีกครั้ง
outcome-failed-staging = การติดตั้งหยุดลงระหว่างเตรียมไฟล์ ก่อนที่จะเปลี่ยนแปลง Windows เปิดไฟล์บันทึกเพื่อดูสาเหตุ แล้วลองอีกครั้ง
outcome-failed-applying = อาจมีการเปลี่ยนแปลงบางอย่างเกิดขึ้นแล้ว หากคุณจะหยุดไว้เพียงเท่านี้ ให้กลับไปเปิดการป้องกันที่ปิดไว้ในแอป ความปลอดภัยของ Windows อีกครั้ง หากการป้องกันเหล่านั้นยังมีอยู่
outcome-not-started = ตัวติดตั้งไม่เริ่มทำงานภายในเวลาที่กำหนด ยังไม่มีการเปลี่ยนแปลงใด ๆ เลือก ลองอีกครั้ง
outcome-lost = ตัวติดตั้งหยุดลงโดยไม่ได้รายงานผล และอาจมีการเปลี่ยนแปลงบางอย่างเกิดขึ้นแล้ว เปิดไฟล์บันทึกเพื่อดูสาเหตุ แล้วเลือก ลองอีกครั้ง เพื่อติดตั้งต่อจากเดิม
restart-now-message = Windows กำลังรีสตาร์ตเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-countdown = Windows จะรีสตาร์ตในอีก { $seconds } วินาที เพื่อให้ Atlas ตั้งค่าให้เสร็จสมบูรณ์
restart-stopped = ยกเลิกการรีสตาร์ตอัตโนมัติแล้ว บันทึกงานของคุณ แล้วรีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-needed = บันทึกงานของคุณ แล้วรีสตาร์ต Windows เพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-dont-now = รีสตาร์ตภายหลัง
restart-now = รีสตาร์ตเดี๋ยวนี้
# Accessible name of the countdown bar.
restart-progress = เวลาที่เหลือก่อนรีสตาร์ต
restart-start-failed = รีสตาร์ต Windows ไม่ได้ บันทึกงานของคุณ แล้วรีสตาร์ตจากเมนูเริ่ม รายละเอียด: { $error }
preflight-title = ยังไม่ได้เริ่มการติดตั้ง
preflight-invalid-options = Atlas ใช้ตัวเลือกการตั้งค่าเหล่านี้ไม่ได้ กลับไปที่ ตัวเลือกของคุณ เพื่อตรวจทาน แล้วลองอีกครั้ง รายละเอียด: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = สถานะของพีซีเปลี่ยนไปหลังการตรวจสอบครั้งก่อน แก้ไขรายการต่อไปนี้ก่อนลองอีกครั้ง { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = ความปลอดภัยของ Windows: { $summary }
preflight-busy = หน้าต่าง Atlas อีกหน้าต่างหนึ่งกำลังเริ่มการติดตั้ง รอสักครู่แล้วลองอีกครั้ง
preflight-record-unreadable = Atlas ตรวจสอบไม่ได้ว่าการติดตั้งครั้งก่อนยังทำงานอยู่หรือไม่ จึงไม่ได้เริ่มการติดตั้งใหม่ ปิดแล้วเปิด Atlas อีกครั้งเพื่อดูคำแนะนำในการกู้คืน รายละเอียด: { $error }
preflight-refused = เริ่มตัวติดตั้งไม่ได้ ยังไม่มีการเปลี่ยนแปลงใด ๆ รายละเอียด: { $error }
go-to-ready = กลับไปที่ เตรียมความพร้อม
go-to-options = กลับไปที่ ตัวเลือกของคุณ
output-problem-title = อ่านความคืบหน้าการติดตั้งไม่ได้
output-problem-message = Atlas อ่านบันทึกไม่ได้ แต่ไม่ได้หมายความว่าการติดตั้งหยุดลง เปิดพีซีไว้ แล้วลองเปิดไฟล์บันทึก รายละเอียด: { $error }
install-elevate-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
install-no-package-title = เลือกไฟล์ติดตั้งก่อน
install-no-package-message = กลับไปที่ เตรียมความพร้อม เพื่อดาวน์โหลด Atlas หรือเปิด playbook (.apbx) ที่บันทึกไว้
install-security-title = ตรวจสอบการป้องกันไวรัสก่อนติดตั้ง
install-security-reading = กำลังตรวจสอบสวิตช์การป้องกันทั้งสี่รายการอีกครั้ง
install-security-message = สวิตช์การป้องกัน{ $summary } เปิดแอป ความปลอดภัยของ Windows แล้วตรวจดูให้แน่ใจว่าสวิตช์ทั้งสี่รายการปิดอยู่ก่อนดำเนินการต่อ
summary-this-install = สรุปการติดตั้ง
summary-try-again = ตรวจทานก่อนลองอีกครั้ง
summary-ready = ตรวจทานการตั้งค่า Atlas ของคุณ
summary-activation = การเปิดใช้งาน
summary-activation-ok = เปิดใช้งานแล้ว Atlas จะไม่เปลี่ยนแปลงสิ่งนี้
summary-activation-missing = ยังไม่ได้เปิดใช้งาน คุณดำเนินการต่อได้ แต่ Atlas จะไม่เปิดใช้งาน Windows ให้
summary-activation-unknown = Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งาน Windows ของคุณ
summary-duration = เวลาโดยประมาณ
summary-duration-value = { $minutes } นาที จากนั้นรีสตาร์ต
summary-restart-checkbox = รีสตาร์ตพีซีของฉันโดยอัตโนมัติหลังติดตั้งเสร็จ
summary-show-command = แสดงคำสั่งติดตั้ง
summary-hide-command = ซ่อนคำสั่งติดตั้ง
summary-command-unavailable = เตรียมคำสั่งติดตั้งไม่ได้ รายละเอียด: { $error }
summary-not-chosen = ยังไม่ได้เลือก
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = เปลี่ยน { $title }
footer-still-checking = กำลังเตรียมการติดตั้ง
footer-fix-items = แก้ไขรายการที่ยังไม่ผ่านด้านบนให้ครบเพื่อดำเนินการต่อ
footer-need-package = ดาวน์โหลด Atlas หรือเปิด playbook เพื่อดำเนินการต่อ
footer-reading-security = กำลังตรวจสอบสวิตช์การป้องกัน
button-checking = กำลังตรวจสอบ
button-installing = กำลังติดตั้ง
button-install = ติดตั้ง Atlas
log-earlier-lines = มีอีก { $count } บรรทัดก่อนหน้านี้อยู่ในไฟล์บันทึก
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (บันทึกฉบับเต็ม: { $path })

## The installing view

installing-checking-title = ตรวจสอบครั้งสุดท้าย
installing-checking-line = Atlas กำลังตรวจสอบพีซีของคุณก่อนทำการเปลี่ยนแปลง อาจใช้เวลาสักครู่
installing-title = กำลังติดตั้ง Atlas
installing-phase-preflight = กำลังตรวจสอบพีซีและเตรียมไฟล์ติดตั้ง
installing-phase-staging = กำลังเตรียมไฟล์ติดตั้งให้พร้อม เปิดพีซีไว้
installing-phase-applying = กำลังตั้งค่า Windows ตามตัวเลือกของคุณ เปิดพีซีไว้และเสียบปลั๊กไว้
installing-phase-done = กำลังติดตั้งขั้นสุดท้าย เปิดพีซีไว้
installing-installed-title = ติดตั้ง Atlas แล้ว
# $time is a formatted clock time.
installing-started-just-now = เริ่มเมื่อ { $time } (ไม่ถึงหนึ่งนาทีที่แล้ว)
installing-started-minutes = เริ่มเมื่อ { $time } ({ $minutes } นาทีที่แล้ว)

## The "Atlas is installed" window after the restart

installed-title-version = ติดตั้ง Atlas { $version } แล้ว
installed-title = ติดตั้ง Atlas แล้ว
installed-ready = เรียบร้อยแล้ว พีซีของคุณพร้อมใช้งานกับ Atlas
installed-open-atlas = ดูการตั้งค่า Atlas ของคุณ

## Settings

settings-title = การตั้งค่า
settings-theme = ธีมของแอป
settings-theme-system = ตาม Windows
settings-theme-light = สว่าง
settings-theme-dark = มืด
settings-theme-contrast-note = Atlas กำลังใช้สีจากธีมความคมชัดของ Windows
settings-theme-mica-note = หากต้องการให้แสดงพื้นหลังโปร่งแสง ให้เลือกธีมสว่างหรือมืดให้ตรงกับ Windows
settings-language = ภาษา
settings-language-system = ตาม Windows
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = เมื่อเลือกตาม Windows: { $language }

# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = รุ่นตัวอย่าง · รอการตรวจทานภาษา
preview-notice = { $language } เป็นคำแปลรุ่นตัวอย่าง
preview-notice-switch = สลับเป็นภาษาอังกฤษ
preview-notice-language = เปลี่ยนภาษา
# $tag is a language tag (text).
settings-language-unavailable = Atlas เวอร์ชันนี้ไม่มี { $tag } จึงแสดงภาษาอังกฤษไปก่อน โดยภาษาที่คุณเลือกยังคงบันทึกไว้
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas ยังไม่รองรับภาษาที่ใช้แสดงผลของ Windows ของคุณ ({ $languages }) จึงแสดงภาษาอังกฤษไปก่อน
settings-language-windows-unavailable = ตรวจสอบภาษาที่ใช้แสดงผลของ Windows ไม่ได้ Atlas จึงใช้ภาษาอังกฤษไปก่อน รายละเอียด: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = ตัวเลข วันที่ และเวลาจะเป็นไปตามรูปแบบภูมิภาคของ Windows ({ $locale })
settings-language-contribute = ช่วยแปล Atlas บน GitHub
settings-installing = การติดตั้ง
settings-restart-label = รีสตาร์ตพีซีของฉันโดยอัตโนมัติหลังติดตั้งเสร็จ
settings-restart-locked = คุณเปลี่ยนการตั้งค่านี้ได้หลังการติดตั้งเสร็จ
settings-restart-description = ต้องรีสตาร์ตเพื่อตั้งค่าให้เสร็จสมบูรณ์ หากเปิดการรีสตาร์ตอัตโนมัติไว้ ให้บันทึกงานของคุณก่อนติดตั้ง
settings-about = เกี่ยวกับ
settings-about-app = Atlas Manager
settings-about-data = ไฟล์ของแอป
settings-about-licence = สัญญาอนุญาต
settings-about-licence-value = GPL-3.0 ซอฟต์แวร์เสรีและโอเพนซอร์ส
settings-view-source = ดูซอร์สโค้ดบน GitHub
settings-open-data-folder = เปิดโฟลเดอร์ของแอป

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = คืนพื้นที่ดิสก์ที่ใช้บันทึกเซสชันของคุณเมื่อไฮเบอร์เนต โดยจะใช้ไฮเบอร์เนตและการเริ่มต้นอย่างรวดเร็วไม่ได้
consequence-disable-power-saving = ปิดฟีเจอร์ประหยัดพลังงาน พีซีของคุณอาจใช้ไฟมากขึ้น ร้อนขึ้น และใช้แบตเตอรี่ได้สั้นลง
consequence-disable-core-isolation = ปิดชั้นความปลอดภัยเพิ่มเติมของ Windows รวมถึงความสมบูรณ์ของหน่วยความจำ ซึ่งจะลดการป้องกันลง และอาจกระทบแอปหรือเกมที่ต้องใช้ฟีเจอร์นี้
consequence-remove-snipping-tool = นำแอปของ Windows สำหรับจับภาพหน้าจอและบันทึกวิดีโอหน้าจอออก
consequence-uninstall-edge = นำเบราว์เซอร์ Microsoft Edge ออก ตรวจดูให้แน่ใจว่าคุณมีเบราว์เซอร์อื่นอยู่ หรือเลือกเบราว์เซอร์ด้านล่าง
consequence-install-another-browser = เลือกเบราว์เซอร์ด้านล่าง แล้ว Atlas จะติดตั้งให้คุณ

# Introduction on the home page before Atlas is installed.
home-intro = Atlas ปรับ Windows เพื่อลดการทำงานเบื้องหลังและสิ่งรบกวน เราจะแนะนำคุณผ่านขั้นตอนการตรวจสอบและตัวเลือกต่าง ๆ ก่อนทำการเปลี่ยนแปลง

detail-build-missing = playbook นี้ไม่ได้ระบุบิลด์ Windows ที่รองรับ เลือก playbook แบบบิลด์เต็มแทนแพ็กเกจ LocalTest
## ISO creation (Beta)
iso-home-title = สื่อการติดตั้ง Windows
iso-home-description = สร้าง ISO ของ Windows ที่มี Atlas สำหรับติดตั้งใหม่บนพีซีเครื่องนี้หรือเครื่องอื่น
iso-open = สร้าง ISO พร้อม Atlas
iso-title = สร้าง ISO พร้อม Atlas
iso-beta = เบต้า
iso-beta-description = ทดสอบ ISO ในเครื่องเสมือนก่อนนำไปใช้บนพีซี และสำรองไฟล์ก่อนติดตั้ง Windows
iso-admin-description = ต้องใช้สิทธิ์ผู้ดูแลระบบเพื่ออ่านอิมเมจ Windows และสร้างสื่อการติดตั้ง
iso-files-description = เลือก ISO ของ Windows 11 x64 ที่ไม่ได้ดัดแปลง, Playbook ของ Atlas (.apbx) และชื่อไฟล์ใหม่สำหรับผลลัพธ์
iso-source = ISO ของ Windows
iso-package = Playbook ของ Atlas (0.6+)
iso-output = บันทึก ISO ใหม่ที่
iso-no-file = ยังไม่ได้เลือกไฟล์
iso-browse = เรียกดู
iso-save-as = บันทึกเป็น
iso-inspect = ตรวจสอบไฟล์
iso-mode-title = การตั้งค่า Windows และ Atlas
iso-mode-interactive = เลือกการตั้งค่า Atlas หลังเข้าสู่ระบบ
iso-mode-interactive-description = หลังเข้าสู่ระบบ แอป Atlas จะช่วยคุณอัปเดต Windows และแอปจาก Store เลือกการตั้งค่า และปรับใช้ Atlas
iso-mode-before = เลือกการตั้งค่า Atlas ตอนนี้
iso-mode-before-description = บันทึกการตั้งค่า Atlas ลงใน ISO หลังเข้าสู่ระบบ ให้อัปเดต Windows และแอปจาก Store แล้วปรับใช้ Atlas ด้วยการตั้งค่าเหล่านี้
iso-package-unsupported-title = เลือก Playbook รุ่นใหม่กว่า
iso-package-unsupported = การตั้งค่า ISO ต้องใช้ Atlas 0.6 ขึ้นไปที่รองรับ ISO โปรดเลือกเพลย์บุ๊กที่เข้ากันได้
iso-atlas-options = การตั้งค่า Atlas
iso-review = ตรวจทาน ISO
iso-review-description = Atlas จะสร้าง ISO ใหม่และเก็บต้นฉบับไว้ หากต้องการติดตั้ง Windows ให้บูตจาก ISO ใหม่ การสร้าง ISO จะไม่ติดตั้ง Atlas บนพีซีเครื่องนี้
iso-review-files = ไฟล์
iso-review-package = Playbook ของ Atlas
iso-review-output = ISO ใหม่
iso-review-editions = รุ่น
iso-review-size = ขนาด
iso-review-size-value = { $size } MB
iso-review-account = ชื่อบัญชี
iso-review-target = ติดตั้งบน
iso-review-drivers = ไดรเวอร์
iso-create = สร้าง ISO
iso-stage-inspect = กำลังตรวจสอบอิมเมจ Windows
iso-stage-copy = กำลังคัดลอกไฟล์ Windows
iso-stage-inject = กำลังเพิ่ม Atlas
iso-stage-master = กำลังสร้าง ISO
iso-stage-verify = กำลังตรวจสอบผลลัพธ์
iso-stage-cleanup = กำลังดำเนินการขั้นสุดท้าย
iso-progress-description = เปิดแอปค้างไว้ การประมวลผลอิมเมจขนาดใหญ่อาจใช้เวลาสักครู่
iso-cancel = ยกเลิกการสร้าง
iso-cancelling = กำลังรอจุดที่ยกเลิกได้อย่างปลอดภัย
iso-cancelled = ยกเลิกการสร้าง ISO แล้ว
iso-cancelled-description = ISO ต้นฉบับยังอยู่ บันทึกการวินิจฉัยจะระบุหากมีไฟล์ชั่วคราวที่ยังต้องลบ
iso-complete = ISO พร้อมใช้งานแล้ว
iso-complete-description = ทดสอบในเครื่องเสมือนก่อน แล้วจึงนำไปสร้างสื่อการติดตั้ง Windows
iso-open-folder = แสดงในโฟลเดอร์
iso-failed = สร้าง ISO ไม่สำเร็จ
iso-failed-description = เปิดการวินิจฉัยเพื่อดูสาเหตุ แก้ไขปัญหาแล้วลองอีกครั้งโดยใช้ชื่อไฟล์ผลลัพธ์ใหม่
iso-diagnostics = เปิดการวินิจฉัย
iso-close-title = ยังสร้าง ISO อยู่
iso-close-message = เปิดหน้าต่างนี้ไว้จนกว่าการสร้างหรือการยกเลิกจะเสร็จ การยกเลิกจะรอจนกว่าขั้นตอนปัจจุบันจะหยุดได้อย่างปลอดภัย
iso-keep-open = เปิดไว้
prepare-title = อัปเดต Windows และแอปจาก Store
prepare-description = ก่อนปรับใช้ Atlas ให้ติดตั้งการอัปเดต Windows รวมถึงอัปเดต Microsoft Store และแอปจาก Store ทั้งหมดที่ติดตั้งไว้ แอปจาก Store อาจปิดระหว่างการอัปเดต
prepare-complete = Windows และแอปจาก Store เป็นเวอร์ชันล่าสุดแล้ว
prepare-reboot = Windows ต้องรีสตาร์ต ตัวเลือก Atlas ของคุณจะถูกบันทึกไว้ เมื่อเข้าสู่ระบบแล้ว ให้ตรวจหาการอัปเดตอีกครั้ง
prepare-failed = การอัปเดตบางรายการไม่สำเร็จ ตรวจสอบบันทึกการวินิจฉัย แก้ไขข้อผิดพลาดของ Windows หรือ Store แล้วลองอีกครั้ง
prepare-cancelled = หยุดการเตรียมพร้อมแล้ว ตรวจหาการอัปเดตอีกครั้งก่อนดำเนินการต่อ
prepare-windows-search = กำลังตรวจหาการอัปเดต Windows…
prepare-windows-download = กำลังดาวน์โหลดการอัปเดต Windows…
prepare-windows-install = กำลังติดตั้งการอัปเดต Windows…
prepare-store-search = กำลังตรวจสอบ Microsoft Store…
prepare-store-install = กำลังอัปเดต Microsoft Store และแอป…
prepare-stop-description = ระบบจะหยุดหลังจากการอัปเดตที่กำลังดำเนินอยู่เสร็จสิ้น โปรดเปิด Atlas ไว้จนกว่าจะหยุด
prepare-stop = หยุดหลังจากขั้นตอนนี้
prepare-restart = รีสตาร์ตและดำเนินการต่อ
prepare-start = ตรวจหาและติดตั้งการอัปเดต
iso-username = ชื่อบัญชีภายในเครื่อง
iso-account-description = Windows จะให้คุณตั้งรหัสผ่านหลังจากติดตั้งใหม่
iso-username-placeholder = ชื่อของคุณ
iso-account-invalid = ใช้ 1–20 อักขระ โดยไม่มีช่องว่างด้านหน้าหรือท้าย และไม่มีสัญลักษณ์ที่ Windows ไม่อนุญาตในชื่อบัญชี
iso-privacy-defaults = การตั้งค่า Windows จะปิดการแชร์ข้อมูลเพิ่มเติมและข้อเสนอเฉพาะบุคคลโดยอัตโนมัติ
prepare-drivers = ต้องการติดตั้งไดรเวอร์อย่างไร?
prepare-drivers-auto = รับไดรเวอร์ผ่าน Windows Update
prepare-drivers-auto-detail = Windows จะค้นหาไดรเวอร์สำหรับฮาร์ดแวร์ของคุณ แนะนำสำหรับพีซีส่วนใหญ่
prepare-drivers-manual = ติดตั้งไดรเวอร์เอง
prepare-drivers-manual-detail = บล็อกการดาวน์โหลดไดรเวอร์จาก Windows Update คุณต้องหาไดรเวอร์เอง โดยไดรเวอร์ที่ติดตั้งไว้แล้วจะยังคงอยู่
prepare-network-needed = เชื่อมต่อ Wi-Fi หรือ Ethernet ที่ไม่ได้ตั้งเป็นการเชื่อมต่อแบบคิดค่าบริการตามปริมาณข้อมูล แล้วลองอีกครั้ง หากไม่มี Wi-Fi ให้ติดตั้งไดรเวอร์เครือข่ายก่อน
prepare-network-settings = เปิดการตั้งค่าเครือข่าย
iso-target-title = ต้องการติดตั้ง Windows ใหม่บนพีซีเครื่องใด?
iso-target-this = พีซีเครื่องนี้
iso-target-other = พีซีเครื่องอื่น
iso-copy-network = รวมไดรเวอร์เครือข่ายของพีซีเครื่องนี้
iso-network-detail = นำไดรเวอร์ Wi-Fi และ Ethernet ของพีซีเครื่องนี้ไปใช้ระหว่างติดตั้ง Windows หลังติดตั้งใหม่ คุณต้องเชื่อมต่อ Wi-Fi อีกครั้ง
iso-network-source = แหล่งที่มาของไดรเวอร์เครือข่าย
iso-network-installed = ใช้ไดรเวอร์ที่ติดตั้งไว้
iso-network-updated = ตรวจสอบ Windows Update ก่อน
iso-network-updated-detail = ดาวน์โหลดไดรเวอร์ที่ตรงกับฮาร์ดแวร์จาก Windows Update และเก็บไดรเวอร์ที่ติดตั้งไว้เป็นสำรอง ต้องใช้การเชื่อมต่อที่ไม่คิดค่าบริการตามปริมาณข้อมูล
iso-stage-network-drivers = กำลังเตรียมไดรเวอร์เครือข่าย…
iso-network-failed = เตรียมไดรเวอร์เครือข่ายไม่ได้ โปรดตรวจสอบข้อมูลวินิจฉัย หรือย้อนกลับไปเปลี่ยนตัวเลือกไดรเวอร์เครือข่าย
iso-mode-desktop = ตั้งค่าให้เสร็จก่อนเข้าสู่เดสก์ท็อป
iso-mode-desktop-description = เลือกการตั้งค่า Atlas ตอนนี้ หลังเข้าสู่ระบบ ให้อัปเดตและตั้งค่า Atlas ให้เสร็จก่อนเปิดเดสก์ท็อป Windows
desktop-setup-description = ตั้งค่าพีซีให้เสร็จ ตัวเลือก Atlas ของคุณบันทึกไว้แล้ว หากจำเป็น คุณสามารถกลับไปที่ Windows ได้
desktop-setup-exit = ดำเนินการต่อใน Windows

# Windows installation USB (Beta)
usb-title = สร้าง USB ติดตั้ง Windows
usb-existing = สร้าง USB จาก ISO ที่มีอยู่
usb-description = สร้าง USB ที่บูตได้สำหรับ Windows 11 25H2 เพื่อใช้ติดตั้ง Windows และ Atlas บนพีซีของคุณ
usb-choose-iso = เลือก ISO
usb-drive = ไดรฟ์ USB
usb-empty = เชื่อมต่อไดรฟ์ USB แล้วรีเฟรชรายการ ระบบจะแสดงเฉพาะไดรฟ์ USB ที่เขียนข้อมูลได้และไม่มี Windows ที่กำลังใช้งานอยู่
usb-refresh = รีเฟรช
usb-drive-detail = { $size } GB · { $volumes } · หมายเลขซีเรียล: { $serial }
usb-review = ตรวจสอบ USB
usb-erase-title = ล้างข้อมูลในไดรฟ์ USB นี้หรือไม่?
usb-erase-description = ไฟล์และพาร์ทิชันทั้งหมดบน { $drive } ({ $size } GB) จะถูกลบอย่างถาวร โดยไฟล์ ISO ของคุณจะยังอยู่
usb-layout = การติดตั้ง Windows ใช้พื้นที่สูงสุด 32 GB พื้นที่ที่เหลือจะยังไม่ถูกจัดสรร USB นี้ใช้กับพีซีที่บูตผ่าน UEFI
usb-ack = ฉันเข้าใจว่าข้อมูลทั้งหมดในไดรฟ์ USB นี้จะถูกลบ
usb-write = ล้างข้อมูลและสร้าง USB
usb-stage-prepare = กำลังเตรียมไฟล์ติดตั้ง…
usb-stage-format = กำลังฟอร์แมต USB…
usb-stage-copy = กำลังคัดลอกไฟล์ติดตั้ง…
usb-stage-verify = กำลังตรวจสอบ USB…
usb-working = เปิด Atlas ไว้และอย่าถอด USB การยกเลิกจะรอให้ขั้นตอนปัจจุบันหยุดอย่างปลอดภัย USB ที่ยังสร้างไม่เสร็จจะใช้ติดตั้ง Windows ไม่ได้
usb-failed = สร้าง USB ไม่สำเร็จ ตรวจสอบการเชื่อมต่อและเปิดการวินิจฉัยเพื่อดูรายละเอียด จากนั้นเลือกไดรฟ์อีกครั้งเพื่อลองใหม่
usb-cancelled = หยุดสร้าง USB แล้ว ไดรฟ์อาจมีไฟล์ติดตั้งที่ไม่สมบูรณ์ โปรดสร้างใหม่ก่อนนำไปติดตั้ง Windows
usb-complete = USB พร้อมใช้งานและตรวจสอบไฟล์ทั้งหมดแล้ว ให้นำ USB ออกอย่างปลอดภัย เชื่อมต่อกับพีซีที่จะติดตั้ง Windows ใหม่ แล้วเลือก USB ในเมนูบูต UEFI ของพีซีเครื่องนั้น
usb-eject = นำ USB ออก
usb-ejected = ถอด USB ได้อย่างปลอดภัยแล้ว เมื่อต้องการติดตั้ง Windows ให้เลือก USB ในเมนูบูต UEFI ของพีซี
usb-eject-failed = Windows ไม่สามารถนำ USB ออกได้ ปิดไฟล์หรือหน้าต่างที่กำลังใช้ไดรฟ์นี้ แล้วลองอีกครั้ง
ready-fresh-title = เริ่มจากการติดตั้ง Windows ใหม่ทั้งหมด
ready-fresh-description = Atlas ต้องใช้ Windows ที่ติดตั้งใหม่ทั้งหมด ยกเว้นการอัปเกรด Atlas ที่รองรับ การติดตั้ง Atlas 0.6 ใหม่ต้องใช้ Windows 11 25H2 โปรดสำรองไฟล์ก่อนติดตั้ง Windows ใหม่
detail-edition-unsupported = ใช้ Windows 11 Pro, Pro for Workstations หรือ Enterprise ไม่รองรับรุ่น Home, LTSC และ Server หากระบุรุ่น Windows ไม่ได้ โปรดแก้ไขปัญหานี้ก่อนดำเนินการต่อ
install-source-title = ไม่สามารถติดตั้งได้
install-source-unsupported = ไม่สามารถอัปเดต Atlas { $source } เป็น { $target } ได้โดยตรง โปรดติดตั้ง Windows ใหม่เพื่อใช้เวอร์ชันนี้
install-source-unknown = Atlas ไม่สามารถตรวจสอบสถานะการติดตั้งได้ โปรดแก้ไขการติดตั้งที่ยังไม่เสร็จและตรวจสอบข้อมูลการวินิจฉัยก่อนลองอีกครั้ง
iso-edition-selection = มีเฉพาะรุ่นที่รองรับเท่านั้น ระหว่างติดตั้ง Windows ให้เลือกรุ่นที่คุณมีสิทธิ์การใช้งาน Windows
detail-windows-preview = ไม่รองรับรุ่น Insider โปรดใช้ Windows 11 รุ่นที่เผยแพร่ทั่วไป
detail-windows-release-unknown = Atlas ยืนยันไม่ได้ว่า Windows รุ่นนี้เป็นรุ่นที่เผยแพร่ทั่วไป โปรดเชื่อมต่ออินเทอร์เน็ตแล้วตรวจสอบอีกครั้ง
iso-release-unknown = ยืนยันไม่ได้ว่า ISO นี้มี Windows 11 25H2 รุ่นที่เผยแพร่ทั่วไป โปรดเชื่อมต่ออินเทอร์เน็ตแล้วลองอีกครั้ง หรือเลือกสื่อการติดตั้งอย่างเป็นทางการ
prepare-previous-worker = การอัปเดตก่อนหน้านี้ยังทำงานอยู่ Atlas จะรอให้เสร็จสิ้นก่อนที่คุณจะลองอีกครั้งได้

ready-used-windows-title = ติดตั้ง Windows ใหม่ก่อนดำเนินการต่อ
ready-used-windows-description = Windows นี้มีสัญญาณว่าเคยใช้งานมาแล้ว การติดตั้ง Atlas บนระบบนี้ไม่ได้รับการสนับสนุนและไม่แนะนำอย่างยิ่ง ดำเนินการต่อเฉพาะเมื่อคุณเข้าใจความเสี่ยงเท่านั้น
ready-used-windows-dismiss = ฉันเข้าใจความเสี่ยง
playbook-option-install-eclean = ติดตั้ง eclean
consequence-install-eclean = เครื่องมือบำรุงรักษาจากทีมผู้สร้าง AtlasOS เพื่อดูแล PC ให้เป็นระเบียบหลังตั้งค่า ตรวจสอบไฟล์ขยะและแอปเริ่มต้นระบบ ต้องมีบัญชีและการเชื่อมต่ออินเทอร์เน็ต

prepare-resumed = Windows เริ่มระบบใหม่แล้ว คืนค่าตัวเลือก Atlas ของคุณแล้ว ดำเนินการอัปเดตต่อก่อนติดตั้ง Atlas
prepare-continue = อัปเดตต่อ
prepare-saving-restart = กำลังบันทึกตัวเลือกและตั้งค่าให้ Atlas เปิดอีกครั้งหลังจาก Windows เริ่มระบบใหม่…
prepare-restart-save-failed = บันทึกตัวเลือกไม่ได้ โปรดลองอีกครั้งก่อนเริ่มระบบใหม่
prepare-restart-registration-failed = บันทึกตัวเลือกแล้ว แต่ตั้งค่าให้เปิดอีกครั้งโดยอัตโนมัติไม่ได้ โปรดลองอีกครั้ง หรือเริ่ม Windows ใหม่แล้วเปิด Atlas ด้วยตนเอง
prepare-restart-failed = Windows เริ่มระบบใหม่ไม่ได้ โปรดลองอีกครั้งหรือเริ่มระบบใหม่ผ่าน Windows บันทึกตัวเลือกแล้วและตั้งค่าให้ Atlas เปิดอีกครั้งแล้ว
diagnostics-export = ส่งออกข้อมูลวินิจฉัย
diagnostics-exporting = กำลังรวบรวมข้อมูลวินิจฉัย…
diagnostics-show = แสดงไฟล์ ZIP วินิจฉัย
diagnostics-privacy = บันทึกมีชื่อบัญชี เส้นทางไฟล์ และรายละเอียดอุปกรณ์ ตรวจสอบ ZIP แล้วส่งให้ฝ่ายสนับสนุน Atlas เป็นการส่วนตัว ไม่มีการอัปโหลดอัตโนมัติ
diagnostics-error = ส่งออกข้อมูลวินิจฉัยไม่ได้: { $error }
