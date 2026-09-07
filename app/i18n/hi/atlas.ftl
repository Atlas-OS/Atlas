### Atlas Manager: हिन्दी (Hindi), preview translation; revised on 6 September 2026 from the en-GB source. Native-speaker review pending.
###
### This complete translation follows the en-GB source.
### Ids are stable identifiers, never shown to users. Comments
### above a message say where it appears and what its variables hold.
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically; use plural selectors ({ $count -> [one] ... *[other] ... })
###   with your language's CLDR categories where the count changes the wording.
###   Hindi CLDR "one" also covers 0, so this catalog uses exact [1]/[2]
###   branches where the noun form changes and invariant nouns elsewhere.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "GitHub"
###   are product names. Windows feature names should match what Windows
###   shows in your language (for example the four Virus & threat protection
###   switches). The Windows Security app is "Windows सुरक्षा" in Hindi Windows.
### - Sentences end with the danda (।); titles, labels and buttons do not.
### - Buttons are short and end in the respectful imperative (करें, खोलें).
### - "Relaunch" (the Atlas Manager) is "दोबारा खोलें"; "restart" (the PC or
###   Windows) is "रीस्टार्ट करें". Keep the two apart.

## Shared

app-name = Atlas Manager
common-done = हो गया
common-cancel = रद्द करें
common-back = वापस
common-next = जारी रखें
common-dismiss = बंद करें
# Link beside a summary row that jumps back to change that choice.
common-change = बदलें
common-copy = कॉपी करें
# Shown where a list of options is empty.
common-none = कोई नहीं
# Accessible description of a disabled control.
common-not-available = अभी उपलब्ध नहीं है
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = होम पर वापस जाएँ
# Accessible name of the gear button in the title bar.
common-settings = सेटिंग्स
common-close-settings = सेटिंग्स बंद करें
common-open-windows-security = Windows सुरक्षा खोलें
common-restart-as-administrator = व्यवस्थापक के रूप में दोबारा खोलें
common-try-again = फिर कोशिश करें
common-read-the-docs = Atlas गाइड पढ़ें
common-show-details = विवरण दिखाएँ
common-hide-details = विवरण छिपाएँ
common-open-log-file = लॉग फ़ाइल खोलें
# Accessible name of the Copy button beside the install log.
common-copy-install-log = इंस्टॉलेशन लॉग कॉपी करें
common-install-log = इंस्टॉलेशन लॉग
# Row labels in summary cards.
common-windows = Windows
common-options = विकल्प
common-package = इंस्टॉलेशन फ़ाइलें
common-installed-as = इंस्टॉलेशन का प्रकार
common-installed = इंस्टॉल किया गया
common-checking = जाँच हो रही है
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } या { $b }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Atlas इंस्टॉल हो रहा है, विंडो बंद करें?
window-close-message = इंस्टॉलेशन बैकग्राउंड में जारी रहेगा। प्रगति और नतीजा देखने के लिए Atlas दोबारा खोलें। इंस्टॉलेशन पूरा होने तक अपना PC चालू रखें।
window-close-keep = खुला रखें
window-close-close = विंडो बंद करें
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Atlas प्लेबुक (.apbx) खोलें
# Message Windows shows in its restart notification.
shutdown-comment = Atlas इंस्टॉल हो गया है। सेटअप पूरा करने के लिए Windows रीस्टार्ट हो रहा है।

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (बिल्ड { $build })

## Home page

home-not-installed = Atlas में आपका स्वागत है
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = { $date } को इंस्टॉल किया गया
home-status-checking = अपडेट की जाँच हो रही है
home-status-offline = अपडेट की जाँच नहीं हो सकी
home-status-not-checked = अपडेट की जाँच अभी नहीं हुई है
home-status-update = Atlas { $version } उपलब्ध है
home-status-up-to-date = नवीनतम संस्करण इंस्टॉल है
home-status-newest = नवीनतम संस्करण: Atlas { $version }
home-check-again = दोबारा जाँचें
# Primary button while an install is running or waiting.
home-show-install = प्रगति देखें
home-continue-installing = सेटअप जारी रखें
home-update-to = Atlas { $version } पर अपडेट करें
home-reinstall = Atlas दोबारा इंस्टॉल करें
home-install = Atlas इंस्टॉल करें
home-start-over = नए सिरे से शुरू करें
home-security-reminder-title = सुरक्षा स्विच फिर से चालू करें
home-security-reminder-message = अभी कोई इंस्टॉलेशन नहीं चल रहा है। Windows सुरक्षा खोलें और छेड़छाड़ से सुरक्षा, रीयल-टाइम सुरक्षा, क्लाउड-आधारित सुरक्षा और स्वचालित नमूना सबमिशन चालू करें।
home-elevation-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
home-state-error-title = आपके Atlas इंस्टॉलेशन का विवरण नहीं पढ़ा जा सका
home-whats-new = Atlas { $version } में नया क्या है
home-view-release = GitHub पर रिलीज़ नोट्स देखें
home-released = { $date } को रिलीज़ किया गया
home-show-less = कम दिखाएँ
home-show-full-notes = पूरे रिलीज़ नोट्स दिखाएँ
home-your-install = आपका Atlas सेटअप
# Row label: how Atlas was set up.
home-set-up = सेटअप का तरीका
home-set-up-during-oobe = Windows सेटअप के दौरान
home-history = इंस्टॉलेशन इतिहास
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = चलिए, आपके PC को Atlas के लिए तैयार करें
home-step-1-title = अपना PC जाँचें
home-step-1-detail = Atlas, Windows की जाँच करता है और इंस्टॉलेशन फ़ाइलें डाउनलोड करता है। आपकी Windows सेटिंग्स जैसी हैं, वैसी ही रहती हैं।
home-step-2-title = अपनी पसंद चुनें
home-step-2-detail = तय करें कि Windows में सुरक्षा और अपडेट कैसे काम करें, फिर अपनी पसंद के अतिरिक्त ऐप या सेटिंग्स चुनें।
home-step-3-title = एंटीवायरस सुरक्षा कुछ समय के लिए रोकें
home-step-3-detail = Atlas आपको Windows सुरक्षा के चार स्विच बंद करने में मदद करता है, ताकि वे इंस्टॉलेशन में रुकावट न डालें।
home-step-4-title = इंस्टॉल करें और रीस्टार्ट करें
home-step-4-detail = लगभग { $minutes } मिनट।
# Accessible name of a numbered step.
home-step-a11y = चरण { $number }: { $title }
home-github = GitHub पर Atlas देखें
home-discord = Discord पर Atlas समुदाय से जुड़ें
home-report-problem = GitHub पर समस्या रिपोर्ट करें

## How an install was done (from the state document)

mode-fresh = पहला इंस्टॉलेशन
mode-upgrade = पुराने संस्करण से अपडेट
mode-reapply = उसी संस्करण का दोबारा इंस्टॉलेशन
mode-unknown = इंस्टॉलेशन
# Lower-case forms used inside a history row.
history-mode-fresh = पहला इंस्टॉलेशन
history-mode-upgrade = अपडेट
history-mode-reapply = दोबारा इंस्टॉलेशन
history-mode-unknown = इंस्टॉलेशन

## Notices on the Home page

notice-settings-reset-title = Atlas डिफ़ॉल्ट ऐप सेटिंग्स इस्तेमाल कर रहा है
# $error is a raw error message (text).
notice-settings-unreadable = Atlas आपकी सहेजी गई ऐप सेटिंग्स नहीं पढ़ सका। आपकी Windows सेटिंग्स नहीं बदली हैं। विवरण: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = आपकी ऐप सेटिंग्स फ़ाइल ख़राब थी, इसलिए उसे रीसेट कर दिया गया है। पुरानी फ़ाइल की एक कॉपी { $file } नाम से सहेजी गई है। विवरण: { $error }
notice-settings-damaged = आपकी ऐप सेटिंग्स फ़ाइल ख़राब थी। Atlas फ़िलहाल डिफ़ॉल्ट सेटिंग्स इस्तेमाल कर रहा है। विवरण: { $error }
notice-settings-not-saved-title = ऐप सेटिंग्स सहेजी नहीं जा सकीं
notice-session-unreadable-title = पिछले इंस्टॉलेशन की जाँच नहीं हो सकी
# $path is a file path (text).
notice-session-unreadable-message = Atlas { $path } नहीं पढ़ सका, और उसे यह जानना ज़रूरी है कि कोई इंस्टॉलेशन अभी भी चल रहा है या नहीं। अगर आप निश्चित नहीं हैं, तो यह फ़ाइल हटाने से पहले Atlas समुदाय से मदद लें। इसे तभी हटाएँ और फिर कोशिश करें, जब आपने पक्का कर लिया हो कि कोई इंस्टॉलेशन नहीं चल रहा है। विवरण: { $error }

## Administrator elevation

elevation-declined = अनुमति नहीं मिली। फिर कोशिश करें, और जब Windows पूछे कि Atlas को बदलाव करने दें या नहीं, तो “हाँ” चुनें।
elevation-declined-continue = अनुमति नहीं मिली। फिर कोशिश करें, और जब Windows पूछे कि Atlas को बदलाव करने दें या नहीं, तो “हाँ” चुनें। आपके सेटअप विकल्प सहेज लिए गए हैं।
elevation-draft-not-saved = Atlas आपके सेटअप विकल्प सहेज नहीं सका, इसलिए वह दोबारा नहीं खुला। फिर कोशिश करें। विवरण: { $error }

## The install flow

step-ready = तैयारी
step-options = आपके विकल्प
step-security = Windows सुरक्षा
step-install = इंस्टॉल
install-title = Atlas सेटअप
# Accessible name of the row of steps.
stepper-label = Atlas सेटअप के चरण
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = { $total } में से चरण { $number }, { $title }, { $status }
stepper-status-completed = पूरा हुआ
stepper-status-current = मौजूदा चरण
stepper-status-upcoming = आगे का चरण
# Heading above each step's content.
step-heading = { $total } में से चरण { $number }: { $title }

## Step 1: Get ready

ready-banner-busy-title = आपका PC तैयार हो रहा है
ready-banner-busy-message = Atlas आपके PC की जाँच कर रहा है और इंस्टॉलेशन फ़ाइलें तैयार कर रहा है।
ready-banner-blocked-title = आपके PC को थोड़ी तैयारी की ज़रूरत है
ready-banner-blocked-message = नीचे दिए निर्देश पूरे करें, फिर “दोबारा जाँचें” चुनें।
ready-banner-no-package-title = जारी रखने के लिए Atlas डाउनलोड करें
ready-banner-no-package-message = नीचे से नवीनतम संस्करण डाउनलोड करें, या सहेजी हुई Atlas प्लेबुक (.apbx) खोलें।
ready-banner-warnings-title = कुछ बातों पर ध्यान दें
ready-banner-warnings-message = नीचे दिए नोट पढ़ें और जारी रखने से पहले सुझाए गए कदम उठाएँ।
ready-banner-ok-title = अब आप अपनी सेटिंग्स चुन सकते हैं
ready-banner-ok-message = सभी जाँचें सफल रहीं और आपकी इंस्टॉलेशन फ़ाइलें तैयार हैं।

# Card title and accessible name of the list of checks.
ready-this-pc = PC की जाँच
ready-check-again = दोबारा जाँचें

package-title = इंस्टॉलेशन फ़ाइलें
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } डाउनलोड हो रहा है · { $total } में से { $received } MB
package-unpacking-progress =
    { $total ->
        [1] फ़ाइल निकाली जा रही है · { $total } में से { $done } फ़ाइल
       *[other] फ़ाइलें निकाली जा रही हैं · { $total } में से { $done } फ़ाइलें
    }
package-unpacking = फ़ाइलें निकाली जा रही हैं
package-looking = Atlas के नवीनतम संस्करण की जाँच हो रही है।
package-none = अभी कोई इंस्टॉलेशन फ़ाइल नहीं है। प्लेबुक (.apbx) में वे निर्देश और फ़ाइलें होती हैं, जो Atlas को चाहिए।
# Short status words beside the card title.
package-status-downloading = डाउनलोड हो रही हैं
package-status-unpacking = निकाली जा रही हैं
package-status-failed = फ़ाइलें तैयार नहीं हो सकीं
package-status-ready = तैयार
package-status-checking = जाँच हो रही है
package-status-missing = डाउनलोड नहीं हुई हैं
# Accessible name of the progress bar.
package-progress = इंस्टॉलेशन फ़ाइलों की प्रगति
package-download-again = दोबारा डाउनलोड करें
package-download-version = Atlas { $version } डाउनलोड करें
package-download-newest = नवीनतम संस्करण डाउनलोड करें
package-open-file = प्लेबुक फ़ाइल खोलें
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } GitHub से डाउनलोड हो गया है और इंस्टॉल के लिए तैयार है।
package-from-file = Atlas { $version }, { $file } से लोड हो गया है और इंस्टॉल के लिए तैयार है।
package-unpacked = Atlas { $version } इंस्टॉल के लिए तैयार है।
package-at = इंस्टॉलेशन फ़ाइलें: { $path }
package-none-yet = कोई इंस्टॉलेशन फ़ाइल नहीं चुनी गई
acquire-no-asset = Atlas { $version } के लिए डाउनलोड करने योग्य कोई प्लेबुक फ़ाइल नहीं है। जारी रखने के लिए सहेजी हुई Atlas प्लेबुक (.apbx) खोलें।
acquire-unsupported = यह ऐप Atlas 0.6.0 और उसके बाद के संस्करण इंस्टॉल कर सकता है। Atlas { $version } इंस्टॉल करने के लिए इसकी जगह AME Wizard इस्तेमाल करें।
acquire-failed = इंस्टॉलेशन फ़ाइलें तैयार नहीं हो सकीं। दोबारा डाउनलोड करें या कोई दूसरी Atlas प्लेबुक (.apbx) खोलें। विवरण: { $error }

## System checks

check-administrator = इंस्टॉल करने की अनुमति
check-supported-build = Windows संगतता
check-pending-updates = Windows अपडेट
check-pending-reboot = लंबित रीस्टार्ट
check-third-party-antivirus = अन्य एंटीवायरस सॉफ़्टवेयर
check-internet = इंटरनेट कनेक्शन
check-power = पावर सप्लाई
check-activation = Windows सक्रियण
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = जाँच हो रही है
check-state-passed = ठीक है
check-state-warning = ध्यान देने की ज़रूरत है
check-state-failed-blocking = इंस्टॉल करने से पहले कार्रवाई ज़रूरी है
check-state-failed = ध्यान देने की ज़रूरत है
check-state-unknown = जाँच नहीं हो सकी
check-fix-windows-update = Windows Update खोलें
check-fix-network = नेटवर्क सेटिंग्स खोलें
check-fix-power = पावर सेटिंग्स खोलें
check-fix-activation = सक्रियण सेटिंग्स खोलें
# Check boxes the user ticks when a check could not run.
check-ack-updates = मैंने Windows Update देख लिया है और कोई अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है
check-ack-reboot = मैंने Windows रीस्टार्ट कर लिया है और अब किसी और रीस्टार्ट की ज़रूरत नहीं है
check-ack-internet = यह PC इंटरनेट से जुड़ा है
check-ack-generic = मैंने यह आवश्यकता ख़ुद जाँच ली है

detail-admin-ok = Atlas को इंस्टॉलेशन के लिए ज़रूरी बदलाव करने की अनुमति है।
detail-admin-missing = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, फिर जब Windows अनुमति माँगे, तो “हाँ” चुनें।
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas के इस संस्करण के लिए Windows बिल्ड { $builds } ज़रूरी है। आपके PC पर बिल्ड { $build } है। जारी रखने से पहले समर्थित Windows संस्करण इंस्टॉल करें।
detail-updates-none = कोई Windows अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है।
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] पहले यह अपडेट इंस्टॉल करें: { $titles }।
        [2] पहले ये अपडेट इंस्टॉल करें: { $titles }।
       *[other] पहले { $count } अपडेट इंस्टॉल करें, जिनमें { $titles } शामिल हैं।
    }
detail-updates-unknown = अपडेट की जाँच नहीं हो सकी। Windows Update खोलें, और अगर कोई अपडेट प्रतीक्षा में नहीं है, तो नीचे पुष्टि करें। ({ $error })
detail-reboot-none = Windows को अभी रीस्टार्ट की ज़रूरत नहीं है।
detail-reboot-pending = पहले किए गए बदलाव पूरे करने के लिए अपना PC रीस्टार्ट करें, फिर Atlas दोबारा खोलकर फिर से जाँचें।
detail-reboot-unknown = यह जाँच नहीं हो सकी कि Windows को रीस्टार्ट की ज़रूरत है या नहीं। अपना PC रीस्टार्ट करें, फिर Atlas दोबारा खोलकर फिर से जाँचें। ({ $error })
detail-antivirus-none = कोई दूसरा एंटीवायरस सॉफ़्टवेयर नहीं मिला।
# $products is a list of product names (text).
detail-antivirus-found = यह एंटीवायरस सॉफ़्टवेयर इंस्टॉलेशन रोक सकता है: { $products }। जारी रखने से पहले इसे अनइंस्टॉल करें।
detail-antivirus-unknown = अन्य एंटीवायरस सॉफ़्टवेयर की जाँच नहीं हो सकी। जारी रखने से पहले अपने इंस्टॉल किए गए ऐप देख लें। ({ $error })
detail-internet-ok = आप इंटरनेट से जुड़े हैं। जब तक Atlas सॉफ़्टवेयर डाउनलोड और इंस्टॉल करता है, यह कनेक्शन बनाए रखें।
detail-internet-missing = इंटरनेट से कनेक्ट करें, फिर दोबारा जाँचें।
detail-power-mains = आपका PC प्लग इन है। इंस्टॉलेशन पूरा होने तक इसे प्लग इन रखें।
detail-power-battery = अपने PC को प्लग इन करें, ताकि वह पूरे इंस्टॉलेशन के दौरान चालू रहे।
detail-power-unknown = पावर सप्लाई की जाँच नहीं हो सकी। अगर आप लैपटॉप इस्तेमाल कर रहे हैं, तो जारी रखने से पहले उसे प्लग इन करें।
detail-activation-ok = Windows सक्रिय है। Atlas इसे नहीं बदलेगा।
detail-activation-missing = Windows सक्रिय नहीं है। आप जारी रख सकते हैं, लेकिन Atlas आपके लिए Windows सक्रिय नहीं करेगा।
detail-activation-no-licence = Windows ने कोई लाइसेंस नहीं बताया। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा।
detail-activation-unknown = Windows सक्रियण की जाँच नहीं हो सकी। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा। ({ $error })

## Step 2: Options

options-progress = { $total } में से पसंद { $number }
options-progress-extras = { $total } में से पसंद { $number }: अतिरिक्त विकल्प
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = एंटीवायरस सुरक्षा चालू रखें?
screen-mitigations-title = प्रोसेसर सुरक्षा
screen-mitigations-question = Windows की प्रोसेसर सुरक्षा बनाए रखें?
screen-updates-title = Windows Update
screen-updates-question = Windows अपडेट कैसे इंस्टॉल करे?
screen-browser-title = ब्राउज़र
screen-power-title = पावर और सुरक्षा
screen-apps-title = ऐप्स
screen-toolbox-title = Atlas Toolbox
screen-choose-one-title = एक विकल्प चुनें
screen-extras-title = अतिरिक्त विकल्प
screen-extras-question = अपनी पसंद के अतिरिक्त विकल्प चुनें
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } के लिए एक विकल्प चुनें
learn-more-defender = Microsoft Defender के बारे में और जानें
learn-more-mitigations = प्रोसेसर सुरक्षा के बारे में पढ़ें
learn-more-updates = Windows Update के बारे में और जानें
learn-more-browser = ब्राउज़र के बारे में और जानें
learn-more-power = पावर और सुरक्षा के बारे में और जानें
learn-more-apps = ऐप्स के बारे में और जानें
learn-more-toolbox = Atlas Toolbox के बारे में और जानें
learn-more-generic = सेटअप गाइड पढ़ें
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Windows का अपना एंटीवायरस चालू रहता है, जो आपके PC को वायरस और अन्य ख़तरों से बचाने में मदद करता है।
consequence-defender-disable = Microsoft Defender को हटा देता है। जब तक आप कोई दूसरा एंटीवायरस ऐप इंस्टॉल नहीं करते, आपके PC पर एंटीवायरस सुरक्षा नहीं रहेगी।
consequence-mitigations-default = आपके प्रोसेसर के काम करने के तरीके का फ़ायदा उठाने वाले हमलों से Windows की डिफ़ॉल्ट सुरक्षा बनी रहती है।
consequence-mitigations-disable = इन सुरक्षा उपायों को बंद कर देता है, जिससे सुरक्षा कम हो जाती है। प्रदर्शन आपके प्रोसेसर पर निर्भर करता है और ख़राब भी हो सकता है।
consequence-auto-updates-disable = आपको Windows Update खोलकर अपडेट ख़ुद इंस्टॉल करने होंगे। अपडेट की सूचनाएँ चालू रहेंगी।
consequence-auto-updates-default = Windows अपडेट अपने-आप इंस्टॉल करेगा, जिनमें सुरक्षा सुधार भी शामिल हैं।

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender रखें (सुझाया गया)
playbook-option-defender-disable = Microsoft Defender हटाएँ
playbook-option-mitigations-default = डिफ़ॉल्ट सुरक्षा बनाए रखें (सुझाया गया)
playbook-option-mitigations-disable = प्रोसेसर सुरक्षा बंद करें
playbook-option-auto-updates-disable = अपडेट मुझे ख़ुद इंस्टॉल करने दें
playbook-option-auto-updates-default = अपडेट अपने-आप इंस्टॉल करें
playbook-option-disable-hibernation = हाइबरनेशन बंद करें
playbook-option-disable-power-saving = पावर सेविंग बंद करें
playbook-option-disable-core-isolation = वर्चुअलाइज़ेशन-आधारित सुरक्षा (VBS) बंद करें
playbook-option-remove-snipping-tool = Snipping Tool हटाएँ
playbook-option-uninstall-edge = Microsoft Edge हटाएँ
playbook-option-install-another-browser = कोई ब्राउज़र इंस्टॉल करें
playbook-option-install-toolbox = Atlas Toolbox इंस्टॉल करें
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender, Windows का अपना एंटीवायरस है। इसे रखने का सुझाव दिया जाता है। इसे तभी हटाएँ, जब आप जोखिम समझते हों और कोई दूसरा एंटीवायरस ऐप इस्तेमाल करने की योजना हो।
playbook-page-mitigations-default-description = ये सुरक्षा उपाय, जिन्हें security mitigations भी कहा जाता है, प्रोसेसर की कमज़ोरियों से बचाव में मदद करते हैं। Windows की डिफ़ॉल्ट सेटिंग बनाए रखने का सुझाव दिया जाता है।
playbook-page-auto-updates-disable-description = Windows अपडेट में सुरक्षा सुधार शामिल होते हैं। आप चाहें तो Windows इन्हें अपने-आप इंस्टॉल करे, या आप इन्हें ख़ुद इंस्टॉल करें।
playbook-page-install-toolbox-description = अपनी Atlas सेटिंग्स सँभालने में मदद के लिए Atlas Toolbox जोड़ें। Toolbox अभी बीटा में है, इसलिए कुछ सुविधाएँ अधूरी हो सकती हैं।
playbook-page-browser-brave-description = इंस्टॉल करने के लिए कोई ब्राउज़र चुनें। Atlas आपकी ब्राउज़र सेटिंग्स नहीं बदलेगा।

## Step 3: Windows Security

security-banner-reading-title = Windows सुरक्षा की जाँच हो रही है
security-banner-reading-message = Atlas नीचे दिए चार सुरक्षा स्विच की जाँच कर रहा है।
security-banner-off-title = चारों सुरक्षा स्विच बंद हैं
security-banner-off-message = अब आप इंस्टॉल करने से पहले अपने विकल्प देख सकते हैं।
security-banner-readable-off-title = जिन स्विच की जाँच Atlas कर सका, वे बंद हैं
security-banner-readable-off-message = बाकी स्विच Windows सुरक्षा में जाँचें।
security-banner-on-title = एंटीवायरस सुरक्षा कुछ समय के लिए बंद करें
security-banner-on-message = ये सुरक्षा सुविधाएँ उन बदलावों को रोक सकती हैं, जो Atlas को करने हैं।
# The page name in Windows Security.
security-list-title = वायरस और ख़तरे से सुरक्षा सेटिंग्स
security-switch-off = बंद
security-switch-on = चालू
security-switch-unreadable = जाँच नहीं हो सकी
security-switch-reading = जाँच हो रही है
security-all-off = सभी बंद
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 can't be read".
security-count-still-on = { $count } अभी भी चालू
security-count-unreadable = { $count } की जाँच नहीं हो सकी
security-count-join = { $a }, { $b }
security-unknown-title = बाकी स्विच की पुष्टि करें
security-unknown-message = Windows सुरक्षा में यह देख लेने के बाद कि चारों स्विच बंद हैं, नीचे पुष्टि करें।
security-acknowledge = मैंने Windows सुरक्षा में देख लिया है और चारों स्विच बंद हैं
security-unknown-unelevated-title = सुरक्षा जाँचने के लिए Atlas को अनुमति चाहिए
security-unknown-unelevated-message = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, ताकि वह Microsoft Defender की सेटिंग्स जाँच सके।
# The four switches, named as Windows Security names them.
protection-tamper = छेड़छाड़ से सुरक्षा
protection-tamper-why = इसे सबसे पहले बंद करें, ताकि Defender अपनी सुरक्षा सेटिंग्स में बदलाव की अनुमति दे।
protection-realtime = रीयल-टाइम सुरक्षा
protection-realtime-why = फ़ाइल स्कैनिंग रोकें, ताकि Defender, Atlas की इंस्टॉलेशन फ़ाइलों को ब्लॉक न करे।
protection-cloud = क्लाउड-आधारित सुरक्षा
protection-cloud-why = ऑनलाइन ख़तरों की वह जाँच रोकें, जो Atlas की इंस्टॉलेशन फ़ाइलों को ब्लॉक कर सकती है।
protection-samples = स्वचालित नमूना सबमिशन
protection-samples-why = Defender को Atlas की फ़ाइलें विश्लेषण के लिए अपने-आप Microsoft को भेजने से रोकें।

## Step 4: Install

install-preparing-title = इंस्टॉलेशन से पहले एक आख़िरी जाँच
install-preparing-message = बदलाव करने से पहले Atlas आपके PC और सुरक्षा सेटिंग्स की एक बार फिर जाँच कर रहा है।
install-installing = इंस्टॉल हो रहा है
install-running = चल रहा है
# Accessible name of the progress bar.
install-progress = इंस्टॉलेशन की प्रगति
phase-preflight = आपके PC की जाँच और फ़ाइलों की तैयारी हो रही है
phase-staging = इंस्टॉलेशन फ़ाइलें तैयार हो रही हैं
phase-applying = Windows में बदलाव किए जा रहे हैं। PC चालू रखें।
phase-done = सेटअप पूरा हो रहा है
outcome-succeeded-title = Atlas इंस्टॉल हो गया है
outcome-lost-title = इंस्टॉलेशन के नतीजे की पुष्टि नहीं हो सकी
outcome-failed-title = इंस्टॉलेशन पूरा नहीं हुआ
outcome-succeeded = Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
outcome-requirements = आपका PC इंस्टॉलेशन की आवश्यकताएँ पूरी नहीं करता। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। तैयारी पर वापस जाकर जाँच दोबारा चलाएँ।
outcome-not-elevated = इंस्टॉलेशन से कोई बदलाव नहीं हुआ। Atlas को व्यवस्थापक के रूप में दोबारा खोलें और फिर कोशिश करें।
outcome-failed-preflight = कोई भी बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। क्या हुआ, यह देखने के लिए लॉग फ़ाइल खोलें, फिर कोशिश करें।
outcome-failed-staging = फ़ाइलें तैयार करते समय, Windows में कोई बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। क्या हुआ, यह देखने के लिए लॉग फ़ाइल खोलें, फिर कोशिश करें।
outcome-failed-applying = कुछ बदलाव पहले ही हो चुके हो सकते हैं। अगर आप यहीं रुकना चाहते हैं, तो Windows सुरक्षा में वे सुरक्षा स्विच फिर चालू करें, जो आपने बंद किए थे (अगर वे अभी भी उपलब्ध हों)।
outcome-not-started = इंस्टॉलर समय पर शुरू नहीं हुआ। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। “फिर कोशिश करें” चुनें।
outcome-lost = इंस्टॉलर बिना नतीजा बताए रुक गया, और कुछ बदलाव पहले ही हो चुके हो सकते हैं। क्या हुआ, यह देखने के लिए लॉग फ़ाइल खोलें, फिर जहाँ इंस्टॉलेशन रुका था वहीं से आगे बढ़ाने के लिए “फिर कोशिश करें” चुनें।
restart-now-message = Atlas का सेटअप पूरा करने के लिए Windows रीस्टार्ट हो रहा है।
restart-countdown = Windows { $seconds } सेकंड में रीस्टार्ट होगा, ताकि Atlas का सेटअप पूरा हो सके।
restart-stopped = स्वचालित रीस्टार्ट रद्द कर दिया गया है। अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
restart-needed = अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए Windows रीस्टार्ट करें।
restart-dont-now = बाद में रीस्टार्ट करें
restart-now = अभी रीस्टार्ट करें
# Accessible name of the countdown bar.
restart-progress = रीस्टार्ट होने में बाकी समय
restart-start-failed = Windows रीस्टार्ट नहीं हो सका। अपना काम सहेजें, फिर स्टार्ट मेनू से रीस्टार्ट करें। विवरण: { $error }
preflight-title = इंस्टॉलेशन शुरू नहीं हुआ
preflight-invalid-options = Atlas इन सेटअप विकल्पों का इस्तेमाल नहीं कर सका। “आपके विकल्प” पर वापस जाकर उन्हें देखें, फिर कोशिश करें। विवरण: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = पिछली जाँच के बाद आपके PC की स्थिति बदल गई है। फिर कोशिश करने से पहले इन्हें ठीक करें। { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Windows सुरक्षा: { $summary }।
preflight-busy = Atlas की एक और विंडो इंस्टॉलेशन शुरू कर रही है। थोड़ा इंतज़ार करें, फिर कोशिश करें।
preflight-record-unreadable = Atlas यह जाँच नहीं सका कि पिछला इंस्टॉलेशन अभी भी चल रहा है या नहीं, इसलिए उसने नया इंस्टॉलेशन शुरू नहीं किया। रिकवरी के निर्देशों के लिए Atlas बंद करके दोबारा खोलें। विवरण: { $error }
preflight-refused = इंस्टॉलर शुरू नहीं हो सका। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। विवरण: { $error }
go-to-ready = तैयारी पर वापस जाएँ
go-to-options = “आपके विकल्प” पर वापस जाएँ
output-problem-title = इंस्टॉलेशन की प्रगति नहीं पढ़ी जा सकी
output-problem-message = Atlas लॉग नहीं पढ़ सका। इसका मतलब यह नहीं कि इंस्टॉलेशन रुक गया है। अपना PC चालू रखें और लॉग फ़ाइल खोलकर देखें। विवरण: { $error }
install-elevate-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
install-no-package-title = पहले अपनी इंस्टॉलेशन फ़ाइलें चुनें
install-no-package-message = Atlas डाउनलोड करने या सहेजी हुई प्लेबुक (.apbx) खोलने के लिए तैयारी पर वापस जाएँ।
install-security-title = इंस्टॉल करने से पहले एंटीवायरस सुरक्षा जाँचें
install-security-reading = चारों सुरक्षा स्विच की फिर से जाँच हो रही है।
install-security-message = { $summary }। Windows सुरक्षा खोलें और जारी रखने से पहले पक्का करें कि चारों स्विच बंद हैं।
summary-this-install = इंस्टॉलेशन का सारांश
summary-try-again = फिर कोशिश करने से पहले देख लें
summary-ready = अपना Atlas सेटअप देख लें
summary-activation = सक्रियण
summary-activation-ok = सक्रिय है। Atlas इसे नहीं बदलेगा।
summary-activation-missing = सक्रिय नहीं है। आप जारी रख सकते हैं, लेकिन Atlas, Windows को सक्रिय नहीं करेगा।
summary-activation-unknown = Atlas आपकी Windows सक्रियण स्थिति नहीं बदलेगा।
summary-duration = अनुमानित समय
summary-duration-value = { $minutes } मिनट, फिर एक रीस्टार्ट
summary-restart-checkbox = इंस्टॉलेशन के बाद मेरा PC अपने-आप रीस्टार्ट करें
summary-show-command = इंस्टॉलेशन कमांड दिखाएँ
summary-hide-command = इंस्टॉलेशन कमांड छिपाएँ
summary-command-unavailable = इंस्टॉलेशन कमांड तैयार नहीं हो सकी। विवरण: { $error }
summary-not-chosen = अभी कोई विकल्प नहीं चुना गया
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } बदलें
footer-still-checking = इंस्टॉलेशन की तैयारी हो रही है
footer-fix-items = जारी रखने के लिए ऊपर दी गई जाँच पूरी करें
footer-need-package = जारी रखने के लिए Atlas डाउनलोड करें या प्लेबुक खोलें
footer-reading-security = सुरक्षा स्विच की जाँच हो रही है
button-checking = जाँच हो रही है
button-installing = इंस्टॉल हो रहा है
button-install = Atlas इंस्टॉल करें
log-earlier-lines =
    { $count ->
        [1] { $count } पिछली पंक्ति लॉग फ़ाइल में है।
       *[other] { $count } पिछली पंक्तियाँ लॉग फ़ाइल में हैं।
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (पूरा लॉग: { $path })

## The installing view

installing-checking-title = एक आख़िरी जाँच
installing-checking-line = बदलाव करने से पहले Atlas आपके PC की जाँच कर रहा है। इसमें थोड़ा समय लग सकता है।
installing-title = Atlas इंस्टॉल हो रहा है
installing-phase-preflight = आपके PC की जाँच और इंस्टॉलेशन फ़ाइलों की तैयारी हो रही है।
installing-phase-staging = इंस्टॉलेशन फ़ाइलें तैयार की जा रही हैं। PC चालू रखें।
installing-phase-applying = आपके विकल्पों के अनुसार Windows में बदलाव किए जा रहे हैं। PC चालू और प्लग इन रखें।
installing-phase-done = इंस्टॉलेशन पूरा हो रहा है। PC चालू रखें।
installing-installed-title = Atlas इंस्टॉल हो गया है
# $time is a formatted clock time.
installing-started-just-now = { $time } पर शुरू हुआ, एक मिनट से भी कम समय पहले
installing-started-minutes = { $time } पर शुरू हुआ, { $minutes } मिनट पहले

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } इंस्टॉल हो गया है
installed-title = Atlas इंस्टॉल हो गया है
installed-ready = सब हो गया। आपका PC अब Atlas के साथ इस्तेमाल के लिए तैयार है।
installed-open-atlas = अपना Atlas सेटअप देखें

## Settings

settings-title = सेटिंग्स
settings-theme = ऐप थीम
settings-theme-system = Windows के अनुसार
settings-theme-light = हल्की
settings-theme-dark = गहरी
settings-theme-contrast-note = Atlas आपकी Windows कंट्रास्ट थीम के रंग इस्तेमाल कर रहा है।
settings-theme-mica-note = पारदर्शी बैकग्राउंड दिखाने के लिए वही हल्की या गहरी थीम चुनें, जो Windows में चुनी है।
settings-language = भाषा
settings-language-system = Windows के अनुसार
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Windows के अनुसार: { $language }
# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = पूर्वावलोकन · भाषा की समीक्षा बाकी है
preview-notice = { $language } एक पूर्वावलोकन अनुवाद है।
preview-notice-switch = अंग्रेज़ी पर स्विच करें
preview-notice-language = भाषा बदलें
# $tag is a language tag (text).
settings-language-unavailable = Atlas के इस संस्करण में { $tag } उपलब्ध नहीं है। फ़िलहाल अंग्रेज़ी दिखाई जा रही है, और आपकी भाषा की पसंद सहेजी गई है।
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas अभी आपकी Windows प्रदर्शन भाषाओं ({ $languages }) का समर्थन नहीं करता। फ़िलहाल अंग्रेज़ी दिखाई जा रही है।
settings-language-windows-unavailable = आपकी Windows प्रदर्शन भाषा की जाँच नहीं हो सकी। Atlas फ़िलहाल अंग्रेज़ी इस्तेमाल कर रहा है। विवरण: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = संख्याएँ, तारीख़ें और समय आपके Windows क्षेत्रीय प्रारूप ({ $locale }) के अनुसार दिखते हैं।
settings-language-contribute = GitHub पर Atlas के अनुवाद में मदद करें
settings-installing = इंस्टॉलेशन
settings-restart-label = इंस्टॉलेशन के बाद मेरा PC अपने-आप रीस्टार्ट करें
settings-restart-locked = इंस्टॉलेशन पूरा होने के बाद आप इसे बदल सकते हैं।
settings-restart-description = सेटअप पूरा करने के लिए रीस्टार्ट ज़रूरी है। अगर स्वचालित रीस्टार्ट चालू है, तो इंस्टॉल करने से पहले अपना काम सहेज लें।
settings-about = परिचय
settings-about-app = Atlas Manager
settings-about-data = ऐप फ़ाइलें
settings-about-licence = लाइसेंस
settings-about-licence-value = GPL-3.0, मुक्त और ओपन सोर्स
settings-view-source = GitHub पर सोर्स कोड देखें
settings-open-data-folder = ऐप फ़ोल्डर खोलें

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = हाइबरनेशन के दौरान आपका सत्र सहेजने में इस्तेमाल होने वाला डिस्क स्पेस ख़ाली करता है। हाइबरनेट और तेज़ स्टार्टअप (Fast Startup) उपलब्ध नहीं रहेंगे।
consequence-disable-power-saving = पावर बचाने वाली सुविधाएँ बंद कर देता है। आपका PC ज़्यादा बिजली ले सकता है, ज़्यादा गर्म हो सकता है और बैटरी कम समय चल सकती है।
consequence-disable-core-isolation = मेमोरी अखंडता (Memory integrity) समेत Windows की सुरक्षा की एक अतिरिक्त परत बंद कर देता है। इससे सुरक्षा कम होती है और इसकी ज़रूरत वाले ऐप या गेम पर असर पड़ सकता है।
consequence-remove-snipping-tool = स्क्रीनशॉट लेने और स्क्रीन रिकॉर्ड करने वाला Windows ऐप हटा देता है।
consequence-uninstall-edge = Microsoft Edge ब्राउज़र हटा देता है। पक्का करें कि आपके पास कोई दूसरा ब्राउज़र है, या नीचे एक चुनें।
consequence-install-another-browser = नीचे कोई ब्राउज़र चुनें, Atlas उसे आपके लिए इंस्टॉल कर देगा।

# Introduction on the home page before Atlas is installed.
home-intro = Atlas बैकग्राउंड गतिविधि और ध्यान भटकाने वाली चीज़ें कम करने के लिए Windows में बदलाव करता है। कोई भी बदलाव करने से पहले हम आपको जाँच और विकल्पों के हर चरण में साथ लेकर चलेंगे।

detail-build-missing = यह प्लेबुक कोई समर्थित Windows बिल्ड नहीं बताती। LocalTest पैकेज की जगह पूरा प्लेबुक बिल्ड चुनें।
## ISO creation (Beta)
iso-home-title = Windows इंस्टॉलेशन मीडिया
iso-home-description = इस या किसी दूसरे PC पर नए सिरे से इंस्टॉल करने के लिए Atlas वाला Windows ISO बनाएँ।
iso-open = Atlas ISO बनाएँ
iso-title = Atlas ISO बनाएँ
iso-beta = बीटा
iso-beta-description = PC पर इस्तेमाल करने से पहले ISO को वर्चुअल मशीन में जाँचें। Windows इंस्टॉल करने से पहले अपनी फ़ाइलों का बैकअप लें।
iso-admin-description = Windows इमेज पढ़ने और इंस्टॉलेशन मीडिया बनाने के लिए एडमिनिस्ट्रेटर की अनुमति चाहिए।
iso-files-description = बिना बदलाव वाला Windows 11 x64 ISO, Atlas प्लेबुक (.apbx) और बनने वाली फ़ाइल के लिए नया नाम चुनें।
iso-source = Windows ISO
iso-package = Atlas प्लेबुक (0.6+)
iso-output = नया ISO यहाँ सहेजें
iso-no-file = कोई फ़ाइल नहीं चुनी गई
iso-browse = ब्राउज़ करें
iso-save-as = इस रूप में सहेजें
iso-inspect = फ़ाइलें जाँचें
iso-mode-title = Windows और Atlas की सेटिंग
iso-mode-interactive = साइन इन करने के बाद Atlas की सेटिंग चुनें
iso-mode-interactive-description = साइन इन करने के बाद Atlas ऐप Windows और Store ऐप अपडेट करने, सेटिंग चुनने और Atlas लागू करने में मदद करेगा।
iso-mode-before = Atlas की सेटिंग अभी चुनें
iso-mode-before-description = अपनी Atlas सेटिंग ISO में सेव करें। साइन इन करने के बाद Windows और Store ऐप अपडेट करें, फिर इन सेटिंग के साथ Atlas लागू करें।
iso-package-unsupported-title = नई प्लेबुक चुनें
iso-package-unsupported = ISO सेटअप के लिए ISO का समर्थन करने वाला Atlas 0.6 या नया संस्करण चाहिए। कोई संगत प्लेबुक चुनें।
iso-atlas-options = Atlas की सेटिंग
iso-review = ISO की समीक्षा करें
iso-review-title = आपका ISO बनाने के लिए सब तैयार है
iso-editions = शामिल संस्करण: { $editions }
iso-source-size = मूल ISO: { $size } MB
iso-review-description = Atlas एक अलग ISO बनाएगा और मूल फ़ाइल बनी रहेगी। Windows इंस्टॉल करने के लिए नए ISO से बूट करें। ISO बनाने से इस PC पर Atlas इंस्टॉल नहीं होगा।
iso-create = ISO बनाएँ
iso-stage-inspect = Windows इमेज की जाँच हो रही है
iso-stage-copy = Windows की फ़ाइलें कॉपी हो रही हैं
iso-stage-inject = Atlas जोड़ा जा रहा है
iso-stage-master = ISO बन रहा है
iso-stage-verify = बनी हुई फ़ाइल की जाँच हो रही है
iso-stage-cleanup = अंतिम चरण पूरे हो रहे हैं
iso-progress-description = ऐप खुला रखें। बड़ी इमेज तैयार होने में कुछ समय लग सकता है।
iso-cancel = बनाना रद्द करें
iso-cancelling = रद्द करने के लिए सुरक्षित चरण का इंतज़ार है
iso-cancelled = ISO बनाना रद्द कर दिया गया
iso-cancelled-description = आपका मूल ISO सुरक्षित है। अगर कोई अस्थायी फ़ाइल अभी हटानी बाकी है, तो उसका विवरण डायग्नोस्टिक लॉग में मिलेगा।
iso-complete = आपका ISO तैयार है
iso-complete-description = पहले इसे वर्चुअल मशीन में जाँचें, फिर Windows इंस्टॉलेशन मीडिया बनाने के लिए इस्तेमाल करें।
iso-open-folder = फ़ोल्डर में दिखाएँ
iso-failed = ISO बनाना पूरा नहीं हो सका
iso-failed-description = समस्या का कारण जानने के लिए डायग्नोस्टिक विवरण खोलें। समस्या ठीक करें, फिर नए फ़ाइल नाम के साथ दोबारा कोशिश करें।
iso-diagnostics = डायग्नोस्टिक विवरण खोलें
iso-close-title = ISO अभी बन रहा है
iso-close-message = बनाने या रद्द करने की प्रक्रिया पूरी होने तक यह विंडो खुली रखें। रद्द करने के लिए मौजूदा काम के सुरक्षित रूप से रुकने का इंतज़ार किया जाएगा।
iso-keep-open = खुला रखें
prepare-title = Windows और Store ऐप अपडेट करें
prepare-description = Atlas लागू करने से पहले Windows अपडेट इंस्टॉल करें और Microsoft Store व उससे इंस्टॉल किए गए सभी ऐप अपडेट करें। अपडेट के दौरान Store ऐप बंद हो सकते हैं।
prepare-complete = Windows और Store ऐप अप टू डेट हैं।
prepare-reboot = Windows को रीस्टार्ट करना होगा। Atlas में आपके चुने हुए विकल्प सेव रहेंगे। साइन इन करने के बाद अपडेट फिर से जाँचें।
prepare-failed = कुछ अपडेट पूरे नहीं हो सके। डायग्नोस्टिक लॉग देखें, Windows या Store की गड़बड़ियाँ ठीक करें और फिर कोशिश करें।
prepare-cancelled = तैयारी रोक दी गई है। आगे बढ़ने से पहले अपडेट फिर से जाँचें।
prepare-windows-search = Windows अपडेट जाँचे जा रहे हैं…
prepare-windows-download = Windows अपडेट डाउनलोड हो रहे हैं…
prepare-windows-install = Windows अपडेट इंस्टॉल हो रहे हैं…
prepare-store-search = Microsoft Store की जाँच हो रही है…
prepare-store-install = Microsoft Store और उसके ऐप अपडेट हो रहे हैं…
prepare-stop-description = अभी चल रहा अपडेट पूरा होने के बाद तैयारी रुकेगी। तब तक Atlas खुला रखें।
prepare-stop = इस प्रक्रिया के बाद रोकें
prepare-restart = रीस्टार्ट करें और आगे बढ़ें
prepare-start = अपडेट जाँचें और इंस्टॉल करें
iso-username = स्थानीय खाते का नाम
iso-account-description = Windows दोबारा इंस्टॉल होने के बाद आपसे पासवर्ड तय करने को कहेगा।
iso-username-placeholder = आपका नाम
iso-account-invalid = 1–20 अक्षर इस्तेमाल करें। शुरुआत या अंत में स्पेस और Windows खाते के नाम में निषिद्ध चिह्न न डालें।
iso-privacy-defaults = Windows सेटअप वैकल्पिक डेटा शेयरिंग और व्यक्तिगत ऑफ़र अपने-आप बंद कर देता है।
prepare-drivers = ड्राइवर कैसे इंस्टॉल करने हैं?
prepare-drivers-auto = Windows Update से ड्राइवर प्राप्त करें
prepare-drivers-auto-detail = Windows आपके हार्डवेयर के लिए ड्राइवर ढूँढेगा। अधिकांश पीसी के लिए यही सुझाव है।
prepare-drivers-manual = ड्राइवर खुद इंस्टॉल करूँगा
prepare-drivers-manual-detail = Windows Update से ड्राइवर डाउनलोड होने से रोकता है। आपको ड्राइवर खुद ढूँढने होंगे; पहले से इंस्टॉल ड्राइवर बने रहेंगे।
prepare-network-needed = ऐसे Wi-Fi या ईथरनेट से कनेक्ट करें जो मीटर्ड कनेक्शन न हो, फिर कोशिश करें। अगर Wi-Fi नहीं दिख रहा, तो पहले नेटवर्क ड्राइवर इंस्टॉल करें।
prepare-network-settings = नेटवर्क सेटिंग खोलें
iso-target-title = किस पीसी पर Windows दोबारा इंस्टॉल करना है?
iso-target-this = इस पीसी पर
iso-target-other = किसी दूसरे पीसी पर
iso-copy-network = इस पीसी के नेटवर्क ड्राइवर शामिल करें
iso-network-detail = Windows इंस्टॉल करते समय इस पीसी के Wi-Fi और ईथरनेट ड्राइवर फिर से इस्तेमाल होंगे। दोबारा इंस्टॉल करने के बाद Wi-Fi से फिर कनेक्ट करना होगा।
iso-network-source = नेटवर्क ड्राइवर का स्रोत
iso-network-installed = इंस्टॉल किए हुए ड्राइवर इस्तेमाल करें
iso-network-updated = पहले Windows Update में जाँचें
iso-network-updated-detail = Windows Update से हार्डवेयर के लिए उपलब्ध ड्राइवर डाउनलोड करता है और इंस्टॉल किए हुए ड्राइवर बैकअप के तौर पर रखता है। इसके लिए गैर-मीटर्ड कनेक्शन चाहिए।
iso-stage-network-drivers = नेटवर्क ड्राइवर तैयार किए जा रहे हैं…
iso-network-failed = नेटवर्क ड्राइवर तैयार नहीं हो सके। डायग्नोस्टिक्स देखें या वापस जाकर नेटवर्क ड्राइवर का विकल्प बदलें।
iso-mode-desktop = डेस्कटॉप खोलने से पहले सेटअप पूरा करें
iso-mode-desktop-description = Atlas की सेटिंग अभी चुनें। साइन इन करने के बाद, Windows डेस्कटॉप खोलने से पहले अपडेट और Atlas का सेटअप पूरा करें।
desktop-setup-description = अपने पीसी का सेटअप पूरा करें। Atlas के आपके विकल्प सहेजे गए हैं; ज़रूरत पड़ने पर आप Windows पर लौट सकते हैं।
desktop-setup-exit = Windows में जारी रखें

# Windows installation USB (Beta)
usb-title = इंस्टॉलेशन USB बनाएँ
usb-existing = मौजूदा ISO से USB बनाएँ
usb-description = अपने PC पर Windows और Atlas इंस्टॉल करने के लिए Windows 11 25H2 का बूट करने योग्य USB बनाएँ।
usb-choose-iso = ISO चुनें
usb-drive = USB ड्राइव
usb-empty = USB ड्राइव कनेक्ट करें, फिर सूची रीफ़्रेश करें। केवल लिखने योग्य USB ड्राइव दिखाई जाती हैं जिन पर अभी चल रहा Windows इंस्टॉल नहीं है।
usb-refresh = रीफ़्रेश करें
usb-drive-detail = { $size } GB · { $volumes } · सीरियल नंबर: { $serial }
usb-review = USB की समीक्षा करें
usb-erase-title = इस USB ड्राइव को मिटाएँ?
usb-erase-description = { $drive } ({ $size } GB) की सभी फ़ाइलें और पार्टिशन हमेशा के लिए मिट जाएँगे। आपकी ISO फ़ाइल रखी जाएगी।
usb-layout = Windows सेटअप के लिए अधिकतम 32 GB इस्तेमाल होगा। बाकी जगह अनावंटित रहेगी। यह USB उन PC के लिए है जो UEFI से बूट होते हैं।
usb-ack = मुझे पता है कि इस USB ड्राइव का सारा डेटा मिट जाएगा।
usb-write = मिटाएँ और USB बनाएँ
usb-stage-prepare = इंस्टॉलेशन फ़ाइलें तैयार की जा रही हैं…
usb-stage-format = USB फ़ॉर्मैट किया जा रहा है…
usb-stage-copy = इंस्टॉलेशन फ़ाइलें कॉपी की जा रही हैं…
usb-stage-verify = USB की पुष्टि की जा रही है…
usb-working = Atlas खुला रखें और USB कनेक्ट रहने दें। रद्द करने पर मौजूदा प्रक्रिया के सुरक्षित रूप से रुकने का इंतज़ार होगा। अधूरे USB से Windows इंस्टॉल नहीं किया जा सकता।
usb-failed = USB बनाना पूरा नहीं हो सका। कनेक्शन जाँचें और जानकारी के लिए डायग्नोस्टिक विवरण खोलें। दोबारा कोशिश करने के लिए ड्राइव फिर से चुनें।
usb-cancelled = USB बनाना रोक दिया गया है। ड्राइव पर अधूरी इंस्टॉलेशन फ़ाइलें हो सकती हैं। Windows इंस्टॉल करने से पहले इसे फिर से बनाएँ।
usb-complete = आपका USB तैयार है और सभी फ़ाइलों की पुष्टि हो गई है। इसे इजेक्ट करें, उस PC से कनेक्ट करें जिस पर Windows फिर से इंस्टॉल करना है, और उसके UEFI बूट मेनू में USB चुनें।
usb-eject = USB इजेक्ट करें
usb-ejected = अब USB सुरक्षित रूप से निकाला जा सकता है। Windows इंस्टॉल करने के लिए अपने PC के UEFI बूट मेनू में इसे चुनें।
usb-eject-failed = Windows USB इजेक्ट नहीं कर सका। इसे इस्तेमाल करने वाली फ़ाइलें या विंडो बंद करें, फिर दोबारा कोशिश करें।
ready-fresh-title = Windows की नई स्थापना से शुरू करें
ready-fresh-description = समर्थित Atlas अपग्रेड को छोड़कर, Atlas के लिए Windows की नई स्थापना ज़रूरी है। Atlas 0.6 की नई स्थापना के लिए Windows 11 25H2 चाहिए। Windows दोबारा इंस्टॉल करने से पहले अपनी फ़ाइलों का बैकअप लें।
detail-edition-unsupported = Windows 11 Pro, Pro for Workstations या Enterprise का उपयोग करें। Home, LTSC और Server संस्करण समर्थित नहीं हैं। यदि आपके संस्करण की पहचान नहीं हो सकी, तो आगे बढ़ने से पहले यह समस्या ठीक करें।
install-source-title = इंस्टॉलेशन उपलब्ध नहीं है
install-source-unsupported = Atlas { $source } को सीधे { $target } में अपडेट नहीं किया जा सकता। इस संस्करण का उपयोग करने के लिए Windows फिर से इंस्टॉल करें।
install-source-unknown = Atlas इंस्टॉलेशन की स्थिति की पुष्टि नहीं कर सका। दोबारा कोशिश करने से पहले अधूरे इंस्टॉलेशन को पूरा करें और डायग्नोस्टिक्स देखें।
iso-edition-selection = केवल समर्थित संस्करण शामिल हैं। Windows सेटअप के दौरान वह संस्करण चुनें जिसके लिए आपके पास Windows लाइसेंस है।
detail-windows-preview = Insider बिल्ड समर्थित नहीं हैं। Windows 11 का सार्वजनिक रिलीज़ संस्करण इस्तेमाल करें।
detail-windows-release-unknown = Atlas पुष्टि नहीं कर सका कि यह Windows बिल्ड सार्वजनिक रूप से रिलीज़ हुआ है। इंटरनेट से कनेक्ट करें और दोबारा जाँचें।
iso-release-unknown = पुष्टि नहीं हो सकी कि इस ISO में Windows 11 25H2 का सार्वजनिक रिलीज़ संस्करण है। इंटरनेट से कनेक्ट करके दोबारा कोशिश करें या आधिकारिक इंस्टॉलेशन मीडिया चुनें।
prepare-previous-worker = पिछला अपडेट अभी चल रहा है। Atlas उसके पूरा होने का इंतज़ार करेगा, फिर आप दोबारा कोशिश कर सकेंगे।
