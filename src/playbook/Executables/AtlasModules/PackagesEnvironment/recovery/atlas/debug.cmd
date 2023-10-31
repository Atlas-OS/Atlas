@echo off
set "log=notepad "%~1""
set "nr=echo] > "%~2""

cls & echo Type %%log%% to open the log.
echo Type %%nr%% to disable automatic restart.