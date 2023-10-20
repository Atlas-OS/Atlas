<#
 .Synopsis
  Sets a certain user Registry value for all users. 
 
 .Example
  Atlas-AllUserRegistry -Action AddValue -Path "\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -Value 0
#>

function Atlas-AllUserRegistry {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("AddKey", "DeleteKey", "AddValue", "DeleteValue")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string]$Name,

        [string]$Value,

        [ValidateSet("String", "ExpandString", "Binary", "DWord", "QWord", "MultiString")]
        [string]$PropertyType = "DWord"
    )

    if ($Action -eq "AddKey" -and -not $Path) {
        throw "Parameter 'Path' is mandatory when 'Action' is set to 'AddKey'."
    }

    if (($Action -eq "AddValue" -or $Action -eq "DeleteValue") -and -not $Name) {
        throw "Parameter 'Name' is mandatory when 'Action' is set to 'AddValue' or 'DeleteValue'."
    }

    if ($Action -eq "AddValue" -and (-not $PropertyType -or -not $Value)) {
        throw "Parameters 'PropertyType' and 'Value' are mandatory when 'Action' is set to 'AddValue'."
    }

    Get-ChildItem "Registry::HKEY_USERS" | ForEach-Object {
        $userKey = $_.Name
        if ($userKey -match '^HKEY_USERS\\.DEFAULT') {$DEFAULT = $true} else {$DEFAULT = $false}
        if ($userKey -match "^HKEY_USERS\\S-.+" -or $userKey -match "^HKEY_USERS\\AME_UserHive_[^_]*" -or $DEFAULT) {
            $userKey1 = "Registry::$userKey"
            if ((Test-Path "$userKey1\Volatile Environment") -or (Test-Path "$userKey1\AME_UserHive_") -or $DEFAULT) {
                $userPath = Join-Path $userKey1 $Path
                
                if (!($DEFAULT)) {
                    $SID = New-Object System.Security.Principal.SecurityIdentifier($userKey -replace "^HKEY_USERS\\","")
                    $objUser = $SID.Translate([System.Security.Principal.NTAccount])
                    $username = $objUser.Value
                } else {$username = 'DEFAULT'}

                switch ($Action) {
                    "AddKey" {
                        New-Item -Path $userPath -Name $Name -Force | Out-Null
                        if ($?) {Write-Host "Added key '$Path' for $username."}
                    }
                    "DeleteKey" {
                        Remove-Item -Path $userPath -Force -Recurse | Out-Null
                        if ($?) {Write-Host "Removed key '$Path' for $username."}
                    }
                    "AddValue" {
                        New-Item -Path $userPath -Force | Out-Null
                        New-ItemProperty -Path $userPath -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
                        if ($?) {Write-Host "Added value '$Name' under '$Path' for $username."}
                    }
                    "DeleteValue" {
                        Remove-ItemProperty -Path $userPath -Name $Name -Force | Out-Null
                        if ($?) {Write-Host "Deleted value '$Name' under '$Path' for $username."}
                    }
                }
            }
        }
    }
}

Export-ModuleMember -Function Atlas-AllUserRegistry