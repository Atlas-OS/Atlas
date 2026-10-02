//! Who else is signed in to this PC. A restart closes every session, so
//! Atlas asks before restarting over someone else's open apps.

use anyhow::{Context, Result};
use windows::Win32::System::RemoteDesktop::{
    ProcessIdToSessionId, WTS_CONNECTSTATE_CLASS, WTS_CURRENT_SERVER_HANDLE, WTS_CURRENT_SESSION,
    WTS_INFO_CLASS, WTS_SESSION_INFOW, WTSActive, WTSDisconnected, WTSDomainName, WTSEnumerateSessionsW,
    WTSFreeMemory, WTSQuerySessionInformationW, WTSUserName,
};
use windows::Win32::System::Threading::GetCurrentProcessId;
use windows::core::PWSTR;

/// The people signed in besides the user running Atlas, each once, by the
/// account name Windows shows. Only sessions someone is using or left
/// disconnected count: their apps are still open. The user's own sessions
/// elsewhere, such as a disconnected remote one, are left out.
///
/// Debug builds accept `ATLAS_REVIEW_OTHER_SESSIONS` (names separated by
/// commas) for design review, so the warning can be captured on a PC
/// nobody else uses.
pub fn others() -> Result<Vec<String>> {
    if cfg!(debug_assertions)
        && let Some(names) = std::env::var_os("ATLAS_REVIEW_OTHER_SESSIONS")
    {
        return Ok(names
            .to_string_lossy()
            .split(',')
            .map(str::trim)
            .filter(|name| !name.is_empty())
            .map(str::to_owned)
            .collect());
    }
    let mut current = 0;
    // SAFETY: plain out-parameter call for this process.
    unsafe { ProcessIdToSessionId(GetCurrentProcessId(), &mut current) }.context("read this session")?;
    let own = account(WTS_CURRENT_SESSION);
    let sessions = sessions()?;
    let mut names = Vec::new();
    for (id, state) in sessions {
        if id == current || !(state == WTSActive || state == WTSDisconnected) {
            continue;
        }
        // A session with nobody signed in, such as the sign-in screen.
        let Some(person) = account(id) else { continue };
        if own.as_ref().is_some_and(|own| own.same_as(&person)) {
            continue;
        }
        if !names.iter().any(|name: &String| name.to_lowercase() == person.user.to_lowercase()) {
            names.push(person.user);
        }
    }
    Ok(names)
}

/// Every session on this PC, with its state.
fn sessions() -> Result<Vec<(u32, WTS_CONNECTSTATE_CLASS)>> {
    let mut info: *mut WTS_SESSION_INFOW = std::ptr::null_mut();
    let mut count = 0u32;
    // SAFETY: Windows allocates the array; it is copied out, then freed once.
    unsafe {
        WTSEnumerateSessionsW(Some(WTS_CURRENT_SERVER_HANDLE), 0, 1, &mut info, &mut count)
            .context("list the sessions on this PC")?;
        let found = std::slice::from_raw_parts(info, count as usize)
            .iter()
            .map(|session| (session.SessionId, session.State))
            .collect();
        WTSFreeMemory(info.cast());
        Ok(found)
    }
}

/// An account signed in to a session.
struct Account {
    domain: String,
    user: String,
}

impl Account {
    /// Windows account names ignore case.
    fn same_as(&self, other: &Account) -> bool {
        self.domain.to_lowercase() == other.domain.to_lowercase()
            && self.user.to_lowercase() == other.user.to_lowercase()
    }
}

/// The account signed in to a session, or `None` when nobody is, or the
/// session can't be read.
fn account(session: u32) -> Option<Account> {
    let user = query(session, WTSUserName).filter(|user| !user.is_empty())?;
    Some(Account { domain: query(session, WTSDomainName).unwrap_or_default(), user })
}

fn query(session: u32, class: WTS_INFO_CLASS) -> Option<String> {
    let mut buffer = PWSTR::null();
    let mut bytes = 0u32;
    // SAFETY: Windows allocates the string; it is copied out, then freed once.
    unsafe {
        WTSQuerySessionInformationW(Some(WTS_CURRENT_SERVER_HANDLE), session, class, &mut buffer, &mut bytes)
            .ok()?;
        let text = buffer.to_string().ok();
        WTSFreeMemory(buffer.0.cast());
        text
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Whoever runs the tests is signed in; who else is depends on the PC,
    /// but never includes them.
    #[test]
    fn the_user_running_atlas_is_never_someone_else() {
        let others = others().expect("read the sessions");
        let own = account(WTS_CURRENT_SESSION).expect("the account running the tests");
        assert!(!others.iter().any(|name| name.eq_ignore_ascii_case(&own.user)), "{others:?}");
    }
}
