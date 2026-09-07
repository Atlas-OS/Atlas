//! The system checks that gate an install: the same requirements the playbook
//! declares in playbook.conf, evaluated with the same rules as
//! `Entry\Install-Atlas.ps1` where the script has an opinion.

use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use windows::Win32::Foundation::{RPC_E_CHANGED_MODE, VARIANT_BOOL};
use windows::Win32::System::Com::{
    CLSCTX_INPROC_SERVER, COINIT_MULTITHREADED, CoCreateInstance, CoInitializeEx, CoSetProxyBlanket,
    CoTaskMemFree, CoUninitialize, EOAC_NONE, RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE,
};
use windows::Win32::System::Rpc::{RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE};
use windows::Win32::System::UpdateAgent::{IUpdateSession, UpdateSession};
use windows::Win32::System::Variant::{VARIANT, VT_EMPTY, VT_NULL, VariantClear, VariantToStringAlloc};
use windows::Win32::System::Wmi::{
    IWbemClassObject, IWbemContext, IWbemLocator, WBEM_FLAG_CONNECT_USE_MAX_WAIT, WBEM_FLAG_FORWARD_ONLY,
    WBEM_FLAG_RETURN_IMMEDIATELY, WBEM_S_TIMEDOUT, WbemLocator,
};
use windows::core::{BSTR, HSTRING, PCWSTR};
use windows_registry::{Key, LOCAL_MACHINE};

use super::system::{self, PowerSource, SystemInfo};

/// How long one check may wait for the Windows Update Agent's local search.
/// It takes seconds on a healthy PC; a provider that never answers must
/// not hold the Get ready step or the final preflight open for ever.
const UPDATE_SEARCH_DEADLINE: Duration = Duration::from_secs(60);
/// How long one WMI query may run in total, and the slice after which the
/// enumerator hands control back so that total can be enforced.
const WMI_QUERY_DEADLINE: Duration = Duration::from_secs(20);
const WMI_ROW_WAIT: Duration = Duration::from_secs(1);
/// How long a check waits for the antivirus or activation answer, including
/// the licensing provider's start-up retries.
const ANTIVIRUS_DEADLINE: Duration = Duration::from_secs(30);
const ACTIVATION_DEADLINE: Duration = Duration::from_secs(50);

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum CheckId {
    Administrator,
    SupportedBuild,
    PendingUpdates,
    PendingReboot,
    ThirdPartyAntivirus,
    Internet,
    Power,
    /// Advisory: Atlas never changes activation, but people should know.
    Activation,
}

impl CheckId {
    pub const ALL: [CheckId; 8] = [
        CheckId::Administrator,
        CheckId::SupportedBuild,
        CheckId::PendingUpdates,
        CheckId::PendingReboot,
        CheckId::ThirdPartyAntivirus,
        CheckId::Internet,
        CheckId::Power,
        CheckId::Activation,
    ];

    /// Whether a failure stops the install, or only warns.
    pub fn blocking(self) -> bool {
        !matches!(self, CheckId::Activation)
    }

    /// A Settings page that helps resolve the failure, if there is one. The
    /// button's label comes from the message catalog.
    pub fn fix_target(self) -> Option<&'static str> {
        match self {
            CheckId::PendingUpdates | CheckId::PendingReboot => Some(system::links::WINDOWS_UPDATE),
            CheckId::Internet => Some("ms-settings:network"),
            CheckId::Power => Some("ms-settings:powersleep"),
            CheckId::Activation => Some("ms-settings:activation"),
            _ => None,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verdict {
    Pass,
    Warn,
    Fail,
    /// The provider could not establish the fact. Required checks fail closed;
    /// only the update scan has a separate manual acknowledgement path.
    Unknown,
}

/// What a check found, as data. The page translates it when it renders,
/// so a result that is already on screen changes language with the app.
/// Raw error text from Windows is kept as a diagnostic, never as the
/// explanation.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CheckDetail {
    AdministratorOk,
    AdministratorMissing,
    BuildSupported,
    EditionUnsupported,
    WindowsPreview,
    WindowsReleaseUnknown,
    BuildUnsupported { supported: Vec<u32>, actual: u32 },
    UpdatesNone,
    UpdatesPending { titles: Vec<String> },
    UpdatesUnknown { error: String },
    RebootNone,
    RebootPending,
    RebootUnknown { error: String },
    AntivirusNone,
    AntivirusFound { products: Vec<String> },
    AntivirusUnknown { error: String },
    InternetOk,
    InternetMissing,
    PowerMains,
    PowerBattery,
    PowerUnknown,
    ActivationOk,
    ActivationMissing,
    ActivationNoLicence,
    ActivationUnknown { error: String },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CheckResult {
    pub id: CheckId,
    pub verdict: Verdict,
    pub detail: CheckDetail,
}

impl CheckResult {
    /// Whether this result stops the install on its own. An unknown result
    /// on a blocking check stops it until the user acknowledges it (see
    /// [`CheckResult::needs_acknowledgement`]).
    pub fn blocks_install(&self) -> bool {
        self.id.blocking() && matches!(self.verdict, Verdict::Fail | Verdict::Unknown)
    }

    /// Only the update scan can be confirmed manually; safety checks must run.
    pub fn needs_acknowledgement(&self) -> bool {
        self.id == CheckId::PendingUpdates && self.verdict == Verdict::Unknown
    }
}

pub struct CheckContext {
    pub system: SystemInfo,
    pub supported_builds: Vec<u32>,
}

/// Runs one check. Slow checks (Windows Update, WMI) take a few seconds.
pub fn run(id: CheckId, ctx: &CheckContext) -> CheckResult {
    use CheckDetail as D;
    let (verdict, detail) = match id {
        CheckId::Administrator => {
            if system::is_elevated() {
                (Verdict::Pass, D::AdministratorOk)
            } else {
                (Verdict::Fail, D::AdministratorMissing)
            }
        }
        CheckId::SupportedBuild => {
            if !ctx.system.supported_edition() {
                (Verdict::Fail, D::EditionUnsupported)
            } else if ctx.supported_builds.contains(&ctx.system.build) {
                match super::windows_release::classify(
                    ctx.system.build,
                    ctx.system.revision,
                    &ctx.system.build_lab,
                ) {
                    super::windows_release::Status::Released => (Verdict::Pass, D::BuildSupported),
                    super::windows_release::Status::Preview => (Verdict::Fail, D::WindowsPreview),
                    super::windows_release::Status::Unknown => (Verdict::Unknown, D::WindowsReleaseUnknown),
                }
            } else {
                (
                    Verdict::Fail,
                    D::BuildUnsupported { supported: ctx.supported_builds.clone(), actual: ctx.system.build },
                )
            }
        }
        CheckId::PendingUpdates => match pending_updates() {
            Ok(titles) if titles.is_empty() => (Verdict::Pass, D::UpdatesNone),
            Ok(titles) => (Verdict::Fail, D::UpdatesPending { titles }),
            Err(error) => (Verdict::Unknown, D::UpdatesUnknown { error: format!("{error:#}") }),
        },
        CheckId::PendingReboot => match reboot_reasons() {
            Ok(reasons) if reasons.is_empty() => (Verdict::Pass, D::RebootNone),
            Ok(_) => (Verdict::Fail, D::RebootPending),
            Err(error) => (Verdict::Unknown, D::RebootUnknown { error: format!("{error:#}") }),
        },
        CheckId::ThirdPartyAntivirus => match third_party_antivirus() {
            Ok(products) if products.is_empty() => (Verdict::Pass, D::AntivirusNone),
            Ok(products) => (Verdict::Fail, D::AntivirusFound { products }),
            Err(error) => (Verdict::Unknown, D::AntivirusUnknown { error: format!("{error:#}") }),
        },
        CheckId::Internet => {
            if system::internet_connected() {
                (Verdict::Pass, D::InternetOk)
            } else {
                (Verdict::Fail, D::InternetMissing)
            }
        }
        CheckId::Power => match system::power_source() {
            PowerSource::Mains => (Verdict::Pass, D::PowerMains),
            PowerSource::Battery => (Verdict::Fail, D::PowerBattery),
            PowerSource::Unknown => (Verdict::Unknown, D::PowerUnknown),
        },
        CheckId::Activation => match windows_activation() {
            Ok(Some(true)) => (Verdict::Pass, D::ActivationOk),
            Ok(Some(false)) => (Verdict::Warn, D::ActivationMissing),
            Ok(None) => (Verdict::Unknown, D::ActivationNoLicence),
            Err(error) => (Verdict::Unknown, D::ActivationUnknown { error: format!("{error:#}") }),
        },
    };
    if verdict == Verdict::Unknown {
        log::warn!("check {id:?} could not run: {detail:?}");
    }
    CheckResult { id, verdict, detail }
}

/// Registry markers Windows sets when servicing or Windows Update wants a
/// restart. A marker that cannot be read is an error, not a pass: only
/// "no such key" means no marker.
fn reboot_reasons() -> Result<Vec<&'static str>> {
    let mut reasons = Vec::new();
    if key_present(
        LOCAL_MACHINE,
        r"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    )? {
        reasons.push("component servicing");
    }
    if key_present(
        LOCAL_MACHINE,
        r"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
    )? {
        reasons.push("Windows Update");
    }
    let session_manager = LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Control\Session Manager")
        .context("open Session Manager")?;
    if pending_file_renames(&session_manager)? {
        reasons.push("file renames");
    }
    Ok(reasons)
}

const ERROR_FILE_NOT_FOUND: i32 = 0x8007_0002_u32 as i32;

/// Whether a registry key exists. Absence is only concluded from "not
/// found"; any other refusal to open it is reported.
pub fn key_present(root: &Key, path: &str) -> Result<bool> {
    match root.open(path) {
        Ok(_) => Ok(true),
        Err(error) if error.code().0 == ERROR_FILE_NOT_FOUND => Ok(false),
        Err(error) => Err(anyhow::anyhow!("open {path}: {error}")),
    }
}

/// Whether `PendingFileRenameOperations` (a REG_MULTI_SZ) lists any rename.
/// A missing value means no renames; any other read failure is reported.
pub fn pending_file_renames(key: &Key) -> Result<bool> {
    match key.get_multi_string("PendingFileRenameOperations") {
        Ok(entries) => Ok(entries.iter().any(|entry| !entry.trim().is_empty())),
        Err(error) if error.code().0 == ERROR_FILE_NOT_FOUND => Ok(false),
        Err(error) => Err(anyhow::anyhow!("read PendingFileRenameOperations: {error}")),
    }
}

/// A COM apartment for the current thread. Only an initialisation this guard
/// performed is undone when it drops; if the thread already belongs to a
/// different apartment model, COM is used as it is and left alone.
struct ComApartment {
    owns_initialisation: bool,
}

impl ComApartment {
    fn enter() -> Result<Self> {
        let hr = unsafe { CoInitializeEx(None, COINIT_MULTITHREADED) };
        if hr.is_ok() {
            // S_OK (first initialisation) and S_FALSE (nested) both need a CoUninitialize.
            Ok(Self { owns_initialisation: true })
        } else if hr == RPC_E_CHANGED_MODE {
            Ok(Self { owns_initialisation: false })
        } else {
            Err(anyhow::anyhow!("initialise COM: {hr}"))
        }
    }
}

impl Drop for ComApartment {
    fn drop(&mut self) {
        if self.owns_initialisation {
            unsafe { CoUninitialize() };
        }
    }
}

/// One outstanding worker per provider. A check that finds the provider's
/// worker still busy from an earlier check waits for that same answer rather
/// than starting another, so rechecking a stalled provider never multiplies
/// stuck threads. A caller whose deadline passes gets an error; the worker
/// finishes on its own. Each run is its own job: every caller that joined it
/// keeps a handle to it and receives its result, however many later jobs
/// start meanwhile, and a caller that arrives after it finished starts a
/// fresh one (a later check wants a fresh reading).
///
/// This bounds the work; it does not interrupt it. A blocking COM call
/// cannot be cancelled safely from outside, so a stalled worker lives until
/// the provider answers or the process ends, and there is never more than
/// one per provider.
pub struct Bounded<T> {
    name: &'static str,
    current: Mutex<Option<Arc<Job<T>>>>,
}

/// One provider call and its outcome, shared by everyone waiting for it.
struct Job<T> {
    outcome: Mutex<Option<Result<T, String>>>,
    done: Condvar,
}

impl<T> Job<T> {
    fn finished(&self) -> bool {
        self.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner()).is_some()
    }
}

/// The provider did not answer within the caller's deadline.
#[derive(Debug)]
pub struct TimedOut {
    pub what: &'static str,
    pub after: Duration,
}

impl std::fmt::Display for TimedOut {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} did not answer within {} seconds", self.what, self.after.as_secs())
    }
}

impl std::error::Error for TimedOut {}

impl<T: Clone + Send + 'static> Bounded<T> {
    pub const fn new(name: &'static str) -> Self {
        Self { name, current: Mutex::new(None) }
    }

    /// Runs `work` on a worker thread this slot owns (a fresh thread, so the
    /// COM apartment is always the one the work initialises), or joins the
    /// worker already running, and waits at most `timeout` for the answer.
    pub fn run(
        &'static self,
        timeout: Duration,
        work: impl FnOnce() -> Result<T> + Send + 'static,
    ) -> Result<T> {
        let job = {
            let mut current = self.current.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
            match &*current {
                Some(job) if !job.finished() => job.clone(),
                _ => {
                    let job = Arc::new(Job { outcome: Mutex::new(None), done: Condvar::new() });
                    let worker = job.clone();
                    let name = self.name;
                    let spawned =
                        std::thread::Builder::new().name(format!("atlas-{name}")).spawn(move || {
                            let result = work().map_err(|error| format!("{error:#}"));
                            *worker.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner()) =
                                Some(result);
                            worker.done.notify_all();
                        });
                    if let Err(error) = spawned {
                        // Nothing is running; the next caller may try again.
                        *current = None;
                        return Err(anyhow::Error::from(error).context(format!("start the {name} worker")));
                    }
                    *current = Some(job.clone());
                    job
                }
            }
        };
        let deadline = Instant::now() + timeout;
        let mut outcome = job.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        loop {
            if let Some(result) = &*outcome {
                return result.clone().map_err(|error| anyhow::anyhow!("{error}"));
            }
            let now = Instant::now();
            if now >= deadline {
                return Err(TimedOut { what: self.name, after: timeout }.into());
            }
            let (guard, _) = job
                .done
                .wait_timeout(outcome, deadline - now)
                .unwrap_or_else(|poisoned| poisoned.into_inner());
            outcome = guard;
        }
    }
}

static UPDATE_SEARCH: Bounded<Vec<String>> = Bounded::new("the Windows Update search");
static ANTIVIRUS_QUERY: Bounded<Vec<String>> = Bounded::new("the Security Center query");
static ACTIVATION_QUERY: Bounded<Vec<String>> = Bounded::new("the licensing query");

/// Titles of software updates that are downloaded or available but not installed.
/// Mirrors the AME Wizard query; searches the local cache only, so it does not
/// wait for Microsoft's servers. Runs on a worker this module owns, so the
/// apartment model is always the one it initialises rather than whatever the
/// caller's thread (an executor worker, say) happens to have; a
/// single-threaded apartment without a message pump makes slow WMI providers
/// return nothing.
fn pending_updates() -> Result<Vec<String>> {
    UPDATE_SEARCH.run(UPDATE_SEARCH_DEADLINE, pending_updates_on_this_thread)
}

fn pending_updates_on_this_thread() -> Result<Vec<String>> {
    let _apartment = ComApartment::enter()?;
    unsafe {
        let session: IUpdateSession = CoCreateInstance(&UpdateSession, None, CLSCTX_INPROC_SERVER)
            .context("create the Windows Update session")?;
        let searcher = session.CreateUpdateSearcher().context("create the update searcher")?;
        searcher.SetOnline(VARIANT_BOOL::from(false))?;
        let manual_drivers =
            super::preparation::existing_driver_policy() == super::preparation::Drivers::Manual;
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
            if manual_drivers && update.Type()?.0 == 2 {
                continue;
            }
            let categories = update.Categories()?;
            let mut feature_upgrade = false;
            for index in 0..categories.Count()? {
                if categories
                    .get_Item(index)?
                    .CategoryID()?
                    .to_string()
                    .eq_ignore_ascii_case("3689bdc8-b205-4af4-8d4a-a63924c5e9d5")
                {
                    feature_upgrade = true;
                }
            }
            if feature_upgrade {
                continue;
            }
            titles.push(update.Title()?.to_string());
        }
        Ok(titles)
    }
}

/// Display names of antivirus products other than Defender registered with
/// Security Center.
fn third_party_antivirus() -> Result<Vec<String>> {
    let names = ANTIVIRUS_QUERY.run(ANTIVIRUS_DEADLINE, || {
        wmi_strings(r"ROOT\SecurityCenter2", "SELECT displayName FROM AntiVirusProduct", "displayName")
    })?;
    Ok(names
        .into_iter()
        .filter(|name| {
            let lower = name.to_ascii_lowercase();
            !lower.starts_with("windows defender") && !lower.starts_with("microsoft defender")
        })
        .collect())
}

/// Whether Windows itself is activated, from the licensing service:
/// `Some(true)` if a Windows product with a key is licensed, `Some(false)`
/// if there is one but it is not, `None` if Windows reports no such product.
fn windows_activation() -> Result<Option<bool>> {
    const WINDOWS_APPLICATION_ID: &str = "55c92734-d682-4d71-983e-d6ec3f16059f";
    const LICENSED: &str = "1";
    let statuses = ACTIVATION_QUERY.run(ACTIVATION_DEADLINE, || {
        let query = format!(
            "SELECT LicenseStatus FROM SoftwareLicensingProduct WHERE ApplicationID = '{WINDOWS_APPLICATION_ID}' AND PartialProductKey IS NOT NULL"
        );
        // The licensing provider answers with no rows while it is still
        // starting up (seen when several WMI queries begin together); ask
        // again before concluding that Windows reports no licence.
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

/// What one turn of an enumerator produced.
pub enum Fetch<R> {
    Row(R),
    /// Nothing yet within the slice; the caller decides whether to keep waiting.
    Timeout,
    /// The enumeration ended normally.
    End,
}

/// Drains an enumerator as its contract describes: a failed turn is a
/// failed query (never a shorter result), a timed-out turn is retried until
/// `deadline`, and only a normal end means the rows are all there. A row
/// whose value cannot be read fails the query too; a row with no value for
/// the property is skipped.
pub fn drain_rows<R>(
    what: &str,
    mut next: impl FnMut() -> Result<Fetch<R>>,
    mut value: impl FnMut(&R) -> Result<Option<String>>,
    deadline: Instant,
) -> Result<Vec<String>> {
    let mut values = Vec::new();
    loop {
        match next()? {
            Fetch::End => return Ok(values),
            Fetch::Timeout => {
                anyhow::ensure!(Instant::now() < deadline, "{what}: the provider did not answer in time");
            }
            Fetch::Row(row) => {
                if let Some(text) = value(&row)? {
                    values.push(text);
                }
            }
        }
    }
}

/// Runs a WQL query and returns one property of every row as text. Fails
/// rather than returning fewer rows when the provider fails part-way, a
/// property cannot be read, or the query overruns its deadline.
fn wmi_strings(namespace: &str, query: &str, property: &str) -> Result<Vec<String>> {
    // One WMI query at a time: providers that are loading on first use have
    // answered concurrent queries with nothing.
    static ONE_AT_A_TIME: Mutex<()> = Mutex::new(());
    let _turn = ONE_AT_A_TIME.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    let _apartment = ComApartment::enter()?;
    let deadline = Instant::now() + WMI_QUERY_DEADLINE;
    let property_name = HSTRING::from(property);
    unsafe {
        let locator: IWbemLocator =
            CoCreateInstance(&WbemLocator, None, CLSCTX_INPROC_SERVER).context("create the WMI locator")?;
        // The connection itself is bounded too (Windows caps this at two
        // minutes; without the flag it has no bound at all).
        let services = locator
            .ConnectServer(
                &BSTR::from(namespace),
                &BSTR::new(),
                &BSTR::new(),
                &BSTR::new(),
                WBEM_FLAG_CONNECT_USE_MAX_WAIT.0,
                &BSTR::new(),
                None::<&IWbemContext>,
            )
            .with_context(|| format!("connect to {namespace}"))?;
        CoSetProxyBlanket(
            &services,
            RPC_C_AUTHN_WINNT,
            RPC_C_AUTHZ_NONE,
            PCWSTR::null(),
            RPC_C_AUTHN_LEVEL_CALL,
            RPC_C_IMP_LEVEL_IMPERSONATE,
            None,
            EOAC_NONE,
        )?;
        let enumerator = services
            .ExecQuery(
                &BSTR::from("WQL"),
                &BSTR::from(query),
                WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
                None::<&IWbemContext>,
            )
            .with_context(|| format!("query {namespace}"))?;
        // The enumerator is its own proxy and would otherwise inherit the
        // process-wide COM security (GPUI sets it up for its own needs), under
        // which some providers, the licensing one included, return nothing.
        CoSetProxyBlanket(
            &enumerator,
            RPC_C_AUTHN_WINNT,
            RPC_C_AUTHZ_NONE,
            PCWSTR::null(),
            RPC_C_AUTHN_LEVEL_CALL,
            RPC_C_IMP_LEVEL_IMPERSONATE,
            None,
            EOAC_NONE,
        )?;

        let wait = i32::try_from(WMI_ROW_WAIT.as_millis()).unwrap_or(i32::MAX);
        drain_rows(
            query,
            || {
                let mut objects: [Option<IWbemClassObject>; 1] = [None];
                let mut returned = 0u32;
                let hr = enumerator.Next(wait, &mut objects, &mut returned);
                if hr.0 == WBEM_S_TIMEDOUT.0 {
                    return Ok(Fetch::Timeout);
                }
                if hr.is_err() {
                    anyhow::bail!("enumerate {query}: {hr}");
                }
                // WBEM_S_FALSE with nothing returned is the end of the set.
                match objects[0].take() {
                    Some(object) if returned > 0 => Ok(Fetch::Row(object)),
                    _ => Ok(Fetch::End),
                }
            },
            |object| property_text(object, &property_name, property),
            deadline,
        )
    }
}

/// One property of a WMI row as text; `None` when the row has no value for
/// it (VT_NULL or VT_EMPTY).
unsafe fn property_text(object: &IWbemClassObject, name: &HSTRING, label: &str) -> Result<Option<String>> {
    unsafe {
        let mut variant = VARIANT::default();
        object
            .Get(PCWSTR(name.as_ptr()), 0, &mut variant, None, None)
            .with_context(|| format!("read {label} from the row"))?;
        let kind = variant.Anonymous.Anonymous.vt;
        let text = if kind == VT_NULL || kind == VT_EMPTY {
            Ok(None)
        } else {
            VariantToStringAlloc(&variant)
                .map(|text| {
                    let value = text.to_string().unwrap_or_default();
                    CoTaskMemFree(Some(text.0 as *const _));
                    Some(value)
                })
                .with_context(|| format!("convert {label} to text"))
        };
        let _ = VariantClear(&mut variant);
        text
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use windows::Win32::System::Com::COINIT_APARTMENTTHREADED;
    use windows_registry::CURRENT_USER;

    fn result(id: CheckId, verdict: Verdict) -> CheckResult {
        CheckResult { id, verdict, detail: CheckDetail::InternetOk }
    }

    #[test]
    fn unknown_blocking_checks_block_until_acknowledged() {
        assert!(result(CheckId::PendingUpdates, Verdict::Unknown).blocks_install());
        assert!(result(CheckId::PendingUpdates, Verdict::Unknown).needs_acknowledgement());
        assert!(result(CheckId::PendingUpdates, Verdict::Fail).blocks_install());
        assert!(!result(CheckId::PendingUpdates, Verdict::Fail).needs_acknowledgement());
        assert!(!result(CheckId::PendingUpdates, Verdict::Pass).blocks_install());
        // Required safety checks cannot be bypassed when their provider fails.
        for id in [CheckId::Power, CheckId::ThirdPartyAntivirus, CheckId::PendingReboot] {
            for verdict in [Verdict::Fail, Verdict::Unknown] {
                assert!(result(id, verdict).blocks_install());
                assert!(!result(id, verdict).needs_acknowledgement());
            }
        }
        // Activation remains advisory.
        for verdict in [Verdict::Warn, Verdict::Fail, Verdict::Unknown] {
            assert!(!result(CheckId::Activation, verdict).blocks_install());
        }
    }

    #[test]
    fn reboot_markers_distinguish_absent_from_unreadable() {
        assert!(!key_present(CURRENT_USER, r"SOFTWARE\AtlasOS\AppTests\NoSuchKey").unwrap());
        assert!(key_present(CURRENT_USER, "SOFTWARE").unwrap());
        // A key that exists but may not be opened is an error, not "absent"
        // (SECURITY is readable by the system account alone).
        assert!(key_present(LOCAL_MACHINE, "SECURITY").is_err());
    }

    #[test]
    fn enumeration_failures_are_never_shorter_results() {
        let far = Instant::now() + Duration::from_secs(60);
        // Rows, then the provider fails: the query fails.
        let mut turns = vec![Ok(Fetch::Row("a")), Ok(Fetch::Row("b")), Err(anyhow::anyhow!("provider gone"))];
        turns.reverse();
        let error =
            drain_rows("q", || turns.pop().unwrap(), |row| Ok(Some(row.to_string())), far).unwrap_err();
        assert!(error.to_string().contains("provider gone"));
        // A property that cannot be read fails the query.
        let mut turns = vec![Ok(Fetch::Row("a")), Ok(Fetch::End)];
        turns.reverse();
        assert!(
            drain_rows("q", || turns.pop().unwrap(), |_| anyhow::bail!("no such property"), far).is_err()
        );
        // A row without a value is skipped; a normal end returns the rest.
        let mut turns = vec![Ok(Fetch::Row("a")), Ok(Fetch::Row("")), Ok(Fetch::Row("c")), Ok(Fetch::End)];
        turns.reverse();
        let values = drain_rows(
            "q",
            || turns.pop().unwrap(),
            |row| Ok((!row.is_empty()).then(|| row.to_string())),
            far,
        )
        .unwrap();
        assert_eq!(values, ["a", "c"]);
        // Slices that time out are retried until the deadline, then fail.
        let mut turns = vec![Ok(Fetch::Timeout), Ok(Fetch::Row("late")), Ok(Fetch::End)];
        turns.reverse();
        assert_eq!(
            drain_rows("q", || turns.pop().unwrap(), |row| Ok(Some(row.to_string())), far).unwrap(),
            ["late"]
        );
        let past = Instant::now() - Duration::from_secs(1);
        assert!(drain_rows::<&str>("q", || Ok(Fetch::Timeout), |_| Ok(None), past).is_err());
        // A genuinely empty set is fine.
        assert!(drain_rows::<&str>("q", || Ok(Fetch::End), |_| Ok(None), far).unwrap().is_empty());
    }

    #[test]
    #[cfg(windows)]
    fn a_real_wmi_query_fails_on_a_missing_property_and_answers_a_valid_one() {
        let caption =
            wmi_strings(r"ROOT\CIMV2", "SELECT Caption FROM Win32_OperatingSystem", "Caption").unwrap();
        assert_eq!(caption.len(), 1, "{caption:?}");
        assert!(caption[0].contains("Windows"), "{caption:?}");
        // The row exists; the property does not: an error, not an empty set.
        let error = wmi_strings(r"ROOT\CIMV2", "SELECT Caption FROM Win32_OperatingSystem", "NoSuchProperty")
            .unwrap_err();
        assert!(format!("{error:#}").contains("NoSuchProperty"), "{error:#}");
        // A query the provider rejects is an error too.
        assert!(
            wmi_strings(r"ROOT\CIMV2", "SELECT NoSuchProperty FROM Win32_OperatingSystem", "NoSuchProperty")
                .is_err()
        );
    }

    #[test]
    fn a_bounded_provider_has_one_worker_and_a_deadline() {
        use std::sync::atomic::{AtomicUsize, Ordering};
        static SLOW: Bounded<u32> = Bounded::new("a slow provider");
        static STARTED: AtomicUsize = AtomicUsize::new(0);
        let work = || {
            STARTED.fetch_add(1, Ordering::SeqCst);
            std::thread::sleep(Duration::from_millis(400));
            Ok(7)
        };
        // The first caller gives up; the worker carries on alone.
        let error = SLOW.run(Duration::from_millis(50), work).unwrap_err();
        assert!(error.downcast_ref::<TimedOut>().is_some(), "{error:#}");
        // A recheck joins that worker instead of starting a second one.
        assert_eq!(SLOW.run(Duration::from_secs(5), work).unwrap(), 7);
        assert_eq!(STARTED.load(Ordering::SeqCst), 1, "one worker for both callers");
        // Once it has answered, the next check wants a fresh reading.
        assert_eq!(SLOW.run(Duration::from_secs(5), work).unwrap(), 7);
        assert_eq!(STARTED.load(Ordering::SeqCst), 2);
        // Errors are shared the same way.
        static FAILING: Bounded<u32> = Bounded::new("a failing provider");
        let failed = FAILING.run(Duration::from_secs(5), || anyhow::bail!("broken")).unwrap_err();
        assert!(failed.to_string().contains("broken"));
    }

    /// The verification's reproduction: many simultaneous callers with a
    /// short deadline against a fast provider. A caller that joined a job
    /// must receive that job's result even when a later caller starts the
    /// next job before it has woken; nobody times out.
    #[test]
    fn a_later_job_never_steals_the_result_from_earlier_waiters() {
        use std::sync::atomic::{AtomicUsize, Ordering};
        static BUSY: Bounded<u32> = Bounded::new("a busy provider");
        static TIMED_OUT: AtomicUsize = AtomicUsize::new(0);
        static ANSWERED: AtomicUsize = AtomicUsize::new(0);
        let threads: Vec<_> = (0..12)
            .map(|_| {
                std::thread::spawn(|| {
                    for _ in 0..12 {
                        match BUSY.run(Duration::from_millis(200), || {
                            std::thread::sleep(Duration::from_millis(1));
                            Ok(42)
                        }) {
                            Ok(42) => ANSWERED.fetch_add(1, Ordering::SeqCst),
                            Ok(other) => panic!("wrong answer {other}"),
                            Err(error) if error.downcast_ref::<TimedOut>().is_some() => {
                                TIMED_OUT.fetch_add(1, Ordering::SeqCst)
                            }
                            Err(error) => panic!("{error:#}"),
                        };
                    }
                })
            })
            .collect();
        for thread in threads {
            thread.join().unwrap();
        }
        assert_eq!(TIMED_OUT.load(Ordering::SeqCst), 0, "a completed job's result reached every waiter");
        assert_eq!(ANSWERED.load(Ordering::SeqCst), 144);

        // Joining: three callers arrive while one slow job runs and all
        // receive its answer; a caller arriving after it finished starts the
        // next job. (The overlap itself, a new job beginning before an old
        // waiter has woken, is what the stress run above exercises.)
        static HANDOFF: Bounded<u32> = Bounded::new("a handoff provider");
        let first = std::thread::spawn(|| {
            HANDOFF.run(Duration::from_secs(5), || {
                std::thread::sleep(Duration::from_millis(150));
                Ok(1)
            })
        });
        std::thread::sleep(Duration::from_millis(30));
        let second = std::thread::spawn(|| HANDOFF.run(Duration::from_secs(5), || Ok(99)));
        std::thread::sleep(Duration::from_millis(30));
        // Arrives while the first job runs, so it joins it.
        let joined = std::thread::spawn(|| HANDOFF.run(Duration::from_secs(5), || Ok(99)));
        assert_eq!(first.join().unwrap().unwrap(), 1);
        assert_eq!(second.join().unwrap().unwrap(), 1);
        assert_eq!(joined.join().unwrap().unwrap(), 1);
        // Now it has finished: a new caller gets a new job.
        assert_eq!(HANDOFF.run(Duration::from_secs(5), || Ok(2)).unwrap(), 2);
    }

    #[test]
    fn atlas_06_accepts_25h2_and_blocks_24h2() {
        let mut context = CheckContext {
            system: SystemInfo {
                build: 26100,
                revision: 6584,
                edition_id: "Professional".into(),
                installation_type: "Client".into(),
                ..Default::default()
            },
            supported_builds: super::super::playbook::Manifest::builtin().supported_builds,
        };
        assert!(run(CheckId::SupportedBuild, &context).blocks_install());
        context.system.build = 26200;
        assert_eq!(run(CheckId::SupportedBuild, &context).verdict, Verdict::Pass);
    }

    #[test]
    fn the_activation_check_reports_without_failing() {
        let context = CheckContext { system: SystemInfo::default(), supported_builds: vec![] };
        let result = run(CheckId::Activation, &context);
        assert!(matches!(result.verdict, Verdict::Pass | Verdict::Warn | Verdict::Unknown), "{result:?}");
        assert!(
            matches!(
                result.detail,
                CheckDetail::ActivationOk
                    | CheckDetail::ActivationMissing
                    | CheckDetail::ActivationNoLicence
                    | CheckDetail::ActivationUnknown { .. }
            ),
            "{:?}",
            result.detail
        );
        assert!(!result.blocks_install());
    }

    #[test]
    fn supported_build_does_not_override_an_unsupported_or_unknown_edition() {
        let mut context = CheckContext {
            system: SystemInfo {
                build: 26200,
                revision: 6584,
                installation_type: "Client".into(),
                ..Default::default()
            },
            supported_builds: vec![26200],
        };
        for edition in [
            "",
            "Core",
            "CoreSingleLanguage",
            "EnterpriseS",
            "EnterpriseSN",
            "EnterpriseSEval",
            "EnterpriseSNEval",
            "IoTEnterpriseS",
            "IoTEnterpriseSK",
        ] {
            context.system.edition_id = edition.into();
            let result = run(CheckId::SupportedBuild, &context);
            assert!(result.blocks_install(), "{edition}");
            assert_eq!(result.detail, CheckDetail::EditionUnsupported);
        }
        for edition in ["Professional", "ProfessionalN", "ProfessionalWorkstation", "Enterprise", "Education"]
        {
            context.system.edition_id = edition.into();
            assert_eq!(run(CheckId::SupportedBuild, &context).verdict, Verdict::Pass);
        }
        context.system.installation_type = "Server".into();
        assert!(run(CheckId::SupportedBuild, &context).blocks_install());
    }

    /// A disposable key under HKCU; nothing the app or Windows reads.
    struct TestKey {
        path: String,
        key: Key,
    }

    impl TestKey {
        fn new() -> Self {
            let path = format!(r"SOFTWARE\AtlasOS\AppTests\{}-{:x}", std::process::id(), rand_nanos());
            let key = CURRENT_USER.create(&path).expect("create a test key under HKCU");
            Self { path, key }
        }
    }

    impl Drop for TestKey {
        fn drop(&mut self) {
            let _ = CURRENT_USER.remove_tree(&self.path);
        }
    }

    fn rand_nanos() -> u128 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    }

    #[test]
    fn pending_file_renames_are_read_as_a_multi_string() {
        let test = TestKey::new();
        assert!(!pending_file_renames(&test.key).unwrap(), "missing value means no renames");

        test.key.set_multi_string("PendingFileRenameOperations", &[r"\??\C:\old.dll", ""]).unwrap();
        assert!(pending_file_renames(&test.key).unwrap());

        test.key.set_multi_string("PendingFileRenameOperations", &[""]).unwrap();
        assert!(!pending_file_renames(&test.key).unwrap(), "only empty entries is not a pending rename");

        // A value of the wrong type is a read error, not silently "no renames".
        test.key.set_u32("PendingFileRenameOperations", 1).unwrap();
        assert!(pending_file_renames(&test.key).is_err());
    }

    #[test]
    fn the_com_guard_only_uninitialises_what_it_initialised() {
        std::thread::spawn(|| unsafe {
            // Another owner has put this thread in a single-threaded apartment.
            assert!(CoInitializeEx(None, COINIT_APARTMENTTHREADED).is_ok());
            {
                let guard = ComApartment::enter().expect("an incompatible mode is not an error");
                assert!(!guard.owns_initialisation);
            }
            // The owner's apartment must still be in place: re-entering the
            // same mode reports S_FALSE (already initialised), not S_OK.
            let hr = CoInitializeEx(None, COINIT_APARTMENTTHREADED);
            assert_eq!(hr.0, 1, "S_FALSE expected, the STA was torn down");
            CoUninitialize();
            CoUninitialize();
        })
        .join()
        .unwrap();

        std::thread::spawn(|| {
            let guard = ComApartment::enter().unwrap();
            assert!(guard.owns_initialisation);
            let nested = ComApartment::enter().unwrap();
            assert!(nested.owns_initialisation, "S_FALSE still needs a balancing CoUninitialize");
        })
        .join()
        .unwrap();
    }
}
