BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:Master = Join-Path $script:AtlasTestRepoRoot 'app\resources\iso\Master-Iso.ps1'
}

Describe 'IMAPI source file lifetime' {
    BeforeEach {
        $script:Media = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path "$Media/boot", "$Media/efi/microsoft/boot" | Out-Null
        # IMAPI needs boot streams for the two catalog entries. Their contents
        # are irrelevant to this handle-lifetime test; no VM boots this fixture.
        [IO.File]::WriteAllBytes("$Media/boot/etfsboot.com", (New-Object byte[] 2048))
        [IO.File]::WriteAllBytes("$Media/efi/microsoft/boot/efisys.bin", (New-Object byte[] 4096))
        Set-Content "$Media/payload.txt" 'Source files must be released before workspace cleanup.'
        $script:Output = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.iso')
        $script:Cancel = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    }

    It 'releases every source file after mastering, without waiting for process exit' {
        & $Master -Media $Media -Output $Output -CancelFile $Cancel
        (Get-Item $Output).Length | Should -BeGreaterThan 0
        foreach ($file in Get-ChildItem $Media -File -Recurse) {
            $stream = [IO.File]::Open($file.FullName, 'Open', 'ReadWrite', 'None')
            $stream.Dispose()
        }
    }

    It 'reports the bytes it writes, ending with all of them' {
        # The reports go straight to the console for the app, as the stage markers do.
        $writer = New-Object IO.StringWriter
        $console = [Console]::Out
        [Console]::SetOut($writer)
        try { & $Master -Media $Media -Output $Output -CancelFile $Cancel }
        finally { [Console]::SetOut($console) }
        $reports = @($writer.ToString() -split "`r?`n" | Where-Object { $_ -like 'ATLAS_PROGRESS:*' } |
            ForEach-Object { $_.Substring('ATLAS_PROGRESS:'.Length) | ConvertFrom-Json })
        $reports.Count | Should -BeGreaterThan 0
        $reports[-1].total | Should -Be (Get-Item $Output).Length
        $reports[-1].done | Should -Be $reports[-1].total
    }

    It 'releases every source file when mastering is cancelled' {
        Set-Content $Cancel ''
        { & $Master -Media $Media -Output $Output -CancelFile $Cancel } | Should -Throw '*cancelled*'
        foreach ($file in Get-ChildItem $Media -File -Recurse) {
            $stream = [IO.File]::Open($file.FullName, 'Open', 'ReadWrite', 'None')
            $stream.Dispose()
        }
    }
}
