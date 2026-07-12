BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Services\Atlas.Services.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:servicesRoot = "$script:testRoot\Services"

    function Write-TestAtlasServicesBackup {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [Parameter(Mandatory = $true)]
            [AllowEmptyString()]
            [string[]]$Lines
        )

        $parent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Path))
        [void][IO.Directory]::CreateDirectory($parent)
        [IO.File]::WriteAllLines(
            $Path,
            $Lines,
            (New-Object Text.UTF8Encoding($false, $true))
        )
    }
}

AfterAll {
    Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasServiceStartup' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Services
        New-Item -Path $script:servicesRoot -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'writes and returns a typed Start value' {
        New-Item -Path "$script:servicesRoot\TestSvc" -Force | Out-Null

        $result = Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 4 `
            -ServicesRoot $script:servicesRoot -PassThru

        $key = Get-Item -LiteralPath "$script:servicesRoot\TestSvc"
        $key.GetValue('Start') | Should -Be 4
        $key.GetValueKind('Start') |
            Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
        $result.Applied | Should -BeTrue
        $result.StartupType | Should -Be 4
    }

    It 'fails for a missing required service but allows reviewed optional absence' {
        { Set-AtlasServiceStartup -Name 'MissingSvc' -StartupType 4 `
                -ServicesRoot $script:servicesRoot } |
            Should -Throw '*Required service or driver*'

        $result = Set-AtlasServiceStartup -Name 'MissingSvc' -StartupType 4 `
            -ServicesRoot $script:servicesRoot -AllowMissing -PassThru
        $result.Applied | Should -BeFalse
        $result.StartupType | Should -BeNullOrEmpty
    }

    It 'does not let AllowMissing hide an existing-service write failure' {
        New-Item -Path "$script:servicesRoot\TestSvc" -Force | Out-Null
        Mock Set-ItemProperty -ModuleName Atlas.Services { throw 'simulated access denied' }

        { Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 4 `
                -ServicesRoot $script:servicesRoot -AllowMissing } |
            Should -Throw '*simulated access denied*'
    }

    It 'rejects invalid startup types and provider navigation names' {
        { Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 5 `
                -ServicesRoot $script:servicesRoot } | Should -Throw
        foreach ($name in @('.', '..')) {
            { Set-AtlasServiceStartup -Name $name -StartupType 4 `
                    -ServicesRoot $script:servicesRoot } | Should -Throw '*not canonical*'
        }
    }
}

Describe 'Stop-AtlasService' {
    It 'warns instead of failing when a service cannot be stopped' {
        Mock Write-AtlasLog -ModuleName Atlas.Services

        { Stop-AtlasService -Name 'AtlasRewriteTestMissingSvc' } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Services -Times 1 -Exactly
    }
}

Describe 'Atlas service backup' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Services
        $script:backupPath = Join-Path -Path $TestDrive -ChildPath 'Other\services.reg'
    }

    It 'exports sorted service Start values and validates the result' {
        Mock Get-AtlasServicesBackupRecordSet -ModuleName Atlas.Services {
            @(
                [pscustomobject]@{ Name = 'Zulu'; Start = [int]4 }
                [pscustomobject]@{ Name = 'Alpha'; Start = [int]2 }
            )
        }

        Export-AtlasServicesBackup -FilePath $script:backupPath
        $content = Get-Content -LiteralPath $script:backupPath -Raw

        $content | Should -Match '"Start"=dword:00000004'
        $content.IndexOf('Services\Alpha]') |
            Should -BeLessThan $content.IndexOf('Services\Zulu]')
    }

    It 'keeps the first valid backup without enumerating current services again' {
        Write-TestAtlasServicesBackup -Path $script:backupPath -Lines @(
            'Windows Registry Editor Version 5.00'
            ''
            '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Original]'
            '"Start"=dword:00000003'
        )
        $originalBytes = [Convert]::ToBase64String(
            [IO.File]::ReadAllBytes($script:backupPath)
        )
        Mock Get-AtlasServicesBackupRecordSet -ModuleName Atlas.Services {
            throw 'service enumeration should not run'
        }

        Export-AtlasServicesBackup -FilePath $script:backupPath

        [Convert]::ToBase64String([IO.File]::ReadAllBytes($script:backupPath)) |
            Should -BeExactly $originalBytes
        Should -Invoke Get-AtlasServicesBackupRecordSet `
            -ModuleName Atlas.Services -Times 0 -Exactly
    }

    It 'does not overwrite an invalid existing backup' {
        Write-TestAtlasServicesBackup -Path $script:backupPath -Lines @('not a registry backup')
        Mock Get-AtlasServicesBackupRecordSet -ModuleName Atlas.Services {
            @([pscustomobject]@{ Name = 'Alpha'; Start = [int]2 })
        }

        { Export-AtlasServicesBackup -FilePath $script:backupPath } | Should -Throw

        Get-Content -LiteralPath $script:backupPath -Raw |
            Should -Match '^not a registry backup'
        Should -Invoke Get-AtlasServicesBackupRecordSet `
            -ModuleName Atlas.Services -Times 0 -Exactly
    }

    It 'rejects malformed, duplicate, and excluded records' {
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Services
        $invalidBackups = @(
            @(
                'Windows Registry Editor Version 5.00'
                '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Alpha]'
            )
            @(
                'Windows Registry Editor Version 5.00'
                '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Alpha]'
                '"Start"=dword:00000002'
                '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Alpha]'
                '"Start"=dword:00000003'
            )
            @(
                'Windows Registry Editor Version 5.00'
                '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend]'
                '"Start"=dword:00000002'
            )
        )

        foreach ($lines in $invalidBackups) {
            Write-TestAtlasServicesBackup -Path $script:backupPath -Lines $lines
            { Restore-AtlasServicesBackup -FilePath $script:backupPath } |
                Should -Throw
        }
        Should -Invoke Set-AtlasServiceStartup `
            -ModuleName Atlas.Services -Times 0 -Exactly
    }

    It 'restores typed values and reports services removed since backup' {
        Write-TestAtlasServicesBackup -Path $script:backupPath -Lines @(
            'Windows Registry Editor Version 5.00'
            '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Alpha]'
            '"Start"=dword:00000002'
            '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Removed]'
            '"Start"=dword:00000004'
        )
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Services {
            if ($Name -ceq 'Alpha') {
                return [pscustomobject]@{
                    Name = $Name; Applied = $true; StartupType = [int]$StartupType
                }
            }
            return [pscustomobject]@{
                Name = $Name; Applied = $false; StartupType = $null
            }
        }

        $result = Restore-AtlasServicesBackup -FilePath $script:backupPath

        $result.RestoredCount | Should -Be 1
        $result.MissingCount | Should -Be 1
        Should -Invoke Set-AtlasServiceStartup `
            -ModuleName Atlas.Services -Times 2 -Exactly
    }

}
