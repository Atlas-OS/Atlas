use super::*;
use crate::services::windows_iso::{self, Language};
use crate::ui::{ComboBox, ComboItem};
use std::sync::{Arc, atomic::AtomicBool};

pub(super) struct IsoDownload {
    open: bool,
    arch: &'static str,
    languages: Vec<Language>,
    selected: Option<usize>,
    loading: bool,
    load_failed: bool,
    transfer_failed: bool,
    cancel: Option<Arc<AtomicBool>>,
    progress: Option<(u64, u64)>,
}
impl Default for IsoDownload {
    fn default() -> Self {
        Self {
            open: false,
            arch: if cfg!(target_arch = "aarch64") { "arm64" } else { "x64" },
            languages: Vec::new(),
            selected: None,
            loading: false,
            load_failed: false,
            transfer_failed: false,
            cancel: None,
            progress: None,
        }
    }
}
impl IsoDownload {
    #[cfg(debug_assertions)]
    pub(super) fn preview(&mut self, downloading: bool) {
        self.open = true;
        self.languages = vec![Language { id: "1".into(), label: "English International".into() }];
        self.selected = Some(0);
        if downloading {
            self.cancel = Some(Arc::new(AtomicBool::new(false)));
            self.progress = Some((2_400_000_000, 7_500_000_000));
        }
    }
    pub(super) fn busy(&self) -> bool {
        self.cancel.is_some()
    }
}
impl Drop for IsoDownload {
    fn drop(&mut self) {
        if let Some(cancel) = &self.cancel {
            cancel.store(true, Ordering::Relaxed)
        }
    }
}

impl IsoPage {
    fn load_languages(&mut self, arch: &'static str, cx: &mut Context<Self>) {
        if self.preview.is_some() || self.download.busy() || self.download.loading {
            return;
        }
        self.download.open = true;
        self.download.arch = arch;
        self.download.languages.clear();
        self.download.selected = None;
        self.download.loading = true;
        self.download.load_failed = false;
        self.download.transfer_failed = false;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result = cx.background_executor().spawn(async move { windows_iso::languages(arch) }).await;
            this.update(cx, |this, cx| {
                this.download.loading = false;
                match result {
                    Ok(list) => this.download.languages = list,
                    Err(_) => this.download.load_failed = true,
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    fn save_download(&mut self, cx: &mut Context<Self>) {
        if self.download.busy() || self.model.read(cx).locked() || self.preview.is_some() {
            return;
        }
        let Some(language) = self.download.selected.and_then(|i| self.download.languages.get(i)) else {
            return;
        };
        let id = language.id.clone();
        let arch = self.download.arch;
        let folder = std::env::var_os("USERPROFILE")
            .map(PathBuf::from)
            .map(|p| p.join("Downloads"))
            .filter(|p| p.is_dir())
            .unwrap_or_else(std::env::temp_dir);
        let name = format!("Windows11-{arch}-{id}.iso");
        let picker = cx.prompt_for_new_path(&folder, Some(&name));
        let cancel = Arc::new(AtomicBool::new(false));
        self.download.cancel = Some(cancel.clone());
        self.download.transfer_failed = false;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result = async {
                let Ok(Ok(Some(path))) = picker.await else { return Ok(None) };
                if cancel.load(Ordering::Relaxed) {
                    return Ok(None);
                }
                let path = with_iso_extension(path);
                let (tx, mut rx) = futures::channel::mpsc::unbounded();
                let work = cx.background_executor().spawn(async move {
                    windows_iso::download(
                        arch,
                        &id,
                        &path,
                        || cancel.load(Ordering::Relaxed),
                        |done, total| {
                            let _ = tx.unbounded_send((done, total));
                        },
                    )?;
                    anyhow::Ok(Some(path))
                });
                while let Some(progress) = rx.next().await {
                    this.update(cx, |this, cx| {
                        this.download.progress = Some(progress);
                        cx.notify();
                    })
                    .ok();
                }
                work.await
            }
            .await;
            this.update(cx, |this, cx| {
                let cancelled = this.download.cancel.take().is_some_and(|v| v.load(Ordering::Relaxed));
                this.download.progress = None;
                match result {
                    Ok(Some(path)) => {
                        this.source = Some(path);
                        this.suggest_output();
                        this.invalidate(cx);
                        this.download.open = false;
                    }
                    Err(_) if !cancelled => this.download.transfer_failed = true,
                    _ => {}
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    pub(super) fn windows_download(&self, cx: &mut Context<Self>) -> AnyElement {
        let state = &self.download;
        let locked = self.model.read(cx).locked() || self.preview.is_some();
        if !state.open {
            return Button::new("iso-source-download", t!("iso-source-download"))
                .hyperlink()
                .compact()
                .disabled(locked)
                .on_click(cx.listener(|this, _, _, cx| this.load_languages(this.download.arch, cx)))
                .into_any_element();
        }
        let mut panel = div()
            .flex()
            .flex_col()
            .gap(px(8.))
            .child(detail_text("iso-download-arch-label", t!("iso-download-arch")));
        let owner = cx.weak_entity();
        panel = panel.child(
            ComboBox::new("iso-download-arch", t!("iso-download-arch"))
                .items([
                    ComboItem::new(t!("iso-architecture-x64")),
                    ComboItem::new(t!("iso-architecture-arm64")),
                ])
                .selected(Some(usize::from(state.arch == "arm64")))
                .disabled(locked || state.loading || state.busy())
                .on_select(move |index, _, cx| {
                    owner
                        .update(cx, |this, cx| {
                            this.load_languages(if index == 1 { "arm64" } else { "x64" }, cx)
                        })
                        .ok();
                }),
        );
        let owner = cx.weak_entity();
        if !state.languages.is_empty() {
            panel = panel.child(detail_text("iso-download-language-label", t!("settings-language"))).child(
                ComboBox::new("iso-download-language", t!("settings-language"))
                    .items(state.languages.iter().map(|l| ComboItem::new(l.label.clone())))
                    .selected(state.selected)
                    .disabled(locked || state.busy())
                    .on_select(move |i, _, cx| {
                        owner
                            .update(cx, |this, cx| {
                                this.download.selected = Some(i);
                                this.download.transfer_failed = false;
                                cx.notify();
                            })
                            .ok();
                    }),
            );
        }
        if state.loading {
            panel = panel.child(detail_text("iso-download-status", t!("iso-download-languages")));
        } else if state.load_failed || state.transfer_failed {
            panel = panel
                .child(detail_text(
                    "iso-download-error",
                    if state.load_failed {
                        t!("iso-download-list-error")
                    } else {
                        t!("iso-download-file-error")
                    },
                ))
                .child(
                    Button::new("iso-download-website", t!("iso-download-website"))
                        .hyperlink()
                        .compact()
                        .opens(if state.arch == "arm64" {
                            "https://www.microsoft.com/software-download/windows11arm64"
                        } else {
                            WINDOWS_DOWNLOAD
                        }),
                );
        }
        if state.busy() {
            let status = if let Some((done, total)) = state.progress {
                t!(
                    "iso-download-progress",
                    received = describe::file_size(done),
                    total = describe::file_size(total)
                )
            } else {
                t!("iso-download-starting")
            };
            let fraction = state.progress.map(|(done, total)| done as f32 / total as f32);
            panel = panel
                .child(detail_text("iso-download-progress", status.clone()))
                .child(ProgressBar::new("iso-windows-transfer", status, fraction).live())
                .child(div().flex().child(
                    Button::new("iso-download-cancel", t!("package-cancel-download")).on_click(cx.listener(
                        |this, _, _, cx| {
                            if let Some(cancel) = &this.download.cancel {
                                cancel.store(true, Ordering::Relaxed)
                            }
                            cx.notify();
                        },
                    )),
                ));
        } else if state.load_failed {
            panel = panel.child(
                Button::new("iso-load-retry", t!("common-try-again"))
                    .disabled(locked)
                    .on_click(cx.listener(|this, _, _, cx| this.load_languages(this.download.arch, cx))),
            );
        } else if !state.loading {
            panel = panel.child(
                Button::new("iso-save-download", t!("iso-source-download"))
                    .disabled(locked || state.selected.is_none())
                    .on_click(cx.listener(|this, _, _, cx| this.save_download(cx))),
            );
        }
        panel.into_any_element()
    }
}
