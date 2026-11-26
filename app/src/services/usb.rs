//! A Windows installation USB writer, never a raw ISO-to-disk copy, and what
//! the USB page needs to offer only drives and ISOs it can write.
use std::fs;
use std::io::{BufRead, Write};
use std::path::{Component, Path, PathBuf, Prefix};
use std::process::Child;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use super::powershell;

/// The smallest drive the worker writes to (Test-AtlasUsbDisk in Write-Usb.ps1).
pub const MIN_BYTES: u64 = 8 << 30;
/// The smallest size USB drives are sold in that holds [`MIN_BYTES`]: one sold
/// as 8 GB holds less than 8 GiB.
pub const MIN_SOLD_GB: u64 = 16;
// Every drive sold as 16 GB, holding at least 88% of it (see `sold_size`), is large enough.
const _: () = assert!(MIN_BYTES > 8_000_000_000 && MIN_SOLD_GB * 880_000_000 >= MIN_BYTES);

/// The largest FAT32 partition Windows formats, the room the worker leaves for
/// the partition table, and the room it keeps free beyond the files.
const PARTITION_LIMIT: u64 = 32_000_000_000;
const PARTITION_RESERVE: u64 = 16 << 20;
const PARTITION_HEADROOM: u64 = 512 << 20;

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Drive {
    pub number: u32,
    pub name: String,
    pub serial: String,
    pub unique_id: String,
    pub path: String,
    pub size: u64,
    /// The letters of its volumes, such as "F".
    #[serde(default)]
    pub letters: Vec<String>,
    /// Smaller than [`MIN_BYTES`]: listed, so the user sees why it can't be used.
    #[serde(default)]
    pub too_small: bool,
}

/// What identifies a drive to the worker, which refuses to change one whose
/// identity differs from the one the app sends (Assert-AtlasUsbIdentity in
/// Write-Usb.ps1, which a test keeps in step).
#[cfg(test)]
const IDENTITY: [&str; 6] = ["number", "name", "serial", "uniqueId", "path", "size"];

impl Drive {
    /// Whether `other` is this drive as a later list reports it, for picking
    /// it again. Its number changes when another disk comes or goes, and its
    /// identifier can change when it is plugged in again, so the serial
    /// number decides then, with the model and size it was sold as. Generic
    /// drives can share all three, so erasing goes by
    /// [`Drive::same_identity`].
    pub fn same_device(&self, other: &Drive) -> bool {
        let serial = self.serial.trim();
        (!self.unique_id.is_empty() && self.unique_id == other.unique_id)
            || (!serial.is_empty()
                && serial == other.serial.trim()
                && self.name == other.name
                && self.size == other.size)
    }

    /// Whether `other` is the very drive this one was, by every part of the
    /// identity the worker checks before erasing (see [`IDENTITY`]): the
    /// only match that carries the user's agreement to erase it.
    pub fn same_identity(&self, other: &Drive) -> bool {
        self.number == other.number
            && self.name == other.name
            && self.serial == other.serial
            && self.unique_id == other.unique_id
            && self.path == other.path
            && self.size == other.size
    }

    /// Whether `path` is on one of its volumes.
    pub fn holds(&self, path: &Path) -> bool {
        drive_letter(path).is_some_and(|letter| {
            self.letters
                .iter()
                .any(|own| own.chars().next().is_some_and(|own| own.eq_ignore_ascii_case(&letter)))
        })
    }

    /// Whether `bytes` of installation files fit the partition the worker
    /// makes, as it decides before erasing.
    pub fn fits(&self, bytes: u64) -> bool {
        bytes.saturating_add(PARTITION_HEADROOM) <= partition_bytes(self.size)
    }
}

/// The installation partition the worker makes on a drive of `size` bytes:
/// up to 32 GB, in whole MiB.
fn partition_bytes(size: u64) -> u64 {
    (PARTITION_LIMIT.min(size.saturating_sub(PARTITION_RESERVE)) >> 20) << 20
}

/// The letter of the drive `path` is on, for a path that starts with one.
pub fn drive_letter(path: &Path) -> Option<char> {
    match path.components().next()? {
        Component::Prefix(prefix) => match prefix.kind() {
            Prefix::Disk(letter) | Prefix::VerbatimDisk(letter) => {
                Some((letter as char).to_ascii_uppercase())
            }
            _ => None,
        },
        _ => None,
    }
}

/// A size as drives are sold, which is not as Windows shows it: a drive sold
/// as 256 GB holds 256 billion bytes, which Windows calls 238 GB.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum SoldSize {
    Gigabytes(u64),
    Terabytes(f64),
}

/// The size `bytes` is sold as. Hard drives and most solid-state drives are
/// sold in round tens of gigabytes, which they hold to within a fraction of
/// a per cent; flash drives in powers of two, of which they hold from about
/// 88% to a little over.
pub fn sold_size(bytes: u64) -> SoldSize {
    let gb = bytes as f64 / 1e9;
    let tens = (gb / 10.).round() * 10.;
    if gb >= 100. && (gb - tens).abs() <= gb * 0.001 {
        return if tens >= 1000. {
            SoldSize::Terabytes(tens / 1000.)
        } else {
            SoldSize::Gigabytes(tens as u64)
        };
    }
    let mut power = 1u64;
    while ((power * 2) as f64) <= gb {
        power *= 2;
    }
    let label = if gb <= power as f64 * 1.03 {
        power
    } else if gb >= (power * 2) as f64 * 0.88 {
        power * 2
    } else {
        return SoldSize::Gigabytes(gb.round() as u64);
    };
    if label >= 1024 { SoldSize::Terabytes((label / 1024) as f64) } else { SoldSize::Gigabytes(label) }
}

/// A stage of writing a USB drive, in the order the worker reports them.
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Stage {
    /// Reading the ISO, splitting a large image and hashing every file;
    /// nothing on the drive has changed yet.
    Prepare,
    Format,
    Copy,
    /// Reading every file back from the drive.
    Verify,
    Eject,
}

impl Stage {
    pub const ALL: [Stage; 5] = [Stage::Prepare, Stage::Format, Stage::Copy, Stage::Verify, Stage::Eject];

    fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "prepare" => Self::Prepare,
            "format" => Self::Format,
            "copy" => Self::Copy,
            "verify" => Self::Verify,
            "eject" => Self::Eject,
            _ => return None,
        })
    }

    /// Its share of a whole write, from the time each typically takes on a
    /// USB 3 drive: copying writes every byte, and checking reads them back.
    fn weight(self) -> f32 {
        match self {
            Self::Prepare => 0.15,
            Self::Format => 0.03,
            Self::Copy => 0.5,
            Self::Verify => 0.3,
            Self::Eject => 0.02,
        }
    }
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct Progress {
    pub stage: String,
    pub done: u64,
    pub total: u64,
}

impl Progress {
    /// How far through its stage the worker is, when it reports bytes.
    pub fn fraction(&self) -> Option<f32> {
        (self.total > 0).then(|| (self.done as f64 / self.total as f64).clamp(0., 1.) as f32)
    }

    /// The stage it reports; an unknown one counts as the first.
    pub fn stage(&self) -> Stage {
        Stage::parse(&self.stage).unwrap_or(Stage::Prepare)
    }

    /// How far through the whole write: every earlier stage, and this one by
    /// its own fraction. A stage that reports no bytes counts as just begun.
    pub fn overall(&self) -> f32 {
        let stage = self.stage();
        let before: f32 = Stage::ALL.iter().take_while(|earlier| **earlier < stage).map(|s| s.weight()).sum();
        (before + stage.weight() * self.fraction().unwrap_or(0.)).clamp(0., 1.)
    }
}

#[derive(Default, Deserialize)]
pub struct Outcome {
    #[serde(default)]
    pub drives: Vec<Drive>,
    /// From a check: the bytes a write copies from the ISO.
    #[serde(default)]
    pub bytes: u64,
    /// From a check: another worker writes or ejects a drive, and may read
    /// the ISO meanwhile, so nothing was checked.
    #[serde(default)]
    pub busy: bool,
    #[serde(default)]
    pub verified: bool,
    #[serde(default)]
    pub ejected: bool,
}

/// Why a USB operation stopped, when the worker reported a reason.
/// It reports these on stdout as `ATLAS_ERROR:<reason>` before it throws.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FailureReason {
    /// The ISO is not supported Windows installation media.
    IsoUnsupported,
    /// The ISO or the app is on the USB drive, a network location or a link.
    SourceLocation,
    /// Too little free space to prepare the split Windows image.
    WorkingSpace,
    /// The prepared files do not fit the USB drive.
    DoesNotFit,
    /// The drive is no longer the one the list showed: removed, reconnected
    /// or replaced since.
    DriveChanged,
    /// Windows lost access to the destination while writing its files.
    DriveUnavailable,
    /// Windows didn't open the ISO as one volume with a drive letter.
    IsoMount,
}

impl FailureReason {
    pub fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "iso-mount" => Self::IsoMount,
            "iso-unsupported" => Self::IsoUnsupported,
            "source-location" => Self::SourceLocation,
            "working-space" => Self::WorkingSpace,
            "does-not-fit" => Self::DoesNotFit,
            "drive-changed" => Self::DriveChanged,
            "drive-unavailable" => Self::DriveUnavailable,
            _ => return None,
        })
    }
}

#[derive(Debug)]
pub struct Failure {
    pub reason: Option<FailureReason>,
    /// The worker may have changed the drive: it went past preparing the
    /// files, or its output could not be read to the end to rule that out.
    pub drive_changed: bool,
    detail: String,
}

impl Failure {
    pub fn new(reason: Option<FailureReason>, drive_changed: bool, detail: impl Into<String>) -> Self {
        Self { reason, drive_changed, detail: detail.into() }
    }
}

impl std::fmt::Display for Failure {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?} (drive changed: {}): {}", self.reason, self.drive_changed, self.detail)
    }
}

impl std::error::Error for Failure {}

/// Runs one worker operation in the job folder `dir`: List, Check (the
/// source, without a drive, or busy while another worker writes or ejects),
/// Write (which ejects the drive once it is verified, and says whether
/// Windows let it go) or Eject.
pub fn run(
    operation: &'static str,
    source: Option<&Path>,
    drive: Option<&Drive>,
    supported_builds: &[u32],
    dir: &Path,
    cancel: Arc<AtomicBool>,
    report: impl FnMut(Progress),
) -> Result<Outcome> {
    log::info!("USB operation {operation} started; diagnostics={}", dir.display());
    anyhow::ensure!(matches!(operation, "List" | "Check" | "Write" | "Eject"), "unknown USB operation");
    if matches!(operation, "Write" | "Eject") {
        anyhow::ensure!(drive.is_some(), "no USB drive given");
    }
    if matches!(operation, "Check" | "Write") {
        anyhow::ensure!(source.is_some(), "no ISO given");
    }
    // Until the worker is running, nothing can have touched the drive.
    let (child, mut log) = start(operation, source, drive, supported_builds, dir)
        .map_err(|error| Failure::new(None, false, format!("{error:#}")))?;
    let (status, output) =
        powershell::follow_worker(child, dir, cancel, |stdout| read_output(stdout, &mut log, report))?;
    if !status.success() {
        return Err(Failure::new(
            output.reason,
            output.drive_changed,
            format!("USB worker failed; see {}", dir.join("usb.log").display()),
        )
        .into());
    }
    let outcome: Outcome = output.outcome.context("USB worker returned no result")?;
    anyhow::ensure!(operation != "Write" || outcome.verified, "USB was not verified");
    anyhow::ensure!(operation != "Eject" || outcome.ejected, "USB was not ejected");
    Ok(outcome)
}

/// What the worker reported on stdout.
struct Output {
    outcome: Option<Outcome>,
    reason: Option<FailureReason>,
    /// See [`Failure::drive_changed`].
    drive_changed: bool,
}

/// Reads the worker's markers to the end, copying every line to `log`.
fn read_output(stream: impl BufRead, log: &mut impl Write, mut report: impl FnMut(Progress)) -> Output {
    let mut output = Output { outcome: None, reason: None, drive_changed: false };
    // Nothing touches the drive before the worker moves past "prepare".
    let mut prepared_only = true;
    let read_all = powershell::read_lines(stream, log, |line| {
        if let Some(typed) = line.strip_prefix("ATLAS_ERROR:").and_then(FailureReason::parse) {
            output.reason = Some(typed);
        }
        if let Some(json) = line.strip_prefix("ATLAS_PROGRESS:")
            && let Ok(progress) = serde_json::from_str::<Progress>(json)
        {
            prepared_only &= progress.stage == "prepare";
            report(progress);
        }
        if let Some(json) = line.strip_prefix("ATLAS_RESULT:") {
            output.outcome = serde_json::from_str(json).ok();
        }
    });
    output.drive_changed = !(prepared_only && read_all);
    output
}

/// Stages the worker and its request in `dir` and starts the worker.
fn start(
    operation: &str,
    source: Option<&Path>,
    drive: Option<&Drive>,
    supported_builds: &[u32],
    dir: &Path,
) -> Result<(Child, fs::File)> {
    let request_json = serde_json::to_vec(&serde_json::json!({
        "source": source,
        "drive": drive,
        "app": std::env::current_exe()?,
        "eraseConfirmed": operation == "Write",
        "supportedBuilds": supported_builds,
    }))?;
    super::recovery_app::stage_media_job(
        dir,
        &[
            ("Write-Usb.ps1", include_str!("../../resources/iso/Write-Usb.ps1").as_bytes()),
            ("Iso-Mount.ps1", include_str!("../../resources/iso/Iso-Mount.ps1").as_bytes()),
            ("usb-request.json", &request_json),
        ],
    )?;
    let log = fs::File::create(dir.join("usb.log"))?;
    let child = powershell::start_worker(dir, "Write-Usb.ps1", "usb-request.json", operation, &log)
        .context("start USB worker")?;
    Ok((child, log))
}

/// The user's Downloads folder, wherever they moved it.
pub fn downloads_folder() -> Option<PathBuf> {
    use windows::Win32::{
        System::Com::CoTaskMemFree,
        UI::Shell::{FOLDERID_Downloads, KF_FLAG_DEFAULT, SHGetKnownFolderPath},
    };
    let path = unsafe { SHGetKnownFolderPath(&FOLDERID_Downloads, KF_FLAG_DEFAULT, None) }.ok()?;
    let text = unsafe { path.to_string() };
    unsafe { CoTaskMemFree(Some(path.0.cast())) };
    text.ok().map(PathBuf::from)
}

/// The newest ISO in `folder` whose name starts with "Atlas", as the ISO page
/// names what it creates ("Atlas-Windows.iso", "Atlas-Windows (2).iso").
pub fn newest_atlas_iso(folder: &Path) -> Option<PathBuf> {
    fs::read_dir(folder)
        .ok()?
        .filter_map(Result::ok)
        .filter(|entry| {
            let name = entry.file_name().to_string_lossy().to_lowercase();
            name.starts_with("atlas") && name.ends_with(".iso")
        })
        .filter_map(|entry| {
            let metadata = entry.metadata().ok().filter(fs::Metadata::is_file)?;
            Some((metadata.modified().ok()?, entry.path()))
        })
        .max_by_key(|(modified, _)| *modified)
        .map(|(_, path)| path)
}

/// What changes when a disk is connected or removed, or a volume gains or
/// loses a letter: the disks Plug and Play lists for the disk driver, and
/// the drive letters in use. Cheap enough to read every few seconds; the
/// drive list itself takes a worker.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Devices {
    disks: Vec<(String, Vec<u8>)>,
    letters: u32,
}

pub fn devices() -> Devices {
    let disks = windows_registry::LOCAL_MACHINE
        .open(r"SYSTEM\CurrentControlSet\Services\disk\Enum")
        .and_then(|key| Ok(key.values()?.map(|(name, value)| (name, value.to_vec())).collect()))
        .unwrap_or_default();
    let letters = unsafe { windows::Win32::Storage::FileSystem::GetLogicalDrives() };
    Devices { disks, letters }
}

/// The made-up drives the review previews list: one to write to, one more,
/// and one too small to use.
pub fn preview_drives() -> [Drive; 3] {
    let drive = |number: u32, name: &str, size: u64, letter: &str| Drive {
        number,
        name: name.into(),
        serial: format!("USB-PREVIEW-{number}"),
        unique_id: format!("preview-{number}"),
        path: "preview".into(),
        size,
        letters: vec![letter.into()],
        too_small: size < MIN_BYTES,
    };
    [
        drive(2, "Kingston DataTraveler Max", 256_060_514_304, "F"),
        drive(3, "SanDisk Ultra Fit", 61_530_439_680, "G"),
        drive(4, "Generic Flash Disk", 7_759_462_400, "H"),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn usb_inventory_worker_returns_typed_results_without_writing_a_drive() {
        let dir = crate::services::test_support::TempDir::new("usb-inventory");
        let result = run("List", None, None, &[], dir.path(), Arc::new(AtomicBool::new(false)), |_| {})
            .expect("read the Windows USB inventory");
        assert!(!result.verified && !result.ejected);
        assert!(result.drives.iter().all(|drive| !drive.unique_id.is_empty() && !drive.path.is_empty()));
    }

    #[test]
    fn failure_reasons_match_the_worker_markers() {
        // Every marker the worker writes, itself or through the mount helper it
        // loads, must be understood here, or the page falls back to generic advice.
        let scripts = [
            include_str!("../../resources/iso/Write-Usb.ps1"),
            include_str!("../../resources/iso/Iso-Mount.ps1"),
        ];
        let markers: Vec<_> = scripts
            .iter()
            .flat_map(|script| script.lines())
            .filter_map(|line| {
                let start = line.find("Fail '")? + "Fail '".len();
                line[start..].split('\'').next()
            })
            .collect();
        assert!(!markers.is_empty());
        for marker in &markers {
            assert!(FailureReason::parse(marker).is_some(), "unknown worker marker {marker:?}");
        }
        assert!(markers.contains(&"drive-changed"));
        assert!(markers.contains(&"iso-mount"));
    }

    #[test]
    fn a_badly_encoded_line_hides_neither_the_reason_nor_the_result() {
        let mut stages = vec![];
        let output = read_output(
            &b"ATLAS_PROGRESS:{\"stage\":\"prepare\",\"done\":0,\"total\":0}\r\nE: Donn\x82es\r\nATLAS_ERROR:does-not-fit\r\nATLAS_RESULT:{\"drives\":[]}\r\n"[..],
            &mut Vec::new(),
            |progress| stages.push(progress.stage),
        );
        assert_eq!(stages, ["prepare"]);
        assert_eq!(output.reason, Some(FailureReason::DoesNotFit));
        assert!(output.outcome.is_some());
        assert!(!output.drive_changed, "the worker only prepared files");
        let formatting = read_output(
            &b"ATLAS_PROGRESS:{\"stage\":\"prepare\",\"done\":0,\"total\":0}\nATLAS_PROGRESS:{\"stage\":\"format\",\"done\":0,\"total\":0}\nATLAS_ERROR:drive-unavailable\n"[..],
            &mut Vec::new(),
            |_| {},
        );
        assert!(formatting.drive_changed);
        assert_eq!(formatting.reason, Some(FailureReason::DriveUnavailable));
    }

    /// The page marks drives as too small, and tells people which drives to
    /// connect, from these; the worker applies them.
    #[test]
    fn drive_size_limits_match_the_worker() {
        let script = include_str!("../../resources/iso/Write-Usb.ps1");
        let number = |pattern: &str| -> u64 {
            regex::Regex::new(pattern).unwrap().captures(script).expect(pattern)[1].parse().unwrap()
        };
        assert_eq!(number(r"\$Disk\.Size -ge (\d+)GB") << 30, MIN_BYTES);
        assert_eq!(number(r"\[math\]::Min\((\d+), \$disk\.Size - (?:\d+)MB\)"), PARTITION_LIMIT);
        assert_eq!(number(r"\$disk\.Size - (\d+)MB\)") << 20, PARTITION_RESERVE);
        assert_eq!(number(r"\$total \+ (\d+)MB -gt \$capacity") << 20, PARTITION_HEADROOM);
    }

    #[test]
    fn a_drive_fits_what_the_partition_holds_with_room_to_spare() {
        let mut drive = preview_drives()[0].clone();
        // 32 GB at most, whatever the drive's size.
        assert!(drive.fits(PARTITION_LIMIT - PARTITION_HEADROOM - (1 << 20)));
        assert!(!drive.fits(PARTITION_LIMIT));
        drive.size = 16_000_000_000;
        let partition = partition_bytes(drive.size);
        assert_eq!(partition % (1 << 20), 0);
        assert!(drive.fits(partition - PARTITION_HEADROOM));
        assert!(!drive.fits(partition - PARTITION_HEADROOM + 1));
    }

    #[test]
    fn sizes_read_as_the_drive_was_sold() {
        let gb = |n: u64| SoldSize::Gigabytes(n);
        // Flash drives hold a little less, or a little more, than their label.
        assert_eq!(sold_size(256_060_514_304), gb(256));
        assert_eq!(sold_size(61_530_439_680), gb(64));
        assert_eq!(sold_size(30_752_000_000), gb(32));
        assert_eq!(sold_size(28_901_000_000), gb(32));
        assert_eq!(sold_size(15_502_000_000), gb(16));
        assert_eq!(sold_size(7_759_462_400), gb(8));
        assert_eq!(sold_size(123_010_000_000), gb(128));
        // Solid-state and hard drives hold their round label.
        assert_eq!(sold_size(250_059_350_016), gb(250));
        assert_eq!(sold_size(480_103_981_056), gb(480));
        assert_eq!(sold_size(500_107_862_016), gb(500));
        assert_eq!(sold_size(1_000_204_886_016), SoldSize::Terabytes(1.));
        assert_eq!(sold_size(2_000_398_934_016), SoldSize::Terabytes(2.));
        // A flash drive sold in terabytes.
        assert_eq!(sold_size(984_000_000_000), SoldSize::Terabytes(1.));
    }

    #[test]
    fn a_reconnected_drive_is_recognised_by_its_serial_number() {
        let [drive, other, _] = preview_drives();
        let renumbered = Drive { number: 7, unique_id: "new".into(), letters: vec![], ..drive.clone() };
        assert!(drive.same_device(&renumbered));
        assert!(!drive.same_device(&other));
        // Without a serial number, only the same identifier says it's the same drive.
        let anonymous = Drive { serial: String::new(), ..drive.clone() };
        assert!(!anonymous.same_device(&Drive { unique_id: "new".into(), ..anonymous.clone() }));
        assert!(anonymous.same_device(&anonymous.clone()));
        // A clone with the same serial but another size is another drive.
        assert!(!drive.same_device(&Drive { unique_id: "new".into(), size: 1, ..drive.clone() }));
    }

    /// Generic flash drives can share a serial number, model and size, so a
    /// drive found again by those is picked again, but only the very drive
    /// the user agreed to erase keeps that agreement.
    #[test]
    fn only_the_same_identity_carries_an_erase_confirmation() {
        let [drive, ..] = preview_drives();
        assert!(drive.same_identity(&drive.clone()));
        let lettered = Drive { letters: vec!["K".into()], ..drive.clone() };
        assert!(drive.same_identity(&lettered), "a drive letter isn't part of its identity");
        let twin = Drive { unique_id: "twin".into(), ..drive.clone() };
        assert!(drive.same_device(&twin), "the list picks it again");
        for other in [
            twin,
            Drive { number: 9, ..drive.clone() },
            Drive { name: "Other".into(), ..drive.clone() },
            Drive { serial: "OTHER".into(), ..drive.clone() },
            Drive { path: "other".into(), ..drive.clone() },
            Drive { size: drive.size + 1, ..drive.clone() },
        ] {
            assert!(!drive.same_identity(&other), "{other:?}");
        }
    }

    /// The worker refuses to erase a drive whose identity changed since the
    /// app sent it; the app carries a confirmation by the same parts.
    #[test]
    fn the_identity_that_carries_a_confirmation_is_the_one_the_worker_checks() {
        let script = include_str!("../../resources/iso/Write-Usb.ps1");
        let keys = regex::Regex::new(r"foreach \(\$key in @\(([^)]*)\)\)").unwrap().captures(script).unwrap()
            [1]
        .replace('\'', "");
        let keys: Vec<&str> = keys.split(',').map(str::trim).collect();
        assert_eq!(keys, IDENTITY);
    }

    #[test]
    fn a_drive_holds_the_paths_on_its_letters() {
        let drive = preview_drives()[0].clone();
        assert!(drive.holds(Path::new(r"F:\Atlas-Windows.iso")));
        assert!(drive.holds(Path::new(r"f:\sub\file.iso")));
        assert!(drive.holds(Path::new(r"\\?\F:\Atlas-Windows.iso")));
        assert!(!drive.holds(Path::new(r"C:\Users\Atlas\Downloads\Atlas-Windows.iso")));
        assert!(!drive.holds(Path::new(r"\\server\share\Atlas-Windows.iso")));
    }

    #[test]
    fn the_newest_atlas_iso_is_found_by_name_and_time() {
        let dir = crate::services::test_support::TempDir::new("usb-downloads");
        let write = |name: &str, age: u64| {
            let path = dir.path().join(name);
            fs::write(&path, b"iso").unwrap();
            let time = std::time::SystemTime::now() - std::time::Duration::from_secs(age);
            fs::File::options().write(true).open(&path).unwrap().set_modified(time).unwrap();
            path
        };
        assert_eq!(newest_atlas_iso(dir.path()), None);
        write("Windows11-x64-en-GB.iso", 0);
        write("Atlas.atlaspkg", 0);
        write("Atlas-Windows.iso", 300);
        let newest = write("ATLAS-Windows (2).ISO", 60);
        fs::create_dir(dir.path().join("Atlas-folder.iso")).unwrap();
        assert_eq!(newest_atlas_iso(dir.path()), Some(newest));
        assert_eq!(newest_atlas_iso(&dir.path().join("missing")), None);
    }

    #[test]
    fn progress_runs_once_through_every_stage_and_never_goes_back() {
        assert_eq!(Progress::default().fraction(), None);
        assert_eq!(Progress { done: 5, total: 10, ..Default::default() }.fraction(), Some(0.5));
        assert_eq!(Progress { done: 11, total: 10, ..Default::default() }.fraction(), Some(1.));
        let weights: f32 = Stage::ALL.iter().map(|stage| stage.weight()).sum();
        assert!((weights - 1.).abs() < 1e-6);
        let at = |stage: &str, done: u64| Progress { stage: stage.into(), done, total: 10 }.overall();
        let mut last = 0.;
        for stage in ["prepare", "format", "copy", "verify", "eject"] {
            for done in [0, 5, 10] {
                let now = at(stage, done);
                assert!(now >= last, "{stage} {done}: {now} < {last}");
                last = now;
            }
        }
        assert!((last - 1.).abs() < 1e-6);
        // A stage without byte counts has only just begun.
        assert_eq!(Progress { stage: "copy".into(), done: 0, total: 0 }.overall(), at("copy", 0));
        assert_eq!(Progress { stage: "unknown".into(), ..Default::default() }.overall(), 0.);
    }
}
