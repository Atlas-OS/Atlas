### Atlas Manager: Bahasa Indonesia (id). Preview translation, revised on 24 November 2026 from the en-GB source; native-speaker review pending.
###
### This complete translation follows the en-GB source.
### Ids are stable identifiers, never shown to users. Comments
### above a message say where it appears and what its variables hold.
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically. Indonesian has only the "other" plural category, so
###   selectors use exact numbers ([1], [2]) or none at all; no singular
###   category exists. Nouns don't change with the count, so most messages
###   need no selector; "tersebut" keeps a reference number-neutral.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "SmartScreen", "GitHub"
###   are product names. Windows feature names should match what Windows
###   shows in Indonesian (for example the four Virus & threat protection
###   switches). "Windows Security" is "Keamanan Windows"; "Windows Update"
###   stays in English, as in Windows.
### - "Mulai ulang" is always the PC / Windows restarting; "jalankan ulang"
###   is always reopening the Atlas Manager (as in "Jalankan sebagai administrator").
### - Buttons are verb-first and short. Sentences end with a full stop;
###   titles and labels do not. Address the user as "Anda".
### - The .atlaspkg file is "paket Atlas", then "paket". The install steps are
###   Persiapan, Pilihan Anda, Keamanan Windows and Instal; the ISO steps are
###   Windows, Penyiapan and Buat. "Penyiapan Windows" is Windows Setup.
### - The protection switches are "pengaturan perlindungan"; they are
###   nonaktifkan (turned off) and aktifkan kembali (turned back on).
### - Licence terms are "ketentuan lisensi". Buttons that open a step say
###   "Buka langkah …", so they differ from "Buka Keamanan Windows" (the app).

## Shared

app-name = Atlas Manager
common-done = Selesai
common-cancel = Batal
common-back = Kembali
common-next = Lanjutkan
common-dismiss = Tutup
# Link beside a summary row that jumps back to change that choice.
common-change = Ubah
common-copy = Salin
# Shown where a list of options is empty.
common-none = Tidak ada
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Kembali ke beranda
# Accessible name of the gear button in the title bar.
common-settings = Pengaturan
common-close-settings = Tutup pengaturan
common-open-windows-security = Buka Keamanan Windows
common-restart-as-administrator = Jalankan ulang sebagai administrator
common-try-again = Coba lagi
common-read-the-docs = Baca panduan Atlas
common-show-details = Tampilkan detail
common-hide-details = Sembunyikan detail
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Buka folder log
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Salin log penginstalan
common-install-log = Log penginstalan
# Row labels in summary cards.
common-windows = Windows
common-package = Paket Atlas
common-checking = Memeriksa
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } atau { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } dan { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Tutup jendela saat Atlas sedang diinstal?
window-close-installing = Penginstalan tetap berjalan. Buka Atlas lagi untuk melihat hasilnya.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = Penginstalan tetap berjalan, tetapi PC Anda tidak akan dimulai ulang dengan sendirinya. Buka Atlas lagi untuk melihat hasilnya.
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = Biarkan terbuka
window-close-close = Tutup jendela
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Hentikan sebelum menginstal?
window-close-checks-unchanged = Penginstalan belum mengubah apa pun. Jika Anda menutup jendela, Atlas tidak akan memulainya.
window-close-keep-installing = Lanjutkan penginstalan
window-close-stop-and-close = Hentikan dan tutup
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = Hentikan pembaruan?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas akan berhenti setelah tahap saat ini. Setelah itu, Anda dapat menutupnya.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = Mulai ulang untuk menyelesaikan penyiapan Atlas?
window-close-restart-closed = Atlas tidak dapat memulai ulang PC Anda setelah ditutup. Simpan pekerjaan Anda terlebih dahulu.
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = Mulai ulang untuk menyelesaikan pembaruan?
window-close-update-restart-later = Simpan pekerjaan Anda terlebih dahulu. Jika Anda memulai ulang nanti, Atlas akan melanjutkan setelah PC dimulai ulang.
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = Tutup Atlas saat perlindungan masih nonaktif?
window-close-protection-all = Keempat pengaturan perlindungan Keamanan Windows sedang nonaktif. Jika Anda tidak menginstal Atlas sekarang, aktifkan kembali terlebih dahulu.
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
       *[other] { $switches } nonaktif di Keamanan Windows. Jika Anda tidak menginstal Atlas sekarang, aktifkan kembali terlebih dahulu.
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = Hentikan pembuatan ISO?
iso-close-safe-point = Atlas akan berhenti pada titik aman berikutnya.
usb-close-question = Hentikan pembuatan drive USB?
usb-close-unfinished = Drive yang belum selesai tidak dapat menginstal Windows.
window-close-keep-creating = Lanjutkan pembuatan
window-close-stop = Hentikan
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Buka paket Atlas (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas sudah terinstal. Windows dimulai ulang untuk menyelesaikan penyiapan.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas memulai ulang Windows untuk menyelesaikan penginstalan pembaruan.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (build { $build })

## Home page

home-not-installed = Selamat datang di Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas mengurangi aktivitas latar belakang dan gangguan di Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas di PC ini
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = Diinstal pada { $date }
home-status-checking = Memeriksa pembaruan…
# While startup checks whether another window's installation is running.
home-status-recovering = Memeriksa penginstalan yang berjalan
home-status-offline = Tidak dapat memeriksa pembaruan
home-status-not-checked = Pembaruan belum diperiksa
home-status-update = Atlas { $version } tersedia
home-status-up-to-date = Sudah versi terbaru
home-status-newest = Versi terbaru: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Penginstalan Atlas { $version } belum selesai
home-check-again = Periksa lagi
# Primary button while an install is running or waiting.
home-show-install = Lihat kemajuan
home-continue-installing = Lanjutkan penyiapan
home-update-to = Perbarui ke Atlas { $version }
home-reinstall = Instal ulang Atlas
home-install = Instal Atlas
home-finish-install = Selesaikan penginstalan Atlas { $version }
home-start-over = Mulai dari awal
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = Instal Atlas di PC ini?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = Aplikasi dan pengaturan yang sudah ada mungkin tidak berfungsi lagi, dan Atlas menghapus OneDrive, sehingga file di dalamnya berhenti disinkronkan dan folder mungkin tampak kosong. Cadangkan file Anda terlebih dahulu.
home-used-windows-install = Tetap instal
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Instal ulang Windows dengan Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Windows di PC ini sudah pernah digunakan, dan Atlas bekerja paling baik pada instalasi Windows yang baru.
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = PC Anda perlu dimulai ulang
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas tidak dapat memulai ulang PC Anda. Mulai ulang PC melalui menu Mulai.
home-security-reminder-title = Aktifkan kembali perlindungan Anda
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Pastikan perlindungan Anda aktif
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
       *[other] Pengaturan berikut masih nonaktif di Keamanan Windows: { $switches }.
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas tidak dapat membaca semua pengaturan perlindungan. Pastikan pengaturan berikut aktif di Keamanan Windows: { $switches }.
home-elevation-title = Atlas memerlukan izin untuk menginstal
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas tidak dapat menyimpan pilihan penyiapan Anda, sehingga Atlas belum dijalankan ulang.
home-state-error-title = Tidak dapat membaca detail penginstalan Atlas Anda
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = Versi Atlas, pilihan, dan riwayat Anda mungkin tidak ditampilkan dengan benar.
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager perlu diperbarui
home-whats-new = Yang baru di Atlas { $version }
home-view-release = Lihat catatan rilis di GitHub
home-show-less = Tampilkan lebih sedikit
home-show-full-notes = Tampilkan semua catatan rilis
home-your-install = Penyiapan Atlas Anda
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = PC ini tidak memiliki catatan tentang cara Atlas diinstal, sehingga pilihan dan riwayat penginstalan Anda tidak dapat ditampilkan.
home-history = Riwayat penginstalan
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Langkah { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = Yang akan terjadi
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Menyiapkan Atlas
# Beside step-ready in that card.
home-step-ready = Atlas memeriksa PC Anda dan memperbarui Windows.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas memeriksa PC Anda dan meningkatkan Windows ke versi { $release }.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Anda memilih apa yang ingin dipertahankan, seperti Microsoft Defender.
# Beside step-security in that card.
home-step-security = Anda menonaktifkan keempat pengaturan perlindungan Keamanan Windows.
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts = Penginstalan biasanya memakan waktu sekitar { $minutes } menit, lalu PC Anda dimulai ulang.
home-step-install-restart-yourself = Penginstalan biasanya memakan waktu sekitar { $minutes } menit, lalu mulai ulang PC Anda.
# At the bottom of that card, under the four steps.
home-steps-save-work = Simpan pekerjaan Anda terlebih dahulu: aplikasi mungkin ditutup dan PC Anda akan dimulai ulang.
home-github = Lihat Atlas di GitHub
home-discord = Bergabung dengan komunitas Atlas
home-report-problem = Laporkan masalah

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = penginstalan pertama
history-mode-upgrade = pembaruan
history-mode-reapply = penginstalan ulang
history-mode-unknown = penginstalan

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas menggunakan pengaturan aplikasi bawaan
notice-settings-unreadable-problem = Atlas tidak dapat membaca pengaturan aplikasi yang tersimpan. Pengaturan Windows Anda tidak berubah.
notice-settings-damaged-kept-problem = File pengaturan aplikasi rusak, sehingga Atlas mengatur ulang file tersebut dan menyimpan salinan file lama.
notice-settings-damaged-problem = File pengaturan aplikasi rusak. Atlas menggunakan pengaturan bawaan untuk sementara.
notice-settings-not-saved-title = Tidak dapat menyimpan pengaturan aplikasi
notice-settings-not-saved-problem = Atlas tidak dapat menyimpan perubahan terbaru Anda, sehingga perubahan tersebut mungkin hilang saat Atlas ditutup. Jika ada jendela Atlas lain yang terbuka, tutup jendela tersebut, lalu lakukan perubahan lagi.
notice-session-unreadable-title = Tidak dapat memeriksa penginstalan sebelumnya
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas tidak dapat memastikan apakah penginstalan sebelumnya masih berjalan. Jika Anda yakin tidak ada, hapus catatan penginstalannya, lalu jalankan ulang Atlas.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas tidak dapat memastikan apakah penginstalan sebelumnya masih berjalan. Jika Anda tidak yakin, minta bantuan komunitas Atlas. Hapus { $path } dan coba lagi hanya jika Anda yakin tidak ada penginstalan yang berjalan. Detail: { $error }

## Administrator elevation

elevation-declined = Izin tidak diberikan. Coba lagi, lalu pilih Ya saat Windows menanyakan apakah Atlas boleh membuat perubahan.
elevation-declined-continue = Izin tidak diberikan. Coba lagi, lalu pilih Ya saat Windows menanyakan apakah Atlas boleh membuat perubahan. Pilihan penyiapan Anda sudah disimpan.
elevation-draft-not-saved = Atlas tidak dapat menyimpan pilihan penyiapan Anda, sehingga aplikasi belum dijalankan ulang. Coba lagi. Detail: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Jendela Atlas lain kini menggunakan penyiapan ini, sehingga Atlas belum dijalankan ulang. Lanjutkan di jendela tersebut, atau pilih Mulai dari awal untuk mengulang penyiapan di sini.

## The install flow

step-ready = Persiapan
step-options = Pilihan Anda
step-security = Keamanan Windows
step-install = Instal
install-title = Siapkan Atlas
# Accessible name of the row of steps.
stepper-label = Langkah penyiapan Atlas
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = selesai
stepper-status-current = langkah saat ini
stepper-status-upcoming = belum dimulai
# A step already visited whose requirements aren't met yet.
stepper-status-attention = perlu diperhatikan
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = Langkah { $number } dari { $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }. { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = Periksa PC Anda
# Status line while the checks run.
ready-checks-running = Memeriksa PC Anda…
ready-check-again = Periksa lagi
# Status line once every check passed; common-show-details lists them.
ready-checks-passed = { $count } pemeriksaan berhasil
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
ready-checks-passed-some = { $passed } dari { $total } pemeriksaan berhasil
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of.
ready-checks-handled = { $count } diatasi oleh pembaruan
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = diatasi oleh pembaruan
# Under the title of a check that updating takes care of.
check-updates-handled = Ada pembaruan yang menunggu. Atlas menginstalnya saat memperbarui Windows.
check-restart-handled = Windows perlu dimulai ulang untuk menyelesaikan perubahan sebelumnya. Ini akan diatasi oleh pembaruan.
check-handled = Ini akan diatasi oleh pembaruan.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Mengunduh…
ready-package-unpacking = Mengekstrak…
ready-package-ready = Siap
ready-package-checking = Memeriksa versi terbaru…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Menyiapkan paket Atlas bawaan…
ready-package-none = Belum diunduh
ready-package-failed = Tidak dapat memperoleh paket Atlas
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = Unduh lagi, atau buka paket Atlas (.atlaspkg) lain.
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = Paket Atlas bawaan versi uji ini tidak dapat diekstrak. Coba lagi.
ready-package-manager = Perlu Atlas Manager versi baru
ready-package-release-failed = Tidak dapat memeriksa versi terbaru
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Periksa koneksi internet Anda, lalu coba lagi. Jika Anda memiliki paket Atlas (.atlaspkg), Anda dapat membukanya sebagai gantinya.
# Row title.
ready-updates-title = Pembaruan Windows dan Microsoft Store
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Aplikasi Store seperti Notepad mungkin ditutup saat diperbarui. Simpan pekerjaan Anda di aplikasi tersebut terlebih dahulu.
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Dimulai setelah Windows ditingkatkan ke versi { $release }.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Melanjutkan setelah PC dimulai ulang…
ready-updates-restarting = Memulai ulang PC Anda…
ready-updates-done = Windows dan aplikasi Store sudah diperbarui.
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows sudah diperbarui.
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown = PC Anda akan dimulai ulang dalam { $seconds } detik.
ready-updates-restart = PC Anda perlu dimulai ulang untuk menyelesaikan pembaruan.
ready-updates-restart-finish = Windows perlu dimulai ulang sekali lagi untuk menyelesaikan penginstalan versi { $release }.
ready-updates-restart-failed = PC Anda tidak dimulai ulang
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Simpan pekerjaan Anda terlebih dahulu.
ready-updates-restart-persists = Windows masih meminta untuk dimulai ulang
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Memulai ulang lagi kemungkinan tidak akan membantu. Selesaikan apa pun yang menunggu di Windows Update, lalu coba lagi.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Alasan mulai ulang: { $reasons }
ready-updates-network = Pembaruan tidak dapat menggunakan koneksi ini
ready-updates-stopped = Pembaruan dihentikan. Beberapa pembaruan mungkin sudah terinstal.
ready-updates-previous = Menunggu pembaruan yang dimulai sebelumnya…
# Button after the user stopped updating.
ready-updates-resume = Lanjutkan pembaruan
ready-updates-start = Mulai pembaruan
# Why updating hasn't started, under the row.
ready-updates-blocked = Pembaruan menunggu hingga Atlas dapat diinstal di PC ini.
ready-updates-needs-admin = Dimulai setelah Atlas mendapatkan izin administrator.
ready-updates-needs-windows = Dimulai setelah pemeriksaan Kompatibilitas Windows berhasil.
ready-updates-needs-drivers = Dimulai setelah Anda menentukan cara driver diinstal.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = Driver: { $choice }
ready-drivers-automatic = Melalui Windows Update
ready-drivers-manual = Instal sendiri
ready-drivers-change-a11y = Ubah cara driver diinstal
# Under the two answers, once updating has run.
ready-drivers-again = Mengubah pilihan ini akan menjalankan pembaruan lagi.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Mengunduh Atlas { $version } · { $received } dari { $total } MB
package-unpacking = Mengekstrak
package-status-ready = Siap
# Accessible name of the progress bar.
package-progress = Kemajuan paket Atlas
package-download-again = Unduh lagi
package-download-version = Unduh Atlas { $version }
package-download-newest = Unduh versi terbaru
package-cancel-download = Batalkan unduhan
package-open-file = Buka file paket
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } telah diunduh dari GitHub dan siap diinstal.
package-from-file = Atlas { $version } telah dimuat dari { $file } dan siap diinstal.
package-unpacked = Atlas { $version } siap diinstal.
package-none-yet = Belum ada paket Atlas
acquire-no-asset = Atlas { $version } tidak memiliki file paket yang dapat diunduh. Buka paket Atlas (.atlaspkg) yang tersimpan untuk melanjutkan.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Aplikasi ini dapat menginstal Atlas 0.6.0 dan yang lebih baru dari paket Atlas (.atlaspkg).
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = Ini adalah ISO Windows, bukan paket Atlas (.atlaspkg). Untuk menginstal ulang Windows dengan Atlas, buat ISO Atlas dengan file ini.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } tidak berisi file yang diperlukan aplikasi ini untuk menginstalnya. Unduh lagi, atau buka paket Atlas (.atlaspkg) lain.
acquire-failed = Tidak dapat menyiapkan paket Atlas. Unduh lagi, atau buka paket Atlas (.atlaspkg) lain. Detail: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Unduhan berhenti merespons. Periksa koneksi internet Anda, lalu unduh lagi, atau buka paket Atlas (.atlaspkg) yang tersimpan.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Tidak dapat menyiapkan paket Atlas bawaan. Pilih Coba lagi. Detail: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = Paket Atlas ini memerlukan versi Atlas Manager yang lebih baru. Unduh Atlas Manager { $version } atau yang lebih baru, lalu gunakan sebagai pengganti versi ini.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Paket Atlas ini memerlukan versi Atlas Manager yang lebih baru. Unduh Atlas Manager versi terbaru, lalu gunakan sebagai pengganti versi ini.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = Untuk menginstal Atlas { $version }, unduh Atlas Manager { $required } atau yang lebih baru, lalu gunakan sebagai pengganti versi ini.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Untuk menginstal Atlas { $version }, unduh Atlas Manager versi terbaru, lalu gunakan sebagai pengganti versi ini.

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Unduh Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } tersedia
manager-update-message = Atlas Manager tidak dapat memperbarui dirinya sendiri. Unduh versi baru dan gunakan sebagai pengganti versi ini.

## System checks

check-administrator = Izin penginstalan
check-supported-build = Kompatibilitas Windows
check-pending-updates = Pembaruan Windows
check-pending-reboot = Mulai ulang yang tertunda
check-third-party-antivirus = Antivirus lain
check-internet = Koneksi internet
check-power = Daya
check-activation = Aktivasi Windows
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Perangkat keras Windows 11
check-move-space = Ruang kosong
check-move-update-source = Sumber pembaruan
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = sedang diperiksa
check-state-passed = berhasil
check-state-warning = perlu diperhatikan
check-state-failed-blocking = perlu ditangani sebelum menginstal
check-state-failed = perlu diperhatikan
check-state-unknown = tidak dapat diperiksa
check-fix-windows-update = Buka Windows Update
check-fix-network = Buka pengaturan jaringan
check-fix-power = Buka pengaturan daya
check-fix-activation = Buka pengaturan aktivasi
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = Buka pengaturan Penyimpanan
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = Buka Aplikasi yang diinstal
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Saya sudah memeriksa Windows Update dan tidak ada pembaruan yang menunggu diinstal

detail-admin-ok = Atlas memiliki izin untuk membuat perubahan yang diperlukan untuk penginstalan.
detail-admin-missing = Jalankan ulang Atlas sebagai administrator, lalu pilih Ya saat Windows meminta izin.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Versi Atlas ini memerlukan Windows build { $builds }. PC Anda menggunakan build { $build }. Instal versi Windows yang didukung sebelum melanjutkan.
detail-build-missing = Paket Atlas ini tidak mencantumkan build Windows yang didukung. Gunakan build lengkap paket ini, bukan build LocalTest.
detail-updates-none = Tidak ada pembaruan Windows yang menunggu diinstal.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left = { $count } pembaruan masih menunggu. Instal di Windows Update, lalu periksa lagi.
detail-updates-scan-failed = Tidak dapat memeriksa pembaruan Windows. Buka Windows Update untuk melihat apakah ada yang menunggu. ({ $error })
detail-reboot-none = Windows tidak perlu dimulai ulang saat ini.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows perlu dimulai ulang untuk menyelesaikan perubahan sebelumnya. Mulai ulang PC Anda, lalu periksa lagi.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows perlu dimulai ulang untuk menyelesaikan perubahan sebelumnya ({ $reasons }). Mulai ulang PC Anda, lalu periksa lagi.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Anda dapat melanjutkan. Windows akan mengganti atau menghapus beberapa file saat PC dimulai ulang berikutnya ({ $files }). Beberapa aplikasi, seperti Xbox Gaming Services, melakukan ini setelah setiap mulai ulang.
detail-reboot-unknown = Tidak dapat memeriksa apakah Windows perlu dimulai ulang. Mulai ulang PC, lalu buka kembali Atlas dan periksa lagi. ({ $error })
detail-antivirus-none = Tidak ada antivirus lain yang terdeteksi.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Aplikasi antivirus selain Microsoft Defender dapat menghalangi penginstalan. Hapus instalan { $products }, lalu periksa lagi.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Keamanan Windows masih mencantumkan { $products }, tetapi file-nya sudah tidak ada, jadi perangkat lunak ini sudah tidak terinstal lagi. Atlas tetap dapat melanjutkan penginstalan.
detail-antivirus-check-failed = Tidak dapat memeriksa apakah ada antivirus lain. Jika ini terus terjadi, mulai ulang PC Anda, lalu periksa lagi. ({ $error })
detail-internet-ok = PC terhubung ke internet. Pertahankan koneksi ini saat Atlas mengunduh dan menginstal perangkat lunak.
detail-internet-missing = Hubungkan PC ke internet, lalu periksa lagi.
detail-power-mains = PC terhubung ke sumber listrik. Biarkan tetap terhubung hingga penginstalan selesai.
detail-power-battery = Hubungkan PC ke sumber listrik agar tetap menyala selama penginstalan.
detail-power-check-failed = Atlas tidak dapat memastikan apakah PC Anda terhubung ke sumber listrik. Jika PC Anda laptop, hubungkan ke sumber listrik, lalu periksa lagi.
detail-activation-ok = Windows sudah diaktifkan. Atlas tidak akan mengubahnya.
detail-activation-missing = Windows belum diaktifkan. Anda dapat melanjutkan, tetapi Atlas tidak akan mengaktifkan Windows untuk Anda.
detail-activation-no-licence = Windows tidak melaporkan adanya lisensi. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda.
detail-activation-unknown = Tidak dapat memeriksa aktivasi Windows. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas tidak perlu meningkatkan Windows ke versi yang lebih baru di PC ini.
detail-move-hardware-ready = PC ini memiliki TPM 2.0 dan firmware UEFI yang diperlukan Windows 11.
detail-move-hardware-missing = PC ini tidak memiliki { $missing }, sehingga Windows Update tidak akan meningkatkannya ke versi { $release }. Cadangkan file Anda, lalu instal ulang Windows dengan ISO Atlas.
detail-move-hardware-unread = Atlas tidak dapat membaca semua perangkat keras PC ini, jadi Windows Update yang akan memeriksanya.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } memiliki ruang kosong { $free } GB.
detail-move-space-short = Versi { $release } memerlukan ruang kosong { $needed } GB di { $drive }, sedangkan yang tersedia { $free } GB. Kosongkan ruang, dan Atlas akan memeriksa lagi dengan sendirinya.
detail-move-space-unknown = Tidak dapat memeriksa ruang kosong untuk pembaruan Windows. Mulai ulang PC Anda, lalu periksa lagi. ({ $error })
detail-move-update-source-ok = PC ini mendapatkan pembaruan dari Windows Update.
detail-move-update-source-managed = PC ini mendapatkan pembaruan dari server organisasinya, yang tidak menawarkan versi { $release }. Tanyakan kepada organisasi Anda, atau instal ulang Windows dengan ISO Atlas.

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Anda dapat mengubah Microsoft Defender, perlindungan prosesor, dan pengaturan pembaruan nanti melalui folder Atlas di desktop.
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = Tidak ada yang dipilih
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = { $count } dipilih
# Links that unfold and fold the Optional extras card.
options-extras-show = Tampilkan
options-extras-hide = Sembunyikan
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender adalah antivirus bawaan Windows.
question-mitigations-description = Perlindungan ini, yang juga disebut mitigasi keamanan, melindungi dari celah keamanan prosesor, seperti Spectre dan Meltdown, serta serangan yang memanfaatkan bug dalam aplikasi.
question-auto-updates-description = Apa pun pilihan Anda, Atlas mempertahankan Windows pada versinya saat ini dan menonaktifkan pembaruan otomatis untuk aplikasi Microsoft Store.
question-browser-description = Atlas tidak akan mengubah pengaturan browser Anda.
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = PC Anda tidak memiliki antivirus sampai Anda menginstal antivirus lain, dan Windows tidak lagi memperingatkan Anda sebelum Anda membuka aplikasi atau unduhan yang tidak dikenal.
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = Ini juga menonaktifkan Perlindungan eksploitasi untuk aplikasi, seperti Control Flow Guard, sehingga keamanan berkurang.
cost-auto-updates-disable = Buka Windows Update secara rutin untuk mendapatkan perbaikan keamanan.
cost-auto-updates-default = Windows mungkin memulai ulang PC Anda untuk menyelesaikan penginstalan pembaruan.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift dan Ctrl+Shift tidak lagi mengganti bahasa atau tata letak.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Membebaskan ruang disk, tetapi Hibernasi dan startup cepat (Fast Startup) tidak lagi tersedia.
extra-disable-power-saving = PC Anda mungkin memakai lebih banyak daya, menjadi lebih panas, dan daya tahan baterainya lebih pendek.
extra-disable-core-isolation = Mengurangi perlindungan, dan game yang memakai anti-cheat seperti Riot Vanguard atau FACEIT mungkin tidak bisa dimulai sampai Anda mengaktifkan kembali integritas memori.
extra-uninstall-edge = Favorit, riwayat, dan kata sandi tersimpan Edge di PC ini akan dihapus, kecuali yang disinkronkan ke akun Microsoft Anda.
extra-install-toolbox = Membantu Anda mengelola pengaturan Atlas, meskipun beberapa fitur mungkin belum selesai selama masih beta.
extra-install-eclean = Alat dari tim di balik AtlasOS untuk meninjau file sampah dan aplikasi startup. Memerlukan akun dan koneksi internet.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Pertahankan Microsoft Defender?
screen-mitigations-title = Perlindungan prosesor
screen-mitigations-question = Pertahankan perlindungan prosesor Windows?
screen-updates-title = Windows Update
screen-updates-question = Bagaimana sebaiknya Windows menginstal pembaruan?
screen-browser-title = Browser web
screen-power-title = Daya dan keamanan
screen-apps-title = Aplikasi
screen-optional-apps-title = Aplikasi opsional
screen-choose-one-title = Pilih salah satu
screen-extras-title = Tambahan opsional
# Each decision's short name in the middle of a sentence, as in summary-change-a11y,
# update-path-differs, preflight-choice-unanswered and installed-not-applied-choices. Write it as
# the language does mid-sentence: in English, product names keep their capitals and other names
# are lower case.
screen-update-path-name = metode pembaruan
screen-defender-name = Microsoft Defender
screen-mitigations-name = perlindungan prosesor
screen-updates-name = pengaturan Windows Update
screen-keyboard-name = bahasa keyboard
screen-browser-name = browser web
screen-power-name = daya dan keamanan
screen-apps-name = aplikasi
screen-optional-apps-name = aplikasi opsional
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = pilihan dalam paket Atlas
screen-extras-name = tambahan opsional
# Question for a required choice this app has no specific wording for.
screen-generic-question = Pilih salah satu opsi untuk { $title }
learn-more-defender = Pelajari selengkapnya tentang Microsoft Defender
learn-more-mitigations = Pelajari selengkapnya tentang perlindungan prosesor
learn-more-updates = Pelajari selengkapnya tentang Windows Update
learn-more-browser = Pelajari selengkapnya tentang browser
learn-more-power = Pelajari selengkapnya tentang daya dan keamanan
learn-more-apps = Pelajari selengkapnya tentang aplikasi
learn-more-eclean = Pelajari selengkapnya tentang eclean
learn-more-keyboard = Pelajari selengkapnya tentang bahasa keyboard
learn-more-generic = Baca panduan penyiapan
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mempertahankan antivirus bawaan Windows untuk membantu melindungi PC Anda dari virus dan ancaman lainnya.
consequence-mitigations-default = Mempertahankan perlindungan bawaan Windows terhadap celah keamanan prosesor dan serangan yang memanfaatkan bug dalam aplikasi.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = Juga menonaktifkan Perlindungan eksploitasi untuk aplikasi, seperti Control Flow Guard. Ini mengurangi keamanan. Perbedaan kinerja, jika ada, bergantung pada prosesor Anda.
consequence-auto-updates-disable = Buka Windows Update secara rutin untuk menginstal pembaruan. Notifikasi pembaruan tetap aktif.
consequence-auto-updates-default = Windows akan menginstal pembaruan secara otomatis, termasuk perbaikan keamanan.

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Bagaimana Anda ingin memperbarui ke Atlas { $version }?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Bagaimana Anda ingin menginstal ulang Atlas { $version }?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = Pertahankan pilihan saya
update-path-keep-detail = Atlas mempertahankan setiap pilihan sesuai kondisi PC ini sekarang dan tidak mengubah satu pun.
update-path-choose = Pilih ulang
update-path-choose-detail = Mulai dari kondisi PC ini sekarang. Aplikasi, file, dan personalisasi Anda tetap ada.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Pilihan Anda di PC ini sekarang
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = Atlas tidak dapat mengetahuinya dari PC Anda, jadi Atlas akan menanyakannya
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = PC ini tidak sesuai dengan catatan Atlas untuk { $choices }.
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas mempertahankan semua pilihan lain sesuai kondisi PC ini sekarang.
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = Di PC ini sekarang
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas mengembalikan Microsoft Defender. Setelah PC dimulai ulang, aktifkan perlindungannya di Keamanan Windows.
change-mitigations-default = Atlas mengaktifkan kembali perlindungan prosesor sesuai pengaturan bawaan Windows. Perubahan ini berlaku setelah PC dimulai ulang.
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = Semua perlindungan prosesor sedang aktif. Jika Anda mempertahankan perlindungan, semuanya tetap aktif.
change-auto-updates-default = Atlas kembali mengizinkan Windows menginstal pembaruan secara otomatis.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas mengaktifkan kembali hibernasi.
change-power-saving-on = Atlas mengaktifkan kembali penghematan daya dan kembali ke rencana daya Anda sebelumnya, atau ke rencana Seimbang jika tidak ada.
change-core-isolation-on = Atlas mengaktifkan kembali keamanan berbasis virtualisasi (VBS), kecuali jika kebijakan di PC ini mengendalikannya. Perubahan ini berlaku setelah PC dimulai ulang.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Menghapus Snipping Tool untuk semua pengguna PC ini. Atlas tidak dapat mengembalikannya nanti, tetapi Anda dapat menginstalnya lagi dari Microsoft Store.
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge sudah dihapus, dan pembaruan Atlas tidak dapat mengembalikannya. Untuk menginstalnya lagi, gunakan Install or Remove Edge di folder Atlas.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } sudah terinstal. Atlas tidak menghapus instalan aplikasi; untuk menghapusnya, buka Aplikasi yang diinstal di Pengaturan Windows.
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } tetap terinstal, dan Atlas juga menginstal { $browser }.

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Pertahankan Microsoft Defender (disarankan)
package-option-defender-enable-short = Pertahankan Microsoft Defender
package-option-defender-disable = Hapus Microsoft Defender
package-option-mitigations-default = Pertahankan perlindungan prosesor (disarankan)
package-option-mitigations-default-short = Pertahankan perlindungan prosesor
package-option-mitigations-disable = Nonaktifkan perlindungan prosesor
package-option-auto-updates-disable = Instal pembaruan sendiri
package-option-auto-updates-default = Instal pembaruan secara otomatis
package-option-disable-hibernation = Nonaktifkan hibernasi
package-option-disable-power-saving = Nonaktifkan penghematan daya
package-option-disable-core-isolation = Nonaktifkan keamanan berbasis virtualisasi (VBS)
package-option-remove-snipping-tool = Hapus Snipping Tool
package-option-uninstall-edge = Hapus Microsoft Edge
package-option-install-another-browser = Instal browser
package-option-install-toolbox = Instal Atlas Toolbox
package-option-install-eclean = Instal eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender adalah antivirus bawaan Windows. Hapus hanya jika Anda memahami risikonya dan berencana menggunakan aplikasi antivirus lain. Apa pun pilihan Anda, Atlas menonaktifkan Kontrol Aplikasi Pintar, Perlindungan pengelabuan, dan Temukan perangkat saya.
package-choice-mitigations-description = Perlindungan ini, yang juga disebut mitigasi keamanan, membantu melindungi dari celah keamanan prosesor, seperti Spectre dan Meltdown, serta dari serangan yang memanfaatkan bug dalam aplikasi. Sebaiknya pertahankan pengaturan bawaan Windows.
package-choice-auto-updates-description = Pembaruan Windows mencakup perbaikan keamanan. Anda dapat membiarkan Windows menginstalnya secara otomatis atau menginstalnya sendiri. Apa pun pilihan Anda, Atlas mempertahankan Windows pada versinya saat ini, yang menerima perbaikan keamanan hanya sampai Microsoft mengakhiri dukungan untuk versi tersebut. Atlas juga menonaktifkan pembaruan otomatis untuk aplikasi Microsoft Store, jadi perbarui aplikasi tersebut di Microsoft Store.
package-choice-browser-description = Pilih browser untuk diinstal. Atlas tidak akan mengubah pengaturan browser Anda.

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender tidak terinstal di PC ini
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Tidak ada pengaturan perlindungan yang perlu dinonaktifkan.
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas telah menghapus Microsoft Defender dari PC ini
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas mengembalikan Microsoft Defender dalam penginstalan ini
security-restore-nothing-to-turn-off = Defender belum berjalan, jadi tidak ada yang perlu dinonaktifkan. Setelah PC dimulai ulang, aktifkan perlindungannya di Keamanan Windows.
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = Microsoft Defender tidak ditemukan
security-banner-missing-message = Atlas tidak menghapusnya, jadi Atlas tidak dapat mengembalikannya. Anda dapat melanjutkan, tetapi PC Anda tidak memiliki antivirus sampai Anda menginstal aplikasi antivirus lain atau memperbaiki Windows.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = Nonaktifkan keempat pengaturan ini
security-turn-off-message = Microsoft Defender dapat memblokir Atlas selama penginstalan. Jika Anda mempertahankan Defender, aktifkan kembali pengaturan ini setelah penginstalan.
# The page name in Windows Security.
security-list-title = Pengaturan perlindungan virus & ancaman
security-switch-off = Nonaktif
security-switch-on = Aktif
security-switch-unreadable = Tidak dapat dibaca
security-switch-reading = Memeriksa
security-all-off = Semua nonaktif
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on = { $count } masih aktif
security-count-unreadable = { $count } tidak dapat dibaca
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. English
# reads the same for one or several; agree with $count where your language needs to.
security-unread-switches-title =
    { $count ->
       *[other] Atlas tidak dapat membaca { $switches }
    }
security-unread-message =
    { $count ->
       *[other] Pastikan pengaturan tersebut nonaktif di Keamanan Windows.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
       *[other] Saya sudah memastikan { $switches } nonaktif
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Saya sudah memeriksa Keamanan Windows dan keempat pengaturan sudah nonaktif
security-unknown-unelevated-title = Atlas memerlukan izin untuk memeriksa perlindungan
security-unknown-unelevated-message = Jalankan ulang Atlas sebagai administrator agar Atlas dapat memeriksa pengaturan Microsoft Defender.
# The four switches, named as Windows Security names them, each with why it must be off.
# "Proteksi Kerusakan" follows the Indonesian Windows interface; Microsoft's
# machine-translated support pages vary. Verify against a localised Windows build.
protection-tamper = Proteksi Kerusakan
protection-tamper-why = Agar Atlas dapat mengubah pengaturan keamanan.
protection-realtime = Perlindungan real-time
protection-realtime-reason = Pemindaian dapat memblokir file Atlas.
protection-cloud = Perlindungan yang dikirimkan cloud
protection-cloud-reason = Pemeriksaan online dapat memblokir file Atlas.
protection-samples = Pengiriman sampel otomatis
protection-samples-why = Agar file Atlas tidak dikirim ke Microsoft.

## Step 4: Install

outcome-succeeded-title = Atlas sudah terinstal
outcome-lost-title = Hasil penginstalan tidak dapat dipastikan
outcome-failed-title = Penginstalan tidak selesai
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = PC Anda tidak memenuhi persyaratan penginstalan, sehingga penginstalan belum mengubah apa pun.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = PC Anda tidak memenuhi persyaratan penginstalan, sehingga upaya ini berhenti. Upaya sebelumnya sudah membuat perubahan.
# Beside common-restart-as-administrator.
result-not-elevated = Atlas tidak memiliki izin administrator, sehingga penginstalan belum mengubah apa pun.
result-not-elevated-resumed = Atlas tidak memiliki izin administrator, sehingga upaya ini berhenti. Upaya sebelumnya sudah membuat perubahan.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas tidak dapat memastikan bahwa Windows dan aplikasi Store sudah diperbarui, sehingga penginstalan berhenti sebelum mengubah Windows.
result-preparation-stale-resumed = Atlas tidak dapat memastikan bahwa Windows dan aplikasi Store sudah diperbarui, sehingga upaya ini berhenti. Upaya sebelumnya sudah membuat perubahan.
result-failed-preflight = Penginstalan berhenti sebelum mengubah apa pun. Anda dapat mencoba lagi.
result-failed-staging = Penginstalan berhenti saat menyiapkan file, sebelum mengubah Windows. Anda dapat mencoba lagi.
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = Sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi, atau jika berhenti di sini, aktifkan kembali pengaturan perlindungan di Keamanan Windows.
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = Sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi.
result-failed-resumed = Upaya ini berhenti lebih awal, tetapi upaya sebelumnya sudah membuat perubahan. Anda dapat mencoba lagi, atau jika berhenti di sini, aktifkan kembali pengaturan perlindungan di Keamanan Windows.
result-failed-resumed-defender-removed = Upaya ini berhenti lebih awal, tetapi upaya sebelumnya sudah membuat perubahan. Anda dapat mencoba lagi.
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = Upaya ini berhenti dengan kesalahan yang sama seperti sebelumnya, jadi mencoba lagi kemungkinan tidak akan membantu. Kirim laporan agar tim Atlas dapat menemukan penyebabnya, dan aktifkan kembali pengaturan perlindungan jika Anda berhenti di sini.
result-failed-repeated-defender-removed = Upaya ini berhenti dengan kesalahan yang sama seperti sebelumnya, jadi mencoba lagi kemungkinan tidak akan membantu. Kirim laporan agar tim Atlas dapat menemukan penyebabnya.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows tetap tidak menghapus { $apps }, jadi mencoba lagi kemungkinan tidak akan membantu. Kirim laporan agar tim Atlas dapat menemukan penyebabnya, dan aktifkan kembali pengaturan perlindungan jika Anda berhenti di sini.
result-failed-repeated-apps-defender-removed = Windows tetap tidak menghapus { $apps }, jadi mencoba lagi kemungkinan tidak akan membantu. Kirim laporan agar tim Atlas dapat menemukan penyebabnya.
result-not-started = Penginstal tidak dimulai tepat waktu, sehingga penginstalan belum mengubah apa pun. Anda dapat mencoba lagi.
result-lost = Penginstal berhenti tanpa melaporkan hasil, sehingga sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi, atau jika berhenti di sini, aktifkan kembali pengaturan perlindungan di Keamanan Windows.
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = Penginstal berhenti tanpa melaporkan hasil, sehingga sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi.
restart-now-message = Windows sedang dimulai ulang untuk menyelesaikan penyiapan Atlas.
restart-stopped = Mulai ulang otomatis dibatalkan. Simpan pekerjaan Anda, lalu mulai ulang PC untuk menyelesaikan penyiapan Atlas.
restart-needed = Simpan pekerjaan Anda, lalu mulai ulang PC untuk menyelesaikan penyiapan Atlas.
restart-dont-now = Mulai ulang nanti
restart-now = Mulai ulang sekarang
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = Penginstalan belum dimulai
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = Atlas memerlukan jawaban Anda untuk { $choice }.
preflight-choices-unusable = Atlas tidak dapat menggunakan pilihan ini.
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
       *[other] { $checks } perlu diperhatikan sejak Atlas memeriksa PC Anda.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = Keamanan Windows berubah sejak Anda menonaktifkan pengaturan perlindungan: { $summary }.
preflight-busy-wait = Jendela Atlas lain sedang memulai penginstalan. Tunggu sebentar, lalu coba lagi.
# Beside home-start-over.
preflight-taken-over-start-over = Jendela Atlas lain kini menggunakan penyiapan ini. Lanjutkan di sana, atau mulai dari awal di sini.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas tidak dapat memastikan apakah penginstalan sebelumnya masih berjalan, sehingga belum memulai penginstalan lain.
preflight-not-started = Atlas tidak dapat memulai penginstal, sehingga penginstalan belum mengubah apa pun. Anda dapat mencoba lagi.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas tidak dapat memulai penginstal, tetapi upaya sebelumnya sudah membuat perubahan. Anda dapat mencoba lagi.
go-to-ready = Buka langkah Persiapan
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Buka langkah Pilihan Anda
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Buka langkah Keamanan Windows
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Kembali ke Instal
output-problem-title = Kemajuan penginstalan tidak dapat dibaca
install-elevate-title = Atlas memerlukan izin untuk menginstal
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Saat Atlas dijalankan ulang, Windows akan meminta izin Anda.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Paket Atlas belum siap
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Selesaikan Persiapan terlebih dahulu
install-not-ready-message = Atlas perlu menyelesaikan pemeriksaan PC dan pembaruan Windows sebelum dapat menginstal.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = Nonaktifkan lagi pengaturan perlindungan
install-switches-message = Keamanan Windows: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Siap diinstal
summary-setup-title = Penyiapan Atlas Anda
summary-activation = Aktivasi
summary-activation-ok = Sudah diaktifkan. Atlas tidak akan mengubahnya.
summary-activation-missing = Belum diaktifkan. Anda dapat melanjutkan, tetapi Atlas tidak akan mengaktifkan Windows.
summary-activation-unknown = Atlas tidak akan mengubah status aktivasi Windows Anda.
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts = Biasanya sekitar { $minutes } menit, lalu PC Anda dimulai ulang
summary-time-restart-yourself = Biasanya sekitar { $minutes } menit, lalu mulai ulang PC Anda
# The check box on the card. It starts from settings-restart-automatically and applies to this install only.
summary-restart-automatically = Mulai ulang secara otomatis setelah penginstalan selesai
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Juga dinonaktifkan
summary-turned-off-value = Kontrol Aplikasi Pintar, Perlindungan pengelabuan, dan Temukan perangkat saya
summary-show-command = Tampilkan perintah penginstalan
summary-hide-command = Sembunyikan perintah penginstalan
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Salin perintah penginstalan
summary-command-unavailable = Tidak dapat menyiapkan perintah penginstalan. Detail: { $error }
summary-not-chosen = Belum dipilih
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = Ubah { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Metode pembaruan
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = Menyiapkan penginstalan
footer-checks-blocked = Atasi hasil pemeriksaan untuk melanjutkan
footer-manager-outdated = Unduh Atlas Manager versi baru untuk melanjutkan
footer-need-files = Dapatkan paket Atlas untuk melanjutkan
# Tester build variant of footer-need-files.
footer-need-package-bundled = Siapkan paket Atlas bawaan untuk melanjutkan
footer-drivers = Tentukan cara driver diinstal untuk melanjutkan
footer-windows-terms = Terima ketentuan lisensi untuk melanjutkan
footer-updating = Memperbarui Windows dan aplikasi Store…
footer-restart = Mulai ulang PC Anda untuk melanjutkan
footer-reading-security = Memeriksa pengaturan perlindungan
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = Nonaktifkan keempat pengaturan untuk melanjutkan
footer-security-confirm = Untuk melanjutkan, konfirmasikan pengaturan yang tidak dapat dibaca Atlas
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = Simpan pekerjaan Anda dan tutup aplikasi terlebih dahulu
button-install = Instal Atlas
log-earlier-lines = { $count } baris sebelumnya ada di file log.
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (log lengkap: { $path })

## The installing view

installing-title = Menginstal Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = Memeriksa PC Anda…
installing-staging-label = Menyalin file Atlas…
installing-applying-label = Menyiapkan Windows…
installing-finishing-label = Menyelesaikan…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Biarkan PC Anda tetap menyala dan terhubung ke sumber listrik. PC akan dimulai ulang dengan sendirinya setelah penginstalan selesai.
installing-keep-on = Biarkan PC Anda tetap menyala dan terhubung ke sumber listrik. Mulai ulang PC setelah penginstalan selesai.
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = Ini tidak berarti penginstalan berhenti.
installing-installed-title = Atlas sudah terinstal
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown = PC Anda akan dimulai ulang dalam { $seconds } detik.
installing-restart-save = Simpan pekerjaan Anda terlebih dahulu.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } sudah terinstal
installed-title = Atlas sudah terinstal
installed-ready = Semua sudah beres. PC Anda siap digunakan dengan Atlas.
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = Dapatkan driver chipset, jaringan, dan grafis dari produsen PC, motherboard, atau perangkat Anda.
installed-drivers-guide = Buka panduan driver
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender telah dihapus
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas tidak menghapusnya. Jika Anda tidak menggunakan aplikasi antivirus lain, instal antivirus untuk melindungi PC Anda.
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender masih terhapus
defender-not-restored-message = Pembaruan Atlas sebelumnya tidak mengembalikannya, jadi Defender tidak melindungi PC Anda. Instal ulang Atlas dan pertahankan Defender, atau jalankan Toggle Defender dari 7. Security > Defender di folder Atlas.
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = Beberapa pilihan tidak diterapkan
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
       *[other] Pilihan berikut tetap seperti semula: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Windows Update kembali nonaktif, sesuai pilihan Anda
installed-update-off-message = Selama nonaktif, PC Anda tidak menerima pembaruan keamanan.
installed-update-paused-title = Pembaruan Windows kembali dijeda, sesuai pilihan Anda
installed-update-paused-message = Selama dijeda, PC Anda tidak menerima pembaruan keamanan.

## Settings

settings-title = Pengaturan
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = Tampilan
settings-installation = Penginstalan
settings-privacy = Privasi
settings-theme = Tema aplikasi
settings-theme-system = Ikuti Windows
settings-theme-light = Terang
settings-theme-dark = Gelap
settings-theme-contrast-note = Atlas menggunakan warna dari tema kontras Windows Anda.
settings-language = Bahasa
# The setting in the Language section, and its box's name.
settings-app-language = Bahasa aplikasi
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Ikuti Windows – { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = Pratinjau
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = Terjemahan ini belum ditinjau oleh penutur asli.
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } adalah terjemahan pratinjau dan mungkin berisi kesalahan.
preview-notice-switch = Beralih ke bahasa Inggris
preview-notice-language = Ubah bahasa
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = Bahasa yang Anda pilih tidak tersedia dalam versi Atlas ini, jadi Atlas menampilkan bahasa Inggris. Pilihan Anda tetap disimpan.
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas belum mendukung bahasa tampilan Windows Anda, jadi Atlas menampilkan bahasa Inggris.
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas tidak dapat memeriksa bahasa tampilan Windows Anda, jadi Atlas menampilkan bahasa Inggris.
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = Angka, tanggal, dan waktu mengikuti format regional Windows Anda: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Angka mengikuti format regional Windows Anda: { $locale }. Tanggal dan waktu menggunakan format standar karena Atlas belum dapat menampilkan teks dari kanan ke kiri.
settings-language-contribute = Bantu menerjemahkan Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Bagikan data penggunaan dengan Atlas
settings-share-usage-description = Halaman yang Anda buka, pembuatan ISO, dan apakah penginstalan berhasil.
settings-privacy-policy = Kebijakan privasi
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = Mulai ulang secara otomatis setelah menginstal dan memperbarui
settings-restart-automatically-description = PC Anda dimulai ulang dalam waktu satu menit setelah Atlas selesai, dan aplikasi yang terbuka akan ditutup.
settings-restart-locked = Pengaturan ini dapat diubah setelah penginstalan selesai.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Bantuan
settings-about = Tentang
settings-about-app = Atlas Manager
settings-about-licence = Lisensi
settings-about-licence-value = GPL-3.0, gratis dan sumber terbuka
settings-view-source = Lihat kode sumber
# Link that opens the third-party licence notices.
settings-view-licences = Lihat pemberitahuan lisensi
# Under the links when Windows could not open the notices.
settings-licences-failed = Tidak dapat membuka pemberitahuan lisensi. Coba lagi, atau cari pemberitahuan tersebut di kode sumber di GitHub.
settings-open-data-folder = Buka folder aplikasi

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Membebaskan ruang disk yang dipakai untuk menyimpan sesi Anda saat hibernasi. Hibernasi dan startup cepat (Fast Startup) tidak akan tersedia.
consequence-disable-power-saving = Menonaktifkan fitur penghematan daya. PC Anda mungkin memakai lebih banyak daya, menjadi lebih panas, dan daya tahan baterainya lebih pendek.
consequence-disable-core-isolation = Menonaktifkan lapisan keamanan tambahan Windows, termasuk integritas memori. Ini mengurangi perlindungan, dan game yang memakai anti-cheat seperti Riot Vanguard atau FACEIT mungkin tidak bisa dimulai sampai Anda mengaktifkan kembali integritas memori.
consequence-remove-snipping-tool = Menghapus aplikasi Windows untuk mengambil tangkapan layar dan merekam layar.
consequence-uninstall-edge = Menghapus browser Microsoft Edge. Pastikan Anda memiliki browser lain, atau pilih salah satu di bawah.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Menghapus favorit, riwayat, dan kata sandi tersimpan Anda di Edge pada PC ini.
consequence-install-another-browser = Pilih browser di bawah dan Atlas akan menginstalnya untuk Anda.
consequence-install-toolbox = Tambahkan Atlas Toolbox untuk membantu mengelola pengaturan Atlas Anda. Toolbox masih dalam tahap beta, sehingga beberapa fitur mungkin belum selesai.
consequence-install-eclean = Alat perawatan dari tim di balik AtlasOS untuk menjaga PC tetap rapi setelah penyiapan. Tinjau file sampah dan aplikasi startup. Memerlukan akun dan koneksi internet.

## ISO creation
iso-open = Buat ISO Atlas
iso-title = Buat ISO Atlas
iso-recommended = Disarankan
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Penyiapan
iso-step-create = Buat
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = Untuk PC mana ISO ini?
iso-target-this = PC ini
iso-target-another = PC lain
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = ISO ini untuk PC { $architecture }.
iso-source = ISO Windows
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Unduh dari Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Unduhan Windows
iso-download-language = Bahasa
iso-download-arch = Arsitektur
iso-download-languages = Memuat bahasa…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Mengunduh Windows 11…
iso-download-amount = { $received } dari { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas tidak dapat menjangkau layanan unduhan Microsoft. Periksa koneksi internet Anda, lalu coba lagi.
iso-download-incomplete = Unduhan tidak selesai. Periksa koneksi internet dan ruang kosong, lalu coba lagi.
iso-download-website = Buka situs unduhan Microsoft
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = Pilih file ISO
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Memeriksa ISO Windows Anda…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = ISO Windows siap, { $facts }
iso-package-latest-label = Terbaru
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = Rilis Atlas terbaru lebih lama daripada versi yang dapat digunakan Atlas Manager ini.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Mendapatkan Atlas terbaru…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas tidak dapat memeriksa versi terbaru. Periksa koneksi internet Anda, lalu coba lagi.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Dapatkan ISO Windows untuk melanjutkan
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Kapan Anda ingin menentukan pilihan Atlas?
iso-mode-after = Setelah masuk
iso-mode-after-description = Atlas memandu Anda melalui penyiapan setelah Anda masuk.
iso-mode-now = Sekarang
iso-mode-now-description = Disimpan dalam ISO. Anda menginstal Atlas setelah masuk.
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = Selesaikan sebelum desktop terbuka
iso-mode-before-desktop-description = Setelah Anda masuk, Atlas berjalan dalam layar penuh hingga terinstal.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Paket Atlas ini tidak dapat menyimpan pilihan dalam ISO, jadi Anda menentukannya setelah masuk.
iso-atlas-options = Pilihan Atlas
# The line at the top of the Create step.
iso-create-intro = Membuat ISO tidak mengubah PC ini atau ISO asli Anda.
iso-review-package = Paket Atlas
iso-review-output = ISO baru
iso-review-edition = Edisi
iso-review-editions = Edisi
iso-edition = Edisi Windows
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Ditanyakan saat Penyiapan Windows
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Pilih saat Penyiapan Windows
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Terima ketentuan lisensi Windows agar Penyiapan Windows tidak menanyakannya
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nama akun
iso-review-target = Instal di
iso-review-drivers = Driver
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Penyiapan Windows
iso-review-skips = Melewati layar akun Microsoft dan privasi
iso-review-skips-terms = Melewati layar lisensi, akun Microsoft, dan privasi
iso-review-network = Driver jaringan
iso-review-network-included = Driver Wi-Fi dan Ethernet PC ini
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Sekarang, selesai sebelum desktop terbuka
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = Memerlukan { $needed } · { $free } kosong di { $drive }
iso-destination-short = ISO memerlukan { $needed }, sedangkan ruang kosong di { $drive } hanya { $free }. Kosongkan ruang, atau simpan ISO ke drive lain.
iso-destination-filesystem = { $drive } tidak dapat menyimpan file besar dalam ISO. Simpan ke drive berformat NTFS, seperti drive Windows Anda.
iso-destination-unusable = Atlas hanya dapat menyimpan ISO ke folder di drive pada PC ini.
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = Di folder tujuan, file dalam ISO akan memerlukan jalur yang lebih panjang daripada yang diizinkan Windows. Simpan ISO baru ke folder dengan jalur yang lebih pendek, seperti folder di drive Windows Anda.
iso-create = Buat ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = Membuat ISO Anda…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Membaca ISO Windows
iso-stage-copy = Menyalin file Windows
iso-stage-add-atlas = Menambahkan Atlas
iso-stage-master = Menulis file ISO
iso-stage-verify = Memeriksa ISO baru
iso-stage-cleanup = Menyelesaikan
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = sedang berlangsung
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = gagal
iso-stage-status-not-started = belum dimulai
iso-progress-keep-open = Biarkan Atlas tetap terbuka hingga selesai.
iso-cancel = Batalkan pembuatan
iso-cancelling = Menunggu titik aman untuk membatalkan
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Membatalkan…
iso-cancelled = Pembuatan ISO dibatalkan
iso-cancelled-unchanged = ISO asli Anda tidak diubah.
iso-complete = ISO Anda siap
iso-complete-backup = Cadangkan file Anda sebelum menginstal ulang Windows dari ISO ini.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Buat drive USB
iso-open-folder = Tampilkan di folder
iso-failed = Pembuatan ISO tidak dapat diselesaikan
# Under iso-failed, beside Try again.
iso-failed-retry = Pastikan file Anda masih berada di lokasi yang Anda pilih dan drive tujuan masih terhubung, lalu coba lagi.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Tidak dapat memeriksa file
iso-check-failed-retry = Pastikan ISO dan paket Atlas sudah selesai diunduh, lalu coba lagi.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas tidak dapat menyiapkan folder kerjanya, sehingga tidak ada yang diubah.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = ISO ini tidak berisi edisi yang didukung Atlas
iso-edition-unsupported = Windows Home dan LTSC tidak didukung. Gunakan ISO dengan edisi Pro, Education, atau Enterprise.
iso-customised-title = ISO ini sudah dimodifikasi
# In place of iso-customised-title, above iso-customised, when the ISO is one Atlas Manager
# created: Atlas creates an ISO only from an unmodified ISO from Microsoft.
iso-created-by-atlas-title = ISO ini dibuat oleh Atlas
iso-customised = ISO ini sudah berisi file penyiapan, seperti autounattend.xml. Gunakan ISO dari Microsoft yang belum dimodifikasi.
iso-preview-title = ISO ini adalah build pratinjau
iso-preview = Build Windows-nya tidak ada dalam daftar rilis publik Microsoft. Gunakan ISO dari Microsoft.
iso-windows-unsupported-title = Paket Atlas ini tidak dapat menggunakan ISO ini
iso-windows-unsupported = Gunakan ISO Windows 11 yang belum dimodifikasi untuk versi yang didukung paket ini.
iso-release-unknown-title = Atlas tidak dapat memastikan rilis Windows ini
iso-release-unconfirmed = Atlas mencocokkannya dengan daftar rilis publik Microsoft. Periksa koneksi internet Anda, lalu coba lagi.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Paket Atlas ini tidak dapat membuat ISO
iso-package-old = Gunakan Atlas { $minimum } atau yang lebih baru.
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = Ini adalah ISO Windows, bukan paket Atlas
iso-package-windows-iso = Pilih paket Atlas (.atlaspkg) sebagai gantinya, dan pilih ISO ini sebagai ISO Windows.
iso-manager-missing-title = File Atlas Manager tidak ditemukan
iso-fix-package = Pilih paket lain
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager perlu diperbarui
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas tidak dapat menambahkan driver jaringan PC ini ke ISO.
iso-network-skip = Buat tanpa driver
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas memerlukan izin untuk membuat ISO
iso-admin-reason = Izin ini diperlukan untuk membaca ISO Windows Anda dan membuat ISO baru.
iso-elevation-declined = Windows tidak memberikan izin kepada Atlas, sehingga Atlas belum dapat membaca ISO Windows Anda.
# The free space ran out while the ISO was being created.
iso-failed-space = Ruang kosong di drive tujuan tidak cukup. Kosongkan ruang, atau simpan ISO baru ke drive lain.
# Under iso-manager-missing-title.
iso-manager-missing = Unduh AtlasManager.exe ke folder lokal seperti Unduhan, lalu buka dari sana.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = ISO ini tidak berisi edisi Windows yang didukung. Windows Home dan LTSC tidak didukung. Gunakan ISO yang menyertakan edisi lain, seperti Pro, Education, atau Enterprise.
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows tidak dapat membuka ISO. Mulai ulang PC Anda, lalu coba lagi.
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows berhenti merespons saat membuka ISO. Mulai ulang PC Anda, lalu coba lagi.
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows tidak dapat membuka file ISO di PC ini karena driver yang digunakannya untuk itu, vdrvroot dan cdrom, dinonaktifkan. Aktifkan kembali driver tersebut, mulai ulang PC Anda, lalu coba lagi.
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows tidak dapat membuka ISO ini karena file-nya dikompresi, dienkripsi, atau berupa file sparse. Salin ke folder yang tidak dikompresi atau dienkripsi, lalu gunakan salinannya.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Buka folder log
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas sedang memproses Windows Update. Anda dapat melanjutkan di sini setelah selesai.
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = pemeliharaan komponen Windows
prepare-reason-windows-update = pembaruan Windows
prepare-reason-file-renames = file yang menunggu diganti
prepare-reason-update-agent = layanan Windows Update
prepare-reason-unknown = alasan tidak dilaporkan
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Jika mencoba lagi tidak membantu, selesaikan pembaruan yang tersisa di Windows Update atau Microsoft Store.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Beberapa pembaruan tidak dapat diselesaikan
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Pembaruan berhenti sebelum melaporkan hasilnya.
# Title of the bar over prepare-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = Tidak dapat memastikan hasil pembaruan
prepare-affected-app = aplikasi terkait
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Tutup { $app }, lalu coba lagi. Jika Anda tidak dapat menemukannya, tutup melalui Pengelola Tugas.
prepare-install-busy = Penginstalan lain atau mulai ulang yang diperlukan menghalangi pembaruan. Tunggu hingga penginstalan lain selesai, mulai ulang PC Anda jika Windows memintanya, lalu coba lagi.
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows tidak dapat memperbaiki dirinya sendiri
prepare-components-damaged = Windows melaporkan kerusakan yang mencegah pembaruan terinstal. Memulai ulang dapat mengatasinya, dan Atlas akan melanjutkan setelah Anda masuk.
prepare-restart-and-retry = Mulai ulang dan coba lagi
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows terlalu rusak untuk diperbarui
prepare-components-unrepairable = Cadangkan file Anda, lalu instal ulang Windows dengan ISO Atlas.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas berjalan dengan akun yang berbeda dari akun yang masuk ke Windows. Masuk ke Windows dengan akun administrator, buka Atlas dari akun tersebut, lalu coba lagi.
prepare-failed-store-missing = Microsoft Store belum disiapkan untuk akun Anda. Buka Microsoft Store sekali, atau instal ulang jika tidak ada, lalu coba lagi.
prepare-failed-store-battery = Microsoft Store menjeda pembaruan untuk menghemat baterai. Hubungkan PC Anda ke sumber listrik, lalu coba lagi.
prepare-failed-store-network = Microsoft Store menjeda pembaruan hingga PC Anda memiliki koneksi yang tidak terukur. Hubungkan ke Wi-Fi atau Ethernet yang tidak terukur, lalu coba lagi.
prepare-failed-store-timeout = Aplikasi Store belum selesai diperbarui. Selesaikan unduhan yang tersisa di Microsoft Store, lalu coba lagi.
prepare-failed-store-passes = Microsoft Store terus menawarkan pembaruan baru. Selesaikan pembaruan yang tersisa di Microsoft Store, lalu coba lagi.
prepare-failed-manual-updates = Beberapa pembaruan Windows perlu diselesaikan di Windows Update. Buka Windows Update, selesaikan pembaruan tersebut, lalu coba lagi.
prepare-failed-windows-passes = Windows Update terus menawarkan pembaruan baru. Selesaikan pembaruan yang tersisa di Windows Update, lalu coba lagi.
prepare-failed-windows-update-unreachable = Windows Update tidak dapat menjangkau server Microsoft. Periksa koneksi internet Anda serta firewall, proxy, atau VPN yang digunakan, lalu coba lagi.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-failed-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager berada di folder tertaut. Tutup Atlas, pindahkan Atlas Manager ke folder lokal di PC ini, lalu buka dari sana.
prepare-error-code = Kode kesalahan: { $code }
prepare-open-store = Buka Microsoft Store
prepare-windows-search = Memeriksa pembaruan Windows…
prepare-percent = { $percent }% dari tahap ini
prepare-count = Pembaruan selesai: { $completed } dari { $total }
prepare-bytes = Terunduh { $downloaded } dari sekitar { $total } MB
prepare-progress-still = Tidak ada kemajuan selama { $minutes } mnt. Pembaruan besar dapat memerlukan waktu, jadi biarkan Atlas tetap terbuka.
prepare-report-late = Windows belum melaporkan kemajuan selama beberapa saat. Pembaruan mungkin masih berjalan, jadi biarkan Atlas tetap terbuka.
prepare-windows-download = Mengunduh pembaruan Windows…
prepare-windows-install = Menginstal pembaruan Windows…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Memperbaiki Windows…
prepare-windows-repair-detail = Windows melaporkan kerusakan yang dapat mencegah pembaruan terinstal. Ini dapat memerlukan waktu setengah jam atau lebih.
prepare-store-search = Memeriksa Microsoft Store…
prepare-store-install = Memperbarui Microsoft Store dan aplikasinya…
prepare-stop = Hentikan pembaruan
prepare-start = Periksa dan instal pembaruan
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Tersedia setelah paket Atlas siap.
iso-username = Nama akun lokal
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Anda akan membuat kata sandi saat pertama kali masuk.
iso-username-placeholder = Nama Anda
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Masukkan nama akun lokal untuk melanjutkan
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Gunakan maksimal 20 karakter, tanpa spasi di awal atau akhir dan tanpa karakter berikut: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Nama tidak boleh diakhiri dengan titik.
iso-account-reserved = Windows menggunakan nama ini untuk akun bawaan. Pilih nama lain.
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Penyiapan Windows akan meminta Anda menerima ketentuan lisensi.
prepare-drivers = Bagaimana driver akan diinstal?
prepare-drivers-auto = Dapatkan driver melalui Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Dapatkan driver melalui Windows Update (disarankan)
prepare-drivers-auto-detail = Windows mencari driver untuk perangkat keras Anda.
prepare-drivers-manual = Saya akan menginstal driver sendiri
prepare-drivers-manual-detail = Windows Update tidak akan menginstal driver, jadi Anda perlu mendapatkannya dari produsen PC atau perangkat Anda. Driver yang sudah terinstal tetap dipertahankan.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Driver
iso-network-drivers = Sertakan driver Wi-Fi dan Ethernet PC ini
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Pilih setelah masuk
prepare-network-unmetered = Pembaruan memerlukan koneksi internet yang tidak terukur. Hubungkan ke Wi-Fi atau Ethernet, lalu coba lagi.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows melaporkan bahwa jaringan ini tidak memiliki akses internet. Masuk ke jaringan jika diminta, atau periksa router serta pemfilteran DNS atau firewall, lalu coba lagi.
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = Koneksi ini terukur atau memiliki batas data. Hubungkan ke jaringan yang tidak terukur, atau nonaktifkan Koneksi terukur di pengaturan jaringan, lalu coba lagi.
prepare-network-settings = Buka pengaturan jaringan
iso-stage-network-drivers = Menyiapkan driver jaringan
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Adaptor jaringan PC ini menggunakan driver bawaan Windows, sehingga ISO tidak perlu menyertakannya.
desktop-setup-description = Selesaikan penyiapan PC Anda. Pilihan Atlas tersimpan; Anda dapat kembali ke Windows jika perlu.
desktop-setup-exit = Lanjutkan di Windows

# Windows installation USB
usb-title = Buat drive USB
usb-existing = Buat drive USB dari ISO yang sudah ada
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = Drive USB
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = ISO Windows
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = Tidak ada ISO Atlas di folder Unduhan Anda.
usb-iso-checking = Memeriksa ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas tidak dapat membuat drive USB dari ISO ini. Gunakan ISO yang dibuat oleh Atlas, atau ISO Windows 11 dari Microsoft untuk versi yang didukung Atlas.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO atau Atlas Manager berada di lokasi jaringan atau folder tertaut. Pindahkan ke folder di PC ini, seperti Unduhan.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Ruang kosong di drive Windows tidak cukup untuk menyiapkan ISO ini. Kosongkan sebagian ruang, dan Atlas akan memeriksa lagi dengan sendirinya.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas tidak dapat membaca ISO ini. Coba lagi, atau gunakan ISO lain.
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = Buka pengaturan Penyimpanan
usb-looking = Mencari drive USB…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Hubungkan drive USB berukuran { $size } GB atau lebih.
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = Terlalu kecil. Memerlukan { $size } GB atau lebih.
usb-drive-too-small-iso = Terlalu kecil untuk ISO ini
usb-drive-has-iso = ISO Anda ada di drive ini
usb-drive-has-app = Atlas Manager berjalan dari drive ini
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, an ISO's architecture and size under its name, and
# ready-checks-passed-some and ready-checks-handled on Get ready.
usb-detail-separator = { " · " }
usb-create = Buat drive USB
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = Pilih drive USB terlebih dahulu
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = Hapus isi { $drive } ({ $size }, { $letters })?
usb-confirm-title = Hapus isi { $drive } ({ $size })?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Hapus isi drive USB ({ $size }, { $letters })?
usb-confirm-title-unnamed = Hapus isi drive USB ({ $size })?
usb-confirm-message = Semua isinya akan dihapus. ISO Anda tetap disimpan.
usb-confirm-erase = Hapus isi dan buat
usb-progress-title = Membuat drive USB…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Menyiapkan file
usb-stage-formatting = Memformat
usb-stage-copying = Menyalin file
usb-stage-checking = Memeriksa drive
usb-stage-ejecting = Mengeluarkan
usb-keep-open = Biarkan Atlas tetap terbuka dan drive tetap terhubung.
usb-scan-failed-title = Tidak dapat membaca daftar drive USB
usb-scan-failed-retry = Atlas tidak dapat membaca drive yang terhubung ke PC ini. Coba lagi.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Tidak dapat membuat drive USB
usb-complete-title = Drive USB Anda siap
# F12, F11 and Esc are key names.
usb-ready = Cabut drive, cadangkan PC yang akan Anda instal ulang, lalu lakukan boot PC tersebut dari drive USB. Menu boot biasanya terbuka dengan F12, F11, atau Esc.
# After erasing may have begun.
usb-failed-partial = Sebagian drive sudah ditulis. Pastikan drive terhubung, lalu coba lagi.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas berhenti sebelum mengubah drive. Coba lagi.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = Drive USB berubah
usb-drive-changed = Drive dilepas atau dihubungkan kembali sebelum Atlas menghapus isinya, jadi isinya tidak berubah.
usb-drive-cancelled-title = Pembuatan drive USB dibatalkan
usb-cancelled-partial = Drive belum lengkap. Buat ulang sebelum menggunakannya.
usb-cancelled-unchanged = Drive USB Anda tidak diubah.
usb-eject-failed-title = Tidak dapat mengeluarkan drive USB
usb-eject-failed-ready = Drive siap digunakan. Tutup file atau jendela yang menggunakannya, lalu coba lagi.
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = Atlas memerlukan izin untuk membuat drive USB
usb-admin-reason = Atlas memerlukan izin administrator untuk menghapus isi dan menulis drive.
usb-elevation-declined = Windows tidak memberikan izin kepada Atlas, sehingga Atlas belum dapat menulis drive USB.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Edisi Windows 11 Home, LTSC, dan Server tidak didukung. Gunakan edisi lain, seperti Pro, Education, atau Enterprise. Jika Windows tidak dapat mengenali edisi Anda, selesaikan masalah tersebut sebelum melanjutkan.
install-source-title = Penginstalan tidak tersedia
install-source-unsupported = Atlas { $source } tidak dapat diperbarui langsung ke { $target }. Untuk menggunakan versi ini, cadangkan file Anda dan instal ulang Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } tidak dapat diperbarui langsung. Untuk menggunakan versi yang lebih baru, cadangkan file Anda dan instal ulang Windows.
# $folder is a folder path (text).
install-source-resume-package = Penginstalan Atlas { $target } tidak selesai, dan hanya paket Atlas { $target } yang dapat menyelesaikannya. Buka paket Atlas tersebut (.atlaspkg). Jika Atlas mengunduhnya, paket tersebut ada di { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Penginstalan Atlas { $target } tidak selesai. Versi uji ini hanya dapat menginstal paket Atlas bawaannya, jadi selesaikan penginstalan tersebut dengan paket Atlas { $target } di versi rilis Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas tidak dapat memastikan apa yang sudah terinstal di PC ini, jadi Atlas tidak akan menginstal apa pun untuk saat ini.
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = PC ini memiliki file dari Atlas versi sebelumnya, tetapi tidak ada catatan penginstalan yang selesai, jadi Atlas tersebut tidak dapat diperbarui. Untuk menginstal Atlas, cadangkan file Anda dan instal ulang Windows.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Di Penyiapan Windows, pilih edisi yang lisensinya Anda miliki.
detail-windows-preview = Build Insider tidak didukung. Gunakan rilis publik Windows 11.
detail-windows-release-unknown = Atlas tidak dapat memastikan bahwa build Windows ini merupakan rilis publik. Hubungkan ke internet, lalu periksa lagi.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Build { $build } tidak ada dalam daftar rilis publik Windows 11 dari Microsoft, sehingga Atlas belum dapat diinstal pada build ini. Build Release Preview dan build pratinjau lainnya tidak didukung. Periksa lagi setelah Microsoft mencantumkan build ini.


prepare-continue = Lanjutkan pembaruan
prepare-saving-restart = Menyimpan pilihan Anda dan mengatur Atlas agar terbuka kembali setelah Windows dimulai ulang…
prepare-restart-save-failed = Pilihan Anda tidak dapat disimpan. Coba lagi sebelum memulai ulang.
prepare-restart-registration-failed = Pilihan Anda tersimpan, tetapi Atlas tidak dapat mengatur agar terbuka kembali setelah PC dimulai ulang. Coba lagi, atau mulai ulang PC Anda sendiri dan buka Atlas setelah Anda masuk.
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = Pilihan Anda tersimpan, tetapi selama Atlas Manager berada di folder tertaut, Atlas tidak dapat mengatur agar terbuka kembali setelah PC dimulai ulang. Tutup Atlas dan pindahkan Atlas Manager ke folder lokal di PC ini. Setelah itu, buka dari sana, atau mulai ulang PC Anda sendiri dan buka dari sana setelah Anda masuk.
prepare-restart-failed = Atlas tidak dapat memulai ulang PC Anda. Coba lagi, atau mulai ulang PC melalui menu Mulai. Pilihan Anda tersimpan, dan Atlas akan terbuka kembali setelah Anda masuk.
diagnostics-export = Ekspor diagnostik
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Mengumpulkan diagnostik…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Dapatkan bantuan
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnostik disimpan
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Disimpan sebagai { $file } di folder { $folder } milik Atlas.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas telah menghapus nama pengguna, nama PC, dan alamat email Anda, serta kata sandi atau kunci yang dikenali, dari file ini.
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = Tidak dapat menyimpan ZIP diagnostik

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Versi uji Atlas { $release }. Aplikasi ini hanya menginstal paket Atlas bawaan.
home-status-bundled = Versi uji { $release }
package-bundled = Atlas { $version } bawaan versi uji ini siap diinstal.
rc-about-release = Versi uji
rc-about-commit = Commit sumber
rc-about-package = Paket Atlas bawaan (SHA-256)
iso-package-bundled = Paket Atlas bawaan versi uji ini

check-user-account = Akun pengguna
detail-user-account-ok = UAC aktif dan akun Anda siap untuk penginstalan.
detail-user-account-not-ready = Aktifkan Kontrol Akun Pengguna (UAC), mulai ulang PC, lalu coba lagi. Jika Anda menggunakan akun Administrator bawaan, masuk dengan akun administrator lain.
detail-user-account-work-or-school = Atlas tidak dapat diinstal dari akun kerja atau sekolah (Microsoft Entra ID). Masuk dengan akun lokal atau akun Microsoft, lalu coba lagi.
detail-user-account-check-failed = Atlas tidak dapat memeriksa akun pengguna Anda. Mulai ulang PC, lalu buka kembali Atlas dan periksa lagi. Windows melaporkan: { $error }

footer-prepare-required = Selesaikan pembaruan Windows dan aplikasi Store untuk melanjutkan
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Menghentikan pembaruan setelah tahap saat ini…
resume-choices-title = Melanjutkan penginstalan sebelumnya
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = Atlas menggunakan pilihan yang Anda buat sebelumnya untuk menyelesaikan penginstalan tersebut, jadi pilihan ini tidak dapat diubah hingga selesai.

## Voluntary reports
report-title = Kirim laporan
report-received = Laporan diterima
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Simpan referensi ini jika Anda menghubungi tim Atlas tentang laporan ini. Jika Anda mencantumkan detail kontak, tim mungkin menggunakannya untuk membalas, tetapi balasan tidak dijamin.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Salin referensi laporan
report-another = Kirim laporan lain
# Label of the choice between the two kinds of report.
report-kind = Apa yang ingin Anda kirim?
report-kind-issue = Masalah
report-kind-suggestion = Saran
report-message = Pesan Anda
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Apa yang terjadi, dan apa yang sedang Anda lakukan?
report-message-placeholder-suggestion = Apa yang sebaiknya diubah?
# Under the message box, which also reads it out.
report-message-help = Jangan sertakan kata sandi.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } dari { $max } karakter
report-contact = Kontak (opsional)
report-contact-placeholder = Email atau nama pengguna Discord
report-attach = Sertakan diagnostik
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = Log dan detail sistem yang membantu menemukan penyebab masalah. Atlas menghapus nama pengguna, nama PC, dan alamat email Anda, serta kata sandi atau kunci yang dikenali. Detail kesalahan, model perangkat keras, dan nama aplikasi tetap disertakan. Anda dapat meninjau ZIP sebelum mengirim.
report-review = Tinjau ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = Tidak dapat menyiapkan diagnostik
report-prepare-failed-advice = Coba lagi, atau kirim tanpa diagnostik.
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = Laporan Anda dikirim secara pribadi ke tim Atlas di reports.atlasos.net. Pesan dan detail kontak Anda dikirim persis seperti yang Anda tulis. Tim mungkin menggunakan layanan AI dari perusahaan lain untuk membantu penyelidikan. Layanan tersebut menerima pesan dan diagnostik Anda, tetapi tidak menerima detail kontak Anda. Laporan dihapus setelah 90 hari, dan log keamanan server mungkin mencatat alamat IP Anda.
report-website = Privasi dan situs laporan
report-consent = Saya setuju mengirim laporan ini dan diagnostik yang disertakan ke tim Atlas
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = Periksa koneksi internet Anda, lalu coba lagi. Anda juga dapat mengirimnya dari situs laporan.
report-not-sent-busy = Layanan laporan sedang sibuk. Tunggu beberapa menit, lalu coba lagi.
report-not-sent-outdated = Versi Atlas Manager ini tidak dapat mengirim laporan. Salin pesan Anda ke situs laporan, beserta ZIP jika Anda menyertakan diagnostik.
report-not-sent-diagnostics = Diagnostik tidak dapat dikirim. Coba lagi, atau kirim tanpa diagnostik.
# The footer's button where this version can't send.
report-failed-website = Buka situs laporan
# Beside a spinner in the footer while the report is on its way.
report-sending = Mengirim…
report-send = Kirim laporan

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = Masukkan { $min }–{ $max } karakter.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = Batasi detail kontak hingga { $max } karakter.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Konfirmasikan persetujuan untuk mengirim laporan ini.

report-failed-title = Laporan belum terkirim

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = File dan aplikasi Anda tetap ada.
home-plan-name = Pembaruan ini terdiri dari dua bagian
home-plan-windows-title = Windows 11, versi { $release }
home-plan-windows-step = Atlas menginstalnya dari Windows Update, lalu PC Anda dimulai ulang.
# The same step where moving is optional.
home-plan-windows-step-ask = Opsional. Atlas bertanya terlebih dahulu, lalu menginstalnya dari Windows Update dan PC Anda dimulai ulang.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Terinstal.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas diperbarui tanpa mengubah pilihan Anda, lalu PC Anda dimulai ulang.
# $date and $until are dates.
home-end-of-updates-title = Windows 11, versi { $current } berhenti menerima pembaruan keamanan pada { $date }
home-end-of-updates-past-title = Windows 11, versi { $current } tidak lagi menerima pembaruan keamanan
home-end-of-updates-message = Pembaruan ke Atlas { $version } juga meningkatkan PC ini ke Windows 11, versi { $release }, yang menerima pembaruan keamanan hingga { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11, versi { $release } menerima pembaruan keamanan hingga { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } berfungsi dengan Windows 11 Pro, Enterprise, dan Education, sehingga tidak dapat diinstal di { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } berfungsi dengan Windows 11 Pro, Enterprise, dan Education, sehingga tidak dapat diinstal di { $product }. Windows 11, versi { $current } menerima pembaruan keamanan hingga { $date }, dan Windows Update dapat meningkatkan PC ini ke versi yang lebih baru.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } berfungsi dengan Windows 11 Pro, Enterprise, dan Education, sehingga tidak dapat diinstal di { $product }. Versi { $current } tidak lagi menerima pembaruan keamanan, jadi tetap perbarui Windows meskipun tanpa Atlas.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version } berfungsi dengan Windows 11 Pro, Enterprise, dan Education. Edisi LTSC tidak didukung.
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } memerlukan Windows 11, versi { $releases }, dan Windows Update tidak dapat meningkatkan PC ini ke versi tersebut. Cadangkan file Anda, lalu instal ulang Windows dengan ISO Atlas.
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } memerlukan Windows 11, versi { $releases }, dan Windows Update tidak dapat meningkatkan PC ini ke versi tersebut.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Pengaturan Windows Update diubah untuk pembaruan Atlas
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas akan mengembalikan pengaturan ini setelah pembaruan selesai.
# When the last check found no offer yet.
home-update-access-waiting = Atlas mengaktifkan Windows Update untuk meningkatkan PC ini ke Windows 11, versi { $release }, tetapi Windows Update belum menawarkannya.
home-update-access-updating = Atlas mengaktifkan Windows Update untuk menginstal pembaruan dan belum selesai.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Tidak dapat membaca catatan Windows Update milik Atlas
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas tidak dapat membaca catatannya tentang pengaturan Windows Update yang diubahnya, sehingga Atlas tidak akan mengubah atau mengembalikan apa pun.
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas tidak dapat mengembalikan pengaturan.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = Selesaikan penginstalan Atlas terlebih dahulu. Tahap terakhir penginstalan akan mengembalikan pengaturan Windows Update yang diubah Atlas.
home-continue-update = Lanjutkan pembaruan
home-put-back = Kembalikan pengaturan
home-putting-back = Mengembalikan pengaturan…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11, versi { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } tidak mendukung versi { $current }, jadi Atlas memperbarui Windows terlebih dahulu.
# Under the title where moving is optional.
windows-optional = Atlas berfungsi dengan kedua versi.
# The choice's accessible name; the two answers say it.
windows-card-question = Versi Windows mana yang sebaiknya digunakan PC ini?
windows-choice-move-recommended = Perbarui ke Windows 11, versi { $release } (disarankan)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Pembaruan keamanan hingga { $date }.
windows-choice-keep = Pertahankan Windows 11, versi { $current }
windows-choice-keep-later = Tetap di versi { $current }. Anda dapat meningkatkannya nanti dari Atlas Manager.
windows-card-facts = Yang berubah
windows-fact-files = File dan aplikasi Anda tetap ada. Atlas menerapkan kembali apa pun yang dibatalkan oleh pembaruan.
windows-fact-time = Biasanya beberapa menit, hingga 2 jam, lalu PC dimulai ulang.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Menghapus Windows PowerShell 2.0 dan WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Cara membatalkan pembaruan
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Dengan memperbarui, Anda menerima Ketentuan Lisensi Perangkat Lunak Microsoft.
windows-terms-link = Baca ketentuan lisensi
windows-accept = Terima dan perbarui
# Once the terms are accepted, before the move starts by itself.
windows-starting = Memulai…
windows-starts-after-checks = Dimulai setelah pemeriksaan berhasil.
windows-starts-after-package = Dimulai setelah Atlas { $version } siap.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = Versi { $release } mengatur ulang sebagian perubahan Atlas. Atlas { $version } akan menerapkannya kembali dengan pilihan Anda sebelumnya.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Pertahankan Windows 11, versi { $current }?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas mengaktifkan Windows Update untuk sementara
access-off = Windows Update dinonaktifkan di PC ini. Atlas mengaktifkannya kembali selama memperbarui Windows.
access-paused = Pembaruan Windows dijeda di PC ini. Atlas membatalkan jeda tersebut selama memperbarui Windows.
access-delayed = Pembaruan bulanan ditunda di PC ini. Atlas menghapus penundaan tersebut selama memperbarui Windows.
# After the lines above.
access-back = Setelah Atlas { $version } terinstal, pengaturan ini dikembalikan seperti semula.
access-back-stop = Jika Anda berhenti sebelum itu, Atlas akan mengembalikannya.

prepare-reason-feature-update = versi Windows baru
prepare-reason-feature-commit = penyelesaian versi Windows baru
prepare-reason-apprepository = penghapusan catatan aplikasi yang tersisa
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Menunggu Windows Update menawarkan Windows 11, versi { $release }…
windows-waiting-detail = Biasanya beberapa menit, hingga 2 jam. Atlas melanjutkan dengan sendirinya; Anda tetap dapat menggunakan PC.
windows-waited = Sudah menunggu { $minutes } menit.
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update tidak menawarkan versi { $release } dalam 2 jam
windows-wait-ended = Atlas sudah mengembalikan pengaturan Anda. Coba lagi nanti, atau instal ulang Windows dengan ISO Atlas.
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas tidak dapat mengembalikan pengaturan Windows Update Anda.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows tidak dapat menyiapkan mulai ulang
windows-commit-failed = PC Anda tidak dimulai ulang. Coba lagi.

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update belum menawarkan versi { $release }
windows-outcome-not-offered = Ini dapat memerlukan waktu hingga 2 jam. PC Anda masih menggunakan versi { $current }.
windows-outcome-hardware-title = PC ini tidak memenuhi persyaratan Windows 11
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = PC ini tidak memiliki { $missing }, sehingga Windows Update tidak akan menawarkan versi { $release }. Cadangkan file Anda, lalu instal ulang Windows dengan ISO Atlas.
hardware-tpm = TPM 2.0
hardware-uefi = firmware UEFI
windows-outcome-hidden-title = Versi { $release } disembunyikan di Windows Update
windows-outcome-hidden = Tampilkan kembali dengan alat yang Anda gunakan untuk menyembunyikannya, lalu coba lagi.
windows-outcome-disk-space-title = Ruang kosong tidak cukup
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows memerlukan ruang kosong { $needed } GB di { $drive }, sedangkan yang tersedia { $free } GB. Atlas akan melanjutkan dengan sendirinya setelah ruangnya cukup.
windows-outcome-managed-title = PC ini mendapatkan pembaruan dari organisasinya
windows-outcome-managed = Server pembaruannya tidak menawarkan versi { $release }, jadi Atlas tidak mengubah apa pun. Tanyakan kepada organisasi Anda, atau instal ulang Windows dengan ISO Atlas.
windows-outcome-policy-title = Sesuatu terus mengubah kembali Windows Update
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = { $setting } kembali seperti semula setelah Atlas mengubahnya, sehingga Atlas tidak dapat memperbarui Windows. Jika PC ini dikelola oleh organisasi, tanyakan kepada mereka.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Layanan dinonaktifkan: { $service }
windows-outcome-blocked-service = Windows Update memerlukan layanan ini. Atur ke Manual di Layanan, lalu coba lagi.
windows-outcome-blocked-title = Sesuatu membuat Windows Update tetap nonaktif
windows-outcome-blocked = Pengaturan yang tidak diubah Atlas, { $setting }, mencegahnya berjalan. Ubah pengaturan tersebut, lalu coba lagi.
windows-outcome-rollback-title = Windows tidak dapat menyelesaikan penginstalan versi { $release }
windows-outcome-rolled-back = Windows kembali ke versi { $current }. File dan aplikasi Anda tidak terpengaruh.
windows-outcome-components-lost-title = Sebagian perubahan Atlas hilang
windows-outcome-components-lost = Atlas tidak dapat mengetahui penyebabnya, sehingga berhenti sebelum menginstal Atlas { $version }.
windows-outcome-build-title = Versi Windows berubah selama pembaruan
windows-outcome-build = Kembalikan pengaturan yang diubah Atlas, lalu mulai lagi dari Beranda.
windows-outcome-journal-title = Atlas tidak dapat membaca catatannya tentang pembaruan ini
windows-outcome-journal = Atlas tidak akan mengubah atau mengembalikan apa pun sampai tim Atlas memeriksanya.
windows-outcome-pin-title = Kebijakan Windows Update tidak dapat dicatat
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } memiliki nilai yang tidak dapat dikembalikan Atlas nanti, sehingga Atlas tidak mengubah apa pun.
windows-outcome-terms-title = Ketentuan lisensi belum diterima
windows-outcome-terms = Windows Update memerlukannya sebelum menginstal versi { $release }.
windows-outcome-failed-title = Windows tidak dapat menginstal versi { $release }
windows-outcome-failed = PC Anda masih menggunakan versi { $current }.
# Windows services a move needs, as Services lists them, in Microsoft's Indonesian terms.
# Check them against Services on Indonesian Windows.
service-bits = Layanan Transfer Cerdas Latar Belakang (BITS)
service-cryptsvc = Layanan Kriptografi
service-trusted-installer = Penginstal Modul Windows
prepare-open-services = Buka Layanan
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Pertahankan versi { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Hentikan pembaruan ke Atlas { $version }?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Hentikan pembaruan Windows?
stop-update-before = Atlas akan mengembalikan pengaturan Windows Update yang diubahnya. Pembaruan yang sudah diinstal Windows tetap terinstal, dan PC Anda tetap menggunakan Windows 11, versi { $current }.
stop-update-after = PC Anda tetap menggunakan Windows 11, versi { $release }. Atlas akan mengembalikan pengaturan Windows Update yang diubahnya.
stop-update-access = Atlas akan mengembalikan pengaturan Windows Update yang diubahnya. Pembaruan yang sudah diinstal Windows tetap terinstal.
stop-update-keep = Teruskan pembaruan
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Tutup Atlas?
window-close-update-access-message = Sebelum ditutup, Atlas akan mengembalikan pengaturan Windows Update yang diubahnya. Anda dapat memulai pembaruan lagi dari Beranda.
window-close-put-back = Kembalikan dan tutup
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Tutup tanpa mengembalikan pengaturan?
window-close-put-back-failed-message = Jika Anda menutup Atlas sekarang, pengaturan Windows Update tetap seperti yang diubah Atlas. Saat Anda membuka Atlas lagi, Beranda akan menawarkan untuk mengembalikannya.

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = Versi Atlas ini memerlukan Windows 11, versi { $release }, sedangkan PC ini menggunakan versi { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Pembaruan Windows untuk Atlas tidak selesai. Detail untuk tim Atlas:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = penginstalan ulang setelah pembaruan Windows
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Pilihan Anda dari Atlas { $previous }
rebase-choices-kept = Atlas menerapkan kembali pilihan yang Anda buat untuk Atlas { $previous }, dan Anda dapat mengubahnya nanti dengan menginstal ulang Atlas.
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas menerapkan kembali semua pilihan lain yang Anda buat untuk Atlas { $previous }.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Mulai ulang saat pengguna lain sedang masuk?
restart-others-question = Mulai ulang saat beberapa pengguna lain sedang masuk?
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
       *[other] { $names } juga sedang masuk. Memulai ulang akan menutup aplikasi di akun tersebut, dan pekerjaan yang belum disimpan akan hilang.
    }
restart-others-keep = Jangan mulai ulang
restart-others-restart = Tetap mulai ulang
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Memperbarui Microsoft Store…
prepare-store-repairing = Memperbaiki Microsoft Store…
prepare-store-repair-detail = Ini dapat memerlukan waktu beberapa menit.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = Microsoft Store dinonaktifkan di PC ini, sehingga aplikasi Store tidak diperbarui.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store tidak berfungsi
prepare-store-broken = Atlas tidak dapat memperbaikinya, dan menginstal Atlas sekarang dapat merusak aplikasi Store.
prepare-store-broken-iso = Jika perbaikan terus gagal, cadangkan file Anda dan instal ulang Windows dengan ISO Atlas.
prepare-repair-store-again = Coba perbaiki lagi
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows tidak dapat memperbarui aplikasi bawaannya
prepare-store-staging = Windows tidak dapat menginstal pembaruan untuk aplikasi bawaan ini, dan perbaikan dari Atlas tidak membantu: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Bahasa keyboard
screen-keyboard-question = Apakah Anda menggunakan beberapa bahasa keyboard?
package-option-keyboard-shortcuts = Ya, dengan pintasan keyboard
package-option-keyboard-selector = Ya, dengan pemilih di taskbar
package-option-keyboard-single = Tidak, saya hanya menggunakan satu tata letak
consequence-keyboard-shortcuts = Alt+Shift mengganti bahasa; Ctrl+Shift mengganti tata letak.
consequence-keyboard-selector = Menonaktifkan Alt+Shift dan Ctrl+Shift agar tidak berganti tanpa sengaja saat bermain game.
package-choice-keyboard-description = Pilih cara mengganti bahasa keyboard.
# Written out rather than referencing consequence-keyboard-selector, with the same text.
consequence-keyboard-single = Menonaktifkan Alt+Shift dan Ctrl+Shift agar tidak berganti tanpa sengaja saat bermain game.
