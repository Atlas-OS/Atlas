# Atlas.Network domain: the File Sharing machine state shared by the fresh install
# and the FileSharing toggle. Enable restores the adapter bindings, NetBIOS, the NetBT
# driver and Network Discovery; Disable removes them, forces Public network profiles,
# disables the sharing firewall groups and removes the Sharing context menu. The firewall
# groups are changed through the Windows Defender Firewall service, which is started for
# the change when it's stopped.

# Client for Microsoft Networks, File and Printer Sharing for Microsoft Networks, and the
# Link-Layer Topology Discovery mapper I/O driver and responder.
$script:AtlasFileSharingBindingComponents = @('ms_msclient', 'ms_server', 'ms_lltdio', 'ms_rspndr')
$script:AtlasFileSharingNetBtInterfacesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'
# The Sharing shell extension behind the 'Give access to' context menu.
$script:AtlasFileSharingContextMenuClsid = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
$script:AtlasFileSharingContextMenuKeys = @(
    'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'Registry::HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
)
$script:AtlasFileSharingMachineContextMenuKeys = @(
    'HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'HKLM:\SOFTWARE\Classes\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
)
# Windows Defender Firewall, which serves the firewall rule cmdlets.
$script:AtlasFirewallServiceName = 'mpssvc'

function Invoke-AtlasFirewallServiceOperation {
    <#
    .SYNOPSIS
        Runs a firewall rule operation with the Windows Defender Firewall service running.
    .DESCRIPTION
        The firewall rule cmdlets reach the rules through the service, so while it's
        stopped they fail with "There are no more endpoints available from the endpoint
        mapper". A running service is used as it is. A stopped one, which tools outside
        Atlas can leave Disabled, is started for the operation, set to Manual first when
        it's Disabled, and then stopped and given its startup type back. A service that
        won't start stops the operation with the steps that fix it.
    .PARAMETER Operation
        The rule changes and their checks.
    .PARAMETER ServicesRoot
        The Services key whose startup type is changed. Tests pass an isolated root.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    $firewallService = $script:AtlasFirewallServiceName
    $fixText = 'Set the Windows Defender Firewall service (mpssvc) to Automatic, restart Windows and try again.'
    try {
        $status = [string](Get-Service -Name $firewallService -ErrorAction Stop).Status
    }
    catch {
        throw ("File Sharing changes the sharing firewall rules through the Windows Defender Firewall " +
            "service (mpssvc), which couldn't be read: $($_.Exception.Message) Repair Windows and try again.")
    }
    if ($status -eq 'Running') {
        & $Operation
        return
    }

    $servicePath = Join-Path -Path $ServicesRoot -ChildPath $firewallService
    $startValue = Get-ItemProperty -LiteralPath $servicePath -Name 'Start' -ErrorAction SilentlyContinue
    if ($null -eq $startValue -or [int]$startValue.Start -lt 0 -or [int]$startValue.Start -gt 4) {
        throw "The Windows Defender Firewall service (mpssvc) has no readable startup type. $fixText"
    }
    $originalStart = [int]$startValue.Start
    $restoreStartup = $false
    $stopAfter = $false
    $operationFailed = $true
    try {
        try {
            # Start value 4 is Disabled and 3 is Manual.
            if ($originalStart -eq 4) {
                $restoreStartup = $true
                $startup = Set-AtlasServiceStartup -Name $firewallService -StartupType 3 `
                    -ServicesRoot $ServicesRoot -PassThru
                if ([string]$startup.ServiceManager -ceq 'Refused') {
                    throw 'The service manager kept it Disabled.'
                }
            }
            $stopAfter = $true
            Start-Service -Name $firewallService -ErrorAction Stop
            $status = [string](Get-Service -Name $firewallService -ErrorAction Stop).Status
            if ($status -ne 'Running') {
                throw "It's $status, not Running."
            }
        }
        catch {
            $reasons = [Collections.Generic.List[string]]::new()
            for ($cause = $_.Exception; $null -ne $cause; $cause = $cause.InnerException) {
                if (-not $reasons.Contains($cause.Message)) { $reasons.Add($cause.Message) }
            }
            throw ("File Sharing couldn't start the Windows Defender Firewall service (mpssvc), which it " +
                "needs to change the sharing firewall rules: $($reasons -join ' ') $fixText")
        }
        Write-AtlasLog -Message ('Started the stopped Windows Defender Firewall service to change the ' +
            "sharing firewall rules; it's stopped again afterwards, with startup type $originalStart.")

        & $Operation
        $operationFailed = $false
    }
    finally {
        $restoreFailures = [Collections.Generic.List[string]]::new()
        if ($stopAfter) {
            try { Stop-Service -Name $firewallService -Force -ErrorAction Stop }
            catch { $restoreFailures.Add("stopping it failed: $($_.Exception.Message)") }
        }
        if ($restoreStartup) {
            try { Set-AtlasServiceStartup -Name $firewallService -StartupType $originalStart -ServicesRoot $ServicesRoot }
            catch { $restoreFailures.Add("restoring startup type $originalStart failed: $($_.Exception.Message)") }
        }
        if ($restoreFailures.Count -gt 0) {
            $restoreText = "The Windows Defender Firewall service (mpssvc) wasn't put back as it was: " +
                ($restoreFailures -join '; ')
            # The operation's own failure is the one that stops the run.
            if ($operationFailed) { Write-AtlasLog -Level Error -Message $restoreText }
            else { throw $restoreText }
        }
    }
}

function Get-AtlasFileSharingFirewallRule {
    <#
    .SYNOPSIS
        Returns the Private-profile rules of the File and Printer Sharing and Network
        Discovery groups.
    #>
    # The group resource strings identify the two groups in any display language; the
    # English display names cover rules created without them.
    @(Get-NetFirewallRule -ErrorAction Stop | Where-Object {
            ($_.Group -in @('@FirewallAPI.dll,-28502', '@FirewallAPI.dll,-32752') -or
                $_.DisplayGroup -in @('File and Printer Sharing', 'Network Discovery')) -and
            ($_.Profile -like '*Private*' -or [string]$_.Profile -eq 'Any')
        })
}

function Enable-AtlasPrivateSharingFirewallRule {
    <#
    .SYNOPSIS
        Enables sharing on Private networks without enabling a disabled rule's
        Public or Domain coverage. Combined-profile rules get a Private-only copy;
        Copy-NetFirewallRule preserves all of the original rule's traffic filters.
    #>
    $rules = @(Get-AtlasFileSharingFirewallRule)
    $processed = @{}
    foreach ($rule in $rules) {
        # Copies are reached through their source rule, never copied recursively.
        if ([string]$rule.Name -like 'Atlas-Private-*') { continue }
        if ($processed.ContainsKey([string]$rule.Name)) { continue }
        $target = $rule
        if ([string]$rule.Profile -ne 'Private') {
            # Already-enabled coverage belongs to the user's existing configuration.
            if ([string]$rule.Enabled -in @('True', '1')) { continue }

            $copyName = 'Atlas-Private-' + $rule.Name
            $existing = @($rules | Where-Object { $_.Name -eq $copyName })
            if ($existing.Count -gt 1) {
                throw "Multiple firewall rules use the name '$copyName'."
            }
            if ($existing.Count -eq 1) {
                $target = $existing[0]
                if ($target.Group -ne $rule.Group -or
                    ([string]$target.Profile -ne 'Private' -and
                        [string]$target.Enabled -notin @('False', '0'))) {
                    throw "Firewall rule '$copyName' is not the expected Private sharing rule."
                }
            }
            else {
                # The source is disabled, so copying it cannot temporarily open its
                # other profiles. Narrow the copy before enabling it.
                Copy-NetFirewallRule -InputObject $rule -NewName $copyName `
                    -ErrorAction Stop | Out-Null
                # Copy's PassThru object can still identify the source. Resolve the
                # persisted copy by its new name before making any changes.
                $copy = @(Get-NetFirewallRule -Name $copyName -ErrorAction Stop)
                if ($copy.Count -ne 1 -or $copy[0].Group -ne $rule.Group -or
                    [string]$copy[0].Enabled -notin @('False', '0')) {
                    throw "Could not resolve the disabled copy of firewall rule '$($rule.Name)'."
                }
                $target = $copy[0]
            }
            if ([string]$target.Profile -ne 'Private') {
                # Also finish narrowing a disabled copy left by an interrupted run.
                Set-NetFirewallRule -InputObject $target -Profile Private -Enabled False `
                    -ErrorAction Stop | Out-Null
                $current = @(Get-NetFirewallRule -Name $copyName -ErrorAction Stop)
                if ($current.Count -ne 1 -or [string]$current[0].Profile -ne 'Private' -or
                    [string]$current[0].Enabled -notin @('False', '0')) {
                    throw "Firewall rule '$copyName' did not retain its disabled Private scope."
                }
                $target = $current[0]
            }
        }

        if ($processed.ContainsKey([string]$target.Name)) { continue }
        Enable-NetFirewallRule -InputObject $target -ErrorAction Stop | Out-Null
        $current = @(Get-NetFirewallRule -Name $target.Name -ErrorAction Stop)
        if ($current.Count -ne 1 -or [string]$current[0].Profile -ne 'Private' -or
            [string]$current[0].Enabled -notin @('True', '1')) {
            throw "Firewall rule '$($target.Name)' did not retain its enabled Private scope."
        }
        $processed[[string]$target.Name] = $true
    }
}

function Set-AtlasFileSharingAdapterBinding {
    <#
    .SYNOPSIS
        Enables or disables the managed adapter binding components on every adapter and
        verifies that no binding was left in the opposite state.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $components = $script:AtlasFileSharingBindingComponents
    foreach ($binding in @(Get-NetAdapterBinding -Name '*' -ComponentID $components -ErrorAction Stop)) {
        if ([bool]$binding.Enabled -eq $Enabled) {
            continue
        }
        # The binding itself is passed, because -Name is a wildcard: an adapter name with
        # brackets, such as a VPN adapter's, would read as a character set and match nothing.
        if ($Enabled) {
            Enable-NetAdapterBinding -InputObject $binding -Confirm:$false `
                -ErrorAction Stop | Out-Null
        }
        else {
            Disable-NetAdapterBinding -InputObject $binding -Confirm:$false `
                -ErrorAction Stop | Out-Null
        }
    }

    $remaining = @(Get-NetAdapterBinding -Name '*' -ComponentID $components -ErrorAction Stop |
            Where-Object { [bool]$_.Enabled -ne $Enabled })
    if ($remaining.Count -ne 0) {
        $stateText = if ($Enabled) { 'enable left a managed adapter binding disabled' }
        else { 'disable left a managed adapter binding enabled' }
        throw "File Sharing $stateText."
    }
}

function Set-AtlasFileSharingNetBiosOption {
    <#
    .SYNOPSIS
        Writes NetbiosOptions (1 = enabled, 2 = disabled) to every NetBT interface that
        declares the value and verifies each write was retained.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(1, 2)]
        [int]$Option,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InterfacesRoot
    )

    $modeText = if ($Option -eq 1) { 'enabled' } else { 'disabled' }
    foreach ($interface in @(Get-ChildItem -LiteralPath $InterfacesRoot -ErrorAction Stop |
                Where-Object { $_.GetValueNames() -contains 'NetbiosOptions' })) {
        Set-ItemProperty -LiteralPath $interface.PSPath -Name 'NetbiosOptions' `
            -Value $Option -Type DWord -Force -ErrorAction Stop
        $key = Get-Item -LiteralPath $interface.PSPath -ErrorAction Stop
        try {
            if ($key.GetValueKind('NetbiosOptions') -ne
                [Microsoft.Win32.RegistryValueKind]::DWord -or
                [int]$key.GetValue('NetbiosOptions') -ne $Option) {
                throw "NetBIOS interface '$($interface.PSChildName)' did not retain $modeText mode."
            }
        }
        finally {
            $key.Close()
        }
    }
}

function Enable-AtlasFileSharing {
    <#
    .SYNOPSIS
        Enables File Sharing: adapter bindings, NetBIOS, the NetBT driver and the
        Network Discovery machine state. Interactively (without -Silent) it also offers
        to switch active network profiles to Private with the sharing firewall groups,
        and to restore the 'Give access to' context menu.
    #>
    param(
        [switch]$Silent,

        # Toggle state store; the default is the toggle engine's own store.
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot,

        # Tests can supply isolated registry roots.
        [ValidateNotNullOrEmpty()]
        [string]$NetBtInterfacesRoot = $script:AtlasFileSharingNetBtInterfacesRoot,

        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    if (-not $Silent) {
        Write-AtlasStep -Text 'Enabling file sharing, NetBIOS and network discovery...'
    }
    Set-AtlasFileSharingAdapterBinding -Enabled $true
    Set-AtlasFileSharingNetBiosOption -Option 1 -InterfacesRoot $NetBtInterfacesRoot
    # Start value 1 is System: NetBT is a kernel driver that loads during kernel initialisation.
    Set-AtlasServiceStartup -Name 'NetBT' -StartupType 1 -ServicesRoot $ServicesRoot

    # Network Discovery owns the rest of the service dependency chain, including SMB.
    $discoveryParameters = @{ Name = 'NetworkDiscovery'; State = 'Enable' }
    if ($PSBoundParameters.ContainsKey('StateRoot')) {
        $discoveryParameters['StateRoot'] = $StateRoot
    }
    Invoke-AtlasToggleMachineState @discoveryParameters
    Write-AtlasLog -Message 'Enabled File Sharing adapter bindings, NetBIOS, NetBT and Network Discovery.'

    if ($Silent) {
        return
    }

    if (Read-AtlasYesNo -Question 'Switch your active networks to the Private profile so other devices can see this PC?') {
        foreach ($networkProfile in @(Get-NetConnectionProfile -ErrorAction Stop)) {
            if ([string]$networkProfile.NetworkCategory -cne 'Private') {
                Set-NetConnectionProfile -InputObject $networkProfile -NetworkCategory Private `
                    -ErrorAction Stop
            }
        }

        Invoke-AtlasFirewallServiceOperation -ServicesRoot $ServicesRoot -Operation {
            Enable-AtlasPrivateSharingFirewallRule
        }

        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' `
            -Name 'AutoSetup' -Type DWord -Data 1
    }

    if (Read-AtlasYesNo -Question "Restore the 'Give access to' context menu?") {
        foreach ($key in $script:AtlasFileSharingContextMenuKeys) {
            Set-AtlasRegistryValue -Path $key -Name '' -Type String `
                -Data $script:AtlasFileSharingContextMenuClsid
        }
    }
}

function Disable-AtlasFileSharing {
    <#
    .SYNOPSIS
        Disables File Sharing: adapter bindings, NetBIOS and the NetBT driver, then
        forces every network profile to Public, disables the Private sharing firewall
        groups and removes the 'Give access to' context menu.
    #>
    param(
        [switch]$Silent,

        # Tests can supply isolated registry roots.
        [ValidateNotNullOrEmpty()]
        [string]$NetBtInterfacesRoot = $script:AtlasFileSharingNetBtInterfacesRoot,

        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    if (-not $Silent) {
        Write-AtlasStep -Text 'Disabling file sharing, NetBIOS and the sharing firewall rules...'
    }
    Set-AtlasFileSharingAdapterBinding -Enabled $false
    Set-AtlasFileSharingNetBiosOption -Option 2 -InterfacesRoot $NetBtInterfacesRoot
    # Start value 4 is Disabled.
    Set-AtlasServiceStartup -Name 'NetBT' -StartupType 4 -ServicesRoot $ServicesRoot

    foreach ($networkProfile in @(Get-NetConnectionProfile -ErrorAction Stop)) {
        if ([string]$networkProfile.NetworkCategory -cne 'Public') {
            Set-NetConnectionProfile -InputObject $networkProfile -NetworkCategory Public `
                -ErrorAction Stop
        }
    }
    if (@(Get-NetConnectionProfile -ErrorAction Stop | Where-Object {
                [string]$_.NetworkCategory -cne 'Public'
            }).Count -ne 0) {
        throw 'File Sharing disable left a network profile outside the Public category.'
    }

    Invoke-AtlasFirewallServiceOperation -ServicesRoot $ServicesRoot -Operation {
        $rules = @(Get-AtlasFileSharingFirewallRule)
        if ($rules.Count -ne 0) {
            Disable-NetFirewallRule -InputObject $rules -ErrorAction Stop | Out-Null
        }
        foreach ($rule in @(Get-AtlasFileSharingFirewallRule)) {
            if ([string]$rule.Enabled -notin @('False', '0')) {
                throw "Firewall rule '$($rule.Name)' did not retain its disabled state."
            }
        }
    }

    foreach ($key in $script:AtlasFileSharingMachineContextMenuKeys) {
        Remove-AtlasRegistryKey -Path $key
        if (Test-Path -LiteralPath $key -ErrorAction Stop) {
            throw "File Sharing disable left the context-menu key '$key'."
        }
    }
    Write-AtlasLog -Message 'Disabled File Sharing adapter bindings, NetBIOS, NetBT, sharing firewall rules and the Sharing context menu.'
}
