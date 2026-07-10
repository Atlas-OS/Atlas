[CmdletBinding()]
param (
    [switch]$RestartAfterUpdate,
    [switch]$Silent
)

$trustBootstrap = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1'))
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$atlasCoreManifest = [IO.Path]::GetFullPath(
    [IO.Path]::Combine($PSScriptRoot, '..\Modules\Atlas.Core\Atlas.Core.psd1')
)
if (-not [IO.File]::Exists($atlasCoreManifest)) {
    throw "The protected Atlas.Core manifest is missing at '$atlasCoreManifest'."
}
$atlasCoreModule = [IO.Path]::ChangeExtension($atlasCoreManifest, '.psm1')
if (-not [IO.File]::Exists($atlasCoreModule)) {
    throw "The protected Atlas.Core root module is missing at '$atlasCoreModule'."
}

$loadedAtlasCore = @(
    Microsoft.PowerShell.Core\Import-Module -Name $atlasCoreManifest -Force -PassThru -ErrorAction Stop
)
if ($loadedAtlasCore.Count -ne 1 -or
    $loadedAtlasCore[0].Name -ne 'Atlas.Core' -or
    -not [IO.Path]::GetFullPath($loadedAtlasCore[0].Path).Equals(
        $atlasCoreModule,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "PowerShell did not load Atlas.Core from its protected adjacent manifest."
}

$script:MicrosoftUpdateServiceId = '7971f918-a847-4430-9279-4a52d1efe18d'
$script:WuaClientApplicationId = 'AtlasOS Driver Updater'

function Test-Admin {
    if (-not (Test-AtlasAdmin)) {
        Write-AtlasLog -Message "Restarting script with administrator privileges..."

        $arguments = @(
            "-ExecutionPolicy RemoteSigned",
            "-NoProfile",
            "-File `"$PSCommandPath`""
        )
        if ($RestartAfterUpdate) {
            $arguments += "-RestartAfterUpdate"
        }
        if ($Silent) {
            $arguments += "-Silent"
        }

        $powershellPath = [IO.Path]::Combine(
            [Environment]::GetFolderPath([Environment+SpecialFolder]::System),
            'WindowsPowerShell',
            'v1.0',
            'powershell.exe'
        )
        if (-not [IO.File]::Exists($powershellPath)) {
            throw "The protected PowerShell host is missing at '$powershellPath'."
        }

        $startProcessParams = @{
            FilePath         = $powershellPath
            WorkingDirectory = [Environment]::GetFolderPath(
                [Environment+SpecialFolder]::System
            )
            ArgumentList     = ($arguments -join ' ')
            Verb             = 'RunAs'
            Wait             = $true
            PassThru         = $true
            ErrorAction      = 'Stop'
        }
        if ($Silent) {
            $startProcessParams['WindowStyle'] = 'Hidden'
        }

        try {
            $elevatedProcess = Microsoft.PowerShell.Management\Start-Process @startProcessParams
        }
        catch {
            if ($_.Exception -is [ComponentModel.Win32Exception] -and
                $_.Exception.NativeErrorCode -eq 1223) {
                [Console]::Error.WriteLine('Driver update elevation was cancelled by the user.')
                exit 1223
            }
            throw
        }
        if ($null -eq $elevatedProcess -or
            $elevatedProcess.PSObject.Properties.Name -notcontains 'ExitCode') {
            throw 'Driver update elevation did not return an exit-code-bearing process.'
        }
        exit ([int]$elevatedProcess.ExitCode)
    }
}
Test-Admin

function New-WuaComObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'ServiceManager',
            'Session',
            'UpdateCollection'
        )]
        [string]$Class
    )

    # Fixed inbox WUA coclass IDs avoid all ProgID and PowerShell module lookup.
    # Test-Admin ensures COM activation occurs in an elevated process, where UAC
    # excludes per-user COM class registrations from resolution.
    $classIds = @{
        ServiceManager   = [Guid]'f8d253d9-89a4-4daa-87b6-1168369f0b21'
        Session          = [Guid]'4cb43d7f-7eee-4906-8698-60da1c38f2fe'
        UpdateCollection = [Guid]'13639463-00db-4646-803d-528026140d88'
    }
    $classId = $classIds[$Class]
    $comType = [Type]::GetTypeFromCLSID($classId, $true)
    $instance = [Activator]::CreateInstance($comType)
    if ($null -eq $instance) {
        throw "Windows Update Agent did not create the protected '$Class' coclass."
    }

    # IUpdateCollection exposes an enumerator; keep the COM object itself intact
    # when it crosses the PowerShell pipeline boundary.
    return ,$instance
}

function Enable-MicrosoftUpdate {
    Write-AtlasLog -Message "Enabling Microsoft Update for driver updates..."
    $serviceManager = New-WuaComObject -Class 'ServiceManager'
    $serviceManager.ClientApplicationID = $script:WuaClientApplicationId

    # 7 = asfAllowPendingRegistration | asfAllowOnlineRegistration | asfRegisterServiceWithAU.
    $registration = $serviceManager.AddService2(
        $script:MicrosoftUpdateServiceId,
        7,
        ''
    )
    if ($null -eq $registration -or [int]$registration.RegistrationState -ne 3) {
        throw 'Microsoft Update did not reach the registered service state.'
    }
    $service = $registration.Service
    if ($null -eq $service -or
        -not ([string]$service.ServiceID).Equals(
            $script:MicrosoftUpdateServiceId,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not [bool]$service.IsRegisteredWithAU) {
        throw 'Windows Update Agent did not retain the expected registered Microsoft Update service identity.'
    }
}

function New-WuaSession {
    $session = New-WuaComObject -Class 'Session'
    $session.ClientApplicationID = $script:WuaClientApplicationId
    return $session
}

function Get-DriverUpdates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Session
    )

    $searcher = $Session.CreateUpdateSearcher()
    $searcher.ClientApplicationID = $script:WuaClientApplicationId
    $searcher.Online = $true
    # ssOthers (3) scopes ServiceID to the Microsoft Update service registered above.
    $searcher.ServerSelection = 3
    $searcher.ServiceID = $script:MicrosoftUpdateServiceId

    $searchResult = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
    if ([int]$searchResult.ResultCode -ne 2) {
        throw "Windows Update Agent driver search returned result code $([int]$searchResult.ResultCode)."
    }

    $updates = @()
    for ($index = 0; $index -lt [int]$searchResult.Updates.Count; $index++) {
        $updates += $searchResult.Updates.Item($index)
    }

    return $updates
}

function New-WuaUpdateCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Updates
    )

    if ($Updates.Count -eq 0) {
        throw 'At least one selected driver update is required.'
    }

    $collection = New-WuaComObject -Class 'UpdateCollection'
    $identities = @{}
    foreach ($update in $Updates) {
        if ($null -eq $update -or $null -eq $update.Identity) {
            throw 'A selected driver update has no Windows Update Agent identity.'
        }

        $updateId = [string]$update.Identity.UpdateID
        $revision = [int]$update.Identity.RevisionNumber
        if ([string]::IsNullOrWhiteSpace($updateId)) {
            throw 'A selected driver update has an empty Windows Update Agent identity.'
        }

        $identityKey = $updateId.ToUpperInvariant() + ':' + $revision
        if ($identities.ContainsKey($identityKey)) {
            throw "The selected driver update '$updateId' revision $revision was supplied more than once."
        }
        $identities[$identityKey] = $true
        [void]$collection.Add($update)
    }

    if ([int]$collection.Count -ne $Updates.Count) {
        throw 'Windows Update Agent did not retain every selected driver update.'
    }

    return ,$collection
}

function Assert-WuaOperationSucceeded {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Result,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ExpectedUpdateCount,

        [Parameter(Mandatory = $true)]
        [ValidateSet('download', 'installation')]
        [string]$Operation
    )

    # OperationResultCode 2 is the only complete success. Code 3 is partial success.
    $resultCode = [int]$Result.ResultCode
    if ($resultCode -ne 2) {
        throw "Windows Update Agent $Operation returned result code $resultCode."
    }

    for ($index = 0; $index -lt $ExpectedUpdateCount; $index++) {
        $updateResult = $Result.GetUpdateResult($index)
        if ($null -eq $updateResult) {
            throw "Windows Update Agent $Operation did not return a result for selected update index $index."
        }

        $updateResultCode = [int]$updateResult.ResultCode
        if ($updateResultCode -ne 2) {
            throw "Windows Update Agent $Operation failed for selected update index $index with result code $updateResultCode."
        }
    }
}

function Install-DriverUpdates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Session,

        [Parameter(Mandatory = $true)]
        [array]$Updates
    )

    $selectedUpdates = New-WuaUpdateCollection -Updates $Updates
    for ($index = 0; $index -lt [int]$selectedUpdates.Count; $index++) {
        $update = $selectedUpdates.Item($index)
        if (-not [bool]$update.EulaAccepted) {
            $update.AcceptEula()
        }
    }

    $downloader = $Session.CreateUpdateDownloader()
    $downloader.ClientApplicationID = $script:WuaClientApplicationId
    $downloader.IsForced = $false
    $downloader.Updates = $selectedUpdates
    $downloadResult = $downloader.Download()
    Assert-WuaOperationSucceeded -Result $downloadResult `
        -ExpectedUpdateCount ([int]$selectedUpdates.Count) -Operation 'download'

    $installer = $Session.CreateUpdateInstaller()
    $installer.ClientApplicationID = $script:WuaClientApplicationId
    $installer.AllowSourcePrompts = $false
    $installer.IsForced = $false
    $installer.Updates = $selectedUpdates
    if ([bool]$installer.RebootRequiredBeforeInstallation) {
        throw 'Windows Update Agent requires a restart before installing the selected driver updates.'
    }

    $installationResult = $installer.Install()
    Assert-WuaOperationSucceeded -Result $installationResult `
        -ExpectedUpdateCount ([int]$selectedUpdates.Count) -Operation 'installation'

    return [pscustomobject]@{
        InstalledCount = [int]$selectedUpdates.Count
        RebootRequired = [bool]$installationResult.RebootRequired
    }
}

function Show-DriverSelection {
    param (
        [array]$Updates
    )

    if ($Updates.Count -eq 0) {
        return @()
    }

    Add-Type -AssemblyName PresentationFramework

    $window = New-Object System.Windows.Window
    $window.Title = "Select drivers to install"
    $window.Width = 500
    $window.Height = 400
    $window.WindowStartupLocation = "CenterScreen"

    $stackPanel = New-Object System.Windows.Controls.StackPanel

    $listBox = New-Object System.Windows.Controls.ListBox
    $listBox.SelectionMode = "Extended"
    foreach ($update in $Updates) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = $update.Title.ToString().Trim()
        # Preserve the exact IUpdate object selected by the user. Mapping by title
        # can select additional updates when two drivers have the same title.
        $item.Tag = $update
        $listBox.Items.Add($item) | Out-Null
    }
    $stackPanel.Children.Add($listBox) | Out-Null

    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Margin = "10,10,10,10"
    $okButton.Add_Click({
            $window.Tag = $listBox.SelectedItems
            $window.Close()
        })
    $stackPanel.Children.Add($okButton) | Out-Null

    $window.Content = $stackPanel
    $window.ShowDialog() | Out-Null

    $selectedUpdates = @()
    foreach ($selected in $window.Tag) {
        if ($null -ne $selected.Tag) {
            $selectedUpdates += $selected.Tag
        }
    }

    return $selectedUpdates
}

function Update-Drivers {
    Write-AtlasLog -Message "Checking for driver updates..."
    try {
        $session = New-WuaSession
        $updates = @(Get-DriverUpdates -Session $session)
    }
    catch {
        Write-Error "Failed to query driver updates: $($_.Exception.Message)"
        return $false
    }

    if ($updates.Count -eq 0) {
        Write-AtlasLog -Message "No driver updates found."
        return $true
    }

    Write-AtlasLog -Message "Available driver updates:"

    if ($Silent) {
        Write-AtlasLog -Message "Silent mode enabled; selecting all available driver updates."
        $selection = $updates
    }
    else {
        $selection = @(Show-DriverSelection -Updates $updates)
    }

    if ($selection.Count -eq 0) {
        Write-AtlasLog -Message "No drivers were selected for update."
        return $true
    }

    Write-AtlasLog -Message "Installing selected driver updates..."
    foreach ($update in $selection) {
        Write-AtlasLog -Message (" - {0}" -f $update.Title.ToString().Trim())
    }

    try {
        $installation = Install-DriverUpdates -Session $session -Updates $selection
    }
    catch {
        Write-Error "Driver update installation failed: $($_.Exception.Message)"
        return $false
    }

    Write-AtlasLog -Message "Driver updates installed successfully!"
    if ($installation.RebootRequired) {
        Write-AtlasLog -Message "Windows Update Agent reports that a restart is required."
    }

    if ($RestartAfterUpdate) {
        Write-AtlasLog -Message "RestartAfterUpdate is enabled. Restarting the system in 10 seconds..."
        Start-Sleep -Seconds 10
        Microsoft.PowerShell.Management\Restart-Computer -Force -ErrorAction Stop
        return $true
    }

    if (-not $Silent) {
        $restartChoice = Read-Host "Do you want to restart now? (Y/N)"
        if ($restartChoice -match "^[Yy]$") {
            Write-AtlasLog -Message "Restarting the system in 10 seconds..."
            Start-Sleep -Seconds 10
            Microsoft.PowerShell.Management\Restart-Computer -Force -ErrorAction Stop
        }
    }

    return $true
}

$scriptSucceeded = $false
try {
    Enable-MicrosoftUpdate
    $scriptSucceeded = Update-Drivers
}
catch {
    Write-Error "Driver update process failed: $($_.Exception.Message)"
    exit 1
}

if (-not $scriptSucceeded) {
    exit 1
}

if (-not $Silent) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
