//! Follows an install's output: tails its log and the machine log, and
//! decodes what arrives into lines for the UI.

use std::fs;
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::thread;
use std::time::Duration;

use futures::SinkExt;
use futures::channel::mpsc::Sender;

use super::{InstallEvent, Watch};

/// Events waiting for the UI at any moment. The child writes to disk, so the
/// follower can simply pause when the window is behind; it never buffers a
/// large replay in memory and never drops a line.
pub(super) const EVENT_BACKLOG: usize = 8;
/// Lines per event, so a big replay reaches the model in pieces it can trim.
const LINES_PER_EVENT: usize = 2000;

/// The detailed log Atlas's install scripts write, shared by every install
/// on this PC.
pub fn machine_log_path() -> PathBuf {
    super::system::windows_dir().join(r"AtlasModules\Logs\install\atlas-install.log")
}

/// The receiver is gone: no window follows this install any more.
pub(super) struct Gone;

/// Tails the log until the installer ends, then drains everything that is
/// left before reporting the outcome. The machine log is followed too, from
/// the offset recorded at `offset_path`, when there is one.
pub(super) fn follow(
    log_path: PathBuf,
    offset_path: PathBuf,
    mut watch: Watch,
    mut sender: Sender<InstallEvent>,
) -> Result<(), Gone> {
    const POLL: Duration = Duration::from_millis(120);
    let mut buffer = Vec::new();
    let mut log = Tail::new(log_path, 0);
    let mut machine = fs::read_to_string(offset_path)
        .ok()
        .and_then(|offset| offset.parse().ok())
        .map(|offset| Tail::new(machine_log_path(), offset));
    let outcome = loop {
        let ended = watch.poll();
        log.pump(&mut buffer, &mut sender)?;
        if let Some(machine) = &mut machine
            && machine.path.exists()
        {
            machine.pump(&mut buffer, &mut sender)?;
        }
        if let Some(outcome) = ended {
            // Drain the detailed log before publishing success or failure.
            if let Some(machine) = &mut machine {
                while machine.path.exists() && machine.pump(&mut buffer, &mut sender)? {}
            }
            break outcome;
        }
        thread::sleep(POLL);
    };
    // Drain to the end of the file: a backlog can be many reads long.
    while log.pump(&mut buffer, &mut sender)? {}
    if let Some(line) = log.decoder.finish() {
        deliver(&mut sender, InstallEvent::Lines(vec![line]))?;
    }
    deliver(&mut sender, InstallEvent::Finished(outcome))
}

/// A file being followed: how far it has been read, its unfinished line,
/// and whether a read problem has been reported yet.
struct Tail {
    path: PathBuf,
    position: u64,
    decoder: LineDecoder,
    reported_problem: bool,
}

impl Tail {
    fn new(path: PathBuf, position: u64) -> Self {
        Self { path, position, decoder: LineDecoder::default(), reported_problem: false }
    }

    /// Sends what was appended since the last read, in batches the UI can
    /// trim, and returns whether anything arrived. A read problem is
    /// reported once.
    fn pump(&mut self, buffer: &mut Vec<u8>, sender: &mut Sender<InstallEvent>) -> Result<bool, Gone> {
        match read_new_bytes(&self.path, &mut self.position, buffer) {
            Ok([]) => Ok(false),
            Ok(bytes) => {
                let mut lines = self.decoder.push(bytes).into_iter().peekable();
                while lines.peek().is_some() {
                    deliver(sender, InstallEvent::Lines(lines.by_ref().take(LINES_PER_EVENT).collect()))?;
                }
                Ok(true)
            }
            Err(error) => {
                if !std::mem::replace(&mut self.reported_problem, true) {
                    deliver(sender, InstallEvent::OutputProblem(error.to_string()))?;
                }
                Ok(false)
            }
        }
    }
}

/// Hands an event to the UI, waiting while its backlog is full.
fn deliver(sender: &mut Sender<InstallEvent>, event: InstallEvent) -> Result<(), Gone> {
    futures::executor::block_on(sender.send(event)).map_err(|_| Gone)
}

/// The most read from a file at once, so a long backlog arrives in pieces.
const MAX_READ_BYTES: usize = 4 * 1024 * 1024;

/// Reads what was appended to the file since `position`, at most
/// [`MAX_READ_BYTES`] of it.
fn read_new_bytes<'a>(path: &Path, position: &mut u64, buffer: &'a mut Vec<u8>) -> std::io::Result<&'a [u8]> {
    let mut file = fs::File::open(path)?;
    let len = file.metadata()?.len();
    if len < *position {
        // Truncated or replaced: start over rather than reading garbage.
        *position = 0;
    }
    if len == *position {
        return Ok(&buffer[..0]);
    }
    file.seek(SeekFrom::Start(*position))?;
    let wanted = usize::try_from(len - *position).unwrap_or(usize::MAX).min(MAX_READ_BYTES);
    if buffer.len() < wanted {
        buffer.resize(wanted, 0);
    }
    let mut filled = 0;
    while filled < wanted {
        let read = file.read(&mut buffer[filled..wanted])?;
        if read == 0 {
            break;
        }
        filled += read;
    }
    *position += filled as u64;
    Ok(&buffer[..filled])
}

/// The most of one line that is kept. Longer lines are cut there and marked;
/// the rest of the line is skipped, not stored. The full text is on disk.
pub const MAX_LINE_BYTES: usize = 8 * 1024;
/// Appended to a line that was cut at [`MAX_LINE_BYTES`].
pub const TRUNCATION_MARKER: &str = " [truncated]";

/// Splits a byte stream into lines, decoding invalid UTF-8 as U+FFFD. Every
/// line is cut at [`MAX_LINE_BYTES`] and the rest of an overlong line
/// skipped, so memory use stays limited; each push scans only the bytes it
/// adds.
#[derive(Default)]
pub struct LineDecoder {
    pending: Vec<u8>,
    /// How much of `pending` has already been searched for a line break.
    scanned: usize,
    /// The rest of an overlong line is being skipped until its line break.
    skipping: bool,
}

impl LineDecoder {
    pub fn push(&mut self, mut bytes: &[u8]) -> Vec<String> {
        let mut lines = Vec::new();
        if self.skipping {
            let Some(end) = bytes.iter().position(|b| *b == b'\n' || *b == b'\r') else {
                return lines;
            };
            self.skipping = false;
            bytes = &bytes[end..];
        }
        self.pending.extend_from_slice(bytes);
        let mut start = 0;
        let mut index = self.scanned;
        while index < self.pending.len() {
            let byte = self.pending[index];
            if byte == b'\n' || byte == b'\r' {
                lines.extend(emit_line(&self.pending[start..index]));
                if byte == b'\r' && self.pending.get(index + 1) == Some(&b'\n') {
                    index += 1;
                }
                start = index + 1;
            }
            index += 1;
        }
        self.pending.drain(..start.min(self.pending.len()));
        self.scanned = self.pending.len();
        if self.pending.len() > MAX_LINE_BYTES {
            lines.extend(truncated_line(&self.pending));
            self.pending.clear();
            self.scanned = 0;
            self.skipping = true;
        }
        lines
    }

    /// The unterminated last line, if any.
    pub fn finish(&mut self) -> Option<String> {
        let rest = std::mem::take(&mut self.pending);
        self.scanned = 0;
        if std::mem::take(&mut self.skipping) {
            // The line was already delivered, cut and marked.
            return None;
        }
        emit_line(&rest)
    }
}

/// One logical line as the UI receives it: decoded leniently, trimmed, and
/// cut at [`MAX_LINE_BYTES`] whatever its origin.
fn emit_line(bytes: &[u8]) -> Option<String> {
    if bytes.len() > MAX_LINE_BYTES { truncated_line(bytes) } else { decode_line(bytes) }
}

fn decode_line(bytes: &[u8]) -> Option<String> {
    let line = String::from_utf8_lossy(bytes);
    let line = line.trim_end();
    (!line.is_empty()).then(|| line.to_owned())
}

/// The first [`MAX_LINE_BYTES`] of a line, cut at a character boundary and marked.
fn truncated_line(bytes: &[u8]) -> Option<String> {
    let text = String::from_utf8_lossy(&bytes[..MAX_LINE_BYTES]);
    let mut text = text.into_owned();
    // A character split by the cut decoded as U+FFFD; drop it.
    if text.ends_with('\u{FFFD}') && bytes.get(MAX_LINE_BYTES).is_some_and(|b| b & 0xC0 == 0x80) {
        text.pop();
    }
    text.push_str(TRUNCATION_MARKER);
    Some(text)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_decoder_survives_invalid_bytes_and_split_reads() {
        let mut decoder = LineDecoder::default();
        let mut lines = decoder.push(&[0xE9, b'\n', b'A', b'F', b'T']);
        assert_eq!(lines, vec!["\u{FFFD}".to_owned()]);
        lines = decoder.push(b"ER\r\nnext\rlast");
        assert_eq!(lines, vec!["AFTER".to_owned(), "next".to_owned()]);
        // A multi-byte character split across reads decodes intact.
        let euro = "€".as_bytes();
        assert!(decoder.push(&euro[..1]).is_empty());
        assert_eq!(decoder.push(&euro[1..]), Vec::<String>::new());
        assert_eq!(decoder.finish(), Some("last€".to_owned()));
        assert_eq!(decoder.finish(), None);
    }

    #[test]
    fn a_long_unterminated_line_costs_its_length_once_and_is_cut_and_marked() {
        let mut decoder = LineDecoder::default();
        let chunk = vec![b'x'; 64 * 1024];
        let mut lines = Vec::new();
        for _ in 0..4 {
            lines.extend(decoder.push(&chunk));
        }
        // No newline: one cut line, and nothing held past the cap.
        assert_eq!(lines.len(), 1, "{} lines", lines.len());
        assert_eq!(lines[0].len(), MAX_LINE_BYTES + TRUNCATION_MARKER.len());
        assert!(lines[0].ends_with(TRUNCATION_MARKER));
        assert!(decoder.pending.len() <= MAX_LINE_BYTES);
        // The rest of that line is skipped; the next line arrives whole.
        assert_eq!(decoder.push(b"tail of the long line\nnext line\n"), vec!["next line".to_owned()]);
        assert_eq!(decoder.finish(), None);

        // A line already cut and delivered is not delivered again at the end.
        let mut decoder = LineDecoder::default();
        assert_eq!(decoder.push(&chunk).len(), 1);
        assert_eq!(decoder.push(b"more"), Vec::<String>::new());
        assert_eq!(decoder.finish(), None);

        // A break split across pushes (\r then \n) is one break, not an empty line.
        let mut decoder = LineDecoder::default();
        assert_eq!(decoder.push(b"one\r"), vec!["one".to_owned()]);
        assert_eq!(decoder.push(b"\ntwo\n"), vec!["two".to_owned()]);
    }

    /// The cap applies to complete lines too: in one push, with CRLF, several
    /// at once, at the boundary, across the chunk that brings the newline,
    /// and at `finish()`.
    #[test]
    fn complete_lines_are_cut_at_the_same_cap_as_unfinished_ones() {
        let marked = MAX_LINE_BYTES + TRUNCATION_MARKER.len();
        let mut decoder = LineDecoder::default();
        let mut input = vec![b'a'; 32 * 1024];
        input.push(b'\n');
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].len(), marked);
        assert!(lines[0].ends_with(TRUNCATION_MARKER));

        // A megabyte line with CRLF, then a short line, in one push.
        let mut input = vec![b'b'; 1024 * 1024 + 1];
        input.extend_from_slice(b"\r\nshort\r\n");
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].len(), marked);
        assert_eq!(lines[1], "short");

        // Two long lines in one read are two marked lines.
        let mut input = vec![b'c'; MAX_LINE_BYTES + 1];
        input.push(b'\n');
        input.extend(vec![b'd'; MAX_LINE_BYTES + 1]);
        input.push(b'\n');
        let lines = decoder.push(&input);
        assert_eq!(lines.len(), 2);
        assert!(lines.iter().all(|line| line.len() == marked));

        // Exactly the cap is kept whole; one more byte is cut.
        let mut input = vec![b'e'; MAX_LINE_BYTES];
        input.push(b'\n');
        assert_eq!(decoder.push(&input)[0].len(), MAX_LINE_BYTES);

        // The newline arrives in the chunk that crosses the cap: still one
        // marked line, nothing of it repeated, and the next line intact.
        assert!(decoder.push(&vec![b'f'; MAX_LINE_BYTES - 10]).is_empty());
        let lines = decoder.push(b"ffffffffffffffffffff\nnext\n");
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].len(), marked);
        assert_eq!(lines[1], "next");

        // Multibyte text is cut on a character boundary, complete or not.
        let text = "\u{20ac}".repeat(MAX_LINE_BYTES / 3 + 5);
        let mut input = text.clone().into_bytes();
        input.push(b'\n');
        let cut = decoder.push(&input).remove(0);
        let kept = cut.strip_suffix(TRUNCATION_MARKER).unwrap();
        assert!(kept.chars().all(|c| c == '\u{20ac}'), "no replacement character at the cut");
        assert!(kept.len() <= MAX_LINE_BYTES);

        // The final unterminated remainder is cut too.
        assert!(decoder.push(&vec![b'g'; MAX_LINE_BYTES - 1]).is_empty());
        assert!(decoder.push(b"g").is_empty(), "exactly the cap is still pending");
        assert_eq!(decoder.finish().unwrap().len(), MAX_LINE_BYTES);
        let mut decoder = LineDecoder::default();
        // Under the overflow trigger but over it once trimmed at finish: the
        // cap applies to what finish() emits as well.
        assert!(decoder.push(&vec![b'h'; MAX_LINE_BYTES]).is_empty());
        assert_eq!(decoder.finish().unwrap().len(), MAX_LINE_BYTES);
    }
}
