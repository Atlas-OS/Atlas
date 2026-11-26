//! The Windows providers the checks read: the Windows Update search, the
//! restart markers, Security Center and the licensing service, and for a
//! move to a newer Windows release, the hardware, the free space and where
//! updates come from.

use std::time::Duration;

use anyhow::{Context, Result};
use windows::Win32::Foundation::VARIANT_BOOL;
use windows::Win32::System::Com::{CLSCTX_INPROC_SERVER, CoCreateInstance};
use windows::Win32::System::UpdateAgent::{IUpdateSession, UpdateSession, utDriver};
use windows::core::BSTR;
use windows_registry::LOCAL_MACHINE;

use super::deadline::Deadline;
use super::wmi::{ComApartment, wmi_query, wmi_strings};
use crate::services::registry::{NOT_FOUND, key_present, pending_file_renames};
use crate::services::{preparation, update_access};

/// How long one check may wait for the Windows Update Agent's local search.
/// It takes seconds on a healthy PC; a provider that never answers must
/// not hold the Get ready step or the final preflight open for ever.
const UPDATE_SEARCH_DEADLINE: Duration = Duration::from_secs(60);
/// How long a check waits for the antivirus or activation answer, including
/// the licensing provider's start-up retries.
const ANTIVIRUS_DEADLINE: Duration = Duration::from_secs(30);
const ACTIVATION_DEADLINE: Duration = Duration::from_secs(50);

const TPM_DEADLINE: Duration = Duration::from_secs(20);

static UPDATE_SEARCH: Deadline<Vec<String>> = Deadline::new("the Windows Update search");
static ANTIVIRUS_QUERY: Deadline<Vec<Vec<Option<String>>>> = Deadline::new("the Security Center query");
static ACTIVATION_QUERY: Deadline<Vec<String>> = Deadline::new("the licensing query");
static TPM_QUERY: Deadline<Vec<String>> = Deadline::new("the TPM query");

/// The Windows Update category of feature upgrades: another Windows release,
/// not a pending update.
const UPGRADES_CATEGORY: &str = "3689bdc8-b205-4af4-8d4a-a63924c5e9d5";

/// Titles of updates that are available or downloaded but not installed.
/// The search uses the criteria of the Atlas package's `Update-Windows.ps1`,
/// whose verification the front door runs before installing, so Get ready
/// and the install agree on whether a PC is ready. It reads the local cache
/// only, so Microsoft's servers aren't contacted. Runs on a fresh thread in COM's
/// multithreaded apartment, whatever the caller's thread uses: in a
/// single-threaded apartment without a message pump, slow providers return
/// nothing.
pub(super) fn pending_updates() -> Result<Vec<String>> {
    let start = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Services\wuauserv")
        .and_then(|key| key.get_u32("Start"))
        .ok();
    if !may_search(start) {
        anyhow::bail!("the Windows Update service is turned off, so Atlas didn't search");
    }
    UPDATE_SEARCH.run(UPDATE_SEARCH_DEADLINE, pending_updates_on_this_thread)
}

/// Whether the Windows Update service's start type lets the check search.
/// An elevated search with the service disabled sets it to start on demand,
/// which would change the PC before Get ready has recorded how Windows Update
/// was set; the update step turns it on itself, and puts it back.
fn may_search(start: Option<u32>) -> bool {
    start != Some(4)
}

fn pending_updates_on_this_thread() -> Result<Vec<String>> {
    let _apartment = ComApartment::enter()?;
    unsafe {
        let session: IUpdateSession = CoCreateInstance(&UpdateSession, None, CLSCTX_INPROC_SERVER)
            .context("create the Windows Update session")?;
        let searcher = session.CreateUpdateSearcher().context("create the update searcher")?;
        searcher.SetOnline(VARIANT_BOOL::from(false))?;
        let manual_drivers = preparation::existing_driver_policy() == preparation::Drivers::Manual;
        let reoffered = preparation::reoffered_updates();
        let result = searcher
            .Search(&BSTR::from(
                "IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and DeploymentAction='Installation'",
            ))
            .context("search for pending updates")?;
        let updates = result.Updates()?;
        let count = updates.Count()?;
        let mut titles = Vec::with_capacity(count.max(0) as usize);
        for index in 0..count {
            let update = updates.get_Item(index)?;
            // Drivers are left alone when the user installs them by hand.
            if manual_drivers && update.Type()? == utDriver {
                continue;
            }
            // Recorded by the worker as done (offered again after it installed, or
            // a driver no better than the device's own), so it no longer waits for it.
            let identity = update.Identity()?;
            if reoffered.contains(&format!("{}/{}", identity.UpdateID()?, identity.RevisionNumber()?)) {
                continue;
            }
            let categories = update.Categories()?;
            let mut feature_upgrade = false;
            for index in 0..categories.Count()? {
                if categories
                    .get_Item(index)?
                    .CategoryID()?
                    .to_string()
                    .eq_ignore_ascii_case(UPGRADES_CATEGORY)
                {
                    feature_upgrade = true;
                    break;
                }
            }
            if !feature_upgrade {
                titles.push(update.Title()?.to_string());
            }
        }
        Ok(titles)
    }
}

/// Registry markers Windows sets when it wants a restart. The servicing and
/// Windows Update keys block: a restart clears them. Pending file renames are
/// reported separately, since some apps re-queue one at every boot.
pub(super) struct RebootMarkers {
    pub(super) blocking: Vec<&'static str>,
    pub(super) file_renames: Vec<String>,
}

/// The servicing stack's key, under which it keeps its restart markers.
const SERVICING: &str = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing";

/// A marker that cannot be read is an error, not a pass: only "no such key"
/// means no marker.
pub(super) fn reboot_markers() -> Result<RebootMarkers> {
    let mut blocking = Vec::new();
    if key_present(LOCAL_MACHINE, &format!(r"{SERVICING}\RebootPending"))? {
        if servicing_marker_stale() {
            log::info!(
                "servicing's restart marker stayed after a restart with nothing pending, as the update worker confirmed in this start of Windows; not counted"
            );
        } else {
            blocking.push("servicing");
        }
    }
    if key_present(
        LOCAL_MACHINE,
        r"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
    )? {
        blocking.push("windows-update");
    }
    let session_manager = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Control\Session Manager")
        .context("open Session Manager")?;
    let file_renames = pending_file_renames(&session_manager)?;
    Ok(RebootMarkers { blocking, file_renames })
}

/// Windows can keep servicing's RebootPending marker over restarts while
/// servicing has nothing pending. The update worker asks servicing after a
/// restart it asked for, and records the start of Windows in which it found
/// nothing waiting (`Test-PreparationServicingStale` in `Update-Windows.ps1`).
/// For the rest of that start the marker doesn't count, while servicing still
/// has nothing waiting. Anything that can't be read counts the marker.
fn servicing_marker_stale() -> bool {
    let recorded = LOCAL_MACHINE
        .open(r"SOFTWARE\AtlasOS\Preparation")
        .and_then(|key| key.get_string("ServicingMarkerStale"))
        .ok();
    let boot = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters")
        .and_then(|key| key.get_u32("BootId"))
        .ok();
    confirmed_in_this_boot(recorded.as_deref(), boot) && servicing_waits().is_ok_and(|waits| !waits)
}

/// Whether the worker's record names this start of Windows, as `boot:<BootId>`.
fn confirmed_in_this_boot(recorded: Option<&str>, boot: Option<u32>) -> bool {
    matches!((recorded, boot), (Some(recorded), Some(boot)) if recorded == format!("boot:{boot}"))
}

/// Whether servicing has something waiting for a restart: pending.xml in the
/// component store, an exclusive session it has yet to finish, or its
/// PackagesPending or RebootInProgress marker. The worker also reads each
/// package's state before it records the marker as stale.
fn servicing_waits() -> Result<bool> {
    if windows_directory()?.join(r"WinSxS\pending.xml").try_exists()? {
        return Ok(true);
    }
    for marker in ["PackagesPending", "RebootInProgress"] {
        if key_present(LOCAL_MACHINE, &format!(r"{SERVICING}\{marker}"))? {
            return Ok(true);
        }
    }
    let exclusive = match LOCAL_MACHINE.open(format!(r"{SERVICING}\SessionsPending")) {
        Ok(key) => match key.get_value("Exclusive") {
            Ok(value) => Some(u32::try_from(value).unwrap_or(u32::MAX)),
            Err(error) if error.code().0 == NOT_FOUND => None,
            Err(error) => anyhow::bail!("read SessionsPending: {error}"),
        },
        Err(error) if error.code().0 == NOT_FOUND => None,
        Err(error) => anyhow::bail!("open SessionsPending: {error}"),
    };
    Ok(exclusive_session(exclusive))
}

/// Whether servicing's `SessionsPending\Exclusive` value names an exclusive
/// session: any value but 0. A value of another type reads as `u32::MAX`.
fn exclusive_session(value: Option<u32>) -> bool {
    value.is_some_and(|value| value != 0)
}

/// `%windir%`, as Windows reports it.
fn windows_directory() -> Result<std::path::PathBuf> {
    use windows::Win32::System::SystemInformation::GetSystemWindowsDirectoryW;
    let mut buffer = [0u16; 260];
    let length = unsafe { GetSystemWindowsDirectoryW(Some(&mut buffer)) } as usize;
    anyhow::ensure!(length > 0 && length < buffer.len(), "the Windows folder couldn't be read");
    Ok(std::path::PathBuf::from(String::from_utf16_lossy(&buffer[..length])))
}

/// One Security Center antivirus registration.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AntivirusProduct {
    pub name: String,
    /// `pathToSignedProductExe`: the product's executable, or a URI for
    /// inbox products. Uninstallers do not always deregister, so this is
    /// how a leftover is told from an installed product.
    pub executable: Option<String>,
}

impl AntivirusProduct {
    /// A registration counts as installed unless it names a file that is
    /// gone. A missing or non-file registration (a URI, say) fails closed.
    pub fn installed(&self) -> bool {
        let Some(executable) = self.executable.as_deref().map(|e| e.trim().trim_matches('"')) else {
            return true;
        };
        // Only a drive or UNC path can be checked; a URI (inbox products
        // register `windowsdefender://`) or an unexpanded `%variable%` path
        // cannot, so it counts as installed. Install-Atlas.ps1 tests the same.
        let bytes = executable.as_bytes();
        let looks_like_path = (bytes.first().is_some_and(u8::is_ascii_alphabetic)
            && bytes.get(1) == Some(&b':'))
            || executable.starts_with(r"\\");
        if !looks_like_path {
            return true;
        }
        std::path::Path::new(executable).is_file()
    }
}

/// Antivirus products other than Defender registered with Security Center.
pub(super) fn third_party_antivirus() -> Result<Vec<AntivirusProduct>> {
    let rows = ANTIVIRUS_QUERY.run(ANTIVIRUS_DEADLINE, || {
        wmi_query(
            r"ROOT\SecurityCenter2",
            "SELECT displayName, pathToSignedProductExe FROM AntiVirusProduct",
            &["displayName", "pathToSignedProductExe"],
        )
    })?;
    Ok(rows
        .into_iter()
        .filter_map(|mut row| {
            let executable = row.pop().flatten();
            let name = row.pop().flatten()?;
            Some(AntivirusProduct { name, executable })
        })
        .filter(|product| {
            let lower = product.name.to_ascii_lowercase();
            !lower.starts_with("windows defender") && !lower.starts_with("microsoft defender")
        })
        .collect())
}

/// Whether Windows itself is activated, from the licensing service:
/// `Some(true)` if a Windows product with a key is licensed, `Some(false)`
/// if there is one but it is not, `None` if Windows reports no such product.
pub(super) fn windows_activation() -> Result<Option<bool>> {
    const WINDOWS_APPLICATION_ID: &str = "55c92734-d682-4d71-983e-d6ec3f16059f";
    const LICENSED: &str = "1";
    let statuses = ACTIVATION_QUERY.run(ACTIVATION_DEADLINE, || {
        let query = format!(
            "SELECT LicenseStatus FROM SoftwareLicensingProduct WHERE ApplicationID = '{WINDOWS_APPLICATION_ID}' AND PartialProductKey IS NOT NULL"
        );
        // The licensing provider can answer with no rows while it starts; ask
        // again before concluding Windows reports no licence.
        let mut statuses = Vec::new();
        for attempt in 0..3 {
            if attempt > 0 {
                std::thread::sleep(Duration::from_millis(700));
            }
            statuses = wmi_strings(r"ROOT\CIMV2", &query, "LicenseStatus")?;
            if !statuses.is_empty() {
                break;
            }
        }
        Ok(statuses)
    })?;
    if statuses.is_empty() {
        return Ok(None);
    }
    Ok(Some(statuses.iter().any(|status| status.trim() == LICENSED)))
}

/// The Windows 11 hardware Windows itself reports, as the preparation
/// worker reads it when Windows Update offers no move: `None` where it
/// couldn't be read. Processor support has no reliable local answer, so it
/// isn't guessed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(super) struct Hardware {
    pub(super) tpm_2: Option<bool>,
    pub(super) uefi: Option<bool>,
}

pub(super) fn windows_11_hardware() -> Hardware {
    // Win32_Tpm answers only an administrator, and lists nothing without a TPM.
    let tpm_2 = TPM_QUERY
        .run(TPM_DEADLINE, || {
            wmi_strings(
                r"ROOT\CIMV2\Security\MicrosoftTpm",
                "SELECT SpecVersion FROM Win32_Tpm",
                "SpecVersion",
            )
        })
        .map(|versions| versions.iter().any(|version| version.trim_start().starts_with("2.0")))
        .inspect_err(|error| log::info!("the TPM couldn't be read: {error:#}"))
        .ok();
    // 1 is BIOS, 2 is UEFI.
    let uefi = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Control")
        .and_then(|key| key.get_u32("PEFirmwareType"))
        .ok()
        .and_then(|kind| match kind {
            1 => Some(false),
            2 => Some(true),
            _ => None,
        });
    Hardware { tpm_2, uefi }
}

/// The system drive, such as "C:", and the bytes free on it for this process.
pub(super) fn free_space() -> Result<(String, u64)> {
    use windows::Win32::Storage::FileSystem::GetDiskFreeSpaceExW;
    use windows::Win32::System::SystemInformation::GetSystemWindowsDirectoryW;
    use windows::core::HSTRING;
    let mut buffer = [0u16; 260];
    let length = unsafe { GetSystemWindowsDirectoryW(Some(&mut buffer)) } as usize;
    anyhow::ensure!(length > 0 && length < buffer.len(), "the Windows folder couldn't be read");
    let windows = String::from_utf16_lossy(&buffer[..length]);
    let drive: String = windows.chars().take(2).collect();
    anyhow::ensure!(drive.ends_with(':'), "the Windows folder {windows} isn't on a drive letter");
    let mut free = 0u64;
    unsafe {
        GetDiskFreeSpaceExW(&HSTRING::from(format!(r"{drive}\")), Some(&mut free as *mut u64), None, None)
    }
    .with_context(|| format!("read the free space on {drive}"))?;
    Ok((drive, free))
}

/// Whether this PC gets updates from its organisation's server
/// (`AU\UseWUServer` set to 1), which the worker never overrides. A redirect
/// to a server that can't be one, on a PC no organisation manages, isn't:
/// tools that block updates set it, and the worker lifts it for the move
/// ([`update_access::redirect_broken`]).
pub(super) fn managed_update_server() -> bool {
    LOCAL_MACHINE
        .open(r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")
        .and_then(|key| key.get_u32("UseWUServer"))
        .is_ok_and(|value| value == 1)
        && !update_access::redirect_broken()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn this_pc_reports_its_system_drive_and_free_space() {
        let (drive, free) = free_space().unwrap();
        assert_eq!(drive.len(), 2, "{drive}");
        assert!(free > 0);
    }

    #[test]
    fn a_registration_whose_executable_is_gone_is_a_leftover() {
        let temp = crate::services::test_support::TempDir::new("antivirus-leftover");
        let present = std::env::current_exe().unwrap();
        let installed =
            AntivirusProduct { name: "Contoso".into(), executable: Some(present.display().to_string()) };
        assert!(installed.installed());
        let quoted = AntivirusProduct {
            name: "Contoso".into(),
            executable: Some(format!("\"{}\"", present.display())),
        };
        assert!(quoted.installed());
        let gone = AntivirusProduct {
            name: "Uninstalled".into(),
            executable: Some(temp.path().join("never-created.exe").display().to_string()),
        };
        assert!(!gone.installed());
        // Nothing to verify against: fail closed.
        let unverifiable =
            ["", "windowsdefender://", "contoso://", r"%ProgramFiles%\Contoso\never-created.exe"];
        for executable in unverifiable.map(|path| Some(path.to_owned())).into_iter().chain([None]) {
            let product = AntivirusProduct { name: "X".into(), executable };
            assert!(product.installed(), "{product:?}");
        }
    }

    /// The worker writes `boot:<BootId>` (`Get-AtlasTransitionBootId`), and only
    /// the start of Windows it confirmed the marker in counts.
    #[test]
    fn a_stale_servicing_marker_counts_only_in_the_start_of_windows_the_worker_confirmed_it_in() {
        assert!(super::confirmed_in_this_boot(Some("boot:41"), Some(41)));
        assert!(!super::confirmed_in_this_boot(Some("boot:40"), Some(41)), "an earlier start");
        assert!(!super::confirmed_in_this_boot(None, Some(41)), "never confirmed");
        assert!(!super::confirmed_in_this_boot(Some("boot:41"), None), "no BootId to compare");
        assert!(!super::confirmed_in_this_boot(Some("41"), Some(41)), "another format");
    }

    #[test]
    fn only_an_exclusive_session_value_other_than_0_waits() {
        assert!(!super::exclusive_session(None));
        assert!(!super::exclusive_session(Some(0)));
        assert!(super::exclusive_session(Some(1)));
        assert!(super::exclusive_session(Some(u32::MAX)), "a value of another type");
    }

    #[test]
    fn this_pc_reports_whether_servicing_waits() {
        // Read only; whatever this PC has, the read itself succeeds.
        super::servicing_waits().unwrap();
    }

    #[test]
    fn a_disabled_windows_update_service_is_never_searched() {
        assert!(!super::may_search(Some(4)));
        for start in [Some(2), Some(3), None] {
            assert!(super::may_search(start), "{start:?}");
        }
    }
}
