
@echo off
set /p comport_num=Please Enter COM Number (0 ~ 250):
echo %comport_num%

set TTERMPRO_EXE="C:\tool_portable\teraterm\ttermpro.exe"
set TTL_FILE=".\template.ttl"

REM %TTERMPRO_EXE% /C=12 /M=%TTL_FILE%
%TTERMPRO_EXE% /C=%comport_num%
