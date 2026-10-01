# Atlas.Registry domain: known-folder helper. Keep the unprefixed name:
# Operations\New-AtlasShortcutSet.ps1 auto-loads it by that name.

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
    Initialize-AtlasNativeType

    $pszPath = [IntPtr]::Zero
    $result = [Atlas.Native.KnownFolder]::SHGetKnownFolderPath($guid, $Flags, $Token, [ref]$pszPath)

    if ($result -eq 0 -and $pszPath -ne [IntPtr]::Zero) {
        $folderPath = [Runtime.InteropServices.Marshal]::PtrToStringUni($pszPath)
        [Runtime.InteropServices.Marshal]::FreeCoTaskMem($pszPath)
        return $folderPath
    }
    else {
        throw "Failed to retrieve $guid. Error code: $result"
    }
}
