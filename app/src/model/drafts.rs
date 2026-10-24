//! The install flow's draft in settings.json, written only while this flow
//! owns it, and the settings writer every change goes through.

use gpui::Context;

use super::{AppModel, Notice, Step};
use crate::services::session::SessionRecord;
use crate::services::settings::{AppSettings, InstallDraft};

/// Outcome of writing the draft only if this flow still owns it.
#[derive(Debug)]
pub(super) enum DraftWrite {
    Written,
    TakenOver,
    Failed(String),
}

/// A draft write that failed. Later draft writes, and settings writes while
/// it stands, replay it until one lands, so a lost write doesn't come back
/// on the next launch.
#[derive(Clone, Debug)]
pub(super) enum UnsavedDraft {
    /// Removing flow `flow`'s draft after that flow was left.
    Removal { flow: Option<String> },
    /// Flow `flow`'s draft, written over whatever is on disk.
    TakeOver { flow: Option<String> },
}

impl AppModel {
    /// This flow's draft as it stands, or `None` outside a flow.
    pub(super) fn current_draft(&self) -> Option<InstallDraft> {
        if !self.flow.active {
            return None;
        }
        Some(InstallDraft {
            preparation_restart_at: self.preparation_restart_at.clone(),
            preparation_ready: self.preparation.ready(),
            step: self.flow.step.name().to_owned(),
            options: self.effective_options(),
            playbook_dir: self.playbook.as_ref().map(|p| p.dir.clone()),
            package_archive: self.playbook.as_ref().and_then(|p| p.archive.clone()),
            option_screen: self.option_screen,
            session: self.own_session.clone(),
            flow: self.flow_id.clone(),
            windows_transition_declined: self.windows_transition_declined,
            windows_terms_accepted: self.windows_terms_accepted,
            used_windows_accepted: self.used_windows_accepted,
            recorded_choices_applied: self.recorded_choices_applied,
            store_outcome: self.store_outcome_seen.map(|outcome| outcome.id().to_owned()),
        })
    }

    /// Runs a settings transaction on the store and, once it has been
    /// written, hands its answer to `then` on the window's thread. A
    /// transaction that fails is reported on Home; nothing waits here.
    pub(super) fn persist<R: Send + 'static>(
        &mut self,
        change: impl FnOnce(&mut AppSettings) -> R + Send + 'static,
        then: impl FnOnce(&mut Self, R, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        let answer = self.store.transact(change);
        cx.spawn(async move |this, cx| {
            let answer = answer.await;
            this.update(cx, |this, cx| match answer {
                Ok(answer) => then(this, answer, cx),
                Err(error) => this.settings_failed(error, cx),
            })
            .ok();
        })
        .detach();
    }

    /// [`AppModel::persist`] for a draft write. `change` says whether it
    /// settled the draft on disk as this window means it, which makes up for
    /// any [`UnsavedDraft`]. A failed write leaves `unsaved`, if given, for
    /// later writes to replay.
    fn persist_draft(
        &mut self,
        change: impl FnOnce(&mut AppSettings) -> bool + Send + 'static,
        unsaved: Option<UnsavedDraft>,
        then: impl FnOnce(&mut Self, bool, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        let answer = self.store.transact(change);
        cx.spawn(async move |this, cx| {
            let answer = answer.await;
            this.update(cx, |this, cx| match answer {
                Ok(landed) => {
                    if landed {
                        this.unsaved_draft = None;
                    }
                    then(this, landed, cx);
                }
                Err(error) => {
                    if unsaved.is_some() {
                        this.unsaved_draft = unsaved;
                    }
                    this.settings_failed(error, cx);
                }
            })
            .ok();
        })
        .detach();
    }

    fn settings_failed(&mut self, error: String, cx: &mut Context<Self>) {
        log::warn!("could not save settings: {error}");
        if self.notice.is_none() {
            self.notice = Some(Notice::SettingsNotSaved { error });
        }
        cx.notify();
    }

    /// Whether a settings write failed and the notice still says so.
    pub(super) fn save_failed(&self) -> bool {
        matches!(self.notice, Some(Notice::SettingsNotSaved { .. }))
    }

    /// Saves a preference the user changed. While a failed save is being
    /// reported, or a draft write is still lost, the change writes everything
    /// this window holds instead (see [`AppModel::resave_settings`]), so what
    /// was lost is saved with it.
    pub(super) fn persist_preference(
        &mut self,
        change: impl FnOnce(&mut AppSettings) + Send + 'static,
        cx: &mut Context<Self>,
    ) {
        if self.save_failed() || self.unsaved_draft.is_some() {
            self.resave_settings(cx);
        } else {
            self.persist(change, |_, (), _| {}, cx);
        }
    }

    /// After a failed save, writes every preference this window holds, plus
    /// its draft while this flow still owns it, or the draft removal or
    /// take-over a failed write left undone (see [`UnsavedDraft`]). A
    /// transaction replays only the field it changes, so only this recovers
    /// a lost preference; the notice goes once it succeeds.
    pub(super) fn resave_settings(&mut self, cx: &mut Context<Self>) {
        // Every field by name, so a new preference fails to build here
        // until someone decides how it is replayed.
        let AppSettings {
            drivers,
            theme,
            language,
            restart_after_install,
            draft: _,
            dismissed_preview_notices,
            protection_reminder_dismissed,
            defender_missing_dismissed,
            protection_reminder_pending,
        } = self.settings.clone();
        let draft = self.current_draft();
        let unsaved = self.unsaved_draft.clone();
        self.persist_draft(
            move |doc| {
                doc.theme = theme;
                doc.language = language;
                doc.restart_after_install = restart_after_install;
                if drivers.is_some() {
                    doc.drivers = drivers;
                }
                for tag in dismissed_preview_notices {
                    if !doc.dismissed_preview_notices.iter().any(|t| t.eq_ignore_ascii_case(&tag)) {
                        doc.dismissed_preview_notices.push(tag);
                    }
                }
                if protection_reminder_dismissed.is_some() {
                    doc.protection_reminder_dismissed = protection_reminder_dismissed;
                }
                if defender_missing_dismissed.is_some() {
                    doc.defender_missing_dismissed = defender_missing_dismissed;
                }
                doc.protection_reminder_pending = protection_reminder_pending;
                write_draft(doc, draft, unsaved)
            },
            None,
            |this, _, cx| {
                if this.save_failed() {
                    this.notice = None;
                    cx.notify();
                }
            },
            cx,
        );
    }

    /// Saves this flow's draft while the draft on disk is still this flow's
    /// (or nobody's). Once another window has begun a newer one, this
    /// window's progress is no longer saved.
    pub(super) fn save_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.current_draft() else { return };
        self.settings.draft = Some(draft.clone());
        let unsaved = self.unsaved_draft.clone();
        self.persist_draft(
            move |doc| write_draft(doc, Some(draft), unsaved),
            None,
            |_, written, _| {
                if !written {
                    log::warn!(
                        "another window has taken over the install flow; this flow is no longer saved"
                    );
                }
            },
            cx,
        );
    }

    /// Writes `draft` as [`AppModel::save_draft`] does, for a caller that
    /// must know the outcome before it goes on. The write is queued at once.
    pub(super) fn write_owned_draft(&self, draft: InstallDraft) -> impl Future<Output = DraftWrite> + use<> {
        // A take-over that was lost still applies; the next save settles it.
        let unsaved = self.unsaved_draft.clone();
        let written = self.store.transact(move |doc| write_draft(doc, Some(draft), unsaved));
        async move {
            match written.await {
                Ok(true) => DraftWrite::Written,
                Ok(false) => DraftWrite::TakenOver,
                Err(error) => DraftWrite::Failed(error),
            }
        }
    }

    /// Writes this flow's draft whatever is on disk: a flow the user has just
    /// begun replaces any earlier one.
    pub(super) fn take_over_draft(&mut self, cx: &mut Context<Self>) {
        let Some(draft) = self.current_draft() else { return };
        self.settings.draft = Some(draft.clone());
        let unsaved = UnsavedDraft::TakeOver { flow: draft.flow.clone() };
        self.persist_draft(
            move |doc| {
                doc.draft = Some(draft);
                true
            },
            Some(unsaved),
            |_, _, _| {},
            cx,
        );
    }

    /// Abandons this flow's draft: the one on disk goes only while this flow
    /// owns it.
    pub(super) fn clear_draft(&mut self, cx: &mut Context<Self>) {
        self.preparation_restart_at = None;
        self.preparation_problem = None;
        self.settings.draft = None;
        let flow = self.flow_id.clone();
        let unsaved = UnsavedDraft::Removal { flow: flow.clone() };
        self.persist_draft(
            move |doc| {
                remove_if_owned(doc, flow.as_deref());
                true
            },
            Some(unsaved),
            |_, _, _| {},
            cx,
        );
    }

    /// Clears the draft that launched install `record`, wherever it is now
    /// on disk, and no other; `then` receives whatever draft remains.
    pub(super) fn clear_draft_of(
        &mut self,
        record: &SessionRecord,
        then: impl FnOnce(&mut Self, Option<InstallDraft>, &mut Context<Self>) + 'static,
        cx: &mut Context<Self>,
    ) {
        if self.settings.draft.as_ref().is_some_and(|draft| draft_launched(draft, record)) {
            self.settings.draft = None;
        }
        let record = record.clone();
        self.persist(
            move |doc| {
                if doc.draft.as_ref().is_some_and(|draft| draft_launched(draft, &record)) {
                    doc.draft = None;
                }
                doc.draft.clone()
            },
            then,
            cx,
        );
    }
}

/// Writes `draft` into `doc` if its flow may (see [`draft_owned_by`]), and
/// says whether it did.
fn write_if_owned(doc: &mut AppSettings, draft: InstallDraft) -> bool {
    let owned = draft_owned_by(&doc.draft, draft.flow.as_deref());
    if owned {
        doc.draft = Some(draft);
    }
    owned
}

/// Removes the draft in `doc` if flow `flow` may (see [`draft_owned_by`]).
fn remove_if_owned(doc: &mut AppSettings, flow: Option<&str>) {
    if draft_owned_by(&doc.draft, flow) {
        doc.draft = None;
    }
}

/// Writes this window's `draft` into `doc`: over anything while its flow's
/// take-over hasn't landed, otherwise only while its flow owns the one on
/// disk. With no draft, it makes the removal a failed write left undone.
/// Says whether this settles the draft on disk as this window means it. A
/// write with neither to make settles nothing: a failure reported after it
/// was queued is still owed.
fn write_draft(doc: &mut AppSettings, draft: Option<InstallDraft>, unsaved: Option<UnsavedDraft>) -> bool {
    match (draft, unsaved) {
        (Some(draft), Some(UnsavedDraft::TakeOver { flow })) if draft.flow == flow => {
            doc.draft = Some(draft);
            true
        }
        (Some(draft), _) => write_if_owned(doc, draft),
        (None, Some(UnsavedDraft::Removal { flow })) => {
            remove_if_owned(doc, flow.as_deref());
            true
        }
        // A take-over for a flow that has ended is owed nothing.
        (None, Some(UnsavedDraft::TakeOver { .. })) => true,
        (None, None) => false,
    }
}

/// Whether flow `flow` may write or remove the draft on disk: there is none,
/// it is this flow's, or it has no owner.
pub fn draft_owned_by(on_disk: &Option<InstallDraft>, flow: Option<&str>) -> bool {
    match on_disk {
        None => true,
        Some(draft) => draft.flow.is_none() || draft.flow.as_deref() == flow,
    }
}

/// Whether `draft` launched `record`: it names the record's session. A draft
/// that names no session counts only if it has no owner and stood at the
/// Install step for the record's package, with every option the record ran
/// among its choices.
pub fn draft_launched(draft: &InstallDraft, record: &SessionRecord) -> bool {
    if draft.session.is_some() {
        return draft.session.as_deref() == Some(record.id.as_str());
    }
    draft.flow.is_none()
        && draft.step == Step::Install.name()
        && draft.playbook_dir.as_deref() == Some(record.request.playbook_dir.as_path())
        && record.request.options.iter().all(|option| draft.options.contains(option))
}
