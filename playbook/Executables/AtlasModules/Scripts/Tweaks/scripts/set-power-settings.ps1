# Companion of set-power-settings.psd1.
$ErrorActionPreference = 'Stop'
$systemDirectory = [Environment]::SystemDirectory
$powerCfgPath = [IO.Path]::Combine($systemDirectory, 'powercfg.exe')
$powerSavingScript = [IO.Path]::GetFullPath([IO.Path]::Combine(
        $PSScriptRoot,
        '..',
        '..',
        'Internal',
        'Set-PowerSavingState.ps1'
    ))

function Invoke-AtlasPowerSettingsNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not [IO.File]::Exists($FilePath)) {
        throw "$Description is missing at '$FilePath'."
    }

    $nativeOutput = @(& $FilePath @ArgumentList 2>&1)
    $nativeExitCode = $LASTEXITCODE
    if ($null -eq $nativeExitCode -or [int]$nativeExitCode -ne 0) {
        $diagnostic = (@($nativeOutput | ForEach-Object { [string]$_ }) -join ' ').Trim()
        if ($diagnostic.Length -gt 512) {
            $diagnostic = $diagnostic.Substring(0, 512)
        }
        throw "$Description failed with exit code '$nativeExitCode'. $diagnostic"
    }
    return @($nativeOutput)
}

$disablePowerSaving = [bool](Test-AtlasOption -Name 'disable-power-saving')
$disableHibernation = [bool](Test-AtlasOption -Name 'disable-hibernation')

if ($disablePowerSaving) {
    if (-not [IO.File]::Exists($powerSavingScript)) {
        throw "The fixed power-saving helper is missing at '$powerSavingScript'."
    }
    $null = & $powerSavingScript -Mode Atlas -Silent
}

# Disabling hibernation also makes NTFS accessible outside Windows.
if ($disableHibernation) {
    $null = Invoke-AtlasPowerSettingsNative -FilePath $powerCfgPath `
        -ArgumentList ([string[]]@('/hibernate', 'off')) `
        -Description 'Hibernation disable operation'
    $flyoutPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
    if (-not (Test-Path -LiteralPath $flyoutPath)) {
        $null = New-Item -Path $flyoutPath -Force -ErrorAction Stop
    }
    Set-ItemProperty -LiteralPath $flyoutPath -Name 'ShowHibernateOption' `
        -Value 0 -Type DWord -Force -ErrorAction Stop
}

# Keep the Balanced power scheme when power saving is retained.
if (-not $disablePowerSaving) {
    $balancedScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $null = Invoke-AtlasPowerSettingsNative -FilePath $powerCfgPath `
        -ArgumentList ([string[]]@('/setactive', $balancedScheme)) `
        -Description 'Balanced power-scheme selection'
    $activeOutput = @(Invoke-AtlasPowerSettingsNative -FilePath $powerCfgPath `
            -ArgumentList ([string[]]@('/getactivescheme')) `
            -Description 'Active power-scheme verification')
    $activeText = @($activeOutput | ForEach-Object { [string]$_ }) -join "`n"
    $guidMatches = @([regex]::Matches(
            $activeText,
            '(?i)(?<![0-9a-f])[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}(?![0-9a-f])'
        ) | ForEach-Object { $_.Value.ToLowerInvariant() } | Sort-Object -Unique)
    if ($guidMatches.Count -ne 1 -or $guidMatches[0] -cne $balancedScheme) {
        throw 'Balanced power-scheme selection failed its active-scheme postcondition.'
    }
}
