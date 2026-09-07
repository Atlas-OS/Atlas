BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Desktop-Policy.ps1')
    $script:SetupSid = 'S-1-5-21-1-2-3-1001'
}

Describe 'Fixed desktop cleanup task contract' {
    BeforeEach {
        $script:Calls = [Collections.Generic.List[object]]::new()
        $script:Action = [pscustomobject]@{ Path = ''; Arguments = '' }
        $actions = [pscustomobject]@{}
        $actions | Add-Member ScriptMethod Create { param($Type) $script:Calls.Add(@('ActionType', $Type)); return $script:Action }
        $script:Definition = [pscustomobject]@{
            RegistrationInfo = [pscustomobject]@{ Description = '' }
            Principal = [pscustomobject]@{ UserId = ''; LogonType = 0 }
            Settings = [pscustomobject]@{ AllowDemandStart = $false; DisallowStartIfOnBatteries = $true; StopIfGoingOnBatteries = $true; ExecutionTimeLimit = '' }
            Actions = $actions
        }
        $script:RegisteredTask = [pscustomobject]@{}
        $script:RegisteredTask | Add-Member ScriptMethod Run { param($Parameters) $script:Calls.Add(@('Run', $Parameters)) }
        $script:Folder = [pscustomobject]@{}
        $script:Folder | Add-Member ScriptMethod RegisterTaskDefinition {
            param($Name, $Definition, $Flags, $User, [securestring]$Password, $Logon, $Sddl)
            $script:Registration = [pscustomobject]@{ Name=$Name; Definition=$Definition; Flags=$Flags; User=$User; Password=$Password; Logon=$Logon; Sddl=$Sddl }
        }
        $script:Folder | Add-Member ScriptMethod GetTask { param($Name) $script:Calls.Add(@('GetTask', $Name)); return $script:RegisteredTask }
        $script:Folder | Add-Member ScriptMethod DeleteTask { param($Name, $Flags) $script:Calls.Add(@('DeleteTask', $Name, $Flags)) }
        $script:Service = [pscustomobject]@{}
        $script:Service | Add-Member ScriptMethod Connect {}
        $script:Service | Add-Member ScriptMethod NewTask { param($Flags) $script:Calls.Add(@('NewTask', $Flags)); return $script:Definition }
        $script:Service | Add-Member ScriptMethod GetFolder { param($Path) $script:Calls.Add(@('Folder', $Path)); return $script:Folder }
        Mock New-Object { $script:Service } -ParameterFilter { $ComObject -eq 'Schedule.Service' }
    }

    It 'registers a create-only SYSTEM action with no caller-supplied command substitution' {
        $root = Join-Path $TestDrive 'Protected Setup'
        Register-AtlasDesktopCleanup -Sid $script:SetupSid -Root $root
        $script:Registration.Name | Should -Be ('AtlasOS ISO desktop cleanup ' + $script:SetupSid)
        $script:Registration.Flags | Should -Be 2
        $script:Registration.User | Should -Be 'S-1-5-18'
        $script:Registration.Logon | Should -Be 5
        $script:Registration.Password | Should -BeNullOrEmpty
        $script:Definition.Principal.UserId | Should -Be 'S-1-5-18'
        $script:Definition.Settings.AllowDemandStart | Should -BeTrue
        $script:Definition.Settings.DisallowStartIfOnBatteries | Should -BeFalse
        $script:Definition.Settings.StopIfGoingOnBatteries | Should -BeFalse
        $script:Definition.Settings.ExecutionTimeLimit | Should -Be 'PT1M'
        $script:Action.Path | Should -Be (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe')
        $script:Action.Arguments | Should -Be ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $root 'Setup.ps1') + '" -RestoreDesktopPolicy')
        $script:Action.Arguments | Should -Not -Match '\$\(Arg'
    }

    It 'allows the setup account to read and run, without changing or deleting the task' {
        Register-AtlasDesktopCleanup -Sid $script:SetupSid -Root $TestDrive
        $descriptor = [Security.AccessControl.RawSecurityDescriptor]::new($script:Registration.Sddl)
        $descriptor.Owner.Value | Should -Be 'S-1-5-32-544'
        $rules = @($descriptor.DiscretionaryAcl | Where-Object { $_.SecurityIdentifier.Value -eq $script:SetupSid })
        $rules | Should -HaveCount 1
        $mask = $rules[0].AccessMask
        ($mask -band 0x40000000) | Should -Be 0 # GENERIC_WRITE
        ($mask -band 0x00010000) | Should -Be 0 # DELETE
        ($mask -band 0x00040000) | Should -Be 0 # WRITE_DAC
        ($mask -band 0x00080000) | Should -Be 0 # WRITE_OWNER
        ($mask -band 0x20000000) | Should -Not -Be 0 # GENERIC_EXECUTE
        @($descriptor.DiscretionaryAcl | ForEach-Object { $_.SecurityIdentifier.Value } | Sort-Object) | Should -Be @('S-1-5-18', 'S-1-5-21-1-2-3-1001', 'S-1-5-32-544')
    }

    It 'requests only the matching task with no runtime parameters' {
        Request-AtlasDesktopCleanup -Sid $script:SetupSid
        $get = @($script:Calls | Where-Object { $_[0] -eq 'GetTask' })
        $get[0][1] | Should -Be ('AtlasOS ISO desktop cleanup ' + $script:SetupSid)
        $run = @($script:Calls | Where-Object { $_[0] -eq 'Run' })
        $run | Should -HaveCount 1
        $run[0][1] | Should -BeNullOrEmpty
        Unregister-AtlasDesktopCleanup -Sid $script:SetupSid
        $delete = @($script:Calls | Where-Object { $_[0] -eq 'DeleteTask' })
        $delete[0][1] | Should -Be ('AtlasOS ISO desktop cleanup ' + $script:SetupSid)
        $delete[0][2] | Should -Be 0
    }
}

Describe 'Owned policy value cleanup' {
    BeforeEach {
        $script:PolicyPath = 'Software\AtlasDesktopPolicyTests\' + [guid]::NewGuid().ToString('N')
        $script:Key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:PolicyPath)
        $script:Key.SetValue('UnrelatedPolicy', 17)
        $script:AclBefore = $script:Key.GetAccessControl().GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access)
    }
    AfterEach {
        $script:Key.Dispose()
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:PolicyPath, $false)
    }
    It 'removes only its exact shell while preserving unrelated values and the DACL' -TestCases @(
        @{ Existing = 'owned shell'; Expected = $null }
        @{ Existing = 'another shell'; Expected = 'another shell' }
        @{ Existing = 'Owned shell'; Expected = 'Owned shell' }
    ) {
        param($Existing, $Expected)
        $script:Key.SetValue('Shell', $Existing)
        Remove-AtlasOwnedShell -Key $script:Key -Shell 'owned shell'
        $script:Key.GetValue('Shell') | Should -Be $Expected
        $script:Key.GetValue('UnrelatedPolicy') | Should -Be 17
        $script:Key.GetAccessControl().GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::Access) | Should -Be $script:AclBefore
    }
}
