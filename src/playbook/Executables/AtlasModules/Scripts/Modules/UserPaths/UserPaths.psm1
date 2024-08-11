function Get-UserPath {
    param (
        # https://learn.microsoft.com/windows/win32/shell/knownfolderid
        [string]$FolderID = 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641',
        # Default user
        # 0 is the current user
        [System.IntPtr]$Token = -1,
        # Create folder if it doesn't exist
        [int]$Flags = 0x00008000
    )

    $guid = [guid]::new($FolderID)
    if ($null -eq $guid) {
        throw "Failed to convert provided FolderID!"
    }

    # https://learn.microsoft.com/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class KnownFolder
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SHGetKnownFolderPath(
        [MarshalAs(UnmanagedType.LPStruct)] Guid rfid,
        uint dwFlags,
        IntPtr hToken,
        out IntPtr pszPath
    );
}
"@

    $pszPath = [IntPtr]::Zero
    $result = [KnownFolder]::SHGetKnownFolderPath($guid, $Flags, $Token, [ref]$pszPath)

    if ($result -eq 0 -and $pszPath -ne [IntPtr]::Zero) {
        $desktopPath = [Runtime.InteropServices.Marshal]::PtrToStringUni($pszPath)
        [Runtime.InteropServices.Marshal]::FreeCoTaskMem($pszPath)
        return $desktopPath
    } else {
        throw "Failed to retrieve $guid. Error code: $result"
    }
}

function Get-Accounts {
    $accounts = Get-CimInstance Win32_UserAccount -Filter "Disabled=False"
    $userProfiles = Get-CimInstance Win32_UserProfile

    $profileLookup = @{}
    foreach ($profile in $userProfiles) {
        $profileLookup[$profile.SID] = $profile.LocalPath
    }

    $data = $accounts | ForEach-Object {
        $account = $_
        $profilePath = $profileLookup[$account.SID]

        [PSCustomObject]@{
            Name    = $account.Name
            Caption = $account.Caption
            Path    = $profilePath
            SID     = $account.SID
        }
    }

    return $data
}

Export-ModuleMember -Function Get-UserPath, Get-Accounts