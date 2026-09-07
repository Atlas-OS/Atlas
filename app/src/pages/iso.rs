//! ISO creation is independent of the live-install flow and its host checks.
use super::{
    card_body, card_header, card_header_with_icon, chip_list, detail_row, detail_text, heading, page_frame,
};
use crate::i18n::describe;
use crate::model::{AppModel, Page};
use crate::services::{
    iso::{self, ImageInfo, Mode, Request, Stage},
    playbook::{self, Manifest, PageKind},
    settings, system,
};
use crate::t;
use crate::theme::ActiveTheme;
use crate::ui::{
    Button, CheckBox, FocusHandles, Icon, InfoBar, ProgressBar, RadioGroup, RadioItem, ScrollbarState,
    Severity, Typography, a11y_text, card,
};
use futures::StreamExt;
use gpui::{
    AnyElement, Context, ElementId, Entity, IntoElement, ParentElement, PathPromptOptions, Render,
    ScrollHandle, Task, Window, div, prelude::*, px,
};
use std::path::PathBuf;
use std::sync::atomic::Ordering;

pub struct IsoPage {
    usb: Option<Entity<super::usb::UsbPage>>,
    username: Entity<crate::ui::text_input::TextInput>,
    model: Entity<AppModel>,
    source: Option<PathBuf>,
    archive: Option<PathBuf>,
    output: Option<PathBuf>,
    package: Option<PathBuf>,
    setup_available: bool,
    manifest: Option<Manifest>,
    options: Vec<String>,
    image: Option<ImageInfo>,
    mode: Mode,
    drivers: crate::services::preparation::Drivers,
    reinstall_this_pc: bool,
    copy_network_drivers: bool,
    update_network_drivers: bool,
    step: usize,
    stage: Stage,
    error: bool,
    release_unverified: bool,
    complete: bool,
    cancelled: bool,
    job: Option<PathBuf>,
    task: Option<Task<()>>,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    focus: FocusHandles,
    // Debug-only fixtures never perform I/O or start a build.
    preview: Option<String>,
    shown: Option<(usize, bool, bool, bool, bool)>,
}

impl IsoPage {
    pub fn new(model: Entity<AppModel>, cx: &mut Context<Self>) -> Self {
        let username = cx.new(crate::ui::text_input::TextInput::new);
        cx.observe(&username, |_, _, cx| cx.notify()).detach();
        cx.observe(&model, |_, _, cx| cx.notify()).detach();
        let mut page = Self {
            usb: None,
            username,
            model,
            source: None,
            archive: None,
            output: None,
            package: None,
            setup_available: false,
            manifest: None,
            options: vec![],
            image: None,
            mode: Mode::Interactive,
            drivers: Default::default(),
            reinstall_this_pc: false,
            copy_network_drivers: true,
            update_network_drivers: false,
            step: 0,
            stage: Stage::Inspect,
            error: false,
            release_unverified: false,
            complete: false,
            cancelled: false,
            job: None,
            task: None,
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            focus: FocusHandles::default(),
            preview: None,
            shown: None,
        };
        if cfg!(debug_assertions)
            && let Ok(state) = std::env::var("ATLAS_ISO_PREVIEW")
        {
            page.preview = Some(state.clone());
            page.source = Some(PathBuf::from(r"C:\Downloads\Windows11_25H2_English_x64.iso"));
            page.archive = Some(PathBuf::from(r"C:\Downloads\Atlas.apbx"));
            page.output = Some(PathBuf::from(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso"));
            page.username.update(cx, |input, cx| input.set_value("Atlas", cx));
            page.image = Some(ImageInfo { editions: vec!["Windows 11 Pro".into()], bytes: 6_500_000_000 });
            page.manifest = playbook::parse(include_str!("../../../playbook/playbook.conf")).ok();
            page.options = page.manifest.as_ref().map(iso::default_options).unwrap_or_default();
            page.step = match state.as_str() {
                "choices" | "before" | "before-desktop" | "network-drivers" => 1,
                "review" | "review-before" => 2,
                _ => 0,
            };
            page.mode = match state.as_str() {
                "before" | "review-before" => Mode::Configured,
                "before-desktop" => Mode::BeforeDesktop,
                _ => Mode::Interactive,
            };
            page.setup_available = matches!(state.as_str(), "before" | "before-desktop" | "review-before");
            page.reinstall_this_pc = state == "network-drivers";
            page.update_network_drivers = state == "network-drivers";
            page.complete = state == "complete";
            page.error = matches!(state.as_str(), "failed" | "release-unknown");
            page.release_unverified = state == "release-unknown";
            if page.error {
                page.job = Some(settings::app_data_dir());
            }
            page.stage = Stage::Master;
            if state.starts_with("usb-") {
                let panel = cx.new(|cx| {
                    super::usb::UsbPage::new(page.model.clone(), page.output.clone(), Some(&state), cx)
                });
                cx.observe(&panel, |_, _, cx| cx.notify()).detach();
                page.usb = Some(panel);
            }
        }
        page
    }

    fn open_usb(&mut self, source: Option<PathBuf>, cx: &mut Context<Self>) {
        let model = self.model.clone();
        let panel = cx.new(|cx| super::usb::UsbPage::new(model, source, None, cx));
        cx.observe(&panel, |_, _, cx| cx.notify()).detach();
        self.usb = Some(panel);
        cx.notify();
    }

    fn pick(&mut self, field: usize, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        if self.model.read(cx).locked() {
            return;
        }
        let receiver = if field == 2 {
            let directory = self
                .source
                .as_ref()
                .and_then(|p| p.parent())
                .map(PathBuf::from)
                .unwrap_or_else(std::env::temp_dir);
            let response = cx.prompt_for_new_path(&directory, Some("Atlas-Windows.iso"));
            cx.spawn(async move |this, cx| {
                if let Ok(Ok(Some(path))) = response.await {
                    this.update(cx, |this, cx| {
                        this.output = Some(path);
                        this.invalidate(cx);
                    })
                    .ok();
                }
            })
            .detach();
            return;
        } else {
            cx.prompt_for_paths(PathPromptOptions {
                files: true,
                directories: false,
                multiple: false,
                prompt: Some(if field == 0 { t!("iso-source") } else { t!("iso-package") }.into()),
            })
        };
        cx.spawn(async move |this, cx| {
            if let Ok(Ok(Some(paths))) = receiver.await
                && let Some(path) = paths.into_iter().next()
            {
                this.update(cx, |this, cx| {
                    if field == 0 {
                        this.source = Some(path);
                    } else {
                        this.archive = Some(path);
                    }
                    this.invalidate(cx);
                })
                .ok();
            }
        })
        .detach();
    }

    fn invalidate(&mut self, cx: &mut Context<Self>) {
        self.image = None;
        self.error = false;
        self.release_unverified = false;
        self.complete = false;
        self.cancelled = false;
        self.step = 0;
        cx.notify();
    }

    fn start(&mut self, inspect: bool, cx: &mut Context<Self>) {
        if self.preview.is_some() {
            return;
        }
        if self.model.read(cx).locked() || self.model.read(cx).recovering {
            return;
        }
        let (Some(source), Some(archive), Some(output)) =
            (self.source.clone(), self.archive.clone(), self.output.clone())
        else {
            return;
        };
        let Ok(job) = iso::job_dir() else {
            self.error = true;
            cx.notify();
            return;
        };
        self.job = Some(job.clone());
        self.error = false;
        self.release_unverified = false;
        self.cancelled = false;
        self.complete = false;
        self.stage = Stage::Inspect;
        let mode = self.mode;
        let drivers = self.drivers;
        let reinstall_this_pc = self.reinstall_this_pc;
        let copy_network_drivers = reinstall_this_pc && self.copy_network_drivers;
        let update_network_drivers = copy_network_drivers && self.update_network_drivers;
        let username = if inspect { "Atlas".to_string() } else { self.username.read(cx).value().to_string() };
        let options = self.options.clone();
        let inspected_package = self.package.clone();
        self.model.update(cx, |m, cx| {
            m.iso_busy = true;
            m.iso_cancel.store(false, Ordering::Relaxed);
            cx.notify();
        });
        let cancel = self.model.read(cx).iso_cancel.clone();
        self.task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded();
            let work = cx.background_executor().spawn(async move {
                let operation = || -> anyhow::Result<(Option<ImageInfo>, PathBuf, Manifest)> {
                    // Inspect and inject the same archive bytes even if the original
                    // file is replaced while the worker is running.
                    let snapshot = job.join("Atlas.apbx");
                    std::fs::copy(&archive, &snapshot)?;
                    let (package, manifest) = playbook::extract_into(
                        &snapshot,
                        &settings::AppPaths::from_process().playbooks(),
                        |_, _| {},
                    )?;
                    anyhow::ensure!(
                        inspect || inspected_package.as_ref() == Some(&package),
                        "The package changed after inspection. Go back and check the files again."
                    );
                    let options = if inspect { iso::default_options(&manifest) } else { options };
                    anyhow::ensure!(
                        iso::supports_version(&manifest.version),
                        "ISO creation requires Atlas 0.6.0 or newer."
                    );
                    iso::validate_options(&manifest, &options)?;
                    let request = Request {
                        reinstall_this_pc,
                        copy_network_drivers,
                        update_network_drivers,
                        drivers,
                        username,
                        source,
                        archive: snapshot,
                        output,
                        package: package.clone(),
                        app: std::env::current_exe()?,
                        mode: if inspect { Mode::Interactive } else { mode },
                        options,
                        supported_builds: manifest.supported_builds.clone(),
                    };
                    let image = iso::run(&request, &job, inspect, cancel, |stage| {
                        let _ = tx.unbounded_send(stage);
                    })?;
                    Ok((image, package, manifest))
                };
                let result = operation();
                if let Err(error) = &result {
                    log::error!("ISO operation failed: {error:#}");
                    let _ = std::fs::write(job.join("error.txt"), format!("{error:#}"));
                }
                result
            });
            while let Some(stage) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.stage = stage;
                    cx.notify();
                })
                .ok();
            }
            let result = work.await;
            this.update(cx, |this, cx| {
                let cancelled = this.model.read(cx).iso_cancel.load(Ordering::Relaxed);
                this.model.update(cx, |m, cx| {
                    m.iso_busy = false;
                    cx.notify();
                });
                match result {
                    Ok((image, package, manifest)) => {
                        if inspect {
                            this.image = image;
                            this.options = iso::default_options(&manifest);
                            this.manifest = Some(manifest);
                            this.setup_available = iso::supports_setup(&package);
                            this.package = Some(package);
                            this.step = 1;
                        } else {
                            this.complete = true;
                        }
                    }
                    Err(error) => {
                        this.release_unverified = error.is::<iso::UnverifiedWindowsRelease>();
                        this.error = !cancelled;
                        this.cancelled = cancelled;
                    }
                }
                this.scroll.set_offset(gpui::point(px(0.), px(0.)));
                cx.notify();
            })
            .ok();
        }));
        cx.notify();
    }

    fn stage_text(&self) -> String {
        match self.stage {
            Stage::Inspect => t!("iso-stage-inspect"),
            Stage::Copy => t!("iso-stage-copy"),
            Stage::Inject => t!("iso-stage-inject"),
            Stage::NetworkDrivers => t!("iso-stage-network-drivers"),
            Stage::Master => t!("iso-stage-master"),
            Stage::Verify => t!("iso-stage-verify"),
            Stage::Cleanup => t!("iso-stage-cleanup"),
        }
    }

    fn files(&self, cx: &mut Context<Self>) -> AnyElement {
        let mut content = card_body(cx).gap(px(14.));
        for (index, label, path) in [
            (0, t!("iso-source"), &self.source),
            (1, t!("iso-package"), &self.archive),
            (2, t!("iso-output"), &self.output),
        ] {
            content = content.child(
                div().flex().flex_col().gap(px(6.)).child(div().type_body_strong().child(label)).child(
                    div()
                        .flex()
                        .items_center()
                        .gap(px(12.))
                        .when(index == 0 && path.is_some(), |this| {
                            this.child(
                                crate::ui::TextMark::new(crate::ui::icon(Icon::Disc), false).natural_text(),
                            )
                        })
                        .child(
                            div().flex_1().min_w_0().child(detail_text(
                                &format!("iso-path-{index}"),
                                path.as_ref()
                                    .map(|p| p.display().to_string())
                                    .unwrap_or_else(|| t!("iso-no-file")),
                            )),
                        )
                        .child(
                            Button::new(
                                ("iso-pick", index),
                                if index == 2 { t!("iso-save-as") } else { t!("iso-browse") },
                            )
                            .icon(Icon::Folder)
                            .on_click(cx.listener(move |this, _, _, cx| this.pick(index, cx))),
                        ),
                ),
            );
        }
        card(cx).child(content).into_any_element()
    }

    fn choices(&mut self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let mut body = vec![];
        let target_entity = cx.entity();
        let target_items = [
            RadioItem::new("iso-this-pc", t!("iso-target-this"), self.focus.get("iso-this-pc", cx))
                .icon(Icon::PC),
            RadioItem::new("iso-other-pc", t!("iso-target-other"), self.focus.get("iso-other-pc", cx))
                .icon(Icon::Devices),
        ];
        let mut target = card_body(cx)
            .gap(px(12.))
            .child(heading("iso-target-title", 2, t!("iso-target-title"), cx))
            .child(
                RadioGroup::new("iso-target", t!("iso-target-title"))
                    .items(target_items)
                    .selected(Some(usize::from(!self.reinstall_this_pc)))
                    .on_select(move |index, _, cx| {
                        target_entity.update(cx, |this, cx| {
                            this.reinstall_this_pc = index == 0;
                            cx.notify();
                        })
                    }),
            );
        if self.reinstall_this_pc {
            target = target
                .child(
                    CheckBox::new("iso-copy-network", t!("iso-copy-network"), self.copy_network_drivers)
                        .on_toggle(cx.listener(|this, _, _, cx| {
                            this.copy_network_drivers = !this.copy_network_drivers;
                            cx.notify();
                        })),
                )
                .child(detail_text("iso-network-detail", t!("iso-network-detail")));
            if self.copy_network_drivers {
                let network_entity = cx.entity();
                target = target.child(
                    RadioGroup::new("iso-network-source", t!("iso-network-source"))
                        .items([
                            RadioItem::new(
                                "iso-network-installed",
                                t!("iso-network-installed"),
                                self.focus.get("iso-network-installed", cx),
                            ),
                            RadioItem::new(
                                "iso-network-updated",
                                t!("iso-network-updated"),
                                self.focus.get("iso-network-updated", cx),
                            )
                            .description(t!("iso-network-updated-detail")),
                        ])
                        .selected(Some(usize::from(self.update_network_drivers)))
                        .on_select(move |index, _, cx| {
                            network_entity.update(cx, |this, cx| {
                                this.update_network_drivers = index == 1;
                                cx.notify();
                            })
                        }),
                );
            }
        }
        body.push(card(cx).child(target).into_any_element());
        body.push(
            card(cx)
                .child(
                    card_body(cx)
                        .gap(px(8.))
                        .child(heading("iso-account-title", 2, t!("iso-username"), cx))
                        .child(detail_text("iso-account-description", t!("iso-account-description")))
                        .child(self.username.clone())
                        .when(
                            !self.username.read(cx).value().is_empty()
                                && !iso::valid_username(self.username.read(cx).value()),
                            |this| this.child(detail_text("iso-account-error", t!("iso-account-invalid"))),
                        ),
                )
                .into_any_element(),
        );
        let entity = cx.entity();
        let driver_entity = entity.clone();
        body.push(
            card(cx)
                .child(
                    card_body(cx).child(heading("iso-drivers-title", 2, t!("prepare-drivers"), cx)).child(
                        RadioGroup::new("iso-drivers", t!("prepare-drivers"))
                            .items([
                                RadioItem::new(
                                    "iso-drivers-auto",
                                    t!("prepare-drivers-auto"),
                                    self.focus.get("iso-drivers-auto", cx),
                                )
                                .description(t!("prepare-drivers-auto-detail")),
                                RadioItem::new(
                                    "iso-drivers-manual",
                                    t!("prepare-drivers-manual"),
                                    self.focus.get("iso-drivers-manual", cx),
                                )
                                .description(t!("prepare-drivers-manual-detail")),
                            ])
                            .selected(Some(usize::from(
                                self.drivers == crate::services::preparation::Drivers::Manual,
                            )))
                            .on_select(move |index, _, cx| {
                                driver_entity.update(cx, |this, cx| {
                                    this.drivers = if index == 0 {
                                        crate::services::preparation::Drivers::Automatic
                                    } else {
                                        crate::services::preparation::Drivers::Manual
                                    };
                                    cx.notify();
                                })
                            }),
                    ),
                )
                .into_any_element(),
        );
        let modes = RadioGroup::new("iso-mode", t!("iso-mode-title"))
            .items([
                RadioItem::new(
                    "iso-interactive",
                    t!("iso-mode-interactive"),
                    self.focus.get("iso-interactive", cx),
                )
                .description(t!("iso-mode-interactive-description")),
                RadioItem::new("iso-before", t!("iso-mode-before"), self.focus.get("iso-before", cx))
                    .description(t!("iso-mode-before-description")),
                RadioItem::new("iso-desktop", t!("iso-mode-desktop"), self.focus.get("iso-desktop", cx))
                    .description(t!("iso-mode-desktop-description")),
            ])
            .selected(Some(match self.mode {
                Mode::Interactive => 0,
                Mode::Configured => 1,
                Mode::BeforeDesktop => 2,
            }))
            .on_select(move |index, _, cx| {
                entity.update(cx, |this, cx| {
                    this.mode = match index {
                        0 => Mode::Interactive,
                        1 => Mode::Configured,
                        _ => Mode::BeforeDesktop,
                    };
                    cx.notify();
                })
            });
        body.push(
            card(cx)
                .child(
                    card_body(cx)
                        .gap(px(8.))
                        .child(heading("iso-mode-title", 2, t!("iso-mode-title"), cx))
                        .child(modes)
                        .child(detail_text("iso-privacy-defaults", t!("iso-privacy-defaults"))),
                )
                .into_any_element(),
        );
        if self.mode != Mode::Interactive {
            if !self.setup_available {
                body.insert(
                    0,
                    InfoBar::new(
                        Severity::Warning,
                        t!("iso-package-unsupported-title"),
                        t!("iso-package-unsupported"),
                    )
                    .into_any_element(),
                );
            }
            if let Some(manifest) = self.manifest.clone() {
                for (page_index, page) in manifest.pages.iter().enumerate() {
                    if page.depends_on.as_ref().is_some_and(|name| !self.options.contains(name)) {
                        continue;
                    }
                    let mut content = card_body(cx);
                    if let Some(description) = describe::page_description(page) {
                        content =
                            content.child(detail_text(&format!("iso-options-{page_index}"), description));
                    }
                    if page.kind == PageKind::Radio {
                        let items: Vec<_> = page
                            .options
                            .iter()
                            .map(|option| {
                                let key = format!("iso-option-{}", option.name);
                                let mut item = RadioItem::new(
                                    key.clone(),
                                    describe::option_label(&option.name, &option.text),
                                    self.focus.get(&key, cx),
                                );
                                if let Some(text) =
                                    describe::known_option_consequence(&option.name, &option.text)
                                {
                                    item = item.description(text);
                                }
                                item
                            })
                            .collect();
                        let names: Vec<_> = page.options.iter().map(|o| o.name.clone()).collect();
                        let selected = names.iter().position(|n| self.options.contains(n));
                        let entity = cx.entity();
                        content = content.child(
                            RadioGroup::new(("iso-options", page_index), t!("iso-atlas-options"))
                                .items(items)
                                .selected(selected)
                                .on_select(move |index, _, cx| {
                                    entity.update(cx, |this, cx| {
                                        this.options.retain(|n| !names.contains(n));
                                        if let Some(name) = names.get(index) {
                                            this.options.push(name.clone());
                                        }
                                        this.clean_options();
                                        cx.notify();
                                    })
                                }),
                        );
                    } else {
                        for option in &page.options {
                            let name = option.name.clone();
                            let selected = self.options.contains(&name);
                            let mut checkbox = CheckBox::new(
                                format!("iso-option-{name}"),
                                describe::option_label(&name, &option.text),
                                selected,
                            );
                            if let Some(description) = describe::known_option_consequence(&name, &option.text)
                            {
                                checkbox = checkbox.description(description);
                            }
                            content =
                                content.child(checkbox.on_toggle(cx.listener(move |this, _, _, cx| {
                                    if selected {
                                        this.options.retain(|n| n != &name);
                                    } else {
                                        this.options.push(name.clone());
                                    }
                                    this.clean_options();
                                    cx.notify();
                                })));
                        }
                    }
                    body.push(card(cx).child(content).into_any_element());
                }
            }
        }
        body
    }

    fn clean_options(&mut self) {
        if let Some(manifest) = &self.manifest {
            for page in &manifest.pages {
                if page.depends_on.as_ref().is_some_and(|n| !self.options.contains(n)) {
                    self.options.retain(|n| !page.options.iter().any(|o| &o.name == n));
                } else if page.kind == PageKind::Radio
                    && !page.options.iter().any(|o| self.options.contains(&o.name))
                    && let Some(default) = page.options.iter().find(|o| o.default)
                {
                    self.options.push(default.name.clone());
                }
            }
        }
    }
    /// Step 3: everything the ISO will be built from, as labelled rows in two
    /// cards, each with a Change link back to the step that set it.
    fn review(&self, cx: &mut Context<Self>) -> Vec<AnyElement> {
        let secondary = cx.theme().text_secondary;
        let caption = move |text: gpui::Text| div().type_caption().text_color(secondary).child(text);
        let stacked = || div().flex().flex_col().gap(px(2.)).min_w_0();
        let file_value = |key: &str, path: &PathBuf| {
            let name = path
                .file_name()
                .map(|name| name.to_string_lossy().into_owned())
                .unwrap_or_else(|| path.display().to_string());
            let folder = path
                .parent()
                .filter(|parent| !parent.as_os_str().is_empty())
                .map(|parent| parent.display().to_string());
            stacked().child(detail_text(key, name)).when_some(folder, |this, folder| {
                this.child(caption(a11y_text(ElementId::Name(format!("detail-{key}-folder").into()), folder)))
            })
        };
        let change = |id: &'static str, title: String, step: usize| {
            Button::new(id, t!("common-change"))
                .hyperlink()
                .compact()
                .aria_label(t!("summary-change-a11y", title = title.as_str()))
                .on_click(cx.listener(move |this, _, _, cx| {
                    this.step = step;
                    this.scroll.set_offset(gpui::point(px(0.), px(0.)));
                    cx.notify();
                }))
                .into_any_element()
        };
        let change_files = change("iso-change-files", t!("iso-review-files"), 0);
        let change_choices = change("iso-change-choices", t!("iso-mode-title"), 1);

        let mut files = card_body(cx).gap(px(4.));
        if let Some(path) = &self.source {
            files = files.child(detail_row(
                cx,
                "iso-source",
                t!("iso-source"),
                file_value("iso-review-source", path),
            ));
        }
        if let Some(image) = &self.image {
            files = files
                .child(detail_row(
                    cx,
                    "iso-editions",
                    t!("iso-review-editions"),
                    div()
                        .flex()
                        .flex_col()
                        .gap(px(6.))
                        .min_w_0()
                        .child(chip_list(
                            cx,
                            "iso-editions",
                            &t!("iso-review-editions"),
                            image.editions.clone(),
                        ))
                        .child(caption(detail_text("iso-edition-selection", t!("iso-edition-selection")))),
                ))
                .child(detail_row(
                    cx,
                    "iso-size",
                    t!("iso-review-size"),
                    detail_text(
                        "iso-size",
                        t!("iso-review-size-value", size = crate::i18n::fmt::megabytes_value(image.bytes)),
                    ),
                ));
        }
        if let Some(path) = &self.archive {
            files = files.child(detail_row(
                cx,
                "iso-package",
                t!("iso-review-package"),
                file_value("iso-review-package", path),
            ));
        }
        if let Some(path) = &self.output {
            files = files.child(detail_row(
                cx,
                "iso-output",
                t!("iso-review-output"),
                file_value("iso-review-output", path),
            ));
        }

        let network = (self.reinstall_this_pc && self.copy_network_drivers).then(|| {
            if self.update_network_drivers {
                t!("iso-network-updated-detail")
            } else {
                t!("iso-network-detail")
            }
        });
        let (mode_title, mode_detail) = match self.mode {
            Mode::Interactive => (t!("iso-mode-interactive"), t!("iso-mode-interactive-description")),
            Mode::BeforeDesktop => (t!("iso-mode-desktop"), t!("iso-mode-desktop-description")),
            _ => (t!("iso-mode-before"), t!("iso-mode-before-description")),
        };
        let mut choices = card_body(cx)
            .gap(px(4.))
            .child(detail_row(
                cx,
                "iso-account",
                t!("iso-review-account"),
                detail_text("iso-review-account", self.username.read(cx).value().to_string()),
            ))
            .child(detail_row(
                cx,
                "iso-target",
                t!("iso-review-target"),
                stacked()
                    .child(detail_text(
                        "iso-review-target",
                        if self.reinstall_this_pc { t!("iso-target-this") } else { t!("iso-target-other") },
                    ))
                    .when_some(network, |this, network| {
                        this.child(caption(detail_text("iso-review-network", network)))
                    }),
            ))
            .child(detail_row(
                cx,
                "iso-drivers",
                t!("iso-review-drivers"),
                detail_text(
                    "iso-review-drivers",
                    if self.drivers == crate::services::preparation::Drivers::Manual {
                        t!("prepare-drivers-manual")
                    } else {
                        t!("prepare-drivers-auto")
                    },
                ),
            ))
            .child(detail_row(
                cx,
                "iso-mode",
                t!("iso-atlas-options"),
                stacked()
                    .child(detail_text("iso-review-mode", mode_title))
                    .child(caption(detail_text("iso-review-mode-detail", mode_detail))),
            ));
        if self.mode != Mode::Interactive {
            let labels: Vec<String> = self
                .manifest
                .as_ref()
                .map(|manifest| {
                    self.options
                        .iter()
                        .filter_map(|name| {
                            manifest.option_label(name).map(|text| describe::option_label(name, text))
                        })
                        .collect()
                })
                .unwrap_or_default();
            let value: AnyElement = if labels.is_empty() {
                div()
                    .text_color(secondary)
                    .child(detail_text("iso-review-options", t!("common-none")))
                    .into_any_element()
            } else {
                chip_list(cx, "iso-review-options", &t!("common-options"), labels).into_any_element()
            };
            choices = choices.child(detail_row(cx, "iso-options", t!("common-options"), value));
        }

        vec![
            card(cx)
                .child(card_header_with_icon(
                    cx,
                    "iso-review-files",
                    t!("iso-review-files"),
                    Some(Icon::Disc),
                    Some(change_files),
                ))
                .child(files)
                .into_any_element(),
            card(cx)
                .child(card_header(cx, "iso-review-choices", t!("iso-mode-title"), Some(change_choices)))
                .child(choices)
                .into_any_element(),
            div()
                .type_body()
                .text_color(secondary)
                .child(detail_text("iso-review-description", t!("iso-review-description")))
                .into_any_element(),
        ]
    }
}

impl Render for IsoPage {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if let Some(usb) = &self.usb {
            if !usb.read(cx).closed {
                return div().size_full().child(usb.clone()).into_any_element();
            }
            self.usb = None;
        }
        let busy = self.model.read(cx).iso_busy || self.preview.as_deref() == Some("progress");
        let cancelling = busy && self.model.read(cx).iso_cancel.load(Ordering::Relaxed);
        let elevated = self.model.read(cx).elevated || self.preview.is_some();
        let focus = self.focus.get("iso-status", cx);
        let step_focus =
            if self.error || self.cancelled { self.focus.get("iso-step-heading", cx) } else { focus.clone() };
        let shown = (self.step, busy, self.complete, self.error, self.cancelled);
        if self.shown != Some(shown) {
            self.shown = Some(shown);
            window.focus(&focus, cx);
        }
        let mut body = vec![
            InfoBar::new(Severity::Informational, t!("iso-beta"), t!("iso-beta-description"))
                .into_any_element(),
        ];
        let mut footer = div().flex().items_center().justify_between().gap(px(12.));
        if elevated && !busy && !self.complete {
            let title = match self.step {
                0 => t!("iso-inspect"),
                1 => t!("iso-mode-title"),
                _ => t!("iso-review"),
            };
            body.push(
                super::focusable_heading(
                    "iso-step-heading",
                    2,
                    t!("step-heading", number = self.step + 1, total = 3, title = title),
                    &step_focus,
                    cx,
                )
                .into_any_element(),
            );
        }
        if !elevated {
            body.push(
                card(cx)
                    .child(
                        card_body(cx)
                            .gap(px(12.))
                            .child(detail_text("iso-admin-description", t!("iso-admin-description")))
                            .child(
                                Button::new("iso-elevate", t!("common-restart-as-administrator"))
                                    .accent()
                                    .icon(Icon::Admin)
                                    .on_click(cx.listener(
                                        |this, _, _, cx| match system::relaunch_iso_elevated() {
                                            Ok(()) => cx.quit(),
                                            Err(_) => {
                                                this.error = true;
                                                cx.notify();
                                            }
                                        },
                                    )),
                            ),
                    )
                    .into_any_element(),
            );
        } else if busy {
            let stage = if cancelling { t!("iso-cancelling") } else { self.stage_text() };
            body.push(
                card(cx)
                    .child(
                        card_body(cx)
                            .gap(px(18.))
                            .child(super::focusable_heading(
                                "iso-progress-title",
                                2,
                                stage.clone(),
                                &focus,
                                cx,
                            ))
                            .child(ProgressBar::new("iso-progress", stage, None))
                            .child(detail_text("iso-progress-description", t!("iso-progress-description"))),
                    )
                    .into_any_element(),
            );
            footer = footer.child(Button::new("iso-cancel", t!("iso-cancel")).disabled(cancelling).on_click(
                cx.listener(|this, _, _, cx| {
                    this.model.update(cx, |m, cx| {
                        m.iso_cancel.store(true, Ordering::Relaxed);
                        cx.notify();
                    });
                }),
            ));
        } else if self.complete {
            body.push(
                InfoBar::new(Severity::Success, t!("iso-complete"), t!("iso-complete-description"))
                    .focus_handle(focus.clone())
                    .into_any_element(),
            );
            if let Some(path) = &self.output {
                body.push(detail_text("iso-created-file", path.display().to_string()).into_any_element());
            }
            footer = footer
                .child(Button::new("iso-done", t!("common-done")).on_click(
                    cx.listener(|this, _, _, cx| this.model.update(cx, |m, cx| m.navigate(Page::Home, cx))),
                ))
                .child(Button::new("iso-reveal", t!("iso-open-folder")).icon(Icon::Folder).on_click(
                    cx.listener(|this, _, _, cx| {
                        if let Some(path) = &this.output {
                            cx.reveal_path(path);
                        }
                    }),
                ))
                .child(
                    Button::new("iso-write-usb", t!("usb-title"))
                        .accent()
                        .on_click(cx.listener(|this, _, _, cx| this.open_usb(this.output.clone(), cx))),
                );
        } else {
            if self.step == 0 {
                body.push(
                    detail_text("iso-files-description", t!("iso-files-description")).into_any_element(),
                );
                body.push(self.files(cx));
                body.push(
                    Button::new("iso-existing-usb", t!("usb-existing"))
                        .hyperlink()
                        .on_click(cx.listener(|this, _, _, cx| this.open_usb(None, cx)))
                        .into_any_element(),
                );
                footer = footer.child(div().flex_1()).child(
                    Button::new("iso-inspect", t!("iso-inspect"))
                        .accent()
                        .disabled(
                            self.source.is_none()
                                || self.archive.is_none()
                                || self.output.is_none()
                                || self.model.read(cx).locked(),
                        )
                        .on_click(cx.listener(|this, _, _, cx| this.start(true, cx))),
                );
            } else if self.step == 1 {
                body.extend(self.choices(cx));
                footer = footer
                    .child(Button::new("iso-back-files", t!("common-back")).on_click(cx.listener(
                        |this, _, _, cx| {
                            this.step = 0;
                            cx.notify();
                        },
                    )))
                    .child(
                        Button::new("iso-review", t!("iso-review"))
                            .accent()
                            .disabled(
                                (self.mode != Mode::Interactive && !self.setup_available)
                                    || !iso::valid_username(self.username.read(cx).value()),
                            )
                            .on_click(cx.listener(|this, _, _, cx| {
                                this.step = 2;
                                this.scroll.set_offset(gpui::point(px(0.), px(0.)));
                                cx.notify();
                            })),
                    );
            } else {
                body.extend(self.review(cx));
                footer = footer
                    .child(Button::new("iso-back-choices", t!("common-back")).on_click(cx.listener(
                        |this, _, _, cx| {
                            this.step = 1;
                            cx.notify();
                        },
                    )))
                    .child(
                        Button::new("iso-create", t!("iso-create"))
                            .accent()
                            .on_click(cx.listener(|this, _, _, cx| this.start(false, cx))),
                    );
            }
        }
        if self.error {
            let mut error = InfoBar::new(
                Severity::Error,
                t!("iso-failed"),
                if !elevated {
                    t!("elevation-declined")
                } else if self.release_unverified {
                    t!("iso-release-unknown")
                } else if self.stage == Stage::NetworkDrivers {
                    t!("iso-network-failed")
                } else {
                    t!("iso-failed-description")
                },
            )
            .focus_handle(focus.clone());
            if let Some(job) = self.job.clone() {
                error = error.action(
                    Button::new("iso-error-diagnostics", t!("iso-diagnostics"))
                        .on_click(move |_, _, cx| cx.reveal_path(&job)),
                );
            }
            body.insert(0, error.into_any_element());
        }
        if self.cancelled {
            body.insert(
                0,
                InfoBar::new(Severity::Informational, t!("iso-cancelled"), t!("iso-cancelled-description"))
                    .focus_handle(focus.clone())
                    .into_any_element(),
            );
        }
        if !self.error
            && let Some(job) = self.job.clone()
        {
            body.push(
                Button::new("iso-diagnostics", t!("iso-diagnostics"))
                    .hyperlink()
                    .icon(Icon::Diagnostic)
                    .on_click(move |_, _, cx| cx.reveal_path(&job))
                    .into_any_element(),
            );
        }
        page_frame(
            "iso-page",
            Some(t!("iso-title").into()),
            if busy { None } else { Some(&self.model) },
            (&self.scroll, &self.scrollbar),
            body.into_iter()
                .chain(std::iter::once(super::diagnostics_panel(&self.model, cx).into_any_element())),
            Some(footer.into_any_element()),
            cx,
        )
        .into_any_element()
    }
}
