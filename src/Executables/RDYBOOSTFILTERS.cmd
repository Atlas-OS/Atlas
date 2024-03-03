@echo off
setlocal EnableDelayedExpansion

:: Remove lower filters for rdyboost driver
set key="HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
for /f "skip=1 tokens=3*" %%a in ('reg query %key% /v "LowerFilters"') do (set val=%%a)
:: `val` would be like `rdyboost\0fvevol\0iorate`
set val=!val:rdyboost\0=!
set val=!val:\0rdyboost=!
set val=!val:rdyboost=!
reg add !key! /v "LowerFilters" /t REG_MULTI_SZ /d !val! /f