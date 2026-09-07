function Enable-AtlasWidgetsMachine {
    param($Toggle)

    # The policy values are removed only after the interactive Edge/WebView step
    # succeeds, so a declined Edge install leaves Widgets disabled.
    if (-not $Toggle.Silent) {
        $programFilesX86 = [Environment]::GetFolderPath(
            [Environment+SpecialFolder]::ProgramFilesX86
        )
        if ([string]::IsNullOrWhiteSpace($programFilesX86) -or
            -not [IO.Directory]::Exists($programFilesX86)) {
            throw 'Widgets: the 32-bit Program Files directory is unavailable.'
        }

        $edgePath = [IO.Path]::Combine(
            $programFilesX86,
            'Microsoft\Edge\Application\msedge.exe'
        )
        $installEdge = -not [IO.File]::Exists($edgePath)

        if ($installEdge) {
            Write-AtlasNote -Text 'Widgets needs Microsoft Edge, which is not installed.'
            if (-not (Read-AtlasYesNo -Question 'Install Microsoft Edge now?')) {
                throw 'Microsoft Edge is not installed and its installation was declined.'
            }
        }

        $edgeHelper = Join-Path -Path $Toggle.OperationsPath -ChildPath 'Remove-Edge.ps1'
        if (-not [IO.File]::Exists($edgeHelper)) {
            throw "Widgets: the Edge helper is missing at '$edgeHelper'."
        }

        $windowsPowerShell = [IO.Path]::Combine(
            $Toggle.WinDir,
            'System32\WindowsPowerShell\v1.0\powershell.exe'
        )
        if (-not [IO.File]::Exists($windowsPowerShell)) {
            throw "Widgets: Windows PowerShell is missing at '$windowsPowerShell'."
        }

        [string[]]$edgeArguments = @(
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $edgeHelper,
            '-NonInteractive',
            '-InstallWebView'
        )
        if ($installEdge) {
            $edgeArguments += '-InstallEdge'
            Write-AtlasStep -Text 'Installing Microsoft Edge and the Edge WebView2 runtime. This can take a few minutes...'
        }
        else {
            Write-AtlasStep -Text 'Updating the Edge WebView2 runtime. This can take a few minutes...'
        }
        [void](Invoke-AtlasToggleNativeCommand `
                -FilePath $windowsPowerShell `
                -ArgumentList $edgeArguments `
                -AllowedExitCodes ([int[]]@(0)))

        Write-AtlasStep -Text 'Enabling the Widgets policies...'
    }

    Set-AtlasMachineDwordPolicy -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Data 1
    foreach ($valueName in 'DisableWidgetsOnLockScreen', 'DisableWidgetsBoard') {
        Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name $valueName -AllowOsProtected
    }
}

function Install-AtlasWidgetsUser {
    param($Toggle)

    # The board and its news feed are separate apps. Restoring only WebExperience
    # leaves the board reporting that the feed provider was uninstalled.
    $packages = @(
        @{ Name = 'MicrosoftWindows.Client.WebExperience'; ProductId = '9MSSGKG348SP'; Label = 'Windows Web Experience Pack' }
        @{ Name = 'Microsoft.StartExperiencesApp'; ProductId = '9PC1H9VN18CM'; Label = 'Start Experiences App' }
    )
    $wingetPath = $null
    foreach ($package in $packages) {
        if (@(Get-AppxPackage -Name $package.Name -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' }).Count -eq 0) {
            if (-not $wingetPath) {
                Import-AtlasModule -Name Atlas.Download
                $wingetPath = Get-AtlasTrustedWingetPath
                Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
            }
            if (-not $Toggle.Silent) {
                Write-AtlasStep -Text "Installing the $($package.Label) from the Microsoft Store..."
            }
            [void](Invoke-AtlasToggleNativeCommand -FilePath $wingetPath -ArgumentList ([string[]]@(
                        'install', '--exact', '--id', $package.ProductId, '--source', 'msstore',
                        '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity'
                    )) -AllowedExitCodes ([int[]]@(0)))
        }
        if (@(Get-AppxPackage -Name $package.Name -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' }).Count -eq 0) {
            throw "$($package.Label) is not healthy for this user after installation."
        }
    }
    if (-not $Toggle.Silent) {
        Write-AtlasSuccess -Text 'The Widgets board and its news feed app are installed for your account.'
        Write-AtlasStep -Text 'Opening Settings > Personalization > Taskbar...'
        Start-Process 'ms-settings:taskbar' -ErrorAction Stop
        Write-AtlasNextStep -Text 'Turn on Widgets in the Taskbar settings that just opened. The button can take a few minutes to appear.'
    }
}
