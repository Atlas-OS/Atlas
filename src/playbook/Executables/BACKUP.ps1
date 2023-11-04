param (
	[Parameter( Mandatory = $True )]
	[string]$FileName
)

if (Test-Path $FileName) { exit }

Add-Content -Path $FileName -Value "Windows Registry Editor Version 5.00"
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
	if ((Get-ItemProperty $_.PSPath).PSObject.Properties.Name -contains "Start") {
		$startValue = (Get-ItemProperty -Path $_.PSPath -Name "Start").Start
		for ($c = 0; $c -le 4; $c++) {
			if ($startValue -eq "0x$c") {
				Add-Content -Path $FileName -Value ("`n" + "[" + $_.Name + "]")
				Add-Content -Path $FileName -Value ("`"Start`"=dword:0000000$c")
			}
		}
	}
}
