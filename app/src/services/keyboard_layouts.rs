//! How many keyboard layouts this user can switch between, so Your choices
//! asks how to switch them only on a PC that has more than one.

use anyhow::Result;
use windows::Win32::UI::Input::KeyboardAndMouse::GetKeyboardLayoutList;

/// The input layouts Windows has loaded for this session: each keyboard
/// layout and input method of every language the user added, which Alt+Shift,
/// Ctrl+Shift and the taskbar's language selector cycle through. An elevated
/// copy of the app runs in the same session and sees the same list.
pub fn count() -> Result<usize> {
    // With no buffer, Windows only says how many there are.
    let count = unsafe { GetKeyboardLayoutList(None) };
    // A session always has at least one layout, so none means the call failed.
    anyhow::ensure!(count > 0, "Windows listed no keyboard layouts: {}", std::io::Error::last_os_error());
    Ok(count as usize)
}
