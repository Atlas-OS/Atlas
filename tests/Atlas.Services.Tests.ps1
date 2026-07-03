BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Services\Atlas.Services.psd1') -Force

    $script:testRoot = 'HKCU:\Software\AtlasRewriteTest'
    $script:servicesRoot = "$script:testRoot\Services"
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Set-AtlasServiceStartup' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Services
        New-Item -Path $script:servicesRoot -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'writes the Start value directly to the service key' {
        New-Item -Path "$script:servicesRoot\TestSvc" -Force | Out-Null

        Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 4 -ServicesRoot $script:servicesRoot

        $key = Get-Item -LiteralPath "$script:servicesRoot\TestSvc"
        $key.GetValue('Start') | Should -Be 4
        $key.GetValueKind('Start') | Should -Be ([Microsoft.Win32.RegistryValueKind]::DWord)
    }

    It 'overwrites an existing Start value' {
        New-Item -Path "$script:servicesRoot\TestSvc" -Force | Out-Null
        Set-ItemProperty -LiteralPath "$script:servicesRoot\TestSvc" -Name 'Start' -Value 2 -Type DWord

        Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 3 -ServicesRoot $script:servicesRoot

        (Get-Item -LiteralPath "$script:servicesRoot\TestSvc").GetValue('Start') | Should -Be 3
    }

    It 'warns instead of failing when the service key is missing' {
        { Set-AtlasServiceStartup -Name 'AtlasRewriteTestMissingSvc' -StartupType 4 -ServicesRoot $script:servicesRoot } |
            Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Services -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like "*AtlasRewriteTestMissingSvc*"
        }
    }

    It 'rejects startup types outside 0-4' {
        { Set-AtlasServiceStartup -Name 'TestSvc' -StartupType 5 -ServicesRoot $script:servicesRoot } |
            Should -Throw
        { Set-AtlasServiceStartup -Name 'TestSvc' -StartupType -1 -ServicesRoot $script:servicesRoot } |
            Should -Throw
    }
}

Describe 'Stop-AtlasService' {
    It 'warns instead of failing when the service does not exist' {
        Mock Write-AtlasLog -ModuleName Atlas.Services

        { Stop-AtlasService -Name 'AtlasRewriteTestMissingSvc' } | Should -Not -Throw

        Should -Invoke Write-AtlasLog -ModuleName Atlas.Services -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning'
        }
    }
}

Describe 'Export-AtlasServicesBackup' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Services
    }

    It 'exports service Start values in the reg.exe format used by BACKUP.ps1' {
        $backupPath = Join-Path -Path $TestDrive -ChildPath 'winServices.reg'

        Export-AtlasServicesBackup -FilePath $backupPath

        Test-Path -LiteralPath $backupPath | Should -BeTrue
        $lines = Get-Content -LiteralPath $backupPath
        $lines[0] | Should -Be 'Windows Registry Editor Version 5.00'
        @($lines | Where-Object { $_ -like '`[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\*`]' }).Count |
            Should -BeGreaterThan 0
        @($lines | Where-Object { $_ -match '^"Start"=dword:0000000\d$' }).Count | Should -BeGreaterThan 0
    }

    It 'writes the file without a byte order mark so reg.exe can import it' {
        $backupPath = Join-Path -Path $TestDrive -ChildPath 'noBom.reg'

        Export-AtlasServicesBackup -FilePath $backupPath

        $bytes = [System.IO.File]::ReadAllBytes($backupPath)
        # UTF-8 BOM is EF BB BF
        (($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)) | Should -BeFalse
    }

    It 'never overwrites an existing backup' {
        $backupPath = Join-Path -Path $TestDrive -ChildPath 'existing.reg'
        Set-Content -LiteralPath $backupPath -Value 'sentinel'

        Export-AtlasServicesBackup -FilePath $backupPath

        Get-Content -LiteralPath $backupPath | Should -Be 'sentinel'
    }

    It 'creates the parent directory when missing' {
        $backupPath = Join-Path -Path $TestDrive -ChildPath 'sub\dir\winServices.reg'

        Export-AtlasServicesBackup -FilePath $backupPath

        Test-Path -LiteralPath $backupPath | Should -BeTrue
    }
}
