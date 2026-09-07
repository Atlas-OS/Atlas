# Translation guidance

Use these conventions when editing the Fluent catalogs. All non-English translations
remain previews and need native-speaker review. The Windows labels below are working
choices; check the open terminology questions against a localized Windows installation
before marking a catalog reviewed. See [language implementation](i18n.md) for
catalog checks and [writing guidance](writing.md) for shared copy conventions.

## Locale conventions

- **de** — Sie; "Ihr PC"; buttons infinitive, Windows names kept
  (Zurück, Weiter, Abbrechen, Fertig); app relaunch "als Administrator
  ausführen", PC "neu starten"; „…“ quotes for quoted button and step
  names; step 2 "Ihre Auswahl". Windows names: Manipulationsschutz,
  Echtzeitschutz, Cloudbasierter Schutz, Automatische Übermittlung von
  Beispielen; "Einstellungen für Viren- & Bedrohungsschutz". Sources:
  support.microsoft.com de-de Windows Security page; learn.microsoft.com
  de-de tamper/cloud pages (machine-translated, weighed accordingly); seven
  human-written German how-tos quoting the four toggles.
- **es** — implicit usted, "su PC"/"el equipo"; international vocabulary
  (agregar, quitar, administrar, aplicación); "volver a abrir" for the app,
  "reiniciar" for the PC; ¿…? questions; step 2 "Sus preferencias". Windows
  names: Protección contra alteraciones, Protección en tiempo real,
  Protección basada en la nube, Envío automático de muestras;
  "Configuración de antivirus y protección contra amenazas". Sources: the
  es-ES/es-MX support page (uses "proporcionada desde la nube"), learn
  es-es walkthrough and a third-party UI guide (both "basada en la nube").
- **fr** — vous; U+00A0 before `: ; ? !` and inside « »; typographic
  apostrophe; infinitive buttons; "relancer" = app, "redémarrer" = PC;
  the switches are "paramètres de protection"; step 2 "Vos choix"; "la
  build". Windows names: Protection contre les falsifications, Protection
  en temps réel, Protection dans le cloud, Envoi automatique d’un
  échantillon; "Paramètres de protection contre les virus et menaces".
  Sources: fr-fr support pages (Windows Security overview and malware
  troubleshooting, which disagree on the cloud label), learn fr-fr tamper
  pages (MT), French UI guides.
- **pt-BR** — você (implicit), "o Atlas"/"o Windows" with article, "seu
  PC"; infinitive buttons; "reabrir" = app, "reiniciar" = PC; the switches
  are "as quatro proteções"; state words match Windows' invariant
  Ativado/Desativado; "à etapa Preparação"; step 2 "Suas escolhas"; also
  serves pt-PT, so neutral forms where they exist. Windows names: Proteção
  contra violações, Proteção em tempo real, Proteção fornecida pela nuvem,
  Envio automático de amostra; "Configurações de proteção contra vírus e
  ameaças". Sources: pt-br support page (human-localized, differs on two
  switches), learn pt-br (MT), Brazilian press describing the live UI.
- **pl** — second person (Twój/Ci capitalised); "Atlas" declined (Atlasa,
  Atlasie, Atlasem), "Zabezpieczenia Windows" declined, Windows and Defender
  not; "otwórz Atlas ponownie" = app, "uruchom ponownie" = PC; all four
  plural categories on every count; step 2 "Opcje" ("wybory" also means
  elections). Windows names: Ochrona przed naruszeniami, Ochrona w czasie
  rzeczywistym, Ochrona dostarczana z chmury, Automatyczne przesyłanie
  próbek; "Ustawienia ochrony przed wirusami i zagrożeniami". Sources: pl-pl
  support pages, learn pl-pl (MT, inconsistent on cloud), Polish tech sites
  quoting the UI.
- **ru** — вы (lower case); "ПК"; imperative buttons; «…» guillemets;
  "перезапустить" = app, "перезагрузить" = PC; the user's choices are
  "настройки", the app's Settings page "параметры"; all four plural
  categories (regression test keeps 1/21/101 минута). Windows names: Защита
  от подделки, Защита в режиме реального времени, Облачная защита,
  Автоматическая отправка образцов; "Параметры защиты от вирусов и других
  угроз"; toggle states Вкл./Откл. Sources: ru-ru support and learn pages.
- **tr** — siz; suffixes on proper nouns with an apostrophe (Atlas'ı,
  Windows'u); never a suffix on a variable (a noun follows it instead:
  "{ $version } sürümünü"); "yeniden aç" = app, "yeniden başlat" = PC; step
  2 "Seçimleriniz". Windows names: Kurcalama Koruması, Gerçek zamanlı
  koruma, Bulut tabanlı koruma, Otomatik örnek gönderimi; "Virüs ve tehdit
  koruması ayarları". Sources: tr-tr support page (human-localized), learn
  tr-tr (MT), a Microsoft Q&A answer using "Değişiklik Koruması".
- **zh-Hans** — 你 (as Windows 11 zh-CN), 电脑; full-width punctuation with
  a space between Chinese and Latin/digits, half-width brackets for
  Latin-only asides; 重新打开 = app, 重启 = PC; Defender 移除 (permanent)
  vs 暂停/暂时关闭 (temporary); step 2 "你的选择". Windows names: 篡改防护,
  实时保护, 云提供的保护, 自动提交样本; “病毒和威胁防护”设置. Sources:
  zh-cn support and learn pages.
- **zh-Hant** — 您; Taiwan glossary (設定, 系統管理員, 檔案, 資料夾, 網路,
  組建, 佈景主題); full-width punctuation; 重新開啟 Atlas = app, 重新啟動 =
  PC; step 2 "您的選擇". Windows names: 竄改防護, 即時保護, 雲端提供的保護,
  自動提交範例; 病毒與威脅防護設定. Sources: zh-tw support page (MT,
  inconsistent), learn zh-tw human-translated cloud page, 2021 and 2026
  Taiwanese guides with screenshots.
- **ja** — です・ます; noun-stop buttons (完了, 今すぐ再起動); half-width
  space between Japanese and Latin and inside katakana compounds; 。、 with
  half-width ( ) and ": " as Microsoft Japanese UI does; 管理者として再実行
  = app, 再起動 = PC; step 2 "設定の選択"; Playbook stays Latin. Windows
  names: 改ざん防止, リアルタイム保護, クラウド提供の保護, サンプルの自動送信;
  ウイルスと脅威の防止の設定. Sources: an OEM (dynabook) Windows 11 support
  page and a 2026 Japanese article describing the live UI; the ja-jp
  support page is machine-translated and disagrees.
- **id** — Anda; formal-neutral register; "jalankan ulang" = app, "mulai
  ulang" = PC, "buka kembali" after a restart; the switches are
  "pengaturan (perlindungan)"; only `other` plurals; step 2 "Pilihan Anda".
  Windows names: Proteksi Kerusakan, Perlindungan real-time, Perlindungan
  yang dikirimkan cloud, Pengiriman sampel otomatis; "Pengaturan
  perlindungan virus & ancaman". Sources: id-id support and learn pages,
  all machine-translated and mutually inconsistent; a community tutorial
  title for the tamper label.
- **th** — คุณ; no sentence-final full stops, a space between clauses and
  around Latin/digits; classifiers instead of plurals; รีสตาร์ต = PC, เปิด
  Atlas ใหม่ = app; "แอป ความปลอดภัยของ Windows" when the app is opened;
  step 2 "ตัวเลือกของคุณ". Windows names: การป้องกันการแก้ไขข้อมูลโดยประสงค์ร้าย,
  การป้องกันแบบเรียลไทม์, การป้องกันบนระบบคลาวด์, การส่งตัวอย่างโดยอัตโนมัติ;
  การตั้งค่าการป้องกันไวรัสและภัยคุกคาม. Sources: th-th support pages
  (Windows Security, turn off Defender, device security, Windows Update,
  activation, power, Snipping Tool); learn th-th pages served English.
- **hi** — आप with respectful imperatives; danda as the only sentence
  terminator; Microsoft-style loanwords in Devanagari (इंस्टॉल, अपडेट,
  सेटिंग्स, फ़ाइल) with nukta applied consistently; "दोबारा खोलें" = app,
  "रीस्टार्ट करें" = PC; step 2 "आपके विकल्प", the decision caption "पसंद".
  Windows names: छेड़छाड़ से सुरक्षा, रीयल-टाइम सुरक्षा, क्लाउड-आधारित सुरक्षा,
  स्वचालित नमूना सबमिशन; वायरस और ख़तरे से सुरक्षा सेटिंग्स. Sources: none in
  Hindi; every Microsoft hi-in page fetched was served in English and the
  review PC has no Hindi language pack, so these five names are reasoned,
  not confirmed.

## Questions for native reviewers

Terminology that could not be settled without a localized Windows 11 build
in front of a reviewer (Microsoft's own localized pages are machine
translated for several languages and disagree with each other):

| Locale | Keys | Reason |
|---|---|---|
| de | protection-cloud, protection-samples, security-list-title | Human-written sources say "Cloudbasierter Schutz"; Microsoft prose says "Über/In der Cloud bereitgestellter Schutz" and "Automatische Beispielübermittlung". |
| es | protection-cloud, security-list-title | Support page says "proporcionada desde la nube"; learn walkthrough and UI guides say "basada en la nube". Usted vs tú: Microsoft consumer pages use tú. |
| fr | protection-cloud, security-list-title | "Protection dans le cloud" (troubleshooting page, UI guides) vs "Protection fournie par le cloud" (overview page); "et" vs "&". |
| pt-BR | protection-tamper casing, protection-cloud | Press quotes "Proteção contra Violações" capitalised; support page says "adulterações" and "na nuvem". |
| pl | protection-cloud | Microsoft pages disagree (chmurowa / w chmurze / untranslated); "dostarczana z chmury" rests on third-party quotations. |
| ru | protection-tamper, security-list-title, security-switch-off | "Защита от подделки" (UI quotations) vs "Защита от незаконного изменения" (docs); page heading with "и других угроз"; "Откл." toggle word. |
| tr | protection-tamper casing, security-list-title, Fast Startup | "Kurcalama koruması/Koruması" vs a moderator's "Değişiklik Koruması"; "ve" vs "&"; "Hızlı Başlatma/başlatma". |
| zh-Hans | security-list-title, protection-samples, protection-cloud | Quotation marks in the page title; 样本 vs 示例; 云提供的保护 vs 云保护. |
| zh-Hant | protection-samples, protection-tamper (Windows 10) | 自動提交範例 / 提交自動樣本 / 自動提交樣本; older builds wrote 防竄改保護. |
| ja | protection-cloud, protection-samples, security-list-title | Live-UI sources vs the machine-translated ja-jp support page; also 再実行 vs 開き直す for relaunch, and Playbook vs プレイブック. |
| id | protection-tamper, protection-cloud, security-list-title, Fast Startup | All Microsoft id-ID pages are MT and give eight renderings of Tamper Protection between them. |
| th | protection-tamper, protection-cloud, security-list-title, memory integrity, Fast Startup | Only MT support pages available; "และ" vs "&"; ความสมบูรณ์ vs ความถูกต้อง ของหน่วยความจำ. |
| hi | all four protection-*, security-list-title, Windows Update vs Windows अपडेट, Start button name, Snipping Tool | No Hindi Microsoft text could be fetched and Hindi Windows coverage is partial; a Hindi PC may show some switches in English. |
