### Atlas Manager: Turkish (tr). Preview translation, revised on 1 October 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically. Turkish nouns do not change after a number, so the
###   [one] and *[other] branches usually carry the same text.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
###   Never attach a Turkish suffix directly to a variable (vowel harmony
###   cannot be known); attach it to a following noun instead
###   ("{ $version } sürümünü", "{ $file } dosyasından").
### - Product names stay as they are: Atlas, AtlasOS, Windows, Microsoft
###   Defender, Windows Güvenliği, Windows Update, GitHub, Discord.
###   Windows feature names follow the Turkish Windows interface (for
###   example the four Virüs ve tehdit koruması switches).
### - Formal "siz" throughout, as in Microsoft Turkish. Buttons are short
###   imperatives. Sentences end with a full stop; titles and labels do not.
### - "Yeniden aç" = relaunch the Atlas Manager. "Yeniden başlat" = restart the PC.
### - The .apbx file is the "Atlas paketi" ("paket" once that is clear;
###   the button is "Paket dosyası aç").
### - A Windows build is a "derleme", as Windows says ("İS Derlemesi").
###   Diagnostics are "tanılama verileri" everywhere.

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
common-open-log-file = Günlük dosyasını aç
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Kurulum günlüğünü kopyala
common-install-log = Kurulum günlüğü
# Row labels in summary cards.
common-windows = Windows
common-options = Seçenekler
common-package = Kurulum dosyaları
common-installed-as = Kurulum türü
common-installed = Kuruldu
common-checking = Denetleniyor
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 veya 26200".
list-or = { $a } veya { $b }
list-and = { $a } ve { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Atlas kurulurken pencere kapatılsın mı?
window-close-message = Kurulum arka planda devam eder. İlerlemeyi ve sonucu görmek için Atlas'ı yeniden açın. Kurulum bitene kadar bilgisayarınızı açık tutun.
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = Kurulum arka planda devam eder, ancak Atlas kapalıyken bilgisayarınız otomatik olarak yeniden başlamaz. İlerlemeyi ve sonucu görmek için Atlas'ı yeniden açın. Kurulum bitene kadar bilgisayarınızı açık tutun.
window-close-keep = Açık tut
window-close-close = Pencereyi kapat
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = Kurulum başlamadan pencere kapatılsın mı?
window-close-preparing-message = Atlas bilgisayarınızı hâlâ denetliyor ve kuruluma henüz başlamadı. Şimdi kapatırsanız kurulum başlamaz. Devam etmek için Atlas'ı yeniden açın.
prepare-close-title = Güncellemeler hâlâ sürüyor
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = Güncellemeler sürerken Atlas'ı açık tutun. Güncellemeyi durdur'u seçerseniz güncellemeler geçerli adımdan sonra durur ve ardından Atlas'ı kapatabilirsiniz.
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = Atlas yeniden başlatmadan kapatılsın mı?
# "Şimdi yeniden başlat" is restart-now, one of this dialog's three buttons.
window-close-restart-message = Atlas kurulumunu tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor. Atlas'ı şimdi kapatırsanız Atlas bilgisayarınızı yeniden başlatmaz; hazır olduğunuzda kendiniz yeniden başlatın. Şimdi yeniden başlat'ı seçmeden önce çalışmanızı kaydedin.
window-close-restart-close = Yeniden başlatmadan kapat
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = Koruma kapalıyken Atlas kapatılsın mı?
window-close-protection-message = Windows Güvenliği'ndeki bazı korumalar hâlâ kapalı: { $switches }. Atlas'ı kurmayı bitirmeyecekseniz, kapatmadan önce bunları yeniden açın. Bitirecekseniz, Atlas'ı yeniden açtığınızda Atlas kurulumunuza kaldığı yerden devam eder.
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Atlas paketi aç (.apbx)
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
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Bu bilgisayardaki Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = { $date } tarihinde kuruldu
home-status-checking = Güncelleştirmeler denetleniyor
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
home-restart-title = Bilgisayarınızın yeniden başlatılması gerekiyor
home-security-reminder-title = Korumayı yeniden açın
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Korumanızın açık olduğundan emin olun
home-security-reminder-message = Atlas şu anda hiçbir şey kurmuyor, ancak Windows Güvenliği'ndeki bazı korumalar hâlâ kapalı. Windows Güvenliği'ni açın ve şunların açık olduğundan emin olun: { $switches }.
home-security-reminder-unreadable-message = Atlas koruma anahtarlarının hepsini okuyamadı. Windows Güvenliği'nde şunların açık olduğunu denetleyin: { $switches }.
home-elevation-title = Atlas'ın kurulum için izne ihtiyacı var
home-state-error-title = Atlas kurulum bilgileriniz okunamadı
home-state-error-message = Atlas sürümünüz, seçimleriniz ve kurulum geçmişiniz doğru gösterilmeyebilir. Yeniden denemek için Yeniden denetle'yi seçin. Ayrıntılar: { $error }
home-whats-new = Atlas { $version } sürümündeki yenilikler
home-view-release = Sürüm notlarını GitHub'da görüntüle
home-released = { $date } tarihinde yayımlandı
home-show-less = Daha az göster
home-show-full-notes = Tüm sürüm notlarını göster
home-your-install = Atlas kurulumunuz
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = Bu bilgisayarda Atlas'ın nasıl kurulduğuna dair bir kayıt yok, bu yüzden seçimleriniz ve kurulum geçmişi gösterilemiyor.
# Row label: how Atlas was set up.
home-set-up = Kurulum yöntemi
home-set-up-during-oobe = Windows kurulumu sırasında
home-history = Kurulum geçmişi
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Bilgisayarınızı Atlas için hazırlayalım
home-step-1-detail = Atlas bilgisayarınızı denetler, bekleyen Windows ve Microsoft Store güncellemelerini yükler ve kurulum dosyalarını indirir. Store uygulamaları kapanabilir ve bilgisayarınızın yeniden başlatılması gerekebilir; bu yüzden önce çalışmanızı kaydedin.
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas bilgisayarınızı denetler, bekleyen Windows ve Microsoft Store güncellemelerini yükler ve birlikte gelen kurulum dosyalarını hazırlar. Store uygulamaları kapanabilir ve bilgisayarınızın yeniden başlatılması gerekebilir; bu yüzden önce çalışmanızı kaydedin.
home-step-2-detail = Microsoft Defender'ı ve işlemci korumalarını tutup tutmayacağınızı, Windows güncelleştirmelerinin nasıl yükleneceğini ve isteğe bağlı ek özellikleri seçin.
home-step-3-detail = Kurulumu engellememeleri için Windows Güvenliği'ndeki dört koruma anahtarını kapatın. Atlas size nasıl yapacağınızı gösterir.
home-step-4-detail =
    { $minutes ->
        [one] Kurulum yaklaşık bir dakika sürer. Ardından bilgisayarınızın yeniden başlatılması gerekir.
       *[other] Kurulum yaklaşık { $minutes } dakika sürer. Ardından bilgisayarınızın yeniden başlatılması gerekir.
    }
# Accessible name of a numbered step.
home-step-a11y = { $number }. adım: { $title }
home-github = Atlas'ı GitHub'da görüntüle
home-discord = Atlas Discord topluluğuna katıl
home-report-problem = Sorun bildir

## How an install was done (from the state document)

mode-fresh = İlk kurulum
mode-upgrade = Önceki sürümden güncelleştirme
mode-reapply = Aynı sürümün yeniden kurulumu
mode-unknown = Kurulum
# Lower-case forms used inside a history row.
history-mode-fresh = ilk kurulum
history-mode-upgrade = güncelleştirme
history-mode-reapply = yeniden kurulum
history-mode-unknown = kurulum

## Notices on the Home page

notice-settings-reset-title = Atlas varsayılan uygulama ayarlarını kullanıyor
# $error is a raw error message (text).
notice-settings-unreadable = Atlas kayıtlı uygulama ayarlarınızı okuyamadı. Windows ayarlarınız değişmedi. Ayrıntılar: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = Uygulama ayarları dosyanız hasarlıydı ve sıfırlandı. Eski dosyanın bir kopyası { $file } adıyla kaydedildi. Ayrıntılar: { $error }
notice-settings-damaged = Uygulama ayarları dosyanız hasarlı. Atlas şimdilik varsayılan ayarları kullanıyor. Ayrıntılar: { $error }
notice-settings-not-saved-title = Uygulama ayarları kaydedilemedi
# $error is a raw error message (text).
notice-settings-not-saved = Atlas son değişikliklerinizi kaydedemedi; Atlas'ı kapattığınızda bu değişiklikler kaybolabilir. Başka bir Atlas penceresi açıksa kapatın, sonra değişikliği yeniden yapın. Ayrıntılar: { $error }
notice-session-unreadable-title = Önceki kurulum denetlenemedi
# $path is a file path (text).
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
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Adım { $number } / { $total }, { $title }, { $status }
stepper-status-completed = tamamlandı
stepper-status-current = geçerli adım
stepper-status-upcoming = sonraki adım
stepper-status-attention = dikkat gerektiriyor
# Heading above each step's content.
step-heading = Adım { $number } / { $total }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }. { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }. { $progress }

## Step 1: Get ready

ready-banner-busy-title = Bilgisayarınız hazırlanıyor
ready-banner-busy-message = Atlas bilgisayarınızı denetliyor ve kurulum dosyalarını hazırlıyor.
ready-banner-blocked-title = Bilgisayarınız henüz hazır değil
ready-banner-blocked-message = Bilgisayar denetimlerinde işaretlenen sorunları giderin, ardından Yeniden denetle'yi seçin.
ready-banner-no-package-title = Devam etmek için Atlas'ı indirin
ready-banner-no-package-message = Atlas'ı Kurulum dosyaları kartından indirin veya bir Atlas paketiniz (.apbx) varsa Paket dosyası aç'ı seçin.
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = Devam etmek için birlikte gelen Atlas paketini hazırlayın
ready-banner-no-package-bundled-message = Bu test sürümüyle gelen Atlas paketi henüz hazır değil. Kurulum dosyaları kartını denetleyin.
ready-banner-updates-title = Devam etmek için Windows ve Store uygulamalarını güncelleyin
ready-banner-updates-message = Güncellemeleri denetle ve yükle'yi seçin. Güncellemeler bittiğinde Atlas bilgisayarınızı yeniden denetler.
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Windows ve Store uygulamaları güncelleniyor
ready-banner-updating-message = Bu biraz zaman alabilir. Atlas'ı açık tutun. İlerlemeyi Windows ve Store güncellemeleri kartında izleyebilirsiniz.
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = Güncelleme durduruldu
ready-banner-updates-stopped-message = Bitirmek için Windows ve Store güncellemeleri kartında Güncellemeleri denetle ve yükle'yi seçin.
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = Bilgisayarınız yeniden başlatıldı
ready-banner-updates-resumed-message = Güncellemeyi bitirmek için Windows ve Store güncellemeleri kartında Güncellemelere devam et'i seçin.
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = Ne yapmanız gerektiğini görmek için Windows ve Store güncellemeleri kartına bakın, ardından Yeniden dene'yi seçin.
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = Önce çalışmanızı kaydedin, ardından Windows ve Store güncellemeleri kartında Yeniden başlat ve devam et'i seçin.
ready-banner-warnings-title = Gözden geçirmeniz gereken birkaç nokta var
ready-banner-warnings-message = Devam edebilirsiniz, ancak önce Bilgisayar denetimlerinde işaretlenen öğeleri okuyun.
ready-banner-ok-title = Seçimlerinizi yapmaya hazırsınız
ready-banner-ok-message = Denetimler geçti ve kurulum dosyalarınız hazır.

# Card title and accessible name of the list of checks.
ready-this-pc = Bilgisayar denetimleri
ready-check-again = Yeniden denetle
ready-checks-passed =
    { $count ->
        [one] { $count } denetim geçti
       *[other] { $count } denetim geçti
    }

package-title = Kurulum dosyaları
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } indiriliyor · { $received } / { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Paket açılıyor · { $done } / { $total } dosya
       *[other] Paket açılıyor · { $done } / { $total } dosya
    }
package-unpacking = Paket açılıyor
package-looking = En son Atlas sürümü denetleniyor.
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = Birlikte gelen Atlas paketi hazırlanıyor.
package-none = Kurulum dosyalarını almak için Atlas'ı indirin. Elinizde bir Atlas paketi (.apbx) varsa bunun yerine onu açın.
# The GitHub release check failed. "En son sürümü indir" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas en son sürümü denetleyemedi. İnternet bağlantınızı denetleyin, sonra En son sürümü indir'i seçin veya kayıtlı bir Atlas paketi (.apbx) açın.
# Short status words beside the card title.
package-status-downloading = İndiriliyor
package-status-unpacking = Açılıyor
package-status-failed = Dosyalar hazırlanamadı
package-status-ready = Hazır
package-status-checking = Denetleniyor
package-status-preparing = Hazırlanıyor
package-status-missing = İndirilmedi
# Accessible name of the progress bar.
package-progress = Kurulum dosyalarının ilerlemesi
package-download-again = Yeniden indir
package-download-version = Atlas { $version } sürümünü indir
package-download-newest = En son sürümü indir
package-cancel-download = İndirmeyi iptal et
package-open-file = Paket dosyası aç
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } GitHub'dan indirildi ve kuruluma hazır.
package-from-file = Atlas { $version }, { $file } dosyasından yüklendi ve kuruluma hazır.
package-unpacked = Atlas { $version } kuruluma hazır.
package-none-yet = Kurulum dosyası seçilmedi
acquire-no-asset = Atlas { $version } sürümü için indirilebilecek bir paket dosyası yok. Devam etmek için kayıtlı bir Atlas paketi (.apbx) açın.
acquire-unsupported = Bu uygulama Atlas 0.6.0 ve sonraki sürümleri kurabilir. Atlas { $version } sürümünü kurmak için AME Wizard'ı kullanın.
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } sürümünde bu uygulamanın kurulum için ihtiyaç duyduğu dosyalar eksik. Sürümü yeniden indirin veya başka bir Atlas paketi (.apbx) açın.
acquire-failed = Kurulum dosyaları hazırlanamadı. Yeniden indirmeyi deneyin veya başka bir Atlas paketi (.apbx) açın. Ayrıntılar: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = İndirme yanıt vermeyi durdurdu. İnternet bağlantınızı denetleyin, sonra yeniden indirin veya kayıtlı bir Atlas paketi (.apbx) açın.
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Birlikte gelen Atlas paketi hazırlanamadı. Yeniden dene'yi seçin. Ayrıntılar: { $error }

## System checks

check-administrator = Kurulum izni
check-supported-build = Windows uyumluluğu
check-pending-updates = Windows güncelleştirmeleri
check-pending-reboot = Bekleyen yeniden başlatma
check-third-party-antivirus = Diğer virüsten koruma yazılımları
check-internet = İnternet bağlantısı
check-power = Güç kaynağı
check-activation = Windows etkinleştirmesi
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
check-fix-apps = Yüklü uygulamaları aç
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = Windows Update'i denetledim: yüklenmeyi bekleyen güncelleştirme yok

detail-admin-ok = Atlas, kurulum için gereken değişiklikleri yapma iznine sahip.
detail-admin-missing = Atlas'ı yönetici olarak yeniden açın, ardından Windows izin istediğinde Evet'i seçin.
# $builds is a list of build numbers such as "26100 veya 26200"; $build is this PC's (text).
detail-build-unsupported = Bu Atlas sürümü için Windows { $builds } derlemesi gerekiyor. Bilgisayarınızda { $build } derlemesi var. Devam etmeden önce desteklenen bir Windows sürümü yükleyin.
detail-build-missing = Bu Atlas paketi desteklenen hiçbir Windows derlemesini listelemiyor. LocalTest sürümü yerine paketin tam sürümünü kullanın.
detail-updates-none = Yüklenmeyi bekleyen Windows güncelleştirmesi yok.
# $titles lists up to two update names (text); $count is the total. "Windows ve Store
# güncellemeleri" is prepare-title, the card that installs them.
detail-updates-pending =
    { $count ->
        [1] Bu güncelleştirme bekliyor: { $titles }. Atlas bunu Windows ve Store güncellemeleri kartında yükler.
        [2] Bu güncelleştirmeler bekliyor: { $titles }. Atlas bunları Windows ve Store güncellemeleri kartında yükler.
       *[other] { $titles } dahil { $count } güncelleştirme bekliyor. Atlas bunları Windows ve Store güncellemeleri kartında yükler.
    }
detail-updates-unknown = Windows güncelleştirmeleri denetlenemedi. Windows Update'i açın; bekleyen güncelleştirme yoksa aşağıda onaylayın. ({ $error })
detail-reboot-none = Windows'un şu anda yeniden başlatılması gerekmiyor.
detail-reboot-pending = Önceki değişiklikleri tamamlamak için Windows'un yeniden başlatılması gerekiyor. Güncellemeleri denetle ve yükle'yi seçtiğinizde Atlas önce yeniden başlatmanızı ister.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = Önceki değişiklikleri tamamlamak için Windows'un yeniden başlatılması gerekiyor ({ $reasons }). Güncellemeleri denetle ve yükle'yi seçtiğinizde Atlas önce yeniden başlatmanızı ister.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = Devam edebilirsiniz. Windows'un bir sonraki yeniden başlatmada değiştireceği veya kaldıracağı dosyalar var ({ $files }). Xbox Gaming Services gibi bazı uygulamalar bunu her yeniden başlatmadan sonra yapar.
detail-reboot-unknown = Windows'un yeniden başlatılması gerekip gerekmediği denetlenemedi. Bilgisayarınızı yeniden başlatın, ardından Atlas'ı yeniden açıp yeniden denetleyin. ({ $error })
detail-antivirus-none = Başka bir virüsten koruma yazılımı algılanmadı.
# $products is a list of product names (text).
detail-antivirus-found = Microsoft Defender dışındaki virüsten koruma uygulamaları kurulumu engelleyebilir. { $products } yazılımını kaldırın, ardından Yeniden denetle'yi seçin.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows Güvenliği { $products } yazılımını hâlâ listeliyor, ancak dosyaları artık yok; yani artık yüklü değil. Atlas yine de kurulabilir.
detail-antivirus-unknown = Diğer virüsten koruma yazılımları denetlenemedi. Yeniden denetle'yi seçin. Sorun devam ederse bilgisayarınızı yeniden başlatın ve yeniden denetleyin. ({ $error })
detail-internet-ok = İnternete bağlısınız. Atlas yazılımları indirip kurarken bu bağlantıyı açık tutun.
detail-internet-missing = İnternete bağlanın, sonra yeniden denetleyin.
detail-power-mains = Bilgisayarınız fişe takılı. Kurulum bitene kadar takılı bırakın.
detail-power-battery = Kurulum boyunca açık kalması için bilgisayarınızı fişe takın.
detail-power-unknown = Atlas, bilgisayarınızın fişe takılı olup olmadığını anlayamadı. Dizüstü bilgisayar kullanıyorsanız fişe takın, ardından Yeniden denetle'yi seçin. Bu durum devam ederse Rapor gönder'i seçin.
detail-activation-ok = Windows etkin. Atlas bunu değiştirmez.
detail-activation-missing = Windows etkin değil. Devam edebilirsiniz, ancak Atlas Windows'u sizin için etkinleştirmez.
detail-activation-no-licence = Windows bir lisans bildirmedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez.
detail-activation-unknown = Windows etkinleştirmesi denetlenemedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez. ({ $error })

## Step 2: Options

options-progress = Seçim { $number } / { $total }
options-progress-extras = Seçim { $number } / { $total }: isteğe bağlı ek özellikler
options-change-later = Microsoft Defender, işlemci korumaları ve güncelleştirme ayarlarını daha sonra masaüstünüzdeki Atlas klasöründen değiştirebilirsiniz.
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
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } için bir seçenek belirleyin
learn-more-defender = Microsoft Defender hakkında daha fazla bilgi
learn-more-mitigations = İşlemci korumaları hakkında daha fazla bilgi
learn-more-updates = Windows Update hakkında daha fazla bilgi
learn-more-browser = Tarayıcılar hakkında daha fazla bilgi
learn-more-power = Güç ve güvenlik hakkında daha fazla bilgi
learn-more-apps = Uygulamalar hakkında daha fazla bilgi
learn-more-eclean = eclean, AtlasOS ile nasıl çalışır?
learn-more-generic = Kurulum kılavuzunu oku
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Bilgisayarınızı virüslerden ve diğer tehditlerden korumaya yardımcı olan yerleşik Windows virüsten koruma yazılımını tutar.
consequence-defender-disable = SmartScreen'i de kaldırır. Başka bir virüsten koruma uygulaması yükleyene kadar bilgisayarınızda virüsten koruma olmaz ve Windows, tanınmayan uygulamaları veya indirilen dosyaları açmadan önce sizi uyarmaz.
consequence-mitigations-default = Windows'un işlemci açıklarına ve uygulamalardaki hatalardan yararlanan saldırılara karşı varsayılan korumalarını tutar.
consequence-mitigations-disable = Uygulamalar için Denetim akışı koruması (CFG) gibi Açıktan yararlanma koruması ayarlarını da kapatır. Bu, güvenliği azaltır. Performansta bir fark olup olmayacağı işlemcinize bağlıdır.
consequence-auto-updates-disable = Güncelleştirmeleri yüklemek için Windows Update'i düzenli olarak açın. Güncelleştirme bildirimleri açık kalır.
consequence-auto-updates-default = Windows, güvenlik düzeltmeleri dahil güncelleştirmeleri otomatik olarak yükler.

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender'ı tut (önerilir)
playbook-option-defender-disable = Microsoft Defender'ı kaldır
playbook-option-mitigations-default = İşlemci korumalarını tut (önerilir)
playbook-option-mitigations-disable = İşlemci korumalarını kapat
playbook-option-auto-updates-disable = Güncelleştirmeleri kendim yükleyeceğim
playbook-option-auto-updates-default = Güncelleştirmeleri otomatik olarak yükle
playbook-option-disable-hibernation = Hazırda bekletmeyi kapat
playbook-option-disable-power-saving = Güç tasarrufunu kapat
playbook-option-disable-core-isolation = Sanallaştırma tabanlı güvenliği (VBS) kapat
playbook-option-remove-snipping-tool = Ekran Alıntısı Aracı'nı kaldır
playbook-option-uninstall-edge = Microsoft Edge'i kaldır
playbook-option-install-another-browser = Tarayıcı yükle
playbook-option-install-toolbox = Atlas Toolbox'ı yükle
playbook-option-install-eclean = eclean yükle
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender, Windows'un yerleşik virüsten koruma yazılımıdır. Yalnızca riskleri anlıyorsanız ve başka bir virüsten koruma uygulaması kullanacaksanız kaldırın. Hangisini seçerseniz seçin, Atlas şunları kapatır: Akıllı Uygulama Denetimi, Gelişmiş Kimlik Avı Koruması ve Cihazımı bul.
playbook-page-mitigations-default-description = Güvenlik risk azaltmaları olarak da bilinen bu korumalar, Spectre ve Meltdown gibi işlemci açıklarına ve uygulamalardaki hatalardan yararlanan saldırılara karşı korunmaya yardımcı olur. Windows varsayılanlarını tutmanız önerilir.
playbook-page-auto-updates-disable-description = Windows güncelleştirmeleri güvenlik düzeltmeleri içerir. Bunları Windows'un otomatik olarak yüklemesini seçebilir veya kendiniz yükleyebilirsiniz. Her iki durumda da Atlas, Windows'u mevcut sürümünde tutar. Bu sürüm, yalnızca Microsoft desteğini sonlandırana kadar güvenlik düzeltmeleri alır. Atlas ayrıca Microsoft Store uygulamalarının otomatik güncelleştirmelerini kapatır; bu yüzden bu uygulamaları Microsoft Store'dan güncelleyin.
playbook-page-browser-brave-description = Yüklenecek bir tarayıcı seçin. Atlas tarayıcı ayarlarınızı değiştirmez.

## Step 3: Windows Security

security-banner-reading-title = Windows Güvenliği denetleniyor
security-banner-reading-message = Atlas aşağıdaki dört koruma anahtarını denetliyor.
security-banner-off-title = Dört koruma anahtarı da kapalı
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = Microsoft Defender bu bilgisayarda yüklü değil
security-banner-absent-message = Bu adımda kapatılacak bir şey yok. Devam et'i seçin.
security-banner-off-message = Kurulumunuzu gözden geçirmek ve Atlas'ı kurmak için Devam et'i seçin.
security-banner-on-title = Windows Güvenliği'nde virüsten korumayı kapatın
security-banner-on-message = Microsoft Defender, Atlas'ın yaptığı değişiklikleri engelleyebilir. Windows Güvenliği'ni aç'ı seçin ve aşağıda listelenen her anahtarı kapatın. Microsoft Defender'ı tutarsanız kurulum bittikten sonra anahtarları yeniden açın.
# The page name in Windows Security.
security-list-title = Virüs ve tehdit koruması ayarları
security-switch-off = Kapalı
security-switch-on = Açık
security-switch-unreadable = Okunamıyor
security-switch-reading = Denetleniyor
security-all-off = Tümü kapalı
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 tanesi hâlâ açık, 1 tanesi okunamıyor".
security-count-still-on = { $count } tanesi hâlâ açık
security-count-unreadable = { $count } tanesi okunamıyor
security-count-join = { $a }, { $b }
security-unknown-title = Atlas'ın okuyamadığı anahtarları onaylayın
security-unknown-message = Windows Güvenliği'nde dört anahtarın da kapalı olduğundan emin olun, ardından aşağıda onaylayın.
security-acknowledge = Windows Güvenliği'ni denetledim ve dört anahtar da kapalı
security-unknown-unelevated-title = Atlas'ın korumayı denetlemek için izne ihtiyacı var
security-unknown-unelevated-message = Microsoft Defender ayarlarını denetleyebilmesi için Atlas'ı yönetici olarak yeniden açın.
# The four switches, named as Windows Security names them in Turkish.
protection-tamper = Kurcalama Koruması
protection-tamper-why = Atlas'ın Defender'ın güvenlik ayarlarını değiştirebilmesi için bunu kapatın.
protection-realtime = Gerçek zamanlı koruma
protection-realtime-why = Defender'ın Atlas kurulum dosyalarını tararken engellememesi için bunu kapatın.
protection-cloud = Bulut tabanlı koruma
protection-cloud-why = Çevrimiçi tehdit denetimlerinin Atlas kurulum dosyalarını engellememesi için bunu kapatın.
protection-samples = Otomatik örnek gönderimi
protection-samples-why = Defender'ın Atlas dosyalarını analiz için Microsoft'a otomatik olarak göndermesini durdurun.

## Step 4: Install

# Accessible name of the progress bar.
install-progress = Kurulum ilerlemesi
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = %{ $percent }
outcome-succeeded-title = Atlas kuruldu
outcome-lost-title = Kurulum sonucu doğrulanamadı
outcome-failed-title = Kurulum tamamlanmadı
outcome-requirements = Bilgisayarınız kurulum gereksinimlerini karşılamadı. Kurulum hiçbir değişiklik yapmadı. Hazırlık adımına dönüp denetimleri yeniden çalıştırın.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = Bilgisayarınız kurulum gereksinimlerini karşılamadığı için bu deneme durdu. Önceki bir deneme değişiklik yapmaya zaten başlamıştı. Hazırlık adımına dönüp denetimleri yeniden çalıştırın.
outcome-not-elevated = Atlas'ın yönetici izni yoktu. Kurulum hiçbir değişiklik yapmadı. Atlas'ı yönetici olarak yeniden açın, ardından yeniden deneyin.
outcome-not-elevated-resumed = Atlas'ın yönetici izni olmadığı için bu deneme durdu. Önceki bir deneme değişiklik yapmaya zaten başlamıştı. Atlas'ı yönetici olarak yeniden açın, ardından yeniden deneyin.
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "Güncellemeleri denetle ve yükle" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas, Windows ve Store uygulamalarının güncel olduğunu doğrulayamadı, bu yüzden kurulum Windows'u değiştirmeden durdu. Hazırlık adımına dönüp Güncellemeleri denetle ve yükle'yi seçin.
outcome-preparation-stale-resumed = Atlas, Windows ve Store uygulamalarının güncel olduğunu doğrulayamadığı için bu deneme durdu, ancak önceki bir deneme değişiklik yapmaya zaten başlamıştı. Hazırlık adımına dönüp Güncellemeleri denetle ve yükle'yi seçin.
outcome-failed-preflight = Kurulum, hiçbir şey değiştirilmeden durdu. Yeniden deneyebilirsiniz. Yine durursa Rapor gönder'i seçin.
outcome-failed-staging = Kurulum, dosyalar hazırlanırken ve Windows değiştirilmeden önce durdu. Yeniden deneyebilirsiniz. Yine durursa Rapor gönder'i seçin.
outcome-failed-applying = Bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz. Burada duracaksanız, kapattığınız korumaları hâlâ mevcutsa Windows Güvenliği'nde yeniden açın.
outcome-failed-resumed = Bu deneme erken durdu, ancak önceki bir deneme değişiklik yapmaya zaten başlamıştı. Yeniden deneyebilirsiniz. Burada duracaksanız, kapattığınız korumaları hâlâ mevcutsa Windows Güvenliği'nde yeniden açın.
outcome-not-started = Yükleyici zamanında başlamadı. Kurulum hiçbir değişiklik yapmadı. Yeniden deneyebilirsiniz.
outcome-lost = Yükleyici bir sonuç bildirmeden durdu ve bazı değişiklikler yapılmış olabilir. Yeniden deneyebilirsiniz. Burada duracaksanız, kapattığınız korumaları hâlâ mevcutsa Windows Güvenliği'nde yeniden açın.
restart-now-message = Atlas kurulumunu tamamlamak için Windows yeniden başlatılıyor.
restart-countdown =
    { $seconds ->
        [one] Atlas kurulumunu tamamlamak için Windows { $seconds } saniye içinde yeniden başlatılacak. Önce çalışmanızı kaydetmek için Daha sonra yeniden başlat'ı seçin.
       *[other] Atlas kurulumunu tamamlamak için Windows { $seconds } saniye içinde yeniden başlatılacak. Önce çalışmanızı kaydetmek için Daha sonra yeniden başlat'ı seçin.
    }
restart-stopped = Otomatik yeniden başlatma iptal edildi. Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
restart-needed = Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
restart-dont-now = Daha sonra yeniden başlat
restart-now = Şimdi yeniden başlat
restart-start-failed = Atlas bilgisayarınızı yeniden başlatamadı. Çalışmanızı kaydedin, ardından Başlat menüsünden yeniden başlatın. Ayrıntılar: { $error }
preflight-title = Kurulum başlamadı
preflight-invalid-options = Atlas bu kurulum seçimlerini kullanamadı. Seçimleriniz adımına dönüp gözden geçirin, sonra yeniden deneyin. Ayrıntılar: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Bilgisayarınızın durumu önceki denetimlerden sonra değişti. Yeniden denemeden önce şunları çözün. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 tanesi hâlâ açık".
preflight-security = Windows Güvenliği: { $summary }.
preflight-busy = Başka bir Atlas penceresi kurulum başlatıyor. Biraz bekleyin, ardından Atlas'ı kur'u yeniden seçin.
# Shown with the home-start-over button.
preflight-taken-over = Başka bir Atlas penceresi bu kurulumu devraldı, bu yüzden kurulum başlamadı. O pencerede devam edin veya kurulumu burada baştan yapmak için Baştan başla'yı seçin.
preflight-record-unreadable = Atlas önceki kurulumun hâlâ sürüp sürmediğini denetleyemedi, bu yüzden yeni bir kurulum başlatmadı. Ne yapmanız gerektiğini görmek için Hazırlık adımına dönün. Ayrıntılar: { $error }
preflight-refused = Yükleyici başlatılamadı. Kurulum hiçbir değişiklik yapmadı. Yeniden denemek için Atlas'ı kur'u seçin. Bu durum devam ederse Rapor gönder'i seçin. Ayrıntılar: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = Yükleyici başlatılamadığı için bu deneme durdu. Önceki bir deneme değişiklik yapmaya zaten başlamıştı. Yeniden denemek için Atlas'ı kur'u seçin. Bu durum devam ederse Rapor gönder'i seçin. Ayrıntılar: { $error }
go-to-ready = Hazırlık adımına dön
go-to-options = Seçimleriniz adımına dön
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Kurulum adımına dön
output-problem-title = Kurulum ilerlemesi okunamadı
output-problem-message = Atlas günlüğü okuyamadı. Bu, kurulumun durduğu anlamına gelmez. Bilgisayarınızı açık tutun ve günlük dosyasını açmayı deneyin. Ayrıntılar: { $error }
install-elevate-title = Atlas'ın kurulum için izne ihtiyacı var
install-no-package-title = Önce kurulum dosyalarınızı seçin
install-no-package-message = Atlas'ı indirmek veya kayıtlı bir Atlas paketi (.apbx) açmak için Hazırlık adımına dönün.
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = Bu test sürümüyle gelen Atlas paketini hazırlamak için Hazırlık adımına dönün.
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Önce Hazırlık adımını tamamlayın
install-not-ready-message = Atlas'ın kuruluma başlayabilmesi için önce bilgisayarınızı denetlemeyi ve Windows'u güncellemeyi bitirmesi gerekiyor.
install-security-title = Kurulumdan önce virüsten korumayı denetleyin
install-security-reading = Dört koruma anahtarı yeniden denetleniyor.
install-security-message = { $summary }. Kurulumdan önce Windows Güvenliği'ni açın ve dört anahtarın da kapalı olduğundan emin olun.
summary-try-again = Yeniden denemeden önce gözden geçirin
summary-ready = Atlas kurulumunuzu gözden geçirin
summary-activation = Etkinleştirme
summary-activation-ok = Etkin. Atlas bunu değiştirmez.
summary-activation-missing = Etkin değil. Devam edebilirsiniz, ancak Atlas Windows'u etkinleştirmez.
summary-activation-unknown = Atlas Windows etkinleştirme durumunuzu değiştirmez.
summary-duration = Tahmini süre
summary-duration-value =
    { $minutes ->
        [one] { $minutes } dakika, ardından yeniden başlatma
       *[other] { $minutes } dakika, ardından yeniden başlatma
    }
summary-restart-checkbox = Kurulumdan sonra bilgisayarımı otomatik olarak yeniden başlat
summary-show-command = Kurulum komutunu göster
summary-hide-command = Kurulum komutunu gizle
summary-copy-command-a11y = Kurulum komutunu kopyala
summary-command-unavailable = Kurulum komutu hazırlanamadı. Ayrıntılar: { $error }
summary-not-chosen = Henüz seçim yapılmadı
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } seçimini değiştir
footer-still-checking = Kuruluma hazırlanıyor
footer-fix-items = Devam etmek için Bilgisayar denetimlerindeki sorunları giderin
footer-need-package = Devam etmek için Atlas'ı indirin veya bir Atlas paketi açın
# Tester build variant of footer-need-package.
footer-need-package-bundled = Devam etmek için birlikte gelen Atlas paketini hazırlayın
footer-reading-security = Koruma anahtarları denetleniyor
footer-security-pending = Devam etmek için dört anahtarı da kapatın
footer-security-confirm = Devam etmek için Atlas'ın okuyamadığı anahtarları onaylayın
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

installing-checking-title = Son bir denetim
installing-checking-line = Atlas değişiklik yapmadan önce bilgisayarınızı denetliyor. Bu biraz sürebilir.
installing-title = Atlas kuruluyor
installing-phase-preflight = Bilgisayarınız denetleniyor ve kurulum dosyaları hazırlanıyor.
installing-phase-staging = Kurulum dosyaları kopyalanıyor. Bilgisayarınızı açık tutun.
installing-phase-applying = Windows seçimlerinize göre ayarlanıyor. Bilgisayarınızı açık ve fişe takılı tutun.
installing-phase-done = Kurulum tamamlanıyor. Bilgisayarınızı açık tutun.
installing-installed-title = Atlas kuruldu
# $time is a formatted clock time.
installing-started-just-now = Başlangıç: { $time }, bir dakikadan kısa süre önce
installing-started-minutes =
    { $minutes ->
        [one] Başlangıç: { $time }, bir dakika önce
       *[other] Başlangıç: { $time }, { $minutes } dakika önce
    }
installing-restart-auto = Kurulum bittiğinde bilgisayarınız otomatik olarak yeniden başlar. Bundan önce diğer uygulamalardaki çalışmalarınızı kaydedin.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } kuruldu
installed-title = Atlas kuruldu
installed-ready = Her şey tamam. Bilgisayarınız Atlas ile kullanıma hazır.
installed-security-message = Microsoft Defender'ı tuttunuz, ancak bazı korumaları hâlâ kapalı. Windows Güvenliği'ni açın ve şunların açık olduğundan emin olun: { $switches }.
installed-defender-removed-title = Microsoft Defender kaldırıldı
installed-defender-removed-message = Başka bir virüsten koruma uygulaması yükleyene kadar bilgisayarınızda virüsten koruma olmaz. SmartScreen de kaldırıldı, bu yüzden Windows, tanınmayan uygulamaları veya indirilen dosyaları açmadan önce sizi uyarmaz.
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = Microsoft Defender'ı tutmayı seçtiniz, ancak Defender bilgisayarınızda yok. Başka bir virüsten koruma uygulaması kullanmıyorsanız bilgisayarınızı korumak için bir tane yükleyin. Defender'ı kendiniz kaldırmadıysanız Sorun bildir'i seçin.

## Settings

settings-title = Ayarlar
settings-theme = Uygulama teması
settings-theme-system = Windows ile aynı
settings-theme-light = Açık
settings-theme-dark = Koyu
settings-theme-contrast-note = Atlas, Windows kontrast temanızın renklerini kullanıyor.
settings-theme-mica-note = Yarı saydam arka planı görmek için Windows ile aynı açık veya koyu temayı seçin.
settings-language = Dil
settings-language-system = Windows ile aynı
settings-language-system-selected = { settings-language-system } ({ $language })
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Windows ile aynı seçildiğinde: { $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = Önizleme
# Under the language list, once, explaining the Preview tag.
settings-language-preview-note = Önizleme çevirileri henüz o dili anadili olarak konuşan biri tarafından incelenmedi.
preview-notice = { $language } çevirisi bir önizlemedir ve hatalar içerebilir.
preview-notice-switch = İngilizceye geç
preview-notice-language = Dili değiştir
# $tag is a language tag (text).
settings-language-unavailable = { $tag } bu Atlas sürümünde kullanılamıyor. Şimdilik İngilizce gösteriliyor; dil seçiminiz kaydedildi.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas, Windows görüntüleme dillerinizi ({ $languages }) henüz desteklemiyor. Şimdilik İngilizce gösteriliyor.
settings-language-windows-unavailable = Windows görüntüleme diliniz denetlenemedi. Atlas şimdilik İngilizce kullanıyor. Ayrıntılar: { $error }
# $locale is the regional format's own name, for example "Türkçe (Türkiye)".
settings-language-formats = Sayılar, tarihler ve saatler Windows bölgesel biçiminizi izler ({ $locale }).
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Sayılar Windows bölgesel biçiminizi izler ({ $locale }). Atlas sağdan sola yazılan metni henüz gösteremediği için tarihler ve saatler standart bir biçimde gösterilir.
settings-language-contribute = Atlas'ın çevirisine GitHub'da katkıda bulun
settings-restart-label = Kurulumdan sonra bilgisayarımı otomatik olarak yeniden başlat
settings-restart-locked = Bunu kurulum bittikten sonra değiştirebilirsiniz.
settings-restart-description = Bu ayar açıkken bilgisayarınız kurulum bittikten sonra bir dakika içinde yeniden başlar ve açık uygulamalarınız kapanır. Kurulumdan önce çalışmanızı kaydedin.
settings-help = Yardım ve geri bildirim
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

consequence-disable-hibernation = Hazırda bekletme sırasında oturumunuzu kaydetmek için kullanılan disk alanını boşaltır. Hazırda bekletme ve Hızlı Başlatma kullanılamaz hale gelir.
consequence-disable-power-saving = Güç tasarrufu özelliklerini kapatır. Bilgisayarınız daha fazla güç tüketebilir, daha çok ısınabilir ve pil ömrü kısalabilir.
consequence-disable-core-isolation = Bellek bütünlüğü dahil ek bir Windows güvenlik katmanını kapatır. Bu, korumayı azaltır ve bu katmana ihtiyaç duyan uygulama veya oyunları etkileyebilir.
consequence-remove-snipping-tool = Ekran görüntüsü ve ekran kaydı almak için kullanılan Windows uygulamasını kaldırır.
consequence-uninstall-edge = Microsoft Edge tarayıcısını kaldırır. Başka bir tarayıcınız olduğundan emin olun veya aşağıdan birini seçin.
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Microsoft Edge'i kaldırır ve bu bilgisayardaki Edge yer işaretlerinizi, geçmişinizi ve kayıtlı parolalarınızı siler. Microsoft hesabınızla eşitlenmemiş olan her şey kaybolur. Başka bir tarayıcınız olduğundan emin olun veya aşağıdan birini seçin.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Bu bilgisayardaki Edge yer işaretlerinizi, geçmişinizi ve kayıtlı parolalarınızı siler.
consequence-install-another-browser = Aşağıdan bir tarayıcı seçin; Atlas onu sizin için yükler.
consequence-install-toolbox = Atlas ayarlarınızı yönetmenize yardımcı olması için Atlas Toolbox'ı ekleyin. Toolbox beta aşamasında olduğu için bazı özellikler henüz tamamlanmamış olabilir.
consequence-install-eclean = Kurulumdan sonra bilgisayarınızı düzenli tutmak için AtlasOS ekibinden bir bakım aracı. Gereksiz dosyaları ve başlangıç uygulamalarını inceleyin. Hesap ve internet bağlantısı gerektirir.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas, arka plan etkinliğini ve dikkat dağıtan öğeleri azaltmak için Windows'ta ayarlamalar yapar. Atlas'ı, kendi uygulamalarınızı ve dosyalarınızı eklemeden önce temiz bir Windows kurulumuna kurun.

## ISO creation (Beta)
iso-home-title = Windows yükleme medyası
iso-home-description = Atlas içeren bir Windows kurulum dosyası (ISO) oluşturun, ardından bu dosyayla Windows'u bu bilgisayara veya başka bir bilgisayara yeniden yükleyin.
iso-open = Atlas ISO'su oluştur
iso-title = Atlas ISO'su oluştur
iso-beta = Beta
iso-beta-description = ISO'yu bir bilgisayarda kullanmadan önce sanal makinede deneyin. Windows'u yüklemeden önce dosyalarınızı yedekleyin.
iso-admin-description = Atlas'ın Windows ISO'nuzu okuyup yenisini oluşturabilmesi için yönetici izni gerekiyor. Yönetici olarak yeniden aç'ı seçin, ardından Windows sorduğunda Evet'i seçin.
iso-files-description = Atlas, Windows'u yeniden yükleyebilmeniz için bir Windows 11 ISO'sunun Atlas eklenmiş bir kopyasını oluşturur. Microsoft'tan indirilmiş bir Windows 11 ISO'su seçin, en son Atlas paketini indirin veya elinizdeki bir paketi (.apbx) seçin, ardından yeni ISO'nun kaydedileceği yeri seçin.
# Tester build: no package picker.
iso-files-description-bundled = Atlas, bir Windows 11 ISO'sunun bu test sürümüyle gelen Atlas paketi eklenmiş bir kopyasını oluşturur. Microsoft'tan indirilmiş bir Windows 11 ISO'su seçin, ardından yeni ISO'nun kaydedileceği yeri seçin.
iso-source = Windows ISO'su
iso-source-download = Windows 11'i Microsoft'tan indir
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Atlas paketi ({ $minimum } veya daha yeni)
iso-output = Yeni ISO'nun kaydedileceği konum
iso-no-file = Dosya seçilmedi
iso-browse = Gözat
iso-save-as = Farklı kaydet
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = Dosyaları denetle
iso-mode-title = Atlas'ı nasıl kurmak istiyorsunuz?
iso-mode-interactive = Atlas seçimlerini oturum açtıktan sonra yap
iso-mode-interactive-description = Oturum açtıktan sonra Atlas açılır ve güncellemelerde, seçimlerinizde ve Atlas'ın kurulumunda size yol gösterir.
iso-mode-before = Atlas seçimlerini şimdi yap
iso-mode-before-description = Atlas seçimlerinizi ISO'ya kaydeder. Oturum açtıktan sonra Atlas açılır ve güncellemelerde size yol gösterir, ardından Atlas'ı bu seçimlerle kurarsınız.
iso-package-unsupported-title = Daha yeni bir Atlas paketi seçin
# "Atlas seçimlerini oturum açtıktan sonra yap" is iso-mode-interactive.
iso-package-unsupported = Bu Atlas paketi, Atlas seçimlerini ISO'ya kaydedemez. Daha yeni bir paket seçin veya Atlas seçimlerini oturum açtıktan sonra yap seçeneğini belirleyin.
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = Bu Atlas paketi ISO oluşturmak için kullanılamaz. Atlas { $minimum } veya daha yeni bir sürüme ait bir paket seçin.
# Tester build: the bundled Atlas package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = Atlas seçimleri bu ISO'ya kaydedilemez
# "Atlas seçimlerini oturum açtıktan sonra yap" is iso-mode-interactive.
iso-package-unsupported-bundled = Bu test sürümüyle gelen Atlas paketi ISO kurulumunu desteklemiyor. Bunun yerine Atlas seçimlerini oturum açtıktan sonra yap seçeneğini belirleyin.
iso-atlas-options = Atlas seçimleri
iso-review = ISO'yu gözden geçir
iso-review-description = ISO oluşturmak bu bilgisayara hiçbir şey kurmaz ve orijinal ISO'nuzu değiştirmez. Ardından Atlas, Windows'u yeniden yükleyebilmeniz için yeni ISO'yu bir USB sürücüsüne yazabilir.
iso-review-files = Dosyalar
iso-step-windows = Windows kurulumu
iso-step-review = İnceleme
iso-review-package = Atlas paketi
iso-review-output = Yeni ISO
iso-review-editions = Sürümler
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Hesap adı
iso-review-target = Yükleme hedefi
iso-review-drivers = Sürücüler
iso-create = ISO oluştur
iso-progress-title = ISO'nuz oluşturuluyor
iso-stage-inspect = Windows ISO'nuz denetleniyor
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
iso-progress-description = Atlas'ı açık tutun. Büyük görüntülerin işlenmesi zaman alabilir.
iso-cancel = Oluşturmayı iptal et
iso-cancelling = İptal için güvenli bir durma noktası bekleniyor
iso-cancelled = ISO oluşturma iptal edildi
iso-cancelled-description = Orijinal ISO'nuz değişmedi. Geride geçici dosyalar kaldıysa nerede olduklarını görmek için Günlük klasörünü aç'ı seçin.
iso-complete = ISO'nuz hazır
iso-complete-description = ISO oluşturma beta aşamasında olduğu için ISO’yu önce bir sanal makinede deneyin. Ardından Kurulum USB’si oluştur’u seçin ve Windows’u yeniden yüklemeden önce dosyalarınızı yedekleyin.
iso-open-folder = Klasörde göster
iso-failed = ISO oluşturma tamamlanamadı
iso-failed-description = Dosyalarınızın hâlâ seçtiğiniz yerde olduğundan ve kaydettiğiniz sürücünün bağlı olduğundan emin olun, ardından ISO oluştur'u seçin. Sorun devam ederse Rapor gönder'i seçin.
# Title while the Check files step fails; the messages below say why.
iso-check-failed = Dosyalar denetlenemedi
iso-check-failed-description = ISO'nun ve Atlas paketinin hâlâ seçtiğiniz yerde olduğundan ve indirilmelerinin bittiğinden emin olun, ardından Dosyaları denetle'yi seçin. Sorun devam ederse Rapor gönder'i seçin.
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas'ın ISO oluşturmak için izne ihtiyacı var
# Typed reasons reported by the image worker.
iso-failed-output-exists = Bu adda bir dosya zaten var. Farklı kaydet'i seçip yeni bir dosya adı girin.
iso-failed-destination = Atlas yeni ISO'yu oraya kaydedemiyor. Farklı kaydet'i seçin ve bu bilgisayarda İndirilenler gibi bir klasör seçin. Ağ konumları ve birçok USB sürücüsü gibi FAT32 ya da exFAT olarak biçimlendirilmiş sürücüler kullanılamaz.
iso-failed-space = Hedef sürücüde yeterli boş alan yok. Alan boşaltın veya yeni ISO'yu başka bir sürücüye kaydedin.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = Bu ISO desteklenen bir Windows sürümü içermiyor. Windows Home ve LTSC desteklenmez. Pro, Education veya Enterprise gibi başka bir sürüm içeren bir ISO kullanın.
iso-failed-customised = Bu ISO zaten autounattend.xml gibi özel kurulum dosyaları içeriyor. Microsoft'tan alınmış, değiştirilmemiş bir Windows ISO'su seçin.
iso-failed-windows-unsupported = Bu Windows görüntüsü Atlas paketi tarafından desteklenmiyor. Bu paketin desteklediği bir Windows 11 sürümünün değiştirilmemiş, 64 bit ISO’sunu kullanın.
iso-failed-network-architecture = Bu bilgisayarın ağ sürücüleri bu ISO'nun mimarisiyle eşleşmiyor. Geri dönüp Bu bilgisayarın ağ sürücülerini ekle seçeneğini kapatın veya bu bilgisayar için bir ISO seçin.
iso-failed-unstaged = Atlas çalışma klasörünü hazırlayamadı, bu yüzden hiçbir şey değiştirilmedi. Yeniden deneyin. Sorun devam ederse hata raporu için Tanılama verilerini dışa aktar’ı seçin.
iso-failed-package-changed = Dosyalar denetlendikten sonra Atlas paketi değişti. Dosyalar’ın yanındaki Değiştir’i, ardından Dosyaları denetle’yi seçin.
iso-diagnostics = Günlük klasörünü aç
iso-close-title = ISO oluşturma devam ediyor
iso-close-message = Oluşturma veya iptal işlemi bitene kadar bu pencereyi açık tutun. İptal işlemi, mevcut işlemin güvenle durdurulabileceği noktayı bekler.
iso-keep-open = Açık tut
# Card title. Turkish uses a noun phrase so that other messages can name the card
# ("Windows ve Store güncellemeleri kartında"); an imperative title reads as an instruction there.
prepare-title = Windows ve Store güncellemeleri
prepare-description = Atlas, kurulumdan önce Windows’u, Microsoft Store’u ve Store uygulamalarınızı günceller. Not Defteri, Paint veya Windows Terminal gibi açık Store uygulamaları güncellenirken kapanabilir; bu yüzden önce bu uygulamalardaki çalışmanızı kaydedin. Bilgisayarınızın yeniden başlatılması da gerekebilir.
prepare-complete = Atlas, yüklenecek başka Windows veya Store güncellemesi bulmadı.
prepare-reboot-title = Devam etmek için bilgisayarınızı yeniden başlatın
prepare-reboot = Güncellemelerin yüklenmesini tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor. Atlas şimdiye kadarki seçimlerinizi kaydeder ve oturum açtıktan sonra yeniden açılır.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = Güncellemelerin yüklenmesini tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor ({ $reasons }). Atlas şimdiye kadarki seçimlerinizi kaydeder ve oturum açtıktan sonra yeniden açılır.
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = Önce çalışmanızı kaydedin ve uygulamalarınızı kapatın. Yeniden başlat ve devam et’i seçtiğiniz anda bilgisayarınız yeniden başlar.
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = Bilgisayarınız yeniden başladı, ancak Windows hâlâ yeniden başlatılması gerektiğini bildiriyor ({ $reasons }); bu yüzden yeniden başlatmak büyük olasılıkla işe yaramaz. Windows Update'i aç'ı seçin ve orada bekleyenleri tamamlayın, ardından Yeniden dene'yi seçin. Bekleyen bir şey yoksa Rapor gönder'i seçin.
# Names of the markers Windows sets when it wants a restart. They complete
# "Güncellemelerin yüklenmesini tamamlamak için bilgisayarınızın yeniden başlatılması gerekiyor (…)";
# keep them short and lower case where the language allows.
prepare-reason-servicing = Windows bileşen bakımı
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = değiştirilmeyi bekleyen dosyalar
prepare-reason-update-agent = Windows Update hizmeti
prepare-reason-unknown = neden bildirilmedi
prepare-failed = Yeniden dene’yi seçin. Yine başarısız olursa kalan güncellemeleri Windows Update’te veya Microsoft Store’da tamamlayın ya da Rapor gönder’i seçin.
prepare-failed-title = Bazı güncellemeler tamamlanamadı
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "Yeniden dene" is common-try-again, the button beside it.
prepare-ended-unconfirmed = Güncelleme bir sonuç bildirmeden durdu, bu yüzden Atlas, Windows ve Store uygulamalarının güncel olduğunu doğrulayamıyor. Güncellemeleri denetlemek için Yeniden dene’yi seçin.
prepare-unconfirmed-title = Güncelleme sonucu doğrulanamadı
# "Güncellemeleri denetle ve yükle" is prepare-start, its button in this state.
prepare-cancelled = Güncelleme durdu. Bazı güncellemeler yüklenmiş olabilir. Devam etmeden önce güncellemeyi bitirmek için Güncellemeleri denetle ve yükle’yi seçin.
prepare-windows-search = Windows güncellemeleri denetleniyor…
prepare-windows-download = Windows güncellemeleri indiriliyor…
prepare-windows-install = Windows güncellemeleri yükleniyor…
prepare-store-search = Microsoft Store denetleniyor…
prepare-store-install = Microsoft Store ve uygulamaları güncelleniyor…
prepare-stop-description = Atlas, geçerli adım bittikten sonra durur. O zamana kadar Atlas’ı açık tutun.
prepare-stop = Güncellemeyi durdur
prepare-restart = Yeniden başlat ve devam et
prepare-start = Güncellemeleri denetle ve yükle
# Under the update button while it is unavailable because this installation can't continue.
prepare-blocked-source = Bu kurulum devam edemediği için kullanılamıyor. Sayfanın üst kısmındaki iletiye bakın.
# Under the update button while it is unavailable. $check is the title of the check
# that must pass first: check-supported-build or check-administrator.
prepare-needs-build-check = Bilgisayar denetimlerinde { $check } denetimi geçtiğinde kullanılabilir.
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = Kurulum dosyaları hazır olduğunda kullanılabilir.
iso-username = Yerel hesap adı
iso-account-description = Windows kurulumu bu adla yerel bir hesap oluşturur, böylece Microsoft hesabına ihtiyacınız olmaz. Windows, ilk kez oturum açtığınızda bir parola belirlemenizi ister.
iso-username-placeholder = Adınız
iso-account-empty = Devam etmek için bir yerel hesap adı girin
iso-account-invalid = En fazla 20 karakter kullanın. Başta veya sonda boşluk olmamalı ve şunların hiçbiri bulunmamalı: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = Ad nokta ile bitemez.
iso-account-reserved = Windows bu adı yerleşik bir hesap için kullanıyor. Başka bir ad seçin.
iso-privacy-defaults = Bu ISO, Windows kurulumundaki lisans, Microsoft hesabı ve gizlilik ekranlarını atlar; isteğe bağlı veri paylaşımını ve kişiselleştirilmiş teklifleri kapatır.
prepare-drivers = Sürücüler nasıl yüklensin?
prepare-drivers-auto = Sürücüleri Windows Update’ten al
prepare-drivers-auto-detail = Windows, donanımınız için sürücüleri bulur. Çoğu bilgisayar için önerilir.
prepare-drivers-manual = Sürücüleri kendim yükleyeceğim
prepare-drivers-manual-detail = Windows Update sürücü yüklemez; bu yüzden sürücüleri bilgisayarınızın veya cihazınızın üreticisinden edinmeniz gerekir. Yüklü sürücüler korunur.
prepare-drivers-description = Sürücüler, Windows’un grafik, ses ve Wi-Fi gibi donanımlarınızı kullanmasını sağlar. Güncellemeden sonra bunu değiştirirseniz Atlas’ın güncellemeleri yeniden denetlemesi gerekir.
prepare-network-needed = Güncellemeler için tarifeli olmayan bir internet bağlantısı gerekir. Wi-Fi’ye veya Ethernet’e bağlanın, ardından Yeniden dene’yi seçin. Hiç Wi-Fi ağı görmüyorsanız önce ağ sürücünüzü yükleyin.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows, bu ağın internet erişimi olmadığını bildiriyor. Ağ sizden oturum açmanızı isterse oturum açın veya yönlendiricinizi ve varsa DNS ya da güvenlik duvarı filtrelemesini denetleyin, ardından tekrar deneyin.
# "Tarifeli bağlantı" is the switch's name in Windows network settings.
prepare-network-metered = Bu bağlantı tarifeli veya bir veri sınırına sahip. Tarifeli olmayan bir ağa bağlanın veya ağ ayarlarında Tarifeli bağlantı seçeneğini kapatın, ardından tekrar deneyin.
prepare-network-settings = Ağ ayarlarını aç
iso-target-title = Windows’u hangi bilgisayara yeniden yükleyeceksiniz?
iso-target-this = Bu bilgisayara
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas, bu bilgisayarın Wi-Fi ve Ethernet sürücülerini ISO’ya ekleyebilir; böylece Windows yeniden yüklendikten hemen sonra internete bağlanabilir.
iso-target-other = Başka bir bilgisayara
iso-copy-network = Bu bilgisayarın ağ sürücülerini ekle
iso-network-detail = Windows kurulumu sırasında bu bilgisayarın Wi-Fi ve Ethernet sürücülerini kullanır. Kurulumdan sonra Wi-Fi’ye yeniden bağlanmanız gerekir.
iso-network-source = Ağ sürücüsü kaynağı
iso-network-installed = Yüklü sürücüleri kullan
iso-network-updated = Önce Windows Update’i denetle
iso-network-updated-detail = Windows Update’in sunduğu uygun sürücüleri indirir ve yüklü sürücüleri yedek olarak saklar. Tarifeli olmayan bir bağlantı gerekir.
iso-stage-network-drivers = Ağ sürücüleri hazırlanıyor
iso-network-failed = Ağ sürücüleri hazırlanamadı. Tanılama verilerini denetleyin veya geri dönüp ağ sürücüsü seçeneğini değiştirin.
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = Bu bilgisayarın ağ bağdaştırıcıları Windows ile birlikte gelen sürücüleri kullanıyor, bu yüzden ISO’nun bunları içermesi gerekmiyor.
iso-mode-desktop = Masaüstünden önce kurulumu tamamla
iso-mode-desktop-description = Atlas seçimlerinizi ISO’ya kaydeder. Oturum açtıktan sonra Atlas, Windows masaüstü açılmadan önce güncellemeleri ve kurulumu tamamlar.
desktop-setup-description = Bilgisayarınızın kurulumunu tamamlayın. Atlas seçimleriniz kaydedildi; gerekirse Windows’a dönebilirsiniz.
desktop-setup-exit = Windows’ta devam et

# Windows installation USB (Beta)
usb-title = Kurulum USB’si oluştur
usb-existing = Mevcut bir ISO’dan USB oluştur
usb-description = Windows’u yeniden yükleyebilmeniz için bir ISO’yu USB sürücüsüne yazın. Atlas’ı aynı anda kurmak için Atlas ile oluşturulmuş bir ISO kullanın.
usb-choose-iso = ISO seç
usb-drive = USB sürücüsü
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = USB sürücüsü bulunamadı. En az { $min } GB boyutunda bir USB sürücüsü bağlayın, ardından Yenile’yi seçin. { $max } TB üzerindeki sürücüler, salt okunur sürücüler ve Windows’un çalıştığı sürücü gösterilmez.
usb-refresh = Yenile
# Shown when the drive list could not be read.
usb-scan-failed = Sürücünün bağlı olduğundan emin olun, ardından Yenile’yi seçin. Ayrıntılar için Günlük klasörünü aç’ı seçin.
usb-scan-failed-title = USB sürücüleri listelenemedi
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = Seri numarası: { $serial }
usb-detail-separator = { " · " }
usb-review = USB’yi gözden geçir
usb-erase-title = Bu USB sürücüsü silinsin mi?
usb-erase-description = { $drive } ({ $size } GB) üzerindeki tüm dosyalar ve bölümler dahil her şey kalıcı olarak silinecek. Saklamak istediğiniz her şeyi önce başka bir sürücüye kopyalayın. ISO dosyanız silinmeyecek.
usb-layout = Atlas sürücüde en fazla 32 GB alan kullanır ve kalan alanı kullanmaz. USB sürücüsü, Windows 11’in gerektirdiği UEFI modunda başlayan bilgisayarlarda çalışır.
usb-ack = Bu USB sürücüsündeki her şeyin silineceğini anlıyorum
usb-write = Sil ve USB oluştur
usb-stage-prepare = Kurulum dosyaları hazırlanıyor…
usb-stage-format = USB biçimlendiriliyor…
usb-stage-copy = Kurulum dosyaları kopyalanıyor…
usb-stage-verify = USB doğrulanıyor…
usb-working = Atlas’ı açık, USB sürücüsünü bağlı tutun. İptal ederseniz tamamlanmamış bir USB sürücüsüyle Windows yüklenemez.
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = USB oluşturma tamamlanamadı
usb-complete-title = USB’niz hazır
usb-close-title = USB oluşturma devam ediyor
# After erasing may have begun.
usb-failed = Sürücü zaten silinmiş olabilir, bu yüzden henüz Windows yüklemek için kullanılamaz. Sürücünün bağlı olduğundan emin olun, ardından yeniden denemek için USB’yi gözden geçir’i seçin. Sürücüyü yeniden bağladıysanız önce Yenile’yi seçip sürücüyü yeniden seçin.
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = USB sürücünüz değiştirilmedi. Neyin başarısız olduğunu görmek için Günlük klasörünü aç’ı seçin, ardından yeniden denemek için USB’yi gözden geçir’i seçin.
usb-failed-iso = Bu ISO ile kurulum USB’si oluşturulamaz. Atlas ile oluşturulmuş bir ISO veya Microsoft’tan alınmış, Atlas’ın desteklediği bir sürüme ait Windows 11 ISO’su seçin. USB sürücünüz değiştirilmedi.
usb-failed-location = ISO dosyası veya Atlas Manager bu USB sürücüsünde, bir ağ konumunda ya da bağlantılı bir klasörde. Dosyayı bu bilgisayardaki yerel bir klasöre taşıyın, ardından yeniden deneyin. USB sürücünüz değiştirilmedi.
usb-failed-space = Windows sürücüsünde kurulum dosyalarını hazırlamak için yeterli boş alan yok. Alan boşaltın, ardından yeniden deneyin. USB sürücünüz değiştirilmedi.
usb-failed-fit = Kurulum dosyaları bu USB sürücüsüne sığmıyor. Daha büyük bir sürücü kullanın, ardından yeniden deneyin. USB sürücünüz değiştirilmedi.
usb-failed-drive-changed = USB sürücüsü, liste okunduktan sonra çıkarıldı, yeniden bağlandı veya yerine başka bir sürücü takıldı. Yenile’yi seçin, sürücüyü yeniden seçin, ardından USB’yi gözden geçir’i seçin. USB sürücünüz değiştirilmedi.
usb-cancelled = Sürücüde eksik kurulum dosyaları bulunabilir. Windows yüklemeden önce USB’yi yeniden oluşturun.
usb-cancelled-title = USB oluşturma iptal edildi
usb-cancelled-unchanged = USB sürücünüz değiştirilmedi.
usb-complete = Atlas her dosyayı denetledi. USB’yi çıkar’ı seçin, ardından Windows’u yeniden yükleyeceğiniz bilgisayardaki dosyaları yedekleyin. Sürücüyü o bilgisayara takın, ardından bilgisayarı önyükleme menüsünü kullanarak USB sürücüsünden başlatın (bilgisayar açılırken genellikle F12, F11 veya Esc).
usb-eject = USB’yi çıkar
usb-ejected = USB sürücüsünü artık çıkarabilirsiniz. Windows’u yeniden yükleyeceğiniz bilgisayardaki dosyaları yedekleyin. Ardından o bilgisayarı önyükleme menüsünü kullanarak USB sürücüsünden başlatın (açılırken genellikle F12, F11 veya Esc).
usb-eject-failed = Sürücüyü kullanan dosyaları veya pencereleri kapatıp yeniden deneyin.
usb-eject-failed-title = USB çıkarılamadı
ready-fresh-title = Atlas, temiz bir Windows kurulumu için tasarlandı
ready-fresh-description = Bu bilgisayarda Windows’u zaten kullanıyorsanız devam etmeden önce dosyalarınızı yedekleyin ve Windows’u yeniden yükleyin. Desteklenen bir sürümü yeniden yüklemek için önce Bilgisayar denetimlerinde Windows uyumluluğu denetiminin geçtiğinden emin olun.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 Home, LTSC ve Server sürümleri desteklenmez. Pro, Education veya Enterprise gibi başka bir sürüm kullanın. Windows sürümünüzü belirleyemediyse devam etmeden önce bu sorunu çözün.
install-source-title = Kurulum kullanılamıyor
install-source-unsupported = Atlas { $source }, doğrudan { $target } sürümüne güncellenemez. Bu sürümü kullanmak için dosyalarınızı yedekleyin ve Windows'u yeniden yükleyin.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } doğrudan güncellenemez. Daha yeni bir sürümü kullanmak için dosyalarınızı yedekleyin ve Windows'u yeniden yükleyin.
# "Paket dosyası aç" is package-open-file. $folder is a folder path (text).
install-source-resume = Atlas { $target } kurulumu yarım kaldı ve bu kurulumu yalnızca Atlas { $target } paketi tamamlayabilir. Paket dosyası aç'ı seçip o Atlas paketini (.apbx) seçin. Dosyayı Atlas indirdiyse { $folder } klasöründedir.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } kurulumu yarım kaldı. Bu test sürümü yalnızca birlikte gelen Atlas paketini kurabilir, bu yüzden bu kurulumu Atlas Manager'ın bir yayın sürümünde Atlas { $target } paketiyle tamamlayın.
install-source-unknown = Atlas bu bilgisayarda neyin kurulu olduğunu doğrulayamadı, bu yüzden şimdilik hiçbir şey kurmayacak. Atlas ekibinin yardımcı olabilmesi için Rapor gönder'i seçin.
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } Ayrıntılar: { $error }
iso-edition-selection = Yalnızca desteklenen sürümler dahil edilir. Windows kurulumu sırasında Windows lisansınızın bulunduğu sürümü seçin.
detail-windows-preview = Insider derlemeleri desteklenmiyor. Windows 11’in genel kullanıma sunulan bir sürümünü kullanın.
detail-windows-release-unknown = Atlas, bu Windows derlemesinin genel kullanıma sunulduğunu doğrulayamadı. İnternete bağlanıp yeniden denetleyin.
iso-release-unknown = Atlas, bu ISO’nun Atlas paketinin desteklediği ve genel kullanıma sunulmuş bir Windows 11 sürümü olduğunu doğrulayamadı. İnternete bağlanın, ardından Dosyaları denetle’yi yeniden seçin. Sorun devam ederse ISO’yu Microsoft’tan yeniden indirin.
prepare-previous-worker = Daha önce başlayan güncellemeler hâlâ sürüyor. Atlas bunların bitmesini bekleyecek, ardından güncellemeleri yeniden denetleyebilirsiniz.

ready-used-windows-title = Bu bilgisayardaki Windows kullanılmış görünüyor
ready-used-windows-description = Bu bilgisayardaki Windows en az bir hafta önce yüklenmiş veya zaten birkaç uygulama içeriyor. Atlas’ı buraya kurmak desteklenmez ve kesinlikle önerilmez: mevcut uygulamalarınız ve ayarlarınız beklendiği gibi çalışmayabilir; ayrıca Atlas OneDrive’ı kaldırır, bu yüzden OneDrive’daki dosyaların eşitlenmesi durur ve Masaüstü, Belgeler ve Resimler klasörleriniz boş görünebilir. Önce dosyalarınızı yedekleyip Windows’u yeniden yükleyin veya yalnızca riski kabul ediyorsanız devam edin.
ready-used-windows-dismiss = Yine de devam et

prepare-resumed = Bilgisayarınız yeniden başladı ve Atlas şimdiye kadarki seçimlerinizi geri yükledi. Atlas’ı kurmadan önce güncellemeyi bitirmek için Güncellemelere devam et’i seçin.
prepare-continue = Güncellemelere devam et
prepare-saving-restart = Seçimleriniz kaydediliyor ve Windows yeniden başlatıldıktan sonra Atlas’ın açılması ayarlanıyor…
prepare-restart-save-failed = Seçimleriniz kaydedilemedi. Yeniden başlatmadan önce tekrar deneyin.
prepare-restart-registration-failed = Seçimleriniz kaydedildi, ancak Atlas yeniden başlatmadan sonra kendini açılacak şekilde ayarlayamadı. Tekrar deneyin veya bilgisayarınızı kendiniz yeniden başlatıp oturum açtıktan sonra Atlas’ı açın.
prepare-restart-failed = Atlas bilgisayarınızı yeniden başlatamadı. Tekrar deneyin veya Başlat menüsünden yeniden başlatın. Seçimleriniz kaydedildi ve Atlas, oturum açtıktan sonra yeniden açılır.
diagnostics-export = Tanılama verilerini dışa aktar
diagnostics-exporting = Tanılama verileri toplanıyor…
diagnostics-privacy = Atlas ekibine özel olarak rapor gönderin veya yardım isterken paylaşmak için bir tanılama ZIP dosyası dışa aktarın. Atlas bu dosyadan kullanıcı adınızı, bilgisayar adınızı ve e-posta adreslerini kaldırır.
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Tanılama ZIP dosyası oluşturuldu
diagnostics-failed-title = Tanılama verileri dışa aktarılamadı
# $error is the raw error (text).
diagnostics-failed = Bilgisayarınızda yeterli boş disk alanı olduğundan emin olun, ardından yeniden deneyin. Ayrıntılar: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Atlas { $release } test sürümü. Bu uygulama yalnızca birlikte gelen Atlas paketini kurar.
home-status-bundled = Test sürümü { $release }
package-bundled = Bu test sürümüyle gelen Atlas { $version } kuruluma hazır.
rc-about-release = Test sürümü
rc-about-commit = Kaynak commit
rc-about-package = Birlikte gelen Atlas paketi (SHA-256)
iso-package-bundled = Bu test sürümüyle gelen Atlas paketi
prepare-percent = Bu aşamanın %{ $percent } kadarı
prepare-count = Tamamlanan güncellemeler: { $completed } / { $total }
prepare-bytes = Yaklaşık { $total } MB verinin { $downloaded } MB kadarı indirildi
prepare-elapsed = Geçen süre: { $minutes } dk { $seconds } sn
prepare-progress-waiting = Güncelleme hizmeti bekleniyor. Bu adım için yüzde bilgisi mevcut değil.
prepare-progress-unchanged = { $minutes } dk boyunca ilerleme olmadı. Büyük güncellemeler zaman alabilir, bu yüzden Atlas’ı açık tutun. Ayrıntılar için Günlük klasörünü aç’ı seçin.
prepare-report-delayed = Windows { $seconds } sn boyunca ilerleme bildirmedi. Güncellemeler hâlâ sürüyor olabilir, bu yüzden Atlas’ı açık tutun.

prepare-affected-app = etkilenen uygulamayı
prepare-app-in-use = Önce { $app } ve pencerelerini kapatın, ardından tekrar deneyin. Uygulama açıkken Windows onu güncelleyemez. Penceresini bulamıyorsanız uygulamayı Görev Yöneticisi’nden kapatın. Yine başarısız olursa bilgisayarınızı yeniden başlatın ve uygulamayı açmadan önce tekrar deneyin.
prepare-install-busy = Başka bir kurulum veya gerekli bir yeniden başlatma güncellemeleri engelliyor. Diğer kurulumların bitmesini bekleyin, Windows isterse bilgisayarınızı yeniden başlatın, ardından tekrar deneyin.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas, Windows’ta oturum açmış hesaptan farklı bir hesapla çalışıyor. Windows’ta bir yönetici hesabıyla oturum açın, Atlas’ı o hesaptan açın ve tekrar deneyin.
prepare-failed-store-missing = Microsoft Store hesabınız için ayarlanmamış. Microsoft Store’u bir kez açın veya eksikse yeniden yükleyin, ardından tekrar deneyin.
prepare-failed-store-battery = Microsoft Store, pil tasarrufu için güncellemeleri duraklattı. Bilgisayarınızı fişe takın, ardından tekrar deneyin.
prepare-failed-store-network = Microsoft Store, bilgisayarınız tarifeli olmayan bir bağlantı kullanana kadar güncellemeleri duraklattı. Tarifeli olmayan bir Wi-Fi veya Ethernet ağına bağlanın, ardından tekrar deneyin.
prepare-failed-store-timeout = Store uygulamalarının güncellenmesi tamamlanmadı. Kalan indirmeleri Microsoft Store’da tamamlayın, ardından tekrar deneyin.
prepare-failed-store-passes = Microsoft Store yeni güncellemeler sunmaya devam etti. Kalan güncellemeleri Microsoft Store’da tamamlayın, ardından tekrar deneyin.
prepare-failed-manual-updates = Bazı Windows güncellemelerinin Windows Update’te tamamlanması gerekiyor. Windows Update’i açıp bunları tamamlayın, ardından tekrar deneyin.
prepare-failed-windows-passes = Windows Update yeni güncellemeler sunmaya devam etti. Kalan güncellemeleri Windows Update’te tamamlayın, ardından tekrar deneyin.
prepare-error-code = Hata kodu: { $code }
prepare-open-store = Microsoft Store’u aç

check-user-account = Kullanıcı hesabı
detail-user-account-ok = UAC açık ve hesabınız kuruluma hazır.
detail-user-account-not-ready = Kullanıcı Hesabı Denetimi’ni (UAC) açın, bilgisayarınızı yeniden başlatın ve tekrar deneyin. Yerleşik Administrator hesabını kullanıyorsanız başka bir yönetici hesabıyla oturum açın.
detail-user-account-unknown = Atlas kullanıcı hesabınızı denetleyemedi. Kurulumdan önce tekrar denetleyin. Windows bildirimi: { $error }

footer-prepare-required = Devam etmek için Windows ve Store uygulamalarını güncellemeyi bitirin
footer-prepare-stopping = Güncellemeler geçerli adımdan sonra durduruluyor…
resume-choices-title = Önceki kurulumunuza devam ediliyor
resume-choices-detail = Atlas, o kurulumu tamamlamak için geçen sefer yaptığınız seçimleri geri yükledi. Kurulum bitene kadar bunları Seçimleriniz adımında değiştiremezsiniz.

## Voluntary reports
report-title = Rapor gönder
report-received = Rapor alındı
report-reference = Bu rapor hakkında Atlas ekibiyle iletişime geçerseniz kullanmak için bu referansı saklayın. İletişim bilgisi bıraktıysanız ekip size yanıt vermek için bu bilgileri kullanabilir, ancak yanıt verileceği garanti edilmez.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Rapor referansını kopyala
report-another = Başka bir rapor gönder
# Label of the choice between the two kinds of report.
report-kind = Ne göndermek istiyorsunuz?
report-kind-issue = Bir sorun
report-kind-suggestion = Bir öneri
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = Ne olduğunu veya neyin değişmesini istediğinizi açıklayın ({ $min }–{ $max } karakter). Mesajınıza parola yazmayın.
report-message = Mesajınız
report-message-placeholder = Şunu yapmaya çalışıyordum…
report-contact = İletişim bilgileri (isteğe bağlı)
report-contact-placeholder = E-posta veya Discord kullanıcı adı
report-attach = Tanılama verilerini ekle
report-attach-description = Sorunun nedenini bulmaya yardımcı olan günlükler ve sistem ayrıntıları. Atlas kullanıcı adınızı, bilgisayar adınızı, e-posta adreslerini ve bilinen parolaları veya anahtarları kaldırır. Hata ayrıntıları, donanım modelleri ve uygulama adları kaldırılmaz. Göndermeden önce ZIP’i inceleyebilirsiniz.
report-prepare = Tanılama verilerini hazırla
report-review = ZIP’i incele
report-prepare-failed-title = Tanılama verileri hazırlanamadı
# $error is a raw error message (text).
report-prepare-failed = Tanılama verilerini yeniden hazırlayın veya raporunuzu tanılama verileri olmadan göndermek için Tanılama verilerini ekle seçeneğini kapatın. Ayrıntılar: { $error }
report-privacy = Raporunuz reports.atlasos.net üzerinden Atlas ekibine özel olarak gönderilir. Mesajınız ve iletişim bilgileriniz yazdığınız gibi gönderilir. Ekip, incelemeye yardımcı olması için başka şirketlerin yapay zekâ hizmetlerini kullanabilir. Bu hizmetler mesajınızı ve tanılama verilerini alır, ancak iletişim bilgilerinizi almaz. Raporlar 90 gün sonra silinir ve sunucu güvenlik günlükleri IP adresinizi kaydedebilir.
report-website = Gizlilik ve rapor sitesi
report-consent = Bu raporu ve varsa eklenen tanılama verilerini Atlas ekibine göndermeyi kabul ediyorum
report-failed = Mesajınız hâlâ burada. İnternet bağlantınızı denetleyin, ardından Yeniden dene’yi seçin veya raporunuzu rapor sitesinden gönderin.
report-failed-busy = Rapor hizmeti meşgul. Mesajınız hâlâ burada. Daha sonra tekrar deneyin.
report-failed-outdated = Atlas Manager’ın bu sürümü artık rapor gönderemiyor. Mesajınız hâlâ burada: kopyalayıp rapor sitesine yapıştırın. Tanılama verilerini eklediyseniz ZIP’i incele’yi seçin ve ZIP’i de oraya ekleyin.
report-failed-diagnostics = Hazırlanan tanılama verileri gönderilemiyor. Mesajınız hâlâ burada. Tanılama verilerini yeniden hazırlayın veya Tanılama verilerini ekle seçeneğini kapatın.
# Link under a report that wasn't sent.
report-failed-website = Rapor sitesini aç
report-sending = Gönderiliyor…
report-send = Rapor gönder

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = { $min }–{ $max } karakter girin.

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = İletişim bilgilerini { $max } karakterle sınırlayın.

report-validation-consent = Bu raporu göndermeyi kabul ettiğinizi onaylayın.

report-failed-title = Rapor gönderilmedi

## Windows version update
home-plan-intro = Bu güncelleştirme iki bölümden oluşur. Dosyalarınız ve uygulamalarınız korunur. Windows'u güncelleştirmek Atlas'ın değişikliklerinden bazılarını geri alırsa Atlas bunları yeniden uygular.
home-plan-windows-title = Windows 11, sürüm { $release }
home-plan-windows-detail = Atlas bunu Windows Update'ten yükler. Tamamlamak için bilgisayarınız yeniden başlar.
home-plan-windows-optional = Önerilir. Atlas bunu Windows Update'ten yükler. Tamamlamak için bilgisayarınız yeniden başlar.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-detail = Atlas dosyalarını güncelleştirir ve yaptığınız seçimleri korur. Sonunda bilgisayarınız yeniden başlar.
home-end-of-updates-title = Windows 11 { $current } sürümü için güvenlik güncelleştirmeleri { $date } tarihinde sona eriyor
home-end-of-updates-past-title = Windows 11 { $current } sürümü artık güvenlik güncelleştirmesi almıyor
home-end-of-updates-message = Atlas { $version } sürümüne güncelleştirmek bu bilgisayarı Windows 11 { $release } sürümüne de geçirir. Bu sürüm { $until } tarihine kadar güvenlik güncelleştirmeleri alır.
install-windows-edition = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır. Bu bilgisayarda { $product } yüklü, bu yüzden Atlas bu bilgisayara kurulamaz.
install-windows-edition-ending = Atlas { $version } sürümü Windows 11 Pro, Enterprise ve Education ile çalışır. Bu bilgisayarda { $product } yüklü, bu yüzden Atlas bu bilgisayara kurulamaz. Windows 11 { $current } sürümü için güvenlik güncelleştirmeleri { $date } tarihinde sona eriyor. Windows Update bu bilgisayarı daha yeni bir sürüme geçirebilir.
install-windows-no-path = Atlas { $version } sürümü için Windows 11 { $releases } sürümü gerekiyor ve Windows Update bu bilgisayarı mevcut Windows'tan bu sürüme geçiremiyor. Atlas { $version } sürümünü kullanmak için dosyalarınızı yedekleyin ve Windows'u bir Atlas ISO'suyla yeniden yükleyin.
home-update-access-title = Atlas güncelleştirmesi için Windows Update ayarları değiştirildi
home-update-access-not-offered = Atlas, bu bilgisayarı Windows 11 { $release } sürümüne geçirmek için Windows Update'i açtı, ancak Windows Update bu sürümü henüz sunmadı. Yeniden denetle'yi veya Ayarları geri yükle'yi seçin.
home-update-access-before = Atlas, bu bilgisayarı Windows 11 { $release } sürümüne geçirmek için Windows Update'i açtı ve işlemi henüz bitirmedi. Güncelleştirmeye devam edin veya Ayarları geri yükle'yi seçin.
home-update-access-after = Bu bilgisayarda Windows 11 { $release } sürümü var. Atlas kurulumunu tamamlayın veya Ayarları geri yükle'yi seçin.
home-update-access-plain = Atlas, güncelleştirmeleri yüklemek için Windows Update'i açtı ve işlemi henüz bitirmedi. Güncelleştirmeye devam edin veya Ayarları geri yükle'yi seçin.
home-update-access-unreadable = Atlas, değiştirdiği Windows Update ayarlarının kaydını okuyamıyor, bu yüzden hiçbir şeyi değiştirmeyecek veya geri yüklemeyecek. Atlas ekibinin yardımcı olabilmesi için Rapor gönder'i seçin.
home-update-access-failed = Atlas ayarları geri yükleyemedi. Yeniden deneyin veya Rapor gönder'i seçin. Ayrıntılar: { $error }
home-update-access-install-active = Önce Atlas kurulumunu tamamlayın. Kurulumun son adımı bu ayarları geri yükler.
home-continue-update = Güncelleştirmeye devam et
home-put-back = Ayarları geri yükle
home-putting-back = Ayarlar geri yükleniyor…
windows-card-title = Windows 11, sürüm { $release }
windows-card-required = Atlas { $version } sürümü için daha yeni bir Windows sürümü gerekiyor. Atlas aşağıda Windows'u güncelleştirirken Windows Update'ten Windows 11 { $release } sürümünü de yükler.
windows-card-question = Bu bilgisayar hangi Windows sürümünü kullansın?
windows-choice-move = Windows 11 { $release } sürümüne güncelleştir
windows-choice-move-detail = Önerilir. { $date } tarihine kadar güvenlik güncelleştirmeleri. Bir yeniden başlatma daha.
windows-choice-keep = Windows 11 { $current } sürümünde kal
windows-choice-keep-detail = Bilgisayarınız bu sürümde kalır. Windows Update onu daha yeni bir sürüme geçirmez, bu yüzden daha sonra geçmek için Atlas Manager'da ayrı bir güncelleştirme gerekir.
windows-card-facts = Neler değişir
windows-fact-keep = Dosyalarınız ve uygulamalarınız korunur. Güncelleştirme Atlas'ın değişikliklerinden bazılarını geri alırsa Atlas, kurulurken bunları yeniden uygular.
windows-fact-restart = Tamamlamak için bilgisayarınız en az bir kez daha yeniden başlar.
transition-offer-expectation = Windows Update bu sürümü genellikle birkaç dakika içinde sunar, ancak bu 2 saate kadar sürebilir; Atlas sizin yerinize bekler ve denetler.
windows-fact-stays = Sonrasında Windows { $release } sürümünde kalır ve kendiliğinden daha yeni bir sürüme geçmez.
windows-fact-removed = { $release } sürümünde Windows PowerShell 2.0 ve WMIC aracı yer almaz.
# Güncelleştirme geçmişi (Update history), Geri dön (Go back) and Sistem > Kurtarma are
# Windows' own Turkish labels.
windows-card-undo = Daha sonra geri almak için güncelleştirmeyi Windows Update > Güncelleştirme geçmişi bölümünden kaldırın. Windows güncelleştirme sırasında kendini yeniden yüklediyse bunun yerine 10 gün içinde Ayarlar > Sistem > Kurtarma bölümünde Geri dön'ü seçin. Atlas { $version } sürümü { $current } sürümünü desteklemez, bu yüzden Atlas { $version } kurulduktan sonra bu güncelleştirmeyi geri almayın.
windows-card-undo-optional = Daha sonra geri almak için güncelleştirmeyi Windows Update > Güncelleştirme geçmişi bölümünden kaldırın. Windows güncelleştirme sırasında kendini yeniden yüklediyse bunun yerine 10 gün içinde Ayarlar > Sistem > Kurtarma bölümünde Geri dön'ü seçin.
windows-terms = Windows 11 { $release } sürümü için Microsoft Yazılım Lisans Koşulları'nı kabul ediyorum
windows-terms-link = Lisans koşullarını oku
windows-card-locked = { $current } sürümünde kalmak için İptal'i, ardından Güncellemeyi durdur'u seçin.
prepare-description-transition = Atlas, kurulumdan önce Windows'un beklediği güncelleştirmeleri, ardından Windows 11 { $release } sürümünü yükler, sonra da Microsoft Store'u ve Store uygulamalarınızı güncelleştirir. Açık Store uygulamaları güncelleştirilirken kapanabilir; bu yüzden önce bu uygulamalardaki çalışmanızı kaydedin. Bilgisayarınız en az bir kez yeniden başlar.
prepare-start-transition = Windows'u { $release } sürümüne güncelleştir
prepare-needs-terms = Windows 11, sürüm { $release } kartında lisans koşullarını kabul ettiğinizde kullanılabilir.
ready-banner-not-offered-message = Şimdi neler yapabileceğinizi görmek için Windows ve Store güncellemeleri kartına bakın.
ready-banner-transition-failed-message = Sonra ne yapmanız gerektiğini görmek için Windows ve Store güncellemeleri kartına bakın.
ready-banner-terms-title = Devam etmek için lisans koşullarını kabul edin
ready-banner-terms-message = Koşullar bu sayfanın aşağısındaki Windows 11, sürüm { $release } kartında. Ardından Windows'u { $release } sürümüne güncelleştir'i seçin.
access-notice-title = Atlas, Windows Update'i geçici olarak açıyor
access-off = Windows Update bu bilgisayarda kapalı. Atlas, Windows'u güncelleştirirken onu yeniden açar.
access-paused = Windows güncelleştirmeleri bu bilgisayarda duraklatılmış. Atlas, Windows'u güncelleştirirken bunları sürdürür.
access-delayed = Aylık güncelleştirmeler bu bilgisayarda ertelenmiş. Atlas, Windows'u güncelleştirirken ertelemeyi kaldırır.
access-back-chosen = Atlas { $version } kurulduğunda bu ayarlar seçtiğiniz şekle döner.
access-back = Atlas { $version } kurulduğunda bu ayarlar eski hâline döner.
access-back-stop = Bundan önce durdurursanız Atlas bunları geri yükler.
prepare-reboot-transition = Windows 11 { $release } sürümü yüklendi. Yüklemeyi tamamlamak için Yeniden başlat ve devam et'i seçin. Oturum açtıktan sonra Atlas yeniden açılır.
prepare-reboot-commit = { $release } sürümünün yüklenmesini tamamlamak için Windows'un bir kez daha yeniden başlatılması gerekiyor. Oturum açtıktan sonra Atlas yeniden açılır.
prepare-restart-commit-failed = Windows, { $release } sürümünü yeniden başlatma sırasında tamamlanacak şekilde hazırlayamadı, bu yüzden bilgisayarınız yeniden başlamadı. Yeniden denemek için Yeniden başlat ve devam et'i seçin.
prepare-reason-feature-update = yeni Windows sürümü
prepare-reason-feature-commit = yeni Windows sürümünün tamamlanması
prepare-resumed-transition = Bilgisayarınız yeniden başladı. Atlas'ın Windows 11 { $release } sürümünün tamamlandığını denetlemesi ve kalan güncelleştirmeleri yüklemesi için Güncellemelere devam et'i seçin.
prepare-waiting-offer = Windows Update'in Windows 11 { $release } sürümünü sunması bekleniyor. Bu genellikle birkaç dakika sürer, ancak 2 saate kadar sürebilir. Bilgisayarınızı kullanmaya devam edebilirsiniz; Atlas'ı açık bırakın.
prepare-resumed-before-move = Bilgisayarınız, güncelleştirmelerin yüklenmesini tamamlamak için yeniden başladı. Atlas'ın kalan güncelleştirmeleri, ardından Windows 11 { $release } sürümünü yükleyebilmesi için Güncellemelere devam et'i seçin.
prepare-not-offered-title = Windows Update'in Windows 11 { $release } sürümünü sunması bekleniyor
prepare-transition-failed-title = Windows, { $release } sürümüne geçemedi
prepare-failed-feature-not-offered = Windows Update'in Windows 11 { $release } sürümünü bir bilgisayara sunması biraz zaman alabilir. Bilgisayarınızda hâlâ { $current } sürümü var.
prepare-offer-rechecking = Atlas her 10 dakikada bir yeniden denetler ve Windows Update bu sürümü sunar sunmaz kendiliğinden devam eder. Yeniden denetle'yi de seçebilirsiniz.
prepare-offer-waited =
    { $minutes ->
        [one] { $minutes } dakikadır bekleniyor.
       *[other] { $minutes } dakikadır bekleniyor.
    }
prepare-offer-next-check =
    { $minutes ->
        [one] Sonraki denetim { $minutes } dakika sonra.
       *[other] Sonraki denetim { $minutes } dakika sonra.
    }
prepare-offer-checking-now = Şimdi denetleniyor.
prepare-offer-check-again = Şimdi denetlemek için Yeniden denetle'yi seçin.
prepare-offer-wait-ended-title = Windows Update, Windows 11 { $release } sürümünü henüz sunmadı
prepare-offer-wait-ended = Windows Update, Windows 11 { $release } sürümünü 2 saat içinde sunmadı, bu yüzden Atlas beklemeyi bıraktı ve Windows Update ayarlarınızı geri yükledi. Daha sonra Yeniden denetle'yi seçin. Bekleyemiyorsanız dosyalarınızı yedekleyin ve Windows'u bir Atlas ISO'suyla yeniden yükleyin.
prepare-offer-wait-put-back-failed = Windows Update, Windows 11 { $release } sürümünü 2 saat içinde sunmadı ve Atlas, Windows Update ayarlarınızı geri yükleyemedi. Yeniden denemek için Ayarları geri yükle'yi seçin. Ayrıntılar: { $error }
prepare-failed-feature-hardware = Bu bilgisayar Windows 11 donanım gereksinimlerini karşılamıyor ({ $missing }), bu yüzden Windows Update onu { $release } sürümüne geçirmez. Bilgisayarınızda hâlâ { $current } sürümü var. Atlas { $version } sürümünü kullanmak için dosyalarınızı yedekleyin ve Windows'u bir Atlas ISO'suyla yeniden yükleyin.
hardware-tpm = TPM 2.0
hardware-uefi = UEFI ürün yazılımı
prepare-failed-feature-hidden = Windows 11 { $release } sürümü bu bilgisayarda Windows Update'te gizlenmiş. Gizlemek için kullandığınız araçla yeniden gösterin, ardından Yeniden dene'yi seçin.
prepare-failed-feature-disk-space = Windows'un bu güncelleştirme için { $drive } sürücüsünde en az { $needed } GB boş alana ihtiyacı var, sürücüde ise { $free } GB boş alan var. Atlas hiçbir şeyi değiştirmedi. Alan boşaltın, ardından Yeniden dene'yi seçin.
prepare-failed-feature-servicing = Windows, bileşen deposunda onaramadığı bir hasar bildiriyor, bu yüzden Atlas hiçbir şeyi değiştirmedi. Windows'u onarın, ardından Yeniden dene'yi seçin.
prepare-failed-feature-managed = Bu bilgisayar güncelleştirmeleri bir kuruluşun güncelleştirme sunucusundan alıyor, bu yüzden Atlas onu { $release } sürümüne geçiremez. Atlas hiçbir şeyi değiştirmedi.
prepare-failed-feature-policy = Bu bilgisayardaki bir şey, Atlas değiştirdikten sonra şunu sürekli eski hâline getiriyor: { $setting }. Bu yüzden Atlas Windows'u güncelleştiremiyor. Bu bilgisayarı bir kuruluş yönetiyorsa kuruluşa danışın. Durdurduğunuzda Atlas değiştirdiklerini geri yükler.
prepare-failed-feature-blocked = Atlas'ın değiştirmediği bir ayar Windows Update'in çalışmasını engelliyor: { $setting }. Windows Update'in çalışabilmesi için bu ayarı değiştirin, ardından Yeniden dene'yi seçin.
prepare-failed-feature-rolled-back = Windows, { $release } sürümünün yüklenmesini yeniden başlatma sırasında tamamlayamadı ve { $current } sürümüne geri döndü. Dosyalarınız ve uygulamalarınız etkilenmedi. Yeniden dene'yi veya Rapor gönder'i seçin.
prepare-failed-feature-components-lost = Windows güncelleştirmesinden sonra Atlas'ın bazı değişiklikleri kayboldu ve Windows'un kendini yeniden yüklediğine dair bir iz yok, bu yüzden Atlas ne olduğunu anlayamıyor. Atlas { $version } kurulmadı. Atlas ekibinin yardımcı olabilmesi için Rapor gönder'i seçin.
prepare-failed-feature-build = Atlas bu bilgisayarı güncelleştirirken Windows sürümü değişti. Ayarları geri yükle'yi seçin, ardından Giriş sayfasından baştan başlayın.
prepare-failed-feature-journal = Atlas, değiştirdiği Windows Update ayarlarının kaydını okuyamıyor, bu yüzden hiçbir şeyi değiştirmeyecek veya geri yüklemeyecek. Atlas ekibinin yardımcı olabilmesi için Rapor gönder'i seçin.
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo (text).
prepare-failed-feature-pin = Bu bilgisayardaki bir Windows Update ilkesinin ({ $setting }) değeri Atlas'ın kaydedemeyeceği türden, bu yüzden Atlas hiçbir şeyi değiştirmedi. Atlas ekibinin yardımcı olabilmesi için Rapor gönder'i seçin.
prepare-failed-feature-terms = Windows 11 { $release } sürümünün lisans koşullarını kabul edin, ardından Yeniden dene'yi seçin.
prepare-failed-feature-failed = Windows, { $release } sürümünü yükleyemedi. Bilgisayarınızda hâlâ { $current } sürümü var. Yeniden dene'yi seçin. Yine başarısız olursa Rapor gönder'i seçin.
prepare-check-again = Yeniden denetle
prepare-keep-version = { $current } sürümünde kal
stop-update-title = Atlas { $version } sürümüne güncelleştirme durdurulsun mu?
stop-update-before = Atlas, değiştirdiği Windows Update ayarlarını geri yükler. Windows'un zaten yüklediği güncelleştirmeler yüklü kalır ve bilgisayarınız Windows 11 { $current } sürümünde kalır.
stop-update-after = Bilgisayarınız Windows 11 { $release } sürümünde kalır. Atlas, değiştirdiği Windows Update ayarlarını geri yükler.
stop-update-access = Atlas, değiştirdiği Windows Update ayarlarını geri yükler. Windows'un zaten yüklediği güncelleştirmeler yüklü kalır.
stop-update-keep = Güncelleştirmeye devam et
window-close-update-access-title = Atlas kapatılsın mı?
window-close-update-access-message = Atlas kapanmadan önce değiştirdiği Windows Update ayarlarını geri yükler. Güncelleştirmeye Giriş sayfasından yeniden başlayabilirsiniz.
window-close-put-back = Geri yükle ve kapat
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Ayarlar geri yüklenmeden kapatılsın mı?
window-close-put-back-failed-message = Atlas'ı şimdi kapatırsanız Windows Update ayarları Atlas'ın değiştirdiği şekilde kalır. Atlas'ı yeniden açtığınızda Giriş sayfası bunları geri yüklemeyi önerir.
installed-update-off-again = Seçtiğiniz gibi Windows Update yeniden kapatıldı. Kapalıyken bilgisayarınız güvenlik güncelleştirmesi almaz.
installed-update-paused-again = Seçtiğiniz gibi Windows güncelleştirmeleri yeniden duraklatıldı. Duraklatılmışken bilgisayarınız güvenlik güncelleştirmesi almaz.
detail-build-transition = Bu bilgisayarda, bu Atlas sürümünün desteklemediği Windows 11 { $current } sürümü var. Atlas aşağıda Windows'u güncelleştirirken Windows'u { $release } sürümüne geçirir.
report-transition-intro = Atlas için Windows güncelleştirmesi tamamlanmadı. Atlas ekibi için ayrıntılar:
mode-rebase = Windows güncelleştirmesinden sonra yeniden kurulum
history-mode-rebase = Windows güncelleştirmesinden sonra yeniden kurulum
ready-rebase-title = Windows güncelleştirme sırasında kendini yeniden yükledi
ready-rebase-message = Windows 11 { $release } sürümü bu bilgisayardaki önceki Windows'un yerini aldı, bu yüzden Atlas'ın bazı değişiklikleri kayboldu. Atlas { $version }, Atlas { $previous } için yaptığınız seçimlerle bunları yeniden uygular.
upgrade-choices-title = Atlas { $previous } sürümündeki seçimleriniz
upgrade-choices-detail = Atlas, Atlas { $previous } sürümünün bu bilgisayarda ayarladıklarından yola çıktı. Güncelleştirme bu seçimlerin yaptıklarını korur, bu yüzden burada bir ek özelliğin işaretini kaldırmak onu geri almaz. Birini daha sonra değiştirmek için Atlas klasörünü veya Windows Ayarları'nı kullanın.
rebase-choices-title = Atlas { $previous } sürümündeki seçimleriniz
rebase-choices-detail = Atlas, Atlas { $previous } için yaptığınız seçimleri kullanır, bu yüzden burada seçilecek bir şey yok. Bunları daha sonra Atlas klasöründen değiştirebilirsiniz.
rebase-choices-partial = Atlas, Atlas { $previous } için yaptığınız seçimleri kullanır. Şunları bulamadı, bu yüzden bunları denetleyin: { $missing }
restart-other-title = Bu bilgisayarda başka biri oturum açmış
restart-others-title = Bu bilgisayarda başka kişiler oturum açmış
restart-others-message = Yeniden başlatma onların uygulamalarını kapatır ve kaydedilmemiş çalışmaları kaybolur. Oturum açmış olanlar: { $names }.
# "Yeniden başlatma" alone would read as the noun "restart", so the button says what it cancels.
restart-others-keep = Yeniden başlatmaktan vazgeç
restart-others-restart = Yine de yeniden başlat
prepare-store-self-update = Önce Microsoft Store güncelleştiriliyor. Bu bilgisayardaki sürümü güncel değil.
prepare-store-repair = Microsoft Store onarılıyor. Bu birkaç dakika sürebilir.
prepare-store-updated = Microsoft Store güncel değildi, bu yüzden Atlas onu uygulamalarınızdan önce güncelleştirdi.
prepare-store-bootstrapped = Microsoft Store kendini güncelleştiremedi, bu yüzden Atlas en son Uygulama Yükleyicisi'ni ve Microsoft Store'u Microsoft'tan yükledi.
prepare-store-repaired = Microsoft Store çalışmıyordu, bu yüzden Atlas onu onardı.
prepare-store-skipped-removed = Microsoft Store bu bilgisayarda kapalı, bu yüzden Atlas Store uygulaması güncelleştirmelerini atladı.
prepare-failed-store-repair-failed = Microsoft Store çalışmıyor ve Atlas onu onaramadı. Yeniden denemek için Microsoft Store'u onar'ı seçin. Yine çalışmazsa Rapor gönder'i seçin.
prepare-repair-store = Microsoft Store'u onar

screen-keyboard-title = Klavye dilleri
screen-keyboard-question = Birden fazla klavye dili kullanıyor musunuz?
playbook-option-keyboard-shortcuts = Evet, klavye kısayollarıyla
playbook-option-keyboard-selector = Evet, görev çubuğundaki seçiciyle
playbook-option-keyboard-single = Hayır, tek bir klavye düzeni kullanıyorum
consequence-keyboard-shortcuts = Alt+Shift dili, Ctrl+Shift klavye düzenini değiştirir.
consequence-keyboard-selector = Oyun sırasında yanlışlıkla geçiş yapmamak için Alt+Shift ve Ctrl+Shift kapatılır.
playbook-page-keyboard-shortcuts-description = Klavye dilini nasıl değiştireceğinizi seçin.
consequence-keyboard-single = { consequence-keyboard-selector }
