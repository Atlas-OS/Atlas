BeforeAll {
    $modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts\Modules'
    Import-Module -Name (Join-Path -Path $modulesRoot -ChildPath 'Atlas.Shortcuts\Atlas.Shortcuts.psd1') -Force

    # Reads a .lnk back through the same shell COM object the module writes it with, so
    # the assertions describe the real on-disk shortcut rather than in-memory state.
    function Read-AtlasTestShortcut {
        param([string]$Path)
        $shell = New-Object -ComObject WScript.Shell
        try {
            $lnk = $shell.CreateShortcut($Path)
            [pscustomobject]@{
                TargetPath       = $lnk.TargetPath
                WorkingDirectory = $lnk.WorkingDirectory
                Arguments        = $lnk.Arguments
                IconLocation     = $lnk.IconLocation
            }
        }
        finally {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        }
    }
}

Describe 'New-AtlasShortcut' {
    BeforeEach {
        # A real source file so the Test-Path/Get-Command source guard passes, and a
        # destination directory that already exists so Save() has somewhere to write.
        $script:sourceDir = Join-Path -Path $TestDrive -ChildPath 'sourceApp'
        New-Item -Path $script:sourceDir -ItemType Directory -Force | Out-Null
        $script:source = Join-Path -Path $script:sourceDir -ChildPath 'tool.exe'
        Set-Content -LiteralPath $script:source -Value 'not a real exe' -NoNewline

        $script:linkDir = Join-Path -Path $TestDrive -ChildPath 'links'
        New-Item -Path $script:linkDir -ItemType Directory -Force | Out-Null
        $script:destination = Join-Path -Path $script:linkDir -ChildPath 'MyTool.lnk'
    }

    It 'creates a .lnk at the destination pointing at the source, defaulting the working dir to the source folder' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination

        Test-Path -LiteralPath $script:destination | Should -BeTrue

        $shortcut = Read-AtlasTestShortcut -Path $script:destination
        $shortcut.TargetPath | Should -Be $script:source
        # Default working directory is Split-Path of the source when -WorkingDir is omitted.
        $shortcut.WorkingDirectory | Should -Be $script:sourceDir
    }

    It 'honors an explicit -WorkingDir, -Arguments and -Icon' {
        $workingDir = Join-Path -Path $TestDrive -ChildPath 'work'
        New-Item -Path $workingDir -ItemType Directory -Force | Out-Null

        New-AtlasShortcut -Source $script:source -Destination $script:destination `
            -WorkingDir $workingDir -Arguments '--flag value' -Icon "$script:source,0"

        $shortcut = Read-AtlasTestShortcut -Path $script:destination
        $shortcut.WorkingDirectory | Should -Be $workingDir
        $shortcut.Arguments | Should -Be '--flag value'
        # WScript.Shell may normalize the icon path's casing on read-back, so match loosely.
        $shortcut.IconLocation | Should -BeLike '*tool.exe,0'
    }

    It 'overwrites an existing .lnk, replacing the target path' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination
        (Read-AtlasTestShortcut -Path $script:destination).TargetPath | Should -Be $script:source

        $otherSource = Join-Path -Path $script:sourceDir -ChildPath 'other.exe'
        Set-Content -LiteralPath $otherSource -Value 'another fake exe' -NoNewline

        New-AtlasShortcut -Source $otherSource -Destination $script:destination

        (Read-AtlasTestShortcut -Path $script:destination).TargetPath | Should -Be $otherSource
    }

    It 'throws when the source does not exist and is not a resolvable command' {
        $missingSource = Join-Path -Path $TestDrive -ChildPath 'does-not-exist-here.exe'
        { New-AtlasShortcut -Source $missingSource -Destination $script:destination } |
            Should -Throw -ExpectedMessage '*not found*'

        Test-Path -LiteralPath $script:destination | Should -BeFalse
    }

    It 'does nothing with -IfExist when the destination is absent' {
        New-AtlasShortcut -Source $script:source -Destination $script:destination -IfExist

        Test-Path -LiteralPath $script:destination | Should -BeFalse
    }

    It 'throws when the destination directory does not exist (it does not create parents)' {
        $unwritable = Join-Path -Path $TestDrive -ChildPath 'no-such-dir\MyTool.lnk'
        { New-AtlasShortcut -Source $script:source -Destination $unwritable } | Should -Throw

        Test-Path -LiteralPath $unwritable | Should -BeFalse
    }
}
