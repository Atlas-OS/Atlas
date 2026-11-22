<#
.SYNOPSIS
    Installs a built Atlas package on a Hyper-V lab VM and verifies the result.
.DESCRIPTION
    One lab run is the end-to-end check that CI can't do on a hosted runner:

      1. Restore the VM to its checkpoint, start it and wait for the lab account's
         interactive session.
      2. Copy the extracted package and the state-dump tool into the guest over
         PowerShell Direct and take a baseline dump of registry, services and tasks.
      3. Run the Atlas front door (Scripts\Entry\Install-Atlas.ps1) unattended with the
         requested options, from Windows PowerShell 5.1 in the lab account's session.
      4. Unless the front door stopped before installing anything, restart, run the health
         check (Scripts\Entry\Test-AtlasHealth.ps1 -Json) over PowerShell Direct, take a
         second dump and diff it against the baseline.
      5. Collect the front door's output, the Atlas logs, the health report and the state
         diff into -OutputPath.

    PowerShell Direct runs commands in session 0, which the front door refuses: Windows
    and Microsoft Store preparation and the install user belong to the signed-in session.
    So step 3 registers a one-time scheduled task with an interactive principal for the
    lab account at the highest run level. Windows runs it only in that account's
    signed-in session, elevated, as Atlas Manager runs the front door. A runner script in
    the guest records the session, the front door's output and its exit code under
    C:\AtlasLab. The run polls for the result, collects it and unregisters the task.

    The run fails when the install exits non-zero, when the health check reports drift
    right after a fresh install, or when the guest never comes back.

    Prerequisites on the host:
      - Hyper-V with its PowerShell module, and PowerShell 7.
      - An elevated prompt, or membership of the Hyper-V Administrators group.
      - 7-Zip or NanaZip, to extract -PackagePath.

    Prerequisites in the VM, which the checkpoint must capture:
      - A Windows build that atlas.json lists in supportedBuilds, with internet access.
      - A local administrator account other than the built-in Administrator, which the
        front door refuses, signed in. Pass that account as -Credential.
      - Windows Update and Microsoft Store with nothing left to install.
      - The four Windows Security protection switches off and no other antivirus app, as
        the package's requirements demand.
      - A standard checkpoint, which keeps the running session. A production checkpoint
        starts the VM at the sign-in screen, so the run stops unless the account signs in
        automatically.

    Once Windows Update or Microsoft Store offers something new, the front door exits 5
    and the run stops: install the updates in the VM, then take the checkpoint again.
.PARAMETER VMName
    Hyper-V virtual machine name.
.PARAMETER CheckpointName
    Checkpoint to restore before the run.
.PARAMETER Credential
    The local administrator account that's signed in at the checkpoint. PowerShell Direct
    signs in with it, and the front door runs as it.
.PARAMETER PackagePath
    An .atlaspkg built by tools\build\Build-Package.ps1 without -LocalTest: LocalTest builds
    list no supportedBuilds, so the front door refuses them. Extracted locally with 7-Zip.
.PARAMETER ArchiveKey
    The ZIP password the package was built with. Build-Package.ps1 uses the public
    password 'atlasos', the default here; pass an empty string for a build made with
    -NoPassword.
.PARAMETER ExtractedRoot
    An already extracted package root (contains atlas.json and Executables). Either
    this or -PackagePath is required.
.PARAMETER Option
    The option ids from atlas.json passed to the front door. Defaults to the recommended set.
.PARAMETER OutputPath
    Directory for logs, reports and dumps. Defaults to lab-output\<timestamp>.
.PARAMETER BootTimeoutSeconds
    How long to wait, after each start, for the guest to accept a PowerShell Direct
    session, and after the restore for the lab account's interactive session.
.PARAMETER InstallTimeoutSeconds
    How long the front door may run before the lab run stops it.
.PARAMETER Keep
    Leave the VM running after the run instead of turning it off.
.EXAMPLE
    pwsh tools/build/Build-Package.ps1 -FileName 'Atlas Lab' -ReplaceExisting -NoExplorer
    pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
        -Credential (Get-Credential AtlasLab) -PackagePath 'package\Atlas Lab.atlaspkg'

    Builds a full package and runs the lab on a developer's Hyper-V host.
.EXAMPLE
    pwsh tools/lab/Invoke-AtlasLabRun.ps1 -VMName AtlasLab -CheckpointName clean `
        -Credential $credential -ExtractedRoot $extracted -Option defender-enable,
        mitigations-default, auto-updates-disable, keyboard-single -Keep

    Installs an extracted package with other options and leaves the VM running.
.NOTES
    Exit codes:
      0  Verified.
      1  The install or the verification failed: the front door failed or didn't finish
         within -InstallTimeoutSeconds, or the health check reported drift or couldn't run.
      2  Lab setup failed: a tool, package or setting is missing, the VM, its session or
         the task never came up, or the VM doesn't meet the prerequisites, so the front
         door exited 3 (not elevated) or 5 (preparation not current).
#>
#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'Package')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CheckpointName,

    [Parameter(Mandatory = $true)]
    [pscredential]$Credential,

    [Parameter(Mandatory = $true, ParameterSetName = 'Package')]
    [ValidateNotNullOrEmpty()]
    [string]$PackagePath,

    [Parameter(ParameterSetName = 'Package')]
    [AllowEmptyString()]
    [string]$ArchiveKey = 'atlasos',

    [Parameter(Mandatory = $true, ParameterSetName = 'Extracted')]
    [ValidateNotNullOrEmpty()]
    [string]$ExtractedRoot,

    [ValidatePattern('^[a-z0-9-]+$')]
    [string[]]$Option = @('defender-enable', 'mitigations-default', 'auto-updates-default', 'keyboard-shortcuts'),

    [string]$OutputPath,

    [ValidateRange(1, 86400)]
    [int]$BootTimeoutSeconds = 600,

    [ValidateRange(1, 604800)]
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
Import-Module (Join-Path -Path $repoRoot -ChildPath 'tools\build\AtlasBuild\AtlasBuild.psd1') -Force

# The front door's task and the files its runner writes in the guest. The run copies the
# three files to install-session.json, install.log and install-result.json.
$taskName = 'Atlas lab front door'
$runnerPath = "$guestRoot\Invoke-FrontDoorTask.ps1"
$startedPath = "$guestRoot\front-door-session.json"
$frontDoorLogPath = "$guestRoot\front-door.log"
$resultPath = "$guestRoot\front-door-result.json"
# How long Windows may take to start the task once it's asked to.
$taskStartSeconds = 120
$pollSeconds = 10

function Write-LabStep {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[lab] $Message"
}

function Expand-AtlasPackage {
    <#
    .SYNOPSIS
        Extracts an .atlaspkg (an encrypted ZIP) with 7-Zip into a temp directory.
    #>
    param([Parameter(Mandatory = $true)][string]$Path, [AllowEmptyString()][string]$Key)

    $target = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ('atlas-lab-' + [guid]::NewGuid().ToString('N'))
    $arguments = @('x', '-y', '-bso0', '-bsp0', "-o$target")
    if ($Key) { $arguments += "-p$Key" }
    $arguments += $Path
    Invoke-SevenZip -SevenZipPath (Resolve-SevenZip) -ArgumentList $arguments `
        -ErrorContext "Extracting '$Path'" | Out-Null
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

function Wait-GuestInteractiveUser {
    <#
    .SYNOPSIS
        Waits until the lab account has an interactive session in the guest and returns
        the account as Windows names it, its SID and the session ID.
    .DESCRIPTION
        The account counts as signed in once File Explorer runs as it in a session other
        than 0. Refuses the built-in Administrator, which the front door refuses too.
    #>
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    # A local account can be given as name, .\name or COMPUTER\name.
    $name = ($UserName -split '\\')[-1]
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $signedIn = Invoke-Command -Session $Session -ScriptBlock {
            Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
                Where-Object { $_.SessionId -gt 0 } |
                ForEach-Object {
                    $owner = Invoke-CimMethod -InputObject $_ -MethodName GetOwner
                    if ($owner.ReturnValue -eq 0 -and $owner.User -eq $using:name) {
                        $account = "$($owner.Domain)\$($owner.User)"
                        [pscustomobject]@{
                            Account   = $account
                            Sid       = ([Security.Principal.NTAccount]$account).Translate([Security.Principal.SecurityIdentifier]).Value
                            SessionId = [int]$_.SessionId
                        }
                    }
                } |
                Select-Object -First 1
        }
        if ($signedIn) {
            if ($signedIn.Sid -match '-500$') {
                throw "The checkpoint is signed in as the built-in Administrator, which the front door refuses. Sign in with another local administrator account and take the checkpoint again."
            }
            return $signedIn
        }
        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)
    throw ("'$UserName' didn't sign in to the guest within $TimeoutSeconds seconds. Take a standard checkpoint " +
        'while that account is signed in, or have it sign in automatically.')
}

function Invoke-GuestPowerShell {
    <#
    .SYNOPSIS
        Runs a script file, or a command, with Windows PowerShell 5.1 over PowerShell
        Direct, in session 0, and returns its exit code with the captured output.
    #>
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true, ParameterSetName = 'File')][string]$ScriptPath,
        [Parameter(ParameterSetName = 'File')][string[]]$Arguments = @(),
        [Parameter(Mandatory = $true, ParameterSetName = 'Command')][string]$Command,
        [int]$TimeoutSeconds = 600
    )

    if ($PSCmdlet.ParameterSetName -eq 'Command') {
        $hostArguments = @('-Command', $Command)
        $description = "Guest command '$Command'"
    }
    else {
        $hostArguments = @('-File', $ScriptPath) + @($Arguments)
        $description = "Guest script '$ScriptPath'"
    }
    $job = Invoke-Command -Session $Session -AsJob -ScriptBlock {
        $powershell = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
        $guestArguments = @($using:hostArguments)
        $output = & $powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass @guestArguments 2>&1 | ForEach-Object { "$_" }
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
    }
    if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
        Stop-Job -Job $job
        throw "$description did not finish within $TimeoutSeconds seconds."
    }
    return Receive-Job -Job $job
}

function Get-FrontDoorCommand {
    <#
    .SYNOPSIS
        The Windows PowerShell command that runs the front door unattended with the given
        options and exits with its exit code.
    .DESCRIPTION
        -File passes each argument as one string, which cannot carry the front door's
        [string[]] option list, so the lab runs a command with an array literal, as Atlas
        Manager does. A call that never sets an exit code, such as one whose parameters
        are rejected, counts as 1.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        # Single quotes are enough for names of this shape.
        [Parameter(Mandatory = $true)][ValidatePattern('^[a-z0-9-]+$')][string[]]$Option
    )

    $optionList = (@($Option) | ForEach-Object { "'$_'" }) -join ','
    return (
        'try {{ & ''{0}'' -Unattended -Option @({1}); $atlasExit = $LASTEXITCODE }} ' +
        'catch {{ [Console]::Error.WriteLine($_.Exception.Message); $atlasExit = 1 }}; ' +
        'if ($null -eq $atlasExit) {{ $atlasExit = 1 }}; exit $atlasExit'
    ) -f ($ScriptPath -replace "'", "''"), $optionList
}

function Get-LabTaskRunner {
    <#
    .SYNOPSIS
        The Windows PowerShell script the front door's scheduled task runs in the guest.
    .DESCRIPTION
        The runner writes the account, session and elevation it runs with to -StartedPath.
        It then runs -Command in a child powershell.exe, as Atlas Manager does, because
        only a child's standard output and error can be captured. Each line goes to
        -LogPath as it arrives, so a run that's stopped keeps what it printed. Last, the
        exit code goes to -ResultPath through a temporary file and a rename, so a reader
        never sees half a result. A runner that fails itself still writes exit code 1.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$StartedPath,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$ResultPath
    )

    $runner = @'
$ErrorActionPreference = 'Stop'
function ConvertFrom-LabValue([string]$Value) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value)) }
$command = ConvertFrom-LabValue '@COMMAND@'
$startedPath = ConvertFrom-LabValue '@STARTED@'
$logPath = ConvertFrom-LabValue '@LOG@'
$resultPath = ConvertFrom-LabValue '@RESULT@'
$utf8 = New-Object Text.UTF8Encoding($false)
$exitCode = 1
$detail = $null
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $started = [ordered]@{
        user      = $identity.Name
        sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
        elevated  = (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        started   = (Get-Date).ToString('o')
    }
    [IO.File]::WriteAllText($startedPath, (ConvertTo-Json -InputObject $started), $utf8)
    $powershell = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
    $writer = New-Object IO.StreamWriter($logPath, $false, $utf8)
    $writer.AutoFlush = $true
    try {
        # Windows PowerShell turns redirected native stderr into error records.
        $ErrorActionPreference = 'Continue'
        & $powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $command 2>&1 |
            ForEach-Object { $writer.WriteLine("$_") }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = 'Stop'
        $writer.Dispose()
    }
}
catch {
    $detail = $_.Exception.Message
    $exitCode = 1
}
finally {
    if ($null -eq $exitCode) { $exitCode = 1 }
    $result = [ordered]@{ exitCode = $exitCode; detail = $detail; finished = (Get-Date).ToString('o') }
    [IO.File]::WriteAllText("$resultPath.tmp", (ConvertTo-Json -InputObject $result), $utf8)
    Move-Item -LiteralPath "$resultPath.tmp" -Destination $resultPath -Force
}
exit $exitCode
'@
    # Base64 carries each value into the script without any quoting rules.
    $values = [ordered]@{
        '@COMMAND@' = $Command
        '@STARTED@' = $StartedPath
        '@LOG@'     = $LogPath
        '@RESULT@'  = $ResultPath
    }
    foreach ($placeholder in $values.Keys) {
        $runner = $runner.Replace($placeholder, [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($values[$placeholder])))
    }
    return $runner
}

function Get-FrontDoorOutcome {
    <#
    .SYNOPSIS
        What the front door's exit code means for the lab run.
    .DESCRIPTION
        Returns the run's exit code, whether anything was installed for the restart and
        health check to verify, and a line for the log. Exit codes 2, 3 and 5 mean the
        install never started. 3 (not elevated) and 5 (preparation not current) come from
        a VM that doesn't meet the prerequisites, so they're lab setup failures. $null
        means the front door didn't finish in time; what it changed is still verified.
    #>
    param(
        [AllowNull()][Nullable[int]]$ExitCode,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    if ($null -eq $ExitCode) {
        return [pscustomobject]@{ LabExitCode = 1; Verify = $true; Message = "The front door didn't finish within $TimeoutSeconds seconds; see install.log." }
    }
    if ($ExitCode -eq 0) {
        return [pscustomobject]@{ LabExitCode = 0; Verify = $true; Message = 'The front door installed Atlas.' }
    }
    if ($ExitCode -eq 2) {
        return [pscustomobject]@{ LabExitCode = 1; Verify = $false; Message = "The front door exited 2: a requirement isn't met, so nothing was installed. install.log lists each check." }
    }
    if ($ExitCode -eq 3) {
        return [pscustomobject]@{ LabExitCode = 2; Verify = $false; Message = "The front door exited 3: it didn't run elevated. The lab account must be an administrator." }
    }
    if ($ExitCode -eq 5) {
        return [pscustomobject]@{ LabExitCode = 2; Verify = $false; Message = 'The front door exited 5: Windows Update or Microsoft Store has updates the checkpoint lacks. Install them in the VM, then take the checkpoint again.' }
    }
    return [pscustomobject]@{ LabExitCode = 1; Verify = $true; Message = "The front door exited $ExitCode; see install.log." }
}

function Copy-GuestItem {
    <#
    .SYNOPSIS
        Copies a file or folder from the guest to -Destination when it exists.
    #>
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $exists = Invoke-Command -Session $Session -ScriptBlock { Test-Path -LiteralPath $using:Path }
    if ($exists) {
        Copy-Item -Path $Path -Destination $Destination -FromSession $Session -Recurse
    }
}

# Guest commands for the front door's task, run over PowerShell Direct.
$registerTask = {
    param($TaskName, $UserId, $RunnerPath, $LimitSeconds)
    $powershell = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
    $action = New-ScheduledTaskAction -Execute $powershell `
        -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}"' -f $RunnerPath)
    # Interactive: only in the account's signed-in session. Highest: the elevated token.
    $principal = New-ScheduledTaskPrincipal -UserId $UserId -LogonType Interactive -RunLevel Highest
    # Tasks run below normal priority unless told otherwise; 4 is normal, as when Atlas
    # Manager starts the front door. The time limit backs up the host's own timeout.
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew -Priority 4 -ExecutionTimeLimit (New-TimeSpan -Seconds $LimitSeconds)
    Register-ScheduledTask -TaskName $TaskName -TaskPath '\' -Action $action -Principal $principal `
        -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName -TaskPath '\'
}
$getTaskStatus = {
    param($TaskName, $StartedPath, $ResultPath)
    # The state is read before the result, so a task that's no longer running and still
    # has no result really ended without one.
    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath '\' -ErrorAction SilentlyContinue
    $state = if ($task) { [string]$task.State } else { 'Missing' }
    $lastResult = if ($task) { [long](Get-ScheduledTaskInfo -InputObject $task).LastTaskResult } else { 0 }
    [pscustomobject]@{
        State      = $state
        LastResult = $lastResult
        Started    = Test-Path -LiteralPath $StartedPath
        Finished   = Test-Path -LiteralPath $ResultPath
    }
}
$removeTask = {
    param($TaskName)
    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath '\' -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.State -eq 'Running') { Stop-ScheduledTask -InputObject $task }
        Unregister-ScheduledTask -InputObject $task -Confirm:$false
    }
}

$exitCode = 0
$session = $null
$extractedTemp = $null
try {
    # Before the VM is touched, so a missing tool or a wrong package fails in seconds.
    if ($PSCmdlet.ParameterSetName -eq 'Package') {
        Write-LabStep "Extracting '$PackagePath'."
        $extractedTemp = Expand-AtlasPackage -Path $PackagePath -Key $ArchiveKey
        $ExtractedRoot = $extractedTemp
    }
    foreach ($required in 'atlas.json', 'Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1') {
        if (-not (Test-Path -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath $required) -PathType Leaf)) {
            throw "'$ExtractedRoot' is not an extracted Atlas package: '$required' is missing."
        }
    }
    $manifest = Get-Content -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath 'atlas.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $supportedBuilds = $manifest.PSObject.Properties['supportedBuilds']
    if ($null -eq $supportedBuilds -or @($supportedBuilds.Value).Count -eq 0) {
        throw "'$ExtractedRoot' is a LocalTest build: its atlas.json lists no supportedBuilds, so the front door would refuse it. Build the package without -LocalTest."
    }

    Write-LabStep "Restoring '$VMName' to checkpoint '$CheckpointName'."
    $checkpoint = Get-VMCheckpoint -VMName $VMName -Name $CheckpointName -ErrorAction Stop
    if ((Get-VM -Name $VMName).State -ne 'Off') {
        Stop-VM -Name $VMName -TurnOff -Force
    }
    Restore-VMCheckpoint -VMCheckpoint $checkpoint -Confirm:$false
    Start-VM -Name $VMName
    $session = Wait-GuestSession -Name $VMName -GuestCredential $Credential -TimeoutSeconds $BootTimeoutSeconds
    $labUser = Wait-GuestInteractiveUser -Session $session -UserName $Credential.UserName -TimeoutSeconds $BootTimeoutSeconds
    Write-LabStep "$($labUser.Account) is signed in to session $($labUser.SessionId)."

    Write-LabStep 'Copying the Atlas package and tools into the guest.'
    Invoke-Command -Session $session -ScriptBlock {
        if (Test-Path -LiteralPath $using:guestRoot) { Remove-Item -LiteralPath $using:guestRoot -Recurse -Force }
        New-Item -Path $using:guestRoot -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $ExtractedRoot -Destination (Join-Path -Path $guestRoot -ChildPath 'package') -ToSession $session -Recurse
    Copy-Item -Path $compareTool -Destination (Join-Path -Path $guestRoot -ChildPath 'Compare-SystemState.ps1') -ToSession $session

    Write-LabStep 'Taking the baseline state dump.'
    $baseline = Invoke-GuestPowerShell -Session $session -ScriptPath "$guestRoot\Compare-SystemState.ps1" -Arguments @('-Mode', 'Dump', '-OutputPath', "$guestRoot\baseline.json")
    if ($baseline.ExitCode -ne 0) {
        throw "Baseline dump failed: $($baseline.Output -join "`n")"
    }

    Write-LabStep "Installing Atlas with options $($Option -join ', '), in $($labUser.Account)'s session."
    $frontDoorCommand = Get-FrontDoorCommand -Option $Option `
        -ScriptPath "$guestRoot\package\Executables\AtlasModules\Scripts\Entry\Install-Atlas.ps1"
    $runner = Get-LabTaskRunner -Command $frontDoorCommand -StartedPath $startedPath -LogPath $frontDoorLogPath -ResultPath $resultPath
    Invoke-Command -Session $session -ScriptBlock {
        [IO.File]::WriteAllText($using:runnerPath, $using:runner, (New-Object Text.UTF8Encoding($true)))
    }
    $frontDoorExit = $null
    try {
        Invoke-Command -Session $session -ScriptBlock $registerTask `
            -ArgumentList $taskName, $labUser.Account, $runnerPath, ($InstallTimeoutSeconds + 600)
        $startDeadline = (Get-Date).AddSeconds($taskStartSeconds)
        $deadline = (Get-Date).AddSeconds($InstallTimeoutSeconds)
        $finished = $false
        # A task that never starts, or ends without a result, fails the setup once what it
        # left behind is collected.
        $taskProblem = $null
        while (-not $finished) {
            Start-Sleep -Seconds $pollSeconds
            $timedOut = (Get-Date) -gt $deadline
            try {
                $status = Invoke-Command -Session $session -ScriptBlock $getTaskStatus `
                    -ArgumentList $taskName, $startedPath, $resultPath
            }
            catch {
                if ($timedOut) { break }
                Write-LabStep "Lost the PowerShell Direct session ($($_.Exception.Message)); opening another."
                Remove-PSSession -Session $session -ErrorAction SilentlyContinue
                $session = $null
                $session = Wait-GuestSession -Name $VMName -GuestCredential $Credential -TimeoutSeconds $BootTimeoutSeconds
                continue
            }
            $finished = $status.Finished
            if ($finished) {
                break
            }
            if (-not $status.Started -and $status.State -ne 'Running' -and (Get-Date) -gt $startDeadline) {
                $taskProblem = ("The front door task didn't start in $($labUser.Account)'s session within $taskStartSeconds seconds " +
                    "(task state $($status.State), last result 0x{0:X8})." -f $status.LastResult)
                break
            }
            if ($status.Started -and $status.State -ne 'Running') {
                $taskProblem = ("The front door task ended without writing a result (task state $($status.State), " +
                    'last result 0x{0:X8}).' -f $status.LastResult)
                break
            }
            if ($timedOut) {
                break
            }
        }
        if (-not $finished -and -not $taskProblem) {
            # Stopped before collection: the runner holds its log open while it runs.
            Write-LabStep "Stopping the front door after $InstallTimeoutSeconds seconds."
            try {
                Invoke-Command -Session $session -ScriptBlock $removeTask -ArgumentList $taskName
            }
            catch {
                Write-LabStep "Couldn't stop the front door task: $($_.Exception.Message)"
            }
        }

        Copy-GuestItem -Session $session -Path $startedPath -Destination (Join-Path -Path $OutputPath -ChildPath 'install-session.json')
        Copy-GuestItem -Session $session -Path $frontDoorLogPath -Destination (Join-Path -Path $OutputPath -ChildPath 'install.log')
        Copy-GuestItem -Session $session -Path $resultPath -Destination (Join-Path -Path $OutputPath -ChildPath 'install-result.json')
        $sessionRecord = Join-Path -Path $OutputPath -ChildPath 'install-session.json'
        if (Test-Path -LiteralPath $sessionRecord) {
            $ran = Get-Content -LiteralPath $sessionRecord -Raw | ConvertFrom-Json
            Write-LabStep "The front door ran as $($ran.user) in session $($ran.sessionId), elevated: $($ran.elevated)."
        }
        if ($taskProblem) {
            throw $taskProblem
        }
        $resultRecord = Join-Path -Path $OutputPath -ChildPath 'install-result.json'
        if ($finished -and (Test-Path -LiteralPath $resultRecord)) {
            $result = Get-Content -LiteralPath $resultRecord -Raw | ConvertFrom-Json
            if ($result.detail) {
                Write-LabStep "The task runner reported: $($result.detail)"
            }
            $frontDoorExit = [int]$result.exitCode
        }
    }
    finally {
        if ($session) {
            try {
                Invoke-Command -Session $session -ScriptBlock $removeTask -ArgumentList $taskName
            }
            catch {
                Write-LabStep "Couldn't unregister the front door task: $($_.Exception.Message)"
            }
        }
    }

    $outcome = Get-FrontDoorOutcome -ExitCode $frontDoorExit -TimeoutSeconds $InstallTimeoutSeconds
    Write-LabStep $outcome.Message
    $exitCode = [Math]::Max($exitCode, $outcome.LabExitCode)

    if ($outcome.Verify) {
        Write-LabStep 'Restarting the guest.'
        Remove-PSSession -Session $session
        $session = $null
        Restart-VM -Name $VMName -Type Reboot -Force -Wait -For Heartbeat -Timeout $BootTimeoutSeconds
        $session = Wait-GuestSession -Name $VMName -GuestCredential $Credential -TimeoutSeconds $BootTimeoutSeconds

        # Over PowerShell Direct: the check reads machine state and the lab account's own
        # registry hive, which needs no interactive session.
        Write-LabStep 'Running the health check.'
        $health = Invoke-GuestPowerShell -Session $session -ScriptPath 'C:\Windows\AtlasModules\Scripts\Entry\Test-AtlasHealth.ps1' -Arguments @('-Json')
        $health.Output | Set-Content -LiteralPath (Join-Path -Path $OutputPath -ChildPath 'health.json')
        switch ($health.ExitCode) {
            0 { Write-LabStep 'Health check: no drift.' }
            1 { Write-LabStep 'Health check reported drift immediately after install; see health.json.'; $exitCode = [Math]::Max($exitCode, 1) }
            default { Write-LabStep "Health check could not run (exit code $($health.ExitCode))."; $exitCode = [Math]::Max($exitCode, 1) }
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
    }

    Write-LabStep 'Collecting Atlas logs.'
    Copy-GuestItem -Session $session -Path 'C:\Windows\AtlasModules\Logs' -Destination (Join-Path -Path $OutputPath -ChildPath 'Logs')
    Copy-GuestItem -Session $session -Path 'C:\Windows\AtlasOS\state.json' -Destination (Join-Path -Path $OutputPath -ChildPath 'state.json')
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
