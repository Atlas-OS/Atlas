function Remove-AtlasMicrosoftStore {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Removing Microsoft Store for all users...'
    }
    $packages = @(Get-AppxPackage -AllUsers Microsoft.WindowsStore -ErrorAction Stop)
    foreach ($package in $packages) {
        $package | Remove-AppxPackage -AllUsers -ErrorAction Stop
    }

    if (-not $Toggle.Silent) {
        Write-AtlasNote -Text 'Enable Microsoft Store restores it for your account and may download it again.'
    }
}

function Register-AtlasMicrosoftStore {
    param($Toggle)

    $packages = @(Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' })
    if ($packages.Count -eq 0) {
        try {
            # Windows resolves the staged family, including a package not registered
            # to any current user. Never register into an alternate administrator.
            Add-AppxPackage -RegisterByFamilyName -MainPackage 'Microsoft.WindowsStore_8wekyb3d8bbwe' -ErrorAction Stop
        }
        catch {
            if (-not $Toggle.Silent) {
                Write-AtlasStep -Text 'Microsoft Store is not available on this PC. Downloading it from Microsoft...'
            }
            Import-AtlasModule -Name Atlas.Download
            $wingetPath = Get-AtlasTrustedWingetPath
            Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
            [void](Invoke-AtlasToggleNativeCommand -FilePath $wingetPath `
                    -ArgumentList ([string[]]@(
                            'install', '--exact', '--id', '9WZDNCRFJBMP', '--source', 'msstore',
                            '--silent', '--accept-source-agreements', '--accept-package-agreements',
                            '--disable-interactivity'
                        )) `
                    -AllowedExitCodes ([int[]]@(0)))
        }
    }
    if (@(Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction Stop | Where-Object { [string]$_.Status -eq 'Ok' }).Count -eq 0) {
        throw 'Microsoft Store registration did not produce a healthy package for this user.'
    }

    if (-not $Toggle.Silent) {
        Write-AtlasSuccess -Text 'Microsoft Store is registered for your account.'
        Write-AtlasNextStep -Text 'Open Microsoft Store to confirm it works.'
    }
}
