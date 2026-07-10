BeforeAll {
    $script:playbookRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\playbook')).ProviderPath
    $script:executablesRoot = Join-Path -Path $script:playbookRoot -ChildPath 'Executables'
    $script:registryFiles = @(Get-ChildItem -LiteralPath $script:playbookRoot -Filter '*.reg' -File -Recurse)
    $script:strictUtf16Le = [System.Text.Encoding]::GetEncoding(
        1200,
        [System.Text.EncoderFallback]::ExceptionFallback,
        [System.Text.DecoderFallback]::ExceptionFallback
    )

    function Read-AtlasRegistryPayload {
        param(
            [Parameter(Mandatory)]
            [System.IO.FileInfo] $File
        )

        $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
        if ($bytes.Length -lt 2 -or $bytes[0] -ne 0xFF -or $bytes[1] -ne 0xFE) {
            throw "$($File.FullName) must be UTF-16LE with a byte-order mark."
        }
        if (($bytes.Length % 2) -ne 0) {
            throw "$($File.FullName) has an odd byte count and is not valid UTF-16LE."
        }

        try {
            $text = $script:strictUtf16Le.GetString($bytes, 2, $bytes.Length - 2)
        } catch {
            throw "$($File.FullName) is not valid UTF-16LE: $($_.Exception.Message)"
        }

        if ($text -match "(?<!`r)`n|`r(?!`n)") {
            throw "$($File.FullName) must use CRLF line endings."
        }

        return $text
    }

    function Assert-AtlasRegistrySyntax {
        param(
            [Parameter(Mandatory)]
            [string] $Text,

            [Parameter(Mandatory)]
            [string] $Path
        )

        $lines = @($Text -split "`r`n")
        if ($lines.Count -lt 3 -or $lines[0] -cne 'Windows Registry Editor Version 5.00') {
            throw "$Path does not start with the Registry Editor 5.00 header."
        }
        if ($lines[1] -ne '') {
            throw "$Path must have a blank line after its header."
        }

        $hasRegistryPath = $false
        $expectsHexContinuation = $false
        for ($index = 2; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]
            $lineNumber = $index + 1

            if ($expectsHexContinuation) {
                if ($line -cnotmatch '^\s*[0-9a-fA-F]{2}(?:,[0-9a-fA-F]{2})*(?:,\\)?$') {
                    throw "$Path line $lineNumber is not a valid hexadecimal continuation."
                }
                $expectsHexContinuation = $line.EndsWith(',\')
                continue
            }

            if ($line -eq '' -or $line.StartsWith(';')) {
                continue
            }

            if ($line -cmatch '^\[-?HKEY_(?:LOCAL_MACHINE|CURRENT_USER|CLASSES_ROOT|USERS|CURRENT_CONFIG)(?:\\[^\]]+)?\]$') {
                $hasRegistryPath = $true
                continue
            }

            if (-not $hasRegistryPath) {
                throw "$Path line $lineNumber defines a value before a registry path."
            }
            if ($line -cnotmatch '^(?:@|"(?:[^"\\]|\\.)*")\s*=\s*(?<Data>.+)$') {
                throw "$Path line $lineNumber is not a valid registry value assignment."
            }

            $data = $Matches.Data
            if ($data -ceq '-' -or
                $data -cmatch '^dword:[0-9a-fA-F]{8}$' -or
                $data -cmatch '^"(?:[^"\\]|\\.)*"$') {
                continue
            }
            if ($data -cmatch '^hex(?:\([0-9a-fA-F]+\))?:(?<Bytes>.*)$') {
                $hexBytes = $Matches.Bytes
                if ($hexBytes -cnotmatch '^(?:[0-9a-fA-F]{2}(?:,[0-9a-fA-F]{2})*)?(?:,\\)?$') {
                    throw "$Path line $lineNumber contains malformed hexadecimal data."
                }
                $expectsHexContinuation = $hexBytes.EndsWith(',\')
                continue
            }

            throw "$Path line $lineNumber uses an unsupported or malformed registry data value."
        }

        if (-not $hasRegistryPath) {
            throw "$Path does not contain a registry path."
        }
        if ($expectsHexContinuation) {
            throw "$Path ends in an incomplete hexadecimal continuation."
        }
    }
}

Describe 'Registry payload format' {
    BeforeDiscovery {
        $discoveryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\playbook')).ProviderPath
        $script:registryPayloadCases = @(
            Get-ChildItem -LiteralPath $discoveryRoot -Filter '*.reg' -File -Recurse | ForEach-Object {
                @{
                    Name = $_.FullName.Substring($discoveryRoot.Length + 1)
                    File = $_
                }
            }
        )
    }

    It 'ships at least one registry payload' {
        $script:registryFiles.Count | Should -BeGreaterThan 0
    }

    It 'keeps registry payloads outside Git text and line-ending filters' {
        $attributesPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.gitattributes'
        Get-Content -LiteralPath $attributesPath -Raw | Should -Match '(?m)^\*\.reg\s+-text\s*$'
    }

    It 'is valid UTF-16LE Registry Editor syntax without importing <Name>' -ForEach $registryPayloadCases {
        $text = Read-AtlasRegistryPayload -File $File
        { Assert-AtlasRegistrySyntax -Text $text -Path $File.FullName } | Should -Not -Throw
    }
}

Describe 'Terminal registry payload derivation' {
    It 'adds only the Atlas state marker to Toolbox state <State>' -TestCases @(
        @{ ScriptName = 'disabled.reg'; ToolboxState = 0; State = 3 }
        @{ ScriptName = 'enabled.reg'; ToolboxState = 1; State = 0 }
        @{ ScriptName = 'minimal.reg'; ToolboxState = 2; State = 1 }
    ) {
        $scriptsFile = Get-Item -LiteralPath (Join-Path -Path $script:executablesRoot -ChildPath "AtlasModules\Scripts\Registry\Terminals\$ScriptName")
        $toolboxFile = Get-Item -LiteralPath (Join-Path -Path $script:executablesRoot -ChildPath "AtlasModules\Toolbox\ConfigurationServices\ContextMenuTerminals\ContextMenuTerminals_$ToolboxState.reg")

        $scriptsText = Read-AtlasRegistryPayload -File $scriptsFile
        $toolboxText = Read-AtlasRegistryPayload -File $toolboxFile
        $expectedSuffix = "`r`n[HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\ContextMenuTerminals]`r`n`"state`"=dword:$($State.ToString('x8'))`r`n"

        $scriptsText | Should -BeExactly ($toolboxText + $expectedSuffix)
    }
}
