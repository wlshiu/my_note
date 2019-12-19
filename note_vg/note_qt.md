Qt (sound like cute)
---

[Qt Downloads](http://download.qt.io/archive/qt/)

# code::blocks

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


# QT Creator

