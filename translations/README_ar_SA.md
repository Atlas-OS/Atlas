## ⚠️WARNING! This translation is not yet updated with the main README.md, information here may be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">نظام تشغيل مليء بالحرية، مصمم لتحسين الأداء وتقليل أزمنة الانتقال.</h4>

<p align="center">
  <a href="https://github.com/Atlas-OS/Atlas/wiki/2.-Installing">التنصيب</a>
  •
  <a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#contents">الأسئلة الشائعة</a>
  •
  <a href="https://discord.com/servers/atlas-795710270000332800" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">مساحة للنقاش</a>
</p>

## 🤔 ما هو أطلس؟ 

أطلس هو نسخة معدلة من ويندوز ١٠ لمعالجة أغلب العيوب والمشاكل التي قد تؤثر سلبًا على أداء الجهاز عند تشغيل الألعاب. نحن أيضًا مشروع مفتوح المصدر ونسعى جاهدين لتحقيق المساواة بين اللاعبين سواءً امتلكوا أجهزة منخفضة التكلفة أو أجهزة باهظة بمواصفات عالية.

نحن أيضًا خيار رائع لتقليل وقت استجابة النظام والشبكة (latency) وتحسين زمن الإدخال (input lag) مع الحفاظ على خصوصية نظامك والإبقاء على تركيزنا الأساسي ألا وهو الأداء.

## 📚 جدول المحتوى: 

<ul>
<li><a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ">الأسئلة الشائعة:</a><ul><li><a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#11-what-is-the-atlas-project">ما هو مشروع أطلس؟</a></li>
<li><a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#12-how-do-i-install-atlas-os">كيف أحمل أطلس؟</a></li>
<li><a href="https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os">ما هي الأشياء المحذوفة في أطلس؟</a></li></ul></li>
<li><a href="#windows-vs-atlas">ويندوز أو أطلس؟</a></li>
<li><a href="https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install">بعد تثبيت أطلس بنجاح</a></li>
<li><a href="https://raw.githubusercontent.com/Atlas-OS/Atlas/main/img/brand-kit.zip">عدة البراند</a></li>
</ul>

## <h1 id="windows-vs-atlas"> 🆚 ويندوز أو أطلس؟</h1>

### 🔒 **الخصوصية**

يزيل أطلس جميع أدوات التعقب الموجودة في ويندوز مسبقًا ويضيف العديد من ال(group policies) لتقليل جمع البيانات. لكن هذا يحدث فقط على نطاق ويندوز؛ لا يمكننا زيادة خصوصيتك عندما تزور موقعًا على الويب مثلًا.

### 🛡️ **الأمان**

يهدف أطلس إلى أن يكون آمنًا قدر الإمكان مع إبقاء الأداء أولوية. نقوم بذلك عن طريق تعطيل المزايا التي يمكنها تسريب المعلومات أو جعل معلوماتك عرضة للاستغلال. هنالك استثناءات لهذا مثل [Spectre](https://spectreattack.com/spectre.pdf) و [Meltdown](https://meltdownattack.com/meltdown.pdf)، تم تعطيلهم لتخفيف وتحسين الأداء. إذا أدت المزايا الأمنية إلى انخفاض الأداء، فسوف يتم تعطيلها. فيما يلي بعض المزايا التي تم تعديلها، إذا كانت تحتوي على الحرف (P) فهي مخاطر أمنية تم إصلاحها:

<ul dir="rtl">
  <li><a href="https://spectreattack.com/spectre.pdf">Spectre</a></li>
  <li><a href="https://meltdownattack.com/meltdown.pdf">Meltdown</a></li>
  <li><a href="https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt">DMA Remapping</a></li>
  <li><a href="https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020">(P) ATMFD Exploit</a></li>
  <li><a href="https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability">(P) Print Nightmare</a></li>
  <li><a href="https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop">Remote Desktop</a></li>
  <li><a href="https://en.wikipedia.org/wiki/NetBIOS">NetBIOS</a> (امكانية استخراج المعلومات)</li>
</ul>

### 🚀 **مخفف**

نظام أطلس مجرد بشدة، تم إزالة أغلب التطبيقات المثبتة مسبقًا. على الرغم من احتمال حدوث بعض المشاكل في التوافق، فإن هذا يقلل بشكل كبير من حجم ملف التثبيت وحجم الويندوز ككل. الوظائف مثل Windows Defender وما إلى ذلك تم حذفها تمامًا. يركز هذا الويندوز على الألعاب بشكل بحت، ومع ذلك معظم تطبيقات العمل والتعليم تعمل بشكل طبيعي. [تحقق من الأشياء التي قمنا بإزالتها في الأسئلة الشائعة](https://github.com/Atlas-OS/Atlas/wiki/1.-FAQ#13-whats-removed-in-atlas-os).

### ✅ **أداء قوي**

سعينا جاهدين لتحقيق أفضل أداء، قمنا بضغط كل قطرة من الأداء في نظام ويندوز الخاص بنا. <br/> هذه بعض التغييرات التي أجريناها لتحسين الأداء:

<ul>
<li>مخطط طاقة مخصص</li>
<li>تقليل كمية الخدمات التي تعمل بالخلفية</li>
<li>تعطيل (Audio exclusive)</li>
<li>تعطيل الأجهزة الغير ضرورية</li>
<li>تعطيل توفير الطاقة</li>
<li>تعطيل إجراءات زيادة الأمان المستنزفة للأداء</li>
<li>تشغل وضع MSI تلقائيًا على جميع الأجهزة</li>
<li>تحسين (BCD)</li>
<li>تحسين جدولة العمليات</li>
</ul>

## 🎨 عدة البراند

هل ترغب في إنشاء خلفية أطلس الخاصة بك؟ ربما العبث بشعارنا لعمل التصميم الخاص بك؟ عدتنا في متناول الجميع. <br/> [جرب العبث بعلامتنا التجارية واصنع شيئًا مذهلًا!](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

أيضًا لدينا [مساحة خاصة للمبدعين](https://github.com/Atlas-OS/Atlas/discussions/categories/community-artwork), حتى تتمكن من مشاركة أفكارك وإبداعاتك مع عباقرة ومبدعين آخرين!

## ⚠️ Disclaimer (تنبيه)

By downloading, modifying, or utilizing any of these images, you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm). <br/> None of these images are pre-activated, you **must** use a genuine key.

## Translation Contributors (مساهمات الترجمة)

[Khalil Melhem](https://github.com/pewpewded) |
[VOID](https://github.com/dz-void)
