//! The package to install: the release check, and an Atlas package
//! downloaded, opened from a file or unpacked from a tester build.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant};

use futures::StreamExt;
use futures::channel::mpsc::UnboundedSender;
use gpui::{Context, PathPromptOptions};

use super::{AppModel, Generation, Step};
use crate::services::iso;
use crate::services::playbook::{self, Manifest, PageKind};
use crate::services::releases::{self, Release};
use crate::t;

#[derive(Clone, Debug)]
pub enum ReleaseCheck {
    NotChecked,
    Checking,
    Ready { release: Release },
    Failed,
}

impl ReleaseCheck {
    pub fn release(&self) -> Option<&Release> {
        match self {
            ReleaseCheck::Ready { release } => Some(release),
            _ => None,
        }
    }
}

#[derive(Clone, Debug)]
pub enum Acquisition {
    Idle,
    Downloading { received: u64, total: u64 },
    Extracting { done: usize, total: usize },
    Failed(AcquireProblem),
}

/// Why the package could not be made ready. Worded when rendered.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AcquireProblem {
    /// The release has no .apbx asset.
    NoPlaybookAsset { version: String },
    /// The package is older than the first one this app can install.
    Unsupported { version: String },
    /// The package is recent enough to include `Install-Atlas.ps1` but does not.
    Incomplete { version: String },
    /// The download stopped receiving data.
    Stalled,
    /// Anything else, with the raw error chain as a diagnostic.
    Other { error: String },
}

impl Acquisition {
    pub fn is_busy(&self) -> bool {
        matches!(self, Acquisition::Downloading { .. } | Acquisition::Extracting { .. })
    }
}

#[derive(Clone, Debug)]
pub enum Origin {
    Release(String),
    LocalFile(PathBuf),
    /// Unpacked earlier and picked up again after a relaunch.
    Unpacked,
    /// The Atlas package built into a tester build.
    Bundled,
}

/// A prepared package: an immutable directory whose name carries the
/// package's version and content digest (see [`playbook::extract_into`]),
/// so the manifest read from it describes the files that will run.
#[derive(Clone, Debug)]
pub struct PlaybookSource {
    pub dir: PathBuf,
    pub manifest: Manifest,
    pub origin: Origin,
    /// The Atlas package file (.apbx) it was unpacked from: the download, or
    /// the file opened. ISO creation offers it, so a first-time user who
    /// never handled the file can still make an ISO from it.
    pub archive: Option<PathBuf>,
}

impl PlaybookSource {
    /// Where the package came from, in the current language.
    pub fn describe(&self) -> String {
        match &self.origin {
            Origin::Release(version) => t!("package-from-release", version = version),
            Origin::LocalFile(path) => {
                t!("package-from-file", version = &self.manifest.version, file = releases::file_name(path))
            }
            Origin::Unpacked => t!("package-unpacked", version = &self.manifest.version),
            Origin::Bundled => t!("package-bundled", version = &self.manifest.version),
        }
    }
}

enum Progress {
    Download(u64, u64),
    Extract(usize, usize),
}

/// How long a package download may receive nothing before it is abandoned.
const DOWNLOAD_STALL: Duration = if cfg!(test) { Duration::from_secs(2) } else { Duration::from_secs(60) };
/// The longest a download goes without reporting progress while data
/// arrives, so a slow download is not taken for a stalled one.
const PROGRESS_HEARTBEAT: Duration = Duration::from_secs(1);

/// Whether an unpacked directory holds the Atlas package built into this
/// tester build. Never true in other builds.
pub(super) fn bundled_holds(dir: &Path) -> bool {
    #[cfg(feature = "embedded-playbook")]
    {
        crate::services::embedded::holds(dir)
    }
    #[cfg(not(feature = "embedded-playbook"))]
    {
        let _ = dir;
        false
    }
}

impl AppModel {
    /// Whether `release` could finish the unfinished install, if one is waiting.
    fn release_finishes_resume(&self, release: &Release) -> bool {
        self.resume_target().is_none_or(|target| target == release.version())
    }

    /// A tester build: the bundled Atlas package is the only one on offer.
    pub fn bundled(&self) -> bool {
        self.env.embedded_startup
    }

    /// The manifest that describes the install: the loaded package's, or the
    /// one built into this app until a package is available.
    pub fn manifest(&self) -> &Manifest {
        self.playbook.as_ref().map(|p| &p.manifest).unwrap_or(&self.builtin_manifest)
    }

    /// A release newer than what is installed, if the check has run.
    pub fn update_available(&self) -> Option<&Release> {
        let release = self.release.release()?;
        let installed = self.installed_version()?;
        releases::compare_versions(release.version(), installed).is_gt().then_some(release)
    }

    /// The update Home offers: none while no install can start from Home,
    /// while an unfinished install waits for a different version, or when
    /// the release predates the first one this app can install.
    pub fn offered_update(&self) -> Option<&Release> {
        if self.start_block().is_some() {
            return None;
        }
        self.update_available().filter(|release| {
            self.release_finishes_resume(release) && !playbook::predates_front_door(release.version())
        })
    }

    /// The latest release is older than the first one this app can install.
    pub fn latest_predates_app(&self) -> bool {
        self.release.release().is_some_and(|release| playbook::predates_front_door(release.version()))
    }

    /// Avoid replacing a loaded preview package with an older public
    /// release, or downloading one that can't finish an unfinished install.
    pub fn can_download_latest(&self) -> bool {
        self.release.release().is_some_and(|release| {
            self.release_finishes_resume(release)
                && self.playbook.as_ref().is_none_or(|package| {
                    !releases::compare_versions(release.version(), &package.manifest.version).is_lt()
                })
        })
    }

    /// Whether Get ready offers the latest release: when it can be
    /// downloaded, or while there is no package and no known release that
    /// an unfinished install rules out.
    pub fn offers_download(&self) -> bool {
        self.can_download_latest()
            || (self.playbook.is_none()
                && self.release.release().is_none_or(|release| self.release_finishes_resume(release)))
    }

    pub fn check_for_updates(&mut self, cx: &mut Context<Self>) {
        if self.bundled() {
            // A tester build installs only its bundled package and never
            // asks GitHub what is newest.
            return;
        }
        self.refresh_atlas_state();
        if matches!(self.release, ReleaseCheck::Checking) {
            return;
        }
        self.release = ReleaseCheck::Checking;
        cx.notify();
        let fetch = self.env.adapters.fetch_release.clone();
        cx.spawn(async move |this, cx| {
            let result = cx.background_executor().spawn(async move { fetch() }).await;
            this.update(cx, |this, cx| {
                this.release = match result {
                    Ok(release) => ReleaseCheck::Ready { release },
                    Err(error) => {
                        log::warn!("release check failed: {error:#}");
                        ReleaseCheck::Failed
                    }
                };
                // The flow may have started before the release was known, or
                // a Download chosen elsewhere waited for the check.
                let requested = std::mem::take(&mut this.download_requested);
                if (this.flow.active && this.flow.step == Step::Ready && this.playbook.is_none()) || requested
                {
                    this.acquire_latest(cx);
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// The Download button: the latest release, or first a new release check
    /// when the last one failed, whose completion starts the download.
    pub fn download_latest(&mut self, cx: &mut Context<Self>) {
        match self.release {
            ReleaseCheck::Ready { .. } => self.acquire_latest(cx),
            // The check under way starts the download when it ends.
            ReleaseCheck::Checking => self.download_requested = true,
            ReleaseCheck::NotChecked | ReleaseCheck::Failed => {
                self.download_requested = true;
                self.check_for_updates(cx);
            }
        }
        cx.notify();
    }

    /// Downloads the latest Atlas package (or reuses a verified cached copy)
    /// and unpacks it so it can be installed.
    pub fn acquire_latest(&mut self, cx: &mut Context<Self>) {
        if self.bundled()
            || self.locked()
            || self.acquisition.is_busy()
            || !self.flow.may_edit()
            || !self.can_download_latest()
        {
            return;
        }
        // `can_download_latest` is false until the release is known.
        let Some(release) = self.release.release().cloned() else { return };
        if self.latest_predates_app() {
            // Its version already says this app cannot install it.
            self.acquisition =
                Acquisition::Failed(AcquireProblem::Unsupported { version: release.version().to_owned() });
            cx.notify();
            return;
        }
        let Some(asset) = release.playbook_asset().cloned() else {
            self.acquisition = Acquisition::Failed(AcquireProblem::NoPlaybookAsset {
                version: release.version().to_owned(),
            });
            cx.notify();
            return;
        };
        let version = release.version().to_owned();
        let downloads = self.env.paths.downloads();
        let playbooks = self.env.paths.playbooks();
        self.acquisition = Acquisition::Downloading { received: 0, total: asset.size };
        let generation = self.acquisition_generation.next();
        let cancel = Arc::new(AtomicBool::new(false));
        self.acquisition_cancel = cancel.clone();
        self.download_heard = Instant::now();
        self.watch_download(generation, cx);
        cx.notify();

        self.acquisition_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded::<Progress>();
            let task = cx.background_executor().spawn(async move {
                let cancelled = || cancel.load(Ordering::Relaxed);
                let path = match releases::cached_in(&downloads, &asset) {
                    Some(path) => path,
                    None => {
                        let mut last_percent = u64::MAX;
                        let mut last_sent = Instant::now();
                        releases::download_into(&downloads, &asset, cancelled, |received, total| {
                            let percent = received * 100 / total.max(1);
                            if percent != last_percent || last_sent.elapsed() >= PROGRESS_HEARTBEAT {
                                last_percent = percent;
                                last_sent = Instant::now();
                                let _ = tx.unbounded_send(Progress::Download(received, total));
                            }
                        })?
                    }
                };
                anyhow::ensure!(!cancelled(), "the download was cancelled");
                extract_reporting(&path, &playbooks, &tx).map(|(dir, manifest)| (dir, manifest, path))
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    if this.acquisition_generation != generation {
                        return;
                    }
                    this.acquisition = match progress {
                        Progress::Download(received, total) => {
                            this.download_heard = Instant::now();
                            Acquisition::Downloading { received, total }
                        }
                        Progress::Extract(done, total) => Acquisition::Extracting { done, total },
                    };
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                this.finish_acquisition(
                    generation,
                    result.map(|(dir, manifest, path)| (dir, manifest, Origin::Release(version), Some(path))),
                    cx,
                );
            })
            .ok();
        }));
    }

    /// Gives up on download `generation` once it has received nothing for
    /// [`DOWNLOAD_STALL`]. Its transfer, blocked in a read, stops when that
    /// read returns or its own timeout ends it; nothing it produces is
    /// applied.
    fn watch_download(&self, generation: Generation, cx: &mut Context<Self>) {
        cx.spawn(async move |this, cx| {
            loop {
                cx.background_executor().timer(DOWNLOAD_STALL / 4).await;
                let watching = this
                    .update(cx, |this, cx| {
                        if this.acquisition_generation != generation
                            || !matches!(this.acquisition, Acquisition::Downloading { .. })
                        {
                            return false;
                        }
                        if this.download_heard.elapsed() < DOWNLOAD_STALL {
                            return true;
                        }
                        log::warn!(
                            "The package download received nothing for {DOWNLOAD_STALL:?}; stopping it"
                        );
                        this.cancel_acquisition();
                        this.acquisition = Acquisition::Failed(AcquireProblem::Stalled);
                        cx.notify();
                        false
                    })
                    .unwrap_or(false);
                if !watching {
                    break;
                }
            }
        })
        .detach();
    }

    /// Stops a download the user no longer wants (see [`AppModel::cancel_acquisition`]).
    pub fn cancel_download(&mut self, cx: &mut Context<Self>) {
        if matches!(self.acquisition, Acquisition::Downloading { .. }) {
            self.cancel_acquisition();
            cx.notify();
        }
    }

    /// Unpacks the Atlas package built into a tester build: written to the
    /// downloads folder on a worker, then loaded like any other file. Waits
    /// for startup recovery, which retries this once it knows nothing else
    /// is running. A no-op in other builds.
    pub fn load_bundled_package(&mut self, cx: &mut Context<Self>) {
        #[cfg(feature = "embedded-playbook")]
        {
            if self.recovering || self.locked() || self.acquisition.is_busy() || !self.flow.may_edit() {
                return;
            }
            let paths = self.env.paths.clone();
            self.acquisition = Acquisition::Extracting { done: 0, total: 0 };
            let generation = self.acquisition_generation.next();
            cx.notify();
            self.acquisition_task = Some(cx.spawn(async move |this, cx| {
                let result = cx
                    .background_executor()
                    .spawn(async move { crate::services::embedded::materialize(&paths) })
                    .await;
                this.update(cx, |this, cx| {
                    if this.acquisition_generation != generation {
                        return;
                    }
                    this.acquisition_task = None;
                    match result {
                        Ok(path) => {
                            this.acquisition = Acquisition::Idle;
                            this.load_playbook_file(path, cx);
                        }
                        Err(error) => {
                            log::error!("Could not write the bundled package: {error:#}");
                            this.acquisition =
                                Acquisition::Failed(AcquireProblem::Other { error: format!("{error:#}") });
                            cx.notify();
                        }
                    }
                })
                .ok();
            }));
        }
        #[cfg(not(feature = "embedded-playbook"))]
        {
            let _ = cx;
        }
    }

    /// Whether "Open package file" can act: the flow may change and no
    /// package is being unpacked. A download under way gives way to a
    /// chosen file.
    pub fn may_choose_playbook(&self) -> bool {
        !self.locked() && self.flow.may_edit() && !matches!(self.acquisition, Acquisition::Extracting { .. })
    }

    /// Lets the user pick an .apbx they already have. A download under way
    /// carries on until a file is actually chosen, then gives way to it.
    pub fn choose_local_playbook(&mut self, cx: &mut Context<Self>) {
        if !self.may_choose_playbook() {
            return;
        }
        let receiver = cx.prompt_for_paths(PathPromptOptions {
            files: true,
            directories: false,
            multiple: false,
            prompt: Some(t!("file-dialog-open-package").into()),
        });
        cx.spawn(async move |this, cx| {
            let Ok(Ok(Some(paths))) = receiver.await else { return };
            let Some(path) = paths.into_iter().next() else { return };
            this.update(cx, |this, cx| {
                // The chosen file replaces whatever was still being prepared.
                if this.acquisition.is_busy() && !this.locked() && this.flow.may_edit() {
                    this.cancel_acquisition();
                }
                this.load_playbook_file(path, cx)
            })
            .ok();
        })
        .detach();
    }

    /// Unpacks an .apbx the user already has (file dialog, `--playbook`, or
    /// "Open with" on the package).
    pub fn load_playbook_file(&mut self, path: PathBuf, cx: &mut Context<Self>) {
        log::info!("Opening package: {}", path.display());
        if self.locked() || self.acquisition.is_busy() || !self.flow.may_edit() {
            return;
        }
        let playbooks = self.env.paths.playbooks();
        self.acquisition = Acquisition::Extracting { done: 0, total: 0 };
        let generation = self.acquisition_generation.next();
        cx.notify();
        self.acquisition_task = Some(cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded::<Progress>();
            let source = path.clone();
            let task =
                cx.background_executor().spawn(async move { extract_reporting(&source, &playbooks, &tx) });
            while let Some(Progress::Extract(done, total)) = rx.next().await {
                this.update(cx, |this, cx| {
                    if this.acquisition_generation != generation {
                        return;
                    }
                    this.acquisition = Acquisition::Extracting { done, total };
                    cx.notify();
                })
                .ok();
            }
            let result = task.await;
            this.update(cx, |this, cx| {
                this.finish_acquisition(
                    generation,
                    result.map(|(dir, manifest)| {
                        // A tester build's own package needs no file: ISO creation adds it.
                        if bundled_holds(&dir) {
                            (dir, manifest, Origin::Bundled, None)
                        } else {
                            (dir, manifest, Origin::LocalFile(path.clone()), Some(path))
                        }
                    }),
                    cx,
                );
            })
            .ok();
        }));
    }

    /// Stops an acquisition and forgets it. A download stops at its next
    /// chunk and removes its partial file; an extraction already under way
    /// on a worker runs to its end on its own. Nothing either produces is
    /// applied.
    pub(super) fn cancel_acquisition(&mut self) {
        self.acquisition_cancel.store(true, Ordering::Relaxed);
        self.acquisition_task = None;
        self.acquisition_generation.next();
        if self.acquisition.is_busy() {
            self.acquisition = Acquisition::Idle;
        }
    }

    fn finish_acquisition(
        &mut self,
        generation: Generation,
        result: anyhow::Result<(PathBuf, Manifest, Origin, Option<PathBuf>)>,
        cx: &mut Context<Self>,
    ) {
        if generation != self.acquisition_generation {
            return;
        }
        self.acquisition_task = None;
        if self.flow.locked() {
            // An install is running with the package it was given.
            self.acquisition = Acquisition::Idle;
            cx.notify();
            return;
        }
        match result {
            Ok((dir, manifest, origin, archive)) => {
                // Keep the user's choices that still exist; fill the rest with defaults.
                let valid: BTreeSet<String> =
                    manifest.pages.iter().flat_map(|p| p.options.iter().map(|o| o.name.clone())).collect();
                let mut options: BTreeSet<String> =
                    self.options.iter().filter(|o| valid.contains(*o)).cloned().collect();
                for page in &manifest.pages {
                    let has_choice = page.options.iter().any(|o| options.contains(&o.name));
                    if page.kind == PageKind::Radio
                        && !has_choice
                        && let Some(default) = page.options.iter().find(|o| o.default)
                    {
                        options.insert(default.name.clone());
                    }
                }
                self.options = options;
                if let Some(saved) = self.iso_initial_options.take() {
                    if iso::validate_options(&manifest, &saved).is_ok() {
                        self.options = saved.into_iter().collect();
                    } else {
                        log::warn!(
                            "The staged Atlas options do not match the selected package; using the normal options flow."
                        );
                    }
                }
                log::info!(
                    "Package ready: version={}; identity={:?}",
                    manifest.version,
                    playbook::identity(&dir)
                );
                self.playbook = Some(PlaybookSource { dir, manifest, origin, archive });
                self.acquisition = Acquisition::Idle;
                // Supported builds may differ between packages.
                if self.flow.active {
                    self.run_checks(cx);
                } else {
                    self.checks.clear();
                    self.check_tasks.clear();
                }
                self.save_draft(cx);
            }
            Err(error) => {
                log::error!("Package acquisition failed: {error:#}");
                let problem = if let Some(unsupported) = error.downcast_ref::<playbook::Unsupported>() {
                    AcquireProblem::Unsupported { version: unsupported.version.clone() }
                } else if let Some(incomplete) = error.downcast_ref::<playbook::Incomplete>() {
                    AcquireProblem::Incomplete { version: incomplete.version.clone() }
                } else {
                    AcquireProblem::Other { error: format!("{error:#}") }
                };
                self.acquisition = Acquisition::Failed(problem);
            }
        }
        cx.notify();
    }
}

/// Unpacks the package at `path` under `playbooks`, sending its progress on
/// `tx` once per whole percent.
fn extract_reporting(
    path: &Path,
    playbooks: &Path,
    tx: &UnboundedSender<Progress>,
) -> anyhow::Result<(PathBuf, Manifest)> {
    let mut last_percent = usize::MAX;
    playbook::extract_into(path, playbooks, |done, total| {
        let percent = done * 100 / total.max(1);
        if percent != last_percent {
            last_percent = percent;
            let _ = tx.unbounded_send(Progress::Extract(done, total));
        }
    })
}
