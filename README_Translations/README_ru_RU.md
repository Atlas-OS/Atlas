<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Открытая и прозрачная операционная система Windows, разработанная для оптимизации производительности и задержки.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Установка</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
</p>
<p align="center">
 Другие языки:
   <a href="https://github.com/Atlas-OS/Atlas/blob/main/README.md">English</a> • <a href="https://github.com/Atlas-OS/Atlas/blob/main/README_Translations/README_zh_CN.md">简体中文</a> • <a href="https://github.com/Atlas-OS/Atlas/blob/main/README_Translations/README_fr_FR.md">Français</a> • <a href="https://github.com/Atlas-OS/Atlas/blob/main/README_Translations/README_pl_PL.md">Polski</a>
</p>

# Что такое Atlas?

Atlas - это модифицированная версия Windows, в которой устранены все негативные недостатки Windows, отрицательно влияющие на игровую производительность. Мы являемся прозрачным проектом с открытым исходным кодом, стремящимся к равным правам для игроков, независимо от того, используете ли вы ПК низкого класса или игровой ПК.

Уделяя основное внимание производительности, мы также являемся отличным вариантом для снижения системных задержек, сетевых задержек, задержек ввода и сохранения конфиденциальности вашей системы.

## Содержание

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Что представляет собой проект Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Как установить Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Что удаленно в Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [После установки](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Брендовый комплект](./img/brand-kit.zip)

## Windows vs. Atlas

### **Конфиденциальность**

Atlas удаляет все типы отслеживания, встроенные в Windows, и реализует многочисленные групповые политики для минимизации сбора данных. Мы не можем повысить конфиденциальность данных, которые находятся за пределами Windows, например, посещаемых вами веб-сайтов.

### **Безопасность**

Atlas стремится быть максимально безопасным без потери производительности. Мы добиваемся этого путем отключения функций, которые могут привести к утечке информации или быть использованы. Существуют исключения, такие как [Spectre](https://spectreattack.com/spectre.pdf) и [Meltdown](https://meltdownattack.com/meltdown.pdf). Эти средства защиты отключаются для повышения производительности.
Если меры по снижению безопасности снижают производительность, они будут отключены.
Ниже приведены некоторые функции/минимумы, которые были изменены, если они содержат символ (P), то это риски безопасности, которые были исправлены:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Возможный поиск информации_)

### **Удаленно**

Atlas сильно очищен, удалены предустановленные приложения и другие компоненты. Несмотря на возможность возникновения проблем с совместимостью, это значительно уменьшает размер ISO и размер установки. Функциональные возможности, такие как Windows Defender и подобные, полностью удалены. Эта модификация ориентирована на чистые игры, но большинство рабочих и образовательных приложений работают. [Узнайте, что еще мы удалили в нашем FAQ] (https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Производительность**

Atlas предварительно настроен. Сохраняя совместимость, но также стремясь к производительности, мы выжали все до последней капли производительности из наших образов Windows. Ниже перечислены некоторые из многочисленных изменений, которые мы сделали для улучшения Windows.

- Настроенная схема питания
- Сокращены количества служб
- Сокращены количества драйверов
- Отключены не используемые устройств
- Отключенное энергосбережение
- Отключение требовательных к производительности средств защиты
- Автоматически включенный режим MSI
- Оптимизация конфигурации загрузки
- Оптимизированное планирование процессов

## Брендовый набор

Хотите создать свои собственные обои Atlas? Может быть, поизвращаться с нашим логотипом, чтобы создать свой собственный дизайн? Мы предоставляем это в открытый доступ, чтобы вдохнуть новые творческие идеи в сообщество. (Посмотрите наш набор для создания бренда и сделайте что-нибудь впечатляющее.](./img/brand-kit.zip)

У нас также есть [специальная область во вкладке обсуждений](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), где вы можете поделиться своими творениями с другими творческими гениями и, возможно, даже вдохновиться!

## Заявление об отказе от претензий

Загружая, изменяя или используя любое из этих изображений, вы соглашаетесь с [Условиями Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). Ни один из этих образов не является предварительно активированным, вы **должны** использовать подлинный ключ.

## Translation contributors (Автор перевода)

[arl1ne](https://github.com/arl1nef)
