# Companion for the Workplace toggle: hides or shows the Access work or school page in
# Settings. Its functions run as Administrator when you run a launcher and when an update
# replays the recorded state.

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
