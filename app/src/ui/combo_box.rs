//! The Fluent ComboBox: a button that shows the current choice and opens a
//! list of the others below it, or over it, with the current choice on the
//! control, when there's no room below. The list never covers the title bar.
//!
//! A choice takes a deliberate step. While the list is closed the arrow keys
//! do nothing, so a value such as the app's language never changes as focus
//! passes over it. Open, the arrow keys move a highlight, and only Enter,
//! Space or a click commits it. Escape, Tab or a click outside closes the
//! list without changing anything.

use std::cell::Cell;
use std::rc::Rc;

use gpui::{
    AccessibleAction, AnyElement, App, Bounds, ClickEvent, Context, ElementId, Entity, FocusHandle, Hsla,
    IntoElement, MouseButton, ParentElement, Pixels, RenderOnce, Role, ScrollHandle, SharedString, Styled,
    Window, actions, anchored, deferred, div, point, prelude::*, px,
};

use super::actions::{FocusNext, FocusPrevious};
use super::icons::icon_in_line_sized;
use super::titlebar::TITLE_BAR_HEIGHT;
use super::typography::CapCenteredText;
use super::{
    BODY_LINE_HEIGHT, ClickHandler, Icon, Revealed, ScrollbarState, Typography, drawn_bounds,
    elevation_shadow, focus_ring, nested_scrollbar, on_activate, pointer_hover,
};
use crate::theme::{ActiveTheme, Theme};

actions!(combo_box, [Toggle, Previous, Next, First, Last, PageUp, PageDown, Commit, Close]);

/// Between the combo box and its list.
const GAP: Pixels = px(4.);
/// Between the list and the window's edges.
const MARGIN: Pixels = px(8.);
/// A list longer than this scrolls. The half row shows there is more.
const MAX_ROWS: f32 = 9.5;
/// A row's padding and stroke around its line of text: 32px tall in all at
/// the default text size.
const ROW_PADDING: f32 = 12.;
/// The space a row keeps above and below it.
const ROW_MARGIN: f32 = 4.;
/// The list's own padding and stroke, above and below its rows.
const LIST_CHROME: f32 = 6.;
/// From the list's top to the top of its first row's box: the 1px stroke,
/// the 2px padding and the row's own 2px margin.
const FIRST_ROW_TOP: f32 = 5.;
/// The fewest rows the list shows below the combo box; with less room there
/// it opens over the box instead.
const MIN_ROWS_BELOW: f32 = 3.;
/// Above the page, below tooltips.
const PRIORITY: usize = 1;

type SelectHandler = Rc<dyn Fn(usize, &mut Window, &mut App)>;

/// One choice in a [`ComboBox`].
pub struct ComboItem {
    label: SharedString,
    chip: Option<SharedString>,
    selected_label: Option<SharedString>,
    language: Option<SharedString>,
}

impl ComboItem {
    pub fn new(label: impl Into<SharedString>) -> Self {
        Self { label: label.into(), chip: None, selected_label: None, language: None }
    }

    /// The language the label is written in (a BCP 47 tag), when it isn't
    /// the app's, so a screen reader reads it in that language's voice.
    pub fn lang(mut self, tag: impl Into<SharedString>) -> Self {
        self.language = Some(tag.into());
        self
    }

    /// A short tag after the label, such as "Preview", which is also the
    /// item's accessible description.
    pub fn chip(mut self, text: impl Into<SharedString>) -> Self {
        self.chip = Some(text.into());
        self
    }

    /// What the closed combo box shows while this item is chosen, when the
    /// label alone says too little there.
    pub fn selected_label(mut self, text: impl Into<SharedString>) -> Self {
        self.selected_label = Some(text.into());
        self
    }
}

/// A Fluent combo box. It fills its container's width; size it there.
#[derive(IntoElement)]
pub struct ComboBox {
    id: ElementId,
    label: SharedString,
    items: Vec<ComboItem>,
    selected: Option<usize>,
    disabled: bool,
    on_select: Option<SelectHandler>,
}

impl ComboBox {
    /// `label` is the accessible name; show the same text beside the control.
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

    /// Shows the current choice in the disabled colours; it can't be
    /// focused or opened, and reports itself unavailable.
    pub fn disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }

    pub fn items(mut self, items: impl IntoIterator<Item = ComboItem>) -> Self {
        self.items.extend(items);
        self
    }

    pub fn selected(mut self, index: Option<usize>) -> Self {
        self.selected = index;
        self
    }

    /// Called with the index of a newly committed item, never for the
    /// current one.
    pub fn on_select(mut self, handler: impl Fn(usize, &mut Window, &mut App) + 'static) -> Self {
        self.on_select = Some(Rc::new(handler));
        self
    }
}

/// Whether the list is open and which item its highlight is on. The rules
/// for keys and clicks, apart from drawing.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct Picker {
    open: bool,
    /// The item the arrow keys have reached; Enter or Space commits it.
    highlight: usize,
}

/// How a key moves the highlight in the open list.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Step {
    Previous,
    Next,
    First,
    Last,
    PageUp,
    PageDown,
}

impl Picker {
    /// Opens on the current choice, or on the first item. An empty list
    /// doesn't open.
    fn open(&mut self, selected: Option<usize>, len: usize) -> bool {
        if len == 0 {
            return false;
        }
        self.open = true;
        self.highlight = selected.filter(|&index| index < len).unwrap_or(0);
        true
    }

    /// Moves the highlight `page` rows at a time for Page Up and Page Down.
    /// It stops at the ends, as a Windows list does. A closed list ignores it.
    fn step(&mut self, step: Step, len: usize, page: usize) {
        if !self.open || len == 0 {
            return;
        }
        let last = len - 1;
        let page = page.max(1);
        self.highlight = match step {
            Step::Previous => self.highlight.saturating_sub(1),
            Step::Next => (self.highlight + 1).min(last),
            Step::First => 0,
            Step::Last => last,
            Step::PageUp => self.highlight.saturating_sub(page),
            Step::PageDown => (self.highlight + page).min(last),
        };
    }

    /// Closes the list and returns the item to commit: the highlight, unless
    /// it is the current choice already or the list has since shrunk.
    fn commit(&mut self, selected: Option<usize>, len: usize) -> Option<usize> {
        let committed =
            self.open.then_some(self.highlight).filter(|&index| index < len && Some(index) != selected);
        self.open = false;
        committed
    }

    fn close(&mut self) {
        self.open = false;
    }
}

/// Where the list goes, measured from the window's top edge, how tall it may
/// grow, and how far its rows start scrolled.
#[derive(Clone, Copy, Debug, PartialEq)]
struct Placement {
    top: Pixels,
    max_height: Pixels,
    /// Over the combo box, the rows are scrolled this far so the current
    /// choice sits on the box where the clamp allows; below it, none.
    scroll: Pixels,
    over: bool,
}

/// Below the combo box when at least [`MIN_ROWS_BELOW`] rows fit there.
/// Otherwise over it, as WinUI does: the current choice's row on the box,
/// the list kept between the title bar and the window's bottom edge.
fn placement(
    combo: Bounds<Pixels>,
    window_height: Pixels,
    wanted: Pixels,
    row: Pixels,
    len: usize,
    selected: Option<usize>,
) -> Placement {
    let top_bound = px(TITLE_BAR_HEIGHT) + MARGIN;
    let bottom_bound = window_height - MARGIN;
    let below = bottom_bound - (combo.bottom() + GAP);
    if below >= row * MIN_ROWS_BELOW + px(LIST_CHROME) {
        return Placement {
            top: combo.bottom() + GAP,
            max_height: wanted.min(below),
            scroll: px(0.),
            over: false,
        };
    }
    let height = wanted.min((bottom_bound - top_bound).max(px(0.)));
    let first_row = px(FIRST_ROW_TOP);
    let ideal = match selected {
        Some(index) => combo.top() - first_row - row * index as f32,
        None => combo.top() + combo.size.height / 2. - height / 2.,
    };
    let top = ideal.min(bottom_bound - height).max(top_bound);
    // Scroll a long list so the current row lands as near the box as it
    // can, and never outside the list.
    let content = row * len as f32 + px(LIST_CHROME);
    let max_scroll = (content - height).max(px(0.));
    let scroll = match selected {
        Some(index) => {
            let row_top = first_row + row * index as f32;
            let at_box = top + row_top - combo.top();
            at_box.min(row_top).max(row_top + row - height).min(max_scroll).max(px(0.))
        }
        None => px(0.),
    };
    Placement { top, max_height: height, scroll, over: true }
}

/// The height of one row of the open list at the current text size.
fn row_height(window: &Window) -> Pixels {
    BODY_LINE_HEIGHT.to_pixels(window.rem_size()) + px(ROW_PADDING + ROW_MARGIN)
}

/// [`placement`] for a list of `len` items beside `combo` in this window.
fn list_placement(window: &Window, combo: Bounds<Pixels>, len: usize, selected: Option<usize>) -> Placement {
    let row = row_height(window);
    let wanted = row * (len as f32).min(MAX_ROWS) + px(LIST_CHROME);
    placement(combo, window.viewport_size().height, wanted, row, len, selected)
}

/// A combo box between frames: focus, the open list and where it was drawn.
struct ComboState {
    focus: FocusHandle,
    list_focus: FocusHandle,
    picker: Picker,
    scroll: ScrollHandle,
    scrollbar: ScrollbarState,
    bounds: Rc<Cell<Bounds<Pixels>>>,
}

impl ComboState {
    fn new(cx: &mut Context<Self>) -> Self {
        Self {
            focus: cx.focus_handle(),
            list_focus: cx.focus_handle(),
            picker: Picker::default(),
            scroll: ScrollHandle::new(),
            scrollbar: ScrollbarState::new(),
            bounds: Rc::default(),
        }
    }

    fn open(&mut self, selected: Option<usize>, len: usize, window: &mut Window, cx: &mut Context<Self>) {
        if self.picker.open(selected, len) {
            let place = list_placement(window, self.bounds.get(), len, selected);
            if place.over {
                // The current choice lands on the box, not merely in view.
                self.scroll.set_offset(point(px(0.), -place.scroll));
            } else {
                self.scroll.scroll_to_item(self.picker.highlight);
            }
            window.focus(&self.list_focus, cx);
            cx.notify();
        }
    }

    /// Closes the list and puts focus back on the combo box.
    fn close(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        self.picker.close();
        window.focus(&self.focus, cx);
        cx.notify();
    }

    fn step(&mut self, step: Step, len: usize, row: Pixels, cx: &mut Context<Self>) {
        // A page is one row less than the list shows, so a row stays in view.
        let page = (self.scroll.bounds().size.height / row) as usize;
        self.picker.step(step, len, page.saturating_sub(1));
        self.scroll.scroll_to_item(self.picker.highlight);
        cx.notify();
    }
}

impl RenderOnce for ComboBox {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let ComboBox { id, label, items, selected, disabled, on_select } = self;
        let state = window.use_keyed_state(id.clone(), cx, |_, cx| ComboState::new(cx));
        let (focus, picker, bounds) = {
            let state = state.read(cx);
            (state.focus.clone(), state.picker, state.bounds.clone())
        };
        let theme = cx.theme().clone();
        let len = items.len();
        let selected = selected.filter(|&index| index < len);
        let shown: SharedString = selected
            .map(|index| items[index].selected_label.clone().unwrap_or_else(|| items[index].label.clone()))
            .unwrap_or_default();
        let open = picker.open && !disabled;

        let toggle = {
            let state = state.clone();
            move |window: &mut Window, cx: &mut App| {
                state.update(cx, |state, cx| {
                    if state.picker.open {
                        state.close(window, cx)
                    } else {
                        state.open(selected, len, window, cx)
                    }
                })
            }
        };
        let (expand, collapse) = (state.clone(), state.clone());

        // Win11 draws a slightly darker stroke on the bottom edge of raised
        // controls, as on a standard button.
        let bottom_edge = (!theme.high_contrast).then(|| gpui::BoxShadow {
            color: theme.control_stroke_secondary,
            offset: point(px(0.), px(1.)),
            blur_radius: px(0.),
            spread_radius: px(0.),
            inset: false,
        });
        let (fill_hover, fill_pressed) = (theme.control_fill_hover, theme.control_fill_pressed);
        let hover_text = theme.text_on_hover(theme.text_primary);
        let (focus_outer, focus_inner) = (theme.focus_outer, theme.focus_inner);
        // In a contrast theme it takes the text's colour, which follows the hover fill.
        let chevron = (!theme.high_contrast).then_some(theme.text_secondary);
        let click = toggle.clone();

        let text_colour = if disabled { theme.text_disabled } else { theme.text_primary };
        let fill = if disabled { theme.control_fill_disabled } else { theme.control_fill };
        let list = open.then(|| {
            OpenList { label: label.clone(), items, selected, highlight: picker.highlight, on_select }
                .render(&state, window, cx)
        });

        let combo = div()
            .id(id)
            .role(Role::ComboBox)
            .aria_label(label)
            .aria_value(shown.clone())
            .aria_expanded(open)
            .aria_disabled(disabled)
            .key_context("ComboBox")
            .flex()
            .items_center()
            .gap(px(8.))
            .w_full()
            .min_h(px(32.))
            .pl(px(12.))
            .pr(px(10.))
            .rounded(px(4.))
            .bg(fill)
            .border_1()
            .border_color(theme.control_stroke)
            .when_some(bottom_edge.filter(|_| !disabled), |this, edge| this.shadow(vec![edge]))
            .type_body()
            .text_color(text_colour)
            .when(!disabled, |this| {
                this.track_focus(&focus.tab_index(0).tab_stop(true))
                    // The open list covers it, so it shows no hover then.
                    .map(|this| {
                        pointer_hover(this, window, move |style| {
                            if open { style } else { style.bg(fill_hover).text_color(hover_text) }
                        })
                    })
                    .active(move |style| style.bg(fill_pressed))
                    .focus_visible(move |style| focus_ring(style, focus_outer, focus_inner))
                    .on_action(move |_: &Toggle, window, cx| toggle(window, cx))
                    .on_a11y_action(AccessibleAction::Expand, move |_, window, cx| {
                        expand.update(cx, |state, cx| state.open(selected, len, window, cx))
                    })
                    .on_a11y_action(AccessibleAction::Collapse, move |_, window, cx| {
                        collapse.update(cx, |state, cx| state.close(window, cx))
                    })
                    .map(|this| {
                        on_activate(this, Rc::new(move |_: &ClickEvent, window, cx| click(window, cx)))
                    })
            })
            .child(div().flex_1().min_w_0().child(CapCenteredText(shown)))
            .child(
                icon_in_line_sized(Icon::ChevronDown, 12., BODY_LINE_HEIGHT)
                    .when_some(chevron.filter(|_| !disabled), |icon, colour| icon.text_color(colour)),
            )
            .child(drawn_bounds(bounds))
            .children(list);
        Revealed::new(combo)
    }
}

/// What the open list draws from.
struct OpenList {
    label: SharedString,
    items: Vec<ComboItem>,
    selected: Option<usize>,
    highlight: usize,
    on_select: Option<SelectHandler>,
}

impl OpenList {
    /// The list over the page, with a layer behind it that closes it on a
    /// press anywhere else, so that press does nothing more.
    fn render(self, state: &Entity<ComboState>, window: &mut Window, cx: &mut App) -> AnyElement {
        let OpenList { label, items, selected, highlight, on_select } = self;
        let theme = cx.theme().clone();
        let (list_focus, scroll, scrollbar, combo) = {
            let state = state.read(cx);
            (state.list_focus.clone(), state.scroll.clone(), state.scrollbar.clone(), state.bounds.get())
        };
        let viewport = window.viewport_size();
        let row = row_height(window);
        let len = items.len();
        let place = list_placement(window, combo, len, selected);
        let max_height = place.max_height;

        // Commits the item clicked, or the highlight for a key.
        let commit = {
            let state = state.clone();
            Rc::new(move |clicked: Option<usize>, window: &mut Window, cx: &mut App| {
                let committed = state.update(cx, |state, cx| {
                    if let Some(index) = clicked {
                        state.picker.highlight = index;
                    }
                    let committed = state.picker.commit(selected, len);
                    state.close(window, cx);
                    committed
                });
                if let (Some(index), Some(on_select)) = (committed, &on_select) {
                    on_select(index, window, cx);
                }
            })
        };
        let close = {
            let state = state.clone();
            move |window: &mut Window, cx: &mut App| state.update(cx, |state, cx| state.close(window, cx))
        };
        let step = |step: Step| {
            let state = state.clone();
            move |cx: &mut App| state.update(cx, |state, cx| state.step(step, len, row, cx))
        };
        let (previous, next, first, last) =
            (step(Step::Previous), step(Step::Next), step(Step::First), step(Step::Last));
        let (page_up, page_down) = (step(Step::PageUp), step(Step::PageDown));
        // Tab closes the list unchanged and moves on from the combo box.
        let tab = {
            let close = close.clone();
            move |window: &mut Window, cx: &mut App| {
                close(window, cx);
                cx.propagate();
            }
        };
        let (tab_back, close_key, close_left, close_right) =
            (tab.clone(), close.clone(), close.clone(), close);
        let commit_key = commit.clone();

        let rows = items.into_iter().enumerate().map(|(index, item)| {
            let commit = commit.clone();
            let on_click: ClickHandler = Rc::new(move |_, window, cx| commit(Some(index), window, cx));
            let row = option(item, index, Some(index) == selected, index == highlight, window, &theme);
            on_activate(row, on_click)
        });

        let surface = div()
            .id("list")
            .role(Role::ListBox)
            .aria_label(label)
            .aria_size_of_set(len)
            .track_focus(&list_focus)
            .key_context("ComboBoxList")
            .on_action(move |_: &Previous, _, cx| previous(cx))
            .on_action(move |_: &Next, _, cx| next(cx))
            .on_action(move |_: &First, _, cx| first(cx))
            .on_action(move |_: &Last, _, cx| last(cx))
            .on_action(move |_: &PageUp, _, cx| page_up(cx))
            .on_action(move |_: &PageDown, _, cx| page_down(cx))
            .on_action(move |_: &Commit, window, cx| commit_key(None, window, cx))
            .on_action(move |_: &Close, window, cx| close_key(window, cx))
            .on_action(move |_: &FocusNext, window, cx| tab(window, cx))
            .on_action(move |_: &FocusPrevious, window, cx| tab_back(window, cx))
            // A press on the list stays off the layer behind it.
            .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
            .on_mouse_down(MouseButton::Right, |_, _, cx| cx.stop_propagation())
            .absolute()
            .left(combo.left())
            .top(place.top)
            .min_w(combo.size.width)
            .max_w((viewport.width - combo.left() - MARGIN).max(combo.size.width))
            .rounded(px(8.))
            .bg(theme.flyout_fill)
            .border_1()
            .border_color(theme.flyout_stroke)
            .shadow(elevation_shadow(&theme, 32.))
            .type_body()
            .text_color(theme.text_primary)
            .child(
                div()
                    .relative()
                    .child(
                        div()
                            .id("items")
                            .flex()
                            .flex_col()
                            .overflow_y_scroll()
                            .track_scroll(&scroll)
                            // The height left inside the list's 1px stroke.
                            .max_h(max_height - px(2.))
                            .py(px(2.))
                            .children(rows),
                    )
                    .child(nested_scrollbar(&scroll, &scrollbar)),
            );

        deferred(
            anchored().position(point(px(0.), px(0.))).child(
                div()
                    .id("dismiss")
                    .w(viewport.width)
                    .h(viewport.height)
                    .occlude()
                    .on_mouse_down(MouseButton::Left, move |_, window, cx| close_left(window, cx))
                    .on_mouse_down(MouseButton::Right, move |_, window, cx| close_right(window, cx))
                    .child(surface),
            ),
        )
        .with_priority(PRIORITY)
        .into_any_element()
    }
}

/// One row of the open list: the selection bar and fill on the current
/// choice, and the focus ring on the highlight once the keyboard moves it.
fn option(
    item: ComboItem,
    index: usize,
    selected: bool,
    highlight: bool,
    window: &Window,
    theme: &Theme,
) -> gpui::Stateful<gpui::Div> {
    let (hover, pressed) = (theme.subtle_hover, theme.subtle_pressed);
    let hover_text = theme.text_on_hover(theme.text_primary);
    let text = if selected { theme.text_on_hover(theme.text_primary) } else { theme.text_primary };
    // In a contrast theme the selected row has the highlight fill, which the accent would vanish into.
    let bar = theme.text_on_hover(theme.accent);
    div()
        .id(("item", index))
        .role(Role::ListBoxOption)
        .aria_label(item.label.clone())
        .when_some(item.language.clone(), |this, tag| this.aria_lang(tag))
        .when_some(item.chip.clone(), |this, chip| this.aria_description(chip))
        .aria_selected(selected)
        .aria_position_in_set(index)
        .when(highlight, |this| this.aria_active_descendant())
        .relative()
        .flex()
        .items_center()
        .gap(px(8.))
        .mx(px(5.))
        .my(px(2.))
        .px(px(10.))
        .py(px(5.))
        .rounded(px(4.))
        .border_1()
        .border_color(theme.transparent())
        .text_color(text)
        .when(selected, |this| this.bg(hover))
        .map(|this| {
            pointer_hover(this, window, move |style| {
                style.bg(if selected { pressed } else { hover }).text_color(hover_text)
            })
        })
        .active(move |style| style.bg(pressed).text_color(hover_text))
        .when(highlight && window.last_input_was_keyboard(), |this| {
            focus_ring(this, theme.focus_outer, theme.focus_inner)
        })
        .when(selected, |this| {
            // Clear of the focus ring, which is drawn inside the row.
            this.child(
                div()
                    .absolute()
                    .left(px(3.))
                    .top_0()
                    .bottom_0()
                    .flex()
                    .items_center()
                    .child(div().w(px(3.)).h(px(16.)).rounded(px(1.5)).bg(bar)),
            )
        })
        .child(div().flex_1().min_w_0().child(CapCenteredText(item.label)))
        .when_some(item.chip, |this, chip| this.child(chip_tag(chip, theme)))
}

/// The inline tag on a row, such as "Preview". In a contrast theme it has no
/// fill, so its text keeps the row's colour on any row.
fn chip_tag(text: SharedString, theme: &Theme) -> impl IntoElement {
    let fill: Hsla = if theme.high_contrast { theme.transparent() } else { theme.subtle_hover };
    div()
        .flex_shrink_0()
        .px(px(6.))
        .rounded(px(4.))
        .bg(fill)
        .border_1()
        .border_color(theme.card_stroke)
        .type_caption()
        .child(text)
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::size;

    #[test]
    fn arrow_keys_never_change_a_closed_combo_box() {
        let mut picker = Picker::default();
        for step in [Step::Next, Step::Previous, Step::Last, Step::PageDown] {
            picker.step(step, 5, 3);
        }
        assert_eq!(picker, Picker::default());
        assert_eq!(picker.commit(Some(1), 5), None, "nothing to commit while closed");
    }

    #[test]
    fn the_list_opens_on_the_current_choice_and_stops_at_its_ends() {
        let mut picker = Picker::default();
        assert!(!picker.open(None, 0), "an empty list stays closed");
        assert!(picker.open(Some(3), 5));
        assert_eq!(picker.highlight, 3);
        picker.step(Step::Next, 5, 3);
        picker.step(Step::Next, 5, 3);
        assert_eq!(picker.highlight, 4);
        picker.step(Step::PageUp, 5, 3);
        assert_eq!(picker.highlight, 1);
        picker.step(Step::PageUp, 5, 3);
        picker.step(Step::Previous, 5, 3);
        assert_eq!(picker.highlight, 0);
        picker.step(Step::Last, 5, 3);
        assert_eq!(picker.highlight, 4);
        assert!(picker.open(Some(9), 5));
        assert_eq!(picker.highlight, 0, "a choice past the end opens on the first item");
    }

    #[test]
    fn only_a_commit_changes_the_value() {
        let mut picker = Picker::default();
        picker.open(Some(1), 5);
        picker.step(Step::Next, 5, 3);
        picker.close();
        assert!(!picker.open);
        assert_eq!(picker.commit(Some(1), 5), None, "closing keeps the choice");

        picker.open(Some(1), 5);
        picker.step(Step::Next, 5, 3);
        assert_eq!(picker.commit(Some(1), 5), Some(2));
        assert!(!picker.open);

        picker.open(Some(2), 5);
        assert_eq!(picker.commit(Some(2), 5), None, "the current choice again changes nothing");

        picker.open(Some(4), 5);
        assert_eq!(picker.commit(Some(0), 3), None, "an item gone from the list");
    }

    /// 16 languages and Match Windows at the default text size: 32px rows.
    const ROW: f32 = 36.;
    const LEN: usize = 17;

    fn wanted(row: f32) -> Pixels {
        px(row * (LEN as f32).min(MAX_ROWS) + LIST_CHROME)
    }

    #[test]
    fn the_list_opens_below_where_three_rows_fit() {
        // 900x680: the language box at about 352.
        let combo = Bounds::new(point(px(40.), px(352.)), size(px(352.), px(32.)));
        let place = placement(combo, px(680.), wanted(ROW), px(ROW), LEN, Some(0));
        assert_eq!(place, Placement { top: px(388.), max_height: px(284.), scroll: px(0.), over: false });
    }

    #[test]
    fn with_no_room_below_the_list_opens_over_the_box_and_never_over_the_title_bar() {
        // The 700x520 minimum, the box at about 376: the list goes over it,
        // clamped to the bottom bound and never above 40px.
        let combo = Bounds::new(point(px(40.), px(376.)), size(px(352.), px(32.)));
        let place = placement(combo, px(520.), wanted(ROW), px(ROW), LEN, Some(0));
        assert!(place.over);
        assert_eq!(place.max_height, wanted(ROW));
        assert_eq!(place.top, px(512.) - wanted(ROW));
        assert!(place.top >= px(40.));
        // A choice further down is scrolled into the list, as near the box as
        // the clamp allows.
        for index in [5, 12, 16] {
            let place = placement(combo, px(520.), wanted(ROW), px(ROW), LEN, Some(index));
            let row_top = px(FIRST_ROW_TOP) + px(ROW) * index as f32 - place.scroll;
            assert!(row_top >= px(0.) && row_top + px(ROW) <= place.max_height, "{index} is in view");
            assert!(place.top >= px(40.) && place.top + place.max_height <= px(512.));
        }
    }

    #[test]
    fn at_large_text_the_list_fills_the_room_under_the_title_bar_and_shows_the_choice() {
        // 225%: rows of 61px and a box about 94px tall, near the bottom.
        let row = 45. + ROW_PADDING + ROW_MARGIN;
        let combo = Bounds::new(point(px(40.), px(400.)), size(px(352.), px(94.)));
        for selected in [Some(0), Some(9), Some(16), None] {
            let place = placement(combo, px(520.), wanted(row), px(row), LEN, selected);
            assert!(place.over);
            assert_eq!(place.top, px(40.), "never over the 0-32px title bar");
            assert_eq!(place.max_height, px(472.));
            if let Some(index) = selected {
                let row_top = px(FIRST_ROW_TOP) + px(row) * index as f32 - place.scroll;
                assert!(row_top >= px(0.) && row_top + px(row) <= place.max_height, "{index} is in view");
            }
        }
    }
}
