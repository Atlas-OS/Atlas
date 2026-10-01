# Translation guidance

Use these conventions when editing the Fluent catalogs. All non-English translations
remain previews and need native-speaker review. The Windows labels below are working
choices; check the open terminology questions against a localized Windows installation
before marking a catalog reviewed. See [language implementation](i18n.md) for
catalog checks and [writing guidance](writing.md) for shared copy conventions.

## Atlas package and step names

The `.apbx` file is the Atlas package in every language, shortened once it's
clear. "Playbook" appears only where a string explains AME Wizard's name for it;
the `playbook-*` message ids, `i18n/playbook-source.ftl` and the
`embedded-playbook` feature keep their names. The ISO flow's third step reuses
the install flow's Your choices (`step-options`).

| Locale | Atlas package, then its short form | Install steps (`step-*`) | ISO steps 1, 2 and 4 (`iso-review-files`, `iso-step-windows`, `iso-step-review`) |
|---|---|---|---|
| de | Atlas-Paket, Paket; the file is the Paketdatei | Vorbereiten, Ihre Auswahl, Windows-Sicherheit, Installieren | Dateien, Windows-Einrichtung, Überprüfung |
| es | paquete de Atlas, el paquete | Preparación, Sus preferencias, Seguridad de Windows, Instalación | Archivos, Instalación de Windows, Revisión |
| fr | package Atlas (masculine), le package | Préparation, Vos choix, Sécurité Windows, Installation | Fichiers, Installation de Windows, Récapitulatif |
| pt-BR | pacote do Atlas, o pacote | Preparação, Suas escolhas, Segurança do Windows, Instalação | Arquivos, Instalação do Windows, Revisão |
| pl | pakiet Atlasa, pakiet; the file is plik pakietu | Przygotowanie, Opcje, Zabezpieczenia Windows, Instalacja | Pliki, Konfiguracja Windows, Podsumowanie |
| ru | пакет Atlas (declined: пакета, пакетом), пакет | Подготовка, Ваш выбор, Безопасность Windows, Установка | Файлы, Установка Windows, Проверка |
| tr | Atlas paketi, paket | Hazırlık, Seçimleriniz, Windows Güvenliği, Kurulum | Dosyalar, Windows kurulumu, İnceleme |
| zh-Hans | Atlas 安装包, 安装包 | 准备, 你的选择, Windows 安全中心, 安装 | 文件, Windows 安装设置, 检查 |
| zh-Hant | Atlas 套件, 套件 | 準備, 您的選擇, Windows 安全性, 安裝 | 檔案, Windows 安裝, 檢閱 |
| ja | Atlas パッケージ, パッケージ | 準備, 設定の選択, Windows セキュリティ, インストール | ファイル, Windows のセットアップ, 確認 |
| id | paket Atlas, paket | Persiapan, Pilihan Anda, Keamanan Windows, Instal | File, Penyiapan Windows, Tinjau |
| th | แพ็กเกจ Atlas, แพ็กเกจ | เตรียมความพร้อม, ตัวเลือกของคุณ, ความปลอดภัยของ Windows, ติดตั้ง | ไฟล์, การตั้งค่า Windows, ตรวจทาน |
| hi | Atlas पैकेज (masculine), पैकेज | तैयारी, आपके विकल्प, Windows सुरक्षा, इंस्टॉल | फ़ाइलें, Windows सेटअप, समीक्षा |

## Windows feature names

The features Atlas turns off are named as each language's Windows shows them,
in `consequence-mitigations-disable` (Exploit protection, Control Flow Guard)
and `playbook-page-defender-enable-description` (the other three). Names not
yet confirmed on a localized Windows are in the
[questions for native reviewers](#questions-for-native-reviewers).

| Locale | Exploit protection | Control Flow Guard | Smart App Control | Enhanced Phishing Protection | Find my device |
|---|---|---|---|---|---|
| de | Exploit-Schutz | Ablaufsteuerungsschutz (CFG) | Intelligente App-Steuerung | Erweiterter Phishingschutz | „Mein Gerät suchen“ |
| es | Protección contra vulnerabilidades | Protección de flujo de control (CFG) | Control inteligente de aplicaciones | Protección mejorada contra suplantación de identidad | Encontrar mi dispositivo |
| fr | Exploit Protection (English, as French Windows shows it) | Protection du flux de contrôle (CFG) | Contrôle intelligent des applications | Protection renforcée contre l’hameçonnage | Localiser mon appareil |
| pt-BR | Proteção contra vulnerabilidades | Proteção de fluxo de controle (CFG) | Controle Inteligente de Aplicativos | Proteção aprimorada contra phishing | Localizar meu dispositivo |
| pl | Ochrona przed lukami w zabezpieczeniach | Ochrona przepływu sterowania (CFG) | Inteligentna kontrola aplikacji | Rozszerzona ochrona przed wyłudzaniem informacji | Znajdź moje urządzenie |
| ru | защита от эксплойтов | защита потока управления (CFG) | «Интеллектуальное управление приложениями» | «Расширенная защита от фишинга» | «Поиск устройства» |
| tr | Açıktan yararlanma koruması | Denetim akışı koruması (CFG) | Akıllı Uygulama Denetimi | Gelişmiş Kimlik Avı Koruması | Cihazımı bul |
| zh-Hans | Exploit Protection (English, as Chinese Windows shows it) | 控制流保护 (CFG) | 智能应用控制 | 增强型网络钓鱼防护 | 查找我的设备 |
| zh-Hant | 惡意探索保護 | 控制流程防護（CFG） | 智慧型應用程式控制 | 增強式網路釣魚保護 (the Group Policy name) | 尋找我的裝置 |
| ja | Exploit Protection (Latin letters, as Japanese Windows shows it) | 制御フロー ガード | スマート アプリ コントロール | 拡張フィッシング保護 | デバイスの検索 |
| id | Perlindungan eksploitasi | Control Flow Guard (English) | Kontrol Aplikasi Pintar | Perlindungan pengelabuan (the switch's own label) | Temukan perangkat saya |
| th | การป้องกัน Exploit | Control Flow Guard (English) | การควบคุมแอปแบบอัจฉริยะ | การป้องกันฟิชชิ่งขั้นสูง | ค้นหาอุปกรณ์ของฉัน |
| hi | शोषण से सुरक्षा | नियंत्रण प्रवाह गार्ड (CFG) | स्मार्ट ऐप नियंत्रण | उन्नत फ़िशिंग सुरक्षा | मेरा डिवाइस ढूँढें |

## Locale conventions

These hold in every language:

- Name a control by its exact label in your catalog, quoted as your language
  quotes labels.
- `list-and` joins the last two items of a list, and `$a` may already hold
  several items joined with `list-separator`. Chinese joins with 和 and
  Japanese with 、, without spaces.
- **Report a problem** (`home-report-problem`) opens the in-app Send a report
  page, so its label names no website.
- Where your language uses one word for both, keep the four flow steps apart
  from the stages of updating or of creating an ISO.

Each language's own choices:

- **de** — Sie; "Ihr PC"; buttons infinitive, Windows names kept
  (Zurück, Weiter, Abbrechen, Fertig); app relaunch "als Administrator
  ausführen", PC "neu starten"; „…“ quotes for quoted button and step
  names; step 2 "Ihre Auswahl". Windows names: Manipulationsschutz,
  Echtzeitschutz, Cloudbasierter Schutz, Automatische Übermittlung von
  Beispielen; "Einstellungen für Viren- & Bedrohungsschutz". Sources:
  support.microsoft.com de-de Windows Security page; learn.microsoft.com
  de-de tamper/cloud pages (machine-translated, weighed accordingly); seven
  human-written German how-tos quoting the four toggles.
  - Processor protections are "Prozessorschutz", never "Prozessorsicherheit";
    security mitigations are "Mitigationen". "Protokollordner öffnen", "Updates
    anhalten". "Diagnose-ZIP" in titles, "Diagnose-ZIP-Datei" in body text.
    "Antivirensoftware" for an app, "Virenschutz" for the protection.
    "Startmenü" is the Start menu and "Boot-Menü" the firmware menu, kept
    apart. "No installation changes were made" is "Die Installation hat nichts
    geändert".
- **es** — implicit usted, "su PC"/"el equipo"; international vocabulary
  (agregar, quitar, administrar, aplicación); "volver a abrir" for the app,
  "reiniciar" for the PC; ¿…? questions; step 2 "Sus preferencias". Windows
  names: Protección contra alteraciones, Protección en tiempo real,
  Protección basada en la nube, Envío automático de muestras;
  "Configuración de antivirus y protección contra amenazas". Sources: the
  es-ES/es-MX support page (uses "proporcionada desde la nube"), learn
  es-es walkthrough and a third-party UI guide (both "basada en la nube").
  - "su PC" with a possessive, "el equipo" where an adjective must agree;
    never "equipo" (the PC) and "equipo de Atlas" (the team) in one sentence.
    "Abrir la carpeta de registros"; "Detener actualizaciones" pairs with
    "Continuar actualizaciones". "Protecciones del procesador". Cards are
    named exactly ("Comprobaciones del equipo", "Archivos de instalación",
    "Actualizar Windows y las apps de la Store"); running text says
    "aplicaciones de la Store". "Unsupported" is "no cuenta con soporte",
    since "no es compatible" means incompatible. Titles say "No se pudo…";
    "Internet" is capitalised; "en cuanto…", not the Spain-only "nada más" +
    infinitive.
- **fr** — vous; U+00A0 before `: ; ? !` and `%` and inside « »; typographic
  apostrophe; infinitive buttons; "relancer" = app, "redémarrer" = PC;
  the switches are "paramètres de protection"; step 2 "Vos choix"; "la
  build". Windows names: Protection contre les falsifications, Protection
  en temps réel, Protection dans le cloud, Envoi automatique d’un
  échantillon; "Paramètres de protection contre les virus et menaces".
  Sources: fr-fr support pages (Windows Security overview and malware
  troubleshooting, which disagree on the cloud label), learn fr-fr tamper
  pages (MT), French UI guides.
  - « étape » means only the four flow steps; an update stage is
    « opération ». « ce PC » is always the PC running Atlas; the one being
    reinstalled is « ce même PC » or « le PC à réinstaller ». Cards are named
    bare (« Vérifications du PC »), except the infinitive « Mettre à jour
    Windows et les applications du Store », which goes in « ». « Ouvrir le
    dossier des journaux », « Arrêter les mises à jour ». The data is « les
    diagnostics », the file « ZIP de diagnostic ». Stage statuses are
    feminine, like the stepper's (« en cours », « non commencée »).
- **pt-BR** — você (implicit), "o Atlas"/"o Windows" with article, "seu
  PC"; infinitive buttons; "reabrir" = app, "reiniciar" = PC; the switches
  are "as quatro proteções"; state words match Windows' invariant
  Ativado/Desativado; "à etapa Preparação"; step 2 "Suas escolhas"; also
  serves pt-PT, so neutral forms where they exist. Windows names: Proteção
  contra violações, Proteção em tempo real, Proteção fornecida pela nuvem,
  Envio automático de amostra; "Configurações de proteção contra vírus e
  ameaças". Sources: pt-br support page (human-localized, differs on two
  switches), learn pt-br (MT), Brazilian press describing the live UI.
  - A check that passes "é aprovada", not "passa". Cards: "em Verificações do
    PC", "no cartão Atualizar o Windows e os apps da Store". "Proteções do
    processador". "Abrir pasta de logs", "Parar atualizações". Test build
    "versão de teste", release build "versão oficial", package builds "versão
    completa do pacote" and "versão LocalTest". Stage states agree with
    "etapa" ("em andamento", "não iniciada", "concluída"). Plurals are `one`
    and `other`, and `one` covers 0.
- **pl** — second person (Twój/Ci capitalised); "Atlas" declined (Atlasa,
  Atlasie, Atlasem), "Zabezpieczenia Windows" declined, Windows and Defender
  not; "otwórz Atlas ponownie" = app, "uruchom ponownie" = PC; all four
  plural categories on every count; step 2 "Opcje" ("wybory" also means
  elections). Windows names: Ochrona przed naruszeniami, Ochrona w czasie
  rzeczywistym, Ochrona dostarczana z chmury, Automatyczne przesyłanie
  próbek; "Ustawienia ochrony przed wirusami i zagrożeniami". Sources: pl-pl
  support pages, learn pl-pl (MT, inconsistent on cloud), Polish tech sites
  quoting the UI.
  - "krok" only for the four flow steps; update and ISO stages are "etap".
    Cards are "w sekcji <title>", never "karta", which reads as a tab
    ("w sekcji Sprawdzanie komputera"). Radio options are "zaznacz", buttons
    "wybierz". Metered and unmetered are "taryfowe" and "nietaryfowe", not
    "bez ustawionego limitu" (the separate data limit). Statuses shared by
    steps and stages are impersonal ("ukończono", "nie rozpoczęto"). Never
    the reader's gendered past tense: "wybrano", "Jeśli korzystasz już z
    Windows". "Otwórz folder dzienników", "Zatrzymaj aktualizowanie"; security
    mitigations "środki zaradcze"; AI "sztuczna inteligencja".
- **ru** — вы (lower case); "ПК"; imperative buttons; «…» guillemets;
  "перезапустить" = app, "перезагрузить" = PC; the user's choices are
  "настройки", the app's Settings page "параметры"; all four plural
  categories (regression test keeps 1/21/101 минута). Windows names: Защита
  от подделки, Защита в режиме реального времени, Облачная защита,
  Автоматическая отправка образцов; "Параметры защиты от вирусов и других
  угроз"; toggle states Вкл./Откл. Sources: ru-ru support and learn pages.
  - A control is quoted with its exact label (нажмите «Повторить попытку»);
    a quote inside a label uses „…“ («Открыть „Безопасность Windows“»).
    Get ready's cards are «раздел «…»»; update stages are «этап», flow steps
    «шаг». «этот ПК» is only the PC running Atlas; the one being reinstalled
    is «тот ПК». Always «ПК», never «компьютер». First-person rows avoid the
    gendered past tense («Я даю согласие…», «Когда я…»). "Microsoft account"
    is «учётная запись Майкрософт»; SmartScreen stays in Latin letters.
    «Открыть папку журналов», «Остановить обновление».
- **tr** — siz; suffixes on proper nouns with an apostrophe (Atlas'ı,
  Windows'u); never a suffix on a variable (a noun follows it instead:
  "{ $version } sürümünü"); "yeniden aç" = app, "yeniden başlat" = PC; step
  2 "Seçimleriniz". Windows names: Kurcalama Koruması, Gerçek zamanlı
  koruma, Bulut tabanlı koruma, Otomatik örnek gönderimi; "Virüs ve tehdit
  koruması ayarları". Sources: tr-tr support page (human-localized), learn
  tr-tr (MT), a Microsoft Q&A answer using "Değişiklik Koruması".
  - A control is named by its label, then an apostrophe, its suffix and
    "seçin" ("Yeniden dene'yi seçin", "Atlas'ı kur'u seçin"); a radio option
    takes "… seçeneğini belirleyin". Card titles are noun phrases so text can
    name them: the update card is "Windows ve Store güncellemeleri" ("…
    kartında"). "kur" installs Atlas; "yükle" installs updates, apps, drivers
    and Windows. "denetle", not "kontrol et". Build is "derleme",
    diagnostics "tanılama verileri". "No installation changes were made" is
    "Kurulum hiçbir değişiklik yapmadı", never "Bilgisayarınızda…".
    Mitigations are "güvenlik risk azaltmaları"; privacy text's "kept" is
    "kaldırılmaz". "Günlük klasörünü aç", "Güncellemeyi durdur".
- **zh-Hans** — 你 (as Windows 11 zh-CN), 电脑; full-width punctuation with
  a space between Chinese and Latin/digits, half-width brackets for
  Latin-only asides; 重新打开 = app, 重启 = PC; 移除 for Defender (permanent),
  关闭 and 重新开启 for the four switches; step 2 "你的选择". Windows names:
  篡改防护, 实时保护, 云提供的保护, 自动提交样本; “病毒和威胁防护”设置.
  Sources: zh-cn support and learn pages.
  - 安装文件 means prepared files, never the .apbx. Processor protections are
    处理器防护, replacing 处理器安全. Review is 核对 in the install summary and
    检查 in the ISO, USB and report flows. The USB is U 盘 in titles and USB
    驱动器 in lists and the erase text; erasing is 清空 in titles and buttons,
    永久删除 in body text. Edge bookmarks are 收藏夹. Windows setup the program
    is Windows 安装程序, OOBE Windows 初始设置. 打开日志文件夹, 停止更新.
- **zh-Hant** — 您; Taiwan glossary (設定, 系統管理員, 檔案, 資料夾, 網路,
  組建, 佈景主題); full-width punctuation; 重新開啟 Atlas = app, 重新啟動 =
  PC; step 2 "您的選擇". Windows names: 竄改防護, 即時保護, 雲端提供的保護,
  自動提交範例; 病毒與威脅防護設定. Sources: zh-tw support page (MT,
  inconsistent), learn zh-tw human-translated cloud page, 2021 and 2026
  Taiwanese guides with screenshots.
  - Full-width brackets even around Latin-only text: （.apbx）, （UAC）.
    Processor protections are 處理器防護, replacing 處理器安全性; security
    mitigations 安全性緩和措施. Erasing is 清除 throughout. Edge's
    「我的最愛」 is always quoted. Store apps are 市集應用程式. Controls named
    in text take 「」: 開啟記錄資料夾, 停止更新, 回報問題, 傳送報告, 說明與意見反應.
- **ja** — です・ます; noun-stop buttons (完了, 今すぐ再起動); half-width
  space between Japanese and Latin and inside katakana compounds; 。、 with
  half-width ( ) and ": " as Microsoft Japanese UI does; 管理者として再実行
  = app, 再起動 = PC; step 2 "設定の選択". Windows names: 改ざん防止,
  リアルタイム保護, クラウド提供の保護, サンプルの自動送信;
  ウイルスと脅威の防止の設定. Sources: an OEM (dynabook) Windows 11 support
  page and a 2026 Japanese article describing the live UI; the ja-jp
  support page is machine-translated and disagrees.
  - The counter is 件 for updates and 個 for switches. The USB list's Refresh
    is 一覧を更新, because bare 更新 means "update" here. "Antivirus app" is
    ウイルス対策アプリ; ソフト only where the English says "software". Edge
    bookmarks are お気に入り. Status words are 進行中, 失敗, 未開始 and 完了,
    and stage names end in 〜中. ログ フォルダーを開く, 更新を停止.
- **id** — Anda; formal-neutral register; "jalankan ulang" = app, "mulai
  ulang" = PC, "buka kembali" after a restart; the switches are
  "pengaturan (perlindungan)"; only `other` plurals; step 2 "Pilihan Anda".
  Windows names: Proteksi Kerusakan, Perlindungan real-time, Perlindungan
  yang dikirimkan cloud, Pengiriman sampel otomatis; "Pengaturan
  perlindungan virus & ancaman". Sources: id-id support and learn pages,
  all machine-translated and mutually inconsistent; a community tutorial
  title for the tamper label.
  - "penginstalan" is the Atlas install, "instalasi Windows" a Windows
    installation. "No installation changes were made" is "Penginstalan belum
    mengubah apa pun", never a claim about the whole PC. "Hubungkan", not
    "Sambungkan"; "file", not "berkas"; "Setelah itu," rather than a sentence
    starting with "Lalu". "Buka file paket", "Buka folder log", "Hentikan
    pembaruan", "Bantuan dan masukan"; "needs attention" is "perlu
    diperhatikan".
- **th** — คุณ; no sentence-final full stops, a space between clauses and
  around Latin/digits; classifiers instead of plurals; รีสตาร์ต = PC, เปิด
  Atlas ใหม่ = app; "แอป ความปลอดภัยของ Windows" when the app is opened;
  step 2 "ตัวเลือกของคุณ". Windows names: การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย,
  การป้องกันแบบเรียลไทม์, การป้องกันบนระบบคลาวด์, การส่งตัวอย่างโดยอัตโนมัติ;
  การตั้งค่าการป้องกันไวรัสและภัยคุกคาม. Sources: th-th support pages
  (Windows Security, turn off Defender, device security, Windows Update,
  activation, power, Snipping Tool); learn th-th pages served English.
  - Diagnostics are ข้อมูลการวินิจฉัย. Review is ตรวจทาน; ตรวจสอบ is checking
    and verifying. Restart is only รีสตาร์ต, never รีสตาร์ท or เริ่มระบบใหม่.
    Build is บิลด์ (รุ่น is an edition or release), Beta เบต้า, Ethernet
    อีเทอร์เน็ต; Wi-Fi stays Latin. No โปรด; question titles have no "?".
    Controls named in text have a space either side; cards are ในการ์ด
    <label>.
- **hi** — आप with respectful imperatives; danda as the only sentence
  terminator; Microsoft-style loanwords in Devanagari (इंस्टॉल, अपडेट,
  सेटिंग्स, फ़ाइल) with nukta applied consistently; "दोबारा खोलें" = app,
  "रीस्टार्ट करें" = PC; step 2 "आपके विकल्प", the decision caption "पसंद".
  Windows names: छेड़छाड़ से सुरक्षा, रीयल-टाइम सुरक्षा, क्लाउड-आधारित सुरक्षा,
  स्वचालित नमूना सबमिशन; वायरस और ख़तरे से सुरक्षा सेटिंग्स. Sources: none in
  Hindi; every Microsoft hi-in page fetched was served in English and the
  review PC has no Hindi language pack, so these five names are reasoned,
  not confirmed.
  - The Atlas package, ISO and USB are masculine (नया ISO); USB ड्राइव and ISO
    फ़ाइल are feminine. Diagnostics are डायग्नोस्टिक्स (masculine plural),
    never निदान. "PC" stays Latin, never पीसी; इंस्टॉलेशन, not स्थापना;
    रीस्टार्ट, not पुनः आरंभ; "फिर कोशिश करें"; अगर, not यदि. Card titles and
    labels go in “ ”, except the step तैयारी. First-person text stays
    gender-neutral (मेरी कोशिश थी कि…, "X ख़ुद इंस्टॉल करें").

## Questions for native reviewers

Terminology that could not be settled without a localized Windows 11 build
in front of a reviewer (Microsoft's own localized pages are machine
translated for several languages and disagree with each other):

| Locale | Keys | Reason |
|---|---|---|
| de | protection-cloud, protection-samples, security-list-title, prepare-description, playbook-page-defender-enable-description, consequence-mitigations-disable, playbook-page-mitigations-default-description, consequence-defender-disable | Human-written sources say "Cloudbasierter Schutz"; Microsoft prose says "Über/In der Cloud bereitgestellter Schutz" and "Automatische Beispielübermittlung". Start shows "Terminal", not "Windows-Terminal". Whether "Intelligente App-Steuerung" and "Erweiterter Phishingschutz" keep their capitals mid-sentence, and the exact CFG label on the Exploit-Schutz page. "Mitigationen" vs Microsoft's "Entschärfungen" or "Risikominderungen"; SmartScreen's own dialog says "unbekannte App", the catalog "nicht erkannte Apps". |
| es | protection-cloud, security-list-title, playbook-page-defender-enable-description, prepare-description | Support page says "proporcionada desde la nube"; learn walkthrough and UI guides say "basada en la nube". Usted vs tú: Microsoft consumer pages use tú. Enhanced Phishing Protection: Microsoft's es-es page is machine-translated and adds "(phishing)". "Terminal Windows". |
| fr | protection-cloud, security-list-title, playbook-page-defender-enable-description, prepare-description | "Protection dans le cloud" (troubleshooting page, UI guides) vs "Protection fournie par le cloud" (overview page); "et" vs "&". « Protection renforcée contre l’hameçonnage » (learn fr-fr, MT) vs the section's « Protection contre l’hameçonnage ». Start shows « Terminal », not « Terminal Windows ». |
| pt-BR | protection-tamper casing, protection-cloud, playbook-page-defender-enable-description, detail-windows-preview, detail-windows-release-unknown | Press quotes "Proteção contra Violações" capitalised; support page says "adulterações" and "na nuvem". Enhanced Phishing Protection: "aprimorada" (Windows 11 security book) vs "avançada" (business page), low priority. "build" vs "compilação": three strings say "build", two "compilação"; settle on a pt-BR install. |
| pl | protection-cloud, consequence-mitigations-disable, playbook-page-defender-enable-description, check-fix-apps, prepare-description | Microsoft pages disagree (chmurowa / w chmurze / untranslated); "dostarczana z chmury" rests on third-party quotations. Exploit protection: Microsoft pages say "Ochrona przed exploitami", "ochrona przed programami wykorzystującymi luki" or leave it in English. Enhanced Phishing Protection: no Microsoft source has "Rozszerzona…"; the switch is "Ochrona przed wyłudzaniem informacji" and the business page says "Ulepszona…". Smart App Control: one older page says "Kontrola aplikacji inteligentnej". Find my device, Installed apps, Notepad and Windows Terminal are unchecked. |
| ru | protection-tamper, security-list-title, security-switch-off, consequence-mitigations-disable, playbook-page-defender-enable-description, usb-title (and the other флешка strings), iso-step-review | "Защита от подделки" (UI quotations) vs "Защита от незаконного изменения" (docs); page heading with "и других угроз"; "Откл." toggle word. Exploit protection, CFG, Smart App Control and Enhanced Phishing Protection («Расширенная» or «Улучшенная») are unchecked. «флешка» vs Microsoft's «USB-накопитель». «Проверка» for Review is also the Checking status; «Сводка» if testers mix them up. |
| tr | protection-tamper casing, security-list-title, Fast Startup, consequence-mitigations-disable, playbook-page-defender-enable-description, the update noun, apostrophes | "Kurcalama koruması/Koruması" vs a moderator's "Değişiklik Koruması"; "ve" vs "&"; "Hızlı Başlatma/başlatma". CFG may be "koruyucusu"; casing of "Gelişmiş Kimlik Avı Koruması". "güncelleştirme" (Microsoft's term, on Home, PC checks and Your choices) vs "güncelleme" (Get ready's update card); pick one for the whole catalog. The catalog mixes ' and ’ by section; pick one. |
| zh-Hans | security-list-title, protection-samples, protection-cloud, consequence-mitigations-disable, playbook-page-defender-enable-description | Quotation marks in the page title; 样本 vs 示例; 云提供的保护 vs 云保护. "Exploit Protection" left in English and 控制流保护 (CFG) to confirm on a zh-CN build. The Windows Security switch reads 网络钓鱼防护, not 增强型网络钓鱼防护. |
| zh-Hant | protection-samples, protection-tamper (Windows 10), consequence-mitigations-disable, playbook-page-defender-enable-description, iso-network-inbox, iso-step-review, usb-review, report-review | 自動提交範例 / 提交自動樣本 / 自動提交樣本; older builds wrote 防竄改保護. 惡意探索保護, 控制流程防護, 智慧型應用程式控制, 增強式網路釣魚保護 (the switch reads 網路釣魚保護), 尋找我的裝置 and 網路介面卡 need a zh-TW build. Review is 檢閱 in the ISO flow but 檢查 for the USB and the report ZIP. |
| ja | protection-cloud, protection-samples, security-list-title, playbook-page-defender-enable-description | Live-UI sources vs the machine-translated ja-jp support page; also 再実行 vs 開き直す for relaunch. 拡張フィッシング保護 is the title of Microsoft's Japanese docs page; other docs say 強化されたフィッシング保護, and the switch reads フィッシング対策. |
| id | protection-tamper, protection-cloud, security-list-title, Fast Startup, consequence-mitigations-disable, playbook-page-defender-enable-description, prepare-description, check-fix-apps, list-and | All Microsoft id-ID pages are MT and give eight renderings of Tamper Protection between them. Perlindungan eksploitasi, Perlindungan pengelabuan, Temukan perangkat saya and Aplikasi yang diinstal are unconfirmed; Control Flow Guard, Notepad, Paint and Windows Terminal stay English until confirmed (Kontrol Aplikasi Pintar is confirmed by the id-ID Smart App Control FAQ). `list-and` gives "A, B dan C", but PUEBI and CLDR want "A, B, dan C", which needs a separate message for the last of three or more. |
| th | protection-tamper, protection-cloud, security-list-title, memory integrity, Fast Startup, playbook-page-defender-enable-description, prepare-description, check-fix-apps, sign-in | Only MT support pages available; "และ" vs "&"; ความสมบูรณ์ vs ความถูกต้อง ของหน่วยความจำ. Only ฟิชชิ่ง in การป้องกันฟิชชิ่งขั้นสูง is confirmed. Whether Notepad, Paint and Windows Terminal show in Thai; แอปที่ติดตั้ง. Microsoft's Thai pages say ลงชื่อเข้าใช้ for "sign in"; the catalog says เข้าสู่ระบบ. |
| hi | all four protection-*, security-list-title, Windows Update vs Windows अपडेट, Start button name, Snipping Tool, consequence-mitigations-disable, playbook-page-defender-enable-description, prepare-description, check-fix-apps, consequence-disable-hibernation, consequence-disable-core-isolation | No Hindi Microsoft text could be fetched and Hindi Windows coverage is partial; a Hindi PC may show some switches in English. Every feature name in the table above is reasoned, as are कार्य प्रबंधक, नोटपैड/पेंट/Windows टर्मिनल, the folder names and इंस्टॉल किए गए ऐप्स; शोषण usually means the exploitation of people. "मेमोरी अखंडता (Memory integrity)" and "तेज़ स्टार्टअप (Fast Startup)" keep English in brackets until confirmed. The nukta is applied to क़ only in मुताबिक़; pick one rule. |
