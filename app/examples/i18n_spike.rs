//! Rendering spike: how the pinned GPUI draws RTL, CJK and mixed-script text.
//! Not part of the app; run with `cargo run --example i18n_spike`.

use gpui::{
    App, Bounds, Context, Font, FontFallbacks, FontFeatures, FontStyle, FontWeight, IntoElement,
    ParentElement, Render, Styled, TitlebarOptions, Window, WindowBounds, WindowOptions, div, prelude::*, px,
    rgb, size,
};
#[path = "../src/platform.rs"]
mod platform;
use platform::application;

struct Spike;

const TEXT: &str = "Segoe UI Variable Text";
const DISPLAY: &str = "Segoe UI Variable Display";

fn font(family: &str, fallbacks: Option<Vec<&str>>) -> Font {
    Font {
        family: family.to_owned().into(),
        features: FontFeatures::default(),
        fallbacks: fallbacks
            .map(|list| FontFallbacks::from_fonts(list.into_iter().map(str::to_owned).collect())),
        weight: FontWeight::NORMAL,
        style: FontStyle::Normal,
    }
}

fn row(
    label: &str,
    text: String,
    family: &str,
    fallbacks: Option<Vec<&str>>,
    right: bool,
) -> impl IntoElement {
    div()
        .flex()
        .items_start()
        .gap(px(12.))
        .child(
            div()
                .w(px(150.))
                .flex_shrink_0()
                .text_size(px(11.))
                .text_color(rgb(0x808080))
                .child(label.to_owned()),
        )
        .child(
            div()
                .w(px(420.))
                .border_1()
                .border_color(rgb(0xd0d0d0))
                .px(px(6.))
                .font(font(family, fallbacks))
                .text_size(px(15.))
                .line_height(px(22.))
                .when(right, |this| this.text_right())
                .child(text),
        )
}

impl Render for Spike {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        let arabic = "يستغرق التثبيت حوالي 15 دقيقة، ثم إعادة تشغيل Windows.";
        let arabic_long = "يفحص Atlas هذا الكمبيوتر أولاً: إصدار Windows، والتحديثات المعلقة، وبرامج مكافحة الفيروسات الأخرى. لا يتغير شيء بعد. ثم تختار خياراتك، وتوقف أمان Windows لبضع دقائق.";
        let hebrew = "ההתקנה נמשכת כ-15 דקות, ואז Windows מופעל מחדש.";
        let cjk = "直骨海刃关関關令曜";
        div()
            .size_full()
            .bg(rgb(0xffffff))
            .text_color(rgb(0x1a1a1a))
            .flex()
            .flex_col()
            .gap(px(6.))
            .p(px(16.))
            .child(row("A ar plain", arabic.to_owned(), TEXT, None, false))
            .child(row("B ar RLI..PDI right", format!("\u{2067}{arabic}\u{2069}"), TEXT, None, true))
            .child(row(
                "C ar FSI placeable",
                "أطلس \u{2068}0.6.0\u{2069} متاح الآن.".to_owned(),
                TEXT,
                None,
                true,
            ))
            .child(row("D he plain", hebrew.to_owned(), TEXT, None, false))
            .child(row("E he RLI right", format!("\u{2067}{hebrew}\u{2069}"), TEXT, None, true))
            .child(row("F ar long wrap right", format!("\u{2067}{arabic_long}\u{2069}"), TEXT, None, true))
            .child(row("G ar long wrap plain", arabic_long.to_owned(), TEXT, None, false))
            .child(row("H zh-Hans sysfb", format!("Atlas 未安装在这台电脑上。{cjk}"), TEXT, None, false))
            .child(row("I zh-Hant sysfb", format!("Atlas 尚未安裝在這台電腦上。{cjk}"), TEXT, None, false))
            .child(row(
                "J ja sysfb",
                format!("Atlas はこの PC にインストールされていません。{cjk}"),
                TEXT,
                None,
                false,
            ))
            .child(row(
                "K zh-Hant JhengHei",
                format!("Atlas 尚未安裝在這台電腦上。{cjk}"),
                TEXT,
                Some(vec!["Microsoft JhengHei UI"]),
                false,
            ))
            .child(row(
                "L ja YuGothic",
                format!("Atlas はこの PC にインストールされていません。{cjk}"),
                TEXT,
                Some(vec!["Yu Gothic UI"]),
                false,
            ))
            .child(row(
                "M zh-Hans YaHei",
                format!("Atlas 未安装在这台电脑上。{cjk}"),
                TEXT,
                Some(vec!["Microsoft YaHei UI"]),
                false,
            ))
            .child(row(
                "N ko Malgun",
                format!("Atlas가 이 PC에 설치되어 있지 않습니다. {cjk}"),
                TEXT,
                Some(vec!["Malgun Gothic"]),
                false,
            ))
            .child(row(
                "O latin FSI marks",
                "Atlas \u{2068}0.6.0\u{2069} is available · Zażółć gęślą jaźń · İstanbul · Straße".to_owned(),
                TEXT,
                None,
                false,
            ))
            .child(row(
                "P vi th emoji",
                "Tiếng Việt: cài đặt mất khoảng 15 phút · การติดตั้งใช้เวลาประมาณ 15 นาที · ✓ ⚠ 🚀".to_owned(),
                TEXT,
                None,
                false,
            ))
            .child(row(
                "Q display ar title",
                "\u{2067}تم تثبيت Atlas 0.6.0\u{2069}".to_owned(),
                DISPLAY,
                None,
                true,
            ))
            .child(row("R display zh title", "Atlas 0.6.0 已安装".to_owned(), DISPLAY, None, false))
            .child(row(
                "S ar digits arabic-indic",
                "\u{2067}يتبقى ٣ تحديثات من أصل ١٢\u{2069}".to_owned(),
                TEXT,
                None,
                true,
            ))
    }
}

fn main() {
    application(false).run(|cx: &mut App| {
        let bounds = Bounds::centered(None, size(px(640.), px(760.)), cx);
        cx.open_window(
            WindowOptions {
                window_bounds: Some(WindowBounds::Windowed(bounds)),
                titlebar: Some(TitlebarOptions { title: Some("i18n spike".into()), ..Default::default() }),
                ..Default::default()
            },
            |_, cx| cx.new(|_| Spike),
        )
        .expect("open");
        cx.activate(true);
    });
}
