BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:tasksRoot = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Tasks'
    $script:externalCompatibility = @(
        'Remove-PhoneLinkAppx.ps1'
        'Save-AppxPackageSnapshot.ps1'
        'Set-AppxDeprovisionedPackages.ps1'
    )
}

Describe 'PowerShell task helper references' {
    It 'ships no unreferenced helper without an explicit external-path contract' {
        $textExtensions = @(
            '.bat', '.cmd', '.json', '.md', '.ps1', '.psd1', '.psm1',
            '.sh', '.xml', '.yaml', '.yml'
        )
        $referenceFiles = @(Get-ChildItem -LiteralPath $script:repoRoot -Recurse -File | Where-Object {
                $_.Extension -in $textExtensions -and $_.FullName -ne $PSCommandPath
            })

        $unreferenced = foreach ($task in @(Get-ChildItem -LiteralPath $script:tasksRoot -File -Filter '*.ps1')) {
            if ($script:externalCompatibility -contains $task.Name) {
                continue
            }

            $hasReference = $false
            foreach ($candidate in $referenceFiles) {
                if ($candidate.FullName -eq $task.FullName) {
                    continue
                }
                if ([IO.File]::ReadAllText($candidate.FullName).IndexOf(
                        $task.Name,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -ge 0) {
                    $hasReference = $true
                    break
                }
            }

            if (-not $hasReference) {
                $task.Name
            }
        }

        @($unreferenced) | Should -BeNullOrEmpty `
            -Because 'dead payload helpers expand the supported surface without an execution path'
    }

    It 'documents every external-path compatibility exception in the forwarder itself' {
        foreach ($name in $script:externalCompatibility) {
            $path = Join-Path $script:tasksRoot $name
            $path | Should -Exist
            [IO.File]::ReadAllText($path) | Should -Match '(?i)external invocations.*path'
        }
    }
}
