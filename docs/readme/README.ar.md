# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

تطبيق SwiftUI أصلي لنقل الملفات عبر USB بين Android وMac المزود بـ Apple Silicon. واجهة بسيطة بأسلوب Finder، ولون النظام، وبحث أصلي وLiquid Glass. يُثبّت مستقلًا عن Google Android File Transfer.

## المتطلبات والتثبيت

يتطلب **Apple Silicon / arm64 وmacOS 14.0 أو أحدث**. تم التحقق على macOS 27.2 وGalaxy Z Fold7؛ لم يتم التحقق من macOS 28 أو Intel أو الأجهزة الأخرى. شغّل `dist/MacAndFiles.app` بعد البناء أو فك ZIP وضع التطبيق في Applications. يتضمن libmtp/libusb؛ لا يلزم Homebrew أو Android Studio للتشغيل. هذا إصدار تطوير بتوقيع ad-hoc دون Developer ID أو توثيق Apple.

## الاتصال والاستخدام

اتصل بكابل بيانات USB، وافتح قفل Android، واختر «نقل الملفات / Android Auto». أغلق Android File Transfer وAgent التابع له وتطبيقات MTP الأخرى. ابحث عن الأجهزة واختر جهازًا واتصل به. لا يلزم تصحيح USB أو ADB. انقر مرتين لفتح المجلدات؛ ⌘D يحفظ على Mac و⌘U يرسل إلى Android؛ يمكن إسقاط ملفات Finder أيضًا. ⌘↑ يصعد، و⌘⇧N ينشئ مجلدًا، و⌘R يحدث. ⌘F يبحث في أسماء المجلد الحالي فقط؛ المسح أو Esc يعيد القائمة. تُلغى تحديدات العناصر المخفية بالبحث. المزيد يتضمن المساعدة وقطع الاتصال والتشخيص. راجع أسماء الملفات قبل مشاركة السجلات.

## اللغات

يتبع لغة macOS المفضلة ولغة التطبيق في إعدادات النظام → عام → اللغة والمنطقة. أعد تشغيل التطبيق بعد التغيير. يتضمن 13 لغة ويستخدم الإنجليزية لغير المدعوم. تتبع التواريخ والأحجام والنسب المنطقة، وتبقى أسماء الملفات والأجهزة كما هي. قد تبقى تشخيصات المكتبات بالإنجليزية. الواجهة العربية تستخدم اتجاه النظام من اليمين إلى اليسار.

## سلوك النقل

يوقف الاسم الموجود العملية دون استبدال. تُكتب التنزيلات مؤقتًا ويُتحقق من الحجم قبل الاسم النهائي؛ يتحقق الرفع من حجم Android. يحتفظ الإلغاء أو الفشل بالمكتمل وقد يترك ملفات جزئية على Android. تُنسخ المجلدات تكراريًا بعمق أقصى 128؛ تُرفض الروابط الرمزية والملفات الخاصة. يشمل التقدم ملفات وبايتات العملية بأكملها. المحتوى المكشوف عبر MTP فقط متاح؛ الحذف وإعادة التسمية والتركيب كوحدة Finder غير متوفرة.

## البناء والتحقق

يتطلب Swift 6.2+ وSDK macOS 26+ وlibmtp 1.1.23 وlibusb 1.0.30. يتحقق السكربت من الإصدارات وSHA-256 للمصادر ويضم المكتبات الديناميكية ومصادرها. يستثني أرشيف المصدر البناء والتشخيص الخاص. الأوامر أدناه تشخيصات للقراءة فقط، وليست CLI عامة للملفات أو MCP. يكتب `--verify-transfer` ملفات اختبار UUID: افصل GUI واستخدم جهاز اختبار مصرحًا به فقط وافحص البقايا المحتملة.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## التراخيص والمساهمة

الكود والسكربتات والوثائق: **MIT**. روبوت Android: **CC BY 3.0**. libmtp/libusb: **LGPL-2.1-or-later**. حافظ على التراخيص والإشعارات. Android علامة Google LLC وهذا ليس تطبيقًا رسميًا. MacAndFiles اسم تطوير؛ راجع العلامة وتوثيق Apple قبل النشر. README الإنجليزي هو المرجع التقني الكامل. اقرأ AGENT.md للمساهمة. لم ينشر هذا المسار على GitHub بعد.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## الطرفية والوكلاء

بعد تثبيت التطبيق، ثبّت `maf` باستخدام `scripts/install-cli.sh`. اعرض المعرّفات عبر `maf devices` و `maf storages --device "ID"`. راجع `maf help` و[دليل CLI](../CLI.md) لعرض الملفات ورفعها وتنزيلها وإنشاء المجلدات. النتائج بصيغة JSON، والأخطاء لها رموز وحالة خروج غير صفرية. افصل اتصال الجهاز في الواجهة قبل استخدام CLI.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

مُعدّ لـ macOS 14+ ومختبر على macOS 27.2؛ الإصدارات الأقدم تحتاج تحققًا فعليًا. Liquid Glass على macOS 26+.

عدد الملفات الكلي والمكتمل والتقدم العام ومتوسط السرعة والوقت المتبقي التقديري. تُحفظ الملفات المكتملة إذا توقف النقل.

ثبّت maf من المزيد ← الطرفية والوكلاء. أضف ~/.local/bin إلى PATH عند الحاجة. افصل GUI قبل عمليات CLI.

يستخدم maf محرك النقل نفسه: نتائج JSON ورموز أخطاء مستقرة وحالة USB واضحة للبرامج والوكلاء.

[MacAndFiles](https://macandfiles.pages.dev/ar/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
