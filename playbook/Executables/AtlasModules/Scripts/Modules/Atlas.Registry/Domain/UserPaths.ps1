# Atlas.Registry domain: known-folder helper.
# The unprefixed function name is an internal contract for the scripts that resolve
# it through PSModulePath auto-loading - do not rename it.

function Get-UserPath {
    <#
    .SYNOPSIS
        Resolves a known folder (default: the desktop) for the default or current user
        via SHGetKnownFolderPath.
    #>
    param(
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
        throw 'Failed to convert provided FolderID!'
    }

    if (-not ('KnownFolder' -as [type])) {
        # https://learn.microsoft.com/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
        Add-Type @'
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
'@
    }

    $pszPath = [IntPtr]::Zero
    $result = [KnownFolder]::SHGetKnownFolderPath($guid, $Flags, $Token, [ref]$pszPath)

    if ($result -eq 0 -and $pszPath -ne [IntPtr]::Zero) {
        $folderPath = [Runtime.InteropServices.Marshal]::PtrToStringUni($pszPath)
        [Runtime.InteropServices.Marshal]::FreeCoTaskMem($pszPath)
        return $folderPath
    }
    else {
        throw "Failed to retrieve $guid. Error code: $result"
    }
}
