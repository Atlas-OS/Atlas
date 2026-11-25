BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $PSScriptRoot '..\package\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1') -JobPath $TestDrive -FunctionsOnly
    Initialize-PreparationAppRepositoryType

    # Fixtures are written through the same winsqlite3.dll the repair reads them with.
    if (-not ('AtlasTests.AppRepositorySqlite' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
namespace AtlasTests {
    public static class AppRepositorySqlite {
        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_open", CallingConvention = CallingConvention.StdCall)]
        static extern int Open(byte[] name, out IntPtr db);
        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_exec", CallingConvention = CallingConvention.StdCall)]
        static extern int Exec(IntPtr db, byte[] sql, IntPtr callback, IntPtr argument, IntPtr error);
        [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_close_v2", CallingConvention = CallingConvention.StdCall)]
        static extern int Close(IntPtr db);
        public static void Execute(string path, string sql) {
            IntPtr db;
            if (Open(Encoding.UTF8.GetBytes(path + "\0"), out db) != 0) throw new InvalidOperationException("Opening the fixture failed.");
            try {
                if (Exec(db, Encoding.UTF8.GetBytes(sql + "\0"), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero) != 0) throw new InvalidOperationException("The fixture SQL failed.");
            }
            finally { Close(db); }
        }
    }
}
'@
    }

    # The tables the repair reads, with the real schema's foreign keys: File,
    # AppxManifest and PackageSourceUri point at Package, and ContentGroupFile at File.
    function New-AppRepositoryFixture([string]$Name, [int[]]$LivePackages, [int[]]$FilePackages, [int[]]$ManifestPackages = @(), [int[]]$SourceUriPackages = @(), [int[]]$GroupedFiles = @()) {
        $directory = Join-Path $TestDrive $Name
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        $path = @{
            Directory = $directory
            Deployment = Join-Path $directory 'StateRepository-Deployment.srd'
            Machine = Join-Path $directory 'StateRepository-Machine.srd'
        }
        $machine = @('CREATE TABLE Package(_PackageID INTEGER PRIMARY KEY NOT NULL);') + @($LivePackages | ForEach-Object { "INSERT INTO Package VALUES ($_);" })
        [AtlasTests.AppRepositorySqlite]::Execute($path.Machine, ($machine -join ' '))
        $deployment = @(
            'PRAGMA journal_mode=WAL;'
            'CREATE TABLE File(_FileID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL REFERENCES Package(_PackageID));'
            'CREATE TABLE AppxManifest(_AppxManifestID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL REFERENCES Package(_PackageID));'
            'CREATE TABLE PackageSourceUri(_PackageSourceUriID INTEGER PRIMARY KEY NOT NULL, Package INTEGER NOT NULL REFERENCES Package(_PackageID));'
            'CREATE TABLE ContentGroupFile(_ContentGroupFileID INTEGER PRIMARY KEY NOT NULL, File INTEGER NOT NULL REFERENCES File(_FileID));'
        )
        $deployment += @($FilePackages | ForEach-Object { "INSERT INTO File(Package) VALUES ($_);" })
        $deployment += @($ManifestPackages | ForEach-Object { "INSERT INTO AppxManifest(Package) VALUES ($_);" })
        $deployment += @($SourceUriPackages | ForEach-Object { "INSERT INTO PackageSourceUri(Package) VALUES ($_);" })
        $deployment += @($GroupedFiles | ForEach-Object { "INSERT INTO ContentGroupFile(File) VALUES ($_);" })
        [AtlasTests.AppRepositorySqlite]::Execute($path.Deployment, ($deployment -join ' '))
        $path
    }

    function Get-AppRepositoryCount([hashtable]$Path) { [AtlasPreparation.AppRepository]::Count($Path.Deployment, $Path.Machine) }
    function Remove-AppRepositoryOrphan([hashtable]$Path, [scriptblock]$Stopped = { $true }) {
        [AtlasPreparation.AppRepository]::Remove($Path.Deployment, $Path.Machine, [Func[bool]]$Stopped)
    }
}

Describe 'Orphaned AppX deployment rows' {
    It 'counts the rows of packages the machine database no longer lists' {
        $path = New-AppRepositoryFixture 'count' -LivePackages 1, 2 -FilePackages 1, 1, 2, 3, 3 -ManifestPackages 1, 3 -SourceUriPackages 2, 3, 4
        $count = Get-AppRepositoryCount $path
        $count.Packages | Should -Be 2
        $count.Files | Should -Be 2
        $count.Manifests | Should -Be 1
        $count.SourceUris | Should -Be 2
        $count.LiveFiles | Should -Be 3
        $count.Total | Should -Be 5
        $count.Refusal() | Should -BeNullOrEmpty
    }

    It 'removes only the orphaned rows' {
        $path = New-AppRepositoryFixture 'remove' -LivePackages 1, 2 -FilePackages 1, 2, 3 -ManifestPackages 1, 3 -SourceUriPackages 3
        (Remove-AppRepositoryOrphan $path).Total | Should -Be 3
        $after = Get-AppRepositoryCount $path
        $after.Total | Should -Be 0
        $after.LiveFiles | Should -Be 2
    }

    It 'refuses when the machine database lists no packages' {
        $path = New-AppRepositoryFixture 'empty' -LivePackages @() -FilePackages 1, 2
        (Get-AppRepositoryCount $path).Refusal() | Should -Match 'no packages'
        { Remove-AppRepositoryOrphan $path } | Should -Throw '*No rows were removed*'
        (Get-AppRepositoryCount $path).Files | Should -Be 2
    }

    It 'refuses when more files are orphaned than kept' {
        $path = New-AppRepositoryFixture 'mismatch' -LivePackages 1 -FilePackages 1, 2, 3
        (Get-AppRepositoryCount $path).Refusal() | Should -Match 'more files are orphaned'
        { Remove-AppRepositoryOrphan $path } | Should -Throw '*No rows were removed*'
        (Get-AppRepositoryCount $path).Files | Should -Be 2
    }

    It 'rolls back when a row elsewhere still points at a removed file' {
        # File 3 belongs to package 9, which is gone, and a content group still lists it.
        $path = New-AppRepositoryFixture 'referenced' -LivePackages 1 -FilePackages 1, 1, 9 -GroupedFiles 1, 3
        { Remove-AppRepositoryOrphan $path } | Should -Throw '*ContentGroupFile still points at 1 removed row*'
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'rolls back when StateRepository started again before the delete' {
        $path = New-AppRepositoryFixture 'restarted' -LivePackages 1 -FilePackages 1, 1, 2
        { Remove-AppRepositoryOrphan $path { $false } } | Should -Throw '*started again before the delete*'
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'rolls back when StateRepository started again before the commit' {
        $path = New-AppRepositoryFixture 'restarted-late' -LivePackages 1 -FilePackages 1, 1, 2
        $script:Asked = 0
        { Remove-AppRepositoryOrphan $path { $script:Asked++; $script:Asked -lt 2 } } | Should -Throw '*started again before the commit*'
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }
}

Describe 'AppX database repair at startup' {
    BeforeEach {
        $script:Backups = 0
        Remove-Item -LiteralPath (Join-Path $JobPath 'apprepository.json') -ErrorAction SilentlyContinue
        Mock Get-PreparationServiceStart { 'disabled' }
        Mock Test-PreparationStateRepositoryStopped { $true }
        # Tests run as the signed-in user; the repair's own check wants TrustedInstaller.
        Mock Get-PreparationAppRepositoryIdentity { 'TrustedInstaller' }
    }

    It 'checks the guards before the backup and removes nothing when they refuse' {
        $path = New-AppRepositoryFixture 'startup-refused' -LivePackages 1 -FilePackages 1, 2, 3
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Save-PreparationAppRepositoryBackup { $script:Backups++ }
        Repair-PreparationAppRepository
        (Get-Content (Join-Path $JobPath 'apprepository.json') -Raw | ConvertFrom-Json).status | Should -Be 'refused'
        $script:Backups | Should -Be 0
        (Get-AppRepositoryCount $path).Files | Should -Be 2
    }

    It 'backs up and removes the rows' {
        $path = New-AppRepositoryFixture 'startup-removed' -LivePackages 1 -FilePackages 1, 1, 2 -ManifestPackages 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Repair-PreparationAppRepository
        $result = Get-Content (Join-Path $JobPath 'apprepository.json') -Raw | ConvertFrom-Json
        $result.status | Should -Be 'removed'
        [IO.File]::Exists($result.backup) | Should -BeTrue
        (Get-AppRepositoryCount $path).Total | Should -Be 0
    }

    It 'changes nothing unless StateRepository is disabled and stopped' {
        $path = New-AppRepositoryFixture 'startup-running' -LivePackages 1 -FilePackages 1, 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Save-PreparationAppRepositoryBackup { $script:Backups++ }
        foreach ($state in @(@{ Start = 'auto'; Stopped = $true }, @{ Start = 'disabled'; Stopped = $false })) {
            Mock Get-PreparationServiceStart { $state.Start }
            Mock Test-PreparationStateRepositoryStopped { $state.Stopped }
            Remove-Item -LiteralPath (Join-Path $JobPath 'apprepository.json') -ErrorAction SilentlyContinue
            Repair-PreparationAppRepository
            $result = Get-Content (Join-Path $JobPath 'apprepository.json') -Raw | ConvertFrom-Json
            $result.status | Should -Be 'failed'
            $result.message | Should -Match 'not disabled and stopped'
        }
        $script:Backups | Should -Be 0
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'refuses to run as anyone but TrustedInstaller' {
        Mock Get-PreparationAppRepositoryIdentity { 'S-1-5-18' }
        Repair-PreparationAppRepository
        (Get-Content (Join-Path $JobPath 'apprepository.json') -Raw | ConvertFrom-Json).message | Should -Match 'only as TrustedInstaller'
    }

    It 'keeps the outcome of an earlier startup and repairs nothing again' {
        $path = New-AppRepositoryFixture 'startup-again' -LivePackages 1 -FilePackages 1, 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Save-PreparationAppRepositoryBackup { $script:Backups++ }
        $earlier = '{"status":"removed","message":"3 row(s) removed"}'
        [IO.File]::WriteAllText((Join-Path $JobPath 'apprepository.json'), $earlier)
        Repair-PreparationAppRepository
        Get-Content (Join-Path $JobPath 'apprepository.json') -Raw | Should -Be $earlier
        $script:Backups | Should -Be 0
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }
}

Describe 'Preparing the AppX database repair' {
    BeforeEach {
        $script:Log = [Collections.Generic.List[string]]::new()
        $script:Disabled = $false
        Mock Test-PreparationProtectedPath { $true }
        Mock Write-PreparationStoreEvidence { $script:Log.Add($Text) }
        Mock Get-PreparationAppRepositoryOutcome { $null }
        Mock Get-PreparationServiceStart { if ($script:Disabled) { 'disabled' } else { 'auto' } }
        Mock Register-PreparationAppRepositoryRepair {}
        Mock Disable-PreparationStateRepository { $script:Disabled = $true }
        Mock Unregister-PreparationAppRepositoryRepair {}
        Mock Test-PreparationRestart { $false }
        Mock Get-PreparationAppRepositorySymptom { [datetime]'2026-11-19 14:09' }
        Mock Set-PreparationAppRepositoryNotice { $script:NoticeDisabled = $script:Disabled; $true }
        Mock Clear-PreparationAppRepositoryNotice {}
        $script:PreparationAppRepositoryArmed = $false
    }

    It 'counts in a copy and asks for no restart without orphaned rows' {
        $path = New-AppRepositoryFixture 'prepare-none' -LivePackages 1 -FilePackages 1
        Mock Get-PreparationAppRepositoryPath { $path }
        $before = (Get-Item $path.Deployment).LastWriteTimeUtc
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log | Should -Contain 'AppX database repair: no orphaned rows'
        (Get-Item $path.Deployment).LastWriteTimeUtc | Should -Be $before
        Test-Path (Join-Path $JobPath 'apprepository-count') | Should -BeFalse
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'asks for no restart when the guards refuse' {
        $path = New-AppRepositoryFixture 'prepare-refused' -LivePackages 1 -FilePackages 1, 2, 3
        Mock Get-PreparationAppRepositoryPath { $path }
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Match 'left in place: more files are orphaned'
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'registers the startup tasks before disabling StateRepository, then asks for a restart' {
        $path = New-AppRepositoryFixture 'prepare-orphaned' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Register-PreparationAppRepositoryRepair { $script:RegisteredDisabled = $script:Disabled }
        $script:PreparationRestartReasons = @()
        Invoke-PreparationAppRepository | Should -Be 'reboot'
        $script:RegisteredDisabled | Should -BeFalse
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 1 -Exactly -ParameterFilter { $Start -eq 'auto' -and $Job -eq ([IO.Path]::GetFullPath($JobPath).TrimEnd('\')) }
        Should -Invoke Disable-PreparationStateRepository -Times 1 -Exactly
        $script:NoticeDisabled | Should -BeFalse
        @($script:PreparationRestartReasons) | Should -Be @('apprepository')
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'leaves the rows alone without the symptom, before counting them' {
        Mock Get-PreparationAppRepositorySymptom { $null }
        Mock Measure-PreparationAppRepository { throw 'not reached' }
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Match 'no install failed in the Evaluated state with 0x80070490'
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'logs when the symptom was last seen' {
        $path = New-AppRepositoryFixture 'prepare-symptom' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Invoke-PreparationAppRepository | Should -Be 'reboot'
        $script:Log[-1] | Should -Match 'with 0x80070490 was at 2026-11-19 14:09; 1 orphaned row'
    }

    It 'waits for a restart Windows already owes' {
        $path = New-AppRepositoryFixture 'prepare-owed' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Test-PreparationRestart { $script:PreparationRestartReasons = @('servicing'); $true }
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Match 'already owes a restart'
        @($script:PreparationRestartReasons).Count | Should -Be 0
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
        Should -Invoke Disable-PreparationStateRepository -Times 0 -Exactly
    }

    It 'does not repeat a repair an earlier startup ran' {
        Mock Get-PreparationAppRepositoryOutcome { [pscustomobject]@{ status = 'removed'; message = '3 row(s) removed' } }
        Mock Get-PreparationAppRepositoryPath { throw 'not reached' }
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Match 'earlier startup: removed, 3 row\(s\) removed; not repeated'
    }

    It 'removes the startup tasks when StateRepository could not be disabled' {
        $path = New-AppRepositoryFixture 'prepare-undisabled' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Disable-PreparationStateRepository { throw "StateRepository couldn't be disabled" }
        { Invoke-PreparationAppRepository } | Should -Throw "*couldn't be disabled*"
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 1 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 1 -Exactly
    }

    It 'keeps the startup tasks when StateRepository ended up disabled' {
        $path = New-AppRepositoryFixture 'prepare-late' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Disable-PreparationStateRepository { $script:Disabled = $true; throw 'timed out' }
        { Invoke-PreparationAppRepository } | Should -Throw
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 0 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 0 -Exactly
    }

    It 'is left out when the worker does not run from a protected job folder' {
        Mock Test-PreparationProtectedPath { $false }
        Invoke-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Match 'not from a protected job folder'
    }
}

Describe 'The outcome of an earlier startup''s repair' {
    It 'reads the newest outcome among the scope''s job folders' {
        $scope = Join-Path $TestDrive 'scope'
        foreach ($job in @('1-1', '1-2', '1-3')) { New-Item -Path (Join-Path $scope $job) -ItemType Directory -Force | Out-Null }
        Set-Content -LiteralPath (Join-Path $scope '1-1\apprepository.json') -Value '{"status":"failed","message":"old"}'
        (Get-Item (Join-Path $scope '1-1\apprepository.json')).LastWriteTimeUtc = [DateTime]::UtcNow.AddHours(-1)
        Set-Content -LiteralPath (Join-Path $scope '1-2\apprepository.json') -Value '{"status":"removed","message":"new"}'
        Mock Test-PreparationProtectedPath { $true }
        (Get-PreparationAppRepositoryOutcome (Join-Path $scope '1-3')).message | Should -Be 'new'
        Get-PreparationAppRepositoryOutcome (Join-Path $TestDrive 'empty\1-1') | Should -BeNullOrEmpty
    }
}

Describe 'The AppX database repair before the update work' {
    BeforeEach {
        $script:Log = [Collections.Generic.List[string]]::new()
        Mock Write-PreparationStoreEvidence { $script:Log.Add($Text) }
        $script:PreparationAppRepositoryArmed = $false
        $script:PreparationRestartReasons = @()
    }

    It 'passes the outcome on' {
        Mock Invoke-PreparationAppRepository { 'reboot' }
        Start-PreparationAppRepository | Should -Be 'reboot'
    }

    It 'lets the run go on when it fails before StateRepository was disabled' {
        Mock Invoke-PreparationAppRepository { throw 'database is locked' }
        Mock Get-PreparationServiceStart { 'auto' }
        Start-PreparationAppRepository | Should -BeFalse
        $script:Log[-1] | Should -Be 'AppX database repair failed: database is locked'
    }

    It 'still asks for the restart when it fails with StateRepository disabled' {
        Mock Invoke-PreparationAppRepository { $script:PreparationAppRepositoryArmed = $true; throw 'timed out' }
        Mock Get-PreparationServiceStart { 'disabled' }
        Start-PreparationAppRepository | Should -Be 'reboot'
        @($script:PreparationRestartReasons) | Should -Be @('apprepository')
    }

    It 'asks for no restart for a StateRepository the PC had disabled already' {
        Mock Invoke-PreparationAppRepository { throw 'database is locked' }
        Mock Get-PreparationServiceStart { 'disabled' }
        Start-PreparationAppRepository | Should -BeFalse
    }

    It 'rethrows Stop' {
        Mock Invoke-PreparationAppRepository { throw [OperationCanceledException]::new() }
        { Start-PreparationAppRepository } | Should -Throw -ExceptionType ([OperationCanceledException])
    }

    It 'is no longer one of the Store repairs' {
        $script:PreparationStoreRepairs | Should -Not -Contain 'apprepository'
    }
}

Describe 'The notice before sign-in' {
    BeforeEach {
        $script:SavedNoticeKey = $script:PreparationNoticeKey
        $script:PreparationNoticeKey = 'HKCU:\Software\AtlasOSTests\Notice'
        Remove-Item -LiteralPath $script:PreparationNoticeKey -Recurse -ErrorAction SilentlyContinue
        New-Item -Path $script:PreparationNoticeKey -Force | Out-Null
    }
    AfterEach {
        Remove-Item -LiteralPath 'HKCU:\Software\AtlasOSTests' -Recurse -ErrorAction SilentlyContinue
        $script:PreparationNoticeKey = $script:SavedNoticeKey
    }

    It 'is set where the PC has none, and cleared again' {
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticecaption -Value ''
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticetext -Value ([string][char]0)
        Set-PreparationAppRepositoryNotice | Should -BeTrue
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be $script:PreparationNoticeText
        Clear-PreparationAppRepositoryNotice
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticecaption | Should -Be ''
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be ''
    }

    It 'keeps a notice of the PC''s own' {
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticecaption -Value 'Company'
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticetext -Value 'Authorized use only'
        Set-PreparationAppRepositoryNotice | Should -BeFalse
        Clear-PreparationAppRepositoryNotice
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be 'Authorized use only'
    }
}

Describe 'The restore task''s command' {
    BeforeAll {
        $names = "'AtlasOS AppX database repair at startup','AtlasOS AppX database repair','AtlasOS StateRepository restore'"
        $script:Command = $script:PreparationRestoreCommand.Replace('{start}', 'auto').Replace('{key}', $script:PreparationNoticeKey).Replace('{caption}', $script:PreparationNoticeCaption).Replace('{names}', $names) -replace '\r?\n', ' '
    }

    It 'is one line PowerShell parses, without double quotes' {
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($script:Command, [ref]$null, [ref]$errors)
        @($errors).Count | Should -Be 0
        $script:Command | Should -Not -Match '[\r\n"]'
    }

    It 'restarts Windows only once the tasks and the disabled start type are gone, and not while Atlas Manager is open' {
        $guard = $script:Command.IndexOf('if ($left -or')
        $atlas = $script:Command.IndexOf('Get-Process -Name AtlasManager')
        $restart = $script:Command.IndexOf('shutdown.exe /r')
        $guard | Should -BeGreaterThan $script:Command.IndexOf('schtasks.exe /delete')
        $atlas | Should -BeGreaterThan $guard
        $restart | Should -BeGreaterThan $atlas
        $script:Command | Should -Match 'Start -eq 4\) \{ return \}'
    }

    It 'keeps the tasks and the notice while the start type is still disabled' {
        $check = $script:Command.IndexOf("Services\StateRepository').Start -eq 4) { return }")
        $check | Should -BeGreaterThan $script:Command.IndexOf('sc.exe config StateRepository')
        $check | Should -BeLessThan $script:Command.IndexOf('Start-Service StateRepository')
        $check | Should -BeLessThan $script:Command.IndexOf('legalnoticecaption -eq')
        $check | Should -BeLessThan $script:Command.IndexOf('schtasks.exe /delete')
    }

    It 'clears only the notice Atlas set' {
        $script:Command | Should -Match ([regex]::Escape("legalnoticecaption -eq '$($script:PreparationNoticeCaption)'"))
    }
}
