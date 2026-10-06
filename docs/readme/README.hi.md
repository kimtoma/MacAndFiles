# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

Android और Apple Silicon Mac के बीच USB फ़ाइल ट्रांसफ़र के लिए मूल SwiftUI ऐप। न्यूनतम Finder जैसी UI, सिस्टम रंग, मूल खोज और Liquid Glass। यह Google Android File Transfer से अलग इंस्टॉल होता है।

## आवश्यकताएँ और इंस्टॉलेशन

**Apple Silicon / arm64 और macOS 14.0 या नया** आवश्यक है। macOS 27.2 और Galaxy Z Fold7 पर सत्यापित; macOS 28, Intel और अन्य डिवाइस सत्यापित नहीं हैं। बिल्ड के बाद `dist/MacAndFiles.app` चलाएँ या ZIP निकालकर ऐप Applications में रखें। libmtp/libusb शामिल हैं; चलाने के लिए Homebrew या Android Studio आवश्यक नहीं। यह ad-hoc हस्ताक्षरित विकास बिल्ड है; Developer ID और Apple notarization नहीं हुआ है।

## कनेक्ट और उपयोग

USB डेटा केबल से कनेक्ट करें, Android अनलॉक करें और “फ़ाइल ट्रांसफ़र / Android Auto” चुनें। Android File Transfer, उसका Agent और अन्य MTP ऐप बंद करें। डिवाइस खोजें, चुनें और कनेक्ट करें। USB डीबगिंग या ADB आवश्यक नहीं। फ़ोल्डर पर डबल-क्लिक करें; ⌘D Mac पर सहेजता है, ⌘U Android पर भेजता है; Finder फ़ाइलें भी छोड़ सकते हैं। ⌘↑ ऊपर जाता है, ⌘⇧N फ़ोल्डर बनाता है, ⌘R रीफ़्रेश करता है। ⌘F केवल वर्तमान फ़ोल्डर के नाम खोजता है; साफ़ करना या Esc सूची लौटाता है। खोज से छिपे आइटम का चयन हटता है। अधिक मेनू में सहायता, डिस्कनेक्ट और निदान हैं। लॉग साझा करने से पहले फ़ाइल नाम जाँचें।

## भाषाएँ

macOS की पसंदीदा भाषा और सिस्टम सेटिंग्स → सामान्य → भाषा और क्षेत्र की ऐप भाषा का पालन करता है। बदलाव के बाद ऐप फिर चलाएँ। 13 भाषाएँ शामिल हैं; अन्य के लिए अंग्रेज़ी है। तारीख़, आकार और प्रतिशत क्षेत्र सेटिंग्स का पालन करते हैं। फ़ाइल और डिवाइस नाम सुरक्षित रहते हैं; लाइब्रेरी निदान अंग्रेज़ी में रह सकता है।

## ट्रांसफ़र का व्यवहार

मौजूदा नाम पर कार्रवाई रुकती है, अधिलेखन नहीं होता। डाउनलोड अस्थायी फ़ाइल में लिखा जाता है, आकार जाँचकर अंतिम नाम दिया जाता है; अपलोड Android के बताए आकार को जाँचता है। रद्द करने या विफलता पर पूरी हुई फ़ाइलें रहती हैं और Android पर अधूरी फ़ाइलें रह सकती हैं। फ़ोल्डर 128 गहराई तक पुनरावर्ती कॉपी होते हैं; सिंबॉलिक लिंक और विशेष फ़ाइलें अस्वीकार हैं। प्रगति पूरी कार्रवाई की फ़ाइलों और बाइट्स के आधार पर दिखाई जाती है। केवल MTP में दिखने वाली सामग्री सुलभ है; हटाना, नाम बदलना और Finder वॉल्यूम माउंट उपलब्ध नहीं हैं।

## बिल्ड और सत्यापन

Swift 6.2+, macOS 26+ SDK, libmtp 1.1.23 और libusb 1.0.30 आवश्यक हैं। स्क्रिप्ट संस्करण और स्रोत SHA-256 जाँचती है तथा डायनेमिक लाइब्रेरी और स्रोत शामिल करती है। स्रोत संग्रह बिल्ड और निजी निदान को छोड़ता है। नीचे के कमांड केवल पढ़ने वाले निदान हैं, सामान्य फ़ाइल CLI या MCP नहीं। `--verify-transfer` UUID परीक्षण फ़ाइलें लिखता है: GUI डिस्कनेक्ट करें, केवल अधिकृत परीक्षण डिवाइस पर चलाएँ और बची फ़ाइलें जाँचें।

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

## लाइसेंस और योगदान

कोड, स्क्रिप्ट और दस्तावेज़: **MIT**। Android रोबोट: **CC BY 3.0**। libmtp/libusb: **LGPL-2.1-or-later**। लाइसेंस और नोटिस सुरक्षित रखें। Android, Google LLC का ट्रेडमार्क है; यह आधिकारिक ऐप नहीं। MacAndFiles विकास नाम है; प्रकाशित करने से पहले ब्रांड और notarization की आवश्यकताएँ जाँचें। पूरा तकनीकी संदर्भ अंग्रेज़ी README में है। योगदान के लिए AGENT.md पढ़ें। इस प्रक्रिया ने अभी GitHub पर प्रकाशन नहीं किया है।

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## टर्मिनल और एजेंट

ऐप इंस्टॉल करने के बाद `scripts/install-cli.sh` से `maf` इंस्टॉल करें। `maf devices` और `maf storages --device "ID"` से ID देखें। फ़ाइल सूची, अपलोड, डाउनलोड और फ़ोल्डर बनाने के लिए `maf help` तथा [CLI गाइड](../CLI.md) देखें। परिणाम JSON में मिलते हैं; विफलता पर त्रुटि कोड और गैर-शून्य निकास स्थिति मिलती है। CLI उपयोग से पहले GUI में डिवाइस डिस्कनेक्ट करें।

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

macOS 14+ के लिए बना। macOS 27.2 पर परीक्षण हुआ; पुराने संस्करणों पर वास्तविक डिवाइस जाँच बाकी है। Liquid Glass macOS 26+ पर।

कुल और पूरी फ़ाइलें, कुल प्रगति, औसत गति और अनुमानित शेष समय देखें। रुकने पर पूरी फ़ाइलें सुरक्षित रहती हैं।

अधिक → टर्मिनल और एजेंट से maf इंस्टॉल करें। ज़रूरत पर ~/.local/bin को PATH में जोड़ें। CLI फ़ाइल काम से पहले GUI डिस्कनेक्ट करें।

maf वही इंजन उपयोग करता है: JSON परिणाम, स्थिर त्रुटि कोड और स्पष्ट USB स्थिति, स्क्रिप्ट तथा एजेंटों के लिए।

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/hi/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
