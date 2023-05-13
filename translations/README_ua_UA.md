⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Ліцензія" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Учасники" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Релізи" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Релізи завантажень" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Відкрита та прозора операційна система, створена з метою оптимізації продуктивності, приватності та стабільності.</h4>

<p align="center">
  <a href="https://atlasos.net">Вебсайт</a>
  •
  <a href="https://docs.atlasos.net">Документація</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Форум</a>
</p>

## 🤔 **Що таке Atlas?**

Atlas — це модифікована версія Windows 10, яка прибирає майже всі недоліки Windows, які негативно впливають на ігрову продуктивність.
Також Atlas є гарним вибором для зниження затримок системи, мережі та введення, зберігаючи конфіденційність системи, зосереджуючись на продуктивності.
Ви можете дізнатися більше про Atlas на нашому офіційному [вебсайті](https://atlasos.net).

## 📚 **Зміст**

- [Contribution Guidelines](https://docs.atlasos.net/contributions)

- Getting Started
  - [Installation](https://docs.atlasos.net/getting-started/installation)
  - [Other installation methods](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [Post-Installation](https://docs.atlasos.net/getting-started/post-installation/drivers)

- Troubleshooting
  - [Removed Features](https://docs.atlasos.net/troubleshooting/removed-features)
  - [Scripts](https://docs.atlasos.net/troubleshooting/scripts)

- FAQ
  - [Atlas](https://atlasos.net/faq)
  - [Common Issues](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **Чому саме Atlas?**

### 🔒 Більша приватність
Звичайна Windows має у собі багато contains сервісів відстеження, що збирають ваші дані та надсилають їх до Microsoft.
Atlas видаляє всі типи стеження у Windows та впроваджує численну кількість групових політик для мінімізації збору даних. 

Зауважте, що Atlas не може забезпечити безпеку для речей, що не входять до сфери застосування Windows (такі як браузер чи сторонні застосунки).

### 🛡️ Більша безпека (порівнюючи з іншими користувацькими ISO-образами Windows)
Завантаження модифікованих ISO-образів Windows з інтернету є небезпечним. Крім того, що люди зловмисно можуть змінити багато бінарних/виконуваних файлів у складі Windows, ці образи можуть не мати останніх оновлень безпеки, що можуть поставити ваш комп'ютер під суттєву загрозу. 

Atlas зроблений по-іншому. Ми використовуємо [AME Wizard](https://ameliorated.io) для встановлення Atlas, всі скрипти, які ми використовуємо мають відкритий вихідний код і знаходяться тут, у нашому GitHub репозиторії. Ви можете переглянути упакований Atlas плейбук (`.apbx` - пакет скриптів AME Wizard) як архів, з паролем `malte` (стандарти для плейбуків AME Wizard), який створений тільки для обходу хибних прапорців від антивірусу.

Єдині виконувані файли, що включені в плейбук знаходяться у відкритому доступі [тут](https://github.com/Atlas-OS/Atlas-Utilities) під ліцензією [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), хеши яких є ідентичними з релізами. Все інше — звичайний текст.

Ви також можете встановити останні оновлення безпеки перед встановленням Atlas, що є нашою рекомендацією для забезпечення надійності та безпеки вашої системи.

Будь ласка, врахуйте, що починаючи з версії Atlas v0.2.0, Atlas загалом **менш безпечний, ніж звичайна Windows**, через видалені/вимкнені функції безпеки, такі як Захисник Windows. Однак у версії Atlas v0.3.0 більшість з них буде додано назад як опціональні функції. Дивіться [тут](https://docs.atlasos.net/troubleshooting/removed-features/) для більш детальної інформації. 

### 🚀 Більше місця
Попередньо встановлені застосунки та інші малозначущі компоненти були видалені з Atlas.Попри можливість виникнення проблем із сумісністю, це значно зменшує розмір інсталяції та робить вашу систему більш гнучкою. Тому, деякі функції, (як Захисник Windows) вилучені повністю.
Подивіться, що ще ми видалили в нашому [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Більша продуктивність
Деякі налаштовані системи в інтернеті заходять далеко, зламуючи своїми налаштуваннями сумісність із базовими функціями, такими як Bluetooth, Wi-Fi, і так далі.
Atlas є золотою серединою. Вона забезпечує отримання максимальної продуктивності, водночас зі збереженням сумісності.

Деякі з великої кількості змін, що ми зробили для покращення Windows зазначений нижче:
- Індивідуальна схема живлення
- Знижена кількість служб та драйверів
- Вимкнення зайвих аудіосервісів
- Вилучені непотрібні пристрої
- Вимкнене енергозбереження (для персональних комп'ютерів)
- Вимкнені засоби захисту, що сильно впливають на продуктивність
- Автоматично увімкнено режим MSI для всіх пристроїв
- Оптимізовано конфігурацію завантаження
- Оптимізоване планування процесів

### 🔒 Легальність
Багато користувацьких операційних систем Windows розповсюджують свої системи шляхом надання модифікованого ISO-образу. Це не тільки порушує [Угоду використання Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm), але і є ненадійним методом встановлення.

Atlas є партнером команди Ameliorated, щоб забезпечити користувачам безпеку і легальний шлях встановлення — [AME Wizard](https://ameliorated.io). З ним, Atlas повністю сумісний із [Угодою використання Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## 🎨 Набір брендування
Відчуваєте натхнення? Хочете створити власні шпалери Atlas з оригінальним креативним дизайном? У нашому наборі є все необхідне!
Будь-хто змогу завантажити набір брендування [тут](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) і зробити щось грандіозне!

У нас також є спеціальний розділ на нашому [форумі](https://forum.atlasos.net/t/art-showcase), тож ви можете поділитися своїми творіннями з іншими креативними геніями та, можливо, надихнути когось! Також, там ви зможете знайти оригінальні шпалери інших користувачів тут!

## ⚠️ Disclaimer (Дисклеймер)
https://github.com/Atlas-OS/Atlas/#%EF%B8%8F-disclaimer

## Translation contributors (Дописувачі перекладу)
[kentffg](https://github.com/kentffg) |
[Xyueta](https://github.com/Xyueta) |
[va1dee](https://github.com/va1dee)
