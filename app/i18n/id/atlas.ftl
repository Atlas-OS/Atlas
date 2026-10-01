### Atlas Manager: Bahasa Indonesia (id). Preview translation, revised on 1 October 2026 from the en-GB source; native-speaker review pending.
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
###   category exists.
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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
common-open-log-file = Buka file log
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Salin log penginstalan
common-install-log = Log penginstalan
# Row labels in summary cards.
common-windows = Windows
common-options = Pilihan
common-package = File penginstalan
common-installed-as = Jenis penginstalan
common-installed = Terinstal
common-checking = Memeriksa
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } atau { $b }
list-and = { $a } dan { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Tutup jendela saat Atlas sedang diinstal?
window-close-message = Penginstalan akan berlanjut di latar belakang. Buka Atlas lagi untuk melihat kemajuan dan hasilnya. Biarkan PC tetap menyala hingga penginstalan selesai.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = Penginstalan akan berlanjut di latar belakang, tetapi PC Anda tidak akan dimulai ulang secara otomatis selama Atlas ditutup. Buka Atlas lagi untuk melihat kemajuan dan hasilnya. Biarkan PC tetap menyala hingga penginstalan selesai.
window-close-keep = Biarkan terbuka
window-close-close = Tutup jendela
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = Tutup sebelum penginstalan dimulai?
window-close-preparing-message = Atlas masih memeriksa PC Anda dan belum mulai menginstal. Jika Anda menutup jendela sekarang, penginstalan tidak akan dimulai. Buka Atlas lagi untuk melanjutkan.
prepare-close-title = Pembaruan masih berjalan
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Biarkan Atlas tetap terbuka selama pembaruan berjalan. Jika Anda memilih Hentikan pembaruan, pembaruan akan berhenti setelah langkah saat ini, lalu Anda dapat menutup Atlas.
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = Tutup Atlas tanpa memulai ulang?
# "Restart now" is restart-now, one of this dialog's three buttons.
window-close-restart-message = PC Anda perlu dimulai ulang untuk menyelesaikan penyiapan Atlas. Jika Anda menutup Atlas sekarang, Atlas tidak akan memulai ulang PC Anda, jadi mulai ulang PC sendiri saat Anda siap. Simpan pekerjaan Anda sebelum memilih Mulai ulang sekarang.
window-close-restart-close = Tutup tanpa memulai ulang
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Tutup Atlas saat perlindungan masih nonaktif?
window-close-protection-message = Beberapa perlindungan di Keamanan Windows masih nonaktif: { $switches }. Jika Anda tidak akan menyelesaikan penginstalan Atlas, aktifkan kembali perlindungan tersebut sebelum menutup Atlas. Jika Anda akan menyelesaikannya, Atlas akan melanjutkan penyiapan Anda saat dibuka lagi.
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Buka paket Atlas (.apbx)
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
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas di PC ini
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Diinstal pada { $date }
home-status-checking = Memeriksa pembaruan
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
home-restart-title = PC Anda perlu dimulai ulang
home-security-reminder-title = Aktifkan kembali perlindungan Anda
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Pastikan perlindungan Anda aktif
home-security-reminder-message = Atlas tidak sedang menginstal apa pun, tetapi beberapa perlindungan di Keamanan Windows masih nonaktif. Buka Keamanan Windows dan pastikan pengaturan berikut aktif: { $switches }.
home-security-reminder-unreadable-message = Atlas tidak dapat memeriksa semua pengaturan perlindungan. Pastikan pengaturan berikut aktif di Keamanan Windows: { $switches }.
home-elevation-title = Atlas memerlukan izin untuk menginstal
home-state-error-title = Tidak dapat membaca detail penginstalan Atlas Anda
home-state-error-message = Versi Atlas, pilihan, dan riwayat Anda mungkin tidak ditampilkan dengan benar. Pilih Periksa lagi untuk mencoba lagi. Detail: { $error }
home-whats-new = Yang baru di Atlas { $version }
home-view-release = Lihat catatan rilis di GitHub
home-released = Dirilis pada { $date }
home-show-less = Tampilkan lebih sedikit
home-show-full-notes = Tampilkan semua catatan rilis
home-your-install = Penyiapan Atlas Anda
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = PC ini tidak memiliki catatan tentang cara Atlas diinstal, sehingga pilihan dan riwayat penginstalan Anda tidak dapat ditampilkan.
# Row label: how Atlas was set up.
home-set-up = Metode penyiapan
home-set-up-during-oobe = Saat penyiapan Windows
home-history = Riwayat penginstalan
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Mari siapkan PC Anda untuk Atlas
home-step-1-detail = Atlas memeriksa PC Anda, menginstal pembaruan Windows dan Microsoft Store yang tertunda, lalu mengunduh file penginstalan. Aplikasi Store mungkin ditutup dan PC Anda mungkin perlu dimulai ulang, jadi simpan pekerjaan Anda terlebih dahulu.
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas memeriksa PC Anda, menginstal pembaruan Windows dan Microsoft Store yang tertunda, lalu menyiapkan file penginstalan bawaan. Aplikasi Store mungkin ditutup dan PC Anda mungkin perlu dimulai ulang, jadi simpan pekerjaan Anda terlebih dahulu.
home-step-2-detail = Pilih apakah akan mempertahankan Microsoft Defender dan perlindungan prosesor, cara pembaruan Windows diinstal, dan tambahan opsional yang Anda inginkan.
home-step-3-detail = Nonaktifkan empat pengaturan perlindungan di Keamanan Windows agar tidak menghalangi penginstalan. Atlas akan menunjukkan caranya.
# Indonesian has no plural forms; one wording covers every count.
home-step-4-detail = Penginstalan memerlukan waktu sekitar { $minutes } menit. Setelah itu, PC Anda perlu dimulai ulang.
# Accessible name of a numbered step.
home-step-a11y = Langkah { $number }: { $title }
home-github = Lihat Atlas di GitHub
home-discord = Bergabung dengan komunitas Atlas di Discord
home-report-problem = Laporkan masalah

## How an install was done (from the state document)

mode-fresh = Penginstalan pertama
mode-upgrade = Pembaruan dari versi sebelumnya
mode-reapply = Penginstalan ulang versi yang sama
mode-unknown = Penginstalan
# Lower-case forms used inside a history row.
history-mode-fresh = penginstalan pertama
history-mode-upgrade = pembaruan
history-mode-reapply = penginstalan ulang
history-mode-unknown = penginstalan

## Notices on the Home page

notice-settings-reset-title = Atlas menggunakan pengaturan aplikasi bawaan
# $error is a raw error message (text).
notice-settings-unreadable = Atlas tidak dapat membaca pengaturan aplikasi yang tersimpan. Pengaturan Windows Anda tidak berubah. Detail: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = File pengaturan aplikasi rusak dan telah diatur ulang. Salinan file lama disimpan sebagai { $file }. Detail: { $error }
notice-settings-damaged = File pengaturan aplikasi rusak. Atlas menggunakan pengaturan bawaan untuk sementara. Detail: { $error }
notice-settings-not-saved-title = Tidak dapat menyimpan pengaturan aplikasi
# $error is a raw error message (text).
notice-settings-not-saved = Atlas tidak dapat menyimpan perubahan terbaru Anda, sehingga perubahan tersebut mungkin hilang saat Atlas ditutup. Jika ada jendela Atlas lain yang terbuka, tutup jendela tersebut, lalu lakukan perubahan lagi. Detail: { $error }
notice-session-unreadable-title = Tidak dapat memeriksa penginstalan sebelumnya
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Langkah { $number } dari { $total }, { $title }, { $status }
stepper-status-completed = selesai
stepper-status-current = langkah saat ini
stepper-status-upcoming = belum dimulai
stepper-status-attention = perlu diperhatikan
# Heading above each step's content.
step-heading = Langkah { $number } dari { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Step 1: Get ready

ready-banner-busy-title = Menyiapkan PC Anda
ready-banner-busy-message = Atlas sedang memeriksa PC Anda dan menyiapkan file penginstalan.
ready-banner-blocked-title = PC Anda belum siap
ready-banner-blocked-message = Atasi item yang ditandai di Pemeriksaan PC, lalu pilih Periksa lagi.
ready-banner-no-package-title = Unduh Atlas untuk melanjutkan
ready-banner-no-package-message = Unduh Atlas di File penginstalan, atau pilih Buka file paket jika Anda sudah memiliki paket Atlas (.apbx).
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = Siapkan paket Atlas bawaan untuk melanjutkan
ready-banner-no-package-bundled-message = Paket Atlas bawaan versi uji ini belum siap. Periksa kartu File penginstalan.
ready-banner-updates-title = Perbarui Windows dan aplikasi Store untuk melanjutkan
ready-banner-updates-message = Pilih Periksa dan instal pembaruan. Setelah pembaruan selesai, Atlas akan memeriksa PC Anda lagi.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Memperbarui Windows dan aplikasi Store
ready-banner-updating-message = Proses ini mungkin memerlukan waktu. Biarkan Atlas tetap terbuka. Anda dapat memantau kemajuannya di Perbarui Windows dan aplikasi Store.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Pembaruan dihentikan
ready-banner-updates-stopped-message = Pilih Periksa dan instal pembaruan di Perbarui Windows dan aplikasi Store untuk menyelesaikannya.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = PC Anda telah dimulai ulang
ready-banner-updates-resumed-message = Pilih Lanjutkan pembaruan di Perbarui Windows dan aplikasi Store untuk menyelesaikan pembaruan.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Lihat langkah yang perlu dilakukan di Perbarui Windows dan aplikasi Store, lalu pilih Coba lagi.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Simpan pekerjaan Anda terlebih dahulu, lalu pilih Mulai ulang dan lanjutkan di Perbarui Windows dan aplikasi Store.
ready-banner-warnings-title = Ada beberapa hal yang perlu diperhatikan
ready-banner-warnings-message = Anda dapat melanjutkan, tetapi baca dahulu item yang ditandai di Pemeriksaan PC.
ready-banner-ok-title = Anda siap menentukan pilihan
ready-banner-ok-message = Semua pemeriksaan berhasil dan file penginstalan sudah siap.
# Card title and accessible name of the list of checks.
ready-this-pc = Pemeriksaan PC
ready-check-again = Periksa lagi
# Indonesian has no plural forms; one wording covers every count.
ready-checks-passed = { $count } pemeriksaan berhasil
package-title = File penginstalan
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Mengunduh Atlas { $version } · { $received } dari { $total } MB
# Indonesian has no plural forms; one wording covers every count.
package-unpacking-progress = Mengekstrak · { $done } dari { $total } file
package-unpacking = Mengekstrak
package-looking = Memeriksa versi Atlas terbaru.
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = Menyiapkan paket Atlas bawaan.
package-none = Unduh Atlas untuk mendapatkan file penginstalan. Jika Anda sudah memiliki paket Atlas (.apbx), buka paket tersebut.
# The GitHub release check failed. "Download latest version" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas tidak dapat memeriksa versi terbaru. Periksa koneksi internet Anda, lalu pilih Unduh versi terbaru, atau buka paket Atlas (.apbx) yang tersimpan.
# Short status words beside the card title.
package-status-downloading = Mengunduh
package-status-unpacking = Mengekstrak
package-status-failed = File tidak dapat disiapkan
package-status-ready = Siap
package-status-checking = Memeriksa
package-status-preparing = Menyiapkan
package-status-missing = Belum diunduh
# Accessible name of the progress bar.
package-progress = Kemajuan penyiapan file penginstalan
package-download-again = Unduh lagi
package-download-version = Unduh Atlas { $version }
package-download-newest = Unduh versi terbaru
package-cancel-download = Batalkan unduhan
package-open-file = Buka file paket
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } telah diunduh dari GitHub dan siap diinstal.
package-from-file = Atlas { $version } telah dimuat dari { $file } dan siap diinstal.
package-unpacked = Atlas { $version } siap diinstal.
package-none-yet = Belum ada file penginstalan yang dipilih
acquire-no-asset = Atlas { $version } tidak memiliki file paket yang dapat diunduh. Buka paket Atlas (.apbx) yang tersimpan untuk melanjutkan.
acquire-unsupported = Aplikasi ini dapat menginstal Atlas 0.6.0 dan yang lebih baru. Untuk menginstal Atlas { $version }, gunakan AME Wizard.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } tidak berisi file yang diperlukan aplikasi ini untuk menginstalnya. Unduh lagi, atau buka paket Atlas (.apbx) lain.
acquire-failed = Tidak dapat menyiapkan file penginstalan. Coba unduh lagi, atau buka paket Atlas (.apbx) lain. Detail: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = Unduhan berhenti merespons. Periksa koneksi internet Anda, lalu unduh lagi, atau buka paket Atlas (.apbx) yang tersimpan.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Tidak dapat menyiapkan paket Atlas bawaan. Pilih Coba lagi. Detail: { $error }

## System checks

check-administrator = Izin penginstalan
check-supported-build = Kompatibilitas Windows
check-pending-updates = Pembaruan Windows
check-pending-reboot = Mulai ulang yang tertunda
check-third-party-antivirus = Antivirus lain
check-internet = Koneksi internet
check-power = Daya
check-activation = Aktivasi Windows
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
check-fix-apps = Buka Aplikasi yang diinstal
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Saya sudah memeriksa Windows Update dan tidak ada pembaruan yang menunggu diinstal
detail-admin-ok = Atlas memiliki izin untuk membuat perubahan yang diperlukan untuk penginstalan.
detail-admin-missing = Jalankan ulang Atlas sebagai administrator, lalu pilih Ya saat Windows meminta izin.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Versi Atlas ini memerlukan Windows build { $builds }. PC Anda menggunakan build { $build }. Instal versi Windows yang didukung sebelum melanjutkan.
detail-build-missing = Paket Atlas ini tidak mencantumkan build Windows yang didukung. Gunakan build lengkap paket ini, bukan build LocalTest.
detail-updates-none = Tidak ada pembaruan Windows yang menunggu diinstal.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Pembaruan ini menunggu diinstal: { $titles }. Atlas menginstalnya di Perbarui Windows dan aplikasi Store.
        [2] Kedua pembaruan ini menunggu diinstal: { $titles }. Atlas menginstalnya di Perbarui Windows dan aplikasi Store.
       *[other] { $count } pembaruan menunggu diinstal, termasuk { $titles }. Atlas menginstalnya di Perbarui Windows dan aplikasi Store.
    }
detail-updates-unknown = Tidak dapat memeriksa pembaruan Windows. Buka Windows Update, lalu konfirmasikan di bawah jika tidak ada pembaruan yang menunggu. ({ $error })
detail-reboot-none = Windows tidak perlu dimulai ulang saat ini.
detail-reboot-pending = Windows perlu dimulai ulang untuk menyelesaikan perubahan sebelumnya. Saat Anda memilih Periksa dan instal pembaruan, Atlas akan meminta Anda memulai ulang terlebih dahulu.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Windows perlu dimulai ulang untuk menyelesaikan perubahan sebelumnya ({ $reasons }). Saat Anda memilih Periksa dan instal pembaruan, Atlas akan meminta Anda memulai ulang terlebih dahulu.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Anda dapat melanjutkan. Windows akan mengganti atau menghapus beberapa file saat PC dimulai ulang berikutnya ({ $files }). Beberapa aplikasi, seperti Xbox Gaming Services, melakukan ini setelah setiap mulai ulang.
detail-reboot-unknown = Tidak dapat memeriksa apakah Windows perlu dimulai ulang. Mulai ulang PC, lalu buka kembali Atlas dan periksa lagi. ({ $error })
detail-antivirus-none = Tidak ada antivirus lain yang terdeteksi.
# $products is a list of product names (text).
detail-antivirus-found = Aplikasi antivirus selain Microsoft Defender dapat menghalangi penginstalan. Hapus instalan { $products }, lalu pilih Periksa lagi.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Keamanan Windows masih mencantumkan { $products }, tetapi file-nya sudah tidak ada, jadi perangkat lunak ini sudah tidak terinstal lagi. Atlas tetap dapat melanjutkan penginstalan.
detail-antivirus-unknown = Tidak dapat memeriksa antivirus lain. Pilih Periksa lagi. Jika terus gagal, mulai ulang PC Anda, lalu periksa lagi. ({ $error })
detail-internet-ok = PC terhubung ke internet. Pertahankan koneksi ini saat Atlas mengunduh dan menginstal perangkat lunak.
detail-internet-missing = Hubungkan PC ke internet, lalu periksa lagi.
detail-power-mains = PC terhubung ke sumber listrik. Biarkan tetap terhubung hingga penginstalan selesai.
detail-power-battery = Hubungkan PC ke sumber listrik agar tetap menyala selama penginstalan.
detail-power-unknown = Atlas tidak dapat memastikan apakah PC Anda terhubung ke sumber listrik. Jika PC Anda laptop, hubungkan ke sumber listrik, lalu pilih Periksa lagi. Jika ini terus terjadi, pilih Kirim laporan.
detail-activation-ok = Windows sudah diaktifkan. Atlas tidak akan mengubahnya.
detail-activation-missing = Windows belum diaktifkan. Anda dapat melanjutkan, tetapi Atlas tidak akan mengaktifkan Windows untuk Anda.
detail-activation-no-licence = Windows tidak melaporkan adanya lisensi. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda.
detail-activation-unknown = Tidak dapat memeriksa aktivasi Windows. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda. ({ $error })

## Step 2: Options

options-progress = Pilihan { $number } dari { $total }
options-progress-extras = Pilihan { $number } dari { $total }: tambahan opsional
options-change-later = Anda dapat mengubah Microsoft Defender, perlindungan prosesor, dan pengaturan pembaruan nanti melalui folder Atlas di desktop.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Pertahankan Microsoft Defender?
screen-mitigations-title = Perlindungan prosesor
screen-mitigations-question = Pertahankan perlindungan prosesor Windows?
screen-updates-title = Windows Update
screen-updates-question = Bagaimana sebaiknya Windows menginstal pembaruan?
screen-browser-title = Browser
screen-power-title = Daya dan keamanan
screen-apps-title = Aplikasi
screen-optional-apps-title = Aplikasi opsional
screen-choose-one-title = Pilih salah satu
screen-extras-title = Tambahan opsional
# Question for a required choice this app has no specific wording for.
screen-generic-question = Pilih salah satu opsi untuk { $title }
learn-more-defender = Pelajari selengkapnya tentang Microsoft Defender
learn-more-mitigations = Pelajari selengkapnya tentang perlindungan prosesor
learn-more-updates = Pelajari selengkapnya tentang Windows Update
learn-more-browser = Pelajari selengkapnya tentang browser
learn-more-power = Pelajari selengkapnya tentang daya dan keamanan
learn-more-apps = Pelajari selengkapnya tentang aplikasi
learn-more-eclean = Cara eclean bekerja dengan AtlasOS
learn-more-generic = Baca panduan penyiapan
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mempertahankan antivirus bawaan Windows untuk membantu melindungi PC Anda dari virus dan ancaman lainnya.
consequence-defender-disable = Juga menghapus SmartScreen. PC Anda tidak akan memiliki perlindungan antivirus sampai Anda menginstal aplikasi antivirus lain, dan Windows tidak akan memperingatkan Anda sebelum Anda membuka aplikasi atau unduhan yang tidak dikenal.
consequence-mitigations-default = Mempertahankan perlindungan bawaan Windows terhadap celah keamanan prosesor dan serangan yang memanfaatkan bug dalam aplikasi.
consequence-mitigations-disable = Juga menonaktifkan Perlindungan eksploitasi untuk aplikasi, seperti Control Flow Guard. Ini mengurangi keamanan. Perbedaan kinerja, jika ada, bergantung pada prosesor Anda.
consequence-auto-updates-disable = Buka Windows Update secara rutin untuk menginstal pembaruan. Notifikasi pembaruan tetap aktif.
consequence-auto-updates-default = Windows akan menginstal pembaruan secara otomatis, termasuk perbaikan keamanan.

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Pertahankan Microsoft Defender (disarankan)
playbook-option-defender-disable = Hapus Microsoft Defender
playbook-option-mitigations-default = Pertahankan perlindungan prosesor (disarankan)
playbook-option-mitigations-disable = Nonaktifkan perlindungan prosesor
playbook-option-auto-updates-disable = Instal pembaruan sendiri
playbook-option-auto-updates-default = Instal pembaruan secara otomatis
playbook-option-disable-hibernation = Nonaktifkan hibernasi
playbook-option-disable-power-saving = Nonaktifkan penghematan daya
playbook-option-disable-core-isolation = Nonaktifkan keamanan berbasis virtualisasi (VBS)
playbook-option-remove-snipping-tool = Hapus Snipping Tool
playbook-option-uninstall-edge = Hapus Microsoft Edge
playbook-option-install-another-browser = Instal browser
playbook-option-install-toolbox = Instal Atlas Toolbox
playbook-option-install-eclean = Instal eclean
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender adalah antivirus bawaan Windows. Hapus hanya jika Anda memahami risikonya dan berencana menggunakan aplikasi antivirus lain. Apa pun pilihan Anda, Atlas menonaktifkan Kontrol Aplikasi Pintar, Perlindungan pengelabuan, dan Temukan perangkat saya.
playbook-page-mitigations-default-description = Perlindungan ini, yang juga disebut mitigasi keamanan, membantu melindungi dari celah keamanan prosesor, seperti Spectre dan Meltdown, serta dari serangan yang memanfaatkan bug dalam aplikasi. Sebaiknya pertahankan pengaturan bawaan Windows.
playbook-page-auto-updates-disable-description = Pembaruan Windows mencakup perbaikan keamanan. Anda dapat membiarkan Windows menginstalnya secara otomatis atau menginstalnya sendiri. Apa pun pilihan Anda, Atlas mempertahankan Windows pada versinya saat ini, yang menerima perbaikan keamanan hanya sampai Microsoft mengakhiri dukungan untuk versi tersebut. Atlas juga menonaktifkan pembaruan otomatis untuk aplikasi Microsoft Store, jadi perbarui aplikasi tersebut di Microsoft Store.
playbook-page-browser-brave-description = Pilih browser untuk diinstal. Atlas tidak akan mengubah pengaturan browser Anda.

## Step 3: Windows Security

security-banner-reading-title = Memeriksa Keamanan Windows
security-banner-reading-message = Atlas sedang memeriksa empat pengaturan perlindungan di bawah.
security-banner-off-title = Keempat pengaturan perlindungan sudah nonaktif
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender tidak terinstal di PC ini
security-banner-absent-message = Tidak ada yang perlu dinonaktifkan di langkah ini. Pilih Lanjutkan.
security-banner-off-message = Pilih Lanjutkan untuk meninjau penyiapan Anda dan menginstal Atlas.
security-banner-on-title = Nonaktifkan perlindungan antivirus di Keamanan Windows
security-banner-on-message = Microsoft Defender dapat memblokir perubahan yang dilakukan Atlas. Pilih Buka Keamanan Windows, lalu nonaktifkan setiap pengaturan yang tercantum di bawah. Jika Anda mempertahankan Microsoft Defender, aktifkan kembali pengaturan tersebut setelah penginstalan selesai.
# The page name in Windows Security.
security-list-title = Pengaturan perlindungan virus & ancaman
security-switch-off = Nonaktif
security-switch-on = Aktif
security-switch-unreadable = Tidak dapat diperiksa
security-switch-reading = Memeriksa
security-all-off = Semua nonaktif
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 can't be read".
security-count-still-on = { $count } masih aktif
security-count-unreadable = { $count } tidak dapat diperiksa
security-count-join = { $a }, { $b }
security-unknown-title = Konfirmasikan pengaturan yang tidak dapat diperiksa Atlas
security-unknown-message = Pastikan keempat pengaturan sudah nonaktif di Keamanan Windows, lalu konfirmasikan di bawah.
security-acknowledge = Saya sudah memeriksa Keamanan Windows dan keempat pengaturan sudah nonaktif
security-unknown-unelevated-title = Atlas memerlukan izin untuk memeriksa perlindungan
security-unknown-unelevated-message = Jalankan ulang Atlas sebagai administrator agar Atlas dapat memeriksa pengaturan Microsoft Defender.
# The four switches, named as Windows Security names them in Indonesian.
# "Proteksi Kerusakan" follows the Indonesian Windows interface; Microsoft's
# machine-translated support pages vary ("Proteksi perusak", "Perlindungan
# Perubahan"). Verify against a localized Windows build.
protection-tamper = Proteksi Kerusakan
protection-tamper-why = Nonaktifkan pengaturan ini agar Defender tidak memblokir Atlas saat mengubah pengaturan keamanan Defender.
protection-realtime = Perlindungan real-time
protection-realtime-why = Nonaktifkan pengaturan ini agar Defender tidak memblokir file penginstalan Atlas saat memindainya.
protection-cloud = Perlindungan yang dikirimkan cloud
protection-cloud-why = Nonaktifkan pengaturan ini agar pemeriksaan ancaman online tidak memblokir file penginstalan Atlas.
protection-samples = Pengiriman sampel otomatis
protection-samples-why = Cegah Defender mengirim file Atlas secara otomatis ke Microsoft untuk dianalisis.

## Step 4: Install

# Accessible name of the progress bar.
install-progress = Kemajuan penginstalan
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = Atlas sudah terinstal
outcome-lost-title = Hasil penginstalan tidak dapat dipastikan
outcome-failed-title = Penginstalan tidak selesai
outcome-requirements = PC Anda tidak memenuhi persyaratan penginstalan. Penginstalan belum mengubah apa pun. Kembali ke Persiapan dan jalankan pemeriksaan lagi.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = PC Anda tidak memenuhi persyaratan penginstalan, sehingga upaya ini berhenti. Upaya sebelumnya sudah mulai membuat perubahan. Kembali ke Persiapan dan jalankan pemeriksaan lagi.
outcome-not-elevated = Atlas tidak memiliki izin administrator. Penginstalan belum mengubah apa pun. Jalankan ulang Atlas sebagai administrator, lalu coba lagi.
outcome-not-elevated-resumed = Atlas tidak memiliki izin administrator, sehingga upaya ini berhenti. Upaya sebelumnya sudah mulai membuat perubahan. Jalankan ulang Atlas sebagai administrator, lalu coba lagi.
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "Check and install updates" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas tidak dapat memastikan bahwa Windows dan aplikasi Store sudah diperbarui, sehingga penginstalan berhenti sebelum mengubah Windows. Kembali ke Persiapan dan pilih Periksa dan instal pembaruan.
outcome-preparation-stale-resumed = Atlas tidak dapat memastikan bahwa Windows dan aplikasi Store sudah diperbarui, sehingga upaya ini berhenti. Upaya sebelumnya sudah mulai membuat perubahan. Kembali ke Persiapan dan pilih Periksa dan instal pembaruan.
outcome-failed-preflight = Penginstalan berhenti sebelum mengubah apa pun. Anda dapat mencoba lagi. Jika berhenti lagi, pilih Kirim laporan.
outcome-failed-staging = Penginstalan berhenti saat menyiapkan file, sebelum mengubah Windows. Anda dapat mencoba lagi. Jika berhenti lagi, pilih Kirim laporan.
outcome-failed-applying = Sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi. Jika Anda berhenti di sini, aktifkan kembali perlindungan yang tadi Anda nonaktifkan di Keamanan Windows, jika masih tersedia.
outcome-failed-resumed = Upaya ini berhenti lebih awal, tetapi upaya sebelumnya sudah mulai membuat perubahan. Anda dapat mencoba lagi. Jika Anda berhenti di sini, aktifkan kembali perlindungan yang tadi Anda nonaktifkan di Keamanan Windows, jika masih tersedia.
outcome-not-started = Penginstal tidak dimulai tepat waktu. Penginstalan belum mengubah apa pun. Anda dapat mencoba lagi.
outcome-lost = Penginstal berhenti tanpa melaporkan hasil, dan sebagian perubahan mungkin sudah diterapkan. Anda dapat mencoba lagi. Jika Anda berhenti di sini, aktifkan kembali perlindungan yang tadi Anda nonaktifkan di Keamanan Windows, jika masih tersedia.
restart-now-message = Windows sedang dimulai ulang untuk menyelesaikan penyiapan Atlas.
# Indonesian has no plural forms; one wording covers every count.
restart-countdown = Windows akan dimulai ulang dalam { $seconds } detik untuk menyelesaikan penyiapan Atlas. Untuk menyimpan pekerjaan Anda terlebih dahulu, pilih Mulai ulang nanti.
restart-stopped = Mulai ulang otomatis dibatalkan. Simpan pekerjaan Anda, lalu mulai ulang PC untuk menyelesaikan penyiapan Atlas.
restart-needed = Simpan pekerjaan Anda, lalu mulai ulang PC untuk menyelesaikan penyiapan Atlas.
restart-dont-now = Mulai ulang nanti
restart-now = Mulai ulang sekarang
restart-start-failed = Atlas tidak dapat memulai ulang PC Anda. Simpan pekerjaan Anda, lalu mulai ulang PC melalui menu Mulai. Detail: { $error }
preflight-title = Penginstalan belum dimulai
preflight-invalid-options = Atlas tidak dapat menggunakan pilihan penyiapan ini. Kembali ke Pilihan Anda dan tinjau kembali, lalu coba lagi. Detail: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Kondisi PC Anda berubah sejak pemeriksaan sebelumnya. Atasi hal berikut sebelum mencoba lagi. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Keamanan Windows: { $summary }.
preflight-busy = Jendela Atlas lain sedang memulai penginstalan. Tunggu sebentar, lalu pilih Instal Atlas lagi.
# Shown with the home-start-over button.
preflight-taken-over = Jendela Atlas lain kini menggunakan penyiapan ini, sehingga penginstalan belum dimulai. Lanjutkan di jendela tersebut, atau pilih Mulai dari awal untuk mengulang penyiapan di sini.
preflight-record-unreadable = Atlas tidak dapat memastikan apakah penginstalan sebelumnya masih berjalan, sehingga belum memulai penginstalan baru. Kembali ke Persiapan untuk melihat langkah selanjutnya. Detail: { $error }
preflight-refused = Penginstal tidak dapat dijalankan. Penginstalan belum mengubah apa pun. Pilih Instal Atlas untuk mencoba lagi. Jika ini terus terjadi, pilih Kirim laporan. Detail: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = Penginstal tidak dapat dijalankan, sehingga upaya ini berhenti. Upaya sebelumnya sudah mulai membuat perubahan. Pilih Instal Atlas untuk mencoba lagi. Jika ini terus terjadi, pilih Kirim laporan. Detail: { $error }
go-to-ready = Kembali ke Persiapan
go-to-options = Kembali ke Pilihan Anda
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Kembali ke Instal
output-problem-title = Kemajuan penginstalan tidak dapat dibaca
output-problem-message = Atlas tidak dapat membaca log. Ini tidak berarti penginstalan berhenti. Biarkan PC tetap menyala dan coba buka file log. Detail: { $error }
install-elevate-title = Atlas memerlukan izin untuk menginstal
install-no-package-title = Pilih file penginstalan terlebih dahulu
install-no-package-message = Kembali ke Persiapan untuk mengunduh Atlas atau membuka paket Atlas (.apbx) yang tersimpan.
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = Kembali ke Persiapan untuk menyiapkan paket Atlas bawaan versi uji ini.
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Selesaikan Persiapan terlebih dahulu
install-not-ready-message = Atlas perlu menyelesaikan pemeriksaan PC dan pembaruan Windows sebelum dapat menginstal.
install-security-title = Periksa perlindungan antivirus sebelum menginstal
install-security-reading = Memeriksa kembali keempat pengaturan perlindungan.
install-security-message = { $summary }. Buka Keamanan Windows dan pastikan keempat pengaturan sudah nonaktif sebelum menginstal.
summary-try-again = Tinjau sebelum mencoba lagi
summary-ready = Tinjau penyiapan Atlas Anda
summary-activation = Aktivasi
summary-activation-ok = Sudah diaktifkan. Atlas tidak akan mengubahnya.
summary-activation-missing = Belum diaktifkan. Anda dapat melanjutkan, tetapi Atlas tidak akan mengaktifkan Windows.
summary-activation-unknown = Atlas tidak akan mengubah status aktivasi Windows Anda.
summary-duration = Perkiraan waktu
# Indonesian has no plural forms; one wording covers every count.
summary-duration-value = { $minutes } menit, lalu mulai ulang
summary-restart-checkbox = Mulai ulang PC secara otomatis setelah penginstalan
summary-show-command = Tampilkan perintah penginstalan
summary-hide-command = Sembunyikan perintah penginstalan
summary-copy-command-a11y = Salin perintah penginstalan
summary-command-unavailable = Tidak dapat menyiapkan perintah penginstalan. Detail: { $error }
summary-not-chosen = Belum dipilih
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Ubah { $title }
footer-still-checking = Menyiapkan penginstalan
footer-fix-items = Atasi item di Pemeriksaan PC untuk melanjutkan
footer-need-package = Unduh Atlas atau buka paket Atlas untuk melanjutkan
# Tester build variant of footer-need-package.
footer-need-package-bundled = Siapkan paket Atlas bawaan untuk melanjutkan
footer-reading-security = Memeriksa pengaturan perlindungan
footer-security-pending = Nonaktifkan keempat pengaturan untuk melanjutkan
footer-security-confirm = Untuk melanjutkan, konfirmasikan pengaturan yang tidak dapat diperiksa Atlas
footer-install-ready = Simpan pekerjaan Anda dan tutup aplikasi terlebih dahulu
button-install = Instal Atlas
# Indonesian has no plural forms; one wording covers every count.
log-earlier-lines = { $count } baris sebelumnya ada di file log.
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (log lengkap: { $path })

## The installing view

installing-checking-title = Pemeriksaan terakhir
installing-checking-line = Atlas memeriksa PC Anda sebelum membuat perubahan. Ini mungkin perlu beberapa saat.
installing-title = Menginstal Atlas
installing-phase-preflight = Memeriksa PC dan menyiapkan file penginstalan.
installing-phase-staging = Menyiapkan file penginstalan. Biarkan PC tetap menyala.
installing-phase-applying = Menyiapkan Windows sesuai pilihan Anda. Biarkan PC tetap menyala dan terhubung ke sumber listrik.
installing-phase-done = Menyelesaikan penginstalan. Biarkan PC tetap menyala.
installing-installed-title = Atlas sudah terinstal
# $time is a formatted clock time.
installing-started-just-now = Dimulai pukul { $time }, kurang dari satu menit yang lalu
# Indonesian has no plural forms; one wording covers every count.
installing-started-minutes = Dimulai pukul { $time }, { $minutes } menit yang lalu
installing-restart-auto = PC Anda akan dimulai ulang secara otomatis setelah penginstalan selesai. Simpan pekerjaan Anda di aplikasi lain sebelum itu.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } sudah terinstal
installed-title = Atlas sudah terinstal
installed-ready = Semua sudah beres. PC Anda siap digunakan dengan Atlas.
installed-security-message = Anda mempertahankan Microsoft Defender, tetapi sebagian perlindungannya masih nonaktif. Buka Keamanan Windows dan pastikan pengaturan berikut aktif: { $switches }.
installed-defender-removed-title = Microsoft Defender telah dihapus
installed-defender-removed-message = PC Anda tidak akan memiliki perlindungan antivirus sampai Anda menginstal aplikasi antivirus lain. SmartScreen juga telah dihapus, jadi Windows tidak akan memperingatkan Anda sebelum Anda membuka aplikasi atau unduhan yang tidak dikenal.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Anda memilih untuk mempertahankan Microsoft Defender, tetapi Defender tidak ditemukan. Jika Anda tidak menggunakan aplikasi antivirus lain, instal aplikasi antivirus untuk melindungi PC Anda. Jika Anda tidak menghapus Defender sendiri, pilih Laporkan masalah.

## Settings

settings-title = Pengaturan
settings-theme = Tema aplikasi
settings-theme-system = Ikuti Windows
settings-theme-light = Terang
settings-theme-dark = Gelap
settings-theme-contrast-note = Atlas menggunakan warna dari tema kontras Windows Anda.
settings-theme-mica-note = Untuk menampilkan latar belakang tembus pandang, pilih tema terang atau gelap yang sama dengan Windows.
settings-language = Bahasa
settings-language-system = Ikuti Windows
settings-language-system-selected = { settings-language-system } ({ $language })
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Jika mengikuti Windows: { $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Pratinjau
# Under the language list, once, explaining the Preview tag.
settings-language-preview-note = Terjemahan pratinjau belum ditinjau oleh penutur asli.
preview-notice = { $language } adalah terjemahan pratinjau dan mungkin berisi kesalahan.
preview-notice-switch = Beralih ke bahasa Inggris
preview-notice-language = Ubah bahasa
# $tag is a language tag (text).
settings-language-unavailable = { $tag } tidak tersedia dalam versi Atlas ini. Bahasa Inggris ditampilkan untuk sementara, dan pilihan bahasa Anda tetap disimpan.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas belum mendukung bahasa tampilan Windows Anda ({ $languages }). Bahasa Inggris ditampilkan untuk sementara.
settings-language-windows-unavailable = Tidak dapat memeriksa bahasa tampilan Windows Anda. Atlas menggunakan bahasa Inggris untuk sementara. Detail: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = Angka, tanggal, dan waktu mengikuti format regional Windows Anda ({ $locale }).
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Angka mengikuti format regional Windows Anda ({ $locale }). Tanggal dan waktu menggunakan format standar karena Atlas belum dapat menampilkan teks dari kanan ke kiri.
settings-language-contribute = Bantu menerjemahkan Atlas di GitHub
settings-restart-label = Mulai ulang PC secara otomatis setelah penginstalan
settings-restart-locked = Pengaturan ini dapat diubah setelah penginstalan selesai.
settings-restart-description = Jika pengaturan ini aktif, PC Anda akan dimulai ulang dalam waktu satu menit setelah penginstalan selesai, sehingga aplikasi yang terbuka akan ditutup. Simpan pekerjaan Anda sebelum menginstal.
settings-help = Bantuan dan masukan
settings-about = Tentang
settings-about-app = Atlas Manager
settings-about-licence = Lisensi
settings-about-licence-value = GPL-3.0, gratis dan sumber terbuka
settings-view-source = Lihat kode sumber di GitHub
# Link that opens the third-party licence notices.
settings-view-licences = Lihat pemberitahuan lisensi
# Under the links when Windows could not open the notices.
settings-licences-failed = Tidak dapat membuka pemberitahuan lisensi. Coba lagi, atau cari pemberitahuan tersebut di kode sumber di GitHub.
settings-open-data-folder = Buka folder aplikasi

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Membebaskan ruang disk yang dipakai untuk menyimpan sesi Anda saat hibernasi. Hibernasi dan startup cepat (Fast Startup) tidak akan tersedia.
consequence-disable-power-saving = Menonaktifkan fitur penghematan daya. PC Anda mungkin memakai lebih banyak daya, menjadi lebih panas, dan daya tahan baterainya lebih pendek.
consequence-disable-core-isolation = Menonaktifkan lapisan keamanan tambahan Windows, termasuk integritas memori. Ini mengurangi perlindungan dan dapat memengaruhi aplikasi atau game yang memerlukannya.
consequence-remove-snipping-tool = Menghapus aplikasi Windows untuk mengambil tangkapan layar dan merekam layar.
consequence-uninstall-edge = Menghapus browser Microsoft Edge. Pastikan Anda memiliki browser lain, atau pilih salah satu di bawah.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Menghapus Microsoft Edge serta favorit, riwayat, dan kata sandi tersimpan Anda di Edge pada PC ini. Data yang tidak disinkronkan ke akun Microsoft Anda akan hilang. Pastikan Anda memiliki browser lain, atau pilih salah satu di bawah.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Menghapus favorit, riwayat, dan kata sandi tersimpan Anda di Edge pada PC ini.
consequence-install-another-browser = Pilih browser di bawah dan Atlas akan menginstalnya untuk Anda.
consequence-install-toolbox = Tambahkan Atlas Toolbox untuk membantu mengelola pengaturan Atlas Anda. Toolbox masih dalam tahap beta, sehingga beberapa fitur mungkin belum selesai.
consequence-install-eclean = Alat perawatan dari tim di balik AtlasOS untuk menjaga PC tetap rapi setelah penyiapan. Tinjau file sampah dan aplikasi startup. Memerlukan akun dan koneksi internet.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas menyesuaikan Windows untuk mengurangi aktivitas latar belakang dan gangguan. Instal Atlas pada instalasi Windows yang bersih, sebelum Anda menambahkan aplikasi dan file Anda sendiri.
## ISO creation (Beta)
iso-home-title = Media instalasi Windows
iso-home-description = Buat file instalasi Windows (ISO) yang menyertakan Atlas, lalu gunakan untuk menginstal ulang Windows di PC ini atau PC lain.
iso-open = Buat ISO Atlas
iso-title = Buat ISO Atlas
iso-beta = Beta
iso-beta-description = Uji ISO di mesin virtual sebelum menggunakannya di PC. Cadangkan file Anda sebelum menginstal Windows.
iso-admin-description = Atlas memerlukan izin administrator untuk membaca ISO Windows Anda dan membuat ISO baru. Pilih Jalankan ulang sebagai administrator, lalu pilih Ya saat Windows meminta izin.
iso-files-description = Atlas membuat salinan ISO Windows 11 yang sudah berisi Atlas, untuk menginstal ulang Windows. Pilih ISO Windows 11 yang diunduh dari Microsoft, unduh paket Atlas terbaru atau pilih paket yang sudah Anda miliki (.apbx), lalu pilih lokasi untuk menyimpan ISO baru.
# Tester build: no package picker.
iso-files-description-bundled = Atlas membuat salinan ISO Windows 11 yang sudah berisi paket Atlas bawaan versi uji ini. Pilih ISO Windows 11 yang diunduh dari Microsoft, lalu pilih lokasi untuk menyimpan ISO baru.
iso-source = ISO Windows
iso-source-download = Unduh Windows 11 dari Microsoft
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Paket Atlas ({ $minimum } atau lebih baru)
iso-output = Simpan ISO baru ke
iso-no-file = Belum ada file yang dipilih
iso-browse = Telusuri
iso-save-as = Simpan sebagai
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Periksa file
iso-mode-title = Bagaimana Anda ingin menyiapkan Atlas?
iso-mode-interactive = Tentukan pilihan Atlas setelah masuk
iso-mode-interactive-description = Setelah Anda masuk, Atlas terbuka dan memandu Anda melalui pembaruan, pilihan Anda, dan penginstalan Atlas.
iso-mode-before = Tentukan pilihan Atlas sekarang
iso-mode-before-description = Atlas menyimpan pilihan Anda dalam ISO. Setelah Anda masuk, Atlas terbuka dan memandu Anda melalui pembaruan, lalu Anda menginstal Atlas dengan pilihan tersebut.
iso-package-unsupported-title = Pilih paket Atlas yang lebih baru
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported = Paket Atlas ini tidak dapat menyimpan pilihan Atlas dalam ISO. Pilih paket yang lebih baru, atau pilih Tentukan pilihan Atlas setelah masuk.
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = Paket Atlas ini tidak dapat digunakan untuk membuat ISO. Pilih paket untuk Atlas { $minimum } atau yang lebih baru.
# Tester build: the bundled package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = Pilihan Atlas tidak dapat disimpan dalam ISO ini
# "Make Atlas choices after sign-in" is iso-mode-interactive.
iso-package-unsupported-bundled = Paket Atlas bawaan versi uji ini tidak mendukung penyiapan ISO. Sebagai gantinya, pilih Tentukan pilihan Atlas setelah masuk.
iso-atlas-options = Pilihan Atlas
iso-review = Tinjau ISO
iso-review-description = Membuat ISO tidak menginstal apa pun di PC ini dan tidak mengubah ISO asli Anda. Setelah itu, Atlas dapat menyalin ISO baru ke drive USB agar Anda dapat menginstal ulang Windows dari drive tersebut.
iso-review-files = File
iso-step-windows = Penyiapan Windows
iso-step-review = Tinjau
iso-review-package = Paket Atlas
iso-review-output = ISO baru
iso-review-editions = Edisi
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Nama akun
iso-review-target = Instal di
iso-review-drivers = Driver
iso-create = Buat ISO
iso-progress-title = Membuat ISO Anda
iso-stage-inspect = Memeriksa ISO Windows Anda
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
iso-progress-description = Biarkan Atlas tetap terbuka. Citra berukuran besar mungkin memerlukan waktu untuk diproses.
iso-cancel = Batalkan pembuatan
iso-cancelling = Menunggu titik aman untuk membatalkan
iso-cancelled = Pembuatan ISO dibatalkan
iso-cancelled-description = ISO asli Anda tidak berubah. Jika ada file sementara yang tertinggal, pilih Buka folder log untuk melihat lokasinya.
iso-complete = ISO Anda siap
iso-complete-description = Pembuatan ISO masih dalam tahap beta, jadi uji ISO di mesin virtual terlebih dahulu. Setelah itu, pilih Buat USB instalasi, dan cadangkan file Anda sebelum menginstal ulang Windows.
iso-open-folder = Tampilkan di folder
iso-failed = Pembuatan ISO tidak dapat diselesaikan
iso-failed-description = Pastikan file Anda masih berada di lokasi yang Anda pilih dan drive tujuan masih terhubung, lalu pilih Buat ISO. Jika terus gagal, pilih Kirim laporan.
# Title while the Check files step fails; the messages below say why.
iso-check-failed = Tidak dapat memeriksa file
iso-check-failed-description = Pastikan ISO dan paket Atlas masih berada di lokasi yang Anda pilih dan sudah selesai diunduh, lalu pilih Periksa file. Jika terus gagal, pilih Kirim laporan.
# Title when Windows refused the administrator relaunch (UAC declined); elevation-declined is the message.
iso-elevation-title = Atlas memerlukan izin untuk membuat ISO
# Typed reasons reported by the image worker.
iso-failed-output-exists = File dengan nama tersebut sudah ada. Pilih Simpan sebagai dan masukkan nama file baru.
iso-failed-destination = Atlas tidak dapat menyimpan ISO baru di sana. Pilih Simpan sebagai, lalu pilih folder di PC ini, seperti Unduhan. Lokasi jaringan dan drive berformat FAT32 atau exFAT, seperti banyak drive USB, tidak dapat digunakan.
iso-failed-space = Ruang kosong di drive tujuan tidak cukup. Kosongkan ruang, atau simpan ISO baru ke drive lain.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = ISO ini tidak berisi edisi Windows yang didukung. Windows Home dan LTSC tidak didukung. Gunakan ISO yang menyertakan edisi lain, seperti Pro, Education, atau Enterprise.
iso-failed-customised = ISO ini sudah berisi file penyiapan kustom, seperti autounattend.xml. Pilih ISO Windows dari Microsoft yang belum dimodifikasi.
iso-failed-windows-unsupported = Citra Windows ini tidak didukung oleh paket Atlas. Gunakan ISO Windows 11 64-bit yang belum dimodifikasi untuk versi yang didukung paket ini.
iso-failed-network-architecture = Driver jaringan PC ini tidak cocok dengan arsitektur ISO ini. Kembali dan nonaktifkan Sertakan driver jaringan PC ini, atau pilih ISO untuk PC ini.
iso-failed-unstaged = Atlas tidak dapat menyiapkan folder kerjanya, sehingga tidak ada yang diubah. Coba lagi. Jika masih gagal, pilih Ekspor diagnostik untuk laporan bug.
iso-failed-package-changed = Paket Atlas berubah setelah file diperiksa. Pilih Ubah di samping File, lalu pilih Periksa file.
iso-diagnostics = Buka folder log
iso-close-title = Pembuatan ISO masih berlangsung
iso-close-message = Biarkan jendela ini terbuka hingga pembuatan atau pembatalan selesai. Pembatalan menunggu hingga operasi saat ini dapat dihentikan dengan aman.
iso-keep-open = Biarkan terbuka
prepare-title = Perbarui Windows dan aplikasi Store
prepare-description = Sebelum menginstal, Atlas memperbarui Windows, Microsoft Store, dan aplikasi Store Anda. Aplikasi Store yang sedang terbuka, seperti Notepad, Paint, atau Windows Terminal, mungkin ditutup saat diperbarui, jadi simpan pekerjaan Anda di aplikasi tersebut terlebih dahulu. PC Anda mungkin juga perlu dimulai ulang.
prepare-complete = Atlas tidak menemukan pembaruan Windows atau Store lain yang perlu diinstal.
prepare-reboot-title = Mulai ulang PC Anda untuk melanjutkan
prepare-reboot = PC Anda perlu dimulai ulang untuk menyelesaikan penginstalan pembaruan. Atlas menyimpan pilihan Anda sejauh ini dan akan terbuka kembali setelah Anda masuk.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = PC Anda perlu dimulai ulang untuk menyelesaikan penginstalan pembaruan ({ $reasons }). Atlas menyimpan pilihan Anda sejauh ini dan akan terbuka kembali setelah Anda masuk.
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = Simpan pekerjaan Anda dan tutup aplikasi terlebih dahulu. PC Anda langsung dimulai ulang begitu Anda memilih Mulai ulang dan lanjutkan.
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = PC Anda sudah dimulai ulang, tetapi Windows masih meminta mulai ulang ({ $reasons }), jadi memulai ulang lagi kemungkinan tidak akan membantu. Pilih Buka Windows Update dan selesaikan apa pun yang menunggu di sana, lalu pilih Coba lagi. Jika tidak ada yang menunggu, pilih Kirim laporan.
# Names of the markers Windows sets when it wants a restart. They complete
# "Windows needs to restart (…)"; keep them short and lower case where the language allows.
prepare-reason-servicing = pemeliharaan komponen Windows
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = file yang menunggu diganti
prepare-reason-update-agent = layanan Windows Update
prepare-reason-unknown = alasan tidak dilaporkan
prepare-failed = Pilih Coba lagi. Jika gagal lagi, selesaikan pembaruan yang tersisa di Windows Update atau Microsoft Store, atau pilih Kirim laporan.
prepare-failed-title = Beberapa pembaruan tidak dapat diselesaikan
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Try again" is common-try-again, the button beside it.
prepare-ended-unconfirmed = Proses pembaruan berhenti sebelum melaporkan hasilnya, sehingga Atlas tidak dapat memastikan bahwa Windows dan aplikasi Store sudah diperbarui. Pilih Coba lagi untuk memeriksa pembaruan.
prepare-unconfirmed-title = Tidak dapat memastikan hasil pembaruan
# "Check and install updates" is prepare-start, its button in this state.
prepare-cancelled = Pembaruan dihentikan. Beberapa pembaruan mungkin sudah terinstal. Pilih Periksa dan instal pembaruan untuk menyelesaikannya sebelum melanjutkan.
prepare-windows-search = Memeriksa pembaruan Windows…
prepare-windows-download = Mengunduh pembaruan Windows…
prepare-windows-install = Menginstal pembaruan Windows…
prepare-store-search = Memeriksa Microsoft Store…
prepare-store-install = Memperbarui Microsoft Store dan aplikasinya…
prepare-stop-description = Atlas akan berhenti setelah langkah saat ini selesai. Biarkan Atlas tetap terbuka sampai saat itu.
prepare-stop = Hentikan pembaruan
prepare-restart = Mulai ulang dan lanjutkan
prepare-start = Periksa dan instal pembaruan
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = Tidak tersedia karena penginstalan ini tidak dapat dilanjutkan. Lihat pesan di bagian atas halaman.
prepare-needs-build-check = Tersedia setelah { $check } berhasil di Pemeriksaan PC.
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = Tersedia setelah file penginstalan siap.
iso-username = Nama akun lokal
iso-account-description = Penyiapan Windows membuat akun lokal dengan nama ini, jadi Anda tidak memerlukan akun Microsoft. Windows akan meminta Anda membuat kata sandi saat pertama kali masuk.
iso-username-placeholder = Nama Anda
iso-account-empty = Masukkan nama akun lokal untuk melanjutkan
iso-account-invalid = Gunakan maksimal 20 karakter, tanpa spasi di awal atau akhir dan tanpa karakter berikut: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Nama tidak boleh diakhiri dengan titik.
iso-account-reserved = Windows menggunakan nama ini untuk akun bawaan. Pilih nama lain.
iso-privacy-defaults = ISO ini melewati layar lisensi, akun Microsoft, dan privasi dalam penyiapan Windows, serta menonaktifkan berbagi data opsional dan penawaran yang dipersonalisasi.
prepare-drivers = Bagaimana driver akan diinstal?
prepare-drivers-auto = Dapatkan driver melalui Windows Update
prepare-drivers-auto-detail = Windows mencari driver untuk perangkat keras Anda. Disarankan untuk sebagian besar PC.
prepare-drivers-manual = Saya akan menginstal driver sendiri
prepare-drivers-manual-detail = Windows Update tidak akan menginstal driver, jadi Anda perlu mendapatkannya dari produsen PC atau perangkat Anda. Driver yang sudah terinstal tetap dipertahankan.
prepare-drivers-description = Driver memungkinkan Windows menggunakan perangkat keras Anda, seperti grafis, suara, dan Wi-Fi. Jika Anda mengubah pilihan ini setelah memperbarui, Atlas perlu memeriksa pembaruan lagi.
prepare-network-needed = Pembaruan memerlukan koneksi internet yang tidak terukur. Hubungkan ke Wi-Fi atau Ethernet, lalu pilih Coba lagi. Jika tidak ada jaringan Wi-Fi yang muncul, instal driver jaringan Anda terlebih dahulu.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows melaporkan bahwa jaringan ini tidak memiliki akses internet. Masuk ke jaringan jika diminta, atau periksa router serta pemfilteran DNS atau firewall, lalu coba lagi.
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = Koneksi ini terukur atau memiliki batas data. Hubungkan ke jaringan yang tidak terukur, atau nonaktifkan Koneksi terukur di pengaturan jaringan, lalu coba lagi.
prepare-network-settings = Buka pengaturan jaringan
iso-target-title = Di PC mana Anda akan menginstal ulang Windows?
iso-target-this = PC ini
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas dapat menambahkan driver Wi-Fi dan Ethernet PC ini ke ISO, sehingga Windows dapat langsung terhubung ke internet setelah diinstal ulang.
iso-target-other = PC lain
iso-copy-network = Sertakan driver jaringan PC ini
iso-network-detail = Gunakan kembali driver Wi-Fi dan Ethernet PC ini saat menginstal Windows. Anda perlu menghubungkan ulang Wi-Fi setelah instalasi.
iso-network-source = Sumber driver jaringan
iso-network-installed = Gunakan driver yang terinstal
iso-network-updated = Periksa Windows Update terlebih dahulu
iso-network-updated-detail = Unduh driver yang sesuai dari Windows Update dan simpan driver terinstal sebagai cadangan. Memerlukan koneksi yang tidak terukur.
iso-stage-network-drivers = Menyiapkan driver jaringan
iso-network-failed = Driver jaringan tidak dapat disiapkan. Periksa diagnostik atau kembali dan ubah opsi driver jaringan.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Adaptor jaringan PC ini menggunakan driver bawaan Windows, sehingga ISO tidak perlu menyertakannya.
iso-mode-desktop = Selesaikan penyiapan sebelum membuka desktop
iso-mode-desktop-description = Atlas menyimpan pilihan Anda dalam ISO. Setelah Anda masuk, Atlas menyelesaikan pembaruan dan penginstalan sebelum desktop Windows terbuka.
desktop-setup-description = Selesaikan penyiapan PC Anda. Pilihan Atlas tersimpan; Anda dapat kembali ke Windows jika perlu.
desktop-setup-exit = Lanjutkan di Windows

# Windows installation USB (Beta)
usb-title = Buat USB instalasi
usb-existing = Buat USB dari ISO yang sudah ada
usb-description = Salin ISO ke drive USB agar Anda dapat menginstal ulang Windows dari drive tersebut. Gunakan ISO yang dibuat oleh Atlas untuk sekaligus menginstal Atlas.
usb-choose-iso = Pilih ISO
usb-drive = Drive USB
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = Tidak ada drive USB yang ditemukan. Hubungkan drive USB berukuran minimal { $min } GB, lalu pilih Muat ulang. Drive yang lebih besar dari { $max } TB, drive hanya-baca, dan drive tempat Windows berjalan tidak ditampilkan.
usb-refresh = Muat ulang
# Shown when the drive list could not be read.
usb-scan-failed = Pastikan drive terhubung, lalu pilih Muat ulang. Untuk melihat detailnya, pilih Buka folder log.
usb-scan-failed-title = Tidak dapat membaca daftar drive USB
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = Nomor seri: { $serial }
usb-detail-separator = { " · " }
usb-review = Tinjau USB
usb-erase-title = Hapus isi drive USB ini?
usb-erase-description = Seluruh isi { $drive } ({ $size } GB) akan dihapus secara permanen, termasuk semua file dan partisi. Salin semua yang ingin Anda simpan ke drive lain terlebih dahulu. ISO Anda akan tetap disimpan.
usb-layout = Atlas menggunakan hingga 32 GB dari drive ini dan membiarkan sisanya tidak terpakai. Drive USB ini berfungsi di PC yang melakukan boot dalam mode UEFI, yang diwajibkan oleh Windows 11.
usb-ack = Saya memahami bahwa seluruh isi drive USB ini akan dihapus
usb-write = Hapus dan buat USB
usb-stage-prepare = Menyiapkan file instalasi…
usb-stage-format = Memformat USB…
usb-stage-copy = Menyalin file instalasi…
usb-stage-verify = Memverifikasi USB…
usb-working = Biarkan Atlas tetap terbuka dan drive USB tetap terhubung. Jika Anda membatalkan, drive USB yang belum selesai tidak dapat digunakan untuk menginstal Windows.
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = Pembuatan USB tidak dapat diselesaikan
usb-complete-title = USB Anda siap
usb-close-title = Pembuatan USB masih berlangsung
# After erasing may have begun.
usb-failed = Isi drive mungkin sudah dihapus, sehingga drive belum dapat digunakan untuk menginstal Windows. Pastikan drive terhubung, lalu pilih Tinjau USB untuk mencoba lagi. Jika Anda menghubungkannya kembali, terlebih dahulu pilih Muat ulang dan pilih drive tersebut lagi.
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = Drive USB Anda tidak diubah. Pilih Buka folder log untuk melihat penyebabnya, lalu pilih Tinjau USB untuk mencoba lagi.
usb-failed-iso = ISO ini tidak dapat digunakan untuk membuat USB instalasi. Pilih ISO yang dibuat oleh Atlas, atau ISO Windows 11 dari Microsoft untuk versi yang didukung Atlas. Drive USB Anda tidak diubah.
usb-failed-location = ISO atau Atlas Manager berada di drive USB ini, lokasi jaringan, atau folder tertaut. Pindahkan ke folder lokal di PC ini, lalu coba lagi. Drive USB Anda tidak diubah.
usb-failed-space = Ruang kosong di drive Windows tidak cukup untuk menyiapkan file instalasi. Kosongkan ruang, lalu coba lagi. Drive USB Anda tidak diubah.
usb-failed-fit = File instalasi tidak muat di drive USB ini. Gunakan drive yang lebih besar, lalu coba lagi. Drive USB Anda tidak diubah.
usb-failed-drive-changed = Drive USB dilepas, dihubungkan kembali, atau diganti setelah daftar dibaca. Pilih Muat ulang, pilih drive tersebut lagi, lalu pilih Tinjau USB. Drive USB Anda tidak diubah.
usb-cancelled = Drive mungkin berisi file instalasi yang belum lengkap. Buat ulang sebelum menggunakannya untuk menginstal Windows.
usb-cancelled-title = Pembuatan USB dibatalkan
usb-cancelled-unchanged = Drive USB Anda tidak diubah.
usb-complete = Atlas sudah memeriksa setiap file. Pilih Keluarkan USB, lalu cadangkan file di PC yang ingin Anda instal ulang. Hubungkan drive ke PC tersebut, lalu lakukan boot dari drive USB melalui menu boot PC (biasanya F12, F11, atau Esc saat PC dinyalakan).
usb-eject = Keluarkan USB
usb-ejected = Drive USB sekarang dapat dicabut. Cadangkan file di PC yang ingin Anda instal ulang. Setelah itu, lakukan boot PC tersebut dari drive USB melalui menu boot-nya (biasanya F12, F11, atau Esc saat PC dinyalakan).
usb-eject-failed = Tutup file atau jendela yang menggunakan USB ini, lalu coba lagi.
usb-eject-failed-title = Tidak dapat mengeluarkan USB
ready-fresh-title = Atlas dibuat untuk instalasi Windows yang bersih
ready-fresh-description = Jika Anda sudah menggunakan Windows di PC ini, cadangkan file Anda dan instal ulang Windows sebelum melanjutkan. Pastikan Kompatibilitas Windows berhasil di Pemeriksaan PC terlebih dahulu, agar Anda menginstal ulang versi yang didukung.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Edisi Windows 11 Home, LTSC, dan Server tidak didukung. Gunakan edisi lain, seperti Pro, Education, atau Enterprise. Jika Windows tidak dapat mengenali edisi Anda, selesaikan masalah tersebut sebelum melanjutkan.
install-source-title = Penginstalan tidak tersedia
install-source-unsupported = Atlas { $source } tidak dapat diperbarui langsung ke { $target }. Untuk menggunakan versi ini, cadangkan file Anda dan instal ulang Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } tidak dapat diperbarui langsung. Untuk menggunakan versi yang lebih baru, cadangkan file Anda dan instal ulang Windows.
# "Open package file" is package-open-file. $folder is a folder path (text).
install-source-resume = Penginstalan Atlas { $target } tidak selesai, dan hanya paket Atlas { $target } yang dapat menyelesaikannya. Pilih Buka file paket, lalu pilih paket Atlas tersebut (.apbx). Jika Atlas mengunduhnya, paket tersebut ada di { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Penginstalan Atlas { $target } tidak selesai. Versi uji ini hanya dapat menginstal paket Atlas bawaannya, jadi selesaikan penginstalan tersebut dengan paket Atlas { $target } di versi rilis Atlas Manager.
install-source-unknown = Atlas tidak dapat memastikan apa yang sudah terinstal di PC ini, jadi Atlas tidak akan menginstal apa pun untuk saat ini. Pilih Kirim laporan agar tim Atlas dapat membantu.
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } Detail: { $error }
iso-edition-selection = Hanya edisi yang didukung yang disertakan. Saat menginstal Windows, pilih edisi yang sesuai dengan lisensi Windows Anda.
detail-windows-preview = Build Insider tidak didukung. Gunakan rilis publik Windows 11.
detail-windows-release-unknown = Atlas tidak dapat memastikan bahwa build Windows ini merupakan rilis publik. Hubungkan ke internet, lalu periksa lagi.
iso-release-unknown = Atlas tidak dapat memastikan bahwa ISO ini adalah rilis publik Windows 11 yang didukung oleh paket Atlas. Hubungkan ke internet, lalu pilih Periksa file lagi. Jika masih gagal, unduh ulang ISO dari Microsoft.
prepare-previous-worker = Pembaruan yang dimulai sebelumnya masih berjalan. Atlas akan menunggu hingga selesai, lalu Anda dapat memeriksa pembaruan lagi.

ready-used-windows-title = Windows di PC ini tampaknya sudah pernah digunakan
ready-used-windows-description = Windows di PC ini diinstal setidaknya seminggu yang lalu atau sudah memiliki beberapa aplikasi. Menginstal Atlas di sini tidak didukung dan sangat tidak disarankan: aplikasi dan pengaturan yang sudah Anda miliki mungkin tidak berfungsi seperti yang diharapkan, dan Atlas menghapus OneDrive, sehingga file di dalamnya berhenti disinkronkan dan folder Desktop, Dokumen, dan Gambar Anda mungkin tampak kosong. Cadangkan file Anda dan instal ulang Windows terlebih dahulu, atau lanjutkan hanya jika Anda menerima risikonya.
ready-used-windows-dismiss = Tetap lanjutkan

prepare-resumed = PC Anda telah dimulai ulang, dan Atlas telah memulihkan pilihan Anda sejauh ini. Pilih Lanjutkan pembaruan untuk menyelesaikan pembaruan sebelum Anda menginstal Atlas.
prepare-continue = Lanjutkan pembaruan
prepare-saving-restart = Menyimpan pilihan Anda dan mengatur Atlas agar terbuka kembali setelah Windows dimulai ulang…
prepare-restart-save-failed = Pilihan Anda tidak dapat disimpan. Coba lagi sebelum memulai ulang.
prepare-restart-registration-failed = Pilihan Anda tersimpan, tetapi Atlas tidak dapat mengatur agar terbuka kembali setelah PC dimulai ulang. Coba lagi, atau mulai ulang PC Anda sendiri dan buka Atlas setelah Anda masuk.
prepare-restart-failed = Atlas tidak dapat memulai ulang PC Anda. Coba lagi, atau mulai ulang PC melalui menu Mulai. Pilihan Anda tersimpan, dan Atlas akan terbuka kembali setelah Anda masuk.
diagnostics-export = Ekspor diagnostik
diagnostics-exporting = Mengumpulkan diagnostik…
diagnostics-privacy = Kirim laporan secara pribadi ke tim Atlas, atau ekspor ZIP diagnostik untuk dibagikan saat Anda meminta bantuan. Atlas menghapus nama pengguna, nama PC, dan alamat email Anda dari ZIP tersebut.
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = ZIP diagnostik dibuat
diagnostics-failed-title = Tidak dapat mengekspor diagnostik
# $error is the raw error (text).
diagnostics-failed = Pastikan PC Anda memiliki ruang disk kosong, lalu coba lagi. Detail: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Versi uji Atlas { $release }. Aplikasi ini hanya menginstal paket Atlas bawaan.
home-status-bundled = Versi uji { $release }
package-bundled = Atlas { $version } bawaan versi uji ini siap diinstal.
rc-about-release = Versi uji
rc-about-commit = Commit sumber
rc-about-package = Paket Atlas bawaan (SHA-256)
iso-package-bundled = Paket Atlas bawaan versi uji ini
prepare-percent = { $percent }% dari tahap ini
prepare-count = Pembaruan selesai: { $completed } dari { $total }
prepare-bytes = Terunduh { $downloaded } dari sekitar { $total } MB
prepare-elapsed = Waktu berlalu: { $minutes } mnt { $seconds } dtk
prepare-progress-waiting = Menunggu layanan pembaruan. Persentase tidak tersedia untuk langkah ini.
prepare-progress-unchanged = Tidak ada kemajuan selama { $minutes } mnt. Pembaruan besar dapat memerlukan waktu, jadi biarkan Atlas tetap terbuka. Untuk melihat detailnya, pilih Buka folder log.
prepare-report-delayed = Windows belum melaporkan kemajuan selama { $seconds } dtk. Pembaruan mungkin masih berjalan, jadi biarkan Atlas tetap terbuka.

prepare-affected-app = aplikasi terkait
prepare-app-in-use = Tutup { $app }, lalu coba lagi. Windows tidak dapat memperbaruinya saat aplikasi tersebut terbuka. Jika Anda tidak dapat menemukan jendelanya, tutup aplikasi melalui Pengelola Tugas. Jika masih gagal, mulai ulang PC Anda dan coba lagi sebelum membuka { $app }.
prepare-install-busy = Penginstalan lain atau mulai ulang yang diperlukan menghalangi pembaruan. Tunggu hingga penginstalan lain selesai, mulai ulang PC Anda jika Windows memintanya, lalu coba lagi.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas berjalan dengan akun yang berbeda dari akun yang masuk ke Windows. Masuk ke Windows dengan akun administrator, buka Atlas dari akun tersebut, lalu coba lagi.
prepare-failed-store-missing = Microsoft Store belum disiapkan untuk akun Anda. Buka Microsoft Store sekali, atau instal ulang jika tidak ada, lalu coba lagi.
prepare-failed-store-battery = Microsoft Store menjeda pembaruan untuk menghemat baterai. Hubungkan PC Anda ke sumber listrik, lalu coba lagi.
prepare-failed-store-network = Microsoft Store menjeda pembaruan hingga PC Anda memiliki koneksi yang tidak terukur. Hubungkan ke Wi-Fi atau Ethernet yang tidak terukur, lalu coba lagi.
prepare-failed-store-timeout = Aplikasi Store belum selesai diperbarui. Selesaikan unduhan yang tersisa di Microsoft Store, lalu coba lagi.
prepare-failed-store-passes = Microsoft Store terus menawarkan pembaruan baru. Selesaikan pembaruan yang tersisa di Microsoft Store, lalu coba lagi.
prepare-failed-manual-updates = Beberapa pembaruan Windows perlu diselesaikan di Windows Update. Buka Windows Update, selesaikan pembaruan tersebut, lalu coba lagi.
prepare-failed-windows-passes = Windows Update terus menawarkan pembaruan baru. Selesaikan pembaruan yang tersisa di Windows Update, lalu coba lagi.
prepare-error-code = Kode kesalahan: { $code }
prepare-open-store = Buka Microsoft Store

check-user-account = Akun pengguna
detail-user-account-ok = UAC aktif dan akun Anda siap untuk penginstalan.
detail-user-account-not-ready = Aktifkan Kontrol Akun Pengguna (UAC), mulai ulang PC, lalu coba lagi. Jika Anda menggunakan akun Administrator bawaan, masuk dengan akun administrator lain.
detail-user-account-unknown = Atlas tidak dapat memeriksa akun pengguna Anda. Periksa lagi sebelum menginstal. Windows melaporkan: { $error }

footer-prepare-required = Selesaikan pembaruan Windows dan aplikasi Store untuk melanjutkan
footer-prepare-stopping = Menghentikan pembaruan setelah langkah saat ini…
resume-choices-title = Melanjutkan penginstalan sebelumnya
resume-choices-detail = Untuk menyelesaikan penginstalan tersebut, Atlas memulihkan pilihan yang Anda buat sebelumnya. Anda tidak dapat mengubahnya di Pilihan Anda sampai penginstalan selesai.

## Voluntary reports
report-title = Kirim laporan
report-received = Laporan diterima
report-reference = Simpan referensi ini jika Anda menghubungi tim Atlas tentang laporan ini. Jika Anda mencantumkan detail kontak, tim mungkin menggunakannya untuk membalas, tetapi balasan tidak dijamin.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Salin referensi laporan
report-another = Kirim laporan lain
# Label of the choice between the two kinds of report.
report-kind = Apa yang ingin Anda kirim?
report-kind-issue = Masalah
report-kind-suggestion = Saran
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = Jelaskan apa yang terjadi atau apa yang ingin Anda ubah ({ $min }–{ $max } karakter). Jangan sertakan kata sandi dalam pesan Anda.
report-message = Pesan Anda
report-message-placeholder = Saya sedang mencoba…
report-contact = Kontak (opsional)
report-contact-placeholder = Email atau nama pengguna Discord
report-attach = Sertakan diagnostik
report-attach-description = Log dan detail sistem yang membantu menemukan penyebab masalah. Atlas menghapus nama pengguna, nama PC, dan alamat email Anda, serta kata sandi atau kunci yang dikenali. Detail kesalahan, model perangkat keras, dan nama aplikasi tetap disertakan. Anda dapat meninjau ZIP sebelum mengirim.
report-prepare = Siapkan diagnostik
report-review = Tinjau ZIP
report-prepare-failed-title = Tidak dapat menyiapkan diagnostik
# $error is a raw error message (text).
report-prepare-failed = Siapkan diagnostik lagi, atau nonaktifkan Sertakan diagnostik untuk mengirim laporan tanpa diagnostik. Detail: { $error }
report-privacy = Laporan Anda dikirim secara pribadi ke tim Atlas di reports.atlasos.net. Pesan dan detail kontak Anda dikirim persis seperti yang Anda tulis. Tim mungkin menggunakan layanan AI dari perusahaan lain untuk membantu penyelidikan. Layanan tersebut menerima pesan dan diagnostik Anda, tetapi tidak menerima detail kontak Anda. Laporan dihapus setelah 90 hari, dan log keamanan server mungkin mencatat alamat IP Anda.
report-website = Privasi dan situs laporan
report-consent = Saya setuju mengirim laporan ini dan diagnostik yang disertakan ke tim Atlas
report-failed = Pesan Anda masih tersimpan. Periksa koneksi internet Anda, lalu pilih Coba lagi, atau kirim laporan Anda dari situs laporan.
report-failed-busy = Layanan laporan sedang sibuk. Pesan Anda masih tersimpan. Coba lagi nanti.
report-failed-outdated = Versi Atlas Manager ini tidak dapat lagi mengirim laporan. Pesan Anda masih tersimpan: salin pesan tersebut ke situs laporan. Jika Anda menyertakan diagnostik, pilih Tinjau ZIP dan lampirkan ZIP tersebut di sana juga.
report-failed-diagnostics = Diagnostik yang disiapkan tidak dapat dikirim. Pesan Anda masih tersimpan. Siapkan diagnostik lagi, atau nonaktifkan Sertakan diagnostik.
# Link under a report that wasn't sent.
report-failed-website = Buka situs laporan
report-sending = Mengirim…
report-send = Kirim laporan

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = Masukkan { $min }–{ $max } karakter.

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = Batasi detail kontak hingga { $max } karakter.

report-validation-consent = Konfirmasikan persetujuan untuk mengirim laporan ini.

report-failed-title = Laporan belum terkirim
