//! A Fluent menu flyout under the link that opens it, one row per command,
//! for a Change that offers a few ways or a few values. The opener puts
//! focus on a row; the arrow keys move between rows, Enter or Space runs
//! one, and Escape, Tab or a press outside closes it, with focus back on
//! the link. A menu of values marks the current one with a check, as a
//! radio menu item.

use std::cell::Cell;
use std::rc::Rc;

use gpui::{
    AccessibleAction, AnyElement, App, Bounds, ElementId, FocusHandle, IntoElement, KeyDownEvent,
    MouseButton, ParentElement, Pixels, Role, SharedString, Styled, Toggled, Window, anchored, canvas,
    deferred, div, point, prelude::*, px,
};

use crate::theme::ActiveTheme;
use crate::ui::actions::{FocusNext, FocusPrevious, NavigateBack};
use crate::ui::{Icon, Typography, elevation_shadow, focus_ring, icon_sized};

/// What a row does, or what closing does.
pub(super) type Command = Rc<dyn Fn(&mut Window, &mut App)>;

/// One row of the menu.
pub(super) struct MenuCommand {
    pub id: ElementId,
    pub label: String,
    pub focus: FocusHandle,
    /// For a menu of values, whether this row is the current one; `None` for
    /// a menu of commands.
    pub checked: Option<bool>,
    pub run: Command,
}

/// Records where the control it sits in was drawn, so the menu can open
/// under it on the next frame.
pub(super) fn anchor(bounds: Rc<Cell<Bounds<Pixels>>>) -> impl IntoElement {
    canvas(move |drawn, _, _| bounds.set(drawn), |_, _, _, _| {}).absolute().inset(px(0.))
}

/// Between the link and the menu.
const GAP: Pixels = px(4.);

/// The open menu under `under`, over the page, with a layer behind it that
/// closes it on a press anywhere else.
pub(super) fn flyout(
    label: SharedString,
    commands: Vec<MenuCommand>,
    under: Bounds<Pixels>,
    close: Command,
    window: &mut Window,
    cx: &mut App,
) -> AnyElement {
    let theme = cx.theme().clone();
    let viewport = window.viewport_size();
    let count = commands.len();
    let handles: Vec<FocusHandle> = commands.iter().map(|command| command.focus.clone()).collect();
    let runs: Vec<Command> = commands.iter().map(|command| command.run.clone()).collect();
    let (hover, pressed) = (theme.subtle_hover, theme.subtle_pressed);
    let (focus_outer, focus_inner) = (theme.focus_outer, theme.focus_inner);

    let rows = commands.into_iter().enumerate().map(|(index, command)| {
        let run = {
            let (run, close) = (command.run.clone(), close.clone());
            Rc::new(move |window: &mut Window, cx: &mut App| {
                close(window, cx);
                run(window, cx);
            })
        };
        let by_action = run.clone();
        let row = div()
            .id(command.id)
            .aria_label(command.label.clone())
            .aria_position_in_set(index)
            .track_focus(&command.focus.tab_stop(false))
            .flex()
            .items_center()
            .gap(px(12.))
            .mx(px(4.))
            .my(px(2.))
            .px(px(11.))
            .py(px(5.))
            .rounded(px(4.))
            .border_1()
            .border_color(theme.transparent())
            .hover(move |style| style.bg(hover))
            .active(move |style| style.bg(pressed))
            .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
            .on_click(move |_, window, cx| run(window, cx))
            .on_a11y_action(AccessibleAction::Click, move |_, window, cx| by_action(window, cx));
        match command.checked {
            // A value: the check sits in a column of its own, so every
            // label starts at the same place.
            Some(checked) => row
                .role(Role::MenuItemRadio)
                .aria_toggled(if checked { Toggled::True } else { Toggled::False })
                .child(
                    div()
                        .flex_shrink_0()
                        .w(px(16.))
                        .flex()
                        .justify_center()
                        .when(checked, |slot| slot.child(icon_sized(Icon::CheckMark, 16.))),
                )
                .child(command.label),
            None => row.role(Role::MenuItem).child(command.label),
        }
    });
    let rows: Vec<_> = rows.collect();

    let move_focus = {
        let handles = handles.clone();
        move |step: isize, window: &mut Window, cx: &mut App| {
            let current = handles.iter().position(|handle| handle.is_focused(window));
            let next = match current {
                Some(index) => (index as isize + step).rem_euclid(count as isize) as usize,
                None => 0,
            };
            if let Some(handle) = handles.get(next) {
                window.focus(handle, cx);
            }
        }
    };
    let (back, next, previous, outside_left, outside_right) =
        (close.clone(), close.clone(), close.clone(), close.clone(), close);
    let surface = div()
        .id("menu")
        .role(Role::Menu)
        .aria_label(label)
        .aria_size_of_set(count)
        .on_key_down(move |event: &KeyDownEvent, window, cx| match event.keystroke.key.as_str() {
            "down" => {
                move_focus(1, window, cx);
                cx.stop_propagation();
            }
            "up" => {
                move_focus(-1, window, cx);
                cx.stop_propagation();
            }
            "enter" | "space" => {
                if let Some(index) = handles.iter().position(|handle| handle.is_focused(window)) {
                    cx.stop_propagation();
                    (runs[index])(window, cx);
                }
            }
            _ => {}
        })
        // Escape and Tab are bound to actions, which reach the menu first.
        .on_action(move |_: &NavigateBack, window, cx| back(window, cx))
        .on_action(move |_: &FocusNext, window, cx| next(window, cx))
        .on_action(move |_: &FocusPrevious, window, cx| previous(window, cx))
        // A press on the menu stays off the layer behind it.
        .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
        .on_mouse_down(MouseButton::Right, |_, _, cx| cx.stop_propagation())
        .absolute()
        .left(under.left())
        .top(under.bottom() + GAP)
        .min_w(px(200.))
        .py(px(2.))
        .rounded(px(8.))
        .bg(theme.flyout_fill)
        .border_1()
        .border_color(theme.flyout_stroke)
        .shadow(elevation_shadow(&theme, 32.))
        .type_body()
        .text_color(theme.text_primary)
        .children(rows);

    deferred(
        anchored().position(point(px(0.), px(0.))).child(
            div()
                .id("menu-dismiss")
                .w(viewport.width)
                .h(viewport.height)
                .occlude()
                .on_mouse_down(MouseButton::Left, move |_, window, cx| outside_left(window, cx))
                .on_mouse_down(MouseButton::Right, move |_, window, cx| outside_right(window, cx))
                .child(surface),
        ),
    )
    .with_priority(1)
    .into_any_element()
}
