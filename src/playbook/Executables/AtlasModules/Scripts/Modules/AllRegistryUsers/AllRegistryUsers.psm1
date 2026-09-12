function Get-RegUserPaths {
    param (
        [switch]$DontCheckEnv,
        [switch]$NoDefault
    )

    $regPattern = 'Volatile Environment|AME_UserHive_'
    if ($NoDefault) {$regPattern = "$regPattern[1-9].*"}
    $initPaths = Get-ChildItem -Path "Registry::HKU" | Where-Object { $_.Name -match "S-[0-9-]+(?!.*_)|$regPattern" }

    # If the 'Volatile Environment' key exists, that means it is a proper user. Built in accounts/SIDs don't have this key
    $paths = @()
    if (!$DontCheckEnv) {
        foreach ($userKey in $initPaths) {
            if ((Get-ChildItem -Path $userKey.PsPath | Where-Object { $_ -match $regPattern }).Count -ne 0) {
                $paths += $userKey
            }
        }
    } else {
        $paths = $initPaths
    }

    return $paths
}

Export-ModuleMember -Function Get-RegUserPaths