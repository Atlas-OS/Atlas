BeforeAll {
    $script:RepositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
    $script:NotificationScriptPath = Join-Path -Path $script:RepositoryRoot -ChildPath `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-NotificationState.ps1'
    $script:NotificationPolicyPath =
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'

    function Get-AtlasInstallWorkRoot {
        return $script:AtlasNotificationTestWorkRoot
    }

    function Get-AtlasInstallState {
        return [pscustomobject]@{ status = 'Running' }
    }
}

AfterAll {
    Remove-Variable -Name AtlasNotificationTestWorkRoot -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name AtlasNotificationRegistryTestState -Scope Script -ErrorAction SilentlyContinue
}

Describe 'Temporary notification policy state' {
    BeforeEach {
        $script:AtlasNotificationTestWorkRoot = Join-Path -Path $TestDrive -ChildPath `
            ([Guid]::NewGuid().ToString('N'))
        [void](New-Item -ItemType Directory -Path $script:AtlasNotificationTestWorkRoot -Force)
        $script:AtlasNotificationRegistryTestState = @{
            KeyExists   = $false
            ValueExists = $false
            Kind        = [Microsoft.Win32.RegistryValueKind]::DWord
            Value       = $null
            IgnoreWrite = $false
        }

        Mock Import-Module {}
        Mock Test-Path -ParameterFilter {
            $LiteralPath -eq $script:NotificationPolicyPath
        } -MockWith {
            return [bool]$script:AtlasNotificationRegistryTestState.KeyExists
        }
        Mock Get-Item -ParameterFilter {
            $LiteralPath -eq $script:NotificationPolicyPath
        } -MockWith {
            $key = [pscustomobject]@{}
            $key | Add-Member -MemberType ScriptMethod -Name GetValueNames -Value {
                if ($script:AtlasNotificationRegistryTestState.ValueExists) {
                    return @('NoToastApplicationNotification')
                }
                return @()
            }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueKind -Value {
                return $script:AtlasNotificationRegistryTestState.Kind
            }
            $key | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
                $defaultValue = $args[1]
                if (-not $script:AtlasNotificationRegistryTestState.ValueExists) {
                    return $DefaultValue
                }
                return $script:AtlasNotificationRegistryTestState.Value
            }
            return $key
        }
        Mock New-Item -ParameterFilter {
            $Path -eq $script:NotificationPolicyPath
        } -MockWith {
            $script:AtlasNotificationRegistryTestState.KeyExists = $true
        }
        Mock New-ItemProperty -ParameterFilter {
            $LiteralPath -eq $script:NotificationPolicyPath
        } -MockWith {
            if (-not $script:AtlasNotificationRegistryTestState.IgnoreWrite) {
                $script:AtlasNotificationRegistryTestState.KeyExists = $true
                $script:AtlasNotificationRegistryTestState.ValueExists = $true
                $script:AtlasNotificationRegistryTestState.Kind =
                    [Microsoft.Win32.RegistryValueKind]::DWord
                $script:AtlasNotificationRegistryTestState.Value = [int]$Value
            }
        }
        Mock Remove-ItemProperty -ParameterFilter {
            $LiteralPath -eq $script:NotificationPolicyPath
        } -MockWith {
            if (-not $script:AtlasNotificationRegistryTestState.IgnoreWrite) {
                $script:AtlasNotificationRegistryTestState.ValueExists = $false
                $script:AtlasNotificationRegistryTestState.Value = $null
            }
        }
    }

    It 'captures absence once and disables notifications' {
        . $script:NotificationScriptPath -Mode Disable

        $snapshotPath = Join-Path $script:AtlasNotificationTestWorkRoot 'notification.json'
        $snapshot = [IO.File]::ReadAllText($snapshotPath) | ConvertFrom-Json
        $snapshot.existed | Should -BeFalse
        $snapshot.value | Should -BeNullOrEmpty
        $script:AtlasNotificationRegistryTestState.Value | Should -Be 1

        $script:AtlasNotificationRegistryTestState.Value = 0
        . $script:NotificationScriptPath -Mode Disable
        $snapshot = [IO.File]::ReadAllText($snapshotPath) | ConvertFrom-Json
        $snapshot.existed | Should -BeFalse
        $script:AtlasNotificationRegistryTestState.Value | Should -Be 1
    }

    It 'restores the exact prior DWORD and removes the snapshot' {
        $script:AtlasNotificationRegistryTestState.KeyExists = $true
        $script:AtlasNotificationRegistryTestState.ValueExists = $true
        $script:AtlasNotificationRegistryTestState.Value = [int]::MinValue

        . $script:NotificationScriptPath -Mode Disable
        . $script:NotificationScriptPath -Mode Enable

        $script:AtlasNotificationRegistryTestState.ValueExists | Should -BeTrue
        $script:AtlasNotificationRegistryTestState.Value | Should -Be ([int]::MinValue)
        [IO.File]::Exists((Join-Path $script:AtlasNotificationTestWorkRoot 'notification.json')) |
            Should -BeFalse
    }

    It 'restores an absent value and tolerates a repeated restore' {
        . $script:NotificationScriptPath -Mode Disable
        . $script:NotificationScriptPath -Mode Enable
        . $script:NotificationScriptPath -Mode Enable

        $script:AtlasNotificationRegistryTestState.ValueExists | Should -BeFalse
        [IO.File]::Exists((Join-Path $script:AtlasNotificationTestWorkRoot 'notification.json')) |
            Should -BeFalse
    }

    It 'rejects a pre-existing non-DWORD policy without changing it' {
        $script:AtlasNotificationRegistryTestState.KeyExists = $true
        $script:AtlasNotificationRegistryTestState.ValueExists = $true
        $script:AtlasNotificationRegistryTestState.Kind =
            [Microsoft.Win32.RegistryValueKind]::String
        $script:AtlasNotificationRegistryTestState.Value = 'custom'

        { . $script:NotificationScriptPath -Mode Disable } | Should -Throw '*must be a DWORD*'
        $script:AtlasNotificationRegistryTestState.Value | Should -Be 'custom'
        [IO.File]::Exists((Join-Path $script:AtlasNotificationTestWorkRoot 'notification.json')) |
            Should -BeFalse
    }

    It 'keeps the snapshot when restoration does not verify' {
        $script:AtlasNotificationRegistryTestState.KeyExists = $true
        $script:AtlasNotificationRegistryTestState.ValueExists = $true
        $script:AtlasNotificationRegistryTestState.Value = 0
        . $script:NotificationScriptPath -Mode Disable
        $script:AtlasNotificationRegistryTestState.IgnoreWrite = $true

        { . $script:NotificationScriptPath -Mode Enable } |
            Should -Throw '*did not match the requested state*'
        [IO.File]::Exists((Join-Path $script:AtlasNotificationTestWorkRoot 'notification.json')) |
            Should -BeTrue
    }
}
