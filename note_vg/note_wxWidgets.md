wxWidgets
---

[wxWidgets 3.0.4](https://github.com/wxWidgets/wxWidgets/releases/tag/v3.0.4)

[wxMSW-3.0.4-mingw](https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.4/wxMSW-3.0.4_gcc510TDM_Dev.7z)

[wxWidgets-3.0.4-headers](https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.4/wxWidgets-3.0.4-headers.7z)

# code::blocks (17.12)

+ setup

    - decompress
        > + `wxWidgets-3.0.4-headers.7z` to `c:/wxWidgets-3.0.4`
        > + `wxMSW-3.0.4_gcc510TDM_Dev.7z` to `c:/wxWidgets-3.0.4`
        >> rename `gcc510TDM_dll` to `gcc_dll`

    ```
    c:/wxWidgets-3.0.4
        ├── include
        │   ├── msvc
        │   └── wx
        └── lib
            └── gcc_dll
    ```

+ IDE setting

    - set global variables
        > [Settings]->[Global variables]

        ```
        base    = 'C:\wxWidgets-3.0.4'
        include = 'C:\wxWidgets-3.0.4\include\'
        lib     = 'C:\wxWidgets-3.0.4\lib'
        ```

+ create project

    - New wxWidgets project
    - select `wxWidgets 3.0.x`
    - ignore author info
    - GUI builder `wxSmith`
    - wxWidgets location `C:\wxWidgets-3.0.4`
    - wxWidgets libraries setting

        1. Use wxWidgets dll
        1. enable unicode

    - build options

        1. set include path
            > [search directories]->[Compiler]

        ```
        add 'C:\wxWidgets-3.0.4\lib\gcc_dll\mswud'
        ```

        1. set libraries path
            > [search directories]->[Linker]

        ```
        add 'C:\wxWidgets-3.0.4\lib\gcc_dll'
        ```










