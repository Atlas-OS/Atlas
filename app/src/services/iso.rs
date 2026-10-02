//! Build installation media without running Atlas on this PC.
//! Requests are JSON data, never interpolated into PowerShell source.

use std::fs;
use std::io::{BufRead, Write};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

use super::powershell;

/// The oldest Atlas release media can install: the first with a front door
/// script.
pub const MINIMUM_VERSION: &str = super::playbook::FIRST_FRONT_DOOR_VERSION;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Mode {
    #[default]
    Interactive,
    Configured,
    BeforeDesktop,
}

/// What the image worker builds, written to its job as `request.json` and
/// read there by Build-Iso.ps1.
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Request {
    pub reinstall_this_pc: bool,
    pub copy_network_drivers: bool,
    pub update_network_drivers: bool,
    pub drivers: super::preparation::Drivers,
    pub username: String,
    pub source: PathBuf,
    pub output: PathBuf,
    pub archive: PathBuf,
    pub package: PathBuf,
    pub app: PathBuf,
    pub mode: Mode,
    pub options: Vec<String>,
    pub supported_builds: Vec<u32>,
    /// Decide whether the image is a public release from the bundled
    /// catalog alone, as tester builds do, rather than Microsoft's live page.
    pub offline_release_check: bool,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Architecture {
    #[default]
    X64,
    Arm64,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ImageInfo {
    pub editions: Vec<String>,
    pub bytes: u64,
    #[serde(default)]
    pub architecture: Architecture,
}

/// What the image worker is doing, in the order a build does it. A check
/// only inspects.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord)]
pub enum Stage {
    #[default]
    Inspect,
    Copy,
    /// Atlas, its setup files and the answer file are added to the media
    /// beside the Windows image, not into it.
    AddAtlas,
    NetworkDrivers,
    Master,
    Verify,
    Cleanup,
}
impl Stage {
    pub fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "inspect" => Self::Inspect,
            "copy" => Self::Copy,
            "add-atlas" => Self::AddAtlas,
            "network-drivers" => Self::NetworkDrivers,
            "master" => Self::Master,
            "verify" => Self::Verify,
            "cleanup" => Self::Cleanup,
            _ => return None,
        })
    }

    /// The stages of a build, in the order the worker reports them. This
    /// PC's network drivers are prepared only when the ISO includes them.
    pub fn build(network_drivers: bool) -> Vec<Self> {
        [
            Self::Inspect,
            Self::Copy,
            Self::AddAtlas,
            Self::NetworkDrivers,
            Self::Master,
            Self::Verify,
            Self::Cleanup,
        ]
        .into_iter()
        .filter(|stage| network_drivers || *stage != Self::NetworkDrivers)
        .collect()
    }
}

/// Where a package declares that it can finish setup from media.
const SETUP_CAPABILITY: &str = "Executables/AtlasModules/Scripts/Install/iso-setup.json";

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct SetupCapability {
    schema: u32,
    first_sign_in: bool,
}

/// Whether the package can set Windows up from media (the configured and
/// before-desktop modes). Only its iso-setup.json counts: a version number,
/// or the SupportsISO flag in playbook.conf (an AME Wizard setting), is not
/// enough.
pub fn supports_setup(package: &Path) -> bool {
    fs::read_to_string(package.join(SETUP_CAPABILITY))
        .ok()
        .and_then(|text| serde_json::from_str::<SetupCapability>(&text).ok())
        .is_some_and(|capability| capability.schema == 1 && capability.first_sign_in)
}

/// Whether media can install this version: a known one no older than
/// [`MINIMUM_VERSION`].
pub fn supports_version(version: &str) -> bool {
    super::releases::AtlasVersion::parse(version).is_some() && !super::playbook::predates_front_door(version)
}

pub fn validate_options(manifest: &super::playbook::Manifest, options: &[String]) -> Result<()> {
    use std::collections::HashSet;
    let unique: HashSet<_> = options.iter().collect();
    if unique.len() != options.len() || options.iter().any(|o| manifest.option_label(o).is_none()) {
        bail!("Unknown or repeated Atlas option");
    }
    for page in &manifest.pages {
        let selected = page.options.iter().filter(|o| options.contains(&o.name)).count();
        let active = page.depends_on.as_ref().is_none_or(|n| options.contains(n));
        if (!active && selected != 0)
            || (active && page.kind == super::playbook::PageKind::Radio && selected != 1)
        {
            bail!("The Atlas choices are incomplete or inconsistent");
        }
    }
    Ok(())
}

pub fn default_options(manifest: &super::playbook::Manifest) -> Vec<String> {
    let mut options = manifest.default_options();
    for page in &manifest.pages {
        if page.depends_on.as_ref().is_some_and(|n| !options.contains(n)) {
            options.retain(|n| !page.options.iter().any(|o| &o.name == n));
        }
    }
    options
}

/// The choices to show after the files are checked again: the user's own if
/// the package is unchanged (same digest, so the same pages) and they still
/// validate, otherwise the defaults.
pub fn options_after_inspection(
    manifest: &super::playbook::Manifest,
    previous: &[String],
    same_package: bool,
) -> Vec<String> {
    if same_package && validate_options(manifest, previous).is_ok() {
        previous.to_vec()
    } else {
        default_options(manifest)
    }
}

pub fn validate(request: &Request) -> Result<()> {
    anyhow::ensure!(
        !request.update_network_drivers || request.copy_network_drivers,
        "Network driver updates require network driver copying."
    );
    anyhow::ensure!(
        !request.copy_network_drivers || request.reinstall_this_pc,
        "Network drivers can only be copied for reinstalling this PC."
    );
    if !valid_username(&request.username) {
        bail!("Invalid Windows local account name");
    }
    if !request.source.extension().is_some_and(|e| e.eq_ignore_ascii_case("iso")) {
        bail!("Choose a Windows ISO file");
    }
    if !request.output.extension().is_some_and(|e| e.eq_ignore_ascii_case("iso")) {
        bail!("The output filename must end in .iso");
    }
    if request.output.exists() {
        return Err(Failure::new(
            FailureReason::OutputExists,
            "The output already exists; choose a new filename",
        )
        .into());
    }
    let parent = request.output.parent().context("output has no parent")?.canonicalize()?;
    let source = request.source.canonicalize()?;
    if source == parent.join(request.output.file_name().context("missing filename")?) {
        bail!("The source and output must be different files");
    }
    if request.mode != Mode::Interactive && !supports_setup(&request.package) {
        bail!("This package does not support ISO setup");
    }
    if !request.options.iter().all(|option| super::installer::valid_option_name(option)) {
        bail!("Invalid Atlas option identifier");
    }
    Ok(())
}

/// Why Windows would refuse a local account name, so the page can say what
/// to change.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UsernameProblem {
    /// Empty, too long, blank at either end, or using a reserved symbol.
    Invalid,
    /// Ends with a full stop.
    TrailingDot,
    /// The name of a built-in Windows account.
    Reserved,
}

/// The longest local account name Windows accepts, in UTF-16 units.
const MAX_ACCOUNT_NAME_UNITS: usize = 20;

pub fn username_problem(name: &str) -> Option<UsernameProblem> {
    if name.is_empty()
        || name.encode_utf16().count() > MAX_ACCOUNT_NAME_UNITS
        || name.trim() != name
        || name.chars().any(|c| c.is_control() || "\"/\\[]:;|=,+*?<>@".contains(c))
    {
        return Some(UsernameProblem::Invalid);
    }
    if [
        "administrator",
        "guest",
        "defaultaccount",
        "defaultuser0",
        "wdagutilityaccount",
        "system",
        "anonymous logon",
    ]
    .iter()
    .any(|reserved| name.eq_ignore_ascii_case(reserved))
    {
        return Some(UsernameProblem::Reserved);
    }
    name.ends_with('.').then_some(UsernameProblem::TrailingDot)
}

pub fn valid_username(name: &str) -> bool {
    username_problem(name).is_none()
}

/// The setup.json (schema 2) Build-Iso.ps1 puts on media, read only when this
/// executable is the copy Windows Setup staged beside it.
fn staged_settings() -> Option<serde_json::Value> {
    let root = PathBuf::from(std::env::var_os("WINDIR")?).join("AtlasISO");
    if std::env::current_exe().ok()?.canonicalize().ok()?
        != root.join("AtlasManager.exe").canonicalize().ok()?
    {
        return None;
    }
    let value: serde_json::Value =
        serde_json::from_str(&fs::read_to_string(root.join("setup.json")).ok()?).ok()?;
    if value["schema"] != 2 {
        return None;
    }
    Some(value)
}

pub fn is_staged_setup() -> bool {
    staged_settings().is_some()
}

pub fn staged_drivers() -> Option<super::preparation::Drivers> {
    serde_json::from_value(staged_settings()?["drivers"].clone()).ok()
}

/// The setup mode the media was built with.
pub(super) fn staged_mode() -> Option<Mode> {
    serde_json::from_value(staged_settings()?["mode"].clone()).ok()
}

/// The choices made when the media was built, for the modes that carry them.
pub fn staged_options() -> Option<Vec<String>> {
    let settings = staged_settings()?;
    match serde_json::from_value(settings["mode"].clone()).ok()? {
        Mode::Configured | Mode::BeforeDesktop => serde_json::from_value(settings["options"].clone()).ok(),
        Mode::Interactive => None,
    }
}

/// A unique job path for an ISO or USB worker. Staging creates the directory
/// with admin-only access; it is kept after a failure for diagnostics.
pub fn new_job() -> Result<PathBuf> {
    let root = super::recovery_app::media_root(&super::settings::AppPaths::from_process().settings())?;
    let id = SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos();
    Ok(root.join(format!("{}-{id}", std::process::id())))
}

/// Newest jobs kept whatever their age.
const KEPT_JOBS: usize = 20;
/// Age after which any other job is removed.
const JOB_RETENTION: Duration = Duration::from_secs(24 * 60 * 60);

/// Removes jobs beside `current` that are both beyond the newest
/// [`KEPT_JOBS`] and older than [`JOB_RETENTION`]; the age rule spares jobs
/// another instance may still be running. This process's jobs and
/// unrecognised names are never touched.
pub fn prune_jobs(current: &Path) {
    if let Some(root) = current.parent() {
        prune_jobs_in(root);
    }
}

/// Cleans up `app_data/ISO`, where the 0.6.0 release candidates kept their
/// jobs: prunes it like current jobs and deletes the package and notice
/// copies (not evidence) from jobs older than [`JOB_RETENTION`].
pub fn prune_legacy_jobs(app_data: &Path) {
    let root = app_data.join("ISO");
    prune_jobs_in(&root);
    let (Ok(entries), Ok(now)) = (fs::read_dir(&root), SystemTime::now().duration_since(UNIX_EPOCH)) else {
        return;
    };
    for entry in entries.flatten() {
        let stamp = entry.file_name().to_str().and_then(|name| name.split_once('-')?.1.parse::<u128>().ok());
        if stamp.is_some_and(|stamp| now.as_nanos().saturating_sub(stamp) > JOB_RETENTION.as_nanos()) {
            for copy in ["Atlas.apbx", NOTICES] {
                let _ = fs::remove_file(entry.path().join(copy));
            }
        }
    }
    // Only succeeds once no job is left.
    let _ = fs::remove_dir(&root);
}

fn prune_jobs_in(root: &Path) {
    let Ok(now) = SystemTime::now().duration_since(UNIX_EPOCH) else { return };
    let Ok(entries) = fs::read_dir(root) else { return };
    let mut jobs: Vec<(u128, PathBuf)> = entries
        .flatten()
        .filter_map(|entry| {
            let name = entry.file_name();
            let (pid, stamp) = name.to_str()?.split_once('-')?;
            let stamp = stamp.parse().ok()?;
            (pid.parse::<u32>().ok()? != std::process::id() && entry.file_type().ok()?.is_dir())
                .then(|| (stamp, entry.path()))
        })
        .collect();
    jobs.sort_by_key(|job| std::cmp::Reverse(job.0));
    for (stamp, path) in jobs.into_iter().skip(KEPT_JOBS) {
        if now.as_nanos().saturating_sub(stamp) > JOB_RETENTION.as_nanos() {
            let _ = fs::remove_dir_all(path);
        }
    }
}

/// Why an ISO operation failed. The worker sends most reasons as
/// `ATLAS_ERROR:<reason>` before it throws; otherwise the last stage reported
/// picks Check (nothing built yet) or Build.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FailureReason {
    /// The Windows build could not be verified as a public release.
    WindowsReleaseUnknown,
    /// The output file already exists.
    OutputExists,
    /// The destination is not a local NTFS or ReFS volume.
    DestinationFilesystem,
    /// The destination has too little free space.
    DiskSpace,
    /// The image is not a supported client build or architecture.
    WindowsUnsupported,
    /// The ISO contains no supported edition (Home, LTSC).
    EditionUnsupported,
    /// The ISO already carries custom setup content.
    IsoCustomised,
    /// Network drivers from this PC cannot go on media for another architecture.
    NetworkArchitecture,
    /// The Atlas package is too old for ISO creation, or has no front door.
    /// Decided by the app before the worker starts, so it has no marker.
    PackageUnsupported,
    /// The package is no longer the one the files were checked with.
    /// Decided by the app before the worker starts, so it has no marker.
    PackageChanged,
    /// Some other problem while checking the files.
    Check,
    /// Some other problem after the checks passed.
    Build,
}

impl FailureReason {
    pub fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "windows-release-unknown" => Self::WindowsReleaseUnknown,
            "output-exists" => Self::OutputExists,
            "destination-filesystem" => Self::DestinationFilesystem,
            "disk-space" => Self::DiskSpace,
            "windows-unsupported" => Self::WindowsUnsupported,
            "edition-unsupported" => Self::EditionUnsupported,
            "iso-customised" => Self::IsoCustomised,
            "network-architecture" => Self::NetworkArchitecture,
            _ => return None,
        })
    }
}

#[derive(Debug)]
pub struct Failure {
    pub reason: FailureReason,
    detail: String,
}

impl Failure {
    pub fn new(reason: FailureReason, detail: impl Into<String>) -> Self {
        Self { reason, detail: detail.into() }
    }
}

impl std::fmt::Display for Failure {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.reason, self.detail)
    }
}

impl std::error::Error for Failure {}

/// Types a package the app cannot use for ISO creation, so the page can say
/// so instead of pointing at the diagnostics. Other errors pass through.
pub fn package_error(error: anyhow::Error) -> anyhow::Error {
    if error.is::<super::playbook::Unsupported>() {
        Failure::new(FailureReason::PackageUnsupported, format!("{error:#}")).into()
    } else {
        error
    }
}

/// The scripts and data the image worker loads from its job directory.
const WORKER_FILES: &[(&str, &str)] = &[
    ("Build-Iso.ps1", include_str!("../../resources/iso/Build-Iso.ps1")),
    (
        "Windows-Release.ps1",
        include_str!("../../../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1"),
    ),
    ("windows-releases.json", super::windows_release::CATALOG),
    ("Master-Iso.ps1", include_str!("../../resources/iso/Master-Iso.ps1")),
    ("Setup.ps1", include_str!("../../resources/iso/Setup.ps1")),
    ("Desktop.ps1", include_str!("../../resources/iso/Desktop.ps1")),
    ("Desktop-Policy.ps1", include_str!("../../resources/iso/Desktop-Policy.ps1")),
    ("RegistryFile.ps1", super::preparation::REGISTRY_LIBRARY),
    ("Network-Drivers.ps1", include_str!("../../resources/iso/Network-Drivers.ps1")),
];

/// The licence notices placed on the media beside the app.
pub(super) const NOTICES: &str = "THIRD-PARTY-NOTICES.txt";

/// The notices beside the worker while it builds media: only copied onto the
/// media, never run, and too large (4 MB) to pass through the protected
/// staging. Removed when dropped, so no early return leaves them in the job.
struct NoticesCopy(PathBuf);

impl NoticesCopy {
    fn write(dir: &Path) -> Result<Self> {
        let copy = Self(dir.join(NOTICES));
        fs::write(&copy.0, super::licenses::TEXT)?;
        Ok(copy)
    }
}

impl Drop for NoticesCopy {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

pub fn run(
    request: &Request,
    dir: &Path,
    inspect: bool,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Stage),
) -> Result<Output> {
    log::info!("ISO operation started; inspect={inspect}; diagnostics={}", dir.display());
    validate(request)?;
    let request_json = serde_json::to_vec(request)?;
    let mut files: Vec<(&str, &[u8])> =
        WORKER_FILES.iter().map(|(name, text)| (*name, text.as_bytes())).collect();
    files.push(("DriverPolicy.reg", request.drivers.policy()));
    files.push(("request.json", &request_json));
    super::recovery_app::stage_media_job(dir, &files)?;
    let _notices = if inspect { None } else { Some(NoticesCopy::write(dir)?) };
    let mut log = fs::File::create(dir.join("build.log"))?;
    let operation = if inspect { "Inspect" } else { "Build" };
    let child = powershell::start_worker(dir, "Build-Iso.ps1", "request.json", operation, &log)
        .context("start Windows image worker")?;
    let (status, output) =
        powershell::follow_worker(child, dir, cancel, |stdout| read_output(stdout, &mut log, report))?;
    if !status.success() {
        let reason = output.reason.unwrap_or(if output.stage == Stage::Inspect {
            FailureReason::Check
        } else {
            FailureReason::Build
        });
        return Err(Failure::new(
            reason,
            format!("Windows image worker failed. See {}", dir.join("build.log").display()),
        )
        .into());
    }
    if inspect && output.image.is_none() {
        bail!("Windows did not return image information");
    }
    Ok(output)
}

/// What the image worker reported on stdout.
#[derive(Default)]
pub struct Output {
    pub image: Option<ImageInfo>,
    reason: Option<FailureReason>,
    /// The last stage announced.
    stage: Stage,
    /// This PC's network adapters use drivers that come with Windows, so the
    /// build included none.
    pub network_drivers_inbox: bool,
}

/// Reads the worker's markers to the end, copying every line to `log`.
fn read_output(stream: impl BufRead, log: &mut impl Write, mut report: impl FnMut(Stage)) -> Output {
    let mut output = Output::default();
    powershell::read_lines(stream, log, |line| {
        if let Some(typed) = line.strip_prefix("ATLAS_ERROR:").and_then(FailureReason::parse) {
            output.reason = Some(typed);
        }
        if let Some(stage) = line.strip_prefix("ATLAS_STAGE:").and_then(Stage::parse) {
            output.stage = stage;
            report(stage);
        }
        if let Some(json) = line.strip_prefix("ATLAS_RESULT:") {
            output.image = serde_json::from_str(json).ok();
        }
        if line == "ATLAS_NOTE:network-drivers-inbox" {
            output.network_drivers_inbox = true;
        }
    });
    output
}

/// The files and choices for [`create`], as the ISO page holds them.
pub struct CreateInput {
    /// Check the files and read the image, rather than build media.
    pub inspect: bool,
    /// Add the package bundled with this build instead of `archive`.
    pub bundled: bool,
    pub archive: PathBuf,
    /// The package the last check extracted; a build refuses any other.
    pub inspected_package: Option<PathBuf>,
    pub source: PathBuf,
    pub output: PathBuf,
    pub mode: Mode,
    pub options: Vec<String>,
    pub drivers: super::preparation::Drivers,
    pub username: String,
    pub reinstall_this_pc: bool,
    pub copy_network_drivers: bool,
    pub update_network_drivers: bool,
}

/// What a check or build leaves: the image a check read, the extracted
/// package and its manifest, and whether a build asked to include this PC's
/// network drivers found none to include (its adapters use drivers that come
/// with Windows).
pub struct Created {
    pub image: Option<ImageInfo>,
    pub package: PathBuf,
    pub manifest: super::playbook::Manifest,
    pub network_drivers_inbox: bool,
}

/// The architecture of this PC's processor, whatever this app was built
/// for: an x64 build running on Arm64 Windows reports Arm64.
pub fn host_architecture() -> Architecture {
    use windows::Win32::System::SystemInformation::IMAGE_FILE_MACHINE_ARM64;
    use windows::Win32::System::Threading::{GetCurrentProcess, IsWow64Process2};
    let (mut process, mut native) = (Default::default(), Default::default());
    // SAFETY: the current process's pseudo handle and two out parameters.
    let ok = unsafe { IsWow64Process2(GetCurrentProcess(), &mut process, Some(&mut native)) }.is_ok();
    if ok && native == IMAGE_FILE_MACHINE_ARM64 { Architecture::Arm64 } else { Architecture::X64 }
}

/// Checks the files or builds the media in the job directory `job`. A failure
/// is also written to the job for the diagnostics link.
pub fn create(
    input: CreateInput,
    job: &Path,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Stage),
) -> Result<Created> {
    let CreateInput {
        inspect,
        bundled,
        archive,
        inspected_package,
        source,
        output,
        mode,
        options,
        drivers,
        username,
        reinstall_this_pc,
        copy_network_drivers,
        update_network_drivers,
    } = input;
    // Inspect and add the same archive bytes even if the original
    // file is replaced while the worker is running. The copy is only
    // needed until the worker has put it on the media.
    let snapshot = std::env::temp_dir()
        .join(format!("Atlas-{}.apbx", job.file_name().unwrap_or_default().to_string_lossy()));
    let operation = || -> Result<Created> {
        // The job exists before anything else can fail, so every
        // failure leaves its error there for the diagnostics link.
        // The worker's files are staged into it later.
        super::recovery_app::stage_media_job(job, &[])?;
        let archive = if bundled { bundled_archive()? } else { archive };
        std::io::copy(
            &mut fs::File::open(&archive)?,
            &mut fs::OpenOptions::new().write(true).create_new(true).open(&snapshot)?,
        )?;
        let (package, manifest) = super::playbook::extract_into(
            &snapshot,
            &super::settings::AppPaths::from_process().playbooks(),
            |_, _| {},
        )
        .map_err(package_error)?;
        if !inspect && inspected_package.as_ref() != Some(&package) {
            return Err(Failure::new(
                FailureReason::PackageChanged,
                "The package changed after inspection. Go back and check the files again.",
            )
            .into());
        }
        let options = if inspect { default_options(&manifest) } else { options };
        if !supports_version(&manifest.version) {
            return Err(Failure::new(
                FailureReason::PackageUnsupported,
                format!("ISO creation requires Atlas {MINIMUM_VERSION} or newer."),
            )
            .into());
        }
        validate_options(&manifest, &options)?;
        let request = Request {
            reinstall_this_pc,
            copy_network_drivers,
            update_network_drivers,
            drivers,
            username,
            source,
            archive: snapshot.clone(),
            output,
            package: package.clone(),
            app: std::env::current_exe()?,
            mode: if inspect { Mode::Interactive } else { mode },
            options,
            supported_builds: manifest.supported_builds.clone(),
            offline_release_check: !super::windows_release::REFRESH_ONLINE,
        };
        let output = run(&request, job, inspect, cancel, report)?;
        Ok(Created {
            image: output.image,
            package,
            manifest,
            network_drivers_inbox: output.network_drivers_inbox,
        })
    };
    let result = operation();
    let _ = fs::remove_file(&snapshot);
    if let Err(error) = &result {
        log::error!("ISO operation failed: {error:#}");
        let _ = fs::write(job.join("error.txt"), format!("{error:#}"));
    }
    result
}

/// The bundled package, written to the downloads folder so it can be added
/// to the media.
fn bundled_archive() -> Result<PathBuf> {
    #[cfg(feature = "embedded-playbook")]
    {
        super::embedded::materialize(&super::settings::AppPaths::from_process())
    }
    #[cfg(not(feature = "embedded-playbook"))]
    {
        bail!("this build has no bundled package")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::playbook;
    use crate::services::test_support::TempDir;

    #[test]
    fn refused_account_names_say_what_to_change() {
        for name in ["Administrator", "guest", "SYSTEM", "Anonymous Logon"] {
            assert_eq!(username_problem(name), Some(UsernameProblem::Reserved), "{name:?}");
        }
        for name in ["name.", "José.", "Administrator."] {
            assert_eq!(username_problem(name), Some(UsernameProblem::TrailingDot), "{name:?}");
        }
        for name in
            ["", " admin", "admin ", "user/name", "user\nname", "name@example", "123456789012345678901"]
        {
            assert_eq!(username_problem(name), Some(UsernameProblem::Invalid), "{name:?}");
        }
        // Up to 20 UTF-16 units, in any script.
        for name in ["Atlas", "小明", "Мария", "José", "माया", "ผู้ใช้", "12345678901234567890"]
        {
            assert_eq!(username_problem(name), None, "{name:?}");
        }
    }

    #[test]
    fn iso_support_begins_with_atlas_06() {
        for version in ["0.4.1", "0.5.0", "invalid"] {
            assert!(!supports_version(version));
        }
        for version in ["0.6.0", "0.6.0-beta.1", "0.7.0", "1.0.0", MINIMUM_VERSION] {
            assert!(supports_version(version));
        }
    }

    fn request(dir: &Path) -> Request {
        Request {
            reinstall_this_pc: false,
            copy_network_drivers: false,
            update_network_drivers: false,
            drivers: Default::default(),
            username: "Atlas".into(),
            source: dir.join("Windows.iso"),
            output: dir.join("Atlas.iso"),
            archive: dir.join("Atlas.apbx"),
            package: dir.to_path_buf(),
            app: dir.join("AtlasManager.exe"),
            mode: Mode::Interactive,
            options: vec![],
            supported_builds: vec![26100],
            offline_release_check: false,
        }
    }

    /// Build-Iso.ps1 reads request.json by these names; one the app stopped
    /// writing would reach the worker as `$null`.
    #[test]
    fn the_request_carries_every_field_the_worker_reads() {
        let request = Request { mode: Mode::BeforeDesktop, ..request(Path::new("C:\\Jobs")) };
        let json = serde_json::to_value(&request).unwrap();
        let script = include_str!("../../resources/iso/Build-Iso.ps1");
        let read: std::collections::BTreeSet<&str> = script
            .split("$request.")
            .skip(1)
            .map(|rest| &rest[..rest.find(|c: char| !c.is_ascii_alphanumeric()).unwrap_or(rest.len())])
            // PSObject is PowerShell's own view of the object, not a field.
            .filter(|name| !name.is_empty() && *name != "PSObject")
            .collect();
        assert!(read.len() >= 10, "{read:?}");
        for name in read {
            assert!(json.get(name).is_some(), "Build-Iso.ps1 reads {name}, which the request lacks");
        }
        assert_eq!(json["mode"], "before-desktop");
        assert_eq!(json["drivers"], "automatic");
    }

    #[test]
    fn every_script_setup_loads_goes_onto_the_media() {
        // Setup.ps1 runs from %WINDIR%\AtlasISO, where only what Build-Iso
        // copies from the job is; a script it dot-sources must be in both.
        let setup = include_str!("../../resources/iso/Setup.ps1");
        let build = include_str!("../../resources/iso/Build-Iso.ps1");
        let loaded: Vec<&str> = setup
            .lines()
            .filter_map(|line| line.trim().strip_prefix(". (Join-Path $root '"))
            .filter_map(|rest| rest.strip_suffix("')"))
            .collect();
        assert!(
            loaded.contains(&"RegistryFile.ps1"),
            "setup applies the drivers choice with the shared import"
        );
        for name in loaded {
            assert!(WORKER_FILES.iter().any(|(file, _)| *file == name), "the job lacks {name}");
            assert!(build.contains(&format!("'{name}'")), "Build-Iso.ps1 doesn't copy {name} onto the media");
        }
    }

    #[test]
    fn the_validation_tool_stages_the_same_job() {
        // Run-IsoValidation.ps1 runs the worker outside the app, so it must
        // provide every file the app stages and run the worker from that job.
        let tool = include_str!("../../tools/Run-IsoValidation.ps1");
        let names =
            WORKER_FILES.iter().map(|(name, _)| *name).chain(["DriverPolicy.reg", "request.json", NOTICES]);
        for name in names {
            assert!(tool.contains(&format!("'{name}'")), "the validation tool does not provide {name}");
        }
        assert!(tool.contains("(Join-Path $root 'Build-Iso.ps1')"), "the worker must run from its job");
    }

    #[test]
    fn image_architecture_is_typed_and_defaults_to_x64() {
        let arm: ImageInfo =
            serde_json::from_str(r#"{"editions":["Windows 11 Pro"],"bytes":1,"architecture":"arm64"}"#)
                .unwrap();
        assert_eq!(arm.architecture, Architecture::Arm64);
        let older: ImageInfo = serde_json::from_str(r#"{"editions":["Windows 11 Pro"],"bytes":1}"#).unwrap();
        assert_eq!(older.architecture, Architecture::X64);
    }

    /// Every stage the worker announces must be understood here, or the
    /// progress shown stops moving.
    #[test]
    fn stage_protocol_is_closed() {
        let script = include_str!("../../resources/iso/Build-Iso.ps1");
        let stages: Vec<&str> =
            script.lines().filter_map(|line| line.trim().strip_prefix("Write-Stage ")).collect();
        assert!(!stages.is_empty());
        for stage in stages {
            assert!(Stage::parse(stage).is_some(), "unknown worker stage {stage:?}");
        }
        assert_eq!(Stage::parse("done"), None);
        assert_eq!(Stage::parse("inject"), None, "the stage is add-atlas");
    }

    /// The page lists a build's stages and ticks off those before the one
    /// reported last, so the worker must report every stage once, in that order.
    #[test]
    fn a_build_reports_its_stages_in_checklist_order() {
        let script = include_str!("../../resources/iso/Build-Iso.ps1");
        // The main flow starts with inspect; a helper defined above it reports
        // copy again from inside the copy stage.
        let reported: Vec<Stage> = script
            .lines()
            .filter_map(|line| line.trim().strip_prefix("Write-Stage "))
            .skip_while(|stage| *stage != "inspect")
            .map(|stage| Stage::parse(stage).expect("a known stage"))
            .collect();
        assert_eq!(reported, Stage::build(true));
        assert_eq!(
            Stage::build(false),
            [Stage::Inspect, Stage::Copy, Stage::AddAtlas, Stage::Master, Stage::Verify, Stage::Cleanup]
        );
    }

    #[test]
    fn a_badly_encoded_line_hides_neither_the_stage_nor_the_result() {
        let mut stages = vec![];
        let output = read_output(
            &b"ATLAS_STAGE:copy\r\nE: Donn\x82es\r\nATLAS_ERROR:disk-space\r\nATLAS_RESULT:{\"editions\":[\"Windows 11 Pro\"],\"bytes\":1}\r\n"[..],
            &mut Vec::new(),
            |stage| stages.push(stage),
        );
        assert_eq!(stages, [Stage::Copy]);
        assert_eq!(output.stage, Stage::Copy);
        assert_eq!(output.reason, Some(FailureReason::DiskSpace));
        assert!(output.image.is_some());
        assert!(!output.network_drivers_inbox);
    }

    #[test]
    fn a_build_says_when_this_pc_had_no_network_drivers_to_include() {
        let script = include_str!("../../resources/iso/Build-Iso.ps1");
        assert!(script.contains("ATLAS_NOTE:network-drivers-inbox"), "the worker writes the note");
        let output = read_output(
            &b"ATLAS_STAGE:network-drivers\r\nATLAS_NOTE:network-drivers-inbox\r\nATLAS_STAGE:master\r\n"[..],
            &mut Vec::new(),
            |_| {},
        );
        assert!(output.network_drivers_inbox);
    }

    #[test]
    fn failure_reasons_match_the_worker_markers() {
        // Every marker the worker writes must be understood here, or the page
        // falls back to generic advice.
        let script = include_str!("../../resources/iso/Build-Iso.ps1");
        for marker in script.lines().filter_map(|line| {
            let start = line.find("Fail '")? + "Fail '".len();
            line[start..].split('\'').next()
        }) {
            assert!(FailureReason::parse(marker).is_some(), "unknown worker marker {marker:?}");
        }
        assert_eq!(
            FailureReason::parse("windows-release-unknown"),
            Some(FailureReason::WindowsReleaseUnknown)
        );
        assert_eq!(FailureReason::parse("check"), None);
        assert_eq!(FailureReason::parse("network-architecture"), Some(FailureReason::NetworkArchitecture));
    }

    #[test]
    fn unusable_packages_are_typed_and_other_errors_pass_through() {
        let old = package_error(playbook::Unsupported { version: "0.5.0".into() }.into());
        assert_eq!(
            old.downcast_ref::<Failure>().map(|failure| failure.reason),
            Some(FailureReason::PackageUnsupported)
        );
        assert!(package_error(anyhow::anyhow!("unreadable archive")).downcast_ref::<Failure>().is_none());
    }

    #[test]
    fn checking_the_same_package_again_keeps_valid_choices() {
        use playbook::PageKind;
        let manifest = playbook::Manifest::builtin();
        let defaults = default_options(&manifest);
        // A valid choice other than the default on a top-level radio page.
        let page = manifest
            .pages
            .iter()
            .find(|page| page.kind == PageKind::Radio && page.depends_on.is_none() && page.options.len() > 1)
            .expect("a radio page with a choice");
        let other = page.options.iter().find(|o| !defaults.contains(&o.name)).unwrap().name.clone();
        let mut chosen: Vec<String> =
            defaults.iter().filter(|n| !page.options.iter().any(|o| &o.name == *n)).cloned().collect();
        chosen.push(other);
        assert!(validate_options(&manifest, &chosen).is_ok());
        assert_eq!(options_after_inspection(&manifest, &chosen, true), chosen);
        assert_eq!(options_after_inspection(&manifest, &chosen, false), defaults);
        let mut repeated = chosen.clone();
        repeated.push(chosen[0].clone());
        assert_eq!(options_after_inspection(&manifest, &repeated, true), defaults);
        assert_eq!(options_after_inspection(&manifest, &[], true), defaults);
    }

    #[test]
    fn pruning_removes_only_old_jobs_beyond_the_newest() {
        let temp = TempDir::new("iso-prune");
        let root = temp.path();
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
        let old = now - 2 * JOB_RETENTION.as_nanos();
        let other = std::process::id().wrapping_add(1);
        // Thirty old jobs of another process, one recent one and a job of this process.
        for index in 0..30u128 {
            fs::create_dir_all(root.join(format!("{other}-{}", old - index))).unwrap();
        }
        let recent = root.join(format!("{other}-{now}"));
        let own = root.join(format!("{}-{}", std::process::id(), old - 100));
        let unrelated = root.join("notes-1");
        for dir in [&recent, &own, &unrelated] {
            fs::create_dir_all(dir).unwrap();
        }
        prune_jobs(&root.join(format!("{}-{now}", std::process::id())));
        assert!(recent.is_dir() && own.is_dir() && unrelated.is_dir());
        // The newest twenty other jobs remain: the recent one and nineteen old ones.
        let kept: Vec<u128> =
            (0..30u128).filter(|index| root.join(format!("{other}-{}", old - index)).is_dir()).collect();
        assert_eq!(kept, (0..(KEPT_JOBS as u128 - 1)).collect::<Vec<_>>());
    }

    #[test]
    fn release_candidate_jobs_are_pruned_and_lose_their_copies() {
        let temp = TempDir::new("iso-legacy");
        let root = temp.path().join("ISO");
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
        let old = now - 2 * JOB_RETENTION.as_nanos();
        let other = std::process::id().wrapping_add(1);
        // A recent job may still be in use by a release candidate's window.
        let recent = root.join(format!("{other}-{now}"));
        for job in
            (0..25u128).map(|index| root.join(format!("{other}-{}", old - index))).chain([recent.clone()])
        {
            fs::create_dir_all(&job).unwrap();
            for name in ["Atlas.apbx", NOTICES, "build.log", "error.txt"] {
                fs::write(job.join(name), name).unwrap();
            }
        }
        prune_legacy_jobs(temp.path());
        let kept: Vec<PathBuf> = fs::read_dir(&root).unwrap().flatten().map(|entry| entry.path()).collect();
        assert_eq!(kept.len(), KEPT_JOBS);
        for job in kept.iter().filter(|job| **job != recent) {
            assert!(!job.join("Atlas.apbx").exists() && !job.join(NOTICES).exists(), "{}", job.display());
            assert!(job.join("build.log").is_file() && job.join("error.txt").is_file());
        }
        assert!(recent.join("Atlas.apbx").is_file() && recent.join(NOTICES).is_file());

        // Once no job is left, neither is the directory.
        let empty = TempDir::new("iso-legacy-empty");
        fs::create_dir_all(empty.path().join("ISO")).unwrap();
        prune_legacy_jobs(empty.path());
        assert!(!empty.path().join("ISO").exists());
        prune_legacy_jobs(empty.path());
    }

    #[test]
    fn iso_options_respect_required_groups_and_dependencies() {
        let builtin = playbook::Manifest::builtin();
        assert!(validate_options(&builtin, &default_options(&builtin)).is_ok(), "the built-in defaults");
        // A choice of two, extras, and a choice of two shown only with `extra`.
        let manifest = playbook::parse(
            "<Playbook><Version>0.6.0</Version><FeaturePages>\
             <RadioPage DefaultOption=\"a1\"><Options><RadioOption><Name>a1</Name></RadioOption><RadioOption><Name>a2</Name></RadioOption></Options></RadioPage>\
             <CheckboxPage><Options><CheckboxOption><Name>extra</Name></CheckboxOption></Options></CheckboxPage>\
             <RadioPage DependsOn=\"extra\" DefaultOption=\"b1\"><Options><RadioOption><Name>b1</Name></RadioOption><RadioOption><Name>b2</Name></RadioOption></Options></RadioPage>\
             </FeaturePages></Playbook>",
        )
        .unwrap();
        let options = |names: &[&str]| names.iter().map(|name| name.to_string()).collect::<Vec<_>>();
        assert_eq!(default_options(&manifest), options(&["a1"]), "a hidden page's default is dropped");
        assert!(validate_options(&manifest, &options(&["a1"])).is_ok());
        assert!(validate_options(&manifest, &options(&["a1", "extra", "b2"])).is_ok());
        for refused in
            [&[][..], &["a1", "a2"], &["a1", "a1"], &["a1", "shell-command"], &["a1", "b1"], &["a1", "extra"]]
        {
            assert!(validate_options(&manifest, &options(refused)).is_err(), "{refused:?}");
        }
    }

    #[test]
    fn existing_outputs_and_unsupported_setup_packages_are_refused() {
        let temp = TempDir::new("iso-validation");
        let dir = temp.path().to_path_buf();
        let mut request = request(&dir);
        let (source, output) = (request.source.clone(), request.output.clone());
        fs::write(&source, b"source").unwrap();
        assert!(validate(&request).is_ok());
        request.copy_network_drivers = true;
        assert!(validate(&request).is_err());
        request.reinstall_this_pc = true;
        assert!(validate(&request).is_ok());
        request.update_network_drivers = true;
        request.copy_network_drivers = false;
        assert!(validate(&request).is_err());
        request.update_network_drivers = false;
        fs::write(&output, b"keep").unwrap();
        let existing = validate(&request).unwrap_err();
        assert_eq!(existing.downcast_ref::<Failure>().map(|f| f.reason), Some(FailureReason::OutputExists));
        assert_eq!(fs::read(&output).unwrap(), b"keep");
        request.output = source.clone();
        assert!(validate(&request).is_err());
        request.output = dir.join("new.iso");
        request.mode = Mode::Configured;
        assert!(validate(&request).is_err());
        fs::create_dir_all(dir.join(SETUP_CAPABILITY).parent().unwrap()).unwrap();
        fs::write(dir.join(SETUP_CAPABILITY), r#"{"schema":1,"firstSignIn":true}"#).unwrap();
        assert!(validate(&request).is_ok());
        fs::write(dir.join(SETUP_CAPABILITY), r#"{"schema":2,"firstSignIn":true}"#).unwrap();
        assert!(validate(&request).is_err());
    }
}
