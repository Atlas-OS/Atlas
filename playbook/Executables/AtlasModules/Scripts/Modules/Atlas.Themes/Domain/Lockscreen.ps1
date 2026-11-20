# Atlas.Themes domain: the lock screen image. Runs as the signed-in user, from the
# per-user setup at first sign-in, because the WinRT LockScreen API sets the image
# for the calling user.

function Set-AtlasLockscreenImage {
    <#
    .SYNOPSIS
        Sets the current user's lock screen image through the WinRT LockScreen API.
    .DESCRIPTION
        Hands the API a temporary copy of the image and removes the copy afterwards.
    .PARAMETER Path
        The image file; by default the Atlas dark lock screen image under AtlasModules.
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Path = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Wallpapers\lockscreen_dark.png"
    )

    if (!(Test-Path $Path)) {
        throw "Path ('$Path') for lockscreen not found."
    }
    $newImagePath = [System.IO.Path]::GetTempPath() + (New-Guid).Guid + [System.IO.Path]::GetExtension($Path)
    Copy-Item $Path $newImagePath

    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null

    # WinRT async operations, awaited through .NET tasks.
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
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
        $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
        $netTask = $asTask.Invoke($null, @($WinRtAction))
        $netTask.Wait(-1) | Out-Null
    }

    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
    $image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($newImagePath)) ([Windows.Storage.StorageFile])

    AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))

    Remove-Item $newImagePath
}
