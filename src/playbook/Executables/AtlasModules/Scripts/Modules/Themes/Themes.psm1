$windir = [Environment]::GetFolderPath('Windows')

function Stop-ThemeProcesses {
    Get-Process 'SystemSettings', 'control' -EA 0 | Stop-Process -Force
}

function Set-Theme {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (!((Get-Item $Path -EA 0).Extension -eq '.theme')) {
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

function Set-ThemeMRU {
    if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
        Stop-ThemeProcesses
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" -Name "ThemeMRU" -Value "$((@(
            "atlas-v0.4.x-dark.theme",
            "atlas-v0.4.x-light.theme",
            "atlas-v0.3.x-dark.theme",
            "atlas-v0.3.x-light.theme",
            "dark.theme",
            "aero.theme"
        ) | ForEach-Object { "$windir\resources\Themes\$_" }) -join ';');" -Type String -Force
    }
}

# Credit: https://superuser.com/a/1343640
function Set-LockscreenImage {
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Path = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Wallpapers\lockscreen.png"
    )

    if (!(Test-Path $Path)) {
        throw "Path ('$Path') for lockscreen not found."
    }
    $newImagePath = [System.IO.Path]::GetTempPath() + (New-Guid).Guid + [System.IO.Path]::GetExtension($Path)
    Copy-Item $Path $newImagePath

    # setup WinRT namespaces
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null

    # setup async
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? {
        $_.Name -eq 'AsTask' -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    Function Await($WinRtTask, $ResultType) {
        $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
        $netTask = $asTask.Invoke($null, @($WinRtTask))
        $netTask.Wait(-1) | Out-Null
        $netTask.Result
    }
    Function AwaitAction($WinRtAction) {
        $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
        $netTask = $asTask.Invoke($null, @($WinRtAction))
        $netTask.Wait(-1) | Out-Null
    }

    # make image object
    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
    $image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($newImagePath)) ([Windows.Storage.StorageFile])
    
    # execute
    AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))
    
    # cleanup
    Remove-Item $newImagePath
}

Export-ModuleMember -Function Set-Theme, Set-ThemeMRU, Set-LockscreenImage