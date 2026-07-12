BeforeAll {
    $script:scriptsRoot = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts'
    $script:implementationPath = Join-Path $script:scriptsRoot 'Internal\Set-FileAssociations.ps1'
    $script:definitionPath = Join-Path $script:scriptsRoot 'Tweaks\scripts\set-file-associations.psd1'

    . $script:implementationPath -PlanOnly | Out-Null
}

Describe 'File associations' {
    It 'runs as the non-elevated user and skips OOBE' {
        $definition = Import-PowerShellDataFile -LiteralPath $script:definitionPath

        $definition.RunAs | Should -BeExactly 'User'
        $definition.Oobe | Should -BeFalse
    }

    It 'rejects an unknown profile before applying changes' {
        { & $script:implementationPath -AssociationProfile 'Unknown Browser' -PlanOnly } |
            Should -Throw '*ValidateSet*'
    }

    It 'leaves protected browser defaults to Windows' {
        $plan = & $script:implementationPath -AssociationProfile Firefox -PlanOnly

        $plan.Mode | Should -BeExactly 'PlanOnly'
        $plan.Profile | Should -BeExactly 'Firefox'
        $plan.BrowserDefaultRequested | Should -BeTrue
        $plan.BrowserDefaultDisposition | Should -BeExactly 'WindowsProtectedUserActionRequired'
        $plan.DefaultAppsSettingsUri | Should -BeExactly 'ms-settings:defaultapps'
        @($plan.Changes | Where-Object Hive -ne 'CurrentUser').Count | Should -Be 0
        @($plan.Changes | Where-Object Value -Match 'Brave|Firefox|Chrome|LibreWolf|Edge').Count | Should -Be 0
    }

    It 'maps every registered 7-Zip archive handler to OpenWithProgids' {
        Mock Test-MachineClassRegistration { $true }

        $changes = @(Get-ArchiveAssociationChanges)
        $handlers = @($changes | Where-Object Path -Like '*\OpenWithProgids')
        $handlers.Count | Should -Be 38
        $handlers[0].Path | Should -BeExactly 'SOFTWARE\Classes\.001\OpenWithProgids'
        $handlers[0].Name | Should -BeExactly '7-Zip.001'
        $handlers[-1].Path | Should -BeExactly 'SOFTWARE\Classes\.zip\OpenWithProgids'
        $handlers[-1].Name | Should -BeExactly '7-Zip.zip'
        @($handlers | Where-Object { $_.Value -ne '' -or $_.Kind -ne [Microsoft.Win32.RegistryValueKind]::String }).Count |
            Should -Be 0

        $options = $changes[-1]
        $options.Path | Should -BeExactly 'SOFTWARE\7-Zip\Options'
        $options.Name | Should -BeExactly 'ContextMenu'
        $options.Value | Should -Be 1073746726
        $options.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
    }

    It 'is retry-safe and propagates the first registry failure' {
        $changes = @(
            New-AssociationChange -Path 'SOFTWARE\Atlas\One' -Name A -Value '' -Kind String
            New-AssociationChange -Path 'SOFTWARE\Atlas\Two' -Name B -Value 1 -Kind DWord
        )

        Mock Set-CurrentUserRegistryValue {}
        Set-AssociationChanges -Changes $changes
        Set-AssociationChanges -Changes $changes
        Should -Invoke Set-CurrentUserRegistryValue -Times 4 -Exactly

        Mock Set-CurrentUserRegistryValue { throw 'registry write failed' }
        { Set-AssociationChanges -Changes $changes } | Should -Throw '*registry write failed*'
    }

    It 'validates the expected user SID before registry work' {
        { Assert-IntendedInteractiveUser -ExpectedUserSid 'not-a-sid' } |
            Should -Throw "*expected file-association user SID 'not-a-sid' is invalid*"
        { Assert-IntendedInteractiveUser -ExpectedUserSid 'S-1-5-21-0-0-0-1000' } |
            Should -Throw '*does not match expected SID*'
    }
}
