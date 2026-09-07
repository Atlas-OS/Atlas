# Atlas.Search domain: per-user Microsoft Store search recommendation block.

function Disable-AtlasStoreSearchRecommendations {
    <#
    .SYNOPSIS
        Blocks the current user's Store search recommendations by denying Everyone all
        access to the Store's local search database (creating the file if needed).
    #>
    param(
        # Tests can supply an isolated local application-data root.
        [string]$LocalAppDataPath = [Environment]::GetFolderPath('LocalApplicationData')
    )

    if ([string]::IsNullOrWhiteSpace($LocalAppDataPath)) {
        throw 'LocalApplicationData is not available for the current user.'
    }

    $storeDb = Join-Path -Path $LocalAppDataPath `
        -ChildPath 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db'
    $storeDbParent = Split-Path -Path $storeDb -Parent

    New-Item -Path $storeDbParent -ItemType Directory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $storeDb -PathType Leaf)) {
        New-Item -Path $storeDb -ItemType File -Force | Out-Null
    }

    $icaclsPath = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'icacls.exe'
    Invoke-AtlasHiddenProcess -FilePath $icaclsPath `
        -ArgumentList @($storeDb, '/deny', '*S-1-1-0:F') -Wait | Out-Null
    Write-AtlasLog -Message "Denied Everyone access to the Store search database '$storeDb'."
}
