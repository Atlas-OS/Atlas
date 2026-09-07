[CmdletBinding()]
param(
    [ValidateSet('Minimal', 'Networking', 'CommandPrompt', 'Exit')]
    [string]$Mode,
    [switch]$LibraryOnly
)

Set-StrictMode -Version 3.0

function Get-AtlasSafeModePaths {
    $windows = [Environment]::GetFolderPath('Windows')
    if ([string]::IsNullOrWhiteSpace($windows)) {
        throw 'Windows did not provide its Windows directory.'
    }
    $recovery = Join-Path $windows 'AtlasOS\Recovery'
    [pscustomobject]@{
        BcdEdit       = Join-Path $windows 'System32\bcdedit.exe'
        Recovery      = $recovery
        ShellState    = Join-Path $recovery 'SafeMode.json'
        CbsRetryState = Join-Path $recovery 'CbsRetry.json'
    }
}

function Invoke-AtlasBcdEdit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $executable = (Get-AtlasSafeModePaths).BcdEdit
    if (![IO.File]::Exists($executable)) { throw "Required Windows executable '$executable' is missing." }
    $output = @(& $executable @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "bcdedit.exe failed with exit code $LASTEXITCODE`: $($output -join ' ')"
    }
    return $output
}

function Get-AtlasSafeBootConfiguration {
    $safeBoot = $null
    $alternatePresent = $false
    $alternateShell = $false
    foreach ($line in @(Invoke-AtlasBcdEdit -Arguments @('/enum', '{current}'))) {
        if ([string]$line -match '^\s*safeboot\s+(\S+)\s*$') {
            $safeBoot = switch ($Matches[1].ToLowerInvariant()) {
                'minimal' { 'minimal' }
                'network' { 'network' }
                default { throw "Unsupported current safeboot value '$($Matches[1])'." }
            }
        }
        elseif ([string]$line -match '^\s*safebootalternateshell\s+(\S+)\s*$') {
            $alternatePresent = $true
            $alternateShell = $Matches[1] -match '^(?i:yes|true)$'
        }
    }
    [pscustomobject]@{
        SafeBoot              = $safeBoot
        AlternateShellPresent = $alternatePresent
        AlternateShell        = $alternateShell
    }
}

function Get-AtlasWinlogonShell {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', $false)
    if ($null -eq $key) { throw 'The Winlogon registry key is missing.' }
    try {
        [pscustomobject]@{
            Value = [string]$key.GetValue('Shell', $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            Kind  = $key.GetValueKind('Shell').ToString()
        }
    }
    finally { $key.Dispose() }
}

function Set-AtlasWinlogonShell {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][ValidateSet('String', 'ExpandString')][string]$Kind
    )
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', $true)
    if ($null -eq $key) { throw 'The Winlogon registry key could not be opened for writing.' }
    try { $key.SetValue('Shell', $Value, [Microsoft.Win32.RegistryValueKind]::$Kind) }
    finally { $key.Dispose() }
}

function Read-AtlasSafeModeShellState {
    param([string]$Path = (Get-AtlasSafeModePaths).ShellState)
    if (![IO.File]::Exists($Path)) { return $null }
    $state = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($state.Version -ne 1 -or $state.Owner -cne 'AtlasOS' -or
        [string]::IsNullOrEmpty([string]$state.OriginalShell) -or
        [string]$state.OriginalKind -notin @('String', 'ExpandString')) {
        throw "Safe Mode shell state '$Path' is invalid."
    }
    return $state
}

function Write-AtlasSafeModeShellState {
    param([Parameter(Mandatory = $true)]$Shell, [string]$Path = (Get-AtlasSafeModePaths).ShellState)
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    $json = [ordered]@{
        Version = 1; Owner = 'AtlasOS'; OriginalShell = [string]$Shell.Value
        OriginalKind = [string]$Shell.Kind
    } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($false)))
}

function Clear-AtlasSafeModeShellState {
    param([string]$Path = (Get-AtlasSafeModePaths).ShellState)
    if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) }
}

function Test-AtlasCbsRetryPending {
    $path = (Get-AtlasSafeModePaths).CbsRetryState
    if (![IO.File]::Exists($path)) { return $false }
    $state = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($state.Version -ne 1 -or [string]$state.Phase -notin @('Pending', 'Armed')) {
        throw "CBS retry state '$path' is invalid."
    }
    return $true
}

function Restore-AtlasSafeModeShell {
    param($CurrentShell, $State)
    if ($null -eq $State) { return }
    if ([string]::Equals([string]$CurrentShell.Value, 'cmd.exe', [StringComparison]::OrdinalIgnoreCase)) {
        Set-AtlasWinlogonShell -Value ([string]$State.OriginalShell) -Kind ([string]$State.OriginalKind)
    }
    Clear-AtlasSafeModeShellState
}

function Set-AtlasSafeMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Minimal', 'Networking', 'CommandPrompt', 'Exit')]
        [string]$Mode,
        [switch]$AllowCbsRetryPending
    )

    if ($Mode -cne 'Exit' -and !$AllowCbsRetryPending -and (Test-AtlasCbsRetryPending)) {
        throw 'A CBS retry is pending; only Exit may change Safe Mode.'
    }
    $boot = Get-AtlasSafeBootConfiguration
    $shell = Get-AtlasWinlogonShell
    $shellState = Read-AtlasSafeModeShellState

    if ($Mode -ceq 'Exit') {
        if ($boot.AlternateShellPresent) {
            Invoke-AtlasBcdEdit -Arguments @('/deletevalue', '{current}', 'safebootalternateshell') | Out-Null
        }
        if ($null -ne $boot.SafeBoot) {
            Invoke-AtlasBcdEdit -Arguments @('/deletevalue', '{current}', 'safeboot') | Out-Null
        }
        Restore-AtlasSafeModeShell -CurrentShell $shell -State $shellState
        return
    }

    $target = if ($Mode -ceq 'Networking') { 'network' } else { 'minimal' }
    if ($boot.SafeBoot -cne $target) {
        Invoke-AtlasBcdEdit -Arguments @('/set', '{current}', 'safeboot', $target) | Out-Null
    }
    if ($Mode -ceq 'CommandPrompt') {
        if (!$boot.AlternateShellPresent -or !$boot.AlternateShell) {
            Invoke-AtlasBcdEdit -Arguments @('/set', '{current}', 'safebootalternateshell', 'yes') | Out-Null
        }
        if (![string]::Equals([string]$shell.Value, 'cmd.exe', [StringComparison]::OrdinalIgnoreCase)) {
            Write-AtlasSafeModeShellState -Shell $shell
            Set-AtlasWinlogonShell -Value 'cmd.exe' -Kind String
        }
    }
    else {
        if ($boot.AlternateShellPresent) {
            Invoke-AtlasBcdEdit -Arguments @('/deletevalue', '{current}', 'safebootalternateshell') | Out-Null
        }
        Restore-AtlasSafeModeShell -CurrentShell $shell -State $shellState
    }
}

if (!$LibraryOnly) {
    if ([string]::IsNullOrEmpty($Mode)) { throw 'Specify -Mode or use -LibraryOnly.' }
    Set-AtlasSafeMode -Mode $Mode
}
