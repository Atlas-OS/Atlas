function Add-AtlasRunWithPriorityContextMenu {
    param($Toggle)

    $priorityRoot = 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'
    $shellRoot = "$priorityRoot\ExtendedSubCommandsKey\Shell"
    # The verb lives under the machine HKCR view (HKLM\SOFTWARE\Classes). Its command is
    # stored as an expandable string so %SystemRoot% is resolved by the shell at launch
    # time, and the one template is formatted once per priority submenu entry.
    $commandTemplate = '"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SystemRoot%\AtlasModules\Scripts\Operations\Invoke-AtlasPriorityLaunch.ps1" -Priority "{0}" -TargetPath "%1"'
    $menuEntries = @(
        @{ Key = '001flyout'; Label = 'Realtime'; Priority = 'Realtime' }
        @{ Key = '002flyout'; Label = 'High'; Priority = 'High' }
        @{ Key = '003flyout'; Label = 'Above normal'; Priority = 'AboveNormal' }
        @{ Key = '004flyout'; Label = 'Normal'; Priority = 'Normal' }
        @{ Key = '005flyout'; Label = 'Below normal'; Priority = 'BelowNormal' }
        @{ Key = '006flyout'; Label = 'Low'; Priority = 'Low' }
    )

    Remove-AtlasRegistryKey -Path $priorityRoot
    Set-AtlasRegistryValue -Path $priorityRoot `
        -Name 'MUIVerb' -Type String -Data 'Run with priority'
    Set-AtlasRegistryValue -Path $priorityRoot `
        -Name 'MultiSelectModel' -Type String -Data 'Single'

    foreach ($entry in $menuEntries) {
        $menuPath = "$shellRoot\$($entry.Key)"
        Set-AtlasRegistryValue -Path $menuPath `
            -Name 'MUIVerb' -Type String -Data $entry.Label
        Set-AtlasRegistryValue -Path "$menuPath\command" `
            -Name '' -Type ExpandString `
            -Data ($commandTemplate -f $entry.Priority)
    }
    [void]$Toggle
}
