ffmpeg mingw64
---

## [MSYS2](https://msys2.github.io/)

- verison
    + i686 => 32bits version
    + x86_64 => 64 bits version

- cmd
    + `pacman`: extension manager
        a. update the package
            > pacman -Sy pacman

        b. list extension
            > pacman -Sl | grep gcc

        c. install
            > pacman -S gcc


## ffmpeg

- setup
    + pacman -Sl | greg tar
    + pacman -Sl | grep gcc
    + pacman -Sl | grep gdb
    + pacman -Sl | grep pkg-config
    + pacman -Sl | grep make
    + pacman -Sl | grep SDL

- configuration

    ```
    # --prefix: set install path
    ./configure --disable-shared --enable-static --disable-optimizations --enable-memalign-hack --disable-asm --enable-pthreads --enable-debug=3 --prefix=~/ffmpeg_output

    ps. MSVC: --toolchain=msvc
        other compiler options: --extra-cflags=-g -O0 --extra-ldflags=-g

    ```
- ffmpeg-2.6.2 version
    > Use mingw64-i686

## code block

- Set up compiler
    + menu Settings -> Compiler
    + Add new compiler (e.g. GNU GCC Compiler (x64)).
    + update the parameters of toolchain (tab Toolchain executables -> Program Files)
        1. C compiler: x86_64-w64-mingw32-gcc.exe
        2. C++ compiler: x86_64-w64-mingw32-g++.exe
        3. Linker for dynamic libs: x86_64-w64-mingw32-g++.exe
        4. Linker for static libs: x86_64-w64-mingw32-gcc-ar.exe

- Set up debugger
    +  menu Settings -> Debugger -> GDB/CDB debgger -> Create Config
        1. enter the name for the configuration (e.g. gdb64)
        2. `Executable path` select the corresponding gdb debugger for mingw64. (e.g. C:\mingw64\bin\gdb.exe)

- compiler and get ffmpeg debug veriosn lib
- put libs to code block project
- Write your app program
- enjoy run-time trace with gdb

- example cbp

    ```
    <?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
    <CodeBlocks_project_file>
        <FileVersion major="1" minor="6" />
        <Project>
            <Option title="test_ffmpeg-2.6.2" />
            <Option pch_mode="2" />
            <Option compiler="gcc" />
            <Build>
                <Target title="Debug">
                    <Option output="bin/Debug/test_ffmpeg-2.6" prefix_auto="1" extension_auto="1" />
                    <Option object_output="obj/Debug/" />
                    <Option type="1" />
                    <Option compiler="mingw64-i686_gnu_gcc_compiler" />
                    <Option parameters="tt.mp4 -strict -2" />
                    <Compiler>
                        <Add option="-std=c99" />
                        <Add option="-g" />
                        <Add directory="ffmpeg_debug/include" />
                        <Add directory="../../../../_portable/msys64/mingw32/include" />
                        <Add directory="../../../../_portable/msys64/mingw32/i686-w64-mingw32/include" />
                    </Compiler>
                    <Linker>
                        <Add library="../../../../_portable/msys64/mingw32/lib/gcc/i686-w64-mingw32/5.3.0/libgcc.a" />
                        <Add library="../../../../_portable/msys64/mingw32/i686-w64-mingw32/lib/libmingwex.a" />
                        <Add library="ffmpeg_debug/lib/libavformat.a" />
                        <Add library="ffmpeg_debug/lib/libavdevice.a" />
                        <Add library="ffmpeg_debug/lib/libavcodec.a" />
                        <Add library="ffmpeg_debug/lib/libavutil.a" />
                        <Add library="ffmpeg_debug/lib/libswscale.a" />
                        <Add library="../../../../_portable/msys64/mingw32/lib/libiconv.a" />
                        <Add library="../../../../_portable/msys64/mingw32/lib/libz.a" />
                        <Add library="../../../../_portable/msys64/mingw32/i686-w64-mingw32/lib/libpthread.a" />
                        <Add library="ffmpeg_debug/lib/libswresample.a" />
                        <Add library="../../../../_portable/msys64/mingw32/lib/libbz2.a" />
                        <Add library="../../../../_portable/msys64/mingw32/i686-w64-mingw32/lib/libwsock32.a" />
                        <Add library="../../../../_portable/msys64/mingw32/i686-w64-mingw32/lib/libws2_32.a" />
                        <Add directory="ffmpeg_debug/lib" />
                        <Add directory="../../../../_portable/msys64/mingw32/lib" />
                        <Add directory="../../../../_portable/msys64/mingw32/i686-w64-mingw32/lib" />
                    </Linker>
                </Target>
                <Target title="Release">
                    <Option output="bin/Release/test_ffmpeg-2.6" prefix_auto="1" extension_auto="1" />
                    <Option object_output="obj/Release/" />
                    <Option type="1" />
                    <Option compiler="gcc" />
                    <Compiler>
                        <Add option="-O2" />
                    </Compiler>
                    <Linker>
                        <Add option="-s" />
                    </Linker>
                </Target>
            </Build>
            <Compiler>
                <Add option="-Wall" />
            </Compiler>
            <Unit filename="muxing.c">
                <Option compilerVar="CC" />
            </Unit>
            <Extensions>
                <code_completion />
                <envvars />
                <debugger />
                <lib_finder disable_auto="1" />
            </Extensions>
        </Project>
    </CodeBlocks_project_file>
    ```





