# Only known legacy records are translated. Paths identify old launchers as data;
# they are never opened or executed. Current records have no launcher path.

function Get-AtlasLegacyToggleObservedState {
    param([Parameter(Mandatory = $true)][string]$Name)

    $base = [Microsoft.Win32.Registry]::LocalMachine
    $path = switch ($Name) {
        'ContextMenuTerminals' { 'SOFTWARE\Classes\Directory\shell\AtlasTerminals' }
        'VbsState' { 'SYSTEM\CurrentControlSet\Control\DeviceGuard' }
        'VerboseMessages' { 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' }
        'AutomaticUpdates' { 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' }
        'OldContextMenu' {
            $sid = [string](Get-AtlasContext).InteractiveUserSid
            if (-not $sid -or $sid -notmatch '^S-1-(5-21|12-1)-\d+-\d+-\d+-\d+$') { return $null }
            $base = [Microsoft.Win32.Registry]::Users
            $userHive = $base.OpenSubKey($sid, $false)
            if ($null -eq $userHive) { return $null }
            $userHive.Dispose()
            "$sid\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        }
        default { return $null }
    }
    $key = $base.OpenSubKey($path, $false)
    try {
        switch ($Name) {
            'OldContextMenu' {
                if ($null -eq $key) { return 0 }
                if (@($key.GetValueNames()) -contains '' -and $key.GetValue('') -ceq '') { return 1 }
            }
            'ContextMenuTerminals' {
                if ($null -eq $key) { return 0 }
                $terminal = $key.OpenSubKey('shell\Item1', $false)
                try { if ($null -ne $terminal) { return 1 }; return 2 }
                finally { if ($null -ne $terminal) { $terminal.Dispose() } }
            }
            'VbsState' {
                if ($null -eq $key) { return $null }
                $hvci = $key.OpenSubKey('Scenarios\HypervisorEnforcedCodeIntegrity', $false)
                try {
                    if ($null -eq $hvci) { return $null }
                    if (@($key.GetValueNames()) -contains 'EnableVirtualizationBasedSecurity' -and
                        @($hvci.GetValueNames()) -contains 'Enabled' -and
                        $key.GetValueKind('EnableVirtualizationBasedSecurity') -eq [Microsoft.Win32.RegistryValueKind]::DWord -and
                        $hvci.GetValueKind('Enabled') -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
                        $vbs = [int]$key.GetValue('EnableVirtualizationBasedSecurity')
                        if ($vbs -in @(0, 1) -and $vbs -eq [int]$hvci.GetValue('Enabled')) { return $vbs }
                    }
                } finally { if ($null -ne $hvci) { $hvci.Dispose() } }
            }
            default {
                $valueName = if ($Name -eq 'AutomaticUpdates') { 'AUOptions' } else { 'verbosestatus' }
                if ($null -eq $key -or @($key.GetValueNames()) -notcontains $valueName) {
                    if ($Name -eq 'AutomaticUpdates') { return 1 }; return 0
                }
                if ($key.GetValueKind($valueName) -ne [Microsoft.Win32.RegistryValueKind]::DWord) { return $null }
                $value = [int]$key.GetValue($valueName)
                if ($Name -eq 'AutomaticUpdates') {
                    if ($value -eq 2) { return 0 }
                    if ($value -in @(3, 4, 5)) { return 1 }
                } elseif ($value -in @(0, 1)) { return $value }
            }
        }
        return $null
    } finally { if ($null -ne $key) { $key.Dispose() } }
}

function Repair-AtlasLegacyToggleState {
    param([Parameter(Mandatory = $true)]$Key)

    $value = $Key.GetValue('state', $null)
    $path = $Key.GetValue('path', $null)
    if ($null -eq $value -or $Key.GetValueKind('state') -ne [Microsoft.Win32.RegistryValueKind]::DWord -or
        $path -isnot [string]) { return }
    $file = ($path -split '[\\/]')[-1]
    $state = $null
    switch ([string]$Key.PSChildName) {
        'LockScreen' {
            if ($value -eq 1 -and $file -eq 'Hide Lock Screen.cmd') { $state = 0 }
        }
        'HideAppBrowserControl' {
            if ($value -eq 0 -and $file -eq 'Show App and Browser Control.cmd') { $state = 1 }
        }
        'VbsState' {
            if ($value -eq 0 -and $file -eq 'Enable VBS.cmd') {
                $state = Get-AtlasLegacyToggleObservedState -Name VbsState
                if ($null -eq $state) { $state = 1 }
            }
        }
        'ContextMenuTerminals' {
            if ($value -in @(0, 1, 2) -and $file -in @('Add Terminals.cmd', 'Add Terminals (no Windows Terminal).cmd', 'Remove Terminals Context Menu (default).cmd')) {
                # Toolbox changed the value without changing the old path. The
                # installed menu distinguishes its three choices unambiguously.
                $state = Get-AtlasLegacyToggleObservedState -Name ContextMenuTerminals
                if ($null -eq $state) {
                    $state = switch ($file) {
                        'Add Terminals.cmd' { 1 }
                        'Add Terminals (no Windows Terminal).cmd' { 2 }
                        default { 0 }
                    }
                }
            }
        }
    }
    if ($null -ne $state -and $state -ne $value) {
        Set-ItemProperty -LiteralPath $Key.PSPath -Name state -Value ([int]$state) -ErrorAction Stop
        Write-AtlasLog -Message "Migrated legacy toggle '$($Key.PSChildName)' from state $value to $state."
    }
}

function Repair-AtlasLegacyToggleAlias {
    param([Parameter(Mandatory = $true)][string]$StateRoot)

    foreach ($name in @('VerboseStatusMessage', 'AutomaticUpdates')) {
        $sourcePath = Join-Path $StateRoot $name
        if (-not (Test-Path -LiteralPath $sourcePath)) { continue }
        $key = Get-Item -LiteralPath $sourcePath -ErrorAction Stop
        $value = $key.GetValue('state', $null)
        if ($null -eq $value -or $key.GetValueKind('state') -ne [Microsoft.Win32.RegistryValueKind]::DWord) { continue }
        $path = $key.GetValue('path', $null)
        $file = if ($path -is [string]) { ($path -split '[\\/]')[-1] } else { '' }
        if ($name -eq 'VerboseStatusMessage' -and $value -in @(0, 1)) {
            $targetName = 'VerboseMessages'; $state = [int]$value
        } elseif ($name -eq 'AutomaticUpdates' -and $value -eq 1 -and
            $file -in @('Add Idle Toggle in Desktop Context Menu.cmd', 'Remove Idle Toggle in Desktop Context Menu (default).cmd')) {
            $targetName = 'CpuIdleContextMenu'
            $state = if ($file -eq 'Add Idle Toggle in Desktop Context Menu.cmd') { 1 } else { 0 }
        } else { continue }
        $targetPath = Join-Path $StateRoot $targetName
        $target = if (Test-Path -LiteralPath $targetPath) { Get-Item -LiteralPath $targetPath -ErrorAction Stop } else { $null }
        if ($null -eq $target -or $null -eq $target.GetValue('state', $null)) {
            Set-AtlasToggleState -Name $targetName -State $state -StateRoot $StateRoot
        } elseif ($targetName -eq 'VerboseMessages' -and $target.GetValue('path', $null) -is [string]) {
            # Two legacy names can coexist; the live policy tells which was last
            # applied. A modern canonical record always takes precedence.
            $observed = Get-AtlasLegacyToggleObservedState -Name VerboseMessages
            if ($null -ne $observed) { Set-AtlasToggleState -Name $targetName -State $observed -StateRoot $StateRoot }
        }
        Remove-AtlasToggleReplayRecord -Name $name -KeyPath $sourcePath -Reason "was recorded under the wrong legacy name; migrated to '$targetName'."
        if ($targetName -eq 'CpuIdleContextMenu') {
            # The wrong record overwrote the update choice. Recover its live
            # policy instead of letting a context-menu choice enable updates.
            $observed = Get-AtlasLegacyToggleObservedState -Name AutomaticUpdates
            if ($null -ne $observed) { Set-AtlasToggleState -Name AutomaticUpdates -State $observed -StateRoot $StateRoot }
        }
    }
}
