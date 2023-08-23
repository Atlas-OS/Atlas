function Get-Hash {
    [CmdletBinding()]
    param (
      [Parameter( Position = 0, Mandatory = $True )]
      [string]
      $BaseInfo
    )


    function local:Get-ShiftRight {
      [CmdletBinding()]
      param (
        [Parameter( Position = 0, Mandatory = $true)]
        [long] $iValue, 
            
        [Parameter( Position = 1, Mandatory = $true)]
        [int] $iCount 
      )
    
      if ($iValue -band 0x80000000) {
        Write-Output (( $iValue -shr $iCount) -bxor 0xFFFF0000)
      }
      else {
        Write-Output  ($iValue -shr $iCount)
      }
    }
    

    function local:Get-Long {
      [CmdletBinding()]
      param (
        [Parameter( Position = 0, Mandatory = $true)]
        [byte[]] $Bytes,
    
        [Parameter( Position = 1)]
        [int] $Index = 0
      )
    
      Write-Output ([BitConverter]::ToInt32($Bytes, $Index))
    }

    function local:Convert-Int32 {
      param (
        [Parameter( Position = 0, Mandatory = $true)]
        $Value
      )
    
      [byte[]] $bytes = [BitConverter]::GetBytes($Value)
      return [BitConverter]::ToInt32( $bytes, 0) 
    }

    [Byte[]] $bytesBaseInfo = [System.Text.Encoding]::Unicode.GetBytes($baseInfo) 
    $bytesBaseInfo += 0x00, 0x00  
    
    $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    [Byte[]] $bytesMD5 = $MD5.ComputeHash($bytesBaseInfo)
    
    $lengthBase = ($baseInfo.Length * 2) + 2 
    $length = (($lengthBase -band 4) -le 1) + (Get-ShiftRight $lengthBase  2) - 1
    $base64Hash = ""

    if ($length -gt 1) {
    
      $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
        R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
      }
    
      $map.CACHE = 0
      $map.OUTHASH1 = 0
      $map.PDATA = 0
      $map.MD51 = (((Get-Long $bytesMD5) -bor 1) + 0x69FB0000L)
      $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1) + 0x13DB0000L
      $map.INDEX = Get-ShiftRight ($length - 2) 1
      $map.COUNTER = $map.INDEX + 1
    
      while ($map.COUNTER) {
        $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + [long]$map.OUTHASH1)
        $map.R1[0] = Convert-Int32 (Get-Long $bytesBaseInfo ($map.PDATA + 4))
        $map.PDATA = $map.PDATA + 8
        $map.R2[0] = Convert-Int32 (($map.R0 * ([long]$map.MD51)) - (0x10FA9605L * ((Get-ShiftRight $map.R0 16))))
        $map.R2[1] = Convert-Int32 ((0x79F8A395L * ([long]$map.R2[0])) + (0x689B6B9FL * (Get-ShiftRight $map.R2[0] 16)))
        $map.R3 = Convert-Int32 ((0xEA970001L * $map.R2[1]) - (0x3C101569L * (Get-ShiftRight $map.R2[1] 16) ))
        $map.R4[0] = Convert-Int32 ($map.R3 + $map.R1[0])
        $map.R5[0] = Convert-Int32 ($map.CACHE + $map.R3)
        $map.R6[0] = Convert-Int32 (($map.R4[0] * [long]$map.MD52) - (0x3CE8EC25L * (Get-ShiftRight $map.R4[0] 16)))
        $map.R6[1] = Convert-Int32 ((0x59C3AF2DL * $map.R6[0]) - (0x2232E0F1L * (Get-ShiftRight $map.R6[0] 16)))
        $map.OUTHASH1 = Convert-Int32 ((0x1EC90001L * $map.R6[1]) + (0x35BD1EC9L * (Get-ShiftRight $map.R6[1] 16)))
        $map.OUTHASH2 = Convert-Int32 ([long]$map.R5[0] + [long]$map.OUTHASH1)
        $map.CACHE = ([long]$map.OUTHASH2)
        $map.COUNTER = $map.COUNTER - 1
      }

      [Byte[]] $outHash = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
      [byte[]] $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
      $buffer.CopyTo($outHash, 0)
      $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
      $buffer.CopyTo($outHash, 4)
    
      $map = @{PDATA = 0; CACHE = 0; COUNTER = 0 ; INDEX = 0; MD51 = 0; MD52 = 0; OUTHASH1 = 0; OUTHASH2 = 0;
        R0 = 0; R1 = @(0, 0); R2 = @(0, 0); R3 = 0; R4 = @(0, 0); R5 = @(0, 0); R6 = @(0, 0); R7 = @(0, 0)
      }
    
      $map.CACHE = 0
      $map.OUTHASH1 = 0
      $map.PDATA = 0
      $map.MD51 = ((Get-Long $bytesMD5) -bor 1)
      $map.MD52 = ((Get-Long $bytesMD5 4) -bor 1)
      $map.INDEX = Get-ShiftRight ($length - 2) 1
      $map.COUNTER = $map.INDEX + 1

      while ($map.COUNTER) {
        $map.R0 = Convert-Int32 ((Get-Long $bytesBaseInfo $map.PDATA) + ([long]$map.OUTHASH1))
        $map.PDATA = $map.PDATA + 8
        $map.R1[0] = Convert-Int32 ($map.R0 * [long]$map.MD51)
        $map.R1[1] = Convert-Int32 ((0xB1110000L * $map.R1[0]) - (0x30674EEFL * (Get-ShiftRight $map.R1[0] 16)))
        $map.R2[0] = Convert-Int32 ((0x5B9F0000L * $map.R1[1]) - (0x78F7A461L * (Get-ShiftRight $map.R1[1] 16)))
        $map.R2[1] = Convert-Int32 ((0x12CEB96DL * (Get-ShiftRight $map.R2[0] 16)) - (0x46930000L * $map.R2[0]))
        $map.R3 = Convert-Int32 ((0x1D830000L * $map.R2[1]) + (0x257E1D83L * (Get-ShiftRight $map.R2[1] 16)))
        $map.R4[0] = Convert-Int32 ([long]$map.MD52 * ([long]$map.R3 + (Get-Long $bytesBaseInfo ($map.PDATA - 4))))
        $map.R4[1] = Convert-Int32 ((0x16F50000L * $map.R4[0]) - (0x5D8BE90BL * (Get-ShiftRight $map.R4[0] 16)))
        $map.R5[0] = Convert-Int32 ((0x96FF0000L * $map.R4[1]) - (0x2C7C6901L * (Get-ShiftRight $map.R4[1] 16)))
        $map.R5[1] = Convert-Int32 ((0x2B890000L * $map.R5[0]) + (0x7C932B89L * (Get-ShiftRight $map.R5[0] 16)))
        $map.OUTHASH1 = Convert-Int32 ((0x9F690000L * $map.R5[1]) - (0x405B6097L * (Get-ShiftRight ($map.R5[1]) 16)))
        $map.OUTHASH2 = Convert-Int32 ([long]$map.OUTHASH1 + $map.CACHE + $map.R3) 
        $map.CACHE = ([long]$map.OUTHASH2)
        $map.COUNTER = $map.COUNTER - 1
      }
    
      $buffer = [BitConverter]::GetBytes($map.OUTHASH1)
      $buffer.CopyTo($outHash, 8)
      $buffer = [BitConverter]::GetBytes($map.OUTHASH2)
      $buffer.CopyTo($outHash, 12)
    
      [Byte[]] $outHashBase = @(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
      $hashValue1 = ((Get-Long $outHash 8) -bxor (Get-Long $outHash))
      $hashValue2 = ((Get-Long $outHash 12) -bxor (Get-Long $outHash 4))
    
      $buffer = [BitConverter]::GetBytes($hashValue1)
      $buffer.CopyTo($outHashBase, 0)
      $buffer = [BitConverter]::GetBytes($hashValue2)
      $buffer.CopyTo($outHashBase, 4)
      $base64Hash = [Convert]::ToBase64String($outHashBase) 
    }

    Write-Output $base64Hash
  }

function Get-Time {
  $now = [DateTime]::Now
  $dateTime = [DateTime]::New($now.Year, $now.Month, $now.Day, $now.Hour, $now.Minute, 0)
  $fileTime = $dateTime.ToFileTime()
  $hi = ($fileTime -shr 32)
  $low = ($fileTime -band 0xFFFFFFFFL)
  $dateTimeHex = ($hi.ToString("X8") + $low.ToString("X8")).ToLower()

  Write-Output $dateTimeHex
}

function Delete-UserChoiceKey {
  param (
    [Parameter( Position = 0, Mandatory = $True )]
    [String]
    $Key
  )
  $code = @'
  using System;
  using System.Runtime.InteropServices;
  using Microsoft.Win32;
  
  namespace Registry {
    public class Utils {
      [DllImport("advapi32.dll", SetLastError = true)]
      private static extern int RegOpenKeyEx(UIntPtr hKey, string subKey, int ulOptions, int samDesired, out UIntPtr hkResult);
  
      [DllImport("advapi32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
      private static extern uint RegDeleteKey(UIntPtr hKey, string subKey);
  
      public static void DeleteKey(string key) {
        UIntPtr hKey = UIntPtr.Zero;
        RegOpenKeyEx((UIntPtr)0x80000003u, key, 0, 0x20019, out hKey);
        RegDeleteKey((UIntPtr)0x80000003u, key);
      }
     }
   }
'@
  Add-Type -TypeDefinition $code

  [Registry.Utils]::DeleteKey($Key)
}

$Hive = $args[1]

$userExperience = ""
if ($Hive.StartsWith("S-")) 
{
  $userExperienceSearch = "User Choice set via Windows User Experience"
  $user32Path = [Environment]::GetFolderPath([Environment+SpecialFolder]::SystemX86) + "\Shell32.dll"
  $fileStream = [System.IO.File]::Open($user32Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  $binaryReader = New-Object System.IO.BinaryReader($fileStream)
  [Byte[]] $bytesData = $binaryReader.ReadBytes(5mb)
  $fileStream.Close()
  $dataString = [Text.Encoding]::Unicode.GetString($bytesData)
  $position1 = $dataString.IndexOf($userExperienceSearch)
  $position2 = $dataString.IndexOf("}", $position1)

  $userExperience = $dataString.Substring($position1, $position2 - $position1 + 1)
}

Write-Host "Setting file associations for HKEY_USERS\$Hive..."

New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null

If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Clients")) {
New-Item -Path "HKU:\$Hive\SOFTWARE\Clients" -Force | Out-Null
}
If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Clients\StartMenuInternet")) {
New-Item -Path "HKU:\$Hive\SOFTWARE\Clients\StartMenuInternet" -Force | Out-Null
}

Get-Item -Path "HKLM:\SOFTWARE\Clients\StartMenuInternet\*" |
ForEach-Object {
Copy-Item -Path "$($_.PSPath)" -Destination "HKU:\$Hive\SOFTWARE\Clients\StartMenuInternet" -Force -Recurse | Out-Null
}

for ($i = 2; $i -lt $args.Length; $i++) {
  $splitArg = $args[$i] -split ":"
  if ($splitArg[0] -eq "Proto") {
    If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])")) {
    New-Item -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])" -Force | Out-Null
    }
    If (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])\UserChoice") {
    Delete-UserChoiceKey "$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])\UserChoice"
    }
    If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts")) {
    New-Item -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" -Force | Out-Null
    }
    New-ItemProperty -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" -Name "$($splitArg[2])_$($splitArg[1])" -PropertyType DWORD -Value 0 -Force | Out-Null

    $dateTimeHex = Get-Time
    $hash = Get-Hash "$($splitArg[1])$Hive$($splitArg[2])$dateTimeHex$userExperience".ToLower()
    [Microsoft.Win32.Registry]::SetValue("HKEY_USERS\$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])\UserChoice", "Hash", $hash)

    [Microsoft.Win32.Registry]::SetValue("HKEY_USERS\$Hive\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\$($splitArg[1])\UserChoice", "ProgId", "$($splitArg[2])")
  } else {
    If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])")) {
    New-Item -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])" -Force | Out-Null
    } 
    If (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])\UserChoice") {
    Delete-UserChoiceKey "$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])\UserChoice"
    }
    If (-NOT (Test-Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts")) {
    New-Item -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" -Force | Out-Null
    }
    New-ItemProperty -Path "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" -Name "$($splitArg[1])_$($splitArg[0])" -PropertyType DWORD -Value 0 -Force | Out-Null

    if ($Hive.StartsWith("S-")) {
      $dateTimeHex = Get-Time
      $hash = Get-Hash "$($splitArg[0])$Hive$($splitArg[1])$dateTimeHex$userExperience".ToLower()

      [Microsoft.Win32.Registry]::SetValue("HKEY_USERS\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])\UserChoice", "Hash", $hash)
      [Microsoft.Win32.Registry]::SetValue("HKEY_USERS\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($splitArg[0])\UserChoice", "ProgId", "$($splitArg[1])")
    }

    [Microsoft.Win32.Registry]::SetValue("HKEY_CLASSES_ROOT\$($splitArg[0])", "", "$($splitArg[1])")
    [Microsoft.Win32.Registry]::SetValue("HKEY_USERS\$Hive\SOFTWARE\Classes\$($splitArg[0])", "", "$($splitArg[1])")
  }
}