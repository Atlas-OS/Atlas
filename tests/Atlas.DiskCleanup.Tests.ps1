BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:CleanupPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Invoke-DiskCleanup.ps1'

    # Load the private cleanup functions without reaching either cleanup path.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        . $script:CleanupPath -Scope CurrentUser -ExpectedUserSid 'not-a-sid'
    }
    catch {
        if ($_.Exception.Message -notlike '*is invalid*') {
            throw
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

Describe 'Atlas disk cleanup boundaries' {
    It 'rejects a user SID on the machine cleanup path before doing work' {
        { & $script:CleanupPath -Scope Machine -ExpectedUserSid 'S-1-5-18' } |
            Should -Throw '*must not accept a user SID*'
    }

    It 'removes ordinary TEMP entries literally and retains the AME working directory' {
        $temp = Join-Path $TestDrive 'Temp'
        $ame = Join-Path $temp 'AME'
        $nested = Join-Path $temp 'ordinary\nested'
        [void][IO.Directory]::CreateDirectory($ame)
        [void][IO.Directory]::CreateDirectory($nested)
        [IO.File]::WriteAllText((Join-Path $ame 'keep.txt'), 'keep')
        $readOnlyFile = Join-Path $nested 'remove.txt'
        [IO.File]::WriteAllText($readOnlyFile, 'remove')
        [IO.File]::SetAttributes($readOnlyFile, [IO.FileAttributes]::ReadOnly)

        Invoke-AtlasTempCleanup -Path $temp

        [IO.Directory]::Exists($ame) | Should -BeTrue
        [IO.File]::Exists((Join-Path $ame 'keep.txt')) | Should -BeTrue
        [IO.Directory]::Exists((Join-Path $temp 'ordinary')) | Should -BeFalse
    }

    It 'deletes a directory junction without traversing or deleting its target' {
        $temp = Join-Path $TestDrive 'TempWithLink'
        $outside = Join-Path $TestDrive 'OutsideTarget'
        $link = Join-Path $temp 'linked'
        [void][IO.Directory]::CreateDirectory($temp)
        [void][IO.Directory]::CreateDirectory($outside)
        $sentinel = Join-Path $outside 'sentinel.txt'
        [IO.File]::WriteAllText($sentinel, 'keep')

        try {
            New-Item -ItemType Junction -Path $link -Target $outside -ErrorAction Stop | Out-Null
        }
        catch {
            Set-ItResult -Skipped -Because "Directory junctions are unavailable: $($_.Exception.Message)"
            return
        }

        Invoke-AtlasTempCleanup -Path $temp

        [IO.Directory]::Exists($link) | Should -BeFalse
        [IO.File]::Exists($sentinel) | Should -BeTrue
    }

    It 'ignores the current Windows root and detects a different Windows installation' {
        $script:SystemRootUnderTest = Join-Path $TestDrive 'SystemVolume'
        $script:OtherRootUnderTest = Join-Path $TestDrive 'OtherVolume'
        [void][IO.Directory]::CreateDirectory(
            (Join-Path $script:SystemRootUnderTest 'Windows'))
        [void][IO.Directory]::CreateDirectory(
            (Join-Path $script:OtherRootUnderTest 'Windows'))

        Mock Get-PSDrive {
            @([pscustomobject]@{ Root = $script:SystemRootUnderTest })
        }
        Test-AtlasOtherWindowsInstall -SystemRoot $script:SystemRootUnderTest |
            Should -BeFalse

        Mock Get-PSDrive {
            @(
                [pscustomobject]@{ Root = $script:SystemRootUnderTest }
                [pscustomobject]@{ Root = $script:OtherRootUnderTest }
            )
        }
        Test-AtlasOtherWindowsInstall -SystemRoot $script:SystemRootUnderTest |
            Should -BeTrue
    }

    It 'returns before every machine mutation when another Windows installation exists' {
        Mock Test-AtlasOtherWindowsInstall { $true }
        Mock Invoke-AtlasDiskCleanup {}
        Mock Invoke-AtlasTempCleanup {}
        Mock Invoke-AtlasSystemShadowCopyCleanup {}

        Invoke-AtlasMachineCleanup -SystemRoot $TestDrive -WindowsRoot $TestDrive `
            -CleanMgrPath (Join-Path $TestDrive 'missing-cleanmgr.exe') `
            -VssAdminPath (Join-Path $TestDrive 'missing-vssadmin.exe')

        Should -Invoke Test-AtlasOtherWindowsInstall -Times 1 -Exactly
        Should -Invoke Invoke-AtlasDiskCleanup -Times 0 -Exactly
        Should -Invoke Invoke-AtlasTempCleanup -Times 0 -Exactly
        Should -Invoke Invoke-AtlasSystemShadowCopyCleanup -Times 0 -Exactly
    }
}
