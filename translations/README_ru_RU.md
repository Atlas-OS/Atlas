⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://gcore.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="Лицензия" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF&label=%D0%9B%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%8F"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Вкладчики" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=%D0%A7%D0%B8%D1%81%D0%BB%D0%BE%20%D0%B2%D0%BA%D0%BB%D0%B0%D0%B4%D1%87%D0%B8%D0%BA%D0%BE%D0%B2" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Выпуск" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF&label=%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Число скачиваний" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF&label=%D0%A7%D0%B8%D1%81%D0%BB%D0%BE%20%D1%81%D0%BA%D0%B0%D1%87%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D0%B9" />
    </a>
  </p>
<h4 align="center">Открытая и прозрачная операционная система, разработанная для оптимизации производительности, конфиденциальности и стабильности.</h4>

<p align="center">
  <a href="https://atlasos.net">Веб-сайт</a>
  •
  <a href="https://docs.atlasos.net">Документация</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">Форум</a>
</p>

## 🤔 **Что такое Atlas?**

Atlas - это модифицированная версия Windows 10, в которой устранены все негативные особенности Windows, отрицательно влияющие на игровую производительность.
Уделяя основное внимание производительности и сохранению конфиденциальности вашей системы, Atlas также является отличным вариантом для снижения системных задержек, сетевых задержек и задержек ввода.
Вы можете узнать больше об Atlas на нашем официальном [сайте](https://atlasos.net).

## 📚 **Содержание**

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

## 👀 **Почему именно Atlas?**

### 🔒 Больше конфиденциальности
Стандартная Windows содержит службу отслеживания, которая собирает ваши данные и отправляет их в Microsoft.
Atlas удаляет все типы отслеживания, встроенные в Windows, и внедряет многочисленные групповые политики для минимизации сбора данных.

Обратите внимание, что мы не можем обеспечить безопасность того, что выходит за рамки системы (например, браузеры и приложения от сторонних разработчиков.)

### 🛡️ Больше безопасности по сравнению с пользовательскими ISO-образами Windows
Загрузка модифицированного ISO-образа из Интернета является очень рискованной. Мало того, что люди могут легко злоумышленно изменить один из многих бинарных/исполняемых файлов, входящих в состав Windows, в ISO-образе также могут отсутствовать последние исправления безопасности, что может подвергнуть ваш компьютер серьезной опасности.

Atlas устроена по-другому. Для установки мы используем [AME Wizard](https://ameliorated.io), и все скрипты, которые мы используем, находятся в открытом доступе в нашем репозитории. Вы можете просмотреть упакованный плейбук Atlas (`.apbx` - пакет скриптов AME Wizard) в виде архива, с паролем `malte` (является стандартным для плейбуков AME Wizard), который служит только для обхода ложных срабатываний от антивирусов.

Единственные исполняемые файлы, включенные в плейбук, [находятся в открытом доступе](https://github.com/Atlas-OS/Atlas-Utilities) под лицензией [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE), а хэши идентичны релизам. Все остальное - обычный текст.

Вы также можете применить последние обновления безопасности перед установкой Atlas, обеспечивая безопасность вашей системы.

Обратите внимание, что начиная с Atlas v0.2.0, Atlas в основном **не так безопасен, как обычная Windows**, из-за удаленных/отключенных функций безопасности, таких как Защитник Windows. Однако в Atlas v0.3.0 большинство из них будут добавлены обратно в качестве дополнительных функций. Более подробную информацию смотрите [здесь](https://docs.atlasos.net/troubleshooting/removed-features/).

### 🚀 Больше места
Предустановленные приложения и другие незначимые компоненты удалены из Atlas. Несмотря на возможность возникновения проблем с совместимостью, это значительно уменьшает размер установки и делает систему более гибкой. Поэтому такие функции, как Защитник Windows и подобные, полностью удалены.
Узнайте, что еще мы удалили в нашем [FAQ](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ Больше производительности
Некоторые настроенные системы в Интернете зашли слишком далеко, нарушив совместимость основных функций, таких как Bluetooth, Wi-Fi и так далее.
Atlas же находится в оптимальной точке. Она обеспечивает большую производительность, но при этом сохраняет хорошую совместимость.

Ниже перечислены некоторые из многочисленных изменений, которые мы сделали для улучшения Windows:
- Настроенная схема питания
- Сокращение количества служб и драйверов
- Отключены эксклюзивы аудио
- Отключены неиспользуемые устройства
- Отключено энергосбережение (для персональных компьютеров)
- Отключены требовательные к производительности средства защиты
- Автоматически включенный режим MSI на всех устройствах
- Оптимизация конфигурации загрузки
- Оптимизированное планирование процессов

### 🔒 Легальность
Многие пользовательские ОС Windows распространяются с изменениями ISO-образа Windows. Это не только нарушает [Условия соглашения Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Russian.htm), но и не является безопасным способом установки.

Atlas совместно с командой Windows Ameliorated предоставила пользователям более безопасный и законный способ установки - [AME Wizard](https://ameliorated.io). Используя его, Atlas полностью соблюдает [Условия соглашения Microsoft](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Russian.htm).

## 🎨 Брендовый набор
Чувствуете себя креативным? Хотите создать свои собственные обои Atlas с оригинальным креативным дизайном? Наш брендовый набор поможет вам в этом!
Набор Atlas находится в открытом доступе, вы можете скачать его [здесь](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip) и сделать что-то потрясающее!

У нас также есть специальная область на [форуме](https://forum.atlasos.net/t/art-showcase), где вы можете поделиться своими творениями с другими творческими гениями и, возможно, даже вдохновиться! Здесь вы также можете найти креативные обои, которыми делятся другие пользователи!

## ⚠️ Disclaimer (Disclaimer)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (Авторы перевода)
[arl1ne](https://github.com/arl1nef) |
[Lumaeris](https://github.com/Lumaeris)
