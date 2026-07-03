# Atlas.TasksProcs domain: scheduled tasks.
#
# schtasks.exe is used instead of the ScheduledTasks CIM cmdlets because it behaves
# consistently under TrustedInstaller and against protected Microsoft tasks. Exit code
# 1 means the task does not exist, which is expected on many Windows editions/builds
# and therefore only logged as a warning (or silenced with -IgnoreMissing).

function Invoke-AtlasScheduledTaskCommand {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OperationLabel,

        [switch]$IgnoreMissing
    )

    $output = & schtasks.exe @Arguments 2>&1
    if ($LASTEXITCODE -eq 1) {
        if (-not $IgnoreMissing) {
            Write-AtlasLog -Level Warning -Message "Scheduled task '$Path' was not found; nothing to $OperationLabel."
        }
    }
    elseif ($LASTEXITCODE -ne 0) {
        $details = (@($output) | ForEach-Object { "$_" }) -join ' '
        Write-AtlasLog -Level Warning -Message "Couldn't $OperationLabel scheduled task '$Path' (schtasks.exe exited with code $LASTEXITCODE): $details"
    }
}

function Disable-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Disables a scheduled task by path (e.g. '\Microsoft\Windows\Defrag\ScheduledDefrag').
        A missing task logs a warning unless -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'disable' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Change', '/TN', $Path, '/DISABLE')
}

function Enable-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Enables a scheduled task by path. A missing task logs a warning unless
        -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'enable' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Change', '/TN', $Path, '/ENABLE')
}

function Remove-AtlasScheduledTask {
    <#
    .SYNOPSIS
        Deletes a scheduled task by path. A missing task logs a warning unless
        -IgnoreMissing is passed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$IgnoreMissing
    )

    Invoke-AtlasScheduledTaskCommand -Path $Path -OperationLabel 'delete' -IgnoreMissing:$IgnoreMissing `
        -Arguments @('/Delete', '/TN', $Path, '/F')
}
