# Atlas.Services domain: backup of default Windows service start values.
#
# Exports every service's Start value to a .reg file (imported by the
# "Windows Default Services" toggle) before Atlas changes them.

function Export-AtlasServicesBackup {
    <#
    .SYNOPSIS
        Exports the Start value of every service/driver under CurrentControlSet to a
        reg.exe-compatible .reg file. Does nothing when the file already exists, so the
        first backup (the Windows defaults) is never overwritten. Windows Defender
        services are excluded because their Start values are locked.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$FilePath = (Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Other\winServices.reg')
    )

    if (Test-Path -LiteralPath $FilePath) {
        Write-AtlasLog -Message "Services backup '$FilePath' already exists; keeping the original backup."
        return
    }

    $parentPath = Split-Path -Parent $FilePath
    if ($parentPath -and -not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
    }

    $content = [System.Collections.Generic.List[string]]::new()
    $content.Add('Windows Registry Editor Version 5.00')

    foreach ($serviceKey in (Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services')) {
        $serviceProps = Get-ItemProperty -Path $serviceKey.PSPath -ErrorAction SilentlyContinue
        if ($null -eq $serviceProps) {
            continue
        }

        $startProperty = $serviceProps.PSObject.Properties['Start']
        if ($null -eq $startProperty) {
            continue
        }
        $startValue = $startProperty.Value

        $description = $null
        $descriptionProperty = $serviceProps.PSObject.Properties['Description']
        if ($null -ne $descriptionProperty) {
            $description = [string]$descriptionProperty.Value
        }

        if (($null -ne $description) -and ($description -match 'Windows Defender')) {
            Write-Host "Excluding $($serviceKey.Name)..."
            continue
        }

        $content.Add("`n[$($serviceKey.Name)]")
        $content.Add('"Start"=dword:0000000' + $startValue)
    }

    # Set-Content can only do UTF8 with BOM on 5.1, which doesn't work with reg.exe
    [System.IO.File]::WriteAllLines($FilePath, $content, (New-Object System.Text.UTF8Encoding $false))
    Write-AtlasLog -Message "Exported the default service configuration to '$FilePath'."
}
