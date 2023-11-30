⚠️Note: This is a translated version of the original [README.md](https://github.com/Atlas-OS/Atlas/blob/main/README.md), information here may not be accurate and can be outdated.
<h1 align="center">
  <a href="http://atlasos.net"><img src="https://github.com/Atlas-OS/branding/blob/main/github-banner.png" alt="Atlas" width="900" style="border-radius: 30px"></a>
</h1>
  <p align="center">
    <a href="https://github.com/Atlas-OS/Atlas/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/atlas-os/atlas?style=for-the-badge&logo=github&color=1A91FF"/>
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/graphs/contributors">
      <img alt="Contributors" src="https://img.shields.io/github/contributors/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases/latest">
      <img alt="Release" src="https://img.shields.io/github/release/atlas-os/atlas?style=for-the-badge&color=1A91FF" />
    </a>
    <a href="https://github.com/Atlas-OS/Atlas/releases">
      <img alt="Release Downloads" src="https://img.shields.io/github/downloads/Atlas-OS/Atlas/total?style=for-the-badge&logo=github&color=1A91FF" />
    </a>
  </p>
<h4 align="center">एक खुला और पारदर्शी ऑपरेटिंग सिस्टम, जो प्रदर्शन, गोपनीयता और स्थिरता को अनुकूलित करने के लिए डिजाइन किया गया है।</h4>

<p align="center">
  <a href="https://atlasos.net">वेबसाइट</a>
  •
  <a href="https://docs.atlasos.net">प्रलेखन</a>
  •
  <a href="https://discord.atlasos.net" target="_blank">डिस्कॉर्ड</a>
  •
  <a href="https://forum.atlasos.net">मंच</a>
</p>

## 🤔 **एटलस क्या है?**
एटलस विंडोज 10 का एक संशोधित संस्करण है, जो विंडोज के नकारात्मक पहलुओं को हटाता है जो गेमिंग प्रदर्शन को नकारात्मक रूप से प्रभावित करते हैं। 
हम एक अच्छा विकल्प भी हैं जो प्रणाली लैटेंसी, नेटवर्क लैटेंसी, इनपुट लैग और प्रदर्शन पर ध्यान केंद्रित करते हुए आपकी प्रणाली को निजी रखने में मदद करता है।
आप हमारी आधिकारिक [वेबसाइट](https://atlasos.net) पर एटलस के बारे में अधिक जान सकते हैं।

## 📚 **विषयसूची**

- [सहयोग दिशानिर्देशिका](https://docs.atlasos.net/contributions)

- शुरू करना
  - [स्थापना](https://docs.atlasos.net/getting-started/installation)
  - [अन्य स्थापना विधियाँ](https://docs.atlasos.net/getting-started/other-installation-methods/no-usb)
  - [स्थापना के बाद](https://docs.atlasos.net/getting-started/post-installation/drivers)

- त्रुटि समस्याओं का समाधान
  - [हटाई गई विशेषताएं](https://docs.atlasos.net/troubleshooting/removed-features)
  - [लिपियाँ](https://docs.atlasos.net/troubleshooting/scripts)

- आम पूछे जाने वाले प्रश्न
  - [एटलस](https://atlasos.net/faq)
  - [सामान्य समस्याएं](https://docs.atlasos.net/troubleshooting/common-issues/hyper-v/)

## 👀 **एटलस क्यों?**

### 🔒 और निजी
स्टॉक विंडोज में ट्रैकिंग सेवा होती है जो आपके डेटा को कलेक्ट करती है और उन्हें माइक्रोसॉफ्ट को अपलोड करती है। 
अटलस विंडोज के भीतर सभी प्रकार की ट्रैकिंग को हटाता है और डेटा कलेक्शन को कम करने के लिए कई ग्रुप पॉलिसी को लागू करता है।

(टिप्पणी। हम विंडोज़ के दायरे से बाहर की चीज़ों की सुरक्षा सुनिश्चित नहीं कर सकते, जैसे कि ब्राउज़र, तृतीय-पक्ष ऐप्स।)

### 🛡️ अधिक  सुरक्षित
इंटरनेट से एक संशोधित आईएसओ डाउनलोड करना जोखिम भरा होता है। इसमें खतरनाक लिपियाँ होने की संभावना होती है और इसमें नवीनतम सुरक्षा पैच न होने की वजह से आपके कंप्यूटर को गंभीर सुरक्षा खतरे के अंदर डाल सकता है। 

एटलस अलग है। हम यहां [AME विज़ार्ड](https://ameliorated.io/) का उपयोग करके एटलस स्थापित करने के लिए उपयोग करते हैं, और हमारे गिटहब रिपॉज़िटरी में हम सभी स्क्रिप्ट ओपन सोर्स का उपयोग करते हैं। आप आर्काइव के रूप में पैकेज किए गए एटलस प्लेबुक (.apbx - AME विज़ार्ड स्क्रिप्ट पैकेज) देख सकते हैं, जिसका पासवर्ड malte है (AME विज़ार्ड प्लेबुक के लिए मानक), जो केवल एंटीवायरस से गलत चिह्न द्वारा बाधा दूर करने के लिए है।

प्लेबुक में सम्मिलित केवल ओपन सोर्स लाइसेंस [GPLv3](https://github.com/Atlas-OS/Atlas-Utilities/blob/main/LICENSE) के तहत रिलीज़ होने वाले (कार्यान्वयन क्रियाएँ हैं)[https://github.com/Atlas-OS/Atlas-Utilities], जिनके हैश रिलीज़ के समान होते हैं। बाकी सभी टेक्स्ट रूप में है।

आप एटलस स्थापित करने से पहले नवीनतम सुरक्षा अपडेट्स भी स्थापित कर सकते हैं, जिसे हम सुरक्षित और सुरक्षित रखने की सलाह देते हैं।

कृपया ध्यान दें कि एटलस v0.2.0 के अनुसार, एटलस आमतौर पर विंडोज़ की तुलना में अधिक सुरक्षित नहीं है क्योंकि सुरक्षा सुविधाओं को हटा दिया गया/अक्षम कर दिया गया है, जैसे कि विंडोज़ डिफेंडर को हटा दिया गया है। हालांकि, एटलस v0.3.0 में इनमें से अधिकांश को वैकल्पिक सुविधाएँ के रूप में वापस जोड़ा जाएगा। अधिक जानकारी के लिए [यहां](https://docs.atlasos.net/troubleshooting/removed-features/) देखें।

### 🚀 अधिक संग्रहण स्थान
ऐटलस से पूर्व स्थापित एप्लिकेशन और अन्य अप्रत्यक्ष घटकों को हटाया जाता है। संगतता समस्याओं की संभावना होने के बावजूद, यह इंस्टॉल का आकार काफी कम करता है और आपके सिस्टम को और अधिक स्लीक बनाता है। इसलिए, विंडोज डिफेंडर जैसी विशेषताएं पूरी तरह से हटा दी गई हैं। हमारे [हटाई गई विशेषताएं](https://docs.atlasos.net/troubleshooting/removed-features) में देखें कि हमने क्या और हटाया है।

### ✅ अधिक प्रदर्शन
इंटरनेट पर कुछ ट्वीक्ड सिस्टमों को बहुत दूर ट्वीक कर दिया गया है, जिससे ब्लूटूथ, वाई-फाई जैसी मुख्य विशेषताओं के लिए संगतता टूट जाती है। 
ऐटलस मीठे स्थान पर है। अधिक प्रदर्शन प्राप्त करने के साथ-साथ एक अच्छी संगतता भी बनाए रखना।

विंडोज को बेहतर बनाने के लिए हमने जो कई बदलाव किए हैं, उनमें से कुछ को नीचे सूचीबद्ध किया गया है:
- अनुकूलित बिजली योजना
- सेवाओं और ड्राइवरों की कम मात्रा
- अक्षम ऑडियो अनन्य
- अक्षम अनावश्यक उपकरण
- अक्षम बिजली की बचत (व्यक्तिगत कंप्यूटरों के लिए)
- अक्षम प्रदर्शन-भूखी सुरक्षा शमन
- सभी उपकरणों पर स्वचालित रूप से एमएसआई मोड सक्षम किया गया।
-  बूट कॉन्फ़िगरेशन का अनुकूलन
- अनुकूलित प्रक्रिया समयबद्धन

### 🔒 कानूनी

बहुत सारे कस्टम विंडोज ओएसेस अपने सिस्टम को विंडोज के एक ट्वीक्ड आईएसओ के माध्यम से वितरित करते हैं। यह [माइक्रोसॉफ्ट की शर्तों](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) का उल्लंघन करता है और इंस्टॉल करने का एक सुरक्षित तरीका नहीं है।

अटलास ने उपयोगकर्ताओं को इंस्टॉल करने के लिए एक सुरक्षित और कानूनी तरीका प्रदान करने के लिए विंडोज अमेलिओरेटेड टीम के साथ भागीदारी की, जो [AME विज़ार्ड](https://ameliorated.io) के रूप में उपलब्ध है। इसका उपयोग करके, अटलास पूरी तरह से [माइक्रोसॉफ्ट की शर्तों](https://www.microsoft.com/en-us/Useterms/Retail/Windows/10/UseTerms_Retail_Windows_10_English.htm) का पालन करता है।

## 🎨 ब्रांड किट
क्या आप सृजनात्मक महसूस कर रहे हैं? कुछ मूल सृजनात्मक डिजाइन के साथ अपनी खुद की एटलस वॉलपेपर बनाना चाहते हैं? तो हमारे ब्रांड किट आपके लिए बना हुआ है!
एटलस ब्रांड किट सार्वजनिक रूप से उपलब्ध है, आप इसे [यहां](https://github.com/Atlas-OS/branding/archive/refs/heads/main.zip) डाउनलोड करके कुछ शानदार बना सकते हैं!

हमारे [मंच](https://forum.atlasos.net/t/art-showcase) पर हमारा एक विशेष क्षेत्र भी है, जिससे आप अन्य रचनात्मक जीनियस के साथ अपनी रचनाओं को साझा कर सकते हैं और शायद थोड़ी सी प्रेरणा उत्पन्न कर सकते हैं! आप यहां दूसरे उपयोगकर्ताओं द्वारा साझा की गई रचनात्मक वॉलपेपर भी खोज सकते हैं!

## ⚠️ Disclaimer (अस्वीकरण)
https://github.com/Atlas-OS/Atlas#%EF%B8%8F-disclaimer

## Translation contributors (Translation contributor in the translated language)
[Contributor A](https://github.com/A) |
[Contributor B](https://github.com/B) |
[Contributor C](https://github.com/C)
