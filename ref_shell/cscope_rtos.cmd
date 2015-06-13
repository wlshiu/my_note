@echo off
set PATH=%PATH%;Z:\tool

set WORKSPACE=%cd%
echo active path = %WORKSPACE%

set rots_path_app=%WORKSPACE%\rtos\rtos\app\connected\app
set rots_path_applib=%WORKSPACE%\rtos\rtos\app\connected\applib
set rots_path_mw=%WORKSPACE%\rtos\rtos\mw
set rots_path_ssp=%WORKSPACE%\rtos\rtos\ssp
set rots_path_vendors=%WORKSPACE%\rtos\rtos\vendors

set dest_rtos=%WORKSPACE%\rtos\rtos\app\connected\applib\src


gfind %rots_path_app%\system -type f -iname *.h -o -iname *.c -o -iname *.cpp > %dest_rtos%\cscope.files


gfind %rots_path_applib%\src\ambalink_privrpc -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\src\ambalink_privsvc -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\src\ambalink_pubsvc -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\src\recorder -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\src\net -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\unittest -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files

gfind %rots_path_applib%\inc\net -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\inc\recorder -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_applib%\inc\rpcprog -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files


gfind %rots_path_mw%\net -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_mw%\dspflow\fifo -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files

gfind %rots_path_ssp%\link -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_ssp%\kal -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files

gfind %rots_path_vendors%\ambarella\inc\mw\fifo -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_vendors%\ambarella\inc\mw\net -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
REM gfind %rots_path_vendors%\ambarella\inc\ssp\link -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_vendors%\ambarella\inc\mw\stream -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files
gfind %rots_path_vendors%\ambarella\inc\ssp -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_rtos%\cscope.files

cd Z:\tool
.\cscope.exe -bkq -i %dest_rtos%\cscope.files
.\ctags.exe --c++-kinds=+p --fields=+iaS --extra=+q -L %dest_rtos%\cscope.files

move /Y .\cscope.in.out %dest_rtos%\cscope.in.out
move /Y .\cscope.out %dest_rtos%\cscope.out
move /Y .\cscope.po.out %dest_rtos%\cscope.po.out
move /Y .\tags %dest_rtos%\tags

echo move to %dest_rtos%
echo;

pause
if "%ERRORLEVEL%" != "0" pause
