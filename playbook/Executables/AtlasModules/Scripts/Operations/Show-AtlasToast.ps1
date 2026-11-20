<#
.SYNOPSIS
    Shows a native toast from the sender "Atlas".
.DESCRIPTION
    Windows attributes a toast from an unpackaged script only to a registered
    AppUserModelId, so the first run registers a minimal one under HKCU.

    Atlas scripts run this with the call operator in the signed-in user's own process:
    first sign-in setup and Open Terminal Here. It reports a failure as an error, not
    as an exit code.
.PARAMETER Title
    The first line of the toast.
.PARAMETER Message
    The second line of the toast.
.PARAMETER Persistent
    Keeps the toast on screen until the user dismisses it, for a notice the user may
    only see when they come back to the PC, such as the end of an install.
#>
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$Message,
    [switch]$Persistent
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
# ask the user for the first time this AppId sends a toast. Windows writes the same value
# itself once someone clicks "Yes" on that prompt.
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

# scenario="urgent" is the documented way to break through Focus Assist/Do Not Disturb,
# reserved for one-off, non-repeating notices like this rather than routine notifications.
# scenario="reminder" keeps the toast on screen until it is dismissed; it needs an action,
# and the system "dismiss" one closes it without launching anything.
$scenario = if ($Persistent) { 'reminder' } else { 'urgent' }
$actionsNode = if ($Persistent) {
    '<actions><action content="OK" arguments="dismiss" activationType="system"/></actions>'
}
else { '' }
$toastXml = @"
<toast scenario="$scenario">
    <visual>
        <binding template="ToastGeneric">
            $logoNode
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
    $actionsNode
</toast>
"@

$xmlDoc = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$xmlDoc.LoadXml($toastXml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
