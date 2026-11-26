### Atlas Manager: Turkish (tr). Preview translation, revised on 24 November 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically. Turkish plural categories are one and other; nouns do not
###   change after a number, so the [one] and *[other] branches usually carry
###   the same text.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
###   Never attach a Turkish suffix directly to a variable (vowel harmony
###   cannot be known); attach it to a following noun instead
###   ("{ $version } sürümünü", "{ $file } dosyasından"), or end the sentence
###   with a colon and the variable.
### - Product names stay as they are: Atlas, AtlasOS, Windows, Microsoft
###   Defender, Windows Güvenliği, Windows Update, GitHub, Discord.
###   Windows feature names follow the Turkish Windows interface (for
###   example the four Virüs ve tehdit koruması switches).
### - Formal "siz" throughout, as in Microsoft Turkish. Buttons are short
###   imperatives. Sentences end with a full stop; titles and labels do not.
###   A control is named by its label without quotation marks, then an
###   apostrophe and suffix ("Yeniden dene'yi seçin").
### - Apostrophes are straight (') everywhere.
### - "Yeniden aç" = relaunch Atlas Manager. "Yeniden başlat" = restart the PC.
### - "Kur" installs Atlas; "yükle" installs updates, apps, drivers and Windows.
### - "Update" is "güncelleştirme" and "to update" is "güncelleştir", as in
###   Microsoft Turkish ("Güncelleştirmeyi durdur", "Güncelleştirmeleri sürdür").
### - The .atlaspkg file is the "Atlas paketi" ("paket" once that is clear;
###   the button is "Paket dosyası aç").
### - A Windows build is a "derleme", as Windows says ("İS Derlemesi").
###   Diagnostics are "tanılama verileri" everywhere.
### - Install steps: Hazırlık, Seçimleriniz, Windows Güvenliği, Kurulum.
###   ISO steps: Windows, Yapılandırma, Oluşturma. Windows' own installer
###   (Windows Setup) is "Windows Kurulumu".
### - "Try again" is "yeniden deneyin"; "tekrar" only where "yeniden başlat"
###   already stands beside it.

## Shared

app-name = Atlas Manager
common-done = Bitti
common-cancel = İptal
common-back = Geri
common-next = Devam et
common-dismiss = Kapat
# Link beside a summary row that jumps back to change that choice.
common-change = Değiştir
common-copy = Kopyala
# Shown where a list of options is empty.
common-none = Yok
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Giriş sayfasına dön
# Accessible name of the gear button in the title bar.
common-settings = Ayarlar
common-close-settings = Ayarları kapat
common-open-windows-security = Windows Güvenliği'ni aç
common-restart-as-administrator = Yönetici olarak yeniden aç
common-try-again = Yeniden dene
common-read-the-docs = Atlas kılavuzunu oku
common-show-details = Ayrıntıları göster
common-hide-details = Ayrıntıları gizle
# Accessible name of a button that acts on one card. $action is the button's label;
# $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Günlük klasörünü aç
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Kurulum günlüğünü kopyala
common-install-log = Kurulum günlüğü
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas paketi
common-checking = Denetleniyor
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 veya 26200".
list-or = { $a } veya { $b }
# Joins the last two items of a list; $a may already hold several items.
list-and = { $a } ve { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Atlas kurulurken pencere kapatılsın mı?
window-close-installing = Kurulum devam eder. Sonucu görmek için Atlas'ı yeniden açın.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = Kurulum devam eder, ancak bilgisayarınız kendiliğinden yeniden başlamaz. Sonucu görmek için Atlas'ı yeniden açın.
# The answer that keeps the window open when closing it would interrupt something.
window-close-keep = Açık tut
window-close-close = Pencereyi kapat
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Kurulum başlamadan durdurulsun mu?
window-close-checks-unchanged = Kurulum henüz hiçbir değişiklik yapmadı. Kapatırsanız kurulum başlamaz.
window-close-keep-installing = Kuruluma devam et
window-close-stop-and-close = Durdur ve kapat
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop.
prepare-close-question = Güncelleştirme durdurulsun mu?
# "Aşama" is a stage of updating (as in prepare-percent), not one of the four flow steps (adım).
prepare-close-stops-after-stage = Atlas geçerli aşamadan sonra durur. Ardından Atlas'ı kapatabilirsiniz.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now.
window-close-restart-question = Atlas kurulumunu tamamlamak için yeniden başlatılsın mı?
window-close-restart-closed = Atlas kapandıktan sonra bilgisayarınızı yeniden başlatamaz. Önce çalışmanızı kaydedin.
# Closing while Get ready counts down to the restart that updates need. Its buttons are
# restart-now and restart-dont-now; Atlas carries on after the next restart.
window-close-update-restart-question = Güncelleştirmeyi tamamlamak için yeniden başlatılsın mı?
window-close-update-restart-later = Önce çalışmanızı kaydedin. Daha sonra yeniden başlatırsanız Atlas, bilgisayar açıldığında devam eder.
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some.
window-close-protection-title = Koruma kapalıyken Atlas kapatılsın mı?
window-close-protection-all = Windows Güvenliği'ndeki dört koruma anahtarı kapalı. Atlas'ı şimdi kurmayacaksanız önce bunları yeniden açın.
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
        [one] Windows Güvenliği'nde şu koruma kapalı: { $switches }. Atlas'ı şimdi kurmayacaksanız önce yeniden açın.
       *[other] Windows Güvenliği'nde şu korumalar kapalı: { $switches }. Atlas'ı şimdi kurmayacaksanız önce bunları yeniden açın.
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop.
iso-close-question = ISO oluşturma durdurulsun mu?
iso-close-safe-point = Atlas bir sonraki güvenli noktada durur.
usb-close-question = USB sürücüsü oluşturma durdurulsun mu?
usb-close-unfinished = Tamamlanmamış bir sürücüyle Windows yüklenemez.
window-close-keep-creating = Oluşturmaya devam et
window-close-stop = Durdur
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Atlas paketi aç (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas kuruldu. Kurulumu tamamlamak için Windows yeniden başlatılıyor.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas, güncelleştirmelerin yüklenmesini tamamlamak için Windows'u yeniden başlatıyor.

## System

# "Windows 11 Pro 25H2 (derleme 26200.1234)". All three values are text.
system-description = { $product } { $version } (derleme { $build })

## Home page

home-not-installed = Atlas'a hoş geldiniz
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas, Windows'taki arka plan etkinliğini ve dikkat dağıtıcı öğeleri azaltır.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Bu bilgisayardaki Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status. $date is a formatted date.
home-installed-on = { $date } tarihinde kuruldu
home-status-checking = Güncelleştirmeler denetleniyor…
# While startup checks whether another window's installation is running.
home-status-recovering = Devam eden bir kurulum aranıyor
home-status-offline = Güncelleştirmeler denetlenemedi
home-status-not-checked = Güncelleştirmeler henüz denetlenmedi
home-status-update = Atlas { $version } kullanılabilir
home-status-up-to-date = Güncel
home-status-newest = En son sürüm: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Atlas { $version } kurulumu tamamlanmadı
home-check-again = Yeniden denetle
# Primary button while an install is running or waiting.
home-show-install = İlerlemeyi görüntüle
home-continue-installing = Kuruluma devam et
home-update-to = Atlas { $version } sürümüne güncelleştir
home-reinstall = Atlas'ı yeniden kur
home-install = Atlas'ı kur
home-finish-install = Atlas { $version } kurulumunu tamamla
home-start-over = Baştan başla
# Asked by Install Atlas where Windows on this PC has been in use. Its buttons are
# common-cancel and home-used-windows-install.
home-used-windows-title = Atlas bu bilgisayara kurulsun mu?
home-used-windows-message = Mevcut uygulamalarınız ve ayarlarınız artık çalışmayabilir. Atlas OneDrive'ı da kaldırır; OneDrive'daki dosyaların eşitlenmesi durur ve klasörler boş görünebilir. Önce dosyalarınızı yedekleyin.
home-used-windows-install = Yine de kur
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Windows'u Atlas ile yeniden yükle
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Bu bilgisayardaki Windows bir süredir kullanılıyor; Atlas en iyi sonucu temiz bir kurulumda verir.
# A bar on Home after an installation finished, until the PC restarts.
home-restart-title = Bilgisayarınızın yeniden başlatılması gerekiyor
# Instead of restart-needed when Windows refused to restart; the bar's button is common-try-again.
home-restart-failed = Atlas bilgisayarınızı yeniden başlatamadı. Başlat menüsünden yeniden başlatın.
home-security-reminder-title = Korumayı yeniden açın
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Korumanızın açık olduğundan emin olun
# Under home-security-reminder-title. $switches names the switches that read off, as Windows
# Security names them, joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] Windows Güvenliği'nde şu koruma hâlâ kapalı: { $switches }.
       *[other] Windows Güvenliği'nde şu korumalar hâlâ kapalı: { $switches }.
    }
# Instead of security-switches-still-off when no switch reads off but some couldn't be read.
home-security-reminder-unreadable-message = Atlas koruma anahtarlarının hepsini okuyamadı. Windows Güvenliği'nde şunların açık olduğunu denetleyin: { $switches }.
home-elevation-title = Atlas'ın kurulum için izne ihtiyacı var
# The raw error is behind Show details.
home-elevation-draft-not-saved = Atlas kurulum seçimlerinizi kaydedemedi, bu yüzden yeniden açılmadı.
home-state-error-title = Atlas kurulum bilgileriniz okunamadı
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = Atlas sürümünüz, seçimleriniz ve geçmişiniz doğru gösterilmeyebilir.
# A bar on Home when the Atlas package needs a newer Atlas Manager; manager-download is beside
# the version above.
home-manager-needed-title = Daha yeni bir Atlas Manager gerekiyor
home-whats-new = Atlas { $version } sürümündeki yenilikler
home-view-release = Sürüm notlarını GitHub'da görüntüle
home-show-less = Daha az göster
home-show-full-notes = Tüm sürüm notlarını göster
home-your-install = Atlas kurulumunuz
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Bu bilgisayarda Atlas'ın nasıl kurulduğuna dair bir kayıt yok, bu yüzden seçimleriniz ve kurulum geçmişi gösterilemiyor.
home-history = Kurulum geçmişi
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = { $number }. adım: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = Neler olacak
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Atlas kurulumu sürüyor
# Beside step-ready in that card.
home-step-ready = Atlas bilgisayarınızı denetler ve Windows'u güncelleştirir.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas bilgisayarınızı denetler ve Windows'u { $release } sürümüne geçirir.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = Microsoft Defender gibi neleri tutacağınızı seçersiniz.
# Beside step-security in that card.
home-step-security = Windows Güvenliği'ndeki dört koruma anahtarını kapatırsınız.
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
        [one] Kurulum genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınız yeniden başlar.
       *[other] Kurulum genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınız yeniden başlar.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] Kurulum genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınızı yeniden başlatın.
       *[other] Kurulum genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınızı yeniden başlatın.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Önce çalışmanızı kaydedin: uygulamalar kapanabilir ve bilgisayarınız yeniden başlar.
home-github = Atlas'ı GitHub'da görüntüle
home-discord = Atlas Discord topluluğuna katıl
home-report-problem = Sorun bildir

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = ilk kurulum
history-mode-upgrade = güncelleştirme
history-mode-reapply = yeniden kurulum
history-mode-unknown = kurulum

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas varsayılan uygulama ayarlarını kullanıyor
notice-settings-unreadable-problem = Atlas kayıtlı uygulama ayarlarınızı okuyamadı. Windows ayarlarınız değişmedi.
notice-settings-damaged-kept-problem = Uygulama ayarları dosyanız hasarlıydı; Atlas dosyayı sıfırladı ve eski dosyanın bir kopyasını sakladı.
notice-settings-damaged-problem = Uygulama ayarları dosyanız hasarlı. Atlas şimdilik varsayılan ayarları kullanıyor.
notice-settings-not-saved-title = Uygulama ayarları kaydedilemedi
notice-settings-not-saved-problem = Atlas son değişikliklerinizi kaydedemedi; Atlas'ı kapattığınızda bunlar kaybolabilir. Başka bir Atlas penceresi açıksa kapatın, ardından değişikliği yeniden yapın.
notice-session-unreadable-title = Önceki kurulum denetlenemedi
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas, önceki bir kurulumun hâlâ sürüp sürmediğini anlayamadı. Çalışan bir kurulum olmadığından eminseniz kurulum kaydını silin, ardından Atlas'ı yeniden açın.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas, önceki bir kurulumun hâlâ sürüp sürmediğini anlayamadı. Emin değilseniz Atlas topluluğundan yardım isteyin. Yalnızca çalışan bir kurulum olmadığından eminseniz { $path } dosyasını silin ve yeniden deneyin. Ayrıntılar: { $error }

## Administrator elevation

elevation-declined = İzin verilmedi. Yeniden deneyin ve Windows, Atlas'ın değişiklik yapmasına izin vermenizi istediğinde Evet'i seçin.
elevation-declined-continue = İzin verilmedi. Yeniden deneyin ve Windows, Atlas'ın değişiklik yapmasına izin vermenizi istediğinde Evet'i seçin. Kurulum seçimleriniz kaydedildi.
elevation-draft-not-saved = Atlas kurulum seçimlerinizi kaydedemedi, bu yüzden yeniden açılmadı. Yeniden deneyin. Ayrıntılar: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Başka bir Atlas penceresi bu kurulumu devraldı, bu yüzden Atlas yeniden açılmadı. O pencerede devam edin veya kurulumu burada baştan yapmak için Baştan başla'yı seçin.

## The install flow

step-ready = Hazırlık
step-options = Seçimleriniz
step-security = Windows Güvenliği
step-install = Kurulum
install-title = Atlas kurulumu
# Accessible name of the row of steps.
stepper-label = Atlas kurulum adımları
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = tamamlandı
stepper-status-current = geçerli adım
stepper-status-upcoming = sonraki adım
# A step already visited whose requirements aren't met yet.
stepper-status-attention = dikkat gerektiriyor
# Names the step showing; read when the current step takes focus.
step-heading = Adım { $number } / { $total }: { $title }
# Accessible name of the current step on Your choices. $heading is stepper-item-a11y;
# $questions is each question the screen asks, one after another.
step-heading-choices-a11y = { $heading }. { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. Turkish uses a noun phrase, like the other two rows.
ready-checks-title = Bilgisayar denetimleri
# Status line while the checks run.
ready-checks-running = Bilgisayarınız denetleniyor…
ready-check-again = Yeniden denetle
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [one] { $count } denetim geçti
       *[other] { $count } denetim geçti
    }
# Status line when some checks need attention, which are listed under it.
ready-checks-passed-some =
    { $total ->
        [one] { $total } denetimden { $passed } tanesi geçti
       *[other] { $total } denetimden { $passed } tanesi geçti
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of: "9 denetimden 5 tanesi geçti · 4 tanesi güncelleştirmeyle halledilecek". $count is
# how many updating takes care of.
ready-checks-handled = { $count } tanesi güncelleştirmeyle halledilecek
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = güncelleştirmeyle halledilecek
# Under the title of a check that updating takes care of.
check-updates-handled = Bekleyen güncelleştirmeler var. Atlas bunları Windows'u güncelleştirirken yükler.
check-restart-handled = Windows'un önceki değişiklikleri tamamlamak için yeniden başlatılması gerekiyor. Atlas bunu güncelleştirme sırasında halleder.
check-handled = Atlas bunu güncelleştirme sırasında halleder.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version } paketi
# Status lines of the package row.
ready-package-downloading = İndiriliyor…
ready-package-unpacking = Paket açılıyor…
ready-package-ready = Hazır
ready-package-checking = En son sürüm denetleniyor…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Birlikte gelen Atlas paketi hazırlanıyor…
ready-package-none = Henüz indirilmedi
ready-package-failed = Atlas paketi alınamadı
# Under ready-package-failed, with package-download-again and package-open-file.
ready-package-failed-detail = Yeniden indirin veya başka bir Atlas paketi (.atlaspkg) açın.
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = Bu test sürümüyle gelen Atlas paketi açılamadı. Yeniden deneyin.
ready-package-manager = Daha yeni bir Atlas Manager gerekiyor
ready-package-release-failed = En son sürüm denetlenemedi
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = İnternet bağlantınızı denetleyin, ardından yeniden deneyin. Bir Atlas paketiniz (.atlaspkg) varsa onu açabilirsiniz.
# Row title.
ready-updates-title = Windows ve Microsoft Store güncelleştirmeleri
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Not Defteri gibi Store uygulamaları güncelleştirilirken kapanabilir. Önce bu uygulamalardaki çalışmanızı kaydedin.
# Status line while Windows moves to version $release.
ready-updates-after-move = Windows { $release } sürümüne geçtikten sonra başlar.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Yeniden başlatmanın ardından devam ediliyor…
ready-updates-restarting = Bilgisayarınız yeniden başlatılıyor…
ready-updates-done = Windows ve Store uygulamaları güncel.
# Instead of ready-updates-done where Microsoft Store is turned off.
ready-updates-done-windows = Windows güncel.
# The countdown before the restart updating needs. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Bilgisayarınız { $seconds } saniye içinde yeniden başlayacak.
       *[other] Bilgisayarınız { $seconds } saniye içinde yeniden başlayacak.
    }
ready-updates-restart = Güncelleştirmeyi tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor.
ready-updates-restart-finish = { $release } sürümünün yüklenmesini tamamlamak için Windows'un bir kez daha yeniden başlatılması gerekiyor.
ready-updates-restart-failed = Bilgisayarınız yeniden başlamadı
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Önce çalışmanızı kaydedin.
ready-updates-restart-persists = Windows hâlâ yeniden başlatma istiyor
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Bir kez daha yeniden başlatmak büyük olasılıkla işe yaramaz. Windows Update'te bekleyenleri tamamlayın, ardından yeniden deneyin.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Yeniden başlatma nedenleri: { $reasons }
ready-updates-network = Güncelleştirmeler bu bağlantıyı kullanamıyor
ready-updates-stopped = Güncelleştirme durdu. Bazı güncelleştirmeler zaten yüklenmiş olabilir.
ready-updates-previous = Daha önce başlayan güncelleştirmeler bekleniyor…
# Button after the user stopped updating.
ready-updates-resume = Güncelleştirmeleri sürdür
ready-updates-start = Güncelleştirmeyi başlat
# Why updating hasn't started, under the row.
ready-updates-blocked = Güncelleştirmeler, Atlas bu bilgisayara kurulabilene kadar bekler.
ready-updates-needs-admin = Atlas yönetici izni aldığında başlar.
ready-updates-needs-windows = Windows uyumluluk denetimi geçtiğinde başlar.
ready-updates-needs-drivers = Sürücülerin nasıl yükleneceğine karar verdiğinizde başlar.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual.
ready-drivers-row = Sürücüler: { $choice }
ready-drivers-automatic = Windows Update aracılığıyla
ready-drivers-manual = Kendim yükleyeceğim
ready-drivers-change-a11y = Sürücülerin nasıl yükleneceğini değiştir
# Under the two answers, once updating has run.
ready-drivers-again = Bunu değiştirirseniz güncelleştirmeler yeniden çalıştırılır.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } indiriliyor · { $received } / { $total } MB
package-unpacking = Paket açılıyor
package-status-ready = Hazır
# Accessible name of the progress bar.
package-progress = Atlas paketinin ilerlemesi
package-download-again = Yeniden indir
package-download-version = Atlas { $version } sürümünü indir
package-download-newest = En son sürümü indir
package-cancel-download = İndirmeyi iptal et
package-open-file = Paket dosyası aç
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } GitHub'dan indirildi ve kuruluma hazır.
package-from-file = Atlas { $version }, { $file } dosyasından yüklendi ve kuruluma hazır.
package-unpacked = Atlas { $version } kuruluma hazır.
package-none-yet = Henüz Atlas paketi yok
acquire-no-asset = Atlas { $version } sürümü için indirilebilecek bir paket dosyası yok. Devam etmek için kayıtlı bir Atlas paketi (.atlaspkg) açın.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = Bu uygulama Atlas 0.6.0 ve sonraki sürümleri Atlas paketlerinden (.atlaspkg) kurabilir.
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = Bu bir Windows ISO'sudur, Atlas paketi (.atlaspkg) değildir. Windows'u Atlas ile yeniden yüklemek için bununla bir Atlas ISO'su oluşturun.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } sürümünde bu uygulamanın kurulum için ihtiyaç duyduğu dosyalar eksik. Sürümü yeniden indirin veya başka bir Atlas paketi (.atlaspkg) açın.
acquire-failed = Atlas paketi hazırlanamadı. Yeniden indirin veya başka bir Atlas paketi (.atlaspkg) açın. Ayrıntılar: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = İndirme yanıt vermeyi durdurdu. İnternet bağlantınızı denetleyin, sonra yeniden indirin veya kayıtlı bir Atlas paketi (.atlaspkg) açın.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Birlikte gelen Atlas paketi hazırlanamadı. Yeniden dene'yi seçin. Ayrıntılar: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks
# for, such as 0.7.0. manager-download is beside it. "Onu" is the Atlas Manager downloaded, and
# "bu sürüm" the Atlas Manager running now.
acquire-manager-update-needed = Bu Atlas paketi için daha yeni bir Atlas Manager gerekiyor. Atlas Manager'ın { $version } veya sonraki bir sürümünü indirin ve bu sürüm yerine onu kullanın.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = Bu Atlas paketi için daha yeni bir Atlas Manager gerekiyor. Atlas Manager'ın en son sürümünü indirin ve bu sürüm yerine onu kullanın.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# manager-download is beside it, on Get ready and on Home.
acquire-manager-update-required = Atlas { $version } sürümünü kurmak için Atlas Manager'ın { $required } veya sonraki bir sürümünü indirin ve bu sürüm yerine onu kullanın.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Atlas { $version } sürümünü kurmak için Atlas Manager'ın en son sürümünü indirin ve bu sürüm yerine onu kullanın.

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Atlas Manager'ı indir
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } sürümü kullanılabilir
manager-update-message = Atlas Manager kendini güncelleştiremez. Yeni sürümü indirin ve bu sürüm yerine onu kullanın.

## System checks

check-administrator = Kurulum izni
check-supported-build = Windows uyumluluğu
check-pending-updates = Windows güncelleştirmeleri
check-pending-reboot = Bekleyen yeniden başlatma
check-third-party-antivirus = Diğer virüsten koruma yazılımları
check-internet = İnternet bağlantısı
check-power = Güç kaynağı
check-activation = Windows etkinleştirmesi
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Windows 11 donanımı
check-move-space = Boş alan
check-move-update-source = Güncelleştirme kaynağı
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = denetleniyor
check-state-passed = geçti
check-state-warning = dikkat gerektiriyor
check-state-failed-blocking = kurulumdan önce işlem gerekiyor
check-state-failed = dikkat gerektiriyor
check-state-unknown = denetlenemedi
check-fix-windows-update = Windows Update'i aç
check-fix-network = Ağ ayarlarını aç
check-fix-power = Güç ayarlarını aç
check-fix-activation = Etkinleştirme ayarlarını aç
# Opens Storage (Depolama) in Windows Settings, where space is freed up.
check-fix-storage = Depolama ayarlarını aç
# Opens Installed apps (Yüklü uygulamalar) in Windows Settings, from the Other antivirus software
# check, as in fixed-installed.
check-fix-installed-apps = Yüklü uygulamalar sayfasını aç
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Windows Update'i denetledim: yüklenmeyi bekleyen güncelleştirme yok

detail-admin-ok = Atlas, kurulum için gereken değişiklikleri yapma iznine sahip.
detail-admin-missing = Atlas'ı yönetici olarak yeniden açın, ardından Windows izin istediğinde Evet'i seçin.
# $builds is a list of build numbers such as "26100 veya 26200"; $build is this PC's (text).
detail-build-unsupported = Bu Atlas sürümü için Windows { $builds } derlemesi gerekiyor. Bilgisayarınızda { $build } derlemesi var. Devam etmeden önce desteklenen bir Windows sürümü yükleyin.
detail-build-missing = Bu Atlas paketi desteklenen hiçbir Windows derlemesini listelemiyor. LocalTest sürümü yerine paketin tam sürümünü kullanın.
detail-updates-none = Yüklenmeyi bekleyen Windows güncelleştirmesi yok.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } güncelleştirme hâlâ bekliyor. Bunu Windows Update'ten yükleyin, ardından yeniden denetleyin.
       *[other] { $count } güncelleştirme hâlâ bekliyor. Bunları Windows Update'ten yükleyin, ardından yeniden denetleyin.
    }
detail-updates-scan-failed = Windows güncelleştirmeleri denetlenemedi. Bekleyen güncelleştirme olup olmadığını görmek için Windows Update'i açın. ({ $error })
detail-reboot-none = Windows'un şu anda yeniden başlatılması gerekmiyor.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Önceki değişiklikleri tamamlamak için Windows'un yeniden başlatılması gerekiyor. Bilgisayarınızı yeniden başlatın, ardından yeniden denetleyin.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Önceki değişiklikleri tamamlamak için Windows'un yeniden başlatılması gerekiyor ({ $reasons }). Bilgisayarınızı yeniden başlatın, ardından yeniden denetleyin.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Devam edebilirsiniz. Windows'un bir sonraki yeniden başlatmada değiştireceği veya kaldıracağı dosyalar var ({ $files }). Xbox Gaming Services gibi bazı uygulamalar bunu her yeniden başlatmadan sonra yapar.
detail-reboot-unknown = Windows'un yeniden başlatılması gerekip gerekmediği denetlenemedi. Bilgisayarınızı yeniden başlatın, ardından Atlas'ı yeniden açıp yeniden denetleyin. ({ $error })
detail-antivirus-none = Başka bir virüsten koruma yazılımı algılanmadı.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Microsoft Defender dışındaki virüsten koruma uygulamaları kurulumu engelleyebilir. { $products } yazılımını kaldırın, ardından yeniden denetleyin.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows Güvenliği { $products } yazılımını hâlâ listeliyor, ancak dosyaları artık yok; yani artık yüklü değil. Atlas yine de kurulabilir.
detail-antivirus-check-failed = Diğer virüsten koruma yazılımları denetlenemedi. Bu durum devam ederse bilgisayarınızı yeniden başlatın ve yeniden denetleyin. ({ $error })
detail-internet-ok = İnternete bağlısınız. Atlas yazılımları indirip kurarken bu bağlantıyı açık tutun.
detail-internet-missing = İnternete bağlanın, sonra yeniden denetleyin.
detail-power-mains = Bilgisayarınız fişe takılı. Kurulum bitene kadar takılı bırakın.
detail-power-battery = Kurulum boyunca açık kalması için bilgisayarınızı fişe takın.
detail-power-check-failed = Atlas, bilgisayarınızın fişe takılı olup olmadığını anlayamadı. Dizüstü bilgisayar kullanıyorsanız fişe takın, ardından yeniden denetleyin.
detail-activation-ok = Windows etkin. Atlas bunu değiştirmez.
detail-activation-missing = Windows etkin değil. Devam edebilirsiniz, ancak Atlas Windows'u sizin için etkinleştirmez.
detail-activation-no-licence = Windows bir lisans bildirmedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez.
detail-activation-unknown = Windows etkinleştirmesi denetlenemedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez. ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = Atlas'ın bu bilgisayarda Windows'u daha yeni bir sürüme geçirmesi gerekmiyor.
detail-move-hardware-ready = Bu bilgisayarda Windows 11'in gerektirdiği TPM 2.0 ve UEFI ürün yazılımı var.
detail-move-hardware-missing = Bu bilgisayarda { $missing } yok, bu yüzden Windows Update onu { $release } sürümüne geçirmez. Dosyalarınızı yedekleyin, ardından Windows'u bir Atlas ISO'suyla yeniden yükleyin.
detail-move-hardware-unread = Atlas bu bilgisayarın donanımının tamamını okuyamadı, bu yüzden denetimi Windows Update yapacak.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } sürücüsünde { $free } GB boş alan var.
detail-move-space-short = { $release } sürümü için { $drive } sürücüsünde { $needed } GB boş alan gerekiyor; sürücüde { $free } GB var. Alan boşaltın, Atlas kendiliğinden yeniden denetler.
detail-move-space-unknown = Windows güncelleştirmesi için boş alan denetlenemedi. Bilgisayarınızı yeniden başlatın, ardından yeniden denetleyin. ({ $error })
detail-move-update-source-ok = Bu bilgisayar güncelleştirmeleri Windows Update'ten alıyor.
detail-move-update-source-managed = Bu bilgisayar güncelleştirmeleri kuruluşunun sunucusundan alıyor ve bu sunucu { $release } sürümünü sunmuyor. Kuruluşunuza danışın veya Windows'u bir Atlas ISO'suyla yeniden yükleyin.

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back.
options-change-later = Microsoft Defender, işlemci korumaları ve güncelleştirme ayarlarını daha sonra masaüstünüzdeki Atlas klasöründen değiştirebilirsiniz.
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = Hiçbiri seçilmedi
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = { $count } seçildi
# Links that unfold and fold the Optional extras card.
options-extras-show = Göster
options-extras-hide = Gizle
# Under each question's title, one sentence at most.
question-defender-description = Microsoft Defender, Windows'un yerleşik virüsten koruma yazılımıdır.
question-mitigations-description = Güvenlik risk azaltmaları olarak da bilinen bu korumalar, Spectre ve Meltdown gibi işlemci açıklarına ve uygulamalardaki hatalardan yararlanan saldırılara karşı korur.
question-auto-updates-description = Her iki durumda da Atlas, Windows'u mevcut sürümünde tutar ve Microsoft Store uygulamalarının otomatik güncelleştirmelerini kapatır.
question-browser-description = Atlas tarayıcı ayarlarınızı değiştirmez.
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = Başka bir virüsten koruma uygulaması yükleyene kadar bilgisayarınızda virüsten koruma olmaz ve Windows, tanınmayan uygulamaları veya indirilen dosyaları açmadan önce sizi artık uyarmaz.
# "Açıktan yararlanma koruması" is the Windows Security page of that name.
cost-mitigations-disable = Uygulamalar için Denetim akışı koruması (CFG) gibi Açıktan yararlanma koruması ayarlarını da kapatır; bu da güvenliği azaltır.
cost-auto-updates-disable = Güvenlik düzeltmelerini almak için Windows Update'i düzenli olarak açın.
cost-auto-updates-default = Windows, güncelleştirmelerin yüklenmesini tamamlamak için bilgisayarınızı yeniden başlatabilir.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift ve Ctrl+Shift artık dili veya klavye düzenini değiştirmez.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Disk alanı boşaltır, ancak hazırda bekletme ve Hızlı Başlatma kullanılamaz hâle gelir.
extra-disable-power-saving = Bilgisayarınız daha fazla güç tüketebilir, daha çok ısınabilir ve pil ömrü kısalabilir.
extra-disable-core-isolation = Korumayı azaltır; Riot Vanguard veya FACEIT gibi hile önleme sistemlerini kullanan oyunlar, bellek bütünlüğünü yeniden açana kadar başlamayabilir.
extra-uninstall-edge = Microsoft hesabınızla eşitlenenler dışında, bu bilgisayardaki Edge yer işaretleriniz, geçmişiniz ve kayıtlı parolalarınız silinir.
extra-install-toolbox = Atlas ayarlarınızı yönetmenize yardımcı olur; ancak beta aşamasında olduğu için bazı özellikler tamamlanmamış olabilir.
extra-install-eclean = AtlasOS ekibinden, gereksiz dosyaları ve başlangıç uygulamalarını incelemeye yarayan bir araç. Hesap ve internet bağlantısı gerektirir.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Microsoft Defender kalsın mı?
screen-mitigations-title = İşlemci korumaları
screen-mitigations-question = Windows'un işlemci korumaları açık kalsın mı?
screen-updates-title = Windows Update
screen-updates-question = Windows güncelleştirmeleri nasıl yüklesin?
screen-browser-title = Tarayıcı
screen-power-title = Güç ve güvenlik
screen-apps-title = Uygulamalar
screen-optional-apps-title = İsteğe bağlı uygulamalar
screen-choose-one-title = Bir seçenek belirleyin
screen-extras-title = İsteğe bağlı ek özellikler
# Each decision's short name in the middle of a sentence, as in summary-change-a11y and
# update-path-differs: product names keep their capitals, other names are lower case.
# Messages that use them put them after a colon, so they never take a suffix.
screen-update-path-name = güncelleştirme yöntemi
screen-defender-name = Microsoft Defender
screen-mitigations-name = işlemci korumaları
screen-updates-name = Windows Update
screen-keyboard-name = klavye dilleri
screen-browser-name = tarayıcı
screen-power-name = güç ve güvenlik
screen-apps-name = uygulamalar
screen-optional-apps-name = isteğe bağlı uygulamalar
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = Atlas paketindeki bir seçim
screen-extras-name = isteğe bağlı ek özellikler
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } için bir seçenek belirleyin
learn-more-defender = Microsoft Defender hakkında daha fazla bilgi
learn-more-mitigations = İşlemci korumaları hakkında daha fazla bilgi
learn-more-updates = Windows Update hakkında daha fazla bilgi
learn-more-browser = Tarayıcılar hakkında daha fazla bilgi
learn-more-power = Güç ve güvenlik hakkında daha fazla bilgi
learn-more-apps = Uygulamalar hakkında daha fazla bilgi
learn-more-eclean = eclean hakkında daha fazla bilgi
learn-more-keyboard = Klavye dilleri hakkında daha fazla bilgi
learn-more-generic = Kurulum kılavuzunu oku
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Bilgisayarınızı virüslerden ve diğer tehditlerden korumaya yardımcı olan yerleşik Windows virüsten koruma yazılımını tutar.
consequence-mitigations-default = Windows'un işlemci açıklarına ve uygulamalardaki hatalardan yararlanan saldırılara karşı varsayılan korumalarını tutar.
# Under Turn off processor protections.
consequence-mitigations-disable = Uygulamalar için Denetim akışı koruması (CFG) gibi Açıktan yararlanma koruması ayarlarını da kapatır. Bu, güvenliği azaltır. Performansta bir fark olup olmayacağı işlemcinize bağlıdır.
consequence-auto-updates-disable = Güncelleştirmeleri yüklemek için Windows Update'i düzenli olarak açın. Güncelleştirme bildirimleri açık kalır.
consequence-auto-updates-default = Windows, güvenlik düzeltmeleri dahil güncelleştirmeleri otomatik olarak yükler.

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = Atlas { $version } sürümüne nasıl güncelleştirmek istersiniz?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = Atlas { $version } sürümünü nasıl yeniden kurmak istersiniz?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = Seçimlerimi koru
update-path-keep-detail = Atlas her seçimi bu bilgisayardaki şu anki hâliyle korur ve hiçbirini değiştirmez.
update-path-choose = Yeniden seç
update-path-choose-detail = Bu bilgisayarın şu anki durumundan başlayın. Uygulamalarınız, dosyalarınız ve kişiselleştirmeleriniz korunur.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Bu bilgisayardaki mevcut seçimleriniz
# The value of a row in that list for a choice nothing on the PC shows.
update-path-unknown = Atlas bunu bilgisayarınızdan anlayamıyor, bu yüzden size soracak
# Above that list. $choices lists the screen-*-name messages, joined with list-and.
update-path-differs = Bu bilgisayar, Atlas'ın kaydıyla şu seçimlerde eşleşmiyor: { $choices }.
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas diğer tüm seçimleri bu bilgisayardaki şu anki hâliyle korur.
# A short tag under the answer this PC has now, on the screens of Choose again.
option-now = Şu anda bu bilgisayarda
# Under an answer on a screen of Choose again when choosing it changes this PC.
change-defender-enable = Atlas, Microsoft Defender'ı geri getirir. Bilgisayarınız yeniden başladıktan sonra korumasını Windows Güvenliği'nde açın.
change-mitigations-default = Atlas, işlemci korumalarını Windows'un varsayılan ayarlarıyla yeniden açar. Bu değişiklik, bilgisayarınız yeniden başladıktan sonra geçerli olur.
# Under Keep processor protections when every protection is turned on.
change-mitigations-all-on = Şu anda tüm işlemci korumaları açık. Korumaları tutarsanız hepsi açık kalır.
change-auto-updates-default = Atlas, Windows'un güncelleştirmeleri yeniden otomatik olarak yüklemesine izin verir.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas hazırda bekletmeyi yeniden açar.
change-power-saving-on = Atlas güç tasarrufunu yeniden açar ve önceki güç planınıza, önceki bir plan yoksa Dengeli plana geri döner.
change-core-isolation-on = Atlas, sanallaştırma tabanlı güvenliği (VBS) yeniden açar; ancak bu bilgisayarda bir ilke bunu denetliyorsa açmaz. Bu değişiklik, bilgisayarınız yeniden başladıktan sonra geçerli olur.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Ekran Alıntısı Aracı'nı bu bilgisayardaki herkes için kaldırır. Atlas onu daha sonra geri getiremez, ancak Microsoft Store'dan yeniden yükleyebilirsiniz.
# Install or Remove Edge is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge zaten kaldırılmış ve Atlas'ı güncelleştirmek onu geri getiremez. Yeniden yüklemek için Atlas klasöründeki Install or Remove Edge dosyasını kullanın.
# $app is the name of an app Atlas installed, such as Atlas Toolbox or Brave.
fixed-installed = { $app } yüklü. Atlas uygulamaları kaldırmaz; bu uygulamayı kaldırmak için Windows Ayarları'ndaki Yüklü uygulamalar sayfasını açın.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } yüklü kalır ve Atlas ayrıca { $browser } tarayıcısını yükler.

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too, without the
## recommendation, for the Install step's summary, Home and the records.

package-option-defender-enable = Microsoft Defender'ı tut (önerilir)
package-option-defender-enable-short = Microsoft Defender'ı tut
package-option-defender-disable = Microsoft Defender'ı kaldır
package-option-mitigations-default = İşlemci korumalarını tut (önerilir)
package-option-mitigations-default-short = İşlemci korumalarını tut
package-option-mitigations-disable = İşlemci korumalarını kapat
package-option-auto-updates-disable = Güncelleştirmeleri kendim yükleyeceğim
package-option-auto-updates-default = Güncelleştirmeleri otomatik olarak yükle
package-option-disable-hibernation = Hazırda bekletmeyi kapat
package-option-disable-power-saving = Güç tasarrufunu kapat
package-option-disable-core-isolation = Sanallaştırma tabanlı güvenliği (VBS) kapat
package-option-remove-snipping-tool = Ekran Alıntısı Aracı'nı kaldır
package-option-uninstall-edge = Microsoft Edge'i kaldır
package-option-install-another-browser = Tarayıcı yükle
package-option-install-toolbox = Atlas Toolbox'ı yükle
package-option-install-eclean = eclean yükle
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender, Windows'un yerleşik virüsten koruma yazılımıdır. Yalnızca riskleri anlıyorsanız ve başka bir virüsten koruma uygulaması kullanacaksanız kaldırın. Hangisini seçerseniz seçin, Atlas şunları kapatır: Akıllı Uygulama Denetimi, Gelişmiş Kimlik Avı Koruması ve Cihazımı bul.
package-choice-mitigations-description = Güvenlik risk azaltmaları olarak da bilinen bu korumalar, Spectre ve Meltdown gibi işlemci açıklarına ve uygulamalardaki hatalardan yararlanan saldırılara karşı korunmaya yardımcı olur. Windows varsayılanlarını tutmanız önerilir.
package-choice-auto-updates-description = Windows güncelleştirmeleri güvenlik düzeltmeleri içerir. Bunları Windows'un otomatik olarak yüklemesini seçebilir veya kendiniz yükleyebilirsiniz. Her iki durumda da Atlas, Windows'u mevcut sürümünde tutar. Bu sürüm, yalnızca Microsoft desteğini sonlandırana kadar güvenlik düzeltmeleri alır. Atlas ayrıca Microsoft Store uygulamalarının otomatik güncelleştirmelerini kapatır; bu yüzden bu uygulamaları Microsoft Store'dan güncelleştirin.
package-choice-browser-description = Yüklenecek bir tarayıcı seçin. Atlas tarayıcı ayarlarınızı değiştirmez.

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender bu bilgisayarda yüklü değil
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = Kapatılacak koruma anahtarı yok.
# When Atlas's own package removed Microsoft Defender and it stays removed.
security-banner-removed-title = Atlas, Microsoft Defender'ı bu bilgisayardan kaldırdı
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas bu kurulumda Microsoft Defender'ı geri getiriyor
security-restore-nothing-to-turn-off = Defender henüz çalışmıyor, bu yüzden kapatılacak bir şey yok. Yeniden başlatmanın ardından korumasını Windows Güvenliği'nde açın.
# The user chose to keep Microsoft Defender, but it isn't on this PC and Atlas didn't remove it.
# Home and the "Atlas is installed" window use the same title.
security-banner-missing-title = Microsoft Defender bulunamadı
security-banner-missing-message = Atlas onu kaldırmadı, bu yüzden geri getiremez. Devam edebilirsiniz, ancak başka bir virüsten koruma uygulaması yükleyene veya Windows'u onarana kadar bilgisayarınızda virüsten koruma olmaz.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches.
security-turn-off-title = Bu dört anahtarı kapatın
security-turn-off-message = Microsoft Defender, kurulum sırasında Atlas'ı engelleyebilir. Defender'ı tutarsanız kurulumdan sonra anahtarları yeniden açın.
# The page name in Windows Security.
security-list-title = Virüs ve tehdit koruması ayarları
security-switch-off = Kapalı
security-switch-on = Açık
security-switch-unreadable = Okunamadı
security-switch-reading = Denetleniyor
security-all-off = Tümü kapalı
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 tanesi hâlâ açık, 1 tanesi okunamadı".
security-count-still-on = { $count } tanesi hâlâ açık
security-count-unreadable = { $count } tanesi okunamadı
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# joined with list-and; $count is how many there are.
security-unread-switches-title =
    { $count ->
        [one] Atlas, { $switches } anahtarını okuyamadı
       *[other] Atlas, { $switches } anahtarlarını okuyamadı
    }
security-unread-message =
    { $count ->
        [one] Windows Güvenliği'nde kapalı olduğundan emin olun.
       *[other] Windows Güvenliği'nde kapalı olduklarından emin olun.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] { $switches } anahtarının kapalı olduğunu denetledim
       *[other] { $switches } anahtarlarının kapalı olduğunu denetledim
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = Windows Güvenliği'ni denetledim ve dört anahtar da kapalı
security-unknown-unelevated-title = Atlas'ın korumayı denetlemek için izne ihtiyacı var
security-unknown-unelevated-message = Microsoft Defender ayarlarını denetleyebilmesi için Atlas'ı yönetici olarak yeniden açın.
# The four switches, named as Windows Security names them in Turkish, each with why it must be off.
protection-tamper = Kurcalama Koruması
protection-tamper-why = Atlas'ın güvenlik ayarlarını değiştirebilmesi için.
protection-realtime = Gerçek zamanlı koruma
protection-realtime-reason = Taramalar Atlas'ın dosyalarını engelleyebilir.
protection-cloud = Bulut tabanlı koruma
protection-cloud-reason = Çevrimiçi denetimler Atlas'ın dosyalarını engelleyebilir.
protection-samples = Otomatik örnek gönderimi
protection-samples-why = Atlas'ın dosyalarının Microsoft'a gönderilmemesi için.

## Step 4: Install

outcome-succeeded-title = Atlas kuruldu
outcome-lost-title = Kurulum sonucu doğrulanamadı
outcome-failed-title = Kurulum tamamlanmadı
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. It never names the bar's button.
# Beside go-to-ready.
result-requirements = Bilgisayarınız kurulum gereksinimlerini karşılamadı, bu yüzden kurulum hiçbir değişiklik yapmadı.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Bilgisayarınız kurulum gereksinimlerini karşılamadığı için bu deneme durdu. Önceki bir deneme zaten değişiklik yaptı.
# Beside common-restart-as-administrator.
result-not-elevated = Atlas'ın yönetici izni yoktu, bu yüzden kurulum hiçbir değişiklik yapmadı.
result-not-elevated-resumed = Atlas'ın yönetici izni olmadığı için bu deneme durdu. Önceki bir deneme zaten değişiklik yaptı.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready.
result-preparation-stale = Atlas, Windows ve Store uygulamalarının güncel olduğunu doğrulayamadı, bu yüzden kurulum Windows'u değiştirmeden durdu.
result-preparation-stale-resumed = Atlas, Windows ve Store uygulamalarının güncel olduğunu doğrulayamadığı için bu deneme durdu. Önceki bir deneme zaten değişiklik yaptı.
result-failed-preflight = Kurulum hiçbir şeyi değiştirmeden durdu. Yeniden deneyebilirsiniz.
result-failed-staging = Kurulum, dosyalar hazırlanırken ve Windows değiştirilmeden önce durdu. Yeniden deneyebilirsiniz.
# Beside common-open-windows-security. The protection switches are the four the user turned off.
result-failed-applying = Bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz; burada duracaksanız koruma anahtarlarını Windows Güvenliği'nde yeniden açın.
# The -defender-removed variants once Microsoft Defender has been removed.
result-failed-applying-defender-removed = Bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz.
result-failed-resumed = Bu deneme erken durdu, ancak önceki bir deneme zaten değişiklik yaptı. Yeniden deneyebilirsiniz; burada duracaksanız koruma anahtarlarını Windows Güvenliği'nde yeniden açın.
result-failed-resumed-defender-removed = Bu deneme erken durdu, ancak önceki bir deneme zaten değişiklik yaptı. Yeniden deneyebilirsiniz.
# The -repeated variants follow a retry that stopped with the same error as the attempt before
# it, so they point to a report. Send a report (report-title) is under the bar.
result-failed-repeated = Bu deneme öncekiyle aynı hatayla durdu, bu yüzden yeniden denemek büyük olasılıkla işe yaramaz. Atlas ekibinin nedeni bulabilmesi için bir rapor gönderin; burada duracaksanız koruma anahtarlarınızı yeniden açın.
result-failed-repeated-defender-removed = Bu deneme öncekiyle aynı hatayla durdu, bu yüzden yeniden denemek büyük olasılıkla işe yaramaz. Atlas ekibinin nedeni bulabilmesi için bir rapor gönderin.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows şunları yine kaldırmadı: { $apps }. Yeniden denemek büyük olasılıkla işe yaramaz. Atlas ekibinin nedeni bulabilmesi için bir rapor gönderin; burada duracaksanız koruma anahtarlarınızı yeniden açın.
result-failed-repeated-apps-defender-removed = Windows şunları yine kaldırmadı: { $apps }. Yeniden denemek büyük olasılıkla işe yaramaz. Atlas ekibinin nedeni bulabilmesi için bir rapor gönderin.
result-not-started = Yükleyici zamanında başlamadı, bu yüzden kurulum hiçbir değişiklik yapmadı. Yeniden deneyebilirsiniz.
result-lost = Yükleyici bir sonuç bildirmeden durdu, bu yüzden bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz; burada duracaksanız koruma anahtarlarını Windows Güvenliği'nde yeniden açın.
# Instead of result-lost once Defender is gone.
result-lost-defender-removed = Yükleyici bir sonuç bildirmeden durdu, bu yüzden bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz.
restart-now-message = Atlas kurulumunu tamamlamak için Windows yeniden başlatılıyor.
restart-stopped = Otomatik yeniden başlatma iptal edildi. Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
restart-needed = Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
restart-dont-now = Daha sonra yeniden başlat
restart-now = Şimdi yeniden başlat
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = Kurulum başlamadı
# Beside go-to-options. $choice is a screen-*-name message, such as işlemci korumaları, so it
# goes after a colon.
preflight-choice-unanswered = Atlas'ın şu konuda yanıtınıza ihtiyacı var: { $choice }.
preflight-choices-unusable = Atlas bu seçimleri kullanamadı.
# Beside go-to-ready. $checks lists check-* names joined with list-and; $count is how many.
preflight-checks-changed =
    { $count ->
        [one] Atlas bilgisayarınızı denetledikten sonra şu denetim dikkat gerektirmeye başladı: { $checks }.
       *[other] Atlas bilgisayarınızı denetledikten sonra şu denetimler dikkat gerektirmeye başladı: { $checks }.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 tanesi hâlâ açık".
preflight-security-changed = Anahtarları kapattığınızdan bu yana Windows Güvenliği'nde değişiklik oldu: { $summary }.
preflight-busy-wait = Başka bir Atlas penceresi kurulum başlatıyor. Biraz bekleyin, ardından yeniden deneyin.
# Beside home-start-over.
preflight-taken-over-start-over = Başka bir Atlas penceresi artık bu kurulumu kullanıyor. Orada devam edin veya burada baştan başlayın.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas önceki bir kurulumun hâlâ sürüp sürmediğini denetleyemedi, bu yüzden yeni bir kurulum başlatmadı.
preflight-not-started = Atlas yükleyiciyi başlatamadı, bu yüzden kurulum hiçbir değişiklik yapmadı. Yeniden deneyebilirsiniz.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas yükleyiciyi başlatamadı, ancak önceki bir deneme zaten değişiklik yaptı. Yeniden deneyebilirsiniz.
go-to-ready = Hazırlık adımına git
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Seçimleriniz adımına git
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Windows Güvenliği adımına git
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Kurulum adımına dön
output-problem-title = Kurulum ilerlemesi okunamadı
install-elevate-title = Atlas'ın kurulum için izne ihtiyacı var
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Atlas yeniden açıldığında Windows izninizi ister.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Atlas paketi hazır değil
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Önce Hazırlık adımını tamamlayın
install-not-ready-message = Atlas'ın kuruluma başlayabilmesi için önce bilgisayarınızı denetlemeyi ve Windows'u güncelleştirmeyi bitirmesi gerekiyor.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 tanesi hâlâ açık".
install-switches-title = Koruma anahtarlarını yeniden kapatın
install-switches-message = Windows Güvenliği: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Kuruluma hazır
summary-setup-title = Atlas kurulumunuz
summary-activation = Etkinleştirme
summary-activation-ok = Etkin. Atlas bunu değiştirmez.
summary-activation-missing = Etkin değil. Devam edebilirsiniz, ancak Atlas Windows'u etkinleştirmez.
summary-activation-unknown = Atlas Windows etkinleştirme durumunuzu değiştirmez.
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınız yeniden başlar
       *[other] Genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınız yeniden başlar
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınızı yeniden başlatın
       *[other] Genellikle yaklaşık { $minutes } dakika sürer, ardından bilgisayarınızı yeniden başlatın
    }
# The check box on the card. It's the same setting as settings-restart-automatically.
summary-restart-automatically = Kurulum bittiğinde otomatik olarak yeniden başlat
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Ayrıca kapatılanlar
summary-turned-off-value = Akıllı Uygulama Denetimi, Gelişmiş Kimlik Avı Koruması ve Cihazımı bul
summary-show-command = Kurulum komutunu göster
summary-hide-command = Kurulum komutunu gizle
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Kurulum komutunu kopyala
summary-command-unavailable = Kurulum komutu hazırlanamadı. Ayrıntılar: { $error }
summary-not-chosen = Henüz seçim yapılmadı
# Accessible name of a Change link. $title is a screen-*-name message.
summary-change-a11y = Değiştir: { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = Güncelleştirme yöntemi
# Why Continue waits on Get ready: read with it as its description. 8 words or fewer.
footer-still-checking = Kuruluma hazırlanıyor
footer-checks-blocked = Devam etmek için denetimlerin bulduğu sorunları giderin
footer-manager-outdated = Devam etmek için daha yeni bir Atlas Manager indirin
footer-need-files = Devam etmek için Atlas paketini edinin
# Tester build variant of footer-need-files.
footer-need-package-bundled = Devam etmek için birlikte gelen Atlas paketini hazırlayın
footer-drivers = Devam etmek için sürücülerin nasıl yükleneceğine karar verin
footer-windows-terms = Devam etmek için lisans koşullarını kabul edin
footer-updating = Windows ve Store uygulamaları güncelleştiriliyor…
footer-restart = Devam etmek için bilgisayarınızı yeniden başlatın
footer-reading-security = Koruma anahtarları denetleniyor
# Why Continue waits on Windows Security: while a switch is on, then while only switches
# Atlas couldn't read are left to confirm.
footer-security-pending = Devam etmek için dört anahtarı da kapatın
footer-security-confirm = Devam etmek için Atlas'ın okuyamadığı anahtarları onaylayın
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = Önce çalışmanızı kaydedip uygulamalarınızı kapatın
button-install = Atlas'ı kur
log-earlier-lines =
    { $count ->
        [one] Önceki { $count } satır günlük dosyasında.
       *[other] Önceki { $count } satır günlük dosyasında.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (günlüğün tamamı: { $path })

## The installing view

installing-title = Atlas kuruluyor
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis.
installing-checking-label = Bilgisayarınız denetleniyor…
installing-staging-label = Atlas'ın dosyaları kopyalanıyor…
installing-applying-label = Windows ayarlanıyor…
installing-finishing-label = Tamamlanıyor…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Bilgisayarınızı açık ve fişe takılı tutun. Kurulum bittiğinde kendiliğinden yeniden başlar.
installing-keep-on = Bilgisayarınızı açık ve fişe takılı tutun. Kurulum bittiğinde yeniden başlatın.
# When Atlas can't follow the installer's log. Its title is output-problem-title; its button
# is common-open-log-folder.
installing-output-problem = Bu, kurulumun durduğu anlamına gelmez.
installing-installed-title = Atlas kuruldu
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown =
    { $seconds ->
        [one] Bilgisayarınız { $seconds } saniye içinde yeniden başlayacak.
       *[other] Bilgisayarınız { $seconds } saniye içinde yeniden başlayacak.
    }
installing-restart-save = Önce çalışmanızı kaydedin.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } kuruldu
installed-title = Atlas kuruldu
installed-ready = Her şey tamam. Bilgisayarınız Atlas ile kullanıma hazır.
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = Yonga seti, ağ ve grafik sürücülerini bilgisayar, anakart veya cihaz üreticinizden edinin.
installed-drivers-guide = Sürücü kılavuzunu aç
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender kaldırıldı
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas onu kaldırmadı. Başka bir virüsten koruma uygulaması kullanmıyorsanız bilgisayarınızı korumak için bir tane yükleyin.
# When Atlas's record kept Microsoft Defender but Atlas's own package still removes it. Its button
# is home-reinstall. 7. Security, Defender and Toggle Defender are folder and file names in the
# Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender hâlâ kaldırılmış durumda
defender-not-restored-message = Önceki bir Atlas güncelleştirmesi onu geri getirmedi, bu yüzden Defender bilgisayarınızı korumuyor. Atlas'ı yeniden kurup Defender'ı tutun veya Atlas klasöründe 7. Security > Defender konumundaki Toggle Defender dosyasını çalıştırın.
# When what the installation recorded for some choices isn't what was chosen.
installed-not-applied-title = Bazı seçimler uygulanmadı
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender ve işlemci korumaları", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [one] Şu seçim olduğu gibi kaldı: { $choices }.
       *[other] Şu seçimler olduğu gibi kaldı: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Seçtiğiniz gibi Windows Update yeniden kapatıldı
installed-update-off-message = Kapalıyken bilgisayarınız güvenlik güncelleştirmesi almaz.
installed-update-paused-title = Seçtiğiniz gibi Windows güncelleştirmeleri yeniden duraklatıldı
installed-update-paused-message = Duraklatılmışken bilgisayarınız güvenlik güncelleştirmesi almaz.

## Settings

settings-title = Ayarlar
# Headings of the page's sections, over their cards.
settings-appearance = Görünüm
settings-installation = Kurulum
settings-privacy = Gizlilik
settings-theme = Uygulama teması
settings-theme-system = Windows ile aynı
settings-theme-light = Açık
settings-theme-dark = Koyu
settings-theme-contrast-note = Atlas, Windows kontrast temanızın renklerini kullanıyor.
settings-language = Dil
# The setting in the Language section, and its box's name.
settings-app-language = Uygulama dili
# The first choice in the language box. $language is that language's own name, for example "Türkçe".
settings-language-match-windows = Windows ile aynı – { $language }

# A short tag after each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Önizleme
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = Bu çeviri henüz ana dili Türkçe olan biri tarafından incelenmedi.
# A bar at the top of the content while a preview translation is in use. $language is the
# language's own name.
preview-notice = { $language } çevirisi bir önizlemedir ve hatalar içerebilir.
preview-notice-switch = İngilizceye geç
preview-notice-language = Dili değiştir
# Under the language box when the language chosen isn't in this version.
settings-language-chosen-unavailable = Seçtiğiniz dil bu Atlas sürümünde yok, bu yüzden Atlas İngilizce gösteriyor. Seçiminiz korunur.
# While Match Windows is chosen and Atlas has none of the Windows display languages.
settings-language-windows-unsupported = Atlas, Windows görüntüleme dilinizi henüz desteklemiyor, bu yüzden İngilizce gösteriyor.
# While Match Windows is chosen and the Windows display languages couldn't be read.
settings-language-windows-unreadable = Atlas, Windows görüntüleme dilinizi denetleyemedi, bu yüzden İngilizce gösteriyor.
# $locale is the regional format's own name, for example "Türkçe (Türkiye)".
settings-language-formats = Sayılar, tarihler ve saatler Windows bölgesel biçiminizi izler: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Sayılar Windows bölgesel biçiminizi izler: { $locale }. Atlas sağdan sola yazılan metni henüz gösteremediği için tarihler ve saatler standart bir biçimde gösterilir.
settings-language-contribute = Atlas'ın çevirisine GitHub'da katkıda bulun
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Kullanım verilerini Atlas ile paylaş
settings-share-usage-description = Açtığınız sayfalar, ISO oluşturma işlemleri ve kurulumların başarılı olup olmadığı.
settings-privacy-policy = Gizlilik ilkesi
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = Kurulum ve güncelleştirmeden sonra otomatik olarak yeniden başlat
settings-restart-automatically-description = Atlas işini bitirdikten sonra bilgisayarınız bir dakika içinde yeniden başlar ve açık uygulamalar kapanır.
settings-restart-locked = Bunu kurulum bittikten sonra değiştirebilirsiniz.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Yardım
settings-about = Hakkında
settings-about-app = Atlas Manager
settings-about-licence = Lisans
settings-about-licence-value = GPL-3.0, ücretsiz ve açık kaynak
settings-view-source = Kaynak kodunu GitHub'da görüntüle
# Link that opens the third-party licence notices.
settings-view-licences = Lisans bildirimlerini görüntüle
# Under the links when Windows could not open the notices.
settings-licences-failed = Lisans bildirimleri açılamadı. Yeniden deneyin veya bildirimleri GitHub'daki kaynak kodunda bulun.
settings-open-data-folder = Uygulama klasörünü aç

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Hazırda bekletme sırasında oturumunuzu kaydetmek için kullanılan disk alanını boşaltır. Hazırda bekletme ve Hızlı Başlatma kullanılamaz hâle gelir.
consequence-disable-power-saving = Güç tasarrufu özelliklerini kapatır. Bilgisayarınız daha fazla güç tüketebilir, daha çok ısınabilir ve pil ömrü kısalabilir.
consequence-disable-core-isolation = Bellek bütünlüğü dahil ek bir Windows güvenlik katmanını kapatır. Bu, korumayı azaltır; Riot Vanguard veya FACEIT gibi hile önleme sistemlerini kullanan oyunlar, bellek bütünlüğünü yeniden açana kadar başlamayabilir.
consequence-remove-snipping-tool = Ekran görüntüsü ve ekran kaydı almak için kullanılan Windows uygulamasını kaldırır.
consequence-uninstall-edge = Microsoft Edge tarayıcısını kaldırır. Başka bir tarayıcınız olduğundan emin olun veya aşağıdan birini seçin.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Bu bilgisayardaki Edge yer işaretlerinizi, geçmişinizi ve kayıtlı parolalarınızı siler.
consequence-install-another-browser = Aşağıdan bir tarayıcı seçin; Atlas onu sizin için yükler.
consequence-install-toolbox = Atlas ayarlarınızı yönetmenize yardımcı olması için Atlas Toolbox'ı ekleyin. Toolbox beta aşamasında olduğu için bazı özellikler henüz tamamlanmamış olabilir.
consequence-install-eclean = Kurulumdan sonra bilgisayarınızı düzenli tutmak için AtlasOS ekibinden bir bakım aracı. Gereksiz dosyaları ve başlangıç uygulamalarını inceleyin. Hesap ve internet bağlantısı gerektirir.

## ISO creation
iso-open = Atlas ISO'su oluştur
iso-title = Atlas ISO'su oluştur
iso-recommended = Önerilen
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO. "Yapılandırma" keeps the second apart from the
# install flow's Kurulum step and from Windows Kurulumu.
iso-step-source = Windows
iso-step-setup = Yapılandırma
iso-step-create = Oluşturma
# The first question on the Windows step. It sets the defaults that follow.
iso-target-title = Bu ISO hangi bilgisayar için?
iso-target-this = Bu bilgisayar
iso-target-another = Başka bir bilgisayar
# Under the question when the ISO is for another kind of processor than this PC's.
# $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = Bu ISO, { $architecture } bilgisayarlar içindir.
iso-source = Windows ISO'su
# Starts the Windows 11 download at once, in the language and architecture of iso-download-caption.
iso-download-windows = Microsoft'tan indir
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "Turkish"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download for the accessible name of its Change link.
iso-download-what = Windows indirmesi
iso-download-language = Dil
iso-download-arch = Mimari
iso-download-languages = Diller yükleniyor…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2,4 GB" (size-gigabytes).
iso-downloading = Windows 11 indiriliyor…
iso-download-amount = { $received } / { $total }
# Microsoft's download service couldn't be reached, or the download stopped part-way.
# Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas, Microsoft'un indirme hizmetine ulaşamadı. İnternet bağlantınızı denetleyin, ardından yeniden deneyin.
iso-download-incomplete = İndirme tamamlanmadı. İnternet bağlantınızı ve boş alanı denetleyin, ardından yeniden deneyin.
iso-download-website = Microsoft'un indirme sayfasını aç
# Opens the file picker for a Windows ISO, and is that picker's Open button.
iso-use-local = ISO dosyası seç
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Windows ISO'nuz denetleniyor…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6,6 GB".
iso-checked-a11y = Windows ISO'su hazır, { $facts }
iso-package-latest-label = En güncel
# The latest Atlas release is older than this Atlas Manager can use; package-open-file is under it.
iso-package-release-old = En son Atlas sürümü, bu Atlas Manager'ın kullanabileceğinden daha eski.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = En son Atlas sürümü alınıyor…
# The release check failed; Try again is beside it.
iso-package-release-failed = Atlas en son sürümü denetleyemedi. İnternet bağlantınızı denetleyin, ardından yeniden deneyin.
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Devam etmek için bir Windows ISO'su edinin
# The question on the Setup step about when the package's choices are made.
iso-mode-question = Atlas seçimlerinizi ne zaman yapmak istersiniz?
iso-mode-after = Oturum açtıktan sonra
iso-mode-after-description = Oturum açtıktan sonra Atlas kurulumda size yol gösterir.
iso-mode-now = Şimdi
iso-mode-now-description = Seçimler ISO'ya kaydedilir. Atlas'ı oturum açtıktan sonra kurarsınız.
# A check box under Now.
iso-mode-before-desktop = Masaüstü açılmadan önce tamamla
iso-mode-before-desktop-description = Oturum açtığınızda Atlas, kurulum bitene kadar tam ekran çalışır.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = Bu Atlas paketi seçimleri ISO'ya kaydedemez, bu yüzden seçimlerinizi oturum açtıktan sonra yaparsınız.
iso-atlas-options = Atlas seçimleri
# The line at the top of the Create step.
iso-create-intro = ISO oluşturmak bu bilgisayarı veya orijinal ISO'nuzu değiştirmez.
iso-review-package = Atlas paketi
iso-review-output = Yeni ISO
iso-review-edition = Sürüm
iso-review-editions = Sürümler
iso-edition = Windows sürümü
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Windows Kurulumu sorar
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Windows Kurulumu sorsun
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Windows lisans koşullarını kabul et, böylece Windows Kurulumu sormaz
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Hesap adı
iso-review-target = Yükleme hedefi
iso-review-drivers = Sürücüler
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows Kurulumu
iso-review-skips = Microsoft hesabı ve gizlilik ekranlarını atlar
iso-review-skips-terms = Lisans, Microsoft hesabı ve gizlilik ekranlarını atlar
iso-review-network = Ağ sürücüleri
iso-review-network-included = Bu bilgisayarın Wi-Fi ve Ethernet sürücüleri
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Şimdi; masaüstü açılmadan önce tamamlanır
# Under the new ISO on the Create step. $needed and $free are sizes such as "35,0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = { $needed } gerekli · { $drive } sürücüsünde { $free } boş
iso-destination-short = ISO için { $needed } gerekiyor, { $drive } sürücüsünde ise { $free } boş alan var. Alan boşaltın veya ISO'yu başka bir sürücüye kaydedin.
iso-destination-filesystem = { $drive } sürücüsü ISO'nun büyük dosyalarını barındıramaz. ISO'yu Windows sürücünüz gibi NTFS biçimli bir sürücüye kaydedin.
iso-destination-unusable = Atlas, ISO'yu yalnızca bu bilgisayardaki bir sürücüde bulunan bir klasöre kaydedebilir.
iso-create = ISO oluştur
# Heading above the progress bar and the list of stages while the ISO is being created.
iso-progress-title = ISO'nuz oluşturuluyor…
# The progress bar's label: the stage under way. $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Windows ISO'su okunuyor
iso-stage-copy = Windows dosyaları kopyalanıyor
iso-stage-add-atlas = Atlas ekleniyor
iso-stage-master = ISO dosyası yazılıyor
iso-stage-verify = Yeni ISO denetleniyor
iso-stage-cleanup = Tamamlanıyor
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = devam ediyor
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = başarısız oldu
iso-stage-status-not-started = henüz başlamadı
iso-progress-keep-open = Bitene kadar Atlas'ı açık tutun.
iso-cancel = Oluşturmayı iptal et
iso-cancelling = İptal için güvenli bir durma noktası bekleniyor
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = İptal ediliyor…
iso-cancelled = ISO oluşturma iptal edildi
iso-cancelled-unchanged = Orijinal ISO'nuz değiştirilmedi.
iso-complete = ISO'nuz hazır
iso-complete-backup = Windows'u bu ISO'dan yeniden yüklemeden önce dosyalarınızı yedekleyin.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = USB sürücüsü oluştur
iso-open-folder = Klasörde göster
iso-failed = ISO oluşturma tamamlanamadı
# Under iso-failed, beside Try again.
iso-failed-retry = Dosyalarınızın hâlâ seçtiğiniz yerde olduğundan ve kaydettiğiniz sürücünün bağlı olduğundan emin olun, ardından yeniden deneyin.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Dosyalar denetlenemedi
iso-check-failed-retry = ISO'nun ve Atlas paketinin indirilmesinin bittiğinden emin olun, ardından yeniden deneyin.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas çalışma klasörünü hazırlayamadı, bu yüzden hiçbir şey değişmedi.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix.
iso-edition-unsupported-title = Bu ISO'da Atlas'ın desteklediği bir sürüm yok
iso-edition-unsupported = Windows Home ve LTSC desteklenmez. Pro, Education veya Enterprise içeren bir ISO kullanın.
iso-customised-title = Bu ISO özelleştirilmiş
iso-customised = autounattend.xml gibi kurulum dosyaları zaten içeriyor. Microsoft'tan alınmış, değiştirilmemiş bir ISO kullanın.
iso-preview-title = Bu ISO bir önizleme derlemesi
iso-preview = Windows derlemesi, Microsoft'un genel kullanıma sunulan sürümler listesinde yok. Microsoft'tan alınmış bir ISO kullanın.
iso-windows-unsupported-title = Bu Atlas paketi bu ISO'yu kullanamaz
iso-windows-unsupported = Paketin desteklediği bir sürüme ait, değiştirilmemiş bir Windows 11 ISO'su kullanın.
iso-release-unknown-title = Atlas bu Windows sürümünü doğrulayamadı
iso-release-unconfirmed = Atlas bunu Microsoft'un genel kullanıma sunulan sürümler listesiyle karşılaştırır. İnternet bağlantınızı denetleyin, ardından yeniden deneyin.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = Bu Atlas paketiyle ISO oluşturulamaz
iso-package-old = Atlas { $minimum } veya daha yeni bir sürüm kullanın.
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = Bu bir Windows ISO'su, Atlas paketi değil
iso-package-windows-iso = Bunun yerine bir Atlas paketi (.atlaspkg) seçin ve bu ISO'yu Windows ISO'su olarak seçin.
iso-manager-missing-title = Atlas Manager dosyası eksik
iso-fix-package = Başka bir paket seç
# A package that needs a newer Atlas Manager; manager-download is beside it.
iso-manager-outdated-title = Daha yeni bir Atlas Manager gerekiyor
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas bu bilgisayarın ağ sürücülerini ISO'ya ekleyemedi.
iso-network-skip = Bunlar olmadan oluştur
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas'ın ISO oluşturmak için izne ihtiyacı var
iso-admin-reason = Windows ISO'nuzu okumak ve yenisini oluşturmak için gereklidir.
iso-elevation-declined = Windows, Atlas'a izin vermedi, bu yüzden Atlas Windows ISO'nuzu henüz okuyamıyor.
# The free space ran out while the ISO was being created.
iso-failed-space = Hedef sürücüde yeterli boş alan yok. Alan boşaltın veya yeni ISO'yu başka bir sürücüye kaydedin.
# Under iso-manager-missing-title.
iso-manager-missing = AtlasManager.exe dosyasını İndirilenler gibi yerel bir klasöre indirin, ardından oradan açın.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Bu ISO desteklenen bir Windows sürümü içermiyor. Windows Home ve LTSC desteklenmez. Pro, Education veya Enterprise gibi başka bir sürüm içeren bir ISO kullanın.
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows ISO'yu açamadı. Bilgisayarınızı yeniden başlatın, ardından yeniden deneyin.
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = Windows, ISO'yu açarken yanıt vermeyi durdurdu. Bilgisayarınızı yeniden başlatın, ardından yeniden deneyin.
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = Windows bu bilgisayarda ISO dosyalarını açamıyor, çünkü bunun için kullandığı vdrvroot ve cdrom sürücüleri devre dışı. Bu sürücüleri yeniden etkinleştirin, bilgisayarınızı yeniden başlatın ve yeniden deneyin.
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows bu ISO'yu açamıyor, çünkü dosya sıkıştırılmış, şifrelenmiş veya seyrek bir dosya. Dosyayı sıkıştırılmamış ve şifrelenmemiş bir klasöre kopyalayın, ardından kopyayı kullanın.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Günlük klasörünü aç
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas şu anda Windows Update ile meşgul. Bu iş bittiğinde buradan devam edebilirsiniz.
# Names of the markers Windows sets when it wants a restart. They complete
# "Güncelleştirmelerin yüklenmesini tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor (…)";
# keep them short and lower case where the language allows.
prepare-reason-servicing = Windows bileşen bakımı
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = değiştirilmeyi bekleyen dosyalar
prepare-reason-update-agent = Windows Update hizmeti
prepare-reason-unknown = neden bildirilmedi
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = Yeniden denemek işe yaramazsa kalan güncelleştirmeleri Windows Update'te veya Microsoft Store'da tamamlayın.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Bazı güncelleştirmeler tamamlanamadı
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Güncelleştirme bir sonuç bildirmeden durdu.
# Not called a failure, as none was reported.
prepare-unconfirmed-title = Güncelleştirme sonucu doğrulanamadı
# The value of $app in prepare-close-app when Windows doesn't name the app. It starts that
# sentence, so it has a capital.
prepare-affected-app = Etkilenen uygulama
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app; it starts the sentence so that it needs no suffix.
prepare-close-app = { $app } açıkken güncelleştirilemez. Kapatıp yeniden deneyin; bulamazsanız Görev Yöneticisi'nden kapatın.
prepare-install-busy = Başka bir kurulum veya gerekli bir yeniden başlatma güncelleştirmeleri engelliyor. Diğer kurulumların bitmesini bekleyin, Windows isterse bilgisayarınızı yeniden başlatın, ardından yeniden deneyin.
# Updates failed after Atlas's own repair of the component store (DISM). The button is
# prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows kendini onaramadı
prepare-components-damaged = Windows, güncelleştirmelerin yüklenmesini engelleyen bir hasar bildiriyor. Yeniden başlatmak bunu giderebilir; Atlas, oturum açtığınızda devam eder.
prepare-restart-and-retry = Yeniden başlat ve tekrar dene
# Windows records damage to its component store that it can't repair. The one button is iso-open.
prepare-components-unrepairable-title = Windows güncelleştirilemeyecek kadar hasarlı
prepare-components-unrepairable = Dosyalarınızı yedekleyin, ardından Windows'u bir Atlas ISO'suyla yeniden yükleyin.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas, Windows'ta oturum açmış hesaptan farklı bir hesapla çalışıyor. Windows'ta bir yönetici hesabıyla oturum açın, Atlas'ı o hesaptan açın ve yeniden deneyin.
prepare-failed-store-missing = Microsoft Store hesabınız için ayarlanmamış. Microsoft Store'u bir kez açın veya eksikse yeniden yükleyin, ardından yeniden deneyin.
prepare-failed-store-battery = Microsoft Store, pil tasarrufu için güncelleştirmeleri duraklattı. Bilgisayarınızı fişe takın, ardından yeniden deneyin.
prepare-failed-store-network = Microsoft Store, bilgisayarınız tarifeli olmayan bir bağlantı kullanana kadar güncelleştirmeleri duraklattı. Tarifeli olmayan bir Wi-Fi veya Ethernet ağına bağlanın, ardından yeniden deneyin.
prepare-failed-store-timeout = Store uygulamalarının güncelleştirilmesi tamamlanmadı. Kalan indirmeleri Microsoft Store'da tamamlayın, ardından yeniden deneyin.
prepare-failed-store-passes = Microsoft Store yeni güncelleştirmeler sunmaya devam etti. Kalan güncelleştirmeleri Microsoft Store'da tamamlayın, ardından yeniden deneyin.
prepare-failed-manual-updates = Bazı Windows güncelleştirmelerinin Windows Update'te tamamlanması gerekiyor. Windows Update'i açıp bunları tamamlayın, ardından yeniden deneyin.
prepare-failed-windows-passes = Windows Update yeni güncelleştirmeler sunmaya devam etti. Kalan güncelleştirmeleri Windows Update'te tamamlayın, ardından yeniden deneyin.
prepare-failed-windows-update-unreachable = Windows Update, Microsoft'un sunucularına ulaşamadı. İnternet bağlantınızı ve varsa güvenlik duvarını, ara sunucuyu veya VPN'i denetleyin, ardından yeniden deneyin.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic link).
prepare-failed-source-linked = Atlas Manager bağlantılı bir klasörde. Atlas'ı kapatın, Atlas Manager'ı bu bilgisayardaki yerel bir klasöre taşıyın, ardından oradan açın.
prepare-error-code = Hata kodu: { $code }
prepare-open-store = Microsoft Store'u aç
prepare-windows-search = Windows güncelleştirmeleri denetleniyor…
prepare-percent = Bu aşamanın %{ $percent } kadarı
prepare-count = Tamamlanan güncelleştirmeler: { $completed } / { $total }
prepare-bytes = Yaklaşık { $total } MB verinin { $downloaded } MB kadarı indirildi
prepare-progress-still = { $minutes } dk boyunca ilerleme olmadı. Büyük güncelleştirmeler zaman alabilir, bu yüzden Atlas'ı açık tutun.
prepare-report-late = Windows bir süredir ilerleme bildirmedi. Güncelleştirmeler hâlâ sürüyor olabilir, bu yüzden Atlas'ı açık tutun.
prepare-windows-download = Windows güncelleştirmeleri indiriliyor…
prepare-windows-install = Windows güncelleştirmeleri yükleniyor…
# While DISM repairs Windows' component store, with prepare-windows-repair-detail under the
# progress bar. DISM reports no progress.
prepare-windows-repairing = Windows onarılıyor…
prepare-windows-repair-detail = Windows, güncelleştirmelerin yüklenmesini engelleyebilecek bir hasar bildiriyor. Bu yarım saat veya daha uzun sürebilir.
prepare-store-search = Microsoft Store denetleniyor…
prepare-store-install = Microsoft Store ve uygulamaları güncelleştiriliyor…
prepare-stop = Güncelleştirmeyi durdur
prepare-start = Güncelleştirmeleri denetle ve yükle
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Atlas paketi hazır olduğunda kullanılabilir.
iso-username = Yerel hesap adı
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = Parolanızı ilk oturum açışınızda belirleyeceksiniz.
iso-username-placeholder = Adınız
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Devam etmek için bir yerel hesap adı girin
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = En fazla 20 karakter kullanın. Başta veya sonda boşluk olmamalı ve şunların hiçbiri bulunmamalı: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Ad nokta ile bitemez.
iso-account-reserved = Windows bu adı yerleşik bir hesap için kullanıyor. Başka bir ad seçin.
iso-terms-in-setup = Windows Kurulumu lisans koşullarını kabul etmenizi isteyecek.
prepare-drivers = Sürücüler nasıl yüklensin?
prepare-drivers-auto = Sürücüleri Windows Update'ten al
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Sürücüleri Windows Update'ten al (önerilir)
prepare-drivers-auto-detail = Windows, donanımınız için sürücüleri bulur.
prepare-drivers-manual = Sürücüleri kendim yükleyeceğim
prepare-drivers-manual-detail = Windows Update sürücü yüklemez; bu yüzden sürücüleri bilgisayarınızın veya cihazınızın üreticisinden edinmeniz gerekir. Yüklü sürücüler korunur.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Sürücüler
iso-network-drivers = Bu bilgisayarın Wi-Fi ve Ethernet sürücülerini ekle
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Oturum açtıktan sonra seç
prepare-network-unmetered = Güncelleştirmeler için tarifeli olmayan bir internet bağlantısı gerekiyor. Wi-Fi'ye veya Ethernet'e bağlanın, ardından yeniden deneyin.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows, bu ağın internet erişimi olmadığını bildiriyor. Ağ sizden oturum açmanızı isterse oturum açın veya yönlendiricinizi ve varsa DNS ya da güvenlik duvarı filtrelemesini denetleyin, ardından yeniden deneyin.
# "Tarifeli bağlantı" is the switch's name in Windows network settings.
prepare-network-metered = Bu bağlantı tarifeli veya bir veri sınırına sahip. Tarifeli olmayan bir ağa bağlanın veya ağ ayarlarında Tarifeli bağlantı seçeneğini kapatın, ardından yeniden deneyin.
prepare-network-settings = Ağ ayarlarını aç
iso-stage-network-drivers = Ağ sürücüleri hazırlanıyor
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Bu bilgisayarın ağ bağdaştırıcıları Windows ile birlikte gelen sürücüleri kullanıyor, bu yüzden ISO'nun bunları içermesi gerekmiyor.
desktop-setup-description = Bilgisayarınızın kurulumunu tamamlayın. Atlas seçimleriniz kaydedildi; gerekirse Windows'a dönebilirsiniz.
desktop-setup-exit = Windows'ta devam et

# Windows installation USB
usb-title = USB sürücüsü oluştur
usb-existing = Mevcut bir ISO'dan USB sürücüsü oluştur
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB sürücüsü
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows ISO'su
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = İndirilenler klasörünüzde Atlas ISO'su yok.
usb-iso-checking = ISO denetleniyor…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas bu ISO'dan USB sürücüsü oluşturamaz. Atlas ile oluşturulmuş bir ISO veya Microsoft'tan alınmış, Atlas'ın desteklediği bir sürüme ait Windows 11 ISO'su kullanın.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO veya Atlas Manager bir ağ konumunda ya da bağlantılı bir klasörde. Dosyayı İndirilenler gibi bu bilgisayardaki bir klasöre taşıyın.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = Windows sürücüsünde bu ISO'yu hazırlamak için yeterli boş alan yok. Biraz alan boşaltın, Atlas kendiliğinden yeniden denetler.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas bu ISO'yu okuyamadı. Yeniden deneyin veya başka bir ISO kullanın.
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = Depolama ayarlarını aç
usb-looking = USB sürücüleri aranıyor…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = { $size } GB veya daha büyük bir USB sürücüsü bağlayın.
# Under a drive that can't be used, after its size and letters: why.
usb-drive-too-small-needs = Çok küçük. En az { $size } GB olmalı.
usb-drive-too-small-iso = Bu ISO için çok küçük
usb-drive-has-iso = ISO'nuz bu sürücüde
usb-drive-has-app = Atlas Manager bu sürücüden çalışıyor
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = USB sürücüsü oluştur
# Beside the unavailable usb-create while several drives are listed and none is picked.
usb-hint-pick = Önce bir USB sürücüsü seçin
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:".
usb-confirm-title-letters = { $drive } ({ $size }, { $letters }) silinsin mi?
usb-confirm-title = { $drive } ({ $size }) silinsin mi?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = USB sürücüsü ({ $size }, { $letters }) silinsin mi?
usb-confirm-title-unnamed = USB sürücüsü ({ $size }) silinsin mi?
usb-confirm-message = Sürücüdeki her şey silinecek. ISO'nuz korunur.
usb-confirm-erase = Sil ve oluştur
usb-progress-title = USB sürücüsü oluşturuluyor…
# $percent is a whole number.
usb-percent = %{ $percent }
# The stages of creating the USB drive, as a checklist under usb-progress-title.
usb-stage-prepare-files = Dosyalar hazırlanıyor
usb-stage-formatting = Biçimlendiriliyor
usb-stage-copying = Dosyalar kopyalanıyor
usb-stage-checking = Sürücü denetleniyor
usb-stage-ejecting = Çıkarılıyor
usb-keep-open = Atlas'ı açık ve sürücüyü bağlı tutun.
usb-scan-failed-title = USB sürücüleri listelenemedi
usb-scan-failed-retry = Atlas bu bilgisayara bağlı sürücüleri okuyamadı. Yeniden deneyin.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = USB sürücüsü oluşturulamadı
usb-complete-title = USB sürücünüz hazır
# F12, F11 and Esc are key names.
usb-ready = Sürücüyü çıkarın, yeniden yükleyeceğiniz bilgisayarı yedekleyin ve o bilgisayarı USB sürücüsünden başlatın. Önyükleme menüsü genellikle F12, F11 veya Esc ile açılır.
# After erasing may have begun.
usb-failed-partial = Sürücüye kısmen yazıldı. Bağlı olduğundan emin olun, ardından yeniden deneyin.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas sürücüyü değiştirmeden önce durdu. Yeniden deneyin.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
usb-drive-changed-title = USB sürücüsü değişti
usb-drive-changed = Atlas silmeden önce sürücü çıkarıldı veya yeniden bağlandı, bu yüzden üzerinde hiçbir şey değişmedi.
usb-drive-cancelled-title = USB sürücüsü oluşturma iptal edildi
usb-cancelled-partial = Sürücü tamamlanmadı. Kullanmadan önce yeniden oluşturun.
usb-cancelled-unchanged = USB sürücünüz değiştirilmedi.
usb-eject-failed-title = USB sürücüsü çıkarılamadı
usb-eject-failed-ready = Sürücü kullanıma hazır. Sürücüyü kullanan dosyaları veya pencereleri kapatın, ardından yeniden deneyin.
# Title of the bar with common-restart-as-administrator. Its message is usb-admin-reason, or
# usb-elevation-declined after Windows refused the relaunch (UAC declined).
usb-elevation-title = Atlas'ın USB sürücüsü oluşturmak için izne ihtiyacı var
usb-admin-reason = Atlas'ın sürücüyü silip yazabilmesi için yönetici izni gerekiyor.
usb-elevation-declined = Windows, Atlas'a izin vermedi, bu yüzden Atlas USB sürücüsüne henüz yazamıyor.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 Home, LTSC ve Server sürümleri desteklenmez. Pro, Education veya Enterprise gibi başka bir sürüm kullanın. Windows sürümünüzü belirleyemediyse devam etmeden önce bu sorunu çözün.
install-source-title = Kurulum kullanılamıyor
install-source-unsupported = Atlas { $source }, doğrudan { $target } sürümüne güncelleştirilemez. Bu sürümü kullanmak için dosyalarınızı yedekleyin ve Windows'u yeniden yükleyin.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } doğrudan güncelleştirilemez. Daha yeni bir sürümü kullanmak için dosyalarınızı yedekleyin ve Windows'u yeniden yükleyin.
# $folder is a folder path (text).
install-source-resume-package = Atlas { $target } kurulumu tamamlanmadı ve bu kurulumu yalnızca Atlas { $target } paketi tamamlayabilir. O Atlas paketini (.atlaspkg) açın. Dosyayı Atlas indirdiyse { $folder } klasöründedir.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } kurulumu yarım kaldı. Bu test sürümü yalnızca birlikte gelen Atlas paketini kurabilir, bu yüzden bu kurulumu Atlas Manager'ın bir yayın sürümünde Atlas { $target } paketiyle tamamlayın.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas bu bilgisayarda neyin kurulu olduğunu doğrulayamadı, bu yüzden şimdilik hiçbir şey kurmayacak.
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = Bu bilgisayarda önceki bir Atlas sürümünün dosyaları var, ancak tamamlanmış bir kurulum kaydı yok, bu yüzden güncelleştirilemez. Atlas'ı kurmak için dosyalarınızı yedekleyin ve Windows'u yeniden yükleyin.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Windows Kurulumu'nda lisansınızın bulunduğu bir sürümü seçin.
detail-windows-preview = Insider derlemeleri desteklenmiyor. Windows 11'in genel kullanıma sunulan bir sürümünü kullanın.
detail-windows-release-unknown = Atlas, bu Windows derlemesinin genel kullanıma sunulduğunu doğrulayamadı. İnternete bağlanıp yeniden denetleyin.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = { $build } derlemesi, Microsoft'un genel kullanıma sunulan Windows 11 sürümleri listesinde yer almıyor, bu yüzden Atlas henüz bu derlemeye kurulamaz. Release Preview ve diğer önizleme derlemeleri desteklenmiyor. Microsoft bu derlemeyi listeye ekledikten sonra yeniden denetleyin.

prepare-continue = Güncelleştirmelere devam et
prepare-saving-restart = Seçimleriniz kaydediliyor ve Windows yeniden başlatıldıktan sonra Atlas'ın açılması ayarlanıyor…
prepare-restart-save-failed = Seçimleriniz kaydedilemedi. Yeniden başlatmadan önce tekrar deneyin.
prepare-restart-registration-failed = Seçimleriniz kaydedildi, ancak Atlas yeniden başlatmadan sonra kendini açılacak şekilde ayarlayamadı. Tekrar deneyin veya bilgisayarınızı kendiniz yeniden başlatıp oturum açtıktan sonra Atlas'ı açın.
# The same cause as prepare-failed-source-linked, met while arranging the restart.
prepare-restart-source-linked = Seçimleriniz kaydedildi, ancak Atlas Manager bağlantılı bir klasördeyken Atlas yeniden başlatmadan sonra kendini açılacak şekilde ayarlayamaz. Atlas'ı kapatın ve Atlas Manager'ı bu bilgisayardaki yerel bir klasöre taşıyın. Ardından oradan açın veya bilgisayarınızı kendiniz yeniden başlatıp oturum açtıktan sonra oradan açın.
prepare-restart-failed = Atlas bilgisayarınızı yeniden başlatamadı. Tekrar deneyin veya Başlat menüsünden yeniden başlatın. Seçimleriniz kaydedildi ve Atlas, oturum açtıktan sonra yeniden açılır.
diagnostics-export = Tanılama verilerini dışa aktar
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Tanılama verileri toplanıyor…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Yardım al
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Tanılama verileri kaydedildi
# Under diagnostics-saved. $file is the ZIP's name and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Atlas'ın { $folder } klasörüne { $file } adıyla kaydedildi.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas bu dosyadan kullanıcı adınızı, bilgisayar adınızı, e-posta adreslerini ve bilinen parolaları veya anahtarları kaldırdı.
# The bar when an export failed. Its button is common-try-again; its raw error is behind Show details.
diagnostics-save-failed = Tanılama ZIP dosyası kaydedilemedi

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } test sürümü. Bu uygulama yalnızca birlikte gelen Atlas paketini kurar.
home-status-bundled = Test sürümü { $release }
package-bundled = Bu test sürümüyle gelen Atlas { $version } kuruluma hazır.
rc-about-release = Test sürümü
rc-about-commit = Kaynak commit
rc-about-package = Birlikte gelen Atlas paketi (SHA-256)
iso-package-bundled = Bu test sürümüyle gelen Atlas paketi

check-user-account = Kullanıcı hesabı
detail-user-account-ok = UAC açık ve hesabınız kuruluma hazır.
detail-user-account-not-ready = Kullanıcı Hesabı Denetimi'ni (UAC) açın, bilgisayarınızı yeniden başlatın ve yeniden deneyin. Yerleşik Administrator hesabını kullanıyorsanız başka bir yönetici hesabıyla oturum açın.
detail-user-account-work-or-school = Atlas, iş veya okul hesabından (Microsoft Entra ID) kurulamaz. Yerel bir hesapla veya Microsoft hesabıyla oturum açın, ardından yeniden deneyin.
detail-user-account-check-failed = Atlas kullanıcı hesabınızı denetleyemedi. Bilgisayarınızı yeniden başlatın, ardından Atlas'ı yeniden açıp yeniden denetleyin. Windows bildirimi: { $error }

footer-prepare-required = Devam etmek için Windows ve Store uygulamalarını güncelleştirmeyi bitirin
# "Aşama" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Güncelleştirme geçerli aşamadan sonra durduruluyor…
resume-choices-title = Önceki kurulumunuza devam ediliyor
# The bar on Your choices, above the choices an unfinished installation holds.
resume-choices-held = Atlas, o kurulumu tamamlamak için geçen sefer yaptığınız seçimleri kullanır; bu yüzden kurulum bitene kadar bunlar değiştirilemez.

## Voluntary reports
report-title = Rapor gönder
report-received = Rapor alındı
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Bu rapor hakkında Atlas ekibiyle iletişime geçerseniz kullanmak için bu referansı saklayın. İletişim bilgisi bıraktıysanız ekip size yanıt vermek için bu bilgileri kullanabilir, ancak yanıt verileceği garanti edilmez.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Rapor referansını kopyala
report-another = Başka bir rapor gönder
# Label of the choice between the two kinds of report.
report-kind = Ne göndermek istiyorsunuz?
report-kind-issue = Bir sorun
report-kind-suggestion = Bir öneri
report-message = Mesajınız
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = Ne oldu ve o sırada ne yapıyordunuz?
report-message-placeholder-suggestion = Neyin değişmesini istersiniz?
# Under the message box, which also reads it out.
report-message-help = Mesajınıza parola yazmayın.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } / { $max } karakter
report-contact = İletişim bilgileri (isteğe bağlı)
report-contact-placeholder = E-posta veya Discord kullanıcı adı
report-attach = Tanılama verilerini ekle
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = Sorunun nedenini bulmaya yardımcı olan günlükler ve sistem ayrıntıları. Atlas kullanıcı adınızı, bilgisayar adınızı, e-posta adreslerini ve bilinen parolaları veya anahtarları kaldırır. Hata ayrıntıları, donanım modelleri ve uygulama adları kaldırılmaz. Göndermeden önce ZIP'i inceleyebilirsiniz.
report-review = ZIP'i incele
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = Tanılama verileri hazırlanamadı
report-prepare-failed-advice = Yeniden deneyin veya tanılama verileri olmadan gönderin.
# The privacy notice the user agrees to, with report-attach-description.
report-privacy = Raporunuz reports.atlasos.net üzerinden Atlas ekibine özel olarak gönderilir. Mesajınız ve iletişim bilgileriniz yazdığınız gibi gönderilir. Ekip, incelemeye yardımcı olması için başka şirketlerin yapay zekâ hizmetlerini kullanabilir. Bu hizmetler mesajınızı ve tanılama verilerini alır, ancak iletişim bilgilerinizi almaz. Raporlar 90 gün sonra silinir ve sunucu güvenlik günlükleri IP adresinizi kaydedebilir.
report-website = Gizlilik ve rapor sitesi
report-consent = Bu raporu ve varsa eklenen tanılama verilerini Atlas ekibine göndermeyi kabul ediyorum
# Under report-failed-title. The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website.
report-not-sent-retry = İnternet bağlantınızı denetleyin, ardından yeniden deneyin. Raporu rapor sitesinden de gönderebilirsiniz.
report-not-sent-busy = Rapor hizmeti meşgul. Birkaç dakika bekleyin, ardından yeniden deneyin.
report-not-sent-outdated = Atlas Manager'ın bu sürümü rapor gönderemez. Mesajınızı rapor sitesine kopyalayın; tanılama verilerini eklediyseniz ZIP'i de ekleyin.
report-not-sent-diagnostics = Tanılama verileri gönderilemedi. Yeniden deneyin veya tanılama verileri olmadan gönderin.
# The footer's button where this version can't send.
report-failed-website = Rapor sitesini aç
# Beside a spinner in the footer while the report is on its way.
report-sending = Gönderiliyor…
report-send = Rapor gönder

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = { $min }–{ $max } karakter girin.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = İletişim bilgilerini { $max } karakterle sınırlayın.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Bu raporu göndermeyi kabul ettiğinizi onaylayın.

report-failed-title = Rapor gönderilmedi

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# Turkish says "Windows 11, sürüm …" in titles and "Windows 11 … sürümü" in sentences.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Dosyalarınız ve uygulamalarınız korunur.
home-plan-name = Bu güncelleştirme iki bölümden oluşur
home-plan-windows-title = Windows 11, sürüm { $release }
home-plan-windows-step = Atlas bunu Windows Update'ten yükler, ardından bilgisayarınız yeniden başlar.
# The same step where moving is optional.
home-plan-windows-step-ask = İsteğe bağlı. Atlas önce sorar, ardından bunu Windows Update'ten yükler ve bilgisayarınız yeniden başlar.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Yüklendi.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas güncelleştirilir ve seçimleriniz korunur, ardından bilgisayarınız yeniden başlar.
# $date and $until are dates.
home-end-of-updates-title = Windows 11 { $current } sürümü için güvenlik güncelleştirmeleri { $date } tarihinde sona eriyor
home-end-of-updates-past-title = Windows 11 { $current } sürümü artık güvenlik güncelleştirmesi almıyor
home-end-of-updates-message = Atlas { $version } sürümüne güncelleştirmek bu bilgisayarı Windows 11 { $release } sürümüne de geçirir. Bu sürüm { $until } tarihine kadar güvenlik güncelleştirmeleri alır.
# Instead of home-end-of-updates-message when the card with the update's two parts is under the bar.
home-end-of-support-plan = Windows 11 { $release } sürümü { $until } tarihine kadar güvenlik güncelleştirmeleri alır.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır, bu yüzden { $product } üzerine kurulamaz.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır, bu yüzden { $product } üzerine kurulamaz. Windows 11 { $current } sürümü { $date } tarihine kadar güvenlik güncelleştirmeleri alır ve Windows Update bu bilgisayarı daha yeni bir sürüme geçirebilir.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır, bu yüzden { $product } üzerine kurulamaz. { $current } sürümü artık güvenlik güncelleştirmesi almıyor; Atlas'ı kurmasanız bile Windows'u güncelleştirin.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır. LTSC sürümleri desteklenmez.
# $releases lists the supported releases, such as "25H2 veya 26H2".
install-windows-reinstall = Atlas { $version } sürümü için Windows 11 { $releases } sürümü gerekiyor ve Windows Update bu bilgisayarı bu sürüme geçiremiyor. Dosyalarınızı yedekleyin, ardından Windows'u bir Atlas ISO'suyla yeniden yükleyin.
# The same on Home, where the card that creates an Atlas ISO comes first.
home-windows-no-path = Atlas { $version } sürümü için Windows 11 { $releases } sürümü gerekiyor ve Windows Update bu bilgisayarı bu sürüme geçiremiyor.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; home-continue-update is beside the version above.
home-update-access-title = Atlas güncelleştirmesi için Windows Update ayarları değiştirildi
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas bu ayarları güncelleştirme bittiğinde geri yükler.
# When the last check found no offer yet.
home-update-access-waiting = Atlas, bu bilgisayarı Windows 11 { $release } sürümüne geçirmek için Windows Update'i açtı, ancak Windows Update bu sürümü henüz sunmadı.
home-update-access-updating = Atlas, güncelleştirmeleri yüklemek için Windows Update'i açtı ve işlemi henüz bitirmedi.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Atlas'ın Windows Update kaydı okunamadı
# With Send a report and Export diagnostics under it; the raw error is behind Show details.
home-update-access-unreadable-problem = Atlas, değiştirdiği Windows Update ayarlarının kaydını okuyamıyor, bu yüzden hiçbir şeyi değiştirmeyecek veya geri yüklemeyecek.
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas ayarları geri yükleyemedi.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, in the close question when
# putting them back failed, and under the Windows release choice on Get ready. "Aşama" is a stage
# of installing, not one of the four flow steps (adım).
update-access-finish-install = Önce Atlas kurulumunu tamamlayın. Kurulumun son aşaması, Atlas'ın değiştirdiği Windows Update ayarlarını geri yükler.
home-continue-update = Güncelleştirmeye devam et
home-put-back = Ayarları geri yükle
home-putting-back = Ayarlar geri yükleniyor…

# Get ready: the card of the move to a newer Windows version, first on the page.
windows-card-title = Windows 11, sürüm { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version }, { $current } sürümünü desteklemediği için önce Windows'u güncelleştirir.
# Under the title where moving is optional.
windows-optional = Atlas her iki sürümle de çalışır.
# The choice's accessible name; the two answers say it.
windows-card-question = Bu bilgisayar hangi Windows sürümünü kullansın?
windows-choice-move-recommended = Windows 11 { $release } sürümüne güncelleştir (önerilir)
# $date is when the new version stops getting security updates.
windows-choice-move-support = { $date } tarihine kadar güvenlik güncelleştirmeleri.
windows-choice-keep = Windows 11 { $current } sürümünde kal
windows-choice-keep-later = { $current } sürümünde kalır. Daha sonra Atlas Manager'dan geçebilirsiniz.
windows-card-facts = Neler değişir
windows-fact-files = Dosyalarınız ve uygulamalarınız korunur. Güncelleştirmenin geri aldığı her şeyi Atlas yeniden uygular.
windows-fact-time = Genellikle birkaç dakika, en fazla 2 saat sürer; ardından bilgisayar yeniden başlar.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Windows PowerShell 2.0 ve WMIC kaldırılır.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = Güncelleştirme nasıl geri alınır?
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Güncelleştirerek Microsoft Yazılım Lisans Koşulları'nı kabul etmiş olursunuz.
windows-terms-link = Lisans koşullarını oku
windows-accept = Kabul et ve güncelleştir
# Once the terms are accepted, before the move starts by itself.
windows-starting = Başlatılıyor…
windows-starts-after-checks = Denetimler geçtiğinde başlar.
windows-starts-after-package = Atlas { $version } hazır olduğunda başlar.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = { $release } sürümü Atlas'ın bazı değişikliklerini sıfırladı. Atlas { $version }, önceki seçimlerinizle bunları yeniden uygular.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Windows 11 { $current } sürümünde kalınsın mı?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas, Windows Update'i geçici olarak açıyor
access-off = Windows Update bu bilgisayarda kapalı. Atlas, Windows'u güncelleştirirken onu yeniden açar.
access-paused = Windows güncelleştirmeleri bu bilgisayarda duraklatılmış. Atlas, Windows'u güncelleştirirken bunları sürdürür.
access-delayed = Aylık güncelleştirmeler bu bilgisayarda ertelenmiş. Atlas, Windows'u güncelleştirirken ertelemeyi kaldırır.
# After the lines above.
access-back = Atlas { $version } kurulduğunda bu ayarlar eski hâline döner.
access-back-stop = Bundan önce durdurursanız Atlas bunları geri yükler.

prepare-reason-feature-update = yeni Windows sürümü
prepare-reason-feature-commit = yeni Windows sürümünün tamamlanması
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Windows Update'in Windows 11 { $release } sürümünü sunması bekleniyor…
windows-waiting-detail = Genellikle birkaç dakika, en fazla 2 saat sürer. Atlas kendiliğinden devam eder; bu sırada bilgisayarınızı kullanabilirsiniz.
windows-waited =
    { $minutes ->
        [one] { $minutes } dakikadır bekleniyor.
       *[other] { $minutes } dakikadır bekleniyor.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update, { $release } sürümünü 2 saat içinde sunmadı
windows-wait-ended = Atlas ayarlarınızı geri yükledi. Daha sonra yeniden deneyin veya Windows'u bir Atlas ISO'suyla yeniden yükleyin.
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas, Windows Update ayarlarınızı geri yükleyemedi.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows yeniden başlatmayı hazırlayamadı
windows-commit-failed = Bilgisayarınız yeniden başlamadı. Yeniden deneyin.

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update, { $release } sürümünü henüz sunmadı
windows-outcome-not-offered = Bu 2 saate kadar sürebilir. Bilgisayarınızda hâlâ { $current } sürümü var.
windows-outcome-hardware-title = Bu bilgisayar Windows 11 gereksinimlerini karşılamıyor
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = Bilgisayarda { $missing } yok, bu yüzden Windows Update { $release } sürümünü sunmaz. Dosyalarınızı yedekleyin, ardından Windows'u bir Atlas ISO'suyla yeniden yükleyin.
hardware-tpm = TPM 2.0
hardware-uefi = UEFI ürün yazılımı
windows-outcome-hidden-title = { $release } sürümü Windows Update'te gizlenmiş
windows-outcome-hidden = Gizlemek için kullandığınız araçla yeniden gösterin, ardından yeniden deneyin.
windows-outcome-disk-space-title = Yeterli boş alan yok
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows'un { $drive } sürücüsünde { $needed } GB boş alana ihtiyacı var, sürücüde { $free } GB var. Yeterli alan olduğunda Atlas kendiliğinden devam eder.
windows-outcome-managed-title = Bu bilgisayar güncelleştirmeleri kuruluşundan alıyor
windows-outcome-managed = Güncelleştirme sunucusu { $release } sürümünü sunmuyor, bu yüzden Atlas hiçbir şeyi değiştirmedi. Kuruluşunuza danışın veya Windows'u bir Atlas ISO'suyla yeniden yükleyin.
windows-outcome-policy-title = Bir şey Windows Update'i sürekli eski hâline getiriyor
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = Atlas değiştirdikten sonra { $setting } eski hâline dönüyor, bu yüzden Atlas Windows'u güncelleştiremiyor. Bu bilgisayarı bir kuruluş yönetiyorsa kuruluşa danışın.
# $service is a service-* name, after a colon so that the name needs no suffix. The buttons are
# common-try-again and prepare-open-services.
windows-outcome-service-off-title = Hizmet kapatılmış: { $service }
windows-outcome-blocked-service = Windows Update'in bu hizmete ihtiyacı var. Hizmetler'de El ile olarak ayarlayın, ardından yeniden deneyin.
windows-outcome-blocked-title = Bir şey Windows Update'i kapalı tutuyor
windows-outcome-blocked = Atlas'ın değiştirmediği bir ayar Windows Update'in çalışmasını engelliyor: { $setting }. Bu ayarı değiştirin, ardından yeniden deneyin.
windows-outcome-rollback-title = Windows, { $release } sürümünü yüklemeyi tamamlayamadı
windows-outcome-rolled-back = Windows { $current } sürümüne geri döndü. Dosyalarınız ve uygulamalarınız etkilenmedi.
windows-outcome-components-lost-title = Atlas'ın bazı değişiklikleri kayboldu
windows-outcome-components-lost = Atlas nedenini anlayamadığı için Atlas { $version } kurulmadan önce durdu.
windows-outcome-build-title = Güncelleştirme sırasında Windows sürümü değişti
windows-outcome-build = Atlas'ın değiştirdiği ayarları geri yükleyin, ardından Giriş sayfasından baştan başlayın.
windows-outcome-journal-title = Atlas bu güncelleştirmenin kaydını okuyamıyor
windows-outcome-journal = Atlas ekibi inceleyene kadar Atlas hiçbir şeyi değiştirmeyecek veya geri yüklemeyecek.
windows-outcome-pin-title = Bir Windows Update ilkesi kaydedilemiyor
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = Atlas, { $setting } ilkesinin değerini daha sonra geri yükleyemez, bu yüzden hiçbir şeyi değiştirmedi.
windows-outcome-terms-title = Lisans koşulları kabul edilmedi
windows-outcome-terms = Windows Update'in { $release } sürümünü yüklemesi için koşulların kabul edilmesi gerekiyor.
windows-outcome-failed-title = Windows, { $release } sürümünü yükleyemedi
windows-outcome-failed = Bilgisayarınızda hâlâ { $current } sürümü var.
# Windows services a move needs, as the Turkish Services app lists them.
service-bits = Arka Plan Akıllı Aktarım Hizmeti (BITS)
service-cryptsvc = Şifreleme Hizmetleri
service-trusted-installer = Windows Modül Yükleyicisi
prepare-open-services = Hizmetler'i aç
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = { $current } sürümünde kal

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Atlas { $version } sürümüne güncelleştirme durdurulsun mu?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Windows güncelleştirmesi durdurulsun mu?
stop-update-before = Atlas, değiştirdiği Windows Update ayarlarını geri yükler. Windows'un zaten yüklediği güncelleştirmeler yüklü kalır ve bilgisayarınız Windows 11 { $current } sürümünde kalır.
stop-update-after = Bilgisayarınız Windows 11 { $release } sürümünde kalır. Atlas, değiştirdiği Windows Update ayarlarını geri yükler.
stop-update-access = Atlas, değiştirdiği Windows Update ayarlarını geri yükler. Windows'un zaten yüklediği güncelleştirmeler yüklü kalır.
stop-update-keep = Güncelleştirmeye devam et
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Atlas kapatılsın mı?
window-close-update-access-message = Atlas kapanmadan önce değiştirdiği Windows Update ayarlarını geri yükler. Güncelleştirmeye Giriş sayfasından yeniden başlayabilirsiniz.
window-close-put-back = Geri yükle ve kapat
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Ayarlar geri yüklenmeden kapatılsın mı?
window-close-put-back-failed-message = Atlas'ı şimdi kapatırsanız Windows Update ayarları Atlas'ın değiştirdiği şekilde kalır. Atlas'ı yeniden açtığınızda Giriş sayfası bunları geri yüklemeyi önerir.

# PC checks: Windows compatibility on a version Atlas moves from.
detail-build-needs-release = Bu Atlas sürümü için Windows 11 { $release } sürümü gerekiyor; bu bilgisayarda { $current } sürümü var.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Atlas için Windows güncelleştirmesi tamamlanmadı. Atlas ekibi için ayrıntılar:

# When Windows reinstalled itself while it moved to a newer version.
history-mode-rebase = Windows güncelleştirmesinden sonra yeniden kurulum
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Atlas { $previous } sürümündeki seçimleriniz
rebase-choices-kept = Atlas, Atlas { $previous } için yaptığınız seçimleri geri yükler. Bunları daha sonra Atlas'ı yeniden kurarak değiştirebilirsiniz.
# Above the questions the record of the move had no answer for.
rebase-choices-asked = Atlas, Atlas { $previous } için yaptığınız diğer tüm seçimleri geri yükler.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Başka biri oturum açmışken yeniden başlatılsın mı?
restart-others-question = Başka kişiler oturum açmışken yeniden başlatılsın mı?
# $names lists their account names, such as "Alex ve Sam", after a colon; $count is how many
# there are.
restart-others-signed-in =
    { $count ->
        [one] Şu kişi de oturum açmış durumda: { $names }. Yeniden başlatırsanız bu kişinin uygulamaları kapanır ve kaydedilmemiş çalışmaları kaybolur.
       *[other] Şu kişiler de oturum açmış durumda: { $names }. Yeniden başlatırsanız bu kişilerin uygulamaları kapanır ve kaydedilmemiş çalışmaları kaybolur.
    }
# "Yeniden başlatma" alone would read as the noun "restart", so the button says what it cancels.
restart-others-keep = Yeniden başlatmaktan vazgeç
restart-others-restart = Yine de yeniden başlat
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Microsoft Store güncelleştiriliyor…
prepare-store-repairing = Microsoft Store onarılıyor…
prepare-store-repair-detail = Bu birkaç dakika sürebilir.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
prepare-store-skipped-removed = Microsoft Store bu bilgisayarda kapalı, bu yüzden Store uygulamaları güncelleştirilmedi.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and iso-open are behind common-show-details.
prepare-store-broken-title = Microsoft Store çalışmıyor
prepare-store-broken = Atlas onu onaramadı ve Atlas'ı şimdi kurmak Store uygulamalarını bozabilir.
prepare-store-broken-iso = Onarım başarısız olmaya devam ederse dosyalarınızı yedekleyin ve Windows'u bir Atlas ISO'suyla yeniden yükleyin.
prepare-repair-store-again = Onarmayı yeniden dene
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows yerleşik uygulamalarını güncelleştiremiyor
prepare-store-staging = Windows bu yerleşik uygulamaların güncelleştirmelerini yükleyemedi ve Atlas'ın onarımları işe yaramadı: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Klavye dilleri
screen-keyboard-question = Birden fazla klavye dili kullanıyor musunuz?
package-option-keyboard-shortcuts = Evet, klavye kısayollarıyla
package-option-keyboard-selector = Evet, görev çubuğundaki seçiciyle
package-option-keyboard-single = Hayır, tek bir klavye düzeni kullanıyorum
consequence-keyboard-shortcuts = Alt+Shift dili, Ctrl+Shift klavye düzenini değiştirir.
consequence-keyboard-selector = Oyun sırasında yanlışlıkla geçiş yapmamak için Alt+Shift ve Ctrl+Shift kapatılır.
package-choice-keyboard-description = Klavye dilini nasıl değiştireceğinizi seçin.
# The same line as consequence-keyboard-selector, written out.
consequence-keyboard-single = Oyun sırasında yanlışlıkla geçiş yapmamak için Alt+Shift ve Ctrl+Shift kapatılır.
