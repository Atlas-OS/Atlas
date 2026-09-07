//! Redact exported copies only. Keep diagnostic context and correlate aliases
//! within one archive; never write an identity mapping into the archive.
use std::collections::HashMap;

use regex::{Captures, Regex};
use serde_json::Value;

pub struct Redactor {
    aliases: HashMap<String, String>,
    identities: Vec<Regex>,
    profile: Regex,
    email: Regex,
    sid: Regex,
    secrets: Vec<Regex>,
    assignment: Regex,
    sensitive_key: Regex,
}

impl Redactor {
    pub fn new() -> Self {
        let mut this = Self {
            aliases: HashMap::new(),
            identities: Vec::new(),
            profile: Regex::new(r#"(?i)([a-z]:[\\/]+Users[\\/]+)([^\\/\r\n\"<>]+)"#).unwrap(),
            email: Regex::new(r"(?i)\b[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)+\b").unwrap(),
            // Keep well-known SIDs (SYSTEM, Administrators, etc.) and the RID
            // of account SIDs, so ACL and per-user failures remain diagnosable.
            sid: Regex::new(r"(?i)\b(S-1-5-21-\d+-\d+-\d+)(-\d+)?\b").unwrap(),
            secrets: [
                r"(?s)-----BEGIN (?:[A-Z ]*PRIVATE KEY)-----.*?(?:-----END [A-Z ]*PRIVATE KEY-----|\z)",
                r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b",
                r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b",
                r"(?i)\b(?:Bearer|Basic)\s+[A-Za-z0-9_+/=.-]+",
                r"(?i)\b[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}\b",
            ].into_iter().map(|pattern| Regex::new(pattern).unwrap()).collect(),
            assignment: Regex::new(r#"(?i)(\b(?:password|passwd|pwd|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|authorization|proxy-authorization|cookie|set-cookie|sig|signature|x-amz-signature|x-goog-signature)\b[\"']?\s*[:=]\s*)(?:\"(?:\\.|[^\"\\])*\"|'[^']*'|[^\s&;,}\"<>]+)"#).unwrap(),
            sensitive_key: Regex::new(r"(?i)^(?:password|passwd|pwd|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret|authorization|proxy-authorization|cookie|set-cookie|private[_-]?key)$").unwrap(),
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
        for pattern in &self.secrets {
            text = pattern.replace_all(&text, "[credential removed]").into_owned();
        }
        static HEADERS: std::sync::LazyLock<Regex> = std::sync::LazyLock::new(|| {
            Regex::new(r"(?im)^(\s*(?:authorization|proxy-authorization|cookie|set-cookie|password|passwd|pwd)\s*:\s*)[^\r\n]*").unwrap()
        });
        text = HEADERS.replace_all(&text, "${1}[credential removed]").into_owned();
        static ARGUMENTS: std::sync::LazyLock<Regex> = std::sync::LazyLock::new(|| {
            Regex::new(r#"(?i)((?:--?|/)(?:password|passwd|pwd|access-token|api-key|client-secret)\s+)(?:\"[^\"]*\"|'[^']*'|\S+)"#).unwrap()
        });
        text = ARGUMENTS.replace_all(&text, "${1}[credential removed]").into_owned();
        static XML: std::sync::LazyLock<Regex> = std::sync::LazyLock::new(|| {
            Regex::new(r"(?is)(<(?:Password|AccessToken|RefreshToken|ApiKey|ClientSecret|PrivateKey)>).*?(</(?:Password|AccessToken|RefreshToken|ApiKey|ClientSecret|PrivateKey)>)").unwrap()
        });
        text = XML.replace_all(&text, "${1}[credential removed]${2}").into_owned();
        text = self.assignment.replace_all(&text, "${1}[credential removed]").into_owned();
        // URL user-info is never needed to diagnose a download failure. Keep
        // the protocol, host, asset path and non-secret query parameters.
        static URL_AUTH: std::sync::LazyLock<Regex> =
            std::sync::LazyLock::new(|| Regex::new(r"(?i)(https?://)[^\s/@]+@([^\s/]+)").unwrap());
        text = URL_AUTH.replace_all(&text, "${1}[credential removed]@${2}").into_owned();
        let aliases = &mut self.aliases;
        text = self
            .profile
            .replace_all(&text, |caps: &Captures<'_>| {
                if ["Public", "Default", "Default User", "All Users"]
                    .iter()
                    .any(|name| caps[2].eq_ignore_ascii_case(name))
                {
                    caps[0].to_owned()
                } else {
                    format!("{}{}", &caps[1], alias(aliases, &caps[2]))
                }
            })
            .into_owned();
        text = self.email.replace_all(&text, |caps: &Captures<'_>| alias(aliases, &caps[0])).into_owned();
        text = self
            .sid
            .replace_all(&text, |caps: &Captures<'_>| {
                format!("{}{}", alias(aliases, &caps[1]), caps.get(2).map_or("", |m| m.as_str()))
            })
            .into_owned();
        for pattern in &self.identities {
            text = pattern.replace_all(&text, |caps: &Captures<'_>| alias(aliases, &caps[0])).into_owned();
        }
        text
    }

    fn json(&mut self, value: &mut Value) {
        match value {
            Value::Object(fields) => {
                for (key, mut value) in std::mem::take(fields) {
                    if self.sensitive_key.is_match(&key) {
                        value = Value::String("[credential removed]".into());
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

fn alias(aliases: &mut HashMap<String, String>, value: &str) -> String {
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
    fn handles_headers_command_arguments_and_multiline_credentials() {
        let text = "Cookie: session=secret; second=also-secret\nAuthorization: Basic dXNlcjpwYXNz\nsetup.exe -Password 'two words' -Mode Repair\n<Password>xml-secret</Password>\n-----BEGIN PRIVATE KEY-----\nkey-material\n-----END PRIVATE KEY-----\nERROR exit=5 module=Atlas.Install line=42";
        let result = Redactor::new().text(text);
        for secret in
            ["session=secret", "also-secret", "dXNlcjpwYXNz", "two words", "xml-secret", "key-material"]
        {
            assert!(!result.contains(secret), "leaked {secret}");
        }
        assert!(
            result.contains("-Mode Repair") && result.contains("ERROR exit=5 module=Atlas.Install line=42")
        );
    }
}
