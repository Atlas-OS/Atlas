<#
.SYNOPSIS
    Installs a built playbook on a Hyper-V lab VM and verifies the result.
.DESCRIPTION
    One lab run is the end-to-end check that CI cannot do on a hosted runner:

      1. Restore the VM to a clean checkpoint and boot it.
      2. Copy the extracted playbook and the state-dump tool into the guest over
         PowerShell Direct and take a baseline dump of registry, services and tasks.
      3. Run the Atlas front door (Scripts\Entry\Install-Atlas.ps1) unattended with the
         requested options, from Windows PowerShell 5.1 inside the guest.
      4. Reboot, run the health check (Scripts\Entry\Test-AtlasHealth.ps1 -Json), take a
         second dump and diff it against the baseline.
      5. Collect the Atlas logs, the health report and the state diff into -OutputPath.

    The run fails when the install exits non-zero, when the health check reports drift
    right after a fresh install, or when the guest never comes back.

    Requirements on the host: Hyper-V with the Hyper-V PowerShell module, a VM with a
    supported Windows build, PowerShell Direct (the guest runs Windows 10 1607 or later)
    and a local administrator credential for the guest. The checkpoint must exist before
    the first run; take it after Windows setup completes and before Atlas is installed.
.PARAMETER VMName
    Hyper-V virtual machine name.
.PARAMETER CheckpointName
    Checkpoint to restore before the run.
.PARAMETER Credential
    Local administrator credential inside the guest.
.PARAMETER PlaybookPath
    An .apbx built by tools\build\Build-Playbook.ps1. Extracted locally with 7-Zip.
.PARAMETER ArchiveKey
    The zip key the playbook was built with. AME Wizard playbooks all use the same
    published key; pass an empty string for a build made with -NoPassword.
.PARAMETER ExtractedRoot
    An already extracted playbook root (contains playbook.conf and Executables). Either
    this or -PlaybookPath is required.
.PARAMETER Option
    FeaturePage options passed to the front door. Defaults to the recommended set.
.PARAMETER OutputPath
    Directory for logs, reports and dumps. Defaults to lab-output\<timestamp>.
.PARAMETER Keep
    Leave the VM running after the run instead of turning it off.
.NOTES
    Exit codes: 0 verified, 1 install or verification failed, 2 lab setup failed.
#>
#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'Apbx')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CheckpointName,

    [Parameter(Mandatory = $true)]
    [pscredential]$Credential,

    [Parameter(Mandatory = $true, ParameterSetName = 'Apbx')]
    [ValidateNotNullOrEmpty()]
    [string]$PlaybookPath,

    [Parameter(ParameterSetName = 'Apbx')]
    [AllowEmptyString()]
    [string]$ArchiveKey = 'malte',

    [Parameter(Mandatory = $true, ParameterSetName = 'Extracted')]
    [ValidateNotNullOrEmpty()]
    [string]$ExtractedRoot,

    [ValidatePattern('^[a-z0-9-]+$')]
    [string[]]$Option = @('defender-enable', 'mitigations-default', 'auto-updates-default'),

    [string]$OutputPath,

    [int]$BootTimeoutSeconds = 600,

    [int]$InstallTimeoutSeconds = 7200,

    [switch]$Keep
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $repoRoot -ChildPath ('lab-output\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
$transcript = Join-Path -Path $OutputPath -ChildPath 'lab-run.log'
Start-Transcript -Path $transcript -Force | Out-Null

$guestRoot = 'C:\AtlasLab'
$compareTool = Join-Path -Path $repoRoot -ChildPath 'tools\dev\Compare-SystemState.ps1'

function Write-LabStep {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[lab] $Message"
}

function Expand-Playbook {
    <#
    .SYNOPSIS
        Extracts an .apbx (a keyed zip) with 7-Zip into a temp directory.
    #>
    param([Parameter(Mandatory = $true)][string]$Path, [AllowEmptyString()][string]$Key)

    $sevenZip = Get-Command -Name '7z' -ErrorAction SilentlyContinue
    if (-not $sevenZip) {
        throw '7-Zip (7z) is required on PATH to extract the playbook.'
    }
    $target = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ('atlas-lab-' + [guid]::NewGuid().ToString('N'))
    $arguments = @('x', '-y', "-o$target")
    if ($Key) { $arguments += "-p$Key" }
    $arguments += $Path
    & $sevenZip.Source @arguments | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip failed to extract '$Path' (exit code $LASTEXITCODE)."
    }
    return $target
}

function Wait-GuestSession {
    <#
    .SYNOPSIS
        Waits for PowerShell Direct to accept a session and returns it.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][pscredential]$GuestCredential,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $session = New-PSSession -VMName $Name -Credential $GuestCredential -ErrorAction Stop
            $ready = Invoke-Command -Session $session -ScriptBlock {
                (Get-Service -Name 'Winmgmt').Status -eq 'Running'
            }
            if ($ready) {
                return $session
            }
            Remove-PSSession -Session $session
        }
        catch {
            Start-Sleep -Seconds 5
        }
    }
    throw "The guest '$Name' did not accept a PowerShell Direct session within $TimeoutSeconds seconds."
}

function Invoke-GuestPowerShell {
    <#
    .SYNOPSIS
        Runs a script file with Windows PowerShell 5.1 inside the guest, as the payload
        would be run by a user, and returns its exit code with the captured output.
    #>
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 600
    )

    $guestArguments = @($Arguments)
    $job = Invoke-Command -Session $Session -AsJob -ScriptBlock {
        $powershell = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
        $scriptArguments = @($using:guestArguments)
        $output = & $powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $using:ScriptPath @scriptArguments 2>&1 | ForEach-Object { "$_" }
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
    }
    if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
        Stop-Job -Job $job
        throw "Guest script '$ScriptPath' did not finish within $TimeoutSeconds seconds."
    }
    return Receive-Job -Job $job
}

$exitCode = 0
$session = $null
$extractedTemp = $null
try {
    Write-LabStep "Restoring '$VMName' to checkpoint '$CheckpointName'."
    $checkpoint = Get-VMCheckpoint -VMName $VMName -Name $CheckpointName -ErrorAction Stop
    if ((Get-VM -Name $VMName).State -ne 'Off') {
        Stop-VM -Name $VMName -TurnOff -Force
    }
    Restore-VMCheckpoint -VMCheckpoint $checkpoint -Confirm:$false
    Start-VM -Name $VMName
    $session = Wait-GuestSession -Name $VMName -GuestCredential $Credential -TimeoutSeconds $BootTimeoutSeconds

    if ($PSCmdlet.ParameterSetName -eq 'Apbx') {
        Write-LabStep "Extracting '$PlaybookPath'."
        $extractedTemp = Expand-Playbook -Path $PlaybookPath -Key $ArchiveKey
        $ExtractedRoot = $extractedTemp
    }
    foreach ($required in 'playbook.conf', 'Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1') {
        if (-not (Test-Path -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath $required) -PathType Leaf)) {
            throw "'$ExtractedRoot' is not an extracted playbook: '$required' is missing."
        }
    }

    Write-LabStep 'Copying the playbook and tools into the guest.'
    Invoke-Command -Session $session -ScriptBlock {
        if (Test-Path -LiteralPath $using:guestRoot) { Remove-Item -LiteralPath $using:guestRoot -Recurse -Force }
        New-Item -Path $using:guestRoot -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $ExtractedRoot -Destination (Join-Path -Path $guestRoot -ChildPath 'playbook') -ToSession $session -Recurse
    Copy-Item -Path $compareTool -Destination (Join-Path -Path $guestRoot -ChildPath 'Compare-SystemState.ps1') -ToSession $session

    Write-LabStep 'Taking the baseline state dump.'
    $baseline = Invoke-GuestPowerShell -Session $session -ScriptPath "$guestRoot\Compare-SystemState.ps1" -Arguments @('-Mode', 'Dump', '-OutputPath', "$guestRoot\baseline.json")
    if ($baseline.ExitCode -ne 0) {
        throw "Baseline dump failed: $($baseline.Output -join "`n")"
    }

    Write-LabStep "Installing Atlas with options: $($Option -join ', ')."
    $install = Invoke-GuestPowerShell -Session $session -TimeoutSeconds $InstallTimeoutSeconds `
        -ScriptPath "$guestRoot\playbook\Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1" `
        -Arguments (@('-Unattended', '-Option') + @($Option -join ','))
    $install.Output | Set-Content -LiteralPath (Join-Path -Path $OutputPath -ChildPath 'install.log')
    if ($install.ExitCode -ne 0) {
        Write-LabStep "Install exited with code $($install.ExitCode); see install.log."
        $exitCode = 1
    }

    Write-LabStep 'Restarting the guest.'
    Remove-PSSession -Session $session
    $session = $null
    Restart-VM -Name $VMName -Force -Wait -For Heartbeat -Timeout $BootTimeoutSeconds
    $session = Wait-GuestSession -Name $VMName -GuestCredential $Credential -TimeoutSeconds $BootTimeoutSeconds

    Write-LabStep 'Running the health check.'
    $health = Invoke-GuestPowerShell -Session $session -ScriptPath 'C:\Windows\AtlasModules\Scripts\Entry\Test-AtlasHealth.ps1' -Arguments @('-Json')
    $health.Output | Set-Content -LiteralPath (Join-Path -Path $OutputPath -ChildPath 'health.json')
    switch ($health.ExitCode) {
        0 { Write-LabStep 'Health check: no drift.' }
        1 { Write-LabStep 'Health check reported drift immediately after install; see health.json.'; $exitCode = 1 }
        default { Write-LabStep "Health check could not run (exit code $($health.ExitCode))."; $exitCode = 1 }
    }

    Write-LabStep 'Taking the post-install dump and diffing it against the baseline.'
    $candidate = Invoke-GuestPowerShell -Session $session -ScriptPath "$guestRoot\Compare-SystemState.ps1" -Arguments @('-Mode', 'Dump', '-OutputPath', "$guestRoot\candidate.json")
    if ($candidate.ExitCode -eq 0) {
        $diff = Invoke-GuestPowerShell -Session $session -ScriptPath "$guestRoot\Compare-SystemState.ps1" -Arguments @('-Mode', 'Compare', '-Baseline', "$guestRoot\baseline.json", '-Candidate', "$guestRoot\candidate.json")
        $diff.Output | Set-Content -LiteralPath (Join-Path -Path $OutputPath -ChildPath 'state-diff.txt')
        foreach ($dump in 'baseline.json', 'candidate.json') {
            Copy-Item -Path "$guestRoot\$dump" -Destination (Join-Path -Path $OutputPath -ChildPath $dump) -FromSession $session
        }
    }

    Write-LabStep 'Collecting Atlas logs.'
    $logs = Invoke-Command -Session $session -ScriptBlock { Test-Path -LiteralPath 'C:\Windows\AtlasModules\Logs' }
    if ($logs) {
        Copy-Item -Path 'C:\Windows\AtlasModules\Logs' -Destination (Join-Path -Path $OutputPath -ChildPath 'Logs') -FromSession $session -Recurse
    }
    $stateDocument = Invoke-Command -Session $session -ScriptBlock { Test-Path -LiteralPath 'C:\Windows\AtlasOS\state.json' }
    if ($stateDocument) {
        Copy-Item -Path 'C:\Windows\AtlasOS\state.json' -Destination (Join-Path -Path $OutputPath -ChildPath 'state.json') -FromSession $session
    }
}
catch {
    Write-LabStep "Lab setup failed: $($_.Exception.Message)"
    $exitCode = 2
}
finally {
    if ($session) {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
    }
    if (-not $Keep) {
        Stop-VM -Name $VMName -TurnOff -Force -ErrorAction SilentlyContinue
    }
    if ($extractedTemp -and (Test-Path -LiteralPath $extractedTemp)) {
        Remove-Item -LiteralPath $extractedTemp -Recurse -Force -ErrorAction SilentlyContinue
    }
    Stop-Transcript | Out-Null
}

Write-LabStep "Run finished with exit code $exitCode; output in '$OutputPath'."
exit $exitCode
