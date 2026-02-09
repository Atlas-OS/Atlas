param (
    [Parameter(Mandatory = $false)]
    [hashtable[]]$RegistryObjects,
    [switch]$Verbose
)

# Cache active user SIDs once at script start
$script:ActiveUserSIDs = $null

function Get-ActiveUserSIDsCached {
    if ($null -eq $script:ActiveUserSIDs) {
        $script:ActiveUserSIDs = @((Get-ChildItem "Registry::HKEY_USERS" -ErrorAction SilentlyContinue).PSChildName -match '^S-1-5-21-[\d-]+$')
    }
    return $script:ActiveUserSIDs
}

function Convert-PathToRegExe {
    param ([string]$Path, [string]$Scope, [string]$SID = $null)
    
    # Strip PowerShell provider prefixes and normalize
    $p = $Path -replace '^Registry::', '' -replace ':\\', '\' -replace ':$', ''
    
    switch ($Scope) {
        'currentUser' {
            $p = $p -replace '^HKEY_CURRENT_USER\\?', 'HKCU\' -replace '^HKCU\\?', 'HKCU\'
            if ($p -notmatch '^HKCU\\') { $p = "HKCU\$($p.TrimStart('\'))" }
        }
        'allUsers' {
            $p = $p -replace '^HKEY_LOCAL_MACHINE\\?', 'HKLM\' -replace '^HKLM\\?', 'HKLM\'
            if ($p -notmatch '^HKLM\\') { $p = "HKLM\$($p.TrimStart('\'))" }
        }
        'activeUsers' {
            if ($SID) {
                $p = $p -replace '^HKEY_CURRENT_USER\\?', '' -replace '^HKCU\\?', ''
                $p = "HKU\$SID\$($p.TrimStart('\'))"
            }
        }
        'defaultUsers' {
            $p = $p -replace '^HKEY_CURRENT_USER\\?', '' -replace '^HKCU\\?', ''
            $p = "HKU\.DEFAULT\$($p.TrimStart('\'))"
        }
    }
    return $p
}

function Get-ScopeFromPath {
    param ([string]$Path)
    if ($Path -match '^(HKCU|HKEY_CURRENT_USER)') { return 'currentUser' }
    if ($Path -match '^(HKLM|HKEY_LOCAL_MACHINE)') { return 'allUsers' }
    if ($Path -match '^(HKU|HKEY_USERS)') { return 'activeUsers' }
    return 'currentUser'
}


function Invoke-RegExe {
    param (
        [string]$Path,
        [string]$ValueName,
        [string]$Data,
        [string]$Type,
        [string]$Operation
    )
    
    switch ($Operation) {
        'add' {
            if ($ValueName) {
                # Add/set value
                $null = reg add $Path /v $ValueName /t $Type /d $Data /f 2>$null
            } else {
                # Create key only
                $null = reg add $Path /f 2>$null
            }
            if ($Verbose) { Write-Host "[ADD] $Path\$ValueName = $Data" -ForegroundColor Green }
        }
        'set' {
            if ($ValueName) {
                $null = reg add $Path /v $ValueName /t $Type /d $Data /f 2>$null
            }
            if ($Verbose) { Write-Host "[SET] $Path\$ValueName = $Data" -ForegroundColor Yellow }
        }
        'delete' {
            if ($ValueName) {
                $null = reg delete $Path /v $ValueName /f 2>$null
                if ($Verbose) { Write-Host "[DEL] $Path\$ValueName" -ForegroundColor Red }
            } else {
                $null = reg delete $Path /f 2>$null
                if ($Verbose) { Write-Host "[DEL] $Path" -ForegroundColor Red }
            }
        }
    }
}

function Invoke-RegistryModification {
    param ([hashtable[]]$RegistryObjects)
    
    foreach ($hash in $RegistryObjects) {
        $scope = if ($hash.Scope) { $hash.Scope } else { Get-ScopeFromPath -Path $hash.Path }
        $operation = if ($hash.Operation) { $hash.Operation } else { 'add' }
        $type = if ($hash.Type) { $hash.Type } else { 'REG_SZ' }
        
        switch ($scope) {
            'activeUsers' {
                foreach ($sid in (Get-ActiveUserSIDsCached)) {
                    $regPath = Convert-PathToRegExe -Path $hash.Path -Scope $scope -SID $sid
                    Invoke-RegExe -Path $regPath -ValueName $hash.Value -Data $hash.Data -Type $type -Operation $operation
                }
            }
            default {
                $regPath = Convert-PathToRegExe -Path $hash.Path -Scope $scope
                Invoke-RegExe -Path $regPath -ValueName $hash.Value -Data $hash.Data -Type $type -Operation $operation
            }
        }
    }
}

# Main execution
if ($RegistryObjects) {
    Invoke-RegistryModification -RegistryObjects $RegistryObjects
}
