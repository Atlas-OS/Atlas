//! The user's preferences (theme, language, restarting after the install)
//! and the notices Home shows until they are dismissed.

use gpui::Context;

use super::{AppModel, ModelEvent, Page};
use crate::i18n;
use crate::services::security::{Protection, SecurityStatus, Switch};
use crate::services::settings::{LanguagePreference, ThemePreference};
use crate::services::system::AccessibilityPreferences;

/// Why Home or the "Atlas is installed" window reminds the user about
/// Windows Security.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReminderReason {
    /// The user left an install flow after turning switches off.
    LeftFlow,
    /// A recorded install kept Microsoft Defender.
    KeptDefender,
}

/// The switches a Windows Security reminder names, from a live reading.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ProtectionReminder {
    pub reason: ReminderReason,
    /// The switches that read off, in Windows Security's order; or, when
    /// none does, those that couldn't be read.
    pub switches: Vec<Protection>,
    /// The switches couldn't be read, so none is known to be off.
    pub unreadable: bool,
    /// Microsoft Defender isn't on the PC at all, though the install kept it:
    /// the reminder is that there is no antivirus, not about switches.
    pub missing: bool,
}

impl ProtectionReminder {
    /// What a reading says to remind about: the switches that read off, or
    /// failing those, the ones that couldn't be read. Nothing once every
    /// switch reads on. Where Defender is gone, an install that kept it says
    /// so; leaving a flow, there is nothing to turn back on.
    pub fn from_reading(reason: ReminderReason, status: &SecurityStatus) -> Option<Self> {
        if !status.defender_present {
            return (reason == ReminderReason::KeptDefender).then(|| Self {
                reason,
                switches: Vec::new(),
                unreadable: false,
                missing: true,
            });
        }
        let off = status.switches(Switch::Off);
        let (switches, unreadable) =
            if off.is_empty() { (status.switches(Switch::Unknown), true) } else { (off, false) };
        (!switches.is_empty()).then_some(Self { reason, switches, unreadable, missing: false })
    }
}

/// The included English variant that best matches a Windows display-language
/// list; British English, the source, when none matches.
pub fn english_for(windows_languages: &[String]) -> String {
    let english: Vec<&'static i18n::Locale> = i18n::catalog::LOCALES
        .iter()
        .filter(|locale| locale.listed() && locale.id().language.as_str() == "en")
        .collect();
    let requested = i18n::negotiate::parse_tags(windows_languages.iter().map(String::as_str));
    i18n::negotiate::negotiate(&requested, &english)
        .first()
        .filter(|_| requested.iter().any(|tag| tag.language.as_str() == "en"))
        .map(|locale| locale.tag.to_owned())
        .unwrap_or_else(|| i18n::catalog::SOURCE_TAG.to_owned())
}

impl AppModel {
    pub fn dismiss_notice(&mut self, cx: &mut Context<Self>) {
        self.notice = None;
        cx.notify();
    }

    /// Dismisses the Windows Security reminder that shows: for this window
    /// after leaving a flow, or for good for the recorded install. Switches
    /// left off and a missing Defender are dismissed apart, so one doesn't
    /// hide the other later. The "Atlas is installed" window shows a
    /// reminder dismissed before it opened, and hides it once dismissed there.
    pub fn dismiss_security_reminder(&mut self, cx: &mut Context<Self>) {
        if self.security_reminder {
            self.security_reminder = false;
            self.forget_pending_reminder(cx);
        } else if let Some(reminder) = self.protection_reminder()
            && let Some(installed_at) = self.kept_defender()
        {
            if self.page == Page::Installed {
                self.reminder_dismissed_here = true;
            }
            if reminder.missing {
                self.settings.defender_missing_dismissed = Some(installed_at.clone());
                self.persist_preference(move |doc| doc.defender_missing_dismissed = Some(installed_at), cx);
            } else {
                self.settings.protection_reminder_dismissed = Some(installed_at.clone());
                self.persist_preference(
                    move |doc| doc.protection_reminder_dismissed = Some(installed_at),
                    cx,
                );
            }
        }
        cx.notify();
    }

    /// The `installedAt` of a recorded install that kept Microsoft Defender,
    /// whatever was dismissed.
    pub(super) fn kept_defender(&self) -> Option<String> {
        let installed = self.installed()?;
        let installed_at = installed.installed_at.clone()?;
        installed.options.iter().any(|option| option == "defender-enable").then_some(installed_at)
    }

    /// Whether the recorded install kept Microsoft Defender.
    pub fn kept_defender_recorded(&self) -> bool {
        self.kept_defender().is_some()
    }

    /// Whether a dismissal of the reminder of `kind` (missing Defender, or
    /// switches) holds on this page: on the "Atlas is installed" window, only
    /// one made there.
    fn reminder_dismissed(&self, missing: bool) -> bool {
        if self.page == Page::Installed {
            return self.reminder_dismissed_here;
        }
        let dismissed = if missing {
            &self.settings.defender_missing_dismissed
        } else {
            &self.settings.protection_reminder_dismissed
        };
        dismissed.is_some() && *dismissed == self.kept_defender()
    }

    /// The Windows Security reminder to show, if any: after leaving a flow
    /// with switches off, or after an install that kept Microsoft Defender
    /// until it is dismissed. Each names what the latest reading says, so a
    /// switch turned back on (by the user or by Windows) leaves the list.
    /// While the install's restart is still owed, there's none for it: the
    /// restart comes first, and Defender may only be back after it.
    pub fn protection_reminder(&self) -> Option<ProtectionReminder> {
        if self.security_reminder {
            // The flow's last reading stands until a new one arrives; one
            // restored from an earlier run waits for a live reading.
            let reading = match &self.protection {
                Some(reading) => reading,
                None if self.awaiting_reminder_reading => return None,
                None => &self.security,
            };
            return ProtectionReminder::from_reading(ReminderReason::LeftFlow, reading);
        }
        self.kept_defender()?;
        if self.owed_restart.is_some() {
            return None;
        }
        ProtectionReminder::from_reading(ReminderReason::KeptDefender, self.protection.as_ref()?)
            .filter(|reminder| !self.reminder_dismissed(reminder.missing))
    }

    /// Whether an install that kept Microsoft Defender waits on its first
    /// Windows Security reading, so nothing yet says the PC is all set.
    pub fn protection_reading_pending(&self) -> bool {
        self.protection.is_none()
            && !self.security_reminder
            && self.kept_defender().is_some()
            && self.owed_restart.is_none()
    }

    /// Whether the latest reading confirms that an install that kept
    /// Microsoft Defender has it, with every switch on. Unknown counts as not
    /// on, and dismissing a reminder changes nothing here: it hides the bar,
    /// not what Windows Security reports.
    pub fn protection_confirmed_on(&self) -> bool {
        self.protection.as_ref().is_some_and(|status| {
            status.defender_present && Protection::ALL.iter().all(|switch| status.get(*switch) == Switch::On)
        })
    }

    /// Reads Windows Security again for Home's and the "Atlas is installed"
    /// window's reminders, on a worker, when one could show. Called as those
    /// pages open and when the window is activated, which is when someone
    /// returns from Windows Security. An install that kept Defender is read
    /// whatever was dismissed, so a missing Defender and "you're all set"
    /// follow the PC, not the last answer.
    pub fn refresh_protection(&mut self, cx: &mut Context<Self>) {
        let shown = matches!(self.page, Page::Home | Page::Installed) && !self.install_in_progress();
        if !shown || !(self.security_reminder || self.kept_defender().is_some()) {
            return;
        }
        let generation = self.protection_generation.next();
        let read = self.env.adapters.read_security.clone();
        cx.spawn(async move |this, cx| {
            let status = cx.background_executor().spawn(async move { read() }).await;
            this.update(cx, |this, cx| {
                if this.protection_generation != generation {
                    return;
                }
                this.awaiting_reminder_reading = false;
                // Nothing left off: the reminder a flow left need not survive a relaunch.
                if this.security_reminder && !status.any_off() {
                    this.forget_pending_reminder(cx);
                }
                if this.protection != Some(status) {
                    this.protection = Some(status);
                    cx.notify();
                }
            })
            .ok();
        })
        .detach();
    }

    /// Brings what Home and the "Atlas is installed" window show up to date
    /// as either opens: whether a restart is owed, and Windows Security.
    pub(super) fn refresh_page_notices(&mut self, cx: &mut Context<Self>) {
        if matches!(self.page, Page::Home | Page::Installed) {
            self.refresh_owed_restart();
            self.refresh_protection(cx);
        }
    }

    /// Remembers, in settings, that a flow was left with protection off, so
    /// the reminder survives a relaunch (see [`AppModel::restore_pending_reminder`]).
    pub(super) fn remember_pending_reminder(&mut self, cx: &mut Context<Self>) {
        if !self.settings.protection_reminder_pending {
            self.settings.protection_reminder_pending = true;
            self.persist_preference(|doc| doc.protection_reminder_pending = true, cx);
        }
    }

    /// Forgets that reminder: dismissed, an install started or finished, or
    /// a reading has no switch off.
    pub(super) fn forget_pending_reminder(&mut self, cx: &mut Context<Self>) {
        if self.settings.protection_reminder_pending {
            self.settings.protection_reminder_pending = false;
            self.persist_preference(|doc| doc.protection_reminder_pending = false, cx);
        }
    }

    /// At startup, with no flow resumed, brings back the reminder a flow
    /// left on the last run. It waits for a live reading before it shows,
    /// so an unread default never names four switches it can't read.
    pub(super) fn restore_pending_reminder(&mut self, cx: &mut Context<Self>) {
        if self.settings.protection_reminder_pending && !self.flow.active && !self.security_reminder {
            self.security_reminder = true;
            self.protection = None;
            self.awaiting_reminder_reading = true;
            self.refresh_protection(cx);
        }
    }

    pub fn set_theme(&mut self, theme: ThemePreference, cx: &mut Context<Self>) {
        if self.settings.theme == theme {
            // Choosing it again after a failed save saves it, as the notice asks.
            if self.save_failed() {
                self.resave_settings(cx);
            }
            return;
        }
        self.settings.theme = theme;
        self.persist_preference(move |doc| doc.theme = theme, cx);
        cx.emit(ModelEvent::ThemeChanged);
        cx.notify();
    }

    /// The preview translation currently in use, unless the user has
    /// dismissed the notice for it. The shell shows a bar naming it and
    /// offering English, the language Atlas is verified in.
    pub fn preview_notice(&self) -> Option<&'static i18n::Locale> {
        let locale = self.localization.primary();
        let dismissed =
            self.settings.dismissed_preview_notices.iter().any(|tag| tag.eq_ignore_ascii_case(locale.tag));
        (locale.readiness < i18n::Readiness::Source && !dismissed).then_some(locale)
    }

    /// Hides the preview notice for the current language, for good.
    pub fn dismiss_preview_notice(&mut self, cx: &mut Context<Self>) {
        let Some(locale) = self.preview_notice() else { return };
        let tag = locale.tag.to_owned();
        self.settings.dismissed_preview_notices.push(tag.clone());
        self.persist_preference(
            move |doc| {
                if !doc.dismissed_preview_notices.iter().any(|t| t.eq_ignore_ascii_case(&tag)) {
                    doc.dismissed_preview_notices.push(tag);
                }
            },
            cx,
        );
        cx.notify();
    }

    /// Switches to English from the preview notice: the English variant
    /// closest to the Windows display languages, so a US-English Windows
    /// gets US spelling. The choice is saved like one made in Settings.
    pub fn switch_to_english(&mut self, cx: &mut Context<Self>) {
        let tag = english_for(&self.localization.windows_languages);
        self.set_language(LanguagePreference::Explicit(tag), cx);
    }

    /// Changes the app language. Nothing but the words changes: the page,
    /// step, choices, focus and any running install stay as they are, and
    /// the next render draws every notice and status in the new language.
    pub fn set_language(&mut self, language: LanguagePreference, cx: &mut Context<Self>) {
        if self.settings.language == language {
            // Choosing it again after a failed save saves it, as the notice asks.
            if self.save_failed() {
                self.resave_settings(cx);
            }
            // Choosing "Match Windows" again is a request to look at Windows
            // again, for example after a query that failed at startup.
            if language == LanguagePreference::System {
                self.apply_language(cx);
            }
            return;
        }
        self.settings.language = language.clone();
        self.persist_preference(move |doc| doc.language = language, cx);
        self.apply_language(cx);
    }

    fn apply_language(&mut self, cx: &mut Context<Self>) {
        self.apply_language_with(i18n::current_windows_languages(), cx);
    }

    /// Applies the language setting against an already-read Windows list, so
    /// a refresh negotiates against the list it just compared and never
    /// downgrades a working choice because a second query failed.
    fn apply_language_with(&mut self, windows: Result<Vec<String>, String>, cx: &mut Context<Self>) {
        self.localization = i18n::activate_with(&self.settings.language, None, windows);
        cx.emit(ModelEvent::LanguageChanged);
        cx.notify();
    }

    /// While "Match Windows" is on, follows a change to the Windows display
    /// language made while the app was in the background. Windows may need a
    /// sign-out for some changes, so this only reflects what it reports.
    pub fn refresh_language(&mut self, cx: &mut Context<Self>) {
        // The regional format is read live by the formatters; a change only
        // needs a redraw.
        let format_locale = i18n::fmt::format_locale_tag();
        if format_locale != self.localization.format_locale {
            self.localization.format_locale = format_locale;
            cx.notify();
        }
        if self.settings.language != LanguagePreference::System || !self.localization.follows_windows() {
            return;
        }
        match i18n::current_windows_languages() {
            Ok(languages) => {
                let was_unavailable =
                    matches!(self.localization.decision, i18n::Decision::WindowsUnavailable(_));
                if languages == self.localization.windows_languages && !was_unavailable {
                    return;
                }
                self.apply_language_with(Ok(languages), cx);
            }
            // A transient failure keeps the last working choice; the next
            // activation tries again.
            Err(error) => log::warn!("could not re-read the Windows display languages: {error:#}"),
        }
    }

    pub fn set_restart_after_install(&mut self, restart: bool, cx: &mut Context<Self>) {
        if self.locked() || !self.flow.may_edit() {
            return;
        }
        self.settings.restart_after_install = restart;
        self.persist_preference(move |doc| doc.restart_after_install = restart, cx);
        cx.notify();
    }

    /// Re-reads the Ease of Access preferences; the theme follows them.
    pub fn refresh_accessibility(&mut self, cx: &mut Context<Self>) {
        let preferences = AccessibilityPreferences::read();
        if preferences != self.accessibility {
            self.accessibility = preferences;
            cx.emit(ModelEvent::ThemeChanged);
            cx.notify();
        }
    }
}
