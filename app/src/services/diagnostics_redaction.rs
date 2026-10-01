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
/// JSON keys whose values are credentials, removed whatever they hold.
static SENSITIVE_KEY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?i)^(?:password|passwd|pwd|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|authorization|proxy-authorization|cookie|set-cookie|private[_-]?key)$").unwrap()
});
/// The local account name typed for an ISO, in each media job's request.json.
static IDENTITY_KEY: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?i)^user[_-]?name$").unwrap());

impl Redactor {
    pub fn new() -> Self {
        Self::with_profiles(spaced_profiles())
    }

    /// A redactor that knows `spaced`, the profile folder names containing
    /// whitespace, so it can tell where such a name ends.
    fn with_profiles(spaced: Vec<String>) -> Self {
        // Longest first, so a name is never cut short by another it begins with.
        let mut spaced: Vec<String> = spaced.iter().map(|name| regex::escape(name)).collect();
        spaced.sort_by_key(|name| std::cmp::Reverse(name.len()));
        let spaced = if spaced.is_empty() {
            String::new()
        } else {
            format!(r"(?P<spaced>{})(?P<after>\W|\z)|", spaced.join("|"))
        };
        let mut this = Self {
            aliases: HashMap::new(),
            identities: Vec::new(),
            // A profile name may contain spaces when a separator follows it on
            // the same line. Otherwise a known name with spaces is matched
            // whole, and any other stops at whitespace, so a quoted or
            // sentence-final path keeps the rest of its line. The excluded
            // characters cannot appear in account names.
            profile: Regex::new(&format!(
                r#"(?i)(?P<prefix>[a-z]:[\\/]+Users[\\/]+)(?:(?P<name>[^\\/\r\n"<>:|?*,;=+\[\]@]+)(?P<separator>[\\/])|{spaced}(?P<tail>[^\\/\r\n"<>:|?*,;=+\[\]@\s]+))"#
            ))
            .unwrap(),
        };
        for name in ["USERNAME", "COMPUTERNAME", "USERDOMAIN", "USERDNSDOMAIN"] {
            if let Ok(value) = std::env::var(name)
                && !value.is_empty()
                && !["WORKGROUP", "NT AUTHORITY", "SYSTEM"]
                    .iter()
                    .any(|item| value.eq_ignore_ascii_case(item))
            {
                this.identities.push(Regex::new(&format!(r"(?i)\b{}\b", regex::escape(&value))).unwrap());
            }
        }
        this
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

    /// Redacts a text file: UTF-8, or UTF-16 with a byte order mark. JSON is
    /// redacted by key as well, and written back pretty-printed. `None` for
    /// anything else, which the caller leaves out.
    pub fn file(&mut self, bytes: &[u8]) -> Option<Vec<u8>> {
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
        if source.contains('\0') {
            return None;
        }
        if let Ok(mut value) = serde_json::from_str::<Value>(&source) {
            self.json(&mut value);
            serde_json::to_vec_pretty(&value).ok()
        } else {
            Some(self.text(&source).into_bytes())
        }
    }
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

    #[test]
    fn removes_credentials_without_losing_failure_context() {
        let source = r#"{"password":"two words","nested":{"apiKey":"top-secret"},"error":"Access denied (0x80070005) at C:\\Users\\Sample Person\\AppData\\Local\\AtlasOS\\Logs\\install.log","build":"26200.9278","model":"Samsung SSD 980","transactionId":"test-job-42","options":["disable-defender"],"url":"https://user:secret@example.org/Atlas.apbx?sig=secret-value&version=1","email":"test@example.net"}"#;
        let result = String::from_utf8(Redactor::new().file(source.as_bytes()).unwrap()).unwrap();
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
        let mut redactor = Redactor::new();
        let result = String::from_utf8(redactor.file(&bytes).unwrap()).unwrap();
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
        let mut redactor = Redactor::new();
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
        let mut redactor = Redactor::new();
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
        let mut redactor = Redactor::with_profiles(vec!["Jane Doe".into(), "Jane Doe Smith".into()]);
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
        let mut redactor = Redactor::with_profiles(Vec::new());
        redactor.identities.push(Regex::new(r"(?i)\bJane Doe\b").unwrap());
        // A domain name aliased on its own must not break an address apart.
        redactor.identities.push(Regex::new(r"(?i)\bcorp\.example\.org\b").unwrap());
        let result =
            redactor.text("'C:\\Users\\Jane Doe' is denied for Jane Doe; ask bob@corp.example.org\n");
        assert!(!result.contains("Doe") && !result.contains("bob"), "{result}");
        assert!(result.contains("'C:\\Users\\anonymous-2' is denied for anonymous-2;"), "{result}");
        assert_eq!(redactor.text(&result), result);
    }

    #[test]
    fn the_iso_account_name_gets_the_label_of_its_profile() {
        let source = r#"{"username":"Priya","output":"C:\\Users\\Priya\\x.iso","options":["disable-defender"],"supportedBuilds":[26100]}"#;
        let mut redactor = Redactor::new();
        let once = redactor.file(source.as_bytes()).unwrap();
        let result = String::from_utf8(once.clone()).unwrap();
        assert!(!result.contains("Priya"), "{result}");
        let json: Value = serde_json::from_str(&result).unwrap();
        assert_eq!(json["output"], format!("C:\\Users\\{}\\x.iso", json["username"].as_str().unwrap()));
        assert_eq!(json["options"][0], "disable-defender");
        assert_eq!(json["supportedBuilds"][0], 26100);
        assert_eq!(redactor.file(&once).unwrap(), once);
    }

    #[test]
    fn handles_headers_command_arguments_and_multiline_credentials() {
        // The second Authorization header is mid-line, where the header rule
        // cannot see it.
        let text = "Cookie: session=secret; second=also-secret\nAuthorization: Basic dXNlcjpwYXNz\nrequest Authorization: Basic bWlkOmxpbmU=\nsetup.exe -Password 'two words' -Mode Repair\n<Password>xml-secret</Password>\n-----BEGIN PRIVATE KEY-----\nkey-material\n-----END PRIVATE KEY-----\nERROR exit=5 module=Atlas.Install line=42";
        let result = Redactor::new().text(text);
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
        let mut redactor = Redactor::new();
        let once = redactor.text(source);
        assert_eq!(redactor.text(&once), once);
    }

    #[test]
    fn keeps_driver_names_and_code_signing_results() {
        let evidence =
            "Microsoft Basic Display Adapter; signature=valid; signature: invalid; ERROR=0x800B0100";
        assert_eq!(Redactor::new().text(evidence), evidence);
    }
}
