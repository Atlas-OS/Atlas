//! Windows PowerShell children. Every launch goes through [`command`]: the
//! full System32 path, the same switches and no console window. Long-running
//! workers are asked to stop through a marker file in their job directory,
//! and the ISO and USB workers report through `ATLAS_*` lines on stdout.

use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::os::windows::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdout, Command, ExitStatus, Stdio};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread::JoinHandle;
use std::time::Duration;

use anyhow::{Context, Result};
use windows::Win32::System::Threading::CREATE_NO_WINDOW;

/// The switches every launch passes before `-File` or `-Command`.
pub const FLAGS: [&str; 5] = ["-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass"];

/// Windows PowerShell 5.1, the one runtime Atlas's scripts are written for.
pub fn path() -> PathBuf {
    super::system::windows_dir().join(r"System32\WindowsPowerShell\v1.0\powershell.exe")
}

/// A hidden Windows PowerShell child with [`FLAGS`]; the caller adds `-File`
/// or `-Command`. Started by full path: a bare `powershell.exe` is also looked
/// up in the app's own folder, where a planted copy would run with the app's
/// rights.
pub fn command() -> Command {
    let mut command = Command::new(path());
    command.args(FLAGS).creation_flags(CREATE_NO_WINDOW.0);
    command
}

/// Asks a worker to stop once `cancel` is set, by writing the marker it polls
/// for: a worker that stops itself can finish what it is servicing and
/// release mounted media. A failed write is retried. Watching ends when this
/// is dropped.
pub struct CancelWatch {
    stop: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl CancelWatch {
    pub fn start(cancel: Arc<AtomicBool>, marker: PathBuf, write: fn(&Path) -> io::Result<()>) -> Self {
        let stop = Arc::new(AtomicBool::new(false));
        let stopped = stop.clone();
        let thread = std::thread::spawn(move || {
            let mut reported = false;
            while !stopped.load(Ordering::Relaxed) {
                if cancel.load(Ordering::Relaxed) {
                    match write(&marker) {
                        Ok(()) => break,
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
                std::thread::sleep(Duration::from_millis(100));
            }
        });
        Self { stop, thread: Some(thread) }
    }
}

impl Drop for CancelWatch {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::Relaxed);
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

/// Creates a cancellation marker; for the ISO and USB job directories.
pub fn create_marker(marker: &Path) -> io::Result<()> {
    File::create(marker).map(drop)
}

/// Starts an ISO or USB worker: `script` from its job directory `dir`, with
/// its request file and operation. Its `ATLAS_*` lines arrive on stdout; its
/// errors are appended to `log`.
pub fn start_worker(dir: &Path, script: &str, request: &str, operation: &str, log: &File) -> Result<Child> {
    Ok(command()
        .arg("-File")
        .arg(dir.join(script))
        .arg("-RequestFile")
        .arg(dir.join(request))
        .arg("-Operation")
        .arg(operation)
        .stdout(Stdio::piped())
        .stderr(Stdio::from(log.try_clone()?))
        .spawn()?)
}

/// Follows a worker from [`start_worker`] to its end. `read` gets its stdout;
/// meanwhile the worker is asked to stop through the `cancel` marker in `dir`
/// once `cancel` is set. Returns the exit status and what `read` returned.
pub fn follow_worker<T>(
    mut child: Child,
    dir: &Path,
    cancel: Arc<AtomicBool>,
    read: impl FnOnce(BufReader<ChildStdout>) -> T,
) -> Result<(ExitStatus, T)> {
    let stdout = child.stdout.take().context("read the worker's output")?;
    let watch = CancelWatch::start(cancel, dir.join("cancel"), create_marker);
    let output = read(BufReader::new(stdout));
    let status = child.wait()?;
    drop(watch);
    Ok((status, output))
}

/// Reads `stream` line by line, copying each line to `log` and handing it to
/// `on_line`. A line that is not valid UTF-8 is decoded leniently, so it hides
/// none of the lines after it. Returns whether the stream was read to its end.
pub fn read_lines(mut stream: impl BufRead, log: &mut impl Write, mut on_line: impl FnMut(&str)) -> bool {
    let mut bytes = Vec::new();
    loop {
        bytes.clear();
        match stream.read_until(b'\n', &mut bytes) {
            Ok(0) => return true,
            Ok(_) => {}
            Err(_) => return false,
        }
        let line = String::from_utf8_lossy(&bytes);
        let line = line.trim_end_matches(['\r', '\n']);
        let _ = writeln!(log, "{line}");
        on_line(line);
    }
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::AtomicUsize;
    use std::time::Instant;

    use super::*;

    #[test]
    fn cancellation_retries_a_failed_marker_write_and_stops_once_it_succeeds() {
        // `start` takes a plain `fn`, so the writer counts its calls in a static.
        static CALLS: AtomicUsize = AtomicUsize::new(0);
        fn fails_twice(_: &Path) -> io::Result<()> {
            match CALLS.fetch_add(1, Ordering::SeqCst) {
                0 | 1 => Err(io::ErrorKind::NotFound.into()),
                _ => Ok(()),
            }
        }
        let watch = CancelWatch::start(Arc::new(AtomicBool::new(true)), PathBuf::from("cancel"), fails_twice);
        let deadline = Instant::now() + Duration::from_secs(5);
        while CALLS.load(Ordering::SeqCst) < 3 && Instant::now() < deadline {
            std::thread::sleep(Duration::from_millis(20));
        }
        assert_eq!(CALLS.load(Ordering::SeqCst), 3, "the third write succeeds");
        // A few more retry intervals: a watch that kept writing would show here.
        std::thread::sleep(Duration::from_millis(300));
        drop(watch);
        assert_eq!(CALLS.load(Ordering::SeqCst), 3);
    }
}
