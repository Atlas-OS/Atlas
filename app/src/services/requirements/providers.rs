//! The Windows providers the checks read: the Windows Update search, the
//! restart markers, Security Center and the licensing service.

use std::time::Duration;

use anyhow::{Context, Result};
use windows::Win32::Foundation::VARIANT_BOOL;
use windows::Win32::System::Com::{CLSCTX_INPROC_SERVER, CoCreateInstance};
use windows::Win32::System::UpdateAgent::{IUpdateSession, UpdateSession, utDriver};
use windows::core::BSTR;
use windows_registry::LOCAL_MACHINE;

use super::bounded::Bounded;
use super::wmi::{ComApartment, wmi_query, wmi_strings};
use crate::services::preparation;
use crate::services::registry::{key_present, pending_file_renames};

/// How long one check may wait for the Windows Update Agent's local search.
/// It takes seconds on a healthy PC; a provider that never answers must
/// not hold the Get ready step or the final preflight open for ever.
const UPDATE_SEARCH_DEADLINE: Duration = Duration::from_secs(60);
/// How long a check waits for the antivirus or activation answer, including
/// the licensing provider's start-up retries.
const ANTIVIRUS_DEADLINE: Duration = Duration::from_secs(30);
const ACTIVATION_DEADLINE: Duration = Duration::from_secs(50);

static UPDATE_SEARCH: Bounded<Vec<String>> = Bounded::new("the Windows Update search");
static ANTIVIRUS_QUERY: Bounded<Vec<Vec<Option<String>>>> = Bounded::new("the Security Center query");
static ACTIVATION_QUERY: Bounded<Vec<String>> = Bounded::new("the licensing query");

/// The Windows Update category of feature upgrades: another Windows release,
/// not a pending update.
const UPGRADES_CATEGORY: &str = "3689bdc8-b205-4af4-8d4a-a63924c5e9d5";

/// Titles of updates that are available or downloaded but not installed.
/// The search is the one AME Wizard runs, so the app and AME Wizard agree
/// on whether a PC is ready. It reads the local cache only, so Microsoft's
/// servers are not contacted. Runs on a fresh thread in COM's
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
            // Offered again after it installed: the worker no longer waits for it.
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

/// A marker that cannot be read is an error, not a pass: only "no such key"
/// means no marker.
pub(super) fn reboot_markers() -> Result<RebootMarkers> {
    let mut blocking = Vec::new();
    if key_present(
        LOCAL_MACHINE,
        r"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    )? {
        blocking.push("servicing");
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
        // register `windowsdefender://`) cannot, so it counts as installed.
        let looks_like_path = executable.as_bytes().get(1) == Some(&b':') || executable.starts_with(r"\\");
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

#[cfg(test)]
mod tests {
    use super::*;

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
        for executable in [None, Some(String::new()), Some("windowsdefender://".to_owned())] {
            assert!(AntivirusProduct { name: "X".into(), executable }.installed());
        }
    }

    #[test]
    fn a_disabled_windows_update_service_is_never_searched() {
        assert!(!super::may_search(Some(4)));
        for start in [Some(2), Some(3), None] {
            assert!(super::may_search(start), "{start:?}");
        }
    }
}
