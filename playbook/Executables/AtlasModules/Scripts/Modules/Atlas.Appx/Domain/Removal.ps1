# Atlas.Appx domain: installed and provisioned package-family removal.
#
# AME's former family-level AppX action matched package families, not only the
# package identity Name exposed by Get-AppxPackage. Keep that distinction here so
# exact family names (notably Edge's `*_8wekyb3d8bbwe` identities) and wildcard
# patterns retain their original meaning.
# https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/package-identity-overview
# https://learn.microsoft.com/en-us/powershell/module/appx/remove-appxpackage
# https://learn.microsoft.com/en-us/powershell/module/dism/remove-appxprovisionedpackage

function Get-AtlasAppxRemovalDefinition {
    <#
    .SYNOPSIS
        Returns the ordered package-family removal policy migrated from the former
        AME AppX actions and now owned by the AppxSupport phase.
    #>
    return @(
        [pscustomobject]@{ Name = 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe';        Option = 'uninstall-edge';      IgnoreErrors = $true }
        [pscustomobject]@{ Name = 'Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'; Option = 'uninstall-edge';      IgnoreErrors = $true }
        [pscustomobject]@{ Name = 'Microsoft.Edge.GameAssist*';                   Option = 'uninstall-edge';      IgnoreErrors = $true }
        [pscustomobject]@{ Name = 'MicrosoftTeams*';                              Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'MSTeams*';                                     Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Copilot*';                           Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'MicrosoftWindows.Client.WebExperience*';       Option = $null;                 IgnoreErrors = $true }
        [pscustomobject]@{ Name = 'Microsoft.WidgetsPlatformRuntime*';            Option = $null;                 IgnoreErrors = $true }
        [pscustomobject]@{ Name = 'Clipchamp.Clipchamp*';                         Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Disney.37853FC22B2CE*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'SpotifyAB.SpotifyMusic*';                      Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.549981C3F5F10*';                     Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.XboxApp*';                           Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'microsoft.windowscommunicationsapps*';          Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.MSPaint*';                           Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Paint*';                             Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Getstarted*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsBackup*';                     Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.ZuneVideo*';                         Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.ZuneMusic*';                         Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'MicrosoftCorporationII.MicrosoftFamily*';       Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'MicrosoftCorporationII.QuickAssist*';           Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.MixedReality.Portal*';               Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Windows.DevHome*';                   Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.BingWeather*';                       Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.BingNews*';                          Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.BingFinance*';                       Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.BingSports*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.BingSearch*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.OutlookForWindows*';                 Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.GetHelp*';                           Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Microsoft3DViewer*';                 Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.MicrosoftOfficeHub*';                Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.MicrosoftSolitaireCollection*';       Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.MicrosoftStickyNotes*';              Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.StickyNotesPreview*';                Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Office.OneNote*';                    Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.OneConnect*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.People*';                            Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.PowerAutomateDesktop*';              Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.ScreenSketch*';                      Option = 'remove-snipping-tool'; IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.SkypeApp*';                          Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Todos*';                             Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Wallet*';                            Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.Whiteboard*';                        Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsAlarms*';                     Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsCamera*';                     Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsFeedbackHub*';                Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsMaps*';                       Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.WindowsSoundRecorder*';              Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Microsoft.StartExperiencesApp*';               Option = $null;                 IgnoreErrors = $false }
        [pscustomobject]@{ Name = 'Ink.Handwriting.Main.Store.en-US1.0';           Option = $null;                 IgnoreErrors = $false }
    )
}

function Get-AtlasAppxIdentityCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Package
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($propertyName in @('Name', 'DisplayName', 'PackageFamilyName', 'PackageFullName', 'PackageName')) {
        $property = $Package.PSObject.Properties[$propertyName]
        if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            $candidates.Add([string]$property.Value)
        }
    }

    # DISM's provisioned-package object does not consistently expose a family-name
    # property. PackageName follows Name_Version_Architecture_ResourceId_PublisherId;
    # derive Name_PublisherId so exact family patterns keep working.
    $packageNameProperty = $Package.PSObject.Properties['PackageName']
    if ($packageNameProperty -and -not [string]::IsNullOrWhiteSpace([string]$packageNameProperty.Value)) {
        $segments = @(([string]$packageNameProperty.Value) -split '_')
        if ($segments.Count -ge 5) {
            $candidates.Add(('{0}_{1}' -f $segments[0], $segments[$segments.Count - 1]))
        }
    }

    return @($candidates | Select-Object -Unique)
}

function Test-AtlasAppxFamilyMatch {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Package,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    foreach ($candidate in @(Get-AtlasAppxIdentityCandidate -Package $Package)) {
        if ($candidate -like $Name) {
            return $true
        }
    }
    return $false
}

function Get-AtlasAppxInstalledInventory {
    # Remove-AppxPackage -AllUsers acts on a parent package. Include bundles explicitly
    # as Microsoft documents; Main covers non-bundled app packages.
    return @(Get-AppxPackage -AllUsers -PackageTypeFilter Bundle, Main -ErrorAction Stop)
}

function Get-AtlasAppxProvisionedInventory {
    return @(Get-AppxProvisionedPackage -Online -ErrorAction Stop)
}

function Get-AtlasAppxParentInstalledPackage {
    param(
        [AllowEmptyCollection()]
        [psobject[]]$Package = @()
    )

    # Get-AppxPackage returns both a bundle and its architecture-specific Main child
    # when Bundle,Main is requested. Remove-AppxPackage -AllUsers must act on the
    # parent bundle; attempting the child afterward produces a false failure.
    $familiesWithBundles = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($item in $Package) {
        $isBundleProperty = $item.PSObject.Properties['IsBundle']
        if (-not $isBundleProperty -or -not [bool]$isBundleProperty.Value) {
            continue
        }

        $familyProperty = $item.PSObject.Properties['PackageFamilyName']
        $nameProperty = $item.PSObject.Properties['Name']
        $family = if ($familyProperty) { [string]$familyProperty.Value } elseif ($nameProperty) { [string]$nameProperty.Value } else { $null }
        if (-not [string]::IsNullOrWhiteSpace($family)) {
            [void]$familiesWithBundles.Add($family)
        }
    }

    foreach ($item in $Package) {
        $isBundleProperty = $item.PSObject.Properties['IsBundle']
        if ($isBundleProperty -and [bool]$isBundleProperty.Value) {
            $item
            continue
        }

        $familyProperty = $item.PSObject.Properties['PackageFamilyName']
        $nameProperty = $item.PSObject.Properties['Name']
        $family = if ($familyProperty) { [string]$familyProperty.Value } elseif ($nameProperty) { [string]$nameProperty.Value } else { $null }
        if ([string]::IsNullOrWhiteSpace($family) -or -not $familiesWithBundles.Contains($family)) {
            $item
        }
    }
}

function Add-AtlasAppxRemovalFailure {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Failures,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    if ([bool]$Definition.IgnoreErrors) {
        Write-AtlasLog -Level Warning -Message "Ignoring AppX removal failure for '$($Definition.Name)': $Message"
        return
    }

    $Failures.Add("$($Definition.Name): $Message")
    Write-AtlasLog -Level Error -Message "AppX removal failed for '$($Definition.Name)': $Message"
}

function Invoke-AtlasAppxRemovalPlan {
    <#
    .SYNOPSIS
        Removes matching installed registrations for every existing user and matching
        provisioned packages for future users, then verifies both inventories.
    .DESCRIPTION
        All definitions are attempted in order. Command failures remain visible, but
        the fresh inventories taken afterward determine whether a required removal
        actually failed. Definitions that formerly used AME's ignoreErrors flag remain
        warning-only. Option gates are read from Atlas's authoritative install context
        (install-state-backed, with released-flag compatibility).
    #>
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$Definition = @(Get-AtlasAppxRemovalDefinition)
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    $activeDefinitions = [System.Collections.Generic.List[psobject]]::new()

    try {
        $installedInventory = @(Get-AtlasAppxInstalledInventory)
    }
    catch {
        $installedInventory = @()
        $message = "Installed-package inventory failed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Error -Message $message
    }

    try {
        $provisionedInventory = @(Get-AtlasAppxProvisionedInventory)
    }
    catch {
        $provisionedInventory = @()
        $message = "Provisioned-package inventory failed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Error -Message $message
    }

    $removedInstalled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $removedProvisioned = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($item in $Definition) {
        foreach ($requiredProperty in @('Name', 'Option', 'IgnoreErrors')) {
            if (-not $item.PSObject.Properties[$requiredProperty]) {
                throw "AppX removal definition is missing required property '$requiredProperty'."
            }
        }
        if ([string]::IsNullOrWhiteSpace([string]$item.Name)) {
            throw 'AppX removal definition Name cannot be empty.'
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$item.Option) -and
            -not (Test-AtlasOption -Name ([string]$item.Option))) {
            Write-AtlasLog -Message "Skipped AppX family '$($item.Name)' because option '$($item.Option)' is not selected."
            continue
        }

        $activeDefinitions.Add($item)
        Write-AtlasLog -Message "Removing AppX family '$($item.Name)'."

        $installedMatches = @($installedInventory | Where-Object {
                Test-AtlasAppxFamilyMatch -Package $_ -Name ([string]$item.Name)
            })
        foreach ($package in @(Get-AtlasAppxParentInstalledPackage -Package $installedMatches)) {
            $fullNameProperty = $package.PSObject.Properties['PackageFullName']
            $fullName = if ($fullNameProperty) { [string]$fullNameProperty.Value } else { $null }
            if ([string]::IsNullOrWhiteSpace($fullName)) {
                Add-AtlasAppxRemovalFailure -Failures $failures -Definition $item `
                    -Message 'An installed match did not expose PackageFullName.'
                continue
            }
            if (-not $removedInstalled.Add($fullName)) {
                continue
            }

            try {
                Remove-AppxPackage -Package $fullName -AllUsers -Confirm:$false -ErrorAction Stop
                Write-AtlasLog -Message "Removed installed AppX package '$fullName' for all users."
            }
            catch {
                Write-AtlasLog -Message `
                    "Installed AppX removal command reported an error for '$fullName'; deferring to final inventory: $($_.Exception.Message)"
            }
        }

        foreach ($package in @($provisionedInventory | Where-Object {
                    Test-AtlasAppxFamilyMatch -Package $_ -Name ([string]$item.Name)
                })) {
            $packageNameProperty = $package.PSObject.Properties['PackageName']
            $packageName = if ($packageNameProperty) { [string]$packageNameProperty.Value } else { $null }
            if ([string]::IsNullOrWhiteSpace($packageName)) {
                Add-AtlasAppxRemovalFailure -Failures $failures -Definition $item `
                    -Message 'A provisioned match did not expose PackageName.'
                continue
            }
            if (-not $removedProvisioned.Add($packageName)) {
                continue
            }

            try {
                Remove-AppxProvisionedPackage -PackageName $packageName -Online -AllUsers `
                    -ErrorAction Stop | Out-Null
                Write-AtlasLog -Message "Removed provisioned AppX package '$packageName'."
            }
            catch {
                Write-AtlasLog -Message `
                    "Provisioned AppX removal command reported an error for '$packageName'; deferring to final inventory: $($_.Exception.Message)"
            }
        }
    }

    # Re-inventory after every removal attempt. A cmdlet returning without a terminating
    # error is not enough evidence that registration/provisioning state actually changed.
    try {
        $remainingInstalled = @(Get-AtlasAppxInstalledInventory)
    }
    catch {
        $remainingInstalled = @()
        $message = "Installed-package verification failed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Error -Message $message
    }

    try {
        $remainingProvisioned = @(Get-AtlasAppxProvisionedInventory)
    }
    catch {
        $remainingProvisioned = @()
        $message = "Provisioned-package verification failed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Error -Message $message
    }

    foreach ($item in $activeDefinitions) {
        $installedMatches = @($remainingInstalled | Where-Object {
                Test-AtlasAppxFamilyMatch -Package $_ -Name ([string]$item.Name)
            })
        if ($installedMatches.Count -gt 0) {
            Add-AtlasAppxRemovalFailure -Failures $failures -Definition $item `
                -Message "$($installedMatches.Count) installed package(s) remain registered."
        }

        $provisionedMatches = @($remainingProvisioned | Where-Object {
                Test-AtlasAppxFamilyMatch -Package $_ -Name ([string]$item.Name)
            })
        if ($provisionedMatches.Count -gt 0) {
            Add-AtlasAppxRemovalFailure -Failures $failures -Definition $item `
                -Message "$($provisionedMatches.Count) provisioned package(s) remain."
        }
    }

    if ($failures.Count -gt 0) {
        throw "AppX removal completed with $($failures.Count) required failure(s): $($failures -join ' | ')"
    }
}
