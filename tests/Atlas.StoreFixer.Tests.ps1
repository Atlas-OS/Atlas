BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $coreModule = Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force -PassThru
    & $coreModule { Initialize-AtlasNativeType }
    . (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles\Troubleshooting\FixMSStoreIssues.ps1')

    # Fixtures are written through the same winsqlite3.dll the repair reads them with.
    if (-not ('AtlasTests.StoreFixerSqlite' -as [type])) {
        Add-Type -Language CSharp -TypeDefinition @'
namespace AtlasTests
{
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public static class StoreFixerSqlite
    {
        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_open", CallingConvention = CallingConvention.StdCall)]
        private static extern int Open(byte[] fileName, out IntPtr db);

        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_exec", CallingConvention = CallingConvention.StdCall)]
        private static extern int Exec(IntPtr db, byte[] sql, IntPtr callback, IntPtr argument, IntPtr errorMessage);

        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_close_v2", CallingConvention = CallingConvention.StdCall)]
        private static extern int Close(IntPtr db);

        public static void Execute(string path, string sql)
        {
            IntPtr db;
            if (Open(Encoding.UTF8.GetBytes(path + "\0"), out db) != 0)
                throw new InvalidOperationException("Opening the fixture failed.");
            try
            {
                if (Exec(db, Encoding.UTF8.GetBytes(sql + "\0"), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero) != 0)
                    throw new InvalidOperationException("The fixture SQL failed.");
            }
            finally
            {
                Close(db);
            }
        }
    }
}
'@
    }

    function New-StoreFixerFixture {
        param(
            [string]$Name,
            [int[]]$LivePackages,
            [int[]]$FilePackages,
            [int[]]$ManifestPackages = @(),
            [int[]]$SourceUriPackages = @()
        )

        $directory = Join-Path $TestDrive $Name
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        $path = [pscustomobject]@{
            Directory  = $directory
            Deployment = Join-Path $directory 'StateRepository-Deployment.srd'
            Machine    = Join-Path $directory 'StateRepository-Machine.srd'
        }

        $machine = @('CREATE TABLE Package(_PackageID INTEGER PRIMARY KEY NOT NULL);')
        $machine += @($LivePackages | ForEach-Object { "INSERT INTO Package VALUES ($_);" })
        [AtlasTests.StoreFixerSqlite]::Execute($path.Machine, ($machine -join ' '))

        $deployment = @(
            'PRAGMA journal_mode=WAL;'
            'CREATE TABLE File(_FileID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL);'
            'CREATE TABLE AppxManifest(_AppxManifestID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL);'
            'CREATE TABLE PackageSourceUri(_PackageSourceUriID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL);'
        )
        $deployment += @($FilePackages | ForEach-Object { "INSERT INTO File(Package) VALUES ($_);" })
        $deployment += @($ManifestPackages | ForEach-Object { "INSERT INTO AppxManifest(Package) VALUES ($_);" })
        $deployment += @($SourceUriPackages | ForEach-Object { "INSERT INTO PackageSourceUri(Package) VALUES ($_);" })
        [AtlasTests.StoreFixerSqlite]::Execute($path.Deployment, ($deployment -join ' '))
        $path
    }
}

Describe 'AppX deployment database orphans' {
    It 'counts rows of packages the machine database no longer lists' {
        $path = New-StoreFixerFixture -Name 'count' -LivePackages 1, 2 -FilePackages 1, 1, 2, 3, 3 `
            -ManifestPackages 1, 3 -SourceUriPackages 2, 3, 4

        $count = Get-AtlasAppRepositoryOrphanCount -Path $path

        $count.Packages | Should -Be 2
        $count.Files | Should -Be 2
        $count.Manifests | Should -Be 1
        $count.SourceUris | Should -Be 2
        $count.LiveFiles | Should -Be 3
        $count.Total | Should -Be 5
    }

    It 'removes only the orphaned rows' {
        $path = New-StoreFixerFixture -Name 'remove' -LivePackages 1, 2 -FilePackages 1, 2, 3 `
            -ManifestPackages 1, 3 -SourceUriPackages 3

        $removed = Remove-AtlasAppRepositoryOrphanRow -Path $path
        $after = Get-AtlasAppRepositoryOrphanCount -Path $path

        $removed.Total | Should -Be 3
        $after.Total | Should -Be 0
        $after.Packages | Should -Be 2
        $after.LiveFiles | Should -Be 2
    }

    It 'refuses when the machine database lists no packages' {
        $path = New-StoreFixerFixture -Name 'empty' -LivePackages @() -FilePackages 1, 2

        { Remove-AtlasAppRepositoryOrphanRow -Path $path } | Should -Throw '*no rows were removed*'
        (Get-AtlasAppRepositoryOrphanCount -Path $path).Files | Should -Be 2
    }

    It 'refuses when more files are orphaned than kept' {
        $path = New-StoreFixerFixture -Name 'mismatch' -LivePackages 1 -FilePackages 1, 2, 3

        { Remove-AtlasAppRepositoryOrphanRow -Path $path } | Should -Throw '*no rows were removed*'
        (Get-AtlasAppRepositoryOrphanCount -Path $path).Files | Should -Be 2
    }
}

Describe 'Fix MS Store Issues' {
    BeforeEach {
        Mock Write-AtlasLog {}
        Mock Initialize-AtlasNativeType {}
        Mock Stop-Service {}
        Mock Start-Service {}
        Mock Get-Service {
            [pscustomobject]@{
                DependentServices = @(
                    [pscustomobject]@{ Name = 'AppXSvc'; Status = 'Running' }
                    [pscustomobject]@{ Name = 'WslInstaller'; Status = 'Stopped' }
                )
            }
        }
    }

    It 'skips StoreFixer when orphaned rows were removed' {
        Mock Repair-AtlasAppRepositoryOrphan { $true }
        Mock Invoke-AtlasToggleNativeCommand {}

        Invoke-AtlasStoreFixer -Toggle ([pscustomobject]@{ AtlasModulesPath = $TestDrive })

        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 0 -Exactly
    }

    It 'runs StoreFixer when there was nothing to remove' {
        Mock Repair-AtlasAppRepositoryOrphan { $false }
        Mock Invoke-AtlasToggleNativeCommand {}
        New-Item -Path (Join-Path $TestDrive 'Tools') -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $TestDrive 'Tools\StoreFixer.exe') -Value ''

        Invoke-AtlasStoreFixer -Toggle ([pscustomobject]@{ AtlasModulesPath = $TestDrive })

        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\Tools\StoreFixer.exe' -and ($ArgumentList -join ' ') -ceq 'silent -wait'
        }
    }

    It 'backs up and repairs a database with orphaned rows, then restarts the running services' {
        $path = New-StoreFixerFixture -Name 'repair' -LivePackages 1 -FilePackages 1, 1, 2 -ManifestPackages 2
        Mock Get-AtlasAppRepositoryPath { $path }

        Repair-AtlasAppRepositoryOrphan | Should -BeTrue

        (Get-AtlasAppRepositoryOrphanCount -Path $path).Total | Should -Be 0
        @(Get-ChildItem -LiteralPath $path.Directory -Filter 'StateRepository-Deployment.srd.atlas-backup-*').Count |
            Should -BeGreaterThan 0
        Should -Invoke Stop-Service -Times 1 -Exactly -ParameterFilter { $Name -ceq 'StateRepository' }
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -ceq 'StateRepository' }
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -ceq 'AppXSvc' }
        Should -Invoke Start-Service -Times 0 -Exactly -ParameterFilter { $Name -ceq 'WslInstaller' }
    }

    It 'leaves a database without orphaned rows unchanged' {
        $path = New-StoreFixerFixture -Name 'clean' -LivePackages 1 -FilePackages 1
        Mock Get-AtlasAppRepositoryPath { $path }

        Repair-AtlasAppRepositoryOrphan | Should -BeFalse

        @(Get-ChildItem -LiteralPath $path.Directory -Filter '*.atlas-backup-*').Count | Should -Be 0
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -ceq 'StateRepository' }
    }

    It 'falls back to StoreFixer and restarts services when the removal fails' {
        $path = New-StoreFixerFixture -Name 'failure' -LivePackages @() -FilePackages 1
        Mock Get-AtlasAppRepositoryPath { $path }

        Repair-AtlasAppRepositoryOrphan | Should -BeFalse

        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter { $Level -ceq 'Warning' }
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -ceq 'StateRepository' }
    }

    It 'falls back to StoreFixer when the databases are missing' {
        Mock Get-AtlasAppRepositoryPath {
            [pscustomobject]@{
                Directory  = $TestDrive
                Deployment = Join-Path $TestDrive 'missing\StateRepository-Deployment.srd'
                Machine    = Join-Path $TestDrive 'missing\StateRepository-Machine.srd'
            }
        }

        Repair-AtlasAppRepositoryOrphan | Should -BeFalse

        Should -Invoke Stop-Service -Times 0 -Exactly
    }
}
