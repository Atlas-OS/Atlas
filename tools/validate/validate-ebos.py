#!/usr/bin/env python3
"""
EBOS Repository Validator
=========================
Cross-platform static validation for the unified EBOS repository.

Checks
------
1. YAML syntax        — every .yml/.yaml under src/ parses
2. Task references    — every `!task {path: ...}` resolves to a file
3. Executable refs    — every `!run`/`!cmd` `exe:` target exists in Executables/
4. Playbook manifest  — playbook.conf parses as XML; options used by tasks
                        are declared in its FeaturePages
5. Branding           — no legacy product names outside the attribution allowlist
6. Secrets            — scans for tokens/keys/credentials
7. Build sync         — SupportedBuilds in playbook.conf match EBOS-Core.ps1

Exit code 0 = all green. Any ERROR fails the build; WARNINGs are reported.
"""
import os
import re
import sys
import glob
import json
import xml.etree.ElementTree as ET

try:
    import yaml
except ImportError:
    print("FATAL: PyYAML is required (pip install pyyaml)")
    sys.exit(2)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CFG = os.path.join(ROOT, "src", "playbook", "Configuration")
EXE = os.path.join(ROOT, "src", "playbook", "Executables")
CONF = os.path.join(ROOT, "src", "playbook", "playbook.conf")

ERRORS, WARNINGS = [], []

def err(msg): ERRORS.append(msg); print(f"  [ERROR] {msg}")
def warn(msg): WARNINGS.append(msg); print(f"  [WARN ] {msg}")
def ok(msg): print(f"  [PASS ] {msg}")

# --------------------------------------------------------------------------
# 1. YAML syntax (with tolerant handling of AME Wizard custom tags)
# --------------------------------------------------------------------------
class TolerantLoader(yaml.SafeLoader):
    pass

def _any_constructor(loader, tag_suffix, node):
    if isinstance(node, yaml.MappingNode):
        return loader.construct_mapping(node)
    if isinstance(node, yaml.SequenceNode):
        return loader.construct_sequence(node)
    return loader.construct_scalar(node)

TolerantLoader.add_multi_constructor("!", _any_constructor)

yaml_files = sorted(
    glob.glob(os.path.join(ROOT, "src", "**", "*.yml"), recursive=True) +
    glob.glob(os.path.join(ROOT, "src", "**", "*.yaml"), recursive=True) +
    glob.glob(os.path.join(ROOT, ".github", "**", "*.yaml"), recursive=True) +
    glob.glob(os.path.join(ROOT, ".github", "**", "*.yml"), recursive=True)
)

print(f"\n== 1. YAML syntax ({len(yaml_files)} files) ==")
parsed = {}
bad = 0
for path in yaml_files:
    rel = os.path.relpath(path, ROOT)
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        doc = yaml.load(text, Loader=TolerantLoader)
        parsed[rel] = (doc, text)
    except yaml.YAMLError as e:
        bad += 1
        err(f"YAML parse failure in {rel}: {e}")
if bad == 0:
    ok(f"all {len(yaml_files)} YAML files parse")

# --------------------------------------------------------------------------
# 2. Task references resolve
# --------------------------------------------------------------------------
print("\n== 2. Task path references ==")
task_re = re.compile(r"!task:\s*\{[^}]*path:\s*['\"]([^'\"]+)['\"]")
checked = missing = 0
for rel, (doc, text) in parsed.items():
    cfg_rel = os.path.relpath(os.path.join(CFG, ""), CFG)
    if not rel.startswith(os.path.join("src", "playbook", "Configuration")):
        continue
    for m in task_re.finditer(text):
        p = m.group(1).replace("\\", os.sep)
        checked += 1
        target = os.path.join(CFG, p)
        if not os.path.isfile(target):
            missing += 1
            err(f"dangling task reference in {rel}: {m.group(1)}")
if checked and missing == 0:
    ok(f"{checked} task references resolve")
elif checked == 0:
    warn("no task references found")

# --------------------------------------------------------------------------
# 3. Executable references
# --------------------------------------------------------------------------
print("\n== 3. Executable references ==")
exe_re = re.compile(r"!run:\s*\{[^}]*exe:\s*['\"]([^'\"]+)['\"]")
checked = missing = 0
builtin_exes = {
    "explorer.exe", "rundll32.exe", "DISM.exe", "gpupdate.exe", "fsutil.exe", "powercfg.exe",
    "netsh.exe", "bcdedit.exe", "msiexec.exe", "PowerShell", "reg.exe",
    "Enable-WindowsOptionalFeature", "schtasks.exe", "reagentc.exe",
}
for rel, (doc, text) in parsed.items():
    if not rel.startswith(os.path.join("src", "playbook", "Configuration")):
        continue
    for m in exe_re.finditer(text):
        name = m.group(1)
        checked += 1
        if name in builtin_exes or "\\" not in name and "." not in name:
            continue
        if not os.path.isfile(os.path.join(EXE, name)):
            missing += 1
            err(f"missing executable in {rel}: {name}")
if checked and missing == 0:
    ok(f"{checked} !run executable references valid")

# --------------------------------------------------------------------------
# 4. Playbook manifest + option sync
# --------------------------------------------------------------------------
print("\n== 4. Playbook manifest ==")
try:
    tree = ET.parse(CONF)
    root = tree.getroot()
    defined_options = {el.findtext("Name") for el in root.iter() if el.tag.endswith("Option") and el.findtext("Name")}
    ok(f"playbook.conf parses; {len(defined_options)} options declared")
except ET.ParseError as e:
    defined_options = set()
    err(f"playbook.conf XML invalid: {e}")

used_options = set()
negated = set()
for rel, (doc, text) in parsed.items():
    if not rel.startswith(os.path.join("src", "playbook", "Configuration")):
        continue
    for m in re.finditer(r"option[s]?:\s*([^ {}\n]+)", text):
        vals = [v.strip("'\"![],") for v in m.group(1).split(",")]
        for v in vals:
            if not v or v.startswith("!"):
                if v.startswith("!") and len(v) > 1:
                    negated.add(v[1:])
                continue
            used_options.add(v)
undeclared = used_options - defined_options - negated
if undeclared:
    for u in sorted(undeclared):
        warn(f"option '{u}' used by tasks but not declared in playbook.conf FeaturePages")
else:
    ok("every option used by tasks is declared in playbook.conf")

# --------------------------------------------------------------------------
# 5. Branding scan
# --------------------------------------------------------------------------
print("\n== 5. Branding migration ==")
ALLOWLIST = [
    os.path.join("docs", "ATTRIBUTION.md"),
    os.path.join("docs", "CHANGELOG.md"),
    "LICENSE",
    os.path.join(".github", "SECURITY.md"),
    os.path.join("src", "playbook", "Executables", "EBOSModules", "Acknowledgements"),
    os.path.join("src", "playbook", "Executables", "Licenses"),
    os.path.join("src", "playbook", "Executables", "BraveSoftware"),
]
BRAND_RE = re.compile(r"\b(atlas\s?os|atlas)\b", re.IGNORECASE)
REV_RE = re.compile(r"\b(revios|revision|revitool|meetrevision)\b", re.IGNORECASE)
violations = 0
for path in glob.glob(os.path.join(ROOT, "**", "*"), recursive=True):
    if not os.path.isfile(path) or ".git" + os.sep in path + os.sep:
        continue
    rel = os.path.relpath(path, ROOT)
    if rel.startswith("tools" + os.sep):  # dev tooling (incl. this validator)
        continue
    if any(rel.startswith(a) for a in ALLOWLIST):
        continue
    if not rel.endswith((".yml", ".yaml", ".md", ".ps1", ".cmd", ".json", ".xml", ".conf", ".reg", ".txt", ".theme", ".url", ".py", ".psm1")):
        continue
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh, 1):
                if "github.com/meetrevision" in line or "Atlas-OS/sxsc" in line:
                    continue  # factual upstream references (issues/tooling) are allowed
                if BRAND_RE.search(line) or REV_RE.search(line):
                    violations += 1
                    err(f"legacy branding in {rel}:{i}: {line.strip()[:100]}")
    except OSError:
        pass
if violations == 0:
    ok("no legacy product branding outside the attribution allowlist")

# --------------------------------------------------------------------------
# 6. Secret scan
# --------------------------------------------------------------------------
print("\n== 6. Secret scan ==")
SECRET_PATTERNS = [
    (re.compile(r"(?i)(api[_-]?key|secret|password|passwd|token)\s*[:=]\s*['\"][A-Za-z0-9+/=_-]{16,}['\"]"), "hardcoded credential"),
    (re.compile(r"(?i)-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"), "private key"),
    (re.compile(r"(?i)\b(ghp|gho|github_pat)_[A-Za-z0-9]{20,}"), "GitHub token"),
    (re.compile(r"(?i)\bAKIA[0-9A-Z]{16}\b"), "AWS access key"),
]
findings = 0
for path in glob.glob(os.path.join(ROOT, "**", "*"), recursive=True):
    if not os.path.isfile(path) or (".git" + os.sep) in (path + os.sep):
        continue
    rel = os.path.relpath(path, ROOT)
    if rel.startswith((".git", "images", "src/playbook/Images")):
        continue
    if not rel.endswith((".yml", ".yaml", ".md", ".ps1", ".cmd", ".json", ".xml", ".conf", ".py", ".psm1", ".theme", ".url")):
        continue
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh, 1):
                for pat, desc in SECRET_PATTERNS:
                    if pat.search(line):
                        findings += 1
                        err(f"possible {desc} in {rel}:{i}: {line.strip()[:80]}")
    except OSError:
        pass
if findings == 0:
    ok("no secrets detected")

# --------------------------------------------------------------------------
# 7. SupportedBuilds sync (playbook.conf <-> EBOS-Core.ps1)
# --------------------------------------------------------------------------
print("\n== 7. Build support sync ==")
try:
    conf_builds = {el.text.strip() for el in root.iter() if el.tag.endswith("string") and el.text and el.text.strip().isdigit()}
    core_path = os.path.join(EXE, "EBOSModules", "Core", "EBOS-Core.ps1")
    core_text = open(core_path, encoding="utf-8").read()
    m = re.search(r"\$script:EBOSSupportedBuilds\s*=\s*@\(([^)]*)\)", core_text)
    core_builds = set(re.findall(r"\d+", m.group(1))) if m else set()
    if conf_builds == core_builds:
        ok(f"SupportedBuilds in sync ({', '.join(sorted(conf_builds))})")
    else:
        err(f"SupportedBuilds mismatch: playbook.conf={sorted(conf_builds)} EBOS-Core.ps1={sorted(core_builds)}")
except Exception as e:
    err(f"build sync check failed: {e}")

# --------------------------------------------------------------------------
print("\n" + "=" * 60)
print(f"RESULT: {len(ERRORS)} error(s), {len(WARNINGS)} warning(s)")
print("=" * 60)
sys.exit(1 if ERRORS else 0)
