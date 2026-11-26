[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidOverwritingBuiltInCmdlets',
    '',
    Justification = 'The startup task''s command runs against stand-ins for the registry, service and object cmdlets it calls.'
)]
param()

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
            IntPtr db = Hold(path, sql);
            Close(db);
        }
        // A connection left open after sql, such as a reader in the middle of a transaction.
        public static IntPtr Hold(string path, string sql) {
            IntPtr db;
            if (Open(Encoding.UTF8.GetBytes(path + "\0"), out db) != 0) throw new InvalidOperationException("Opening the fixture failed.");
            if (Exec(db, Encoding.UTF8.GetBytes(sql + "\0"), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero) != 0) {
                Close(db);
                throw new InvalidOperationException("The fixture SQL failed.");
            }
            return db;
        }
        public static void Release(IntPtr db) {
            Exec(db, Encoding.UTF8.GetBytes("COMMIT;\0"), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero);
            Close(db);
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

    # No test reads or writes this PC's record of the repair, or its start of Windows.
    $script:RecordText = ''
    $script:Records = [Collections.Generic.List[string]]::new()
    function Get-PreparationAppRepositoryRecordText { $script:RecordText }
    function Set-PreparationAppRepositoryRecordText([string]$Text) { $script:RecordText = $Text; $script:Records.Add($Text) }
    function Set-AppRepositoryRecord([hashtable]$Values) { $script:RecordText = ConvertTo-Json -InputObject ([pscustomobject]$Values) -Compress }
    function Get-AppRepositoryRecord { $script:RecordText | ConvertFrom-Json }
    function Get-AppRepositoryRecordStatus { @($script:Records | ForEach-Object { ($_ | ConvertFrom-Json).status }) }
    $script:Boot = 'boot:8'
    function Get-PreparationBootId { $script:Boot }
    # Nor reaches its Task Scheduler, or writes StateRepository's start type.
    function Get-PreparationTaskFolder { throw 'A test reached the Task Scheduler without standing in for it.' }
    function Set-PreparationStateRepositoryStart([string]$Start) { throw "A test wrote the start type $Start without standing in for it." }
    # The notice goes to a scratch key of the current user's.
    $script:PreparationNoticeKey = 'HKCU:\Software\AtlasOSTests\Notice'
}

AfterAll {
    Remove-Item -LiteralPath 'HKCU:\Software\AtlasOSTests' -Recurse -ErrorAction SilentlyContinue
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
        $removed = Remove-AppRepositoryOrphan $path
        $removed.Total | Should -Be 3
        $removed.Checkpoint | Should -BeNullOrEmpty
        $after = Get-AppRepositoryCount $path
        $after.Total | Should -Be 0
        $after.LiveFiles | Should -Be 2
    }

    It 'keeps the rows removed when the checkpoint after the commit can''t finish, and says why' {
        $path = New-AppRepositoryFixture 'checkpoint' -LivePackages 1 -FilePackages 1, 1, 2
        # A reader in the middle of a transaction keeps the write-ahead log from emptying.
        $reader = [AtlasTests.AppRepositorySqlite]::Hold($path.Deployment, 'BEGIN; SELECT count(*) FROM File;')
        try { $removed = Remove-AppRepositoryOrphan $path }
        finally { [AtlasTests.AppRepositorySqlite]::Release($reader) }
        $removed.Total | Should -Be 1
        $removed.Checkpoint | Should -Not -BeNullOrEmpty
        (Get-AppRepositoryCount $path).Files | Should -Be 0
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

Describe 'The repair at startup' {
    BeforeEach {
        $script:Records.Clear()
        $script:Backups = 0
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'auto'; notice = $true }
        Mock Get-PreparationServiceStart { 'disabled' }
        Mock Test-PreparationStateRepositoryStopped { $true }
        Mock Write-PreparationStoreEvidence {}
        # Tests run as the signed-in user; the repair's own check wants TrustedInstaller.
        Mock Get-PreparationAppRepositoryIdentity { 'TrustedInstaller' }
    }

    It 'records each step before it takes it, and removes the rows' {
        $path = New-AppRepositoryFixture 'startup-removed' -LivePackages 1 -FilePackages 1, 1, 2 -ManifestPackages 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Repair-PreparationAppRepository
        Get-AppRepositoryRecordStatus | Should -Be @('started', 'removing', 'committed')
        ($script:Records[0] | ConvertFrom-Json).boot | Should -Be 'boot:8'
        $record = Get-AppRepositoryRecord
        [IO.File]::Exists($record.backup) | Should -BeTrue
        $record.message | Should -Match '^2 row\(s\) of packages no longer registered removed \(1 files, 1 manifests, 0 source URIs\)'
        $record.notice | Should -BeTrue -Because 'the record keeps what the worker set up'
        (Get-AppRepositoryCount $path).Total | Should -Be 0
    }

    It 'checks the guards before the backup and removes nothing when they refuse' {
        $path = New-AppRepositoryFixture 'startup-refused' -LivePackages 1 -FilePackages 1, 2, 3
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Save-PreparationAppRepositoryBackup { $script:Backups++ }
        Repair-PreparationAppRepository
        (Get-AppRepositoryRecord).status | Should -Be 'refused'
        $script:Backups | Should -Be 0
        (Get-AppRepositoryCount $path).Files | Should -Be 2
    }

    It 'changes nothing unless StateRepository is disabled and stopped' {
        $path = New-AppRepositoryFixture 'startup-running' -LivePackages 1 -FilePackages 1, 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Save-PreparationAppRepositoryBackup { $script:Backups++ }
        foreach ($state in @(@{ Start = 'auto'; Stopped = $true }, @{ Start = 'disabled'; Stopped = $false })) {
            Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'auto' }
            Mock Get-PreparationServiceStart { $state.Start }
            Mock Test-PreparationStateRepositoryStopped { $state.Stopped }
            Repair-PreparationAppRepository
            $record = Get-AppRepositoryRecord
            $record.status | Should -Be 'failed'
            $record.message | Should -Match "isn't disabled and stopped"
        }
        $script:Backups | Should -Be 0
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'leaves the record alone unless it runs as TrustedInstaller' {
        Mock Get-PreparationAppRepositoryIdentity { 'S-1-5-18' }
        Mock Get-PreparationAppRepositoryPath { throw 'not reached' }
        Repair-PreparationAppRepository
        $script:Records.Count | Should -Be 0
    }

    It 'leaves a repair that ended as it is, at any later startup' {
        Set-AppRepositoryRecord @{ status = 'removed'; boot = 'boot:7'; message = '3 row(s) removed' }
        Mock Get-PreparationAppRepositoryPath { throw 'not reached' }
        Repair-PreparationAppRepository
        $script:Records.Count | Should -Be 0
    }

    It 'ends the repair once StateRepository has started with the change' {
        Set-AppRepositoryRecord @{ status = 'committed'; boot = 'boot:8'; message = '2 row(s) removed' }
        Mock Test-PreparationStateRepositoryRunning { $true }
        Mock Restore-PreparationAppRepositoryBackup { throw 'not reached' }
        Repair-PreparationAppRepository
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'removed'
        $record.message | Should -Be '2 row(s) removed; StateRepository started with the change'
    }

    It 'puts the backup back and starts StateRepository again when it doesn''t start after the repair' {
        $path = New-AppRepositoryFixture 'startup-put-back' -LivePackages 1 -FilePackages 1, 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Repair-PreparationAppRepository
        (Get-AppRepositoryCount $path).Files | Should -Be 0
        Mock Test-PreparationStateRepositoryRunning { $false }
        Mock Start-Service {}
        Repair-PreparationAppRepository
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Match "StateRepository didn't start, so the database before was put back, and StateRepository started$"
        (Get-AppRepositoryCount $path).Files | Should -Be 1 -Because 'the database is as it was before the repair'
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'StateRepository' }
    }

    It 'says so when the backup can''t go back' {
        Set-AppRepositoryRecord @{ status = 'committed'; boot = 'boot:8'; message = '2 row(s) removed'; backup = 'C:\elsewhere.srd' }
        Mock Get-PreparationAppRepositoryPath { @{ Deployment = Join-Path $TestDrive 'none\StateRepository-Deployment.srd' } }
        Mock Test-PreparationStateRepositoryRunning { $false }
        Mock Start-Service { throw 'not reached' }
        Repair-PreparationAppRepository
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Match "couldn't be put back: its backup is missing"
    }

    It 'ends a first run its time limit stopped before it changed anything as failed' {
        Set-AppRepositoryRecord @{ status = 'started'; boot = 'boot:8' }
        Mock Test-PreparationStateRepositoryRunning { throw 'not reached' }
        Repair-PreparationAppRepository
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Be 'the repair stopped before it changed anything'
        # And it's never repeated.
        $script:Records.Clear()
        Repair-PreparationAppRepository
        $script:Records.Count | Should -Be 0
    }

    It 'ends a first run its time limit stopped while it removed rows as failed, keeping a database StateRepository runs with' {
        $path = New-AppRepositoryFixture 'startup-stopped-running' -LivePackages 1 -FilePackages 1, 1, 2
        Set-AppRepositoryRecord @{ status = 'removing'; boot = 'boot:8'; backup = (Save-PreparationAppRepositoryBackup $path) }
        Remove-AppRepositoryOrphan $path | Out-Null
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Test-PreparationStateRepositoryRunning { $true }
        Repair-PreparationAppRepository
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Be 'the repair stopped while it removed rows; StateRepository started with the database as it was left'
        (Get-AppRepositoryCount $path).Files | Should -Be 0
    }

    It 'puts the backup back after a first run its time limit stopped while it removed rows, when StateRepository doesn''t start' {
        $path = New-AppRepositoryFixture 'startup-stopped-down' -LivePackages 1 -FilePackages 1, 1, 2
        Set-AppRepositoryRecord @{ status = 'removing'; boot = 'boot:8'; backup = (Save-PreparationAppRepositoryBackup $path) }
        Remove-AppRepositoryOrphan $path | Out-Null
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Test-PreparationStateRepositoryRunning { $false }
        Mock Start-Service {}
        Repair-PreparationAppRepository
        (Get-AppRepositoryRecord).status | Should -Be 'failed'
        (Get-AppRepositoryCount $path).Files | Should -Be 1
    }

    It 'logs how it ended in the job folder that set it up' {
        Set-AppRepositoryRecord @{ status = 'started'; boot = 'boot:8' }
        Repair-PreparationAppRepository
        Should -Invoke Write-PreparationStoreEvidence -Times 1 -Exactly -ParameterFilter { $Text -eq 'AppX database repair at startup: failed, the repair stopped before it changed anything' }
    }
}

Describe 'Putting the database back' {
    BeforeEach {
        $script:Directory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -Path $script:Directory -ItemType Directory | Out-Null
        $script:Path = @{ Deployment = Join-Path $script:Directory 'StateRepository-Deployment.srd' }
        foreach ($file in @(@('', 'new'), @('-wal', 'new log'), @('-shm', 'new index'), @('.atlas-backup-1', 'old'), @('-wal.atlas-backup-1', 'old log'))) {
            [IO.File]::WriteAllText($script:Path.Deployment + $file[0], $file[1])
        }
        Mock Test-PreparationStateRepositoryStopped { $true }
    }

    It 'puts back the database and its log as they were copied, and leaves out what the copy has none of' {
        Restore-PreparationAppRepositoryBackup $script:Path ($script:Path.Deployment + '.atlas-backup-1')
        [IO.File]::ReadAllText($script:Path.Deployment) | Should -Be 'old'
        [IO.File]::ReadAllText($script:Path.Deployment + '-wal') | Should -Be 'old log'
        [IO.File]::Exists($script:Path.Deployment + '-shm') | Should -BeFalse
    }

    It 'refuses while StateRepository runs' {
        Mock Test-PreparationStateRepositoryStopped { $false }
        { Restore-PreparationAppRepositoryBackup $script:Path ($script:Path.Deployment + '.atlas-backup-1') } | Should -Throw "*isn't stopped*"
        [IO.File]::ReadAllText($script:Path.Deployment) | Should -Be 'new'
    }

    It 'refuses a copy that isn''t the database''s own' {
        [IO.File]::WriteAllText((Join-Path $script:Directory 'other.atlas-backup-1'), 'other')
        { Restore-PreparationAppRepositoryBackup $script:Path (Join-Path $script:Directory 'other.atlas-backup-1') } | Should -Throw '*backup is missing*'
        [IO.File]::ReadAllText($script:Path.Deployment) | Should -Be 'new'
    }
}

Describe 'Setting up the repair' {
    BeforeEach {
        $script:RecordText = ''
        $script:Records.Clear()
        $script:Log = [Collections.Generic.List[string]]::new()
        $script:Order = [Collections.Generic.List[string]]::new()
        $script:Disabled = $false
        $script:PreparationRestartReasons = @()
        Mock Test-PreparationProtectedPath { $true }
        Mock Write-PreparationStoreEvidence { $script:Log.Add($Text) }
        Mock Write-PreparationState {}
        Mock Get-PreparationServiceStart { if ($script:Disabled) { 'disabled' } else { 'auto' } }
        Mock Register-PreparationAppRepositoryRepair { $script:Order.Add('register') }
        Mock Disable-PreparationStateRepository { $script:Order.Add('disable'); $script:Disabled = $true; [pscustomobject]@{ Disabled = $true; Failure = '' } }
        Mock Unregister-PreparationAppRepositoryRepair {}
        Mock Test-PreparationRestart { $false }
        Mock Get-PreparationAppRepositorySymptom { [datetime]'2026-11-19 14:09' }
        Mock Set-PreparationAppRepositoryNotice { $script:Order.Add('notice'); $true }
        Mock Clear-PreparationAppRepositoryNotice {}
    }

    It 'counts in a copy and leaves the repair out without orphaned rows' {
        $path = New-AppRepositoryFixture 'prepare-none' -LivePackages 1 -FilePackages 1
        Mock Get-PreparationAppRepositoryPath { $path }
        $before = (Get-Item $path.Deployment).LastWriteTimeUtc
        Invoke-PreparationAppRepository | Should -Match 'hold no orphaned rows'
        (Get-Item $path.Deployment).LastWriteTimeUtc | Should -Be $before
        Test-Path (Join-Path $JobPath 'apprepository-count') | Should -BeFalse
        $script:RecordText | Should -BeNullOrEmpty -Because 'nothing was tried, so a later run may decide again'
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'records a refusal, and isn''t set up again after it' {
        $path = New-AppRepositoryFixture 'prepare-refused' -LivePackages 1 -FilePackages 1, 2, 3
        Mock Get-PreparationAppRepositoryPath { $path }
        Invoke-PreparationAppRepository | Should -Match 'refused: 2 orphaned row\(s\) left in place: more files are orphaned'
        (Get-AppRepositoryRecord).status | Should -Be 'refused'
        Mock Measure-PreparationAppRepository { throw 'not reached' }
        Invoke-PreparationAppRepository | Should -Match "ended earlier \(refused: .+\), so it isn't repeated"
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'registers the tasks and records the setup before disabling StateRepository, then asks for the restart' {
        $path = New-AppRepositoryFixture 'prepare-orphaned' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Register-PreparationAppRepositoryRepair { $script:Order.Add('register'); $script:RegisteredRecord = $script:RecordText }
        Invoke-PreparationAppRepository | Should -Be 'reboot'
        @($script:Order) | Should -Be @('register', 'notice', 'disable')
        $script:RegisteredRecord | Should -BeNullOrEmpty
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 1 -Exactly -ParameterFilter { $Start -eq 'auto' -and $Job -eq ([IO.Path]::GetFullPath($JobPath).TrimEnd('\')) }
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'armed'
        $record.armed | Should -Be 'boot:8'
        $record.start | Should -Be 'auto'
        $record.notice | Should -BeTrue
        @($script:PreparationRestartReasons) | Should -Be @('apprepository')
        $script:Log[-1] | Should -Match 'was at 2026-11-19 14:09; 1 orphaned row\(s\)'
        (Get-AppRepositoryCount $path).Files | Should -Be 1 -Because 'the rows go at the next startup'
    }

    It 'records that it set no notice where the PC shows its own' {
        $path = New-AppRepositoryFixture 'prepare-own-notice' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Set-PreparationAppRepositoryNotice { $false }
        Invoke-PreparationAppRepository | Should -Be 'reboot'
        (Get-AppRepositoryRecord).notice | Should -BeFalse
    }

    It 'is left out without the symptom, before anything is copied' {
        Mock Get-PreparationAppRepositorySymptom { $null }
        Mock Measure-PreparationAppRepository { throw 'not reached' }
        Invoke-PreparationAppRepository | Should -Match 'no install failed in the Evaluated state with 0x80070490'
        $script:RecordText | Should -BeNullOrEmpty
    }

    It 'waits for a restart Windows already owes' {
        $path = New-AppRepositoryFixture 'prepare-owed' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Test-PreparationRestart { $script:PreparationRestartReasons = @('servicing'); $true }
        Invoke-PreparationAppRepository | Should -Match 'waits for the restart Windows already owes'
        $script:RecordText | Should -BeNullOrEmpty
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
        Should -Invoke Disable-PreparationStateRepository -Times 0 -Exactly
    }

    It 'isn''t repeated once it has a record, which job folders Atlas Manager removes don''t take with them: <Status>' -TestCases @(
        @{ Status = 'removed' }, @{ Status = 'failed' }, @{ Status = 'refused' }, @{ Status = 'none' }
    ) {
        Set-AppRepositoryRecord @{ status = $Status; boot = 'boot:7'; message = 'as it ended' }
        Mock Get-PreparationAppRepositorySymptom { throw 'not reached' }
        Invoke-PreparationAppRepository | Should -Be "The AppX database repair ended earlier ($($Status): as it ended), so it isn't repeated."
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'takes away what it set up and records the failure when StateRepository couldn''t be disabled' {
        $path = New-AppRepositoryFixture 'prepare-undisabled' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Disable-PreparationStateRepository { [pscustomobject]@{ Disabled = $false; Failure = "StateRepository couldn't be disabled" } }
        Invoke-PreparationAppRepository | Should -Be "Setting up the AppX database repair failed: StateRepository couldn't be disabled."
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 1 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 1 -Exactly
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Be "setting it up failed: StateRepository couldn't be disabled"
        @($script:PreparationRestartReasons).Count | Should -Be 0
    }

    It 'takes away what it set up when setting it up throws before StateRepository is disabled' {
        $path = New-AppRepositoryFixture 'prepare-throws' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Register-PreparationAppRepositoryRepair { throw 'The task scheduler is busy.' }
        Invoke-PreparationAppRepository | Should -Match 'failed: The task scheduler is busy\.'
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 1 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 0 -Exactly
        (Get-AppRepositoryRecord).status | Should -Be 'failed'
    }

    It 'keeps the startup tasks and asks for the restart when StateRepository may be disabled' {
        $path = New-AppRepositoryFixture 'prepare-maybe' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Disable-PreparationStateRepository { [pscustomobject]@{ Disabled = $true; Failure = "the task that disables StateRepository couldn't be removed: access denied" } }
        Invoke-PreparationAppRepository | Should -Be 'reboot'
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 0 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 0 -Exactly
        (Get-AppRepositoryRecord).status | Should -Be 'armed'
        $script:Log | Should -Contain "AppX database repair: the task that disables StateRepository couldn't be removed: access denied; the startup tasks stay to put StateRepository back"
    }

    It 'is left out for a start type it can''t put back' {
        $path = New-AppRepositoryFixture 'prepare-start' -LivePackages 1 -FilePackages 1, 2
        Mock Get-PreparationAppRepositoryPath { $path }
        Mock Get-PreparationServiceStart { 'system' }
        Invoke-PreparationAppRepository | Should -Match "StateRepository's start type is system"
        Should -Invoke Register-PreparationAppRepositoryRepair -Times 0 -Exactly
    }

    It 'is left out when the worker doesn''t run from a protected job folder' {
        Mock Test-PreparationProtectedPath { $false }
        Invoke-PreparationAppRepository | Should -Match "isn't from a protected job folder"
    }
}

Describe 'Registering the repair''s tasks' {
    BeforeEach {
        $script:Registered = @{}
        $folder = [pscustomobject]@{}
        $folder | Add-Member -MemberType ScriptMethod -Name RegisterTaskDefinition -Value { param($Name, $Definition) $script:Registered[$Name] = $Definition }
        $script:Tasks = @{ Service = [pscustomobject]@{}; Folder = $folder }
        Mock Get-PreparationTaskFolder { $script:Tasks }
        Mock New-PreparationSystemTask {
            $task = [pscustomobject]@{ Arguments = $Arguments; Limit = $Limit; Triggers = [pscustomobject]@{ Kinds = [Collections.Generic.List[int]]::new() } }
            $task.Triggers | Add-Member -MemberType ScriptMethod -Name Create -Value { param($Kind) $this.Kinds.Add($Kind) }
            $task
        }
    }

    It 'gives each task its command and time limit, and only the startup task a trigger, for a <Start> start' -TestCases @(
        @{ Start = 'auto'; Value = 2; Delayed = $false }, @{ Start = 'delayed-auto'; Value = 2; Delayed = $true }, @{ Start = 'demand'; Value = 3; Delayed = $false }
    ) {
        Register-PreparationAppRepositoryRepair 'C:\Jobs\1-2\Update-Windows.ps1' 'C:\Jobs\1-2' $Start
        $repair = $script:Registered[$script:PreparationRepairTask]
        $repair.Arguments | Should -Match ([regex]::Escape('-File "C:\Jobs\1-2\Update-Windows.ps1" -JobPath "C:\Jobs\1-2" -RepairAppRepository'))
        $repair.Limit | Should -Be 'PT3M'
        $restore = $script:Registered[$script:PreparationRestoreTask]
        $restore.Arguments | Should -Match "sc\.exe config StateRepository start= $Start;"
        $restore.Limit | Should -Be 'PT2M'
        $startup = $script:Registered[$script:PreparationStartupTask]
        $startup.Limit | Should -Be 'PT15M'
        @($startup.Triggers.Kinds) | Should -Be @(8)
        @($repair.Triggers.Kinds).Count + @($restore.Triggers.Kinds).Count | Should -Be 0
        $startup.Arguments | Should -Match "-Name Start -Value $Value -Type DWord"
        ($startup.Arguments -match 'DelayedAutostart') | Should -Be $Delayed
        foreach ($task in @($restore, $startup)) {
            # Only the quotes around the command.
            ($task.Arguments.ToCharArray() | Where-Object { $_ -eq '"' }).Count | Should -Be 2
        }
    }
}

Describe 'Disabling StateRepository' {
    BeforeEach {
        $script:Order = [Collections.Generic.List[string]]::new()
        $task = [pscustomobject]@{ State = 3; StopsWhenAsked = $true }
        $task | Add-Member -MemberType ScriptMethod -Name RunEx -Value { $script:Order.Add('run'); $this.State = 4 }
        $task | Add-Member -MemberType ScriptMethod -Name Stop -Value { $script:Order.Add('stop'); if ($this.StopsWhenAsked) { $this.State = 3 } }
        $folder = [pscustomobject]@{ Task = $task; Deletes = $true }
        $folder | Add-Member -MemberType ScriptMethod -Name RegisterTaskDefinition -Value { $script:Order.Add('register'); $this.Task }
        $folder | Add-Member -MemberType ScriptMethod -Name DeleteTask -Value { if (-not $this.Deletes) { throw 'Access is denied.' }; $script:Order.Add('delete') }
        $script:Tasks = @{ Service = [pscustomobject]@{}; Folder = $folder }
        Mock Get-PreparationTaskFolder { $script:Tasks }
        Mock New-PreparationSystemTask { [pscustomobject]@{} }
        Mock Start-Service {}
        Mock Start-Sleep {}
        Mock Get-PreparationServiceStart { $script:Order.Add('read'); 'auto' }
        $script:SavedDisableSeconds = $script:PreparationDisableSeconds
        $script:PreparationDisableSeconds = 0
    }
    AfterEach { $script:PreparationDisableSeconds = $script:SavedDisableSeconds }

    It 'stops and removes the task before it reads the start type for the last time, and counts an sc.exe that ran late' {
        # sc.exe finishes as the task is stopped, after the wait ended.
        Mock Get-PreparationServiceStart { $script:Order.Add('read'); if ($script:Order -contains 'stop') { 'disabled' } else { 'auto' } }
        $result = Disable-PreparationStateRepository
        $result.Disabled | Should -BeTrue
        $result.Failure | Should -BeNullOrEmpty
        $order = @($script:Order)
        [array]::IndexOf($order, 'stop') | Should -BeLessThan ([array]::IndexOf($order, 'delete'))
        [array]::LastIndexOf($order, 'read') | Should -BeGreaterThan ([array]::IndexOf($order, 'delete'))
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TrustedInstaller' }
    }

    It 'says StateRepository isn''t disabled once the task is gone and the start type never changed' {
        $result = Disable-PreparationStateRepository
        $result.Disabled | Should -BeFalse
        $result.Failure | Should -Be "StateRepository couldn't be disabled"
        $script:Order | Should -Contain 'delete'
    }

    It 'counts StateRepository as one that may be disabled when the task can''t be removed' {
        $script:Tasks.Folder.Deletes = $false
        $result = Disable-PreparationStateRepository
        $result.Disabled | Should -BeTrue
        $result.Failure | Should -Match "the task that disables StateRepository couldn't be removed: .*Access is denied"
    }

    It 'counts a task that still runs after it was asked to stop as one that may disable StateRepository' {
        $script:Tasks.Folder.Task.StopsWhenAsked = $false
        $result = Disable-PreparationStateRepository
        $result.Disabled | Should -BeTrue
        $result.Failure | Should -Match 'it still runs'
        $script:Order | Should -Not -Contain 'delete'
    }

    It 'says StateRepository isn''t disabled when the task couldn''t be registered' {
        $script:Tasks.Folder | Add-Member -MemberType ScriptMethod -Name RegisterTaskDefinition -Value { throw 'The task XML is malformed.' } -Force
        $result = Disable-PreparationStateRepository
        $result.Disabled | Should -BeFalse
        $result.Failure | Should -Match 'malformed'
        $script:Order | Should -Not -Contain 'delete'
    }
}

Describe 'A repair that still owes a restart' {
    BeforeEach {
        $script:RecordText = ''
        $script:Records.Clear()
        $script:Log = [Collections.Generic.List[string]]::new()
        $script:Start = 'auto'
        $script:Startup = $null
        $script:Owed = $true
        $script:PreparationRestartReasons = @()
        Mock Write-PreparationStoreEvidence { $script:Log.Add($Text) }
        Mock Write-PreparationState {}
        Mock Assert-PreparationContinue {}
        Mock Start-Sleep {}
        Mock Get-PreparationServiceStart { $script:Start }
        Mock Get-PreparationAppRepositoryStartupTask { $script:Startup }
        Mock Test-PreparationAppRepositoryStartupDue { $false }
        Mock Complete-PreparationAppRepositoryStartup { $script:Owed }
    }

    It 'reads one value and asks nothing else without a record' {
        Test-PreparationAppRepositoryPending | Should -BeFalse
        Should -Invoke Get-PreparationServiceStart -Times 0 -Exactly
        Should -Invoke Get-PreparationAppRepositoryStartupTask -Times 0 -Exactly
        Should -Invoke Write-PreparationStoreEvidence -Times 0 -Exactly
    }

    It 'owes the restart while it''s set up and Windows hasn''t restarted, as when Get ready runs again first' {
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:8'; start = 'auto' }
        Test-PreparationAppRepositoryPending | Should -BeTrue
        @($script:PreparationRestartReasons) | Should -Be @('apprepository')
        Should -Invoke Test-PreparationAppRepositoryStartupDue -Times 0 -Exactly
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 0 -Exactly
    }

    It 'waits while the startup task runs, as when Atlas Manager opens first at sign-in, then owes the restart it ends with' {
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'auto' }
        $script:Due = 0
        Mock Test-PreparationAppRepositoryStartupDue {
            $script:Due++
            if ($script:Due -lt 4) { return $true }
            Set-AppRepositoryRecord @{ status = 'removed'; armed = 'boot:7'; boot = 'boot:8'; message = '2 row(s) removed' }
            $false
        }
        Test-PreparationAppRepositoryPending | Should -BeTrue
        Should -Invoke Write-PreparationState -ParameterFilter { $Status -eq 'running' -and $Stage -eq 'store-repair' }
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 0 -Exactly
        $script:Log[-1] | Should -Be 'AppX database repair at this startup: removed, 2 row(s) removed; Windows restarts once more to finish it'
    }

    It 'finishes startup work that ended without the repair, or never came, and owes the restart that needs' {
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'auto' }
        Test-PreparationAppRepositoryPending | Should -BeTrue
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 1 -Exactly -ParameterFilter { $Record['status'] -eq 'armed' }
        @($script:PreparationRestartReasons) | Should -Be @('apprepository')
    }

    It 'goes on when the work it finished leaves StateRepository running' {
        Set-AppRepositoryRecord @{ status = 'started'; armed = 'boot:6'; boot = 'boot:7'; start = 'auto' }
        $script:Owed = $false
        Test-PreparationAppRepositoryPending | Should -BeFalse
        @($script:PreparationRestartReasons).Count | Should -Be 0
    }

    It 'owes the restart in the start of Windows the repair ran in' {
        Set-AppRepositoryRecord @{ status = 'failed'; armed = 'boot:7'; boot = 'boot:8'; message = 'the repair stopped before it changed anything' }
        Test-PreparationAppRepositoryPending | Should -BeTrue
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 0 -Exactly
    }

    It 'owes nothing once Windows has restarted after it, and logs how it ended once' {
        Set-AppRepositoryRecord @{ status = 'removed'; armed = 'boot:6'; boot = 'boot:7'; message = '2 row(s) removed' }
        Test-PreparationAppRepositoryPending | Should -BeFalse
        $script:Log | Should -Be @('AppX database repair at an earlier startup: removed, 2 row(s) removed')
        (Get-AppRepositoryRecord).reported | Should -BeTrue
        Test-PreparationAppRepositoryPending | Should -BeFalse
        $script:Log.Count | Should -Be 1
    }

    It 'counts a disabled StateRepository as the repair''s while the startup task is still there' {
        Set-AppRepositoryRecord @{ status = 'removed'; armed = 'boot:6'; boot = 'boot:7'; message = '2 row(s) removed' }
        $script:Start = 'disabled'
        $script:Startup = [pscustomobject]@{ State = 3 }
        Test-PreparationAppRepositoryPending | Should -BeTrue
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 1 -Exactly
    }

    It 'leaves a disabled StateRepository alone once the startup task is gone' {
        Set-AppRepositoryRecord @{ status = 'removed'; armed = 'boot:6'; boot = 'boot:7'; message = '2 row(s) removed'; reported = $true }
        $script:Start = 'disabled'
        Test-PreparationAppRepositoryPending | Should -BeFalse
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 0 -Exactly
    }

    It 'treats a record it can''t read as a repair that didn''t end' {
        $script:RecordText = '{not json'
        Test-PreparationAppRepositoryPending | Should -BeTrue
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 1 -Exactly -ParameterFilter { $Record['status'] -eq 'unreadable' }
    }

    It 'is what the check before the install asks too, without changing anything: <Case>' -TestCases @(
        @{ Case = 'no record'; Record = $null; Start = 'auto'; Expected = $false }
        @{ Case = 'set up'; Record = @{ status = 'armed'; armed = 'boot:8' }; Start = 'disabled'; Expected = $true }
        @{ Case = 'ended in this start'; Record = @{ status = 'removed'; boot = 'boot:8' }; Start = 'auto'; Expected = $true }
        @{ Case = 'ended before'; Record = @{ status = 'removed'; boot = 'boot:7' }; Start = 'auto'; Expected = $false }
    ) {
        if ($Record) { Set-AppRepositoryRecord $Record }
        $script:Start = $Start
        Test-PreparationAppRepositoryUnfinished | Should -Be $Expected
        $script:Records.Count | Should -Be 0
        Should -Invoke Complete-PreparationAppRepositoryStartup -Times 0 -Exactly
    }
}

Describe 'Finishing what the startup task left' {
    BeforeEach {
        $script:RecordText = ''
        $script:Order = [Collections.Generic.List[string]]::new()
        $script:Start = 'disabled'
        $script:Running = $false
        Mock Get-PreparationServiceStart { $script:Start }
        Mock Set-PreparationStateRepositoryStart { $script:Order.Add("start $Start") }
        Mock Unregister-PreparationAppRepositoryRepair { $script:Order.Add('unregister') }
        Mock Clear-PreparationAppRepositoryNotice { $script:Order.Add('notice') }
        Mock Test-PreparationStateRepositoryRunning { $script:Running }
        Mock Write-PreparationStoreEvidence {}
    }

    It 'puts the start type back in the registry before the tasks go, and records a repair that didn''t run as failed' {
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'delayed-auto'; notice = $true }
        Complete-PreparationAppRepositoryStartup (Read-PreparationAppRepositoryRecord) | Should -BeTrue
        @($script:Order) | Should -Be @('start delayed-auto', 'unregister', 'notice')
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Be "the repair didn't run at startup"
    }

    It 'keeps the tasks while the start type can''t go back' {
        Set-AppRepositoryRecord @{ status = 'armed'; armed = 'boot:7'; start = 'auto'; notice = $true }
        Mock Set-PreparationStateRepositoryStart { throw 'Requested registry access is not allowed.' }
        { Complete-PreparationAppRepositoryStartup (Read-PreparationAppRepositoryRecord) } | Should -Throw '*not allowed*'
        Should -Invoke Unregister-PreparationAppRepositoryRepair -Times 0 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 0 -Exactly
    }

    It 'records rows removed that StateRepository runs with as removed, and owes nothing' {
        Set-AppRepositoryRecord @{ status = 'committed'; boot = 'boot:7'; start = 'auto'; message = '2 row(s) removed' }
        $script:Start = 'auto'
        $script:Running = $true
        Complete-PreparationAppRepositoryStartup (Read-PreparationAppRepositoryRecord) | Should -BeFalse
        (Get-AppRepositoryRecord).status | Should -Be 'removed'
        Should -Invoke Set-PreparationStateRepositoryStart -Times 0 -Exactly
        Should -Invoke Clear-PreparationAppRepositoryNotice -Times 0 -Exactly
    }

    It 'records a repair that stopped at <Status> as failed, and owes the restart StateRepository needs' -TestCases @(
        @{ Status = 'started'; Message = 'the repair stopped at startup before it changed anything' }
        @{ Status = 'removing'; Message = 'the repair stopped at startup while it removed rows, and StateRepository keeps the database as it was left' }
        @{ Status = 'committed'; Message = "2 row(s) removed; StateRepository didn't start with the change" }
    ) {
        Set-AppRepositoryRecord @{ status = $Status; boot = 'boot:7'; start = 'auto'; message = '2 row(s) removed' }
        $script:Start = 'auto'
        Complete-PreparationAppRepositoryStartup (Read-PreparationAppRepositoryRecord) | Should -BeTrue
        $record = Get-AppRepositoryRecord
        $record.status | Should -Be 'failed'
        $record.message | Should -Be $Message
    }

    It 'puts back StateRepository''s own default for a record it can''t read' {
        $script:RecordText = '{not json'
        Complete-PreparationAppRepositoryStartup (Read-PreparationAppRepositoryRecord) | Should -BeTrue
        $script:Order | Should -Contain 'start auto'
        (Get-AppRepositoryRecord).status | Should -Be 'failed'
    }
}

Describe 'The startup task''s turn' {
    BeforeEach {
        $script:Booted = [DateTime]::Now.AddMinutes(-5)
        Mock Get-PreparationWindowsStart { $script:Booted }
    }

    It 'is due while it <Case>' -TestCases @(
        @{ Case = 'runs'; State = 4; Ran = -1; Expected = $true }
        @{ Case = 'waits in the queue'; State = 2; Ran = -1; Expected = $true }
        @{ Case = 'has still to start, soon after Windows started'; State = 3; Ran = -60; Expected = $true }
        @{ Case = 'ran at this start'; State = 3; Ran = -1; Expected = $false }
    ) {
        Mock Get-PreparationAppRepositoryStartupTask { [pscustomobject]@{ State = $State; LastRunTime = [DateTime]::Now.AddMinutes($Ran) } }
        Test-PreparationAppRepositoryStartupDue | Should -Be $Expected
    }

    It 'isn''t due long after Windows started, or once it''s gone' {
        $script:Booted = [DateTime]::Now.AddMinutes(-20)
        Mock Get-PreparationAppRepositoryStartupTask { [pscustomobject]@{ State = 3; LastRunTime = [DateTime]::Now.AddDays(-1) } }
        Test-PreparationAppRepositoryStartupDue | Should -BeFalse
        Mock Get-PreparationAppRepositoryStartupTask { $null }
        Test-PreparationAppRepositoryStartupDue | Should -BeFalse
    }

    It 'reads a missing task as gone, and fails on anything else' {
        $folder = [pscustomobject]@{ HResult = -2147024894 }
        $folder | Add-Member -MemberType ScriptMethod -Name GetTask -Value { throw [Runtime.InteropServices.COMException]::new('The system cannot find the file specified.', $this.HResult) }
        Mock Get-PreparationTaskFolder { @{ Folder = $folder } }
        Get-PreparationAppRepositoryStartupTask | Should -BeNullOrEmpty
        $folder.HResult = -2147024891
        { Get-PreparationAppRepositoryStartupTask } | Should -Throw
    }
}

Describe 'The startup task''s command' {
    BeforeAll {
        $script:Delayed = '; Set-ItemProperty -LiteralPath $key -Name DelayedAutostart -Value 1 -Type DWord'
        function Get-StartupCommand([string]$Delayed = '') {
            Format-PreparationTaskCommand $script:PreparationStartupCommand @{
                service = 'HKLM:\SYSTEM\CurrentControlSet\Services\StateRepository'; repair = 'repair'; restore = 'restore'; startvalue = 2; delayed = $Delayed
                root = $script:PreparationReofferedRoot; notice = 'HKLM:\Notice'; caption = $script:PreparationNoticeCaption; names = "'startup','repair','restore'"
            }
        }
        # Runs the command against stand-ins for the registry, the services, the Task
        # Scheduler and shutdown.exe, which shadow the real ones inside it.
        function Invoke-StartupCommand([hashtable]$Machine, [string]$Delayed = '') {
            # As powershell.exe -Command runs it.
            Set-StrictMode -Off
            $ErrorActionPreference = 'Continue'
            $script:Machine = $Machine
            $Machine.Steps = [Collections.Generic.List[string]]::new()
            $Machine.Deleted = [Collections.Generic.List[string]]::new()
            $Machine.Written = [Collections.Generic.List[string]]::new()
            $Machine.Restarts = 0
            function Get-ItemProperty([string]$LiteralPath, [string]$Name) {
                switch -Wildcard ($LiteralPath) {
                    '*StateRepository' { [pscustomobject]@{ Start = $script:Machine.Start } }
                    '*AtlasOS\Preparation' { [pscustomobject]@{ AppRepositoryRepair = $script:Machine.Record } }
                    default { [pscustomobject]@{ legalnoticecaption = $script:Machine.Caption } }
                }
            }
            function Set-ItemProperty([string]$LiteralPath, [string]$Name, $Value, [string]$Type) {
                if ($LiteralPath -like '*StateRepository') {
                    if (-not $script:Machine.Writable) { Write-Error 'Requested registry access is not allowed.' -ErrorAction Continue 2>$null; return }
                    if ($Name -eq 'Start') { $script:Machine.Start = $Value }
                }
                elseif ($Name -eq 'legalnoticecaption') { $script:Machine.Caption = $Value }
                $script:Machine.Written.Add("$Name=$Value")
            }
            function Start-Service([string]$Name) { if (-not $script:Machine.TrustedInstaller) { throw 'The service cannot be started.' } }
            function Start-Sleep { }
            function New-Object {
                $service = [pscustomobject]@{}
                $service | Add-Member -MemberType ScriptMethod -Name Connect -Value { }
                $service | Add-Member -MemberType ScriptMethod -Name GetFolder -Value {
                    $folder = [pscustomobject]@{}
                    $folder | Add-Member -MemberType ScriptMethod -Name GetTask -Value {
                        param($Name)
                        $task = [pscustomobject]@{ Name = $Name; State = 3 }
                        $task | Add-Member -MemberType ScriptMethod -Name RunEx -Value {
                            if (-not $script:Machine.TrustedInstaller) { throw 'The user name or password is incorrect.' }
                            $script:Machine.Steps.Add($this.Name)
                            if ($this.Name -eq 'restore' -and $script:Machine.Restores) { $script:Machine.Start = 2 }
                        }
                        $task | Add-Member -MemberType ScriptMethod -Name Stop -Value { }
                        $task
                    }
                    $folder | Add-Member -MemberType ScriptMethod -Name DeleteTask -Value { param($Name) $script:Machine.Deleted.Add($Name) }
                    $folder
                }
                $service
            }
            function shutdown.exe { $script:Machine.Restarts++; $script:Machine.Shutdown = $args -join ' ' }
            . ([scriptblock]::Create((Get-StartupCommand $Delayed)))
        }
        function New-Machine { @{ Start = 4; TrustedInstaller = $true; Restores = $true; Writable = $true; Caption = 'Atlas'; Record = '{"status":"removed","notice":true}' } }
    }

    It 'is one line PowerShell parses, without double quotes' {
        $command = Get-StartupCommand $script:Delayed
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($command, [ref]$null, [ref]$errors)
        @($errors).Count | Should -Be 0
        $command | Should -Not -Match '[\r\n"]'
    }

    It 'runs the repair, the restore and the repair again as TrustedInstaller, then takes everything away and restarts Windows once' {
        $machine = New-Machine
        Invoke-StartupCommand $machine
        @($machine.Steps) | Should -Be @('repair', 'restore', 'repair')
        @($machine.Deleted) | Should -Be @('startup', 'repair', 'restore')
        $machine.Caption | Should -Be ''
        $machine.Written | Should -Not -Contain 'Start=2' -Because 'the restore put it back'
        $machine.Restarts | Should -Be 1
        $machine.Shutdown | Should -Be '/r /t 30 /d p:4:1'
    }

    It 'puts the start type back itself when TrustedInstaller doesn''t start, then restarts Windows' {
        $machine = New-Machine
        $machine.TrustedInstaller = $false
        Invoke-StartupCommand $machine
        $machine.Steps.Count | Should -Be 0
        $machine.Start | Should -Be 2
        $machine.Deleted.Count | Should -Be 3
        $machine.Restarts | Should -Be 1
    }

    It 'puts back a delayed start as one' {
        $machine = New-Machine
        $machine.Restores = $false
        Invoke-StartupCommand $machine $script:Delayed
        @($machine.Written | Where-Object { $_ -like 'Start=*' -or $_ -like 'DelayedAutostart=*' }) | Should -Be @('Start=2', 'DelayedAutostart=1')
    }

    It 'keeps the tasks and the notice, and doesn''t restart, while the start type stays disabled' {
        $machine = New-Machine
        $machine.TrustedInstaller = $false
        $machine.Writable = $false
        Invoke-StartupCommand $machine
        $machine.Deleted.Count | Should -Be 0
        $machine.Caption | Should -Be 'Atlas'
        $machine.Restarts | Should -Be 0
    }

    It 'doesn''t restart at a startup where StateRepository wasn''t disabled' {
        $machine = New-Machine
        $machine.Start = 2
        Invoke-StartupCommand $machine
        $machine.Deleted.Count | Should -Be 3
        $machine.Restarts | Should -Be 0
    }

    It 'clears only the notice Atlas set: <Case>' -TestCases @(
        @{ Case = 'the record says it set none'; Record = '{"status":"removed","notice":false}'; Caption = 'Atlas' }
        @{ Case = 'the PC shows its own'; Record = '{"status":"removed","notice":true}'; Caption = 'Company' }
        @{ Case = 'no record'; Record = $null; Caption = 'Atlas' }
    ) {
        $machine = New-Machine
        $machine.Record = $Record
        $machine.Caption = $Caption
        Invoke-StartupCommand $machine
        $machine.Caption | Should -Be $Caption
        $machine.Restarts | Should -Be 1
    }

    It 'stops a step that outlasts its wait before the next one starts, and restarts the whole of Windows, never only the shell' {
        $command = Get-StartupCommand
        $command | Should -Match 'while \(\$task\.State -in 2, 4 -and \[DateTime\]::UtcNow -lt \$deadline\); if \(\$task\.State -eq 4\) \{ \$task\.Stop\(0\) \}'
        $command | Should -Not -Match 'AtlasManager|explorer|Stop-Process'
    }
}

Describe 'The restore task''s command' {
    It 'is one line PowerShell parses, which puts the start type back before it starts StateRepository' {
        $command = Format-PreparationTaskCommand $script:PreparationRestoreCommand @{ start = 'demand' }
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($command, [ref]$null, [ref]$errors)
        @($errors).Count | Should -Be 0
        $command | Should -Not -Match '[\r\n"]'
        $command.IndexOf('sc.exe config StateRepository start= demand;') | Should -BeLessThan $command.IndexOf('Start-Service StateRepository')
    }
}

Describe 'The notice before sign-in' {
    BeforeEach {
        Remove-Item -LiteralPath $script:PreparationNoticeKey -Recurse -ErrorAction SilentlyContinue
        New-Item -Path $script:PreparationNoticeKey -Force | Out-Null
        # The worker's parameter, as Atlas Manager passes it.
        Set-Variable -Name RepairNotice -Value 'Atlas is repairing Microsoft Store.'
    }

    It 'is set in Atlas Manager''s words where the PC has none, and cleared again' {
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticecaption -Value ''
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticetext -Value ([string][char]0)
        Set-PreparationAppRepositoryNotice | Should -BeTrue
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticecaption | Should -BeExactly 'Atlas'
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be 'Atlas is repairing Microsoft Store.'
        Clear-PreparationAppRepositoryNotice
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticecaption | Should -Be ''
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be ''
    }

    It 'keeps a notice of the PC''s own' {
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticecaption -Value 'atlas'
        Set-ItemProperty -LiteralPath $script:PreparationNoticeKey -Name legalnoticetext -Value 'Authorized use only'
        Set-PreparationAppRepositoryNotice | Should -BeFalse
        Clear-PreparationAppRepositoryNotice
        (Get-ItemProperty $script:PreparationNoticeKey).legalnoticetext | Should -Be 'Authorized use only'
    }

    It 'isn''t set without Atlas Manager''s text' {
        Set-Variable -Name RepairNotice -Value ''
        Set-PreparationAppRepositoryNotice | Should -BeFalse
        (Get-ItemProperty $script:PreparationNoticeKey).PSObject.Properties['legalnoticecaption'] | Should -BeNullOrEmpty
    }
}

Describe 'The repair before a Store staging stop' {
    BeforeEach {
        $script:Log = [Collections.Generic.List[string]]::new()
        Mock Write-PreparationStoreEvidence { $script:Log.Add($Text) }
    }

    It 'passes a setup on' {
        Mock Invoke-PreparationAppRepository { 'reboot' }
        Start-PreparationAppRepository | Should -Be 'reboot'
        $script:Log.Count | Should -Be 0
    }

    It 'logs why it isn''t set up, for the stop to say too' {
        Mock Invoke-PreparationAppRepository { 'The AppX database repair was left out, as the AppX databases hold no orphaned rows.' }
        Start-PreparationAppRepository | Should -Be 'The AppX database repair was left out, as the AppX databases hold no orphaned rows.'
        $script:Log | Should -Be @('The AppX database repair was left out, as the AppX databases hold no orphaned rows.')
    }

    It 'turns a failure into what the stop says' {
        Mock Invoke-PreparationAppRepository { throw 'database is locked' }
        Start-PreparationAppRepository | Should -Be 'Setting up the AppX database repair failed: database is locked'
    }

    It 'rethrows Stop' {
        Mock Invoke-PreparationAppRepository { throw [OperationCanceledException]::new() }
        { Start-PreparationAppRepository } | Should -Throw -ExceptionType ([OperationCanceledException])
    }

    It 'isn''t one of the Store repairs' {
        $script:PreparationStoreRepairs | Should -Not -Contain 'apprepository'
    }
}

Describe 'Where the worker decides about the repair' {
    BeforeAll {
        $path = Join-Path $PSScriptRoot '..\package\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1'
        $script:Ast = [Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path), [ref]$null, [ref]$null)
        function Get-CommandCall([string]$Name) {
            @($script:Ast.FindAll({ param($Node) $Node -is [Management.Automation.Language.CommandAst] -and $Node.GetCommandName() -eq $Name }, $true))
        }
        function Get-EnclosingFunction($Node) {
            for ($parent = $Node.Parent; $null -ne $parent; $parent = $parent.Parent) {
                if ($parent -is [Management.Automation.Language.FunctionDefinitionAst]) { return $parent.Name }
            }
            return $null
        }
    }

    It 'sets the repair up only at a Store staging stop, never before the update work' {
        $calls = @(Get-CommandCall 'Start-PreparationAppRepository')
        $calls.Count | Should -Be 2
        foreach ($call in $calls) { Get-EnclosingFunction $call | Should -Be 'Repair-PreparationStore' }
        @(Get-CommandCall 'Invoke-PreparationAppRepository' | ForEach-Object { Get-EnclosingFunction $_ }) | Should -Be @('Start-PreparationAppRepository')
        @(Get-CommandCall 'Measure-PreparationAppRepository' | ForEach-Object { Get-EnclosingFunction $_ }) | Should -Be @('Invoke-PreparationAppRepository')
        # Each comes right before the stop it can take the place of.
        $body = (Get-CommandCall 'Stop-PreparationStoreStaging' | ForEach-Object { $_.Parent.Parent.Extent.Text })
        foreach ($block in $body) { $block | Should -Match "Start-PreparationAppRepository\s+if \('reboot' -eq \`$repair\) \{ return 'reboot' \}\s+Stop-PreparationStoreStaging" }
    }

    It 'asks about a pending repair before any Store or Windows Update work, in every kind of run' {
        $assignment = $script:Ast.Find({ param($Node) $Node -is [Management.Automation.Language.AssignmentStatementAst] -and $Node.Left.Extent.Text -eq '$outcome' -and $Node.Right.Extent.Text -match 'Invoke-PreparationTransition' }, $true)
        $assignment.Right | Should -BeOfType ([Management.Automation.Language.IfStatementAst])
        $assignment.Right.Clauses[0].Item1.Extent.Text | Should -Match '^Test-PreparationAppRepositoryPending\b'
        $assignment.Right.Extent.Text | Should -Match '(?s)Test-PreparationAppRepositoryPending.+Invoke-PreparationTransition.+Invoke-PreparationAccess.+Invoke-PreparationUpdates'
    }

    It 'stops the check before the install while the repair is unfinished' {
        Mock Assert-PreparationContinue {}
        Mock Assert-PreparationUser {}
        Mock Test-PreparationRestart { $false }
        Mock Test-PreparationAppRepositoryUnfinished { $true }
        Mock Test-PreparationNetwork { throw 'not reached' }
        { Assert-PreparationCurrent } | Should -Throw '*pending: apprepository*'
    }
}
