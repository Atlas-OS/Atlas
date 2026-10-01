### Atlas Manager: हिन्दी (Hindi), preview translation; revised on 30 September 2026 from the en-GB source. Native-speaker review pending.
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
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "SmartScreen", "GitHub"
###   are product names. Windows feature names should match what Windows
###   shows in your language (for example the four Virus & threat protection
###   switches). The Windows Security app is "Windows सुरक्षा" in Hindi Windows.
### - Sentences end with the danda (।); titles, labels and buttons do not.
### - Buttons are short and end in the respectful imperative (करें, खोलें).
### - "Relaunch" (the Atlas Manager) is "दोबारा खोलें"; "restart" (the PC or
###   Windows) is "रीस्टार्ट करें". Keep the two apart.
### - The .apbx file is the "Atlas package": "Atlas पैकेज", then "पैकेज" once
###   it is clear (masculine: "साथ में दिया गया Atlas पैकेज"). Use प्लेबुक only
###   where a string explains that AME Wizard calls it a playbook. The
###   selections made in the Your choices step are "विकल्प" everywhere, the ISO
###   modes included, never "सेटिंग"/"सेटिंग्स": those name the app's own
###   Settings page and Windows settings.
### - Where a message names a button or option, quote its exact label in “ ”.

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
# Accessible name of a Show details or Hide details toggle. $action is common-show-details or
# common-hide-details; $section is the title of the card it opens.
common-details-a11y = { $action }, { $section }
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
list-and = { $a } और { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }। { $message }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Atlas इंस्टॉल हो रहा है, विंडो बंद करें?
window-close-message = इंस्टॉलेशन बैकग्राउंड में जारी रहेगा। प्रगति और नतीजा देखने के लिए Atlas दोबारा खोलें। इंस्टॉलेशन पूरा होने तक अपना PC चालू रखें।
# Instead of window-close-message when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-message-restart = इंस्टॉलेशन बैकग्राउंड में जारी रहेगा, लेकिन Atlas बंद रहने पर आपका PC अपने-आप रीस्टार्ट नहीं होगा। प्रगति और नतीजा देखने के लिए Atlas दोबारा खोलें। इंस्टॉलेशन पूरा होने तक अपना PC चालू रखें।
window-close-keep = खुला रखें
window-close-close = विंडो बंद करें
# Dialog shown when the window is closed during the final checks, before the
# installer has started; window-close-keep and window-close-close are its buttons.
window-close-preparing-title = इंस्टॉलेशन शुरू होने से पहले बंद करें?
window-close-preparing-message = Atlas अभी भी आपके PC की जाँच कर रहा है और उसने इंस्टॉल करना शुरू नहीं किया है। अगर आप अभी बंद करते हैं, तो इंस्टॉलेशन शुरू नहीं होगा। जारी रखने के लिए Atlas दोबारा खोलें।
prepare-close-title = अपडेट अभी भी चल रहे हैं
# "Stop updating" is prepare-stop, the dialog's other button.
prepare-close-message = अपडेट चलने तक Atlas खुला रखें। अगर आप “अपडेट करना रोकें” चुनते हैं, तो मौजूदा चरण के बाद अपडेट रुक जाएँगे, और तब आप Atlas बंद कर सकते हैं।
# Dialog shown when the window is closed during the restart countdown after a
# successful install. Its buttons are window-close-keep, restart-now and
# window-close-restart-close.
window-close-restart-title = रीस्टार्ट किए बिना Atlas बंद करें?
# "अभी रीस्टार्ट करें" is restart-now, one of this dialog's three buttons.
window-close-restart-message = Atlas का सेटअप पूरा करने के लिए आपके PC को रीस्टार्ट करना होगा। अगर आप अभी Atlas बंद करते हैं, तो वह आपका PC रीस्टार्ट नहीं करेगा, इसलिए जब आप तैयार हों, तब इसे ख़ुद रीस्टार्ट करें। “अभी रीस्टार्ट करें” चुनने से पहले अपना काम सहेजें।
window-close-restart-close = रीस्टार्ट किए बिना बंद करें
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. $switches names them as Windows Security does, joined like a list. Its buttons are
# window-close-keep, common-open-windows-security and window-close-close.
window-close-protection-title = सुरक्षा बंद है, फिर भी Atlas बंद करें?
window-close-protection-message = Windows सुरक्षा में कुछ सुरक्षा सुविधाएँ अभी भी बंद हैं: { $switches }। अगर आप Atlas इंस्टॉल करना पूरा नहीं करने वाले हैं, तो Atlas बंद करने से पहले इन्हें फिर से चालू करें। अगर करने वाले हैं, तो Atlas दोबारा खोलने पर वह आपका सेटअप जारी रखेगा।
# Title of the file picker for an Atlas package (.apbx) file.
file-dialog-open-package = Atlas पैकेज (.apbx) खोलें
# Message Windows shows in its restart notification.
shutdown-comment = Atlas इंस्टॉल हो गया है। सेटअप पूरा करने के लिए Windows रीस्टार्ट हो रहा है।
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = अपडेट इंस्टॉल करना पूरा करने के लिए Atlas, Windows रीस्टार्ट कर रहा है।

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (बिल्ड { $build })

## Home page

home-not-installed = Atlas में आपका स्वागत है
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = इस PC पर Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = { $date } को इंस्टॉल किया गया
home-status-checking = अपडेट की जाँच हो रही है
# While startup checks whether another window's installation is running.
home-status-recovering = चल रहे इंस्टॉलेशन की जाँच हो रही है
home-status-offline = अपडेट की जाँच नहीं हो सकी
home-status-not-checked = अपडेट की जाँच अभी नहीं हुई है
home-status-update = Atlas { $version } उपलब्ध है
home-status-up-to-date = नवीनतम संस्करण इंस्टॉल है
home-status-newest = नवीनतम संस्करण: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Atlas { $version } का इंस्टॉलेशन अधूरा है
home-check-again = दोबारा जाँचें
# Primary button while an install is running or waiting.
home-show-install = प्रगति देखें
home-continue-installing = सेटअप जारी रखें
home-update-to = Atlas { $version } पर अपडेट करें
home-reinstall = Atlas दोबारा इंस्टॉल करें
home-install = Atlas इंस्टॉल करें
home-finish-install = Atlas { $version } का इंस्टॉलेशन पूरा करें
home-start-over = नए सिरे से शुरू करें
home-restart-title = आपके PC को रीस्टार्ट करना होगा
home-security-reminder-title = सुरक्षा स्विच फिर से चालू करें
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = पक्का करें कि आपकी सुरक्षा चालू है
home-security-reminder-message = Atlas अभी कुछ भी इंस्टॉल नहीं कर रहा है, लेकिन Windows सुरक्षा में कुछ सुरक्षा सुविधाएँ अभी भी बंद हैं। Windows सुरक्षा खोलें और पक्का करें कि ये चालू हैं: { $switches }।
home-security-reminder-unreadable-message = Atlas हर सुरक्षा स्विच की स्थिति नहीं पढ़ सका। Windows सुरक्षा में देखें कि ये चालू हैं: { $switches }।
home-elevation-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
home-state-error-title = आपके Atlas इंस्टॉलेशन का विवरण नहीं पढ़ा जा सका
home-state-error-message = हो सकता है कि आपका Atlas संस्करण, विकल्प और इतिहास सही न दिखें। फिर से कोशिश करने के लिए “दोबारा जाँचें” चुनें। विवरण: { $error }
home-whats-new = Atlas { $version } में नया क्या है
home-view-release = GitHub पर रिलीज़ नोट्स देखें
home-released = { $date } को रिलीज़ किया गया
home-show-less = कम दिखाएँ
home-show-full-notes = पूरे रिलीज़ नोट्स दिखाएँ
home-your-install = आपका Atlas सेटअप
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = इस PC पर इस बात का कोई रिकॉर्ड नहीं है कि Atlas कैसे इंस्टॉल किया गया था, इसलिए आपके विकल्प और इंस्टॉलेशन इतिहास नहीं दिखाए जा सकते।
# Row label: how Atlas was set up.
home-set-up = सेटअप का तरीका
home-set-up-during-oobe = Windows सेटअप के दौरान
home-history = इंस्टॉलेशन इतिहास
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = चलिए, आपके PC को Atlas के लिए तैयार करें
home-step-1-detail = Atlas आपके PC की जाँच करता है, Windows और Microsoft Store के लंबित अपडेट इंस्टॉल करता है, और इंस्टॉलेशन फ़ाइलें डाउनलोड करता है। Store ऐप बंद हो सकते हैं और आपके PC को रीस्टार्ट करना पड़ सकता है, इसलिए पहले अपना काम सहेज लें।
# Tester build: the Atlas package is bundled, nothing is downloaded.
home-step-1-detail-bundled = Atlas आपके PC की जाँच करता है, Windows और Microsoft Store के लंबित अपडेट इंस्टॉल करता है, और साथ में दी गई इंस्टॉलेशन फ़ाइलें तैयार करता है। Store ऐप बंद हो सकते हैं और आपके PC को रीस्टार्ट करना पड़ सकता है, इसलिए पहले अपना काम सहेज लें।
home-step-2-detail = चुनें कि Microsoft Defender और प्रोसेसर सुरक्षा रखनी है या नहीं, Windows अपडेट कैसे इंस्टॉल हों, और आपको कौन-से अतिरिक्त विकल्प चाहिए।
home-step-3-detail = Windows सुरक्षा में चार सुरक्षा स्विच बंद करें, ताकि वे इंस्टॉलेशन न रोकें। Atlas आपको इसका तरीका दिखाएगा।
home-step-4-detail =
    { $minutes ->
        [1] इंस्टॉलेशन में लगभग { $minutes } मिनट लगता है। इसके बाद आपके PC को रीस्टार्ट करना होगा।
       *[other] इंस्टॉलेशन में लगभग { $minutes } मिनट लगते हैं। इसके बाद आपके PC को रीस्टार्ट करना होगा।
    }
# Accessible name of a numbered step.
home-step-a11y = चरण { $number }: { $title }
home-github = GitHub पर Atlas देखें
home-discord = Discord पर Atlas समुदाय से जुड़ें
home-report-problem = समस्या रिपोर्ट करें

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
# $error is a raw error message (text).
notice-settings-not-saved = Atlas आपके हाल के बदलाव सहेज नहीं सका, इसलिए Atlas बंद करने पर वे खो सकते हैं। अगर Atlas की कोई दूसरी विंडो खुली है, तो उसे बंद करें, फिर बदलाव दोबारा करें। विवरण: { $error }
notice-session-unreadable-title = पिछले इंस्टॉलेशन की जाँच नहीं हो सकी
# $path is a file path (text).
notice-session-unreadable-message = Atlas यह पता नहीं लगा सका कि पिछला इंस्टॉलेशन अभी भी चल रहा है या नहीं। अगर आप निश्चित नहीं हैं, तो Atlas समुदाय से मदद माँगें। { $path } तभी हटाएँ और फिर कोशिश करें, जब आपको पक्का पता हो कि कोई इंस्टॉलेशन नहीं चल रहा है। विवरण: { $error }

## Administrator elevation

elevation-declined = अनुमति नहीं मिली। फिर कोशिश करें, और जब Windows पूछे कि Atlas को बदलाव करने दें या नहीं, तो “हाँ” चुनें।
elevation-declined-continue = अनुमति नहीं मिली। फिर कोशिश करें, और जब Windows पूछे कि Atlas को बदलाव करने दें या नहीं, तो “हाँ” चुनें। आपके सेटअप विकल्प सहेज लिए गए हैं।
elevation-draft-not-saved = Atlas आपके सेटअप विकल्प सहेज नहीं सका, इसलिए वह दोबारा नहीं खुला। फिर कोशिश करें। विवरण: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Atlas की एक दूसरी विंडो अब इस सेटअप का इस्तेमाल कर रही है, इसलिए Atlas दोबारा नहीं खुला। उसी विंडो में जारी रखें, या यहाँ फिर से सेटअप करने के लिए “नए सिरे से शुरू करें” चुनें।

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
stepper-status-attention = ध्यान देने की ज़रूरत है
# Heading above each step's content.
step-heading = { $total } में से चरण { $number }: { $title }
# Accessible name of the step heading on a screen of Your choices, read when it takes focus.
# $heading is step-heading; $progress is options-progress; $question is the screen's question.
step-heading-choice-a11y = { $heading }। { $progress }: { $question }
# The same on the optional extras screen; $progress is options-progress-extras.
step-heading-extras-a11y = { $heading }। { $progress }

## Step 1: Get ready

ready-banner-busy-title = आपका PC तैयार हो रहा है
ready-banner-busy-message = Atlas आपके PC की जाँच कर रहा है और इंस्टॉलेशन फ़ाइलें तैयार कर रहा है।
ready-banner-blocked-title = आपका PC अभी तैयार नहीं है
ready-banner-blocked-message = “PC की जाँच” में चिह्नित समस्याएँ ठीक करें, फिर “दोबारा जाँचें” चुनें।
ready-banner-no-package-title = जारी रखने के लिए Atlas डाउनलोड करें
ready-banner-no-package-message = “इंस्टॉलेशन फ़ाइलें” में Atlas डाउनलोड करें, या अगर आपके पास पहले से Atlas पैकेज (.apbx) है, तो “पैकेज फ़ाइल खोलें” चुनें।
# Tester build: the bundled Atlas package couldn't be unpacked.
ready-banner-no-package-bundled-title = जारी रखने के लिए साथ में दिया गया Atlas पैकेज तैयार करें
ready-banner-no-package-bundled-message = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज अभी तैयार नहीं है। “इंस्टॉलेशन फ़ाइलें” कार्ड देखें।
ready-banner-updates-title = जारी रखने के लिए Windows और Store ऐप अपडेट करें
ready-banner-updates-message = “अपडेट जाँचें और इंस्टॉल करें” चुनें। अपडेट पूरे होने पर Atlas आपके PC की दोबारा जाँच करेगा।
# While Windows and Store apps update. "Update Windows and Store apps" is prepare-title, the
# card further down the page.
ready-banner-updating-title = Windows और Store ऐप अपडेट हो रहे हैं
ready-banner-updating-message = इसमें कुछ समय लग सकता है। Atlas खुला रखें। आप “Windows और Store ऐप अपडेट करें” में प्रगति देख सकते हैं।
# After Stop updating. "Check and install updates" is prepare-start, the card's button.
ready-banner-updates-stopped-title = अपडेट करना रुक गया
ready-banner-updates-stopped-message = अपडेट पूरे करने के लिए “Windows और Store ऐप अपडेट करें” में “अपडेट जाँचें और इंस्टॉल करें” चुनें।
# Atlas reopened after restarting the PC to continue updating. "Continue updates" is
# prepare-continue, the card's button.
ready-banner-updates-resumed-title = आपका PC रीस्टार्ट हो गया है
ready-banner-updates-resumed-message = अपडेट पूरे करने के लिए “Windows और Store ऐप अपडेट करें” में “अपडेट जारी रखें” चुनें।
# Under prepare-failed-title or prepare-unconfirmed-title. "Try again" is common-try-again,
# the card's button.
ready-banner-updates-failed-message = क्या करना है, यह जानने के लिए “Windows और Store ऐप अपडेट करें” देखें, उसके बाद “फिर कोशिश करें” चुनें।
# Under prepare-reboot-title. "Restart and continue" is prepare-restart, the card's button.
ready-banner-reboot-message = पहले अपना काम सहेजें, फिर “Windows और Store ऐप अपडेट करें” में “रीस्टार्ट करें और आगे बढ़ें” चुनें।
ready-banner-warnings-title = कुछ बातों पर ध्यान दें
ready-banner-warnings-message = आप जारी रख सकते हैं, लेकिन पहले “PC की जाँच” में चिह्नित बातें पढ़ लें।
ready-banner-ok-title = अब आप अपने विकल्प चुन सकते हैं
ready-banner-ok-message = सभी जाँचें सफल रहीं और आपकी इंस्टॉलेशन फ़ाइलें तैयार हैं।

# Card title and accessible name of the list of checks.
ready-this-pc = PC की जाँच
ready-check-again = दोबारा जाँचें
ready-checks-passed =
    { $count ->
        [1] { $count } जाँच सफल रही
       *[other] { $count } जाँचें सफल रहीं
    }

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
# Tester build: the bundled Atlas package is being unpacked, nothing is downloaded.
package-looking-bundled = साथ में दिया गया Atlas पैकेज तैयार किया जा रहा है।
package-none = इंस्टॉलेशन फ़ाइलें पाने के लिए Atlas डाउनलोड करें। अगर आपके पास पहले से Atlas पैकेज (.apbx) है, तो उसे खोलें।
# The GitHub release check failed. "नवीनतम संस्करण डाउनलोड करें" is package-download-newest,
# the button offered in this state; it checks again.
package-release-failed = Atlas नवीनतम संस्करण की जाँच नहीं कर सका। अपना इंटरनेट कनेक्शन जाँचें, फिर “नवीनतम संस्करण डाउनलोड करें” चुनें, या सहेजा हुआ Atlas पैकेज (.apbx) खोलें।
# Short status words beside the card title.
package-status-downloading = डाउनलोड हो रही हैं
package-status-unpacking = निकाली जा रही हैं
package-status-failed = फ़ाइलें तैयार नहीं हो सकीं
package-status-ready = तैयार
package-status-checking = जाँच हो रही है
package-status-preparing = तैयार की जा रही हैं
package-status-missing = डाउनलोड नहीं हुई हैं
# Accessible name of the progress bar.
package-progress = इंस्टॉलेशन फ़ाइलों की प्रगति
package-download-again = दोबारा डाउनलोड करें
package-download-version = Atlas { $version } डाउनलोड करें
package-download-newest = नवीनतम संस्करण डाउनलोड करें
package-cancel-download = डाउनलोड रद्द करें
package-open-file = पैकेज फ़ाइल खोलें
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } GitHub से डाउनलोड हो गया है और इंस्टॉल के लिए तैयार है।
package-from-file = Atlas { $version }, { $file } से लोड हो गया है और इंस्टॉल के लिए तैयार है।
package-unpacked = Atlas { $version } इंस्टॉल के लिए तैयार है।
package-none-yet = कोई इंस्टॉलेशन फ़ाइल नहीं चुनी गई
acquire-no-asset = Atlas { $version } के लिए डाउनलोड करने योग्य कोई पैकेज फ़ाइल नहीं है। जारी रखने के लिए सहेजा हुआ Atlas पैकेज (.apbx) खोलें।
acquire-unsupported = यह ऐप Atlas 0.6.0 और उसके बाद के संस्करण इंस्टॉल कर सकता है। Atlas { $version } इंस्टॉल करने के लिए इसकी जगह AME Wizard इस्तेमाल करें।
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } में वे फ़ाइलें नहीं हैं, जिनकी ज़रूरत इस ऐप को इसे इंस्टॉल करने के लिए है। इसे दोबारा डाउनलोड करें, या कोई दूसरा Atlas पैकेज (.apbx) खोलें।
acquire-failed = इंस्टॉलेशन फ़ाइलें तैयार नहीं हो सकीं। दोबारा डाउनलोड करके देखें, या कोई दूसरा Atlas पैकेज (.apbx) खोलें। विवरण: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = डाउनलोड ने प्रतिक्रिया देना बंद कर दिया। अपना इंटरनेट कनेक्शन जाँचें, फिर दोबारा डाउनलोड करें, या सहेजा हुआ Atlas पैकेज (.apbx) खोलें।
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = साथ में दिया गया Atlas पैकेज तैयार नहीं हो सका। “फिर कोशिश करें” चुनें। विवरण: { $error }

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
check-fix-apps = इंस्टॉल किए गए ऐप्स खोलें
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = मैंने Windows Update देख लिया है और कोई अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है

detail-admin-ok = Atlas को इंस्टॉलेशन के लिए ज़रूरी बदलाव करने की अनुमति है।
detail-admin-missing = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, फिर जब Windows अनुमति माँगे, तो “हाँ” चुनें।
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas के इस संस्करण के लिए Windows बिल्ड { $builds } ज़रूरी है। आपके PC पर बिल्ड { $build } है। जारी रखने से पहले समर्थित Windows संस्करण इंस्टॉल करें।
detail-build-missing = यह Atlas पैकेज किसी भी समर्थित Windows बिल्ड की सूची नहीं देता। LocalTest बिल्ड की जगह पैकेज का पूरा बिल्ड इस्तेमाल करें।
detail-updates-none = कोई Windows अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है।
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] यह अपडेट इंस्टॉल होने की प्रतीक्षा में है: { $titles }। Atlas इसे “Windows और Store ऐप अपडेट करें” में इंस्टॉल करेगा।
        [2] ये अपडेट इंस्टॉल होने की प्रतीक्षा में हैं: { $titles }। Atlas इन्हें “Windows और Store ऐप अपडेट करें” में इंस्टॉल करेगा।
       *[other] { $count } अपडेट इंस्टॉल होने की प्रतीक्षा में हैं, जिनमें { $titles } शामिल हैं। Atlas इन्हें “Windows और Store ऐप अपडेट करें” में इंस्टॉल करेगा।
    }
detail-updates-unknown = अपडेट की जाँच नहीं हो सकी। Windows Update खोलें, और अगर कोई अपडेट प्रतीक्षा में नहीं है, तो नीचे पुष्टि करें। ({ $error })
detail-reboot-none = Windows को अभी रीस्टार्ट की ज़रूरत नहीं है।
detail-reboot-pending = पहले किए गए बदलाव पूरे करने के लिए Windows को रीस्टार्ट करना होगा। जब आप “अपडेट जाँचें और इंस्टॉल करें” चुनेंगे, तो Atlas आपसे पहले रीस्टार्ट करने को कहेगा।
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-reboot-pending-reasons = पहले किए गए बदलाव पूरे करने के लिए Windows को रीस्टार्ट करना होगा ({ $reasons })। जब आप “अपडेट जाँचें और इंस्टॉल करें” चुनेंगे, तो Atlas आपसे पहले रीस्टार्ट करने को कहेगा।
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = आप जारी रख सकते हैं। Windows को अगली बार रीस्टार्ट होने पर कुछ फ़ाइलें बदलनी या हटानी हैं ({ $files })। Xbox Gaming Services जैसे कुछ ऐप हर रीस्टार्ट के बाद ऐसा करते हैं।
detail-reboot-unknown = यह जाँच नहीं हो सकी कि Windows को रीस्टार्ट की ज़रूरत है या नहीं। अपना PC रीस्टार्ट करें, फिर Atlas दोबारा खोलकर फिर से जाँचें। ({ $error })
detail-antivirus-none = कोई दूसरा एंटीवायरस सॉफ़्टवेयर नहीं मिला।
# $products is a list of product names (text).
detail-antivirus-found = Microsoft Defender के अलावा दूसरे एंटीवायरस ऐप इंस्टॉलेशन रोक सकते हैं। { $products } अनइंस्टॉल करें, फिर “दोबारा जाँचें” चुनें।
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows सुरक्षा में { $products } अब भी सूचीबद्ध है, लेकिन इसकी फ़ाइलें हट चुकी हैं, इसलिए यह अब इंस्टॉल नहीं है। Atlas फिर भी इंस्टॉलेशन जारी रख सकता है।
detail-antivirus-unknown = अन्य एंटीवायरस सॉफ़्टवेयर की जाँच नहीं हो सकी। “दोबारा जाँचें” चुनें। अगर यह बार-बार विफल हो, तो अपना PC रीस्टार्ट करें और फिर से जाँचें। ({ $error })
detail-internet-ok = आप इंटरनेट से जुड़े हैं। जब तक Atlas सॉफ़्टवेयर डाउनलोड और इंस्टॉल करता है, यह कनेक्शन बनाए रखें।
detail-internet-missing = इंटरनेट से कनेक्ट करें, फिर दोबारा जाँचें।
detail-power-mains = आपका PC प्लग इन है। इंस्टॉलेशन पूरा होने तक इसे प्लग इन रखें।
detail-power-battery = अपने PC को प्लग इन करें, ताकि वह पूरे इंस्टॉलेशन के दौरान चालू रहे।
detail-power-unknown = Atlas यह पता नहीं लगा सका कि आपका PC प्लग इन है या नहीं। अगर यह लैपटॉप है, तो इसे प्लग इन करें, फिर “दोबारा जाँचें” चुनें। अगर ऐसा बार-बार हो, तो “रिपोर्ट भेजें” चुनें।
detail-activation-ok = Windows सक्रिय है। Atlas इसे नहीं बदलेगा।
detail-activation-missing = Windows सक्रिय नहीं है। आप जारी रख सकते हैं, लेकिन Atlas आपके लिए Windows सक्रिय नहीं करेगा।
detail-activation-no-licence = Windows ने कोई लाइसेंस नहीं बताया। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा।
detail-activation-unknown = Windows सक्रियण की जाँच नहीं हो सकी। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा। ({ $error })

## Step 2: Options

options-progress = { $total } में से पसंद { $number }
options-progress-extras = { $total } में से पसंद { $number }: अतिरिक्त विकल्प
options-change-later = Microsoft Defender, प्रोसेसर सुरक्षा और अपडेट सेटिंग्स को आप बाद में अपने डेस्कटॉप पर मौजूद Atlas फ़ोल्डर से बदल सकते हैं।
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Microsoft Defender रखें?
screen-mitigations-title = प्रोसेसर सुरक्षा
screen-mitigations-question = Windows की प्रोसेसर सुरक्षा बनाए रखें?
screen-updates-title = Windows Update
screen-updates-question = Windows अपडेट कैसे इंस्टॉल करे?
screen-browser-title = ब्राउज़र
screen-power-title = पावर और सुरक्षा
screen-apps-title = ऐप्स
screen-optional-apps-title = वैकल्पिक ऐप्स
screen-choose-one-title = एक विकल्प चुनें
screen-extras-title = अतिरिक्त विकल्प
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } के लिए एक विकल्प चुनें
learn-more-defender = Microsoft Defender के बारे में और जानें
learn-more-mitigations = प्रोसेसर सुरक्षा के बारे में और जानें
learn-more-updates = Windows Update के बारे में और जानें
learn-more-browser = ब्राउज़र के बारे में और जानें
learn-more-power = पावर और सुरक्षा के बारे में और जानें
learn-more-apps = ऐप्स के बारे में और जानें
learn-more-eclean = eclean, AtlasOS के साथ कैसे काम करता है
learn-more-generic = सेटअप गाइड पढ़ें
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Windows का अपना एंटीवायरस चालू रहता है, जो आपके PC को वायरस और अन्य ख़तरों से बचाने में मदद करता है।
consequence-defender-disable = SmartScreen को भी हटा देता है। जब तक आप कोई दूसरा एंटीवायरस ऐप इंस्टॉल नहीं करते, तब तक आपके PC में एंटीवायरस सुरक्षा नहीं होगी। साथ ही, अपरिचित ऐप या डाउनलोड खोलने से पहले Windows आपको चेतावनी नहीं देगा।
consequence-mitigations-default = Windows की डिफ़ॉल्ट सुरक्षा बनाए रखता है, जो प्रोसेसर की ख़ामियों और ऐप्स के बग का फ़ायदा उठाने वाले हमलों से बचाती है।
consequence-mitigations-disable = ऐप्स के लिए शोषण से सुरक्षा भी बंद कर देता है, जैसे नियंत्रण प्रवाह गार्ड (CFG)। इससे सुरक्षा कम होती है। प्रदर्शन में कोई अंतर आएगा या नहीं, यह आपके प्रोसेसर पर निर्भर करता है।
consequence-auto-updates-disable = नियमित रूप से Windows Update खोलकर अपडेट इंस्टॉल करें। अपडेट की सूचनाएँ चालू रहेंगी।
consequence-auto-updates-default = Windows अपडेट अपने-आप इंस्टॉल करेगा, जिनमें सुरक्षा सुधार भी शामिल हैं।

## Atlas package text
## The Atlas package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Microsoft Defender रखें (सुझाया गया)
playbook-option-defender-disable = Microsoft Defender हटाएँ
playbook-option-mitigations-default = प्रोसेसर सुरक्षा बनाए रखें (सुझाया गया)
playbook-option-mitigations-disable = प्रोसेसर सुरक्षा बंद करें
playbook-option-auto-updates-disable = अपडेट ख़ुद इंस्टॉल करें
playbook-option-auto-updates-default = अपडेट अपने-आप इंस्टॉल करें
playbook-option-disable-hibernation = हाइबरनेशन बंद करें
playbook-option-disable-power-saving = पावर सेविंग बंद करें
playbook-option-disable-core-isolation = वर्चुअलाइज़ेशन-आधारित सुरक्षा (VBS) बंद करें
playbook-option-remove-snipping-tool = Snipping Tool हटाएँ
playbook-option-uninstall-edge = Microsoft Edge हटाएँ
playbook-option-install-another-browser = कोई ब्राउज़र इंस्टॉल करें
playbook-option-install-toolbox = Atlas Toolbox इंस्टॉल करें
playbook-option-install-eclean = eclean इंस्टॉल करें
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender, Windows में पहले से मौजूद एंटीवायरस है। इसे तभी हटाएँ, जब आप इसके जोखिम समझते हों और कोई दूसरा एंटीवायरस ऐप इस्तेमाल करने वाले हों। आप जो भी चुनें, Atlas ये सुविधाएँ बंद कर देता है: स्मार्ट ऐप नियंत्रण, उन्नत फ़िशिंग सुरक्षा और मेरा डिवाइस ढूँढें।
playbook-page-mitigations-default-description = ये सुरक्षा उपाय, जिन्हें सुरक्षा मिटिगेशन भी कहा जाता है, Spectre और Meltdown जैसी प्रोसेसर की ख़ामियों से और ऐप्स के बग का फ़ायदा उठाने वाले हमलों से बचाने में मदद करते हैं। Windows की डिफ़ॉल्ट सेटिंग्स बनाए रखने का सुझाव दिया जाता है।
playbook-page-auto-updates-disable-description = Windows अपडेट में सुरक्षा सुधार शामिल होते हैं। आप चाहें तो Windows उन्हें अपने-आप इंस्टॉल कर सकता है, या आप उन्हें ख़ुद इंस्टॉल कर सकते हैं। दोनों ही स्थितियों में Atlas, Windows को उसके मौजूदा संस्करण पर बनाए रखता है, जिसे सुरक्षा सुधार तभी तक मिलते हैं, जब तक Microsoft उसका समर्थन बंद नहीं कर देता। Atlas, Microsoft Store ऐप्स के अपने-आप होने वाले अपडेट भी बंद कर देता है, इसलिए उन्हें Microsoft Store में अपडेट करें।
playbook-page-browser-brave-description = इंस्टॉल करने के लिए कोई ब्राउज़र चुनें। Atlas आपकी ब्राउज़र सेटिंग्स नहीं बदलेगा।

## Step 3: Windows Security

security-banner-reading-title = Windows सुरक्षा की जाँच हो रही है
security-banner-reading-message = Atlas नीचे दिए चार सुरक्षा स्विच की जाँच कर रहा है।
security-banner-off-title = चारों सुरक्षा स्विच बंद हैं
# Shown instead of the switch list when an earlier Atlas install removed Microsoft Defender.
security-banner-absent-title = इस PC पर Microsoft Defender इंस्टॉल नहीं है
security-banner-absent-message = इस चरण में बंद करने के लिए कुछ नहीं है। “जारी रखें” चुनें।
security-banner-off-message = अपना सेटअप देखने और Atlas इंस्टॉल करने के लिए “जारी रखें” चुनें।
security-banner-on-title = Windows सुरक्षा में एंटीवायरस सुरक्षा बंद करें
security-banner-on-message = Microsoft Defender उन बदलावों को रोक सकता है, जो Atlas करता है। “Windows सुरक्षा खोलें” चुनें और नीचे दिया गया हर स्विच बंद करें। अगर आप Microsoft Defender रखते हैं, तो इंस्टॉलेशन पूरा होने के बाद ये स्विच फिर से चालू करें।
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
security-unknown-title = उन स्विच की पुष्टि करें, जिनकी जाँच Atlas नहीं कर सका
security-unknown-message = Windows सुरक्षा में पक्का करें कि चारों स्विच बंद हैं, फिर नीचे पुष्टि करें।
security-acknowledge = मैंने Windows सुरक्षा में देख लिया है और चारों स्विच बंद हैं
security-unknown-unelevated-title = सुरक्षा जाँचने के लिए Atlas को अनुमति चाहिए
security-unknown-unelevated-message = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, ताकि वह Microsoft Defender की सेटिंग्स जाँच सके।
# The four switches, named as Windows Security names them.
protection-tamper = छेड़छाड़ से सुरक्षा
protection-tamper-why = इसे बंद करें, ताकि जब Atlas, Defender की सुरक्षा सेटिंग्स बदले, तो Defender उसे न रोके।
protection-realtime = रीयल-टाइम सुरक्षा
protection-realtime-why = इसे बंद करें, ताकि स्कैन करते समय Defender, Atlas की इंस्टॉलेशन फ़ाइलों को ब्लॉक न करे।
protection-cloud = क्लाउड-आधारित सुरक्षा
protection-cloud-why = इसे बंद करें, ताकि ऑनलाइन ख़तरों की जाँच Atlas की इंस्टॉलेशन फ़ाइलों को ब्लॉक न करे।
protection-samples = स्वचालित नमूना सबमिशन
protection-samples-why = Defender को Atlas की फ़ाइलें विश्लेषण के लिए अपने-आप Microsoft को भेजने से रोकें।

## Step 4: Install

# Accessible name of the progress bar.
install-progress = इंस्टॉलेशन की प्रगति
# The installation's progress shown beside the bar. $percent is a whole number from 0 to 99.
install-percent = { $percent }%
outcome-succeeded-title = Atlas इंस्टॉल हो गया है
outcome-lost-title = इंस्टॉलेशन के नतीजे की पुष्टि नहीं हो सकी
outcome-failed-title = इंस्टॉलेशन पूरा नहीं हुआ
outcome-requirements = आपका PC इंस्टॉलेशन की आवश्यकताएँ पूरी नहीं करता। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। तैयारी पर वापस जाकर जाँच दोबारा चलाएँ।
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
outcome-requirements-resumed = आपका PC इंस्टॉलेशन की आवश्यकताएँ पूरी नहीं करता, इसलिए यह प्रयास रुक गया। पिछले प्रयास में पहले ही बदलाव शुरू हो चुके थे। तैयारी पर वापस जाकर जाँच दोबारा चलाएँ।
outcome-not-elevated = Atlas के पास व्यवस्थापक की अनुमति नहीं थी। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। Atlas को व्यवस्थापक के रूप में दोबारा खोलें, फिर कोशिश करें।
outcome-not-elevated-resumed = Atlas के पास व्यवस्थापक की अनुमति नहीं थी, इसलिए यह प्रयास रुक गया। पिछले प्रयास में पहले ही बदलाव शुरू हो चुके थे। Atlas को व्यवस्थापक के रूप में दोबारा खोलें, फिर कोशिश करें।
# The installer's live check found Windows or Store updates unfinished. Get ready offers the
# update check again; "अपडेट जाँचें और इंस्टॉल करें" is prepare-start, its button in that state.
outcome-preparation-stale = Atlas पुष्टि नहीं कर सका कि Windows और Store ऐप अप टू डेट हैं, इसलिए Windows में कोई बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। तैयारी पर वापस जाएँ और “अपडेट जाँचें और इंस्टॉल करें” चुनें।
outcome-preparation-stale-resumed = Atlas पुष्टि नहीं कर सका कि Windows और Store ऐप अप टू डेट हैं, इसलिए यह प्रयास रुक गया, लेकिन पिछले प्रयास में पहले ही बदलाव शुरू हो चुके थे। तैयारी पर वापस जाएँ और “अपडेट जाँचें और इंस्टॉल करें” चुनें।
outcome-failed-preflight = कोई भी बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। आप फिर कोशिश कर सकते हैं। अगर यह फिर रुक जाए, तो “रिपोर्ट भेजें” चुनें।
outcome-failed-staging = फ़ाइलें तैयार करते समय, Windows में कोई बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। आप फिर कोशिश कर सकते हैं। अगर यह फिर रुक जाए, तो “रिपोर्ट भेजें” चुनें।
outcome-failed-applying = हो सकता है कि कुछ बदलाव पहले ही हो चुके हों। आप फिर कोशिश कर सकते हैं। अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में वे सुरक्षा स्विच फिर से चालू करें, जो आपने बंद किए थे (अगर वे अभी भी उपलब्ध हों)।
outcome-failed-resumed = यह प्रयास शुरुआत में ही रुक गया, लेकिन पिछले प्रयास में पहले ही बदलाव शुरू हो चुके थे। आप फिर कोशिश कर सकते हैं। अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में वे सुरक्षा स्विच फिर से चालू करें, जो आपने बंद किए थे (अगर वे अभी भी उपलब्ध हों)।
outcome-not-started = इंस्टॉलर समय पर शुरू नहीं हुआ। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। आप फिर कोशिश कर सकते हैं।
outcome-lost = इंस्टॉलर कोई नतीजा बताए बिना रुक गया, और हो सकता है कि कुछ बदलाव पहले ही हो चुके हों। आप फिर कोशिश कर सकते हैं। अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में वे सुरक्षा स्विच फिर से चालू करें, जो आपने बंद किए थे (अगर वे अभी भी उपलब्ध हों)।
restart-now-message = Atlas का सेटअप पूरा करने के लिए Windows रीस्टार्ट हो रहा है।
restart-countdown = Atlas का सेटअप पूरा करने के लिए Windows { $seconds } सेकंड में रीस्टार्ट होगा। पहले अपना काम सहेजने के लिए “बाद में रीस्टार्ट करें” चुनें।
restart-stopped = स्वचालित रीस्टार्ट रद्द कर दिया गया है। अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
restart-needed = अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
restart-dont-now = बाद में रीस्टार्ट करें
restart-now = अभी रीस्टार्ट करें
restart-start-failed = Atlas आपका PC रीस्टार्ट नहीं कर सका। अपना काम सहेजें, फिर स्टार्ट मेनू से इसे रीस्टार्ट करें। विवरण: { $error }
preflight-title = इंस्टॉलेशन शुरू नहीं हुआ
preflight-invalid-options = Atlas इन सेटअप विकल्पों का इस्तेमाल नहीं कर सका। “आपके विकल्प” पर वापस जाकर उन्हें देखें, फिर कोशिश करें। विवरण: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = पिछली जाँच के बाद आपके PC की स्थिति बदल गई है। फिर कोशिश करने से पहले इन्हें ठीक करें। { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Windows सुरक्षा: { $summary }।
preflight-busy = Atlas की एक और विंडो इंस्टॉलेशन शुरू कर रही है। थोड़ा इंतज़ार करें, फिर “Atlas इंस्टॉल करें” दोबारा चुनें।
# Shown with the home-start-over button.
preflight-taken-over = Atlas की एक दूसरी विंडो अब इस सेटअप का इस्तेमाल कर रही है, इसलिए इंस्टॉलेशन शुरू नहीं हुआ। उसी विंडो में जारी रखें, या यहाँ फिर से सेटअप करने के लिए “नए सिरे से शुरू करें” चुनें।
preflight-record-unreadable = Atlas यह जाँच नहीं सका कि पिछला इंस्टॉलेशन अभी भी चल रहा है या नहीं, इसलिए उसने नया इंस्टॉलेशन शुरू नहीं किया। आगे क्या करना है, यह जानने के लिए तैयारी पर वापस जाएँ। विवरण: { $error }
preflight-refused = इंस्टॉलर शुरू नहीं हो सका। इंस्टॉलेशन से कोई बदलाव नहीं हुआ। फिर कोशिश करने के लिए “Atlas इंस्टॉल करें” चुनें। अगर ऐसा बार-बार हो, तो “रिपोर्ट भेजें” चुनें। विवरण: { $error }
# Instead of preflight-refused when retrying an installation an earlier attempt had already started applying.
preflight-refused-resumed = इंस्टॉलर शुरू नहीं हो सका, इसलिए यह प्रयास रुक गया। पिछले प्रयास में पहले ही बदलाव शुरू हो चुके थे। फिर कोशिश करने के लिए “Atlas इंस्टॉल करें” चुनें। अगर ऐसा बार-बार हो, तो “रिपोर्ट भेजें” चुनें। विवरण: { $error }
go-to-ready = तैयारी पर वापस जाएँ
# Button on the preflight banner when the setup choices could not be used; leads to step 2.
go-to-options = “आपके विकल्प” पर वापस जाएँ
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = “इंस्टॉल” पर वापस जाएँ
output-problem-title = इंस्टॉलेशन की प्रगति नहीं पढ़ी जा सकी
output-problem-message = Atlas लॉग नहीं पढ़ सका। इसका मतलब यह नहीं कि इंस्टॉलेशन रुक गया है। अपना PC चालू रखें और लॉग फ़ाइल खोलकर देखें। विवरण: { $error }
install-elevate-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
install-no-package-title = पहले अपनी इंस्टॉलेशन फ़ाइलें चुनें
install-no-package-message = Atlas डाउनलोड करने या सहेजा हुआ Atlas पैकेज (.apbx) खोलने के लिए तैयारी पर वापस जाएँ।
# Tester build variant of install-no-package-message.
install-no-package-bundled-message = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज तैयार करने के लिए तैयारी पर वापस जाएँ।
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = पहले तैयारी पूरी करें
install-not-ready-message = इंस्टॉल करने से पहले Atlas को आपके PC की जाँच और Windows का अपडेट पूरा करना होगा।
install-security-title = इंस्टॉल करने से पहले एंटीवायरस सुरक्षा जाँचें
install-security-reading = चारों सुरक्षा स्विच की फिर से जाँच हो रही है।
install-security-message = { $summary }। Windows सुरक्षा खोलें और इंस्टॉल करने से पहले पक्का करें कि चारों स्विच बंद हैं।
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
summary-copy-command-a11y = इंस्टॉलेशन कमांड कॉपी करें
summary-command-unavailable = इंस्टॉलेशन कमांड तैयार नहीं हो सकी। विवरण: { $error }
summary-not-chosen = अभी कोई विकल्प नहीं चुना गया
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = { $title } बदलें
footer-still-checking = इंस्टॉलेशन की तैयारी हो रही है
footer-fix-items = जारी रखने के लिए “PC की जाँच” में चिह्नित समस्याएँ ठीक करें
footer-need-package = जारी रखने के लिए Atlas डाउनलोड करें या Atlas पैकेज खोलें
# Tester build variant of footer-need-package.
footer-need-package-bundled = जारी रखने के लिए साथ में दिया गया Atlas पैकेज तैयार करें
footer-reading-security = सुरक्षा स्विच की जाँच हो रही है
footer-security-pending = जारी रखने के लिए चारों स्विच बंद करें
footer-security-confirm = जारी रखने के लिए उन स्विच की पुष्टि करें, जिनकी जाँच Atlas नहीं कर सका
footer-install-ready = पहले अपना काम सहेजें और अपने ऐप बंद करें
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
installing-restart-auto = इंस्टॉलेशन पूरा होने पर आपका PC अपने-आप रीस्टार्ट हो जाएगा। उससे पहले दूसरे ऐप में अपना काम सहेज लें।

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } इंस्टॉल हो गया है
installed-title = Atlas इंस्टॉल हो गया है
installed-ready = सब हो गया। आपका PC अब Atlas के साथ इस्तेमाल के लिए तैयार है।
installed-security-message = आपने Microsoft Defender रखा है, लेकिन इसकी कुछ सुरक्षा सुविधाएँ अभी भी बंद हैं। Windows सुरक्षा खोलें और पक्का करें कि ये चालू हैं: { $switches }।
installed-defender-removed-title = Microsoft Defender हटा दिया गया है
installed-defender-removed-message = जब तक आप कोई दूसरा एंटीवायरस ऐप इंस्टॉल नहीं करते, तब तक आपके PC में एंटीवायरस सुरक्षा नहीं होगी। SmartScreen भी हटा दिया गया है, इसलिए अपरिचित ऐप या डाउनलोड खोलने से पहले Windows आपको चेतावनी नहीं देगा।
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing. Its title is security-banner-absent-title; "Report a problem" is
# home-report-problem, its button.
installed-defender-missing-message = आपने Microsoft Defender रखना चुना था, लेकिन यह अब मौजूद नहीं है। अगर आप कोई दूसरा एंटीवायरस ऐप इस्तेमाल नहीं करते, तो अपने PC की सुरक्षा के लिए एक इंस्टॉल करें। अगर आपने Defender ख़ुद नहीं हटाया है, तो “समस्या रिपोर्ट करें” चुनें।

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
settings-language-system-selected = { settings-language-system } ({ $language })
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = Windows के अनुसार: { $language }
# A short tag under each language that is translated but not yet reviewed by a native speaker.
settings-language-preview-tag = पूर्वावलोकन
# Under the language list, once, explaining the Preview tag.
settings-language-preview-note = पूर्वावलोकन अनुवादों की अभी किसी मूल भाषी ने समीक्षा नहीं की है।
# One-line strip under the title bar while a preview translation is in use, until the
# user dismisses it (common-dismiss names the close button). $language is the
# language's own name; the two links follow the sentence on the same line.
preview-notice = { $language } एक पूर्वावलोकन अनुवाद है और इसमें ग़लतियाँ हो सकती हैं।
preview-notice-switch = अंग्रेज़ी पर स्विच करें
preview-notice-language = भाषा बदलें
# $tag is a language tag (text).
settings-language-unavailable = Atlas के इस संस्करण में { $tag } उपलब्ध नहीं है। फ़िलहाल अंग्रेज़ी दिखाई जा रही है, और आपकी भाषा की पसंद सहेजी गई है।
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas अभी आपकी Windows प्रदर्शन भाषाओं ({ $languages }) का समर्थन नहीं करता। फ़िलहाल अंग्रेज़ी दिखाई जा रही है।
settings-language-windows-unavailable = आपकी Windows प्रदर्शन भाषा की जाँच नहीं हो सकी। Atlas फ़िलहाल अंग्रेज़ी इस्तेमाल कर रहा है। विवरण: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = संख्याएँ, तारीख़ें और समय आपके Windows क्षेत्रीय प्रारूप ({ $locale }) के अनुसार दिखते हैं।
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = संख्याएँ आपके Windows क्षेत्रीय प्रारूप ({ $locale }) के अनुसार दिखती हैं। तारीख़ें और समय एक मानक प्रारूप में दिखते हैं, क्योंकि Atlas अभी दाएँ से बाएँ लिखा जाने वाला टेक्स्ट नहीं दिखा सकता।
settings-language-contribute = GitHub पर Atlas के अनुवाद में मदद करें
settings-restart-label = इंस्टॉलेशन के बाद मेरा PC अपने-आप रीस्टार्ट करें
settings-restart-locked = इंस्टॉलेशन पूरा होने के बाद आप इसे बदल सकते हैं।
settings-restart-description = यह चालू होने पर, इंस्टॉलेशन पूरा होने के एक मिनट के अंदर आपका PC रीस्टार्ट हो जाता है, जिससे आपके खुले ऐप बंद हो जाते हैं। इंस्टॉल करने से पहले अपना काम सहेजें।
settings-help = मदद और फ़ीडबैक
settings-about = परिचय
settings-about-app = Atlas Manager
settings-about-licence = लाइसेंस
settings-about-licence-value = GPL-3.0, मुक्त और ओपन सोर्स
settings-view-source = GitHub पर सोर्स कोड देखें
# Link that opens the third-party licence notices.
settings-view-licences = लाइसेंस सूचनाएँ देखें
# Under the links when Windows could not open the notices.
settings-licences-failed = लाइसेंस सूचनाएँ नहीं खुल सकीं। फिर कोशिश करें, या उन्हें GitHub पर सोर्स कोड में देखें।
settings-open-data-folder = ऐप फ़ोल्डर खोलें

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = हाइबरनेशन के दौरान आपका सत्र सहेजने में इस्तेमाल होने वाला डिस्क स्पेस ख़ाली करता है। हाइबरनेट और तेज़ स्टार्टअप (Fast Startup) उपलब्ध नहीं रहेंगे।
consequence-disable-power-saving = पावर बचाने वाली सुविधाएँ बंद कर देता है। आपका PC ज़्यादा बिजली ले सकता है, ज़्यादा गर्म हो सकता है और बैटरी कम समय चल सकती है।
consequence-disable-core-isolation = मेमोरी अखंडता (Memory integrity) समेत Windows की सुरक्षा की एक अतिरिक्त परत बंद कर देता है। इससे सुरक्षा कम होती है और इसकी ज़रूरत वाले ऐप या गेम पर असर पड़ सकता है।
consequence-remove-snipping-tool = स्क्रीनशॉट लेने और स्क्रीन रिकॉर्ड करने वाला Windows ऐप हटा देता है।
consequence-uninstall-edge = Microsoft Edge ब्राउज़र हटा देता है। पक्का करें कि आपके पास कोई दूसरा ब्राउज़र है, या नीचे एक चुनें।
# Instead of consequence-uninstall-edge when Atlas is installed on this PC, which has the
# user's Edge data. "choose one below" refers to the browser choice under it.
consequence-uninstall-edge-data = Microsoft Edge को हटा देता है और इस PC पर आपके Edge बुकमार्क, इतिहास और सहेजे गए पासवर्ड मिटा देता है। जो कुछ आपके Microsoft खाते में सिंक नहीं हुआ है, वह खो जाएगा। पक्का करें कि आपके पास कोई दूसरा ब्राउज़र है, या नीचे एक चुनें।
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = इस PC पर आपके Edge बुकमार्क, इतिहास और सहेजे गए पासवर्ड मिटा देता है।
consequence-install-another-browser = नीचे कोई ब्राउज़र चुनें, Atlas उसे आपके लिए इंस्टॉल कर देगा।
consequence-install-toolbox = अपनी Atlas सेटिंग्स सँभालने में मदद के लिए Atlas Toolbox जोड़ें। Toolbox अभी बीटा में है, इसलिए कुछ सुविधाएँ अधूरी हो सकती हैं।
consequence-install-eclean = AtlasOS की टीम का रखरखाव टूल, जो सेटअप के बाद PC को व्यवस्थित रखने में मदद करता है। बेकार फ़ाइलों और स्टार्टअप ऐप्स की समीक्षा करें। खाता और इंटरनेट कनेक्शन ज़रूरी है।

# Introduction on the home page before Atlas is installed.
home-intro = Atlas बैकग्राउंड गतिविधि और ध्यान भटकाने वाली चीज़ें कम करने के लिए Windows में बदलाव करता है। अपने ऐप और फ़ाइलें जोड़ने से पहले, Atlas को नए सिरे से इंस्टॉल किए गए Windows पर इंस्टॉल करें।

## ISO creation (Beta)
iso-home-title = Windows इंस्टॉलेशन मीडिया
iso-home-description = Atlas वाली Windows इंस्टॉलेशन फ़ाइल (ISO) बनाएँ, फिर उससे इस PC या किसी दूसरे PC पर Windows दोबारा इंस्टॉल करें।
iso-open = Atlas ISO बनाएँ
iso-title = Atlas ISO बनाएँ
iso-beta = बीटा
iso-beta-description = PC पर इस्तेमाल करने से पहले ISO को वर्चुअल मशीन में जाँचें। Windows इंस्टॉल करने से पहले अपनी फ़ाइलों का बैकअप लें।
iso-admin-description = आपका Windows ISO पढ़ने और नया ISO बनाने के लिए Atlas को व्यवस्थापक की अनुमति चाहिए। “व्यवस्थापक के रूप में दोबारा खोलें” चुनें, फिर जब Windows पूछे, तो “हाँ” चुनें।
iso-files-description = Atlas, Windows 11 ISO की एक कॉपी बनाकर उसमें Atlas जोड़ता है, ताकि आप Windows दोबारा इंस्टॉल कर सकें। Microsoft से डाउनलोड किया गया Windows 11 ISO चुनें, नवीनतम Atlas पैकेज डाउनलोड करें या पहले से मौजूद पैकेज (.apbx) चुनें, फिर चुनें कि नया ISO कहाँ सहेजना है।
# Tester build: no package picker.
iso-files-description-bundled = Atlas, Windows 11 ISO की एक कॉपी बनाकर उसमें इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज जोड़ता है। Microsoft से डाउनलोड किया गया Windows 11 ISO चुनें, फिर चुनें कि नया ISO कहाँ सहेजना है।
iso-source = Windows ISO
iso-source-download = Microsoft से Windows 11 डाउनलोड करें
# $minimum is the first Atlas version that can be used (text, such as 0.6.0).
iso-package = Atlas पैकेज ({ $minimum } या उससे नया)
iso-output = नया ISO यहाँ सहेजें
iso-no-file = कोई फ़ाइल नहीं चुनी गई
iso-browse = ब्राउज़ करें
iso-save-as = इस रूप में सहेजें
# Accessible name of the Browse or Save as button beside a file field: $action is
# that button's text and $field the field's label.
iso-pick-a11y = { $action }: { $field }
iso-inspect = फ़ाइलें जाँचें
iso-mode-title = आप Atlas को कैसे सेट अप करना चाहते हैं?
iso-mode-interactive = साइन इन करने के बाद Atlas के विकल्प चुनें
iso-mode-interactive-description = साइन इन करने के बाद Atlas खुलता है और अपडेट करने, अपने विकल्प चुनने और Atlas इंस्टॉल करने में आपकी मदद करता है।
iso-mode-before = Atlas के विकल्प अभी चुनें
iso-mode-before-description = Atlas आपके विकल्प ISO में सहेजता है। साइन इन करने के बाद Atlas खुलता है और अपडेट पूरे करने में आपकी मदद करता है, फिर आप इन विकल्पों के साथ Atlas इंस्टॉल करते हैं।
iso-package-unsupported-title = नया Atlas पैकेज चुनें
# "साइन इन करने के बाद Atlas के विकल्प चुनें" is iso-mode-interactive.
iso-package-unsupported = यह Atlas पैकेज Atlas के विकल्प ISO में नहीं सहेज सकता। कोई नया पैकेज चुनें, या “साइन इन करने के बाद Atlas के विकल्प चुनें” चुनें।
# Shown when Check files refuses the Atlas package; $minimum as for iso-package.
iso-failed-package-unsupported = इस Atlas पैकेज से ISO नहीं बनाया जा सकता। Atlas { $minimum } या उससे नए संस्करण का पैकेज चुनें।
# Tester build: the bundled Atlas package cannot be swapped, so the only way on is the after-sign-in mode.
iso-package-unsupported-bundled-title = इस ISO में Atlas के विकल्प सहेजे नहीं जा सकते
# "साइन इन करने के बाद Atlas के विकल्प चुनें" is iso-mode-interactive.
iso-package-unsupported-bundled = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज ISO सेटअप का समर्थन नहीं करता। इसकी जगह “साइन इन करने के बाद Atlas के विकल्प चुनें” चुनें।
iso-atlas-options = Atlas के विकल्प
iso-review = ISO की समीक्षा करें
iso-review-description = ISO बनाने से इस PC पर कुछ भी इंस्टॉल नहीं होता और आपके मूल ISO में कोई बदलाव नहीं होता। इसके बाद Atlas नया ISO किसी USB ड्राइव पर डाल सकता है, ताकि आप उससे Windows दोबारा इंस्टॉल कर सकें।
iso-review-files = फ़ाइलें
iso-step-windows = Windows सेटअप
iso-step-review = समीक्षा
iso-review-package = Atlas पैकेज
iso-review-output = नया ISO
iso-review-editions = संस्करण
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = खाते का नाम
iso-review-target = लक्षित PC
iso-review-drivers = ड्राइवर
iso-create = ISO बनाएँ
iso-progress-title = आपका ISO बन रहा है
iso-stage-inspect = आपके Windows ISO की जाँच हो रही है
iso-stage-copy = Windows की फ़ाइलें कॉपी हो रही हैं
iso-stage-add-atlas = Atlas जोड़ा जा रहा है
iso-stage-master = ISO फ़ाइल लिखी जा रही है
iso-stage-verify = नए ISO की जाँच हो रही है
iso-stage-cleanup = अंतिम चरण पूरे हो रहे हैं
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = जारी है
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = विफल
iso-stage-status-not-started = शुरू नहीं हुआ
iso-progress-description = Atlas खुला रखें। बड़ी इमेज तैयार होने में कुछ समय लग सकता है।
iso-cancel = बनाना रद्द करें
iso-cancelling = रद्द करने के लिए सुरक्षित चरण का इंतज़ार है
iso-cancelled = ISO बनाना रद्द कर दिया गया
iso-cancelled-description = आपके मूल ISO में कोई बदलाव नहीं हुआ है। अगर कुछ अस्थायी फ़ाइलें बची रह गई हों, तो वे कहाँ हैं, यह देखने के लिए “लॉग फ़ोल्डर खोलें” चुनें।
iso-complete = आपका ISO तैयार है
iso-complete-description = ISO बनाने की सुविधा अभी बीटा में है, इसलिए पहले ISO को वर्चुअल मशीन में जाँचें। फिर “इंस्टॉलेशन USB बनाएँ” चुनें, और Windows दोबारा इंस्टॉल करने से पहले अपनी फ़ाइलों का बैकअप लें।
iso-open-folder = फ़ोल्डर में दिखाएँ
iso-failed = ISO बनाना पूरा नहीं हो सका
iso-failed-description = पक्का करें कि आपकी फ़ाइलें अभी भी उसी जगह हैं, जहाँ से आपने उन्हें चुना था, और जिस ड्राइव पर आप सहेज रहे हैं, वह कनेक्ट है, फिर “ISO बनाएँ” चुनें। अगर यह बार-बार विफल हो, तो “रिपोर्ट भेजें” चुनें।
# Title while the Check files step fails; the messages below say why.
iso-check-failed = फ़ाइलों की जाँच नहीं हो सकी
iso-check-failed-description = पक्का करें कि ISO और Atlas पैकेज अभी भी उसी जगह हैं, जहाँ से आपने उन्हें चुना था, और उनका डाउनलोड पूरा हो चुका है, फिर “फ़ाइलें जाँचें” चुनें। अगर यह बार-बार विफल हो, तो “रिपोर्ट भेजें” चुनें।
# Title of the bar that asks for administrator permission. Its message is iso-admin-description,
# or elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = ISO बनाने के लिए Atlas को अनुमति चाहिए
# Typed reasons reported by the image worker.
iso-failed-output-exists = इस नाम की फ़ाइल पहले से मौजूद है। “इस रूप में सहेजें” चुनें और नया फ़ाइल नाम दर्ज करें।
iso-failed-destination = Atlas नया ISO वहाँ नहीं सहेज सकता। “इस रूप में सहेजें” चुनें और इस PC पर कोई फ़ोल्डर चुनें, जैसे डाउनलोड फ़ोल्डर। नेटवर्क स्थान और FAT32 या exFAT में फ़ॉर्मैट की गई ड्राइव, जैसे कई USB ड्राइव, इस्तेमाल नहीं की जा सकतीं।
iso-failed-space = गंतव्य ड्राइव पर पर्याप्त ख़ाली जगह नहीं है। जगह ख़ाली करें, या नया ISO किसी दूसरी ड्राइव पर सहेजें।
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = इस ISO में कोई समर्थित Windows संस्करण नहीं है। Windows Home और LTSC समर्थित नहीं हैं। ऐसा ISO इस्तेमाल करें, जिसमें कोई दूसरा संस्करण हो, जैसे Pro, Education या Enterprise।
iso-failed-customised = इस ISO में पहले से कस्टम सेटअप फ़ाइलें हैं, जैसे autounattend.xml। Microsoft का बिना बदलाव वाला Windows ISO चुनें।
iso-failed-windows-unsupported = Atlas पैकेज इस Windows इमेज का समर्थन नहीं करता। Windows 11 के ऐसे संस्करण का बिना बदलाव वाला 64-बिट ISO इस्तेमाल करें, जिसका यह पैकेज समर्थन करता है।
iso-failed-network-architecture = इस PC के नेटवर्क ड्राइवर इस ISO के आर्किटेक्चर से मेल नहीं खाते। वापस जाकर “इस PC के नेटवर्क ड्राइवर शामिल करें” बंद करें, या इस PC के लिए ISO चुनें।
iso-failed-unstaged = Atlas अपना कार्य फ़ोल्डर तैयार नहीं कर सका, इसलिए कुछ भी नहीं बदला गया। दोबारा कोशिश करें। अगर यह फिर भी विफल हो, तो बग रिपोर्ट के लिए “डायग्नोस्टिक्स निर्यात करें” चुनें।
iso-failed-package-changed = फ़ाइलें जाँचने के बाद Atlas पैकेज बदल गया। “फ़ाइलें” के पास “बदलें” चुनें, फिर “फ़ाइलें जाँचें” चुनें।
iso-diagnostics = लॉग फ़ोल्डर खोलें
iso-close-title = ISO अभी बन रहा है
iso-close-message = बनाने या रद्द करने की प्रक्रिया पूरी होने तक यह विंडो खुली रखें। रद्द करने के लिए मौजूदा काम के सुरक्षित रूप से रुकने का इंतज़ार किया जाएगा।
iso-keep-open = खुला रखें
prepare-title = Windows और Store ऐप अपडेट करें
prepare-description = इंस्टॉल करने से पहले Atlas इन्हें अपडेट करता है: Windows, Microsoft Store और आपके Store ऐप। नोटपैड, पेंट या Windows टर्मिनल जैसे खुले हुए Store ऐप अपडेट होते समय बंद हो सकते हैं, इसलिए पहले उनमें अपना काम सहेज लें। आपके PC को रीस्टार्ट भी करना पड़ सकता है।
prepare-complete = Atlas को Windows या Store का ऐसा कोई और अपडेट नहीं मिला, जिसे इंस्टॉल करना बाकी हो।
prepare-reboot-title = जारी रखने के लिए अपना PC रीस्टार्ट करें
prepare-reboot = अपडेट इंस्टॉल करना पूरा करने के लिए आपके PC को रीस्टार्ट करना होगा। Atlas अब तक के आपके विकल्प सहेज लेगा और साइन इन करने के बाद फिर से खुल जाएगा।
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
prepare-reboot-reasons = अपडेट इंस्टॉल करना पूरा करने के लिए आपके PC को रीस्टार्ट करना होगा ({ $reasons })। Atlas अब तक के आपके विकल्प सहेज लेगा और साइन इन करने के बाद फिर से खुल जाएगा।
# Under the restart message: the button restarts Windows without a countdown.
prepare-reboot-save-work = पहले अपना काम सहेजें और अपने ऐप बंद करें। “रीस्टार्ट करें और आगे बढ़ें” चुनते ही आपका PC रीस्टार्ट हो जाएगा।
# Shown instead of another restart when Windows asks for one again right after restarting.
prepare-restart-persists = आपका PC रीस्टार्ट हुआ, लेकिन Windows अब भी बता रहा है कि उसे रीस्टार्ट की ज़रूरत है ({ $reasons }), इसलिए दोबारा रीस्टार्ट करने से शायद कोई फ़ायदा नहीं होगा। “Windows Update खोलें” चुनें और वहाँ जो कुछ भी प्रतीक्षा में है, उसे पूरा करें, उसके बाद “फिर कोशिश करें” चुनें। अगर कुछ भी प्रतीक्षा में नहीं है, तो “रिपोर्ट भेजें” चुनें।
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)" and "Windows needs to restart
# to finish earlier changes (…)"; keep them short and lower case where the language allows.
prepare-reason-servicing = Windows सर्विसिंग
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = बदले जाने की प्रतीक्षा में फ़ाइलें
prepare-reason-update-agent = Windows Update सेवा
prepare-reason-unknown = कारण नहीं बताया गया
prepare-failed = “फिर कोशिश करें” चुनें। अगर यह फिर से विफल हो, तो बाकी अपडेट Windows Update या Microsoft Store में पूरे करें, या “रिपोर्ट भेजें” चुनें।
prepare-failed-title = कुछ अपडेट पूरे नहीं हो सके
# The update run ended without writing any result, for example after Atlas was closed
# while it ran. "फिर कोशिश करें" is common-try-again, the button beside it.
prepare-ended-unconfirmed = अपडेट की प्रक्रिया कोई नतीजा बताने से पहले ही रुक गई, इसलिए Atlas पुष्टि नहीं कर सकता कि Windows और Store ऐप अप टू डेट हैं। अपडेट की जाँच करने के लिए “फिर कोशिश करें” चुनें।
prepare-unconfirmed-title = अपडेट के नतीजे की पुष्टि नहीं हो सकी
# "अपडेट जाँचें और इंस्टॉल करें" is prepare-start, its button in this state.
prepare-cancelled = अपडेट करना रुक गया है। हो सकता है कि कुछ अपडेट पहले ही इंस्टॉल हो चुके हों। जारी रखने से पहले, अपडेट पूरे करने के लिए “अपडेट जाँचें और इंस्टॉल करें” चुनें।
prepare-windows-search = Windows अपडेट जाँचे जा रहे हैं…
prepare-windows-download = Windows अपडेट डाउनलोड हो रहे हैं…
prepare-windows-install = Windows अपडेट इंस्टॉल हो रहे हैं…
prepare-store-search = Microsoft Store की जाँच हो रही है…
prepare-store-install = Microsoft Store और उसके ऐप अपडेट हो रहे हैं…
prepare-stop-description = मौजूदा चरण पूरा होने के बाद Atlas अपडेट करना रोक देगा। तब तक Atlas खुला रखें।
prepare-stop = अपडेट करना रोकें
prepare-restart = रीस्टार्ट करें और आगे बढ़ें
prepare-start = अपडेट जाँचें और इंस्टॉल करें
# Under the preparation button while it is unavailable. $check is the check-supported-build title.
prepare-blocked-source = उपलब्ध नहीं है, क्योंकि यह इंस्टॉलेशन जारी नहीं रह सकता। पेज के ऊपर दिया गया संदेश देखें।
prepare-needs-build-check = “PC की जाँच” में { $check } ठीक होने पर उपलब्ध होगा।
# Under the preparation button, and under the Administrator check, while the installation files are still downloading or unpacking.
prepare-wait-for-package = इंस्टॉलेशन फ़ाइलें तैयार होने पर उपलब्ध होगा।
iso-username = स्थानीय खाते का नाम
iso-account-description = Windows सेटअप इस नाम से एक स्थानीय खाता बनाता है, इसलिए आपको Microsoft खाते की ज़रूरत नहीं है। पहली बार साइन इन करने पर Windows आपसे पासवर्ड चुनने को कहेगा।
iso-username-placeholder = आपका नाम
iso-account-empty = जारी रखने के लिए स्थानीय खाते का नाम दर्ज करें
iso-account-invalid = अधिकतम 20 अक्षर इस्तेमाल करें, शुरुआत या अंत में स्पेस न रखें, और इनमें से कोई चिह्न न रखें: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = नाम के अंत में बिंदु (.) नहीं हो सकता।
iso-account-reserved = Windows इस नाम का इस्तेमाल एक अंतर्निहित खाते के लिए करता है। कोई दूसरा नाम चुनें।
iso-privacy-defaults = यह ISO, Windows सेटअप में लाइसेंस, Microsoft खाते और गोपनीयता वाली स्क्रीन छोड़ देता है। साथ ही, यह वैकल्पिक डेटा शेयरिंग और व्यक्तिगत ऑफ़र बंद कर देता है।
prepare-drivers = ड्राइवर कैसे इंस्टॉल करने हैं?
prepare-drivers-auto = Windows Update से ड्राइवर प्राप्त करें
prepare-drivers-auto-detail = Windows आपके हार्डवेयर के लिए ड्राइवर ढूँढेगा। अधिकांश PC के लिए यही सुझाव है।
prepare-drivers-manual = ड्राइवर ख़ुद इंस्टॉल करें
prepare-drivers-manual-detail = Windows Update ड्राइवर इंस्टॉल नहीं करेगा, इसलिए आपको उन्हें अपने PC या डिवाइस के निर्माता से लेना होगा। पहले से इंस्टॉल ड्राइवर बने रहेंगे।
prepare-drivers-description = ड्राइवर की मदद से Windows आपके हार्डवेयर, जैसे ग्राफ़िक्स, साउंड और Wi-Fi, का इस्तेमाल कर पाता है। अगर आप अपडेट करने के बाद इसे बदलते हैं, तो Atlas को अपडेट की जाँच दोबारा करनी होगी।
prepare-network-needed = अपडेट के लिए ऐसा इंटरनेट कनेक्शन चाहिए, जो मीटर्ड न हो। Wi-Fi या ईथरनेट से कनेक्ट करें, उसके बाद “फिर कोशिश करें” चुनें। अगर आपको कोई Wi-Fi नेटवर्क नहीं दिख रहा, तो पहले अपना नेटवर्क ड्राइवर इंस्टॉल करें।
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows के अनुसार इस नेटवर्क पर इंटरनेट उपलब्ध नहीं है। अगर नेटवर्क साइन इन करने को कहे, तो साइन इन करें, या अपना राउटर और कोई भी DNS या फ़ायरवॉल फ़िल्टरिंग जाँचें, फिर कोशिश करें।
# "मीटर्ड कनेक्शन" is the switch's name in Windows network settings.
prepare-network-metered = यह कनेक्शन मीटर्ड है या इस पर डेटा सीमा लगी है। ऐसे नेटवर्क से कनेक्ट करें जो मीटर्ड न हो, या नेटवर्क सेटिंग में “मीटर्ड कनेक्शन” बंद करें, फिर कोशिश करें।
prepare-network-settings = नेटवर्क सेटिंग खोलें
iso-target-title = किस PC पर Windows दोबारा इंस्टॉल करना है?
iso-target-this = इस PC पर
# Under This PC (iso-target-this), before it's chosen.
iso-target-this-description = Atlas इस PC के Wi-Fi और ईथरनेट ड्राइवर ISO में जोड़ सकता है, ताकि दोबारा इंस्टॉल होते ही Windows इंटरनेट से जुड़ सके।
iso-target-other = किसी दूसरे PC पर
iso-copy-network = इस PC के नेटवर्क ड्राइवर शामिल करें
iso-network-detail = Windows इंस्टॉल करते समय इस PC के Wi-Fi और ईथरनेट ड्राइवर फिर से इस्तेमाल होंगे। दोबारा इंस्टॉल करने के बाद Wi-Fi से फिर कनेक्ट करना होगा।
iso-network-source = नेटवर्क ड्राइवर का स्रोत
iso-network-installed = इंस्टॉल किए हुए ड्राइवर इस्तेमाल करें
iso-network-updated = पहले Windows Update में जाँचें
iso-network-updated-detail = Windows Update से हार्डवेयर के लिए उपलब्ध ड्राइवर डाउनलोड करता है और इंस्टॉल किए हुए ड्राइवर बैकअप के तौर पर रखता है। इसके लिए गैर-मीटर्ड कनेक्शन चाहिए।
iso-stage-network-drivers = नेटवर्क ड्राइवर तैयार किए जा रहे हैं
iso-network-failed = नेटवर्क ड्राइवर तैयार नहीं हो सके। डायग्नोस्टिक्स देखें या वापस जाकर नेटवर्क ड्राइवर का विकल्प बदलें।
# Under iso-complete when Include this PC's network drivers was chosen but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = इस PC के नेटवर्क एडेप्टर Windows के साथ आने वाले ड्राइवर इस्तेमाल करते हैं, इसलिए उन्हें ISO में शामिल करने की ज़रूरत नहीं है।
iso-mode-desktop = डेस्कटॉप खोलने से पहले सेटअप पूरा करें
iso-mode-desktop-description = Atlas आपके विकल्प ISO में सहेजता है। साइन इन करने के बाद, Windows डेस्कटॉप खुलने से पहले ही Atlas अपडेट और इंस्टॉलेशन पूरा कर देता है।
desktop-setup-description = अपने PC का सेटअप पूरा करें। Atlas के लिए आपके विकल्प सहेजे गए हैं; ज़रूरत पड़ने पर आप Windows पर लौट सकते हैं।
desktop-setup-exit = Windows में जारी रखें

# Windows installation USB (Beta)
usb-title = इंस्टॉलेशन USB बनाएँ
usb-existing = मौजूदा ISO से USB बनाएँ
usb-description = किसी ISO को USB ड्राइव पर डालें, ताकि आप उससे Windows दोबारा इंस्टॉल कर सकें। Windows के साथ Atlas भी इंस्टॉल करने के लिए, Atlas से बनाया गया ISO इस्तेमाल करें।
usb-choose-iso = ISO चुनें
usb-drive = USB ड्राइव
# $min and $max are formatted numbers (text), in gigabytes and terabytes.
usb-empty = कोई USB ड्राइव नहीं मिली। कम से कम { $min } GB की USB ड्राइव कनेक्ट करें, फिर “रीफ़्रेश करें” चुनें। { $max } TB से बड़ी ड्राइव, ऐसी ड्राइव जिन पर लिखा नहीं जा सकता, और वह ड्राइव जिससे Windows चल रहा है, यहाँ नहीं दिखाई जातीं।
usb-refresh = रीफ़्रेश करें
# Shown when the drive list could not be read.
usb-scan-failed = जाँचें कि ड्राइव कनेक्ट है, फिर “रीफ़्रेश करें” चुनें। विवरण के लिए “लॉग फ़ोल्डर खोलें” चुनें।
usb-scan-failed-title = USB ड्राइव की सूची नहीं पढ़ी जा सकी
# Parts of a drive's detail line, joined by usb-detail-separator; empty parts are left out.
# $size is a formatted number of gigabytes (text); $volumes and $serial are text.
usb-drive-size = { $size } GB
usb-drive-serial = सीरियल नंबर: { $serial }
usb-detail-separator = { " · " }
usb-review = USB की समीक्षा करें
usb-erase-title = इस USB ड्राइव को मिटाएँ?
usb-erase-description = { $drive } ({ $size } GB) पर मौजूद सब कुछ हमेशा के लिए मिट जाएगा, जिसमें सभी फ़ाइलें और पार्टिशन शामिल हैं। आप जो कुछ भी रखना चाहते हैं, उसे पहले किसी दूसरी ड्राइव पर कॉपी कर लें। आपकी ISO फ़ाइल बनी रहेगी।
usb-layout = Atlas ड्राइव का अधिकतम 32 GB इस्तेमाल करता है और बाकी जगह ख़ाली छोड़ देता है। यह USB ड्राइव उन PC पर काम करती है, जो UEFI मोड में चालू होते हैं। Windows 11 के लिए यह मोड ज़रूरी है।
usb-ack = मुझे पता है कि इस USB ड्राइव पर मौजूद सब कुछ मिट जाएगा
usb-write = मिटाएँ और USB बनाएँ
usb-stage-prepare = इंस्टॉलेशन फ़ाइलें तैयार की जा रही हैं…
usb-stage-format = USB फ़ॉर्मैट किया जा रहा है…
usb-stage-copy = इंस्टॉलेशन फ़ाइलें कॉपी की जा रही हैं…
usb-stage-verify = USB की पुष्टि की जा रही है…
usb-working = Atlas खुला रखें और USB ड्राइव कनेक्ट रहने दें। अगर आप रद्द करते हैं, तो अधूरी USB ड्राइव से Windows इंस्टॉल नहीं किया जा सकेगा।
# Titles of the error bar, the success bar and the close prompt while a USB is being written.
usb-failed-title = USB बनाना पूरा नहीं हो सका
usb-complete-title = आपका USB तैयार है
usb-close-title = USB अभी बन रहा है
# After erasing may have begun.
usb-failed = हो सकता है कि ड्राइव पहले ही मिटा दी गई हो, इसलिए अभी उससे Windows इंस्टॉल नहीं किया जा सकता। पक्का करें कि वह कनेक्ट है, फिर दोबारा कोशिश करने के लिए “USB की समीक्षा करें” चुनें। अगर आपने उसे दोबारा कनेक्ट किया है, तो पहले “रीफ़्रेश करें” चुनें और उसे फिर से चुनें।
# Before anything on the drive was changed: in general, then for the reasons the writer reports.
usb-failed-unchanged = आपकी USB ड्राइव में कोई बदलाव नहीं हुआ। क्या विफल हुआ, यह देखने के लिए “लॉग फ़ोल्डर खोलें” चुनें, फिर दोबारा कोशिश करने के लिए “USB की समीक्षा करें” चुनें।
usb-failed-iso = इस ISO से इंस्टॉलेशन USB नहीं बनाया जा सकता। Atlas से बनाया गया ISO चुनें, या Microsoft से लिया गया Windows 11 का ऐसा ISO, जिसके संस्करण का Atlas समर्थन करता है। आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-failed-location = ISO या Atlas Manager इस USB ड्राइव पर, किसी नेटवर्क स्थान पर या किसी लिंक किए गए फ़ोल्डर में है। उसे इस PC के किसी स्थानीय फ़ोल्डर में ले जाएँ, फिर कोशिश करें। आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-failed-space = इंस्टॉलेशन फ़ाइलें तैयार करने के लिए Windows ड्राइव पर पर्याप्त ख़ाली जगह नहीं है। जगह ख़ाली करें, फिर कोशिश करें। आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-failed-fit = इस USB ड्राइव पर इंस्टॉलेशन फ़ाइलों के लिए पर्याप्त जगह नहीं है। कोई बड़ी ड्राइव इस्तेमाल करें, फिर कोशिश करें। आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-failed-drive-changed = सूची पढ़े जाने के बाद USB ड्राइव हटाई गई, दोबारा कनेक्ट की गई या बदल दी गई। “रीफ़्रेश करें” चुनें, ड्राइव को फिर से चुनें, फिर “USB की समीक्षा करें” चुनें। आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-cancelled = ड्राइव पर अधूरी इंस्टॉलेशन फ़ाइलें हो सकती हैं। Windows इंस्टॉल करने से पहले इसे फिर से बनाएँ।
usb-cancelled-title = USB बनाना रद्द कर दिया गया
usb-cancelled-unchanged = आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-complete = Atlas ने हर फ़ाइल की जाँच कर ली है। “USB इजेक्ट करें” चुनें, फिर जिस PC पर Windows दोबारा इंस्टॉल करना है, उसकी फ़ाइलों का बैकअप लें। ड्राइव को उस PC में लगाएँ, फिर उस PC के बूट मेनू से USB ड्राइव चुनकर उसे चालू करें (PC चालू होते समय अक्सर F12, F11 या Esc दबाने पर बूट मेनू खुलता है)।
usb-eject = USB इजेक्ट करें
usb-ejected = अब आप USB ड्राइव निकाल सकते हैं। जिस PC पर Windows दोबारा इंस्टॉल करना है, उसकी फ़ाइलों का बैकअप लें। फिर उस PC के बूट मेनू से USB ड्राइव चुनकर उसे चालू करें (PC चालू होते समय अक्सर F12, F11 या Esc दबाने पर बूट मेनू खुलता है)।
usb-eject-failed = इसे इस्तेमाल करने वाली फ़ाइलें या विंडो बंद करें, फिर दोबारा कोशिश करें।
usb-eject-failed-title = USB इजेक्ट नहीं हो सका
ready-fresh-title = Atlas, नए सिरे से इंस्टॉल किए गए Windows के लिए बना है
ready-fresh-description = अगर आप इस PC पर पहले से Windows इस्तेमाल कर रहे हैं, तो जारी रखने से पहले अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें। उससे पहले देख लें कि “PC की जाँच” में Windows संगतता की जाँच सफल रही है, ताकि आप समर्थित संस्करण ही दोबारा इंस्टॉल करें।
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 Home, LTSC और Server संस्करण समर्थित नहीं हैं। कोई दूसरा संस्करण इस्तेमाल करें, जैसे Pro, Education या Enterprise। अगर Windows आपके संस्करण की पहचान नहीं कर सका, तो आगे बढ़ने से पहले यह समस्या ठीक करें।
install-source-title = इंस्टॉलेशन उपलब्ध नहीं है
install-source-unsupported = Atlas { $source } को सीधे { $target } पर अपडेट नहीं किया जा सकता। इस संस्करण का इस्तेमाल करने के लिए अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें।
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } को सीधे अपडेट नहीं किया जा सकता। नए संस्करण का इस्तेमाल करने के लिए अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें।
# "पैकेज फ़ाइल खोलें" is package-open-file. $folder is a folder path (text).
install-source-resume = Atlas { $target } का एक इंस्टॉलेशन पूरा नहीं हुआ, और इसे केवल Atlas { $target } का पैकेज ही पूरा कर सकता है। “पैकेज फ़ाइल खोलें” चुनें और वही Atlas पैकेज (.apbx) चुनें। अगर Atlas ने इसे डाउनलोड किया था, तो यह { $folder } में है।
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } का एक इंस्टॉलेशन पूरा नहीं हुआ। यह परीक्षण बिल्ड केवल अपने साथ दिया गया Atlas पैकेज इंस्टॉल कर सकता है, इसलिए वह इंस्टॉलेशन Atlas Manager के रिलीज़ बिल्ड में Atlas { $target } के पैकेज से पूरा करें।
install-source-unknown = Atlas पुष्टि नहीं कर सका कि इस PC पर पहले से क्या इंस्टॉल है, इसलिए वह फ़िलहाल कुछ भी इंस्टॉल नहीं करेगा। “रिपोर्ट भेजें” चुनें, ताकि Atlas टीम मदद कर सके।
# $problem is one of the install-source-* messages; $error is a raw error message (text).
install-source-details = { $problem } विवरण: { $error }
iso-edition-selection = केवल समर्थित संस्करण शामिल हैं। Windows सेटअप के दौरान वह संस्करण चुनें जिसके लिए आपके पास Windows लाइसेंस है।
detail-windows-preview = Insider बिल्ड समर्थित नहीं हैं। Windows 11 का सार्वजनिक रिलीज़ संस्करण इस्तेमाल करें।
detail-windows-release-unknown = Atlas पुष्टि नहीं कर सका कि यह Windows बिल्ड सार्वजनिक रूप से रिलीज़ हुआ है। इंटरनेट से कनेक्ट करें और दोबारा जाँचें।
iso-release-unknown = Atlas पुष्टि नहीं कर सका कि यह ISO, Windows 11 का ऐसा सार्वजनिक रिलीज़ है, जिसका Atlas पैकेज समर्थन करता है। इंटरनेट से कनेक्ट करें, फिर “फ़ाइलें जाँचें” दोबारा चुनें। अगर फिर भी विफल हो, तो Microsoft से ISO दोबारा डाउनलोड करें।
prepare-previous-worker = पहले शुरू हुए अपडेट अभी भी चल रहे हैं। Atlas उनके पूरा होने का इंतज़ार करेगा, फिर आप अपडेट की जाँच दोबारा कर सकेंगे।

ready-used-windows-title = इस PC पर Windows पहले से इस्तेमाल किया हुआ लगता है
ready-used-windows-description = इस PC पर Windows कम से कम एक हफ़्ते पहले इंस्टॉल किया गया था, या इसमें पहले से कई ऐप हैं। यहाँ Atlas इंस्टॉल करना समर्थित नहीं है और इसकी बिल्कुल सलाह नहीं दी जाती। आपके मौजूदा ऐप और सेटिंग्स शायद उम्मीद के मुताबिक़ काम न करें, और Atlas, OneDrive को हटा देता है, इसलिए उसमें रखी फ़ाइलें सिंक होना बंद हो जाएँगी और आपके डेस्कटॉप, दस्तावेज़ और चित्र फ़ोल्डर ख़ाली दिख सकते हैं। पहले अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें, या तभी जारी रखें, जब आप यह जोखिम स्वीकार करते हों।
ready-used-windows-dismiss = फिर भी जारी रखें

prepare-resumed = आपका PC रीस्टार्ट हो गया है, और Atlas ने अब तक के आपके विकल्प वापस ला दिए हैं। Atlas इंस्टॉल करने से पहले अपडेट पूरे करने के लिए “अपडेट जारी रखें” चुनें।
prepare-continue = अपडेट जारी रखें
prepare-saving-restart = आपके विकल्प सहेजे जा रहे हैं और Windows रीस्टार्ट होने के बाद Atlas दोबारा खोलने की व्यवस्था की जा रही है…
prepare-restart-save-failed = आपके विकल्प सहेजे नहीं जा सके। रीस्टार्ट करने से पहले फिर कोशिश करें।
prepare-restart-registration-failed = आपके विकल्प सहेजे गए हैं, लेकिन Atlas रीस्टार्ट के बाद अपने-आप दोबारा खुलने की व्यवस्था नहीं कर सका। फिर कोशिश करें, या अपना PC ख़ुद रीस्टार्ट करें और साइन इन करने के बाद Atlas खोलें।
prepare-restart-failed = Atlas आपका PC रीस्टार्ट नहीं कर सका। फिर कोशिश करें, या स्टार्ट मेनू से इसे रीस्टार्ट करें। आपके विकल्प सहेजे गए हैं, और साइन इन करने के बाद Atlas फिर से खुल जाएगा।
diagnostics-export = डायग्नोस्टिक्स निर्यात करें
diagnostics-exporting = डायग्नोस्टिक्स इकट्ठा किए जा रहे हैं…
diagnostics-privacy = Atlas टीम को निजी तौर पर रिपोर्ट भेजें, या मदद माँगते समय शेयर करने के लिए डायग्नोस्टिक्स ZIP निर्यात करें। Atlas उस ZIP से आपका उपयोगकर्ता नाम, PC का नाम और ईमेल पते हटा देता है।
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = डायग्नोस्टिक्स ZIP बन गई
diagnostics-failed-title = डायग्नोस्टिक्स निर्यात नहीं हो सके
# $error is the raw error (text).
diagnostics-failed = जाँचें कि आपके PC में ख़ाली डिस्क स्पेस है, फिर कोशिश करें। विवरण: { $error }

## Tester builds (embedded-playbook feature)

# One line of chrome under the title bar on a release-candidate build.
rc-banner = Atlas { $release } परीक्षण बिल्ड। यह ऐप केवल साथ में दिया गया Atlas पैकेज इंस्टॉल करता है।
home-status-bundled = परीक्षण बिल्ड { $release }
package-bundled = इस परीक्षण बिल्ड के साथ दिया गया Atlas { $version } इंस्टॉल के लिए तैयार है।
rc-about-release = परीक्षण बिल्ड
rc-about-commit = स्रोत कमिट
rc-about-package = साथ में दिया गया Atlas पैकेज (SHA-256)
iso-package-bundled = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज
prepare-percent = इस चरण का { $percent }% पूरा हुआ
prepare-count = पूरे हुए अपडेट: { $total } में से { $completed }
prepare-bytes = लगभग { $total } MB में से { $downloaded } MB डाउनलोड हुआ
prepare-elapsed = बीता समय: { $minutes } मिनट { $seconds } सेकंड
prepare-progress-waiting = अपडेट सेवा की प्रतीक्षा है। इस चरण के लिए प्रतिशत उपलब्ध नहीं है।
prepare-progress-unchanged = { $minutes } मिनट से कोई प्रगति नहीं हुई। बड़े अपडेट में समय लग सकता है, इसलिए Atlas खुला रखें। विवरण के लिए “लॉग फ़ोल्डर खोलें” चुनें।
prepare-report-delayed = Windows ने { $seconds } सेकंड से प्रगति की जानकारी नहीं दी है। हो सकता है कि अपडेट अभी भी चल रहे हों, इसलिए Atlas खुला रखें।

prepare-affected-app = प्रभावित ऐप
prepare-app-in-use = { $app } बंद करें, फिर कोशिश करें। जब तक यह खुला है, Windows इसे अपडेट नहीं कर सकता। अगर इसकी विंडो नहीं मिल रही, तो इसे कार्य प्रबंधक से बंद करें। अगर फिर भी विफल हो, तो अपना PC रीस्टार्ट करें और { $app } खोलने से पहले फिर कोशिश करें।
prepare-install-busy = कोई दूसरा इंस्टॉलेशन या ज़रूरी रीस्टार्ट अपडेट रोक रहा है। दूसरे इंस्टॉलेशन पूरे होने दें, अगर Windows कहे तो अपना PC रीस्टार्ट करें, फिर कोशिश करें।
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas उस खाते से अलग खाते में चल रहा है, जिससे Windows में साइन इन किया गया है। व्यवस्थापक खाते से Windows में साइन इन करें, उसी खाते से Atlas खोलें, फिर कोशिश करें।
prepare-failed-store-missing = आपके खाते के लिए Microsoft Store सेट अप नहीं है। Microsoft Store एक बार खोलें, या अगर वह मौजूद नहीं है तो उसे दोबारा इंस्टॉल करें, फिर कोशिश करें।
prepare-failed-store-battery = बैटरी बचाने के लिए Microsoft Store ने अपडेट रोक दिए हैं। अपना PC प्लग इन करें, फिर कोशिश करें।
prepare-failed-store-network = Microsoft Store ने अपडेट रोक दिए हैं, क्योंकि आपका PC मीटर्ड कनेक्शन पर है। ऐसे Wi-Fi या ईथरनेट से कनेक्ट करें जो मीटर्ड कनेक्शन न हो, फिर कोशिश करें।
prepare-failed-store-timeout = Store ऐप अभी पूरी तरह अपडेट नहीं हुए हैं। Microsoft Store में बाकी डाउनलोड पूरे करें, फिर कोशिश करें।
prepare-failed-store-passes = Microsoft Store लगातार नए अपडेट देता रहा। Microsoft Store में बाकी अपडेट पूरे करें, फिर कोशिश करें।
prepare-failed-manual-updates = कुछ Windows अपडेट Windows Update में ही पूरे करने होंगे। Windows Update खोलें, उन्हें पूरा करें, फिर कोशिश करें।
prepare-failed-windows-passes = Windows Update लगातार नए अपडेट देता रहा। Windows Update में बाकी अपडेट पूरे करें, फिर कोशिश करें।
prepare-error-code = त्रुटि कोड: { $code }
prepare-open-store = Microsoft Store खोलें

check-user-account = उपयोगकर्ता खाता
detail-user-account-ok = UAC चालू है और आपका खाता इंस्टॉलेशन के लिए तैयार है।
detail-user-account-not-ready = उपयोगकर्ता खाता नियंत्रण (UAC) चालू करें, अपना PC रीस्टार्ट करें और फिर कोशिश करें। अगर आप अंतर्निहित Administrator खाते का इस्तेमाल करते हैं, तो किसी दूसरे व्यवस्थापक खाते से साइन इन करें।
detail-user-account-unknown = Atlas आपके उपयोगकर्ता खाते की जाँच नहीं कर सका। इंस्टॉल करने से पहले फिर से जाँच करें। Windows ने बताया: { $error }

footer-prepare-required = जारी रखने के लिए Windows और Store ऐप अपडेट करना पूरा करें
footer-prepare-stopping = मौजूदा चरण पूरा होते ही अपडेट रुक जाएँगे…
resume-choices-title = आपका पिछला इंस्टॉलेशन जारी है
resume-choices-detail = वह इंस्टॉलेशन पूरा करने के लिए Atlas ने पिछली बार चुने गए आपके विकल्प वापस ला दिए हैं। उसके पूरा होने तक आप इन्हें “आपके विकल्प” में नहीं बदल सकते।

## Voluntary reports
report-title = रिपोर्ट भेजें
report-received = रिपोर्ट मिल गई
report-reference = इस रिपोर्ट के बारे में Atlas टीम से संपर्क करने के लिए यह संदर्भ सँभालकर रखें। अगर आपने संपर्क विवरण दिए हैं, तो टीम जवाब देने के लिए उनका इस्तेमाल कर सकती है, लेकिन जवाब मिलने की गारंटी नहीं है।
# Accessible name of the Copy button beside the report reference.
report-copy-reference = रिपोर्ट संदर्भ कॉपी करें
report-another = एक और रिपोर्ट भेजें
# Label of the choice between the two kinds of report.
report-kind = आप क्या भेजना चाहते हैं?
report-kind-issue = समस्या
report-kind-suggestion = सुझाव
# $min and $max are numbers: the message lengths the report service accepts.
report-intro = बताएँ कि क्या हुआ या आप क्या बदलना चाहेंगे ({ $min }–{ $max } अक्षर)। अपने संदेश में पासवर्ड न लिखें।
report-message = आपका संदेश
report-message-placeholder = मेरी कोशिश थी कि…
report-contact = संपर्क जानकारी (वैकल्पिक)
report-contact-placeholder = ईमेल या Discord उपयोगकर्ता नाम
report-attach = डायग्नोस्टिक्स शामिल करें
report-attach-description = लॉग और सिस्टम की जानकारी, जो कारण ढूँढने में मदद करती है। Atlas आपका उपयोगकर्ता नाम, PC का नाम, ईमेल पते और पहचाने गए पासवर्ड या कुंजियाँ हटा देता है। त्रुटि का विवरण, हार्डवेयर मॉडल और ऐप के नाम रखे जाते हैं। भेजने से पहले आप ZIP की समीक्षा कर सकते हैं।
report-prepare = डायग्नोस्टिक्स तैयार करें
report-review = ZIP की समीक्षा करें
report-prepare-failed-title = डायग्नोस्टिक्स तैयार नहीं हो सके
# $error is a raw error message (text).
report-prepare-failed = “डायग्नोस्टिक्स तैयार करें” दोबारा चुनें, या अपनी रिपोर्ट उनके बिना भेजने के लिए “डायग्नोस्टिक्स शामिल करें” बंद करें। विवरण: { $error }
report-privacy = आपकी रिपोर्ट निजी तौर पर reports.atlasos.net पर Atlas टीम को जाती है। आपका संदेश और संपर्क विवरण जैसे लिखे गए हैं, वैसे ही भेजे जाते हैं। जाँच में मदद के लिए टीम दूसरी कंपनियों की AI सेवाओं का इस्तेमाल कर सकती है। इन सेवाओं को आपका संदेश और डायग्नोस्टिक्स मिलते हैं, लेकिन आपके संपर्क विवरण नहीं। रिपोर्टें 90 दिन बाद हटा दी जाती हैं, और सर्वर के सुरक्षा लॉग में आपका IP पता दर्ज हो सकता है।
report-website = गोपनीयता और रिपोर्ट वेबसाइट
report-consent = मैं यह रिपोर्ट और इसमें शामिल डायग्नोस्टिक्स Atlas टीम को भेजने के लिए सहमत हूँ
report-failed = आपका संदेश सुरक्षित है। अपना इंटरनेट कनेक्शन जाँचें, उसके बाद “फिर कोशिश करें” चुनें, या रिपोर्ट वेबसाइट से अपनी रिपोर्ट भेजें।
report-failed-busy = रिपोर्ट सेवा अभी व्यस्त है। आपका संदेश सुरक्षित है। बाद में फिर कोशिश करें।
report-failed-outdated = Atlas Manager का यह संस्करण अब रिपोर्ट नहीं भेज सकता। आपका संदेश सुरक्षित है: इसे कॉपी करके रिपोर्ट वेबसाइट में चिपकाएँ। अगर आपने डायग्नोस्टिक्स शामिल किए थे, तो “ZIP की समीक्षा करें” चुनें और वह ZIP भी वहाँ संलग्न करें।
report-failed-diagnostics = तैयार किए गए डायग्नोस्टिक्स भेजे नहीं जा सकते। आपका संदेश सुरक्षित है। “डायग्नोस्टिक्स तैयार करें” दोबारा चुनें, या “डायग्नोस्टिक्स शामिल करें” बंद करें।
# Link under a report that wasn't sent.
report-failed-website = रिपोर्ट वेबसाइट खोलें
report-sending = भेज रहे हैं…
report-send = रिपोर्ट भेजें

# $min and $max are numbers: the message lengths the report service accepts.
report-validation-message = { $min }–{ $max } अक्षर लिखें।

# $max is a number: the longest contact details the report service accepts.
report-validation-contact = संपर्क विवरण { $max } अक्षरों तक रखें।

report-validation-consent = इस रिपोर्ट को भेजने की सहमति की पुष्टि करें।

report-failed-title = रिपोर्ट नहीं भेजी गई
