# Translation guidance

This page sets the terms, Windows names and conventions for each language in Atlas Manager's Fluent catalogs, for translators and the native speakers who review their work.
For how languages are implemented and how the catalog checks work, see [Languages in Atlas Manager](i18n.md); for the copy conventions every language shares, see the [app writing guide](writing.md).

Every non-English catalog is a preview until a native speaker reviews it.
Before you mark a catalog reviewed, check its Windows names and open questions against localised Windows.

## Atlas package and step names

The `.apbx` file is the Atlas package in every language, shortened once it's clear.
Interface text never says "playbook" in any language.
The `playbook-*` message ids, `i18n/playbook-source.ftl` and the `embedded-playbook` feature keep their names.
The ISO flow's third step reuses **Your choices** (`step-options`) from the install flow.

| Locale | Atlas package, then its short form | Install steps (`step-*`) | ISO steps 1, 2 and 4 (`iso-review-files`, `iso-step-windows`, `iso-step-review`) |
| --- | --- | --- | --- |
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

Name the features Atlas turns off as Windows shows them in your language.
They appear in `consequence-mitigations-disable` (Exploit protection, Control Flow Guard) and `playbook-page-defender-enable-description` (the other three).
Each row has the weakest status of any name in it:

| Status | Meaning |
| --- | --- |
| Confirmed in localised Windows | The name matches what Windows shows in that language, and no open question disputes it. |
| Microsoft documentation | Microsoft's localised pages use the name, but it isn't confirmed on screen. |
| Reasoned, unconfirmed | The name has no source, hasn't been checked, or differs from Microsoft's pages and isn't confirmed. |

Each locale's open questions, under [Locale conventions](#locale-conventions), name the features still in doubt and list the candidates.

| Locale | Exploit protection | Control Flow Guard | Smart App Control | Enhanced Phishing Protection | Find my device | Status |
| --- | --- | --- | --- | --- | --- | --- |
| de | Exploit-Schutz | Ablaufsteuerungsschutz (CFG) | Intelligente App-Steuerung | Erweiterter Phishingschutz | „Mein Gerät suchen“ | Reasoned, unconfirmed |
| es | Protección contra vulnerabilidades | Protección de flujo de control (CFG) | Control inteligente de aplicaciones | Protección mejorada contra suplantación de identidad | Encontrar mi dispositivo | Microsoft documentation |
| fr | Exploit Protection (English, as French Windows shows it) | Protection du flux de contrôle (CFG) | Contrôle intelligent des applications | Protection renforcée contre l’hameçonnage | Localiser mon appareil | Microsoft documentation |
| pt-BR | Proteção contra vulnerabilidades | Proteção de fluxo de controle (CFG) | Controle Inteligente de Aplicativos | Proteção aprimorada contra phishing | Localizar meu dispositivo | Microsoft documentation |
| pl | Ochrona przed lukami w zabezpieczeniach | Ochrona przepływu sterowania (CFG) | Inteligentna kontrola aplikacji | Rozszerzona ochrona przed wyłudzaniem informacji | Znajdź moje urządzenie | Reasoned, unconfirmed |
| ru | защита от эксплойтов | защита потока управления (CFG) | «Интеллектуальное управление приложениями» | «Расширенная защита от фишинга» | «Поиск устройства» | Reasoned, unconfirmed |
| tr | Açıktan yararlanma koruması | Denetim akışı koruması (CFG) | Akıllı Uygulama Denetimi | Gelişmiş Kimlik Avı Koruması | Cihazımı bul | Reasoned, unconfirmed |
| zh-Hans | Exploit Protection (English) | 控制流保护 (CFG) | 智能应用控制 | 增强型网络钓鱼防护 | 查找我的设备 | Reasoned, unconfirmed |
| zh-Hant | 惡意探索保護 | 控制流程防護（CFG） | 智慧型應用程式控制 | 增強式網路釣魚保護 (the Group Policy name) | 尋找我的裝置 | Reasoned, unconfirmed |
| ja | Exploit Protection (Latin letters, as Japanese Windows shows it) | 制御フロー ガード | スマート アプリ コントロール | 拡張フィッシング保護 | デバイスの検索 | Microsoft documentation |
| id | Perlindungan eksploitasi | Control Flow Guard (English) | Kontrol Aplikasi Pintar | Perlindungan pengelabuan (the switch's own label) | Temukan perangkat saya | Reasoned, unconfirmed |
| th | การป้องกัน Exploit | Control Flow Guard (English) | การควบคุมแอปแบบอัจฉริยะ | การป้องกันฟิชชิ่งขั้นสูง | ค้นหาอุปกรณ์ของฉัน | Reasoned, unconfirmed |
| hi | शोषण से सुरक्षा | नियंत्रण प्रवाह गार्ड (CFG) | स्मार्ट ऐप नियंत्रण | उन्नत फ़िशिंग सुरक्षा | मेरा डिवाइस ढूँढें | Reasoned, unconfirmed |

## Protection switch names

Name the four Windows Security protection switches (`protection-tamper`, `protection-realtime`, `protection-cloud` and `protection-samples`) as Windows shows them in your language.
The settings page is the **Virus & threat protection settings** page that holds them, named in `security-list-title`.
Status works as it does for [Windows feature names](#windows-feature-names), and each locale's open questions say which names are disputed.

| Locale | Tamper Protection | Real-time protection | Cloud-delivered protection | Automatic sample submission | Settings page | Status |
| --- | --- | --- | --- | --- | --- | --- |
| de | Manipulationsschutz | Echtzeitschutz | Cloudbasierter Schutz | Automatische Übermittlung von Beispielen | Einstellungen für Viren- & Bedrohungsschutz | Reasoned, unconfirmed |
| es | Protección contra alteraciones | Protección en tiempo real | Protección basada en la nube | Envío automático de muestras | Configuración de antivirus y protección contra amenazas | Microsoft documentation |
| fr | Protection contre les falsifications | Protection en temps réel | Protection dans le cloud | Envoi automatique d’un échantillon | Paramètres de protection contre les virus et menaces | Microsoft documentation |
| pt-BR | Proteção contra violações | Proteção em tempo real | Proteção fornecida pela nuvem | Envio automático de amostra | Configurações de proteção contra vírus e ameaças | Microsoft documentation |
| pl | Ochrona przed naruszeniami | Ochrona w czasie rzeczywistym | Ochrona dostarczana z chmury | Automatyczne przesyłanie próbek | Ustawienia ochrony przed wirusami i zagrożeniami | Reasoned, unconfirmed |
| ru | Защита от подделки | Защита в режиме реального времени | Облачная защита | Автоматическая отправка образцов | Параметры защиты от вирусов и других угроз | Reasoned, unconfirmed |
| tr | Kurcalama Koruması | Gerçek zamanlı koruma | Bulut tabanlı koruma | Otomatik örnek gönderimi | Virüs ve tehdit koruması ayarları | Microsoft documentation |
| zh-Hans | 篡改防护 | 实时保护 | 云提供的保护 | 自动提交样本 | “病毒和威胁防护”设置 | Microsoft documentation |
| zh-Hant | 竄改防護 | 即時保護 | 雲端提供的保護 | 自動提交範例 | 病毒與威脅防護設定 | Microsoft documentation |
| ja | 改ざん防止 | リアルタイム保護 | クラウド提供の保護 | サンプルの自動送信 | ウイルスと脅威の防止の設定 | Reasoned, unconfirmed |
| id | Proteksi Kerusakan | Perlindungan real-time | Perlindungan yang dikirimkan cloud | Pengiriman sampel otomatis | Pengaturan perlindungan virus & ancaman | Reasoned, unconfirmed |
| th | การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย | การป้องกันแบบเรียลไทม์ | การป้องกันบนระบบคลาวด์ | การส่งตัวอย่างโดยอัตโนมัติ | การตั้งค่าการป้องกันไวรัสและภัยคุกคาม | Microsoft documentation |
| hi | छेड़छाड़ से सुरक्षा | रीयल-टाइम सुरक्षा | क्लाउड-आधारित सुरक्षा | स्वचालित नमूना सबमिशन | वायरस और ख़तरे से सुरक्षा सेटिंग्स | Reasoned, unconfirmed |

## Locale conventions

These rules hold in every language:

- Name a control by its exact label in your catalog, quoted as your language quotes labels.
- `list-and` joins the last two items of a list, and `$a` may already hold several items joined with `list-separator`.
- **Report a problem** (`home-report-problem`) opens the in-app **Send a report** page, so its label names no website.
- Where your language uses one word for both, keep the four flow steps apart from the stages of updating or of creating an ISO.

Each locale's section starts with a one-row table of its main choices, then bullets with the rest of its conventions, then its open questions for native reviewers.
The relaunch column gives the verb for reopening Atlas, then the one for restarting the PC.
The switch names column gives the locale's collective term for the protection switches, or links to their Windows names where the locale has no such term.

### German (`de`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Sie, with "Ihr PC" | "als Administrator ausführen" (app), "neu starten" (PC) | „…“ around quoted button and step names | "Ihre Auswahl" | See [protection switch names](#protection-switch-names) |

- Buttons are infinitives, and buttons that Windows also uses keep their Windows names (Zurück, Weiter, Abbrechen, Fertig).
- Processor protections are "Prozessorschutz", never "Prozessorsicherheit".
- Security mitigations are "Mitigationen".
- **Open log folder** is "Protokollordner öffnen", and **Stop updating** is "Updates anhalten".
- Use "Diagnose-ZIP" in titles and "Diagnose-ZIP-Datei" in body text.
- "Antivirensoftware" is an app, and "Virenschutz" is the protection.
- Keep "Startmenü" (the Start menu) apart from "Boot-Menü" (the firmware menu).
- "No installation changes were made" is "Die Installation hat nichts geändert".

#### Open questions

- `protection-cloud`, `protection-samples`, `security-list-title`: does Windows show "Cloudbasierter Schutz" and "Automatische Übermittlung von Beispielen", or Microsoft's wording, "Über/In der Cloud bereitgestellter Schutz" and "Automatische Beispielübermittlung"?
  Check the page title, "Einstellungen für Viren- & Bedrohungsschutz", at the same time.
- `prepare-description`: Start shows "Terminal", not "Windows-Terminal"; which name should the text use?
- `playbook-page-defender-enable-description`: do "Intelligente App-Steuerung" and "Erweiterter Phishingschutz" keep their capitals mid-sentence?
- `consequence-mitigations-disable`: what's the exact Control Flow Guard label on the Exploit-Schutz page?
- `playbook-page-mitigations-default-description`: "Mitigationen", or Microsoft's "Entschärfungen" or "Risikominderungen"?
- `consequence-defender-disable`: SmartScreen's own dialog says "unbekannte App", but the catalog says "nicht erkannte Apps"; which should it say?

### Spanish (`es`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Implicit usted | "volver a abrir" (app), "reiniciar" (PC) | None around labels | "Sus preferencias" | See [protection switch names](#protection-switch-names) |

- Use international vocabulary: agregar, quitar, administrar, aplicación.
- Wrap questions in `¿…?`.
- Use "su PC" with a possessive, and "el equipo" where an adjective must agree.
- Never use "equipo" (the PC) and "equipo de Atlas" (the team) in one sentence.
- **Open log folder** is "Abrir la carpeta de registros".
- **Stop updating**, "Detener actualizaciones", pairs with **Continue updates**, "Continuar actualizaciones".
- Processor protections are "Protecciones del procesador".
- Name cards exactly ("Comprobaciones del equipo", "Archivos de instalación", "Actualizar Windows y las apps de la Store"), but running text says "aplicaciones de la Store".
- "Unsupported" is "no cuenta con soporte", because "no es compatible" means incompatible.
- Titles say "No se pudo…".
- "Internet" is capitalised.
- Use "en cuanto…", not the Spain-only "nada más" + infinitive.

#### Open questions

- `protection-cloud`, `security-list-title`: is the cloud switch "basada en la nube" or "proporcionada desde la nube"?
  Check the page title at the same time.
- Whole catalog: usted or tú?
  Microsoft's consumer pages use tú.
- `playbook-page-defender-enable-description`: should Enhanced Phishing Protection add "(phishing)", as Microsoft's machine-translated Spanish page does?
- `prepare-description`: is the app "Terminal Windows" in Spanish Windows?

### French (`fr`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| vous | "relancer" (app), "redémarrer" (PC) | « » with U+00A0 inside | "Vos choix" | "paramètres de protection" |

- Put U+00A0 before `: ; ? !` and `%`.
- Use the typographic apostrophe.
- Buttons are infinitives.
- Build is feminine: "la build".
- « étape » means only the four flow steps; an update stage is « opération ».
- « ce PC » is always the PC running Atlas; the one being reinstalled is « ce même PC » or « le PC à réinstaller ».
- Cards are named bare (« Vérifications du PC »), except the infinitive « Mettre à jour Windows et les applications du Store », which goes in « ».
- **Open log folder** is « Ouvrir le dossier des journaux », and **Stop updating** is « Arrêter les mises à jour ».
- The data is « les diagnostics », and the file is « ZIP de diagnostic ».
- Stage statuses are feminine, like the stepper's (« en cours », « non commencée »).

#### Open questions

- `protection-cloud`: "Protection dans le cloud" or "Protection fournie par le cloud"?
  Microsoft's pages use both.
- `security-list-title`: "et" or "&"?
- `playbook-page-defender-enable-description`: is Enhanced Phishing Protection « Protection renforcée contre l’hameçonnage », or the section's own title, « Protection contre l’hameçonnage »?
- `prepare-description`: Start shows « Terminal », not « Terminal Windows »; which name should the text use?

### Brazilian Portuguese (`pt-BR`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Implicit você, with "seu PC" | "reabrir" (app), "reiniciar" (PC) | None around labels | "Suas escolhas" | "as quatro proteções" |

- "o Atlas" and "o Windows" take the article.
- Buttons are infinitives.
- The switch states (`security-switch-on`, `security-switch-off`) match Windows' invariant Ativado/Desativado.
- Refer to a step as in "à etapa Preparação".
- The catalog also serves pt-PT, so use neutral forms where they exist.
- A check that passes "é aprovada", not "passa".
- Name cards as in "em Verificações do PC" and "no cartão Atualizar o Windows e os apps da Store".
- Processor protections are "Proteções do processador".
- **Open log folder** is "Abrir pasta de logs", and **Stop updating** is "Parar atualizações".
- A test build is "versão de teste", and a release build is "versão oficial".
- Package builds are "versão completa do pacote" and "versão LocalTest".
- Stage states agree with "etapa" ("em andamento", "não iniciada", "concluída").
- Plurals are `one` and `other`, and `one` covers 0.

#### Open questions

- `protection-tamper`, `protection-cloud`: is Tamper Protection "Proteção contra violações", "Proteção contra Violações" or a form with "adulterações", and is the cloud switch "fornecida pela nuvem" or "na nuvem"?
- `playbook-page-defender-enable-description`: is Enhanced Phishing Protection "aprimorada" or "avançada"?
  Microsoft's pages use both; this is low priority.
- `detail-windows-preview`, `detail-windows-release-unknown`, `detail-windows-release-unlisted`, `iso-release-unlisted`: "build" or "compilação"?
  Three strings say "build" and four say "compilação"; check which one Brazilian Windows uses, then use it in all of them.

### Polish (`pl`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Second person, with Twój and Ci capitalised | "otwórz Atlas ponownie" (app), "uruchom ponownie" (PC) | None around labels | "Opcje", because "wybory" also means elections | See [protection switch names](#protection-switch-names) |

- "Atlas" is declined (Atlasa, Atlasie, Atlasem), and so is "Zabezpieczenia Windows"; Windows and Defender aren't.
- Use all four plural categories on every count.
- "krok" is only for the four flow steps; update and ISO stages are "etap".
- Cards are `w sekcji <title>` ("w sekcji Sprawdzanie komputera"), never "karta", which reads as a tab.
- Radio options take "zaznacz", and buttons take "wybierz".
- Metered and unmetered are "taryfowe" and "nietaryfowe", not "bez ustawionego limitu", which is the separate data limit.
- Statuses shared by steps and stages are impersonal ("ukończono", "nie rozpoczęto").
- Never use the reader's gendered past tense: "wybrano", "Jeśli korzystasz już z Windows".
- **Open log folder** is "Otwórz folder dzienników", and **Stop updating** is "Zatrzymaj aktualizowanie".
- Security mitigations are "środki zaradcze".
- AI is "sztuczna inteligencja".

#### Open questions

- `protection-cloud`: is the cloud switch "Ochrona dostarczana z chmury", or one of the forms Microsoft's pages use: "chmurowa", "w chmurze" or the English name?
- `consequence-mitigations-disable`: is Exploit protection "Ochrona przed lukami w zabezpieczeniach", or one of Microsoft's forms: "Ochrona przed exploitami", "ochrona przed programami wykorzystującymi luki" or the English name?
- `playbook-page-defender-enable-description`: is Enhanced Phishing Protection "Rozszerzona…", "Ulepszona…" or the switch's own label, "Ochrona przed wyłudzaniem informacji"?
  No Microsoft page uses "Rozszerzona…".
- `playbook-page-defender-enable-description`: is Smart App Control "Inteligentna kontrola aplikacji", or "Kontrola aplikacji inteligentnej" as one older Microsoft page has it?
- `playbook-page-defender-enable-description`, `check-fix-apps`, `prepare-description`: do Find my device ("Znajdź moje urządzenie"), Installed apps, Notepad and Windows Terminal match Polish Windows?
  None of them has been checked.

### Russian (`ru`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| вы (lower case) | "перезапустить" (app), "перезагрузить" (PC) | «…», with „…“ for a quote inside a label («Открыть „Безопасность Windows“») | "Ваш выбор" | See [protection switch names](#protection-switch-names) |

- Buttons are imperatives.
- The user's choices are "настройки", and the app's Settings page is "параметры".
- Use all four plural categories; a regression test keeps 1/21/101 минута.
- The switch states (`security-switch-on`, `security-switch-off`) are Вкл./Откл.
- Quote a control with its exact label (нажмите «Повторить попытку»).
- Cards on the **Get ready** page are «раздел «…»».
- Update stages are «этап», and flow steps are «шаг».
- «этот ПК» is only the PC running Atlas; the one being reinstalled is «тот ПК».
- Always «ПК», never «компьютер».
- First-person rows avoid the gendered past tense («Я даю согласие…», «Когда я…»).
- "Microsoft account" is «учётная запись Майкрософт».
- SmartScreen stays in Latin letters.
- **Open log folder** is «Открыть папку журналов», and **Stop updating** is «Остановить обновление».

#### Open questions

- `protection-tamper`: is Tamper Protection "Защита от подделки", as quoted from the interface, or "Защита от незаконного изменения", as Microsoft's documentation says?
- `security-list-title`: does the page heading include "и других угроз"?
- `security-switch-off`: is the off state "Откл."?
- `consequence-mitigations-disable`, `playbook-page-defender-enable-description`: do Exploit protection, Control Flow Guard and Smart App Control match Russian Windows, and is Enhanced Phishing Protection «Расширенная» or «Улучшенная»?
  None of the four has been checked.
- `usb-title` and the other флешка strings: «флешка», or Microsoft's «USB-накопитель»?
- `iso-step-review`: «Проверка» for Review is also the Checking status; should Review be «Сводка»?
  Switch to it if testers mix the two up.

### Turkish (`tr`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| siz | "yeniden aç" (app), "yeniden başlat" (PC) | None around labels | "Seçimleriniz" | See [protection switch names](#protection-switch-names) |

- Suffixes on proper nouns follow an apostrophe (Atlas'ı, Windows'u).
- Never put a suffix on a variable; a noun follows it instead: "{ $version } sürümünü".
- Name a control by its label, then an apostrophe, its suffix and "seçin" ("Yeniden dene'yi seçin", "Atlas'ı kur'u seçin").
- A radio option takes "… seçeneğini belirleyin".
- Card titles are noun phrases so text can name them: the update card is "Windows ve Store güncellemeleri" ("… kartında").
- "kur" installs Atlas; "yükle" installs updates, apps, drivers and Windows.
- Use "denetle", not "kontrol et".
- Build is "derleme", and diagnostics are "tanılama verileri".
- "No installation changes were made" is "Kurulum hiçbir değişiklik yapmadı", never "Bilgisayarınızda…".
- Mitigations are "güvenlik risk azaltmaları".
- In privacy text, "kept" is "kaldırılmaz".
- **Open log folder** is "Günlük klasörünü aç", and **Stop updating** is "Güncellemeyi durdur".

#### Open questions

- `protection-tamper`: "Kurcalama Koruması", "Kurcalama koruması" or "Değişiklik Koruması"?
- `security-list-title`: "ve" or "&"?
- Fast Startup (`consequence-disable-hibernation`): "Hızlı Başlatma" or "Hızlı başlatma"?
- `consequence-mitigations-disable`: does Control Flow Guard end in "koruması" or "koruyucusu"?
- `playbook-page-defender-enable-description`: how is "Gelişmiş Kimlik Avı Koruması" capitalised?
- Whole catalog: "güncelleştirme", Microsoft's term, appears on the home page, in PC checks and on the **Your choices** page, but the update card on the **Get ready** page says "güncelleme".
  Which should the whole catalog use?
- Whole catalog: the catalog mixes ' and ’ by section; which should it use throughout?

### Simplified Chinese (`zh-Hans`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| 你, as in Windows 11 zh-CN, and 电脑 for the PC | 重新打开 (app), 重启 (PC) | “…” | "你的选择" | 关闭 and 重新开启 |

- Punctuation is full-width.
- Put a space between Chinese and Latin letters or digits.
- Latin-only asides take half-width brackets.
- `list-and` joins with 和, without spaces.
- Removing Defender is 移除, because it's permanent.
- 安装文件 means prepared files, never the .apbx.
- Processor protections are 处理器防护, not 处理器安全.
- Review is 核对 in the install summary and 检查 in the ISO, USB and report flows.
- The USB is U 盘 in titles, and USB 驱动器 in lists and the erase text.
- Erasing is 清空 in titles and buttons, and 永久删除 in body text.
- Edge bookmarks are 收藏夹.
- Windows setup, the program, is Windows 安装程序, and OOBE is Windows 初始设置.
- **Open log folder** is 打开日志文件夹, and **Stop updating** is 停止更新.

#### Open questions

- `security-list-title`: should the page title keep its quotation marks, as in “病毒和威胁防护”设置?
- `protection-samples`: 样本 or 示例?
- `protection-cloud`: 云提供的保护 or 云保护?
- `consequence-mitigations-disable`: does Chinese Windows show "Exploit Protection" in English, and is Control Flow Guard 控制流保护 (CFG)?
- `playbook-page-defender-enable-description`: Enhanced Phishing Protection is 增强型网络钓鱼防护, but the Windows Security switch reads 网络钓鱼防护; which should the text use?

### Traditional Chinese (`zh-Hant`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| 您 | 重新開啟 Atlas (app), 重新啟動 (PC) | 「」 around controls named in text | "您的選擇" | See [protection switch names](#protection-switch-names) |

- Use the Taiwan glossary: 設定, 系統管理員, 檔案, 資料夾, 網路, 組建, 佈景主題.
- Punctuation is full-width.
- Brackets are full-width even around Latin-only text: （.apbx）, （UAC）.
- `list-and` joins with 和, without spaces.
- Processor protections are 處理器防護, not 處理器安全性.
- Security mitigations are 安全性緩和措施.
- Erasing is 清除 throughout.
- Edge's 「我的最愛」 is always quoted.
- Store apps are 市集應用程式.
- Controls named in text include **Open log folder** (開啟記錄資料夾), **Stop updating** (停止更新), **Report a problem** (回報問題), **Send a report** (傳送報告) and **Help and feedback** (說明與意見反應).

#### Open questions

- `protection-samples`: 自動提交範例, 提交自動樣本 or 自動提交樣本?
- `protection-tamper`: older Windows 10 builds use 防竄改保護 rather than 竄改防護; which should the text use?
- `consequence-mitigations-disable`, `playbook-page-defender-enable-description`, `iso-network-inbox`: do 惡意探索保護, 控制流程防護, 智慧型應用程式控制, 增強式網路釣魚保護, 尋找我的裝置 and 網路介面卡 match Taiwanese Windows?
  The Enhanced Phishing Protection switch itself reads 網路釣魚保護.
- `iso-step-review`, `usb-review`, `report-review`: Review is 檢閱 in the ISO flow but 檢查 for the USB and the report ZIP; should they match?
- `detail-windows-release-unlisted`, `iso-release-unlisted`: should the Release Preview channel stay in Latin letters, or become 版本預覽通道, 發行預覽 or 版本預覽?
  Taiwanese Windows shows 版本預覽通道 in screenshots, while Microsoft's pages mix 發行預覽, 版本預覽 and Release Preview.

### Japanese (`ja`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| です・ます | 管理者として再実行 (app), 再起動 (PC) | 「」 | "設定の選択" | See [protection switch names](#protection-switch-names) |

- Buttons end in a noun (完了, 今すぐ再起動).
- Put a half-width space between Japanese and Latin text, and inside katakana compounds.
- Use 。 and 、 with half-width ( ) and ": ", as Microsoft's Japanese UI does.
- `list-and` joins with 、, without spaces.
- The counter is 件 for updates and 個 for switches.
- The USB list's **Refresh** is 一覧を更新, because bare 更新 means "update" here.
- "Antivirus app" is ウイルス対策アプリ; use ソフト only where the English says "software".
- Edge bookmarks are お気に入り.
- Status words are 進行中, 失敗, 未開始 and 完了, and stage names end in 〜中.
- **Open log folder** is ログ フォルダーを開く, and **Stop updating** is 更新を停止.

#### Open questions

- `protection-cloud`, `protection-samples`, `security-list-title`: do クラウド提供の保護, サンプルの自動送信 and ウイルスと脅威の防止の設定 match Japanese Windows?
  Microsoft's machine-translated Japanese support page words them differently.
- Relaunching Atlas: 再実行 or 開き直す?
- `playbook-page-defender-enable-description`: is Enhanced Phishing Protection 拡張フィッシング保護 or 強化されたフィッシング保護, as different Microsoft pages call it, or フィッシング対策, as the switch reads?
  拡張フィッシング保護 is the title of Microsoft's Japanese documentation page.
- `detail-windows-release-unlisted`, `iso-release-unlisted`: should the Release Preview channel stay in Latin letters, or does Japanese Windows show リリース プレビュー in Settings, as Microsoft's machine-translated Japanese Insider pages suggest?

### Indonesian (`id`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Anda, formal-neutral | "jalankan ulang" (app), "mulai ulang" (PC), "buka kembali" after a restart | None around labels | "Pilihan Anda" | "pengaturan (perlindungan)" |

- Plurals use only `other`.
- "penginstalan" is the Atlas install, and "instalasi Windows" is a Windows installation.
- "No installation changes were made" is "Penginstalan belum mengubah apa pun", never a claim about the whole PC.
- Use "Hubungkan", not "Sambungkan".
- Use "file", not "berkas".
- Use "Setelah itu," rather than a sentence starting with "Lalu".
- **Open package file** is "Buka file paket", **Open log folder** is "Buka folder log", **Stop updating** is "Hentikan pembaruan" and **Help and feedback** is "Bantuan dan masukan".
- "needs attention" is "perlu diperhatikan".

#### Open questions

- `protection-tamper`, `protection-cloud`, `security-list-title`: does Indonesian Windows show "Proteksi Kerusakan", "Perlindungan yang dikirimkan cloud" and "Pengaturan perlindungan virus & ancaman"?
  Microsoft's machine-translated pages disagree with each other and give eight renderings of Tamper Protection between them.
- Fast Startup (`consequence-disable-hibernation`): what does Indonesian Windows call it?
- `consequence-mitigations-disable`, `playbook-page-defender-enable-description`, `check-fix-apps`: do Perlindungan eksploitasi, Perlindungan pengelabuan, Temukan perangkat saya and Aplikasi yang diinstal match Indonesian Windows?
  Kontrol Aplikasi Pintar matches Microsoft's Indonesian Smart App Control FAQ.
- `consequence-mitigations-disable`, `prepare-description`: Control Flow Guard, Notepad, Paint and Windows Terminal stay in English until confirmed; what does Indonesian Windows call them?
- `list-and`: should lists of three or more read "A, B, dan C", as PUEBI and CLDR want, rather than "A, B dan C"?
  That needs a separate message for the last of three or more.

### Thai (`th`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| คุณ | เปิด Atlas ใหม่ (app), รีสตาร์ต (PC) | None; a control named in text has a space either side | "ตัวเลือกของคุณ" | See [protection switch names](#protection-switch-names) |

- Sentences have no final full stop.
- Put a space between clauses and around Latin letters or digits.
- Use classifiers instead of plurals.
- Call Windows Security "แอป ความปลอดภัยของ Windows" where the app is opened.
- Diagnostics are ข้อมูลการวินิจฉัย.
- Review is ตรวจทาน; ตรวจสอบ is checking and verifying.
- Restart is only รีสตาร์ต, never รีสตาร์ท or เริ่มระบบใหม่.
- Build is บิลด์; รุ่น is an edition or release.
- Beta is เบต้า and Ethernet is อีเทอร์เน็ต; Wi-Fi stays Latin.
- Don't use โปรด.
- Question titles have no "?".
- Cards are `ในการ์ด <label>`.

#### Open questions

- `protection-tamper`, `protection-cloud`, `security-list-title`: do การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย and การป้องกันบนระบบคลาวด์ match Thai Windows, and does the page title use "และ" or "&"?
- Memory integrity (`consequence-disable-core-isolation`): ความสมบูรณ์ or ความถูกต้อง ของหน่วยความจำ?
- Fast Startup (`consequence-disable-hibernation`): what does Thai Windows call it?
- `playbook-page-defender-enable-description`: only ฟิชชิ่ง in การป้องกันฟิชชิ่งขั้นสูง is confirmed; does Thai Windows word the rest of the name the same way?
- `prepare-description`, `check-fix-apps`: do Notepad, Paint and Windows Terminal show in Thai, and is Installed apps แอปที่ติดตั้ง?
- Sign-in strings: Microsoft's Thai pages say ลงชื่อเข้าใช้ for "sign in", but the catalog says เข้าสู่ระบบ; which should it use?

### Hindi (`hi`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| आप, with respectful imperatives | "दोबारा खोलें" (app), "रीस्टार्ट करें" (PC) | “ ” around card titles and labels, except the step तैयारी | "आपके विकल्प" | See [protection switch names](#protection-switch-names) |

- The danda is the only sentence terminator.
- Loanwords follow Microsoft's style in Devanagari (इंस्टॉल, अपडेट, सेटिंग्स, फ़ाइल), with the nukta applied consistently.
- The decision caption is "पसंद".
- The Atlas package, ISO and USB are masculine (नया ISO); USB ड्राइव and ISO फ़ाइल are feminine.
- Diagnostics are डायग्नोस्टिक्स (masculine plural), never निदान.
- "PC" stays Latin, never पीसी.
- Use इंस्टॉलेशन, not स्थापना.
- Use रीस्टार्ट, not पुनः आरंभ.
- **Try again** is "फिर कोशिश करें".
- Use अगर, not यदि.
- First-person text stays gender-neutral (मेरी कोशिश थी कि…, "X ख़ुद इंस्टॉल करें").

#### Open questions

- `protection-tamper`, `protection-realtime`, `protection-cloud`, `protection-samples`, `security-list-title`: do these five names match Hindi Windows?
  Hindi Windows coverage is partial, so a Hindi PC may show some switches in English.
- Windows Update, the Start button and Snipping Tool: does Hindi Windows say Windows Update or Windows अपडेट, and what does it call the Start button and Snipping Tool?
- `consequence-mitigations-disable`, `playbook-page-defender-enable-description`: does Hindi Windows use the feature names in the table?
  All of them are reasoned, and शोषण usually means the exploitation of people.
- `prepare-description`, `check-fix-apps`: do कार्य प्रबंधक, नोटपैड/पेंट/Windows टर्मिनल, the folder names and इंस्टॉल किए गए ऐप्स match Hindi Windows?
  All of them are reasoned.
- `consequence-disable-core-isolation`, `consequence-disable-hibernation`: "मेमोरी अखंडता (Memory integrity)" and "तेज़ स्टार्टअप (Fast Startup)" keep English in brackets until confirmed; can they drop it?
- Whole catalog: the nukta is applied to क़ only in मुताबिक़; which rule should the catalog follow?
