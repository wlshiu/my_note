CodeBlocks
---

# Linux (lubuntu 18.04)

+ install

    ```shell
    # $ sudo add-apt-repository ppa:damien-moore/codeblocks-stable
    # $ sudo apt-get update
    $ sudo apt-get install codeblocks codeblocks-contrib
    ```

+ uninstall

    ```sh
    $ sudo apt-get autoremove codeblocks
    ```

+ disable full screen hot key F11

    ```
    $ vi ~/.config/openbox/lubuntu-rc.xml
        mark F11 item
    ```

    - editor

    ```
    https://github.com/nsf/obkey

    $ cd obkey
    $ ./obkey ~/.config/openbox/lubuntu-rc.xml
    ```

# Configure

+ options flag

    ```
    menu bar settings --> Compiler --> Compiler settings --> compiler flags
    enable:
        1. [-g]
        2. [-std=c++11]
    ```

+ toolchain

    ```
    menu bar settings --> Compiler --> Compiler settings --> Toolchain executables
        Compiler's installation directory: /usr
    ps. you should check is there gcc/g++/ar/gdb execution file in /usr/bin
    ```

    ```
    # include header path
    menu bar settings --> Compiler --> search directories --> compler
    Add:
        /usr/lib/gcc/x86_64-linux-gnu/4.9.4/include
        /usr/include

    # include lib path
    menu bar settings --> Compiler --> search directories --> linker
    Add:
        1. /usr/lib/gcc/x86_64-linux-gnu/4.9.4
        2. /usr/lib/x86_64-linux-gnu
    ```

+ change terminal

    ```
    menu bar Settings --> Environment --> General settings
        Terminal to launch console programs:
            1. xterm -T $TITLE -e (default)
            2. lxterminal --disable-factory -t $TITLE -x
            3. gnome-terminal --disable-factory -t $TITLE -x
    ```

+ printf chinese

    ```
    menu bar settings --> Compiler --> Compiler settings --> Other compiler options
    Add:
        -finput-charset=UTF-8
        -fexec-charset=UTF-8
    ```

+ link dll file

    ```
    # e.g. link regex.dll, iniparser.dll
    menu bar settings --> Compiler --> Linker settings --> Other linker options
    Add:
        -lregex -liniparser

    menu bar settings --> Compiler --> search directories --> linker
    Add:
        the dirctory path of the dll file
    ```

+ map file

    ```
    menu bar Project -> build options -> link setting -> other linker options
    Add '-Wl,-Map=${TARGET_OUTPUT_FILE}.map'
    ```

+ size target

    ```
    menu bar Project -> build options -> Pre/Post build steps -> Post-build steps
    Add 'size ${TARGET_OUTPUT_FILE}'
    ```
