@echo off

REM set TOOLCHAIN=D:\_portable\msys64\home\gcc-arm-none-eabi-10-2020-q4-major\bin
set TOOLCHAIN=D:\_portable\codeblocks-17.12mingw\MinGW\bin
set CMDER=C:\cmder\vendor\git-for-windows\usr\bin;C:\cmder\vendor\bin;C:\cmder
set PATH=%TOOLCHAIN%;%CMDER%;C:\Windows\System32
call cmd