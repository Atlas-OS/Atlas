[CmdletBinding()]
param(
    [string[]]$Disable,
    [string[]]$Enable,
    [switch]$DebloatDefaults,
    [string]$ExpectedUserSid
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Resolve-AtlasSendToSelectorName {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Selector,
        [Parameter(Mandatory = $true)]
        [string[]]$KnownName
    )

    if ($Selector.Count -eq 0) {
        throw 'A Send-To selector list cannot be empty.'
    }

    $resolved = @()
    foreach ($candidate in $Selector) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            throw 'A Send-To selector cannot be empty or whitespace.'
        }
        $matchingNames = @($KnownName | Where-Object { $_ -like $candidate })
        if ($matchingNames.Count -eq 0) {
            throw "Unsupported Send-To item selector '$candidate'."
        }
        foreach ($match in $matchingNames) {
            if ($resolved -cnotcontains $match) { $resolved += $match }
        }
    }
    return $resolved
}

function ConvertFrom-AtlasSendToChoice {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Output,
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableName,
        [Parameter(Mandatory = $true)]
        [string]$DisableAllChoice
    )

    if ($Output.Count -gt 1) {
        throw "The Send-To choice helper returned $($Output.Count) output lines."
    }
    $choices = if ($Output.Count -eq 1) {
        @($Output[0].Split([char]';') | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            })
    }
    else { @() }
    if ($choices.Count -eq 0) {
        return [pscustomobject]@{ Cancelled = $true; Enabled = [string[]]@() }
    }

    $validChoices = @($AvailableName + $DisableAllChoice)
    $unsupported = @($choices | Where-Object { $validChoices -cnotcontains $_ })
    if ($unsupported.Count -gt 0) {
        throw "The Send-To choice helper returned unsupported item '$($unsupported[0])'."
    }
    if (@($choices | Sort-Object -Unique).Count -ne $choices.Count) {
        throw 'The Send-To choice helper returned a duplicate item.'
    }
    if ($choices -ccontains $DisableAllChoice) {
        if ($choices.Count -ne 1) {
            throw 'The disable-all Send-To choice cannot be combined with enabled items.'
        }
        $choices = @()
    }

    return [pscustomobject]@{ Cancelled = $false; Enabled = [string[]]$choices }
}

function Set-AtlasSendToItemState {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private helper applies the state selected by the parent script.'
    )]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path,
        [Parameter(Mandatory = $true)][bool]$Enabled
    )

    if ($Name -ceq 'Removable Drives') {
        $policyPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        if ($Enabled) {
            Remove-AtlasRegistryValue -Path $policyPath -Name 'NoDrivesInSendToMenu'
        }
        else {
            Set-AtlasRegistryValue -Path $policyPath -Name 'NoDrivesInSendToMenu' `
                -Type DWord -Data 1
        }
        return
    }

    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($Enabled) {
        $file.Attributes = $file.Attributes -band (-bnot [IO.FileAttributes]::Hidden)
    }
    else {
        $file.Attributes = $file.Attributes -bor [IO.FileAttributes]::Hidden
    }
}

$hasDisable = $PSBoundParameters.ContainsKey('Disable')
$hasEnable = $PSBoundParameters.ContainsKey('Enable')
if (($hasDisable -and $hasEnable) -or
    ($DebloatDefaults -and ($hasDisable -or $hasEnable))) {
    throw 'Choose exactly one of -Disable, -Enable, or -DebloatDefaults.'
}
if ($DebloatDefaults) {
    $Disable = @('Documents', 'Mail Recipient', 'Fax recipient', 'Bluetooth')
    $hasDisable = $true
}

$scriptsRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $scriptsRoot 'Modules\Atlas.Core\Atlas.Core.psd1') `
    -Force -DisableNameChecking -ErrorAction Stop
Import-Module (Join-Path $scriptsRoot 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
    -Force -DisableNameChecking -ErrorAction Stop

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
try {
    if ($null -eq $identity.User) {
        throw 'The Send-To process token has no user SID.'
    }
    $actualSid = $identity.User.Value
    if (-not $identity.User.IsAccountSid() -or
        $actualSid -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
        throw "Send-To requires a user account token, not '$actualSid'."
    }
}
finally {
    $identity.Dispose()
}
if ([string]::IsNullOrWhiteSpace($ExpectedUserSid)) { $ExpectedUserSid = $actualSid }
Initialize-AtlasRegistryIdentityContext -CurrentToken `
    -ExpectedUserSid $ExpectedUserSid | Out-Null

$sendToPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::SendTo)
$systemPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
if ([string]::IsNullOrWhiteSpace($sendToPath) -or
    [string]::IsNullOrWhiteSpace($systemPath)) {
    throw 'The current user Send-To directory or Windows System32 directory is unavailable.'
}

$knownNames = [string[]]@(
    'Removable Drives', 'Bluetooth', 'Fax recipient', 'Compressed (zipped) folder',
    'Desktop (create shortcut)', 'Mail recipient', 'Documents'
)
$items = [ordered]@{ 'Removable Drives' = $null }
$sendToEntries = @(Get-ChildItem -LiteralPath $sendToPath -Force -ErrorAction Stop)
$shell = New-Object -ComObject WScript.Shell
foreach ($link in @($sendToEntries | Where-Object { $_.Extension -ieq '.lnk' })) {
    $target = [string]$shell.CreateShortcut($link.FullName).TargetPath
    if ($target -ieq (Join-Path $systemPath 'fsquirt.exe')) {
        $items['Bluetooth'] = $link.FullName
    }
    elseif ($target -ieq (Join-Path $systemPath 'WFS.exe')) {
        $items['Fax recipient'] = $link.FullName
    }
}
$extensions = [ordered]@{
    'Compressed (zipped) folder' = '.ZFSendToTarget'
    'Desktop (create shortcut)'  = '.DeskLink'
    'Mail recipient'             = '.MAPIMail'
    'Documents'                  = '.mydocs'
}
foreach ($name in $extensions.Keys) {
    $entry = @($sendToEntries | Where-Object {
            $_.Extension -ieq $extensions[$name]
        }) | Select-Object -First 1
    if ($null -ne $entry) { $items[$name] = $entry.FullName }
}

if ($hasDisable -or $hasEnable) {
    $selectors = if ($hasEnable) { $Enable } else { $Disable }
    foreach ($name in @(Resolve-AtlasSendToSelectorName -Selector $selectors `
                -KnownName $knownNames)) {
        if ($items.Contains($name)) {
            Set-AtlasSendToItemState -Name $name -Path $items[$name] -Enabled $hasEnable
        }
        else {
            Write-Verbose "Optional Send-To item '$name' is not present for this user."
        }
    }
    return
}

$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
$multiChoice = Join-Path $windowsRoot 'AtlasModules\Tools\multichoice.exe'
if (-not (Test-Path -LiteralPath $multiChoice -PathType Leaf)) {
    throw "The Send-To choice helper is missing at '$multiChoice'."
}
$disableAllChoice = '[Apply with every listed Send-To item disabled]'
$availableNames = [string[]]@($items.Keys)
$choiceOutput = @(& $multiChoice 'Send To Debloat' `
        "Tick the 'Send To' items to enable. Unchecked items are disabled." `
        (@($availableNames + $disableAllChoice) -join ';'))
if ($LASTEXITCODE -ne 0) {
    throw "The Send-To choice helper exited with code $LASTEXITCODE."
}
$selection = ConvertFrom-AtlasSendToChoice -Output $choiceOutput `
    -AvailableName $availableNames -DisableAllChoice $disableAllChoice
if ($selection.Cancelled) {
    Write-Verbose 'The Send-To selection dialog was cancelled; no state was changed.'
    return
}

foreach ($name in $availableNames) {
    Set-AtlasSendToItemState -Name $name -Path $items[$name] `
        -Enabled ($selection.Enabled -ccontains $name)
}
if ((Read-MessageBox -Title 'Atlas - Send To Debloat' `
        -Body 'Would you like to restart Windows Explorer to apply the changes now?' `
        -Icon Info) -eq 'Yes') {
    & (Join-Path $PSScriptRoot 'Invoke-AtlasUserShellRefresh.ps1') `
        -CurrentSession -Operation ExplorerRefresh
}
