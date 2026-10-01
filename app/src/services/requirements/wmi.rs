//! WMI queries over COM, read so that a failure is never mistaken for a
//! shorter answer, and the COM apartment they run in.

use std::sync::Mutex;
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use windows::Win32::Foundation::RPC_E_CHANGED_MODE;
use windows::Win32::System::Com::{
    CLSCTX_INPROC_SERVER, COINIT_MULTITHREADED, CoCreateInstance, CoInitializeEx, CoSetProxyBlanket,
    CoTaskMemFree, CoUninitialize, EOAC_NONE, RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE,
};
use windows::Win32::System::Rpc::{RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE};
use windows::Win32::System::Variant::{VARIANT, VT_EMPTY, VT_NULL, VariantClear, VariantToStringAlloc};
use windows::Win32::System::Wmi::{
    IWbemClassObject, IWbemContext, IWbemLocator, WBEM_FLAG_CONNECT_USE_MAX_WAIT, WBEM_FLAG_FORWARD_ONLY,
    WBEM_FLAG_RETURN_IMMEDIATELY, WBEM_S_TIMEDOUT, WbemLocator,
};
use windows::core::{BSTR, HSTRING, IUnknown, PCWSTR};

/// How long one WMI query may run in total, and the slice after which the
/// enumerator hands control back so that total can be enforced.
const WMI_QUERY_DEADLINE: Duration = Duration::from_secs(20);
const WMI_ROW_WAIT: Duration = Duration::from_secs(1);

/// A COM apartment for the current thread. Only an initialisation this guard
/// performed is undone when it drops; if the thread already belongs to a
/// different apartment model, COM is used as it is and left alone.
pub(super) struct ComApartment {
    owns_initialisation: bool,
}

impl ComApartment {
    pub(super) fn enter() -> Result<Self> {
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

/// What one turn of an enumerator produced.
enum Fetch<R> {
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
fn drain_rows<R, T>(
    what: &str,
    mut next: impl FnMut() -> Result<Fetch<R>>,
    mut value: impl FnMut(&R) -> Result<Option<T>>,
    deadline: Instant,
) -> Result<Vec<T>> {
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

/// Runs a WQL query and returns one property of every row as text; rows
/// without a value for it are left out. Fails rather than returning fewer
/// rows when the provider fails part-way, a property cannot be read, or
/// the query overruns its deadline.
pub(super) fn wmi_strings(namespace: &str, query: &str, property: &str) -> Result<Vec<String>> {
    Ok(wmi_query(namespace, query, &[property])?
        .into_iter()
        .filter_map(|mut row| row.pop().flatten())
        .collect())
}

/// Runs a WQL query and returns the named properties of every row as text,
/// in the order given; `None` where a row has no value for one.
pub(super) fn wmi_query(
    namespace: &str,
    query: &str,
    properties: &[&str],
) -> Result<Vec<Vec<Option<String>>>> {
    // One WMI query at a time: providers that are loading on first use have
    // answered concurrent queries with nothing.
    static ONE_AT_A_TIME: Mutex<()> = Mutex::new(());
    let _turn = ONE_AT_A_TIME.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    let _apartment = ComApartment::enter()?;
    let deadline = Instant::now() + WMI_QUERY_DEADLINE;
    let property_names: Vec<(HSTRING, &str)> =
        properties.iter().map(|property| (HSTRING::from(*property), *property)).collect();
    unsafe {
        let locator: IWbemLocator =
            CoCreateInstance(&WbemLocator, None, CLSCTX_INPROC_SERVER).context("create the WMI locator")?;
        // The connection has a time limit too: Windows caps it at two
        // minutes, and without the flag it has none.
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
        set_proxy_security(&services)?;
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
        set_proxy_security(&enumerator)?;

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
            |object| {
                let mut row = Vec::with_capacity(property_names.len());
                for (name, label) in &property_names {
                    row.push(property_text(object, name, label)?);
                }
                Ok(Some(row))
            },
            deadline,
        )
    }
}

/// Calls through `proxy` authenticate as this user and let WMI impersonate
/// them, as the providers expect.
unsafe fn set_proxy_security<'a, T>(proxy: &'a T) -> Result<()>
where
    &'a T: Into<&'a IUnknown>,
{
    unsafe {
        CoSetProxyBlanket(
            proxy.into(),
            RPC_C_AUTHN_WINNT,
            RPC_C_AUTHZ_NONE,
            PCWSTR::null(),
            RPC_C_AUTHN_LEVEL_CALL,
            RPC_C_IMP_LEVEL_IMPERSONATE,
            None,
            EOAC_NONE,
        )?;
    }
    Ok(())
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
            drain_rows::<&str, String>(
                "q",
                || turns.pop().unwrap(),
                |_| anyhow::bail!("no such property"),
                far
            )
            .is_err()
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
        assert!(drain_rows::<&str, String>("q", || Ok(Fetch::Timeout), |_| Ok(None), past).is_err());
        // A genuinely empty set is fine.
        assert!(drain_rows::<&str, String>("q", || Ok(Fetch::End), |_| Ok(None), far).unwrap().is_empty());
    }

    #[test]
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
