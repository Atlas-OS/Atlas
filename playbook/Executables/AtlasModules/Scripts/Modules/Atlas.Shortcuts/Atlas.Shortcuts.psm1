function Set-AtlasShortcutAppUserModelId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$AppUserModelId
    )

    if (-not ('Atlas.Shortcuts.Native.ShortcutPropertyStore' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Atlas.Shortcuts.Native
{
    [ComImport]
    [Guid("00021401-0000-0000-C000-000000000046")]
    internal class ShellLink
    {
    }

    [ComImport]
    [Guid("0000010B-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPersistFile
    {
        void GetClassID(out Guid classId);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string fileName, uint mode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string fileName, [MarshalAs(UnmanagedType.Bool)] bool remember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string fileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string fileName);
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    internal struct PropertyKey
    {
        internal Guid FormatId;
        internal uint PropertyId;
    }

    [StructLayout(LayoutKind.Explicit)]
    internal struct PropVariant
    {
        [FieldOffset(0)] internal ushort VariantType;
        [FieldOffset(8)] internal IntPtr PointerValue;
    }

    [ComImport]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPropertyStore
    {
        uint GetCount();
        void GetAt(uint propertyIndex, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant value);
        void SetValue(ref PropertyKey key, ref PropVariant value);
        void Commit();
    }

    public static class ShortcutPropertyStore
    {
        [DllImport("ole32.dll")]
        private static extern int PropVariantClear(ref PropVariant value);

        public static void SetAppUserModelId(string path, string appUserModelId)
        {
            object link = new ShellLink();
            PropVariant value = new PropVariant();
            try
            {
                IPersistFile file = (IPersistFile)link;
                file.Load(path, 2); // STGM_READWRITE

                PropertyKey key = new PropertyKey
                {
                    FormatId = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
                    PropertyId = 5
                };
                value.VariantType = 31; // VT_LPWSTR
                value.PointerValue = Marshal.StringToCoTaskMemUni(appUserModelId);

                IPropertyStore store = (IPropertyStore)link;
                store.SetValue(ref key, ref value);
                store.Commit();
                file.Save(path, true);
            }
            finally
            {
                PropVariantClear(ref value);
                if (link != null && Marshal.IsComObject(link))
                {
                    Marshal.FinalReleaseComObject(link);
                }
            }
        }
    }
}
'@
    }

    [Atlas.Shortcuts.Native.ShortcutPropertyStore]::SetAppUserModelId(
        $Path,
        $AppUserModelId
    )
}

function Resolve-AtlasShortcutPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$PathType = 'Any',

        [switch]$AllowMissing
    )

    $isDrivePath = $Path -match '\A[A-Za-z]:[\\/]'
    $isUncPath = $Path -match '\A\\\\[^\\]+\\[^\\]+'
    if (-not $isDrivePath -and -not $isUncPath) {
        throw "$Description must be a fully qualified path: '$Path'."
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "$Description is not a valid path: '$Path'. $($_.Exception.Message)"
    }

    if ($AllowMissing) {
        return $fullPath
    }

    $exists = switch ($PathType) {
        'File' { [System.IO.File]::Exists($fullPath) }
        'Directory' { [System.IO.Directory]::Exists($fullPath) }
        default {
            [System.IO.File]::Exists($fullPath) -or
                [System.IO.Directory]::Exists($fullPath)
        }
    }
    if (-not $exists) {
        throw "$Description was not found: '$fullPath'."
    }

    return $fullPath
}

function New-AtlasShortcut {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [ValidateNotNullOrEmpty()]
        [string]$WorkingDir,

        [AllowEmptyString()]
        [string]$Arguments = '',

        [ValidateNotNullOrEmpty()]
        [string]$Icon,

        [ValidateLength(1, 128)]
        [ValidatePattern('^\S+$')]
        [string]$AppUserModelId,

        [switch]$IfExist
    )

    $sourcePath = Resolve-AtlasShortcutPath -Path $Source -Description 'Shortcut source'
    $destinationPath = Resolve-AtlasShortcutPath `
        -Path $Destination `
        -Description 'Shortcut destination' `
        -AllowMissing

    if (-not [string]::Equals(
            [System.IO.Path]::GetExtension($destinationPath),
            '.lnk',
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Shortcut destination must use the '.lnk' extension: '$destinationPath'."
    }

    if ($IfExist -and -not [System.IO.File]::Exists($destinationPath)) {
        return
    }

    $destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
    [void](Resolve-AtlasShortcutPath `
            -Path $destinationDirectory `
            -Description 'Shortcut destination directory' `
            -PathType Directory)

    if ([string]::IsNullOrWhiteSpace($WorkingDir)) {
        $WorkingDir = [System.IO.Path]::GetDirectoryName($sourcePath)
    }
    $workingDirectoryPath = Resolve-AtlasShortcutPath `
        -Path $WorkingDir `
        -Description 'Shortcut working directory' `
        -PathType Directory

    if (-not $PSCmdlet.ShouldProcess($destinationPath, "Create shortcut to '$sourcePath'")) {
        return
    }

    $shell = $null
    $shortcut = $null
    try {
        $shell = New-Object -ComObject WScript.Shell -ErrorAction Stop
        $shortcut = $shell.CreateShortcut($destinationPath)
        $shortcut.TargetPath = $sourcePath
        $shortcut.WorkingDirectory = $workingDirectoryPath
        $shortcut.Arguments = $Arguments
        if (-not [string]::IsNullOrWhiteSpace($Icon)) {
            $shortcut.IconLocation = $Icon
        }
        $shortcut.Save()

    }
    finally {
        if ($null -ne $shortcut -and
            [System.Runtime.InteropServices.Marshal]::IsComObject($shortcut)) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)
        }
        if ($null -ne $shell -and
            [System.Runtime.InteropServices.Marshal]::IsComObject($shell)) {
            [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }

    # WScript.Shell keeps the link open until its COM objects are released.
    # Reopen it through IShellLink only after that lifecycle is complete.
    if (-not [string]::IsNullOrWhiteSpace($AppUserModelId)) {
        Set-AtlasShortcutAppUserModelId -Path $destinationPath `
            -AppUserModelId $AppUserModelId
    }

    if (-not [System.IO.File]::Exists($destinationPath)) {
        throw "WScript.Shell did not create the shortcut '$destinationPath'."
    }
}

Export-ModuleMember -Function New-AtlasShortcut
