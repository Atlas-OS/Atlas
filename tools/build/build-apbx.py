#!/usr/bin/env python3
"""
EBOS APBX Builder
=================
Cross-platform port of ``src/dependencies/local-build.ps1`` (the official
build script). Produces the EBOS Playbook ``.apbx`` — a renamed
password-protected ZIP (password: ``malte``).

Faithful behavior of the original script:
  1. Locates the playbook directory (repo root or ``src/playbook``)
  2. Optionally strips requirement/verification entries from playbook.conf
     (--removals "Requirements,WinverRequirement,Verification,Dependencies")
  3. Optionally injects the AME Wizard live-log command into custom.yml
     (--add-live-log)
  4. Optionally strips the "NO LOCAL BUILD" section from
     Configuration/windows/init.yml (removals contains "Dependencies")
  5. ALWAYS substitutes ``EBOSVersionUndefined`` with the playbook version
     (``v<Version>``) in Configuration/misc/config-oem-information.yml
  6. Zips the playbook contents (excluding ``local-build.*`` and
     ``*.apbx``) with password ``malte`` and renames to ``.apbx``

Usage (release build — no removals, no live log):
    python3 tools/build/build-apbx.py --file-name "EBOS Playbook" --output-dir src/release-zip

CI/test build (matches the GitHub workflow):
    python3 tools/build/build-apbx.py --file-name "EBOS Playbook abcdef01" \\
        --add-live-log --removals Verification,WinverRequirement

Requires: Info-ZIP ``zip`` (or 7-Zip ``7zz``/``7z`` if present).
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

HERE = os.path.abspath(os.path.dirname(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PASSWORD = "malte"
EXCLUDE_FILES = ("local-build.*", "*.apbx")


def find_playbook_dir():
    """Mirror the original: playbook.conf in cwd, else a 'playbook' subdir."""
    cand = os.path.join(ROOT, "src", "playbook")
    if os.path.isfile(os.path.join(cand, "playbook.conf")):
        return cand
    raise SystemExit("playbook.conf not found under src/playbook")


def find_zipper():
    """Prefer 7-Zip (byte-parity with upstream builds), else Info-ZIP."""
    for z in ("7zz", "7z", "/opt/tools/7zz"):
        if shutil.which(z) or os.path.isfile(z):
            return "7z", z
    if shutil.which("zip"):
        return "zip", shutil.which("zip")
    raise SystemExit("No zip tool found: install Info-ZIP 'zip' or 7-Zip")


def matches_exclude(name):
    import fnmatch
    return any(fnmatch.fnmatch(name, pat) for pat in EXCLUDE_FILES)


def transform_playbook_conf(text, removals):
    """Replicate the pattern-stripping of local-build.ps1."""
    patterns = []
    # 0.6.5 bug workaround kept from upstream: Requirements removal strips
    # the <Requirement> entries only
    if "Requirements" in removals:
        patterns.append("<Requirement>")
    if "WinverRequirement" in removals:
        patterns += ["<string>", "</SupportedBuilds>", "<SupportedBuilds>"]
    if "Verification" in removals:
        patterns.append("<ProductCode>")
    if not patterns:
        return text
    rx = re.compile("|".join(re.escape(p) for p in patterns))
    return "\n".join(l for l in text.splitlines() if not rx.search(l)) + "\n"


LIVE_LOG_SNIPPET = (
    "  - !cmd: {command: 'start \"AME Wizard Live Log\" PowerShell -NoP -C "
    "\"$a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath("
    "'CommonApplicationData')) '\\\\AME\\\\Logs') -Directory | Sort-Object "
    "LastWriteTime -Descending | Select-Object -First 1).FullName '\\\\OutputBuffer.txt'; "
    "while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; "
    "Start-Sleep 1 }\"'}"
)


def inject_live_log(custom_text):
    idx = custom_text.find("actions:")
    if idx == -1:
        raise SystemExit("custom.yml: 'actions:' not found — cannot inject live log")
    insert_at = custom_text.find("\n", idx) + 1
    return custom_text[:insert_at] + LIVE_LOG_SNIPPET + "\n" + custom_text[insert_at:]


def strip_no_local_build(text):
    start = text.find("  ################ NO LOCAL BUILD ################")
    end = text.find("  ################ END NO LOCAL BUILD ################")
    if start == -1 or end == -1:
        raise SystemExit("init.yml: NO LOCAL BUILD markers not found")
    return text[:start] + text[end + len("  ################ END NO LOCAL BUILD ################") + 1:]


def main():
    ap = argparse.ArgumentParser(description="Build the EBOS .apbx playbook")
    ap.add_argument("--file-name", default="EBOS Playbook",
                    help="base name of the output (default: 'EBOS Playbook')")
    ap.add_argument("--output-dir", default=None,
                    help="where to place the .apbx (default: playbook directory)")
    ap.add_argument("--add-live-log", action="store_true",
                    help="inject the AME Wizard live-log command (test builds)")
    ap.add_argument("--removals", default="",
                    help="comma list: Requirements,WinverRequirement,Verification,Dependencies")
    ap.add_argument("--replace-old", action="store_true",
                    help="replace an existing output file")
    ap.add_argument("--no-password", action="store_true",
                    help="build without password protection (testing only)")
    args = ap.parse_args()

    removals = [r.strip() for r in args.removals.split(",") if r.strip()]
    playbook = find_playbook_dir()
    out_dir = os.path.abspath(os.path.join(ROOT, args.output_dir)) if args.output_dir else playbook
    os.makedirs(out_dir, exist_ok=True)
    apbx_path = os.path.join(out_dir, f"{args.file_name}.apbx")

    if os.path.exists(apbx_path):
        if args.replace_old:
            os.remove(apbx_path)
        else:
            i = 1
            while os.path.exists(os.path.join(out_dir, f"{args.file_name} ({i}).apbx")):
                i += 1
            apbx_path = os.path.join(out_dir, f"{args.file_name} ({i}).apbx")

    # ---- read + transform the files that need editing -------------------
    conf_path = os.path.join(playbook, "playbook.conf")
    conf_text = open(conf_path, encoding="utf-8").read()
    conf_edited = transform_playbook_conf(conf_text, removals)

    conf_xml = ET.fromstring(conf_text)
    version = conf_xml.findtext("Version") or ""
    if not re.match(r"^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$", version):
        raise SystemExit(f"Invalid version format in playbook.conf: {version!r}")
    oem_token = f"v{version}"

    oem_rel = os.path.join("Configuration", "misc", "config-oem-information.yml")
    oem_path = os.path.join(playbook, oem_rel)
    oem_text = open(oem_path, encoding="utf-8").read()
    if "EBOSVersionUndefined" not in oem_text:
        raise SystemExit("Couldn't find OEM string 'EBOSVersionUndefined'")
    oem_edited = oem_text.replace("EBOSVersionUndefined", oem_token)

    custom_edited = None
    if args.add_live_log:
        custom_path = os.path.join(playbook, "Configuration", "custom.yml")
        custom_edited = inject_live_log(open(custom_path, encoding="utf-8").read())

    init_edited = None
    if "Dependencies" in removals:
        init_path = os.path.join(playbook, "Configuration", "windows", "init.yml")
        init_edited = strip_no_local_build(open(init_path, encoding="utf-8").read())

    # ---- stage + zip -----------------------------------------------------
    kind, zipper = find_zipper()
    staging = tempfile.mkdtemp(prefix="ebos-apbx-")
    try:
        included = 0
        for dirpath, dirnames, filenames in os.walk(playbook):
            for fn in filenames:
                if matches_exclude(fn):
                    continue
                src = os.path.join(dirpath, fn)
                rel = os.path.relpath(src, playbook)
                dst = os.path.join(staging, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
                included += 1

        # overwrite edited copies in the staging tree
        def put(rel, text):
            dst = os.path.join(staging, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(text)

        put("playbook.conf", conf_edited)
        put(oem_rel.replace(os.sep, "/"), oem_edited)
        if custom_edited is not None:
            put("Configuration/custom.yml", custom_edited)
        if init_edited is not None:
            put("Configuration/windows/init.yml", init_edited)

        temp_zip = os.path.join(staging, "playbook.zip")
        if kind == "7z":
            pw = [] if args.no_password else [f"-p{PASSWORD}"]
            cmd = [zipper, "a", "-spf", "-y", "-mx1", *pw, "-tzip", temp_zip, "."]
            subprocess.run(cmd, cwd=staging, check=True, stdout=subprocess.DEVNULL)
        else:
            pw = ["-P", PASSWORD] if not args.no_password else []
            cmd = [zipper, "-q", "-r", "-X", "-D", *pw, temp_zip, "."]
            subprocess.run(cmd, cwd=staging, check=True)

        shutil.move(temp_zip, apbx_path)
    finally:
        shutil.rmtree(staging, ignore_errors=True)

    size_mb = os.path.getsize(apbx_path) / (1024 * 1024)
    print(f"Built successfully! Path: \"{apbx_path}\"")
    print(f"  {included} files staged, {size_mb:.1f} MiB, "
          f"password protected: {not args.no_password} (password: {PASSWORD})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
