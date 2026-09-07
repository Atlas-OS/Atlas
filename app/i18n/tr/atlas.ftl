### Atlas Manager: Turkish (tr). Preview translation, revised on 6 September 2026 from the en-GB source (i18n/en-GB/atlas.ftl).
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
# Accessible description of a disabled control.
common-not-available = Şu anda kullanılamıyor
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

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Atlas kurulurken pencere kapatılsın mı?
window-close-message = Kurulum arka planda devam eder. İlerlemeyi ve sonucu görmek için Atlas'ı yeniden açın. Kurulum bitene kadar bilgisayarınızı açık tutun.
window-close-keep = Açık tut
window-close-close = Pencereyi kapat
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Atlas playbook dosyası aç (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas kuruldu. Kurulumu tamamlamak için Windows yeniden başlatılıyor.

## System

# "Windows 11 Pro 25H2 (yapı 26200.1234)". All three values are text.
system-description = { $product } { $version } (yapı { $build })

## Home page

home-not-installed = Atlas'a hoş geldiniz
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = { $date } tarihinde kuruldu
home-status-checking = Güncelleştirmeler denetleniyor
home-status-offline = Güncelleştirmeler denetlenemedi
home-status-not-checked = Güncelleştirmeler henüz denetlenmedi
home-status-update = Atlas { $version } kullanılabilir
home-status-up-to-date = Güncel
home-status-newest = En son sürüm: Atlas { $version }
home-check-again = Yeniden denetle
# Primary button while an install is running or waiting.
home-show-install = İlerlemeyi görüntüle
home-continue-installing = Kuruluma devam et
home-update-to = Atlas { $version } sürümüne güncelleştir
home-reinstall = Atlas'ı yeniden kur
home-install = Atlas'ı kur
home-start-over = Baştan başla
home-security-reminder-title = Korumayı yeniden açın
home-security-reminder-message = Çalışan bir kurulum yok. Windows Güvenliği'ni açın ve Kurcalama Koruması, gerçek zamanlı koruma, bulut tabanlı koruma ve otomatik örnek gönderimi anahtarlarını yeniden açın.
home-elevation-title = Atlas'ın kurulum için izne ihtiyacı var
home-state-error-title = Atlas kurulum bilgileriniz okunamadı
home-whats-new = Atlas { $version } sürümündeki yenilikler
home-view-release = Sürüm notlarını GitHub'da görüntüle
home-released = { $date } tarihinde yayımlandı
home-show-less = Daha az göster
home-show-full-notes = Tüm sürüm notlarını göster
home-your-install = Atlas kurulumunuz
# Row label: how Atlas was set up.
home-set-up = Kurulum yöntemi
home-set-up-during-oobe = Windows kurulumu sırasında
home-history = Kurulum geçmişi
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Bilgisayarınızı Atlas için hazırlayalım
home-step-1-title = Bilgisayarınızı denetleyin
home-step-1-detail = Atlas, Windows'u denetler ve kurulum dosyalarını indirir. Windows ayarlarınız olduğu gibi kalır.
home-step-2-title = Seçimlerinizi yapın
home-step-2-detail = Windows'un korumayı ve güncelleştirmeleri nasıl yöneteceğini seçin, ardından isterseniz ek uygulama ve ayarlar ekleyin.
home-step-3-title = Virüsten korumayı geçici olarak kapatın
home-step-3-detail = Atlas, kurulumu engellememeleri için Windows Güvenliği'ndeki dört koruma anahtarını kapatmanızda size yol gösterir.
home-step-4-title = Kurun ve yeniden başlatın
home-step-4-detail =
    { $minutes ->
        [one] Yaklaşık bir dakika.
       *[other] Yaklaşık { $minutes } dakika.
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
notice-session-unreadable-title = Önceki kurulum denetlenemedi
# $path is a file path (text).
notice-session-unreadable-message = Atlas, { $path } dosyasını okuyamıyor; bu dosya olmadan bir kurulumun hâlâ sürüp sürmediğini bilemez. Emin değilseniz dosyayı silmeden önce Atlas topluluğundan yardım alın. Dosyayı yalnızca çalışan bir kurulum olmadığından emin olduktan sonra silip yeniden deneyin. Ayrıntılar: { $error }

## Administrator elevation

elevation-declined = İzin verilmedi. Yeniden deneyin ve Windows, Atlas'ın değişiklik yapmasına izin vermenizi istediğinde Evet'i seçin.
elevation-declined-continue = İzin verilmedi. Yeniden deneyin ve Windows, Atlas'ın değişiklik yapmasına izin vermenizi istediğinde Evet'i seçin. Kurulum seçimleriniz kaydedildi.
elevation-draft-not-saved = Atlas kurulum seçimlerinizi kaydedemedi, bu yüzden yeniden açılmadı. Yeniden deneyin. Ayrıntılar: { $error }

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
# Heading above each step's content.
step-heading = Adım { $number } / { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = Bilgisayarınız hazırlanıyor
ready-banner-busy-message = Atlas bilgisayarınızı denetliyor ve kurulum dosyalarını hazırlıyor.
ready-banner-blocked-title = Bilgisayarınızın biraz hazırlanması gerekiyor
ready-banner-blocked-message = Aşağıdaki yönergeleri uygulayın, sonra Yeniden denetle'yi seçin.
ready-banner-no-package-title = Devam etmek için Atlas'ı indirin
ready-banner-no-package-message = Aşağıdan en son sürümü indirin veya kayıtlı bir Atlas playbook dosyası (.apbx) açın.
ready-banner-warnings-title = Gözden geçirmeniz gereken birkaç nokta var
ready-banner-warnings-message = Devam etmeden önce aşağıdaki notları okuyun ve önerilen adımları uygulayın.
ready-banner-ok-title = Seçimlerinizi yapmaya hazırsınız
ready-banner-ok-message = Denetimler geçti ve kurulum dosyalarınız hazır.

# Card title and accessible name of the list of checks.
ready-this-pc = Bilgisayar denetimleri
ready-check-again = Yeniden denetle

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
package-none = Henüz kurulum dosyası yok. Playbook (.apbx), Atlas'ın ihtiyaç duyduğu yönergeleri ve dosyaları içerir.
# Short status words beside the card title.
package-status-downloading = İndiriliyor
package-status-unpacking = Açılıyor
package-status-failed = Dosyalar hazırlanamadı
package-status-ready = Hazır
package-status-checking = Denetleniyor
package-status-missing = İndirilmedi
# Accessible name of the progress bar.
package-progress = Kurulum dosyalarının ilerlemesi
package-download-again = Yeniden indir
package-download-version = Atlas { $version } sürümünü indir
package-download-newest = En son sürümü indir
package-open-file = Playbook dosyası aç
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } GitHub'dan indirildi ve kuruluma hazır.
package-from-file = Atlas { $version }, { $file } dosyasından yüklendi ve kuruluma hazır.
package-unpacked = Atlas { $version } kuruluma hazır.
package-at = Kurulum dosyaları: { $path }
package-none-yet = Kurulum dosyası seçilmedi
acquire-no-asset = Atlas { $version } sürümü için indirilebilecek bir playbook dosyası yok. Devam etmek için kayıtlı bir Atlas playbook dosyası (.apbx) açın.
acquire-unsupported = Bu uygulama Atlas 0.6.0 ve sonraki sürümleri kurabilir. Atlas { $version } sürümünü kurmak için AME Wizard'ı kullanın.
acquire-failed = Kurulum dosyaları hazırlanamadı. Yeniden indirmeyi deneyin veya başka bir Atlas playbook dosyası (.apbx) açın. Ayrıntılar: { $error }

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
# Check boxes the user ticks when a check could not run.
check-ack-updates = Windows Update'i denetledim: yüklenmeyi bekleyen güncelleştirme yok
check-ack-reboot = Windows'u yeniden başlattım ve başka yeniden başlatma gerekmiyor
check-ack-internet = Bu bilgisayar internete bağlı
check-ack-generic = Bu gereksinimi kendim denetledim

detail-admin-ok = Atlas, kurulum için gereken değişiklikleri yapma iznine sahip.
detail-admin-missing = Atlas'ı yönetici olarak yeniden açın, ardından Windows izin istediğinde Evet'i seçin.
# $builds is a list of build numbers such as "26100 veya 26200"; $build is this PC's (text).
detail-build-unsupported = Bu Atlas sürümü için Windows { $builds } yapısı gerekiyor. Bilgisayarınızda { $build } yapısı var. Devam etmeden önce desteklenen bir Windows sürümü yükleyin.
detail-updates-none = Yüklenmeyi bekleyen Windows güncelleştirmesi yok.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Önce şu güncelleştirmeyi yükleyin: { $titles }.
        [2] Önce şu güncelleştirmeleri yükleyin: { $titles }.
       *[other] Önce { $titles } dahil { $count } güncelleştirmeyi yükleyin.
    }
detail-updates-unknown = Windows güncelleştirmeleri denetlenemedi. Windows Update'i açın; bekleyen güncelleştirme yoksa aşağıda onaylayın. ({ $error })
detail-reboot-none = Windows'un şu anda yeniden başlatılması gerekmiyor.
detail-reboot-pending = Önceki değişiklikleri tamamlamak için bilgisayarınızı yeniden başlatın, ardından Atlas'ı yeniden açıp yeniden denetleyin.
detail-reboot-unknown = Windows'un yeniden başlatılması gerekip gerekmediği denetlenemedi. Bilgisayarınızı yeniden başlatın, ardından Atlas'ı yeniden açıp yeniden denetleyin. ({ $error })
detail-antivirus-none = Başka bir virüsten koruma yazılımı algılanmadı.
# $products is a list of product names (text).
detail-antivirus-found = Virüsten koruma yazılımı kurulumu engelleyebilir: { $products }. Devam etmeden önce bu yazılımı kaldırın.
detail-antivirus-unknown = Diğer virüsten koruma yazılımları denetlenemedi. Devam etmeden önce yüklü uygulamalarınızı gözden geçirin. ({ $error })
detail-internet-ok = İnternete bağlısınız. Atlas yazılımları indirip kurarken bu bağlantıyı açık tutun.
detail-internet-missing = İnternete bağlanın, sonra yeniden denetleyin.
detail-power-mains = Bilgisayarınız fişe takılı. Kurulum bitene kadar takılı bırakın.
detail-power-battery = Kurulum boyunca açık kalması için bilgisayarınızı fişe takın.
detail-power-unknown = Güç kaynağı denetlenemedi. Dizüstü bilgisayar kullanıyorsanız devam etmeden önce fişe takın.
detail-activation-ok = Windows etkin. Atlas bunu değiştirmez.
detail-activation-missing = Windows etkin değil. Devam edebilirsiniz, ancak Atlas Windows'u sizin için etkinleştirmez.
detail-activation-no-licence = Windows bir lisans bildirmedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez.
detail-activation-unknown = Windows etkinleştirmesi denetlenemedi. Devam edebilirsiniz; Atlas etkinleştirme durumunuzu değiştirmez. ({ $error })

## Step 2: Options

options-progress = Seçim { $number } / { $total }
options-progress-extras = Seçim { $number } / { $total }: isteğe bağlı ek özellikler
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Virüsten koruma açık kalsın mı?
screen-mitigations-title = İşlemci güvenliği
screen-mitigations-question = Windows'un işlemci korumaları açık kalsın mı?
screen-updates-title = Windows Update
screen-updates-question = Windows güncelleştirmeleri nasıl yüklesin?
screen-browser-title = Tarayıcı
screen-power-title = Güç ve güvenlik
screen-apps-title = Uygulamalar
screen-optional-apps-title = İsteğe bağlı uygulamalar
screen-choose-one-title = Bir seçenek belirleyin
screen-extras-title = İsteğe bağlı ek özellikler
screen-extras-question = İstediğiniz ek özellikleri seçin
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } için bir seçenek belirleyin
learn-more-defender = Microsoft Defender hakkında daha fazla bilgi
learn-more-mitigations = İşlemci güvenliği hakkında daha fazla bilgi
learn-more-updates = Windows Update hakkında daha fazla bilgi
learn-more-browser = Tarayıcılar hakkında daha fazla bilgi
learn-more-power = Güç ve güvenlik hakkında daha fazla bilgi
learn-more-apps = Uygulamalar hakkında daha fazla bilgi
learn-more-eclean = eclean, AtlasOS ile nasıl çalışır?
learn-more-generic = Kurulum kılavuzunu oku
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Bilgisayarınızı virüslerden ve diğer tehditlerden korumaya yardımcı olan yerleşik Windows virüsten koruma yazılımını tutar.
consequence-defender-disable = Microsoft Defender'ı kaldırır. Başka bir virüsten koruma uygulaması yükleyene kadar bilgisayarınızda virüsten koruma olmaz.
consequence-mitigations-default = İşlemcinizin çalışma biçiminden yararlanan saldırılara karşı Windows'un varsayılan korumalarını tutar.
consequence-mitigations-disable = Bu korumaları kapatır ve güvenliği azaltır. Performans işlemcinize bağlıdır ve kötüleşebilir.
consequence-auto-updates-disable = Windows Update'i açıp güncelleştirmeleri kendiniz yüklemeniz gerekir. Güncelleştirme bildirimleri açık kalır.
consequence-auto-updates-default = Windows, güvenlik düzeltmeleri dahil güncelleştirmeleri otomatik olarak yükler.

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender'ı tut (önerilir)
playbook-option-defender-disable = Microsoft Defender'ı kaldır
playbook-option-mitigations-default = Varsayılan korumaları tut (önerilir)
playbook-option-mitigations-disable = İşlemci korumalarını kapat
playbook-option-auto-updates-disable = Güncelleştirmeleri kendim yükleyeyim
playbook-option-auto-updates-default = Güncelleştirmeleri otomatik olarak yükle
playbook-option-disable-hibernation = Hazırda bekletmeyi kapat
playbook-option-disable-power-saving = Güç tasarrufunu kapat
playbook-option-disable-core-isolation = Sanallaştırma tabanlı güvenliği (VBS) kapat
playbook-option-remove-snipping-tool = Ekran Alıntısı Aracı'nı kaldır
playbook-option-uninstall-edge = Microsoft Edge'i kaldır
playbook-option-install-another-browser = Tarayıcı yükle
playbook-option-install-toolbox = Atlas Toolbox'ı yükle
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender, Windows'un yerleşik virüsten koruma yazılımıdır. Tutulması önerilir. Yalnızca riskleri anlıyor ve başka bir virüsten koruma uygulaması kullanmayı planlıyorsanız kaldırın.
playbook-page-mitigations-default-description = Azaltma (mitigation) olarak da bilinen bu korumalar, işlemcideki güvenlik açıklarına karşı savunmaya yardımcı olur. Windows varsayılanlarının tutulması önerilir.
playbook-page-auto-updates-disable-description = Windows güncelleştirmeleri güvenlik düzeltmeleri içerir. Windows'un bunları otomatik olarak yüklemesini sağlayabilir veya kendiniz yükleyebilirsiniz.
consequence-install-toolbox = Atlas ayarlarınızı yönetmenize yardımcı olması için Atlas Toolbox'ı ekleyin. Toolbox beta aşamasında olduğu için bazı özellikler henüz tamamlanmamış olabilir.
playbook-page-browser-brave-description = Yüklenecek bir tarayıcı seçin. Atlas tarayıcı ayarlarınızı değiştirmez.

## Step 3: Windows Security

security-banner-reading-title = Windows Güvenliği denetleniyor
security-banner-reading-message = Atlas aşağıdaki dört koruma anahtarını denetliyor.
security-banner-off-title = Dört koruma anahtarı da kapalı
security-banner-off-message = Artık kurulumdan önce seçimlerinizi gözden geçirebilirsiniz.
security-banner-readable-off-title = Atlas'ın denetleyebildiği anahtarlar kapalı
security-banner-readable-off-message = Kalan anahtarları Windows Güvenliği'nde denetleyin.
security-banner-on-title = Virüsten korumayı geçici olarak kapatın
security-banner-on-message = Bu korumalar, Atlas'ın yapması gereken değişiklikleri engelleyebilir.
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
security-unknown-message = Windows Güvenliği'nde dört anahtarın da kapalı olduğunu denetledikten sonra aşağıda onaylayın.
security-acknowledge = Windows Güvenliği'ni denetledim ve dört anahtar da kapalı
security-unknown-unelevated-title = Atlas'ın korumayı denetlemek için izne ihtiyacı var
security-unknown-unelevated-message = Microsoft Defender ayarlarını denetleyebilmesi için Atlas'ı yönetici olarak yeniden açın.
# The four switches, named as Windows Security names them in Turkish.
protection-tamper = Kurcalama Koruması
protection-tamper-why = Defender'ın koruma ayarlarında değişikliğe izin vermesi için önce bunu kapatın.
protection-realtime = Gerçek zamanlı koruma
protection-realtime-why = Defender'ın Atlas kurulum dosyalarını engellememesi için dosya taramasını duraklatın.
protection-cloud = Bulut tabanlı koruma
protection-cloud-why = Atlas kurulum dosyalarını engelleyebilecek çevrimiçi tehdit denetimlerini duraklatın.
protection-samples = Otomatik örnek gönderimi
protection-samples-why = Defender'ın Atlas dosyalarını analiz için Microsoft'a otomatik olarak göndermesini durdurun.

## Step 4: Install

install-preparing-title = Kurulumdan önce son bir denetim
install-preparing-message = Atlas değişiklik yapmadan önce bilgisayarınızı ve koruma ayarlarınızı yeniden denetliyor.
install-installing = Kuruluyor
install-running = Çalışıyor
# Accessible name of the progress bar.
install-progress = Kurulum ilerlemesi
phase-preflight = Bilgisayarınız denetleniyor ve dosyalar hazırlanıyor
phase-staging = Kurulum dosyaları kopyalanıyor. Windows henüz değiştirilmedi.
phase-applying = Windows ayarlanıyor. Bilgisayarınızı açık tutun.
phase-done = Kurulum tamamlanıyor
outcome-succeeded-title = Atlas kuruldu
outcome-lost-title = Kurulum sonucu doğrulanamadı
outcome-failed-title = Kurulum tamamlanmadı
outcome-succeeded = Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
outcome-requirements = Bilgisayarınız kurulum gereksinimlerini karşılamadı. Bilgisayarınızda hiçbir değişiklik yapılmadı. Hazırlık adımına dönüp denetimleri yeniden çalıştırın.
outcome-not-elevated = Bilgisayarınızda hiçbir değişiklik yapılmadı. Atlas'ı yönetici olarak yeniden açıp yeniden deneyin.
outcome-failed-preflight = Kurulum, henüz hiçbir şey değiştirilmeden durdu. Ne olduğunu görmek için günlük dosyasını açın, sonra yeniden deneyin.
outcome-failed-staging = Kurulum, dosyalar hazırlanırken durdu; Windows henüz değiştirilmedi. Ne olduğunu görmek için günlük dosyasını açın, sonra yeniden deneyin.
outcome-failed-applying = Bazı değişiklikler yapılmış olabilir. Burada duracaksanız, kapattığınız korumaları hâlâ mevcutsa Windows Güvenliği'nde yeniden açın.
outcome-not-started = Yükleyici zamanında başlamadı. Bilgisayarınızda hiçbir değişiklik yapılmadı. Yeniden dene'yi seçin.
outcome-lost = Yükleyici sonuç bildirmeden durdu ve bazı değişiklikler yapılmış olabilir. Ne olduğunu görmek için günlük dosyasını açın, sonra kaldığı yerden devam etmesi için Yeniden dene'yi seçin.
restart-now-message = Atlas kurulumunu tamamlamak için Windows yeniden başlatılıyor.
restart-countdown =
    { $seconds ->
        [one] Atlas kurulumunu tamamlamak için Windows { $seconds } saniye içinde yeniden başlatılacak.
       *[other] Atlas kurulumunu tamamlamak için Windows { $seconds } saniye içinde yeniden başlatılacak.
    }
restart-stopped = Otomatik yeniden başlatma iptal edildi. Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için bilgisayarınızı yeniden başlatın.
restart-needed = Çalışmanızı kaydedin, sonra Atlas kurulumunu tamamlamak için Windows'u yeniden başlatın.
restart-dont-now = Daha sonra yeniden başlat
restart-now = Şimdi yeniden başlat
# Accessible name of the countdown bar.
restart-progress = Yeniden başlatmaya kalan süre
restart-start-failed = Windows yeniden başlatılamadı. Çalışmanızı kaydedin, sonra Başlat menüsünden yeniden başlatın. Ayrıntılar: { $error }
preflight-title = Kurulum başlamadı
preflight-invalid-options = Atlas bu kurulum seçimlerini kullanamadı. Seçimleriniz adımına dönüp gözden geçirin, sonra yeniden deneyin. Ayrıntılar: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Bilgisayarınızın durumu önceki denetimlerden sonra değişti. Yeniden denemeden önce şunları çözün. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 tanesi hâlâ açık".
preflight-security = Windows Güvenliği: { $summary }.
preflight-busy = Başka bir Atlas penceresi kurulum başlatıyor. Biraz bekleyin, sonra yeniden deneyin.
preflight-record-unreadable = Atlas önceki kurulumun hâlâ sürüp sürmediğini denetleyemedi, bu yüzden yeni bir kurulum başlatmadı. Kurtarma yönergeleri için Atlas'ı kapatıp yeniden açın. Ayrıntılar: { $error }
preflight-refused = Yükleyici başlatılamadı. Bilgisayarınızda hiçbir değişiklik yapılmadı. Ayrıntılar: { $error }
go-to-ready = Hazırlık adımına dön
go-to-options = Seçimleriniz adımına dön
output-problem-title = Kurulum ilerlemesi okunamadı
output-problem-message = Atlas günlüğü okuyamadı. Bu, kurulumun durduğu anlamına gelmez. Bilgisayarınızı açık tutun ve günlük dosyasını açmayı deneyin. Ayrıntılar: { $error }
install-elevate-title = Atlas'ın kurulum için izne ihtiyacı var
install-no-package-title = Önce kurulum dosyalarınızı seçin
install-no-package-message = Atlas'ı indirmek veya kayıtlı bir playbook dosyası (.apbx) açmak için Hazırlık adımına dönün.
install-security-title = Kurulumdan önce virüsten korumayı denetleyin
install-security-reading = Dört koruma anahtarı yeniden denetleniyor.
install-security-message = { $summary }. Devam etmeden önce Windows Güvenliği'ni açıp dört anahtarın da kapalı olduğundan emin olun.
summary-this-install = Kurulum özeti
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
summary-command-unavailable = Kurulum komutu hazırlanamadı. Ayrıntılar: { $error }
summary-not-chosen = Henüz seçim yapılmadı
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } seçimini değiştir
footer-still-checking = Kuruluma hazırlanıyor
footer-fix-items = Devam etmek için yukarıdaki denetimleri tamamlayın
footer-need-package = Devam etmek için Atlas'ı indirin veya bir playbook açın
footer-reading-security = Koruma anahtarları denetleniyor
button-checking = Denetleniyor
button-installing = Kuruluyor
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

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } kuruldu
installed-title = Atlas kuruldu
installed-ready = Her şey tamam. Bilgisayarınız Atlas ile kullanıma hazır.
installed-open-atlas = Atlas kurulumunuzu görüntüle

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
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Windows ile aynı seçildiğinde: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Önizleme · dil incelemesi bekliyor
preview-notice = { $language } için önizleme çevirisi kullanılıyor.
preview-notice-switch = İngilizceye geç
preview-notice-language = Dili değiştir
# $tag is a language tag (text).
settings-language-unavailable = { $tag } bu Atlas sürümünde kullanılamıyor. Şimdilik İngilizce gösteriliyor; dil seçiminiz kaydedildi.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas, Windows görüntüleme dillerinizi ({ $languages }) henüz desteklemiyor. Şimdilik İngilizce gösteriliyor.
settings-language-windows-unavailable = Windows görüntüleme diliniz denetlenemedi. Atlas şimdilik İngilizce kullanıyor. Ayrıntılar: { $error }
# $locale is the regional format's own name, for example "Türkçe (Türkiye)".
settings-language-formats = Sayılar, tarihler ve saatler Windows bölgesel biçiminizi izler ({ $locale }).
settings-language-contribute = Atlas'ın çevirisine GitHub'da katkıda bulun
settings-installing = Kurulum
settings-restart-label = Kurulumdan sonra bilgisayarımı otomatik olarak yeniden başlat
settings-restart-locked = Bunu kurulum bittikten sonra değiştirebilirsiniz.
settings-restart-description = Kurulumu tamamlamak için yeniden başlatma gerekir. Otomatik yeniden başlatma açıksa kurulumdan önce çalışmanızı kaydedin.
settings-about = Hakkında
settings-about-app = Atlas Manager
settings-about-data = Uygulama dosyaları
settings-about-licence = Lisans
settings-about-licence-value = GPL-3.0, ücretsiz ve açık kaynak
settings-view-source = Kaynak kodunu GitHub'da görüntüle
settings-open-data-folder = Uygulama klasörünü aç

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Hazırda bekletme sırasında oturumunuzu kaydetmek için kullanılan disk alanını boşaltır. Hazırda bekletme ve Hızlı Başlatma kullanılamaz hale gelir.
consequence-disable-power-saving = Güç tasarrufu özelliklerini kapatır. Bilgisayarınız daha fazla güç tüketebilir, daha çok ısınabilir ve pil ömrü kısalabilir.
consequence-disable-core-isolation = Bellek bütünlüğü dahil ek bir Windows güvenlik katmanını kapatır. Bu, korumayı azaltır ve bu katmana ihtiyaç duyan uygulama veya oyunları etkileyebilir.
consequence-remove-snipping-tool = Ekran görüntüsü ve ekran kaydı almak için kullanılan Windows uygulamasını kaldırır.
consequence-uninstall-edge = Microsoft Edge tarayıcısını kaldırır. Başka bir tarayıcınız olduğundan emin olun veya aşağıdan birini seçin.
consequence-install-another-browser = Aşağıdan bir tarayıcı seçin; Atlas onu sizin için yükler.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas, arka plan etkinliğini ve dikkat dağıtan öğeleri azaltmak için Windows'ta ayarlamalar yapar. Değişiklik yapmadan önce denetimlerde ve seçimlerde size yol gösteririz.

detail-build-missing = Bu playbook desteklenen bir Windows yapısı belirtmiyor. LocalTest paketi yerine tam bir playbook yapısı seçin.
## ISO creation (Beta)
iso-home-title = Windows yükleme medyası
iso-home-description = Bu veya başka bir bilgisayara temiz kurulum yapmak için Atlas içeren bir Windows ISO'su oluşturun.
iso-open = Atlas ISO'su oluştur
iso-title = Atlas ISO'su oluştur
iso-beta = Beta
iso-beta-description = ISO'yu bir bilgisayarda kullanmadan önce sanal makinede deneyin. Windows'u yüklemeden önce dosyalarınızı yedekleyin.
iso-admin-description = Windows görüntülerini okumak ve yükleme medyası oluşturmak için yönetici erişimi gerekir.
iso-files-description = Değiştirilmemiş bir Windows 11 x64 ISO'su, bir Atlas playbook dosyası (.apbx) ve çıktı için yeni bir dosya adı seçin.
iso-source = Windows ISO'su
iso-package = Atlas playbook dosyası (0.6+)
iso-output = Yeni ISO'nun kaydedileceği konum
iso-no-file = Dosya seçilmedi
iso-browse = Gözat
iso-save-as = Farklı kaydet
iso-inspect = Dosyaları denetle
iso-mode-title = Windows ve Atlas tercihleri
iso-mode-interactive = Atlas ayarlarını oturum açtıktan sonra seçin
iso-mode-interactive-description = Oturum açtıktan sonra Atlas, Windows ve Store uygulamalarını güncellemenize, ayarlarınızı seçmenize ve Atlas’ı uygulamanıza yardımcı olur.
iso-mode-before = Atlas ayarlarını şimdi seçin
iso-mode-before-description = Atlas ayarlarınızı ISO’ya kaydedin. Oturum açtıktan sonra Windows ve Store uygulamalarını güncelleyin, ardından Atlas’ı bu ayarlarla uygulayın.
iso-package-unsupported-title = Daha yeni bir playbook seçin
iso-package-unsupported = ISO kurulumu için ISO desteği sunan Atlas 0.6 veya daha yeni bir sürüm gerekir. Uyumlu bir playbook seçin.
iso-atlas-options = Atlas ayarları
iso-review = ISO'yu gözden geçir
iso-review-description = Atlas ayrı bir ISO oluşturur ve orijinalini korur. Windows'u yüklemek için yeni ISO'dan önyükleme yapın. ISO oluşturmak bu bilgisayara Atlas yüklemez.
iso-review-files = Dosyalar
iso-review-package = Atlas playbook dosyası
iso-review-output = Yeni ISO
iso-review-editions = Sürümler
iso-review-size = Boyut
iso-review-size-value = { $size } MB
iso-review-account = Hesap adı
iso-review-target = Yükleme hedefi
iso-review-drivers = Sürücüler
iso-create = ISO oluştur
iso-stage-inspect = Windows görüntüsü denetleniyor
iso-stage-copy = Windows dosyaları kopyalanıyor
iso-stage-inject = Atlas ekleniyor
iso-stage-master = ISO oluşturuluyor
iso-stage-verify = Çıktı doğrulanıyor
iso-stage-cleanup = Tamamlanıyor
iso-progress-description = Uygulamayı açık tutun. Büyük görüntülerin işlenmesi zaman alabilir.
iso-cancel = Oluşturmayı iptal et
iso-cancelling = İptal için güvenli bir durma noktası bekleniyor
iso-cancelled = ISO oluşturma iptal edildi
iso-cancelled-description = Orijinal ISO'nuz korundu. Hâlâ silinmesi gereken geçici dosyalar varsa tanılama günlüğünde belirtilir.
iso-complete = ISO'nuz hazır
iso-complete-description = Önce sanal makinede deneyin, ardından Windows yükleme medyası oluşturmak için kullanın.
iso-open-folder = Klasörde göster
iso-failed = ISO oluşturma tamamlanamadı
iso-failed-description = Neyin başarısız olduğunu görmek için tanılamayı açın. Sorunu giderip yeni bir çıktı dosyası adıyla tekrar deneyin.
iso-diagnostics = Tanılamayı aç
iso-close-title = ISO oluşturma devam ediyor
iso-close-message = Oluşturma veya iptal işlemi bitene kadar bu pencereyi açık tutun. İptal işlemi, mevcut işlemin güvenle durdurulabileceği noktayı bekler.
iso-keep-open = Açık tut
prepare-title = Windows ve Store uygulamalarını güncelleyin
prepare-description = Atlas’ı uygulamadan önce Windows güncellemelerini yükleyin, Microsoft Store’u ve yüklü tüm Store uygulamalarını güncelleyin. Store uygulamaları güncellenirken kapanabilir.
prepare-complete = Windows ve Store uygulamaları güncel.
prepare-reboot = Windows’un yeniden başlatılması gerekiyor. Atlas seçimleriniz kaydedilecek. Oturum açtıktan sonra güncellemeleri yeniden denetleyin.
prepare-failed = Bazı güncellemeler tamamlanamadı. Tanılama günlüğünü inceleyin, Windows veya Store hatalarını giderin ve yeniden deneyin.
prepare-cancelled = Hazırlık durduruldu. Devam etmeden önce güncellemeleri yeniden denetleyin.
prepare-windows-search = Windows güncellemeleri denetleniyor…
prepare-windows-download = Windows güncellemeleri indiriliyor…
prepare-windows-install = Windows güncellemeleri yükleniyor…
prepare-store-search = Microsoft Store denetleniyor…
prepare-store-install = Microsoft Store ve uygulamaları güncelleniyor…
prepare-stop-description = Durdurma işlemi, devam eden güncelleme işleminin bitmesini bekler. O zamana kadar Atlas’ı açık tutun.
prepare-stop = Bu işlemden sonra durdur
prepare-restart = Yeniden başlat ve devam et
prepare-start = Güncellemeleri denetle ve yükle
iso-username = Yerel hesap adı
iso-account-description = Windows, yeniden yüklendikten sonra parola belirlemenizi isteyecek.
iso-username-placeholder = Adınız
iso-account-invalid = Başında veya sonunda boşluk olmayan, Windows hesap adlarında yasaklanan simgeleri içermeyen 1–20 karakter kullanın.
iso-privacy-defaults = Windows kurulumu, isteğe bağlı veri paylaşımını ve kişiselleştirilmiş teklifleri otomatik olarak kapatır.
prepare-drivers = Sürücüler nasıl yüklensin?
prepare-drivers-auto = Sürücüleri Windows Update’ten al
prepare-drivers-auto-detail = Windows, donanımınız için sürücüleri bulur. Çoğu bilgisayar için önerilir.
prepare-drivers-manual = Sürücüleri kendim yükleyeceğim
prepare-drivers-manual-detail = Windows Update’ten sürücü indirilmesini engeller. Sürücüleri kendiniz edinmeniz gerekir; yüklü sürücüler korunur.
prepare-network-needed = Tarifeli olmayan bir Wi-Fi veya Ethernet bağlantısı kurup yeniden deneyin. Wi-Fi görünmüyorsa önce ağ sürücünüzü yükleyin.
prepare-network-settings = Ağ ayarlarını aç
iso-target-title = Windows’u hangi bilgisayara yeniden yükleyeceksiniz?
iso-target-this = Bu bilgisayara
iso-target-other = Başka bir bilgisayara
iso-copy-network = Bu bilgisayarın ağ sürücülerini ekle
iso-network-detail = Windows kurulumu sırasında bu bilgisayarın Wi-Fi ve Ethernet sürücülerini kullanır. Kurulumdan sonra Wi-Fi’ye yeniden bağlanmanız gerekir.
iso-network-source = Ağ sürücüsü kaynağı
iso-network-installed = Yüklü sürücüleri kullan
iso-network-updated = Önce Windows Update’i kontrol et
iso-network-updated-detail = Windows Update’in sunduğu uygun sürücüleri indirir ve yüklü sürücüleri yedek olarak saklar. Tarifeli olmayan bir bağlantı gerekir.
iso-stage-network-drivers = Ağ sürücüleri hazırlanıyor…
iso-network-failed = Ağ sürücüleri hazırlanamadı. Tanılama bilgilerini kontrol edin veya geri dönüp ağ sürücüsü seçeneğini değiştirin.
iso-mode-desktop = Masaüstünden önce kurulumu tamamla
iso-mode-desktop-description = Atlas ayarlarını şimdi seçin. Oturum açtıktan sonra Windows masaüstünü açmadan önce güncellemeleri ve Atlas kurulumunu tamamlayın.
desktop-setup-description = Bilgisayarınızın kurulumunu tamamlayın. Atlas tercihleriniz kaydedildi; gerekirse Windows’a dönebilirsiniz.
desktop-setup-exit = Windows’ta devam et

# Windows installation USB (Beta)
usb-title = Kurulum USB’si oluştur
usb-existing = Mevcut bir ISO’dan USB oluştur
usb-description = Bilgisayarınıza Windows ve Atlas kurmak için önyüklenebilir bir Windows 11 25H2 USB’si oluşturun.
usb-choose-iso = ISO seç
usb-drive = USB sürücüsü
usb-empty = Bir USB sürücüsü bağlayıp listeyi yenileyin. Yalnızca yazılabilir ve çalışan Windows kurulumunu içermeyen USB sürücüleri gösterilir.
usb-refresh = Yenile
usb-drive-detail = { $size } GB · { $volumes } · Seri numarası: { $serial }
usb-review = USB’yi gözden geçir
usb-erase-title = Bu USB sürücüsü silinsin mi?
usb-erase-description = { $drive } ({ $size } GB) üzerindeki tüm dosyalar ve bölümler kalıcı olarak silinecek. ISO dosyanız korunacak.
usb-layout = Windows kurulumu için en fazla 32 GB kullanılır. Kalan alan ayrılmamış olarak bırakılır. Bu USB, UEFI ile açılan bilgisayarlar içindir.
usb-ack = Bu USB sürücüsündeki her şeyin silineceğini anlıyorum.
usb-write = Sil ve USB oluştur
usb-stage-prepare = Kurulum dosyaları hazırlanıyor…
usb-stage-format = USB biçimlendiriliyor…
usb-stage-copy = Kurulum dosyaları kopyalanıyor…
usb-stage-verify = USB doğrulanıyor…
usb-working = Atlas’ı açık, USB’yi bağlı tutun. İptal işlemi, mevcut işlemin güvenli biçimde durmasını bekler. Tamamlanmamış bir USB ile Windows kurulamaz.
usb-failed = USB oluşturma tamamlanamadı. Bağlantıyı kontrol edin ve ayrıntılar için tanılamayı açın. Yeniden denemek için sürücüyü tekrar seçin.
usb-cancelled = USB oluşturma durduruldu. Sürücüde eksik kurulum dosyaları bulunabilir. Windows kurmadan önce USB’yi yeniden oluşturun.
usb-complete = USB’niz hazır ve tüm dosyalar doğrulandı. USB’yi çıkarın, Windows’u yeniden kuracağınız bilgisayara bağlayın ve UEFI önyükleme menüsünden seçin.
usb-eject = USB’yi çıkar
usb-ejected = USB’yi güvenle çıkarabilirsiniz. Windows kurmak için bilgisayarınızın UEFI önyükleme menüsünden USB’yi seçin.
usb-eject-failed = Windows USB’yi çıkaramadı. Sürücüyü kullanan dosyaları veya pencereleri kapatıp yeniden deneyin.
ready-fresh-title = Temiz bir Windows kurulumuyla başlayın
ready-fresh-description = Desteklenen Atlas yükseltmeleri dışında Atlas, temiz bir Windows kurulumu gerektirir. Yeni bir Atlas 0.6 kurulumu için Windows 11 25H2 gerekir. Windows’u yeniden kurmadan önce dosyalarınızı yedekleyin.
detail-edition-unsupported = Windows 11 Pro, Pro for Workstations veya Enterprise kullanın. Home, LTSC ve Server sürümleri desteklenmez. Sürümünüz belirlenemediyse devam etmeden önce bu sorunu çözün.
install-source-title = Kurulum kullanılamıyor
install-source-unsupported = Atlas { $source }, doğrudan { $target } sürümüne güncellenemez. Bu sürümü kullanmak için Windows'u yeniden yükleyin.
install-source-unknown = Atlas kurulum durumunu doğrulayamadı. Yeniden denemeden önce yarım kalan kurulumu tamamlayın ve tanılama bilgilerini inceleyin.
iso-edition-selection = Yalnızca desteklenen sürümler dahil edilir. Windows kurulumu sırasında Windows lisansınızın bulunduğu sürümü seçin.
detail-windows-preview = Insider derlemeleri desteklenmiyor. Windows 11’in genel kullanıma sunulan bir sürümünü kullanın.
detail-windows-release-unknown = Atlas, bu Windows derlemesinin genel kullanıma sunulduğunu doğrulayamadı. İnternete bağlanıp yeniden kontrol edin.
iso-release-unknown = Bu ISO’nun genel kullanıma sunulan bir Windows 11 25H2 sürümü içerdiği doğrulanamadı. İnternete bağlanıp yeniden deneyin veya resmî bir yükleme medyası seçin.
prepare-previous-worker = Önceki bir güncelleme işlemi hâlâ sürüyor. Atlas, yeniden deneyebilmeniz için işlemin bitmesini bekleyecek.

ready-used-windows-title = Devam etmeden önce Windows’u yeniden yükleyin
ready-used-windows-description = Bu Windows kurulumunda önceki kullanım belirtileri var. Buraya Atlas yüklemek desteklenmez ve kesinlikle önerilmez. Yalnızca riskleri anlıyorsanız devam edin.
ready-used-windows-dismiss = Riskleri anlıyorum
playbook-option-install-eclean = eclean yükle
consequence-install-eclean = Kurulumdan sonra bilgisayarınızı düzenli tutmak için AtlasOS ekibinden bir bakım aracı. Gereksiz dosyaları ve başlangıç uygulamalarını inceleyin. Hesap ve internet bağlantısı gerektirir.

prepare-resumed = Windows yeniden başlatıldı. Atlas seçimleriniz geri yüklendi. Atlas’ı yüklemeden önce güncellemelere devam edin.
prepare-continue = Güncellemelere devam et
prepare-saving-restart = Seçimleriniz kaydediliyor ve Windows yeniden başlatıldıktan sonra Atlas’ın açılması ayarlanıyor…
prepare-restart-save-failed = Seçimleriniz kaydedilemedi. Yeniden başlatmadan önce tekrar deneyin.
prepare-restart-registration-failed = Seçimleriniz kaydedildi ancak otomatik açılma ayarlanamadı. Tekrar deneyin veya Windows’u yeniden başlatıp Atlas’ı elle açın.
prepare-restart-failed = Windows yeniden başlatılamadı. Tekrar deneyin veya Windows üzerinden yeniden başlatın. Seçimleriniz kaydedildi ve Atlas yeniden açılacak şekilde ayarlandı.
diagnostics-export = Tanı bilgilerini dışa aktar
diagnostics-exporting = Tanı bilgileri toplanıyor…
diagnostics-show = Tanı ZIP dosyasını göster
diagnostics-privacy = Herkese açık hata bildirimi için hassas verileri gizlenmiş bir ZIP oluşturun.
diagnostics-error = Tanı bilgileri dışa aktarılamadı: { $error }
