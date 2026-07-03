BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\tools\build\AtlasBuild\AtlasBuild.psd1') -Force
}

Describe 'Get-PlaybookVersion' {
    It 'parses version metadata from a valid playbook.conf' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.5.1</Title>
    <Version>0.5.1</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        $result = Get-PlaybookVersion -PlaybookConfPath $conf
        $result.Version | Should -Be '0.5.1'
        $result.IsDev | Should -BeFalse
        $result.VersionLabel | Should -Be 'v0.5.1'
    }

    It 'marks dev builds from the title' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.6.0 (dev)</Title>
    <Version>0.6.0</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        $result = Get-PlaybookVersion -PlaybookConfPath $conf
        $result.IsDev | Should -BeTrue
        $result.VersionLabel | Should -Be 'v0.6.0 (dev)'
    }

    It 'throws on an invalid version format' {
        $conf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas</Title>
    <Version>not.a.version</Version>
</Playbook>
'@ | Set-Content -Path $conf -Encoding UTF8

        { Get-PlaybookVersion -PlaybookConfPath $conf } | Should -Throw
    }

    It 'throws when the file is missing' {
        { Get-PlaybookVersion -PlaybookConfPath (Join-Path $TestDrive 'missing.conf') } | Should -Throw
    }
}

Describe 'New-StagedPlaybookConf' {
    BeforeEach {
        $script:sourceConf = Join-Path $TestDrive 'playbook.conf'
        @'
<Playbook>
    <Title>Atlas v0.5.1</Title>
    <Version>0.5.1</Version>
    <Requirements>
        <Requirement>Internet</Requirement>
        <Requirement>PluggedIn</Requirement>
    </Requirements>
    <SupportedBuilds>
        <string>26100</string>
        <string>26200</string>
    </SupportedBuilds>
    <ProductCode>64</ProductCode>
</Playbook>
'@ | Set-Content -Path $script:sourceConf -Encoding UTF8
        $script:stagedConf = Join-Path $TestDrive 'staged\playbook.conf'
    }

    It 'returns false when no removals are requested' {
        $result = New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf
        $result | Should -BeFalse
        Test-Path $stagedConf | Should -BeFalse
    }

    It 'strips requirement lines' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveRequirements | Should -BeTrue
        $content = Get-Content $stagedConf -Raw
        $content | Should -Not -Match '<Requirement>'
        $content | Should -Match '<SupportedBuilds>'
        $content | Should -Match '<ProductCode>'
    }

    It 'strips supported builds lines' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveWinverRequirement | Should -BeTrue
        $content = Get-Content $stagedConf -Raw
        $content | Should -Not -Match 'SupportedBuilds'
        $content | Should -Not -Match '<string>26100</string>'
        $content | Should -Match '<Requirement>'
    }

    It 'strips the product code line' {
        New-StagedPlaybookConf -PlaybookConfPath $sourceConf -DestinationPath $stagedConf -RemoveVerification | Should -BeTrue
        (Get-Content $stagedConf -Raw) | Should -Not -Match '<ProductCode>'
    }
}

Describe 'Add-LiveLogAction' {
    It 'injects a live-log action directly after the actions key' {
        $customYml = Join-Path $TestDrive 'custom.yml'
        @'
title: Root Playbook File
actions:
  - !powerShell: {command: 'Write-Host hi', wait: true}
'@ | Set-Content -Path $customYml -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-custom.yml'

        Add-LiveLogAction -CustomYmlPath $customYml -DestinationPath $staged | Should -BeTrue

        $lines = Get-Content $staged
        $actionsIndex = $lines.IndexOf('actions:')
        $lines[$actionsIndex + 1] | Should -Match 'AME Wizard Live Log'
        # The original first action must still follow the injected one
        $lines[$actionsIndex + 2] | Should -Match 'Write-Host hi'
    }

    It 'returns false when actions key is missing' {
        $customYml = Join-Path $TestDrive 'no-actions.yml'
        'title: Nothing here' | Set-Content -Path $customYml -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-no-actions.yml'

        Add-LiveLogAction -CustomYmlPath $customYml -DestinationPath $staged -WarningAction SilentlyContinue | Should -BeFalse
        Test-Path $staged | Should -BeFalse
    }
}

Describe 'Remove-DependencyBlock' {
    It 'removes the NO LOCAL BUILD block' {
        $startYml = Join-Path $TestDrive 'start.yml'
        @'
actions:
  - !writeStatus: {status: 'Before'}
  ################ NO LOCAL BUILD ################
  - !cmd: {command: 'dism /online /something'}
  ################ END NO LOCAL BUILD ################
  - !writeStatus: {status: 'After'}
'@ | Set-Content -Path $startYml -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-start.yml'

        Remove-DependencyBlock -StartYmlPath $startYml -DestinationPath $staged | Should -BeTrue

        $content = Get-Content $staged -Raw
        $content | Should -Not -Match 'dism /online'
        $content | Should -Match 'Before'
        $content | Should -Match 'After'
    }

    It 'returns false when the block markers are absent' {
        $startYml = Join-Path $TestDrive 'plain-start.yml'
        'actions: []' | Set-Content -Path $startYml -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-plain.yml'

        Remove-DependencyBlock -StartYmlPath $startYml -DestinationPath $staged -WarningAction SilentlyContinue | Should -BeFalse
    }
}

Describe 'Set-OemVersionStamp' {
    It 'replaces the placeholder with the version label' {
        $script = Join-Path $TestDrive 'Set-OemInformation.ps1'
        '$version = "AtlasVersionUndefined"' | Set-Content -Path $script -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-oem.ps1'

        Set-OemVersionStamp -ScriptPath $script -VersionLabel 'v0.5.1' -DestinationPath $staged | Should -BeTrue
        (Get-Content $staged -Raw) | Should -Match ([regex]::Escape('$version = "v0.5.1"'))
    }

    It 'returns false when the placeholder is missing' {
        $script = Join-Path $TestDrive 'no-placeholder.ps1'
        '$version = "v9.9.9"' | Set-Content -Path $script -Encoding UTF8
        $staged = Join-Path $TestDrive 'staged-none.ps1'

        Set-OemVersionStamp -ScriptPath $script -VersionLabel 'v0.5.1' -DestinationPath $staged -WarningAction SilentlyContinue | Should -BeFalse
    }
}

Describe 'Get-AvailableArchiveName' {
    It 'returns the base name when nothing conflicts' {
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas.apbx'
    }

    It 'appends a counter when the file exists and replacement is not allowed' {
        New-Item -Path (Join-Path $TestDrive 'Atlas.apbx') -ItemType File | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' |
            Should -Be 'Atlas (1).apbx'
    }

    It 'replaces the existing file when allowed' {
        New-Item -Path (Join-Path $TestDrive 'Atlas.apbx') -ItemType File -Force | Out-Null
        Get-AvailableArchiveName -BaseName 'Atlas.apbx' -WorkingDirectory $TestDrive -DisplayName 'Atlas' -AllowReplace |
            Should -Be 'Atlas.apbx'
        Test-Path (Join-Path $TestDrive 'Atlas.apbx') | Should -BeFalse
    }
}
