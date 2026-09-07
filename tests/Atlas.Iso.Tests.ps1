BeforeAll {
    $script:IsoResources = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $script:IsoResources 'Build-Iso.ps1'), [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    $function = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Assert-BootCatalog' }, $true)
    . ([scriptblock]::Create($function.Extent.Text))
    $xmlLiteral = $ast.Find({ param($n) $n -is [Management.Automation.Language.StringConstantExpressionAst] -and $n.Value.StartsWith('<?xml') }, $true)
    $script:Answer = [xml]$xmlLiteral.Value
    $script:Media = Join-Path $TestDrive 'media'
    New-Item -ItemType Directory -Path (Join-Path $script:Media 'boot'), (Join-Path $script:Media 'efi\microsoft\boot') -Force | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $script:Media 'boot\etfsboot.com'), (New-Object byte[] 4096))
    [IO.File]::WriteAllBytes((Join-Path $script:Media 'efi\microsoft\boot\efisys.bin'), (New-Object byte[] 2048))
    $script:Image = Join-Path $TestDrive 'test.iso'
    $script:Cancel = Join-Path $TestDrive 'cancel'
    & (Join-Path $script:IsoResources 'Master-Iso.ps1') -Media $script:Media -Output $script:Image -CancelFile $script:Cancel
}

Describe 'Native ISO mastering' {
    It 'uses one local-account bootstrap and a native first-logon handoff' {
        $oobe = @($script:Answer.unattend.settings | Where-Object pass -eq 'oobeSystem')[0].component
        $oobe.OOBE.HideOnlineAccountScreens | Should -Be 'true'
        $oobe.OOBE.ProtectYourPC | Should -Be '3'
        $oobe.OOBE.HideEULAPage | Should -Be 'true'
        $oobe.UserAccounts.LocalAccounts.LocalAccount.Group | Should -Be 'Administrators'
        $oobe.AutoLogon.LogonCount | Should -Be '1'
        $oobe.FirstLogonCommands.SynchronousCommand.CommandLine | Should -Match '-FirstLogon'
        @($oobe.FirstLogonCommands.SynchronousCommand) | Should -HaveCount 1
    }
    It 'makes the answer file discoverable in WinPE before the destination specialize pass' {
        # Without a valid current pass, Setup silently ignores the answer file.
        $pe = @($script:Answer.unattend.settings | Where-Object pass -eq 'windowsPE')
        $pe | Should -HaveCount 1
        $pe[0].component.name | Should -Be 'Microsoft-Windows-Setup'
        $pe[0].component.EnableFirewall | Should -Be 'true'
        $pe[0].component.UserData.ProductKey.WillShowUI | Should -Be 'Always'
        $pe[0].component.UserData.ProductKey.Key | Should -BeNullOrEmpty
        $pe[0].component.ImageInstall.OSImage.WillShowUI | Should -Be 'Always'
        $pe[0].component.ImageInstall.OSImage.InstallFrom | Should -BeNullOrEmpty
        $specialize = @($script:Answer.unattend.settings | Where-Object pass -eq 'specialize')
        $specialize | Should -HaveCount 1
        $specialize[0].component.RunSynchronous.RunSynchronousCommand.Path | Should -Match 'AtlasISO\\Setup.ps1'
    }
    It 'creates a complete image with independently readable BIOS and UEFI catalog entries' {
        { Assert-BootCatalog $script:Image } | Should -Not -Throw
        (Get-Item $script:Image).Length % 2048 | Should -Be 0
    }
    It 'rejects a truncated image' {
        $bad = Join-Path $TestDrive 'truncated.iso'
        [IO.File]::WriteAllBytes($bad, (New-Object byte[] 64))
        { Assert-BootCatalog $bad } | Should -Throw '*Truncated*'
    }
    It 'does not overwrite an existing output' {
        $before = (Get-FileHash $script:Image).Hash
        { & (Join-Path $script:IsoResources 'Master-Iso.ps1') -Media $script:Media -Output $script:Image -CancelFile $script:Cancel } | Should -Throw
        (Get-FileHash $script:Image).Hash | Should -Be $before
    }
    It 'honours cancellation before writing any image bytes' {
        [IO.File]::WriteAllText($script:Cancel, 'cancel')
        $output = Join-Path $TestDrive 'cancelled.iso'
        { & (Join-Path $script:IsoResources 'Master-Iso.ps1') -Media $script:Media -Output $output -CancelFile $script:Cancel } | Should -Throw '*cancelled*'
        (Get-Item $output).Length | Should -Be 0
    }
}
