//! RadioGroup and CheckBox, drawn to the Windows 11 spec (20px glyphs, 4px
//! corners on the check box, accent fill when selected).
//!
//! A radio group is one tab stop: Tab lands on the selected option and the
//! arrow keys move the selection, as in Windows Settings. Each control
//! carries its accessible role, name and checked state.

use std::collections::HashMap;
use std::rc::Rc;

use gpui::{
    App, ClickEvent, ElementId, FocusHandle, IntoElement, ParentElement, RenderOnce, Role, SharedString,
    Styled, Toggled, Window, div, prelude::*, px,
};

use super::actions::{RadioNext, RadioPrevious};
use super::typography::CapCenteredText;
use super::{Icon, TextMark, Typography, focus_ring, icon_sized};
use crate::t;
use crate::theme::ActiveTheme;

type ClickHandler = Rc<dyn Fn(&ClickEvent, &mut Window, &mut App)>;
type SelectHandler = Rc<dyn Fn(usize, &mut Window, &mut App)>;

/// Focus handles that persist across frames, keyed by a stable name, so
/// pages can move keyboard focus to controls they render.
#[derive(Default)]
pub struct FocusHandles {
    handles: HashMap<String, FocusHandle>,
}

impl FocusHandles {
    pub fn get(&mut self, key: &str, cx: &mut App) -> FocusHandle {
        self.handles.entry(key.to_owned()).or_insert_with(|| cx.focus_handle()).clone()
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

    #[allow(dead_code)]
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
pub fn step_index(current: usize, len: usize, forward: bool) -> usize {
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
        let control_fill = theme.control_fill;
        let stroke =
            if disabled { theme.control_strong_stroke_disabled } else { theme.control_strong_stroke };

        for (index, item) in self.items.into_iter().enumerate() {
            let is_selected = selected == Some(index);
            let glyph = if is_selected {
                // Accent ring with a white centre dot.
                div()
                    .size(px(20.))
                    .rounded_full()
                    .bg(accent)
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
                .map(|path| {
                    // No accessible role: the image is decorative and the radio owns the name.
                    div()
                        .relative()
                        .w(px(26.))
                        .h(px(20.))
                        .flex_shrink_0()
                        .child(
                            gpui::img(path)
                                .id(gpui::ElementId::Name(format!("logo-{:?}", item.id).into()))
                                .aria_label("")
                                .absolute()
                                .top(px(-3.))
                                .size(px(26.)),
                        )
                        .into_any_element()
                })
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
                disabled,
                handler,
                window,
                cx,
            ));
        }
        group
    }
}

#[derive(IntoElement)]
pub struct CheckBox {
    id: ElementId,
    label: SharedString,
    description: Option<SharedString>,
    checked: bool,
    disabled: bool,
    on_toggle: Option<ClickHandler>,
}

impl CheckBox {
    pub fn new(id: impl Into<ElementId>, label: impl Into<SharedString>, checked: bool) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            description: None,
            checked,
            disabled: false,
            on_toggle: None,
        }
    }

    pub fn description(mut self, text: impl Into<SharedString>) -> Self {
        self.description = Some(text.into());
        self
    }

    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
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
        let glyph = if self.checked {
            div()
                .size(px(20.))
                .rounded(px(4.))
                .bg(theme.accent)
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
        selectable_row(
            self.id,
            Role::CheckBox,
            self.checked,
            None,
            glyph,
            None,
            self.label,
            self.description,
            self.disabled,
            self.on_toggle,
            window,
            cx,
        )
    }
}

#[allow(clippy::too_many_arguments)]
fn selectable_row(
    id: ElementId,
    role: Role,
    checked: bool,
    focus: Option<FocusHandle>,
    glyph: gpui::Div,
    decoration: Option<gpui::AnyElement>,
    label: SharedString,
    description: Option<SharedString>,
    disabled: bool,
    handler: Option<ClickHandler>,
    _window: &Window,
    cx: &App,
) -> impl IntoElement {
    let theme = cx.theme();
    let focus_outer = theme.focus_outer;
    let focus_inner = theme.focus_inner;
    let hover = theme.subtle_hover;
    let pressed = theme.subtle_pressed;
    let hover_text = theme.text_on_hover(theme.text_primary);
    let transparent = theme.transparent();
    let label_color = if disabled { theme.text_disabled } else { theme.text_primary };
    let description_color = if disabled { theme.text_disabled } else { theme.text_secondary };
    let has_description = description.as_ref().is_some_and(|text| !text.is_empty());
    div()
        .id(id)
        .role(role)
        .aria_label(label.clone())
        .when_some(description.clone(), |this, text| this.aria_description(text))
        .aria_toggled(if checked { Toggled::True } else { Toggled::False })
        .when(disabled, |this| this.aria_description(t!("common-not-available")))
        .flex()
        .items_start()
        .gap(px(12.))
        .w_full()
        .px(px(8.))
        .py(px(6.))
        .rounded(px(4.))
        // A transparent border keeps the focus ring from moving the layout.
        .border_1()
        .border_color(transparent)
        .when(!disabled, |this| {
            this.map(|this| match &focus {
                Some(handle) => this.track_focus(handle),
                None => this.tab_index(0),
            })
            .hover(move |style| style.bg(hover).text_color(hover_text))
            .active(move |style| style.bg(pressed))
            .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
            .when_some(handler, |this, handler| {
                // Assistive technology asks for a Click by action, not by
                // pointer; without a listener GPUI would synthesise a mouse
                // click at the row's centre, which misses a row that is
                // scrolled out of view.
                let by_action = handler.clone();
                this.on_click(move |event, window, cx| handler(event, window, cx))
                    .on_a11y_action(gpui::AccessibleAction::Click, move |_, window, cx| {
                        by_action(&ClickEvent::default(), window, cx)
                    })
            })
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
                .text_color(label_color)
                .child(CapCenteredText(label))
                .when_some(description, |this, text| {
                    this.child(div().type_caption().text_color(description_color).child(text))
                }),
        )
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
