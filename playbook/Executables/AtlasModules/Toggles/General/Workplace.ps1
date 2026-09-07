function Hide-AtlasWorkplaceSettingsPage {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation hide -Page workplace
}

function Show-AtlasWorkplaceSettingsPage {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation unhide -Page workplace

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Opening Settings > Accounts > Access work or school...'
        Start-Process 'ms-settings:workplace'
    }
}
