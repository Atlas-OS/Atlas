### Atlas Manager: हिन्दी (Hindi), preview translation; revised on 24 November 2026 from the en-GB source. Native-speaker review pending.
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
### - The .atlaspkg file is the "Atlas package": "Atlas पैकेज", then "पैकेज" once
###   it is clear (masculine: "साथ में दिया गया Atlas पैकेज"). The
###   selections made in the Your choices step are "विकल्प" everywhere, the ISO
###   modes included, never "सेटिंग"/"सेटिंग्स": those name the app's own
###   Settings page and Windows settings.
### - Where a message names a button or option, quote its exact label in “ ”.
###   Step names are quoted too (“आपके विकल्प”, “Windows सुरक्षा”), except तैयारी.
### - The install steps are तैयारी, आपके विकल्प, Windows सुरक्षा and इंस्टॉल. The ISO
###   steps are Windows, सेटअप and बनाएँ. Windows' own installer (Windows Setup)
###   is "Windows सेटअप".
### - A USB drive is "USB ड्राइव" (feminine) in titles and running text.
### - चरण is only a step of the install or ISO flow (stepper, "चरण 2"); a stage of
###   updating or of creating an ISO is पड़ाव (masculine: "मौजूदा पड़ाव").
### - Status lines for work under way end with the ellipsis (…), as in English.
###   Checklist stages that show done and pending states use verbal nouns
###   (फ़ॉर्मैट करना), not the progressive.
### - Windows names Hindi Windows may show in English keep the English in
###   brackets until confirmed: "मेमोरी अखंडता (Memory integrity)", the services.

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
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = लॉग फ़ोल्डर खोलें
# Accessible name of the Copy button beside the install log.
common-copy-install-log = इंस्टॉलेशन लॉग कॉपी करें
common-install-log = इंस्टॉलेशन लॉग
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas पैकेज
common-checking = जाँच हो रही है
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } या { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } और { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }। { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Atlas इंस्टॉल हो रहा है, विंडो बंद करें?
window-close-installing = इंस्टॉलेशन चलता रहेगा। नतीजा देखने के लिए Atlas दोबारा खोलें।
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = इंस्टॉलेशन चलता रहेगा, लेकिन आपका PC अपने-आप रीस्टार्ट नहीं होगा। नतीजा देखने के लिए Atlas दोबारा खोलें।
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = खुला रखें
window-close-close = विंडो बंद करें
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = इंस्टॉल करने से पहले रोकें?
window-close-checks-unchanged = इंस्टॉलेशन से अभी तक कोई बदलाव नहीं हुआ है। अगर आप बंद करते हैं, तो यह शुरू नहीं होगा।
window-close-keep-installing = इंस्टॉल करते रहें
window-close-stop-and-close = रोकें और बंद करें
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = अपडेट करना रोकें?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps: पड़ाव.
prepare-close-stops-after-stage = मौजूदा पड़ाव पूरा होने के बाद Atlas रुक जाएगा। तब आप इसे बंद कर सकते हैं।
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = Atlas का सेटअप पूरा करने के लिए रीस्टार्ट करें?
window-close-restart-closed = बंद होने के बाद Atlas आपका PC रीस्टार्ट नहीं कर सकता। पहले अपना काम सहेजें।
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = अपडेट पूरा करने के लिए रीस्टार्ट करें?
window-close-update-restart-later = पहले अपना काम सहेजें। अगर आप बाद में रीस्टार्ट करते हैं, तो रीस्टार्ट के बाद Atlas आगे का काम जारी रखेगा।
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = सुरक्षा बंद है, फिर भी Atlas बंद करें?
window-close-protection-all = Windows सुरक्षा के चारों सुरक्षा स्विच बंद हैं। अगर आप अभी Atlas इंस्टॉल नहीं कर रहे हैं, तो पहले उन्हें फिर से चालू करें।
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some =
    { $count ->
        [1] Windows सुरक्षा में { $switches } बंद है। अगर आप अभी Atlas इंस्टॉल नहीं कर रहे हैं, तो पहले इसे फिर से चालू करें।
       *[other] Windows सुरक्षा में { $switches } बंद हैं। अगर आप अभी Atlas इंस्टॉल नहीं कर रहे हैं, तो पहले इन्हें फिर से चालू करें।
    }
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = ISO बनाना रोकें?
iso-close-safe-point = Atlas अगले सुरक्षित पड़ाव पर रुक जाएगा।
usb-close-question = USB ड्राइव बनाना रोकें?
usb-close-unfinished = अधूरी ड्राइव से Windows इंस्टॉल नहीं किया जा सकता।
window-close-keep-creating = बनाते रहें
window-close-stop = रोकें
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Atlas पैकेज (.atlaspkg) खोलें
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
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas, Windows में बैकग्राउंड गतिविधि और ध्यान भटकाने वाली चीज़ें कम करता है।
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = इस PC पर Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = { $date } को इंस्टॉल किया गया
home-status-checking = अपडेट की जाँच हो रही है…
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
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = इस PC पर Atlas इंस्टॉल करें?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = आपके मौजूदा ऐप और सेटिंग्स काम करना बंद कर सकते हैं, और Atlas, OneDrive को हटा देता है, इसलिए उसकी फ़ाइलें सिंक नहीं होंगी और फ़ोल्डर ख़ाली दिख सकते हैं। पहले अपनी फ़ाइलों का बैकअप लें।
home-used-windows-install = फिर भी इंस्टॉल करें
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Atlas के साथ Windows दोबारा इंस्टॉल करें
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = इस PC का Windows पहले से इस्तेमाल में है, और Atlas नए इंस्टॉलेशन पर सबसे अच्छा काम करता है।
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = आपके PC को रीस्टार्ट करना होगा
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas आपका PC रीस्टार्ट नहीं कर सका। स्टार्ट मेनू से इसे रीस्टार्ट करें।
home-security-reminder-title = सुरक्षा स्विच फिर से चालू करें
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = पक्का करें कि आपकी सुरक्षा चालू है
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [1] Windows सुरक्षा में यह अभी भी बंद है: { $switches }।
       *[other] Windows सुरक्षा में ये अभी भी बंद हैं: { $switches }।
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas हर सुरक्षा स्विच की स्थिति नहीं पढ़ सका। Windows सुरक्षा में देखें कि ये चालू हैं: { $switches }।
home-elevation-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas आपके सेटअप विकल्प सहेज नहीं सका, इसलिए वह दोबारा नहीं खुला।
home-state-error-title = आपके Atlas इंस्टॉलेशन का विवरण नहीं पढ़ा जा सका
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = हो सकता है कि आपका Atlas संस्करण, विकल्प और इतिहास सही न दिखें।
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager को अपडेट की ज़रूरत है
home-whats-new = Atlas { $version } में नया क्या है
home-view-release = GitHub पर रिलीज़ नोट्स देखें
home-show-less = कम दिखाएँ
home-show-full-notes = पूरे रिलीज़ नोट्स दिखाएँ
home-your-install = आपका Atlas सेटअप
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = इस PC पर इस बात का कोई रिकॉर्ड नहीं है कि Atlas कैसे इंस्टॉल किया गया था, इसलिए आपके विकल्प और इंस्टॉलेशन इतिहास नहीं दिखाए जा सकते।
home-history = इंस्टॉलेशन इतिहास
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = चरण { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }। { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = आगे क्या होगा
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Atlas का सेटअप जारी है
# Beside step-ready in that card.
home-step-ready = Atlas आपके PC की जाँच करता है और Windows को अपडेट करता है।
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas आपके PC की जाँच करता है और Windows को संस्करण { $release } पर ले जाता है।
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = आप चुनते हैं कि क्या रखना है, जैसे Microsoft Defender।
# Beside step-security in that card.
home-step-security = आप Windows सुरक्षा के चारों सुरक्षा स्विच बंद करते हैं।
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts = इंस्टॉल होने में आम तौर पर लगभग { $minutes } मिनट का समय लगता है, फिर आपका PC रीस्टार्ट होता है।
home-step-install-restart-yourself = इंस्टॉल होने में आम तौर पर लगभग { $minutes } मिनट का समय लगता है, फिर अपना PC रीस्टार्ट करें।
# At the bottom of that card, under the four steps.
home-steps-save-work = पहले अपना काम सहेजें, क्योंकि ऐप बंद हो सकते हैं और आपका PC रीस्टार्ट होगा।
home-github = GitHub पर Atlas देखें
home-discord = Discord पर Atlas समुदाय से जुड़ें
home-report-problem = समस्या रिपोर्ट करें

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = पहला इंस्टॉलेशन
history-mode-upgrade = अपडेट
history-mode-reapply = दोबारा इंस्टॉलेशन
history-mode-unknown = इंस्टॉलेशन

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas डिफ़ॉल्ट ऐप सेटिंग्स इस्तेमाल कर रहा है
notice-settings-unreadable-problem = Atlas आपकी सहेजी गई ऐप सेटिंग्स नहीं पढ़ सका। आपकी Windows सेटिंग्स नहीं बदली हैं।
notice-settings-damaged-kept-problem = आपकी ऐप सेटिंग्स फ़ाइल ख़राब थी, इसलिए Atlas ने उसे रीसेट कर दिया और पुरानी फ़ाइल की एक कॉपी रख ली।
notice-settings-damaged-problem = आपकी ऐप सेटिंग्स फ़ाइल ख़राब थी। Atlas फ़िलहाल डिफ़ॉल्ट सेटिंग्स इस्तेमाल कर रहा है।
notice-settings-not-saved-title = ऐप सेटिंग्स सहेजी नहीं जा सकीं
notice-settings-not-saved-problem = Atlas आपके हाल के बदलाव सहेज नहीं सका, इसलिए Atlas बंद करने पर वे खो सकते हैं। अगर Atlas की कोई दूसरी विंडो खुली है, तो उसे बंद करें, फिर बदलाव दोबारा करें।
notice-session-unreadable-title = पिछले इंस्टॉलेशन की जाँच नहीं हो सकी
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas यह पता नहीं लगा सका कि पिछला इंस्टॉलेशन अभी भी चल रहा है या नहीं। अगर आपको पक्का पता है कि कोई नहीं चल रहा, तो उसका इंस्टॉलेशन रिकॉर्ड हटाएँ, फिर Atlas दोबारा खोलें।
# Get ready, when the install record can't be read. $path is a file path (text).
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
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = पूरा हुआ
stepper-status-current = मौजूदा चरण
stepper-status-upcoming = आगे का चरण
# A step already visited whose requirements aren't met yet.
stepper-status-attention = ध्यान देने की ज़रूरत है
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = { $total } में से चरण { $number }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }। { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = PC की जाँच
# Status line while the checks run.
ready-checks-running = आपके PC की जाँच हो रही है…
ready-check-again = दोबारा जाँचें
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [1] { $count } जाँच सफल रही
       *[other] { $count } जाँचें सफल रहीं
    }
# Status line when some checks need attention, which are listed under it. The verb agrees
# with $passed, so this selects on $passed.
ready-checks-passed-some =
    { $passed ->
        [1] { $total } में से { $passed } जाँच सफल रही
       *[other] { $total } में से { $passed } जाँचें सफल रहीं
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "9 में से 5 जाँचें सफल रहीं · अपडेट करने पर 4 ठीक हो जाएँगी".
# $count is how many updating takes care of; the verb agrees with the जाँचें before it.
ready-checks-handled =
    { $count ->
        [1] अपडेट करने पर { $count } ठीक हो जाएगी
       *[other] अपडेट करने पर { $count } ठीक हो जाएँगी
    }
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = अपडेट करने पर ठीक हो जाएगा
# Under the title of a check that updating takes care of.
check-updates-handled = अपडेट इंस्टॉल होने की प्रतीक्षा में हैं। Windows अपडेट करते समय Atlas इन्हें इंस्टॉल कर देगा।
check-restart-handled = पहले किए गए बदलाव पूरे करने के लिए Windows को रीस्टार्ट करना होगा। अपडेट करते समय यह भी हो जाएगा।
check-handled = अपडेट करने पर यह ठीक हो जाएगा।
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = डाउनलोड हो रहा है…
ready-package-unpacking = फ़ाइलें निकाली जा रही हैं…
ready-package-ready = तैयार
ready-package-checking = नवीनतम संस्करण की जाँच हो रही है…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = साथ में दिया गया Atlas पैकेज तैयार किया जा रहा है…
ready-package-none = अभी डाउनलोड नहीं हुआ
ready-package-failed = Atlas पैकेज नहीं मिल सका
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = इसे दोबारा डाउनलोड करें, या कोई दूसरा Atlas पैकेज (.atlaspkg) खोलें।
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज निकाला नहीं जा सका। फिर कोशिश करें।
ready-package-manager = Atlas Manager का नया संस्करण चाहिए
ready-package-release-failed = नवीनतम संस्करण की जाँच नहीं हो सकी
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = अपना इंटरनेट कनेक्शन जाँचें, फिर कोशिश करें। अगर आपके पास Atlas पैकेज (.atlaspkg) है, तो आप इसकी जगह उसे खोल सकते हैं।
# Row title.
ready-updates-title = Windows और Microsoft Store अपडेट
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = नोटपैड जैसे Store ऐप अपडेट होते समय बंद हो सकते हैं। पहले उनमें अपना काम सहेजें।
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Windows के संस्करण { $release } पर जाने के बाद शुरू होगा।
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = रीस्टार्ट के बाद जारी रखा जा रहा है…
ready-updates-restarting = आपका PC रीस्टार्ट हो रहा है…
ready-updates-done = Windows और Store ऐप अप टू डेट हैं।
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows अप टू डेट है।
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second. सेकंड doesn't change with the number.
ready-updates-restart-countdown = आपका PC { $seconds } सेकंड में रीस्टार्ट होगा।
ready-updates-restart = अपडेट पूरा करने के लिए आपके PC को रीस्टार्ट करना होगा।
ready-updates-restart-finish = संस्करण { $release } का इंस्टॉलेशन पूरा करने के लिए Windows को एक बार और रीस्टार्ट करना होगा।
ready-updates-restart-failed = आपका PC रीस्टार्ट नहीं हुआ
# Under the restart's status line, before Restart now.
ready-updates-restart-save = पहले अपना काम सहेजें।
ready-updates-restart-persists = Windows अब भी रीस्टार्ट माँग रहा है
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = दोबारा रीस्टार्ट करने से शायद कोई फ़ायदा नहीं होगा। Windows Update में जो कुछ प्रतीक्षा में है, उसे पूरा करें, फिर कोशिश करें।
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = रीस्टार्ट के कारण: { $reasons }
ready-updates-network = अपडेट इस कनेक्शन का इस्तेमाल नहीं कर सकते
ready-updates-stopped = अपडेट करना रुक गया। हो सकता है कि कुछ अपडेट पहले ही इंस्टॉल हो चुके हों।
ready-updates-previous = पहले शुरू हुए अपडेट की प्रतीक्षा है…
# Button after the user stopped updating.
ready-updates-resume = अपडेट फिर से शुरू करें
ready-updates-start = अपडेट करना शुरू करें
# Why updating hasn't started, under the row.
ready-updates-blocked = अपडेट तब शुरू होंगे, जब Atlas इस PC पर इंस्टॉल हो सकेगा।
ready-updates-needs-admin = Atlas को व्यवस्थापक की अनुमति मिलने पर शुरू होगा।
ready-updates-needs-windows = Windows संगतता की जाँच सफल होने पर शुरू होगा।
ready-updates-needs-drivers = ड्राइवर इंस्टॉल करने का तरीका चुनने पर शुरू होगा।
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = ड्राइवर: { $choice }
ready-drivers-automatic = Windows Update से
ready-drivers-manual = ख़ुद इंस्टॉल करें
ready-drivers-change-a11y = ड्राइवर इंस्टॉल करने का तरीका बदलें
# Under the two answers, once updating has run.
ready-drivers-again = इसे बदलने पर अपडेट दोबारा चलेंगे।

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Atlas { $version } डाउनलोड हो रहा है · { $total } में से { $received } MB
package-unpacking = फ़ाइलें निकाली जा रही हैं
package-status-ready = तैयार
# Accessible name of the progress bar.
package-progress = Atlas पैकेज की प्रगति
package-download-again = दोबारा डाउनलोड करें
package-download-version = Atlas { $version } डाउनलोड करें
package-download-newest = नवीनतम संस्करण डाउनलोड करें
package-cancel-download = डाउनलोड रद्द करें
package-open-file = पैकेज फ़ाइल खोलें
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } GitHub से डाउनलोड हो गया है और इंस्टॉल के लिए तैयार है।
package-from-file = Atlas { $version }, { $file } से लोड हो गया है और इंस्टॉल के लिए तैयार है।
package-unpacked = Atlas { $version } इंस्टॉल के लिए तैयार है।
package-none-yet = अभी कोई Atlas पैकेज नहीं है
acquire-no-asset = Atlas { $version } के लिए डाउनलोड करने योग्य कोई पैकेज फ़ाइल नहीं है। जारी रखने के लिए सहेजा हुआ Atlas पैकेज (.atlaspkg) खोलें।
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = यह ऐप Atlas पैकेज (.atlaspkg) से Atlas 0.6.0 और उसके बाद के संस्करण इंस्टॉल कर सकता है।
# Instead of acquire-unsupported for a Windows ISO opened as the Atlas package. Create an Atlas ISO (iso-open) is beside it.
acquire-windows-iso = यह एक Windows ISO है, Atlas पैकेज (.atlaspkg) नहीं। Atlas के साथ Windows दोबारा इंस्टॉल करने के लिए, इससे एक Atlas ISO बनाएँ।
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } में वे फ़ाइलें नहीं हैं, जिनकी ज़रूरत इस ऐप को इसे इंस्टॉल करने के लिए है। इसे दोबारा डाउनलोड करें, या कोई दूसरा Atlas पैकेज (.atlaspkg) खोलें।
acquire-failed = Atlas पैकेज तैयार नहीं हो सका। इसे दोबारा डाउनलोड करें, या कोई दूसरा Atlas पैकेज (.atlaspkg) खोलें। विवरण: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = डाउनलोड ने प्रतिक्रिया देना बंद कर दिया। अपना इंटरनेट कनेक्शन जाँचें, फिर दोबारा डाउनलोड करें, या सहेजा हुआ Atlas पैकेज (.atlaspkg) खोलें।
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = साथ में दिया गया Atlas पैकेज तैयार नहीं हो सका। “फिर कोशिश करें” चुनें। विवरण: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" (उसका) is the Atlas
# Manager downloaded, and "this one" (इसकी) the Atlas Manager running now.
acquire-manager-update-needed = इस Atlas पैकेज के लिए Atlas Manager का नया संस्करण चाहिए। Atlas Manager { $version } या उसके बाद का संस्करण डाउनलोड करें और इसकी जगह उसका इस्तेमाल करें।
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = इस Atlas पैकेज के लिए Atlas Manager का नया संस्करण चाहिए। Atlas Manager का नवीनतम संस्करण डाउनलोड करें और इसकी जगह उसका इस्तेमाल करें।
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = Atlas { $version } इंस्टॉल करने के लिए Atlas Manager { $required } या उसके बाद का संस्करण डाउनलोड करें और इसकी जगह उसका इस्तेमाल करें।
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = Atlas { $version } इंस्टॉल करने के लिए Atlas Manager का नवीनतम संस्करण डाउनलोड करें और इसकी जगह उसका इस्तेमाल करें।

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Atlas Manager डाउनलोड करें
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } उपलब्ध है
manager-update-message = Atlas Manager ख़ुद को अपडेट नहीं कर सकता। नया संस्करण डाउनलोड करें और इसकी जगह उसका इस्तेमाल करें।

## System checks

check-administrator = इंस्टॉल करने की अनुमति
check-supported-build = Windows संगतता
check-pending-updates = Windows अपडेट
check-pending-reboot = लंबित रीस्टार्ट
check-third-party-antivirus = अन्य एंटीवायरस सॉफ़्टवेयर
check-internet = इंटरनेट कनेक्शन
check-power = पावर सप्लाई
check-activation = Windows सक्रियण
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Windows 11 हार्डवेयर
check-move-space = ख़ाली जगह
check-move-update-source = अपडेट का स्रोत
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
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = संग्रहण सेटिंग्स खोलें
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, quoted as in fixed-installed.
check-fix-installed-apps = “इंस्टॉल किए गए ऐप्स” खोलें
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = मैंने Windows Update देख लिया है और कोई अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है

detail-admin-ok = Atlas को इंस्टॉलेशन के लिए ज़रूरी बदलाव करने की अनुमति है।
detail-admin-missing = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, फिर जब Windows अनुमति माँगे, तो “हाँ” चुनें।
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = Atlas के इस संस्करण के लिए Windows बिल्ड { $builds } ज़रूरी है। आपके PC पर बिल्ड { $build } है। जारी रखने से पहले समर्थित Windows संस्करण इंस्टॉल करें।
detail-build-missing = यह Atlas पैकेज किसी भी समर्थित Windows बिल्ड की सूची नहीं देता। LocalTest बिल्ड की जगह पैकेज का पूरा बिल्ड इस्तेमाल करें।
detail-updates-none = कोई Windows अपडेट इंस्टॉल होने की प्रतीक्षा में नहीं है।
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [1] { $count } अपडेट अभी भी प्रतीक्षा में है। इसे Windows Update में इंस्टॉल करें, फिर दोबारा जाँचें।
       *[other] { $count } अपडेट अभी भी प्रतीक्षा में हैं। इन्हें Windows Update में इंस्टॉल करें, फिर दोबारा जाँचें।
    }
detail-updates-scan-failed = Windows अपडेट की जाँच नहीं हो सकी। Windows Update खोलकर देखें कि कोई अपडेट प्रतीक्षा में है या नहीं। ({ $error })
detail-reboot-none = Windows को अभी रीस्टार्ट की ज़रूरत नहीं है।
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = पहले किए गए बदलाव पूरे करने के लिए Windows को रीस्टार्ट करना होगा। अपना PC रीस्टार्ट करें, फिर दोबारा जाँचें।
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = पहले किए गए बदलाव पूरे करने के लिए Windows को रीस्टार्ट करना होगा ({ $reasons })। अपना PC रीस्टार्ट करें, फिर दोबारा जाँचें।
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = आप जारी रख सकते हैं। Windows को अगली बार रीस्टार्ट होने पर कुछ फ़ाइलें बदलनी या हटानी हैं ({ $files })। Xbox Gaming Services जैसे कुछ ऐप हर रीस्टार्ट के बाद ऐसा करते हैं।
detail-reboot-unknown = यह जाँच नहीं हो सकी कि Windows को रीस्टार्ट की ज़रूरत है या नहीं। अपना PC रीस्टार्ट करें, फिर Atlas दोबारा खोलकर फिर से जाँचें। ({ $error })
detail-antivirus-none = कोई दूसरा एंटीवायरस सॉफ़्टवेयर नहीं मिला।
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Microsoft Defender के अलावा दूसरे एंटीवायरस ऐप इंस्टॉलेशन रोक सकते हैं। { $products } अनइंस्टॉल करें, फिर दोबारा जाँचें।
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows सुरक्षा में { $products } अब भी सूचीबद्ध है, लेकिन इसकी फ़ाइलें हट चुकी हैं, इसलिए यह अब इंस्टॉल नहीं है। Atlas फिर भी इंस्टॉलेशन जारी रख सकता है।
detail-antivirus-check-failed = अन्य एंटीवायरस सॉफ़्टवेयर की जाँच नहीं हो सकी। अगर ऐसा बार-बार हो, तो अपना PC रीस्टार्ट करें और दोबारा जाँचें। ({ $error })
detail-internet-ok = आप इंटरनेट से जुड़े हैं। जब तक Atlas सॉफ़्टवेयर डाउनलोड और इंस्टॉल करता है, यह कनेक्शन बनाए रखें।
detail-internet-missing = इंटरनेट से कनेक्ट करें, फिर दोबारा जाँचें।
detail-power-mains = आपका PC प्लग इन है। इंस्टॉलेशन पूरा होने तक इसे प्लग इन रखें।
detail-power-battery = अपने PC को प्लग इन करें, ताकि वह पूरे इंस्टॉलेशन के दौरान चालू रहे।
detail-power-check-failed = Atlas यह पता नहीं लगा सका कि आपका PC प्लग इन है या नहीं। अगर यह लैपटॉप है, तो इसे प्लग इन करें, फिर दोबारा जाँचें।
detail-activation-ok = Windows सक्रिय है। Atlas इसे नहीं बदलेगा।
detail-activation-missing = Windows सक्रिय नहीं है। आप जारी रख सकते हैं, लेकिन Atlas आपके लिए Windows सक्रिय नहीं करेगा।
detail-activation-no-licence = Windows ने कोई लाइसेंस नहीं बताया। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा।
detail-activation-unknown = Windows सक्रियण की जाँच नहीं हो सकी। आप जारी रख सकते हैं; Atlas आपकी सक्रियण स्थिति नहीं बदलेगा। ({ $error })
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-not-needed = इस PC पर Atlas को Windows को नए संस्करण पर ले जाने की ज़रूरत नहीं है।
detail-move-hardware-ready = इस PC में Windows 11 के लिए ज़रूरी TPM 2.0 और UEFI फ़र्मवेयर है।
detail-move-hardware-missing = इस PC में { $missing } नहीं है, इसलिए Windows Update इसे संस्करण { $release } पर नहीं ले जाएगा। अपनी फ़ाइलों का बैकअप लें, फिर Atlas ISO से Windows दोबारा इंस्टॉल करें।
detail-move-hardware-unread = Atlas इस PC का पूरा हार्डवेयर नहीं पढ़ सका, इसलिए Windows Update इसकी जाँच करेगा।
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } पर { $free } GB ख़ाली है।
detail-move-space-short = संस्करण { $release } के लिए { $drive } पर { $needed } GB ख़ाली जगह चाहिए, और उस पर { $free } GB ख़ाली है। जगह ख़ाली करें, Atlas अपने-आप दोबारा जाँच लेगा।
detail-move-space-unknown = Windows अपडेट के लिए ख़ाली जगह की जाँच नहीं हो सकी। अपना PC रीस्टार्ट करें, फिर दोबारा जाँचें। ({ $error })
detail-move-update-source-ok = इस PC को Windows Update से अपडेट मिलते हैं।
detail-move-update-source-managed = इस PC को इसके संगठन के सर्वर से अपडेट मिलते हैं, जो संस्करण { $release } उपलब्ध नहीं कराता। अपने संगठन से पूछें, या Atlas ISO से Windows दोबारा इंस्टॉल करें।

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = Microsoft Defender, प्रोसेसर सुरक्षा और अपडेट सेटिंग्स को आप बाद में अपने डेस्कटॉप पर मौजूद Atlas फ़ोल्डर से बदल सकते हैं।
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = कोई नहीं चुना गया
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked =
    { $count ->
        [1] { $count } चुना गया
       *[other] { $count } चुने गए
    }
# Links that unfold and fold the Optional extras card.
options-extras-show = दिखाएँ
options-extras-hide = छिपाएँ
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender, Windows में पहले से मौजूद एंटीवायरस है।
question-mitigations-description = ये सुरक्षा उपाय, जिन्हें सुरक्षा मिटिगेशन भी कहा जाता है, Spectre और Meltdown जैसी प्रोसेसर की ख़ामियों और ऐप्स के बग का फ़ायदा उठाने वाले हमलों से बचाते हैं।
question-auto-updates-description = दोनों ही स्थितियों में Atlas, Windows को उसके मौजूदा संस्करण पर बनाए रखता है और Microsoft Store ऐप्स के अपने-आप होने वाले अपडेट बंद कर देता है।
question-browser-description = Atlas आपकी ब्राउज़र सेटिंग्स नहीं बदलेगा।
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = जब तक आप कोई दूसरा एंटीवायरस इंस्टॉल नहीं करते, आपके PC में कोई एंटीवायरस नहीं होगा, और अपरिचित ऐप या डाउनलोड खोलने से पहले Windows आपको चेतावनी नहीं देगा।
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = इससे ऐप्स के लिए शोषण से सुरक्षा भी बंद हो जाती है, जैसे नियंत्रण प्रवाह गार्ड (CFG), जिससे सुरक्षा कम होती है।
cost-auto-updates-disable = सुरक्षा सुधार पाने के लिए नियमित रूप से Windows Update खोलें।
cost-auto-updates-default = अपडेट इंस्टॉल करना पूरा करने के लिए Windows आपका PC रीस्टार्ट कर सकता है।
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift और Ctrl+Shift से अब भाषा या लेआउट नहीं बदलेगा।
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = डिस्क स्पेस ख़ाली होगा, लेकिन हाइबरनेट और तेज़ स्टार्टअप (Fast Startup) उपलब्ध नहीं रहेंगे।
extra-disable-power-saving = आपका PC ज़्यादा बिजली ले सकता है, ज़्यादा गर्म हो सकता है और बैटरी कम समय चल सकती है।
extra-disable-core-isolation = इससे सुरक्षा कम होती है, और हो सकता है कि Riot Vanguard या FACEIT जैसे एंटी-चीट वाले गेम तब तक शुरू न हों, जब तक आप मेमोरी अखंडता (Memory integrity) फिर से चालू न करें।
extra-uninstall-edge = इस PC पर आपके Edge बुकमार्क, इतिहास और सहेजे गए पासवर्ड मिट जाते हैं, सिवाय उनके जो आपके Microsoft खाते में सिंक हैं।
extra-install-toolbox = आपकी Atlas सेटिंग्स सँभालने में मदद करता है, हालाँकि बीटा में होने के कारण कुछ सुविधाएँ अधूरी हो सकती हैं।
extra-install-eclean = बेकार फ़ाइलों और स्टार्टअप ऐप्स की समीक्षा के लिए AtlasOS की टीम का टूल, जिसके लिए खाता और इंटरनेट कनेक्शन चाहिए।
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
# Each decision's short name in the middle of a sentence, as in summary-change-a11y,
# update-path-differs, preflight-choice-unanswered and installed-not-applied-choices. Hindi has no capitals, so these match the titles except where a
# title is a whole question or instruction.
screen-update-path-name = अपडेट का तरीका
screen-defender-name = Microsoft Defender
screen-mitigations-name = प्रोसेसर सुरक्षा
screen-updates-name = Windows Update
screen-keyboard-name = कीबोर्ड की भाषाएँ
screen-browser-name = ब्राउज़र
screen-power-name = पावर और सुरक्षा
screen-apps-name = ऐप्स
screen-optional-apps-name = वैकल्पिक ऐप्स
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title. मौजूद keeps it the same before के लिए and alone.
screen-package-choice-name = Atlas पैकेज में मौजूद एक विकल्प
screen-extras-name = अतिरिक्त विकल्प
# Question for a required choice this app has no specific wording for.
screen-generic-question = { $title } के लिए एक विकल्प चुनें
learn-more-defender = Microsoft Defender के बारे में और जानें
learn-more-mitigations = प्रोसेसर सुरक्षा के बारे में और जानें
learn-more-updates = Windows Update के बारे में और जानें
learn-more-browser = ब्राउज़र के बारे में और जानें
learn-more-power = पावर और सुरक्षा के बारे में और जानें
learn-more-apps = ऐप्स के बारे में और जानें
learn-more-eclean = eclean के बारे में और जानें
learn-more-keyboard = कीबोर्ड की भाषाओं के बारे में और जानें
learn-more-generic = सेटअप गाइड पढ़ें
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Windows का अपना एंटीवायरस चालू रहता है, जो आपके PC को वायरस और अन्य ख़तरों से बचाने में मदद करता है।
consequence-mitigations-default = Windows की डिफ़ॉल्ट सुरक्षा बनाए रखता है, जो प्रोसेसर की ख़ामियों और ऐप्स के बग का फ़ायदा उठाने वाले हमलों से बचाती है।
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = ऐप्स के लिए शोषण से सुरक्षा भी बंद कर देता है, जैसे नियंत्रण प्रवाह गार्ड (CFG)। इससे सुरक्षा कम होती है। प्रदर्शन में कोई अंतर आएगा या नहीं, यह आपके प्रोसेसर पर निर्भर करता है।
consequence-auto-updates-disable = नियमित रूप से Windows Update खोलकर अपडेट इंस्टॉल करें। अपडेट की सूचनाएँ चालू रहेंगी।
consequence-auto-updates-default = Windows अपडेट अपने-आप इंस्टॉल करेगा, जिनमें सुरक्षा सुधार भी शामिल हैं।

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = आप Atlas { $version } पर कैसे अपडेट करना चाहते हैं?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = आप Atlas { $version } को दोबारा कैसे इंस्टॉल करना चाहते हैं?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = मेरे विकल्प बनाए रखें
update-path-keep-detail = Atlas हर विकल्प वैसा ही रखता है, जैसा वह अभी इस PC पर है, और उनमें से किसी को नहीं बदलता।
update-path-choose = विकल्प दोबारा चुनें
update-path-choose-detail = इस PC के मौजूदा सेटअप से शुरू करें। आपके ऐप, फ़ाइलें और वैयक्तिकरण बने रहते हैं।
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = इस PC पर अभी लागू आपके विकल्प
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = Atlas आपके PC से यह पता नहीं लगा सकता, इसलिए आपसे पूछेगा
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = { $choices } के लिए यह PC, Atlas के रिकॉर्ड से मेल नहीं खाता।
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = बाकी हर विकल्प Atlas वैसा ही रखता है, जैसा वह अभी इस PC पर है।
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = अभी इस PC पर लागू
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas, Microsoft Defender को वापस लाता है। रीस्टार्ट के बाद Windows सुरक्षा में इसकी सुरक्षा सुविधाएँ चालू करें।
change-mitigations-default = Atlas, Windows की डिफ़ॉल्ट सेटिंग्स के अनुसार प्रोसेसर सुरक्षा फिर से चालू करता है। यह बदलाव रीस्टार्ट के बाद लागू होता है।
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = अभी सभी प्रोसेसर सुरक्षा उपाय चालू हैं। सुरक्षा बनाए रखने पर ये सभी चालू रहेंगे।
change-auto-updates-default = Atlas, Windows को फिर से अपडेट अपने-आप इंस्टॉल करने देता है।
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas हाइबरनेशन फिर से चालू करता है।
change-power-saving-on = Atlas पावर सेविंग फिर से चालू करता है और आपका पिछला पावर प्लान वापस लगाता है। अगर पिछला प्लान नहीं है, तो वह “संतुलित” प्लान लगाता है।
change-core-isolation-on = Atlas वर्चुअलाइज़ेशन-आधारित सुरक्षा (VBS) फिर से चालू करता है, बशर्ते इस PC पर कोई नीति इसे नियंत्रित न करती हो। यह बदलाव रीस्टार्ट के बाद लागू होता है।
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = इस PC के सभी उपयोगकर्ताओं के लिए Snipping Tool हटा देता है। Atlas इसे बाद में वापस नहीं ला सकता, लेकिन आप इसे Microsoft Store से फिर से इंस्टॉल कर सकते हैं।
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge पहले ही हटाया जा चुका है, और Atlas अपडेट करने से यह वापस नहीं आ सकता। इसे फिर से इंस्टॉल करने के लिए Atlas फ़ोल्डर में “Install or Remove Edge” इस्तेमाल करें।
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } इंस्टॉल है। Atlas ऐप अनइंस्टॉल नहीं करता। इसे हटाने के लिए Windows सेटिंग्स में “इंस्टॉल किए गए ऐप्स” पर जाएँ।
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } इंस्टॉल रहता है, और Atlas साथ में { $browser } भी इंस्टॉल करता है।

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Microsoft Defender रखें (सुझाया गया)
package-option-defender-enable-short = Microsoft Defender रखें
package-option-defender-disable = Microsoft Defender हटाएँ
package-option-mitigations-default = प्रोसेसर सुरक्षा बनाए रखें (सुझाया गया)
package-option-mitigations-default-short = प्रोसेसर सुरक्षा बनाए रखें
package-option-mitigations-disable = प्रोसेसर सुरक्षा बंद करें
package-option-auto-updates-disable = अपडेट ख़ुद इंस्टॉल करें
package-option-auto-updates-default = अपडेट अपने-आप इंस्टॉल करें
package-option-disable-hibernation = हाइबरनेशन बंद करें
package-option-disable-power-saving = पावर सेविंग बंद करें
package-option-disable-core-isolation = वर्चुअलाइज़ेशन-आधारित सुरक्षा (VBS) बंद करें
package-option-remove-snipping-tool = Snipping Tool हटाएँ
package-option-uninstall-edge = Microsoft Edge हटाएँ
package-option-install-another-browser = कोई ब्राउज़र इंस्टॉल करें
package-option-install-toolbox = Atlas Toolbox इंस्टॉल करें
package-option-install-eclean = eclean इंस्टॉल करें
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender, Windows में पहले से मौजूद एंटीवायरस है। इसे तभी हटाएँ, जब आप इसके जोखिम समझते हों और कोई दूसरा एंटीवायरस ऐप इस्तेमाल करने वाले हों। आप जो भी चुनें, Atlas ये सुविधाएँ बंद कर देता है: स्मार्ट ऐप नियंत्रण, उन्नत फ़िशिंग सुरक्षा और मेरा डिवाइस ढूँढें।
package-choice-mitigations-description = ये सुरक्षा उपाय, जिन्हें सुरक्षा मिटिगेशन भी कहा जाता है, Spectre और Meltdown जैसी प्रोसेसर की ख़ामियों से और ऐप्स के बग का फ़ायदा उठाने वाले हमलों से बचाने में मदद करते हैं। Windows की डिफ़ॉल्ट सेटिंग्स बनाए रखने का सुझाव दिया जाता है।
package-choice-auto-updates-description = Windows अपडेट में सुरक्षा सुधार शामिल होते हैं। आप चाहें तो Windows उन्हें अपने-आप इंस्टॉल कर सकता है, या आप उन्हें ख़ुद इंस्टॉल कर सकते हैं। दोनों ही स्थितियों में Atlas, Windows को उसके मौजूदा संस्करण पर बनाए रखता है, जिसे सुरक्षा सुधार तभी तक मिलते हैं, जब तक Microsoft उसका समर्थन बंद नहीं कर देता। Atlas, Microsoft Store ऐप्स के अपने-आप होने वाले अपडेट भी बंद कर देता है, इसलिए उन्हें Microsoft Store में अपडेट करें।
package-choice-browser-description = इंस्टॉल करने के लिए कोई ब्राउज़र चुनें। Atlas आपकी ब्राउज़र सेटिंग्स नहीं बदलेगा।

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = इस PC पर Microsoft Defender इंस्टॉल नहीं है
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = बंद करने के लिए कोई सुरक्षा स्विच नहीं है।
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas ने इस PC से Microsoft Defender हटा दिया है
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = इस इंस्टॉलेशन में Atlas, Microsoft Defender को वापस लाएगा
security-restore-nothing-to-turn-off = Defender अभी चल नहीं रहा है, इसलिए बंद करने के लिए कुछ नहीं है। रीस्टार्ट के बाद Windows सुरक्षा में इसकी सुरक्षा सुविधाएँ चालू करें।
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = Microsoft Defender मौजूद नहीं है
security-banner-missing-message = Atlas ने इसे नहीं हटाया था, इसलिए वह इसे वापस नहीं ला सकता। आप जारी रख सकते हैं, लेकिन जब तक आप कोई दूसरा एंटीवायरस ऐप इंस्टॉल नहीं करते या Windows को ठीक नहीं करते, तब तक आपके PC में कोई एंटीवायरस नहीं होगा।
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = ये चारों स्विच बंद करें
security-turn-off-message = इंस्टॉल होते समय Microsoft Defender, Atlas को रोक सकता है। अगर आप Defender रखते हैं, तो इंस्टॉल होने के बाद इन्हें फिर से चालू करें।
# The page name in Windows Security.
security-list-title = वायरस और ख़तरे से सुरक्षा सेटिंग्स
security-switch-off = बंद
security-switch-on = चालू
security-switch-unreadable = पढ़ा नहीं जा सका
security-switch-reading = जाँच हो रही है
security-all-off = सभी बंद
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on = { $count } अभी भी चालू
security-count-unreadable =
    { $count ->
        [1] { $count } पढ़ा नहीं जा सका
       *[other] { $count } पढ़े नहीं जा सके
    }
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. The
# Hindi agrees with Atlas, so it doesn't change with $count.
security-unread-switches-title =
    { $count ->
       *[other] Atlas { $switches } की स्थिति नहीं पढ़ सका
    }
security-unread-message =
    { $count ->
        [1] Windows सुरक्षा में पक्का करें कि यह बंद है।
       *[other] Windows सुरक्षा में पक्का करें कि ये बंद हैं।
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [1] मैंने जाँच लिया है कि { $switches } बंद है
       *[other] मैंने जाँच लिया है कि { $switches } बंद हैं
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = मैंने Windows सुरक्षा में देख लिया है और चारों स्विच बंद हैं
security-unknown-unelevated-title = सुरक्षा जाँचने के लिए Atlas को अनुमति चाहिए
security-unknown-unelevated-message = Atlas को व्यवस्थापक के रूप में दोबारा खोलें, ताकि वह Microsoft Defender की सेटिंग्स जाँच सके।
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = छेड़छाड़ से सुरक्षा
protection-tamper-why = ताकि Atlas सुरक्षा सेटिंग्स बदल सके।
protection-realtime = रीयल-टाइम सुरक्षा
protection-realtime-reason = स्कैन, Atlas की फ़ाइलों को ब्लॉक कर सकते हैं।
protection-cloud = क्लाउड-आधारित सुरक्षा
protection-cloud-reason = ऑनलाइन जाँचें Atlas की फ़ाइलों को ब्लॉक कर सकती हैं।
protection-samples = स्वचालित नमूना सबमिशन
protection-samples-why = ताकि Atlas की फ़ाइलें Microsoft को न भेजी जाएँ।

## Step 4: Install

outcome-succeeded-title = Atlas इंस्टॉल हो गया है
outcome-lost-title = इंस्टॉलेशन के नतीजे की पुष्टि नहीं हो सकी
outcome-failed-title = इंस्टॉलेशन पूरा नहीं हुआ
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = आपका PC इंस्टॉलेशन की आवश्यकताएँ पूरी नहीं करता था, इसलिए इंस्टॉलेशन से कोई बदलाव नहीं हुआ।
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = आपका PC इंस्टॉलेशन की आवश्यकताएँ पूरी नहीं करता था, इसलिए यह प्रयास रुक गया। पिछला प्रयास पहले ही बदलाव कर चुका है।
# Beside common-restart-as-administrator.
result-not-elevated = Atlas के पास व्यवस्थापक की अनुमति नहीं थी, इसलिए इंस्टॉलेशन से कोई बदलाव नहीं हुआ।
result-not-elevated-resumed = Atlas के पास व्यवस्थापक की अनुमति नहीं थी, इसलिए यह प्रयास रुक गया। पिछला प्रयास पहले ही बदलाव कर चुका है।
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas पुष्टि नहीं कर सका कि Windows और Store ऐप अप टू डेट हैं, इसलिए Windows में कोई बदलाव करने से पहले ही इंस्टॉलेशन रुक गया।
result-preparation-stale-resumed = Atlas पुष्टि नहीं कर सका कि Windows और Store ऐप अप टू डेट हैं, इसलिए यह प्रयास रुक गया। पिछला प्रयास पहले ही बदलाव कर चुका है।
result-failed-preflight = कोई भी बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। आप फिर कोशिश कर सकते हैं।
result-failed-staging = फ़ाइलें तैयार करते समय, Windows में कोई बदलाव करने से पहले ही इंस्टॉलेशन रुक गया। आप फिर कोशिश कर सकते हैं।
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = हो सकता है कि कुछ बदलाव पहले ही हो चुके हों। आप फिर कोशिश कर सकते हैं, या अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में सुरक्षा स्विच फिर से चालू करें।
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = हो सकता है कि कुछ बदलाव पहले ही हो चुके हों। आप फिर कोशिश कर सकते हैं।
result-failed-resumed = यह प्रयास जल्दी रुक गया, लेकिन पिछला प्रयास पहले ही बदलाव कर चुका है। आप फिर कोशिश कर सकते हैं, या अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में सुरक्षा स्विच फिर से चालू करें।
result-failed-resumed-defender-removed = यह प्रयास जल्दी रुक गया, लेकिन पिछला प्रयास पहले ही बदलाव कर चुका है। आप फिर कोशिश कर सकते हैं।
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = यह प्रयास उसी त्रुटि पर रुका, जिस पर पिछला प्रयास रुका था, इसलिए फिर कोशिश करने से शायद फ़ायदा नहीं होगा। रिपोर्ट भेजें, ताकि Atlas टीम कारण ढूँढ सके, और अगर आप यहीं रुकते हैं, तो अपने सुरक्षा स्विच फिर से चालू करें।
result-failed-repeated-defender-removed = यह प्रयास उसी त्रुटि पर रुका, जिस पर पिछला प्रयास रुका था, इसलिए फिर कोशिश करने से शायद फ़ायदा नहीं होगा। रिपोर्ट भेजें, ताकि Atlas टीम कारण ढूँढ सके।
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows ने अब भी { $apps } को नहीं हटाया, इसलिए फिर कोशिश करने से शायद फ़ायदा नहीं होगा। रिपोर्ट भेजें, ताकि Atlas टीम कारण ढूँढ सके, और अगर आप यहीं रुकते हैं, तो अपने सुरक्षा स्विच फिर से चालू करें।
result-failed-repeated-apps-defender-removed = Windows ने अब भी { $apps } को नहीं हटाया, इसलिए फिर कोशिश करने से शायद फ़ायदा नहीं होगा। रिपोर्ट भेजें, ताकि Atlas टीम कारण ढूँढ सके।
result-not-started = इंस्टॉलर समय पर शुरू नहीं हुआ, इसलिए इंस्टॉलेशन से कोई बदलाव नहीं हुआ। आप फिर कोशिश कर सकते हैं।
result-lost = इंस्टॉलर कोई नतीजा बताए बिना रुक गया, इसलिए हो सकता है कि कुछ बदलाव हो चुके हों। आप फिर कोशिश कर सकते हैं, या अगर आप यहीं रुकते हैं, तो Windows सुरक्षा में सुरक्षा स्विच फिर से चालू करें।
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = इंस्टॉलर कोई नतीजा बताए बिना रुक गया, इसलिए हो सकता है कि कुछ बदलाव हो चुके हों। आप फिर कोशिश कर सकते हैं।
restart-now-message = Atlas का सेटअप पूरा करने के लिए Windows रीस्टार्ट हो रहा है।
restart-stopped = स्वचालित रीस्टार्ट रद्द कर दिया गया है। अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
restart-needed = अपना काम सहेजें, फिर Atlas का सेटअप पूरा करने के लिए अपना PC रीस्टार्ट करें।
restart-dont-now = बाद में रीस्टार्ट करें
restart-now = अभी रीस्टार्ट करें
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = इंस्टॉलेशन शुरू नहीं हुआ
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# प्रोसेसर सुरक्षा.
preflight-choice-unanswered = Atlas को { $choice } के लिए आपका जवाब चाहिए।
preflight-choices-unusable = Atlas इन विकल्पों का इस्तेमाल नहीं कर सका।
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names. The Hindi doesn't change with $count.
preflight-checks-changed =
    { $count ->
       *[other] Atlas की पिछली जाँच के बाद से { $checks } पर ध्यान देने की ज़रूरत है।
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = आपके स्विच बंद करने के बाद Windows सुरक्षा बदल गई है: { $summary }।
preflight-busy-wait = Atlas की एक और विंडो इंस्टॉलेशन शुरू कर रही है। थोड़ा इंतज़ार करें, फिर कोशिश करें।
# Beside home-start-over.
preflight-taken-over-start-over = Atlas की एक दूसरी विंडो अब इस सेटअप का इस्तेमाल कर रही है। वहीं जारी रखें, या यहाँ नए सिरे से शुरू करें।
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas यह जाँच नहीं सका कि पिछला इंस्टॉलेशन अभी भी चल रहा है या नहीं, इसलिए उसने नया इंस्टॉलेशन शुरू नहीं किया।
preflight-not-started = Atlas इंस्टॉलर शुरू नहीं कर सका, इसलिए इंस्टॉलेशन से कोई बदलाव नहीं हुआ। आप फिर कोशिश कर सकते हैं।
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas इंस्टॉलर शुरू नहीं कर सका, लेकिन पिछला प्रयास पहले ही बदलाव कर चुका है। आप फिर कोशिश कर सकते हैं।
go-to-ready = तैयारी पर जाएँ
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = “आपके विकल्प” पर जाएँ
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = “Windows सुरक्षा” पर जाएँ
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = “इंस्टॉल” पर वापस जाएँ
output-problem-title = इंस्टॉलेशन की प्रगति नहीं पढ़ी जा सकी
install-elevate-title = इंस्टॉल करने के लिए Atlas को अनुमति चाहिए
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = Atlas के दोबारा खुलने पर Windows आपसे अनुमति माँगेगा।
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = Atlas पैकेज तैयार नहीं है
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = पहले तैयारी पूरी करें
install-not-ready-message = इंस्टॉल करने से पहले Atlas को आपके PC की जाँच और Windows का अपडेट पूरा करना होगा।
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = सुरक्षा स्विच फिर से बंद करें
install-switches-message = Windows सुरक्षा: { $summary }।
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = इंस्टॉल करने के लिए तैयार
summary-setup-title = आपका Atlas सेटअप
summary-activation = सक्रियण
summary-activation-ok = सक्रिय है। Atlas इसे नहीं बदलेगा।
summary-activation-missing = सक्रिय नहीं है। आप जारी रख सकते हैं, लेकिन Atlas, Windows को सक्रिय नहीं करेगा।
summary-activation-unknown = Atlas आपकी Windows सक्रियण स्थिति नहीं बदलेगा।
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't. मिनट doesn't change with the number.
summary-time-restarts = आम तौर पर लगभग { $minutes } मिनट, फिर आपका PC रीस्टार्ट होगा
summary-time-restart-yourself = आम तौर पर लगभग { $minutes } मिनट, फिर अपना PC रीस्टार्ट करें
# The check box on the card. It's the same setting as settings-restart-label.
summary-restart-automatically = इंस्टॉलेशन पूरा होने पर अपने-आप रीस्टार्ट करें
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = ये भी बंद होंगे
summary-turned-off-value = स्मार्ट ऐप नियंत्रण, उन्नत फ़िशिंग सुरक्षा और मेरा डिवाइस ढूँढें
summary-show-command = इंस्टॉलेशन कमांड दिखाएँ
summary-hide-command = इंस्टॉलेशन कमांड छिपाएँ
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = इंस्टॉलेशन कमांड कॉपी करें
summary-command-unavailable = इंस्टॉलेशन कमांड तैयार नहीं हो सकी। विवरण: { $error }
summary-not-chosen = अभी कोई विकल्प नहीं चुना गया
# Accessible name of a Change link. $title is a screen-*-name message, as it reads mid-sentence.
summary-change-a11y = { $title } बदलें
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = अपडेट का तरीका
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = इंस्टॉलेशन की तैयारी हो रही है
footer-checks-blocked = जारी रखने के लिए जाँच में मिली समस्याएँ ठीक करें
footer-manager-outdated = जारी रखने के लिए Atlas Manager का नया संस्करण डाउनलोड करें
footer-need-files = जारी रखने के लिए Atlas पैकेज प्राप्त करें
# Tester build variant of footer-need-files.
footer-need-package-bundled = जारी रखने के लिए साथ में दिया गया Atlas पैकेज तैयार करें
footer-drivers = जारी रखने के लिए ड्राइवर इंस्टॉल करने का तरीका चुनें
footer-windows-terms = जारी रखने के लिए लाइसेंस शर्तें स्वीकार करें
footer-updating = Windows और Store ऐप अपडेट हो रहे हैं…
footer-restart = जारी रखने के लिए अपना PC रीस्टार्ट करें
footer-reading-security = सुरक्षा स्विच की जाँच हो रही है
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = जारी रखने के लिए चारों स्विच बंद करें
footer-security-confirm = जारी रखने के लिए उन स्विच की पुष्टि करें, जिनकी जाँच Atlas नहीं कर सका
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
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

installing-title = Atlas इंस्टॉल हो रहा है
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = आपके PC की जाँच हो रही है…
installing-staging-label = Atlas की फ़ाइलें कॉपी हो रही हैं…
installing-applying-label = Windows सेट अप हो रहा है…
installing-finishing-label = पूरा हो रहा है…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = अपना PC चालू और प्लग इन रखें। इंस्टॉलेशन पूरा होने पर यह अपने-आप रीस्टार्ट हो जाएगा।
installing-keep-on = अपना PC चालू और प्लग इन रखें। इंस्टॉलेशन पूरा होने पर इसे रीस्टार्ट करें।
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = इसका मतलब यह नहीं कि इंस्टॉलेशन रुक गया है।
installing-installed-title = Atlas इंस्टॉल हो गया है
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now. सेकंड doesn't change with the number.
installing-restart-countdown = आपका PC { $seconds } सेकंड में रीस्टार्ट होगा।
installing-restart-save = पहले अपना काम सहेजें।

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } इंस्टॉल हो गया है
installed-title = Atlas इंस्टॉल हो गया है
installed-ready = सब हो गया। आपका PC अब Atlas के साथ इस्तेमाल के लिए तैयार है।
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = चिपसेट, नेटवर्क और ग्राफ़िक्स ड्राइवर अपने PC, मदरबोर्ड या डिवाइस के निर्माता से लें।
installed-drivers-guide = ड्राइवर गाइड खोलें
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender हटा दिया गया है
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas ने इसे नहीं हटाया। अगर आप कोई दूसरा एंटीवायरस ऐप इस्तेमाल नहीं करते, तो अपने PC की सुरक्षा के लिए एक इंस्टॉल करें।
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender अब भी हटा हुआ है
defender-not-restored-message = Atlas का एक पिछला अपडेट इसे वापस नहीं लाया, इसलिए Defender आपके PC को सुरक्षित नहीं रख रहा है। Atlas दोबारा इंस्टॉल करें और Defender रखें, या Atlas फ़ोल्डर में 7. Security > Defender से Toggle Defender चलाएँ।
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = कुछ विकल्प लागू नहीं हुए
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender और प्रोसेसर सुरक्षा", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [1] यह विकल्प पहले जैसा ही रहा: { $choices }।
       *[other] ये विकल्प पहले जैसे ही रहे: { $choices }।
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = जैसा आपने चुना था, Windows Update फिर से बंद है
installed-update-off-message = जब तक यह बंद है, आपके PC को सुरक्षा अपडेट नहीं मिलते।
installed-update-paused-title = जैसा आपने चुना था, Windows अपडेट फिर से रोक दिए गए हैं
installed-update-paused-message = जब तक ये रुके हुए हैं, आपके PC को सुरक्षा अपडेट नहीं मिलते।

## Settings

settings-title = सेटिंग्स
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = स्वरूप
settings-installation = इंस्टॉलेशन
settings-privacy = गोपनीयता
settings-theme = ऐप थीम
settings-theme-system = Windows के अनुसार
settings-theme-light = हल्की
settings-theme-dark = गहरी
settings-theme-contrast-note = Atlas आपकी Windows कंट्रास्ट थीम के रंग इस्तेमाल कर रहा है।
settings-language = भाषा
# The setting in the Language section, and its box's name.
settings-app-language = ऐप की भाषा
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Windows के अनुसार – { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = पूर्वावलोकन
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = इस अनुवाद की अभी किसी मूल भाषी ने समीक्षा नहीं की है।
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } एक पूर्वावलोकन अनुवाद है और इसमें ग़लतियाँ हो सकती हैं।
preview-notice-switch = अंग्रेज़ी पर स्विच करें
preview-notice-language = भाषा बदलें
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = आपकी चुनी हुई भाषा Atlas के इस संस्करण में नहीं है, इसलिए Atlas अंग्रेज़ी दिखा रहा है। आपकी पसंद सहेजी गई है।
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas अभी आपकी Windows प्रदर्शन भाषा का समर्थन नहीं करता, इसलिए अंग्रेज़ी दिखा रहा है।
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas आपकी Windows प्रदर्शन भाषा की जाँच नहीं कर सका, इसलिए अंग्रेज़ी दिखा रहा है।
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = संख्याएँ, तारीख़ें और समय आपके Windows क्षेत्रीय प्रारूप के अनुसार दिखते हैं: { $locale }।
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = संख्याएँ आपके Windows क्षेत्रीय प्रारूप के अनुसार दिखती हैं: { $locale }। तारीख़ें और समय एक मानक प्रारूप में दिखते हैं, क्योंकि Atlas अभी दाएँ से बाएँ लिखा जाने वाला टेक्स्ट नहीं दिखा सकता।
settings-language-contribute = GitHub पर Atlas के अनुवाद में मदद करें
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Atlas के साथ उपयोग डेटा साझा करें
settings-share-usage-description = आपके खोले गए पेज, बनाए गए ISO और इंस्टॉलेशन सफल हुए या नहीं।
settings-privacy-policy = गोपनीयता नीति
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = इंस्टॉल और अपडेट करने के बाद अपने-आप रीस्टार्ट करें
settings-restart-automatically-description = Atlas का काम पूरा होने के एक मिनट के अंदर आपका PC रीस्टार्ट हो जाता है, जिससे खुले ऐप बंद हो जाते हैं।
settings-restart-locked = इंस्टॉलेशन पूरा होने के बाद आप इसे बदल सकते हैं।
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = मदद
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
consequence-disable-core-isolation = मेमोरी अखंडता (Memory integrity) समेत Windows की सुरक्षा की एक अतिरिक्त परत बंद कर देता है। इससे सुरक्षा कम होती है, और हो सकता है कि Riot Vanguard या FACEIT जैसे एंटी-चीट वाले गेम तब तक शुरू न हों, जब तक आप मेमोरी अखंडता फिर से चालू न करें।
consequence-remove-snipping-tool = स्क्रीनशॉट लेने और स्क्रीन रिकॉर्ड करने वाला Windows ऐप हटा देता है।
consequence-uninstall-edge = Microsoft Edge ब्राउज़र हटा देता है। पक्का करें कि आपके पास कोई दूसरा ब्राउज़र है, या नीचे एक चुनें।
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = इस PC पर आपके Edge बुकमार्क, इतिहास और सहेजे गए पासवर्ड मिटा देता है।
consequence-install-another-browser = नीचे कोई ब्राउज़र चुनें, Atlas उसे आपके लिए इंस्टॉल कर देगा।
consequence-install-toolbox = अपनी Atlas सेटिंग्स सँभालने में मदद के लिए Atlas Toolbox जोड़ें। Toolbox अभी बीटा में है, इसलिए कुछ सुविधाएँ अधूरी हो सकती हैं।
consequence-install-eclean = AtlasOS की टीम का रखरखाव टूल, जो सेटअप के बाद PC को व्यवस्थित रखने में मदद करता है। बेकार फ़ाइलों और स्टार्टअप ऐप्स की समीक्षा करें। खाता और इंटरनेट कनेक्शन ज़रूरी है।

## ISO creation
iso-open = Atlas ISO बनाएँ
iso-title = Atlas ISO बनाएँ
iso-recommended = सुझाया गया
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = सेटअप
iso-step-create = बनाएँ
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = यह ISO किस PC के लिए है?
iso-target-this = यह PC
iso-target-another = कोई दूसरा PC
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = यह ISO { $architecture } PC के लिए है।
iso-source = Windows ISO
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Microsoft से डाउनलोड करें
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Names the download's language and architecture for the accessible name of its Change link.
iso-download-what = Windows डाउनलोड
iso-download-language = भाषा
iso-download-arch = आर्किटेक्चर
iso-download-languages = भाषाएँ लोड हो रही हैं…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Windows 11 डाउनलोड हो रहा है…
iso-download-amount = { $total } में से { $received }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas, Microsoft की डाउनलोड सेवा तक नहीं पहुँच सका। अपना इंटरनेट कनेक्शन जाँचें, फिर कोशिश करें।
iso-download-incomplete = डाउनलोड पूरा नहीं हुआ। अपना इंटरनेट कनेक्शन और ख़ाली जगह जाँचें, फिर कोशिश करें।
iso-download-website = Microsoft के डाउनलोड पेज पर जाएँ
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = ISO फ़ाइल चुनें
# A status pill while the files are checked, before Continue becomes available.
iso-checking = आपके Windows ISO की जाँच हो रही है…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = Windows ISO तैयार है, { $facts }
iso-package-latest-label = नवीनतम
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = Atlas की नवीनतम रिलीज़ इतनी पुरानी है कि यह Atlas Manager उसका इस्तेमाल नहीं कर सकता।
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Atlas का नवीनतम संस्करण लाया जा रहा है…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas नवीनतम संस्करण की जाँच नहीं कर सका। अपना इंटरनेट कनेक्शन जाँचें, फिर कोशिश करें।
# Accessible name of the Change button beside a file: $action is that button's text and
# $field the file's label.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = जारी रखने के लिए Windows ISO प्राप्त करें
# The question on the Setup step about when the package's choices are made.
iso-mode-question = आप Atlas के विकल्प कब चुनना चाहते हैं?
iso-mode-after = साइन इन के बाद
iso-mode-after-description = साइन इन करने के बाद Atlas सेटअप में आपका मार्गदर्शन करता है।
iso-mode-now = अभी
iso-mode-now-description = विकल्प ISO में सहेजे जाते हैं। साइन इन करने के बाद आप Atlas इंस्टॉल करते हैं।
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = डेस्कटॉप खुलने से पहले पूरा करें
iso-mode-before-desktop-description = साइन इन करने के बाद, इंस्टॉल होने तक Atlas पूरी स्क्रीन पर चलता है।
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = यह Atlas पैकेज ISO में विकल्प नहीं सहेज सकता, इसलिए आप उन्हें साइन इन के बाद चुनेंगे।
iso-atlas-options = Atlas के विकल्प
# The line at the top of the Create step.
iso-create-intro = ISO बनाने से इस PC या आपके मूल ISO में कोई बदलाव नहीं होता।
iso-review-package = Atlas पैकेज
iso-review-output = नया ISO
iso-review-edition = संस्करण
iso-review-editions = संस्करण
iso-edition = Windows संस्करण
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Windows सेटअप पूछेगा
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install. It matches iso-edition-auto, which the card then shows.
iso-edition-auto-menu = Windows सेटअप पूछेगा
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Windows लाइसेंस शर्तें स्वीकार करें, ताकि Windows सेटअप न पूछे
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = खाते का नाम
iso-review-target = लक्षित PC
iso-review-drivers = ड्राइवर
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows सेटअप
iso-review-skips = Microsoft खाता और गोपनीयता स्क्रीन छोड़ देता है
iso-review-skips-terms = लाइसेंस, Microsoft खाता और गोपनीयता स्क्रीन छोड़ देता है
iso-review-network = नेटवर्क ड्राइवर
iso-review-network-included = इस PC के Wi-Fi और ईथरनेट ड्राइवर
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = अभी, डेस्कटॉप खुलने से पहले पूरा होगा
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = { $needed } चाहिए · { $drive } पर { $free } ख़ाली
iso-destination-short = ISO के लिए { $needed } चाहिए, और { $drive } पर { $free } ख़ाली है। जगह ख़ाली करें, या ISO किसी दूसरी ड्राइव पर सहेजें।
iso-destination-filesystem = { $drive } पर ISO की बड़ी फ़ाइलें नहीं रखी जा सकतीं। इसे NTFS में फ़ॉर्मैट की गई ड्राइव पर सहेजें, जैसे आपकी Windows ड्राइव।
iso-destination-unusable = Atlas, ISO को केवल इस PC की किसी ड्राइव के फ़ोल्डर में सहेज सकता है।
# Copying the ISO's files would pass Windows' limit of 260 characters for a path, even at the
# root of the drive the new ISO is saved to. Under iso-failed.
iso-path-too-long = जिस फ़ोल्डर में आप सहेज रहे हैं, उसमें ISO की फ़ाइलों को Windows की अनुमति से लंबे पाथ चाहिए होंगे। नया ISO छोटे पाथ वाले फ़ोल्डर में सहेजें, जैसे आपकी Windows ड्राइव का कोई फ़ोल्डर।
iso-create = ISO बनाएँ
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = आपका ISO बन रहा है…
# The progress bar's label: the stage under way, as a verb phrase ending in an ellipsis.
# $stage is one of the iso-stage-* messages.
iso-progress-stage = { $stage }…
iso-stage-read = Windows ISO पढ़ा जा रहा है
iso-stage-copy = Windows की फ़ाइलें कॉपी हो रही हैं
iso-stage-add-atlas = Atlas जोड़ा जा रहा है
iso-stage-master = ISO फ़ाइल लिखी जा रही है
iso-stage-verify = नए ISO की जाँच हो रही है
iso-stage-cleanup = आख़िरी काम निपटाए जा रहे हैं
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = जारी है
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = विफल
iso-stage-status-not-started = शुरू नहीं हुआ
iso-progress-keep-open = पूरा होने तक Atlas खुला रखें।
iso-cancel = बनाना रद्द करें
iso-cancelling = रद्द करने के लिए सुरक्षित पड़ाव का इंतज़ार है
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = रद्द किया जा रहा है…
iso-cancelled = ISO बनाना रद्द कर दिया गया
iso-cancelled-unchanged = आपके मूल ISO में कोई बदलाव नहीं हुआ।
iso-complete = आपका ISO तैयार है
iso-complete-backup = इससे Windows दोबारा इंस्टॉल करने से पहले अपनी फ़ाइलों का बैकअप लें।
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = USB ड्राइव बनाएँ
iso-open-folder = फ़ोल्डर में दिखाएँ
iso-failed = ISO बनाना पूरा नहीं हो सका
# Under iso-failed, beside Try again.
iso-failed-retry = पक्का करें कि आपकी फ़ाइलें अभी भी वहीं हैं, जहाँ से आपने उन्हें चुना था, और जिस ड्राइव पर आप सहेज रहे हैं, वह कनेक्ट है, फिर कोशिश करें।
# Title while checking the files fails; the messages below say why.
iso-check-failed = फ़ाइलों की जाँच नहीं हो सकी
iso-check-failed-retry = पक्का करें कि ISO और Atlas पैकेज का डाउनलोड पूरा हो गया है, फिर कोशिश करें।
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas अपना कार्य फ़ोल्डर तैयार नहीं कर सका, इसलिए कुछ नहीं बदला।
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = इस ISO में ऐसा कोई संस्करण नहीं है, जिसका Atlas समर्थन करता हो
iso-edition-unsupported = Windows Home और LTSC समर्थित नहीं हैं। Pro, Education या Enterprise वाला ISO इस्तेमाल करें।
iso-customised-title = इस ISO में बदलाव किए गए हैं
iso-customised = इसमें पहले से सेटअप फ़ाइलें हैं, जैसे autounattend.xml। Microsoft का बिना बदलाव वाला ISO इस्तेमाल करें।
iso-preview-title = यह ISO एक पूर्वावलोकन बिल्ड है
iso-preview = इसका Windows बिल्ड, Microsoft की सार्वजनिक रिलीज़ की सूची में नहीं है। Microsoft का ISO इस्तेमाल करें।
iso-windows-unsupported-title = यह Atlas पैकेज इस ISO का इस्तेमाल नहीं कर सकता
iso-windows-unsupported = Windows 11 के ऐसे संस्करण का बिना बदलाव वाला ISO इस्तेमाल करें, जिसका यह पैकेज समर्थन करता है।
iso-release-unknown-title = Atlas इस Windows रिलीज़ की पुष्टि नहीं कर सका
iso-release-unconfirmed = Atlas इसे Microsoft की सार्वजनिक रिलीज़ की सूची से मिलाता है। अपना इंटरनेट कनेक्शन जाँचें, फिर कोशिश करें।
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = इस Atlas पैकेज से ISO नहीं बनाया जा सकता
iso-package-old = Atlas { $minimum } या उससे नया संस्करण इस्तेमाल करें।
# Instead of iso-package-old-title and iso-package-old when the file chosen as the Atlas package is a Windows ISO. "The Windows ISO" is the field named iso-source.
iso-package-windows-iso-title = यह एक Windows ISO है, Atlas पैकेज नहीं
iso-package-windows-iso = इसके बजाय कोई Atlas पैकेज (.atlaspkg) चुनें, और इस ISO को Windows ISO के रूप में चुनें।
iso-manager-missing-title = Atlas Manager की फ़ाइल नहीं मिली
iso-fix-package = कोई दूसरा पैकेज चुनें
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager को अपडेट की ज़रूरत है
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas इस PC के नेटवर्क ड्राइवर ISO में नहीं जोड़ सका।
iso-network-skip = इनके बिना बनाएँ
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = ISO बनाने के लिए Atlas को अनुमति चाहिए
iso-admin-reason = आपका Windows ISO पढ़ने और नया ISO बनाने के लिए यह ज़रूरी है।
iso-elevation-declined = Windows ने Atlas को अनुमति नहीं दी, इसलिए वह अभी आपका Windows ISO नहीं पढ़ सकता।
# The free space ran out while the ISO was being created.
iso-failed-space = गंतव्य ड्राइव पर पर्याप्त ख़ाली जगह नहीं है। जगह ख़ाली करें, या नया ISO किसी दूसरी ड्राइव पर सहेजें।
# Under iso-manager-missing-title.
iso-manager-missing = AtlasManager.exe को डाउनलोड जैसे किसी स्थानीय फ़ोल्डर में सहेजें, फिर उसे वहीं से खोलें।
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = इस ISO में कोई समर्थित Windows संस्करण नहीं है। Windows Home और LTSC समर्थित नहीं हैं। ऐसा ISO इस्तेमाल करें, जिसमें कोई दूसरा संस्करण हो, जैसे Pro, Education या Enterprise।
# Windows didn't open an ISO as a drive Atlas can read: the Windows ISO, the new ISO while it's
# checked, or the ISO a USB drive is made from. Under iso-check-failed or iso-failed, or on the
# USB page's ISO card.
iso-mount-failed = Windows ISO नहीं खोल सका। अपना PC रीस्टार्ट करें, फिर कोशिश करें।
# Windows stopped answering while it read or mounted the ISO.
iso-mount-timeout = ISO खोलते समय Windows ने जवाब देना बंद कर दिया। अपना PC रीस्टार्ट करें, फिर कोशिश करें।
# vdrvroot and cdrom are the Windows drivers' own names, as tools that turn drivers off show
# them. Keep them as they are.
iso-mount-drivers = इस PC पर Windows ISO फ़ाइलें नहीं खोल सकता, क्योंकि इसके लिए ज़रूरी ड्राइवर, vdrvroot और cdrom, बंद हैं। उन्हें फिर से चालू करें, अपना PC रीस्टार्ट करें, फिर कोशिश करें।
# Windows can store a file compressed or encrypted (in the file's Properties, under Advanced),
# and a download can be stored sparse, with space reserved but not yet written. Windows can't
# open an ISO stored any of these ways. Under iso-check-failed, with iso-download-windows and
# iso-use-local beside it, or on the USB page's ISO card.
iso-mount-file = Windows यह ISO नहीं खोल सकता, क्योंकि फ़ाइल कंप्रेस, एन्क्रिप्ट या स्पार्स (sparse) है। इसे ऐसे फ़ोल्डर में कॉपी करें जो कंप्रेस या एन्क्रिप्ट न हो, फिर वह कॉपी इस्तेमाल करें।
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = लॉग फ़ोल्डर खोलें
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas अभी Windows Update के साथ काम कर रहा है। इसके पूरा होने के बाद आप यहाँ जारी रख सकते हैं।
# Names of the markers Windows sets when it wants a restart. They complete
# "Your PC needs to restart to finish installing updates (…)"; keep them short and lower
# case where the language allows.
prepare-reason-servicing = Windows सर्विसिंग
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = बदले जाने की प्रतीक्षा में फ़ाइलें
prepare-reason-update-agent = Windows Update सेवा
prepare-reason-unknown = कारण नहीं बताया गया
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = अगर फिर कोशिश करने से फ़ायदा न हो, तो बाकी अपडेट Windows Update या Microsoft Store में पूरे करें।
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = कुछ अपडेट पूरे नहीं हो सके
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = अपडेट करना कोई नतीजा बताए बिना रुक गया।
# Title of the bar over prepare-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = अपडेट के नतीजे की पुष्टि नहीं हो सकी
prepare-affected-app = प्रभावित ऐप
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = { $app } बंद करें, फिर कोशिश करें। अगर यह न मिले, तो इसे कार्य प्रबंधक में बंद करें।
prepare-install-busy = कोई दूसरा इंस्टॉलेशन या ज़रूरी रीस्टार्ट अपडेट रोक रहा है। दूसरे इंस्टॉलेशन पूरे होने दें, अगर Windows कहे तो अपना PC रीस्टार्ट करें, फिर कोशिश करें।
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows ख़ुद को ठीक नहीं कर सका
prepare-components-damaged = Windows के अनुसार उसमें ऐसी ख़राबी है, जो अपडेट इंस्टॉल नहीं होने देती। रीस्टार्ट से यह ठीक हो सकती है, और साइन इन करने के बाद Atlas जारी रखेगा।
prepare-restart-and-retry = रीस्टार्ट करके फिर कोशिश करें
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows इतना ख़राब है कि अपडेट नहीं हो सकता
prepare-components-unrepairable = अपनी फ़ाइलों का बैकअप लें, फिर Atlas ISO से Windows दोबारा इंस्टॉल करें।
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas उस खाते से अलग खाते में चल रहा है, जिससे Windows में साइन इन किया गया है। व्यवस्थापक खाते से Windows में साइन इन करें, उसी खाते से Atlas खोलें, फिर कोशिश करें।
prepare-failed-store-missing = आपके खाते के लिए Microsoft Store सेट अप नहीं है। Microsoft Store एक बार खोलें, या अगर वह मौजूद नहीं है तो उसे दोबारा इंस्टॉल करें, फिर कोशिश करें।
prepare-failed-store-battery = बैटरी बचाने के लिए Microsoft Store ने अपडेट रोक दिए हैं। अपना PC प्लग इन करें, फिर कोशिश करें।
prepare-failed-store-network = Microsoft Store ने अपडेट रोक दिए हैं, क्योंकि आपका PC मीटर्ड कनेक्शन पर है। ऐसे Wi-Fi या ईथरनेट से कनेक्ट करें जो मीटर्ड कनेक्शन न हो, फिर कोशिश करें।
prepare-failed-store-timeout = Store ऐप अभी पूरी तरह अपडेट नहीं हुए हैं। Microsoft Store में बाकी डाउनलोड पूरे करें, फिर कोशिश करें।
prepare-failed-store-passes = Microsoft Store लगातार नए अपडेट देता रहा। Microsoft Store में बाकी अपडेट पूरे करें, फिर कोशिश करें।
prepare-failed-manual-updates = कुछ Windows अपडेट Windows Update में ही पूरे करने होंगे। Windows Update खोलें, उन्हें पूरा करें, फिर कोशिश करें।
prepare-failed-windows-passes = Windows Update लगातार नए अपडेट देता रहा। Windows Update में बाकी अपडेट पूरे करें, फिर कोशिश करें।
prepare-failed-windows-update-unreachable = Windows Update, Microsoft के सर्वर तक नहीं पहुँच सका। अपना इंटरनेट कनेक्शन और कोई भी फ़ायरवॉल, प्रॉक्सी या VPN जाँचें, फिर कोशिश करें।
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-failed-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager किसी लिंक किए गए फ़ोल्डर में है। Atlas बंद करें, Atlas Manager को इस PC के किसी स्थानीय फ़ोल्डर में ले जाएँ, फिर उसे वहीं से खोलें।
prepare-error-code = त्रुटि कोड: { $code }
prepare-open-store = Microsoft Store खोलें
prepare-windows-search = Windows अपडेट जाँचे जा रहे हैं…
prepare-percent = इस पड़ाव का { $percent }% पूरा हुआ
prepare-count = पूरे हुए अपडेट: { $total } में से { $completed }
prepare-bytes = लगभग { $total } MB में से { $downloaded } MB डाउनलोड हुआ
prepare-progress-still = { $minutes } मिनट से कोई प्रगति नहीं हुई। बड़े अपडेट में समय लग सकता है, इसलिए Atlas खुला रखें।
prepare-report-late = Windows ने कुछ समय से प्रगति की जानकारी नहीं दी है। हो सकता है कि अपडेट अभी भी चल रहे हों, इसलिए Atlas खुला रखें।
prepare-windows-download = Windows अपडेट डाउनलोड हो रहे हैं…
prepare-windows-install = Windows अपडेट इंस्टॉल हो रहे हैं…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Windows ठीक किया जा रहा है…
prepare-windows-repair-detail = Windows के अनुसार उसमें ऐसी ख़राबी है, जो अपडेट इंस्टॉल होने से रोक सकती है। इसमें आधा घंटा या उससे ज़्यादा लग सकता है।
prepare-store-search = Microsoft Store की जाँच हो रही है…
prepare-store-install = Microsoft Store और उसके ऐप अपडेट हो रहे हैं…
prepare-stop = अपडेट करना रोकें
prepare-start = अपडेट जाँचें और इंस्टॉल करें
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Atlas पैकेज तैयार होने पर उपलब्ध होगा।
iso-username = स्थानीय खाते का नाम
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = पहली बार साइन इन करने पर आप पासवर्ड चुनेंगे।
iso-username-placeholder = आपका नाम
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = जारी रखने के लिए स्थानीय खाते का नाम दर्ज करें
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = अधिकतम 20 अक्षर इस्तेमाल करें, शुरुआत या अंत में स्पेस न रखें, और इनमें से कोई चिह्न न रखें: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = नाम के अंत में बिंदु (.) नहीं हो सकता।
iso-account-reserved = Windows इस नाम का इस्तेमाल एक अंतर्निहित खाते के लिए करता है। कोई दूसरा नाम चुनें।
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Windows सेटअप आपसे लाइसेंस की शर्तें स्वीकार करने को कहेगा।
prepare-drivers = ड्राइवर कैसे इंस्टॉल करने हैं?
prepare-drivers-auto = Windows Update से ड्राइवर प्राप्त करें
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Windows Update से ड्राइवर प्राप्त करें (सुझाया गया)
prepare-drivers-auto-detail = Windows आपके हार्डवेयर के लिए ड्राइवर ढूँढता है।
prepare-drivers-manual = ड्राइवर ख़ुद इंस्टॉल करें
prepare-drivers-manual-detail = Windows Update ड्राइवर इंस्टॉल नहीं करेगा, इसलिए आपको उन्हें अपने PC या डिवाइस के निर्माता से लेना होगा। पहले से इंस्टॉल ड्राइवर बने रहेंगे।
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = ड्राइवर
iso-network-drivers = इस PC के Wi-Fi और ईथरनेट ड्राइवर शामिल करें
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = साइन इन करने के बाद चुनें
prepare-network-unmetered = अपडेट के लिए ऐसा इंटरनेट कनेक्शन चाहिए, जो मीटर्ड न हो। Wi-Fi या ईथरनेट से कनेक्ट करें, फिर कोशिश करें।
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows के अनुसार इस नेटवर्क पर इंटरनेट उपलब्ध नहीं है। अगर नेटवर्क साइन इन करने को कहे, तो साइन इन करें, या अपना राउटर और कोई भी DNS या फ़ायरवॉल फ़िल्टरिंग जाँचें, फिर कोशिश करें।
# "मीटर्ड कनेक्शन" is the switch's name in Windows network settings.
prepare-network-metered = यह कनेक्शन मीटर्ड है या इस पर डेटा सीमा लगी है। ऐसे नेटवर्क से कनेक्ट करें जो मीटर्ड न हो, या नेटवर्क सेटिंग्स में “मीटर्ड कनेक्शन” बंद करें, फिर कोशिश करें।
prepare-network-settings = नेटवर्क सेटिंग्स खोलें
iso-stage-network-drivers = नेटवर्क ड्राइवर तैयार किए जा रहे हैं
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = इस PC के नेटवर्क एडेप्टर Windows के साथ आने वाले ड्राइवर इस्तेमाल करते हैं, इसलिए उन्हें ISO में शामिल करने की ज़रूरत नहीं है।
desktop-setup-description = अपने PC का सेटअप पूरा करें। Atlas के लिए आपके विकल्प सहेजे गए हैं; ज़रूरत पड़ने पर आप Windows पर लौट सकते हैं।
desktop-setup-exit = Windows में जारी रखें

# Windows installation USB
usb-title = USB ड्राइव बनाएँ
usb-existing = मौजूदा ISO से USB ड्राइव बनाएँ
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB ड्राइव
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows ISO
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = आपके डाउनलोड फ़ोल्डर में कोई Atlas ISO नहीं है।
usb-iso-checking = ISO की जाँच हो रही है…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas इस ISO से USB ड्राइव नहीं बना सकता। Atlas से बनाया गया ISO इस्तेमाल करें, या Microsoft का ऐसा Windows 11 ISO, जिसके संस्करण का Atlas समर्थन करता है।
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = ISO या Atlas Manager किसी नेटवर्क स्थान पर या लिंक किए गए फ़ोल्डर में है। उसे इस PC के किसी फ़ोल्डर में ले जाएँ, जैसे डाउनलोड।
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = यह ISO तैयार करने के लिए Windows ड्राइव पर पर्याप्त ख़ाली जगह नहीं है। कुछ जगह ख़ाली करें, Atlas अपने-आप दोबारा जाँच लेगा।
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas यह ISO नहीं पढ़ सका। फिर कोशिश करें, या कोई दूसरा ISO इस्तेमाल करें।
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = संग्रहण सेटिंग्स खोलें
usb-looking = USB ड्राइव ढूँढी जा रही हैं…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = { $size } GB या उससे बड़ी USB ड्राइव कनेक्ट करें।
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = बहुत छोटी है। { $size } GB या उससे बड़ी चाहिए।
usb-drive-too-small-iso = इस ISO के लिए बहुत छोटी है
usb-drive-has-iso = आपका ISO इसी ड्राइव पर है
usb-drive-has-app = Atlas Manager इसी ड्राइव से चल रहा है
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, and an ISO's architecture and size under its name.
usb-detail-separator = { " · " }
usb-create = USB ड्राइव बनाएँ
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = पहले कोई USB ड्राइव चुनें
# The question before erasing. $drive is the drive's name; $size is usb-drive-size or
# usb-drive-size-tb; $letters is its drive letters, such as "F:" or "F:, G:". A drive with no
# letter, such as one an unfinished write left, is asked with usb-confirm-title.
usb-confirm-title-letters = { $drive } ({ $size }, { $letters }) मिटाएँ?
usb-confirm-title = { $drive } ({ $size }) मिटाएँ?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = USB ड्राइव ({ $size }, { $letters }) मिटाएँ?
usb-confirm-title-unnamed = USB ड्राइव ({ $size }) मिटाएँ?
usb-confirm-message = इस पर मौजूद सब कुछ मिट जाएगा। आपका ISO बना रहेगा।
usb-confirm-erase = मिटाएँ और बनाएँ
usb-progress-title = USB ड्राइव बन रही है…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title. Each item
# shows done, under way or not started, so these are verbal nouns.
usb-stage-prepare-files = फ़ाइलें तैयार करना
usb-stage-formatting = फ़ॉर्मैट करना
usb-stage-copying = फ़ाइलें कॉपी करना
usb-stage-checking = ड्राइव की जाँच
usb-stage-ejecting = इजेक्ट करना
usb-keep-open = Atlas खुला रखें और ड्राइव कनेक्ट रहने दें।
usb-scan-failed-title = USB ड्राइव की सूची नहीं पढ़ी जा सकी
usb-scan-failed-retry = Atlas इस PC से कनेक्ट की गई ड्राइव नहीं पढ़ सका। फिर कोशिश करें।
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = USB ड्राइव नहीं बन सकी
usb-complete-title = आपकी USB ड्राइव तैयार है
# F12, F11 and Esc are key names.
usb-ready = इसे निकालें, जिस PC पर Windows दोबारा इंस्टॉल करना है, उसका बैकअप लें, फिर उस PC को USB ड्राइव से चालू करें। उसका बूट मेनू अक्सर F12, F11 या Esc से खुलता है।
# After erasing may have begun.
usb-failed-partial = ड्राइव पर कुछ हद तक ही लिखा जा सका। जाँचें कि वह कनेक्ट है, फिर कोशिश करें।
# Before anything on the drive was changed.
usb-failed-before-erase = ड्राइव में बदलाव करने से पहले ही Atlas रुक गया। फिर कोशिश करें।
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = USB ड्राइव बदल गई
usb-drive-changed = Atlas के मिटाने से पहले इसे हटाया या दोबारा कनेक्ट किया गया, इसलिए इस पर कुछ नहीं बदला।
usb-drive-cancelled-title = USB ड्राइव बनाना रद्द कर दिया गया
usb-cancelled-partial = ड्राइव अधूरी है। इस्तेमाल करने से पहले इसे फिर से बनाएँ।
usb-cancelled-unchanged = आपकी USB ड्राइव में कोई बदलाव नहीं हुआ।
usb-eject-failed-title = USB ड्राइव इजेक्ट नहीं हो सकी
usb-eject-failed-ready = यह इस्तेमाल के लिए तैयार है। इसे इस्तेमाल करने वाली फ़ाइलें या विंडो बंद करें, फिर कोशिश करें।
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = USB ड्राइव बनाने के लिए Atlas को अनुमति चाहिए
usb-admin-reason = ड्राइव को मिटाने और उस पर लिखने के लिए Atlas को व्यवस्थापक की अनुमति चाहिए।
usb-elevation-declined = Windows ने Atlas को अनुमति नहीं दी, इसलिए वह अभी USB ड्राइव पर नहीं लिख सकता।
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 Home, LTSC और Server संस्करण समर्थित नहीं हैं। कोई दूसरा संस्करण इस्तेमाल करें, जैसे Pro, Education या Enterprise। अगर Windows आपके संस्करण की पहचान नहीं कर सका, तो आगे बढ़ने से पहले यह समस्या ठीक करें।
install-source-title = इंस्टॉलेशन उपलब्ध नहीं है
install-source-unsupported = Atlas { $source } को सीधे { $target } पर अपडेट नहीं किया जा सकता। इस संस्करण का इस्तेमाल करने के लिए अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें।
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } को सीधे अपडेट नहीं किया जा सकता। नए संस्करण का इस्तेमाल करने के लिए अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें।
# $folder is a folder path (text).
install-source-resume-package = Atlas { $target } का एक इंस्टॉलेशन पूरा नहीं हुआ, और इसे केवल Atlas { $target } का पैकेज ही पूरा कर सकता है। वही Atlas पैकेज (.atlaspkg) खोलें। अगर Atlas ने इसे डाउनलोड किया था, तो यह { $folder } में है।
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = Atlas { $target } का एक इंस्टॉलेशन पूरा नहीं हुआ। यह परीक्षण बिल्ड केवल अपने साथ दिया गया Atlas पैकेज इंस्टॉल कर सकता है, इसलिए वह इंस्टॉलेशन Atlas Manager के रिलीज़ बिल्ड में Atlas { $target } के पैकेज से पूरा करें।
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas पुष्टि नहीं कर सका कि इस PC पर पहले से क्या इंस्टॉल है, इसलिए वह फ़िलहाल कुछ भी इंस्टॉल नहीं करेगा।
# Atlas's files are on this PC without a record of a finished installation. Create an Atlas ISO (iso-open) is beside it.
install-source-unrecorded = इस PC पर Atlas के पुराने संस्करण की फ़ाइलें हैं, लेकिन पूरे हुए इंस्टॉलेशन का कोई रिकॉर्ड नहीं है, इसलिए उसे अपडेट नहीं किया जा सकता। Atlas इंस्टॉल करने के लिए अपनी फ़ाइलों का बैकअप लें और Windows दोबारा इंस्टॉल करें।
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = Windows सेटअप में वह संस्करण चुनें, जिसका लाइसेंस आपके पास है।
detail-windows-preview = Insider बिल्ड समर्थित नहीं हैं। Windows 11 का सार्वजनिक रिलीज़ संस्करण इस्तेमाल करें।
detail-windows-release-unknown = Atlas पुष्टि नहीं कर सका कि यह Windows बिल्ड सार्वजनिक रूप से रिलीज़ हुआ है। इंटरनेट से कनेक्ट करें और दोबारा जाँचें।
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = बिल्ड { $build }, Microsoft की Windows 11 सार्वजनिक रिलीज़ की सूची में नहीं है, इसलिए Atlas अभी इस पर इंस्टॉल नहीं हो सकता। Release Preview और दूसरे पूर्वावलोकन बिल्ड समर्थित नहीं हैं। Microsoft के इस बिल्ड को सूची में जोड़ने के बाद दोबारा जाँचें।


prepare-continue = अपडेट जारी रखें
prepare-saving-restart = आपके विकल्प सहेजे जा रहे हैं और Windows रीस्टार्ट होने के बाद Atlas दोबारा खोलने की व्यवस्था की जा रही है…
prepare-restart-save-failed = आपके विकल्प सहेजे नहीं जा सके। रीस्टार्ट करने से पहले फिर कोशिश करें।
prepare-restart-registration-failed = आपके विकल्प सहेजे गए हैं, लेकिन Atlas रीस्टार्ट के बाद अपने-आप दोबारा खुलने की व्यवस्था नहीं कर सका। फिर कोशिश करें, या अपना PC ख़ुद रीस्टार्ट करें और साइन इन करने के बाद Atlas खोलें।
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = आपके विकल्प सहेजे गए हैं, लेकिन जब तक Atlas Manager किसी लिंक किए गए फ़ोल्डर में है, Atlas रीस्टार्ट के बाद अपने-आप दोबारा खुलने की व्यवस्था नहीं कर सकता। Atlas बंद करें और Atlas Manager को इस PC के किसी स्थानीय फ़ोल्डर में ले जाएँ। फिर उसे वहीं से खोलें, या अपना PC ख़ुद रीस्टार्ट करें और साइन इन करने के बाद उसे वहीं से खोलें।
prepare-restart-failed = Atlas आपका PC रीस्टार्ट नहीं कर सका। फिर कोशिश करें, या स्टार्ट मेनू से इसे रीस्टार्ट करें। आपके विकल्प सहेजे गए हैं, और साइन इन करने के बाद Atlas फिर से खुल जाएगा।
diagnostics-export = डायग्नोस्टिक्स निर्यात करें
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = डायग्नोस्टिक्स इकट्ठा किए जा रहे हैं…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = मदद पाएँ
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = डायग्नोस्टिक्स सहेजे गए
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Atlas के { $folder } फ़ोल्डर में { $file } नाम से सहेजे गए।
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas ने इसमें से आपका उपयोगकर्ता नाम, PC का नाम, ईमेल पते और पहचाने गए पासवर्ड या कुंजियाँ हटा दी हैं।
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = डायग्नोस्टिक्स ZIP सहेजी नहीं जा सकी

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } परीक्षण बिल्ड। यह ऐप केवल साथ में दिया गया Atlas पैकेज इंस्टॉल करता है।
home-status-bundled = परीक्षण बिल्ड { $release }
package-bundled = इस परीक्षण बिल्ड के साथ दिया गया Atlas { $version } इंस्टॉल के लिए तैयार है।
rc-about-release = परीक्षण बिल्ड
rc-about-commit = स्रोत कमिट
rc-about-package = साथ में दिया गया Atlas पैकेज (SHA-256)
iso-package-bundled = इस परीक्षण बिल्ड के साथ दिया गया Atlas पैकेज

check-user-account = उपयोगकर्ता खाता
detail-user-account-ok = UAC चालू है और आपका खाता इंस्टॉलेशन के लिए तैयार है।
detail-user-account-not-ready = उपयोगकर्ता खाता नियंत्रण (UAC) चालू करें, अपना PC रीस्टार्ट करें और फिर कोशिश करें। अगर आप अंतर्निहित Administrator खाते का इस्तेमाल करते हैं, तो किसी दूसरे व्यवस्थापक खाते से साइन इन करें।
detail-user-account-work-or-school = Atlas को कार्य या विद्यालय खाते (Microsoft Entra ID) से इंस्टॉल नहीं किया जा सकता। किसी स्थानीय खाते या Microsoft खाते से साइन इन करें, फिर कोशिश करें।
detail-user-account-check-failed = Atlas आपके उपयोगकर्ता खाते की जाँच नहीं कर सका। अपना PC रीस्टार्ट करें, फिर Atlas दोबारा खोलकर फिर से जाँचें। Windows ने बताया: { $error }

footer-prepare-required = जारी रखने के लिए Windows और Store ऐप अपडेट करना पूरा करें
# "Stage" as in prepare-close-stops-after-stage: पड़ाव.
footer-prepare-stopping-stage = मौजूदा पड़ाव पूरा होते ही अपडेट रुक जाएँगे…
resume-choices-title = आपका पिछला इंस्टॉलेशन जारी है
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = वह इंस्टॉलेशन पूरा करने के लिए Atlas पिछली बार चुने गए आपके विकल्प इस्तेमाल करता है, इसलिए उसके पूरा होने तक इन्हें बदला नहीं जा सकता।

## Voluntary reports
report-title = रिपोर्ट भेजें
report-received = रिपोर्ट मिल गई
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = इस रिपोर्ट के बारे में Atlas टीम से संपर्क करने के लिए यह संदर्भ सँभालकर रखें। अगर आपने संपर्क विवरण दिए हैं, तो टीम जवाब देने के लिए उनका इस्तेमाल कर सकती है, लेकिन जवाब मिलने की गारंटी नहीं है।
# Accessible name of the Copy button beside the report reference.
report-copy-reference = रिपोर्ट संदर्भ कॉपी करें
report-another = एक और रिपोर्ट भेजें
# Label of the choice between the two kinds of report.
report-kind = आप क्या भेजना चाहते हैं?
report-kind-issue = समस्या
report-kind-suggestion = सुझाव
report-message = आपका संदेश
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = क्या हुआ, और आप क्या कर रहे थे?
report-message-placeholder-suggestion = आप क्या बदलना चाहेंगे?
# Under the message box, which also reads it out.
report-message-help = पासवर्ड शामिल न करें।
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $max } में से { $count } अक्षर
report-contact = संपर्क जानकारी (वैकल्पिक)
report-contact-placeholder = ईमेल या Discord उपयोगकर्ता नाम
report-attach = डायग्नोस्टिक्स शामिल करें
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = लॉग और सिस्टम की जानकारी, जो कारण ढूँढने में मदद करती है। Atlas आपका उपयोगकर्ता नाम, PC का नाम, ईमेल पते और पहचाने गए पासवर्ड या कुंजियाँ हटा देता है। त्रुटि का विवरण, हार्डवेयर मॉडल और ऐप के नाम रखे जाते हैं। भेजने से पहले आप ZIP की समीक्षा कर सकते हैं।
report-review = ZIP की समीक्षा करें
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = डायग्नोस्टिक्स तैयार नहीं हो सके
report-prepare-failed-advice = फिर कोशिश करें, या डायग्नोस्टिक्स के बिना भेजें।
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = आपकी रिपोर्ट निजी तौर पर reports.atlasos.net पर Atlas टीम को जाती है। आपका संदेश और संपर्क विवरण जैसे लिखे गए हैं, वैसे ही भेजे जाते हैं। जाँच में मदद के लिए टीम दूसरी कंपनियों की AI सेवाओं का इस्तेमाल कर सकती है। इन सेवाओं को आपका संदेश और डायग्नोस्टिक्स मिलते हैं, लेकिन आपके संपर्क विवरण नहीं। रिपोर्टें 90 दिन बाद हटा दी जाती हैं, और सर्वर के सुरक्षा लॉग में आपका IP पता दर्ज हो सकता है।
report-website = गोपनीयता और रिपोर्ट वेबसाइट
report-consent = मैं यह रिपोर्ट और इसमें शामिल डायग्नोस्टिक्स Atlas टीम को भेजने के लिए सहमत हूँ
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = अपना इंटरनेट कनेक्शन जाँचें, फिर कोशिश करें। आप इसे रिपोर्ट वेबसाइट से भी भेज सकते हैं।
report-not-sent-busy = रिपोर्ट सेवा अभी व्यस्त है। कुछ मिनट रुकें, फिर कोशिश करें।
report-not-sent-outdated = Atlas Manager का यह संस्करण रिपोर्ट नहीं भेज सकता। अपना संदेश रिपोर्ट वेबसाइट में कॉपी करें, और अगर आपने डायग्नोस्टिक्स शामिल किए थे, तो साथ में ZIP भी।
report-not-sent-diagnostics = डायग्नोस्टिक्स भेजे नहीं जा सके। फिर कोशिश करें, या डायग्नोस्टिक्स के बिना भेजें।
# The footer's button where this version can't send.
report-failed-website = रिपोर्ट वेबसाइट खोलें
# Beside a spinner in the footer while the report is on its way.
report-sending = भेज रहे हैं…
report-send = रिपोर्ट भेजें

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = { $min }–{ $max } अक्षर लिखें।

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = संपर्क विवरण { $max } अक्षरों तक रखें।

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = इस रिपोर्ट को भेजने की सहमति की पुष्टि करें।

report-failed-title = रिपोर्ट नहीं भेजी गई

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = आपकी फ़ाइलें और ऐप बने रहते हैं।
home-plan-name = इस अपडेट के दो हिस्से हैं
home-plan-windows-title = Windows 11, संस्करण { $release }
home-plan-windows-step = Atlas इसे Windows Update से इंस्टॉल करता है, फिर आपका PC रीस्टार्ट होता है।
# The same step where moving is optional.
home-plan-windows-step-ask = वैकल्पिक। Atlas पहले पूछता है, फिर इसे Windows Update से इंस्टॉल करता है और आपका PC रीस्टार्ट होता है।
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = इंस्टॉल हो गया।
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas अपडेट होता है और आपके विकल्प बनाए रखता है, फिर आपका PC रीस्टार्ट होता है।
# $date and $until are dates.
home-end-of-updates-title = Windows 11, संस्करण { $current } के सुरक्षा अपडेट { $date } को बंद हो जाएँगे
home-end-of-updates-past-title = Windows 11, संस्करण { $current } को अब सुरक्षा अपडेट नहीं मिलते
home-end-of-updates-message = Atlas { $version } पर अपडेट करने से यह PC Windows 11, संस्करण { $release } पर भी चला जाता है, जिसे { $until } तक सुरक्षा अपडेट मिलेंगे।
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11, संस्करण { $release } को { $until } तक सुरक्षा अपडेट मिलेंगे।

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version }, Windows 11 Pro, Enterprise और Education के साथ काम करता है, इसलिए यह { $product } पर इंस्टॉल नहीं हो सकता।
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version }, Windows 11 Pro, Enterprise और Education के साथ काम करता है, इसलिए यह { $product } पर इंस्टॉल नहीं हो सकता। Windows 11, संस्करण { $current } को { $date } तक सुरक्षा अपडेट मिलेंगे, और Windows Update इस PC को नए संस्करण पर ले जा सकता है।
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version }, Windows 11 Pro, Enterprise और Education के साथ काम करता है, इसलिए यह { $product } पर इंस्टॉल नहीं हो सकता। संस्करण { $current } को अब सुरक्षा अपडेट नहीं मिलते, इसलिए Atlas के बिना भी Windows अपडेट करें।
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year that reads like a version.
install-windows-edition-ltsc = Atlas { $version }, Windows 11 Pro, Enterprise और Education के साथ काम करता है। LTSC संस्करण समर्थित नहीं हैं।
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } के लिए Windows 11, संस्करण { $releases } ज़रूरी है, और Windows Update इस PC को वहाँ नहीं ले जा सकता। अपनी फ़ाइलों का बैकअप लें, फिर Atlas ISO से Windows दोबारा इंस्टॉल करें।
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } के लिए Windows 11, संस्करण { $releases } ज़रूरी है, और Windows Update इस PC को वहाँ नहीं ले जा सकता।

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Atlas के अपडेट के लिए Windows Update सेटिंग्स बदली गई हैं
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = अपडेट पूरा होने पर Atlas ये सेटिंग्स पहले जैसी कर देगा।
# When the last check found no offer yet.
home-update-access-waiting = Atlas ने इस PC को Windows 11, संस्करण { $release } पर ले जाने के लिए Windows Update चालू किया था, और Windows Update ने अभी तक इसे उपलब्ध नहीं कराया है।
home-update-access-updating = Atlas ने अपडेट इंस्टॉल करने के लिए Windows Update चालू किया था, और यह काम अभी पूरा नहीं हुआ है।
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Atlas का Windows Update रिकॉर्ड नहीं पढ़ा जा सका
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas, Windows Update की उन सेटिंग्स का अपना रिकॉर्ड नहीं पढ़ सकता, जिन्हें उसने बदला था, इसलिए वह न कुछ बदलेगा और न कुछ पहले जैसा करेगा।
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas सेटिंग्स पहले जैसी नहीं कर सका।
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps: पड़ाव.
update-access-finish-install = पहले Atlas का इंस्टॉलेशन पूरा करें। उसके आख़िरी पड़ाव में Windows Update की वे सेटिंग्स पहले जैसी कर दी जाती हैं, जिन्हें Atlas ने बदला था।
home-continue-update = अपडेट करना जारी रखें
home-put-back = सेटिंग्स पहले जैसी करें
home-putting-back = सेटिंग्स पहले जैसी की जा रही हैं…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11, संस्करण { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version }, संस्करण { $current } का समर्थन नहीं करता, इसलिए Atlas पहले Windows अपडेट करेगा।
# Under the title where moving is optional.
windows-optional = Atlas दोनों संस्करणों के साथ काम करता है।
# The choice's accessible name; the two answers say it.
windows-card-question = यह PC Windows का कौन-सा संस्करण इस्तेमाल करे?
windows-choice-move-recommended = Windows 11, संस्करण { $release } पर अपडेट करें (सुझाया गया)
# $date is when the new version stops getting security updates.
windows-choice-move-support = { $date } तक सुरक्षा अपडेट मिलेंगे।
windows-choice-keep = Windows 11, संस्करण { $current } रखें
windows-choice-keep-later = संस्करण { $current } पर बना रहता है। आप बाद में Atlas Manager से नए संस्करण पर जा सकते हैं।
windows-card-facts = क्या बदलेगा
windows-fact-files = आपकी फ़ाइलें और ऐप बने रहते हैं। अपडेट से Atlas का जो भी बदलाव हटता है, Atlas उसे फिर से लागू कर देता है।
windows-fact-time = आम तौर पर कुछ मिनट, अधिकतम 2 घंटे, फिर एक रीस्टार्ट।
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Windows PowerShell 2.0 और WMIC हटा देता है।
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = अपडेट पूर्ववत कैसे करें
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = अपडेट करने का मतलब है कि आप Microsoft सॉफ़्टवेयर लाइसेंस शर्तें स्वीकार करते हैं।
windows-terms-link = लाइसेंस शर्तें पढ़ें
windows-accept = स्वीकार करें और अपडेट करें
# Once the terms are accepted, before the move starts by itself.
windows-starting = शुरू हो रहा है…
windows-starts-after-checks = जाँचें सफल होने पर शुरू होगा।
windows-starts-after-package = Atlas { $version } तैयार होने पर शुरू होगा।
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = संस्करण { $release } ने Atlas के कुछ बदलाव रीसेट कर दिए। Atlas { $version } आपके पिछले विकल्पों के साथ उन्हें फिर से लागू करता है।
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Windows 11, संस्करण { $current } रखें?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas कुछ समय के लिए Windows Update चालू करता है
access-off = इस PC पर Windows Update बंद है। Windows अपडेट करते समय Atlas इसे फिर से चालू करता है।
access-paused = इस PC पर Windows अपडेट रोके गए हैं। Windows अपडेट करते समय Atlas यह रोक हटा देता है।
access-delayed = इस PC पर मासिक अपडेट टाले गए हैं। Windows अपडेट करते समय Atlas यह देरी हटा देता है।
# After the lines above.
access-back = Atlas { $version } इंस्टॉल होने पर ये सेटिंग्स पहले जैसी हो जाती हैं।
access-back-stop = अगर आप उससे पहले रोकते हैं, तो Atlas इन्हें पहले जैसी कर देता है।

prepare-reason-feature-update = नया Windows संस्करण
prepare-reason-feature-commit = नए Windows संस्करण को पूरा करना
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Windows Update के Windows 11, संस्करण { $release } उपलब्ध कराने की प्रतीक्षा है…
windows-waiting-detail = आम तौर पर कुछ मिनट, अधिकतम 2 घंटे। Atlas अपने-आप आगे बढ़ेगा; आप अपना PC इस्तेमाल करते रह सकते हैं।
# मिनट doesn't change with the number.
windows-waited = { $minutes } मिनट से प्रतीक्षा जारी है।
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update ने 2 घंटे के अंदर संस्करण { $release } उपलब्ध नहीं कराया
windows-wait-ended = Atlas ने आपकी सेटिंग्स पहले जैसी कर दीं। बाद में फिर कोशिश करें, या Atlas ISO से Windows दोबारा इंस्टॉल करें।
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas आपकी Windows Update सेटिंग्स पहले जैसी नहीं कर सका।
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows रीस्टार्ट की तैयारी नहीं कर सका
windows-commit-failed = आपका PC रीस्टार्ट नहीं हुआ। फिर कोशिश करें।

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update ने अभी तक संस्करण { $release } उपलब्ध नहीं कराया है
windows-outcome-not-offered = इसमें 2 घंटे तक लग सकते हैं। आपके PC पर अभी भी संस्करण { $current } है।
windows-outcome-hardware-title = यह PC, Windows 11 की आवश्यकताएँ पूरी नहीं करता
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = इसमें { $missing } नहीं है, इसलिए Windows Update संस्करण { $release } उपलब्ध नहीं कराएगा। अपनी फ़ाइलों का बैकअप लें, फिर Atlas ISO से Windows दोबारा इंस्टॉल करें।
hardware-tpm = TPM 2.0
hardware-uefi = UEFI फ़र्मवेयर
windows-outcome-hidden-title = Windows Update में संस्करण { $release } छिपा हुआ है
windows-outcome-hidden = जिस टूल से आपने इसे छिपाया था, उसी से इसे फिर से दिखाएँ, फिर कोशिश करें।
windows-outcome-disk-space-title = पर्याप्त ख़ाली जगह नहीं है
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows को { $drive } पर { $needed } GB ख़ाली जगह चाहिए, और उस पर { $free } GB ख़ाली है। पर्याप्त जगह होते ही Atlas अपने-आप आगे बढ़ेगा।
windows-outcome-managed-title = इस PC को इसके संगठन से अपडेट मिलते हैं
windows-outcome-managed = इसका अपडेट सर्वर संस्करण { $release } उपलब्ध नहीं कराता, इसलिए Atlas ने कुछ नहीं बदला। अपने संगठन से पूछें, या Atlas ISO से Windows दोबारा इंस्टॉल करें।
windows-outcome-policy-title = कोई चीज़ Windows Update को बार-बार वापस बदल रही है
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = Atlas के बदलने के बाद { $setting } फिर से पहले जैसा हो जाता है, इसलिए Atlas, Windows को अपडेट नहीं कर सकता। अगर यह PC कोई संगठन प्रबंधित करता है, तो उससे पूछें।
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = सेवा बंद है: { $service }
windows-outcome-blocked-service = Windows Update को इसकी ज़रूरत है। “सेवाएँ” में इसे “मैन्युअल” पर सेट करें, फिर कोशिश करें।
windows-outcome-blocked-title = कोई चीज़ Windows Update को बंद रख रही है
windows-outcome-blocked = { $setting } नाम की एक सेटिंग, जिसे Atlas ने नहीं बदला, इसे चलने नहीं देती। उसे बदलें, फिर कोशिश करें।
windows-outcome-rollback-title = Windows, संस्करण { $release } का इंस्टॉलेशन पूरा नहीं कर सका
windows-outcome-rolled-back = यह संस्करण { $current } पर वापस चला गया। आपकी फ़ाइलें और ऐप ठीक हैं।
windows-outcome-components-lost-title = Atlas के कुछ बदलाव हट गए हैं
windows-outcome-components-lost = Atlas यह पता नहीं लगा सकता कि ऐसा क्यों हुआ, इसलिए वह Atlas { $version } इंस्टॉल करने से पहले रुक गया।
windows-outcome-build-title = अपडेट के दौरान Windows का संस्करण बदल गया
windows-outcome-build = Atlas की बदली हुई सेटिंग्स पहले जैसी करें, फिर होम से दोबारा शुरू करें।
windows-outcome-journal-title = Atlas इस अपडेट का अपना रिकॉर्ड नहीं पढ़ सकता
windows-outcome-journal = जब तक Atlas टीम इसकी जाँच नहीं कर लेती, Atlas न कुछ बदलेगा और न कुछ पहले जैसा करेगा।
windows-outcome-pin-title = Windows Update की एक नीति रिकॉर्ड नहीं की जा सकती
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } में ऐसा मान है, जिसे Atlas बाद में पहले जैसा नहीं कर सकता, इसलिए Atlas ने कुछ नहीं बदला।
windows-outcome-terms-title = लाइसेंस शर्तें स्वीकार नहीं की गईं
windows-outcome-terms = संस्करण { $release } इंस्टॉल करने से पहले Windows Update को इनकी स्वीकृति चाहिए।
windows-outcome-failed-title = Windows, संस्करण { $release } इंस्टॉल नहीं कर सका
windows-outcome-failed = आपके PC पर अभी भी संस्करण { $current } है।
# Windows services a move needs, as Services lists them. Hindi Windows may list them in
# English, so the English name follows in brackets until confirmed.
service-bits = बैकग्राउंड इंटेलिजेंट ट्रांसफ़र सेवा (BITS)
service-cryptsvc = क्रिप्टोग्राफ़िक सेवाएँ (Cryptographic Services)
service-trusted-installer = Windows मॉड्यूल इंस्टॉलर (Windows Modules Installer)
prepare-open-services = सेवाएँ खोलें
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = संस्करण { $current } रखें

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Atlas { $version } पर अपडेट करना रोकें?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Windows अपडेट करना रोकें?
stop-update-before = Atlas, Windows Update की वे सेटिंग्स पहले जैसी कर देगा, जो उसने बदली थीं। Windows जो अपडेट पहले ही इंस्टॉल कर चुका है, वे इंस्टॉल रहेंगे, और आपके PC पर Windows 11, संस्करण { $current } बना रहेगा।
stop-update-after = आपके PC पर Windows 11, संस्करण { $release } बना रहेगा। Atlas, Windows Update की वे सेटिंग्स पहले जैसी कर देगा, जो उसने बदली थीं।
stop-update-access = Atlas, Windows Update की वे सेटिंग्स पहले जैसी कर देगा, जो उसने बदली थीं। Windows जो अपडेट पहले ही इंस्टॉल कर चुका है, वे इंस्टॉल रहेंगे।
stop-update-keep = अपडेट करते रहें
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Atlas बंद करें?
window-close-update-access-message = बंद होने से पहले Atlas, Windows Update की वे सेटिंग्स पहले जैसी कर देगा, जो उसने बदली थीं। आप होम से अपडेट फिर से शुरू कर सकते हैं।
window-close-put-back = सेटिंग्स पहले जैसी करके बंद करें
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = सेटिंग्स पहले जैसी किए बिना बंद करें?
window-close-put-back-failed-message = अगर आप अभी Atlas बंद करते हैं, तो Windows Update सेटिंग्स वैसी ही रहेंगी, जैसी Atlas ने बदली थीं। Atlas दोबारा खोलने पर होम पर उन्हें पहले जैसी करने का विकल्प मिलेगा।

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = Atlas के इस संस्करण के लिए Windows 11, संस्करण { $release } ज़रूरी है, और इस PC पर संस्करण { $current } है।

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Atlas के लिए Windows का अपडेट पूरा नहीं हुआ। Atlas टीम के लिए विवरण:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = Windows अपडेट के बाद दोबारा इंस्टॉलेशन
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Atlas { $previous } से आपके विकल्प
rebase-choices-kept = Atlas वही विकल्प फिर से लागू करता है, जो आपने Atlas { $previous } के लिए चुने थे। आप Atlas दोबारा इंस्टॉल करके इन्हें बाद में बदल सकते हैं।
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas { $previous } के लिए चुना गया आपका बाकी हर विकल्प Atlas फिर से लागू करता है।
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = कोई और साइन इन है, फिर भी रीस्टार्ट करें?
restart-others-question = दूसरे लोग साइन इन हैं, फिर भी रीस्टार्ट करें?
# $names lists their account names, such as "Alex और Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
        [1] { $names } भी साइन इन है। रीस्टार्ट करने से उनके ऐप बंद हो जाएँगे और उनका बिना सहेजा काम खो जाएगा।
       *[other] { $names } भी साइन इन हैं। रीस्टार्ट करने से उनके ऐप बंद हो जाएँगे और उनका बिना सहेजा काम खो जाएगा।
    }
restart-others-keep = रीस्टार्ट न करें
restart-others-restart = फिर भी रीस्टार्ट करें
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Microsoft Store अपडेट हो रहा है…
prepare-store-repairing = Microsoft Store ठीक किया जा रहा है…
prepare-store-repair-detail = इसमें कुछ मिनट लग सकते हैं।
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = इस PC पर Microsoft Store बंद है, इसलिए Store ऐप अपडेट नहीं किए गए।
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store काम नहीं कर रहा है
prepare-store-broken = Atlas इसे ठीक नहीं कर सका, और अभी Atlas इंस्टॉल करने से Store ऐप ख़राब हो सकते हैं।
prepare-store-broken-iso = अगर ठीक करने की कोशिश बार-बार विफल हो, तो अपनी फ़ाइलों का बैकअप लें और Atlas ISO से Windows दोबारा इंस्टॉल करें।
prepare-repair-store-again = फिर से ठीक करें
# Windows couldn't install updates for some of its own apps, and Atlas's Store repairs didn't help.
# $apps lists the apps by their package names, joined with list-and.
prepare-store-staging-title = Windows अपने बिल्ट-इन ऐप अपडेट नहीं कर पा रहा है
prepare-store-staging = Windows इन बिल्ट-इन ऐप के अपडेट इंस्टॉल नहीं कर सका, और Atlas के ठीक करने से भी मदद नहीं मिली: { $apps }। { prepare-components-unrepairable }

screen-keyboard-title = कीबोर्ड की भाषाएँ
screen-keyboard-question = क्या आप कीबोर्ड की कई भाषाएँ इस्तेमाल करते हैं?
package-option-keyboard-shortcuts = हाँ, कीबोर्ड शॉर्टकट से
package-option-keyboard-selector = हाँ, टास्कबार के चयनकर्ता से
package-option-keyboard-single = नहीं, मेरे पास एक ही कीबोर्ड लेआउट है
consequence-keyboard-shortcuts = Alt+Shift से भाषा और Ctrl+Shift से लेआउट बदलता है।
consequence-keyboard-selector = गेम खेलते समय ग़लती से बदलाव रोकने के लिए Alt+Shift और Ctrl+Shift बंद करें।
package-choice-keyboard-description = चुनें कि कीबोर्ड की भाषा कैसे बदलनी है।
consequence-keyboard-single = { consequence-keyboard-selector }
