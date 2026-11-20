# Accessibility

This page describes how Atlas Manager works with the keyboard, Narrator, contrast themes and text scaling.
It's for contributors who change controls or pages, and for reviewers who check them.

## Roles and names

Every control has an accessible role and name: buttons, links, radio groups, check boxes, combo boxes, toggle switches, headings, lists, status and alert regions, and the install log.
Accessible names come from the same [language catalog](i18n.md) as visible text.

Headings report their level, so Narrator's heading navigation follows the outline:

| Level | Heading |
| --- | --- |
| 1 | The page title. |
| 2 | A step heading, or one of a page's cards. |
| 3 | A card under a step. |

AccessKit's Windows adapter maps a level only to UI Automation's tree-item `Level`, so Atlas vendors it with a change that reports `HeadingLevel` ([AccessKit changes](../vendor/accesskit_windows/ATLAS-PATCH.md)).

Every node reports the app's language as its UI Automation culture, and each language in **Settings** > **Language** reports its own ([GPUI changes](../vendor/gpui-pre/ATLAS-PATCH.md#accessibility-states-live-regions-and-language)).

## Keyboard

- Tab and Shift+Tab move between controls.
  A radio group is one tab stop, and the arrow keys change its selection.
- Enter and Space activate a control.
- The focus ring is Windows' 2 px outer and 1 px inner ring.
- Page Up, Page Down, Ctrl+Home and Ctrl+End scroll the page.
- The install log is a tab stop that also scrolls with the arrow keys, Home and End.
- In a text box, Ctrl+Home and Ctrl+End jump to the start or end.
  In the report message, Page Up and Page Down move the caret a page.

### Combo boxes

A closed combo box ignores the arrow keys, so a value such as the app's language never changes as focus passes over it.

- Enter, Space, Alt+Down, Alt+Up or F4 opens the list.
- The arrow keys, Home, End, Page Up and Page Down move the highlight.
- Enter or Space commits the highlighted value.
- Escape or Tab closes the list without changing anything.

### Tooltips and dialogs

A tooltip appears after 500 ms of hover, or at once when its control takes keyboard focus.
It stays until the pointer or focus leaves, and Escape or a press dismisses it.

A close confirmation is a Fluent ContentDialog drawn over the window, in the app's theme and language.
Its safe answer, **Keep open**, is the rightmost button, uses the accent colour and has focus, and Escape chooses it.

## Focus and announcements

- Changing page or step moves focus to its heading.
- Install results take focus so Narrator announces them.
  Export results do too, if focus hasn't moved since the export started.
- Message bars that don't take focus are polite live regions, as are progress bars and the status of the installation files and the protection switches.
  Narrator reads them as they appear or change.

## Themes, text size and motion

- Contrast themes switch to the system colours, selected text included.
- The Windows text size setting (**Accessibility** > **Text size**) scales the type ramp.
- Turning off Windows animation effects stops the progress indicators moving.

The completion page's background animates whatever the animation setting says, because Atlas turns that setting off, and omits its artwork in contrast themes ([shader changes](../vendor/gpui-pre-windows/ATLAS-PATCH.md#completion-page-shader)).

## Checking

- `tools\Get-AccessibilityTree.ps1` prints what UI Automation, and so Narrator, sees, with focus and toggle states.
- `ATLAS_TEXT_SCALE` and `ATLAS_HIGH_CONTRAST` preview a text size or a contrast theme in debug builds without changing Windows.

[Review tools](review-tools.md) lists both and the other review hooks.
A UI Automation check doesn't show which voice Narrator uses for a non-English language, so release checks also listen with Narrator.
