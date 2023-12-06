# Qt (sound like cute)

+ [Qt Downloads](http://download.qt.io/archive/qt/)
+ [Prebuilt-Tool](https://download.qt.io/development_releases/prebuilt/)

## Code::Blocks

+ Setup IDE

    - Set toolchain
        > [Settings]->[Compiler]->[Copy GCC]->

        * tab [toolchain executables]

        ```
        compiler's installation directory = 'C:\Qt\Tools\mingw730_32'
        c compiler              = gcc.exe
        c++ compiler            = g++.exe
        linker for dynamic libs = g++.exe
        linker for static libs  = ar.exe
        debugger                = [select your gdb for qt]
        * others no change
        ```

        * tab [Search directories]

            1. `Compiler`
                > + add `C:\Qt\5.12.6\mingw73_32\include`
                > + add `C:\Qt\Tools\mingw730_32\include`

            1. `Linker`
                > + `C:\Qt\5.12.6\mingw73_32\lib`
                > + `C:\Qt\Tools\mingw730_32\lib`

        * Tab [Linker Setting]

            1. add libs `C:\Qt\...\lib\libxxx.a`

                ```
                Qt/QT_5.14.2_static/plugins/platforms/libqwindows.a
                Qt/QT_5.14.2_static/lib/libqtlibpng.a
                Qt/QT_5.14.2_static/lib/libqtharfbuzz.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libversion.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libws2_32.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libwsock32.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libole32.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libuserenv.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libwinmm.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libuuid.a
                Qt/Tools/mingw730_32/i686-w64-mingw32/lib/libnetapi32.a
                ```

    - Set global environment variables
        > [Setting]->[Environment]->[Environment variables]

        * create

        ```
        key   : PATH
        value : %PATH%;C:\Qt\5.12.6\mingw73_32\bin

        ps. press 'Set now'
        ```

    - Set global variables
        > [Setting]->[Global variables]->[New]

        ```
        base    = C:\Qt\5.12.6\mingw73_32
        include = C:\Qt\5.12.6\mingw73_32\include
        lib     = C:\Qt\5.12.6\mingw73_32\lib
        bin     = C:\Qt\5.12.6\mingw73_32\bin
        ```

    - Set debugger
        > [Setting]->[Debugger]->[GDB/CDB debugger]

        * Create Config

        ```
        Executable path = C:\Qt\Tools\mingw730_32\bin\gdb.exe
        ```

    - Set Qt qmake
        > [Tools]->[Configure tools]

        * `qmake -project static`

        ```
        name                = 'qmake -project static'
        Executable          = 'C:\Qt\5.12.6\mingw73_32\bin\qmake.exe'
        Parameters          = '-project'
        Working directory   = '${{PROJECT_DIR}}'

        select 'Launch tool hidden with standard output redirected'

        ```

        * `qmake static`

        ```
        name                = 'qmake static'
        Executable          = 'C:\Qt\5.12.6\mingw73_32\bin\qmake.exe'
        Parameters          = ''
        Working directory   = '${{PROJECT_DIR}}'

        select 'Launch tool hidden with standard output redirected'
        ```

+ Create Qt5 project

    - execute `qmake -project static`
    - execute `qmake static`
    - compiler with gcc

## Build static library

### Official

+ [Qt Online Installer](https://download.qt.io/archive/online_installers/4.2/)

    - Select tool
        > + MinGW 7.3.0 32-bit/64-bit
        > + Source
        > + Strawberry Perl

+ Install `Python` by self


### Self Tools

+ [cmder_mini](https://cmder.net/)
+ mingw
    - [mingw730_32](https://download.qt.io/development_releases/prebuilt/mingw_32/)
    - [mingw730_64](https://download.qt.io/development_releases/prebuilt/mingw_64/)

+ [cmake](https://cmake.org/download/)

+ [Python 2.7.16](https://www.python.org/downloads/release/python-2716/)

+ Setup environment

    - Use cmder as front-end console
        > Inject your commands to `cmder/bin`

    - Decompress mingw to root directory of cmder
    - Decompress cmake to root directory of cmder

    - Enter QT source code folder

### Configure

+ check `gcc` version

    ```
    > gcc --version
        ...
        gcc version 7.3.0
        ...
    ```

+ check `perl` version

    ```
    > perl --version
        ...
        perl 5, version 22
        ...
    ```

+ check `python` version
    > Python-3 ideally support too.

    ```
    > python --version
        Python 2.7.16
        ...
    ```

+ generate makefile
    > `-prefix` set the target directory for installing

    ```batch
    @echo off
    rem '-debug-and-release' or '-debug' or '-release'
    rem '-static' or '-shared'
    .\configure.bat -confirm-license -opensource -platform win32-g++ -mp -release -static ^
        -prefix C:\QT_5.14.2_static ^
        -qt-sqlite ^
        -qt-zlib ^
        -qt-libpng ^
        -qt-libjpeg ^
        -opengl desktop ^
        -qt-freetype ^
        -no-qml-debug ^
        -no-angle ^
        -nomake tests ^
        -nomake examples ^
        -skip qtwebengine ^
        -skip qtwebview ^
        -skip qt3d
    ```

+ make

    ```
    > mingw32-make
    > mingw32-make install
    ```

### Reference

+ [Qt5.14.2 MinGW-32靜態編譯及壓縮過程配置教程-CSDN博客](https://blog.csdn.net/zhoufoxcn/article/details/120999085?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-1.pc_relevant_paycolumn_v3&spm=1001.2101.3001.4242.2&utm_relevant_index=4)
+ [Qt5.14.2 MInGW靜態編譯配置教程-CSDN博客\_qt5.14靜態編譯](https://blog.csdn.net/weixin_42508702/article/details/118784750?spm=1001.2101.3001.6650.4&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-4.pc_relevant_default&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-4.pc_relevant_default&utm_relevant_index=9)


## Build App with console

+ reference
    - [mingw_w64-qt5_static-cmake-console-example](https://github.com/tim-lebedkov/mingw_w64-qt5_static-cmake-console-example)

## QT Designer

[Download](https://build-system.fman.io/qt-designer-download)

### Qt ui file convert to C++

+ `uic`
    > `QtDesigner/uic.exe`

    ```
    > uic -o my_window.h my_window.ui
    ```


### IDE tips

+ `Edit Signal/Slot` (hot key: F4)
    > Enter Signal/Slot mode
    >> 可用 Drag/Drop 來連接元件

+ `Edit Widgets` (hot key: F3)
    > Enter Widgets mode
    >> 可用 Drag/Drop 來編輯元件 layout

+ 在元件上 `Right click`

    - `Go to slot`
        > Generate **method code** of this component


### Reference

+ [6.2 Hello Qt -> 6.2.5 第 3 種方法](https://wizardforcel.gitbooks.io/wudi-qt4/content/39.html)
+ [使用 Qt Designer 進行 GUI 設計](https://wizardforcel.gitbooks.io/wudi-qt4/content/32.html)

## qmake

make for QT and involve
> + moc (Meta-Object Compiler)
> + uic (User Interface Compiler)
> + rcc (Resource Compiler)

### Command line build project

+ Setup environment

    ```
    $ vi run.bat
        @echo off
        set QtPath=C:\Qt\5.14.2\mingw73_32\bin
        set QtToolPath=C:\Qt\Tools\mingw730_32\bin
        set PATH=%QtToolPath%;%QtPath%;%PATH%;
    ```

+ App code

    ```cpp
    $ vi hello.cpp
        #include <QPushButton>
        #include <QApplication>
        int main(int argc,char *argv[])
        {
            QApplication a(argc,argv);
            QPushButton hellobtn("Hello World!",0);
            hellobtn.resize(200,50);
            hellobtn.show();
            return a.exec();
        }
    ```

+ Static library setup
    > add `QMAKE_LFLAGS = -static` and `QMAKE_LFLAGS_DLL = -static`

    ```
    $ vi C:\QT_5.14.2_static\mkspecs\common\g++-win32.conf
        #
        # This file is used as a basis for the following compilers, when targeting
        # MinGW-w64:
        #
        # - GCC
        # - Clang
        #
        # Compiler-specific settings go into win32-g++/qmake.conf and
        # win32-clang-g++/qmake.conf
        #

        load(device_config)
        include(gcc-base.conf)
        include(g++-base.conf)

        # modifications to gcc-base.conf and g++-base.conf

        MAKEFILE_GENERATOR      = MINGW
        QMAKE_PLATFORM          = win32 mingw
        CONFIG                 += debug_and_release debug_and_release_target precompile_header
        DEFINES                += UNICODE _UNICODE WIN32 MINGW_HAS_SECURE_API=1
        QMAKE_COMPILER_DEFINES += __GNUC__ _WIN32
        # can't add 'DEFINES += WIN64' and 'QMAKE_COMPILER_DEFINES += _WIN64' defines for
        # x86_64 platform similar to 'msvc-desktop.conf' toolchain, because, unlike for MSVC,
        # 'QMAKE_TARGET.arch' is inherently unavailable.

        QMAKE_LEX               = flex
        QMAKE_LEXFLAGS          =
        QMAKE_YACC              = bison -y
        QMAKE_YACCFLAGS         = -d

        QMAKE_CFLAGS_SSE2      += -mstackrealign

        QMAKE_CXXFLAGS_EXCEPTIONS_ON = -fexceptions -mthreads

        QMAKE_INCDIR            =

        QMAKE_RUN_CC            = $(CC) -c $(CFLAGS) $(INCPATH) -o $obj $src
        QMAKE_RUN_CC_IMP        = $(CC) -c $(CFLAGS) $(INCPATH) -o $@ $<
        QMAKE_RUN_CXX           = $(CXX) -c $(CXXFLAGS) $(INCPATH) -o $obj $src
        QMAKE_RUN_CXX_IMP       = $(CXX) -c $(CXXFLAGS) $(INCPATH) -o $@ $<

        QMAKE_LFLAGS = -static  ################# added by user

        QMAKE_LFLAGS_EXCEPTIONS_ON = -mthreads
        QMAKE_LFLAGS_RELEASE    = -Wl,-s
        QMAKE_LFLAGS_CONSOLE    = -Wl,-subsystem,console
        QMAKE_LFLAGS_WINDOWS    = -Wl,-subsystem,windows
        # QMAKE_LFLAGS_DLL        = -shared
        QMAKE_LFLAGS_DLL        = -static ######## Modified by user

        QMAKE_LFLAGS_GCSECTIONS = -Wl,--gc-sections
        equals(QMAKE_HOST.os, Windows) {
            QMAKE_LINK_OBJECT_MAX = 10
            QMAKE_LINK_OBJECT_SCRIPT = object_script
        }
        QMAKE_EXT_OBJ           = .o
        QMAKE_EXT_RES           = _res.o
        QMAKE_PREFIX_SHLIB      =
        QMAKE_EXTENSION_SHLIB   = dll
        QMAKE_PREFIX_STATICLIB  = lib
        QMAKE_EXTENSION_STATICLIB = a
        QMAKE_LIB_EXTENSIONS    = a dll.a

        QMAKE_LIBS              =
        QMAKE_LIBS_GUI          = -lgdi32 -lcomdlg32 -loleaut32 -limm32 -lwinmm -lws2_32 -lole32 -luuid -luser32 -ladvapi32
        QMAKE_LIBS_NETWORK      = -lws2_32
        QMAKE_LIBS_OPENGL       = -lglu32 -lopengl32 -lgdi32 -luser32
        QMAKE_LIBS_OPENGL_ES2   = -lgdi32 -luser32
        QMAKE_LIBS_OPENGL_ES2_DEBUG = -lgdi32 -luser32
        QMAKE_LIBS_COMPAT       = -ladvapi32 -lshell32 -lcomdlg32 -luser32 -lgdi32 -lws2_32
        QMAKE_LIBS_QT_ENTRY     = -lmingw32 -lqtmain

        QMAKE_IDL               = midl
        QMAKE_LIB               = $${CROSS_COMPILE}ar -rc
        QMAKE_RC                = $${CROSS_COMPILE}windres

        QMAKE_STRIP             = $${CROSS_COMPILE}strip
        QMAKE_STRIPFLAGS_LIB   += --strip-unneeded
        QMAKE_OBJCOPY           = $${CROSS_COMPILE}objcopy
        QMAKE_NM                = $${CROSS_COMPILE}nm -P

        include(angle.conf)
        include(windows-vulkan.conf)

    ```

+ Build

    - Create project file

        ```
        $ run.bat
        $ qmake -project  # generate project file *.pro
        ```

    - Add configuration to project file

        ```
        $ vi hello.pro
            ######################################################################
            # Automatically generated by qmake (3.1) Wed Feb 9 09:52:50 2022
            ######################################################################

            TEMPLATE = app
            TARGET = hello
            INCLUDEPATH += .

            # You can make your code fail to compile if you use deprecated APIs.
            # In order to do so, uncomment the following line.
            # Please consult the documentation of the deprecated API in order to know
            # how to port your code away from it.
            # You can also select to disable deprecated APIs only up to a certain version of Qt.
            #DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

            ### user add +
            QT += core gui
            greaterThan(QT_MAJOR_VERSION, 4): QT += widgets
            ### user add -

            # Input
            SOURCES += hello.cpp

        ```

    - Launch project file

        ```
        $ qmake hello.pro
        ```

    - Compile

        ```
        $ mingw32-make
        ```

    - Execture program

        ```
        $ ./release/hello.exe
        ```

## UPX

[UPX](https://upx.github.io/) is used to compress executable files.


## Enigma virtual box

[Enigma virtual box](https://enigmaprotector.com/en/downloads.html) is used
to pack all files (e.g. *.dll, *.lib, *.exe, ...etc) to an executable file

> In real-time, it will un-pack in background.


## QT Creater

+ `Windows 7` use **QT Creater 4.11.1** base on **QT5.14.1**

### IDE Tips

+ Project pane
    > `Window -> Show Left Sidebar`

    1. `+ (split)`
        > 分割側邊欄

    1. 下拉選擇 View
        > e.g. Projects, Open Documnets, ..., etc.

+ Add a new ui file
    - [File]->[New file or Project]
    - [Files and Classes]->[QT]
    - [Qt Designer Form Class]

+ Use static Qt lib

    - Add new Qt lib

        1. [Tools] -> [Options...]

            > + Qt Version (add qmake path)
            >> `C:\Qt\QT_5.14.2_static\bin\qmake.exe`

            > + Kits (add QT_5.14.2_static)
            >> Compile C   : `MinGW 7.3.0 32-bit for C` <br>
            >> Compile C++ : `MinGW 7.3.0 32-bit for C++` <br>
            >> Debugger    : `GNU gdb 8.1 for MinGW 7.3.0 32-bit` <br>
            >> Qt Version  : `QT_5.14.2_static`

    - Enable Build & Run environment

        1. [Sidebar- Projects] -> [Build & Run]

            > + Expand `QT_5.14.2_static`
            > + [Right key] -> [Enable for All Projects]

+ Enable console log

    - [Sidebar- Projects] -> [Build & Run] -> [Run]
        > select `Run in terminal`

    - [Sidebar- Edit] -> `*.pro`
        > add `CONFIG += console`

    - progam use `QDebug`

### [Programming concept](note_qt_prog.md)

### Reference
+ [第 12 章 使用 Qt Creator](https://wizardforcel.gitbooks.io/wudi-qt4/content/88.html)
