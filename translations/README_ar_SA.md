## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">نظام تشغيل مَفتوح المصدر، مُصمم لتحسين الأداء وزيادة خُصوصيّة واستقرار نظامك.</h4>

<p align="center">
  <a href="https://atlasos.net">الموقع الإلكتروني</a>
  •
  <a href="https://docs.atlasos.net">وثائق</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">دسكورد</a>
  •
  <a href="https://forum.atlasos.net">المنتدى</a>
</p>

## 🤔 **مَا هُو أطلس؟**

أطلس هو نسخة مُعدلة من ويندوز ١٠ لمعالجة أغلب العُيوب والمشاكل التي قد تؤثّر سلبًا على أداء جهازك عند تشغيل الألعاب. نحن أيضًا خيار رائع لتقليل وقت استجابة النظام والشّبكة (latency) وتحسين زمن الإدخال (input lag) مع الحفاظ على خُصوصيّة نظامك والإبقاء على تركيزنا الأساسي ألا وهو الأدَاء. <br /> يمكنك معرفة المزيد عن أطلس من خلال [موقعنا الرسمي](https://atlasos.net).

## 📚 **جدول المُحتوى:**

<ul>
<li>البداية:
<ul>
<li>
<a href="https://docs.atlasos.net/getting-started/installation">حمل أطلس الآن!</a>
</li>
<li>
<a href="https://docs.atlasos.net/getting-started/other-installation-methods/no-usb">طُرق أخرى لتثبيت أطلس</a>
</li>
<li>
<a href="https://docs.atlasos.net/getting-started/post-installation/drivers">بعد تثبيت أطلس بنجاح</a>
</li>
</ul>
</li>
<li>إذا واجهت مُشكلة:
<ul>
<li>
<a href="https://docs.atlasos.net/troubleshooting/removed-features">ماذا حُذف في أطلس؟</a>
</li>
<li>
<a href="https://docs.atlasos.net/troubleshooting/scripts">Scripts</a>
</li>
</ul>
</li>
<li>الأسئلة الشّائعة:
<ul>
<li>
<a href="https://docs.atlasos.net/FAQ/Installation">أسئلة مُتعلقة بالتثبيت</a>
</li>
<li>
<a href="https://docs.atlasos.net/FAQ/Contribute">كيف أقدّر أساعد؟</a>
</li>
</ul>
</li>
</ul>

## 👀 **لِماذا أطلس؟**

### 🔒 أكثر خُصوصيّة

يُزيل أطلس جميع أدوات التعقُّب الموجودة في ويندوز مسبقًا ويضيف العديد من ال(group policies) لتقليل جَمع البيانات. <br /> لكن هذا يحدث فقط على نِطاق ويندوز؛ لا يُمكننا زيادة خصوصيّتك عندما تزُور موقعًا على الويب مثلًا.

### 🛡️ أكثر أمنًا

يُعد تنزيل وتثبيت ملف ISO معدّل من الإنترنت محفوفًا بالمخاطر. ليس فقط لإمكانيّة احتوائه على برمجيّات ضارّة، بل لأنه قد لا يحتوي على أحدث التحديثات الأمنيّة، بالتالي جعل جهازك عُرضة لمخاطر أمنية خطيرة.

أطلس مُختلف. نَستخدم [AME Wizard](https://ameliorated.io) للتَّثبيت، وجميع ال(scripts) التي يتم استخدامها مفتُوحة المصدر هنا في GitHub. يُمكنك أيضًا تحميل آخر تحديثات الأمان من ويندوز قبل تثبيتك لأطلس، مما سوف يُساهم في الحفاظ على أمان نظامك.

### 🚀 مِساحة أكبر

تمَّ إزالة أغلب التطبيقات المثبتة مسبقًا والمكونات غير المهمة الأُخرى التي تأتي مع ويندوز في أطلس. على الرغم من احتمال حُدوث بعض المشاكل في التوافق، فإن هذا يُقلِّل بشكل كبير من حجم ملفّ التثبيت وحجم الويندوز ككُل، مما يجعل جهازك أكثر سَلاسة. لذلك، الوظائف مثل Windows Defender وما إلى ذلك تمَّ حذفها تمامًا. تحقَّق من الأشياء التي قُمنا بإزالتها في [الأسئلة الشّائعة](https://docs.atlasos.net/troubleshooting/removed-features).

### ✅ المزيد من الأدَاء

بعض الأنظمة على الإنترنت تمَّ تعديلها كثيرًا لدرجة تَعطِيل بعض المزايا الأساسيَّة مثل البلوتوث أو الواي فاي، أطلس لا يَفعل ذلك. <br /> نحن في المنتصف حيث نُقدِّم لك المزيد من الأداء بينما نُحافظ على نسبة توافق جيدة.

هذه بعض التغييرات التي أجريناها لتحسين الأداء:

<ul>
<li>مُخطَّط طاقة مُخصَّص</li>
<li>تَقليل عدد الخدمات التي تعمل بالخلفيَّة</li>
<li>تَعطِيل (audio exclusive)</li>
<li>تعطيل الأجْهزة الغير ضّرورية</li>
<li>تعطيل توفير الطَّاقة (لأجهزة سطح المكتب)</li>
<li>تعطيل إجراءات زيادة الأمَان المستنزفة للأداء</li>
<li>تشغيل وضع MSI تِلقائيًا على جميع الأجهزة</li>
<li>تحسِين (BCD)</li>
<li>تحسين جدولة العمليّات</li>
</ul>

### 🔒 قانونيًا

تُوَزَّع العديد من أنظمة تشغيل ويندوز الأخرى من خلال توفير ISO مُعدّل للنظام. هذا لا ينتهك [شروط خدمة مايكروسوفت](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Arabic.htm) فحسب، بل إنه أيضًا طريقة غير آمنة للتثبيت وقد تُعرِّض جهازك للضرر.

عَقد أطلس شراكة مع فريق Windows Ameliorated لتزويد المستخدمين بطريقة آمنة وقانونية للتثبيت، [AME Wizard](https://ameliorated.io). <br /> باستخدامه، يتوافق أطلس تمامًا مع [شروط خدمة مايكروسوفت](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_Arabic.htm).

## 🎨 عُدّة البراند

هل ترغب في إنشاء خلفية أطلس الخاصّة بك؟ ربما العبث بشعارنا لعمل التصميم الخاص بك؟ عُدَّتنا في مُتناول الجميع. <br/> [جَرّب العبث بعلامتنا التجاريّة واصنع شيئًا مُذهلًا!](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

أيضًا لدينا [مساحة خاصّة للمبدعين](https://forum.atlasos.net/t/art-showcase), حتّى تتمكّن من مُشاركة أفكارك وإبداعاتك مع عباقرة ومبدعين آخرين!

## ⚠️ إخلاء مسؤوليّة - Disclaimer

<div align='right'>

https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

</div>

## ✍️ القائمون على التّرجمة

[خليل مِلحم](https://github.com/pewpewded/)
