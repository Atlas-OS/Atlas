⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net" target="_blank"><img src="/img/github-banner.png" alt="Atlas" width="800"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Лиценз" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Приносители" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Издания" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
  </p>
<h4 align="center">Отворена и открита операционна система, проектирана да оптимизира производителността, поверителноста и стабилността.</h4>

<p align="center">
  <a href="https://atlasos.net">🌐 Уебсайт</a>
  •
  <a href="https://docs.atlasos.net">📚 Документация</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">☎️ Дискорд</a>
  •
  <a href="https://forum.atlasos.net">💬 Форум</a>
</p>

## 📚 **Съдържание**

- [Указания за принос](https://docs.atlasos.net/contributions)
- [Инсталация](https://docs.atlasos.net/getting-started/installation)
  
- След инсталацията
  - [Папката Атлас](https://docs.atlasos.net/getting-started/post-installation/atlas-folder/configuration/)
  - [Драйвъри](https://docs.atlasos.net/getting-started/post-installation/drivers/getting-started/)

- Отстраняване на неизправности
  - [Често задавани въпроси & Често срещани проблеми](https://docs.atlasos.net/faq-and-troubleshooting/removed-features/)
  - [Скриптове](https://docs.atlasos.net/faq-and-troubleshooting/atlas-folder-scripts/)
  
## 🤔 **Какво е Atlas?**

Atlas е модифицирана версия на Windows 10, която премаха всички задръжки които негативно засягат gaming производителността.
Atlas е също добра опция да се намали забавянето на системата, забавянето на мрежата, закъснението при въвеждане и да пази системата поверителна докато се фокусира върху производителността. 
Можеш да научиш повече за Atlas на нашия официален [уебсайт](https://atlasos.net). 


## 👀 **Защо Atlas?**

### 🔒 По-поверителен
Стоковия Windows съдържа проследяващи услуги които събират вашата информация и я пращат на Microsoft.
Atlas премахва всички видове проследаващи услуги вградени във Windows и прилага десетки групови политики за да минимизира събирането на данни. 

Имайте предвид, че Atlas не може да гарантира сигурността на неща извън обхвата на Windows (като браузъри и приложения от трети страни).

### 🛡️ По-сигурен (от модифицираните Windows ISO-та)
Изтеглянето на модифицирано ISO от интернет може да бъде рисковано. Не само хората могат лесно да модифицират бинарни/изпълняеми файлове включени във Windows, но може и да не съдържат пачове за сигурност който могат да поставят вашия компютър под риск.

Atlas също идва със следните функции за сигурност който може да си изберете, който обаче други персонализирани Windows-и премахват.
- Windows Security
  - Windows Defender & SmartScreen (По избор)
  - Изолация на ядрата (По избор)
  - CPU мерки (По избор)
- Windows Update-и (По избор)

Atlas е различен. Ние използваме [AME Wizard](https://ameliorated.io) да инсталираме Atlas и всички скриптове които използваме са open-sourced тук в нашето GitHub repository. Може да видите пакетирания Atlas playbook(`.apbx` - AME Wizard скриптов пакет) като архив, със паролата `malte`(стандартната за AME Wizard playbook-овете), който е само за да заобиколи фалшивите сигнализации от анти-вирусните.

Единствените изпълними файлове във playbook-a са open-source [тук](https://github.com/Atlas-OS/Atlas-Utilities) под [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), със хашовете бивайки идентични към изданията. Всичко друго е във чист текст.


### ✅ Повече производителност
Някои променени системи във интернета са променени твърде много, разваляики съвместимостта със главни функции като Bluetooth, Wi-fi, и т.н.  
Atlas е в златната среда. Той се цели да получи повече производителност докато поддържа добро ниво на съвместимост.

Някои от многото промени които сме направили за да подобрим Windows са изброени по долу:
- Персонализирана захранваща схема
- Намален брой на услуги и драйвъри
- Изключено ексклузивно аудио
- Изключени ненужни устройства
- Изключено спестяване на енергия (за настолни компютри) 
- Деактивирани жадни за ресурси мерки за сигирност
- Автоматично активиран MSI режим на всички устройства
- Оптимизарана конфигурация за стартиране 
- Оптимизация на планирането на процеси 

### 🔒 Легална част
Много персонализирани ОС-ове дистрибутират техните системи със променени ISO на Windows. Не само нарушава [Условията за Ползване на Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Bulgarian.htm), но също не е и сигурен начин за инсталиране .

Atlas партнира със Windows Ameliorated Team за да предостави на потребителите си по-сигурен и по-легален начин да инсталира Atlas, използвайки [AME Wizard](https://ameliorated.io). Със него, Atlas напълно спазва [Условията за Ползване на Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Bulgarian.htm).

## 🎨 Brand kit
Чустваш се креативен? Искаш да създадеш свой Atlas тапет със оригинален и креативен дизайн? Нашия марков комплект ви осигурява!
Всеки има достъп към марковия комплект на Atlas — можеш да го изтеглиш [тук](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) и да направиш нешо прекрасно!

Ние също имаме специална част за това на нашия [форум](https://forum.atlasos.net/t/art-showcase), за да може да споделите вашите творби със други креативни гении и дори да предизвикате вдъхновение! Можете да намерите и креативни тапети които други потребители са споделили тук!

## ⚠️ Disclaimer (Отказ от отговорност)
[Disclaimer](https://github.com/Atlas-OS/Atlas#%EF%B8%8F-not-pre-activated)

## Translation contributors （Сътрудници за превода）
[dido](https://github.com/notdido)
