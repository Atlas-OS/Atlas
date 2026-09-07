function Invoke-AtlasPowerSavingToggle {
    param($Toggle)

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            $mode = 'Atlas'
            $message = 'The Atlas AC power policy is active.'
        }
        'Default' {
            $mode = 'Default'
            $message = 'The previous power plan, or Balanced when none was saved, is active and the Atlas plan was removed.'
        }
        default { throw "PowerSaving: unsupported state '$($Toggle.State)'." }
    }

    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasPowerSavingState -Mode $mode -Silent:$Toggle.Silent

    if (-not $Toggle.Silent) {
        Write-AtlasSuccess -Text $message
    }
}
