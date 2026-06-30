# Run tasks
function Invoke-RunTaskInternal
{
    param (
        [string]$TaskName,
        [string]$TaskArgs
    )
    & $TaskName $TaskArgs
}
function Invoke-RunTask
{
    param (
        [string]$TaskName,
        [string]$TaskArgs,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-RunTask" -ParentParams $PSBoundParameters
}

function Invoke-CmdTaskInternal
{
    param (
        [string]$Command
    )

    cmd.exe /c "$Command" | Out-String | Write-Output
}
function Invoke-CmdTask
{
    param (
        [string]$Command,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-CmdTask" -ParentParams $PSBoundParameters
}

# File tasks
function Remove-FileInternal
{
    param (
        [string]$Path
    )

    if (Test-Path $Path)
    {
        Remove-Item $Path -Force
    } else
    {
        Write-Output "File not found: $Path"
    }
}
function Invoke-RemoveFile
{
    param (
        [string]$Path,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-RemoveFile" -ParentParams $PSBoundParameters
}

# registry tasks
enum PossibleOptions
{
    None
    Unknown
    String
    ExpandString
    DWord
    MultiString
    QWord
    Binary
}

function SetRegistryInternal
{
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$ValueData,
        [PossibleOptions]$Type = [PossibleOptions]::DWord
    )

    $null = New-Item -Path $KeyPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type $Type -Force
}
function Invoke-SetRegistry
{
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$ValueData,
        [PossibleOptions]$Type = 'DWord',
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-SetRegistry" -ParentParams $PSBoundParameters
}

function GetRegistryInternal
{
    param (
        [string]$KeyPath,
        [string]$ValueName
    )
    if ($ValueName)
    {
        Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue
    } else
    {
        Get-ItemProperty -Path $KeyPath -ErrorAction SilentlyContinue
    }
}
function Invoke-GetRegistry
{
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-GetRegistry" -ParentParams $PSBoundParameters
}

function DeleteRegistryInternal
{
    param (
        [string]$KeyPath,
        [string]$ValueName
    )
    if ($ValueName)
    {
        Remove-ItemProperty -Path $KeyPath -Name $ValueName -Force -ErrorAction SilentlyContinue
    } else
    {
        Remove-ItemProperty -Path $KeyPath -Force -ErrorAction SilentlyContinue
    }
}
function Invoke-DeleteRegistry
{
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-DeleteRegistry" -ParentParams $PSBoundParameters
}

# Scheduled tasks
enum ScheduledTaskOperation
{
    delete
    deleteFolder
    enable
    disable
}

function Set-ScheduledTaskOperationInternal
{
    param (
        [string]$Path,
        [ScheduledTaskOperation]$Operation = "delete"
    )
    switch ($Operation)
    {
        "delete"
        { Remove-ScheduledTask -Path $Path
        }
        "deleteFolder"
        { Remove-ScheduledTaskFolder -Path $Path
        }
        "enable"
        { Enable-ScheduledTask -Path $Path
        }
        "disable"
        { Disable-ScheduledTask -Path $Path
        }
    }
}
function Invoke-ScheduledTaskOperation
{
    param (
        [string]$Path,
        [ScheduledTaskOperation]$Operation = "delete",
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-ScheduledTaskOperation" -ParentParams $PSBoundParameters
}

function Set-NewScheduledTaskInternal
{
    param (
        [string]$Path,
        [string]$TaskName,
        [string]$Command,
        [string]$Arguments = "",
        [string]$Description = ""
    )

    Register-ScheduledTask -Path $Path -TaskName $TaskName -Action (New-ScheduledTaskAction -Execute $Command -Argument $Arguments) -Description $Description
}
function Invoke-NewScheduledTask
{
    param (
        [string]$Path,
        [string]$TaskName,
        [string]$Command,
        [string]$Arguments = "",
        [string]$Description = "",
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-NewScheduledTask" -ParentParams $PSBoundParameters
}

# service tasks
enum ServiceOperation
{
    stop
    continue
    start
    pause
    delete
}
enum ServiceScope
{
    allUsers
    currentUser
    activeUsers
    defaultUsers
}

function Set-NewServiceTaskInternal
{
    param (
        [string]$Name,
        [string]$DisplayName,
        [string]$Path,
        [string]$Arguments = ""
    )

    New-Service -Name $Name -DisplayName $DisplayName -BinaryPathName $Path -StartupType Automatic -ArgumentList $Arguments
}
function Invoke-NewServiceTask
{
    param (
        [string]$Name,
        [string]$DisplayName,
        [string]$Path,
        [string]$Arguments = "",
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-NewServiceTask" -ParentParams $PSBoundParameters
}

function Set-ServiceOperationInternal
{
    param (
        [string]$Name,
        [ServiceOperation]$Operation = "delete",
        [ServiceScope]$Scope = "allUsers"
    )

    switch ($Operation)
    {
        "stop"
        { Stop-Service -Name $Name -Scope $Scope
        }
        "continue"
        { Start-Service -Name $Name -Scope $Scope
        }
        "start"
        { Start-Service -Name $Name -Scope $Scope
        }
        "pause"
        { Suspend-Service -Name $Name -Scope $Scope
        }
        "delete"
        { Remove-Service -Name $Name -Scope $Scope
        }
    }
}
function Invoke-ServiceOperation
{
    param (
        [string]$Name,
        [ServiceOperation]$Operation = "delete",
        [ServiceScope]$Scope = "allUsers",
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )
    Invoke-CommonTaskLogic -TargetFunction "Invoke-ServiceOperation" -ParentParams $PSBoundParameters
}

function Remove-AppxPackageInternal
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Packages,
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePackages = @(),
        [Parameter(Mandatory = $false)]
        [switch]$Unregister = $false
    )

    $baseRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"

    $allPackages = Get-AppxPackage -AllUsers | Select-Object PackageFullName, PackageFamilyName, PackageUserInformation, NonRemovable

    foreach ($package in $Packages)
    {
        $filteredPackages = $allPackages | Where-Object { $_.PackageFullName -like "*$package*" }
        if ($ExcludePackages.Count -gt 0)
        {
            $filteredPackages = $filteredPackages | Where-Object {
                $fullPackageName = $_.PackageFullName
                -not ($ExcludePackages | Where-Object { $fullPackageName -like "*$_*" })
            }
        }

        foreach ($pkg in $filteredPackages)
        {
            $fullPackageName = $pkg.PackageFullName
            $packageFamilyName = $pkg.PackageFamilyName

            Write-Host "Removing package: $($fullPackageName)"

            $deprovisionedPath = "$baseRegistryPath\Deprovisioned\$packageFamilyName"
            if (-not (Test-Path -Path $deprovisionedPath))
            {
                New-Item -Path $deprovisionedPath -Force
            }

            $inboxAppsPath = "$baseRegistryPath\InboxApplications\$fullPackageName"
            if (Test-Path $inboxAppsPath)
            {
                Remove-Item -Path $inboxAppsPath -Force
            }

            if ($pkg.NonRemovable -eq 1)
            {
                Set-NonRemovableAppsPolicy -Online -PackageFamilyName $packageFamilyName -NonRemovable 0
            }

            foreach ($userInfo in $pkg.PackageUserInformation)
            {
                $userSid = $userInfo.UserSecurityID.SID
                $endOfLifePath = "$baseRegistryPath\EndOfLife\$userSid\$fullPackageName"
                New-Item -Path $endOfLifePath -Force

                if ($Unregister)
                {
                    Remove-AppxPackage -Package $fullPackageName -User $userSid -PreserveRoamableApplicationData
                } else
                {
                    Remove-AppxPackage -Package $fullPackageName -User $userSid
                }
            }

            if ($Unregister)
            {
                Remove-AppxPackage -Package $fullPackageName -AllUsers -PreserveRoamableApplicationData
            } else
            {
                Remove-AppxPackage -Package $fullPackageName -AllUsers
            }
        }
    }
}
function Invoke-RemoveAppxPackage
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Packages,
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePackages = @(),
        [Parameter(Mandatory = $false)]
        [switch]$Unregister = $false,
        [string]$BuildScope,
        [bool]$IsUpdate,
        [string[]]$AtlasVersion
    )

    Invoke-CommonTaskLogic -TargetFunction "Invoke-RemoveAppxPackage" -ParentParams $PSBoundParameters
}

# Common task logic section
function Invoke-CheckBuildScope
{
    param (
        [string]$BuildScope
    )

    if ($BuildScope -match '^(?<operator>>=|<=|>|<)(?<targetBuild>\d+)$')
    {
        $currentBuild = [System.Environment]::OSVersion.Version.Build
        $targetBuild  = [int]$Matches['targetBuild']
        $opMap = @{
            '>'   = '-gt'
            '<'  = '-lt'
            '>=' = '-ge'
            '<=' = '-le'
        }
        $psOperator = $opMap[$Matches['operator']]
        return Invoke-Expression "$currentBuild $psOperator $targetBuild"
    }

    return $false
}
function Invoke-IsUpdateCheck
{
    $isUpdate = Get-ItemProperty -Path 'HKLM:\SOFTWARE\AtlasOS' -Name 'IsUpdate' -ErrorAction SilentlyContinue
    return $null -ne $isUpdate
}
function Invoke-CheckAtlasVersionScope
{
    param (
        [string[]]$AtlasVersionList
    )

    $appliedPlaybooks = Get-ItemProperty -Path 'HKLM:\SOFTWARE\AME\Playbooks\Applied' -ErrorAction SilentlyContinue
    if ($null -ne $appliedPlaybooks)
    {
        foreach ($key in $appliedPlaybooks.PSObject.Properties)
        {
            if ($key.Name -eq 'AtlasOS')
            {
                if ($AtlasVersionList -contains $key.Value)
                {
                    return $true
                }
                return $false
            }
        }
    }
    return $false
}

function Invoke-CommonTaskLogic
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetFunction,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ParentParams
    )

    # 1. Evaluate Build Scope if passed
    if ($ParentParams.ContainsKey('BuildScope'))
    {
        if (-not (Invoke-CheckBuildScope $ParentParams['BuildScope']))
        {
            return $false
        }
    }

    # 2. Evaluate Update logic if flag is active
    if ($ParentParams['IsUpdate'])
    {
        if (-not (Invoke-IsUpdateCheck))
        {
            return $false
        }

        if ($ParentParams.ContainsKey('AtlasVersion'))
        {
            if (-not (Invoke-CheckAtlasVersionScope -AtlasVersionList $ParentParams['AtlasVersion']))
            {
                return $false
            }
        }
    }

    # 3. Safe Explicit Variable Routing
    switch ($TargetFunction)
    {
        'Invoke-RunTask'
        {
            Invoke-RunTaskInternal -TaskName $ParentParams['TaskName'] -TaskArgs $ParentParams['TaskArgs']
        }
        'Invoke-CmdTask'
        {
            Invoke-CmdTaskInternal -Command $ParentParams['Command']
        }
        'Invoke-RemoveFile'
        {
            Remove-FileInternal -Path $ParentParams['Path']
        }
        'Invoke-SetRegistry'
        {
            $RegistryArgs = @{
                KeyPath   = $ParentParams['KeyPath']
                ValueName = $ParentParams['ValueName']
                ValueData = if ($ParentParams.ContainsKey('ValueData'))
                { $ParentParams['ValueData']
                } else
                { ""
                }
            }
            if ($ParentParams.ContainsKey('Type'))
            { $RegistryArgs['Type'] = $ParentParams['Type']
            }

            SetRegistryInternal @RegistryArgs
        }
        'Invoke-GetRegistry'
        {
            GetRegistryInternal -KeyPath $ParentParams['KeyPath'] -ValueName $ParentParams['ValueName']
        }
        'Invoke-DeleteRegistry'
        {
            DeleteRegistryInternal -KeyPath $ParentParams['KeyPath'] -ValueName $ParentParams['ValueName']
        }
        'Invoke-ScheduledTaskOperation'
        {
            $SchedOpArgs = @{ Path = $ParentParams['Path'] }
            if ($ParentParams.ContainsKey('Operation'))
            { $SchedOpArgs['Operation'] = $ParentParams['Operation']
            }

            Set-ScheduledTaskOperationInternal @SchedOpArgs
        }
        'Invoke-NewScheduledTask'
        {
            $NewSchedArgs = @{
                Path     = $ParentParams['Path']
                TaskName = $ParentParams['TaskName']
                Command  = $ParentParams['Command']
            }
            if ($ParentParams.ContainsKey('Arguments'))
            { $NewSchedArgs['Arguments']   = $ParentParams['Arguments']
            }
            if ($ParentParams.ContainsKey('Description'))
            { $NewSchedArgs['Description'] = $ParentParams['Description']
            }

            Set-NewScheduledTaskInternal @NewSchedArgs
        }
        'Invoke-ServiceOperation'
        {
            $ServOpArgs = @{ Name = $ParentParams['Name'] }
            if ($ParentParams.ContainsKey('Operation'))
            { $ServOpArgs['Operation'] = $ParentParams['Operation']
            }
            if ($ParentParams.ContainsKey('Scope'))
            { $ServOpArgs['Scope']     = $ParentParams['Scope']
            }

            Set-ServiceOperationInternal @ServOpArgs
        }
        'Invoke-NewServiceTask'
        {
            $NewServArgs = @{
                Name        = $ParentParams['Name']
                DisplayName = $ParentParams['DisplayName']
                Path        = $ParentParams['Path']
            }
            if ($ParentParams.ContainsKey('Arguments'))
            { $NewServArgs['Arguments'] = $ParentParams['Arguments']
            }

            Set-NewServiceTaskInternal @NewServArgs
        }
        'Invoke-RemoveAppxPackage'
        {
            Remove-AppxPackageInternal -Packages $ParentParams['Packages'] -ExcludePackages $ParentParams['ExcludePackages'] -Unregister $ParentParams['Unregister']
        }
        Default
        {
            Write-Error "Unknown target function: $TargetFunction"
            return $false
        }
    }
}

Export-ModuleMember -function @(
    'Invoke-RunTask'
    'Invoke-CmdTask'
    'Invoke-RemoveFile'
    'Invoke-SetRegistry'
    'Invoke-GetRegistry'
    'Invoke-DeleteRegistry'
    'Invoke-ScheduledTaskOperation'
    'Invoke-NewScheduledTask'
    'Invoke-NewServiceTask'
    'Invoke-ServiceOperation'
    'Invoke-RemoveAppxPackage'
)
