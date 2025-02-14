if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
  Remove-Item -Path "$env:windir\AtlasDesktop\7. Security\Mitigations\Fault Tolerant Heap" -Recurse -Force -ErrorAction SilentlyContinue
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
  Start-Process -FilePath "rundll32.exe" -ArgumentList "fthsvc.dll,FthSysprepSpecialize" -NoNewWindow -Wait
  reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 0 /f
}
