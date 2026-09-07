# Atlas.Shell domain: Send To context-menu items.
#
# Send To entries are per-user shell files plus one Explorer policy value, so every
# change here runs as the signed-in, non-elevated user through its own token.

function Resolve-AtlasSendToSelectorName {
    <#
    .SYNOPSIS
        Expands exact names and wildcard selectors into known Send To item names in
        stable first-match order, rejecting empty or unknown selectors.
    #>
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
    <#
    .SYNOPSIS
        Interprets the multichoice helper output as a cancelled dialog, an explicit
        disable-all choice, or the set of items to keep enabled.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Output,

        [Parameter(Mandatory = $true)]
        [string[]]$AvailableName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisableAllChoice
    )

    if ($Output.Count -gt 1) {
        throw "The Send-To choice helper returned $($Output.Count) output lines."
    }
    $choices = @()
    if ($Output.Count -eq 1) {
        $choices = @($Output[0].Split([char]';') | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            })
    }
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
    <#
    .SYNOPSIS
        Enables or disables one Send To item: the removable-drives entry through its
        Explorer policy value, every other entry through the hidden file attribute.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [bool]$Enabled
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

function Assert-AtlasSendToUser {
    <#
    .SYNOPSIS
        Requires a user-account token, binds Atlas.Registry to it, and returns the SID.
    #>
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ExpectedUserSid
    )

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
    return $actualSid
}

function Get-AtlasSendToItem {
    <#
    .SYNOPSIS
        Enumerates the current user's known Send To items as an ordered name-to-path map;
        the removable-drives entry maps to $null because it is policy-backed.
    #>
    $sendToPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::SendTo)
    $systemPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    if ([string]::IsNullOrWhiteSpace($sendToPath) -or
        [string]::IsNullOrWhiteSpace($systemPath)) {
        throw 'The current user Send-To directory or Windows System32 directory is unavailable.'
    }

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
    return $items
}

function Set-AtlasSendToContextMenu {
    <#
    .SYNOPSIS
        Enables or disables the current user's Send To context-menu items.
    .DESCRIPTION
        Exactly one of -Disable, -Enable or -DebloatDefaults selects the items; with none
        of them the multichoice helper asks interactively and offers an Explorer restart
        afterwards. Runs as the signed-in user; -ExpectedUserSid pins the token when the
        install pipeline launches it.
    #>
    param(
        [string[]]$Disable,

        [string[]]$Enable,

        [switch]$DebloatDefaults,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$ExpectedUserSid
    )

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

    [void](Assert-AtlasSendToUser -ExpectedUserSid $ExpectedUserSid)

    $knownNames = [string[]]@(
        'Removable Drives', 'Bluetooth', 'Fax recipient', 'Compressed (zipped) folder',
        'Desktop (create shortcut)', 'Mail recipient', 'Documents'
    )
    $items = Get-AtlasSendToItem

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
    if (Read-AtlasYesNo -Question 'Restart File Explorer now to apply the change?' -DefaultYes) {
        $shellRefresh = Join-Path -Path $script:AtlasShellOperationsRoot -ChildPath 'Invoke-AtlasUserShellRefresh.ps1'
        if (-not (Test-Path -LiteralPath $shellRefresh -PathType Leaf)) {
            throw "The user shell refresh helper is missing at '$shellRefresh'."
        }
        & $shellRefresh -CurrentSession -Operation ExplorerRefresh
    }
}
