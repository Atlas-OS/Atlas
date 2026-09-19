<#
.SYNOPSIS
    Collect missing early-install evidence for RC3 without rerunning installation.
.DESCRIPTION
    Reads Atlas state and the ten newest staging requests. Writes one local log in
    Atlas Manager's Logs directory so Export diagnostics includes and redacts it,
    even in RC3. Does not execute staged scripts or change installation state.
    Run in elevated Windows PowerShell as the account that attempted installation.
#>
[CmdletBinding()]
param(
    [string]$WindowsRoot = [Environment]::GetFolderPath('Windows'),
    [string]$AppRoot = $(if ($env:ATLAS_APP_DATA) { $env:ATLAS_APP_DATA } else { Join-Path $env:LOCALAPPDATA 'AtlasOS\App' })
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$report = [Text.StringBuilder]::new()
$stateRoot = Join-Path $WindowsRoot 'AtlasOS'

function Assert-EvidencePath {
    param([string]$Path)
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Skipped reparse point: $current"
            }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Add-EvidenceFile {
    param([string]$Path)
    [void]$report.AppendLine("`r`nFILE: $Path")
    try {
        Assert-EvidencePath $Path
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.PSIsContainer -or $item.Length -gt 33554432) { throw 'Not a file or exceeds 32 MiB.' }
        $text = if ($item.Length -gt 1048576 -and $item.Extension -eq '.log') {
            "[Last 400 lines of large log]`r`n" + ((Get-Content -LiteralPath $item.FullName -Tail 400) -join "`r`n")
        } else { [IO.File]::ReadAllText($item.FullName) }
        if ($report.Length + $text.Length -gt 4194304) { throw 'Evidence report reached its 4 Mi-character limit.' }
        [void]$report.AppendLine($text)
    }
    catch { [void]$report.AppendLine("Unavailable: $($_.Exception.Message)") }
}

function Add-InstallLogDirectory {
    param([string]$Path)
    try {
        Assert-EvidencePath $Path
        # RC3 writes atlas-install.log and transcripts here, rather than the new
        # install-capture.log/install-run.log files beside this directory.
        Add-EvidenceFile (Join-Path $Path 'atlas-install.log')
        $files = @(Get-ChildItem -LiteralPath $Path -File -Filter '*.log' -Force |
            Where-Object Name -ne 'atlas-install.log' |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 5)
        foreach ($file in $files) { Add-EvidenceFile $file.FullName }
    }
    catch { [void]$report.AppendLine("Install logs unavailable at ${Path}: $($_.Exception.Message)") }
}

[void]$report.AppendLine("Atlas early-install evidence; UTC $([DateTime]::UtcNow.ToString('o'))")
[void]$report.AppendLine("PowerShell $($PSVersionTable.PSVersion); language mode $($ExecutionContext.SessionState.LanguageMode)")
Add-EvidenceFile (Join-Path $AppRoot 'session.json')
Add-EvidenceFile (Join-Path $stateRoot 'state.json')
foreach ($name in @('active.json', 'active.json.bak', 'completed.json', 'abandoned.json')) {
    Add-EvidenceFile (Join-Path $stateRoot "Install\$name")
}
Add-InstallLogDirectory (Join-Path $WindowsRoot 'AtlasModules\Logs\install')
try {
    $staging = Join-Path $stateRoot 'Staging'
    Assert-EvidencePath $staging
    $stages = @(Get-ChildItem -LiteralPath $staging -Directory -Force |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 10)
    foreach ($stage in $stages) {
        Add-EvidenceFile (Join-Path $stage.FullName 'Executables\request.json')
        Add-EvidenceFile (Join-Path $stage.FullName 'Preparation\state.json')
        Add-InstallLogDirectory (Join-Path $stage.FullName 'Executables\AtlasModules\Logs\install')
        foreach ($phase in @('capture', 'run')) {
            Add-EvidenceFile (Join-Path $stage.FullName "Executables\AtlasModules\Logs\install-$phase.log")
        }
    }
}
catch { [void]$report.AppendLine("Staging unavailable: $($_.Exception.Message)") }

$logs = Join-Path $AppRoot 'Logs'
Assert-EvidencePath $logs
[void][IO.Directory]::CreateDirectory($logs)
$outputPath = Join-Path $logs ("install-evidence-{0}-{1}.log" -f [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N'))
[IO.File]::WriteAllText($outputPath, $report.ToString(), [Text.UTF8Encoding]::new($false))
Write-Output "Evidence saved to $outputPath"
Write-Output 'Now use Export diagnostics in Atlas Manager and send the new ZIP. The export redacts this local log; send the ZIP rather than the raw log.'
