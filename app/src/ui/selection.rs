//! RadioGroup and CheckBox, drawn to the Windows 11 spec (20px glyphs, 4px
//! corners on the check box, accent fill when selected, a grey fill when
//! selected but disabled).
//!
//! A radio group is one tab stop: Tab lands on the selected option and the
//! arrow keys move the selection, as in Windows Settings. Each control
//! carries its accessible role, name and checked state.
//!
//! A disabled row greys out its label, glyph and description. An option that
//! is disabled for a reason its description gives, such as a drive that's
//! too small, keeps that description readable with
//! [`RadioItem::readable_description`].

use std::collections::HashMap;
use std::rc::Rc;

use gpui::{
    AnyElement, App, ClickEvent, ElementId, FocusHandle, Hsla, ImageSource, IntoElement, ParentElement,
    Pixels, RenderOnce, Role, SharedString, Styled, Toggled, Window, div, prelude::*, px,
};

use super::actions::{RadioNext, RadioPrevious};
use super::text_input::error_caption;
use super::typography::CapCenteredText;
use super::{
    ClickHandler, Icon, Revealed, TextMark, Typography, focus_ring, icon_sized, on_activate, pointer_hover,
};
use crate::theme::{ActiveTheme, Theme};

type SelectHandler = Rc<dyn Fn(usize, &mut Window, &mut App)>;

/// Focus handles that persist across frames, keyed by a stable name, so
/// pages can move keyboard focus to controls they render.
#[derive(Default)]
pub struct FocusHandles {
    handles: HashMap<String, FocusHandle>,
}

impl FocusHandles {
    pub fn get(&mut self, key: &str, cx: &mut App) -> FocusHandle {
        if let Some(handle) = self.handles.get(key) {
            return handle.clone();
        }
        let handle = cx.focus_handle();
        self.handles.insert(key.to_owned(), handle.clone());
        handle
    }
}

pub struct RadioItem {
    pub id: ElementId,
    pub label: SharedString,
    pub description: Option<SharedString>,
    pub focus: FocusHandle,
    pub leading_icon: Option<Icon>,
    pub image: Option<std::path::PathBuf>,
    /// Shown but unavailable, with its description saying why: Tab and the
    /// arrow keys pass over it.
    pub disabled: bool,
    /// See [`RadioItem::readable_description`].
    pub readable_description: bool,
}

impl RadioItem {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, focus: FocusHandle) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            description: None,
            focus,
            leading_icon: None,
            image: None,
            disabled: false,
            readable_description: false,
        }
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    /// Keeps the description in the secondary text colour while the item is
    /// disabled, so a reason such as "Too small" stays readable (4.5:1 or
    /// more); the label and glyph still grey out. For a description that
    /// says why the option can't be chosen. Without it, a disabled item's
    /// description greys out with the rest of the row.
    pub fn readable_description(mut self) -> Self {
        self.readable_description = true;
        self
    }

    pub fn icon(mut self, icon: Icon) -> Self {
        self.leading_icon = Some(icon);
        self
    }

    pub fn image(mut self, path: std::path::PathBuf) -> Self {
        self.image = Some(path);
        self
    }

    pub fn description(mut self, text: impl Into<SharedString>) -> Self {
        self.description = Some(text.into());
        self
    }
}

#[derive(IntoElement)]
pub struct RadioGroup {
    id: ElementId,
    label: SharedString,
    items: Vec<RadioItem>,
    selected: Option<usize>,
    disabled: bool,
    on_select: Option<SelectHandler>,
}

impl RadioGroup {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            items: Vec::new(),
            selected: None,
            disabled: false,
            on_select: None,
        }
    }

    pub fn items(mut self, items: impl IntoIterator<Item = RadioItem>) -> Self {
        self.items.extend(items);
        self
    }

    pub fn selected(mut self, index: Option<usize>) -> Self {
        self.selected = index;
        self
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    pub fn on_select(mut self, handler: impl Fn(usize, &mut Window, &mut App) + 'static) -> Self {
        self.on_select = Some(Rc::new(handler));
        self
    }
}

/// The index an arrow key moves to, wrapping at the ends.
fn step_index(current: usize, len: usize, forward: bool) -> usize {
    if len == 0 {
        return 0;
    }
    if forward { (current + 1) % len } else { (current + len - 1) % len }
}

/// The next option an arrow key reaches from `current`, passing over
/// unavailable ones; `current` itself when no other option is available.
fn step_available(current: usize, available: &[bool], forward: bool) -> usize {
    let mut next = current;
    for _ in 0..available.len() {
        next = step_index(next, available.len(), forward);
        if available[next] {
            return next;
        }
    }
    current
}

impl RenderOnce for RadioGroup {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let disabled = self.disabled;
        let selected = self.selected;
        let on_select = self.on_select.clone();
        let available: Vec<bool> = self.items.iter().map(|item| !disabled && !item.disabled).collect();
        // Tab lands on the selected option only, or the first available one;
        // arrows reach the rest.
        let tab_stop_index = selected.or_else(|| available.iter().position(|&available| available));
        let handles: Vec<FocusHandle> = self
            .items
            .iter()
            .enumerate()
            .map(|(index, item)| {
                item.focus.clone().tab_index(0).tab_stop(available[index] && Some(index) == tab_stop_index)
            })
            .collect();

        let mover = |forward: bool| {
            let items: Vec<FocusHandle> = handles.clone();
            let available = available.clone();
            let on_select = on_select.clone();
            move |window: &mut Window, cx: &mut App| {
                let current = items.iter().position(|h| h.is_focused(window)).or(selected).unwrap_or(0);
                let next = step_available(current, &available, forward);
                if let Some(handle) = items.get(next).filter(|_| available[next]) {
                    window.focus(handle, cx);
                    super::focus_reveal::request(window, cx);
                    if let Some(on_select) = &on_select {
                        on_select(next, window, cx);
                    }
                }
            }
        };
        let next = mover(true);
        let previous = mover(false);

        let mut group = div()
            .id(self.id)
            .role(Role::RadioGroup)
            .aria_label(self.label)
            .key_context("RadioGroup")
            // The glyphs line up with the text above, as Fluent aligns a
            // control with its column: each row's padding and border move
            // into the margin (see `ROW_INSET`).
            .ml(-ROW_INSET)
            .flex()
            .flex_col()
            .gap(px(2.))
            .when(!disabled, |this| {
                this.on_action(move |_: &RadioNext, window, cx| next(window, cx))
                    .on_action(move |_: &RadioPrevious, window, cx| previous(window, cx))
            });

        let control_fill = theme.control_fill;
        let (stroke, stroke_disabled) = (theme.control_strong_stroke, theme.control_strong_stroke_disabled);
        let (enabled_mark, disabled_mark) = (Checked::of(theme, true), Checked::of(theme, false));
        // The dot is a touch softer than the check box's tick in dark mode.
        let dot_opacity = if theme.is_dark() && !theme.high_contrast { 0.9 } else { 1. };

        for (index, item) in self.items.into_iter().enumerate() {
            let is_selected = selected == Some(index);
            let stroke = if available[index] { stroke } else { stroke_disabled };
            let glyph = if is_selected {
                // A filled disc with a centre dot.
                let Checked { fill, mark, outline } =
                    if available[index] { enabled_mark } else { disabled_mark };
                div()
                    .size(px(20.))
                    .rounded_full()
                    .bg(fill)
                    .when_some(outline, |this, colour| this.border_1().border_color(colour))
                    .flex()
                    .items_center()
                    .justify_center()
                    .child(div().size(px(8.)).rounded_full().bg(mark.opacity(dot_opacity)))
            } else {
                div().size(px(20.)).rounded_full().bg(control_fill).border_1().border_color(stroke)
            };
            let handler: Option<ClickHandler> = on_select.clone().map(|on_select| {
                Rc::new(move |_: &ClickEvent, window: &mut Window, cx: &mut App| on_select(index, window, cx))
                    as ClickHandler
            });
            let decoration = item
                .image
                .map(|path| decorative_image(path, px(26.), px(-3.)))
                .or_else(|| item.leading_icon.map(|icon| icon_sized(icon, 20.).into_any_element()));
            group = group.child(selectable_row(
                item.id,
                Role::RadioButton,
                is_selected,
                Some(handles[index].clone()),
                glyph,
                decoration,
                item.label,
                item.description,
                None,
                !available[index],
                item.readable_description,
                handler,
                window,
                cx,
            ));
        }
        group
    }
}

/// A logo `size` square in a 20px-tall slot beside an option, `top` from the
/// slot's top. Decorative: the control carries the accessible name.
fn decorative_image(source: impl Into<ImageSource>, size: Pixels, top: Pixels) -> AnyElement {
    div()
        .relative()
        .w(size)
        .h(px(20.))
        .flex_shrink_0()
        .child(gpui::img(source).id("logo").aria_label("").absolute().top(top).size(size))
        .into_any_element()
}

#[derive(IntoElement)]
pub struct CheckBox {
    id: ElementId,
    label: SharedString,
    description: Option<SharedString>,
    image: Option<SharedString>,
    checked: bool,
    disabled: bool,
    focus: Option<FocusHandle>,
    error: Option<SharedString>,
    on_toggle: Option<ClickHandler>,
}

impl CheckBox {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, checked: bool) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            description: None,
            image: None,
            checked,
            disabled: false,
            focus: None,
            error: None,
            on_toggle: None,
        }
    }

    pub fn description(mut self, text: impl Into<SharedString>) -> Self {
        self.description = Some(text.into());
        self
    }

    pub fn image(mut self, asset: impl Into<SharedString>) -> Self {
        self.image = Some(asset.into());
        self
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    /// A handle the page keeps, so it can move focus to the box: to the one
    /// a form needs ticked, for example.
    pub fn focus_handle(mut self, handle: FocusHandle) -> Self {
        self.focus = Some(handle);
        self
    }

    /// What is wrong, or `None`: a critical caption under the label, which
    /// the box reads out as its description, as a text box's error does.
    /// Write it as the fix: "Confirm you agree to send this report."
    pub fn error(mut self, error: Option<SharedString>) -> Self {
        self.error = error;
        self
    }

    pub fn on_toggle(mut self, handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static) -> Self {
        self.on_toggle = Some(Rc::new(handler));
        self
    }
}

impl RenderOnce for CheckBox {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let decoration = self.image.map(|asset| decorative_image(asset, px(20.), px(0.)));
        let glyph = if self.checked {
            let Checked { fill, mark, outline } = Checked::of(theme, !self.disabled);
            div()
                .size(px(20.))
                .rounded(px(4.))
                .bg(fill)
                .when_some(outline, |this, colour| this.border_1().border_color(colour))
                .flex()
                .items_center()
                .justify_center()
                .text_color(mark)
                .child(icon_sized(Icon::CheckMark, 12.))
        } else {
            div().size(px(20.)).rounded(px(4.)).bg(theme.control_fill).border_1().border_color(
                if self.disabled {
                    theme.control_strong_stroke_disabled
                } else {
                    theme.control_strong_stroke
                },
            )
        };
        let row = selectable_row(
            self.id,
            Role::CheckBox,
            self.checked,
            self.focus.map(|handle| handle.tab_index(0).tab_stop(true)),
            glyph,
            decoration,
            self.label,
            self.description,
            self.error,
            self.disabled,
            false,
            self.on_toggle,
            window,
            cx,
        );
        // The box lines up with the text above, as a radio group's glyphs do.
        div().ml(-ROW_INSET).child(row).into_any_element()
    }
}

/// How a checked box or selected radio is painted: its fill, the tick or dot
/// on it, and an outline in a contrast theme.
#[derive(Clone, Copy, Debug, PartialEq)]
struct Checked {
    fill: Hsla,
    mark: Hsla,
    outline: Option<Hsla>,
}

impl Checked {
    /// The accent while the control can be used. A disabled one takes
    /// WinUI's disabled accent fill, so it doesn't look like a live choice;
    /// a contrast theme draws it as gray text on the control colour.
    fn of(theme: &Theme, enabled: bool) -> Self {
        match (enabled, theme.high_contrast) {
            // In a contrast theme the fill is the highlight colour, as a
            // hovered row's outline is; an outline of its own keeps it distinct.
            (true, true) => {
                Self { fill: theme.accent, mark: theme.text_on_accent, outline: Some(theme.text_on_accent) }
            }
            (true, false) => Self { fill: theme.accent, mark: theme.text_on_accent, outline: None },
            (false, true) => Self {
                fill: theme.control_fill,
                mark: theme.text_disabled,
                outline: Some(theme.control_strong_stroke_disabled),
            },
            (false, false) => {
                Self { fill: theme.accent_disabled, mark: theme.text_on_accent_disabled, outline: None }
            }
        }
    }
}

/// How far a selectable row's glyph sits inside the row: its 8px padding and
/// 1px border. Radio groups and check boxes move it into the margin, so the
/// glyph lines up with the text above while the hover fill and focus ring
/// reach into the gutter. An auto width grows by the margin, so the right
/// edge stays where it was.
const ROW_INSET: Pixels = px(9.);

#[allow(clippy::too_many_arguments)]
fn selectable_row(
    id: ElementId,
    role: Role,
    checked: bool,
    focus: Option<FocusHandle>,
    glyph: gpui::Div,
    decoration: Option<AnyElement>,
    label: SharedString,
    description: Option<SharedString>,
    error: Option<SharedString>,
    disabled: bool,
    readable_description: bool,
    handler: Option<ClickHandler>,
    window: &Window,
    cx: &App,
) -> impl IntoElement {
    let theme = cx.theme();
    let focus_outer = theme.focus_outer;
    let focus_inner = theme.focus_inner;
    let hover = theme.subtle_hover;
    let pressed = theme.subtle_pressed;
    // In a contrast theme `accent` is the highlight colour.
    let highlight = theme.accent;
    let transparent = theme.transparent();
    let high_contrast = theme.high_contrast;
    let label_color = if disabled { theme.text_disabled } else { theme.text_primary };
    let description_color = description_colour(theme, disabled, readable_description);
    let has_description = description.as_ref().is_some_and(|text| !text.is_empty());
    let description_line = description
        .clone()
        .map(|text| div().type_caption().when_some(description_color, Styled::text_color).child(text));
    let row = div()
        .id(id)
        .role(role)
        .aria_label(label.clone())
        // The error first, then the control's own description: neither replaces the other.
        .when_some(super::compose_description(&[error.clone(), description]), |this, text| {
            this.aria_description(text)
        })
        .aria_toggled(if checked { Toggled::True } else { Toggled::False })
        .aria_disabled(disabled)
        .flex()
        .items_start()
        .gap(px(12.))
        .w_full()
        .px(px(8.))
        .py(px(6.))
        .rounded(px(4.))
        // A transparent border keeps the focus ring, and a contrast theme's
        // hover outline, from moving the layout.
        .border_1()
        .border_color(transparent)
        .text_color(label_color)
        // Hover and press never change the text colour. GPUI lays text out
        // with the hover state of the last mouse move, which can outlive the
        // pointer (the window opened under it, or it left between moves),
        // while fills follow the pointer itself. A highlight-text colour could
        // then stay on the words alone, on the window background, where a
        // contrast theme's words look disabled. So a contrast theme outlines
        // the row in the highlight colour instead of filling it.
        .when(!disabled, |this| {
            this.map(|this| match &focus {
                Some(handle) => this.track_focus(handle),
                None => this.tab_index(0),
            })
            .map(|this| {
                pointer_hover(this, window, move |style| {
                    if high_contrast { style.border_color(highlight) } else { style.bg(hover) }
                })
            })
            .active(
                move |style| if high_contrast { style.border_color(highlight) } else { style.bg(pressed) },
            )
            .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
            .when_some(handler, on_activate)
        })
        // With supporting copy, align the control's top to the visible title.
        // A label alone is centred against the control.
        .child(TextMark::new(glyph.flex_shrink_0(), has_description))
        .child(
            div()
                .flex()
                .flex_col()
                .flex_1()
                .min_w_0()
                .type_body()
                .child(label_line(decoration, label))
                .children(description_line)
                .children(error.map(|error| div().pt(px(2.)).child(error_caption(error, theme)))),
        );
    Revealed::new(row)
}

/// A row's label, after its icon or logo when it has one. The icon sits on
/// the label's line, not beside the whole text, so every description in a
/// list starts at the same text edge, with an icon or without.
fn label_line(decoration: Option<AnyElement>, label: SharedString) -> AnyElement {
    match decoration {
        Some(decoration) => div()
            .flex()
            .items_center()
            .gap(px(8.))
            .child(div().flex_shrink_0().child(decoration))
            .child(div().flex_1().min_w_0().child(CapCenteredText(label)))
            .into_any_element(),
        None => CapCenteredText(label).into_any_element(),
    }
}

/// The colour of a row's description, or `None` to take the row's own, as
/// the label does. A disabled row's description greys out with it, unless it
/// says why the row is disabled. In a contrast theme secondary text is the
/// body colour anyway, so only such a reason sets one there.
fn description_colour(theme: &Theme, disabled: bool, readable: bool) -> Option<Hsla> {
    match (disabled, readable) {
        (true, true) => Some(theme.text_secondary),
        _ if theme.high_contrast => None,
        (true, false) => Some(theme.text_disabled),
        (false, _) => Some(theme.text_secondary),
    }
}

#[cfg(test)]
mod tests {
    use super::{Checked, description_colour, step_available, step_index};
    use crate::theme::{Theme, composite, contrast_ratio, windows_contrast_themes};

    #[test]
    fn a_disabled_reason_stays_readable_on_a_card() {
        for theme in [Theme::light(), Theme::dark()] {
            let layer = composite(theme.layer_fill, theme.solid_background);
            let reason = description_colour(&theme, true, true).expect("a reason sets its colour");
            let ratio = contrast_ratio(reason, theme.card_fill, layer);
            assert!(ratio >= 4.5, "{:?}: {ratio:.2}:1", theme.appearance);
            // Without the option, the description greys out with the row.
            assert_eq!(description_colour(&theme, true, false), Some(theme.text_disabled));
        }
        for (name, colors) in windows_contrast_themes() {
            let theme = Theme::high_contrast(colors);
            assert_eq!(description_colour(&theme, true, true), Some(theme.text_primary), "{name}");
            assert_eq!(description_colour(&theme, false, false), None, "{name}");
        }
    }

    #[test]
    fn a_disabled_choice_never_keeps_the_accent() {
        for theme in [Theme::light(), Theme::dark()] {
            let disabled = Checked::of(&theme, false);
            assert_ne!(disabled.fill, theme.accent, "{:?}", theme.appearance);
            assert_eq!(Checked::of(&theme, true).fill, theme.accent);
        }
        for (name, colors) in windows_contrast_themes() {
            let theme = Theme::high_contrast(colors);
            let disabled = Checked::of(&theme, false);
            assert_ne!(disabled.fill, theme.accent, "{name}");
            // The gray tick on the control colour still reads as checked.
            let ratio = contrast_ratio(disabled.mark, disabled.fill, theme.solid_background);
            assert!(ratio >= 3.0, "{name}: {ratio:.2}:1");
        }
    }

    #[test]
    fn arrow_keys_wrap_around_the_group() {
        assert_eq!(step_index(0, 3, true), 1);
        assert_eq!(step_index(2, 3, true), 0);
        assert_eq!(step_index(0, 3, false), 2);
        assert_eq!(step_index(1, 3, false), 0);
        assert_eq!(step_index(0, 1, true), 0);
        assert_eq!(step_index(0, 0, true), 0);
    }

    #[test]
    fn arrow_keys_pass_over_unavailable_options() {
        let available = [true, false, true, false];
        assert_eq!(step_available(0, &available, true), 2);
        assert_eq!(step_available(2, &available, true), 0);
        assert_eq!(step_available(0, &available, false), 2);
        // With nothing else available, the option stays where it is.
        assert_eq!(step_available(0, &[true, false], true), 0);
        assert_eq!(step_available(0, &[], true), 0);
    }
}
