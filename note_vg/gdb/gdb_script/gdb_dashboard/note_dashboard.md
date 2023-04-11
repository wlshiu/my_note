[GDB Dashboard](https://github.com/cyrus-and/gdb-dashboard)
---

## Setup gdb-dashboard

+ dependency

    ```
    $ sudo apt-get install libpython2.7
    $ sudo apt-get install libpython2.7:i386 --> necessary ?
    ```


+ download gdb-dashboard

    ```
    $ wget -P ~ https://git.io/.gdbinit
    ```

+ manually setup

    - Put `.gdbinit` and `.gdbinit.d` to `$HOME`
        > `.gdbinit` is the core of gdb-dashboard and it will pre-load `.gdbinit.d/*`



## Running

+ Execute GDB
    > the promp will be changed from `(gdb)` to `>>>`
    >>  `gdb-dashboard` will automatically launch after **set breakpoint and run program**

    - ARM toolchain

        ```
        $ arm-none-eabi-gdb-py  ---> include python2
            or
        $ arm-none-eabi-gdb-py3 ---> include python3
        ```

+ use `GDB commnads` to start debug

## Tips

+ reflash screen

    ```
    >>> dashboard
    ```

+ change layout
    > the customer commands are defined in `~/.gdbinit.d/init`

    ```
    >>> win- (press tab to list customer commands)
    ```

