function Get-RegUserPaths {
    param (
        [switch]$DontCheckEnv,
        [switch]$NoDefault
    )

    $regPattern = 'Volatile Environment|AME_UserHive_'
    $defaultPathPattern = '(^|\\)\.DEFAULT$|(^|\\)AME_UserHive_Default$'

    $initPaths = Get-ChildItem -Path "Registry::HKU" |
        Where-Object {
            $keyName = $_.Name
            $isUserHive = $keyName -match 'S-[0-9-]+(?!.*_)' -or $keyName -match 'AME_UserHive_'
            $isDefaultHive = $keyName -match $defaultPathPattern

            $isUserHive -and (-not ($NoDefault -and $isDefaultHive))
        }

    # If the 'Volatile Environment' key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
    $paths = @()
    if (!$DontCheckEnv) {
        foreach ($userKey in $initPaths) {
            $hasUserMarker = Get-ChildItem -Path $userKey.PsPath | Where-Object { $_.Name -match $regPattern }
            if ($hasUserMarker) {
                $paths += $userKey
            }
        }
    } else {
        $paths = $initPaths
    }

    return @($paths)
}

Export-ModuleMember -Function Get-RegUserPaths