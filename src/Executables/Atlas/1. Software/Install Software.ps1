function WriteList ($list, $name) {
    $listname = $list
    Start-Sleep -Seconds 2
    Clear-Host

    Write-Host "Please select a $name to install:"
    For ($i=0; $i -lt $listname.Count; $i++)  {
    Write-Host "$($i+1): $($listname[$i])"
    }

    [int]$number = Read-Host "Enter the number to select the option"
    Write-Host "You have selected $($listname[$number-1])."
    Start-Sleep -Seconds 2
    Clear-Host

    return $listname[$number-1]
}

$provider = WriteList -list @("Chocolatey", "Scoop") -name "provider"

function InstallBrowser {
    $script = $PSScriptRoot+"\Manual\Install Browser via $provider.ps1"
    & $script
}

function InstallAltSoft {
    $script = $PSScriptRoot+"\Manual\Install Other Software via $provider.ps1"
    & $script
}

function InstallSoftware {
    $type = WriteList -list @("Browser", "Other Software") -name "type of software"
    if ($type -eq "Browser") {
        InstallBrowser
    } else {
        InstallAltSoft
    }
}

if ($provider -eq "Chocolatey") {
    $ChocoInstalled = $false
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $ChocoInstalled = $true
    } else {
        Write-Host "Chocolatey not found, installing..."
        & "$PSScriptRoot\Manual\Install $provider.ps1"
    }
} else {
    $ScoopInstalled = $false
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $ScoopInstalled = $true
    } else {
        Write-Host "Scoop not found, installing..."
        & "$PSScriptRoot\Manual\Install $provider.ps1"
    }
}
InstallSoftware
