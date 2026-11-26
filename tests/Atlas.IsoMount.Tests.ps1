BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $script:AtlasTestRepoRoot 'app\resources\iso\Iso-Mount.ps1')
    # The workers define Fail; the reason is what the app shows, the message what the log keeps.
    function Fail([string]$Reason, [string]$Message) { throw "$($Reason)|$Message" }
    # Initialize-AtlasIsoMountPoint compiles its mount point wrapper only when no type of
    # that name exists. This stand-in takes its place in the test session, so no drive
    # letter is ever given or taken: it records the calls and answers as a test asks.
    if (-not ('AtlasIsoMountPoint' -as [type])) {
        Add-Type -TypeDefinition @'
public static class AtlasIsoMountPoint {
 public static System.Collections.Generic.List<string> Calls = new System.Collections.Generic.List<string>();
 public static string Answer;
 public static void Add(string root, string volume) { Calls.Add("add " + root + " " + volume); }
 public static void Remove(string root) { Calls.Add("remove " + root); }
 public static string Volume(string root) { Calls.Add("volume " + root); return Answer; }
}
'@
    }
    if ($null -eq ('AtlasIsoMountPoint' -as [type]).GetField('Calls')) { throw 'The real mount point wrapper is loaded in this session.' }
    function New-TestVolume([string]$Letter, [string]$FileSystem = 'UDF') {
        [pscustomobject]@{
            DriveLetter = if ($Letter) { [char]$Letter } else { $null }
            FileSystem = $FileSystem
            HealthStatus = 'Healthy'
            OperationalStatus = 'OK'
            Path = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
        }
    }
}

Describe 'Finding the mounted ISO''s drive' {
    BeforeEach {
        $script:AtlasIsoLetterPolls = 8
        $script:AtlasIsoLetterAssignAfter = 3
        $script:AtlasIsoLetters = @{}
        # Get-Volume takes the image object Mount-DiskImage returns.
        $script:Disk = [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_DiskImage', 'root/Microsoft/Windows/Storage')
        # What Get-Volume reports for the image object the mount returned, then what
        # each later query of a fresh image object reports.
        $script:First = @(New-TestVolume 'E')
        $script:Later = @()
        $script:Queries = 0
        Mock Get-Volume { $script:First }
        Mock Get-AtlasIsoVolumes { $script:Queries++; $script:Later[[Math]::Min($script:Queries, $script:Later.Count) - 1] }
        Mock Start-Sleep { }
        Mock Add-AtlasIsoLetter { throw 'Unexpected drive letter.' }
        Mock Get-AtlasIsoStorageParameters { @{} }
        Mock Receive-AtlasIsoStorage { if ($null -ne $Job) { $Job } }
        $script:Starts = @{ vdrvroot = 0; cdrom = 1 }
        Mock Get-ItemProperty {
            $name = Split-Path -Leaf $LiteralPath
            if ($script:Starts.ContainsKey($name)) { [pscustomobject]@{ Start = $script:Starts[$name] } }
        } -ParameterFilter { $LiteralPath -like 'HKLM:\SYSTEM\CurrentControlSet\Services\*' }
    }
    It 'uses the first answer at once when it is one volume with a drive letter' {
        Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned | Should -BeExactly 'E:\'
        Should -Invoke Get-AtlasIsoVolumes -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
        Should -Invoke Get-Volume -Times 1 -Exactly -ParameterFilter { $DiskImage -eq $script:Disk }
    }
    It 'stops at once with a typed reason when Windows stops answering' {
        $script:First = @(New-TestVolume '')
        Mock Get-AtlasIsoVolumes { throw [TimeoutException]::new("Windows didn't finish reading the ISO within 120 seconds.") }
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned } | Should -Throw 'iso-mount-timeout|*within 120 seconds*'
        Should -Invoke Get-AtlasIsoVolumes -Times 1 -Exactly
        Mock Receive-AtlasIsoStorage { throw [TimeoutException]::new('late') }
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk } | Should -Throw 'iso-mount-timeout|late'
        # A disabled driver explains it.
        $script:Starts.cdrom = 4
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk } | Should -Throw 'iso-mount-drivers|*cdrom*'
    }
    It 'names a disabled driver when no drive letter came, and only then reads the drivers' {
        Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk | Should -BeExactly 'E:\'
        Should -Invoke Get-ItemProperty -Times 0 -Exactly
        $script:First = @(New-TestVolume '')
        $script:Later = , @(New-TestVolume '')
        $script:Starts.vdrvroot = 4
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk } | Should -Throw 'iso-mount-drivers|*vdrvroot*'
    }
    It 'waits for a drive letter Windows gives late, querying the image again' {
        $script:First = @(New-TestVolume '')
        $script:Later = @(), @(New-TestVolume ''), @(New-TestVolume 'F')
        Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned | Should -BeExactly 'F:\'
        Should -Invoke Get-AtlasIsoVolumes -Times 3 -Exactly -ParameterFilter { $ImagePath -eq 'C:\Downloads\Windows.iso' }
        Should -Invoke Start-Sleep -Times 3 -Exactly -ParameterFilter { $Milliseconds -eq 500 }
        Should -Invoke Add-AtlasIsoLetter -Times 0 -Exactly
    }
    It 'gives its own mount a free letter once Windows has given none for a while' {
        $script:First = @(New-TestVolume '')
        $script:Later = , @(New-TestVolume '')
        Mock Add-AtlasIsoLetter { $script:Later = , @(New-TestVolume 'Z'); 'Z:\' }
        Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned | Should -BeExactly 'Z:\'
        Should -Invoke Add-AtlasIsoLetter -Times 1 -Exactly -ParameterFilter {
            $ImagePath -eq 'C:\Downloads\Windows.iso' -and $VolumePath -eq '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
        }
        # Windows had the first polls to give its own letter.
        Should -Invoke Start-Sleep -Times $script:AtlasIsoLetterAssignAfter -Exactly
    }
    It 'never gives a letter to an image it did not mount, and says what Windows reported' {
        $script:First = @(New-TestVolume '')
        $script:Later = , @(New-TestVolume '')
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk } |
            Should -Throw 'iso-mount|*1 volume(s): `[FileSystem=UDF, DriveLetter=none, HealthStatus=Healthy, OperationalStatus=OK`]*'
        Should -Invoke Add-AtlasIsoLetter -Times 0 -Exactly
        Should -Invoke Get-AtlasIsoVolumes -Times $script:AtlasIsoLetterPolls -Exactly
    }
    It 'gives no letter to a volume Windows found no filesystem on' {
        $script:First = @(New-TestVolume '' '')
        $script:Later = , @(New-TestVolume '' '')
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned } | Should -Throw 'iso-mount|*FileSystem=none*'
        Should -Invoke Add-AtlasIsoLetter -Times 0 -Exactly
    }
    It 'still requires exactly one volume with a drive letter' {
        $script:First = @((New-TestVolume 'E'), (New-TestVolume 'F'))
        $script:Later = , @((New-TestVolume 'E'), (New-TestVolume 'F'))
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned } | Should -Throw 'iso-mount|*2 volume(s)*'
        $script:First = @()
        $script:Later = , @()
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned } | Should -Throw 'iso-mount|*0 volume(s)*'
    }
    It 'reports a letter it could not give, and a query that failed' {
        $script:First = @(New-TestVolume '')
        $script:Later = , @(New-TestVolume '')
        Mock Add-AtlasIsoLetter { throw 'Access is denied.' }
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned } | Should -Throw "iso-mount|*couldn't give it a drive letter: Access is denied.*"
        Should -Invoke Add-AtlasIsoLetter -Times 1 -Exactly
        Mock Get-AtlasIsoVolumes { throw 'Provider failure.' }
        { Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk } | Should -Throw 'iso-mount|*The last query failed: Provider failure.*'
    }
}

Describe 'Drive letters Atlas gives its own mounts' {
    BeforeEach {
        $script:AtlasIsoLetters = @{}
        [AtlasIsoMountPoint]::Calls.Clear()
        [AtlasIsoMountPoint]::Answer = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
    }
    It 'takes the highest free letter, never A: to C:' {
        Get-AtlasIsoFreeLetter @('C:\', 'D:\') | Should -BeExactly 'Z:\'
        Get-AtlasIsoFreeLetter @('C:\', 'X:\', 'Y:\', 'Z:\') | Should -BeExactly 'W:\'
        $taken = @(68..90 | ForEach-Object { [string][char]$_ + ':\' })
        { Get-AtlasIsoFreeLetter $taken } | Should -Throw '*in use*'
    }
    It 'gives a letter only to a volume GUID path, and records it' {
        { Add-AtlasIsoLetter 'C:\Windows.iso' 'E:\' } | Should -Throw '*stable path*'
        [AtlasIsoMountPoint]::Calls.Count | Should -Be 0
        $root = Add-AtlasIsoLetter 'C:\Windows.iso' '\\?\Volume{12345678-1234-1234-1234-123456789abc}\'
        $root | Should -Match '^[D-Z]:\\$'
        [AtlasIsoMountPoint]::Calls[0] | Should -BeExactly "add $root \\?\Volume{12345678-1234-1234-1234-123456789abc}\"
        $script:AtlasIsoLetters['C:\Windows.iso'].Root | Should -BeExactly $root
    }
    It 'takes back only the letter it gave, while it still names the same volume' {
        Remove-AtlasIsoLetter 'C:\Windows.iso'
        [AtlasIsoMountPoint]::Calls.Count | Should -Be 0
        $script:AtlasIsoLetters['C:\Windows.iso'] = [pscustomobject]@{ Root = 'Z:\'; Volume = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\' }
        Remove-AtlasIsoLetter 'C:\Windows.iso'
        ([AtlasIsoMountPoint]::Calls -join ',') | Should -BeExactly 'volume Z:\,remove Z:\'
        $script:AtlasIsoLetters.Count | Should -Be 0
        # Another volume took the letter since: it isn't Atlas's to remove.
        [AtlasIsoMountPoint]::Calls.Clear()
        [AtlasIsoMountPoint]::Answer = '\\?\Volume{87654321-4321-4321-4321-cba987654321}\'
        $script:AtlasIsoLetters['C:\Windows.iso'] = [pscustomobject]@{ Root = 'Z:\'; Volume = '\\?\Volume{12345678-1234-1234-1234-123456789abc}\' }
        Remove-AtlasIsoLetter 'C:\Windows.iso'
        ([AtlasIsoMountPoint]::Calls -join ',') | Should -BeExactly 'volume Z:\'
    }
}

Describe 'Ejecting the ISO' {
    BeforeEach {
        $script:Order = [Collections.Generic.List[string]]::new()
        Mock Remove-AtlasIsoLetter { $script:Order.Add('letter') }
        Mock Dismount-DiskImage { $script:Order.Add('dismount') }
        Mock Get-AtlasIsoStorageParameters { @{} }
        Mock Receive-AtlasIsoStorage { if ($null -ne $Job) { $Job } }
    }
    It 'takes back a letter Atlas gave before it ejects the image' {
        Dismount-AtlasIso 'C:\Windows.iso'
        ($script:Order -join ',') | Should -BeExactly 'letter,dismount'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly -ParameterFilter { $ImagePath -eq 'C:\Windows.iso' }
    }
    It 'ejects the image even when the letter could not be taken back' {
        Mock Remove-AtlasIsoLetter { throw 'Access is denied.' }
        Dismount-AtlasIso 'C:\Windows.iso'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly
    }
    It 'writes no failure marker of its own, and fails only when the caller needs the image released' {
        Mock Dismount-DiskImage { throw 'The image is in use.' }
        Mock Fail { throw 'A marker would replace the reason the worker is failing for.' }
        { Dismount-AtlasIso 'C:\Windows.iso' } | Should -Not -Throw
        { Dismount-AtlasIso 'C:\verify.iso' -Required } | Should -Throw '*in use*'
        Mock Receive-AtlasIsoStorage { throw [TimeoutException]::new('late') }
        { Dismount-AtlasIso 'C:\Windows.iso' } | Should -Not -Throw
        Should -Invoke Fail -Times 0 -Exactly
    }
}

Describe 'Storage calls with a deadline' {
    BeforeAll {
        # Real jobs in a process of their own, which touch no storage.
        $script:AtlasIsoStorageTimeout = 20
    }
    AfterAll { $script:AtlasIsoStorageTimeout = 120 }
    It 'returns what the call returned' {
        Receive-AtlasIsoStorage (Start-Job { 'image' }) 'reading the ISO' | Should -BeExactly 'image'
    }
    It 'passes on the error the call ended with' {
        { Receive-AtlasIsoStorage (Start-Job { Write-Error 'A virtual disk support provider for the specified file was not found.' }) 'mounting the ISO' } |
            Should -Throw '*virtual disk support provider*'
    }
    It 'stops waiting at the deadline and says what Windows did not finish' {
        $script:AtlasIsoStorageTimeout = 1
        $job = Start-Job { Start-Sleep -Seconds 60 }
        try {
            { Receive-AtlasIsoStorage $job 'mounting the ISO' } | Should -Throw "Windows didn't finish mounting the ISO within 1 seconds."
            $job.State | Should -Be 'Running'
        }
        finally { Remove-Job -Job $job -Force; $script:AtlasIsoStorageTimeout = 20 }
    }
    It 'uses one local session with the same operation timeout for every call' {
        $script:AtlasIsoSession = $null
        Mock New-CimSession { New-MockObject -Type ([Microsoft.Management.Infrastructure.CimSession]) }
        $first = Get-AtlasIsoStorageParameters
        $second = Get-AtlasIsoStorageParameters
        [object]::ReferenceEquals($first.CimSession, $second.CimSession) | Should -BeTrue
        $first.AsJob | Should -BeTrue
        $first.ErrorAction | Should -Be 'Continue'
        Should -Invoke New-CimSession -Times 1 -Exactly -ParameterFilter { $OperationTimeoutSec -eq 20 -and -not $ComputerName }
        $script:AtlasIsoSession = $null
    }
}

Describe 'Mounting the ISO' {
    BeforeEach {
        $script:Starts = @{ vdrvroot = 0; cdrom = 1 }
        Mock Get-ItemProperty {
            $name = Split-Path -Leaf $LiteralPath
            if ($script:Starts.ContainsKey($name)) { [pscustomobject]@{ Start = $script:Starts[$name] } }
        } -ParameterFilter { $LiteralPath -like 'HKLM:\SYSTEM\CurrentControlSet\Services\*' }
        $script:Image = [pscustomobject]@{ Attached = $true }
        Mock Mount-DiskImage { $script:Image }
        Mock Get-DiskImage { $script:Image }
        Mock Get-AtlasIsoStorageParameters { @{} }
        Mock Receive-AtlasIsoStorage { if ($null -ne $Job) { $Job } }
        Mock Get-AtlasIsoFileAttributes { [IO.FileAttributes]::Archive }
    }
    It 'mounts the image read-only and returns its image object' {
        Mount-AtlasIso 'C:\Downloads\Windows.iso' -ReadOnly | Should -Be $script:Image
        Should -Invoke Mount-DiskImage -Times 1 -Exactly -ParameterFilter { $ImagePath -eq 'C:\Downloads\Windows.iso' -and $Access -eq 'ReadOnly' -and $PassThru }
    }
    It 'mounts as before while <Driver> is set to disabled but still loaded, until a restart' -ForEach @(@{ Driver = 'vdrvroot' }, @{ Driver = 'cdrom' }) {
        $script:Starts[$Driver] = 4
        Mount-AtlasIso 'C:\Downloads\Windows.iso' -ReadOnly | Should -Be $script:Image
        Get-AtlasIsoImage 'C:\Downloads\Windows.iso' | Should -Be $script:Image
        # Nothing reads the drivers until something fails.
        Should -Invoke Get-ItemProperty -Times 0 -Exactly
    }
    It 'names <Driver> as the reason a mount failed while it is disabled' -ForEach @(@{ Driver = 'vdrvroot' }, @{ Driver = 'cdrom' }) {
        $script:Starts[$Driver] = 4
        Mock Mount-DiskImage { throw 'A virtual disk support provider for the specified file was not found.' }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw "iso-mount-drivers|*: $Driver.*"
    }
    It 'names <Driver> as the reason a mount did not finish while it is disabled' -ForEach @(@{ Driver = 'vdrvroot' }, @{ Driver = 'cdrom' }) {
        $script:Starts[$Driver] = 4
        Mock Receive-AtlasIsoStorage { throw [TimeoutException]::new("Windows didn't finish mounting the ISO within 120 seconds.") }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw "iso-mount-drivers|*: $Driver.*"
    }
    It 'treats a driver it cannot read, or one set to start on demand, as available' {
        $script:Starts = @{ cdrom = 3 }
        Mock Mount-DiskImage { throw 'The device is not ready.' }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw 'iso-mount|*not ready*'
    }
    It 'says the file must be copied when Windows refuses a <Stored> file' -ForEach @(
        @{ Stored = 'Compressed' }, @{ Stored = 'Encrypted' }, @{ Stored = 'SparseFile' }
    ) {
        Mock Get-AtlasIsoFileAttributes { [IO.FileAttributes]::Archive -bor [IO.FileAttributes]::$Stored }
        Mock Mount-DiskImage { throw 'A virtual disk support provider for the specified file was not found.' }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw "iso-mount-file|*stored $($Stored):*support provider*"
        # Its own output is no file for the user to copy.
        { Mount-AtlasIso 'C:\Atlas\verify.iso' -OwnFile } | Should -Throw 'iso-mount|*support provider*'
    }
    It 'reports any other mount failure with what Windows said' {
        Mock Mount-DiskImage { throw 'The device is not ready.' }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw "iso-mount|Windows couldn't mount 'C:\Downloads\Windows.iso': The device is not ready."
    }
    It 'reports a mount Windows did not finish in time' {
        Mock Receive-AtlasIsoStorage { throw [TimeoutException]::new("Windows didn't finish mounting the ISO within 120 seconds.") }
        { Mount-AtlasIso 'C:\Downloads\Windows.iso' } | Should -Throw 'iso-mount-timeout|*within 120 seconds*'
    }
    It 'types a failure to read the image, and leaves it to the mount when asked' {
        Get-AtlasIsoImage 'C:\Downloads\Windows.iso' | Should -Be $script:Image
        # With vdrvroot off, Windows can't read any image.
        $script:Starts.vdrvroot = 4
        Mock Get-DiskImage { throw 'A virtual disk support provider for the specified file was not found.' }
        { Get-AtlasIsoImage 'C:\Downloads\Windows.iso' } | Should -Throw 'iso-mount-drivers|*vdrvroot*'
        $script:Starts.vdrvroot = 0
        { Get-AtlasIsoImage 'C:\Downloads\Windows.iso' } | Should -Throw 'iso-mount|*support provider*'
        Get-AtlasIsoImage 'C:\Downloads\Windows.iso' -Quiet | Should -BeNullOrEmpty
        # A provider that stops answering stops the worker either way.
        Mock Get-DiskImage { $script:Image }
        Mock Receive-AtlasIsoStorage { throw [TimeoutException]::new('late') }
        { Get-AtlasIsoImage 'C:\Downloads\Windows.iso' -Quiet } | Should -Throw 'iso-mount-timeout|late'
    }
}

Describe 'Exporting Windows images' {
    BeforeAll {
        # An owned stub, so a test that fails to mock it never runs DISM on this PC.
        function Export-WindowsImage { param($SourceImagePath, $SourceIndex, $DestinationImagePath, $CompressionType, [switch]$CheckIntegrity, $ErrorAction) throw "Unmocked image export: $SourceImagePath, $SourceIndex, $DestinationImagePath, $CompressionType, $CheckIntegrity, $ErrorAction" }
    }
    BeforeEach {
        $script:Steps = [Collections.Generic.List[string]]::new()
        $script:Destination = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.wim')
        Mock Export-WindowsImage { $script:Steps.Add("cmdlet $SourceIndex") }
        Mock Invoke-AtlasDismExport { $script:Steps.Add("dism $Index $(Test-Path -LiteralPath $DestinationImage)") }
        $script:Checkpoint = { $script:Steps.Add('checkpoint') }
    }
    It 'exports each image in order, with maximum compression and an integrity check, after its checkpoint' {
        Export-AtlasWindowsImages 'X:\sources\install.esd' $script:Destination @(1, 2) $script:Checkpoint
        ($script:Steps -join ',') | Should -BeExactly 'checkpoint,cmdlet 1,checkpoint,cmdlet 2'
        Should -Invoke Export-WindowsImage -Times 2 -Exactly -ParameterFilter {
            $SourceImagePath -eq 'X:\sources\install.esd' -and $DestinationImagePath -eq $script:Destination -and $CompressionType -eq 'Max' -and $CheckIntegrity
        }
    }
    It 'starts again from nothing with dism.exe when the DISM module has no native code for this process' {
        Mock Export-WindowsImage {
            Set-Content -LiteralPath $DestinationImagePath -Value 'partial'
            throw [BadImageFormatException]::new('An attempt was made to load a program with an incorrect format. (Exception from HRESULT: 0x8007000B)')
        }
        Export-AtlasWindowsImages 'X:\sources\install.esd' $script:Destination @(1, 2) $script:Checkpoint
        ($script:Steps -join ',') | Should -BeExactly 'checkpoint,checkpoint,dism 1 False,checkpoint,dism 2 False'
        Should -Invoke Invoke-AtlasDismExport -Times 2 -Exactly -ParameterFilter { $SourceImage -eq 'X:\sources\install.esd' -and $DestinationImage -eq $script:Destination }
    }
    It 'passes on any other export failure, and a checkpoint that stops the worker' {
        Mock Export-WindowsImage { throw 'Access is denied.' }
        { Export-AtlasWindowsImages 'X:\sources\install.esd' $script:Destination @(1, 2) $script:Checkpoint } | Should -Throw 'Access is denied.'
        Should -Invoke Invoke-AtlasDismExport -Times 0 -Exactly
        { Export-AtlasWindowsImages 'X:\sources\install.esd' $script:Destination @(1, 2) { throw [OperationCanceledException]::new('USB creation stopped.') } } | Should -Throw 'USB creation stopped.'
        Should -Invoke Invoke-AtlasDismExport -Times 0 -Exactly
    }
}
Describe 'Exporting an edition with Windows'' own DISM' {
    BeforeAll {
        # A stand-in for dism.exe that records its arguments, so no image is touched.
        $script:FakeDism = Join-Path $TestDrive 'dism.ps1'
        $script:DismArguments = Join-Path $TestDrive 'dism-arguments.txt'
        Set-Content -LiteralPath $script:FakeDism -Value @"
`$args | Set-Content -LiteralPath '$script:DismArguments'
'Error: 87'
exit `$(if (`$args -contains '/SourceIndex:9') { 87 } else { 0 })
"@
    }
    It 'exports one index with maximum compression and an integrity check' {
        Invoke-AtlasDismExport 'X:\sources\install.wim' 4 'C:\Users\A B\.atlas-iso-1\supported.wim' -Dism $script:FakeDism
        (Get-Content -LiteralPath $script:DismArguments) -join '|' | Should -BeExactly (@(
            '/English', '/Export-Image', '/SourceImageFile:X:\sources\install.wim', '/SourceIndex:4',
            '/DestinationImageFile:C:\Users\A B\.atlas-iso-1\supported.wim', '/Compress:max', '/CheckIntegrity'
        ) -join '|')
    }
    It 'fails with DISM''s exit code and last words' {
        { Invoke-AtlasDismExport 'X:\sources\install.wim' 9 'C:\out.wim' -Dism $script:FakeDism } | Should -Throw "DISM couldn't export image 9 (exit code 87): Error: 87"
    }
}
