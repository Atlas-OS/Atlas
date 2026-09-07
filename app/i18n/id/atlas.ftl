### Atlas Manager: Bahasa Indonesia (id). Preview translation, revised on 6 September 2026 from the en-GB source; native-speaker review pending.
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
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "GitHub"
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
# Accessible description of a disabled control.
common-not-available = Saat ini tidak tersedia
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

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Tutup jendela saat Atlas sedang diinstal?
window-close-message = Penginstalan akan berlanjut di latar belakang. Buka Atlas lagi untuk melihat kemajuan dan hasilnya. Biarkan PC tetap menyala hingga penginstalan selesai.
window-close-keep = Biarkan terbuka
window-close-close = Tutup jendela
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Buka playbook Atlas (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas sudah terinstal. Windows dimulai ulang untuk menyelesaikan penyiapan.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (build { $build })

## Home page

home-not-installed = Selamat datang di Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Diinstal pada { $date }
home-status-checking = Memeriksa pembaruan
home-status-offline = Tidak dapat memeriksa pembaruan
home-status-not-checked = Pembaruan belum diperiksa
home-status-update = Atlas { $version } tersedia
home-status-up-to-date = Sudah versi terbaru
home-status-newest = Versi terbaru: Atlas { $version }
home-check-again = Periksa lagi
# Primary button while an install is running or waiting.
home-show-install = Lihat kemajuan
home-continue-installing = Lanjutkan penyiapan
home-update-to = Perbarui ke Atlas { $version }
home-reinstall = Instal ulang Atlas
home-install = Instal Atlas
home-start-over = Mulai dari awal
home-security-reminder-title = Aktifkan kembali perlindungan Anda
home-security-reminder-message = Tidak ada penginstalan yang berjalan. Buka Keamanan Windows, lalu aktifkan kembali Proteksi Kerusakan, Perlindungan real-time, Perlindungan yang dikirimkan cloud, dan Pengiriman sampel otomatis.
home-elevation-title = Atlas memerlukan izin untuk menginstal
home-state-error-title = Tidak dapat membaca detail penginstalan Atlas Anda
home-whats-new = Yang baru di Atlas { $version }
home-view-release = Lihat catatan rilis di GitHub
home-released = Dirilis pada { $date }
home-show-less = Tampilkan lebih sedikit
home-show-full-notes = Tampilkan semua catatan rilis
home-your-install = Penyiapan Atlas Anda
# Row label: how Atlas was set up.
home-set-up = Metode penyiapan
home-set-up-during-oobe = Saat penyiapan Windows
home-history = Riwayat penginstalan
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Mari siapkan PC Anda untuk Atlas
home-step-1-title = Periksa PC Anda
home-step-1-detail = Atlas memeriksa Windows dan mengunduh file penginstalan. Pengaturan Windows Anda tetap seperti semula.
home-step-2-title = Tentukan pilihan Anda
home-step-2-detail = Pilih cara Windows menangani perlindungan dan pembaruan, lalu pilih aplikasi atau pengaturan tambahan yang Anda inginkan.
home-step-3-title = Jeda perlindungan antivirus
home-step-3-detail = Atlas memandu Anda menonaktifkan sementara empat pengaturan Keamanan Windows agar tidak menghalangi penginstalan.
home-step-4-title = Instal dan mulai ulang
# Indonesian has no plural forms; one wording covers every count.
home-step-4-detail = Sekitar { $minutes } menit.
# Accessible name of a numbered step.
home-step-a11y = Langkah { $number }: { $title }
home-github = Lihat Atlas di GitHub
home-discord = Bergabung dengan komunitas Atlas di Discord
home-report-problem = Laporkan masalah di GitHub

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
notice-session-unreadable-title = Tidak dapat memeriksa penginstalan sebelumnya
# $path is a file path (text).
notice-session-unreadable-message = Atlas tidak dapat membaca { $path }, padahal file ini diperlukan untuk mengetahui apakah penginstalan masih berjalan. Jika Anda tidak yakin, minta bantuan komunitas Atlas sebelum menghapus file ini. Hapus file ini dan coba lagi hanya jika Anda sudah memastikan tidak ada penginstalan yang berjalan. Detail: { $error }

## Administrator elevation

elevation-declined = Izin tidak diberikan. Coba lagi, lalu pilih Ya saat Windows menanyakan apakah Atlas boleh membuat perubahan.
elevation-declined-continue = Izin tidak diberikan. Coba lagi, lalu pilih Ya saat Windows menanyakan apakah Atlas boleh membuat perubahan. Pilihan penyiapan Anda sudah disimpan.
elevation-draft-not-saved = Atlas tidak dapat menyimpan pilihan penyiapan Anda, sehingga aplikasi belum dijalankan ulang. Coba lagi. Detail: { $error }

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
# Heading above each step's content.
step-heading = Langkah { $number } dari { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = Menyiapkan PC Anda
ready-banner-busy-message = Atlas sedang memeriksa PC Anda dan menyiapkan file instalasi.
ready-banner-blocked-title = PC Anda masih perlu disiapkan
ready-banner-blocked-message = Ikuti petunjuk di bawah, lalu pilih Periksa lagi.
ready-banner-no-package-title = Unduh Atlas untuk melanjutkan
ready-banner-no-package-message = Unduh versi terbaru di bawah, atau buka playbook Atlas (.apbx) yang tersimpan.
ready-banner-warnings-title = Ada beberapa hal yang perlu diperhatikan
ready-banner-warnings-message = Baca catatan di bawah dan lakukan langkah yang disarankan sebelum melanjutkan.
ready-banner-ok-title = Anda siap menentukan pilihan
ready-banner-ok-message = Semua pemeriksaan berhasil dan file penginstalan sudah siap.
# Card title and accessible name of the list of checks.
ready-this-pc = Pemeriksaan PC
ready-check-again = Periksa lagi
package-title = File penginstalan
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Mengunduh Atlas { $version } · { $received } dari { $total } MB
# Indonesian has no plural forms; one wording covers every count.
package-unpacking-progress = Mengekstrak · { $done } dari { $total } file
package-unpacking = Mengekstrak
package-looking = Memeriksa versi Atlas terbaru.
package-none = Belum ada file penginstalan. Playbook (.apbx) berisi petunjuk dan file yang diperlukan Atlas.
# Short status words beside the card title.
package-status-downloading = Mengunduh
package-status-unpacking = Mengekstrak
package-status-failed = File tidak dapat disiapkan
package-status-ready = Siap
package-status-checking = Memeriksa
package-status-missing = Belum diunduh
# Accessible name of the progress bar.
package-progress = Kemajuan penyiapan file penginstalan
package-download-again = Unduh lagi
package-download-version = Unduh Atlas { $version }
package-download-newest = Unduh versi terbaru
package-open-file = Buka file playbook
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } telah diunduh dari GitHub dan siap diinstal.
package-from-file = Atlas { $version } telah dimuat dari { $file } dan siap diinstal.
package-unpacked = Atlas { $version } siap diinstal.
package-at = File penginstalan: { $path }
package-none-yet = Belum ada file penginstalan yang dipilih
acquire-no-asset = Atlas { $version } tidak memiliki file playbook yang dapat diunduh. Buka playbook Atlas (.apbx) yang tersimpan untuk melanjutkan.
acquire-unsupported = Aplikasi ini dapat menginstal Atlas 0.6.0 dan yang lebih baru. Untuk menginstal Atlas { $version }, gunakan AME Wizard.
acquire-failed = Tidak dapat menyiapkan file penginstalan. Coba unduh lagi atau buka playbook Atlas (.apbx) lain. Detail: { $error }

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
# Check boxes the user ticks when a check could not run.
check-ack-updates = Saya sudah memeriksa Windows Update dan tidak ada pembaruan yang menunggu diinstal
check-ack-reboot = Saya sudah memulai ulang Windows dan tidak perlu memulai ulang lagi
check-ack-internet = PC ini terhubung ke internet
check-ack-generic = Saya sudah memeriksa persyaratan ini sendiri
detail-admin-ok = Atlas memiliki izin untuk membuat perubahan yang diperlukan untuk penginstalan.
detail-admin-missing = Jalankan ulang Atlas sebagai administrator, lalu pilih Ya saat Windows meminta izin.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Versi Atlas ini memerlukan Windows build { $builds }. PC Anda menggunakan build { $build }. Instal versi Windows yang didukung sebelum melanjutkan.
detail-updates-none = Tidak ada pembaruan Windows yang menunggu diinstal.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Instal pembaruan ini terlebih dahulu: { $titles }.
        [2] Instal kedua pembaruan ini terlebih dahulu: { $titles }.
       *[other] Instal { $count } pembaruan terlebih dahulu, termasuk { $titles }.
    }
detail-updates-unknown = Tidak dapat memeriksa pembaruan Windows. Buka Windows Update, lalu konfirmasikan di bawah jika tidak ada pembaruan yang menunggu. ({ $error })
detail-reboot-none = Windows tidak perlu dimulai ulang saat ini.
detail-reboot-pending = Mulai ulang PC untuk menyelesaikan perubahan sebelumnya. Setelah itu, buka kembali Atlas dan periksa lagi.
detail-reboot-unknown = Tidak dapat memeriksa apakah Windows perlu dimulai ulang. Mulai ulang PC, lalu buka kembali Atlas dan periksa lagi. ({ $error })
detail-antivirus-none = Tidak ada antivirus lain yang terdeteksi.
# $products is a list of product names (text).
detail-antivirus-found = Antivirus berikut dapat menghalangi penginstalan: { $products }. Hapus instalan perangkat lunak ini sebelum melanjutkan.
detail-antivirus-unknown = Tidak dapat memeriksa antivirus lain. Periksa aplikasi yang terinstal sebelum melanjutkan. ({ $error })
detail-internet-ok = PC terhubung ke internet. Pertahankan koneksi ini saat Atlas mengunduh dan menginstal perangkat lunak.
detail-internet-missing = Hubungkan PC ke internet, lalu periksa lagi.
detail-power-mains = PC terhubung ke sumber listrik. Biarkan tetap terhubung hingga penginstalan selesai.
detail-power-battery = Hubungkan PC ke sumber listrik agar tetap menyala selama penginstalan.
detail-power-unknown = Tidak dapat memeriksa sumber daya listrik. Jika Anda menggunakan laptop, hubungkan ke sumber listrik sebelum melanjutkan.
detail-activation-ok = Windows sudah diaktifkan. Atlas tidak akan mengubahnya.
detail-activation-missing = Windows belum diaktifkan. Anda dapat melanjutkan, tetapi Atlas tidak akan mengaktifkan Windows untuk Anda.
detail-activation-no-licence = Windows tidak melaporkan adanya lisensi. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda.
detail-activation-unknown = Tidak dapat memeriksa aktivasi Windows. Anda dapat melanjutkan; Atlas tidak akan mengubah status aktivasi Anda. ({ $error })

## Step 2: Options

options-progress = Pilihan { $number } dari { $total }
options-progress-extras = Pilihan { $number } dari { $total }: tambahan opsional
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Pertahankan perlindungan antivirus?
screen-mitigations-title = Keamanan prosesor
screen-mitigations-question = Pertahankan perlindungan prosesor Windows?
screen-updates-title = Windows Update
screen-updates-question = Bagaimana sebaiknya Windows menginstal pembaruan?
screen-browser-title = Browser
screen-power-title = Daya dan keamanan
screen-apps-title = Aplikasi
screen-toolbox-title = Atlas Toolbox
screen-choose-one-title = Pilih salah satu
screen-extras-title = Tambahan opsional
screen-extras-question = Pilih tambahan yang Anda inginkan
# Question for a required choice this app has no specific wording for.
screen-generic-question = Pilih salah satu opsi untuk { $title }
learn-more-defender = Pelajari selengkapnya tentang Microsoft Defender
learn-more-mitigations = Pelajari selengkapnya tentang keamanan prosesor
learn-more-updates = Pelajari selengkapnya tentang Windows Update
learn-more-browser = Pelajari selengkapnya tentang browser
learn-more-power = Pelajari selengkapnya tentang daya dan keamanan
learn-more-apps = Pelajari selengkapnya tentang aplikasi
learn-more-toolbox = Pelajari selengkapnya tentang Atlas Toolbox
learn-more-generic = Baca panduan penyiapan
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Mempertahankan antivirus bawaan Windows untuk membantu melindungi PC Anda dari virus dan ancaman lainnya.
consequence-defender-disable = Menghapus Microsoft Defender. PC Anda tidak akan memiliki perlindungan antivirus sampai Anda menginstal aplikasi antivirus lain.
consequence-mitigations-default = Mempertahankan perlindungan bawaan Windows terhadap serangan yang mengeksploitasi cara kerja prosesor.
consequence-mitigations-disable = Menonaktifkan perlindungan ini dan mengurangi keamanan. Kinerja bergantung pada prosesor Anda dan mungkin justru memburuk.
consequence-auto-updates-disable = Anda perlu membuka Windows Update dan menginstal pembaruan sendiri. Notifikasi pembaruan tetap aktif.
consequence-auto-updates-default = Windows akan menginstal pembaruan secara otomatis, termasuk perbaikan keamanan.

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Pertahankan Microsoft Defender (disarankan)
playbook-option-defender-disable = Hapus Microsoft Defender
playbook-option-mitigations-default = Pertahankan perlindungan bawaan (disarankan)
playbook-option-mitigations-disable = Nonaktifkan perlindungan prosesor
playbook-option-auto-updates-disable = Instal pembaruan secara manual
playbook-option-auto-updates-default = Instal pembaruan secara otomatis
playbook-option-disable-hibernation = Nonaktifkan hibernasi
playbook-option-disable-power-saving = Nonaktifkan penghematan daya
playbook-option-disable-core-isolation = Nonaktifkan keamanan berbasis virtualisasi (VBS)
playbook-option-remove-snipping-tool = Hapus Snipping Tool
playbook-option-uninstall-edge = Hapus Microsoft Edge
playbook-option-install-another-browser = Instal browser
playbook-option-install-toolbox = Instal Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender adalah antivirus bawaan Windows. Sebaiknya pertahankan antivirus ini. Hapus hanya jika Anda memahami risikonya dan berencana menggunakan aplikasi antivirus lain.
playbook-page-mitigations-default-description = Perlindungan ini, yang juga disebut mitigasi keamanan, membantu melindungi dari kerentanan prosesor. Sebaiknya pertahankan pengaturan bawaan Windows.
playbook-page-auto-updates-disable-description = Pembaruan Windows mencakup perbaikan keamanan. Anda dapat membiarkan Windows menginstalnya secara otomatis atau menginstalnya sendiri.
playbook-page-install-toolbox-description = Tambahkan Atlas Toolbox untuk membantu mengelola pengaturan Atlas Anda. Toolbox masih dalam tahap beta, sehingga beberapa fitur mungkin belum selesai.
playbook-page-browser-brave-description = Pilih browser untuk diinstal. Atlas tidak akan mengubah pengaturan browser Anda.

## Step 3: Windows Security

security-banner-reading-title = Memeriksa Keamanan Windows
security-banner-reading-message = Atlas sedang memeriksa empat pengaturan perlindungan di bawah.
security-banner-off-title = Keempat pengaturan perlindungan sudah nonaktif
security-banner-off-message = Sekarang Anda dapat meninjau pilihan sebelum menginstal.
security-banner-readable-off-title = Pengaturan yang berhasil diperiksa Atlas sudah nonaktif
security-banner-readable-off-message = Periksa pengaturan lainnya di Keamanan Windows.
security-banner-on-title = Nonaktifkan perlindungan antivirus untuk sementara
security-banner-on-message = Perlindungan ini dapat menghalangi perubahan yang perlu dilakukan Atlas.
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
security-unknown-message = Setelah memastikan di Keamanan Windows bahwa keempat pengaturan sudah nonaktif, konfirmasikan di bawah.
security-acknowledge = Saya sudah memeriksa Keamanan Windows dan keempat pengaturan sudah nonaktif
security-unknown-unelevated-title = Atlas memerlukan izin untuk memeriksa perlindungan
security-unknown-unelevated-message = Jalankan ulang Atlas sebagai administrator agar Atlas dapat memeriksa pengaturan Microsoft Defender.
# The four switches, named as Windows Security names them in Indonesian.
# "Proteksi Kerusakan" follows the Indonesian Windows interface; Microsoft's
# machine-translated support pages vary ("Proteksi perusak", "Perlindungan
# Perubahan"). Verify against a localized Windows build.
protection-tamper = Proteksi Kerusakan
protection-tamper-why = Nonaktifkan ini terlebih dahulu agar Defender mengizinkan perubahan pada pengaturan perlindungannya.
protection-realtime = Perlindungan real-time
protection-realtime-why = Jeda pemindaian file agar Defender tidak memblokir file penginstalan Atlas.
protection-cloud = Perlindungan yang dikirimkan cloud
protection-cloud-why = Jeda pemeriksaan ancaman online yang dapat memblokir file penginstalan Atlas.
protection-samples = Pengiriman sampel otomatis
protection-samples-why = Cegah Defender mengirim file Atlas secara otomatis ke Microsoft untuk dianalisis.

## Step 4: Install

install-preparing-title = Pemeriksaan terakhir sebelum penginstalan
install-preparing-message = Atlas memeriksa kembali PC dan pengaturan perlindungan Anda sebelum membuat perubahan.
install-installing = Menginstal
install-running = Berjalan
# Accessible name of the progress bar.
install-progress = Kemajuan penginstalan
phase-preflight = Memeriksa PC dan menyiapkan file
phase-staging = Menyiapkan file penginstalan
phase-applying = Menyiapkan Windows. Biarkan PC tetap menyala.
phase-done = Menyelesaikan penyiapan
outcome-succeeded-title = Atlas sudah terinstal
outcome-lost-title = Hasil penginstalan tidak dapat dipastikan
outcome-failed-title = Penginstalan tidak selesai
outcome-succeeded = Mulai ulang PC untuk menyelesaikan penyiapan Atlas.
outcome-requirements = PC Anda tidak memenuhi persyaratan penginstalan. Tidak ada perubahan yang dilakukan pada PC Anda. Kembali ke Persiapan dan jalankan pemeriksaan lagi.
outcome-not-elevated = Tidak ada perubahan yang dilakukan pada PC Anda. Jalankan ulang Atlas sebagai administrator, lalu coba lagi.
outcome-failed-preflight = Penginstalan berhenti sebelum mengubah apa pun. Buka file log untuk melihat penyebabnya, lalu coba lagi.
outcome-failed-staging = Penginstalan berhenti saat menyiapkan file, sebelum mengubah Windows. Buka file log untuk melihat penyebabnya, lalu coba lagi.
outcome-failed-applying = Sebagian perubahan mungkin sudah diterapkan. Jika Anda berhenti di sini, aktifkan kembali perlindungan yang tadi Anda nonaktifkan di Keamanan Windows, jika masih tersedia.
outcome-not-started = Penginstal tidak dimulai tepat waktu. Tidak ada perubahan yang dilakukan pada PC Anda. Pilih Coba lagi.
outcome-lost = Penginstal berhenti tanpa melaporkan hasilnya, dan sebagian perubahan mungkin sudah diterapkan. Buka file log untuk melihat apa yang terjadi, lalu pilih Coba lagi untuk melanjutkan penginstalan.
restart-now-message = Windows sedang dimulai ulang untuk menyelesaikan penyiapan Atlas.
# Indonesian has no plural forms; one wording covers every count.
restart-countdown = Windows akan dimulai ulang dalam { $seconds } detik agar Atlas dapat menyelesaikan penyiapan.
restart-stopped = Mulai ulang otomatis dibatalkan. Simpan pekerjaan Anda, lalu mulai ulang PC untuk menyelesaikan penyiapan Atlas.
restart-needed = Simpan pekerjaan Anda, lalu mulai ulang Windows untuk menyelesaikan penyiapan Atlas.
restart-dont-now = Mulai ulang nanti
restart-now = Mulai ulang sekarang
# Accessible name of the countdown bar.
restart-progress = Waktu hingga mulai ulang
restart-start-failed = Windows tidak dapat dimulai ulang. Simpan pekerjaan Anda, lalu mulai ulang melalui menu Mulai. Detail: { $error }
preflight-title = Penginstalan belum dimulai
preflight-invalid-options = Atlas tidak dapat menggunakan pilihan penyiapan ini. Kembali ke Pilihan Anda dan tinjau kembali, lalu coba lagi. Detail: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Kondisi PC Anda berubah sejak pemeriksaan sebelumnya. Atasi hal berikut sebelum mencoba lagi. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Keamanan Windows: { $summary }.
preflight-busy = Jendela Atlas lain sedang memulai penginstalan. Tunggu sebentar, lalu coba lagi.
preflight-record-unreadable = Atlas tidak dapat memastikan apakah penginstalan sebelumnya masih berjalan, sehingga belum memulai penginstalan baru. Tutup dan buka kembali Atlas untuk melihat petunjuk pemulihan. Detail: { $error }
preflight-refused = Penginstal tidak dapat dijalankan. Tidak ada perubahan yang dilakukan pada PC Anda. Detail: { $error }
go-to-ready = Kembali ke Persiapan
go-to-options = Kembali ke Pilihan Anda
output-problem-title = Kemajuan penginstalan tidak dapat dibaca
output-problem-message = Atlas tidak dapat membaca log. Ini tidak berarti penginstalan berhenti. Biarkan PC tetap menyala dan coba buka file log. Detail: { $error }
install-elevate-title = Atlas memerlukan izin untuk menginstal
install-no-package-title = Pilih file penginstalan terlebih dahulu
install-no-package-message = Kembali ke Persiapan untuk mengunduh Atlas atau membuka playbook (.apbx) yang tersimpan.
install-security-title = Periksa perlindungan antivirus sebelum menginstal
install-security-reading = Memeriksa kembali keempat pengaturan perlindungan.
install-security-message = { $summary }. Buka Keamanan Windows dan pastikan keempat pengaturan sudah nonaktif sebelum melanjutkan.
summary-this-install = Ringkasan penginstalan
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
summary-command-unavailable = Tidak dapat menyiapkan perintah penginstalan. Detail: { $error }
summary-not-chosen = Belum dipilih
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Ubah { $title }
footer-still-checking = Menyiapkan penginstalan
footer-fix-items = Selesaikan pemeriksaan di atas untuk melanjutkan
footer-need-package = Unduh Atlas atau buka playbook untuk melanjutkan
footer-reading-security = Memeriksa pengaturan perlindungan
button-checking = Memeriksa
button-installing = Menginstal
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

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } sudah terinstal
installed-title = Atlas sudah terinstal
installed-ready = Semua sudah beres. PC Anda siap digunakan dengan Atlas.
installed-open-atlas = Lihat penyiapan Atlas Anda

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
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Jika mengikuti Windows: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Pratinjau · menunggu peninjauan bahasa
preview-notice = { $language } adalah terjemahan pratinjau.
preview-notice-switch = Beralih ke bahasa Inggris
preview-notice-language = Ubah bahasa
# $tag is a language tag (text).
settings-language-unavailable = { $tag } tidak tersedia dalam versi Atlas ini. Bahasa Inggris ditampilkan untuk sementara, dan pilihan bahasa Anda tetap disimpan.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas belum mendukung bahasa tampilan Windows Anda ({ $languages }). Bahasa Inggris ditampilkan untuk sementara.
settings-language-windows-unavailable = Tidak dapat memeriksa bahasa tampilan Windows Anda. Atlas menggunakan bahasa Inggris untuk sementara. Detail: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = Angka, tanggal, dan waktu mengikuti format regional Windows Anda ({ $locale }).
settings-language-contribute = Bantu menerjemahkan Atlas di GitHub
settings-installing = Penginstalan
settings-restart-label = Mulai ulang PC secara otomatis setelah penginstalan
settings-restart-locked = Pengaturan ini dapat diubah setelah penginstalan selesai.
settings-restart-description = PC perlu dimulai ulang untuk menyelesaikan penyiapan. Jika mulai ulang otomatis aktif, simpan pekerjaan Anda sebelum menginstal.
settings-about = Tentang
settings-about-app = Atlas Manager
settings-about-data = File aplikasi
settings-about-licence = Lisensi
settings-about-licence-value = GPL-3.0, gratis dan sumber terbuka
settings-view-source = Lihat kode sumber di GitHub
settings-open-data-folder = Buka folder aplikasi

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Membebaskan ruang disk yang dipakai untuk menyimpan sesi Anda saat hibernasi. Hibernasi dan startup cepat (Fast Startup) tidak akan tersedia.
consequence-disable-power-saving = Menonaktifkan fitur penghematan daya. PC Anda mungkin memakai lebih banyak daya, menjadi lebih panas, dan daya tahan baterainya lebih pendek.
consequence-disable-core-isolation = Menonaktifkan lapisan keamanan tambahan Windows, termasuk integritas memori. Ini mengurangi perlindungan dan dapat memengaruhi aplikasi atau game yang memerlukannya.
consequence-remove-snipping-tool = Menghapus aplikasi Windows untuk mengambil tangkapan layar dan merekam layar.
consequence-uninstall-edge = Menghapus browser Microsoft Edge. Pastikan Anda memiliki browser lain, atau pilih salah satu di bawah.
consequence-install-another-browser = Pilih browser di bawah dan Atlas akan menginstalnya untuk Anda.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas menyesuaikan Windows untuk mengurangi aktivitas latar belakang dan gangguan. Kami akan memandu Anda melalui pemeriksaan dan pilihan sebelum membuat perubahan.
detail-build-missing = Playbook ini tidak mencantumkan build Windows yang didukung. Pilih build playbook lengkap, bukan paket LocalTest.
## ISO creation (Beta)
iso-home-title = Media instalasi Windows
iso-home-description = Buat ISO Windows berisi Atlas untuk instalasi baru di PC ini atau PC lain.
iso-open = Buat ISO Atlas
iso-title = Buat ISO Atlas
iso-beta = Beta
iso-beta-description = Uji ISO di mesin virtual sebelum menggunakannya di PC. Cadangkan file Anda sebelum menginstal Windows.
iso-admin-description = Akses administrator diperlukan untuk membaca citra Windows dan membuat media instalasi.
iso-files-description = Pilih ISO Windows 11 x64 yang belum dimodifikasi, playbook Atlas (.apbx), dan nama file baru untuk hasilnya.
iso-source = ISO Windows
iso-package = Playbook Atlas (0.6+)
iso-output = Simpan ISO baru ke
iso-no-file = Belum ada file yang dipilih
iso-browse = Telusuri
iso-save-as = Simpan sebagai
iso-inspect = Periksa file
iso-mode-title = Preferensi Windows dan Atlas
iso-mode-interactive = Pilih pengaturan Atlas setelah masuk
iso-mode-interactive-description = Setelah masuk, Atlas membantu Anda memperbarui Windows dan aplikasi Store, memilih pengaturan, lalu menerapkan Atlas.
iso-mode-before = Pilih pengaturan Atlas sekarang
iso-mode-before-description = Simpan pengaturan Atlas dalam ISO. Setelah masuk, perbarui Windows dan aplikasi Store, lalu terapkan Atlas dengan pengaturan ini.
iso-package-unsupported-title = Pilih playbook yang lebih baru
iso-package-unsupported = Penyiapan ISO memerlukan Atlas 0.6 atau lebih baru dengan dukungan ISO. Pilih playbook yang kompatibel.
iso-atlas-options = Pengaturan Atlas
iso-review = Tinjau ISO
iso-review-title = Siap membuat ISO Anda
iso-editions = Edisi yang disertakan: { $editions }
iso-source-size = ISO sumber: { $size } MB
iso-review-description = Atlas akan membuat ISO terpisah dan mempertahankan ISO asli. Lakukan boot dari ISO baru untuk menginstal Windows. Membuat ISO tidak menginstal Atlas di PC ini.
iso-create = Buat ISO
iso-stage-inspect = Memeriksa citra Windows
iso-stage-copy = Menyalin file Windows
iso-stage-inject = Menambahkan Atlas
iso-stage-master = Membuat ISO
iso-stage-verify = Memverifikasi hasil
iso-stage-cleanup = Menyelesaikan
iso-progress-description = Biarkan aplikasi tetap terbuka. Citra berukuran besar mungkin memerlukan waktu untuk diproses.
iso-cancel = Batalkan pembuatan
iso-cancelling = Menunggu titik aman untuk membatalkan
iso-cancelled = Pembuatan ISO dibatalkan
iso-cancelled-description = ISO asli Anda tetap tersimpan. Log diagnostik mencatat file sementara yang masih perlu dihapus.
iso-complete = ISO Anda siap
iso-complete-description = Uji di mesin virtual, lalu gunakan untuk membuat media instalasi Windows.
iso-open-folder = Tampilkan di folder
iso-failed = Pembuatan ISO tidak dapat diselesaikan
iso-failed-description = Buka diagnostik untuk melihat penyebabnya. Atasi masalahnya, lalu coba lagi dengan nama file keluaran yang baru.
iso-diagnostics = Buka diagnostik
iso-close-title = Pembuatan ISO masih berlangsung
iso-close-message = Biarkan jendela ini terbuka hingga pembuatan atau pembatalan selesai. Pembatalan menunggu hingga operasi saat ini dapat dihentikan dengan aman.
iso-keep-open = Biarkan terbuka
prepare-title = Perbarui Windows dan aplikasi Store
prepare-description = Sebelum menerapkan Atlas, instal pembaruan Windows serta perbarui Microsoft Store dan semua aplikasi Store yang terinstal. Aplikasi Store mungkin ditutup saat diperbarui.
prepare-complete = Windows dan aplikasi Store sudah diperbarui.
prepare-reboot = Windows perlu dimulai ulang. Pilihan Atlas Anda akan disimpan. Periksa pembaruan lagi setelah masuk.
prepare-failed = Beberapa pembaruan belum selesai. Periksa log diagnostik, atasi kesalahan Windows atau Store, lalu coba lagi.
prepare-cancelled = Persiapan dihentikan. Periksa pembaruan lagi sebelum melanjutkan.
prepare-windows-search = Memeriksa pembaruan Windows…
prepare-windows-download = Mengunduh pembaruan Windows…
prepare-windows-install = Menginstal pembaruan Windows…
prepare-store-search = Memeriksa Microsoft Store…
prepare-store-install = Memperbarui Microsoft Store dan aplikasinya…
prepare-stop-description = Persiapan akan berhenti setelah proses pembaruan saat ini selesai. Biarkan Atlas tetap terbuka sampai saat itu.
prepare-stop = Hentikan setelah proses ini
prepare-restart = Mulai ulang dan lanjutkan
prepare-start = Periksa dan instal pembaruan
iso-username = Nama akun lokal
iso-account-description = Windows akan meminta Anda membuat kata sandi setelah diinstal ulang.
iso-username-placeholder = Nama Anda
iso-account-invalid = Gunakan 1–20 karakter tanpa spasi di awal atau akhir dan tanpa simbol yang dilarang untuk nama akun Windows.
iso-privacy-defaults = Penyiapan Windows otomatis menonaktifkan berbagi data opsional dan penawaran yang dipersonalisasi.
prepare-drivers = Bagaimana driver akan diinstal?
prepare-drivers-auto = Dapatkan driver melalui Windows Update
prepare-drivers-auto-detail = Windows mencari driver untuk perangkat keras Anda. Disarankan untuk sebagian besar PC.
prepare-drivers-manual = Saya akan menginstal driver sendiri
prepare-drivers-manual-detail = Memblokir unduhan driver dari Windows Update. Anda perlu mencari driver sendiri; driver yang sudah terinstal tetap dipertahankan.
prepare-network-needed = Hubungkan ke Wi-Fi atau Ethernet yang tidak diatur sebagai koneksi terukur, lalu coba lagi. Jika Wi-Fi tidak tersedia, instal driver jaringan terlebih dahulu.
prepare-network-settings = Buka pengaturan jaringan
iso-target-title = Di PC mana Anda akan menginstal ulang Windows?
iso-target-this = PC ini
iso-target-other = PC lain
iso-copy-network = Sertakan driver jaringan PC ini
iso-network-detail = Gunakan kembali driver Wi-Fi dan Ethernet PC ini saat menginstal Windows. Anda perlu menghubungkan ulang Wi-Fi setelah instalasi.
iso-network-source = Sumber driver jaringan
iso-network-installed = Gunakan driver yang terinstal
iso-network-updated = Periksa Windows Update terlebih dahulu
iso-network-updated-detail = Unduh driver yang sesuai dari Windows Update dan simpan driver terinstal sebagai cadangan. Memerlukan koneksi yang tidak terukur.
iso-stage-network-drivers = Menyiapkan driver jaringan…
iso-network-failed = Driver jaringan tidak dapat disiapkan. Periksa diagnostik atau kembali dan ubah opsi driver jaringan.
iso-mode-desktop = Selesaikan penyiapan sebelum membuka desktop
iso-mode-desktop-description = Pilih pengaturan Atlas sekarang. Setelah masuk, selesaikan pembaruan dan penyiapan Atlas sebelum membuka desktop Windows.
desktop-setup-description = Selesaikan penyiapan PC Anda. Pilihan Atlas tersimpan; Anda dapat kembali ke Windows jika perlu.
desktop-setup-exit = Lanjutkan di Windows

# Windows installation USB (Beta)
usb-title = Buat USB instalasi
usb-existing = Buat USB dari ISO yang sudah ada
usb-description = Buat USB boot Windows 11 25H2 untuk menginstal Windows dan Atlas di PC Anda.
usb-choose-iso = Pilih ISO
usb-drive = Drive USB
usb-empty = Hubungkan drive USB, lalu muat ulang daftar. Hanya drive USB yang dapat ditulis dan tidak berisi Windows yang sedang berjalan yang ditampilkan.
usb-refresh = Muat ulang
usb-drive-detail = { $size } GB · { $volumes } · Nomor seri: { $serial }
usb-review = Tinjau USB
usb-erase-title = Hapus isi drive USB ini?
usb-erase-description = Semua file dan partisi pada { $drive } ({ $size } GB) akan dihapus secara permanen. ISO Anda tetap disimpan.
usb-layout = Instalasi Windows menggunakan hingga 32 GB. Ruang sisanya tidak akan dialokasikan. USB ini untuk PC yang melakukan boot melalui UEFI.
usb-ack = Saya memahami bahwa seluruh isi drive USB ini akan dihapus.
usb-write = Hapus dan buat USB
usb-stage-prepare = Menyiapkan file instalasi…
usb-stage-format = Memformat USB…
usb-stage-copy = Menyalin file instalasi…
usb-stage-verify = Memverifikasi USB…
usb-working = Biarkan Atlas terbuka dan USB tetap terhubung. Pembatalan menunggu operasi saat ini berhenti dengan aman. USB yang belum selesai tidak dapat digunakan untuk menginstal Windows.
usb-failed = Pembuatan USB tidak dapat diselesaikan. Periksa koneksinya dan buka diagnostik untuk melihat detail. Pilih kembali drive untuk mencoba lagi.
usb-cancelled = Pembuatan USB dihentikan. Drive mungkin berisi file instalasi yang belum lengkap. Buat ulang sebelum menggunakannya untuk menginstal Windows.
usb-complete = USB Anda siap dan semua file telah diverifikasi. Keluarkan USB, hubungkan ke PC yang akan diinstal ulang, lalu pilih USB di menu boot UEFI PC tersebut.
usb-eject = Keluarkan USB
usb-ejected = USB dapat dicabut dengan aman. Untuk menginstal Windows, pilih USB di menu boot UEFI PC Anda.
usb-eject-failed = Windows tidak dapat mengeluarkan USB. Tutup file atau jendela yang menggunakannya, lalu coba lagi.
ready-fresh-title = Mulai dengan instalasi Windows yang bersih
ready-fresh-description = Atlas memerlukan instalasi Windows yang bersih, kecuali untuk peningkatan Atlas yang didukung. Instalasi baru Atlas 0.6 memerlukan Windows 11 25H2. Cadangkan berkas Anda sebelum menginstal ulang Windows.
detail-edition-unsupported = Gunakan Windows 11 Pro, Pro for Workstations, atau Enterprise. Edisi Home, LTSC, dan Server tidak didukung. Jika edisi Anda tidak dapat dikenali, selesaikan masalah tersebut sebelum melanjutkan.
install-source-title = Instalasi tidak tersedia
install-source-unsupported = Atlas { $source } tidak dapat diperbarui langsung ke { $target }. Instal ulang Windows untuk menggunakan versi ini.
install-source-unknown = Atlas tidak dapat memverifikasi status instalasi. Selesaikan instalasi yang tertunda dan periksa diagnostik sebelum mencoba lagi.
iso-edition-selection = Hanya edisi yang didukung yang disertakan. Saat menginstal Windows, pilih edisi yang sesuai dengan lisensi Windows Anda.
detail-windows-preview = Build Insider tidak didukung. Gunakan rilis publik Windows 11.
detail-windows-release-unknown = Atlas tidak dapat memastikan bahwa build Windows ini merupakan rilis publik. Sambungkan ke internet dan periksa lagi.
iso-release-unknown = Tidak dapat dipastikan bahwa ISO ini berisi rilis publik Windows 11 25H2. Sambungkan ke internet dan coba lagi, atau pilih media instalasi resmi.
prepare-previous-worker = Proses pembaruan sebelumnya masih berjalan. Atlas akan menunggu hingga selesai sebelum Anda dapat mencoba lagi.

ready-used-windows-title = Instal ulang Windows sebelum melanjutkan
ready-used-windows-description = Windows ini menunjukkan tanda penggunaan sebelumnya. Menginstal Atlas di sini tidak didukung dan sangat tidak disarankan. Lanjutkan hanya jika Anda memahami risikonya.
ready-used-windows-dismiss = Saya memahami risikonya
