//! Facts about the machine: Windows version, elevation, power, connectivity,
//! process liveness and the accessibility preferences the UI honours.

use anyhow::{Context, Result};
use windows::Win32::Foundation::{CloseHandle, FILETIME, HANDLE, HWND, STILL_ACTIVE};
use windows::Win32::Graphics::Gdi::{
    COLOR_BTNFACE, COLOR_BTNTEXT, COLOR_GRAYTEXT, COLOR_HIGHLIGHT, COLOR_HIGHLIGHTTEXT, COLOR_HOTLIGHT,
    COLOR_WINDOW, COLOR_WINDOWTEXT, GetSysColor, SYS_COLOR_INDEX,
};
use windows::Win32::Networking::WinInet::{INTERNET_CONNECTION, InternetGetConnectedState};
use windows::Win32::Security::{GetTokenInformation, TOKEN_ELEVATION, TOKEN_QUERY, TokenElevation};
use windows::Win32::System::Power::{GetSystemPowerStatus, SYSTEM_POWER_STATUS};
use windows::Win32::System::SystemInformation::GetTickCount64;
use windows::Win32::System::Threading::{
    GetCurrentProcess, GetExitCodeProcess, GetProcessTimes, OpenProcess, OpenProcessToken,
    PROCESS_QUERY_LIMITED_INFORMATION,
};
use windows::Win32::UI::Accessibility::{HCF_HIGHCONTRASTON, HIGHCONTRASTW};
use windows::Win32::UI::Shell::ShellExecuteW;
use windows::Win32::UI::WindowsAndMessaging::{
    SPI_GETCLIENTAREAANIMATION, SPI_GETHIGHCONTRAST, SW_SHOWNORMAL, SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS,
    SystemParametersInfoW,
};
use windows::core::{HSTRING, PCWSTR};
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

fn shell_execute(verb: &str, target: &str) -> Result<()> {
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

pub fn relaunch_iso_elevated() -> Result<()> {
    let exe = std::env::current_exe()?;
    shell_execute_with_args("runas", &exe.to_string_lossy(), "--page iso")
}

pub fn powershell_path() -> std::path::PathBuf {
    std::env::var_os("SystemRoot")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| std::path::PathBuf::from(r"C:\Windows"))
        .join(r"System32\WindowsPowerShell\v1.0\powershell.exe")
}

/// Keep cancellation cooperative so workers can finish servicing and release mounted media.
pub fn watch_cancellation(
    cancel: std::sync::Arc<std::sync::atomic::AtomicBool>,
    stop: std::sync::Arc<std::sync::atomic::AtomicBool>,
    marker: std::path::PathBuf,
) -> std::thread::JoinHandle<()> {
    std::thread::spawn(move || {
        use std::sync::atomic::Ordering;
        let mut reported = false;
        while !stop.load(Ordering::Relaxed) {
            if cancel.load(Ordering::Relaxed) {
                match std::fs::File::create(&marker) {
                    Ok(_) => break,
                    Err(error) if !reported => {
                        log::error!(
                            "could not signal cancellation at {}: {error}; retrying",
                            marker.display()
                        );
                        reported = true;
                    }
                    Err(_) => {}
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
    })
}

#[cfg(test)]
mod cancellation_tests {
    use super::watch_cancellation;
    use std::sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    };
    use std::time::{Duration, Instant};

    #[test]
    fn unknown_battery_flags_do_not_mean_no_battery() {
        use super::{PowerSource, classify_power};
        assert_eq!(classify_power(255, 255), PowerSource::Unknown);
        assert_eq!(classify_power(255, 1), PowerSource::Mains);
        assert_eq!(classify_power(255, 0), PowerSource::Battery);
        assert_eq!(classify_power(128, 255), PowerSource::Mains);
        assert_eq!(classify_power(1, 0), PowerSource::Battery);
    }

    #[test]
    fn cancellation_retries_a_failed_marker_write_until_the_directory_is_writable() {
        let temp = super::super::test_support::TempDir::new("cancel-retry");
        let parent = temp.path().join("not-yet-created");
        let marker = parent.join("cancel");
        assert!(std::fs::File::create(&marker).is_err());
        let stop = Arc::new(AtomicBool::new(false));
        let watcher = watch_cancellation(Arc::new(AtomicBool::new(true)), stop.clone(), marker.clone());
        std::thread::sleep(Duration::from_millis(150));
        let before_repair = marker.exists();
        std::fs::create_dir(&parent).unwrap();
        let deadline = Instant::now() + Duration::from_secs(3);
        while !marker.exists() && Instant::now() < deadline {
            std::thread::sleep(Duration::from_millis(20));
        }
        stop.store(true, Ordering::Relaxed);
        watcher.join().unwrap();
        assert!(!before_repair);
        assert_eq!(std::fs::metadata(marker).unwrap().len(), 0);
    }
}

/// Restarts Windows immediately, after the app countdown.
/// `comment` is the message Windows shows in its restart notice (at most
/// 512 characters).
pub fn schedule_restart(comment: &str) -> Result<()> {
    super::desktop_setup::note_restart()?;
    let comment: String = comment.chars().take(512).collect();
    shutdown(&["/r", "/t", "0", "/c", &comment])
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
    let system32 = std::env::var_os("SystemRoot")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| std::path::PathBuf::from(r"C:\Windows"))
        .join("System32");
    let mut command = std::process::Command::new(system32.join("shutdown.exe"));
    command.args(arguments);
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        command.creation_flags(0x0800_0000);
    }
    let output = command.output().context("run shutdown.exe")?;
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

// ----- Processes ------------------------------------------------------------

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
    /// ERROR_INVALID_PARAMETER: no process has this id.
    const NO_SUCH_PROCESS: i32 = 87;
    let handle = match ProcessHandle::open(pid) {
        Ok(handle) => handle,
        Err(error) if error.code().0 & 0xFFFF == NO_SUCH_PROCESS => return Liveness::Ended,
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
    // Reads are milliseconds apart. A minute hid quick installs followed by a reboot.
    booted - chrono::Duration::seconds(1) > moment.with_timezone(&chrono::Utc)
}

// ----- Accessibility preferences ---------------------------------------------

/// Ease of Access settings that change how the UI should draw.
#[derive(Clone, Debug, PartialEq)]
pub struct AccessibilityPreferences {
    /// A Windows contrast theme is active; use the system colours.
    pub high_contrast: bool,
    /// "Show animations in Windows" is off.
    pub reduce_motion: bool,
    /// The "Text size" slider, 1.0 to 2.25.
    pub text_scale: f32,
    /// System colours to draw with while a contrast theme is active.
    pub system_colors: Option<SystemColors>,
}

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
    pub fn read() -> Self {
        let high_contrast = high_contrast_on();
        Self {
            high_contrast,
            reduce_motion: !client_area_animation(),
            text_scale: text_scale(),
            system_colors: high_contrast.then(SystemColors::read),
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
        .map(|percent| (percent as f32 / 100.0).clamp(1.0, 2.25))
        .unwrap_or(1.0)
}

impl SystemColors {
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

/// Well-known shell targets used by the UI.
pub mod links {
    pub const WINDOWS_SECURITY_PROTECTION: &str = "windowsdefender://threatsettings";
    pub const WINDOWS_UPDATE: &str = "ms-settings:windowsupdate";
    pub const DOCS: &str = "https://docs.atlasos.net/";
    pub const GITHUB: &str = "https://github.com/Atlas-OS/Atlas";
    pub const RELEASES: &str = "https://github.com/Atlas-OS/Atlas/releases";
    pub const ISSUES: &str = "https://github.com/Atlas-OS/Atlas/issues";
    pub const DISCORD: &str = "https://discord.atlasos.net/";
}

#[cfg(test)]
mod tests {
    use super::*;

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
    fn a_pid_nobody_has_is_ended_and_a_refusal_is_unknown() {
        // PIDs are multiples of four; an odd one can never name a process.
        assert_eq!(process_liveness(0x7FFF_FFF1, 0), Liveness::Ended);
        assert_eq!(process_liveness(std::process::id(), 0), Liveness::Alive);
        // The System process (4) refuses limited queries only to restricted
        // tokens; whichever it is, the answer is never "ended".
        assert_ne!(process_liveness(4, 0), Liveness::Ended);
    }

    #[test]
    fn boot_time_is_compared_against_a_moment() {
        assert!(booted_since("2001-01-01T00:00:00+00:00"), "the PC booted after 2001");
        assert!(!booted_since(&chrono::Local::now().to_rfc3339()), "not since a moment ago");
        assert!(!booted_since("not a time"), "an unreadable time never claims a boot");
    }

    #[test]
    fn accessibility_preferences_read_without_failing() {
        let preferences = AccessibilityPreferences::read();
        assert!((1.0..=2.25).contains(&preferences.text_scale));
        assert_eq!(preferences.high_contrast, preferences.system_colors.is_some());
    }
}
