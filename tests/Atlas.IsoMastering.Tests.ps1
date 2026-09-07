BeforeAll {
    $script:Master = Join-Path (Split-Path $PSScriptRoot -Parent) 'app/resources/iso/Master-Iso.ps1'
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

    It 'releases every source file when mastering is cancelled' {
        Set-Content $Cancel ''
        { & $Master -Media $Media -Output $Output -CancelFile $Cancel } | Should -Throw '*cancelled*'
        foreach ($file in Get-ChildItem $Media -File -Recurse) {
            $stream = [IO.File]::Open($file.FullName, 'Open', 'ReadWrite', 'None')
            $stream.Dispose()
        }
    }
}
