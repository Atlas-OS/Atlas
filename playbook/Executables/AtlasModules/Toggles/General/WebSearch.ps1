function Disable-AtlasWebSearchMachine {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation hide -Page search-permissions -NoProcessCleanup

    Import-AtlasModule -Name Atlas.Appx
    Invoke-AtlasAppxRemovalPlan -Definition @(
        [pscustomobject]@{
            Name         = 'Microsoft.BingSearch*'
            Option       = $null
            IgnoreErrors = $false
        }
    )
}

function Enable-AtlasWebSearchMachine {
    param($Toggle)

    $locationKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    $useLocation = $null
    if (-not $Toggle.Silent) {
        $useLocation = Read-AtlasYesNo -Question 'Let web search use your location for local results?'
    }
    if ($useLocation -eq $true) {
        Remove-AtlasRegistryValue -Path $locationKey -Name 'AllowSearchToUseLocation'
    }
    elseif ($useLocation -eq $false) {
        Set-AtlasRegistryValue -Path $locationKey `
            -Name 'AllowSearchToUseLocation' -Type DWord -Data 0
    }

    # Stopped search indexing shows a graphical bug in web search.
    $wsearch = Get-Service -Name wsearch -ErrorAction Stop
    if ($wsearch.Status -eq 'Stopped') {
        $enableIndexing = $false
        if (-not $Toggle.Silent) {
            Write-AtlasWarning -Text 'Search indexing is stopped, which causes a display bug in web search.'
            $enableIndexing = Read-AtlasYesNo -Question 'Turn on full search indexing to avoid it?'
        }
        if ($enableIndexing) {
            Write-AtlasStep -Text 'Enabling full search indexing...'
            Import-AtlasModule -Name Atlas.Search
            Set-AtlasIndexingMachineState -State Full -PreservePowerModes
            # Full indexing was explicitly requested and successfully applied. Keep
            # its independent record consistent so upgrade replay preserves it.
            Set-AtlasToggleState -Name Indexing -State 2 -StateRoot $Toggle.StateRoot
        }
    }

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Enabling web search and search highlights...'
    }
    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation unhide -Page search-permissions -NoProcessCleanup
}

function Enable-AtlasWebSearchUser {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Installing the Bing search provider from the Microsoft Store...'
    }
    Import-AtlasModule -Name Atlas.Download
    $wingetPath = Get-AtlasTrustedWingetPath
    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
    [void](Invoke-AtlasToggleNativeCommand `
            -FilePath $wingetPath `
            -ArgumentList ([string[]]@(
                    'install'
                    '--exact'
                    '--id'
                    '9NZBF4GT040C'
                    '--source'
                    'msstore'
                    '--uninstall-previous'
                    '--silent'
                    '--accept-source-agreements'
                    '--accept-package-agreements'
                    '--disable-interactivity'
                )) `
            -AllowedExitCodes ([int[]]@(0)))
}
