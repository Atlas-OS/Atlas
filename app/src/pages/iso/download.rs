//! Windows 11 from Microsoft, without a Save dialog: the language Windows
//! shows on this PC and the target PC's architecture, saved to Downloads.
//! A caption says what will be downloaded, and Change opens both choices.

use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use super::*;
use crate::services::windows_iso::{self, Language};
use crate::ui::{ComboBox, ComboItem};

/// Microsoft's Windows 11 download pages, the fallback when its service
/// can't be reached through Atlas.
const WINDOWS_DOWNLOAD: &str = "https://www.microsoft.com/software-download/windows11";
const WINDOWS_DOWNLOAD_ARM64: &str = "https://www.microsoft.com/software-download/windows11arm64";

pub(super) struct IsoDownload {
    /// The language and architecture are shown as choices, not a caption.
    editing: bool,
    arch: Architecture,
    /// The user chose the architecture, so the target PC no longer sets it.
    arch_chosen: bool,
    /// The architecture `languages` belongs to: Microsoft lists each apart.
    loaded_arch: Option<Architecture>,
    languages: Vec<Language>,
    selected: Option<usize>,
    /// The user chose the language, so it's kept when the list loads again.
    language_chosen: bool,
    loading: bool,
    load_failed: bool,
    transfer_failed: bool,
    /// Download was chosen before the languages arrived.
    start_when_loaded: bool,
    cancel: Option<Arc<AtomicBool>>,
    progress: Option<(u64, u64)>,
    /// Windows' display language on this PC, the language to download.
    display_language: Option<String>,
}

impl IsoDownload {
    pub(super) fn new() -> Self {
        Self {
            editing: false,
            arch: iso::host_architecture(),
            arch_chosen: false,
            loaded_arch: None,
            languages: Vec::new(),
            selected: None,
            language_chosen: false,
            loading: false,
            load_failed: false,
            transfer_failed: false,
            start_when_loaded: false,
            cancel: None,
            progress: None,
            display_language: crate::i18n::current_windows_languages()
                .ok()
                .and_then(|languages| languages.into_iter().next()),
        }
    }

    #[cfg(debug_assertions)]
    pub(super) fn preview(&mut self, state: &str) {
        self.arch = Architecture::X64;
        self.loaded_arch = Some(Architecture::X64);
        self.languages = ["English (United States)", "English International", "French", "German"]
            .into_iter()
            .enumerate()
            .map(|(index, label)| Language { id: (index + 1).to_string(), label: label.into() })
            .collect();
        self.selected = Some(1);
        self.editing = state == "download-change";
        self.transfer_failed = state == "download-failed";
        if state == "download-progress" {
            self.cancel = Some(Arc::new(AtomicBool::new(false)));
            self.progress = Some((2_400_000_000, 7_100_000_000));
        }
    }

    pub(super) fn busy(&self) -> bool {
        self.cancel.is_some()
    }

    /// The language to download, as Microsoft names it, once the list is in.
    fn language(&self) -> Option<&Language> {
        self.selected.and_then(|index| self.languages.get(index))
    }
}

impl Drop for IsoDownload {
    fn drop(&mut self) {
        if let Some(cancel) = &self.cancel {
            cancel.store(true, Ordering::Relaxed)
        }
    }
}

/// The names Microsoft may give the Windows 11 download for a display
/// language (a BCP 47 tag), best first. The website passes on Microsoft's
/// list as US English names it.
fn microsoft_names(tag: &str) -> &'static [&'static str] {
    let tag = tag.to_ascii_lowercase();
    let mut parts = tag.split(['-', '_']);
    let language = parts.next().unwrap_or_default();
    let rest: Vec<&str> = parts.collect();
    let has = |part: &str| rest.contains(&part);
    match language {
        "en" if rest.is_empty() || has("us") => &["English (United States)", "English"],
        "en" => &["English International"],
        "pt" if has("br") => &["Brazilian Portuguese", "Portuguese (Brazil)"],
        "pt" => &["Portuguese", "Portuguese (Portugal)"],
        "fr" if has("ca") => &["French Canadian", "French (Canada)"],
        "fr" => &["French"],
        "es" if rest.is_empty() || has("es") => &["Spanish", "Spanish (Spain)"],
        "es" => &["Spanish (Mexico)", "Spanish"],
        "zh" if has("tw") || has("hk") || has("mo") || has("hant") => {
            &["Chinese Traditional", "Chinese (Traditional)"]
        }
        "zh" => &["Chinese Simplified", "Chinese (Simplified)"],
        "sr" => &["Serbian Latin", "Serbian (Latin)", "Serbian"],
        "nb" | "nn" | "no" => &["Norwegian", "Norwegian (Bokmal)", "Norwegian Bokmal"],
        "ar" => &["Arabic"],
        "bg" => &["Bulgarian"],
        "hr" => &["Croatian"],
        "cs" => &["Czech"],
        "da" => &["Danish"],
        "nl" => &["Dutch"],
        "et" => &["Estonian"],
        "fi" => &["Finnish"],
        "de" => &["German"],
        "el" => &["Greek"],
        "he" | "iw" => &["Hebrew"],
        "hu" => &["Hungarian"],
        "it" => &["Italian"],
        "ja" => &["Japanese"],
        "ko" => &["Korean"],
        "lv" => &["Latvian"],
        "lt" => &["Lithuanian"],
        "pl" => &["Polish"],
        "ro" => &["Romanian"],
        "ru" => &["Russian"],
        "sk" => &["Slovak"],
        "sl" => &["Slovenian"],
        "sv" => &["Swedish"],
        "th" => &["Thai"],
        "tr" => &["Turkish"],
        "uk" => &["Ukrainian"],
        _ => &[],
    }
}

/// A language name compared without case, accents or punctuation, so
/// "Chinese (Simplified)" and "Chinese Simplified" match.
fn comparable(name: &str) -> String {
    name.chars()
        .filter(|c| c.is_alphanumeric() || c.is_whitespace())
        .flat_map(char::to_lowercase)
        .map(|c| if c == 'å' { 'a' } else { c })
        .collect::<String>()
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

/// The language in Microsoft's `list` to download for the display language
/// `tag`: its own, else English International, else US English, else the first.
pub(super) fn language_for(tag: Option<&str>, list: &[Language]) -> Option<usize> {
    let find = |names: &[&str]| {
        names.iter().find_map(|name| {
            let name = comparable(name);
            list.iter().position(|language| comparable(&language.label) == name)
        })
    };
    tag.and_then(|tag| find(microsoft_names(tag)))
        .or_else(|| find(&["English International"]))
        .or_else(|| find(&["English (United States)", "English"]))
        .or((!list.is_empty()).then_some(0))
}

/// The Windows ISO's file name: "Win11_EnglishInternational_x64.iso", as
/// Microsoft names its own downloads.
fn download_stem(language: &str, arch: Architecture) -> String {
    let language: String = language.chars().filter(|c| c.is_ascii_alphanumeric()).collect();
    let arch = match arch {
        Architecture::X64 => "x64",
        Architecture::Arm64 => "Arm64",
    };
    if language.is_empty() { format!("Win11_{arch}") } else { format!("Win11_{language}_{arch}") }
}

/// The user's Downloads folder, wherever it was moved to, or the temporary
/// folder when Windows can't say.
fn downloads_folder() -> PathBuf {
    use windows::Win32::System::Com::CoTaskMemFree;
    use windows::Win32::UI::Shell::{FOLDERID_Downloads, KF_FLAG_DEFAULT, SHGetKnownFolderPath};
    // SAFETY: a known folder id; the returned string is freed once read.
    let folder =
        unsafe { SHGetKnownFolderPath(&FOLDERID_Downloads, KF_FLAG_DEFAULT, None) }.ok().and_then(|path| {
            // SAFETY: the string Windows returned, read before it's freed.
            let text = unsafe { path.to_string() }.ok();
            // SAFETY: freed once, with the allocator Windows used.
            unsafe { CoTaskMemFree(Some(path.0.cast())) };
            text
        });
    folder.map(PathBuf::from).filter(|path| path.is_dir()).unwrap_or_else(std::env::temp_dir)
}

fn arch_name(arch: Architecture) -> &'static str {
    match arch {
        Architecture::X64 => "x64",
        Architecture::Arm64 => "arm64",
    }
}

impl IsoPage {
    /// Fetches Microsoft's languages for the download's architecture, once,
    /// so the caption can name the language before the download starts.
    pub(super) fn prefetch_languages(&mut self, cx: &mut Context<Self>) {
        let state = &self.download;
        if state.loading || state.load_failed || state.loaded_arch == Some(state.arch) {
            return;
        }
        self.load_languages(cx);
    }

    fn load_languages(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() || self.download.busy() || self.download.loading {
            return;
        }
        let arch = self.download.arch;
        let previous = self.download.language().map(|language| language.label.clone());
        self.download.loading = true;
        self.download.load_failed = false;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let result =
                cx.background_executor().spawn(async move { windows_iso::languages(arch_name(arch)) }).await;
            this.update(cx, |this, cx| {
                let state = &mut this.download;
                state.loading = false;
                match result {
                    Ok(list) if state.arch == arch => {
                        // A language the user chose stays chosen on the other architecture.
                        state.selected = previous
                            .filter(|_| state.language_chosen)
                            .and_then(|name| list.iter().position(|language| language.label == name))
                            .or_else(|| language_for(state.display_language.as_deref(), &list));
                        state.languages = list;
                        state.loaded_arch = Some(arch);
                        if std::mem::take(&mut state.start_when_loaded) {
                            this.start_download(cx);
                        }
                    }
                    // The architecture changed while the list loaded.
                    Ok(_) => this.load_languages(cx),
                    Err(error) => {
                        log::warn!("Couldn't list Microsoft's Windows languages: {error:#}");
                        state.load_failed = true;
                        if std::mem::take(&mut state.start_when_loaded) {
                            state.transfer_failed = true;
                        }
                    }
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// Sets the download's architecture: the target PC's, unless the user
    /// chose one (`chosen`), and loads that architecture's languages.
    pub(super) fn set_download_arch(&mut self, arch: Architecture, chosen: bool, cx: &mut Context<Self>) {
        let state = &mut self.download;
        if state.busy() || (state.arch_chosen && !chosen) || state.arch == arch {
            state.arch_chosen |= chosen;
            return;
        }
        state.arch = arch;
        state.arch_chosen |= chosen;
        state.load_failed = false;
        state.transfer_failed = false;
        if self.source.is_none() && self.preview.is_none() {
            self.load_languages(cx);
        }
    }

    /// Replaces the Windows ISO with a new download from Microsoft, started
    /// at once with the language and architecture the caption names.
    pub(super) fn download_windows_now(&mut self, cx: &mut Context<Self>) {
        if self.preview.is_some() || self.model.read(cx).locked() || self.model.read(cx).iso_busy {
            return;
        }
        self.source = None;
        self.source_menu = false;
        self.invalidate(cx);
        self.start_download(cx);
    }

    /// Downloads Windows to the Downloads folder under a name no file has
    /// yet, once the languages are known.
    fn start_download(&mut self, cx: &mut Context<Self>) {
        if self.download.busy() || self.model.read(cx).locked() || self.preview.is_some() {
            return;
        }
        self.download.transfer_failed = false;
        self.download.editing = false;
        let arch = self.download.arch;
        let Some(language) =
            self.download.language().filter(|_| self.download.loaded_arch == Some(arch)).cloned()
        else {
            self.download.start_when_loaded = true;
            self.download.load_failed = false;
            self.load_languages(cx);
            return;
        };
        let path = free_name(&downloads_folder(), &download_stem(&language.label, arch), Path::exists);
        let cancel = Arc::new(AtomicBool::new(false));
        self.download.cancel = Some(cancel.clone());
        self.download.progress = None;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let (tx, mut rx) = futures::channel::mpsc::unbounded();
            let target = path.clone();
            let flag = cancel.clone();
            let work = cx.background_executor().spawn(async move {
                windows_iso::download(
                    arch_name(arch),
                    &language.id,
                    &target,
                    || flag.load(Ordering::Relaxed),
                    |done, total| {
                        let _ = tx.unbounded_send((done, total));
                    },
                )
            });
            while let Some(progress) = rx.next().await {
                this.update(cx, |this, cx| {
                    this.download.progress = Some(progress);
                    cx.notify();
                })
                .ok();
            }
            let result = work.await;
            this.update(cx, |this, cx| {
                let cancelled = cancel.load(Ordering::Relaxed);
                this.download.cancel = None;
                this.download.progress = None;
                match result {
                    Ok(()) => this.accept_source(path, cx),
                    Err(error) if !cancelled => {
                        log::warn!("The Windows download didn't finish: {error:#}");
                        this.download.transfer_failed = true;
                    }
                    Err(_) => {}
                }
                cx.notify();
            })
            .ok();
        })
        .detach();
    }

    /// The download as the Windows ISO card offers it: the button and its
    /// caption, the choices behind Change, the transfer, or why it stopped.
    /// `accent` says whether its button is the page's next action.
    pub(super) fn windows_download(&self, accent: bool, cx: &mut Context<Self>) -> AnyElement {
        let theme = cx.theme().clone();
        let state = &self.download;
        let locked = self.model.read(cx).locked();
        let mut panel = div().flex().flex_col().gap(px(8.));
        if state.busy() {
            let fraction = state.progress.map(|(done, total)| done as f32 / total.max(1) as f32);
            panel = panel
                .child(div().type_body().child(detail_text("iso-downloading", t!("iso-downloading"))))
                .child(ProgressBar::new("iso-windows-transfer", t!("iso-downloading"), fraction).live())
                .child(div().type_caption().text_color(theme.text_secondary).child(detail_text(
                    "iso-download-amount",
                    match state.progress {
                        Some((done, total)) => t!(
                            "iso-download-amount",
                            received = describe::file_size(done),
                            total = describe::file_size(total)
                        ),
                        None => self.download_caption(),
                    },
                )))
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
            return panel.into_any_element();
        }
        if state.transfer_failed {
            let message = if state.load_failed {
                t!("iso-download-unreachable")
            } else {
                t!("iso-download-incomplete")
            };
            return panel
                .child(
                    div()
                        .id("iso-download-problem")
                        .role(Role::Status)
                        .aria_label(message.clone())
                        .aria_live(gpui::Live::Polite)
                        .type_body()
                        .text_color(theme.critical)
                        .child(message),
                )
                .child(
                    div().flex().child(
                        Button::new("iso-download-retry", t!("common-try-again"))
                            .when(accent, Button::accent)
                            .disabled(locked)
                            .on_click(cx.listener(|this, _, _, cx| this.start_download(cx))),
                    ),
                )
                .child(
                    link_row()
                        .child(
                            Button::new("iso-download-website", t!("iso-download-website"))
                                .hyperlink()
                                .compact()
                                .trailing_icon(Icon::OpenInNewWindow)
                                .opens(match state.arch {
                                    Architecture::X64 => WINDOWS_DOWNLOAD,
                                    Architecture::Arm64 => WINDOWS_DOWNLOAD_ARM64,
                                }),
                        )
                        .when(!locked, |row| row.child(self.choose_file_link(cx))),
                )
                .into_any_element();
        }
        panel = panel.child(
            div().flex().child(
                Button::new("iso-source-download", t!("iso-download-windows"))
                    .when(accent, Button::accent)
                    .icon(Icon::Download)
                    .disabled(locked)
                    .aria_description(self.download_caption())
                    .on_click(cx.listener(|this, _, _, cx| this.start_download(cx))),
            ),
        );
        if state.editing && !locked {
            panel = panel.child(self.download_choices(locked, cx));
        } else {
            // Change is hidden while another job holds the app, as every
            // Change on the page is while it can't work.
            panel = panel.child(
                div()
                    .flex()
                    .flex_wrap()
                    .items_center()
                    .gap_x(px(6.))
                    .type_caption()
                    .text_color(theme.text_secondary)
                    .child(detail_text("iso-download-caption", self.download_caption()))
                    .when(!locked, |row| {
                        row.child(div().child("·")).child(
                            // The link's own padding stands in for the gap after the dot.
                            div().ml(-crate::ui::COMPACT_INSET).child(
                                Button::new("iso-download-change", t!("common-change"))
                                    .hyperlink()
                                    .compact()
                                    .aria_label(t!("summary-change-a11y", title = t!("iso-download-what")))
                                    .on_click(cx.listener(|this, _, _, cx| {
                                        this.download.editing = true;
                                        cx.notify();
                                    })),
                            ),
                        )
                    }),
            );
        }
        if locked {
            return panel.into_any_element();
        }
        panel.child(link_row().child(self.choose_file_link(cx))).into_any_element()
    }

    fn choose_file_link(&self, cx: &mut Context<Self>) -> Button {
        Button::new("iso-source-local", t!("iso-use-local"))
            .compact()
            .hyperlink()
            .on_click(cx.listener(|this, _, _, cx| this.pick(Field::Source, cx)))
    }

    /// "Windows 11 · English International · x64": what Download gets.
    fn download_caption(&self) -> String {
        let architecture = architecture_text(self.download.arch);
        match self.download.language().filter(|_| self.download.loaded_arch == Some(self.download.arch)) {
            Some(language) => {
                t!("iso-download-caption", language = language.label.as_str(), architecture = architecture)
            }
            None => t!("iso-download-caption-loading", architecture = architecture),
        }
    }

    /// The language and architecture as choices, side by side, each under
    /// its label.
    fn download_choices(&self, locked: bool, cx: &mut Context<Self>) -> AnyElement {
        let state = &self.download;
        let theme = cx.theme().clone();
        let field = |key: &str, label: String, control: AnyElement, width: f32| {
            div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .w(px(width))
                .max_w_full()
                .child(div().type_body().text_color(theme.text_primary).child(detail_text(key, label)))
                .child(control)
        };
        let language = {
            let owner = cx.weak_entity();
            let control = if state.languages.is_empty() {
                div()
                    .type_body()
                    .text_color(theme.text_secondary)
                    .child(detail_text(
                        "iso-download-languages",
                        if state.loading {
                            t!("iso-download-languages")
                        } else {
                            t!("iso-download-unreachable")
                        },
                    ))
                    .into_any_element()
            } else {
                ComboBox::new("iso-download-language", t!("iso-download-language"))
                    .items(state.languages.iter().map(|language| ComboItem::new(language.label.clone())))
                    .selected(state.selected)
                    .disabled(locked)
                    .on_select(move |index, _, cx| {
                        owner
                            .update(cx, |this, cx| {
                                this.download.selected = Some(index);
                                this.download.language_chosen = true;
                                cx.notify();
                            })
                            .ok();
                    })
                    .into_any_element()
            };
            field("iso-download-language-label", t!("iso-download-language"), control, 260.)
        };
        let arch = {
            let owner = cx.weak_entity();
            let control = ComboBox::new("iso-download-arch", t!("iso-download-arch"))
                .items([
                    ComboItem::new(t!("iso-architecture-x64")),
                    ComboItem::new(t!("iso-architecture-arm64")),
                ])
                .selected(Some(usize::from(state.arch == Architecture::Arm64)))
                .disabled(locked || state.loading)
                .on_select(move |index, _, cx| {
                    owner
                        .update(cx, |this, cx| {
                            let arch = if index == 1 { Architecture::Arm64 } else { Architecture::X64 };
                            this.set_download_arch(arch, true, cx);
                            cx.notify();
                        })
                        .ok();
                })
                .into_any_element();
            field("iso-download-arch-label", t!("iso-download-arch"), control, 160.)
        };
        div().flex().flex_wrap().gap(px(12.)).child(language).child(arch).into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn list(labels: &[&str]) -> Vec<Language> {
        labels
            .iter()
            .enumerate()
            .map(|(index, label)| Language { id: index.to_string(), label: (*label).to_owned() })
            .collect()
    }

    #[test]
    fn the_download_follows_the_display_language() {
        let microsoft = list(&[
            "Arabic",
            "Brazilian Portuguese",
            "Chinese (Simplified)",
            "Chinese (Traditional)",
            "English (United States)",
            "English International",
            "French",
            "French Canadian",
            "German",
            "Norwegian",
            "Portuguese",
            "Spanish",
            "Spanish (Mexico)",
        ]);
        let label =
            |tag: Option<&str>| language_for(tag, &microsoft).map(|index| microsoft[index].label.as_str());
        assert_eq!(label(Some("en-GB")), Some("English International"));
        assert_eq!(label(Some("en-US")), Some("English (United States)"));
        assert_eq!(label(Some("en")), Some("English (United States)"));
        assert_eq!(label(Some("pt-BR")), Some("Brazilian Portuguese"));
        assert_eq!(label(Some("pt-PT")), Some("Portuguese"));
        assert_eq!(label(Some("fr-CA")), Some("French Canadian"));
        assert_eq!(label(Some("fr-BE")), Some("French"));
        assert_eq!(label(Some("es-ES")), Some("Spanish"));
        assert_eq!(label(Some("es-AR")), Some("Spanish (Mexico)"));
        assert_eq!(label(Some("zh-Hant-TW")), Some("Chinese (Traditional)"));
        assert_eq!(label(Some("zh-CN")), Some("Chinese (Simplified)"));
        assert_eq!(label(Some("nb-NO")), Some("Norwegian"));
        assert_eq!(label(Some("de-AT")), Some("German"));
        // No ISO in the display language, or none known: English International.
        assert_eq!(label(Some("hi-IN")), Some("English International"));
        assert_eq!(label(None), Some("English International"));
        // Microsoft's spelling without brackets matches too.
        assert_eq!(language_for(Some("zh-TW"), &list(&["Chinese Traditional"])), Some(0));
        assert_eq!(language_for(Some("de-DE"), &list(&["Japanese"])), Some(0), "the first as a last resort");
        assert_eq!(language_for(Some("de-DE"), &[]), None);
    }

    #[test]
    fn a_download_is_named_as_microsoft_names_its_own() {
        assert_eq!(
            download_stem("English International", Architecture::X64),
            "Win11_EnglishInternational_x64"
        );
        assert_eq!(
            download_stem("Chinese (Simplified)", Architecture::Arm64),
            "Win11_ChineseSimplified_Arm64"
        );
        assert_eq!(download_stem("", Architecture::X64), "Win11_x64");
    }
}
