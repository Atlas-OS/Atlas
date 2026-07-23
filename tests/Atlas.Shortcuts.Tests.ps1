BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Shortcuts\Atlas.Shortcuts.psd1') -Force

    function Read-AtlasTestShortcut {
        param([string]$Path)

        $shell = $null
        $shortcut = $null
        $shellApplication = $null
        $shellFolder = $null
        $shellItem = $null
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($Path)
            $shellApplication = New-Object -ComObject Shell.Application
            $shellFolder = $shellApplication.Namespace((Split-Path $Path))
            $shellItem = $shellFolder.ParseName((Split-Path $Path -Leaf))
            return [pscustomobject]@{
                TargetPath       = $shortcut.TargetPath
                WorkingDirectory = $shortcut.WorkingDirectory
                Arguments        = $shortcut.Arguments
                IconLocation     = $shortcut.IconLocation
                AppUserModelId   = $shellItem.ExtendedProperty('System.AppUserModel.ID')
            }
        }
        finally {
            foreach ($comObject in @($shellItem, $shellFolder, $shellApplication)) {
                if ($null -ne $comObject -and
                    [System.Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                    [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
                }
            }
            if ($null -ne $shortcut) {
                [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
            }
            if ($null -ne $shell) {
                [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
            }
        }
    }
}

Describe 'New-AtlasShortcut' {
    BeforeEach {
        $script:sourceDir = Join-Path -Path $TestDrive -ChildPath 'sourceApp'
        New-Item -Path $script:sourceDir -ItemType Directory -Force | Out-Null
        $script:source = Join-Path -Path $script:sourceDir -ChildPath 'tool.exe'
        Set-Content -LiteralPath $script:source -Value 'not a real exe' -NoNewline

        $script:linkDir = Join-Path -Path $TestDrive -ChildPath 'links'
        New-Item -Path $script:linkDir -ItemType Directory -Force | Out-Null
        $script:destination = Join-Path -Path $script:linkDir -ChildPath 'MyTool.lnk'
        Remove-Item -LiteralPath $script:destination -Force -ErrorAction SilentlyContinue
    }

    It 'creates a link and defaults its working directory to the source folder' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination

        $shortcut = Read-AtlasTestShortcut -Path $script:destination
        $shortcut.TargetPath | Should -Be $script:source
        $shortcut.WorkingDirectory | Should -Be $script:sourceDir
    }

    It 'applies an explicit working directory, arguments, and icon' {
        $workingDir = Join-Path -Path $TestDrive -ChildPath 'work'
        New-Item -Path $workingDir -ItemType Directory | Out-Null

        New-AtlasShortcut -Source $script:source -Destination $script:destination `
            -WorkingDir $workingDir -Arguments '--flag value' -Icon "$script:source,0"

        $shortcut = Read-AtlasTestShortcut -Path $script:destination
        $shortcut.WorkingDirectory | Should -Be $workingDir
        $shortcut.Arguments | Should -Be '--flag value'
        $shortcut.IconLocation | Should -BeLike '*tool.exe,0'
    }

    It 'writes an explicit AppUserModelID into the shortcut property store' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination `
            -AppUserModelId 'Microsoft.Windows.Explorer'

        (Read-AtlasTestShortcut -Path $script:destination).AppUserModelId |
            Should -BeExactly 'Microsoft.Windows.Explorer'
    }

    It 'updates an existing link' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination

        $otherSource = Join-Path -Path $script:sourceDir -ChildPath 'other.exe'
        Set-Content -LiteralPath $otherSource -Value 'another fake exe' -NoNewline
        New-AtlasShortcut -Source $otherSource -Destination $script:destination

        (Read-AtlasTestShortcut -Path $script:destination).TargetPath |
            Should -Be $otherSource
    }

    It 'requires an existing source and destination directory' {
        $missingSource = Join-Path -Path $TestDrive -ChildPath 'missing.exe'
        { New-AtlasShortcut -Source $missingSource -Destination $script:destination } |
            Should -Throw -ExpectedMessage '*was not found*'

        $missingDestination = Join-Path -Path $TestDrive -ChildPath 'missing\Tool.lnk'
        { New-AtlasShortcut -Source $script:source -Destination $missingDestination } |
            Should -Throw -ExpectedMessage '*destination directory*'
    }

    It 'does nothing with IfExist when the destination is absent' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination -IfExist

        Test-Path -LiteralPath $script:destination | Should -BeFalse
    }

    It 'requires explicit paths and a link destination' {
        { New-AtlasShortcut -Source 'control.exe' -Destination $script:destination } |
            Should -Throw -ExpectedMessage '*fully qualified path*'

        $urlDestination = Join-Path -Path $script:linkDir -ChildPath 'MyTool.url'
        { New-AtlasShortcut -Source $script:source -Destination $urlDestination } |
            Should -Throw -ExpectedMessage "*'.lnk' extension*"
    }
}
