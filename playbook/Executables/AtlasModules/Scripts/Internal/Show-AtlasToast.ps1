# Shows a native Action Center toast under an "Atlas" sender name. Registers a minimal
# AppUserModelId under HKCU the first time it runs - the same technique BurntToast uses
# for unpackaged scripts - since Windows won't attribute a toast to "Atlas" without one.
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$Message
)

$appId = 'AtlasOS.SetupNotification'
$appRegPath = "HKCU:\SOFTWARE\Classes\AppUserModelId\$appId"
if (-not (Test-Path -LiteralPath $appRegPath)) {
    $null = New-Item -Path $appRegPath -Force
}
Set-ItemProperty -Path $appRegPath -Name 'DisplayName' -Value 'Atlas' -Type String -Force

$iconPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\atlas-folder.ico'
$hasIcon = Test-Path -LiteralPath $iconPath -PathType Leaf
if ($hasIcon) {
    Set-ItemProperty -Path $appRegPath -Name 'IconUri' -Value $iconPath -Type ExpandString -Force
}

# Pre-grant the urgent-scenario (Focus Assist bypass) permission Windows would otherwise
# ask the user for the first time this AppId sends a toast - same value it writes itself
# once someone clicks "Yes" on that prompt.
$notifSettingsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$appId"
if (-not (Test-Path -LiteralPath $notifSettingsPath)) {
    $null = New-Item -Path $notifSettingsPath -Force
}
Set-ItemProperty -Path $notifSettingsPath -Name 'AllowUrgentNotifications' -Value 1 -Type DWord -Force

[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
[void][Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
[void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

$logoNode = if ($hasIcon) { "<image placement=`"appLogoOverride`" hint-crop=`"none`" src=`"$iconPath`"/>" } else { '' }
$escapedTitle = [System.Security.SecurityElement]::Escape($Title)
$escapedMessage = [System.Security.SecurityElement]::Escape($Message)

# scenario="urgent" is the documented way to break through Focus Assist/Do Not Disturb -
# reserved for one-off, non-repeating notices like this rather than routine notifications.
$toastXml = @"
<toast scenario="urgent">
    <visual>
        <binding template="ToastGeneric">
            $logoNode
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
</toast>
"@

$xmlDoc = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$xmlDoc.LoadXml($toastXml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
