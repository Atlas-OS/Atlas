Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' |
    Where-Object { $_.Name -notmatch 'Xbl|Xbox' } |
    ForEach-Object {
        if ($null -ne (Get-ItemProperty -Path "Registry::$_" -ErrorAction SilentlyContinue).Start) {
            Set-ItemProperty -Path "Registry::$_" -Name 'SvcHostSplitDisable' -Type DWORD -Value 1 -Force -ErrorAction SilentlyContinue
        }
    }
