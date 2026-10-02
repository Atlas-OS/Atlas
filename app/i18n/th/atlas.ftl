### Atlas Manager: ไทย (Thai) — preview translation, revised on 1 October 2026 from the en-GB source.
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
### - "Atlas", "AtlasOS", "Windows", "Defender", "SmartScreen", "GitHub" are
###   product names. The Atlas package (.apbx) is "แพ็กเกจ Atlas", or
###   "แพ็กเกจ" once it is clear.
###   Windows features use the names Thai Windows shows: the app is
###   "ความปลอดภัยของ Windows" (written "แอป ความปลอดภัยของ Windows" when it is
###   the object of "open"), and the four switches are named on the
###   "การตั้งค่าการป้องกันไวรัสและภัยคุกคาม" page.
### - Thai punctuation: no full stop at the end of a sentence; separate
###   sentences and clauses with a space; put a space on both sides of Latin
###   words and numbers. Buttons are short and verb-first.
### - When text names a button, card or step, write its exact label with a
###   space on each side: "เลือก ลองอีกครั้ง", "ในการ์ด การตรวจสอบพีซี".
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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
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
list-and = { $a } และ{ $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }, { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = ปิดหน้าต่างขณะที่ Atlas กำลังติดตั้งหรือไม่
window-close-message = การติดตั้งจะดำเนินต่อไปในเบื้องหลัง เปิด Atlas อีกครั้งเพื่อดูความคืบหน้าและผลลัพธ์ และเปิดพีซีไว้จนกว่าจะเสร็จ
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = การติดตั้งจะดำเนินต่อไปในเบื้องหลัง แต่พีซีของคุณจะไม่รีสตาร์ตโดยอัตโนมัติขณะที่ Atlas ปิดอยู่ เปิด Atlas อีกครั้งเพื่อดูความคืบหน้าและผลลัพธ์ และเปิดพีซีไว้จนกว่าจะเสร็จ
window-close-keep = เปิดหน้าต่างไว้
window-close-close = ปิดหน้าต่าง
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = ปิดหน้าต่างก่อนเริ่มการติดตั้งหรือไม่
window-close-preparing-message = Atlas ยังตรวจสอบพีซีของคุณอยู่และยังไม่ได้เริ่มติดตั้ง หากปิดตอนนี้ การติดตั้งจะไม่เริ่มขึ้น เปิด Atlas อีกครั้งเพื่อดำเนินการต่อ
prepare-close-title = การอัปเดตยังทำงานอยู่
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = เปิด Atlas ไว้ขณะที่การอัปเดตทำงานอยู่ หากคุณเลือก หยุดอัปเดต การอัปเดตจะหยุดหลังจากขั้นตอนปัจจุบัน แล้วคุณจึงปิด Atlas ได้
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = ปิด Atlas โดยไม่รีสตาร์ตหรือไม่
# "Restart now" is restart-now, one of this dialog's three buttons.
window-close-restart-message = พีซีของคุณต้องรีสตาร์ตเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์ หากปิด Atlas ตอนนี้ Atlas จะไม่รีสตาร์ตพีซีให้ คุณจึงต้องรีสตาร์ตเองเมื่อพร้อม บันทึกงานของคุณก่อนเลือก รีสตาร์ตเดี๋ยวนี้
window-close-restart-close = ปิดโดยไม่รีสตาร์ต
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = ปิด Atlas ขณะที่การป้องกันยังปิดอยู่หรือไม่
window-close-protection-message = การป้องกันบางรายการในแอป ความปลอดภัยของ Windows ยังปิดอยู่: { $switches } หากคุณจะไม่ติดตั้ง Atlas ต่อให้เสร็จ ให้เปิดการป้องกันเหล่านี้อีกครั้งก่อนปิด หากจะติดตั้งต่อ Atlas จะตั้งค่าต่อจากเดิมเมื่อคุณเปิด Atlas อีกครั้ง
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = เปิดแพ็กเกจ Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = ติดตั้ง Atlas แล้ว กำลังรีสตาร์ต Windows เพื่อตั้งค่าให้เสร็จสมบูรณ์
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas กำลังรีสตาร์ต Windows เพื่อติดตั้งการอัปเดตให้เสร็จสมบูรณ์

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (บิลด์ { $build })

## Home page

home-not-installed = ยินดีต้อนรับสู่ Atlas
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas บนพีซีเครื่องนี้
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = ติดตั้งเมื่อ { $date }
home-status-checking = กำลังตรวจหาการอัปเดต
# While startup checks whether another window's installation is running.
home-status-recovering = กำลังตรวจหาการติดตั้งที่ดำเนินการอยู่
home-status-offline = ตรวจหาการอัปเดตไม่ได้
home-status-not-checked = ยังไม่ได้ตรวจหาการอัปเดต
home-status-update = มี Atlas { $version } ให้อัปเดต
home-status-up-to-date = เป็นเวอร์ชันล่าสุดแล้ว
home-status-newest = เวอร์ชันล่าสุด: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = การติดตั้ง Atlas { $version } ยังไม่เสร็จ
home-check-again = ตรวจสอบอีกครั้ง
# Primary button while an install is running or waiting.
home-show-install = ดูความคืบหน้า
home-continue-installing = ตั้งค่าต่อ
home-update-to = อัปเดตเป็น Atlas { $version }
home-reinstall = ติดตั้ง Atlas ใหม่
home-install = ติดตั้ง Atlas
home-finish-install = ติดตั้ง Atlas { $version } ให้เสร็จ
home-start-over = เริ่มใหม่ตั้งแต่ต้น
home-restart-title = พีซีของคุณต้องรีสตาร์ต
home-security-reminder-title = เปิดการป้องกันของคุณอีกครั้ง
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = ตรวจดูให้แน่ใจว่าการป้องกันของคุณเปิดอยู่
home-security-reminder-message = ขณะนี้ Atlas ไม่ได้ติดตั้งสิ่งใดอยู่ แต่การป้องกันบางรายการในแอป ความปลอดภัยของ Windows ยังปิดอยู่ เปิดแอป ความปลอดภัยของ Windows แล้วตรวจดูให้แน่ใจว่ารายการต่อไปนี้เปิดอยู่: { $switches }
home-security-reminder-unreadable-message = Atlas อ่านค่าสวิตช์การป้องกันได้ไม่ครบ ตรวจดูในแอป ความปลอดภัยของ Windows ว่ารายการต่อไปนี้เปิดอยู่: { $switches }
home-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
home-state-error-title = อ่านรายละเอียดการติดตั้ง Atlas ของคุณไม่ได้
home-state-error-message = เวอร์ชัน Atlas ตัวเลือก และประวัติการติดตั้งของคุณอาจแสดงไม่ถูกต้อง เลือก ตรวจสอบอีกครั้ง เพื่อลองใหม่ รายละเอียด: { $error }
home-whats-new = มีอะไรใหม่ใน Atlas { $version }
home-view-release = ดูบันทึกประจำรุ่นบน GitHub
home-released = เผยแพร่เมื่อ { $date }
home-show-less = แสดงน้อยลง
home-show-full-notes = แสดงบันทึกประจำรุ่นทั้งหมด
home-your-install = การตั้งค่า Atlas ของคุณ
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = พีซีเครื่องนี้ไม่มีบันทึกว่าติดตั้ง Atlas ไว้อย่างไร จึงแสดงตัวเลือกและประวัติการติดตั้งของคุณไม่ได้
# Row label: how Atlas was set up.
home-set-up = วิธีการตั้งค่า
home-set-up-during-oobe = ระหว่างการตั้งค่า Windows
home-history = ประวัติการติดตั้ง
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = เตรียมพีซีของคุณให้พร้อมสำหรับ Atlas
home-step-1-detail = Atlas จะตรวจสอบพีซีของคุณ ติดตั้งการอัปเดต Windows และ Microsoft Store ที่ค้างอยู่ แล้วดาวน์โหลดไฟล์ติดตั้ง แอปจาก Store อาจปิดลง และพีซีของคุณอาจต้องรีสตาร์ต จึงควรบันทึกงานของคุณก่อน
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas จะตรวจสอบพีซีของคุณ ติดตั้งการอัปเดต Windows และ Microsoft Store ที่ค้างอยู่ แล้วเตรียมไฟล์ติดตั้งที่มาพร้อมกัน แอปจาก Store อาจปิดลง และพีซีของคุณอาจต้องรีสตาร์ต จึงควรบันทึกงานของคุณก่อน
home-step-2-detail = เลือกว่าจะเก็บ Microsoft Defender และการป้องกันตัวประมวลผลไว้หรือไม่ ให้ติดตั้งการอัปเดต Windows อย่างไร และเลือกรายการเพิ่มเติมตามต้องการ
home-step-3-detail = ปิดสวิตช์การป้องกันสี่รายการในแอป ความปลอดภัยของ Windows เพื่อไม่ให้ขัดขวางการติดตั้ง โดย Atlas จะแสดงวิธีให้คุณดู
home-step-4-detail = การติดตั้งใช้เวลาประมาณ { $minutes } นาที จากนั้นพีซีของคุณต้องรีสตาร์ต
# Accessible name of a numbered step.
home-step-a11y = ขั้นตอนที่ { $number }: { $title }
home-github = ดู Atlas บน GitHub
home-discord = เข้าร่วมชุมชน Atlas บน Discord
home-report-problem = รายงานปัญหา

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
# $error is a raw error message (text).
notice-settings-not-saved = Atlas บันทึกการเปลี่ยนแปลงล่าสุดของคุณไม่ได้ การเปลี่ยนแปลงเหล่านั้นจึงอาจหายไปเมื่อปิด Atlas หากมีหน้าต่าง Atlas อื่นเปิดอยู่ ให้ปิดหน้าต่างนั้น แล้วทำการเปลี่ยนแปลงอีกครั้ง รายละเอียด: { $error }
notice-session-unreadable-title = ตรวจสอบการติดตั้งครั้งก่อนไม่ได้
# $path is a file path (text).
notice-session-unreadable-message = Atlas ตรวจสอบไม่ได้ว่าการติดตั้งครั้งก่อนยังทำงานอยู่หรือไม่ หากไม่แน่ใจ ให้ขอความช่วยเหลือจากชุมชน Atlas ก่อน คุณลบ { $path } แล้วลองอีกครั้งได้ก็ต่อเมื่อแน่ใจว่าไม่มีการติดตั้งใดทำงานอยู่ รายละเอียด: { $error }

## Administrator elevation

elevation-declined = ไม่ได้รับสิทธิ์ ลองอีกครั้ง แล้วเลือก ใช่ เมื่อ Windows ถามว่าจะอนุญาตให้ Atlas ทำการเปลี่ยนแปลงหรือไม่
elevation-declined-continue = ไม่ได้รับสิทธิ์ ลองอีกครั้ง แล้วเลือก ใช่ เมื่อ Windows ถามว่าจะอนุญาตให้ Atlas ทำการเปลี่ยนแปลงหรือไม่ ตัวเลือกการตั้งค่าของคุณบันทึกไว้แล้ว
elevation-draft-not-saved = Atlas บันทึกตัวเลือกการตั้งค่าของคุณไม่ได้ จึงยังไม่ได้เปิด Atlas ใหม่ ลองอีกครั้ง รายละเอียด: { $error }
# Shown with the home-start-over button.
elevation-taken-over = หน้าต่าง Atlas อีกหน้าต่างหนึ่งกำลังดำเนินการตั้งค่านี้อยู่ จึงยังไม่ได้เปิด Atlas ใหม่ ดำเนินการต่อในหน้าต่างนั้น หรือเลือก เริ่มใหม่ตั้งแต่ต้น เพื่อตั้งค่าใหม่ในหน้าต่างนี้

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
stepper-status-attention = ต้องดำเนินการ
# Heading above each step's content.
step-heading = ขั้นตอนที่ { $number } จาก { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }, { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }, { $progress }

## Step 1: Get ready

ready-banner-busy-title = กำลังเตรียมพีซีของคุณ
ready-banner-busy-message = Atlas กำลังตรวจสอบพีซีของคุณและเตรียมไฟล์ติดตั้ง
ready-banner-blocked-title = พีซีของคุณยังไม่พร้อม
ready-banner-blocked-message = แก้ไขรายการที่ทำเครื่องหมายไว้ในการ์ด การตรวจสอบพีซี แล้วเลือก ตรวจสอบอีกครั้ง
ready-banner-no-package-title = ดาวน์โหลด Atlas เพื่อดำเนินการต่อ
ready-banner-no-package-message = ดาวน์โหลด Atlas ในการ์ด ไฟล์ติดตั้ง หรือเลือก เปิดไฟล์แพ็กเกจ หากคุณมีแพ็กเกจ Atlas (.apbx) อยู่แล้ว
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = เตรียมแพ็กเกจ Atlas ที่มาพร้อมกันเพื่อดำเนินการต่อ
ready-banner-no-package-bundled-message = แพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้ยังไม่พร้อม ตรวจดูการ์ด ไฟล์ติดตั้ง
ready-banner-updates-title = อัปเดต Windows และแอปจาก Store เพื่อดำเนินการต่อ
ready-banner-updates-message = เลือก ตรวจหาและติดตั้งการอัปเดต เมื่ออัปเดตเสร็จแล้ว Atlas จะตรวจสอบพีซีของคุณอีกครั้ง
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = กำลังอัปเดต Windows และแอปจาก Store
ready-banner-updating-message = ขั้นตอนนี้อาจใช้เวลาสักพัก เปิด Atlas ไว้ คุณติดตามความคืบหน้าได้ในการ์ด อัปเดต Windows และแอปจาก Store
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = หยุดการอัปเดตแล้ว
ready-banner-updates-stopped-message = เลือก ตรวจหาและติดตั้งการอัปเดต ในการ์ด อัปเดต Windows และแอปจาก Store เพื่ออัปเดตให้เสร็จ
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = พีซีของคุณรีสตาร์ตแล้ว
ready-banner-updates-resumed-message = เลือก อัปเดตต่อ ในการ์ด อัปเดต Windows และแอปจาก Store เพื่ออัปเดตให้เสร็จ
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = ดูสิ่งที่ต้องทำในการ์ด อัปเดต Windows และแอปจาก Store แล้วเลือก ลองอีกครั้ง
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = บันทึกงานของคุณก่อน แล้วเลือก รีสตาร์ตและดำเนินการต่อ ในการ์ด อัปเดต Windows และแอปจาก Store
ready-banner-warnings-title = มีบางอย่างที่ควรตรวจดู
ready-banner-warnings-message = คุณดำเนินการต่อได้ แต่ควรอ่านรายการที่ทำเครื่องหมายไว้ในการ์ด การตรวจสอบพีซี ก่อน
ready-banner-ok-title = พร้อมกำหนดตัวเลือกของคุณแล้ว
ready-banner-ok-message = ผ่านการตรวจสอบทุกรายการ และไฟล์ติดตั้งพร้อมแล้ว

# Card title and accessible name of the list of checks.
ready-this-pc = การตรวจสอบพีซี
ready-check-again = ตรวจสอบอีกครั้ง
ready-checks-passed = ผ่านการตรวจสอบ { $count } รายการ
package-title = ไฟล์ติดตั้ง
# $received and $total are formatted numbers of megabytes (text).
package-downloading = กำลังดาวน์โหลด Atlas { $version } · { $received } จาก { $total } MB
package-unpacking-progress = กำลังแตกไฟล์ · { $done } จาก { $total } ไฟล์
package-unpacking = กำลังแตกไฟล์
package-looking = กำลังตรวจหา Atlas เวอร์ชันล่าสุด
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = กำลังเตรียมแพ็กเกจ Atlas ที่มาพร้อมกัน
package-none = ดาวน์โหลด Atlas เพื่อรับไฟล์ติดตั้ง หากคุณมีแพ็กเกจ Atlas (.apbx) อยู่แล้ว ให้เปิดแพ็กเกจนั้นแทน
# The GitHub release check failed. "Download latest version" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas ตรวจหาเวอร์ชันล่าสุดไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วเลือก ดาวน์โหลดเวอร์ชันล่าสุด หรือเปิดแพ็กเกจ Atlas (.apbx) ที่บันทึกไว้
# Short status words beside the card title.
package-status-downloading = กำลังดาวน์โหลด
package-status-unpacking = กำลังแตกไฟล์
package-status-failed = เตรียมไฟล์ไม่ได้
package-status-ready = พร้อม
package-status-checking = กำลังตรวจสอบ
package-status-preparing = กำลังเตรียม
package-status-missing = ยังไม่ได้ดาวน์โหลด
# Accessible name of the progress bar.
package-progress = ความคืบหน้าของไฟล์ติดตั้ง
package-download-again = ดาวน์โหลดอีกครั้ง
package-download-version = ดาวน์โหลด Atlas { $version }
package-download-newest = ดาวน์โหลดเวอร์ชันล่าสุด
package-cancel-download = ยกเลิกการดาวน์โหลด
package-open-file = เปิดไฟล์แพ็กเกจ
# Where the package came from. $file is a file name (text).
package-from-release = ดาวน์โหลด Atlas { $version } จาก GitHub แล้ว พร้อมติดตั้ง
package-from-file = โหลด Atlas { $version } จาก { $file } แล้ว พร้อมติดตั้ง
package-unpacked = Atlas { $version } พร้อมติดตั้งแล้ว
package-none-yet = ยังไม่ได้เลือกไฟล์ติดตั้ง
acquire-no-asset = Atlas { $version } ไม่มีไฟล์แพ็กเกจให้ดาวน์โหลด เปิดแพ็กเกจ Atlas (.apbx) ที่บันทึกไว้เพื่อดำเนินการต่อ
acquire-unsupported = แอปนี้ติดตั้งได้เฉพาะ Atlas 0.6.0 ขึ้นไป หากต้องการติดตั้ง Atlas { $version } ให้ใช้ AME Wizard แทน
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } ขาดไฟล์ที่แอปนี้ต้องใช้ในการติดตั้ง ดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.apbx) อีกไฟล์หนึ่ง
acquire-failed = เตรียมไฟล์ติดตั้งไม่ได้ ลองดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.apbx) อีกไฟล์หนึ่ง รายละเอียด: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = การดาวน์โหลดหยุดตอบสนอง ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.apbx) ที่บันทึกไว้
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = เตรียมแพ็กเกจ Atlas ที่มาพร้อมกันไม่ได้ เลือก ลองอีกครั้ง รายละเอียด: { $error }

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
check-fix-apps = เปิดแอปที่ติดตั้ง
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = ฉันตรวจสอบ Windows Update แล้ว ไม่มีการอัปเดตที่รอติดตั้ง

detail-admin-ok = Atlas มีสิทธิ์ทำการเปลี่ยนแปลงที่จำเป็นสำหรับการติดตั้ง
detail-admin-missing = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วเลือก ใช่ เมื่อ Windows ขอสิทธิ์
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas เวอร์ชันนี้ต้องใช้ Windows บิลด์ { $builds } แต่พีซีของคุณเป็นบิลด์ { $build } ติดตั้ง Windows เวอร์ชันที่รองรับก่อนดำเนินการต่อ
detail-build-missing = แพ็กเกจ Atlas นี้ไม่ได้ระบุบิลด์ Windows ที่รองรับ ใช้แพ็กเกจแบบบิลด์เต็มแทนบิลด์ LocalTest
detail-updates-none = ไม่มีการอัปเดต Windows ที่รอติดตั้ง
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] การอัปเดตนี้รอติดตั้งอยู่: { $titles } โดย Atlas จะติดตั้งให้ในการ์ด อัปเดต Windows และแอปจาก Store
        [2] การอัปเดตเหล่านี้รอติดตั้งอยู่: { $titles } โดย Atlas จะติดตั้งให้ในการ์ด อัปเดต Windows และแอปจาก Store
       *[other] มีการอัปเดต { $count } รายการรอติดตั้งอยู่ รวมถึง { $titles } โดย Atlas จะติดตั้งให้ในการ์ด อัปเดต Windows และแอปจาก Store
    }
detail-updates-unknown = ตรวจหาการอัปเดต Windows ไม่ได้ เปิด Windows Update แล้วยืนยันด้านล่างหากไม่มีการอัปเดตที่รอติดตั้ง ({ $error })
detail-reboot-none = Windows ไม่จำเป็นต้องรีสตาร์ตในขณะนี้
detail-reboot-pending = Windows ต้องรีสตาร์ตเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ เมื่อคุณเลือก ตรวจหาและติดตั้งการอัปเดต แล้ว Atlas จะขอให้คุณรีสตาร์ตก่อน
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Windows ต้องรีสตาร์ตเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ ({ $reasons }) เมื่อคุณเลือก ตรวจหาและติดตั้งการอัปเดต แล้ว Atlas จะขอให้คุณรีสตาร์ตก่อน
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = คุณดำเนินการต่อได้ Windows มีไฟล์ที่ต้องแทนที่หรือลบเมื่อรีสตาร์ตครั้งถัดไป ({ $files }) บางแอป เช่น Xbox Gaming Services จะทำเช่นนี้หลังรีสตาร์ตทุกครั้ง
detail-reboot-unknown = ตรวจสอบไม่ได้ว่า Windows ต้องรีสตาร์ตหรือไม่ รีสตาร์ตพีซี จากนั้นเปิด Atlas อีกครั้งแล้วตรวจสอบใหม่ ({ $error })
detail-antivirus-none = ไม่พบโปรแกรมป้องกันไวรัสอื่น
# $products is a list of product names (text).
detail-antivirus-found = แอปป้องกันไวรัสอื่นนอกเหนือจาก Microsoft Defender อาจขัดขวางการติดตั้ง ถอนการติดตั้ง { $products } แล้วเลือก ตรวจสอบอีกครั้ง
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = ความปลอดภัยของ Windows ยังแสดง { $products } อยู่ แต่ไฟล์ของโปรแกรมหายไปแล้ว จึงไม่ถือว่าติดตั้งอยู่อีกต่อไป Atlas ยังติดตั้งต่อได้
detail-antivirus-unknown = ตรวจหาโปรแกรมป้องกันไวรัสอื่นไม่ได้ เลือก ตรวจสอบอีกครั้ง หากยังไม่สำเร็จ ให้รีสตาร์ตพีซีแล้วตรวจสอบอีกครั้ง ({ $error })
detail-internet-ok = เชื่อมต่ออินเทอร์เน็ตอยู่ เชื่อมต่อไว้ตลอดขณะที่ Atlas ดาวน์โหลดและติดตั้งซอฟต์แวร์
detail-internet-missing = เชื่อมต่ออินเทอร์เน็ต แล้วตรวจสอบอีกครั้ง
detail-power-mains = พีซีของคุณเสียบปลั๊กอยู่ เสียบปลั๊กไว้จนกว่าการติดตั้งจะเสร็จ
detail-power-battery = เสียบปลั๊กพีซีของคุณเพื่อให้เปิดอยู่ตลอดการติดตั้ง
detail-power-unknown = Atlas ตรวจสอบไม่ได้ว่าพีซีของคุณเสียบปลั๊กอยู่หรือไม่ หากเป็นแล็ปท็อป ให้เสียบปลั๊ก แล้วเลือก ตรวจสอบอีกครั้ง หากยังเป็นเช่นนี้อยู่ ให้เลือก ส่งรายงาน
detail-activation-ok = Windows เปิดใช้งานแล้ว Atlas จะไม่เปลี่ยนแปลงสิ่งนี้
detail-activation-missing = Windows ยังไม่ได้เปิดใช้งาน คุณดำเนินการต่อได้ แต่ Atlas จะไม่เปิดใช้งาน Windows ให้
detail-activation-no-licence = Windows ไม่ได้รายงานสิทธิ์การใช้งาน คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ
detail-activation-unknown = ตรวจสอบการเปิดใช้งาน Windows ไม่ได้ คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ ({ $error })

## Step 2: Options

options-progress = ตัวเลือกที่ { $number } จาก { $total }
options-progress-extras = ตัวเลือกที่ { $number } จาก { $total }: รายการเพิ่มเติม
options-change-later = คุณเปลี่ยนตัวเลือกเกี่ยวกับ Microsoft Defender การป้องกันตัวประมวลผล และการอัปเดต ได้ภายหลังจากโฟลเดอร์ Atlas บนเดสก์ท็อปของคุณ
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = เก็บ Microsoft Defender ไว้หรือไม่
screen-mitigations-title = การป้องกันตัวประมวลผล
screen-mitigations-question = เก็บการป้องกันตัวประมวลผลของ Windows ไว้หรือไม่
screen-updates-title = Windows Update
screen-updates-question = ต้องการให้ Windows ติดตั้งการอัปเดตอย่างไร
screen-browser-title = เบราว์เซอร์
screen-power-title = พลังงานและความปลอดภัย
screen-apps-title = แอป
screen-optional-apps-title = แอปเสริม
screen-choose-one-title = เลือกหนึ่งตัวเลือก
screen-extras-title = รายการเพิ่มเติม
# Question for a required choice this app has no specific wording for.
screen-generic-question = เลือกตัวเลือกสำหรับ { $title }
learn-more-defender = เรียนรู้เพิ่มเติมเกี่ยวกับ Microsoft Defender
learn-more-mitigations = เรียนรู้เพิ่มเติมเกี่ยวกับการป้องกันตัวประมวลผล
learn-more-updates = เรียนรู้เพิ่มเติมเกี่ยวกับ Windows Update
learn-more-browser = เรียนรู้เพิ่มเติมเกี่ยวกับเบราว์เซอร์
learn-more-power = เรียนรู้เพิ่มเติมเกี่ยวกับพลังงานและความปลอดภัย
learn-more-apps = เรียนรู้เพิ่มเติมเกี่ยวกับแอป
learn-more-eclean = eclean ทำงานร่วมกับ AtlasOS อย่างไร
learn-more-generic = อ่านคู่มือการตั้งค่า
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = เก็บโปรแกรมป้องกันไวรัสที่มาพร้อม Windows ไว้ เพื่อช่วยปกป้องพีซีของคุณจากไวรัสและภัยคุกคามอื่น ๆ
consequence-defender-disable = นำ SmartScreen ออกด้วย พีซีของคุณจะไม่มีการป้องกันไวรัสจนกว่าคุณจะติดตั้งแอปป้องกันไวรัสอื่น และ Windows จะไม่เตือนคุณก่อนเปิดแอปหรือไฟล์ดาวน์โหลดที่ไม่รู้จัก
consequence-mitigations-default = เก็บการป้องกันเริ่มต้นของ Windows ไว้ เพื่อรับมือกับข้อบกพร่องของตัวประมวลผลและการโจมตีที่อาศัยบั๊กในแอป
consequence-mitigations-disable = ปิด การป้องกัน Exploit สำหรับแอปด้วย เช่น Control Flow Guard การทำเช่นนี้จะลดความปลอดภัย ประสิทธิภาพจะต่างไปมากน้อยเพียงใดขึ้นอยู่กับตัวประมวลผลของคุณ
consequence-auto-updates-disable = เปิด Windows Update เป็นประจำเพื่อติดตั้งการอัปเดต การแจ้งเตือนการอัปเดตจะยังเปิดอยู่
consequence-auto-updates-default = Windows จะติดตั้งการอัปเดตโดยอัตโนมัติ รวมถึงการแก้ไขด้านความปลอดภัย

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = เก็บ Microsoft Defender ไว้ (แนะนำ)
playbook-option-defender-disable = นำ Microsoft Defender ออก
playbook-option-mitigations-default = เก็บการป้องกันตัวประมวลผลไว้ (แนะนำ)
playbook-option-mitigations-disable = ปิดการป้องกันตัวประมวลผล
playbook-option-auto-updates-disable = ติดตั้งการอัปเดตเอง
playbook-option-auto-updates-default = ติดตั้งการอัปเดตโดยอัตโนมัติ
playbook-option-disable-hibernation = ปิดไฮเบอร์เนต
playbook-option-disable-power-saving = ปิดการประหยัดพลังงาน
playbook-option-disable-core-isolation = ปิดความปลอดภัยที่ใช้การจำลองเสมือน (VBS)
# Thai Windows localizes Snipping Tool as "เครื่องมือสนิป".
playbook-option-remove-snipping-tool = นำเครื่องมือสนิปออก
playbook-option-uninstall-edge = นำ Microsoft Edge ออก
playbook-option-install-another-browser = ติดตั้งเบราว์เซอร์
playbook-option-install-toolbox = ติดตั้ง Atlas Toolbox
playbook-option-install-eclean = ติดตั้ง eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender คือโปรแกรมป้องกันไวรัสที่มาพร้อมกับ Windows ให้นำออกเฉพาะเมื่อคุณเข้าใจความเสี่ยงและวางแผนจะใช้แอปป้องกันไวรัสอื่น ไม่ว่าคุณจะเลือกแบบใด Atlas จะปิด การควบคุมแอปแบบอัจฉริยะ การป้องกันฟิชชิ่งขั้นสูง และ ค้นหาอุปกรณ์ของฉัน
playbook-page-mitigations-default-description = การป้องกันเหล่านี้ หรือที่เรียกว่ามาตรการลดความเสี่ยงด้านความปลอดภัย ช่วยรับมือกับข้อบกพร่องของตัวประมวลผล เช่น Spectre และ Meltdown รวมถึงการโจมตีที่อาศัยบั๊กในแอป แนะนำให้ใช้ค่าเริ่มต้นของ Windows
playbook-page-auto-updates-disable-description = การอัปเดต Windows มีการแก้ไขด้านความปลอดภัยรวมอยู่ด้วย คุณจะให้ Windows ติดตั้งการอัปเดตโดยอัตโนมัติหรือติดตั้งเองก็ได้ ไม่ว่าจะเลือกแบบใด Atlas จะคง Windows ไว้ที่เวอร์ชันปัจจุบัน ซึ่งจะได้รับการแก้ไขด้านความปลอดภัยจนกว่า Microsoft จะสิ้นสุดการสนับสนุนเวอร์ชันนั้นเท่านั้น นอกจากนี้ Atlas ยังปิดการอัปเดตอัตโนมัติสำหรับแอปจาก Microsoft Store ด้วย จึงควรอัปเดตแอปเหล่านั้นใน Microsoft Store
playbook-page-browser-brave-description = เลือกเบราว์เซอร์ที่ต้องการติดตั้ง โดย Atlas จะไม่เปลี่ยนการตั้งค่าเบราว์เซอร์ของคุณ

## Step 3: Windows Security

security-banner-reading-title = กำลังตรวจสอบความปลอดภัยของ Windows
security-banner-reading-message = Atlas กำลังตรวจสอบสวิตช์การป้องกันทั้งสี่รายการด้านล่าง
security-banner-off-title = สวิตช์การป้องกันทั้งสี่รายการปิดอยู่
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = พีซีเครื่องนี้ไม่ได้ติดตั้ง Microsoft Defender ไว้
security-banner-absent-message = ไม่มีสิ่งใดต้องปิดในขั้นตอนนี้ เลือก ดำเนินการต่อ
security-banner-off-message = เลือก ดำเนินการต่อ เพื่อตรวจทานการตั้งค่าและติดตั้ง Atlas
security-banner-on-title = ปิดการป้องกันไวรัสในแอป ความปลอดภัยของ Windows
security-banner-on-message = Microsoft Defender อาจขัดขวางการเปลี่ยนแปลงที่ Atlas ทำ เลือก เปิดแอป ความปลอดภัยของ Windows แล้วปิดสวิตช์แต่ละรายการที่แสดงด้านล่าง หากคุณเก็บ Microsoft Defender ไว้ ให้เปิดสวิตช์เหล่านี้อีกครั้งหลังติดตั้งเสร็จ
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
security-unknown-message = ตรวจดูให้แน่ใจว่าสวิตช์ทั้งสี่รายการปิดอยู่ในแอป ความปลอดภัยของ Windows แล้วยืนยันด้านล่าง
security-acknowledge = ฉันตรวจดูในแอป ความปลอดภัยของ Windows แล้ว สวิตช์ทั้งสี่รายการปิดอยู่
security-unknown-unelevated-title = Atlas ต้องได้รับสิทธิ์จึงจะตรวจสอบการป้องกันได้
security-unknown-unelevated-message = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบเพื่อให้ Atlas ตรวจสอบการตั้งค่าของ Microsoft Defender ได้
# The four switches, named as Thai Windows Security names them (checked against
# Microsoft's Thai support pages on 6 September 2026; not yet compared with a
# Thai-language Windows installation).
protection-tamper = การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย
protection-tamper-why = ปิดสวิตช์นี้เพื่อไม่ให้ Defender ขัดขวาง Atlas ในการเปลี่ยนการตั้งค่าความปลอดภัยของ Defender
protection-realtime = การป้องกันแบบเรียลไทม์
protection-realtime-why = ปิดสวิตช์นี้เพื่อไม่ให้ Defender บล็อกไฟล์ติดตั้งของ Atlas ระหว่างสแกน
protection-cloud = การป้องกันบนระบบคลาวด์
protection-cloud-why = ปิดสวิตช์นี้เพื่อไม่ให้การตรวจสอบภัยคุกคามทางออนไลน์บล็อกไฟล์ติดตั้งของ Atlas
protection-samples = การส่งตัวอย่างโดยอัตโนมัติ
protection-samples-why = หยุดไม่ให้ Defender ส่งไฟล์ของ Atlas ไปให้ Microsoft วิเคราะห์โดยอัตโนมัติ

## Step 4: Install

# Accessible name of the progress bar.
install-progress = ความคืบหน้าการติดตั้ง
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = ติดตั้ง Atlas แล้ว
outcome-lost-title = ยืนยันผลการติดตั้งไม่ได้
outcome-failed-title = การติดตั้งไม่เสร็จสมบูรณ์
outcome-requirements = พีซีของคุณไม่ตรงตามข้อกำหนดการติดตั้ง ยังไม่มีการเปลี่ยนแปลงใด ๆ กลับไปที่ เตรียมความพร้อม แล้วตรวจสอบอีกครั้ง
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = พีซีของคุณไม่ตรงตามข้อกำหนดการติดตั้ง การติดตั้งรอบนี้จึงหยุดลง แต่การติดตั้งรอบก่อนได้เริ่มทำการเปลี่ยนแปลงไปแล้ว กลับไปที่ เตรียมความพร้อม แล้วตรวจสอบอีกครั้ง
outcome-not-elevated = Atlas ไม่มีสิทธิ์ผู้ดูแลระบบ ยังไม่มีการเปลี่ยนแปลงใด ๆ เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วลองอีกครั้ง
outcome-not-elevated-resumed = Atlas ไม่มีสิทธิ์ผู้ดูแลระบบ การติดตั้งรอบนี้จึงหยุดลง การติดตั้งรอบก่อนได้เริ่มทำการเปลี่ยนแปลงไปแล้ว เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วลองอีกครั้ง
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "Check and install updates" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas ยืนยันไม่ได้ว่า Windows และแอปจาก Store เป็นเวอร์ชันล่าสุดแล้ว การติดตั้งจึงหยุดลงก่อนเปลี่ยนแปลง Windows กลับไปที่ เตรียมความพร้อม แล้วเลือก ตรวจหาและติดตั้งการอัปเดต
outcome-preparation-stale-resumed = Atlas ยืนยันไม่ได้ว่า Windows และแอปจาก Store เป็นเวอร์ชันล่าสุดแล้ว การติดตั้งรอบนี้จึงหยุดลง แต่การติดตั้งรอบก่อนได้เริ่มทำการเปลี่ยนแปลงไปแล้ว กลับไปที่ เตรียมความพร้อม แล้วเลือก ตรวจหาและติดตั้งการอัปเดต
outcome-failed-preflight = การติดตั้งหยุดลงก่อนที่จะเปลี่ยนแปลงสิ่งใด คุณลองอีกครั้งได้ หากหยุดลงอีก ให้เลือก ส่งรายงาน
outcome-failed-staging = การติดตั้งหยุดลงระหว่างเตรียมไฟล์ ก่อนที่จะเปลี่ยนแปลง Windows คุณลองอีกครั้งได้ หากหยุดลงอีก ให้เลือก ส่งรายงาน
outcome-failed-applying = อาจมีการเปลี่ยนแปลงบางอย่างเกิดขึ้นแล้ว คุณลองอีกครั้งได้ หากคุณจะหยุดไว้เพียงเท่านี้ ให้กลับไปเปิดการป้องกันที่ปิดไว้ในแอป ความปลอดภัยของ Windows อีกครั้ง หากการป้องกันเหล่านั้นยังมีอยู่
outcome-failed-resumed = การติดตั้งรอบนี้หยุดลงตั้งแต่ช่วงต้น แต่การติดตั้งรอบก่อนได้เริ่มทำการเปลี่ยนแปลงไปแล้ว คุณลองอีกครั้งได้ หากคุณจะหยุดไว้เพียงเท่านี้ ให้กลับไปเปิดการป้องกันที่ปิดไว้ในแอป ความปลอดภัยของ Windows อีกครั้ง หากการป้องกันเหล่านั้นยังมีอยู่
outcome-not-started = ตัวติดตั้งไม่เริ่มทำงานภายในเวลาที่กำหนด ยังไม่มีการเปลี่ยนแปลงใด ๆ คุณลองอีกครั้งได้
outcome-lost = ตัวติดตั้งหยุดทำงานโดยไม่ได้รายงานผล และอาจมีการเปลี่ยนแปลงบางอย่างเกิดขึ้นแล้ว คุณลองอีกครั้งได้ หากคุณจะหยุดไว้เพียงเท่านี้ ให้กลับไปเปิดการป้องกันที่ปิดไว้ในแอป ความปลอดภัยของ Windows อีกครั้ง หากการป้องกันเหล่านั้นยังมีอยู่
restart-now-message = Windows กำลังรีสตาร์ตเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-countdown = Windows จะรีสตาร์ตในอีก { $seconds } วินาทีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์ หากต้องการบันทึกงานก่อน ให้เลือก รีสตาร์ตภายหลัง
restart-stopped = ยกเลิกการรีสตาร์ตอัตโนมัติแล้ว บันทึกงานของคุณ แล้วรีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-needed = บันทึกงานของคุณ แล้วรีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-dont-now = รีสตาร์ตภายหลัง
restart-now = รีสตาร์ตเดี๋ยวนี้
restart-start-failed = Atlas รีสตาร์ตพีซีของคุณไม่ได้ บันทึกงานของคุณ แล้วรีสตาร์ตจากเมนูเริ่ม รายละเอียด: { $error }
preflight-title = ยังไม่ได้เริ่มการติดตั้ง
preflight-invalid-options = Atlas ใช้ตัวเลือกการตั้งค่าเหล่านี้ไม่ได้ กลับไปที่ ตัวเลือกของคุณ เพื่อตรวจทาน แล้วลองอีกครั้ง รายละเอียด: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = สถานะของพีซีเปลี่ยนไปหลังการตรวจสอบครั้งก่อน แก้ไขรายการต่อไปนี้ก่อนลองอีกครั้ง { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = ความปลอดภัยของ Windows: { $summary }
preflight-busy = หน้าต่าง Atlas อีกหน้าต่างหนึ่งกำลังเริ่มการติดตั้ง รอสักครู่ แล้วเลือก ติดตั้ง Atlas อีกครั้ง
# Shown with the home-start-over button.
preflight-taken-over = หน้าต่าง Atlas อีกหน้าต่างหนึ่งกำลังดำเนินการตั้งค่านี้อยู่ จึงยังไม่ได้เริ่มการติดตั้ง ดำเนินการต่อในหน้าต่างนั้น หรือเลือก เริ่มใหม่ตั้งแต่ต้น เพื่อตั้งค่าใหม่ในหน้าต่างนี้
preflight-record-unreadable = Atlas ตรวจสอบไม่ได้ว่าการติดตั้งครั้งก่อนยังทำงานอยู่หรือไม่ จึงไม่ได้เริ่มการติดตั้งใหม่ กลับไปที่ เตรียมความพร้อม เพื่อดูว่าต้องทำอะไรต่อ รายละเอียด: { $error }
preflight-refused = เริ่มตัวติดตั้งไม่ได้ ยังไม่มีการเปลี่ยนแปลงใด ๆ เลือก ติดตั้ง Atlas เพื่อลองอีกครั้ง หากยังเกิดขึ้นอีก ให้เลือก ส่งรายงาน รายละเอียด: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = เริ่มตัวติดตั้งไม่ได้ การติดตั้งรอบนี้จึงหยุดลง การติดตั้งรอบก่อนได้เริ่มทำการเปลี่ยนแปลงไปแล้ว เลือก ติดตั้ง Atlas เพื่อลองอีกครั้ง หากยังเกิดขึ้นอีก ให้เลือก ส่งรายงาน รายละเอียด: { $error }
go-to-ready = กลับไปที่ เตรียมความพร้อม
go-to-options = กลับไปที่ ตัวเลือกของคุณ
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = กลับไปที่ ติดตั้ง
output-problem-title = อ่านความคืบหน้าการติดตั้งไม่ได้
output-problem-message = Atlas อ่านบันทึกไม่ได้ แต่ไม่ได้หมายความว่าการติดตั้งหยุดลง เปิดพีซีไว้ แล้วลองเปิดไฟล์บันทึก รายละเอียด: { $error }
install-elevate-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
install-no-package-title = เลือกไฟล์ติดตั้งก่อน
install-no-package-message = กลับไปที่ เตรียมความพร้อม เพื่อดาวน์โหลด Atlas หรือเปิดแพ็กเกจ Atlas (.apbx) ที่บันทึกไว้
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = กลับไปที่ เตรียมความพร้อม เพื่อเตรียมแพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = ทำขั้นตอน เตรียมความพร้อม ให้เสร็จก่อน
install-not-ready-message = Atlas ต้องตรวจสอบพีซีและอัปเดต Windows ให้เสร็จก่อนจึงจะติดตั้งได้
install-security-title = ตรวจสอบการป้องกันไวรัสก่อนติดตั้ง
install-security-reading = กำลังตรวจสอบสวิตช์การป้องกันทั้งสี่รายการอีกครั้ง
install-security-message = สวิตช์การป้องกัน{ $summary } เปิดแอป ความปลอดภัยของ Windows แล้วตรวจดูให้แน่ใจว่าสวิตช์ทั้งสี่รายการปิดอยู่ก่อนติดตั้ง
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
summary-copy-command-a11y = คัดลอกคำสั่งติดตั้ง
summary-command-unavailable = เตรียมคำสั่งติดตั้งไม่ได้ รายละเอียด: { $error }
summary-not-chosen = ยังไม่ได้เลือก
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = เปลี่ยน { $title }
footer-still-checking = กำลังเตรียมการติดตั้ง
footer-fix-items = แก้ไขรายการในการ์ด การตรวจสอบพีซี เพื่อดำเนินการต่อ
footer-need-package = ดาวน์โหลด Atlas หรือเปิดแพ็กเกจ Atlas เพื่อดำเนินการต่อ
# Tester build variant of footer-need-package.
footer-need-package-bundled = เตรียมแพ็กเกจ Atlas ที่มาพร้อมกันเพื่อดำเนินการต่อ
footer-reading-security = กำลังตรวจสอบสวิตช์การป้องกัน
footer-security-pending = ปิดสวิตช์ทั้งสี่รายการเพื่อดำเนินการต่อ
footer-security-confirm = ยืนยันสวิตช์ที่ Atlas อ่านค่าไม่ได้เพื่อดำเนินการต่อ
footer-install-ready = บันทึกงานและปิดแอปของคุณก่อน
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
installing-restart-auto = พีซีของคุณจะรีสตาร์ตโดยอัตโนมัติเมื่อติดตั้งเสร็จ บันทึกงานในแอปอื่น ๆ ไว้ก่อนถึงตอนนั้น

## The "Atlas is installed" window after the restart

installed-title-version = ติดตั้ง Atlas { $version } แล้ว
installed-title = ติดตั้ง Atlas แล้ว
installed-ready = เรียบร้อยแล้ว พีซีของคุณพร้อมใช้งานกับ Atlas
installed-security-message = คุณเก็บ Microsoft Defender ไว้ แต่การป้องกันบางรายการยังปิดอยู่ เปิดแอป ความปลอดภัยของ Windows แล้วตรวจดูให้แน่ใจว่ารายการต่อไปนี้เปิดอยู่: { $switches }
installed-defender-removed-title = นำ Microsoft Defender ออกแล้ว
installed-defender-removed-message = พีซีของคุณจะไม่มีการป้องกันไวรัสจนกว่าคุณจะติดตั้งแอปป้องกันไวรัสอื่น และ SmartScreen ถูกนำออกไปด้วย Windows จึงจะไม่เตือนคุณก่อนเปิดแอปหรือไฟล์ดาวน์โหลดที่ไม่รู้จัก
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = คุณเลือกเก็บ Microsoft Defender ไว้ แต่ไม่พบ Microsoft Defender ในพีซีเครื่องนี้ หากคุณไม่ได้ใช้แอปป้องกันไวรัสอื่น ให้ติดตั้งแอปป้องกันไวรัสเพื่อปกป้องพีซีของคุณ หากคุณไม่ได้นำ Defender ออกเอง ให้เลือก รายงานปัญหา

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
settings-language-system-selected = { settings-language-system } ({ $language })
# Under the language box while a particular language is chosen: what Match Windows
# would give instead. $language is a language's own name.
settings-language-system-detail = เมื่อเลือกตาม Windows: { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = รุ่นตัวอย่าง
# Under the language box, once, explaining the Preview tag.
settings-language-preview-note = คำแปลรุ่นตัวอย่างยังไม่ได้รับการตรวจทานโดยเจ้าของภาษา
preview-notice = { $language } เป็นคำแปลรุ่นตัวอย่างและอาจมีข้อผิดพลาด
preview-notice-switch = สลับเป็นภาษาอังกฤษ
preview-notice-language = เปลี่ยนภาษา
# $tag is a language tag (text).
settings-language-unavailable = Atlas เวอร์ชันนี้ไม่มี { $tag } จึงแสดงภาษาอังกฤษไปก่อน โดยภาษาที่คุณเลือกยังคงบันทึกไว้
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas ยังไม่รองรับภาษาที่ใช้แสดงผลของ Windows ของคุณ ({ $languages }) จึงแสดงภาษาอังกฤษไปก่อน
settings-language-windows-unavailable = ตรวจสอบภาษาที่ใช้แสดงผลของ Windows ไม่ได้ Atlas จึงใช้ภาษาอังกฤษไปก่อน รายละเอียด: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = ตัวเลข วันที่ และเวลาจะเป็นไปตามรูปแบบภูมิภาคของ Windows ({ $locale })
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = ตัวเลขจะเป็นไปตามรูปแบบภูมิภาคของ Windows ({ $locale }) ส่วนวันที่และเวลาจะใช้รูปแบบมาตรฐาน เนื่องจาก Atlas ยังแสดงข้อความที่เขียนจากขวาไปซ้ายไม่ได้
settings-language-contribute = ช่วยแปล Atlas บน GitHub
settings-restart-label = รีสตาร์ตพีซีของฉันโดยอัตโนมัติหลังติดตั้งเสร็จ
settings-restart-locked = คุณเปลี่ยนการตั้งค่านี้ได้หลังการติดตั้งเสร็จ
settings-restart-description = เมื่อเปิดการตั้งค่านี้ พีซีของคุณจะรีสตาร์ตภายในหนึ่งนาทีหลังติดตั้งเสร็จ ซึ่งจะปิดแอปที่เปิดอยู่ บันทึกงานของคุณก่อนติดตั้ง
settings-help = ความช่วยเหลือและคำติชม
settings-about = เกี่ยวกับ
settings-about-app = Atlas Manager
settings-about-licence = สัญญาอนุญาต
settings-about-licence-value = GPL-3.0 ซอฟต์แวร์เสรีและโอเพนซอร์ส
settings-view-source = ดูซอร์สโค้ดบน GitHub
# Link that opens the third-party licence notices.
settings-view-licences = ดูประกาศสัญญาอนุญาต
# Under the links when Windows could not open the notices.
settings-licences-failed = เปิดประกาศสัญญาอนุญาตไม่ได้ ลองอีกครั้ง หรือดูได้ในซอร์สโค้ดบน GitHub
settings-open-data-folder = เปิดโฟลเดอร์ของแอป

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = คืนพื้นที่ดิสก์ที่ใช้บันทึกเซสชันของคุณเมื่อไฮเบอร์เนต โดยจะใช้ไฮเบอร์เนตและการเริ่มต้นอย่างรวดเร็วไม่ได้
consequence-disable-power-saving = ปิดฟีเจอร์ประหยัดพลังงาน พีซีของคุณอาจใช้ไฟมากขึ้น ร้อนขึ้น และใช้แบตเตอรี่ได้สั้นลง
consequence-disable-core-isolation = ปิดชั้นความปลอดภัยเพิ่มเติมของ Windows รวมถึงความสมบูรณ์ของหน่วยความจำ ซึ่งจะลดการป้องกันลง และอาจกระทบแอปหรือเกมที่ต้องใช้ฟีเจอร์นี้
consequence-remove-snipping-tool = นำแอปของ Windows สำหรับจับภาพหน้าจอและบันทึกวิดีโอหน้าจอออก
consequence-uninstall-edge = นำเบราว์เซอร์ Microsoft Edge ออก ตรวจดูให้แน่ใจว่าคุณมีเบราว์เซอร์อื่นอยู่ หรือเลือกเบราว์เซอร์ด้านล่าง
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = นำ Microsoft Edge ออก และลบรายการโปรด ประวัติ และรหัสผ่านที่บันทึกไว้ของ Edge บนพีซีเครื่องนี้ ข้อมูลที่ไม่ได้ซิงค์กับบัญชี Microsoft ของคุณจะสูญหาย ตรวจดูให้แน่ใจว่าคุณมีเบราว์เซอร์อื่นอยู่ หรือเลือกเบราว์เซอร์ด้านล่าง
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = ลบรายการโปรด ประวัติ และรหัสผ่านที่บันทึกไว้ของ Edge บนพีซีเครื่องนี้
consequence-install-another-browser = เลือกเบราว์เซอร์ด้านล่าง แล้ว Atlas จะติดตั้งให้คุณ
consequence-install-toolbox = เพิ่ม Atlas Toolbox เพื่อช่วยจัดการการตั้งค่า Atlas ของคุณ โดย Toolbox ยังอยู่ในรุ่นเบต้า บางฟีเจอร์จึงอาจยังไม่สมบูรณ์
consequence-install-eclean = เครื่องมือบำรุงรักษาจากทีมผู้สร้าง AtlasOS เพื่อดูแลพีซีของคุณให้เป็นระเบียบหลังตั้งค่า ตรวจสอบไฟล์ขยะและแอปเริ่มต้นระบบ ต้องมีบัญชีและการเชื่อมต่ออินเทอร์เน็ต

# Introduction on the home page before Atlas is installed.
home-intro = Atlas ปรับ Windows เพื่อลดการทำงานเบื้องหลังและสิ่งรบกวน ติดตั้ง Atlas บน Windows ที่ติดตั้งใหม่ทั้งหมด ก่อนที่คุณจะเพิ่มแอปและไฟล์ของคุณเอง

## ISO creation (Beta)
iso-home-title = สื่อการติดตั้ง Windows
iso-home-description = สร้างไฟล์ติดตั้ง Windows (ISO) ที่มี Atlas อยู่ด้วย แล้วใช้ไฟล์นั้นติดตั้ง Windows ใหม่บนพีซีเครื่องนี้หรือเครื่องอื่น
iso-open = สร้าง ISO พร้อม Atlas
iso-title = สร้าง ISO พร้อม Atlas
iso-beta = เบต้า
iso-beta-description = ทดสอบ ISO ในเครื่องเสมือนก่อนนำไปใช้บนพีซี และสำรองไฟล์ก่อนติดตั้ง Windows
iso-admin-description = Atlas ต้องได้รับสิทธิ์ผู้ดูแลระบบเพื่ออ่าน ISO ของ Windows และสร้าง ISO ใหม่ เลือก เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วเลือก ใช่ เมื่อ Windows ถาม
iso-files-description = Atlas จะคัดลอก ISO ของ Windows 11 แล้วเพิ่ม Atlas ลงไป เพื่อใช้ติดตั้ง Windows ใหม่ เลือก ISO ของ Windows 11 ที่ดาวน์โหลดจาก Microsoft ดาวน์โหลดแพ็กเกจ Atlas ล่าสุดหรือเลือกแพ็กเกจที่คุณมีอยู่แล้ว (.apbx) จากนั้นเลือกตำแหน่งที่จะบันทึก ISO ใหม่
# Tester build: no package picker.
iso-files-description-bundled = Atlas จะคัดลอก ISO ของ Windows 11 แล้วเพิ่มแพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้ลงไป เลือก ISO ของ Windows 11 ที่ดาวน์โหลดจาก Microsoft จากนั้นเลือกตำแหน่งที่จะบันทึก ISO ใหม่
iso-source = ISO ของ Windows
iso-source-download = ดาวน์โหลด Windows 11 จาก Microsoft
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = แพ็กเกจ Atlas ({ $minimum } ขึ้นไป)
iso-output = บันทึก ISO ใหม่ที่
iso-no-file = ยังไม่ได้เลือกไฟล์
iso-browse = เรียกดู
iso-save-as = บันทึกเป็น
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = ตรวจสอบไฟล์
iso-mode-title = ต้องการตั้งค่า Atlas อย่างไร
iso-mode-interactive = กำหนดตัวเลือก Atlas หลังเข้าสู่ระบบ
iso-mode-interactive-description = หลังจากคุณเข้าสู่ระบบแล้ว Atlas จะเปิดขึ้นและแนะนำคุณทีละขั้นตอน ตั้งแต่การอัปเดต การเลือกตัวเลือก ไปจนถึงการติดตั้ง Atlas
iso-mode-before = กำหนดตัวเลือก Atlas ตอนนี้
iso-mode-before-description = Atlas จะบันทึกตัวเลือกของคุณลงใน ISO หลังจากคุณเข้าสู่ระบบแล้ว Atlas จะเปิดขึ้นและแนะนำคุณทีละขั้นตอนในการอัปเดต จากนั้นคุณจึงติดตั้ง Atlas ด้วยตัวเลือกเหล่านี้
iso-package-unsupported-title = เลือกแพ็กเกจ Atlas รุ่นใหม่กว่า
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported = แพ็กเกจ Atlas นี้บันทึกตัวเลือก Atlas ลงใน ISO ไม่ได้ เลือกแพ็กเกจรุ่นใหม่กว่า หรือเลือก กำหนดตัวเลือก Atlas หลังเข้าสู่ระบบ
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = ใช้แพ็กเกจ Atlas นี้สร้าง ISO ไม่ได้ เลือกแพ็กเกจสำหรับ Atlas { $minimum } ขึ้นไป
# Tester build: the bundled package cannot be swapped, so the only way on is the after-sign-in
# mode. Also the Your choices footer hint for any package that can't save choices.
iso-package-unsupported-bundled-title = บันทึกตัวเลือก Atlas ลงใน ISO นี้ไม่ได้
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported-bundled = แพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้ไม่รองรับการตั้งค่าผ่าน ISO ให้เลือก กำหนดตัวเลือก Atlas หลังเข้าสู่ระบบ แทน
iso-atlas-options = ตัวเลือก Atlas
iso-review = ตรวจทาน ISO
iso-review-description = การสร้าง ISO จะไม่ติดตั้งสิ่งใดบนพีซีเครื่องนี้ และไม่เปลี่ยนแปลง ISO ต้นฉบับของคุณ หลังจากนั้น Atlas สามารถนำ ISO ใหม่ไปใส่ในไดรฟ์ USB เพื่อให้คุณใช้ติดตั้ง Windows ใหม่ได้
iso-review-files = ไฟล์
iso-step-windows = การตั้งค่า Windows
iso-step-review = ตรวจทาน
iso-review-package = แพ็กเกจ Atlas
iso-review-output = ISO ใหม่
iso-review-editions = รุ่น
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = ชื่อบัญชี
iso-review-target = ติดตั้งบน
iso-review-drivers = ไดรเวอร์
iso-create = สร้าง ISO
iso-progress-title = กำลังสร้าง ISO ของคุณ
iso-stage-inspect = กำลังตรวจสอบ ISO ของ Windows
iso-stage-copy = กำลังคัดลอกไฟล์ Windows
iso-stage-add-atlas = กำลังเพิ่ม Atlas
iso-stage-master = กำลังเขียนไฟล์ ISO
iso-stage-verify = กำลังตรวจสอบ ISO ใหม่
iso-stage-cleanup = กำลังดำเนินการขั้นสุดท้าย
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = กำลังดำเนินการ
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = ไม่สำเร็จ
iso-stage-status-not-started = ยังไม่เริ่ม
iso-progress-description = เปิด Atlas ไว้ การประมวลผลอิมเมจขนาดใหญ่อาจใช้เวลาสักครู่
iso-cancel = ยกเลิกการสร้าง
iso-cancelling = กำลังรอจุดที่ยกเลิกได้อย่างปลอดภัย
iso-cancelled = ยกเลิกการสร้าง ISO แล้ว
iso-cancelled-description = ISO ต้นฉบับของคุณไม่มีการเปลี่ยนแปลง หากมีไฟล์ชั่วคราวหลงเหลืออยู่ ให้เลือก เปิดโฟลเดอร์บันทึก เพื่อดูว่าไฟล์อยู่ที่ใด
iso-complete = ISO พร้อมใช้งานแล้ว
iso-complete-description = การสร้าง ISO ยังอยู่ในรุ่นเบต้า จึงควรทดสอบ ISO ในเครื่องเสมือนก่อน จากนั้นเลือก สร้าง USB ติดตั้ง Windows และสำรองไฟล์ของคุณก่อนติดตั้ง Windows ใหม่
iso-open-folder = แสดงในโฟลเดอร์
iso-failed = สร้าง ISO ไม่สำเร็จ
iso-failed-description = ตรวจดูให้แน่ใจว่าไฟล์ของคุณยังอยู่ในตำแหน่งที่เลือกไว้ และไดรฟ์ที่จะบันทึกยังเชื่อมต่ออยู่ จากนั้นเลือก สร้าง ISO หากยังไม่สำเร็จ ให้เลือก ส่งรายงาน
# Title while the Check files step fails; the messages below say why.
iso-check-failed = ตรวจสอบไฟล์ไม่ได้
iso-check-failed-description = ตรวจดูให้แน่ใจว่า ISO และแพ็กเกจ Atlas ยังอยู่ในตำแหน่งที่คุณเลือกและดาวน์โหลดเสร็จแล้ว จากนั้นเลือก ตรวจสอบไฟล์ หากยังไม่สำเร็จ ให้เลือก ส่งรายงาน
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะสร้าง ISO ได้
# Typed reasons reported by the image worker.
iso-failed-output-exists = มีไฟล์ชื่อนี้อยู่แล้ว เลือก บันทึกเป็น แล้วป้อนชื่อไฟล์ใหม่
iso-failed-destination = Atlas บันทึก ISO ใหม่ที่ตำแหน่งนั้นไม่ได้ เลือก บันทึกเป็น แล้วเลือกโฟลเดอร์ในพีซีเครื่องนี้ เช่น ดาวน์โหลด ตำแหน่งบนเครือข่ายและไดรฟ์ที่ฟอร์แมตเป็น FAT32 หรือ exFAT ซึ่งรวมถึงไดรฟ์ USB จำนวนมาก ใช้บันทึกไม่ได้
iso-failed-space = พื้นที่ว่างในไดรฟ์ปลายทางไม่พอ เพิ่มพื้นที่ว่าง หรือบันทึก ISO ใหม่ลงในไดรฟ์อื่น
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = ISO นี้ไม่มีรุ่น Windows ที่รองรับ ไม่รองรับ Windows Home และ LTSC ให้ใช้ ISO ที่มีรุ่นอื่น เช่น Pro, Education หรือ Enterprise
iso-failed-customised = ISO นี้มีไฟล์ตั้งค่าแบบกำหนดเองอยู่แล้ว เช่น autounattend.xml เลือก ISO ของ Windows จาก Microsoft ที่ไม่ได้ดัดแปลง
iso-failed-windows-unsupported = แพ็กเกจ Atlas ไม่รองรับอิมเมจ Windows นี้ ใช้ ISO ของ Windows 11 แบบ 64 บิตที่ไม่ได้ดัดแปลง สำหรับเวอร์ชันที่แพ็กเกจนี้รองรับ
iso-failed-network-architecture = ไดรเวอร์เครือข่ายของพีซีเครื่องนี้ไม่ตรงกับสถาปัตยกรรมของ ISO นี้ ย้อนกลับไปแล้วยกเลิกการเลือก รวมไดรเวอร์เครือข่ายของพีซีเครื่องนี้ หรือเลือก ISO ที่ตรงกับพีซีเครื่องนี้
iso-failed-unstaged = Atlas เตรียมโฟลเดอร์ทำงานไม่ได้ จึงไม่มีการเปลี่ยนแปลงใด ๆ ลองอีกครั้ง หากยังไม่สำเร็จ ให้เลือก ส่งออกข้อมูลการวินิจฉัย เพื่อแนบไปกับรายงานข้อบกพร่อง
iso-failed-package-changed = แพ็กเกจ Atlas มีการเปลี่ยนแปลงหลังจากตรวจสอบไฟล์แล้ว เลือก เปลี่ยน ในส่วน ไฟล์ แล้วเลือก ตรวจสอบไฟล์
iso-diagnostics = เปิดโฟลเดอร์บันทึก
iso-close-title = ยังสร้าง ISO อยู่
iso-close-message = เปิดหน้าต่างนี้ไว้จนกว่าการสร้างหรือการยกเลิกจะเสร็จ การยกเลิกจะรอจนกว่าขั้นตอนปัจจุบันจะหยุดได้อย่างปลอดภัย
iso-keep-open = เปิดไว้
prepare-title = อัปเดต Windows และแอปจาก Store
prepare-description = Atlas จะอัปเดต Windows รวมถึง Microsoft Store และแอปจาก Store ของคุณก่อนติดตั้ง แอปจาก Store ที่คุณเปิดอยู่ เช่น Notepad, Paint หรือ Windows Terminal อาจปิดลงระหว่างอัปเดต จึงควรบันทึกงานในแอปเหล่านั้นก่อน และพีซีของคุณอาจต้องรีสตาร์ตด้วย
prepare-complete = Atlas ไม่พบการอัปเดต Windows หรือ Store ที่ต้องติดตั้งเพิ่มเติม
prepare-reboot-title = รีสตาร์ตพีซีเพื่อดำเนินการต่อ
prepare-reboot = พีซีของคุณต้องรีสตาร์ตเพื่อติดตั้งการอัปเดตให้เสร็จ Atlas จะบันทึกตัวเลือกที่คุณเลือกไว้จนถึงตอนนี้ และจะเปิดขึ้นอีกครั้งหลังจากคุณเข้าสู่ระบบ
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = พีซีของคุณต้องรีสตาร์ตเพื่อติดตั้งการอัปเดตให้เสร็จ ({ $reasons }) Atlas จะบันทึกตัวเลือกที่คุณเลือกไว้จนถึงตอนนี้ และจะเปิดขึ้นอีกครั้งหลังจากคุณเข้าสู่ระบบ
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = บันทึกงานและปิดแอปของคุณก่อน พีซีของคุณจะรีสตาร์ตทันทีเมื่อคุณเลือก รีสตาร์ตและดำเนินการต่อ
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = พีซีของคุณรีสตาร์ตแล้ว แต่ Windows ยังแจ้งว่าต้องรีสตาร์ต ({ $reasons }) การรีสตาร์ตอีกครั้งจึงน่าจะไม่ช่วย เลือก เปิด Windows Update แล้วดำเนินการทุกอย่างที่รออยู่ให้เสร็จ จากนั้นเลือก ลองอีกครั้ง หากไม่มีอะไรรออยู่ ให้เลือก ส่งรายงาน
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = การบำรุงรักษา Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = ไฟล์ที่รอการแทนที่
prepare-reason-update-agent = บริการ Windows Update
prepare-reason-unknown = ไม่ได้รายงานสาเหตุ
prepare-failed = เลือก ลองอีกครั้ง หากยังไม่สำเร็จ ให้ติดตั้งการอัปเดตที่เหลือใน Windows Update หรือ Microsoft Store ให้เสร็จ หรือเลือก ส่งรายงาน
prepare-failed-title = การอัปเดตบางรายการไม่เสร็จสมบูรณ์
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Try again" is common-try-again, the button beside it.
prepare-ended-unconfirmed = การอัปเดตหยุดลงก่อนรายงานผล Atlas จึงยืนยันไม่ได้ว่า Windows และแอปจาก Store เป็นเวอร์ชันล่าสุดแล้ว เลือก ลองอีกครั้ง เพื่อตรวจหาการอัปเดต
prepare-unconfirmed-title = ยืนยันผลการอัปเดตไม่ได้
# "Check and install updates" is prepare-start, its button in this state.
prepare-cancelled = หยุดการอัปเดตแล้ว การอัปเดตบางรายการอาจติดตั้งไปแล้ว เลือก ตรวจหาและติดตั้งการอัปเดต เพื่อให้เสร็จก่อนดำเนินการต่อ
prepare-windows-search = กำลังตรวจหาการอัปเดต Windows…
prepare-windows-download = กำลังดาวน์โหลดการอัปเดต Windows…
prepare-windows-install = กำลังติดตั้งการอัปเดต Windows…
prepare-store-search = กำลังตรวจสอบ Microsoft Store…
prepare-store-install = กำลังอัปเดต Microsoft Store และแอป…
prepare-stop-description = Atlas จะหยุดหลังจากขั้นตอนปัจจุบันเสร็จ เปิด Atlas ไว้จนถึงตอนนั้น
prepare-stop = หยุดอัปเดต
prepare-restart = รีสตาร์ตและดำเนินการต่อ
prepare-start = ตรวจหาและติดตั้งการอัปเดต
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = ใช้ไม่ได้เนื่องจากการติดตั้งนี้ดำเนินการต่อไม่ได้ ดูข้อความที่ด้านบนของหน้า
prepare-needs-build-check = ใช้ได้เมื่อรายการ { $check } ในการ์ด การตรวจสอบพีซี ผ่านแล้ว
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = ใช้ได้เมื่อไฟล์ติดตั้งพร้อมแล้ว
iso-username = ชื่อบัญชีภายในเครื่อง
iso-account-description = Windows จะสร้างบัญชีภายในเครื่องด้วยชื่อนี้ระหว่างการตั้งค่า คุณจึงไม่ต้องใช้บัญชี Microsoft และ Windows จะให้คุณตั้งรหัสผ่านเมื่อเข้าสู่ระบบครั้งแรก
iso-username-placeholder = ชื่อของคุณ
iso-account-empty = ป้อนชื่อบัญชีภายในเครื่องเพื่อดำเนินการต่อ
iso-account-invalid = ใช้ไม่เกิน 20 อักขระ โดยไม่มีช่องว่างที่ต้นหรือท้ายชื่อ และไม่มีอักขระต่อไปนี้: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = ชื่อต้องไม่ลงท้ายด้วยจุด (.)
iso-account-reserved = Windows ใช้ชื่อนี้สำหรับบัญชีที่มีมาในระบบ เลือกชื่ออื่น
iso-privacy-defaults = ISO นี้จะข้ามหน้าจอสัญญาอนุญาต บัญชี Microsoft และความเป็นส่วนตัวระหว่างการตั้งค่า Windows และปิดการแชร์ข้อมูลเพิ่มเติมและข้อเสนอเฉพาะบุคคล
prepare-drivers = ต้องการติดตั้งไดรเวอร์อย่างไร
prepare-drivers-auto = รับไดรเวอร์ผ่าน Windows Update
prepare-drivers-auto-detail = Windows จะค้นหาไดรเวอร์สำหรับฮาร์ดแวร์ของคุณ แนะนำสำหรับพีซีส่วนใหญ่
prepare-drivers-manual = ติดตั้งไดรเวอร์เอง
prepare-drivers-manual-detail = Windows Update จะไม่ติดตั้งไดรเวอร์ คุณจึงต้องหาไดรเวอร์จากผู้ผลิตพีซีหรืออุปกรณ์ของคุณเอง ไดรเวอร์ที่ติดตั้งไว้แล้วจะยังคงอยู่
prepare-drivers-description = ไดรเวอร์ช่วยให้ Windows ใช้งานฮาร์ดแวร์ของคุณได้ เช่น กราฟิก เสียง และ Wi-Fi หากคุณเปลี่ยนตัวเลือกนี้หลังอัปเดตแล้ว Atlas จะต้องตรวจหาการอัปเดตอีกครั้ง
prepare-network-needed = การอัปเดตต้องใช้การเชื่อมต่ออินเทอร์เน็ตที่ไม่คิดค่าบริการตามปริมาณข้อมูล เชื่อมต่อ Wi-Fi หรืออีเทอร์เน็ต แล้วเลือก ลองอีกครั้ง หากไม่เห็นเครือข่าย Wi-Fi ใด ๆ ให้ติดตั้งไดรเวอร์เครือข่ายก่อน
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows รายงานว่าเครือข่ายนี้ไม่มีการเข้าถึงอินเทอร์เน็ต หากเครือข่ายขอให้เข้าสู่ระบบ ให้เข้าสู่ระบบก่อน หรือตรวจสอบเราเตอร์และการกรองผ่าน DNS หรือไฟร์วอลล์ที่อาจมีอยู่ แล้วลองอีกครั้ง
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = การเชื่อมต่อนี้เป็นแบบคิดค่าบริการตามปริมาณข้อมูลหรือมีขีดจำกัดข้อมูล เชื่อมต่อเครือข่ายที่ไม่คิดค่าบริการตามปริมาณข้อมูล หรือปิด การเชื่อมต่อแบบคิดค่าบริการตามปริมาณข้อมูล ในการตั้งค่าเครือข่าย แล้วลองอีกครั้ง
prepare-network-settings = เปิดการตั้งค่าเครือข่าย
iso-target-title = ต้องการติดตั้ง Windows ใหม่บนพีซีเครื่องใด
iso-target-this = พีซีเครื่องนี้
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas สามารถเพิ่มไดรเวอร์ Wi-Fi และอีเทอร์เน็ตของพีซีเครื่องนี้ลงใน ISO เพื่อให้ Windows เชื่อมต่ออินเทอร์เน็ตได้ทันทีหลังติดตั้งใหม่
iso-target-other = พีซีเครื่องอื่น
iso-copy-network = รวมไดรเวอร์เครือข่ายของพีซีเครื่องนี้
iso-network-detail = นำไดรเวอร์ Wi-Fi และอีเทอร์เน็ตของพีซีเครื่องนี้ไปใช้ระหว่างติดตั้ง Windows หลังติดตั้งใหม่ คุณต้องเชื่อมต่อ Wi-Fi อีกครั้ง
iso-network-source = แหล่งที่มาของไดรเวอร์เครือข่าย
iso-network-installed = ใช้ไดรเวอร์ที่ติดตั้งไว้
iso-network-updated = ตรวจสอบ Windows Update ก่อน
iso-network-updated-detail = ดาวน์โหลดไดรเวอร์ที่ตรงกับฮาร์ดแวร์จาก Windows Update และเก็บไดรเวอร์ที่ติดตั้งไว้เป็นสำรอง ต้องใช้การเชื่อมต่อที่ไม่คิดค่าบริการตามปริมาณข้อมูล
iso-stage-network-drivers = กำลังเตรียมไดรเวอร์เครือข่าย
iso-network-failed = เตรียมไดรเวอร์เครือข่ายไม่ได้ ตรวจสอบข้อมูลการวินิจฉัย หรือย้อนกลับไปเปลี่ยนตัวเลือกไดรเวอร์เครือข่าย
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = อะแดปเตอร์เครือข่ายของพีซีเครื่องนี้ใช้ไดรเวอร์ที่มาพร้อมกับ Windows จึงไม่จำเป็นต้องรวมไดรเวอร์ไว้ใน ISO
iso-mode-desktop = ตั้งค่าให้เสร็จก่อนเข้าสู่เดสก์ท็อป
iso-mode-desktop-description = Atlas จะบันทึกตัวเลือกของคุณลงใน ISO หลังจากคุณเข้าสู่ระบบแล้ว Atlas จะอัปเดตและติดตั้งให้เสร็จก่อนที่เดสก์ท็อป Windows จะเปิดขึ้น
desktop-setup-description = ตั้งค่าพีซีให้เสร็จ ตัวเลือก Atlas ของคุณบันทึกไว้แล้ว หากจำเป็น คุณสามารถกลับไปที่ Windows ได้
desktop-setup-exit = ดำเนินการต่อใน Windows

# Windows installation USB (Beta)
usb-title = สร้าง USB ติดตั้ง Windows
usb-existing = สร้าง USB จาก ISO ที่มีอยู่
usb-description = นำ ISO ใส่ลงในไดรฟ์ USB เพื่อใช้ติดตั้ง Windows ใหม่ หากใช้ ISO ที่สร้างโดย Atlas จะติดตั้ง Atlas ไปพร้อมกันได้
usb-choose-iso = เลือก ISO
usb-drive = ไดรฟ์ USB
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = ไม่พบไดรฟ์ USB เชื่อมต่อไดรฟ์ USB ขนาดอย่างน้อย { $min } GB แล้วเลือก รีเฟรช ไดรฟ์ที่ใหญ่กว่า { $max } TB ไดรฟ์แบบอ่านอย่างเดียว และไดรฟ์ที่ Windows กำลังทำงานอยู่จะไม่แสดงในรายการ
usb-refresh = รีเฟรช
# Shown when the drive list could not be read.
usb-scan-failed = ตรวจดูว่าเชื่อมต่อไดรฟ์แล้ว จากนั้นเลือก รีเฟรช หากต้องการดูรายละเอียด ให้เลือก เปิดโฟลเดอร์บันทึก
usb-scan-failed-title = แสดงรายการไดรฟ์ USB ไม่ได้
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = หมายเลขซีเรียล: { $serial }
usb-detail-separator = { " · " }
usb-review = ตรวจทาน USB
usb-erase-title = ล้างข้อมูลในไดรฟ์ USB นี้หรือไม่
usb-erase-description = ข้อมูลทั้งหมดบน { $drive } ({ $size } GB) จะถูกลบอย่างถาวร รวมถึงไฟล์และพาร์ติชันทั้งหมด คัดลอกสิ่งที่ต้องการเก็บไว้ไปยังไดรฟ์อื่นก่อน ไฟล์ ISO ของคุณจะยังอยู่
usb-layout = Atlas ใช้พื้นที่ไดรฟ์สูงสุด 32 GB และปล่อยพื้นที่ที่เหลือไว้โดยไม่ใช้งาน ไดรฟ์ USB นี้ใช้ได้กับพีซีที่เริ่มทำงานในโหมด UEFI ซึ่ง Windows 11 กำหนดให้ต้องใช้
usb-ack = ฉันเข้าใจว่าข้อมูลทั้งหมดในไดรฟ์ USB นี้จะถูกลบ
usb-write = ล้างข้อมูลและสร้าง USB
usb-stage-prepare = กำลังเตรียมไฟล์ติดตั้ง…
usb-stage-format = กำลังฟอร์แมต USB…
usb-stage-copy = กำลังคัดลอกไฟล์ติดตั้ง…
usb-stage-verify = กำลังตรวจสอบ USB…
usb-working = เปิด Atlas ไว้และเสียบไดรฟ์ USB ไว้ หากคุณยกเลิก ไดรฟ์ USB ที่ยังสร้างไม่เสร็จจะใช้ติดตั้ง Windows ไม่ได้
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = สร้าง USB ไม่สำเร็จ
usb-complete-title = USB พร้อมใช้งานแล้ว
usb-close-title = ยังสร้าง USB อยู่
# After erasing may have begun.
usb-failed = ไดรฟ์อาจถูกล้างข้อมูลไปแล้ว จึงยังใช้ติดตั้ง Windows ไม่ได้ ตรวจดูให้แน่ใจว่าเชื่อมต่อไดรฟ์อยู่ แล้วเลือก ตรวจทาน USB เพื่อลองอีกครั้ง หากคุณถอดไดรฟ์แล้วเสียบกลับเข้าไป ให้เลือก รีเฟรช แล้วเลือกไดรฟ์นั้นอีกครั้งก่อน
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง เลือก เปิดโฟลเดอร์บันทึก เพื่อดูสาเหตุ แล้วเลือก ตรวจทาน USB เพื่อลองอีกครั้ง
usb-failed-iso = ใช้ ISO นี้สร้าง USB ติดตั้งไม่ได้ เลือก ISO ที่สร้างโดย Atlas หรือ ISO ของ Windows 11 จาก Microsoft ในเวอร์ชันที่ Atlas รองรับ ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-failed-location = ISO หรือ Atlas Manager อยู่ในไดรฟ์ USB นี้ ตำแหน่งบนเครือข่าย หรือโฟลเดอร์ที่ลิงก์ไว้ ย้ายไฟล์ไปยังโฟลเดอร์ในพีซีเครื่องนี้ แล้วลองอีกครั้ง ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-failed-space = พื้นที่ว่างในไดรฟ์ Windows ไม่พอสำหรับเตรียมไฟล์ติดตั้ง เพิ่มพื้นที่ว่าง แล้วลองอีกครั้ง ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-failed-fit = ไฟล์ติดตั้งมีขนาดใหญ่เกินกว่าที่ไดรฟ์ USB นี้จะรองรับได้ ใช้ไดรฟ์ที่มีขนาดใหญ่กว่า แล้วลองอีกครั้ง ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-failed-drive-changed = ไดรฟ์ USB ถูกถอดออก เสียบกลับใหม่ หรือถูกเปลี่ยนเป็นไดรฟ์อื่นหลังจากอ่านรายการแล้ว เลือก รีเฟรช แล้วเลือกไดรฟ์นั้นอีกครั้ง จากนั้นเลือก ตรวจทาน USB ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-cancelled = ไดรฟ์อาจมีไฟล์ติดตั้งที่ไม่สมบูรณ์ สร้าง USB ใหม่อีกครั้งก่อนนำไปใช้ติดตั้ง Windows
usb-cancelled-title = ยกเลิกการสร้าง USB แล้ว
usb-cancelled-unchanged = ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-complete = Atlas ตรวจสอบไฟล์ทุกไฟล์แล้ว เลือก นำ USB ออก แล้วสำรองไฟล์ในพีซีที่คุณต้องการติดตั้งใหม่ เสียบไดรฟ์เข้ากับพีซีเครื่องนั้น แล้วบูตจากไดรฟ์ USB ผ่านเมนูบูต (มักกด F12, F11 หรือ Esc ขณะพีซีเริ่มทำงาน)
usb-eject = นำ USB ออก
usb-ejected = ถอดไดรฟ์ USB ได้แล้ว สำรองไฟล์ในพีซีที่คุณต้องการติดตั้งใหม่ จากนั้นบูตพีซีเครื่องนั้นจากไดรฟ์ USB ผ่านเมนูบูต (มักกด F12, F11 หรือ Esc ขณะพีซีเริ่มทำงาน)
usb-eject-failed = ปิดไฟล์หรือหน้าต่างที่กำลังใช้ไดรฟ์นี้ แล้วลองอีกครั้ง
usb-eject-failed-title = นำ USB ออกไม่ได้
ready-fresh-title = Atlas สร้างมาสำหรับ Windows ที่ติดตั้งใหม่ทั้งหมด
ready-fresh-description = หากคุณใช้ Windows บนพีซีเครื่องนี้มาสักระยะแล้ว ให้สำรองไฟล์และติดตั้ง Windows ใหม่ก่อนดำเนินการต่อ แต่ก่อนอื่นให้ตรวจดูว่ารายการ ความเข้ากันได้กับ Windows ในการ์ด การตรวจสอบพีซี ผ่านแล้ว เพื่อให้แน่ใจว่าคุณจะติดตั้ง Windows เวอร์ชันที่รองรับ
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = ไม่รองรับ Windows 11 รุ่น Home, LTSC และ Server ให้ใช้รุ่นอื่น เช่น Pro, Education หรือ Enterprise หาก Windows ระบุรุ่นของคุณไม่ได้ ให้แก้ไขปัญหานี้ก่อนดำเนินการต่อ
install-source-title = ไม่สามารถติดตั้งได้
install-source-unsupported = อัปเดต Atlas { $source } เป็น { $target } โดยตรงไม่ได้ หากต้องการใช้เวอร์ชันนี้ ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = อัปเดต Atlas { $source } โดยตรงไม่ได้ หากต้องการใช้เวอร์ชันที่ใหม่กว่า ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่
# "Open package file" is package-open-file. $folder is a folder path (text).
install-source-resume = การติดตั้ง Atlas { $target } ยังไม่เสร็จ และมีเพียงแพ็กเกจ Atlas { $target } เท่านั้นที่ติดตั้งต่อให้เสร็จได้ เลือก เปิดไฟล์แพ็กเกจ แล้วเลือกแพ็กเกจ Atlas นั้น (.apbx) หาก Atlas ดาวน์โหลดไว้ ไฟล์จะอยู่ใน { $folder }
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = การติดตั้ง Atlas { $target } ยังไม่เสร็จ รุ่นทดสอบนี้ติดตั้งได้เฉพาะแพ็กเกจ Atlas ที่มาพร้อมกัน จึงต้องติดตั้งให้เสร็จด้วยแพ็กเกจ Atlas { $target } ใน Atlas Manager รุ่นเผยแพร่
install-source-unknown = Atlas ยืนยันไม่ได้ว่ามีอะไรติดตั้งอยู่แล้วบนพีซีเครื่องนี้ จึงจะยังไม่ติดตั้งสิ่งใดในตอนนี้ เลือก ส่งรายงาน เพื่อให้ทีม Atlas ช่วยเหลือ
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } รายละเอียด: { $error }
iso-edition-selection = มีเฉพาะรุ่นที่รองรับเท่านั้น ระหว่างติดตั้ง Windows ให้เลือกรุ่นที่คุณมีสิทธิ์การใช้งาน Windows
detail-windows-preview = ไม่รองรับบิลด์ Insider ให้ใช้ Windows 11 รุ่นที่เผยแพร่ทั่วไป
detail-windows-release-unknown = Atlas ยืนยันไม่ได้ว่าบิลด์ Windows นี้เป็นรุ่นที่เผยแพร่ทั่วไป เชื่อมต่ออินเทอร์เน็ต แล้วตรวจสอบอีกครั้ง
iso-release-unknown = Atlas ยืนยันไม่ได้ว่า ISO นี้เป็น Windows 11 รุ่นที่เผยแพร่ทั่วไปซึ่งแพ็กเกจ Atlas รองรับ เชื่อมต่ออินเทอร์เน็ต แล้วเลือก ตรวจสอบไฟล์ อีกครั้ง หากยังไม่สำเร็จ ให้ดาวน์โหลด ISO จาก Microsoft ใหม่
prepare-previous-worker = การอัปเดตที่เริ่มไว้ก่อนหน้านี้ยังทำงานอยู่ Atlas จะรอให้เสร็จ แล้วคุณจึงตรวจหาการอัปเดตอีกครั้งได้

ready-used-windows-title = Windows บนพีซีเครื่องนี้ดูเหมือนเคยใช้งานมาแล้ว
ready-used-windows-description = Windows บนพีซีเครื่องนี้ติดตั้งมาแล้วอย่างน้อยหนึ่งสัปดาห์ หรือมีแอปติดตั้งอยู่หลายแอปแล้ว การติดตั้ง Atlas ที่นี่ไม่ได้รับการสนับสนุนและไม่แนะนำอย่างยิ่ง เพราะแอปและการตั้งค่าที่คุณมีอยู่อาจทำงานไม่เป็นไปตามที่คาดไว้ และ Atlas จะนำ OneDrive ออก ไฟล์ใน OneDrive จึงจะหยุดซิงค์ และโฟลเดอร์ เดสก์ท็อป เอกสาร และ รูปภาพ ของคุณอาจดูเหมือนว่างเปล่า สำรองไฟล์ของคุณและติดตั้ง Windows ใหม่ก่อน หรือดำเนินการต่อเฉพาะเมื่อคุณยอมรับความเสี่ยงนี้
ready-used-windows-dismiss = ยังคงดำเนินการต่อ

prepare-resumed = พีซีของคุณรีสตาร์ตแล้ว และ Atlas คืนค่าตัวเลือกที่คุณเลือกไว้จนถึงตอนนี้แล้ว เลือก อัปเดตต่อ เพื่ออัปเดตให้เสร็จก่อนติดตั้ง Atlas
prepare-continue = อัปเดตต่อ
prepare-saving-restart = กำลังบันทึกตัวเลือกของคุณและตั้งค่าให้ Atlas เปิดขึ้นอีกครั้งหลังจาก Windows รีสตาร์ต…
prepare-restart-save-failed = บันทึกตัวเลือกของคุณไม่ได้ ลองอีกครั้งก่อนรีสตาร์ต
prepare-restart-registration-failed = ตัวเลือกของคุณบันทึกไว้แล้ว แต่ Atlas ตั้งค่าให้เปิดขึ้นอีกครั้งหลังรีสตาร์ตไม่ได้ ลองอีกครั้ง หรือรีสตาร์ตพีซีด้วยตนเองแล้วเปิด Atlas หลังจากเข้าสู่ระบบ
prepare-restart-failed = Atlas รีสตาร์ตพีซีของคุณไม่ได้ ลองอีกครั้ง หรือรีสตาร์ตจากเมนูเริ่ม ตัวเลือกของคุณบันทึกไว้แล้ว และ Atlas จะเปิดขึ้นอีกครั้งหลังจากคุณเข้าสู่ระบบ
diagnostics-export = ส่งออกข้อมูลการวินิจฉัย
diagnostics-exporting = กำลังรวบรวมข้อมูลการวินิจฉัย…
diagnostics-privacy = ส่งรายงานถึงทีม Atlas แบบส่วนตัว หรือส่งออกไฟล์ ZIP ข้อมูลการวินิจฉัยเพื่อแชร์เมื่อขอความช่วยเหลือ Atlas จะลบชื่อผู้ใช้ ชื่อพีซี และที่อยู่อีเมลของคุณออกจากไฟล์นี้
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = สร้างไฟล์ ZIP ข้อมูลการวินิจฉัยแล้ว
diagnostics-failed-title = ส่งออกข้อมูลการวินิจฉัยไม่ได้
# $error is the raw error (text).
diagnostics-failed = ตรวจดูว่าพีซีของคุณมีพื้นที่ดิสก์ว่างเพียงพอ แล้วลองอีกครั้ง รายละเอียด: { $error }

## Tester builds (embedded-playbook feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } รุ่นทดสอบ แอปนี้ติดตั้งเฉพาะแพ็กเกจ Atlas ที่มาพร้อมกันเท่านั้น
home-status-bundled = รุ่นทดสอบ { $release }
package-bundled = Atlas { $version } ที่มาพร้อมรุ่นทดสอบนี้พร้อมติดตั้งแล้ว
rc-about-release = รุ่นทดสอบ
rc-about-commit = คอมมิตต้นทาง
rc-about-package = แพ็กเกจ Atlas ที่มาพร้อมกัน (SHA-256)
iso-package-bundled = แพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้
prepare-percent = ขั้นตอนนี้เสร็จแล้ว { $percent }%
prepare-count = การอัปเดตที่เสร็จแล้ว: { $completed } จาก { $total }
prepare-bytes = ดาวน์โหลดแล้ว { $downloaded } จากประมาณ { $total } MB
prepare-elapsed = เวลาที่ผ่านไป: { $minutes } นาที { $seconds } วินาที
prepare-progress-waiting = กำลังรอบริการอัปเดต ไม่มีข้อมูลเปอร์เซ็นต์สำหรับขั้นตอนนี้
prepare-progress-unchanged = ไม่มีความคืบหน้ามา { $minutes } นาที การอัปเดตขนาดใหญ่อาจใช้เวลานาน จึงควรเปิด Atlas ไว้ หากต้องการดูรายละเอียด ให้เลือก เปิดโฟลเดอร์บันทึก
prepare-report-delayed = Windows ไม่ได้รายงานความคืบหน้ามา { $seconds } วินาที การอัปเดตอาจยังทำงานอยู่ จึงควรเปิด Atlas ไว้

prepare-affected-app = แอปที่มีปัญหา
prepare-app-in-use = ปิด { $app } แล้วลองอีกครั้ง Windows อัปเดตแอปนี้ไม่ได้ขณะที่แอปเปิดอยู่ หากไม่พบหน้าต่างของแอป ให้ปิดแอปในตัวจัดการงาน หากยังไม่สำเร็จ ให้รีสตาร์ตพีซีแล้วลองอีกครั้งก่อนเปิด { $app }
prepare-install-busy = การติดตั้งอื่นหรือการรีสตาร์ตที่จำเป็นกำลังขัดขวางการอัปเดต รอให้การติดตั้งอื่นเสร็จ รีสตาร์ตพีซีหาก Windows ขอให้รีสตาร์ต แล้วลองอีกครั้ง
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas กำลังทำงานด้วยบัญชีอื่นที่ไม่ใช่บัญชีที่เข้าสู่ระบบ Windows อยู่ เข้าสู่ระบบ Windows ด้วยบัญชีผู้ดูแลระบบ แล้วเปิด Atlas จากบัญชีนั้น จากนั้นลองอีกครั้ง
prepare-failed-store-missing = Microsoft Store ยังไม่ได้ตั้งค่าสำหรับบัญชีของคุณ เปิด Microsoft Store สักครั้ง หรือติดตั้งใหม่หากไม่มีแอปนี้ แล้วลองอีกครั้ง
prepare-failed-store-battery = Microsoft Store หยุดการอัปเดตไว้ชั่วคราวเพื่อประหยัดแบตเตอรี่ เสียบปลั๊กพีซีของคุณ แล้วลองอีกครั้ง
prepare-failed-store-network = Microsoft Store หยุดการอัปเดตไว้ชั่วคราวจนกว่าพีซีของคุณจะใช้การเชื่อมต่อที่ไม่คิดค่าบริการตามปริมาณข้อมูล เชื่อมต่อ Wi-Fi หรืออีเทอร์เน็ตที่ไม่คิดค่าบริการตามปริมาณข้อมูล แล้วลองอีกครั้ง
prepare-failed-store-timeout = แอปจาก Store ยังอัปเดตไม่เสร็จ ดาวน์โหลดรายการที่เหลือใน Microsoft Store ให้เสร็จ แล้วลองอีกครั้ง
prepare-failed-store-passes = Microsoft Store ยังมีการอัปเดตใหม่เข้ามาเรื่อย ๆ ติดตั้งการอัปเดตที่เหลือใน Microsoft Store ให้เสร็จ แล้วลองอีกครั้ง
prepare-failed-manual-updates = การอัปเดต Windows บางรายการต้องติดตั้งให้เสร็จใน Windows Update เปิด Windows Update แล้วติดตั้งการอัปเดตเหล่านั้นให้เสร็จ จากนั้นลองอีกครั้ง
prepare-failed-windows-passes = Windows Update ยังมีการอัปเดตใหม่เข้ามาเรื่อย ๆ ติดตั้งการอัปเดตที่เหลือใน Windows Update ให้เสร็จ แล้วลองอีกครั้ง
prepare-error-code = รหัสข้อผิดพลาด: { $code }
prepare-open-store = เปิด Microsoft Store

check-user-account = บัญชีผู้ใช้
detail-user-account-ok = เปิดใช้งาน UAC แล้ว และบัญชีของคุณพร้อมสำหรับการติดตั้ง
detail-user-account-not-ready = เปิดการควบคุมบัญชีผู้ใช้ (UAC) รีสตาร์ตพีซี แล้วลองอีกครั้ง หากคุณใช้บัญชี Administrator ที่มีมาในระบบ ให้เข้าสู่ระบบด้วยบัญชีผู้ดูแลระบบอื่น
detail-user-account-unknown = Atlas ตรวจสอบบัญชีผู้ใช้ของคุณไม่ได้ ตรวจสอบอีกครั้งก่อนติดตั้ง รายละเอียดจาก Windows: { $error }

footer-prepare-required = อัปเดต Windows และแอปจาก Store ให้เสร็จเพื่อดำเนินการต่อ
footer-prepare-stopping = กำลังจะหยุดอัปเดตหลังจากขั้นตอนปัจจุบันเสร็จ…
resume-choices-title = ดำเนินการติดตั้งครั้งก่อนต่อ
resume-choices-detail = Atlas คืนค่าตัวเลือกที่คุณเลือกไว้ครั้งก่อนเพื่อติดตั้งให้เสร็จ คุณจะเปลี่ยนตัวเลือกเหล่านี้ใน ตัวเลือกของคุณ ไม่ได้จนกว่าการติดตั้งจะเสร็จ

## Voluntary reports
report-title = ส่งรายงาน
report-received = ได้รับรายงานแล้ว
report-reference = เก็บหมายเลขอ้างอิงนี้ไว้หากคุณติดต่อทีม Atlas เกี่ยวกับรายงานนี้ หากคุณให้ข้อมูลติดต่อไว้ ทีมอาจใช้ข้อมูลนั้นเพื่อตอบกลับ แต่ไม่รับประกันว่าจะได้รับการตอบกลับ
# Accessible name of the Copy button beside the report reference.
report-copy-reference = คัดลอกหมายเลขอ้างอิงของรายงาน
report-another = ส่งรายงานอีกฉบับ
# Label of the choice between the two kinds of report.
report-kind = คุณต้องการส่งอะไร
report-kind-issue = ปัญหา
report-kind-suggestion = ข้อเสนอแนะ
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = อธิบายสิ่งที่เกิดขึ้นหรือสิ่งที่คุณอยากให้เปลี่ยน ({ $min }–{ $max } ตัวอักษร) อย่าใส่รหัสผ่านในข้อความ
report-message = ข้อความของคุณ
report-message-placeholder = ฉันกำลังพยายาม…
report-contact = ข้อมูลติดต่อ (ไม่บังคับ)
report-contact-placeholder = อีเมลหรือชื่อผู้ใช้ Discord
report-attach = แนบข้อมูลการวินิจฉัย
report-attach-description = ไฟล์บันทึกและรายละเอียดระบบที่ช่วยหาสาเหตุ Atlas จะลบชื่อผู้ใช้ ชื่อพีซี ที่อยู่อีเมล และรหัสผ่านหรือคีย์ที่ตรวจพบได้ออก แต่จะเก็บรายละเอียดข้อผิดพลาด รุ่นฮาร์ดแวร์ และชื่อแอปไว้ คุณตรวจสอบไฟล์ ZIP ได้ก่อนส่ง
report-prepare = เตรียมข้อมูลการวินิจฉัย
report-review = ตรวจสอบ ZIP
report-prepare-failed-title = เตรียมข้อมูลการวินิจฉัยไม่ได้
# $error is a raw error message (text).
report-prepare-failed = เตรียมข้อมูลการวินิจฉัยอีกครั้ง หรือยกเลิกการเลือก แนบข้อมูลการวินิจฉัย เพื่อส่งรายงานโดยไม่แนบข้อมูลนี้ รายละเอียด: { $error }
report-privacy = รายงานของคุณจะส่งถึงทีม Atlas แบบส่วนตัวที่ reports.atlasos.net โดยข้อความและข้อมูลติดต่อของคุณจะถูกส่งไปตามที่เขียนไว้ ทีมอาจใช้บริการ AI ของบริษัทอื่นเพื่อช่วยตรวจสอบปัญหา บริการเหล่านี้จะได้รับข้อความและข้อมูลการวินิจฉัยของคุณ แต่จะไม่ได้รับข้อมูลติดต่อของคุณ รายงานจะถูกลบหลังจาก 90 วัน และบันทึกความปลอดภัยของเซิร์ฟเวอร์อาจเก็บที่อยู่ IP ของคุณไว้
report-website = ความเป็นส่วนตัวและเว็บไซต์รายงาน
report-consent = ฉันยินยอมส่งรายงานนี้และข้อมูลการวินิจฉัยที่แนบมาไปยังทีม Atlas
report-failed = ข้อความของคุณยังอยู่ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วเลือก ลองอีกครั้ง หรือส่งรายงานจากเว็บไซต์รายงาน
report-failed-busy = บริการรายงานไม่ว่างในขณะนี้ ข้อความของคุณยังอยู่ ลองอีกครั้งในภายหลัง
report-failed-outdated = Atlas Manager เวอร์ชันนี้ส่งรายงานไม่ได้อีกต่อไป ข้อความของคุณยังอยู่ ให้คัดลอกไปวางในเว็บไซต์รายงาน หากคุณแนบข้อมูลการวินิจฉัยไว้ ให้เลือก ตรวจสอบ ZIP แล้วแนบไฟล์ ZIP ในเว็บไซต์นั้นด้วย
report-failed-diagnostics = ส่งข้อมูลการวินิจฉัยที่เตรียมไว้ไม่ได้ ข้อความของคุณยังอยู่ เตรียมข้อมูลการวินิจฉัยอีกครั้ง หรือยกเลิกการเลือก แนบข้อมูลการวินิจฉัย
# Link under a report that wasn't sent.
report-failed-website = เปิดเว็บไซต์รายงาน
report-sending = กำลังส่ง…
report-send = ส่งรายงาน

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = กรอกข้อความ { $min }–{ $max } ตัวอักษร

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = จำกัดข้อมูลติดต่อไว้ไม่เกิน { $max } ตัวอักษร

report-validation-consent = ยืนยันว่าคุณยินยอมส่งรายงานนี้

report-failed-title = ยังไม่ได้ส่งรายงาน

## Windows version update
# Home, under the update button, when the update also moves Windows.
home-plan-intro = การอัปเดตนี้มีสองส่วน ไฟล์และแอปของคุณจะยังอยู่ หากการอัปเดต Windows ทำให้การเปลี่ยนแปลงใด ๆ ของ Atlas หายไป Atlas จะนำการเปลี่ยนแปลงเหล่านั้นกลับมา
home-plan-windows-title = Windows 11 เวอร์ชัน { $release }
home-plan-windows-detail = Atlas จะติดตั้งเวอร์ชันนี้จาก Windows Update และพีซีของคุณจะรีสตาร์ตเพื่อติดตั้งให้เสร็จ
# The same step where moving is optional.
home-plan-windows-optional = แนะนำ Atlas จะติดตั้งเวอร์ชันนี้จาก Windows Update และพีซีของคุณจะรีสตาร์ตเพื่อติดตั้งให้เสร็จ
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas จะอัปเดตไฟล์ของตัวเองและคงตัวเลือกที่คุณเลือกไว้ พีซีของคุณจะรีสตาร์ตในตอนท้าย
# $date and $until are dates.
home-end-of-updates-title = Windows 11 เวอร์ชัน { $current } จะหยุดรับการอัปเดตความปลอดภัยในวันที่ { $date }
home-end-of-updates-past-title = Windows 11 เวอร์ชัน { $current } ไม่ได้รับการอัปเดตความปลอดภัยอีกต่อไป
home-end-of-updates-message = การอัปเดตเป็น Atlas { $version } จะอัปเดตพีซีเครื่องนี้เป็น Windows 11 เวอร์ชัน { $release } ด้วย ซึ่งจะได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $until }
# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition = Atlas { $version } ใช้ได้กับ Windows 11 Pro, Enterprise และ Education แต่พีซีเครื่องนี้ใช้ { $product } Atlas จึงติดตั้งบนพีซีเครื่องนี้ไม่ได้
# The same, on a version whose security updates end. $date is a date.
install-windows-edition-ending = Atlas { $version } ใช้ได้กับ Windows 11 Pro, Enterprise และ Education แต่พีซีเครื่องนี้ใช้ { $product } Atlas จึงติดตั้งบนพีซีเครื่องนี้ไม่ได้ Windows 11 เวอร์ชัน { $current } จะหยุดรับการอัปเดตความปลอดภัยในวันที่ { $date } Windows Update อัปเดตพีซีเครื่องนี้เป็นเวอร์ชันที่ใหม่กว่าได้
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-no-path = Atlas { $version } ต้องใช้ Windows 11 เวอร์ชัน { $releases } แต่ Windows Update อัปเดตพีซีเครื่องนี้จาก Windows ที่มีอยู่ไปเป็นเวอร์ชันนั้นไม่ได้ หากต้องการใช้ Atlas { $version } ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่ด้วย ISO พร้อม Atlas
# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
home-update-access-title = การตั้งค่า Windows Update ถูกเปลี่ยนไว้สำหรับการอัปเดต Atlas
# When the last check found no offer yet.
home-update-access-not-offered = Atlas เปิด Windows Update เพื่ออัปเดตพีซีเครื่องนี้เป็น Windows 11 เวอร์ชัน { $release } แต่ Windows Update ยังไม่ได้เสนอเวอร์ชันนี้ เลือก ตรวจสอบอีกครั้ง หรือ คืนค่าการตั้งค่า
home-update-access-before = Atlas เปิด Windows Update เพื่ออัปเดตพีซีเครื่องนี้เป็น Windows 11 เวอร์ชัน { $release } แต่ยังอัปเดตไม่เสร็จ อัปเดตต่อให้เสร็จ หรือเลือก คืนค่าการตั้งค่า
home-update-access-after = พีซีเครื่องนี้ใช้ Windows 11 เวอร์ชัน { $release } แล้ว ติดตั้ง Atlas ให้เสร็จ หรือเลือก คืนค่าการตั้งค่า
home-update-access-plain = Atlas เปิด Windows Update เพื่อติดตั้งการอัปเดต แต่ยังอัปเดตไม่เสร็จ อัปเดตต่อให้เสร็จ หรือเลือก คืนค่าการตั้งค่า
home-update-access-unreadable = Atlas อ่านบันทึกการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ไม่ได้ จึงจะไม่เปลี่ยนแปลงหรือคืนค่าสิ่งใด เลือก ส่งรายงาน เพื่อให้ทีม Atlas ช่วยเหลือ
# $error is the raw error.
home-update-access-failed = Atlas คืนค่าการตั้งค่าไม่ได้ ลองอีกครั้ง หรือเลือก ส่งรายงาน รายละเอียด: { $error }
home-update-access-install-active = ติดตั้ง Atlas ให้เสร็จก่อน ขั้นตอนสุดท้ายของการติดตั้งจะคืนค่าการตั้งค่าเหล่านี้
home-continue-update = ดำเนินการอัปเดตต่อ
home-put-back = คืนค่าการตั้งค่า
home-putting-back = กำลังคืนค่าการตั้งค่า…
# Get ready: the Windows version card.
windows-card-title = Windows 11 เวอร์ชัน { $release }
windows-card-required = Atlas { $version } ต้องใช้ Windows เวอร์ชันที่ใหม่กว่า เมื่อ Atlas อัปเดต Windows ด้านล่าง Atlas จะติดตั้ง Windows 11 เวอร์ชัน { $release } จาก Windows Update ด้วย
windows-card-question = พีซีเครื่องนี้ควรใช้ Windows เวอร์ชันใด
windows-choice-move = อัปเดตเป็น Windows 11 เวอร์ชัน { $release }
# $date is when the new version stops getting security updates.
windows-choice-move-detail = แนะนำ ได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $date } และต้องรีสตาร์ตเพิ่มอีกหนึ่งครั้ง
windows-choice-keep = คงไว้ที่ Windows 11 เวอร์ชัน { $current }
windows-choice-keep-detail = พีซีของคุณจะใช้เวอร์ชันนี้ต่อไป Windows Update จะไม่อัปเดตพีซีเป็นเวอร์ชันที่ใหม่กว่า หากต้องการเปลี่ยนเวอร์ชันภายหลังจึงต้องอัปเดตอีกครั้งใน Atlas Manager
windows-card-facts = สิ่งที่จะเปลี่ยนแปลง
windows-fact-keep = ไฟล์และแอปของคุณจะยังอยู่ หากการอัปเดตทำให้การเปลี่ยนแปลงใด ๆ ของ Atlas หายไป Atlas จะนำการเปลี่ยนแปลงเหล่านั้นกลับมาเมื่อติดตั้ง
windows-fact-restart = พีซีของคุณจะรีสตาร์ตอีกอย่างน้อยหนึ่งครั้งเพื่อให้การอัปเดตเสร็จสมบูรณ์
# Also after home-plan-windows-detail on Home, and among the 26H2 card's facts: how long Windows Update can take to offer the new version, which Atlas waits for by itself.
transition-offer-expectation = โดยปกติ Windows Update จะเสนอเวอร์ชันนี้ภายในไม่กี่นาที แต่อาจใช้เวลานานถึง 2 ชั่วโมง Atlas จะรอและตรวจสอบให้คุณ
windows-fact-stays = หลังจากนั้น Windows จะคงอยู่ที่เวอร์ชัน { $release } และจะไม่อัปเดตเป็นเวอร์ชันที่ใหม่กว่าเอง
windows-fact-removed = เวอร์ชัน { $release } ไม่มีทั้ง Windows PowerShell 2.0 และเครื่องมือ WMIC
# How to undo the move: Windows may switch the new version on in place, which Update history
# can uninstall, or reinstall itself, which Go back undoes for 10 days. Update history, Go back,
# Recovery and System are Windows' own labels; use them as your language's Windows shows them.
windows-card-undo = หากต้องการย้อนการอัปเดตนี้ในภายหลัง ให้ถอนการติดตั้งการอัปเดตจาก ประวัติการอัปเดต ใน Windows Update แต่หาก Windows ติดตั้งตัวเองใหม่เพื่ออัปเดต ให้เลือก ย้อนกลับ ในหน้า การกู้คืน ของการตั้งค่า ระบบ แทน โดยต้องทำภายใน 10 วัน Atlas { $version } ไม่รองรับเวอร์ชัน { $current } จึงอย่าย้อนการอัปเดตนี้หลังจากติดตั้ง Atlas { $version } แล้ว
windows-card-undo-optional = หากต้องการย้อนการอัปเดตนี้ในภายหลัง ให้ถอนการติดตั้งการอัปเดตจาก ประวัติการอัปเดต ใน Windows Update แต่หาก Windows ติดตั้งตัวเองใหม่เพื่ออัปเดต ให้เลือก ย้อนกลับ ในหน้า การกู้คืน ของการตั้งค่า ระบบ แทน โดยต้องทำภายใน 10 วัน
windows-terms = ฉันยอมรับข้อกำหนดสิทธิ์การใช้งานซอฟต์แวร์ของ Microsoft สำหรับ Windows 11 เวอร์ชัน { $release }
windows-terms-link = อ่านข้อกำหนดสิทธิ์การใช้งาน
# Cancel is the flow's own button (common-cancel); Stop updating confirms it (prepare-stop).
windows-card-locked = หากต้องการคงไว้ที่เวอร์ชัน { $current } ให้เลือก ยกเลิก แล้วเลือก หยุดอัปเดต
# Get ready: the update card while Windows moves.
prepare-description-transition = ก่อนติดตั้ง Atlas จะติดตั้งการอัปเดตที่ Windows รอติดตั้งอยู่ จากนั้นติดตั้ง Windows 11 เวอร์ชัน { $release } แล้วอัปเดต Microsoft Store และแอปจาก Store ของคุณ แอปจาก Store ที่คุณเปิดอยู่อาจปิดลงระหว่างอัปเดต จึงควรบันทึกงานในแอปเหล่านั้นก่อน และพีซีของคุณจะรีสตาร์ตอย่างน้อยหนึ่งครั้ง
prepare-start-transition = อัปเดต Windows เป็นเวอร์ชัน { $release }
prepare-needs-terms = ใช้ได้เมื่อคุณยอมรับข้อกำหนดสิทธิ์การใช้งานในการ์ด Windows 11 เวอร์ชัน { $release }
ready-banner-not-offered-message = ดูสิ่งที่คุณทำได้ตอนนี้ในการ์ด อัปเดต Windows และแอปจาก Store
ready-banner-transition-failed-message = ดูสิ่งที่ต้องทำต่อในการ์ด อัปเดต Windows และแอปจาก Store
ready-banner-terms-title = ยอมรับข้อกำหนดสิทธิ์การใช้งานเพื่อดำเนินการต่อ
ready-banner-terms-message = ข้อกำหนดอยู่ในการ์ด Windows 11 เวอร์ชัน { $release } ด้านล่างของหน้านี้ จากนั้นเลือก อัปเดต Windows เป็นเวอร์ชัน { $release }
# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas จะเปิด Windows Update ไว้ชั่วคราว
access-off = Windows Update ปิดอยู่บนพีซีเครื่องนี้ Atlas จะเปิดอีกครั้งระหว่างอัปเดต Windows
access-paused = การอัปเดต Windows ถูกหยุดชั่วคราวอยู่บนพีซีเครื่องนี้ Atlas จะยกเลิกการหยุดชั่วคราวระหว่างอัปเดต Windows
access-delayed = การอัปเดตรายเดือนถูกเลื่อนออกไปบนพีซีเครื่องนี้ Atlas จะยกเลิกการเลื่อนระหว่างอัปเดต Windows
# After the lines above. "As you chose" applies when an Atlas setting the user chose set them.
access-back-chosen = เมื่อติดตั้ง Atlas { $version } แล้ว การตั้งค่าเหล่านี้จะกลับไปเป็นตามที่คุณเลือกไว้
access-back = เมื่อติดตั้ง Atlas { $version } แล้ว การตั้งค่าเหล่านี้จะกลับไปเป็นเหมือนเดิม
access-back-stop = หากคุณหยุดก่อนถึงตอนนั้น Atlas จะคืนค่าการตั้งค่าเหล่านี้ให้
# The restart that finishes the new version.
prepare-reboot-transition = Windows 11 เวอร์ชัน { $release } ติดตั้งแล้ว เลือก รีสตาร์ตและดำเนินการต่อ เพื่อติดตั้งให้เสร็จ Atlas จะเปิดขึ้นอีกครั้งหลังจากคุณเข้าสู่ระบบ
prepare-reboot-commit = Windows ต้องรีสตาร์ตอีกหนึ่งครั้งเพื่อติดตั้งเวอร์ชัน { $release } ให้เสร็จ Atlas จะเปิดขึ้นอีกครั้งหลังจากคุณเข้าสู่ระบบ
prepare-restart-commit-failed = Windows เตรียมเวอร์ชัน { $release } ให้พร้อมติดตั้งต่อตอนรีสตาร์ตไม่ได้ พีซีของคุณจึงไม่ได้รีสตาร์ต เลือก รีสตาร์ตและดำเนินการต่อ เพื่อลองอีกครั้ง
prepare-reason-feature-update = Windows เวอร์ชันใหม่
prepare-reason-feature-commit = การติดตั้ง Windows เวอร์ชันใหม่ให้เสร็จ
prepare-resumed-transition = พีซีของคุณรีสตาร์ตแล้ว เลือก อัปเดตต่อ เพื่อให้ Atlas ตรวจสอบว่า Windows 11 เวอร์ชัน { $release } ติดตั้งเสร็จแล้ว และติดตั้งการอัปเดตที่เหลืออยู่
# Under the progress bar while Windows Update has yet to offer the new version.
prepare-waiting-offer = กำลังรอให้ Windows Update เสนอ Windows 11 เวอร์ชัน { $release } โดยปกติจะใช้เวลาไม่กี่นาที แต่อาจนานถึง 2 ชั่วโมง คุณใช้พีซีต่อไปได้ แต่ให้เปิด Atlas ไว้
# After a restart for the updates Windows installs before the new version.
prepare-resumed-before-move = พีซีของคุณรีสตาร์ตเพื่อติดตั้งการอัปเดตให้เสร็จแล้ว เลือก อัปเดตต่อ เพื่อให้ Atlas ติดตั้งการอัปเดตที่เหลืออยู่ แล้วจึงติดตั้ง Windows 11 เวอร์ชัน { $release }
# Outcomes of moving Windows. Each says what changed and what to do next.
prepare-not-offered-title = กำลังรอให้ Windows Update เสนอ Windows 11 เวอร์ชัน { $release }
prepare-transition-failed-title = Windows อัปเดตเป็นเวอร์ชัน { $release } ไม่ได้
prepare-failed-feature-not-offered = Windows Update อาจใช้เวลาสักพักกว่าจะเสนอ Windows 11 เวอร์ชัน { $release } ให้กับพีซี พีซีของคุณยังใช้เวอร์ชัน { $current } อยู่
# Added after the message above while Atlas looks again by itself.
prepare-offer-rechecking = Atlas จะตรวจสอบอีกครั้งทุก 10 นาที และดำเนินการต่อเองทันทีที่ Windows Update เสนอเวอร์ชันนี้ หรือคุณจะเลือก ตรวจสอบอีกครั้ง ก็ได้
# Under the progress bar while Atlas waits, updated as time passes: how long it has waited, then when it looks again, or that it's looking now. Shown together on one line. Thai has one plural category.
prepare-offer-waited =
    { $minutes ->
       *[other] รอมาแล้ว { $minutes } นาที
    }
prepare-offer-next-check =
    { $minutes ->
       *[other] จะตรวจสอบอีกครั้งในอีก { $minutes } นาที
    }
prepare-offer-checking-now = กำลังตรวจสอบ
# Added instead while Atlas isn't looking again by itself.
prepare-offer-check-again = เลือก ตรวจสอบอีกครั้ง เพื่อตรวจสอบตอนนี้
# After 2 hours of looking again without an offer.
prepare-offer-wait-ended-title = Windows Update ยังไม่ได้เสนอ Windows 11 เวอร์ชัน { $release }
prepare-offer-wait-ended = Windows Update ไม่ได้เสนอ Windows 11 เวอร์ชัน { $release } ภายใน 2 ชั่วโมง Atlas จึงหยุดรอและคืนค่าการตั้งค่า Windows Update ของคุณแล้ว เลือก ตรวจสอบอีกครั้ง ในภายหลัง หากรอไม่ได้ ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่ด้วย ISO พร้อม Atlas
# Instead of prepare-offer-wait-ended when putting the settings back at the end of the wait failed. $error is the raw error.
prepare-offer-wait-put-back-failed = Windows Update ไม่ได้เสนอ Windows 11 เวอร์ชัน { $release } ภายใน 2 ชั่วโมง และ Atlas คืนค่าการตั้งค่า Windows Update ของคุณไม่ได้ เลือก คืนค่าการตั้งค่า เพื่อลองอีกครั้ง รายละเอียด: { $error }
# $missing lists the hardware this PC lacks, from the two messages below.
prepare-failed-feature-hardware = พีซีเครื่องนี้ไม่ตรงตามข้อกำหนดฮาร์ดแวร์ของ Windows 11 ({ $missing }) Windows Update จึงจะไม่อัปเดตพีซีเป็นเวอร์ชัน { $release } พีซีของคุณยังใช้เวอร์ชัน { $current } อยู่ หากต้องการใช้ Atlas { $version } ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่ด้วย ISO พร้อม Atlas
hardware-tpm = TPM 2.0
hardware-uefi = เฟิร์มแวร์ UEFI
prepare-failed-feature-hidden = Windows 11 เวอร์ชัน { $release } ถูกซ่อนไว้ใน Windows Update บนพีซีเครื่องนี้ ใช้เครื่องมือที่คุณใช้ซ่อนเพื่อแสดงการอัปเดตนี้อีกครั้ง แล้วเลือก ลองอีกครั้ง
# $needed and $free are whole gigabytes; $drive is a drive such as C:.
prepare-failed-feature-disk-space = Windows ต้องมีพื้นที่ว่างอย่างน้อย { $needed } GB ในไดรฟ์ { $drive } สำหรับการอัปเดตนี้ แต่ไดรฟ์นี้มีพื้นที่ว่าง { $free } GB Atlas ไม่ได้เปลี่ยนแปลงสิ่งใด เพิ่มพื้นที่ว่าง แล้วเลือก ลองอีกครั้ง
prepare-failed-feature-servicing = Windows รายงานว่าที่เก็บคอมโพเนนต์ของ Windows เสียหายและซ่อมแซมไม่ได้ Atlas จึงไม่ได้เปลี่ยนแปลงสิ่งใด ซ่อมแซม Windows แล้วเลือก ลองอีกครั้ง
prepare-failed-feature-managed = พีซีเครื่องนี้รับการอัปเดตจากเซิร์ฟเวอร์อัปเดตขององค์กร Atlas จึงอัปเดตพีซีเป็นเวอร์ชัน { $release } ไม่ได้ Atlas ไม่ได้เปลี่ยนแปลงสิ่งใด
# $setting is the technical name of a Windows Update policy value or service, such as NoAutoUpdate or BITS, shown as it is.
prepare-failed-feature-policy = มีบางอย่างบนพีซีเครื่องนี้เปลี่ยน { $setting } กลับคืนทุกครั้งหลังจากที่ Atlas เปลี่ยน Atlas จึงอัปเดต Windows ไม่ได้ หากพีซีเครื่องนี้อยู่ภายใต้การจัดการขององค์กร ให้สอบถามองค์กรนั้น เมื่อคุณหยุด Atlas จะคืนค่าสิ่งที่ Atlas เปลี่ยนไว้
prepare-failed-feature-blocked = การตั้งค่าที่ Atlas ไม่ได้เปลี่ยนกำลังทำให้ Windows Update ทำงานไม่ได้: { $setting } เปลี่ยนการตั้งค่านี้เพื่อให้ Windows Update ทำงานได้ แล้วเลือก ลองอีกครั้ง
prepare-failed-feature-rolled-back = Windows ติดตั้งเวอร์ชัน { $release } ให้เสร็จระหว่างรีสตาร์ตไม่ได้ จึงย้อนกลับไปใช้เวอร์ชัน { $current } ไฟล์และแอปของคุณไม่ได้รับผลกระทบ เลือก ลองอีกครั้ง หรือเลือก ส่งรายงาน
prepare-failed-feature-components-lost = การเปลี่ยนแปลงบางอย่างของ Atlas หายไปหลังการอัปเดต Windows และไม่มีร่องรอยว่า Windows ติดตั้งตัวเองใหม่ Atlas จึงบอกไม่ได้ว่าเกิดอะไรขึ้น และยังไม่ได้ติดตั้ง Atlas { $version } เลือก ส่งรายงาน เพื่อให้ทีม Atlas ช่วยเหลือ
prepare-failed-feature-build = เวอร์ชัน Windows ของพีซีเครื่องนี้เปลี่ยนไประหว่างที่ Atlas กำลังอัปเดต เลือก คืนค่าการตั้งค่า แล้วเริ่มใหม่จากหน้าหลัก
prepare-failed-feature-journal = Atlas อ่านบันทึกการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ไม่ได้ จึงจะไม่เปลี่ยนแปลงหรือคืนค่าสิ่งใด เลือก ส่งรายงาน เพื่อให้ทีม Atlas ช่วยเหลือ
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
prepare-failed-feature-pin = นโยบาย Windows Update บนพีซีเครื่องนี้ ({ $setting }) มีค่าที่ Atlas บันทึกไว้ไม่ได้ Atlas จึงไม่ได้เปลี่ยนแปลงสิ่งใด เลือก ส่งรายงาน เพื่อให้ทีม Atlas ช่วยเหลือ
prepare-failed-feature-terms = ยอมรับข้อกำหนดสิทธิ์การใช้งานสำหรับ Windows 11 เวอร์ชัน { $release } แล้วเลือก ลองอีกครั้ง
prepare-failed-feature-failed = Windows ติดตั้งเวอร์ชัน { $release } ไม่ได้ พีซีของคุณยังใช้เวอร์ชัน { $current } อยู่ เลือก ลองอีกครั้ง หากยังไม่สำเร็จ ให้เลือก ส่งรายงาน
prepare-check-again = ตรวจสอบอีกครั้ง
prepare-keep-version = คงไว้ที่เวอร์ชัน { $current }
# Asked before leaving the update with Windows Update settings changed.
stop-update-title = หยุดอัปเดตเป็น Atlas { $version } หรือไม่
stop-update-before = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ การอัปเดตที่ Windows ติดตั้งไปแล้วจะยังคงอยู่ และพีซีของคุณจะยังใช้ Windows 11 เวอร์ชัน { $current }
stop-update-after = พีซีของคุณจะยังใช้ Windows 11 เวอร์ชัน { $release } และ Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้
stop-update-access = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ การอัปเดตที่ Windows ติดตั้งไปแล้วจะยังคงอยู่
stop-update-keep = อัปเดตต่อไป
window-close-update-access-title = ปิด Atlas หรือไม่
window-close-update-access-message = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ก่อนปิด คุณเริ่มอัปเดตอีกครั้งได้จากหน้าหลัก
window-close-put-back = คืนค่าและปิด
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = ปิดโดยไม่คืนค่าการตั้งค่าหรือไม่
window-close-put-back-failed-message = หากปิด Atlas ตอนนี้ การตั้งค่า Windows Update จะยังเป็นตามที่ Atlas เปลี่ยนไว้ เมื่อคุณเปิด Atlas อีกครั้ง หน้าหลักจะเสนอให้คืนค่าการตั้งค่าเหล่านั้น
# The "Atlas is installed" window, when the user's choice turned Windows Update off again.
installed-update-off-again = Windows Update ปิดอีกครั้งตามที่คุณเลือก ขณะที่ปิดอยู่ พีซีของคุณจะไม่ได้รับการอัปเดตความปลอดภัย
installed-update-paused-again = การอัปเดต Windows ถูกหยุดชั่วคราวอีกครั้งตามที่คุณเลือก ขณะที่หยุดชั่วคราวอยู่ พีซีของคุณจะไม่ได้รับการอัปเดตความปลอดภัย
# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-transition = พีซีเครื่องนี้ใช้ Windows 11 เวอร์ชัน { $current } ซึ่ง Atlas เวอร์ชันนี้ไม่รองรับ Atlas จะอัปเดต Windows เป็นเวอร์ชัน { $release } เมื่ออัปเดต Windows ด้านล่าง
# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = การอัปเดต Windows สำหรับ Atlas ไม่เสร็จสมบูรณ์ รายละเอียดสำหรับทีม Atlas:
# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
mode-rebase = การติดตั้งซ้ำหลังการอัปเดต Windows
history-mode-rebase = ติดตั้งซ้ำหลังอัปเดต Windows
ready-rebase-title = Windows ติดตั้งตัวเองใหม่ระหว่างอัปเดต
# $previous is the Atlas version the PC had before.
ready-rebase-message = Windows 11 เวอร์ชัน { $release } เข้ามาแทนที่ Windows เดิมของพีซีเครื่องนี้ การเปลี่ยนแปลงบางอย่างของ Atlas จึงหายไป Atlas { $version } จะนำการเปลี่ยนแปลงเหล่านั้นกลับมา โดยใช้ตัวเลือกที่คุณเลือกไว้สำหรับ Atlas { $previous }
# Your choices on an update, started from what the installed Atlas chose.
upgrade-choices-title = ตัวเลือกของคุณจาก Atlas { $previous }
upgrade-choices-detail = Atlas เริ่มจากสิ่งที่ Atlas { $previous } ตั้งค่าไว้บนพีซีเครื่องนี้ การอัปเดตจะคงผลของตัวเลือกเหล่านั้นไว้ การยกเลิกการเลือกรายการเพิ่มเติมที่นี่จึงไม่ได้ย้อนผลนั้นกลับ หากต้องการเปลี่ยนในภายหลัง ให้ใช้โฟลเดอร์ Atlas หรือการตั้งค่า Windows
rebase-choices-title = ตัวเลือกของคุณจาก Atlas { $previous }
rebase-choices-detail = Atlas ใช้ตัวเลือกที่คุณเลือกไว้สำหรับ Atlas { $previous } จึงไม่มีอะไรให้เลือกที่นี่ คุณเปลี่ยนตัวเลือกเหล่านี้ได้ภายหลังในโฟลเดอร์ Atlas
# $missing lists the choices, such as "Microsoft Defender, Mitigations".
rebase-choices-partial = Atlas ใช้ตัวเลือกที่คุณเลือกไว้สำหรับ Atlas { $previous } แต่หาตัวเลือกต่อไปนี้ไม่พบ จึงควรตรวจดู: { $missing }
# Asked before any restart Atlas makes while other people are signed in to the PC.
restart-other-title = มีผู้ใช้อีกคนเข้าสู่ระบบพีซีเครื่องนี้อยู่
restart-others-title = มีผู้ใช้คนอื่นหลายคนเข้าสู่ระบบพีซีเครื่องนี้อยู่
# $names lists their account names, such as "Alex and Sam".
restart-others-message = การรีสตาร์ตจะปิดแอปของผู้ใช้อื่น และงานที่ยังไม่ได้บันทึกของพวกเขาจะสูญหาย ผู้ที่เข้าสู่ระบบอยู่: { $names }
restart-others-keep = ไม่รีสตาร์ต
restart-others-restart = ยังคงรีสตาร์ต
# Microsoft Store itself, before the Store apps. Get ready's status line while it updates or is repaired.
prepare-store-self-update = กำลังอัปเดต Microsoft Store ก่อน เนื่องจาก Microsoft Store บนพีซีเครื่องนี้ไม่ใช่เวอร์ชันล่าสุด
prepare-store-repair = กำลังซ่อมแซม Microsoft Store ขั้นตอนนี้อาจใช้เวลาสองสามนาที
# Under prepare-complete, once Get ready has finished.
prepare-store-updated = Microsoft Store ไม่ใช่เวอร์ชันล่าสุด Atlas จึงอัปเดต Microsoft Store ก่อนอัปเดตแอปของคุณ
prepare-store-bootstrapped = Microsoft Store อัปเดตตัวเองไม่ได้ Atlas จึงติดตั้ง App Installer และ Microsoft Store เวอร์ชันล่าสุดจาก Microsoft
prepare-store-repaired = Microsoft Store ไม่ทำงาน Atlas จึงซ่อมแซมให้แล้ว
prepare-store-skipped-removed = Microsoft Store ถูกปิดไว้บนพีซีเครื่องนี้ Atlas จึงข้ามการอัปเดตแอปจาก Store
# "Repair Microsoft Store" is prepare-repair-store; "Send a report" is report-title.
prepare-failed-store-repair-failed = Microsoft Store ไม่ทำงาน และ Atlas ซ่อมแซมไม่ได้ เลือก ซ่อมแซม Microsoft Store เพื่อลองอีกครั้ง หากยังไม่ได้ผล ให้เลือก ส่งรายงาน
prepare-repair-store = ซ่อมแซม Microsoft Store
