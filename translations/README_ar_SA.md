<div align="right" dir="rtl">

<h1 align="center">
  <a href="http://atlasos.net"><img src="https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>

<h4 align="center">نظام تشغيل Windows مفتوح المصدر بشفافية ، مصمم لتحسين الأداء وزمن الانتقال.</h4>

<p align="center">
  <a href="https://atlasos.net">الموقع الالكتروني</a>
  •
  <a href="https://docs.atlasos.net/FAQ/Installation/">التعليمات</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">Discord</a>
  •
  <a href="https://forum.atlasos.net">المنتدي</a>
</p>

## 🤔 **لماذا Atlas؟**
<div dir="rtl">
Atlas هو نسخة معدلة من Windows 10 ، والتي تزيل جميع عيوب Windows السلبية التي تؤثر سلبًا على أداء الألعاب. نحن مشروع مفتوح المصدر وشفاف نسعى جاهدين للحصول على حقوق متساوية للاعبين سواء كنت تقوم بتشغيل جهاز كمبيوتر منخفض التكلفة أو كمبيوتر ألعاب.

نحن أيضًا خيار رائع لتقليل زمن انتقال النظام وزمن وصول الشبكة وتأخر الإدخال والحفاظ على خصوصية نظامك مع الحفاظ على تركيزنا الأساسي على الأداء
.
يمكنك معرفة المزيد عن Atlas عبر [موقعنا الرسمي](https://atlasos.net).


## 📚 **جدول المحتويات**
- التعليمات
  - [التثبيت](https://docs.atlasos.net/FAQ/Installation/)
  - [المساهمة](https://docs.atlasos.net/FAQ/Contribute/)

- البدأ
  - [التثبيت](https://docs.atlasos.net/Getting%20started/Installation/)
  - [طرق التثبيت الأخرى](https://docs.atlasos.net/Getting%20started/Other%20installation%20methods/Install%20with%20no%20USB/)
  - [ما بعد التثبيت](https://docs.atlasos.net/Getting%20started/Post-Installation/Drivers/)

- استكشاف الأخطاء وإصلاحها
  - [الميزات التي تمت إزالتها](https://docs.atlasos.net/Troubleshooting/Removed%20features/)
  - [الملحقات](https://docs.atlasos.net/Troubleshooting/Scripts/)

- <a href="#windows-vs-atlas">Windows مقرانة ب Atlas</a>
- [مجموعة العلامات التجارية](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

## 🆚 **Windows مقرانة ب Atlas**

### 🔒 يخصك
يزيل Atlas جميع أنواع التعقب المضمنة في Windows وينفذ العديد من سياسات المجموعة لتقليل جمع البيانات. أشياء خارج نطاق Windows لا يمكننا زيادة الخصوصية لها ، مثل مواقع الويب التي تزورها.

### 🛡️ أمن
يهدف Atlas إلى أن يكون آمنًا قدر الإمكان دون فقدان الأداء. نقوم بذلك عن طريق تعطيل الميزات التي يمكنها تسريب المعلومات أو استغلالها. هناك استثناءات لهذا مثل [Specter] (https://spectreattack.com/spectre.pdf) و [Meltdown] (https://meltdownattack.com/meltdown.pdf). تم تعطيل عوامل التخفيف هذه لتحسين الأداء.

إذا أدى قياس التخفيف الأمني ​​إلى انخفاض الأداء ، فسيتم تعطيله.
فيما يلي بعض الميزات / عوامل التخفيف التي تم تغييرها ، إذا كانت تحتوي على (P) فهي مخاطر أمنية تم إصلاحها:

- [Spectre](https://spectreattack.com/spectre.pdf)
- [Meltdown](https://meltdownattack.com/meltdown.pdf)
- [DMA Remapping](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt)
- (P) [ATMFD Exploit](https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2020-1020)
- (P) [Print Nightmare](https://us-cert.cisa.gov/ncas/current-activity/2021/06/30/printnightmare-critical-windows-print-spooler-vulnerability)
- [Remote Desktop](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=Windows+Remote+Desktop)
- [NetBIOS](https://en.wikipedia.org/wiki/NetBIOS) (*Possible information retrieval*)

### 🚀 مخفف
تم تجريد Atlas بشكل كبير ، مع إزالة التطبيقات المثبتة مسبقًا والمكونات الأخرى. على الرغم من احتمال حدوث مشكلات في التوافق ، فإن هذا يقلل بشكل كبير من ISO وحجم التثبيت. تم تجريد وظائف مثل Windows Defender ، وما إلى ذلك تمامًا.

يركز هذا التعديل على الألعاب البحتة ، لكن معظم تطبيقات العمل والتعليم تعمل. تحقق من ما قمنا بإزالته في ملف [التعليمات](https://docs.atlasos.net/Troubleshooting/Removed%20features/).

### ✅ أداء سريع
تم تعديل Atlas مسبقًا. مع الحفاظ على التوافق ، ولكن أيضًا نسعى جاهدين لتحقيق الأداء ، قمنا بضغط كل قطرة أخيرة من الأداء في صور Windows الخاصة بنا.

تم سرد بعض التغييرات العديدة التي أجريناها لتحسين Windows أدناه.

- مخطط طاقة مخصص
- انخفاض كمية الخدمات والسائقين
- صوت معطل حصريا
- الأجهزة المعطلة غير الضرورية
- توفير الطاقة المعوقين
- التخفيفات الأمنية المتعطشة للأداء المعوقين
- تمكين وضع MSI تلقائيًا على جميع الأجهزة
- تحسين تكوين التمهيد
- جدولة عملية محسّنة

## 🎨 مجموعة العلامات التجارية
هل ترغب في إنشاء خلفية أطلس الخاصة بك؟ ربما العبث بشعارنا لعمل التصميم الخاص بك؟ لدينا هذا في متناول الجمهور لإثارة أفكار إبداعية جديدة عبر المجتمع. [تحقق من مجموعة علامتنا التجارية واصنع شيئًا مذهلاً](https://cdn.jsdelivr.net/gh/Atlas-OS/Atlas@main/img/brand-kit.zip)

لدينا أيضًا منطقة مخصصة في [المنتدى] (https://forum.atlasos.net/t/art-showcase) ، حتى تتمكن من مشاركة إبداعاتك مع عباقرة مبدعين آخرين وربما تثير بعض الإلهام!

## ⚠️ Disclaimer - تنازل
AtlasOS is **NOT** a pre-activated version of Windows, you **must** use a genuine key to run Atlas. Before you buy a Windows 10 (Pro OR Home) license, make sure the seller is trusted and the key is legitimate, no matter where you buy it. Atlas is based on Microsoft Windows, by using Windows you agree to [Microsoft's Terms](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm).

## المساهمون في الترجمة
[Crv5heR](https://github.com/Crv5heR)

</div>
