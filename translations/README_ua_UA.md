<h1 align="center">
  <br>
  <a href="http://atlasos.net"><img src="https://i.imgur.com/xV08gIt.png" alt="Atlas" width="900"></a>
</h1>
<h4 align="center">Відкрита та прозора операційна система Windows, розроблена для оптимізації продуктивності та зменшення затримок.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">Установка</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">FAQ</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Форум</a>
</p>


# Що таке Atlas?

Atlas - це модифікована версія Windows 10, яка усуває всі недоліки Windows, що негативно впливають на ігрову продуктивність. Це прозорий проект з відкритим кодом, який прагне забезпечити рівні права для гравців, незалежно від того, чи використовуєте ви бюджетний, чи ігровий комп'ютер.

Ми також є чудовим варіантом зменшити затримку системи, мережеву затримку, затримку введення та зберегти конфіденційність вашої системи, зберігаючи при цьому основну увагу на продуктивності.

## Зміст

- [FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ)
  - [Що таке проект "Atlas"?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project)
  - [Як встановити Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os)
  - [Що видалено в Atlas?](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os)
- <a href="#windows-vs-atlas">Windows vs. Atlas</a>
- [Пост-інсталяція](https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install)
- [Брендування](https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip)

## Windows vs. Atlas

### **Конфіденційність**

Atlas видаляє всі типи відстеження, вбудовані в Windows, і впроваджує численні групові політики для мінімізації збору даних. Ми не можемо підвищити рівень конфіденційності для речей поза межами Windows, наприклад, веб-сайтів, які ви відвідуєте.

### **Безпека**

Atlas прагне бути максимально безпечним без втрати продуктивності. Ми робимо це шляхом вимкнення функцій, які можуть призвести до витоку інформації або бути використані. Існують винятки, такі як [Spectre](https://spectreattack.com/spectre.pdf), and [Meltdown](https://meltdownattack.com/meltdown.pdf). Ці функції вимкнено для покращення продуктивності.
Якщо захід зі зниження безпеки знижує продуктивність, його буде вимкнено.
Нижче наведено деякі функції / виправлення, які були змінені, якщо вони містять (P), то це ризики безпеки, які були виправлені:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- [(P) ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- [(P) Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (_Можливий пошук інформації_)

### **Видалено**

Atlas сильно очищено, попередньо встановлені програми та інші компоненти видалено. Незважаючи на можливість виникнення проблем із стабільністю, це значно зменшує розмір ISO та інсталяційного файлу. Такі функції, як Windows Defender та інші, видалено повністю. Ця модифікація орієнтована на ігри, але більшість робочих і навчальних програм працюють. [Подивіться, що ще ми видалили в нашому FAQ](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### **Продуктивність**

Atlas попередньо налаштований. Зберігаючи стабільність, але також прагнучи до продуктивності, ми доклали максимум зусиль, щоб зробити наші образи Windows максимально ефективними. Нижче наведено деякі з багатьох змін, які ми зробили для покращення роботи Windows.

- Індивідуальна схема електроживлення
- Зменшення кількості сервісів
- Зменшення кількості драйверів
- Вимкнення зайвих пристроїв
- Вимкнено функціі енергозбереження
- Вимкнення високонавантажених засобів захисту, що вимагають високої продуктивності
- Автоматично ввімкнено режим MSI на всіх пристроях
- Оптимізація конфігурації завантаження
- Оптимізоване планування процесів

## Комплект для брендування

Хочете створити власні обої Atlas? Може, погратися з нашим логотипом, щоб створити власний дизайн? Ми зробили це доступним для всіх, щоб стимулювати нові творчі ідеї в усій спільноті. [Ознайомтеся з нашим фірмовим набором і зробіть щось вражаюче.](https://github.com/Atlas-OS/Atlas/blob/main/img/brand-kit.zip?raw=true)

У нас також є [спеціальний розділ у вкладці обговорення](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), щоб ви могли поділитися своїми творіннями з іншими творчими геніями і, можливо, навіть надихнутися!

## Disclaimer (Відмова від відповідальності)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). None of these images are pre-activated, you **must** use a genuine key.

## Translation contributors (Дописувачі перекладу)

[kentffg](https://github.com/kentffg) | [Xyueta](https://github.com/Xyueta)
