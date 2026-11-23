BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:IsoResources = Join-Path $script:AtlasTestRepoRoot 'app\resources\iso'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $script:IsoResources 'Build-Iso.ps1'), [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in @('Assert-BootCatalog', 'Get-AtlasIsoDestinationVolume', 'Assert-Output', 'Open-AtlasIsoManager')) {
        $function = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    function Fail([string]$Reason, [string]$Message) { throw "$($Reason): $Message" }
    function Get-TestIsoOutput {
        Assert-Output -OutputPath (Join-Path $TestDrive 'destination.iso') -PackagePath $script:Media -SourcePath $script:Image
    }
    # The worker's statements from the answer template to the finished file, so the
    # tests read what the media carries after the account name and architecture go in.
    $answerSteps = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$answer' }, $true))
    $start = $answerSteps[0].Extent.StartOffset
    $script:WriteAnswer = [scriptblock]::Create($ast.Extent.Text.Substring($start, $answerSteps[-1].Extent.EndOffset - $start))
    $pathsStart = $ast.Find({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$answerPaths' }, $true)
    $writeFiles = $ast.Find({ param($n) $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -eq '$answerPaths' }, $true)
    $script:WriteAnswerFiles = [scriptblock]::Create("param(`$supportedEditions)`n" + $ast.Extent.Text.Substring($pathsStart.Extent.StartOffset, $writeFiles.Extent.EndOffset - $pathsStart.Extent.StartOffset))
    function New-TestAnswer([string]$architecture, [string]$username, [string]$acceptedTerms) {
        . $script:WriteAnswer
        [xml]$answer
    }
    $script:Answer = New-TestAnswer x64 'Atlas'
    $script:Media = Join-Path $TestDrive 'media'
    New-Item -ItemType Directory -Path (Join-Path $script:Media 'boot'), (Join-Path $script:Media 'efi\microsoft\boot') -Force | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $script:Media 'boot\etfsboot.com'), (New-Object byte[] 4096))
    [IO.File]::WriteAllBytes((Join-Path $script:Media 'efi\microsoft\boot\efisys.bin'), (New-Object byte[] 2048))
    $script:Image = Join-Path $TestDrive 'test.iso'
    $script:Cancel = Join-Path $TestDrive 'cancel'
    & (Join-Path $script:IsoResources 'Master-Iso.ps1') -Media $script:Media -Output $script:Image -CancelFile $script:Cancel
}

Describe 'ISO Manager executable' {
    It 'can add the same executable after its original path disappears' {
        $source = Join-Path $TestDrive 'AtlasManager.exe'
        $moved = Join-Path $TestDrive 'moved.exe'
        [IO.File]::WriteAllText($source, 'original')

        $stream = Open-AtlasIsoManager $source
        try {
            [IO.File]::Move($source, $moved)
            [IO.File]::WriteAllText($source, 'replacement')
            $reader = New-Object IO.StreamReader($stream)
            try { $reader.ReadToEnd() | Should -BeExactly 'original' }
            finally { $reader.Dispose() }
        } finally { $stream.Dispose() }
    }

    It 'reports an executable that was already removed' -ForEach @(
        @{ RelativePath = 'deleted.exe' }
        @{ RelativePath = 'removed\AtlasManager.exe' }
    ) {
        { Open-AtlasIsoManager (Join-Path $TestDrive $RelativePath) } | Should -Throw 'manager-missing:*'
    }
}

Describe 'ISO destination validation' {
    It 'reads the filesystem and free space for a local folder' {
        $volume = Get-AtlasIsoDestinationVolume -Path $script:Media
        $volume.FileSystem | Should -BeIn @('NTFS', 'ReFS')
        $volume.AvailableBytes | Should -BeGreaterOrEqual 0
    }

    It 'reports an unrecognised destination when Windows cannot query the volume' {
        Mock Get-AtlasIsoDestinationVolume { throw 'Volume lookup failed' }
        { Get-TestIsoOutput } | Should -Throw 'destination-filesystem:*Volume lookup failed*'
    }

    It 'rejects unsupported destination filesystems' {
        Mock Get-AtlasIsoDestinationVolume { [pscustomobject]@{ FileSystem = 'exFAT'; AvailableBytes = 64GB } }
        { Get-TestIsoOutput } | Should -Throw 'destination-filesystem:*'
    }

    It 'still reports insufficient space on a supported filesystem' {
        Mock Get-AtlasIsoDestinationVolume { [pscustomobject]@{ FileSystem = 'ReFS'; AvailableBytes = 0 } }
        { Get-TestIsoOutput } | Should -Throw 'disk-space:*'
    }
}

Describe 'Native ISO mastering' {
    It 'uses one local-account bootstrap and a native first-logon handoff' {
        $oobe = @($script:Answer.unattend.settings | Where-Object pass -eq 'oobeSystem')[0].component
        $oobe.OOBE.HideOnlineAccountScreens | Should -Be 'true'
        $oobe.OOBE.HideWirelessSetupInOOBE | Should -Be 'true'
        $oobe.OOBE.ProtectYourPC | Should -Be '3'
        $oobe.OOBE.HideEULAPage | Should -Be 'false'
        $oobe.UserAccounts.LocalAccounts.LocalAccount.Group | Should -Be 'Administrators'
        $oobe.AutoLogon.LogonCount | Should -Be '1'
        $oobe.FirstLogonCommands.SynchronousCommand.CommandLine | Should -Match '-FirstLogon'
        @($oobe.FirstLogonCommands.SynchronousCommand) | Should -HaveCount 1
    }
    It 'only skips the Windows licence pages after explicit acceptance' {
        $script:Answer.unattend.settings[0].component.UserData.AcceptEula | Should -Be 'false'
        $accepted = New-TestAnswer x64 'Atlas' -acceptedTerms 'verified-media'
        $accepted.unattend.settings[0].component.UserData.AcceptEula | Should -Be 'true'
        ($accepted.unattend.settings | Where-Object pass -eq 'oobeSystem').component.OOBE.HideEULAPage | Should -Be 'true'
    }
    It 'makes the answer file discoverable in WinPE before the destination specialize pass' {
        # Without a valid current pass, Setup silently ignores the answer file.
        $pe = @($script:Answer.unattend.settings | Where-Object pass -eq 'windowsPE')
        $pe | Should -HaveCount 1
        $pe[0].component.name | Should -Be 'Microsoft-Windows-Setup'
        $pe[0].component.EnableFirewall | Should -Be 'true'
        $pe[0].component.DynamicUpdate.Enable | Should -Be 'false'
        $pe[0].component.DynamicUpdate.WillShowUI | Should -Be 'Never'
        $pe[0].component.UserData.ProductKey.WillShowUI | Should -Be 'Always'
        $pe[0].component.UserData.ProductKey.Key | Should -BeNullOrEmpty
        $pe[0].component.ImageInstall.OSImage.WillShowUI | Should -Be 'Always'
        $pe[0].component.ImageInstall.OSImage.InstallFrom | Should -BeNullOrEmpty
        $specialize = @($script:Answer.unattend.settings | Where-Object pass -eq 'specialize')
        $specialize | Should -HaveCount 1
        $specialize[0].component.RunSynchronous.RunSynchronousCommand.Path | Should -Match 'AtlasISO\\Setup.ps1'
    }
    It 'stages the answer for the correct setup pass on <Edition> media' -ForEach @(
        @{ Edition = 'EnterpriseEval'; AnswerInWinPE = $false }
        @{ Edition = 'Professional'; AnswerInWinPE = $true }
    ) {
        $media = Join-Path $TestDrive $Edition
        $answer = $script:Answer.OuterXml
        . $script:WriteAnswerFiles @([pscustomobject]@{ EditionId = $Edition })
        Test-Path (Join-Path $media 'autounattend.xml') | Should -Be $AnswerInWinPE
        Test-Path (Join-Path $media 'sources\autounattend.xml') | Should -Be $AnswerInWinPE
        Test-Path (Join-Path $media 'sources\$OEM$\$$\Panther\unattend.xml') | Should -Be (!$AnswerInWinPE)
        foreach ($relative in $answerPaths) {
            [IO.File]::ReadAllText((Join-Path $media $relative)) | Should -BeExactly $answer
        }
    }
    It 'names the account and matches the components to <Architecture> media' -ForEach @(
        @{ Architecture = 'x64'; Expected = 'amd64' }
        @{ Architecture = 'arm64'; Expected = 'arm64' }
    ) {
        # Setup.ps1 refuses a first logon whose account isn't the configured name.
        $name = 'A&B'
        $answer = New-TestAnswer $Architecture $name
        $answer.OuterXml | Should -Not -Match 'ATLAS_LOCAL_ACCOUNT'
        $oobe = @($answer.unattend.settings | Where-Object pass -eq 'oobeSystem')[0].component
        $oobe.UserAccounts.LocalAccounts.LocalAccount.Name | Should -BeExactly $name
        $oobe.AutoLogon.Username | Should -BeExactly $name
        $oobe.RegisteredOwner | Should -BeExactly $name
        $components = @($answer.unattend.settings.component)
        $components | Should -HaveCount 3
        foreach ($component in $components) { $component.processorArchitecture | Should -BeExactly $Expected }
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
    It 'creates ARM64 media with a UEFI boot catalog and no BIOS boot file' {
        $armMedia = Join-Path $TestDrive 'arm-media'
        New-Item -ItemType Directory -Path (Join-Path $armMedia 'efi\microsoft\boot') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $armMedia 'efi\microsoft\boot\efisys.bin'), (New-Object byte[] 4096))
        $armIso = Join-Path $TestDrive 'arm.iso'
        & (Join-Path $script:IsoResources 'Master-Iso.ps1') -Media $armMedia -Output $armIso -CancelFile $script:Cancel -Architecture arm64
        { Assert-BootCatalog $armIso arm64 } | Should -Not -Throw
        { Assert-BootCatalog $armIso x64 } | Should -Throw '*BIOS and UEFI*'
        { Assert-BootCatalog $script:Image arm64 } | Should -Throw '*UEFI entry for ARM64*'
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
