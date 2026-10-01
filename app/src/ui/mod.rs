//! Fluent controls built on GPUI primitives. Each control is a `RenderOnce`
//! component that reads the active [`Theme`](crate::theme::Theme), carries
//! its accessible role and name, and takes part in keyboard traversal.

mod button;
mod card;
mod combo_box;
mod completion_backdrop;
pub mod content_dialog;
pub mod focus_reveal;
mod icons;
mod infobar;
mod markdown;
mod progress;
mod scrollbar;
mod selection;
mod status;
pub mod text_input;
mod text_mark;
mod titlebar;
mod toggle_switch;
mod tooltip;
mod typography;

pub use button::Button;
pub use card::card;
pub use combo_box::{ComboBox, ComboItem};
pub use completion_backdrop::{CompletionBackdrop, KeepOut};
pub use focus_reveal::Revealed;
pub use icons::{Icon, icon, icon_in_line, icon_in_line_sized, icon_sized};
pub use infobar::{InfoBar, Severity, dismiss_button};
pub use markdown::{Block as MarkdownBlock, Markdown, parse as parse_markdown};
pub use progress::{ProgressBar, ProgressRing};
pub use scrollbar::{
    ScrollbarState, keyboard_scrolling, nested_scrollbar, page_keyboard_scrolling, scrollbar,
};
pub use selection::{CheckBox, FocusHandles, RadioGroup, RadioItem};
pub use status::{LightState, StatusLight};
pub use text_mark::TextMark;
pub use titlebar::TitleBar;
pub use toggle_switch::ToggleSwitch;
pub use typography::{
    BODY_LINE_HEIGHT, CapCenteredText, Typography, body_cap_center_offset, centred_step_number,
    set_text_scale,
};

/// Keyboard actions the shell and controls respond to, bound by
/// [`key_bindings`]. `NavigateBack` (Escape) does what a page's back arrow
/// does.
pub mod actions {
    gpui::actions!(
        atlas,
        [
            FocusNext,
            FocusPrevious,
            NavigateBack,
            RadioNext,
            RadioPrevious,
            ScrollLineUp,
            ScrollLineDown,
            ScrollPageUp,
            ScrollPageDown,
            ScrollToTop,
            ScrollToBottom,
            ScrollLogToTop,
            ScrollLogToBottom,
        ]
    );
}

/// The app's key bindings, which `main` installs. Keyboard traversal and
/// scrolling are not built into GPUI; the shell and controls handle these.
///
/// A binding with no context ranks with the deepest context and a later
/// binding wins a tie, so the context bindings for keys that are also
/// bound globally come after the global ones.
pub fn key_bindings() -> Vec<gpui::KeyBinding> {
    use actions::*;
    use gpui::KeyBinding;
    vec![
        KeyBinding::new("tab", FocusNext, None),
        KeyBinding::new("shift-tab", FocusPrevious, None),
        KeyBinding::new("escape", NavigateBack, None),
        KeyBinding::new("down", RadioNext, Some("RadioGroup")),
        KeyBinding::new("right", RadioNext, Some("RadioGroup")),
        KeyBinding::new("up", RadioPrevious, Some("RadioGroup")),
        KeyBinding::new("left", RadioPrevious, Some("RadioGroup")),
        // The page on screen scrolls wherever focus is; a focused log scrolls itself first.
        KeyBinding::new("pageup", ScrollPageUp, None),
        KeyBinding::new("pagedown", ScrollPageDown, None),
        KeyBinding::new("ctrl-home", ScrollToTop, None),
        KeyBinding::new("ctrl-end", ScrollToBottom, None),
        KeyBinding::new("up", ScrollLineUp, Some("Log")),
        KeyBinding::new("down", ScrollLineDown, Some("Log")),
        // Home and End stay with the log even when it is already at that end.
        KeyBinding::new("home", ScrollLogToTop, Some("Log")),
        KeyBinding::new("end", ScrollLogToBottom, Some("Log")),
        // In a text box, Ctrl+Home and Ctrl+End go to the start and end of the
        // text, and a multi-line one moves its caret a page at a time.
        KeyBinding::new("ctrl-home", text_input::TextStart, Some("TextInput")),
        KeyBinding::new("ctrl-end", text_input::TextEnd, Some("TextInput")),
        KeyBinding::new("ctrl-shift-home", text_input::SelectTextStart, Some("TextInput")),
        KeyBinding::new("ctrl-shift-end", text_input::SelectTextEnd, Some("TextInput")),
        KeyBinding::new("pageup", text_input::PageUp, Some("TextInput && multiline")),
        KeyBinding::new("pagedown", text_input::PageDown, Some("TextInput && multiline")),
        KeyBinding::new("shift-pageup", text_input::SelectPageUp, Some("TextInput && multiline")),
        KeyBinding::new("shift-pagedown", text_input::SelectPageDown, Some("TextInput && multiline")),
        // Editing in a text box; a multi-line one also takes Enter and the up and down arrows.
        KeyBinding::new("backspace", text_input::Backspace, Some("TextInput")),
        KeyBinding::new("delete", text_input::Delete, Some("TextInput")),
        KeyBinding::new("left", text_input::Left, Some("TextInput")),
        KeyBinding::new("right", text_input::Right, Some("TextInput")),
        KeyBinding::new("shift-left", text_input::SelectLeft, Some("TextInput")),
        KeyBinding::new("shift-right", text_input::SelectRight, Some("TextInput")),
        KeyBinding::new("ctrl-a", text_input::SelectAll, Some("TextInput")),
        KeyBinding::new("ctrl-v", text_input::Paste, Some("TextInput")),
        KeyBinding::new("ctrl-c", text_input::Copy, Some("TextInput")),
        KeyBinding::new("ctrl-x", text_input::Cut, Some("TextInput")),
        KeyBinding::new("home", text_input::Home, Some("TextInput")),
        KeyBinding::new("end", text_input::End, Some("TextInput")),
        KeyBinding::new("shift-home", text_input::SelectHome, Some("TextInput")),
        KeyBinding::new("shift-end", text_input::SelectEnd, Some("TextInput")),
        KeyBinding::new("enter", text_input::Newline, Some("TextInput && multiline")),
        KeyBinding::new("shift-enter", text_input::Newline, Some("TextInput && multiline")),
        KeyBinding::new("up", text_input::Up, Some("TextInput && multiline")),
        KeyBinding::new("down", text_input::Down, Some("TextInput && multiline")),
        KeyBinding::new("shift-up", text_input::SelectUp, Some("TextInput && multiline")),
        KeyBinding::new("shift-down", text_input::SelectDown, Some("TextInput && multiline")),
        // A closed combo box opens only on purpose: its arrow keys do nothing.
        KeyBinding::new("alt-down", combo_box::Toggle, Some("ComboBox")),
        KeyBinding::new("alt-up", combo_box::Toggle, Some("ComboBox")),
        KeyBinding::new("f4", combo_box::Toggle, Some("ComboBox")),
        // Its open list takes the arrows, the page keys, Enter, Space and Escape.
        KeyBinding::new("up", combo_box::Previous, Some("ComboBoxList")),
        KeyBinding::new("down", combo_box::Next, Some("ComboBoxList")),
        KeyBinding::new("home", combo_box::First, Some("ComboBoxList")),
        KeyBinding::new("end", combo_box::Last, Some("ComboBoxList")),
        KeyBinding::new("pageup", combo_box::PageUp, Some("ComboBoxList")),
        KeyBinding::new("pagedown", combo_box::PageDown, Some("ComboBoxList")),
        KeyBinding::new("enter", combo_box::Commit, Some("ComboBoxList")),
        KeyBinding::new("space", combo_box::Commit, Some("ComboBoxList")),
        KeyBinding::new("escape", combo_box::Close, Some("ComboBoxList")),
    ]
}

/// The Windows focus visual: a 2px outer ring with a 1px inner ring, drawn
/// with the element's border and inset shadows so it never paints behind a
/// transparent control. Elements need a 1px (transparent) border already.
pub fn focus_ring<S: gpui::Styled>(style: S, outer: gpui::Hsla, inner: gpui::Hsla) -> S {
    use gpui::{BoxShadow, point, px};
    // Inset shadows start under the border: the outer one adds a second line
    // to it, and the inner one shows a line inside that.
    style.border_color(outer).shadow(vec![
        BoxShadow {
            color: inner,
            offset: point(px(0.), px(0.)),
            blur_radius: px(0.),
            spread_radius: px(3.),
            inset: true,
        },
        BoxShadow {
            color: outer,
            offset: point(px(0.), px(0.)),
            blur_radius: px(0.),
            spread_radius: px(2.),
            inset: true,
        },
    ])
}

/// The Fluent shadow under a surface raised `elevation` above the page: 16
/// for a tooltip, 32 for a flyout. A contrast theme draws none; the
/// surface's stroke marks its edge.
pub(crate) fn elevation_shadow(theme: &crate::theme::Theme, elevation: f32) -> Vec<gpui::BoxShadow> {
    use gpui::{BoxShadow, black, point, px};
    if theme.high_contrast {
        return Vec::new();
    }
    let (ambient, key) = if theme.is_dark() { (0.24, 0.28) } else { (0.12, 0.14) };
    let shadow = |opacity: f32, y: f32, blur: f32| BoxShadow {
        color: black().opacity(opacity),
        offset: point(px(0.), px(y)),
        blur_radius: px(blur),
        spread_radius: px(0.),
        inset: false,
    };
    // Fluent spreads the ambient shadow further from flyouts up.
    let ambient_blur = if elevation > 16. { 8. } else { 2. };
    vec![shadow(ambient, 0., ambient_blur), shadow(key, elevation / 2., elevation)]
}

/// Adds a hover `style` that applies only while the mouse is in use. Once a
/// key is pressed GPUI stops drawing a hovered element's fill, but its text
/// keeps the hover colour until the pointer moves. A contrast theme would
/// then show highlight text on the normal fill, which can be the same colour.
fn pointer_hover<E: gpui::InteractiveElement>(
    element: E,
    window: &gpui::Window,
    style: impl FnOnce(gpui::StyleRefinement) -> gpui::StyleRefinement,
) -> E {
    let keyboard = window.last_input_was_keyboard();
    // An empty hover style still has GPUI track the pointer, so the hover
    // state is current when the mouse takes over again.
    element.hover(move |base| if keyboard { base } else { style(base) })
}

/// Records where the control it's placed in was drawn, border included, so a
/// popup can sit beside the control on the next frame. The control needs the
/// 1px border every control here has.
fn drawn_bounds(bounds: std::rc::Rc<std::cell::Cell<gpui::Bounds<gpui::Pixels>>>) -> impl gpui::IntoElement {
    use gpui::{Styled, canvas, px};
    // Insets count from inside the border, and a child with none sits after
    // the padding, so pin all four edges to the border's outside.
    canvas(move |drawn, _, _| bounds.set(drawn), |_, _, _, _| {}).absolute().inset(px(-1.))
}

/// One accessible description from its parts, in the order given: an error
/// first, then what the control says about itself. Empty parts are left out
/// and the rest joined with a space, so no part replaces another; `None`
/// when nothing is left. Call `aria_description` once with the result: a
/// second call would replace the first.
pub fn compose_description(parts: &[Option<gpui::SharedString>]) -> Option<gpui::SharedString> {
    let parts: Vec<&str> =
        parts.iter().flatten().map(|part| part.trim()).filter(|part| !part.is_empty()).collect();
    (!parts.is_empty()).then(|| parts.join(" ").into())
}

/// Accessible plain text: a labelled text node screen readers can read.
/// Ordinary string children are drawn but not reported.
pub fn a11y_text(id: impl Into<gpui::ElementId>, text: impl Into<gpui::SharedString>) -> gpui::Text {
    gpui::Text::new(id.into(), text.into())
}

type ClickHandler = std::rc::Rc<dyn Fn(&gpui::ClickEvent, &mut gpui::Window, &mut gpui::App)>;

/// Runs `handler` on a click and on assistive technology's Click action.
/// Without a listener for that action GPUI would synthesise a mouse click at
/// the element's centre, which misses an element scrolled out of view.
fn on_activate(element: gpui::Stateful<gpui::Div>, handler: ClickHandler) -> gpui::Stateful<gpui::Div> {
    use gpui::prelude::*;
    let by_action = handler.clone();
    element
        .on_click(move |event, window, cx| handler(event, window, cx))
        .on_a11y_action(gpui::AccessibleAction::Click, move |_, window, cx| {
            by_action(&gpui::ClickEvent::default(), window, cx)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::{Action, KeyContext, Keymap, Keystroke};

    /// The action the keymap picks for `key` with the given contexts, innermost last.
    fn action_for(keymap: &Keymap, key: &str, contexts: &[&str]) -> Option<&'static str> {
        let contexts: Vec<KeyContext> =
            contexts.iter().map(|name| KeyContext::parse(name).unwrap()).collect();
        let (bindings, _) = keymap.bindings_for_input(&[Keystroke::parse(key).unwrap()], &contexts);
        bindings.first().map(|binding| binding.action().name())
    }

    #[test]
    fn scrolling_keys_leave_controls_their_own_keys() {
        let keymap = Keymap::new(key_bindings());
        assert_eq!(action_for(&keymap, "down", &["RadioGroup"]), Some(actions::RadioNext.name()));
        assert_eq!(action_for(&keymap, "up", &["RadioGroup"]), Some(actions::RadioPrevious.name()));
        assert_eq!(action_for(&keymap, "down", &[]), None, "arrows alone do not scroll the page");
        assert_eq!(action_for(&keymap, "pagedown", &[]), Some(actions::ScrollPageDown.name()));
        assert_eq!(action_for(&keymap, "pagedown", &["RadioGroup"]), Some(actions::ScrollPageDown.name()));
        assert_eq!(action_for(&keymap, "ctrl-end", &[]), Some(actions::ScrollToBottom.name()));
        assert_eq!(action_for(&keymap, "down", &["Log"]), Some(actions::ScrollLineDown.name()));
        assert_eq!(action_for(&keymap, "end", &["Log"]), Some(actions::ScrollLogToBottom.name()));
        assert_eq!(action_for(&keymap, "home", &["Log"]), Some(actions::ScrollLogToTop.name()));
        assert_eq!(action_for(&keymap, "ctrl-home", &["Log"]), Some(actions::ScrollToTop.name()));
        assert_eq!(action_for(&keymap, "ctrl-home", &["TextInput"]), Some(text_input::TextStart.name()));
        assert_eq!(action_for(&keymap, "pagedown", &["TextInput"]), Some(actions::ScrollPageDown.name()));
        let message = ["TextInput multiline"];
        assert_eq!(action_for(&keymap, "ctrl-home", &message), Some(text_input::TextStart.name()));
        assert_eq!(action_for(&keymap, "ctrl-end", &message), Some(text_input::TextEnd.name()));
        assert_eq!(action_for(&keymap, "ctrl-shift-end", &message), Some(text_input::SelectTextEnd.name()));
        assert_eq!(action_for(&keymap, "pagedown", &message), Some(text_input::PageDown.name()));
        assert_eq!(action_for(&keymap, "shift-pageup", &message), Some(text_input::SelectPageUp.name()));
    }

    #[test]
    fn a_description_keeps_every_part_in_order() {
        let part = |text: &str| Some(gpui::SharedString::from(text.to_owned()));
        assert_eq!(compose_description(&[None, None]), None);
        assert_eq!(compose_description(&[part(" "), None]), None, "blank parts are left out");
        assert_eq!(
            compose_description(&[
                part("Enter 10–4,000 characters."),
                None,
                part("Don't include passwords.")
            ]),
            part("Enter 10–4,000 characters. Don't include passwords.")
        );
        assert_eq!(
            compose_description(&[None, part("Logs and system details.")]),
            part("Logs and system details.")
        );
    }

    #[test]
    fn a_closed_combo_box_ignores_arrows_and_its_open_list_keeps_its_keys() {
        let keymap = Keymap::new(key_bindings());
        let closed = ["ComboBox"];
        for key in ["up", "down", "left", "right", "home", "end"] {
            assert_eq!(action_for(&keymap, key, &closed), None, "{key} leaves a closed combo box alone");
        }
        for key in ["alt-down", "alt-up", "f4"] {
            assert_eq!(action_for(&keymap, key, &closed), Some(combo_box::Toggle.name()), "{key}");
        }
        assert_eq!(action_for(&keymap, "escape", &closed), Some(actions::NavigateBack.name()));

        let open = ["ComboBox", "ComboBoxList"];
        assert_eq!(action_for(&keymap, "down", &open), Some(combo_box::Next.name()));
        assert_eq!(action_for(&keymap, "up", &open), Some(combo_box::Previous.name()));
        assert_eq!(action_for(&keymap, "end", &open), Some(combo_box::Last.name()));
        assert_eq!(action_for(&keymap, "pagedown", &open), Some(combo_box::PageDown.name()), "not the page");
        assert_eq!(action_for(&keymap, "enter", &open), Some(combo_box::Commit.name()));
        assert_eq!(action_for(&keymap, "space", &open), Some(combo_box::Commit.name()));
        assert_eq!(action_for(&keymap, "escape", &open), Some(combo_box::Close.name()), "not back");
        for key in ["alt-down", "alt-up", "f4"] {
            assert_eq!(action_for(&keymap, key, &open), Some(combo_box::Toggle.name()), "{key} closes it");
        }
        assert_eq!(action_for(&keymap, "tab", &open), Some(actions::FocusNext.name()));
    }
}
