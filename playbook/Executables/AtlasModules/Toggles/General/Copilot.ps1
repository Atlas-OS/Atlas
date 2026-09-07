function Remove-AtlasCopilotApp {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Removing the Copilot app...'
    }
    Import-AtlasModule -Name Atlas.Appx
    Invoke-AtlasAppxRemovalPlan -Definition @(
        [pscustomobject]@{
            Name         = 'Microsoft.Copilot*'
            Option       = $null
            IgnoreErrors = $false
        }
    )
}

function Enable-AtlasCopilotMachine {
    param($Toggle)

    $programFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
    if ([string]::IsNullOrWhiteSpace($programFilesX86)) {
        throw 'Copilot: the 32-bit Program Files directory is unavailable.'
    }
    $edgePath = [IO.Path]::Combine($programFilesX86, 'Microsoft\Edge\Application\msedge.exe')
    if (-not [IO.File]::Exists($edgePath)) {
        throw 'Copilot needs Microsoft Edge, which is not installed. Install Edge from 1. Software, then try again.'
    }

    Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'RemoveMicrosoftCopilotApp'
}

function Enable-AtlasCopilotUser {
    param($Toggle)

    # When the taskbar Copilot button is unavailable (24H2+), Copilot ships as an app
    # installed through the trusted WinGet resolver; otherwise re-show the button.
    $available = Get-ItemPropertyValue -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Copilot' `
        -Name 'IsCopilotAvailable' -ErrorAction SilentlyContinue
    $legacyTaskbarAvailable = ($Toggle.WindowsBuild -lt 26100 -and $null -ne $available -and [int]$available -eq 1)
    if ($legacyTaskbarAvailable) {
        Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
            -Name 'ShowCopilotButton' -Type DWord -Data 1
        return
    }

    $installed = @(Get-AppxPackage -Name Microsoft.Copilot -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' })
    if ($installed.Count -gt 0) { return }

    if (-not $Toggle.Silent) {
        Write-AtlasNote -Text 'This Windows version has no Copilot taskbar button, so the Copilot app is installed instead.'
        Write-AtlasStep -Text 'Installing the Copilot app from the Microsoft Store. This can take a few minutes...'
    }
    Import-AtlasModule -Name Atlas.Download
    $wingetPath = Get-AtlasTrustedWingetPath
    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
    [void](Invoke-AtlasToggleNativeCommand -FilePath $wingetPath `
            -ArgumentList ([string[]]@(
                    'install', '--exact', '--id', '9NHT9RB2F4HD', '--source', 'msstore',
                    '--uninstall-previous', '--silent', '--accept-source-agreements',
                    '--accept-package-agreements', '--disable-interactivity'
                )) `
            -AllowedExitCodes ([int[]]@(0)))
    if (@(Get-AppxPackage -Name Microsoft.Copilot -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' }).Count -eq 0) {
        throw 'Copilot installation did not produce a healthy package for this user.'
    }
}
