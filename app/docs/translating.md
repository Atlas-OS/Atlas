# Translation guidance

This page sets the terms, Windows names and conventions for each language in Atlas Manager's Fluent catalogs, for translators and the native speakers who review their work.
For how languages are implemented and how the catalog checks work, see [Languages in Atlas Manager](i18n.md); for the copy conventions every language shares, see the [app writing guide](writing.md).

Every non-English catalog is a preview until a native speaker reviews it.
Before you mark a catalog reviewed, check its Windows names and open questions against localised Windows.

## Atlas package and step names

The `.atlaspkg` file is the Atlas package in every language, shortened once it's clear.
Interface text never says "playbook" in any language.

| Locale | Atlas package, then its short form | Install steps (`step-*`) | ISO steps (`iso-step-*`) |
| --- | --- | --- | --- |
| de | Atlas-Paket, Paket; the file is the Paketdatei | Vorbereiten, Ihre Auswahl, Windows-Sicherheit, Installieren | Windows, Einrichtung, Erstellen |
| es | paquete de Atlas, el paquete | Preparación, Sus preferencias, Seguridad de Windows, Instalación | Windows, Configuración, Creación |
| fr | package Atlas (masculine), le package | Préparation, Vos choix, Sécurité Windows, Installation | Windows, Configuration, Création |
| pt-BR | pacote do Atlas, o pacote | Preparação, Suas escolhas, Segurança do Windows, Instalação | Windows, Configuração, Criação |
| pl | pakiet Atlasa, pakiet; the file is plik pakietu | Przygotowanie, Opcje, Zabezpieczenia Windows, Instalacja | Windows, Konfiguracja, Tworzenie |
| ru | пакет Atlas (declined: пакета, пакетом), пакет; the summary row is Пакет Atlas | Подготовка, Ваш выбор, Безопасность Windows, Установка | Windows, Настройка, Создание |
| tr | Atlas paketi, paket | Hazırlık, Seçimleriniz, Windows Güvenliği, Kurulum | Windows, Yapılandırma, Oluşturma |
| zh-Hans | Atlas 安装包, 安装包 | 准备, 你的选择, Windows 安全中心, 安装 | Windows, 配置, 创建 |
| zh-Hant | Atlas 套件, 套件 | 準備, 您的選擇, Windows 安全性, 安裝 | Windows, 安裝設定, 建立 |
| ja | Atlas パッケージ, パッケージ | 準備, 設定の選択, Windows セキュリティ, インストール | Windows, セットアップ, 作成 |
| id | paket Atlas, paket; the summary row is Paket Atlas | Persiapan, Pilihan Anda, Keamanan Windows, Instal | Windows, Penyiapan, Buat |
| th | แพ็กเกจ Atlas, แพ็กเกจ | เตรียมความพร้อม, ตัวเลือกของคุณ, ความปลอดภัยของ Windows, ติดตั้ง | Windows, ตั้งค่า, สร้าง |
| hi | Atlas पैकेज (masculine), पैकेज | तैयारी, आपके विकल्प, Windows सुरक्षा, इंस्टॉल | Windows, सेटअप, बनाएँ |

## Windows feature names

Name the features Atlas turns off as Windows shows them in your language.
They appear in `consequence-mitigations-disable` (Exploit protection, Control Flow Guard) and `package-choice-defender-description` (the other three).
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

## Storage settings and services

Name the Windows pages and services that Atlas sends people to as Windows shows them in your language.
**Storage settings** opens from `check-fix-storage` and `usb-open-storage`, and **Services** opens from `prepare-open-services`.
`windows-outcome-blocked-service` asks people to set a service to **Manual** in Services, and `service-bits`, `service-cryptsvc` and `service-trusted-installer` name the services.
Status works as it does for [Windows feature names](#windows-feature-names), and each locale's open questions ask for these names to be checked.

| Locale | Storage settings | Services | Manual | BITS | Cryptographic Services | Windows Modules Installer | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| de | Speichereinstellungen | Dienste | Manuell | Intelligenter Hintergrundübertragungsdienst (BITS) | Kryptografiedienste | English | Reasoned, unconfirmed |
| es | Almacenamiento | Servicios | Manual | Servicio de transferencia inteligente en segundo plano (BITS) | Servicios de cifrado | Instalador de módulos de Windows | Reasoned, unconfirmed |
| fr | paramètres de stockage | Services | Manuel | Service de transfert intelligent en arrière-plan (BITS) | Services de chiffrement | Programme d’installation pour les modules Windows | Reasoned, unconfirmed |
| pt-BR | configurações de armazenamento | Serviços | Manual | Serviço de Transferência Inteligente de Plano de Fundo (BITS) | Serviços de Criptografia | Instalador de Módulos do Windows | Reasoned, unconfirmed |
| pl | ustawienia magazynu | Usługi | Ręczny | Usługa inteligentnego transferu w tle (BITS) | Usługi kryptograficzne | Instalator modułów systemu Windows | Reasoned, unconfirmed |
| ru | параметры памяти | Службы | Вручную | Фоновая интеллектуальная служба передачи (BITS) | Службы криптографии | Установщик модулей Windows | Reasoned, unconfirmed |
| tr | Depolama ayarları | Hizmetler | El ile | Arka Plan Akıllı Aktarım Hizmeti (BITS) | Şifreleme Hizmetleri | Windows Modül Yükleyicisi | Reasoned, unconfirmed |
| zh-Hans | 存储设置 | 服务 | 手动 | English | English | English | Reasoned, unconfirmed |
| zh-Hant | 「儲存體」設定 | 服務 | 手動 | 背景智慧型傳送服務（BITS） | 密碼編譯服務 | English | Reasoned, unconfirmed |
| ja | ストレージ設定 | サービス | 手動 | English | English | English | Reasoned, unconfirmed |
| id | pengaturan Penyimpanan | Layanan | Manual | Layanan Transfer Cerdas Latar Belakang (BITS) | Layanan Kriptografi | Penginstal Modul Windows | Reasoned, unconfirmed |
| th | การตั้งค่าที่เก็บข้อมูล | บริการ | ด้วยตนเอง | บริการโอนย้ายข้อมูลอัจฉริยะเบื้องหลัง (BITS) | บริการการเข้ารหัสลับ | ตัวติดตั้งโมดูลของ Windows | Reasoned, unconfirmed |
| hi | संग्रहण सेटिंग्स | सेवाएँ | मैन्युअल | बैकग्राउंड इंटेलिजेंट ट्रांसफ़र सेवा (BITS) | क्रिप्टोग्राफ़िक सेवाएँ (Cryptographic Services) | Windows मॉड्यूल इंस्टॉलर (Windows Modules Installer) | Reasoned, unconfirmed |

## Locale conventions

These rules hold in every language:

- Name a control by its exact label in your catalog, quoted as your language quotes labels.
- `list-and` joins the last two items of a list, and `$a` may already hold several items joined with `list-separator`.
- Names inserted into a sentence (`screen-*-name`, switch, check and service names) go after a colon, or the sentence is built so they need no agreement.
- **Report a problem** (`home-report-problem`) opens the in-app **Send a report** page, so its label names no website.
- Your word for a step names only the steps of the install and ISO flows; a stage of updating, of creating an ISO or of writing a USB drive takes a different word.
- Where the English says "no installation changes were made", say that the installation changed nothing, not that nothing on the PC changed, because **Get ready** may already have installed updates.

Each locale's section starts with a one-row table of its main choices, then bullets with the rest of its conventions, then its open questions for native reviewers.
The relaunch column gives the verb for reopening Atlas, then the one for restarting the PC.
The switch names column gives the locale's collective term for the protection switches, or links to their Windows names where the locale has no such term.

### German (`de`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Sie, with "Ihr PC" | "als Administrator ausführen" with administrator rights, otherwise "Atlas erneut öffnen" (app), "neu starten" (PC) | „…“ around quoted button and step names | "Ihre Auswahl" | "Schutzschalter" |

- Buttons are infinitives, and buttons that Windows also uses keep their Windows names (Zurück, Weiter, Abbrechen, Fertig).
- A button that opens a step is "Zu „…“ wechseln" ("Zu „Vorbereiten“ wechseln").
- "Schritt" is only a flow step, and a stage of updating, of creating an ISO or of writing a USB drive is a "Phase".
- Windows' own installer is "Windows-Setup".
- A USB drive is always "USB-Laufwerk", never "USB-Stick".
- Key names follow German keyboards: Strg and Umschalt (Alt+Umschalt).
- Processor protections are "Prozessorschutz", never "Prozessorsicherheit".
- Security mitigations are "Mitigationen".
- Moving Windows to a newer version is "auf Version … umstellen".
- Updating on **Get ready** is "Aktualisieren" ("wird beim Aktualisieren erledigt").
- Atlas's record of an installation or update is its "Aufzeichnung".
- **Open log folder** is "Protokollordner öffnen", and **Stop updating** is "Updates anhalten".
- A switch Atlas couldn't read shows "Lesen fehlgeschlagen".
- Use "Diagnose-ZIP" in titles and "Diagnose-ZIP-Datei" in body text.
- "Antivirensoftware" is an app, and "Virenschutz" is the protection.
- Keep "Startmenü" (the Start menu) apart from "Boot-Menü" (the firmware menu).
- "No installation changes were made" is "die Installation hat nichts geändert".
- Lists of choices (`$choices`) go after a colon.
- Put a no-break space between a number and "%".

#### Open questions

- `protection-cloud`, `protection-samples`, `security-list-title`: does Windows show "Cloudbasierter Schutz" and "Automatische Übermittlung von Beispielen", or Microsoft's wording, "Über/In der Cloud bereitgestellter Schutz" and "Automatische Beispielübermittlung"?
  Check the page title, "Einstellungen für Viren- & Bedrohungsschutz", at the same time.
- `package-choice-defender-description`: do "Intelligente App-Steuerung" and "Erweiterter Phishingschutz" keep their capitals mid-sentence?
- `consequence-mitigations-disable`: what's the exact Control Flow Guard label on the Exploit-Schutz page?
- `package-choice-mitigations-description`: "Mitigationen", or Microsoft's "Entschärfungen" or "Risikominderungen"?
- `cost-defender-disable`: SmartScreen's own dialog says "unbekannte App", but the catalog says "nicht erkannte Apps"; which should it say?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match German Windows?
  Windows Modules Installer stays in English until someone checks it.

### Spanish (`es`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Implicit usted | "volver a abrir" (app), "reiniciar" (PC) | None around labels | "Sus preferencias" | "interruptores de protección" |

- Use international vocabulary: agregar, quitar, administrar, aplicación.
- Wrap questions in `¿…?`.
- Use "su PC" with a possessive, and "el equipo" where an adjective must agree.
- Never use "equipo" (the PC) and "equipo de Atlas" (the team) in one sentence.
- The user's choices are "preferencias", and "Configuración" is the app's Settings page and Windows settings.
- "paso" is only a flow step, and a stage of updating or of creating an ISO is an "etapa".
- A button that opens a step is "Ir a …" ("Ir a Preparación").
- Windows Setup is "el programa de instalación de Windows".
- A USB drive is a "unidad USB".
- Put "el interruptor" or "estos interruptores" before a switch name ("Estos interruptores…: X"), so adjectives agree whatever the name.
- **Open log folder** is "Abrir la carpeta de registros".
- **Stop updating**, "Detener actualizaciones", pairs with **Resume updates**, "Reanudar actualizaciones".
- Processor protections are "Protecciones del procesador".
- Running text calls Store apps "aplicaciones de la Store".
- The data is "diagnósticos", and the file is "ZIP de diagnóstico".
- Atlas's record of an installation is "los datos", never "registro", which is the log.
- Shift is "Mayús", and a Microsoft account is "cuenta de Microsoft".
- A switch Atlas couldn't read shows "No se pudo leer".
- "No installation changes were made" is "la instalación no hizo ningún cambio".
- "Unsupported" is "no cuenta con soporte", because "no es compatible" means incompatible.
- Titles say "No se pudo…".
- "Internet" is capitalised.
- Use "en cuanto…", not the Spain-only "nada más" + infinitive.

#### Open questions

- `protection-cloud`, `security-list-title`: is the cloud switch "basada en la nube" or "proporcionada desde la nube"?
  Check the page title at the same time.
- Whole catalog: usted or tú?
  Microsoft's consumer pages use tú.
- `package-choice-defender-description`: should Enhanced Phishing Protection add "(phishing)", as Microsoft's machine-translated Spanish page does?
- `iso-step-setup`: the ISO step "Configuración" is the same word as the app's Settings page; should the step use another word?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Spanish Windows?

### French (`fr`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| vous | "relancer" (app), "redémarrer" (PC) | « » with U+00A0 inside | "Vos choix" | "paramètres de protection" |

- Put U+00A0 before `: ; ? !` and `%`.
- Use the typographic apostrophe.
- Buttons are infinitives.
- Build is feminine, « la build », and so is an ISO.
- « étape » means only a flow step, and a stage of updating, of creating an ISO or of writing a USB drive is an « opération ».
- A button that opens a step is « Aller à … » (« Aller à Préparation »).
- « relancer » is only for the app; updates that run again « s’exécutent à nouveau », and the repair button is « Réessayer la réparation ».
- Windows Setup is the « programme d’installation de Windows ».
- A USB drive is a « clé USB » (« la clé » after that), and any other drive is a « lecteur ».
- « ce PC » is always the PC running Atlas; the one being reinstalled is « ce même PC » or « le PC à réinstaller ».
- Names of switches, checks and choices inserted into a sentence follow a colon (« Ces paramètres… : { $switches } »).
- Windows feature names in running text carry their article (« le Contrôle intelligent des applications »).
- The driver choices are « Via Windows Update » and « Installation manuelle ».
- Shift is « Maj ».
- **Open log folder** is « Ouvrir le dossier des journaux », and **Stop updating** is « Arrêter les mises à jour ».
- The data is « les diagnostics », and the file is « ZIP de diagnostic ».
- A switch Atlas couldn't read shows « Lecture impossible ».
- "No installation changes were made" is « l’installation n’a rien modifié ».
- Stage statuses are feminine, like the stepper's (« en cours », « non commencée »).

#### Open questions

- `protection-cloud`: "Protection dans le cloud" or "Protection fournie par le cloud"?
  Microsoft's pages use both.
- `security-list-title`: "et" or "&"?
- `package-choice-defender-description`: is Enhanced Phishing Protection « Protection renforcée contre l’hameçonnage », or the section's own title, « Protection contre l’hameçonnage »?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match French Windows?

### Brazilian Portuguese (`pt-BR`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Implicit você, with "seu PC" | "reabrir" (app), "reiniciar" (PC) | None around labels | "Suas escolhas" | "as quatro proteções" |

- "o Atlas" and "o Windows" take the article.
- Buttons are infinitives.
- The switch states (`security-switch-on`, `security-switch-off`) match Windows' invariant Ativado/Desativado.
- The switch names differ in gender, so sentences put them after a colon ("Esta proteção está desativada: …").
- "Etapa" is only a flow step, referred to as in "à etapa Preparação", and a stage of updating or of the installer is a "fase".
- A button that opens a step is "Ir para a etapa …" ("Ir para a etapa Preparação").
- Windows Setup, the program, is "a Instalação do Windows", with a capital I.
- A Windows build is a "compilação" in every string.
- A USB drive is a "unidade USB", and an Atlas ISO is "uma ISO com o Atlas".
- The catalog also serves pt-PT, so use neutral forms where they exist.
- A check that passes "é aprovada", not "passa".
- The update card on **Get ready** is "Atualizações do Windows e da Microsoft Store".
- Processor protections are "Proteções do processador".
- **Open log folder** is "Abrir pasta de logs", and **Stop updating** is "Parar atualizações".
- The data is "diagnósticos", and the file is "ZIP de diagnóstico".
- A test build is "versão de teste", and a release build is "versão oficial".
- Package builds are "versão completa do pacote" and "versão LocalTest".
- Stage states agree with "fase" ("em andamento", "não iniciada", "concluída").
- A switch Atlas couldn't read shows "Não foi possível ler".
- "No installation changes were made" is "a instalação não alterou nada".
- Plurals are `one` and `other`, and `one` covers 0.

#### Open questions

- `protection-tamper`, `protection-cloud`: is Tamper Protection "Proteção contra violações", "Proteção contra Violações" or a form with "adulterações", and is the cloud switch "fornecida pela nuvem" or "na nuvem"?
- `consequence-mitigations-disable`: is Exploit protection "Proteção contra vulnerabilidades" or "Proteção contra exploração"?
- `package-choice-defender-description`: is Enhanced Phishing Protection "aprimorada" or "avançada"?
  Microsoft's pages use both; this is low priority.
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Brazilian Windows?

### Polish (`pl`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Second person, with Twój and Ci capitalised | "otwórz Atlas ponownie" (app), "uruchom ponownie" (PC) | None around labels | "Opcje", because "wybory" also means elections | See [protection switch names](#protection-switch-names) |

- "Atlas" is declined (Atlasa, Atlasie, Atlasem), and so is "Zabezpieczenia Windows"; Windows and Defender aren't.
- Use all four plural categories on every count.
- "krok" is only a flow step, and update, ISO and USB stages are "etap".
- A button that opens a step is "Przejdź do kroku …" ("Przejdź do kroku Przygotowanie").
- Names inserted mid-sentence follow a colon, so they stay in the nominative ("Zmień: przeglądarka").
- A card on **Your choices** is "w sekcji …" ("w sekcji Przeglądarka"), never "karta", which reads as a tab.
- Radio options take "zaznacz", and buttons take "wybierz".
- Metered and unmetered are "taryfowe" and "nietaryfowe", not "bez ustawionego limitu", which is the separate data limit.
- Statuses shared by steps and stages are impersonal ("ukończono", "nie rozpoczęto").
- Never use the reader's gendered past tense: "wybrano", "Jeśli korzystasz już z Windows".
- Windows Setup is "Instalator Windows".
- A USB drive is a "dysk USB".
- **Your Atlas setup** is "Twoja konfiguracja Atlasa".
- **Open log folder** is "Otwórz folder dzienników", and **Stop updating** is "Zatrzymaj aktualizowanie".
- A switch Atlas couldn't read shows "Nie udało się odczytać", and a count of them uses "nieodczytany".
- "No installation changes were made" is "instalacja niczego nie zmieniła".
- Security mitigations are "środki zaradcze".
- AI is "sztuczna inteligencja".

#### Open questions

- `protection-cloud`: is the cloud switch "Ochrona dostarczana z chmury", or one of the forms Microsoft's pages use: "chmurowa", "w chmurze" or the English name?
- `consequence-mitigations-disable`: is Exploit protection "Ochrona przed lukami w zabezpieczeniach", or one of Microsoft's forms: "Ochrona przed exploitami", "ochrona przed programami wykorzystującymi luki" or the English name?
- `package-choice-defender-description`: is Enhanced Phishing Protection "Rozszerzona…", "Ulepszona…" or the switch's own label, "Ochrona przed wyłudzaniem informacji"?
  No Microsoft page uses "Rozszerzona…".
- `package-choice-defender-description`: is Smart App Control "Inteligentna kontrola aplikacji", or "Kontrola aplikacji inteligentnej" as one older Microsoft page has it?
- `package-choice-defender-description`, `check-fix-installed-apps`, `ready-updates-pending`: do Find my device ("Znajdź moje urządzenie"), Installed apps ("Zainstalowane aplikacje") and Notepad ("Notatnik") match Polish Windows?
  None of them has been checked.
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Polish Windows?

### Russian (`ru`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| вы (lower case) | "перезапустить" (app), "перезагрузить" (PC) | «…», with „…“ for a quote inside a quoted label | "Ваш выбор" | See [protection switch names](#protection-switch-names) |

- Buttons are infinitives.
- The user's choices are "настройки", and the app's Settings page is "параметры".
- Use all four plural categories; a regression test keeps 1/21/101 минуту in `windows-waited`.
- The switch states (`security-switch-on`, `security-switch-off`) are Вкл./Откл.
- Quote a control with its exact label (нажмите «Повторить попытку»).
- The four protection switch names are feminine, so words that agree with `$switches` are feminine.
- Names that follow a verb or preposition go after a colon, so they stay in the nominative («Изменить: { $title }»).
- A card on **Your choices** is «раздел «…»» («в разделе «Браузер»»).
- Flow steps are «шаг», and a stage of updating, of creating an ISO or of writing a USB drive is «этап».
- A button that opens a step is «Перейти к шагу «…»».
- Windows Setup is «программа установки Windows».
- A USB drive is «USB-накопитель», as File Explorer names an unlabelled one.
- Windows versions are «Windows 11, версия …» in titles and «Windows 11 версии …» in running text.
- An edition is «редакция», and a release is «выпуск».
- Repairing Microsoft Store is «исправить», and repairing Windows is «восстановление».
- «этот ПК» is only the PC running Atlas; the one being reinstalled is «тот ПК».
- Always «ПК», never «компьютер».
- First-person rows avoid the gendered past tense («Я подтверждаю…», «Когда я…»).
- "Microsoft account" is «учётная запись Майкрософт».
- SmartScreen stays in Latin letters.
- **Open log folder** is «Открыть папку журналов», and **Stop updating** is «Остановить обновление».
- A switch Atlas couldn't read shows «Не удалось прочитать».
- "No installation changes were made" is «установка ничего не изменила», and "Installation hasn't changed anything yet" is «Установка пока ничего не изменила».

#### Open questions

- `protection-tamper`: is Tamper Protection "Защита от подделки", as quoted from the interface, or "Защита от незаконного изменения", as Microsoft's documentation says?
- `security-list-title`: does the page heading include "и других угроз"?
- `security-switch-off`: is the off state "Откл."?
- `consequence-mitigations-disable`, `package-choice-defender-description`: do Exploit protection, Control Flow Guard and Smart App Control match Russian Windows, and is Enhanced Phishing Protection «Расширенная» or «Улучшенная»?
  None of the four has been checked.
- `iso-edition`, `iso-review-edition`: the catalog calls an edition «редакция», but the About page in Russian Windows labels it «Выпуск»; which should the catalog use?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Russian Windows?

### Turkish (`tr`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| siz | "yeniden aç" (app), "yeniden başlat" (PC) | None around labels | "Seçimleriniz" | See [protection switch names](#protection-switch-names) |

- Apostrophes are straight (') everywhere, and suffixes on proper nouns follow one (Atlas'ı, Windows'u).
- Never put a suffix on a variable; a noun follows it instead: "{ $version } sürümünü".
- Name a control by its label, then an apostrophe, its suffix and "seçin" ("Yeniden dene'yi seçin", "Atlas'ı kur'u seçin").
- A radio option takes "… seçeneğini belirleyin".
- "adım" is only a flow step, and a stage of updating or of creating an ISO is an "aşama".
- A button that opens a step is "… adımına git" ("Hazırlık adımına git").
- "kur" installs Atlas; "yükle" installs updates, apps, drivers and Windows.
- Windows Setup is "Windows Kurulumu".
- A USB drive is a "USB sürücüsü".
- "Update" is "güncelleştirme" and "to update" is "güncelleştir", as in Microsoft Turkish.
- Use "denetle", not "kontrol et".
- "Try again" is "yeniden deneyin"; use "tekrar" only where "yeniden başlat" already stands beside it.
- "Keep" is "tut" ("Microsoft Defender'ı tut").
- Build is "derleme", a tester build is "test sürümü", and diagnostics are "tanılama verileri".
- The licence terms are "Microsoft Yazılım Lisans Koşulları".
- A switch Atlas couldn't read shows "Okunamadı".
- "No installation changes were made" is "Kurulum hiçbir değişiklik yapmadı", never "Bilgisayarınızda…".
- Mitigations are "güvenlik risk azaltmaları".
- In privacy text, "kept" is "kaldırılmaz".
- **Open log folder** is "Günlük klasörünü aç", and **Stop updating** is "Güncelleştirmeyi durdur".

#### Open questions

- `protection-tamper`: "Kurcalama Koruması", "Kurcalama koruması" or "Değişiklik Koruması"?
- `security-list-title`: "ve" or "&"?
- Fast Startup (`consequence-disable-hibernation`): "Hızlı Başlatma" or "Hızlı başlatma"?
- `consequence-mitigations-disable`: does Control Flow Guard end in "koruması" or "koruyucusu"?
- `package-choice-defender-description`: how is "Gelişmiş Kimlik Avı Koruması" capitalised?
- `detail-power-mains`, `detail-power-check-failed`: the catalog says "fişe takılı", but Windows says "Prize takılı"; which should it use?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Turkish Windows?

### Simplified Chinese (`zh-Hans`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| 你, as in Windows 11 zh-CN, and 电脑 for the PC | 重新打开 (app), 重启 (PC) | “…” | "你的选择" | 关闭 and 重新开启 |

- Punctuation is full-width.
- Put a space between Chinese and Latin letters or digits.
- Latin-only asides take half-width brackets.
- `list-and` joins with 和, without spaces.
- Where a name may be Latin text (switch names, lists of choices), put it after a colon to avoid the spacing problem.
- 步骤 (第 n 步) is only a flow step, and a stage of updating or of creating an ISO is a 阶段.
- Stage names (`iso-stage-*`, `usb-stage-*`) are verb phrases without 正在, and `iso-progress-stage` adds 正在….
- A button that opens a step is 转到“…”, and one that returns to a step is 返回“…”.
- Removing Defender is 移除, because it's permanent.
- 安装文件 means prepared files, never the .atlaspkg file.
- Processor protections are 处理器防护, not 处理器安全.
- Review is 检查 (检查 ZIP).
- A USB drive is U 盘 in titles and buttons (创建 U 盘), and USB 驱动器 in the drive list and body text.
- Erasing is 清空 in titles and buttons, and 永久删除 in body text.
- Edge bookmarks are 收藏夹.
- Windows Setup, the program, is Windows 安装程序.
- The Show and Hide links on a folded card are 展开 and 收起.
- **Your Atlas setup** is Atlas 安装详情.
- "Bundled" is 内置, and a test build is 测试版.
- Microsoft is never 微软.
- A "Couldn't…" title is 无法…, and a failure that has already happened is 未能…, as in the status of a switch Atlas couldn't read, 未能读取.
- "No installation changes were made" is 未进行任何安装更改, and "may have been made" is 可能已经应用.
- **Open log folder** is 打开日志文件夹, and **Stop updating** is 停止更新.

#### Open questions

- `security-list-title`: should the page title keep its quotation marks, as in “病毒和威胁防护”设置?
- `protection-samples`: 样本 or 示例?
- `protection-cloud`: 云提供的保护 or 云保护?
- `consequence-mitigations-disable`: does Chinese Windows show "Exploit Protection" in English, and is Control Flow Guard 控制流保护 (CFG)?
- `package-choice-defender-description`: Enhanced Phishing Protection is 增强型网络钓鱼防护, but the Windows Security switch reads 网络钓鱼防护; which should the text use?
- Whole catalog: 账户 or 帐户?
  The catalog uses 账户; check which one Simplified Chinese Windows shows.
- `service-*`, `check-fix-storage`, `prepare-open-services`: does Simplified Chinese Windows list the services in English, as the catalog assumes, and do the other [Storage settings and services](#storage-settings-and-services) names match?

### Traditional Chinese (`zh-Hant`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| 您 | 重新開啟 Atlas (app), 重新啟動 (PC) | 「」 around controls named in text | "您的選擇" | See [protection switch names](#protection-switch-names) |

- Use the Taiwan glossary: 設定, 系統管理員, 檔案, 資料夾, 網路, 組建, 佈景主題.
- Punctuation is full-width.
- Brackets are full-width even around Latin-only text: （.atlaspkg）, （UAC）.
- `list-and` joins with 和, without spaces.
- 重新開啟 also turns a protection back on, and 重新啟動 is only restarting the PC or Windows.
- 步驟 (第 n 步) is only a flow step, and a stage of updating or of creating an ISO is a 階段.
- A button that opens a step is 前往「…」.
- Windows Setup, the installer, is Windows 安裝程式.
- A USB drive is USB 磁碟機 everywhere (磁碟機 once it's clear), never 隨身碟.
- "Windows 11, version …" is "Windows 11 版本 …".
- Edition names such as Home and Pro stay in English.
- Processor protections are 處理器防護, not 處理器安全性.
- Security mitigations are 安全性緩和措施.
- Erasing is 清除 throughout.
- Edge's 「我的最愛」 is always quoted.
- Store apps are 市集應用程式.
- Atlas's install record is its 安裝狀態檔案, and 安裝記錄 is the install log.
- A switch Atlas couldn't read shows 無法讀取, and 檢查 is checking.
- "No installation changes were made" is 未進行任何安裝變更, and "may have been made" is 可能已進行部分變更.
- Privacy is 隱私權.
- Controls named in text include **Open log folder** (開啟記錄資料夾), **Stop updating** (停止更新), **Report a problem** (回報問題), **Send a report** (傳送報告) and **Help** (說明).

#### Open questions

- `protection-samples`: 自動提交範例, 提交自動樣本 or 自動提交樣本?
- `protection-tamper`: older Windows 10 builds use 防竄改保護 rather than 竄改防護; which should the text use?
- `consequence-mitigations-disable`, `package-choice-defender-description`, `iso-network-inbox`: do 惡意探索保護, 控制流程防護, 智慧型應用程式控制, 增強式網路釣魚保護, 尋找我的裝置 and 網路介面卡 match Taiwanese Windows?
  The Enhanced Phishing Protection switch itself reads 網路釣魚保護.
- `detail-windows-release-not-listed`: should the Release Preview channel stay in Latin letters, or become 版本預覽通道, 發行預覽 or 版本預覽?
  Taiwanese Windows shows 版本預覽通道 in screenshots, while Microsoft's pages mix 發行預覽, 版本預覽 and Release Preview.
- `list-and`: 和 has no spaces around it, so a Latin item sits against it with no space; should the message add a space around Latin text?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Taiwanese Windows?
  Windows Modules Installer stays in English until someone checks it.

### Japanese (`ja`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| です・ます | 再実行 when Atlas relaunches itself, 開き直す when you reopen it (app), 再起動 (PC) | 「」 | "設定の選択" | See [protection switch names](#protection-switch-names) |

- Buttons end in a noun (完了, 今すぐ再起動).
- Put a half-width space between Japanese and Latin text, and inside katakana compounds.
- Use 。 and 、 with half-width ( ) and ": ", as Microsoft's Japanese UI does.
- `list-and` joins with 、, without spaces.
- The counter is 項目 for checks, 件 for updates and 個 for switches and extras.
- 手順 is only a flow step, and a stage of updating is a 段階.
- Status lines for work in progress end in 〜しています….
  Checklist and ISO stage names are plain nouns (ファイルのコピー), because the checklist shows them done, current or pending; the progress label `iso-progress-stage` adds 中… after them.
- A button that opens a step is 「…」に移動 (「準備」に移動), and **Return to Install** is 「インストール」に戻る.
- Windows Setup is Windows セットアップ, and a USB drive is a USB ドライブ.
- A check that updating takes care of is 更新時に対処 as a status, and 更新時に対処されます in its description.
- The Windows regional format is 地域のフォーマット, and personalisation is 個人用設定, as Settings names them.
- "Antivirus app" is ウイルス対策アプリ; use ソフト only where the English says "software".
- Edge bookmarks are お気に入り.
- Status words are 進行中, 失敗, 未開始 and 完了, and a switch Atlas couldn't read shows 読み取り不可.
- "No installation changes were made" is インストールによる変更はありません.
- **Open log folder** is ログ フォルダーを開く, and **Stop updating** is 更新を停止.

#### Open questions

- `protection-cloud`, `protection-samples`, `security-list-title`: do クラウド提供の保護, サンプルの自動送信 and ウイルスと脅威の防止の設定 match Japanese Windows?
  Microsoft's machine-translated Japanese support page words them differently.
- `package-choice-defender-description`: is Enhanced Phishing Protection 拡張フィッシング保護 or 強化されたフィッシング保護, as different Microsoft pages call it, or フィッシング対策, as the switch reads?
  拡張フィッシング保護 is the title of Microsoft's Japanese documentation page.
- `detail-windows-release-not-listed`: should the Release Preview channel stay in Latin letters, or does Japanese Windows show リリース プレビュー in Settings, as Microsoft's machine-translated Japanese Insider pages suggest?
- `service-*`, `check-fix-storage`, `prepare-open-services`: does Japanese Windows list the services in English, as the catalog assumes, and do the other [Storage settings and services](#storage-settings-and-services) names match?

### Indonesian (`id`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| Anda, formal-neutral | "jalankan ulang" (app), "mulai ulang" (PC), "buka kembali" after a restart | None around labels | "Pilihan Anda" | "pengaturan (perlindungan)" |

- Plurals use only `other`.
- "penginstalan" is the Atlas install, and "instalasi Windows" is a Windows installation.
- "langkah" is only a flow step, and a stage of updating or of creating an ISO is a "tahap".
- A button that opens a step is "Buka langkah …" ("Buka langkah Persiapan"), so it differs from "Buka Keamanan Windows", which opens the app.
- Windows Setup is "Penyiapan Windows".
- A USB drive is a "drive USB", and erasing it is "Hapus isi".
- Moving Windows to a newer version is "meningkatkan … ke versi …".
- The protection switches are turned off with "nonaktifkan" and back on with "aktifkan kembali".
- Licence terms are "ketentuan lisensi".
- Task Manager is "Pengelola Tugas".
- A switch Atlas couldn't read shows "Tidak dapat dibaca".
- "No installation changes were made" is "Penginstalan belum mengubah apa pun", never a claim about the whole PC.
- Use "Hubungkan", not "Sambungkan".
- Use "file", not "berkas".
- Use "Setelah itu," rather than a sentence starting with "Lalu".
- **Open package file** is "Buka file paket", **Open log folder** is "Buka folder log", **Stop updating** is "Hentikan pembaruan" and **Help** is "Bantuan".
- "needs attention" is "perlu diperhatikan".

#### Open questions

- `protection-tamper`, `protection-cloud`, `security-list-title`: does Indonesian Windows show "Proteksi Kerusakan", "Perlindungan yang dikirimkan cloud" and "Pengaturan perlindungan virus & ancaman"?
  Microsoft's machine-translated pages disagree with each other and give eight renderings of Tamper Protection between them.
- Fast Startup (`consequence-disable-hibernation`): the catalog says "startup cepat (Fast Startup)"; what does Indonesian Windows call it?
- `consequence-mitigations-disable`, `package-choice-defender-description`, `check-fix-installed-apps`: do Perlindungan eksploitasi, Perlindungan pengelabuan, Temukan perangkat saya and Aplikasi yang diinstal match Indonesian Windows?
  Kontrol Aplikasi Pintar matches Microsoft's Indonesian Smart App Control FAQ.
- `consequence-mitigations-disable`, `ready-updates-pending`: Control Flow Guard and Notepad stay in English until confirmed; what does Indonesian Windows call them?
- `list-and`: should lists of three or more read "A, B, dan C", as PUEBI and CLDR want, rather than "A, B dan C"?
  That needs a separate message for the last of three or more.
- `service-*`, `check-fix-storage`, `prepare-open-services`: Indonesian Windows may show the service names in English; do the [Storage settings and services](#storage-settings-and-services) names match?

### Thai (`th`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| คุณ | เปิด Atlas ใหม่, or เปิด Atlas อีกครั้ง after it was closed (app), รีสตาร์ต (PC) | None; a control named in text has a space either side | "ตัวเลือกของคุณ" | See [protection switch names](#protection-switch-names) |

- Sentences have no final full stop.
- Put a space between clauses and around Latin letters or digits.
- Use classifiers instead of plurals.
- Call Windows Security "แอป ความปลอดภัยของ Windows" where the app is opened, and Services "แอป บริการ".
- A button that opens a step is "ไปที่ …" ("ไปที่ เตรียมความพร้อม").
- ขั้นตอน is only a flow step, and a stage of updating, of installing, of creating an ISO or of writing a USB drive is ช่วง (ช่วงปัจจุบัน, ช่วงสุดท้าย).
- ช่วงนี้ on its own reads as "these days", so `prepare-percent` puts it after the number (…% ของช่วงนี้), and the repair details name the work instead (การซ่อมแซมนี้).
- The ISO step ตั้งค่า has no การ, so it isn't read as the app's Settings page (การตั้งค่า).
- Windows Setup is โปรแกรมติดตั้ง Windows, and Atlas's installer is ตัวติดตั้ง.
- A retried installation is การติดตั้งรอบนี้, and the earlier one is รอบก่อน.
- A USB drive is a ไดรฟ์ USB; erasing it is ลบข้อมูล, and ejecting it is นำออก.
- Stage checklists use bare verbs, and กำลัง appears only in the progress label.
- "X anyway" is "X ต่อไป" (ติดตั้งต่อไป).
- Sign in is ลงชื่อเข้าใช้, as Microsoft's Thai pages write it.
- Task Manager is ตัวจัดการงาน, the Downloads folder is ดาวน์โหลด, and the Start menu is เมนูเริ่ม.
- Diagnostics are ข้อมูลการวินิจฉัย.
- Characters are อักขระ.
- Review is ตรวจทาน; ตรวจสอบ is checking and verifying.
- Restart is only รีสตาร์ต, never รีสตาร์ท or เริ่มระบบใหม่.
- Build is บิลด์; รุ่น is an edition or release, and a tester build is รุ่นทดสอบ.
- Beta is เบต้า and Ethernet is อีเทอร์เน็ต; Wi-Fi stays Latin.
- Don't use โปรด.
- Question titles have no "?".
- A switch Atlas couldn't read shows อ่านไม่ได้.
- "No installation changes were made" is การติดตั้งจึงไม่ได้เปลี่ยนแปลงสิ่งใด.

#### Open questions

- `protection-tamper`, `protection-cloud`, `security-list-title`: do การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย and การป้องกันบนระบบคลาวด์ match Thai Windows, and does the page title use "และ" or "&"?
- Memory integrity (`consequence-disable-core-isolation`): ความสมบูรณ์ or ความถูกต้อง ของหน่วยความจำ?
- Fast Startup (`consequence-disable-hibernation`): the catalog says การเริ่มต้นอย่างรวดเร็ว; does Thai Windows call it การเริ่มต้นใช้งานด่วน?
- `package-choice-defender-description`: only ฟิชชิ่ง in การป้องกันฟิชชิ่งขั้นสูง is confirmed; does Thai Windows word the rest of the name the same way?
- `ready-updates-pending`, `check-fix-installed-apps`: does Notepad show in Thai, and is Installed apps แอปที่ติดตั้ง?
- `service-*`, `check-fix-storage`, `prepare-open-services`: Thai Windows may show the Services list and its Manual startup type (ด้วยตนเอง) in English; do the [Storage settings and services](#storage-settings-and-services) names match?

### Hindi (`hi`)

| Register | App relaunch vs PC restart | Quotes | Step 2 | Switch names |
| --- | --- | --- | --- | --- |
| आप, with respectful imperatives | "दोबारा खोलें" (app), "रीस्टार्ट करें" (PC) | “ ” around labels and step names, except the step तैयारी | "आपके विकल्प" | See [protection switch names](#protection-switch-names) |

- The danda is the only sentence terminator.
- Loanwords follow Microsoft's style in Devanagari (इंस्टॉल, अपडेट, सेटिंग्स, फ़ाइल), with the nukta applied consistently.
- The decision caption is "पसंद".
- The selections made on **Your choices** are "विकल्प" everywhere, never सेटिंग or सेटिंग्स, which name the app's Settings page and Windows settings.
- चरण is only a flow step ("चरण 2"), and a stage of updating or of creating an ISO is a पड़ाव (masculine: "मौजूदा पड़ाव").
- A button that opens a step is "… पर जाएँ" (“आपके विकल्प” पर जाएँ).
- Checklist stages that show done and pending states use verbal nouns (फ़ॉर्मैट करना), not the progressive, and status lines for work under way end with "…".
- Windows Setup is "Windows सेटअप".
- The Atlas package, ISO and USB are masculine (नया ISO); USB ड्राइव and ISO फ़ाइल are feminine.
- A USB drive is a "USB ड्राइव" in titles and running text.
- Diagnostics are डायग्नोस्टिक्स (masculine plural), never निदान.
- "PC" stays Latin, never पीसी.
- Use इंस्टॉलेशन, not स्थापना.
- Use रीस्टार्ट, not पुनः आरंभ.
- **Try again** is "फिर कोशिश करें".
- Use अगर, not यदि.
- First-person text stays gender-neutral (मेरी कोशिश थी कि…, "X ख़ुद इंस्टॉल करें").
- Windows names that Hindi Windows may show in English keep the English in brackets until confirmed, as in "मेमोरी अखंडता (Memory integrity)" and the service names.
- A switch Atlas couldn't read shows "पढ़ा नहीं जा सका".
- "No installation changes were made" is "इंस्टॉलेशन से कोई बदलाव नहीं हुआ".

#### Open questions

- `protection-tamper`, `protection-realtime`, `protection-cloud`, `protection-samples`, `security-list-title`: do these five names match Hindi Windows?
  Hindi Windows coverage is partial, so a Hindi PC may show some switches in English.
- Windows Update, the Start menu and Snipping Tool: does Hindi Windows say Windows Update or Windows अपडेट, and does it call the others स्टार्ट मेनू and Snipping Tool?
- `consequence-mitigations-disable`, `package-choice-defender-description`: does Hindi Windows use the feature names in the table?
  All of them are reasoned, and शोषण usually means the exploitation of people.
- `prepare-close-app`, `ready-updates-pending`, `usb-iso-missing`, `check-fix-installed-apps`: do कार्य प्रबंधक, नोटपैड, डाउनलोड फ़ोल्डर and इंस्टॉल किए गए ऐप्स match Hindi Windows?
  All of them are reasoned.
- `consequence-disable-core-isolation`, `consequence-disable-hibernation`, `service-cryptsvc`, `service-trusted-installer`: "मेमोरी अखंडता (Memory integrity)", "तेज़ स्टार्टअप (Fast Startup)" and two of the service names keep English in brackets until confirmed; can they drop it?
- `service-*`, `check-fix-storage`, `prepare-open-services`: do the [Storage settings and services](#storage-settings-and-services) names match Hindi Windows?
- Whole catalog: संस्करण means both edition and version; should edition take its own word?
- Whole catalog: the nukta is applied to क़ only in मुताबिक़; which rule should the catalog follow?
