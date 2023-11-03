@echo off
set "log=notepad "%~1""
set "nr=echo] > "%~2""
set "s=del /f /q "%~3""

cls & echo Type %%log%% to open the log.
echo Type %%nr%% to disable automatic restart.
echo Type %%s%% to stop auto-focus of MSHTA.