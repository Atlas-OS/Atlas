//! Redact exported copies only. Keep diagnostic context and correlate aliases
//! within one archive; never write an identity mapping into the archive.
use std::collections::HashMap;
use std::sync::LazyLock;

use regex::{Captures, Regex};
use serde_json::Value;

pub struct Redactor {
    aliases: HashMap<String, String>,
    /// The collecting user's account, computer and domain names.
    identities: Vec<Regex>,
    profile: Regex,
}

/// Profile folders that are not an account's and keep their names.
const SHARED_PROFILES: [&str; 4] = ["Public", "Default", "Default User", "All Users"];
/// Names that identify no one but are words of the logs themselves, Atlas's
/// own among them: aliasing them would turn "User account" into "anonymous-1
/// account" and "module=Atlas.Install" into "module=anonymous-1.Install".
/// Profile paths with them are still aliased.
const GENERIC_NAMES: [&str; 10] = [
    "WORKGROUP",
    "NT AUTHORITY",
    "SYSTEM",
    "User",
    "Admin",
    "Administrator",
    "Owner",
    "Guest",
    "Atlas",
    "AtlasOS",
];
/// NUL characters in a row that are taken for padding rather than text: the
/// zeros a crash or hard reset leaves where a log's length reached the disk
/// before its data. UTF-16 text read as UTF-8 never has more than two in a
/// row, so it is still refused.
const NUL_RUN: usize = 16;

static SECRETS: LazyLock<[Regex; 6]> = LazyLock::new(|| {
    [
        // PEM private key
        r"(?s)-----BEGIN (?:[A-Z ]*PRIVATE KEY)-----.*?(?:-----END [A-Z ]*PRIVATE KEY-----|\z)",
        // GitHub token
        r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b",
        // JSON web token
        r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b",
        // Bearer token
        r"(?i)\bBearer\s+[A-Za-z0-9_+/=.-]{16,}",
        // Authorization header value
        r"(?i)\b(?:authorization|proxy-authorization)\s*[:=]\s*(?:Bearer|Basic)\s+[A-Za-z0-9_+/=.-]+",
        // Windows product key
        r"(?i)\b[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}\b",
    ]
    .map(|pattern| Regex::new(pattern).unwrap())
});
static HEADERS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?im)^(\s*(?:authorization|proxy-authorization|cookie|set-cookie|password|passwd|pwd)\s*:\s*)[^\r\n]*").unwrap()
});
static ARGUMENTS: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r#"(?i)((?:--?|/)(?:password|passwd|pwd|access-token|api-key|client-secret)\s+)(?:\[credential removed\]|\"[^\"]*\"|'[^']*'|\S+)"#).unwrap()
});
static XML: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?is)(<(?:Password|AccessToken|RefreshToken|ApiKey|ClientSecret|PrivateKey)>).*?(</(?:Password|AccessToken|RefreshToken|ApiKey|ClientSecret|PrivateKey)>)").unwrap()
});
static ASSIGNMENT: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r#"(?i)(\b(?:password|passwd|pwd|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|authorization|proxy-authorization|cookie|set-cookie)\b[\"']?\s*[:=]\s*)(?:\[credential removed\]|\"(?:\\.|[^\"\\])*\"|'[^']*'|[^\s&;,}\"<>]+)"#).unwrap()
});
static URL_AUTH: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(?i)(https?://)[^\s/@]+@([^\s/]+)").unwrap());
static URL_SIGNATURE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(
        r"(?i)([?&](?:sig|signature|x-amz-signature|x-goog-signature)=)(?:\[credential removed\]|[^\s&#]+)",
    )
    .unwrap()
});
static EMAIL: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)\b[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)+\b").unwrap()
});
// Keep well-known SIDs (SYSTEM, Administrators, etc.) and the RID of account
// SIDs, so ACL and per-user failures remain diagnosable. No leading word
// boundary: per-user task names glue the SID to a word
// ("GoogleUpdateTaskUserS-1-5-21-…").
static SID: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)(S-1-5-21-\d+-\d+-\d+)(-\d+)?\b").unwrap());
// Microsoft Entra ID account SIDs encode the account's object ID. No trailing
// word boundary: task names and _Classes hives glue a word to the end, and
// unlike an account SID's optional RID there is no shorter match to fall back
// to.
static ENTRA_SID: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)S-1-12-1-\d+-\d+-\d+-\d+").unwrap());
// The protected preparation and media job folders sit in one folder per
// app-data directory, named by the SHA-256 of its settings path. That path
// contains the profile name, which a guess could be checked against.
static RECOVERY_SCOPE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)(Atlas Setup Recovery[\\/]+(?:Preparation|Media)[\\/]+)([0-9a-f]{64})\b").unwrap()
});
/// One word character, as `\w` and `\b` count them.
static WORD: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^\w$").unwrap());
/// JSON keys whose values are credentials, removed whatever they hold.
static SENSITIVE_KEY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)^(?:password|passwd|pwd|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|authorization|proxy-authorization|cookie|set-cookie|private[_-]?key)$").unwrap()
});
/// The local account name typed for an ISO, in each media job's request.json.
static IDENTITY_KEY: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)^user[_-]?name$").unwrap());

/// A text file as it goes into the archive.
pub struct Redacted {
    pub bytes: Vec<u8>,
    /// Runs of NUL padding were taken out.
    pub padding_removed: bool,
}

impl Redactor {
    /// A redactor for the collecting user on this PC.
    pub fn new() -> Self {
        let names: Vec<String> = ["USERNAME", "COMPUTERNAME", "USERDOMAIN", "USERDNSDOMAIN"]
            .into_iter()
            .filter_map(|name| std::env::var(name).ok())
            .collect();
        Self::with(&names, spaced_profiles())
    }

    /// A redactor that aliases `names`, the collecting user's account,
    /// computer and domain names, wherever they stand alone, and knows
    /// `spaced`, the profile folder names containing whitespace, so it can
    /// tell where such a name ends.
    pub fn with(names: &[String], spaced: Vec<String>) -> Self {
        // Longest first, so a name is never cut short by another it begins with.
        let mut spaced: Vec<String> = spaced.iter().map(|name| regex::escape(name)).collect();
        spaced.sort_by_key(|name| std::cmp::Reverse(name.len()));
        let spaced = if spaced.is_empty() {
            String::new()
        } else {
            format!(r"(?P<spaced>{})(?P<after>\W|\z)|", spaced.join("|"))
        };
        Self {
            aliases: HashMap::new(),
            identities: names
                .iter()
                .filter(|name| {
                    !name.is_empty() && !GENERIC_NAMES.iter().any(|item| name.eq_ignore_ascii_case(item))
                })
                .map(|name| identity(name))
                .collect(),
            // A profile name may contain spaces when a separator follows it on
            // the same line. Otherwise a known name with spaces is matched
            // whole, and any other stops at whitespace, so a quoted or
            // sentence-final path keeps the rest of its line. The excluded
            // characters cannot appear in account names.
            profile: Regex::new(&format!(
                r#"(?i)(?P<prefix>[a-z]:[\\/]+Users[\\/]+)(?:(?P<name>[^\\/\r\n"<>:|?*,;=+\[\]@]+)(?P<separator>[\\/])|{spaced}(?P<tail>[^\\/\r\n"<>:|?*,;=+\[\]@\s]+))"#
            ))
            .unwrap(),
        }
    }

    pub fn text(&mut self, source: &str) -> String {
        let mut text = source.to_owned();
        for pattern in SECRETS.iter() {
            text = pattern.replace_all(&text, "[credential removed]").into_owned();
        }
        text = HEADERS.replace_all(&text, "${1}[credential removed]").into_owned();
        text = ARGUMENTS.replace_all(&text, "${1}[credential removed]").into_owned();
        text = XML.replace_all(&text, "${1}[credential removed]${2}").into_owned();
        text = ASSIGNMENT.replace_all(&text, "${1}[credential removed]").into_owned();
        // URL user-info is never needed to diagnose a download failure. Keep
        // the protocol, host, asset path and non-secret query parameters.
        text = URL_AUTH.replace_all(&text, "${1}[credential removed]@${2}").into_owned();
        text = URL_SIGNATURE.replace_all(&text, "${1}[credential removed]").into_owned();
        let aliases = &mut self.aliases;
        // Before the collecting user's names, which could match a word of the
        // folder names around it and hide the hash from this pattern.
        text = RECOVERY_SCOPE
            .replace_all(&text, |caps: &Captures<'_>| format!("{}{}", &caps[1], alias(aliases, &caps[2])))
            .into_owned();
        // Addresses first: a domain name aliased on its own would leave the
        // rest of an address that no longer looks like one.
        text = EMAIL.replace_all(&text, |caps: &Captures<'_>| alias(aliases, &caps[0])).into_owned();
        // The collecting user's names before profile paths, so a name with
        // spaces keeps one label wherever its path ends.
        for pattern in &self.identities {
            text = pattern.replace_all(&text, |caps: &Captures<'_>| alias(aliases, &caps[0])).into_owned();
        }
        text = self
            .profile
            .replace_all(&text, |caps: &Captures<'_>| {
                let (name, rest) = if let Some(name) = caps.name("spaced") {
                    (name.as_str(), &caps["after"])
                } else if let Some(name) = caps.name("name") {
                    (name.as_str(), &caps["separator"])
                } else {
                    // Punctuation closing a quote or a sentence is not part
                    // of the name; account names cannot end in '.'.
                    let tail = &caps["tail"];
                    let name = tail.trim_end_matches(['\'', '.', ')']);
                    (name, &tail[name.len()..])
                };
                if name.is_empty() || SHARED_PROFILES.iter().any(|shared| name.eq_ignore_ascii_case(shared)) {
                    caps[0].to_owned()
                } else {
                    format!("{}{}{rest}", &caps["prefix"], alias(aliases, name))
                }
            })
            .into_owned();
        text = SID
            .replace_all(&text, |caps: &Captures<'_>| {
                format!("{}{}", alias(aliases, &caps[1]), caps.get(2).map_or("", |m| m.as_str()))
            })
            .into_owned();
        text = ENTRA_SID.replace_all(&text, |caps: &Captures<'_>| alias(aliases, &caps[0])).into_owned();
        text
    }

    fn json(&mut self, value: &mut Value) {
        match value {
            Value::Object(fields) => {
                for (key, mut value) in std::mem::take(fields) {
                    if SENSITIVE_KEY.is_match(&key) {
                        value = Value::String("[credential removed]".into());
                    } else if let Value::String(name) = &value
                        && !name.is_empty()
                        && IDENTITY_KEY.is_match(&key)
                    {
                        // The same label as the name gets in a profile path.
                        value = Value::String(alias(&mut self.aliases, name));
                    } else {
                        self.json(&mut value);
                    }
                    fields.insert(self.text(&key), value);
                }
            }
            Value::Array(values) => {
                for value in values {
                    self.json(value);
                }
            }
            Value::String(text) => *text = self.text(text),
            _ => {}
        }
    }

    /// Redacts a text file: UTF-8, or UTF-16 with a byte order mark, without
    /// its NUL padding. JSON is redacted by key as well, and written back
    /// pretty-printed. `None` for anything else, which the caller leaves out.
    pub fn file(&mut self, bytes: &[u8]) -> Option<Redacted> {
        let source = if bytes.starts_with(&[0xff, 0xfe]) || bytes.starts_with(&[0xfe, 0xff]) {
            if !bytes.len().is_multiple_of(2) {
                return None;
            }
            let little = bytes[0] == 0xff;
            let units: Vec<u16> = bytes[2..]
                .as_chunks::<2>()
                .0
                .iter()
                .map(|pair| {
                    if little {
                        u16::from_le_bytes([pair[0], pair[1]])
                    } else {
                        u16::from_be_bytes([pair[0], pair[1]])
                    }
                })
                .collect();
            String::from_utf16(&units).ok()?
        } else {
            std::str::from_utf8(bytes).ok()?.trim_start_matches('\u{feff}').to_owned()
        };
        let padding_removed = source.contains('\0');
        let source = if padding_removed { without_padding(&source)? } else { source };
        let bytes = if let Ok(mut value) = serde_json::from_str::<Value>(&source) {
            self.json(&mut value);
            serde_json::to_vec_pretty(&value).ok()?
        } else {
            self.text(&source).into_bytes()
        };
        Some(Redacted { bytes, padding_removed })
    }
}

/// `text` without its runs of NUL padding: one with more text after it is
/// marked, one at the end is dropped. `None` when a shorter run or a single
/// NUL is left, as in binary data or UTF-16 without a byte order mark.
fn without_padding(text: &str) -> Option<String> {
    let mut kept = String::with_capacity(text.len());
    let mut rest = text;
    while let Some(start) = rest.find('\0') {
        let after = rest[start..].trim_start_matches('\0');
        if rest.len() - start - after.len() < NUL_RUN {
            return None;
        }
        kept.push_str(&rest[..start]);
        if !after.is_empty() {
            kept.push_str("[NUL bytes removed]");
        }
        rest = after;
    }
    kept.push_str(rest);
    Some(kept)
}

/// Matches an account, computer or domain name where it stands on its own:
/// with no word character beside it at either end. `\b` says that only for
/// an end that is itself a word character; beside punctuation, as at the end
/// of `Jack!`, it would demand a word character instead. `\B` says it there,
/// and like `\b` consumes no character, so two occurrences one character
/// apart both match.
fn identity(name: &str) -> Regex {
    let edge = |end: Option<char>| match end {
        Some(end) if WORD.is_match(end.encode_utf8(&mut [0; 4])) => r"\b",
        _ => r"\B",
    };
    let (first, last) = (edge(name.chars().next()), edge(name.chars().next_back()));
    Regex::new(&format!("(?i){first}{}{last}", regex::escape(name))).unwrap()
}

/// The profile folder names on this PC that contain whitespace: the current
/// profile and its siblings.
fn spaced_profiles() -> Vec<String> {
    let Some(home) = std::env::var_os("USERPROFILE") else { return Vec::new() };
    let Some(profiles) = std::path::Path::new(&home).parent() else { return Vec::new() };
    std::fs::read_dir(profiles)
        .into_iter()
        .flatten()
        .flatten()
        .filter_map(|entry| entry.file_name().into_string().ok())
        .filter(|name| {
            name.contains(char::is_whitespace)
                && !SHARED_PROFILES.iter().any(|shared| name.eq_ignore_ascii_case(shared))
        })
        .collect()
}

fn alias(aliases: &mut HashMap<String, String>, value: &str) -> String {
    // Manifest strings may already have been redacted while recording an
    // unreadable file. Preserve the same label on that second pass.
    if aliases.values().any(|label| label.eq_ignore_ascii_case(value)) {
        return value.to_owned();
    }
    let next = aliases.len() + 1;
    aliases.entry(value.to_lowercase()).or_insert_with(|| format!("anonymous-{next}")).clone()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A redactor that knows no account, computer or profile names.
    fn nameless() -> Redactor {
        Redactor::with(&[], Vec::new())
    }

    #[test]
    fn removes_credentials_without_losing_failure_context() {
        let source = r#"{"password":"two words","nested":{"apiKey":"top-secret"},"error":"Access denied (0x80070005) at C:\\Users\\Sample Person\\AppData\\Local\\AtlasOS\\Logs\\install.log","build":"26200.9278","model":"Samsung SSD 980","transactionId":"test-job-42","options":["disable-defender"],"url":"https://user:secret@example.org/Atlas.apbx?sig=secret-value&version=1","email":"test@example.net"}"#;
        let result = String::from_utf8(nameless().file(source.as_bytes()).unwrap().bytes).unwrap();
        for secret in
            ["two words", "top-secret", "Sample Person", "user:secret", "secret-value", "test@example.net"]
        {
            assert!(!result.contains(secret), "leaked {secret}");
        }
        let json: Value = serde_json::from_str(&result).unwrap();
        assert_eq!(json["password"], "[credential removed]");
        for evidence in [
            "0x80070005",
            "AppData",
            "install.log",
            "26200.9278",
            "Samsung SSD 980",
            "test-job-42",
            "disable-defender",
            "example.org/Atlas.apbx",
            "version=1",
        ] {
            assert!(result.contains(evidence), "lost {evidence}");
        }
    }

    #[test]
    fn preserves_relationships_and_system_accounts_in_utf16_logs() {
        let source = "C:\\Users\\Alice\\AppData\\Local\\AtlasOS error\nC:\\Users\\Bob\\AppData\\Local\\AtlasOS error\nC:\\Users\\Alice\\Downloads\\Atlas.apbx\nS-1-5-18 S-1-5-32-544 S-1-5-21-111-222-333-1001\npassword='a secret' HRESULT=0x80070005\n";
        let bytes: Vec<u8> =
            [0xff, 0xfe].into_iter().chain(source.encode_utf16().flat_map(u16::to_le_bytes)).collect();
        let mut redactor = nameless();
        let result = String::from_utf8(redactor.file(&bytes).unwrap().bytes).unwrap();
        assert!(!result.contains("Alice") && !result.contains("Bob") && !result.contains("a secret"));
        assert_eq!(result.matches("anonymous-1").count(), 2);
        assert!(result.contains("anonymous-2") && result.contains("S-1-5-18 S-1-5-32-544"));
        assert!(result.contains("-1001") && result.contains("HRESULT=0x80070005"));
        assert!(redactor.file(&[0, 0, 255]).is_none());
        assert!(redactor.file(&[0xff, 0xfe, 0]).is_none());
    }

    #[test]
    fn aliases_glued_and_entra_sids_but_keeps_well_known_ones() {
        let source = "\\GoogleUpdateTaskUserS-1-5-21-111-222-333-1001Core{A}\nTask-S-1-5-21-111-222-333-1001\nHKU\\S-1-5-21-111-222-333-1001_Classes\nS-1-12-1-1234-5678-9012-3456 S-1-5-18 S-1-5-32-544\n\\GoogleUpdateTaskUserS-1-12-1-1234-5678-9012-3456Core{B}\n\\MicrosoftEdgeUpdateTaskUserS-1-12-1-1234-5678-9012-3456UA{C}\nHKU\\S-1-12-1-1234-5678-9012-3456_Classes\n";
        let mut redactor = nameless();
        let result = redactor.text(source);
        assert!(!result.contains("111-222-333") && !result.contains("1234-5678"), "{result}");
        assert_eq!(result.matches("anonymous-1-1001").count(), 3, "{result}");
        assert!(result.contains("Useranonymous-1-1001Core{A}") && result.contains("-1001_Classes"));
        assert!(result.contains("anonymous-2 S-1-5-18 S-1-5-32-544"), "{result}");
        assert!(
            result.contains("Useranonymous-2Core{B}") && result.contains("Useranonymous-2UA{C}"),
            "{result}"
        );
        assert!(result.contains("HKU\\anonymous-2_Classes"), "{result}");
        assert_eq!(result.matches("anonymous-2").count(), 4, "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn a_path_ending_at_the_profile_folder_keeps_the_rest_of_its_line() {
        let source = "Access to the path 'C:\\Users\\Zelda' is denied.\npath C:\\Users\\Zelda is missing, retrying\nC:\\Users\\Zelda\\x and C:\\Users\\Zelda.\nC:\\Users\\O'Brien\\AppData and 'C:\\Users\\O'Brien'\nC:\\Users\\Public C:\\Users\\Default User\\NTUSER.DAT\n";
        let mut redactor = nameless();
        let result = redactor.text(source);
        assert!(!result.contains("Zelda") && !result.contains("Brien"), "{result}");
        assert!(result.contains("'C:\\Users\\anonymous-1' is denied."), "{result}");
        assert!(result.contains("C:\\Users\\anonymous-1 is missing, retrying"), "{result}");
        assert!(result.contains("C:\\Users\\anonymous-1\\x and C:\\Users\\anonymous-1.\n"), "{result}");
        assert!(result.contains("anonymous-2\\AppData and 'C:\\Users\\anonymous-2'"), "{result}");
        assert!(result.contains("C:\\Users\\Public C:\\Users\\Default User\\NTUSER.DAT"), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn a_profile_name_with_spaces_keeps_one_label_wherever_its_path_ends() {
        let source = "Access to the path 'C:\\Users\\Jane Doe' is denied.\nUSERPROFILE=C:\\Users\\Jane Doe\nC:\\Users\\Jane Doe\\AppData\\x.log\nSaved to C:\\Users\\Jane Doe.\nC:\\Users\\Jane Doe Smith\\x and 'C:\\Users\\Jane Doe Smith'\nC:\\Users\\Default User\\NTUSER.DAT\n";
        let mut redactor = Redactor::with(&[], vec!["Jane Doe".into(), "Jane Doe Smith".into()]);
        let result = redactor.text(source);
        assert!(!result.contains("Doe") && !result.contains("Smith"), "{result}");
        assert!(result.contains("'C:\\Users\\anonymous-1' is denied.\n"), "{result}");
        assert!(result.contains("USERPROFILE=C:\\Users\\anonymous-1\n"), "{result}");
        assert!(result.contains("C:\\Users\\anonymous-1\\AppData\\x.log"), "{result}");
        assert!(result.contains("Saved to C:\\Users\\anonymous-1.\n"), "{result}");
        assert!(result.contains("C:\\Users\\anonymous-2\\x and 'C:\\Users\\anonymous-2'"), "{result}");
        assert!(result.contains("C:\\Users\\Default User\\NTUSER.DAT"), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn the_collecting_users_name_with_spaces_is_aliased_before_its_profile_path() {
        // A domain name aliased on its own must not break an address apart.
        let mut redactor = Redactor::with(&["Jane Doe".into(), "corp.example.org".into()], Vec::new());
        let result =
            redactor.text("'C:\\Users\\Jane Doe' is denied for Jane Doe; ask bob@corp.example.org\n");
        assert!(!result.contains("Doe") && !result.contains("bob"), "{result}");
        assert!(result.contains("'C:\\Users\\anonymous-2' is denied for anonymous-2;"), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn names_that_begin_or_end_with_punctuation_are_aliased_where_they_stand_alone() {
        let mut redactor = Redactor::with(&["Jack!", "(Desk)", "Al"].map(String::from), Vec::new());
        let result = redactor.text(
            "Jack! signed in on (Desk). 'Jack!' then Jack!,Jack! and at the end Jack!\nAlready Al.\nPC=(DESK)\n",
        );
        assert!(!result.contains("Jack") && !result.contains("Desk") && !result.contains("DESK"), "{result}");
        assert_eq!(result.matches("anonymous-1").count(), 5, "{result}");
        assert!(result.contains("on anonymous-2. 'anonymous-1'"), "{result}");
        assert!(result.contains("PC=anonymous-2\n"), "{result}");
        // A name that is all word characters still never matches inside a word.
        assert!(result.contains("Already anonymous-3.\n"), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn recovery_job_folders_keep_no_hash_of_the_profile_path() {
        let scope = crate::services::releases::sha256_bytes(
            br"C:\Users\Priya\AppData\Local\AtlasOS\App\settings.json",
        );
        let executable = "0".repeat(64);
        let source = format!(
            "following a preparation worker still running: pid 42 in C:\\Program Files\\Atlas Setup Recovery\\Preparation\\{scope}\\1234-5678\n\
             {{\"job\":\"C:\\\\Program Files\\\\Atlas Setup Recovery\\\\Media\\\\{}\\\\99-1\"}}\n\
             C:\\Program Files\\Atlas Setup Recovery\\{executable}\\AtlasManager.exe\n",
            scope.to_uppercase()
        );
        let mut redactor = nameless();
        let result = redactor.text(&source);
        assert!(!result.to_lowercase().contains(&scope), "{result}");
        assert!(result.contains("Recovery\\Preparation\\anonymous-1\\1234-5678\n"), "{result}");
        assert!(result.contains("Recovery\\\\Media\\\\anonymous-1\\\\99-1"), "{result}");
        // The executable's folder is named by its own digest, which says nothing about anyone.
        assert!(result.contains(&format!("Recovery\\{executable}\\AtlasManager.exe")), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn the_iso_account_name_gets_the_label_of_its_profile() {
        let source = r#"{"username":"Priya","output":"C:\\Users\\Priya\\x.iso","options":["disable-defender"],"supportedBuilds":[26100]}"#;
        let mut redactor = nameless();
        let once = redactor.file(source.as_bytes()).unwrap().bytes;
        let result = String::from_utf8(once.clone()).unwrap();
        assert!(!result.contains("Priya"), "{result}");
        let json: Value = serde_json::from_str(&result).unwrap();
        assert_eq!(json["output"], format!("C:\\Users\\{}\\x.iso", json["username"].as_str().unwrap()));
        assert_eq!(json["options"][0], "disable-defender");
        assert_eq!(json["supportedBuilds"][0], 26100);
        assert_eq!(redactor.file(&once).unwrap().bytes, once);
    }

    #[test]
    fn handles_headers_command_arguments_and_multiline_credentials() {
        // The second Authorization header is mid-line, where the header rule
        // cannot see it.
        let text = "Cookie: session=secret; second=also-secret\nAuthorization: Basic dXNlcjpwYXNz\nrequest Authorization: Basic bWlkOmxpbmU=\nsetup.exe -Password 'two words' -Mode Repair\n<Password>xml-secret</Password>\n-----BEGIN PRIVATE KEY-----\nkey-material\n-----END PRIVATE KEY-----\nERROR exit=5 module=Atlas.Install line=42";
        let result = nameless().text(text);
        for secret in [
            "session=secret",
            "also-secret",
            "dXNlcjpwYXNz",
            "bWlkOmxpbmU",
            "two words",
            "xml-secret",
            "key-material",
        ] {
            assert!(!result.contains(secret), "leaked {secret}");
        }
        assert!(
            result.contains("-Mode Repair") && result.contains("ERROR exit=5 module=Atlas.Install line=42")
        );
    }

    #[test]
    fn repeated_redaction_keeps_aliases_and_credential_markers_stable() {
        let source = "C:\\Users\\Sample Person\\AppData\\Local\\AtlasOS\\install.log\npassword='secret'\nsetup.exe -Password 'secret' -Mode Repair\n";
        let mut redactor = nameless();
        let once = redactor.text(source);
        assert_eq!(redactor.text(&once), once);
    }

    #[test]
    fn keeps_driver_names_and_code_signing_results() {
        let evidence =
            "Microsoft Basic Display Adapter; signature=valid; signature: invalid; ERROR=0x800B0100";
        assert_eq!(nameless().text(evidence), evidence);
    }

    #[test]
    fn generic_and_atlas_names_stay_words_of_the_logs() {
        let names = ["User", "ATLAS", "AtlasOS", "Jane", ""].map(String::from);
        let mut redactor = Redactor::with(&names, Vec::new());
        let result = redactor.text(
            "User account Jane signed in\nAtlas Manager 0.6.0 started\nERROR module=Atlas.Install\n\
             https://example.org/Atlas.apbx\n%LOCALAPPDATA%\\AtlasOS\\App\nC:\\Users\\Atlas\\AppData\n",
        );
        assert!(result.contains("User account anonymous-1 signed in\n"), "{result}");
        for evidence in [
            "Atlas Manager 0.6.0 started",
            "module=Atlas.Install",
            "example.org/Atlas.apbx",
            "\\AtlasOS\\App",
        ] {
            assert!(result.contains(evidence), "lost {evidence}: {result}");
        }
        // A profile folder is someone's whatever it is called.
        assert!(result.contains("C:\\Users\\anonymous-2\\AppData"), "{result}");
    }

    #[test]
    fn the_collecting_users_account_name_is_aliased() {
        let Ok(name) = std::env::var("USERNAME") else { return };
        if name.is_empty() || GENERIC_NAMES.iter().any(|item| name.eq_ignore_ascii_case(item)) {
            return;
        }
        assert_eq!(Redactor::new().text(&format!("signed in as {name}")), "signed in as anonymous-1");
    }

    #[test]
    fn nul_padding_is_taken_out_and_utf16_without_a_mark_is_still_refused() {
        let mut redactor = nameless();
        // UTF-8 with a byte order mark, as the engine's logs are, cut off by a crash.
        let padded = [b"\xef\xbb\xbfphase 3 started\r\n".as_slice(), &[0; 4096]].concat();
        let redacted = redactor.file(&padded).unwrap();
        assert!(redacted.padding_removed);
        assert_eq!(redacted.bytes, b"phase 3 started\r\n");
        // A resumed install writes on after the padding, and that is redacted as usual.
        let resumed =
            [b"phase 3 started\r\n".as_slice(), &[0; 512], b"resumed in C:\\Users\\Zelda\\x\r\n"].concat();
        assert_eq!(
            String::from_utf8(redactor.file(&resumed).unwrap().bytes).unwrap(),
            "phase 3 started\r\n[NUL bytes removed]resumed in C:\\Users\\anonymous-1\\x\r\n"
        );
        let utf16: Vec<u8> = [0xff, 0xfe]
            .into_iter()
            .chain("line\r\n".encode_utf16().flat_map(u16::to_le_bytes))
            .chain([0; 64])
            .collect();
        assert_eq!(redactor.file(&utf16).unwrap().bytes, b"line\r\n");
        assert!(!redactor.file(b"no padding").unwrap().padding_removed);
        // Without a mark, UTF-16 has a NUL beside each ASCII character and
        // at most two together, as between 'a' and U+0100.
        let unmarked: Vec<u8> = "a\u{100}bc".encode_utf16().flat_map(u16::to_le_bytes).collect();
        assert!(redactor.file(&unmarked).is_none());
        assert!(redactor.file(&[b"short".as_slice(), &[0; NUL_RUN - 1], b"run"].concat()).is_none());
    }
}
