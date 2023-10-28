# Removes 'Bitmap' from the 'New' context menu in Windows 11
foreach ($userKey in $((Get-ChildItem -Path "Registry::HKEY_USERS").Name | Where-Object { $_ -like '*_Classes' })) {
    foreach ($key in $(Get-ChildItem -Path "Registry::$userKey\Local Settings\MrtCache" -Recurse)) {
        $key | Get-ItemProperty | ForEach-Object {
            foreach ($value in $($_.PSObject.Properties.Name | Where-Object {$_ -like '*ShellNewDisplayName_Bmp*'})) {
                Set-ItemProperty -Path $key.PSPath -Name $value -Value ""
                Write-Host "Removed 'Bitmap' from 'New' context menu for $userKey..."
            }
        }
    }
}