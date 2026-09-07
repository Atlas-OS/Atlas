Describe 'Shipped timer source provenance' {
    BeforeAll {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $script:repo = Split-Path -Parent $PSScriptRoot
        $script:manifest = Get-Content (Join-Path $repo 'tools/timer/accepted-build.json') -Raw | ConvertFrom-Json
    }
    It 'ships the reviewed executable bytes recorded by the accepted build' {
        $paths = @{
            'SetTimerResolution.exe' = 'playbook/Executables/AtlasModules/Tools/SetTimerResolution.exe'
            'MeasureSleep.exe' = 'playbook/Executables/AtlasDesktop/3. General Configuration/Timer Resolution/! MeasureSleep.exe'
        }
        foreach ($output in $manifest.outputs) {
            (Get-FileHash (Join-Path $repo $paths[$output.name]) -Algorithm SHA256).Hash | Should -Be $output.sha256
        }
    }
    It 'includes the complete accepted source inputs and licenses in the payload archive' {
        $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $repo 'playbook/Executables/AtlasModules/Sources/TimerResolution-source.zip'))
        try {
            $zip.Entries.Count | Should -Be $manifest.sourceFiles.Count
            foreach ($sourceFile in $manifest.sourceFiles) {
                $entry = $zip.GetEntry("source/$($sourceFile.name)")
                $entry | Should -Not -BeNullOrEmpty
                $stream = $entry.Open()
                $hash = [Security.Cryptography.SHA256]::Create()
                try {
                    ([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-', '') | Should -Be $sourceFile.sha256
                } finally { $hash.Dispose(); $stream.Dispose() }
            }
            $zip.GetEntry('source/TimerResolution-LICENSE') | Should -Not -BeNullOrEmpty
            $zip.GetEntry('source/args-LICENSE') | Should -Not -BeNullOrEmpty
        } finally { $zip.Dispose() }
    }
    It 'keeps the published build recipe and patches identical to accepted source' {
        foreach ($name in 'Build-TimerTools.ps1', 'inputs.json', 'MeasureSleep.patch', 'SetTimerResolution.patch') {
            $accepted = $manifest.sourceFiles | Where-Object name -EQ $name
            $accepted | Should -Not -BeNullOrEmpty
            (Get-FileHash (Join-Path $repo "tools/timer/$name") -Algorithm SHA256).Hash | Should -Be $accepted.sha256
        }
    }
}
