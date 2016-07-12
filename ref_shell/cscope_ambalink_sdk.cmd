@echo off
set PATH=%PATH%;Z:\tool\


set WORKSPACE=%cd%

echo active path = %WORKSPACE%

set path_pkg=%WORKSPACE%\ambalink_sdk_3_10\pkg
set path_libev=%WORKSPACE%\ambalink_sdk_3_10\output\a12_ambalink\build\libev-4.15
set path_libcurl=%WORKSPACE%\ambalink_sdk_3_10\output\a12_ambalink\build\libcurl-7.39.0
set path_ffmpeg=%WORKSPACE%\ambalink_sdk_3_10\output\a12_ambalink\build\ffmpeg-2.4.3

REM set dest_linux=%WORKSPACE%\ambalink_sdk_3_10\pkg\youtube_livestream
set dest_linux=%WORKSPACE%\ambalink_sdk_3_10\pkg\


gfind %path_pkg% -type f -iname *.h -o -iname *.c -o -iname *.cpp > %dest_linux%\cscope.files
gfind %path_libev% -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files
gfind %path_libcurl%\include\curl -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files
gfind %path_libcurl%\lib -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files
gfind %path_ffmpeg%\libavformat -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files
gfind %path_ffmpeg%\libavcodec -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files
gfind %path_ffmpeg%\libavfilter -type f -iname *.h -o -iname *.c -o -iname *.cpp >> %dest_linux%\cscope.files

cd Z:\tool
.\cscope.exe -bkq -i %dest_linux%\cscope.files
.\ctags.exe --c++-kinds=+p --fields=+iaS --extra=+q -L %dest_linux%\cscope.files

move /Y .\cscope.in.out %dest_linux%\cscope.in.out
move /Y .\cscope.out %dest_linux%\cscope.out
move /Y .\cscope.po.out %dest_linux%\cscope.po.out
move /Y .\tags %dest_linux%\tags

echo move to %dest_linux%
echo

pause
if "%ERRORLEVEL%" != "0" pause
