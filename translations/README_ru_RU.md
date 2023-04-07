
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">Открытая и прозрачная операционная система Windows, разработанная для оптимизации производительности и задержки.</h4>

<p align="center">
  <a href="https://atlasos.net">Веб-сайт</a>
  •
  <a href="https://docs.atlasos.net/FAQ/Installation/">FAQ</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Форум</a>
</p>

## 🤔 **Что такое Atlas?**

Atlas - это модифицированная версия Windows 10, в которой устранены все негативные особенности Windows, отрицательно влияющие на игровую производительность. Мы являемся прозрачным проектом с открытым исходным кодом, стремящимся к равным правам для игроков, независимо от того, используете ли вы ПК низкого класса или игровой ПК.

Уделяя основное внимание производительности, мы также являемся отличным вариантом для снижения системных задержек, сетевых задержек, задержек ввода и сохранения конфиденциальности вашей системы.

Вы можете узнать больше об Atlas на нашем официальном [сайте](https://atlasos.net).

## 📚 **Содержание**
- FAQ
  - [Установка](https://docs.atlasos.net/FAQ/Installation/)
  - [Внести вклад](https://docs.atlasos.net/FAQ/Contribute/)

- Первые шаги
  - [Установка](https://docs.atlasos.net/Getting%20started/Installation/)
  - [Другие методы установки](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [После установки](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- Устранение неполадок
  - [Удалённые функции](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [Скрипты](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Брендовый кит](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

## 🆚 **Windows vs. Atlas**

### 🔒 Конфиденциальность
Atlas удаляет все типы отслеживания, встроенные в Windows, и реализует многочисленные групповые политики для минимизации сбора данных. Мы не можем повысить конфиденциальность данных, которые находятся за пределами Windows, например, посещаемых вами веб-сайтов.

### 🛡️ Безопасность
Atlas стремится быть максимально безопасным без потери производительности. Мы добиваемся этого путем отключения функций, которые могут привести к утечке информации или быть использованы. Существуют исключения, такие как [Spectre](https://spectreattack.com/spectre.pdf) и [Meltdown](https://meltdownattack.com/meltdown.pdf). Эти средства защиты отключаются для повышения производительности.

Если меры по снижению безопасности снижают производительность, они будут отключены.
Ниже приведены некоторые функции/минимумы, которые были изменены, если они содержат символ (P), то это риски безопасности, которые были исправлены:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Возможный поиск информации*)

### 🚀 Удалено
Atlas сильно очищен, удалены предустановленные приложения и другие компоненты. Несмотря на возможность возникновения проблем с совместимостью, это значительно уменьшает размер ISO и размер установки. Функциональные возможности, такие как Windows Defender и подобные, полностью удалены.

Эта модификация ориентирована на безупречный гейминг, но также работают большинство рабочих и образовательных приложений. Узнайте, что еще мы удалили в нашем [FAQ](https://docs.atlasos.net/Troubleshooting/Removed%20features/).

### ✅ Производительность
Atlas предварительно настроен. Сохраняя совместимость, но также стремясь к производительности, мы вложили в наши образы Windows все до последней капли.

Ниже перечислены некоторые из многочисленных изменений, которые мы сделали для улучшения Windows.

- Настроенная схема питания
- Сокращение количества служб и драйверов
- Отключены эксклюзивы аудио
- Отключены неиспользуемые устройства
- Отключено энергосбережение
- Отключены требовательные к производительности средства защиты
- Автоматически включенный режим MSI на всех устройствах
- Оптимизация конфигурации загрузки
- Оптимизированное планирование процессов

## 🎨 Брендовый набор
Хотите создать свои собственные обои Atlas? Может быть, поизвращаться с нашим логотипом, чтобы создать свой собственный дизайн? Мы предоставляем это в открытый доступ, чтобы вдохнуть новые творческие идеи в сообщество. [Посмотрите наш набор для создания бренда и сделайте что-нибудь впечатляющее.](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

У нас также есть специальная область на [форуме](https://forum.atlasos.net/t/art-showcase), где вы можете поделиться своими творениями с другими творческими гениями и, возможно, даже вдохновиться!

## ⚠️ Disclaimer
AtlasOS is **NOT** a pre-activated version of Windows, you **must** use a genuine key to run Atlas. Before you buy a Windows 10 (Pro OR Home) license, make sure the seller is trusted and the key is legitimate, no matter where you buy it. Atlas is based on Microsoft Windows, by using Windows you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## Translation contributors (Авторы перевода)

[arl1ne](https://github.com/arl1nef) |
[Lumaeris](https://github.com/Lumaeris)
