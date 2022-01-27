Qt (sound like cute)
---

+ [Qt Downloads](http://download.qt.io/archive/qt/)
+ [Prebuilt-Tool](https://download.qt.io/development_releases/prebuilt/)

# Code::Blocks

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

        * tab [Linker Setting]

            1. add libs `C:\Qt\5.12.6\mingw73_32\lib\libxxx.a`


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

# Build static library

## Official

+ [Qt Online Installer](https://download.qt.io/archive/online_installers/4.2/)

    - Select tool
        > + MinGW 7.3.0 32-bit/64-bit
        > + Source
        > + Strawberry Perl

+ Install `Python` by self


## Self Tools

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

## Configure

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
    .\configure.bat -confirm-license -opensource -platform win32-g++ -mp -debug-and-release -static ^
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

## Reference

+ [Qt5.14.2 MinGW-32靜態編譯及壓縮過程配置教程-CSDN博客](https://blog.csdn.net/zhoufoxcn/article/details/120999085?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-1.pc_relevant_paycolumn_v3&spm=1001.2101.3001.4242.2&utm_relevant_index=4)
+ [Qt5.14.2 MInGW靜態編譯配置教程-CSDN博客\_qt5.14靜態編譯](https://blog.csdn.net/weixin_42508702/article/details/118784750?spm=1001.2101.3001.6650.4&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-4.pc_relevant_default&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-4.pc_relevant_default&utm_relevant_index=9)


# Build App with console

+ reference
    - [mingw_w64-qt5_static-cmake-console-example](https://github.com/tim-lebedkov/mingw_w64-qt5_static-cmake-console-example)

# QT Designer

[Download](https://build-system.fman.io/qt-designer-download)

## Qt ui file convert to C++

+ `uic`
    > `QtDesigner/uic.exe`

    ```
    > uic -o my_window.h my_window.ui
    ```

# QT Creater
