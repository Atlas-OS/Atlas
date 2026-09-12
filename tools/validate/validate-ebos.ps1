# =====================================================================
#  EBOS Repository Validator (Windows/PowerShell edition)
#  ---------------------------------------------------------------
#  Native PowerShell port of tools/validate/validate-ebos.py covering
#  the checks that matter most on a Windows contributor machine:
#    1. Every !task path resolves under src\playbook\Configuration
#    2. Every !run exe reference resolves in src\playbook\Executables
#       (system executables whitelisted)
#    3. No legacy product branding outside the attribution allowlist
#    4. No obvious secrets
#    5. playbook.conf parses as XML and declares every option used
#
#  The Python validator additionally checks YAML parse + build sync and
#  runs in CI. Exit code 0 = pass.
# =====================================================================
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$cfg  = Join-Path $root 'src\playbook\Configuration'
$exe  = Join-Path $root 'src\playbook\Executables'
$conf = Join-Path $root 'src\playbook\playbook.conf'
$errors = 0

function Fail($msg) { Write-Host "  [ERROR] $msg" -ForegroundColor Red; $script:errors++ }
function Pass($msg) { Write-Host "  [PASS ] $msg" -ForegroundColor Green }

# ---- 1. task references ------------------------------------------------
$checked = 0
Get-ChildItem $cfg -Recurse -Include *.yml | ForEach-Object {
    $file = $_
    $text = Get-Content $file.FullName -Raw
    foreach ($m in [regex]::Matches($text, "!task:\s*\{[^}]*path:\s*['\"]([^'\"]+)['\"]")) {
        $script:checked++
        $p = Join-Path $cfg ($m.Groups[1].Value -replace '\\', '\')
        if (!(Test-Path $p -PathType Leaf)) { Fail "dangling task reference in $($file.Name): $($m.Groups[1].Value)" }
    }
}
if ($checked -gt 0) { Pass "$checked task references resolve" }

# ---- 2. executable references -------------------------------------------
$builtin = @('explorer.exe','rundll32.exe','DISM.exe','gpupdate.exe','fsutil.exe','powercfg.exe','netsh.exe','bcdedit.exe','msiexec.exe','PowerShell','reg.exe','schtasks.exe','reagentc.exe')
$exeChecked = 0
Get-ChildItem $cfg -Recurse -Include *.yml | ForEach-Object {
    $file = $_
    $text = Get-Content $file.FullName -Raw
    foreach ($m in [regex]::Matches($text, "!run:\s*\{[^}]*exe:\s*['\"]([^'\"]+)['\"]")) {
        $name = $m.Groups[1].Value
        $script:exeChecked++
        if ($builtin -contains $name) { continue }
        if (!(Test-Path (Join-Path $exe $name) -PathType Leaf)) { Fail "missing executable in $($file.Name): $name" }
    }
}
if ($exeChecked -gt 0) { Pass "$exeChecked executable references valid" }

# ---- 3. branding ----------------------------------------------------------
$allow = @('docs\ATTRIBUTION.md','docs\CHANGELOG.md','LICENSE','src\playbook\Executables\EBOSModules\Acknowledgements','src\playbook\Executables\Licenses')
$brandRe = [regex]'\b(atlas\s?os|atlas|revios|revision|revitool|meetrevision)\b'
Get-ChildItem $root -Recurse -File -Include *.yml,*.yaml,*.md,*.ps1,*.cmd,*.json,*.xml,*.conf,*.reg,*.theme,*.url |
    Where-Object { $rel = [IO.Path]::GetRelativePath($root, $_.FullName); -not ($allow | Where-Object { $rel.StartsWith($_) }) -and $rel -notmatch '^(tools|\.git)\\' } |
    ForEach-Object {
        $file = $_; $rel = [IO.Path]::GetRelativePath($root, $_.FullName)
        $i = 0
        foreach ($line in (Get-Content $file.FullName -EA 0)) {
            $i++
            if ($line -match 'github\.com/meetrevision|Atlas-OS/sxsc') { continue }
            if ($brandRe.IsMatch($line)) { Fail "legacy branding in ${rel}:$i — $($line.Trim().Substring(0, [Math]::Min(90, $line.Trim().Length)))" }
        }
    }
if ($errors -eq 0) { Pass 'no legacy product branding outside the attribution allowlist' }

# ---- 4. secrets -------------------------------------------------------------
$secretRes = @(
    [regex]'(?i)(api[_-]?key|secret|password|passwd|token)\s*[:=]\s*["''][A-Za-z0-9+/=_-]{16,}["'']',
    [regex]'(?i)-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    [regex]'(?i)\b(ghp|gho|github_pat)_[A-Za-z0-9]{20,}'
)
Get-ChildItem $root -Recurse -File -Include *.yml,*.yaml,*.md,*.ps1,*.cmd,*.json,*.xml,*.conf,*.py,*.psm1 |
    Where-Object { [IO.Path]::GetRelativePath($root, $_.FullName) -notmatch '^\.git\\' } |
    ForEach-Object {
        $file = $_; $rel = [IO.Path]::GetRelativePath($root, $_.FullName); $i = 0
        foreach ($line in (Get-Content $file.FullName -EA 0)) {
            $i++
            foreach ($re in $secretRes) { if ($re.IsMatch($line)) { Fail "possible secret in ${rel}:$i" } }
        }
    }
if ($errors -eq 0) { Pass 'no secrets detected' }

# ---- 5. manifest + options -----------------------------------------------------
try {
    [xml]$xml = Get-Content $conf -Raw
    $declared = @($xml.Playbook.FeaturePages.Descendants() | ForEach-Object { $_.Name } | Where-Object { $_ })
    $used = @()
    Get-ChildItem $cfg -Recurse -Include *.yml | ForEach-Object {
        foreach ($m in [regex]::Matches((Get-Content $_.FullName -Raw), "options?:\s*([^ {}\r\n]+)")) {
            ($m.Groups[1].Value -split ',') | ForEach-Object {
                $v = $_.Trim("'\"![],")
                if ($v -and -not $v.StartsWith('!')) { $used += $v }
            }
        }
    }
    $undeclared = Compare-Object $used ($declared | Select-Object -Unique) | Where-Object SideIndicator -eq '<='
    if ($undeclared) { $undeclared | ForEach-Object { Fail "option '$($_.InputObject)' used by tasks but not declared in playbook.conf" } }
    else { Pass 'every option used by tasks is declared in playbook.conf' }
} catch { Fail "playbook.conf parse failed: $($_.Exception.Message)" }

Write-Host ''
Write-Host "RESULT: $errors error(s)" -ForegroundColor ($errors ? 'Red' : 'Green')
exit ($(if ($errors -gt 0) { 1 } else { 0 }))
