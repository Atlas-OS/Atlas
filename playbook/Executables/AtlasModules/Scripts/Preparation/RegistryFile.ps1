# Applying a .reg file of HKLM policy values, such as the drivers choice. Function
# definitions only: the update worker and ISO setup dot-source this file, and
# neither may inherit a side effect from it. Windows PowerShell 5.1.

# Applies a .reg file of HKLM values under $Root (HKLM itself unless a test
# passes another key), noting each change in $Log. Unlike reg.exe import, a
# value to delete is deleted only where its key exists, so no empty key is left
# behind for it. A key marked for deletion goes when present. Only DWORD values
# and deletions are expected; the whole file is read first, so a line Atlas
# doesn't apply changes nothing.
function Import-AtlasRegistryFile([string]$Path, [string]$Log, [Microsoft.Win32.RegistryKey]$Root = [Microsoft.Win32.Registry]::LocalMachine) {
    $file = [IO.Path]::GetFileName($Path)
    $operations = [Collections.Generic.List[object]]::new()
    $key = $null
    foreach ($raw in ([IO.File]::ReadAllText($Path) -split "`r?`n")) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith(';') -or $line -like 'Windows Registry Editor Version*') { continue }
        if ($line -match '^\[(-?)HKEY_LOCAL_MACHINE\\([^\]]+)\]$') {
            $key = $Matches[2]
            if ($Matches[1]) {
                $operations.Add([pscustomobject]@{ Kind = 'delete-key'; Key = $key; Name = $null; Data = $null })
                $key = $null
            }
            continue
        }
        if ($null -eq $key -or $line -notmatch '^"([^"]+)"=(.+)$') { throw "$file has a line Atlas doesn't apply: $line" }
        $name = $Matches[1]
        if ($Matches[2] -eq '-') { $operations.Add([pscustomobject]@{ Kind = 'delete-value'; Key = $key; Name = $name; Data = $null }) }
        elseif ($Matches[2] -match '^dword:([0-9a-fA-F]{8})$') {
            $operations.Add([pscustomobject]@{ Kind = 'dword'; Key = $key; Name = $name; Data = [Convert]::ToUInt32($Matches[1], 16) })
        }
        else { throw "$file has a value Atlas doesn't apply: $line" }
    }
    foreach ($operation in $operations) {
        switch ($operation.Kind) {
            'delete-key' {
                $existing = $Root.OpenSubKey($operation.Key, $false)
                if ($null -eq $existing) { continue }
                $existing.Dispose()
                $Root.DeleteSubKeyTree($operation.Key)
                "Deleted HKLM\$($operation.Key)" | Add-Content -LiteralPath $Log -Encoding UTF8
            }
            'delete-value' {
                $handle = $Root.OpenSubKey($operation.Key, $true)
                if ($null -eq $handle) { continue }
                try {
                    if (@($handle.GetValueNames()) -contains $operation.Name) {
                        $handle.DeleteValue($operation.Name)
                        "Deleted HKLM\$($operation.Key)\$($operation.Name)" | Add-Content -LiteralPath $Log -Encoding UTF8
                    }
                }
                finally { $handle.Dispose() }
            }
            'dword' {
                $handle = $Root.CreateSubKey($operation.Key)
                try {
                    $handle.SetValue($operation.Name, [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$operation.Data), 0), [Microsoft.Win32.RegistryValueKind]::DWord)
                    "Set HKLM\$($operation.Key)\$($operation.Name) to $($operation.Data)" | Add-Content -LiteralPath $Log -Encoding UTF8
                }
                finally { $handle.Dispose() }
            }
        }
    }
}
