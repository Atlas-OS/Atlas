use super::{card_body, card_header_with_icon, detail_text, page_frame};
use crate::ui::{
    Button, CheckBox, FocusHandles, InfoBar, ProgressBar, RadioGroup, RadioItem, ScrollbarState, Severity,
    card,
};
use crate::{
    model::AppModel,
    services::{
        iso,
        usb::{self, Drive, Progress},
    },
    t,
};
use futures::StreamExt;
use gpui::{
    Context, Entity, IntoElement, ParentElement, PathPromptOptions, Render, ScrollHandle, Task, Window, div,
    prelude::*, px,
};
use std::{path::PathBuf, sync::atomic::Ordering};

pub struct UsbPage {
    pub closed: bool,
    model: Entity<AppModel>,
    source: Option<PathBuf>,
    drives: Vec<Drive>,
    selected: Option<usize>,
    review: bool,
    acknowledged: bool,
    scanning: bool,
    working: bool,
    complete: bool,
    ejected: bool,
    error: Option<&'static str>,
    progress: Progress,
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    preview: bool,
}

impl UsbPage {
    pub fn new(
        model: Entity<AppModel>,
        source: Option<PathBuf>,
        preview: Option<&str>,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        let mut page = Self {
            closed: false,
            model,
            source,
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
        };
        if let Some(state) = preview {
            page.source = Some(PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso"));
            if state != "usb-empty" {
                page.drives = vec![usb::preview_drive()];
            }
            page.selected = (!page.drives.is_empty()).then_some(0);
            page.review = state == "usb-review";
            page.complete = state == "usb-complete";
            page.working = state == "usb-progress";
            page.progress = Progress { stage: "copy".into(), done: 3, total: 8 };
            if state == "usb-failed" {
                page.error = Some("usb-failed");
            }
        } else {
            let entity = cx.entity();
            cx.defer(move |cx| entity.update(cx, |this, cx| this.start("List", cx)));
        }
        page
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
        let Ok(job) = iso::job_dir() else {
            self.error = Some("usb-failed");
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
                usb::run(operation, source.as_deref(), drive.as_ref(), &job, cancel, |p| {
                    let _ = tx.unbounded_send(p);
                })
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.progress = progress;
                    cx.notify();
                })
                .ok();
            }
            let result = work.await;
            this.update(cx, |this, cx| {
                let cancelled = this.model.read(cx).iso_cancel.load(Ordering::Relaxed);
                this.model.update(cx, |m, cx| {
                    m.iso_busy = false;
                    m.usb_busy = false;
                    cx.notify();
                });
                this.working = false;
                this.scanning = false;
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
                        this.error = Some(if operation == "Eject" {
                            "usb-eject-failed"
                        } else if cancelled {
                            "usb-cancelled"
                        } else {
                            "usb-failed"
                        })
                    }
                }
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }
}

impl Render for UsbPage {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let busy = self.working || self.scanning;
        let mut body = vec![
            InfoBar::new(Severity::Informational, t!("iso-beta"), t!("usb-description")).into_any_element(),
        ];
        let mut footer = div().flex().items_center().justify_between().gap(px(12.));
        let chosen = self.selected.and_then(|i| self.drives.get(i)).cloned();
        if let Some(error) = self.error {
            let text = match error {
                "usb-cancelled" => t!("usb-cancelled"),
                "usb-eject-failed" => t!("usb-eject-failed"),
                _ => t!("usb-failed"),
            };
            body.push(InfoBar::new(Severity::Error, t!("usb-title"), text).into_any_element());
        }
        if busy {
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
                        card_body(cx)
                            .gap(px(12.))
                            .child(detail_text("usb-stage", text.clone()))
                            .child(ProgressBar::new("usb-progress", text, self.progress.fraction()))
                            .child(detail_text("usb-working", t!("usb-working"))),
                    )
                    .into_any_element(),
            );
            let cancelling = self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
            footer = footer.child(
                Button::new(
                    "usb-cancel",
                    if cancelling { t!("iso-cancelling") } else { t!("common-cancel") },
                )
                .disabled(cancelling)
                .on_click(cx.listener(|this, _, _, cx| {
                    this.model.update(cx, |m, cx| {
                        m.iso_cancel.store(true, Ordering::Relaxed);
                        cx.notify();
                    });
                })),
            );
        } else if self.complete {
            body.push(
                InfoBar::new(
                    Severity::Success,
                    t!("usb-title"),
                    if self.ejected { t!("usb-ejected") } else { t!("usb-complete") },
                )
                .into_any_element(),
            );
            if let Some(drive) = chosen {
                body.push(detail_text("usb-completed-drive", drive.name).into_any_element());
            }
            footer = footer
                .child(Button::new("usb-done", t!("common-done")).on_click(cx.listener(|this, _, _, cx| {
                    this.closed = true;
                    cx.notify();
                })))
                .child(
                    Button::new("usb-eject", t!("usb-eject"))
                        .accent()
                        .disabled(self.ejected)
                        .on_click(cx.listener(|this, _, _, cx| this.start("Eject", cx))),
                );
        } else if self.review {
            if let Some(drive) = chosen {
                body.push(
                    InfoBar::new(
                        Severity::Warning,
                        t!("usb-erase-title"),
                        t!(
                            "usb-erase-description",
                            drive = drive.name.clone(),
                            size = crate::i18n::fmt::decimal(drive.size as f64 / 1e9, 1)
                        ),
                    )
                    .into_any_element(),
                );
                body.push(
                    card(cx)
                        .child(
                            card_body(cx)
                                .gap(px(12.))
                                .child(
                                    div()
                                        .flex()
                                        .items_center()
                                        .gap(px(12.))
                                        .child(
                                            crate::ui::TextMark::new(
                                                crate::ui::icon(crate::ui::Icon::Usb),
                                                false,
                                            )
                                            .natural_text(),
                                        )
                                        .child(detail_text(
                                            "usb-confirm-identity",
                                            t!(
                                                "usb-drive-detail",
                                                size = crate::i18n::fmt::decimal(drive.size as f64 / 1e9, 1),
                                                volumes = drive.volumes,
                                                serial = drive.serial
                                            ),
                                        )),
                                )
                                .child(detail_text("usb-layout", t!("usb-layout")))
                                .child(CheckBox::new("usb-ack", t!("usb-ack"), self.acknowledged).on_toggle(
                                    cx.listener(|this, _, _, cx| {
                                        this.acknowledged = !this.acknowledged;
                                        cx.notify();
                                    }),
                                )),
                        )
                        .into_any_element(),
                );
            }
            footer = footer
                .child(Button::new("usb-back", t!("common-back")).on_click(cx.listener(|this, _, _, cx| {
                    this.review = false;
                    this.acknowledged = false;
                    cx.notify();
                })))
                .child(
                    Button::new("usb-write", t!("usb-write"))
                        .accent()
                        .disabled(!self.acknowledged)
                        .on_click(cx.listener(|this, _, _, cx| this.start("Write", cx))),
                );
        } else {
            body.push(
                card(cx)
                    .child(
                        card_body(cx)
                            .gap(px(12.))
                            .child(
                                div()
                                    .flex()
                                    .items_center()
                                    .gap(px(12.))
                                    .when(self.source.is_some(), |this| {
                                        this.child(
                                            crate::ui::TextMark::new(
                                                crate::ui::icon(crate::ui::Icon::Disc),
                                                false,
                                            )
                                            .natural_text(),
                                        )
                                    })
                                    .child(detail_text(
                                        "usb-source",
                                        self.source
                                            .as_ref()
                                            .map(|p| p.display().to_string())
                                            .unwrap_or_else(|| t!("iso-no-file")),
                                    )),
                            )
                            .child(
                                Button::new("usb-choose-iso", t!("usb-choose-iso"))
                                    .on_click(cx.listener(|this, _, _, cx| this.choose_iso(cx))),
                            ),
                    )
                    .into_any_element(),
            );
            let items = self
                .drives
                .iter()
                .enumerate()
                .map(|(i, drive)| {
                    RadioItem::new(
                        ("usb-drive", i),
                        drive.name.clone(),
                        self.focus.get(&format!("usb-drive-{i}"), cx),
                    )
                    .description(t!(
                        "usb-drive-detail",
                        size = crate::i18n::fmt::decimal(drive.size as f64 / 1e9, 1),
                        volumes = drive.volumes.clone(),
                        serial = drive.serial.clone()
                    ))
                })
                .collect::<Vec<_>>();
            let entity = cx.entity();
            let mut content = card_body(cx).gap(px(12.));
            if items.is_empty() {
                content = content.child(detail_text("usb-empty", t!("usb-empty")));
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
                        Some(crate::ui::Icon::Usb),
                        Some(
                            Button::new("usb-refresh", t!("usb-refresh"))
                                .on_click(cx.listener(|this, _, _, cx| this.start("List", cx)))
                                .into_any_element(),
                        ),
                    ))
                    .child(content)
                    .into_any_element(),
            );
            footer = footer
                .child(Button::new("usb-close", t!("common-back")).on_click(cx.listener(|this, _, _, cx| {
                    this.closed = true;
                    cx.notify();
                })))
                .child(
                    Button::new("usb-review", t!("usb-review"))
                        .accent()
                        .disabled(self.selected.is_none() || self.source.is_none())
                        .on_click(cx.listener(|this, _, _, cx| {
                            this.review = true;
                            this.acknowledged = false;
                            this.error = None;
                            cx.notify();
                        })),
                );
        }
        if let Some(job) = self.job.clone() {
            body.push(
                Button::new("usb-diagnostics", t!("iso-diagnostics"))
                    .hyperlink()
                    .on_click(move |_, _, cx| cx.reveal_path(&job))
                    .into_any_element(),
            );
        }
        page_frame(
            "usb-page",
            Some(t!("usb-title").into()),
            None,
            (&self.scroll, &self.scrollbar),
            body.into_iter()
                .chain(std::iter::once(super::diagnostics_panel(&self.model, cx).into_any_element())),
            Some(footer.into_any_element()),
            cx,
        )
    }
}
