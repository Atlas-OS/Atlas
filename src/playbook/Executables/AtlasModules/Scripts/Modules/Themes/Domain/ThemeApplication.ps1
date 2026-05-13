function Stop-ThemeProcesses {
    Get-Process 'SystemSettings', 'control' -EA 0 | Stop-Process -Force -EA 0
}

function Set-Theme {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $themeItem = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if (($null -eq $themeItem) -or ($themeItem.Extension -ne '.theme')) {
        throw "'$Path' is not a valid path to a theme file."
    }

    function Set-ThemeUsingExplorer {
        Write-Warning "Failed to apply theme using COM, falling back to launching file..."

        Stop-ThemeProcesses
        Start-Process -FilePath explorer -ArgumentList $Path
        Start-Sleep 10
    }

    Add-Type @'
using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

public static class ThemeManagerAPI
{
    public static void ApplyTheme(string themeFilePath)
    {
        IThemeManager themeManager = new ThemeManagerClass();
        themeManager.ApplyTheme(themeFilePath);
    }

    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("D23CC733-5522-406D-8DFB-B3CF5EF52A71")]
    [ComImport]
    public interface ITheme
    {
    }

    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("0646EBBE-C1B7-4045-8FD0-FFD65D3FC792")]
    [ComImport]
    public interface IThemeManager
    {
        [DispId(1610678272)]
        ITheme CurrentTheme { get; }

        [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
        void ApplyTheme([MarshalAs(UnmanagedType.BStr)] string themeFilePath);
    }

    [TypeLibType(TypeLibTypeFlags.FCanCreate)]
    [Guid("C04B329E-5823-4415-9C93-BA44688947B0")]
    [ClassInterface(ClassInterfaceType.None)]
    [ComImport]
    public class ThemeManagerClass : IThemeManager
    {
        [DispId(1610678272)]
        public virtual extern ITheme CurrentTheme { [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)] get; }

        [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
        public virtual extern void ApplyTheme([MarshalAs(UnmanagedType.BStr)] string themeFilePath);
    }
}
'@

    try {
        [ThemeManagerAPI]::ApplyTheme($Path)
    } catch {
        Set-ThemeUsingExplorer
    }

    Stop-ThemeProcesses
}
