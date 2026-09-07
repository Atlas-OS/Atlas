[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars',
    '',
    Justification = 'Shell.Application doubles are COM-shaped script methods that resolve their recording state through a global variable.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    '',
    Justification = 'Mock doubles declare the parameters of the commands they shadow.'
)]
param()

BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module -Name (Join-Path -Path $script:AtlasTestModulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $script:AtlasTestModulesRoot -ChildPath 'Atlas.Shell\Atlas.Shell.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:settingsKey = "$script:testRoot\Explorer"
    $script:defaultUserKey = "$script:testRoot\DefaultUser"
    $script:taskbandKey = 'HKCU\Software\AtlasRewriteTest\Taskband'
    $script:tweaksRoot = Join-Path -Path $script:AtlasTestScriptsRoot -ChildPath 'Tweaks'

    function Get-TestRegistryValue {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -eq $item) {
            return $null
        }
        return $item.$Name
    }

    function ConvertTo-TestHexString {
        param([Parameter(Mandatory = $true)][byte[]]$Bytes)

        return (($Bytes | ForEach-Object { $_.ToString('X2') }) -join '')
    }
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasSettingsPageVisibility' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
        Mock Test-AtlasAdmin -ModuleName Atlas.Shell { $true }
        Mock Get-AtlasSettingsPageVisibilityKey -ModuleName Atlas.Shell { $script:settingsKey }
        Remove-Item -Path $script:settingsKey -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'preserves an allowlist when hiding and unhiding one page including an empty list' {
        New-Item -Path $script:settingsKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:settingsKey -Name SettingsPageVisibility -Value 'showonly:printers;windowsupdate' -Type String
        Set-AtlasSettingsPageVisibility -Operation hide -Page printers -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility | Should -Be 'showonly:windowsupdate'
        Set-AtlasSettingsPageVisibility -Operation hide -Page windowsupdate -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility | Should -Be 'showonly:'
        Set-AtlasSettingsPageVisibility -Operation unhide -Page printers -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility | Should -Be 'showonly:printers'
    }

    It 'requires an administrator token' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Shell { $false }

        { Set-AtlasSettingsPageVisibility -Operation hide -Page windowsupdate -NoProcessCleanup } |
            Should -Throw '*Administrator rights*'
        Test-Path -LiteralPath $script:settingsKey | Should -BeFalse
    }

    It 'rejects a page that is not a canonical identifier' {
        { Set-AtlasSettingsPageVisibility -Operation hide -Page 'Windows Update' -NoProcessCleanup } |
            Should -Throw '*canonical page identifier*'
        { Set-AtlasSettingsPageVisibility -Operation hide -Page ('a' * 257) -NoProcessCleanup } |
            Should -Throw '*canonical page identifier*'
    }

    It 'hides pages cumulatively under the hide: prefix without duplicates' {
        Set-AtlasSettingsPageVisibility -Operation hide -Page windowsupdate -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility |
            Should -BeExactly 'hide:windowsupdate'

        Set-AtlasSettingsPageVisibility -Operation hide -Page printers -NoProcessCleanup
        Set-AtlasSettingsPageVisibility -Operation hide -Page windowsupdate -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility |
            Should -BeExactly 'hide:windowsupdate;printers'
    }

    It 'unhides one page and removes the value with the last page' {
        New-Item -Path $script:settingsKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:settingsKey -Name SettingsPageVisibility `
            -Value 'hide:privacy-location;findmydevice' -Type String

        Set-AtlasSettingsPageVisibility -Operation unhide -Page privacy-location -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility |
            Should -BeExactly 'hide:findmydevice'

        Set-AtlasSettingsPageVisibility -Operation unhide -Page findmydevice -NoProcessCleanup
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility |
            Should -BeNullOrEmpty

        { Set-AtlasSettingsPageVisibility -Operation unhide -Page findmydevice -NoProcessCleanup } |
            Should -Not -Throw
    }

    It 'refuses to rewrite a value of an unexpected kind' {
        New-Item -Path $script:settingsKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $script:settingsKey -Name SettingsPageVisibility -Value 1 -Type DWord

        { Set-AtlasSettingsPageVisibility -Operation hide -Page printers -NoProcessCleanup } |
            Should -Throw '*unsupported registry value kind*'
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility | Should -Be 1
    }

    It 'closes only Settings in the caller session, and none when cleanup is suppressed' {
        Mock Get-Process -ModuleName Atlas.Shell {
            $currentSession = [Diagnostics.Process]::GetCurrentProcess().SessionId
            [pscustomobject]@{ ProcessName = 'SystemSettings'; Id = 4101; SessionId = $currentSession }
            [pscustomobject]@{ ProcessName = 'explorer'; Id = 4102; SessionId = $currentSession }
            [pscustomobject]@{ ProcessName = 'SystemSettings'; Id = 4103; SessionId = $currentSession + 1 }
        }
        Mock Stop-Process -ModuleName Atlas.Shell

        Set-AtlasSettingsPageVisibility -Operation hide -Page printers
        Should -Invoke Stop-Process -ModuleName Atlas.Shell -Times 1 -Exactly
        Should -Not -Invoke Stop-Process -ModuleName Atlas.Shell -ParameterFilter { $InputObject.Id -eq 4103 }

        Set-AtlasSettingsPageVisibility -Operation unhide -Page printers -NoProcessCleanup
        Should -Invoke Get-Process -ModuleName Atlas.Shell -Times 1 -Exactly
        Should -Invoke Stop-Process -ModuleName Atlas.Shell -Times 1 -Exactly
    }

    It 'reports a Settings window that will not close without failing the change' {
        Mock Get-Process -ModuleName Atlas.Shell {
            [pscustomobject]@{ ProcessName = 'SystemSettings'; Id = 4101; SessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId }
        }
        Mock Stop-Process -ModuleName Atlas.Shell { throw 'access denied' }

        { Set-AtlasSettingsPageVisibility -Operation hide -Page printers } | Should -Not -Throw
        Get-TestRegistryValue -Path $script:settingsKey -Name SettingsPageVisibility |
            Should -BeExactly 'hide:printers'
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*4101*access denied*'
        }
    }
}

Describe 'Set-AtlasFileAssociations' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
    }

    It 'rejects an unknown profile before planning' {
        { Set-AtlasFileAssociations -AssociationProfile 'Unknown Browser' -PlanOnly } |
            Should -Throw '*ValidateSet*'
    }

    It 'leaves protected browser defaults to Windows' {
        $plan = Set-AtlasFileAssociations -AssociationProfile Firefox -PlanOnly

        $plan.Mode | Should -BeExactly 'PlanOnly'
        $plan.Profile | Should -BeExactly 'Firefox'
        $plan.BrowserDefaultRequested | Should -BeTrue
        $plan.BrowserDefaultDisposition | Should -BeExactly 'WindowsProtectedUserActionRequired'
        $plan.DefaultAppsSettingsUri | Should -BeExactly 'ms-settings:defaultapps'
        @($plan.Changes | Where-Object Hive -ne 'CurrentUser').Count | Should -Be 0
        @($plan.Changes | Where-Object Value -Match 'Brave|Firefox|Chrome|LibreWolf|Edge').Count | Should -Be 0
    }

    It 'maps every registered 7-Zip archive handler to OpenWithProgids' {
        Mock Test-AtlasMachineClassRegistration -ModuleName Atlas.Shell { $true }

        $changes = @((Set-AtlasFileAssociations -PlanOnly).Changes)
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

    It 'plans nothing when no 7-Zip handler is registered on the machine' {
        Mock Test-AtlasMachineClassRegistration -ModuleName Atlas.Shell { $false }

        @((Set-AtlasFileAssociations -PlanOnly).Changes).Count | Should -Be 0
    }

    It 'applies every planned change, is retry-safe and propagates the first write failure' {
        Mock Test-AtlasMachineClassRegistration -ModuleName Atlas.Shell { $true }
        Mock Assert-AtlasFileAssociationUser -ModuleName Atlas.Shell
        Mock Write-AtlasFileAssociationChange -ModuleName Atlas.Shell

        $first = Set-AtlasFileAssociations
        $second = Set-AtlasFileAssociations
        $first.Mode | Should -BeExactly 'Apply'
        $second.Mode | Should -BeExactly 'Apply'
        Should -Invoke Write-AtlasFileAssociationChange -ModuleName Atlas.Shell -Times 78 -Exactly
        Should -Invoke Assert-AtlasFileAssociationUser -ModuleName Atlas.Shell -Times 2 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 0

        Mock Write-AtlasFileAssociationChange -ModuleName Atlas.Shell { throw 'registry write failed' }
        { Set-AtlasFileAssociations } | Should -Throw '*registry write failed*'
    }

    It 'warns that a requested browser default stays user-controlled' {
        Mock Test-AtlasMachineClassRegistration -ModuleName Atlas.Shell { $false }
        Mock Assert-AtlasFileAssociationUser -ModuleName Atlas.Shell

        Set-AtlasFileAssociations -AssociationProfile LibreWolf | Out-Null
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "*'LibreWolf' browser default remains user-controlled*"
        }
    }

    It 'validates the expected user SID before any registry work' {
        Mock Test-AtlasMachineClassRegistration -ModuleName Atlas.Shell { $true }
        Mock Write-AtlasFileAssociationChange -ModuleName Atlas.Shell

        { Set-AtlasFileAssociations -ExpectedUserSid 'not-a-sid' } |
            Should -Throw "*expected file-association user SID 'not-a-sid' is invalid*"
        { Set-AtlasFileAssociations -ExpectedUserSid 'S-1-5-21-0-0-0-1000' } |
            Should -Throw '*does not match expected SID*'
        Should -Invoke Write-AtlasFileAssociationChange -ModuleName Atlas.Shell -Times 0
    }

    It 'writes a planned value into the current-user hive' {
        InModuleScope Atlas.Shell {
            Write-AtlasFileAssociationChange -Change (New-AtlasFileAssociationChange `
                    -Path 'Software\AtlasRewriteTest\Assoc\.zip\OpenWithProgids' `
                    -Name '7-Zip.zip' -Value '' -Kind String)
            Write-AtlasFileAssociationChange -Change (New-AtlasFileAssociationChange `
                    -Path 'Software\AtlasRewriteTest\Assoc\Options' `
                    -Name 'ContextMenu' -Value 1073746726 -Kind DWord)
        }

        $handler = Get-Item -LiteralPath "$script:testRoot\Assoc\.zip\OpenWithProgids"
        $handler.GetValueKind('7-Zip.zip') | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        $handler.GetValue('7-Zip.zip') | Should -BeExactly ''
        Get-TestRegistryValue -Path "$script:testRoot\Assoc\Options" -Name ContextMenu |
            Should -Be 1073746726
    }
}

Describe 'Set-AtlasSendToContextMenu' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
        Mock Assert-AtlasSendToUser -ModuleName Atlas.Shell { 'S-1-5-21-1-2-3-1001' }
        Mock Get-AtlasSendToItem -ModuleName Atlas.Shell {
            [ordered]@{
                'Removable Drives'          = $null
                'Bluetooth'                 = 'C:\SendTo\Bluetooth File Transfer.lnk'
                'Desktop (create shortcut)' = 'C:\SendTo\Desktop.DeskLink'
                'Mail recipient'            = 'C:\SendTo\Mail Recipient.MAPIMail'
                'Documents'                 = 'C:\SendTo\Documents.mydocs'
            }
        }
        Mock Set-AtlasSendToItemState -ModuleName Atlas.Shell
    }

    It 'accepts exactly one selection mode' {
        { Set-AtlasSendToContextMenu -Disable @('Bluetooth') -Enable @('Documents') } |
            Should -Throw '*exactly one of*'
        { Set-AtlasSendToContextMenu -DebloatDefaults -Disable @('Bluetooth') } |
            Should -Throw '*exactly one of*'
        Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 0
    }

    It 'disables the documented default items and skips absent ones' {
        Set-AtlasSendToContextMenu -DebloatDefaults

        Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 3 -Exactly -ParameterFilter {
            $Enabled -eq $false
        }
        foreach ($expected in @('Documents', 'Mail recipient', 'Bluetooth')) {
            Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
                $Name -ceq $expected -and $Enabled -eq $false
            }
        }
        Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 0 -ParameterFilter {
            $Name -ceq 'Desktop (create shortcut)' -or $Name -ceq 'Removable Drives'
        }
    }

    It 'enables a selected item through its recorded path' {
        Set-AtlasSendToContextMenu -Enable @('Bluetooth')

        Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'Bluetooth' -and $Path -eq 'C:\SendTo\Bluetooth File Transfer.lnk' -and $Enabled -eq $true
        }
    }

    It 'binds the registry engine to the caller-supplied user SID' {
        Set-AtlasSendToContextMenu -Disable @('Documents') -ExpectedUserSid 'S-1-5-21-1-2-3-1001'

        Should -Invoke Assert-AtlasSendToUser -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $ExpectedUserSid -eq 'S-1-5-21-1-2-3-1001'
        }
    }

    It 'rejects an unknown selector before changing anything' {
        { Set-AtlasSendToContextMenu -Disable @('Typo') } |
            Should -Throw '*Unsupported Send-To item selector*'
        Should -Invoke Set-AtlasSendToItemState -ModuleName Atlas.Shell -Times 0
    }

    It 'resolves known names and wildcard selectors in stable order' {
        InModuleScope Atlas.Shell {
            $known = [string[]]@('Bluetooth', 'Mail recipient', 'Documents')
            @(Resolve-AtlasSendToSelectorName -Selector @('Mail*', 'Bluetooth', 'Mail*') -KnownName $known) |
                Should -Be @('Mail recipient', 'Bluetooth')
            { Resolve-AtlasSendToSelectorName -Selector @() -KnownName @('Documents') } |
                Should -Throw '*cannot be empty*'
            { Resolve-AtlasSendToSelectorName -Selector @(' ') -KnownName @('Documents') } |
                Should -Throw '*cannot be empty or whitespace*'
        }
    }

    It 'interprets the multichoice output as cancel, disable-all or an enabled set' {
        InModuleScope Atlas.Shell {
            $cancelled = ConvertFrom-AtlasSendToChoice -Output @() -AvailableName @('Documents') -DisableAllChoice '[all]'
            $cancelled.Cancelled | Should -BeTrue
            @($cancelled.Enabled).Count | Should -Be 0
            (ConvertFrom-AtlasSendToChoice -Output @('') -AvailableName @('Documents') -DisableAllChoice '[all]').Cancelled |
                Should -BeTrue

            $none = ConvertFrom-AtlasSendToChoice -Output @('[all]') -AvailableName @('Documents', 'Bluetooth') -DisableAllChoice '[all]'
            $none.Cancelled | Should -BeFalse
            @($none.Enabled).Count | Should -Be 0

            $some = ConvertFrom-AtlasSendToChoice -Output @('Documents;Bluetooth') -AvailableName @('Documents', 'Bluetooth') -DisableAllChoice '[all]'
            $some.Enabled | Should -Be @('Documents', 'Bluetooth')

            { ConvertFrom-AtlasSendToChoice -Output @('Documents;[all]') -AvailableName @('Documents') -DisableAllChoice '[all]' } |
                Should -Throw '*cannot be combined*'
            { ConvertFrom-AtlasSendToChoice -Output @('Unknown') -AvailableName @('Documents') -DisableAllChoice '[all]' } |
                Should -Throw '*unsupported item*'
            { ConvertFrom-AtlasSendToChoice -Output @('Documents;Documents') -AvailableName @('Documents') -DisableAllChoice '[all]' } |
                Should -Throw '*duplicate item*'
            { ConvertFrom-AtlasSendToChoice -Output @('a', 'b') -AvailableName @('a') -DisableAllChoice '[all]' } |
                Should -Throw '*2 output lines*'
        }
    }

}

Describe 'Send-To item state' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
    }

    It 'hides and unhides a Send-To file through its hidden attribute' {
        $fixture = Join-Path $TestDrive 'Mail Recipient.MAPIMail'
        [IO.File]::WriteAllText($fixture, 'fixture')

        InModuleScope Atlas.Shell -Parameters @{ Fixture = $fixture } {
            Set-AtlasSendToItemState -Name 'Mail recipient' -Path $Fixture -Enabled $false
            ((Get-Item -LiteralPath $Fixture -Force).Attributes -band [IO.FileAttributes]::Hidden) |
                Should -Be ([IO.FileAttributes]::Hidden)

            Set-AtlasSendToItemState -Name 'Mail recipient' -Path $Fixture -Enabled $true
            ((Get-Item -LiteralPath $Fixture -Force).Attributes -band [IO.FileAttributes]::Hidden) |
                Should -Be 0
        }
    }

    It 'uses the removable-drive policy for its registry-backed item' {
        Mock Set-AtlasRegistryValue -ModuleName Atlas.Shell
        Mock Remove-AtlasRegistryValue -ModuleName Atlas.Shell

        InModuleScope Atlas.Shell {
            Set-AtlasSendToItemState -Name 'Removable Drives' -Path $null -Enabled $false
            Set-AtlasSendToItemState -Name 'Removable Drives' -Path $null -Enabled $true
        }

        Should -Invoke Set-AtlasRegistryValue -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -and
            $Name -eq 'NoDrivesInSendToMenu' -and $Type -eq 'DWord' -and $Data -eq 1
        }
        Should -Invoke Remove-AtlasRegistryValue -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -and
            $Name -eq 'NoDrivesInSendToMenu'
        }
    }
}

Describe 'Shell context-menu argument helpers' {
    It 'quotes <Name> using Windows argv rules' -TestCases @(
        @{ Name = 'an empty value'; Value = ''; Expected = '""' }
        @{ Name = 'a drive root'; Value = 'C:\'; Expected = '"C:\\"' }
        @{ Name = 'a UNC root'; Value = '\\server\share\'; Expected = '"\\server\share\\"' }
        @{
            Name = 'spaces and a trailing separator'
            Value = 'C:\folder with spaces\'
            Expected = '"C:\folder with spaces\\"'
        }
        @{
            Name = 'an embedded quote'
            Value = 'synthetic\value"with-quote\'
            Expected = '"synthetic\value\"with-quote\\"'
        }
    ) {
        ConvertTo-AtlasShellWindowsArgument -Value $Value | Should -BeExactly $Expected
    }

    It 'refuses an argument beyond the Windows command-line boundary' {
        { ConvertTo-AtlasShellWindowsArgument -Value ('a' * 32768) } |
            Should -Throw '*command-line length boundary*'
    }

    It 'builds non-recursive and recursive native ownership arguments' {
        $file = Get-AtlasTakeOwnershipArgumentPlan -TargetType File -TargetPath 'C:\file.txt'
        $directory = Get-AtlasTakeOwnershipArgumentPlan -TargetType Directory -TargetPath 'C:\directory' -YesChoice 'Y'
        $drive = Get-AtlasTakeOwnershipArgumentPlan -TargetType Drive -TargetPath 'C:\' -YesChoice 'Y'

        $file.TakeOwnArguments | Should -Be @('/f', 'C:\file.txt')
        $file.IcaclsArguments | Should -Contain '/l'
        foreach ($plan in @($directory, $drive)) {
            $plan.TakeOwnArguments | Should -Contain '/r'
            $plan.TakeOwnArguments | Should -Contain '/SKIPSL'
            $plan.IcaclsArguments | Should -Contain '/l'
        }
        $directory.IcaclsArguments | Should -Contain '/q'
        $drive.IcaclsArguments | Should -Not -Contain '/q'
        { Get-AtlasTakeOwnershipArgumentPlan -TargetType Directory -TargetPath 'C:\directory' } |
            Should -Throw '*localized affirmative choice*'
    }

    It 'accepts a tree without reparse points' {
        $root = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'plain-tree')
        [void](New-Item -ItemType Directory -Path (Join-Path $root.FullName 'child'))
        [IO.File]::WriteAllText((Join-Path $root.FullName 'child\file.txt'), 'x')

        { Assert-AtlasTakeOwnershipTree -RootPath $root.FullName } | Should -Not -Throw
    }

    It 'rejects a descendant junction without traversing it' {
        $root = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'ownership-tree')
        $target = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'junction-target')
        $junctionPath = Join-Path $root.FullName 'junction'
        [void](New-Item -ItemType Junction -Path $junctionPath -Target $target.FullName)

        try {
            { Assert-AtlasTakeOwnershipTree -RootPath $root.FullName } |
                Should -Throw '*descendant reparse point*'
        }
        finally {
            Remove-Item -LiteralPath $junctionPath -Force
        }
    }
}

Describe 'Set-AtlasStartLayout' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
        Mock Get-AtlasStartDefaultUserKey -ModuleName Atlas.Shell { $script:defaultUserKey }
        Mock Get-AtlasStartWindowsVersion -ModuleName Atlas.Shell {
            [pscustomobject]@{ Build = 26100; Revision = 4770 }
        }
        $script:layoutPath = Join-Path $TestDrive 'StartLayout.json'
        Mock Get-AtlasStartLayoutPath -ModuleName Atlas.Shell { $script:layoutPath }
        Set-Content -LiteralPath $script:layoutPath -Encoding UTF8 -Value @'
{ "applyOnce": true, "pinnedList": [ { "packagedAppId": "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" } ] }
'@
        Remove-Item -Path $script:defaultUserKey -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'accepts the shipped Start layout' {
        Mock Get-AtlasStartLayoutPath -ModuleName Atlas.Shell {
            Join-Path -Path $script:AtlasTestRepoRoot -ChildPath 'playbook\Executables\AtlasModules\Other\StartLayout.json'
        }

        { Set-AtlasStartLayout } | Should -Not -Throw
    }

    It 'requires a layout that applies once with at least one pin' {
        Set-Content -LiteralPath $script:layoutPath -Encoding UTF8 -Value '{ "applyOnce": false, "pinnedList": [ { } ] }'
        { Set-AtlasStartLayout } | Should -Throw '*must apply once*'

        Set-Content -LiteralPath $script:layoutPath -Encoding UTF8 -Value '{ "applyOnce": true, "pinnedList": [] }'
        { Set-AtlasStartLayout } | Should -Throw '*must apply once*'

        Set-Content -LiteralPath $script:layoutPath -Encoding UTF8 -Value '{ not json'
        { Set-AtlasStartLayout } | Should -Throw '*Start layout is invalid*'

        Remove-Item -LiteralPath $script:layoutPath -Force
        { Set-AtlasStartLayout } | Should -Throw '*Start layout is missing*'
    }

    It 'removes the default Start advertisements from the default-user hive' {
        $startKey = "$script:defaultUserKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start"
        New-Item -Path $startKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $startKey -Name Config -Value ([byte[]]@(1, 2, 3)) -Type Binary
        Set-ItemProperty -LiteralPath $startKey -Name Other -Value 1 -Type DWord

        Set-AtlasStartLayout

        Get-TestRegistryValue -Path $startKey -Name Config | Should -BeNullOrEmpty
        Get-TestRegistryValue -Path $startKey -Name Other | Should -Be 1
        { Set-AtlasStartLayout } | Should -Not -Throw
    }

    It 'reports policy support on a serviced build and warns on an older one' {
        Set-AtlasStartLayout
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Message -like '*support detected on OS build 26100.4770*'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 0 -ParameterFilter { $Level -eq 'Warning' }

        Mock Get-AtlasStartWindowsVersion -ModuleName Atlas.Shell {
            [pscustomobject]@{ Build = 26100; Revision = 4769 }
        }
        Set-AtlasStartLayout
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*26100.4769*' -and $Message -like '*26100.4770*'
        }
    }

    It 'names the exact build boundary that introduced the 24H2 GPO' {
        InModuleScope Atlas.Shell {
            Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4769 | Should -BeFalse
            Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4770 | Should -BeTrue
            Test-AtlasStartPinPolicySupported -Build 26100 -Revision 9000 | Should -BeTrue
            Test-AtlasStartPinPolicySupported -Build 26200 -Revision 1 | Should -BeTrue
            Test-AtlasStartPinPolicySupported -Build 22631 -Revision 9999 | Should -BeFalse
        }
    }
}

Describe 'Set-AtlasTaskbarPins' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
        Mock Test-AtlasTaskbarExecutable -ModuleName Atlas.Shell { $true }
        Mock Stop-Process -ModuleName Atlas.Shell
        Mock Start-Sleep -ModuleName Atlas.Shell
        $script:appData = Join-Path $TestDrive 'AppData'
        Remove-Item -LiteralPath $script:appData -Recurse -Force -ErrorAction SilentlyContinue
        $script:profileAppData = $script:appData
        $script:taskBarFolder = Join-Path $script:appData 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
        New-Item -Path $script:taskBarFolder -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:taskBarFolder 'Stale.lnk'), 'stale')
        Mock Get-AtlasTaskbarProfileTarget -ModuleName Atlas.Shell {
            [pscustomobject]@{
                Sid         = 'S-1-5-21-1-2-3-1001'
                AppData     = $script:profileAppData
                RegistryKey = $script:taskbandKey
            }
        }
        $script:stagedShortcuts = [Collections.Generic.List[string]]::new()
        Mock New-AtlasShortcut -ModuleName Atlas.Shell {
            $script:stagedShortcuts.Add($Destination)
            [IO.File]::WriteAllText($Destination, "shortcut to $Source")
        }
        Remove-Item -Path "$script:testRoot\Taskband" -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'replaces the pin folder with File Explorer plus the selected browser and writes the Taskband values' {
        Set-AtlasTaskbarPins -Browser 'Brave' -NoExplorerStop

        @(Get-ChildItem -LiteralPath $script:taskBarFolder | ForEach-Object { $_.Name } | Sort-Object) |
            Should -Be @('Brave.lnk', 'File Explorer.lnk')
        $table = InModuleScope Atlas.Shell { Get-AtlasTaskbarShortcutTable }
        ConvertTo-TestHexString -Bytes (Get-TestRegistryValue -Path "$script:testRoot\Taskband" -Name Favorites) |
            Should -Be $table['Brave'].RegFavorites
        ConvertTo-TestHexString -Bytes (Get-TestRegistryValue -Path "$script:testRoot\Taskband" -Name FavoritesResolve) |
            Should -Be $table['Brave'].RegFavoritesResolve
        Should -Invoke New-AtlasShortcut -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Destination -like '*\File Explorer.lnk' -and $AppUserModelId -eq 'Microsoft.Windows.Explorer'
        }
        Should -Invoke New-AtlasShortcut -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Destination -like '*\Brave.lnk' -and $Source -eq $table['Brave'].Path
        }
        Should -Invoke Stop-Process -ModuleName Atlas.Shell -Times 0
    }

    It 'falls back to Microsoft Edge and then to File Explorer alone' {
        Mock Test-AtlasTaskbarExecutable -ModuleName Atlas.Shell { $Path -like '*\msedge.exe' }
        Set-AtlasTaskbarPins -Browser 'Firefox' -NoExplorerStop

        @(Get-ChildItem -LiteralPath $script:taskBarFolder | ForEach-Object { $_.Name } | Sort-Object) |
            Should -Be @('File Explorer.lnk', 'Microsoft Edge.lnk')
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match "'Firefox' is not installed"
        }

        Mock Test-AtlasTaskbarExecutable -ModuleName Atlas.Shell { $false }
        Set-AtlasTaskbarPins -Browser 'Unknown Browser' -NoExplorerStop

        @(Get-ChildItem -LiteralPath $script:taskBarFolder | ForEach-Object { $_.Name }) |
            Should -Be @('File Explorer.lnk')
        $table = InModuleScope Atlas.Shell { Get-AtlasTaskbarShortcutTable }
        ConvertTo-TestHexString -Bytes (Get-TestRegistryValue -Path "$script:testRoot\Taskband" -Name Favorites) |
            Should -Be $table['File Explorer'].RegFavorites
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match "'Unknown Browser' is not a supported taskbar pin"
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match 'Microsoft Edge is not installed'
        }
    }

    It 'stops Explorer around the replacement unless suppressed' {
        Set-AtlasTaskbarPins

        Should -Invoke Stop-Process -ModuleName Atlas.Shell -Times 2 -Exactly -ParameterFilter {
            $Name -eq 'explorer' -and $Force
        }
    }

    It 'skips a profile without an AppData directory and still removes its staging directory' {
        $script:profileAppData = Join-Path $TestDrive 'missing-appdata'

        Set-AtlasTaskbarPins -NoExplorerStop

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Shell -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*skipping taskbar pin cleanup*'
        }
        Test-Path -LiteralPath "$script:testRoot\Taskband" | Should -BeFalse
        (Get-ChildItem -LiteralPath $script:taskBarFolder).Name | Should -Be 'Stale.lnk'
        $script:stagedShortcuts.Count | Should -BeGreaterThan 0
        foreach ($staged in $script:stagedShortcuts) {
            Test-Path -LiteralPath (Split-Path -Parent $staged) | Should -BeFalse
        }
    }

    It 'removes the staging directory even when a Taskband write fails' {
        Mock Invoke-AtlasTaskbarRegistryWrite -ModuleName Atlas.Shell { throw 'reg.exe failed' }

        { Set-AtlasTaskbarPins -NoExplorerStop } | Should -Throw '*reg.exe failed*'
        foreach ($staged in $script:stagedShortcuts) {
            Test-Path -LiteralPath (Split-Path -Parent $staged) | Should -BeFalse
        }
    }

    It 'turns a native reg.exe failure into a terminating error' {
        $fakeReg = Join-Path $TestDrive 'reg-failure.cmd'
        Set-Content -LiteralPath $fakeReg -Value '@exit /b 5'

        InModuleScope Atlas.Shell -Parameters @{ RegExe = $fakeReg } {
            { Invoke-AtlasTaskbarRegistryWrite -RegExe $RegExe -RegistryKey 'HKCU\Test' -Name Favorites -Data '00' } |
                Should -Throw '*exit code 5*'
        }
    }

    It 'passes the exact reg.exe add arguments for a binary value' {
        $fakeReg = Join-Path $TestDrive 'reg-capture.cmd'
        $captured = Join-Path $TestDrive 'reg-capture.txt'
        Set-Content -LiteralPath $fakeReg -Encoding Ascii -Value @(
            "@echo %*> `"$captured`""
            '@exit /b 0'
        )

        InModuleScope Atlas.Shell -Parameters @{ RegExe = $fakeReg } {
            Invoke-AtlasTaskbarRegistryWrite -RegExe $RegExe -RegistryKey 'HKCU\Test\Taskband' -Name Favorites -Data 'FF00AB'
        }

        (Get-Content -LiteralPath $captured -Raw).Trim() |
            Should -BeExactly 'add HKCU\Test\Taskband /v Favorites /t REG_BINARY /d FF00AB /f'
    }
}

Describe 'Add-AtlasMusicVideosToHome' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Shell
        $global:AtlasShellHomeTest = @{
            Pins        = @()
            Invocations = [Collections.Generic.List[string]]::new()
            HomeMissing = $false
        }
        Mock Get-AtlasShellApplication -ModuleName Atlas.Shell {
            $shell = [pscustomobject]@{}
            $shell | Add-Member -MemberType ScriptMethod -Name Namespace -Value {
                param($Path)

                if ($Path -eq 'shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}') {
                    if ($global:AtlasShellHomeTest.HomeMissing) {
                        return $null
                    }
                    $homeNamespace = [pscustomobject]@{}
                    $homeNamespace | Add-Member -MemberType ScriptMethod -Name Items -Value {
                        @($global:AtlasShellHomeTest.Pins | ForEach-Object { [pscustomobject]@{ Path = $_ } })
                    }
                    return $homeNamespace
                }

                $self = [pscustomobject]@{ Path = $Path }
                $self | Add-Member -MemberType ScriptMethod -Name InvokeVerb -Value {
                    param($Verb)
                    $global:AtlasShellHomeTest.Invocations.Add("$Verb|$($this.Path)")
                }
                return [pscustomobject]@{ Self = $self }
            }
            return $shell
        }
        $script:homeFolders = @(
            [Environment]::GetFolderPath('MyVideos')
            [Environment]::GetFolderPath('MyMusic')
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container) }
    }

    AfterEach {
        Remove-Variable -Name AtlasShellHomeTest -Scope Global -ErrorAction SilentlyContinue
    }

    It 'pins the existing Music and Videos folders that are not pinned yet' {
        Add-AtlasMusicVideosToHome

        @($global:AtlasShellHomeTest.Invocations) |
            Should -Be @($script:homeFolders | ForEach-Object { "pintohome|$_" })
    }

    It 'leaves folders alone that Home already lists' {
        $global:AtlasShellHomeTest.Pins = @($script:homeFolders)

        Add-AtlasMusicVideosToHome

        @($global:AtlasShellHomeTest.Invocations).Count | Should -Be 0
    }

    It 'fails when the Home namespace cannot be opened' {
        $global:AtlasShellHomeTest.HomeMissing = $true

        { Add-AtlasMusicVideosToHome } | Should -Throw '*File Explorer Home namespace*'
    }
}

Describe 'Atlas.Shell tweak bindings' {
    It 'runs file associations as the non-elevated user outside OOBE' {
        $definition = Import-PowerShellDataFile -LiteralPath (Join-Path $script:tweaksRoot 'scripts\set-file-associations.psd1')

        $definition.RunAs | Should -BeExactly 'User'
        $definition.Oobe | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:tweaksRoot "scripts\$($definition.Script)") -PathType Leaf |
            Should -BeTrue
    }

    It 'runs the Send-To debloat companion as the non-elevated user outside OOBE' {
        $definition = Import-PowerShellDataFile -LiteralPath (Join-Path $script:tweaksRoot 'qol\explorer\debloat-send-to.psd1')

        $definition.Script | Should -BeExactly 'debloat-send-to.ps1'
        $definition.RunAs | Should -BeExactly 'User'
        $definition.Oobe | Should -BeFalse
        $definition.ContainsKey('Run') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:tweaksRoot 'qol\explorer\debloat-send-to.ps1') -PathType Leaf |
            Should -BeTrue
    }
}
