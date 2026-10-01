//! Writes an ISO to a USB drive: choose, review, write, eject. Shown as a panel
//! over the ISO page.

use std::path::PathBuf;
use std::rc::Rc;
use std::sync::atomic::Ordering;

use futures::StreamExt;
use gpui::{
    AnyElement, Context, Entity, IntoElement, ParentElement, PathPromptOptions, Render, Role, ScrollHandle,
    Task, Window, div, prelude::*, px,
};

use super::iso::{captioned, file_value};
use super::{
    CommandBar, Diagnostics, PageTitle, PanelBack, card_body, card_header_with_icon, detail_row, detail_text,
    focusable_heading, page_frame,
};
use crate::i18n::fmt;
use crate::model::AppModel;
use crate::services::usb::{self, Drive, FailureReason, Progress};
use crate::services::{iso, settings};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CheckBox, FocusHandles, Icon, InfoBar, ProgressBar, RadioGroup, RadioItem, ScrollbarState,
    Severity, Typography, card,
};

/// What the error bar reports.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum UsbError {
    /// The drive list could not be read.
    Scan,
    /// A finished USB could not be ejected; it is still ready.
    Eject,
    /// The user stopped a write; `changed` when the drive may be partly written.
    Cancelled { changed: bool },
    /// A write failed; `changed` when the drive may be partly written.
    Write { reason: Option<FailureReason>, changed: bool },
}

impl UsbError {
    /// The error for a failed `operation`, from what the worker reported.
    fn of(operation: &str, cancelled: bool, failure: Option<&usb::Failure>) -> Self {
        // Without the worker's account of it, the drive may have been changed.
        let changed = failure.is_none_or(|failure| failure.drive_changed);
        match operation {
            "List" => Self::Scan,
            "Eject" => Self::Eject,
            _ if cancelled => Self::Cancelled { changed },
            _ => Self::Write { reason: failure.and_then(|failure| failure.reason), changed },
        }
    }

    /// Severity, title and message of the bar. Cancelling is the user's own
    /// choice, and a failed eject leaves a finished USB, so neither is an error.
    /// Without `diagnostics` to open, the worker never started, and the
    /// messages that point at them say so instead.
    fn bar(self, diagnostics: bool) -> (Severity, String, String) {
        match self {
            Self::Scan if !diagnostics => {
                (Severity::Error, t!("usb-scan-failed-title"), t!("iso-failed-unstaged"))
            }
            Self::Scan => (Severity::Error, t!("usb-scan-failed-title"), t!("usb-scan-failed")),
            Self::Eject => (Severity::Warning, t!("usb-eject-failed-title"), t!("usb-eject-failed")),
            Self::Cancelled { changed } => (
                Severity::Informational,
                t!("usb-cancelled-title"),
                if changed { t!("usb-cancelled") } else { t!("usb-cancelled-unchanged") },
            ),
            Self::Write { reason, changed } => (
                Severity::Error,
                t!("usb-failed-title"),
                match reason {
                    // The worker reports its typed reasons before erasing anything.
                    _ if changed => t!("usb-failed"),
                    Some(FailureReason::IsoUnsupported) => t!("usb-failed-iso"),
                    Some(FailureReason::SourceLocation) => t!("usb-failed-location"),
                    Some(FailureReason::WorkingSpace) => t!("usb-failed-space"),
                    Some(FailureReason::DoesNotFit) => t!("usb-failed-fit"),
                    Some(FailureReason::DriveChanged) => t!("usb-failed-drive-changed"),
                    None if !diagnostics => t!("iso-failed-unstaged"),
                    None => t!("usb-failed-unchanged"),
                },
            ),
        }
    }

    /// Whether the job's log folder and the diagnostics belong with the bar:
    /// they do for a failure or a cancelled write, and not for a USB that is
    /// ready but still in use.
    fn offers_help(self) -> bool {
        !matches!(self, Self::Eject)
    }
}

pub struct UsbPage {
    pub closed: bool,
    model: Entity<AppModel>,
    source: Option<PathBuf>,
    /// The Windows builds the Atlas package supports; the worker refuses others.
    supported_builds: Vec<u32>,
    drives: Vec<Drive>,
    selected: Option<usize>,
    review: bool,
    acknowledged: bool,
    scanning: bool,
    working: bool,
    complete: bool,
    ejected: bool,
    error: Option<UsbError>,
    progress: Progress,
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    preview: bool,
    diagnostics: Diagnostics,
    /// The state last announced by moving focus: review, scanning, working,
    /// complete, ejected and the error. Selection, the acknowledgement and
    /// progress are left out so they never move focus.
    shown: Option<(bool, bool, bool, bool, bool, Option<UsbError>)>,
}

impl UsbPage {
    pub fn new(
        model: Entity<AppModel>,
        source: Option<PathBuf>,
        supported_builds: Vec<u32>,
        preview: Option<&str>,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        let mut page = Self {
            closed: false,
            model,
            source,
            supported_builds,
            drives: vec![],
            selected: None,
            review: false,
            acknowledged: false,
            scanning: false,
            working: false,
            complete: false,
            ejected: false,
            error: None,
            progress: Progress::default(),
            job: None,
            task: None,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            preview: preview.is_some(),
            diagnostics: Diagnostics::new(cx),
            shown: None,
        };
        if let Some(state) = preview {
            page.load_preview(state);
        } else {
            let entity = cx.entity();
            cx.defer(move |cx| entity.update(cx, |this, cx| this.start("List", cx)));
        }
        page
    }

    /// Shows the panel in the preview `state` the ISO page was given, with a made-up drive.
    fn load_preview(&mut self, state: &str) {
        self.source = Some(PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso"));
        if state != "usb-empty" {
            self.drives = vec![usb::preview_drive()];
        }
        self.selected = (!self.drives.is_empty()).then_some(0);
        self.review = state == "usb-review";
        self.complete = matches!(state, "usb-complete" | "usb-ejected" | "usb-eject-failed");
        self.ejected = state == "usb-ejected";
        self.working = state == "usb-progress";
        self.progress = Progress { stage: "copy".into(), done: 3, total: 8 };
        self.error = match state {
            "usb-failed" => Some(UsbError::Write { reason: None, changed: true }),
            "usb-failed-iso" => {
                Some(UsbError::Write { reason: Some(FailureReason::IsoUnsupported), changed: false })
            }
            "usb-failed-unchanged" => Some(UsbError::Write { reason: None, changed: false }),
            "usb-cancelled-unchanged" => Some(UsbError::Cancelled { changed: false }),
            "usb-scan-failed" => Some(UsbError::Scan),
            "usb-eject-failed" => Some(UsbError::Eject),
            _ => None,
        };
        // A real failure leaves its job, and the log folder with it.
        if self.error.is_some() {
            self.job = Some(settings::app_data_dir());
        }
    }

    fn choose_iso(&mut self, cx: &mut Context<Self>) {
        if self.preview || self.working || self.scanning {
            return;
        }
        let response = cx.prompt_for_paths(PathPromptOptions {
            files: true,
            directories: false,
            multiple: false,
            prompt: Some(t!("usb-choose-iso").into()),
        });
        cx.spawn(async move |this, cx| {
            if let Ok(Ok(Some(paths))) = response.await
                && let Some(path) = paths.into_iter().next()
            {
                this.update(cx, |this, cx| {
                    this.source = Some(path);
                    this.review = false;
                    this.acknowledged = false;
                    this.error = None;
                    cx.notify();
                })
                .ok();
            }
        })
        .detach();
    }

    fn start(&mut self, operation: &'static str, cx: &mut Context<Self>) {
        if self.preview || self.working || self.scanning || self.model.read(cx).locked() {
            return;
        }
        if operation == "Write" && (!self.review || !self.acknowledged || self.source.is_none()) {
            return;
        }
        let drive = self.selected.and_then(|i| self.drives.get(i)).cloned();
        if operation != "List" && drive.is_none() {
            return;
        }
        let Ok(job) = iso::new_job() else {
            // Nothing ran, so nothing on the drive changed and there are no
            // diagnostics to open.
            let unchanged = usb::Failure::new(None, false, "no job directory");
            self.job = None;
            self.error = Some(UsbError::of(operation, false, Some(&unchanged)));
            cx.notify();
            return;
        };
        self.error = None;
        self.job = Some(job.clone());
        self.scanning = operation == "List";
        self.working = !self.scanning;
        self.review = false;
        self.acknowledged = false;
        if operation == "List" {
            self.selected = None;
            self.drives.clear();
        }
        self.progress = Progress { stage: "prepare".into(), ..Default::default() };
        if operation == "Eject" {
            self.progress.stage = "eject".into();
        }
        let source = self.source.clone();
        let builds = self.supported_builds.clone();
        let cancel = self.model.read(cx).iso_cancel.clone();
        cancel.store(false, Ordering::Relaxed);
        self.model.update(cx, |m, cx| {
            m.iso_busy = true;
            m.usb_busy = true;
            cx.notify();
        });
        let (tx, mut rx) = futures::channel::mpsc::unbounded();
        self.task = Some(cx.spawn(async move |this, cx| {
            let work = cx.background_executor().spawn(async move {
                iso::prune_jobs(&job);
                iso::prune_legacy_jobs(&settings::AppPaths::from_process().root);
                let result =
                    usb::run(operation, source.as_deref(), drive.as_ref(), &builds, &job, cancel, |p| {
                        let _ = tx.unbounded_send(p);
                    });
                (result, job.is_dir())
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.progress = progress;
                    cx.notify();
                })
                .ok();
            }
            let (result, staged) = work.await;
            this.update(cx, |this, cx| {
                let cancelled = this.model.read(cx).iso_cancel.load(Ordering::Relaxed);
                this.model.update(cx, |m, cx| {
                    m.iso_busy = false;
                    m.usb_busy = false;
                    cx.notify();
                });
                this.working = false;
                this.scanning = false;
                if !staged {
                    // The job could not be created, so there are no diagnostics to show.
                    this.job = None;
                }
                match result {
                    Ok(outcome) => match operation {
                        "List" => this.drives = outcome.drives,
                        "Write" => {
                            this.complete = outcome.verified;
                            this.ejected = false;
                        }
                        "Eject" => this.ejected = outcome.ejected,
                        _ => {}
                    },
                    Err(error) => {
                        log::error!("USB operation {operation} failed: {error:#}");
                        this.error = Some(UsbError::of(operation, cancelled, error.downcast_ref()));
                    }
                }
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    fn close(&mut self, cx: &mut Context<Self>) {
        self.closed = true;
        cx.notify();
    }

    /// Back, from the footer, the title's arrow or Escape alike: from Review
    /// to the drive list, and from anywhere else out of the panel.
    pub fn back(&mut self, cx: &mut Context<Self>) {
        if self.review {
            self.review = false;
            self.acknowledged = false;
            cx.notify();
        } else {
            self.close(cx);
        }
    }
}

/// A size in decimal gigabytes, as drives are sold.
fn gigabytes(bytes: u64) -> String {
    fmt::decimal(bytes as f64 / 1e9, 1)
}

/// "28.7 GB · F: USB", leaving out parts Windows did not report. With
/// `serial`, as on Review, the drive's serial number too.
fn drive_detail(drive: &Drive, serial: bool) -> String {
    let mut parts = vec![t!("usb-drive-size", size = gigabytes(drive.size))];
    if !drive.volumes.trim().is_empty() {
        parts.push(drive.volumes.trim().to_string());
    }
    if serial && !drive.serial.trim().is_empty() {
        parts.push(t!("usb-drive-serial", serial = drive.serial.trim()));
    }
    parts.join(&t!("usb-detail-separator"))
}

impl Render for UsbPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let busy = self.working || self.scanning;
        // Results are announced by moving focus to them: an error or result
        // bar, the progress heading, or the drive list.
        let status = self.focus.get("usb-status", cx);
        let shown = (self.review, self.scanning, self.working, self.complete, self.ejected, self.error);
        let announce = self.shown != Some(shown);
        self.shown = Some(shown);
        let secondary = cx.theme().text_secondary;
        let mut body: Vec<AnyElement> = Vec::new();
        let chosen = self.selected.and_then(|i| self.drives.get(i)).cloned();
        let mut focus = None;
        // What the panel is for, while choosing what to write.
        if !self.review && !self.working && !self.complete {
            body.push(
                div()
                    .type_body()
                    .text_color(secondary)
                    .child(detail_text("usb-description", t!("usb-description")))
                    .into_any_element(),
            );
        }
        if let Some(error) = self.error {
            let (severity, title, message) = error.bar(self.job.is_some());
            let mut bar = InfoBar::new(severity, title, message).id("usb-error").focus_handle(status.clone());
            if let Some(job) = self.job.clone().filter(|_| error.offers_help()) {
                bar = bar.action(
                    Button::new("usb-error-log", t!("iso-diagnostics"))
                        .icon(Icon::Folder)
                        .on_click(move |_, _, cx| cx.reveal_path(&job)),
                );
            }
            body.push(bar.into_any_element());
            if error.offers_help() {
                body.push(self.diagnostics.panel(&self.model, cx).into_any_element());
            }
            focus = Some(status.clone());
        }
        let footer = if busy {
            let text = if self.scanning {
                t!("common-checking")
            } else {
                match self.progress.stage.as_str() {
                    "format" => t!("usb-stage-format"),
                    "copy" => t!("usb-stage-copy"),
                    "verify" => t!("usb-stage-verify"),
                    "eject" => t!("usb-eject"),
                    _ => t!("usb-stage-prepare"),
                }
            };
            body.push(
                card(cx)
                    .child(
                        card_body()
                            .gap(px(12.))
                            .child(focusable_heading("usb-stage", 2, text.clone(), &status, cx))
                            // The one live node while writing: its name is the stage.
                            .child(ProgressBar::new("usb-progress", text, self.progress.fraction()).live())
                            .child(detail_text("usb-working", t!("usb-working"))),
                    )
                    .into_any_element(),
            );
            focus = Some(status.clone());
            let cancelling = self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
            CommandBar::new().cancel(
                "usb-cancel",
                if cancelling { t!("iso-cancelling") } else { t!("common-cancel") },
                cancelling,
                cx.listener(|this, _, _, cx| {
                    this.model.update(cx, |m, cx| {
                        m.iso_cancel.store(true, Ordering::Relaxed);
                        cx.notify();
                    });
                }),
            )
        } else if self.complete {
            // A failed eject is announced above; the USB itself is still ready.
            let mut ready = InfoBar::new(
                Severity::Success,
                t!("usb-complete-title"),
                if self.ejected { t!("usb-ejected") } else { t!("usb-complete") },
            )
            .id("usb-complete");
            if focus.is_none() {
                ready = ready.focus_handle(status.clone());
                focus = Some(status.clone());
            }
            body.push(ready.into_any_element());
            let done = Button::new("usb-done", t!("common-done"))
                .on_click(cx.listener(|this, _, _, cx| this.close(cx)));
            // Once the drive is ejected, Done is all that's left to do.
            if self.ejected {
                CommandBar::new().primary(done.accent())
            } else {
                CommandBar::new().back(done).primary(
                    Button::new("usb-eject", t!("usb-eject"))
                        .accent()
                        .on_click(cx.listener(|this, _, _, cx| this.start("Eject", cx))),
                )
            }
        } else if self.review {
            if let Some(drive) = chosen {
                let mut warning = InfoBar::new(
                    Severity::Warning,
                    t!("usb-erase-title"),
                    t!("usb-erase-description", drive = drive.name.clone(), size = gigabytes(drive.size)),
                )
                .id("usb-erase");
                if focus.is_none() {
                    warning = warning.focus_handle(status.clone());
                    focus = Some(status.clone());
                }
                body.push(warning.into_any_element());
                let mut rows = card_body().gap(px(4.));
                if let Some(source) = &self.source {
                    rows = rows.child(detail_row(
                        cx,
                        "usb-iso",
                        t!("iso-source"),
                        file_value("usb-review-iso", source, cx),
                    ));
                }
                rows = rows
                    .child(detail_row(
                        cx,
                        "usb-drive",
                        t!("usb-drive"),
                        captioned(
                            "usb-review-drive",
                            drive.name.clone(),
                            Some(drive_detail(&drive, true)),
                            cx,
                        ),
                    ))
                    .child(div().pt(px(8.)).child(detail_text("usb-layout", t!("usb-layout"))))
                    .child(div().pt(px(4.)).child(
                        CheckBox::new("usb-ack", t!("usb-ack"), self.acknowledged).on_toggle(cx.listener(
                            |this, _, _, cx| {
                                this.acknowledged = !this.acknowledged;
                                cx.notify();
                            },
                        )),
                    ));
                body.push(card(cx).child(rows).into_any_element());
            }
            CommandBar::new()
                .back(
                    Button::new("usb-back", t!("common-back"))
                        .on_click(cx.listener(|this, _, _, cx| this.back(cx))),
                )
                .primary(
                    Button::new("usb-write", t!("usb-write"))
                        .accent()
                        .disabled(!self.acknowledged)
                        .on_click(cx.listener(|this, _, _, cx| this.start("Write", cx))),
                )
        } else {
            let iso = match &self.source {
                Some(path) => file_value("usb-source", path, cx),
                None => div().text_color(secondary).child(detail_text("usb-source", t!("iso-no-file"))),
            };
            body.push(
                card(cx)
                    .child(card_header_with_icon(
                        cx,
                        "usb-iso",
                        t!("iso-source"),
                        Some(Icon::Disc),
                        Some(
                            Button::new("usb-choose-iso", t!("usb-choose-iso"))
                                .icon(Icon::Folder)
                                .on_click(cx.listener(|this, _, _, cx| this.choose_iso(cx)))
                                .into_any_element(),
                        ),
                        2,
                    ))
                    .child(card_body().child(iso))
                    .into_any_element(),
            );
            // Focus lands on the chosen drive, or the first one, so the list
            // is announced; with no drives, on the text that says why.
            let target = self.selected.unwrap_or(0);
            let items = self
                .drives
                .iter()
                .enumerate()
                .map(|(i, drive)| {
                    let handle = self.focus.get(&format!("usb-drive-{i}"), cx);
                    if i == target && focus.is_none() {
                        focus = Some(handle.clone());
                    }
                    RadioItem::new(("usb-drive", i), drive.name.clone(), handle)
                        .description(drive_detail(drive, false))
                })
                .collect::<Vec<_>>();
            let entity = cx.entity();
            let mut content = card_body().gap(px(12.));
            if items.is_empty() {
                let empty = t!(
                    "usb-empty",
                    min = gigabytes(usb::MIN_BYTES),
                    max = fmt::decimal(usb::MAX_BYTES as f64 / 1e12, 1)
                );
                // The group's name carries the text, so it is read once.
                let mut text = div().id("usb-empty").role(Role::Group).aria_label(empty.clone()).child(empty);
                if focus.is_none() {
                    text = text.track_focus(&status.clone().tab_stop(false));
                    focus = Some(status.clone());
                }
                content = content.child(text);
            } else {
                content = content.child(
                    RadioGroup::new("usb-drives", t!("usb-drive"))
                        .items(items)
                        .selected(self.selected)
                        .on_select(move |index, _, cx| {
                            entity.update(cx, |this, cx| {
                                this.selected = Some(index);
                                this.acknowledged = false;
                                cx.notify();
                            })
                        }),
                );
            }
            body.push(
                card(cx)
                    .child(card_header_with_icon(
                        cx,
                        "usb-drives",
                        t!("usb-drive"),
                        Some(Icon::Usb),
                        Some(
                            Button::new("usb-refresh", t!("usb-refresh"))
                                .on_click(cx.listener(|this, _, _, cx| this.start("List", cx)))
                                .into_any_element(),
                        ),
                        2,
                    ))
                    .child(content)
                    .into_any_element(),
            );
            CommandBar::new()
                .back(
                    Button::new("usb-close", t!("common-back"))
                        .on_click(cx.listener(|this, _, _, cx| this.back(cx))),
                )
                .primary(
                    Button::new("usb-review", t!("usb-review"))
                        .accent()
                        .disabled(self.selected.is_none() || self.source.is_none())
                        .on_click(cx.listener(|this, _, _, cx| {
                            this.review = true;
                            this.acknowledged = false;
                            this.error = None;
                            cx.notify();
                        })),
                )
        };
        if announce && let Some(focus) = focus {
            window.focus(&focus, cx);
        }
        self.diagnostics.settle(&self.model, window, cx);
        // The title's arrow, like Escape, goes where the footer's Back goes, so
        // every Back on a screen does the same thing.
        let entity = cx.entity();
        let back = PanelBack {
            enabled: !busy,
            on_back: Rc::new(move |_, cx| entity.update(cx, |this, cx| this.back(cx))),
        };
        page_frame(
            "usb-page",
            Some(PageTitle {
                text: t!("usb-title").into(),
                badge: Some(t!("iso-beta").into()),
                back: Some(back),
            }),
            None,
            None,
            (&self.scroll, &self.scrollbar),
            body,
            Some(footer.into_any_element()),
            cx,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn failure(reason: Option<FailureReason>, drive_changed: bool) -> anyhow::Error {
        usb::Failure::new(reason, drive_changed, "test").into()
    }

    #[test]
    fn a_write_that_stopped_while_preparing_says_the_drive_is_unchanged() {
        let early = failure(Some(FailureReason::IsoUnsupported), false);
        assert_eq!(
            UsbError::of("Write", false, early.downcast_ref()),
            UsbError::Write { reason: Some(FailureReason::IsoUnsupported), changed: false }
        );
        assert_eq!(
            UsbError::of("Write", true, failure(None, false).downcast_ref()),
            UsbError::Cancelled { changed: false }
        );
        // Past preparing, or with no account from the worker, the drive may be erased.
        assert_eq!(
            UsbError::of("Write", true, failure(None, true).downcast_ref()),
            UsbError::Cancelled { changed: true }
        );
        assert_eq!(UsbError::of("Write", false, None), UsbError::Write { reason: None, changed: true });
    }

    #[test]
    fn scan_eject_and_cancel_are_not_reported_as_a_failed_write() {
        assert_eq!(UsbError::of("List", true, None), UsbError::Scan);
        assert_eq!(UsbError::of("Eject", false, None), UsbError::Eject);
        crate::i18n::testing::english(|| {
            let write = UsbError::Write { reason: None, changed: true }.bar(true);
            assert_eq!(write.0, Severity::Error);
            for error in [UsbError::Scan, UsbError::Eject, UsbError::Cancelled { changed: true }] {
                assert_ne!(error.bar(true).1, write.1, "{error:?}");
            }
            assert_eq!(UsbError::Eject.bar(true).0, Severity::Warning, "the USB is still ready");
            assert_eq!(UsbError::Cancelled { changed: false }.bar(true).0, Severity::Informational);
            // A typed reason is only trusted while the drive is untouched.
            let erased = UsbError::Write { reason: Some(FailureReason::DoesNotFit), changed: true }.bar(true);
            assert_eq!(erased.2, write.2);
        });
    }

    #[test]
    fn a_drive_that_changed_before_erasing_sends_the_user_to_refresh() {
        crate::i18n::testing::english(|| {
            let early = failure(Some(FailureReason::DriveChanged), false);
            let error = UsbError::of("Write", false, early.downcast_ref());
            assert_eq!(error.bar(true).2, t!("usb-failed-drive-changed"));
            assert!(error.bar(true).2.contains(&t!("usb-refresh")));
            // After erasing began, the drive may be partly written whatever changed.
            let late = UsbError::Write { reason: Some(FailureReason::DriveChanged), changed: true };
            assert_eq!(late.bar(true).2, t!("usb-failed"));
        });
    }

    #[test]
    fn without_a_job_no_message_points_at_diagnostics() {
        crate::i18n::testing::english(|| {
            let open = t!("iso-diagnostics");
            let unchanged = UsbError::Write { reason: None, changed: false };
            // With a job, these two send the user to its diagnostics.
            assert!(UsbError::Scan.bar(true).2.contains(&open) && unchanged.bar(true).2.contains(&open));
            for error in [
                UsbError::Scan,
                UsbError::Eject,
                unchanged,
                UsbError::Write { reason: None, changed: true },
                UsbError::Cancelled { changed: false },
            ] {
                let (_, title, message) = error.bar(false);
                assert!(!message.contains(&open), "{error:?}: {message}");
                assert_eq!(title, error.bar(true).1, "{error:?}");
            }
            assert_eq!(UsbError::Scan.bar(false).2, t!("iso-failed-unstaged"));
        });
    }

    #[test]
    fn the_drive_list_leaves_the_serial_number_to_review() {
        crate::i18n::testing::english(|| {
            let drive = usb::preview_drive();
            assert_eq!(drive_detail(&drive, false), "256.1 GB · F: USB");
            assert_eq!(drive_detail(&drive, true), "256.1 GB · F: USB · Serial: USB-PREVIEW");
            // Parts Windows didn't report are left out.
            let bare = Drive { volumes: " ".into(), serial: String::new(), ..drive };
            assert_eq!(drive_detail(&bare, true), "256.1 GB");
        });
    }

    #[test]
    fn back_leaves_review_for_the_drive_list_before_it_leaves_the_panel() {
        use crate::model::test_harness::{Machine, all_off, new_model, run_model_test};
        use crate::services::test_support::TempDir;
        run_model_test(|mut cx| async move {
            let temp = TempDir::new("usb-back");
            let model = new_model(&mut cx, Machine::new(all_off()).environment(temp.path()));
            let panel =
                cx.update(|cx| cx.new(|cx| UsbPage::new(model, None, vec![], Some("usb-review"), cx)));
            panel.update(&mut cx, |panel, cx| {
                panel.acknowledged = true;
                panel.back(cx);
                // The erase warning is gone, with its acknowledgement, but the drive stays chosen.
                assert!(!panel.review && !panel.acknowledged && !panel.closed);
                assert_eq!(panel.selected, Some(0));
                panel.back(cx);
                assert!(panel.closed);
            });
        });
    }

    #[test]
    fn only_a_ready_usb_that_would_not_eject_goes_without_the_log_and_reports() {
        assert!(!UsbError::Eject.offers_help(), "the USB is ready; closing what uses it is the fix");
        for error in [
            UsbError::Scan,
            UsbError::Cancelled { changed: false },
            UsbError::Write { reason: None, changed: true },
            UsbError::Write { reason: Some(FailureReason::DoesNotFit), changed: false },
        ] {
            assert!(error.offers_help(), "{error:?}");
        }
    }
}
