//! RadioGroup and CheckBox, drawn to the Windows 11 spec (20px glyphs, 4px
//! corners on the check box, accent fill when selected).
//!
//! A radio group is one tab stop: Tab lands on the selected option and the
//! arrow keys move the selection, as in Windows Settings. Each control
//! carries its accessible role, name and checked state.

use std::collections::HashMap;
use std::rc::Rc;

use gpui::{
    AnyElement, App, ClickEvent, ElementId, FocusHandle, ImageSource, IntoElement, ParentElement, Pixels,
    RenderOnce, Role, SharedString, Styled, Toggled, Window, div, prelude::*, px,
};

use super::actions::{RadioNext, RadioPrevious};
use super::text_input::error_caption;
use super::typography::CapCenteredText;
use super::{
    ClickHandler, Icon, Revealed, TextMark, Typography, focus_ring, icon_sized, on_activate, pointer_hover,
};
use crate::theme::ActiveTheme;

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
}

impl RadioItem {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, focus: FocusHandle) -> Self {
        Self { id: id.into(), label: label.into(), description: None, focus, leading_icon: None, image: None }
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

impl RenderOnce for RadioGroup {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.theme();
        let disabled = self.disabled;
        let selected = self.selected;
        let on_select = self.on_select.clone();
        // Tab lands on the selected option only; arrows reach the rest.
        let tab_stop_index = selected.unwrap_or(0);
        let handles: Vec<FocusHandle> = self
            .items
            .iter()
            .enumerate()
            .map(|(index, item)| {
                item.focus.clone().tab_index(0).tab_stop(!disabled && index == tab_stop_index)
            })
            .collect();

        let mover = |forward: bool| {
            let items: Vec<FocusHandle> = handles.clone();
            let on_select = on_select.clone();
            move |window: &mut Window, cx: &mut App| {
                let current = items.iter().position(|h| h.is_focused(window)).or(selected).unwrap_or(0);
                let next = step_index(current, items.len(), forward);
                if let Some(handle) = items.get(next) {
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
            .flex()
            .flex_col()
            .gap(px(2.))
            .when(!disabled, |this| {
                this.on_action(move |_: &RadioNext, window, cx| next(window, cx))
                    .on_action(move |_: &RadioPrevious, window, cx| previous(window, cx))
            });

        let accent = theme.accent;
        let dot = if theme.is_dark() && !theme.high_contrast {
            theme.text_on_accent.opacity(0.9)
        } else {
            theme.text_on_accent
        };
        // In a contrast theme the selected ring is the highlight colour, as a
        // hovered row's outline is; an outline of its own keeps it distinct.
        let outline = theme.high_contrast.then_some(theme.text_on_accent);
        let control_fill = theme.control_fill;
        let stroke =
            if disabled { theme.control_strong_stroke_disabled } else { theme.control_strong_stroke };

        for (index, item) in self.items.into_iter().enumerate() {
            let is_selected = selected == Some(index);
            let glyph = if is_selected {
                // Accent disc with a centre dot in the on-accent colour.
                div()
                    .size(px(20.))
                    .rounded_full()
                    .bg(accent)
                    .when_some(outline, |this, colour| this.border_1().border_color(colour))
                    .flex()
                    .items_center()
                    .justify_center()
                    .child(div().size(px(8.)).rounded_full().bg(dot))
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
                disabled,
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
    flush_start: bool,
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
            flush_start: false,
            on_toggle: None,
        }
    }

    /// Lines the box up with the text and buttons above it, as in a bar
    /// whose message it confirms: the row's padding and border move into the
    /// margin, so the hover fill and focus ring reach into the gutter instead.
    pub fn flush_start(mut self) -> Self {
        self.flush_start = true;
        self
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
            div()
                .size(px(20.))
                .rounded(px(4.))
                .bg(theme.accent)
                // Kept distinct from a contrast theme's highlight hover outline.
                .when(theme.high_contrast, |this| this.border_1().border_color(theme.text_on_accent))
                .flex()
                .items_center()
                .justify_center()
                .text_color(theme.text_on_accent)
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
        let flush_start = self.flush_start;
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
            self.on_toggle,
            window,
            cx,
        );
        if flush_start {
            // The row's 8px padding plus its 1px border. An auto width grows
            // by the margin, so the right edge stays where it was.
            div().ml(px(-9.)).child(row).into_any_element()
        } else {
            row.into_any_element()
        }
    }
}

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
    let description_color = if disabled { theme.text_disabled } else { theme.text_secondary };
    let has_description = description.as_ref().is_some_and(|text| !text.is_empty());
    // In a contrast theme secondary text is the body colour anyway; it takes
    // the row's colour there, as the label does.
    let description_line = description.clone().map(|text| {
        div().type_caption().when(!high_contrast, |this| this.text_color(description_color)).child(text)
    });
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
        .when_some(decoration, |this, decoration| this.child(TextMark::new(decoration, has_description)))
        .child(
            div()
                .flex()
                .flex_col()
                .flex_1()
                .min_w_0()
                .type_body()
                .child(CapCenteredText(label))
                .children(description_line)
                .children(error.map(|error| div().pt(px(2.)).child(error_caption(error, theme)))),
        );
    Revealed::new(row)
}

#[cfg(test)]
mod tests {
    use super::step_index;

    #[test]
    fn arrow_keys_wrap_around_the_group() {
        assert_eq!(step_index(0, 3, true), 1);
        assert_eq!(step_index(2, 3, true), 0);
        assert_eq!(step_index(0, 3, false), 2);
        assert_eq!(step_index(1, 3, false), 0);
        assert_eq!(step_index(0, 1, true), 0);
        assert_eq!(step_index(0, 0, true), 0);
    }
}
