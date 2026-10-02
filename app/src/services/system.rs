//! Facts about the machine: Windows version, elevation, power, connectivity,
//! process liveness and the accessibility preferences the UI honours.

use std::ops::RangeInclusive;
use std::os::windows::process::CommandExt;
use std::path::PathBuf;

use anyhow::{Context, Result};
use windows::Win32::Foundation::{
    CloseHandle, ERROR_ACCESS_DENIED, ERROR_INVALID_PARAMETER, FILETIME, HANDLE, HWND, STILL_ACTIVE,
    WIN32_ERROR,
};
use windows::Win32::Graphics::Gdi::{
    COLOR_BTNFACE, COLOR_BTNTEXT, COLOR_GRAYTEXT, COLOR_HIGHLIGHT, COLOR_HIGHLIGHTTEXT, COLOR_HOTLIGHT,
    COLOR_WINDOW, COLOR_WINDOWTEXT, GetSysColor, SYS_COLOR_INDEX,
};
use windows::Win32::Networking::WinInet::{INTERNET_CONNECTION, InternetGetConnectedState};
use windows::Win32::Security::{
    EqualSid, GetTokenInformation, TOKEN_ELEVATION, TOKEN_ELEVATION_TYPE, TOKEN_QUERY, TokenElevation,
    TokenElevationType, TokenElevationTypeDefault, TokenElevationTypeFull, TokenElevationTypeLimited,
};
use windows::Win32::System::Power::{GetSystemPowerStatus, SYSTEM_POWER_STATUS};
use windows::Win32::System::RemoteDesktop::{
    WTS_CURRENT_SERVER_HANDLE, WTS_PROCESS_INFO_EXW, WTSEnumerateProcessesExW, WTSFreeMemoryExW,
    WTSTypeProcessInfoLevel1,
};
use windows::Win32::System::SystemInformation::GetTickCount64;
use windows::Win32::System::Threading::{
    CREATE_NO_WINDOW, GetCurrentProcess, GetExitCodeProcess, GetProcessTimes, OpenProcess, OpenProcessToken,
    PROCESS_QUERY_LIMITED_INFORMATION,
};
use windows::Win32::UI::Accessibility::{HCF_HIGHCONTRASTON, HIGHCONTRASTW};
use windows::Win32::UI::Shell::ShellExecuteW;
use windows::Win32::UI::WindowsAndMessaging::{
    SPI_GETCLIENTAREAANIMATION, SPI_GETHIGHCONTRAST, SW_SHOWNORMAL, SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS,
    SystemParametersInfoW,
};
use windows::core::{HSTRING, PCWSTR, PWSTR};
use windows_registry::{CURRENT_USER, LOCAL_MACHINE};

/// The Windows release this app is running on, read once at startup.
#[derive(Clone, Debug, Default)]
pub struct SystemInfo {
    /// Marketing name, for example "Windows 11 Pro".
    pub product_name: String,
    /// Feature release label, for example "25H2".
    pub display_version: String,
    /// Major build number, for example 26200.
    pub build: u32,
    /// Update build revision, the number after the dot.
    pub revision: u32,
    pub edition_id: String,
    pub installation_type: String,
    pub build_lab: String,
}

impl SystemInfo {
    pub fn read() -> Self {
        let Ok(key) = LOCAL_MACHINE.open(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion") else {
            return Self::default();
        };
        // The registry still reports "Windows 10" on Windows 11; the build number is the truth.
        let build: u32 = key
            .get_string("CurrentBuildNumber")
            .ok()
            .and_then(|value| value.parse().ok())
            .unwrap_or_default();
        let mut product_name = key.get_string("ProductName").unwrap_or_default();
        if build >= 22000 {
            product_name = product_name.replace("Windows 10", "Windows 11");
        }
        Self {
            product_name,
            display_version: key.get_string("DisplayVersion").unwrap_or_default(),
            build,
            revision: key.get_u32("UBR").unwrap_or_default(),
            edition_id: key.get_string("EditionID").unwrap_or_default(),
            installation_type: key.get_string("InstallationType").unwrap_or_default(),
            build_lab: key.get_string("BuildLabEx").unwrap_or_default(),
        }
    }

    pub fn supported_edition(&self) -> bool {
        let edition = self.edition_id.to_ascii_lowercase();
        self.installation_type.eq_ignore_ascii_case("Client")
            && !edition.trim().is_empty()
            && !edition.starts_with("core")
            && !matches!(
                edition.as_str(),
                "enterprises"
                    | "enterprisesn"
                    | "enterpriseseval"
                    | "enterprisesneval"
                    | "iotenterprises"
                    | "iotenterprisesk"
            )
    }

    /// "26200.1234": the build with its update revision, as text, so it is
    /// never grouped like a quantity.
    pub fn build_label(&self) -> String {
        format!("{}.{}", self.build, self.revision)
    }
}

/// Whether the current process token is elevated (running as administrator).
pub fn is_elevated() -> bool {
    unsafe {
        let mut token = HANDLE::default();
        if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token).is_err() {
            return false;
        }
        let mut elevation = TOKEN_ELEVATION::default();
        let mut returned = 0u32;
        let result = GetTokenInformation(
            token,
            TokenElevation,
            Some(&mut elevation as *mut _ as *mut _),
            std::mem::size_of::<TOKEN_ELEVATION>() as u32,
            &mut returned,
        );
        let _ = CloseHandle(token);
        result.is_ok() && elevation.TokenIsElevated != 0
    }
}

/// Whether UAC is on and in effect for this token. EnableLUA alone is not
/// enough: UAC turned back on takes effect only after a restart, and until
/// then an administrator has no limited token to run the user's part with.
pub fn user_account_ready() -> Result<bool> {
    let enabled = LOCAL_MACHINE
        .open(r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System")?
        .get_u32("EnableLUA")?;
    unsafe {
        let mut token = HANDLE::default();
        OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token)?;
        let result = (|| -> Result<bool> {
            let mut kind = TOKEN_ELEVATION_TYPE::default();
            let mut elevation = TOKEN_ELEVATION::default();
            let mut returned = 0;
            GetTokenInformation(
                token,
                TokenElevationType,
                Some(&mut kind as *mut _ as *mut _),
                std::mem::size_of_val(&kind) as u32,
                &mut returned,
            )?;
            GetTokenInformation(
                token,
                TokenElevation,
                Some(&mut elevation as *mut _ as *mut _),
                std::mem::size_of_val(&elevation) as u32,
                &mut returned,
            )?;
            Ok(user_account_token_ready(enabled, kind, elevation.TokenIsElevated != 0))
        })();
        let _ = CloseHandle(token);
        result
    }
}

/// A split token (full or limited) means UAC is in effect. A default token
/// is fine for a standard user, never for an unfiltered administrator.
fn user_account_token_ready(enabled: u32, kind: TOKEN_ELEVATION_TYPE, elevated: bool) -> bool {
    enabled == 1
        && (kind == TokenElevationTypeFull
            || kind == TokenElevationTypeLimited
            || (kind == TokenElevationTypeDefault && !elevated))
}

pub(crate) fn shell_execute(verb: &str, target: &str) -> Result<()> {
    shell_execute_with_args(verb, target, "")
}

fn shell_execute_with_args(verb: &str, target: &str, args: &str) -> Result<()> {
    let verb = HSTRING::from(verb);
    let target = HSTRING::from(target);
    let args = HSTRING::from(args);
    let result = unsafe {
        ShellExecuteW(
            None::<HWND>,
            PCWSTR(verb.as_ptr()),
            PCWSTR(target.as_ptr()),
            PCWSTR(args.as_ptr()),
            PCWSTR::null(),
            SW_SHOWNORMAL,
        )
    };
    // ShellExecute reports success with a value above 32.
    if result.0 as usize > 32 {
        Ok(())
    } else {
        anyhow::bail!("Windows could not open {target} (code {})", result.0 as usize)
    }
}

/// Starts a second, elevated copy of this executable through the UAC prompt.
/// The caller quits afterwards; the new instance takes over.
pub fn relaunch_elevated() -> Result<()> {
    let exe = std::env::current_exe().context("locate the running executable")?;
    shell_execute("runas", &exe.to_string_lossy())
}

/// Relaunches elevated on the install page, with `--playbook` if given. A
/// quote or a trailing backslash would end the quoted argument early, so such
/// a path is refused.
pub fn relaunch_setup_elevated(playbook: Option<&std::path::Path>) -> Result<()> {
    let exe = std::env::current_exe()?;
    let mut args = String::from("--page install");
    if let Some(path) = playbook {
        let path = path.to_string_lossy();
        anyhow::ensure!(!path.contains('"') && !path.ends_with('\\'), "invalid package path");
        args.push_str(&format!(" --playbook \"{path}\""));
    }
    shell_execute_with_args("runas", &exe.to_string_lossy(), &args)
}

pub fn relaunch_iso_elevated() -> Result<()> {
    let exe = std::env::current_exe()?;
    shell_execute_with_args("runas", &exe.to_string_lossy(), "--page iso")
}

/// The Windows directory, from `SystemRoot`.
pub fn windows_dir() -> PathBuf {
    std::env::var_os("SystemRoot").map(PathBuf::from).unwrap_or_else(|| PathBuf::from(r"C:\Windows"))
}

/// The longest restart notice `shutdown.exe /c` accepts.
const SHUTDOWN_COMMENT_MAX: usize = 512;

/// Restarts Windows immediately; any countdown or warning belongs to the
/// caller. `comment` is the message Windows shows in its restart notice;
/// `shutdown.exe` refuses control characters and anything past
/// [`SHUTDOWN_COMMENT_MAX`], so those are dropped.
///
/// Debug builds accept `ATLAS_REVIEW_NO_RESTART` for design review: the
/// restart is logged and reported as requested, and Windows keeps running,
/// so a capture of a countdown or a Restart now button can never restart
/// the reviewer's PC.
pub fn schedule_restart(comment: &str) -> Result<()> {
    if cfg!(debug_assertions) && std::env::var_os("ATLAS_REVIEW_NO_RESTART").is_some() {
        log::warn!("ATLAS_REVIEW_NO_RESTART is set; not restarting Windows");
        return Ok(());
    }
    super::desktop_setup::note_restart()?;
    let comment: String = comment.chars().filter(|c| !c.is_control()).take(SHUTDOWN_COMMENT_MAX).collect();
    accept_restart_under_way(shutdown(&["/r", "/t", "0", "/c", comment.trim()]))
}

/// ERROR_SHUTDOWN_IN_PROGRESS and ERROR_SHUTDOWN_IS_SCHEDULED: Windows is
/// already shutting down or restarting, so another window's request, or a
/// second press, isn't refused: the restart is under way.
const RESTART_UNDER_WAY: [i32; 2] = [1115, 1190];

fn accept_restart_under_way(result: Result<()>) -> Result<()> {
    match result {
        Err(error)
            if error
                .downcast_ref::<ShutdownFailed>()
                .is_some_and(|failed| failed.code.is_some_and(|code| RESTART_UNDER_WAY.contains(&code))) =>
        {
            log::info!("a restart is already under way: {error:#}");
            Ok(())
        }
        other => other,
    }
}

/// `shutdown.exe` exited with an error.
#[derive(Debug)]
pub struct ShutdownFailed {
    pub code: Option<i32>,
    pub message: String,
}

impl std::fmt::Display for ShutdownFailed {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} (exit code {:?})", self.message, self.code)
    }
}

impl std::error::Error for ShutdownFailed {}

fn shutdown(arguments: &[&str]) -> Result<()> {
    let output = std::process::Command::new(windows_dir().join(r"System32\shutdown.exe"))
        .args(arguments)
        .creation_flags(CREATE_NO_WINDOW.0)
        .output()
        .context("run shutdown.exe")?;
    if output.status.success() {
        Ok(())
    } else {
        let text = String::from_utf8_lossy(&output.stderr);
        let text = if text.trim().is_empty() { String::from_utf8_lossy(&output.stdout) } else { text };
        Err(ShutdownFailed { code: output.status.code(), message: text.trim().to_owned() }.into())
    }
}

/// Power source, if the machine reports one.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PowerSource {
    /// Mains power, or a desktop with no battery at all.
    Mains,
    Battery,
    Unknown,
}

pub fn power_source() -> PowerSource {
    let mut status = SYSTEM_POWER_STATUS::default();
    if unsafe { GetSystemPowerStatus(&mut status) }.is_err() {
        return PowerSource::Unknown;
    }
    classify_power(status.BatteryFlag, status.ACLineStatus)
}

fn classify_power(battery: u8, ac: u8) -> PowerSource {
    // BatteryFlag 128 means "no system battery"; ACLineStatus 1 means online.
    if battery != 255 && battery & 128 != 0 {
        return PowerSource::Mains;
    }
    match ac {
        1 => PowerSource::Mains,
        0 => PowerSource::Battery,
        _ => PowerSource::Unknown,
    }
}

/// Whether WinInet believes the machine has a network route to the internet.
pub fn internet_connected() -> bool {
    let mut flags = INTERNET_CONNECTION(0);
    unsafe { InternetGetConnectedState(&mut flags, None) }.is_ok()
}

struct ProcessHandle(HANDLE);

impl ProcessHandle {
    fn open(pid: u32) -> windows::core::Result<Self> {
        unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid) }.map(Self)
    }

    fn creation_time(&self) -> Option<u64> {
        let mut creation = FILETIME::default();
        let mut exit = FILETIME::default();
        let mut kernel = FILETIME::default();
        let mut user = FILETIME::default();
        unsafe { GetProcessTimes(self.0, &mut creation, &mut exit, &mut kernel, &mut user) }.ok()?;
        Some(((creation.dwHighDateTime as u64) << 32) | creation.dwLowDateTime as u64)
    }

    fn is_running(&self) -> windows::core::Result<bool> {
        let mut code = 0u32;
        unsafe { GetExitCodeProcess(self.0, &mut code) }?;
        Ok(code == STILL_ACTIVE.0 as u32)
    }
}

impl Drop for ProcessHandle {
    fn drop(&mut self) {
        unsafe {
            let _ = CloseHandle(self.0);
        }
    }
}

/// The creation time of a process, as a FILETIME value. Together with the
/// PID this identifies a process even after the PID is reused.
pub fn process_start_time(pid: u32) -> Option<u64> {
    ProcessHandle::open(pid).ok()?.creation_time()
}

/// Whether a recorded process is still running. Absence is only concluded
/// from Windows saying there is no such process, or that it has exited, or
/// that the PID now belongs to a process created at another time. A refusal
/// to answer (access denied, say) is reported as such, never as "ended".
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Liveness {
    Alive,
    Ended,
    Unknown(String),
}

pub fn process_liveness(pid: u32, start_time: u64) -> Liveness {
    let handle = match ProcessHandle::open(pid) {
        Ok(handle) => handle,
        // OpenProcess answers "invalid parameter" for a PID no process has.
        Err(error) if WIN32_ERROR::from_error(&error) == Some(ERROR_INVALID_PARAMETER) => {
            return Liveness::Ended;
        }
        // A process this one may not open, in someone else's session say,
        // is never one Atlas started.
        Err(error)
            if WIN32_ERROR::from_error(&error) == Some(ERROR_ACCESS_DENIED)
                && process_is_elsewhere(pid) == Some(true) =>
        {
            return Liveness::Ended;
        }
        Err(error) => return Liveness::Unknown(format!("open process {pid}: {error}")),
    };
    match handle.is_running() {
        Ok(false) => return Liveness::Ended,
        Err(error) => return Liveness::Unknown(format!("query process {pid}: {error}")),
        Ok(true) => {}
    }
    match handle.creation_time() {
        Some(actual) if start_time == 0 || actual == start_time => Liveness::Alive,
        Some(_) => Liveness::Ended,
        None => Liveness::Unknown(format!("query creation time for process {pid}")),
    }
}

/// Whether the process using `pid` belongs to another session, or to another
/// account, than this process. Atlas only follows processes it started in its
/// own session, as its own user, and Windows gives each user one session, so
/// such a process has taken the PID over. Read from the list Remote Desktop
/// Services keeps of every session's processes, which needs no access to the
/// process. `None` when Windows doesn't say: the list can't be read, lacks
/// the PID, or names no account where the sessions match.
fn process_is_elsewhere(pid: u32) -> Option<bool> {
    /// WTS_ANY_SESSION: every session's processes.
    const ANY_SESSION: u32 = 0xFFFF_FFFE;
    let mut level = 1u32;
    let mut list = PWSTR::null();
    let mut count = 0u32;
    // SAFETY: Windows allocates `count` level-1 entries at `list`; they are
    // read in place, then freed once.
    unsafe {
        WTSEnumerateProcessesExW(
            Some(WTS_CURRENT_SERVER_HANDLE),
            &mut level,
            ANY_SESSION,
            &mut list,
            &mut count,
        )
        .ok()?;
        if list.is_null() {
            return None;
        }
        let processes = std::slice::from_raw_parts(list.0 as *const WTS_PROCESS_INFO_EXW, count as usize);
        let find = |id: u32| processes.iter().find(|process| process.ProcessId == id);
        let answer = find(std::process::id()).zip(find(pid)).and_then(|(own, other)| {
            if own.SessionId != other.SessionId {
                Some(true)
            } else if own.pUserSid.is_invalid() || other.pUserSid.is_invalid() {
                None
            } else {
                Some(EqualSid(own.pUserSid, other.pUserSid).is_err())
            }
        });
        let _ = WTSFreeMemoryExW(WTSTypeProcessInfoLevel1, list.0 as *const _, count);
        answer
    }
}

/// Whether the process with this PID and creation time is still running.
/// Unknown counts as not alive here; callers that must not guess use
/// [`process_liveness`].
#[cfg(test)]
pub fn process_alive(pid: u32, start_time: u64) -> bool {
    process_liveness(pid, start_time) == Liveness::Alive
}

/// Whether Windows has started since `moment` (an RFC 3339 timestamp), from
/// the time elapsed since boot. A timestamp that cannot be read answers
/// `false`, so nothing is discarded on a guess.
pub fn booted_since(moment: &str) -> bool {
    let Ok(moment) = chrono::DateTime::parse_from_rfc3339(moment) else { return false };
    let uptime = std::time::Duration::from_millis(unsafe { GetTickCount64() });
    let booted = chrono::Utc::now() - chrono::Duration::from_std(uptime).unwrap_or_default();
    // One second of slack covers the gap between reading the clock and the
    // uptime. More would miss a quick install followed by a restart.
    booted - chrono::Duration::seconds(1) > moment.with_timezone(&chrono::Utc)
}

/// Ease of Access settings that change how the UI should draw.
#[derive(Clone, Debug, PartialEq)]
pub struct AccessibilityPreferences {
    /// A Windows contrast theme is active; use the system colours.
    pub high_contrast: bool,
    /// "Show animations in Windows" is off.
    pub reduce_motion: bool,
    /// The "Text size" slider, within [`TEXT_SCALE`].
    pub text_scale: f32,
    /// System colours to draw with while a contrast theme is active.
    pub system_colors: Option<SystemColors>,
}

/// The range of Settings > Accessibility > Text size.
const TEXT_SCALE: RangeInclusive<f32> = 1.0..=2.25;

impl Default for AccessibilityPreferences {
    fn default() -> Self {
        Self { high_contrast: false, reduce_motion: false, text_scale: 1.0, system_colors: None }
    }
}

/// The contrast theme's palette, as 0xRRGGBB.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SystemColors {
    pub window: u32,
    pub window_text: u32,
    pub button_face: u32,
    pub button_text: u32,
    pub highlight: u32,
    pub highlight_text: u32,
    pub gray_text: u32,
    pub hot_light: u32,
}

impl AccessibilityPreferences {
    /// Debug builds accept `ATLAS_TEXT_SCALE` (1.0 to 2.25) and
    /// `ATLAS_HIGH_CONTRAST` (any value, a dark contrast palette) for design
    /// review, so these settings can be checked without changing Windows.
    pub fn read() -> Self {
        let review = |name| cfg!(debug_assertions).then(|| std::env::var(name).ok()).flatten();
        let review_contrast = review("ATLAS_HIGH_CONTRAST").is_some();
        let high_contrast = review_contrast || high_contrast_on();
        Self {
            high_contrast,
            reduce_motion: !client_area_animation(),
            text_scale: review("ATLAS_TEXT_SCALE")
                .and_then(|scale| scale.parse::<f32>().ok())
                .map_or_else(text_scale, |scale| scale.clamp(*TEXT_SCALE.start(), *TEXT_SCALE.end())),
            system_colors: high_contrast
                .then(|| if review_contrast { SystemColors::REVIEW } else { SystemColors::read() }),
        }
    }
}

fn high_contrast_on() -> bool {
    let mut info =
        HIGHCONTRASTW { cbSize: std::mem::size_of::<HIGHCONTRASTW>() as u32, ..Default::default() };
    let ok = unsafe {
        SystemParametersInfoW(
            SPI_GETHIGHCONTRAST,
            info.cbSize,
            Some(&mut info as *mut _ as *mut _),
            SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0),
        )
    }
    .is_ok();
    ok && info.dwFlags.0 & HCF_HIGHCONTRASTON.0 != 0
}

fn client_area_animation() -> bool {
    let mut enabled = windows::core::BOOL(1);
    let ok = unsafe {
        SystemParametersInfoW(
            SPI_GETCLIENTAREAANIMATION,
            0,
            Some(&mut enabled as *mut _ as *mut _),
            SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0),
        )
    }
    .is_ok();
    !ok || enabled.as_bool()
}

/// Settings > Accessibility > Text size, stored as a percentage.
fn text_scale() -> f32 {
    CURRENT_USER
        .open(r"SOFTWARE\Microsoft\Accessibility")
        .and_then(|key| key.get_u32("TextScaleFactor"))
        .map(|percent| (percent as f32 / 100.0).clamp(*TEXT_SCALE.start(), *TEXT_SCALE.end()))
        .unwrap_or(1.0)
}

impl SystemColors {
    /// A dark contrast palette for review builds; see `AccessibilityPreferences::read`.
    const REVIEW: Self = Self {
        window: 0x000000,
        window_text: 0xFFFFFF,
        button_face: 0x000000,
        button_text: 0xFFFFFF,
        highlight: 0xD6B4FD,
        highlight_text: 0x2B2B2B,
        gray_text: 0xA6A6A6,
        hot_light: 0xFFFF00,
    };

    fn read() -> Self {
        fn color(index: SYS_COLOR_INDEX) -> u32 {
            // GetSysColor returns COLORREF (0x00BBGGRR).
            let bgr = unsafe { GetSysColor(index) };
            ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF)
        }
        Self {
            window: color(COLOR_WINDOW),
            window_text: color(COLOR_WINDOWTEXT),
            button_face: color(COLOR_BTNFACE),
            button_text: color(COLOR_BTNTEXT),
            highlight: color(COLOR_HIGHLIGHT),
            highlight_text: color(COLOR_HIGHLIGHTTEXT),
            gray_text: color(COLOR_GRAYTEXT),
            hot_light: color(COLOR_HOTLIGHT),
        }
    }
}

/// Flashes the window's taskbar button, and its caption, until the user
/// brings it to the front: a restart countdown started while nobody looks.
/// It never takes focus or restores a minimised window.
pub fn flash_until_foreground(window: &gpui::Window) {
    use raw_window_handle::{HasWindowHandle, RawWindowHandle};
    use windows::Win32::UI::WindowsAndMessaging::{FLASHW_ALL, FLASHW_TIMERNOFG, FLASHWINFO, FlashWindowEx};
    let Ok(handle) = HasWindowHandle::window_handle(window) else { return };
    let RawWindowHandle::Win32(handle) = handle.as_raw() else { return };
    let info = FLASHWINFO {
        cbSize: std::mem::size_of::<FLASHWINFO>() as u32,
        hwnd: HWND(handle.hwnd.get() as *mut _),
        dwFlags: FLASHW_ALL | FLASHW_TIMERNOFG,
        // Until the window comes to the front.
        uCount: 0,
        dwTimeout: 0,
    };
    // SAFETY: the window handle is GPUI's own, alive while `window` is.
    let _ = unsafe { FlashWindowEx(&info) };
}

/// Well-known shell targets used by the UI.
pub mod links {
    pub const WINDOWS_SECURITY_PROTECTION: &str = "windowsdefender://threatsettings";
    pub const WINDOWS_UPDATE: &str = "ms-settings:windowsupdate";
    pub const NETWORK: &str = "ms-settings:network";
    pub const POWER: &str = "ms-settings:powersleep";
    pub const ACTIVATION: &str = "ms-settings:activation";
    pub const DOCS: &str = "https://docs.atlasos.net/";
    pub const GITHUB: &str = "https://github.com/Atlas-OS/Atlas";
    pub const RELEASES: &str = "https://github.com/Atlas-OS/Atlas/releases";
    pub const DISCORD: &str = "https://discord.atlasos.net/";
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_restart_already_under_way_is_not_a_refusal() {
        let failed =
            |code| -> Result<()> { Err(ShutdownFailed { code: Some(code), message: "x".into() }.into()) };
        assert!(accept_restart_under_way(failed(1115)).is_ok(), "shutting down already");
        assert!(accept_restart_under_way(failed(1190)).is_ok(), "already scheduled");
        assert!(accept_restart_under_way(failed(5)).is_err(), "access denied is still a refusal");
        assert!(accept_restart_under_way(Err(anyhow::anyhow!("no shutdown.exe"))).is_err());
    }

    /// The edition gate exists three times: here, in ISO creation and in the
    /// front door script, `Install-Atlas.ps1`. They must refuse the same LTSC
    /// editions (and every Core* edition), because the app's edition advice
    /// is worded from this one.
    #[test]
    fn every_edition_gate_refuses_the_same_editions() {
        let edition = |id: &str| {
            SystemInfo { edition_id: id.into(), installation_type: "Client".into(), ..Default::default() }
                .supported_edition()
        };
        let iso = include_str!("../../resources/iso/Build-Iso.ps1");
        let iso_line = iso.lines().find(|line| line.contains("$edition -like 'Core*'")).expect("ISO gate");
        let iso_list = &iso_line[iso_line.find("-in @(").expect("ISO list") + 6..];
        let iso_ids: Vec<&str> = iso_list[..iso_list.find(')').unwrap()]
            .split(',')
            .map(|id| id.trim().trim_matches('\''))
            .collect();
        let direct =
            include_str!("../../../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
        let direct_line =
            direct.lines().find(|line| line.contains("$EditionId -notlike 'Core*'")).expect("direct gate");
        let direct_list = &direct_line[direct_line.find("'^(").expect("direct list") + 3..];
        let direct_ids: Vec<&str> = direct_list[..direct_list.find(")$'").unwrap()].split('|').collect();
        assert_eq!(iso_ids, direct_ids);
        assert!(iso_ids.len() >= 6, "{iso_ids:?}");
        for id in iso_ids.iter().copied().chain(["Core", "CoreN", "CoreSingleLanguage"]) {
            assert!(!edition(id), "{id} passes the app's gate");
        }
        for id in
            ["Professional", "ProfessionalWorkstation", "Education", "ProfessionalEducation", "Enterprise"]
        {
            assert!(edition(id), "{id} fails the app's gate");
        }
    }

    #[test]
    fn uac_requires_both_policy_and_a_usable_user_token() {
        assert!(user_account_token_ready(1, TokenElevationTypeFull, true));
        assert!(user_account_token_ready(1, TokenElevationTypeLimited, false));
        assert!(user_account_token_ready(1, TokenElevationTypeDefault, false));
        // UAC disabled; re-enabled without restarting; unfiltered built-in Administrator.
        assert!(!user_account_token_ready(0, TokenElevationTypeDefault, true));
        assert!(!user_account_token_ready(1, TokenElevationTypeDefault, true));
        assert!(!user_account_token_ready(0, TokenElevationTypeFull, true));
        assert!(!user_account_token_ready(2, TokenElevationTypeFull, true));
        assert!(!user_account_token_ready(1, TOKEN_ELEVATION_TYPE(0), false));
    }

    #[test]
    fn unknown_battery_flags_do_not_mean_no_battery() {
        assert_eq!(classify_power(255, 255), PowerSource::Unknown);
        assert_eq!(classify_power(255, 1), PowerSource::Mains);
        assert_eq!(classify_power(255, 0), PowerSource::Battery);
        assert_eq!(classify_power(128, 255), PowerSource::Mains);
        assert_eq!(classify_power(1, 0), PowerSource::Battery);
    }

    #[test]
    fn the_current_process_is_alive_and_a_stale_start_time_is_not() {
        let pid = std::process::id();
        let start = process_start_time(pid).expect("own creation time");
        assert!(process_alive(pid, start));
        assert!(process_alive(pid, 0), "an unknown start time only checks the PID");
        assert!(!process_alive(pid, start.wrapping_add(1)), "a different creation time is another process");
    }

    #[test]
    fn a_finished_process_is_reported_dead() {
        let mut child = std::process::Command::new("cmd.exe")
            .args(["/c", "exit 0"])
            .spawn()
            .expect("start a disposable Windows command process");
        let pid = child.id();
        let start = process_start_time(pid).expect("child creation time");
        child.wait().unwrap();
        assert!(!process_alive(pid, start));
    }

    #[test]
    fn a_pid_nobody_has_is_ended() {
        // PIDs are multiples of four; an odd one can never name a process.
        assert_eq!(process_liveness(0x7FFF_FFF1, 0), Liveness::Ended);
        assert_eq!(process_liveness(std::process::id(), 0), Liveness::Alive);
    }

    /// After fast user switching, a PID Atlas recorded can belong to a process
    /// in the other person's session that this one may not open. It is
    /// another process, not one still running for Atlas.
    #[test]
    fn a_pid_taken_over_in_another_session_is_ended() {
        assert_eq!(process_is_elsewhere(std::process::id()), Some(false));
        // The System process (4) always runs in session 0, never a user's.
        assert_eq!(process_is_elsewhere(4), Some(true));
        let start = process_start_time(4).unwrap_or(1);
        assert_eq!(
            process_liveness(4, start),
            if ProcessHandle::open(4).is_ok() { Liveness::Alive } else { Liveness::Ended },
            "refused or not, its own start time is the only way it counts as running"
        );
    }

    #[test]
    fn boot_time_is_compared_against_a_moment() {
        assert!(booted_since("2001-01-01T00:00:00+00:00"), "the PC booted after 2001");
        assert!(!booted_since(&chrono::Local::now().to_rfc3339()), "not since a moment ago");
        assert!(!booted_since("not a time"), "an unreadable time never claims a boot");
    }
}
