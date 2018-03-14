@echo off

for %%* in (.) do set CurrDirName=%%~nx*
echo %CurrDirName%
pause
