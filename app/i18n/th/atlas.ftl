### Atlas Manager: ไทย (Thai) — preview translation, revised on 24 November 2026 from the en-GB source.
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
###   product names. The Atlas package (.atlaspkg) is "แพ็กเกจ Atlas", or
###   "แพ็กเกจ" once it is clear.
###   Windows features use the names Thai Windows shows: the app is
###   "ความปลอดภัยของ Windows" (written "แอป ความปลอดภัยของ Windows" when it is
###   the object of "open"), and the four switches are named on the
###   "การตั้งค่าการป้องกันไวรัสและภัยคุกคาม" page.
### - Thai punctuation: no full stop at the end of a sentence; separate
###   sentences and clauses with a space; put a space on both sides of Latin
###   words and numbers. Buttons are short and verb-first.
### - When text names a button, card or step, write its exact label with a
###   space on each side: "เลือก ลองอีกครั้ง", "ไปที่ เตรียมความพร้อม".
### - "รีสตาร์ต" always means restarting the PC / Windows; "เปิด Atlas ใหม่"
###   always means relaunching this app, and "เปิด Atlas อีกครั้ง" opening it
###   again after it was closed.
### - Question titles have no "?"; they end in "หรือไม่" or a question word.
###   Status lines that show work in progress keep the ellipsis (…).
### - Sign in is "ลงชื่อเข้าใช้", as Microsoft's Thai pages write it.
### - The ISO steps are "Windows", "ตั้งค่า" and "สร้าง". "ตั้งค่า" has no
###   "การ" so it isn't read as the app's Settings page ("การตั้งค่า").
### - "ขั้นตอน" is only a step of the install and ISO flows. A stage of updating,
###   installing, creating an ISO or writing a USB drive is "ช่วง" ("ช่วงปัจจุบัน",
###   "ช่วงสุดท้าย"). "ช่วงนี้" alone reads as "these days", so put it after a
###   number ("{ $percent }% ของช่วงนี้"), and where English says "This can
###   take…" of a repair, name the work ("การซ่อมแซมนี้").
### - Windows Setup, Windows' own installer, is "โปรแกรมติดตั้ง Windows";
###   Atlas's installer is "ตัวติดตั้ง". A retried installation is
###   "การติดตั้งรอบนี้", the earlier one "รอบก่อน".
### - Windows names: Storage settings "การตั้งค่าที่เก็บข้อมูล", Task Manager
###   "ตัวจัดการงาน", Services "บริการ" (opened as "แอป บริการ"), the
###   Downloads folder "ดาวน์โหลด", the Start menu "เมนูเริ่ม".
### - A tester build is "รุ่นทดสอบ"; Review is "ตรวจทาน", checking is "ตรวจสอบ".

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
# Opens the folder of the install log, with the log selected.
common-open-log-folder = เปิดโฟลเดอร์บันทึก
# Accessible name of the Copy button beside the install log.
common-copy-install-log = คัดลอกบันทึกการติดตั้ง
common-install-log = บันทึกการติดตั้ง
# Row labels in summary cards.
common-windows = Windows
common-package = แพ็กเกจ Atlas
common-checking = กำลังตรวจสอบ
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } หรือ { $b }
list-and = { $a } และ { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }, { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = ปิดหน้าต่างขณะที่ Atlas กำลังติดตั้งหรือไม่
window-close-installing = การติดตั้งจะยังดำเนินต่อไป เปิด Atlas อีกครั้งเพื่อดูผลลัพธ์
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = การติดตั้งจะยังดำเนินต่อไป แต่พีซีของคุณจะไม่รีสตาร์ตเอง เปิด Atlas อีกครั้งเพื่อดูผลลัพธ์
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = เปิดหน้าต่างไว้
window-close-close = ปิดหน้าต่าง
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = หยุดก่อนติดตั้งหรือไม่
window-close-checks-unchanged = การติดตั้งยังไม่ได้เปลี่ยนแปลงสิ่งใด หากคุณปิดตอนนี้ การติดตั้งจะไม่เริ่ม
window-close-keep-installing = ติดตั้งต่อ
window-close-stop-and-close = หยุดและปิด
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = หยุดอัปเดตหรือไม่
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas จะหยุดหลังจากช่วงปัจจุบันเสร็จ จากนั้นคุณจึงปิด Atlas ได้
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = รีสตาร์ตเพื่อตั้งค่า Atlas ให้เสร็จหรือไม่
window-close-restart-closed = Atlas รีสตาร์ตพีซีของคุณไม่ได้หลังจากปิดไปแล้ว บันทึกงานของคุณก่อน
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = รีสตาร์ตเพื่ออัปเดตให้เสร็จหรือไม่
window-close-update-restart-later = บันทึกงานของคุณก่อน หากรีสตาร์ตภายหลัง Atlas จะดำเนินการต่อหลังรีสตาร์ต
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = ปิด Atlas ขณะที่การป้องกันยังปิดอยู่หรือไม่
window-close-protection-all = สวิตช์การป้องกันทั้งสี่รายการในแอป ความปลอดภัยของ Windows ปิดอยู่ หากคุณยังไม่ติดตั้ง Atlas ตอนนี้ ให้เปิดกลับก่อน
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
       *[other] { $switches } ปิดอยู่ในแอป ความปลอดภัยของ Windows หากคุณยังไม่ติดตั้ง Atlas ตอนนี้ ให้เปิดกลับก่อน
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = หยุดสร้าง ISO หรือไม่
iso-close-safe-point = Atlas จะหยุดเมื่อถึงจุดที่หยุดได้อย่างปลอดภัย
usb-close-question = หยุดสร้างไดรฟ์ USB หรือไม่
usb-close-unfinished = ไดรฟ์ที่สร้างไม่เสร็จจะใช้ติดตั้ง Windows ไม่ได้
window-close-keep-creating = สร้างต่อ
window-close-stop = หยุด
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = เปิดแพ็กเกจ Atlas (.atlaspkg)
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
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas ลดการทำงานเบื้องหลังและสิ่งรบกวนใน Windows
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas บนพีซีเครื่องนี้
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = ติดตั้งเมื่อ { $date }
home-status-checking = กำลังตรวจหาการอัปเดต…
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
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = ติดตั้ง Atlas บนพีซีเครื่องนี้หรือไม่
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = แอปและการตั้งค่าที่คุณมีอยู่อาจหยุดทำงาน และ Atlas จะลบ OneDrive ออก ไฟล์ใน OneDrive จึงจะหยุดซิงค์และโฟลเดอร์อาจดูว่างเปล่า สำรองไฟล์ของคุณก่อน
home-used-windows-install = ติดตั้งต่อไป
# The card that opens ISO creation; its button is iso-open.
home-iso-title = ติดตั้ง Windows ใหม่พร้อม Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Windows บนพีซีเครื่องนี้ผ่านการใช้งานมาแล้ว และ Atlas ทำงานได้ดีที่สุดบน Windows ที่ติดตั้งใหม่
home-restart-title = พีซีของคุณต้องรีสตาร์ต
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas รีสตาร์ตพีซีของคุณไม่ได้ รีสตาร์ตจากเมนูเริ่ม
home-security-reminder-title = เปิดการป้องกันของคุณอีกครั้ง
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = ตรวจดูให้แน่ใจว่าการป้องกันของคุณเปิดอยู่
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
       *[other] รายการต่อไปนี้ยังปิดอยู่ในแอป ความปลอดภัยของ Windows: { $switches }
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas อ่านค่าสวิตช์การป้องกันได้ไม่ครบ ตรวจดูในแอป ความปลอดภัยของ Windows ว่ารายการต่อไปนี้เปิดอยู่: { $switches }
home-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas บันทึกตัวเลือกการตั้งค่าของคุณไม่ได้ จึงยังไม่ได้เปิด Atlas ใหม่
home-state-error-title = อ่านรายละเอียดการติดตั้ง Atlas ของคุณไม่ได้
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = เวอร์ชัน Atlas ตัวเลือก และประวัติของคุณอาจแสดงไม่ถูกต้อง
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = ต้องอัปเดต Atlas Manager
home-whats-new = มีอะไรใหม่ใน Atlas { $version }
home-view-release = ดูบันทึกประจำรุ่นบน GitHub
home-show-less = แสดงน้อยลง
home-show-full-notes = แสดงบันทึกประจำรุ่นทั้งหมด
home-your-install = การตั้งค่า Atlas ของคุณ
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = พีซีเครื่องนี้ไม่มีบันทึกว่าติดตั้ง Atlas ไว้อย่างไร จึงแสดงตัวเลือกและประวัติการติดตั้งของคุณไม่ได้
home-history = ประวัติการติดตั้ง
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = ขั้นตอนที่ { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }, { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = สิ่งที่จะเกิดขึ้น
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = กำลังตั้งค่า Atlas
# Beside step-ready in that card.
home-step-ready = Atlas ตรวจสอบพีซีของคุณและอัปเดต Windows
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas ตรวจสอบพีซีของคุณและเปลี่ยน Windows เป็นเวอร์ชัน { $release }
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = คุณเลือกสิ่งที่จะเก็บไว้ เช่น Microsoft Defender
# Beside step-security in that card.
home-step-security = คุณปิดสวิตช์การป้องกันทั้งสี่รายการในแอป ความปลอดภัยของ Windows
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts = โดยปกติการติดตั้งใช้เวลาประมาณ { $minutes } นาที จากนั้นพีซีของคุณจะรีสตาร์ต
home-step-install-restart-yourself = โดยปกติการติดตั้งใช้เวลาประมาณ { $minutes } นาที จากนั้นให้รีสตาร์ตพีซีของคุณ
# At the bottom of that card, under the four steps.
home-steps-save-work = บันทึกงานของคุณก่อน เพราะแอปอาจปิดลงและพีซีของคุณจะรีสตาร์ต
home-github = ดู Atlas บน GitHub
home-discord = เข้าร่วมชุมชน Atlas บน Discord
home-report-problem = รายงานปัญหา

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = ติดตั้งครั้งแรก
history-mode-upgrade = อัปเดต
history-mode-reapply = ติดตั้งซ้ำ
history-mode-unknown = ติดตั้ง

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas กำลังใช้การตั้งค่าเริ่มต้นของแอป
notice-settings-unreadable-problem = Atlas อ่านการตั้งค่าแอปที่บันทึกไว้ไม่ได้ การตั้งค่า Windows ของคุณไม่ได้เปลี่ยนแปลง
notice-settings-damaged-kept-problem = ไฟล์การตั้งค่าแอปของคุณเสียหาย Atlas จึงรีเซ็ตไฟล์และเก็บสำเนาของไฟล์เดิมไว้
notice-settings-damaged-problem = ไฟล์การตั้งค่าแอปของคุณเสียหาย Atlas จะใช้ค่าเริ่มต้นไปก่อน
notice-settings-not-saved-title = บันทึกการตั้งค่าแอปไม่ได้
notice-settings-not-saved-problem = Atlas บันทึกการเปลี่ยนแปลงล่าสุดของคุณไม่ได้ การเปลี่ยนแปลงจึงอาจหายไปเมื่อปิด Atlas หากมีหน้าต่าง Atlas อื่นเปิดอยู่ ให้ปิดหน้าต่างนั้น แล้วเปลี่ยนอีกครั้ง
notice-session-unreadable-title = ตรวจสอบการติดตั้งครั้งก่อนไม่ได้
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas ตรวจสอบไม่ได้ว่าการติดตั้งครั้งก่อนยังทำงานอยู่หรือไม่ หากแน่ใจว่าไม่มีการติดตั้งใดทำงานอยู่ ให้ลบไฟล์ข้อมูลการติดตั้งนั้น แล้วเปิด Atlas ใหม่
# Get ready, when the install record can't be read. $path is a file path (text).
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
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = เสร็จแล้ว
stepper-status-current = ขั้นตอนปัจจุบัน
stepper-status-upcoming = ยังไม่ถึง
stepper-status-attention = ต้องดำเนินการ
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = ขั้นตอนที่ { $number } จาก { $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }, { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = ตรวจสอบพีซีของคุณ
# Status line while the checks run.
ready-checks-running = กำลังตรวจสอบพีซีของคุณ…
ready-check-again = ตรวจสอบอีกครั้ง
# Status line once every check passed; common-show-details lists them.
ready-checks-passed = ผ่านการตรวจสอบ { $count } รายการ
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
ready-checks-passed-some = ผ่านการตรวจสอบ { $passed } จาก { $total } รายการ
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of.
ready-checks-handled = การอัปเดตจะจัดการให้ { $count } รายการ
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = การอัปเดตจะจัดการให้
# Under the title of a check that updating takes care of.
check-updates-handled = มีการอัปเดตรอติดตั้งอยู่ Atlas จะติดตั้งให้ระหว่างอัปเดต Windows
check-restart-handled = Windows ต้องรีสตาร์ตเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ การอัปเดตจะจัดการให้
check-handled = การอัปเดตจะจัดการรายการนี้ให้
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = กำลังดาวน์โหลด…
ready-package-unpacking = กำลังแตกไฟล์…
ready-package-ready = พร้อมแล้ว
ready-package-checking = กำลังตรวจหาเวอร์ชันล่าสุด…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = กำลังเตรียมแพ็กเกจ Atlas ที่มาพร้อมกัน…
ready-package-none = ยังไม่ได้ดาวน์โหลด
ready-package-failed = รับแพ็กเกจ Atlas ไม่ได้
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = ดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.atlaspkg) อื่น
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = แตกไฟล์แพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้ไม่ได้ ลองอีกครั้ง
ready-package-manager = ต้องใช้ Atlas Manager เวอร์ชันที่ใหม่กว่า
ready-package-release-failed = ตรวจหาเวอร์ชันล่าสุดไม่ได้
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง หากคุณมีแพ็กเกจ Atlas (.atlaspkg) ก็เปิดแพ็กเกจนั้นแทนได้
# Row title.
ready-updates-title = การอัปเดต Windows และ Microsoft Store
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = แอปจาก Store เช่น Notepad อาจปิดลงระหว่างอัปเดต บันทึกงานในแอปเหล่านั้นก่อน
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = เริ่มหลังจาก Windows เปลี่ยนเป็นเวอร์ชัน { $release }
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = กำลังดำเนินการต่อหลังรีสตาร์ต…
ready-updates-restarting = กำลังรีสตาร์ตพีซีของคุณ…
ready-updates-done = Windows และแอปจาก Store เป็นเวอร์ชันล่าสุดแล้ว
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows เป็นเวอร์ชันล่าสุดแล้ว
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown = พีซีของคุณจะรีสตาร์ตใน { $seconds } วินาที
ready-updates-restart = พีซีของคุณต้องรีสตาร์ตเพื่ออัปเดตให้เสร็จ
ready-updates-restart-finish = Windows ต้องรีสตาร์ตอีกหนึ่งครั้งเพื่อติดตั้งเวอร์ชัน { $release } ให้เสร็จ
ready-updates-restart-failed = พีซีของคุณไม่ได้รีสตาร์ต
# Under the restart's status line, before Restart now.
ready-updates-restart-save = บันทึกงานของคุณก่อน
ready-updates-restart-persists = Windows ยังขอให้รีสตาร์ตอยู่
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = การรีสตาร์ตอีกครั้งไม่น่าจะช่วย ทำรายการที่รออยู่ใน Windows Update ให้เสร็จ แล้วลองอีกครั้ง
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = เหตุผลที่ต้องรีสตาร์ต: { $reasons }
ready-updates-network = การอัปเดตใช้การเชื่อมต่อนี้ไม่ได้
ready-updates-stopped = หยุดอัปเดตแล้ว การอัปเดตบางรายการอาจติดตั้งไปแล้ว
ready-updates-previous = กำลังรอการอัปเดตที่เริ่มไว้ก่อนหน้านี้…
# Button after the user stopped updating.
ready-updates-resume = อัปเดตต่อ
ready-updates-start = เริ่มอัปเดต
# Why updating hasn't started, under the row.
ready-updates-blocked = การอัปเดตจะรอจนกว่า Atlas จะติดตั้งบนพีซีเครื่องนี้ได้
ready-updates-needs-admin = จะเริ่มเมื่อ Atlas ได้รับสิทธิ์ผู้ดูแลระบบ
ready-updates-needs-windows = จะเริ่มเมื่อผ่านการตรวจสอบความเข้ากันได้กับ Windows
ready-updates-needs-drivers = จะเริ่มเมื่อคุณเลือกวิธีติดตั้งไดรเวอร์แล้ว
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = ไดรเวอร์: { $choice }
ready-drivers-automatic = ผ่าน Windows Update
ready-drivers-manual = ติดตั้งเอง
ready-drivers-change-a11y = เปลี่ยนวิธีติดตั้งไดรเวอร์
# Under the two answers, once updating has run.
ready-drivers-again = หากเปลี่ยนตัวเลือกนี้ การอัปเดตจะทำงานอีกครั้ง

# $received and $total are formatted numbers of megabytes (text).
package-downloading = กำลังดาวน์โหลด Atlas { $version } · { $received } จาก { $total } MB
package-unpacking = กำลังแตกไฟล์
package-status-ready = พร้อม
# Accessible name of the progress bar.
package-progress = ความคืบหน้าของแพ็กเกจ Atlas
package-download-again = ดาวน์โหลดอีกครั้ง
package-download-version = ดาวน์โหลด Atlas { $version }
package-download-newest = ดาวน์โหลดเวอร์ชันล่าสุด
package-cancel-download = ยกเลิกการดาวน์โหลด
package-open-file = เปิดไฟล์แพ็กเกจ
# Where the package came from. $file is a file name (text).
package-from-release = ดาวน์โหลด Atlas { $version } จาก GitHub แล้ว พร้อมติดตั้ง
package-from-file = โหลด Atlas { $version } จาก { $file } แล้ว พร้อมติดตั้ง
package-unpacked = Atlas { $version } พร้อมติดตั้งแล้ว
package-none-yet = ยังไม่มีแพ็กเกจ Atlas
acquire-no-asset = Atlas { $version } ไม่มีไฟล์แพ็กเกจให้ดาวน์โหลด เปิดแพ็กเกจ Atlas (.atlaspkg) ที่บันทึกไว้เพื่อดำเนินการต่อ
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = แอปนี้ติดตั้งได้เฉพาะ Atlas 0.6.0 ขึ้นไปจากแพ็กเกจ Atlas (.atlaspkg)
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } ขาดไฟล์ที่แอปนี้ต้องใช้ในการติดตั้ง ดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.atlaspkg) อีกไฟล์หนึ่ง
acquire-failed = เตรียมแพ็กเกจ Atlas ไม่ได้ ดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.atlaspkg) อื่น รายละเอียด: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = การดาวน์โหลดหยุดตอบสนอง ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วดาวน์โหลดอีกครั้ง หรือเปิดแพ็กเกจ Atlas (.atlaspkg) ที่บันทึกไว้
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = เตรียมแพ็กเกจ Atlas ที่มาพร้อมกันไม่ได้ เลือก ลองอีกครั้ง รายละเอียด: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = แพ็กเกจ Atlas นี้ต้องใช้ Atlas Manager เวอร์ชันที่ใหม่กว่า ดาวน์โหลด Atlas Manager { $version } ขึ้นไป แล้วใช้แทนเวอร์ชันนี้
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = แพ็กเกจ Atlas นี้ต้องใช้ Atlas Manager เวอร์ชันที่ใหม่กว่า ดาวน์โหลด Atlas Manager เวอร์ชันล่าสุด แล้วใช้แทนเวอร์ชันนี้
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = หากต้องการติดตั้ง Atlas { $version } ให้ดาวน์โหลด Atlas Manager { $required } ขึ้นไป แล้วใช้แทนเวอร์ชันนี้
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = หากต้องการติดตั้ง Atlas { $version } ให้ดาวน์โหลด Atlas Manager เวอร์ชันล่าสุด แล้วใช้แทนเวอร์ชันนี้

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = ดาวน์โหลด Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = มี Atlas Manager { $version } ให้ดาวน์โหลด
manager-update-message = Atlas Manager อัปเดตตัวเองไม่ได้ ดาวน์โหลดเวอร์ชันใหม่ แล้วใช้แทนเวอร์ชันนี้

## System checks

check-administrator = สิทธิ์ในการติดตั้ง
check-supported-build = ความเข้ากันได้กับ Windows
check-pending-updates = การอัปเดต Windows
check-pending-reboot = การรีสตาร์ตที่ค้างอยู่
check-third-party-antivirus = โปรแกรมป้องกันไวรัสอื่น
check-internet = การเชื่อมต่ออินเทอร์เน็ต
check-power = แหล่งจ่ายไฟ
check-activation = การเปิดใช้งาน Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = ฮาร์ดแวร์สำหรับ Windows 11
check-move-space = พื้นที่ว่าง
check-move-update-source = แหล่งที่มาของการอัปเดต
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
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = เปิดการตั้งค่าที่เก็บข้อมูล
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = เปิดหน้า แอปที่ติดตั้ง
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = ฉันตรวจสอบ Windows Update แล้ว ไม่มีการอัปเดตที่รอติดตั้ง

detail-admin-ok = Atlas มีสิทธิ์ทำการเปลี่ยนแปลงที่จำเป็นสำหรับการติดตั้ง
detail-admin-missing = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบ แล้วเลือก ใช่ เมื่อ Windows ขอสิทธิ์
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas เวอร์ชันนี้ต้องใช้ Windows บิลด์ { $builds } แต่พีซีของคุณเป็นบิลด์ { $build } ติดตั้ง Windows เวอร์ชันที่รองรับก่อนดำเนินการต่อ
detail-build-missing = แพ็กเกจ Atlas นี้ไม่ได้ระบุบิลด์ Windows ที่รองรับ ใช้แพ็กเกจแบบบิลด์เต็มแทนบิลด์ LocalTest
detail-updates-none = ไม่มีการอัปเดต Windows ที่รอติดตั้ง
# Updates still waiting once updating has run. $count is how many.
detail-updates-left = ยังมีการอัปเดต { $count } รายการรอติดตั้งอยู่ ติดตั้งใน Windows Update แล้วตรวจสอบอีกครั้ง
detail-updates-scan-failed = ตรวจหาการอัปเดต Windows ไม่ได้ เปิด Windows Update เพื่อดูว่ามีการอัปเดตรอติดตั้งอยู่หรือไม่ ({ $error })
detail-reboot-none = Windows ไม่จำเป็นต้องรีสตาร์ตในขณะนี้
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows ต้องรีสตาร์ตเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ รีสตาร์ตพีซีของคุณ แล้วตรวจสอบอีกครั้ง
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows ต้องรีสตาร์ตเพื่อให้การเปลี่ยนแปลงก่อนหน้านี้เสร็จสมบูรณ์ ({ $reasons }) รีสตาร์ตพีซีของคุณ แล้วตรวจสอบอีกครั้ง
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = คุณดำเนินการต่อได้ Windows มีไฟล์ที่ต้องแทนที่หรือลบเมื่อรีสตาร์ตครั้งถัดไป ({ $files }) บางแอป เช่น Xbox Gaming Services จะทำเช่นนี้หลังรีสตาร์ตทุกครั้ง
detail-reboot-unknown = ตรวจสอบไม่ได้ว่า Windows ต้องรีสตาร์ตหรือไม่ รีสตาร์ตพีซี จากนั้นเปิด Atlas อีกครั้งแล้วตรวจสอบใหม่ ({ $error })
detail-antivirus-none = ไม่พบโปรแกรมป้องกันไวรัสอื่น
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = แอปป้องกันไวรัสอื่นนอกเหนือจาก Microsoft Defender อาจขัดขวางการติดตั้ง ถอนการติดตั้ง { $products } แล้วตรวจสอบอีกครั้ง
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = ความปลอดภัยของ Windows ยังแสดง { $products } อยู่ แต่ไฟล์ของโปรแกรมหายไปแล้ว จึงไม่ถือว่าติดตั้งอยู่อีกต่อไป Atlas ยังติดตั้งต่อได้
detail-antivirus-check-failed = ตรวจหาโปรแกรมป้องกันไวรัสอื่นไม่ได้ หากยังเกิดขึ้นอีก ให้รีสตาร์ตพีซีแล้วตรวจสอบอีกครั้ง ({ $error })
detail-internet-ok = เชื่อมต่ออินเทอร์เน็ตอยู่ เชื่อมต่อไว้ตลอดขณะที่ Atlas ดาวน์โหลดและติดตั้งซอฟต์แวร์
detail-internet-missing = เชื่อมต่ออินเทอร์เน็ต แล้วตรวจสอบอีกครั้ง
detail-power-mains = พีซีของคุณเสียบปลั๊กอยู่ เสียบปลั๊กไว้จนกว่าการติดตั้งจะเสร็จ
detail-power-battery = เสียบปลั๊กพีซีของคุณเพื่อให้เปิดอยู่ตลอดการติดตั้ง
detail-power-check-failed = Atlas ตรวจสอบไม่ได้ว่าพีซีของคุณเสียบปลั๊กอยู่หรือไม่ หากเป็นแล็ปท็อป ให้เสียบปลั๊ก แล้วตรวจสอบอีกครั้ง
detail-activation-ok = Windows เปิดใช้งานแล้ว Atlas จะไม่เปลี่ยนแปลงสิ่งนี้
detail-activation-missing = Windows ยังไม่ได้เปิดใช้งาน คุณดำเนินการต่อได้ แต่ Atlas จะไม่เปิดใช้งาน Windows ให้
detail-activation-no-licence = Windows ไม่ได้รายงานสิทธิ์การใช้งาน คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ
detail-activation-unknown = ตรวจสอบการเปิดใช้งาน Windows ไม่ได้ คุณดำเนินการต่อได้ Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งานของคุณ ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas ไม่จำเป็นต้องเปลี่ยน Windows บนพีซีเครื่องนี้เป็นเวอร์ชันที่ใหม่กว่า
detail-move-hardware-ready = พีซีเครื่องนี้มี TPM 2.0 และเฟิร์มแวร์ UEFI ที่ Windows 11 ต้องใช้
detail-move-hardware-missing = พีซีเครื่องนี้ไม่มี { $missing } Windows Update จึงจะไม่เปลี่ยนเป็นเวอร์ชัน { $release } ให้ สำรองไฟล์ของคุณ แล้วติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
detail-move-hardware-unread = Atlas อ่านข้อมูลฮาร์ดแวร์ของพีซีเครื่องนี้ได้ไม่ครบ Windows Update จึงจะตรวจสอบเอง
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } มีพื้นที่ว่าง { $free } GB
detail-move-space-short = เวอร์ชัน { $release } ต้องใช้พื้นที่ว่าง { $needed } GB บน { $drive } แต่มีอยู่ { $free } GB เพิ่มพื้นที่ว่าง แล้ว Atlas จะตรวจสอบอีกครั้งเอง
detail-move-space-unknown = ตรวจสอบพื้นที่ว่างสำหรับการอัปเดต Windows ไม่ได้ รีสตาร์ตพีซีของคุณ แล้วตรวจสอบอีกครั้ง ({ $error })
detail-move-update-source-ok = พีซีเครื่องนี้รับการอัปเดตจาก Windows Update
detail-move-update-source-managed = พีซีเครื่องนี้รับการอัปเดตจากเซิร์ฟเวอร์ขององค์กร ซึ่งไม่มีเวอร์ชัน { $release } ให้ ติดต่อองค์กรของคุณ หรือติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = คุณเปลี่ยนตัวเลือกเกี่ยวกับ Microsoft Defender การป้องกันตัวประมวลผล และการอัปเดต ได้ภายหลังจากโฟลเดอร์ Atlas บนเดสก์ท็อปของคุณ
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = ไม่ได้เลือก
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = เลือก { $count } รายการ
# Links that unfold and fold the Optional extras card.
options-extras-show = แสดง
options-extras-hide = ซ่อน
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender คือโปรแกรมป้องกันไวรัสที่มาพร้อมกับ Windows
question-mitigations-description = การป้องกันเหล่านี้ หรือที่เรียกว่ามาตรการลดความเสี่ยงด้านความปลอดภัย ช่วยรับมือกับข้อบกพร่องของตัวประมวลผล เช่น Spectre และ Meltdown รวมถึงการโจมตีที่อาศัยบั๊กในแอป
question-auto-updates-description = ไม่ว่าจะเลือกแบบใด Atlas จะคง Windows ไว้ที่เวอร์ชันปัจจุบัน และปิดการอัปเดตอัตโนมัติของแอปจาก Microsoft Store
question-browser-description = Atlas จะไม่เปลี่ยนการตั้งค่าเบราว์เซอร์ของคุณ
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = พีซีของคุณจะไม่มีโปรแกรมป้องกันไวรัสจนกว่าคุณจะติดตั้งตัวอื่น และ Windows จะไม่เตือนคุณก่อนเปิดแอปหรือไฟล์ดาวน์โหลดที่ไม่รู้จัก
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = การเลือกนี้จะปิด การป้องกัน Exploit สำหรับแอปด้วย เช่น Control Flow Guard ซึ่งจะลดความปลอดภัย
cost-auto-updates-disable = เปิด Windows Update เป็นประจำเพื่อรับการแก้ไขด้านความปลอดภัย
cost-auto-updates-default = Windows อาจรีสตาร์ตพีซีของคุณเพื่อติดตั้งการอัปเดตให้เสร็จ
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift และ Ctrl+Shift จะไม่สลับภาษาหรือรูปแบบแป้นพิมพ์อีกต่อไป
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = คืนพื้นที่ดิสก์ แต่จะใช้ไฮเบอร์เนตและการเริ่มต้นอย่างรวดเร็วไม่ได้
extra-disable-power-saving = พีซีของคุณอาจใช้ไฟมากขึ้น ร้อนขึ้น และใช้แบตเตอรี่ได้สั้นลง
extra-disable-core-isolation = ลดการป้องกัน รวมถึงปิดความสมบูรณ์ของหน่วยความจำ และอาจกระทบแอปหรือเกมที่ต้องใช้ฟีเจอร์นี้
extra-uninstall-edge = รายการโปรด ประวัติ และรหัสผ่านที่บันทึกไว้ของ Edge บนพีซีเครื่องนี้จะถูกลบ ยกเว้นข้อมูลที่ซิงค์กับบัญชี Microsoft ของคุณ
extra-install-toolbox = ช่วยจัดการการตั้งค่า Atlas ของคุณ แต่บางฟีเจอร์อาจยังไม่สมบูรณ์ขณะที่ยังเป็นรุ่นเบต้า
extra-install-eclean = เครื่องมือจากทีมผู้สร้าง AtlasOS สำหรับตรวจสอบไฟล์ขยะและแอปเริ่มต้นระบบ ต้องมีบัญชีและการเชื่อมต่ออินเทอร์เน็ต
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
# Each decision's short name in the middle of a sentence, as in summary-change-a11y,
# update-path-differs, preflight-choice-unanswered and installed-not-applied-choices. Write it as
# the language does mid-sentence: in English, product names keep their capitals and other names
# are lower case.
screen-update-path-name = วิธีที่ Atlas อัปเดต
screen-defender-name = Microsoft Defender
screen-mitigations-name = การป้องกันตัวประมวลผล
screen-updates-name = Windows Update
screen-keyboard-name = ภาษาของแป้นพิมพ์
screen-browser-name = เบราว์เซอร์
screen-power-name = พลังงานและความปลอดภัย
screen-apps-name = แอป
screen-optional-apps-name = แอปเสริม
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = ตัวเลือกในแพ็กเกจ Atlas
screen-extras-name = รายการเพิ่มเติม
# Question for a required choice this app has no specific wording for.
screen-generic-question = เลือกตัวเลือกสำหรับ { $title }
learn-more-defender = เรียนรู้เพิ่มเติมเกี่ยวกับ Microsoft Defender
learn-more-mitigations = เรียนรู้เพิ่มเติมเกี่ยวกับการป้องกันตัวประมวลผล
learn-more-updates = เรียนรู้เพิ่มเติมเกี่ยวกับ Windows Update
learn-more-browser = เรียนรู้เพิ่มเติมเกี่ยวกับเบราว์เซอร์
learn-more-power = เรียนรู้เพิ่มเติมเกี่ยวกับพลังงานและความปลอดภัย
learn-more-apps = เรียนรู้เพิ่มเติมเกี่ยวกับแอป
learn-more-eclean = เรียนรู้เพิ่มเติมเกี่ยวกับ eclean
learn-more-keyboard = เรียนรู้เพิ่มเติมเกี่ยวกับภาษาของแป้นพิมพ์
learn-more-generic = อ่านคู่มือการตั้งค่า
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = เก็บโปรแกรมป้องกันไวรัสที่มาพร้อม Windows ไว้ เพื่อช่วยปกป้องพีซีของคุณจากไวรัสและภัยคุกคามอื่น ๆ
consequence-mitigations-default = เก็บการป้องกันเริ่มต้นของ Windows ไว้ เพื่อรับมือกับข้อบกพร่องของตัวประมวลผลและการโจมตีที่อาศัยบั๊กในแอป
consequence-mitigations-disable = ปิด การป้องกัน Exploit สำหรับแอปด้วย เช่น Control Flow Guard การทำเช่นนี้จะลดความปลอดภัย ประสิทธิภาพจะต่างไปมากน้อยเพียงใดขึ้นอยู่กับตัวประมวลผลของคุณ
consequence-auto-updates-disable = เปิด Windows Update เป็นประจำเพื่อติดตั้งการอัปเดต การแจ้งเตือนการอัปเดตจะยังเปิดอยู่
consequence-auto-updates-default = Windows จะติดตั้งการอัปเดตโดยอัตโนมัติ รวมถึงการแก้ไขด้านความปลอดภัย

## Step 2 on an update or reinstall of the installed Atlas

update-path-update-title = ต้องการอัปเดตเป็น Atlas { $version } อย่างไร
update-path-reinstall-title = ต้องการติดตั้ง Atlas { $version } ใหม่อย่างไร
update-path-keep = คงตัวเลือกเดิมไว้
update-path-keep-detail = Atlas จะคงทุกตัวเลือกไว้ตามที่พีซีเครื่องนี้ใช้อยู่ตอนนี้ โดยไม่เปลี่ยนตัวเลือกใดเลย
update-path-choose = เลือกใหม่
update-path-choose-detail = เริ่มจากการตั้งค่าที่พีซีเครื่องนี้ใช้อยู่ตอนนี้ แอป ไฟล์ และการตั้งค่าส่วนบุคคลของคุณจะยังอยู่
update-path-now-title = ตัวเลือกของคุณที่ใช้อยู่ในพีซีเครื่องนี้
update-path-unknown = Atlas ระบุข้อนี้จากพีซีของคุณไม่ได้ จึงจะถามคุณ
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = พีซีเครื่องนี้ไม่ตรงกับข้อมูลที่ Atlas บันทึกไว้ในส่วนของ { $choices }
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas จะคงตัวเลือกอื่นทั้งหมดไว้ตามที่พีซีเครื่องนี้ใช้อยู่ตอนนี้
option-now = ใช้อยู่ในพีซีเครื่องนี้
change-defender-enable = Atlas จะนำ Microsoft Defender กลับมา หลังรีสตาร์ต ให้เปิดการป้องกันของ Defender ในแอป ความปลอดภัยของ Windows
change-mitigations-default = Atlas จะเปิดการป้องกันตัวประมวลผลอีกครั้งตามค่าเริ่มต้นของ Windows โดยจะมีผลหลังรีสตาร์ต
change-mitigations-all-on = ตอนนี้การป้องกันตัวประมวลผลเปิดอยู่ทุกรายการ หากเก็บการป้องกันไว้ ทุกรายการจะยังเปิดอยู่
change-auto-updates-default = Atlas จะให้ Windows ติดตั้งการอัปเดตโดยอัตโนมัติอีกครั้ง
change-hibernation-on = Atlas จะเปิดไฮเบอร์เนตอีกครั้ง
change-power-saving-on = Atlas จะเปิดการประหยัดพลังงานอีกครั้ง และกลับไปใช้แผนการใช้พลังงานเดิมของคุณ หรือใช้แผน สมดุล หากไม่มีแผนเดิม
change-core-isolation-on = Atlas จะเปิดความปลอดภัยที่ใช้การจำลองเสมือน (VBS) อีกครั้ง เว้นแต่จะมีนโยบายในพีซีเครื่องนี้ควบคุมอยู่ โดยจะมีผลหลังรีสตาร์ต
change-remove-snipping-tool = นำเครื่องมือสนิปออกสำหรับผู้ใช้ทุกคนในพีซีเครื่องนี้ Atlas จะนำกลับมาภายหลังไม่ได้ แต่คุณติดตั้งอีกครั้งได้จาก Microsoft Store
fixed-uninstall-edge = Microsoft Edge ถูกนำออกไปแล้ว และการอัปเดต Atlas จะนำกลับมาไม่ได้ หากต้องการติดตั้งอีกครั้ง ให้ใช้ Install or Remove Edge ในโฟลเดอร์ Atlas
fixed-installed = ติดตั้ง { $app } ไว้แล้ว Atlas ไม่ถอนการติดตั้งแอป หากต้องการนำออก ให้ไปที่หน้า แอปที่ติดตั้ง ในการตั้งค่า Windows
browser-also = { $installed } จะยังติดตั้งอยู่ และ Atlas จะติดตั้ง { $browser } ให้ด้วย

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = เก็บ Microsoft Defender ไว้ (แนะนำ)
package-option-defender-enable-short = เก็บ Microsoft Defender ไว้
package-option-defender-disable = นำ Microsoft Defender ออก
package-option-mitigations-default = เก็บการป้องกันตัวประมวลผลไว้ (แนะนำ)
package-option-mitigations-default-short = เก็บการป้องกันตัวประมวลผลไว้
package-option-mitigations-disable = ปิดการป้องกันตัวประมวลผล
package-option-auto-updates-disable = ติดตั้งการอัปเดตเอง
package-option-auto-updates-default = ติดตั้งการอัปเดตโดยอัตโนมัติ
package-option-disable-hibernation = ปิดไฮเบอร์เนต
package-option-disable-power-saving = ปิดการประหยัดพลังงาน
package-option-disable-core-isolation = ปิดความปลอดภัยที่ใช้การจำลองเสมือน (VBS)
# Thai Windows localizes Snipping Tool as "เครื่องมือสนิป".
package-option-remove-snipping-tool = นำเครื่องมือสนิปออก
package-option-uninstall-edge = นำ Microsoft Edge ออก
package-option-install-another-browser = ติดตั้งเบราว์เซอร์
package-option-install-toolbox = ติดตั้ง Atlas Toolbox
package-option-install-eclean = ติดตั้ง eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender คือโปรแกรมป้องกันไวรัสที่มาพร้อมกับ Windows ให้นำออกเฉพาะเมื่อคุณเข้าใจความเสี่ยงและวางแผนจะใช้แอปป้องกันไวรัสอื่น ไม่ว่าคุณจะเลือกแบบใด Atlas จะปิด การควบคุมแอปแบบอัจฉริยะ การป้องกันฟิชชิ่งขั้นสูง และ ค้นหาอุปกรณ์ของฉัน
package-choice-mitigations-description = การป้องกันเหล่านี้ หรือที่เรียกว่ามาตรการลดความเสี่ยงด้านความปลอดภัย ช่วยรับมือกับข้อบกพร่องของตัวประมวลผล เช่น Spectre และ Meltdown รวมถึงการโจมตีที่อาศัยบั๊กในแอป แนะนำให้ใช้ค่าเริ่มต้นของ Windows
package-choice-auto-updates-description = การอัปเดต Windows มีการแก้ไขด้านความปลอดภัยรวมอยู่ด้วย คุณจะให้ Windows ติดตั้งการอัปเดตโดยอัตโนมัติหรือติดตั้งเองก็ได้ ไม่ว่าจะเลือกแบบใด Atlas จะคง Windows ไว้ที่เวอร์ชันปัจจุบัน ซึ่งจะได้รับการแก้ไขด้านความปลอดภัยจนกว่า Microsoft จะสิ้นสุดการสนับสนุนเวอร์ชันนั้นเท่านั้น นอกจากนี้ Atlas ยังปิดการอัปเดตอัตโนมัติสำหรับแอปจาก Microsoft Store ด้วย จึงควรอัปเดตแอปเหล่านั้นใน Microsoft Store
package-choice-browser-description = เลือกเบราว์เซอร์ที่ต้องการติดตั้ง โดย Atlas จะไม่เปลี่ยนการตั้งค่าเบราว์เซอร์ของคุณ

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = พีซีเครื่องนี้ไม่ได้ติดตั้ง Microsoft Defender ไว้
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = ไม่มีสวิตช์การป้องกันที่ต้องปิด
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas นำ Microsoft Defender ออกจากพีซีเครื่องนี้แล้ว
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas จะนำ Microsoft Defender กลับมาในการติดตั้งครั้งนี้
security-restore-nothing-to-turn-off = Defender ยังไม่ทำงาน จึงไม่มีสิ่งใดที่ต้องปิด หลังรีสตาร์ต ให้เปิดการป้องกันของ Defender ในแอป ความปลอดภัยของ Windows
security-banner-missing-title = ไม่พบ Microsoft Defender
security-banner-missing-message = Atlas ไม่ได้เป็นผู้นำ Defender ออก จึงนำกลับมาไม่ได้ คุณดำเนินการต่อได้ แต่พีซีของคุณจะไม่มีโปรแกรมป้องกันไวรัสจนกว่าคุณจะติดตั้งแอปป้องกันไวรัสอื่นหรือซ่อมแซม Windows
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = ปิดสวิตช์ทั้งสี่รายการนี้
security-turn-off-message = Microsoft Defender อาจขัดขวาง Atlas ระหว่างติดตั้ง หากคุณเก็บ Defender ไว้ ให้เปิดสวิตช์เหล่านี้อีกครั้งหลังติดตั้ง
# The page name in Windows Security.
security-list-title = การตั้งค่าการป้องกันไวรัสและภัยคุกคาม
security-switch-off = ปิด
security-switch-on = เปิด
security-switch-unreadable = อ่านไม่ได้
security-switch-reading = กำลังตรวจสอบ
security-all-off = ปิดทั้งหมด
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on = ยังเปิดอยู่ { $count } รายการ
security-count-unreadable = อ่านไม่ได้ { $count } รายการ
security-count-join = { $a } และ{ $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. English
# reads the same for one or several; agree with $count where your language needs to.
security-unread-switches-title =
    { $count ->
       *[other] Atlas อ่านค่า { $switches } ไม่ได้
    }
security-unread-message =
    { $count ->
       *[other] ตรวจดูให้แน่ใจว่าปิดอยู่ในแอป ความปลอดภัยของ Windows
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
       *[other] ฉันตรวจดูแล้วว่า { $switches } ปิดอยู่
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = ฉันตรวจดูในแอป ความปลอดภัยของ Windows แล้ว สวิตช์ทั้งสี่รายการปิดอยู่
security-unknown-unelevated-title = Atlas ต้องได้รับสิทธิ์จึงจะตรวจสอบการป้องกันได้
security-unknown-unelevated-message = เปิด Atlas ใหม่ในฐานะผู้ดูแลระบบเพื่อให้ Atlas ตรวจสอบการตั้งค่าของ Microsoft Defender ได้
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย
protection-tamper-why = เพื่อให้ Atlas เปลี่ยนการตั้งค่าความปลอดภัยได้
protection-realtime = การป้องกันแบบเรียลไทม์
protection-realtime-reason = การสแกนอาจบล็อกไฟล์ของ Atlas
protection-cloud = การป้องกันบนระบบคลาวด์
protection-cloud-reason = การตรวจสอบออนไลน์อาจบล็อกไฟล์ของ Atlas
protection-samples = การส่งตัวอย่างโดยอัตโนมัติ
protection-samples-why = เพื่อไม่ให้ไฟล์ของ Atlas ถูกส่งไปยัง Microsoft

## Step 4: Install

outcome-succeeded-title = ติดตั้ง Atlas แล้ว
outcome-lost-title = ยืนยันผลการติดตั้งไม่ได้
outcome-failed-title = การติดตั้งไม่เสร็จสมบูรณ์
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = พีซีของคุณไม่ตรงตามข้อกำหนดในการติดตั้ง การติดตั้งจึงไม่ได้เปลี่ยนแปลงสิ่งใด
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = พีซีของคุณไม่ตรงตามข้อกำหนดในการติดตั้ง การติดตั้งรอบนี้จึงหยุดลง รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว
# Beside common-restart-as-administrator.
result-not-elevated = Atlas ไม่มีสิทธิ์ผู้ดูแลระบบ การติดตั้งจึงไม่ได้เปลี่ยนแปลงสิ่งใด
result-not-elevated-resumed = Atlas ไม่มีสิทธิ์ผู้ดูแลระบบ การติดตั้งรอบนี้จึงหยุดลง รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas ยืนยันไม่ได้ว่า Windows และแอปจาก Store เป็นเวอร์ชันล่าสุด การติดตั้งจึงหยุดลงก่อนเปลี่ยนแปลง Windows
result-preparation-stale-resumed = Atlas ยืนยันไม่ได้ว่า Windows และแอปจาก Store เป็นเวอร์ชันล่าสุด การติดตั้งรอบนี้จึงหยุดลง รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว
result-failed-preflight = การติดตั้งหยุดลงก่อนเปลี่ยนแปลงสิ่งใด คุณลองอีกครั้งได้
result-failed-staging = การติดตั้งหยุดลงระหว่างเตรียมไฟล์ ก่อนเปลี่ยนแปลง Windows คุณลองอีกครั้งได้
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = อาจมีการเปลี่ยนแปลงบางอย่างไปแล้ว คุณลองอีกครั้งได้ หรือหากจะหยุดเพียงเท่านี้ ให้เปิดสวิตช์การป้องกันอีกครั้งในแอป ความปลอดภัยของ Windows
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = อาจมีการเปลี่ยนแปลงบางอย่างไปแล้ว คุณลองอีกครั้งได้
result-failed-resumed = การติดตั้งรอบนี้หยุดลงก่อนกำหนด แต่รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว คุณลองอีกครั้งได้ หรือหากจะหยุดเพียงเท่านี้ ให้เปิดสวิตช์การป้องกันอีกครั้งในแอป ความปลอดภัยของ Windows
result-failed-resumed-defender-removed = การติดตั้งรอบนี้หยุดลงก่อนกำหนด แต่รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว คุณลองอีกครั้งได้
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = การติดตั้งรอบนี้หยุดลงด้วยข้อผิดพลาดเดียวกับรอบก่อน การลองอีกครั้งจึงไม่น่าจะช่วย ส่งรายงานเพื่อให้ทีม Atlas หาสาเหตุ และหากจะหยุดเพียงเท่านี้ ให้เปิดสวิตช์การป้องกันอีกครั้ง
result-failed-repeated-defender-removed = การติดตั้งรอบนี้หยุดลงด้วยข้อผิดพลาดเดียวกับรอบก่อน การลองอีกครั้งจึงไม่น่าจะช่วย ส่งรายงานเพื่อให้ทีม Atlas หาสาเหตุ
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows ยังคงนำ { $apps } ออกไม่ได้ การลองอีกครั้งจึงไม่น่าจะช่วย ส่งรายงานเพื่อให้ทีม Atlas หาสาเหตุ และหากจะหยุดเพียงเท่านี้ ให้เปิดสวิตช์การป้องกันอีกครั้ง
result-failed-repeated-apps-defender-removed = Windows ยังคงนำ { $apps } ออกไม่ได้ การลองอีกครั้งจึงไม่น่าจะช่วย ส่งรายงานเพื่อให้ทีม Atlas หาสาเหตุ
result-not-started = ตัวติดตั้งไม่เริ่มทำงานภายในเวลาที่กำหนด การติดตั้งจึงไม่ได้เปลี่ยนแปลงสิ่งใด คุณลองอีกครั้งได้
result-lost = ตัวติดตั้งหยุดทำงานโดยไม่ได้รายงานผล จึงอาจมีการเปลี่ยนแปลงบางอย่างไปแล้ว คุณลองอีกครั้งได้ หรือหากจะหยุดเพียงเท่านี้ ให้เปิดสวิตช์การป้องกันอีกครั้งในแอป ความปลอดภัยของ Windows
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = ตัวติดตั้งหยุดทำงานโดยไม่ได้รายงานผล จึงอาจมีการเปลี่ยนแปลงบางอย่างไปแล้ว คุณลองอีกครั้งได้
restart-now-message = Windows กำลังรีสตาร์ตเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-stopped = ยกเลิกการรีสตาร์ตอัตโนมัติแล้ว บันทึกงานของคุณ แล้วรีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-needed = บันทึกงานของคุณ แล้วรีสตาร์ตพีซีเพื่อตั้งค่า Atlas ให้เสร็จสมบูรณ์
restart-dont-now = รีสตาร์ตภายหลัง
restart-now = รีสตาร์ตเดี๋ยวนี้
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = ยังไม่ได้เริ่มการติดตั้ง
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = Atlas ต้องการคำตอบของคุณสำหรับ { $choice }
preflight-choices-unusable = Atlas ใช้ตัวเลือกเหล่านี้ไม่ได้
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
       *[other] ตั้งแต่ Atlas ตรวจสอบพีซีของคุณ { $checks } มีสิ่งที่ต้องดำเนินการ
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = ความปลอดภัยของ Windows เปลี่ยนไปหลังจากที่คุณปิดสวิตช์: { $summary }
preflight-busy-wait = หน้าต่าง Atlas อื่นกำลังเริ่มการติดตั้ง รอสักครู่ แล้วลองอีกครั้ง
# Beside home-start-over.
preflight-taken-over-start-over = หน้าต่าง Atlas อื่นกำลังใช้การตั้งค่านี้อยู่ ดำเนินการต่อในหน้าต่างนั้น หรือเริ่มใหม่ในหน้าต่างนี้
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas ตรวจสอบไม่ได้ว่าการติดตั้งครั้งก่อนยังทำงานอยู่หรือไม่ จึงยังไม่เริ่มการติดตั้งใหม่
preflight-not-started = Atlas เริ่มตัวติดตั้งไม่ได้ การติดตั้งจึงไม่ได้เปลี่ยนแปลงสิ่งใด คุณลองอีกครั้งได้
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas เริ่มตัวติดตั้งไม่ได้ แต่รอบก่อนได้ทำการเปลี่ยนแปลงไปแล้ว คุณลองอีกครั้งได้
go-to-ready = ไปที่ เตรียมความพร้อม
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = ไปที่ ตัวเลือกของคุณ
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = ไปที่ ความปลอดภัยของ Windows
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = กลับไปที่ ติดตั้ง
output-problem-title = อ่านความคืบหน้าการติดตั้งไม่ได้
install-elevate-title = Atlas ต้องได้รับสิทธิ์จึงจะติดตั้งได้
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = เมื่อเปิด Atlas ใหม่ Windows จะขอสิทธิ์จากคุณ
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = แพ็กเกจ Atlas ยังไม่พร้อม
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = ทำขั้นตอน เตรียมความพร้อม ให้เสร็จก่อน
install-not-ready-message = Atlas ต้องตรวจสอบพีซีและอัปเดต Windows ให้เสร็จก่อนจึงจะติดตั้งได้
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = ปิดสวิตช์การป้องกันอีกครั้ง
install-switches-message = ความปลอดภัยของ Windows: { $summary }
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = พร้อมติดตั้ง
summary-setup-title = การตั้งค่า Atlas ของคุณ
summary-activation = การเปิดใช้งาน
summary-activation-ok = เปิดใช้งานแล้ว Atlas จะไม่เปลี่ยนแปลงสิ่งนี้
summary-activation-missing = ยังไม่ได้เปิดใช้งาน คุณดำเนินการต่อได้ แต่ Atlas จะไม่เปิดใช้งาน Windows ให้
summary-activation-unknown = Atlas จะไม่เปลี่ยนสถานะการเปิดใช้งาน Windows ของคุณ
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts = โดยปกติใช้เวลาประมาณ { $minutes } นาที จากนั้นพีซีของคุณจะรีสตาร์ต
summary-time-restart-yourself = โดยปกติใช้เวลาประมาณ { $minutes } นาที จากนั้นให้รีสตาร์ตพีซีของคุณ
# The check box on the card. It starts from settings-restart-automatically and applies to this install only.
summary-restart-automatically = รีสตาร์ตโดยอัตโนมัติเมื่อติดตั้งเสร็จ
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = สิ่งที่ปิดด้วย
summary-turned-off-value = การควบคุมแอปแบบอัจฉริยะ การป้องกันฟิชชิ่งขั้นสูง และ ค้นหาอุปกรณ์ของฉัน
summary-show-command = แสดงคำสั่งติดตั้ง
summary-hide-command = ซ่อนคำสั่งติดตั้ง
summary-copy-command-a11y = คัดลอกคำสั่งติดตั้ง
summary-command-unavailable = เตรียมคำสั่งติดตั้งไม่ได้ รายละเอียด: { $error }
summary-not-chosen = ยังไม่ได้เลือก
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = เปลี่ยน { $title }
summary-update-path = วิธีอัปเดต Atlas
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = กำลังเตรียมการติดตั้ง
footer-checks-blocked = แก้ไขสิ่งที่การตรวจสอบพบเพื่อดำเนินการต่อ
footer-manager-outdated = ดาวน์โหลด Atlas Manager เวอร์ชันที่ใหม่กว่าเพื่อดำเนินการต่อ
footer-need-files = รับแพ็กเกจ Atlas เพื่อดำเนินการต่อ
# Tester build variant of footer-need-files.
footer-need-package-bundled = เตรียมแพ็กเกจ Atlas ที่มาพร้อมกันเพื่อดำเนินการต่อ
footer-drivers = เลือกวิธีติดตั้งไดรเวอร์เพื่อดำเนินการต่อ
footer-windows-terms = ยอมรับข้อกำหนดสิทธิ์การใช้งานเพื่อดำเนินการต่อ
footer-updating = กำลังอัปเดต Windows และแอปจาก Store…
footer-restart = รีสตาร์ตพีซีของคุณเพื่อดำเนินการต่อ
footer-reading-security = กำลังตรวจสอบสวิตช์การป้องกัน
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = ปิดสวิตช์ทั้งสี่รายการเพื่อดำเนินการต่อ
footer-security-confirm = ยืนยันสวิตช์ที่ Atlas อ่านค่าไม่ได้เพื่อดำเนินการต่อ
footer-install-ready = บันทึกงานและปิดแอปของคุณก่อน
button-install = ติดตั้ง Atlas
log-earlier-lines = มีอีก { $count } บรรทัดก่อนหน้านี้อยู่ในไฟล์บันทึก
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (บันทึกฉบับเต็ม: { $path })

## The installing view

installing-title = กำลังติดตั้ง Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = กำลังตรวจสอบพีซีของคุณ…
installing-staging-label = กำลังคัดลอกไฟล์ของ Atlas…
installing-applying-label = กำลังตั้งค่า Windows…
installing-finishing-label = กำลังดำเนินการขั้นสุดท้าย…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = ให้พีซีเปิดอยู่และเสียบปลั๊กไว้ พีซีจะรีสตาร์ตเองเมื่อติดตั้งเสร็จ
installing-keep-on = ให้พีซีเปิดอยู่และเสียบปลั๊กไว้ แล้วรีสตาร์ตพีซีเมื่อติดตั้งเสร็จ
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = ไม่ได้หมายความว่าการติดตั้งหยุดลงแล้ว
installing-installed-title = ติดตั้ง Atlas แล้ว
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown = พีซีของคุณจะรีสตาร์ตใน { $seconds } วินาที
installing-restart-save = บันทึกงานของคุณก่อน

## The "Atlas is installed" window after the restart

installed-title-version = ติดตั้ง Atlas { $version } แล้ว
installed-title = ติดตั้ง Atlas แล้ว
installed-ready = เรียบร้อยแล้ว พีซีของคุณพร้อมใช้งานกับ Atlas
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = ดาวน์โหลดไดรเวอร์ชิปเซ็ต เครือข่าย และกราฟิกจากผู้ผลิตพีซี เมนบอร์ด หรืออุปกรณ์ของคุณ
installed-drivers-guide = เปิดคู่มือการติดตั้งไดรเวอร์
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = นำ Microsoft Defender ออกแล้ว
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas ไม่ได้นำ Defender ออก หากคุณไม่ได้ใช้แอปป้องกันไวรัสอื่น ให้ติดตั้งสักแอปเพื่อปกป้องพีซีของคุณ
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender ยังคงถูกนำออกอยู่
defender-not-restored-message = การอัปเดต Atlas ครั้งก่อนไม่ได้นำ Defender กลับมา Defender จึงไม่ได้ปกป้องพีซีของคุณ ติดตั้ง Atlas ใหม่โดยเก็บ Defender ไว้ หรือเรียกใช้ Toggle Defender จาก 7. Security > Defender ในโฟลเดอร์ Atlas
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = ตัวเลือกบางรายการไม่มีผล
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
       *[other] ตัวเลือกต่อไปนี้ยังคงเหมือนเดิม: { $choices }
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Windows Update ปิดอีกครั้งตามที่คุณเลือก
installed-update-off-message = ขณะที่ปิดอยู่ พีซีของคุณจะไม่ได้รับการอัปเดตความปลอดภัย
installed-update-paused-title = การอัปเดต Windows หยุดชั่วคราวอีกครั้งตามที่คุณเลือก
installed-update-paused-message = ขณะที่หยุดชั่วคราว พีซีของคุณจะไม่ได้รับการอัปเดตความปลอดภัย

## Settings

settings-title = การตั้งค่า
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = ลักษณะที่ปรากฏ
settings-installation = การติดตั้ง
settings-privacy = ความเป็นส่วนตัว
settings-theme = ธีมของแอป
settings-theme-system = ตาม Windows
settings-theme-light = สว่าง
settings-theme-dark = มืด
settings-theme-contrast-note = Atlas กำลังใช้สีจากธีมความคมชัดของ Windows
settings-language = ภาษา
# The setting in the Language section, and its box's name.
settings-app-language = ภาษาของแอป
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = ตาม Windows – { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = รุ่นตัวอย่าง
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = คำแปลนี้ยังไม่ได้รับการตรวจทานโดยเจ้าของภาษา
preview-notice = { $language } เป็นคำแปลรุ่นตัวอย่างและอาจมีข้อผิดพลาด
preview-notice-switch = สลับเป็นภาษาอังกฤษ
preview-notice-language = เปลี่ยนภาษา
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = Atlas เวอร์ชันนี้ไม่มีภาษาที่คุณเลือก จึงแสดงเป็นภาษาอังกฤษ โดยยังเก็บตัวเลือกของคุณไว้
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas ยังไม่รองรับภาษาที่ใช้แสดงของ Windows ของคุณ จึงแสดงเป็นภาษาอังกฤษ
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas ตรวจสอบภาษาที่ใช้แสดงของ Windows ไม่ได้ จึงแสดงเป็นภาษาอังกฤษ
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = ตัวเลข วันที่ และเวลาจะเป็นไปตามรูปแบบภูมิภาคของ Windows: { $locale }
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = ตัวเลขจะเป็นไปตามรูปแบบภูมิภาคของ Windows: { $locale } ส่วนวันที่และเวลาใช้รูปแบบมาตรฐาน เนื่องจาก Atlas ยังแสดงข้อความที่เขียนจากขวาไปซ้ายไม่ได้
settings-language-contribute = ช่วยแปล Atlas บน GitHub
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = แชร์ข้อมูลการใช้งานกับ Atlas
settings-share-usage-description = หน้าในแอปที่คุณเปิด การสร้าง ISO และการติดตั้งสำเร็จหรือไม่
settings-privacy-policy = นโยบายความเป็นส่วนตัว
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = รีสตาร์ตโดยอัตโนมัติหลังติดตั้งและอัปเดต
settings-restart-automatically-description = พีซีของคุณจะรีสตาร์ตภายในหนึ่งนาทีหลังจาก Atlas ทำงานเสร็จ และแอปที่เปิดอยู่จะปิดลง
settings-restart-locked = คุณเปลี่ยนการตั้งค่านี้ได้หลังการติดตั้งเสร็จ
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = ความช่วยเหลือ
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
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = ลบรายการโปรด ประวัติ และรหัสผ่านที่บันทึกไว้ของ Edge บนพีซีเครื่องนี้
consequence-install-another-browser = เลือกเบราว์เซอร์ด้านล่าง แล้ว Atlas จะติดตั้งให้คุณ
consequence-install-toolbox = เพิ่ม Atlas Toolbox เพื่อช่วยจัดการการตั้งค่า Atlas ของคุณ โดย Toolbox ยังอยู่ในรุ่นเบต้า บางฟีเจอร์จึงอาจยังไม่สมบูรณ์
consequence-install-eclean = เครื่องมือบำรุงรักษาจากทีมผู้สร้าง AtlasOS เพื่อดูแลพีซีของคุณให้เป็นระเบียบหลังตั้งค่า ตรวจสอบไฟล์ขยะและแอปเริ่มต้นระบบ ต้องมีบัญชีและการเชื่อมต่ออินเทอร์เน็ต

## ISO creation
iso-open = สร้าง ISO พร้อม Atlas
iso-title = สร้าง ISO พร้อม Atlas
iso-recommended = แนะนำ
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = ตั้งค่า
iso-step-create = สร้าง
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = ISO นี้สำหรับพีซีเครื่องใด
iso-target-this = พีซีเครื่องนี้
iso-target-another = พีซีเครื่องอื่น
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = ISO นี้สำหรับพีซี { $architecture }
iso-source = ISO ของ Windows
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = ดาวน์โหลดจาก Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = การดาวน์โหลด Windows
iso-download-language = ภาษา
iso-download-arch = สถาปัตยกรรม
iso-download-languages = กำลังโหลดภาษา…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = กำลังดาวน์โหลด Windows 11…
iso-download-amount = { $received } จาก { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas เชื่อมต่อบริการดาวน์โหลดของ Microsoft ไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง
iso-download-incomplete = การดาวน์โหลดไม่เสร็จสมบูรณ์ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและพื้นที่ว่าง แล้วลองอีกครั้ง
iso-download-website = ไปที่หน้าดาวน์โหลดของ Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = เลือกไฟล์ ISO
# A status pill while the files are checked, before Continue becomes available.
iso-checking = กำลังตรวจสอบ ISO ของ Windows…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = ISO ของ Windows พร้อมแล้ว, { $facts }
iso-package-latest-label = ล่าสุด
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = Atlas รุ่นล่าสุดเก่ากว่าที่ Atlas Manager นี้ใช้ได้
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = กำลังรับ Atlas เวอร์ชันล่าสุด…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas ตรวจหาเวอร์ชันล่าสุดไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = รับ ISO ของ Windows เพื่อดำเนินการต่อ
# The question on the Setup step about when the package's choices are made.
iso-mode-question = คุณต้องการกำหนดตัวเลือก Atlas เมื่อใด
iso-mode-after = หลังลงชื่อเข้าใช้
iso-mode-after-description = Atlas จะแนะนำคุณตลอดการตั้งค่าหลังจากที่คุณลงชื่อเข้าใช้
iso-mode-now = ตอนนี้
iso-mode-now-description = บันทึกไว้ใน ISO และคุณจะติดตั้ง Atlas หลังลงชื่อเข้าใช้
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = ติดตั้งให้เสร็จก่อนเดสก์ท็อปเปิดขึ้น
iso-mode-before-desktop-description = หลังจากคุณลงชื่อเข้าใช้ Atlas จะทำงานแบบเต็มหน้าจอจนกว่าจะติดตั้งเสร็จ
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = แพ็กเกจ Atlas นี้บันทึกตัวเลือกไว้ใน ISO ไม่ได้ คุณจึงต้องกำหนดตัวเลือกหลังลงชื่อเข้าใช้
iso-atlas-options = ตัวเลือก Atlas
# The line at the top of the Create step.
iso-create-intro = การสร้าง ISO จะไม่เปลี่ยนแปลงพีซีเครื่องนี้หรือ ISO ต้นฉบับของคุณ
iso-review-package = แพ็กเกจ Atlas
iso-review-output = ISO ใหม่
iso-review-edition = รุ่น
iso-review-editions = รุ่น
iso-edition = รุ่นของ Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = โปรแกรมติดตั้ง Windows จะถาม
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = ให้โปรแกรมติดตั้ง Windows ถาม
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = ยอมรับข้อกำหนดสิทธิ์การใช้งาน Windows ไว้ก่อน เพื่อให้โปรแกรมติดตั้ง Windows ไม่ต้องถาม
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = ชื่อบัญชี
iso-review-target = ติดตั้งบน
iso-review-drivers = ไดรเวอร์
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = โปรแกรมติดตั้ง Windows
iso-review-skips = ข้ามหน้าจอบัญชี Microsoft และความเป็นส่วนตัว
iso-review-skips-terms = ข้ามหน้าจอสิทธิ์การใช้งาน บัญชี Microsoft และความเป็นส่วนตัว
iso-review-network = ไดรเวอร์เครือข่าย
iso-review-network-included = ไดรเวอร์ Wi-Fi และอีเทอร์เน็ตของพีซีเครื่องนี้
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = ตอนนี้ และติดตั้งเสร็จก่อนเดสก์ท็อปเปิดขึ้น
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = ต้องใช้ { $needed } · { $drive } ว่าง { $free }
iso-destination-short = ISO ต้องใช้พื้นที่ { $needed } แต่ { $drive } มีพื้นที่ว่าง { $free } เพิ่มพื้นที่ว่าง หรือบันทึก ISO ลงในไดรฟ์อื่น
iso-destination-filesystem = { $drive } เก็บไฟล์ขนาดใหญ่ของ ISO ไม่ได้ บันทึกลงในไดรฟ์ที่ฟอร์แมตเป็น NTFS เช่น ไดรฟ์ Windows ของคุณ
iso-destination-unusable = Atlas บันทึก ISO ได้เฉพาะในโฟลเดอร์บนไดรฟ์ในพีซีเครื่องนี้
iso-create = สร้าง ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = กำลังสร้าง ISO ของคุณ…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
# "กำลัง" is added here, because the stage names also label the checklist of finished and
# upcoming stages.
iso-progress-stage = กำลัง{ $stage }…
iso-stage-read = อ่าน ISO ของ Windows
iso-stage-copy = คัดลอกไฟล์ Windows
iso-stage-add-atlas = เพิ่ม Atlas
iso-stage-master = เขียนไฟล์ ISO
iso-stage-verify = ตรวจสอบ ISO ใหม่
iso-stage-cleanup = ดำเนินการขั้นสุดท้าย
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = กำลังดำเนินการ
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = ไม่สำเร็จ
iso-stage-status-not-started = ยังไม่เริ่ม
iso-progress-keep-open = เปิด Atlas ไว้จนกว่าจะเสร็จ
iso-cancel = ยกเลิกการสร้าง
iso-cancelling = กำลังรอจุดที่ยกเลิกได้อย่างปลอดภัย
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = กำลังยกเลิก…
iso-cancelled = ยกเลิกการสร้าง ISO แล้ว
iso-cancelled-unchanged = ISO ต้นฉบับของคุณไม่ได้เปลี่ยนแปลง
iso-complete = ISO พร้อมใช้งานแล้ว
iso-complete-backup = สำรองไฟล์ของคุณก่อนติดตั้ง Windows ใหม่จาก ISO นี้
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = สร้างไดรฟ์ USB
iso-open-folder = แสดงในโฟลเดอร์
iso-failed = สร้าง ISO ไม่สำเร็จ
# Under iso-failed, beside Try again.
iso-failed-retry = ตรวจดูให้แน่ใจว่าไฟล์ของคุณยังอยู่ในตำแหน่งที่เลือกไว้ และไดรฟ์ที่ใช้บันทึกยังเชื่อมต่ออยู่ แล้วลองอีกครั้ง
# Title while checking the files fails; the messages below say why.
iso-check-failed = ตรวจสอบไฟล์ไม่ได้
iso-check-failed-retry = ตรวจดูให้แน่ใจว่า ISO และแพ็กเกจ Atlas ดาวน์โหลดเสร็จแล้ว แล้วลองอีกครั้ง
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas เตรียมโฟลเดอร์ทำงานไม่ได้ จึงไม่มีการเปลี่ยนแปลงใด
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = ISO นี้ไม่มีรุ่นที่ Atlas รองรับ
iso-edition-unsupported = ไม่รองรับ Windows Home และ LTSC ให้ใช้ ISO ที่มีรุ่น Pro, Education หรือ Enterprise
iso-customised-title = ISO นี้ผ่านการปรับแต่งมาแล้ว
iso-customised = ISO นี้มีไฟล์ตั้งค่าการติดตั้งอยู่แล้ว เช่น autounattend.xml ให้ใช้ ISO จาก Microsoft ที่ไม่ได้ดัดแปลง
iso-preview-title = ISO นี้เป็นบิลด์ตัวอย่าง
iso-preview = บิลด์ Windows ของ ISO นี้ไม่อยู่ในรายการรุ่นเผยแพร่สาธารณะของ Microsoft ให้ใช้ ISO จาก Microsoft
iso-windows-unsupported-title = แพ็กเกจ Atlas นี้ใช้ ISO นี้ไม่ได้
iso-windows-unsupported = ใช้ ISO ของ Windows 11 ที่ไม่ได้ดัดแปลง สำหรับเวอร์ชันที่แพ็กเกจรองรับ
iso-release-unknown-title = Atlas ยืนยันรุ่นเผยแพร่ของ Windows นี้ไม่ได้
iso-release-unconfirmed = Atlas จะตรวจสอบกับรายการรุ่นเผยแพร่สาธารณะของ Microsoft ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = แพ็กเกจ Atlas นี้สร้าง ISO ไม่ได้
iso-package-old = ใช้ Atlas { $minimum } ขึ้นไป
iso-manager-missing-title = ไม่พบไฟล์ของ Atlas Manager
iso-fix-package = เลือกแพ็กเกจอื่น
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = ต้องอัปเดต Atlas Manager
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas เพิ่มไดรเวอร์เครือข่ายของพีซีเครื่องนี้ลงใน ISO ไม่ได้
iso-network-skip = สร้างโดยไม่รวมไดรเวอร์
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะสร้าง ISO ได้
iso-admin-reason = ต้องใช้สิทธิ์นี้เพื่ออ่าน ISO ของ Windows และสร้าง ISO ใหม่
iso-elevation-declined = Windows ไม่ได้ให้สิทธิ์แก่ Atlas จึงยังอ่าน ISO ของ Windows ไม่ได้
# The free space ran out while the ISO was being created.
iso-failed-space = พื้นที่ว่างในไดรฟ์ปลายทางไม่พอ เพิ่มพื้นที่ว่าง หรือบันทึก ISO ใหม่ลงในไดรฟ์อื่น
# Under iso-manager-missing-title.
iso-manager-missing = ดาวน์โหลด AtlasManager.exe ไปยังโฟลเดอร์ในเครื่อง เช่น ดาวน์โหลด แล้วเปิดจากที่นั่น
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = ISO นี้ไม่มีรุ่น Windows ที่รองรับ ไม่รองรับ Windows Home และ LTSC ให้ใช้ ISO ที่มีรุ่นอื่น เช่น Pro, Education หรือ Enterprise
iso-diagnostics = เปิดโฟลเดอร์บันทึก
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas กำลังทำงานกับ Windows Update คุณดำเนินการต่อที่นี่ได้เมื่อเสร็จแล้ว
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = การบำรุงรักษา Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = ไฟล์ที่รอการแทนที่
prepare-reason-update-agent = บริการ Windows Update
prepare-reason-unknown = ไม่ได้รายงานสาเหตุ
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = หากลองอีกครั้งแล้วไม่ได้ผล ให้ติดตั้งการอัปเดตที่เหลือใน Windows Update หรือ Microsoft Store ให้เสร็จ
prepare-failed-title = การอัปเดตบางรายการไม่เสร็จสมบูรณ์
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = การอัปเดตหยุดลงก่อนรายงานผล
# Title of the bar over prepare-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = ยืนยันผลการอัปเดตไม่ได้
prepare-affected-app = แอปที่มีปัญหา
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = ปิด { $app } แล้วลองอีกครั้ง หากหาแอปไม่พบ ให้ปิดในตัวจัดการงาน
prepare-install-busy = การติดตั้งอื่นหรือการรีสตาร์ตที่จำเป็นกำลังขัดขวางการอัปเดต รอให้การติดตั้งอื่นเสร็จ รีสตาร์ตพีซีหาก Windows ขอให้รีสตาร์ต แล้วลองอีกครั้ง
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows ซ่อมแซมตัวเองไม่ได้
prepare-components-damaged = Windows รายงานความเสียหายที่ทำให้ติดตั้งการอัปเดตไม่ได้ การรีสตาร์ตอาจแก้ไขได้ และ Atlas จะดำเนินการต่อหลังจากคุณลงชื่อเข้าใช้
prepare-restart-and-retry = รีสตาร์ตแล้วลองอีกครั้ง
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows เสียหายมากเกินกว่าจะอัปเดตได้
prepare-components-unrepairable = สำรองไฟล์ของคุณ แล้วติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas กำลังทำงานด้วยบัญชีอื่นที่ไม่ใช่บัญชีที่ลงชื่อเข้าใช้ Windows อยู่ ลงชื่อเข้าใช้ Windows ด้วยบัญชีผู้ดูแลระบบ แล้วเปิด Atlas จากบัญชีนั้น จากนั้นลองอีกครั้ง
prepare-failed-store-missing = Microsoft Store ยังไม่ได้ตั้งค่าสำหรับบัญชีของคุณ เปิด Microsoft Store สักครั้ง หรือติดตั้งใหม่หากไม่มีแอปนี้ แล้วลองอีกครั้ง
prepare-failed-store-battery = Microsoft Store หยุดการอัปเดตไว้ชั่วคราวเพื่อประหยัดแบตเตอรี่ เสียบปลั๊กพีซีของคุณ แล้วลองอีกครั้ง
prepare-failed-store-network = Microsoft Store หยุดการอัปเดตไว้ชั่วคราวจนกว่าพีซีของคุณจะใช้การเชื่อมต่อที่ไม่คิดค่าบริการตามปริมาณข้อมูล เชื่อมต่อ Wi-Fi หรืออีเทอร์เน็ตที่ไม่คิดค่าบริการตามปริมาณข้อมูล แล้วลองอีกครั้ง
prepare-failed-store-timeout = แอปจาก Store ยังอัปเดตไม่เสร็จ ดาวน์โหลดรายการที่เหลือใน Microsoft Store ให้เสร็จ แล้วลองอีกครั้ง
prepare-failed-store-passes = Microsoft Store ยังมีการอัปเดตใหม่เข้ามาเรื่อย ๆ ติดตั้งการอัปเดตที่เหลือใน Microsoft Store ให้เสร็จ แล้วลองอีกครั้ง
prepare-failed-manual-updates = การอัปเดต Windows บางรายการต้องติดตั้งให้เสร็จใน Windows Update เปิด Windows Update แล้วติดตั้งการอัปเดตเหล่านั้นให้เสร็จ จากนั้นลองอีกครั้ง
prepare-failed-windows-passes = Windows Update ยังมีการอัปเดตใหม่เข้ามาเรื่อย ๆ ติดตั้งการอัปเดตที่เหลือใน Windows Update ให้เสร็จ แล้วลองอีกครั้ง
prepare-failed-windows-update-unreachable = Windows Update เชื่อมต่อเซิร์ฟเวอร์ของ Microsoft ไม่ได้ ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต รวมถึงไฟร์วอลล์ พร็อกซี หรือ VPN ที่อาจมีอยู่ แล้วลองอีกครั้ง
prepare-failed-source-linked = Atlas Manager อยู่ในโฟลเดอร์ที่ลิงก์ไว้ ปิด Atlas ย้าย Atlas Manager ไปยังโฟลเดอร์ในพีซีเครื่องนี้ แล้วเปิดจากที่นั่น
prepare-error-code = รหัสข้อผิดพลาด: { $code }
prepare-open-store = เปิด Microsoft Store
prepare-windows-search = กำลังตรวจหาการอัปเดต Windows…
prepare-percent = เสร็จไปแล้ว { $percent }% ของช่วงนี้
prepare-count = การอัปเดตที่เสร็จแล้ว: { $completed } จาก { $total }
prepare-bytes = ดาวน์โหลดแล้ว { $downloaded } จากประมาณ { $total } MB
prepare-progress-still = ไม่มีความคืบหน้ามา { $minutes } นาที การอัปเดตขนาดใหญ่อาจใช้เวลาสักพัก จึงควรเปิด Atlas ไว้
prepare-report-late = Windows ไม่ได้รายงานความคืบหน้ามาสักพัก การอัปเดตอาจยังทำงานอยู่ จึงควรเปิด Atlas ไว้
prepare-windows-download = กำลังดาวน์โหลดการอัปเดต Windows…
prepare-windows-install = กำลังติดตั้งการอัปเดต Windows…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = กำลังซ่อมแซม Windows…
prepare-windows-repair-detail = Windows รายงานความเสียหายที่อาจทำให้ติดตั้งการอัปเดตไม่ได้ การซ่อมแซมนี้อาจใช้เวลาครึ่งชั่วโมงขึ้นไป
prepare-store-search = กำลังตรวจสอบ Microsoft Store…
prepare-store-install = กำลังอัปเดต Microsoft Store และแอป…
prepare-stop = หยุดอัปเดต
prepare-start = ตรวจหาและติดตั้งการอัปเดต
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = ใช้ได้เมื่อแพ็กเกจ Atlas พร้อมแล้ว
iso-username = ชื่อบัญชีภายในเครื่อง
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = คุณจะตั้งรหัสผ่านเมื่อลงชื่อเข้าใช้ครั้งแรก
iso-username-placeholder = ชื่อของคุณ
iso-account-empty = ป้อนชื่อบัญชีภายในเครื่องเพื่อดำเนินการต่อ
iso-account-invalid = ใช้ไม่เกิน 20 อักขระ โดยไม่มีช่องว่างที่ต้นหรือท้ายชื่อ และไม่มีอักขระต่อไปนี้: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = ชื่อต้องไม่ลงท้ายด้วยจุด (.)
iso-account-reserved = Windows ใช้ชื่อนี้สำหรับบัญชีที่มีมาในระบบ เลือกชื่ออื่น
iso-terms-in-setup = โปรแกรมติดตั้ง Windows จะขอให้คุณยอมรับข้อกำหนดสิทธิ์การใช้งาน
prepare-drivers = ต้องการติดตั้งไดรเวอร์อย่างไร
prepare-drivers-auto = รับไดรเวอร์ผ่าน Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = รับไดรเวอร์ผ่าน Windows Update (แนะนำ)
prepare-drivers-auto-detail = Windows จะค้นหาไดรเวอร์สำหรับฮาร์ดแวร์ของคุณ
prepare-drivers-manual = ติดตั้งไดรเวอร์เอง
prepare-drivers-manual-detail = Windows Update จะไม่ติดตั้งไดรเวอร์ คุณจึงต้องหาไดรเวอร์จากผู้ผลิตพีซีหรืออุปกรณ์ของคุณเอง ไดรเวอร์ที่ติดตั้งไว้แล้วจะยังคงอยู่
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = ไดรเวอร์
iso-network-drivers = รวมไดรเวอร์ Wi-Fi และอีเทอร์เน็ตของพีซีเครื่องนี้
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = เลือกหลังลงชื่อเข้าใช้
prepare-network-unmetered = การอัปเดตต้องใช้การเชื่อมต่ออินเทอร์เน็ตที่ไม่คิดค่าบริการตามปริมาณข้อมูล เชื่อมต่อ Wi-Fi หรืออีเทอร์เน็ต แล้วลองอีกครั้ง
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows รายงานว่าเครือข่ายนี้ไม่มีการเข้าถึงอินเทอร์เน็ต หากเครือข่ายขอให้ลงชื่อเข้าใช้ ให้ลงชื่อเข้าใช้ก่อน หรือตรวจสอบเราเตอร์และการกรองผ่าน DNS หรือไฟร์วอลล์ที่อาจมีอยู่ แล้วลองอีกครั้ง
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = การเชื่อมต่อนี้เป็นแบบคิดค่าบริการตามปริมาณข้อมูลหรือมีขีดจำกัดข้อมูล เชื่อมต่อเครือข่ายที่ไม่คิดค่าบริการตามปริมาณข้อมูล หรือปิด การเชื่อมต่อแบบคิดค่าบริการตามปริมาณข้อมูล ในการตั้งค่าเครือข่าย แล้วลองอีกครั้ง
prepare-network-settings = เปิดการตั้งค่าเครือข่าย
iso-stage-network-drivers = เตรียมไดรเวอร์เครือข่าย
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = อะแดปเตอร์เครือข่ายของพีซีเครื่องนี้ใช้ไดรเวอร์ที่มาพร้อมกับ Windows จึงไม่จำเป็นต้องรวมไดรเวอร์ไว้ใน ISO
desktop-setup-description = ตั้งค่าพีซีให้เสร็จ ตัวเลือก Atlas ของคุณบันทึกไว้แล้ว หากจำเป็น คุณสามารถกลับไปที่ Windows ได้
desktop-setup-exit = ดำเนินการต่อใน Windows

# Windows installation USB
usb-title = สร้างไดรฟ์ USB
usb-existing = สร้างไดรฟ์ USB จาก ISO ที่มีอยู่
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = ไดรฟ์ USB
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = ISO ของ Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = ไม่มี ISO ของ Atlas ในโฟลเดอร์ ดาวน์โหลด ของคุณ
usb-iso-checking = กำลังตรวจสอบ ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas สร้างไดรฟ์ USB จาก ISO นี้ไม่ได้ ใช้ ISO ที่ Atlas สร้าง หรือ ISO ของ Windows 11 จาก Microsoft สำหรับเวอร์ชันที่ Atlas รองรับ
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO หรือ Atlas Manager อยู่ในตำแหน่งเครือข่ายหรือในโฟลเดอร์ที่ลิงก์ไว้ ย้ายไปยังโฟลเดอร์ในพีซีเครื่องนี้ เช่น ดาวน์โหลด
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = พื้นที่ว่างในไดรฟ์ Windows ไม่พอสำหรับเตรียม ISO นี้ เพิ่มพื้นที่ว่าง แล้ว Atlas จะตรวจสอบอีกครั้งเอง
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas อ่าน ISO นี้ไม่ได้ ลองอีกครั้ง หรือใช้ ISO อื่น
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = เปิดการตั้งค่าที่เก็บข้อมูล
usb-looking = กำลังค้นหาไดรฟ์ USB…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = เชื่อมต่อไดรฟ์ USB ขนาด { $size } GB ขึ้นไป
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = เล็กเกินไป ต้องมีขนาด { $size } GB ขึ้นไป
usb-drive-too-small-iso = เล็กเกินไปสำหรับ ISO นี้
usb-drive-has-iso = ISO ของคุณอยู่ในไดรฟ์นี้
usb-drive-has-app = Atlas Manager กำลังทำงานจากไดรฟ์นี้
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = สร้างไดรฟ์ USB
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = เลือกไดรฟ์ USB ก่อน
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = ลบข้อมูลใน { $drive } ({ $size }, { $letters }) หรือไม่
usb-confirm-title = ลบข้อมูลใน { $drive } ({ $size }) หรือไม่
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = ลบข้อมูลในไดรฟ์ USB ({ $size }, { $letters }) หรือไม่
usb-confirm-title-unnamed = ลบข้อมูลในไดรฟ์ USB ({ $size }) หรือไม่
usb-confirm-message = ทุกอย่างในไดรฟ์นี้จะถูกลบ ส่วน ISO ของคุณจะยังอยู่
usb-confirm-erase = ลบข้อมูลและสร้าง
usb-progress-title = กำลังสร้างไดรฟ์ USB…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = เตรียมไฟล์
usb-stage-formatting = ฟอร์แมต
usb-stage-copying = คัดลอกไฟล์
usb-stage-checking = ตรวจสอบไดรฟ์
usb-stage-ejecting = นำไดรฟ์ออก
usb-keep-open = เปิด Atlas ไว้และเชื่อมต่อไดรฟ์ไว้
usb-scan-failed-title = แสดงรายการไดรฟ์ USB ไม่ได้
usb-scan-failed-retry = Atlas อ่านไดรฟ์ที่เชื่อมต่อกับพีซีเครื่องนี้ไม่ได้ ลองอีกครั้ง
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = สร้างไดรฟ์ USB ไม่ได้
usb-complete-title = ไดรฟ์ USB ของคุณพร้อมแล้ว
# F12, F11 and Esc are key names.
usb-ready = ถอดไดรฟ์ออก สำรองไฟล์ในพีซีที่คุณจะติดตั้งใหม่ แล้วเริ่มพีซีเครื่องนั้นจากไดรฟ์ USB โดยมักเปิดเมนูบูตได้ด้วย F12, F11 หรือ Esc
# After erasing may have begun.
usb-failed-partial = ไดรฟ์ถูกเขียนไปแล้วบางส่วน ตรวจดูว่าไดรฟ์ยังเชื่อมต่ออยู่ แล้วลองอีกครั้ง
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas หยุดก่อนเปลี่ยนแปลงไดรฟ์ ลองอีกครั้ง
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = ไดรฟ์ USB เปลี่ยนไป
usb-drive-changed = ไดรฟ์ถูกถอดออกหรือเชื่อมต่อใหม่ก่อนที่ Atlas จะลบข้อมูล จึงไม่มีการเปลี่ยนแปลงใดในไดรฟ์
usb-drive-cancelled-title = ยกเลิกการสร้างไดรฟ์ USB แล้ว
usb-cancelled-partial = ไดรฟ์ยังไม่สมบูรณ์ สร้างอีกครั้งก่อนใช้งาน
usb-cancelled-unchanged = ไดรฟ์ USB ของคุณไม่มีการเปลี่ยนแปลง
usb-eject-failed-title = นำไดรฟ์ USB ออกไม่ได้
usb-eject-failed-ready = ไดรฟ์พร้อมใช้งานแล้ว ปิดไฟล์หรือหน้าต่างที่ใช้ไดรฟ์นี้อยู่ แล้วลองอีกครั้ง
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = Atlas ต้องได้รับสิทธิ์จึงจะสร้างไดรฟ์ USB ได้
usb-admin-reason = Atlas ต้องใช้สิทธิ์ผู้ดูแลระบบเพื่อลบข้อมูลและเขียนไดรฟ์
usb-elevation-declined = Windows ไม่ได้ให้สิทธิ์แก่ Atlas จึงยังเขียนไดรฟ์ USB ไม่ได้
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = ไม่รองรับ Windows 11 รุ่น Home, LTSC และ Server ให้ใช้รุ่นอื่น เช่น Pro, Education หรือ Enterprise หาก Windows ระบุรุ่นของคุณไม่ได้ ให้แก้ไขปัญหานี้ก่อนดำเนินการต่อ
install-source-title = ไม่สามารถติดตั้งได้
install-source-unsupported = อัปเดต Atlas { $source } เป็น { $target } โดยตรงไม่ได้ หากต้องการใช้เวอร์ชันนี้ ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = อัปเดต Atlas { $source } โดยตรงไม่ได้ หากต้องการใช้เวอร์ชันที่ใหม่กว่า ให้สำรองไฟล์ของคุณแล้วติดตั้ง Windows ใหม่
# $folder is a folder path (text).
install-source-resume-package = การติดตั้ง Atlas { $target } ยังไม่เสร็จ และมีเพียงแพ็กเกจ Atlas { $target } เท่านั้นที่ติดตั้งให้เสร็จได้ เปิดแพ็กเกจ Atlas (.atlaspkg) นั้น หาก Atlas ดาวน์โหลดไว้ แพ็กเกจจะอยู่ใน { $folder }
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = การติดตั้ง Atlas { $target } ยังไม่เสร็จ รุ่นทดสอบนี้ติดตั้งได้เฉพาะแพ็กเกจ Atlas ที่มาพร้อมกัน จึงต้องติดตั้งให้เสร็จด้วยแพ็กเกจ Atlas { $target } ใน Atlas Manager รุ่นเผยแพร่
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas ยืนยันไม่ได้ว่ามีอะไรติดตั้งอยู่แล้วบนพีซีเครื่องนี้ จึงจะยังไม่ติดตั้งสิ่งใดในตอนนี้
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = ในโปรแกรมติดตั้ง Windows ให้เลือกรุ่นที่คุณมีสิทธิ์การใช้งาน
detail-windows-preview = ไม่รองรับบิลด์ Insider ให้ใช้ Windows 11 รุ่นที่เผยแพร่ทั่วไป
detail-windows-release-unknown = Atlas ยืนยันไม่ได้ว่าบิลด์ Windows นี้เป็นรุ่นที่เผยแพร่ทั่วไป เชื่อมต่ออินเทอร์เน็ต แล้วตรวจสอบอีกครั้ง
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = บิลด์ { $build } ไม่อยู่ในรายการรุ่นเผยแพร่สาธารณะของ Windows 11 ที่ Microsoft ระบุไว้ จึงยังติดตั้ง Atlas บนบิลด์นี้ไม่ได้ ไม่รองรับ Release Preview และบิลด์ตัวอย่างอื่น ๆ ตรวจสอบอีกครั้งเมื่อ Microsoft เพิ่มบิลด์นี้ในรายการแล้ว


prepare-continue = อัปเดตต่อ
prepare-saving-restart = กำลังบันทึกตัวเลือกของคุณและตั้งค่าให้ Atlas เปิดขึ้นอีกครั้งหลังจาก Windows รีสตาร์ต…
prepare-restart-save-failed = บันทึกตัวเลือกของคุณไม่ได้ ลองอีกครั้งก่อนรีสตาร์ต
prepare-restart-registration-failed = ตัวเลือกของคุณบันทึกไว้แล้ว แต่ Atlas ตั้งค่าให้เปิดขึ้นอีกครั้งหลังรีสตาร์ตไม่ได้ ลองอีกครั้ง หรือรีสตาร์ตพีซีด้วยตนเองแล้วเปิด Atlas หลังจากลงชื่อเข้าใช้
prepare-restart-source-linked = ตัวเลือกของคุณบันทึกไว้แล้ว แต่ขณะที่ Atlas Manager อยู่ในโฟลเดอร์ที่ลิงก์ไว้ Atlas จะตั้งค่าให้เปิดขึ้นอีกครั้งหลังรีสตาร์ตไม่ได้ ปิด Atlas แล้วย้าย Atlas Manager ไปยังโฟลเดอร์ในพีซีเครื่องนี้ จากนั้นเปิดจากที่นั่น หรือรีสตาร์ตพีซีด้วยตนเองแล้วเปิดจากที่นั่นหลังจากลงชื่อเข้าใช้
prepare-restart-failed = Atlas รีสตาร์ตพีซีของคุณไม่ได้ ลองอีกครั้ง หรือรีสตาร์ตจากเมนูเริ่ม ตัวเลือกของคุณบันทึกไว้แล้ว และ Atlas จะเปิดขึ้นอีกครั้งหลังจากคุณลงชื่อเข้าใช้
diagnostics-export = ส่งออกข้อมูลการวินิจฉัย
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = กำลังรวบรวมข้อมูลการวินิจฉัย…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = รับความช่วยเหลือ
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = บันทึกข้อมูลการวินิจฉัยแล้ว
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = บันทึกเป็น { $file } ในโฟลเดอร์ { $folder } ของ Atlas
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas ลบชื่อผู้ใช้ ชื่อพีซี ที่อยู่อีเมล และรหัสผ่านหรือคีย์ที่ตรวจพบได้ออกจากไฟล์นี้แล้ว
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = บันทึกไฟล์ ZIP ข้อมูลการวินิจฉัยไม่ได้

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } รุ่นทดสอบ แอปนี้ติดตั้งเฉพาะแพ็กเกจ Atlas ที่มาพร้อมกันเท่านั้น
home-status-bundled = รุ่นทดสอบ { $release }
package-bundled = Atlas { $version } ที่มาพร้อมรุ่นทดสอบนี้พร้อมติดตั้งแล้ว
rc-about-release = รุ่นทดสอบ
rc-about-commit = คอมมิตต้นทาง
rc-about-package = แพ็กเกจ Atlas ที่มาพร้อมกัน (SHA-256)
iso-package-bundled = แพ็กเกจ Atlas ที่มาพร้อมรุ่นทดสอบนี้

check-user-account = บัญชีผู้ใช้
detail-user-account-ok = เปิดใช้งาน UAC แล้ว และบัญชีของคุณพร้อมสำหรับการติดตั้ง
detail-user-account-not-ready = เปิดการควบคุมบัญชีผู้ใช้ (UAC) รีสตาร์ตพีซี แล้วลองอีกครั้ง หากคุณใช้บัญชี Administrator ที่มีมาในระบบ ให้ลงชื่อเข้าใช้ด้วยบัญชีผู้ดูแลระบบอื่น
detail-user-account-work-or-school = ไม่สามารถติดตั้ง Atlas จากบัญชีที่ทำงานหรือโรงเรียน (Microsoft Entra ID) ได้ ลงชื่อเข้าใช้ด้วยบัญชีภายในเครื่องหรือบัญชี Microsoft แล้วลองอีกครั้ง
detail-user-account-check-failed = Atlas ตรวจสอบบัญชีผู้ใช้ของคุณไม่ได้ รีสตาร์ตพีซีของคุณ จากนั้นเปิด Atlas อีกครั้งแล้วตรวจสอบใหม่ Windows รายงานว่า: { $error }

footer-prepare-required = อัปเดต Windows และแอปจาก Store ให้เสร็จเพื่อดำเนินการต่อ
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = กำลังจะหยุดอัปเดตหลังจากช่วงปัจจุบันเสร็จ…
resume-choices-title = ดำเนินการติดตั้งครั้งก่อนต่อ
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = Atlas จะใช้ตัวเลือกที่คุณเลือกไว้ครั้งก่อนเพื่อติดตั้งให้เสร็จ จึงเปลี่ยนตัวเลือกไม่ได้จนกว่าจะเสร็จ

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
report-message = ข้อความของคุณ
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = เกิดอะไรขึ้น และคุณกำลังทำอะไรอยู่
report-message-placeholder-suggestion = คุณอยากให้เปลี่ยนอะไร
# Under the message box, which also reads it out.
report-message-help = อย่าใส่รหัสผ่าน
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } จาก { $max } อักขระ
report-contact = ข้อมูลติดต่อ (ไม่บังคับ)
report-contact-placeholder = อีเมลหรือชื่อผู้ใช้ Discord
report-attach = แนบข้อมูลการวินิจฉัย
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = ไฟล์บันทึกและรายละเอียดระบบที่ช่วยหาสาเหตุ Atlas จะลบชื่อผู้ใช้ ชื่อพีซี ที่อยู่อีเมล และรหัสผ่านหรือคีย์ที่ตรวจพบได้ออก แต่จะเก็บรายละเอียดข้อผิดพลาด รุ่นฮาร์ดแวร์ และชื่อแอปไว้ คุณตรวจทานไฟล์ ZIP ได้ก่อนส่ง
report-review = ตรวจทาน ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = เตรียมข้อมูลการวินิจฉัยไม่ได้
report-prepare-failed-advice = ลองอีกครั้ง หรือส่งโดยไม่แนบข้อมูลการวินิจฉัย
report-privacy = รายงานของคุณจะส่งถึงทีม Atlas แบบส่วนตัวที่ reports.atlasos.net โดยข้อความและข้อมูลติดต่อของคุณจะถูกส่งไปตามที่เขียนไว้ ทีมอาจใช้บริการ AI ของบริษัทอื่นเพื่อช่วยตรวจสอบปัญหา บริการเหล่านี้จะได้รับข้อความและข้อมูลการวินิจฉัยของคุณ แต่จะไม่ได้รับข้อมูลติดต่อของคุณ รายงานจะถูกลบหลังจาก 90 วัน และบันทึกความปลอดภัยของเซิร์ฟเวอร์อาจเก็บที่อยู่ IP ของคุณไว้
report-website = ความเป็นส่วนตัวและเว็บไซต์รายงาน
report-consent = ฉันยินยอมส่งรายงานนี้และข้อมูลการวินิจฉัยที่แนบมาไปยังทีม Atlas
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง หรือส่งจากเว็บไซต์รายงานก็ได้
report-not-sent-busy = บริการรายงานไม่ว่างในขณะนี้ รอสองสามนาที แล้วลองอีกครั้ง
report-not-sent-outdated = Atlas Manager เวอร์ชันนี้ส่งรายงานไม่ได้ คัดลอกข้อความของคุณไปวางในเว็บไซต์รายงาน พร้อมไฟล์ ZIP หากคุณแนบข้อมูลการวินิจฉัยไว้
report-not-sent-diagnostics = ส่งข้อมูลการวินิจฉัยไม่ได้ ลองอีกครั้ง หรือส่งโดยไม่แนบข้อมูลการวินิจฉัย
# The footer's button where this version can't send.
report-failed-website = เปิดเว็บไซต์รายงาน
# Beside a spinner in the footer while the report is on its way.
report-sending = กำลังส่ง…
report-send = ส่งรายงาน

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = กรอกข้อความ { $min }–{ $max } อักขระ

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = จำกัดข้อมูลติดต่อไว้ไม่เกิน { $max } อักขระ

report-validation-consent = ยืนยันว่าคุณยินยอมส่งรายงานนี้

report-failed-title = ยังไม่ได้ส่งรายงาน

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = ไฟล์และแอปของคุณจะยังอยู่
home-plan-name = การอัปเดตนี้มีสองส่วน
home-plan-windows-title = Windows 11 เวอร์ชัน { $release }
home-plan-windows-step = Atlas จะติดตั้งจาก Windows Update จากนั้นพีซีของคุณจะรีสตาร์ต
# The same step where moving is optional.
home-plan-windows-step-ask = ไม่บังคับ Atlas จะถามก่อน แล้วจึงติดตั้งจาก Windows Update และพีซีของคุณจะรีสตาร์ต
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = ติดตั้งแล้ว
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas จะอัปเดตและคงตัวเลือกของคุณไว้ จากนั้นพีซีของคุณจะรีสตาร์ต
# $date and $until are dates.
home-end-of-updates-title = Windows 11 เวอร์ชัน { $current } จะหยุดรับการอัปเดตความปลอดภัยในวันที่ { $date }
home-end-of-updates-past-title = Windows 11 เวอร์ชัน { $current } ไม่ได้รับการอัปเดตความปลอดภัยอีกต่อไป
home-end-of-updates-message = การอัปเดตเป็น Atlas { $version } จะอัปเดตพีซีเครื่องนี้เป็น Windows 11 เวอร์ชัน { $release } ด้วย ซึ่งจะได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $until }
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11 เวอร์ชัน { $release } จะได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $until }

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } ใช้ได้กับ Windows 11 Pro, Enterprise และ Education จึงติดตั้งบน { $product } ไม่ได้
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } ใช้ได้กับ Windows 11 Pro, Enterprise และ Education จึงติดตั้งบน { $product } ไม่ได้ Windows 11 เวอร์ชัน { $current } จะได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $date } และ Windows Update เปลี่ยนพีซีเครื่องนี้เป็นเวอร์ชันที่ใหม่กว่าได้
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } ใช้ได้กับ Windows 11 Pro, Enterprise และ Education จึงติดตั้งบน { $product } ไม่ได้ เวอร์ชัน { $current } ไม่ได้รับการอัปเดตความปลอดภัยแล้ว จึงควรอัปเดต Windows แม้จะไม่ใช้ Atlas
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } ต้องใช้ Windows 11 เวอร์ชัน { $releases } และ Windows Update เปลี่ยนพีซีเครื่องนี้เป็นเวอร์ชันนั้นไม่ได้ สำรองไฟล์ของคุณ แล้วติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } ต้องใช้ Windows 11 เวอร์ชัน { $releases } และ Windows Update เปลี่ยนพีซีเครื่องนี้เป็นเวอร์ชันนั้นไม่ได้

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = การตั้งค่า Windows Update ถูกเปลี่ยนไว้สำหรับการอัปเดต Atlas
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas จะคืนค่าการตั้งค่าเหล่านี้เมื่ออัปเดตเสร็จ
# When the last check found no offer yet.
home-update-access-waiting = Atlas เปิด Windows Update เพื่อเปลี่ยนพีซีเครื่องนี้เป็น Windows 11 เวอร์ชัน { $release } แต่ Windows Update ยังไม่ได้เสนอเวอร์ชันนี้
home-update-access-updating = Atlas เปิด Windows Update เพื่อติดตั้งการอัปเดต และยังติดตั้งไม่เสร็จ
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = อ่านข้อมูล Windows Update ที่ Atlas บันทึกไว้ไม่ได้
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas ไม่สามารถอ่านข้อมูลที่บันทึกไว้เกี่ยวกับการตั้งค่า Windows Update ที่ Atlas เปลี่ยน จึงจะไม่เปลี่ยนแปลงหรือคืนค่าสิ่งใด
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas คืนค่าการตั้งค่าไม่ได้
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = ติดตั้ง Atlas ให้เสร็จก่อน ช่วงสุดท้ายของการติดตั้งจะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้
home-continue-update = ดำเนินการอัปเดตต่อ
home-put-back = คืนค่าการตั้งค่า
home-putting-back = กำลังคืนค่าการตั้งค่า…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11 เวอร์ชัน { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } ไม่รองรับเวอร์ชัน { $current } Atlas จึงจะอัปเดต Windows ก่อน
# Under the title where moving is optional.
windows-optional = Atlas ใช้ได้กับทั้งสองเวอร์ชัน
# The choice's accessible name; the two answers say it.
windows-card-question = พีซีเครื่องนี้ควรใช้ Windows เวอร์ชันใด
windows-choice-move-recommended = อัปเดตเป็น Windows 11 เวอร์ชัน { $release } (แนะนำ)
# $date is when the new version stops getting security updates.
windows-choice-move-support = ได้รับการอัปเดตความปลอดภัยจนถึงวันที่ { $date }
windows-choice-keep = คงไว้ที่ Windows 11 เวอร์ชัน { $current }
windows-choice-keep-later = คงไว้ที่เวอร์ชัน { $current } คุณเปลี่ยนเวอร์ชันภายหลังได้จาก Atlas Manager
windows-card-facts = สิ่งที่จะเปลี่ยนแปลง
windows-fact-files = ไฟล์และแอปของคุณจะยังอยู่ และ Atlas จะคืนค่าทุกอย่างที่การอัปเดตยกเลิกไป
windows-fact-time = โดยปกติใช้เวลาไม่กี่นาที และนานสุด 2 ชั่วโมง จากนั้นจะรีสตาร์ต
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = นำ Windows PowerShell 2.0 และ WMIC ออก
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = วิธีย้อนกลับการอัปเดต
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = การอัปเดตหมายความว่าคุณยอมรับข้อกำหนดสิทธิ์การใช้งานซอฟต์แวร์ของ Microsoft
windows-terms-link = อ่านข้อกำหนดสิทธิ์การใช้งาน
windows-accept = ยอมรับและอัปเดต
# Once the terms are accepted, before the move starts by itself.
windows-starting = กำลังเริ่ม…
windows-starts-after-checks = จะเริ่มเมื่อผ่านการตรวจสอบ
windows-starts-after-package = จะเริ่มเมื่อ Atlas { $version } พร้อม
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = เวอร์ชัน { $release } รีเซ็ตการเปลี่ยนแปลงบางส่วนของ Atlas ซึ่ง Atlas { $version } จะนำกลับมาตามตัวเลือกเดิมของคุณ
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = คงไว้ที่ Windows 11 เวอร์ชัน { $current } หรือไม่


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas จะเปิด Windows Update ไว้ชั่วคราว
access-off = Windows Update ปิดอยู่บนพีซีเครื่องนี้ Atlas จะเปิดอีกครั้งระหว่างอัปเดต Windows
access-paused = การอัปเดต Windows ถูกหยุดชั่วคราวอยู่บนพีซีเครื่องนี้ Atlas จะยกเลิกการหยุดชั่วคราวระหว่างอัปเดต Windows
access-delayed = การอัปเดตรายเดือนถูกเลื่อนออกไปบนพีซีเครื่องนี้ Atlas จะยกเลิกการเลื่อนระหว่างอัปเดต Windows
# After the lines above.
access-back = เมื่อติดตั้ง Atlas { $version } แล้ว การตั้งค่าเหล่านี้จะกลับไปเป็นเหมือนเดิม
access-back-stop = หากคุณหยุดก่อนถึงตอนนั้น Atlas จะคืนค่าการตั้งค่าเหล่านี้ให้

prepare-reason-feature-update = Windows เวอร์ชันใหม่
prepare-reason-feature-commit = การติดตั้ง Windows เวอร์ชันใหม่ให้เสร็จ
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = กำลังรอให้ Windows Update เสนอ Windows 11 เวอร์ชัน { $release }…
windows-waiting-detail = โดยปกติใช้เวลาไม่กี่นาที และนานสุด 2 ชั่วโมง Atlas จะดำเนินการต่อเอง ระหว่างนี้คุณใช้พีซีต่อได้
windows-waited = รอมาแล้ว { $minutes } นาที
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update ไม่ได้เสนอเวอร์ชัน { $release } ภายใน 2 ชั่วโมง
windows-wait-ended = Atlas คืนค่าการตั้งค่าของคุณแล้ว ลองอีกครั้งภายหลัง หรือติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas คืนค่าการตั้งค่า Windows Update ของคุณไม่ได้
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows เตรียมการรีสตาร์ตไม่ได้
windows-commit-failed = พีซีของคุณไม่ได้รีสตาร์ต ลองอีกครั้ง

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update ยังไม่ได้เสนอเวอร์ชัน { $release }
windows-outcome-not-offered = อาจใช้เวลานานถึง 2 ชั่วโมง พีซีของคุณยังใช้เวอร์ชัน { $current } อยู่
windows-outcome-hardware-title = พีซีเครื่องนี้ไม่ตรงตามข้อกำหนดของ Windows 11
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = พีซีเครื่องนี้ไม่มี { $missing } Windows Update จึงจะไม่เสนอเวอร์ชัน { $release } สำรองไฟล์ของคุณ แล้วติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
hardware-tpm = TPM 2.0
hardware-uefi = เฟิร์มแวร์ UEFI
windows-outcome-hidden-title = เวอร์ชัน { $release } ถูกซ่อนไว้ใน Windows Update
windows-outcome-hidden = แสดงเวอร์ชันนี้อีกครั้งด้วยเครื่องมือที่คุณใช้ซ่อน แล้วลองอีกครั้ง
windows-outcome-disk-space-title = พื้นที่ว่างไม่พอ
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows ต้องใช้พื้นที่ว่าง { $needed } GB บน { $drive } แต่มีอยู่ { $free } GB Atlas จะดำเนินการต่อเองเมื่อมีพื้นที่พอ
windows-outcome-managed-title = พีซีเครื่องนี้รับการอัปเดตจากองค์กร
windows-outcome-managed = เซิร์ฟเวอร์อัปเดตขององค์กรไม่มีเวอร์ชัน { $release } ให้ Atlas จึงไม่ได้เปลี่ยนแปลงสิ่งใด ติดต่อองค์กรของคุณ หรือติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
windows-outcome-policy-title = มีบางอย่างเปลี่ยน Windows Update กลับเป็นเหมือนเดิมอยู่เรื่อย ๆ
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = { $setting } กลับเป็นค่าเดิมหลังจาก Atlas เปลี่ยน Atlas จึงอัปเดต Windows ไม่ได้ หากองค์กรจัดการพีซีเครื่องนี้อยู่ ให้ติดต่อองค์กร
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = บริการที่ปิดอยู่: { $service }
windows-outcome-blocked-service =Windows Update ต้องใช้บริการนี้ ตั้งค่าเป็น ด้วยตนเอง ในแอป บริการ แล้วลองอีกครั้ง
windows-outcome-blocked-title = มีบางอย่างทำให้ Windows Update ปิดอยู่
windows-outcome-blocked = การตั้งค่าที่ Atlas ไม่ได้เปลี่ยน ({ $setting }) ทำให้ Windows Update ทำงานไม่ได้ เปลี่ยนการตั้งค่านี้ แล้วลองอีกครั้ง
windows-outcome-rollback-title = Windows ติดตั้งเวอร์ชัน { $release } ไม่เสร็จ
windows-outcome-rolled-back =Windows ย้อนกลับไปเป็นเวอร์ชัน { $current } ไฟล์และแอปของคุณยังปกติดี
windows-outcome-components-lost-title = การเปลี่ยนแปลงบางส่วนของ Atlas หายไป
windows-outcome-components-lost = Atlas ระบุสาเหตุไม่ได้ จึงหยุดก่อนติดตั้ง Atlas { $version }
windows-outcome-build-title = Windows เปลี่ยนเวอร์ชันระหว่างอัปเดต
windows-outcome-build = คืนค่าการตั้งค่าที่ Atlas เปลี่ยนไว้ แล้วเริ่มใหม่จากหน้าหลัก
windows-outcome-journal-title = Atlas อ่านข้อมูลที่บันทึกไว้ของการอัปเดตนี้ไม่ได้
windows-outcome-journal = Atlas จะไม่เปลี่ยนแปลงหรือคืนค่าสิ่งใดจนกว่าทีม Atlas จะตรวจสอบ
windows-outcome-pin-title = บันทึกนโยบาย Windows Update ไม่ได้
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } มีค่าที่ Atlas คืนค่าภายหลังไม่ได้ Atlas จึงไม่ได้เปลี่ยนแปลงสิ่งใด
windows-outcome-terms-title = ยังไม่ได้ยอมรับข้อกำหนดสิทธิ์การใช้งาน
windows-outcome-terms = Windows Update ต้องให้คุณยอมรับก่อนจึงจะติดตั้งเวอร์ชัน { $release }
windows-outcome-failed-title = Windows ติดตั้งเวอร์ชัน { $release } ไม่ได้
windows-outcome-failed = พีซีของคุณยังใช้เวอร์ชัน { $current } อยู่
# Windows services a move needs, as Services lists them.
service-bits = บริการโอนย้ายข้อมูลอัจฉริยะเบื้องหลัง (BITS)
service-cryptsvc = บริการการเข้ารหัสลับ
service-trusted-installer = ตัวติดตั้งโมดูลของ Windows
prepare-open-services = เปิดแอป บริการ
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = คงไว้ที่เวอร์ชัน { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = หยุดอัปเดตเป็น Atlas { $version } หรือไม่
stop-update-title-windows = หยุดอัปเดต Windows หรือไม่
stop-update-before = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ การอัปเดตที่ Windows ติดตั้งไปแล้วจะยังคงอยู่ และพีซีของคุณจะยังใช้ Windows 11 เวอร์ชัน { $current }
stop-update-after = พีซีของคุณจะยังใช้ Windows 11 เวอร์ชัน { $release } และ Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้
stop-update-access = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ การอัปเดตที่ Windows ติดตั้งไปแล้วจะยังคงอยู่
stop-update-keep = อัปเดตต่อไป
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = ปิด Atlas หรือไม่
window-close-update-access-message = Atlas จะคืนค่าการตั้งค่า Windows Update ที่ Atlas เปลี่ยนไว้ก่อนปิด คุณเริ่มอัปเดตอีกครั้งได้จากหน้าหลัก
window-close-put-back = คืนค่าและปิด
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = ปิดโดยไม่คืนค่าการตั้งค่าหรือไม่
window-close-put-back-failed-message = หากปิด Atlas ตอนนี้ การตั้งค่า Windows Update จะยังเป็นตามที่ Atlas เปลี่ยนไว้ เมื่อคุณเปิด Atlas อีกครั้ง หน้าหลักจะเสนอให้คืนค่าการตั้งค่าเหล่านั้น

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = Atlas เวอร์ชันนี้ต้องใช้ Windows 11 เวอร์ชัน { $release } แต่พีซีเครื่องนี้ใช้เวอร์ชัน { $current }

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = การอัปเดต Windows สำหรับ Atlas ไม่เสร็จสมบูรณ์ รายละเอียดสำหรับทีม Atlas:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = ติดตั้งซ้ำหลังอัปเดต Windows
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = ตัวเลือกของคุณจาก Atlas { $previous }
rebase-choices-kept = Atlas จะนำตัวเลือกที่คุณเลือกไว้สำหรับ Atlas { $previous } กลับมา และคุณเปลี่ยนตัวเลือกภายหลังได้โดยติดตั้ง Atlas ใหม่
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas จะนำตัวเลือกอื่นทั้งหมดที่คุณเลือกไว้สำหรับ Atlas { $previous } กลับมา
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = รีสตาร์ตขณะที่มีผู้ใช้อื่นลงชื่อเข้าใช้อยู่หรือไม่
restart-others-question = รีสตาร์ตขณะที่มีผู้ใช้อื่นหลายคนลงชื่อเข้าใช้อยู่หรือไม่
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
       *[other] { $names } ลงชื่อเข้าใช้อยู่ด้วย การรีสตาร์ตจะปิดแอปของผู้ใช้ดังกล่าว และงานที่ยังไม่ได้บันทึกจะสูญหาย
    }
restart-others-keep = ไม่รีสตาร์ต
restart-others-restart = รีสตาร์ตต่อไป
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = กำลังอัปเดต Microsoft Store…
prepare-store-repairing = กำลังซ่อมแซม Microsoft Store…
prepare-store-repair-detail = การซ่อมแซมนี้อาจใช้เวลาสองสามนาที
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = Microsoft Store ถูกปิดไว้บนพีซีเครื่องนี้ จึงไม่ได้อัปเดตแอปจาก Store
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store ไม่ทำงาน
prepare-store-broken = Atlas ซ่อมแซมไม่ได้ และการติดตั้ง Atlas ตอนนี้อาจทำให้แอปจาก Store เสียหาย
prepare-store-broken-iso = หากการซ่อมแซมยังไม่สำเร็จ ให้สำรองไฟล์ของคุณ แล้วติดตั้ง Windows ใหม่ด้วย ISO ของ Atlas
prepare-repair-store-again = ลองซ่อมแซมอีกครั้ง

screen-keyboard-title = ภาษาของแป้นพิมพ์
screen-keyboard-question = คุณใช้แป้นพิมพ์หลายภาษาหรือไม่
package-option-keyboard-shortcuts = ใช่ ใช้แป้นพิมพ์ลัด
package-option-keyboard-selector = ใช่ ใช้ตัวเลือกบนแถบงาน
package-option-keyboard-single = ไม่ ใช้รูปแบบแป้นพิมพ์เดียว
consequence-keyboard-shortcuts = Alt+Shift สลับภาษา ส่วน Ctrl+Shift สลับรูปแบบแป้นพิมพ์
consequence-keyboard-selector = ปิด Alt+Shift และ Ctrl+Shift เพื่อป้องกันการสลับโดยไม่ตั้งใจขณะเล่นเกม
package-choice-keyboard-description = เลือกวิธีสลับภาษาของแป้นพิมพ์
consequence-keyboard-single = { consequence-keyboard-selector }
