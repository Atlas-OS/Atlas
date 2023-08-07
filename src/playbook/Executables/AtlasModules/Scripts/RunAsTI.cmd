<# : batch portion
@echo off
setlocal EnableDelayedExpansion

:: Detect whether the script is run with cmd or the external script
if not defined run_by (
	set "cmdcmdline=!cmdcmdline:"=!"
	set "cmdcmdline=!cmdcmdline:~0,-1!"
	if /i "!cmdcmdline!" == "C:\Windows\System32\cmd.exe" (
		set "run_by=cmd"
	) else (
		set "run_by=external"
	)
)

goto RunAsTI-Elevate

----------------------------------------
[CREDITS]
- Adapted from https://github.com/AveYo/LeanAndMean
- Revised and customized for Atlas by he3als & Xyueta
- Added error checking, an interface and quotes support

[FEATURES]
- Innovative HKCU load, no need for 'reg load' or unload ping-pong; programs get the user profile
- Sets ownership privileges, high priority, and Explorer support; get System if TrustedInstaller is unavailable
- Accepts special characters in paths for which default 'Run as Administrator' fails

[USAGE]
- call RunAsTI.cmd "[executable]" [args (optional)]
- Put this at the top of your script:

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)
----------------------------------------

:RunAsTI-Elevate
if "%~1" == "" (
	set /P program_path="Enter the valid path of the program or drag it here: "
	if "!program_path!" == "" echo error: failed && timeout /t 3 > nul & if "!run_by!" == "cmd" (pause & exit) else (exit /b 1)
	if exist "!program_path!\*" echo error: !program_path! is a folder & if "!run_by!" == "cmd" (pause & exit) else (exit /b 1)

	if exist !program_path! (
		call :RunAsTI !program_path!
		if "!run_by!" == "cmd" (exit) else (exit /b)
	) else (
		where !program_path! > nul 2>&1
		if !errorlevel! == 0 (
			call :RunAsTI !program_path!
			if "!run_by!" == "cmd" (exit) else (exit /b)
		)
	)
	echo error: failed
	if "!run_by!" == "cmd" (pause & exit) else (exit /b 1)
)

call :RunAsTI %*
exit /b

:RunAsTI-Declined
echo]
echo Self-elevation to TrustedInstaller failed, because the UAC prompt was declined.
echo Selecting 'Yes' to the UAC prompt is required for this script.
echo]
echo Press any key to attempt to elevate again...
pause > nul
goto RunAsTI-Elevate

:RunAsTI-Fail
echo]
echo Executing the script as TrustedInstaller failed with the RunAsTI snippet.
echo An unknown error has occured, please report this (with the error) or attempt to elevate again!
echo]
echo Press any key to attempt to elevate again...
pause > nul
goto RunAsTI-Elevate

:RunAsTI
set "0=%~f0"
set "1=%*"
powershell -nop -c iex(gc """$env:0""" -Raw)
set RunAsTI_Errorlevel=%errorlevel%
if %RunAsTI_Errorlevel%==1 (
	goto RunAsTI-Fail
) else (
	if %RunAsTI_Errorlevel%==2 (
		goto RunAsTI-Declined
	) else (
		exit /b
	)
)
: end batch / begin powershell #>

function RunAsTI ($cmd,$arg) { $id='RunAsTI'; $key="Registry::HKU\$(((whoami /user)-split' ')[-1])\Volatile Environment"; $code=@'
 $I=[int32]; $M=$I.module.gettype("System.Runtime.Interop`Services.Mar`shal"); $P=$I.module.gettype("System.Int`Ptr"); $S=[string]
 $D=@(); $T=@(); $DM=[AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1); $Z=[uintptr]::size
 0..5|% {$D += $DM."Defin`eType"("AveYo_$_",1179913,[ValueType])}; $D += [uintptr]; 4..6|% {$D += $D[$_]."MakeByR`efType"()}
 $F='kernel','advapi','advapi', ($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), ([uintptr],$S,$I,$I,$D[9]),([uintptr],$S,$I,$I,[byte[]],$I)
 0..2|% {$9=$D[0]."DefinePInvok`eMethod"(('CreateProcess','RegOpenKeyEx','RegSetValueEx')[$_],$F[$_]+'32',8214,1,$S,$F[$_+3],1,4)}
 $DF=($P,$I,$P),($I,$I,$I,$I,$P,$D[1]),($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P),($D[3],$P),($P,$P,$I,$I)
 1..5|% {$k=$_; $n=1; $DF[$_-1]|% {$9=$D[$k]."Defin`eField"('f' + $n++, $_, 6)}}; 0..5|% {$T += $D[$_]."Creat`eType"()}
 0..5|% {nv "A$_" ([Activator]::CreateInstance($T[$_])) -fo}; function F ($1,$2) {$T[0]."G`etMethod"($1).invoke(0,$2)}
 $TI=(whoami /groups)-like'*1-16-16384*'; $As=0; if(!$cmd) {$cmd='control';$arg='admintools'}; if ($cmd-eq'This PC'){$cmd='file:'}
 if (!$TI) {'TrustedInstaller','lsass','winlogon'|% {if (!$As) {$9=sc.exe start $_; $As=@(get-process -name $_ -ea 0|% {$_})[0]}}
 function M ($1,$2,$3) {$M."G`etMethod"($1,[type[]]$2).invoke(0,$3)}; $H=@(); $Z,(4*$Z+16)|% {$H += M "AllocHG`lobal" $I $_}
 M "WriteInt`Ptr" ($P,$P) ($H[0],$As.Handle); $A1.f1=131072; $A1.f2=$Z; $A1.f3=$H[0]; $A2.f1=1; $A2.f2=1; $A2.f3=1; $A2.f4=1
 $A2.f6=$A1; $A3.f1=10*$Z+32; $A4.f1=$A3; $A4.f2=$H[1]; M "StructureTo`Ptr" ($D[2],$P,[boolean]) (($A2 -as $D[2]),$A4.f2,$false)
 $Run=@($null, "powershell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
 F 'CreateProcess' $Run; return}; $env:R=''; rp $key $id -force; $priv=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {$priv.Invoke($null, @("$_",2))}
 $HKU=[uintptr][uint32]2147483651; $NT='S-1-5-18'; $reg=($HKU,$NT,8,2,($HKU -as $D[9])); F 'RegOpenKeyEx' $reg; $LNK=$reg[4]
 function L ($1,$2,$3) {sp 'HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $3 -force -ea 0
  $b=[Text.Encoding]::Unicode.GetBytes("\Registry\User\$1"); F 'RegSetValueEx' @($2,'SymbolicLinkValue',0,6,[byte[]]$b,$b.Length)}
 function Q {[int](gwmi win32_process -filter 'name="explorer.exe"'|?{$_.getownersid().sid-eq$NT}|select -last 1).ProcessId}
 $11bug=($((gwmi Win32_OperatingSystem).BuildNumber)-eq'22000')-AND(($cmd-eq'file:')-OR(test-path -lit $cmd -PathType Container))
 if ($11bug) {'System.Windows.Forms','Microsoft.VisualBasic' |% {[Reflection.Assembly]::LoadWithPartialName("'$_")}}
 if ($11bug) {$path='^(l)'+$($cmd -replace '([\+\^\%\~\(\)\[\]])','{$1}')+'{ENTER}'; $cmd='control.exe'; $arg='admintools'}
 L ($key-split'\\')[1] $LNK ''; $R=[diagnostics.process]::start($cmd,$arg); if ($R) {$R.PriorityClass='High'; $R.WaitForExit()}
 if ($11bug) {$w=0; do {if($w-gt40){break}; sleep -mi 250;$w++} until (Q); [Microsoft.VisualBasic.Interaction]::AppActivate($(Q))}
 if ($11bug) {[Windows.Forms.SendKeys]::SendWait($path)}; do {sleep 7} while(Q); L '.Default' $LNK 'Interactive User'
'@; $V='';'cmd','arg','id','key'|%{$V+="`n`$$_='$($(gv $_ -val)-replace"'","''")';"}; sp $key $id $($V,$code) -type 7 -force -ea 0
 start powershell -args "-win 1 -nop -c `n$V `$env:R=(gi `$key -ea 0).getvalue(`$id)-join''; iex `$env:R" -verb runas
} #:RunAsTI lean & mean snippet by AveYo, 2023.07.06

Try {
	$initArgs = $env:1
	$split = ($initArgs -split ' ')[0]

	if ($split -like '*"*') {
		$exe = ''; $quoteCount = 0
		foreach ($char in $initArgs.ToCharArray()) {
			$exe += $char
			if ($char -eq '"') {
				$quoteCount++
				if ($quoteCount -eq 2) {break}
			}
		}
	} else {
		$exe = $split
	}

	$arguments = ($initArgs.Remove(0, $exe.Length)).Trim()

	RunAsTI $exe $arguments
}
Catch {
	Write-Host ""
	$UACDeclined = $PSItem | Select-String -pattern "The operation was canceled by the user" -quiet
	if ( $UACDeclined )
	{
		$exitcode = 2
		Write-Host "PowerShell: UAC prompt was declined!" -ForegroundColor Red
	}
	else {
		$exitcode = 1
		Write-Host "PowerShell: Failed to self-elevate (unknown error)!" -ForegroundColor Red
		Write-Host ""
		Write-Host Error: $PSItem -ForegroundColor Red
		Write-Host Where: $PSItem.ScriptStackTrace -ForegroundColor Red
	}
	exit $exitcode
}