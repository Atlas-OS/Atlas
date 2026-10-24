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
    let current = current_session()?;
    let own = account(WTS_CURRENT_SESSION);
    Ok(others_from(current, own.as_ref(), &sessions()?, account))
}

/// The choice behind [`others`]: `current` is this process's session, `own`
/// the account running Atlas, and `account` reads a session's account. Only
/// sessions that could count are read.
fn others_from(
    current: u32,
    own: Option<&Account>,
    sessions: &[(u32, WTS_CONNECTSTATE_CLASS)],
    account: impl Fn(u32) -> Option<Account>,
) -> Vec<String> {
    let mut names = Vec::new();
    for &(id, state) in sessions {
        if id == current || !(state == WTSActive || state == WTSDisconnected) {
            continue;
        }
        // A session with nobody signed in, such as the sign-in screen.
        let Some(person) = account(id) else { continue };
        if own.is_some_and(|own| own.same_as(&person)) {
            continue;
        }
        if !names.iter().any(|name: &String| name.to_lowercase() == person.user.to_lowercase()) {
            names.push(person.user);
        }
    }
    names
}

/// The session this process runs in.
fn current_session() -> Result<u32> {
    let mut current = 0;
    // SAFETY: plain out-parameter call for this process.
    unsafe { ProcessIdToSessionId(GetCurrentProcessId(), &mut current) }.context("read this session")?;
    Ok(current)
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
    use windows::Win32::System::RemoteDesktop::{WTSConnected, WTSIdle, WTSListen};

    use super::*;

    fn signed_in(domain: &str, user: &str) -> Option<Account> {
        Some(Account { domain: domain.into(), user: user.into() })
    }

    /// Atlas runs in session 1 as PC\morgan.
    fn morgan() -> Account {
        Account { domain: "PC".into(), user: "morgan".into() }
    }

    #[test]
    fn the_user_running_atlas_is_left_out_wherever_they_are_signed_in() {
        let sessions = [(1, WTSActive), (2, WTSDisconnected), (3, WTSDisconnected)];
        let account = |id: u32| match id {
            1 => signed_in("PC", "morgan"),
            2 => signed_in("pc", "MORGAN"),
            _ => signed_in("CORP", "morgan"),
        };
        // The same name from another domain is someone else.
        assert_eq!(others_from(1, Some(&morgan()), &sessions, account), ["morgan"]);
        // Atlas's own session doesn't count even when its account can't be read.
        assert!(others_from(1, None, &sessions[..1], account).is_empty());
    }

    /// Only a session someone is using or left disconnected still has their
    /// apps open.
    #[test]
    fn only_people_with_apps_open_count() {
        let sessions = [
            (0, WTSDisconnected),
            (2, WTSActive),
            (3, WTSDisconnected),
            (4, WTSListen),
            (5, WTSIdle),
            (6, WTSConnected),
        ];
        let account = |id: u32| match id {
            // Services: nobody signed in.
            0 => None,
            2 => signed_in("PC", "Alex"),
            3 => signed_in("PC", "Sam"),
            _ => signed_in("PC", "Robin"),
        };
        assert_eq!(others_from(1, Some(&morgan()), &sessions, account), ["Alex", "Sam"]);
    }

    #[test]
    fn each_person_is_listed_once() {
        let sessions = [(2, WTSActive), (3, WTSDisconnected)];
        let account = |id: u32| if id == 2 { signed_in("PC", "Alex") } else { signed_in("PC", "ALEX") };
        assert_eq!(others_from(1, Some(&morgan()), &sessions, account), ["Alex"]);
    }

    /// The Windows calls behind [`others`] on this PC. Who is signed in
    /// varies, but this process's own session is always listed, and its
    /// account can be read.
    #[test]
    fn this_pcs_sessions_include_the_one_running_the_tests() {
        let current = current_session().expect("read this session");
        let sessions = sessions().expect("list the sessions");
        assert!(sessions.iter().any(|&(id, _)| id == current), "{current} in {sessions:?}");
        // A lookup that never reads anyone would list nobody else either.
        let own = account(WTS_CURRENT_SESSION).expect("the account running the tests");
        assert!(account(current).is_some_and(|person| person.same_as(&own)), "session {current}");
        // Reading every session's account, signed in or not, must not crash.
        for (id, _) in sessions {
            let _ = account(id);
        }
    }
}
