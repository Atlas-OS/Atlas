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
        # Get-Volume takes the image object Mount-DiskImage returns from the pipeline.
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
    }
    It 'uses the first answer at once when it is one volume with a drive letter' {
        Get-AtlasIsoRoot -ImagePath 'C:\Downloads\Windows.iso' -Disk $script:Disk -Owned | Should -BeExactly 'E:\'
        Should -Invoke Get-AtlasIsoVolumes -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
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
    }
    It 'takes back a letter Atlas gave before it ejects the image' {
        Dismount-AtlasIso 'C:\Windows.iso'
        ($script:Order -join ',') | Should -BeExactly 'letter,dismount'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly -ParameterFilter { $ImagePath -eq 'C:\Windows.iso' -and $ErrorAction -eq 'Continue' }
    }
    It 'ejects the image even when the letter could not be taken back' {
        Mock Remove-AtlasIsoLetter { throw 'Access is denied.' }
        Dismount-AtlasIso 'C:\Windows.iso'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly
    }
    It 'fails when the caller needs the image released' {
        Mock Dismount-DiskImage { Write-Error 'The image is in use.' }
        { Dismount-AtlasIso 'C:\verify.iso' -Required } | Should -Throw '*in use*'
        Should -Invoke Dismount-DiskImage -Times 1 -Exactly -ParameterFilter { $ErrorAction -eq 'Stop' }
    }
}
